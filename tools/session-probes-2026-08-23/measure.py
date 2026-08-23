#!/usr/bin/env python3
"""Measure what the two proposed spellings are worth, WITHOUT editing any source.

Runs convert_reachable_ranges' acceptance loop twice over the same cached
decodes: once with the tree's own cc.translate, once with cc.translate wrapped to
also yield `push_a` and `orddm8 (<addr>), <r8>`. Reports accepted ranges, bytes,
and bytes lost to truncation.
"""
import importlib.util, json, os, re, sys, collections
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
def load(n,p):
    s=importlib.util.spec_from_file_location(n,os.path.join(REPO,p))
    m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
crr=load("crr","scripts/converters/convert_reachable_ranges.py"); cc=crr.cc
spans=load("spans","scripts/analysis/v7_undisassembled_spans.py")
os.chdir(REPO)
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
targets=json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]
addr2name=dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

CACHE={}
def decode(t):
    if t not in CACHE: CACHE[t]=crr.decode_range(rom,terr,t)
    return CACHE[t]

_orig=cc.translate
def patched(text):
    yield from _orig(text)
    p=text.split(None,1)
    if len(p)==2:
        mn,rest=p[0].lower(),p[1].strip()
        if mn=="push" and rest.upper()=="A":
            yield "push_a"
        m=re.match(r'^\((0x[0-9a-fA-F]+)\)\s*,\s*([A-Za-z])$',rest)
        if mn=="or" and m:
            yield f"orddm8 ({m.group(1)}), {m.group(2).lower()}"
            yield f"orddm16 ({m.group(1)}), {m.group(2).lower()}"

def run(tr):
    cc.translate=tr
    ok=total=trunc=0
    for t in sorted(targets):
        insns=decode(t)
        if len(insns)<3: continue
        _off=t-BASE; _run=0
        while _off+_run<len(terr) and terr[_off+_run]==2: _run+=1
        ends=sum(n for _,n,_ in insns)==_run
        last=insns[-1][2].strip()
        if (last.split()[0].lower() not in crr.TERMINATORS
                and not crr.UNCOND_JUMP.match(last) and not ends): continue
        span=sum(n for _,n,_ in insns); want=rom[t-BASE:t-BASE+span]; full=span
        br=crr.resolve_branches(insns,t,span,addr2name)
        if br is None: continue
        br_texts,br_labels=br
        texts,pos,bad=[],0,False
        for bi,(a,n,x) in enumerate(insns):
            tgt=want[pos:pos+n]
            if br_texts[bi] is not None:
                e=cc.encode(br_texts[bi])
                if e is None or len(e)!=n: bad=True; break
                texts.append(br_texts[bi]); pos+=n; continue
            ch=None
            for cand in list(cc.translate(x))+[cc.canonical(x)]:
                if cc.encode(cand)==tgt: ch=cand; break
            if ch is None: bad=True; break
            texts.append(ch); pos+=n
        if bad:
            if len(texts)<3: continue
            insns=insns[:len(texts)]; span=sum(n for _,n,_ in insns)
            want=want[:span]; br_texts=br_texts[:len(texts)]
            end=t+span
            br_labels={a:l for a,l in br_labels.items() if t<=a<end}
            live=set(br_labels.values())
            if any(bt and ".Lc_" in bt and bt.rsplit(None,1)[-1] not in live
                   for bt in br_texts): continue
            trunc+=full-span
        if crr.implausible(texts): continue
        if not br_labels and not any(x is not None for x in br_texts):
            encs=cc.encode_block(texts)
            if encs is None or b"".join(encs)!=want: continue
        ok+=1; total+=span
    return ok,total,trunc

a=run(_orig);  print(f"baseline : {a[0]:5} ranges  {a[1]:8,} bytes  trunc-loss {a[2]:6,}")
b=run(patched);print(f"patched  : {b[0]:5} ranges  {b[1]:8,} bytes  trunc-loss {b[2]:6,}")
print(f"delta    : {b[0]-a[0]:+5} ranges  {b[1]-a[1]:+8,} bytes  trunc-loss {b[2]-a[2]:+6,}")
