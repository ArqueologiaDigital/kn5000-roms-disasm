#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_pointer_stride_analysis.py -- decode the class-2 addr8 as the SIGNED scratch-pointer
stride, and correlate its distribution with the effect algorithm.

Every class-2 (route/store/pointer-move) word carries a signed post-increment in addr8
(dsp_disasm: `dd = ad-256 if ad>=128 else ad`) -- the move of the internal scratch/state
pointer `p`.  (The EXTERNAL delay-DRAM taps live in the descriptor, not here; these strides
are the ON-CHIP state/scratch geometry.)  Histogramming the strides by effect family turns
an already-decoded field into an algorithm discriminator:

  * stride  0        -- same-cell accumulate / store-back (by far the most common)
  * stride +-1, +-2  -- the biquad two-state (z^-1 / z^-2) move
  * |stride| > 2     -- REACH-BACK into scratch: an on-chip short delay / all-pass / comb
                        state, or a multi-tap read.  The count and spread of these
                        distinguishes a state-machine filter (EQ) from a delay network.

    python3 dsp/tools/dsp_pointer_stride_analysis.py

MEASURED 2026-09-08 (both products' committed effect .dsm):
  * Global: stride 0 = 2248, +1 = 614, -1 = 365 (same-cell + biquad-state dominate).
  * EQ is STATE-BOUND: ~75% of its strides are |dd|<=2 (biquad z-state); few reach-backs.
  * REVERB / DELAY / MODULATION carry a large REACH-BACK fraction (~40-47%) -- on-chip
    delay-line access -- and MODULATION has the widest spread of distinct reach strides
    (LFO-swept taps read at many offsets).
  => the scratch-pointer stride pattern is a family fingerprint of the on-chip state/delay
     geometry, complementary to the DRAM-tap topology (which is descriptor-borne).

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


def stride(w):
    a = D.addr8(w)
    return a - 256 if a >= 128 else a


def load():
    progs = []
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
            if nm and ws:
                progs.append((family(nm), ws))
    return progs


def strides_of(ws):
    return [stride(w) for w in ws if not D.c_format(w) and (D.class4(w) & 7) == 2]


def main():
    progs = load()
    glob_hist = collections.Counter()
    for _, ws in progs:
        glob_hist.update(strides_of(ws))
    print("class-2 scratch-pointer stride (signed addr8), most common globally:")
    for v, c in glob_hist.most_common(8):
        tag = ("same-cell" if v == 0 else "biquad-state" if abs(v) <= 2 else "reach-back")
        print("   %+4d : %-5d  (%s)" % (v, c, tag))

    print("\nfamily      strides  same0%  state(|d|<=2)%  reach(|d|>2)%  #distinct-reach")
    for fam in ("eq", "reverb", "delay", "modulation", "dyn/dist", "pitch", "other"):
        alls = [s for f, ws in progs if f == fam for s in strides_of(ws)]
        if not alls:
            continue
        n = len(alls)
        z = sum(1 for s in alls if s == 0)
        st = sum(1 for s in alls if abs(s) <= 2)
        rb = [s for s in alls if abs(s) > 2]
        print("%-11s %6d   %4.0f    %5.0f          %5.0f          %d"
              % (fam, n, 100.0 * z / n, 100.0 * st / n, 100.0 * len(rb) / n,
                 len(set(rb))))

    print("\nReading: EQ is state-bound (biquad z-state); reverb/delay/modulation reach back")
    print("into on-chip scratch (short delay / all-pass / comb state); modulation's reach is")
    print("the most varied (LFO-swept tap offsets). External DRAM taps are descriptor-borne")
    print("and NOT counted here -- this is the ON-CHIP state/delay geometry.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
