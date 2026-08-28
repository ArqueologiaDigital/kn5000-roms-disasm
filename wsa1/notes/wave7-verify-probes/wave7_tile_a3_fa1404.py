S="""FA1404 FA146F code
FA146F FA148B pointer_table
FA148B FA15E8 code
FA15E8 FA15EE index_map
FA15EE FA1690 bit_table
FA1690 FA16EC pointer_table
FA16EC FA1712 index_map
FA1712 FA17CA pointer_table
FA17CA FA17CF index_map
FA17CF FA182B pointer_table
FA182B FA182F index_map
FA182F FA188B pointer_table
FA188B FA1892 index_map
FA1892 FA1A5E pointer_table
FA1A5E FA1A82 index_map
FA1A82 FA1B63 bit_table
FA1B63 FA1B75 index_map
FA1B75 FA1B7E bit_table
FA1B7E FA1B82 index_map
FA1B82 FA1B94 bit_table
FA1B94 FA1C4C pointer_table
FA1C4C FA1CAB index_map
FA1CAB FA1D07 pointer_table
FA1D07 FA1D10 index_map
FA1D10 FA1DC8 pointer_table
FA1DC8 FA1DE1 index_map
FA1DE1 FA1E49 pointer_table
FA1E49 FA1E52 bit_table
FA1E52 FA1E64 index_map
FA1E64 FA1ECD bit_table
FA1ECD FA1EDF index_map
FA1EDF FA1F21 bit_table
FA1F21 FA2216 display_list
FA2216 FA22C0 ascii
FA22C0 FA2469 display_list
FA2469 FA2479 ascii
FA2479 FA2BC1 display_list
FA2BC1 FA2D45 ascii
FA2D45 FA33CF display_list
FA33CF FA348D ascii
FA348D FA38F4 display_list
FA38F4 FA3954 ascii
FA3954 FA3A6C display_list
FA3A6C FA3A9C ascii
FA3A9C FA3CD4 display_list
FA3CD4 FA3D34 ascii
FA3D34 FA4075 display_list
FA4075 FA408D ascii
FA408D FA4487 display_list
FA4487 FA44E8 ascii
FA44E8 FA4B33 display_list
FA4B33 FA4B9F ascii
FA4B9F FA4E58 display_list
FA4E58 FA4E60 ascii
FA4E60 FA4EB5 display_list
FA4EB5 FA5369 code
FA5369 FA5400 pad"""
segs=[(int(a,16),int(b,16),c) for a,b,c in (l.split() for l in S.strip().splitlines())]
LO,HI=0xFA1404,0xFA5400
print("dossier segments:",len(segs))
cur=LO; bad=0
for lo,hi,k in segs:
    if lo!=cur: print("  DISCONTINUITY at 0x%06X: expected 0x%06X"%(lo,cur)); bad+=1
    if hi<=lo: print("  NON-POSITIVE length 0x%06X-0x%06X"%(lo,hi)); bad+=1
    cur=hi
print("last end 0x%06X want 0x%06X"%(cur,HI))
print("sum:",sum(h-l for l,h,_ in segs),"want",HI-LO)
print("discontinuities:",bad)
# cross-check every dossier boundary is a boundary in the script's fine output
import re
pat=re.compile(r'^\s+(\S+)\s+0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+(\d+)\b')
fb=set()
for l in open('/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/fine_objs.txt'):
    m=pat.match(l)
    if m: fb.add(int(m.group(2),16)); fb.add(int(m.group(3),16))
miss=[hex(l) for l,h,_ in segs if l not in fb]
print("dossier boundaries NOT a script boundary:",miss)
# per-segment: check kinds roughly agree by counting script objects inside
