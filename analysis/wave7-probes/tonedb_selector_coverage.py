import struct, collections
ROM='/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom'
d=open(ROM,'rb').read(); BASE=0x800000; TDB=0x830000
def fo(a): return a-BASE
def u8(a): return d[fo(a)]
def u16(a): return struct.unpack_from('<H',d,fo(a))[0]
def u32(a): return struct.unpack_from('<I',d,fo(a))[0]
TAB=TDB+u32(TDB+0x30); N=487
recs=[dict(i=i,flags=u8(TAB+i*15),A=u32(TAB+i*15+1),B=u32(TAB+i*15+5)) for i in range(N)]
offs=sorted(set([r['A'] for r in recs]+[r['B'] for r in recs])); END=0x863079-TDB
nxt={o:(offs[k+1] if k+1<len(offs) else END) for k,o in enumerate(offs)}
inb1=set(); inrest=set(); allsel=set()
for r in recs:
    stride=6 if r['flags']&0x80 else 4
    nz=(nxt[r['B']]-r['B'])//stride
    for z in range(nz):
        s=u16(TDB+r['B']+z*stride); allsel.add(s)
        (inb1 if r['flags']&2 else inrest).add(s)
print('distinct total', len(allsel))
print('appearing in bit1 SETs (any):', len(inb1))
print('exclusive to bit1 SETs:', len(inb1-inrest))
print('shared:', len(inb1&inrest))
print('exclusive pct %.1f  any pct %.1f'%(100*len(inb1-inrest)/len(allsel),100*len(inb1)/len(allsel)))
