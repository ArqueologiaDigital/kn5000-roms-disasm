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

from kernels import BiquadDF1, OnePole, LFO, DelayLine, LevelDetector, waveshape
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


# ---------------------------------------------------------------------------
# The DYNAMICS family.  These were the HLE's blind spot: `families.md' groups
# ENHANCER, AUTO WAH, COMPRESSOR and NO OPERATION as the programs that carry a
# LEVEL DETECTOR, and none of them was modelled here -- which meant the oracle
# was silent exactly where N-INPUT-GATE-OPENED §63-§67's `hi12 bit 5' signal is
# strongest.  The detector itself (kernels.LevelDetector) is READ FROM THE ROM,
# constant for constant.  What each effect DOES with it is marked per function.
# ---------------------------------------------------------------------------


def level_envelope(x, attack_s=None, release_s=None, fs=D.FS):
    """The decoded 2/pi level detector, exposed on its own (§67).

    `attack_s' / `release_s' are the chip's own `ATTACK SENS.(s)' / `RELEASE SENS.(s)' UI
    parameters; omit them to use the ROM's shipped constants (4.712 ms / 11.764 ms)."""
    det = LevelDetector(D.onepole_a_from_seconds(attack_s, fs) if attack_s else None,
                        D.onepole_a_from_seconds(release_s, fs) if release_s else None)
    return det.process(x)


def compressor(x, threshold=0.25, ratio=4.0, attack_s=None, release_s=None,
               volume=1.0, fs=D.FS):
    """COMPRESSOR (algo 13; params THRESHOLD, RATIO, ATTACK SENS.(s), RELEASE SENS.(s),
    VOLUME, REV SEND).

    ★ DECODED, from the ROM: the detector -- rectify, scale by 2/pi, smooth with a one-pole whose
      coefficient is the ATTACK constant while the level rises and the RELEASE constant while it
      falls.  `prog36_compressor' runs the idiom TWICE (two stages), consuming one smoother
      constant each.

    ⚠ SPECULATIVE, and this is the part to challenge: THE GAIN LAW.  What the decode establishes
      is NEGATIVE and strong -- `DECODE-by-correlation' / `families.md': *"The compressor computes
      gain ARITHMETICALLY: there is NO COMPARATOR OPCODE in the corpus (the bodies are branchless),
      so THRESHOLD/RATIO enter as COEFFICIENTS, not as a compare."*  A branchless, divider-free,
      MAC-only machine cannot evaluate `if env > threshold'.  The simplest law that fits those
      constraints is a LINEAR gain reduction driven by the envelope and bounded by the chip's own
      saturating clamp (which the hardware really has -- the bit-4 store clamp and the class-8
      post-sum word):

          g[n] = clip(1 - k * env[n],  1/ratio,  1),     k = (1 - 1/ratio) / threshold

      so gain is unity in silence and reaches its floor 1/ratio when the envelope reaches the
      threshold.  ⚠ RIVALS NOT EXCLUDED: a reciprocal-style AGC (`g = 1/(1 + k*env)'), or a gain
      curve delivered by the same table-lookup idiom the distortion family uses.  Nothing in the
      corpus has yet been measured to choose between them -- do not read this curve as decoded."""
    x = np.asarray(x, dtype=np.float64)
    env = level_envelope(x, attack_s, release_s, fs)
    k = (1.0 - 1.0 / float(ratio)) / max(float(threshold), 1e-6)
    g = np.clip(1.0 - k * env, 1.0 / float(ratio), 1.0)
    return x * g * float(volume)


def auto_wah(x, resonance=4.0, manual_hz=400.0, sweep_range=3.0,
             attack_s=None, release_s=None, volume=1.0, fs=D.FS):
    """AUTO WAH (algo 18; params RESONANCE, MANUAL, SWEEP RANGE, VOLUME, REV SEND).
    `families.md': a level detector plus *"a swept resonator"* -- the same detector as the
    compressor, driving the centre frequency of a resonant low-pass.

        f0[n] = MANUAL * (1 + SWEEP RANGE * env[n])      RESONANCE = the biquad Q

    ⚠ HLE APPROXIMATION, stated so it is not mistaken for a decode: the biquad coefficients are
    recomputed every `block' samples rather than every sample.  The chip re-derives them
    continuously; at 32 samples (0.7 ms) the difference is inaudible and the cost is ~1400x lower.
    ⚠ SPECULATIVE: that the sweep is MULTIPLICATIVE in `f0' (musically the usual choice, and what
    a MAC computes naturally) rather than additive in some warped coordinate."""
    x = np.asarray(x, dtype=np.float64)
    env = level_envelope(x, attack_s, release_s, fs)
    block = 32
    y = np.empty_like(x)
    bq = BiquadDF1(*D.biquad_lowpass(manual_hz, resonance, fs))
    for i in range(0, x.size, block):
        f0 = manual_hz * (1.0 + float(sweep_range) * env[i])
        f0 = min(max(f0, 20.0), 0.45 * fs)
        b0, b1, b2, a1, a2 = D.biquad_lowpass(f0, resonance, fs)
        #  ⚠ BiquadDF1 keeps its coefficients in the tuples `b' and `a', NOT as b0/b1/...
        #  attributes -- assigning the latter silently creates dead fields and the filter never
        #  moves.  Caught by the "auto wah sweeps up with level" check in test_hle.py, which
        #  reported identical spectral centroids at a 12x input level.
        bq.b, bq.a = (b0, b1, b2), (a1, a2)
        y[i:i + block] = bq.process(x[i:i + block])
    return y * float(volume)
