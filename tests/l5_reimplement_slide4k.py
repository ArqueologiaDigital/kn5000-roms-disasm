#!/usr/bin/env python3
"""L5 test: implement SLIDE4K from demo_presets/README.md ALONE and decompress the 19 songs.

Every rule below is quoted from that document. Shares no code with scripts/build/. If the
document is wrong or incomplete about the codec, this fails.

    python3 tests/l5_reimplement_slide4k.py
"""
import glob
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent


def slide4k(blob, size):
    """blob is the LZSS PAYLOAD; size is the declared uncompressed length.

    ⚠ The document's "Block format" (8-byte magic, 3-byte size, then payload) describes the
    ROM BLOCK. The committed *_compressed.bin files are the PAYLOAD ONLY -- the .asciz
    "SLIDE4K" and the size are emitted by table_data/kn5000_table_data.s, not stored in the
    file. An implementer following the document alone asserts on the missing magic, which is
    how this test found the gap.
    """
    src = 0
    # "4 KB ring buffer prefilled with zeros, initial write position 0xFEE"
    ring = bytearray(4096)
    r = 0xFEE
    out = bytearray()
    flags = 0
    while len(out) < size and src < len(blob):
        flags >>= 1
        if not (flags & 0x100):
            if src >= len(blob):
                break
            # "flag byte LSB-first (1 = literal, 0 = match)"
            flags = blob[src] | 0xFF00
            src += 1
        if flags & 1:
            c = blob[src]; src += 1
            out.append(c); ring[r] = c; r = (r + 1) & 0xFFF
        else:
            if src + 1 >= len(blob):
                break
            # "match = 12-bit offset + 4-bit length nibble"
            b1, b2 = blob[src], blob[src + 1]; src += 2
            off = b1 | ((b2 & 0xF0) << 4)
            # "the copy length is nibble + 2 + 1 (3..18 bytes)"
            ln = (b2 & 0x0F) + 2 + 1
            for k in range(ln):
                c = ring[(off + k) & 0xFFF]
                out.append(c); ring[r] = c; r = (r + 1) & 0xFFF
    return bytes(out[:size])


ok = bad = 0
for cz in sorted(glob.glob(str(REPO / 'table_data/includes/demo_presets/*_compressed.bin'))):
    plain = cz.replace('_compressed.bin', '.bin')
    if not pathlib.Path(plain).exists():
        continue
    want = pathlib.Path(plain).read_bytes()
    got = slide4k(pathlib.Path(cz).read_bytes(), len(want))
    if got == want:
        ok += 1
    else:
        bad += 1
        n = sum(1 for a, b in zip(got, want) if a != b) if len(got) == len(want) else -1
        print(f"  *** {pathlib.Path(cz).name}: {len(got)} vs {len(want)} B, "
              f"{n} differing" if n >= 0 else f"  *** {pathlib.Path(cz).name}: length {len(got)} vs {len(want)}")
print(f"SLIDE4K from the document alone: {ok} exact, {bad} wrong")
sys.exit(1 if bad else 0)
