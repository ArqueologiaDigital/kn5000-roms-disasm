#!/usr/bin/env python3
"""fx_features.py -- generic feature A/B for the HLE effect-preview inserts.

Reports, for a DRY (DHLE=0) capture A and an EFFECT (DHLE=N) capture B, the signal features
that identify each effect's characteristic behaviour, so a preview can be validated against the
dry control without a bespoke analyzer per effect:

  RMS, crest factor          -- compressor (crest down), distortion (up)
  band energy lo/mid/hi      -- exciter/enhancer (hi up), wah (band peak)
  spectral centroid          -- wah/exciter (moves up), rotary
  THD (odd/even harmonics)   -- distortion/exciter/ring (added harmonics)
  inharmonic fraction        -- ring modulator (sidebands off the harmonic grid)
  AM rate & depth            -- auto-pan / tremolo / rotary (amplitude modulated)
  L/R antiphase AM           -- auto-pan (L and R modulate in opposition)
  echo lags (autocorr)       -- multi-tap delay, (gated) reverb
  tail energy after note     -- reverb / gated reverb / delay

Captures are the 3-channel MAME wavs (main stereo = channels 1 & 2). Usage:
  python3 fx_features.py A.wav B.wav [--mode sustain|pluck] [--f0 261.63]
"""
import sys, wave
import numpy as np

def load(path):
    w = wave.open(path, "rb"); sr = w.getframerate(); ch = w.getnchannels()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64).reshape(-1, ch)
    w.close()
    L = x[:, 1] if ch >= 3 else x[:, 0]           # main stereo = ch 1,2 (ch0 is silent)
    R = x[:, 2] if ch >= 3 else x[:, -1]
    return sr, L / 32768.0, R / 32768.0

def loudest_frame(sr, m, fr_s=0.1):
    fr = max(1, int(fr_s * sr)); n = len(m) // fr
    if n < 2: return 0
    rms = np.array([np.sqrt(np.mean(m[i*fr:(i+1)*fr]**2)) for i in range(n)])
    return int(np.argmax(rms)) * fr

def feats(sr, L, R, mode, f0):
    m = 0.5 * (L + R)
    start = loudest_frame(sr, m)
    if mode == "pluck":
        seg = m[start:start + int(3.0*sr)]; segL = L[start:start+int(3.0*sr)]; segR = R[start:start+int(3.0*sr)]
    else:  # sustain: analyse steady part, 0.6 s past the onset
        a = min(len(m)-sr//4, start + int(0.6*sr)); b = min(len(m), a + int(2.0*sr))
        seg = m[a:b]; segL = L[a:b]; segR = R[a:b]
    out = {}
    rms = np.sqrt(np.mean(seg**2)) + 1e-12
    out["rms"] = rms
    out["crest"] = np.max(np.abs(seg)) / rms
    # spectrum
    w = np.hanning(len(seg)); X = np.abs(np.fft.rfft(seg*w)); f = np.fft.rfftfreq(len(seg), 1.0/sr)
    P = X**2
    out["centroid"] = float(np.sum(f*P) / (np.sum(P)+1e-12))
    out["lo"] = float(np.sum(P[f < 500]))
    out["mid"] = float(np.sum(P[(f >= 500) & (f < 3000)]))
    out["hi"] = float(np.sum(P[f >= 3000]))
    tot = out["lo"]+out["mid"]+out["hi"]+1e-12
    out["hi_frac"] = out["hi"]/tot
    # harmonics vs f0
    def peak(ft):
        lo, hi = ft*0.97, ft*1.03; mk = (f>=lo)&(f<=hi)
        return X[mk].max() if mk.any() else 0.0
    fund = peak(f0)+1e-12
    odd = np.sqrt(sum((peak(f0*k)/fund)**2 for k in (3,5,7)))
    even = np.sqrt(sum((peak(f0*k)/fund)**2 for k in (2,4,6)))
    out["thd"] = np.sqrt(sum((peak(f0*k)/fund)**2 for k in range(2,9)))
    out["odd"] = odd; out["even"] = even
    # inharmonic fraction: energy NOT within +-3% of any harmonic of f0
    harm_mask = np.zeros_like(f, dtype=bool)
    for k in range(1, int(sr/2/f0)+1):
        harm_mask |= (np.abs(f - k*f0) < 0.03*f0)
    out["inharm"] = float(np.sum(P[~harm_mask]) / (np.sum(P)+1e-12))
    # amplitude-modulation rate & depth (envelope spectrum, 0.2..15 Hz)
    env = np.abs(seg);
    # decimate envelope to ~1 kHz
    dec = max(1, sr//1000); e = env[::dec]; esr = sr/dec
    e = e - e.mean()
    if len(e) > 16:
        EW = np.abs(np.fft.rfft(e*np.hanning(len(e)))); ef = np.fft.rfftfreq(len(e), 1.0/esr)
        band = (ef >= 0.2) & (ef <= 15.0)
        if band.any() and EW[band].max() > 0:
            pk = ef[band][np.argmax(EW[band])]
            out["am_hz"] = float(pk); out["am_depth"] = float(EW[band].max()/(np.sum(np.abs(e))/len(e)*len(e)/2 + 1e-12))
        else:
            out["am_hz"] = 0.0; out["am_depth"] = 0.0
    else:
        out["am_hz"] = 0.0; out["am_depth"] = 0.0
    # L/R antiphase (pan): correlation of the L and R envelopes
    eL = np.abs(segL[::dec]); eR = np.abs(segR[::dec]); eL-=eL.mean(); eR-=eR.mean()
    n = min(len(eL), len(eR))
    out["lr_corr"] = float(np.corrcoef(eL[:n], eR[:n])[0,1]) if n > 4 else 0.0
    # echo lags: autocorrelation of the AMPLITUDE ENVELOPE (robust for tonal signals, where the
    # waveform self-correlates at every lag). Envelope bumps recur at the echo spacing.
    full = 0.5*(L + R)
    env = np.abs(full); dec2 = max(1, sr//2000); e = env[::dec2]; esr = sr/dec2
    # smooth the envelope a little
    k = max(1, int(0.003*esr)); e = np.convolve(e, np.ones(k)/k, mode="same")
    e = e - e.mean(); ne = len(e)
    nf = 1 << int(np.ceil(np.log2(2*ne)))
    F = np.fft.rfft(e, nf); ac = np.fft.irfft(F*np.conj(F), nf)[:ne]; ac = ac/(ac[0]+1e-12)
    lags = []
    for lag_ms in range(40, 700, 2):
        lag = int(lag_ms*esr/1000)
        if 0 < lag < len(ac): lags.append((lag_ms, ac[lag]))
    lags.sort(key=lambda t: -t[1])
    out["echoes_ms"] = [l for l, v in lags[:5] if v > 0.10]
    # early tail (gate-open / first reflections) and late tail (after a gate would cut)
    e0 = start + int(0.30*sr); e1 = e0 + int(0.30*sr)
    out["early_rms"] = float(np.sqrt(np.mean(full[e0:e1]**2))) if e1 <= len(full) else 0.0
    t0 = start + int(1.2*sr); t1 = t0 + int(0.5*sr)
    out["tail_rms"] = float(np.sqrt(np.mean(full[t0:t1]**2))) if t1 <= len(full) else 0.0
    return out

def main():
    args = sys.argv[1:]
    mode = "sustain"; f0 = 261.63
    if "--mode" in args: mode = args[args.index("--mode")+1]
    if "--f0" in args: f0 = float(args[args.index("--f0")+1])
    paths = [a for a in args if a.endswith(".wav")]
    if len(paths) != 2: print(__doc__); sys.exit(2)
    srA, LA, RA = load(paths[0]); srB, LB, RB = load(paths[1])
    A = feats(srA, LA, RA, mode, f0); B = feats(srB, LB, RB, mode, f0)
    keys = ["rms","crest","centroid","hi_frac","thd","odd","even","inharm","am_hz","am_depth","lr_corr","early_rms","tail_rms"]
    print(f"{'feature':<12} {'A dry':>12} {'B effect':>12}   ratio/delta")
    for k in keys:
        a, b = A[k], B[k]
        r = (b/a) if (isinstance(a,float) and abs(a)>1e-9) else float('nan')
        print(f"{k:<12} {a:>12.5f} {b:>12.5f}   x{r:.2f}" if r==r else f"{k:<12} {a:>12.5f} {b:>12.5f}")
    print(f"{'echoes_ms':<12} A={A['echoes_ms']}  B={B['echoes_ms']}")

if __name__ == "__main__":
    main()
