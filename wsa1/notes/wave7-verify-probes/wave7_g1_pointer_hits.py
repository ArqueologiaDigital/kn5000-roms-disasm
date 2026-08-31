BASE=0xF80000
rom=open('/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/wsa1_prom_c.ic28','rb').read()
def scan(pat,label):
    hits=[];i=0
    while True:
        i=rom.find(pat,i)
        if i<0:break
        hits.append(BASE+i);i+=1
    print("%-42s %d hits: %s"%(label,len(hits),' '.join('0x%06X'%h for h in hits)))
    return hits
# callers of sub_FC7FCA : call addr24 = 1d ca 7f fc
scan(bytes.fromhex('1dca7ffc'),'call 0xFC7FCA (1d ca 7f fc)')
# 32-bit immediate 0x0000D75E (staging struct base) anywhere
scan(bytes.fromhex('5ed70000'),'imm32 0x0000D75E')
# 3-byte 0x00D75E
scan(bytes.fromhex('5ed700'),'operand 0x00D75E (3-byte)')
