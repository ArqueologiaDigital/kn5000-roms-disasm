#!/usr/bin/env python3
"""WAVE 18, lane w18/voice-tonedb -- CLOSING WAVE 17's REFUSAL OF 0xFB405F-0xFB6E09.

QUESTION THIS ANSWERS
    Wave 17's voice lane named 65 of 119 `sub_` labels and refused 54.  Fifty of
    the refusals were one family, 0xFB405F-0xFB6E09 inside
    prom_c/voice/note_engine.s, refused for a reason it stated plainly:

        "They are the TONE DATABASE and PROGRAM CHANGE machinery, not the note
         engine. ... follow part_record[+0x00] to the part's loaded tone object,
         take `object[+0xD0] & 0x0F` as a class 0..15, and index a 39-byte ROM
         record at 0xFDF4F1 + 39*class ... WHAT WOULD SETTLE THEM: prom_d's
         tone-record layout decoded far enough to name `object[+0xD0]`'s class
         field and the 0xFDF4F1 record."

    The SAME wave's tone-db lane decoded exactly that, from the other side:
    ToneRec +0xD0 low nibble is `dsp_algo`, an ALGORITHM TYPE indexing prom_c's
    12-record, 39-byte DSP_AlgoDescriptor_Records; +0xD1..+0xD8 is dsp_param[8];
    43 = WaveSelRec, 150 = PercInst, 41 = the part-element sub-record, 81 = the
    element parameter block, 713/408/150 = the three staging regions.

        SO THE QUESTION HERE IS: with that vocabulary, which of the fifty can
        now be named from a decoded fact at BOTH ends, and which cannot?

    Answer: 42 named, 8 still refused.  This file is both the record and the
    tool, so the rename is re-derivable, auditable and revertable from one place.

RUN
    python3 wsa1/notes/prom_c_voice_tonedb_w18.py --report   # the table
    python3 wsa1/notes/prom_c_voice_tonedb_w18.py --claims   # re-read the ROM
    python3 wsa1/notes/prom_c_voice_tonedb_w18.py --apply    # do the rename
    python3 wsa1/notes/prom_c_voice_tonedb_w18.py --check    # assert it landed

THE TEST APPLIED TO EVERY CANDIDATE, stated before the results so it can be
checked against them:

    A routine is NAMED only when a decoded fact fixes BOTH ends of the name --
    the OBJECT it works on and the VERB it performs -- and at least one end is a
    concept some other file already names (ToneRec, WaveSelRec, PercInst,
    element parameter block, part record, dsp_algo, dsp_param,
    DSP_AlgoDescriptor_Records, ToneDB_EnvDescTable, the staging image).

    A routine is REFUSED when neither end is named: when it reads an
    UNIDENTIFIED byte of one record and writes an UNIDENTIFIED byte of another.
    Naming those would be naming by position, and the eight that fall there are
    listed with what each turns on and what would settle it.

  ⚠ THE UNBLOCKING FACT IS SPECIFIC.  It explains the algorithm type and the
    descriptor row.  It does NOT explain the element parameter block's bytes
    +0x06/+0x26/+0x38, and it does not explain the 4 x 4 array of 4-byte
    records at part record +0x35.  Seven of the eight refusals are exactly the
    routines that turn on those, and they stay refused for that reason.

HOW IT RENAMES, AND WHY IT IS SAFE
    * It rewrites only the CODE half of a line (everything before the first `;`)
      -- the same mechanism prom_c_voice_names_w17.py used.  A `★ NAMED (wave
      18)` or `★ NOT NAMED (wave 18)` block is INSERTED above each generated
      `; sub_FBxxxx -- 0x...` header, which itself is kept verbatim.
    * `sub_XXXXXX__YYYYYY` internal branch labels are deliberately NOT renamed,
      the same choice the tree already made for ChanRec_Release and for wave 17.
    * ⚠ Every cross-file reference to these labels is a COMMENT (`; Calls:` /
      `; Called from:` lines in tone_db_module.s and elsewhere) -- no code line
      outside this file names them, because prom_c's call operands are numeric
      (`calr (0xFB4324 - 0xFB43C4)`).  So the rename cannot break assembly, and
      the stale spellings it leaves in OTHER files are comments this lane may
      not edit.  Their addresses are authoritative.
    * A rename must not move a byte.  The gates are
        make LLVM_MC=<snap> gate-all          (13/13 identical, 8/8 assembling)
        python3 scripts/analysis/assert_comments_preserved.py --base main \
            --rename-map <map> wsa1/prom_c/voice/note_engine.s

GRADES (this tree's ladder, unchanged)
    PROVEN  -- a reader or a writer settles it; usually the whole body.
    STRONG  -- several independent facts agree and no null explains them.
    WEAK    -- one suggestive pattern.  Nothing below is graded WEAK; a WEAK
               reading was left as `sub_`.
"""
import argparse
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "prom_c/voice/note_engine.s"

PROM_C = ROOT / "original_ROMs" / "wsa1_prom_c.ic28"
C = open(PROM_C, "rb").read()
C_BASE = 0x1000000 - len(C)          # 0xF80000: prom_c is the top of the space

# ---------------------------------------------------------------------------
# old label -> (new label, grade, reason lines)
# ---------------------------------------------------------------------------
RENAMES = {

# --- A. the record walk: tone record -> element block -> wave-select record ---
"sub_FB405F": ("ToneRec_MapElementIndex_ByMask", "PROVEN", [
    "args (bank selector, element index i, element mask).  Body: bank selectors",
    "8..0x0F return i unchanged (0xFB4065/0xFB406B/0xFB4071 -- those banks are the",
    "713-byte 4-element RAM tones, see ToneDB_ResolveToneRecord's 0x02C9 arm).",
    "Otherwise it reads `1 << 2i` from the byte table at 0xFDE69D (0xFB407E; the",
    "bytes there are 01 04 10 40 ...) and ANDs it with the mask: no bit, return",
    "0xFF; a bit, return the count of set slots in 1..i (loop 0xFB4096-0xFB40B5).",
    "That count IS the PACKED position of element i among the elements the record",
    "actually stores, provided slot 0 is present -- said as a proviso because the",
    "ROM does not bound it.  prom_d already cites this routine as `the selector at",
    "0xFB405F, whose 0xFF answer means no element`; the mask is ToneRec +0x11."]),

"sub_FB40C7": ("ToneRec_CountElements_ByMask", "PROVEN", [
    "args (bank selector, element mask).  Bank selectors 8..0x0F return the",
    "constant 4 (0xFB40F9); every other selector counts the slots i = 0..3 whose",
    "`1 << 2i` (same 0xFDE69D table, 0xFB40E2) is set in the mask, bounded by",
    "`cp H,4` at 0xFB40F3.  The count is the N of prom_d's ToneRec: its one caller",
    "uses it to skip N*81 bytes of element blocks before the wave-select array."]),

"sub_FB4103": ("ToneStage_RecordForBankSelector", "PROVEN", [
    "the whole body is `return (bank selector >= 0x20) ? 0x008A9B : 0x0087D2`",
    "(`cp (XIZ+0x08),0x20` 0xFB4108, `lda XBC,0x008a9b` 0xFB410E, `lda",
    "XIX,0x0087d2` 0xFB4117).  Those two addresses are the first two regions of",
    "the RAM tone staging image tone_db_module.s documents: +0x000 the 713-byte",
    "TONE RECORD and +0x2C9 = 0x008A9B the 408-byte DRUM-KIT RECORD.  0x2C9 = 713",
    "is why they are consecutive, and bank selectors >= 0x20 are the drum banks --",
    "the same threshold ToneDB_ResolveToneRecord splits on at 0xFB4176."]),

"sub_FB42B0": ("Part_ResolveToneRecord", "PROVEN", [
    "args (part, program, bank selector).  If part record +0x04 bit 0 is set",
    "(0xFB42C1/0xFB42C6 -- tone_db_module.s names that bit `staged`) it returns",
    "ToneStage_RecordForBankSelector(bank selector); otherwise it tail-calls",
    "ToneDB_ResolveToneRecord(program, bank selector) at 0xFB42DC.  So it is the",
    "one place that answers `where is this part's tone record`, RAM or database."]),

"sub_FB42E3": ("Part_GetElementBlock_Unpacked", "PROVEN", [
    "args (part, element index, bank selector).  Bank selectors >= 0x20 return",
    "0x008C33, the staging image's DRUM-INSTRUMENT region (0xFB42EF).  Otherwise",
    "it follows part record +0x00 to the tone record (`ld XIY,(XWA+0x1523)`",
    "0xFB4313) and adds 0xD9 + 81*index (`ld C,0x51` 0xFB42F8, `add XBC,0x000000d9`",
    "0xFB42FF) -- prom_d's ToneRec.element[] with NO mask packing, which is what",
    "makes it the counterpart of ToneRec_GetElementBlock rather than a copy of it."]),

"sub_FB4383": ("Part_GetElementBlock", "PROVEN", [
    "args (part, element index, bank selector).  It is the two-armed wrapper: part",
    "record +0x04 bit 0 set -> Part_GetElementBlock_Unpacked (0xFB43B2), clear ->",
    "ToneRec_GetElementBlock on part record +0x00 (0xFB43BB/0xFB43C1), which packs",
    "the index through the element mask.  Both arms return an 81-byte ELEMENT",
    "PARAMETER BLOCK, so the difference is only whether the index is packed."]),

"sub_FB43CB": ("ToneRec_GetWaveSelectRecord", "PROVEN", [
    "args (bank selector, element index, tone record).  ★★ THIS IS THE",
    "WAVE-SELECT SIBLING OF ToneRec_GetElementBlock, and that is what round 11",
    "could not see when it refused this label for `reading slot +0xAC like",
    "ToneRec_GetElementBlock but sharing none of the arithmetic`.  Body: pack the",
    "index through the mask at ToneRec +0x11 (0xFB43D4/0xFB43E2); on 0xFF take",
    "directory slot +0xAC (ToneDB_DefaultLayerParams) PLUS 0x51 (0xFB4401) -- that",
    "slot is 81 + 43 bytes, so +0x51 is precisely its wave-select half, which is",
    "why the same slot serves both routines.  Otherwise ask",
    "ToneRec_CountElements_ByMask for N (0xFB4415) and return",
    "record + 0xD9 + 81*N + 43*packed: the four arms carry 0x51, 0xA2, 0xF3 and",
    "0x144 (0xFB443F, 0xFB445C, 0xFB4479, 0xFB4496) = 81, 162, 243, 324 = 81*N,",
    "each with `ld A,0x2b` (43) as the stride.  That is prom_d's",
    "`WaveSelRec wavesel[N] at +0xD9 + 81*N`, computed."]),

"sub_FB44A5": ("ToneRec_GetWaveSelectRecord_ByBankSelector", "PROVEN", [
    "args (bank selector, element index, tone record).  Bank selectors 8..0x0F",
    "(0xFB44AE/0xFB44B4) skip the packing entirely and take record + 0xD9 + 0x144 +",
    "43*index (0xFB44BD/0xFB44C3/0xFB44CA) -- 0x144 = 4*81, i.e. N is ASSUMED to be",
    "4, which is consistent with those banks holding 713-byte four-element records",
    "and with ToneRec_CountElements_ByMask returning the constant 4 for them.",
    "Every other selector defers to ToneRec_GetWaveSelectRecord (0xFB44E2)."]),

"sub_FB44EC": ("Part_GetWaveSelectRecord", "PROVEN", [
    "args (part, element index).  Part record +0x04 bit 0 set -> staging image",
    "0x0087D2 + 0x21D + 43*index (0xFB4510/0xFB4517/0xFB451D); 0x21D = 541 =",
    "217 + 4*81 is the staged tone's wave-select array.  Clear -> ",
    "ToneRec_GetWaveSelectRecord_ByBankSelector(part record +0x1C, index, part",
    "record +0x00) at 0xFB4536/0xFB4542.  ★ That call is where part record +0x1C",
    "is USED as the bank selector -- tone_db_module.s derived that field's role",
    "from Voice_GetOctaveShift, and this is a second, independent reader."]),

"sub_FB454C": ("PercInst_GetWaveSelectRecord", "PROVEN", [
    "args (index, drum-instrument record).  Returns record + 0x12 + 0x2E +",
    "43*index (0xFB4554/0xFB455A/0xFB4561) = record + 0x40 + 43*index, which is",
    "prom_d's `PercInst.wavesel[2] at +0x40, stride 43` exactly.  The 0x12/0x2E",
    "split is how the compiler emitted 0x40, not two fields.  Its sibling",
    "Part_GetPercWaveSelectRecord proves the argument IS a PercInst: that routine's",
    "other arm computes the same thing in the staging image."]),

"sub_FB456F": ("Part_GetPercWaveSelectRecord", "PROVEN", [
    "args (part, wave-select index, drum-instrument record, instrument number).",
    "Part record +0x04 bit 0 set -> 0x0087D2 + 0x4A1 + 150*instrument +",
    "43*index (`ld A,0x96` 0xFB4595, `add XWA,0x000004a1` 0xFB459E,",
    "`add XWA,0x000087d2` 0xFB45A4).  0x4A1 = 0x461 + 0x40: 0x461 is the staging",
    "image's DRUM-INSTRUMENT region and +0x40 is PercInst.wavesel -- the same",
    "0x4A1 - 0x461 = 0x40 prom_d cites at 0xFB868F.  Clear -> ",
    "PercInst_GetWaveSelectRecord (0xFB45B7).  Two arms, one answer."]),

"sub_FB49EB": ("Part_ResolveDrumInstrumentRecord", "PROVEN", [
    "args (part, drum-kit record, ..., MIDI note).  Part record +0x04 bit 0 set ->",
    "staging image 0x0087D2 + 0x461 + 150*note (0xFB4A13/0xFB4A19/0xFB4A1F).",
    "Clear -> read the kit's note-map entry as TWO separate bytes at kit + 0x98 +",
    "2n and + 0x99 + 2n (0xFB4A33, 0xFB4A46 -- prom_d's DrumKitRec.note_map), form",
    "a 2-bit arm from part record +0x1B bit 0 and +0x1C - 0x28 (0xFB4A58-0xFB4A84)",
    "and hand all four to DrumKit_ResolveInstrumentRecord (0xFB4A94)."]),

# --- B. the second resolver: the same selector pair, the descriptor tables ---
"sub_FB45C0": ("ToneDB_ResolveEnvDescriptor", "PROVEN", [
    "★★ THIS IS THE MISSING READER OF prom_d's DESCRIPTOR BLOCKS.  prom_d's wave",
    "17 block says of slots +0x30/+0x34/+0x38 `⚠ STILL NO READER ... nothing in",
    "prom_c reaches their slots`, and of the index maps +0x24/+0x28/+0x2C `same",
    "1024-entry shape, no reader located`.  This routine reaches all six.",
    "args (sel_program, sel_bank_family) -- the SAME two bytes",
    "ToneDB_ResolveWaveSelectRecord consumes, masked the same way: `res 0x07,C`",
    "0xFB45CE and `and A,0x0f` 0xFB45D8.  Family bits 5:4 pick the file base",
    "(internal 0x00D7ED/0x00D7F1, or the expansion board's 0x00D80D/0x00D811 at",
    "0xFB461B); family bits 7:6 pick a (map, array, stride) triple:",
    "  0x00 / 0xC0 -> dir +0x24 ToneDB_ToneIndexMapC, +0x30 ToneDB_EnvDescTable,",
    "                 stride +0xEC   (0xFB4668 `a9 24`, 0xFB466E `a9 30`,",
    "                 0xFB4679 `d3 e5 ec 00`)",
    "  0x40        -> dir +0x2C ToneDB_DrumToneIndexMap, +0x38",
    "                 ToneDB_EnvDescTable_Perc, stride +0xF2   (0xFB468C `a9 2c`,",
    "                 0xFB4692 `a9 38`, 0xFB469D `d3 e5 f2 00`)",
    "  0x80        -> dir +0x28 ToneDB_ToneIndexMapD, +0x34 (the +0x30 alias),",
    "                 stride +0xEC   (0xFB46B3 `a9 28`, 0xFB46B9 `a9 34`,",
    "                 0xFB46C4 `d3 e5 ec 00`)",
    "and the walk itself is bit for bit ToneDB_ResolveWaveSelectRecord's:",
    "  i = (family & 0x0F)*128 + (program & 0x7F)  (`sll 0x07,BC` 0xFB46DA)",
    "  n = LE16 at base + dir[map] + 2*i           (0xFB46DF-0xFB46E9)",
    "  return base + dir[array] + n*dir[stride]    (0xFB46EB-0xFB46F1)",
    "★ TWO PARALLEL RESOLVERS, ONE SELECTOR PAIR: an element's (sel_program,",
    "sel_bank_family) chooses a 43-byte wave-select record through one triple and",
    "a 14-byte envelope descriptor through the other.  That is what makes the",
    "triples parallel rather than coincidental.",
    "⚠ CORRECTION OWED TO prom_d, reported not edited: its block gives stride",
    "+0xF2 for +0x30/+0x34 as well as +0x38.  The instructions say +0x30 and",
    "+0x34 are scaled by +0xEC and only +0x38 by +0xF2.  Both words hold 14, so",
    "no address changes -- but the attribution does."]),

"sub_FB46FC": ("PartElement_ResolveEnvDescriptor", "PROVEN", [
    "args (part, element, slot k in 0..3).  Follows the part-element sub-record's",
    "WAVE-SELECT pointer -- 0x1523 + 300*part + 41*element + 0x8C (`ld A,0x29`",
    "0xFB4710, `add IY,0x008c` 0xFB4722, `ld XWA,(XIY+0x1523)` 0xFB4728), which",
    "tone_db_module.s already names -- reads the byte PAIR at +0x03 + 2k and",
    "+0x04 + 2k (0xFB470B/0xFB4732 and 0xFB4736/0xFB473B) and passes it to",
    "ToneDB_ResolveEnvDescriptor (0xFB4745).",
    "★★ SO A WAVE-SELECT RECORD CARRIES FOUR (sel_program, sel_bank_family)",
    "PAIRS, at +0x03/+0x04, +0x05/+0x06, +0x07/+0x08, +0x09/+0x0A -- eight of the",
    "eleven bytes prom_d spells `unk_00[11]`, and they end exactly where",
    "tail_preset (+0x0B) begins."]),

"sub_FB474E": ("WaveSelRec_ResolveEnvDescriptor", "PROVEN", [
    "args (slot k, wave-select record).  The same two bytes at +0x03 + 2k and",
    "+0x04 + 2k (0xFB4754-0xFB476B) into ToneDB_ResolveEnvDescriptor (0xFB4772),",
    "but taking the record pointer directly instead of walking a part.  Six of its",
    "callers are the VoiceParams_Compute_* routines, which is the shortest",
    "statement of what the descriptor is FOR without saying what it means."]),

"sub_FB477B": ("PartElement_SetEnvDescriptorPointer", "PROVEN", [
    "args (part, element, slot k).  Calls PartElement_ResolveEnvDescriptor",
    "(0xFB4791) and stores the answer at 0x1523 + 300*part + 41*element + 0x90 +",
    "4k (`ld C,0x29` 0xFB4796, `ld C,0x04` 0xFB47AA, `add BC,0x0090` 0xFB47B1,",
    "`ld (XBC+0x1523),XIY` 0xFB47B7).",
    "★ THE DESTINATION IS SETTLED FROM OUTSIDE THIS FILE: round 11's",
    "DrawbarPreset_GetDescriptor writes its 14-byte descriptor to the SAME slot,",
    "0x1523 + 300*part + 41*element + 0x90 (0xFC29AC/0xFC29B7).  So the part",
    "element sub-record's +0x08..+0x17 is an array of four descriptor pointers,",
    "and the drawbar path fills one where the melodic path fills four."]),

"sub_FB47C4": ("Part_LoadToneRecordAndPointers", "PROVEN", [
    "args (part, program, bank selector).  The PROGRAM-CHANGE loader:",
    "  1. tone = Part_ResolveToneRecord(part, program, selector) (0xFB47DC), and",
    "     store it in part record +0x00 (0xFB47EE);",
    "  2. switch on ToneRec +0x10 & 0xC0 (0xFB47F3) -- prom_d's `kind`, whose",
    "     bits 7:6 it says `select the loader's arm`.  THIS IS THAT LOADER.",
    "  3. arms 0x00 and 0xC0, for e = 0..3: part element +0x00 =",
    "     Part_GetElementBlock (0xFB4837, stored 0xFB484E at +0x88), +0x04 =",
    "     Part_GetWaveSelectRecord (0xFB485C, stored 0xFB486B at +0x8C), then",
    "     PartElement_SetEnvDescriptorPointer for k = 0..3 (0xFB4880);",
    "  4. arm 0x40, for e = 0..3: the element block as above, then",
    "     PartElement_SetWaveSelectPointer_ToRomDefault (0xFB48CF) and",
    "     DrawbarPreset_GetDescriptor (0xFB48DC) -- both already named, and both",
    "     write the same two slots.  So kind 0x40 is the DRAWBAR arm, which is the",
    "     complement of prom_d's `0x80 is the DRUM path`;",
    "  5. arm 0x80 falls straight through and stores nothing here.",
    "0x0029 is added per element at 0xFB488B/0xFB48E3 -- the 41-byte stride."]),

# --- C. the dsp_algo readers, all unblocked by ToneRec +0xD0 --------------
"sub_FB5636": ("Part_StageDspAlgoParams", "STRONG", [
    "args (part, mode).  Reads the tone's ALGORITHM TYPE, `(XWA+0x00d0)` masked",
    "0x0F at 0xFB564F/0xFB5654, and branches on it: type 7 forces part record",
    "+0x09 bit 15 (`or (XHL+0x1523),0x8000` 0xFB5667) -- the bit prom_d says is",
    "mirrored into ToneRec +0xD0 bit 7 -- writes the three bytes at part record",
    "+0x71/+0x72/+0x73 as either 0F/4F/96 or 01/01/01 depending on +0x09 bit 14,",
    "and then runs the four stagers PartRec_StageChanFreqWord_0065/_0067 (twice",
    "each, chan 0 and 1), _006D and _006F (0xFB56E0-0xFB570C).  Type 0x0A sets",
    "part record +0x06 bit 9 instead (0xFB57C8).  Every other type clears +0x09",
    "bit 15 and zeroes +0x71..+0x73.",
    "GRADE STRONG, not PROVEN: the algorithm type, the four stagers and every",
    "destination offset are decoded, but what +0x71..+0x73 hold is not."]),

"sub_FB582A": ("PartRec_StageChanFreqWord_0065", "PROVEN", [
    "args (part, channel 0..1).  A 12-arm computed goto on the tone's ALGORITHM",
    "TYPE (`cp BC,0x000b` 0xFB5857; DSP_AlgoDescriptor_Records is 12 records).",
    "It takes byte 6*type + 2*chan of DSP_AlgoChannel_SelectorRecords (0xFB58AB /",
    "0xFB58C6 / 0xFB5946, `add XWA,0x00fde6a9`) as a ROW of DSP_ChanFreq_CurvePool,",
    "indexes that row by 2 * dsp_param at ToneRec +0xD1 (chan 0) or +0xD3 (chan 1)",
    "-- 0xFB58E1, 0xFB5915, 0xFB5962 -- with row base 0xFDEA21 = CurvePool + 8*0x66",
    "(0xFB58F6/0xFB592A/0xFB5977), and for types 10 and 11 ORs in",
    "EGEnv_ModeBits_Table[(AlgoDescriptor[39*type + 3*chan + 2] & 0xC0) >> 6]",
    "(0xFB5992 `add XWA,0x00fdf4f1`, 0xFB59A5 `add XBC,0x00fdebec`) -- which is the",
    "use voice_dsp_tables.s already attributes to descriptor byte +0x02, citing",
    "this very address.  The word lands at part record +0x65 + 4*chan (0xFB59BF",
    "`add WA,0x0065`), and Voice_StageChanSel_Reg0440_Reg0480 reads +0x65 at",
    "0xFA9BF8 straight into the 0x0010C000 staging word at 0x00D7A0.",
    "Named by DESTINATION because the destination is decoded and the MEANING of",
    "the curve value is not -- the idiom the tree already uses in",
    "PartRec_ApplyParam_0025 and PartRec_Word0006_SetBit13."]),

"sub_FB59D2": ("PartRec_StageChanFreqWord_0067", "PROVEN", [
    "the twin of PartRec_StageChanFreqWord_0065, differing in exactly four",
    "operands and nothing else: the SECOND byte of the selector pair, 6*type +",
    "2*chan + 1 (`inc 1,XWA` 0xFB5A53/0xFB5A70/0xFB5AF1); dsp_param at ToneRec",
    "+0xD2 / +0xD4 (0xFB5A8D, 0xFB5AC1); curve-pool row base 0xFDE6F1, i.e. row 0",
    "(0xFB5AA2/0xFB5AD6/0xFB5B2B); descriptor byte 39*type + 3*chan + 1 (0xFB5B13);",
    "and destination part record +0x67 + 4*chan (0xFB5B43).  0x00D79C is fed from",
    "+0x67 at 0xFA9C3D.  The pairing of the two routines is the pairing of the two",
    "bytes voice_dsp_tables.s calls `three 2-byte channel pairs per algorithm",
    "type`."]),

"sub_FB5BAA": ("PartRec_StageChanFreqWord_006D", "PROVEN", [
    "args (part).  Only algorithm types 6 and 7 do anything (`cp BC,6` 0xFB5BCF,",
    "`cp BC,7` 0xFB5BD3); every other type stores 0.  Both take the THIRD selector",
    "pair's first byte, 6*type + 4 (`inc 4,XBC` 0xFB5BE0/0xFB5C25, base 0xFDE6A9),",
    "as a curve-pool row with base 0xFDEB53 = CurvePool + 11*0x66 (0xFB5BFF,",
    "0xFB5C4E).  Type 6 indexes it by 2 * dsp_param at ToneRec +0xD1 and ORs",
    "EGEnv_ModeBits_Table[2 * ToneRec +0xD3] (0xFB5C11); type 7 indexes it by",
    "2 * AlgoDescriptor[39*type + 6] (0xFB5C37 -- the `packet sub-index` byte",
    "voice_dsp_tables.s names, citing this address).  Destination part record",
    "+0x6D (0xFB5C64)."]),

"sub_FB5C77": ("PartRec_StageChanFreqWord_006F", "PROVEN", [
    "args (part).  Algorithm types 6 and 7 only (0xFB5CA0/0xFB5CA4); everything",
    "else stores 0.  Selector byte 6*type + 5 (`inc 5,XBC` 0xFB5CB0), curve-pool",
    "row base 0xFDE6F1 = row 0 (0xFB5CDE), indexed by 2 * dsp_param at ToneRec",
    "+0xD2 (0xFB5CC9).  Destination part record +0x6F (0xFB5CF3)."]),

"sub_FB5B56": ("Part_GetDspParam_00D2_Low6", "PROVEN", [
    "args (part).  Returns ToneRec +0xD2 & 0x3F when the tone's ALGORITHM TYPE is",
    "10 or 11, and 0 otherwise (0xFB5B6E/0xFB5B73 for the type, 0xFB5B78/0xFB5B7E",
    "for the two arms, 0xFB5B96/0xFB5B9B for the field).  Its one caller,",
    "Voice_StageChanSel_Reg0440_Reg0480, takes the answer at 0xFA9BD2 and passes",
    "it beside part record +0x65 & 0x1FFF into sub_FA7927 (0xFA9C0C/0xFA9C18)."]),

"sub_FB5D05": ("Part_GetSecondaryParam_AlgoType9", "PROVEN", [
    "args (part).  Returns 0xFF unless part record +0x09 bit 15 is set AND the",
    "ALGORITHM TYPE is exactly 9 (0xFB5D22, 0xFB5D31/0xFB5D36/0xFB5D39); then it",
    "returns Voice_SecondaryParam_Curve[ToneRec +0xD1] (0xFB5D3E, `add",
    "XWA,0x00fdf6c5` 0xFB5D47) and clears part record +0x09 bit 13 (0xFB5D57).",
    "Both the table and the field are named elsewhere; the curve is 31 bytes",
    "descending 0x46..0x00 and voice_dsp_tables.s already cites four other",
    "readers of it."]),

"sub_FB5D6C": ("Part_GetDspParam_00D7", "PROVEN", [
    "args (part).  Returns 0 unless part record +0x09 bit 15 is set (0xFB5D8B).",
    "Then, for ALGORITHM TYPES 10 and 11 only, if AlgoDescriptor[39*type + 0x0D]",
    "bit 7 is set it returns AlgoDescriptor[39*type + 0x0E] instead of the tone's",
    "own byte (0xFB5DB2-0xFB5DDD; voice_dsp_tables.s already states `+0x0D bit 7",
    "selects the +0x0E byte` and cites 0xFB5DC0, which is this instruction).",
    "Otherwise it returns dsp_param at ToneRec +0xD7 (0xFB5DEF)."]),

"sub_FB5E00": ("Part_GetDspParam_00D8", "PROVEN", [
    "args (part).  The whole body is `return part record +0x09 bit 15 ? ToneRec",
    "+0xD8 : 0` (0xFB5E19/0xFB5E1E for the gate, 0xFB5E2B for the field).  +0xD8 is",
    "the LAST byte of prom_d's dsp_param[8] and the last byte of the record head."]),

"sub_FB5F91": ("Voice_Reg0180ModeBits_FromAlgoDesc", "STRONG", [
    "args (part, channel).  Returns 0x0000, 0x4000 or 0xC000.  Algorithm types 6",
    "and 7 only (0xFB5FB7/0xFB5FBB); it reads AlgoDescriptor[39*type + 5*chan +",
    "0x13] (0xFB5FCC/0xFB5FD2/0xFB5FD8 -- the `+0x13 + 5*channel per-channel flag`",
    "voice_dsp_tables.s names), requires its bit 5 (0xFB5FE2), and then returns",
    "0xC000 only when ToneRec +0xD0 bit 6 AND descriptor bit 1 are both set",
    "(0xFB5FFC, 0xFB6003), else 0x4000.",
    "★ ToneRec +0xD0 BIT 6 HAS A READER.  prom_d's block says `Bits 4:6",
    "UNIDENTIFIED`; this instruction and 0xFB5EEB / 0xFB5F36 in",
    "Dev10C_ChanSelHighBits and 0xFB4F44 in the still-refused sub_FB4D45 all gate",
    "on bit 6.  Reported to prom_d, not edited there.",
    "GRADE STRONG: the source bits are decoded and the caller",
    "(Voice_StageRegs_0180_AB, its only one) fixes where the value goes; what",
    "0x4000 versus 0xC000 MEANS is not established -- the same reservation",
    "Dev10C_ChanSelHighBits already records for its own 0x0040/0x00C0."]),

"sub_FB601A": ("Part_GetAlgoDescByte14", "PROVEN", [
    "args (part, channel).  Returns AlgoDescriptor[39*type + 5*chan + 0x14]",
    "(`ld C,0x05` 0xFB603C, `ld C,0x27` 0xFB6046, `add XBC,0x00000014` 0xFB604F,",
    "`add XBC,0x00fdf4f1` 0xFB6055), except that algorithm type 8 on channel 1",
    "returns dsp_param at ToneRec +0xD3 instead (0xFB6061/0xFB606F).  One of the",
    "five byte columns of the per-channel descriptor row +0x13..+0x17."]),

"sub_FB607F": ("Part_GetAlgoDescByte15", "PROVEN", [
    "args (part, channel).  AlgoDescriptor[39*type + 5*chan + 0x15] (0xFB60B9),",
    "with a 9-arm computed goto on the algorithm type (0xFB60CD) that overrides it",
    "on channel 1: types 0-3 use 2 * ToneRec +0xD3 (0xFB6118), types 4-5 use",
    "2 * +0xD5 (0xFB6136), type 8 uses 2 * +0xD2 (0xFB6145).  Types 6, 7 and",
    "anything out of range take the descriptor byte unchanged."]),

"sub_FB6190": ("Part_GetAlgoDescByte16", "PROVEN", [
    "args (part, channel).  AlgoDescriptor[39*type + 5*chan + 0x16] (0xFB61CB),",
    "with a 9-arm goto (0xFB61DF): types 0-3 on channel 1 use ToneRec +0xD5 - 0x64",
    "and then ADD Part_GetAlgoDescByte16_Bias (0xFB622A-0xFB623B); types 4-5 return",
    "the bias alone (0xFB6245); types 6 and 8 on channel 1 use ToneRec +0xD4 - 0x64",
    "(0xFB625E/0xFB6263); type 7 and out-of-range take the byte unchanged."]),

"sub_FB6158": ("Part_GetAlgoDescByte16_Bias", "STRONG", [
    "args (part, channel).  Returns 0xFC (-4) for channel 0, 0xF0 (-16) for",
    "channel 1 and 0 otherwise, but only when part record +0x06 & 0xC000 is",
    "non-zero (0xFB6169/0xFB616E); otherwise 0.",
    "★ THE NAME IS THE CALL GRAPH, the same licence tone_db_module.s took for",
    "ToneRec_LoadDspParams_AlgoTypes0to3: both of its call sites are inside",
    "Part_GetAlgoDescByte16 (0xFB6238, 0xFB6245) and at the first one the result",
    "is added to that routine's descriptor byte (`add A,H` 0xFB623B).  Nothing",
    "else in the image reaches it.",
    "GRADE STRONG: what +0x06 bits 15:14 mean is not established."]),

"sub_FB6272": ("Part_GetAlgoDescByte17", "PROVEN", [
    "args (part, channel).  AlgoDescriptor[39*type + 5*chan + 0x17] (0xFB62C6),",
    "gated on part record +0x09 bit 15 (0xFB6298), with a 9-arm goto (0xFB62DB):",
    "types 0-3 on channel 1 read DSP_ChanFreq_IndexMap[ToneRec +0xD4] (0xFB6327,",
    "`add XBC,0x00fdebb9` 0xFB6330), types 4-5 the same map indexed by +0xD6",
    "(0xFB6356), type 8 by +0xD1 (0xFB6370); those three arms also clear part",
    "record +0x09 bit 13 (0xFB6388).  voice_dsp_tables.s already lists 0xFB6330,",
    "0xFB6356 and 0xFB6372 as that map's three references."]),

"sub_FB639A": ("PartElement_StageAlgoDescBytes_0024", "PROVEN", [
    "args (part).  For e = 0..3 it calls Part_GetAlgoDescByte14, _15 and _16",
    "(0xFB63CC, 0xFB63F5, 0xFB640E) and stores the three answers at part element",
    "sub-record +0x24, +0x25, +0x26 -- 0x1523 + 300*part + 41*e + 0xAC/0xAD/0xAE",
    "(0xFB63E2, 0xFB63FE, 0xFB6417), stepping 0x0029 at 0xFB6425.  When part",
    "record +0x09 bit 15 is clear it writes zeros into the same twelve bytes",
    "instead (0xFB6450, 0xFB645F, 0xFB646E).  Byte +0x17 is NOT staged here;",
    "Part_GetAlgoDescByte17 is called from VoiceParams_Compute_A directly."]),

"sub_FB6487": ("PartRec_StageByte0075_FromDspParam00D7", "PROVEN", [
    "args (part).  Calls Part_GetDspParam_00D7 when part record +0x09 bit 15 is",
    "set (0xFB649F/0xFB64A4/0xFB64AB) and stores the byte -- or 0 -- at part record",
    "+0x75 (0xFB64B5/0xFB64BF).  Two decoded ends: the source is prom_d's",
    "dsp_param, the destination is a part-record byte."]),

"sub_FB64C8": ("PartRec_Word0004_ClearStagedSetBit2", "PROVEN", [
    "args (part).  The whole body is `part record +0x04 &= 0xFFFC; |= 0x0004`",
    "(0xFB64E5 `and (XBC),0xfffc`, 0xFB64F0 `set 0x02,BC`).  tone_db_module.s",
    "names that word: bit 0 = staged, bit 1 tested for part >= 0x21, bit 2 set by",
    "sub_FB9AC2.  So this drops the part out of the staging buffer and raises the",
    "same bit sub_FB9AC2 raises; MidiProgram_SelectToneForPart calls it first",
    "thing (0xFB6C04), before the tone is re-resolved.",
    "Named after the field the tree already names, as PartRec_Word0006_SetBit13 is."]),

"sub_FB6500": ("PartRec_ResetToDefaults", "STRONG", [
    "args (part).  Writes CONSTANTS and nothing else, across the whole part",
    "record: zero into +0x1D and the eleven words +0x1F..+0x33 (0xFB651B-0xFB6560),",
    "zero into the 4 x 3 pairs at +0x37 + 16j + 4e and +0x38 + ... (0xFB6618,",
    "0xFB6626), and 0x40 into the 12 x 2 bytes from +0x76 (0xFB665F).  It also",
    "calls nine setters with a zero argument -- sub_FC7E10, three",
    "Rec8644_Store3Bytes_AndFlagChanged, sub_FC589E, sub_FC59EF, sub_FC5EFB,",
    "sub_FC6175, sub_FC63EC, sub_FC654F, sub_FC65EC.",
    "GRADE STRONG: the verb (write constants), the object (this part's record) and",
    "every offset are decoded; what the fields hold is not.  Its five call sites",
    "are all resets -- PartRec_InitAllParts, MidiProgram_SelectToneForPart,",
    "MidiCtrl_Dispatch and Dev10C_QuiesceListedChans_0800_0840."]),

"sub_FB6681": ("Part_RestageVoiceParams_Melodic", "STRONG", [
    "args (part).  The arm MidiProgram_SelectToneForPart takes when ToneRec +0x10",
    "& 0xC0 is 0x00 or 0xC0 (0xFB6C95-0xFB6CB7) -- the same two values",
    "Part_LoadToneRecordAndPointers routes to its element/wave-select/descriptor",
    "loop.  It runs Part_StageDspAlgoParams, PartRec_StageByte0075_FromDspParam00D7,",
    "PartRec_RecomputeWord0006_FromToneRec and sub_FB4D45 (0xFB6690-0xFB66A8),",
    "then a 3 x 4 pass over the 4-byte records at part record +0x35 followed by",
    "sub_FB53C5 per element (0xFB66C4-0xFB6847), then",
    "PartElement_StageAlgoDescBytes_0024 (0xFB684F), then for each element sub_FC6803",
    "with that element's WAVE-SELECT pointer from +0x8C and a bit tested against",
    "BitMask_Table_FDE695 (0xFB687C-0xFB68AA), and finally sub_FC7481 and",
    "sub_FC81F8.",
    "GRADE STRONG: the arm selector is prom_d's `kind` and every callee above is",
    "named, but three of its own steps are still `sub_`."]),

"sub_FB68DD": ("Part_RestageVoiceParams_Drawbar", "STRONG", [
    "args (part).  The arm MidiProgram_SelectToneForPart takes when ToneRec +0x10",
    "& 0xC0 is 0x40 (0xFB6CBD-0xFB6CCB) -- and 0x40 is the arm",
    "Part_LoadToneRecordAndPointers routes to",
    "PartElement_SetWaveSelectPointer_ToRomDefault and DrawbarPreset_GetDescriptor,",
    "which is what makes it the DRAWBAR kind.  Same shape as",
    "Part_RestageVoiceParams_Melodic and the same closing sequence (sub_FC6803 per",
    "element, sub_FC7481, sub_FC81F8), with sub_FC2CD5 inserted at 0xFB68FC, an",
    "extra 0x0010 step of the outer index at 0xFB6AB9, and no",
    "PartRec_RecomputeWord0006_FromToneRec.",
    "⚠ prom_d says `0x80 is the DRUM path`; 0x80 is the third arm here",
    "(0xFB6CD1) and calls neither of these two.  The three arms are disjoint."]),

"sub_FB4A9F": ("PartRec_RecomputeWord0006_FromToneRec", "STRONG", [
    "args (part).  Rebuilds part record +0x06: it keeps bits 13:4 (`and",
    "WA,0x3ff0` 0xFB4ABA), sets bit 0, 1, 2 or 3 from ToneRec +0x11 bits 0, 2, 4",
    "and 6 (0xFB4AD0, 0xFB4B9A, 0xFB4C62, 0xFB4CBC) -- the element mask, one bit",
    "per element, the same `1 << 2i` positions ToneRec_MapElementIndex_ByMask",
    "reads -- and ORs 0x4001 or 0x8002 through two 9-arm computed gotos whose",
    "arms are all the same target and whose index is the ALGORITHM TYPE bounded",
    "at 8 (0xFB4B0D, 0xFB4BD7).  It also sets or clears bit 15 of the word at",
    "part element sub-record +0x18 for each of the four elements -- +0xA0, +0xC9,",
    "+0xF2, +0x11B, which are 0x88 + 0x18 + 41e (0xFB4B5D, 0xFB4C27, 0xFB4C81,",
    "0xFB4CDB) -- from the 2-bit fields of ToneRec +0x12.",
    "GRADE STRONG: destination and one source are named fields; ToneRec +0x12 is",
    "UNIDENTIFIED in prom_d and this pass does not name it either."]),

"sub_FB4D21": ("Clamp_0_to_007F", "PROVEN", [
    "the whole body is `if (x > 0x7F) x = 0x7F; else if (x < 0) x = 0; return",
    "(s8)x` (0xFB4D29-0xFB4D3F).  Named to match the tree's existing",
    "Clamp_0_to_00FF and Clamp_36_to_120 rather than inventing a second idiom.",
    "Its one caller is the still-refused sub_FB4D45."]),

"sub_FB6B5A": ("ExtBoard_RemapBankSelector", "STRONG", [
    "args (program, bank selector).  Returns the selector unchanged unless it is",
    "exactly 0x10 (0xFB6B5F).  For 0x10 it requires an expansion board -- the",
    "0x00D80D base non-zero (0xFB6B65) -- bounds the program against the board's",
    "byte at 0x00C00031 (0xFB6B73/0xFB6B76) and reads the board's table at",
    "0x00C00000 + byte 0x00C00018 + program (0xFB6B7B-0xFB6B93); the answer is",
    "0x30 when that byte is 1 and 0 otherwise.",
    "★ 0x30 IS THE EXPANSION-BOARD ARM of ToneDB_ResolveToneRecord (`cp HL,0x0030`",
    "0xFB4131), and its caller MidiProgram_SelectToneForPart stores the result in",
    "part record +0x1C, the BANK selector.  So the routine promotes a board tone",
    "from bank 0x10 to bank 0x30.",
    "GRADE STRONG: the board's own record format is undumped, so `byte == 1 means",
    "present` is read off this code alone."]),

"sub_FB6CEE": ("PartRec_InitAllParts", "STRONG", [
    "no arguments.  For every one of the 33 parts (`cp (XIZ+0xf5),0x21` 0xFB6D78)",
    "it zeroes the 4 x 3 bytes at +0x35 + 16j + 41e and the words at +0xA6 + 41e +",
    "2j (0xFB6D36, 0xFB6D44) and calls PartRec_ResetToDefaults (0xFB6D71); then it",
    "calls sub_FA78E8 for all 64 x 3 (chan, slot) pairs (0xFB6D8D); then it writes",
    "0xFF to 0x00D733 and 0x11 to 0x1509 (0xFB6DA1, 0xFB6DA7); then it writes 1",
    "into +0x17, +0x18 and +0x19 of every part record, stepping 0x012C until",
    "0x26AC (0xFB6DC2-0xFB6E02).  0x26AC = 300 * 33 EXACTLY, which is what fixes",
    "the loop as `all parts` rather than a span.",
    "GRADE STRONG: the verb and the object are decoded; the fields are not.  Its",
    "two callers are ExtBoard_ProbeAndInstallBases and sub_FADA7C -- an init path."]),
}

STAR = "★"

# ---------------------------------------------------------------------------
# The EIGHT still refused, with what each turns on.  A refusal is a result.
# ---------------------------------------------------------------------------
REFUSED = {
"sub_FB4D45":
    "writes part element sub-record +0x27 and +0x28 for all four elements "
    "(part record +0xAF/+0xB0 and, for element 1, +0xD8/+0xD9 -- 0x88 + 0x27 + "
    "41e), from clamp(element block +0x01 + part record +0x0D - 0x40) using "
    "Clamp_0_to_007F.  EVERY ONE of those is UNIDENTIFIED: prom_d's element "
    "block is `unk_00[2]` at +0x00..+0x01, and neither part-record field is "
    "named.  The dsp_algo read at 0xFB4F2E-0xFB4F5A only gates a side branch. "
    "So both ends are unnamed and a name would be pure position.  ★ IT DOES "
    "SETTLE ONE THING WORTH RECORDING: 0xFB4F44 `and A,0x40` is a reader of "
    "ToneRec +0xD0 BIT 6, which prom_d lists as UNIDENTIFIED. "
    "WHAT WOULD SETTLE IT: element parameter block +0x01, or part record +0x0D.",

"sub_FB501F":
    "clears bits 0:1 of the byte at part record +0x35 + 16j + 4k and sets bit 0 "
    "when any of the four elements has bit 5 set and bits 7:6 equal to k in its "
    "element block byte +0x06, +0x26 or +0x38 (chosen by j).  prom_d's "
    "ToneRec_Element gives +0x04..+0x4C as `unk`, and nothing names the 4 x 4 "
    "array of 4-byte records at part record +0x35.  Both ends unnamed. "
    "WHAT WOULD SETTLE IT: element parameter block +0x06/+0x26/+0x38, whose "
    "bit 5 and bits 7:6 this pass MEASURED (enable, plus a 2-bit selector "
    "compared against k) without being able to say what they select.",

"sub_FB5103":
    "the same routine one bit-pair over: clears bits 2:3 of the same byte and "
    "sets bit 2, reading only element block +0x06.  Refused for the same reason "
    "as sub_FB501F, and it would be worse to name one of the pair and not the "
    "other.",

"sub_FB519C":
    "⚠ NOT REFERENCED -- no literal call/calr/jp/jrl anywhere in the image. "
    "Writes a word at arg0 + 0x1E + 2*arg3 built from a 2-bit selector and one "
    "of the constants 0xC0 / 0xC000 / 0x3300 / 0x1100 / bit 6 / bit 14, gated on "
    "the two byte tables at 0xFDE6A1 and 0xFDE6A5 (`1 << 2i` and `1 << (2i+1)`) "
    "ANDed against byte +0x01 of its second argument.  Its destination offset is "
    "shared with sub_FB53C5, so the object is probably the part element "
    "sub-record -- PROBABLY is not a grade.  WHAT WOULD SETTLE IT: a caller.",

"sub_FB52A5":
    "unreferenced, and a strict subset of sub_FB53C5's inner arm 0: writes "
    "arg0 + 0x1E + 2*arg1 with (k | 0xC0) or (k | 0x40) when a flag byte has "
    "bit 5 set and bits 7:6 equal to k, splitting on bit 4.  The flag byte is "
    "passed in, so not even its record is decided here.",

"sub_FB5304":
    "unreferenced; identical to sub_FB52A5 with the constants moved into the "
    "high half (0xC000 / bit 14 instead of 0xC0 / bit 6).",

"sub_FB5364":
    "unreferenced; identical again with the constants 0x3300 and 0x1100.  The "
    "three together are the three arms sub_FB53C5 has inline, which is a "
    "suggestive shape and not a name.",

"sub_FB53C5":
    "args (part, element, k).  Writes ONE word at part element sub-record "
    "+0x1E + 2k, chosen by scanning all four elements' +0x35 records and their "
    "element block bytes +0x06 / +0x26 / +0x38, with the same 0xFDE6A1 / "
    "0xFDE6A5 bit-pair tables and the same six constants as sub_FB519C.  It is "
    "the live version of that family and it is REFERENCED (ten call sites), but "
    "every field it reads and the field it writes are all UNIDENTIFIED. "
    "WHAT WOULD SETTLE IT: the same element-block bytes as sub_FB501F, plus "
    "part element sub-record +0x1E.",
}

HEADER_RE = re.compile(r"^; (sub_[0-9A-F]{6}) -- 0x[0-9A-F]{6}\.\.")


# ---------------------------------------------------------------------------
# the applier
# ---------------------------------------------------------------------------
def rename_code(line, table):
    """Rewrite only the code half of `line` (everything before the first `;`)."""
    if ";" in line:
        code, sep, rest = line.partition(";")
    else:
        code, sep, rest = line, "", ""
    for old, new in table.items():
        code = re.sub(r"\b" + old + r"\b(?!__)", new, code)
    return code + sep + rest


def apply_to(path):
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    table = {o: v[0] for o, v in RENAMES.items()}
    out, renamed, annotated, refused = [], 0, 0, 0
    for line in lines:
        m = HEADER_RE.match(line)
        if m and m.group(1) in RENAMES:
            new, grade, why = RENAMES[m.group(1)]
            # ⚠ The old label is spelled as an ADDRESS here, never as the token
            # `sub_XXXXXX`.  sync_comments_to_renamed_labels.py substitutes that
            # token everywhere it appears in a comment, which would turn this
            # line into "`X` is now `X`" and delete the very provenance it
            # carries.  The address-form spellings live in the committed
            # notes/prom_c_voice_tonedb_w18.rename-map instead.
            addr = m.group(1)[4:]
            out.append(f"; {STAR} NAMED (wave 18): the routine at 0x{addr} is now `{new}`.")
            out.append(f";   GRADE {grade}.  WHY `{new}`:")
            for w in why:
                out.append(f";   {w}")
            annotated += 1
        elif m and m.group(1) in REFUSED:
            out.append(f"; {STAR} NOT NAMED (wave 18): `{m.group(1)}` stays an address.")
            out.append(";   The wave 17 refusal of 0xFB405F-0xFB6E09 was lifted for 42 of its 50")
            out.append(";   routines by prom_d's dsp_algo / dsp_param decode.  It is NOT lifted")
            out.append(";   here, and this is why:")
            for w in _wrap(REFUSED[m.group(1)], 72):
                out.append(f";   {w}")
            refused += 1
        new_line = rename_code(line, table)
        if new_line != line:
            renamed += 1
        out.append(new_line)
    path.write_text("\n".join(out), encoding="utf-8")
    return renamed, annotated, refused


def _wrap(s, width):
    words, line, out = s.split(), "", []
    for w in words:
        if line and len(line) + 1 + len(w) > width:
            out.append(line)
            line = w
        else:
            line = (line + " " + w) if line else w
    if line:
        out.append(line)
    return out


# ---------------------------------------------------------------------------
# --claims: re-read every literal this table quotes, out of the ROM image
# ---------------------------------------------------------------------------
_fail = []
_n = 0


def cbytes(addr, n):
    o = addr - C_BASE
    return C[o:o + n]


def check(msg, ok, detail=""):
    global _n
    _n += 1
    print("   %s  %s%s" % ("ok  " if ok else "FAIL", msg,
                           ("   [%s]" % detail) if detail else ""))
    if not ok:
        _fail.append(msg)


def count_image(value, width):
    want = value.to_bytes(width, "little")
    n, i = 0, C.find(want)
    while i >= 0:
        n += 1
        i = C.find(want, i + 1)
    return n, len(C) / float(1 << (8 * width))


def cite(addr, value, width, what, window=10):
    """Does the instruction at `addr` carry `value` as a little-endian operand?
    The image-wide occurrence count beside it is the null: a 3- or 4-byte
    literal is expected far below once by chance, a 1-byte one ~2,048 times."""
    hit = value.to_bytes(width, "little") in cbytes(addr, window)
    got, exp = count_image(value, width)
    check("0x%06X carries 0x%0*X  -- %s" % (addr, width * 2, value, what), hit,
          "image-wide %d, by chance %.4f" % (got, exp))


def opbytes(addr, hexs, what):
    """The STRONGEST form: the instruction at `addr` BEGINS with these bytes.
    Used for register+displacement operands, which are not standalone literals."""
    want = bytes.fromhex(hexs)
    check("0x%06X begins %s  -- %s" % (addr, hexs, what),
          cbytes(addr, len(want)) == want)


def claims():
    print("\nA. THE `1 << 2i` ELEMENT-MASK TABLE")
    check("0xFDE69D holds 01 04 10 40 -- bit 2i for i = 0..3",
          cbytes(0xFDE69D, 4) == bytes.fromhex("01041040"),
          cbytes(0xFDE69D, 12).hex(" "))
    cite(0xFB407E, 0xFDE69D, 3, "ToneRec_MapElementIndex_ByMask reads it")
    cite(0xFB40E2, 0xFDE69D, 3, "ToneRec_CountElements_ByMask reads it")

    print("\nB. THE STAGING IMAGE, AND THAT THE THREE REGIONS TILE")
    check("0x008A9B - 0x0087D2 == 713, the tone record", 0x008A9B - 0x0087D2 == 713)
    check("0x008C33 - 0x0087D2 == 713 + 408", 0x008C33 - 0x0087D2 == 713 + 408)
    cite(0xFB4117, 0x0087D2, 3, "ToneStage_RecordForBankSelector, tone arm")
    cite(0xFB410E, 0x008A9B, 3, "ToneStage_RecordForBankSelector, kit arm")
    cite(0xFB4331, 0x008C33, 3, "the drum-instrument arm of ToneRec_GetElementBlock")
    cite(0xFB4517, 0x21D, 4, "Part_GetWaveSelectRecord staged: +0x21D = 217 + 4*81")
    check("0x21D == 217 + 4*81", 0x21D == 217 + 4 * 81)
    cite(0xFB459E, 0x4A1, 4, "Part_GetPercWaveSelectRecord staged: 0x461 + 0x40")
    check("0x4A1 - 0x461 == 0x40, PercInst.wavesel", 0x4A1 - 0x461 == 0x40)
    cite(0xFB4A19, 0x461, 4, "Part_ResolveDrumInstrumentRecord staged")

    print("\nC. ToneRec_GetWaveSelectRecord IS record + 0xD9 + 81*N + 43*i")
    cite(0xFB4439, 0x2B, 1, "`ld A,0x2b` -- the 43-byte WaveSelRec stride")
    for a, v, n in ((0xFB443F, 0x51, 1), (0xFB445C, 0xA2, 2),
                    (0xFB4479, 0xF3, 3), (0xFB4496, 0x144, 4)):
        cite(a, v, 4, "N = %d arm skips %d = 81*%d bytes of element blocks" % (n, v, n))
        check("0x%X == 81 * %d" % (v, n), v == 81 * n)
    cite(0xFB44CA, 0x144, 4, "ToneRec_..._ByBankSelector assumes N = 4")
    cite(0xFB4561, 0x2E, 4, "PercInst_GetWaveSelectRecord: 0x12 + 0x2E = 0x40")
    check("0x12 + 0x2E == 0x40, PercInst.wavesel", 0x12 + 0x2E == 0x40)

    print("\nD. ToneDB_ResolveEnvDescriptor's THREE (map, array, stride) TRIPLES")
    opbytes(0xFB4668, "a924", "family 0x00/0xC0 -> dir +0x24 ToneDB_ToneIndexMapC")
    opbytes(0xFB466E, "a930", "                -> dir +0x30 ToneDB_EnvDescTable")
    opbytes(0xFB4679, "d3e5ec00", "                -> stride dir +0xEC")
    opbytes(0xFB468C, "a92c", "family 0x40     -> dir +0x2C ToneDB_DrumToneIndexMap")
    opbytes(0xFB4692, "a938", "                -> dir +0x38 EnvDescTable_Perc")
    opbytes(0xFB469D, "d3e5f200", "                -> stride dir +0xF2")
    opbytes(0xFB46B3, "a928", "family 0x80     -> dir +0x28 ToneDB_ToneIndexMapD")
    opbytes(0xFB46B9, "a934", "                -> dir +0x34 (the +0x30 alias)")
    opbytes(0xFB46C4, "d3e5ec00", "                -> stride dir +0xEC")
    check("prom_d's block gives +0xF2 for +0x30/+0x34 too -- the ROM says +0xEC",
          cbytes(0xFB4679, 4) == cbytes(0xFB46C4, 4) != cbytes(0xFB469D, 4),
          "0xFB4679 == 0xFB46C4 != 0xFB469D")

    print("\nE. A WAVE-SELECT RECORD CARRIES FOUR SELECTOR PAIRS AT +0x03..+0x0A")
    opbytes(0xFB4710, "2129", "PartElement_ResolveEnvDescriptor: `ld A,0x29`")
    cite(0xFB4722, 0x8C, 2, "part element sub-record +0x04, the wave-select pointer")
    check("+0x03 + 2k and +0x04 + 2k for k = 0..3 span +0x03..+0x0A, and 0x0B is"
          " tail_preset", 3 + 2 * 3 + 1 == 0x0A)

    print("\nF. THE DESCRIPTOR-POINTER ARRAY AT PART ELEMENT SUB-RECORD +0x08")
    opbytes(0xFB4796, "2329", "PartElement_SetEnvDescriptorPointer: 41-byte stride")
    opbytes(0xFB47AA, "2304", "                                    4-byte entries")
    cite(0xFB47B1, 0x90, 2, "base 0x88 + 0x08")
    cite(0xFC29AC, 0x90, 2, "DrawbarPreset_GetDescriptor writes the SAME slot")

    print("\nG. THE dsp_algo READERS")
    cite(0xFB58AB, 0xFDE6A9, 3, "_0065 -> DSP_AlgoChannel_SelectorRecords")
    cite(0xFB58F6, 0xFDEA21, 3, "_0065 -> DSP_ChanFreq_CurvePool row 8")
    check("0xFDEA21 == CurvePool + 8*0x66", 0xFDEA21 - 0xFDE6F1 == 8 * 0x66)
    cite(0xFB5992, 0xFDF4F1, 3, "_0065 -> DSP_AlgoDescriptor_Records")
    cite(0xFB59A5, 0xFDEBEC, 3, "_0065 -> EGEnv_ModeBits_Table")
    cite(0xFB5AA2, 0xFDE6F1, 3, "_0067 -> DSP_ChanFreq_CurvePool row 0")
    cite(0xFB5BFF, 0xFDEB53, 3, "_006D -> DSP_ChanFreq_CurvePool row 11")
    check("0xFDEB53 == CurvePool + 11*0x66", 0xFDEB53 - 0xFDE6F1 == 11 * 0x66)
    cite(0xFB5D47, 0xFDF6C5, 3, "Part_GetSecondaryParam_AlgoType9 -> the curve")
    cite(0xFB6330, 0xFDEBB9, 3, "Part_GetAlgoDescByte17 -> DSP_ChanFreq_IndexMap")
    check("DSP_AlgoDescriptor_Records is 12 x 39 = 468 bytes",
          0xFDF6C4 - 0xFDF4F1 + 1 == 12 * 39)

    print("\nH. PartRec_InitAllParts COVERS EXACTLY THE 33 PARTS")
    cite(0xFB6DFE, 0x26AC, 2, "the loop bound")
    check("0x26AC == 300 * 33", 0x26AC == 300 * 33)
    cite(0xFB6D78, 0x21, 1, "and the per-part loop stops at part 0x21 = 33")

    print("\nI. THE CENSUS OF ToneRec +0xD0 READS, SWEPT NOT SAMPLED")
    loads, masks, owners = _d0_census()
    check("21 loads of ToneRec +0xD0 in 0xFB405F-0xFB6E09", len(loads) == 21,
          " ".join("%06X" % a for a in loads))
    check("16 of them are masked 0x0F -- the ALGORITHM TYPE",
          len(masks["0f"]) == 16, " ".join("%06X" % a for a in masks["0f"]))
    check("...spread over 15 routines (0xFB4A9F loads it twice)",
          len(owners) == 15, " ".join("%06X" % a for a in owners))
    check("4 mask 0x40 -- ToneRec +0xD0 BIT 6, which prom_d calls UNIDENTIFIED",
          len(masks["40"]) == 4, " ".join("%06X" % a for a in masks["40"]))
    check("1 masks 0x80 -- bit 7, in MidiProgram_SelectToneForPart",
          len(masks["80"]) == 1, " ".join("%06X" % a for a in masks["80"]))
    check("no read of +0xD0 in this block masks 0x10 or 0x20 -- bits 4:5 stay"
          " unread", not masks["10"] and not masks["20"])

    print("\n   %d checks, %d failed" % (_n, len(_fail)))
    return 1 if _fail else 0


def _d0_census():
    """Sweep the block's own listing for every `ld r,(rr+0x00d0)` and classify it
    by which `and r,imm` the loaded value reaches.

    HOW, said plainly because it is a heuristic and not a proof: the load's
    DESTINATION register is tainted; a following `ld rB,rA` with rA tainted
    taints rB; an `and rX,imm` with rX tainted is attributed to this load.  The
    follow stops after 16 listing lines or at the next routine, whichever comes
    first, and it does NOT model branches -- so it can over-attribute across an
    arm boundary.  It is used only to COUNT, and its counts are printed with the
    addresses so a reader can check any one of them by hand.

    Reads the .s file, not the ROM, because the question is about the DECODE --
    and the decode is what the byte gate certifies."""
    txt = TARGET.read_text(encoding="utf-8")
    rows = [(int(a, 16), t.strip()) for a, t in
            re.findall(r";\s([0-9A-F]{6})\s\s(.*)$", txt, re.M)]
    blk = sorted(set(r for r in rows if 0xFB405F <= r[0] <= 0xFB6E09))
    idx = {a: i for i, (a, _t) in enumerate(blk)}
    labs = sorted(int(m.group(1), 16) for m in
                  re.finditer(r"^; \S+ -- 0x(FB[0-9A-F]{4})\.\.", txt, re.M)
                  if 0xFB405F <= int(m.group(1), 16) <= 0xFB6E09)
    loads = [a for a, t in blk if "0x00d0" in t]
    masks = {k: [] for k in ("0f", "10", "20", "40", "80")}
    owners = set()
    for a in loads:
        dst = re.match(r"ld (\w+),\(", dict(blk)[a]).group(1)
        taint, own = {dst}, max(l for l in labs if l <= a)
        for k in range(1, 17):
            j = idx[a] + k
            if j >= len(blk) or max(l for l in labs if l <= blk[j][0]) != own:
                break
            t = blk[j][1]
            m = re.match(r"ld (\w+),(\w+)$", t)
            if m and m.group(2) in taint:
                taint.add(m.group(1))
                continue
            m = re.match(r"and (\w+),0x([0-9a-f]{2})$", t)
            if m and m.group(1) in taint and m.group(2) in masks:
                masks[m.group(2)].append(blk[j][0])
                if m.group(2) == "0f":
                    owners.add(own)
                break
    return loads, masks, sorted(owners)


# ---------------------------------------------------------------------------
def report():
    txt = TARGET.read_text(encoding="utf-8")
    print("\nnote_engine.s 0xFB405F-0xFB6E09 -- %d renamed, %d refused, %d total"
          % (len(RENAMES), len(REFUSED), len(RENAMES) + len(REFUSED)))
    for old, (new, grade, _w) in sorted(RENAMES.items()):
        here = "   " if re.search(r"^(?:%s|%s):" % (old, new), txt, re.M) else " ? "
        print("  %s%s -> %-45s %s" % (here, old, new, grade))
    print("\n  REFUSED (%d):" % len(REFUSED))
    for k, v in sorted(REFUSED.items()):
        print("    %s: %s" % (k, _wrap(v, 66)[0] + " ..."))
    return 0


def check_landed():
    txt = TARGET.read_text(encoding="utf-8")
    bad = [old for old in RENAMES if re.search(r"^%s:" % old, txt, re.M)]
    left = sorted(set(re.findall(r"^(sub_[0-9A-F]{6}):", txt, re.M)))
    print("  %d renamed, %d labels still address-form in note_engine.s"
          % (len(RENAMES), len(left)))
    for b in bad:
        print("  FAIL", b, "still defined")
    missing = [k for k in REFUSED if k not in left]
    for m in missing:
        print("  FAIL", m, "was supposed to stay address-form")
    return 1 if bad or missing else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--claims", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    if a.apply:
        r, n, f = apply_to(TARGET)
        print("  %s  %d code line(s) renamed, %d named block(s), %d refusal block(s)"
              % (TARGET.name, r, n, f))
        return 0
    if a.claims:
        return claims()
    if a.check:
        return check_landed()
    return report()


if __name__ == "__main__":
    sys.exit(main())
