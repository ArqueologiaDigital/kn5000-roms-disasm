#!/usr/bin/env python3
r"""reverb_active_cells_probe.py -- N4: which D-RAM cells the unit-1 reverb actually
reads and writes each frame (the real delay-line taps), vs the REVSEED seed set.

QUESTION IT ANSWERS
    The REVSEED_ONCE impulse-decay test showed no clean decay even with a reverb
    selected (reverb_select.lua, page 0x0A): some seeded cells stayed frozen. This
    censuses the reverb frame's D-RAM accesses (reads and bit-4 stores) so the real
    delay-line/state cells are on record and the seed set can be corrected.

FINDING (reverb_select.lua, reverb page 0x0A, frame ~2000001):
    Most-active cells: 0x94 (45 reads / 5 stores -- the hub), 0x8B (30 / 4, NOT in
    the REVSEED set), 0xD0-0xD2, 0x88, 0x89, 0x8A, 0xFC. The current REVSEED set
    {0xD0,0x94,0x8A,0x85,0x8C,0x8F} includes DEAD cells: 0x85 = 4 reads / 0 stores
    (a coefficient, not a tap), 0x8C/0x8F barely touched -- which is why they stayed
    frozen and no decay appeared. Correct target set for the decay test: the cells
    with the most stores (written state) -- 0x94, 0x8B, 0xD0/0xD1/0xD2, 0x88, 0x89.
    Still OPEN: with the right cells seeded, does the delay line ADVANCE (§73-78) and
    decay per loop tracking the gains?

    Run: python3 dsp/tools/reverb_active_cells_probe.py <reverb-frame-trace.txt>
"""
import sys, os
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hle"))
from lle_trace_diff import parse_trace  # noqa: E402

REVSEED = {0xD0, 0x94, 0x8A, 0x85, 0x8C, 0x8F}

def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(2)
    rows = parse_trace(open(sys.argv[1]).read())
    starts = [i for i, r in enumerate(rows) if r["n"] == 0]
    fr = rows[starts[0]:(starts[1] if len(starts) > 1 else len(rows))] if starts else rows
    reads, stores = Counter(), Counter()
    for x in fr:
        if x["dp"] >= 0x80:
            reads[x["dp"]] += 1
            if (((x["word"] >> 24) & 0xFFF) >> 4) & 1:
                stores[x["dp"]] += 1
    print(f"reverb_active_cells_probe: {os.path.basename(sys.argv[1])}")
    print("  cell   reads  stores  seeded?  role")
    for c, n in reads.most_common(14):
        st = stores.get(c, 0)
        seeded = "SEED" if c in REVSEED else "  - "
        role = "DELAY/STATE" if st else "coef/const (frozen if seeded)"
        print(f"  0x{c:02X}    {n:4d}   {st:4d}    {seeded}   {role}")
    dead = sorted(c for c in REVSEED if stores.get(c, 0) == 0)
    live_unseeded = sorted(c for c, s in stores.items() if s >= 2 and c not in REVSEED)
    print(f"\n  REVSEED cells that are DEAD (0 stores): {['0x%02X'%c for c in dead]}")
    print(f"  active state cells NOT seeded (fix the target set): "
          f"{['0x%02X'%c for c in live_unseeded]}")

if __name__ == "__main__":
    main()
