#!/usr/bin/env python3
"""After accautoplay_modeavail_<tree>.json: drop the unreferenced label on the two padding bytes and the carried
data-as-code note.  Usage: accautoplay_postedit.py v10|v9"""
import os, sys
p = "%s/maincpu/sequencer/accompaniment_engine.s" % sys.argv[1]
L = open(p, "rb").read().decode("latin-1").split("\n")
k = L.index("AccAutoPlay_ModeAvail_Extended:")
assert L[k + 1] == "\t; padding" and L[k + 2] == "\t.byte\t0x00, 0x00", L[k:k + 3]
L[k:k + 3] = ["\t.byte\t0x00, 0x00\t; padding"]
e = L.index("AccAutoPlay_ConfigureIfPending_Return:", k)
n = [i for i in range(k, e) if L[i].startswith("\t; data-as-code (v10_data_as_code_census.py")]
assert len(n) == 1, n
del L[n[0]]
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
print(sys.argv[1], "ok")
