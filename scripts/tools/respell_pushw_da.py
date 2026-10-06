#!/usr/bin/env python3
"""respell_pushw_da.py -- `pushw_da b0, b1, b2` (raw address bytes) -> the native `pushw (ADDR:24)` (v10/v9/v7).

QUESTION IT ANSWERS
  `pushw_da` is an assembler pseudo-instruction that takes the 24-bit address of a pushed 16-bit memory word as
  three raw bytes: `pushw_da 0x30, 0x79, 0xeb` -> d2 30 79 eb 04.  The native spelling `pushw (X:24)` encodes the
  same way (llvm-mc: `pushw (Softver_MainProgramVersion:24)` -> d2 A A A 04), and can name the address.
  This script rewrites every use.
    - A ROM address that the tree's symbol file (symbols/maincpu*_symbols_reference.txt) gives a label becomes
      `pushw (Label:24)`.  0xEB7930 is Softver_MainProgramVersion in v10 / v9: the version number the
      software-version screen prints, a finding of the round-3 triage of the nakarest slices.
    - Any other address becomes `pushw (0xADDR:24)`.  These are work-RAM cells such as 0x3EFA2 and 0x2748C, which
      have no symbols yet; the spelling is the same as the tree's other `(0x3e99e:24)` operands.
  The byte gate checks the encodings.

RUN (repository root)
  python3 scripts/tools/respell_pushw_da.py [--apply]
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SYMS = {"v10": "symbols/maincpu_symbols_reference.txt", "v9": "symbols/maincpu_v9_symbols_reference.txt",
        "v7": "symbols/maincpu_v7_symbols_reference.txt"}
PDA = re.compile(r'^(\s*)pushw_da\s+(0x[0-9a-fA-F]+|\d+),\s*(0x[0-9a-fA-F]+|\d+),\s*(0x[0-9a-fA-F]+|\d+)\s*(;.*)?$')


def main():
    apply = "--apply" in sys.argv
    for tree, sf in SYMS.items():
        byaddr = {}
        for ln in open(os.path.join(ROOT, sf), encoding="latin-1"):
            f = ln.split()
            if len(f) == 2 and not ln.startswith("#"):
                a = int(f[1], 16)
                if not f[0].startswith(".") and (a not in byaddr or len(f[0]) < len(byaddr[a])):
                    byaddr[a] = f[0]
        n = named = 0
        for p in sorted(glob.glob(os.path.join(ROOT, tree, "maincpu", "**", "*.s"), recursive=True)):
            L = open(p, "rb").read().decode("latin-1").split("\n")
            changed = False
            for i, x in enumerate(L):
                m = PDA.match(x)
                if not m:
                    continue
                a = int(m.group(2), 0) | int(m.group(3), 0) << 8 | int(m.group(4), 0) << 16
                sym = byaddr.get(a) if a >= 0xE00000 else None
                op = "(%s:24)" % sym if sym else "(0x%x:24)" % a
                L[i] = "%spushw\t%s%s" % (m.group(1), op, ("\t" + m.group(5)) if m.group(5) else "")
                n += 1
                named += bool(sym)
                changed = True
            if changed and apply:
                data = "\n".join(L).encode("latin-1")
                open(p + ".tmp", "wb").write(data)
                os.replace(p + ".tmp", p)
        print("%s: %d pushw_da respelled, %d of them by name" % (tree, n, named))


if __name__ == "__main__":
    main()
