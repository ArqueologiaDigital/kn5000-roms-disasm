#!/usr/bin/env python3
"""payload_hexdump.py -- hex dump the v142 sub-CPU payload at a SUB-CPU ADDRESS.

QUESTION ANSWERED: what bytes live at a given sub-CPU address? The payload image on disk is not a
flat image of that address space, so a plain `xxd -s` at the address gives the wrong bytes. This
applies the mapping.

    python3 tools/payload_hexdump.py 0x023A4A            # 32 bytes at Pitch_Emit_Reg400
    python3 tools/payload_hexdump.py 0x00FBE4 256        # the +0x080 note-field table

THE MAPPING, which is the point of this script:

    sub-CPU 0x000400 .. 0x0004FF  ->  file 0x000000 ..   the 5-byte jp/ret trampoline block
    sub-CPU 0x00F000 .. 0x03EF00  ->  file 0x000100 ..   everything else

The payload's first 0x40 bytes are trampolines into the RAM it fills, which is part of what proved
v142 is the right firmware for this machine (the IC30 vector table points at 0x400 with a 5-byte
stride -- see WAVE-STATUS.md, wave 6).

Addresses outside those two ranges raise rather than returning plausible-looking wrong bytes.
"""
import sys

ROM = '/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom'


def file_offset(addr):
    if 0x400 <= addr <= 0x4FF:
        return addr - 0x400
    if 0x0F000 <= addr < 0x3EF00:
        return 256 + (addr - 0x0F000)
    raise ValueError(f"{addr:#x} is not in the payload's address space")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    addr = int(sys.argv[1], 16)
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 32
    data = open(ROM, 'rb').read()
    off = file_offset(addr)
    chunk = data[off:off + count]
    for i in range(0, len(chunk), 16):
        row = chunk[i:i + 16]
        text = ''.join(chr(b) if 32 <= b < 127 else '.' for b in row)
        print(f"{addr + i:06X}: {' '.join(f'{b:02x}' for b in row):<47}  {text}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
