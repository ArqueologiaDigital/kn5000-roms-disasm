#!/usr/bin/env python3
"""After port_islands.py --whole put v10's AccDraw_Secondary_Sub block on v7 0xF6A085-0xF6A2D5: the pointer
table as 20 .long of the (now defined) handler labels, the obsolete misframing notes dropped, [v10] comments
restated (they quote no RAM address)."""
import os
p = "v7/maincpu/sequencer/accompaniment_engine.s"
L = open(p, "rb").read().decode("latin-1").split("\n")
a = L.index("AccDraw_SecondarySub_Handlers:")
b = L.index("AccDraw_Secondary_Sub:", a)
hdr = [l for l in L[a + 1:b] if l.startswith("; [v10] ")]
assert len(hdr) == 4, hdr
L[a + 1:b] = ["\t" + l.replace("; [v10] ", "; ") for l in hdr] + \
             ["\t.long\tAccDraw_SecondarySub_Handler%02d" % i for i in range(20)]
c = L.index("AccDraw_IndexBitMask:")
d = L.index("AccDraw_SecondarySub_Handler00:", c)
out = []
for i, l in enumerate(L):
    if c < i < d and l.startswith("; [v10] "):
        l = "\t" + l.replace("; [v10] ", "; ")
    if c < i < d and l.lstrip().startswith("; data-as-code (v10_data_as_code_census.py"):
        continue
    out.append(l)
L = out
e = L.index("AccDraw_SecondarySub_Handlers:")
f = L.index("AccDraw_Secondary_Helper10:", e)
left = [l for l in L[e:f] if "[v10]" in l]
print("left [v10]:", left)
data = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(data)
os.replace(p + ".tmp", p)
