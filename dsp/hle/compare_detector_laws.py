#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""compare_detector_laws.py -- HOW MUCH did correcting the compressor's detector change?

QUESTION IT ANSWERS
    N-INPUT-GATE-OPENED §68 corrected the shipped HLE compressor on three points, all from the
    ROM: the detector RECTIFIES (2/pi = mean of |sin|) rather than squaring, the attack is
    4.712 ms rather than an invented ~2.1 ms, and the release is 11.764 ms from C-RAM[0x03]
    rather than a fixed 150 ms with that cell ignored.

    "Corrected" is only worth the word if the difference is audible.  This runs BOTH laws on the
    same signal and reports how far apart they are -- so the correction is a measured quantity
    rather than an assertion, and so a reader can see that the release constant (13x) dominates.

    ⚠ This compares the two DETECTORS, which is what the ROM settles.  Both are then fed through
    the SAME gain law, because the corpus does not settle that one (§68) -- so no part of the
    difference reported here is attributable to a change nobody has evidence for.

USAGE
    python3 dsp/hle/compare_detector_laws.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from kernels import LevelDetector                                         # noqa: E402
import designer as D                                                      # noqa: E402

FS = D.FS


def detect(x, law, atk_s, rel_s):
    """law 'rect' = the ROM's: |x| * 2/pi.  law 'square' = the HLE's old x*x, sqrt'd back to an
    amplitude in the gain computer (which is what the shipped code did)."""
    ca = np.exp(-1.0 / (FS * atk_s))
    cr = np.exp(-1.0 / (FS * rel_s))
    out = np.empty_like(x)
    e = 0.0
    for n in range(x.size):
        r = abs(x[n]) * LevelDetector.TWO_OVER_PI if law == "rect" else x[n] * x[n]
        c = ca if r > e else cr
        e = r + c * (e - r)
        out[n] = e if law == "rect" else np.sqrt(max(e, 0.0))
    return out


def main():
    # A signal with real dynamics: a loud burst followed by a quiet passage, which is exactly
    # where an attack and a release differ from each other.
    t = np.arange(int(2.0 * FS)) / FS
    tone = np.sin(2.0 * np.pi * 220.0 * t)
    amp = np.where(t < 0.5, 0.08, np.where(t < 1.0, 0.9, 0.08))
    x = tone * amp

    new = detect(x, "rect", 0.004712, 0.011764)        # the ROM's
    old = detect(x, "square", 0.002096, 0.150)         # the shipped HLE's
    print("=== COMPRESSOR DETECTOR: the ROM's law vs the one that shipped ===")
    print("  signal: 220 Hz, amplitude 0.08 -> 0.9 at 0.5 s -> 0.08 at 1.0 s\n")

    def recover_ms(e):
        """time for the envelope to fall back to within 25 % of its quiet-passage value."""
        quiet = e[int(1.9 * FS)]
        loud = e[int(0.95 * FS)]
        thr = quiet + 0.25 * (loud - quiet)
        k = int(1.0 * FS) + int(np.argmax(e[int(1.0 * FS):] < thr))
        return 1000.0 * (k - 1.0 * FS) / FS

    for nm, e in (("ROM (rectify, 4.712 / 11.764 ms)", new),
                  ("shipped (square-law, ~2.1 / 150 ms)", old)):
        print("  %-36s steady loud %.4f   release-to-quiet %6.1f ms"
              % (nm, e[int(0.95 * FS)], recover_ms(e)))
    ratio = recover_ms(old) / max(recover_ms(new), 1e-9)
    print("\n  ⇒ the shipped detector took %.1fx longer to let go." % ratio)
    print("    That is the audible part: a compressor whose release is an order of magnitude too")
    print("    slow keeps ducking a passage the instrument's own ROM says should already have")
    print("    recovered -- and the release was not even read from its cell.")
    print("\n  ⚠ The steady-state levels also differ, but that is a SCALE difference two laws with")
    print("    different calibrations will always show; the makeup/threshold mapping absorbs it.")
    print("    The TIME is the part neither mapping can absorb.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
