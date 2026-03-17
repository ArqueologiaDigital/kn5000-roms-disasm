#!/usr/bin/env python3
"""Convert embedded jump tables within raw-byte code blocks to symbolic .long entries.

Unlike convert_pointer_tables.py which handles tables at the START of byte blocks,
this script handles tables EMBEDDED within larger raw-byte code blocks.

Strategy: Process each affected byte block holistically:
1. Flatten the byte block into a single byte array
2. Identify all table regions and label insertion points
3. Rebuild the block with .long entries and labels at the right positions
"""

import re
import struct
import sys

BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):')
FILL_RE = re.compile(r'(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*0x([0-9a-fA-F]+)')

# Embedded tables: (table_address, num_entries)
EMBEDDED_TABLES = [
    # Region 1: FCC8B4-FCCAC8
    (0xFCC8CC, 12),   # dispatch on B, 0-11
    (0xFCC9E2, 4),    # dispatch on B, 0-3
    (0xFCCA24, 2),    # dispatch on B, 0-1
    (0xFCCA5D, 12),   # dispatch on B, 0-11
    # Region 2: FCFA4D-FD055D
    (0xFCFA67, 16),   # dispatch on (0x9634)&0x0F
    (0xFCFB3D, 8),    # dispatch on (0x9634)&0x70
    (0xFCFBB3, 48),   # dispatch on 0x9657 * 4
]

ROM_BASE = 0xE00000


def parse_byte_values(line):
    return [int(m, 16) for m in BYTE_RE.findall(line)]


def line_byte_count(line):
    stripped = line.strip()
    if stripped.startswith('.byte '):
        return len(BYTE_RE.findall(line))
    m = FILL_RE.match(line)
    if m:
        return int(m.group(2))
    if stripped.startswith('.long '):
        return 4
    return 0


def format_bytes_multiline(byte_list, indent='\t'):
    result = []
    for i in range(0, len(byte_list), 8):
        chunk = byte_list[i:i + 8]
        hex_str = ', '.join(f'0x{b:02x}' for b in chunk)
        result.append(f'{indent}.byte {hex_str}\n')
    return result


def build_label_index(lines):
    index = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            addr = int(m.group(1)[6:], 16)
            index[addr] = i
    return index


def collect_byte_block(lines, start_line):
    """Collect consecutive data lines (.byte/.fill) starting at start_line.
    Stops at non-data lines (except existing labels within bytes are OK).
    Returns (all_bytes, end_line_exclusive, existing_labels_in_block).
    """
    all_bytes = []
    existing_labels = {}  # offset -> label_name
    j = start_line
    while j < len(lines):
        stripped = lines[j].strip()
        if stripped.startswith('.byte '):
            all_bytes.extend(parse_byte_values(lines[j]))
            j += 1
        elif FILL_RE.match(lines[j]):
            m = FILL_RE.match(lines[j])
            count = int(m.group(2))
            val = int(m.group(3), 16)
            all_bytes.extend([val] * count)
            j += 1
        elif LABEL_RE.match(stripped):
            # Existing label within the byte block - record its position
            existing_labels[len(all_bytes)] = LABEL_RE.match(stripped).group(1)
            j += 1
        elif stripped == '' or stripped.startswith(';'):
            j += 1
        else:
            break
    return all_bytes, j, existing_labels


def rebuild_block(all_bytes, block_start_addr, tables, labels, indent='\t'):
    """Rebuild a byte block with tables and labels inserted.

    tables: list of (offset, num_entries) - table positions within block
    labels: dict of offset -> label_name - label positions within block
    """
    # Create events: (offset, type, data)
    # type: 'table_start', 'table_end', 'label'
    events = []

    table_ranges = []
    for offset, num_entries in tables:
        table_end = offset + num_entries * 4
        table_ranges.append((offset, table_end, num_entries))
        events.append((offset, 'table_start', num_entries))

    for offset, name in sorted(labels.items()):
        # Don't add label if it's inside a table range (table already covers it)
        in_table = False
        for t_start, t_end, _ in table_ranges:
            if t_start <= offset < t_end:
                in_table = True
                break
        if not in_table:
            events.append((offset, 'label', name))

    events.sort(key=lambda x: (x[0], 0 if x[1] == 'label' else 1))

    output = []
    pos = 0

    for event in events:
        offset = event[0]
        etype = event[1]

        if etype == 'label':
            label_name = event[2]
            # Emit bytes from pos to offset
            if offset > pos:
                output.extend(format_bytes_multiline(all_bytes[pos:offset], indent))
            elif offset < pos:
                # Label is inside previously emitted region (shouldn't happen)
                print(f"  WARNING: Label {label_name} at offset {offset} < pos {pos}")
                continue
            output.append(f'{label_name}:\n')
            pos = offset

        elif etype == 'table_start':
            num_entries = event[2]
            table_end = offset + num_entries * 4

            # Emit bytes from pos to table start
            if offset > pos:
                output.extend(format_bytes_multiline(all_bytes[pos:offset], indent))

            # Emit table label if it's in our labels dict
            table_addr = block_start_addr + offset
            label_name = labels.get(offset, f'LABEL_{table_addr:06X}')
            if offset in labels or True:  # Always add table label
                output.append(f'{label_name}:\n')

            # Emit .long entries
            for i in range(num_entries):
                entry_offset = offset + i * 4
                val = struct.unpack_from('<I', bytes(all_bytes), entry_offset)[0]
                output.append(f'{indent}.long LABEL_{val:06X}\n')

            pos = table_end

    # Emit remaining bytes
    if pos < len(all_bytes):
        output.extend(format_bytes_multiline(all_bytes[pos:], indent))

    return output


def find_line_and_offset(lines, label_line, byte_offset):
    """Find (line_idx, offset_within_line) for a byte offset from a label."""
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


def split_and_insert_label(lines, line_idx, offset_in_line, label_name):
    """Insert a label at a position in a data line."""
    if offset_in_line == 0:
        return (line_idx, line_idx, [f'{label_name}:\n'])

    stripped = lines[line_idx].strip()
    if stripped.startswith('.byte '):
        byte_vals = parse_byte_values(lines[line_idx])
        before = byte_vals[:offset_in_line]
        after = byte_vals[offset_in_line:]
        new_lines = []
        if before:
            hex_str = ', '.join(f'0x{b:02x}' for b in before)
            new_lines.append(f'\t.byte {hex_str}\n')
        new_lines.append(f'{label_name}:\n')
        if after:
            hex_str = ', '.join(f'0x{b:02x}' for b in after)
            new_lines.append(f'\t.byte {hex_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    m = FILL_RE.match(lines[line_idx])
    if m:
        indent = m.group(1)
        count = int(m.group(2))
        val_str = m.group(3)
        new_lines = []
        if offset_in_line > 0:
            new_lines.append(f'{indent}.fill {offset_in_line}, 1, 0x{val_str}\n')
        new_lines.append(f'{label_name}:\n')
        remaining = count - offset_in_line
        if remaining > 0:
            new_lines.append(f'{indent}.fill {remaining}, 1, 0x{val_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    return None


def process_file(filepath, rom_path):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    with open(rom_path, 'rb') as f:
        rom = f.read()

    print("Building label index...")
    label_index = build_label_index(lines)
    existing_labels = set(label_index.keys())

    # Group tables by their containing byte block
    # block_label_addr -> list of (table_offset_in_block, num_entries)
    block_tables = {}
    # block_label_addr -> set of target addresses
    block_targets = {}

    all_new_labels = {}  # addr -> label_name

    for table_addr, num_entries in EMBEDDED_TABLES:
        # Find containing block
        preceding = [(a, l) for a, l in label_index.items() if a <= table_addr]
        if not preceding:
            print(f"WARNING: No preceding label for table at 0x{table_addr:06X}")
            continue

        block_label_addr = max(preceding, key=lambda x: x[0])[0]
        table_offset = table_addr - block_label_addr

        if block_label_addr not in block_tables:
            block_tables[block_label_addr] = []
            block_targets[block_label_addr] = set()

        block_tables[block_label_addr].append((table_offset, num_entries))

        # Decode targets from ROM
        rom_offset = table_addr - ROM_BASE
        for i in range(num_entries):
            val = struct.unpack_from('<I', rom, rom_offset + i * 4)[0]
            block_targets[block_label_addr].add(val)

        # Track table label
        if table_addr not in existing_labels:
            all_new_labels[table_addr] = f'LABEL_{table_addr:06X}'

        print(f"Table 0x{table_addr:06X}: {num_entries} entries in block LABEL_{block_label_addr:06X}")

    # Process each affected byte block
    all_changes = []

    for block_addr in sorted(block_tables.keys()):
        block_label_line = label_index[block_addr]
        tables = block_tables[block_addr]
        targets = block_targets[block_addr]

        # Collect the byte block
        data_start = block_label_line + 1
        all_bytes, data_end, existing_in_block = collect_byte_block(lines, data_start)
        block_size = len(all_bytes)

        print(f"\nBlock LABEL_{block_addr:06X}: {block_size} bytes, "
              f"lines {data_start}-{data_end}")

        # Build labels dict (offset -> name) for this block
        block_labels = dict(existing_in_block)  # Start with existing labels

        for target_addr in sorted(targets):
            offset = target_addr - block_addr
            if 0 <= offset <= block_size:
                label_name = f'LABEL_{target_addr:06X}'
                if offset not in block_labels:
                    block_labels[offset] = label_name
                if target_addr not in existing_labels:
                    all_new_labels[target_addr] = label_name
            # External targets handled separately

        # Add table labels
        for table_offset, num_entries in tables:
            table_addr = block_addr + table_offset
            label_name = f'LABEL_{table_addr:06X}'
            if table_offset not in block_labels:
                block_labels[table_offset] = label_name

        # Rebuild the block
        new_lines = rebuild_block(all_bytes, block_addr, tables, block_labels)

        all_changes.append((data_start, data_end, new_lines))
        print(f"  Replaced lines {data_start}-{data_end} with {len(new_lines)} lines")

        # Handle external targets (outside this block)
        for target_addr in sorted(targets):
            offset = target_addr - block_addr
            if offset < 0 or offset > block_size:
                if target_addr not in existing_labels:
                    all_new_labels[target_addr] = f'LABEL_{target_addr:06X}'

    # Insert external labels (targets not in any processed block)
    processed_blocks = set(block_tables.keys())

    for addr, label_name in sorted(all_new_labels.items()):
        # Skip if already handled within a block
        in_block = False
        for block_addr in processed_blocks:
            block_label_line = label_index[block_addr]
            data_start = block_label_line + 1
            all_bytes, data_end, _ = collect_byte_block(lines, data_start)
            block_size = len(all_bytes)
            offset = addr - block_addr
            if 0 <= offset <= block_size:
                in_block = True
                break

        if in_block:
            continue  # Already handled in block rebuild

        if addr in existing_labels:
            continue  # Already exists

        # Find position in the file
        preceding = [(a, l) for a, l in label_index.items() if a <= addr]
        if not preceding:
            print(f"  WARNING: No preceding label for {label_name}")
            continue

        prev_addr, prev_line = max(preceding, key=lambda x: x[0])
        byte_offset = addr - prev_addr

        pos = find_line_and_offset(lines, prev_line, byte_offset)
        if pos is None:
            print(f"  WARNING: Could not find position for {label_name}")
            continue

        line_idx, offset_in_line = pos

        # Check not in an existing change range
        conflicts = any(start <= line_idx < end for start, end, _ in all_changes)
        if conflicts:
            continue

        change = split_and_insert_label(lines, line_idx, offset_in_line, label_name)
        if change:
            all_changes.append(change)
            print(f"  External label: {label_name} at line {line_idx}")

    # Sort and apply changes in reverse order
    all_changes.sort(key=lambda x: x[0], reverse=True)

    # Verify no overlaps
    for i in range(len(all_changes) - 1):
        curr_start = all_changes[i][0]
        prev_end = all_changes[i + 1][1]
        if curr_start < prev_end:
            print(f"ERROR: Overlapping changes at lines "
                  f"{all_changes[i+1][0]}-{prev_end} and "
                  f"{curr_start}-{all_changes[i][1]}")
            sys.exit(1)

    for start, end, new_lines in all_changes:
        lines[start:end] = new_lines

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print(f"\nDone! Applied {len(all_changes)} changes.")
    print(f"New labels: {len(all_new_labels)}")
    return all_new_labels


if __name__ == '__main__':
    new_labels = process_file(
        'maincpu/kn5000_v10_program.s',
        'original_ROMs/kn5000_v10_program.rom'
    )
    if new_labels:
        print("\nLabels for symbol reference:")
        for addr in sorted(new_labels.keys()):
            print(f"  {new_labels[addr]} 0x{addr:06X}")
