#!/usr/bin/env python3
"""act0b_hazard.py -- does the ROM SCHEDULE around `ACT 0x0B'?  A null, and the control that kills it.

QUESTION IT ANSWERS
    `act0b-reverb.md' item D leaves THREE readings of `ACT 0x0B' alive: `none', `mem<-bus' and
    `tA<-acc'.  `sd_act0b.py' MEASURED that SINGLE DELAY's lag-1001 ROM product cannot separate
    them (all six readings accepted, LEDGER sect. 291), so the queue's head needs a criterion that
    can SEE the code.  This is one such criterion, and it fails.

    ★ THE IDEA.  If `ACT 0x0B' writes tempA, then an ACT-0x0B word placed between a tempA WRITE
    (`ACT 0x13') and the READ that consumes it (`SRC 0x19') would destroy a value the program
    depends on.  A compiler -- or a human writing microcode -- must avoid that.  So: do ACT-0x0B
    words ever land inside a tempA live range?

    ★★ THE ANSWER LOOKS DECISIVE, AND IS NOT.
      * Pooled: **0 of 213** ACT-0x0B words land inside a tempA live range, base rate 9.0 %.
      * Restricted to the 26 images carrying BOTH (the control for program-level segregation):
        windows span **25.7 %** of slots and **0 of 48** ACT-0x0B words are inside.
        Binomial P(0) = 6.6e-7; permutation null over 2000 reshuffles within each image:
        mean 11.8, sd 2.8, **MIN 4**.  Observed 0, p = 0.0000.
      * ⛔ **AND THEN THE PER-ACTION CONTROL.**  The same test for EVERY action: **5 of the 14
        with n >= 20 are equally excluded** -- `0x13`, `0x0B`, `0x03`, `0x01`, `0x1C`.  Two of
        those have no tempA relationship whatever, and `0x13` is excluded BY CONSTRUCTION (it is
        the write that opens the window; this file's window definition cannot place one inside).
        ⇒ the exclusion is a property of what a filter's INNER LOOP contains -- a narrow ACTION
        vocabulary, with `0x12` and `0x14` ENRICHED 3.6x -- not a hazard-avoidance around 0x0B.

    ⇒ **THE READING IS NOT SUPPORTED AND NOT REFUTED.  The criterion has no power.**

USAGE
    python3 dsp/tools/act0b_hazard.py

★ THE METHOD NOTE THIS EXISTS FOR.  The permutation null was CORRECT and INSUFFICIENT.  It asked
  *"is 0 unusual for ACT 0x0B's positions?"* and answered yes, decisively.  The question that
  decides is *"is 0 unusual for an ACTION OF THIS KIND?"* -- and it is not.  A null that moves is
  not automatically a null that discriminates; the second session running, the row that survived
  its first null died to the second.  Run the per-category control before believing a rate.
"""
import collections
import os
import random
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402
import xprod_homolog as X                                                 # noqa: E402

ACT0B = 0x0B
SHUFFLES = 2000


def windows(ws):
    """(write, read) pairs -- a tempA write and the NEXT tempA read.  ⚠ A second write re-opens
    the window, so an `ACT 0x13' word can never be `inside' one: that exclusion is an artefact of
    this definition and is called out in the control below rather than being quietly counted."""
    out, last = [], None
    for i, w in enumerate(ws):
        if DIS.c_format(w):
            continue
        if DIS.lo_act(w) == DIS.LO_ACT_CAP_TA:
            last = i
        elif DIS.lo_src(w) == DIS.LO_SRC_TA and last is not None:
            out.append((last, i))
            last = None
    return out


def span_of(ws):
    s = set()
    for a, b in windows(ws):
        s.update(range(a + 1, b))
    return s


def main():
    random.seed(3)
    imgs = list(X.images())
    print("=" * 100)
    print("  act0b_hazard -- does the ROM schedule around `ACT 0x0B'?")
    print("=" * 100)

    #  ---- 1. the test, restricted to co-occurring images -------------------
    co = [(l, n, ws) for l, n, ws in imgs
          if windows(ws) and any((not DIS.c_format(w)) and DIS.lo_act(w) == ACT0B for w in ws)]
    span_tot = slots = inside = occ = 0
    for l, n, ws in co:
        sp = span_of(ws)
        span_tot += len(sp)
        slots += len(ws)
        for i, w in enumerate(ws):
            if DIS.c_format(w) or DIS.lo_act(w) != ACT0B:
                continue
            occ += 1
            inside += i in sp
    p = span_tot / float(slots) if slots else 0.0
    print("\n   ★ TEST -- %d images carry BOTH a tempA live range and an ACT-0x0B word." % len(co))
    print("     (the pooled base rate cannot tell instruction-level avoidance from program-level")
    print("      segregation; this restriction can)\n")
    print("      windows span %d of %d slots (%.1f %%)" % (span_tot, slots, 100 * p))
    print("      ACT-0x0B words inside one: %d of %d" % (inside, occ))
    print("      binomial expectation %.1f;  P(0 | p=%.3f, n=%d) = %.3g"
          % (occ * p, p, occ, (1 - p) ** occ))

    nulls = []
    for _ in range(SHUFFLES):
        s = 0
        for l, n, ws in co:
            sp = span_of(ws)
            free = [i for i, w in enumerate(ws) if not DIS.c_format(w)]
            k = sum(1 for w in ws if (not DIS.c_format(w)) and DIS.lo_act(w) == ACT0B)
            s += sum(1 for i in random.sample(free, min(k, len(free))) if i in sp)
        nulls.append(s)
    print("\n      ⛔ PERMUTATION NULL (%d reshuffles within each image): mean %.1f, sd %.1f, MIN %d"
          % (SHUFFLES, statistics.mean(nulls), statistics.pstdev(nulls), min(nulls)))
    print("         observed %d -- below the minimum of every one of %d shuffles."
          % (inside, SHUFFLES))
    print("      ⇒ on this null the reading `ACT 0x0B writes tempA' looks CONFIRMED.")

    #  ---- 2. the control that kills it ------------------------------------
    ins = collections.Counter()
    tot = collections.Counter()
    sp_slots = all_slots = 0
    for l, n, ws in imgs:
        if not windows(ws):
            continue
        sp = span_of(ws)
        sp_slots += len(sp)
        all_slots += sum(1 for w in ws if not DIS.c_format(w))
        for i, w in enumerate(ws):
            if DIS.c_format(w):
                continue
            tot[DIS.lo_act(w)] += 1
            if i in sp:
                ins[DIS.lo_act(w)] += 1
    q = sp_slots / float(all_slots)
    print("\n   ⛔⛔ THE CONTROL THAT KILLS IT -- the SAME test for EVERY action.")
    print("      Windows span %.1f %% of non-C-format slots in the images that have them.\n" % (100 * q))
    print("      %-6s %7s %8s %9s %7s  %s" % ("ACT", "n", "inside", "expected", "ratio", ""))
    rows = [(ins[a] / max(1e-9, tot[a] * q), a) for a in tot if tot[a] >= 20]
    for r, a in sorted(rows):
        note = "★ THE ONE UNDER TEST" if a == ACT0B else (
            "⚠ excluded BY CONSTRUCTION -- it is the window's own write"
            if a == DIS.LO_ACT_CAP_TA else "")
        print("      0x%02X   %7d %8d %9.1f %7.2f  %s%s"
              % (a, tot[a], ins[a], tot[a] * q, r,
                 "★ EXCLUDED" if ins[a] == 0 else ("depleted" if r < 0.5 else "ordinary"),
                 "   " + note if note else ""))
    zero = [a for r, a in rows if ins[a] == 0]
    print("\n      ⇒ %d of %d actions with n >= 20 are COMPLETELY excluded: %s"
          % (len(zero), len(rows), " ".join("0x%02X" % a for a in zero)))
    print("      ⇒ ACT 0x0B is NOT alone, and two of its companions have no tempA relationship at")
    print("        all.  The exclusion describes what a FILTER'S INNER LOOP contains -- a narrow")
    print("        ACTION vocabulary, with 0x12 and 0x14 ENRICHED ~3.6x -- not hazard avoidance.")
    print("\n   ⇒ VERDICT: the reading is NEITHER supported NOR refuted.  The criterion has no")
    print("     power, and the permutation null could not tell me that: it asked whether 0 was")
    print("     unusual for THESE POSITIONS, not whether 0 was unusual for AN ACTION OF THIS KIND.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
