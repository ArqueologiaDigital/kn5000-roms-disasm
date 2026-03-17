#!/usr/bin/env python3
"""Extract FD SAVE/LOAD TEST dialog data and code to dedicated files.

Moves the type-0x16 widget structures, associated NAKA widgets, pointer tables,
strings, and the FDLoadSaveTest/HamaListProc code into two dedicated include files:
  - maincpu/fd_test_data.s  (data region: widget structures + tables + strings)
  - maincpu/fd_test_code.s  (code region: FDLoadSaveTest + HamaListProc)

Also converts .byte 0x16 headers to naka_header NAKA_TYPE_DIAGLIST.
"""

import sys

MAIN_FILE = "maincpu/kn5000_v10_program.s"
NAKA_FILE = "maincpu/naka/naka_e1f868_e1fd3e.s"
DATA_OUT = "maincpu/fd_test_data.s"
CODE_OUT = "maincpu/fd_test_code.s"


def find_line(lines, pattern, start=0):
    """Find line index containing pattern, starting from start."""
    for i in range(start, len(lines)):
        if pattern in lines[i]:
            return i
    return None


def main():
    # Read files in Latin-1
    with open(MAIN_FILE, 'r', encoding='latin-1') as f:
        main_lines = f.read().split('\n')

    with open(NAKA_FILE, 'r', encoding='latin-1') as f:
        naka_lines = f.read().split('\n')

    # === Locate data region in main file ===
    # Starts at LABEL_E1F794 (first type-0x16 widget)
    data_start = find_line(main_lines, 'LABEL_E1F794:')
    if data_start is None:
        print("ERROR: Could not find LABEL_E1F794", file=sys.stderr)
        sys.exit(1)
    print(f"Data start: line {data_start + 1} (LABEL_E1F794)")

    # Ends at the .include of the old naka file (inclusive)
    naka_include = find_line(main_lines, '.include "naka/naka_e1f868_e1fd3e.s"', data_start)
    if naka_include is None:
        print("ERROR: Could not find naka include directive", file=sys.stderr)
        sys.exit(1)
    print(f"Old naka include: line {naka_include + 1}")

    data_end = naka_include  # inclusive

    # === Locate code region in main file ===
    code_start = find_line(main_lines, 'FDLoadSaveTest:')
    if code_start is None:
        print("ERROR: Could not find FDLoadSaveTest", file=sys.stderr)
        sys.exit(1)

    # Find HamaListProc and its ret
    hama_start = find_line(main_lines, 'HamaListProc:', code_start)
    if hama_start is None:
        print("ERROR: Could not find HamaListProc", file=sys.stderr)
        sys.exit(1)

    # Find the ret after HamaListProc
    code_end = find_line(main_lines, '\tret', hama_start)
    if code_end is None:
        print("ERROR: Could not find ret after HamaListProc", file=sys.stderr)
        sys.exit(1)
    print(f"Code region: lines {code_start + 1}-{code_end + 1} (FDLoadSaveTest through HamaListProc)")

    # === Build fd_test_data.s ===
    # Content from main file (type-0x16 widgets + type-0x29 widget)
    data_from_main = main_lines[data_start:data_end]  # excludes the .include line

    # Content from naka file (everything except RESOURCE_INFO_HANDLER_OFFSETS at end)
    # Find where RESOURCE_INFO_HANDLER_OFFSETS starts in the naka file
    rih_line = find_line(naka_lines, 'RESOURCE_INFO_HANDLER_OFFSETS:')
    if rih_line is not None:
        naka_content = naka_lines[:rih_line]
        # Strip trailing empty lines
        while naka_content and naka_content[-1].strip() == '':
            naka_content.pop()
    else:
        naka_content = naka_lines[:]

    # Combine
    data_content = data_from_main + naka_content

    # Convert .byte 0x16, 0x00, 0x60, 0x01 to naka_header NAKA_TYPE_DIAGLIST
    converted = 0
    new_data_content = []
    for line in data_content:
        stripped = line.strip()
        # Pattern 1: .byte 0x16, 0x00, 0x60, 0x01 (header only)
        if stripped == '.byte 0x16, 0x00, 0x60, 0x01':
            indent = line[:len(line) - len(line.lstrip())]
            new_data_content.append(f'{indent}naka_header NAKA_TYPE_DIAGLIST')
            converted += 1
        # Pattern 2: .byte 0x16, 0x00, 0x60, 0x01, ... (header + body on same line)
        elif stripped.startswith('.byte 0x16, 0x00, 0x60, 0x01, '):
            indent = line[:len(line) - len(line.lstrip())]
            remaining = stripped[len('.byte 0x16, 0x00, 0x60, 0x01, '):]
            new_data_content.append(f'{indent}naka_header NAKA_TYPE_DIAGLIST')
            new_data_content.append(f'{indent}.byte {remaining}')
            converted += 1
        else:
            new_data_content.append(line)

    print(f"Converted {converted} type-0x16 headers to naka_header NAKA_TYPE_DIAGLIST")

    # Write fd_test_data.s
    with open(DATA_OUT, 'w', encoding='latin-1') as f:
        f.write('\n'.join(new_data_content))
        f.write('\n')
    print(f"Wrote {DATA_OUT}: {len(new_data_content)} lines")

    # === Build fd_test_code.s ===
    code_content = main_lines[code_start:code_end + 1]

    with open(CODE_OUT, 'w', encoding='latin-1') as f:
        f.write('\n'.join(code_content))
        f.write('\n')
    print(f"Wrote {CODE_OUT}: {len(code_content)} lines")

    # === Update main file ===
    new_main = []

    # Before data region
    new_main.extend(main_lines[:data_start])

    # Replace data region with include
    new_main.append('.include "fd_test_data.s"')

    # RESOURCE_INFO_HANDLER_OFFSETS label (was at end of naka file)
    if rih_line is not None:
        new_main.append('RESOURCE_INFO_HANDLER_OFFSETS:')

    # After data region (skip the old .include line too)
    after_data_start = data_end + 1

    # Before code region
    new_main.extend(main_lines[after_data_start:code_start])

    # Replace code region with include
    new_main.append('.include "fd_test_code.s"')

    # After code region
    new_main.extend(main_lines[code_end + 1:])

    # Write updated main file
    with open(MAIN_FILE, 'w', encoding='latin-1') as f:
        f.write('\n'.join(new_main))
    print(f"Updated {MAIN_FILE}: {len(main_lines)} -> {len(new_main)} lines")

    # Summary
    data_lines_extracted = len(new_data_content)
    code_lines_extracted = len(code_content)
    total = data_lines_extracted + code_lines_extracted
    print(f"\nTotal: {total} lines extracted ({data_lines_extracted} data + {code_lines_extracted} code)")
    print(f"\nRemember to delete {NAKA_FILE} after verifying the build!")


if __name__ == "__main__":
    main()
