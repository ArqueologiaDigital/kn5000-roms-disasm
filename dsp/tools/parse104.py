#!/usr/bin/env python3
"""Parse the §104 PER-SLOT QUIET/LOUD SPLIT table out of an archived upd6383 log.

Row format (after the "[:dsp1] upd6383:" prefix):
   iw word dp nq/nl  accQlo..accQhi accLlo..accLhi M | memQlo..memQhi memLlo..memLhi M | Llo..Lhi Llo..Lhi M
where M is '*' (quiet range != loud range) or '=' (identical).
"""
import re, sys, gzip

ROW = re.compile(
    r'^\s*(\d+)\s+([0-9A-F]{10})\s+([0-9A-F]{2})\s+(\d+)/(\d+)\s+'
    r'(-?\d+)\.\.(-?\d+)\s+(-?\d+)\.\.(-?\d+)\s+([*=])\s*\|\s*'
    r'(-?\d+)\.\.(-?\d+)\s+(-?\d+)\.\.(-?\d+)\s+([*=])\s*\|\s*'
    r'(-?\d+)\.\.(-?\d+)\s+(-?\d+)\.\.(-?\d+)\s+([*=])\s*$')

PREFIX = re.compile(r'^\[:dsp\d\]\s+upd6383:\s?')

def parse(path):
    op = gzip.open if path.endswith('.gz') else open
    rows = {}
    intable = False
    with op(path, 'rt', errors='replace') as f:
        for line in f:
            if '§104 PER-SLOT QUIET/LOUD SPLIT' in line:
                intable = True
                continue
            if intable and ('§104 SUMMARY' in line or '§104 A/B' in line):
                intable = False
                continue
            if not intable:
                continue
            body = PREFIX.sub('', line.rstrip('\n'))
            m = ROW.match(body)
            if m:
                g = m.groups()
                iw = int(g[0])
                rows[iw] = dict(
                    iw=iw, word=g[1], dp=g[2], nq=int(g[3]), nl=int(g[4]),
                    acc=(int(g[5]), int(g[6]), int(g[7]), int(g[8])), accM=g[9],
                    mem=(int(g[10]), int(g[11]), int(g[12]), int(g[13])), memM=g[14],
                    L=(int(g[15]), int(g[16]), int(g[17]), int(g[18])), LM=g[19])
    return rows

# Program-word regions, from upd6383.cpp:630-632 (the device's own labels):
#   kernel A  iw   0.. 49     kernel B  iw  50.. 59     epilogue  iw  60.. 82
#   body 0    iw  84..199     body 1    iw 200..332
RANGES = {'kernelA': (0, 49), 'kernelB': (50, 59), 'epilogue': (60, 82),
          'body0': (84, 199), 'body1': (200, 332)}

def tally(rows, lo, hi):
    a = m = l = 0
    for iw, r in rows.items():
        if lo <= iw <= hi:
            a += r['accM'] == '*'
            m += r['memM'] == '*'
            l += r['LM'] == '*'
    return a, m, l

if __name__ == '__main__':
    for path in sys.argv[1:]:
        rows = parse(path)
        out = []
        for name, (lo, hi) in RANGES.items():
            out.append('%s %d/%d/%d' % (name, *tally(rows, lo, hi)))
        print('%-32s rows=%3d  %s' % (path.split('/')[-1], len(rows), ' | '.join(out)))
