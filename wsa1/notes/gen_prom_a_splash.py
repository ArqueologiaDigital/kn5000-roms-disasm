#!/usr/bin/env python3
"""Emit prom_a 0xFF8000-0xFFFF00 -- three 320x240 BITMAPS and the pad after them.

QUESTION IT ANSWERS
  "The last 32 KiB of prom_a is 78% zero bytes with sparse bit patterns.  What
  is it, and how do I put it in the source so a reader can see it?"

  It is three full-screen 1-bit images.  This script emits them as `.byte` -- a
  bitmap has no better rendering in assembly -- but it puts an ASCII-ART PREVIEW
  of each one in the header, so the source shows what the data looks like
  without anyone having to run a tool, and it annotates every line with the
  COLUMN and ROW RANGE those bytes occupy on the panel.

  It refuses to print anything it has not first checked: the three images must
  be exactly 9,600 bytes each, images 0 and 1 must have zero bits in common and
  equal popcounts (the complementary-dither claim), and the tail must be uniform
  0x0E.

RUN
  python3 notes/gen_prom_a_splash.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xFF8000 0xFFFF00 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
COLS, ROWS = 40, 240          # 40 bytes across = 320 pixels; 240 lines
SIZE = COLS * ROWS            # 9600
IMGS = [(0xFF8000, "SplashImage_DitherA"),
        (0xFFA580, "SplashImage_DitherB"),
        (0xFFCB00, "SplashImage_Wordmark")]
PAD_LO, PAD_HI = 0xFFF080, 0xFFFF00


def img(at):
    return ROM[at - BASE:at - BASE + SIZE]


def bit(d, x, y):
    return (d[(x // 8) * ROWS + y] >> (7 - (x % 8))) & 1


def preview(d, ystep=3, xstep=2):
    """ASCII art, OR-downsampled, only over the rows that carry anything."""
    rows = [y for y in range(ROWS) if any(bit(d, x, y) for x in range(320))]
    if not rows:
        return ["; (every pixel clear)"]
    out = []
    for y in range(rows[0], rows[-1] + 1, ystep):
        line = []
        for x in range(0, 320, xstep):
            v = any(bit(d, xx, yy)
                    for xx in range(x, min(x + xstep, 320))
                    for yy in range(y, min(y + ystep, ROWS)))
            line.append("#" if v else " ")
        out.append(";   " + "".join(line).rstrip())
    return out


def bytes_lines(at, label):
    out = ["%s:" % label]
    d = img(at)
    for k in range(0, SIZE, 16):
        col, row = divmod(k, ROWS)
        out.append("\t.byte " + ", ".join("0x%02x" % b for b in d[k:k + 16])
                   + "   ; %06X  col %2d rows %3d-%3d"
                   % (at + k, col, row, row + 15))
    return out


def main():
    a, b = img(IMGS[0][0]), img(IMGS[1][0])
    if len(a) != SIZE or len(b) != SIZE:
        sys.exit("REFUSED: an image is not %d bytes" % SIZE)
    if any(x & y for x, y in zip(a, b)):
        sys.exit("REFUSED: images 0 and 1 share a set bit -- they are not "
                 "complementary dithers")
    pa = sum(bin(x).count("1") for x in a)
    pb = sum(bin(x).count("1") for x in b)
    if pa != pb:
        sys.exit("REFUSED: popcounts differ, %d vs %d" % (pa, pb))
    if IMGS[2][0] + SIZE != PAD_LO:
        sys.exit("REFUSED: the third image does not end at 0x%06X" % PAD_LO)
    tail = ROM[PAD_LO - BASE:PAD_HI - BASE]
    if set(tail) != {0x0E}:
        sys.exit("REFUSED: 0x%06X-0x%06X is not uniform 0x0E" % (PAD_LO, PAD_HI))

    out = [BANNER % (pa, pb, pa + pb)]
    for (at, name), hdr in zip(IMGS, (HDR_A, HDR_B, HDR_C)):
        out.append(hdr % (name, at, at + SIZE - 1))
        out += preview(img(at))
        out.append("; ---------------------------------------------------------------------")
        out += bytes_lines(at, name)
        out.append("")
    out.append("; 0x%06X-0x%06X -- %d bytes of 0x0E (RET), image-area padding."
               % (PAD_LO, PAD_HI - 1, PAD_HI - PAD_LO))
    out.append("; Checked byte by byte, not sampled: this generator refuses to")
    out.append("; emit the directive unless set(ROM[lo:hi]) == {0x0E}.")
    out.append("\t.fill %d, 1, 0x0E" % (PAD_HI - PAD_LO))
    print("\n".join(out))


BANNER = '''; ==============================================================================
; 0xFF8000-0xFFF080 -- THREE 320 x 240 BITMAPS, and how the ROM says so
; ==============================================================================
;
; Converted 2026-08-25 by notes/gen_prom_a_splash.py.  Verified by
; notes/prom_a_splash_checks.py.
;
; ★ THE GEOMETRY IS THE CALLER'S, NOT A GUESS.  prom_a 0xF94131 is
;
;     ld XIY,0x00FF8000 / ldw IX,0x0000 / ldw HL,0x00F0 / ldw BC,0x0028
;     ldb A,0x03 / swi 7
;
;   and SWI7 service 0x03 is `LCD_Svc_03_BlitColumns` (0xF8EDB4), whose header
;   in this file reads: XIY = source, BC = number of COLUMNS, HL = bytes down
;   each column, IX = the destination offset within the current layer.  So
;   BC = 40 columns, HL = 240 bytes per column, 40 x 240 = 9,600 bytes, and the
;   routine issues CSRDIR DOWN before it starts -- the source is stored
;   COLUMN-MAJOR and lands row-major in display RAM.
;
;   40 bytes x 8 pixels = 320 wide, 240 tall, which is exactly the panel:
;   notes/FINDINGS-display-controller.md reads C/R = 0x27+1 = 40 and
;   L/F = 0xEF+1 = 240 off the SED1330's own SYSTEM SET bytes.
;
;   PIXEL (x, y) IS BIT (7 - x%%8) OF BYTE (x/8)*240 + y.
;
; ★ AND THE THREE IMAGES TILE THE REGION: 0xFF8000 + 3 x 9,600 = 0xFFF080,
;   where 3,712 bytes of 0x0E padding run to the vector table at 0xFFFF00.
;   Each of the three is named by its own blit site -- 0xFF8000 at 0xF94131,
;   0xFFA580 at 0xF94142, 0xFFCB00 at 0xF941D3 -- and no other address in this
;   region is named by anything in either image.
;
; ★ IMAGES 0 AND 1 ARE COMPLEMENTARY HALVES OF ONE DITHERED PICTURE, and that
;   is arithmetic rather than impression: they have **NO SET BIT IN COMMON**
;   (bitwise AND over all 9,600 bytes is zero), and their popcounts are EQUAL
;   -- %d and %d, summing to %d.  Two disjoint half-tones of the same
;   artwork, going to two different display layers (IX = 0x0000 and IX =
;   0x4C00, and 0x4C00 is SAD3, the third layer's base).  The SED1330
;   OR-composites its layers, so together they make the solid shape; alone,
;   either is a 50%% grey of it.
;
; ⚠ WHAT THE ARTWORK SAYS IS NOT ESTABLISHED for images 0 and 1.  The preview
;   below shows a large italic script logotype in four glyph-like clusters,
;   occupying rows 72-153 of the panel.  This file does not name it.  Image 2 is
;   different: it is plainly the word TECHNICS in a bold face, and the preview
;   shows it.
; =============================================================================='''

HDR_A = '''
; ---------------------------------------------------------------------
; %s -- 9,600 bytes, 0x%06X-0x%06X
;
; Blitted by 0xF94131 with IX = 0x0000, i.e. to offset 0 of the layer that
; (0x2540) selects.  One of the two disjoint dither halves.
; Non-empty rows: 72-153.  Preview, OR-downsampled 2x3:
; ---------------------------------------------------------------------'''

HDR_B = '''
; ---------------------------------------------------------------------
; %s -- 9,600 bytes, 0x%06X-0x%06X
;
; Blitted by 0xF94142 with IX = 0x4C00 -- SAD3, the third graphics layer's base
; (notes/FINDINGS-display-controller.md sec. on SCROLL).  The other dither half:
; it shares no set bit with the first and has the same number of them.
; Non-empty rows: 72-153.  Preview, OR-downsampled 2x3:
; ---------------------------------------------------------------------'''

HDR_C = '''
; ---------------------------------------------------------------------
; %s -- 9,600 bytes, 0x%06X-0x%06X
;
; Blitted by 0xF941D3, which sets (0x2540) = 1 immediately before it and passes
; IX = 0x0000.  Not dithered: solid pixels.
; Non-empty rows: 89-121 -- a single band of large letterforms.  Preview,
; OR-downsampled 2x3:
; ---------------------------------------------------------------------'''

if __name__ == "__main__":
    main()
