#!/usr/bin/env python3
"""NULL for the drift figure.

If the labels were scattered at random inside a CORRECT decode, what drift
distribution would that give?  Every non-boundary byte of an instruction of
length n contributes an offset in 1..n-1.  If the observed drifts match that,
drift says nothing; if they are shifted towards small values it does.
"""
import collections, json, os, pickle, subprocess, re, sys
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm"; S=os.environ["SCRATCH"]; BASE=0xE00000
UNI=os.path.expanduser("~/compartilhado/tools/unidasm")
rom=open(os.path.join(ROOT,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
cases=pickle.load(open(os.path.join(S,"cases.pkl"),"rb"))["cases"]
obs=collections.Counter()
null=collections.Counter()
lens=collections.Counter()
for c in cases:
    ia={a:n for a,n,_ in c["insns"]}
    for n in ia.values():
        lens[n]+=1
        for k in range(1,n):
            null[k]+=1
    ins=sorted(ia)
    for a,nm in c["off_boundary"]:
        below=max((x for x in ins if x<=a),default=None)
        if below is not None: obs[a-below]+=1
tn=sum(null.values()); to=sum(obs.values())
print("instruction lengths in the 33 decodes:", dict(sorted(lens.items())))
print(f"\n{'drift':>6} {'observed':>9} {'obs %':>7} {'null %':>7}")
for k in sorted(set(list(obs)+list(null))):
    print(f"{k:>6} {obs.get(k,0):>9} {100.0*obs.get(k,0)/to:6.1f}% {100.0*null.get(k,0)/tn:6.1f}%")
# same for the 314-label census
cen=json.load(open(os.path.join(S,"census313.json")))
o2=collections.Counter(r["drift"] for r in cen if r["drift"] is not None)
t2=sum(o2.values())
print(f"\n314-label census, observed drift: " + ", ".join(f"+{k}:{100.0*v/t2:.1f}%" for k,v in sorted(o2.items())))
