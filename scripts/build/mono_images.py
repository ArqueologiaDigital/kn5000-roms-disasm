#!/usr/bin/env python3
"""mono_images.py -- the eight 1bpp flash-update banners <-> PNGs, ROUND TRIP.

QUESTION ANSWERED: can the messages the KN5000 shows while it reflashes itself -- "Now
Erasing", "Please Wait", "Turn On AGAIN", "Illegal Disk" -- be looked at, and still rebuild
the ROM byte for byte?

Format: 224x22 at 1 bit per pixel, row-major, 28 bytes per row, MSB leftmost. 616 B each.

These are the screens a user sees during a firmware update, including the failure ones, so
having them visible matters more than their size suggests.

    python3 scripts/build/mono_images.py export   # bin -> png (run once)
    python3 scripts/build/mono_images.py build    # png -> bin (build step)
    python3 scripts/build/mono_images.py verify   # assert the round trip is exact
"""
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
DIR = REPO / 'v10' / 'maincpu' / 'images'
W, H = 224, 22
STRIDE = W // 8            # 28 bytes per row
NAMES = ['Bitmap_1bit_Change_FD_2_of_2', 'Bitmap_1bit_Completed',
         'Bitmap_1bit_FD_to_Flash_Memory', 'Bitmap_1bit_Flash_Memory_Update',
         'Bitmap_1bit_Illegal_Disk', 'Bitmap_1bit_Now_Erasing',
         'Bitmap_1bit_Please_Wait', 'Bitmap_1bit_Turn_On_AGAIN']


def export():
    for n in NAMES:
        d = (DIR / f'{n}.bin').read_bytes()
        img = Image.new('1', (W, H), 0)
        px = img.load()
        for y in range(H):
            for x in range(W):
                if d[y * STRIDE + (x >> 3)] & (0x80 >> (x & 7)):
                    px[x, y] = 1
        img.save(DIR / f'{n}.png')
    print(f"exported {len(NAMES)} banners")


def rebuild(n):
    img = Image.open(DIR / f'{n}.png').convert('1')
    assert img.size == (W, H), f'{n}: expected {(W, H)}, got {img.size}'
    px = img.load()
    out = bytearray()
    for y in range(H):
        for c in range(STRIDE):
            b = 0
            for bit in range(8):
                if px[c * 8 + bit, y]:
                    b |= (0x80 >> bit)
            out.append(b)
    return bytes(out)


def build():
    tot = 0
    for n in NAMES:
        d = rebuild(n)
        (DIR / f'{n}.bin').write_bytes(d)
        tot += len(d)
    print(f"mono_images: rebuilt {len(NAMES)} banners, {tot:,} B from PNGs")


def verify():
    bad = 0
    for n in NAMES:
        if rebuild(n) != (DIR / f'{n}.bin').read_bytes():
            bad += 1
            print(f"  *** {n}: MISMATCH")
    if bad:
        sys.exit(f"{bad} banner(s) do not round-trip")
    print(f"ROUND TRIP EXACT: all {len(NAMES)} banners ({len(NAMES) * STRIDE * H:,} B)")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
