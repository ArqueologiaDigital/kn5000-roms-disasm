#!/usr/bin/env python3
"""
naka_to_c.py — Convert NAKA widget assembly data to C structs

Reads a .s file containing NAKA widget descriptors, extracts the byte layout
from the ROM binary, and generates a C source file with packed struct
initializers using named fields for known types and raw byte arrays for
unknown types.

Usage:
    python scripts/naka_to_c.py <input.s> [--start-line N] [--end-line N]

The script:
1. Parses the .s file to find naka_header blocks and their types
2. Reads the ROM binary to get exact bytes
3. Looks up symbol addresses from the ELF
4. Generates a .c file with struct initializers
5. Generates a linker script for extern references
"""

import sys
import os
import re
import struct
import subprocess
from pathlib import Path

# Paths
ROMS_DIR = Path(__file__).parent.parent
ROM_PATH = Path("/mnt/shared/kn5000_original_roms/kn5000/kn5000_v10_program.rom")
ELF_PATH = ROMS_DIR / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"
LLVM_NM = Path("/mnt/shared/llvm-project/build/bin/llvm-nm")
ROM_BASE = 0xE00000  # maincpu ROM maps to 0xE00000-0xFFFFFF

# Known widget type sizes (body size AFTER the 4-byte header, before any trailing string)
# These are the fixed-body types with known struct layouts
KNOWN_TYPES = {
    0x34: ("naka_container_t", 38),   # CONTAINER
    0x1D: ("naka_menu_item_t", 50),   # MENU_ITEM
    0x2B: ("naka_label_t", 28),       # LABEL
    0x30: ("naka_slider_t", 40),      # SLIDER
    0x31: ("naka_group_t", 22),       # GROUP
    0x48: ("naka_type_0x48_t", 22),   # TYPE_0x48
}

# Field definitions for known types (field_name, size_bytes, is_pointer)
CONTAINER_FIELDS = [
    ("parent_idx", 2, False), ("self_idx", 2, False),
    ("next_sibling", 2, False), ("prev_sibling", 2, False),
    ("child_count", 2, False), ("field_0e", 2, False), ("field_10", 2, False),
    ("handler", 4, True), ("style", 2, False), ("field_18", 2, False),
    ("field_1a", 2, False), ("screen_id", 2, False),
    ("handler_table", 4, False), ("string_ptr", 4, True),
    ("string_id", 2, False), ("reserved", 2, False),
]

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

LABEL_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_offset", 2, False), ("field_0e", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("string_ptr", 4, True),
    ("flags", 2, False), ("field_1a", 2, False),
    ("bg_color", 2, False),
]

GROUP_FIELDS = [
    ("parent_idx", 2, False), ("field_06", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("x_offset", 2, False), ("y_offset", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("field_16", 2, False),
    ("field_18", 2, False),
]

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

TYPE_0x48_FIELDS = [
    ("parent_idx", 2, False), ("prev_sibling", 2, False),
    ("self_idx", 2, False), ("next_sibling", 2, False),
    ("field_0c", 2, False), ("field_0e", 2, False),
    ("field_10", 2, False), ("field_12", 2, False),
    ("field_14", 2, False), ("field_16", 2, False),
    ("field_18", 2, False),
]

FIELD_DEFS = {
    0x34: CONTAINER_FIELDS,
    0x1D: MENU_ITEM_FIELDS,
    0x2B: LABEL_FIELDS,
    0x30: SLIDER_FIELDS,
    0x31: GROUP_FIELDS,
    0x48: TYPE_0x48_FIELDS,
}

# NAKA type name mapping
TYPE_NAMES = {
    0x16: "DIAGLIST", 0x1D: "MENU_ITEM", 0x1E: "PANEL",
    0x2B: "LABEL", 0x2E: "VALUE", 0x2F: "OPTION",
    0x30: "SLIDER", 0x31: "GROUP", 0x34: "CONTAINER",
    0x48: "0x48", 0x66: "LIST", 0x6C: "BITMAP",
}


def load_symbols():
    """Load symbol table from ELF."""
    result = subprocess.run(
        [str(LLVM_NM), "--no-sort", str(ELF_PATH)],
        capture_output=True, text=True
    )
    symbols = {}  # addr -> name
    names = {}    # name -> addr
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            symbols[addr] = name
            names[name] = addr
    return symbols, names


def load_rom():
    """Load ROM binary."""
    with open(ROM_PATH, 'rb') as f:
        return f.read()


def parse_assembly(filepath, start_line=0, end_line=None):
    """Parse assembly file to extract widget info.

    Returns list of widget descriptors:
    [
        {
            'type': int,          # NAKA type code
            'type_name': str,     # e.g. 'NAKA_TYPE_CONTAINER'
            'line': int,          # line number in source
            'labels_before': [],  # labels defined before this widget
            'labels_inside': [],  # labels defined within (inline strings)
            'has_long': bool,     # has .long references
            'long_labels': [],    # label names from .long directives
        },
        ...
    ]
    Also returns:
    - preamble_labels: labels before the first widget
    - postamble_labels: labels after the last widget
    """
    with open(filepath, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    if end_line is None:
        end_line = len(lines)

    widgets = []
    preamble_labels = []
    current_labels = []
    in_widget = False
    current_widget = None

    type_pattern = re.compile(r'naka_header\s+(\S+)')
    label_pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s')
    long_pattern = re.compile(r'\.long\s+(\S+)')
    type_const_pattern = re.compile(r'NAKA_TYPE_(\S+)')

    for i, line in enumerate(lines):
        if i < start_line or i >= end_line:
            continue

        stripped = line.strip()

        # Check for label definitions
        m = label_pattern.match(line)
        if m:
            label_name = m.group(1)
            if current_widget is not None:
                current_widget['labels_inside'].append(label_name)
            else:
                current_labels.append(label_name)

        # Check for naka_header
        m = type_pattern.search(stripped)
        if m:
            # Save previous widget
            if current_widget is not None:
                widgets.append(current_widget)

            type_str = m.group(1)
            # Parse type code
            tm = type_const_pattern.match(type_str)
            if tm:
                type_suffix = tm.group(1)
                if type_suffix.startswith('0x'):
                    type_code = int(type_suffix, 16)
                else:
                    # Named type — look up
                    name_to_code = {v: k for k, v in TYPE_NAMES.items()}
                    type_code = name_to_code.get(type_suffix, -1)
            else:
                type_code = -1

            if not widgets and current_labels:
                preamble_labels = current_labels

            current_widget = {
                'type': type_code,
                'type_name': type_str,
                'line': i + 1,
                'labels_before': current_labels if widgets else [],
                'labels_inside': [],
                'has_long': False,
                'long_labels': [],
            }
            current_labels = []
            in_widget = True

        # Check for .long references within widget
        if in_widget and current_widget is not None:
            m = long_pattern.search(stripped)
            if m:
                current_widget['has_long'] = True
                current_widget['long_labels'].append(m.group(1))

    # Save last widget
    if current_widget is not None:
        widgets.append(current_widget)

    return widgets, preamble_labels, current_labels


def compute_assembly_byte_count(filepath, start_line=0, end_line=None):
    """Compute total byte count from assembly directives.

    Counts bytes from: naka_header (4), .byte (N), .long (4),
    aligned_string (len+NUL+pad), .incbin (file size).
    """
    with open(filepath, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    if end_line is None:
        end_line = len(lines)

    total = 0
    byte_pattern = re.compile(r'\.byte\s+(.+)')
    long_pattern = re.compile(r'\.long\s+')
    header_pattern = re.compile(r'naka_header\s+')
    string_pattern = re.compile(r'aligned_string\s+"([^"]*)"')
    incbin_pattern = re.compile(r'\.incbin\s+"([^"]*)"')

    for i, line in enumerate(lines):
        if i < start_line or i >= end_line:
            continue
        stripped = line.strip()

        if header_pattern.search(stripped):
            total += 4
        elif m := byte_pattern.search(stripped):
            # Count comma-separated values
            vals = m.group(1).split(',')
            total += len(vals)
        elif long_pattern.search(stripped):
            total += 4
        elif m := string_pattern.search(stripped):
            text = m.group(1)
            str_len = len(text) + 1  # +NUL
            total += (str_len + 1) & ~1  # align to even
        elif m := incbin_pattern.search(stripped):
            incbin_path = Path(filepath).parent.parent / m.group(1)
            if incbin_path.exists():
                total += incbin_path.stat().st_size

    return total


def scan_rom_for_widgets(rom, start_addr, expected_count, max_bytes=None):
    """Scan ROM bytes for NAKA headers starting at start_addr.

    Returns (leading_bytes, list of (rom_addr, type_code, body_bytes)).
    leading_bytes: bytes before the first widget header (may be empty).
    max_bytes limits the scan range (from assembly byte count).
    """
    offset = start_addr - ROM_BASE
    if max_bytes is None:
        max_scan = min(len(rom) - offset, expected_count * 200)
    else:
        max_scan = min(len(rom) - offset, max_bytes)

    # First pass: find all header positions within range
    header_positions = []
    i = 0
    while i < max_scan - 3:
        if (rom[offset + i + 1] == 0x00 and
            rom[offset + i + 2] == 0x60 and
            rom[offset + i + 3] == 0x01):
            type_code = rom[offset + i]
            if type_code <= 0x6F or type_code >= 0xEC:
                header_positions.append((i, type_code))
        i += 1

    # Take only expected_count headers
    header_positions = header_positions[:expected_count]

    # Extract leading bytes (before first widget header)
    leading = b''
    if header_positions and header_positions[0][0] > 0:
        leading = bytes(rom[offset: offset + header_positions[0][0]])

    # Second pass: extract body bytes between consecutive headers
    widgets = []
    for idx, (pos, type_code) in enumerate(header_positions):
        widget_addr = start_addr + pos
        body_start = pos + 4
        if idx + 1 < len(header_positions):
            body_end = header_positions[idx + 1][0]
        else:
            body_end = max_scan  # last widget extends to end of range
        body = rom[offset + body_start: offset + body_end]
        widgets.append((widget_addr, type_code, bytes(body)))

    return leading, widgets


def format_u16(val):
    """Format a uint16_t value."""
    if val == 0xFFFF:
        return "NAKA_NONE"
    elif val == 0:
        return "0x0000"
    elif val <= 10:
        return f"{val}"
    else:
        return f"0x{val:04X}"


def format_u32(val):
    """Format a uint32_t value."""
    return f"0x{val:08X}"


def generate_known_type_init(type_code, body_bytes, field_defs, self_macro=None,
                              string_field_offset=None, symbols=None):
    """Generate C initializer for a known widget type."""
    lines = []
    offset = 0
    for fname, fsize, is_ptr in field_defs:
        if fsize == 2:
            val = struct.unpack_from('<H', body_bytes, offset)[0]
            if is_ptr and fname == "string_ptr" and self_macro:
                lines.append(f"        .{fname:<14s} = {self_macro},")
            else:
                lines.append(f"        .{fname:<14s} = {format_u16(val)},")
        elif fsize == 4:
            val = struct.unpack_from('<I', body_bytes, offset)[0]
            if is_ptr and fname == "string_ptr" and self_macro:
                lines.append(f"        .{fname:<14s} = {self_macro},")
            elif is_ptr and symbols and val in symbols:
                sym = symbols[val]
                lines.append(f"        .{fname:<14s} = NAKA_ADDR({sym}),")
            else:
                lines.append(f"        .{fname:<14s} = {format_u32(val)},")
        offset += fsize
    return lines


def format_string_bytes(data):
    """Format a char array initializer from raw bytes.

    Handles aligned_string format: string + NUL + optional 0xFF pad.
    """
    # Find NUL terminator
    nul_pos = data.find(b'\x00')
    if nul_pos < 0:
        # No NUL — just raw bytes
        return format_raw_bytes(data)

    string_part = data[:nul_pos]
    remaining = data[nul_pos:]

    # Check if all chars are printable ASCII
    if all(0x20 <= b <= 0x7E for b in string_part):
        text = string_part.decode('ascii')
        # Check for characters that need special handling in C
        has_special = any(b in (0x27, 0x5C, 0x22) for b in string_part)  # ' \ "
        if len(remaining) == 1:
            # Just NUL, no pad — use C string if no special chars
            if not has_special:
                return f'"{text}"'
            else:
                escaped = text.replace('\\', '\\\\').replace('"', '\\"')
                return f'"{escaped}"'
        elif len(remaining) == 2 and remaining[1] == 0xFF:
            # NUL + 0xFF pad — need explicit char array
            if len(string_part) == 0:
                return "{ 0, 0xFF }"
            def fmt_char(b):
                c = chr(b)
                if c == "'":
                    return "'\\''"
                elif c == "\\":
                    return "'\\\\'"
                else:
                    return f"'{c}'"
            chars = ', '.join(fmt_char(b) for b in string_part)
            return f"{{ {chars}, 0, 0xFF }}"
        else:
            # More data after NUL — use raw bytes
            return format_raw_bytes(data)
    elif len(string_part) == 0:
        # Empty string
        if len(remaining) == 1:
            return '""'
        elif len(remaining) == 2 and remaining[1] == 0xFF:
            return "{ 0, 0xFF }"
        else:
            return format_raw_bytes(data)
    else:
        return format_raw_bytes(data)


def format_raw_bytes(data):
    """Format raw bytes as a C array initializer."""
    if not data:
        return "{ 0 }"
    hex_bytes = ', '.join(f"0x{b:02X}" for b in data)
    # Wrap long lines
    if len(data) > 12:
        lines = []
        for i in range(0, len(data), 12):
            chunk = data[i:i+12]
            lines.append('        ' + ', '.join(f"0x{b:02X}" for b in chunk))
        return '{\n' + ',\n'.join(lines) + '\n    }'
    return '{ ' + hex_bytes + ' }'


def compute_string_alloc(text_bytes):
    """Compute aligned_string allocation size.

    aligned_string = NUL-terminated string, 0xFF-padded to even address.
    """
    nul_pos = text_bytes.find(b'\x00')
    if nul_pos < 0:
        return len(text_bytes)
    str_len = nul_pos  # chars before NUL
    alloc = (str_len + 2) & ~1  # round up to even
    return alloc


def generate_c_file(widgets_parsed, rom_widgets, symbols, names,
                     block_base, output_name, extern_symbols,
                     leading_data=b'', trailing_data=b''):
    """Generate the C source file content."""
    lines = []
    lines.append(f'/**')
    lines.append(f' * {output_name}.c — NAKA widget descriptors (C struct conversion)')
    lines.append(f' *')
    lines.append(f' * Auto-generated by scripts/naka_to_c.py')
    lines.append(f' * Base ROM address: 0x{block_base:06X}')
    lines.append(f' * Widget count: {len(rom_widgets)}')
    lines.append(f' */')
    lines.append(f'')
    lines.append(f'#include "naka_types.h"')
    lines.append(f'')

    # Extern declarations
    if extern_symbols:
        lines.append(f'/* External symbol addresses (resolved by linker script) */')
        for sym in sorted(extern_symbols):
            lines.append(f'extern const char {sym};')
        lines.append(f'')

    # Base address
    lines.append(f'#define BASE  0x{block_base:08X}u')
    lines.append(f'')

    # Struct typedef
    lines.append(f'typedef struct __attribute__((packed)) {{')
    total_size = 0
    if leading_data:
        lines.append(f'    uint8_t leading[{len(leading_data)}];')
        total_size += len(leading_data)
    for i, (addr, type_code, body) in enumerate(rom_widgets):
        type_name = TYPE_NAMES.get(type_code, f"0x{type_code:02X}")
        body_size = len(body)

        # Check if this is a known type
        if type_code in KNOWN_TYPES:
            struct_name, known_body_size = KNOWN_TYPES[type_code]
            trailing_size = body_size - known_body_size
            lines.append(f'    {struct_name} w{i};')
            total_size += 4 + known_body_size
            if trailing_size > 0:
                lines.append(f'    char w{i}_text[{trailing_size}];')
                total_size += trailing_size
        else:
            # Generic: header + body as raw bytes
            lines.append(f'    naka_header_t w{i}_hdr;  /* TYPE_{type_name} */')
            if body_size > 0:
                lines.append(f'    uint8_t w{i}_body[{body_size}];')
            total_size += 4 + body_size

    if trailing_data:
        lines.append(f'    uint8_t trailing[{len(trailing_data)}];')
        total_size += len(trailing_data)

    lines.append(f'}} {output_name}_t;')
    lines.append(f'')
    lines.append(f'#define SELF(field) (BASE + __builtin_offsetof({output_name}_t, field))')
    lines.append(f'')
    lines.append(f'_Static_assert(sizeof({output_name}_t) == {total_size},')
    lines.append(f'    "{output_name} must be exactly {total_size} bytes");')
    lines.append(f'')

    # Data initializer
    lines.append(f'const {output_name}_t {output_name}_data')
    lines.append(f'    __attribute__((section(".text"), used)) = {{')
    lines.append(f'')

    if leading_data:
        lines.append(f'    .leading = {format_raw_bytes(leading_data)},')
        lines.append(f'')

    for i, (addr, type_code, body) in enumerate(rom_widgets):
        type_name = TYPE_NAMES.get(type_code, f"0x{type_code:02X}")

        if type_code in KNOWN_TYPES:
            struct_name, known_body_size = KNOWN_TYPES[type_code]
            fields = FIELD_DEFS.get(type_code, [])
            trailing = body[known_body_size:]
            body_part = body[:known_body_size]

            # Determine self-referential string pointer
            self_macro = None
            if trailing and type_code in FIELD_DEFS:
                # Check if there's a string_ptr field that should point to w{i}_text
                for fname, fsize, is_ptr in fields:
                    if fname == "string_ptr" and is_ptr:
                        self_macro = f"SELF(w{i}_text)"
                        break

            field_lines = generate_known_type_init(
                type_code, body_part, fields,
                self_macro=self_macro, symbols=symbols
            )

            lines.append(f'    /* w{i}: {type_name} */')
            # Use named NAKA_TYPE_ constant for known semantic names
            NAMED_TYPES = {0x16, 0x1D, 0x1E, 0x2B, 0x2E, 0x2F, 0x30, 0x31, 0x34, 0x66, 0x6C}
            if type_code in NAMED_TYPES:
                hdr_code = f"NAKA_TYPE_{TYPE_NAMES[type_code]}"
            else:
                hdr_code = f"0x{type_code:02X}"
            lines.append(f'    .w{i} = {{')
            lines.append(f'        .header       = NAKA_HDR({hdr_code}),')
            lines.extend(field_lines)
            lines.append(f'    }},')

            if trailing:
                text_str = format_string_bytes(trailing)
                lines.append(f'    .w{i}_text = {text_str},')
            lines.append(f'')
        else:
            # Generic type
            lines.append(f'    /* w{i}: TYPE_{type_name} */')
            hdr_code = f"0x{type_code:02X}"
            lines.append(f'    .w{i}_hdr = NAKA_HDR({hdr_code}),')
            if body:
                lines.append(f'    .w{i}_body = {format_raw_bytes(body)},')
            lines.append(f'')

    if trailing_data:
        lines.append(f'    .trailing = {format_raw_bytes(trailing_data)},')
        lines.append(f'')

    lines.append(f'}};')
    lines.append(f'')

    return '\n'.join(lines)


def generate_linker_script(extern_symbols, names, output_name):
    """Generate linker script for extern symbol resolution."""
    lines = []
    lines.append(f'/* {output_name}_link.ld — Linker script for {output_name}.c')
    lines.append(f' * Auto-generated by scripts/naka_to_c.py')
    lines.append(f' */')
    lines.append(f'')
    lines.append(f'ENTRY(0)')
    lines.append(f'')
    lines.append(f'SECTIONS {{')
    lines.append(f'    .text : {{ *(.text*) }}')
    lines.append(f'    /DISCARD/ : {{ *(.comment) *(.note*) *(.eh_frame*) }}')
    lines.append(f'}}')
    lines.append(f'')
    for sym in sorted(extern_symbols):
        if sym in names:
            lines.append(f'{sym} = 0x{names[sym]:08X};')
        else:
            lines.append(f'/* WARNING: {sym} not found in ELF */')
    lines.append(f'')
    return '\n'.join(lines)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Convert NAKA widget assembly to C structs')
    parser.add_argument('input', help='Input .s file')
    parser.add_argument('--start-line', type=int, default=0, help='Start line (0-based)')
    parser.add_argument('--end-line', type=int, default=None, help='End line (exclusive)')
    parser.add_argument('--output', help='Output name (default: derived from input)')
    parser.add_argument('--base-addr', help='Base ROM address (hex, e.g. 0xED3C96)')
    parser.add_argument('--end-addr', help='End ROM address (hex, exclusive). Overrides assembly byte count.')
    parser.add_argument('--dry-run', action='store_true', help='Print output without writing files')
    args = parser.parse_args()

    print("Loading symbols from ELF...")
    symbols, names = load_symbols()
    print(f"  {len(symbols)} symbols loaded")

    print("Loading ROM...")
    rom = load_rom()
    print(f"  {len(rom)} bytes loaded")

    print(f"Parsing {args.input}...")
    widgets_parsed, preamble, postamble = parse_assembly(
        args.input, args.start_line, args.end_line
    )
    print(f"  {len(widgets_parsed)} widgets found")

    # Determine output name
    if args.output:
        output_name = args.output
    else:
        base = Path(args.input).stem
        output_name = f"naka_{base}"

    # Determine base address
    if args.base_addr:
        block_base = int(args.base_addr, 16)
    else:
        # Try to find from first label inside a widget
        for w in widgets_parsed:
            for label in w['labels_inside']:
                if label in names:
                    # This label's address is at some offset within the widget block
                    # We'd need to know the offset, which we don't easily have
                    # For now, require --base-addr
                    pass
        print("ERROR: --base-addr required (could not auto-detect)")
        print("  Find it with: llvm-nm rebuilt_ROMs/kn5000_v10_program.llvm.elf | grep <first_label>")
        sys.exit(1)

    # Determine scan range
    if args.end_addr:
        scan_bytes = int(args.end_addr, 16) - block_base
        print(f"  ROM range: 0x{block_base:06X} - {args.end_addr} ({scan_bytes} bytes)")
    else:
        scan_bytes = compute_assembly_byte_count(
            args.input, args.start_line, args.end_line
        )
        print(f"  Assembly byte count: {scan_bytes}")

    # Scan ROM for widgets
    print(f"Scanning ROM at 0x{block_base:06X}...")
    leading_data, rom_widgets = scan_rom_for_widgets(rom, block_base, len(widgets_parsed),
                                                      max_bytes=scan_bytes)
    print(f"  {len(rom_widgets)} widgets found in ROM")
    if leading_data:
        print(f"  {len(leading_data)} leading bytes before first widget")

    if len(rom_widgets) != len(widgets_parsed):
        print(f"  WARNING: assembly has {len(widgets_parsed)} widgets, ROM scan found {len(rom_widgets)}")
        # Use the smaller count
        count = min(len(rom_widgets), len(widgets_parsed))
        rom_widgets = rom_widgets[:count]

    # Collect extern symbols — any pointer field resolved to a known symbol
    # that won't be rendered as SELF() (string_ptr fields with trailing text)
    extern_symbols = set()
    total_block_size = sum(4 + len(b) for _, _, b in rom_widgets)
    for i, (addr, type_code, body) in enumerate(rom_widgets):
        if type_code in FIELD_DEFS:
            fields = FIELD_DEFS[type_code]
            known_body_size = KNOWN_TYPES[type_code][1]
            has_trailing_text = len(body) > known_body_size
            offset = 0
            for fname, fsize, is_ptr in fields:
                if is_ptr and fsize == 4:
                    val = struct.unpack_from('<I', body, offset)[0]
                    if val in symbols:
                        # Skip string_ptr if it will use SELF() macro
                        if fname == "string_ptr" and has_trailing_text:
                            pass  # rendered as SELF(w{i}_text)
                        else:
                            extern_symbols.add(symbols[val])
                offset += fsize

    print(f"  {len(extern_symbols)} extern symbols")

    # Compute trailing data (bytes after last widget but before end_addr)
    widget_total = len(leading_data) + sum(4 + len(b) for _, _, b in rom_widgets)
    trailing_data = b''
    if args.end_addr:
        expected_total = int(args.end_addr, 16) - block_base
        if widget_total < expected_total:
            trail_offset = block_base - ROM_BASE + widget_total
            trailing_data = rom[trail_offset:trail_offset + (expected_total - widget_total)]
            if trailing_data:
                print(f"  {len(trailing_data)} trailing bytes after last widget")

    # Generate C file
    c_content = generate_c_file(
        widgets_parsed, rom_widgets, symbols, names,
        block_base, output_name, extern_symbols,
        leading_data=leading_data, trailing_data=trailing_data
    )

    # Generate linker script
    ld_content = generate_linker_script(extern_symbols, names, output_name)

    if args.dry_run:
        print("\n=== C FILE ===")
        print(c_content[:3000])
        print("...")
        print(f"\n=== LINKER SCRIPT ===")
        print(ld_content)
    else:
        c_path = Path(args.input).parent / f"{output_name}.c"
        ld_path = Path(args.input).parent / f"{output_name}_link.ld"

        with open(c_path, 'w') as f:
            f.write(c_content)
        print(f"  Written: {c_path}")

        with open(ld_path, 'w') as f:
            f.write(ld_content)
        print(f"  Written: {ld_path}")

    # Compute total size
    total = len(leading_data) + sum(4 + len(body) for _, _, body in rom_widgets) + len(trailing_data)
    extras = []
    if leading_data: extras.append(f"{len(leading_data)} leading")
    if trailing_data: extras.append(f"{len(trailing_data)} trailing")
    extra_str = f", {', '.join(extras)}" if extras else ""
    print(f"\nTotal data size: {total} bytes ({len(rom_widgets)} widgets{extra_str})")
    end_addr = block_base + total
    print(f"Address range: 0x{block_base:06X} - 0x{end_addr:06X}")


if __name__ == '__main__':
    main()
