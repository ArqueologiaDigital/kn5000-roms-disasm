P="/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_waveform_rom.ic307"
d=open(P,"rb").read(); PAGE=0x100000
def u16(o): return d[o]|d[o+1]<<8
tot=0; strict=0; nonincr=0; bad=[]
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
            tot+=1
            if all(f0[k]>f0[k+1] for k in range(len(f0)-1)): strict+=1
            elif all(f0[k]>=f0[k+1] for k in range(len(f0)-1)): nonincr+=1
            else: bad.append((p,i,f0))
print("records with >1 flag0 value:",tot," strictly descending:",strict," non-increasing (ties):",nonincr," other:",len(bad))
for x in bad[:12]: print("  ",x)
