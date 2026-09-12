#!/usr/bin/env python3
"""load_nocoef_census.py -- how many words would a "stale LOAD is an erasure" rule change?

QUESTION IT ANSWERS
    `upd6383.cpp' names a candidate rule in two places (§83 for delay words, §138 generalised):

        a word with `f31 == 0' (LOAD acc <- P) that fetches NO coefficient brought no fresh
        product, so loading from P is an ERASURE, not an operation -- treat it as HOLD.

    N-INPUT-GATE-OPENED §23 MEASURED that exactly such a word (`iw88') throws away the parametric
    EQ's input two words after it arrives.  Before testing the rule it is worth knowing its BLAST
    RADIUS: a rule that rewrites a third of the corpus is not a tweak, and a two-sided gate pass
    would have to be read in that light.

    This counts it statically from the listings, with the device's own predicates:

        f31        = hi12[3:1]                       (0 = LOAD)
        coeff_fetch= (class4 & 8) && !c_format       (upd6383d.h:981)
        c_format   = (hi12 & 0xf00) == 0xc00         (upd6383d.h:73)

USAGE
    python3 dsp/tools/load_nocoef_census.py [dsp/disasm/*.dsm]

    With no arguments it reads every listing in dsp/disasm/.  Prints the corpus totals and the
    programs most affected.  MEASURED 2026-09-12 over 3 057 words: 1 302 LOADs (42.6 %), of which
    1 084 fetch no coefficient -- 35.5 % of the whole corpus.
"""
import glob
import os
import re
import sys

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def fields(w):
    hi12 = (w >> 24) & 0xfff
    return hi12, (hi12 >> 1) & 7, (w >> 20) & 0xf


def c_format(hi12):
    return (hi12 & 0xf00) == 0xc00


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    tot = load = load_nocoef = 0
    per = {}
    for f in files:
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if not m:
                continue
            w = int(m.group(2), 16)
            hi12, f31, cls = fields(w)
            tot += 1
            if f31 != 0:
                continue
            load += 1
            if (cls & 8) and not c_format(hi12):
                continue                    # it fetches a coefficient: the product IS fresh
            load_nocoef += 1
            per[os.path.basename(f)] = per.get(os.path.basename(f), 0) + 1

    if not tot:
        print("no listing rows matched -- wrong path?")
        return 1
    print("corpus words                       : %d" % tot)
    print("f31 == 0 (LOAD acc <- P)           : %d  (%.1f%%)" % (load, 100.0 * load / tot))
    print("  ...fetching NO coefficient       : %d  (%.1f%% of ALL words)"
          % (load_nocoef, 100.0 * load_nocoef / tot))
    print("  ⇒ that is the blast radius of the \"stale LOAD is an erasure\" rule.")
    print("programs with the most such words:")
    for k, v in sorted(per.items(), key=lambda kv: -kv[1])[:10]:
        print("   %-40s %d" % (k, v))
    return 0


if __name__ == "__main__":
    sys.exit(main())
