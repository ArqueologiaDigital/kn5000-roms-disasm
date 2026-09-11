#!/usr/bin/env python3
r"""eq_hle_ab_fft.py -- spectral A/B of the MAME audible-EQ insert (the decisive test).

QUESTION IT ANSWERS
    Does the eq_hle insert (kn5000_tonegen.cpp), fed the effects-DSP C-RAM, actually
    boost the audio by the panel-dialled amount at the decoded band centre? This
    compares two WAVs captured by eq_hle_ab.lua with band-0 gain driven +12 dB:
        A = EQHLE=0  (insert bypassed, dry)
        B = EQHLE=1  (insert active)
    and reports B/A in dB per frequency. PASS = a clear bump (~+12 dB, tolerant) in the
    band-0 region (~500-900 Hz, centre 673 Hz) and ~flat far from it.  This validates the
    PLUMBING (C-RAM read -> RBJ -> per-sample filter); the coefficient math is already
    validated offline by eq_rbj_reconstruct_ab.py.

    Run:
      cd ~/compartilhado/kn7000_mame_build
      for e in 0 1; do DISPLAY=:0 EQHLE=$e timeout 300 ./kn7000 kn5000 -rompath ./roms \
        -skip_gameinfo -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/eq_hle_ab.lua \
        -wavwrite /tmp/eq_$e.wav; done
      python3 dsp/tools/eq_hle_ab_fft.py /tmp/eq_0.wav /tmp/eq_1.wav
"""
import sys, wave
import numpy as np

# Band centre in Hz: argv[3] (default 673 = band 0). The measured band centres are
# 673, 966, 1405, 2091, 3219 Hz. The in-band window is centre*[0.74 .. 1.34].
CENTRE = float(sys.argv[3]) if len(sys.argv) > 3 else 673.0
BAND_LO, BAND_HI, BAND_CENTRE = CENTRE * 0.74, CENTRE * 1.34, CENTRE


def read_wav(path):
    w = wave.open(path, "rb")
    fs = w.getframerate()
    n = w.getnframes()
    ch = w.getnchannels()
    sw = w.getsampwidth()
    raw = w.readframes(n)
    w.close()
    dt = {1: np.int8, 2: np.int16, 4: np.int32}[sw]
    a = np.frombuffer(raw, dtype=dt).astype(np.float64)
    if ch > 1:
        # The KN5000 WAV has 3 channels: main L, main R, and the DO3 direct-out
        # (a SEPARATE physical output, not in the mix and NOT touched by the EQ insert).
        # This content is panned to main-R (L is silent), so pick the loudest of the two
        # MAIN channels (0,1) -- never ch 2 (DO3) -- so the boost is neither diluted nor
        # read off an EQ-untouched output.
        m = a.reshape(-1, ch)[:, :2]
        a = m[:, int(np.argmax((m ** 2).mean(axis=0)))]
    if sw == 2:
        a /= 32768.0
    elif sw == 4:
        a /= 2.0 ** 31
    return fs, a


def loud_window(x, fs):
    """Largest contiguous region above 25% of peak RMS, in 50 ms hops."""
    hop = int(0.05 * fs)
    rms = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2) + 1e-20)
                    for i in range(0, len(x) - hop, hop)])
    thr = 0.25 * rms.max()
    loud = rms > thr
    best_s = best_e = cur_s = None
    best = 0
    for i, v in enumerate(list(loud) + [False]):
        if v and cur_s is None:
            cur_s = i
        elif not v and cur_s is not None:
            if i - cur_s > best:
                best, best_s, best_e = i - cur_s, cur_s, i
            cur_s = None
    if best_s is None:
        return 0, len(x)
    # trim 100 ms off each end to avoid attack/release transients
    s = (best_s * hop) + int(0.1 * fs)
    e = (best_e * hop) - int(0.1 * fs)
    return s, max(e, s + fs // 2)


def welch(x, fs, nfft=8192):
    win = np.hanning(nfft)
    step = nfft // 2
    acc = np.zeros(nfft // 2 + 1)
    cnt = 0
    for i in range(0, len(x) - nfft, step):
        seg = x[i:i + nfft] * win
        acc += np.abs(np.fft.rfft(seg)) ** 2
        cnt += 1
    if cnt == 0:
        seg = np.zeros(nfft); seg[:len(x)] = x
        acc = np.abs(np.fft.rfft(seg * win)) ** 2; cnt = 1
    psd = acc / cnt
    freqs = np.fft.rfftfreq(nfft, 1.0 / fs)
    return freqs, psd


def main():
    if len(sys.argv) not in (3, 4):
        print("usage: eq_hle_ab_fft.py <A_dry.wav> <B_eq.wav> [band_centre_Hz]"); return 2
    fsa, A = read_wav(sys.argv[1])
    fsb, B = read_wav(sys.argv[2])
    assert fsa == fsb, "sample-rate mismatch"
    fs = fsa
    # eq_hle_ab.lua always plays the chord over a FIXED emulated window (NOTES ON t=49 s,
    # OFF t=57 s), and -wavwrite records from emulation start, so the same wall-clock window
    # holds both runs. Use a fixed matched window (50.5-56.0 s, inside the sustain) rather
    # than an independent per-file loudness detector, which can pick different-length
    # segments for A and B and skew the off-band comparison. Fall back to detection only if
    # the file is shorter than the fixed window.
    ws, we = int(50.5 * fs), int(56.0 * fs)
    if len(A) < we or len(B) < we:
        sa, ea = loud_window(A, fs); sb, eb = loud_window(B, fs)
    else:
        sa, ea = sb, eb = ws, we
    print(f"fs={fs}  A window {sa/fs:.2f}-{ea/fs:.2f}s  B window {sb/fs:.2f}-{eb/fs:.2f}s")
    fA, pA = welch(A[sa:ea], fs)
    fB, pB = welch(B[sb:eb], fs)
    ratio_db = 10.0 * np.log10((pB + 1e-12) / (pA + 1e-12))

    def band_mean(lo, hi):
        m = (fA >= lo) & (fA < hi)
        # weight by A's energy so silent bins don't dominate the average
        w = pA[m]
        return np.average(ratio_db[m], weights=w + 1e-12) if m.any() else float("nan")

    in_band = band_mean(BAND_LO, BAND_HI)
    lo_hi = max(120.0, CENTRE * 0.55)
    hi_lo = CENTRE * 1.8
    lo_ref = band_mean(60.0, lo_hi)                       # below the band
    hi_ref = band_mean(hi_lo, min(CENTRE * 6.0, 14000.0)) # above the band
    ci = np.argmin(np.abs(fA - BAND_CENTRE))
    print(f"\n  B/A at {fA[ci]:.0f} Hz (band centre {BAND_CENTRE:.0f}): {ratio_db[ci]:+.2f} dB")
    print(f"  B/A mean in band ({BAND_LO:.0f}-{BAND_HI:.0f} Hz, A-weighted): {in_band:+.2f} dB")
    print(f"  B/A mean below  (60-{lo_hi:.0f} Hz):   {lo_ref:+.2f} dB")
    print(f"  B/A mean above  ({hi_lo:.0f} Hz+):     {hi_ref:+.2f} dB")

    # show the biggest-boost bins overall
    order = np.argsort(ratio_db)[::-1]
    seen = []
    print("\n  largest B/A boosts:")
    for i in order:
        f = fA[i]
        if pA[i] < pA.max() * 1e-4:   # ignore near-silent bins
            continue
        if any(abs(f - s) < 40 for s in seen):
            continue
        seen.append(f)
        print(f"    {f:7.1f} Hz  {ratio_db[i]:+6.2f} dB")
        if len(seen) >= 6:
            break

    print()
    ok = (in_band > 4.0) and (in_band - lo_ref > 3.0) and (in_band - hi_ref > 3.0)
    print("PASS -- EQ insert boosts the band-0 region above the rest." if ok else
          "FAIL/INCONCLUSIVE -- no clear band-0 boost; inspect the bins above.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
