#!/usr/bin/env python3
r"""delay_ab_echo.py -- TEMPORAL A/B of the MAME HLE SINGLE-DELAY insert.

QUESTION IT ANSWERS
    Does the delay insert (kn5000_tonegen.cpp) produce echoes at the decoded delay time
    with the decoded feedback? A delay's signature is LAG, not a spectral peak, so this is
    a temporal test. Compares two WAVs from delay_ab.lua (a short pluck + long silence):
        A = DHLE=0 (delay off, dry pluck, no echoes)
        B = DHLE=2 (delay on)
    Method: CROSS-correlate B's envelope against A's (the dry). The delay inserts a scaled,
    delayed COPY of the dry into B, so xcorr(B_env, A_env) peaks at lag 0 (the dry-vs-dry
    match) AND again at lag = the delay time (the echo-vs-dry match). A shows no such second
    peak. This is robust to the note's own shape/beating (which pollutes a plain
    autocorrelation, since that structure is present in BOTH arms). Default delay 350 ms
    (descriptor cell 0x26). A/B arms are onset-aligned first.

    PASS: B autocorr peaks in [280,420] ms AND that peak is much stronger than A's at the
    same lag (echoes are real, RULE 13: a difference from silence is not a signal -- here
    the control A is the dry pluck, so a B-only periodicity is the signal).

    Run:
      cd ~/compartilhado/kn7000_mame_build
      for d in 0 2; do DISPLAY=:0 DHLE=$d timeout 200 ./kn7000 kn5000 -rompath ./roms \
        -skip_gameinfo -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/delay_ab.lua \
        -wavwrite /tmp/dly_$d.wav; done
      python3 dsp/tools/delay_ab_echo.py /tmp/dly_0.wav /tmp/dly_2.wav
"""
import sys, wave
import numpy as np


def read_env(path):
    w = wave.open(path, "rb")
    fs, ch = w.getframerate(), w.getnchannels()
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64)
    w.close()
    a = a.reshape(-1, ch)
    m = a[:, :2]                              # main L/R only (ch2 = DO3, not the mix)
    x = m[:, int(np.argmax((m ** 2).mean(axis=0)))] / 32768.0
    # amplitude envelope: abs, smoothed with a 10 ms moving average
    win = max(1, int(0.010 * fs))
    env = np.convolve(np.abs(x), np.ones(win) / win, mode="same")
    return fs, x, env


def first_onset(env, fs, after_s=37.0):
    # search only AFTER the navigation completes (delay_ab.lua plucks at t=38 s); earlier
    # menu/nav sounds must not be mistaken for the pluck.
    i0 = int(after_s * fs)
    thr = 0.15 * env[i0:].max()
    idx = np.where(env[i0:] > thr)[0]
    return i0 + int(idx[0]) if len(idx) else i0


def xcorr_norm(b, a):
    b = b - b.mean(); a = a - a.mean()
    xc = np.correlate(b, a, mode="full")[len(a) - 1:]     # lag >= 0 (b lags a)
    return xc / (np.std(a) * np.std(b) * len(a) + 1e-12)


def peak_in(xc, fs, lo_ms, hi_ms):
    lo, hi = int(lo_ms / 1000 * fs), int(hi_ms / 1000 * fs)
    k = lo + int(np.argmax(xc[lo:hi]))
    return k / fs * 1000.0, float(xc[k])


def main():
    if len(sys.argv) != 3:
        print("usage: delay_ab_echo.py <A_dry.wav> <B_delay.wav>"); return 2
    fsa, xa, ea = read_env(sys.argv[1])
    fsb, xb, eb = read_env(sys.argv[2])
    fs = fsa
    oa, ob = first_onset(ea, fs), first_onset(eb, fs)
    W = int(1.8 * fs)
    A, B = ea[oa:oa + W], eb[ob:ob + W]
    print(f"fs={fs}  A onset {oa/fs:.2f}s  B onset {ob/fs:.2f}s")
    # cross-correlation of B's envelope against the dry A: echo = delayed copy of the dry
    xcBA = xcorr_norm(B, A)
    l0_ms, l0_v = peak_in(xcBA, fs, 0, 60)
    ec_ms, ec_v = peak_in(xcBA, fs, 150, 900)
    print(f"  xcorr(B,A) lag~0  peak: {l0_ms:6.1f} ms  (strength {l0_v:.3f})  [dry-vs-dry]")
    print(f"  xcorr(B,A) echo   peak: {ec_ms:6.1f} ms  (strength {ec_v:.3f})  [echo-vs-dry]")
    # control: the SAME echo band on A-vs-A must NOT show a comparable peak (RULE 13 null)
    xcAA = xcorr_norm(A, A)
    ac_ms, ac_v = peak_in(xcAA, fs, 150, 900)
    print(f"  control xcorr(A,A) in echo band: {ac_ms:6.1f} ms (strength {ac_v:.3f})")

    ok = (300 < ec_ms < 400) and (ec_v > 0.08) and (ec_v > ac_v + 0.05)
    print(f"\nPASS -- B carries a delayed copy of the dry at {ec_ms:.0f} ms (the decoded ~350 ms "
          f"delay), absent from the control." if ok else
          "\nFAIL/INCONCLUSIVE -- no clean ~350 ms delayed copy in B vs A.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
