#!/usr/bin/env python3
"""dlyseed_echo.py -- measure the LLE single-delay's echo train from a DLYSEED2_ONCE capture.

A run with UPD6383_DLYSEED2_ONCE=F (no note playing, DSPCFG=3 so the LLE wet is in the mix)
puts ONE impulse into the external delay line at the tap address on frame F: it comes out of
the tap immediately (frame F), is fed back through the damping and written to the line base,
and recirculates -- returning every LOOP DELAY frames, decaying by the feedback gain.  The
audio therefore shows a first click at t0 = F / 44100 s and further clicks spaced by the loop
delay.  That spacing is the quantity two readings disagree on:

    * descriptor 0x26 (READ_CELL - WRITE_CELL) = 15437 samples = 350.05 ms  (the HLE delay)
    * hardware question Q4 (§234): under the shipped 0x0D/0x0E pair the LLE returns its
      product at lag ~500 samples = 11.3 ms, not 1001 / not the descriptor's 15437

This tool finds the clicks after t0 and reports their spacing (in 48 kHz output samples and in
44.1 kHz DSP frames) against both, plus the decay ratio between successive echoes -- the
lle_oracle_delay.py prediction (peaks at N, 2N, 3N decaying by ~g, damped < undamped).

    python3 dsp/tools/dlyseed_echo.py CAPTURE.wav [--seed-frame 1820000] [--fs-dsp 44100]
"""
import sys
import wave

import numpy as np

DESC_N = 15437        # descriptor loop delay, DSP frames
Q4_N = 500            # the §234 shipped-pair lag, DSP frames


def load(path):
    w = wave.open(path, "rb"); sr = w.getframerate(); ch = w.getnchannels()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64).reshape(-1, ch)
    w.close()
    m = 0.5 * (x[:, 1] + x[:, 2]) if ch >= 3 else x[:, 0]
    return sr, m / 32768.0


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    seed_frame = int(sys.argv[sys.argv.index("--seed-frame") + 1]) if "--seed-frame" in sys.argv else 1820000
    fs_dsp = float(sys.argv[sys.argv.index("--fs-dsp") + 1]) if "--fs-dsp" in sys.argv else 44100.0
    if not args:
        print(__doc__); return 2
    sr, m = load(args[0])
    t0 = seed_frame / fs_dsp
    a = int((t0 - 0.05) * sr); b = min(len(m), int((t0 + 1.5) * sr))
    if b - a < int(0.5 * sr):
        print("capture ends at %.2f s -- less than 0.5 s after the seed time %.2f s; too short" % (len(m) / sr, t0)); return 1
    print("analysis window %.3f..%.3f s (%.2f s after the seed; a truncated capture is clamped)" % (a / sr, b / sr, b / sr - t0))
    seg = m[a:b]
    noise = np.sqrt(np.mean(m[int((t0 - 1.0) * sr):int((t0 - 0.1) * sr)] ** 2)) + 1e-9
    env = np.abs(seg)
    thr = max(8.0 * noise, 0.002)
    print("seed t0 = %.3f s (frame %d @ %.0f Hz); pre-seed noise rms %.6f; click threshold %.5f"
          % (t0, seed_frame, fs_dsp, noise, thr))
    # clicks = local maxima of |x| above threshold, at least 2 ms apart
    idx = np.where(env > thr)[0]
    if len(idx) == 0:
        print("NO click above threshold after the seed -- the seeded impulse did not reach the output"
              " (or the wet return is not in the mix). Nothing to measure."); return 1
    peaks = []
    gap = int(0.002 * sr)
    i = 0
    while i < len(idx):
        j = i
        while j + 1 < len(idx) and idx[j + 1] - idx[j] <= gap:
            j += 1
        k = idx[i] + int(np.argmax(env[idx[i]:idx[j] + 1]))
        peaks.append((k, env[k])); i = j + 1
    peaks = peaks[:12]
    print("\n%d click(s) after the seed (offset from the first, in output samples / ms / DSP frames):" % len(peaks))
    p0 = peaks[0][0]
    for k, amp in peaks:
        off = k - p0
        print("  +%6d smp  %8.2f ms  %7.0f frames   amp %.5f" % (off, 1000.0 * off / sr, off * fs_dsp / sr, amp))
    if len(peaks) >= 2:
        sp = np.diff([k for k, _ in peaks])
        med = float(np.median(sp)); med_fr = med * fs_dsp / sr
        print("\nmedian spacing = %.0f output samples = %.2f ms = %.0f DSP frames" % (med, 1000.0 * med / sr, med_fr))
        print("  descriptor 0x26 predicts %d frames (%.2f ms): ratio %.3f" % (DESC_N, 1000.0 * DESC_N / fs_dsp, med_fr / DESC_N))
        print("  Q4 shipped-pair lag  %d frames (%.2f ms): ratio %.3f" % (Q4_N, 1000.0 * Q4_N / fs_dsp, med_fr / Q4_N))
        amps = [amp for _, amp in peaks]
        ratios = [amps[i + 1] / amps[i] for i in range(min(3, len(amps) - 1)) if amps[i] > 0]
        if ratios:
            print("  successive-echo amplitude ratios: " + ", ".join("%.3f" % r for r in ratios)
                  + "   (oracle: ~feedback g per loop, damped < undamped)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
