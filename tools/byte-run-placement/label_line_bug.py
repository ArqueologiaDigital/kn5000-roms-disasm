#!/usr/bin/env python3
"""How often does blocks_of() give a `.byte` run the WRONG address, and why?

Compares every block blocks_of() produces -- BEFORE source_index()'s ROM filter --
with the address the assembler gives that line.
"""
import glob, importlib.util, os, pickle, re, sys, tempfile
REPO=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))); OUT=os.environ.get("KN5000_PROBE_DIR", os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
BASE=0xE00000
os.chdir(REPO); sys.argv=[sys.argv[0]]
spec=importlib.util.spec_from_file_location("cc", os.path.join(REPO,"scripts/converters/convert_corroborated_blocks.py"))
cc=importlib.util.module_from_spec(spec); spec.loader.exec_module(cc)
syms=cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
recs=pickle.load(open(os.path.join(OUT,"line_map.pkl"),"rb"))
LM={}
for (a,_g,rel,ln,_t) in recs: LM.setdefault((rel,ln),a)
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
files=sorted(glob.glob(REPO+"/v7/maincpu/*/*.s")+glob.glob(REPO+"/v7/maincpu/*.s"))
agree=dis=noaddr=nolabel=0
cases=[]
for f in files:
    rel=os.path.relpath(f,REPO+"/v7/maincpu")
    lines,blocks=cc.blocks_of(f,syms)
    for (lb,a,s,e,raw) in blocks:
        if a is None: nolabel+=1; continue
        real=LM.get((rel,s))
        if real is None: noaddr+=1; continue
        if real==a: agree+=1; continue
        dis+=1
        prev=lines[s-1] if s>0 else ""
        romok = rom[a-BASE:a-BASE+len(raw)]==raw
        cases.append((rel,s+1,a,real,len(raw),prev.strip()[:60],romok))
print(f"blocks_of(): {agree} block(s) at the assembler's address, {dis} at a DIFFERENT one, "
      f"{nolabel} with no label address, {noaddr} in files the v7 build never includes")
print(f"of the {dis} wrong ones, {sum(1 for c in cases if c[6])} still PASS source_index()'s ROM check")
for (rel,ln,a,real,n,prev,romok) in cases[:40]:
    print(f"  {rel}:{ln}  index 0x{a:06X} vs assembler 0x{real:06X} (+{real-a})  {n} B  "
          f"ROM check {'PASSES ANYWAY' if romok else 'catches it'}\n      label line: {prev!r}")
