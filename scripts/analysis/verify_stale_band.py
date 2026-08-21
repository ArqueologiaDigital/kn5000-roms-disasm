#!/usr/bin/env python3
"""Q: what is the 'unreferenced residue' at table_data 0x981570-0x985FFF?
A: it is the live help-database region written 0x8000 (32 KB) LOWER -- one
   single stale duplicate, not three separate mysteries.
Run: python3 verify_stale_band.py <kn5000_table_data.rom>"""
import sys
rom=open(sys.argv[1],'rb').read(); o=lambda x:x-0x800000
for name,lo0 in (("A: English-DB tail",0x983000),("B: German DB (stale)",0x984000)):
    lo=hi=lo0
    while rom[o(lo-1)]==rom[o(lo-1+0x8000)]: lo-=1
    while rom[o(hi)]==rom[o(hi+0x8000)]: hi+=1
    print(f"{name}: 0x{lo:06X}-0x{hi-1:06X} ({hi-lo} B) is byte-identical to 0x{lo+0x8000:06X}-0x{hi-1+0x8000:06X}")
print("only differing byte in 0x98156F-0x985FFF vs +0x8000:",
      [hex(i) for i in range(0x98156F,0x986000) if rom[o(i)]!=rom[o(i+0x8000)]])
