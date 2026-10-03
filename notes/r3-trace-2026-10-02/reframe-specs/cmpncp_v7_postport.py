#!/usr/bin/env python3
"""After port_islands.py put v10's CMPNCP block onto v7's DrumVoice_Handler7 romslice:
name the two tables v10 names, and re-state the carried [v10] comments with v7's RAM addresses."""
import os
p = "v7/maincpu/sequencer/accompaniment_engine.s"
L = open(p, "rb").read().decode("latin-1").split("\n")
a = L.index("DrumVoice_Handler7:")
b = L.index("DrumVoice_NotifyEE:", a)
def one(text):
    ks = [i for i in range(a, b) if L[i] == text]
    assert len(ks) == 1, (text, ks)
    return ks[0]
# 1. CmpNcp_ProgramGroupBase
L[one("\tld\txix, 0xf6518e")] = "\tld\txix, CmpNcp_ProgramGroupBase"
k = one("\t.byte\t0x80, 0x80, 0x80, 0x80, 0x84, 0x84, 0x84, 0x84")
assert L[k + 1] == "\t.byte\t0x88, 0x88, 0x88, 0x88"
L[k:k + 2] = ["CmpNcp_ProgramGroupBase:",
              "\t; (0xFC5A) & 0x7F -> the first program of its group of four: 0x81..0x83 -> 0x80, 0x85..0x87 ->",
              "\t; 0x84, 0x89..0x8B -> 0x88.  DrumVoice_Handler7_Code_Helper returns before the lookup for",
              "\t; values below 0x80 and for 0x80, 0x84 and 0x88 themselves.",
              "\t.byte\t0x80, 0x80, 0x80, 0x80, 0x84, 0x84, 0x84, 0x84, 0x88, 0x88, 0x88, 0x88"]
# 2. CmpNcp_ItemHandlerTable
L[one("\tadd\txhl, 0xf65253")] = "\tadd\txhl, CmpNcp_ItemHandlerTable"
k = one("\t.byte\t0x6f, 0x52, 0xf6, 0x00")
assert L[k + 1:k + 5] == ["\t.long\tCmpNcp_ItemHandler1",
                          "\t.byte\t0xa6, 0x52, 0xf6, 0x00, 0xba, 0x52, 0xf6, 0x00",
                          "\t.byte\t0xc9, 0x52, 0xf6, 0x00, 0xf3, 0x4e, 0xf6, 0x00",
                          "\t.byte\t0xf3, 0x4e, 0xf6, 0x00"], L[k + 1:k + 5]
L[k:k + 5] = ["CmpNcp_ItemHandlerTable:",
              "\t; DrumVoice_Handler7_Data_3_Helper5 calls entry (HL & 7).  DrumVoice_Handler7_Data_3_Helper2",
              "\t; and _Helper4 pass 0..4 from the two tables above; the wrapper just before",
              "\t; DrumVoice_Handler7_Data_3_Helper5 passes its caller's HL.  5 and 6 are DrumVoice_NullHandler;",
              "\t; an index of 7 would read the first four bytes of CmpNcp_ItemHandler0.  Each handler sets bits",
              "\t; of (0xE31C) and stores its own word in (0xE31E): 0x0080, 0x0181, 0x0282, 0x8505, 0x0686.",
              "\t.long\tCmpNcp_ItemHandler0",
              "\t.long\tCmpNcp_ItemHandler1",
              "\t.long\tCmpNcp_ItemHandler2",
              "\t.long\tCmpNcp_ItemHandler3",
              "\t.long\tCmpNcp_ItemHandler4",
              "\t.long\tDrumVoice_NullHandler",
              "\t.long\tDrumVoice_NullHandler"]
b = L.index("DrumVoice_NotifyEE:", a)
# 3. the carried comments
REPL = {
 "; [v10] (0x39A7), stepped between 0 and 2 by DrumVoice_Handler7_Data_3_Helper -> the":
 "\t; (0x390B), stepped between 0 and 2 by DrumVoice_Handler7_Data_3_Helper -> the",
 "; [v10] CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper2 dispatches.":
 "\t; CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper2 dispatches.",
 "; [v10] Reached through CmpNcpTtl_Dispatch2_Helper / _Helper2.":
 "\t; Reached through CmpNcpTtl_Dispatch2_Helper / _Helper2.",
 "; [v10] (0x39A8), stepped between 0 and 1 by DrumVoice_Handler7_Data_3_Helper3 -> the":
 "\t; (0x390C), stepped between 0 and 1 by DrumVoice_Handler7_Data_3_Helper3 -> the",
 "; [v10] CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper4 dispatches.":
 "\t; CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper4 dispatches.",
 "; [v10] Reached through CmpNcpTtl_Dispatch2_Helper3.":
 "\t; Reached through CmpNcpTtl_Dispatch2_Helper3.",
}
n = 0
for i in range(a, b):
    if L[i] in REPL:
        L[i] = REPL[L[i]]; n += 1
    elif "\t; [v10] TT_" in L[i]:
        L[i] = L[i].replace("\t; [v10] TT_", "\t; TT_"); n += 1
assert n == 11, n
assert not any("[v10]" in L[i] for i in range(a, b))
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
print("ok", n)
