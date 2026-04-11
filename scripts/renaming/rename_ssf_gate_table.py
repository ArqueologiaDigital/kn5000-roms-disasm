#!/usr/bin/env python3
"""Rename LABEL_E01F80 to SSF_PresentationGateTable and add header comments.

Safely handles Latin-1 encoded assembly file.

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python scripts/rename_ssf_gate_table.py
"""

import sys

ASM_FILE = 'maincpu/kn5000_v10_program.s'
SYM_FILE = 'symbols/maincpu_symbols_reference.txt'

OLD_NAME = 'LABEL_E01F80'
NEW_NAME = 'SSF_PresentationGateTable'

HEADER_COMMENT = """\
; =============================================================================
; SSF_PresentationGateTable (0xE01F80) -- 256-entry pointer lookup table
; =============================================================================
; Gates the SSF (Feature Demo) presentation system. Each entry is a .long
; pointer to a 16-bit value array (terminated by 0xFFFF) that lists the panel
; states in which the Feature Demo button should trigger event 0x1C00038.
;
; Index: DRAM byte at 0x8D38, loaded by LABEL_F0618F. Represents the current
; UI mode (e.g., 0x00 = boot/init, 0x01 = normal operation, 0xE0 = demo menu,
; 0xE4 = Feature Presentation sub-menu).
;
; Lookup: GroupBoxNotify_SendSSFEvent (0xF98697) reads table[index] to get a
; pointer P. If P points to {0xFFFE}, the event fires unconditionally. If P
; points to {0xFFFF}, the entry is disabled (no event). Otherwise, the array
; at P is scanned for a match against the current panel selection state
; (packed from DRAM bytes 0xC07D and 0xC080).
;
; Structure: 256 x .long entries (1024 bytes), addresses 0xE01F80-0xE02380.
; Targets: arrays of 16-bit values in ROM range 0xE014CE-0xE01F7E.
; =============================================================================
"""


def process_asm(filepath):
    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    original_count = len(lines)
    print(f"Read {original_count} lines from {filepath}")

    changes = 0

    # 1. Rename the label definition
    for i in range(len(lines)):
        if lines[i].strip() == f'{OLD_NAME}:':
            lines[i] = lines[i].replace(f'{OLD_NAME}:', f'{NEW_NAME}:')
            changes += 1
            print(f"  Renamed label at line {i+1}")
            break

    # 2. Update comment references
    for i in range(len(lines)):
        if 'ROM table at 0xE01F80' in lines[i]:
            lines[i] = lines[i].replace(
                'ROM table at 0xE01F80',
                f'{NEW_NAME} (ROM 0xE01F80)')
            changes += 1
            print(f"  Updated comment at line {i+1}")
        if 'ROM[0xE01F80 + R*4]' in lines[i]:
            lines[i] = lines[i].replace(
                'ROM[0xE01F80 + R*4]',
                f'{NEW_NAME}[R]')
            changes += 1
            print(f"  Updated comment at line {i+1}")

    # 3. Insert header comment block before the renamed label
    header_lines = [line + '\n' for line in HEADER_COMMENT.rstrip('\n').split('\n')]
    for i in range(len(lines)):
        if lines[i].strip() == f'{NEW_NAME}:':
            lines[i:i] = header_lines
            changes += 1
            print(f"  Inserted {len(header_lines)}-line header at line {i+1}")
            break

    if changes == 0:
        print("WARNING: No changes made!")
        return

    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(lines)

    new_count = len(lines)
    print(f"Written {new_count} lines (was {original_count}, added {new_count - original_count})")


def process_symbols(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if f'{OLD_NAME} ' in content:
        content = content.replace(f'{OLD_NAME} 0xE01F80', f'{NEW_NAME} 0xE01F80')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")
    else:
        print(f"WARNING: {OLD_NAME} not found in {filepath}")


if __name__ == '__main__':
    process_asm(ASM_FILE)
    process_symbols(SYM_FILE)
    print("\nDone. Run 'make clean && make all' to verify build.")
