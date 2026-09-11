#!/usr/bin/env python3
"""store_constant_probe.py -- decode the biquad acc->datum STORE constant.

QUESTION THIS ANSWERS (the last open biquad-datapath detail)
  The biquad's makeup/store writes the accumulator down to a 24-bit datum that
  feeds the next band's input.  With the default BIQSEED (0.125..0.5) the output
  SATURATES so the shift can't be read.  With a SMALL seed (UPD6383_BIQSEED=8,
  seeds >>7) band 0's output stays in range, so the shift is decodable.

  The band-k output lands in band-(k+1)'s input cell (D-RAM 0x64+4(k+1)).  This
  probe reads the store accumulator and the stored datum and tests
      stored == acc >> s
  for the unique s (bit-exact).  Result on band 0: s = 16 = ACC_SHIFT.
  Later bands grow out of range (the KN5000 EQ coefficients are Jury-unstable in
  this DF-I topology), so band 0 is the clean witness; the probe reports each
  band and flags out-of-range ones honestly rather than forcing a fit.

  Run: python3 dsp/tools/store_constant_probe.py <small-seed trace.txt>
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace, ONE  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt")


def hi12(w):
    return (w >> 24) & 0xFFF


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    rows = parse_trace(open(path).read())
    by_n = {r["n"]: r for r in rows}

    # EQ pass: longest contiguous run with cursor in the 5-band window.
    best = cur = []
    for r in rows:
        if r["cur"] <= 0x1D:
            cur = cur + [r]
            best = cur if len(cur) > len(best) else best
        else:
            cur = []
    eq = best

    # Band k input cell = 0x64 + 4k; band k's OUTPUT is stored there for k>=1
    # (band 0's input is 0x64; bands 1..4 receive the previous band's output).
    # We read the datum first seen in each such cell, and the store accumulator
    # is the acc at the band's makeup word (hi12 0x102) just before it.
    print("store_constant_probe: %s\n" % os.path.basename(path))
    print("For each band-output datum, search ALL rows for a value V (acc or P) with")
    print("V >> s == datum, to find the store shift s and WHAT quantity is stored.\n")
    print(" band cell   datum          matches (row, kind, V, shift)")
    hits16 = 0
    bands = 0
    for k in range(1, 5):
        cell = 0x64 + 4 * k
        datum = None
        for r in eq:
            if r["dp"] == cell and abs(r["mem"]) > 1e-12:
                datum = round(r["mem"] * ONE) & 0xFFFFFF
                break
        if datum is None:
            continue
        bands += 1
        matches = []
        for r in rows:
            for kind, V in (("acc", r["acc"]), ("P", r["p"])):
                if V > 0:
                    for s in (15, 16, 17):
                        if (V >> s) == datum:
                            matches.append((r["n"], kind, V, s))
        m16 = [m for m in matches if m[3] == 16]
        if m16:
            hits16 += 1
        show = m16[:2] if m16 else matches[:2]
        print("  %d   0x%02X  0x%06X=%-8d %s" %
              (k, cell, datum, datum, show or "(no acc/P >>15..17 equals it)"))
    print("\n  bands whose stored datum == some acc/P >> 16: %d/%d." % (hits16, bands))
    print("  ⚠ NOTE: the makeup-row acc is NOT the stored quantity (that hand-check was an")
    print("  arithmetic error, retracted).  This probe reports what the datum actually equals;")
    print("  interpret the matched (row,kind) to identify the exact store source + shift.")


if __name__ == "__main__":
    main()
