"""Which ranges are newly ACCEPTED by the push_a/orddm8 spellings? Patch the
`ok += 1` accounting by wrapping cc.encode_block/implausible is fragile, so
instead re-run main() with a tap on the acceptance print: raise the `ok <= 8`
print limit to everything by monkeypatching builtins.print is also fragile.
Simplest reliable tap: wrap crr.implausible to record, and wrap cc.encode_block.
Instead: set the limit high by patching the module's source-level constant is
not available -- so record via a wrapper around cc.encode_block AND the
`pending` list by running with --dry-run? that writes.

Chosen: re-implement nothing; instead monkeypatch `crr.addr2name`-free by
tapping `cc.encode_block` is insufficient (branchy ranges skip it).

Final approach: tap sys.stdout is unnecessary -- main() prints only the first 8.
So: patch the module's global `print` via crr.__dict__ to capture the
"0x%06X  %d B" acceptance lines, and lift the `ok <= 8` guard by making `ok`
comparison always true is impossible without editing source.

=> Use the ranges' effect indirectly: run the per-range acceptance decision in
a faithful copy of main()'s loop. Copied verbatim from the source below.
"""
import importlib.util, json, os, pickle, re, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; os.chdir(REPO)
_s=importlib.util.spec_from_file_location("crr",os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
cc=crr.cc
BASE=crr.BASE
CACHE=os.path.join(os.path.dirname(os.path.abspath(__file__)),"decodes.pkl")
decodes=pickle.load(open(CACHE,"rb"))

rom=open(os.path.join(REPO,"original_ROMs","kn5000_v7_program.rom"),"rb").read()
spec=importlib.util.spec_from_file_location("spans",os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
syms=cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addr2name=dict(syms)
targets=json.load(open(os.path.join(REPO,"analysis/v7-reachability/v7_call_targets.json")))["targets"]

_orig=cc.translate
def patched(x):
    for c in _orig(x): yield c
    p=x.split()
    if p[0].lower()=="push" and len(p)==2 and p[1].upper()=="A": yield "push_a"
    m=re.match(r'^or\s+\((0x[0-9a-fA-F]+)\),([A-Za-z]{1,3})$',x.strip())
    if m:
        yield f"orddm8 {m.group(1)}, {m.group(2).lower()}"
        yield f"orddm16 {m.group(1)}, {m.group(2).lower()}"

def run(tr):
    cc.translate=tr
    acc={}
    for t in sorted(targets):
        insns=decodes.get(t,[])
        if len(insns)<3: continue
        _off=t-BASE; _run=0
        while _off+_run<len(terr) and terr[_off+_run]==2: _run+=1
        ends_at_code=sum(n for _,n,_ in insns)==_run
        _last=insns[-1][2].strip()
        if (_last.split()[0].lower() not in crr.TERMINATORS
                and not crr.UNCOND_JUMP.match(_last) and not ends_at_code): continue
        span=sum(n for _,n,_ in insns)
        want=rom[t-BASE:t-BASE+span]; full_span=span
        br=crr.resolve_branches(insns,t,span,addr2name)
        if br is None: continue
        br_texts,br_labels=br
        texts,pos,bad=[],0,False
        for bi,(_,n,x) in enumerate(insns):
            target=want[pos:pos+n]
            if br_texts[bi] is not None:
                e=cc.encode(br_texts[bi])
                if e is None or len(e)!=n: bad=True; break
                texts.append(br_texts[bi]); pos+=n; continue
            chosen=None
            for cand in list(cc.translate(x))+[cc.canonical(x)]:
                if cc.encode(cand)==target: chosen=cand; break
            if chosen is None: bad=True; break
            texts.append(chosen); pos+=n
        if bad:
            kept=len(texts)
            if kept<3: continue
            insns=insns[:kept]; span=sum(n for _,n,_ in insns); want=want[:span]
            br_texts=br_texts[:kept]; end=t+span
            br_labels={a:l for a,l in br_labels.items() if t<=a<end}
            live=set(br_labels.values())
            if any(bt and ".Lc_" in bt and bt.rsplit(None,1)[-1] not in live for bt in br_texts): continue
            bad=False
        bad_mn=crr.implausible(texts)
        if bad_mn: continue
        has_branch=any(x is not None for x in br_texts)
        if not br_labels and not has_branch:
            encs=cc.encode_block(texts)
            if encs is None or b"".join(encs)!=want: continue
        acc[t]=(span,texts)
    return acc

base=run(_orig)
pat=run(patched)
print(f"baseline {len(base)} ranges {sum(v[0] for v in base.values())} B")
print(f"patched  {len(pat)} ranges {sum(v[0] for v in pat.values())} B")
print("\nNEWLY ACCEPTED:")
for t in sorted(set(pat)-set(base)):
    print(f"  0x{t:06X}  {pat[t][0]:5} B  {addr2name.get(t,'')}")
    for ln in pat[t][1][:6]: print(f"        {ln}")
    print("        ...")
print("\nNO LONGER ACCEPTED:")
for t in sorted(set(base)-set(pat)):
    print(f"  0x{t:06X}  {base[t][0]:5} B  {addr2name.get(t,'')}")
print("\nGREW (same range, more bytes):")
for t in sorted(set(base)&set(pat)):
    if pat[t][0]!=base[t][0]:
        print(f"  0x{t:06X}  {base[t][0]} -> {pat[t][0]} B  {addr2name.get(t,'')}")
