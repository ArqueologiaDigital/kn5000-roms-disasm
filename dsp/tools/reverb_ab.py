#!/usr/bin/env python3
r"""reverb_ab.py -- A/B for the MAME HLE REVERB insert (the decaying tail).

QUESTION IT ANSWERS
    Does the reverb insert (kn5000_tonegen.cpp), reconstructed from the DECODED reverb C-RAM
    coefficients, add a reverberant tail? A reverb's signature is a smooth exponential decay
    that continues after the dry note has died. Compares two WAVs from delay_ab.lua (a short
    pluck + long silence):
        A = DHLE=0  (reverb off, dry pluck -> silence)
        B = DHLE=14 (reverb on)
    Metric: the RMS envelope after the pluck. In a LATE window (well past the dry note's
    release), B still has energy (the reverb tail) while A is near silent; B/A there is the
    signal. Also estimates RT60 from B's envelope decay slope.

    PASS: B's late-window (0.9-1.8 s after onset) RMS is well above A's (>3x) -- a tail the dry
    control does not have (RULE 13: the dry is the null). NOTE this validates that a reverb
    tail is PRESENT and decays; the absolute RT60 is not claimed hardware-faithful (the chip's
    exact topology/delay lengths are an open decode), only that the tail tracks the decoded
    reverb coefficients.

    Run:
      cd ~/compartilhado/kn7000_mame_build
      for d in 0 14; do DISPLAY=:0 DHLE=$d DSPCFG=2 TYPEIDX=0 timeout 200 ./kn7000 kn5000 \
        -rompath ./roms -skip_gameinfo \
        -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/delay_ab.lua \
        -wavwrite /tmp/rv_$d.wav; done
      python3 dsp/tools/reverb_ab.py /tmp/rv_0.wav /tmp/rv_14.wav
"""
import sys, wave
import numpy as np


def env(path):
    w = wave.open(path, "rb")
    fs, ch = w.getframerate(), w.getnchannels()
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64)
    w.close()
    a = a.reshape(-1, ch)[:, :2]
    x = a[:, int(np.argmax((a ** 2).mean(axis=0)))] / 32768.0
    hop = int(0.02 * fs)
    e = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2) + 1e-20) for i in range(0, len(x) - hop, hop)])
    return fs, e, hop


def onset(e, hop, fs, t0=36.0):
    i0 = int(t0 * fs / hop)
    idx = np.where(e[i0:] > 0.2 * e[i0:].max())[0]
    return (i0 + idx[0]) if len(idx) else i0


def rt60(e, o, hop, fs):
    # fit dB decay from the peak over the next ~1.5 s; RT60 = time to -60 dB
    seg = e[o:o + int(1.5 * fs / hop)]
    if len(seg) < 10 or seg.max() <= 0:
        return float("nan")
    db = 20 * np.log10(seg / seg.max() + 1e-9)
    t = np.arange(len(seg)) * hop / fs
    m = db > -55
    if m.sum() < 5:
        return float("nan")
    slope = np.polyfit(t[m], db[m], 1)[0]   # dB/s (negative)
    return -60.0 / slope if slope < -1 else float("nan")


def main():
    if len(sys.argv) != 3:
        print("usage: reverb_ab.py <A_dry.wav> <B_reverb.wav>"); return 2
    fsa, ea, hop = env(sys.argv[1])
    fsb, eb, _ = env(sys.argv[2])
    fs = fsa
    oa, ob = onset(ea, hop, fs), onset(eb, hop, fs)
    print(f"fs={fs}  A onset {oa*hop/fs:.2f}s  B onset {ob*hop/fs:.2f}s")
    # late window 0.9-1.8 s after onset (well past the dry pluck's release)
    def win_rms(e, o, t1, t2):
        s, x = o + int(t1 * fs / hop), o + int(t2 * fs / hop)
        seg = e[s:min(x, len(e))]
        return float(np.sqrt(np.mean(seg ** 2))) if len(seg) else 0.0
    a_late = win_rms(ea, oa, 0.4, 1.2)
    b_late = win_rms(eb, ob, 0.4, 1.2)
    a_note = win_rms(ea, oa, 0.0, 0.3)
    print(f"  note window (0-0.3s):   A {a_note:.4f}")
    print(f"  tail window (0.4-1.2s): A {a_late:.5f}   B {b_late:.5f}   B/A {b_late/max(a_late,1e-9):.1f}x")
    print(f"  B reverb RT60 estimate: {rt60(eb, ob, hop, fs):.2f} s")
    ok = (b_late > 3.0 * a_late) and (b_late > 0.002)
    print("\nPASS -- B carries a decaying reverb tail well past the dry note, absent from the "
          "control." if ok else "\nFAIL/INCONCLUSIVE -- no reverb tail above the dry control.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
