import re
rom=open('/home/fsanches/compartilhado/kn5000-roms-disasm/original_ROMs/kn5000_subprogram_v142.rom','rb').read()
BASE=0x0EF00
txt=open('/tmp/claude-1000/-home-fsanches-compartilhado-kn5000-roms-disasm/53b889a2-7a91-44a2-993e-a73c39d83e0d/scratchpad/verify/v142.txt').read()
for m in re.finditer(r'### SITE (\d+): (\S+)\s+src_addr=0x([0-9A-F]+)\s+target=0x([0-9A-F]+)\s+proposed_label=(\S+)',txt):
    n,loc,src,tgt,lab=m.groups(); src=int(src,16); tgt=int(tgt,16)
    b=rom[src-BASE:src-BASE+4]
    op=b[0]
    if 0x60<=op<=0x6f:
        d=b[1]; d=d-256 if d>127 else d; t=src+2+d; kind='jr'
    elif 0x70<=op<=0x7f:
        d=b[1]|b[2]<<8; d=d-65536 if d>32767 else d; t=src+3+d; kind='jrl'
    elif op==0x1e:
        d=b[1]|b[2]<<8; d=d-65536 if d>32767 else d; t=src+3+d; kind='calr'
    elif op in (0x1d,0x1b):
        t=b[1]|b[2]<<8|b[3]<<16; kind='call' if op==0x1d else 'jp'
    else:
        t=None; kind='??'
    print(n, kind, hex(src), hex(tgt), 'OK' if t==tgt else 'MISMATCH %s'%(hex(t) if t is not None else None), b.hex(), lab)
