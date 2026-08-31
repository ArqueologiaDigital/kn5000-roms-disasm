#!/usr/bin/env python3
"""How many sites in CPU 1's ROMs compute the `0x610000 + n*0xC00` bank index?

QUESTION IT ANSWERS
  FINDINGS-prom_b-block-store.md says the 3 KiB workspace at 0x00603400 is one
  of ten banks at 0x00610000 + n*0xC00, and that the index is always built the
  same way -- `sla 0x0B` (n*0x800) plus `sla 0x0A` (n*0x400).  "Always" is a
  quantity, so it needs a count, and a hand count of four sites was the first
  draft of the memory-map row.  This is the count.

WHAT COUNTS AS A SITE
  A 32-bit immediate 0x00610000 -- the four bytes `00 00 61 00` preceded by an
  `ld rr,imm32` opcode 0x40-0x47 -- that has BOTH shift immediates `EC 0B` and
  `EC 0A` somewhere in the 30 bytes either side of it.

WHAT IT DOES NOT CLAIM
  The window is a WINDOW, not a decode: a site is bytes near bytes.  It cannot
  distinguish an instruction from a coincidence, and it does not try -- which is
  why the number is reported as an upper bound and why the two sites the
  findings note actually argues from (0xF64B3D, 0xF64BE3) are named separately
  and were read as instructions.  A shift pair without the immediate, or a
  differently ordered computation, is invisible to it.

RUN
  python3 notes/prom_b_bank_index_census.py
  python3 notes/prom_b_bank_index_census.py --selftest
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMGS = (("prom_a", "wsa1_prom_a.ic12", 0xF80000),
        ("prom_b", "wsa1_prom_b.ic13", 0xF00000))
IMM = bytes((0x00, 0x00, 0x61, 0x00))
LD32 = set(range(0x40, 0x48))


def sites():
    out = {}
    for name, fn, base in IMGS:
        img = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        hits = []
        for i in range(1, len(img) - 4):
            if img[i:i + 4] == IMM and img[i - 1] in LD32:
                w = img[max(0, i - 30):i + 30]
                if b"\xec\x0b" in w and b"\xec\x0a" in w:
                    hits.append(base + i - 1)
        out[name] = hits
    return out


def main():
    s = sites()
    tot = sum(len(v) for v in s.values())
    print("`ld rr,0x00610000` with both `sla 0x0B` and `sla 0x0A` within 30 bytes")
    for k, v in s.items():
        print("  %s  %d sites" % (k, len(v)))
        for i in range(0, len(v), 8):
            print("    " + " ".join("0x%06X" % x for x in v[i:i + 8]))
    print("  TOTAL %d" % tot)
    print()
    print("The two this tree argues from, read as instructions, are")
    print("  0xF64B3D BStore_Workspace_LoadFromBank  (ld XIY,0x00610000 at 0xF64B4D)")
    print("  0xF64BE3 BStore_Workspace_SaveToBank    (ld XIX,0x00610000 at 0xF64BEC)")
    ok = 0xF64B4D in s["prom_b"] and 0xF64BEC in s["prom_b"]
    print("  both present in the census ... %s" % ("ok" if ok else "FAILED"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
