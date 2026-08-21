from collections import Counter
P="/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_waveform_rom.ic307"
d=open(P,"rb").read()
PAGE=0x100000
def u16(o): return d[o]|d[o+1]<<8
print("file size", hex(len(d)))
allpairs=0; flag0=Counter(); f0_mult8=0; f0_gt7f=0
f1_2f=0; f1_2f_ge_e0=0
bit7=0; bit7_last=0; bit6=0; bit6_last=0
uniq=set(); tot=0
for p in range(4):
    b=p*PAGE; n=u16(b)//4
    idx=[(u16(b+4*i), u16(b+4*i+2)) for i in range(n)]
    params=sorted(set(x[0] for x in idx)); waves=sorted(set(x[1] for x in idx))
    pcm0=min(waves)*16
    print(f"page {p} base 0x{b:06X} N={n} dir 0x0000-0x{n*4-1:04X} params 0x{params[0]:04X}-0x{params[-1]:04X} "
          f"PCM starts 0x{pcm0:06X} (wave_off min {min(waves)}) max wave_off*16=0x{max(waves)*16:06X}")
    # padding between last param record end and PCM start
    # find end of last param record by stripping trailing zero words
    lastpp=params[-1]
    raw=d[b+lastpp:b+pcm0]
    e=len(raw)
    while e>=2 and raw[e-2]==0 and raw[e-1]==0: e-=2
    print(f"   last param rec 0x{lastpp:04X}, raw len {len(raw)}, stripped len {e}, pad {len(raw)-e} bytes")
    # back-steps in wave_off
    backsteps=[i for i in range(1,n) if idx[i][1] < idx[i-1][1]]
    if backsteps: print(f"   wave_off back-steps at entries {backsteps}")
    for i,(pp,wo) in enumerate(idx):
        tot+=1; uniq.add((p,wo))
        nx=[q for q in params if q>pp]
        if nx: end=nx[0]
        else:
            end=lastpp+e
        rec=d[b+pp:b+end]
        pairs=[(rec[j],rec[j+1]) for j in range(2,len(rec),2)]
        allpairs+=len(pairs)
        for k,(v,f) in enumerate(pairs):
            last = (k==len(pairs)-1)
            if f==0:
                flag0[0]+=1
                if v%8==0: f0_mult8+=1
                if v>0x7F: f0_gt7f+=1
            if 0x01<=f<=0x2F:
                f1_2f+=1
                if v>=0xE0: f1_2f_ge_e0+=1
            if f&0x80:
                bit7+=1
                if last: bit7_last+=1
            if f&0x40:
                bit6+=1
                if last: bit6_last+=1
print()
print("total slots", tot, "unique (page,wave_off)", len(uniq))
print("total pairs", allpairs)
print("flag 0x00 pairs", flag0[0], "mult8", f0_mult8, "value>0x7F", f0_gt7f)
print("flags 0x01-0x2F", f1_2f, "of which value>=0xE0", f1_2f_ge_e0, f"({100*f1_2f_ge_e0/f1_2f:.1f}%)")
print("bit7", bit7, "final", bit7_last, "non-final", bit7-bit7_last)
print("bit6", bit6, "final", bit6_last, "non-final", bit6-bit6_last)
