#!/usr/bin/env python3
"""error_number_table.py -- what does the KN5000's "ERROR 08" actually mean?

QUESTION ANSWERED
    The sibling KN7000's floppy FORMAT fails with "ERROR 08" and the KN7000 notes
    treat that number as if it identified a decision point in the disk code.  The
    KN5000 uses the same Technics error-message scheme and its firmware is now
    complete source, so the number's meaning can be settled from the ROM:
    which numbered message is which, and what produces number 8.

    This script (a) lists every "ERROR NN" string in the program ROM with its
    address, and (b) decodes the error-code -> message-number table that
    FileIO_ValidateSignedValue indexes, so the mapping is not taken on trust.

COMMAND
    cd ~/compartilhado/disasm-lanes/drvkn5000
    python3 scripts/analysis/error_number_table.py original_ROMs/kn5000_v10_program.rom

WHAT THE TABLE IS
    At ROM 0x00EA067C (file offset 0xA067C, link base 0x00E00000) there is an
    array of 4-byte entries { int16 code, uint8 message_number, uint8 pad },
    terminated by { 0, 255 }.  FileIO_ValidateSignedValue
    (v10/maincpu/demo/file_demo_proc.s:8711) walks it to turn a negative return
    code into the message number stored at DRAM 0x7F42, which IvMesageProc
    (v10/maincpu/ui/drawbar_panel_ui.s:8350) renders.

    The caller supplies a DEFAULT message number for codes not in the table.
    FmmFormatFunc's default is 8 (v10/maincpu/file_io/disk_operations.s:539,
    `ldw bc, 0x8`), and the format worker's own failure return is -6
    (file_demo_proc.s:4670, `ldw hl, 0xfffa`), which the table also maps to 8.
    So on this firmware EIGHT IS THE FORMAT HANDLER'S CATCH-ALL: it says the
    format returned failure and says nothing about where.
"""
import re, struct, sys

TABLE_ADDR = 0x00EA067C
LINK_BASE  = 0x00E00000

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else 'original_ROMs/kn5000_v10_program.rom'
    d = open(path, 'rb').read()
    print(f'# {path}, {len(d)} bytes, link base {LINK_BASE:#08x}\n')

    print('===== "ERROR NN" strings in the program ROM =====')
    for m in re.finditer(rb'ERROR \d\d[^\x00]{0,20}', d):
        print(f'  {LINK_BASE + m.start():#08x}  {m.group(0).decode("latin-1")}')

    off = TABLE_ADDR - LINK_BASE
    print(f'\n===== error-code -> message-number table at {TABLE_ADDR:#08x} =====')
    i = 0
    while True:
        code, msg, pad = struct.unpack_from('<hBB', d, off + i * 4)
        if code == 0:
            print(f'  terminator {{ 0, {msg} }} -- codes not listed take the '
                  f"caller's default message number")
            break
        print(f'  {code:6d} -> message {msg}')
        i += 1
        if i > 64:
            print('  !! no terminator within 64 entries -- table base is wrong')
            break

    print('\n===== the format path =====')
    print('  format_FD (v10/maincpu/sequencer/smf_event_processor.s:8894) returns 0')
    print('  IMMEDIATELY, without touching the FDC, unless WA is 2 (2DD) or 3 (2HD).')
    print('  FileIO_ValidateRecord_CheckSize (demo/file_demo_proc.s:4656) turns that')
    print('  0 into -6, and FmmFormatFunc (file_io/disk_operations.s:539) maps it')
    print('  with a default of 8 -> "ERROR 08".')

if __name__ == '__main__':
    main()
