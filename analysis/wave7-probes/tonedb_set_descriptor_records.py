import struct, collections
ROM='/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom'
d=open(ROM,'rb').read(); BASE=0x800000; TDB=0x830000
def fo(a): return a-BASE
def u8(a): return d[fo(a)]
def u16(a): return struct.unpack_from('<H',d,fo(a))[0]
def u32(a): return struct.unpack_from('<I',d,fo(a))[0]
TAB=TDB+u32(TDB+0x30); N=487
recs=[]
for i in range(N):
    a=TAB+i*15
    recs.append(dict(i=i, flags=u8(a), A=u32(a+1), B=u32(a+5),
                     lo=u8(a+9), hi=u8(a+10), root=u8(a+11),
                     bp=u16(a+12), e=u8(a+14)))
print('table end ROM 0x%06X (claim 0x85959D)'%(TAB+N*15))
print('flags census', sorted(collections.Counter(r['flags'] for r in recs).items()))
print('+0x0E census', sorted(collections.Counter(r['e'] for r in recs).items()))
print('lo census(min,max, count==12)', min(r['lo'] for r in recs), max(r['lo'] for r in recs), sum(1 for r in recs if r['lo']==12))
print('hi min,max, count==120', min(r['hi'] for r in recs), max(r['hi'] for r in recs), sum(1 for r in recs if r['hi']==120))
print('root census', sorted(collections.Counter(r['root'] for r in recs).items()))
bit1=[r['i'] for r in recs if r['flags']&2]
print('bit1 records', bit1)
print('bit1 roots', sorted(set(r['root'] for r in recs if r['flags']&2)), 'bp', sorted(set(hex(r['bp']) for r in recs if r['flags']&2)))
print('non-0x42 roots recs', [r['i'] for r in recs if r['root']!=0x42])
print('bit7 set count', sum(1 for r in recs if r['flags']&0x80), 'clear', sum(1 for r in recs if not r['flags']&0x80))
print('bit0 count', sum(1 for r in recs if r['flags']&1), 'bit3 count', sum(1 for r in recs if r['flags']&8))
print('bit6 any', any(r['flags']&0x40 for r in recs))
# offsets distinct and tiling
offs=sorted(set([r['A'] for r in recs]+[r['B'] for r in recs]))
print('distinct offsets', len(offs), 'first ROM 0x%06X'%(TDB+offs[0]), 'last 0x%06X'%(TDB+offs[-1]))
# melodic/percussion
mel=[r for r in recs if r['i']<341]; per=[r for r in recs if r['i']>=341]
print('melodic',len(mel),'perc',len(per))
b1c=[r for r in mel if not r['flags']&2]
print('melodic bit1-clear', len(b1c), 'all root 0x42 & bp 0x4280:', all(r['root']==0x42 and r['bp']==0x4280 for r in b1c))
print('perc: all root 0x42', all(r['root']==0x42 for r in per), 'all stride4', all(not r['flags']&0x80 for r in per),
      'all lo=12 hi=120', all(r['lo']==12 and r['hi']==120 for r in per))
print('perc bp!=0x4280 count', sum(1 for r in per if r['bp']!=0x4280))
pc=collections.Counter(r['bp'] for r in per)
print('perc bp distinct', len(pc), sorted(((hex(k),v) for k,v in pc.items()), key=lambda x:-x[1]))
print('perc flags census', sorted(collections.Counter(r['flags'] for r in per).items()))
