#!/usr/bin/env python3
"""How many of the 170 'a branch target cannot be named' skips would be named if
the blocking labels sat on the instruction boundary they drifted off?"""
import contextlib, importlib.util, io, json, os, re, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; S=os.environ["SCRATCH"]; BASE=0xE00000
os.chdir(REPO)
sp=importlib.util.spec_from_file_location("crr", REPO+"/scripts/converters/convert_reachable_ranges.py")
mod=importlib.util.module_from_spec(sp); sp.loader.exec_module(mod)
BR=mod.BRANCH_RE
UNNAMED=[]
orig=mod.resolve_branches
def hook(insns,t,span,addr2name):
    addrs={a for a,_n,_x in insns}
    for a,n,x in insns:
        m=BR.match(x.strip())
        if not m: continue
        tgt=int(m.group(3),16)
        if t<=tgt<t+span:
            if tgt not in addrs: UNNAMED.append(("mid-insn",t,tgt))
        elif tgt not in addr2name:
            UNNAMED.append(("no-symbol",t,tgt))
    return orig(insns,t,span,addr2name)
mod.resolve_branches=hook
sys.argv=["conv","--no-incbin"]
buf=io.StringIO()
with contextlib.redirect_stdout(buf): mod.main()
cen=json.load(open(os.path.join(S,"census313.json")))
lab={r["addr"]:r for r in cen}
kinds=collections.Counter(k for k,_,_ in UNNAMED)
print("unnamable branch targets seen:",dict(kinds))
ns=[tg for k,_,tg in UNNAMED if k=="no-symbol"]
hits=0
for tg in set(ns):
    for d in range(1,7):
        if tg+d in lab and lab[tg+d]["drift"]==d:
            hits+=1; break
print(f"distinct 'no symbol at the target' addresses: {len(set(ns))}")
print(f"   ... that a blocking label would land on if moved back by its drift: {hits}")
