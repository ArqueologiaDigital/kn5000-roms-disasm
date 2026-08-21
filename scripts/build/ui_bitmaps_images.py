#!/usr/bin/env python3
"""ui_bitmaps_images.py -- the 87 UI bitmaps <-> palette-indexed PNGs, ROUND TRIP.

QUESTION ANSWERED: can the KN5000's on-screen bitmaps -- transport buttons, faders, the
Technics wordmark, the note and drum edit grids -- be PNGs in the repo and still rebuild the
ROM byte for byte?

They were 87 offset/length slices of one opaque blob, `includes/wallpaper1_to_icons.bin`, with
their dimensions written only in end-of-line comments. Nobody could see them without running a
one-way script, and nothing checked the comments against the bytes.

EVERY ONE HAS AN INTEGRAL ROW STRIDE. Measured across all 87: length / height is always a whole
number and never less than the width, and the padding is either 0 or 1 byte per row (44 and 43
of them respectively). That is what makes this convertible at all, and it is the same stride
rule that made the HD-AE5000 icon decode one byte wide for months.

The PNGs store palette INDICES, not colours (PIL mode 'P'), so a pixel byte is the ROM byte.
Row padding is preserved in `ui_bitmaps_padding.json` because it is not always zero.

    python3 scripts/build/ui_bitmaps_images.py export   # blob -> 87 PNGs (run once)
    python3 scripts/build/ui_bitmaps_images.py build    # PNGs -> bins (build step)
    python3 scripts/build/ui_bitmaps_images.py verify   # assert round trip is byte-exact
"""
import json
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
IMG = REPO / 'table_data' / 'images' / 'ui_bitmaps'
GEN = REPO / 'table_data' / 'includes' / 'generated'
MANIFEST = REPO / 'table_data' / 'images' / 'ui_bitmaps_manifest.json'
PADS = REPO / 'table_data' / 'images' / 'ui_bitmaps_padding.json'
PALETTE = REPO / 'v10' / 'maincpu' / 'images' / 'Palette_8bit_RGBA.bin'


def manifest():
    return json.loads(MANIFEST.read_text())


def rgb_palette():
    p = PALETTE.read_bytes()
    return b''.join(p[i:i + 3] for i in range(0, 1024, 4))


def export():
    IMG.mkdir(parents=True, exist_ok=True)
    pal = rgb_palette()
    pads = {}
    for e in manifest():
        blob = (REPO / 'table_data' / e['src']).read_bytes()
        data = blob[e['off']:e['off'] + e['len']]
        w, h, st = e['w'], e['h'], e['stride']
        img = Image.new('P', (w, h))
        img.frombytes(b''.join(data[y * st:y * st + w] for y in range(h)))
        img.putpalette(pal)
        img.save(IMG / f"{e['label']}.png")
        if st > w:
            pads[e['label']] = [list(data[y * st + w:(y + 1) * st]) for y in range(h)]
    PADS.write_text(json.dumps(pads, separators=(',', ':')))
    print(f"exported {len(manifest())} bitmaps to {IMG.relative_to(REPO)}")


def rebuild(e, pads):
    w, h, st = e['w'], e['h'], e['stride']
    img = Image.open(IMG / f"{e['label']}.png")
    assert img.mode == 'P', f"{e['label']}: must be palette-indexed"
    assert img.size == (w, h), f"{e['label']}: expected {(w, h)}, got {img.size}"
    px = img.tobytes()
    if st == w:
        return px
    pad = pads[e['label']]
    return b''.join(px[y * w:(y + 1) * w] + bytes(pad[y]) for y in range(h))


def build():
    GEN.mkdir(parents=True, exist_ok=True)
    pads = json.loads(PADS.read_text())
    tot = 0
    for e in manifest():
        d = rebuild(e, pads)
        assert len(d) == e['len'], e['label']
        (GEN / f"{e['label']}.bin").write_bytes(d)
        tot += len(d)
    print(f"ui_bitmaps_images: rebuilt {len(manifest())} bitmaps, {tot:,} B from PNGs")


def verify():
    pads = json.loads(PADS.read_text())
    bad = 0
    for e in manifest():
        blob = (REPO / 'table_data' / e['src']).read_bytes()
        want = blob[e['off']:e['off'] + e['len']]
        if rebuild(e, pads) != want:
            bad += 1
            print(f"  *** {e['label']}: MISMATCH")
    if bad:
        sys.exit(f"{bad} of {len(manifest())} bitmaps do not round-trip")
    print(f"ROUND TRIP EXACT: all {len(manifest())} bitmaps rebuild their ROM bytes")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
