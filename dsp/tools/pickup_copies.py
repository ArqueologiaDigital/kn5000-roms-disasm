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

    print("body entry at iw%d, pickup cell 0x%02X -- the HLE says the ratio must be 1.0\n" % (entry, cell))
    print("%-34s %12s %12s %16s %8s  %s" % ("capture", "bus datum", "cell", "acc @ store", "ratio", "verdict"))
    bad = 0
    for p in logs:
        bus, cellv, acc = measure(p, entry, cell)
        name = os.path.basename(p)[:34]
        if not bus:
            print("%-34s %12s %12s %16s %8s  ⛔ NO INPUT on the bus at all"
                  % (name, bus, cellv, acc, "-"))
            bad += 1
            continue
        ratio = cellv / bus
        if cellv is not None and abs(cellv) >= RAIL:
            verdict = "⛔ RAILED -- the entry oversums the input"
            bad += 1
        elif abs(ratio - 1.0) <= 0.01:
            verdict = "✅ ONE COPY"
        else:
            verdict = "⛔ %.3f copies -- the entry is not delivering the input" % ratio
            bad += 1
        print("%-34s %12d %12d %16d %8.3f  %s" % (name, bus, cellv, acc, ratio, verdict))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
