#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""position_sensitivity.py -- a SPECULATIVE, honest characterization of the one number the
L7A1429 decode cannot supply: the absolute scale of POSITION (HLE-GUIDE §8.1, "the single most
valuable missing number").  It is nowhere in the ROM and only a hardware trace would pin it.

Rather than invent a value, this USES the HLE to answer two things that do not need hardware:

  (1) WHAT the constant controls -- audibly and spectrally.  In a physical resonator, exciting
      or picking at a fraction p of the length is a comb filter with nulls at every harmonic n
      where n*p is an integer (the classic "pickup position" signature).  So the POSITION scale
      chooses which harmonics the voice suppresses -- its timbre, not its pitch.  We measure the
      comb nulls the HLE produces as position sweeps, confirming the signature.

  (2) The PHYSICAL BOUND on the scale.  A pickup fraction is in (0, 1): the tap cannot exceed
      the resonator length.  With the register's known log-domain span, that bounds the scale
      constant to a range -- a speculative bracket, clearly graded, not a measurement.

    python3 wsa1/hle/position_sensitivity.py

⚠ Everything here is GRADED SPECULATIVE except the comb arithmetic.  It does not close §8.1; it
characterizes it, so a future hardware trace knows exactly what it is pinning.
stdlib + numpy.
"""
import math
import os
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import l7a1429_hle as L                                                  # noqa: E402

FS = L.FS


def comb_nulls(note, position, fs=FS):
    """Render a resonator with the pickup at `position` (fraction of the loop) and return the
    harmonics that are SUPPRESSED (the comb nulls)."""
    y = L.synth_channel(note, dur=1.0, sub_gain=0.0, position=position,
                        muting_cut_hz=12000, feedback=0.9995)
    n = 1 << int(math.log2(len(y)))
    m = np.abs(np.fft.rfft(y[:n] * np.hanning(n)))
    f0 = 440.0 * 2 ** ((note - 69) / 12)
    harm = []
    for k in range(1, 17):
        b = int(round(k * f0 * n / fs))
        if b < len(m):
            harm.append(m[b])
    harm = np.array(harm) / (max(harm) + 1e-12)
    nulls = [i + 1 for i, h in enumerate(harm) if h < 0.15]
    return harm, nulls


def main():
    print("POSITION as a pickup comb (note A4=440); harmonic amplitudes, then the suppressed set:")
    print("pos    h1..h12 (normalized)                                    suppressed harmonics")
    for p in (0.10, 0.20, 0.25, 0.333, 0.50):
        harm, nulls = comb_nulls(69, p)
        bar = " ".join("%3.0f" % (100 * h) for h in harm[:12])
        # a pickup at fraction p classically nulls harmonic n = round(1/p) and multiples
        predicted = [n for n in range(1, 13) if abs((n * p) - round(n * p)) < 0.06 and n * p >= 0.9]
        print("%.3f  %s   nulls~%s  (pred n=%s)" % (p, bar, nulls[:6], predicted[:6]))

    print("\nWHAT THE SCALE CONTROLS: as the pickup fraction moves, the comb nulls move -- the")
    print("timbre changes while the pitch (set by TUNING, not POSITION) does not.  That is the")
    print("audible role of the missing POSITION-scale constant.")

    # Physical bound on the scale, graded SPECULATIVE.
    # POSITION register 0x00C0: log-domain, 3072 counts/octave, range [0, 0x7F00] (HLE-GUIDE §5).
    span_octaves = 0x7F00 / 3072.0
    print("\nPHYSICAL BOUND (speculative): register span = 0x7F00/3072 = %.2f octaves of period."
          % span_octaves)
    print("A pickup fraction must lie in (0,1], so the scale C (samples per unit) satisfies")
    print("C * 2^(v/3072) <= fundamental_period for all in-range v -- i.e. C is bounded above by")
    print("the shortest note's period divided by the largest POSITION value used.  The exact C")
    print("still needs one hardware read (§8.1); this brackets it, it does not pin it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
