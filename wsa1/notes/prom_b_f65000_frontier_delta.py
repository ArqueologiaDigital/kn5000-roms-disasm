#!/usr/bin/env python3
"""Did round 4 remove exactly the four thunk runs it claimed, and no others?

QUESTION IT ANSWERS
  A round that says "this span retires the frontier's top four runs" is making a
  claim about a tool's output before and after.  This re-derives both halves from
  the ROM and from prom_b/wsa1_prom_b.s so the claim is a measurement:

    * BEFORE -- the run survey as it would be if 0xF65000-0xF6D001 were still
      `.incbin`.  Computed by taking the file's CURRENT `.incbin` set and adding
      that range back, so it is not a number copied out of an old session log --
      which is the only way a "before" figure stays checkable after the fact.
    * AFTER  -- the same survey against the file as it stands.
    * The difference, run by run, and the slot count.

  ⚠ ITS RUN COUNT IS NOT notes/prom_b_module_frontier.py's.  That tool groups a
  run across a leading NON-`jp` slot ("opens with a pointer"); this script groups
  maximal spans of consecutive `jp` slots only.  The two therefore differ by a
  run at each end -- the tool prints 20 before and 16 after where this prints 19
  and 15, and names one span T_F42E40-T_F42E6C where this names it
  T_F42E44-T_F42E6C.  The four runs the round claims are named identically by
  both and are unaffected; do not quote this script's TOTALS as the tool's.

WHAT IT ASSERTS (non-zero exit if any fails)
    1. the four runs T_F432C0, T_F42B70, T_F42EC0, T_F42ED0 are in BEFORE
    2. none of the four is in AFTER
    3. no OTHER run disappeared -- a round must not be credited with a run some
       other change removed
    4. the four own exactly 69 `jp` slots between them, counted from the thunk
       table's own bytes
    5. every one of those 69 targets is inside 0xF65000-0xF6D001

RUN
  python3 notes/prom_b_f65000_frontier_delta.py
  python3 notes/prom_b_f65000_frontier_delta.py --runs
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
LO, HI = 0xF65000, 0xF6D002
CLAIMED = ["T_F432C0-T_F432CC", "T_F42B70-T_F42C2C",
           "T_F42EC0-T_F42EC8", "T_F42ED0-T_F42F04"]
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
    print("runs with unconverted prom_b targets (THIS script's grouping -- see")
    print("the docstring; notes/prom_b_module_frontier.py reports one more at")
    print("each end): before %d, after %d" % (len(before), len(after)))
    gone = sorted(set(before) - set(after))
    print("runs that disappeared: %s" % ", ".join(gone))
    for r in CLAIMED:
        check("%s is in BEFORE" % r, r in before, True)
        check("%s is NOT in AFTER" % r, r in after, False)
    check("no run disappeared other than the four claimed",
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
    check("the four runs own 69 `jp` slots", n, 69)
    check("every one of the 69 targets is inside 0x%06X-0x%06X" % (LO, HI - 1),
          outside, [])
    print("\n%s (%d failed)" % ("DELTA PASS" if not FAIL else "DELTA FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
