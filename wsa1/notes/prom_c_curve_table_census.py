#!/usr/bin/env python3
"""prom_c CURVE-TABLE CENSUS -- which routines read which voice curve, and which
0x0010C000 staging word do those routines write?

WHAT QUESTION THIS ANSWERS
--------------------------
Gap **A** wants a 0x0010C000 register NAMED.  The lever used in round 2 is that prom_c's
voice curves already carry names (transplanted from the KN5000 sub-CPU, byte-identical),
so following a curve to the register it ends up in transfers the name.  That only works if
the correspondence is a BIJECTION rather than an overlap, so this script prints both sides
and lets the reader check:

  * for each named curve, every routine in prom_c that computes its address, and
  * for each of the ten staging words 12..21 (registers 0x0800..0x0A40 of one channel),
    every routine that stores into it.

THE RESULT THIS WAS WRITTEN FOR
    Voice_LevelPair_AttackCurve has 4 reference sites in 4 routines.
    Staging word 12 -- register 0x0800 + chan -- has 4 store sites in the SAME 4 routines.
    Nothing else reads that curve and nothing else writes that word.
    Voice_EnvelopeLevel_Curve is read 6 times each by Voice_StageRegs_0900_0940_0980_AB and Voice_StageRegs_09C0_0A00_0A40_AB, which are
    the only writers of words 16-18 and 19-21 respectively.

⚠ WHAT THIS IS.  A scan of the gate-certified listing `prom_c/wsa1_prom_c.s` for the
table base as an instruction immediate, plus a scan for stores to the staging words.  It
is an ADDRESS-COMPUTATION census, not a dataflow: a routine that computes a table address
and then does not use it would still be counted.  The per-site readings the finding rests
on were done by hand and are cited in notes/FINDINGS-prom_c-voice-readback.md §8.

⚠ It names no register.  It reports correspondences.

USAGE
    python3 notes/prom_c_curve_table_census.py
    python3 notes/prom_c_curve_table_census.py --selftest   # assert the counts above
"""
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
INSN = re.compile(r";\s([0-9A-F]{6})\s\s(.+?)\s*$")
HDR = re.compile(r"^;\s*(?:★+\s*)?([A-Za-z_][A-Za-z_0-9]*)\s+--\s+0x([0-9A-F]{6})\.\.0x([0-9A-F]{6})")

CURVES = {0xFDEF74: "Voice_LevelPair_AttackCurve",
          0xFDEFD9: "Voice_EnvelopeLevel_Curve",
          0xFDF03E: "Voice_EnvelopeRate_Table",
          0xFDF0A3: "Ramp_0_to_100_Curve",
          0xFDF123: "Detune_Scale_Curve"}
WORD_OF_SLOT = {0xD776: 12, 0xD778: 13, 0xD77A: 14, 0xD77C: 15, 0xD77E: 16,
                0xD780: 17, 0xD782: 18, 0xD784: 19, 0xD786: 20, 0xD788: 21}
REG_OF_WORD = {12: 0x0800, 13: 0x0840, 14: 0x0880, 15: 0x08C0, 16: 0x0900,
               17: 0x0940, 18: 0x0980, 19: 0x09C0, 20: 0x0A00, 21: 0x0A40}

seq, routines = [], []
for line in open(SRC, encoding="utf-8"):
    line = line.rstrip("\n")
    h = HDR.match(line)
    if h:
        routines.append((int(h.group(2), 16), int(h.group(3), 16), h.group(1)))
    m = INSN.search(line)
    if m:
        seq.append((int(m.group(1), 16), m.group(2)))
routines.sort()


def owner(addr):
    for lo, hi, name in routines:
        if lo <= addr <= hi:
            return name
    return "?"


curve_hits = defaultdict(list)
store_hits = defaultdict(list)
for addr, text in seq:
    low = text.lower()
    for base, name in CURVES.items():
        if f"{base:06x}" in low:
            curve_hits[name].append((addr, owner(addr)))
    m = re.match(r"ld \(0x00d7([0-9a-f]{2})\),(\S+)", text)
    if m and (0xD700 | int(m.group(1), 16)) in WORD_OF_SLOT and not m.group(2).startswith("0x"):
        store_hits[WORD_OF_SLOT[0xD700 | int(m.group(1), 16)]].append((addr, owner(addr)))

print("CURVE -> the routines that compute its address")
for base, name in CURVES.items():
    hits = curve_hits[name]
    by = defaultdict(list)
    for a, o in hits:
        by[o].append(a)
    print(f"  {name} (0x{base:06X}): {len(hits)} site(s), {len(by)} routine(s)")
    for o in sorted(by):
        print(f"      {o:<28} {' '.join(f'0x{a:06X}' for a in by[o])}")

print()
print("STAGING WORD -> the routines that store a computed value into it")
for w in sorted(store_hits):
    by = defaultdict(list)
    for a, o in store_hits[w]:
        by[o].append(a)
    print(f"  word {w:2d} = register 0x{REG_OF_WORD[w]:04X} + chan: "
          f"{len(store_hits[w])} store(s), {len(by)} routine(s)")
    for o in sorted(by):
        print(f"      {o:<28} {' '.join(f'0x{a:06X}' for a in by[o])}")

if "--selftest" in sys.argv:
    atk = {o for _, o in curve_hits["Voice_LevelPair_AttackCurve"]}
    w12 = {o for _, o in store_hits[12]}
    lvl = defaultdict(int)
    for _, o in curve_hits["Voice_EnvelopeLevel_Curve"]:
        lvl[o] += 1
    ok = (len(curve_hits["Voice_LevelPair_AttackCurve"]) == 4
          and atk == w12
          and atk == {"Voice_StageRegs_0800_A", "Voice_StageRegs_0800_CD", "Voice_StageRegs_0800_B_ModeLt3", "Voice_StageRegs_0800_B_ModeGe3"}
          and lvl["Voice_StageRegs_0900_0940_0980_AB"] == 6 and lvl["Voice_StageRegs_09C0_0A00_0A40_AB"] == 6
          and {o for _, o in store_hits[16]} == {"Voice_StageRegs_0900_0940_0980_AB"}
          and {o for _, o in store_hits[21]} == {"Voice_StageRegs_09C0_0A00_0A40_AB"})
    print()
    print(f"selftest: attack-curve readers {sorted(atk)}")
    print(f"selftest: word-12 writers      {sorted(w12)}")
    print(f"selftest: EnvelopeLevel_Curve lookups -- Voice_StageRegs_0900_0940_0980_AB {lvl['Voice_StageRegs_0900_0940_0980_AB']}, "
          f"Voice_StageRegs_09C0_0A00_0A40_AB {lvl['Voice_StageRegs_09C0_0A00_0A40_AB']}")
    print(f"selftest: LAST word (21) writers {sorted({o for _, o in store_hits[21]})}")
    print("selftest: OK" if ok else "selftest: FAILED")
    sys.exit(0 if ok else 1)
