#!/usr/bin/env python3
"""Do the claims about prom_a's drum-kit name table hold against the ROM?

QUESTION IT ANSWERS
  The header at prom_a 0xFEB330 claims a 35-entry RAM-pointer table, a 130-entry
  block-pointer table and a 13 x 129 x 10 name table, and it claims the framing
  is established by the POINTERS rather than by the string content.  This script
  re-derives all of that from the image, plus the cross-module agreement with
  PtrTable_FF4251 that the header leans on.

RUN
  python3 notes/prom_a_drumnames_checks.py
Exit status is non-zero if any check fails.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
SRC = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
BASE = 0xF80000
PART, NPART = 0xFEB330, 35
KITP, NKITP = 0xFEB3BC, 130
NAMES, KITS, PER, W = 0xFEB5C4, 13, 129, 10

FAIL = 0


def check(ok, msg):
    global FAIL
    print(("  ok   " if ok else "  FAIL ") + msg)
    if not ok:
        FAIL = 1


def long_at(a):
    return int.from_bytes(ROM[a - BASE:a - BASE + 4], "little")


def name(kit, j):
    at = NAMES + (kit * PER + j) * W
    return ROM[at - BASE:at - BASE + W]


print("1. the three regions tile 0xFEB330-0xFEF746 exactly")
check(PART + 4 * NPART == KITP, "RecordPtrs_RAM76A2 ends where DrumKitNameBlockPtrs begins")
check(KITP + 4 * NKITP == NAMES, "DrumKitNameBlockPtrs ends where DrumKitNames begins")
check(NAMES + KITS * PER * W == 0xFEF746,
      "★ 13 x 129 x 10 = 16,770 bytes ends at 0xFEF746 EXACTLY, with no remainder")
check(ROM[0xFEF746 - BASE:0xFEF746 - BASE + 5] == b"\xf1\x40\x25\x00\x00",
      "0xFEF746 is `stdi8 (0x2540),0x00` -- the next region is code")
check(ROM[PART - BASE - 1] == 0x0E, "0xFEB32F is a `ret` -- the previous region is code")

print("\n2. RecordPtrs_RAM76A2, and the cross-module agreement")
part = [long_at(PART + 4 * k) for k in range(NPART)]
check(all(0x7000 <= v < 0x8000 for v in part), "all 35 values are RAM addresses")
check(all((v - 0x76A2) % 0x40 == 0 for v in part),
      "all 35 are 0x76A2 + a multiple of 0x40 -- a 64-byte record array")
steps = [part[i + 1] - part[i] for i in range(NPART - 1)]
check(steps.count(0x80) == 1 and steps.count(0x40) == 30
      and steps[-3:] == [-2048, 0, 0],
      "the 34 steps are thirty 0x40, ONE 0x80, and a fall back to entry 0 that "
      "the last three entries then repeat (got %s)" % steps[-4:])
ff = [long_at(0xFF4251 + 4 * k) for k in range(16)]
check(all(v - 0x0D in part for v in ff),
      "★ every one of PtrTable_FF4251's 16 pointers is one of these records + 13")
fsteps = [ff[i + 1] - ff[i] for i in range(15)]
check(fsteps.count(0x80) == 1 and set(fsteps) == {0x40, 0x80},
      "★ and PtrTable_FF4251 has the SAME single 0x80 step -- two modules agree "
      "on the record array's one irregularity")
check(part.index(0x78E2) == ff.index(0x78E2 + 0x0D),
      "★ the 0x80 step is at the same array position in both tables (index %d)"
      % part.index(0x78E2))

print("\n3. DrumKitNameBlockPtrs -- the framing evidence")
kp = [long_at(KITP + 4 * k) for k in range(NKITP)]
check(all((v - NAMES) % (PER * W) == 0 for v in kp),
      "★ all 130 pointers are 0xFEB5C4 + a multiple of 1290 = 129 x 10 -- every "
      "one lands on a name-block boundary, never one byte off")
blocks = [(v - NAMES) // (PER * W) for v in kp]
check(min(blocks) == 1 and max(blocks) == 6,
      "the blocks named are 1..6 (got %d..%d)" % (min(blocks), max(blocks)))
check(blocks.count(1) == 123, "123 of the 130 programs use block 1 (got %d)"
      % blocks.count(1))
exc = {i: b for i, b in enumerate(blocks) if b != 1}
check(exc == {24: 2, 26: 2, 29: 2, 40: 3, 48: 5, 112: 4, 120: 6},
      "the seven exceptions are exactly programs 24/26/29->2, 40->3, 48->5, "
      "112->4, 120->6 (got %s)" % exc)

print("\n4. DrumKitNames -- content and shape")
allb = ROM[NAMES - BASE:0xFEF746 - BASE]
check(all(0x20 <= c < 0x7F for c in allb),
      "all 16,770 bytes are printable ASCII")
check(max(allb) == 0x7A, "the highest byte is 0x7A ('z'), so no control or "
                         "high-bit characters")
blanks = [sum(1 for j in range(PER) if not name(k, j).strip()) for k in range(KITS)]
check(blanks[0] == PER, "★ block 0 is 129 BLANK names -- the empty kit")
check(blanks == [129, 10, 10, 10, 41, 67, 72, 22, 20, 78, 69, 69, 67],
      "the blank count per block is %s" % blanks)
for k, j, want in ((1, 0, b"          "), (1, 3, b"Zap 1     "),
                   (1, 127, b"WoodBlk H2"), (4, 0, b"          "),
                   (6, 128, b"          "), (12, 128, b"          ")):
    check(name(k, j) == want,
          "block %d name %d is %r" % (k, j, want.decode()))
# ★ LAST-ELEMENT TEST: the very last name in the region
last = name(KITS - 1, PER - 1)
check(last == ROM[0xFEF746 - BASE - W:0xFEF746 - BASE],
      "★ the last name of block 12 is the last 10 bytes of the region")
gm = [b"Bass Dr 1 ", b"Hand Claps", b"Ride Cym 1", b"Cowbell 2 ", b"Vibraslap "]
present = [g for g in gm if any(name(1, j) == g for j in range(PER))]
check(len(present) == len(gm),
      "block 1 contains the General-MIDI percussion legends %s"
      % [g.decode().strip() for g in gm])

print("\n5. which blocks anything in either image actually NAMES")
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
import re as _re
named_blocks = []
for k in range(KITS):
    a = NAMES + k * PER * W
    pat = a.to_bytes(3, "little")
    n = len(_re.findall(_re.escape(pat), ROM)) + len(_re.findall(_re.escape(pat), B))
    if n:
        named_blocks.append(k)
check(named_blocks == [0, 1, 2, 3, 4, 5, 6],
      "★ a raw 3-byte address scan of BOTH images finds blocks 0-6 named and "
      "blocks 7-12 named NOWHERE (got %s).  The scan is opcode-agnostic, so it "
      "over-reports and cannot under-report: this is a searched negative, not "
      "an assumption" % named_blocks)

print("\n6. the five arms of the record-TYPE dispatcher at 0xFEB2F5")
# targets computed the way the CPU does: displacement from the end of the jr.
arms = {0x20: 0xFEB2FA + 0x11, 0x28: 0xFEB2FF + 0x1F, 0x29: 0xFEB304 + 0x1A,
        0x30: 0xFEB309 + 0x1B}
check(arms == {0x20: 0xFEB30B, 0x28: 0xFEB31E, 0x29: 0xFEB31E, 0x30: 0xFEB324},
      "the four `jr z` arms land at 0xFEB30B / 0xFEB31E / 0xFEB31E / 0xFEB324")
check(0xFEB30B + 0x1F == 0xFEB32A, "the fall-through `jr` lands at 0xFEB32A")
check(long_at(0xFEB30E + 1) == KITP,
      "★ the 0x20 arm loads XIX = 0x%06X, DrumKitNameBlockPtrs -- so type 0x20 "
      "is the one that reaches the name table" % KITP)
check(long_at(0xFEB31E + 1) == 0x00603FF6 and long_at(0xFEB324 + 1) == 0x00603FF6,
      "the 0x28/0x29 and 0x30 arms both load RAM 0x00603FF6")
check(long_at(0xFEB32A + 1) == NAMES,
      "★ the FALL-THROUGH arm loads 0x%06X -- name block 0, the 129 blanks: an "
      "unrecognised record type shows blanks, not garbage" % NAMES)

print("\n6b. ★ THE NAME INDEX IS THE MIDI NOTE NUMBER (General MIDI percussion)")
# Each block holds 129 names indexed 0..128, and the index used to look one up
# is the byte the caller supplies.  If that byte is a MIDI key number, then
# indices 35..81 must be the General MIDI percussion map -- and they are.
# The test is a KEYWORD test rather than a string compare, because Technics
# abbreviates to 10 characters ("Bass Dr 2 " for Acoustic Bass Drum).
# ⚠ AND IT HAS A NEGATIVE CONTROL: the same keywords are re-tested with the
# index shifted by +1 and by -1.  If those passed too, the test would be
# measuring "these words appear in the table" instead of "they appear AT THE
# GENERAL MIDI KEY NUMBER", which is the whole claim.
GM_KEYWORDS = {
    35: "Bass Dr",     36: "Bass Dr",     37: "Rim Shot",   38: "Snare Dr",
    39: "Hand Clap",   40: "Snare",       41: "FloorTom",   42: "Hi-Hat",
    43: "FloorTom",    44: "Hi-Hat",      46: "Hi-Hat",     49: "Crash Cym",
    51: "Ride Cym",    52: "ChineseCym",  53: "Ride Bell",  54: "Tamburn",
    55: "Splash Cym",  56: "Cowbell",     57: "Crash Cym",  58: "Vibraslap",
    59: "Ride Cym",    60: "Bongo",       61: "Bongo",      62: "Conga",
    63: "Conga",       64: "Conga",       65: "Timb",       66: "Timb",
    67: "Agogo",       68: "Agogo",       69: "Cabasa",     70: "Maracas",
    71: "SambaWh",     72: "SambaWh",     73: "Guiro",      74: "Guiro",
    75: "Claves",      76: "Wood Blk",    77: "Wood Blk",   78: "Cuica",
    79: "Cuica",       80: "Triangle",    81: "Triangle",
}
KIT = 1   # block 0 is 129 blanks; block 1 is the first populated kit


def hits(shift):
    return sum(1 for k, kw in GM_KEYWORDS.items()
               if 0 <= k + shift < PER
               and kw in name(KIT, k + shift).decode("latin1"))


aligned, plus1, minus1 = hits(0), hits(1), hits(-1)
print("     aligned %d/%d, shifted +1 %d/%d, shifted -1 %d/%d"
      % (aligned, len(GM_KEYWORDS), plus1, len(GM_KEYWORDS),
         minus1, len(GM_KEYWORDS)))
check(aligned == len(GM_KEYWORDS),
      "★ all %d General MIDI percussion keys 35-81 land on a matching name -- "
      "the lookup index IS the MIDI note number" % len(GM_KEYWORDS))
check(plus1 < aligned // 2 and minus1 < aligned // 2,
      "NEGATIVE CONTROL: the same keywords at index+1 and index-1 do NOT match "
      "(%d and %d of %d), so the test measures the ALIGNMENT" 
      % (plus1, minus1, len(GM_KEYWORDS)))
# LAST-ELEMENT TEST: 81 is the highest GM percussion key, Open Triangle.
check(name(KIT, 81).decode("latin1") == "Triangle O",
      "LAST GM KEY 81 (Open Triangle) is 'Triangle O'")
check(name(KIT, 82).decode("latin1").strip() == "Shaker On",
      "and 82, one past the end of General MIDI, is a Technics extension "
      "('Shaker On') -- the map is extended upward, not shifted")

print("\n7. the source really carries it as readable text")
check(SRC.count('.ascii "') >= KITS * PER,
      "at least %d `.ascii` lines in prom_a/wsa1_prom_a.s (got %d)"
      % (KITS * PER, SRC.count('.ascii "')))
check('.ascii "Bass Dr 1 "' in SRC, 'the source contains .ascii "Bass Dr 1 "')

print()
sys.exit(FAIL)
