#!/usr/bin/env python3
"""Print a WSA1 glyph table as a CONTACT SHEET -- many glyphs side by side.

QUESTION IT ANSWERS: "notes/render_font.py draws one glyph per screen, which is
fine for checking a single code but useless for reading a 224-glyph table.  What
does a whole code RANGE of one of these tables look like at once, and where does
the table actually START and STOP?"

WHY IT EXISTS: FINDINGS-fonts.md identified ten glyph tables and ran an ASCII
test on codes 0x20-0x7E only.  Five tables failed that test and were left
unnamed.  They failed because the window was wrong twice over:

  * the tables do NOT span 0x00-0xFF.  Read as 256 codes they OVERLAP each
    other -- e.g. 0xF1B400 + 256*14 = 0xF1C200, which is past the next table's
    base 0xF1BEF0.  `--extent` computes the real first and last code from the
    zero padding around the data, so a range test is asked of the right window.
  * codes 0x10-0x1F are NOT control codes here.  Every one of the ten tables
    defines them, and in the ASCII tables they are music-notation symbols.

    python3 notes/font_sheet.py 0xF212B0 14 --range 0x21-0x30
    python3 notes/font_sheet.py 0xF22840 32 --width 16 --range 0x10-0x17
    python3 notes/font_sheet.py --extent            # all ten tables' real ranges

The bit order (MSB leftmost) and the two storage layouts (8-wide = one byte per
row; 16-wide = even bytes down the left column, odd bytes down the right) are
read off prom_a's blitters and are documented in notes/render_font.py.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMGS = [(0xF00000, 0xF80000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")),
        (0xF80000, 0x1000000, os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"))]

# base, bytes/glyph, pixel width -- every row read out of prom_a's text services
# by notes/prom_a_byte_checks.py, which fails if any of it drifts.
TABLES = [(0xF1B400, 14, 8), (0xF1BEF0, 16, 8), (0xF1CB70, 32, 16),
          (0xF203B0, 32, 16), (0xF212B0, 14, 8), (0xF21940, 32, 16),
          (0xF22840, 32, 16), (0xF24640, 32, 16), (0xF24DC0, 10, 8),
          (0xF25590, 48, 16)]


def load(addr):
    for lo, hi, path in IMGS:
        if lo <= addr < hi:
            return open(path, "rb").read(), lo
    raise SystemExit("0x%06X is in neither image" % addr)


def rows(data, base, lo, n, width, code):
    o = base - lo + code * n
    g = data[o:o + n]
    per = 1 if width == 8 else 2
    out = []
    for i in range(0, len(g) - per + 1, per):
        line = ""
        for k in range(per):
            line += "".join("#" if g[i + k] & (0x80 >> b) else "." for b in range(8))
        out.append(line)
    return out


def extent(data, base, lo, n):
    """First and last code whose glyph cell is not entirely zero, searched over a
    window wide enough to run past the neighbouring tables, then reported with
    the interior gaps so a split table is visible rather than averaged away."""
    live = []
    for c in range(0, 512):
        o = base - lo + c * n
        if o < 0 or o + n > len(data):
            break
        if any(data[o:o + n]):
            live.append(c)
    return live


def main():
    if "--extent" in sys.argv:
        for base, n, w in sorted(TABLES):
            data, lo = load(base)
            live = extent(data, base, lo, n)
            blocks = []
            for c in live:
                if blocks and c == blocks[-1][1] + 1:
                    blocks[-1][1] = c
                else:
                    blocks.append([c, c])
            # a table stops where the NEXT table's data begins; drop every block
            # that starts at or after the next base.
            nxt = min((b for b, _, _ in TABLES if b > base), default=None)
            kept = [b for b in blocks if nxt is None or base + b[0] * n < nxt]
            print("0x%06X %2dB %2dw : %s" % (base, n, w,
                  "  ".join("0x%02X-0x%02X(%d)" % (a, b, b - a + 1) for a, b in kept)))
            if nxt is not None:
                last = kept[-1][1]
                print("            last code 0x%02X ends 0x%06X, next table base 0x%06X"
                      % (last, base + (last + 1) * n, nxt))
        return
    base = int(sys.argv[1], 16)
    n = int(sys.argv[2], 0)
    width = 8
    if "--width" in sys.argv:
        width = int(sys.argv[sys.argv.index("--width") + 1], 0)
    spec = sys.argv[sys.argv.index("--range") + 1]
    a, b = (int(x, 16) for x in spec.split("-"))
    data, lo = load(base)
    per_row = 16 if width == 8 else 8
    for start in range(a, b + 1, per_row):
        codes = list(range(start, min(start + per_row, b + 1)))
        print("  " + " ".join("0x%02X".ljust(width + 1) % c for c in codes))
        arts = [rows(data, base, lo, n, width, c) for c in codes]
        for r in range(len(arts[0])):
            print("  " + " ".join(a2[r] for a2 in arts))
        print()


if __name__ == "__main__":
    main()
