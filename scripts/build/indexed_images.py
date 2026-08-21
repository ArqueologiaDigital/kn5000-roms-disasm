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
