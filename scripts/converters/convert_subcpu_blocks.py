#!/usr/bin/env python3
"""Convert specific .byte blocks in subcpu payload to native instructions with documentation.

Each block has been analyzed and given documentation comments describing its purpose.
Uses binary I/O to handle encoding safely.
"""

import re
import os

# Each entry: (label_to_find, comment_lines, instruction_lines)
# The script finds the label, locates the .byte block that follows, and replaces it.
CONVERSIONS = [
    # Block 1: Line 10697-10705, LABEL_020A22 (67 bytes)
    # Five small utility routines for managing audio buffer pointers
    ('LABEL_020A22', [
        '; --- Audio buffer pointer load/store utilities ---',
        '; Five small routines that load/store 16-bit pointer values',
        '; from the audio buffer control block at 0x041138-0x041142.',
        '; Each routine saves/restores caller registers.',
    ], [
        '\tpushw\thl',           # save hl
        '\tld16_24\thl, 266554', # ld hl, (0x04113A)
        '\tst16_24\t266552, hl', # st (0x041138), hl
        '\tpopw\thl',            # restore hl
        '\tret',
        '\tpushw\tix',
        '\tpush\txde',
        '\tlda_24\txde, 266562', # load ptr to 0x041142
        '\tcall\t133932',        # call write handler
        '\tpop\txde',
        '\tpopw\tix',
        '\tret',
        '\tpushw\tix',
        '\tpush\txde',
        '\tlda_24\txde, 266562',
        '\tcall\t133959',        # call alternate write handler
        '\tpop\txde',
        '\tpopw\tix',
        '\tret',
        '\tpushw\thl',
        '\tld16_24\thl, 266556', # ld hl, (0x04113C)
        '\tst16_24\t266554, hl', # st (0x04113A), hl
        '\tpopw\thl',
        '\tret',
        '\tpushw\thl',
        '\tld16_24\thl, 266558', # ld hl, (0x04113E)
        '\tst16_24\t266556, hl', # st (0x04113C), hl
        '\tpopw\thl',
        '\tret',
    ]),

    # Block 6: Line 38242-38244, Audio_CmdHandler_ConstData (24 bytes)
    # Circular ring buffer write with 4KB (4096-entry) wrapping
    ('Audio_CmdHandler_ConstData', [
        '; --- RingBuffer_Write4K: Write a byte to a 4KB circular buffer ---',
        '; Entry: XWA = pointer to buffer control block',
        ';        C = byte to write',
        '; Buffer layout: [0]=write_ptr(16), [4]=count(16), [6+]=data area',
        '; Write pointer wraps at 4095 (AND 0x0FFF).',
    ], [
        '\tld\txde, xwa',        # DE = buffer base
        '\tld\thl, (xde)',       # HL = current write pointer
        '\tincm\t1, (xde)',      # increment write pointer in memory
        '\tand\thl, 4095',       # wrap to 12-bit (4096 entries)
        '\tld\tde, hl',          # DE = wrapped offset
        '\textz\txde',           # zero-extend to 32 bits
        '\tinc\t6, xde',         # offset past header (6 bytes)
        '\tadd\txde, xwa',       # XDE = buffer base + header + offset
        '\tld\t(xde), c',        # store byte
        '\tincm\t1, (xwa+4)',    # increment count
        '\tret',
    ]),

    # Block 7: Line 39442-39444, LABEL_03587B (24 bytes)
    # Circular ring buffer write with 2KB (2048-entry) wrapping
    ('LABEL_03587B', [
        '; --- RingBuffer_Write2K: Write a byte to a 2KB circular buffer ---',
        '; Entry: XWA = pointer to buffer control block',
        ';        C = byte to write',
        '; Same as RingBuffer_Write4K but wraps at 2047 (AND 0x07FF).',
    ], [
        '\tld\txde, xwa',
        '\tld\thl, (xde)',
        '\tincm\t1, (xde)',
        '\tand\thl, 2047',       # wrap to 11-bit (2048 entries)
        '\tld\tde, hl',
        '\textz\txde',
        '\tinc\t6, xde',
        '\tadd\txde, xwa',
        '\tld\t(xde), c',
        '\tincm\t1, (xwa+4)',
        '\tret',
    ]),

    # Block 8: Line 39527-39532, LABEL_035950 (45 bytes)
    # Packs three 7-bit fields from a structure into XHL
    ('LABEL_035950', [
        '; --- Pack3x7bit: Extract and pack three 7-bit fields ---',
        '; Entry: XWA = pointer to a 4-byte structure',
        ';   byte[1] bits 6:0 -> XHL bits 20:14',
        ';   byte[2] bits 6:0 -> XHL bits 13:7',
        ';   byte[3] bits 6:0 -> XHL bits 6:0',
        '; Exit: XHL = packed 21-bit value',
    ], [
        '\tld\tc, (xwa+2)',      # load byte[2]
        '\tres\t7, c',           # clear bit 7 (keep 7 bits)
        '\tldb\tb, 0',
        '\textz\txbc',
        '\tld\txde, xbc',
        '\tsll\txde, 7',         # shift to bits 13:7
        '\tld\tc, (xwa+1)',      # load byte[1]
        '\tres\t7, c',
        '\tldb\tb, 0',
        '\textz\txbc',
        '\tsll\txbc, 14',        # shift to bits 20:14
        '\tor\txbc, xde',        # combine
        '\tld\ta, (xwa+3)',      # load byte[3]
        '\tres\t7, a',
        '\tldb\tw, 0',
        '\textz\txwa',
        '\tld\txhl, xwa',        # bits 6:0
        '\tor\txhl, xbc',        # combine all three fields
        '\tret',
    ]),

    # Block 9: Line 43079-43084, LABEL_036E12 (43 bytes)
    # Converts 2-byte value from structure into 24-bit address offset
    ('LABEL_036E12', [
        '; --- CalcSampleAddr: Compute sample address from 2-byte index ---',
        '; Entry: XWA = pointer to structure with byte[0] and byte[1]',
        '; Exit: XHL = XWA + computed offset (address into sample data)',
        ';   offset = (byte[0] << 8) + byte[1], capped at 0xF0',
    ], [
        '\tld\tc, (xwa+1)',      # byte[1]
        '\tand\tc, 255',
        '\tld\te, c',
        '\textz\tde',
        '\tld\tc, (xwa)',        # byte[0]
        '\textz\tbc',
        '\tsll\tbc, 8',          # byte[0] << 8
        '\tld\thl, bc',
        '\tldb\tl, 0',           # clear low byte (aligned)
        '\tadd\thl, de',         # combine with byte[1]
        '\tld\tbc, hl',
        '\tsrl\tbc, 8',          # check if high byte >= 0xF0
        '\tcp\tbc, 240',
        '\tjr\tz, 6',            # if == 0xF0, skip add
        '\tld\tbc, hl',
        '\textz\txbc',
        '\tadd\txwa, xbc',       # add offset to base
        '\tld\txhl, xwa',        # result in XHL
        '\tret',
    ]),

    # Block 10: Line 53356-53359, LABEL_03DD51 (27 bytes)
    # Function wrapper: allocates 12 bytes of stack, calls two functions
    ('LABEL_03DD51', [
        '; --- CallWithBuffer12: Allocate 12-byte stack buffer and call ---',
        '; Entry: XWA = source data, XBC = ptr to function table',
        '; Allocates 12 bytes on stack, calls function from table, then',
        '; calls cleanup function. Stack buffer passed in XWA/XBC.',
    ], [
        '\tpush\txiz',
        '\tlda\txsp, (xsp-12)',  # allocate 12 bytes
        '\tld\txiz, xwa',       # save source
        '\tld\txwa, xsp',       # buffer = stack ptr
        '\tld\txbc, (xbc)',     # load function ptr from table
        '\tcall\t253935',       # call function
        '\tld\txwa, xiz',       # restore source
        '\tld\txbc, xsp',       # buffer = stack ptr
        '\tcall\t254022',       # call cleanup
        '\tlda\txsp, (xsp+12)', # deallocate
        '\tpop\txiz',
        '\tret',
    ]),

    # Block 11: Line 53425-53428, LABEL_03DDE5 (27 bytes)
    # Same pattern as above but with 8-byte buffer
    ('LABEL_03DDE5', [
        '; --- CallWithBuffer8: Allocate 8-byte stack buffer and call ---',
        '; Entry: XWA = source data, XBC = ptr to function table',
        '; Same pattern as CallWithBuffer12 but with 8-byte buffer.',
    ], [
        '\tpush\txiz',
        '\tlda\txsp, (xsp-8)',   # allocate 8 bytes
        '\tld\txiz, xwa',
        '\tld\txwa, xsp',
        '\tld\txbc, (xbc)',
        '\tcall\t253491',
        '\tld\txwa, xiz',
        '\tld\txbc, xsp',
        '\tcall\t254128',
        '\tlda\txsp, (xsp+8)',   # deallocate
        '\tpop\txiz',
        '\tret',
    ]),

    # Block 3: Line 31272-31275, LABEL_02E1F4 (31 bytes)
    # Check status bits at offset+16 of a structure looked up by index
    ('LABEL_02E1F4', [
        '; --- CheckStatusBits_Zero: Check if status bits [7:6] are zero ---',
        '; Entry: WA = index',
        '; Exit: HL = 1 if status bits are 0b00, else HL = 0',
    ], [
        '\textz\txwa',
        '\tld\txbc, 287',
        '\tcall\t252106',        # lookup structure by index
        '\tlda_24\txwa, 267118',
        '\tadd\txwa, xhl',
        '\tld\txwa, (xwa)',      # load structure pointer
        '\tld\ta, (xwa+16)',     # get status byte at offset 16
        '\tand\ta, 192',         # mask bits 7:6
        '\tcps\ta, 0',           # compare to 0
        '\tscc16\tz, hl',        # HL = 1 if zero
        '\tret',
    ]),

    # Block 4: Line 31291-31298, LABEL_02E233 (64 bytes)
    # Two similar routines checking for specific bit patterns
    ('LABEL_02E233', [
        '; --- CheckStatusBits_80: Check if status bits [7:6] are 0b10 ---',
        '; Entry: WA = index',
        '; Exit: HL = 1 if status bits are 0x80, else HL = 0',
    ], [
        '\textz\txwa',
        '\tld\txbc, 287',
        '\tcall\t252106',
        '\tlda_24\txwa, 267118',
        '\tadd\txwa, xhl',
        '\tld\txwa, (xwa)',
        '\tld\ta, (xwa+16)',
        '\tand\ta, 192',
        '\tcp\ta, 128',          # check for 0x80
        '\tscc16\tz, hl',
        '\tret',
        # Second routine: check for 0xC0
        '; --- CheckStatusBits_C0: Check if status bits [7:6] are 0b11 ---',
        '\textz\txwa',
        '\tld\txbc, 287',
        '\tcall\t252106',
        '\tlda_24\txwa, 267118',
        '\tadd\txwa, xhl',
        '\tld\txwa, (xwa)',
        '\tld\ta, (xwa+16)',
        '\tand\ta, 192',
        '\tcp\ta, 192',          # check for 0xC0
        '\tscc16\tz, hl',
        '\tret',
    ]),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        data = f.read()

    lines = data.decode('latin-1').split('\n')
    converted = 0

    for label, comments, instructions in CONVERSIONS:
        # Find the label line
        label_idx = None
        for i, line in enumerate(lines):
            if line.strip() == label + ':':
                label_idx = i
                break

        if label_idx is None:
            print(f'  WARNING: label {label} not found, skipping')
            continue

        # Find the .byte block starting right after the label
        byte_start = None
        byte_end = None
        for i in range(label_idx + 1, min(label_idx + 100, len(lines))):
            stripped = lines[i].strip()
            if stripped.startswith('.byte '):
                if byte_start is None:
                    byte_start = i
                byte_end = i
            elif byte_start is not None:
                break  # end of .byte block

        if byte_start is None:
            print(f'  WARNING: no .byte block after {label}, skipping')
            continue

        # Build replacement: comments before label, instructions replace .byte
        # Insert comments before the label line
        comment_lines = comments
        # Replace .byte lines with instructions
        new_instruction_lines = []
        for inst in instructions:
            if inst.startswith(';'):
                new_instruction_lines.append(inst)
            else:
                new_instruction_lines.append(inst)

        # Replace .byte block with instructions
        lines[byte_start:byte_end + 1] = new_instruction_lines

        # Insert comments before the label (adjust index since we just modified lines)
        for j, comment in enumerate(comment_lines):
            lines.insert(label_idx + j, comment)

        converted += 1
        total_bytes = sum(len(re.findall(r'0x[0-9a-fA-F]{2}', line)) for line in lines[byte_start:byte_end + 1])
        print(f'  Converted {label}')

    with open(src, 'wb') as f:
        f.write('\n'.join(lines).encode('latin-1'))

    print(f'\nConverted {converted} blocks in subcpu payload')


if __name__ == '__main__':
    main()
