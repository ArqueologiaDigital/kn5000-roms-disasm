#!/usr/bin/env python3
"""peq_ab.py -- the analytic target for the decode test.

Three LIVE C-RAM captures of PARAMETRIC EQ, taken by driving the real panel:

  FLAT   the preset as PARAMETRIC EQ loads it   (band0 FC 125 Hz, Q 2.0, G  0.0 dB)
  FC16K  VALUE-up x24 on the FC row             (band0 FC 16K Hz, Q 2.0, G  0.0 dB)
  G12    VALUE-up x24 on the G  row             (band0 FC 125 Hz, Q 2.0, G +12.0 dB)

Format (notes/kn5000-dsp-biquad-coeffs.md sect.3, already solved):
  NN+0 b1, NN+1 b0, NN+2 b2   x2^22 and PRE-HALVED
  NN+3 -a1/a0                 x2^22
  NN+4 -a2/a0                 x2^23
  NN+5 x2 make-up             x2^22   (sect.127 correction)

y = b0*x + b1*x1 + b2*x2 + A1*y1 + A2*y2
"""
import cmath
import math

FS = 44100.0

FLAT = [0xC04B34, 0x200000, 0x1FB760, 0x7F6996, 0x81227A, 0x800000,
        0xC09AE0, 0x200000, 0x1F6F6C, 0x7ECA3E, 0x824250, 0x800000,
        0xC14746, 0x200000, 0x1EE18C, 0x7D7172, 0x8479CA, 0x800000,
        0xC2D20A, 0x1FFFF8, 0x1DCE4E, 0x7A5C04, 0x88C6AE, 0x800000,
        0xC69D20, 0x200000, 0x1BCC2C, 0x72C5C0, 0x90CF4C, 0x800000]
G12 = list(FLAT)
G12[0:6] = [0xC0515C, 0x20691C, 0x1F481C, 0x7F6996, 0x81227A, 0x800000]
FC16K = list(FLAT)
FC16K[0:6] = [0x2303C4, 0x200000, 0x15CA92, 0xB9F876, 0xA8D5B0, 0x800000]


def s24(v):
    return v - 0x1000000 if v & 0x800000 else v


def secs(cram):
    out = []
    for k in range(5):
        r = cram[6 * k:6 * k + 6]
        out.append((s24(r[1]) / 2.0**22, s24(r[0]) / 2.0**22, s24(r[2]) / 2.0**22,
                    s24(r[3]) / 2.0**22, s24(r[4]) / 2.0**23, s24(r[5]) / 2.0**22))
    return out


def H(cram, f):
    z = cmath.exp(-2j * math.pi * f / FS)
    h = 1.0
    for b0, b1, b2, A1, A2, mk in secs(cram):
        h *= (b0 + b1 * z + b2 * z * z) / (1.0 - A1 * z - A2 * z * z) * mk
    return h


def db(x):
    return 20 * math.log10(abs(x)) if abs(x) > 1e-30 else -999.0


print("SECTION 0 COEFFICIENTS -- what each panel edit moved\n")
print("  cell        FLAT      G=+12dB    FC=16kHz     role")
names = ["b1 (num)", "b0 (num)", "b2 (num)", "-a1/a0 (den)", "-a2/a0 (den)", "x2 makeup"]
for i in range(6):
    tag = ""
    if G12[i] != FLAT[i] and FC16K[i] != FLAT[i]:
        tag = "  <- moved by BOTH"
    elif G12[i] != FLAT[i]:
        tag = "  <- moved by GAIN only"
    elif FC16K[i] != FLAT[i]:
        tag = "  <- moved by FC only"
    print("  0x%02X   %8s   %8s   %8s     %-13s%s"
          % (i, "%06X" % FLAT[i], "%06X" % G12[i], "%06X" % FC16K[i], names[i], tag))

print("\n  ★ The GAIN edit moved the NUMERATOR ONLY and left 0x03/0x04 bit-identical.")
print("    That is the signature of this designer's gain-independent denominator")
print("    (a0 = 1 + K/Q + K^2, a1 = 2(K^2-1), a2 = 1 - K/Q + K^2) and it independently")
print("    confirms cells 0,1,2 = numerator and 3,4 = denominator.")

print("\n\nCASCADE MAGNITUDE RESPONSE (dB) -- THE ANALYTIC TARGET\n")
print("      f(Hz)      FLAT     G=+12dB    FC=16kHz")
fs = [31.25, 62.5, 88, 125, 177, 250, 500, 1000, 2000, 4000, 8000, 16000, 20000]
for f in fs:
    print("  %9.1f  %+8.2f  %+8.2f  %+8.2f" % (f, db(H(FLAT, f)), db(H(G12, f)), db(H(FC16K, f))))

# locate the peak of the G12 response
best_f, best_d = 0.0, -999.0
f = 20.0
while f < 20000.0:
    d = db(H(G12, f))
    if d > best_d:
        best_d, best_f = d, f
    f *= 1.0005
print("\n  G=+12dB  PEAK: %+.2f dB at %.1f Hz" % (best_d, best_f))
print("  FLAT     max deviation from 0 dB over 20 Hz..20 kHz: %.3f dB"
      % max(abs(db(H(FLAT, x))) for x in [20 * 1.05**i for i in range(140)]))
print("  FC=16kHz max deviation from 0 dB: %.3f dB"
      % max(abs(db(H(FC16K, x))) for x in [20 * 1.05**i for i in range(140)]))
print("""
  ⇒ THE TEST TARGET.  FLAT and FC=16kHz are both essentially exact pass-throughs
    (numerator == denominator per section, because G = 0.0 dB makes H(z) = 1 whatever
    the centre frequency is).  ONLY the G=+12 dB capture has a feature to look for.
    A chip that merely passes its input through scores IDENTICALLY on FLAT and on
    FC=16kHz, and is separated ONLY by the G=+12 dB run -- which is what makes that
    run, and not the other two, the actual discriminator.""")
