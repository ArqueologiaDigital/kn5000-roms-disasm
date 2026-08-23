#!/usr/bin/env python3
"""CONTROL: is "v7 gap == v9 gap" special to the blocking labels, or universal?

Also: how different are the v7 and v9 BYTES at each blocking label?  If the
spacing is v9's but the bytes are not, the offset cannot be right for v7.
"""
import os, pickle, re, subprocess, sys, collections, json
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm"; S=os.environ["SCRATCH"]; BASE=0xE00000
NM=os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
def syms(elf):
    out={}
    for ln in subprocess.run([NM,"--no-sort",os.path.join(ROOT,elf)],capture_output=True,text=True).stdout.splitlines():
        p=ln.split()
        if len(p)==3:
            try:a=int(p[0],16)
            except ValueError:continue
            if BASE<=a<0x1000000 and p[2] not in out: out[p[2]]=a
    return out
s7=syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"); s9=syms("rebuilt_ROMs/kn5000_v9_program.llvm.elf")
rom7=open(os.path.join(ROOT,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
rom9=open(os.path.join(ROOT,"original_ROMs/kn5000_v9_program.rom"),"rb").read()
# control: every consecutive pair of v7 symbols that both exist in v9
common=sorted((a,n) for n,a in s7.items() if n in s9)
same=diff=0
for i in range(len(common)-1):
    (a0,n0),(a1,n1)=common[i],common[i+1]
    if a1==a0: continue
    g7=a1-a0; g9=s9[n1]-s9[n0]
    if g9==g7: same+=1
    else: diff+=1
print(f"CONTROL over ALL v7 symbol pairs also present in v9: {same+diff} pairs")
print(f"   gap identical to v9 : {same} ({100.0*same/(same+diff):.1f}%)")
print(f"   gap differs         : {diff} ({100.0*diff/(same+diff):.1f}%)")
print()
# byte agreement at each blocking label
ev=json.load(open(os.path.join(S,"evidence.json")))
ag=[]
for r in ev:
    for l in r["labels"]:
        a7=l["addr"]; a9=s9.get(l["name"])
        if a9 is None: continue
        w=32
        m=sum(1 for k in range(-w,w) if rom7[a7-BASE+k]==rom9[a9-BASE+k])
        ag.append((l["name"],a7,a9,m,2*w))
print(f"BYTE AGREEMENT v7 vs v9 in a +/-32 B window around each blocking label ({len(ag)} labels):")
b=collections.Counter()
for _,_,_,m,t in ag:
    b[f"{10*(m*10//t)}-{10*(m*10//t)+9}%"]+=1
for k,v in sorted(b.items()): print(f"   {k:8} {v}")
print(f"   mean agreement {sum(m for *_ ,m,t in [(0,0,0,m,t) for _,_,_,m,t in ag])/len(ag)/64*100:.1f}%")
