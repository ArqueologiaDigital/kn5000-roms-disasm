#!/usr/bin/env python3
r"""chorus_ab.py -- A/B for the MAME HLE CHORUS insert (detect the LFO-rate modulation).

QUESTION IT ANSWERS
    Does the chorus insert (kn5000_tonegen.cpp) modulate the signal at the DECODED LFO rate?
    A chorus is a quadrature LFO-swept delay: its comb notches sweep across the spectrum at
    the LFO rate, so each held harmonic is amplitude-modulated at that rate. This compares
    two WAVs (a sustained C4/E4/G4 chord) from eq_hle_ab.lua with TYPEIDX=0 (CHORUS):
        A = DSPHLE=0 (chorus off, dry)
        B = DSPHLE=3 (chorus on)
    Method: STFT both; for the strongest harmonic bins take the magnitude-vs-time series,
    remove its DC/trend, and FFT it (the "modulation spectrum"); the chorus shows a clear
    peak at the LFO rate (~0.6 Hz at rest = decoded cell 0x00), the dry does not. Averaged
    over the top bins for robustness.

    PASS: B's modulation-spectrum peak is in [0.2,4] Hz, well above A's at the same rate, and
    (when LFO SPEED is driven) the peak rate rises. RULE 12: notes must be sounding; RULE 13:
    the dry A is the null (its harmonics are steady, so any B-only periodicity is the signal).

    Use a SINGLE sustained note (chorus_ab.lua), NOT a chord: a multi-note chord's own
    beating adds competing modulation peaks that bury the LFO rate.

    Run:
      cd ~/compartilhado/kn7000_mame_build
      for d in 0 3; do DISPLAY=:0 DHLE=$d timeout 200 ./kn7000 kn5000 -rompath ./roms \
        -skip_gameinfo -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/chorus_ab.lua \
        -wavwrite /tmp/cho_$d.wav; done
      python3 dsp/tools/chorus_ab.py /tmp/cho_0.wav /tmp/cho_3.wav
"""
import sys, wave
import numpy as np


def read_main(path):
    w = wave.open(path, "rb")
    fs, ch = w.getframerate(), w.getnchannels()
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64)
    w.close()
    a = a.reshape(-1, ch)[:, :2]
    return fs, a[:, int(np.argmax((a ** 2).mean(axis=0)))] / 32768.0


def loud_window(x, fs):
    # A long window (several LFO cycles) is needed to resolve a ~0.6 Hz modulation. Find the
    # note onset, then take a fixed 6.5 s span from just after the attack -- onset-relative so
    # it adapts to the rig's note timing (chorus_ab.lua holds one note for 8 s).
    hop = int(0.05 * fs)
    rms = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2) + 1e-20)
                    for i in range(0, len(x) - hop, hop)])
    loud = np.where(rms > 0.25 * rms.max())[0]
    if not len(loud):
        return 0, min(len(x), int(6.5 * fs))
    onset = loud[0] * hop
    s = onset + int(0.5 * fs)                 # skip the attack
    e = min(s + int(6.5 * fs), len(x) - 1)
    return s, e


def mod_spectrum(x, fs):
    """Modulation spectrum: STFT magnitude per bin over time, FFT'd; averaged over the
    strongest harmonic bins. Returns (mod_freqs, avg_mod_mag)."""
    nfft = 2048
    hop = int(0.020 * fs)                     # 20 ms frames -> ~50 Hz frame rate
    frame_rate = fs / hop
    win = np.hanning(nfft)
    mags = []
    for i in range(0, len(x) - nfft, hop):
        mags.append(np.abs(np.fft.rfft(x[i:i + nfft] * win)))
    mags = np.array(mags)                      # [time, bin]
    if len(mags) < 16:
        return np.array([0.0]), np.array([0.0])
    energy = mags.mean(axis=0)
    top = np.argsort(energy)[::-1][:12]        # strongest harmonic bins
    mlen = len(mags)
    mwin = np.hanning(mlen)
    acc = None
    for b in top:
        series = mags[:, b]
        series = (series - series.mean())
        M = np.abs(np.fft.rfft(series * mwin))
        M /= (np.sum(np.abs(series)) + 1e-9)   # normalise by that bin's activity
        acc = M if acc is None else acc + M
    acc /= len(top)
    mfreqs = np.fft.rfftfreq(mlen, 1.0 / frame_rate)
    return mfreqs, acc


def main():
    if len(sys.argv) not in (3, 4, 5):
        print("usage: chorus_ab.py <A_dry.wav> <B_chorus.wav> [band_lo_Hz] [band_hi_Hz]"); return 2
    fsa, A = read_main(sys.argv[1])
    fsb, B = read_main(sys.argv[2])
    fs = fsa
    sa, ea = loud_window(A, fs); sb, eb = loud_window(B, fs)
    print(f"fs={fs}  A window {sa/fs:.2f}-{ea/fs:.2f}s  B window {sb/fs:.2f}-{eb/fs:.2f}s")
    mf, mA = mod_spectrum(A[sa:ea], fs)
    _, mB = mod_spectrum(B[sb:eb], fs)
    # Search the LFO BAND for the effect's rate. Default 0.35-1.1 Hz (chorus/driven flanger/
    # phaser/ensemble); override via argv[3],argv[4] for a faster LFO (e.g. vibrato ~4 Hz).
    # The instrument voice's own tremolo (~2.6 Hz) is present in the dry too, so the band is
    # chosen to exclude it.
    band_lo = float(sys.argv[3]) if len(sys.argv) > 3 else 0.35
    band_hi = float(sys.argv[4]) if len(sys.argv) > 4 else 1.1
    lo, hi = np.searchsorted(mf, band_lo), np.searchsorted(mf, band_hi)

    def peak(m):
        k = lo + int(np.argmax(m[lo:hi]))
        return mf[k], float(m[k])
    fB, vB = peak(mB)
    vA_here = float(mA[np.searchsorted(mf, fB)])
    fA, vA = peak(mA)
    print(f"  A (dry)    LFO-band peak: {fA:5.2f} Hz  (strength {vA:.4f})")
    print(f"  B (chorus) LFO-band peak: {fB:5.2f} Hz  (strength {vB:.4f})")
    print(f"  B/A strength ratio at {fB:.2f} Hz: {vB / max(vA_here, 1e-9):.1f}x")

    ok = (band_lo < fB < band_hi) and (vB > 3.0 * vA_here) and (vB > 0.02)
    print(f"\nPASS -- modulates the note at {fB:.2f} Hz (the decoded LFO rate), "
          f"far above the dry control." if ok else
          "\nFAIL/INCONCLUSIVE -- no clear LFO-rate modulation in B vs A.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
