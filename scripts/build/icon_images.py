#!/usr/bin/env python3
"""icon_images.py -- the 177 UI icons <-> palette-indexed PNGs, ROUND TRIP.

QUESTION ANSWERED: can the KN5000's icon sheet be PNGs in the repo and still rebuild the ROM
byte for byte?

The icons were 177 offset/length slices of `includes/icon_pixel_data.bin`, 288 bytes each.
The format is 24x24 at 4 BITS PER PIXEL: 12 bytes per row, high nibble first (matching
scripts/analysis/extract_icons.py, which drew them one way only).

PNGs are written in PIL mode 'P' with a 16-entry palette, so a pixel's value IS the ROM's
nibble. `verify` asserts export-then-build is a no-op at the byte level, which is the property
that lets the PNG be the build's source instead of a picture of the blob.

    python3 scripts/build/icon_images.py export   # blob -> 177 PNGs (run once)
    python3 scripts/build/icon_images.py build    # PNGs -> bins (build step)
    python3 scripts/build/icon_images.py verify   # assert the round trip is exact
"""
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
BLOB = REPO / 'table_data' / 'includes' / 'icon_pixel_data.bin'
IMG = REPO / 'table_data' / 'images' / 'icons_png'
GEN = REPO / 'table_data' / 'includes' / 'generated'
W = H = 24
STRIDE = 12          # bytes per row: 24 pixels at 4bpp
SIZE = STRIDE * H    # 288

# A readable 16-colour ramp. It only affects how the PNG LOOKS; the stored value is the
# ROM nibble either way, so the round trip does not depend on it.
PALETTE = bytes(sum(([v, v, v] for v in range(0, 256, 17)), []))


def count():
    return BLOB.stat().st_size // SIZE


def unpack(data):
    out = bytearray()
    for y in range(H):
        row = data[y * STRIDE:(y + 1) * STRIDE]
        for b in row:
            out.append((b >> 4) & 0x0F)   # high nibble is the first pixel
            out.append(b & 0x0F)
    return bytes(out)


def pack(px):
    out = bytearray()
    for y in range(H):
        row = px[y * W:(y + 1) * W]
        for i in range(0, W, 2):
            out.append(((row[i] & 0x0F) << 4) | (row[i + 1] & 0x0F))
    return bytes(out)


def export():
    IMG.mkdir(parents=True, exist_ok=True)
    blob = BLOB.read_bytes()
    for i in range(count()):
        img = Image.new('P', (W, H))
        img.frombytes(unpack(blob[i * SIZE:(i + 1) * SIZE]))
        img.putpalette(PALETTE)
        img.save(IMG / f'IconPixels_{i:03d}.png')
    print(f"exported {count()} icons to {IMG.relative_to(REPO)}")


def rebuild(i):
    img = Image.open(IMG / f'IconPixels_{i:03d}.png')
    assert img.mode == 'P', f'icon {i}: must be palette-indexed'
    assert img.size == (W, H), f'icon {i}: expected {(W, H)}, got {img.size}'
    return pack(img.tobytes())


def build():
    GEN.mkdir(parents=True, exist_ok=True)
    tot = 0
    for i in range(count()):
        d = rebuild(i)
        assert len(d) == SIZE
        (GEN / f'IconPixels_{i:03d}.bin').write_bytes(d)
        tot += len(d)
    print(f"icon_images: rebuilt {count()} icons, {tot:,} B from PNGs")


def verify():
    blob = BLOB.read_bytes()
    bad = [i for i in range(count()) if rebuild(i) != blob[i * SIZE:(i + 1) * SIZE]]
    if bad:
        sys.exit(f"{len(bad)} of {count()} icons do not round-trip: {bad[:8]}")
    print(f"ROUND TRIP EXACT: all {count()} icons rebuild their ROM bytes ({count() * SIZE:,} B)")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
