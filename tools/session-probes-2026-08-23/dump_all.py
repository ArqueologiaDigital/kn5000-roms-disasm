#!/usr/bin/env python3
"""EVERY site of `push r` / `or (imm),r` in the reachable-range decodes, whether
or not an earlier unspellable instruction currently masks it, plus the proposed
spelling's encoding from llvm-mc."""
import importlib.util, json, os, re, sys, collections
REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE = 0xE00000
def load(n,p):
    s=importlib.util.spec_from_file_location(n,os.path.join(REPO,p))
    m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
crr=load("crr","scripts/converters/convert_reachable_ranges.py"); cc=crr.cc
spans=load("spans","scripts/analysis/v7_undisassembled_spans.py")
os.chdir(REPO)
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
targets=json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

def formkey(x):
    mn=x.split()[0]; rest=x.split(None,1)[1] if len(x.split(None,1))>1 else ""
    return mn+" "+re.sub(r'0x[0-9a-fA-F]+','imm',re.sub(r'\b[A-Z]{1,4}\b','r',rest))
WANT={"push r","or (imm),r"}
sites={}   # addr -> dict
for t in sorted(targets):
    insns=crr.decode_range(rom,terr,t)
    if len(insns)<3: continue
    for (a,n,x) in insns:
        if formkey(x) in WANT:
            b=rom[a-BASE:a-BASE+n]
            rec=sites.setdefault(a,dict(addr=a,bytes=b.hex(" "),text=x,
                                        form=formkey(x),entries=[]))
            rec["entries"].append(t)
            assert rec["bytes"]==b.hex(" ") and rec["text"]==x
json.dump(sorted(sites.values(),key=lambda r:r["addr"]),
          open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/allsites.json","w"),indent=1)
print("SITES", len(sites))
