#!/usr/bin/env python3
"""Extract Toshi subsystem code and data into maincpu/toshi/ directory.

Reads maincpu/kn5000_v10_program.s in binary mode (Latin-1 safety)
and extracts two regions:

  Data region: lines 32951-39658 → toshi/toshi_data.s
    (contains all ED-range data: tone/style tables, mode/title definitions)
    (includes 4 NAKA .include directives that remain unchanged)
  Code region: lines 299738-299844 → toshi/toshi_code.s
    (InitializeToshi function with RegObjTable/RegObjTabl/RegMode/RegTitle calls)

The extracted regions are replaced with .include directives in the main file.
"""

import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(SCRIPT_DIR)
MAINCPU_DIR = os.path.join(REPO_DIR, "maincpu")
MAIN_FILE = os.path.join(MAINCPU_DIR, "kn5000_v10_program.s")
TOSHI_DIR = os.path.join(MAINCPU_DIR, "toshi")

# Line numbers (1-based) for extraction regions
DATA_START = 32951   # LABEL_ED0008:
DATA_END = 39658     # last line of LABEL_EDFFFE data

CODE_START = 299738  # InitializeToshi:
CODE_END = 299844    # ret


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
        print(f"  Line {lineno}: OK ({line[:70]})")

    print("Verifying boundaries...")
    # Data region boundaries
    check_line(32950, ".byte 0xed, 0x00, 0x02")   # last EC data line (before ED)
    check_line(DATA_START, "LABEL_ED0008")          # first ED label
    check_line(DATA_END, ".byte 0x00, 0xff")        # last ED data line
    check_line(39659, "LABEL_EE0010")               # first EE label (after ED)

    # Verify NAKA includes are within data region
    check_line(34237, '.include "naka/naka_ed2a9c_ed2b96.s"')
    check_line(34465, '.include "naka/naka_ed333c_ed35e4.s"')
    check_line(34734, '.include "naka/naka_ed3cc0_ed665a.s"')
    check_line(34840, '.include "naka/naka_ed803c_eda02c.s"')

    # Code region boundaries
    check_line(299737, "")                          # blank line before
    check_line(CODE_START, "InitializeToshi:")       # function start
    check_line(CODE_END, "ret")                     # function end
    check_line(299845, "")                          # blank line after
    check_line(299846, "InitializeKSS:")            # next function

    # Create toshi directory
    os.makedirs(TOSHI_DIR, exist_ok=True)

    # Extract data region: lines 32951-39658 (1-based)
    data_lines = lines[DATA_START - 1 : DATA_END]
    with open(os.path.join(TOSHI_DIR, "toshi_data.s"), "wb") as f:
        f.writelines(data_lines)
    print(f"Wrote toshi/toshi_data.s ({len(data_lines)} lines)")

    # Extract code region: lines 299738-299844
    code_lines = lines[CODE_START - 1 : CODE_END]
    with open(os.path.join(TOSHI_DIR, "toshi_code.s"), "wb") as f:
        f.writelines(code_lines)
    print(f"Wrote toshi/toshi_code.s ({len(code_lines)} lines)")

    # Now rebuild main file with replacements
    new_lines = []

    # Lines 1-32950 (before data region)
    new_lines.extend(lines[: DATA_START - 1])

    # Replace data region with include
    new_lines.append(b'.include "toshi/toshi_data.s"\n')

    # Lines 39659 through 299737 (between data and code regions)
    new_lines.extend(lines[DATA_END : CODE_START - 1])

    # Replace code region with include
    new_lines.append(b'.include "toshi/toshi_code.s"\n')

    # Lines 299845-end (after code region)
    new_lines.extend(lines[CODE_END:])

    # Write modified main file
    with open(MAIN_FILE, "wb") as f:
        f.writelines(new_lines)

    removed = total_lines - len(new_lines)
    print(f"Updated kn5000_v10_program.s: {len(new_lines)} lines ({removed} lines extracted)")
    print("Done! Run 'make clean && make all' and 'python3 scripts/compare_roms.py' to verify.")


if __name__ == "__main__":
    main()
