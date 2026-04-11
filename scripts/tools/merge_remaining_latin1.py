#!/usr/bin/env python3
"""Merge remaining Latin-1 string fragments using ROM as ground truth.

Handles patterns that merge_latin1_strings.py and fix_bogus_instructions_in_strings.py
don't cover:

1. LABEL_XXX: / .byte 0xNN... / aligned_string "..." → LABEL_XXX: aligned_string "..."
2. LABEL_XXX: .ascii "..." / .byte 0xNN / string → LABEL_XXX: aligned_string "..."
3. LABEL_XXX: / .byte 0xNN... / .ascii "..." / .byte 0xNN, 0x00 → LABEL_XXX: .asciz "..."

Uses ROM binary as ground truth: reads the actual string at each label's address and
replaces the fragmented assembly with a single directive.

SAFETY: Computes exact expected byte count using address-aware aligned_string sizing.
Verifies assembly bytes consumed == ROM string size before applying any fix.

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python scripts/merge_remaining_latin1.py [--dry-run]
"""

import re
import sys

ASM_FILE = 'maincpu/kn5000_v10_program.s'
ROM_FILE = '/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_v10_program.rom'
ROM_BASE = 0xE00000

LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):(.*)$')
ANY_LABEL_RE = re.compile(r'^([A-Za-z_]\w*):(.*)$')
BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"((?:[^"\\]|\\.)*)"')
ASCII_RE = re.compile(r'^\t\.(ascii|asciz)\s+"((?:[^"\\]|\\.)*)"(.*)$')
ALIGNED_LINE_RE = re.compile(r'^\taligned_string\s+"((?:[^"\\]|\\.)*)"(.*)$')
BYTE_LINE_RE = re.compile(r'^\t\.byte\s+((?:0x[0-9a-fA-F]{2}(?:,\s*)?)+)\s*$')


def parse_byte_values(byte_str):
    return [int(m, 16) for m in BYTE_RE.findall(byte_str)]


def can_inline_byte(b):
    """Check if byte can be directly embedded in a Latin-1 string literal."""
    if b == 0x00 or b == 0x22 or b == 0x5C:
        return False
    if 0x20 <= b <= 0x7E:
        return True
    if 0x80 <= b <= 0xFF:
        return True
    return False


def read_rom_string(rom, addr):
    """Read null-terminated string from ROM, return (text, total_bytes_with_null)."""
    off = addr - ROM_BASE
    if off < 0 or off >= len(rom):
        return None, 0
    end = off
    while end < len(rom) and rom[end] != 0x00:
        if not can_inline_byte(rom[end]):
            return None, 0
        end += 1
    if end >= len(rom):
        return None, 0
    text = rom[off:end].decode('latin-1')
    return text, (end - off) + 1


def needs_aligned_pad(rom, addr, text_len_with_null):
    """Check if string at addr needs 0xFF alignment padding."""
    end_addr = addr + text_len_with_null
    if end_addr % 2 != 0:
        pad_off = end_addr - ROM_BASE
        if pad_off < len(rom) and rom[pad_off] == 0xFF:
            return True
    return False


def asm_string_byte_len(s):
    """Calculate byte length of an assembly string with escape sequences."""
    i = 0
    length = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            next_char = s[i + 1]
            if next_char == 'x' and i + 3 < len(s):
                i += 4
            elif next_char in '01234567':
                end = i + 2
                while end < len(s) and end < i + 4 and s[end] in '01234567':
                    end += 1
                i = end
            else:
                i += 2
            length += 1
        else:
            i += 1
            length += 1
    return length


def line_byte_count(line, current_addr):
    """Count bytes a data line emits with address-aware aligned_string sizing.
    Returns byte count or None for non-data lines."""
    stripped = line.strip()
    # Strip label prefix if any
    lm = LABEL_RE.match(stripped)
    if lm:
        stripped = lm.group(2).strip()
    alm = ANY_LABEL_RE.match(stripped)
    if alm:
        stripped = alm.group(2).strip()
    if not stripped:
        return 0

    if stripped.startswith('.byte '):
        return len(BYTE_RE.findall(stripped))
    if stripped.startswith('.ascii '):
        m = re.search(r'"((?:[^"\\]|\\.)*)"', stripped)
        return asm_string_byte_len(m.group(1)) if m else 0
    if stripped.startswith('.asciz '):
        m = re.search(r'"((?:[^"\\]|\\.)*)"', stripped)
        return (asm_string_byte_len(m.group(1)) + 1) if m else 1
    m = ALIGNED_STRING_RE.search(stripped)
    if m:
        size = asm_string_byte_len(m.group(1)) + 1  # string + null
        if (current_addr + size) % 2 != 0:
            size += 1  # alignment padding byte (0xFF)
        return size
    if stripped.startswith('.long ') or stripped.startswith('.4byte '):
        return 4
    if stripped.startswith('.short ') or stripped.startswith('.2byte '):
        return 2
    m = re.match(r'^\s*\.zero\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    m = re.match(r'^\s*\.fill\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    return None


def process_file(filepath, rom_path, dry_run=False):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines, ROM {len(rom)} bytes")

    # Build label index: line_number -> address
    label_line_addrs = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line.strip())
        if m:
            try:
                addr = int(m.group(1)[6:], 16)
                label_line_addrs[i] = addr
            except ValueError:
                pass

    fixes = []
    skipped = {'no_rom_string': 0, 'byte_mismatch': 0, 'label_collision': 0}

    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        # Get label info for this line
        label_name = None
        addr = None
        lm = LABEL_RE.match(stripped)
        if lm:
            label_name = lm.group(1)
            label_data = lm.group(2).strip()
            try:
                addr = int(label_name[6:], 16)
            except ValueError:
                addr = None
        else:
            label_data = stripped

        if addr is None:
            i += 1
            continue

        # Determine what follows the label
        # Case A: bare label line (label_data is empty)
        # Case B: label with .ascii data on same line

        is_fragmented = False
        start_line = i
        scan_from = None  # line to start scanning for more fragments

        if not label_data:
            # Bare label — check next line for .byte with printable Latin-1
            if i + 1 < len(lines):
                bm = BYTE_LINE_RE.match(lines[i + 1])
                if bm:
                    byte_vals = parse_byte_values(bm.group(1))
                    if all(can_inline_byte(b) for b in byte_vals):
                        is_fragmented = True
                        scan_from = i + 2

        elif label_data.startswith('.ascii '):
            # Label with .ascii — check next line for .byte
            if i + 1 < len(lines):
                bm = BYTE_LINE_RE.match(lines[i + 1])
                if bm:
                    byte_vals = parse_byte_values(bm.group(1))
                    non_null = [b for b in byte_vals if b != 0x00]
                    if all(can_inline_byte(b) for b in non_null):
                        is_fragmented = True
                        scan_from = i + 2

        if not is_fragmented:
            i += 1
            continue

        # Scan forward collecting fragment lines until we hit a terminator
        j = scan_from
        end_line = scan_from  # exclusive end
        found_terminator = False

        # Check if the .byte line itself has a null terminator
        byte_line = lines[scan_from - 1].strip()
        byte_vals_check = parse_byte_values(byte_line)
        if 0x00 in byte_vals_check:
            found_terminator = True
            end_line = scan_from

        while j < len(lines) and not found_terminator:
            s = lines[j].strip()

            # Stop at any label
            if ANY_LABEL_RE.match(s):
                break

            # Check for .byte
            bm = BYTE_LINE_RE.match(lines[j])
            if bm:
                bvals = parse_byte_values(bm.group(1))
                non_null = [b for b in bvals if b != 0x00]
                if all(can_inline_byte(b) for b in non_null):
                    end_line = j + 1
                    if 0x00 in bvals:
                        found_terminator = True
                    j += 1
                    continue
                break

            # Check for .ascii
            asc = ASCII_RE.match(lines[j])
            if asc:
                end_line = j + 1
                if asc.group(1) == 'asciz':
                    found_terminator = True
                j += 1
                continue

            # Check for aligned_string
            am = ALIGNED_LINE_RE.match(lines[j])
            if am:
                end_line = j + 1
                found_terminator = True
                j += 1
                break

            break

        if not found_terminator:
            i += 1
            continue

        # Must consume at least 2 lines (label + something)
        if end_line - start_line < 2:
            i += 1
            continue

        # Count total assembly bytes consumed (address-aware)
        total_asm_bytes = 0
        current_addr = addr
        for k in range(start_line, end_line):
            bc = line_byte_count(lines[k], current_addr)
            if bc is None:
                # Non-data line in the middle — shouldn't happen
                total_asm_bytes = -1
                break
            total_asm_bytes += bc
            current_addr += bc

        if total_asm_bytes <= 0:
            i += 1
            continue

        # Get ROM string
        rom_text, rom_total = read_rom_string(rom, addr)
        if rom_text is None:
            skipped['no_rom_string'] += 1
            i += 1
            continue

        # Determine directive: aligned_string or .asciz
        use_aligned = needs_aligned_pad(rom, addr, rom_total)

        # Expected byte count for the replacement
        expected_replacement_bytes = rom_total
        if use_aligned and (addr + rom_total) % 2 != 0:
            expected_replacement_bytes += 1

        # STRICT: assembly bytes must exactly match replacement bytes
        if total_asm_bytes != expected_replacement_bytes:
            skipped['byte_mismatch'] += 1
            i += 1
            continue

        # Safety: check no other labels exist in the consumed range (except on first line)
        has_inner_label = False
        for k in range(start_line + 1, end_line):
            s = lines[k].strip()
            if ANY_LABEL_RE.match(s):
                has_inner_label = True
                break
        if has_inner_label:
            skipped['label_collision'] += 1
            i += 1
            continue

        # Build replacement
        if use_aligned:
            directive = f'aligned_string "{rom_text}"'
        else:
            directive = f'.asciz "{rom_text}"'

        new_line = f'{label_name}:\t{directive}\n'
        fixes.append((start_line, end_line, [new_line],
                       f'{label_name}: merge {end_line - start_line} lines'))

        i = end_line

    print(f"\nFound {len(fixes)} fixes")
    print(f"Skipped: {skipped}")

    if dry_run:
        for start, end, content, desc in fixes:
            print(f"\n--- {desc} (lines {start+1}-{end}) ---")
            print("OLD:")
            for k in range(start, end):
                print(f"  {lines[k].rstrip()[:100]}")
            print("NEW:")
            for nl in content:
                print(f"  {nl.rstrip()[:100]}")
        print(f"\n[DRY RUN] No changes written.")
        return

    # Apply in reverse order
    fixes.sort(key=lambda x: x[0], reverse=True)
    for start, end, content, desc in fixes:
        lines[start:end] = content

    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(lines)

    print(f"Applied {len(fixes)} fixes")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run)
