#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""showcase.py -- one combined WAV that demonstrates BOTH HLE chips making sound: the effects
DSP (dry -> EQ -> chorus -> delay -> reverb -> overdrive on a chord) and the L7A1429
acoustic-model resonators (a phrase as string / membrane / cylinder).  Regenerable; write to
a scratch dir.

    python3 dsp/hle/showcase.py [OUTFILE.wav]      # default /tmp/kn5000_hle_showcase.wav
"""
import math
import os
import sys
import wave
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "wsa1", "hle"))
import effects as FX                                                     # noqa: E402
import l7a1429_hle as L                                                  # noqa: E402

FS = 44100


def chord(seconds=2.0):
    n = int(FS * seconds); t = np.arange(n) / FS
    y = sum(np.sin(2 * math.pi * f * t) for f in (220, 277.18, 329.63, 440))
    return 0.18 * y * np.exp(-2.0 * (t % 1.0))


def gap(seconds=0.3):
    return np.zeros(int(FS * seconds))


def phrase(voice_kw, notes=(60, 64, 67, 72), per=0.5):
    return np.concatenate([L.synth_channel(nn, dur=per, **voice_kw) for nn in notes])


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kn5000_hle_showcase.wav"
    dry = chord()
    parts = [
        ("effects: dry",       dry),
        ("effects: EQ",        FX.parametric_eq(dry, [(120, 1, 8), (1000, 2, 10), (5000, 1.2, 6)])),
        ("effects: chorus",    FX.chorus(dry, rate_hz=0.7, depth_ms=4, mix=0.5, voices=2)),
        ("effects: delay",     FX.delay(dry, time_ms=300, feedback=0.45, mix=0.4)),
        ("effects: reverb",    FX.reverb_kn5000(dry, decay=0.86, mix=0.4)),
        ("effects: overdrive", FX.distortion(dry, drive=10, level=0.4, curve="tanh", tone_hz=3500)),
        ("acoustic: string",   phrase(dict(muting_cut_hz=8000, feedback=0.9992, sub_gain=0.7, sub_detune_cents=-6))),
        ("acoustic: membrane", phrase(dict(muting_cut_hz=1500, feedback=0.995, sub_gain=1.0, sub_detune_cents=-12))),
        ("acoustic: cylinder", phrase(dict(muting_cut_hz=4000, feedback=0.9990, sub_gain=0.5, position=0.28))),
    ]
    stream = []
    for name, y in parts:
        y = np.asarray(y, float)
        y = y / (np.max(np.abs(y)) + 1e-9) * 0.85
        print("  %-20s %5.2f s" % (name, len(y) / FS))
        stream.append(y); stream.append(gap())
    full = np.clip(np.concatenate(stream), -1, 1)
    with wave.open(out, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((full * 32767).astype("<i2").tobytes())
    print("wrote %s  (%.1f s)" % (out, len(full) / FS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
