#!/usr/bin/env python3
"""How many 32-entry dispatch tables sit at prom_b 0xF7D2D8, and how do we know?

QUESTION ANSWERED
  0xF7D000 is a stub block two of the thunk table's busier slots point at
  (T_F431B0 x53, T_F431B4 x57).  Most of its stubs do `ld XIX,<some address> /
  call 0xF41B08 / ret`, and 0xF41B08 is a thunk to prom_a 0xF8BDC5, which calls
  entry HL of the table in XIX after masking HL to 5 bits.  So the addresses are
  32-entry tables.  This script establishes how many there are and where they
  stop, without taking the stub block's word for it.

THREE INDEPENDENT COUNTS, all re-derived here from the ROM bytes
  1. BLOCK SCAN.  Walk 128-byte blocks upward from 0xF7D2D8 while every one of a
     block's 32 words is in 0x00F00000-0x00FFFFFF.
  2. IMMEDIATE CENSUS.  Count the `ld XIX,imm32` instructions (opcode 0x44) in
     0xF7D000-0xF7D2D7 and check their immediates land on 128-byte boundaries of
     the family.
  3. LAST TABLE.  The highest immediate plus 128 must equal the end the block
     scan found.
  If the three disagree, the script says so and exits non-zero.

WHY 32 ENTRIES, and it is prom_a that says so
  prom_a 0xF8BDC5:  cp HL,0x1F / jr UGT,<ret> / ... / and L,0x1F / sla 2,L /
                    ld XIX,(XIX+L) / call XIX
  The `and L,0x1F` and the `sla 2` are the whole argument: 32 slots, 4 bytes each.

RUN
  python3 notes/prom_b_f7d_tables.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B_BASE = 0xF00000
A_BASE = 0xF80000
STUB_LO, STUB_HI = 0xF7D000, 0xF7D2D8
FAMILY = 0xF7D2D8
STRIDE = 0x80


def main():
    b = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    a = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
    L = lambda p: int.from_bytes(b[p - B_BASE:p - B_BASE + 4], "little")

    # the prom_a consumer, byte for byte
    want = bytes([0xCF, 0xCC, 0x1F,           # and L,0x1F
                  0xCF, 0xEC, 0x02,           # sla 0x02,L
                  0xE3, 0x03, 0xF0, 0xEC, 0x24,   # ld XIX,(XIX+L)
                  0xB4, 0xE8])                # call XIX
    got = a[0xF8BDEA - A_BASE:0xF8BDEA - A_BASE + len(want)]
    print("prom_a 0xF8BDEA is `and L,0x1F / sla 2,L / ld XIX,(XIX+L) / call XIX`: %s"
          % ("YES" if got == want else "NO -- %s" % got.hex()))
    ok = got == want

    # 1. block scan
    n, p = 0, FAMILY
    while all(0xF00000 <= L(p + 4 * i) <= 0xFFFFFF for i in range(32)):
        n += 1
        p += STRIDE
    print("1. block scan: %d consecutive all-pointer 128-byte blocks, ending 0x%06X"
          % (n, p))
    print("   first word of the block after them (0x%06X) = 0x%08X" % (p, L(p)))

    # 2. immediate census
    imms = []
    o = STUB_LO
    while o < STUB_HI:
        if b[o - B_BASE] == 0x44:
            imms.append((o, int.from_bytes(b[o - B_BASE + 1:o - B_BASE + 5], "little")))
        o += 1
    aligned = [v for _, v in imms if FAMILY <= v < p and (v - FAMILY) % STRIDE == 0]
    print("2. `ld XIX,imm32` in the stub block: %d; landing on a table base: %d; "
          "distinct tables named: %d" % (len(imms), len(aligned), len(set(aligned))))

    # 3. last table
    hi = max(aligned)
    print("3. highest table named: 0x%06X ; + 0x80 = 0x%06X" % (hi, hi + STRIDE))

    agree = (len(imms) == len(aligned) == len(set(aligned)) == n) and (hi + STRIDE == p)
    print()
    print("VERDICT: %s -- %d tables of 32 entries, 0x%06X-0x%06X"
          % ("the three counts AGREE" if agree else "the counts DISAGREE",
             n, FAMILY, p - 1))
    return 0 if (agree and ok) else 1


if __name__ == "__main__":
    sys.exit(main())
