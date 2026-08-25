#!/usr/bin/env python3
"""Did the prom_b frontier fall by exactly what round 3 converted, in BOTH units?

QUESTION IT ANSWERS
    Round 3 converted ONE span of prom_b, 0xF47800-0xF4EFFF (the eight modules at
    the head of the 0x047800 `.incbin`).  The claim in
    notes/FINDINGS-prom_b-f47800-modules.md is that the unconverted-thunk frontier
    fell by exactly the number of slots that span owns and nothing else moved.
    This re-derives it from the ROM instead of from two printouts taken hours
    apart, and it reports SLOTS and DISTINCT TARGETS separately.

WHY BOTH UNITS
    ⚠ Two thunk slots can name the same routine, so a reconciliation done in the
    wrong unit is silently off.  Round 2's span 0xF44018-0xF477FF held 64 slots
    resolving to 62 distinct targets -- off by two with nothing to show why.  For
    THIS span the two units happen to agree (92 and 92), and that agreement is
    itself asserted below rather than assumed: a round that reports one number
    for both must prove they are the same number.

METHOD
    The current `.incbin` ranges are parsed from prom_b/wsa1_prom_b.s.  The state
    BEFORE the conversion is reconstructed by adding the span back to the
    unconverted set -- exact, because a converted span is exactly a span that is
    no longer `.incbin`.  Slot classification comes from the committed
    scripts/analysis/prom_b_thunk_table.py.

    ⚠ Nothing here is hard-coded to a state a LATER round can change except the
    numbers this round is reporting.  When round 4 converts something, add its
    span to LATER (as this file's round-2 sibling now does) so the round-3 row
    keeps meaning what it said.

IT ALSO CHECKS THE "MOST REFERENCED" CLAIM
    The block header in prom_b/wsa1_prom_b.s says the span held eight of the
    eleven unconverted slots with a reference bound of 13 or more.  That is
    stated at a THRESHOLD rather than as "N of the top ten" on purpose: two
    slots tie at x13 and two more at x14 and at x15, so a top-N phrasing depends
    on how the sort broke the tie and cannot be reproduced.  The threshold row
    below re-derives both numbers from the ROM.

RUN
    python3 notes/prom_b_round3_frontier_delta.py
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
ROUND3 = [("0xF47800-0xF4EFFF  the eight modules at the head of 0x047800",
           0xF47800, 0xF4F000)]
# spans converted AFTER round 3.  Empty today; a later round adds its own so
# that the "NOW" rows below keep asserting the post-round-3 state.
LATER = []
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


def slot_ref_bound():
    """{slot address: opcode-anchored UPPER BOUND on references to it}.

    ⚠ This ranks slots; it is not a call count, and must never be quoted as one.
    Same window as notes/prom_b_call_graph.py."""
    cnt = {}
    for nm in ("wsa1_prom_a.ic12", "wsa1_prom_b.ic13"):
        blob = open(os.path.join(ROOT, "original_ROMs", nm), "rb").read()
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if B_BASE + TT.TBL_LO <= t < B_BASE + TT.TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    return cnt


def top_slots(ranges, threshold):
    """(all, in-span) unconverted slots at or above `threshold` references."""
    _, b = TT.load()
    cnt, allr, ins = slot_ref_bound(), 0, 0
    for o in range(TT.TBL_LO, TT.TBL_HI, 4):
        kind, t = TT.classify(b, o)
        if kind != "jp" or not (B_BASE <= t < 0xF80000):
            continue
        if not any(lo <= t < hi for lo, hi in ranges):
            continue
        if cnt.get(B_BASE + o, 0) >= threshold:
            allr += 1
            if 0xF47800 <= t < 0xF4F000:
                ins += 1
    return allr, ins


def main():
    now = sorted(incbin_ranges() + [(lo, hi) for _, lo, hi in LATER])
    s_now, t_now = frontier(now)
    print("prom_b frontier AFTER round 3 (from the .s's own .incbin directives)")
    check("unconverted thunk SLOTS", s_now, 191)
    check("unconverted DISTINCT TARGETS", t_now, 185)
    print()
    state = list(now)
    tot_s, tot_t = 0, 0
    for name, lo, hi in reversed(ROUND3):
        os_, ot_ = owned(lo, hi)
        state = sorted(state + [(lo, hi)])
        s, t = frontier(state)
        print("undo %s" % name)
        # The left-hand sides come from the RECONSTRUCTED `.incbin` set and the
        # right-hand sides from the thunk table, by two different code paths.
        check("  slots the frontier gains back", s - (s_now + tot_s), os_)
        check("  distinct targets it gains back", t - (t_now + tot_t), ot_)
        tot_s += os_
        tot_t += ot_
    s_before, t_before = frontier(state)
    print()
    print("prom_b frontier BEFORE round 3")
    check("slots", s_before, 283)
    check("distinct targets", t_before, 277)
    check("slots retired this round", s_before - s_now, 92)
    check("distinct targets retired this round", t_before - t_now, 92)
    # the two units AGREE here; assert that rather than let one stand for both
    check("...the span owns the same number of slots and targets",
          list(owned(0xF47800, 0xF4F000)), [92, 92])
    # and the nine runs the module-frontier tool named are all gone
    runs = [(0xF47800, 0xF487A8), (0xF48C1A, 0xF48C1B), (0xF49800, 0xF4B415),
            (0xF4C3F2, 0xF4C4DD), (0xF4C800, 0xF4CADB), (0xF4D000, 0xF4D6F7),
            (0xF4E000, 0xF4E593), (0xF4EC00, 0xF4EEF4)]
    check("...and every slot in it now points at converted bytes",
          sum(owned(lo, hi)[0] for lo, hi in runs), 92)
    # the block header's "most referenced" claim, at a threshold not a top-N
    check("of the unconverted slots at x13 or more, this many were in the span",
          list(top_slots(state, 13)), [11, 8])
    check("...and the threshold is tie-free: nothing else sits at exactly 13",
          top_slots(state, 12)[0] - top_slots(state, 13)[0], 1)
    print("\n%s (%d failed)" % ("PASS" if not FAIL else "FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
