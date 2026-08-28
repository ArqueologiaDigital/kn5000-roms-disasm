# Independent tiling check, transcribed from the DOSSIER TEXT, not from the lane's script.
segs = [
 (0xF067A6,0xF067FF,"pad"),(0xF06800,0xF068B3,"record_table"),(0xF068B4,0xF06EB3,"ascii"),
 (0xF06EB4,0xF06EC3,"index_map"),(0xF06EC4,0xF06ED3,"index_map"),(0xF06ED4,0xF06EE3,"index_map"),
 (0xF06EE4,0xF06EF3,"index_map"),(0xF06EF4,0xF07133,"word_table"),(0xF07134,0xF08133,"word_table"),
 (0xF08134,0xF08333,"pointer_table"),(0xF08334,0xF08513,"record_table"),(0xF08514,0xF08CD7,"word_table"),
 (0xF08CD8,0xF097FF,"pad"),(0xF09800,0xF09B32,"code"),(0xF09B33,0xF09B3A,"word_table"),
 (0xF09B3B,0xF09B7A,"index_map"),(0xF09B7B,0xF09B9A,"pointer_table"),(0xF09B9B,0xF09E84,"code"),
 (0xF09E85,0xF09FFF,"unknown"),(0xF0A000,0xF0AE2E,"code"),(0xF0AE2F,0xF0AE5E,"pointer_table"),
 (0xF0AE5F,0xF0AEF5,"code"),(0xF0AEF6,0xF0AF25,"pointer_table"),(0xF0AF26,0xF0AFC0,"code"),
 (0xF0AFC1,0xF0AFF0,"pointer_table"),(0xF0AFF1,0xF0B09A,"code"),(0xF0B09B,0xF0B0C2,"pointer_table"),
 (0xF0B0C3,0xF0B156,"code"),(0xF0B157,0xF0B16E,"pointer_table"),(0xF0B16F,0xF0B281,"code"),
 (0xF0B282,0xF0B2B1,"pointer_table"),(0xF0B2B2,0xF0B33B,"code"),(0xF0B33C,0xF0B36B,"pointer_table"),
 (0xF0B36C,0xF0C734,"code"),
]
LO,HI=0xF067A6,0xC735+0xF00000
print("segments:",len(segs))
assert segs[0][0]==LO, "first seg start"
assert segs[-1][1]==HI-1, ("last seg end", hex(segs[-1][1]), hex(HI-1))
tot=0; bad=[]
for i,(lo,hi,k) in enumerate(segs):
    assert hi>=lo, ("inverted",hex(lo))
    tot += hi-lo+1
    if i: 
        plo,phi,_=segs[i-1]
        if lo != phi+1: bad.append((hex(phi),hex(lo)))
print("sum of lengths:",tot,"span size:",HI-LO)
print("gaps/overlaps:",bad)
assert tot==HI-LO, "TILING FAILS"
# dossier's own quoted lengths
print("data block 0xF067A6-0xF097FF =",0xF09800-0xF067A6,"(dossier says 12,378)")
print("code block 0xF09800-0xF0C734 =",0xF0C735-0xF09800,"(dossier says 12,085)")
print("moat2 0xF08CD8-0xF097FF     =",0xF09800-0xF08CD8,"(dossier says 2,856)")
print("moat1 =",0xF06800-0xF067A6,"(dossier says 90)")
# per-kind totals
from collections import Counter
c=Counter()
for lo,hi,k in segs: c[k]+=hi-lo+1
print(dict(c))
print("code total:",c["code"],"ptrtab total:",c["pointer_table"])
