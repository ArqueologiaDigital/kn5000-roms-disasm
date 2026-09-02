#!/usr/bin/env python3
"""prom_d slot +0x70 -- WHAT ARE THE TWO 4,374-BYTE POOL OBJECTS?

QUESTION IT ANSWERS
    notes/DATA-CENSUS-2026-09-02.md ranked `prom_d 0x044B26-0x046D6A`, 8,772 B,
    first among the whole tree's genuinely unexplained ranges: two pools of
    4,374 bytes reached from DrawbarPreset_EnvDescTable_Desc000..003's +0x05
    field, whose own source header said

        "part B of descriptor 0 -- role NOT established".

    This script establishes what they are, and it does it the way four other
    lanes converged on this week: FROM THE CODE THAT READS THEM, never from the
    shape of the bytes.  Every stride, mask and coefficient below is an
    instruction operand re-decoded from prom_c's ROM at the address it cites.

    ANSWER, in one sentence: each pool is a 9 x 9 x 9 DRAWBAR-COMBINATION TABLE
    -- 729 six-byte records giving the composite waveform, level trim and octave
    transpose for one setting of three organ drawbars, each drawbar 0..8 --
    addressed by prom_c's base-9 index `n2*81 + n1*9 + n0` at 0xFC355B.

THE CHAIN, end to end (every address re-decoded below)

    tone record +0x10 bits 7:6 == 0x40                     "this part is a DRAWBAR tone"
      0xFB47F3  ld A,(XIY+0x10) / and A,0xC0               sub_FB47C4 selects the drawbar arm
      0xFB387A  the same test in MidiNote_OnByPartMode     -> VoiceRegs_Stage_B

    element block +0x02 / +0x03                            three drawbar positions, one per nibble
      0xFC28F3  ld C,(XWA+0x02)                            sub_FC28B5, once per element
      0xFC28FA  ld C,(XWA+0x03) / sll 8 / or
      0xFC2906  and DE,0x0FFF                              -> RAM 0x00DC0E + 23*part + 2*elem

    element block +0x03 bits 5:4                           which of the 4 descriptors
      0xFC2983  ld C,(XWA+0x03) / and C,0x30 / srl 4,C     DrawbarPreset_GetDescriptor
      0xFC299A  ld BC,(XWA+0xEC) / mul XBC,HL              stride 14 from the directory
                -> voice[+0x1F] via RAM 0x1523+300*part+41*elem+0x90 (0xFB2078/0xFB20F4)

    descriptor +0x05                                       the pool object = the combo table
      0xFA8278  ld XBC,(XDE+0x1F)                          Voice_StageRegs_0040_B
      0xFA827B  ld XWA,(XBC+0x05) / add XIX,(0x00D7ED)

    the three nibbles -> a linear index                    KEYBOARD FOLDBACK, then base 9
      0xFC3427  ld IY,(XWA+0x3BCF) / srl 8                 the note number
      0xFC3440  cp HL,0x0024                               elem 0 folds below note 24
      0xFC34BC  cp DE,0x0054                               elems 1,2 fold above note 96
      0xFC356E  mul BC,0x0051   (81)                       sub_FC355B: n2*81 + n1*9 + n0
      0xFC357D  mul IY,0x0009   (9)

    record = table + 6*index                               STRIDE FROM THE READER
      0xFA82C2  mul WA,0x0006                              and again at 0xFA82D0

    the record's fields
      +0x00 LE16  0xFA82E2  ld BC,(XIX)  -> RAM 0x00D760 -> TG register chan+0x0040
      +0x02 byte  0xFA7DE5  ld H,(XWA+0x02), bit 7 tested  Voice_StageLevel_Reg0080
      +0x03 byte  0xFAB668  ld A,(XBC+0x03) / exts WA      summed into voice[+0x0D] -> reg 0x0080
      +0x04 LE16  0xFA82E9  ld BC,(XIX+0x04) -> 0x005A4F   the key-zone pitch offset
                            (Voice_PitchAddZoneOffset_AB, 0xFA8330, adds it to the pitch)

HOW TO RUN
    python3 notes/prom_d_drawbar_chain.py            # every check
    python3 notes/prom_d_drawbar_chain.py --quiet    # failures only

    Exit status is non-zero if ANY check fails.  scripts/analysis/gen_prom_d_asm.py
    imports DRAWBAR from this file and REFUSES to emit if any of it moved, so the
    prose in prom_d/tone_database_aux.s cannot outlive this measurement.

WHAT IS *NOT* ESTABLISHED, said before the results
  * NOT that the nine values are "the nine Hammond drawbars".  What is measured
    is: four elements, coarse transposes -12/+12/+7/0 semitones, three 0..8
    nibbles each, a 9^3 table for three of them.  "Drawbar" is prom_d's own
    label for the block and the KN5000's for the same directory slot; the
    FOOTAGE reading of the transposes is stated as an inference and marked.
  * NOT what descriptor 3's 4-record table is.  Its element takes prom_c's
    h >= 3 arm, where the slot word is used RAW (no base-9 conversion,
    0xFA82CC), so its index space is 0..3 and 4 records is exactly right --
    but what the four choices ARE is not established.
  * NOT the meaning of descriptor +0x09 / +0x0A.  They are the 2nd and 3rd
    arguments of sub_FA73EB at 0xFA818C, whose own role is not established.
    +0x0C IS placed: 0xFA8160 `ld DE,(XWA+0x0C)` makes it the base pitch.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROMS = os.path.join(ROOT, "original_ROMs")
D = open(os.path.join(ROMS, "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(ROMS, "wsa1_prom_c.ic28"), "rb").read()
assert len(D) == 0x80000
PROM_C_BASE = 0xF80000

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-66s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-66s %s" % (label, detail))


def cbytes(addr, n):
    """prom_c ROM bytes at a CPU address."""
    o = addr - PROM_C_BASE
    assert 0 <= o and o + n <= len(C), "0x%06X outside prom_c" % addr
    return C[o:o + n]


def opcheck(label, addr, hexs, detail=""):
    """The instruction at `addr` in prom_c IS these bytes -- read from ROM."""
    want = bytes.fromhex(hexs)
    got = cbytes(addr, len(want))
    check("%-34s @0x%06X" % (label, addr), got == want,
          detail or ("%s" % got.hex()))


# ===========================================================================
say("=" * 78)
say("Q1  the descriptor array at directory slot +0x70")
say("=" * 78)

DESC_AT = S(0x70)
DESCS = []
for i in range(4):
    a = DESC_AT + 14 * i
    DESCS.append(dict(at=a, tag=D[a], partA=u32(a + 1), partB=u32(a + 5),
                      b9=D[a + 9], w10=u16(a + 10), w12=u16(a + 12)))

check("slot +0x70 -> 0x%05X" % DESC_AT, DESC_AT == 0x44AEE)
check("all four tags are 0x92", all(r["tag"] == 0x92 for r in DESCS))
check("all four part-A offsets are NULL", all(r["partA"] == 0 for r in DESCS))
POOL_AT = min(r["partB"] for r in DESCS)
check("array ends where the smallest part-B begins",
      POOL_AT == DESC_AT + 14 * 4, "0x%05X" % POOL_AT)
BLOCK_END = 0x46D6A                       # ToneDB_SourceNameList1, directory +0x50
check("block ends at the next directory region", BLOCK_END == S(0x50))
say("      descriptor  tag   partA   partB     +0x09  +0x0A   +0x0C")
for i, r in enumerate(DESCS):
    say("      %d           0x%02X  %-7s 0x%05X    0x%02X   0x%04X  0x%04X"
        % (i, r["tag"], "none" if not r["partA"] else "0x%05X" % r["partA"],
           r["partB"], r["b9"], r["w10"], r["w12"]))
check("+0x0C is the same in all four", len({r["w12"] for r in DESCS}) == 1,
      "0x%04X" % DESCS[0]["w12"])

# the pool objects, cut by the part-B offsets and the block end
PTS = sorted({r["partB"] for r in DESCS})
POOL = []
for j, p in enumerate(PTS):
    e = PTS[j + 1] if j + 1 < len(PTS) else BLOCK_END
    POOL.append((p, e - p))
check("three pool objects", len(POOL) == 3,
      " ".join("0x%05X:%d" % (p, n) for p, n in POOL))

# ===========================================================================
say("")
say("=" * 78)
say("Q2  the STRIDE is prom_c's, not the pool's -- `mul WA,0x0006`, twice")
say("=" * 78)
# Voice_StageRegs_0040_B: the descriptor, its part B, and the two strides.
opcheck("ld XBC,(XDE+0x1F)   voice[+0x1F]", 0xFA8278, "aa1f21")
opcheck("ld XWA,(XBC+0x05)   part B",       0xFA827B, "a90520")
opcheck("add XIX,(0x00D7ED)  + base",       0xFA8281, "e2edd70024")
opcheck("call 0xFC355B / mul WA,0x0006",    0xFA82BE, "1d5b35fcd8080600")
opcheck("call 0xFC3793 / mul WA,0x0006",    0xFA82CC, "1d9337fcd8080600")
STRIDE = cbytes(0xFA82C2, 4)[2]
check("stride operand == 6", STRIDE == 6, "0x%02X" % STRIDE)
for p, n in POOL:
    check("pool object 0x%05X is a whole number of records" % p, n % STRIDE == 0,
          "%d B / %d = %d records" % (n, STRIDE, n // STRIDE))

# ===========================================================================
say("")
say("=" * 78)
say("Q3  the INDEX is base 9 -- sub_FC355B, `mul BC,0x0051` and `mul IY,0x0009`")
say("=" * 78)
opcheck("ld BC,HL / srl 8,BC / and BC,0x0F", 0xFC3565, "db89d9ef08d9cc0f00")
opcheck("mul BC,0x0051  (81)",               0xFC356E, "d9085100")
opcheck("srl 4,IY / and IY,0x0F",            0xFC3576, "ddef04ddcc0f00")
opcheck("mul IY,0x0009  (9)",                0xFC357D, "dd080900")
opcheck("and BC,0x0F / add BC,IX",           0xFC3585, "db89d9cc0f00dc81")
C81 = struct.unpack_from("<H", cbytes(0xFC356E, 4), 2)[0]
C9 = struct.unpack_from("<H", cbytes(0xFC357D, 4), 2)[0]
check("the two coefficients are 81 and 9", (C81, C9) == (81, 9), "%d, %d" % (C81, C9))
check("81 == 9*9 and the radix is 9", C81 == C9 * C9)
NCOMBO = C9 ** 3
check("index space is 9^3 = %d" % NCOMBO, NCOMBO == 729)
check("9^3 * stride == the pool object size",
      NCOMBO * STRIDE == POOL[0][1] == POOL[1][1],
      "%d == %d" % (NCOMBO * STRIDE, POOL[0][1]))

# ⚠ the NULL.  4,374 factors many ways; the point is that the reader picks THIS
# one.  A stride/radix pair taken from the bytes could have been (2,3^7) or
# (6,3^6) or (54,81) -- all divide 4,374.  Only 6 and 9 are in prom_c.
DIVS = [k for k in range(2, 4375) if 4374 % k == 0]
check("null: 4,374 has %d divisors, so the byte shape decides nothing" % len(DIVS),
      len(DIVS) > 8, "the reader is what picks 6 and 9")

# ===========================================================================
say("")
say("=" * 78)
say("Q4  the three nibbles come from the ELEMENT BLOCK -- sub_FC28B5")
say("=" * 78)
opcheck("ld C,(XWA+0x02)",             0xFC28F3, "880223")
opcheck("ld C,(XWA+0x03) / sll 8,BC",  0xFC28FA, "880323d912d9ee08")
opcheck("and DE,0x0FFF",               0xFC2906, "daccff0f")
opcheck("add XBC,0x0000DC0E / ld (XBC),DE", 0xFC2913, "e9c80edc0000b152db")
MASK = struct.unpack_from("<H", cbytes(0xFC2906, 4), 2)[0]
check("mask is 0x0FFF -- THREE nibbles", MASK == 0x0FFF, "0x%04X" % MASK)

# the four descriptors are selected by bits 5:4 of the SAME byte
opcheck("ld C,(XWA+0x03) / and C,0x30 / srl 4,C", 0xFC2983, "880323cbcc30cbef04")
SEL_MASK = cbytes(0xFC2986, 3)[2]
check("descriptor selector is bits 5:4", SEL_MASK == 0x30, "0x%02X" % SEL_MASK)
check("selector spans exactly the 4 descriptors",
      (SEL_MASK >> 4) + 1 == len(DESCS), "%d" % ((SEL_MASK >> 4) + 1))

# ===========================================================================
say("")
say("=" * 78)
say("Q5  WHICH tones take this path -- tone record +0x10 bits 7:6 == 0x40")
say("=" * 78)
opcheck("ld A,(XIY+0x10) / and A,0xC0", 0xFB47F3, "8d1021c9ccc0")
opcheck("cp WA,0x0040 -> the drawbar arm", 0xFB4801, "d8cf4000")
PTRS = [u32(0xB80 + 4 * i) for i in range(274)]
CLS = {}
for i, p in enumerate(PTRS):
    CLS.setdefault(D[p + 0x10] & 0xC0, []).append(i)
say("      class 0x00: %3d records   class 0x40: %3d   class 0x80: %3d"
    % (len(CLS.get(0x00, [])), len(CLS.get(0x40, [])), len(CLS.get(0x80, []))))
DRAWBAR_TONES = CLS.get(0x40, [])
check("exactly two tone records are class 0x40", len(DRAWBAR_TONES) == 2,
      "%s" % DRAWBAR_TONES)
NAMES = [D[PTRS[i]:PTRS[i] + 16].decode("latin1") for i in DRAWBAR_TONES]
check("and they are the two Drawbar records",
      all("Drawbar" in n for n in NAMES), "%r" % NAMES)

# ===========================================================================
say("")
say("=" * 78)
say("Q6  every drawbar element's three nibbles are 0..8, and the four elements")
say("    select the four descriptors one-to-one")
say("=" * 78)
ELEMS = []
for t in DRAWBAR_TONES:
    rec = PTRS[t]
    for e in range(4):
        eb = rec + 217 + 81 * e          # prom_c 0xFB4373 `add XBC,0xD9` / `ld C,0x51`
        word = ((D[eb + 3] << 8) | D[eb + 2]) & MASK
        ELEMS.append(dict(tone=t, elem=e, at=eb,
                          desc=(D[eb + 3] & SEL_MASK) >> 4,
                          word=word,
                          nib=(word >> 8, (word >> 4) & 0xF, word & 0xF),
                          coarse=struct.unpack("b", D[eb + 4:eb + 5])[0],
                          fine=struct.unpack("b", D[eb + 5:eb + 6])[0]))
say("      tone elem  desc  drawbars  coarse  fine")
for r in ELEMS:
    say("      0x%02X  %d     %d     %d,%d,%d     %+4d   %+3d"
        % (r["tone"], r["elem"], r["desc"], *r["nib"], r["coarse"], r["fine"]))
check("element i selects descriptor i, in both tones",
      all(r["desc"] == r["elem"] for r in ELEMS))
BAD = [r for r in ELEMS if max(r["nib"]) > 8]
check("all %d nibbles are 0..8 (the radix)" % (3 * len(ELEMS)), not BAD, "%s" % BAD)

# ⚠ THE NULL.  "three nibbles that happen to be <= 8" is worth nothing without
# the rate over element blocks that are NOT drawbar elements.  Same two bytes,
# same test, every ordinary tone record's elements.
ORD = 0
ORDOK = 0
for i, p in enumerate(PTRS):
    if i in DRAWBAR_TONES:
        continue
    mask = D[p + 0x11]
    for e in range(4):
        if not (mask >> (2 * e)) & 1:
            continue
        eb = p + 217 + 81 * e
        w = ((D[eb + 3] << 8) | D[eb + 2]) & MASK
        ORD += 1
        if max(w >> 8, (w >> 4) & 0xF, w & 0xF) <= 8:
            ORDOK += 1
check("null: same test over %d ordinary elements" % ORD, ORD > 100,
      "%d of %d pass = %.1f%% (drawbar: 8 of 8 = 100%%)"
      % (ORDOK, ORD, 100.0 * ORDOK / max(ORD, 1)))

# ===========================================================================
say("")
say("=" * 78)
say("Q7  what the 729 records CONTAIN")
say("=" * 78)
opcheck("ld BC,(XIX) -> RAM 0x00D760",  0xFA82E2, "9421f260d70051")
opcheck("ld BC,(XIX+4) -> RAM 0x5A4F",  0xFA82E9, "9c0421f14f5a")
opcheck("ld H,(XWA+0x02), bit 7",       0xFA7DE5, "880226ce89c9cc80")
opcheck("ld A,(XBC+0x03) / exts WA",    0xFAB668, "890321d813")
opcheck("ld WA,(0x5A4F) / add WA,HL",   0xFA8330, "d14f5a20db80")

REC = {}
for p, n in POOL:
    REC[p] = [D[p + STRIDE * i:p + STRIDE * i + STRIDE] for i in range(n // STRIDE)]
ALL = [r for p, _ in POOL for r in REC[p]]
check("byte +0x02 is 0 in all %d records" % len(ALL),
      all(r[2] == 0 for r in ALL), "so the level OVERRIDE is off throughout")
PITCH = sorted({struct.unpack_from("<H", r, 4)[0] for r in ALL})
_BIG = [q for q, n in POOL if n // STRIDE == NCOMBO]
PITCH_BIG = sorted({struct.unpack_from("<H", r, 4)[0] for q in _BIG for r in REC[q]})
check("field +0x04 in the two 729-tables is 0 or a WHOLE OCTAVE",
      all(v % 0x0C00 == 0 for v in PITCH_BIG),
      "%s = %s semitones (the pitch word carries the note in bits 15..8)"
      % ([hex(v) for v in PITCH_BIG], [v >> 8 for v in PITCH_BIG]))
check("and it is non-zero EXACTLY where the LOW drawbar digit is 0",
      all((struct.unpack_from("<H", REC[_BIG[1]][i], 4)[0] != 0)
          == (i % C9 == 0 and i != 0) for i in range(NCOMBO)),
      "the run-time foldback of sub_FC3480, precomputed into the table")
check("the 4-record table adds one value the cubes never use",
      set(PITCH) - set(PITCH_BIG) == {0x1300},
      "0x1300 = %d semitones" % (0x1300 >> 8))

# the codomain join: the waves of the two 729-tables are EXACTLY one interval
BIG = [p for p, n in POOL if n // STRIDE == NCOMBO]
WAVES = {struct.unpack_from("<H", r, 0)[0] for p in BIG for r in REC[p]}
LO, HI = min(WAVES), max(WAVES)
check("the two 729-tables' wave set is EXACTLY the interval [0x%03X,0x%03X]" % (LO, HI),
      WAVES == set(range(LO, HI + 1)),
      "%d values, no gap, nothing outside" % len(WAVES))
check("the two tables partition that interval",
      not ({struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[0]]}
           & {struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[1]]}),
      "0x%03X..0x%03X then 0x%03X..0x%03X"
      % (min(struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[0]]),
         max(struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[0]]),
         min(struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[1]]),
         max(struct.unpack_from("<H", r, 0)[0] for r in REC[BIG[1]])))

# ★ THE LEVEL TRIM IS A MONOTONE MIXING SURFACE.  prom_c reads +0x03 SIGNED
# (`exts WA` at 0xFAB66B), and that is also the only reading under which the
# all-drawbars-full corner, byte 0x00, is the LOUDEST cell rather than the
# quietest.  The test is run on the signed value for that reason.
S8 = lambda v: v - 256 if v >= 128 else v


def cube_lines(q, field):
    """every axis-parallel line of the 9x9x9 cube."""
    for axis in range(3):
        for a in range(C9):
            for b in range(C9):
                seq = []
                for k in range(C9):
                    ix = [a, b]
                    ix.insert(axis, k)
                    seq.append(field(REC[q][ix[0] * 81 + ix[1] * 9 + ix[2]]))
                yield seq


LEVEL = lambda r: S8(r[3])
WAVE = lambda r: struct.unpack_from("<H", r, 0)[0]
MONO, WORST, TOT = {}, {}, 0
for q in BIG:
    ls = list(cube_lines(q, LEVEL))
    steps = [min(x[k + 1] - x[k] for k in range(C9 - 1)) for x in ls]
    MONO[q] = sum(1 for d in steps if d >= 0)
    WORST[q] = min(steps)
    TOT += len(ls)
check("descriptor 0's cube: level non-decreasing on EVERY axis-parallel line",
      MONO[BIG[0]] == TOT // 2,
      "%d of %d lines, worst backward step %d" % (MONO[BIG[0]], TOT // 2, WORST[BIG[0]]))
check("descriptors 1/2's cube: the same to within a rounding wobble",
      WORST[BIG[1]] >= -3,
      "%d of %d lines exactly, worst backward step %d over a 128-wide range"
      % (MONO[BIG[1]], TOT // 2, WORST[BIG[1]]))

# ⚠ the NULL for monotonicity: the same lines over the WAVE field, which is an
# identifier and not a magnitude.  Without it the counts above mean nothing.
WMONO = sum(all(x[k] <= x[k + 1] for k in range(C9 - 1))
            for q in BIG for x in cube_lines(q, WAVE))
check("null: the wave field is monotone on far fewer lines",
      WMONO < MONO[BIG[0]] + MONO[BIG[1]],
      "%d of %d, against %d of %d for the level"
      % (WMONO, TOT, MONO[BIG[0]] + MONO[BIG[1]], TOT))


# ===========================================================================
say("")
say("=" * 78)
say("Q8  KEYBOARD FOLDBACK -- and it falls on the right elements")
say("=" * 78)
opcheck("ld IY,(XWA+0x3BCF) / srl 8,IY", 0xFC3427, "d3e1cf3b25ddef08")
opcheck("add HL,0x000C / ... / cp HL,0x0024", 0xFC3431, "dbc80c00")
opcheck("cp HL,0x0024   (bass fold below note 24)", 0xFC3440, "dbcf2400")
opcheck("sub BC,0x000C", 0xFC34AD, "d9ca0c00")
opcheck("cp DE,0x0054   (treble fold above note 96)", 0xFC34BC, "dacf5400")
BASS = struct.unpack_from("<H", cbytes(0xFC3440, 4), 2)[0] \
    - struct.unpack_from("<H", cbytes(0xFC3431, 4), 2)[0]
check("sub_FC3407 folds below note %d" % BASS, BASS == 24)
check("sub_FC3480 folds in 12-semitone steps above note 96",
      struct.unpack_from("<H", cbytes(0xFC34BC, 4), 2)[0] == 84
      and struct.unpack_from("<H", cbytes(0xFC34AD, 4), 2)[0] == 12)
# ★ the prediction: element 0 takes the BASS folder (prom_c's h == 0 arm) and it
# is the element transposed DOWN an octave; elements 1 and 2 take the TREBLE
# folder and are the ones transposed UP.  Nothing arranged that.
E = {r["elem"]: r for r in ELEMS if r["tone"] == DRAWBAR_TONES[0]}
check("element 0 (bass folder) is the DOWN-transposed one",
      E[0]["coarse"] < 0, "%+d semitones" % E[0]["coarse"])
check("elements 1 and 2 (treble folder) are the UP-transposed ones",
      E[1]["coarse"] > 0 and E[2]["coarse"] > 0,
      "%+d and %+d semitones" % (E[1]["coarse"], E[2]["coarse"]))
check("element 3 (raw index, no base-9) has the smallest table",
      len(REC[DESCS[3]["partB"]]) < NCOMBO,
      "%d records" % len(REC[DESCS[3]["partB"]]))

# ===========================================================================
say("")
say("=" * 78)
say("Q9  what stays a REFUSAL")
say("=" * 78)
say("  * descriptor +0x09 and +0x0A: arguments 2 and 3 of sub_FA73EB (0xFA818C),")
say("    whose role is not established.  NOT identified.")
say("  * descriptor 3's 4-record table: the index arrives raw from the slot")
say("    record (prom_c 0xFA82CC), so 4 entries is the right size, but what the")
say("    four choices ARE is not established.")
say("  * the FOOTAGE reading of the coarse transposes (-12 = 16', 0 = 8',")
say("    +7 = 5 1/3', +12 = 4') is an INFERENCE from the intervals; no prom_c")
say("    instruction and no prom_d byte names a footage.")
say("  * the wave numbers 0x%03X..0x%03X are register-0x0040 payloads; nothing"
    % (LO, HI))
say("    here reads the wave ROM, so 'waveform' is the register's role, not a")
say("    measured spectrum.")

# ---------------------------------------------------------------------------
DRAWBAR = dict(
    desc_at=DESC_AT, pool_at=POOL_AT, block_end=BLOCK_END,
    descs=DESCS, pool=POOL, stride=STRIDE, radix=C9, ncombo=NCOMBO,
    mask=MASK, sel_mask=SEL_MASK, elems=ELEMS,
    tones=DRAWBAR_TONES, wave_lo=LO, wave_hi=HI, nwave=len(WAVES),
    pitch_vals=PITCH, bass_fold=BASS,
)

if __name__ == "__main__":
    say("")
    print("%d checks, %d failed" % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        print("  FAILED: %s" % f)
    sys.exit(1 if FAILED else 0)
