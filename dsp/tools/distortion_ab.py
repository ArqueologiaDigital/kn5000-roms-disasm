#!/usr/bin/env python3
"""distortion_ab.py -- quantify the HLE DISTORTION insert's harmonic generation.

Question it answers: does the DSPHLE==15 AGC-waveshaper insert add harmonics to a pure
tone (the defining property of a distortion), versus the dry signal?

Inputs: two WAVs captured by distortion_ab.lua with MAME -wavwrite, rendered in SINE mode
so the dry spectrum is a single tone (C4 ~= 261.63 Hz):
    dist_A.wav  DHLE=0   distortion OFF (control -- clean sine)
    dist_B.wav  DHLE=15  distortion ON  (test -- tanh waveshaper)

It extracts a stable window during the sustained note, finds the fundamental, and reports
the energy at harmonics 2..8 relative to the fundamental, and a THD figure. PASS = the
distortion arm's THD is well above the control's.

Usage:  python3 distortion_ab.py /tmp/dist_A.wav /tmp/dist_B.wav
"""
import sys, wave
import numpy as np

F0_NOMINAL = 261.63          # C4
WIN_S = 2.0                  # length of the analysis window (s), centred on the loudest region


def load(path):
    w = wave.open(path, "rb")
    sr = w.getframerate(); n = w.getnframes(); ch = w.getnchannels()
    raw = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64)
    w.close()
    if ch > 1:
        raw = raw.reshape(-1, ch).mean(axis=1)   # mix to mono
    return sr, raw / 32768.0


def window(sr, x):
    # Auto-locate the STEADY SUSTAIN of the note: find the loudest 100 ms frame (near the
    # attack), then window WIN_S seconds starting 0.6 s LATER -- past the attack transient,
    # where the AGC envelope has settled and the clipping is in steady state. Robust to the
    # panel-navigation timing drift between arms.
    fr = max(1, int(0.1 * sr))
    nfr = len(x) // fr
    if nfr < 3:
        return x
    rms = np.array([np.sqrt(np.mean(x[i * fr:(i + 1) * fr] ** 2)) for i in range(nfr)])
    peak = int(np.argmax(rms))
    a = min(len(x) - fr, (peak + 6) * fr)       # 0.6 s into the sustain, past the attack
    b = min(len(x), a + int(WIN_S * sr))
    if b - a < sr // 4:                          # fell off the end -> back up
        a = max(0, b - int(WIN_S * sr))
    return x[a:b]


def spectrum(sr, seg):
    seg = seg - seg.mean()
    w = np.hanning(len(seg))
    X = np.abs(np.fft.rfft(seg * w))
    f = np.fft.rfftfreq(len(seg), 1.0 / sr)
    return f, X


def peak_near(f, X, f_target, tol=0.03):
    lo, hi = f_target * (1 - tol), f_target * (1 + tol)
    m = (f >= lo) & (f <= hi)
    if not m.any():
        return 0.0
    return X[m].max()


def analyse(tag, path):
    sr, x = load(path)
    seg = window(sr, x)
    rms = np.sqrt(np.mean(seg ** 2))
    f, X = spectrum(sr, seg)
    # refine the fundamental: strongest bin within +-6% of nominal C4
    lo, hi = F0_NOMINAL * 0.94, F0_NOMINAL * 1.06
    band = (f >= lo) & (f <= hi)
    if not band.any() or X[band].max() == 0:
        print(f"  {tag}: no fundamental found (silent?) rms={rms:.5f}")
        return None
    f0 = f[band][np.argmax(X[band])]
    fund = X[band].max()
    harmonics = {}
    hsum2 = odd2 = even2 = 0.0
    for k in range(2, 9):
        h = peak_near(f, X, f0 * k)
        r = h / fund if fund else 0.0
        harmonics[k] = r
        hsum2 += r ** 2
        if k % 2:
            odd2 += r ** 2
        else:
            even2 += r ** 2
    thd = np.sqrt(hsum2)
    print(f"  {tag}: f0={f0:6.1f} Hz  rms={rms:.5f}  THD={thd*100:6.2f}%")
    print("        harmonics (rel. to fundamental): " +
          "  ".join(f"{k}f={harmonics[k]*100:5.1f}%" for k in range(2, 7)))
    return {"thd": thd, "h3": harmonics[3], "odd": np.sqrt(odd2), "even": np.sqrt(even2)}


def main():
    if len(sys.argv) != 3:
        print(__doc__); sys.exit(2)
    print("Distortion HLE harmonic-generation A/B")
    A = analyse("A  dry (DHLE=0) ", sys.argv[1])
    B = analyse("B  dist (DHLE=15)", sys.argv[2])
    if A is None or B is None:
        print("\nINCONCLUSIVE: a window was silent.")
        sys.exit(1)
    ratio = (B["thd"] + 1e-9) / (A["thd"] + 1e-9)
    print(f"\nTHD(dist)/THD(dry) = {ratio:.1f}x   3rd-harmonic(dist) = {B['h3']*100:.1f}%")
    # PASS is SIGNATURE-based, not a round THD: a symmetric waveshaper's fingerprint is a clear
    # ODD-harmonic series (3f, 5f) absent from the clean tone, dominating the even harmonics, and
    # vastly above the dry baseline. (An arbitrary absolute-THD bar would just reward cranking the
    # drive; the odd-harmonic structure + ratio is the real evidence it is a waveshaper.)
    odd_dominant = B["odd"] > 3.0 * (B["even"] + 1e-9)
    if B["h3"] > 0.02 and ratio > 20.0 and odd_dominant:
        print("PASS: the distortion insert generates the odd-harmonic series of a waveshaper,")
        print("      far above the dry tone -- a working, harmonic-generating distortion.")
    else:
        print("WEAK/FAIL: no clear waveshaper signature above the dry baseline.")


if __name__ == "__main__":
    main()
