#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""l7a1429_hle.py -- high-level-emulation REFERENCE of the SX-WSA1R acoustic-modeling LSI
(IC3, L7A1429 at 0x00104000), built strictly from wsa1/notes/HLE-GUIDE-l7a1429.md.

WHAT THE CHIP IS (HLE-GUIDE §0/§3, graded STRONG): a per-channel pair of coupled linear
RESONATORS (MAIN + SUB) -- a digital-waveguide model of the media the firmware names itself
(STRING, CYLINDER, CONE, FLARE, PLATE, MEMB).  Each resonator is:
    excitation  ->  delay (length = the pitch PERIOD)  ->  one-pole loss filter (MUTING)  ->  gain
with a shared POSITION (a delay-tap along the medium) and an excitation shaping (FITTING).
MAIN and SUB are coupled through their TUNINGS (the firmware's sub_FC4269 solver adds a detune);
SUB GAIN mixes them.  There is NO key-off: a note-off re-programs release values and the chip
then decays autonomously -- so the parameters are INITIAL CONDITIONS + TIME CONSTANTS, and this
model must sustain and decay on its own (HLE-GUIDE §7.5).

WHAT IS SETTLED vs FAKED (HLE-GUIDE §1/§7.3/§8), each stand-in behind a switch:
  * PROVEN: the MUTING cutoff decode -- a bilinear one-pole coefficient, index = MIDI note-36
    (a1_from_word / cutoff_hz below are the guide's own C, ported).  fs = 44100.
  * STRONG: the topology (waveguide resonator pair) -- the manufacturer's own vocabulary.
  * UNKNOWN, exposed as a named constant: the absolute scale of POSITION (§8.1, "the single
    most valuable missing number").
  * STAND-IN (undumped): the excitation is a DRIVER *sample* from prom_d's wave ROMs, which are
    NOT dumped -- here it is a synthetic shaped burst, clearly marked, drop-in replaceable.
  * INFERENCE: the internal signal path (series/parallel, where the driver enters) is unmeasured.

=> This is a physically-plausible realization of the DOCUMENTED resonator model, NOT a faithful
reproduction of the chip's audio (impossible without the wave ROMs and an internal-path trace).
It consumes the decoded per-channel parameters the MAME l7a1429_device already exposes
(decoded_channel), and is the "eventual synthesis" that guide invites (§ IMPLEMENTED note).

stdlib + numpy.
"""
import math
import numpy as np

FS = 44100.0


# ---- PROVEN coefficient decode (HLE-GUIDE §7.2, ported from the guide's C) -----------------
def a1_from_word(w):
    """sign-magnitude Q15 -> [-1,+1): the packer's fold, registers 0x0400/0x0440/0x0480."""
    w &= 0xFFFF
    mag = -(w & 0x7FFF) if (w & 0x8000) else w
    return mag / 32768.0


def cutoff_hz(w, fs=FS):
    """MUTING one-pole cutoff from its register word (bilinear prewarp K=(1+a1)/(1-a1))."""
    a1 = a1_from_word(w)
    if a1 >= 1.0:
        return fs / 2.0
    K = (1.0 + a1) / (1.0 - a1)
    return fs * math.atan(K) / math.pi


def muting_word_for_cutoff(fc, fs=FS):
    """Inverse: the register word that encodes a given MUTING cutoff (for driving the model
    from a cutoff in Hz).  a1 = (K-1)/(K+1), K = tan(pi*fc/fs); re-fold to sign-magnitude."""
    K = math.tan(math.pi * min(fc, fs / 2 - 1) / fs)
    a1 = (K - 1.0) / (K + 1.0)
    q = int(round(abs(a1) * 32768.0)) & 0x7FFF
    return q if a1 >= 0 else (0x8000 | q)


def onepole_coeff(fc, fs=FS):
    """The loop loss filter as a normalized one-pole lowpass with -3dB at fc: returns d in
    [0,1) for y = (1-d)*x + d*y1 (matches designer.damping_from_hz in the effects HLE)."""
    if fc >= fs / 2.0:
        return 0.0
    x = math.cos(2.0 * math.pi * fc / fs)
    t = 2.0 - x
    return t - math.sqrt(max(t * t - 1.0, 0.0))


class Waveguide:
    """One resonator: a Karplus-Strong / digital-waveguide loop -- a delay of `period`
    samples with a one-pole loss filter and a feedback gain, plus a POSITION pickup tap.
    This is the linear struck/plucked-resonator the guide argues for (§3.1): excitation ->
    delay(period) -> loss -> gain, entirely linear, exactly what STRING/PLATE/MEMB need."""

    def __init__(self, period, muting_cut_hz, feedback=0.999, position=0.5, fs=FS):
        self.N = max(2, int(round(period)))
        self.buf = np.zeros(self.N, dtype=np.float64)
        self.i = 0
        self.d = onepole_coeff(muting_cut_hz, fs)   # MUTING loss (PROVEN cutoff decode)
        self.fb = float(feedback)
        self.y1 = 0.0
        self.pos = min(max(position, 0.0), 0.999)   # POSITION pickup tap (0..1 along the loop)

    def excite(self, burst):
        """Seed the delay line with the excitation (the DRIVER sample stand-in)."""
        n = min(len(burst), self.N)
        self.buf[:n] += np.asarray(burst[:n], dtype=np.float64)

    def run(self, nsamples):
        out = np.empty(nsamples, dtype=np.float64)
        N, buf, d, fb = self.N, self.buf, self.d, self.fb
        tap = int(self.pos * N)
        i = self.i
        y1 = self.y1
        for n in range(nsamples):
            v = buf[i]
            y1 = (1.0 - d) * v + d * y1          # loss filter in the loop = MUTING damping
            buf[i] = fb * y1                      # feed back around the delay
            # POSITION pickup: comb of the current and tapped sample
            out[n] = v - buf[(i - tap) % N]
            i = (i + 1) % N
        self.i, self.y1 = i, y1
        return out


def driver_excitation(nsamples, fitting_rise=0.002, fitting_decay=0.03, seed=0, fs=FS):
    """STAND-IN for the undumped DRIVER wave-ROM sample (HLE-GUIDE §3/§8): a short shaped
    noise burst whose rise/decay stand for FITTING.  Marked, and drop-in replaceable the day
    IC4's six wave mask ROMs are dumped."""
    rng = np.random.default_rng(seed)
    n = max(4, int((fitting_rise + fitting_decay) * fs))
    t = np.arange(n) / fs
    env = np.minimum(t / max(fitting_rise, 1e-5), 1.0) * np.exp(-t / max(fitting_decay, 1e-4))
    return rng.standard_normal(n) * env


def synth_channel(note, dur=2.0, *, muting_cut_hz=3000.0, sub_gain=1.0, sub_detune_cents=-6.0,
                  position=0.5, position_scale=1.0, feedback=0.999,
                  fitting_rise=0.002, fitting_decay=0.03, fs=FS, seed=0):
    """Render one L7A1429 channel: coupled MAIN+SUB waveguides mixed by SUB GAIN.

    note            : MIDI note -> the pitch PERIOD (delay length).
    muting_cut_hz   : MUTING loop-loss cutoff (PROVEN decode; here given in Hz).
    sub_gain        : SUB GAIN mix, 0..1 (register 0x0280).
    sub_detune_cents: the MAIN<->SUB coupling, applied as a tuning detune (HLE-GUIDE: they
                      interact through their tunings, no coupling register).
    position        : POSITION pickup tap 0..1; position_scale is the UNKNOWN absolute-scale
                      constant (§8.1), exposed as a single named parameter.
    """
    f0 = 440.0 * 2.0 ** ((note - 69) / 12.0)
    period_main = fs / f0 * position_scale
    period_sub = fs / (f0 * 2.0 ** (sub_detune_cents / 1200.0)) * position_scale
    nsamp = int(dur * fs)
    exc = driver_excitation(nsamp, fitting_rise, fitting_decay, seed, fs)

    main = Waveguide(period_main, muting_cut_hz, feedback, position, fs)
    sub = Waveguide(period_sub, muting_cut_hz, feedback, position, fs)
    main.excite(exc)
    sub.excite(exc)
    y = main.run(nsamp) + sub_gain * sub.run(nsamp)
    peak = np.max(np.abs(y)) or 1.0
    return y / peak * 0.9
