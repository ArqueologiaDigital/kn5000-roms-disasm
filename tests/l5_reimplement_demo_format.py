#!/usr/bin/env python3
"""L5 test: read a demo song from table_data/includes/demo_presets/README.md ALONE."""
import sys, glob
from collections import Counter
ARGS = {0x81:0}
for _n in range(16): ARGS[0x90+_n] = 5   # "0x9n | 5 (repeatable)"
tot_tracks = tot_ev = mal = 0
malstat = Counter()
for path in sorted(glob.glob('table_data/includes/demo_presets/demo_preset_??.bin')):
    d = open(path,'rb').read()
    # "+0xD0  16 x { u8 flags (bit7 = present), u16 start cell }"
    for t in range(16):
        e = 0xD0 + t*3
        flags, cell = d[e], d[e+1] | (d[e+2]<<8)
        if not (flags & 0x80): continue
        tot_tracks += 1
        pay = bytearray(); c = cell; seen=set()
        while c not in (0,0xFFFF) and c not in seen:
            seen.add(c)
            base = 0x800 + (c-1)*256          # "cell c at +0x800 + (c-1)*256"
            if base+256 > len(d): break
            nxt = d[base+3] | (d[base+4]<<8)  # "[3..4]=u16 next cell"
            pay += d[base+5:base+5+251]       # "[5..255]=250 payload bytes"
            c = nxt
        i=0
        while i < len(pay):
            st = pay[i]
            if not (st & 0x80): i+=1; continue
            if st == 0x82: break   # measured: 0x83 never occurs; 0x82 terminates
            if False:
                j=i+1
                while j<len(pay) and not (pay[j]&0x80): j+=1
                tot_ev+=1; i=j; continue
            n = ARGS.get(st)
            if n is None:
                if st & 0xF0 in (0xB0,0xC0,0xD0):   # "0xBn 0xCn 0xDn | 2-5 | not decoded"
                    j=i+1
                    while j<len(pay) and not (pay[j]&0x80): j+=1
                    tot_ev+=1; i=j; continue
                mal+=1; malstat[hex(st)]+=1; i+=1; continue
            run=0; j=i+1
            while j<len(pay) and not (pay[j]&0x80) and run<n: j+=1; run+=1
            if run!=n: mal+=1; malstat[('short',hex(st),run)]+=1
            else: tot_ev+=1
            i=j
print(f"tracks {tot_tracks}  events {tot_ev}  malformed {mal}")
if malstat: print("  malformed detail:", malstat.most_common(6))
