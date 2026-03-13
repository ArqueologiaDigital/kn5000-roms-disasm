#!/usr/bin/env python3
"""
Extract MSP_DefaultSettings + Composer_SettingsBlock + callback tables
from kn5000_v10_program.s into sequencer/composer_msp_defaults.s.

These form a single logical unit: the Composer/MSP (Music Style Preset)
configuration data, including default parameter values, UI config,
callback function pointer tables, and debug name strings.

Binary I/O for Latin-1 safety.
"""

import re
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAINCPU = os.path.join(REPO, 'maincpu')
MAIN_FILE = os.path.join(MAINCPU, 'kn5000_v10_program.s')


def main():
    with open(MAIN_FILE, 'rb') as f:
        lines = f.readlines()

    # Find MSP_DefaultSettings start
    start_idx = None
    for i, line in enumerate(lines):
        if line.startswith(b'MSP_DefaultSettings:'):
            start_idx = i
            break
    assert start_idx is not None, "MSP_DefaultSettings not found"

    # Find the end: after the last FuncName_ aligned_string line
    # followed by StrDesc_Empty_0 which is NOT part of our block
    end_idx = None
    for i in range(start_idx, len(lines)):
        if lines[i].startswith(b'StrDesc_Empty_0:'):
            end_idx = i
            break
    assert end_idx is not None, "End marker StrDesc_Empty_0 not found"

    # Extract lines [start_idx, end_idx)
    # Remove trailing blank lines
    block = lines[start_idx:end_idx]
    while block and block[-1].strip() == b'':
        block.pop()
    block.append(b'\n')

    print(f"Extracted lines {start_idx + 1}-{end_idx} ({len(block)} lines)")

    # Build the new file with header
    header = b"""; ===========================================================================
; Composer / MSP (Music Style Preset) Default Configuration
; ===========================================================================
;
; MSP is the Music Style Preset system - user-saveable performance setups
; that capture sound selections, accompaniment style, tempo, and panel
; settings. "Cmp" = Composer (the style editor/recorder). "S2c" = Song-to-
; Composer (import a song as a custom accompaniment).
;
; This file contains:
;
; 1. MSP_DefaultSettings - Initial parameter values for a new MSP preset
;    Three sub-blocks, each beginning with an "HK" signature (0x48, 0x4B):
;      Sub-block 1 (offset 0x00): Sound/voice defaults
;        - Default volumes (0x5A = 90 for 3 channels)
;        - Channel-to-part assignments (parts 1-2 across 8 slots)
;        - Reverb/chorus levels, voice enable bitmask (0x80..0x87)
;      Sub-block 2 (offset 0xE0): Sequencer defaults
;        - Tempo (0x28 = 40?), time signature, quantize settings
;      Sub-block 3 (offset 0x130): Accompaniment/rhythm defaults
;        - Part counts, group sizes, rhythm channel mapping
;        - Interleaved group/variation index tables
;        - Offset tables for rhythm pattern positioning
;
; 2. Composer_SettingsBlock - Composer UI configuration
;    - "HK" signature header
;    - Display layout parameters
;    - Bank name strings ("Compile Bank 1/2", "User Bank 1/2")
;    - Callback function pointer table (55 entries) for UI event handlers
;    - Null-terminated (.long 0 sentinel)
;
; 3. Composer_CallbackNameTable - Debug name string table
;    - Parallel array of .long pointers to FuncName_* strings
;    - One entry per callback, same order as the function pointer table
;    - Used by the NAKA widget system for debug/diagnostic display
;
; 4. FuncName_* strings - Null-terminated function name strings
;    - Each contains the ASCII name of a callback function
;    - Referenced only by Composer_CallbackNameTable
;
; ===========================================================================

"""

    out_path = os.path.join(MAINCPU, 'sequencer', 'composer_msp_defaults.s')
    with open(out_path, 'wb') as f:
        f.write(header)
        f.writelines(block)
    print(f"Wrote sequencer/composer_msp_defaults.s ({len(block)} lines + header)")

    # Replace extracted lines with .include
    replacement = [b'\t.include "sequencer/composer_msp_defaults.s"\n']
    new_lines = lines[:start_idx] + replacement + lines[end_idx:]

    with open(MAIN_FILE, 'wb') as f:
        f.writelines(new_lines)
    print(f"Main file: {len(lines)} -> {len(new_lines)} lines")


if __name__ == '__main__':
    main()
