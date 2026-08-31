# INDEPENDENT re-derivation of the dossier's write-site census.
# Written by lane G1 (verification), NOT by the lane under review.
import sys
BASE = 0xF80000
rom = open('/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/original_ROMs/wsa1_prom_c.ic28','rb').read()
print("rom len", len(rom), "range 0x%06X-0x%06X" % (BASE, BASE+len(rom)-1))
for word, ram in ((8,0x00D76E),(9,0x00D770),(10,0x00D772),(11,0x00D774)):
    pat = ram.to_bytes(3,'little')
    hits=[]
    i=0
    while True:
        i = rom.find(pat, i)
        if i < 0: break
        hits.append(BASE+i)
        i += 1
    print("word %2d reg 0x%04X  RAM 0x%06X  operand %s  -> %d raw occurrences" %
          (word, 0x0440+ (word-8)*0x40, ram, pat.hex(' '), len(hits)))
    for h in hits:
        off = h-BASE
        # print 4 bytes before and 8 after, to show the opcode
        print("    0x%06X  pre=%s  at=%s" % (h, rom[off-4:off].hex(' '), rom[off:off+8].hex(' ')))
