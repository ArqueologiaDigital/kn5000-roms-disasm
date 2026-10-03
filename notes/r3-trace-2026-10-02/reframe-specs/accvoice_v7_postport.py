#!/usr/bin/env python3
"""After the four port_islands.py --whole runs of accvoice_setupslots (v7 0xF670F8, 0xF6757F, 0xF675FB,
0xF677C5): restate the carried [v10] comments with v7's names and RAM, drop the old per-byte notes.
v7: v10 0x37C9/0x3898/0x38D1/0x34D7 = v7 0x372D/0x37FC/0x3835/0x343B; v10 AccPatch_ResolveEntryAddr_* =
v7 AccVoice_SetupSlots_DataBlock_*; v10 AccVoice_SetupSlots_ForEachSlot = v7 ..._Helper10_Helper2."""
import os
p = "v7/maincpu/sequencer/accompaniment_engine.s"
L = open(p, "rb").read().decode("latin-1").split("\n")
R = {
 "; [v10] A pattern stream that is only its end code 0x83 (RhythmVoice_WriteToBuffer stops at 0x83);":
 "\t; A pattern stream that is only its end code 0x83 (RhythmVoice_WriteToBuffer stops at 0x83);",
 "; [v10] AccPatch_ResolveEntryAddr_Helper10 stores its address in a slot of 0x3898.  Was `ld a, (xhl)`.":
 "\t; AccVoice_SetupSlots_DataBlock_Helper10 stores its address in a slot of 0x37FC.  Was `ld a, (xhl)`.",
 "; [v10] (0x37C9) := 1, then AccPatch_ResolveEntryAddr_Helper, _Helper10_Helper, _Helper2 and":
 "\t; (0x372D) := 1, then AccVoice_SetupSlots_DataBlock_Helper, _Helper10_Helper, _Helper2 and",
 "; [v10] AccVoice_SetupSlots_ForEachSlot.":
 "\t; AccVoice_SetupSlots_DataBlock_Helper10_Helper2 (v10/v9: AccVoice_SetupSlots_ForEachSlot).",
 "; [v10] The slot name the routine above copies (ldir85, BC = 16) to the slot at +64.  Was":
 "\t; The slot name the routine above copies (ldir85, BC = 16) to the slot at +64.  Was one",
 "; [v10] `aligned_string \"Easy            #\"`, which took the next instruction's 23 00 as \"#\\0\".":
 "\t; `.byte` per character, with the next instruction's 23 00 among them.",
 "; [v10] (0x38D1) := 0, then while (0x38D1) < (0x34D7) + 1: ...":
 "\t; (0x3835) := 0, then while (0x3835) < (0x343B) + 1: ...",
 "; [v10] L & 7 -> the bit AccPatch_ResolveEntryAddr_Helper16 returns; 6 and 7 share bit 6.  Was":
 "\t; L & 7 -> the bit AccVoice_SetupSlots_DataBlock_Helper16 returns; 6 and 7 share bit 6.  Was",
 "; [v10] `normal / push sr / max / ld (P4:8), 32 / ld xwa, 0xf4eb1e40`.":
 "\t; `normal / push sr / max / ld (P4:8), 32 / ld xwa, 4109049408`.",
 "; [v10] Reads the slot's stream pointer (0x3898 + 4 * index) and compares its first byte with 0x90 / 0x91.":
 "\t; Reads the slot's stream pointer (0x37FC + 4 * index) and compares its first byte with 0x90 / 0x91.",
}
n = 0
for i, l in enumerate(L):
    if l in R:
        L[i] = R[l]; n += 1
assert n == len(R), n
a = L.index("AccVoice_SlotName_Easy:")
b = L.index("AccVoice_SetupSlots_DataBlock_Helper10_Helper2:", a)
e = b + 6
gone = [i for i in range(a, e) if L[i] == "; v10 does not spell this byte either"]
assert len(gone) == 17, len(gone)   # the 16 name bytes and 23 00 carried 17 such notes
for i in reversed(gone):
    del L[i]
assert not any("[v10]" in x for x in L)
d = "\n".join(L).encode("latin-1")
with open(p + ".tmp", "wb") as fh:
    fh.write(d)
os.replace(p + ".tmp", p)
print("ok", n, len(gone))
