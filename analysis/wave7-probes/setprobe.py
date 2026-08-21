import sys, struct, collections
ROM = open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom','rb').read()
BASE_ADDR = 0x800000
DBB = 0x830000            # ToneDB_Base
def off(a): return a - BASE_ADDR
def u8(a): return ROM[off(a)]
def u16(a): return struct.unpack_from('<H', ROM, off(a))[0]
def u32(a): return struct.unpack_from('<I', ROM, off(a))[0]

DESC = 0x857914
N = 487
STRIDE = 15

print("=== directory slots ===")
for s in (0x08,0x18,0x1c,0x20,0x30,0x34,0x38,0x70,0xea,0xec,0xf0,0xf2):
    print("  +0x%02X = 0x%08X (=%d)" % (s, u32(DBB+s), u32(DBB+s)))

print()
print("=== descriptor census ===")
flags = collections.Counter()
recs=[]
for i in range(N):
    a = DESC + i*STRIDE
    f  = u8(a)
    oA = u32(a+1); oB = u32(a+5)
    b9 = u8(a+9); bA = u8(a+10); root = u8(a+11)
    bp = u16(a+12); bE = u8(a+14)
    recs.append((i,f,oA,oB,b9,bA,root,bp,bE))
    flags[f]+=1
print(" flags:", dict(sorted(flags.items())))
print(" +0x0E byte census:", collections.Counter(r[8] for r in recs))
print(" root byte census:", collections.Counter(r[6] for r in recs))
print(" basepitch census:", collections.Counter(hex(r[7]) for r in recs))
print(" +0x09 range: %d..%d ; +0x0A range: %d..%d" % (
    min(r[4] for r in recs), max(r[4] for r in recs),
    min(r[5] for r in recs), max(r[5] for r in recs)))
print(" records with +0x09 > +0x0A:", sum(1 for r in recs if r[4]>r[5]))

print()
print("=== bit1 records (the pitch trap) ===")
for r in recs:
    if r[1] & 0x02:
        print("  idx %3d flags 0x%02X A=0x%06X B=0x%06X lo=%3d hi=%3d root=0x%02X basepitch=0x%04X +0x0E=0x%02X"
              % (r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8]))
print(" count bit1 =", sum(1 for r in recs if r[1]&2))
print(" root!=0x42 set:", sorted(r[0] for r in recs if r[6]!=0x42))
print(" basepitch!=0x4280 set:", sorted(r[0] for r in recs if r[7]!=0x4280))
