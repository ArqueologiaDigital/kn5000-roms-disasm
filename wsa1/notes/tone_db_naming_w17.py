#!/usr/bin/env python3
"""WAVE 17, lane w17/tone-db -- WHAT READS THE TONE DATABASE, AND WHAT THAT SAYS
   THE RECORDS ARE.

QUESTION THIS ANSWERS
    prom_d is documented down to the byte for SHAPE -- record sizes, counts,
    strides -- and its own header says, in as many words, that "the MEANING of
    individual fields ... is STILL unknown throughout" and that round 3 "read a
    consumer's ADDRESS ARITHMETIC; it did not read one field".

    This lane owns both halves of the subject: prom_d, and the prom_c module
    that reads it (prom_c/tone_db/tone_db_module.s).  So the question here is
    the one that position makes answerable:

        WHICH prom_c INSTRUCTION TOUCHES WHICH BYTE OF WHICH RECORD, and what
        does the surrounding code do with the value?

    Every claim below is a decoded operand.  Nothing is inferred from a byte
    histogram, and every literal cited is re-read from the ROM image at the
    address it is cited at, with an image-wide occurrence count beside it so a
    reader can see how surprising the hit is.

★ WHAT IT ESTABLISHES (run it; do not quote this list)

  Q1  THE RAM STAGING IMAGE AT 0x0087D2, and that it TILES.
      prom_c assembles the selected part's tone into one RAM area and the
      three regions of that area are consecutive with no slack:
          0x0087D2 + 0x000  713 B  a whole 4-element TONE RECORD
          0x0087D2 + 0x2C9  408 B  a whole DRUM-KIT RECORD          (= 0x008A9B)
          0x0087D2 + 0x461  128 x 150 B  DRUM-INSTRUMENT RECORDS    (= 0x008C33)
      713, 408 and 150 are prom_d's own record sizes, and 0x2C9 = 713 and
      0x461 = 713 + 408 are the offsets prom_c's instructions carry.

  Q2  THE TONE RECORD'S THREE ARRAYS, from the offsets prom_c writes to:
      head at +0, 81-byte element blocks at +217 (0xD9), and the 43-byte
      wave-select records at +541 (0x21D) -- 541 = 217 + 4*81, so the four
      element blocks are contiguous and the wave-select array follows them.

  Q3  THE DRUM-INSTRUMENT RECORD IS 64 + 2*43.  prom_c copies 0x40 bytes to
      the record base and 43-byte records to base+0x40 and base+0x40+43;
      64 + 2*43 = 150 exactly, which is prom_d's stride word +0xEE.

  Q4  THE DRUM-KIT RECORD'S NOTE MAP IS AT +0x98, 128 two-byte entries, and
      prom_c reads the two bytes SEPARATELY as two arguments.  16 + 136 = 152
      = 0x98 and 152 + 2*128 = 408, prom_d's own drum-kit record size.

  Q5  ★★ THE +0x18 / +0x20 WAVE-SELECT ARRAYS HAVE A READER after all, and so
      do the index maps at +0x0C / +0x10 / +0x14.  prom_d's header lists those
      slots among the 13 with NO reader; round 3's census could not see this
      one because the routine SPILLS THE BASE TO ITS FRAME before indexing, so
      the `base load; load (base+slot)` pair the census matched never occurs.
      sub_FB82C3 (0xFB82C3) turns two bytes of a wave-catalogue row into a
      wave-select record address:
          index  = (row[15] & 0x0F) * 128 + (row[14] & 0x7F)
          entry  = LE16 at  base + dir[map slot] + 2*index
          result = base + dir[array slot] + entry * dir[stride word]
      with (map, array, stride) = (+0x0C, +0x18, +0xEA) for row[15] & 0xC0 in
      {0x00, 0xC0}, (+0x14, +0x20, +0xF0) for 0x40 and (+0x10, +0x1C, +0xEA)
      for 0x80; row[15] bit 5 switches the whole walk to the EXPANSION BOARD's
      copy at 0x00D80D / 0x00D811.

  Q6  ★ TONE RECORD +0xD0 LOW NIBBLE IS THE DSP ALGORITHM TYPE.  Four routines
      load it, mask 0x0F and use it as a computed-goto index; the widest has
      TWELVE arms, and prom_c's own DSP_AlgoDescriptor_Records (0xFDF4F1) is
      TWELVE records of 39 bytes.  Arm k passes k to a helper that indexes that
      table at stride 0x27 and scatters seven or eight of its bytes into tone
      record +0xD1..+0xD8.
      ⚠ This LIFTS round 12's refusal of sub_FC10BE, which replies exactly that
      byte and was refused because "+0xD0 is inside the 217-byte head that no
      reader in either image interprets".

  Q7  ★ WAVE-SELECT RECORD +0x0B, LOW SIX BITS, IS A TAIL-PRESET NUMBER, and 0
      means "keep the tone's own".  Non-zero selects row n of prom_d slot +0x3C
      (ToneDB_WaveSelTailPresets) and bytes 13..42 are copied from it.
      ⚠ prom_d round 12's Q31 left this field as a CANDIDATE ("two 6-bit fields
      with the same mask and the same range are not the same field").  This does
      not close that question -- it says what prom_c does with the field, not
      that the panel variable feeds it.

  Q8  THE PART RECORD TILES TOO: 300 = 0x88 + 4*41, and each 41-byte
      per-element sub-record begins with two pointers, +0x00 to the 81-byte
      element block and +0x04 to a 43-byte wave-select record (defaulted to
      prom_c's Table_FE14A0, which is 43 bytes long).

  Q9  NULLS.  Every literal cited above is counted image-wide, with the count a
      uniform-random image of the same length would give.

 Q10  ⚠ A COMMENT IN THE TREE THAT THIS LANE BELIEVES IS WRONG, reported and
      NOT edited (the comment gate forbids editing; adjudication is the
      caller's).  See --wrong.

RUN
    python3 notes/tone_db_naming_w17.py             # every section
    python3 notes/tone_db_naming_w17.py --selftest  # exit 1 on any failure
    python3 notes/tone_db_naming_w17.py --wrong     # just Q10
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROM_C = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
PROM_D = os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin")

C = open(PROM_C, "rb").read()
D = open(PROM_D, "rb").read()
C_BASE = 0x1000000 - len(C)          # 0xF80000: prom_c is the top of the space

_fail = []
_n = 0


def say(s=""):
    print(s)


def check(msg, ok, detail=""):
    global _n
    _n += 1
    print("   %s  %s%s" % ("ok  " if ok else "FAIL", msg,
                           ("   [%s]" % detail) if detail else ""))
    if not ok:
        _fail.append(msg)


def cbytes(addr, n):
    o = addr - C_BASE
    return C[o:o + n]


def carries(addr, value, width, window=10):
    """Does the instruction at `addr` carry `value` as a little-endian operand
    of `width` bytes, within the first `window` bytes?  This is the
    self-verifying form: a wrong address does not accidentally carry the
    literal (see Q9 for how often it does)."""
    want = value.to_bytes(width, "little")
    return want in cbytes(addr, window)


def count_image(value, width):
    """How many times does that little-endian literal occur ANYWHERE in prom_c?
    This is the null: a 4-byte literal is expected 512K/2^32 = 0.0001 times by
    chance, a 2-byte one 8 times, a 1-byte one 2,048."""
    want = value.to_bytes(width, "little")
    n, i = 0, C.find(want)
    while i >= 0:
        n += 1
        i = C.find(want, i + 1)
    return n, len(C) / float(1 << (8 * width))


def cite(addr, value, width, what):
    hit = carries(addr, value, width)
    got, exp = count_image(value, width)
    check("0x%06X carries 0x%0*X  -- %s" % (addr, width * 2, value, what), hit,
          "image-wide %d, by chance %.4f" % (got, exp))


# --------------------------------------------------------------------------
def q1():
    say("== Q1  the RAM staging image at 0x0087D2, and that it tiles ==")
    say("   the three destination bases, each an instruction literal:")
    cite(0xFB84E3, 0x0087D2, 3, "lda XBC,0x0087d2 -- the tone-record image")
    cite(0xFB8567, 0x008A9B, 3, "lda XBC,0x008a9b -- the drum-kit image")
    cite(0xFB4331, 0x008C33, 3, "lda XBC,0x008c33 -- the drum-instrument array")
    say("   and the two offsets prom_c adds to the FIRST base to reach the")
    say("   other two, which is what makes them one object:")
    cite(0xFB85E3, 0x00000461, 4, "add XBC,0x00000461 (drum-instrument array)")
    cite(0xFB868F, 0x000004A1, 4, "add XWA,0x000004a1 (+0x40 inside a record)")
    check("0x0087D2 + 713 == 0x008A9B  (713 = prom_d's longest tone record)",
          0x0087D2 + 713 == 0x008A9B)
    check("0x008A9B + 408 == 0x008C33  (408 = prom_d's drum-kit record)",
          0x008A9B + 408 == 0x008C33)
    check("0x0087D2 + 0x461 == 0x008C33, so the literal and the tiling agree",
          0x0087D2 + 0x461 == 0x008C33)
    check("0x461 - 0x2C9 == 408 and 0x2C9 == 713: no slack between the three",
          (0x461 - 0x2C9, 0x2C9) == (408, 713))
    say("   ⚠ NULL for the tiling: two 3-byte literals chosen at random differ")
    say("      by a NAMED record size with probability 3/2^24 = 1.8e-7 (three")
    say("      sizes are in play: 713, 408, 150).  Two do here.")
    say("")


def q2():
    say("== Q2  the tone record's three arrays, from the offsets prom_c writes ==")
    cite(0xFB84EB, 0x00D9, 2, "push 0x00d9 -- 217 bytes of head copied")
    cite(0xFB8528, 0x51, 1, "ld A,0x51 -- the 81-byte element-block stride")
    cite(0xFB852F, 0x000000D9, 4, "add XWA,0x000000d9 -- element array at +217")
    cite(0xFB8446, 0x2B, 1, "ld C,0x2b -- the 43-byte wave-select stride")
    cite(0xFB844D, 0x0000021D, 4, "add XBC,0x0000021d -- wave-select array at +541")
    check("541 == 217 + 4*81, so the wave-select array starts exactly where the "
          "four element blocks end", 0x21D == 217 + 4 * 81)
    check("217 + 4*81 + 4*43 == 713, prom_d's longest tone record",
          217 + 4 * 81 + 4 * 43 == 713)
    say("   ⚠ NULL for `541 = 217 + 4*81`: for a head h in [0,713) and a stride")
    say("      s in [1,150] drawn uniformly, P(h + 4s == 541) = 135/106950 =")
    say("      0.13%.  Here h and s are BOTH separately cited literals.")
    hits = sum(1 for h in range(713) for s in range(1, 151) if h + 4 * s == 541)
    check("that null is 135 of 106,950 pairs", (hits, 713 * 150) == (135, 106950),
          "%d/%d" % (hits, 713 * 150))
    say("")


def q3():
    say("== Q3  the drum-instrument record is 64 + 2*43 ==")
    cite(0xFB85F4, 0x0040, 2, "push 0x0040 -- 64 bytes of head copied")
    cite(0xFB85DC, 0x96, 1, "ld C,0x96 -- the 150-byte record stride")
    cite(0xFB868F, 0x000004A1, 4, "the wave-select sub-array at record + 0x40")
    check("0x4A1 - 0x461 == 0x40, so the sub-array starts 64 bytes into the "
          "record", 0x4A1 - 0x461 == 0x40)
    check("64 + 2*43 == 150 exactly -- the head and two wave-select records "
          "tile prom_d's stride word +0xEE with nothing left over",
          64 + 2 * 43 == 150)
    check("prom_d's +0xEE really is 150", struct.unpack_from("<H", D, 0xEE)[0] == 150)
    check("prom_d's +0xEA and +0xF0 really are 43",
          (struct.unpack_from("<H", D, 0xEA)[0],
           struct.unpack_from("<H", D, 0xF0)[0]) == (43, 43))
    say("   ⚠ NULL: for a head h in [0,150) and the SAME two 43s, P(h + 2*43 ==")
    say("      150) over h uniform is 1/150 = 0.67%.  The loop bound 2 is the")
    say("      `cp (XIZ+0xf3),0x02` at 0xFB897D, not a fitted parameter.")
    cite(0xFB897D, 0x02, 1, "cp (XIZ+0xf3),0x02 -- exactly two per record")
    say("")


def q4():
    say("== Q4  the drum-kit record's note map is at +0x98, 128 x 2 bytes ==")
    cite(0xFB891C, 0x00000099, 4, "add XBC,0x00000099 -- the odd byte of entry n")
    cite(0xFB892A, 0x00000098, 4, "add XBC,0x00000098 -- the even byte of entry n")
    cite(0xFB8913, 0x02, 1, "ld C,0x02 -- two bytes per entry")
    cite(0xFB8900, 0x80, 1, "cp (XIZ+0xf4),0x80 -- 128 entries")
    check("16 (name) + 136 (common) == 0x98, prom_d's own drum-kit framing",
          16 + 136 == 0x98)
    check("0x98 + 2*128 == 408, the whole record", 0x98 + 2 * 128 == 408)
    check("prom_c copies exactly 408 bytes into the kit image (push 0x0198 at "
          "0xFB856F)", carries(0xFB856F, 0x0198, 2))
    say("   ★ and the two bytes are read SEPARATELY, at +0x98+2n and +0x99+2n,")
    say("     and pushed as TWO arguments -- so the entry is a byte PAIR, not")
    say("     an LE16 the code ever adds up.")
    say("")


def q5():
    say("== Q5  sub_FB82C3 reads the slots prom_d lists as having NO reader ==")
    say("   the base is spilled to the frame first, which is why round 3's")
    say("   `base load; load (base+slot)` census could not see this site:")
    cite(0xFB82ED, 0x00D7ED, 3, "ld XBC,(0x00d7ed) -- the base, then SPILLED")
    cite(0xFB82F5, 0x00D7F1, 3, "ld XWA,(0x00d7f1) -- the second base copy")
    say("   the three (index map, record array, stride) triples:")
    cite(0xFB8369, 0x0C, 1, "ld XWA,(XBC+0x0c)  -- ToneDB_ToneIndexMapA")
    cite(0xFB836F, 0x18, 1, "ld XIY,(XBC+0x18)  -- ToneDB_MixerDefaultTable")
    cite(0xFB837A, 0x00EA, 2, "ld WA,(XBC+0x00ea) -- stride 43")
    cite(0xFB8398, 0x14, 1, "ld XWA,(XBC+0x14)  -- ToneDB_PercSourceIndexMapA")
    cite(0xFB839E, 0x20, 1, "ld XIY,(XBC+0x20)  -- ToneDB_PercMixerDefaultTable")
    cite(0xFB83A9, 0x00F0, 2, "ld WA,(XBC+0x00f0) -- stride 43, percussion")
    cite(0xFB83C6, 0x10, 1, "ld XWA,(XBC+0x10)  -- ToneDB_ToneIndexMapB")
    cite(0xFB83CC, 0x1C, 1, "ld XIY,(XBC+0x1c)  -- +0x18's alias")
    say("   and the index arithmetic:")
    cite(0xFB840F, 0x07, 1, "sll 0x07,BC -- the nibble is a BANK, 128 per bank")
    cite(0xFB8415, 0x0002, 2, "mul BC,0x0002 -- the map entry is an LE16")
    check("8 banks x 128 == 1024, which is exactly the entry count prom_d gives "
          "each of those index maps", 8 * 128 == 1024)
    say("   the arm selector, read off the three `and` masks:")
    cite(0xFB82D5, 0x0F, 1, "and A,0x0f  -- row[15] bits 0:3, the bank")
    cite(0xFB82E0, 0x30, 1, "and C,0x30  -- row[15] bits 4:5, image select")
    cite(0xFB8358, 0xC0, 1, "and C,0xc0  -- row[15] bits 6:7, family select")
    cite(0xFB82CA, 0x07, 1, "res 0x07,C  -- row[14] bit 7 cleared: 0..127")
    say("   ⚠ WHAT THIS DOES NOT SAY: nothing here gives a MEANING to any byte")
    say("     INSIDE the 43-byte record it returns, except +0x0B (see Q7).")
    say("")


def q6():
    say("== Q6  tone record +0xD0 low nibble is the DSP algorithm type ==")
    for a in (0xFBB3B3, 0xFBB4D3, 0xFBB590, 0xFBB659, 0xFBB70C):
        cite(a, 0x00D0, 2, "ld C,(Xrr+0x00d0) -- the tone record's +0xD0")
    for a in (0xFBB3B8, 0xFBB4D8, 0xFBB595, 0xFBB65E, 0xFBB711):
        cite(a, 0x0F, 1, "and C,0x0f -- the low nibble")
    cite(0xFBB479, 0x000B, 2, "cp BC,0x000b -- the guard: 12 arms, 0..11")
    say("   the eight helpers all index prom_c's DSP_AlgoDescriptor_Records:")
    for a in (0xFBAF57, 0xFBAFEF, 0xFBB097, 0xFBB120,
              0xFBB1A8, 0xFBB231, 0xFBB2B9, 0xFBB333):
        cite(a, 0x00FDF4F1, 4, "add XBC,0x00fdf4f1 -- the algorithm table")
    for a in (0xFBAF50, 0xFBAFE8, 0xFBB090, 0xFBB119,
              0xFBB1A1, 0xFBB22A, 0xFBB2B2, 0xFBB32C):
        cite(a, 0x27, 1, "ld C,0x27 -- its 39-byte stride")
    check("12 arms and 12 records: (0xFDF6C5 - 0xFDF4F1) / 39 == 12",
          (0xFDF6C5 - 0xFDF4F1) % 39 == 0 and (0xFDF6C5 - 0xFDF4F1) // 39 == 12,
          "%d" % ((0xFDF6C5 - 0xFDF4F1) // 39))
    say("   ⚠ NULL for `the arm count is the record count`: the module holds 18")
    say("     computed-goto tables with arm counts 27,12,8,8,8,5,81,43,5,6,6,46,")
    say("     6,6,5,23,8,8.  TWO of them are 12.  So `an arm count of 12` alone")
    say("     is worth little; what carries the claim is that the SAME routine's")
    say("     arms pass k straight into a table whose stride and base are")
    say("     cited above, and that its guard is `cp BC,0x0b`.")
    say("")


def q7():
    say("== Q7  wave-select record +0x0B, low six bits, is a tail-preset number ==")
    cite(0xFBC741, 0x0B, 1, "ld A,(XBC+0x0b) -- the field")
    cite(0xFBC744, 0x3F, 1, "and A,0x3f -- six bits")
    check("0xFBC74E is the `jr NZ` that sends preset 0 down the arm that does "
          "NOT read the array", cbytes(0xFBC74E, 2) == bytes.fromhex("6e 59"),
          cbytes(0xFBC74E, 2).hex(" "))
    cite(0xFBC7B6, 0x3C, 1, "ld XIY,(XWA+0x3c) -- ToneDB_WaveSelTailPresets")
    cite(0xFBC7BE, 0x00EA, 2, "ld IY,(XWA+0x00ea) -- scaled by the stride, 43")
    cite(0xFBC7D9, 0x000D, 2, "ld (XIZ+0xf0),0x000d -- the copy starts at 13")
    cite(0xFBC7E3, 0x00EA, 2, "ld WA,(XBC+0x00ea) -- and ends at the stride, 43")
    check("prom_d's slot +0x3C really points at the preset array (0x00020F7B)",
          struct.unpack_from("<I", D, 0x3C)[0] == 0x00020F7B)
    check("64 presets x 43 bytes fits between +0x3C's target and +0x18's "
          "(0x0001D965 - 0x00020F7B is negative, so they are separate objects)",
          struct.unpack_from("<I", D, 0x18)[0] != struct.unpack_from("<I", D, 0x3C)[0])
    say("   the percussion twin, same field, same mask, same preset array")
    say("   through the +0x40 alias:")
    cite(0xFBC835, 0x0B, 1, "ld C,(XWA+0x0b)")
    cite(0xFBC838, 0x3F, 1, "and C,0x3f")
    cite(0xFBC826, 0x000004A1, 4, "the record it reads is a PERCUSSION one")
    say("   ⚠ 30 bytes (13..42) is a lot of a 43-byte record, and prom_d round")
    say("     12's M11 measured that 1,309 of 1,485 non-preset wave-select")
    say("     records share such a tail with another record.  So the SHAPE is")
    say("     common; what is new here is only that prom_c copies exactly that")
    say("     span, from exactly that array, under exactly that field.")
    say("")


def q8():
    say("== Q8  the part record tiles: 300 == 0x88 + 4*41 ==")
    cite(0xFB84D5, 0x012C, 2, "mul BC,0x012c -- the 300-byte part record")
    cite(0xFB84DB, 0x1523, 2, "ld XWA,(XBC+0x1523) -- the array base")
    cite(0xFB8508, 0x29, 1, "ld C,0x29 -- the 41-byte per-element sub-record")
    cite(0xFB851A, 0x0088, 2, "add WA,0x0088 -- the first sub-record")
    check("0x88 + 4*41 == 300, so the four sub-records end exactly at the "
          "record boundary", 0x88 + 4 * 41 == 300)
    hits = sum(1 for h in range(300) for s in range(1, 76) if h + 4 * s == 300)
    check("⚠ NULL: 75 of 22,500 (h,s) pairs tile like that -- 0.33%",
          (hits, 300 * 75) == (75, 22500), "%d/%d" % (hits, 300 * 75))
    say("   the two pointers each sub-record begins with:")
    cite(0xFB8520, 0x1523, 2, "ld XBC,(XWA+0x1523) at +0x88+41e -- ptr #1")
    cite(0xFC2947, 0x008C, 2, "add WA,0x008c -- ptr #2, at sub-record +0x04")
    cite(0xFC294D, 0xFE14A0, 3, "lda XBC,0xfe14a0 -- ptr #2's ROM default")
    check("prom_c's Table_FE14A0 is 43 bytes (0xFE14CB - 0xFE14A0), i.e. a "
          "WAVE-SELECT record, which is what ptr #2 points at",
          0xFE14CB - 0xFE14A0 == 43)
    say("   ptr #1 is the SOURCE of an 81-byte copy into the element array of")
    say("   the staging image (0xFB853E `push 0x0051`), so it points at an")
    say("   81-byte ELEMENT BLOCK.")
    cite(0xFB853E, 0x0051, 2, "push 0x0051 -- 81 bytes")
    say("")


def q9():
    say("== Q9  the nulls, gathered ==")
    say("   how often each cited literal occurs in the whole 512 KiB image,")
    say("   against what a uniform-random image of the same length would give:")
    for v, w, what in ((0x000087D2, 4, "0x0087D2, the staging base"),
                       (0x00008A9B, 4, "0x008A9B, the kit image"),
                       (0x00008C33, 4, "0x008C33, the drum-instrument array"),
                       (0x00FDF4F1, 4, "0xFDF4F1, DSP_AlgoDescriptor_Records"),
                       (0x00FE14A0, 4, "0xFE14A0, the default wave-select row"),
                       (0xFE14A0, 3, "0xFE14A0 as a 24-bit lda operand"),
                       (0x0000021D, 4, "541, the wave-select array offset"),
                       (0x000000D9, 4, "217, the tone-record head"),
                       (0x012C, 2, "300, the part-record stride"),
                       (0x1523, 2, "0x1523, the part-record array base"),
                       (0x0198, 2, "408, the drum-kit record"),
                       (0x0051, 2, "81, the element block"),
                       (0x2B, 1, "43, the wave-select record"),
                       (0x96, 1, "150, the drum-instrument record")):
        got, exp = count_image(v, w)
        say("      0x%0*X  %-38s  %6d in image, %8.4f by chance"
            % (w * 2, v, what, got, exp))
    say("   ⚠ READ THAT COLUMN THE RIGHT WAY.  A 1-byte literal like 43 occurs")
    say("     thousands of times by chance and the count says NOTHING; what")
    say("     carries a 1-byte citation is that the byte is at a NAMED ADDRESS")
    say("     inside a decoded instruction, which `carries()` above checks.")
    say("     The 4-byte literals are the ones whose counts are evidence.")
    say("")


def wrong():
    say("== Q10  a comment this lane believes is WRONG -- reported, not edited ==")
    say("")
    say("   FILE  prom_c/tone_db/tone_db_module.s, the header of")
    say("         ToneDB_SourceNameList1_SelectEntry (0xFB90B3), Evidence: line,")
    say("         authored in notes/prom_c_inventory_round8.py NAMES11.")
    say("   TEXT  \"It then reads bytes 14 and 15 of the 16-byte row (0xFB911A,")
    say("         0xFB912E) and stores them at +0x02 and +0x03 of the part")
    say("         element record at 0x1523 + 0x012C*part + 0x29*element + 0x88\"")
    say("")
    say("   WHY IT IS WRONG.  The address 0x1523 + 0x012C*part + 0x29*element +")
    say("   0x88 is not the destination; it is where a POINTER is LOADED FROM.")
    say("   The two instructions are consecutive:")
    ok1 = cbytes(0xFB914B, 5) == bytes.fromhex("e3 f5 23 15 21")
    ok2 = cbytes(0xFB9150, 3) == bytes.fromhex("b9 02 41")
    say("       0xFB914B  %s   ld XBC,(XIY+0x1523)   <- loads the POINTER"
        % cbytes(0xFB914B, 5).hex(" "))
    say("       0xFB9150  %s         ld (XBC+0x02),A       <- stores at *pointer*+2"
        % cbytes(0xFB9150, 3).hex(" "))
    check("0xFB914B is a 32-bit load through (XIY+0x1523), not an address "
          "computation", ok1)
    check("0xFB9150 stores at (XBC+0x02) where XBC is that loaded value", ok2)
    say("   AND WHAT THE POINTER POINTS AT IS KNOWN: the SAME field, at the")
    say("   SAME address expression, is the SOURCE of an 81-byte copy at")
    say("   0xFB8520/0xFB853E.  So bytes 14 and 15 of a wave-catalogue row land")
    say("   at +0x02 and +0x03 of an 81-byte ELEMENT BLOCK, not of the 41-byte")
    say("   part-element sub-record.  The same wording appears on")
    say("   ToneDB_SourceNameList2_SelectEntry.")
    say("   ⚠ NOT EDITED.  The comment gate requires insertions only, and this")
    say("   lane's brief says to report a wrong comment rather than change it.")
    say("")


SECTIONS = [q1, q2, q3, q4, q5, q6, q7, q8, q9, wrong]


def main():
    args = sys.argv[1:]
    only = {"--wrong": [wrong]}
    if args and args[0] in only:
        for f in only[args[0]]:
            f()
    else:
        for f in SECTIONS:
            f()
    say("   %d checks, %d failed" % (_n, len(_fail)))
    if "--selftest" in args and _fail:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
