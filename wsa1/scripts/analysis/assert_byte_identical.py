#!/usr/bin/env python3
"""Are the rebuilt WSA1 ROMs BYTE-IDENTICAL to the originals? Zero tolerance.

THE GATE. Nothing in this tree is certified by anything else.

This script REBUILDS FIRST and then compares bytes. Both halves are deliberate,
and both were learned the hard way in ../kn5000-roms-disasm:

  * It rebuilds, because a gate whose precondition is supplied by the caller is
    a gate that will eventually be run without it. Over there, this script only
    compared what happened to be on disk, and was run alone across 106 commits
    while the rebuilt ROMs were three hours stale and the tree did not compile.
    Every PASS in that window was vacuous.

  * It compares bytes, never a percentage. A "Similarity: 100.00%" line rounds:
    in a 512 KB image that is up to 26 differing bytes, and a grep for the
    prefix also matches "100.00%  (22 incorrect bytes)".

Exit 0 = every pair identical. Exit non-zero = at least one differs, or the
build failed.

Run:  python3 scripts/analysis/assert_byte_identical.py
      python3 scripts/analysis/assert_byte_identical.py --no-build   (warns)
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

PAIRS = [
    ("wsa1_prom_a.ic12", "wsa1_prom_a.llvm.rom"),
    ("wsa1_prom_b.ic13", "wsa1_prom_b.llvm.rom"),
    ("wsa1_prom_c.ic28", "wsa1_prom_c.llvm.rom"),
    ("wsa1_prom_d.bin",  "wsa1_prom_d.llvm.rom"),
]


def main():
    if "--no-build" in sys.argv:
        print("  !! --no-build: comparing whatever is on disk, NOT rebuilding")
    else:
        print("  building (make all) ...")
        r = subprocess.run(["make", "all"], cwd=ROOT, capture_output=True, text=True)
        if r.returncode != 0:
            print("  BUILD FAILED -- the gate cannot pass on a tree that does not assemble.")
            sys.stdout.write(r.stdout[-4000:])
            sys.stderr.write(r.stderr[-4000:])
            return 2

    bad = 0
    for orig, built in PAIRS:
        po = os.path.join(ROOT, "original_ROMs", orig)
        pb = os.path.join(ROOT, "rebuilt_ROMs", built)
        if not os.path.exists(pb):
            print(f"  MISSING  {built}")
            bad += 1
            continue
        a = open(po, "rb").read()
        b = open(pb, "rb").read()
        if a == b:
            print(f"  ok       {orig}  ({len(a):,} bytes)")
        else:
            n = sum(1 for x, y in zip(a, b) if x != y) + abs(len(a) - len(b))
            first = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), None)
            print(f"  DIFFERS  {orig}: {n:,} byte(s), first at 0x{first:X}"
                  if first is not None else f"  DIFFERS  {orig}: length {len(a)} vs {len(b)}")
            bad += 1

    if bad:
        print(f"\nFAIL: {bad} ROM(s) differ.")
        return 1
    print("\nPASS: every rebuilt ROM is byte-identical.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
