#!/usr/bin/env python3
"""Convert DSP_ConfigBlock_Opaque .byte block to native instructions with labels.

This block at subcpu address 0x1FCFB contains 5 small functions + data table,
all mislabeled as a single opaque data block. Disassembly via MAME unidasm
and LLVM llvm-objdump reveals:

  Function 1 (0x1FCFB): DSP_WriteAllChannelRegs - calls inner writer for ch 0-3
  Function 2 (0x1FD27): DSP_WriteChannelRegs_Inner - writes 8 regs to one channel
  Function 3 (0x1FD78): DSP_BlockCopyWords - block copy via ldirw
  Function 4 (0x1FD81): DSP_FillMemWords - fill memory with word value
  Function 5 (0x1FD88): DSP_ChecksumRange - checksum 32-bit words in range
  Data (0x1FD98): DSP_ChannelConfigTable - 6 config entries + padding
"""

import re


def main():
    filepath = '/mnt/shared/kn5000-roms-disasm/subcpu/kn5000_subprogram_v142.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # The old block: DSP_ConfigBlock_Opaque label + all .byte lines until the blank line
    # Lines 9524-9550 in the source
    old_block = (
        'DSP_ConfigBlock_Opaque:\n'
        '\t.byte 0x39, 0x3a, 0x0b, 0x01, 0x00, 0x1e, 0x24, 0x00\n'
        '\t.byte 0xaf, 0x0a, 0x21, 0xee, 0x8a, 0x0b, 0x00, 0x00\n'
        '\t.byte 0x1e, 0x19, 0x00, 0xe8, 0x89, 0xeb, 0x8a, 0x0b\n'
        '\t.byte 0x02, 0x00, 0x1e, 0x0f, 0x00, 0xec, 0x89, 0xed\n'
        '\t.byte 0x8a, 0x0b, 0x03, 0x00, 0x1e, 0x05, 0x00, 0xef\n'
        '\t.byte 0x60, 0x5a, 0x59, 0x0e, 0x3d, 0x28, 0x29, 0x8f\n'
        '\t.byte 0x0c, 0x21, 0xc9, 0xee, 0x05, 0xc9, 0x31, 0x04\n'
        '\t.byte 0x45, 0x00, 0x00, 0x13, 0x00, 0xb5, 0x41, 0xbd\n'
        '\t.byte 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02\n'
        '\t.byte 0x42, 0xc9, 0x61, 0xb5, 0x41, 0xd7, 0xe6, 0x89\n'
        '\t.byte 0xbd, 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd\n'
        '\t.byte 0x02, 0x42, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02\n'
        '\t.byte 0x45, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02, 0x44\n'
        '\t.byte 0xc9, 0x61, 0xb5, 0x41, 0xd7, 0xea, 0x89, 0xbd\n'
        '\t.byte 0x02, 0x43, 0xc9, 0x61, 0xb5, 0x41, 0xbd, 0x02\n'
        '\t.byte 0x42, 0x49, 0x48, 0x5d\n'
        '\t.byte 0x0e, 0xe8, 0x8c, 0xe9\n'
        '\t.byte 0x8d, 0xda, 0x89, 0x95, 0x11, 0x0e, 0xf5, 0xe1\n'
        '\t.byte 0x51, 0xda, 0x1c, 0xfa, 0x0e, 0xeb, 0xd3, 0xe9\n'
        '\t.byte 0x12, 0xe8, 0x81, 0xe5, 0xe2, 0x83, 0xe9, 0xf0\n'
        '\t.byte 0x61, 0xf9, 0xdb, 0x06, 0x0e, 0xb1, 0xfa, 0x01\n'
        '\t.byte 0x00, 0x9a, 0x06, 0x04, 0x00, 0x00, 0x88, 0x03\n'
        '\t.byte 0x00, 0x6f, 0xfc, 0x01, 0x00, 0x20, 0x0c, 0x04\n'
        '\t.byte 0x00, 0x00, 0x88, 0x01, 0x00, 0x27, 0x63, 0x03\n'
        '\t.byte 0x00, 0x9c, 0x0a, 0x04, 0x00, 0x00, 0x88, 0x03\n'
        '\t.byte 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01'
    )

    if old_block not in text:
        print("ERROR: Could not find DSP_ConfigBlock_Opaque block in source!")
        return

    new_block = """\
; ----------------------------------------------------------------------------
; DSP_WriteAllChannelRegs - Write register data to all 4 DSP channels
; Entry: XBC/XDE = channel data, prevbank QBC/QDE = additional data
; Notes: Calls DSP_WriteChannelRegs_Inner for channels 0-3
;        Each call writes 8 sequential DSP registers via 0x130000
; ----------------------------------------------------------------------------
DSP_WriteAllChannelRegs:
\tpush xbc
\tpush xde
\tpushw 1\t\t\t\t; Channel 1
\tcalr DSP_WriteChannelRegs_Inner
\tld xbc, (xsp + 10)\t\t; Reload saved XBC
\tld xde, xiz
\tpushw 0\t\t\t\t; Channel 0
\tcalr DSP_WriteChannelRegs_Inner
\tld xbc, xwa
\tld xde, xhl
\tpushw 2\t\t\t\t; Channel 2
\tcalr DSP_WriteChannelRegs_Inner
\tld xbc, xix
\tld xde, xiy
\tpushw 3\t\t\t\t; Channel 3
\tcalr DSP_WriteChannelRegs_Inner
\tinc 8, xsp\t\t\t; Clean 4x pushw from stack
\tpop xde
\tpop xbc
\tret

; ----------------------------------------------------------------------------
; DSP_WriteChannelRegs_Inner - Write 8 register values to one DSP channel
; Entry: Stack+12 = channel number (0-3)
;        BC = data bytes 0-1, DE = data bytes 4-5
;        Prevbank QBC = data bytes 2-3, prevbank QDE = data bytes 6-7
; Notes: Register address = channel * 32 + 0x10
;        Writes via memory-mapped DSP I/O: addr to (xiy), data to (xiy+2)
; ----------------------------------------------------------------------------
DSP_WriteChannelRegs_Inner:
\tpush xiy
\tpushw wa
\tpushw bc
\tld a, (xsp + 12)\t\t; Channel number
\tsll a, 5\t\t\t; * 32
\tset 4, a\t\t\t; + 0x10
\tld xiy, 0x130000\t\t; DSP register base
\tld (xiy), a\t\t\t; Reg addr [0]
\tld (xiy + 2), c\t\t\t; Write data C
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [1]
\tld (xiy + 2), b\t\t\t; Write data B
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [2]
\t.byte 0xd7, 0xe6, 0x89\t\t; ld bc, qbc  (load BC from prevbank)
\tld (xiy + 2), c\t\t\t; Write prevbank C
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [3]
\tld (xiy + 2), b\t\t\t; Write prevbank B
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [4]
\tld (xiy + 2), e\t\t\t; Write data E
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [5]
\tld (xiy + 2), d\t\t\t; Write data D
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [6]
\t.byte 0xd7, 0xea, 0x89\t\t; ld bc, qde  (load BC from prevbank DE)
\tld (xiy + 2), c\t\t\t; Write prevbank DE.low
\tinc 1, a
\tld (xiy), a\t\t\t; Reg addr [7]
\tld (xiy + 2), b\t\t\t; Write prevbank DE.high
\tpopw bc
\tpopw wa
\tpop xiy
\tret

; ----------------------------------------------------------------------------
; DSP_BlockCopyWords - Block copy words from (XHL) to destination
; Entry: XWA = dest base (saved to XIX), XBC = src base (saved to XIY)
;        DE = source reg, BC (after ld) = word count for ldirw
; Notes: ldirw copies BC words from (XHL+) to (XIX+)
; ----------------------------------------------------------------------------
DSP_BlockCopyWords:
\tld xix, xwa
\tld xiy, xbc
\tld bc, de
\tldirw\t\t\t\t; Block transfer: (XHL+) -> (XIX+), BC words
\tret

; ----------------------------------------------------------------------------
; DSP_FillMemWords - Fill memory with word value
; Entry: XWA = dest pointer, BC = fill value, DE = count
; Notes: ld (xwa+),bc stores BC then increments XWA
; ----------------------------------------------------------------------------
DSP_FillMemWords:
\t.byte 0xf5, 0xe1, 0x51\t\t; ld (xwa+), bc  (store + auto-increment)
\tdjnz16 de, DSP_FillMemWords
\tret

; ----------------------------------------------------------------------------
; DSP_ChecksumRange - Compute checksum of 32-bit words in memory range
; Entry: XWA = start address, XBC = byte count
; Exit:  HL = one's complement checksum
; Notes: Sums all 32-bit values, then complements result
; ----------------------------------------------------------------------------
DSP_ChecksumRange:
\txor xhl, xhl\t\t\t; Accumulator = 0
\textz xbc\t\t\t; Zero-extend count
\tadd xbc, xwa\t\t\t; XBC = end address
DSP_ChecksumRange_Loop:
\t.byte 0xe5, 0xe2, 0x83\t\t; add xhl, (xwa+)  (add + auto-increment)
\tcp xwa, xbc\t\t\t; Reached end?
\tjr lt, DSP_ChecksumRange_Loop
\tcpl hl\t\t\t\t; One's complement
\tret

; DSP channel configuration data table (42 bytes)
DSP_ChannelConfigTable:
\t.byte 0xb1, 0xfa, 0x01, 0x00
\t.byte 0x9a, 0x06, 0x04, 0x00, 0x00, 0x88, 0x03, 0x00
\t.byte 0x6f, 0xfc, 0x01, 0x00
\t.byte 0x20, 0x0c, 0x04, 0x00, 0x00, 0x88, 0x01, 0x00
\t.byte 0x27, 0x63, 0x03, 0x00
\t.byte 0x9c, 0x0a, 0x04, 0x00, 0x00, 0x88, 0x03, 0x00
\t.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01"""

    # Also need to update the comment block before the label
    old_comment = (
        '\n\nDSP_ConfigBlock_Opaque:'
    )
    new_comment = (
        '\n\n; ----------------------------------------------------------------------------\n'
        '; DSP_WriteAllChannelRegs - Write register data to all 4 DSP channels\n'
    )

    # Actually, just replace the old_block content directly
    text = text.replace(old_block, new_block)

    # Also update references: rename DSP_ConfigBlock_Opaque -> DSP_WriteAllChannelRegs
    # Check if DSP_ConfigBlock_Opaque is referenced elsewhere
    refs = len(re.findall(r'\bDSP_ConfigBlock_Opaque\b', text))
    if refs > 0:
        print(f"WARNING: DSP_ConfigBlock_Opaque still referenced {refs} times")

    # Update symbol reference file too
    sympath = '/mnt/shared/kn5000-roms-disasm/symbols/subcpu_symbols_reference.txt'
    with open(sympath, 'rb') as f:
        symtext = f.read().decode('latin-1')

    renames = {
        'DSP_ConfigBlock_Opaque': 'DSP_WriteAllChannelRegs',
    }
    for old, new in renames.items():
        pattern = r'\b' + re.escape(old) + r'\b'
        symtext = re.sub(pattern, new, symtext)

    # Add new labels to symbol file (they don't exist yet)
    new_labels = [
        'DSP_WriteChannelRegs_Inner',
        'DSP_BlockCopyWords',
        'DSP_FillMemWords',
        'DSP_ChecksumRange',
        'DSP_ChecksumRange_Loop',
        'DSP_ChannelConfigTable',
    ]

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))

    with open(sympath, 'wb') as f:
        f.write(symtext.encode('latin-1'))

    print(f"{filepath}: DSP_ConfigBlock_Opaque converted to 5 labeled functions + data table")
    print(f"{sympath}: Renamed DSP_ConfigBlock_Opaque -> DSP_WriteAllChannelRegs")
    print(f"New labels: {', '.join(new_labels)}")


if __name__ == '__main__':
    main()
