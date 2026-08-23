#!/usr/bin/env python3
"""How much of each `.incbin` blob's interior do the sources already NAME?

QUESTION ANSWERED
-----------------
`audit_incbin_legitimacy.py` decides whether a binary include "earns" being a
true binary by reading its BYTES. That is only half the question the project's
own rule asks -- a blob whose interior is documented elsewhere is not opaque in
the sense that matters to a reader.

These sources document blob interiors with `.equ` constants:

    .equ IconBitmapNamePtrTable, NakaData_WidgetNames + 0x4C28
    .equ IconName_i5,            NakaData_WidgetNames + 0x4C02

Each is a NAME for a position inside a blob. The audit cannot see them, so it
reports blobs as OPAQUE / "no better format on this evidence" while thousands of
names for their contents sit in the files beside them.

⚠ WHAT THIS DOES NOT CLAIM. A named offset says where something starts and what
it is called. It does not give its length, its field layout, or its type, and
several names may describe one record. So this measures DOCUMENTATION PRESENT,
not structure fully specified -- it is an upper bound on how well these blobs are
described and a lower bound on how badly.

⚠ It also does not claim the names are apt (that is the L2 problem, and
`ToneGen_ParamTable` is a jump table).

USE: the offsets are the correct BOUNDARIES for any future splitting of these
blobs -- far better founded than a window scan, which is aligned to a power of
two and knows nothing about records.

Run:  python3 scripts/analysis/l3_named_offsets_into_blobs.py [--base NAME]
"""
import argparse, collections, glob, os, pathlib, re, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
EQU = re.compile(r'^\s*\.equ\s+(\w+)\s*,\s*(\w+)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*$')
INCBIN = re.compile(r'^\s*(\w+)?:?\s*\.incbin\s+"([^"]+)"')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", help="list the named offsets for one base label")
    a = ap.parse_args()

    per = collections.defaultdict(list)
    # ⚠ Union, DEDUPED. The two patterns overlap; concatenating them counts
    # every maincpu file twice, which is how an earlier probe of mine turned a
    # per-file count into nonsense.
    for f in sorted(set(glob.glob("*/maincpu/**/*.s", recursive=True))
                    | set(glob.glob("*/**/*.s", recursive=True))):
        try:
            lines = open(f, encoding="latin1").read().splitlines()
        except OSError:
            continue
        for ln in lines:
            m = EQU.match(ln)
            if m:
                per[m.group(2)].append((int(m.group(3), 0), m.group(1)))

    if a.base:
        offs = sorted(set(per.get(a.base, [])))
        print(f"  {len(offs)} named offsets into {a.base}")
        for o, n in offs[:60]:
            print(f"    +0x{o:06X}  {n}")
        if len(offs) > 60:
            print(f"    ... and {len(offs)-60} more")
        if len(offs) > 1:
            d = collections.Counter(offs[i + 1][0] - offs[i][0]
                                    for i in range(len(offs) - 1))
            print("\n  gap histogram (a record stride shows up here):")
            for g, c in d.most_common(8):
                print(f"    {g:6}  x{c}")
        return 0

    print(f"  base labels with named interior offsets : {len(per)}")
    tot = sum(len(set(v)) for v in per.values())
    print(f"  named offsets in total                  : {tot:,}")
    print()
    print(f"  {'names':>6}  base label")
    for k, v in sorted(per.items(), key=lambda kv: -len(set(kv[1])))[:16]:
        print(f"  {len(set(v)):6,}  {k}")
    print()
    print("  ⚠ A named offset gives a position and a name, not a length or a")
    print("    layout. This is documentation PRESENT, not structure specified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
