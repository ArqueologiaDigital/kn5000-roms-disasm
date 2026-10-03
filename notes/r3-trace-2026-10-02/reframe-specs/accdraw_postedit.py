#!/usr/bin/env python3
"""After accdraw_secondary_<tree>.json: drop the carried notes that described the old misframing of the two
tables (they are typed now).  Usage: accdraw_postedit.py v10|v9|v7"""
import os, sys
p = "%s/maincpu/sequencer/accompaniment_engine.s" % sys.argv[1]
L = open(p, "rb").read().decode("latin-1").split("\n")
a = L.index("AccDraw_SecondarySub_Handlers:")
b = L.index("AccDraw_SecondarySub_Handler00:", a)
GONE = ("\t; data, not code (a table of 0x00f6a6xx",
        "\t; pointers misframed as code); was `cp_spiw iz, 166`, whose",
        "\t; register byte 0xa6 names no TLCS-900 register (unidasm: rA6L+)")
out, n = [], 0
for i, l in enumerate(L):
    if a < i < b and (l in GONE or l.startswith("\t; data-as-code (v10_data_as_code_census.py, STRICT rule)")):
        n += 1
        continue
    out.append(l)
print(sys.argv[1], "removed", n)
assert n == 6, n
d = "\n".join(out).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
