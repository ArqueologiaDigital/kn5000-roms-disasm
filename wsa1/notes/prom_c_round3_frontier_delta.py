#!/usr/bin/env python3
"""What did round 3 convert in prom_c, and did the frontier fall by exactly that?

QUESTION IT ANSWERS
  prom_c has no reachability frontier left to rank by -- `notes/prom_c_frontier.py`'s
  targets have been phantoms of linearly decoding data since the byte-stream pool was
  converted, and its own README says "rank prom_c by the .incbin list instead".  So the
  frontier for this image IS the `.incbin` list, and this script measures it before and
  after, from the files rather than from memory.

⚠ THE "BEFORE" IS RECORDED, NOT DERIVED, AND HERE IS WHY.
  Round 2's state was never committed: it lived in the worktree.  A delta against `HEAD`
  therefore measures rounds 2 AND 3 together, which is a different number and is printed
  separately below.  The round-2 `.incbin` list is written into this script as data, with
  the byte counts that `source_coverage.py` reported at the time (prom_c 384,067
  substantive / 11,005 `.incbin`).  Anyone can check the two numbers that matter without
  it: the AFTER column is computed, and 11,005 - 0 = 11,005 is what round 3 claims.

RUN
  python3 notes/prom_c_round3_frontier_delta.py            # the table
  python3 notes/prom_c_round3_frontier_delta.py --selftest # exit != 0 if it does not add up
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
PAT = r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)'
BASE = 0xF80000

# the round-2 worktree state, recorded because it was never committed
ROUND2 = [(0x04C81A, 0x268, "fp_constant_pool_FCC81A, left deliberately"),
          (0x05F7E0, 0x128D, "the tail data zone, part 1"),
          (0x060A6D, 0x783, "copy A's head"),
          (0x061361, 0x337, "the tail data zone, part 2"),
          (0x061698, 0xB4E, "copy B")]

# what round 3 emitted, by region
ROUND3 = [(0xFDF7E0, 0xFE11F0, "tail zone region 1 -- 26 objects"),
          (0xFE1361, 0xFE1698, "tail zone region 2 -- 24 objects"),
          (0xFE1698, 0xFE21E6, "copy B -- 51 objects"),
          (0xFCC81A, 0xFCCA82, "the floating-point constant pool -- 78 elements")]


def spans(text):
    return [(int(a, 16), int(n, 16)) for a, n in re.findall(PAT, text)]


def main():
    now = spans(open(SRC).read())
    head = spans(subprocess.run(["git", "show", "HEAD:prom_c/wsa1_prom_c.s"],
                                cwd=ROOT, capture_output=True, text=True).stdout)
    b2 = sum(n for _, n, _ in ROUND2)
    print("prom_c `.incbin` -- the only frontier this image has left")
    print("  BEFORE (round-2 worktree, recorded): %d span(s), %5d bytes" % (len(ROUND2), b2))
    for off, n, what in ROUND2:
        print("      0x%06X  %5d B  %s" % (BASE + off, n, what))
    print("  AFTER  (this worktree, computed)   : %d span(s), %5d bytes"
          % (len(now), sum(n for _, n in now)))
    print("  for context, HEAD (wave 4)         : %d span(s), %6d bytes"
          % (len(head), sum(n for _, n in head)))
    print()
    tot = 0
    print("  what round 3 emitted:")
    for lo, hi, what in ROUND3:
        print("      0x%06X-0x%06X  %5d B  %s" % (lo, hi - 1, hi - lo, what))
        tot += hi - lo
    print("      %s  %5d B  total" % (" " * 17, tot))
    ok = (sum(n for _, n in now) == 0 and tot == b2)
    print()
    print("  PREDICTED = OBSERVED: %d bytes of .incbin removed, %d bytes emitted -- %s"
          % (b2, tot, "match" if ok else "MISMATCH"))
    if "--selftest" in sys.argv:
        return 0 if ok else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
