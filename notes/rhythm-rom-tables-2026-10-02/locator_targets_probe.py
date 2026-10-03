#!/usr/bin/env python3
"""locator_targets_probe.py -- what the main CPU's RhythmROM_BankProgramLocators point at in the Rhythm Data ROM.

QUESTION THIS ANSWERS
  VoiceAssign_Process_Return computes xix = 0x400000 + (long at RAM 0x3277) + ((hi & 0xFF) << 16 | lo)
  from RhythmROM_BankProgramLocators[bank][program]; RhythmROM_ValidateHeader stores 0 at RAM
  0x3277 when the ROM at 0x400000 starts with the 12-byte signature 00 01 04 05 83 00 01 04 05 83
  00 01 (else 0xFFFFFFFF).  Using the corrected IC14 dump (A19/A21 swap undone), this prints how
  many locators are non-zero, their offset range and spacing, and the first bytes at each target.

USAGE
  python3 notes/rhythm-rom-tables-2026-10-02/locator_targets_probe.py [IC14_PATH]
  default IC14_PATH: ~/compartilhado/kn5000_corrected_roms/kn5000/kn5000_rhythm_data_rom.ic14
"""
import collections
import os
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ic14p = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    "~/compartilhado/kn5000_corrected_roms/kn5000/kn5000_rhythm_data_rom.ic14")
syms = {l.split()[2]: int(l.split()[0], 16) for l in subprocess.run(
    [NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")],
    capture_output=True, text=True, check=True).stdout.splitlines()}
rom = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
ic14 = open(ic14p, "rb").read()
LOC = syms["RhythmROM_BankProgramLocators"] - 0xE00000
offs = []
for i in range(1024):
    hi = int.from_bytes(rom[LOC + 4 * i:LOC + 4 * i + 2], "little")
    lo = int.from_bytes(rom[LOC + 4 * i + 2:LOC + 4 * i + 4], "little")
    if hi or lo:
        offs.append(((hi & 0xFF) << 16 | lo, i >> 7, i & 127))
ds = sorted(set(o for o, _, _ in offs))
print("IC14 %d bytes; signature at offset 0: %s" % (len(ic14), ic14[:12].hex(" ")))
print("%d non-zero locators, %d distinct offsets 0x%X-0x%X, min spacing %d, all 2 KB aligned: %s"
      % (len(offs), len(ds), ds[0], ds[-1], min(b - a for a, b in zip(ds, ds[1:])), all(o % 0x800 == 0 for o in ds)))
print("first 12 bytes at the targets:", collections.Counter(ic14[o:o + 12].hex(" ") for o in ds).most_common(3))
