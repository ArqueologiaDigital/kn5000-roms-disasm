#!/usr/bin/env python3
"""Did round 6 remove exactly the thunk run it claimed, and no others?

QUESTION IT ANSWERS
  A round that says "this span retires the frontier's top four runs" is making a
  claim about a tool's output before and after.  This re-derives both halves from
  the ROM and from prom_b/wsa1_prom_b.s so the claim is a measurement:

    * BEFORE -- the run survey as it would be if 0xF6D002-0xF77FFF were still
      `.incbin`.  Computed by taking the file's CURRENT `.incbin` set and adding
      that range back, so it is not a number copied out of an old session log --
      which is the only way a "before" figure stays checkable after the fact.
    * AFTER  -- the same survey against the file as it stands.
    * The difference, run by run, and the slot count.

  ⚠ ITS RUN COUNT IS NOT notes/prom_b_module_frontier.py's.  That tool groups a
  run across a leading NON-`jp` slot ("opens with a pointer"); this script groups
  maximal spans of consecutive `jp` slots only, so its TOTALS differ by a run at
  each end.  The runs a round CLAIMS are named identically by both; do not quote
  this script's totals as the tool's.

  ⚠⚠ AND SOMEONE DID.  Round-2 audit finding F10: round 5's report printed
  "16 -> 14 runs" and cited THIS script's round-5 twin, which prints 15 and 13.  The warning
  above was already here and was not enough, so the script now RUNS
  prom_b_module_frontier.py itself, prints both totals side by side, and asserts
  the +1-at-each-end relationship as check 6.  A number a reader can see being
  derived cannot be attributed to the wrong tool.

  ⚠⚠ AND THE HEADLINE HERE IS SMALL ON PURPOSE.  Round 6 converted 45,054
  bytes and retires exactly ONE run of TWO slots, because this module is entered
  by DIRECT CALL and not through the 0xF40000 routine directory.  The frontier
  delta is therefore the WRONG measure of this round and is reported anyway, so
  that "the frontier barely moved" is a stated fact rather than an omission.
  The measure that ranked the span is notes/prom_b_span_frontier.py.

WHAT IT ASSERTS (non-zero exit if any fails)
    1. the run T_F43380-T_F43384 is in BEFORE
    2. it is not in AFTER
    3. no OTHER run disappeared -- a round must not be credited with a run some
       other change removed
    4. it owns exactly 2 `jp` slots, counted from the thunk table's own bytes
    5. both targets are inside 0xF6D002-0xF77FFF
    6. notes/prom_b_module_frontier.py's LIVE run total is this script's AFTER
       total + 1 (round-2 audit F10)
    6. notes/prom_b_module_frontier.py's LIVE run total is exactly this
       script's AFTER total + 1 -- the single run the two groupings
       disagree about, present in BOTH columns (round-2 audit F10).
       ⚠ "one more at each end" in the paragraph above means one more in
       the BEFORE figure AND one more in the AFTER figure, i.e. +1 to each
       column, not +2 overall; round 4 measured 19->15 against the tool's
       20->16 and this check pins that reading down.

RUN
  python3 notes/prom_b_round6_frontier_delta.py
  python3 notes/prom_b_round6_frontier_delta.py --runs
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import prom_b_module_frontier as MF                                # noqa: E402

SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
LO, HI = 0xF6D002, 0xF78000
CLAIMED = ["T_F43380-T_F43384"]

FAIL = []


def incbins(extra=None):
    """[(lo, hi)] CPU-address spans still `.incbin`, optionally plus `extra`."""
    out = []
    for l in open(SRC):
        m = re.search(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', l)
        if m:
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            out.append((B_BASE + o, B_BASE + o + n))
    if extra:
        out.append(extra)
    return sorted(out)


def runs_for(spans):
    """The frontier tool's run survey, but against a supplied `.incbin` set."""
    def covered(a):
        return any(s <= a < e for s, e in spans)
    d = open(IMG, "rb").read()
    slots = []
    for o in range(0x40000, 0x44018, 4):
        if d[o] == 0x1B:
            t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
            slots.append((B_BASE + o, t))
    # group into RUNS the same way prom_b_thunk_modules does: consecutive slots
    groups, cur = [], []
    for i, (s, t) in enumerate(slots):
        if cur and s != cur[-1][0] + 4:
            groups.append(cur)
            cur = []
        cur.append((s, t))
    if cur:
        groups.append(cur)
    out = {}
    for g in groups:
        unc = [(s, t) for s, t in g if B_BASE <= t < 0xF80000 and covered(t)]
        if unc:
            name = "T_%06X-T_%06X" % (g[0][0], g[-1][0])
            out[name] = unc
    return out


def check(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append(name)
    print("  %-64s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r" % (got, want)))


def main():
    after = runs_for(incbins())
    before = runs_for(incbins((LO, HI)))
    if "--runs" in sys.argv:
        for k in sorted(set(before) | set(after)):
            print("  %-22s before %3s  after %3s"
                  % (k, len(before.get(k, [])) or "-", len(after.get(k, [])) or "-"))
        return 0
    mf = len(MF.survey())
    print("runs with unconverted prom_b targets:")
    print("  THIS script's grouping (maximal `jp` spans): before %d, after %d"
          % (len(before), len(after)))
    print("  notes/prom_b_module_frontier.py, LIVE, on the same tree: %d" % mf)
    print("  the two groupings differ by ONE run in each column -- see the")
    print("  docstring.  QUOTE THE TOOL'S NUMBER AS THE TOOL'S (round-2 F10).")
    gone = sorted(set(before) - set(after))
    print("runs that disappeared: %s" % ", ".join(gone))
    for r in CLAIMED:
        check("%s is in BEFORE" % r, r in before, True)
        check("%s is NOT in AFTER" % r, r in after, False)
    check("no run disappeared other than the two claimed",
          sorted(set(gone) - set(CLAIMED)), [])
    d = open(IMG, "rb").read()
    n, outside = 0, []
    for r in CLAIMED:
        lo_ = int(r.split("-")[0][2:], 16)
        hi_ = int(r.split("-")[1][2:], 16)
        for o in range(lo_ - B_BASE, hi_ - B_BASE + 4, 4):
            if d[o] == 0x1B:
                n += 1
                t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
                if not (LO <= t < HI):
                    outside.append("0x%06X" % t)
    check("the run owns 2 `jp` slots", n, 2)
    check("both targets are inside 0x%06X-0x%06X" % (LO, HI - 1),
          outside, [])
    check("prom_b_module_frontier.py's live total is this script's AFTER + 1",
          mf, len(after) + 1)
    print("\n%s (%d failed)" % ("DELTA PASS" if not FAIL else "DELTA FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
