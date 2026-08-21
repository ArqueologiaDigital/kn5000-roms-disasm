import glob, os, re
FULL="/tmp/spec-audit3/full"; CONLY="/tmp/spec-audit3/repo"
INC=re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
cbin_names=set(os.path.basename(l.strip()) for l in open("/tmp/spec-audit3/v7_c_bins.txt") if l.strip())
tree="v7/maincpu"; TOTAL=2097152
inc=0; c_ok=0; c_rom=0; slice_rom=0; blob=0
for f in glob.glob(os.path.join(FULL,tree)+"/**/*.s",recursive=True):
    txt=open(f,encoding="latin-1").read()
    for path,off,ln in INC.findall(txt):
        cands=[os.path.join(os.path.dirname(f),path),os.path.join(FULL,tree,path),os.path.join(FULL,path)]
        real=next((c for c in cands if os.path.exists(c)),None)
        if not real: continue
        data=open(real,'rb').read()
        o=int(off,0) if off else 0
        n=int(ln,0) if ln else len(data)-o
        used=data[o:o+n]; inc+=len(used)
        base=os.path.basename(real)
        if "generated/" in real.replace(FULL,"") and base in cbin_names:
            cpath=os.path.join(CONLY,tree,"includes/generated",base)
            cdata=open(cpath,'rb').read()[o:o+n] if os.path.exists(cpath) else b""
            eq=sum(1 for a,b in zip(used,cdata) if a==b)
            c_ok+=eq; c_rom+=len(used)-eq
        elif "generated/" in real.replace(FULL,""):
            slice_rom+=len(used)
        else:
            blob+=len(used)
asm=TOTAL-inc
print(f"v7 maincpu ROM                          {TOTAL:9,d} B  100.00%")
print(f"  assembly source (.s, committed)       {asm:9,d} B  {100*asm/TOTAL:6.2f}%")
print(f"  incbin total                          {inc:9,d} B  {100*inc/TOTAL:6.2f}%")
print(f"    (a) C-rule bin, byte matches clang  {c_ok:9,d} B  {100*c_ok/TOTAL:6.2f}%   REAL SOURCE")
print(f"    (c) C-rule bin, ROM-slice override  {c_rom:9,d} B  {100*c_rom/TOTAL:6.2f}%   CIRCULAR")
print(f"    (c) pure extract_v7_bins ROM slice  {slice_rom:9,d} B  {100*slice_rom/TOTAL:6.2f}%   CIRCULAR")
print(f"    (b) committed .bin blob, no rule    {blob:9,d} B  {100*blob/TOTAL:6.2f}%   honest, not reconstructed")
print()
print(f"REAL SOURCE (asm + genuine C)           {asm+c_ok:9,d} B  {100*(asm+c_ok)/TOTAL:6.2f}%")
print(f"BUILD-TIME ROM COPY (circular)          {c_rom+slice_rom:9,d} B  {100*(c_rom+slice_rom)/TOTAL:6.2f}%")
print(f"COMMITTED BLOB (not reconstructed)      {blob:9,d} B  {100*blob/TOTAL:6.2f}%")
