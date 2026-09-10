#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""render_l7a1429_demo.py -- render the acoustic-model HLE to WAV so the resonator can be
heard.  WAVs are regenerable (this is the recipe); write to a scratch dir.

    python3 wsa1/hle/render_l7a1429_demo.py [OUTDIR]     # default /tmp
"""
import os
import sys
import wave
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import l7a1429_hle as L                                                  # noqa: E402

FS = int(L.FS)


def write_wav(path, y):
    y = np.clip(y, -1.0, 1.0)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((y * 32767.0).astype("<i2").tobytes())
    return path


def melody(notes, per=0.9, **kw):
    out = []
    for n in notes:
        out.append(L.synth_channel(n, dur=per, **kw))
    return np.concatenate(out)


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp"
    os.makedirs(outdir, exist_ok=True)
    scale = [60, 62, 64, 65, 67, 69, 71, 72]
    demos = {
        # a bright, lightly-damped "string": high MUTING cutoff, long feedback, sub coupling
        "string":   dict(muting_cut_hz=8000, feedback=0.9992, sub_gain=0.7, sub_detune_cents=-6),
        # a darker, faster-decaying "membrane/plate": low cutoff, shorter feedback
        "membrane": dict(muting_cut_hz=1500, feedback=0.995,  sub_gain=1.0, sub_detune_cents=-12),
        # a hollow "cylinder": mid cutoff, off-centre POSITION pickup
        "cylinder": dict(muting_cut_hz=4000, feedback=0.9990, sub_gain=0.5, position=0.28),
    }
    for name, kw in demos.items():
        y = melody(scale, **kw)
        p = write_wav(os.path.join(outdir, "l7a1429_%s.wav" % name), y)
        print("wrote %-30s peak=%.3f rms=%.3f  (%d notes)" %
              (p, np.max(np.abs(y)), np.sqrt(np.mean(y * y)), len(scale)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
