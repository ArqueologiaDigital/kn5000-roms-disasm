import json, sys, collections
img, romf, base = sys.argv[1], sys.argv[2], int(sys.argv[3],16)
rom=open(romf,'rb').read()
d=json.load(open(f'symbr/{img}.json'))
newt={int(a,16):(n,l) for a,n,l,k in d['labels_new']}
def pr(c): return 0x20<=c<0x7f
def ascii_win(p):
    w=rom[max(0,p-8):p+8]
    return sum(pr(c) for c in w)>=13 and 0 in rom[max(0,p-24):p+24]
def ptr_win(p):
    for a in range(4):
        n=best=0
        for i in range(max(0,p-16)+a, p+16, 4):
            v=int.from_bytes(rom[i:i+4],'little')
            if base<=v<base+len(rom): n+=1; best=max(best,n)
            else: n=0
        if best>=4: return True
    return False
hits=collections.defaultdict(list)
for p in range(len(rom)-3):
    op=rom[p]; t=None
    if 0x60<=op<=0x6f: t=p+2+(rom[p+1]-256 if rom[p+1]>127 else rom[p+1])
    elif 0x70<=op<=0x7f or op==0x1e:
        v=int.from_bytes(rom[p+1:p+3],'little'); v=v-65536 if v>32767 else v; t=p+3+v
    else: continue
    ta=base+t
    if ta in newt:
        kind='ascii' if ascii_win(p) else ('ptrtab' if ptr_win(p) else None)
        if kind: hits[kind].append((hex(base+p),hex(ta))+newt[ta])
for k,v in hits.items():
    print(k,len(v))
    for x in v[:40]: print('  ',x)
