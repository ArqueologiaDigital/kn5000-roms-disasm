#!/usr/bin/env python3
"""Do the two committed 0x41A claims contradict each other?

docs/IS-IT-DONE.md carries both:

  (A) the RETRACTION: the displaced-labels detector is wrong, because the ROM's
      own pointer tables point at the labels' ORIGINAL addresses -- 11 of 11
      contradict the detector, each broken word showing ROM - built = 0x41A.

  (B) the 153: "153 v7 names sit on the wrong routine, 152 off by exactly 0x41A
      ... byte agreement decides it 153/153 in favour of the pointer table's
      target."

(A) says the current addresses are right. (B) says 153 of them are wrong by the
same 0x41A. Both cannot be true of the same names.

THE TEST, using the evidence (A) itself calls decisive -- a pointer the firmware
dereferences: for each named routine, does any 32-bit word in the ROM equal its
CURRENT address, or its address MINUS 0x41A, or PLUS 0x41A?

  * current-address hits dominant  -> (A) is right and (B) does not apply to
    these names as the tree stands;
  * shifted hits dominant          -> (B) is right and names are still misplaced.

⚠ A word equal to an address is only evidence if such words are RARE. The
control counts, for the same symbols, how often a random ROM-range address
appears as a 32-bit word -- if that rate is high, matches mean nothing.

Run:  python3 tools/spelling-probes/check_0x41A_contradiction.py
"""
import importlib.util, os, random, struct, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
SHIFT = 0x41A

_c = importlib.util.spec_from_file_location(
    "cc", os.path.join(REPO, "scripts/converters/convert_corroborated_blocks.py"))
cc = importlib.util.module_from_spec(_c); _c.loader.exec_module(cc)

rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")

words = set()
for i in range(0, len(rom) - 3):
    words.add(struct.unpack("<I", rom[i:i + 4])[0])

PREFIX = ("SndParam_", "MidiPkt_", "UIState_", "SoundFX_Handler_",
          "HdaeRom_", "CharMap_")
cand = [(a, n) for a, n in syms.items() if n.startswith(PREFIX)]
cur = sum(1 for a, _n in cand if a in words)
lo = sum(1 for a, _n in cand if (a - SHIFT) in words)
hi = sum(1 for a, _n in cand if (a + SHIFT) in words)

rng = random.Random(41)
ctrl = sum(1 for _ in range(len(cand)) if rng.randrange(0xE00000, 0x1000000) in words)

print(f"  symbols in the six named families : {len(cand)}")
print()
print(f"  address appears as a 32-bit word in the ROM:")
print(f"      at its CURRENT address        : {cur:5}  ({100*cur/len(cand):.1f}%)")
print(f"      at address - 0x41A            : {lo:5}  ({100*lo/len(cand):.1f}%)")
print(f"      at address + 0x41A            : {hi:5}  ({100*hi/len(cand):.1f}%)")
print(f"  CONTROL, random ROM-range address : {ctrl:5}  ({100*ctrl/len(cand):.1f}%)")
print()
if cur > max(lo, hi) * 2 and cur > ctrl * 2:
    print("  => CURRENT addresses dominate. Claim (A) holds; the tree's names are")
    print("     where the firmware's own pointers say they should be.")
elif max(lo, hi) > cur * 2:
    print("  => SHIFTED addresses dominate. Claim (B) holds; names are misplaced.")
else:
    print("  => NEITHER dominates. The test does not separate them, and saying")
    print("     which claim is right would be going beyond this evidence.")
