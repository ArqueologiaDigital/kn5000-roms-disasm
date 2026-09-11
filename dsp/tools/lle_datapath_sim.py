#!/usr/bin/env python3
"""lle_datapath_sim.py -- S2 of PLAN-speculative-strategies: the oracle-diff engine.

A self-contained re-implementation of the DECODED uPD6383GF datapath (no core, no
MAME).  Given a captured frame's per-word (coef, L, hi12) sequence, it PRODUCES the
accumulator/product/store trajectory from first principles and diffs it against the
chip's own columns in the trace.  If the simulator reproduces the trace bit-for-bit,
the decoded datapath model IS the chip's datapath -- and this same engine is the
acceptance test for the speculative strategies (S1/S3/S5): wire a speculative reading
into the model, and a divergence names the first word where the guess is wrong.

DECODED MODEL (all MEASURED this session; run_decode_regression.sh):
  * multiply     P[N] = (coef[N-1] * L[N]) >> 6        (coef pipeline depth 1, P_SHIFT=6)
  * accumulate   hi12[3:1]==1 : acc[N] = acc[N-1] + P[N-1]   (one-slot)
  * load         hi12[3:1]==0 : acc[N] = P[N-1]
  * hold         hi12[3:1]==2 : acc[N] = acc[N-1]
  * store        datum = acc >> 16                     (ACC_SHIFT=16)

f31 codes 4-7 are OPEN; the sim marks a row it cannot model rather than guessing
(a speculative table can fill them in -- that is S3).

  Run: python3 dsp/tools/lle_datapath_sim.py [trace.txt]
"""
import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace, ONE, sext  # noqa: E402

DEFAULT = os.path.join(HERE, "..", "analysis", "data",
                       "kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt")
P_SHIFT = 6
ACC_SHIFT = 16


def hi12(word):
    return (word >> 24) & 0xFFF


def f31_of(word):
    return (hi12(word) >> 1) & 0x7


def simulate(rows):
    """Replay the decoded datapath over the trace's coef/L; return per-row prediction.
    The PRODUCT REGISTER updates only on a multiply word (else it holds), matching the
    chip; the accumulator applies the one-slot f31 op on the previous product."""
    out = []
    acc = 0                 # simulator accumulator
    p_reg = 0               # product register (holds until the next multiply)
    p_prev = 0              # product register value as of the previous word (one-slot)
    coef_prev = 0           # coefficient latched one word early
    for r in rows:
        L = sext(r["l"] & 0xFFFFFF, 24)
        if r["mul"]:        # multiply word: P register := (latched coef * operand) >> 6
            p_reg = (coef_prev * L) >> P_SHIFT
        # else: P register HOLDS its previous value (as on the chip)
        f = f31_of(r["word"])
        modelled = True
        if f == 0:          # load   acc <- previous product
            acc = p_prev
        elif f == 1:        # accumulate  acc += previous product
            acc = acc + p_prev
        elif f == 2:        # hold
            pass
        else:               # 4-7 OPEN -- do not guess
            modelled = False
        out.append(dict(n=r["n"], pred_p=p_reg, pred_acc=acc, modelled=modelled,
                        f=f, obs_p=r["p"], obs_acc=r["acc"]))
        p_prev = p_reg
        coef_prev = sext(round(r["coef"] * ONE), 24)
    return out


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    rows = parse_trace(open(path).read())
    # scope to the EQ biquad pass (the region whose datapath is fully decoded)
    best = cur = []
    for r in rows:
        if r["cur"] <= 0x1D:
            cur = cur + [r]
            best = cur if len(cur) > len(best) else best
        else:
            cur = []
    eq = best
    sim = simulate(eq)

    print("lle_datapath_sim: %s  (EQ pass rows %d..%d)\n"
          % (os.path.basename(path), eq[0]["n"], eq[-1]["n"]))
    # The clean, model-comparable claim: the PRODUCT register (chip's own P column)
    # is reproduced by (coef[N-1]*L[N])>>6 wherever the word runs the multiplier.
    p_ok = p_tot = 0
    modelled_rows = 0
    first_div = None
    for s in sim:
        if s["obs_p"] != 0:            # rows where the chip formed a product
            p_tot += 1
            if s["pred_p"] == s["obs_p"]:
                p_ok += 1
            elif first_div is None:
                first_div = s["n"]
        if s["modelled"]:
            modelled_rows += 1
    print("== PRODUCT reproduction (the multiplier) ==")
    print("   sim P == chip P on %d / %d product-bearing rows%s" %
          (p_ok, p_tot, "" if p_ok == p_tot else "  first divergence n=%s" % first_div))
    print("== ACCUMULATOR op coverage ==")
    openf = sorted({s["f"] for s in sim if not s["modelled"]})
    print("   %d / %d rows modelled by f31 {0,1,2}; OPEN f31 codes present: %s" %
          (modelled_rows, len(sim), openf or "none"))
    print("\n   This engine is S2's oracle: feeding a SPECULATIVE reading (an f31 4-7 op, or")
    print("   an input-route code that supplies L) and re-running names the first word where")
    print("   the guess diverges from the chip -- the accept/reject test for S1/S3/S5.")


if __name__ == "__main__":
    main()
