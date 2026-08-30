#!/usr/bin/env python3
"""prom_c's TAIL DATA ZONE, 0xFDF7E0-0xFE21E5: what is in it, and the assembly for it.

QUESTION IT ANSWERS
  After round 2 prom_c had 11,005 bytes left as `.incbin`, of which 10,389 were four
  spans of the tail data zone.  Round 2 said of them: "0xFDF7E0-0xFE11EF and
  0xFE1280-0xFE12B4 and 0xFE1361-0xFE1697 have no established object boundaries".
  They do.  Every object below starts at an address prom_c's own code CITES
  (notes/prom_c_tail_census.py), and most of them have a closed form or an index range
  that the reading code fixes independently.

★ THE THREE THINGS THIS ESTABLISHED THAT WERE NOT KNOWN BEFORE

  1. FIVE 256-ENTRY u16 MATH TABLES sit end to end at 0xFE06C9, 0xFE08C9, 0xFE0AC9,
     0xFE0CC9 and 0xFE0EC9 -- sin, cos, atan, log2 and exp2 -- each cited by its own
     `add <X..>,#imm32`, each 0x200 bytes after the last, and each matching a closed form
     over all 256 entries.  Four small routines at 0xFC419D, 0xFC41C3, 0xFC41E9 and
     0xFC4227 are the library that reads them, in Q11 fixed point (2048 = 1.0).

  2. THE COSINE TABLE CROSSES 0xFE0A6D, so round 2's "copy A starts at 0xFE0A6D" is a
     boundary of the DUPLICATION and not of an object.  0xFE0AC9 -- the atan table, and the
     cosine table's exclusive end -- is cited by `add XBC,0x00FE0AC9` at 0xFC4207, which is
     one of the eight citations `prom_c_dup_image.py --refs` could not see.

  3. THE FOUR FLASH BANKS AT 0xE80000/0xE90000/0xEA0000/0xEB0000 ARE NAMED IN THE ROM:
     "WSA SOUND RAM S0".."S3", four NUL-terminated strings at 0xFE14CB..0xFE150E, a table
     of pointers to them at 0xFE150F and a table of their base addresses at 0xFE151F.  The
     routine at 0xFC3899 walks the two tables together, four iterations, calling
     Flash_ReadSectorToBuffer (0xFC89AF) and Flash_ReprogramSector (0xFC876C) on each base
     while displaying the bank's name and "  --(Clear)--   " (0xFE152F).

WHAT IS NOT ESTABLISHED
  * What most of the small tables are FOR.  Where the closed form is the only fact, the
    name says so (`Table_XXXXXX`, `Curve_XXXXXX`), and the header gives the shape, the
    index and the reader, never a role.
  * Copy B is emitted with its counterparts' names plus `_B`.  That is a statement about
    the BYTES (each object is byte-identical to its twin except for relocated pointers,
    counted per object below), not a claim that anything runs it -- nothing cites it.

RUN
  python3 notes/gen_prom_c_tail_tables.py --verify   # every claim below; exit != 0 on fail
  python3 notes/gen_prom_c_tail_tables.py --emit     # the assembly fragment
  python3 notes/gen_prom_c_tail_tables.py --census   # objects, sizes, citations
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prom_c_tail_census as CEN                                    # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
BASE = 0xF80000
IMG = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()

R1_LO, R1_HI = 0xFDF7E0, 0xFE11F0        # first emit region  (was two .incbin spans)
MID_LO, MID_HI = 0xFE11F0, 0xFE1361      # already converted in round 2 -- not emitted
R2_LO, R2_HI = 0xFE1361, 0xFE1698        # second emit region
R3_LO, R3_HI = 0xFE1698, 0xFE21E6        # copy B
D1, D2 = 0xC2B, 0xC05                    # the two copy-A -> copy-B deltas
NO_TWIN = (0xFE133B, 38)                 # the copy-A object copy B does not have


def u8(a):
    return IMG[a - BASE]


def s8(a):
    v = IMG[a - BASE]
    return v - 256 if v >= 128 else v


def u16(a):
    return IMG[a - BASE] | (IMG[a - BASE + 1] << 8)


def u32(a):
    return int.from_bytes(IMG[a - BASE:a - BASE + 4], "little")


# ---------------------------------------------------------------- closed forms
def law_exp2_down(k):
    return round(32768 * 2 ** ((k - 255) / 16))


def law_exp2_up(k):
    return round(32768 * (1 - 2 ** (-k / 16)))


def law_exp2_down101(k):
    return 0 if k == 0 else round(32768 * 2 ** ((k - 100) / 16))


def law_log2_a(k):
    return 0x6C00 if k == 0 else round(27543 - 3072 * math.log2(k))


def law_log2(k):
    return 0xFFFF if k == 0 else round(3072 * (7 - math.log2(k))) % 65536


def law_sin16(k):
    return round(32767 * math.sin(2 * math.pi * k / 256)) % 65536


def law_cos16(k):
    return round(32768 * math.cos(2 * math.pi * k / 256)) % 65536


def law_atan(k):
    return round(16384 * math.atan(k / 16))


def law_exp2(k):
    return round(12868 * 2 ** (k / 256))


def law_sin8(k):
    return round(128 * math.sin(2 * math.pi * k / 512)) % 256


def law_lin_0096(k):
    return (2 * k - 128) % 256


def law_lin_0116(k):
    return (k * 65 // 128 - 32) % 256


def law_lin_0196(k):
    # ⚠ the LAST entry breaks the ramp: k//2 - 64 would be -1, the ROM holds 0.
    return 0 if k == 127 else (k // 2 - 64) % 256


# ---------------------------------------------------------------- the objects
# (addr, size, unit, name, [description lines])
# unit: 'b' bytes, 'w' u16, 'l' u32, 'sz' NUL-terminated string, 'r6' 6-byte {u32,u8,u8}
OBJ_R1 = [
 (0xFDF7E0, 512, 'w', "Curve_Exp2Decay_256", [
  "256 u16.  T[k] = round(32768 * 2^((k-255)/16)) over all 256 entries, |err| <= 4:",
  "a curve that DOUBLES EVERY 16 STEPS -- 0.376 dB a step, 96 dB end to end -- and is 0",
  "for k <= 46 because it has fallen below half a count.  T[255] = 0x8000.",
  "COUNT 256, from the reader's own clamp: 0xFC4FEC `cp BC,0x00ff` (else HL = 0xFF) and",
  "0xFC4FF7 `cp HL,0` (else HL = 0), then `ld BC,2 / muls XBC,HL / add XBC,<this>`.",
  "So index 255 is reachable and 256 is not."]),
 (0xFDF9E0, 256, 'w', "Curve_Exp2Rise_128", [
  "128 u16.  T[k] = 32768 * (1 - 2^(-k/16)) EXACTLY -- zero error on all 128 entries,",
  "the complement of Curve_Exp2Decay_256's ratio.  T[127] = 0x7F7A.",
  "COUNT 128, from the readers' clamp to 0..0x7F (0xFC4AA3 and 0xFC533A, `cp .,0x007f`)."]),
 (0xFDFAE0, 502, 'w', "Curve_Log2_251", [
  "251 u16.  T[0] = 0x6C00; T[k] = round(27543 - 3072*log2 k) for k >= 1.  3072 counts per",
  "halving is the same slope MathTable_Log2_256 uses, and entry for entry this table is",
  "that one plus 6039 (+/-1 from independent rounding).",
  "COUNT 251, from the reader's clamp at 0xFC49CC: `cp HL,0x00fa` (else 0xFA) then",
  "`cp HL,0` (else 0) -- index 0..250 -- and the table is 502 bytes = 251 u16.",
  "The value goes to word +0x06 of the 0x00104000 staging struct (register 0x00C0+chan)",
  "after two offsets are added and the result is clamped to 0x0000 / 0x7F00 (0xFC4A2B)."]),
 (0xFDFCD6, 502, 'w', "Const_0100_251", [
  "251 u16, and EVERY ONE OF THEM IS 0x0100.  Read with the same clamped 0..250 index as",
  "Curve_Log2_251, one instruction later (`lda XBC,0xFDFCD6 / add XBC,XIX` at 0xFC49ED),",
  "and stored to word +0x08 of the 0x00104000 staging struct = register 0x0100 + channel.",
  "So on this firmware that register's value from this path is the constant 0x0100.",
  "⚠ A table of identical entries is a fact about THIS image, not about the hardware."]),
 (0xFDFECC, 202, 'w', "Curve_Exp2Decay_101", [
  "101 u16.  T[0] = 0; T[k] = Curve_Exp2Decay_256[k+155] for k = 1..100 -- entry for entry,",
  "no exceptions -- i.e. the same exponential over its top 100 steps, ending on 0x8000.",
  "COUNT 101, from the readers' clamp to 0..0x64 (0xFC4B04, 0xFC6ECA)."]),
 (0xFDFF96, 256, 'b', "Table_FDFF96", [
  "256 u8, values 0x22..0x3C.  Indexed by the byte at RAM (0x00E08C), zero-extended",
  "(0xFC52A6 `ld C,(0x00e08c) / extz BC / extz XBC / add XBC,<this> / ld B,(XBC)`), so the",
  "index is 0..255 and the object is exactly 256 bytes.",
  "⚠ What the value is is NOT established; it is used as a shift/limit further down."]),
 (0xFE0096, 128, 'b', "LinCoef_FE0096", [
  "128 SIGNED bytes.  T[k] = (k*256)//128 - 128 = 2k - 128: -128 .. +126 in steps of 2,",
  "exact on all 128 entries.  One of four tables read by the identical idiom, at 0xFC55E0:",
  "    lda XIX,<this> ; A = record[+0x10] (signed) ; if A == 0 -> result 0",
  "    D = (0x00E088)                 ; a 0..127 key",
  "    if A < 0:  D = 0x7F - D ; A = -A   ; the curve is MIRRORED for a negative depth",
  "    result = (T[D] * A) >> 5",
  "so T is a coefficient in Q5 (32 = 1.0) and this one spans -4.0 .. +3.94.",
  "COUNT 128: the index is (0x00E088), which Pack104_SetInputs_E088_E089_E08A builds as voice_record[+0x0C] with",
  "BIT 7 CLEARED, so 0..127, and 0x7F - D stays in range.",
  "⚠ that the key IS a note number is not established here."]),
 (0xFE0116, 128, 'b', "LinCoef_FE0116", [
  "128 signed bytes, same reader idiom (0xFC4F51, 0xFC500E).",
  "T[k] = (k*65)//128 - 32: -32 .. +32, i.e. -1.0 .. +1.0 in Q5, exact on all 128.",
  "★ The LAST entries are what pick the law.  T[63] = T[64]... is wrong and so is",
  "floor(k/2) - 32: the real table repeats each step below k = 64 and then stops repeating",
  "(..., -1, -1, 0, 1, 1, 2, ...), which only the slope 65/128 reproduces.  T[127] = +32."]),
 (0xFE0196, 128, 'b', "LinCoef_FE0196", [
  "128 signed bytes, same reader idiom (0xFC5249, 0xFC53BF).",
  "T[k] = k//2 - 64 for k = 0..126: -64 .. -1, i.e. -2.0 .. -0.03 in Q5.",
  "★ AND THE LAST ENTRY BREAKS THE RULE: T[127] is 0, where the ramp would give -1.  A",
  "sampled check would have missed that; every entry was compared."]),
 (0xFE0216, 128, 'b', "LinCoef_FE0216", [
  "128 signed bytes, BYTE-IDENTICAL to LinCoef_FE0196 (all 128), and read by the same",
  "idiom at 0xFC513E.  Two copies of one curve, not two curves."]),
 (0xFE0296, 51, 'b', "Curve_FE0296", [
  "51 u8, 0x00..0x7E, rising with a flat head (0,1,2,3,4,6,8,12,17,...) and a flat tail.",
  "Read at 0xFC626E as `exts XBC / add XBC,<this> / ld A,(XBC)` with the index taken from",
  "(XIX+0x12) with bit 7 cleared.",
  "⚠ TENSION, RECORDED RATHER THAN RESOLVED: that mask allows 0..127 while the object is",
  "51 bytes -- the next object, MathTable_Sin_S8_512, starts at 0xFE02C9 and is proved",
  "independently by its own closed form.  Nothing in the reader bounds the index to 50."]),
 (0xFE02C9, 512, 'b', "MathTable_Sin_S8_512", [
  "512 SIGNED bytes.  T[k] = round(128 * sin(2*pi*k/512)) over all 512 entries, |err| <= 1.",
  "The period IS the object: one full cycle, so the size is fixed by the data itself and",
  "not only by the next citation.  Read at 0xFC5570 and 0xFC7C91."]),
 (0xFE04C9, 256, 'w', "Curve_FE04C9", [
  "128 s16, rising from -510 (repeated ten times) to +28591 (repeated at the top).",
  "Read at 0xFC4987 / 0xFC52E1 / 0xFC5457 with `ld BC,2 / muls XBC,HL / add XBC,<this>`;",
  "the visible clamp at 0xFC4976 is a LOWER one (`cp HL,44`, else 44) and 0xFC4971 loads 96,",
  "so the reachable index band is narrower than the table.  ⚠ No upper clamp located, so",
  "the count 128 rests on the next cited base, 0xFE05C9, and not on the reader."]),
 (0xFE05C9, 256, 'w', "Curve_FE05C9", [
  "128 s16, falling from -25 to -8188, read one instruction after Curve_FE04C9 through the",
  "same index (`lda XBC,0xFE05C9 / add XBC,XIX` at 0xFC4996, 0xFC52EF, 0xFC5465).",
  "The pair is the same shape as (Curve_Log2_251, Const_0100_251): two parallel tables,",
  "one index, two struct words."]),
 (0xFE06C9, 512, 'w', "MathTable_Sin_S16_256", [
  "256 s16.  T[k] = round(32767 * sin(2*pi*k/256)), err in [-4, +8] over all 256.",
  "★ ITS READER IS A Q11 SINE.  Math_Sin_Q11 (0xFC419D, 38 bytes) is",
  "    ld BC,0x28BE / muls XBC,(XIZ+8) / Shift32_ArithRight(.,19) / muls IY,2",
  "    add XIY,<this> / ld BC,(XIY) / sra 4,BC",
  "and 0x28BE / 2^19 = 256/(2*pi*2048) exactly to 5 digits: the argument is an angle in",
  "units of 1/2048 radian and the result is 32767/16 = 2048 * sin(theta), i.e. Q11 in and",
  "Q11 out.  The caller's own constant agrees: at 0xFC445B it forms 0x1922 - 2*arg, and",
  "0x1922 = 6434 maps to index 128.0 = half a table = pi radians."]),
 (0xFE08C9, 512, 'w', "MathTable_Cos_S16_256", [
  "256 u16.  T[k] = round(32768 * cos(2*pi*k/256)) mod 2^16, err in [-3, +6] over all 256.",
  "Read by Math_Cos_Q11, which is Math_Sin_Q11 with this base substituted -- the two routines",
  "are the same 38 bytes apart from the table address.",
  "⚠ T[0] = 0x8000, and the reader does `ld BC,(XIY) / sra 4,BC` on it, so Cos_Q11(0)",
  "comes out as -2048 rather than +2048: +1.0 does not fit in the s16 the reader assumes.",
  "That is what the ROM contains; whether any caller passes 0 is not established here.",
  "★ THIS TABLE CROSSES 0xFE0A6D, which round 2 called the start of copy A.  Its exclusive",
  "end, 0xFE0AC9, is cited by `add XIY,0x00FE0AC9` at 0xFC4239 -- so copy A's start is a",
  "boundary of the duplication and NOT an object boundary."]),
 (0xFE0AC9, 512, 'w', "MathTable_Atan_256", [
  "256 u16.  T[k] = round(16384 * atan(k/16)) over all 256 entries, err in {-1, 0}.",
  "Read by Math_Atan_Q11 (0xFC41E9): index = |arg| >> 7, result = T[index] >> 3, and the sign",
  "of arg is applied afterwards -- so with arg in Q11, index/16 = arg/2048 = the Q11 value",
  "and the result is 2048 * atan(x): Q11 in, Q11 out, an odd function."]),
 (0xFE0CC9, 512, 'w', "MathTable_Log2_256", [
  "256 s16.  T[0] = 0xFFFF (a sentinel: log2 0 has no value); T[k] = round(3072*(7-log2 k))",
  "for k >= 1, err in {-1, 0, +1}.  It is 0 at k = 128 and negative above it.",
  "Read at 0xFC465F as `ld BC,0x0800 / sub BC,WA / sra 4,BC / muls BC,2 / add XBC,<this>`",
  "i.e. index = (2048 - x)/16 with x in Q11, so the value is -3072*log2(1 - x/2048).",
  "3072 counts per halving is the same slope Curve_Log2_251 uses."]),
 (0xFE0EC9, 512, 'w', "MathTable_Exp2_256", [
  "256 u16.  T[k] = round(12868 * 2^(k/256)), err in {-1, 0} over all 256 entries, and",
  "12868 = round(2048 * 2*pi).  Read by Math_Exp2_Q11 (0xFC4227): index = (arg & 0x7FF) >> 3",
  "-- the FRACTIONAL part of a Q11 number -- result = T[index] >> 1, and for a negative arg",
  "the result is then shifted right by |arg >> 11|, the integer part.  So the routine is",
  "2^x for x in Q11, scaled by 2*pi*1024: the shape of an angular frequency."]),
 (0xFE10C9, 32, 'b', "Table_FE10C9", [
  "32 u8, values 0..3.  COUNT 32 from the reader's mask: 0xFA5EFC `ld C,E / and C,0x1f`,",
  "then `add XBC,<this> / ld L,(XBC)` at 0xFA5F05 -- index 0..31 exactly.",
  "ROUND 4: the reader is Voice_LookupDev10CChanIndex (0xFA5ED3) and the key is its THIRD",
  "argument, `and E,0x3f` at 0xFA5EDD.  The value L is used as a byte offset INSIDE the",
  "12-byte record at RAM 0x11FE + 12*arg2: 0xFA5F2A/0xFA5F2E `ld C,L / inc 0,BC` then",
  "0xFA5F32 `ld H,(XWA+BC)`, so the four values 0..3 select bytes +1..+4 of that record.",
  "Values 0..3 confirmed over all 32 entries -- STILL NOT NAMED, because what the record",
  "is is not established."]),
 (0xFE10E9, 64, 'b', "Table_FE10E9", [
  "64 u8: 0x00..0x0D then 0x0C 0x0D 0x0E 0x0E 0x0E 0x0E, twelve zeroes, 0x0F..0x1A, then",
  "zeroes.  Read one instruction after Table_FE10C9 (0xFA5F13) with the UNMASKED E, so the",
  "two are parallel tables over the same key: 0x1F wide masked, 0x3F wide unmasked.",
  "ROUND 4: same reader, Voice_LookupDev10CChanIndex (0xFA5ED3).  Its value D is compared",
  "for EQUALITY against byte +3 of the 5-byte record at RAM 0x0E3E + 5*H (0xFA5F54/",
  "0xFA5F57 `ld C,(XIX+0x03) / cp C,D`, mismatch -> the fail path at 0xFA5F7D), and it is",
  "also added to 27*arg1 at 0xFA5FA2.  Its maximum over all 64 entries is 26, which is what",
  "keeps that sum inside the 34-record stride-27 array at 0x0AA8 (27*32 + 26 = 890 < 918).",
  "STILL NOT NAMED: what the record is."]),
 (0xFE1129, 27, 'b', "Table_FE1129", [
  "27 u8: 0x00..0x0D, 0x10, then 0x20..0x2B.  Read at 0xFA60C9 with an index fetched from",
  "(XWA + 0x0E3E) in RAM.  ⚠ Nothing here bounds that index to 26; the size comes from the",
  "next cited base, 0xFE1144."]),
 (0xFE1144, 18, 'b', "Table_FE1144", [
  "18 u8.  COUNT 18 from the loop that reads it: the counter at (XIZ-7) runs while",
  "`cp (XIZ-7),0x12` is carry (0xFA677B), i.e. 0..17, and each pass does",
  "`add XBC,<this> / ld A,(XBC)` at 0xFA66EF and stores to (XHL+0x200)."]),
 (0xFE1156, 18, 'b', "Table_FE1156", [
  "18 u8, the OTHER arm of the same loop (0xFA6707): the argument at (XIZ+8) picks this",
  "table or Table_FE1144, and both fill the same 18 RAM slots at (XHL+0x200)."]),
 (0xFE1168, 68, 'w', "Table_FE1168", [
  "34 u16, 0x0200..0x03FE.  COUNT 34 from the second loop in the same routine, which",
  "presets its counter to 0x22 = 34 at 0xFA678A and reads `lda XBC,<this> / add XBC,XIX /",
  "ld WA,(XBC)` at 0xFA6799, storing to (XHL+0x41C).",
  "This copy is nearly flat: 0x0200 once, 0x021E seven times, then 0x023C to the end."]),
 (0xFE11AC, 68, 'w', "Table_FE11AC", [
  "34 u16, the other arm of that loop (0xFA67AB), same 34 slots.  This copy is the ramp",
  "the first one flattens: 0x0200, 0x021E, 0x023C ... 0x03C2 in steps of 0x1E, twice over,",
  "then 0x03C2 and 0x03FE."]),
]

OBJ_R2 = [
 (0xFE1361, 4, 'b', "Field2Bit_Masks_b", [
  "Four 2-bit field masks, 0x03 0x0C 0x30 0xC0 -- byte-identical to Field2Bit_Masks at",
  "0xFE12AD, all 4 of 4.  Cited twice, from 0xFB9B1C and 0xFB9B32, and ROUND 4 promoted",
  "the name from Table_FE1361 because the reader PROVES they are masks and not just the",
  "same four numbers: Field2Bit_CopyField (0xFB9B11) loads T[dst], complements it and ANDs",
  "it into the destination byte (0xFB9B24/0xFB9B29) to CLEAR that field, then loads T[src]",
  "and ANDs it with the source byte (0xFB9B38/0xFB9B3A) to EXTRACT it.  The shift is not a",
  "second table here -- it is computed as 2*index (`add B,B` at 0xFB9B40).",
  "Re-checked by `python3 notes/prom_c_understanding_round4.py --names`."]),
 (0xFE1365, 8, 'b', "Table_FE1365", [
  "8 u8: 00 F5 then six zeroes.  Cited once, `lda XIX,<this>` at 0xFC1077."]),
 (0xFE136D, 9, 'b', "Table_FE136D", [
  "9 u8, a permutation of 0..8: 00 01 06 03 05 08 02 04 07.  Cited four times from",
  "0xFC2A58, 0xFC2A7A, 0xFC2A99 and 0xFC2AB6."]),
 (0xFE1376, 20, 'w', "Table_FE1376", [
  "10 s16: 0, 0, -1, -2, -3, -4, -5, -6, -7, -8.  Cited from 0xFC2C5F."]),
 (0xFE138A, 18, 'w', "Table_FE138A", [
  "9 u16: 0xF400 then 0x0000, 0x0700, 0x0C00, 0x1300, 0x1800, 0x1C00, 0x1F00, 0x2400 --",
  "i.e. a byte-valued curve in the high half of each word.  Cited from 0xFC2C7E."]),
 (0xFE139C, 18, 'w', "Table_FE139C", [
  "9 s16: 0, -5, -8, -16, -16, -16, -27, -27, -32.  Cited from 0xFC2C9D."]),
 (0xFE13AE, 20, 'w', "Table_FE13AE", [
  "10 s16: -128, -67, -51, -39, -27, -19, -11, -5, 0, 0.  Cited from 0xFC2CB2."]),
 (0xFE13C2, 20, 'w', "Table_FE13C2", [
  "10 u16, an even ramp 0x0000, 0x0000, 0x0002 ... 0x0010.  Cited from 0xFC2C93."]),
 (0xFE13D6, 202, 'w', "Curve_FE13D6", [
  "101 u16.  Entries 0..3 are 0xFFFF; then a steep decay 0xC673, 0xA560, 0x8F53 ... down to",
  "0x0001 at entry 100.  Cited once, from 0xFC3663.",
  "⚠ 101 entries is the extent between two cited bases; no reader clamp was located."]),
 (0xFE14A0, 43, 'b', "Table_FE14A0", [
  "43 u8: 7F 7F 7F, then zeroes with a single 0x01 at +0x0C.  Cited from 0xFC294D",
  "(`lda XIX,0x00FE14A0`).  Its end is fixed by the first of the four bank-name strings."]),
 (0xFE14CB, 17, 'sz', "SoundRam_BankName_S0", [
  "★ THE FOUR FLASH BANKS ARE NAMED IN THE ROM.  Four 16-character NUL-terminated strings,",
  "\"WSA SOUND RAM S0\" .. \"S3\", reached only through SoundRam_BankNamePtrs below."]),
 (0xFE14DC, 17, 'sz', "SoundRam_BankName_S1", []),
 (0xFE14ED, 17, 'sz', "SoundRam_BankName_S2", []),
 (0xFE14FE, 17, 'sz', "SoundRam_BankName_S3", []),
 (0xFE150F, 16, 'l', "SoundRam_BankNamePtrs", [
  "Four u32 pointers, and they are exactly the four string addresses above -- which is what",
  "fixes both this table's count and the strings' boundaries.  Read at 0xFC38AF",
  "(`lda XBC,0x00FE150F / add XBC,(XIZ-0x24)`), 16 characters copied per bank."]),
 (0xFE151F, 16, 'l', "SoundRam_BankBases", [
  "★ Four u32 base addresses: 0x00E80000, 0x00E90000, 0x00EA0000, 0x00EB0000 -- the four",
  "64 KiB banks whose names the table above holds.  Read at 0xFC38A2 and 0xFC39D7, in a",
  "FOUR-PASS loop (`ld D,0x04` at 0xFC3899, `dec 1,D` at 0xFC39EC) which per pass calls",
  "Flash_ReadSectorToBuffer (0xFC89AF) on the base, copies the bank name and the",
  "Str_ClearBanner text into two 16-byte display buffers, and calls Flash_ReprogramSector",
  "(0xFC876C) on the same base.",
  "★ 0xE80000-0xEBFFFF is 256 KiB -- exactly the span prom_a's Remote_E80000_Read32Blocks",
  "reads over the link (32 blocks of 0x2000)."]),
 (0xFE152F, 17, 'sz', "Str_ClearBanner", [
  "\"  --(Clear)--   \", 16 characters and a NUL, copied a byte at a time by the loop at",
  "0xFC39B6 (`cp H,0x10`) into the second display buffer while a bank is being cleared."]),
 (0xFE1540, 68, 'w', "Dev10C_StagingStruct_NotePool8Image", [
  "★ A SECOND 68-byte image of the 0x0010C000 staging struct -- the twin of",
  "Dev10C_StagingStruct_ResetImage (0xFE12CF), same length, same 34 words.",
  "NotePool8_NoteOnOff copies it into a stack buffer (`push 0x0044` at 0xFC3ED1,",
  "`lda XWA,<this>` at 0xFC3ED8, `call MemCopyWords` at 0xFC3EDE), fills five of its",
  "words from the note, and hands that buffer to Dev10C_WriteAllChanRegs at 0xFC3F17.",
  "Dev10C_ResetAllChannels does exactly the same with 0xFE12CF at 0xFB814F / 0xFB8155",
  "/ 0xFB817E, which is what makes the two images twins rather than lookalikes.",
  "★ IT DIFFERS FROM THE RESET IMAGE IN 9 OF 68 BYTES, 8 of 34 words: word 0",
  "0x1200->0xF000; word 1 (reg 0x0040) 0x0002->0x0000; word 4 (reg 0x0100)",
  "0x257C->0x017C; word 7 (reg 0x0400) 0x0000->0x0080; words 12/13/14 (regs 0x0800 /",
  "0x0840 / 0x0880) 0xFF80/0xFF00/0xFF00 -> 0xA07F/0xFF7F/0xFF7F; word 23",
  "0xFF00->0xA000.  The word->register map is notes/prom_c_tg_chanmap.py --pairs.",
  "★ Word 7 = 0x0080 is the pitch register's own half-semitone centring constant,",
  "the `add HL,0x0080` at 0xFA7F48 in Voice_ComputePitch; NotePool8_StageVoice ORs",
  "note*256 on top of it.  Word 2 = 0x8000 is register 0x0080 with the gate bit set",
  "and a zero level field, which the level cap is then OR'd into.",
  "Evidence: `push 0x0044` 0xFC3ED1, `lda XWA,0xfe1540` 0xFC3ED8, `call MemCopyWords`",
  "0xFC3EDE, `call Dev10C_WriteAllChanRegs` 0xFC3F17; the reset twin at 0xFB814F /",
  "0xFB8155 / 0xFB817E.  The 9-of-68 byte diff is recomputed from the ROM by",
  "notes/prom_c_inventory_round8.py --pool8, which prints every differing word."]),
 (0xFE1584, 7, 'b', "NotePool8_TransposeByVariant", [
  "7 SIGNED BYTES, one per variant 0..6: 0, 0, +24, -24, 0, 0, 0 -- two octaves up for",
  "variant 2, two octaves down for variant 3.",
  "COUNT 7 from the reader, not from the next cited base: NotePool8_NoteOnOff forms the",
  "variant as `and L,0x0f` (0xFC3E17) clamped by `cp L,6 / jr ULE` (0xFC3E1A) with an",
  "else-arm `ld L,0x00` (0xFC3E1E), so the index is 0..6 exactly.",
  "NotePool8_StageVoice reads this table at 0xFC3D35, adds the entry to the note byte",
  "at 0xFC3D3D, clears bit 7 at 0xFC3D42, shifts left 8 at 0xFC3D49 and ORs the result",
  "into staging word 7 at 0xFC3D4F -- the word Dev10C_WriteAllChanRegs sends to register",
  "chan+0x0400, whose unit is 1/256 semitone (FINDINGS-prom_c-dev10c-register-meanings.md",
  "sec.2).  A shift of 8 on that register is therefore one SEMITONE per count.",
  "Evidence: 0xFC3D35 the read, 0xFC3D3D the add, 0xFC3D42 the mask, 0xFC3D49 the",
  "shift, 0xFC3D4F the OR into word 7; the index bound is 0xFC3E17/0xFC3E1A/0xFC3E1E."]),
 (0xFE158B, 14, 'w', "NotePool8_LevelCapByVariant", [
  "7 u16 on the same variant index: 0x0DFF, 0x0B42, 0x0DFF, 0x0DFF, 0x0DFF, 0x0B42,",
  "0x0B42.  NotePool8_LevelFromVelocity returns min(velocity*32 + 31, this[variant]) for",
  "variant 4 (`cp D,4` at 0xFC3CC2, `sll 0x05,BC` at 0xFC3CC9, `add BC,0x001f` at",
  "0xFC3CCE, `cp BC,WA / jr LE` at 0xFC3CE2) and this[variant] unchanged for every other",
  "variant; the result is OR'd into staging word 2 at 0xFC3D73 and 0xFC3DF1, the word",
  "Dev10C_WriteAllChanRegs sends to register chan+0x0080.",
  "Both distinct values fall inside that register's measured 12-bit level span,",
  "0x0000-0x0FF4: 0x0DFF is 501 counts and 0x0B42 is 1202 counts below the top, and at",
  "the measured 256 counts per octave that is 11.8 dB and 28.3 dB down.  So they are",
  "LEVEL CAPS on the register's own log scale, one per variant.",
  "Evidence: 0xFC3CDA and 0xFC3CEC the two reads, 0xFC3CC2 the variant-4 test,",
  "0xFC3CC9/0xFC3CCE the velocity law, 0xFC3CE2/0xFC3CE4 the minimum, 0xFC3D73 and",
  "0xFC3DF1 the OR into word 2."]),
 (0xFE1599, 24, 'w', "NotePool8_Reg0040_ByPitchClass", [
  "12 u16 indexed by PITCH CLASS: 0x0000, 0x2000, 0x4000, then nine zeroes.",
  "NotePool8_StageVoice forms the index with `div C,0x0c` at 0xFC3D7A and takes the",
  "REMAINDER (`ld A,B` at 0xFC3D7D, doubled by `mul A,0x02` at 0xFC3D7F) -- the same",
  "idiom the user-scale read at 0xFA7FC5-0xFA7FD2 uses for `note mod 12`, where the",
  "remainder indexes RAM 0x00150B.  The word is stored into staging word 1 at 0xFC3D96,",
  "which Dev10C_WriteAllChanRegs sends to register chan+0x0040, and only its top nibble",
  "is ever non-zero: 0, 2, 4 in the 4-bit top field over a zero 12-bit payload",
  "(FINDINGS-prom_c-dev10c-register-meanings.md sec.4).",
  "NotePool8_StageVoice_Var1 reads ENTRY 0 of it directly, `ld BC,(0xfe1599)` at",
  "0xFC3DF4, and so always stages 0x0000 there.",
  "Evidence: 0xFC3D7A the divide, 0xFC3D7D the remainder, 0xFC3D7F the doubling,",
  "0xFC3D8B the read, 0xFC3D96 the store into word 1; 0xFA7FC5-0xFA7FD2 is the",
  "already-documented `note mod 12` use of the same idiom."]),
 (0xFE15B1, 24, 'w', "NotePool8_Reg0040_ByPitchClass_Var6", [
  "12 u16 on the same pitch-class index, used INSTEAD of NotePool8_Reg0040_ByPitchClass",
  "when the variant is 6 (`cp H,6 / jr Z` at 0xFC3D87): 0xC000, 0xE000, then ten times",
  "0xC000.  Read at 0xFC3D9B-0xFC3DA2 and stored into staging word 1 at 0xFC3DA7.",
  "Same field split as the other table: top nibble C or E, 12-bit payload zero.",
  "Evidence: 0xFC3D87 the variant test, 0xFC3D9B the read, 0xFC3DA7 the store."]),
 (0xFE15C9, 24, 'w', "NotePool8_Word0_ByPitchClass_Var1", [
  "12 u16 on the pitch-class index: 0x0000, 0x0200, 0x0400 ... 0x0E00, then 0x0E00 four",
  "more times.  NotePool8_StageVoice_Var1 reads it at 0xFC3DD8 with 2*(note mod 12) --",
  "`div C,0x0c` / `ld H,B` at 0xFC3DBD-0xFC3DC0, doubled at 0xFC3DD4 -- and ORs the word",
  "into staging word 0 at 0xFC3DE0.",
  "★ Staging word 0 is the one Dev10C_WriteAllChanRegs never sends, and whose purpose",
  "its header records as unknown.  This call path answers it: NotePool8_NoteOnOff hands",
  "word 0 to Dev10C_WriteReg_c as the VALUE for register chan+0x0000 immediately after",
  "the burst (`ld BC,(XIZ+0x92)` at 0xFC3F1B, the channel pushed at 0xFC3F1F, `call",
  "0xFB732C` at 0xFC3F27).  Dev10C_WriteAllChanRegs writes that same register with the",
  "literal 0x8100 instead.",
  "Evidence: 0xFC3DBD/0xFC3DC0 the pitch-class index, 0xFC3DD4 the doubling, 0xFC3DD8",
  "the read, 0xFC3DE0 the OR into word 0, 0xFC3F1B-0xFC3F27 the hand-off of word 0 to",
  "Dev10C_WriteReg_c.",
  "Its last byte, 0xFE15E0, is where copy A ends."]),
 (0xFE15E1, 183, 'b', "DupTail_FE15E1", [
  "183 bytes, byte-identical to 0xFE152A-0xFE15E0 -- a THIRD copy of the run that ends copy",
  "A, at delta 0xB7, with no relocation and no citation.  (The same 183 bytes appear a",
  "third time at 0xFE212F, inside copy B, at delta 0xC05 from the first.)",
  "It starts one byte inside SoundRam_BankBases' last entry, so its start is not an object",
  "boundary either -- it is where the repeat happens to begin."]),
]

# objects of the already-converted middle, 0xFE11F0-0xFE1360.  Names read off
# prom_c/wsa1_prom_c.s; --verify checks each one is a label there.
MIDDLE = [
 (0xFE11F0, 8, 'b', "Voice_KeyTable_Remapping"),
 (0xFE11F8, 15, 'b', "Voice_Search_Order_List_1"),
 (0xFE1207, 14, 'b', "Voice_Search_Order_List_2"),
 (0xFE1215, 11, 'b', "Voice_Search_Order_List_3"),
 (0xFE1220, 96, 'r6', "Voice_SearchOrder_Records"),
 (0xFE1280, 6, 'b', "BitMasks_1shl0_to_5"),
 (0xFE1286, 4, 'b', "BitMasks_EvenBits"),
 (0xFE128A, 4, 'b', "BitMasks_OddBits"),
 (0xFE128E, 16, 'w', "Words_FE128E"),
 (0xFE129E, 11, 'sz', "ExtBoard_Signature"),
 (0xFE12A9, 4, 'b', "Table_FE12A9"),
 (0xFE12AD, 4, 'b', "Field2Bit_Masks"),
 (0xFE12B1, 4, 'b', "Field2Bit_Shifts"),
 (0xFE12B5, 26, 'w', "Dev10C_GlobalRegs_ResetImage"),
 (0xFE12CF, 68, 'w', "Dev10C_StagingStruct_ResetImage"),
 (0xFE1313, 2, 'w', "Dev104_Reg0800_ResetValue"),
 (0xFE1315, 38, 'w', "Dev104_StagingStruct_StageBImage"),
 (0xFE133B, 38, 'w', "Dev104_StagingStruct_ResetImage"),
]

LAWS = {
 0xFDF7E0: (law_exp2_down, 256, 'w', 4),
 0xFDF9E0: (law_exp2_up, 128, 'w', 0),
 0xFDFAE0: (law_log2_a, 251, 'w', 1),
 0xFDFECC: (law_exp2_down101, 101, 'w', 4),
 0xFE0096: (law_lin_0096, 128, 'b', 0),
 0xFE0116: (law_lin_0116, 128, 'b', 0),
 0xFE0196: (law_lin_0196, 128, 'b', 0),
 0xFE0216: (law_lin_0196, 128, 'b', 0),
 0xFE02C9: (law_sin8, 512, 'b', 1),
 0xFE06C9: (law_sin16, 256, 'w', 8),
 0xFE08C9: (law_cos16, 256, 'w', 6),
 0xFE0AC9: (law_atan, 256, 'w', 1),
 0xFE0CC9: (law_log2, 256, 'w', 1),
 0xFE0EC9: (law_exp2, 256, 'w', 1),
}


def copyb_addr(a):
    """copy-A address -> copy-B address, from the two measured deltas."""
    if 0xFE0A6D <= a < NO_TWIN[0]:
        return a + D1
    if 0xFE1361 <= a < 0xFE15E1:
        return a + D2
    return None


def copyb_objects():
    """The copy-B object list, derived from copy A -- never typed."""
    out = [(R3_LO, 92, 'w', "MathTable_Cos_S16_256_Tail_B", 0xFE0A6D)]
    src = ([o[:4] for o in OBJ_R1 if o[0] >= 0xFE0AC9]
           + [m for m in MIDDLE]
           + [o[:4] for o in OBJ_R2 if o[0] < 0xFE15E1])
    for a, n, unit, name in src:
        b = copyb_addr(a)
        if b is None:
            continue                     # Dev104_StagingStruct_ResetImage has no twin
        out.append((b, n, unit, name + "_B", a))
    return out


# ---------------------------------------------------------------- checks
FAILED = []


def chk(cond, msg):
    print(("  ok   " if cond else "  FAIL ") + msg)
    if not cond:
        FAILED.append(msg)


def law_err(addr, law, n, unit):
    e = []
    for k in range(n):
        got = u8(addr + k) if unit == 'b' else u16(addr + 2 * k)
        want = law(k) % (256 if unit == 'b' else 65536)
        m = 256 if unit == 'b' else 65536
        d = (got - want + m // 2) % m - m // 2
        e.append(d)
    return min(e), max(e)


def verify():
    cites, _ = CEN.census(CEN.ZONE_LO, CEN.ZONE_HI)

    print("TILING")
    for lo, hi, objs, tag in ((R1_LO, R1_HI, OBJ_R1, "region 1"),
                              (R2_LO, R2_HI, OBJ_R2, "region 2")):
        a = lo
        ok = True
        for o in objs:
            ok &= (o[0] == a)
            a += o[1]
        chk(ok and a == hi, "%s: %d objects tile 0x%06X-0x%06X with no gap or overlap"
            % (tag, len(objs), lo, hi - 1))
    b = copyb_objects()
    a = R3_LO
    ok = True
    for o in b:
        ok &= (o[0] == a)
        a += o[1]
    chk(ok and a == R3_HI, "copy B: %d objects tile 0x%06X-0x%06X with no gap or overlap"
        % (len(b), R3_LO, R3_HI - 1))
    total = sum(o[1] for o in OBJ_R1) + sum(o[1] for o in OBJ_R2) + sum(o[1] for o in b)
    chk(total == 10389, "the three regions are %d bytes -- prom_c's whole remaining "
        ".incbin except the 616 deliberate ones" % total)

    print("CITATIONS -- every object start is an address prom_c's code cites")
    uncited = [o for o in OBJ_R1 + OBJ_R2 if o[0] not in cites]
    named = {0xFE14CB, 0xFE14DC, 0xFE14ED, 0xFE14FE, 0xFE15E1}
    chk(set(x[0] for x in uncited) <= named,
        "%d of %d region-1/2 objects are cited by name; the %d that are not are the four "
        "strings the pointer table points at and the unreferenced 183-byte repeat"
        % (len(OBJ_R1) + len(OBJ_R2) - len(uncited), len(OBJ_R1) + len(OBJ_R2), len(uncited)))
    starts = set(o[0] for o in OBJ_R1 + OBJ_R2) | set(m[0] for m in MIDDLE)
    inner = sorted(a for a in cites if a not in starts and (R1_LO <= a < R1_HI or R2_LO <= a < R2_HI))
    chk(not inner, "no citation lands INSIDE an object of the two EMITTED regions: %s"
        % (["0x%06X" % a for a in inner] or "none"))
    mid_inner = sorted(a for a in cites if a not in starts and MID_LO <= a < MID_HI)
    chk(len(mid_inner) == 10, "the %d interior citations in the already-converted middle are "
        "the byte-by-byte ones round 2 recorded at 0xFE12A9-0xFE12B4 and 0xFE12B7"
        % len(mid_inner))

    print("CLOSED FORMS")
    for addr, (law, n, unit, tol) in sorted(LAWS.items()):
        lo, hi = law_err(addr, law, n, unit)
        name = [o[3] for o in OBJ_R1 if o[0] == addr][0]
        chk(max(abs(lo), abs(hi)) <= tol,
            "%-24s n=%3d  err in [%+d, %+d], tolerance %d" % (name, n, lo, hi, tol))

    print("RELATIONS BETWEEN TABLES")
    chk(all(u16(0xFDFECC + 2 * k) == u16(0xFDF7E0 + 2 * (k + 155)) for k in range(1, 101)),
        "Curve_Exp2Decay_101[1..100] == Curve_Exp2Decay_256[156..255], entry for entry")
    chk(u16(0xFDFECC) == 0, "Curve_Exp2Decay_101[0] = 0, the one entry that is not shared")
    chk(all(u16(0xFDFCD6 + 2 * k) == 0x0100 for k in range(251)),
        "all 251 entries of Const_0100_251 are 0x0100 (checked, not sampled)")
    d = set((u16(0xFDFAE0 + 2 * k) - u16(0xFE0CC9 + 2 * k)) % 65536 for k in range(1, 251))
    chk(d <= {6038, 6039, 6040},
        "Curve_Log2_251[k] - MathTable_Log2_256[k] is 6039 +/- 1 for every k in 1..250")
    chk(IMG[0xFE0196 - BASE:0xFE0216 - BASE] == IMG[0xFE0216 - BASE:0xFE0296 - BASE],
        "LinCoef_FE0196 and LinCoef_FE0216 are byte-identical, all 128")
    chk(u16(0xFE08C9) == 0x8000 and (u16(0xFE08C9) >> 4) >= 0x800,
        "MathTable_Cos_S16_256[0] = 0x8000, which the reader's `sra 4` turns into -2048")

    print("THE FLASH-BANK TABLES")
    ptrs = [u32(0xFE150F + 4 * i) for i in range(4)]
    names = [0xFE14CB, 0xFE14DC, 0xFE14ED, 0xFE14FE]
    chk(ptrs == names, "the four pointers at 0xFE150F are the four string starts: %s"
        % ", ".join("0x%06X" % p for p in ptrs))
    txt = [IMG[n - BASE:n - BASE + 16].decode("ascii") for n in names]
    chk(txt == ["WSA SOUND RAM S%d" % i for i in range(4)],
        "and the strings are %s" % " / ".join(repr(t) for t in txt))
    chk(all(IMG[n - BASE + 16] == 0 for n in names), "each of the four is NUL-terminated")
    bases = [u32(0xFE151F + 4 * i) for i in range(4)]
    chk(bases == [0x00E80000, 0x00E90000, 0x00EA0000, 0x00EB0000],
        "the four bases are %s" % ", ".join("0x%08X" % b for b in bases))
    chk(IMG[0xFE152F - BASE:0xFE152F - BASE + 17] == b"  --(Clear)--   \x00",
        "Str_ClearBanner is '  --(Clear)--   ' + NUL")

    print("COPY B")
    diffs = 0
    for b_, n, unit, name, a_ in copyb_objects():
        k = sum(1 for i in range(n) if IMG[a_ - BASE + i] != IMG[b_ - BASE + i])
        diffs += k
    chk(diffs == 41, "copy B differs from copy A in %d bytes in all (41 expected: 40 "
        "relocated pointer bytes and one 0x0010C000 parameter)" % diffs)
    chk(IMG[0xFE15E1 - BASE:0xFE1698 - BASE] == IMG[0xFE152A - BASE:0xFE15E1 - BASE],
        "DupTail_FE15E1's 183 bytes are byte-identical to 0xFE152A-0xFE15E0")
    src = open(image_path(ROOT, "prom_c/wsa1_prom_c.s")).read()
    missing = [m[3] for m in MIDDLE if (m[3] + ":") not in src and m[3] != "Voice_SearchOrder_Records"]
    chk(not missing, "every mirrored middle name is a label in prom_c/wsa1_prom_c.s "
        "(Voice_SearchOrder_Records is a comment there, not a label): %s" % (missing or "none"))

    print()
    if FAILED:
        print("%d CHECK(S) FAILED" % len(FAILED))
        return 1
    print("ALL CHECKS PASSED")
    return 0


# ---------------------------------------------------------------- emit
def rows(addr, n, unit, out):
    if unit == 'b':
        for i in range(0, n, 16):
            row = IMG[addr - BASE + i:addr - BASE + min(i + 16, n)]
            out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in row)
                       + "   ; 0x%06X" % (addr + i))
    elif unit == 'w':
        for i in range(0, n // 2, 8):
            row = [u16(addr + 2 * (i + j)) for j in range(min(8, n // 2 - i))]
            out.append("\t.short\t" + ", ".join("0x%04X" % x for x in row)
                       + "   ; 0x%06X" % (addr + 2 * i))
    elif unit == 'l':
        for i in range(n // 4):
            out.append("\t.long\t0x%08X" % u32(addr + 4 * i) + "   ; 0x%06X" % (addr + 4 * i))
    elif unit == 'sz':
        s = IMG[addr - BASE:addr - BASE + n - 1].decode("ascii")
        out.append("\t.asciz\t\"%s\"" % s + "   ; 0x%06X" % addr)
    elif unit == 'r6':
        for i in range(n // 6):
            a = addr + 6 * i
            out.append("\t.long\t0x%08X" % u32(a))
            out.append("\t.byte\t0x%02x, 0x%02x   ; 0x%06X  record %2d"
                       % (u8(a + 4), u8(a + 5), a, i))
    else:
        raise SystemExit("unit?" + unit)


def cite_lines(addr, cites):
    """`cited by` lines, with the INSTRUCTION address, not the literal's."""
    back = {"add <X..>,#imm32": 2}
    out = []
    for site, shape in cites.get(addr, []):
        out.append("0x%06X [%s]" % (site - back.get(shape, 1), shape))
    return out


def emit(out):
    cites, _ = CEN.census(CEN.ZONE_LO, CEN.ZONE_HI)
    L = out.append

    def block(objs, title, banner):
        L("")
        L("; " + "=" * 76)
        L("; " + title)
        L("; " + "=" * 76)
        for ln in banner:
            L("; " + ln if ln else ";")
        L("; " + "=" * 76)
        for o in objs:
            addr, n, unit, name = o[0], o[1], o[2], o[3]
            desc = o[4] if len(o) > 4 and isinstance(o[4], list) else []
            L("")
            L("; " + "-" * 76)
            L("; %s -- 0x%06X-0x%06X  (%d bytes)" % (name, addr, addr + n - 1, n))
            if desc:
                L(";")
                for ln in desc:
                    L("; " + ln)
            c = cite_lines(addr, cites)
            if c:
                L(";")
                L("; Cited by: " + ", ".join(c))
            L("; " + "-" * 76)
            L(name + ":")
            rows(addr, n, unit, out)

    block(OBJ_R1, "0xFDF7E0-0xFE11EF -- THE TAIL DATA ZONE, PART 1: 26 objects",
          ["Generated by notes/gen_prom_c_tail_tables.py --emit; every number is read out of",
           "the ROM by that script and re-proved by `--verify`.  Nothing here is retyped.",
           "",
           "★ FIVE 256-ENTRY MATH TABLES END TO END: sin (0xFE06C9), cos (0xFE08C9), atan",
           "(0xFE0AC9), log2 (0xFE0CC9) and exp2 (0xFE0EC9), each 0x200 bytes after the last,",
           "each cited by its own `add <X..>,#imm32`, and each matching a closed form over all",
           "256 entries.  Their readers are four 38-to-66-byte routines at 0xFC419D, 0xFC41C3,",
           "0xFC41E9 and 0xFC4227 that work in Q11 fixed point -- 2048 = 1.0, angles in units",
           "of 1/2048 radian.",
           "",
           "★ THE COSINE TABLE RUNS THROUGH 0xFE0A6D, which round 2 called the start of the",
           "duplicated initialiser image.  That address is a boundary of the DUPLICATION, not",
           "of an object: the table's exclusive end, 0xFE0AC9, is cited by an instruction.",
           "",
           "⚠ Round 2 wrote that this range had \"no established object boundaries\" and that",
           "the earliest citation into it was 0xFE1168.  That was an artefact of a classifier",
           "that did not know the `add <X..>,#imm32` shape -- see notes/prom_c_tail_census.py",
           "--corrections, which prints the eight citations it could not see."])

    block(OBJ_R2, "0xFE1361-0xFE1697 -- THE TAIL DATA ZONE, PART 2: 24 objects",
          ["★ THE FOUR FLASH BANKS ARE NAMED HERE.  \"WSA SOUND RAM S0\" .. \"S3\" at 0xFE14CB,",
           "a pointer table at 0xFE150F and the bases 0x00E80000/0x00E90000/0x00EA0000/",
           "0x00EB0000 at 0xFE151F, walked together four times by the loop at 0xFC3899 around",
           "Flash_ReadSectorToBuffer and Flash_ReprogramSector.",
           "",
           "The last 183 bytes are a third copy of the run that ends copy A; see the object."])

    bobjs = [(b, n, unit, name, [
        "Byte-identical to %s (0x%06X), %d bytes, except %d byte(s)."
        % (name[:-2], a, n, sum(1 for i in range(n) if IMG[a - BASE + i] != IMG[b - BASE + i])),
        "Copy-B address = copy-A address + 0x%03X." % (b - a)])
        for (b, n, unit, name, a) in copyb_objects()]
    block(bobjs, "0xFE1698-0xFE21E5 -- COPY B OF THE INITIALISER IMAGE, 2,894 bytes",
          ["The second, relocated copy of 0xFE0A6D-0xFE15E0.  Its objects are ITS TWIN'S,",
           "named `<twin>_B`; the boundaries are the twin's boundaries plus the measured",
           "delta (0xC2B below the 38-byte object at 0xFE133B, which copy B does not have,",
           "and 0xC05 above it -- notes/prom_c_dup_image.py --extent).",
           "",
           "Copy B differs from copy A in exactly 41 bytes: 40 of them are the low bytes of",
           "24-bit pointers rewritten to point inside copy B, and the 41st is the word at",
           "0xFE12C9 -- item 10 of Dev10C_GlobalRegs_ResetImage, which goes to GLOBAL register",
           "0x0C04 of the 0x0010C000 device -- which is 0x0030 in copy A and 0x0020 here.",
           "",
           "⚠ NOTHING CITES COPY B.  `python3 notes/prom_c_tail_census.py --copyb` searches",
           "every 24-bit literal in the image against every address in it and finds none in an",
           "address-operand position.  Literals only: a pointer built at run time would be",
           "invisible.  The names below are a statement about the BYTES, not about reachability.",
           "",
           "The first object is only PART of a twin: copy B begins 92 bytes before the cosine",
           "table ends, so its first 92 bytes are that table's tail."])
    L("")


def census():
    cites, noise = CEN.census(CEN.ZONE_LO, CEN.ZONE_HI)
    for tag, objs in (("region 1", OBJ_R1), ("region 2", OBJ_R2)):
        print("%s: %d objects, %d bytes" % (tag, len(objs), sum(o[1] for o in objs)))
        for o in objs:
            print("  0x%06X  %5d B  %-2s  %-28s  %d citation(s)"
                  % (o[0], o[1], o[2], o[3], len(cites.get(o[0], []))))
    b = copyb_objects()
    print("copy B: %d objects, %d bytes" % (len(b), sum(o[1] for o in b)))


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--census" in sys.argv:
        census()
    elif "--emit" in sys.argv:
        buf = []
        emit(buf)
        print("\n".join(buf))
    else:
        print(__doc__)
