#!/usr/bin/env python3
"""Rename LABEL_E0174E to SSF_GateStates_Mode05 and add header comments.

Safely handles Latin-1 encoded assembly file.

Usage:
    cd /mnt/shared/kn5000-roms-disasm
    python scripts/rename_ssf_gate_states_05.py
"""

ASM_FILE = 'maincpu/kn5000_v10_program.s'
SYM_FILE = 'symbols/maincpu_symbols_reference.txt'

OLD_NAME = 'LABEL_E0174E'
NEW_NAME = 'SSF_GateStates_Mode05'

HEADER_COMMENT = """\
; -----------------------------------------------------------------------------
; SSF_GateStates_Mode05 (0xE0174E) -- SSF gate filter for UI mode 0x05
; -----------------------------------------------------------------------------
; State-value array referenced by SSF_PresentationGateTable[5]. Contains 14
; allowed (chain, param) pairs -- all for event chain 0x92 with params 0x00
; through 0x0D -- that permit GroupBoxNotify_SendSSFEvent (0xF98697) to send
; event 0x1C00038.
;
; Format: array of 16-bit LE values, terminated by 0xFFFF.
; Each value encodes (chain_index << 8) | param, compared against the packed
; panel selection state (DRAM 0xC080 << 8) | (DRAM 0xC07D).
;
; Entries: 14 states + terminator = 30 bytes (0xE0174E-0xE0176B).
; -----------------------------------------------------------------------------
"""


def process_asm(filepath):
    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    original_count = len(lines)
    print(f"Read {original_count} lines from {filepath}")

    changes = 0

    # 1. Rename all occurrences of the label (definition and .long references)
    for i in range(len(lines)):
        if OLD_NAME in lines[i]:
            lines[i] = lines[i].replace(OLD_NAME, NEW_NAME)
            changes += 1
            print(f"  Renamed at line {i+1}: {lines[i].rstrip()}")

    # 2. Insert header comment block before the renamed label definition
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
        content = content.replace(f'{OLD_NAME} 0xE0174E', f'{NEW_NAME} 0xE0174E')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")
    else:
        print(f"WARNING: {OLD_NAME} not found in {filepath}")


if __name__ == '__main__':
    process_asm(ASM_FILE)
    process_symbols(SYM_FILE)
    print("\nDone. Run 'make clean && make all' to verify build.")
