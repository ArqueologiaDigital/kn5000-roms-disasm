#!/usr/bin/env python3
"""ONE DSP driver, TWO processors, ONE differing byte per routine.

QUESTION IT ANSWERS
-------------------
This tree already knows that prom_a and prom_c share a KERNEL -- `kernel/kernel.s`
assembles to 2,180 identical bytes of both images (`notes/FINDINGS-kernel-*`).
The question here is whether the SOUND side has the same shape, and it does:

    prom_a 0xF85F0F..0xF85FF8   |   prom_c 0xF98000..0xF980E9
    234 bytes, four routines    |   234 bytes, four routines
    231 of 234 bytes IDENTICAL
    the 3 that differ are ONE BYTE OF EACH ROUTINE'S BASE LITERAL:
        prom_a +0x034 0xF85F43 = 0x7F      prom_c 0xF98034 = 0xE0
        prom_a +0x05A 0xF85F69 = 0x7F      prom_c 0xF9805A = 0xE0
        prom_a +0x0A8 0xF85FB7 = 0x7F      prom_c 0xF980A8 = 0xE0

    0x007F0000 on CPU 1, 0x00E00000 on CPU 2 -- A23..A16 of the DSP register
    file, and nothing else in 234 bytes.

★ WHY THAT IS A FINDING AND NOT A COINCIDENCE.  Three routines each loading a
32-bit immediate, all three differing in the SAME byte position of that immediate
and in no other byte of 234, is one source assembled twice with one symbol
changed.  It is the same evidence shape the kernel finding rests on, at 234 bytes
instead of 2,180.  ⚠ And it is the same evidence shape that carries the same
warning: BYTE IDENTITY IS NOT SEMANTIC IDENTITY.  What is established is that the
two processors run the same driver against two bases; what each of the eight
per-channel registers HOLDS is not established for either.

THE THIRD COPY.  `DSP_WriteAllChannelRegs`, 44 of these bytes, is byte-identical
in the KN5000 sub-CPU at 0x1FCFB as well -- three processors across two products,
already recorded in `prom_c/boot/boot_and_main.s`.  The 234-byte block as a whole
is NOT: the KN5000's `DSP_Init_Channels` fills its buffer with 0x5A5A5A5A where
both WSA1 copies fill it with zero, so only 12 of 74 bytes line up there.

    python3 notes/sound/wsa1_dsp_driver_shared.py
    python3 notes/sound/wsa1_dsp_driver_shared.py --selftest
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LOAD = 0xF80000
PA, PC, LEN = 0xF85F0F, 0xF98000, 234
# the four routines, prom_a offset -> (prom_a label, prom_c label)
ROUTINES = [
    (0x000, "DSP_ChannelRegs_Init",  "DSP_ChannelRegs_Init"),
    (0x04A, "DSP_ChannelRegs_Write8", "DSP_ChannelRegs_Write8"),
    (0x06D, "DSP_WriteAllChannelRegs", "DSP_WriteAllChannelRegs"),
    (0x099, "DSP_WriteChannelRegs_Inner", "DSP_WriteChannelRegs_Inner"),
]


def img(name):
    return open(os.path.join(ROOT, "original_ROMs", name), "rb").read()


def diff(shift=0):
    a, c = img("wsa1_prom_a.ic12"), img("wsa1_prom_c.ic28")
    out = []
    for i in range(LEN):
        x = a[PA - LOAD + i]
        y = c[PC - LOAD + i + shift]
        if x != y:
            out.append((i, x, y))
    return out


def report():
    d = diff()
    print("THE DSP REGISTER-FILE DRIVER, prom_a AGAINST prom_c")
    print("=" * 78)
    print("prom_a 0x%06X..0x%06X   prom_c 0x%06X..0x%06X   %d bytes"
          % (PA, PA + LEN - 1, PC, PC + LEN - 1, LEN))
    print("%d of %d bytes identical; %d differ\n" % (LEN - len(d), LEN, len(d)))
    for i, x, y in d:
        print("   +0x%03X   prom_a 0x%06X = 0x%02X     prom_c 0x%06X = 0x%02X"
              % (i, PA + i, x, PC + i, y))
    print("\n   every one of them is A23..A16 of a `ld <Xrr>,imm32`:")
    print("   0x007F0000 on CPU 1, 0x00E00000 on CPU 2.\n")
    print("the four routines this block holds:")
    for off, la, lc in ROUTINES:
        print("   +0x%03X   prom_a 0x%06X   prom_c 0x%06X   %s"
              % (off, PA + off, PC + off, la))
    # ★ THE NULL.  A misalignment must NOT match.  Without this, "231 of 234"
    #   could be an artefact of two regions of mostly-zero padding.
    print("\nNULL CONTROL -- the same comparison at eight nearby alignments:")
    for s in (-4, -3, -2, -1, 1, 2, 3, 4):
        print("   shift %+d bytes: %3d of %d identical" % (s, LEN - len(diff(s)), LEN))
    print("""
  ★ Only the true alignment matches.  A neighbouring one scores like two
    unrelated byte strings, which is what makes 231/234 a fact about the code
    and not about the padding around it.""")


def selftest():
    checks, fails = [], 0

    def ck(n, c, d=""):
        nonlocal fails
        checks.append((n, c, d))
        if not c:
            fails += 1

    d = diff()
    ck("231 of 234 bytes identical", LEN - len(d) == 231, "%d" % (LEN - len(d)))
    ck("exactly 3 bytes differ", len(d) == 3, "%d" % len(d))
    ck("every differing byte is 0x7F in prom_a and 0xE0 in prom_c",
       all(x == 0x7F and y == 0xE0 for _, x, y in d),
       ", ".join("+0x%03X %02X/%02X" % t for t in d))
    ck("they sit 0x26 and 0x4E apart -- one per base literal, three literals",
       [i for i, _, _ in d] == [0x034, 0x05A, 0x0A8],
       str(["0x%03X" % i for i, _, _ in d]))
    # ★ THE NULL, asserted rather than merely printed.
    worst = max(LEN - len(diff(s)) for s in (-4, -3, -2, -1, 1, 2, 3, 4))
    ck("★ NULL: no neighbouring alignment scores anywhere near 231",
       worst < 60, "best misaligned score %d of %d" % (worst, LEN))
    # And the source really does carry these labels, at these addresses.
    src = open(os.path.join(ROOT, "prom_a/wsa1_prom_a.s"),
               encoding="utf-8", errors="replace").read()
    for off, la, _ in ROUTINES:
        ck("prom_a source defines %s" % la, ("\n%s:" % la) in src, "")
    for name, ok, detail in checks:
        print("  %-4s %-58s %s" % ("ok" if ok else "FAIL", name, detail))
    print("\n%d checks, %d failures" % (len(checks), fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv[1:] else (report() or 0))
