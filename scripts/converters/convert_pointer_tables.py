#!/usr/bin/env python3
"""Convert raw-byte pointer tables to symbolic .long entries and insert target labels.

This script:
1. Converts raw 4-byte LE sequences in known pointer tables to .long LABEL_XXXXXX
2. Inserts labels into remaining raw byte blocks at target offsets
3. Handles targets both within and outside the table's immediate byte block

Tables are processed in two phases:
- Phase 1: Convert table pointer bytes to .long and insert in-block labels
- Phase 2: Insert labels for external targets (in other byte blocks)

All changes are applied in reverse line order to avoid line number shifts.
"""

import re
import sys

BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):')
FILL_RE = re.compile(r'(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*0x([0-9a-fA-F]+)')

# Tables: (label, num_pointer_entries)
TABLES = [
    ('LABEL_FCA3BB', 8),
    ('LABEL_FCA4F9', 8),
    ('LABEL_F59517', 16),
    ('LABEL_F652BB', 15),
    ('LABEL_F64D75', 10),
    ('LABEL_F6EFEC', 8),
    ('LABEL_F564A6', 40),
    ('LABEL_FD0609', 16),
]


def decode_le32(raw_bytes, offset):
    """Decode a 4-byte little-endian value."""
    return (raw_bytes[offset] |
            (raw_bytes[offset + 1] << 8) |
            (raw_bytes[offset + 2] << 16) |
            (raw_bytes[offset + 3] << 24))


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
    if stripped.startswith('.ascii '):
        m = re.search(r'"([^"]*)"', stripped)
        return len(m.group(1)) if m else 0
    if stripped.startswith('.asciz '):
        m = re.search(r'"([^"]*)"', stripped)
        return (len(m.group(1)) + 1) if m else 1
    return 0


def parse_byte_values(line):
    """Extract byte values from a .byte line."""
    return [int(m, 16) for m in BYTE_RE.findall(line)]


def format_bytes_line(byte_list, indent='\t'):
    """Format bytes as a single .byte line."""
    hex_str = ', '.join(f'0x{b:02x}' for b in byte_list)
    return f'{indent}.byte {hex_str}\n'


def format_bytes_multiline(byte_list, indent='\t'):
    """Format bytes as multiple .byte lines (max 8 per line)."""
    result = []
    for i in range(0, len(byte_list), 8):
        chunk = byte_list[i:i + 8]
        result.append(format_bytes_line(chunk, indent))
    return result


def build_label_index(lines):
    """Build address -> line_index map for all LABEL_XXXXXX labels."""
    index = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            addr = int(m.group(1)[6:], 16)
            index[addr] = i
    return index


def collect_byte_block(lines, start_line):
    """Collect consecutive .byte lines starting at start_line.
    Returns (all_byte_values, end_line_exclusive)."""
    all_bytes = []
    j = start_line
    while j < len(lines) and lines[j].strip().startswith('.byte '):
        all_bytes.extend(parse_byte_values(lines[j]))
        j += 1
    return all_bytes, j


def split_remaining_with_labels(remaining_bytes, label_offsets, indent='\t'):
    """Split remaining bytes into .byte lines with labels inserted at offsets.

    label_offsets: sorted list of (offset, label_name) pairs.
    Returns: list of output lines.
    """
    output = []
    prev_offset = 0

    for offset, label_name in label_offsets:
        # Emit bytes from prev_offset to offset
        chunk = remaining_bytes[prev_offset:offset]
        if chunk:
            output.extend(format_bytes_multiline(chunk, indent))
        # Emit label
        output.append(f'{label_name}:\n')
        prev_offset = offset

    # Emit remaining bytes after last label
    chunk = remaining_bytes[prev_offset:]
    if chunk:
        output.extend(format_bytes_multiline(chunk, indent))

    return output


def find_insert_position(lines, label_line, byte_offset):
    """Find the line position for inserting a label at a byte offset from a label.

    Walks through data lines after label_line, counting bytes.
    Returns (line_idx, offset_within_line) or None.
    """
    cumulative = 0
    j = label_line + 1

    while j < len(lines):
        bc = line_byte_count(lines[j])
        if bc == 0:
            break
        if cumulative + bc > byte_offset:
            return (j, byte_offset - cumulative)
        if cumulative + bc == byte_offset:
            return (j + 1, 0)
        cumulative += bc
        j += 1

    return None


def make_split_change(lines, line_idx, offset_in_line, label_name):
    """Create a change to insert a label at a specific position in a data line.

    Returns (start_line, end_line, new_lines) or None.
    """
    if offset_in_line == 0:
        # Insert label before this line
        return (line_idx, line_idx, [f'{label_name}:\n'])

    stripped = lines[line_idx].strip()

    # Split .byte line
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

    # Split .fill line
    m = FILL_RE.match(lines[line_idx])
    if m:
        indent = m.group(1)
        count = int(m.group(2))
        val_str = m.group(3)
        before_count = offset_in_line
        after_count = count - before_count
        new_lines = []
        if before_count > 0:
            new_lines.append(f'{indent}.fill {before_count}, 1, 0x{val_str}\n')
        new_lines.append(f'{label_name}:\n')
        if after_count > 0:
            new_lines.append(f'{indent}.fill {after_count}, 1, 0x{val_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    print(f"  WARNING: Cannot split line {line_idx}: {stripped[:60]}")
    return None


def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    print("Building label index...")
    label_index = build_label_index(lines)
    existing_labels = set(label_index.keys())

    all_changes = []  # (start_line, end_line, new_lines)

    for table_label, num_entries in TABLES:
        table_addr = int(table_label[6:], 16)

        if table_addr not in label_index:
            print(f"WARNING: {table_label} not found")
            continue

        label_line = label_index[table_addr]

        # Collect all bytes from consecutive .byte lines after the label
        data_start = label_line + 1
        all_bytes, data_end = collect_byte_block(lines, data_start)

        if len(all_bytes) < num_entries * 4:
            print(f"WARNING: {table_label} has only {len(all_bytes)} bytes, "
                  f"need {num_entries * 4}")
            continue

        # Decode pointer entries
        ptr_byte_count = num_entries * 4
        remaining_start_addr = table_addr + ptr_byte_count
        remaining_bytes = all_bytes[ptr_byte_count:]

        # Decode all target addresses
        targets = {}
        for i in range(num_entries):
            addr = decode_le32(all_bytes, i * 4)
            targets[addr] = f'LABEL_{addr:06X}'

        # Separate targets into in-block and external
        in_block_labels = []
        external_targets = []

        for addr in sorted(targets.keys()):
            label_name = targets[addr]
            offset = addr - remaining_start_addr

            if 0 <= offset <= len(remaining_bytes):
                if addr not in existing_labels:
                    in_block_labels.append((offset, label_name))
                # else: label already exists, just reference it
            else:
                if addr not in existing_labels:
                    external_targets.append((addr, label_name))

        # Build replacement for the table block
        new_lines = []

        # .long entries for pointer table
        for i in range(num_entries):
            addr = decode_le32(all_bytes, i * 4)
            new_lines.append(f'\t.long LABEL_{addr:06X}\n')

        # Remaining bytes with labels inserted
        if remaining_bytes or in_block_labels:
            remaining_lines = split_remaining_with_labels(
                remaining_bytes, in_block_labels, '\t')
            new_lines.extend(remaining_lines)

        all_changes.append((data_start, data_end, new_lines))

        print(f"{table_label}: {num_entries} .long entries, "
              f"{len(in_block_labels)} labels in block, "
              f"{len(external_targets)} external")

        # Handle external targets
        for addr, label_name in external_targets:
            # Find the nearest preceding label
            preceding = [(a, l) for a, l in label_index.items() if a <= addr]
            if not preceding:
                print(f"  WARNING: No preceding label for {label_name}")
                continue

            prev_addr, prev_line = max(preceding, key=lambda x: x[0])
            byte_offset = addr - prev_addr

            pos = find_insert_position(lines, prev_line, byte_offset)
            if pos is None:
                print(f"  WARNING: Could not find position for {label_name} "
                      f"(offset {byte_offset} from LABEL_{prev_addr:06X})")
                continue

            line_idx, offset_in_line = pos
            change = make_split_change(lines, line_idx, offset_in_line, label_name)
            if change:
                all_changes.append(change)
                print(f"  External: {label_name} at offset {byte_offset} "
                      f"from LABEL_{prev_addr:06X} (line {line_idx})")
            else:
                print(f"  WARNING: Failed to insert {label_name}")

    # Check for overlapping changes
    all_changes.sort(key=lambda x: x[0], reverse=True)
    for i in range(len(all_changes) - 1):
        curr_start = all_changes[i][0]
        prev_end = all_changes[i + 1][1]
        if curr_start < prev_end:
            print(f"ERROR: Overlapping changes at lines "
                  f"{all_changes[i+1][0]}-{prev_end} and "
                  f"{curr_start}-{all_changes[i][1]}")
            sys.exit(1)

    # Apply all changes in reverse line order
    for start, end, new_lines in all_changes:
        lines[start:end] = new_lines

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print(f"\nDone! Applied {len(all_changes)} changes.")


if __name__ == '__main__':
    process_file('maincpu/kn5000_v10_program.s')
