#!/usr/bin/env python3
"""§225 T1 -- the full blast-radius sweep over every archived tally."""
import sys
from parse104 import parse, RANGES
from rule21 import classify, COLS

def split(rows, lo, hi, col):
    n = i = f = u = 0
    ff = []; uu = []
    for iw in sorted(rows):
        if not (lo <= iw <= hi) or rows[iw][col+'M'] != '*':
            continue
        n += 1
        k, _ = classify(*rows[iw][col])
        if k == 'I': i += 1
        elif k in ('F', 'X-ramp'): f += 1; ff.append(iw)
        else: u += 1; uu.append(iw)
    return n, i, f, u, ff, uu

LOGS = sys.argv[1:]
print('%-30s %-9s %-26s %-26s %-26s' % ('log', 'region', 'acc  n = I + FREE + UND', 'mem  n = I + FREE + UND', 'L    n = I + FREE + UND'))
for path in LOGS:
    rows = parse(path)
    for name, (lo, hi) in RANGES.items():
        cells = []
        any_ = False
        for col in COLS:
            n, i, f, u, ff, uu = split(rows, lo, hi, col)
            if n: any_ = True
            cells.append('%3d = %3d + %3d + %3d' % (n, i, f, u))
        if any_:
            print('%-30s %-9s %s' % (path.split('/')[-1], name, '   '.join(cells)))
    print()
