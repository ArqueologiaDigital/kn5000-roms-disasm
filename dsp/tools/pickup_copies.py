#!/usr/bin/env python3
"""pickup_copies.py -- does the body entry deliver ONE copy of the input, or several?

QUESTION IT ANSWERS
    Every criterion this project had used for the effect body was a SELF-CONSISTENCY measure:
    "do two consecutive frames differ" (liveness), "does the phase advance by its increment".
    Neither asks whether the number arriving is the RIGHT number, and N-INPUT-GATE-OPENED §27
    showed why that matters -- a body entry that counts the same input three times is very much
    alive, and very much wrong.

    The HLE supplies the missing criterion, and it is the simplest one in the project:

        the parametric EQ's input is ONE copy of the pickup.  Not 1.6 of them, not three.

    So: read the bus datum the body entry takes (`iw84`'s operand latch) and the pickup cell the
    band chain reads (`0x10`), and divide.  **1.0 is correct; anything else is a decode error in
    the entry sequence, however live the body looks.**

    MEASURED 2026-09-12 across seven configurations of the two-sided gate:

        UPD6383_CALLFLUSH=1   ratio 0.999     <- the ONLY one that is right
        baseline / CALLACC    ratio 1.589
        SPEC bit 55 / triple  RAILED at 0x7FFFFF
        PCLR / SPEC bit 12    no input at all

    ⇒ the configuration §20 recorded as "starving the EQ" is the one delivering a clean input, and
    the 39-of-44-cells liveness of the baseline was counting CONTAMINATION as life.  See §29.

USAGE
    python3 dsp/tools/pickup_copies.py eq_capture.log [more.log ...] [--entry 84] [--cell 0x10]

    Captures come from dsp/tools/pair_gate.sh (its `pg_<tag>_eq.log').  The ratio is only
    meaningful on the PARAMETRIC EQ (TYPEIDX 15), whose entry sequence is the one decoded here.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dlyseed_confront import parse, s24   # noqa: E402

RAIL = 0x7fffff


def measure(path, entry_iw, cell):
    rows = [r for r in parse(path) if r["u1"] == 0]
    bus = cellv = acc = None
    for r in rows:
        if r["iw"] == entry_iw and bus is None:
            bus = r["l"]
        if r["dp"] == cell and cellv is None:
            cellv = s24(r["mem"])
        if r["iw"] == entry_iw + 4 and acc is None:
            acc = r["acc"]
    return bus, cellv, acc


def main():
    argv = sys.argv[1:]
    logs = []
    skip = False
    for a in argv:
        if skip:
            skip = False
            continue
        if a in ("--entry", "--cell"):
            skip = True
        elif not a.startswith("--"):
            logs.append(a)
    entry = int(argv[argv.index("--entry") + 1]) if "--entry" in argv else 84
    cell = int(argv[argv.index("--cell") + 1], 0) if "--cell" in argv else 0x10
    if not logs:
        print(__doc__)
        return 2

    #  ★ WHICH CELL?  Do not hard-code one.  `iw88's ACT-0x07 store lands on the PRE-increment
    #  pointer (0x10) or the POST-increment pointer (0x50) depending on §109's mask bit 28, and
    #  the EQ's five bands each own a 4-cell state block at 0x50 / 0x54 / 0x58 / 0x5C / 0x60.
    #  Asking only about 0x10 made the correct configuration report "0.000 copies" -- the tool
    #  was measuring the cell the store no longer targets.  So check the candidates and name the
    #  one that holds the input; a correct entry puts ONE copy in the cells the bands READ.
    cands = [cell] + [c for c in (0x10, 0x50, 0x54, 0x58, 0x5C, 0x60) if c != cell]
    print("body entry at iw%d -- the HLE says ONE copy of the input must reach the band's cell\n" % entry)
    print("%-30s %12s  %s" % ("capture", "bus datum", "cells holding exactly one copy"))
    bad = 0
    for p in logs:
        name = os.path.basename(p)[:30]
        bus = measure(p, entry, cands[0])[0]
        if not bus:
            print("%-30s %12s  ⛔ NO INPUT on the bus at all" % (name, bus))
            bad += 1
            continue
        hits, railed, others = [], [], []
        for c in cands:
            _b, cellv, _a = measure(p, entry, c)
            if cellv is None:
                continue
            if abs(cellv) >= RAIL:
                railed.append(c)
            elif abs(cellv / bus - 1.0) <= 0.01:
                hits.append(c)
            elif cellv:
                others.append((c, cellv / bus))
        if hits:
            note = "✅ ONE COPY at " + ", ".join("0x%02X" % c for c in hits)
        else:
            bad += 1
            note = "⛔ none. "
            if railed:
                note += "RAILED at " + ", ".join("0x%02X" % c for c in railed) + ". "
            if others:
                note += "ratios " + ", ".join("0x%02X=%.3f" % (c, r) for c, r in others[:4])
        print("%-30s %12d  %s" % (name, bus, note))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
