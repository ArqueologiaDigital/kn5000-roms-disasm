#!/usr/bin/env python3
r"""Which comments did an edit to wsa1/prom_a/wsa1_prom_a.s drop, and are they only
the kinds lane `proma` drops on purpose?

QUESTION THIS ANSWERS
    scripts/analysis/assert_comments_preserved.py reports every comment line that
    is not carried over.  When a `.byte` run is re-framed (split at a new label,
    re-rowed to start on an object boundary) its trailing ADDRESS-ONLY comments
    (`; FF17E2`, `; FF21F2  1e 0b`) necessarily change, and when a header whose
    claim was proven false is corrected its lines change too.  This separates the
    lost lines into ADDRESS-ONLY (regenerated, no information lost) and OTHER, and
    prints every OTHER line so a human can confirm each one is a deliberate,
    commit-message-justified correction.

RUN
    python3 notes/proma-2026-09-25/comment_loss.py [--base REV] [--rename-map FILE]
    exit status 0 always; read the OTHER list.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import assert_comments_preserved as A  # noqa: E402

PATH = "wsa1/prom_a/wsa1_prom_a.s"
ADDR_ONLY = re.compile(r';\s*[0-9A-F]{6}(\s+[0-9a-f]{2}(\s[0-9a-f]{2})*)?\s*$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--rename-map")
    a = ap.parse_args()
    ren = {}
    if a.rename_map:
        for ln in open(a.rename_map):
            if "=" in ln:
                o, n = ln.strip().split("=", 1)
                ren[o] = n
    base = A.git_show(a.base, PATH)
    new = open(os.path.join(ROOT, PATH), encoding="latin-1").read()
    lost, nb, nn = A.check(base, new, ren or None)
    addr = [c for c in lost if ADDR_ONLY.fullmatch(c.strip())]
    other = [c for c in lost if not ADDR_ONLY.fullmatch(c.strip())]
    print("%s: %d comments at %s -> %d now; lost %d = %d address-only + %d OTHER"
          % (PATH, nb, a.base, nn, len(lost), len(addr), len(other)))
    for c in other:
        print("  OTHER: " + c[:140])


if __name__ == "__main__":
    main()
