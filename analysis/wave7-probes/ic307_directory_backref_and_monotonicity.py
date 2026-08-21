from collections import Counter
P="/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_waveform_rom.ic307"
d=open(P,"rb").read(); PAGE=0x100000
def u16(o): return d[o]|d[o+1]<<8
for p in range(4):
    b=p*PAGE; n=u16(b)//4
    idx=[(u16(b+4*i), u16(b+4*i+2)) for i in range(n)]
    back=sum(1 for pp,wo in idx if u16(b+pp)==wo)
    print(f"page {p}: back {back}/{n}")
    # monotonic checks
    bad_p=[i for i in range(1,n) if idx[i][0]<idx[i-1][0]]
    bad_w=[i for i in range(1,n) if idx[i][1]<idx[i-1][1]]
    print("   param_ptr non-monotonic at", bad_p, " wave_off non-monotonic at", bad_w)
    waves=sorted(set(x[1] for x in idx))
    gaps=[(waves[i+1]-waves[i])*16 for i in range(len(waves)-1)]+[PAGE-waves[-1]*16]
    print("   largest wave region bytes:", max(gaps), "= samples", max(gaps)//2)
# page0 records 180,181 and 185-197
b=0; n=u16(b)//4
idx=[(u16(b+4*i), u16(b+4*i+2)) for i in range(n)]
params=sorted(set(x[0] for x in idx)); pcm=min(x[1] for x in idx)*16
def rec(i):
    pp,wo=idx[i]; nx=[q for q in params if q>pp]; end=nx[0] if nx else pcm
    r=d[b+pp:b+end]; return wo,[(r[j],r[j+1]) for j in range(2,len(r),2)]
for i in [180,181]:
    wo,pr=rec(i); print(f"page0 entry {i}: wave 0x{wo:04X} pairs={len(pr)} flags={sorted(set(f for v,f in pr))}")
for i in range(184,198):
    wo,pr=rec(i)
    f0=[v for v,f in pr if f==0]
    print(f"page0 entry {i}: wave 0x{wo:04X} npairs={len(pr)} flag0vals={f0}")
# descending check for flag0 within record, all pages
desc_ok=0; desc_bad=0
for p in range(4):
    bb=p*PAGE; nn=u16(bb)//4
    ix=[(u16(bb+4*i), u16(bb+4*i+2)) for i in range(nn)]
    pm=sorted(set(x[0] for x in ix)); pc=min(x[1] for x in ix)*16
    for i,(pp,wo) in enumerate(ix):
        nx=[q for q in pm if q>pp]; end=nx[0] if nx else pc
        r=d[bb+pp:bb+end]; pr=[(r[j],r[j+1]) for j in range(2,len(r),2)]
        if not nx:
            while pr and pr[-1]==(0,0): pr.pop()
        f0=[v for v,f in pr if f==0]
        if len(f0)>1:
            if all(f0[k]>f0[k+1] for k in range(len(f0)-1)): desc_ok+=1
            else: desc_bad+=1
print("flag0 lists strictly descending:", desc_ok, "not:", desc_bad)
