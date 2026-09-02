#!/usr/bin/env python3
"""Would moving gen_prom_b_f0ea9f_module.py's block end from 0xF13D34 down to
0xF13D30 change anything except the four bytes it gives up?

WHY THE QUESTION EXISTS
    Lane res02f converted the `.incbin` at 0xF13D34 (44 B) and found that it
    starts FOUR BYTES INSIDE a 24-byte bitmap: six interpreter-A `03 0C`
    records name four bitmaps at 0xF13D00, 0xF13D18, 0xF13D30 and 0xF13D48,
    every one carrying BC=2, HL=12, and the four tile 0xF13D00-0xF13D5F.  The
    bitmap at 0xF13D30 therefore begins four bytes before the `.incbin` does,
    inside the `.byte` run of `Data_F139AB` -- which
    notes/gen_prom_b_f0ea9f_module.py emits from its LAYOUT entry
    ("data", 0xF139AB, 0x0389), and whose `--checks` asserts that LAYOUT covers
    LY.LO..LY.HI-1 = 0xF0EA9F-0xF13D33 exactly.

    So closing the bitmap is a one-line change in another module's layout.  The
    fear was that shrinking that module's HI re-runs its whole code walk and
    silently moves boundaries elsewhere -- the failure this push has hit
    repeatedly, and one the byte gate cannot see, because any framing of the
    right bytes reproduces the ROM.

ANSWER: IT CHANGES NOTHING ELSE.  Measured 2026-09-02.  (The shared toolchain
stood at llvm-project tlcs900_backend 6f456a19f05b; this emission is pure Python
over the ROM and does not call it, but the tree's rule is to name the build any
number was taken with.)  The two emissions differ in SIX lines, and all six are
the four bytes themselves:

    ;   contiguous span of 21141 bytes        -> 21137
    ; LAYOUT.  81 segments, 21141 bytes,      -> 21137          (81 SEGMENTS BOTH)
    ;   unsplit `.byte` runs 23 segments 4821 -> 4817           (23 SEGMENTS BOTH)
    ; Data_F139AB -- 905 bytes                -> 901 bytes
    ; ...printable preview, four characters shorter
    .byte 0x08,0x10,0x10,0x60,0x80,0x00,0x00,0x03,0x0E ; [896..904]
                                              -> .byte 0x08,0x10,0x10,0x60,0x80 ; [896..900]

Not one label, not one instruction, not one segment boundary moves.  The code
walk is insensitive to the shift, which is what makes the one-line change safe.

WHAT THIS PROBE DOES *NOT* ESTABLISH
    It calls `emit()` directly, so it does NOT run the module's `--checks`.
    Whoever makes the change must run `python3 notes/gen_prom_b_f0ea9f_module.py
    --checks` as well: the LAYOUT-contiguity check compares against LY.HI - LY.LO
    and the layout re-derivation compares against LY's own segments, and both
    have to be brought along.
    ⚠ And `prom_b_f0ea9f_layout` is imported by four other modules
    (gen_prom_b_f6d002_module.py, prom_b_f067a6_layout.py, prom_b_f4f000_layout.py,
    prom_b_f4f000_verify.py).  They import it for its rules, not obviously for
    LO/HI, but that was not measured here.  Those four are why lane res02f left
    the change named rather than made -- not the code walk, which this probe
    clears.

RUN  (~3 minutes per emission; run from the wsa1/ directory)
    python3 notes/res02f_f0ea9f_hi_shift_probe.py --baseline > /tmp/a.s
    python3 notes/res02f_f0ea9f_hi_shift_probe.py --shifted  > /tmp/b.s
    diff /tmp/a.s /tmp/b.s        # must be exactly the six lines above
    python3 notes/res02f_f0ea9f_hi_shift_probe.py --diff     # does all of that

⚠ `--diff` compares the two emissions BY LINE POSITION, not with `diff`.  They
have the same line count, so position i corresponds to position i and the count
is exact.  A `diff` line count is not: the first run of this probe reported 16
changed lines because `difflib` swept two IDENTICAL trailing blank lines into
the last replacement block.  Six is the number; sixteen was the instrument.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHIFTED_HI = 0xF13D30
SHIFTED_LAST = ("data", 0xF139AB, 0x0385)


def emit(shift):
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import prom_b_f0ea9f_layout as LY
    if shift:
        # ⚠ before importing the module: it copies LY.LO/LY.HI at import time.
        LY.HI = SHIFTED_HI
    import gen_prom_b_f0ea9f_module as M
    if shift:
        M.LO, M.HI = LY.LO, LY.HI
        M.LAYOUT[-1] = SHIFTED_LAST
    M.install()
    return "\n".join(M.emit())


def main():
    if "--baseline" in sys.argv:
        print(emit(False))
        return 0
    if "--shifted" in sys.argv:
        print(emit(True))
        return 0
    if "--diff" in sys.argv:
        # Two separate processes: the module copies LO/HI at import time, so one
        # process cannot produce both emissions honestly.
        here = os.path.abspath(__file__)
        outs = []
        for flag in ("--baseline", "--shifted"):
            r = subprocess.run([sys.executable, here, flag], cwd=ROOT,
                               capture_output=True, text=True)
            if r.returncode:
                sys.stderr.write(r.stderr)
                return 1
            outs.append(r.stdout.split("\n"))
        # ⚠ POSITIONAL, not difflib.  The two emissions have the same number of
        # lines, so line i corresponds to line i and the answer is exact.  A
        # `diff` count is NOT: on the first run it reported 16 changed lines
        # because it swept two IDENTICAL trailing blank lines into the last
        # replacement block.  Aligning by position removes that artefact.
        a, b = outs
        if len(a) != len(b):
            print("line counts differ: %d vs %d -- the shift moved a boundary"
                  % (len(a), len(b)))
            return 1
        moved = [i for i in range(len(a)) if a[i] != b[i]]
        for i in moved:
            print("line %d\n  baseline %s\n  shifted  %s" % (i + 1, a[i], b[i]))
        print("\n%d lines differ of %d; expected 6, all of them the four bytes"
              % (len(moved), len(a)))
        return 0 if len(moved) == 6 else 1
    print(__doc__.strip().split("RUN")[-1])
    return 1


if __name__ == "__main__":
    sys.exit(main())
