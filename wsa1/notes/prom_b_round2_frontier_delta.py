#!/usr/bin/env python3
"""Did the prom_b frontier fall by exactly what round 2 converted, in BOTH units?

QUESTION IT ANSWERS
    Round 2 converted two spans of prom_b: 0xF5BBE7-0xF62BFF and
    0xF44018-0xF477FF.  The claim in notes/FINDINGS-prom_b-round-maps.md and
    notes/FINDINGS-prom_b-f44018-module.md is that the unconverted-thunk frontier
    fell by exactly the number of slots those spans own, with nothing else moving.
    This re-derives it from the ROM instead of from two printouts taken hours
    apart, and it reports SLOTS and DISTINCT TARGETS separately.

WHY BOTH UNITS
    ⚠ `notes/prom_b_call_graph.py`'s header said "targets" until 2026-08-25 while
    the thing it counted was one row per SLOT.  Two slots can name the same
    routine: 0xF44018-0xF477FF holds 64 slots resolving to 62 distinct targets, so
    a reconciliation done in the wrong unit is off by two with nothing to show
    why.  This tree's own history has "a handler count of 35 that was 34"; the fix
    is to print the unit next to the number, always.

METHOD
    The current `.incbin` ranges are parsed from prom_b/wsa1_prom_b.s.  The state
    BEFORE each conversion is reconstructed by adding that span back to the
    unconverted set -- which is exact, because a converted span is exactly a span
    that is no longer `.incbin`.  Slot classification comes from the committed
    scripts/analysis/prom_b_thunk_table.py.

RUN
    python3 notes/prom_b_round2_frontier_delta.py
Exit status is non-zero if any row fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_thunk_table as TT                                    # noqa: E402

B_BASE = 0xF00000
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
# the two spans this round converted, in the order they were converted
ROUND2 = [("0xF5BBE7-0xF62BFF  the 96-step rounding maps", 0xF5BBE7, 0xF62C00),
          ("0xF44018-0xF477FF  the module after the thunk table", 0xF44018, 0xF47800)]
# ⚠ ADDED 2026-08-25 (round 3).  Spans converted AFTER round 2.  Without this the
# two "NOW" rows below -- 283 slots / 277 targets -- would start FAILING the
# moment a later round converted anything, and a check that breaks on success is
# the opposite of one.  Round 3 converted 0xF47800-0xF4EFFF, so that span is
# added back before the round-2 arithmetic is done, and the rows go on asserting
# the state round 2 actually left behind.  A round 4 adds its own span here.
LATER = [("0xF47800-0xF4EFFF  round 3, the eight modules at 0x047800",
          0xF47800, 0xF4F000)]
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-22s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def incbin_ranges():
    out = []
    for m in re.finditer(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                         open(SRC).read()):
        lo = B_BASE + int(m.group(1), 16)
        out.append((lo, lo + int(m.group(2), 16)))
    return sorted(out)


def frontier(ranges):
    """(slots, distinct targets) whose target is in prom_b and still .incbin."""
    _, b = TT.load()
    slots, tgts = 0, set()
    for o in range(TT.TBL_LO, TT.TBL_HI, 4):
        kind, t = TT.classify(b, o)
        if kind != "jp" or not (B_BASE <= t < 0xF80000):
            continue
        if any(lo <= t < hi for lo, hi in ranges):
            slots += 1
            tgts.add(t)
    return slots, len(tgts)


def owned(lo, hi):
    _, b = TT.load()
    slots, tgts = 0, set()
    for o in range(TT.TBL_LO, TT.TBL_HI, 4):
        kind, t = TT.classify(b, o)
        if kind == "jp" and lo <= t < hi:
            slots += 1
            tgts.add(t)
    return slots, len(tgts)


def main():
    now = sorted(incbin_ranges() + [(lo, hi) for _, lo, hi in LATER])
    s_now, t_now = frontier(now)
    print("prom_b frontier AFTER round 2 (the .s's `.incbin` set with every span"
          " a LATER round converted added back)")
    check("unconverted thunk SLOTS", s_now, 283)
    check("unconverted DISTINCT TARGETS", t_now, 277)
    print()
    state = list(now)
    tot_s, tot_t = 0, 0
    for name, lo, hi in reversed(ROUND2):
        os_, ot_ = owned(lo, hi)
        state = sorted(state + [(lo, hi)])
        s, t = frontier(state)
        print("undo %s" % name)
        # ⚠ the first draft had a third row here that compared os_ with os_ in one
        #    of its branches -- a check that cannot fail.  Removed: the two rows
        #    below are the real test, because their left-hand sides are computed
        #    from the RECONSTRUCTED .incbin set and their right-hand sides from
        #    the thunk table, by two different code paths.
        check("  slots the frontier gains back", s - (s_now + tot_s), os_)
        check("  distinct targets it gains back", t - (t_now + tot_t), ot_)
        tot_s += os_
        tot_t += ot_
    s_before, t_before = frontier(state)
    print()
    print("prom_b frontier BEFORE round 2")
    check("slots", s_before, 364)
    check("distinct targets", t_before, 356)
    check("slots retired this round", s_before - s_now, 81)
    check("distinct targets retired this round", t_before - t_now, 79)
    check("...and 81 slots is 17 + 64, the two spans' own slot counts",
          [owned(lo, hi)[0] for _, lo, hi in ROUND2], [17, 64])
    check("...while 79 targets is 17 + 62 -- the units differ by 2",
          [owned(lo, hi)[1] for _, lo, hi in ROUND2], [17, 62])
    print("\n%s (%d failed)" % ("PASS" if not FAIL else "FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
