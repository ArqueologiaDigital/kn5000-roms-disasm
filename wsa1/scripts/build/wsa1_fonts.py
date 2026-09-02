#!/usr/bin/env python3
"""wsa1_fonts.py -- the WSA1R's twelve character generators <-> PNG sheets, ROUND TRIP.

QUESTION ANSWERED (lane IMAGE, 2026-09-02): 47,504 bytes of prom_b -- 9.1% of
the whole image -- are glyph bitmaps, and until now they were `.byte` rows you
had to run a tool to see.  This makes each face ONE PNG contact sheet that is a
lossless, exact rendering of its bytes and from which those bytes are
regenerated:

    python3 scripts/build/wsa1_fonts.py export   # ROM  -> PNG sheets  (run once)
    python3 scripts/build/wsa1_fonts.py verify   # PNG  -> bytes == ROM
    python3 scripts/build/wsa1_fonts.py check    # PNG  -> assert the .s says this
    python3 scripts/build/wsa1_fonts.py rewrite  # PNG  -> patch the .s `.byte` values

================================================================================
THE TABLE, AND WHY EACH NUMBER IS NOT A GUESS
================================================================================

Bases, pitches and cell counts are notes/FINDINGS-fonts.md's, re-derivable with
`python3 notes/font_layout_check.py -v`.  ★ The twelve tables abut with NO
padding, so `next_base - base` divided by the pitch IS the cell count -- and the
six Latin faces come out at exactly 200 cells each across five different pitches
(8, 10, 14, 16, 32) while the three kana faces come out at exactly 120.  A wrong
pitch or a wrong base gives a fraction.  This script asserts every abutment.

The two STORAGE LAYOUTS come from the two blitters, not from the pictures --
notes/FINDINGS-fonts.md section 3:

* `LCD_BlitGlyph8` (prom_a 0xF8F0D8) sets CSRDIR DOWN, one CSRW, one MWRITE,
  then writes the glyph's bytes consecutively (`inc 1,IZ`).  Cursor down, one
  byte per step => **8 wide, one byte per row**.
* `LCD_BlitGlyph16` (prom_a 0xF8F2F1) writes the EVEN bytes down one column
  (`inc 2,IZ` from 0), then `inc 1,IX`, a fresh CSRW, and the ODD bytes down the
  next => **16 wide, two bytes per row, left byte first**.

⚠ `Font_Svc1C` is stored 16 wide but ADVANCES 11 pixels (`add (0x259e),0x0b` at
prom_a 0xF90367, and TextShift_LoadGlyph16's `and W,0xe0` keeps three bits of
the second byte: 8 + 3 = 11).  The sheet shows the full 16-wide cell, which is
what the bytes are; the 11 is the advance, not the storage.

⚠ `Font_Svc17` is 8 wide and advances 6 (`add (0x259e),0x06` at 0xF901F5).

PNG convention: 8-bit greyscale sheet, 16 cells per row, ink = BLACK (0), paper
= WHITE (255), and a 1-pixel GREY (160) gutter between cells so a 16x16 kanji
face is legible.  Only cell interiors are read back, so the gutter carries no
data -- but do not draw in it.
"""
import argparse
import os
import pathlib
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wsa1_bitmaps as WB                                    # noqa: E402

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required:  pip install Pillow")

ROOT = WB.ROOT
OUT = ROOT / 'prom_b' / 'images' / 'fonts'
COLS = 16
GUTTER = 160          # never confused with ink (0) or paper (255)

# label, base, pitch (bytes/glyph), width, cells, service, note
FACES = [
    ('Font_Svc06_8x14',  0xF1B400, 14,  8, 200, 0x06, 'Latin'),
    ('Font_Svc07_8x16',  0xF1BEF0, 16,  8, 200, 0x07, 'Latin'),
    ('Font_Svc08_16x16', 0xF1CB70, 32, 16, 200, 0x08, 'Latin'),
    ('Font_Svc17_8x8',   0xF1E470,  8,  8, 200, 0x17, 'Latin, proportional, 6 px advance'),
    ('Font_Svc1C_16x16', 0xF1EAB0, 32, 16, 200, 0x1C, 'Latin, proportional, 11 px advance'),
    ('Font_Svc1D_16x16', 0xF203B0, 32, 16, 120, 0x1D, 'hiragana'),
    ('Font_Svc16_8x14',  0xF212B0, 14,  8, 120, 0x16, 'half-width katakana'),
    ('Font_Svc19_16x16', 0xF21940, 32, 16, 120, 0x19, 'katakana'),
    ('Font_Svc1A_16x16', 0xF22840, 32, 16, 240, 0x1A, 'kanji, set A'),
    ('Font_Svc1F_16x16', 0xF24640, 32, 16,  60, 0x1F, 'kanji, set B'),
    ('Font_Svc20_8x10',  0xF24DC0, 10,  8, 200, 0x20, 'Latin'),
    ('Font_Svc21_16x24', 0xF25590, 48, 16, 128, 0x21, 'Latin'),
]
END = 0xF26D90        # 0xF25590 + 128 * 48; the last table has no successor


def check_abutment():
    """★ The cell counts ARE this arithmetic.  Assert it before using them."""
    for i, (name, base, pitch, w, cells, _svc, _n) in enumerate(FACES):
        nxt = FACES[i + 1][1] if i + 1 < len(FACES) else END
        span = nxt - base
        assert span % pitch == 0, f"{name}: {span} is not a multiple of pitch {pitch}"
        assert span // pitch == cells, \
            f"{name}: abutment gives {span // pitch} cells, table says {cells}"
        assert pitch == (w // 8) * (pitch // (w // 8)), name
    total = sum(c * p for _n, _b, p, _w, c, _s, _x in FACES)
    assert total == 47504, total
    return total


def cell_height(pitch, width):
    return pitch if width == 8 else pitch // 2


def glyph_grid(data, pitch, width):
    """data = one glyph.  Returns rows of pixels.

    8-wide: byte r IS row r.   16-wide: bytes 2r, 2r+1 are row r, left byte first.
    """
    h = cell_height(pitch, width)
    g = [[0] * width for _ in range(h)]
    for r in range(h):
        for half in range(width // 8):
            b = data[r * (width // 8) + half]
            for k in range(8):
                if b >> (7 - k) & 1:
                    g[r][half * 8 + k] = 1
    return g


def grid_glyph(g, pitch, width):
    out = bytearray(pitch)
    h = cell_height(pitch, width)
    for r in range(h):
        for half in range(width // 8):
            b = 0
            for k in range(8):
                if g[r][half * 8 + k]:
                    b |= 0x80 >> k
            out[r * (width // 8) + half] = b
    return bytes(out)


def sheet_path(name):
    return OUT / f'{name}.png'


def face_bytes(base, pitch, cells):
    romb, data = WB.rom('b')
    off = base - romb
    return data[off:off + pitch * cells]


def cmd_export(_):
    check_abutment()
    OUT.mkdir(parents=True, exist_ok=True)
    for name, base, pitch, w, cells, _svc, _n in FACES:
        d = face_bytes(base, pitch, cells)
        ch = cell_height(pitch, w)
        rows = (cells + COLS - 1) // COLS
        W = COLS * (w + 1) + 1
        H = rows * (ch + 1) + 1
        img = Image.new('L', (W, H), GUTTER)
        px = img.load()
        for i in range(cells):
            gx = 1 + (i % COLS) * (w + 1)
            gy = 1 + (i // COLS) * (ch + 1)
            g = glyph_grid(d[i * pitch:(i + 1) * pitch], pitch, w)
            for y in range(ch):
                for x in range(w):
                    px[gx + x, gy + y] = 0 if g[y][x] else 255
        img.save(sheet_path(name))
    print(f"exported {len(FACES)} font sheets to {OUT.relative_to(ROOT)}")
    return 0


def sheet_to_bytes(name, base, pitch, w, cells):
    ch = cell_height(pitch, w)
    rows = (cells + COLS - 1) // COLS
    img = Image.open(sheet_path(name)).convert('L')
    want = (COLS * (w + 1) + 1, rows * (ch + 1) + 1)
    if img.size != want:
        sys.exit(f"{name}: sheet is {img.size}, expected {want}")
    px = img.load()
    out = bytearray()
    for i in range(cells):
        gx = 1 + (i % COLS) * (w + 1)
        gy = 1 + (i // COLS) * (ch + 1)
        g = [[1 if px[gx + x, gy + y] < 128 else 0 for x in range(w)] for y in range(ch)]
        out += grid_glyph(g, pitch, w)
    return bytes(out)


def cmd_verify(_):
    tot = check_abutment()
    bad = 0
    for name, base, pitch, w, cells, _svc, _n in FACES:
        got = sheet_to_bytes(name, base, pitch, w, cells)
        want = face_bytes(base, pitch, cells)
        if got != want:
            i = next(k for k in range(len(want)) if got[k] != want[k])
            print(f"  MISMATCH {name} at 0x{base + i:06X}: sheet 0x{got[i]:02X}, "
                  f"ROM 0x{want[i]:02X}")
            bad += 1
    print(f"verify: {len(FACES)} faces, {tot:,} bytes, {bad} failures")
    return 1 if bad else 0


def _rewrite(apply_):
    check_abutment()
    lines, amap, dropped = WB.source_map('b')
    base_b, data = WB.rom('b')
    changed = 0
    for name, base, pitch, w, cells, _svc, _n in FACES:
        changed += WB.patch_lines(lines, amap, base,
                                  sheet_to_bytes(name, base, pitch, w, cells),
                                  data, base_b, name, apply_)
    if apply_ and changed:
        tmp = WB.SOURCES['b'].with_suffix('.s.tmp')
        tmp.write_text('\n'.join(lines), encoding='latin-1')
        os.replace(tmp, WB.SOURCES['b'])
    print(f"prom_b fonts: {changed} `.byte` value(s) "
          f"{'rewritten' if apply_ else 'would change'}"
          f"   (map guard discarded {dropped:,} unconfirmed slots)")
    return changed


def cmd_check(_):
    if _rewrite(False):
        print("check FAILED: the assembly does not match the font sheets")
        return 1
    print("check: every glyph table in the assembly is exactly what its sheet says")
    return 0


def cmd_rewrite(_):
    _rewrite(True)
    return 0


def cmd_list(_):
    tot = check_abutment()
    print(f"{len(FACES)} character generators, {tot:,} bytes\n")
    for i, (name, base, pitch, w, cells, svc, note) in enumerate(FACES):
        nxt = FACES[i + 1][1] if i + 1 < len(FACES) else END
        print(f"{name:18s} 0x{base:06X}-0x{nxt - 1:06X}  pitch {pitch:2d}  "
              f"{w}x{cell_height(pitch, w):<2d}  {cells:3d} cells  "
              f"{pitch * cells:6d} B  SWI7 svc 0x{svc:02X}  {note}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('command', choices=['export', 'verify', 'check', 'rewrite', 'list'])
    a = ap.parse_args()
    return globals()['cmd_' + a.command](a)


if __name__ == '__main__':
    sys.exit(main())
