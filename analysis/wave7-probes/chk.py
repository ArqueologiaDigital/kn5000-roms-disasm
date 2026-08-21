import struct
src=open('hdae5000/hdae5000_init_data.s').read().splitlines()
def table(name):
    out=[];i=0
    while src[i].strip()!=name+':': i+=1
    i+=1
    while True:
        l=src[i].strip()
        if l.startswith('.long'):
            v=l.split(None,1)[1].split(';')[0].strip()
            if v=='0': break
            out.append(v)
        elif l and not l.startswith(';'): break
        i+=1
    return out
d=open('original_ROMs/hd-ae5000_v2_06i.ic4','rb').read(); base=0x280000
def rd(a,n): return [struct.unpack_from('<I',d,a-base+4*i)[0] for i in range(n)]
def s(a):
    o=a-base; return d[o:d.index(b'\x00',o)].decode('latin1')
TABLES=[('HDAE5000_ObjHandler_Table',0x2f94b2,0x2f95ca,69),
        ('HDAE5000_ClassProc_Table',0x2f97fa,0x2f9832,13),
        ('HDAE5000_ScreenProc_Table',0x2f9f5a,0x2f9f96,14)]
tot=0
for t,pa,na,n in TABLES:
    labs=table(t); names=[s(x) for x in rd(na,n)]
    print('TABLE',t,'src entries',len(labs),'rom names',len(names))
    for i,(lab,nm) in enumerate(zip(labs,names)):
        tot+=1
        if lab.replace('HDAE5000_','').lower()!=nm.lower():
            print('  MISMATCH %-26s %2d %-32s ROM name %-22s fn=0x%06x'%(t,i,lab,nm,rd(pa+4*i,1)[0]))
print('total pairs compared', tot)
allp=set()
for t,pa,na,n in TABLES: allp.update(rd(pa,n))
for a in (0x28030E,0x28033B,0x280368,0x280395,0x28F543):
    print(hex(a),'registry-named:', a in allp)
