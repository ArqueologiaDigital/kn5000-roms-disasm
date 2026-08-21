#!/usr/bin/env python3
"""disk_tm_sound_ram.py -- record geometry of the .TM sound-RAM file on KN-series disks.

QUESTION ANSWERED: how is a .TM file laid out, and do the seven sample disks agree?

    +0x000  16 B          ASCII magic "KN1500 SOUND RAM"
    +0x010  40 x 0x121 B  sound records, 16-char ASCII name at +0 of each
    +0x2D38 712 B         tail, not filler, unidentified

Measured: all seven disks carry 40 records with the SAME names, but six of the seven files differ
in content -- so the names are factory defaults over user-edited parameters. Nothing inside a
record beyond the name is identified.

    python3 scripts/analysis/disk_tm_sound_ram.py <dir-with-TM-files>
"""
import glob
import hashlib
import os
import sys

MAGIC = b'KN1500 SOUND RAM'
STRIDE = 0x121


def printable(b):
    return all((32 <= c < 127) or c == 0 for c in b) and any(32 < c < 127 for c in b)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    digests, namesets = set(), set()
    for f in sorted(glob.glob(os.path.join(root, '**', '*.TM'), recursive=True)):
        d = open(f, 'rb').read()
        if d[:16] != MAGIC:
            print(f"{os.path.basename(f)}: magic is {d[:16]!r}, not {MAGIC!r}")
            continue
        names, n = [], 0
        while True:
            o = 16 + n * STRIDE
            if o + 16 > len(d) or not printable(d[o:o + 16]):
                break
            names.append(d[o:o + 16].decode('latin1').rstrip())
            n += 1
        digests.add(hashlib.md5(d).hexdigest())
        namesets.add(tuple(names))
        print(f"{os.path.basename(f):<18} {len(d):6d} B  records {n:2d}  "
              f"tail {len(d) - (16 + n * STRIDE)} B  first {names[:3]}")
    print(f"\ndistinct file contents: {len(digests)}   distinct name lists: {len(namesets)}")
    if len(namesets) == 1 and len(digests) > 1:
        print("Same names, different bytes: factory names over user-edited parameters.")


if __name__ == '__main__':
    main()
