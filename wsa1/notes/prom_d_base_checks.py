#!/usr/bin/env python3
"""prom_d BASE CHECKS -- is prom_d's base 0x00F00000, and is the 0xE80000 flash a
DIFFERENT PART from it?

WHAT QUESTION THIS ANSWERS
--------------------------
Round-1 audit finding F5: this tree ships two incompatible answers for prom_d's base.
`prom_d/prom_d.ld` says prom_d is the 512 KiB flash at CPU 2's 0xE80000;
`prom_d/wsa1_prom_d.s` and `notes/FINDINGS-memory-map.md` §5 say the base is 0x00F00000.
§5 left a third reading open -- "the two windows are the two halves of one larger part".

This script settles it from BYTES ONLY, never from the .s files, in three steps:

  1. prom_d's build tag `wsad_54.ssf` is at file offset 0x7FFF0, and prom_a reads
     eleven bytes from remote 0x00F7FFF0.  0x00F7FFF0 - 0x7FFF0 = 0x00F00000.
  2. prom_c's own flash driver bounds the 0xE80000 part.  `Flash_SectorErase` holds
     the device base 0x00E80000 and tests the requested sector against 0x00EF0000 for
     the TOP-boot sub-sector map, whose four erases are at device offsets 0x70000,
     0x78000, 0x7A000 and 0x7C000.  The highest of those covers 0x7C000-0x7FFFF, so
     the firmware's own model of that part ends at 0xE80000 + 0x7FFFF = 0x00EFFFFF --
     BELOW 0x00F00000.  A 1 MiB part would put its top boot block at 0x00F70000 and
     the compare would read 0x00F70000.
  3. The two addresses are installed as SEPARATE base slots by the same routine
     (`ExtBoard_ProbeAndInstallBases`: 0x00F00000 into RAM 0x00D7ED/0x00D7F1,
     0x00E80000 into 0x00D7F5).

It also re-counts the tail block the prom_d header describes: 60 of the 64 words at
file 0x7FF00 are 0xFFFFFFFF, not 64 -- the last four hold the build tag.  (Audit F5,
second half.)

⚠ WHAT THIS DOES NOT ESTABLISH.  Which PART prom_d is, or whether prom_d is a flash at
all.  Step 2 is a statement about the firmware's model of the device at 0xE80000; a
board could still carry one physical die decoded into two windows, but no firmware in
this set would be able to erase the upper one.

USAGE
    python3 notes/prom_d_base_checks.py            # 12 checks; FAILURES must be 0
    python3 notes/prom_d_base_checks.py --verbose  # print every value read
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs")
PROM_A_BASE = 0xF80000          # CPU 1
PROM_C_BASE = 0xF80000          # CPU 2 -- the two images occupy the same window on
                                # different processors; see FINDINGS-memory-map.md

fails = 0
verbose = "--verbose" in sys.argv


def check(name, got, want):
    global fails
    ok = got == want
    if not ok:
        fails += 1
    if verbose or not ok:
        print(f"  {'ok ' if ok else 'FAIL'}  {name}: got {got!r}, want {want!r}")
    else:
        print(f"  ok    {name}")


d = open(os.path.join(ROM, "wsa1_prom_d.bin"), "rb").read()
a = open(os.path.join(ROM, "wsa1_prom_a.ic12"), "rb").read()
c = open(os.path.join(ROM, "wsa1_prom_c.ic28"), "rb").read()


def at(img, base, addr, n):
    return img[addr - base: addr - base + n]


print("1. the build tag and the base it implies")
check("prom_d is 0x80000 bytes", len(d), 0x80000)
check("tag at file 0x7FFF0", d[0x7FFF0:0x7FFFB], b"wsad_54.ssf")
# prom_a 0xF82A5F: 40 f0 ff f7 00 = ld XWA,0x00F7FFF0 (opcode 0x40 = ld XWA,imm32)
insn = at(a, PROM_A_BASE, 0xF82A5F, 5)
check("prom_a 0xF82A5F is ld XWA,0x00F7FFF0", insn.hex(" "), "40 f0 ff f7 00")
remote = struct.unpack_from("<I", insn, 1)[0]
check("that remote address minus the tag's file offset is 0x00F00000",
      remote - 0x7FFF0, 0x00F00000)

print("2. the 0xE80000 part ends at 0x00EFFFFF -- prom_d cannot be it")
# 0xFC864B: 41 00 00 e8 00 = ld XBC,0x00E80000   (the device base the driver holds)
check("Flash_SectorErase holds base 0x00E80000 (0xFC864B)",
      at(c, PROM_C_BASE, 0xFC864B, 5).hex(" "), "41 00 00 e8 00")
# 0xFC86CF: ec cf 00 00 ef 00 = cp XIX,0x00EF0000  (the TOP-boot sector test)
check("its top-boot arm tests the sector against 0x00EF0000 (0xFC86CF)",
      at(c, PROM_C_BASE, 0xFC86CF, 6).hex(" "), "ec cf 00 00 ef 00")
tops = []
for site in (0xFC86DA, 0xFC86E7, 0xFC86F4, 0xFC8701):
    b = at(c, PROM_C_BASE, site, 6)          # e9 c8 <imm32> = add XBC,imm32
    assert b[:2] == bytes((0xE9, 0xC8)), (hex(site), b.hex(" "))
    tops.append(struct.unpack_from("<I", b, 2)[0])
check("its four top-boot sub-sector offsets", tops, [0x70000, 0x78000, 0x7A000, 0x7C000])
check("so the part's last byte is 0x00EFFFFF, below prom_d's base",
      0x00E80000 + max(tops) + 0x4000 - 1, 0x00EFFFFF)

print("3. the two bases are installed as separate slots, and the tail block")
check("ExtBoard_ProbeAndInstallBases: ld XBC,0x00F00000 at 0xFB051E",
      at(c, PROM_C_BASE, 0xFB051E, 5).hex(" "), "41 00 00 f0 00")
check("ExtBoard_ProbeAndInstallBases: ld XWA,0x00E80000 at 0xFB052D",
      at(c, PROM_C_BASE, 0xFB052D, 5).hex(" "), "40 00 00 e8 00")
words = [struct.unpack_from("<I", d, 0x7FF00 + 4 * i)[0] for i in range(64)]
check("words at file 0x7FF00 that are 0xFFFFFFFF",
      sum(1 for w in words if w == 0xFFFFFFFF), 60)
check("the four that are not are the last four (the build tag)",
      [i for i, w in enumerate(words) if w != 0xFFFFFFFF], [60, 61, 62, 63])

print()
print(f"FAILURES: {fails}")
sys.exit(1 if fails else 0)
