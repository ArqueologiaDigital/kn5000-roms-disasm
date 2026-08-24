import importlib.util, json, os, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
_cr=importlib.util.spec_from_file_location("cr",os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
cr=importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr); cc=cr.cc
_sp=importlib.util.spec_from_file_location("spans",os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)
rom=open(os.path.join(REPO,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
old=spans.l1.ROOT; spans.l1.ROOT=REPO
try: rs=spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu")
finally: spans.l1.ROOT=old
terr=spans.territory(rs)
for a in sys.argv[1:]:
    t=int(a,16); insns=cr.decode_range(rom,terr,t)
    span=sum(n for _,n,_ in insns)
    print(f"=== range 0x{t:06X}: {len(insns)} insns, span {span} B")
    for (ad,n,x) in insns: print(f"   0x{ad:06X} {n} {x}")
