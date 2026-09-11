#!/usr/bin/env python3
r"""reverb_decay_probe.py -- N4: does the reverb delay line decay when seeded once?

QUESTION IT ANSWERS
    With REVSEED retargeted to the MEASURED delay-line cells (0x94, 0x8B, 0xD0, 0xD1,
    0xD2, 0x8A -- reverb_active_cells_probe.py) and REVSEED_ONCE seeding them once on
    the DIGITAL REVERB page (reverb_select.lua), do those cells show a decaying echo
    train across consecutive frames? Reports each cell's per-frame ratio.

FINDING (seed-once at 2000000, REVSEED=8, frames 2000001..2000004):
    The seeded delay-line cells show STABLE GEOMETRIC per-frame ratios -- the reverb's
    linear feedback datapath is operating (unlike the dead-cell run, which stayed
    frozen):
        0xD0 -> x0.767 (decay)      0xD2 -> x0.547 (decay)     0x8A -> x0.547 (decay)
        0x8B -> x2.024 (growth -- an accumulator or a factor-of-2 coefficient)
    Ratios are constant to 4 decimals across all 3 steps => clean linear behaviour.
    So the seed-once impulse-decay METHOD works and the reverb feedback is live.
    Still OPEN: mapping these per-frame ratios to the all-pass gains (0.91 / 0.1367)
    needs the delay-line length/structure (§73-78) -- the per-frame ratio is not the
    single-tap gain until the loop structure is known; and 0x8B's x2.024 growth needs
    the same structural read (likely the C-RAM>>1 factor-of-2 seen in the biquad).

    Run: python3 dsp/tools/reverb_decay_probe.py <frame1.txt> <frame2.txt> ...
"""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402
DATA = os.path.join(HERE, "..", "analysis", "data")
CELLS = [0x94, 0x8B, 0xD0, 0xD1, 0xD2, 0x8A]

def frame(p):
    r = parse_trace(open(p).read())
    s = [i for i, x in enumerate(r) if x["n"] == 0]
    return r[s[0]:(s[1] if len(s) > 1 else len(r))] if s else r

def main():
    paths = sys.argv[1:] if len(sys.argv) > 1 else [
        os.path.join(DATA, f"kn5000-dsp-reverb-decay-F{i}-2026-09-11.txt") for i in range(1, 5)]
    frames = [frame(p) for p in paths]
    def cell(fr, c):
        return next((x["mem"] for x in fr if x["dp"] == c), None)
    print("reverb_decay_probe: %d frames" % len(frames))
    print("  cell   " + "  ".join(f"F{i+1:>9}" for i in range(len(frames))))
    for c in CELLS:
        vals = [cell(fr, c) for fr in frames]
        print(f"  0x{c:02X}   " + "  ".join(f"{(round(v,6) if v is not None else None)!s:>10}" for v in vals))
    print("\n  per-frame ratio (constant <1 = geometric decay tracking a gain):")
    for c in CELLS:
        vals = [cell(fr, c) for fr in frames]
        if all(v is not None for v in vals):
            rs = [vals[i + 1] / vals[i] if vals[i] else None for i in range(len(vals) - 1)]
            if any(r is not None for r in rs):
                print(f"    0x{c:02X}: " + " ".join(f"{r:.4f}" if r is not None else "--" for r in rs)
                      + ("   <- DECAY" if rs[0] and rs[0] < 1 else "   <- growth" if rs[0] else ""))
    print("\n  READ: constant ratios => the reverb feedback datapath is live on these cells;\n"
          "  mapping the ratios to the all-pass gains needs the delay structure (§73-78).")

if __name__ == "__main__":
    main()
