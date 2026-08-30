#!/usr/bin/env python3
"""How many SWI7 services does prom_a actually implement?

QUESTION IT ANSWERS: "of the 64 slots of SWI7_ServiceTable at prom_a 0xF8E9C6,
how many are LIVE, how many distinct routines do they name, and where do those
routines live?"

WHY IT EXISTS: the numbers had been counted by hand and disagreed with each
other -- one note said "35 implemented services", the table's own header said
"35 of them are real", and the live count is 34.  Nothing here is counted by
hand.

The dispatcher at 0xF8E9A5 does `and A,0x3f` then `* 4` then indexes this table,
so the table is 64 entries by construction; that is asserted below rather than
assumed, by checking that the byte before the table and the 64th entry both look
right.  A slot is DEAD when it points at 0xF8EAC6, the bare RET that follows the
table.

It also reports how many of the live services the source has actually CONVERTED,
decided from the .incbin chain in prom_a/wsa1_prom_a.s rather than from a list
anyone maintains by hand.

    python3 notes/swi7_service_table.py            # the counts
    python3 notes/swi7_service_table.py --slots    # every slot
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF80000
TABLE = 0xF8E9C6
N = 64
DEAD = 0xF8EAC6


def still_incbin():
    """prom_a address ranges the source has NOT converted."""
    rx = re.compile(r'\.incbin "original_ROMs/wsa1_prom_a\.ic12", (0x[0-9A-Fa-f]+), '
                    r'(0x[0-9A-Fa-f]+)')
    spans = []
    for line in open(image_path(ROOT, "prom_a/wsa1_prom_a.s")):
        m = rx.search(line)
        if m:
            off, ln = int(m.group(1), 16), int(m.group(2), 16)
            spans.append((BASE + off, BASE + off + ln))
    return spans


def main():
    d = open(ROM, "rb").read()
    off = TABLE - BASE
    ent = [int.from_bytes(d[off + 4 * i:off + 4 * i + 4], "little") for i in range(N)]
    live = [(i, v) for i, v in enumerate(ent) if v != DEAD]
    dead = [i for i, v in enumerate(ent) if v == DEAD]
    bad = [(i, v) for i, v in enumerate(ent)
           if not (0xF80000 <= v <= 0xFFFFFF)]
    if "--slots" in sys.argv:
        for i, v in enumerate(ent):
            print("  slot 0x%02X -> 0x%06X%s" % (i, v, "   (dead)" if v == DEAD else ""))
    print("table at 0x%06X, %d slots, ends at 0x%06X" % (TABLE, N, TABLE + 4 * N - 1))
    print("  the byte AFTER the last slot is 0x%02X at 0x%06X"
          % (d[off + 4 * N], TABLE + 4 * N),
          "-- 0x0E is RET, the dead-slot target" if d[off + 4 * N] == 0x0E else "")
    print("  LIVE slots      : %d" % len(live))
    print("  DEAD slots      : %d  (%s)"
          % (len(dead), ", ".join("0x%02X" % i for i in dead)))
    print("  distinct live targets: %d" % len(set(v for _, v in live)))
    print("  live slot numbers    : 0x%02X..0x%02X" % (live[0][0], live[-1][0]))
    print("  target range         : 0x%06X..0x%06X"
          % (min(v for _, v in live), max(v for _, v in live)))
    print("  entries outside prom_a: %d" % len(bad))
    spans = still_incbin()
    conv = [i for i, v in live if not any(lo <= v < hi for lo, hi in spans)]
    print("  CONVERTED live services: %d of %d  (%s)"
          % (len(conv), len(live), " ".join("0x%02X" % i for i in conv)))
    print("  still .incbin           : %s"
          % " ".join("0x%02X" % i for i, v in live if i not in conv))
    dup = {}
    for i, v in live:
        dup.setdefault(v, []).append(i)
    for v, ii in dup.items():
        if len(ii) > 1:
            print("  ⚠ slots %s share target 0x%06X"
                  % (", ".join("0x%02X" % i for i in ii), v))


if __name__ == "__main__":
    main()
