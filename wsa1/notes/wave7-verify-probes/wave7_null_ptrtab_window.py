import os,sys
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
sys.path.insert(0, os.path.join(ROOT,"notes"))
sys.path.insert(0, os.path.join(ROOT,"scripts","analysis"))
import prom_b_f65000_layout as L
d=L.rom()
runs=L.proven_code_runs()
print("corpus runs",len(runs),"bytes",sum(e-s for s,e in runs))
for lo,hi,name in ((0x00F00000,0x00F80000,"prom_b only (round 5)"),
                   (0x00F00000,0x01000000,"two-image")):
    L.PTR_LO,L.PTR_HI=lo,hi
    hits=[]
    for s,e in runs: hits+=L.ptr_tables(d,s,e)
    print("  ptrtab>=3 window 0x%06X-0x%06X (%s): %d false positives  %s"%(lo,hi-1,name,len(hits)," ".join("0x%06X(%d)"%(a,b-a) for a,b in hits[:6])))
