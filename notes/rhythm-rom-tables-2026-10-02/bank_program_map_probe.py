#!/usr/bin/env python3
"""bank_program_map_probe.py -- what VoiceParam_BankProgramWords holds, measured against the locator table.

QUESTION THIS ANSWERS
  VoiceParam_ClampAndValidate (sequencer/smf_event_processor.s) replaces a requested (H = bank,
  L = program < 0x80) by VoiceParam_BankProgramWords[H & 7][L]; VoiceAssign_Process_Return then
  uses the result as the RhythmROM_BankProgramLocators index [H][L & 0x7F].  Are the words
  (bank', program') pairs, and do they point at slots that have data (a non-zero locator)?
  Prints, per tree: the high/low byte ranges, how many of the 1,024 entries land on a slot with
  a locator, the distinct targets, identity entries per bank, and whether the table is the
  same in v10/v9/v7.

USAGE
  make all
  python3 notes/rhythm-rom-tables-2026-10-02/bank_program_map_probe.py
"""
import os
import subprocess

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ref = None
for v in ("v10", "v9", "v7"):
    syms = {l.split()[2]: int(l.split()[0], 16) for l in subprocess.run(
        [NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
        capture_output=True, text=True, check=True).stdout.splitlines()}
    rom = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
    W = syms["VoiceParam_BankProgramWords"] - 0xE00000
    LOC = syms["RhythmROM_BankProgramLocators"] - 0xE00000
    ws = [int.from_bytes(rom[W + 2 * i:W + 2 * i + 2], "little") for i in range(1024)]
    loc = lambda b, p: rom[LOC + (b * 128 + p) * 4:LOC + (b * 128 + p) * 4 + 4]
    hi = sorted(set(w >> 8 for w in ws))
    lo = (min(w & 0xff for w in ws), max(w & 0xff for w in ws))
    onloc = sum(1 for w in ws if loc(w >> 8, w & 0x7f) != b"\0\0\0\0")
    tg = set(ws)
    slots = sum(1 for b in range(8) for p in range(128) if loc(b, p) != b"\0\0\0\0")
    ident = [sum(1 for p in range(128) if ws[b * 128 + p] == (b << 8 | p)) for b in range(8)]
    empty = ["bank %d program %d -> 0x%04X" % (i >> 7, i & 127, ws[i]) for i in range(1024)
             if loc(ws[i] >> 8, ws[i] & 0x7f) == b"\0\0\0\0"]
    ref = ref or rom[W:W + 2048]
    print("%s: high bytes %s, low bytes %d..%d; %d of 1024 land on a slot with a locator (others: %s); "
          "%d distinct targets, %d of them with a locator; %d non-empty locator slots; identity per bank %s; "
          "same table as v10: %s" % (v, hi, lo[0], lo[1], onloc, empty, len(tg),
                                     sum(1 for w in tg if loc(w >> 8, w & 0x7f) != b"\0\0\0\0"), slots, ident,
                                     rom[W:W + 2048] == ref))
