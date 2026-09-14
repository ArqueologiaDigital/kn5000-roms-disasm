#!/usr/bin/env python3
"""act0b_symmetry.py -- is `ACT 0x0B' the WRITE side of the register `SRC 0x0B' reads?  No.

QUESTION IT ANSWERS
    `SRC 0x0B' is ANCHORED (sect. 215, over 41 listings / 3057 words): *"the delay-read DATA
    REGISTER -- a delay READ has to land somewhere for the next word to use, and 0x0B is the only
    source code in the corpus whose operand is otherwise unaccounted for."*

    `ACT 0x0B' is the queue head, 191 sole-blocked words, with THREE surviving readings.  The same
    numeric code in the other field is a natural candidate: **ACT 0x0B deposits what SRC 0x0B
    collects.**  If so, a SRC-0x0B read should sit right after an ACT-0x0B word.

    ⛔ IT DOES NOT.  Over 488 pooled SRC-0x0B reads: **0 at lag 1**, median lag 14, and `ACT 0x0B`
    ranks **8th of 16** actions on lag-1 adjacency.  The symmetric-code reading is REFUTED.

    ★ AND THE PER-CATEGORY CONTROL -- run WITH the test this time, after sect. 130 -- turned up
    something the test itself had no way to see: `ACT 0x01' sits at lag 1 before a SRC-0x0B read
    in **70 of 91** occurrences, base rate 1.2 %, permutation null mean 4.5 / sd 2.0 / max 12 over
    2000 shuffles.  ~33 sigma.

    ⛔⛔ AND THAT DOES NOT ANCHOR `ACT 0x01' EITHER, for two reasons this file measures:
      1. RULE 9, REPLICATION.  The 70 is per-OCCURRENCE.  De-duplicated it is **one distinct word**
         -- `A00.0.00.041' -- appearing in 27 images (2.6x replication).
      2. ★ THE CONFOUND THE DE-DUPLICATION EXPOSES.  Of the **13** distinct ACT-0x01 words,
         **exactly ONE** ever precedes a SRC-0x0B read, and it does so in 27 of its 27 images.
         The other twelve NEVER do.  ⇒ the adjacency is a property of THAT WORD, not of the
         ACTION field, and it decodes neither of the two unanchored fields it carries
         (`SRC 0x01' and `ACT 0x01' both).

    What survives is a real, null-backed TWO-WORD IDIOM: `A00.0.00.041' is followed by a
    delay-data read in every image that contains it (27 images vs a shuffled null of max 11).

USAGE
    python3 dsp/tools/act0b_symmetry.py

⚠ A NOTE ON A BUG IN THE THROWAWAY THAT FOUND THIS.  The first de-duplication printed
  "13 of 13 distinct words are followed by a SRC-0x0B read", which is false -- the count read a
  `defaultdict` inside a display loop and CREATED the twelve missing keys as it printed them.  The
  table beside it showed the truth (one word at 100 %, twelve at 0 %).  Written down because a
  container that materialises keys on read is a good way to turn a 1 into a 13.
"""
import collections
import os
import random
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402

SRC_DRD = 0x0B
SHUFFLES = 2000


def nonc(ws):
    return [i for i, w in enumerate(ws) if not DIS.c_format(w)]


def lag1_rate(act):
    """SRC-0x0B reads whose immediately preceding non-C word carries `act'."""
    hit = tot = 0
    for label, name, ws in X.images():
        idx = nonc(ws)
        for k in range(1, len(idx)):
            if DIS.lo_src(ws[idx[k]]) != SRC_DRD:
                continue
            tot += 1
            hit += DIS.lo_act(ws[idx[k - 1]]) == act
    return hit, tot


def main():
    random.seed(5)
    print("=" * 100)
    print("  act0b_symmetry -- is ACT 0x0B the write side of what SRC 0x0B reads?")
    print("=" * 100)

    #  ---- 1. the hypothesis ------------------------------------------------
    hit, tot = lag1_rate(0x0B)
    print("\n   ★ TEST -- %d pooled SRC-0x0B reads; preceded at lag 1 by an ACT-0x0B word: %d"
          % (tot, hit))
    lags = []
    for label, name, ws in X.images():
        prod = [i for i in nonc(ws) if DIS.lo_act(ws[i]) == 0x0B]
        for i in nonc(ws):
            if DIS.lo_src(ws[i]) != SRC_DRD:
                continue
            pre = [i - j for j in prod if j < i]
            if pre:
                lags.append(min(pre))
    if lags:
        print("      nearest preceding ACT-0x0B: median lag %d (n = %d)"
              % (statistics.median(lags), len(lags)))
    print("      ⇒ ⛔ REFUTED.  The symmetric-code reading predicts lag 1; the ROM gives 0.")

    #  ---- 2. the per-category control, run WITH the test -------------------
    print("\n   ★ THE PER-CATEGORY CONTROL (sect. 130's lesson: a rate means nothing alone)\n")
    acts = sorted({DIS.lo_act(w) for _l, _n, ws in X.images() for w in ws
                   if not DIS.c_format(w)})
    rows = []
    for a in acts:
        h, t = lag1_rate(a)
        if h:
            rows.append((h, a))
    for h, a in sorted(rows, reverse=True)[:6]:
        print("      ACT 0x%02X   lag-1 before a SRC-0x0B read: %4d   %s"
              % (a, h, "★ the unexpected one" if a == 0x01 else
                 "← the one under test" if a == 0x0B else ""))

    #  ---- 3. and why the unexpected one is not a decode --------------------
    allw = collections.defaultdict(set)
    paired = collections.defaultdict(set)
    for label, name, ws in X.images():
        idx = nonc(ws)
        img = label + ":" + name
        for k in range(len(idx)):
            w = ws[idx[k]]
            if DIS.lo_act(w) != 0x01:
                continue
            allw[w].add(img)
            if k + 1 < len(idx) and DIS.lo_src(ws[idx[k + 1]]) == SRC_DRD:
                paired[w].add(img)
    print("\n   ⛔⛔ RULE 9 -- DE-DUPLICATE, then look at WHICH WORDS\n")
    print("      %-16s %8s %10s %8s" % ("ACT-0x01 word", "images", "paired", "ratio"))
    npair = 0
    for w in sorted(allw, key=lambda w: -len(allw[w])):
        p = len(paired[w]) if w in paired else 0     # ⚠ do NOT index a defaultdict here
        npair += p > 0
        print("      %03X.%X.%02X.%03X %8d %10d %7.0f%%"
              % (DIS.hi12(w), DIS.class4(w), DIS.addr8(w), DIS.lo12(w),
                 len(allw[w]), p, 100.0 * p / len(allw[w])))
    print("\n      ⇒ %d of %d DISTINCT ACT-0x01 words ever precede a SRC-0x0B read."
          % (npair, len(allw)))
    print("      ⇒ the adjacency is a property of ONE WORD, not of the ACTION field, so it")
    print("        anchors neither `ACT 0x01' nor the `SRC 0x01' that word also carries.")

    #  the idiom itself, with its null
    obs = len({i for s in paired.values() for i in s})
    nulls = []
    for _ in range(SHUFFLES):
        s = set()
        for label, name, ws in X.images():
            idx = nonc(ws)
            a = [DIS.lo_act(ws[i]) for i in idx]
            random.shuffle(a)
            for k in range(1, len(idx)):
                if DIS.lo_src(ws[idx[k]]) == SRC_DRD and a[k - 1] == 0x01:
                    s.add(label + ":" + name)
                    break
        nulls.append(len(s))
    print("\n   ★ WHAT SURVIVES: a two-word IDIOM.  `A00.0.00.041' is followed by a delay-data")
    print("     read in %d images; shuffled null mean %.1f, sd %.1f, MAX %d over %d."
          % (obs, statistics.mean(nulls), statistics.pstdev(nulls), max(nulls), SHUFFLES))
    print("     Real, and it decodes nothing -- an adjacency is not a field reading.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
