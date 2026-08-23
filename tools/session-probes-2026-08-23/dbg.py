import importlib.util, json, os, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"
sys.argv=[sys.argv[0]]
spec=importlib.util.spec_from_file_location("crr",os.path.join(REPO,"scripts/converters/convert_reachable_ranges.py"))
crr=importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
rom=open(os.path.join(REPO,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
s2=importlib.util.spec_from_file_location("spans",os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
os.chdir(REPO)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
t=0xFE6611
off=t-0xE00000
end=off
while end<len(terr) and terr[end]==2 and end-off<16384: end+=1
print("run", hex(t), "len", end-off, "terr[off]=",terr[off])
insns=crr.decode_range(rom,terr,t)
for a,n,x in insns:
    if 0xFE67F0 <= a <= 0xFE6820:
        print(hex(a), n, repr(x), rom[a-0xE00000:a-0xE00000+n].hex(' '))
print("total insns", len(insns), "first", hex(insns[0][0]) if insns else None)
