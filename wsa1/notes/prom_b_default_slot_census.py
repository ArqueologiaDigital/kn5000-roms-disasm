#!/usr/bin/env python3
"""Where does the 4-byte spelling of thunk slot T_TableDefault_Ret (0x00F42C70) occur, and
   does it form one dense run?

QUESTION ANSWERED
  `FINDINGS-prom_b-thunk-table.md` and `FINDINGS-prom_b-dispatch-layers.md` said
  the little-endian spelling `70 2C F4 00` occurs 397 times in prom_a+prom_b,
  "222 of them in one dense run at prom_a 0x216B4".

  The 397 is right.  The "222 in one run" was NOT: 222 is prom_a's TOTAL, and the
  file offset 0x216B4 is only where prom_a's FIRST occurrence sits.  This script
  measures both quantities separately so the two can never be joined by hand
  again:

    * per-image occurrence counts of the 4-byte pattern (every byte offset, not
      only 4-aligned ones);
    * the maximal STRIDE-4 run anywhere in each image, and the run that begins at
      each image's first occurrence.

  A "stride-4 run" = a maximal set of occurrences at offsets p, p+4, p+8, ...,
  i.e. consecutive slots of a pointer table all holding the default entry.

WHAT A RESULT MEANS
  If the longest stride-4 run is much shorter than the total, the occurrences are
  scattered across many tables (or many regions of one table), and no single
  "dense run" figure may be quoted.

RUN
  python3 notes/prom_b_default_slot_census.py            # the census
  python3 notes/prom_b_default_slot_census.py --runs     # every run of >= 2
Exit status is non-zero if any self-check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = [("prom_a", "wsa1_prom_a.ic12", 0xF80000),
          ("prom_b", "wsa1_prom_b.ic13", 0xF00000)]
TARGET = 0x00F42C70
PAT = TARGET.to_bytes(4, "little")

FAIL = []


def check(msg, cond):
    print("  %-62s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def occurrences(blob):
    """Every byte offset at which PAT occurs, overlapping scan."""
    out, p = [], blob.find(PAT)
    while p >= 0:
        out.append(p)
        p = blob.find(PAT, p + 1)
    return out


def stride4_runs(offs):
    """Maximal runs of offsets spaced exactly 4 apart. -> [(start, count)]"""
    s = set(offs)
    runs = []
    for p in offs:
        if p - 4 in s:
            continue                     # not the head of its run
        n = 1
        while p + 4 * n in s:
            n += 1
        runs.append((p, n))
    return runs


def main():
    print("census of the 4-byte spelling %s (= 0x%06X)"
          % (" ".join("%02X" % c for c in PAT), TARGET))
    print()
    total = 0
    allruns = {}
    for name, fn, base in IMAGES:
        blob = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        offs = occurrences(blob)
        runs = sorted(stride4_runs(offs), key=lambda r: -r[1])
        allruns[name] = (offs, runs, base)
        total += len(offs)
        longest = runs[0]
        head = [r for r in runs if r[0] == offs[0]][0]
        print("%s  %d occurrences" % (name, len(offs)))
        print("   file offsets 0x%05X..0x%05X   (CPU 0x%06X..0x%06X)"
              % (offs[0], offs[-1], base + offs[0], base + offs[-1]))
        print("   longest stride-4 run: %d entries, starting at file 0x%05X"
              % (longest[1], longest[0]))
        print("   run starting at the FIRST occurrence (file 0x%05X): %d entries"
              % (offs[0], head[1]))
        print("   runs of >= 2: %d ; occurrences in a run of >= 2: %d"
              % (sum(1 for r in runs if r[1] >= 2),
                 sum(r[1] for r in runs if r[1] >= 2)))
        print("   4-aligned occurrences: %d of %d"
              % (sum(1 for p in offs if p % 4 == 0), len(offs)))
        print()

    print("prom_a + prom_b total: %d" % total)
    print()
    print("self-checks")
    check("total over both images is 397", total == 397)
    a_offs, a_runs, _ = allruns["prom_a"]
    b_offs, b_runs, _ = allruns["prom_b"]
    check("prom_a holds 222 of them", len(a_offs) == 222)
    check("prom_b holds 175 of them", len(b_offs) == 175)
    check("prom_a's first occurrence is at file 0x216B4", a_offs[0] == 0x216B4)
    check("no stride-4 run in prom_a reaches 222 entries",
          max(r[1] for r in a_runs) < 222)
    check("no stride-4 run in prom_b reaches 175 entries",
          max(r[1] for r in b_runs) < 175)

    if "--runs" in sys.argv:
        for name in ("prom_a", "prom_b"):
            offs, runs, base = allruns[name]
            print()
            print("%s runs of >= 2 (file offset, CPU address, entries)" % name)
            for p, n in sorted(r for r in runs if r[1] >= 2):
                print("   0x%05X  0x%06X  %d" % (p, base + p, n))

    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
