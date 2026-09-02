#!/usr/bin/env python3
"""Which bytes of a ROM address range are NAMED by a pointer stored somewhere?

QUESTION ANSWERED
  For lane promB3's four prom_b spans: does anything in the four WSA1R program
  images (prom_a/b/c/d) hold a little-endian 3- or 4-byte value equal to an
  address inside the span?  A span whose interior is named by a stored pointer
  is DATA reached by dereference, and the pointer's own record says how wide the
  entries are.  A span nothing points into is not framed by this instrument.

RUN
  python3 notes/lane_promB3/xref_scan.py 0xF0D4D2 0xF0D698
  python3 notes/lane_promB3/xref_scan.py 0xF0D4D2 0xF0D698 --width 3
"""
import os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
IMAGES = {
    "prom_a": ("original_ROMs/wsa1_prom_a.ic12", 0xF80000),
    "prom_b": ("original_ROMs/wsa1_prom_b.ic13", 0xF00000),
    "prom_c": ("original_ROMs/wsa1_prom_c.ic28", 0xF80000),
    "prom_d": ("original_ROMs/wsa1_prom_d.bin",  0xF00000),
}


def main():
    lo = int(sys.argv[1], 0)
    hi = int(sys.argv[2], 0)
    widths = [3, 4]
    if "--width" in sys.argv:
        widths = [int(sys.argv[sys.argv.index("--width") + 1])]
    hits = []
    for name, (path, base) in IMAGES.items():
        b = open(os.path.join(ROOT, path), "rb").read()
        for w in widths:
            for i in range(len(b) - w):
                v = int.from_bytes(b[i:i + w], "little")
                if lo <= v < hi:
                    hits.append((name, base + i, w, v))
    for name, at, w, v in sorted(hits, key=lambda h: (h[3], h[1])):
        print("0x%06X  <- %s:0x%06X (%d-byte LE)" % (v, name, at, w))
    print("%d stored pointers into 0x%06X-0x%06X" % (len(hits), lo, hi - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
