#!/usr/bin/env python3
"""
Two cleanups across all maincpu .s files:

1. Remove redundant address comments (e.g., "; e0018e" at end of line).
   These are no longer needed with the LLVM toolchain.

2. Collapse label + next-line .include/.incbin into single aligned lines,
   removing blank lines between consecutive entries in such blocks.

Binary I/O for Latin-1 safety.
"""

import re
import os

MAINCPU = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')


def process_file(path):
    with open(path, 'rb') as f:
        data = f.read()
    original = data

    # Step 1: Remove address comments like "\t; E023F0" or "\t; e0018e"
    # These appear as tab + semicolon + space + 4-6 hex digits at end of line
    # Be careful not to remove meaningful comments that happen to have hex
    addr_removed = 0
    def remove_addr_comment(m):
        nonlocal addr_removed
        addr_removed += 1
        return m.group(1)  # keep everything before the address comment
    # Match: (content before)\t; followed by exactly a hex address (no other text) at EOL
    data = re.sub(rb'([^\n]+?)\t; [0-9a-fA-F]{4,6}\s*$', remove_addr_comment, data, flags=re.MULTILINE)

    # Step 2: Collapse label + next-line .include/.incbin and align blocks
    lines = data.split(b'\n')
    new_lines = []
    i = 0
    collapse_count = 0

    while i < len(lines):
        line = lines[i]

        # Check if this is a label line followed by .include/.incbin on next line
        label_match = re.match(rb'^(\S+:)\s*$', line)
        if label_match and i + 1 < len(lines):
            next_line = lines[i + 1]
            inc_match = re.match(rb'^\t(\.(include|incbin)\s+.+)$', next_line)
            if inc_match:
                # Collapse: label + tab + directive
                new_lines.append(label_match.group(1) + b'\t' + inc_match.group(1))
                collapse_count += 1
                i += 2
                # Skip blank line after if present
                if i < len(lines) and lines[i].strip() == b'':
                    i += 1
                continue

        # Also handle label with trailing address comment + next line include
        label_match2 = re.match(rb'^(\S+:)\s*$', line)
        if not label_match2:
            # Already cleaned address comment, just a label with nothing after
            pass

        new_lines.append(line)
        i += 1

    data = b'\n'.join(new_lines)

    # Step 3: Find consecutive label+include lines and align them as blocks
    lines = data.split(b'\n')
    new_lines = []
    i = 0

    while i < len(lines):
        # Detect a block of consecutive label+include/incbin lines
        block = []
        j = i
        while j < len(lines):
            m = re.match(rb'^(\S+:)\t(\.(include|incbin)\s+.+)$', lines[j])
            if m:
                block.append((m.group(1), m.group(2)))
                j += 1
            else:
                break

        if len(block) >= 2:
            # Align the block
            max_label_len = max(len(label) for label, _ in block)
            col = ((max_label_len + 8) // 8) * 8  # next tab stop
            for label, directive in block:
                current = len(label)
                tabs_needed = (col - current + 7) // 8
                if tabs_needed < 1:
                    tabs_needed = 1
                new_lines.append(label + b'\t' * tabs_needed + directive)
            i = j
        else:
            new_lines.append(lines[i])
            i += 1

    data = b'\n'.join(new_lines)

    if data != original:
        with open(path, 'wb') as f:
            f.write(data)
        return addr_removed, collapse_count
    return 0, 0


def main():
    total_addr = 0
    total_collapse = 0

    s_files = []
    for root, dirs, files in os.walk(MAINCPU):
        for fn in files:
            if fn.endswith('.s'):
                s_files.append(os.path.join(root, fn))

    for path in sorted(s_files):
        addr, collapse = process_file(path)
        if addr or collapse:
            rel = os.path.relpath(path, MAINCPU)
            parts = []
            if addr:
                parts.append(f'{addr} addr comments')
            if collapse:
                parts.append(f'{collapse} collapsed')
            print(f'  {rel}: {", ".join(parts)}')
            total_addr += addr
            total_collapse += collapse

    print(f'\nTotal: {total_addr} address comments removed, {total_collapse} label+include pairs collapsed')


if __name__ == '__main__':
    main()
