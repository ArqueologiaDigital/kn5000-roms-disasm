#!/usr/bin/env python3
"""After cmpncp_itemsteps_<tree>.json: label CmpNcp_ItemStep4 (the span's end boundary) and head the five
step routines with their caller.  Usage: cmpncp_steps_postedit.py v10|v9|v7"""
import os, sys
tree = sys.argv[1]
p = "%s/maincpu/sequencer/accompaniment_engine.s" % tree
L = open(p, "rb").read().decode("latin-1").split("\n")
# CmpNcp_ItemStep4: the first instruction after TimeSig_DisplayStrings_Code_Return3's ret
k = L.index("TimeSig_DisplayStrings_Code_Return3:")
assert L[k + 1] == "\tret" and L[k + 2].startswith("\tld\ta, ("), L[k:k + 3]
L.insert(k + 2, "CmpNcp_ItemStep4:")
HDR = {
 "CmpNcp_ItemStep0": "; Called by CmpNcp_ItemHandler0.  Bit 7 of W set = step down, clear = step up.",
 "CmpNcp_ItemStep1": "; Called by CmpNcp_ItemHandler1.  Bit 7 of W set = step down, clear = step up.",
 "CmpNcp_ItemStep2": "; Called by CmpNcp_ItemHandler2.  Bit 7 of W set = step down, clear = step up.",
 "CmpNcp_ItemStep3": "; Called by CmpNcp_ItemHandler3.  Bit 7 of W set = step down, clear = step up.",
 "CmpNcp_ItemStep4": "; Called by CmpNcp_ItemHandler4.  Steps (0x34D6) through one of three helpers chosen by bits 4/5 of (0x34CD).",
}
n = 0
for name, h in HDR.items():
    i = L.index(name + ":")
    L.insert(i, h)
    n += 1
assert n == 5
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
print(tree, "ok")
