#!/usr/bin/env python3
r"""eq_band_gain_calibrate.py -- per-band gain calibration for the MAME audible EQ.

QUESTION IT ANSWERS
    Band 0's gain constant (A^2 = 1 + G*(c1-0.5), G=455.7) was fit on a single band-0
    +12 dB capture. Is the SAME G right for the other four bands? This drives EACH band's
    gain +12 dB in turn and measures its own G. Result: G is NOT uniform -- the gain-cell
    slope roughly HALVES per band -- so the emulator needs a per-band G table.

    Navigation (MEASURED here): the PARAMETRIC-EQ editor's PARAMETER cursor is a FLAT list
    over all 5 bands x {FC, Q, G}, so band b's gain is NPARAM = 3*b + 2 (2, 5, 8, 11, 14).
    Each run boosts exactly that one band (verified: the other four stay at c1=0.5000).

CAPTURE RECIPE (binary built -DKN5000_ENABLE_DSP1=1 -DKN5000_EQHLE_DEBUG=1)
    cd ~/compartilhado/kn7000_mame_build
    for np in 2 5 8 11 14; do
      DISPLAY=:0 EQHLE=1 DSPCFG=0 NPARAM=$np NVALUE=24 timeout 200 ./kn7000 kn5000 \
        -rompath ./roms -skip_gameinfo \
        -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/eq_hle_ab.lua \
        > /tmp/nav_np$np.log 2>&1
    done
    python3 dsp/tools/eq_band_gain_calibrate.py /tmp/nav_np2.log /tmp/nav_np5.log \
        /tmp/nav_np8.log /tmp/nav_np11.log /tmp/nav_np14.log

    Each log's LAST all-band snapshot (### EQHLE lines) is parsed; the boosted band is the
    one whose c1 (already normalised to the CELL scale in the log) departs from 0.5.

The debug log prints c1 at the CELL scale (operand x2). +24 VALUE steps == +12 dB, i.e.
A = 10^(12/40), A^2 = 3.98107, so G_band = (A^2 - 1) / (c1_band - 0.5).
"""
import re, sys, math

A2M1 = 10.0 ** (12.0 / 20.0) - 1.0   # A^2 - 1 at +12 dB  (== 2.98107)


def last_snapshot(path):
    """Return {band: c1} from the final all-band ### EQHLE snapshot in the log."""
    rows = {}
    cur = {}
    last_t = None
    for ln in open(path, encoding="utf-8", errors="replace"):
        m = re.search(r"### EQHLE t=([\d.]+) b(\d) .* c1=([-\d.]+) ", ln)
        if not m:
            continue
        t, b, c1 = m.group(1), int(m.group(2)), float(m.group(3))
        if t != last_t:
            if cur:
                rows = dict(cur)
            cur = {}
            last_t = t
        cur[b] = c1
    if cur:
        rows = dict(cur)
    return rows


def main():
    if len(sys.argv) < 2:
        print("usage: eq_band_gain_calibrate.py nav_np2.log nav_np5.log ..."); return 2
    # band boosted by NPARAM=3b+2, in the order the logs are given (2,5,8,11,14)
    gains = {}
    print(f"{'band':4} {'c1@+12dB':>9} {'dev':>9} {'G':>9}")
    for i, path in enumerate(sys.argv[1:]):
        snap = last_snapshot(path)
        # the boosted band = the one with the largest |c1 - 0.5|
        b = max(snap, key=lambda k: abs(snap[k] - 0.5))
        dev = snap[b] - 0.5
        G = A2M1 / dev if abs(dev) > 1e-6 else float("inf")
        gains[b] = G
        print(f"{b:4d} {snap[b]:9.4f} {dev:9.5f} {G:9.1f}")
    print("\nper-band G table (band 0..4):")
    print("  {" + ", ".join(f"{gains[b]:.1f}" for b in sorted(gains)) + "}")
    ratios = [gains[b] / gains[b + 1] for b in sorted(gains)[:-1] if b + 1 in gains]
    if ratios:
        print("  adjacent ratios:", ", ".join(f"{r:.2f}" for r in ratios),
              "(~2 => slope halves per band)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
