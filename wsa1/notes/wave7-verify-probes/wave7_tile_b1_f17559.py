#!/usr/bin/env python3
"""Do lane B1's DOSSIER segments for prom_b 0xF17559-0xF1B3FF tile the span exactly,
and do they agree with the committed layout script?

QUESTION IT ANSWERS
    "Is the layout in the DOSSIER TEXT the same object as the layout the committed
     script prints -- and does it actually cover the span with no gap and no
     overlap?"

WHY IT IS SEPARATE FROM THE LANE'S OWN SCRIPT
    It is transcribed from the dossier PROSE, not imported from the lane's code, so
    a lane that reported one thing and computed another cannot pass both.  A tiling
    error is this project's cheapest catastrophic failure: a one-byte gap silently
    shifts every following segment, and the byte gate cannot see it because the
    region is still .incbin.

    It then cross-checks each coarse dossier segment against the FINE segments the
    committed notes/prom_b_f17559_layout.py prints, and flags any dossier segment
    whose kind is absent from the fine segmentation underneath it.

RUN
    python3 notes/wave7-verify-probes/wave7_tile_b1_f17559.py

    Silence after the "sum:" line means every dossier segment aligns with the fine
    ones and no kind disagrees.
"""
D="""F17559 F1774C ascii
F1774D F1777F display_list
F17780 F17782 unknown
F17783 F17958 ascii
F17959 F1798B display_list
F1798C F179A4 unknown
F179A5 F17A2B ascii
F17A2C F17A5E display_list
F17A5F F17A6B bit_table
F17A6C F17ADF pointer_table
F17AE0 F17BFF bitmap
F17C00 F17C58 display_list
F17C59 F17C8B bitmap
F17C8C F18065 display_list
F18066 F1814D display_list
F1814E F18289 display_list
F1828A F1854C ascii
F1854D F185FC index_map
F185FD F1881C display_list
F1881D F18A1C ascii
F18A1D F19237 display_list
F19238 F19480 ascii
F19481 F19744 display_list
F19745 F197EB display_list
F197EC F19817 ascii
F19818 F19AB2 display_list
F19AB3 F19ABE ascii
F19ABF F1A18C display_list
F1A18D F1A22C index_map
F1A22D F1A2AC ascii
F1A2AD F1A514 display_list
F1A515 F1A53E ascii
F1A53F F1A62E display_list
F1A62F F1A7AE ascii
F1A7AF F1AA7B display_list
F1AA7C F1AB09 record
F1AB0A F1AB12 pad
F1AB13 F1ACFA pointer_table
F1ACFB F1AE47 record
F1AE48 F1AE70 index_map
F1AE71 F1AE94 pointer_table
F1AE95 F1AEB4 bit_table
F1AEB5 F1AF6C pointer_table
F1AF6D F1AFA4 index_map
F1AFA5 F1B030 pointer_table
F1B031 F1B03E index_map
F1B03F F1B0CA pointer_table
F1B0CB F1B10A index_map
F1B10B F1B1A6 pointer_table
F1B1A7 F1B1AF record
F1B1B0 F1B22F pointer_table
F1B230 F1B238 index_map
F1B239 F1B3A8 pointer_table
F1B3A9 F1B3FF pad"""
rows=[(int(a,16),int(b,16),c) for a,b,c in (l.split() for l in D.splitlines())]
print("dossier segments:",len(rows))
LO,HI=0xF17559,0xF1B3FF
bad=0
if rows[0][0]!=LO: print("FATAL first lo"); bad+=1
if rows[-1][1]!=HI: print("FATAL last hi"); bad+=1
tot=0
for i,(lo,hi,k) in enumerate(rows):
    tot+=hi-lo+1
    if i and lo!=rows[i-1][1]+1: print("GAP/OVERLAP",hex(rows[i-1][1]),hex(lo)); bad+=1
print("sum:",tot,"span:",HI-LO+1,"equal:",tot==HI-LO+1,"bad:",bad)

# now cross-check kinds against the script's fine segments
import re, os, subprocess, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# Generate the fine segmentation from the COMMITTED lane script rather than from a
# scratch file, so this probe is self-contained and re-runnable.
_out = subprocess.run([sys.executable, os.path.join(ROOT, "notes", "prom_b_f17559_layout.py")],
                      capture_output=True, text=True, cwd=ROOT).stdout
fine=[]
for ln in _out.splitlines():
    m=re.match(r'\s+(\w+)\s+0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+(\d+)\s',ln)
    if m: fine.append((int(m.group(2),16),int(m.group(3),16),m.group(1)))
for lo,hi,k in rows:
    inner=[f for f in fine if f[0]>=lo and f[1]<=hi]
    covered=sum(f[1]-f[0]+1 for f in inner)
    kinds=sorted(set(f[2] for f in inner))
    ok = covered==hi-lo+1
    flag=""
    if not ok: flag=" *** NOT ALIGNED WITH FINE SEGMENTS ***"
    if k not in kinds: flag+="  <<< dossier kind %r not among fine kinds %s"%(k,kinds)
    if flag: print("%06X-%06X %-14s fine=%s%s"%(lo,hi,k,kinds,flag))
