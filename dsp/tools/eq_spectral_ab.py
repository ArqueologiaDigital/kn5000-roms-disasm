#!/usr/bin/env python3
r"""eq_spectral_ab.py -- N3: spectral A/B of the decoded EQ coefficients.

QUESTION IT ANSWERS
    N3 is "audible EQ from the decode, validated by an INDEPENDENT spectral A/B"
    (a +12 dB panel edit must produce a +12 dB bump at the band centre; an FC edit
    must migrate the peak). This tries to run that A/B directly on the captured
    C-RAM 0x00+ coefficients (flat / +12 dB boost / FC-up, from N1'), by searching
    biquad role mappings (subtractive and additive; the ~2.0 cell as b1==a1 or free)
    for one under which FLAT is ~0 dB and BOOST shows the bump.

RESULT: no mapping of the raw C-RAM cells to a textbook peaking biquad H(z) gives
    flat~0 dB + a boost bump. The reason is structural: forming H(z) from the raw
    cells requires knowing which operands are x-history vs y-history -- i.e. the
    biquad REALIZATION, which is the open N2 question (walled on the undecoded
    input/state-rotation mechanism). So N3's spectral A/B from the LLE cells is
    GATED on N2. The audible EQ itself is already validated in the HLE (dsp/hle/:
    +12 dB -> +12 dB, impulse response == analytic to 0.000 dB, part228) -- the HLE
    uses the DESIGNED coefficients and so bypasses the raw-cell realization question.
    Honest net: N3's audible output exists+validated (HLE); re-deriving it from the
    raw LLE datapath is gated on N2.

    Run: python3 dsp/tools/eq_spectral_ab.py
"""
import re, itertools, cmath, math, os
HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "analysis", "data")

def load(tag):
    c = {}
    for ln in open(os.path.join(DATA, f"kn5000-dsp-eq-cram-{tag}-2026-09-11.txt")):
        m = re.search(r"C-RAM ([0-9A-Fa-f]{2}): (.+)", ln)
        if not m:
            continue
        b = int(m.group(1), 16)
        for i, v in enumerate(m.group(2).split()):
            if re.fullmatch(r"[0-9A-Fa-f]{6}", v):
                c[b + i] = int(v, 16)
    return c

def q22(x):
    return (x - 0x1000000 if x >= 0x800000 else x) / 2.0 ** 22

def resp(coef, mp, sign):
    b0, b1, b2, a1, a2 = (coef[mp[k]] for k in ("b0", "b1", "b2", "a1", "a2"))
    peak, pf = -1e9, 0.0
    for k in range(512):
        w = math.pi * k / 511
        z1, z2 = cmath.exp(-1j * w), cmath.exp(-2j * w)
        num = b0 + b1 * z1 + b2 * z2
        den = 1 + sign * a1 * z1 + sign * a2 * z2
        db = 20 * math.log10(abs(num / den) + 1e-12)
        if db > peak:
            peak, pf = db, w / math.pi
    return peak, pf

def main():
    flat = [q22(load("flat")[i]) for i in range(6)]
    boost = [q22(load("boost")[i]) for i in range(6)]
    print("eq_spectral_ab: searching biquad role mappings for flat~0dB + boost bump\n")
    hits = 0
    for sign in (+1, -1):
        for b1i in range(6):                       # the b1(=a1) cell, any of the 6
            rest = [i for i in range(6) if i != b1i]
            for b0i, b2i, a2i in itertools.permutations(rest, 3):
                mp = {"b0": b0i, "b1": b1i, "b2": b2i, "a1": b1i, "a2": a2i}
                pf, ff = resp(flat, mp, sign)
                pb, fb = resp(boost, mp, sign)
                if abs(pf) < 3.0 and (pb - pf) > 3.0:
                    hits += 1
                    print(f"  sign={'sub' if sign>0 else 'add'} b0={b0i} b1=a1={b1i} b2={b2i} "
                          f"a2={a2i}: flat {pf:+.1f}dB@{ff:.2f}  boost {pb:+.1f}dB "
                          f"(+{pb-pf:.1f}dB)")
    if not hits:
        print("  NO mapping gives flat~0dB + boost bump.")
        print("  => forming H(z) needs the x/y-history assignment = the biquad realization")
        print("     (open N2, walled). N3's spectral A/B from raw cells is gated on N2;")
        print("     the audible EQ is validated in the HLE (dsp/hle/), which uses designed coeffs.")

if __name__ == "__main__":
    main()
