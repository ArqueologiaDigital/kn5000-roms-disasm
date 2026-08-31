#!/usr/bin/env python3
"""How far up does CPU 1's CS1 static RAM actually get used?

QUESTION IT ANSWERS: the MAME driver maps CPU 1's SRAM as 0x000080-0x0051FF,
because that is the span the boot block clears (0x1460 longwords from 0x000080,
prom_a 0xF8278A).  The driver's own comment says that is "a lower bound, not the
size".  This raises the lower bound from reference evidence: every 16-bit memory
operand in prom_a and prom_b that names an address above the cleared span and
below 0x8000.

RUN:  python3 notes/cs1_sram_extent.py            # the census
      python3 notes/cs1_sram_extent.py --top 20   # busiest addresses
      python3 notes/cs1_sram_extent.py --selftest

★ WHAT THIS DOES NOT SHOW: the chip's size.  It shows the highest address the
firmware is observed to touch, which is still a lower bound -- a bigger part with
an unused top would look identical.  The map should follow the evidence, not the
part number, until a part number is established.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asm_source import image_lines

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = (("prom_a", "prom_a/wsa1_prom_a.s"), ("prom_b", "prom_b/wsa1_prom_b.s"))
CLEARED_TOP = 0x5200          # first address past the boot block's cleared span
CS1_TOP     = 0x8000          # first address past the CS1 window on this CPU
OPERAND = re.compile(r'\((0x[0-9a-fA-F]{4})\)')


def census():
    hits = {}
    for tag, rel in IMAGES:
        for ln in image_lines(ROOT, rel):
            for m in OPERAND.finditer(ln):
                v = int(m.group(1), 16)
                if CLEARED_TOP <= v < CS1_TOP:
                    e = hits.setdefault(v, [0, set()])
                    e[0] += 1
                    e[1].add(tag)
    return hits


def main():
    h = census()
    tot = sum(n for n, _ in h.values())
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        # invariants, not pinned counts -- a pinned total goes stale the moment a
        # lane converts more of either image.
        ck("something is referenced above the cleared span at all", bool(h))
        ck("the highest referenced address is above the driver's 0x0051FF limit",
           max(h) > 0x51FF, "highest = 0x%04X" % max(h))
        ck("every hit is inside the CS1 window", all(CLEARED_TOP <= v < CS1_TOP for v in h))
        ck("prom_a's checksum words 0x7FD2 and 0x7FD4 are among them",
           0x7FD2 in h and 0x7FD4 in h)
        ck("0x7620, which prom_a's header calls CS1 static RAM, is among them", 0x7620 in h)
        ck("at least one address is touched by BOTH images",
           any(len(t) == 2 for _n, t in h.values()))
        print("\n6 checks, %d failures" % f)
        return 1 if f else 0
    if "--top" in sys.argv:
        n = int(sys.argv[sys.argv.index("--top") + 1])
        print("busiest CS1 addresses above the driver's limit:")
        for v, (c, t) in sorted(h.items(), key=lambda kv: -kv[1][0])[:n]:
            print("   0x%04X  %4d ref(s)   %s" % (v, c, ",".join(sorted(t))))
        return 0
    print("CPU 1 CS1-space addresses referenced above the driver's 0x0051FF limit")
    print("  distinct addresses : %d" % len(h))
    print("  references total   : %d" % tot)
    print("  highest referenced : 0x%04X" % max(h))
    print("  touched by BOTH images: %d" % sum(1 for _n, t in h.values() if len(t) == 2))
    print("\n★ a lower bound on the chip, not its size -- see the docstring.")
    return 0

sys.exit(main())
