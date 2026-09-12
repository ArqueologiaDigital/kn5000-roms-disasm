#!/usr/bin/env python3
"""entry_erasure_census.py -- is the EQ's "input arrives then is thrown away" shape a one-off?

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §23 MEASURED, on the parametric EQ, that the body's entry puts the live
    input into the accumulator (an `ACT 0x00', `f31 = 1' word, whose bus term is the pickup) and
    then two words later a word with `f31 = 0' that fetches NO COEFFICIENT loads the accumulator
    from the product register -- discarding it.  Before treating that as the shape of the chip's
    rule it has to be asked of the whole corpus: is it the EQ's quirk, or the body-entry idiom?

    This scans the first eight words of every effect body for

        an `ACT 0x00 / f31 = 1' word   (the bus-add that puts the input in the accumulator)
        followed within three words by
        an `f31 = 0' word that fetches no coefficient   (LOAD from a product nothing produced)

    MEASURED 2026-09-12: **18 of 38** distinct body images carry it, including the reference
    program.  So the decode of that one situation reaches about half the catalogue.

    ⚠ WHAT IT DOES NOT SAY.  The shape is in the BYTECODE; calling it an "erasure" is a statement
    about the DEVICE, which has no fresh product there.  On the chip the pipeline may well have
    one.  The census sizes the question; it does not answer it.

USAGE
    python3 dsp/tools/entry_erasure_census.py [dsp/disasm/prog*.dsm]
"""
import glob
import os
import re
import sys

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")
WINDOW = 8          # body-entry words scanned
REACH = 3           # how far after the bus-add the LOAD may sit


def fields(w):
    hi12 = (w >> 24) & 0xfff
    lo = w & 0xfff
    return hi12, (hi12 >> 1) & 7, (w >> 20) & 0xf, (lo >> 6) & 0x1f, lo & 0x1f


def coeff_fetch(w):
    hi12 = (w >> 24) & 0xfff
    return bool((w >> 20) & 8) and (hi12 & 0xf00) != 0xc00


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "prog*.dsm")))
    hit, miss = [], []
    for f in files:
        ws = []
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                ws.append((int(m.group(1)), int(m.group(2), 16)))
        ws.sort()
        head = [w for _, w in ws[:WINDOW]]
        found = None
        for i, w in enumerate(head):
            _hi, f31, _cls, _src, act = fields(w)
            if act != 0x00 or f31 != 1:
                continue
            for j in range(i + 1, min(i + 1 + REACH, len(head))):
                _h2, f2, _c2, _s2, _a2 = fields(head[j])
                if f2 == 0 and not coeff_fetch(head[j]):
                    found = (i, j, "%010X" % w, "%010X" % head[j])
                    break
            if found:
                break
        (hit if found else miss).append((os.path.basename(f), found))

    tot = len(hit) + len(miss)
    print("body-entry shape: 'ACT 0x00 f31=1 (input -> acc) then f31=0 no-coefficient LOAD'")
    print("  scanned %d body images, first %d words, reach %d" % (tot, WINDOW, REACH))
    print("  WITH the shape   : %d of %d" % (len(hit), tot))
    for n, f in hit:
        print("     %-40s w%-2d %s  ->  w%-2d %s" % (n, f[0], f[2], f[1], f[3]))
    print("  without          : %d" % len(miss))
    for n, _ in miss:
        print("     %s" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
