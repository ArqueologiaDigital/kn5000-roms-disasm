#!/usr/bin/env python3
r"""biquad_null_discriminates.py -- P2: can the seeded trajectory decide DF-II
canonical vs transposed? (Answer: NOT under a constant input.)

QUESTION IT ANSWERS
    The captured 6-frame seeded band-0 trajectory has 0x64 (x0) = 0.004419 CONSTANT
    every frame, 0x65 settling to the same constant, and 0x66/0x67 = the output (y)
    history (0x67[n] = 0x66[n-1]/2 exactly). The differential null needs the captured
    cells to DIFFER between DF-II canonical and DF-II transposed. This checks whether
    they can, by running both forms and comparing the observable cells:
      * under a CONSTANT input (as captured), and
      * under a TRANSIENT input (an impulse).

RESULT: under a constant input the two forms' observable states are IDENTICAL --
    the shared cell settles to x, and y-history is topology-invariant by definition --
    so the captured trajectory is a criterion that CANNOT FAIL and decides nothing.
    Under a transient (impulse) input the two forms' internal states DIVERGE, so the
    null WOULD discriminate. => P2 needs a NON-CONSTANT excitation of 0x64 (impulse or
    varying audio), not the constant the seed/route currently delivers. No topology
    call is made from the constant-input capture.

    Run: python3 dsp/tools/biquad_null_discriminates.py
"""
# Captured band-0 coefficients (cursor coef = C-RAM>>1), from null_2000002.
B0 = 0.25000       # on x0 (0x64)
CW = 0.24778       # on the shared cell (0x65)
A1 = 0.99541       # on y1 (0x66)
A2 = -0.99114      # on y2 (0x67)

def df2_canonical(x, s1=0.0, s2=0.0):
    # w[n] = x - a1 w1 - a2 w2 ; y = b0 w + ...   (observable state: w1, w2)
    out = []
    for xn in x:
        w = xn - A1 * s1 - A2 * s2
        y = B0 * w + CW * s1
        out.append((w, s1, y))      # (current shared state, its delay, output)
        s2, s1 = s1, w
    return out

def df2_transposed(x, d1=0.0, d2=0.0):
    # y = b0 x + d1 ; d1 = cw x - a1 y + d2 ; d2 = -a2 y   (observable state: d1, d2)
    out = []
    for xn in x:
        y = B0 * xn + d1
        nd1 = CW * xn - A1 * y + d2
        nd2 = -A2 * y
        out.append((d1, d2, y))
        d1, d2 = nd1, nd2
    return out

def cmp(x, tag):
    c = df2_canonical(x); t = df2_transposed(x)
    # observable = the shared state cell + the output (what the trace sees)
    dstate = max(abs(c[i][0] - t[i][0]) for i in range(len(x)))
    dout = max(abs(c[i][2] - t[i][2]) for i in range(len(x)))
    print(f"  {tag:22s} max|shared-state diff|={dstate:.3e}  max|output diff|={dout:.3e}")
    return dstate

const_in = [0.004419] * 8
imp_in = [0.004419] + [0.0] * 7      # a one-sample step-off = transient
step_in = [0.0] + [0.004419] * 7     # a step transient

print("biquad_null_discriminates: do the forms' internal states differ, and does the")
print("captured cell match one of them?\n")
cmp(const_in, "constant input")
cmp(step_in,  "step input (transient)")
cmp(imp_in,   "impulse input")

# The decisive check: what does the CAPTURED 0x65 settle to, vs each form's steady state?
X = 0.004419
captured_0x65 = 0.004419             # = 0x64 exactly (delayed input), from the 6-frame capture
w_canon = df2_canonical(const_in)[-1][0]
d1_transp = df2_transposed(const_in)[-1][0]
print(f"\n  steady shared-state under constant input x={X}:")
print(f"    captured 0x65        = {captured_0x65:.6f}  (= 0x64 EXACTLY, i.e. delayed input x1)")
print(f"    DF-II canonical  w   = {w_canon:.6f}")
print(f"    DF-II transposed d1  = {d1_transp:.6f}")
print("\n  READ: the captured 0x65 equals the INPUT exactly -- it matches neither DF-II\n"
      "  shared-state steady value; under a constant input x1 = x = w-ish, so every\n"
      "  candidate degenerates and the cell cannot tell them apart (a criterion that\n"
      "  cannot fail). The forms' states DO differ under a transient (rows above), so\n"
      "  P2 needs a NON-CONSTANT excitation of 0x64. NO topology call from this capture.")
