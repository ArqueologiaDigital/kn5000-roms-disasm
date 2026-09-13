#!/usr/bin/env python3
"""bit5_trace.py -- what do the `hi12 bit 5' words actually DO, in a live frame trace?

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §63-§67 bounded the bit-5 population statically: 172 words, the device
    collapses five distinct `f31' codes into one behaviour, 96 of the sites are BLIND (the next
    instruction discards the only register the word touched) and 41 LIVE sites carry a high code.
    All of that is from the listings.  This is the dynamic half: take a capture and report, for
    every bit-5 word the trace actually executed,

        * the accumulator DELTA it produced -- what the collapsed reading currently computes
        * whether the NEXT executed row is an `f31 = 0' LOAD, i.e. whether that delta survives
          (the static successor test, re-done in EXECUTION order rather than address order)
        * the operand `L' and the `LW' latch-write flag beside it

    ⚠ WHY EXECUTION ORDER MATTERS.  The static test in `bit5_words.py' reads the listing in
    ADDRESS order, which is execution order only inside a straight run; a frame runs iw0..49, then
    a body at iw84.., then iw50..81.  This tool uses the trace's own `n' column, so a site the
    static test mis-paired across a control-flow seam is paired correctly here.

USAGE
    python3 dsp/tools/bit5_trace.py <error.log> [more.log ...]

    Each log must carry a TIME-ORDERED FRAME TRACE (UPD6383_TRACE_FRAME set).

⚠ It reports what the CURRENT DEVICE computes at those words, which is the collapsed reading.  It
  is an instrument for aiming an experiment, NOT evidence about the chip: a large delta at a live
  site means the site is GRADEABLE, not that the value is right.
"""
import collections
import os
import re
import sys

ROW = re.compile(r"upd6383:\s+(\d+)\s+(\d+)\s+([01])\s+([0-9A-F]{10})\s+([0-9A-F]{2})\s+"
                 r"([0-9A-F]{6})\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+([0-9A-F]{2})\s+"
                 r"([0-9A-F]{6})\s+([0-9A-F]{6})\s+([0-9A-F]{6})\s+(\S)\s+(-?\d+)\s+(\S)")


def rows(path):
    out, started = [], False
    for ln in open(path, errors="replace"):
        if "TIME-ORDERED FRAME TRACE" in ln:
            started = True
            continue
        if started and (m := ROW.search(ln)):
            g = m.groups()
            out.append(dict(n=int(g[0]), iw=int(g[1]), u1=g[2], word=int(g[3], 16),
                            acc=int(g[6]), p=int(g[8]), L=int(g[14]), lw=g[15]))
    return out


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    tot = blind = live = 0
    for path in sys.argv[1:]:
        tr = rows(path)
        if not tr:
            print("%-26s (no trace rows -- was UPD6383_TRACE_FRAME set?)" % os.path.basename(path))
            continue
        print("\n=== %s : %d executed rows ===" % (os.path.basename(path), len(tr)))
        print("     n  iw  word        f31  delta(acc)            L        LW  successor")
        seen = collections.Counter()
        for k, r in enumerate(tr):
            hi = (r["word"] >> 24) & 0xfff
            if not (hi & 0x20):
                continue
            f31 = (hi >> 1) & 7
            delta = r["acc"] - (tr[k - 1]["acc"] if k else 0)
            nxt = tr[k + 1] if k + 1 < len(tr) else None
            nf = ((nxt["word"] >> 24) & 0xfff) >> 1 & 7 if nxt else None
            #  The successor test, in EXECUTION order: an `f31 == 0' LOAD overwrites the
            #  accumulator outright, so whatever this word put there cannot be observed.
            is_blind = nxt is not None and nf == 0
            tot += 1
            blind += is_blind
            live += (nxt is not None and not is_blind)
            seen[(r["iw"], f31)] += 1
            if seen[(r["iw"], f31)] <= 1:            # one line per site, not per repetition
                print("  %4d %3d  %010X  %d  %19d %8d  %s   %s"
                      % (r["n"], r["iw"], r["word"], f31, delta, r["L"], r["lw"],
                         ("BLIND (next is f31=0 LOAD)" if is_blind
                          else "LIVE  (next f31=%s)" % nf if nxt else "(end of trace)")))
    if tot:
        print("\n⇒ %d bit-5 executions: %d BLIND, %d LIVE.  Aim only at the LIVE ones -- a test at a"
              " blind site returns a false null." % (tot, blind, live))
    else:
        print("\n⇒ NO bit-5 word executed in these captures.  ⚠ That is itself a result: the "
              "program's bit-5 words are in a part of the image the frame never reaches, and no "
              "experiment aimed at them could be graded here either.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
