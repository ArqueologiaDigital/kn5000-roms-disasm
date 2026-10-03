#!/usr/bin/env python3
"""Post-edit of the CMPNCP item-table reframe (cmpncp_itemhandlers_<tree>.json), v10/v9."""
import os, sys
tree = sys.argv[1]
p = "%s/maincpu/sequencer/accompaniment_engine.s" % tree
L = open(p, "rb").read().decode("latin-1").split("\n")
t = L.index("CmpNcp_ItemHandlerTable:")
# 1. the table comment: rewrite, and drop the carried misframing note
old_hdr = L[t + 1:t + 6]
assert old_hdr[0].startswith("\t; DrumVoice_Handler7_Data_3_Helper5 calls entry"), old_hdr
new_hdr = [
    "\t; DrumVoice_Handler7_Data_3_Helper5 calls entry (HL & 7).  DrumVoice_Handler7_Data_3_Helper2",
    "\t; and _Helper4 pass 0..4 from the two tables above; the wrapper just before",
    "\t; DrumVoice_Handler7_Data_3_Helper5 passes its caller's HL.  5 and 6 are DrumVoice_NullHandler;",
    "\t; an index of 7 would read the first four bytes of CmpNcp_ItemHandler0.  Each handler sets bits",
    "\t; of (0xE3E2) and stores its own word in (0xE3E4): 0x0080, 0x0181, 0x0282, 0x8505, 0x0686.",
    "\t; This table and the five handlers were decoded as code (`jrl ule, ...`, `.byte 0xc1, 0xe2,",
    "\t; 0xe3 / push xiz` ...) until 2026-10-03.",
]
L[t + 1:t + 6] = new_hdr
gone = ["\t; data, not code: part of the 4-byte pointer table",
        "\t; misframed around it (LE .long 0x00f656xx). Was spelled",
        "\t; `div8rr h, e`, a byte divide whose even register field",
        "\t; names no result pair (MAME: div ??,E) -- no spelling."]
for g in gone:
    k = L.index(g, t)
    assert k < t + 30, (g, k)
    del L[k]
# 2. title operands and the handlers' words, inside the reframed span only
lo = max(i for i in range(t) if L[i] == "DrumVoice_Handler4_Return:")
hi = L.index("DrumVoice_Handler6_Helper:", t)
TITLES = {"(0x8d37:16)": "(PREVIOUS_TITLE:16)", "(0x8d36:16)": "(CURRENT_TITLE:16)",
          "(0x8d39:16)": "(ACTIVE_TITLE_PREVIOUS:16)"}
IDS = {184: "TT_CMPNCP", 187: "TT_CMBEND", 189: "TT_CMMODE"}
WORDS = {"128": "0x0080", "385": "0x0181", "642": "0x0282", "1670": "0x0686"}
n_t = n_w = 0
h0 = L.index("CmpNcp_ItemHandler0:", t)
h_end = L.index("\tret", L.index("CmpNcp_ItemHandler4:", t))
for i in range(lo, hi):
    for a, b in TITLES.items():
        if L[i].startswith("\tcp\t" + a + ", "):
            v = int(L[i].split(", ")[1])
            L[i] = "\tcp\t%s, %d\t; %s" % (b, v, IDS[v])
            n_t += 1
    if h0 < i < h_end and L[i].startswith("\tldw\t(0xe3e4:16), "):
        v = L[i].split(", ")[1]
        if v in WORDS:
            L[i] = "\tldw\t(0xe3e4:16), " + WORDS[v]
            n_w += 1
print(tree, "title operands", n_t, "words", n_w)
assert (n_t, n_w) == (5, 4), (n_t, n_w)
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
