#!/usr/bin/env python3
"""Score a `§104 PER-SLOT QUIET/LOUD SPLIT' table by §211's pre-registered rule.

    a slot is INPUT-DEPENDENT  iff  flag == '*'  AND  (l_lo - q_lo) != (l_hi - q_hi)
    a slot is FREE-RUNNING     iff  flag == '*'  AND  the two deltas are EQUAL

A pure translation of BOTH endpoints by the same constant is the signature of a
free-running quantity (the LFO ramp in D-RAM cell 0x07) sampled over two buckets
of unequal length.  It is NOT input dependence, and reading it as such is trap #7
in the handoff.  The rule was committed in `analysis/data/PREDICT_211.md` before
the run it first scored.

Usage:  s104_score.py <log-or-extract> [...]
Reads MAME `error.log' files or a grep-extract of the table; both work.
"""
import re
import sys

PAT = re.compile(
    r'upd6383: +(\d+) ([0-9A-F]{10}) ([0-9A-F]{2}) +(\d+)/(\d+)'
    r' +(-?\d+)\.\.(-?\d+) +(-?\d+)\.\.(-?\d+) +(\S)'
    r' \| +(-?\d+)\.\.(-?\d+) +(-?\d+)\.\.(-?\d+) +(\S)'
    r' \| +(-?\d+)\.\.(-?\d+) +(-?\d+)\.\.(-?\d+) +(\S)')

COLS = (('acc', 5, 9), ('mem', 10, 14), ('L', 15, 19))
REGIONS = (('kernel A', 0, 49), ('kernel B', 50, 59), ('epilogue', 60, 82),
           ('body 0', 84, 199), ('body 1', 200, 383))


def parse(path):
    rows = []
    with open(path, encoding='utf-8', errors='replace') as fh:
        for ln in fh:
            m = PAT.search(ln)
            if m:
                rows.append(m.groups())
    # a MAME log prints the census twice (logerror + stderr); keep the first copy
    seen, out = set(), []
    for g in rows:
        if g[0] in seen:
            continue
        seen.add(g[0])
        out.append(g)
    return out


def classify(g, base):
    q_lo, q_hi, l_lo, l_hi = (int(g[base + i]) for i in range(4))
    return 'INPUT-DEPENDENT' if (l_lo - q_lo) != (l_hi - q_hi) else 'free-running'


def main():
    for path in sys.argv[1:]:
        rows = parse(path)
        print(f'=== {path}: {len(rows)} slots ===')
        for name, base, flag in COLS:
            dep = [(int(g[0]), g[1], classify(g, base)) for g in rows if g[flag] == '*']
            idep = [d for d in dep if d[2] == 'INPUT-DEPENDENT']
            free = [d for d in dep if d[2] != 'INPUT-DEPENDENT']
            print(f'  {name:3}: {len(dep):3} slots flagged * -> '
                  f'{len(idep)} INPUT-DEPENDENT, {len(free)} free-running')
            if idep:
                print(f'       input-dependent slots: {[d[0] for d in idep]}')
                print(f'       LAST input-dependent slot: iw {idep[-1][0]} ({idep[-1][1]})')
            if free:
                print(f'       free-running slots:    {[d[0] for d in free]}')
            for rname, lo, hi in REGIONS:
                n = len([d for d in idep if lo <= d[0] <= hi])
                if n:
                    print(f'         {rname}: {n}')
        print()


if __name__ == '__main__':
    main()
