#!/usr/bin/env python3
import sys
ROM=open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v7_program.rom','rb').read()
BASE=0xE00000
for a in sys.argv[1:]:
    n=8
    if ':' in a:
        a,n=a.split(':'); n=int(n)
    addr=int(a,16)
    off=addr-BASE
    print(f"0x{addr:06X}: " + ' '.join(f'{b:02x}' for b in ROM[off:off+n]))
