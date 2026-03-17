#!/usr/bin/env python3
"""Convert the compound data structure at E16184 to symbolic pointer entries.

This structure contains:
1. A 96-byte header (E16184-E161E3)
2. A 32-byte config block (E161E4-E16203)
3. A 128-byte string buffer (E16204-E16283)
4. A 73-entry function pointer table (E16284-E163A7) - F1xxxx range
5. A null separator (E163A8-E163AB)
6. A 74-entry string pointer table (E163AC-E164D3) - E16xxx range
7. String data (E164D4+)

Currently the F1xxxx pointer table is raw .byte data and the ASCII string
incorrectly includes the first byte of the pointer table ('+' = 0x2B).
The first E16xxx pointer (E169AE) is also in raw .byte format.

This script:
1. Fixes the ASCII string boundary
2. Converts F1xxxx pointer bytes to .long with actual source label names
3. Converts the null separator and first E16xxx pointer
4. Inserts LABEL_E169AE if missing
"""

import re
import struct
import sys

BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^(\w+):')
FILL_RE = re.compile(r'(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*0x([0-9a-fA-F]+)')

ROM_BASE = 0xE00000


def build_addr_to_source_label(lines, sym_path):
    """Build address -> actual source label name mapping.

    Uses two strategies:
    1. LABEL_XXXXXX format labels - address is encoded in the name
    2. Named labels - look up address in symbol reference file
    """
    # Load symbol reference: name (uppercase) -> address
    symref_name_to_addr = {}
    with open(sym_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                parts = line.split()
                if len(parts) >= 2:
                    try:
                        symref_name_to_addr[parts[0].upper()] = int(parts[1], 16)
                    except ValueError:
                        pass

    addr_to_source = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            name = m.group(1)
            # Strategy 1: LABEL_XXXXXX format
            if name.startswith('LABEL_') and len(name) == 12:
                try:
                    addr = int(name[6:], 16)
                    addr_to_source[addr] = name
                except ValueError:
                    pass
            else:
                # Strategy 2: look up via symbol reference (case-insensitive)
                upper = name.upper()
                if upper in symref_name_to_addr:
                    addr_to_source[symref_name_to_addr[upper]] = name

    return addr_to_source


def line_byte_count(line):
    """Count how many bytes a data line emits."""
    stripped = line.strip()
    if stripped.startswith('.byte '):
        return len(BYTE_RE.findall(line))
    m = FILL_RE.match(line)
    if m:
        return int(m.group(2))
    if stripped.startswith('.long '):
        return 4
    if stripped.startswith('.short '):
        return 2
    if stripped.startswith('.zero '):
        m2 = re.search(r'\.zero\s+(\d+)', stripped)
        if m2:
            return int(m2.group(1))
    if stripped.startswith('.ascii '):
        m2 = re.search(r'"([^"]*)"', stripped)
        return len(m2.group(1)) if m2 else 0
    if stripped.startswith('.asciz '):
        m2 = re.search(r'"([^"]*)"', stripped)
        return (len(m2.group(1)) + 1) if m2 else 1
    if 'aligned_string' in stripped:
        m2 = re.search(r'"([^"]*)"', stripped)
        if m2:
            slen = len(m2.group(1)) + 1  # string + null
            return slen + (1 if slen % 2 == 1 else 0)
    return 0


def find_insert_position(lines, label_line, byte_offset):
    """Find (line_idx, offset_within_line) for inserting a label at byte_offset from label."""
    cumulative = 0
    j = label_line + 1
    while j < len(lines):
        stripped = lines[j].strip()
        bc = line_byte_count(lines[j])
        if bc == 0:
            if LABEL_RE.match(stripped) or stripped == '' or stripped.startswith(';'):
                j += 1
                continue
            break
        if cumulative + bc > byte_offset:
            return (j, byte_offset - cumulative)
        if cumulative + bc == byte_offset:
            return (j + 1, 0)
        cumulative += bc
        j += 1
    return None


def parse_byte_values(line):
    return [int(m, 16) for m in BYTE_RE.findall(line)]


def format_bytes_line(byte_list, indent='\t'):
    hex_str = ', '.join(f'0x{b:02x}' for b in byte_list)
    return f'{indent}.byte {hex_str}\n'


def make_split_change(lines, line_idx, offset_in_line, label_name):
    """Insert a label at a position within a data line."""
    if offset_in_line == 0:
        return (line_idx, line_idx, [f'{label_name}:\n'])

    stripped = lines[line_idx].strip()

    if stripped.startswith('.byte '):
        byte_vals = parse_byte_values(lines[line_idx])
        before = byte_vals[:offset_in_line]
        after = byte_vals[offset_in_line:]
        new_lines = []
        if before:
            new_lines.append(format_bytes_line(before))
        new_lines.append(f'{label_name}:\n')
        if after:
            new_lines.append(format_bytes_line(after))
        return (line_idx, line_idx + 1, new_lines)

    m = FILL_RE.match(lines[line_idx])
    if m:
        indent_str = m.group(1)
        count = int(m.group(2))
        val_str = m.group(3)
        new_lines = []
        if offset_in_line > 0:
            new_lines.append(f'{indent_str}.fill {offset_in_line}, 1, 0x{val_str}\n')
        new_lines.append(f'{label_name}:\n')
        remaining = count - offset_in_line
        if remaining > 0:
            new_lines.append(f'{indent_str}.fill {remaining}, 1, 0x{val_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    return None


def process_file(filepath, rom_path, sym_path):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    with open(rom_path, 'rb') as f:
        rom = f.read()

    print("Building address -> source label mapping...")
    addr_to_source = build_addr_to_source_label(lines, sym_path)

    # Decode the F1xxxx pointer table from ROM
    table_start = 0xE16284
    offset = table_start - ROM_BASE
    f1_entries = []
    i = 0
    while True:
        val = struct.unpack_from('<I', rom, offset + i * 4)[0]
        if val == 0:
            break
        f1_entries.append(val)
        i += 1

    print(f"F1xxxx pointer table: {len(f1_entries)} entries")

    # Verify all F1xxxx entries have source labels
    missing = []
    for val in f1_entries:
        if val not in addr_to_source:
            missing.append(val)
    if missing:
        print(f"ERROR: {len(missing)} entries have no source label:")
        for addr in missing:
            print(f"  0x{addr:06X}")
        sys.exit(1)

    # First E16xxx entry
    null_addr = table_start + len(f1_entries) * 4
    first_e16_addr = null_addr + 4
    first_e16_val = struct.unpack_from('<I', rom, first_e16_addr - ROM_BASE)[0]
    first_e16_name = addr_to_source.get(first_e16_val, f'LABEL_{first_e16_val:06X}')
    print(f"First E16xxx entry: 0x{first_e16_val:06X} ({first_e16_name})")

    # Find LABEL_E16184
    e16184_line = None
    for i, line in enumerate(lines):
        if line.startswith('LABEL_E16184:'):
            e16184_line = i
            break

    if e16184_line is None:
        print("ERROR: LABEL_E16184 not found")
        sys.exit(1)

    print(f"LABEL_E16184 at line {e16184_line}")

    # Walk through lines counting bytes to find ASCII string and pointer data
    cumulative = 0
    ascii_line = None
    ptr_start_line = None
    ptr_end_line = None
    j = e16184_line + 1

    while j < len(lines):
        stripped = lines[j].strip()
        bc = line_byte_count(lines[j])
        if bc == 0:
            if LABEL_RE.match(stripped) or stripped == '' or stripped.startswith(';'):
                j += 1
                continue
            break

        line_start_offset = cumulative
        cumulative += bc

        # ASCII string at offset 0x80 (E16204 - E16184 = 128)
        if stripped.startswith('.ascii ') and line_start_offset <= 0x80 < cumulative:
            ascii_line = j

        # Pointer data at offset 0x100 (E16284 - E16184 = 256)
        if line_start_offset >= 0x100 and ptr_start_line is None:
            ptr_start_line = j

        j += 1

    # Find where existing .long entries start (end of raw pointer bytes)
    if ptr_start_line:
        k = ptr_start_line
        while k < len(lines):
            stripped = lines[k].strip()
            if stripped.startswith('.long '):
                ptr_end_line = k
                break
            bc = line_byte_count(lines[k])
            if bc == 0 and not LABEL_RE.match(stripped) and stripped != '' and not stripped.startswith(';'):
                break
            k += 1

    print(f"ASCII line: {ascii_line}")
    print(f"Raw pointer data: lines {ptr_start_line} - {ptr_end_line}")

    all_changes = []

    # Fix 1: Trim ASCII string (remove trailing '+' = 0x2B, first pointer byte)
    if ascii_line is not None:
        old_line = lines[ascii_line]
        m = re.search(r'\.ascii\s+"(.+)"', old_line)
        if m:
            content = m.group(1)
            if content.endswith('+'):
                new_content = content[:-1]
                new_line = f'\t.ascii "{new_content}"\n'
                all_changes.append((ascii_line, ascii_line + 1, [new_line]))
                print(f"  Fixed ASCII string: removed trailing '+'")
            else:
                print(f"  WARNING: ASCII string doesn't end with '+'")
        else:
            print(f"  WARNING: Could not parse ASCII line")

    # Fix 2: Replace raw .byte lines with .long entries
    if ptr_start_line and ptr_end_line:
        new_lines = []

        # F1xxxx function pointers
        for val in f1_entries:
            name = addr_to_source[val]
            new_lines.append(f'\t.long {name}\n')

        # Null separator
        new_lines.append(f'\t.long 0\n')

        # First E16xxx string pointer
        new_lines.append(f'\t.long {first_e16_name}\n')

        all_changes.append((ptr_start_line, ptr_end_line, new_lines))
        print(f"  Converted {len(f1_entries)} F1xxxx pointers + null + 1 E16xxx pointer")

    # Fix 3: Insert LABEL_E169AE if it doesn't exist
    e169ae_exists = first_e16_name in set(
        LABEL_RE.match(line).group(1)
        for line in lines if LABEL_RE.match(line)
    )

    if not e169ae_exists:
        # Find position for LABEL_E169AE
        # It's 30 bytes into the string data after LABEL_E16990
        addr_target = first_e16_val  # 0xE169AE

        # Find nearest preceding label by address
        preceding = [(a, addr_to_source[a])
                      for a in sorted(addr_to_source.keys())
                      if a <= addr_target and a != addr_target]
        if preceding:
            prev_addr = max(a for a, _ in preceding)
            prev_name = addr_to_source[prev_addr]
            byte_offset = addr_target - prev_addr

            # Find line of preceding label
            prev_line = None
            for li, line in enumerate(lines):
                if line.startswith(f'{prev_name}:'):
                    prev_line = li
                    break

            if prev_line is not None:
                pos = find_insert_position(lines, prev_line, byte_offset)
                if pos:
                    line_idx, offset_in_line = pos
                    conflicts = any(start <= line_idx < end
                                    for start, end, _ in all_changes)
                    if not conflicts:
                        change = make_split_change(
                            lines, line_idx, offset_in_line, first_e16_name)
                        if change:
                            all_changes.append(change)
                            print(f"  Inserted {first_e16_name} at line {line_idx}")
                        else:
                            print(f"  WARNING: Could not split line for {first_e16_name}")
                    else:
                        print(f"  Skipping {first_e16_name} (conflicts)")
                else:
                    print(f"  WARNING: Could not find position for {first_e16_name}")
            else:
                print(f"  WARNING: Could not find {prev_name} in source")
        else:
            print(f"  WARNING: No preceding label for {first_e16_name}")
    else:
        print(f"  {first_e16_name} already exists")

    # Apply changes in reverse line order
    all_changes.sort(key=lambda x: x[0], reverse=True)

    # Verify no overlaps
    for i in range(len(all_changes) - 1):
        curr_start = all_changes[i][0]
        prev_end = all_changes[i + 1][1]
        if curr_start < prev_end:
            print(f"ERROR: Overlapping changes")
            sys.exit(1)

    for start, end, new_lines in all_changes:
        lines[start:end] = new_lines

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print(f"\nDone! Applied {len(all_changes)} changes.")


if __name__ == '__main__':
    process_file(
        'maincpu/kn5000_v10_program.s',
        'original_ROMs/kn5000_v10_program.rom',
        'symbols/maincpu_symbols_reference.txt'
    )
