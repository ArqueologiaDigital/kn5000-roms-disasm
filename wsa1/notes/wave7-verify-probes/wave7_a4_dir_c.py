import struct
R='/home/fsanches/compartilhado/wsa1-roms-disasm/original_ROMs/'
A=open(R+'wsa1_prom_a.ic12','rb').read(); AB=0xF80000
def a(x,n): return A[x-AB:x-AB+n]
def le32(bs): return list(struct.unpack('<%dI'%(len(bs)//4),bs))
e=le32(a(0xF88EC1,768))
print("dir C entry[167..171]:",[hex(x) for x in e[167:172]])
print("raw at dir C + 167*4 = %06X:"%(0xF88EC1+167*4), a(0xF88EC1+167*4,24).hex())
lo=min(e[167:172]); 
print("area C raw hexdump around those lists:")
for p in range(0xF891C2,0xF893B6,16):
    print("%06X  %s"%(p, a(p,16).hex(' ')))
