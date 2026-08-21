#!/usr/bin/env python3
"""font_images.py -- the nine fixed-width glyph banks <-> PNG sheets, ROUND TRIP.

QUESTION ANSWERED: can the KN5000's fonts be looked at, in full, and still rebuild the ROM?

The committed BDFs stop at ASCII 95 characters. Every bank actually covers 0x20-0xFF, 224
glyphs, and the upper page is where the UI's arrows and markers and the Latin-1 accents live --
the part the multilingual UI depends on, and the part no readable artefact contained.

GLYPH FORMAT: column-major. ceil(width/8) columns, each column `height` bytes, MSB leftmost.
A sheet is 16 glyphs across and 14 down, in code order from 0x20.

THE SHEET IS RENDERED AT THE FULL BYTE WIDTH, ceil(width/8)*8, not at the glyph width. For a
6x8 font that means 8 px per cell, two of them beyond the glyph. Those bits are not always
zero, and rendering only 6 would silently drop them and break the round trip.

Font 5 is NOT here: it is proportional, tiled per Font5_KernTable, and needs the kern table to
place glyphs. It remains a blob (3,696 B) and is the one remaining font work item.

    python3 scripts/build/font_images.py export   # blob -> 9 sheets (run once)
    python3 scripts/build/font_images.py build    # sheets -> bins (build step)
    python3 scripts/build/font_images.py verify   # assert the round trip is exact
"""
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
BLOB = REPO / 'table_data' / 'includes' / 'icons_to_strings.bin'
IMG = REPO / 'table_data' / 'images' / 'fonts'
GEN = REPO / 'table_data' / 'includes' / 'generated'
NGLYPH = 224
COLS = 16

# label, offset, length, width, height
BANKS = [
    ('Font0_Glyphs', 0x0F38, 0x0E00,  8, 16),
    ('Font1_Glyphs', 0x1D38, 0x0E00,  8, 16),
    ('Font2_Glyphs', 0x2B38, 0x1C00, 16, 16),
    ('Font3_Glyphs', 0x4738, 0x0700,  6,  8),
    ('Font4_Glyphs', 0x4E38, 0x1C00, 11, 16),
    ('Font6_Glyphs', 0x7C28, 0x08C0,  8, 10),
    ('Font7_Glyphs', 0x84E8, 0x0E00,  8, 16),
    ('Font8_Glyphs', 0x92E8, 0x0E00,  8, 16),
    ('Font9_Glyphs', 0xA0E8, 0x1C00, 11, 16),
]


def cell(width):
    return ((width + 7) // 8) * 8      # full byte width, so padding bits survive


def export():
    IMG.mkdir(parents=True, exist_ok=True)
    blob = BLOB.read_bytes()
    for label, off, ln, w, h in BANKS:
        cw = cell(w)
        ncol = cw // 8
        gsz = ncol * h
        assert gsz * NGLYPH == ln, f'{label}: {gsz}*{NGLYPH} != {ln}'
        rows = (NGLYPH + COLS - 1) // COLS
        img = Image.new('1', (COLS * cw, rows * h), 0)
        px = img.load()
        for g in range(NGLYPH):
            base = off + g * gsz
            gx, gy = (g % COLS) * cw, (g // COLS) * h
            for c in range(ncol):
                for y in range(h):
                    b = blob[base + c * h + y]
                    for bit in range(8):
                        if b & (0x80 >> bit):
                            px[gx + c * 8 + bit, gy + y] = 1
        img.save(IMG / f'{label}.png')
    print(f"exported {len(BANKS)} glyph sheets to {IMG.relative_to(REPO)}")


def rebuild(label, w, h):
    cw = cell(w)
    ncol = cw // 8
    img = Image.open(IMG / f'{label}.png').convert('1')
    px = img.load()
    out = bytearray()
    for g in range(NGLYPH):
        gx, gy = (g % COLS) * cw, (g // COLS) * h
        for c in range(ncol):
            for y in range(h):
                b = 0
                for bit in range(8):
                    if px[gx + c * 8 + bit, gy + y]:
                        b |= (0x80 >> bit)
                out.append(b)
    return bytes(out)


def build():
    GEN.mkdir(parents=True, exist_ok=True)
    tot = 0
    for label, off, ln, w, h in BANKS:
        d = rebuild(label, w, h)
        assert len(d) == ln, f'{label}: {len(d)} != {ln}'
        (GEN / f'{label}.bin').write_bytes(d)
        tot += len(d)
    print(f"font_images: rebuilt {len(BANKS)} glyph banks, {tot:,} B from PNG sheets")


def verify():
    blob = BLOB.read_bytes()
    bad = 0
    for label, off, ln, w, h in BANKS:
        want = blob[off:off + ln]
        if rebuild(label, w, h) == want:
            print(f"  ok  {label:<16} {ln:>6,} B  ({w}x{h}, {NGLYPH} glyphs)")
        else:
            bad += 1
            print(f"  *** {label}: MISMATCH")
    if bad:
        sys.exit(f"{bad} bank(s) do not round-trip")
    print("ROUND TRIP EXACT")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
