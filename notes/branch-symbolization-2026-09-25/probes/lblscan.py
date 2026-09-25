import json, collections, sys
img=sys.argv[1]; rom=open(sys.argv[2],'rb').read(); base=int(sys.argv[3],16)
d=json.load(open(f'symbr/{img}.json'))
def asc(b): return all(0x20<=c<0x7f or c==0 for c in b) and sum(0x20<=c<0x7f for c in b)>=len(b)//2
def ptrtab(w):
    # find alignment where >=4 consecutive LE 32-bit values look like ROM pointers 0x00E0xxxx-0x00FFxxxx
    for a in range(4):
        n=0;best=0
        for i in range(a,len(w)-3,4):
            v=int.from_bytes(w[i:i+4],'little')
            if 0xE00000<=v<=0xFFFFFF: n+=1; best=max(best,n)
            else: n=0
        if best>=4: return True
    return False
hits=collections.defaultdict(list)
for addr,name,loc,kind in d['labels_new']:
    t=int(addr,16)-base
    if t<0 or t>=len(rom): continue
    w=rom[max(0,t-12):t+12]
    if asc(rom[max(0,t-6):t+6]): hits['ascii'].append((addr,name,loc))
    elif ptrtab(rom[max(0,t-20):t+20]): hits['ptrtab'].append((addr,name,loc))
for k,v in hits.items():
    print(k,len(v)); c=collections.Counter(x[2].split(':')[0] for x in v); print(' ',c.most_common(12))
    for x in v[:25]: print('   ',x)
