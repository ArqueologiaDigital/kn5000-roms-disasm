#!/usr/bin/env python3
"""kn5000_verbatim_list.py -- itemise ONE image's verbatim(DEBT) bytes, per .incbin.

QUESTION ANSWERED: kn5000_source_coverage.py prints a single DEBT total per
image; when that total needs to be tracked down to actual files (to convert,
or to check whether it is a misclassification -- see git log a4ee942e), this
lists every `.incbin` the coverage tool currently classifies as "verbatim",
sorted by size, with the resolved on-disk path it sized.

Reuses kn5000_source_coverage.py's own INC regex, stripped_text and
classify_incbin directly (imported, not re-derived) so this can never drift
from what the headline number actually counts.

Run:
    python3 scripts/analysis/kn5000_verbatim_list.py v10/maincpu
    python3 scripts/analysis/kn5000_verbatim_list.py v9/maincpu

2026-09-02: this is exactly how the v10/v9 "4,928 B verbatim" figure was
found to be 8 files x 616 B, all `.incbin "images/Bitmap_1bit_*.bin"` inside
maincpu/boot/boot_data_tables.s -- misclassified because they resolve via the
assembler's `-I <product>/maincpu` search path, not relative to
boot_data_tables.s's own directory. Fixed in classify_incbin (a4ee942e); this
script is what would have caught it directly and is kept to catch the next
one.
"""
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kn5000_source_coverage as cov


def list_verbatim(root):
    rows = []
    for f in glob.glob(root + "/**/*.s", recursive=True):
        text = cov.stripped_text(f)
        for rel_path, off, ln in cov.INC.findall(text):
            cls, resolved = cov.classify_incbin(root, f, rel_path)
            if cls != "verbatim":
                continue
            if resolved:
                fsz = os.path.getsize(resolved)
                size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            elif ln:
                size = int(ln, 0)
            else:
                size = None
            rows.append((size or 0, f, rel_path, resolved))
    rows.sort(key=lambda r: -r[0])
    return rows


def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <root, e.g. v10/maincpu>", file=sys.stderr)
        return 1
    root = sys.argv[1]
    rows = list_verbatim(root)
    total = 0
    for size, f, rel_path, resolved in rows:
        total += size
        print(f"{size:8,d}  {f}  .incbin \"{rel_path}\"  ->  {resolved}")
    print(f"\nTOTAL verbatim: {total:,} B across {len(rows)} .incbin directive(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
