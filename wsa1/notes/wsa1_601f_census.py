#!/usr/bin/env python3
"""wsa1_601f_census.py -- every 0x601F00-0x601F7D operand in prom_a, grouped by address, form and routine.

QUESTION THIS ANSWERS
  Which routines read and write each byte of the work-DRAM block at 0x601F00-0x601F7D (the NOTE /
  DRUM EDIT state, FINDINGS-prom_a-screen-module.md section 8), and how?  Run it before naming one of
  these addresses; once an address has a name in include/wsa1_ram.inc its numeric operands are gone
  and it drops out of this list (grep the name instead).

USAGE (from the repository's wsa1/ directory)
  python3 notes/wsa1_601f_census.py
"""
import collections
import re

L = open('prom_a/wsa1_prom_a.s', 'rb').read().decode('latin-1').split('\n')
cur = '?'
d = collections.defaultdict(lambda: collections.defaultdict(set))
for l in L:
    m = re.match(r'^([A-Za-z_][\w$]*):', l)
    if m:
        cur = m.group(1)
    c = l.split(';')[0]
    for x in re.findall(r'0x(601f[0-9a-fA-F]{2})\b', c):
        op = re.sub(r'\s+', ' ', c.strip())
        op = re.sub(r'0x601f[0-9a-fA-F]{2}', 'M', op)
        d[int(x, 16)][op].add(cur)
for a in sorted(d):
    print('== %06X' % a)
    for op, rs in sorted(d[a].items()):
        print('   %-40s %s' % (op, ', '.join(sorted(rs))[:200]))
