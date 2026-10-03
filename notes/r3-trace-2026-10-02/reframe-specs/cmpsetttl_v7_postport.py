#!/usr/bin/env python3
"""After port_islands.py put v10's TimeSig/CmpSetTtl text on v7 0xF65CD2 (island) and 0xF67B89 (--whole):
label the two offset tables, name the numeric references to them and to S2cTtl_InitOnTitleChange,
restate the carried [v10] comments with v7's RAM, drop the unreferenced mid-body CmpSetTtl_Dispatch2_Code.
v7 RAM: v10 0x39AA = v7 0x390E; v10 0x3989/0x398A..0x3995 = v7 0x38ED/0x38EE..0x38F9."""
import os
p = "v7/maincpu/sequencer/accompaniment_engine.s"
L = open(p, "rb").read().decode("latin-1").split("\n")
def one(t, lo=0):
    ks = [i for i in range(lo, len(L)) if L[i] == t]
    assert len(ks) == 1, (t, ks)
    return ks[0]
assert 0xF65DA5 == 16145829 and 0xF65DE7 == 16145895
L[one("\tld\txix, 0xf65da5")] = "\tld\txix, TimeSig_SlotEntryByte2Offsets"
L[one("\tld\txix, 0xf65de3")] = "\tld\txix, TimeSig_SlotFieldOffsets"
L[one("\tcall\t16145895")] = "\tcall\tS2cTtl_InitOnTitleChange"
k = one("\t.byte\t0x22, 0x2a, 0x32, 0x3a")
L[k:k + 1] = ["TimeSig_SlotEntryByte2Offsets:",
              "\t; Offsets in the current slot record (AccPatch_GetCurrentSlotAddr) of byte +2 of its four 8-byte",
              "\t; entries, indexed by (0x390E); TimeSig_SlotFieldOffsets are the same entries' byte +5.",
              "\t; TimeSig_DisplayStrings_Helper5 steps the byte within 0..127.",
              "\t.byte\t34, 42, 50, 58"]
k = one("\t.byte\t0x25, 0x2d, 0x35, 0x3d")
L[k:k + 1] = ["; TimeSig_SlotFieldOffsets -- offsets into the current slot record (AccPatch_GetCurrentSlotAddr), indexed by (0x390E)",
              "TimeSig_SlotFieldOffsets:\t.byte\t37, 45, 53, 61"]
k = one("S2cTtl_InitOnTitleChange:")
assert all(x.startswith("; [v10] ") for x in L[k + 1:k + 4]), L[k + 1:k + 4]
L[k + 1:k + 4] = []
L[k:k] = ["; S2cTtl_InitOnTitleChange -- when CURRENT_TITLE differs from PREVIOUS_TITLE: (0x38ED) := (0xFFE3) + 1, and if (0x38EE)",
          ";          is 0, seed 0x38EE-0x38F9.  Called from S2cTtl_Dispatch.  Was part of a `.byte` run until 2026-10-03."]
k = one("CmpSetTtl_Dispatch2_Code:")
del L[k]
k = one("CmpSetTtl_Dispatch2:")
hdr = L[k + 1:k + 6]
assert hdr[0] == "; [v10] CmpSetTtlFunc title dispatch 2" and all(x.startswith("; [v10] ") for x in hdr), hdr
L[k + 1:k + 6] = [
 "\t; Six 16-byte case bodies, CmpSetTtl_Dispatch2 + CmpSetTtl_DynamicLookup_CaseTable[k]: save XDE/XHL/",
 "\t; XIX/XIZ, W := 0x00 (up) or 0x80 (down), call the stepper of the entry index (0x390E), of",
 "\t; entry byte +2 or of entry byte +5, restore, return 0 (CmpReal_ReturnZero).  The first body",
 "\t; is entry-index-up.  Were spelled partly as text (\":;<> \") and with numeric calls."]
left = [i + 1 for i, x in enumerate(L) if "[v10]" in x]
print("left [v10] lines:", left)
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
