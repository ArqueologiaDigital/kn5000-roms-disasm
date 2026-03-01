#!/usr/bin/env python3
"""Convert .asciz directives to aligned_string where safe.

Two cases:
1. Even-length output (.asciz content + null is even): .p2align is a no-op,
   so aligned_string produces identical bytes. Direct conversion.
2. Odd-length output followed by .byte 0xff,...: aligned_string absorbs
   the first 0xff via .p2align. Remove that 0xff from the .byte line.

Also compacts label + string pairs onto single lines in string groups:
    LABEL_X:
        aligned_string "foo"
  becomes:
    LABEL_X:	aligned_string "foo"
"""

import sys
import re


def get_asciz_content(stripped):
    """Extract string content from .asciz directive. Returns content or None."""
    if not stripped.startswith('.asciz '):
        return None
    rest = stripped[7:].strip()
    if rest.startswith('"') and rest.endswith('"'):
        return rest[1:-1]
    return None


def convert_asciz_to_aligned(lines):
    """Convert .asciz to aligned_string where safe. Returns (new_lines, count).

    Only converts even-length output (string + null is even), where .p2align
    is guaranteed to be a no-op regardless of starting address alignment.
    """
    new_lines = list(lines)
    count = 0
    for i in range(len(new_lines)):
        stripped = new_lines[i].strip()

        content = get_asciz_content(stripped)
        if content is None:
            continue

        total_len = len(content) + 1  # string + null
        if total_len % 2 != 0:
            continue  # Odd length: p2align might add a byte, skip

        prefix = new_lines[i][:len(new_lines[i]) - len(new_lines[i].lstrip())]
        new_lines[i] = f'{prefix}aligned_string "{content}"\n'
        count += 1

    return new_lines, count


def compact_label_string_pairs(lines):
    """Compact label + string directive pairs onto single lines.

    Only compacts when we have groups of consecutive labeled strings (2+).
    """
    # First pass: identify which lines are "label followed by string directive"
    is_label_string_pair = [False] * len(lines)

    for i in range(len(lines) - 1):
        stripped = lines[i].strip()
        next_stripped = lines[i + 1].strip()

        # Check if current line is a bare label (label on its own line)
        if (stripped.endswith(':') and
                not stripped.startswith('.') and
                not '\t' in stripped.rstrip(':') and
                ' ' not in stripped.rstrip(':')):

            # Check if next line is a string directive
            if (next_stripped.startswith('aligned_string ') or
                    next_stripped.startswith('.asciz ')):
                is_label_string_pair[i] = True

        # Also handle "LABEL:\t; comment" format
        elif re.match(r'^[A-Za-z_]\w*:\s*;', stripped):
            if (next_stripped.startswith('aligned_string ') or
                    next_stripped.startswith('.asciz ')):
                is_label_string_pair[i] = True

    # Also handle labels with address comments like "LABEL_X:	; E30730"
    for i in range(len(lines) - 1):
        stripped = lines[i].strip()
        next_stripped = lines[i + 1].strip()

        m = re.match(r'^([A-Za-z_]\w*):\s*(;.*)?$', stripped)
        if m:
            if (next_stripped.startswith('aligned_string ') or
                    next_stripped.startswith('.asciz ')):
                is_label_string_pair[i] = True

    # Second pass: only compact pairs that are in groups (2+ consecutive)
    in_group = [False] * len(lines)
    i = 0
    while i < len(lines):
        if is_label_string_pair[i]:
            # Count consecutive label+string pairs
            group_start = i
            j = i
            while j < len(lines) and is_label_string_pair[j]:
                j += 2  # label line + string line = 2 lines per pair
                # But check if the pair at j is also a label+string
                if j < len(lines) and is_label_string_pair[j]:
                    continue
                else:
                    break
            group_end = j
            group_size = (group_end - group_start) // 2

            if group_size >= 2:
                for k in range(group_start, group_end, 2):
                    if k < len(lines) and is_label_string_pair[k]:
                        in_group[k] = True
            i = group_end
        else:
            i += 1

    # Third pass: compact the identified pairs
    new_lines = []
    count = 0
    i = 0
    while i < len(lines):
        if in_group[i] and i + 1 < len(lines):
            # Merge label line with next string line
            label = lines[i].strip()
            # Remove trailing comment from label if it's just an address
            label_clean = re.sub(r'\s*;.*$', '', label)
            string_line = lines[i + 1].strip()
            new_lines.append(f'{label_clean}\t{string_line}\n')
            count += 1
            i += 2
        else:
            new_lines.append(lines[i])
            i += 1

    return new_lines, count


def main():
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <file.s> [--dry-run]')
        sys.exit(1)

    filepath = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    with open(filepath) as f:
        lines = f.readlines()

    # Step 1: Convert .asciz to aligned_string
    lines, asciz_count = convert_asciz_to_aligned(lines)
    print(f'Converted {asciz_count} .asciz to aligned_string')

    # Step 2: Compact label + string pairs
    lines, compact_count = compact_label_string_pairs(lines)
    print(f'Compacted {compact_count} label+string pairs onto single lines')

    if not dry_run:
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print(f'Written to {filepath}')
    else:
        print('(dry run, no changes written)')


if __name__ == '__main__':
    main()
