#!/usr/bin/env python3
"""Do the 6 v7 ranges that block on `ldir` convert byte-exactly under the rule?

QUESTION ANSWERED
  blocking_ldir.py shows all 6 blocked ranges stop at bytes [85 11], and that
  `ldir85` encodes to exactly those bytes.  This script closes the loop: it
  re-decodes each of the 6 ranges and spells EVERY instruction in it -- the
  block transfer by the (prefix, sub-opcode) -> mnemonic map, everything else by
  convert_corroborated_blocks.translate()/canonical() -- and requires each
  spelling to assemble to the ROM bytes.  Branches are skipped, as the converter
  resolves those to symbols itself.

  This is what proves the fix is a CONVERTER change, not a backend change: no
  new .td definition is needed for any instruction in any of the 6 ranges.

RUN   python3 tools/spelling-probes/verify_ldir_blocked_ranges.py

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b
  66 instructions across the 6 ranges, 0 failures.
      0xF56D2B 0xF57524 0xF576E1 0xF5789E 0xF57A5B 0xF67077
      all [85 11] -> ldir85 -> [85 11]   OK
  The surrounding code confirms these are real LDIRs, e.g. at 0xF56D1F:
      ld XIY,0x00003178 / ld XIX,0x00003191 / ld BC,5 / ldir85
  i.e. source, destination, count, copy -- the ridx=5 prefix names XIY as the
  source pair, which is why the ROM uses [85 11] and not [80 11].
"""
import importlib.util, json, os, re, subprocess, tempfile, sys
REPO=os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI=os.path.expanduser('~/compartilhado/tools/unidasm')
BASE=0xE00000
BLOCK_XFER={ (0x80,0x10):'ldi',(0x80,0x11):'ldir',(0x80,0x12):'ldd',(0x80,0x13):'lddr',
 (0x83,0x11):'ldir83',(0x83,0x13):'lddr83',(0x83,0x15):'cpir83',
 (0x85,0x10):'ldi85',(0x85,0x11):'ldir85',(0x85,0x13):'lddr85',
 (0x93,0x11):'ldirw93',(0x95,0x10):'ldiw',(0x95,0x11):'ldirw'}
def load(n,r):
    s=importlib.util.spec_from_file_location(n,os.path.join(REPO,r))
    m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
os.chdir(REPO)
cc=load('cc','scripts/converters/convert_corroborated_blocks.py')
rom=open('original_ROMs/kn5000_v7_program.rom','rb').read()
TD=tempfile.mkdtemp(); TMP=os.path.join(TD,'r.bin')
ENTRIES=[0xF56D10,0xF57505,0xF576C2,0xF5787F,0xF57A3C,0xF67055]
BRANCH=('jr','jrl','calr')
bad=0; tot=0
for e in ENTRIES:
    off=e-BASE
    open(TMP,'wb').write(rom[off:off+256])
    out=subprocess.run([UNI,TMP,'-arch','tlcs900','-basepc',hex(e)],capture_output=True,text=True).stdout
    print(f'--- range 0x{e:06X}')
    for line in out.split('\n'):
        m=re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$',line)
        if not m: continue
        a=int(m.group(1),16); raw=m.group(2).split(); x=m.group(3).strip()
        b=rom[a-BASE:a-BASE+len(raw)]
        assert b.hex(' ')==' '.join(raw)
        mn=x.split()[0].lower()
        # THE NEW RULE: 2 bytes, first in 0x80..0x97, second a block sub-opcode
        sp=None
        if len(b)==2 and BLOCK_XFER.get((b[0],b[1])):
            sp=BLOCK_XFER[(b[0],b[1])]
            got=cc.encode(sp)
            print(f'   0x{a:06X} [{b.hex(" ")}] {x:10s} -> {sp:9s} {"OK" if got==b else "MISMATCH "+got.hex(" ")}')
            tot+=1; bad+= (got!=b)
            continue
        if mn in BRANCH: continue
        for cand in list(cc.translate(x))+[cc.canonical(x)]:
            if cc.encode(cand)==b: sp=cand; break
        tot+=1
        if sp is None:
            print(f'   0x{a:06X} [{b.hex(" ")}] {x:10s} -> STILL UNSPELLABLE'); bad+=1
        if mn in ('ret','reti','retd'): break
print(f'\nchecked {tot} instructions across {len(ENTRIES)} ranges; failures: {bad}')
