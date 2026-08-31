#!/usr/bin/env python3
"""Render a WSA1 glyph table as ASCII art, so a "this is a font" claim can be seen.

QUESTION IT ANSWERS: "the SWI7 text services load a glyph from
<base> + code*<nbytes> and blit <nbytes> bytes -- is what lives at <base>
actually a character generator, and is it indexed by ASCII?"

The bit order is the one the pixel plotter's mask table at prom_a 0xF8EDAC
fixes: `80 40 20 10 08 04 02 01`, MSB leftmost.

WIDTH.  Two blit routines exist and they imply two storage layouts, both read
straight off the code:
  * `LCD_BlitGlyph8` (prom_a 0xF8F0D8 and its twin 0xF8F162) writes the glyph's
    bytes one after another down a single byte-column -- 8 pixels wide, one byte
    per row.  Pass width 8 (the default).
  * `LCD_BlitGlyph16` (prom_a 0xF8F2F1) writes the EVEN bytes down one column
    (`inc 2,IZ` from 0), then steps the cursor one byte right and writes the ODD
    bytes down the next -- 16 pixels wide, two bytes per row, row-major.
    Pass `--width 16`; the height is then nbytes/2.

    python3 notes/render_font.py 0xF1B400 14              # one glyph per line, 0x20-0x7E
    python3 notes/render_font.py 0xF1B400 14 --art 0x41   # draw glyph 0x41
    python3 notes/render_font.py 0xF1CB70 32 --width 16 --art 0x41
    python3 notes/render_font.py 0xF1B400 14 --ascii-check
        prints, for every code 0x20-0x7E, whether the glyph is blank; a real
        ASCII font is blank at 0x20 (space) and non-blank at every other
        printable code.  That is the check, and it is the one worth quoting.

Bases are CPU addresses; the image is picked from the address (prom_b covers
0xF00000-0xF7FFFF, prom_a 0xF80000-0xFFFFFF).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMGS = [(0xF00000, 0xF80000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")),
        (0xF80000, 0x1000000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"))]


def load(addr):
    for lo, hi, path in IMGS:
        if lo <= addr < hi:
            return open(path, "rb").read(), lo
    raise SystemExit("0x%06X is in neither image" % addr)


def glyph(data, base, lo, h, code):
    o = base - lo + code * h
    return data[o:o + h]


def art(rows, width=8):
    per = 1 if width == 8 else 2
    out = []
    for i in range(0, len(rows) - per + 1, per):
        line = ""
        for k in range(per):
            r = rows[i + k]
            line += "".join("#" if r & (0x80 >> b) else "." for b in range(8))
        out.append(line)
    return out


def main():
    base = int(sys.argv[1], 16)
    h = int(sys.argv[2], 0)
    width = 8
    if "--width" in sys.argv:
        width = int(sys.argv[sys.argv.index("--width") + 1], 0)
    data, lo = load(base)
    if "--ascii-check" in sys.argv:
        blank, nonblank = [], []
        for c in range(0x20, 0x7F):
            (blank if not any(glyph(data, base, lo, h, c)) else nonblank).append(c)
        print("0x%06X, %d bytes/glyph, codes 0x20-0x7E:" % (base, h))
        print("  blank    : %d  %s" % (len(blank), " ".join("0x%02X" % c for c in blank)))
        print("  non-blank: %d" % len(nonblank))
        print("  0x20 (space) blank : %s" % (0x20 in blank))
        print("  0x7E (tilde) drawn : %s" % (0x7E in nonblank))
        print("  every code 0x21-0x7E drawn: %s"
              % all(c in nonblank for c in range(0x21, 0x7F)))
        return
    if "--art" in sys.argv:
        spec = sys.argv[sys.argv.index("--art") + 1]
        if "-" in spec:
            a, b = spec.split("-")
            codes = range(int(a, 16), int(b, 16) + 1)
        else:
            codes = [int(spec, 16)]
        for c in codes:
            print("0x%02X %s" % (c, repr(chr(c)) if 32 <= c < 127 else ""))
            for line in art(glyph(data, base, lo, h, c), width):
                print("  " + line)
        return
    for c in range(0x20, 0x7F):
        g = glyph(data, base, lo, h, c)
        print("0x%02X %-4s %s" % (c, repr(chr(c)), g.hex(" ")))


if __name__ == "__main__":
    main()
