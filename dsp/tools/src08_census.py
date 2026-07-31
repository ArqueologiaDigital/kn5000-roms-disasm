#!/usr/bin/env python3
"""src08_census.py -- the SRC 0x08 population, and what a store-suppression would cost.

Supports dsp/analysis/data/SRC08_findings.md.  Read-only; reads dsp/disasm/*.dsm, which
is generated from the firmware by gen_dsp_disasm.py.

Why it exists: the standing task "fix the SRC 0x08 clobber that rails PEQ's input cell"
proposes suppressing a bit-4 store on a SRC-0x08 word.  This counts what that would hit.

  ⚠ POPULATION.  Algorithms 79/88/89/90/91 are IC310/MN19413 programs (a DIFFERENT chip)
  and are NOT present in dsp/disasm/, so nothing here is a two-chip statistic.  The tool
  asserts that, so the day those listings appear the assertion fires instead of silently
  contaminating the count.

Field layout (upd6383d.h):  hi12[35:24] . class4[23:20] . addr8[19:12] . lo12[11:0]
    C-format   hi12[11:8] == 0xC   -- no class4/addr8 at all
    lo12 bit 11 -- the alternate encoding: addressing only, no ALU effect (bit11-family.md)
    SRC = lo12[10:6]   ACT = lo12[5:0]   HI_ST = hi12 bit 4   mode = class4 & 7
"""
import collections
import glob
import os
import re
import sys

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'disasm')
WORD_RE = re.compile(r'\s*w(\d+)\s+([0-9A-F]{10})\b')
IC310 = ('prog79', 'prog88', 'prog89', 'prog90', 'prog91')


def words(path):
    for line in open(path):
        m = WORD_RE.match(line)
        if m:
            yield int(m.group(1)), int(m.group(2), 16)


def fields(w):
    hi, cl, a8, lo = (w >> 24) & 0xfff, (w >> 20) & 0xf, (w >> 12) & 0xff, w & 0xfff
    return dict(hi=hi, cl=cl, a8=a8, lo=lo,
                cfmt=(hi & 0xf00) == 0xc00, alt=bool(lo & 0x800),
                src=(lo >> 6) & 0x1f, act=lo & 0x3f,
                st=bool(hi & 0x10), b7=bool(hi & 0x80),
                f31=(hi >> 1) & 7, mode=cl & 7)


def main():
    files = sorted(glob.glob(os.path.join(BASE, '*.dsm')))
    if not files:
        sys.exit('no listings under %s' % BASE)
    contaminated = [os.path.basename(p) for p in files
                    if os.path.basename(p).startswith(IC310)]
    assert not contaminated, ('IC310/MN19413 listings present -- this is a TWO-CHIP '
                             'population, do not quote the totals: %s' % contaminated)

    tot = collections.Counter()
    forms = collections.Counter()
    sites = collections.defaultdict(list)
    for p in files:
        name = os.path.basename(p)
        for iw, w in words(p):
            f = fields(w)
            if f['cfmt'] or f['alt'] or f['src'] != 0x08:
                continue
            tot['SRC 0x08'] += 1
            if not f['st']:
                continue
            tot['  ... carrying the bit-4 store'] += 1
            tot['      ... mode %d' % f['mode']] += 1
            if f['mode'] == 2:
                forms['%03X (f31=%d)' % (f['hi'], f['f31'])] += 1
                sites[name].append((iw, '%010X' % w))

    print('POPULATION: %d listings, IC311 only\n' % len(files))
    for k, v in tot.items():
        print('  %-34s %4d' % (k, v))
    print('\nhi12 forms among the mode-2 bit-4 SRC-0x08 stores'
          '  (092/094 = the LFO phase-accumulate + wrap idiom):')
    for k, v in sorted(forms.items(), key=lambda kv: -kv[1]):
        print('  %-16s %4d' % (k, v))
    lfo = sum(v for k, v in forms.items() if k[:3] in ('092', '094'))
    print('\n  ==> a store-suppression keyed on `src == 0x08 && bit 4\' would delete the LFO '
          'publish\n      at %d of %d sites.' % (lfo, sum(forms.values())))
    print('\nsites, by image:')
    for k in sorted(sites):
        print('  %-34s %s' % (k, sites[k]))

    # The one word the standing task is actually about.
    target = 0x0010A0020C
    hits = [(os.path.basename(p), iw) for p in files for iw, w in words(p) if w == target]
    print('\nkernel iw45 `010.A.00.20C\' (the SEND, K6 finding 7) occurs %d time(s): %s'
          % (len(hits), hits))
    print('  ==> gate any A/B on the WORD, never on `src == 0x08\'.')


if __name__ == '__main__':
    main()
