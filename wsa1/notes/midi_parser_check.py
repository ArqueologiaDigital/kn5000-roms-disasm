#!/usr/bin/env python3
"""Re-check, from the ROM bytes, every quantified claim the MIDI parser headers make.

QUESTION IT ANSWERS: prom_a 0xFA5400-0xFA5941 now carries sentences like "eight
entries", "one more than it is about to write", "exactly three compares",
"seven registers", "six slots, only one live" and "the 0x0C branch is never
taken".  The byte gate proves the source rebuilds the ROM and is blind to all of
it.  This is the other half.

    python3 notes/midi_parser_check.py        # exits non-zero on any failure
    python3 notes/midi_parser_check.py -v     # print every check

Companion to notes/prom_a_byte_checks.py, kept separate only so the two lanes
do not collide in one file.  Write-up: notes/FINDINGS-midi-port.md.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
FAILS = []
RAN = []
VERBOSE = "-v" in sys.argv


def a(addr, n=1):
    return A[addr - 0xF80000:addr - 0xF80000 + n]


def check(name, cond, detail=""):
    RAN.append(name)
    if VERBOSE or not cond:
        print("%-4s %s%s" % ("ok" if cond else "FAIL", name,
                             ("  -- " + detail) if detail and not cond else ""))
    if not cond:
        FAILS.append(name)


# --- MIDI_StatusDispatch_Table: eight LE32 handlers -------------------------
TBL = 0xFA578E
AWAIT, DROP, TWO, SYSTEM = 0xFA57D8, 0xFA57AE, 0xFA57AF, 0xFA5830
WANT = [AWAIT, AWAIT, DROP, AWAIT, TWO, TWO, AWAIT, SYSTEM]
got = [int.from_bytes(a(TBL + 4 * i, 4), "little") for i in range(8)]
check("message-length table: the eight targets are as the header lists",
      got == WANT, str([hex(x) for x in got]))
# The COUNT is fixed by the addressing, not by inspection.
check("message-length table: the index is `and A,0x70` then `srl 2`",
      a(0xFA5779, 3) == bytes([0xC9, 0xCC, 0x70])
      and a(0xFA577C, 3) == bytes([0xC9, 0xEF, 0x02]),
      a(0xFA5779, 6).hex(" "))
check("message-length table: it is loaded from 0xFA578E",
      a(0xFA5781, 5) == bytes([0x44, 0x8E, 0x57, 0xFA, 0x00]))
check("message-length table: slot 7 ends at 0xFA57AE, so an 8th is the last",
      TBL + 8 * 4 == 0xFA57AE)
# ★ the finding: Poly Key Pressure's slot points at a bare RET.
check("★ slot 2 (Poly Key Pressure) points at 0xFA57AE, and that byte is RET",
      got[2] == 0xFA57AE and a(0xFA57AE, 1) == b"\x0e", a(0xFA57AE, 1).hex())
check("★ it is the ONLY slot pointing at the bare RET",
      got.count(0xFA57AE) == 1)
check("the four distinct targets are four, not three or five",
      len(set(got)) == 4, str(sorted(hex(x) for x in set(got))))

# --- the free-space tests: n is one greater than the bytes about to be written
# `9c fe 3f LL HH` = cp (XIX+0xFE),imm16
for site, imm, nbytes in ((0xFA57B8, 3, 2), (0xFA5803, 4, 3)):
    body = a(site, 5)
    check("free-space test at 0x%06X compares against %d (writes %d bytes)"
          % (site, imm, nbytes),
          body[:3] == bytes([0x9C, 0xFE, 0x3F])
          and int.from_bytes(body[3:5], "little") == imm, body.hex(" "))
check("both free-space tests use the same base 0x00600C1E",
      a(0xFA57B3, 5) == bytes([0x44, 0x1E, 0x0C, 0x60, 0x00])
      and a(0xFA57E9, 5) == bytes([0x44, 0x1E, 0x0C, 0x60, 0x00]))
check("both take `jr c` to an overflow arm",
      a(0xFA57BD, 1) == b"\x67" and a(0xFA5808, 1) == b"\x67")

# --- ★ the congestion rule ------------------------------------------------
# free <= 0x40, message is 0x9n, velocity NOT zero  ->  jump to the RET.
check("congestion: the threshold compare is against 0x0040",
      a(0xFA57EE, 5) == bytes([0x9C, 0xFE, 0x3F, 0x40, 0x00]),
      a(0xFA57EE, 5).hex(" "))
check("congestion: `jr ugt` skips the whole rule when there is room",
      a(0xFA57F3, 2) == bytes([0x6B, 0x0E]))
check("congestion: it tests `and D,0xf0` / `cp D,0x90` -- a Note On",
      a(0xFA57F6, 3) == bytes([0xCC, 0xCC, 0xF0])
      and a(0xFA57F9, 3) == bytes([0xCC, 0xCF, 0x90]))
check("congestion: then `cp E,0` and `jr nz` -- NON-zero velocity is dropped",
      a(0xFA57FF, 2) == bytes([0xCD, 0xD8])
      and a(0xFA5801, 2) == bytes([0x6E, 0x24]))
# and the target of that jr nz really is a bare RET, i.e. the message is lost
check("congestion: `jr nz` lands on 0xFA5827, which is a RET",
      0xFA5803 + 0x24 == 0xFA5827 and a(0xFA5827, 1) == b"\x0e")
# the opposite branch must NOT skip delivery -- velocity 0 falls through
check("congestion: velocity zero falls through into the deliver path 0xFA5803",
      0xFA5801 + 2 == 0xFA5803)

# --- the parser's register context ----------------------------------------
LOAD, SAVE, CLEAR = 0xFA5884, 0xFA58A1, 0xFA58CC
ok_l = all(a(LOAD + 4 * i, 4) == bytes([0xE1, 4 * i, 0x09, 0x20 + i])
           for i in range(7))
ok_s = all(a(SAVE + 4 * i, 4) == bytes([0xF1, 4 * i, 0x09, 0x60 + i])
           for i in range(7))
check("context: seven `ld XRR,(0x0900+4k)` loads", ok_l)
check("context: seven `ld (0x0900+4k),XRR` stores", ok_s)
check("context: both end in RET after exactly seven, at 0xFA58A0 / 0xFA58BD",
      a(0xFA58A0, 1) == b"\x0e" and a(0xFA58BD, 1) == b"\x0e")
check("context: an EIGHTH load would start where the store block does",
      LOAD + 7 * 4 + 1 == SAVE)
ok_c = all(a(CLEAR + 5 * i, 5) == bytes([0xF1, 4 * i, 0x09, 0x00, 0x00])
           for i in range(7))
check("context: ClearContext zeroes exactly those same seven longs", ok_c)
check("context: ClearContext ends in RET after seven, at 0xFA58EF",
      a(0xFA58EF, 1) == b"\x0e")
# and MIDI_RX_Byte really brackets its body with the pair, INSIDE the pushes
check("context: MIDI_RX_Byte pushes 7 registers, then calls the loader",
      a(0xFA54A1, 7) == bytes([0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E])
      and a(0xFA54A8, 3) == bytes([0x1E, 0xD9, 0x03])
      and 0xFA54AB + 0x03D9 == LOAD)
check("context: and calls the saver before popping them",
      a(0xFA54F9, 3) == bytes([0x1E, 0xA5, 0x03])
      and 0xFA54FC + 0x03A5 == SAVE
      and a(0xFA54FC, 7) == bytes([0x5E, 0x5D, 0x5C, 0x5B, 0x5A, 0x59, 0x58]))

# --- System Common: exactly three compares --------------------------------
cmps, pc = [], 0xFA5833
while a(pc, 2) == bytes([0xCC, 0xCF]):
    cmps.append(a(pc + 2, 1)[0])
    pc += 5                                   # cp D,imm8 (3) + jr cc,d8 (2)
check("System Common: exactly three `cp D,imm8` links", len(cmps) == 3,
      str([hex(c) for c in cmps]))
check("System Common: they are 0xF0, 0xF2, 0xF3", cmps == [0xF0, 0xF2, 0xF3],
      str([hex(c) for c in cmps]))
check("System Common: the fall-through after them is a RET (0xF1/0xF6 ignored)",
      a(pc, 1) == b"\x0e", a(pc, 1).hex())
check("System Common: it clears running status FIRST, unconditionally",
      a(0xFA5830, 3) == bytes([0x08, 0x9A, 0x00]))

# --- SysEx: exactly two accepted identifiers ------------------------------
check("SysEx: the two accepted identifiers are 0x50 and 0x7E",
      a(0xFA5850, 3) == bytes([0xCD, 0xCF, 0x50])
      and a(0xFA5855, 3) == bytes([0xCD, 0xCF, 0x7E]))
check("SysEx: anything else takes `jr nz` to the RET at 0xFA586D",
      a(0xFA5858, 2) == bytes([0x6E, 0x13]) and 0xFA585A + 0x13 == 0xFA586D
      and a(0xFA586D, 1) == b"\x0e")
check("SysEx: (0xA9) is set to 1 before the identifier is even looked at",
      a(0xFA584D, 3) == bytes([0x08, 0xA9, 0x01]))

# --- ★ the correction: both counters are BYTE increments ------------------
# `C1 lo hi 61` -- the 0xC0-group prefix is BYTE-sized (MAME 900tbl.hxx
# s_mnemonic_c0[0x61] = op_INCBIM); the word form would be a 0xD1 prefix
# (s_mnemonic_d0[0x61] = op_INCWIM).  An earlier comment called (0x0931) a
# 16-bit counter; it is 8-bit, and it has to be, because (0x0932) is the
# separate overflow counter immediately after it.
check("counters: (0x0931) is incremented with the C1 prefix, i.e. BYTE-sized",
      a(0xFA5429, 4) == bytes([0xC1, 0x31, 0x09, 0x61]), a(0xFA5429, 4).hex(" "))
for site in (0xFA57D3, 0xFA582B):
    check("counters: (0x0932) at 0x%06X is BYTE-sized too" % site,
          a(site, 4) == bytes([0xC1, 0x32, 0x09, 0x61]), a(site, 4).hex(" "))
check("counters: the two addresses are adjacent, so neither can be 16-bit",
      0x0931 + 1 == 0x0932)

# --- the UART setup, and the branch that is never taken -------------------
check("UART: SC0MOD=0x29, SC0CR=0x00, BR0CR=0x0E",
      a(0xFA58F2, 3) == bytes([0x08, 0x52, 0x29])
      and a(0xFA58F5, 3) == bytes([0x08, 0x51, 0x00])
      and a(0xFA58F8, 3) == bytes([0x08, 0x53, 0x0E]))
check("UART: the alternate divisor 0x0C is guarded by (0xFFFFF8) == 0x24",
      a(0xFA58FB, 6) == bytes([0xC2, 0xF8, 0xFF, 0xFF, 0x3F, 0x24]))
check("★ UART: 0xFFFFF8 actually holds 0x02, so that branch is NEVER taken",
      a(0xFFFFF8, 1) == b"\x02", a(0xFFFFF8, 1).hex())
check("UART: 31250 baud x 896 = 28,000,000 (the fc the divisor implies)",
      31250 * 896 == 28000000)

# --- MIDI_EntryThunks: six slots of four, one live ------------------------
slots = [a(0xFA5400 + 4 * i, 4) for i in range(6)]
live = [i for i, s in enumerate(slots) if s[0] == 0x1B]
empty = [i for i, s in enumerate(slots) if s == bytes([0x0E, 0, 0, 0])]
check("entry thunks: six slots, exactly one live and five empty",
      len(live) == 1 and len(empty) == 5, str([s.hex() for s in slots]))
check("entry thunks: the live one is slot 3 and it is `jp MIDI_Reset`",
      live == [3] and slots[3] == bytes([0x1B, 0xBE, 0x58, 0xFA]))
check("entry thunks: the table is bounded below by 0x0E pad and above by "
      "MIDI_RX_ErrorReset",
      a(0xFA53FF, 1) == b"\x0e" and a(0xFA5418, 1) == b"\x28")

# --- 0x0E is this build's pad byte ---------------------------------------
runs, j = [], 0
while j < len(A):
    if A[j] == 0x0E:
        k = j
        while k < len(A) and A[k] == 0x0E:
            k += 1
        if k - j >= 64:
            runs.append((0xF80000 + j, k - j))
        j = k
    else:
        j += 1
check("pad: prom_a has 35 runs of 64 or more 0x0E bytes", len(runs) == 35,
      "got %d" % len(runs))
# ⚠ The forward scan reports this run as 153 bytes, not 152: the pad is 0x0E
# and so is slot 0's own `ret`, so the run does not stop at the table -- it
# runs one byte INTO it.  152 bytes lie strictly before 0xFA5400.  Recorded as
# a check because it is exactly the trap that made an earlier draft of
# FINDINGS-fonts.md read 1200 bytes of 0x0E padding in prom_b as glyph data:
# pad and code are indistinguishable by byte value in this build.
check("pad: the run at 0xFA5368 measures 153, one byte into the table",
      (0xFA5368, 153) in runs,
      str([r for r in runs if 0xFA5000 < r[0] < 0xFA6000]))
check("pad: 152 bytes lie strictly before MIDI_EntryThunks",
      0xFA5400 - 0xFA5368 == 152 and a(0xFA5400, 1) == b"\x0e")

# =========================================================================
# THE FOREGROUND CONSUMER at 0xFA5942 -- the second state machine
# =========================================================================

# --- MIDI_Fg_LengthTable: eight LE32 handlers, bounds-checked --------------
FTBL = 0xFA5A48
AWAIT2, EMIT2, SYS2 = 0xFA5A73, 0xFA5A68, 0xFA5A7D
fwant = [AWAIT2, AWAIT2, AWAIT2, AWAIT2, EMIT2, EMIT2, AWAIT2, SYS2]
fgot = [int.from_bytes(a(FTBL + 4 * i, 4), "little") for i in range(8)]
check("foreground table: the eight targets are as the header lists",
      fgot == fwant, str([hex(x) for x in fgot]))
check("foreground table: the index is bounded by `cp BC,7` / `jr ugt` BEFORE "
      "the scale by 4",
      a(0xFA5A37, 2) == bytes([0xD9, 0xDF])
      and a(0xFA5A39, 2) == bytes([0x6B, 0x4C])
      and a(0xFA5A3B, 3) == bytes([0xD9, 0xEE, 0x02]))
check("foreground table: it is added to 0x00FA5A48",
      a(0xFA5A3E, 6) == bytes([0xE9, 0xC8, 0x48, 0x5A, 0xFA, 0x00]))
# ★ the difference from the interrupt table that must not be glossed over
check("★ foreground slot 2 (Poly Key Pressure) is NOT the bare-RET target",
      fgot[2] != 0xFA57AE and fgot[2] == AWAIT2)
check("★ the interrupt table sends slot 2 to a bare RET and this one does not",
      got[2] == 0xFA57AE and fgot[2] == AWAIT2)
check("the two tables group the SAME statuses by data-byte count",
      [got[i] == got[0] for i in range(8)][:2] == [True, True]
      and [fgot[i] == fgot[0] for i in (0, 1, 3, 6)] == [True] * 4
      and fgot[4] == fgot[5] and got[4] == got[5])

# --- the two message builders: frame size and length argument agree --------
for name, addr, link, length, push_at in (
        ("Deliver2", 0xFA5A8B, 0xFFFE, 2, 0xFA5AA1),
        ("Deliver3", 0xFA5ABE, 0xFFFC, 3, 0xFA5AD9)):
    fr = a(addr, 4)
    check("MIDI_Fg_%s: `link XIZ,0x%04X`" % (name, link),
          fr == bytes([0xEE, 0x0C, link & 0xFF, link >> 8]), fr.hex(" "))
    check("MIDI_Fg_%s: the length pushed is %d, matching the frame"
          % (name, length),
          a(push_at, 3) == bytes([0x0B, length, 0x00]), a(push_at, 3).hex(" "))
    check("MIDI_Fg_%s: hands the buffer to prom_b 0xF41DD4" % name,
          a(push_at + 3, 4) == bytes([0x1D, 0xD4, 0x1D, 0xF4]))
# and both call sub_FA5935 on the buffer first -- the two calr callers whose
# absence prom_a_xref.py wrongly implied
for site, nxt in ((0xFA5A93, 0xFA5A96), (0xFA5AC6, 0xFA5AC9)):
    d = int.from_bytes(a(site + 1, 2), "little")
    check("sub_FA5935: `calr` at 0x%06X resolves to it" % site,
          a(site, 1) == b"\x1e" and (nxt + d - 0x10000) == 0xFA5935,
          "target 0x%06X" % (nxt + d - 0x10000))

# --- ★ (0x9E) bit 5 has TWO writers, and only one is a `set` instruction ---
setb5 = A.count(bytes([0xF0, 0x9E, 0xBD]))
check("(0x9E) bit 5: exactly one `set 5,(0x9e)` in prom_a, at 0xFA59F2",
      setb5 == 1 and a(0xFA59F2, 3) == bytes([0xF0, 0x9E, 0xBD]),
      "count=%d" % setb5)
check("★ (0x9E) bit 5: INTT1_Tick sets it by read-modify-write instead",
      a(0xF82D1C, 3) == bytes([0xC0, 0x9E, 0x21])       # ld A,(0x9e)
      and a(0xF82D30, 3) == bytes([0xC9, 0xCC, 0x7F])   # and A,0x7f
      and a(0xF82D33, 3) == bytes([0xC9, 0xCE, 0x20])   # or  A,0x20  <- bit 5
      and a(0xF82D4A, 3) == bytes([0xF0, 0x9E, 0x41]))  # ld (0x9e),A
check("★ so a `set 5,(0x9e)` census alone would have found only one of the two",
      setb5 == 1)

# --- the two state machines use the same 0xBD clear mask ------------------
for site, pfx in ((0xFA54C3, 0xC0), (0xFA5823, 0xC0), (0xFA541F, 0xC0),
                  (0xFA596A, 0xC1), (0xFA5AE0, 0xC1)):
    n = 4 if pfx == 0xC0 else 5
    check("clear mask 0xBD at 0x%06X" % site, a(site, n)[-1] == 0xBD,
          a(site, n).hex(" "))

# --- the source really uses the names these checks are about --------------
src = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")).read()
for label in ("MIDI_RX_DataByte", "MIDI_StatusDispatch_Table", "MIDI_RX_Drop",
              "MIDI_RX_DeliverTwo", "MIDI_RX_AwaitSecondByte",
              "MIDI_RX_SecondDataByte", "MIDI_RX_SystemCommon",
              "MIDI_RX_SysExStart", "MIDI_RX_SysExData",
              "MIDI_Parser_LoadContext", "MIDI_Parser_SaveContext",
              "MIDI_Reset", "MIDI_Parser_ClearContext", "MIDI_UART_Configure",
              "MIDI_PostSendWork", "MIDI_EntryThunks", "MIDI_DrainQueue",
              "MIDI_Fg_RealTime", "MIDI_Fg_DataByte", "MIDI_Fg_LengthTable",
              "MIDI_Fg_Emit2", "MIDI_Fg_Await", "MIDI_Fg_System",
              "MIDI_Fg_Deliver2", "MIDI_Fg_StashFirstData",
              "MIDI_Fg_Deliver3", "sub_FA5935"):
    check("source defines %s" % label,
          re.search(r"^%s:" % label, src, re.M) is not None)

print("\n%d checks ran, %d failed" % (len(RAN), len(FAILS)))
sys.exit(1 if FAILS else 0)
