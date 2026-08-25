#!/usr/bin/env python3
"""Every site in CPU 1's ROMs that moves or reads P7 bit 1, the link's busy line.

QUESTION IT ANSWERS
    Emulation gap C (kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md): "After
    CPU 2 sends its first packet, CPU 1 leaves P7 bit 1 low forever.  Which arm
    of INT0_LinkByte drops it, which arm is supposed to raise it?"  Answering
    that needs the COMPLETE set of writers, not the ones a reader noticed.

METHOD
    P7 is SFR 0x13 (../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1361).  The
    bit-manipulation form on an 8-bit internal address is  F0 <addr> <op>, with
    op = 0xB0|n for RES n, 0xB8|n for SET n and 0xC8|n for BIT n
    (../mame/src/devices/cpu/tlcs900/dasm900.cpp, the `oprg` tables).  This
    censuses all three for every bit of P7, plus the `ldio P7,#` whole-register
    form (08 13 <imm>), over prom_a AND prom_b.

WHAT IS EXACT AND WHAT IS NOT
    A byte-window scan is an UPPER bound: a hit can be bytes inside another
    instruction or inside data.  Its ZEROES are exact -- if a pattern does not
    occur, no site spells it that way.  Every hit this prints for bit 0 and
    bit 1 lands inside prom_a 0xF8E000-0xF8E6A1, which is converted assembly, so
    for those two bits the hits ARE instruction boundaries and the counts are
    exact.  The `ldio P7,#` hits in prom_b are NOT: they are printed and
    explicitly flagged, because `08 13` is a common byte pair in data.

RUN
    python3 notes/prom_a_p7_link_census.py
Exit status is non-zero if the bit-1 census stops matching what
notes/FINDINGS-prom_a-link-receiver-busy.md says.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMGS = (("prom_a", open(os.path.join(ROOT, "original_ROMs",
                                     "wsa1_prom_a.ic12"), "rb").read(), 0xF80000),
        ("prom_b", open(os.path.join(ROOT, "original_ROMs",
                                     "wsa1_prom_b.ic13"), "rb").read(), 0xF00000))
P7 = 0x13
CONVERTED = (0xF8E000, 0xF8E6A2)     # the link block, converted assembly
fails = []


def scan(pat):
    out = []
    for tag, img, base in IMGS:
        i = 0
        while True:
            i = img.find(pat, i)
            if i < 0:
                break
            out.append((tag, base + i))
            i += 1
    return out


print("P7 (SFR 0x13) bit operations, prom_a + prom_b")
found = {}
for bit in range(8):
    for op, name in ((0xB0 | bit, "res"), (0xB8 | bit, "set"), (0xC8 | bit, "bit")):
        hits = scan(bytes([0xF0, P7, op]))
        if hits:
            found[(bit, name)] = hits
            print("  %s %d,(P7)  %2d: %s"
                  % (name, bit, len(hits),
                     ", ".join("%s 0x%06X" % h for h in hits)))
print("\n  whole-register `ldio P7,#` (08 13 imm) -- ⚠ byte-window, prom_b hits "
      "are data:")
for tag, addr in scan(b"\x08\x13"):
    print("    %-7s 0x%06X" % (tag, addr))

# ---- the claims notes/FINDINGS-prom_a-link-receiver-busy.md makes -----------
res1 = [a for t, a in found.get((1, "res"), []) if t == "prom_a"]
set1 = [a for t, a in found.get((1, "set"), []) if t == "prom_a"]
bit1 = [a for t, a in found.get((1, "bit"), []) if t == "prom_a"]
EXPECT_RES = [0xF8E4CD, 0xF8E4EC, 0xF8E522]
EXPECT_SET = [0xF8E258, 0xF8E5A8, 0xF8E5D6, 0xF8E5EB, 0xF8E663, 0xF8E68C]
EXPECT_BIT = [0xF8E627]
print("\nbit 1 -- the link's receiver-busy line")
print("  cleared at %d site(s): %s" % (len(res1), ["0x%06X" % a for a in res1]))
print("  set     at %d site(s): %s" % (len(set1), ["0x%06X" % a for a in set1]))
print("  tested  at %d site(s): %s" % (len(bit1), ["0x%06X" % a for a in bit1]))
if res1 != EXPECT_RES:
    fails.append("res 1,(P7) sites changed")
if set1 != EXPECT_SET:
    fails.append("set 1,(P7) sites changed")
if bit1 != EXPECT_BIT:
    fails.append("bit 1,(P7) sites changed")
if any(t == "prom_b" for t, _ in found.get((1, "res"), [])
       + found.get((1, "set"), []) + found.get((1, "bit"), [])):
    fails.append("prom_b now touches P7 bit 1")
for a in res1 + set1 + bit1:
    if not CONVERTED[0] <= a < CONVERTED[1]:
        fails.append("0x%06X is outside the converted link block" % a)

print("\nself-checks")
print("  every bit-1 site is inside the converted link block 0x%06X-0x%06X  %s"
      % (CONVERTED[0], CONVERTED[1] - 1, "ok" if not fails else "NO"))
for f in fails:
    print("  FAIL: " + f)
sys.exit(1 if fails else 0)
