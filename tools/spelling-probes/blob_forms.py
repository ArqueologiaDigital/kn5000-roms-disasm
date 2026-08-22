#!/usr/bin/env python3
"""Locate the remaining v7 .byte blobs in the ROM and count `ld r,N` sites in them."""
import os,re,subprocess,collections,glob
REPO=os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
ROM=os.path.join(REPO,'original_ROMs/kn5000_v7_program.rom')
BASE=0xE00000
UNI=os.path.expanduser('~/compartilhado/tools/unidasm')
rom=open(ROM,'rb').read()
byte_re=re.compile(r'^\s*\.byte\s+(.*)$')
runs=[]   # (file, startline, bytes)
for f in sorted(glob.glob(REPO+'/v7/maincpu/**/*.s',recursive=True)):
    cur=b''; start=None
    for i,line in enumerate(open(f,errors='replace'),1):
        m=byte_re.match(line)
        if m:
            vals=[v.strip() for v in m.group(1).split(';')[0].split(',') if v.strip()]
            try: b=bytes(int(v,0)&0xFF for v in vals)
            except ValueError:
                if cur: runs.append((f,start,cur)); cur=b''; start=None
                continue
            if not cur: start=i
            cur+=b
        else:
            if line.strip().startswith(';') or line.strip().endswith(':') or not line.strip():
                continue   # labels/comments don't break a run
            if cur: runs.append((f,start,cur)); cur=b''; start=None
    if cur: runs.append((f,start,cur))
print("runs:",len(runs), "total bytes:", sum(len(r[2]) for r in runs))
# locate each run uniquely in the rom
located=[]
unloc=0; ambig=0
for f,ln,b in runs:
    if len(b)<8: continue
    idx=rom.find(b)
    if idx<0: unloc+=1; continue
    if rom.find(b,idx+1)>=0: ambig+=1; continue
    located.append((f,ln,BASE+idx,b))
print("located:",len(located),"unlocated:",unloc,"ambiguous:",ambig,
      "located bytes:",sum(len(x[3]) for x in located))
pat=re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(ld [A-Z]+,[0-7])$')
cnt=collections.Counter(); examples={}
import tempfile
for f,ln,addr,b in located:
    tf=tempfile.NamedTemporaryFile(suffix='.bin',delete=False)
    tf.write(b); tf.close()
    out=subprocess.run([UNI,tf.name,'-arch','tlcs900','-basepc',hex(addr)],
                       capture_output=True,text=True).stdout
    os.unlink(tf.name)
    for line in out.split('\n'):
        m=pat.match(line)
        if not m: continue
        nb=len(m.group(2).split())
        key=(m.group(3).split()[1].split(',')[0], nb)
        cnt[key]+=1
        examples.setdefault(key,(int(m.group(1),16),m.group(2).strip(),m.group(3),f))
print("\n`ld r,N` sites inside remaining v7 .byte blobs:")
for k,v in cnt.most_common():
    a,by,txt,f=examples[k]
    print(f"  {v:5d}  reg={k[0]:5s} nbytes={k[1]}   e.g. {a:06x}: {by:10s} {txt}   [{os.path.relpath(f,REPO)}]")
print("total:",sum(cnt.values()))
