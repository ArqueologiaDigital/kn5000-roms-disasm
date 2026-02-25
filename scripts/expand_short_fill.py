#!/usr/bin/env python3
"""Replace short .fill and .zero directives with explicit .byte sequences.

- .fill N, 1, 0xVV (N <= 4) -> .byte 0xVV, 0xVV, ...
- .zero N (N <= 4) -> .byte 0x00, 0x00, ...
"""

import re
import os
import sys

FILL_RE = re.compile(r'^(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*(0x[0-9a-fA-F]+|\d+)(.*)')
ZERO_RE = re.compile(r'^(\s*)\.zero\s+(\d+)(.*)')

MAX_EXPAND = 4


def process_line(line):
    m = FILL_RE.match(line.rstrip('\n'))
    if m:
        indent, count_s, val_s, rest = m.groups()
        count = int(count_s)
        val = int(val_s, 0)
        if 1 <= count <= MAX_EXPAND:
            bytes_str = ', '.join(f'0x{val:02x}' for _ in range(count))
            return f'{indent}.byte {bytes_str}{rest}\n'

    m = ZERO_RE.match(line.rstrip('\n'))
    if m:
        indent, count_s, rest = m.groups()
        count = int(count_s)
        if 1 <= count <= MAX_EXPAND:
            bytes_str = ', '.join('0x00' for _ in range(count))
            return f'{indent}.byte {bytes_str}{rest}\n'

    return line


def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    new_lines = [process_line(line) for line in lines]

    if new_lines != lines:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        return True
    return False


def main():
    target_dirs = ['maincpu', 'subcpu', 'hdae5000', 'table_data', 'custom_data']
    for tdir in target_dirs:
        if not os.path.exists(tdir):
            continue
        for root, dirs, files in os.walk(tdir):
            for fname in files:
                if fname.endswith('.s'):
                    path = os.path.join(root, fname)
                    if process_file(path):
                        print(f"Updated {path}")


if __name__ == '__main__':
    main()
