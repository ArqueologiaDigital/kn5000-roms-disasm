import importlib.util, json, os, re, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; os.chdir(REPO)
sys.argv=["x"]
s=importlib.util.spec_from_file_location("crr","scripts/converters/convert_reachable_ranges.py")
crr=importlib.util.module_from_spec(s); s.loader.exec_module(crr)
cc=crr.cc
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
sp=importlib.util.spec_from_file_location("spans","scripts/analysis/v7_undisassembled_spans.py")
spans=importlib.util.module_from_spec(sp); sp.loader.exec_module(spans)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
a2n=dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
sites={0xEF8484:0xEF8440,0xEF852F:0xEF84AC,0xEF870C:0xEF86D1,0xEFF455:0xEFF447,
       0xF0FA00:0xF0F9A7,0xF27267:0xF27267,0xF50EF4:0xF50D10,0xF97839:0xF97814}
tg={0xEF8484:0xEF8480,0xEF852F:0xEF850D,0xEF870C:0xEF86D6,0xEFF455:0xEFF452,
    0xF0FA00:0xF0F9AF,0xF27267:0xF2723C,0xF50EF4:0xF50EB3,0xF97839:0xF97833}
for site,t in sorted(sites.items()):
    insns=crr.decode_range(rom,terr,t)
    span=sum(n for _,n,_ in insns)
    addrs={a for a,_,_ in insns}
    tgt=tg[site]
    inside = t <= tgt < t+span
    if inside:
        verdict = ".Lc_%06x (LOCAL)"%tgt if tgt in addrs else "*** MID-INSTRUCTION -> resolve_branches returns None ***"
    else:
        verdict = "external -> %s"%(a2n.get(tgt,"*** UNNAMEABLE -> None ***"))
    print("site 0x%06X entry 0x%06X span %5d  target 0x%06X  inside=%-5s  %s"%(
        site,t,span,tgt,inside,verdict))
