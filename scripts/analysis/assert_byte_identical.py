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

# (stem, original file in original_ROMs/, rebuilt file in rebuilt_ROMs/)
#
# ⚠ THE LAST THREE WERE NOT GATED AT ALL UNTIL 2026-09-01.  The list used to hold
# stems only and looked for `original_ROMs/<stem>.rom`; the sub-CPU boot ROM, the
# custom-data flash and the HD-AE5000 board ROM are dumped under their IC names
# (`.ic30`, `.ic19`, `.ic4`), so those three names never resolved and three of the
# nine images `make all` builds were certified by nothing.  All three were in fact
# byte-identical when the pairs were added, so this widens the gate without moving
# a byte -- but "it happened to be right" is not the same as "it was checked", and
# subcpu/boot in particular carries tone-generator code.
PAIRS = [
    ("kn5000_v7_program", "kn5000_v7_program.rom", "kn5000_v7_program.llvm.rom"),
    ("kn5000_v9_program", "kn5000_v9_program.rom", "kn5000_v9_program.llvm.rom"),
    ("kn5000_v10_program", "kn5000_v10_program.rom", "kn5000_v10_program.llvm.rom"),
    ("kn5000_subprogram_v142", "kn5000_subprogram_v142.rom", "kn5000_subprogram_v142.llvm.rom"),
    ("kn5000_subprogram_v142_compressed", "kn5000_subprogram_v142_compressed.rom", "kn5000_subprogram_v142_compressed.rom"),
    ("kn5000_table_data", "kn5000_table_data.rom", "kn5000_table_data.llvm.rom"),
    ("kn5000_subcpu_boot", "kn5000_subcpu_boot.ic30", "kn5000_subcpu_boot.llvm.rom"),
    ("kn5000_custom_data", "kn5000_custom_data.ic19", "kn5000_custom_data.llvm.rom"),
    ("hd-ae5000_v2_06i", "hd-ae5000_v2_06i.ic4", "hd-ae5000_v2_06i.llvm.rom"),
]


def main():

    # REBUILD FIRST -- see the docstring. A stale rebuilt_ROMs/ makes this
    # script report PASS on artefacts that no longer correspond to the sources.
    if "--no-build" in sys.argv:
        print("  !! --no-build: comparing whatever is on disk, NOT rebuilding")
        _build_started = 0.0
    else:
        import subprocess as _sp
        import time as _time
        _build_started = _time.time()
        print("  building (make all) ...")
        r = _sp.run(["make", "all"], cwd=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), capture_output=True, text=True)
        if r.returncode != 0:
            tail = "\n".join((r.stdout + r.stderr).strip().splitlines()[-6:])
            print("  BUILD FAILED -- the comparison below would be meaningless:")
            print(tail)
            sys.exit(2)
    # ⚠ A NON-ZERO EXIT IS NOT THE ONLY WAY A BUILD FAILS. If a recipe fails
    # while make still returns 0, or make simply does not rebuild what it
    # should, the PREVIOUS rebuilt_ROMs/*.rom is still on disk and this
    # comparison reports IDENTICAL for it -- a false green of exactly the shape
    # that let week-old objects certify the tree on 2026-09-01 (blog Part 152),
    # reported again by lane v10audio on 2026-09-02.
    #
    # ⚠ TWO HAND-ROLLED VERSIONS OF THIS GUARD WERE WRONG BEFORE THIS ONE, both
    # FALSE-REDDING on a perfectly good tree -- and a false red trains people to
    # ignore the gate, which is the same damage as a false green:
    #   1. "every ROM must be newer than when the build started" -- wrong,
    #      because a correct INCREMENTAL build has nothing to do and its
    #      up-to-date ROMs legitimately predate it.
    #   2. "every ROM must be newer than the newest source in the tree" --
    #      wrong, because it compared the v7 and v9 ROMs against a v10 source
    #      they do not depend on.
    #
    # The invariant is per-target and make already owns it, so ASK MAKE:
    # `make -q <target>` runs no recipe and exits non-zero exactly when the
    # target is out of date. No dependency logic is duplicated here, so this
    # cannot drift from the Makefile the way a hand-rolled mtime rule does.
    if "--no-build" not in sys.argv:
        import subprocess as _sp2
        stale = []
        for stem, _orig, built in PAIRS:
            t = os.path.join("rebuilt_ROMs", built)
            q = _sp2.run(["make", "-q", t], capture_output=True, text=True)
            if q.returncode != 0:
                stale.append(f"{stem} ({t})")
        if stale:
            print("  STALE -- `make -q` says these targets are out of date, so "
                  "the build did not produce them and the comparison below "
                  "would be meaningless:")
            for line in stale:
                print(f"    {line}")
            sys.exit(2)

    bad = 0
    for stem, orig, built in PAIRS:
        o = os.path.join("original_ROMs", orig)
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
