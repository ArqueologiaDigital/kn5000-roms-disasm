#!/usr/bin/env python3
"""chorus_wet_ab.py -- did a change to the HLE chorus's WET GAIN move the modulation depth as predicted?

QUESTION IT ANSWERS
    kn5000_tonegen.cpp's chorus wet gain was read as `q22c(cell 0x09) * cs` (Q22 of the chip cell,
    0.303) and is now read at Q23 (`* 0.5`, 0.152), because the seeded LLE traces pin the chip's
    coefficient field at Q23 (dsp/analysis/N-SINGLE-DELAY-RECURRENCE-2026-09-12 S6-S7).  A chorus's
    comb notches sweep the harmonics, so each held harmonic is amplitude-modulated at the LFO rate
    with a depth that grows with the wet level; halving the wet gain should roughly halve the
    LFO-band modulation strength that chorus_ab.py measures (same rig, same note, same rate).

    python3 dsp/tools/chorus_wet_ab.py before.wav after.wav [band_lo_Hz band_hi_Hz]

    BEFORE = the previous binary (~/compartilhado/kn7000-emulator), AFTER = the rebuilt one, both:
      DISPLAY=:0 DHLE=3 DSPCFG=2 TYPEIDX=0 ./kn7000 kn5000 -rompath <roms> -skip_gameinfo -window \
        -autoboot_script dsp/tools/chorus_ab.lua -wavwrite X.wav
    Reports each capture's LFO-band peak (rate, strength) and the after/before strength ratio;
    the rate must be unchanged (same cell 0x00) and the ratio should sit near 0.5.  RULE 12: the
    rig holds a note; RULE 13: the dry null is chorus_ab.py's job -- this compares two WET runs.
"""
import sys
import os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chorus_ab import read_main, loud_window, mod_spectrum   # noqa: E402


def main():
    if len(sys.argv) not in (3, 5):
        print(__doc__); return 2
    band_lo = float(sys.argv[3]) if len(sys.argv) > 3 else 0.35
    band_hi = float(sys.argv[4]) if len(sys.argv) > 4 else 1.1
    res = []
    for path in sys.argv[1:3]:
        fs, x = read_main(path)
        s, e = loud_window(x, fs)
        mf, m = mod_spectrum(x[s:e], fs)
        lo, hi = np.searchsorted(mf, band_lo), np.searchsorted(mf, band_hi)
        k = lo + int(np.argmax(m[lo:hi]))
        rms = float(np.sqrt(np.mean(x[s:e] ** 2)))
        res.append((path, mf[k], float(m[k]), rms))
        print("%-40s window %.2f-%.2fs  rms %.4f  LFO-band peak %.2f Hz  strength %.4f"
              % (os.path.basename(path), s / fs, e / fs, rms, mf[k], m[k]))
    ratio = res[1][2] / (res[0][2] + 1e-12)
    same_rate = abs(res[1][1] - res[0][1]) < 0.1
    print("after/before modulation strength = %.3f  (rate %s: %.2f vs %.2f Hz)"
          % (ratio, "unchanged" if same_rate else "CHANGED", res[0][1], res[1][1]))
    print("VERDICT:", "wet halved as predicted" if same_rate and 0.3 <= ratio <= 0.7
          else "NOT the predicted halving -- inspect")
    return 0


if __name__ == "__main__":
    sys.exit(main())
