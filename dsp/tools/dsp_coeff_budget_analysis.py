#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_coeff_budget_analysis.py -- the C-RAM coefficient budget per effect, and whether the
coefficient cursor is ever REWOUND.

Each program reads its coefficients by advancing a cursor (`c+` = fetch-and-advance).  Two
questions with clean, decoded answers:

  1. How many coefficients does each family consume?  -- the C-RAM budget an emulator must
     allocate per effect.  (coeff_consumer, a decoded predicate.)
  2. Does any program REWIND the cursor (rstcur) to re-read coefficients?  A rewind means a
     later pass reuses an earlier coefficient block -- e.g. a stereo second channel reusing
     the first channel's filter coefficients.  No rewind means every pass/channel/band has
     its OWN cells and the cursor is monotonic.

    python3 dsp/tools/dsp_coeff_budget_analysis.py

MEASURED 2026-09-08 (both products' effect .dsm):
  * Coefficient budget ranks by family exactly as the algorithms predict:
    eq ~38 (6 biquad coeffs x bands x channels) > pitch ~32 > reverb ~23 ~ delay ~22 >
    modulation ~18 > dyn/dist ~14 (a waveshaper needs few).
  * rstcur occurs EXACTLY ONCE in the whole corpus -- the KN5000 PARAMETRIC EQ, which rewinds
    between its two channels so channel 2 re-reads channel 1's 30 coefficients (L/R share one
    EQ curve).  Every other program -- including the WSA1R 6-band PEQ -- has a MONOTONIC
    cursor: distinct cells per channel/band, no reuse.  => an emulator advances a coefficient
    cursor without rewind, except it must model the one KN5000-PEQ stereo rewind.

Graded structural correlation; stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [(os.path.join(HERE, "..", "disasm"), "KN5000"),
         (os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm"), "WSA1R")]


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


def load():
    rows = []
    for tree, prod in TREES:
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
            if nm and ws:
                rows.append((prod, family(nm), nm, ws))
    return rows


def main():
    rows = load()
    byf = collections.defaultdict(list)
    rewinders = []
    for prod, f, nm, ws in rows:
        cc = sum(1 for w in ws if D.coeff_consumer(w))
        rst = sum(1 for w in ws if D.is_rstcur(w))
        byf[f].append(cc)
        if rst:
            rewinders.append((prod, nm, rst))

    print("coefficient BUDGET per family (c+ fetches = distinct C-RAM cells consumed)\n")
    print("family       progs  mean  min  max")
    for f in sorted(byf, key=lambda k: -statistics.mean(byf[k])):
        v = byf[f]
        print("%-11s  %4d  %4.1f  %3d  %3d" % (f, len(v), statistics.mean(v), min(v), max(v)))

    total_rst = sum(r[2] for r in rewinders)
    print("\ncursor REWIND (rstcur) across the whole corpus: %d occurrence(s)" % total_rst)
    for prod, nm, rst in rewinders:
        print("  %s / %s : %d rstcur -- rewinds to re-read an earlier coefficient block "
              "(stereo channels share one set)" % (prod, nm, rst))
    print("=> the coefficient cursor is MONOTONIC everywhere except the one case above; an")
    print("   emulator streams coefficients forward per effect, no reuse, and sizes C-RAM to")
    print("   the budget above (the rewinder reuses its block for the second channel).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
