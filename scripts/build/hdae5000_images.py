#!/usr/bin/env python3
"""hdae5000_images.py -- HD-AE5000 graphics <-> human-readable form, ROUND TRIP.

QUESTION ANSWERED: can the HD-AE5000's 313,076 bytes of graphics live in the repo as images
and palettes a human can look at, and still rebuild the ROM byte for byte?

Yes. That is the whole point: an extractor that only goes one way leaves the blob as the build
input, so the readable form is a view rather than a source. This goes both ways, and `export`
followed by `build` is required to be a no-op at the byte level (`verify` checks it).

WHAT IS IN THERE (offsets into hdae5000/includes/code_29af2d_2fffff.bin):

    off 54881    1024 B   palette, 256 x RGBX          -> HDAE5000_Palette_Logo.txt
    off 55905   76800 B   320x240 8bpp  Logo           -> HDAE5000_Logo.png
    off 132705   1024 B   palette                      -> HDAE5000_Palette_Hands.txt
    off 133729  76800 B   320x240 8bpp  Hands          -> HDAE5000_Hands.png
    off 210529   1024 B   palette                      -> HDAE5000_Palette_FilePanel.txt
    off 211553  76800 B   320x240 8bpp  FilePanel      -> HDAE5000_FilePanel.png
    off 288353   1024 B   palette                      -> HDAE5000_Palette_Icon.txt
    off 289377     756 B  27x27 8bpp, 28-byte stride   -> HDAE5000_Icon.png
    off 306849   1024 B   palette                      -> HDAE5000_Palette_Splash.txt
    off 307873  76800 B   320x240 8bpp  SplashScreen   -> HDAE5000_SplashScreen.png

THE PNGS STORE PALETTE INDICES, NOT COLOURS. They are written in PIL mode 'P', so a pixel's
byte value IS the ROM's byte value. Storing RGB instead would not round-trip: these palettes
contain duplicate colours, so RGB -> index is ambiguous.

THE ICON'S STRIDE IS LOAD-BEARING. It is 27 pixels wide in a 28-byte row. The 28th byte of
each row is padding and is preserved separately in the sidecar, because it is not always 0
and the ROM must come back exactly.

    python3 scripts/build/hdae5000_images.py export    # blob -> png + txt (run once)
    python3 scripts/build/hdae5000_images.py build     # png + txt -> raw bins (build step)
    python3 scripts/build/hdae5000_images.py verify    # assert the round trip is byte-exact
"""
import json
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
BLOB = REPO / 'hdae5000' / 'includes' / 'code_29af2d_2fffff.bin'
ART = REPO / 'hdae5000' / 'images'
GEN = REPO / 'hdae5000' / 'includes' / 'generated'

# name, offset, length, (width, height, stride) or None for a palette
ASSETS = [
    ('HDAE5000_Palette_Logo',      54881,  1024, None),
    ('HDAE5000_Logo',              55905, 76800, (320, 240, 320)),
    ('HDAE5000_Palette_Hands',    132705,  1024, None),
    ('HDAE5000_Hands',            133729, 76800, (320, 240, 320)),
    ('HDAE5000_Palette_FilePanel', 210529, 1024, None),
    ('HDAE5000_FilePanel',        211553, 76800, (320, 240, 320)),
    ('HDAE5000_Palette_Icon',     288353,  1024, None),
    ('HDAE5000_Icon',             289377,   756, (27, 27, 28)),
    ('HDAE5000_Palette_Splash',   306849,  1024, None),
    ('HDAE5000_SplashScreen',     307873, 76800, (320, 240, 320)),
]
PAL_FOR = {
    'HDAE5000_Logo': 'HDAE5000_Palette_Logo',
    'HDAE5000_Hands': 'HDAE5000_Palette_Hands',
    'HDAE5000_FilePanel': 'HDAE5000_Palette_FilePanel',
    'HDAE5000_Icon': 'HDAE5000_Palette_Icon',
    'HDAE5000_SplashScreen': 'HDAE5000_Palette_Splash',
}


def read_palette_txt(path):
    vals = []
    for line in path.read_text().splitlines():
        line = line.split('#', 1)[0].strip()
        if line:
            vals.append(bytes(int(x, 0) for x in line.split()))
    return b''.join(vals)


def write_palette_txt(path, data, name):
    out = [f"# {name} -- 256 entries, 4 bytes each, as stored in the ROM.",
           "# Columns are the raw bytes; on this board the first three are R, G, B and the",
           "# fourth is unused padding. Values are decimal. Editing a line changes the ROM.",
           "#  R    G    B    X"]
    for i in range(0, len(data), 4):
        r, g, b, x = data[i:i + 4]
        out.append(f"{r:4d} {g:4d} {b:4d} {x:4d}   # index {i // 4}")
    path.write_text('\n'.join(out) + '\n')


def export():
    blob = BLOB.read_bytes()
    ART.mkdir(parents=True, exist_ok=True)
    pads = {}
    for name, off, ln, geom in ASSETS:
        data = blob[off:off + ln]
        assert len(data) == ln, name
        if geom is None:
            write_palette_txt(ART / f'{name}.txt', data, name)
            continue
        w, h, stride = geom
        pal = blob[dict((n, o) for n, o, _, _ in ASSETS)[PAL_FOR[name]]:][:1024]
        img = Image.new('P', (w, h))
        flat = bytearray()
        pad = []
        for y in range(h):
            row = data[y * stride:(y + 1) * stride]
            flat += row[:w]
            if stride > w:
                pad.append(list(row[w:]))
        img.frombytes(bytes(flat))
        img.putpalette(b''.join(pal[i:i + 3] for i in range(0, 1024, 4)))
        img.save(ART / f'{name}.png')
        if pad:
            pads[name] = pad
    (ART / 'row_padding.json').write_text(json.dumps(pads, separators=(',', ':')))
    print(f"exported {len(ASSETS)} assets to {ART.relative_to(REPO)}")


def rebuild_one(name, geom):
    if geom is None:
        return read_palette_txt(ART / f'{name}.txt')
    w, h, stride = geom
    img = Image.open(ART / f'{name}.png')
    assert img.mode == 'P', f"{name}: PNG must be palette-indexed, got {img.mode}"
    assert img.size == (w, h), f"{name}: expected {(w, h)}, got {img.size}"
    px = img.tobytes()
    pads = json.loads((ART / 'row_padding.json').read_text()).get(name)
    out = bytearray()
    for y in range(h):
        out += px[y * w:(y + 1) * w]
        if stride > w:
            out += bytes(pads[y])
    return bytes(out)


def build():
    GEN.mkdir(parents=True, exist_ok=True)
    tot = 0
    for name, off, ln, geom in ASSETS:
        data = rebuild_one(name, geom)
        assert len(data) == ln, f"{name}: rebuilt {len(data)} B, expected {ln}"
        (GEN / f'{name}.bin').write_bytes(data)
        tot += len(data)
    print(f"hdae5000_images: rebuilt {len(ASSETS)} assets, {tot:,} B from images and palettes")


def verify():
    blob = BLOB.read_bytes()
    bad = 0
    for name, off, ln, geom in ASSETS:
        want = blob[off:off + ln]
        got = rebuild_one(name, geom)
        if got != want:
            bad += 1
            n = sum(1 for a, b in zip(got, want) if a != b) if len(got) == len(want) else -1
            print(f"  *** {name}: MISMATCH ({n} bytes)" if n >= 0 else f"  *** {name}: LENGTH {len(got)} vs {ln}")
        else:
            print(f"  ok  {name:<28} {ln:>7,} B")
    if bad:
        sys.exit(f"{bad} asset(s) do not round-trip")
    print("ROUND TRIP EXACT: images and palettes rebuild the ROM bytes")


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'verify'
    {'export': export, 'build': build, 'verify': verify}[cmd]()
