#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""test_l7a1429_hle.py -- validate the L7A1429 acoustic-model HLE by its defining properties.
No hardware; each check is analytic or signal-based.

    python3 wsa1/hle/test_l7a1429_hle.py
"""
import math
import sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import l7a1429_hle as L                                                  # noqa: E402

FS = L.FS
PASS = True


def check(name, ok, detail=""):
    global PASS
    PASS = PASS and ok
    print("  [%s] %-46s %s" % ("PASS" if ok else "FAIL", name, detail))


def dominant_hz(y, fs=FS):
    y = y[:1 << int(math.log2(len(y)))]
    m = np.abs(np.fft.rfft(y * np.hanning(len(y))))
    k = np.argmax(m[2:]) + 2
    return k * fs / len(y)


def main():
    # 1. PROVEN coefficient decode: MUTING cutoff index is a MIDI note (index = note-36).
    print("MUTING cutoff decode (bilinear one-pole, HLE-GUIDE 2.2/7.2):")
    # round-trip: word -> cutoff -> word
    for fc in (466.0, 1000.0, 4000.0, 12000.0):
        w = L.muting_word_for_cutoff(fc)
        fc2 = L.cutoff_hz(w)
        check("cutoff round-trips at %.0f Hz" % fc, abs(fc2 - fc) / fc < 0.02,
              "%.0f -> word 0x%04X -> %.0f Hz" % (fc, w, fc2))
    # the guide's law: cutoff(i) = 440*2^((i+36-69)/12); check the octave relationship holds
    w_a = L.muting_word_for_cutoff(440.0 * 2 ** ((60 + 36 - 69) / 12))
    w_b = L.muting_word_for_cutoff(440.0 * 2 ** ((72 + 36 - 69) / 12))
    ratio = L.cutoff_hz(w_b) / L.cutoff_hz(w_a)
    check("one octave of index = 2x cutoff", abs(ratio - 2.0) < 0.03, "ratio %.3f" % ratio)

    # 2. The resonator produces a PITCHED tone at the note's fundamental.
    print("\nWaveguide resonator pitch (delay = period):")
    for note, name in ((57, "A3=220"), (69, "A4=440"), (81, "A5=880")):
        y = L.synth_channel(note, dur=1.0, sub_gain=0.0, muting_cut_hz=6000, feedback=0.999)
        f0 = 440.0 * 2 ** ((note - 69) / 12)
        got = dominant_hz(y)
        check("note %d (%s) rings at f0" % (note, name), abs(got - f0) / f0 < 0.03,
              "want %.1f Hz, got %.1f Hz" % (f0, got))

    # 3. Autonomous sustain + decay (no key-off; §7.5): energy present early, decayed late,
    #    and the decay is gradual (a finite T60), not an instant cut.
    print("\nAutonomous decay (no key-off, §7.5):")
    y = L.synth_channel(60, dur=3.0, sub_gain=0.0, muting_cut_hz=4000, feedback=0.9995)
    seg = lambda a, b: np.sqrt(np.mean(y[int(a * FS):int(b * FS)] ** 2))
    e_early, e_mid, e_late = seg(0.05, 0.15), seg(1.0, 1.1), seg(2.5, 2.6)
    check("energy sustains past 1 s", e_mid > e_early * 0.05, "early %.3f mid %.3f" % (e_early, e_mid))
    check("energy decays by 2.5 s", e_late < e_mid, "mid %.3f late %.3f" % (e_mid, e_late))
    check("decay is gradual, not a cut", e_mid > e_late > 1e-5, "late rms %.2e" % e_late)

    # 4. MUTING controls brightness: a lower cutoff = less high-frequency energy.
    print("\nMUTING damping controls brightness:")
    def hf_ratio(cut):
        y = L.synth_channel(60, dur=1.0, sub_gain=0.0, muting_cut_hz=cut, feedback=0.999)
        m = np.abs(np.fft.rfft(y[:32768] * np.hanning(32768)))
        fb = lambda f: int(f * 32768 / FS)
        return m[fb(3000):fb(10000)].sum() / (m[fb(100):fb(1200)].sum() + 1e-9)
    dark, bright = hf_ratio(1200.0), hf_ratio(9000.0)
    check("brighter MUTING -> more HF energy", bright > dark * 1.3, "dark %.3f bright %.3f" % (dark, bright))

    # 5. SUB GAIN mixes a detuned second resonator (adds beating -> amplitude modulation).
    print("\nSUB GAIN mixes the coupled SUB resonator:")
    solo = L.synth_channel(69, dur=2.0, sub_gain=0.0, sub_detune_cents=-8, muting_cut_hz=5000)
    pair = L.synth_channel(69, dur=2.0, sub_gain=1.0, sub_detune_cents=-8, muting_cut_hz=5000)
    IFS=int(FS)
    env = lambda y: np.abs(y[IFS // 4: IFS])
    check("SUB adds amplitude beating", env(pair).std() / (env(pair).mean() + 1e-9)
          > env(solo).std() / (env(solo).mean() + 1e-9), "coupling detune produces beats")

    print("\n%s" % ("ALL L7A1429 HLE CHECKS PASSED" if PASS else "SOME CHECKS FAILED"))
    return 0 if PASS else 1


if __name__ == "__main__":
    sys.exit(main())
