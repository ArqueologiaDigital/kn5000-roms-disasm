#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""effects.py -- per-family HLE of the uPD6383GF effects, each wired from kernels.py using
coefficients from designer.py.  The wiring is the decoded block diagram
(DECODE-by-correlation §5/§7/§12/§16 + EFFECT-ALGORITHMS-implementation-spec).

Every effect is `process(x) -> y` on a mono float array at FS=44100.  These are reference
models of the decoded ALGORITHM (graded), not bit-exact to the chip.
"""
import math
import numpy as np

from kernels import BiquadDF1, OnePole, LFO, DelayLine, waveshape
import designer as D


def parametric_eq(x, bands):
    """PARAMETRIC EQ (§7b): a series of Direct-Form-I peaking biquads.
    bands = [(f0, Q, gain_db), ...] (KN5000 uses 5, WSA1R 6)."""
    y = np.asarray(x, dtype=np.float64)
    for f0, Q, g in bands:
        y = BiquadDF1(*D.biquad_peaking(f0, Q, g)).process(y)
    return y


def chorus(x, rate_hz=0.8, depth_ms=3.0, base_ms=12.0, mix=0.5, voices=2, fs=D.FS):
    """CHORUS (§7a): LFO-swept delay taps summed with the dry signal; `voices` detuned LFO
    phases (quadrature for 2, spread for more) = the §6 multi-LFO-table count."""
    x = np.asarray(x, dtype=np.float64)
    n = x.size
    dl = DelayLine(int(D.ms_to_samples(base_ms + depth_ms + 1.0, fs)))
    base = D.ms_to_samples(base_ms, fs)
    depth = D.ms_to_samples(depth_ms, fs)
    lfos = [LFO(rate_hz, fs, "sine", phase=v / voices) for v in range(voices)]
    mods = [l.block(n) for l in lfos]
    wet = np.zeros(n)
    for i in range(n):
        dl.push(x[i])
        s = 0.0
        for v in range(voices):
            s += dl.read(base + depth * (0.5 + 0.5 * mods[v][i]))
        wet[i] = s / voices
    return (1.0 - mix) * x + mix * wet


def flanger(x, rate_hz=0.3, depth_ms=2.0, base_ms=1.0, feedback=0.5, mix=0.5, fs=D.FS):
    """FLANGER (§16 ~ chorus with feedback and a short sweep)."""
    x = np.asarray(x, dtype=np.float64)
    n = x.size
    dl = DelayLine(int(D.ms_to_samples(base_ms + depth_ms + 1.0, fs)))
    base = D.ms_to_samples(base_ms, fs)
    depth = D.ms_to_samples(depth_ms, fs)
    mod = LFO(rate_hz, fs, "sine").block(n)
    y = np.zeros(n)
    for i in range(n):
        d = dl.read(base + depth * (0.5 + 0.5 * mod[i]))
        dl.push(x[i] + feedback * d)
        y[i] = (1.0 - mix) * x[i] + mix * d
    return y


def delay(x, time_ms=300.0, feedback=0.4, mix=0.4, damp_hz=6000.0, fs=D.FS):
    """SINGLE DELAY (§12): a feedback delay line with a one-pole HIGH-DAMP in the loop."""
    x = np.asarray(x, dtype=np.float64)
    n = x.size
    N = int(D.ms_to_samples(time_ms, fs))
    dl = DelayLine(N + 4)
    damp = OnePole(D.damping_from_hz(damp_hz, fs))
    y = np.zeros(n)
    for i in range(n):
        d = dl.read(N)
        dl.push(x[i] + feedback * damp.process_one(d))
        y[i] = (1.0 - mix) * x[i] + mix * d
    return y


class _Comb:
    def __init__(self, n, fb, damp):
        self.dl = DelayLine(n + 4); self.n = n; self.fb = fb; self.f = OnePole(damp)
    def tick(self, x):
        d = self.dl.read(self.n)
        self.dl.push(x + self.fb * self.f.process_one(d))
        return d


class _Allpass:
    def __init__(self, n, g):
        self.dl = DelayLine(n + 4); self.n = n; self.g = g
    def tick(self, x):
        d = self.dl.read(self.n)
        v = x + (-self.g) * d
        self.dl.push(v)
        return d + self.g * v


def reverb(x, decay=0.84, damp_hz=4500.0, mix=0.3, fs=D.FS):
    """REVERB (§5): a Schroeder tank -- a bank of damped feedback combs summed, then an
    all-pass diffuser chain.  WSA1R uses comb+damp stages (§5 RMMzzW); the KN5000 uses an
    all-pass ladder -- both are represented here (combs + all-passes).  Delay lengths are the
    classic mutually-prime Schroeder set scaled to fs."""
    x = np.asarray(x, dtype=np.float64)
    n = x.size
    damp = D.damping_from_hz(damp_hz, fs)
    comb_ms = [29.7, 37.1, 41.1, 43.7]
    ap_ms = [5.0, 1.7, 0.5]
    combs = [_Comb(int(D.ms_to_samples(m, fs)), decay, damp) for m in comb_ms]
    aps = [_Allpass(int(D.ms_to_samples(m, fs)), 0.7) for m in ap_ms]
    y = np.zeros(n)
    for i in range(n):
        s = sum(c.tick(x[i]) for c in combs) / len(combs)
        for ap in aps:
            s = ap.tick(s)
        y[i] = (1.0 - mix) * x[i] + mix * s
    return y


def reverb_kn5000(x, decay=0.86, damp_hz=5000.0, mix=0.3, fs=D.FS):
    """KN5000 REVERB (§5 + public effects-dsp.md §4): a pre-delay feeding NINE first-order
    all-pass diffusers in two descending-gain ladders (five + four), with a damping one-pole
    and recirculation providing the decay (the diffuser ladder itself is loss-less/all-pass,
    exactly as proven; decay lives in the feedback around it)."""
    x = np.asarray(x, dtype=np.float64)
    n = x.size
    predelay = DelayLine(int(D.ms_to_samples(20.0, fs)) + 4)
    pd_n = int(D.ms_to_samples(20.0, fs))
    # nine all-pass diffusers, two descending-gain ladders (5 + 4); mutually-prime lengths
    ap_ms = [4.2, 6.1, 8.3, 11.9, 15.1,   3.1, 5.3, 7.7, 10.3]
    gains = [0.72, 0.70, 0.68, 0.66, 0.64,  0.70, 0.68, 0.66, 0.64]  # descending per ladder
    aps = [_Allpass(int(D.ms_to_samples(m, fs)), g) for m, g in zip(ap_ms, gains)]
    fb_delay = DelayLine(int(D.ms_to_samples(38.0, fs)) + 4)
    fb_n = int(D.ms_to_samples(38.0, fs))
    damp = OnePole(D.damping_from_hz(damp_hz, fs))
    y = np.zeros(n)
    recirc = 0.0
    for i in range(n):
        predelay.push(x[i])
        s = predelay.read(pd_n) + decay * damp.process_one(recirc)
        for ap in aps:
            s = ap.tick(s)
        fb_delay.push(s)
        recirc = fb_delay.read(fb_n)
        y[i] = (1.0 - mix) * x[i] + mix * s
    return y


def distortion(x, drive=8.0, level=0.4, curve="tanh", tone_hz=None, fs=D.FS):
    """DISTORTION / OVERDRIVE / EXCITER (§7d): drive -> waveshaper(curve) -> output level,
    with an optional post tone biquad (overdrive/exciter add one; fuzz/distortion do not)."""
    y = waveshape(x, drive=drive, curve=curve) * level
    if tone_hz is not None:
        y = BiquadDF1(*D.biquad_lowpass(tone_hz, 0.707)).process(y)
    return y
