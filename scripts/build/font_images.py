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

Font 5 IS here, and it is proportional: widths 3..10, each glyph ceil(width/8)*16 bytes at its
own offset, the whole bank tiled exactly by Font5_KernTable (verified: the 224 entries are
monotonic, gapless, and sum to 0xE70). Its widths are read from the kern table already typed
out in table_data/fonts.s, so the source of truth stays in one place.

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


def font5_widths():
    """The 224 glyph widths, read from the kern table already typed out in fonts.s."""
    import re
    src = (REPO / 'table_data' / 'fonts.s').read_text()
    seg = src[src.index('Font5_KernTable:'):]
    pairs = re.findall(r'^\t\.short\t(\d+), (0x[0-9a-fA-F]+)', seg, re.M)[:NGLYPH]
    assert len(pairs) == NGLYPH, f'kern table: {len(pairs)} entries'
    return [(int(w), int(o, 0)) for w, o in pairs]


F5 = ('Font5_Glyphs', 0x6A38, 0x0E70)
F5_CELL = 16          # max ceil(width/8)*8 over widths 3..10


def font5_export(blob, palette_unused=None):
    ks = font5_widths()
    rows = (NGLYPH + COLS - 1) // COLS
    img = Image.new('1', (COLS * F5_CELL, rows * 16), 0)
    px = img.load()
    for g, (w, off) in enumerate(ks):
        ncol = (w + 7) // 8
        base = F5[1] + off
        gx, gy = (g % COLS) * F5_CELL, (g // COLS) * 16
        for c in range(ncol):
            for y in range(16):
                b = blob[base + c * 16 + y]
                for bit in range(8):
                    if b & (0x80 >> bit):
                        px[gx + c * 8 + bit, gy + y] = 1
    img.save(IMG / 'Font5_Glyphs.png')


def font5_rebuild():
    ks = font5_widths()
    img = Image.open(IMG / 'Font5_Glyphs.png').convert('1')
    px = img.load()
    out = bytearray()
    for g, (w, off) in enumerate(ks):
        assert len(out) == off, f'glyph {g}: kern says 0x{off:X}, built 0x{len(out):X}'
        ncol = (w + 7) // 8
        gx, gy = (g % COLS) * F5_CELL, (g // COLS) * 16
        for c in range(ncol):
            for y in range(16):
                b = 0
                for bit in range(8):
                    if px[gx + c * 8 + bit, gy + y]:
                        b |= (0x80 >> bit)
                out.append(b)
    return bytes(out)


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
    font5_export(blob)
    print(f"exported {len(BANKS) + 1} glyph sheets to {IMG.relative_to(REPO)}")


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
    d5 = font5_rebuild()
    assert len(d5) == F5[2], f'Font5: {len(d5)} != {F5[2]}'
    (GEN / 'Font5_Glyphs.bin').write_bytes(d5)
    tot += len(d5)
    print(f"font_images: rebuilt {len(BANKS) + 1} glyph banks, {tot:,} B from PNG sheets")


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
    want5 = blob[F5[1]:F5[1] + F5[2]]
    if font5_rebuild() == want5:
        print(f"  ok  {F5[0]:<16} {F5[2]:>6,} B  (proportional, widths 3-10)")
    else:
        bad += 1
        print(f"  *** {F5[0]}: MISMATCH")
    if bad:
        sys.exit(f"{bad} bank(s) do not round-trip")
    print("ROUND TRIP EXACT")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
