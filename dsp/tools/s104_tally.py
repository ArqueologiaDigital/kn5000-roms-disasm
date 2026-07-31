#!/usr/bin/env python3
"""§223 grading tool -- tally §104's input-dependence stars per program region.

The register quotes body 0 / body 1 / epilogue / kernel A as `acc/mem/L' triples
(e.g. body 0 `28/32/28').  Those numbers are NOT printed by the core; they are
counts of `*' marks (quiet range != loud range) in the §104 PER-SLOT table over
each region's iw range.  This reproduces them so every arm is graded the same way,
and it is validated against the archived §222 arms before it is used on anything new.

Regions follow pw_region() in upd6383.cpp.
"""
import re
import sys

REGIONS = [
    ("kernel A", 0, 49),
    ("body 0", 84, 199),
    ("body 1", 200, 332),
    ("epilogue", 60, 83),
]

ROW = re.compile(
    r"upd6383:\s+(\d+)\s+([0-9A-F]{10})\s+([0-9A-F]{2})\s+(\d+)/(\d+)\s+(.*)$")


def parse(path):
    rows = {}
    intable = False
    for line in open(path, errors="replace"):
        if "§104 PER-SLOT" in line:
            intable = True
            continue
        if intable and ("§104 SUMMARY" in line or "§213 KERNEL-A" in line):
            intable = False
        if not intable:
            continue
        m = ROW.search(line)
        if not m:
            continue
        iw = int(m.group(1))
        tail = m.group(6)
        # three groups separated by '|', each ending in '=' or '*'
        parts = [p.strip() for p in tail.split("|")]
        if len(parts) != 3:
            continue
        stars = tuple(p.endswith("*") for p in parts)   # acc, mem, L
        rows[iw] = stars
    return rows


def tally(rows):
    out = {}
    for name, lo, hi in REGIONS:
        a = m_ = l = 0
        for iw, (sa, sm, sl) in rows.items():
            if lo <= iw <= hi:
                a += sa
                m_ += sm
                l += sl
        out[name] = (a, m_, l)
    return out


if __name__ == "__main__":
    for path in sys.argv[1:]:
        rows = parse(path)
        t = tally(rows)
        print(f"{path}  ({len(rows)} slots)")
        for name, _, _ in REGIONS:
            a, m_, l = t[name]
            print(f"    {name:10s} {a}/{m_}/{l}")
