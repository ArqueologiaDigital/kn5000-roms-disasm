import sys
rom=open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_v10_program.rom','rb').read()
B=0xE00000
for t in sys.argv[1:]:
    t=int(t,16); hits=[]
    for i in range(len(rom)-4):
        op=rom[i]; p=B+i
        if 0x60<=op<=0x6f:
            d=rom[i+1]; d=d-256 if d>127 else d
            if p+2+d==t: hits.append((hex(p),'jr',op))
        elif 0x70<=op<=0x7f:
            d=rom[i+1]|rom[i+2]<<8; d=d-65536 if d>32767 else d
            if p+3+d==t: hits.append((hex(p),'jrl',op))
        elif op==0x1e:
            d=rom[i+1]|rom[i+2]<<8; d=d-65536 if d>32767 else d
            if p+3+d==t: hits.append((hex(p),'calr'))
        elif op in (0x1b,0x1d):
            a=rom[i+1]|rom[i+2]<<8|rom[i+3]<<16
            if a==t: hits.append((hex(p),'jp' if op==0x1b else 'call'))
    print(hex(t),hits)
