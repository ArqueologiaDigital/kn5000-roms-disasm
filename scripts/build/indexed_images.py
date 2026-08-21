#!/usr/bin/env python3
"""indexed_images.py -- 8bpp ROM images <-> palette-indexed PNGs, ROUND TRIP.

QUESTION ANSWERED: can these images live in the repo as PNGs a human can look at, and still
rebuild the ROM byte for byte?

The project had bin->PNG converters for years and no way back, so every image artefact was a
VIEW of a blob that stayed the build input. This goes both ways, and `verify` asserts that
export-then-build is a no-op at the byte level. Once an image round-trips, the PNG can BE the
source and the blob stops being one.

THE PNGS STORE PALETTE INDICES, NOT COLOURS (PIL mode 'P'), so a pixel's byte value is the
ROM's byte value. Storing RGB would not round-trip: these palettes contain duplicate colours,
so RGB -> index is ambiguous.

    python3 scripts/build/indexed_images.py export   # bin -> png (run once)
    python3 scripts/build/indexed_images.py build    # png -> bin (build step)
    python3 scripts/build/indexed_images.py verify   # assert the round trip is exact

To add an image: give it a row in MANIFEST and run `export`, then `verify`. If verify fails,
the geometry is wrong -- which is a finding, not a nuisance. The HD-AE5000 icon was decoded at
28x28 for months when it is 27x27 in a 28-byte row, and a round-trip check would have caught it.
"""
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
PALETTE = REPO / 'v10' / 'maincpu' / 'images' / 'Palette_8bit_RGBA.bin'

# raw .bin (the ROM bytes), png, width, height, row stride
MANIFEST = [
    ('table_data/images/Wallpaper_0.bin', 'table_data/images/Wallpaper_0.png', 320, 240, 320),
    ('table_data/images/Wallpaper_1.bin', 'table_data/images/Wallpaper_1.png', 320, 240, 320),
    # Every other 8bpp image whose declared geometry matches its file size exactly.
    # Several are shared: the section-bank UI screens are incbin'd by BOTH
    # v10/maincpu and table_data/ui_bitmaps.s, so regenerating the .bin in place
    # serves both consumers without touching either source file.
    ('v10/maincpu/images/BitmapAccger16.bin', 'v10/maincpu/images/BitmapAccger16.png', 120, 95, 120),
    ('v10/maincpu/images/BitmapAccita16.bin', 'v10/maincpu/images/BitmapAccita16.png', 120, 95, 120),
    ('v10/maincpu/images/BitmapBmphk.bin', 'v10/maincpu/images/BitmapBmphk.png', 100, 120, 100),
    ('v10/maincpu/images/BitmapDrawbarNumberedSlider_1.bin', 'v10/maincpu/images/BitmapDrawbarNumberedSlider_1.png', 22, 222, 22),
    ('v10/maincpu/images/BitmapDrawbarNumberedSlider_2.bin', 'v10/maincpu/images/BitmapDrawbarNumberedSlider_2.png', 22, 222, 22),
    ('v10/maincpu/images/BitmapDrawbarNumberedSlider_3.bin', 'v10/maincpu/images/BitmapDrawbarNumberedSlider_3.png', 22, 222, 22),
    ('v10/maincpu/images/BitmapDredt0d.bin', 'v10/maincpu/images/BitmapDredt0d.png', 168, 119, 168),
    ('v10/maincpu/images/BitmapDredt0k.bin', 'v10/maincpu/images/BitmapDredt0k.png', 88, 119, 88),
    ('v10/maincpu/images/BitmapFadeInPicture.bin', 'v10/maincpu/images/BitmapFadeInPicture.png', 112, 25, 112),
    ('v10/maincpu/images/BitmapFadeInText.bin', 'v10/maincpu/images/BitmapFadeInText.png', 80, 18, 80),
    ('v10/maincpu/images/BitmapFadeOutPicture.bin', 'v10/maincpu/images/BitmapFadeOutPicture.png', 114, 25, 114),
    ('v10/maincpu/images/BitmapFadeOutText.bin', 'v10/maincpu/images/BitmapFadeOutText.png', 108, 20, 108),
    ('v10/maincpu/images/BitmapKN5000Logo.bin', 'v10/maincpu/images/BitmapKN5000Logo.png', 200, 36, 200),
    ('v10/maincpu/images/BitmapMIDIConnections_1.bin', 'v10/maincpu/images/BitmapMIDIConnections_1.png', 296, 108, 296),
    ('v10/maincpu/images/BitmapMIDIConnections_2.bin', 'v10/maincpu/images/BitmapMIDIConnections_2.png', 296, 108, 296),
    ('v10/maincpu/images/BitmapMIDIConnections_3.bin', 'v10/maincpu/images/BitmapMIDIConnections_3.png', 296, 108, 296),
    ('v10/maincpu/images/BitmapNtedt0d.bin', 'v10/maincpu/images/BitmapNtedt0d.png', 240, 127, 240),
    ('v10/maincpu/images/BitmapNtedt0k.bin', 'v10/maincpu/images/BitmapNtedt0k.png', 16, 127, 16),
    ('v10/maincpu/images/BitmapSomeArrows.bin', 'v10/maincpu/images/BitmapSomeArrows.png', 294, 6, 294),
    ('v10/maincpu/images/BitmapSplitPoint_A.bin', 'v10/maincpu/images/BitmapSplitPoint_A.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_Ab.bin', 'v10/maincpu/images/BitmapSplitPoint_Ab.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_B.bin', 'v10/maincpu/images/BitmapSplitPoint_B.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_Bb.bin', 'v10/maincpu/images/BitmapSplitPoint_Bb.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_C.bin', 'v10/maincpu/images/BitmapSplitPoint_C.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_D.bin', 'v10/maincpu/images/BitmapSplitPoint_D.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_Db.bin', 'v10/maincpu/images/BitmapSplitPoint_Db.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_E.bin', 'v10/maincpu/images/BitmapSplitPoint_E.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_Eb.bin', 'v10/maincpu/images/BitmapSplitPoint_Eb.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_F.bin', 'v10/maincpu/images/BitmapSplitPoint_F.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_G.bin', 'v10/maincpu/images/BitmapSplitPoint_G.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_Gb.bin', 'v10/maincpu/images/BitmapSplitPoint_Gb.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapSplitPoint_no_split.bin', 'v10/maincpu/images/BitmapSplitPoint_no_split.png', 58, 52, 58),
    ('v10/maincpu/images/BitmapTechnicsLogo.bin', 'v10/maincpu/images/BitmapTechnicsLogo.png', 312, 45, 312),
    ('v10/maincpu/images/BitmapWormWearingHat.bin', 'v10/maincpu/images/BitmapWormWearingHat.png', 24, 24, 24),
]


def rgb_palette():
    p = PALETTE.read_bytes()
    return b''.join(p[i:i + 3] for i in range(0, 1024, 4))


def export():
    pal = rgb_palette()
    for raw, png, w, h, stride in MANIFEST:
        data = (REPO / raw).read_bytes()
        img = Image.new('P', (w, h))
        img.frombytes(b''.join(data[y * stride:y * stride + w] for y in range(h)))
        img.putpalette(pal)
        img.save(REPO / png)
        print(f"  exported {png}")


def rebuild(raw, png, w, h, stride):
    img = Image.open(REPO / png)
    assert img.mode == 'P', f"{png}: must be palette-indexed, got {img.mode}"
    assert img.size == (w, h), f"{png}: expected {(w, h)}, got {img.size}"
    px = img.tobytes()
    if stride == w:
        return px
    pad = (REPO / raw).read_bytes()
    return b''.join(px[y * w:(y + 1) * w] + pad[y * stride + w:(y + 1) * stride] for y in range(h))


def build():
    tot = 0
    for raw, png, w, h, stride in MANIFEST:
        data = rebuild(raw, png, w, h, stride)
        (REPO / raw).write_bytes(data)
        tot += len(data)
    print(f"indexed_images: rebuilt {len(MANIFEST)} images, {tot:,} B from PNGs")


def verify():
    bad = 0
    for raw, png, w, h, stride in MANIFEST:
        want = (REPO / raw).read_bytes()
        got = rebuild(raw, png, w, h, stride)
        if got == want:
            print(f"  ok  {raw:<40} {len(want):>7,} B")
        else:
            bad += 1
            print(f"  *** {raw}: MISMATCH")
    if bad:
        sys.exit(f"{bad} image(s) do not round-trip")
    print("ROUND TRIP EXACT")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
