#!/usr/bin/env python3
"""Are there IMAGES hiding among the blobs triaged as OPAQUE?

QUESTION ANSWERED
-----------------
`l3_slice_structure_triage.py` classes 688 blobs / 2,865,798 B as OPAQUE, meaning
"earns 'no better format' on this evidence". That verdict rests on byte-level
statistics, and an uncompressed bitmap is not distinguishable from noise by byte
statistics alone -- but it IS distinguishable in TWO DIMENSIONS. Adjacent scan
lines of a real image resemble each other; adjacent slices of opaque data do not.

METHOD: for each blob and each plausible row width W (a divisor of the length,
plus the widths this hardware actually uses), reshape into rows and measure the
mean absolute difference between vertically adjacent bytes, normalised by the
mean absolute difference between randomly paired bytes. An image scores well
below 1.0 at its true width; unstructured data scores ~1.0 at every width.

⚠ THE CONTROL THAT CAN FAIL: every blob is also scored after its bytes are
SHUFFLED. Shuffling preserves the byte histogram exactly while destroying all
2-D structure, so a detector keying on byte frequency scores the shuffled copy
identically and is thereby exposed. A candidate is reported only if the real
blob scores well AND its shuffled control does not. This is the control the TEXT
class failed -- 99%-printable "text" that turned out to be pixel data.

⚠ WHAT THIS CANNOT DO: it will not see a COMPRESSED image (no 2-D structure
until decoded), nor a bitplanar image whose planes are stored separately, nor
one whose width is not among those tried. A clean result here bounds the search,
it does not close the question. Widths tried are printed for that reason.

Run:  python3 scripts/analysis/l4_find_unrecognised_images.py [--top N]
"""
import argparse, importlib.util, os, pathlib, random, sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
os.chdir(REPO)
# Widths this hardware actually uses, plus common ones. 640x240 is the LCD.
HW_WIDTHS = [320, 640, 256, 128, 160, 192, 224, 288, 384, 512, 64, 96, 48, 32, 16, 8]


def score(b, w):
    """Mean |row-to-row delta| / mean |random-pair delta|. Low = image-like."""
    h = len(b) // w
    if h < 8:
        return None
    rng = random.Random(1234)
    vert = tot = 0
    n = 0
    for y in range(h - 1):
        base, nxt = y * w, (y + 1) * w
        for x in range(0, w, max(1, w // 64)):      # sample columns
            vert += abs(b[base + x] - b[nxt + x]); n += 1
    if not n:
        return None
    rand = 0
    for _ in range(n):
        rand += abs(b[rng.randrange(len(b))] - b[rng.randrange(len(b))])
    if rand == 0:
        return None
    return (vert / n) / (rand / n)


def best(b):
    out = []
    for w in HW_WIDTHS:
        if len(b) % w == 0 and len(b) // w >= 8:
            s = score(b, w)
            if s is not None:
                out.append((s, w))
    return min(out) if out else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=25)
    a = ap.parse_args()

    tri = REPO / "scripts/analysis/l3_slice_structure_triage.py"
    spec = importlib.util.spec_from_file_location("_triage", tri)
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

    cands = []
    n_op = 0
    for f in mod.blobs():
        b = open(f, "rb").read()
        if len(b) < 256:
            continue
        k, _ = mod.classify(b)
        if k != "OPAQUE":
            continue
        n_op += 1
        r = best(b)
        if r is None:
            continue
        s, w = r
        sh = bytearray(b); random.Random(99).shuffle(sh)
        r2 = best(bytes(sh))
        s_ctrl = r2[0] if r2 else 1.0
        if s < 0.75 and s_ctrl > 0.9:          # image-like AND control clean
            cands.append((s, s_ctrl, w, len(b), str(f)))

    print(f"  OPAQUE blobs examined            : {n_op}")
    print(f"  widths tried                     : {sorted(HW_WIDTHS)}")
    print(f"  image-like AND control-clean     : {len(cands)}")
    print()
    if not cands:
        print("  No unrecognised uncompressed image found among the OPAQUE blobs")
        print("  at any width tried. ⚠ Does not cover compressed or bitplanar images.")
        return 0
    print(f"  {'score':>6} {'ctrl':>6} {'width':>6} {'bytes':>9}  file")
    for s, c, w, n, f in sorted(cands)[:a.top]:
        print(f"  {s:6.3f} {c:6.3f} {w:6} {n:9,}  {f}")
    print("\n  score << 1 = rows resemble each other; ctrl ~1 = the shuffled")
    print("  control shows no such structure, so this is not a byte-frequency artefact.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
