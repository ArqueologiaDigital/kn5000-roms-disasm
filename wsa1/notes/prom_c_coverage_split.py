#!/usr/bin/env python3
"""How much of prom_c's "converted" figure is `.fill` padding?

QUESTION IT ANSWERS
  `scripts/analysis/source_coverage.py` counts a `.fill` directive as converted bytes, and
  says so nowhere.  For prom_c that is not a rounding detail: one directive covering the
  0x0E ("ret") padding run at the top of the ROM is worth more than twenty percentage points.
  A reader who quotes "prom_c 28%" without that split is quoting mostly padding.

  This re-runs the same accounting for prom_c and prints it three ways: total converted,
  `.fill` bytes, and the remainder -- the bytes that are actually instructions and data
  someone had to read.

  ⚠ It does NOT say the `.fill` is wrong.  A 118,298-byte run of one repeated byte is honestly
  converted and re-checked over every byte by `notes/prom_c_dup_image.py --fill`.  The point is
  only that it must not be counted as understanding.

  ⚠ prom_c only.  scripts/analysis/ belongs to another lane; fixing the shared tool -- adding a
  `.fill` column to its table -- is left to whoever integrates.  The same defect inflates
  prom_a and prom_b.

RUN
  python3 notes/prom_c_coverage_split.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# ⚠ prom_c is 26 files now (notes/prom_c_split.py): the master alone is 2% of
# the image, and this scan passed VACUOUSLY over it until this line changed.
# notes/probe_health.py is the check; notes/asm_source.py is the reader,
# and it absorbed the prom_c-only shim that used to stand here.
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
SIZE = 524288

INCBIN = re.compile(r'^\s*\.incbin\s+"[^"]+"\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)')
FILL = re.compile(r'^\s*\.fill\s+(0x[0-9A-Fa-f]+|\d+)\s*,\s*(0x[0-9A-Fa-f]+|\d+)\s*,')


def main():
    incbin = 0
    fill = 0
    nfill = 0
    for ln in open(SRC, encoding="utf-8"):
        m = INCBIN.match(ln)
        if m:
            incbin += int(m.group(2), 0)
            continue
        m = FILL.match(ln)
        if m:
            fill += int(m.group(1), 0) * int(m.group(2), 0)
            nfill += 1
    converted = SIZE - incbin
    real = converted - fill
    print("prom_c/wsa1_prom_c.s -- coverage, with the `.fill` split out")
    print("  image size                 %9s" % f"{SIZE:,}")
    print("  still .incbin              %9s   (%.1f%%)" % (f"{incbin:,}", 100.0 * incbin / SIZE))
    print("  'converted' as the shared tool counts it")
    print("                             %9s   (%.1f%%)" % (f"{converted:,}", 100.0 * converted / SIZE))
    print("    of which .fill padding   %9s   (%.1f%%)   in %d directive(s)"
          % (f"{fill:,}", 100.0 * fill / SIZE, nfill))
    print("    REAL code and data       %9s   (%.1f%%)" % (f"{real:,}", 100.0 * real / SIZE))
    if converted != incbin + 0 and incbin + converted != SIZE:
        print("  FAIL: incbin + converted != image size")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
