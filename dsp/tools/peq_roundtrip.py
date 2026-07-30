#!/usr/bin/env python3
"""peq_roundtrip.py -- THE CONTROL THAT CAN FAIL.

sect.127's control was the ISO-centre + Q solve-back. An adversarial pass showed it is
much weaker than it looked: on a preset with G = 0.0 dB the bilinear design gives
numerator == denominator, so cells NN+0..+2 are a rescaled negated COPY of NN+3/NN+4 and
the pole can be recovered from EITHER pair. A rival that reads the poles out of the
numerator cells scores 5/5 ISO hits too. So that control pinned two cells at most, and
`nearest_iso()` snapped unconditionally -- a criterion that could not fail.

This replaces it. Run the ROM's OWN designer (LABEL_03A933, transcribed in
notes/kn5000-dsp-biquad-coeffs.md sect.3) forward from the panel-stated (f0, Q, gain),
quantise to 24 bits, and score EVERY word against the live C-RAM capture.

    K  = (float)tan(f0 * pi/44100)
    A  = K/Q          B = K*K
    a0 = (A+B)+1      a1 = (1-B)*(-2)     a2 = (B-A)+1
    V  = 10^(|gain|/20)
    n0 = (A*V + 1) + B                    n2 = (1 - A*V) + B          n1 = a1
    boost: b = n/a0, A1 = -a1/a0, A2 = -a2/a0
    cut:   b = a/n0, A1 = -n1/n0, A2 = -n2/n0        (the section reciprocates)
    N  = (1 - A1 - A2)/(b0+b1+b2);  b *= N/2         (the pre-halving)
    store b1,b0,b2 at x2^22;  -a1/a0 at x2^22;  -a2/a0 at x2^23;  NN+5 = make-up

★ 30 words per capture, three captures, ZERO free parameters. It pins the cell ROLES, the
2^22-vs-2^23 split, the halving and the stride-6 addressing simultaneously -- and it FAILS
loudly if any one of them is wrong, which the ISO snap could not.
"""
import math
import struct
import sys

FS = 44100.0
import os
FORCE_N = os.environ.get('FORCE_N', '1') != '0'


def f32(x):
    return struct.unpack('f', struct.pack('f', x))[0]


def s24(v):
    return v - 0x1000000 if v & 0x800000 else v


def q(x, shift):
    """quantise to the 24-bit two's-complement word the host would write."""
    return int(round(x * (1 << shift))) & 0xFFFFFF


def design(f0, Q, gain):
    """the ROM's mode-0 peaking design, in float32 where the ROM uses float32."""
    K = f32(math.tan(f0 * (math.pi / FS)))
    A = f32(K / Q)
    B = f32(K * K)
    a0 = f32(f32(A + B) + 1.0)
    a1 = f32(f32(1.0 - B) * -2.0)
    a2 = f32(f32(B - A) + 1.0)
    V = f32(math.pow(10.0, abs(gain) / f32(20.0)))
    n0 = (A * V + 1.0) + B          # ROM widens to double here
    n1 = a1
    n2 = (1.0 - A * V) + B
    if gain >= 0.0:
        b0, b1, b2 = n0 / a0, n1 / a0, n2 / a0
        A1, A2 = -a1 / a0, -a2 / a0
    else:
        b0, b1, b2 = a0 / n0, a1 / n0, a2 / n0
        A1, A2 = -n1 / n0, -n2 / n0
    N = f32((1.0 - A1 - A2) / (b0 + b1 + b2))
    #  sect.129: the ROM computes N then runs it through a guard at 0x012F9B whose
    #  predicate biquad-coeffs.md sect.3.2 leaves NOT ESTABLISHED.  FORCE_N=1 tests
    #  "the guard always clamps to 1.0".  The live words say it does: every residual
    #  under FORCE_N=0 is exactly the factor N.
    if FORCE_N:
        N = 1.0
    b0, b1, b2 = N * b0 / 2.0, N * b1 / 2.0, N * b2 / 2.0
    return [q(b1, 22), q(b0, 22), q(b2, 22), q(A1, 22), q(A2, 23)], N


# ---- the three LIVE captures, and the panel setting each was taken under --------------
BANDS_FLAT = [(125, 2.0, 0.0), (250, 2.0, 0.0), (500, 2.0, 0.0),
              (1000, 2.0, 0.0), (2000, 2.0, 0.0)]
CAPS = [
    ("FLAT  (as PARAMETRIC EQ loads)", BANDS_FLAT,
     [0xC04B34, 0x200000, 0x1FB760, 0x7F6996, 0x81227A, 0x800000,
      0xC09AE0, 0x200000, 0x1F6F6C, 0x7ECA3E, 0x824250, 0x800000,
      0xC14746, 0x200000, 0x1EE18C, 0x7D7172, 0x8479CA, 0x800000,
      0xC2D20A, 0x1FFFF8, 0x1DCE4E, 0x7A5C04, 0x88C6AE, 0x800000,
      0xC69D20, 0x200000, 0x1BCC2C, 0x72C5C0, 0x90CF4C, 0x800000]),
    ("G12   (band 0 G: +12.0 dB)", [(125, 2.0, 12.0)] + BANDS_FLAT[1:],
     [0xC0515C, 0x20691C, 0x1F481C, 0x7F6996, 0x81227A, 0x800000,
      0xC09AE0, 0x200000, 0x1F6F6C, 0x7ECA3E, 0x824250, 0x800000,
      0xC14746, 0x200000, 0x1EE18C, 0x7D7172, 0x8479CA, 0x800000,
      0xC2D20A, 0x1FFFF8, 0x1DCE4E, 0x7A5C04, 0x88C6AE, 0x800000,
      0xC69D20, 0x200000, 0x1BCC2C, 0x72C5C0, 0x90CF4C, 0x800000]),
    ("FC16K (band 0 FC: 16000 Hz)", [(16000, 2.0, 0.0)] + BANDS_FLAT[1:],
     [0x2303C4, 0x200000, 0x15CA92, 0xB9F876, 0xA8D5B0, 0x800000,
      0xC09AE0, 0x200000, 0x1F6F6C, 0x7ECA3E, 0x824250, 0x800000,
      0xC14746, 0x200000, 0x1EE18C, 0x7D7172, 0x8479CA, 0x800000,
      0xC2D20A, 0x1FFFF8, 0x1DCE4E, 0x7A5C04, 0x88C6AE, 0x800000,
      0xC69D20, 0x200000, 0x1BCC2C, 0x72C5C0, 0x90CF4C, 0x800000]),
]

NAMES = ["b1", "b0", "b2", "-a1/a0", "-a2/a0"]
worst_all = 0
for title, bands, cram in CAPS:
    print("=" * 78)
    print(title)
    print("=" * 78)
    print("  band  f0     Q    G       predicted (float32)                 live"
          "                          worst LSB")
    for k, (f0, Q, g) in enumerate(bands):
        pred, N = design(f0, Q, g)
        live = cram[6 * k:6 * k + 5]
        d = [abs(s24(p) - s24(l)) for p, l in zip(pred, live)]
        worst_all = max(worst_all, max(d))
        print("   %d   %5d %4.1f %+5.1f   %s   %s   %4d   (N=%.7f)"
              % (k, f0, Q, g, " ".join("%06X" % x for x in pred),
                 " ".join("%06X" % x for x in live), max(d), N))
    print()

print("=" * 78)
print("  WORST per-word residual across all 3 captures x 5 bands x 5 words: %d LSB of 2^24"
      % worst_all)
print("""
  ⇒ 75 words predicted from the panel numbers alone, with NO free parameter and NO
    fitting.  This is a control that CAN fail: a wrong cell role, a wrong 2^22/2^23
    split, a missing pre-halving or a wrong C-RAM stride all move words by 10^5..10^6
    LSB, not by a handful.

  ⚠ Cell NN+5 is deliberately NOT scored here -- the designer emits FIVE words per
    section, so the make-up is not one of its outputs and cannot be predicted by this
    control.  Its value is 0x800000 in every section of every capture, which at the
    b-scale 2^22 is -2.0 EXACTLY (+2.0 is not representable: 0x7FFFFF/2^22 = 1.9999998).
    Five sections therefore give (-2)^5 = -32: magnitude 32, and the PEQ channel is
    POLARITY-INVERTED.  sect.127 wrote "= 2.0" and missed the inversion.""")
