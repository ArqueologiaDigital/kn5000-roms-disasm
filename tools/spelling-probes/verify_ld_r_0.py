#!/usr/bin/env python3
"""Verify the llvm-mc spelling for the unidasm form  `ld r,N`  (short 3-bit
immediate load), example `ld XHL,0`.

Question answered: does `lds32 <r>, <N>` / `lds <r>, <N>` / `lds8 <r>, <N>`
assemble to EXACTLY the bytes the KN5000 v7 ROM has at every address where
unidasm prints `ld r,N`?

Signal read: the two ROM bytes at each such address.  PASS = llvm-mc's
--show-encoding output equals those bytes.

Run:  python3 verify_ld_r_0.py
"""
import os, re, subprocess, collections

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
ROM  = os.path.join(REPO, 'original_ROMs/kn5000_v7_program.rom')
BASE = 0xE00000
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
LLVMMC  = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

R16 = ['WA','BC','DE','HL','IX','IY','IZ','SP']
R32 = ['XWA','XBC','XDE','XHL','XIX','XIY','XIZ','XSP']
R8  = ['W','A','B','C','D','E','H','L']

rom = open(ROM,'rb').read()

dis = subprocess.run([UNIDASM, ROM, '-arch','tlcs900','-basepc',hex(BASE)],
                     capture_output=True, text=True).stdout

# `<addr>: <bytes...>   ld <REG>,<N>`  -- 2-byte prefix form only
pat = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+ld ([A-Z]+),([0-7])$')

hits = []
for line in dis.split('\n'):
    m = pat.match(line)
    if not m: continue
    addr = int(m.group(1),16)
    by   = bytes(int(x,16) for x in m.group(2).split())
    if len(by) != 2: continue          # skip C7/D7 3-byte ERP-byte variants
    hits.append((addr, by, m.group(3), int(m.group(4))))

def spell(reg, n):
    r = reg.lower()
    if reg in R32: return f'lds32 {r}, {n}'
    if reg in R16: return f'lds {r}, {n}'
    if reg in R8 : return f'lds8 {r}, {n}'
    return None

def encode(text):
    p = subprocess.run([LLVMMC,'-triple=tlcs900','--show-encoding'],
                       input=text, capture_output=True, text=True)
    m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
    if not m: return None
    return bytes(int(x,16) for x in m.group(1).split(','))

cache = {}
stats = collections.Counter()
bad   = []
for addr, by, reg, n in hits:
    # ground truth straight out of the ROM file, not out of the listing text
    real = rom[addr-BASE: addr-BASE+2]
    assert real == by, (hex(addr), real.hex(), by.hex())
    text = spell(reg, n)
    if text is None:
        stats['NO_SPELLING '+reg] += 1; bad.append((addr, reg, n, by, None, None)); continue
    if text not in cache: cache[text] = encode(text)
    enc = cache[text]
    if enc == real: stats['OK '+reg] += 1
    else:
        stats['MISMATCH '+reg] += 1
        bad.append((addr, reg, n, real, text, enc))

print(f'total 2-byte `ld r,N` sites: {len(hits)}')
for k,v in sorted(stats.items()): print(f'  {v:6d}  {k}')
print(f'failures: {len(bad)}')
for addr,reg,n,real,text,enc in bad[:20]:
    print(f'  {addr:06x} ld {reg},{n} rom={real.hex(" ")} spelling={text!r} enc={enc.hex(" ") if enc else None}')

# sample of concrete verified examples
print('\n--- sample verified examples ---')
seen=set()
for addr, by, reg, n in hits:
    if reg in seen: continue
    seen.add(reg)
    t=spell(reg,n); e=cache.get(t)
    print(f'{addr:06x}  unidasm "ld {reg},{n}"  ->  "{t}"  enc={e.hex(" ") if e else None}  rom={rom[addr-BASE:addr-BASE+2].hex(" ")}  match={e==rom[addr-BASE:addr-BASE+2]}')
