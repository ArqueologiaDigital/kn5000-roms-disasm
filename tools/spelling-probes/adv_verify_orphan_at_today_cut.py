import importlib.util, os, sys
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
addr2name=dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
for a in sys.argv[1:]:
    t=int(a,16); insns=cr.decode_range(rom,terr,t); span=sum(n for _,n,_ in insns)
    br=cr.resolve_branches(insns,t,span,addr2name); bt,bl=br
    want=rom[t-BASE:t-BASE+span]; pos=0; cut=None
    for i,(ad,n,x) in enumerate(insns):
        tgt=want[pos:pos+n]; pos+=n
        if bt[i] is not None:
            e=cc.encode(bt[i]); ok=e is not None and len(e)==n
        else:
            ok=any(cc.encode(c)==tgt for c in list(cc.translate(x))+[cc.canonical(x)])
        if not ok: cut=i; break
    kb=sum(n for _,n,_ in insns[:cut])
    end=t+kb
    live={l for ad,l in bl.items() if t<=ad<end}
    print(f"range 0x{t:06X} {addr2name.get(t,'')}: {len(insns)} insns span {span}; TODAY cut at #{cut} (0x{insns[cut][0]:06X} {insns[cut][2]}) keeping {kb} B")
    print(f"  labels in range: {[(hex(k),v) for k,v in sorted(bl.items())]}")
    print(f"  live after cut : {sorted(live)}")
    for i,x in enumerate(bt[:cut]):
        if x and ".Lc_" in x and x.rsplit(None,1)[-1] not in live:
            print(f"  ORPHANED by #{i} 0x{insns[i][0]:06X}: {x}")
