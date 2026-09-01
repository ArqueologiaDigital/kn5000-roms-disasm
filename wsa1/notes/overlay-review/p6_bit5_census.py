#!/usr/bin/env python3
"""Which processor's P6 bit 5 is which?  (lane O1, overlay gap review)

QUESTION IT ANSWERS
-------------------
The kn7000_mame overlay driver calls P6 bit 5 the serial EEPROM's CHIP SELECT
("set 5,(P6) at 0xFC89CA opens every frame", wsa1.cpp block comment above
cpu2_p6_w()).  notes/FINDINGS-prom_a-for-the-mame-driver.md sec.5 calls P6 bit 5
"a power-control output", citing 0xF830AC ldio DMEMCR,0x2D / 0xF830B0 set 5,(P6)
/ 0xF830B3 halt.  Are these in conflict?

METHOD
------
SFR 0x12 is P6 on the TMP95C061 (MAME src/devices/cpu/tlcs900/tmp95c061.cpp maps
internal address 0x12 to the port 6 read/write handlers).  A bit instruction on
an 8-bit direct address encodes as  F0 <addr> <op>, with
    op = 0xA8+b  BIT b     0xB0+b  RES b     0xB8+b  SET b
so every BIT/RES/SET on P6 in an image is the byte triple  F0 12 (A8..BF).
Also count `ldio P6,imm` (08 12 imm) and `ldio P6FC,imm` (08 15 imm).

Run:  python3 p6_bit5_census.py
It prints, per image, every P6 bit operation with its CPU address.

WHAT A PASS LOOKS LIKE
----------------------
If the two claims are about DIFFERENT PROCESSORS, prom_a/prom_b (CPU 1) contain
P6 bit-5 sites ONLY in the power-fail NMI handler, and prom_c (CPU 2) contains
them ONLY in the EEPROM bit-banger at 0xFC89C5..0xFC8AD0.  Then both are right.
"""
import os, sys

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "original_ROMs")

# (file, cpu base address of the image, label)
IMAGES = [
    ("wsa1_prom_b.ic13", 0xF00000, "prom_b (CPU 1, IC13)"),
    ("wsa1_prom_a.ic12", 0xF80000, "prom_a (CPU 1, IC12)"),
    ("wsa1_prom_c.ic28", 0xF80000, "prom_c (CPU 2, IC28)"),
    ("wsa1_prom_d.bin",  0xF00000, "prom_d (CPU 2, tone database)"),
]

OPS = {}
for b in range(8):
    OPS[0xA8 + b] = f"bit {b},(P6)"
    OPS[0xB0 + b] = f"res {b},(P6)"
    OPS[0xB8 + b] = f"set {b},(P6)"

def main():
    total = {}
    for fn, base, label in IMAGES:
        path = os.path.join(BASE, fn)
        data = open(path, "rb").read()
        print(f"\n=== {label}  ({len(data)} bytes, base 0x{base:06X}) ===")
        hits = []
        for i in range(len(data) - 2):
            if data[i] == 0xF0 and data[i+1] == 0x12 and data[i+2] in OPS:
                hits.append((base + i, OPS[data[i+2]]))
        for a, op in hits:
            print(f"  0x{a:06X}  {op}")
        if not hits:
            print("  (no P6 bit instructions)")
        # ldio P6,imm  /  ldio P6FC,imm
        for sfr, name in ((0x12, "P6"), (0x15, "P6FC")):
            for i in range(len(data) - 2):
                if data[i] == 0x08 and data[i+1] == sfr:
                    print(f"  0x{base+i:06X}  ldio {name},0x{data[i+2]:02X}")
        total[label] = hits
    print("\n--- bit 5 only ---")
    for label, hits in total.items():
        five = [(a, op) for a, op in hits if op.split()[1].startswith("5,")]
        print(f"  {label}: {len(five)} site(s)  " +
              ", ".join(f"0x{a:06X} {op}" for a, op in five))

main()
