import importlib.util, json, os, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
sys.path.insert(0, os.path.join(REPO,"scripts/converters"))
_a=sys.argv[:]; sys.argv=[sys.argv[0]]
spec=importlib.util.spec_from_file_location("crr", os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(spec); spec.loader.exec_module(crr); sys.argv=_a
s2=importlib.util.spec_from_file_location("spans", os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
os.chdir(REPO)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
for t in (0xFCCFF4,0xFE5D89,0xFE6611,0xFE726F):
    insns=crr.decode_range(rom,terr,t)
    off=t-BASE; run=0
    while off+run<len(terr) and terr[off+run]==2: run+=1
    tot=sum(n for _,n,_ in insns)
    last=insns[-1]
    print(f"entry 0x{t:06X}: {len(insns)} insns, sum(len)={tot}, run={run}, ends_at_code={tot==run}, "
          f"last=`{last[2]}` term={last[2].split()[0].lower() in crr.TERMINATORS}")
