#!/usr/bin/env python3
"""apply_package.py -- apply one vetted Wave 7 edit list to the working tree.

QUESTION ANSWERED: can this package be applied without silently corrupting a file?

Every edit is {file, anchor, replacement}. Before writing anything, each anchor is counted in its
target file and must appear EXACTLY ONCE. An anchor matching twice would edit an arbitrary one of
the two sites; an anchor matching zero times means the file moved under the package. Both abort the
whole run -- nothing is written unless every edit is safe.

Edits are applied sequentially to an in-memory copy, so overlapping edits are counted against the
progressively-modified text, which is what actually happens on disk.

    python3 apply_package.py pkgN_fixed.json --dry     # check anchors only, write nothing
    python3 apply_package.py pkgN_fixed.json           # apply

AFTER APPLYING, THE BYTE-MATCH GATE IS MANDATORY:

    make clean-all && make all      # must print Similarity: 100.00% for all 9 targets

These are comment-only packages, so anything less than 9/9 at 100.00% means an edit touched code and
the commit must not happen. Read the gate output before committing -- do not assume it passed.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    edits = json.load(open(sys.argv[1]))
    dry = '--dry' in sys.argv
    cache, ok = {}, True
    for i, e in enumerate(edits):
        p = ROOT / e['file']
        if p not in cache:
            cache[p] = p.read_text()
        n = cache[p].count(e['anchor'])
        print(f"edit[{i}] {e['file']}: anchor count = {n}", "OK" if n == 1 else "*** FAIL ***")
        if n != 1:
            ok = False
        else:
            cache[p] = cache[p].replace(e['anchor'], e['replacement'], 1)
    if not ok:
        sys.exit("\nABORTED: an anchor was not unique -- nothing written")
    if dry:
        print("\nDRY RUN -- nothing written")
        return
    for p, text in cache.items():
        p.write_text(text)
        print(f"\nwrote {p.relative_to(ROOT)}")


if __name__ == '__main__':
    main()
