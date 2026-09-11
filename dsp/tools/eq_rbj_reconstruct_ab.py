#!/usr/bin/env python3
r"""eq_rbj_reconstruct_ab.py -- N3: validate the MAME audible-EQ coefficient formula.

QUESTION IT ANSWERS
    The MAME HLE EQ insert (kn5000_tonegen.cpp, eq_hle path) does NOT read the raw
    C-RAM cells as direct-form biquad coefficients -- eq_spectral_ab.py proved that
    cannot work (it needs the walled N2 realization). Instead it RECONSTRUCTS textbook
    RBJ peaking biquads from DESIGN PARAMETERS pulled out of the cells:
        frequency: cell 0x03 == 2*cos w0          (SOLID, N1')
        gain:      A^2 == (cell1 - cell2)/K       (K = 0.00443, band-0 fit)
        Q:         assumed 2.0
    GAIN de-entanglement (why (c1-c2) is wrong): (c1-c2) moves with FREQUENCY too, so an
    FC edit spuriously reads as +31 dB. The clean gain signal is (c1 - 0.5): cell base+1
    is EXACTLY 0.5 (0x200000) at 0 dB for band 0 AND band 1 AND under an FC edit, and only
    deviates under a gain edit (0.50654 at +12 dB). So the model is A^2 = 1 + G*(c1 - 0.5),
    G = 455.7 (fit so +12 dB -> A^2 = 3.98); frequency-independent, passes all 3 captures.

    This script runs that EXACT formula on the committed flat / +12 dB boost / FC-up
    C-RAM captures and reports the resulting peaking response, so the C++ port can be
    checked offline before spending emulator time on the in-emulator spectral A/B.

    PASS criteria (band 0, fs=44100):
        flat  -> peak ~ 0 dB   at ~672 Hz
        boost -> peak ~ +12 dB at ~672 Hz   (same centre, +12 dB taller)
        fc    -> peak migrates UP in frequency

    Run: python3 dsp/tools/eq_rbj_reconstruct_ab.py
    Data: dsp/analysis/data/kn5000-dsp-eq-cram-{flat,boost,fc}-2026-09-11.txt
"""
import re, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "analysis", "data")
FS = 44100.0
GAIN_G = 455.7    # must match kn5000_tonegen.cpp GAIN_G:  A^2 = 1 + G*(c1 - 0.5)
QVAL = 2.0        # must match kn5000_tonegen.cpp QVAL


def load_band0(tag):
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


def rbj_from_cells(cells):
    """The exact reconstruction kn5000_tonegen.cpp performs, band 0."""
    c1, c3 = q22(cells[1]), q22(cells[3])
    # Scale normalisation (mirrors kn5000_tonegen.cpp): m_cram is read at either the CELL
    # scale (these committed dumps: c3 = 2cos w0) or, at runtime without the LLE, the
    # OPERAND scale (exactly half: c3 = cos w0).  |c3|<=1 => operand => double back to cell
    # scale.  For these cell-scale dumps c3 (1.99/-1.09) is already >1, so norm == 1.
    norm = 2.0 if abs(c3) <= 1.0 else 1.0
    c1 *= norm; c3 *= norm
    cosw0 = max(-0.9995, min(0.9995, c3 * 0.5))
    w0 = math.acos(cosw0)
    f0 = w0 * FS / (2.0 * math.pi)          # design centre frequency (always defined)
    asq = 1.0 + GAIN_G * (c1 - 0.5)         # A^2 = 1 + G*(c1 - 0.5); >1 boost, <1 cut
    if abs(asq - 1.0) < 1e-4:
        return (1.0, 0.0, 0.0, 0.0, 0.0), 1.0, f0   # 0 dB -> passthrough
    A = math.sqrt(max(asq, 0.01))
    alpha = math.sin(w0) / (2.0 * QVAL)
    b0, b1, b2 = 1.0 + alpha * A, -2.0 * cosw0, 1.0 - alpha * A
    a0, a1, a2 = 1.0 + alpha / A, -2.0 * cosw0, 1.0 - alpha / A
    coeffs = (b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    return coeffs, A, f0


def peak(coeffs):
    b0, b1, b2, a1, a2 = coeffs
    pk, pf = -1e9, 0.0
    for k in range(2048):
        w = math.pi * k / 2047
        z1, z2 = complex(math.cos(-w), math.sin(-w)), complex(math.cos(-2 * w), math.sin(-2 * w))
        H = (b0 + b1 * z1 + b2 * z2) / (1.0 + a1 * z1 + a2 * z2)
        db = 20 * math.log10(abs(H) + 1e-12)
        if db > pk:
            pk, pf = db, w / math.pi * FS / 2.0
    return pk, pf


def main():
    print(f"eq_rbj_reconstruct_ab: G={GAIN_G} Q={QVAL} fs={FS:.0f}\n")
    print(f"{'capture':7} {'A':>7} {'f0_design':>10} {'peak_dB':>8} {'peak_Hz':>8}")
    results = {}
    for tag in ("flat", "boost", "fc"):
        cells = load_band0(tag)
        coeffs, A, f0 = rbj_from_cells(cells)
        pk, pf = peak(coeffs)
        results[tag] = (pk, pf, f0)
        print(f"{tag:7} {A:7.3f} {f0:10.1f} {pk:+8.2f} {pf:8.1f}")

    print()
    ok = True
    fp, ff, f0f = results["flat"]
    bp, bf, f0b = results["boost"]
    cp, cf, f0c = results["fc"]
    def check(name, cond):
        nonlocal ok
        ok = ok and cond
        print(f"  [{'PASS' if cond else 'FAIL'}] {name}")
    check("flat peak ~0 dB (|.|<1.5)", abs(fp) < 1.5)
    check("boost peak ~+12 dB (10.5..13.5)", 10.5 < bp < 13.5)
    check("boost centre ~ flat design centre (|df|<60 Hz)", abs(bf - f0f) < 60)
    check("fc gain stays ~0 dB (|.|<1.5) -- freq edit, not gain", abs(cp) < 1.5)
    check("fc DESIGN centre migrates UP (>+300 Hz)", f0c - f0f > 300)
    print("\n" + ("ALL PASS -- formula validated offline; safe to A/B in-emulator."
                  if ok else "FAIL -- fix the formula before enabling the path."))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
