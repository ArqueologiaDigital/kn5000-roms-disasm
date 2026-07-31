#!/usr/bin/env python3
"""§225 T1 detail + the four RULE-20 known-answer controls."""
import sys
from parse104 import parse, RANGES
from rule21 import classify, COLS

def rowdump(rows, iws, cols=COLS, tag=''):
    for iw in iws:
        r = rows.get(iw)
        if not r:
            print('   iw%3d MISSING' % iw); continue
        s = '   iw%3d %s dp%s' % (iw, r['word'], r['dp'])
        for c in cols:
            qlo, qhi, llo, lhi = r[c]
            k, _ = classify(qlo, qhi, llo, lhi) if r[c+'M'] == '*' else ('=', '')
            s += '  %s q[%d..%d] l[%d..%d] %s%s' % (c, qlo, qhi, llo, lhi, r[c+'M'], '' if k == '=' else '/'+k)
        print(s + tag)

def marks(rows, lo, hi, col):
    return {iw for iw in rows if lo <= iw <= hi and rows[iw][col+'M'] == '*'}

def klass(rows, lo, hi, col, want):
    out = []
    for iw in sorted(rows):
        if lo <= iw <= hi and rows[iw][col+'M'] == '*':
            k, _ = classify(*rows[iw][col])
            if k in want: out.append(iw)
    return out

A = parse(sys.argv[1] if len(sys.argv) > 1 else 'logs/A_pickup_222.log')   # shipped, send CLOSED
C = parse(sys.argv[2] if len(sys.argv) > 2 else 'logs/B_pickup_noz05_222.log') # NOZ05, send OPEN
b0 = RANGES['body0']

print('#'*100)
print('# CONTROL 1 (KNOWN ANSWER, §224): cell 0x07 -- THE LFO PHASE -- must classify FREE, never I')
print('#'*100)
# every body-0 row whose mem column reads dp 07
for name, rows in (('arm A shipped', A), ('arm C NOZ05', C)):
    print(' %s:' % name)
    iws = [iw for iw in sorted(rows) if rows[iw]['dp'] == '07' and b0[0] <= iw <= b0[1]]
    rowdump(rows, iws, ('mem',))

print()
print('#'*100)
print('# CONTROL 2 (THE EXPERIMENT\'S OWN DIFFERENTIAL): which body-0 `*` slots are NEW when the')
print('#              send is OPENED?  A free-running ramp is present in BOTH arms.')
print('#'*100)
for col in COLS:
    ma, mc = marks(A, *b0, col), marks(C, *b0, col)
    new  = sorted(mc - ma)
    both = sorted(mc & ma)
    lost = sorted(ma - mc)
    ki = set(klass(C, *b0, col, {'I'}))
    print(' %-4s  armA %2d  armC %2d  |  NEW %2d  SHARED %2d  LOST %2d'
          % (col, len(ma), len(mc), len(new), len(both), len(lost)))
    print('        NEW    = %s' % new)
    print('        SHARED = %s   (present with the send CLOSED)' % both)
    print('        class-I in arm C = %d ; NEW ∩ class-I = %d ; SHARED ∩ class-I = %d'
          % (len(ki), len(set(new) & ki), len(set(both) & ki)))

print()
print('#'*100)
print('# CONTROL 3: the SHARED slots (present in both arms) -- are they exactly the free-running ones?')
print('#'*100)
for col in COLS:
    ma, mc = marks(A, *b0, col), marks(C, *b0, col)
    free = set(klass(C, *b0, col, {'F', 'X-ramp'}))
    print(' %-4s  SHARED=%s  FREE(class F/X-ramp in arm C)=%s   SHARED==FREE ? %s'
          % (col, sorted(ma & mc), sorted(free), (ma & mc) == free))

print()
print('#'*100)
print('# CONTROL 4: arm A body 0 = 2/4/1 -- the "NULL".  Dump every one of the 7 markers.')
print('#'*100)
for col in COLS:
    iws = sorted(marks(A, *b0, col))
    print(' %s:' % col); rowdump(A, iws, (col,))

print()
print('#'*100)
print('# THE ANSWER: body-0 tallies split I / FREE / UNDECIDED')
print('#'*100)
for name, rows in (('arm A (shipped, send CLOSED)', A), ('arm C (NOZ05, send OPEN)', C)):
    t = []
    for col in COLS:
        n = len(marks(rows, *b0, col))
        i = len(klass(rows, *b0, col, {'I'}))
        f = len(klass(rows, *b0, col, {'F', 'X-ramp'}))
        u = len(klass(rows, *b0, col, {'X-sign', 'X-reach'}))
        t.append('%s %d = I%d + FREE%d + UND%d' % (col, n, i, f, u))
    print(' %-32s %s' % (name, ' | '.join(t)))
