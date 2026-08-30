#!/usr/bin/env python3
"""Where does every CPU 1 interrupt vector actually end up?

QUESTION IT ANSWERS: "for each of the 33 slots of prom_a's vector table at
0xFFFF00, what routine finally runs -- after following the prom_b thunk the slot
usually points at, and the SECOND-level thunk some of those reach?"

The table is 33 slots because the part has 33: MAME's tmp95c061_irq_vector_map[]
(../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:322-346) lists the maskable ones
at 0x28-0x80, NMI is at 0x20 (tmp95c061.cpp:505) and the reset PC is fetched from
0xFFFF00 (tlcs900.cpp:215-217); 0x04-0x1C and 0x24 are the conventional SWI/INTWD
slots and MAME does not name them.

A slot is followed while the target is `1B lo mid hi` (`jp nnn`), to a depth of
4.  Everything printed is a byte read plus that one rule.

"Converted" is decided from the .incbin chain in prom_a/wsa1_prom_a.s AND
prom_b/wsa1_prom_b.s, so an address inside a converted routine but without a
label of its own is reported as such rather than as unknown.

⚠ Updated 2026-08-25 (prom_b lane, round 1).  This script used to read only
prom_a/wsa1_prom_a.s and printed "in prom_b -- not this lane" for any target
below 0xF80000, which was true of four slots -- INT6, INTT2, INTRX1 and INTTX1.
All four are now converted, so the script reads BOTH sources and the phrase is
gone.  Nothing else changed.

    python3 notes/vector_map.py
    python3 notes/vector_map.py --unconverted   # targets still inside an .incbin
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRCS = [(image_path(ROOT, "prom_a/wsa1_prom_a.s"), "wsa1_prom_a.ic12", 0xF80000),
        (image_path(ROOT, "prom_b/wsa1_prom_b.s"), "wsa1_prom_b.ic13", 0xF00000)]
IMGS = [(0xF00000, 0xF80000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")),
        (0xF80000, 0x1000000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"))]
VECTORS = 0xFFFF00
NAMES = {0x00: "RESET", 0x04: "SWI1", 0x08: "SWI2/INTUNDEF", 0x0C: "SWI3",
         0x10: "SWI4", 0x14: "SWI5", 0x18: "SWI6", 0x1C: "SWI7", 0x20: "NMI",
         0x24: "INTWD", 0x28: "INT0", 0x2C: "INT4", 0x30: "INT5", 0x34: "INT6",
         0x38: "INT7", 0x3C: "(reserved)", 0x40: "INTT0", 0x44: "INTT1",
         0x48: "INTT2", 0x4C: "INTT3", 0x50: "INTTR4", 0x54: "INTTR5",
         0x58: "INTTR6", 0x5C: "INTTR7", 0x60: "INTRX0", 0x64: "INTTX0",
         0x68: "INTRX1", 0x6C: "INTTX1", 0x70: "INTAD", 0x74: "INTTC0",
         0x78: "INTTC1", 0x7C: "INTTC2", 0x80: "INTTC3"}


def rd(addr, n):
    for lo, hi, path in IMGS:
        if lo <= addr < hi:
            d = open(path, "rb").read()
            return d[addr - lo:addr - lo + n]
    return None


def symbols():
    """address -> label, for every `; ADDRESS bytes` comment that a label owns."""
    out = {}
    for src, _, _ in SRCS:
        out.update(_symbols(src))
    return out


def _symbols(src):
    out, pend = {}, []
    for line in open(src):
        st = line.strip()
        if st.endswith(":") and not st.startswith(".") and " " not in st:
            pend.append(st[:-1])
            continue
        m = re.search(r";\s([0-9A-F]{6})\s", line)
        if m and pend:
            out[int(m.group(1), 16)] = pend[-1]
            pend = []
        elif st and not st.startswith(";"):
            pend = []
    return out


def still_incbin():
    """Every file range either source has NOT converted, from the .incbin chains."""
    spans = []
    for src, rom, base in SRCS:
        rx = re.compile(r'\.incbin "original_ROMs/%s", (0x[0-9A-Fa-f]+), '
                        r'(0x[0-9A-Fa-f]+)' % rom.replace(".", r"\."))
        for line in open(src):
            m = rx.search(line)
            if m:
                off, ln = int(m.group(1), 16), int(m.group(2), 16)
                spans.append((base + off, base + off + ln))
    return spans


def converted(addr, spans):
    if not (0xF00000 <= addr < 0x1000000):
        return None                      # outside CPU 1's two images
    return not any(lo <= addr < hi for lo, hi in spans)


def main():
    sym = symbols()
    spans = still_incbin()
    only_unconv = "--unconverted" in sys.argv
    print("slot  name            vector      chain")
    for off in range(0x00, 0x84, 4):
        v = int.from_bytes(rd(VECTORS + off, 4), "little")
        chain, a = [], v
        for _ in range(4):
            b = rd(a, 4)
            if b is None or b[0] != 0x1B:
                break
            a = b[1] | b[2] << 8 | b[3] << 16
            chain.append(a)
        final = chain[-1] if chain else v
        name = sym.get(final)
        conv = converted(final, spans)
        if conv is None:
            state = "in prom_b -- not this lane"
        elif name:
            state = name
        elif conv:
            state = "converted, inside another routine"
        else:
            state = "STILL .incbin"
        if only_unconv and (name or conv):
            continue
        path = " -> ".join("0x%06X" % c for c in chain)
        print("0x%02X  %-15s 0x%06X  %-24s %s"
              % (off, NAMES.get(off, "?"), v, path, state))


if __name__ == "__main__":
    main()
