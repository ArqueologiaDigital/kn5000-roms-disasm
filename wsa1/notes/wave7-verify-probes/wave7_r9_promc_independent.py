"""Independent re-derivation of the three quantified claims in the round-9 prom_c prose:
(1) exactly 13 24-bit LE occurrences of 0x00E005/0x00E006 in the raw prom_c image;
(2) the NotePool8 staging image differs from the reset image in 9 of 68 bytes / 8 of 34 words;
(3) the level caps' distance below 0x0FF4 and the dB figures quoted."""
import math
D=open('/home/fsanches/compartilhado/wsa1-roms-disasm/original_ROMs/wsa1_prom_c.ic28','rb').read()
BASE=0xF80000
# (1)
hits=[]
for a in (0xE005,0xE006):
    pat=bytes([a&0xFF,(a>>8)&0xFF,0x00]); i=0
    while True:
        i=D.find(pat,i)
        if i<0: break
        hits.append((BASE+i,a)); i+=1
print("(1) 24-bit LE occurrences: %d total; E005=%d E006=%d"%(len(hits),
      sum(1 for _,a in hits if a==0xE005), sum(1 for _,a in hits if a==0xE006)))
print("    address span %06X..%06X ; all inside 0xFC3E02..0xFC3FAD: %s"%(
      min(h for h,_ in hits), max(h for h,_ in hits),
      all(0xFC3E02<=h<=0xFC3FAD for h,_ in hits)))
# (2)
def words(a,n=34): 
    o=a-BASE; return [D[o+2*i]|(D[o+2*i+1]<<8) for i in range(n)]
R=words(0xFE12CF); P=words(0xFE1540)
dw=[(i,R[i],P[i]) for i in range(34) if R[i]!=P[i]]
db=sum(1 for i in range(68) if D[0xFE12CF-BASE+i]!=D[0xFE1540-BASE+i])
print("(2) differing words %d, differing bytes %d"%(len(dw),db))
for i,r,p in dw: print("      word %2d  %04X -> %04X"%(i,r,p))
# (3)
caps=words(0xFE158B,7); top=0x0FF4
print("(3) caps:", ' '.join('%04X'%c for c in caps))
for c in sorted(set(caps)):
    d=top-c; print("      %04X: %d counts below 0x0FF4 -> %.1f dB at 256 counts/octave"%(c,d,d/256*20*math.log10(2)))
