#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_coeff_run_analysis.py -- the LENGTH of each consecutive coefficient run decodes the
filter-section structure, and cross-validates the biquad (sect. 7) and reverb (sect. 5) reads.

Coefficients are read by advancing a cursor (`c+`).  A maximal run of consecutive `c+` words
is one filter section reading its coefficient block, so the run LENGTH names the section:

  run 5 (or 6)  -- a Direct-Form-I biquad section: b1,b0,b2,-a1,-a2 (+ makeup) read in a row.
  run 3-4       -- a reverb comb+damp stage: feedback gain + a short damping filter.
  run 1         -- a single coefficient: one delay-tap gain, one mix/level, one LFO depth.

Because a DF-I section also opens with `ld.ta` (sect. 7), the count of run-5 blocks should
match the count of `ld.ta` section-entries -- an independent cross-check.

    python3 dsp/tools/dsp_coeff_run_analysis.py

MEASURED 2026-09-08 (both products' effect .dsm):
  * eq: 78 run-5 blocks (the DF-I biquad sections) -- ~matches its ~80 ld.ta entries (sect. 7).
  * reverb: run-3/4 blocks dominate its multi-coeff runs (comb+damp stages, sect. 5).
  * delay / modulation: overwhelmingly run-1 (single-coefficient taps and gains).
  * dyn/dist: a few run-5/6 blocks = the OVERDRIVE / EXCITER post tone biquads (sect. 7d).

Graded structural correlation; stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]


def family(n):
    n = n.upper()
    if "EQ" in n:                                              return "eq"
    if any(k in n for k in ("REVERB", "HAAS", "GATED")):      return "reverb"
    if "DELAY" in n:                                          return "delay"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "VIBRATO",
                            "ENSEMBLE", "PAN", "RING", "ROTARY", "MIX")): return "modulation"
    if any(k in n for k in ("DIST", "FUZZ", "OVERDR", "EXCITER",
                            "WAH", "COMPRESS")):                return "dyn/dist"
    if "PITCH" in n:                                          return "pitch"
    return "other"


def runs_of(ws):
    out, run = [], 0
    for w in ws:
        if D.coeff_consumer(w):
            run += 1
        else:
            if run:
                out.append(run)
            run = 0
    if run:
        out.append(run)
    return out


def main():
    byfam = collections.defaultdict(collections.Counter)
    ld_ta = collections.Counter()
    for tree in TREES:
        for p in sorted(glob.glob(os.path.join(tree, "*.dsm"))):
            b = os.path.basename(p)
            if not b.startswith(("prog", "eff")):
                continue
            nm, ws = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    nm = m.group(1)
                m = WORD.match(ln)
                if m:
                    ws.append(int(m.group(1), 16))
            if not (nm and ws):
                continue
            f = family(nm)
            for r in runs_of(ws):
                byfam[f][r] += 1
            ld_ta[f] += sum(1 for w in ws if D.lo_act(w) == 0x13)

    print("coefficient-RUN length histogram per family (consecutive c+ fetches)\n")
    print("family       run1  run2  run3  run4  run5  run6+   | biquad(run5/6)  ld.ta(sect.7)")
    for f in ("eq", "reverb", "delay", "modulation", "dyn/dist", "pitch", "other"):
        h = byfam[f]
        if not sum(h.values()):
            continue
        r6 = sum(v for k, v in h.items() if k >= 6)
        biq = h.get(5, 0) + r6
        print("%-11s  %4d  %4d  %4d  %4d  %4d  %4d    | %6d          %6d"
              % (f, h.get(1, 0), h.get(2, 0), h.get(3, 0), h.get(4, 0), h.get(5, 0), r6,
                 biq, ld_ta[f]))

    print("\nreading: run-5/6 = Direct-Form-I biquad sections (eq, and the OD/exciter tone")
    print("filters in dyn/dist) -- the run-5 count tracks the ld.ta section-entry count (sect.7);")
    print("run-3/4 = reverb comb+damp stages (sect.5); run-1 = single tap/gain (delay/mod).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
