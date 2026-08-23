#!/usr/bin/env python3
"""Are the rebuilt ROMs BYTE-IDENTICAL to the originals? Zero tolerance.

QUESTION ANSWERED
-----------------
`compare_roms.py` prints `Similarity: 100.00%`, rounded to two decimals. In a
2,097,152-byte ROM that is **up to 104 differing bytes**. It does append
`(N incorrect bytes)` when N > 0 -- but a check written as

    grep -c "Similarity: 100.00%"

MATCHES THAT LINE TOO, because it is a prefix. Every "gate 9/9" in this
session's notes was that prefix match, and 14 of the run logs contain
`Similarity: 100.00%  (N incorrect bytes)`.

What it cost: 981 label "repairs" were committed on the strength of a 9/9 that
was really 22 wrong bytes in v7. The corruption was being detected and printed
the entire time; the check was reading past it.

This script does the only thing that settles it -- compares the bytes -- and
exits non-zero if any pair differs. Use it as the gate, not a grep.

Run:  python3 scripts/analysis/assert_byte_identical.py       (rebuilds first)
      python3 scripts/analysis/assert_byte_identical.py --no-build

⚠⚠ THIS SCRIPT NOW REBUILDS BEFORE COMPARING, AND THAT IS THE POINT.
Until 2026-08-23 it only compared `rebuilt_ROMs/` against `original_ROMs/` and
left the rebuild to the caller ("make all && python3 ..."). Run alone it reports
PASS on whatever happens to be on disk. It was run alone -- by hand and by
tools/closure-loop.sh, which had no `make` step -- across 106 commits while the
rebuilt ROMs were three hours old and the tree DID NOT COMPILE. Every PASS in
that window was vacuous, and two build-breaking defects and a 136,782-byte v7
divergence went unnoticed.

A gate whose precondition is supplied by the caller is a gate that will be run
without it. `--no-build` exists for the case where the caller genuinely has just
built, and it prints a warning so the choice is visible.
"""
import glob, os, sys

PAIRS = [
    ("kn5000_v7_program", "kn5000_v7_program.llvm.rom"),
    ("kn5000_v9_program", "kn5000_v9_program.llvm.rom"),
    ("kn5000_v10_program", "kn5000_v10_program.llvm.rom"),
    ("kn5000_subprogram_v142", "kn5000_subprogram_v142.llvm.rom"),
    ("kn5000_subprogram_v142_compressed", "kn5000_subprogram_v142_compressed.rom"),
    ("kn5000_table_data", "kn5000_table_data.llvm.rom"),
]


def main():

    # REBUILD FIRST -- see the docstring. A stale rebuilt_ROMs/ makes this
    # script report PASS on artefacts that no longer correspond to the sources.
    if "--no-build" in sys.argv:
        print("  !! --no-build: comparing whatever is on disk, NOT rebuilding")
    else:
        import subprocess as _sp
        print("  building (make all) ...")
        r = _sp.run(["make", "all"], cwd=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), capture_output=True, text=True)
        if r.returncode != 0:
            tail = "\n".join((r.stdout + r.stderr).strip().splitlines()[-6:])
            print("  BUILD FAILED -- the comparison below would be meaningless:")
            print(tail)
            sys.exit(2)
    bad = 0
    for stem, built in PAIRS:
        o = os.path.join("original_ROMs", stem + ".rom")
        b = os.path.join("rebuilt_ROMs", built)
        if not (os.path.exists(o) and os.path.exists(b)):
            print(f"  {stem:38} MISSING (build first)")
            bad += 1
            continue
        A, B = open(o, "rb").read(), open(b, "rb").read()
        if len(A) != len(B):
            print(f"  {stem:38} SIZE {len(A):,} vs {len(B):,}")
            bad += 1
            continue
        d = sum(1 for x, y in zip(A, B) if x != y)
        print(f"  {stem:38} {'IDENTICAL' if d == 0 else f'{d} BYTES DIFFER'}")
        bad += (d != 0)
    print(f"\n{'PASS: every rebuilt ROM is byte-identical.' if not bad else f'FAIL: {bad} target(s) differ.'}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
