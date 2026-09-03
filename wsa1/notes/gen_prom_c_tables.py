#!/usr/bin/env python3
"""Emit prom_c 0xFDD2AB-0xFDF7DF -- the voice/DSP data-table zone -- as assembly.

WHAT QUESTION THIS ANSWERS. The zone is 9,525 bytes of pure tables. Hand-typing
them would be the single easiest place in this project to introduce a silent
transcription error that the byte gate would catch but that would cost hours to
localise, so the bytes are read out of the ROM and formatted mechanically. Only
the HEADERS are human text; the numbers are never retyped.

WHERE THE BOUNDARIES COME FROM -- three independent sources that agree:

 1. The KN5000 sub-CPU payload's table map (../kn5000-roms-disasm/v142/subcpu/
    subcpu_data_tables.s).  36 of the 43 tables below are BYTE-IDENTICAL to their
    KN5000 counterpart over their whole length, at the sizes that file states.
 2. The chain closes.  Laying the 43 tables end to end from 0xFDD2AB reaches
    exactly 0xFDF7DF with no gap and no overlap, and 0xFDF7E0 onward is zero fill.
    A single wrong size anywhere would desynchronise every table after it and the
    identity checks would collapse; they do not.
 3. prom_c's OWN CODE.  39 of the 43 start addresses appear in this image as a
    literal 32-bit address operand (`add XBC,0x00FDD3AB`, `ld BC,(0xFDE695)`, ...).
    That is the WSA1 firmware itself agreeing with the boundary, with no reference
    to the sibling at all.

Verify all three:  python3 notes/gen_prom_c_tables.py --verify
Emit the block:    python3 notes/gen_prom_c_tables.py

⚠ WHAT IS *NOT* ESTABLISHED. Byte identity says the DATA is the same. It does not
say the WSA1 routine that reads a table does what the KN5000 routine of that name
does. Every borrowed name is marked in its header with the sibling file:line it
came from, and no WSA1 reader has been traced except the three noted inline.
"""
import os
import struct
import subprocess
import sys

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1"
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
PAY = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
BASE = 0xF80000
DT = "v142/subcpu/subcpu_data_tables.s"

# label, addr, nbytes, unit('b'|'w'), kn5000 addr or None, sibling line or None,
# rows(count,stride,fmt) or None, header lines
SPEC = [
 ("Voice_Reg080_NoteField_Table", 0xFDD2AB, 256, 'w', 0x00FBE4, 931, None, [
  "128 u16, indexed by the played note after octave folding.",
  "Supplies bits 14..12 of a tone-generator register on the branch that does not",
  "take the zone record's own bits.  Byte-identical to the KN5000 table, and the",
  "closed form the sibling proves there holds here too, all 128 entries, no",
  "exceptions:   T[n] = floor(2 * (n mod 12) / 3) << 12",
  "-- an eight-step staircase per octave.  Referenced from 0xFA7E12.",
 ]),
 ("Voice_KeyBend_Curve_0", 0xFDD3AB, 128, 'b', None, None, None, [
  "FOUR 128-byte signed per-key bend curves, stride 0x80.  This one is curve 0.",
  "",
  "★ STRUCTURE PROVEN BY prom_c's OWN CODE, not by the sibling.  At 0xFA8016:",
  "      ld BC,DE / sra 0x08,BC        ; index = pitch accumulator >> 8",
  "      exts XBC / add XBC,0x00FDD3AB ; this table",
  "      ld A,(XBC) / exts WA          ; entry is a SIGNED byte",
  "      add DE,WA                     ; added into the pitch accumulator",
  "and again at 0xFA8032 with `add XBC,0x00000080` first -- i.e. curve 1 at",
  "0xFDD42B.  The 0x80 stride and the signed read are both read off that code.",
  "",
  "★ CURVES 0 AND 1 ARE THE KN5000's TWO s16 BEND TABLES, NARROWED TO 8 BITS.",
  "Curve 0 == low byte of Voice_KeyBend_Type41_Table (%s:966), 128/128 entries.",
  "Curve 1 == low byte of Voice_KeyBend_Type42_Table (%s:989), 128/128 entries.",
  "That is not a coincidence available to chance: the KN5000 curves span -50..+168,",
  "so their low bytes are only a smooth sequence if the curve really is the same one.",
  "",
  "⚠ CONSEQUENCE, STATED AS OBSERVED AND NOT EXPLAINED.  The KN5000 curve rises to",
  "+168; eight bits cannot hold that, and prom_c sign-extends what it reads.  So the",
  "top of this curve reads back NEGATIVE here (0xA8 -> -88) where the KN5000 reads",
  "+168.  Whether the WSA1 simply never indexes that far, or this is a narrowing bug,",
  "is NOT ESTABLISHED -- it needs the caller of 0xFA8016 traced.",
 ]),
 ("Voice_KeyBend_Curve_1", 0xFDD42B, 128, 'b', None, None, None, [
  "Bend curve 1.  Reached as Voice_KeyBend_Curve_0 + 0x80 (0xFA8032), never by a",
  "literal address -- which is why it has no reference of its own in the scan.",
  "Byte-identical to the low half of the KN5000's Voice_KeyBend_Type42_Table.",
 ]),
 ("Voice_KeyBend_Curve_2", 0xFDD4AB, 128, 'b', None, None, None, [
  "Bend curve 2.  NO counterpart in the KN5000 payload -- WSA1-only data.",
  "Same shape family as curves 0 and 1: a flat run at the bottom of the keyboard",
  "(0xEA here) and then per-key values.  Unlike curves 0/1 the body is not smooth;",
  "it reads like measured per-key tuning rather than a generated curve.",
  "Which of the four curves a voice selects is NOT YET TRACED.",
 ]),
 ("Voice_KeyBend_Curve_3", 0xFDD52B, 128, 'b', None, None, None, [
  "Bend curve 3.  NO counterpart in the KN5000 payload -- WSA1-only data.",
  "Flat 0xE4 at the bottom, then a non-smooth body, same as curve 2.",
 ]),
 ("Voice_DepthMirror_Table", 0xFDD5AB, 128, 'b', 0x00FEE4, 1010, None, [
  "128 bytes, the exact mirror i -> 0x7F - i.  Byte-identical to the KN5000 table",
  "of this name (%s:1010), where two users are documented: negative pitch-bend",
  "depths are re-mapped through it, and the normal note mapping feeds table[note]",
  "into the colour lookup.  Referenced here from 0xFA75D2, 0xFAB5D9, 0xFAB6FB.",
 ]),
 ("PitchBend_ScaleCoeff_Table", 0xFDD62B, 128, 'b', 0x00FF64, 1032, None, [
  "128 bytes, a signed coefficient (0xC0..0xFF then 0x00) multiplied by the bend",
  "depth and then right-shifted -- a slow-start magnitude curve.  Referenced from",
  "0xFA75EC.  Byte-identical to %s:1032.",
 ]),
 ("Voice_Colour_TransferCurves", 0xFDD6AB, 1792, 'b', 0x00FFE4, 1058, (7, 256, "group %d"), [
  "7 rows x 256 bytes.  Byte [(group << 8) + row], where the row index comes from",
  "Voice_Colour_RowOffset_Table below.  Each row is a monotone 0x00..0xFF transfer",
  "curve and higher groups bow it harder -- a brightness/colour response.",
  "Referenced from 0xFA7CF5.  Byte-identical to %s:1058.",
  "⚠ The sibling notes the group selector is 3 bits but only 7 rows exist; row 7",
  "would run into the table that follows.  The same is true here.",
 ]),
 ("Voice_Colour_RowOffset_Table", 0xFDDDAB, 128, 'b', 0x0106E4, 1296, None, [
  "128 bytes.  First stage of the colour lookup: row = table[control value], then",
  "the byte at Voice_Colour_TransferCurves[(group << 8) + row] is the answer.",
  "Referenced from 0xFA7CE4.  Byte-identical to %s:1296.",
 ]),
 ("Voice_OutputLevel_Table", 0xFDDE2B, 512, 'w', 0x010764, 1317, None, [
  "256 u16, monotone 0x0000..0x07FA.  Output-level curve; the sibling records that",
  "the index is a clamped byte and the result is doubled again by the caller.",
  "Referenced from 0xFA7DD1 and 0xFAC32A.  Byte-identical to %s:1317.",
 ]),
 ("EGEnv_ValueCurve_Simple", 0xFDE02B, 256, 'w', 0x010964, 1355, None, [
  "128 u16.  Envelope-generator VALUE curve: exponential start (0,1,2,4,8,...) and",
  "a linear tail to 0x3FFF.  Four references here: 0xFA7A15, 0xFA7AFB, 0xFA7C5F,",
  "0xFBDC1F.  Byte-identical to %s:1355.",
  "★ This is one of the two tables the earlier notes/kn5000-label-transplant.md got",
  "  right by name and wrong by address; see notes/prom_c_kn5000_xref.py.",
 ]),
 ("EGEnv_BaseCurve_A", 0xFDE12B, 256, 'w', 0x010A64, 1378, None, [
  "128 u16, 0x0000..0x1FFF, 0x10 per step then bowing.  Envelope BASE curve A.",
  "References: 0xFA798B, 0xFBDA88, 0xFBDABE.  Byte-identical to %s:1378.",
 ]),
 ("EGEnv_BaseCurve_B", 0xFDE22B, 256, 'w', 0x010B64, 1399, None, [
  "128 u16.  Envelope BASE curve B -- the sibling records it as a pure linear ramp",
  "of 0x40 per step.  References: 0xFA7A6D, 0xFBDAF9, 0xFBDB2F.  Byte-identical to",
  "%s:1399.",
 ]),
 ("Voice_FreqWrite_BaseCurve", 0xFDE32B, 256, 'w', 0x010C64, 1420, None, [
  "128 u16, the same 0x40-per-step ramp as EGEnv_BaseCurve_B but a separate object",
  "because the code addresses it independently -- and it does so here too:",
  "0xFA7B5D, 0xFA7BD0, 0xFBDB6C, 0xFBDBA2.  Byte-identical to %s:1420.",
 ]),
 ("Voice_ToneRampPitch_Curve", 0xFDE42B, 80, 'b', 0x010D64, 1442, None, [
  "80 bytes, an ease-out curve 0x00..0xFF indexed by the pitch ramp position.",
  "References: 0xFAC827, 0xFAC928, 0xFAC953, 0xFAC9D6.  Byte-identical to %s:1442.",
 ]),
 ("Voice_ToneRampFilter_Curve", 0xFDE47B, 26, 'b', 0x010DB4, 1457, None, [
  "26 bytes, a linear 0x00..0xFF filter-ramp curve.  References: 0xFAC865,",
  "0xFAC93A, 0xFAC97D, 0xFAC9C5, and four 24-bit forms.  Byte-identical to %s:1457.",
  "⚠ The sibling documents a shipped quirk: two of its indexing paths run past 26",
  "entries into the next table.  Not re-checked for the WSA1 readers.",
 ]),
 ("Voice_PitchDepth_Scale", 0xFDE495, 256, 'b', 0x010DCE, 1469, None, [
  "256 bytes, a slow-rising 0x20..0xF8 scale curve (pitch half of the output-list",
  "build in the sibling).  Referenced from 0xFAC4B3.  Byte-identical to %s:1469.",
 ]),
 ("Voice_FilterDepth_Scale", 0xFDE595, 256, 'b', 0x010ECE, 1506, None, [
  "256 bytes, 0x40..0xFF (filter half).  Referenced from 0xFAC616.",
  "Byte-identical to %s:1506.",
 ]),
 ("BitMask_Table_FDE695", 0xFDE695, 20, 'w', None, None, None, [
  "10 u16 bit masks.  WSA1-only: the KN5000 payload has nothing here, and this is",
  "the 20-byte block the WSA1 inserts between Voice_FilterDepth_Scale and the DSP",
  "selector records.",
  "",
  "The u16 element width is read off the readers, not assumed:",
  "  0xFB0BE8  ld C,0x02 / mul BC,(XIZ+0x0e) / add XBC,0x00FDE695 / ld BC,(XBC)",
  "            -- index*2 then a WORD load;",
  "  0xFAFC9D  add XIY,0x00FDE695 / ld IY,(XIY) / and WA,IY",
  "            -- the value is ANDed against a 16-bit word and branched on;",
  "  0xFB0EAE  ld BC,(0xFDE695) -- entry 0 fetched by absolute address.",
  "Seven reference sites in all.  The entry count is the space between its two",
  "neighbours; nothing has been traced that bounds the index, so 10 is a capacity,",
  "not a proven count.  What the mask SELECTS is NOT ESTABLISHED.",
 ]),
 ("DSP_AlgoChannel_SelectorRecords", 0xFDE6A9, 72, 'b', 0x010FCE, 1543, (12, 6, "type %d"), [
  "12 records x 6 bytes: three 2-byte channel pairs per algorithm type, 0xFF = the",
  "'no entry' sentinel.  The bytes select a row in DSP_ChanFreq_CurvePool below.",
  "Four references here: 0xFB58AD, 0xFB58C8, 0xFB5948, 0xFB5A57.",
  "Byte-identical to %s:1543.",
 ]),
 ("DSP_ChanFreq_CurvePool", 0xFDE6F1, 1224, 'w', 0x011016, 1565, (12, 102, "row %d"), [
  "12 rows x 51 u16, stride 0x66.  One contiguous pool of ascending frequency /",
  "coefficient curves addressed with three different row bases in the sibling; row 7",
  "is the constant 0x0B4D there and here.  References: 0xFB5AA2, 0xFB5AD6, 0xFB5B2B,",
  "0xFB5CE0.  Byte-identical to %s:1565.",
 ]),
 ("DSP_ChanFreq_IndexMap", 0xFDEBB9, 51, 'b', 0x0114DE, 1679, None, [
  "51 bytes: identity through 0x15, then bowing up to 0x7F -- a 51-step",
  "exponential bend used to index the pool above.  References: 0xFB6330, 0xFB6356,",
  "0xFB6372.  Byte-identical to %s:1679.",
 ]),
 ("EGEnv_ModeBits_Table", 0xFDEBEC, 8, 'w', 0x011511, 1692, None, [
  "4 u16 {0x0000, 0xC000, 0x4000, 0x8000} -- a 2-bit envelope/format mode field",
  "pre-shifted into bits 15..14, ORed into the computed envelope word.",
  "References: 0xFA79E2, 0xFA7AC4, 0xFA7BB2, 0xFA7C25.  Byte-identical to %s:1692.",
 ]),
 ("TVF_KeyFollow_Curves", 0xFDEBF4, 896, 'b', 0x011519, 1700, (7, 128, "curve %d"), [
  "7 curves x 128 SIGNED bytes (0xC0..0x00, i.e. -64..0).  TVF cutoff key-follow:",
  "a 3-bit selector picks the curve, key & 0x7F indexes inside it, and the signed",
  "byte is scaled by the key-follow depth.  References: 0xFA7716, 0xFA77CF.",
  "Byte-identical to %s:1700.",
  "⚠ Same shipped quirk as the sibling: the selector is 3 bits but only 7 curves",
  "exist, so selector 7 reads into the table that follows.",
 ]),
 ("Voice_LevelPair_AttackCurve", 0xFDEF74, 101, 'b', 0x011899, 1827, None, [
  "101 bytes, descending 0xFF..0x09, indexed by a level clamped to 0..100.",
  "References: 0xFAA56B, 0xFAA9E9, 0xFAADA3, 0xFAB150.  Byte-identical to %s:1827.",
 ]),
 ("Voice_EnvelopeLevel_Curve", 0xFDEFD9, 101, 'b', 0x0118FE, 1850, None, [
  "101 bytes, descending 0xFF..0x04.  The sibling calls this the hottest object in",
  "its zone (38 reference sites); it is heavily referenced here too -- 0xFA84D3,",
  "0xFA84F6, 0xFA851E, 0xFA853C and more.  Byte-identical to %s:1850.",
 ]),
 ("Voice_EnvelopeRate_Table", 0xFDF03E, 101, 'b', 0x011963, 1869, None, [
  "101 bytes, monotone 0x00..0x7F: parameter -> envelope rate.  References:",
  "0xFAA630, 0xFAA81F, 0xFAA83D, 0xFAAB68.  Byte-identical to %s:1869.",
 ]),
 ("Ramp_0_to_100_Curve", 0xFDF0A3, 128, 'b', None, None, None, [
  "128 bytes rising 0x00 -> 0x64 (0 -> 100).  WSA1-only: the KN5000 payload goes",
  "straight from Voice_EnvelopeRate_Table to Detune_Scale_Curve with nothing here.",
  "Shape: doubled steps at the bottom (00 00 00 00 01 01 01 01 02 02 ...), single",
  "steps from index 0x30, so it compresses a 0..127 input into a 0..100 output.",
  "Four references: 0xFBDF8D, 0xFBDFAF, 0xFBF55E, 0xFBF580.  What the 0..100 range",
  "means (a percentage parameter?) is NOT ESTABLISHED.",
 ]),
 ("Detune_Scale_Curve", 0xFDF123, 51, 'b', 0x0119C8, 1889, None, [
  "51 bytes, piecewise-linear 0x00..0x7F with knees at [16] and [32].  Detune",
  "scaling, symmetric about 0 in the sibling.  References: 0xFA7627, 0xFA7646,",
  "0xFA7661.  Byte-identical to %s:1889.",
 ]),
 ("TVF_DepthRecords_A", 0xFDF156, 42, 'b', 0x0119FB, 1902, (14, 3, "rec %2d"), [
  "14 records x 3 bytes: {flag 0x80/0x00, amount 0x00..0x7F, signed offset}.",
  "The sibling notes the three columns are fetched through fixed +0/+1/+2 bases",
  "with index*3 -- and prom_c does the same: 0xFA7891 loads the +0 base and",
  "0xFA786B / 0xFA787D the +1 and +2 bases as 24-bit operands.",
  "Byte-identical to %s:1902.",
 ]),
 ("TVF_DepthRecords_B", 0xFDF180, 42, 'b', 0x011A25, 1922, (14, 3, "rec %2d"), [
  "14 records x 3 bytes, the mirror image of set A (the flag column moves from the",
  "negative arm to the positive arm).  References 0xFA7834, 0xFA7858, and 0xFA7845",
  "for the +1 column.  Byte-identical to %s:1922.",
 ]),
 ("Voice_FineTune_Curve", 0xFDF1AA, 128, 'b', 0x011A4F, 1941, None, [
  "128 signed bytes, a +-8 fine-tune dip curve (0 at both ends, -8 mid-scale),",
  "added into the pitch accumulator.  References: 0xFAB654, 0xFAB759.",
  "Byte-identical to %s:1941.",
 ]),
 ("Instrument_OctaveShift_Semitones", 0xFDF22A, 16, 'b', 0x011ACF, 1962, None, [
  "16 signed bytes = 12*k semitones for k = -8..+7, i.e. -96, -84 ... 0 ... +84.",
  "Whole-octave transpose offsets.  Referenced from 0xFA737C.",
  "Byte-identical to %s:1962.",
 ]),
 ("Voice_EnvLevel_IndexMap", 0xFDF23A, 9, 'b', 0x011ADF, 1971, None, [
  "9 bytes {0x31,0x31,0x35,0x39,0x3D,0x41,0x45,0x49,0x4D} -- an index INTO",
  "Voice_EnvelopeLevel_Curve above, so the pair is read as curve[map[n]].",
  "References: 0xFAB969, 0xFABA72, 0xFABB41, 0xFABC37.  Byte-identical to %s:1971.",
 ]),
 ("Voice_VibratoDepth_Table", 0xFDF243, 128, 'b', 0x011AE8, 1979, None, [
  "128 bytes, every entry 0x96 except [49] = 0x88 -- shipped that way in BOTH",
  "machines, which is itself the strongest possible check that the two tables are",
  "the same object.  Referenced from 0xFAB845 (and 0xFAB85A, 24-bit).",
  "Byte-identical to %s:1979.",
 ]),
 ("Voice_ChromaticBend_Table", 0xFDF2C3, 276, 'b', 0x011B68, 2001, (23, 12, "row %2d"), [
  "23 rows x 12 signed bytes.  Rows 0 and 3..21 are zero; rows 1, 2 and 22 carry",
  "per-semitone corrections.",
  "★ The 12-column row stride is proven by prom_c's own code, at 0xFA8046:",
  "      ld C,(XIX+0x05) / res 0x07,C / div C,0x0c   ; key/12 and key%12",
  "      ld C,0x0c / mul BC,H / add XBC,XWA",
  "      add XBC,0x00FDF2C3 / ld A,(XBC) / exts WA / add WA,WA / add DE,WA",
  "-- row = key/12, column = key%12, the signed byte DOUBLED into the pitch",
  "accumulator.  That matches the sibling's description exactly (%s:2001).",
 ]),
 ("Voice_KeyShiftRamp_Steps", 0xFDF3D7, 26, 'b', 0x011C7C, 2030, None, [
  "26 signed bytes.  KEY SHIFT / transpose ramp: entry [0] seeds the ramp at -127",
  "(0x81) and the ramp self-terminates on the 0x00 entries at [24] and [25].",
  "No literal reference to this address was found in prom_c -- like the bend curves",
  "it is presumably reached as an offset from its neighbour, but that is NOT traced.",
  "Byte-identical to %s:2030.",
 ]),
 ("Voice_CC_VolumeCurve", 0xFDF3F1, 256, 'w', 0x011D16, 2062, None, [
  "128 u16, a non-linear attenuation curve 0xFF01 .. 0x0000 indexed by a 0..0x7F",
  "controller value (CC 7 volume / CC 11 expression in the sibling).",
  "References: 0xFAD710, 0xFAD7A7.  Byte-identical to %s:2062.",
  "★ NOTE THE ALIGNMENT STEP HERE.  Between Voice_KeyShiftRamp_Steps and this table",
  "  the WSA1-to-KN5000 offset moves by exactly 0x80, because the KN5000's 128-byte",
  "  Voice_AltNoteMap_Curve (%s:2040) has NO counterpart in the WSA1 image.",
 ]),
 ("DSP_AlgoDescriptor_Records", 0xFDF4F1, 468, 'b', 0x011E16, 2084, (12, 39, "type %2d"), [
  "12 records x 39 bytes (stride 0x27), indexed by algorithm type.",
  "★ THE RECORD COUNT DIFFERS FROM THE KN5000 AND THE DIFFERENCE IS SELF-PROVING.",
  "  The KN5000 has 14 records (%s:2084); the WSA1 has 12.  Nothing was assumed:",
  "  the byte run that is identical to the sibling ends 78 bytes early, 78 = 2*39,",
  "  and the next table starts exactly there.  Two fewer algorithm types.",
  "  (The sibling notes its own types 12/13 are all-zero -- the two that are gone.)",
  "Field offsets located by the sibling, not re-verified here: +0x00/+0x01/+0x1A",
  "copied to a part record; +0x02 top two bits index EGEnv_ModeBits_Table; +0x06 a",
  "packet sub-index; +0x0D bit 7 selects the +0x0E byte; +0x13 + 5*channel a",
  "per-channel flag.  References: 0xFB5992, 0xFB5B13, 0xFB5C37, 0xFB5DC0.",
 ]),
 ("Voice_SecondaryParam_Curve", 0xFDF6C5, 31, 'b', 0x012038, 2198, None, [
  "31 bytes descending 0x46..0x00 (70..0).  References: 0xFB0D40, 0xFB0FD6,",
  "0xFB11E7, 0xFB146C.  Byte-identical to %s:2198.",
 ]),
 ("Voice_SecondaryParam_WordCurveA", 0xFDF6E4, 62, 'w', 0x012057, 2208, None, [
  "31 s16: 0xFF00 then -62..0.  Indexed by a parameter byte * 2.",
  "References: 0xFB0D5D, 0xFB0D97, 0xFB0FF0, 0xFB1024.  Byte-identical to %s:2208.",
 ]),
 ("Voice_SecondaryParam_WordCurveB", 0xFDF722, 62, 'w', 0x012095, 2217, None, [
  "31 s16: 0xFF00 then -116..0 in steps of 4.  References: 0xFB0D7A, 0xFB100A,",
  "0xFB121B, 0xFB14B4.  Byte-identical to %s:2217.",
 ]),
 ("Curve_Exp2Gain_U8_128", 0xFDF760, 128, 'b', None, None, None, [
  "128 bytes rising 0x00 -> 0x80 with an exponential shape (flat 0x01 for 24",
  "entries, then accelerating; the last 16 steps are 0x43 0x46 0x49 ... 0x7B 0x80).",
  "WSA1-only -- no counterpart anywhere in the KN5000 payload.",
  "Four references: 0xFC51CA, 0xFC6E75, 0xFC70A1, 0xFC72E3 -- note these sit in a",
  "different part of the image from every other table here, so this one belongs to",
  "another subsystem.  Which one is NOT ESTABLISHED.",
 ]),
]

END = 0xFDF7E0


# ============================================================================
# ZONE 2 -- 0xFCC53F-0xFCD0F6, the touch / EQ / mixer-gain / descriptor-string
# zone.  Different evidence mix from zone 1: only three of its objects have a
# KN5000 counterpart, so most of it is carried by prom_c's own reference sites
# and by the decoded values being self-evidently right (ISO third-octave centre
# frequencies, a gain curve that ends exactly at digital full scale).
#
# kind: 'b' byte  'w' u16  'l' u32  'f' f32  'S' asciz pool  'I' incbin  'R' rows
# ============================================================================
SPEC2 = [
 ('l', "Link_ClassHandlerTable", 0xFCC53F, 32, None, [
  "8 x u32.  Every entry is a valid prom_c code address, and four of them",
  "(0xF98D9A, 0xF98DE6, 0xF98FD6, 0xF9901B) land exactly on a `link XIZ,imm` /",
  "`push HL` prologue -- this compiler's function entry -- while the remaining",
  "four are all the SAME address, 0xF9993D, whose first byte is 0x0E = RET.",
  "A handler table with four real arms and four do-nothing stubs.",
  "",
  "★ ROUND 2: THE TWO OPEN QUESTIONS ARE ANSWERED, and the reason a literal search",
  "found nothing is that the dispatcher never uses the ROM address.  RESET copies",
  "ROM 0xFCB4EA.. to RAM 0x00E2DF (notes/prom_c_ram_image.py re-derives the copy",
  "from the instruction bytes), and 0xFCC53F - 0xFCB4EA = 0x1055, so this table's",
  "RAM copy begins at 0x00E2DF + 0x1055 = 0x00F334.  That address appears as an",
  "instruction operand at 0xF99D91, `add xbc, 0x0000F334`, inside",
  "INTTC3_HANDLER__state1_generic (0xF99D6F, converted in this file): it indexes",
  "the table with (link command byte >> 5) * 4 and jumps through it.  So the START",
  "is proven by an operand after all, the dispatcher is traced, and the entry count",
  "of EIGHT is exactly the range of a 3-bit index.",
  "    python3 notes/prom_c_ram_image.py 0x00F334:32     # the boot contents",
  "    python3 notes/prom_c_link_state_machine.py        # the dispatcher",
  "⚠ Still not established: what the four real class handlers DO.",
 ]),
 ('b', "P7Module_RamStateImage", 0xFCC55F, 23, None, [
  "23 bytes that fit no structure found so far: 16 zero bytes, then",
  "00 53 6c 00 6c 00 6c 00.  Left as bytes rather than guessed at.",
 ]),
 ('R', "P7Unit_StreamPtrsByGroupAndUnit", 0xFCC576, 72, (6, 12, 'l', "group %d"), [
  "6 groups x 3 u32 = 18 pointers, all into the length-prefixed packet pool that",
  "starts at 0xFCD0F7.  The grouping is visible in the data itself: every group is",
  "{X, X, Y} -- the first two entries of each group are always equal.",
  "   group 0  {0xFCD22D, 0xFCD22D, 0xFCD40F}",
  "   group 1  {0xFCD97D, 0xFCD97D, 0xFCD40F}",
  "   group 2  {0xFCD0FE, 0xFCD0FE, 0xFCD0F7}",
  "   group 3  {0xFCD105, 0xFCD105, 0xFCD0F7}",
  "   group 4  {0xFCD119, 0xFCD119, 0xFCD10C}",
  "   group 5  {0xFCD131, 0xFCD131, 0xFCD10C}",
  "Five of the six distinct low targets are exactly the packet starts that the",
  "length walk in the header of the string pool below lands on, which is what ties",
  "the two structures together.",
  "⚠ NOT ESTABLISHED: the table start, again -- no literal reference to 0xFCC576.",
 ]),
 ('b', "unexplained_FCC5BE", 0xFCC5BE, 11, None, [
  "11 bytes between the pointer table and the first touch curve.  Four zeros then",
  "ff fa fb 4d 00 80 00.",
  "",
  "★ FOUR OF THE ELEVEN ARE NOW EXPLAINED (2026-08-24).  The u16 at 0xFCC5C5 is",
  "0x004D = 77 and the u16 at 0xFCC5C7 is 0x0080 = 128, and",
  "ToneGen_VelocityFromTouch (0xF995DF, converted above) reads both:",
  "      ld DE,(curve output) / sub DE,(0xFCC5C5)      ; subtract 77",
  "      muls XBC,WA / divs XBC,(0xFCC5C7)             ; times gain, over 128",
  "77 is the PIVOT of the touch transfer function -- the input-curve value at",
  "which the bracket goes to zero and the output equals",
  "ToneGen_VelCurve_ModeParams[mode].pivot whatever the gain is -- and 128 is the",
  "fixed-point divisor that makes that record's first column read as gain/128,",
  "which is exactly how the header below already describes it.",
  "The input curve holds 77 at index 144 and at NO other index, so the pivot is a",
  "single point on the curve.",
  "",
  "⚠ Still unexplained: the four leading zeros and the bytes ff fa fb at",
  "0xFCC5C2-0xFCC5C4.  Note also that the first FOUR bytes of this object (the",
  "zeros) are inside the boot RAM image copied to 0x00F3B3, and that RAM address",
  "IS written at runtime (0xFA2DD4) -- see notes/FINDINGS-prom_c-ram-image.md.",
  "So this object is not homogeneous: its head is a RAM initialiser and its tail",
  "is two constants read in place.",
 ]),
 ('b', "ToneGen_VelCurve_Trim51", 0xFCC5C9, 51, None, [
  "51 signed bytes rising from 0xF4 (-12) to 0x0A (+10), zero-crossing in the",
  "middle -- a symmetric +-12 trim curve.  Referenced once, from 0xF99872, which",
  "is inside the same routine family as the touch tables that follow it.",
  "No KN5000 counterpart at the corresponding address.",
 ]),
 ('R', "ToneGen_VelCurve_ModeParams", 0xFCC5FC, 30, (10, 3, 'b', "curve %d"), [
  "10 records x 3 bytes: {gain/128, output level at the pivot, trim subtracted for",
  "the black keys}.  This is the TOUCH SENSITIVITY table.",
  "★ The table SELF-DESCRIBES: the first column steps 0x00, 0x10, 0x20 ... 0x90,",
  "  so the record size and the row count are both readable off the data.",
  "★ It also sits at exactly the address the KN5000 offset predicts.  The 256-byte",
  "  curve that follows it here is byte-identical to the KN5000's, and under that",
  "  alignment this table lands on kn5000 0x01F420 -- the address the sibling",
  "  documents as the touch-mode parameter table (%s:11302).",
  "The VALUES are re-tuned for this instrument; they are NOT the KN5000's:",
  "     curve  gain  pivot out   black trim      (KN5000, for comparison)",
  "       0     0/128    208         0             208   0",
  "       1    16/128    199         2             199   3",
  "       2    32/128    190         5             189   6",
  "       3    48/128    181         8             180   8",
  "       4    64/128    171        11             171  11",
  "       5    80/128    162        13             161  14",
  "       6    96/128    153        16             152  16",
  "       7   112/128    144        19             143  19",
  "       8   128/128    134        22             134  22",
  "       9   144/128    125        24             130  24",
  "Referenced three times: 0xF9962D, 0xF9966F, 0xF99698.",
 ]),
 ('b', "ToneGen_Velocity_Input_Curve", 0xFCC61A, 256, None, [
  "256 bytes, monotonically DECREASING (0xFF for the first nine inputs, down to",
  "0x00 at the top).  Maps the raw keybed touch reading to the curve domain.",
  "The sibling argues [INFERENCE] that the decreasing sense means the raw reading",
  "behaves like a key-travel TIME -- a small reading is a hard strike.",
  "Referenced from 0xF99608.  Byte-identical to %s:11337 (kn5000 0x01F43E).",
 ]),
 ('b', "ToneGen_Velocity_Output_Curve", 0xFCC71A, 256, None, [
  "256 bytes, the second half of the touch mapping: starts 0x01 then a long run of",
  "0x02 -- a compressive, roughly logarithmic response.  This is the end that",
  "produces the delivered MIDI velocity, so it RISES with strike strength.",
  "Referenced from 0xF99721 (24-bit form).  Byte-identical to kn5000 0x01F53E",
  "(%s:11361).",
 ]),
 ('I', "fp_constant_pool_FCC81A", 0xFCC81A, 616, None, [
  "616 bytes LEFT AS .incbin ON PURPOSE.",
  "It is an IEEE-754 constant pool -- IEEE doubles are visible in it by eye (the",
  "bytes 00 00 00 00 00 00 4C 40 are 56.0) -- but the element boundaries are NOT",
  "established: decoding it as f64 from any of the obvious start offsets yields",
  "mostly denormal garbage (7 of 76 candidates come out as round numbers from the",
  "best-looking alignment), so the pool is not uniformly 8-byte strided and some",
  "of it is probably f32 or something else.  Guessing a stride here would produce",
  "a table of nonsense that the byte gate would happily accept.",
  "The KN5000 has a pool of the same kind two tables earlier (%s:2695); its",
  "contents do NOT match, so the sibling cannot supply the boundaries either.",
 ]),
 ('f', "DSP_EQ_FreqHz_Table", 0xFCCA82, 108, None, [
  "27 x f32: parametric-EQ centre frequencies in Hz.",
  "★ SELF-PROVING: decoded as little-endian f32 from this address the 27 values",
  "  come out as exactly the ISO third-octave series 40, 50, 63, 80 ... 12500,",
  "  16000.  A one-byte error in the base, or a wrong element size, turns that",
  "  into denormals.  The decoded value is written beside every entry below.",
  "Referenced four times: 0xF9E290, 0xF9E9A4, 0xF9ED89, 0xF9F244.",
  "Byte-identical to kn5000 0x012397 (%s:2510).",
 ]),
 ('f', "DSP_EQ_Q_Table", 0xFCCAEE, 128, None, [
  "32 x f32: parametric-EQ Q / bandwidth values -- 0.1..0.9 by 0.1, then 1.0..4.0",
  "by 0.5, then 5..20 by 1.  Same self-proving decode as the frequency table.",
  "Referenced from 0xF9E201.  Byte-identical to kn5000 0x012403 (%s:2520).",
 ]),
 ('b', "unexplained_FCCB6E", 0xFCCB6E, 3, None, [
  "3 bytes, 00 01 00, sitting between the Q table and the gain curve.  0xFCCB6E is",
  "referenced three times (0xFA2C21, 0xFA2CD9, 0xFA2D8C) so it is a real object,",
  "but three bytes is too little to infer a shape from and the readers are not",
  "traced.  Left as bytes.",
 ]),
 ('l', "DSP_MixerGain_Curve_B", 0xFCCB71, 512, None, [
  "128 x u32, strictly monotonic, ending EXACTLY at 0x7FFFFF00 = digital full",
  "scale.  The wide-range curve of the pair: it spans 0x00002068 to 0x7FFFFF00,",
  "about 108 dB, with a steep bottom (ratio up to 3.16 per step) flattening to",
  "1.017 per step at the top.",
  "★ ELEMENT SIZE AND COUNT PROVEN BY THE CONSUMER at 0xFA30D8:",
  "      ld WA,0x0004 / muls XWA,(XIZ+0x08)   ; index * 4",
  "      add XWA,0x00FCCB71 / ld XWA,(XWA)    ; 32-bit load",
  "      sra 0x00,XWA                         ; used unshifted",
  "  and the same routine seeds a register with the literal 0x7FFFFF00, the value",
  "  this curve ends on.  The 128 entries are the space to its neighbour.",
  "WSA1-only: it matches none of the KN5000's five u32 ladders (best 32/512 bytes).",
 ]),
 ('l', "DSP_MixerGain_Curve_A", 0xFCCD71, 512, None, [
  "128 x u32, strictly monotonic, also ending exactly at 0x7FFFFF00.  The narrow",
  "companion of curve B: 0x00451EB3..0x7FFFFF00, about 53.5 dB.",
  "★ Same consumer, four instructions earlier (0xFA30C5):",
  "      ld WA,0x0004 / muls XWA,(XIZ+0x0a) / add XWA,0x00FCCD71 / ld XWA,(XWA)",
  "      ld XIX,XWA / sra 0x0f,XIX           ; >> 15",
  "  and the two looked-up values are then pushed together into 0xFCB0D3 -- a",
  "  two-stage product.  The `>> 15` is exactly what the sibling documents for its",
  "  copy of this curve (%s:2926), which is byte-identical to this one",
  "  (kn5000 0x0131CF).  53.5 dB total span there and here.",
 ]),
 ('S', "DescriptorStrings", 0xCF71 + 0xFC0000, 390, None, [
  "A pool of 44 NUL-terminated ASCII strings in two interleaved families:",
  "  * FIELD-TYPE strings over the alphabet {b, w, v, s, h, c, B} -- 'bbbvb',",
  "    'bwwbbv', 'wwcbbbbbv', ... ;",
  "  * INDEX strings '0', '01234', '0123456789abc' -- a run of consecutive",
  "    base-36 digits whose length matches the type string it is paired with.",
  "The pairing is not a guess: the pointer records at 0xFDBFE9 onward load the two",
  "members of a pair four bytes apart (0xFDBFE9 -> 'bbbvb'-family, 0xFDBFED ->",
  "the digit string), and 0xFCCF77 alone is loaded 21 times.",
  "[INFERENCE, stated as such] this is a field-layout descriptor: one letter per",
  "field giving its width or kind, and the digit string giving each field an index.",
  "What the letters mean individually is NOT ESTABLISHED -- 'b'/'w' as byte/word",
  "is the obvious reading but nothing here proves it.",
 ]),
]


def fmt(buf, off, n, unit, indent="\t"):
    out = []
    if unit == 'b':
        per = 16
        vals = [f"0x{b:02x}" for b in buf[off:off + n]]
    else:
        per = 8
        vals = [f"0x{v:04x}" for v in struct.unpack(f"<{n // 2}H", buf[off:off + n])]
    for i in range(0, len(vals), per):
        out.append(f"{indent}.{'byte' if unit == 'b' else 'short'}\t" + ", ".join(vals[i:i + per]))
    return out


def verify():
    rom = open(ROM, "rb").read()
    pay = open(PAY, "rb").read()
    ok = True
    cur = SPEC[0][1]
    nid = nsame = nref = 0
    for label, addr, n, unit, ka, line, rows, hdr in SPEC:
        if addr != cur:
            print(f"  CHAIN BREAK before {label}: expected 0x{cur:06X}, spec says 0x{addr:06X}")
            ok = False
        cur = addr + n
        if unit == 'w' and n % 2:
            print(f"  {label}: word table with odd length {n}")
            ok = False
        if ka is not None:
            nid += 1
            w = rom[addr - BASE:addr - BASE + n]
            s = pay[ka - 0xEF00:ka - 0xEF00 + n]
            if w == s:
                nsame += 1
            else:
                eq = sum(1 for i in range(n) if w[i] == s[i])
                print(f"  {label}: NOT identical to kn5000 0x{ka:06X} ({eq}/{n})")
                ok = False
        if rom.find(struct.pack("<I", addr)) >= 0:
            nref += 1
    if cur != END:
        print(f"  CHAIN does not end at 0x{END:06X}; it ends at 0x{cur:06X}")
        ok = False
    tail = rom[END - BASE:END - BASE + 94]
    if tail != b"\0" * 94:
        print("  the 94 bytes after the block are not zero fill")
        ok = False
    print(f"  {len(SPEC)} tables, 0x{SPEC[0][1]:06X}..0x{END - 1:06X} = {END - SPEC[0][1]:,} bytes")
    print(f"  chain closes with no gap/overlap and 94 zero bytes follow ... {'yes' if ok else 'NO'}")
    print(f"  byte-identical to the KN5000 sibling: {nsame}/{nid} of the tables that have a counterpart")
    print(f"  start address appears as a literal 32-bit operand in prom_c: {nref}/{len(SPEC)}")
    return 0 if ok else 1


def emit():
    rom = open(ROM, "rb").read()
    L = []
    W = lambda s="": L.append(s)
    W("; " + "=" * 76)
    W("; 0xFDD2AB-0xFDF7DF -- the voice / DSP data-table zone (9,525 B, 43 tables)")
    W("; " + "=" * 76)
    W(";")
    W("; Generated by notes/gen_prom_c_tables.py -- the numbers are read out of the ROM,")
    W("; never retyped.  `python3 notes/gen_prom_c_tables.py --verify` re-proves the")
    W("; three independent facts the boundaries rest on:")
    W(";")
    W(";   1. 36 of the 43 tables are BYTE-IDENTICAL, over their whole length, to a")
    W(";      named table in the KN5000 sub-CPU payload, at the size that project's")
    W(";      map states (../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s).")
    W(";   2. The 43 tables laid end to end from 0xFDD2AB reach 0xFDF7DF exactly, with")
    W(";      no gap and no overlap, and zero fill follows.  One wrong size would")
    W(";      desynchronise everything after it and the identity checks would collapse.")
    W(";   3. 39 of the 43 start addresses occur in THIS image as a literal 32-bit")
    W(";      address operand.  That is prom_c's own code agreeing with the boundary,")
    W(";      with no reference to the sibling project at all.  The reference sites are")
    W(";      quoted in each header.")
    W(";")
    W('; ⚠ ROUND 11 CORRECTION -- 70 CITATIONS IN THIS ZONE AND ITS NEIGHBOUR NAMED THE')
    W('; WRONG ADDRESS, and they now name the right one.  Every "Referenced from"/')
    W('; "References:" line above was written by hand in this generator, and 70 of them')
    W('; cited the address of the ADDRESS OPERAND rather than of the instruction that')
    W('; carries it -- 0xFA737E for `add XBC,0x00FDF22A`, which starts at 0xFA737C.  The')
    W('; deltas are +2 for `add Xrr,imm32` and +1 for `lda_24`.  This is the THIRD time')
    W('; this tree has shipped a systematic off-by-N in call-site citations, and the')
    W('; second time in prom_c: notes/FINDINGS-prom_c-keyboard-and-touch.md already')
    W('; diagnosed exactly this for ONE table ("cited its reference as 0xF99874, which')
    W('; is the address of the literal") and said the header had been corrected -- the')
    W('; correction never reached the file.  Both are corrected here, in the generator')
    W('; as well as in the listing, so a regeneration cannot put it back.  Each fix is')
    W('; accepted only if the instruction at the corrected address literally carries the')
    W("; table's own start address as an operand, so a blind -2 could not pass:")
    W(';     python3 notes/prom_c_inventory_round8.py --cites')
    W(';')
    W("; ⚠ WHAT THIS DOES NOT ESTABLISH.  Byte identity establishes that the DATA is the")
    W("; same.  It does NOT establish that the WSA1 routine reading a table does what the")
    W("; KN5000 routine of that name does.  Three readers HAVE been disassembled here and")
    W("; are quoted where they are relevant (the key-bend selector at 0xFA8016, the")
    W("; chromatic-bend indexer at 0xFA8046, the bit-mask readers at 0xFB0BE8/0xFAFC9D);")
    W("; every other name is carried over on byte identity alone and says so.")
    W(";")
    W("; ⚠ The KN5000 addresses quoted below are LINK addresses in that project's map.")
    W("; They are NOT `0x400 + payload file offset` -- that formula, used by")
    W("; scripts/analysis/transplant_kn5000_labels.py, is wrong by 0xEB00 because the")
    W("; sibling's ROM file is built with a 60,160-byte hole in it.  See")
    W("; notes/prom_c_kn5000_xref.py, which proves the correct mapping from the bytes.")
    W(";")
    W("; PROVENANCE unchanged: this is the publicly redistributed v2 firmware set, not a")
    W("; chip read (../technics_roms/roms/wsa1/PROVENANCE.md).")
    W("")
    for label, addr, n, unit, ka, line, rows, hdr in SPEC:
        W("; " + "-" * 76)
        W(f"; {label} -- 0x{addr:06X}..0x{addr + n - 1:06X}  ({n} bytes)")
        W(";")
        for h in hdr:
            W(("; " + (h % tuple([DT] * h.count("%s")) if "%s" in h else h)).rstrip())
        if ka is not None:
            W(f"; Sibling: kn5000 sub-CPU 0x{ka:06X}, {DT}:{line}")
        W("; " + "-" * 76)
        W(f"{label}:")
        off = addr - BASE
        if rows:
            cnt, stride, rfmt = rows
            assert cnt * stride == n, (label, cnt, stride, n)
            for r in range(cnt):
                W("\t; " + rfmt % r)
                L.extend(fmt(rom, off + r * stride, stride, unit))
        else:
            L.extend(fmt(rom, off, n, unit))
        W("")
    return "\n".join(L)


def emit2():
    """Zone 2 -- 0xFCC53F..0xFCD0F6."""
    rom = open(ROM, "rb").read()
    L = []
    W = lambda t="": L.append(t)
    W("; " + "=" * 76)
    W("; 0xFCC53F-0xFCD0F6 -- touch / EQ / mixer-gain / descriptor-string zone")
    W("; " + "=" * 76)
    W(";")
    W("; Generated by notes/gen_prom_c_tables.py (SPEC2); the numbers are read out of the")
    W("; ROM, never retyped.  This zone rests on DIFFERENT evidence from the big table")
    W("; zone at 0xFDD2AB: only five of its objects have a KN5000 counterpart, so most of")
    W("; it is carried by prom_c's own reference sites plus decodes that are")
    W("; self-evidently right -- the EQ table comes out as the ISO third-octave series,")
    W("; and both mixer curves end exactly on digital full scale, values a wrong base or")
    W("; a wrong element size could not produce.")
    W(";")
    W("; Two objects are deliberately NOT decoded and say why in their own headers: the")
    W("; f32/f64 constant pool at 0xFCC81A (stride not established) and three bytes at")
    W("; 0xFCCB6E.  An honest .incbin beats an invented stride.")
    W("")
    for kind, label, addr, n, extra, hdr in SPEC2:
        W("; " + "-" * 76)
        W("; %s -- 0x%06X..0x%06X  (%d bytes)" % (label, addr, addr + n - 1, n))
        W(";")
        for h in hdr:
            W(("; " + (h % tuple([DT] * h.count("%s")) if "%s" in h else h)).rstrip())
        W("; " + "-" * 76)
        off = addr - BASE
        if kind == 'I':
            W("%s:" % label)
            W('\t.incbin "original_ROMs/wsa1_prom_c.ic28", 0x%06X, 0x%X' % (off, n))
            W("")
            continue
        W("%s:" % label)
        if kind in ('b', 'w'):
            L.extend(fmt(rom, off, n, kind))
        elif kind == 'l':
            v = struct.unpack_from("<%dI" % (n // 4), rom, off)
            for i in range(0, len(v), 4):
                W("\t.long\t" + ", ".join("0x%08x" % x for x in v[i:i + 4]))
        elif kind == 'f':
            v = struct.unpack_from("<%df" % (n // 4), rom, off)
            r = struct.unpack_from("<%dI" % (n // 4), rom, off)
            for i, (fv, rv) in enumerate(zip(v, r)):
                W("\t.long\t0x%08x\t; [%2d] = %g" % (rv, i, fv))
        elif kind == 'S':
            i = off
            end = off + n
            k = 0
            while i < end:
                z = rom.index(b"\0", i)
                txt = rom[i:z].decode("ascii")
                W('\t.asciz\t"%s"\t; [%2d] 0x%06X' % (txt, k, BASE + i))
                k += 1
                i = z + 1
        elif kind == 'R':
            cnt, stride, u, rfmt = extra
            assert cnt * stride == n
            for r in range(cnt):
                W("\t; " + rfmt % r)
                if u == 'l':
                    v = struct.unpack_from("<%dI" % (stride // 4), rom, off + r * stride)
                    W("\t.long\t" + ", ".join("0x%08x" % x for x in v))
                else:
                    L.extend(fmt(rom, off + r * stride, stride, u))
        W("")
    return "\n".join(L)


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--zone2" in sys.argv:
        print(emit2())
    else:
        print(emit())
