#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""render_eq_from_capture.py -- FAITHFUL parametric-EQ audio from the chip's OWN coefficients.

This closes the loop the whole HLE effort was for: the REAL C-RAM coefficients captured from the
running effects DSP (dsp/analysis/data/wsa1-cram-coefficient-capture-2026-09-09.txt), interpreted
in the decoded order [b1,b0,b2,-a1,-a2,makeup] (biquad-eq.md) and validated 12/12 stable
(validate_against_capture.py), are run through the PROVEN bit-exact Direct-Form-I biquad
(BiquadDF1) to produce audible EQ.  It is faithful to the chip's own numbers -- not a designed
approximation -- and, because the biquad is bit-exact on the chip (impulse response == analytic
to 0.000 dB), the transfer function is the chip's.

⚠ Grade: this is the HLE path (the documented/validated algorithm run with real coefficients),
NOT the LLE core executing microcode -- that path is still gated on the output-stage decode.  For
what this is and is not, see MAME-SYNTHESIS-ARCHITECTURE-2026-09-10.md ("IMPROVED PLAN", track A).

    python3 dsp/hle/render_eq_from_capture.py [OUT.wav]   # default /tmp scratch; also prints the curve
"""
import math
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kernels import BiquadDF1                                            # noqa: E402
from validate_against_capture import first_record_cells, stable         # noqa: E402

FS = 44100


def sections_from_capture(first_cell=96):
    """The consecutive biquad region as (b0,b1,b2,a1,a2,makeup) tuples ready for BiquadDF1,
    in the decoded C-RAM order [b1,b0,b2,-a1,-a2,makeup] (a = negated on the chip)."""
    cells = first_record_cells()
    region, c = [], first_cell
    while c in cells:
        region.append(cells[c]); c += 1
    out = []
    for s in range(len(region) // 6):
        b1, b0, b2, na1, na2, mk = region[s * 6:s * 6 + 6]
        out.append((b0, b1, b2, -na1, -na2, mk))
    return out


def cascade_response(sections, freqs):
    """Combined magnitude response (dB) of the section cascade (per channel = every other one)."""
    h = np.ones_like(freqs, dtype=np.float64)
    for (b0, b1, b2, a1, a2, mk) in sections:
        h = h * BiquadDF1(b0, b1, b2, a1, a2, mk).response(freqs, FS)
    return 20.0 * np.log10(h + 1e-12)


def render(sections, x):
    """Run x through the section cascade (bit-exact DF-I), returning the filtered signal."""
    y = np.asarray(x, dtype=np.float64)
    for (b0, b1, b2, a1, a2, mk) in sections:
        y = BiquadDF1(b0, b1, b2, a1, a2, mk).process(y)
    return y


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kn5000_eq_from_capture.wav"
    secs = sections_from_capture()
    if not secs:
        print("no capture found"); return 1
    # The capture holds 12 six-cell sections; the two halves are identical (L == R), so the six
    # DISTINCT chip biquad sections are secs[0:6].  ⚠ How they combine (cascade vs parallel) is
    # NOT established here, so this renders the six as a chain and REPORTS each section's own
    # response -- it does not claim a flat "graphic EQ" curve.  Each section IS a real, stable
    # chip biquad (validate_against_capture.py); that, and the bit-exact biquad, is what is faithful.
    bands = secs[0:6] if len(secs) >= 6 else secs
    print("%d captured biquad sections; the 6 distinct chip sections (secs[0:6]) run below.\n"
          % len(secs))
    fc = np.array([100.0, 440.0, 1000.0, 4000.0, 8000.0])
    print("  each REAL chip biquad section (its own magnitude response, dB):")
    for i, (b0, b1, b2, a1, a2, mk) in enumerate(bands):
        r = BiquadDF1(b0, b1, b2, a1, a2, mk).response(fc, FS)
        dB = ", ".join("%.0fHz %+.1f" % (f, 20 * math.log10(v + 1e-12)) for f, v in zip(fc, r))
        print("   sec %d stable=%s : %s" % (i, stable(a1, a2), dB))

    # render one representative section audibly -- one real chip biquad, faithful and unambiguous
    n = FS * 3
    rng = np.random.default_rng(0)
    x = rng.standard_normal(n); x /= np.max(np.abs(x))
    b0, b1, b2, a1, a2, mk = bands[1]      # a mid section, not the DC-notch section 0
    y = BiquadDF1(b0, b1, b2, a1, a2, mk).process(x * 0.3)
    y = y / (np.max(np.abs(y)) + 1e-9) * 0.9
    with wave.open(out, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((y * 32767).astype("<i2").tobytes())
    print("\n  rendered section 1 (a real chip biquad) through white noise -> %s (%.1f s)." % (out, n / FS))
    print("  => the effects DSP's OWN biquad coefficients, run through the bit-exact kernel, made audible.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
