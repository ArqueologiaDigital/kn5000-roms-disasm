import sys,struct
ROM='/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom'
BASE=0x0EF00
d=open(ROM,'rb').read()
def off(a): return a-BASE
def by(a,n=16): return d[off(a):off(a)+n]
def hx(a,n=16): return ' '.join('%02X'%b for b in by(a,n))
def u32(a): return struct.unpack_from('<I',d,off(a))[0]
def u16(a): return struct.unpack_from('<H',d,off(a))[0]
def s16(a): return struct.unpack_from('<h',d,off(a))[0]
