#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""render_demo.py -- render each HLE effect on a test signal to a WAV, so the reference
model can be listened to.  WAVs are regenerable (this script is the recipe); write them to a
scratch dir, not the repo.

    python3 dsp/hle/render_demo.py [OUTDIR]      # default: /tmp
"""
import math
import os
import sys
import wave
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import designer as D                                                     # noqa: E402
import effects as FX                                                     # noqa: E402

FS = int(D.FS)


def test_signal(seconds=2.5):
    """A dry test bed: a short major chord with a plucked amplitude envelope, mono."""
    n = int(FS * seconds)
    t = np.arange(n) / FS
    y = np.zeros(n)
    for f in (220.0, 277.18, 329.63, 440.0):                # A3 C#4 E4 A4
        y += np.sin(2 * math.pi * f * t)
    env = np.exp(-2.5 * (t % 1.25))                          # re-pluck every 1.25 s
    return 0.2 * y * env


def write_wav(path, y):
    y = np.clip(y, -1.0, 1.0)
    pcm = (y * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(pcm.tobytes())
    return path


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp"
    os.makedirs(outdir, exist_ok=True)
    dry = test_signal()
    renders = {
        "dry": dry,
        "parametric_eq": FX.parametric_eq(dry, [(120, 1.0, 8), (900, 2.0, -8),
                                                (1000, 2.0, 10), (5000, 1.2, 6)]),
        "chorus": FX.chorus(dry, rate_hz=0.7, depth_ms=4.0, mix=0.5, voices=2),
        "flanger": FX.flanger(dry, rate_hz=0.25, feedback=0.6, mix=0.5),
        "delay": FX.delay(dry, time_ms=320, feedback=0.45, mix=0.4),
        "reverb": FX.reverb(dry, decay=0.86, damp_hz=4500, mix=0.35),
        "overdrive": FX.distortion(dry, drive=10, level=0.4, curve="tanh", tone_hz=3500),
        "fuzz": FX.distortion(dry, drive=40, level=0.3, curve="hard"),
    }
    for name, y in renders.items():
        p = write_wav(os.path.join(outdir, "hle_%s.wav" % name), y)
        print("wrote %-24s peak=%.3f rms=%.3f" % (p, np.max(np.abs(y)), np.sqrt(np.mean(y * y))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
