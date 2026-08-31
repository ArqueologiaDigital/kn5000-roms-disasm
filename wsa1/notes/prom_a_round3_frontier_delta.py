#!/usr/bin/env python3
"""What did wave 5 ROUND 3 retire from prom_a's frontier, and does it add up?

QUESTION IT ANSWERS: "round 3 converted four ranges.  Did the unconverted
directory-slot count, the distinct-target count and the `.incbin` byte count
each fall by exactly what those four ranges account for?"

WHY IT IS SHAPED THIS WAY.  Round-2 audit F8 caught a report quoting a BEFORE
column that came from an uncommitted worktree, not from the command it cited,
and F15 recorded that all three rounds' deltas are measured against a baseline
that no longer exists.  So this script does NOT trust a remembered baseline: it
measures the AFTER state from the live worktree, measures what the four ranges
account for from the ROM and the prom_b directory, and requires

    AFTER + (what the four ranges account for) == the round-2-end figures that
    the round-2 audit independently verified: 475 slots / 424 targets /
    284,578 bytes.

If any of the three fails, either a range moved or the baseline was wrong.

    python3 notes/prom_a_round3_frontier_delta.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()

# The four ranges round 3 converted, [lo, hi).
ROUND3 = [(0xF80000, 0xF826A9), (0xF827C8, 0xF82CFF),
          (0xF92C62, 0xF96018), (0xF99021, 0xFA1404)]
# The round-2-END figures, verified independently by the round-2 audit.
R2_SLOTS, R2_TARGETS, R2_BYTES = 475, 424, 284578

FAILS = []


def check(name, cond, detail=""):
    print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                         ("  -- " + detail) if detail else ""))
    if not cond:
        FAILS.append(name)


def directory():
    """slot -> target, for every prom_b `jp` slot naming prom_a."""
    out = {}
    for a in range(0xF40000, 0xF44018, 4):
        o = a - 0xF00000
        if B[o] != 0x1B:
            continue
        t = B[o + 1] | B[o + 2] << 8 | B[o + 3] << 16
        if 0xF80000 <= t <= 0xFFFFFF:
            out[a] = t
    return out


def incbin_ranges():
    """[(lo, hi)] the `.incbin` spans prom_a/wsa1_prom_a.s still has."""
    rx = re.compile(r'\.incbin\s+"[^"]*wsa1_prom_a\.ic12",\s*(0x[0-9A-Fa-f]+),'
                    r'\s*(0x[0-9A-Fa-f]+)')
    out = []
    for line in open(SRC, encoding="utf-8"):
        m = rx.search(line)
        if m:
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            out.append((0xF80000 + o, 0xF80000 + o + n))
    return out


def main():
    dirmap = directory()
    inc = incbin_ranges()

    def unconverted(t):
        return any(lo <= t < hi for lo, hi in inc)

    after_slots = sum(1 for t in dirmap.values() if unconverted(t))
    after_targets = len({t for t in dirmap.values() if unconverted(t)})
    after_bytes = sum(hi - lo for lo, hi in inc)

    in_round3 = lambda t: any(lo <= t < hi for lo, hi in ROUND3)   # noqa: E731
    r3_slots = sum(1 for t in dirmap.values() if in_round3(t))
    r3_targets = len({t for t in dirmap.values() if in_round3(t)})
    r3_bytes = sum(hi - lo for lo, hi in ROUND3)

    print("round 3 converted %d range(s), %d bytes" % (len(ROUND3), r3_bytes))
    for lo, hi in ROUND3:
        n = len({t for t in dirmap.values() if lo <= t < hi})
        print("   0x%06X-0x%06X  %6d bytes  %3d distinct targets retired"
              % (lo, hi, hi - lo, n))
    print()
    print("%-28s %6s %6s %9s" % ("", "slots", "targets", "bytes"))
    print("%-28s %6d %6d %9d" % ("AFTER (live worktree)", after_slots,
                                 after_targets, after_bytes))
    print("%-28s %6d %6d %9d" % ("+ what round 3 retired", r3_slots, r3_targets,
                                 r3_bytes))
    print("%-28s %6d %6d %9d" % ("= reconstructed round-2 end",
                                 after_slots + r3_slots, after_targets + r3_targets,
                                 after_bytes + r3_bytes))
    print("%-28s %6d %6d %9d" % ("round-2 end, audit-verified", R2_SLOTS,
                                 R2_TARGETS, R2_BYTES))
    print()
    check("slots reconcile", after_slots + r3_slots == R2_SLOTS,
          "%d vs %d" % (after_slots + r3_slots, R2_SLOTS))
    check("distinct targets reconcile", after_targets + r3_targets == R2_TARGETS,
          "%d vs %d" % (after_targets + r3_targets, R2_TARGETS))
    check(".incbin bytes reconcile", after_bytes + r3_bytes == R2_BYTES,
          "%d vs %d" % (after_bytes + r3_bytes, R2_BYTES))
    check("self-check: no round-3 range is still `.incbin`",
          not any(any(l2 < hi and lo < h2 for l2, h2 in inc) for lo, hi in ROUND3))
    print("\n%d FAILED" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
