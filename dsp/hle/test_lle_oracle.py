#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""test_lle_oracle.py -- prove the per-word LLE oracle equals the validated HLE biquad.

If the oracle's five-MAC accumulator did not reproduce BiquadDF1 sample-for-sample, it would be
worthless as a decode target.  Each check is analytic or against the already-validated kernel;
no hardware, no LLE core needed (the oracle is what a future LLE trace is confronted with).

    python3 dsp/hle/test_lle_oracle.py
"""
import os
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lle_oracle as O                                                   # noqa: E402

PASS = True


def check(name, ok, detail=""):
    global PASS
    PASS = PASS and ok
    print("  [%s] %-52s %s" % ("PASS" if ok else "FAIL", name, detail))


def main():
    secs = O.sections_from_capture()
    check("capture yields 12 stereo biquad sections", len(secs) == 12, "%d sections" % len(secs))

    # 1. The oracle reproduces the validated BiquadDF1 sample-for-sample, on REAL coefficients,
    #    for EVERY captured section -- the property that makes it a legitimate decode target.
    rng = np.random.default_rng(0)
    x = rng.standard_normal(512)
    worst = 0.0
    for base, section in secs:
        orc = O.BiquadOracle(section, base=base)
        ref = orc.as_biquad()
        yref = ref.process(x)                       # the validated kernel (makeup applied)
        yorc = np.array([orc.step(xi)[2] for xi in x])
        worst = max(worst, float(np.max(np.abs(yorc - yref))))
    check("oracle output == BiquadDF1 on all 12 sections", worst < 1e-12, "max |Δ| = %.2e" % worst)

    # 2. The five products ARE the five DF-I terms (order-invariant hard target).
    base, section = secs[0]
    b1, b0, b2, na1, na2, mk = section
    orc = O.BiquadOracle(section, base=base)
    orc.step(0.3); orc.step(-0.7)                    # prime history
    steps, y_presum, y_out = orc.step(0.5)
    want = {("b0", "x0"): b0 * 0.5, ("b1", "x1"): b1 * (-0.7), ("b2", "x2"): b2 * 0.3,
            ("-a1", "y1"): na1 * orc_prev_y(orc, steps, "y1"),
            ("-a2", "y2"): na2 * orc_prev_y(orc, steps, "y2")}
    got = {(s.coeff_role, s.operand_role): s.product for s in steps}
    check("the five MACs are exactly the DF-I term set", set(got) == set(want),
          "roles %s" % sorted(k for k, _ in got))
    check("each MAC product matches coeff*operand",
          all(abs(got[k] - v) < 1e-12 for k, v in want.items()))

    # 3. The accumulator is a running sum: acc_after[k] == acc_after[k-1] + product[k] (k>0),
    #    and step 0 is a LOAD (acc_after[0] == product[0]).  This is the exact schedule an LLE
    #    trace must exhibit: one load-op word then four accumulate-op words.
    check("step 0 is a load (acc = product)", abs(steps[0].acc_after - steps[0].product) < 1e-15,
          "op=%s" % steps[0].acc_op)
    running_ok = all(abs(steps[k].acc_after - (steps[k - 1].acc_after + steps[k].product)) < 1e-12
                     for k in range(1, 5))
    check("steps 1..4 are accumulates (running sum)", running_ok)
    check("only step 0 carries the load op",
          [s.acc_op for s in steps] == ["load", "mac", "mac", "mac", "mac"])

    # 4. The cursor addresses are consecutive from the section base -- the MEASURED +1-per-word
    #    coefficient cursor.  This is what lets a class-A word's coefficient be named absolutely.
    check("cursor cells are consecutive from base", [s.cursor_cell for s in steps]
          == [base, base + 1, base + 2, base + 3, base + 4], "%s" % [s.cursor_cell for s in steps])

    # 5. The makeup is a separate post-sum step at cell base+5, matching the class-8 post-sum
    #    word -- not one of the five cursor-advancing class-A MACs.
    check("makeup applied after the sum (y_out == presum*makeup)",
          abs(y_out - y_presum * mk) < 1e-12, "makeup %+.3f" % mk)

    # 6. One-pole oracle == the validated OnePole kernel (the 0x0D/0x0E damping pair).
    from kernels import OnePole, LFO                                     # noqa: E402
    op = O.OnePoleOracle(0.6, base=0x30)
    ref = OnePole(0.6)
    xs = np.random.default_rng(1).standard_normal(64)
    worst = max(abs(op.step(x)[1] - ref.process_one(x)) for x in xs)
    check("one-pole oracle == OnePole kernel", worst < 1e-12, "max |Δ| = %.2e" % worst)
    op2 = O.OnePoleOracle(0.6, base=0x30)
    st, _ = op2.step(1.0)
    check("one-pole is load-then-accumulate at consecutive cells",
          [s.acc_op for s in st] == ["load", "mac"] and [s.cursor_cell for s in st] == [0x30, 0x31])

    # 7. LFO oracle: the phase accumulates by a fixed increment and wraps at 2^23 -- and tracks
    #    the validated LFO kernel's fractional phase.
    lo = O.LFOOracle(3.0, fs=44100.0)
    b0, inc, a0 = lo.step()
    b1, _, a1 = lo.step()
    check("LFO phase accumulates by inc", a0 == (b0 + inc) % O.LFOOracle.WRAP and a1 == (b1 + inc) % O.LFOOracle.WRAP)
    check("LFO inc matches rate/fs", abs(inc / O.LFOOracle.WRAP - 3.0 / 44100.0) < 1e-6)
    lref = LFO(3.0, 44100.0)
    lref.block(1)                                          # advance one sample
    check("LFO oracle phase == LFO kernel phase", abs(a0 / O.LFOOracle.WRAP - lref.phase) < 1e-6,
          "oracle %.6f vs kernel %.6f" % (a0 / O.LFOOracle.WRAP, lref.phase))

    print("\n%s" % ("ALL LLE-ORACLE CHECKS PASSED" if PASS else "SOME CHECKS FAILED"))
    return 0 if PASS else 1


def orc_prev_y(orc, steps, role):
    """The y-history value the recursive MAC used (read from the step itself, for the assertion)."""
    for s in steps:
        if s.operand_role == role:
            return s.operand_value
    return 0.0


if __name__ == "__main__":
    sys.exit(main())
