#!/usr/bin/env python3
"""peq_tf.py -- decode the LIVE C-RAM coefficients captured with PARAMETRIC EQ
selected, using the ALREADY-SOLVED format from notes/kn5000-dsp-biquad-coeffs.md:

    NN+0 = b1      x 2^22, pre-halved
    NN+1 = b0      x 2^22, pre-halved
    NN+2 = b2      x 2^22, pre-halved
    NN+3 = -a1/a0  x 2^22
    NN+4 = -a2/a0  x 2^23
    NN+5 = (that note calls it padding; the PROGRAM multiplies by it -- tested here)

y = b0*x + b1*x1 + b2*x2 + A1*y1 + A2*y2   with A1 = -a1/a0, A2 = -a2/a0

THE CONTROL, and it is the point of this script: the sub-CPU designer takes f0 from a
27-entry ISO 1/3-octave table (40 50 63 80 ... 12500 16000) and Q from a 32-entry table,
then computes K = tan(pi*f0/44100).  So if the POLE angles recovered from live C-RAM land
on ISO centres, the whole chain host -> C-RAM -> this decode is verified end to end.
A pole angle that lands nowhere near an ISO centre FALSIFIES the decode.
"""
import cmath
import math

FS = 44100.0
ISO = [40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000,
       1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000]

# C-RAM 0x00..0x1D, verbatim from error.log ("C-RAM 00:" and "C-RAM 10:")
CRAM = [0xC04B34, 0x200000, 0x1FB760, 0x7F6996, 0x81227A, 0x800000,
        0xC09AE0, 0x200000, 0x1F6F6C, 0x7ECA3E, 0x824250, 0x800000,
        0xC14746, 0x200000, 0x1EE18C, 0x7D7172, 0x8479CA, 0x800000,
        0xC2D20A, 0x1FFFF8, 0x1DCE4E, 0x7A5C04, 0x88C6AE, 0x800000,
        0xC69D20, 0x200000, 0x1BCC2C, 0x72C5C0, 0x90CF4C, 0x800000]


def s24(v):
    return v - 0x1000000 if v & 0x800000 else v


def section(raw):
    b1 = s24(raw[0]) / 2.0**22
    b0 = s24(raw[1]) / 2.0**22
    b2 = s24(raw[2]) / 2.0**22
    A1 = s24(raw[3]) / 2.0**22          # = -a1/a0
    A2 = s24(raw[4]) / 2.0**23          # = -a2/a0
    return b0, b1, b2, A1, A2


def nearest_iso(f):
    best = min(ISO, key=lambda c: abs(math.log(f / c)) if f > 0 else 9e9)
    return best, 100.0 * (f - best) / best


print("live C-RAM 0x00..0x1D, five stride-6 sections\n")
print("  sec  b0       b1        b2       A1       A2      "
      "| pole r    f0(Hz)   -> nearest ISO   err")
print("  " + "-" * 96)
secs = []
for k in range(5):
    b0, b1, b2, A1, A2 = section(CRAM[6 * k:6 * k + 6])
    secs.append((b0, b1, b2, A1, A2))
    # denominator 1 - A1 z^-1 - A2 z^-2  ->  z^2 - A1 z - A2
    r = math.sqrt(-A2) if A2 < 0 else float('nan')
    disc = A1 * A1 + 4 * A2
    if disc < 0:
        th = math.acos(max(-1.0, min(1.0, A1 / (2 * r))))
        f0 = th * FS / (2 * math.pi)
        iso, err = nearest_iso(f0)
        note = "%8.1f  -> %6d Hz  %+6.1f%%" % (f0, iso, err)
    else:
        f0 = float('nan')
        note = "   real poles (not resonant)"
    print("  %3d  %+7.4f %+8.4f %+8.4f %+8.5f %+8.5f | %7.5f %s"
          % (k, b0, b1, b2, A1, A2, r, note))

print("\n  (a pole radius >= 1 would be UNSTABLE and would falsify the decode outright)")

# --- the cascade magnitude response, with and without the NN+5 cell as a x2 makeup ---
print("\nCASCADE MAGNITUDE RESPONSE (dB), five sections in series")
print("  NN+5 is 0x800000 in all five sections = 2.0 at the b-scale 2^22.  The b's are")
print("  stored PRE-HALVED, so a x2 per section is exactly what restores unity.  Both")
print("  readings are printed; the flat-at-0dB column is the one a sane EQ preset gives.")
print("\n     f(Hz)   NN+5 unused   NN+5 = x2 makeup")
for f in [31.25, 62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]:
    z = cmath.exp(-2j * math.pi * f / FS)
    h = 1.0
    for b0, b1, b2, A1, A2 in secs:
        num = b0 + b1 * z + b2 * z * z
        den = 1.0 - A1 * z - A2 * z * z
        h *= num / den
    db = 20 * math.log10(abs(h)) if abs(h) > 0 else -999
    db2 = 20 * math.log10(abs(h) * 32) if abs(h) > 0 else -999   # x2 per section, 5 sections
    print("  %8.1f   %+9.2f     %+9.2f" % (f, db, db2))
