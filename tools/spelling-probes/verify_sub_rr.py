#!/usr/bin/env python3
"""Verify the llvm-mc spelling for the unidasm form  `sub r,r`  (SUB between two
registers), example `sub C,QIZH`.

Question answered: for EVERY address in the KN5000 ROM set where unidasm prints
`sub <REG>,<REG>` (both operands bare register names), does the proposed
spelling assemble to EXACTLY the bytes the ROM has there?

Signal read: the raw ROM bytes at each such address, taken from the ROM FILE
(not from the listing text).  PASS = llvm-mc `--show-encoding` output equals
those bytes, byte for byte and length for length.  "llvm-mc accepted it" is NOT
a pass -- the 2-byte and 3-byte encodings share the same printed text.

Run:  python3 verify_sub_rr.py
"""
import os, re, subprocess, collections, json, sys

REPO    = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
LLVMMC  = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

# (path relative to original_ROMs, load base)
ROMS = [
    ('kn5000_v7_program.rom',      0xE00000),
    ('kn5000_v9_program.rom',      0xE00000),
    ('kn5000_v10_program.rom',     0xE00000),
    ('kn5000_table_data.rom',      0x400000),
    ('kn5000_subcpu_boot.ic30',    0x000000),
    ('kn5000_subprogram_v142.rom', 0x000000),
    ('kn5000_custom_data.ic19',    0x000000),
    ('hd-ae5000_v2_06i.ic4',       0x000000),
]

R8  = ['w','a','b','c','d','e','h','l']
R16 = ['wa','bc','de','hl','ix','iy','iz','sp']
R32 = ['xwa','xbc','xde','xhl','xix','xiy','xiz','xsp']

LINE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+sub ([A-Za-z][A-Za-z0-9-]*),([A-Za-z][A-Za-z0-9-]*)$')

def spell(b):
    """b = the instruction's ROM bytes. Returns (spelling, family) or (None, why)."""
    if len(b) == 2 and 0xA0 <= b[1] <= 0xA7:
        d = b[1] & 7
        if 0xC8 <= b[0] <= 0xCF: return f'sub {R8[d]}, {R8[b[0]&7]}',  'rr8'
        if 0xD8 <= b[0] <= 0xDF:
            if (b[0] & 7) == 7:  return None, 'rr16-SP-source(GR16 excludes SP)'
            return f'sub {R16[d]}, {R16[b[0]&7]}', 'rr16'
        if 0xE8 <= b[0] <= 0xEF: return f'sub {R32[d]}, {R32[b[0]&7]}', 'rr32'
    if len(b) == 3 and 0xA0 <= b[2] <= 0xA7:
        d = b[2] & 7
        if b[0] == 0xC7: return f'subb_erp {R8[d]}, {b[1]}',  'erpb'
        if b[0] == 0xD7: return f'subw_erp {R16[d]}, {b[1]}', 'erpw'
        if b[0] == 0xE7: return f'subl_erp {R32[d]}, {b[1]}', 'erpl'
    return None, 'unclassified'

_cache = {}
def encode(text):
    if text in _cache: return _cache[text]
    p = subprocess.run([LLVMMC, '-triple=tlcs900', '--show-encoding'],
                       input=text, capture_output=True, text=True)
    m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
    _cache[text] = bytes(int(x, 16) for x in m.group(1).split(',')) if m else None
    return _cache[text]

fam   = collections.Counter()
stats = collections.Counter()
bad   = []
examples = {}
total = 0

for name, base in ROMS:
    path = os.path.join(REPO, 'original_ROMs', name)
    if not os.path.exists(path):
        print(f'!! missing {path}'); continue
    rom = open(path, 'rb').read()
    dis = subprocess.run([UNIDASM, path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m: continue
        addr = int(m.group(1), 16)
        by   = bytes(int(x, 16) for x in m.group(2).split())
        off  = addr - base
        real = rom[off:off+len(by)]
        assert real == by, (name, hex(addr), real.hex(), by.hex())
        total += 1
        text, family = spell(real)
        fam[family] += 1
        if text is None:
            stats['NO_SPELLING ' + family] += 1
            bad.append((name, addr, m.group(0).split(None, 2)[-1], real, None, None))
            continue
        enc = encode(text)
        if enc == real:
            stats['OK ' + family] += 1
            key = (family, len(real), real[0] if len(real) == 3 else (real[0] & 0xF8))
            examples.setdefault(key, (name, addr, real, text, line.split('  ')[-1].strip()))
        else:
            stats['MISMATCH ' + family] += 1
            bad.append((name, addr, line, real, text, enc))

print(f'total `sub REG,REG` sites across {len(ROMS)} ROMs: {total}')
print('\nby encoding family:')
for k, v in fam.most_common(): print(f'  {v:6d}  {k}')
print('\nresult:')
for k, v in sorted(stats.items()): print(f'  {v:6d}  {k}')
print(f'\nfailures: {len(bad)}')
seen = set()
for name, addr, line, real, text, enc in bad:
    k = (name, real.hex())
    if k in seen: continue
    seen.add(k)
    print(f'  {name} {addr:06x} rom={real.hex(" ")} spelling={text!r} '
          f'enc={enc.hex(" ") if enc else None}')

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sub_rr_unspellable.json')
json.dump([{'rom': n, 'addr': a, 'bytes': r.hex()} for n, a, _l, r, _t, _e in bad],
          open(OUT, 'w'), indent=1)
print(f'\nwrote {len(bad)} unspellable sites to {OUT}')

print('\n--- one verified example per encoding family ---')
for key in sorted(examples):
    name, addr, real, text, txt = examples[key]
    print(f'{name} {addr:06x}  unidasm {txt!r}  ->  {text!r}  '
          f'enc={encode(text).hex(" ")}  rom={real.hex(" ")}  match=True')
