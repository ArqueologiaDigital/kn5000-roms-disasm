#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""designer.py -- the HOST-side coefficient designers, as decoded from the Sub-CPU code
(DSP_PerParameterTranslator, parameter opcodes; see dsp/analysis/host-side.md and
HOST-to-DSP-coefficient-chain-2026-09-09.md).

These turn user parameters (Hz, Q, dB, ms, %) into the DSP coefficients the HLE kernels
consume -- the same job the Sub CPU does before streaming to C-RAM.  This closes the loop the
static analysis identified: user parameter -> host formula -> coefficient -> DSP block.

FS = 44100 Hz, proven three ways (effects-dsp.md); constants from host-side.md.
stdlib only.
"""
import math

FS = 44100.0


def biquad_peaking(f0, Q, gain_db, fs=FS):
    """Parametric-EQ band: bilinear-transform peaking biquad (opcode 0x70 designer,
    K = tan(pi*f0/fs); host-side.md).  Returns (b0,b1,b2,a1,a2) already divided by a0, i.e.
    ready for BiquadDF1(b0,b1,b2,a1,a2).  Cut (gain<0) reciprocates the section, as the ROM
    designer does ('implements cut by reciprocating the whole section')."""
    A = 10.0 ** (gain_db / 40.0)
    K = math.tan(math.pi * f0 / fs)
    Q = max(Q, 1e-4)
    norm = 1.0 + K / (A * Q) + K * K
    b0 = (1.0 + (A / Q) * K + K * K) / norm
    b1 = (2.0 * (K * K - 1.0)) / norm
    b2 = (1.0 - (A / Q) * K + K * K) / norm
    a1 = (2.0 * (K * K - 1.0)) / norm
    a2 = (1.0 - K / (A * Q) + K * K) / norm
    return b0, b1, b2, a1, a2


def biquad_lowpass(f0, Q, fs=FS):
    """A plain RBJ low-pass (for tone filters / damping where a full section is used)."""
    w0 = 2.0 * math.pi * f0 / fs
    alpha = math.sin(w0) / (2.0 * max(Q, 1e-4))
    cw = math.cos(w0)
    a0 = 1.0 + alpha
    b0 = (1.0 - cw) / 2.0 / a0
    b1 = (1.0 - cw) / a0
    b2 = b0
    a1 = (-2.0 * cw) / a0
    a2 = (1.0 - alpha) / a0
    return b0, b1, b2, a1, a2


def ms_to_samples(ms, fs=FS):
    """Delay time: ms * 44100/1000 (opcode 0x67 evaluator, literal 0xAC44/0x3E8; host-side.md)."""
    return ms * fs / 1000.0


def lfo_inc(rate_hz, fs=FS):
    """LFO phase increment = f/fs (opcode 0x6A integer freq curve, §7a)."""
    return rate_hz / fs


def damping_from_hz(cutoff_hz, fs=FS):
    """One-pole damping coefficient d for a given -3 dB cutoff (reverb HIGH DAMP)."""
    if cutoff_hz >= fs / 2.0:
        return 0.0
    x = math.cos(2.0 * math.pi * cutoff_hz / fs)
    # standard one-pole: d = 2 - x - sqrt((2-x)^2 - 1)
    t = 2.0 - x
    return t - math.sqrt(max(t * t - 1.0, 0.0))


def onepole_a_from_seconds(tau_s, fs=FS):
    """One-pole smoother coefficient `a' for a time constant in SECONDS -- the inverse of the
    relation the ROM's own detector constants satisfy: tau = 1/(a*fs).

    MEASURED (SPECULATIVE-APPLIED-REGISTER §147): at ROM 0x84CD the host uploads
    `009DAD' = 0.004812 -> 4.712 ms and `003F29' = 0.001927 -> 11.764 ms, and COMPRESSOR's
    coefficient cursor consumes them as its ATTACK and RELEASE.  This is the host-side designer
    that produces such a coefficient from the UI's `ATTACK SENS.(s)' / `RELEASE SENS.(s)'."""
    return min(max(1.0 / (float(tau_s) * fs), 0.0), 1.0)
