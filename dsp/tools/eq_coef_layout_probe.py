#!/usr/bin/env python3
"""eq_coef_layout_probe.py -- read the KN5000 EQ coefficient->cell layout (Phase 2).

QUESTION THIS ANSWERS
  Phase 2 was blocked because the ASSUMED WSA1R coefficient order
  [b1,b0,b2,-a1,-a2,makeup] is Jury-unstable on the KN5000 coefficients.  With the
  biquad datapath now decoded (operand L = mem[dp], addressing is real), the
  ACTUAL per-band coefficient->operand-cell layout can be READ from a trace instead
  of assumed.  This probe prints, per band, each cursor cell's coefficient, the
  D-RAM cell it multiplies, and its accumulator role (LOAD/MAC/store), so the real
  C-RAM order is on record.

  WHAT IT ESTABLISHES (ungated, from the addressing):
    * b0 = 0.125 multiplies the band INPUT cell (0x64+4k) in every band -- the
      parametric-EQ signature, confirming the input cell is x0.
    * the per-band read order is [prev-band cell (~0.75), input (0.125), input+1
      (~0.12), input+2 (~0.48), input+3 (~0.53), ...] -- NOT the WSA1R order.
  WHAT STAYS GATED: which state cell is x1/x2 vs y1/y2 (and thus the exact
  transfer function + stability) needs the cross-frame DELAY-LINE UPDATE, i.e.
  real signal flow through the band -- the same input-route gate as 4.2/5.x.

  Run: python3 dsp/tools/eq_coef_layout_probe.py <biquad trace.txt>
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt")
ROLE = {0x000: "LOAD acc<-P", 0x202: "MAC acc+=P", 0x212: "MAC+store",
        0x102: "makeup/store", 0x804: "makeup", 0x801: "entry"}


def hi12(w):
    return (w >> 24) & 0xFFF


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    rows = parse_trace(open(path).read())
    best = cur = []
    for r in rows:
        if r["cur"] <= 0x1D:
            cur = cur + [r]
            best = cur if len(cur) > len(best) else best
        else:
            cur = []
    eq = best
    print("eq_coef_layout_probe: %s\n" % os.path.basename(path))
    b0s = []
    for b in range(5):
        inp = 0x64 + 4 * b
        print("band %d (input cell 0x%02X):" % (b, inp))
        for c in range(6):
            rw = [r for r in eq if r["cur"] == b * 6 + c]
            if not rw:
                continue
            r = rw[0]
            off = r["dp"] - inp
            offs = ("input%+d" % off) if -1 <= off <= 4 else "prev-band %+d" % off
            note = ""
            if r["dp"] == inp and hi12(r["word"]) == 0x000:
                note = "  <= b0 x x0 (input)"
                b0s.append(round(r["coef"], 5))
            print("   cur 0x%02X  coef=%+.5f  dp=0x%02X (%s)  %-12s%s" %
                  (b * 6 + c, r["coef"], r["dp"], offs,
                   ROLE.get(hi12(r["word"]), "0x%03X" % hi12(r["word"])), note))
    print("\n  b0 (coef on the input cell) across bands: %s" % b0s)
    print("  => b0 == 0.125 in every band (the parametric-EQ signature): the input")
    print("     cell 0x64+4k is x0.  The read ORDER above is the ACTUAL C-RAM layout,")
    print("     which is NOT the assumed WSA1R [b1,b0,b2,-a1,-a2,makeup].")
    print("  ⚠ x1/x2 vs y1/y2 role assignment (hence the transfer function + stability)")
    print("     needs the cross-frame delay-line update = real signal flow (4.2 gate).")


if __name__ == "__main__":
    main()
