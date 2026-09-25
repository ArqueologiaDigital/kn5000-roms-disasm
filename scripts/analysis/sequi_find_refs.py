#!/usr/bin/env python3
r"""sequi_find_refs.py -- who could reach this address?  (KN5000 maincpu)

QUESTION THIS ANSWERS
    Before a routine or table is written up as "no caller / no reader
    found", which reference FORMS were searched, and what did they find?

FORMS SEARCHED (all over the ORIGINAL dumps, not the sources):
    abs      the 24-bit little-endian value of the address, at ANY byte offset
             of the maincpu image (covers call/jp imm24, ld r,imm32, lda,
             `.long` / addr24 pointers), and with --window N also addr+-N
             (a base-minus-index constant: `ld xix, TABLE - 4*k`)
    abs-*    the same value in the HD-AE5000, table-data, custom-data and
             sub-CPU images (extension ROMs call maincpu routines directly)
    rel16    calr (1E d16) / jrl cc (70-7F d16) whose target is the address
    rel8     jr cc (60-6F d8) whose target is the address
    A hit is a CANDIDATE: the byte found may be an operand of something else,
    so each hit must be checked against the source line at its address.

NOT SEARCHED
    computed jumps through word-offset tables (`jp T, XIX+r` after
    `lda xix, BASE`), where only BASE appears; djnz; references from RAM.

RUN
    python3 scripts/analysis/sequi_find_refs.py v10 0xF537A9 0xF538EC
    python3 scripts/analysis/sequi_find_refs.py v10 --window 64 0xF537D4
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
R = os.path.join(ROOT, "original_ROMs")
OTHERS = {"hdae": "hd-ae5000_v2_06i.ic4", "table": "kn5000_table_data.rom",
          "custom": "kn5000_custom_data.ic19", "sub": "kn5000_subprogram_v142.rom"}
B = 0xE00000


def refs(image, A, window=0):
    rom = open(os.path.join(R, "kn5000_%s_program.rom" % image), "rb").read()
    out = []
    for d in range(-window, window + 1):
        pat = (A + d).to_bytes(3, "little")
        i = rom.find(pat)
        while i >= 0:
            out.append(("abs%+d" % d if d else "abs", "0x%06X" % (B + i)))
            i = rom.find(pat, i + 1)
        for k, f in OTHERS.items():
            b = open(os.path.join(R, f), "rb").read()
            i = b.find(pat)
            while i >= 0:
                out.append(("abs-%s%s" % (k, "%+d" % d if d else ""), "+0x%X" % i))
                i = b.find(pat, i + 1)
    for i in range(len(rom) - 3):
        op = rom[i]
        if op == 0x1E or 0x70 <= op <= 0x7F:
            d = int.from_bytes(rom[i + 1:i + 3], "little", signed=True)
            if B + i + 3 + d == A:
                out.append(("rel16 %02x" % op, "0x%06X" % (B + i)))
        elif 0x60 <= op <= 0x6F:
            d = int.from_bytes(rom[i + 1:i + 2], "little", signed=True)
            if B + i + 2 + d == A:
                out.append(("rel8 %02x" % op, "0x%06X" % (B + i)))
    return out


def main():
    args = sys.argv[1:]
    image = args.pop(0)
    window = 0
    if args and args[0] == "--window":
        window = int(args[1])
        args = args[2:]
    for a in args:
        A = int(a, 16)
        print("0x%06X" % A, refs(image, A, window) or "none")


if __name__ == "__main__":
    main()
