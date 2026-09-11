#!/usr/bin/env python3
"""biquad_topology_probe.py -- why response CANNOT decide the KN5000 biquad topology.

Closes a reproducibility gap flagged by adversarial verification (2026-09-11): the
"DF-II transposed" candidate was quoted with numbers that were actually the DF-I
probe's numbers, and no script implemented a transposed form.  This implements
DF-I, DF-II (canonical) and DF-II TRANSPOSED from the captured band-0 coefficients
and shows the load-bearing fact:

  * their IMPULSE RESPONSES are byte-identical (all realize the same H(z)) -- so
    stability, FFT, the HLE oracle and the designer's (f0,gain,Q) are ALL
    topology-INVARIANT and cannot discriminate the form (a criterion that cannot
    fail);
  * their internal STATE TRAJECTORIES differ -- the ONLY observable that parts the
    forms, and only under the chip's saturating fixed point.

⇒ the topology can be decided ONLY by matching the chip's per-frame state cells
(0x65/0x66, the 0x50 twin) to a candidate's state trajectory, with a DIFFERENTIAL
null (a rival form must FAIL the same test).  Response-matching is not a decode.

  Run: python3 dsp/tools/biquad_topology_probe.py
"""
import math

# Band-0 captured coefficients (SEED8 trace), subtractive (a = +stored, the KN5000
# convention).  b0 = fixed input scale; b1@cur00, b2@cur02; a1@cur03, a2@cur04.
B0, B1, B2 = 0.125, 0.75115, 0.12389
A1, A2 = 0.49770, 0.50443
N = 96


def df1(x):
    x1 = x2 = y1 = y2 = 0.0
    y_out, st = [], []
    for xn in x:
        y = B0 * xn + B1 * x1 + B2 * x2 - A1 * y1 - A2 * y2
        y_out.append(y); st.append((x1, x2, y1, y2))
        x2, x1 = x1, xn; y2, y1 = y1, y
    return y_out, st


def df2_canonical(x):
    # single delay line w: w[n] = x - a1 w[n-1] - a2 w[n-2]; y = b0 w + b1 w1 + b2 w2
    w1 = w2 = 0.0
    y_out, st = [], []
    for xn in x:
        w = xn - A1 * w1 - A2 * w2
        y = B0 * w + B1 * w1 + B2 * w2
        y_out.append(y); st.append((w1, w2))
        w2, w1 = w1, w
    return y_out, st


def df2_transposed(x):
    s1 = s2 = 0.0
    y_out, st = [], []
    for xn in x:
        y = B0 * xn + s1
        s1 = B1 * xn - A1 * y + s2
        s2 = B2 * xn - A2 * y
        y_out.append(y); st.append((s1, s2))
    return y_out, st


def main():
    imp = [1.0] + [0.0] * (N - 1)
    y1, _ = df1(imp)
    y2, _ = df2_canonical(imp)
    y3, _ = df2_transposed(imp)
    d12 = max(abs(a - b) for a, b in zip(y1, y2))
    d13 = max(abs(a - b) for a, b in zip(y1, y3))
    print("biquad_topology_probe: band-0 captured coeffs, subtractive\n")
    print("1. IMPULSE RESPONSES across topologies (should be identical = topology-invariant):")
    print("   max|DF-I - DF-II canonical|   = %.2e" % d12)
    print("   max|DF-I - DF-II transposed| = %.2e" % d13)
    print("   => response/FFT/stability/HLE-oracle CANNOT tell the forms apart (all realize H(z)).")

    # the DISCRIMINATOR: internal state after a few samples differs per form
    step = [0.3] * 8
    _, s1 = df1(step)
    _, s2 = df2_canonical(step)
    _, s3 = df2_transposed(step)
    print("\n2. INTERNAL STATE after 8 samples of a 0.3 step (the ONLY discriminator):")
    print("   DF-I         (x1,x2,y1,y2) = %s" % (tuple(round(v, 4) for v in s1[-1]),))
    print("   DF-II canon. (w1,w2)       = %s" % (tuple(round(v, 4) for v in s2[-1]),))
    print("   DF-II transp.(s1,s2)       = %s" % (tuple(round(v, 4) for v in s3[-1]),))
    print("   => distinct state values -> matching the chip's per-frame cells (0x65/0x66)")
    print("      against these, with a DIFFERENTIAL null (a rival form must FAIL), is the only")
    print("      valid topology decode.  Do it under 24-bit SATURATING arithmetic (forms")
    print("      diverge in overflow) and with identical input across frames.")


if __name__ == "__main__":
    main()
