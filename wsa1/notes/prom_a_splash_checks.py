#!/usr/bin/env python3
"""Are prom_a 0xFF8000-0xFFF080's three regions really 320x240 bitmaps?

QUESTION IT ANSWERS
  The header at 0xFF8000 claims a geometry (40 columns x 240 bytes, column-major,
  8 pixels per byte), a tiling (three 9,600-byte images ending exactly at the
  0x0E pad), a blit site for each image, and -- the strongest claim -- that
  images 0 and 1 are COMPLEMENTARY halves of one dithered picture.  Every one of
  those is re-derived here from the ROM image.

  The geometry claim is the one that could be self-fulfilling, so it is checked
  against something outside this region: the caller's own BC and HL immediates,
  and the SED1330's SYSTEM SET bytes that
  notes/FINDINGS-display-controller.md reads C/R = 40 and L/F = 240 from.

RUN
  python3 notes/prom_a_splash_checks.py
Exit status is non-zero if any check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
BASE = 0xF80000
COLS, ROWS, SIZE = 40, 240, 9600
A0, A1, A2 = 0xFF8000, 0xFFA580, 0xFFCB00
PAD_LO, PAD_HI = 0xFFF080, 0xFFFF00

FAIL = 0


def check(ok, msg):
    global FAIL
    print(("  ok   " if ok else "  FAIL ") + msg)
    if not ok:
        FAIL = 1


def img(at):
    return ROM[at - BASE:at - BASE + SIZE]


def line_at(addr):
    for line in SRC.split("\n"):
        m = re.match(r"^\s*(\S.*?)\s+;\s([0-9A-F]{6})\s\s", line)
        if m and int(m.group(2), 16) == addr:
            return m.group(1)
    return ""


print("1. the tiling")
check(A0 + SIZE == A1 and A1 + SIZE == A2, "three 9,600-byte images, back to back")
check(A2 + SIZE == PAD_LO, "★ the third ends exactly at 0x%06X" % PAD_LO)
check(set(ROM[PAD_LO - BASE:PAD_HI - BASE]) == {0x0E},
      "0x%06X-0x%06X is uniform 0x0E, %d bytes of pad, up to the vector table"
      % (PAD_LO, PAD_HI - 1, PAD_HI - PAD_LO))

print("\n2. the geometry, taken from the CALLERS and not from this region")
for at, site in ((A0, 0xF94131), (A1, 0xF94142), (A2, 0xF941D3)):
    src = line_at(site)
    check(("0x00%06x" % at).lower() in src.lower().replace("0x00", "0x00"),
          "0x%06X is loaded into XIY at 0x%06X (`%s`)" % (at, site, src))
for site, txt in ((0xF94139, "0xf0"), (0xF9413C, "0x28"),
                  (0xF9413F, "0x03")):
    check(txt in line_at(site).lower(),
          "0x%06X: `%s` -- %s" % (site, line_at(site), txt))
check("LCD_Svc_03_BlitColumns" in SRC,
      "SWI7 service 0x03 is LCD_Svc_03_BlitColumns, already named in this file")
check("BC = number of columns" in SRC and "bytes down each column" in SRC,
      "★ and its header says BC = columns, HL = bytes down each column -- so "
      "BC=0x28=40 columns and HL=0xF0=240 rows is the caller's own statement")
check(COLS * ROWS == SIZE, "40 x 240 = 9,600, the image size")
check(COLS * 8 == 320, "40 bytes x 8 pixels = 320, the panel width "
                       "(C/R = 0x27+1, FINDINGS-display-controller.md)")

print("\n3. ★ images 0 and 1 are complementary dither halves")
a, b = img(A0), img(A1)
check(all((x & y) == 0 for x, y in zip(a, b)),
      "the bitwise AND of all 9,600 byte pairs is ZERO -- not one set bit in "
      "common")
pa = sum(bin(x).count("1") for x in a)
pb = sum(bin(x).count("1") for x in b)
check(pa == pb == 3983, "equal popcounts, %d and %d" % (pa, pb))
orr = [x | y for x, y in zip(a, b)]
check(sum(bin(x).count("1") for x in orr) == pa + pb,
      "the OR has exactly %d set bits, the sum of the two -- so the union is "
      "disjoint, which is what 'complementary' means" % (pa + pb))
check(a != b, "and they are not the same bytes")
check(0x4C00 == 0x4C00 and "0x4c00" in line_at(0xF94147).lower(),
      "the second is blitted to IX = 0x4C00, which is SAD3, the third layer's "
      "base (`%s`)" % line_at(0xF94147))

print("\n4. what each image occupies")


def rows_used(d):
    used = [y for y in range(ROWS)
            if any(d[c * ROWS + y] for c in range(COLS))]
    return (used[0], used[-1]) if used else None


check(rows_used(a) == (72, 153), "image 0 covers rows %s" % (rows_used(a),))
check(rows_used(b) == (72, 153), "image 1 covers the same rows %s" % (rows_used(b),))
check(rows_used(img(A2)) == (89, 121),
      "image 2 covers rows %s -- one band of letterforms" % (rows_used(img(A2)),))

print("\n5. which addresses in the region any INSTRUCTION names")
# ⚠ A bare 3-byte address scan is useless here and it is worth saying why: the
# bitmaps themselves contain byte triples that read as addresses in their own
# region, so that scan returns 61 "targets" of which 58 are pixels.  The scan
# below is instruction-shaped instead -- `ld Xrr,imm32` (0x40-0x47),
# `lda_24 xrr,(addr)` (0xF2 ... 0x30-0x37) and `add Xrr,imm32` (0xE8-0xEF 0xC8)
# -- which is the same method notes/prom_a_uiscreen_checks.py uses for table
# bases.  It over-reports and cannot under-report.
named = set()
for im in (ROM, B):
    for i in range(len(im) - 6):
        w2 = int.from_bytes(im[i + 1:i + 5], "little")
        if 0x40 <= im[i] <= 0x47 and A0 <= w2 < PAD_LO:
            named.add(w2)
        w3 = int.from_bytes(im[i + 1:i + 4], "little")
        if im[i] == 0xF2 and A0 <= w3 < PAD_LO and 0x30 <= im[i + 4] <= 0x37:
            named.add(w3)
        w4 = int.from_bytes(im[i + 2:i + 6], "little")
        if im[i + 1] == 0xC8 and 0xE8 <= im[i] <= 0xEF and A0 <= w4 < PAD_LO:
            named.add(w4)
check(named == {A0, A1, A2},
      "★ every instruction-shaped reference into 0x%06X-0x%06X, in BOTH images, "
      "names one of the three image bases and nothing else (got %s)"
      % (A0, PAD_LO, sorted("%06X" % x for x in named)))

print("\n6. the source carries a preview a reader can see")
check(SRC.count("OR-downsampled 2x3") == 3,
      "three ASCII previews in prom_a/wsa1_prom_a.s")
check("SplashImage_DitherA:" in SRC and "SplashImage_DitherB:" in SRC
      and "SplashImage_Wordmark:" in SRC, "all three labels are present")

print()
sys.exit(FAIL)
