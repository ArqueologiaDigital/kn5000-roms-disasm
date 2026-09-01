#!/usr/bin/env python3
"""table_data_debt.py -- how many bytes of table_data are still .incbin (real debt),
broken out by legitimacy class, at the moment this script runs.

QUESTION ANSWERED: lane TABLE's brief (notes/lanes/BRIEF-2026-09-01.md) defines debt as
"any byte not reproduced by real source": .incbin of a committed blob, or untyped
.byte/.word runs standing in for undecoded code/data. This script measures the FIRST half
(every .incbin an assembly file in table_data/ actually pulls in) against the current tree,
rather than trusting docs/COMPLETENESS-STATUS.md's 2026-08-21 snapshot or the coarser
audit_incbin_legitimacy.py (which also sweeps wsa1/ and inflates the "generated/" bucket).

Legitimacy classes (same spirit as scripts/analysis/audit_incbin_legitimacy.py, scoped to
table_data/ only, and reporting BYTES not directive counts):

    round-trip-png     rebuilt from a committed PNG/manifest by scripts/build/*_images.py;
                       `make ...-images` regenerates the .bin, verify asserts the round trip
    round-trip-codec   demo-song / help-db compressed stream; codec has a committed
                       decoder AND encoder (LZSS / SLIDE8K) and rebuilds byte-exactly
    verbatim-bmp       genuine Windows BMP, stored verbatim by the firmware, checked into git
    stale-remnant      documented dead/superseded slice preserved byte-exact on purpose
    UNCLASSIFIED       anything not matching the above -- this is the number that matters

Run:
    python3 scripts/analysis/table_data_debt.py
"""
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
TABLE_DIR = REPO / "table_data"

INCBIN = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*,\s*([0-9a-fA-Fx]+))?')
COMMENT = re.compile(r'^\s*;')

RULES = [
    (('FTBMP',), 'verbatim-bmp'),
    (('images/',), 'round-trip-png'),
    (('includes/generated/',), 'round-trip-png'),
    (('demo_preset', 'help_db'), 'round-trip-codec'),
    (('icons_to_strings.bin',), 'stale-remnant'),
]


def classify(path):
    for needles, label in RULES:
        if any(n in path for n in needles):
            return label
    return 'UNCLASSIFIED'


def resolve_size(path_str, off, ln):
    if ln is not None:
        return int(ln, 0)
    full = TABLE_DIR / path_str
    if full.exists():
        return full.stat().st_size
    return None  # not built yet -- must be generated to know the size


def main():
    rows = []
    missing = []
    for f in sorted(TABLE_DIR.glob("*.s")):
        text = f.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            if COMMENT.match(line):
                continue
            m = INCBIN.search(line)
            if not m:
                continue
            # strip a leading "; Was: .incbin ..." style comment tail on the SAME line
            code_part = line.split(';', 1)[0]
            if '.incbin' not in code_part:
                continue
            path_str, off, ln = m.groups()
            size = resolve_size(path_str, off, ln)
            label = classify(path_str)
            rows.append((f.name, lineno, path_str, off, ln, size, label))
            if size is None:
                missing.append((f.name, lineno, path_str))

    if missing:
        print("Sizes unknown (file not built) -- run `make tabledata-images` etc. first, or pass "
              "--build:", file=sys.stderr)
        for r in missing:
            print("  ", r, file=sys.stderr)

    totals = {}
    grand = 0
    for _, _, _, _, _, size, label in rows:
        if size is None:
            continue
        totals[label] = totals.get(label, 0) + size
        grand += size

    print(f"{'file':<28}{'line':>6}  {'path':<55}{'bytes':>10}  class")
    for f, lineno, path_str, off, ln, size, label in rows:
        sz = "?" if size is None else str(size)
        print(f"{f:<28}{lineno:>6}  {path_str:<55}{sz:>10}  {label}")

    print()
    print("Totals by class:")
    for label, total in sorted(totals.items(), key=lambda kv: -kv[1]):
        print(f"  {label:<20}{total:>10,} B")
    print(f"  {'GRAND TOTAL':<20}{grand:>10,} B  ({len(rows)} .incbin directives, "
          f"{len(missing)} unresolved)")
    unclassified = totals.get('UNCLASSIFIED', 0)
    print()
    print(f"UNCLASSIFIED (the number that matters -- real conversion debt): {unclassified:,} B")


if __name__ == "__main__":
    main()
