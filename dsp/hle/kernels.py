#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""kernels.py -- the FOUR signal-processing kernels the uPD6383GF effects are built from,
as a high-level-emulation (HLE) reference.

This is the audio-producing counterpart to the static decode: `DECODE-by-correlation` §7/§12
show every effect is a wiring of a small set of primitives, and this module implements those
primitives directly (numpy), so the decoded block diagrams can actually run and make sound.

It is HLE, not LLE: it reproduces each block's *transfer function / behaviour*, not the chip's
36-bit microcode execution.  Each kernel is validated by its defining property in test_hle.py.

Kernels (decoded in DECODE-by-correlation + algorithms/biquad-eq.md):
  BiquadDF1        -- Direct-Form-I second-order section (the parametric-EQ band, §7b/§15).
  OnePole          -- the 0x0D/0x0E two-state damping filter used in reverb/mod feedback (§3).
  LFO              -- phase accumulator -> shaped waveform table (§6/§7a).
  DelayLine        -- the external delay-DRAM as a ring buffer with fractional read (§1/§4/§12).
  waveshape        -- the class-6 addr8=0x28 static distortion curve (§6/§7d).

stdlib + numpy; no hardware, no MAME.
"""
import math
import numpy as np


class BiquadDF1:
    """Direct-Form-I biquad, exactly the parametric-EQ band decoded to the bit in
    dsp/algorithms/biquad-eq.md:
        y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    with an optional make-up gain (C-RAM[0x05]).  Coefficients are stored on the chip as
    b1,b0,b2,-a1,-a2,makeup (the recursive pair pre-negated); this class takes the usual
    b0,b1,b2,a1,a2 and applies the same recurrence."""

    def __init__(self, b0, b1, b2, a1, a2, makeup=1.0):
        self.b = (float(b0), float(b1), float(b2))
        self.a = (float(a1), float(a2))
        self.makeup = float(makeup)
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0

    def reset(self):
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0

    def process(self, x):
        x = np.asarray(x, dtype=np.float64)
        y = np.empty_like(x)
        b0, b1, b2 = self.b
        a1, a2 = self.a
        x1, x2, y1, y2 = self.x1, self.x2, self.y1, self.y2
        for n in range(x.size):
            xn = x[n]
            yn = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2, x1 = x1, xn
            y2, y1 = y1, yn
            y[n] = yn
        self.x1, self.x2, self.y1, self.y2 = x1, x2, y1, y2
        return y * self.makeup

    def response(self, freqs, fs):
        """Analytic magnitude response |H(e^jw)| at the given frequencies (for validation)."""
        b0, b1, b2 = self.b
        a1, a2 = self.a
        w = 2 * math.pi * np.asarray(freqs, dtype=np.float64) / fs
        z1 = np.exp(-1j * w)
        z2 = np.exp(-2j * w)
        H = (b0 + b1 * z1 + b2 * z2) / (1.0 + a1 * z1 + a2 * z2)
        return np.abs(H) * self.makeup


class OnePole:
    """One-pole low-pass = the reverb/mod feedback damping filter (the 0x0D/0x0E two-state
    update, §3/§5).  y[n] = (1-d)*x[n] + d*y[n-1], d in [0,1) the damping coefficient."""

    def __init__(self, damping=0.0):
        self.d = float(damping)
        self.y1 = 0.0

    def reset(self):
        self.y1 = 0.0

    def process_one(self, x):
        self.y1 = (1.0 - self.d) * x + self.d * self.y1
        return self.y1


class LFO:
    """Phase accumulator -> shaped waveform table (§6 addr8=0x18 LFO table, §7a).  The chip
    accumulates a 23-bit phase (wrap at 2^23-1) and looks the shaped waveform up in a table;
    here the table is a unit-amplitude waveform sampled by the phase."""

    SHAPES = ("sine", "triangle", "square")

    def __init__(self, rate_hz, fs, shape="sine", phase=0.0):
        self.inc = float(rate_hz) / float(fs)      # cycles per sample (= f/fs, §6 rate)
        self.shape = shape
        self.phase = float(phase) % 1.0

    def block(self, n):
        ph = (self.phase + self.inc * np.arange(n)) % 1.0
        self.phase = (self.phase + self.inc * n) % 1.0
        if self.shape == "sine":
            return np.sin(2 * math.pi * ph)
        if self.shape == "triangle":
            return 2.0 * np.abs(2.0 * (ph - np.floor(ph + 0.5))) - 1.0
        if self.shape == "square":
            return np.where(ph < 0.5, 1.0, -1.0)
        raise ValueError(self.shape)


class DelayLine:
    """External delay-DRAM as a ring buffer with fractional (linear-interpolated) read --
    the R/W delay stages of §4/§12, and the LFO-swept read tap of a chorus (§7a)."""

    def __init__(self, max_samples):
        self.buf = np.zeros(int(max_samples) + 4, dtype=np.float64)
        self.w = 0

    def push(self, x):
        self.buf[self.w] = x
        self.w = (self.w + 1) % self.buf.size

    def read(self, delay_samples):
        d = float(delay_samples)
        i = int(math.floor(d))
        frac = d - i
        a = self.buf[(self.w - 1 - i) % self.buf.size]
        b = self.buf[(self.w - 2 - i) % self.buf.size]
        return a * (1.0 - frac) + b * frac


def waveshape(x, drive=1.0, curve="tanh"):
    """The class-6 addr8=0x28 static distortion curve (§6/§7d): a table-lookup nonlinearity.
    A real chip uses a ROM LUT; here the LUT is a smooth odd saturating curve.  drive is the
    op0x61 pre-gain; the caller applies op0x62 output level afterwards."""
    x = np.asarray(x, dtype=np.float64) * float(drive)
    if curve == "tanh":
        return np.tanh(x)
    if curve == "hard":
        return np.clip(x, -1.0, 1.0)
    if curve == "cubic":                            # soft cubic (overdrive-ish)
        return np.clip(x - (x ** 3) / 3.0, -2.0 / 3.0, 2.0 / 3.0) * 1.5
    raise ValueError(curve)


class LevelDetector:
    """The 2/pi LEVEL DETECTOR (§67 / SPECULATIVE-APPLIED-REGISTER §147) -- the fifth kernel,
    and the one the dynamics family is built on.

    ★ THIS IS NOT A TEXTBOOK ENVELOPE FOLLOWER: every constant below is READ FROM THE ROM.
    At ROM 0x84CD the host's own upload script holds five consecutive Q0.23 coefficients, and
    COMPRESSOR's coefficient cursor consumes them in exactly that order:

        517CC1  0.636620  = floor(2/pi * 2^23) EXACTLY -- the mean of |sin|, i.e. the constant
                            that relates a sine's AMPLITUDE to its RECTIFIED MEAN.  ⚠ The idiom
                            MULTIPLIES by it (a class-A multiply against C-RAM[0x00]), and
                            multiplying cannot undo a rectification -- converting a rectified
                            mean back to an amplitude needs the RECIPROCAL.  So 2/pi here is a
                            scale factor whose other half lives somewhere this decode has not
                            found: most likely folded into the THRESHOLD coefficient the host
                            uploads, which would let a MAC-only machine avoid a divide.  ⚠ WHERE
                            THE RECIPROCAL LIVES IS OPEN; this kernel reproduces what the
                            microcode does, not what would make the number read prettily.
        400000  0.500000
        009DAD  0.004812  -> one-pole tau = 1/(a*fs) = 4.712 ms   ATTACK
        003F29  0.001927  -> one-pole tau =           11.764 ms   RELEASE
        066666  0.050000

    The two time constants are why the chip's parameter list gives COMPRESSOR an `ATTACK SENS.(s)'
    and a `RELEASE SENS.(s)' (kn5000-dsp-paramlist.md), and the idiom appears TWICE in
    prog36_compressor -- once per stage, one smoother constant each.

    ⚠ SPECULATIVE, and named as such: that the idiom's HEAD word (hi12 bit 5, f31 in {3,7}) is the
    RECTIFIER is an INFERENCE -- the detector must rectify, 2/pi is the wrong constant for an RMS
    detector, and the head is the idiom's only slot not already accounted for by a named
    coefficient.  11 of the 12 idiom sites are headed by such a word; one is not.  See
    N-INPUT-GATE-OPENED §67 for the rival readings that survive.

    y[n] = y[n-1] + a * (|x[n]| * 2/pi - y[n-1]),  a = A_ATTACK while rising, A_RELEASE falling.
    """

    TWO_OVER_PI = 5340353 / float(1 << 23)          # 0x517CC1, the ROM's own truncation
    A_ATTACK = 0x009DAD / float(1 << 23)            # 0.004812 -> 4.712 ms
    A_RELEASE = 0x003F29 / float(1 << 23)           # 0.001927 -> 11.764 ms

    def __init__(self, a_attack=None, a_release=None):
        self.a_att = self.A_ATTACK if a_attack is None else float(a_attack)
        self.a_rel = self.A_RELEASE if a_release is None else float(a_release)
        self.y1 = 0.0

    def reset(self):
        self.y1 = 0.0

    def process_one(self, x):
        t = abs(x) * self.TWO_OVER_PI
        a = self.a_att if t > self.y1 else self.a_rel
        self.y1 += a * (t - self.y1)
        return self.y1

    def process(self, x):
        x = np.asarray(x, dtype=np.float64)
        out = np.empty_like(x)
        y, aa, ar, k = self.y1, self.a_att, self.a_rel, self.TWO_OVER_PI
        for n in range(x.size):
            t = abs(x[n]) * k
            y += (aa if t > y else ar) * (t - y)
            out[n] = y
        self.y1 = y
        return out
