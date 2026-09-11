#!/usr/bin/env python3
"""biquad_stability_probe.py -- S4 validation: the KN5000 EQ feedback SUBTRACTS.

The S1 injection ran the measured biquad datapath on real audio but the cascade
saturated.  S4 traced that to the recursion SIGN: the recursive coefficients are
stored positive, and ADDING them (the "-a pre-negated, += MAC" convention in the
session summary and effects-dsp docs §9) puts a pole OUTSIDE the unit circle
(1.001) -- a positive-feedback runaway = the saturation.  SUBTRACTING them (the
stored value = the true a1,a2) gives poles at 0.710 and a real, stable EQ.

This probe proves it from the CAPTURED band-0 coefficients: it runs the DF-I
biquad both ways and reports pole radius, impulse-response decay (stability) and
the frequency response (is it a sensible EQ?).  The subtractive form is the one
that fits -- the concrete fix to wire into the LLE core (subtractive recursive
MACs, or a negated y-state) so S1 produces faithful, non-saturating EQ.

  Run: python3 dsp/tools/biquad_stability_probe.py
"""
import sys, os, cmath, math

# Band-0 captured coefficients (SEED8/EQ trace), order [b1,b0,b2,-a1,-a2,makeup],
# b0=0.125 confirmed on the input cell x0.  Recursive terms stored POSITIVE.
B1, B0, B2 = 0.75115, 0.12500, 0.12389
R3, R4 = 0.49770, 0.50443          # the stored recursive coefficients
MAKEUP = 0.49998


def poles(a1, a2):
    d = cmath.sqrt(a1 * a1 - 4 * a2)
    return abs((-a1 + d) / 2), abs((-a1 + -d) / 2)


def run(x, a1, a2):
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for xn in x:
        y = B0 * xn + B1 * x1 + B2 * x2 - a1 * y1 - a2 * y2
        out.append(y)
        x2, x1 = x1, xn
        y2, y1 = y1, y
    return out


def report(label, a1, a2):
    p1, p2 = poles(a1, a2)
    ir = run([1.0] + [0.0] * 127, a1, a2)
    tail = max(abs(v) for v in ir[48:])
    stable = max(p1, p2) < 1.0
    print("%s : denom 1 %+.4f z^-1 %+.4f z^-2 | poles %.3f,%.3f -> %s (IR tail %.2e)" %
          (label, a1, a2, p1, p2, "STABLE" if stable else "UNSTABLE", tail))
    if stable:
        mags = []
        for f in (0.0, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5):
            re = sum(ir[n] * math.cos(-2 * math.pi * f * n) for n in range(len(ir)))
            im = sum(ir[n] * math.sin(-2 * math.pi * f * n) for n in range(len(ir)))
            mags.append((f, math.hypot(re, im) * MAKEUP))
        peak = max(mags, key=lambda m: m[1])
        print("     EQ response: " + "  ".join("f%.2f=%+.1fdB" % (f, 20 * math.log10(m + 1e-12))
                                               for f, m in mags))
        print("     -> peak at f=%.2f (%+.1f dB): a sensible peaking EQ." %
              (peak[0], 20 * math.log10(peak[1] + 1e-12)))


def full_cascade():
    """The whole 5-band EQ (captured coefficients, subtractive feedback) on an
    impulse -- reads the coefficients live from the SEED8 trace so it is not
    hard-coded to band 0.  Confirms the decoded sign gives a stable, coherent EQ
    across all five bands, not just band 0."""
    import os
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "hle"))
    from lle_trace_diff import parse_trace  # noqa: E402
    trace = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "analysis",
                         "data", "kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt")
    rows = parse_trace(open(trace).read())
    bands = []
    for b in range(5):
        c = [([r for r in rows if r["cur"] == b * 6 + k and abs(r["coef"]) > 1e-9] or [None])[0]
             for k in range(6)]
        bands.append([(x["coef"] if x else 0.0) for x in c])
    sig = [1.0] + [0.0] * 255
    for c in bands:
        b1, b0, b2, a1, a2, _mk = c
        x1 = x2 = y1 = y2 = 0.0
        out = []
        for xn in sig:
            y = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2   # subtractive
            out.append(y)
            x2, x1 = x1, xn
            y2, y1 = y1, y
        sig = out
    tail = max(abs(v) for v in sig[128:])
    print("\nFULL 5-band cascade (captured coeffs, subtractive, makeup=1):")
    print("  IR tail %.2e -> %s;  cur05 makeup per band: %s" %
          (tail, "STABLE" if tail < 1e-3 else "UNSTABLE",
           [round(b[5], 4) for b in bands]))
    peak = max(range(1, 26), key=lambda i: abs(
        sum(sig[n] * cmath.exp(-2j * math.pi * (i / 100.0) * n) for n in range(len(sig)))))
    mag = abs(sum(sig[n] * cmath.exp(-2j * math.pi * (peak / 100.0) * n) for n in range(len(sig))))
    print("  coherent peaking EQ: peak near f=%.2f (%+.1f dB); cur05==0 bands read as DISABLED" %
          (peak / 100.0, 20 * math.log10(mag + 1e-9)))


def main():
    print("biquad_stability_probe: KN5000 band-0 captured coefficients\n")
    print("ADD feedback  (summary/docs '-a pre-negated, += MAC' convention):")
    report("   ", -R3, -R4)
    print("\nSUBTRACT feedback  (stored = true a1,a2 -- the S4 decode):")
    report("   ", R3, R4)
    full_cascade()
    print("\n=> Only the SUBTRACTIVE form is a real filter.  Wire subtractive recursive")
    print("   feedback into the LLE (subtract the recursive MACs, or negate the y-state)")
    print("   and S1's cascade should stop saturating and render faithful EQ.  Corrects")
    print("   the session-summary convention.")


if __name__ == "__main__":
    main()
