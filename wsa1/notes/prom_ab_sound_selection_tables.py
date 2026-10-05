#!/usr/bin/env python3
"""The panel's sound selection and the part's PROGRAM CHANGE & BANK: which prom_b table maps which way.

QUESTION IT ANSWERS
  A part's sound is stored twice (FINDINGS-prom_ab-sound-selection.md):
    * PROGRAM CHANGE & BANK -- the part record's bytes 0 (program) and 1 (bank), the Reference Guide parameter;
    * the panel selection -- the part's second record +0x1B group, +0x1C member, +0x1D bank code
      (SoundGroup_LoadSelectionFromPart copies them to SoundSel_Group / _Member / _Bank).
  prom_a converts between them through three prom_b tables of 8-word rows.  Their names said every one was
  indexed by (group, member), and prom_b's header for 0xF07134 said "do not describe any of them as a reverse
  lookup".  This script reads the ROM and checks:
    1. 0xF06EF4 (SoundCodeByGroupMember_ModeOffsetGroup), read by SoundCode_FromGroupMember_ModeOffset at
       index (group + bias) x 8 + member -- bias 0 for R1, 0x10 for R2, 0x20 for RD (0x22 in GM mode) --
       gives (program, bank) = (low byte, high byte);
    2. 0xF07134 (was SoundCodeByGroupMember_ByteGroup), read by the preset arm of SoundSel_FromProgramAndBank at
       row = program (| 0x80 when bank bit 5 is set), column = bank & 7, gives (group across R1 / R2 / RD, member)
       = (low byte, high byte), the low byte classified 0..0x0F -> R1, 0x10..0x1F -> R2 (- 0x10), 0x20 / 0x21 ->
       RD (- 0x20) as prom_a 0xFC248D does;
    3. every panel selection of R1 (16 x 8), R2 (16 x 8) and RD (2 x 8) goes through 1. and back through 2. to
       itself -- the two tables are inverses on the panel's whole domain.
  It also prints how 0xF08514 (was SoundCodeByGroupMember_SevenBitGroup, index program x 8 + bank & 7, read by
  PartSound_ToProgramChange) relates to (program, bank): it is NOT an identity and NOT the inverse of either,
  which is all this script claims about it.

RUN
  python3 notes/prom_ab_sound_selection_tables.py        # prints the counts; exit 1 if a check fails
"""
import collections
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
FORWARD, INVERSE, TX = 0xF06EF4, 0xF07134, 0xF08514
BANKS = ((0x00, 0x00, 16), (0x01, 0x10, 16), (0x20, 0x20, 2))     # bank code, bias, groups (non-GM mode)


def word(base, index):
    return struct.unpack_from("<H", B, base - 0xF00000 + index * 2)[0]


def classify(group):
    if group <= 0x0F:
        return group, 0x00
    if group <= 0x1F:
        return group - 0x10, 0x01
    if group <= 0x21:
        return group - 0x20, 0x20
    return 0, None


def main():
    total = good = 0
    for code, bias, groups in BANKS:
        for g in range(groups):
            for m in range(8):
                v = word(FORWARD, (g + bias) * 8 + m)
                program, bank = v & 0xFF, v >> 8
                row = program | 0x80 if bank & 0x20 else program
                u = word(INVERSE, row * 8 + (bank & 7))
                gg, cc = classify(u & 0xFF)
                total += 1
                good += (gg, u >> 8, cc) == (g, m, code)
    print("panel selection -> 0xF06EF4 -> (program, bank) -> 0xF07134 -> panel selection: %d of %d" % (good, total))
    c = collections.Counter()
    for p in range(128):
        for bk in range(8):
            v = word(TX, p * 8 + bk)
            c[("program same" if (v & 0xFF) == p else "program differs", "bank same" if (v >> 8) == bk else "bank differs")] += 1
    print("0xF08514 over (program 0..127, bank 0..7):", dict(c))
    ok = good == total == 272
    print("OK" if ok else "FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
