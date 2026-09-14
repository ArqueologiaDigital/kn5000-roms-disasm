#!/usr/bin/env python3
"""QUESTION: in what ENCODING CONTEXT do the undecoded `f31` (hi12[3:1]) values 3..7
actually occur, pooled over both products?

Asked while adversarially reviewing a proposed hardware probe that would measure `f31`
in ONE synthesised context (class 2, bit4=0, bit7=0, SRC 0x07, ACT 0x15, word
`hh.2.00.1D5`) and then claim the result for every `f31` 3..7 word in the corpus.
The census says how large the transfer gap is.

SIGNAL READ: for every non-ESCAPE microword (hi12 bit 11 clear) of both disassembly
trees, the tuple (class4, hi12 bit4 = store, hi12 bit7 = store gate, lo12 bit11,
SRC = lo12[10:6]) tabulated for f31 >= 3.

MEASURED 2026-09-14, pooled, 8003 words parsed, 1562 ESCAPE words excluded:
  f31 histogram      0:2305  1:3368  2:533  3:73  4:57  5:66  6:2  7:37
  f31>=3 total       235 occurrences, 59 distinct full words
  dominant shape     class 2, bit4=0, bit7=0, SRC 0x00 -- 106 (lo12 = 0x000 entirely)
  probe's context    class 2, bit4=0, bit7=0, SRC 0x07 -- 9  (3.8 % of the population)
  entangled w/ store 37 carry bit4=1 (18 of them with bit7=1), i.e. they also need the
                     store gate, which instruction-set.md says is FORCED to read f31
=> a probe run only at `hh.2.00.1D5` speaks for 9 of 235 occurrences.

RUN: python3 dsp/tools/f31_context_census.py
"""
import re, glob, collections

WORD = re.compile(r'^\s+w\d+\s+([0-9A-F]{10})\b')
TREES = ['dsp/disasm/*.dsm', 'wsa1/dsp/disasm/*.dsm']


def load(root='.'):
    out = []
    for pat in TREES:
        for path in sorted(glob.glob(f'{root}/{pat}')):
            for line in open(path, errors='ignore'):
                m = WORD.match(line)
                if m:
                    out.append((path.split('/')[-1], m.group(1)))
    return out


def fields(hexword):
    v = int(hexword, 16)
    return (v >> 24) & 0xfff, (v >> 20) & 0xf, (v >> 12) & 0xff, v & 0xfff


def main(root='.'):
    words = load(root)
    hist, ctx, shapes, esc = collections.Counter(), collections.Counter(), collections.Counter(), 0
    for _, h in words:
        hi12, cls, addr8, lo12 = fields(h)
        if hi12 & 0x800:          # FORMAT ESCAPE: bits[10:0] mean something else
            esc += 1
            continue
        f31 = (hi12 >> 1) & 7
        hist[f31] += 1
        if f31 >= 3:
            ctx[(cls, (hi12 >> 4) & 1, (hi12 >> 7) & 1, (lo12 >> 11) & 1, (lo12 >> 6) & 0x1f)] += 1
            shapes[h] += 1
    print(f'parsed {len(words)} words, {esc} ESCAPE excluded')
    print('f31 histogram', sorted(hist.items()))
    print(f'f31>=3: {sum(v for k, v in hist.items() if k >= 3)} occurrences, {len(shapes)} distinct words')
    print('\ncontexts (class, store bit4, gate bit7, lo12 bit11, SRC):')
    for (cls, b4, b7, b11, src), n in ctx.most_common():
        print(f'  class={cls:X} bit4={b4} bit7={b7} b11={b11} SRC={src:02X}  n={n}')
    probe = sum(n for (cls, b4, b7, b11, src), n in ctx.items()
                if (cls, b4, b7, b11, src) == (2, 0, 0, 0, 0x07))
    stores = sum(n for (cls, b4, b7, b11, src), n in ctx.items() if b4)
    print(f'\nprobe context (class2,bit4=0,bit7=0,SRC=07): {probe}')
    print(f'f31>=3 words that ALSO carry the store bit4: {stores}')
    print('\ntop distinct words:')
    for h, n in shapes.most_common(12):
        print(f'   {h}  {n}')


if __name__ == '__main__':
    main()
