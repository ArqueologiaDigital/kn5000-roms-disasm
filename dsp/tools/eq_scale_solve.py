#!/usr/bin/env python3
"""eq_scale_solve.py -- what scale does each EQ biquad coefficient need?  Solved from the cells.

QUESTION IT ANSWERS
    The chip's multiply is P = (coef x L) >> s.  The LLE ships one s for every word (22 total
    bits), and the seeded traces show that cannot be right: at s=22 the EQ's own state block
    RAILS, at s=23 it stays finite (N-SINGLE-DELAY-RECURRENCE S6-S9).  Rather than guess a
    selector (the bit-12 arms were run and refuted), SOLVE for the scale each coefficient needs
    from a property of the filter itself.

    An RBJ peaking biquad, normalised to a0 = 1, has  b1 == a1  EXACTLY, at every gain and
    every frequency (both are -2*cos(w0)/(1 + alpha/A)).  It also has b0 = (1+alpha*A)/(1+alpha/A)
    and b2 = (1-alpha*A)/(1+alpha/A), so at 0 dB (A = 1) b0 = 1 and b2 = a2.  So reading the five
    cells at ONE scale and printing
        b0/1        b1/a1        b2/a2
    tells us, per band, the factor each b-path coefficient is off by -- and whether that factor
    is the SAME in every band (structural: a datapath scale) or scattered (a wrong cell map).

    python3 dsp/tools/eq_scale_solve.py <trace.log> [--lo 84 --hi 190]

    The trace is any armed PARAMETRIC EQ frame trace (dsp/analysis/data/dlyseed2_eq_*.log.gz,
    uncompressed).  Cells are read from the `coef' column at the cursor the band's words consume,
    exactly as lle_trace_diff.py --eq-trace does, so the two tools agree by construction.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dlyseed_confront import parse, s24, fields   # noqa: E402

Q = 8388608.0                                   # read every cell at Q0.23; only RATIOS matter


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lo = int(sys.argv[sys.argv.index("--lo") + 1]) if "--lo" in sys.argv else 84
    hi = int(sys.argv[sys.argv.index("--hi") + 1]) if "--hi" in sys.argv else 190
    if not args:
        print(__doc__); return 2
    rows = [r for r in parse(args[0]) if r["u1"] == 0 and lo <= r["iw"] <= hi]
    if not rows:
        print("no body rows in iw %d..%d" % (lo, hi)); return 1

    # The KN5000 EQ lays 5 bands x 6 cursor cells from base 0x00, consumed in the order
    # b1, b0, b2, -a1, -a2, makeup (N1-EQ-COEFFICIENT-MEMORY).  Take the FIRST row that
    # consumes each cursor cell, and remember the word that multiplied with it.
    first = {}
    for r in rows:
        first.setdefault(r["cur"], r)
    print("band  cell   b1       b0       b2       -a1      -a2      mk    |  b0/1    b1/a1   b2/a2  | words (bit12,ACT)")
    pat = []
    for band in range(5):
        base = band * 6
        cells = [first.get(base + k) for k in range(6)]
        if not all(cells):
            print("band %d: cursor 0x%02X..0x%02X not all present in the trace" % (band, base, base + 5))
            continue
        v = [s24(c["coef"]) / Q for c in cells]
        b1, b0, b2, na1, na2, mk = v
        a1, a2 = -na1, -na2
        r0 = b0 / 1.0
        r1 = (b1 / a1) if a1 else float("nan")
        r2 = (b2 / a2) if a2 else float("nan")
        pat.append((r0, r1, r2))
        wf = " ".join("%d/%02X" % (((int(c["word"], 16) >> 12) & 1), fields(c)[5]) for c in cells[:5])
        print("  %d  0x%02X  %+7.4f  %+7.4f  %+7.4f  %+7.4f  %+7.4f  %+5.2f |  %6.4f  %6.4f  %6.4f | %s"
              % (band, base, b1, b0, b2, na1, na2, mk, r0, r1, r2, wf))
    # ---- the decisive test: under which per-coefficient scaling is the band FLAT? -------------
    # A 0 dB peaking band must have |H| = 1 at every frequency.  Evaluate |H(e^jw)| over the
    # spectrum for each candidate scaling of the b-path and report its dB spread and mean.
    # (mk = -1.0 in every band: an inversion, which the cascade's own sign flip between bands
    # confirms -- band 0's y cell is the exact negation of band 1's x cell in a live trace.)
    print("\n== FLATNESS TEST: |H(e^jw)| in dB over 200 log-spaced frequencies, per candidate scaling")
    print("   (a 0 dB band must be FLAT at 0 dB; 'spread' is max-min in dB)")
    CANDS = (("as stored (one scale)", 1.0, 1.0, 1.0),
             ("b-path x2",             2.0, 2.0, 2.0),
             ("b-path x4",             4.0, 4.0, 4.0),
             ("b0,b2 x4  b1 x2",       4.0, 2.0, 4.0))
    import math
    for band in range(5):
        base = band * 6
        cells = [first.get(base + k) for k in range(6)]
        if not all(cells):
            continue
        b1, b0, b2, na1, na2, mk = [s24(c["coef"]) / Q for c in cells]
        a1, a2 = -na1, -na2
        line = "  band %d:" % band
        for name, k0, k1, k2 in CANDS:
            mags = []
            for i in range(200):
                w = math.pi * (10 ** (-3 + 3 * i / 199.0))      # 0.001*pi .. pi
                z1 = complex(math.cos(-w), math.sin(-w))
                z2 = z1 * z1
                num = (b0 * k0) + (b1 * k1) * z1 + (b2 * k2) * z2
                den = 1.0 + a1 * z1 + a2 * z2
                mags.append(abs(num / den) * abs(mk))
            db = [20 * math.log10(m + 1e-12) for m in mags]
            line += "  %s: mean %+6.2f dB spread %6.2f |" % (name, sum(db) / len(db), max(db) - min(db))
        print(line)
    print("   ⇒ the scaling whose spread is ~0 dB at ~0 dB mean is the one the chip's datapath must"
          " realise (RBJ: b == a exactly makes H == 1).")

    if len(pat) > 1:
        for name, idx in (("b0/1", 0), ("b1/a1", 1), ("b2/a2", 2)):
            col = [p[idx] for p in pat]
            spread = max(col) - min(col)
            print("  %-6s across bands: %s   spread %.5f  %s" % (
                name, " ".join("%.4f" % c for c in col), spread,
                "CONSTANT -> structural" if spread < 0.02 else "varies -> not one datapath factor"))
        print("\n  RBJ requires b1/a1 == 1 and, at 0 dB, b0 == 1 and b2/a2 == 1.  A constant ratio")
        print("  r means those coefficients' products must be scaled by 1/r -- i.e. shift log2(1/r)")
        print("  bits DIFFERENTLY from the a-path, which is the per-word scale the LLE must model.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
