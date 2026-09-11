#!/usr/bin/env python3
r"""eq_seed_trajectory_probe.py -- N2: the seeded biquad state trajectory + the
store bits that say which cells are WRITTEN state vs passive input history.

QUESTION IT ANSWERS
    With UPD6383_BIQSEED_ONCE (seed the band-0 state once, then let it evolve) the
    recursion produces a non-degenerate trajectory. This probe reads the consecutive
    seeded frames and reports (a) how cells 0x64..0x67 move, and (b) the hi12 bit-4
    STORE gate on each band-0 word -- the direct test of whether a cell is written by
    the computation (a shared DF-II state) or only read (passive input history).

FINDING (seed-once at 2000000, BIQSEED=64, frames 2000001/2000002):
    * 0x64 is only READ (store_bit=0) -> the input x0.
    * 0x65 carries store_bit=1 (cur 0x02 reads it as an operand AND writes it) ->
      it is a COMPUTED state cell, the DF-II shared intermediate w: read as w[n-1],
      rewritten as w[n] in the same word. Its cross-frame value tracks the delayed
      input only because w ~= x when the feedback is small (low-signal degeneracy),
      NOT because it is a passive x1. This independently corroborates SHARED-DELAY
      (DF-II-family) and rules out textbook DF-I (which keeps a passive x1).
    * 0x66 evolves 0 -> 0.00663 -> 0.01543 (the recursive/output history), 0x67 its
      delayed copy.
    Still OPEN: DF-II canonical vs transposed -- needs the full state-update-law match
    with a rival that FAILS (biquad_topology_probe.py, saturating fixed point).

    Run: python3 dsp/tools/eq_seed_trajectory_probe.py [F0.txt F0p1.txt F0p2.txt]
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402
DATA = os.path.join(HERE, "..", "analysis", "data")
DEF = [os.path.join(DATA, f"kn5000-dsp-eq-seedonce-{t}-2026-09-11.txt")
       for t in ("F0", "F0p1", "F0p2")]

def frame(path):
    rows = parse_trace(open(path).read())
    starts = [i for i, r in enumerate(rows) if r["n"] == 0]
    return rows[starts[0]:(starts[1] if len(starts) > 1 else len(rows))] if starts else rows

def main():
    paths = sys.argv[1:4] if len(sys.argv) >= 4 else DEF
    frames = [frame(p) for p in paths]
    def cell(fr, c):
        rd = [r["mem"] for r in fr if r["dp"] == c and r["cur"] <= 0x05]
        return rd[0] if rd else None
    print("eq_seed_trajectory_probe: seeded band-0 state across frames")
    print("  cell      " + "   ".join(f"F{i}" for i in range(len(frames))))
    for c in range(0x64, 0x68):
        vals = "  ".join(f"{cell(fr, c)!s:>10}" for fr in frames)
        print(f"  0x{c:02X}   {vals}")
    # store bits on band-0 cells in the last (richest) frame
    fr = frames[-1]
    print("\n  band-0 store gate (hi12 bit4) per cell, last frame:")
    seen = set()
    for r in fr:
        if 0x64 <= r["dp"] <= 0x67 and r["cur"] <= 0x06 and (r["dp"], r["cur"]) not in seen:
            seen.add((r["dp"], r["cur"]))
            store = (((r["word"] >> 24) & 0xFFF) >> 4) & 1
            print(f"    dp=0x{r['dp']:02X} cur=0x{r['cur']:02X}  store={store}  "
                  f"coef={r['coef']:+.5f}")
    print("\n  READ: 0x65 store=1 -> written state (DF-II shared w), not passive x1;\n"
          "  corroborates shared-delay (DF-II-family). Canonical-vs-transposed still open.")

if __name__ == "__main__":
    main()
