import struct, collections
ROM='/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom'
d=open(ROM,'rb').read()
print('len',hex(len(d)))
BASE=0x800000            # file offset = addr - BASE
def fo(a): return a-BASE
TDB=0x830000             # ToneDB_Base ROM addr
def u8(a): return d[fo(a)]
def u16(a): return struct.unpack_from('<H',d,fo(a))[0]
def u32(a): return struct.unpack_from('<I',d,fo(a))[0]
# directory at 0x830000: 64 LE32 offsets relative to ToneDB_Base
print('--- directory slots of interest ---')
for off in (0x0c,0x10,0x14,0x18,0x1c,0x20,0x24,0x28,0x2c,0x30,0x34,0x38,0x9c,0xa0,0xa4,0x70):
    v=u32(TDB+off)
    print(' dir +0x%02X = 0x%08X -> ROM 0x%06X'%(off,v,TDB+v))
print(' dir u16 +0xEC = %d, +0xF2 = %d'%(u16(TDB+0xEC),u16(TDB+0xF2)))
