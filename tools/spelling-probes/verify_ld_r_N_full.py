#!/usr/bin/env python3
"""FULL verification of the llvm-mc spelling rule for the unidasm form `ld r,N`
(3-bit short immediate load; assignment example `ld XHL,0`), KN5000 v7 ROM.

Rule under test (see report):
  2 bytes, prefix 0xC8+i -> lds8  <r8>,  N      r8  = W A B C D E H L
  2 bytes, prefix 0xD8+i -> lds   <r16>, N      r16 = WA BC DE HL IX IY IZ SP
  2 bytes, prefix 0xE8+i -> lds32 <r32>, N      r32 = XWA XBC XDE XHL XIX XIY XIZ XSP
  3 bytes, 0xD7 <rb> 0xA8+N -> ld <qreg>, N     qreg from rb (prev-bank 16-bit)
  3 bytes, 0xC7 <rb> 0xA8+N -> lds_erpb 0x<rb>, N
PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
Run: python3 verify_ld_r_N_full.py
"""
import os,re,subprocess,collections
REPO=os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
ROM=os.path.join(REPO,'original_ROMs/kn5000_v7_program.rom'); BASE=0xE00000
UNI=os.path.expanduser('~/compartilhado/tools/unidasm')
MC=os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
rom=open(ROM,'rb').read()
dis=subprocess.run([UNI,ROM,'-arch','tlcs900','-basepc',hex(BASE)],
                   capture_output=True,text=True).stdout
pat=re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+ld ([A-Z]+),([0-7])$')
R8 =['W','A','B','C','D','E','H','L']
R16=['WA','BC','DE','HL','IX','IY','IZ','SP']
R32=['XWA','XBC','XDE','XHL','XIX','XIY','XIZ','XSP']
def spell(by,reg,n):
    if len(by)==2:
        p=by[0]
        if 0xC8<=p<=0xCF: return f'lds8 {R8[p-0xC8].lower()}, {n}'
        if 0xD8<=p<=0xDF: return f'lds {R16[p-0xD8].lower()}, {n}'
        if 0xE8<=p<=0xEF: return f'lds32 {R32[p-0xE8].lower()}, {n}'
    if len(by)==3:
        if by[0]==0xD7: return f'ld {reg.lower()}, {n}'     # prev-bank 16-bit
        if by[0]==0xC7: return f'lds_erpb 0x{by[1]:02x}, {n}'
    return None
cache={}
def enc(t):
    if t in cache: return cache[t]
    p=subprocess.run([MC,'-triple=tlcs900','--show-encoding'],input=t,
                     capture_output=True,text=True)
    m=re.search(r'encoding: \[([^\]]*)\]',p.stdout)
    cache[t]=bytes(int(x,16) for x in m.group(1).split(',')) if m else None
    return cache[t]
ok=collections.Counter(); bad=[]
sites=0
for line in dis.split('\n'):
    m=pat.match(line)
    if not m: continue
    addr=int(m.group(1),16); by=bytes(int(x,16) for x in m.group(2).split())
    reg=m.group(3); n=int(m.group(4)); sites+=1
    real=rom[addr-BASE:addr-BASE+len(by)]
    assert real==by
    t=spell(by,reg,n)
    e=enc(t) if t else None
    if e==real: ok[f'{len(by)}B {reg}']+=1
    else: bad.append((addr,reg,n,real,t,e))
print(f'{sites} `ld r,N` sites in the whole v7 ROM (linear scan)')
print(f'byte-exact: {sum(ok.values())}   failures: {len(bad)}')
for k,v in sorted(ok.items(),key=lambda x:-x[1]): print(f'   {v:6d}  {k}')
for a,r,n,real,t,e in bad:
    print(f' FAIL {a:06x} "ld {r},{n}" rom={real.hex(" ")} tried={t!r} got={e.hex(" ") if e else "REJECTED"}')
