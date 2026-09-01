#!/usr/bin/env python3
"""How many prom_a directory SLOTS -- and how many DISTINCT TARGETS -- are still
`.incbin`, for a NAMED version of prom_a/wsa1_prom_a.s?

QUESTION IT ANSWERS
  `notes/prom_a_call_graph.py` prints "top N of M" where M counts SLOTS, and a
  round report quoted that M as a count of "unconverted prom_a directory
  TARGETS".  Those are two different numbers -- several slots publish the same
  address -- and the round-2 audit (F10) caught the difference: 1218/1006 slots
  against 1165/953 distinct targets.  This script prints BOTH, from any revision
  of the source, so a before/after pair is measured rather than remembered.

  It also prints, for a before/after pair, how many distinct targets fall inside
  each newly converted range and HOW MANY RANGES there are -- the other half of
  F10, where seven converted ranges were reported as four.

RUN
  python3 notes/prom_a_frontier_delta.py                       # working tree
  python3 notes/prom_a_frontier_delta.py --rev HEAD            # any git revision
  python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree   # the delta
Exit status is non-zero only if a self-check fails.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import git_show  # noqa: E402  (git paths are repo-relative)
B_BASE, A_BASE = 0xF00000, 0xF80000
TBL_LO, TBL_HI = 0x40000, 0x44018
SRC_REL = "prom_a/wsa1_prom_a.s"
PAT = re.compile(r'\.incbin\s+"[^"]*wsa1_prom_a\.ic12"\s*,\s*(0x[0-9A-Fa-f]+)\s*,'
                 r'\s*(0x[0-9A-Fa-f]+)')

# The named assembly blocks of the 2026-08-25 round, in source order.  They are
# what FINDINGS-prom_a-ring-buffers.md's table lists; `--vs-worktree` reports
# the MAXIMAL CONTIGUOUS ranges instead, which is a coarser grouping of the same
# bytes (0xF830C6-0xF85600 is one run once the two `.fill` pads are counted as
# converted, which they are).  Both groupings are printed so a report can say
# which one it means.
BLOCKS_2026_08_25 = [
    ("SeqBuf/Dev7F",         0xF830C6, 0xF83216),
    ("ring class",           0xF84000, 0xF842DF),
    ("ring instance bank",   0xF842DF, 0xF84C6C),
    ("ASCII numeric field",  0xF8BC00, 0xF8BF22),
    ("callback queue+task2", 0xF8DA00, 0xF8DABA),
    ("analogue scan",        0xF8DC00, 0xF8DDE6),
    ("link block layer",     0xF8E000, 0xF8E47F),
    ("0xFE0000 app span",    0xFE0000, 0xFE54B6),
]


def source(rev=None):
    if rev is None:
        return open(os.path.join(ROOT, SRC_REL), encoding="utf-8").read()
    return git_show(SRC_REL, rev)


def incbin_ranges(text):
    out = []
    for line in text.splitlines():
        m = PAT.search(line)
        if m:
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            out.append((o, o + n))
    return sorted(out)


def is_incbin(ranges, off):
    return any(lo <= off < hi for lo, hi in ranges)


def a_slots():
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    out = {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = b[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            t = s[1] | s[2] << 8 | s[3] << 16
            if t >= A_BASE:
                out[B_BASE + o] = t
    return out


def live(ranges, slots):
    return {s: t for s, t in slots.items() if is_incbin(ranges, t - A_BASE)}


def converted_ranges(before, after):
    """Ranges that were .incbin in `before` and are not in `after`, as (lo,hi)
    file offsets, MERGED only where they are literally adjacent."""
    covered = []
    for lo, hi in before:
        cur = lo
        for alo, ahi in after:
            if ahi <= cur or alo >= hi:
                continue
            if alo > cur:
                covered.append((cur, alo))
            cur = max(cur, ahi)
        if cur < hi:
            covered.append((cur, hi))
    covered.sort()
    merged = []
    for lo, hi in covered:
        if merged and merged[-1][1] == lo:
            merged[-1] = (merged[-1][0], hi)
        else:
            merged.append((lo, hi))
    return merged


def report(tag, ranges, slots):
    lv = live(ranges, slots)
    print("%-24s %5d slots   %5d distinct targets   %6d bytes .incbin"
          % (tag, len(lv), len(set(lv.values())), sum(h - l for l, h in ranges)))
    return lv


def main():
    rev = None
    if "--rev" in sys.argv:
        rev = sys.argv[sys.argv.index("--rev") + 1]
    slots = a_slots()
    print("prom_b directory: %d `jp` slots naming prom_a" % len(slots))
    r_rev = incbin_ranges(source(rev)) if rev else None
    r_wt = incbin_ranges(source(None))

    if rev and "--vs-worktree" in sys.argv:
        lv_b = report(rev, r_rev, slots)
        lv_a = report("working tree", r_wt, slots)
        newly = converted_ranges(r_rev, r_wt)
        gone = set(lv_b.values()) - set(lv_a.values())
        print()
        print("newly converted: %d RANGE(S), %d bytes"
              % (len(newly), sum(h - l for l, h in newly)))
        for lo, hi in newly:
            inside = sorted(t for t in gone if lo <= t - A_BASE < hi)
            print("   0x%06X-0x%06X  %5d bytes   %3d distinct targets retired"
                  % (A_BASE + lo, A_BASE + hi, hi - lo, len(inside)))
        print("   slots retired      %d" % (len(lv_b) - len(lv_a)))
        print("   targets retired    %d" % len(gone))
        if "--by-block" in sys.argv:
            print()
            print("the same targets, split by NAMED BLOCK (finer grouping)")
            for nm, lo, hi in BLOCKS_2026_08_25:
                print("   %-22s 0x%06X-0x%06X  %3d"
                      % (nm, lo, hi, len([t for t in gone if lo <= t < hi])))
        ok = len(gone) == sum(len([t for t in gone if lo <= t - A_BASE < hi])
                              for lo, hi in newly)
        print("self-check: every retired target lies in a newly converted range  %s"
              % ("ok" if ok else "FAIL"))
        return 0 if ok else 1

    report(rev or "working tree", r_rev if rev else r_wt, slots)
    return 0


if __name__ == "__main__":
    sys.exit(main())
