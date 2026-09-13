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
    # KN5000 all-pass diffuser ladder (§5): dense diffusion + a decaying tail from recirculation
    rvk = FX.reverb_kn5000(imp, decay=0.85, mix=1.0)
    early = np.count_nonzero(np.abs(rvk[:int(0.05 * nfs)]) > 1e-4)
    tailk = np.sqrt(np.mean(rvk[nfs // 2:] ** 2))
    check("KN5000 ladder diffuses (dense early echoes)", early > 100, "%d nonzero in 50 ms (a plain delay gives <10)" % early)
    check("KN5000 ladder decays via recirculation", 1e-5 < tailk, "rms %.2e" % tailk)

    # 7. Parametric EQ (multi-band) runs and boosts its bands.
    print("Parametric EQ (5-band series):")
    bands = [(100, 1.0, 6), (400, 1.5, -4), (1000, 2.0, 8), (3000, 1.5, -6), (8000, 1.0, 5)]
    imp = np.zeros(n); imp[0] = 1.0
    h = FX.parametric_eq(imp, bands)
    m = 20 * np.log10(fft_mag(h) + 1e-12)
    check("EQ boosts 1 kHz band", m[bin_at(1000, n)] > 5.0, "%.1f dB" % m[bin_at(1000, n)])
    check("EQ cuts 3 kHz band", m[bin_at(3000, n)] < -3.0, "%.1f dB" % m[bin_at(3000, n)])

    # ---- the DYNAMICS family (N-INPUT-GATE-OPENED §67; constants read from ROM 0x84CD) ----
    print("\n-- level detector / dynamics (ROM constants)")
    from kernels import LevelDetector
    _D = D
    check("2/pi constant is the ROM's, to the LSB",
          LevelDetector.TWO_OVER_PI == 0x517CC1 / float(1 << 23),
          "0x517CC1 = %.6f" % LevelDetector.TWO_OVER_PI)
    # Defining property 1: the smoother time constants ARE 4.712 ms and 11.764 ms.
    for nm, a, want in (("attack", LevelDetector.A_ATTACK, 4.712),
                        ("release", LevelDetector.A_RELEASE, 11.764)):
        tau = 1000.0 / (a * FS)
        check("detector %s tau = %.3f ms" % (nm, want), abs(tau - want) < 0.002,
              "got %.3f ms" % tau)
    check("designer inverts it", abs(_D.onepole_a_from_seconds(0.004712)
                                     - 0x009DAD / float(1 << 23)) < 1e-6)
    # Defining property 2: the detector is LINEAR in amplitude (it is a rectifier + LPF, so
    # doubling the input must double the settled envelope).  This is what makes it a LEVEL
    # detector rather than a waveshaper, and it is the property the compressor depends on.
    t = np.arange(int(FS)) / FS
    e1 = FX.level_envelope(np.sin(2 * np.pi * 440 * t) * 0.2)[-1]
    e2 = FX.level_envelope(np.sin(2 * np.pi * 440 * t) * 0.4)[-1]
    check("detector linear in amplitude", abs(e2 / e1 - 2.0) < 0.02, "ratio %.4f" % (e2 / e1))
    # Defining property 3: it is ASYMMETRIC -- attacks faster than it releases, which is what
    # having two constants is FOR.  Step up then down, and compare the 63 % crossing times.
    step = np.concatenate([np.zeros(int(0.05 * FS)),
                           np.ones(int(0.2 * FS)), np.zeros(int(0.2 * FS))]) \
        * np.sin(2 * np.pi * 1000 * np.arange(int(0.45 * FS)) / FS)
    env = FX.level_envelope(step)
    rise = int(0.05 * FS) + np.argmax(env[int(0.05 * FS):int(0.25 * FS)]
                                      > 0.63 * env[int(0.24 * FS)])
    fall = int(0.25 * FS) + np.argmax(env[int(0.25 * FS):] < 0.37 * env[int(0.24 * FS)])
    check("detector attacks faster than it releases",
          (rise - 0.05 * FS) < (fall - 0.25 * FS),
          "attack %.1f ms, release %.1f ms" % (1000 * (rise - 0.05 * FS) / FS,
                                               1000 * (fall - 0.25 * FS) / FS))
    # COMPRESSOR: its defining property is that it REDUCES dynamic range.
    quiet, loud = 0.1, 0.9
    x = np.sin(2 * np.pi * 440 * t) * np.where(t < 0.5, quiet, loud)
    y = FX.compressor(x, threshold=0.25, ratio=4.0)
    rms = lambda v: float(np.sqrt(np.mean(v ** 2)))
    gi = rms(x[int(0.8 * FS):]) / rms(x[int(0.3 * FS):int(0.5 * FS)])
    go = rms(y[int(0.8 * FS):]) / rms(y[int(0.3 * FS):int(0.5 * FS)])
    check("compressor reduces dynamic range", go < gi,
          "in %.1f dB -> out %.1f dB" % (20 * np.log10(gi), 20 * np.log10(go)))
    check("compressor is transparent below threshold",
          abs(rms(FX.compressor(np.sin(2 * np.pi * 440 * t) * 0.01, threshold=0.25, ratio=4.0))
              / rms(np.sin(2 * np.pi * 440 * t) * 0.01) - 1.0) < 0.05)
    # AUTO WAH: its defining property is that the RESONANCE moves with the input level -- and
    # moves to the place the model's own envelope predicts.  ⚠ The first version of this check
    # used the spectral CENTROID and FAILED at a threshold I would then have been tempted to
    # lower: a 2-pole low-pass leaves so much stopband energy that its centroid barely tracks f0
    # (1183 -> 1229 Hz for a filter whose corner doubles).  Measuring the PEAK instead makes the
    # test two-sided -- it must move AND land where predicted -- which is strictly stronger than
    # the check that was failing, not weaker.
    def peak_hz(v, fmax=4000.0):
        m = np.abs(np.fft.rfft(v * np.hanning(v.size)))
        m = np.convolve(m, np.ones(41) / 41.0, "same")          # kill the noise jitter
        f = np.arange(m.size) * FS / v.size
        return float(f[np.argmax(m[:int(fmax * v.size / FS)])])
    n = np.random.RandomState(7).randn(int(0.5 * FS)) * 0.05
    for gain in (1.0, 12.0):
        xin = n * gain
        pred = 400.0 * (1.0 + 3.0 * float(np.median(FX.level_envelope(xin))))
        got = peak_hz(FX.auto_wah(xin, manual_hz=400.0, sweep_range=3.0, resonance=4.0))
        check("auto wah resonance at gain %.0f" % gain, abs(got - pred) / pred < 0.10,
              "predicted %.0f Hz, measured %.0f Hz" % (pred, got))

    print("\n%s" % ("ALL HLE CHECKS PASSED" if PASS else "SOME CHECKS FAILED"))
    return 0 if PASS else 1


if __name__ == "__main__":
    sys.exit(main())
