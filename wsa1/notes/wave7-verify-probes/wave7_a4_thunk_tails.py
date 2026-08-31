import struct
R='/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/'
A=open(R+'wsa1_prom_a.ic12','rb').read(); AB=0xF80000
def a(x,n): return A[x-AB:x-AB+n]
def le32(bs): return list(struct.unpack('<%dI'%(len(bs)//4),bs))
def walk(p):
    out=[]
    while True:
        v=le32(a(p,4))[0]
        if v==0xFFFFFFFF: return out
        out.append(v); p+=4
e=le32(a(0xF87E91,768))
tail=[0xF415A8,0xF4067C,0xF415B0,0xF40754,0xF418C8,0xF411C0,0xF40810]
match=[]; ne=[]
for i,p in enumerate(e):
    l=walk(p)
    if l: ne.append(i)
    if l and l[0]==0xF41070+4*i and l[1:]==tail: match.append(i)
print("non-empty ids count:",len(ne))
print("ids matching [T_F41070+4*id]+tail exactly:",len(match), match)
print("id 0 list:",[hex(x) for x in walk(e[0])])
print("id 31 list:",[hex(x) for x in walk(e[31])])
print("id 32 list:",[hex(x) for x in walk(e[32])])
# which ids have first entry == 0xF41070+4*id
f=[i for i in ne if walk(e[i])[0]==0xF41070+4*i]
print("ids whose FIRST entry is T_F41070+4*id:",len(f), f)
