#!/usr/bin/env python3
"""
naka_struct_decode.py — Full NAKA widget C file struct decoder

Reads an existing NAKA .c file (with raw hex byte arrays), decodes ALL data into
proper C structs: dispatch widgets with named fields, strings as readable text,
pointers as NAKA_ADDR(symbol) or SELF(field), padding as zero arrays, and unknown
data as uint16_t fields.

Usage:
    python scripts/naka_struct_decode.py <input.c> [--dry-run] [--verify]
    python scripts/naka_struct_decode.py --file naka_sound_menu_drawbar.c

The script:
1. Reads the base address and total size from the existing C file header
2. Reads the corresponding ROM bytes
3. Loads ELF symbol table for pointer resolution
4. Scans for NAKA headers, strings, pointer tables, and padding
5. Generates a fully decoded C file + linker script
6. Optionally verifies byte match after compilation
"""

import sys
import os
import re
import struct
import subprocess
from pathlib import Path
from collections import OrderedDict

# Paths
ROMS_DIR = Path(__file__).parent.parent
ROM_PATH = Path("/mnt/shared/kn5000_original_roms/kn5000/kn5000_v10_program.rom")
ELF_PATH = ROMS_DIR / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"
LLVM_NM = Path("/mnt/shared/llvm-project/build/bin/llvm-nm")
WIDGETS_DIR = ROMS_DIR / "maincpu" / "ui_widgets"
ROM_BASE = 0xE00000  # maincpu ROM maps to 0xE00000-0xFFFFFF

# ── Known widget type layouts ──────────────────────────────────────────

# (field_name, size_bytes, is_pointer)
DISPATCH_FIELDS = [
    ("field_04", 2, False), ("field_06", 2, False),
    ("name_ptr", 4, True), ("inst_ptr", 4, True),
    ("link_ptr", 4, True), ("proc_addr", 4, True),
]
DISPATCH_BODY_SIZE = 20  # 24 total - 4 header

CONTAINER_FIELDS = [
    ("parent_idx", 2, False), ("self_idx", 2, False),
    ("next_sibling", 2, False), ("prev_sibling", 2, False),
    ("child_count", 2, False), ("field_0e", 2, False), ("field_10", 2, False),
    ("handler", 4, True), ("style", 2, False), ("field_18", 2, False),
    ("field_1a", 2, False), ("screen_id", 2, False),
    ("handler_table", 4, False), ("string_ptr", 4, True),
    ("string_id", 2, False), ("reserved", 2, False),
]
CONTAINER_BODY_SIZE = 38

MENU_ITEM_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_margin", 2, False), ("y_pos", 2, False),
    ("sel_x1", 2, False), ("sel_y1", 2, False),
    ("sel_x2", 2, False), ("sel_y2", 2, False),
    ("flags", 2, False), ("link_idx", 2, False),
    ("field_1c", 2, False), ("field_1e", 2, False),
    ("bg_color", 2, False), ("field_22", 2, False),
    ("handler_id", 2, False), ("handler_table", 4, False),
    ("string_ptr", 4, True), ("ui_class", 2, False),
    ("screen_id", 2, False), ("string_len", 2, False),
    ("reserved", 2, False),
]
MENU_ITEM_BODY_SIZE = 50

LABEL_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_offset", 2, False), ("field_0e", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("string_ptr", 4, True),
    ("flags", 2, False), ("field_1a", 2, False),
    ("bg_color", 2, False),
]
LABEL_BODY_SIZE = 28

GROUP_FIELDS = [
    ("parent_idx", 2, False), ("field_06", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_offset", 2, False), ("y_offset", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("field_16", 2, False),
    ("field_18", 2, False),
]
GROUP_BODY_SIZE = 22

SLIDER_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_offset", 2, False), ("y_offset", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("handler", 4, True),
    ("field_1a", 2, False), ("field_1c", 2, False),
    ("field_1e", 2, False), ("handler_id", 2, False),
    ("field_22", 2, False), ("field_24", 2, False),
    ("link_idx", 2, False), ("field_28", 2, False),
    ("field_2a", 2, False),
]
SLIDER_BODY_SIZE = 40

TYPE_0x48_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("field_0c", 2, False), ("field_0e", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("field_16", 2, False),
    ("field_18", 2, False),
]
TYPE_0x48_BODY_SIZE = 22

# Map type code → (struct_name, body_size, field_list, has_trailing_string)
KNOWN_TYPES = {
    0x34: ("naka_container_t", CONTAINER_BODY_SIZE, CONTAINER_FIELDS, True),
    0x1D: ("naka_menu_item_t", MENU_ITEM_BODY_SIZE, MENU_ITEM_FIELDS, True),
    0x2B: ("naka_label_t", LABEL_BODY_SIZE, LABEL_FIELDS, True),
    0x30: ("naka_slider_t", SLIDER_BODY_SIZE, SLIDER_FIELDS, False),
    0x31: ("naka_group_t", GROUP_BODY_SIZE, GROUP_FIELDS, False),
    0x48: ("naka_type_0x48_t", TYPE_0x48_BODY_SIZE, TYPE_0x48_FIELDS, False),
}

# Dispatch types: all types that use the 24-byte dispatch layout
DISPATCH_TYPES = {
    0x00, 0x01, 0x10, 0x11, 0x12, 0x15, 0x1C, 0x20, 0x21, 0x22,
    0x25, 0x26, 0x27, 0x29, 0x33, 0x3E, 0x40, 0x44, 0x45, 0x47, 0x4E, 0x54,
}

# Types that can be EITHER dispatch (24B) or full struct depending on context
AMBIGUOUS_TYPES = {0x34, 0x31}  # CONTAINER and GROUP appear in dispatch arrays too

# NAKA type name mapping for named constants
NAMED_TYPE_CODES = {
    0x16: "NAKA_TYPE_DIAGLIST", 0x1D: "NAKA_TYPE_MENU_ITEM",
    0x1E: "NAKA_TYPE_PANEL", 0x2B: "NAKA_TYPE_LABEL",
    0x2E: "NAKA_TYPE_VALUE", 0x2F: "NAKA_TYPE_OPTION",
    0x30: "NAKA_TYPE_SLIDER", 0x31: "NAKA_TYPE_GROUP",
    0x34: "NAKA_TYPE_CONTAINER", 0x66: "NAKA_TYPE_LIST",
    0x6C: "NAKA_TYPE_BITMAP",
}


# ── Symbol table ───────────────────────────────────────────────────────

def load_symbols():
    """Load symbol table from ELF: addr→name and name→addr."""
    result = subprocess.run(
        [str(LLVM_NM), "--no-sort", str(ELF_PATH)],
        capture_output=True, text=True
    )
    addr_to_name = {}
    name_to_addr = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            addr_to_name[addr] = name
            name_to_addr[name] = addr
    return addr_to_name, name_to_addr


def load_rom():
    """Load ROM binary."""
    with open(ROM_PATH, 'rb') as f:
        return f.read()


# ── Data classification ────────────────────────────────────────────────

def is_naka_header(data, pos):
    """Check if data[pos:pos+4] is a NAKA widget header."""
    if pos + 4 > len(data):
        return False
    return (data[pos + 1] == 0x00 and
            data[pos + 2] == 0x60 and
            data[pos + 3] == 0x01 and
            data[pos] <= 0x6F)


def is_printable_byte(b):
    """Check if byte is printable ASCII (0x20-0x7E)."""
    return 0x20 <= b <= 0x7E


def find_string_at(data, pos):
    """Try to find an aligned_string at pos.

    Returns (string_text, total_bytes) or None.
    String format: printable ASCII + NUL + optional 0xFF pad to even boundary.
    Also handles empty strings: NUL + 0xFF (2 bytes).
    """
    if pos >= len(data):
        return None

    # Empty string case: 0x00 0xFF
    if data[pos] == 0x00 and pos + 1 < len(data) and data[pos + 1] == 0xFF:
        return ("", 2)

    # Non-empty string: printable chars followed by NUL
    if not is_printable_byte(data[pos]):
        return None

    end = pos
    while end < len(data) and is_printable_byte(data[end]):
        end += 1

    if end >= len(data) or data[end] != 0x00:
        return None

    str_len = end - pos
    if str_len == 0:
        return None

    text = bytes(data[pos:end]).decode('ascii')
    total = str_len + 1  # +NUL

    # Check for 0xFF pad to even boundary
    if total % 2 == 1 and end + 1 < len(data) and data[end + 1] == 0xFF:
        total += 1

    return (text, total)


def is_pointer_value(val):
    """Check if a 32-bit value looks like a ROM pointer."""
    return 0xE00000 <= val <= 0xFFFFFF


def is_self_pointer(val, base_addr, total_size):
    """Check if a 32-bit value points within our data block."""
    return base_addr <= val < base_addr + total_size


def find_pointer_table_at(data, pos, min_count=3):
    """Try to find a pointer table (array of 4-byte ROM addresses) at pos.

    Returns (count, total_bytes) or None.
    A pointer table has >=min_count consecutive values that are ROM pointers
    or NULL, with at least one non-null.
    """
    if pos + min_count * 4 > len(data):
        return None

    count = 0
    has_nonzero = False
    i = pos
    while i + 4 <= len(data):
        val = struct.unpack_from('<I', data, i)[0]
        if val == 0:
            count += 1
        elif is_pointer_value(val):
            count += 1
            has_nonzero = True
        else:
            break
        i += 4

    if count >= min_count and has_nonzero:
        return (count, count * 4)
    return None


def find_zero_run(data, pos, min_bytes=4):
    """Find a run of zero bytes at pos. Returns length or 0."""
    end = pos
    while end < len(data) and data[end] == 0x00:
        end += 1
    length = end - pos
    return length if length >= min_bytes else 0


# ── Segment classification ─────────────────────────────────────────────

class Segment:
    """A classified data segment."""
    def __init__(self, offset, size, kind, **kwargs):
        self.offset = offset
        self.size = size
        self.kind = kind  # 'widget', 'dispatch', 'string', 'ptr_table',
                          # 'padding', 'raw_u16', 'string_pair', 'raw_bytes'
        self.extra = kwargs

    def __repr__(self):
        return f"Segment({self.kind}, off=0x{self.offset:04X}, size={self.size})"


def classify_data(data, base_addr, symbols):
    """Classify all bytes in data into segments using forward scanning.

    Strategy: scan from position 0, greedily identify the element at each
    position (widget, string pair, string, pointer table, padding, raw),
    advance past it, repeat.
    """
    total_size = len(data)
    segments = []
    pos = 0

    while pos < total_size:
        remaining = total_size - pos

        # 1. Try NAKA widget header
        if remaining >= 4 and is_naka_header(data, pos):
            type_code = data[pos]
            seg = _try_widget(data, pos, type_code, total_size)
            if seg:
                segments.append(seg)
                pos += seg.size
                continue

        # 2. Try zero padding (at least 4 bytes)
        zero_len = find_zero_run(data, pos, min_bytes=4)
        if zero_len > 0:
            segments.append(Segment(pos, zero_len, 'padding'))
            pos += zero_len
            continue

        # 3. Try string pair (code + name)
        pair = _try_string_pair(data, pos, total_size)
        if pair:
            code_text, code_size, name_text, name_size = pair
            segments.append(Segment(pos, code_size + name_size, 'string_pair',
                                    code_text=code_text, code_size=code_size,
                                    name_text=name_text, name_size=name_size))
            pos += code_size + name_size
            continue

        # 4. Try single string
        result = find_string_at(data, pos)
        if result:
            text, size = result
            segments.append(Segment(pos, size, 'string', text=text))
            pos += size
            continue

        # 5. Try pointer table (3+ consecutive pointers)
        ptr_result = find_pointer_table_at(data, pos, min_count=3)
        if ptr_result:
            count, size = ptr_result
            segments.append(Segment(pos, size, 'ptr_table', count=count))
            pos += size
            continue

        # 6. Try small zero padding (2-3 bytes)
        zero_len = find_zero_run(data, pos, min_bytes=2)
        if zero_len > 0:
            segments.append(Segment(pos, zero_len, 'padding'))
            pos += zero_len
            continue

        # 7. Try single pointer (4-byte value that looks like ROM address)
        if remaining >= 4:
            val = struct.unpack_from('<I', data, pos)[0]
            if is_pointer_value(val):
                segments.append(Segment(pos, 4, 'ptr_single', value=val))
                pos += 4
                continue

        # 8. Raw uint16
        if remaining >= 2:
            val = struct.unpack_from('<H', data, pos)[0]
            segments.append(Segment(pos, 2, 'raw_u16', value=val))
            pos += 2
            continue

        # 9. Single byte fallback
        segments.append(Segment(pos, 1, 'raw_bytes'))
        pos += 1

    return segments


def _try_widget(data, pos, type_code, total_size):
    """Try to classify a NAKA widget starting at pos."""
    # Check for dispatch layout first:
    # If the next NAKA header is at pos+24, this is a dispatch widget
    # (even for types like 0x34/0x31 that can also be larger structs)
    if pos + 24 <= total_size:
        next_is_header = (pos + 24 + 4 <= total_size and
                          is_naka_header(data, pos + 24))
        is_dispatch = (type_code in DISPATCH_TYPES or
                       (type_code in AMBIGUOUS_TYPES and next_is_header) or
                       _check_dispatch_body(data, pos))
        # For ambiguous types, prefer dispatch if next header is at +24
        if type_code in AMBIGUOUS_TYPES:
            if next_is_header:
                return Segment(pos, 24, 'dispatch', type_code=type_code)
            # Otherwise fall through to known type handling
        elif is_dispatch:
            return Segment(pos, 24, 'dispatch', type_code=type_code)

    if type_code in KNOWN_TYPES:
        struct_name, body_size, fields, has_trailing = KNOWN_TYPES[type_code]
        widget_fixed = 4 + body_size

        if pos + widget_fixed > total_size:
            return None

        # Determine trailing string size
        # Only include trailing string if the data after the body is string-like
        # AND the widget's string_ptr field points to that exact position
        trailing_size = 0
        if has_trailing:
            trail_start = pos + widget_fixed
            result = find_string_at(data, trail_start)
            if result:
                trailing_size = result[1]

        total_widget_size = widget_fixed + trailing_size
        return Segment(pos, total_widget_size, 'widget',
                       type_code=type_code, struct_name=struct_name,
                       body_size=body_size, fields=fields,
                       trailing_size=trailing_size)

    # Unknown widget — can't determine size, skip header only
    return None


def _get_string_ptr(data, widget_pos, fields):
    """Extract the string_ptr value from a widget body."""
    offset = 4  # skip header
    for fname, fsize, is_ptr in fields:
        if fname == "string_ptr":
            if widget_pos + offset + fsize <= len(data):
                return struct.unpack_from('<I', data, widget_pos + offset)[0]
            return None
        offset += fsize
    return None


def _check_dispatch_body(data, pos):
    """Heuristic: does data at pos look like a 24-byte dispatch widget?

    Check pointer fields at offsets 8, 12, 16, 20 (four 32-bit values
    that should all be ROM pointers or NULL).
    """
    if pos + 24 > len(data):
        return False

    has_pointer = False
    for field_off in [8, 12, 16, 20]:
        val = struct.unpack_from('<I', data, pos + field_off)[0]
        if val == 0:
            continue
        if is_pointer_value(val):
            has_pointer = True
        else:
            return False

    return has_pointer



def _try_string_pair(data, pos, end):
    """Try to match a string pair: code_string + name_string.

    Common pattern after dispatch widgets:
    - code string (short, 0-10 chars, bytecodes like "jC", "AAj", "^^cGj")
    - name string (PascalCase identifier like "IvDrawbar", "AcPleaseWait")

    NAKA code strings are bytecodes (no underscores, no ALL_CAPS identifiers).
    NAKA name strings are PascalCase (e.g., AcFoo, IvBar, PsFoo).
    """
    first = find_string_at(data, pos)
    if first is None:
        return None

    first_text, first_size = first
    next_pos = pos + first_size
    if next_pos >= end:
        return None

    second = find_string_at(data, next_pos)
    if second is None:
        return None

    second_text, second_size = second

    # Code string must be short (<=10 chars) and must NOT be an identifier
    # (no underscores, no ALL_CAPS_WORD patterns)
    if (len(first_text) <= 10 and len(second_text) >= 2 and
            _looks_like_naka_code(first_text) and
            _looks_like_naka_name(second_text)):
        return (first_text, first_size, second_text, second_size)

    return None


def _looks_like_naka_code(text):
    """Check if text looks like a NAKA bytecode string.

    Bytecodes are short sequences of lowercase and special chars (j, c, n, ^, X, A).
    They do NOT contain underscores or look like identifiers.
    Empty string is valid (common for simple dispatch widgets).
    """
    if not text:
        return True  # empty code string is common
    if '_' in text:
        return False  # bytecodes don't have underscores
    # If it's all uppercase and > 3 chars, it's probably an identifier, not bytecode
    if len(text) > 3 and text.isupper():
        return False
    return True


def _looks_like_naka_name(text):
    """Check if text looks like a NAKA instance name.

    NAKA names are PascalCase identifiers: IvFoo, AcBar, PsFoo, VwBaz, etc.
    They do NOT have underscores (those are event names like EV_FOO, MT_Foo).
    """
    if not text or len(text) < 2:
        return False
    if '_' in text:
        return False  # event names (EV_*, MT_*) are not NAKA instance names
    if ' ' in text:
        return False
    # Must start with uppercase letter followed by lowercase
    if text[0].isupper() and len(text) >= 2 and text[1].islower():
        return True
    return False


# ── C code generation ──────────────────────────────────────────────────

def format_u16(val):
    """Format a uint16_t value for C initializer."""
    if val == 0xFFFF:
        return "NAKA_NONE"
    elif val == 0:
        return "0x0000"
    elif val < 256:
        return f"0x{val:04X}"
    else:
        return f"0x{val:04X}"


def format_u32_ptr(val, base_addr, total_size, symbols, field_name_map=None):
    """Format a uint32_t pointer value.

    Returns (formatted_string, extern_symbol_or_None, is_self_ref).
    """
    if val == 0:
        return ("0x00000000", None, False)

    if is_self_pointer(val, base_addr, total_size):
        # Self-reference — will be resolved to SELF(field_name)
        return (f"SELF_PLACEHOLDER_0x{val:08X}", None, True)

    if val in symbols:
        sym = symbols[val]
        return (f"NAKA_ADDR({sym})", sym, False)

    # Non-zero, non-ROM pointer — keep as hex
    if is_pointer_value(val):
        return (f"0x{val:08X}", None, False)

    return (f"0x{val:08X}", None, False)


def format_string_init(text, alloc_size):
    """Format a string field initializer.

    For aligned strings: text + NUL + optional 0xFF pad.
    """
    if not text:
        # Empty string
        if alloc_size == 2:
            return 'ALIGNED_STRING("")'
        else:
            return '""'

    str_len = len(text)
    needs_pad = (str_len + 1) % 2 == 1  # NUL at odd boundary → need 0xFF

    # Escape special chars
    escaped = text.replace('\\', '\\\\').replace('"', '\\"')

    if needs_pad:
        return f'ALIGNED_STRING("{escaped}")'
    else:
        return f'"{escaped}"'


def format_string_init_chararray(text, alloc_size):
    """Format as explicit char array for strings with special handling."""
    if not text:
        if alloc_size == 2:
            return "{ 0, 0xFF }"
        return '""'

    chars = []
    for c in text:
        if c == "'":
            chars.append("'\\''")
        elif c == "\\":
            chars.append("'\\\\'")
        else:
            chars.append(f"'{c}'")

    # Add NUL
    str_with_nul = len(text) + 1
    if str_with_nul % 2 == 1 and alloc_size > str_with_nul:
        # Pad with 0xFF
        return "{ " + ", ".join(chars) + ", 0, 0xFF }"
    else:
        return "{ " + ", ".join(chars) + ", 0 }"


def compute_str_alloc(text):
    """Compute NAKA_STR_ALLOC for a string."""
    str_len = len(text)
    return (str_len + 2) & ~1


def format_raw_hex(data_bytes, indent=8):
    """Format raw bytes as hex array initializer."""
    if not data_bytes:
        return "{ 0 }"
    prefix = ' ' * indent
    if len(data_bytes) <= 12:
        return '{ ' + ', '.join(f'0x{b:02X}' for b in data_bytes) + ' }'
    lines = []
    for i in range(0, len(data_bytes), 12):
        chunk = data_bytes[i:i+12]
        lines.append(prefix + ', '.join(f'0x{b:02X}' for b in chunk))
    return '{\n' + ',\n'.join(lines) + '\n' + ' ' * (indent - 4) + '}'


# ── Main generation ────────────────────────────────────────────────────

class NakaDecoder:
    """Full NAKA file decoder."""

    def __init__(self, rom, symbols, name_to_addr):
        self.rom = rom
        self.symbols = symbols  # addr → name
        self.name_to_addr = name_to_addr  # name → addr
        self.extern_syms = set()  # extern symbols needed
        self.self_refs = {}  # placeholder → field_name mapping

    def decode_file(self, c_file_path):
        """Decode an existing NAKA C file.

        Returns (c_content, ld_content, base_addr, total_size).
        """
        # Parse existing file for base address and total size
        base_addr, total_size, output_name = self._parse_existing_file(c_file_path)
        print(f"  Base: 0x{base_addr:06X}, Size: {total_size}, Name: {output_name}")

        # Read ROM bytes
        rom_offset = base_addr - ROM_BASE
        data = bytes(self.rom[rom_offset:rom_offset + total_size])
        assert len(data) == total_size, f"ROM read error: got {len(data)}, expected {total_size}"

        # Classify data into segments
        segments = classify_data(data, base_addr, self.symbols)
        print(f"  Segments: {len(segments)}")
        for kind in set(s.kind for s in segments):
            count = sum(1 for s in segments if s.kind == kind)
            size = sum(s.size for s in segments if s.kind == kind)
            print(f"    {kind}: {count} segments, {size} bytes")

        # Verify all bytes accounted for
        total_classified = sum(s.size for s in segments)
        assert total_classified == total_size, \
            f"Classification error: {total_classified} != {total_size}"

        # Generate output
        c_content = self._generate_c(segments, data, base_addr, total_size, output_name)
        ld_content = self._generate_linker_script(output_name)

        return c_content, ld_content, base_addr, total_size

    def _parse_existing_file(self, path):
        """Extract base address and size from existing C file."""
        with open(path, 'rb') as f:
            content = f.read().decode('latin-1')

        # Find base address
        base_addr = None
        m = re.search(r'Base ROM address:\s*0x([0-9A-Fa-f]+)', content)
        if m:
            base_addr = int(m.group(1), 16)
        if base_addr is None:
            # ROM address range: 0xEACCDA-0xEAD470
            m = re.search(r'ROM address range:\s*0x([0-9A-Fa-f]+)\s*-\s*0x([0-9A-Fa-f]+)', content)
            if m:
                base_addr = int(m.group(1), 16)
        if base_addr is None:
            m = re.search(r'#define\s+BASE\s+0x0*([0-9A-Fa-f]+)', content)
            if m:
                base_addr = int(m.group(1), 16)
        if base_addr is None:
            raise ValueError(f"Cannot find base address in {path}")

        # Find total size
        total_size = None
        m = re.search(r'Total size:\s*(\d+)', content)
        if m:
            total_size = int(m.group(1))
        if total_size is None:
            m = re.search(r'sizeof\([^)]+\)\s*==\s*(\d+)', content)
            if m:
                total_size = int(m.group(1))
        if total_size is None:
            # Compute from address range
            m = re.search(r'ROM address range:\s*0x([0-9A-Fa-f]+)\s*-\s*0x([0-9A-Fa-f]+)', content)
            if m:
                total_size = int(m.group(2), 16) - int(m.group(1), 16)
        if total_size is None:
            # Try from #define BASE and _Static_assert
            m = re.search(r'(\d+) bytes', content)
            if m:
                total_size = int(m.group(1))
        if total_size is None:
            raise ValueError(f"Cannot find total size in {path}")

        # Get output name
        stem = Path(path).stem
        output_name = stem

        return base_addr, total_size, output_name

    def _generate_c(self, segments, data, base_addr, total_size, output_name):
        """Generate the complete C file."""
        self.extern_syms = set()
        self.self_refs = {}

        # Name segments for field references
        field_defs = []   # (field_name, c_type, size, comment)
        field_inits = []  # (field_name, init_string)
        widget_idx = 0
        string_idx = 0
        ptr_table_idx = 0
        pad_idx = 0
        raw_idx = 0

        # First pass: assign field names and collect self-references
        field_names = {}  # offset → field_name
        for seg in segments:
            if seg.kind in ('dispatch', 'widget'):
                name = f"w{widget_idx}"
                field_names[seg.offset] = name
                widget_idx += 1
            elif seg.kind == 'widget_generic':
                name = f"w{widget_idx}"
                field_names[seg.offset] = name
                widget_idx += 1
            elif seg.kind == 'string_pair':
                code_name = f"w{widget_idx}_code"  # code goes with prev widget
                name_name = f"w{widget_idx}_name"
                # Actually, string pairs follow dispatch widgets — use previous widget index
                # We'll fix this in a second pass
                field_names[seg.offset] = code_name
                field_names[seg.offset + seg.extra['code_size']] = name_name
                widget_idx += 1
            elif seg.kind == 'string':
                name = f"str_{string_idx}"
                field_names[seg.offset] = name
                string_idx += 1
            elif seg.kind == 'ptr_table':
                name = f"ptrs_{ptr_table_idx}"
                field_names[seg.offset] = name
                ptr_table_idx += 1
            elif seg.kind == 'padding':
                name = f"pad_{pad_idx}"
                field_names[seg.offset] = name
                pad_idx += 1
            elif seg.kind == 'raw_u16':
                name = f"field_{seg.offset:04x}"
                field_names[seg.offset] = name
                raw_idx += 1
            elif seg.kind == 'ptr_single':
                name = f"ptr_{seg.offset:04x}"
                field_names[seg.offset] = name
            else:
                name = f"raw_{seg.offset:04x}"
                field_names[seg.offset] = name

        # Better naming: link string pairs to their dispatch widgets
        self._link_string_pairs_to_widgets(segments, data, base_addr, field_names)

        # Resolve SELF references
        self._resolve_self_references(segments, data, base_addr, total_size, field_names)

        # Second pass: generate struct fields and initializers
        for seg in segments:
            fname = field_names.get(seg.offset, f"unk_{seg.offset:04x}")
            seg_data = data[seg.offset:seg.offset + seg.size]

            if seg.kind == 'dispatch':
                type_code = seg.extra['type_code']
                self._emit_dispatch(fname, type_code, seg_data, seg.offset,
                                    base_addr, total_size, field_defs, field_inits)

            elif seg.kind == 'widget':
                type_code = seg.extra['type_code']
                struct_name = seg.extra['struct_name']
                body_size = seg.extra['body_size']
                fields = seg.extra['fields']
                trailing_size = seg.extra['trailing_size']
                self._emit_known_widget(fname, type_code, struct_name, body_size,
                                        fields, trailing_size, seg_data, seg.offset,
                                        base_addr, total_size, field_defs, field_inits)

            elif seg.kind == 'widget_generic':
                type_code = seg.extra['type_code']
                self._emit_generic_widget(fname, type_code, seg_data, seg.offset,
                                          base_addr, total_size, field_defs, field_inits)

            elif seg.kind == 'string_pair':
                code_text = seg.extra['code_text']
                code_size = seg.extra['code_size']
                name_text = seg.extra['name_text']
                name_size = seg.extra['name_size']
                code_fname = field_names.get(seg.offset, f"{fname}_code")
                name_fname = field_names.get(seg.offset + code_size, f"{fname}_name")
                self._emit_string_pair(code_fname, name_fname,
                                       code_text, code_size, name_text, name_size,
                                       field_defs, field_inits)

            elif seg.kind == 'string':
                text = seg.extra['text']
                self._emit_string(fname, text, seg.size, field_defs, field_inits)

            elif seg.kind == 'ptr_table':
                count = seg.extra['count']
                self._emit_ptr_table(fname, count, seg_data, seg.offset,
                                     base_addr, total_size, field_defs, field_inits)

            elif seg.kind == 'padding':
                field_defs.append((fname, f"uint8_t {fname}[{seg.size}]", seg.size,
                                   "/* zero padding */"))
                field_inits.append((fname, "{ 0 }", None))

            elif seg.kind == 'raw_u16':
                val = seg.extra['value']
                field_defs.append((fname, f"uint16_t {fname}", 2, None))
                field_inits.append((fname, format_u16(val), None))

            elif seg.kind == 'ptr_single':
                val = seg.extra['value']
                fmt, sym, is_self = format_u32_ptr(val, base_addr, total_size,
                                                    self.symbols, field_names)
                if sym:
                    self.extern_syms.add(sym)
                if is_self:
                    fmt = self._resolve_self(val, base_addr, field_names)
                field_defs.append((fname, f"uint32_t {fname}", 4, None))
                field_inits.append((fname, fmt, None))

            else:
                # Raw bytes
                field_defs.append((fname, f"uint8_t {fname}[{seg.size}]", seg.size, None))
                field_inits.append((fname, format_raw_hex(seg_data), None))

        # ── Assemble output ────────────────────────────────────────────
        lines = []
        lines.append(f'/**')
        lines.append(f' * {output_name}.c — NAKA widget descriptors (fully decoded)')
        lines.append(f' *')
        lines.append(f' * Base ROM address: 0x{base_addr:06X}')
        lines.append(f' * Total size: {total_size} bytes')
        lines.append(f' * Auto-generated by scripts/naka_struct_decode.py')
        lines.append(f' */')
        lines.append(f'')
        lines.append(f'#include "naka_types.h"')
        lines.append(f'')

        # Extern declarations
        if self.extern_syms:
            lines.append(f'/* ── External symbols (resolved by linker script) ── */')
            lines.append(f'')
            for sym in sorted(self.extern_syms):
                lines.append(f'extern const char {sym};')
            lines.append(f'')

        # Base address and struct
        lines.append(f'#define BASE  0x{base_addr:08X}u')
        lines.append(f'')
        lines.append(f'typedef struct __attribute__((packed)) {{')

        for fname, c_type, size, comment in field_defs:
            if comment:
                lines.append(f'    {c_type};  {comment}')
            else:
                lines.append(f'    {c_type};')

        lines.append(f'}} {output_name}_t;')
        lines.append(f'')
        lines.append(f'#define SELF(field) \\')
        lines.append(f'    ((uint32_t)(BASE + __builtin_offsetof({output_name}_t, field)))')
        lines.append(f'')
        lines.append(f'_Static_assert(sizeof({output_name}_t) == {total_size},')
        lines.append(f'    "{output_name} must be exactly {total_size} bytes");')
        lines.append(f'')
        lines.append(f'const {output_name}_t {output_name}_data')
        lines.append(f'    __attribute__((section(".text"), used)) = {{')
        lines.append(f'')

        # Initializers
        for fname, init_str, comment in field_inits:
            if comment:
                lines.append(f'    /* {comment} */')
            if '\n' in init_str:
                # Multi-line initializer
                lines.append(f'    .{fname} = {init_str},')
            else:
                lines.append(f'    .{fname} = {init_str},')
            lines.append(f'')

        lines.append(f'}};')
        lines.append(f'')
        lines.append(f'#undef SELF')
        lines.append(f'#undef BASE')
        lines.append(f'')

        return '\n'.join(lines)

    def _link_string_pairs_to_widgets(self, segments, data, base_addr, field_names):
        """Assign better names to string pairs by linking them to dispatch widgets."""
        # Build list of dispatch widgets and their name_ptr/inst_ptr targets
        dispatches = []
        for seg in segments:
            if seg.kind == 'dispatch':
                seg_data = data[seg.offset:seg.offset + seg.size]
                name_ptr = struct.unpack_from('<I', seg_data, 8)[0]
                inst_ptr = struct.unpack_from('<I', seg_data, 12)[0]
                dispatches.append((seg.offset, name_ptr, inst_ptr))

        # Match string pairs to dispatch widgets
        for seg in segments:
            if seg.kind == 'string_pair':
                name_text = seg.extra['name_text']
                code_size = seg.extra['code_size']
                pair_addr = base_addr + seg.offset
                code_addr = pair_addr
                name_addr = pair_addr + code_size

                # Find which dispatch widget points to this string pair
                matched_widget = None
                for widx, (woff, wname_ptr, winst_ptr) in enumerate(dispatches):
                    if wname_ptr == name_addr or winst_ptr == code_addr:
                        matched_widget = widx
                        break

                if matched_widget is not None and name_text:
                    # Use the name_text as the field name base
                    clean_name = name_text.replace(' ', '_')
                    code_fname = f"{clean_name}_code"
                    name_fname = f"{clean_name}_name"
                    field_names[seg.offset] = code_fname
                    field_names[seg.offset + code_size] = name_fname

    def _resolve_self_references(self, segments, data, base_addr, total_size, field_names):
        """Build offset→field_name map for SELF() resolution."""
        self._offset_to_field = {}
        for offset, fname in field_names.items():
            addr = base_addr + offset
            self._offset_to_field[addr] = fname

    def _resolve_self(self, val, base_addr, field_names):
        """Resolve a self-referential pointer to SELF(field_name)."""
        offset = val - base_addr
        if val in self._offset_to_field:
            return f"SELF({self._offset_to_field[val]})"
        # Fallback: try nearby offsets (within a struct that was classified together)
        for addr, fname in self._offset_to_field.items():
            if addr == val:
                return f"SELF({fname})"
        return f"0x{val:08X}"

    def _emit_dispatch(self, fname, type_code, seg_data, offset,
                       base_addr, total_size, field_defs, field_inits):
        """Emit a dispatch widget (24 bytes)."""
        type_str = NAMED_TYPE_CODES.get(type_code, f"0x{type_code:02X}")

        field_defs.append((fname, f"naka_dispatch_t {fname}", 24,
                           f"/* {type_str} */"))

        # Build initializer
        body = seg_data[4:]  # skip header
        init_lines = []
        init_lines.append(f"{{")
        init_lines.append(f"        .header    = NAKA_HDR({type_str}),")

        foff = 0
        for field_name, fsize, is_ptr in DISPATCH_FIELDS:
            if fsize == 2:
                val = struct.unpack_from('<H', body, foff)[0]
                init_lines.append(f"        .{field_name:<10s} = {format_u16(val)},")
            elif fsize == 4:
                val = struct.unpack_from('<I', body, foff)[0]
                fmt, sym, is_self = format_u32_ptr(val, base_addr, total_size,
                                                    self.symbols)
                if sym:
                    self.extern_syms.add(sym)
                if is_self:
                    fmt = self._resolve_self(val, base_addr, {})
                init_lines.append(f"        .{field_name:<10s} = {fmt},")
            foff += fsize

        init_lines.append(f"    }}")
        field_inits.append((fname, '\n'.join(init_lines), None))

    def _emit_known_widget(self, fname, type_code, struct_name, body_size,
                           fields, trailing_size, seg_data, offset,
                           base_addr, total_size, field_defs, field_inits):
        """Emit a known-type widget with named fields."""
        type_str = NAMED_TYPE_CODES.get(type_code, f"0x{type_code:02X}")

        field_defs.append((fname, f"{struct_name} {fname}", 4 + body_size,
                           f"/* {type_str} */"))

        body = seg_data[4:4 + body_size]

        # Check for trailing string — verify string_ptr actually points to it
        has_text = trailing_size > 0
        use_self_for_string = False
        text_fname = f"{fname}_text"

        if has_text:
            trail_data = seg_data[4 + body_size:]
            result = find_string_at(trail_data, 0)
            if result:
                trail_text, trail_alloc = result
            else:
                trail_text = None

            # Check if string_ptr points to the trailing data
            trail_addr = base_addr + offset + 4 + body_size
            string_ptr_val = _get_string_ptr(seg_data, 0, fields)
            if string_ptr_val is not None and string_ptr_val == trail_addr:
                use_self_for_string = True

            field_defs.append((text_fname, f"char {text_fname}[{trailing_size}]",
                               trailing_size, None))

        # Build initializer
        init_lines = []
        init_lines.append(f"{{")
        init_lines.append(f"        .header       = NAKA_HDR({type_str}),")

        foff = 0
        for field_name, fsize, is_ptr in fields:
            if fsize == 2:
                val = struct.unpack_from('<H', body, foff)[0]
                init_lines.append(f"        .{field_name:<14s} = {format_u16(val)},")
            elif fsize == 4:
                val = struct.unpack_from('<I', body, foff)[0]
                # Special case: string_ptr with trailing text → SELF()
                if field_name == "string_ptr" and has_text and use_self_for_string:
                    init_lines.append(f"        .{field_name:<14s} = SELF({text_fname}),")
                else:
                    fmt, sym, is_self = format_u32_ptr(val, base_addr, total_size,
                                                        self.symbols)
                    if sym:
                        self.extern_syms.add(sym)
                    if is_self:
                        fmt = self._resolve_self(val, base_addr, {})
                    init_lines.append(f"        .{field_name:<14s} = {fmt},")
            foff += fsize

        init_lines.append(f"    }}")
        field_inits.append((fname, '\n'.join(init_lines), None))

        # Trailing string initializer
        if has_text:
            trail_data = seg_data[4 + body_size:]
            if trail_text is not None:
                init = format_string_init(trail_text, trailing_size)
                # Check if ALIGNED_STRING or bare string works
                # For bare string with special chars, use char array
                if any(b > 0x7E for b in trail_data if b != 0x00 and b != 0xFF):
                    init = format_raw_hex(trail_data)
                field_inits.append((text_fname, init, None))
            else:
                field_inits.append((text_fname, format_raw_hex(trail_data), None))

    def _emit_generic_widget(self, fname, type_code, seg_data, offset,
                             base_addr, total_size, field_defs, field_inits):
        """Emit a widget of unknown type with uint16_t/uint32_t fields."""
        type_str = f"0x{type_code:02X}"

        # Try to decode body as uint16_t fields with pointer detection
        hdr_fname = f"{fname}_hdr"
        body_fname = f"{fname}_body"
        body = seg_data[4:]

        field_defs.append((hdr_fname, f"naka_header_t {hdr_fname}", 4,
                           f"/* TYPE_{type_str} */"))
        field_inits.append((hdr_fname, f"NAKA_HDR({type_str})", None))

        if body:
            field_defs.append((body_fname, f"uint8_t {body_fname}[{len(body)}]",
                               len(body), None))
            field_inits.append((body_fname, format_raw_hex(body), None))

    def _emit_string_pair(self, code_fname, name_fname,
                          code_text, code_size, name_text, name_size,
                          field_defs, field_inits):
        """Emit a code+name string pair."""
        field_defs.append((code_fname, f"char {code_fname}[{code_size}]",
                           code_size, None))
        field_defs.append((name_fname, f"char {name_fname}[{name_size}]",
                           name_size, None))

        code_init = format_string_init(code_text, code_size)
        name_init = format_string_init(name_text, name_size)

        field_inits.append((code_fname, code_init, None))
        field_inits.append((name_fname, name_init, None))

    def _emit_string(self, fname, text, size, field_defs, field_inits):
        """Emit a single string field."""
        field_defs.append((fname, f"char {fname}[{size}]", size, None))
        init = format_string_init(text, size)
        field_inits.append((fname, init, None))

    def _emit_ptr_table(self, fname, count, seg_data, offset,
                        base_addr, total_size, field_defs, field_inits):
        """Emit a pointer table."""
        field_defs.append((fname, f"uint32_t {fname}[{count}]",
                           count * 4, f"/* {count} pointers */"))

        init_lines = []
        init_lines.append("{")
        for i in range(count):
            val = struct.unpack_from('<I', seg_data, i * 4)[0]
            fmt, sym, is_self = format_u32_ptr(val, base_addr, total_size,
                                                self.symbols)
            if sym:
                self.extern_syms.add(sym)
            if is_self:
                fmt = self._resolve_self(val, base_addr, {})
            init_lines.append(f"        {fmt},")
        init_lines.append("    }")
        field_inits.append((fname, '\n'.join(init_lines), None))

    def _generate_linker_script(self, output_name):
        """Generate linker script for extern symbols."""
        lines = []
        lines.append(f'/* {output_name}_link.ld — Linker script for {output_name}.c')
        lines.append(f' * Auto-generated by scripts/naka_struct_decode.py')
        lines.append(f' */')
        lines.append(f'')
        lines.append(f'ENTRY(0)')
        lines.append(f'')
        lines.append(f'SECTIONS {{')
        lines.append(f'    .text : {{ *(.text*) *(.rodata*) }}')
        lines.append(f'    /DISCARD/ : {{ *(.comment) *(.note*) *(.eh_frame*) }}')
        lines.append(f'}}')
        lines.append(f'')

        if self.extern_syms:
            for sym in sorted(self.extern_syms):
                if sym in self.name_to_addr:
                    lines.append(f'{sym} = 0x{self.name_to_addr[sym]:08X};')
                else:
                    lines.append(f'/* WARNING: {sym} not found in ELF */')
            lines.append(f'')

        return '\n'.join(lines)


# ── Main entry point ───────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Full NAKA widget C struct decoder')
    parser.add_argument('input', nargs='?', help='Input .c file path')
    parser.add_argument('--file', '-f', help='File name (looked up in ui_widgets/)')
    parser.add_argument('--dry-run', action='store_true', help='Print without writing')
    parser.add_argument('--verify', action='store_true', help='Build and verify byte match')
    args = parser.parse_args()

    if args.file:
        input_path = WIDGETS_DIR / args.file
    elif args.input:
        input_path = Path(args.input)
    else:
        parser.error("Provide input file or --file name")

    if not input_path.exists():
        print(f"ERROR: {input_path} not found")
        sys.exit(1)

    print(f"Loading symbols from ELF...")
    symbols, names = load_symbols()
    print(f"  {len(symbols)} symbols loaded")

    print(f"Loading ROM...")
    rom = load_rom()
    print(f"  {len(rom)} bytes loaded")

    print(f"Decoding {input_path.name}...")
    decoder = NakaDecoder(rom, symbols, names)
    c_content, ld_content, base_addr, total_size = decoder.decode_file(str(input_path))

    if args.dry_run:
        print(f"\n{'='*60}")
        print(f"=== C FILE ({len(c_content)} chars) ===")
        print(f"{'='*60}")
        # Print first 5000 chars
        if len(c_content) > 5000:
            print(c_content[:5000])
            print(f"\n... ({len(c_content) - 5000} more chars)")
        else:
            print(c_content)
        print(f"\n{'='*60}")
        print(f"=== LINKER SCRIPT ===")
        print(f"{'='*60}")
        print(ld_content)
    else:
        c_path = input_path
        ld_path = input_path.parent / f"{input_path.stem}_link.ld"

        with open(c_path, 'w') as f:
            f.write(c_content)
        print(f"  Written: {c_path}")

        with open(ld_path, 'w') as f:
            f.write(ld_content)
        print(f"  Written: {ld_path}")

    if args.verify and not args.dry_run:
        print(f"\nVerifying byte match...")
        ok = verify_build(input_path, base_addr, total_size, rom)
        if ok:
            print(f"  ✓ BYTE MATCH VERIFIED")
        else:
            print(f"  ✗ BYTE MISMATCH!")
            sys.exit(1)

    print(f"\nDone. {len(decoder.extern_syms)} extern symbols.")


def verify_build(c_path, base_addr, total_size, rom):
    """Build the C file and verify it matches the original ROM bytes."""
    import tempfile

    stem = c_path.stem
    ld_path = c_path.parent / f"{stem}_link.ld"
    bin_path = c_path.parent.parent / "includes" / "generated" / f"{stem}.bin"

    # Build
    clang = "/mnt/shared/llvm-project/build/bin/clang"
    lld = "/mnt/shared/llvm-project/build/bin/ld.lld"
    objcopy = "/mnt/shared/llvm-project/build/bin/llvm-objcopy"

    obj_path = f"/tmp/{stem}.o"
    elf_path = f"/tmp/{stem}.elf"

    try:
        # Compile
        r = subprocess.run([clang, "-target", "tlcs900", "-ffreestanding", "-c", "-O2",
                           "-I", str(c_path.parent), "-o", obj_path, str(c_path)],
                          capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  Compile error: {r.stderr[:500]}")
            return False

        # Link
        r = subprocess.run([lld, "-T", str(ld_path), "-o", elf_path, obj_path],
                          capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  Link error: {r.stderr[:500]}")
            return False

        # Extract binary
        bin_out = f"/tmp/{stem}.bin"
        r = subprocess.run([objcopy, "-O", "binary", "-j", ".text", elf_path, bin_out],
                          capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  Objcopy error: {r.stderr[:500]}")
            return False

        # Compare
        with open(bin_out, 'rb') as f:
            built = f.read()

        rom_offset = base_addr - ROM_BASE
        expected = rom[rom_offset:rom_offset + total_size]

        if built == expected:
            return True

        # Find first mismatch
        for i in range(min(len(built), len(expected))):
            if built[i] != expected[i]:
                print(f"  First mismatch at offset 0x{i:04X}: "
                      f"built=0x{built[i]:02X} expected=0x{expected[i]:02X}")
                # Show context
                start = max(0, i - 4)
                end = min(len(built), i + 8)
                print(f"  Built:    {' '.join(f'{b:02X}' for b in built[start:end])}")
                print(f"  Expected: {' '.join(f'{b:02X}' for b in expected[start:end])}")
                break

        if len(built) != len(expected):
            print(f"  Size mismatch: built={len(built)}, expected={len(expected)}")

        return False

    finally:
        for p in [obj_path, elf_path, f"/tmp/{stem}.bin"]:
            try:
                os.unlink(p)
            except FileNotFoundError:
                pass


if __name__ == '__main__':
    main()
