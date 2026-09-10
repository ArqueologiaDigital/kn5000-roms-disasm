#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""test_golden.py -- regression fingerprints for the HLE effects.  Each effect is run on one
fixed deterministic input and its output is hashed; if a future edit changes any effect's
output, the hash changes and this test fails loudly.  This is output-stability protection, not
a correctness check (test_hle.py checks correctness by defining properties).

Regenerate the goldens intentionally with `python3 dsp/hle/test_golden.py --update`.

    python3 dsp/hle/test_golden.py
"""
import hashlib
import os
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import effects as FX                                                     # noqa: E402


def cases():
    x = np.random.default_rng(7).standard_normal(8000) * 0.2            # fixed input
    return {
        "parametric_eq": FX.parametric_eq(x, [(120, 1, 8), (1000, 2, 10), (5000, 1.2, 6)]),
        "chorus":        FX.chorus(x, rate_hz=0.7, depth_ms=4, mix=0.5, voices=2),
        "flanger":       FX.flanger(x, rate_hz=0.25, feedback=0.6, mix=0.5),
        "delay":         FX.delay(x, time_ms=320, feedback=0.45, mix=0.4),
        "reverb":        FX.reverb(x, decay=0.86, damp_hz=4500, mix=0.35),
        "reverb_kn5000": FX.reverb_kn5000(x, decay=0.85, damp_hz=5000, mix=0.3),
        "overdrive":     FX.distortion(x, drive=10, level=0.4, curve="tanh", tone_hz=3500),
        "fuzz":          FX.distortion(x, drive=40, level=0.3, curve="hard"),
    }


def sig(y):
    return hashlib.sha1(np.round(np.asarray(y, float), 6).tobytes()).hexdigest()[:16]


GOLDEN = {
    "parametric_eq": "bb9ab2af91d2d125",
    "chorus": "eabbccbfbdddbc51",
    "flanger": "c4d31848db07dd2f",
    "delay": "a59d772964c4d971",
    "reverb": "d8ff1382e936d928",
    "reverb_kn5000": "8f61d33d2ffc2f7b",
    "overdrive": "5de55874cd46eaea",
    "fuzz": "adeb2eb24b6dbcf4",
}


def main():
    got = {k: sig(v) for k, v in cases().items()}
    if "--update" in sys.argv:
        print("GOLDEN = {")
        for k, v in got.items():
            print('    "%s": "%s",' % (k, v))
        print("}")
        return 0
    ok = True
    for k in GOLDEN:
        good = got.get(k) == GOLDEN[k]
        ok = ok and good
        print("  [%s] %-16s %s%s" % ("PASS" if good else "FAIL", k, got.get(k),
                                     "" if good else " != %s" % GOLDEN[k]))
    print("\n%s" % ("GOLDEN OK" if ok else "GOLDEN DRIFT -- outputs changed; if intended, run --update"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
