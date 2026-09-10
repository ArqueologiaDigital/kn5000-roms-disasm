#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""test_hle.py -- validate each HLE kernel/effect by its DEFINING property.  No hardware;
each check is analytic or signal-based, so the reference model is self-verifying.

    python3 dsp/hle/test_hle.py
"""
import math
import sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from kernels import BiquadDF1, LFO, DelayLine, waveshape                # noqa: E402
import designer as D                                                     # noqa: E402
import effects as FX                                                     # noqa: E402

FS = D.FS
PASS = True


def check(name, ok, detail=""):
    global PASS
    PASS = PASS and ok
    print("  [%s] %-42s %s" % ("PASS" if ok else "FAIL", name, detail))


def fft_mag(y):
    return np.abs(np.fft.rfft(y))


def bin_at(freq, n, fs=FS):
    return int(round(freq * n / fs))


def main():
    rng = np.random.default_rng(1)
    n = 16384

    # 1. Peaking-EQ biquad: analytic response must peak +12 dB at f0, and the measured
    #    impulse-response FFT must agree with the analytic response.
    print("Parametric-EQ biquad (bilinear peaking designer):")
    f0, Q, g = 1000.0, 2.0, 12.0
    bq = BiquadDF1(*D.biquad_peaking(f0, Q, g))
    imp = np.zeros(n); imp[0] = 1.0
    h = bq.process(imp)
    meas = fft_mag(h)
    peak_db = 20 * math.log10(meas[bin_at(f0, n)] + 1e-12)
    check("peak gain at f0 = +12 dB", abs(peak_db - g) < 0.5, "measured %.2f dB" % peak_db)
    lo = 20 * math.log10(meas[bin_at(80, n)] + 1e-12)
    check("unity (~0 dB) far below f0", abs(lo) < 0.7, "%.2f dB @80Hz" % lo)
    bq2 = BiquadDF1(*D.biquad_peaking(f0, Q, g))
    ana = 20 * np.log10(bq2.response([80, 1000, 8000], FS) + 1e-12)
    meas3 = 20 * np.log10(np.array([meas[bin_at(f, n)] for f in (80, 1000, 8000)]) + 1e-12)
    check("impulse FFT == analytic response", np.max(np.abs(ana - meas3)) < 0.3,
          "max dev %.3f dB" % np.max(np.abs(ana - meas3)))
    cut = BiquadDF1(*D.biquad_peaking(f0, Q, -12.0))
    cdb = 20 * math.log10(cut.response([f0], FS)[0] + 1e-12)
    check("cut of -12 dB at f0", abs(cdb + 12.0) < 0.5, "%.2f dB" % cdb)

    # 2. LFO: dominant spectral bin is the requested rate.
    print("LFO (phase accumulator -> waveform):")
    for rate in (0.8, 5.0):
        y = LFO(rate, FS, "sine").block(n)
        k = np.argmax(fft_mag(y)[1:]) + 1
        check("LFO %.1f Hz peaks at right bin" % rate, abs(k - bin_at(rate, n)) <= 1,
              "bin %d vs %d" % (k, bin_at(rate, n)))

    # 3. Delay line: an impulse comes back after exactly the delay time.
    print("Delay line (ring buffer):")
    N = int(D.ms_to_samples(100.0))
    dl = DelayLine(N + 4)
    got = None
    for i in range(N + 10):
        dl.push(1.0 if i == 0 else 0.0)
        r = dl.read(N)
        if r > 0.5 and got is None:
            got = i
    check("100 ms echo returns at N samples", got == N, "at %s (N=%d)" % (got, N))

    # 4. All-pass diffuser: flat magnitude response (the reverb all-pass property, §5).
    print("All-pass diffuser (reverb ladder, KN5000):")
    ap = FX._Allpass(int(D.ms_to_samples(5.0)), 0.7)
    imp = np.zeros(n)
    y = np.array([ap.tick(1.0 if i == 0 else 0.0) for i in range(n)])
    mag = fft_mag(y)
    band = mag[bin_at(200, n):bin_at(8000, n)]
    flat = (band.max() - band.min()) / band.mean()
    check("all-pass magnitude is flat", flat < 0.05, "ripple %.4f" % flat)
    check("all-pass energy ~ unity", abs(np.sum(y * y) - 1.0) < 1e-6,
          "E=%.6f" % np.sum(y * y))

    # 5. Distortion: odd, monotonic, and it ADDS harmonics to a pure tone.
    print("Distortion (waveshaper, §7d):")
    xs = np.linspace(-2, 2, 401)
    ws = waveshape(xs, drive=3.0)
    check("waveshaper monotonic", np.all(np.diff(ws) >= -1e-9))
    check("waveshaper odd", np.max(np.abs(ws + waveshape(-xs, drive=3.0))) < 1e-9)
    t = np.arange(n)
    tone = 0.5 * np.sin(2 * math.pi * 500 * t / FS)
    dist = FX.distortion(tone, drive=8.0, level=1.0, curve="tanh")
    m = fft_mag(dist)
    h3 = m[bin_at(1500, n)] / (m[bin_at(500, n)] + 1e-12)
    check("distortion creates 3rd harmonic", h3 > 0.02, "H3/H1=%.3f" % h3)

    # 6. Reverb: adds a decaying tail longer than the input.
    print("Reverb (Schroeder tank, §5):")
    nfs = int(FS)
    imp = np.zeros(nfs); imp[0] = 1.0
    rv = FX.reverb(imp, decay=0.85, mix=1.0)
    tail = np.sqrt(np.mean(rv[nfs // 2:] ** 2))
    check("reverb has an audible tail at 0.5 s", tail > 1e-4, "rms %.2e" % tail)

    # 7. Parametric EQ (multi-band) runs and boosts its bands.
    print("Parametric EQ (5-band series):")
    bands = [(100, 1.0, 6), (400, 1.5, -4), (1000, 2.0, 8), (3000, 1.5, -6), (8000, 1.0, 5)]
    imp = np.zeros(n); imp[0] = 1.0
    h = FX.parametric_eq(imp, bands)
    m = 20 * np.log10(fft_mag(h) + 1e-12)
    check("EQ boosts 1 kHz band", m[bin_at(1000, n)] > 5.0, "%.1f dB" % m[bin_at(1000, n)])
    check("EQ cuts 3 kHz band", m[bin_at(3000, n)] < -3.0, "%.1f dB" % m[bin_at(3000, n)])

    print("\n%s" % ("ALL HLE CHECKS PASSED" if PASS else "SOME CHECKS FAILED"))
    return 0 if PASS else 1


if __name__ == "__main__":
    sys.exit(main())
