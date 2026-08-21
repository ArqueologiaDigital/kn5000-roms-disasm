import struct, collections
ROM='/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom'
d=open(ROM,'rb').read(); BASE=0x800000; TDB=0x830000
def fo(a): return a-BASE
def u8(a): return d[fo(a)]
def u16(a): return struct.unpack_from('<H',d,fo(a))[0]
def u32(a): return struct.unpack_from('<I',d,fo(a))[0]
TAB=TDB+u32(TDB+0x30); N=487
recs=[dict(i=i,flags=u8(TAB+i*15),A=u32(TAB+i*15+1),B=u32(TAB+i*15+5),root=u8(TAB+i*15+11),bp=u16(TAB+i*15+12)) for i in range(N)]
offs=sorted(set([r['A'] for r in recs]+[r['B'] for r in recs]))
END=0x863079-TDB
nxt={}
for k,o in enumerate(offs): nxt[o]=offs[k+1] if k+1<len(offs) else END
sizes=collections.Counter(nxt[o]-o for o in offs)
print('chunk size census top', sizes.most_common(8))
CURVE0=0x85AD9D-TDB; CURVEEND=CURVE0+768
ok_stride=0; ok_alen=0; ok_maxidx=0
curve_use=collections.Counter(); zones_tot=0; sels=collections.Counter()
multizone_mel=0; sel_from_bit1=set(); all_sels=set()
b2=collections.Counter(); b3=[]; s6trim=[]
for r in recs:
    stride = 6 if r['flags']&0x80 else 4
    blen = nxt[r['B']]-r['B']; alen = nxt[r['A']]-r['A']
    nz = blen//stride
    if blen % stride == 0: ok_stride+=1
    kt = u32(TDB+r['A'])
    if CURVE0<=kt<CURVEEND and (kt-CURVE0)%128==0: curve_use[(kt-CURVE0)//128]+=1
    else: curve_use['OTHER 0x%X'%kt]+=1
    tbl = d[fo(TDB+kt):fo(TDB+kt)+128]
    mk = max(tbl)
    if alen == mk+1+4: ok_alen+=1
    band = d[fo(TDB+r['A'])+4 : fo(TDB+r['A'])+alen]
    if band and max(band)==nz-1: ok_maxidx+=1
    zones_tot+=nz
    if r['i']<341 and nz>1: multizone_mel+=1
    for z in range(nz):
        za=TDB+r['B']+z*stride
        sel=u16(za); all_sels.add(sel)
        if r['flags']&2: sel_from_bit1.add(sel)
        sels[sel>>12]+=1
        b2[u8(za+2)]+=1
        v=u8(za+3); b3.append(v-256 if v>127 else v)
        if stride==6:
            t=u16(za+4); s6trim.append(t-65536 if t>32767 else t)
print('stride-consistent %d/%d, A len==max+5 %d/%d, A maxidx==nz-1 %d/%d'%(ok_stride,N,ok_alen,N,ok_maxidx,N))
print('curve use', dict(curve_use))
print('total zone records', zones_tot, 'distinct selectors', len(all_sels))
print('class census 0..7', [sels[c] for c in range(8)])
print('selectors reachable ONLY from bit1 SETs:', len(sel_from_bit1 - (all_sels - sel_from_bit1)), 'of', len(all_sels))
print('  pct %.1f%%'%(100*len(sel_from_bit1-(all_sels-sel_from_bit1))/len(all_sels)))
print('+0x02 census', sorted(b2.items()))
print('+0x03 min %d max %d mean %.2f neg %d'%(min(b3),max(b3),sum(b3)/len(b3),sum(1 for x in b3 if x<0)))
print('s6 trim n=%d min %.2f max %.2f zero %d'%(len(s6trim),min(s6trim)/256,max(s6trim)/256,sum(1 for x in s6trim if x==0)))
print('melodic multizone', multizone_mel)
# curve maxima
for c in range(6):
    t=d[fo(TDB+CURVE0+c*128):fo(TDB+CURVE0+c*128)+128]
    print(' curve %d max %d bands %d'%(c,max(t),max(t)+1))
# scan whole ROM for LE32 landing in curve block
hits=[]
for a in range(0,len(d)-3):
    v=struct.unpack_from('<I',d,a)[0]
    if CURVE0<=v<CURVEEND: hits.append((a+BASE,v))
print('LE32 hits into curve block:', len(hits))
ahead=set(r['A'] for r in recs)
head_addrs=set()
for r in recs: head_addrs.add(TDB+r['A'])
extra=[h for h in hits if h[0] not in head_addrs]
print('non-A-head hits:', [(hex(a),hex(v)) for a,v in extra])
# drumtoneindexmap values
DTM=TDB+u32(TDB+0x2C); vals=set(u16(DTM+2*i) for i in range(1024))
print('DrumToneIndexMap distinct values min %d max %d, sorted head'%(min(vals),max(vals)), sorted(vals)[:6])
MC=TDB+u32(TDB+0x24); MD=TDB+u32(TDB+0x28)
print('MapC max', max(u16(MC+2*i) for i in range(1024)), 'MapD max', max(u16(MD+2*i) for i in range(1024)))
