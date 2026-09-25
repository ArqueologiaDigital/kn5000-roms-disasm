#!/usr/bin/env python3
r"""naka_class_descriptors.py -- what the 24-byte ClassProc descriptors say, checked over all of them.

QUESTION ANSWERED
-----------------
`RegObjTable 0x1600004, ClassProc, &count, table, id` registers tables of
24-byte class descriptors (ClassProc in ui/ui_widget_defs.s indexes them with
index * 24).  Read as {u32 proc, u32 base_class, u16 a, u16 b, u32 name,
u32 sig, u32 props}, do the two u16 fields and the `sig` string have the
meaning naka_types.h gives them?  This script checks, over every ClassProc
table registered anywhere in the v10 sources:

  1. BASE SIZE: a - b is one constant per base_class (it should be the size
     of the base class's record, the part every derived record starts with);
  2. LETTERS: b equals the sum of per-letter sizes of `sig`, with the letters
     j c X ` = 4 bytes and B C ^ _ A G f = 2 bytes (classes using other
     letters are counted separately, not judged);
  3. NAMES: the props block holds one pointer per letter of `sig`, then a
     pointer to "" -- i.e. one property name per type letter.
  4. CLASS IDS: descriptor k of the table registered with id T is class
     T << 16 | k (0x160 -> 0x16000XX, the core classes; 0x161 -> 0x1610XXX ...);
     every widget record a ViewableProc (0x1600010) table points at should
     then begin with the id of a known class, and consecutive records should
     sit record_size apart.

It prints the counts and every exception; the numbers quoted in naka_types.h
and in the lane report come from this output.

RUN
    make rebuilt_ROMs/kn5000_v10_program.llvm.elf     # for symbol names
    python3 scripts/analysis/naka_class_descriptors.py [--list]
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = open(os.path.join(ROOT, 'original_ROMs/kn5000_v10_program.rom'), 'rb').read()
u32 = lambda a: int.from_bytes(ROM[a - 0xE00000:a - 0xE00000 + 4], 'little')
u16 = lambda a: int.from_bytes(ROM[a - 0xE00000:a - 0xE00000 + 2], 'little')
SIZE = dict({L: 4 for L in 'jcX`'}, **{L: 2 for L in 'BC^_AGf'})


def cstr(a):
    if not 0xE00000 <= a < 0x1000000:
        return None
    return ROM[a - 0xE00000:a - 0xE00000 + 40].split(b'\0')[0].decode('latin-1')


def symbols():
    nm = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-nm')
    out = subprocess.run([nm, '--defined-only', os.path.join(
        ROOT, 'rebuilt_ROMs/kn5000_v10_program.llvm.elf')], capture_output=True, text=True).stdout
    return {f[2]: int(f[0], 16) for f in (l.split() for l in out.splitlines()) if len(f) == 3}


def tables(sym, with_id=False):
    out = []
    for dp, _, fns in os.walk(os.path.join(ROOT, 'v10/maincpu')):
        for fn in sorted(fns):
            if not fn.endswith('.s'):
                continue
            for i, l in enumerate(open(os.path.join(dp, fn), encoding='latin-1')):
                m = re.match(r'\s*RegObjTable\s+0x1600004,\s*(\S+),\s*(\S+),\s*(\S+),\s*(\S+)',
                             l.split(';')[0])
                if m:
                    v = lambda x: int(x, 0) if x.startswith('0x') else sym[x]
                    t = (fn, i + 1, v(m.group(3)), u16(v(m.group(2))))
                    out.append(t + (int(m.group(4), 0),) if with_id else t)
    return out


def main():
    sym = symbols()
    tabs = tables(sym)
    rows = []
    for fn, line, t, c in tabs:
        for k in range(c):
            r = t + 24 * k
            rows.append(dict(tab=t, k=k, name=cstr(u32(r + 12)), sig=cstr(u32(r + 16)) or '',
                             a=u16(r + 8), b=u16(r + 10), base=u32(r + 4), props=u32(r + 20)))
    print('%d ClassProc tables, %d class descriptors' % (len(tabs), len(rows)))
    base = collections.defaultdict(set)
    for x in rows:
        base[x['base']].add(x['a'] - x['b'])
    multi = {hex(k): sorted(v) for k, v in base.items() if len(v) > 1}
    print('1. base classes: %d; a - b constant per base class for all but %d: %s'
          % (len(base), len(multi), multi))
    judged = [x for x in rows if x['sig'] and all(L in SIZE for L in x['sig'])]
    bad = [x for x in judged if sum(SIZE[L] for L in x['sig']) != x['b']]
    print('2. %d descriptors use only the letters %s; b = sum of letter sizes for %d, '
          'exceptions: %s' % (len(judged), ''.join(sorted(SIZE)), len(judged) - len(bad),
                               [(x['name'], x['sig'], x['b']) for x in bad]))
    ok = 0
    exc = []
    for x in rows:
        n = len(x['sig'])
        ptrs = [u32(x['props'] + 4 * i) for i in range(n + 1)]
        if all(cstr(p) for p in ptrs[:n]) and cstr(ptrs[n]) == '':
            ok += 1
        else:
            exc.append(x['name'])
    print('3. props block = one name pointer per sig letter, then "": %d of %d; '
          'exceptions: %s' % (ok, len(rows), exc[:20]))
    # 4. class ids and widget records
    cls = {}
    for fn, line, t, c, tid in tables(sym, True):
        for k in range(c):
            r = t + 24 * k
            cls[tid << 16 | k] = (cstr(u32(r + 12)), u16(r + 8))
    views = []
    for dp, _, fns in os.walk(os.path.join(ROOT, 'v10/maincpu')):
        for fn in sorted(fns):
            if not fn.endswith('.s'):
                continue
            for l in open(os.path.join(dp, fn), encoding='latin-1'):
                m = re.match(r'\s*RegObjTabl\s+0x1600010,\s*\S+,\s*(\S+),\s*(\S+),', l.split(';')[0])
                if m:
                    v = lambda x: int(x, 0) if x.startswith('0x') else sym.get(x)
                    if v(m.group(2)) is not None:
                        views.append((v(m.group(2)), v(m.group(1))))
    recs = sorted(set(u32(t + 4 * k) for t, n in views for k in range(n)))
    known = [a for a in recs if u32(a) in cls]
    print('4. %d ViewableProc tables -> %d distinct widget records; %d begin with a known '
          'class id' % (len(views), len(recs), len(known)))
    gaps = collections.Counter()
    for a, b in zip(recs, recs[1:]):
        if u32(a) in cls:
            gaps['next record at record_size' if b - a == cls[u32(a)][1] else
                 'next record further' if b - a > cls[u32(a)][1] else 'OVERLAP'] += 1
    print('   spacing to the next record (records with a known class): %s' % dict(gaps))
    if '--list' in sys.argv:
        for x in rows:
            print('  %-24s base 0x%07X a=%3d b=%3d sig=%-10s' % (x['name'], x['base'], x['a'],
                                                               x['b'], x['sig']))


if __name__ == '__main__':
    main()
