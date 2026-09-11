#!/usr/bin/env python3
"""eq_role_split_probe.py  --  N1: which captured EQ coefficients are b vs a?

QUESTION IT ANSWERS
    The captured 5-band EQ biquad coefficients (see eq_coef_layout_probe.py /
    kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt) were tentatively assigned
    B1=entry, B2=store, A1=c2, A2=c3.  Under THAT assignment every one of the 5
    bands resonates at the same normalised frequency (~0.30 * Nyquist, ~13.5 kHz
    at fs=44.1k) -- a real 5-band parametric EQ must SPREAD its bands across the
    spectrum, so the assignment is suspect.  This probe reproduces that clustering
    as the NULL, then tests every role permutation x sign convention and scores
    each by how much the per-band resonant frequency SPREADS.

FALSIFIER (pre-registered)
    A correct assignment must (a) reproduce the captured numbers by construction
    -- we only permute their ROLES, so every candidate reproduces them trivially
    -- and (b) yield 5 band frequencies that are DISTINCT and spread across the
    spectrum (a real graphic/parametric EQ).  If NO assignment spreads the bands,
    the EQ is not a per-band peaking biquad of the assumed shape -- that is a
    finding, not a knob to keep turning.  Frequency spread is reported in
    NORMALISED units (fraction of Nyquist), which is independent of the (assumed)
    sample rate, so the falsifier does not rest on fs.

RUN
    python3 dsp/tools/eq_role_split_probe.py
"""
import cmath, math, itertools

# --- captured coefficients, 5 bands (from kn5000-dsp-eq-biquad-trace-SEED8-2026-09-11.txt
#     via eq_coef_layout_probe.py).  Per band, cursor order:
#     entry (couples prev band / own input), b0=0.125 (LOAD), store, c2, c3, makeup.
BANDS = {
    "entry":  [0.75115, 0.75236, 0.75499, 0.76102, 0.77584],
    "b0":     [0.12500, 0.12500, 0.12500, 0.12500, 0.12500],
    "store":  [0.12389, 0.12279, 0.12063, 0.11643, 0.10858],
    "c2":     [0.49770, 0.49527, 0.49001, 0.47797, 0.44833],
    "c3":     [0.50443, 0.50882, 0.51748, 0.53428, 0.56566],
    "makeup": [0.49998, 0.00096, 0.37500, 0.00013, 0.00000],
}
FS = 44100.0  # ASSUMED effects-DSP sample rate; frequencies also reported normalised.

def poles(a1, a2, sign):
    """Return (radius, angle_rad) of the denominator roots.
       sign=+1 : subtractive feedback y = ... - a1 y1 - a2 y2  -> char z^2 + a1 z + a2
       sign=-1 : additive             y = ... + a1 y1 + a2 y2  -> char z^2 - a1 z - a2 """
    A1, A2 = sign * a1, sign * a2
    disc = cmath.sqrt(A1 * A1 - 4 * A2)
    r1, r2 = (-A1 + disc) / 2, (-A1 - disc) / 2
    # pick the pole with the larger imaginary part (the resonant one) for the angle
    p = r1 if abs(r1.imag) >= abs(r2.imag) else r2
    return abs(p), abs(cmath.phase(p))

def band_freq(a1, a2, sign):
    r, ang = poles(a1, a2, sign)
    return ang / math.pi, r          # normalised freq (0..1 of Nyquist), pole radius

def spread_score(freqs):
    """large + monotone spread across bands is what a real EQ shows."""
    lo, hi = min(freqs), max(freqs)
    return hi - lo

# 1. THE NULL: the current assignment (a1=c2, a2=c3, subtractive) -> clustering
print("=== NULL: current assignment  a1=c2, a2=c3, subtractive ===")
fn = []
for i in range(5):
    nf, r = band_freq(BANDS["c2"][i], BANDS["c3"][i], +1)
    fn.append(nf)
    print(f"  band {i}: pole r={r:.3f}  f_norm={nf:.3f}  (~{nf*FS/2:6.0f} Hz)")
print(f"  spread = {spread_score(fn):.3f} of Nyquist  <-- clustered = the red flag\n")

# 2. Enumerate role permutations x sign, score by frequency spread.
#    b0 is fixed (0.125 input scale); makeup is a post-gain; the 4 free coeffs
#    {entry, store, c2, c3} fill roles {b1, b2, a1, a2}.
FREE = ["entry", "store", "c2", "c3"]
results = []
for perm in itertools.permutations(FREE):        # (b1_key,b2_key,a1_key,a2_key)
    b1k, b2k, a1k, a2k = perm
    for sign in (+1, -1):
        fs_norm, radii, stable = [], [], True
        for i in range(5):
            a1, a2 = BANDS[a1k][i], BANDS[a2k][i]
            r, ang = poles(a1, a2, sign)
            if r >= 1.0:                          # unstable -> reject the whole assignment
                stable = False
            fs_norm.append(ang / math.pi)
            radii.append(r)
        if not stable:
            continue
        monotone = (all(x < y for x, y in zip(fs_norm, fs_norm[1:])) or
                    all(x > y for x, y in zip(fs_norm, fs_norm[1:])))
        results.append({
            "perm": perm, "sign": "sub" if sign == +1 else "add",
            "spread": spread_score(fs_norm), "monotone": monotone,
            "fnorm": fs_norm, "rmin": min(radii), "rmax": max(radii),
        })

results.sort(key=lambda r: (r["monotone"], r["spread"]), reverse=True)
print("=== stable assignments, ranked by band-frequency spread ===")
print("  (b1,b2,a1,a2)                       sign  spread  mono  f_norm per band")
for r in results[:8]:
    fnorm = " ".join(f"{x:.2f}" for x in r["fnorm"])
    print(f"  {str(r['perm']):34s} {r['sign']:4s} {r['spread']:.3f}  "
          f"{'Y' if r['monotone'] else '.':1s}     [{fnorm}]")

# 3. RBJ peaking-EQ structural test: in a peaking biquad, b1 == a1 (== -2cos w0).
#    Which captured pair is most nearly equal across all 5 bands?
print("\n=== RBJ peaking signature: b1 == a1 ? (nearest-equal coeff pair) ===")
pairs = itertools.combinations(FREE, 2)
diffs = []
for x, y in pairs:
    d = max(abs(BANDS[x][i] - BANDS[y][i]) for i in range(5))
    diffs.append((d, x, y))
for d, x, y in sorted(diffs):
    print(f"  max|{x}-{y}| = {d:.4f}")
print("  (a peaking EQ forces b1==a1; the near-equal pair is the b1/a1 candidate.)")

# 4. Structural note the enumeration can't score: does b0+b1+b2 sum to ~1?
print("\n=== numerator DC-gain check  b0 + entry + store per band ===")
for i in range(5):
    s = BANDS["b0"][i] + BANDS["entry"][i] + BANDS["store"][i]
    print(f"  band {i}: 0.125 + {BANDS['entry'][i]:.3f} + {BANDS['store'][i]:.3f} = {s:.4f}")
print("  (~1.0 => {b0, entry, store} look like a unity-DC-gain NUMERATOR,\n"
      "   which would leave {c2, c3} as the denominator -- i.e. the NULL split.\n"
      "   If so, the clustering is real and the fix is elsewhere: see falsifier.)")

# 5. Is this a FLAT EQ capture?  Compute |H(e^jw)| for the NULL split per band
#    (numerator {b0,entry,store}, denominator {c2,c3} subtractive, x makeup).
#    A flat/default EQ => every band ~0 dB everywhere; that would explain the
#    clustering as "the bands were never boosted", not a decode error.
def resp_db(b0, b1, b2, a1, a2, g):
    peak, trough = -1e9, 1e9
    for k in range(256):
        w = math.pi * k / 255
        z1, z2 = cmath.exp(-1j * w), cmath.exp(-2j * w)
        num = b0 + b1 * z1 + b2 * z2
        den = 1 + a1 * z1 + a2 * z2          # subtractive: +a in the z-poly
        h = g * num / den
        db = 20 * math.log10(abs(h) + 1e-12)
        peak, trough = max(peak, db), min(trough, db)
    return peak, trough
print("\n=== flat-EQ test: response of the NULL split per band (x makeup) ===")
for i in range(5):
    pk, tr = resp_db(BANDS["b0"][i], BANDS["entry"][i], BANDS["store"][i],
                     BANDS["c2"][i], BANDS["c3"][i], BANDS["makeup"][i])
    print(f"  band {i}: peak {pk:+6.2f} dB   trough {tr:+6.2f} dB   swing {pk-tr:5.2f} dB")
print("  (small swing AND ~0 dB peak => a near-flat/default capture: the bands were\n"
      "   not boosted, so their centre frequencies cannot be read from this trace.\n"
      "   The right N1 experiment then is DIFFERENTIAL: drive one band's gain/freq\n"
      "   via peq_gain.lua / peq_cursor.lua and re-capture -- watch which coeff moves.)")
