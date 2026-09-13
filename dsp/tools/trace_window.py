#!/usr/bin/env python3
"""trace_window.py -- print a window of the device's TIME-ORDERED FRAME TRACE, with the deltas.

QUESTION IT ANSWERS
    "What did these instructions actually do to the accumulator?"  The trace banner prints one row
    per executed slot; reading a handful of them by eye is how most of this session's misreadings
    started.  This slices the window, keeps the rows in EXECUTION order (`n', not `iw' -- the frame
    runs iw0..49, then the body iw84.., then iw50..81, so sorting by `iw' scrambles it), and prints
    the accumulator DELTA beside each row so "what did this word add?" is answered by the tool
    rather than by mental arithmetic.

USAGE
    python3 dsp/tools/trace_window.py <error.log> <iw-from> <iw-to> [--unit 0|1] [--n-from N]

    e.g. the parametric EQ's body entry, which is `w0..w5' of the image at I-RAM base 84:
        python3 dsp/tools/trace_window.py reverted/t15_F.log 84 95

⚠ The `acc' column is the value AFTER the row executed, so the delta printed on a row is what THAT
  row did.  `LW' is §29's operand-latch-write flag: `W' means this word drove the operand latch.
"""
import re
import sys

# n  iw u1  word  dp mem  acc  accb  P  cur coef  tA  tB  MUL  L LW
ROW = re.compile(r"upd6383:\s+(\d+)\s+(\d+)\s+([01])\s+([0-9A-F]{10})\s+([0-9A-F]{2})\s+"
                 r"([0-9A-F]{6})\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+([0-9A-F]{2})\s+"
                 r"([0-9A-F]{6})\s+([0-9A-F]{6})\s+([0-9A-F]{6})\s+(\S)\s+(-?\d+)\s+(\S)")


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    log, lo, hi = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    unit = None
    nfrom = 0
    if "--unit" in sys.argv:
        unit = sys.argv[sys.argv.index("--unit") + 1]
    if "--n-from" in sys.argv:
        nfrom = int(sys.argv[sys.argv.index("--n-from") + 1])

    rows = []
    started = False
    for ln in open(log, errors="replace"):
        if "TIME-ORDERED FRAME TRACE" in ln:
            started = True
            continue
        if not started:
            continue
        m = ROW.search(ln)
        if m:
            rows.append(m.groups())
    if not rows:
        print("no trace rows in %s -- was UPD6383_TRACE_FRAME set?" % log)
        return 1

    print("=== %s : iw %d..%d (%d trace rows total) ===" % (log, lo, hi, len(rows)))
    print("    n  iw u1 word        dp mem     acc                 delta(acc)          "
          "P                   coef   L        LW")
    prev = None
    for g in rows:
        n, iw, u1, word, dp, mem, acc, accb, p, cur, coef, ta, tb, mul, ll, lw = g
        if prev is not None and lo <= int(iw) <= hi and int(n) >= nfrom \
                and (unit is None or u1 == unit):
            print("  %4s %3s  %s %s %s %s  %19s %19s %19s %s %8s %s"
                  % (n, iw, u1, word, dp, mem, acc, int(acc) - prev, p, coef, ll, lw))
        prev = int(acc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
