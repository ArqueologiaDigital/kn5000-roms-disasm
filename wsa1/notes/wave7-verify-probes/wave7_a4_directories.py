import struct
R='/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/'
A=open(R+'wsa1_prom_a.ic12','rb').read(); AB=0xF80000
B=open(R+'wsa1_prom_b.ic13','rb').read(); BB=0xF00000
def a(x,n): return A[x-AB:x-AB+n]
def le32(bs): return list(struct.unpack('<%dI'%(len(bs)//4),bs))
P=print
def walk(p):
    out=[]
    while True:
        v=le32(a(p,4))[0]
        if v==0xFFFFFFFF: return out,p+4
        out.append(v); p+=4
        if len(out)>200: raise SystemExit("runaway at %x"%p)
for name,d,area_lo,area_hi in (("A",0xF87681,0xF87982,0xF87B71),
                               ("B",0xF87E91,0xF88192,0xF88D09),
                               ("C",0xF88EC1,0xF891C2,0xF893B5)):
    e=le32(a(d,768))
    P("=== dir",name," min entry",hex(min(e)),"max entry",hex(max(e)))
    ends=[]; nonempty=[]
    for i,p in enumerate(e):
        lst,end=walk(p); ends.append(end)
        if lst: nonempty.append((i,[hex(x) for x in lst]))
    P("  area claimed %06X-%06X len %d"%(area_lo,area_hi,area_hi-area_lo+1))
    P("  entry[0]=%06X  max end of any list=%06X"%(e[0],max(ends)))
    P("  matches area_lo:",e[0]==area_lo," matches area_hi+1:",max(ends)==area_hi+1)
    P("  non-empty lists:",len(nonempty),"of 192")
    if name!="B":
        for i,l in nonempty: P("    [%d] -> %s"%(i,l))
    else:
        P("    first:",nonempty[0][0],nonempty[0][1])
        P("    last :",nonempty[-1][0],nonempty[-1][1])
        ids=[i for i,_ in nonempty]
        P("    ids min..max:",min(ids),max(ids),"contiguous:",ids==list(range(min(ids),max(ids)+1)))
        # claim: ids 0..32 each get per-id handler T_Msg0716_DispatchIndex_Msg0716_ObjectRecords_Msg0716_HandlerTables_13+4*id followed by common tail
        tail=['0xf415a8','0xf4067c','0xf415b0','0xf40754','0xf418c8','0xf411c0','0xf40810']
        okc=0; badc=[]
        for i,l in nonempty:
            if l[0]==hex(0xF41070+4*i) and l[1:]==tail: okc+=1
            else: badc.append((i,l))
        P("    lists == [T_Msg0716_DispatchIndex_Msg0716_ObjectRecords_Msg0716_HandlerTables_13+4*id]+common tail:",okc,"exceptions:",len(badc))
        for x in badc[:6]: P("      ",x)
# fallback lists
for base in (0xF87E81,0xF88E91,0xF89671):
    lst,end=walk(base)
    P("fallback %06X -> %s  end=%06X len=%d"%(base,[hex(x) for x in lst],end,end-base))
# zero fields
for lo,hi in ((0xF87B72,0xF87E80),(0xF87E85,0xF87E90),(0xF88D0A,0xF88E90),(0xF88EAD,0xF88EC0),
              (0xF893B6,0xF89670),(0xF89675,0xF89684),(0xF89686,0xF8969A)):
    bs=a(lo,hi-lo+1)
    P("zero %06X-%06X len %d allzero %s"%(lo,hi,len(bs),set(bs)=={0}))
P("0xF89685 byte:",hex(A[0xF89685-AB]))
cl=a(0xF8969B,357)
P("closing fill 357B set:",sorted(set(cl)),"byte before:",hex(A[0xF8969A-AB]),"byte at 0xF89800:",hex(A[0xF89800-AB]))
# the three handler-table exceptions
for x in (0xF406C4,0xF406CC,0xF406DC):
    P("prom_b %06X +0..11:"%x, B[x-BB:x-BB+12].hex(), "set",sorted(set(B[x-BB:x-BB+12])))
