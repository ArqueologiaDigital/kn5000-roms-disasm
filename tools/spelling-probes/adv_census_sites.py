#!/usr/bin/env python3
"""Replicate main()'s accounting to find WHICH addresses actually enter the
--forms census, so the 'phantoms inflate the census' claim can be tested."""
import importlib.util, json, os, re, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
sys.path.insert(0, os.path.join(REPO,"scripts/converters"))
_a=sys.argv[:]; sys.argv=[sys.argv[0]]
spec=importlib.util.spec_from_file_location("crr", os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(spec); spec.loader.exec_module(crr); sys.argv=_a
cc=crr.cc
s2=importlib.util.spec_from_file_location("spans", os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
os.chdir(REPO)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
targets=json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]
syms=cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"); addr2name=dict(syms)

def formkey(text):
    mn=text.split()[0]; rest=text.split(None,1)[1] if len(text.split(None,1))>1 else ""
    return mn+" "+re.sub(r'0x[0-9a-fA-F]+','imm',re.sub(r'\b[A-Z]{1,4}\b','r',rest))

WANT={'bit 7,(r+r)','ld (r+imm),r','ld (r+imm),imm'}
counted=[]
for t in sorted(targets):
    insns=crr.decode_range(rom,terr,t)
    if len(insns)<3: continue
    off=t-BASE; run=0
    while off+run<len(terr) and terr[off+run]==2: run+=1
    ends_at_code=sum(n for _,n,_ in insns)==run
    last=insns[-1][2].strip()
    if (last.split()[0].lower() not in crr.TERMINATORS
            and not crr.UNCOND_JUMP.match(last) and not ends_at_code):
        continue
    span=sum(n for _,n,_ in insns); want=rom[t-BASE:t-BASE+span]
    br=crr.resolve_branches(insns,t,span,addr2name)
    if br is None: continue
    br_texts,br_labels=br
    pos=0
    for bi,(addr,n,x) in enumerate(insns):
        target=want[pos:pos+n]
        if br_texts[bi] is not None:
            e=cc.encode(br_texts[bi])
            if e is None or len(e)!=n: break
            pos+=n; continue
        chosen=None
        for cand in list(cc.translate(x))+[cc.canonical(x)]:
            if cc.encode(cand)==target: chosen=cand; break
        if chosen is None:
            k=formkey(x)
            counted.append((t,addr,n,x,k, addr+n>t+run))
            break
        pos+=n
c=collections.Counter(k for _,_,_,_,k,_ in counted)
print("total census instances:",len(counted))
for k in sorted(WANT):
    rs=[r for r in counted if r[4]==k]
    print(f"\n{k}: {len(rs)} census instance(s)")
    for t,addr,n,x,_,ov in rs:
        print(f"   entry 0x{t:06X}  site 0x{addr:06X}  `{x}`  {'PHANTOM' if ov else ''}")
print("\nphantom instances in the census:", sum(1 for r in counted if r[5]))
