#!/usr/bin/env python3
"""Extract HAMA subsystem code and data into maincpu/hama/ directory.

Reads maincpu/kn5000_v10_program.s in binary mode (Latin-1 safety)
and extracts two regions:

  Data region: lines 4630-4881 → hama/hama_data.s
  Code region: lines 88577-88787, 88790-88882 → hama/hama_code.s
               (with .include "hama/fd_test_code.s" between the two blocks)

The extracted regions are replaced with .include directives in the main file.
"""

import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(SCRIPT_DIR)
MAINCPU_DIR = os.path.join(REPO_DIR, "maincpu")
MAIN_FILE = os.path.join(MAINCPU_DIR, "kn5000_v10_program.s")
HAMA_DIR = os.path.join(MAINCPU_DIR, "hama")

# Line numbers (1-based) for extraction regions
DATA_START = 4630
DATA_END = 4881
FD_TEST_DATA_INCLUDE = 4882  # .include "fd_test_data.s"

CODE_START = 88577
FD_TEST_CODE_INCLUDE = 88788  # .include "fd_test_code.s"
CODE_RESUME = 88790
CODE_END = 88882


def main():
    # Read entire file in binary mode (Latin-1 safety)
    with open(MAIN_FILE, "rb") as f:
        lines = f.readlines()

    total_lines = len(lines)
    print(f"Read {total_lines} lines from kn5000_v10_program.s")

    # Verify boundary markers (1-based → 0-based index)
    def check_line(lineno, expected_fragment):
        line = lines[lineno - 1].decode("latin-1").strip()
        if expected_fragment not in line:
            print(f"ERROR: Line {lineno} expected to contain '{expected_fragment}'")
            print(f"  Actual: {line!r}")
            sys.exit(1)
        print(f"  Line {lineno}: OK ({line[:60]})")

    print("Verifying boundaries...")
    check_line(4629, "LABEL_E1F012")
    check_line(DATA_START, "LABEL_E1F032")
    check_line(DATA_END, 'aligned_string "FD SAVE/LOAD TEST"')
    check_line(FD_TEST_DATA_INCLUDE, '.include "fd_test_data.s"')
    check_line(4883, "RESOURCE_INFO_HANDLER_OFFSETS")

    check_line(88574, "ret")
    check_line(CODE_START, ".macro RegObjTableHama")
    check_line(88786, ".byte 0x0e")
    check_line(FD_TEST_CODE_INCLUDE, '.include "fd_test_code.s"')
    check_line(CODE_RESUME, "LABEL_F1E89A")
    check_line(CODE_END, "ret")
    check_line(88883, "")  # blank line
    check_line(88884, "LABEL_F1EA20")

    # Create hama directory
    os.makedirs(HAMA_DIR, exist_ok=True)

    # Extract data region: lines 4630-4881 (1-based)
    data_lines = lines[DATA_START - 1 : DATA_END]
    with open(os.path.join(HAMA_DIR, "hama_data.s"), "wb") as f:
        f.writelines(data_lines)
    print(f"Wrote hama/hama_data.s ({len(data_lines)} lines)")

    # Extract code region: lines 88577-88786 + include + 88790-88882
    code_block1 = lines[CODE_START - 1 : 88786]  # lines 88577-88786
    code_block2 = lines[CODE_RESUME - 1 : CODE_END]  # lines 88790-88882
    fd_include = b'.include "hama/fd_test_code.s"\n'

    with open(os.path.join(HAMA_DIR, "hama_code.s"), "wb") as f:
        f.writelines(code_block1)
        f.write(b"\n")
        f.write(fd_include)
        f.write(b"\n")
        f.writelines(code_block2)
    print(f"Wrote hama/hama_code.s ({len(code_block1)} + {len(code_block2)} lines)")

    # Now rebuild main file with replacements
    new_lines = []

    # Lines 1-4629 (before data region)
    new_lines.extend(lines[: DATA_START - 1])

    # Replace data region (lines 4630-4882) with includes
    new_lines.append(b'.include "hama/hama_data.s"\n')
    new_lines.append(b'.include "hama/fd_test_data.s"\n')

    # Lines 4883-88576 (between data and code regions)
    new_lines.extend(lines[FD_TEST_DATA_INCLUDE : CODE_START - 1])

    # Replace code region (lines 88577-88882) with include
    new_lines.append(b'.include "hama/hama_code.s"\n')

    # Lines 88883-end (after code region)
    new_lines.extend(lines[CODE_END:])

    # Write modified main file
    with open(MAIN_FILE, "wb") as f:
        f.writelines(new_lines)

    removed = total_lines - len(new_lines)
    print(f"Updated kn5000_v10_program.s: {len(new_lines)} lines ({removed} lines extracted)")
    print("Done! Run 'make clean && make all' and 'python3 scripts/compare_roms.py' to verify.")


if __name__ == "__main__":
    main()
