import struct
R='/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/'
A=open(R+'wsa1_prom_a.ic12','rb').read(); AB=0xF80000
B=open(R+'wsa1_prom_b.ic13','rb').read(); BB=0xF00000
def a(x,n): return A[x-AB:x-AB+n]
def b(x,n): return B[x-BB:x-BB+n]
def le32(bs): return list(struct.unpack('<%dI'%(len(bs)//4),bs))
def le16(bs): return list(struct.unpack('<%dH'%(len(bs)//2),bs))
P=print
P("A. head pad 0xF85FF9..0xF85FFF:",a(0xF85FF9,7).hex(), "set",sorted(set(a(0xF85FF9,7))))
P("   byte at 0xF85FF8:",hex(A[0xF85FF8-AB]))
w=le32(a(0xF8671A,128))
P("B. 0xF8671A 32 words == 1<<k:", all(w[k]==(1<<k) for k in range(32)), "last=",hex(w[31]))
w2=le32(a(0xF8679A,128))
P("C. 0xF8679A[0:8]:",[hex(x) for x in w2[:8]], "expect 1<<17..1<<24:",[w2[i]==(1<<(17+i)) for i in range(8)])
P("   0xF8679A[8:32] all zero:", set(w2[8:])=={0}, "last:",hex(w2[31]))
P("D. 0xF868DB 32B:",a(0xF868DB,32).hex())
P("E. 0xF868FB 8B:",a(0xF868FB,8).hex())
for base in (0xF86BA0,0xF86BA8,0xF86BB0,0xF86BB8):
    P("F. 0x%06X:"%base, a(base,8).hex())
wt=le16(a(0xF86C8C,34))
P("G. 0xF86C8C 17 words:",[hex(x) for x in wt])
P("H. 0xF86CC9,CA:",a(0xF86CC9,2).hex())
P("I. 0xF86CCB..0xF86E80 438B all zero:", set(a(0xF86CCB,438))=={0}, "len chk", 0xF86E80-0xF86CCB+1)
P("   byte at 0xF86E81:",hex(A[0xF86E81-AB]))
m=a(0xF86E81,32)
P("J. 0xF86E81 32B:",m.hex()," min/max",hex(min(m)),hex(max(m)))
P("J2.0xF86EA1 32B:",a(0xF86EA1,32).hex())
ht=le32(a(0xF86EC1,1024))
P("K. handler tbl len",len(ht),"all in 0x00F00000..0x01000000:", all(0x00F00000<=x<0x01000000 for x in ht))
P("   ==0xF872C1 count:",sum(1 for x in ht if x==0xF872C1), " live:",sum(1 for x in ht if x!=0xF872C1))
P("   last entry:",hex(ht[255]))
# 172 naming three consecutive jp slots of prom_b directory
def is_jp_slot(addr):
    # prom_b thunk directory: check bytes at addr are a jp long (opcode?)
    if not (0xF00000<=addr<0xF80000-3): return None
    return b(addr,4).hex()
live=[x for x in ht if x!=0xF872C1]
def three_jp(x):
    if not (0xF00000<=x and x+12<=0xF80000+0xF00000): pass
    try:
        bs=b(x,12)
    except Exception:
        return False
    # a `jp` in tlcs900: 0x1A imm24? check pattern of directory: each slot 4 bytes
    return bs
cnt=0; exc=[]
for x in live:
    ok=False
    if 0xF00000<=x<0xF80000:
        bs=b(x,12)
        # three consecutive 4-byte slots each starting with the same opcode as a jp
        if bs[0]==bs[4]==bs[8] and bs[0]!=0x0E:
            ok=True
    if ok: cnt+=1
    else: exc.append(hex(x))
P("   crude 'three consecutive same-opcode slots':",cnt,"exceptions:",exc)
P("L. stub 0xF872C1 9B:",a(0xF872C1,9).hex())
P("M. 0xF872CA..0xF87680 951B all zero:",set(a(0xF872CA,951))=={0}, 0xF87680-0xF872CA+1)
for name,d,end in (("A",0xF87681,0xF87980),("B",0xF87E91,0xF88190),("C",0xF88EC1,0xF891C0)):
    e=le32(a(d,768))
    P("N.%s dir entries"%name,len(e),"e[0]=",hex(e[0]),"end+1=",hex(end+1),"e[0]==end+2?",hex(end+2),
      " spare byte:",hex(A[end+1-AB]), " e[191]=",hex(e[191]),"e[190]=",hex(e[190]),"equal:",e[191]==e[190])
