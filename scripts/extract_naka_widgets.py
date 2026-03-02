#!/usr/bin/env python3
"""Extract NAKA widget structures to dedicated include files.

Identifies contiguous blocks of NAKA widget structures and their associated
data (labels, body bytes, strings, pointer tables) in the main program source.
Extracts each block to a numbered include file and replaces the block in the
main source with an .include directive.

The extraction preserves exact byte output -- the .include substitution is
purely textual.
"""

import re
import sys
import os


def find_naka_blocks(lines):
    """Find contiguous blocks of lines that contain NAKA widget data.

    A NAKA block starts at a label preceding a naka_header and extends
    through the widget body. Blocks are merged when separated by < 15 lines
    of non-NAKA content (small gaps between widgets in the same region).

    Returns list of (start_line, end_line) tuples (0-indexed, inclusive).
    """
    # First, find all naka_header line indices
    naka_lines = set()
    for i, line in enumerate(lines):
        if 'naka_header' in line:
            naka_lines.add(i)

    if not naka_lines:
        return []

    # For each naka_header, find the extent of its block:
    # - Start: the label line above (or the naka_header itself)
    # - End: the last line of body data before the next label/block
    blocks = []
    for i in sorted(naka_lines):
        # Find block start: scan backward for the label
        start = i
        while start > 0 and lines[start - 1].strip() == '':
            start -= 1
        # Include the label line(s) before naka_header
        while start > 0:
            prev = lines[start - 1].strip()
            if re.match(r'^[A-Z_][A-Za-z0-9_]*:', prev):
                start -= 1
            elif prev == '':
                start -= 1
            else:
                break

        # Find block end: scan forward through body data
        end = i
        while end + 1 < len(lines):
            next_line = lines[end + 1].strip()
            # Body lines: .byte, .long, .zero, .asciz, aligned_string, ldb, labels, blanks
            if (next_line.startswith('.byte') or
                next_line.startswith('.long') or
                next_line.startswith('.zero') or
                next_line.startswith('.asciz') or
                next_line.startswith('aligned_string') or
                next_line.startswith('.fill') or
                next_line.startswith('.incbin') or
                next_line.startswith('ldb') or
                next_line.startswith(';') or
                next_line == '' or
                re.match(r'^[A-Z_][A-Za-z0-9_]*:\s', next_line) or
                re.match(r'^[A-Z_][A-Za-z0-9_]*:$', next_line)):
                # Check if the next label starts a new naka_header block
                if re.match(r'^[A-Z_][A-Za-z0-9_]*:', next_line):
                    # Peek ahead: is the next non-blank, non-label line a naka_header?
                    j = end + 2
                    while j < len(lines) and (lines[j].strip() == '' or
                          re.match(r'^[A-Z_][A-Za-z0-9_]*:', lines[j].strip())):
                        j += 1
                    if j < len(lines) and 'naka_header' in lines[j]:
                        # This label starts the next widget - don't include it
                        break
                end += 1
            else:
                break

        blocks.append((start, end))

    # Merge overlapping/adjacent blocks (gap < 5 lines)
    merged = [blocks[0]]
    for start, end in blocks[1:]:
        prev_end = merged[-1][1]
        if start - prev_end <= 5:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))

    return merged


def merge_nearby_blocks(blocks, max_gap=80):
    """Merge blocks that are close together into larger extraction units.

    This creates fewer, larger include files instead of many tiny ones.
    Content between merged blocks (non-NAKA data) is included in the extraction.
    """
    if not blocks:
        return []

    merged = [blocks[0]]
    for start, end in blocks[1:]:
        prev_end = merged[-1][1]
        if start - prev_end <= max_gap:
            merged[-1] = (merged[-1][0], end)
        else:
            merged.append((start, end))

    return merged


def main():
    src = "maincpu/kn5000_v10_program.s"
    out_dir = "maincpu/naka"

    with open(src, 'rb') as f:
        data = f.read()
    lines = data.decode('latin-1').split('\n')

    # Find individual widget blocks
    blocks = find_naka_blocks(lines)
    print(f"Found {len(blocks)} individual NAKA widget blocks")

    # Merge nearby blocks into extraction units
    units = merge_nearby_blocks(blocks, max_gap=80)
    print(f"Merged into {len(units)} extraction units")

    # Create output directory
    os.makedirs(out_dir, exist_ok=True)

    # Track total stats
    total_extracted_lines = 0
    total_naka_count = 0

    # Process each extraction unit
    include_insertions = []  # (line_index, filename)
    lines_to_remove = set()  # line indices to remove from main file

    for idx, (start, end) in enumerate(units):
        # Count naka_headers in this unit
        naka_count = sum(1 for i in range(start, end + 1)
                        if 'naka_header' in lines[i])

        # Determine a descriptive filename
        # Use the ROM address range from labels
        start_addr = None
        end_addr = None
        for i in range(start, end + 1):
            m = re.match(r'^LABEL_([0-9A-Fa-f]+)', lines[i])
            if m:
                addr = int(m.group(1), 16)
                if start_addr is None:
                    start_addr = addr
                end_addr = addr
            # Also check named labels like FTDEMO_*, NAKA_*
            if not m:
                m2 = re.match(r'^(FTDEMO_|NAKA_)', lines[i])
                if m2 and start_addr is None:
                    # Try to find address from context
                    pass

        if start_addr and end_addr:
            filename = f"naka_{start_addr:06x}_{end_addr:06x}.s"
        else:
            filename = f"naka_block_{idx:03d}.s"

        filepath = os.path.join(out_dir, filename)

        # Extract the content
        extracted = lines[start:end + 1]

        # Write the include file
        content = '\n'.join(extracted)
        with open(filepath, 'w', encoding='latin-1') as f:
            f.write(content)
            f.write('\n')  # ensure trailing newline

        # Record what to do in the main file
        include_insertions.append((start, f'naka/{filename}'))
        for i in range(start, end + 1):
            lines_to_remove.add(i)

        total_extracted_lines += (end - start + 1)
        total_naka_count += naka_count

        # Report
        line_range = f"lines {start+1}-{end+1}"
        addr_range = ""
        if start_addr and end_addr:
            addr_range = f" (0x{start_addr:X}-0x{end_addr:X})"
        print(f"  {filename}: {naka_count} widgets, {end-start+1} lines, {line_range}{addr_range}")

    # Build the new main file
    new_lines = []
    i = 0
    insertion_map = {start: fname for start, fname in include_insertions}

    while i < len(lines):
        if i in insertion_map:
            # Add include directive
            new_lines.append(f'.include "{insertion_map[i]}"')
            # Skip all lines in this block
            while i in lines_to_remove:
                i += 1
        else:
            new_lines.append(lines[i])
            i += 1

    # Write the updated main file
    with open(src, 'w', encoding='latin-1') as f:
        f.write('\n'.join(new_lines))

    print(f"\nTotal: {total_naka_count} widgets in {total_extracted_lines} lines")
    print(f"Created {len(units)} include files in {out_dir}/")
    print(f"Main file: {len(include_insertions)} .include directives added")


if __name__ == "__main__":
    main()
