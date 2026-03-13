#!/usr/bin/env python3
"""
Move sound category metadata from kn5000_v10_program.s into audio/sound_data.s.
Rename opaque LABEL_* to meaningful names.

Binary I/O for Latin-1 safety.
"""

import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAINCPU = os.path.join(REPO, 'maincpu')
MAIN_FILE = os.path.join(MAINCPU, 'kn5000_v10_program.s')
SOUND_DATA = os.path.join(MAINCPU, 'audio', 'sound_data.s')


def read_bytes(path):
    with open(path, 'rb') as f:
        return f.read()


def write_bytes(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def main():
    # --- Step 1: Rename labels in all .s files ---
    renames = {
        b'LABEL_E02380': b'SoundData_RegionID',
        b'LABEL_E0239C': b'SoundData_CategoryDescPtr',
        b'LABEL_E023A0': b'SoundData_CategoryDesc',
    }

    # Find all .s files
    s_files = []
    for root, dirs, files in os.walk(MAINCPU):
        for fn in files:
            if fn.endswith('.s'):
                s_files.append(os.path.join(root, fn))

    total_renames = 0
    for path in sorted(s_files):
        content = read_bytes(path)
        original = content
        for old, new in sorted(renames.items(), key=lambda x: -len(x[0])):
            n = content.count(old)
            if n > 0:
                content = content.replace(old, new)
                total_renames += n
        if content != original:
            write_bytes(path, content)
            rel = os.path.relpath(path, MAINCPU)
            print(f'  Renamed labels in {rel}')

    print(f'  Total label renames: {total_renames}')

    # --- Step 2: Read main file, extract metadata block ---
    main_lines = read_bytes(MAIN_FILE).split(b'\n')

    # Find the section boundaries
    start_idx = None
    end_idx = None
    for i, line in enumerate(main_lines):
        if b'; --- Instrument Sound Data & Category Metadata ---' in line:
            start_idx = i
        if b'MEMORY B' in line and b'.ascii' in line:
            end_idx = i
            break

    assert start_idx is not None, "Could not find start marker"
    assert end_idx is not None, "Could not find end marker"

    # Extract lines start_idx through end_idx (inclusive)
    extracted = main_lines[start_idx:end_idx + 1]
    print(f'\n  Extracted lines {start_idx + 1}-{end_idx + 1} from main file')

    # Remove those lines from main file, plus trailing blank line
    # Also remove the blank line before .include "audio/sound_data.s"
    remaining = main_lines[:start_idx] + main_lines[end_idx + 1:]
    # Clean up: the next line should be blank, then .include "audio/sound_data.s"
    # Remove extra blank lines
    write_bytes(MAIN_FILE, b'\n'.join(remaining))
    print(f'  Main file: {len(main_lines)} -> {len(remaining)} lines')

    # --- Step 3: Prepend metadata to sound_data.s with header ---
    sound_data_content = read_bytes(SOUND_DATA)

    header = b"""; ===========================================================================
; Sound Data Section - Instrument Category Metadata & Sound Data Includes
; ===========================================================================
;
; This file contains:
;   1. Region identifier string (16-byte padded, possibly "HK" = Hong Kong variant)
;   2. Category table descriptor structure:
;        +0: pointer to SoundData_CategoryDesc
;        SoundData_CategoryDesc layout:
;          +0  .long  pointer to SOUND_CATEGORY_NAMES string table
;          +4  .long  entry count (18 = number of categories)
;          +8  .long  stride or field offset (0x28 = 40)
;          +12 .long  sentinel (0xFFFFFFFF = end-of-descriptor)
;   3. Sound data section pointer table (16 entries, one per instrument category)
;   4. Sound category name table (18 x 16-char fixed-width, space-padded)
;   5. Per-category instrument data includes
;
; ===========================================================================

"""

    # Build the metadata section from the extracted lines
    # We already renamed the labels, so just join them
    metadata = b'\n'.join(extracted) + b'\n\n'

    new_content = header + metadata + sound_data_content
    write_bytes(SOUND_DATA, new_content)
    print(f'  Updated audio/sound_data.s with metadata header')


if __name__ == '__main__':
    main()
