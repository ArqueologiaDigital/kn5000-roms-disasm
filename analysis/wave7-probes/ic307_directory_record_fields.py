from collections import Counter
P="/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_waveform_rom.ic307"
d=open(P,"rb").read()
PAGE=0x100000
def u16(o): return d[o]|d[o+1]<<8
tot_pairs=0; tot_pairs_nopad=0
allflags=Counter(); allflags_nopad=Counter()
back=0; tot=0
bit7_notlast=0; bit7_last=0
bit6_mid=0; bit6_last=0
f0_vals=[]; f1_2f_vals=[]
recs_with_bit7=0
allwaves=set()
for p in range(4):
    b=p*PAGE; n=u16(b)//4
    idx=[(u16(b+4*i), u16(b+4*i+2)) for i in range(n)]
    params=sorted(set(x[0] for x in idx)); waves=sorted(set(x[1] for x in idx))
    allwaves|=set((p,w) for w in waves)
    dir_end=4*n
    pcm_start=min(waves)*16
    last_param=max(params)
    # trailing zero pad between end of last record's real content and pcm_start
    e=pcm_start
    z=0
    while e-1-z>=0 and d[b+e-1-z]==0: z+=1
    print(f"page {p}: n={n} dir 0x0000-0x{dir_end-1:04X} params 0x{min(params):04X}-0x{pcm_start-1:04X} lastparam=0x{last_param:04X} pcm_start=0x{pcm_start:06X} trailing_zero_bytes={z} last_rec_extent={pcm_start-last_param}")
    print(f"   pcm end (page end) 0x{PAGE-1:06X}; max wave_off*16 = 0x{max(waves)*16:06X}")
    for i,(pp,wo) in enumerate(idx):
        tot+=1
        if u16(b+pp)==wo: back+=1
        nx=[q for q in params if q>pp]; end=nx[0] if nx else pcm_start
        rec=d[b+pp:b+end]
        pairs=[(rec[j],rec[j+1]) for j in range(2,len(rec),2)]
        tot_pairs+=len(pairs)
        for v,f in pairs: allflags[f]+=1
        # strip trailing all-zero words (pad) for the LAST record of the page
        pr=pairs[:]
        if not nx:
            while pr and pr[-1]==(0,0): pr.pop()
        tot_pairs_nopad+=len(pr)
        for v,f in pr: allflags_nopad[f]+=1
        for k,(v,f) in enumerate(pr):
            if f&0x80:
                if k==len(pr)-1: bit7_last+=1
                else: bit7_notlast+=1
            if f&0x40:
                if k==len(pr)-1: bit6_last+=1
                else: bit6_mid+=1
            if f==0x00: f0_vals.append(v)
            if 0x01<=f<=0x2f: f1_2f_vals.append(v)
        if pr and (pr[-1][1]&0x80): recs_with_bit7+=1
print("back:",back,"/",tot)
print("pairs raw",tot_pairs,"nopad",tot_pairs_nopad)
print("flag0x00 raw",allflags[0],"nopad",allflags_nopad[0])
print("bit7 last",bit7_last,"notlast",bit7_notlast,"records ending bit7",recs_with_bit7)
print("bit6 mid",bit6_mid,"last",bit6_last, "total bit6", bit6_mid+bit6_last)
print("f0: n=",len(f0_vals)," mult8=",sum(1 for v in f0_vals if v%8==0)," >0x7F=",sum(1 for v in f0_vals if v>0x7f))
print("f1-2f: n=",len(f1_2f_vals)," >=0xE0=",sum(1 for v in f1_2f_vals if v>=0xE0))
print("distinct (page,wave_off) =",len(allwaves))
