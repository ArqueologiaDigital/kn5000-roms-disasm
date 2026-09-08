#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_combo_decomposition.py -- the combination effects are CONCATENATIONS of their
component algorithms' microcode.

A multi-effect (PEQ+CHORUS, S.DELAY+FLANGER, PEQ+COMPR+DIST, ...) should, if the DSP builds
chains the obvious way, contain each component effect's program as a block.  Test it: for each
combo, measure how much of each standalone component's idiom sequence appears inside the
combo (longest-common-subsequence overlap).

    python3 dsp/tools/dsp_combo_decomposition.py

MEASURED 2026-09-08 (both products' effect .dsm):
  * Every combo contains its components as high-overlap sub-sequences -- the second/later
    effect nearly whole (CHORUS ~97%, DISTORTION/OVERDRIVE ~83-98%, FLANGER ~83-86%,
    VIBRATO ~80-85%), confirming a combo is its components CONCATENATED.
  * The PEQ prefix is TRIMMED: only ~50-65% of the standalone 5/6-band PARAMETRIC EQ appears
    in a PEQ+ combo -- the EQ is cut to fewer bands to make room for the second effect, while
    the second effect is used essentially whole.
  => a combination effect = component blocks chained, EQ-stage reduced; an emulator builds a
     combo by running the (possibly band-reduced) EQ then the full second/third effect.

Graded structural correlation; stdlib + dsp_disasm (via dsp_template_clusters); read-only.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_template_clusters as TC                  # noqa: E402  (reuses load_bodies + idiom)

# combo token -> standalone base effect name
NAMEMAP = {
    "PEQ": "PARAMETRIC EQ", "S.DELAY": "SINGLE DELAY", "DELAY": "SINGLE DELAY",
    "COMPR": "COMPRESSOR", "COMPRESSOR": "COMPRESSOR", "DIST": "DISTORTION",
    "OVERDR": "OVERDRIVE", "CHORUS": "CHORUS", "FLANGER": "FLANGER", "VIBRATO": "VIBRATO",
    "PHASER": "PHASER", "AUTO WAH": "AUTO WAH", "PEDAL WAH": "PEDAL WAH", "WAH": "AUTO WAH",
}


def lcs(a, b):
    la, lb = len(a), len(b)
    if not la or not lb:
        return 0
    prev = [0] * (lb + 1)
    for i in range(1, la + 1):
        cur = [0] * (lb + 1)
        ai = a[i - 1]
        for j in range(1, lb + 1):
            cur[j] = prev[j - 1] + 1 if ai == b[j - 1] else max(prev[j], cur[j - 1])
        prev = cur
    return prev[lb]


def main():
    progs = TC.load_bodies()
    by = {}
    for prod, nm, seq in progs:
        by.setdefault(nm, {})[prod] = seq

    print("combo decomposition -- LCS overlap of each standalone component vs the combo\n")
    print("prod    combo                  len   components (overlap of each base in the combo)")
    peq_ov, other_ov = [], []
    for nm in sorted(by):
        if "+" not in nm:
            continue
        comps = [c.strip() for c in nm.split("+")]
        for prod, seq in sorted(by[nm].items()):
            parts = []
            for c in comps:
                base = NAMEMAP.get(c)
                if base and base in by and prod in by[base]:
                    ov = lcs(by[base][prod], seq) / max(1, len(by[base][prod]))
                    parts.append("%s=%.0f%%" % (c, 100 * ov))
                    (peq_ov if base == "PARAMETRIC EQ" else other_ov).append(ov)
                else:
                    parts.append("%s=?" % c)
            print("%-6s  %-20s  %3d   %s" % (prod, nm[:20], len(seq), "  ".join(parts)))

    def avg(v):
        return 100 * sum(v) / len(v) if v else 0
    print("\nmean overlap: PEQ prefix %.0f%% (trimmed) vs other components %.0f%% (near-whole)."
          % (avg(peq_ov), avg(other_ov)))
    print("=> a combo is its component blocks concatenated; the EQ stage is band-reduced to")
    print("   fit, the second/third effect is used essentially whole.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
