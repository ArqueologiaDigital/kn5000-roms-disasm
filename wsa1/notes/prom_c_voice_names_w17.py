#!/usr/bin/env python3
"""Wave 17 -- the semantic names given to the prom_c voice subsystem's `sub_` labels.

QUESTION THIS ANSWERS
    "Which address-form labels in wsa1/prom_c/voice/ were renamed in wave 17, to
    what, on what evidence, and at what confidence?"  The table below IS the
    answer; this file is both the record and the tool that applied it, so the
    rename can be re-derived, audited or reverted from one place.

RUN
    python3 wsa1/notes/prom_c_voice_names_w17.py --report    # the table
    python3 wsa1/notes/prom_c_voice_names_w17.py --apply     # do the rename
    python3 wsa1/notes/prom_c_voice_names_w17.py --check     # assert it landed

HOW IT RENAMES, AND WHY IT IS SAFE
    * It rewrites only the CODE half of a line (everything before the first `;`).
      Comments are never touched, because
      `scripts/analysis/assert_comments_preserved.py` requires the base's comment
      sequence to be a SUBSEQUENCE of the new one -- rewording one character fails.
      That is why every `; sub_FAxxxx -- 0x...` header line below the new name
      still spells the old address-form name: it is a historical comment, kept
      verbatim, and the `; * NAMED (wave 17 ...)` block inserted ABOVE it carries
      the current label.
    * `sub_XXXXXX__YYYYYY` internal branch labels are deliberately NOT renamed --
      the same choice the tree already made for `ChanRec_Release`, whose internal
      labels are still `sub_FA6528__FA65B7`.  The regex requires the token not to
      be followed by `__`.
    * A rename must not move a byte.  The gate is
        make LLVM_MC=<snap> gate-all      (13/13 byte-identical, 8/8 assembling)

GRADES (this tree's ladder)
    PROVEN  -- a reader or a writer settles it; usually the whole body.
    STRONG  -- several independent facts agree (body + every caller + a field the
               value reaches).
    WEAK    -- one suggestive pattern.  Nothing below is graded WEAK; a WEAK
               reading was left as `sub_`.
"""
import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
FILES = [ROOT / "wsa1/prom_c/voice/voice_leaf_helpers.s",
         ROOT / "wsa1/prom_c/voice/voice_parameters.s",
         ROOT / "wsa1/prom_c/voice/note_engine.s"]

# old label -> (new label, grade, reason lines)
RENAMES = {
# ---------------------------------------------------------------- leaf helpers
"sub_FA5949": ("MidiIn_StoreRingBacklog", "PROVEN", [
    "the whole body is `(0x008678) = (XIZ+0x08)`, and its ONE caller pushes the",
    "ring byte count it has just guarded (`cp DE,4` 0xFB0619, `push DE` 0xFB061E).",
    "0x008678 is read only by ChanAlloc_ForNoteRequest, which compares it against",
    "0x20/0x30/0x40/0x50 to pick how hard to work for a free channel."]),
"sub_FA5958": ("MidiNote_StoreStatusBit3", "PROVEN", [
    "the whole body is `(0x008677) = (XIZ+0x08)`, and its ONE caller pushes",
    "`msg[0] & 0x08` (0xFB3F50-0xFB3F55) -- bit 3 of the message's status byte.",
    "0x008677 is read only by ChanAlloc_ForNoteRequest, as the flag that chooses",
    "between two sets of backlog thresholds."]),
"sub_FA5967": ("Rec0E3E_GroupOfIndex", "PROVEN", [
    "body: index < 0x40 -> 0, 0x40..0x7F -> 4, 0x80..0xBF -> 8, else 0.  Both",
    "callers pass a 0x0E3E slot index and hand the result straight to",
    "Rec0E3E_MoveToList as its COLUMN argument, so the three values are the three",
    "64-slot groups the 192-record array is divided into."]),
"sub_FA598C": ("Rec0E3E_IndexWithinGroup", "PROVEN", [
    "body: selector&3 == 0 or 1 -> i & 0x3F; == 2 -> (i - 0x40) & 0x7F;",
    "== 3 -> i & 0x7F.  Every caller passes a 0x0E3E slot index and uses the",
    "result as the low byte of a (selector, index) pair."]),
"sub_FA59CE": ("Rec11FE_UnlinkFromRing", "PROVEN", [
    "body: with rec = 0x11FE + 12*chan and ring r, it does",
    "`next=rec[r]; prev=rec[r+4]; A[prev][r]=next; A[next][r+4]=prev;`",
    "`rec[r]=rec[r+4]=chan` -- a circular doubly-linked unlink and self-link."]),
"sub_FA5A36": ("Rec11FE_InsertIntoRing", "PROVEN", [
    "body: the same unlink, then splices `chan` in beside the third argument's",
    "record on ring r, using the same next=[r] / prev=[r+4] pair."]),
"sub_FA5ACA": ("Rec11FE_BindRingToSlot", "PROVEN", [
    "body: detaches chan's ring r from the 0x0E3E slot it currently names",
    "(handing that slot's owner byte [+4] to the next channel on the ring, or",
    "0xFF when chan was alone), then links chan into the new slot's ring and",
    "stores the new slot index in rec11FE[chan][8+r]."]),
"sub_FA5B70": ("Rec0E3E_UnlinkFromRing", "PROVEN", [
    "body: with s = 0x0E3E + 5*index, `next=s[0]; prev=s[1];`",
    "`S[prev][0]=next; S[next][1]=prev; s[0]=s[1]=index` -- unlink + self-link."]),
"sub_FA5BC7": ("Rec0E3E_InsertBeforeInRing", "PROVEN", [
    "body: the same unlink, then inserts the first argument's record immediately",
    "before the second's in the [0]=next / [1]=prev ring."]),
"sub_FA5C43": ("Rec0E3E_MoveToList", "PROVEN", [
    "body: takes slot `s` off the list named by its own s[+2] (part) and s[+3]",
    "(column) in the head table at 0x0AA8, links it onto list (arg2, arg3) --",
    "self-linking when that head reads 0xFF -- and then stores arg2 into s[+2]",
    "and arg3 into s[+3]."]),
"sub_FA5CE9": ("Rec11FE_ReleaseAllRings", "PROVEN", [
    "body: for r = 0..3, if rec11FE[chan][8+r] < 0xC0 and that slot's owner byte",
    "[+4] is chan, hand ownership to the next channel on the ring (or 0xFF),",
    "Rec0E3E_MoveToList(slot, 0x21, Rec0E3E_GroupOfIndex(slot)) -- part 0x21 is",
    "one past the 33 real parts, i.e. the free list -- unlink the ring, and store",
    "0xFF in rec11FE[chan][8+r]."]),
"sub_FA5D84": ("VoiceSlots_InitAllTables", "PROVEN", [
    "body: fills all three tables with their own strides and counts --",
    "0x11FE 64 x 12 (rings self-linked, slot bytes 0xFF), 0x0E3E 192 x 5 (rings",
    "self-linked, owner 0xFF), 0x0AA8 34 x 27 (all 0xFF) -- then puts all 192",
    "slots on the free list with Rec0E3E_MoveToList(s, 0x21, group)."]),
"sub_FA5E82": ("Rec0E3E_FreeListHead", "PROVEN", [
    "body: reads 0x0AA8 + 0x37B + {0, 4, 8} by a 2-bit selector.  0x37B = 27*33,",
    "so the row is part 33 -- the free row, one past the 33 real parts -- and the",
    "three columns are Rec0E3E_GroupOfIndex's three values."]),
"sub_FA6026": ("VoiceSlots_ReleaseChanAndReturnNone", "PROVEN", [
    "body: if chan < 0x40 call Rec11FE_ReleaseAllRings(chan); return",
    "((sel & 0x3F) << 8) | 0xFF -- the same two-byte (selector, result) shape",
    "Voice_LookupDev10CChanIndex returns, with 0xFF meaning `no slot`."]),
"sub_FA6051": ("VoiceSlots_ReleaseThenLookup", "PROVEN", [
    "body is two calls and nothing else: VoiceSlots_ReleaseChanAndReturnNone",
    "then Voice_LookupDev10CChanIndex on the same channel.",
    "⚠ NOT REFERENCED -- no literal call/calr/jp/jrl and no 24- or 32-bit pointer",
    "in the 512 KiB reaches it.  The BODY is the evidence for the name, not a",
    "caller; the precedent for naming an unreferenced routine from its body alone",
    "is Clamp_ToRange_Word_b (0xFA78C6)."]),
"sub_FA607B": ("VoiceSlots_ListSlotsOfChannel", "PROVEN", [
    "body: walks rec11FE[chan] rings 0..3, keeps a ring whose slot's",
    "Table_FE1129 code passes the caller's (value, mask) filter, and appends",
    "(code << 8) | Rec0E3E_IndexWithinGroup(slot) to the buffer at RAM 0x0086FC,",
    "terminating it with 0xFFFF.  ⚠ NOT REFERENCED (see VoiceSlots_ReleaseThenLookup)."]),
"sub_FA6110": ("VoiceSlots_ListSlotsOfPart", "PROVEN", [
    "body: walks the 27 columns of the 0x0AA8 row for one part, and for each",
    "column whose Table_FE1129 code passes the caller's (value, mask) filter walks",
    "that column's ring of slots, appending (code << 8) |",
    "Rec0E3E_IndexWithinGroup(slot) to the buffer at RAM 0x0086 7A, 0xFFFF-terminated."]),
"sub_FA61BD": ("VoiceSlots_ListChannelsOfPart", "PROVEN", [
    "body: the same 0x0AA8 row walk, but for each surviving column it follows the",
    "slot's owner byte [+4] into the 0x11FE ring and appends CHANNEL numbers to",
    "the buffer at RAM 0x00877E, 0xFF-terminated.",
    "⚠ NOT REFERENCED (see VoiceSlots_ReleaseThenLookup)."]),
"sub_FA6269": ("VoiceSlots_ReapOrphansInBank", "PROVEN", [
    "body: over the 48 slots of one bank (`mul BC,0x30` on the bank number, 4",
    "banks x 48 = the 192 slots), any slot whose owner byte [+4] is > 0x40 and",
    "whose part [+2] is not already 0x21 is put back on the free list.  Its one",
    "caller is Dev10C_PollBankAndRetire's tail, once per bank sweep."]),
"sub_FA62DA": ("ChanRec_RelinkToPoolQueue", "PROVEN", [
    "body: unlinks the channel record from the queue named by its OWN cursor",
    "pair rec[+0x0F] (pool base) / rec[+0x11] (queue index), decrementing that",
    "queue's occupancy byte at base+idx+0x10 or +0x17 (chosen by bit 0 of the",
    "channel number rec[+0x14]); links it onto queue arg2 of pool arg1 through",
    "the rec[+0x00]/rec[+0x02] link pair; stores the new cursor and increments",
    "the new queue's occupancy byte."]),
"sub_FA643F": ("ChanRec_RelinkToPartQueue", "PROVEN", [
    "the same routine one link pair over: it uses rec[+0x04]/rec[+0x06] as the",
    "links and rec[+0x0C]/rec[+0x0E] as the cursor, and keeps no occupancy count.",
    "ChanRec_Release passes it 0x041C + 6*33 -- the row one past the 33 parts."]),
"sub_FA65BD": ("ChanRec_ToPoolQueue6_SetFlag1", "PROVEN", [
    "body: if rec[+0x12] & 3 is zero, clear flag bits 2 and 3, set bit 1, and",
    "ChanRec_RelinkToPoolQueue(rec, rec[+0x0F], 6) -- queue 6 of the record's own",
    "pool, which is the queue ChanRec_Release also uses."]),
"sub_FA65F6": ("ChanRec_BeginRelease", "PROVEN", [
    "body: held channels (flag bit 7) are left alone; a channel whose cached",
    "0x0180 read-back rec[+0x15] has fallen below 0x80 goes to",
    "ChanRec_ToPoolQueue6_SetFlag1; otherwise, if flag bit 3 is set, bit 3 is",
    "cleared, bit 2 set, and the record relinked to pool queue rec[+0x16]."]),
"sub_FA69FD": ("ChanAlloc_FindVictim", "PROVEN", [
    "body: walks a 0xFF-terminated byte list of queue codes in priority order",
    "(bit 7 = a queue of the shared pool at 0x03E0, else a queue of the pool the",
    "part object's first word names), takes the first non-empty queue whose",
    "occupancy byte is non-zero, and returns the first record on it whose channel",
    "number rec[+0x14] has the wanted parity, or 0."]),
"sub_FA6BB5": ("ChanAlloc_ForNoteRequest", "PROVEN", [
    "body: bounds the request's part index with `cp A,0x21`, then for each of the",
    "four element slots req[+2+i] runs ChanAlloc_FindVictim over the search order",
    "in the 6-byte ROM record at 0xFE1220 + 6*(req[+2+i] & 0x0F), stamps the note",
    "into rec[+0x13], the flag byte 0x08/0x88 into rec[+0x12], relinks the record",
    "to a pool queue and to the part's queue 0, and writes the channel number",
    "into req[+0x0A+i] (0xFF when nothing was found).  Its five callers are",
    "VoiceParams_Compute_A..D and VoiceRecords_InitFromAlloc, whose own header",
    "already reads \"asks the allocator for voices\"."]),
"sub_FA6EA5": ("ChanRec_ClearHoldAndRelease", "PROVEN", [
    "body: clears flag bit 7 of rec[+0x12], clears the channel's bit in the",
    "0x0087C7 hold mask, then calls ChanRec_BeginRelease on the same record."]),
"sub_FA6EFA": ("ChanRec_ReleaseByChannel", "PROVEN", [
    "body: rejects chan >= 0x40, relinks the record to queue 1 of its own part",
    "object, calls ChanRec_BeginRelease, and unlinks it from the",
    "rec[+0x08]/rec[+0x0A] pair.  Its one caller is MidiNote_OffTail."]),
"sub_FA6F48": ("ChanRec_ReleaseQueueAndCollect", "PROVEN", [
    "body: walks one part queue; unless the caller passes the `any note` flag it",
    "keeps only records whose rec[+0x13] equals the wanted note; each kept record",
    "is relinked to part queue 1, passed to ChanRec_BeginRelease, has its channel",
    "number rec[+0x14] appended to the caller's output list, and is unlinked from",
    "the rec[+0x08]/rec[+0x0A] pair.  The list is 0xFF-terminated."]),
"sub_FA6FE0": ("VoiceQuery_Run", "PROVEN", [
    "its six callers are exactly the six VoiceQuery_Tag* wrappers, and it is the",
    "whole body of all six: it selects on the request's tag byte req[0] (bits",
    "0x80 / 0x40) and on req[+3] bit 7, walks part queue 0 and/or queue 1 of",
    "0x041C + 6*part -- or all 64 channel records when req[+3]'s part field is",
    "non-zero -- and writes the matching channel numbers to req+5, 0xFF-terminated."]),
"sub_FA727D": ("VelSplit_LayerFromVelocity", "PROVEN", [
    "body: `v = arg & 0x7F`; returns 0/1/2/3 for v <= t[0] / t[1] / t[2] / above.",
    "Every caller passes VoiceParams_Compute_A's fourth argument, and",
    "MidiNote_OnByPartMode pushes MidiNote_Dispatch's msg[3] into that slot",
    "(0xFB38A4 / 0xFB38B7), i.e. the VELOCITY."]),
"sub_FA72B3": ("VelSplit_LayerFromVelocity_b", "PROVEN", [
    "byte-for-byte identical to VelSplit_LayerFromVelocity (54 bytes, 0 differ,",
    "prom_c_module_map.py --dups) and reached with the same argument from",
    "VoiceParams_Compute_C/D.  The `_b` suffix is the tree's existing spelling",
    "for a byte-identical twin (Clamp_ToRange_Word_b, ScaleClampedDelta_Shr5_b)."]),
"sub_FA738F": ("Pitch_ClampToNoteRange", "PROVEN", [
    "body: negative pitches saturate to 0x7FFF or to 0 (the same 0xC000 split",
    "Sat16_0_to_7FFF uses), then the value is clamped to",
    "[lo*256 + 0x80, hi*256 + 0x80] -- the 1/256-semitone encoding of two note",
    "numbers that Voice_ComputePitch's own header establishes."]),
"sub_FA73EB": ("Pitch_FoldOctavesIntoRange", "PROVEN", [
    "the same two bounds, but instead of clamping it ADDS or SUBTRACTS 0x0C00 --",
    "twelve semitones in the 1/256-semitone unit -- until the pitch lies inside",
    "the range."]),
"sub_FA76D6": ("VoiceParam_AddCurveAndKeyDepth_Clamp", "STRONG", [
    "body: base + (Table_FDEBF4[bank*0x80 + voice[+0x0C] & 0x7F] * depth1) >> 5",
    "+ ((voice[+0x08]>>8 clamped to tone[+0x3A]..tone[+0x3B]) - tone[+0x39])",
    "* depth2 >> 5, then + 0x18 and Clamp_36_to_120.  All seven callers are the",
    "five VoiceParam_Build0100_0140_On36_Arm* routines, and Clamp_36_to_120's own",
    "header records that every one of ITS callers is on the path to registers",
    "0x0100/0x0140."]),
"sub_FA778E": ("VoiceParam_AddCurveDepth_Clamp", "STRONG", [
    "the same shape with the velocity term only (tone[+0x12] as the depth,",
    "tone[+0x11] bits 7..5 as the curve bank), + 0x18, Clamp_36_to_120.  All six",
    "callers are the five VoiceParam_Build0100_0140_On11_Arm* routines."]),
"sub_FA7810": ("VoiceParam_LoadTriple_Set5A51", "PROVEN", [
    "body: reads a 3-byte record at 0xFDF180 + 3*(arg & 0x0F) when arg bit 7 is",
    "set, else at 0xFDF156 + 3*(arg & 0x0F); returns (rec[1] << 8) | rec[0] and",
    "stores rec[2], sign-extended, at RAM 0x005A51.  Every caller ORs the return",
    "into voice_record[+0x41]."]),
"sub_FA78E8": ("EnvRec_ClearSlot", "PROVEN", [
    "body: zeroes bytes +0..+5 and +7 of the 9-byte sub-record at",
    "0x4CCF + 27*chan + 9*slot.  0x4CCF is 0x3BCF + 64*0x44, the byte after the",
    "voice-record array, and 27 = 3 * 9."]),
"sub_FA7927": ("EGEnv_ScaleDepth_Shr12", "PROVEN", [
    "body: returns min(v, (v * ((0x7F - a) * b)) >> 12) using Multiply32 twice.",
    "All five callers are EGEnv_Eval_BaseCurveA/B/FreqWrite and",
    "Voice_StageChanSel_Reg0440_Reg0480, each subtracting the result from the",
    "curve product it has just formed."]),
"sub_FA7CC9": ("VelCurve_Lookup", "STRONG", [
    "body: `Table_FDD6AB[0x100 * ((b & 0xE0) >> 5) + Table_FDDDAB[a]]` -- one of",
    "eight 256-entry curves.  All four callers are Voice_ComputeLevelBase_AB/_CD,",
    "which pass Table_FDD5AB[velocity] as `a` and a tone-record byte as the bank,",
    "then subtract 0xD0 and multiply by the tone's signed sensitivity byte."]),
# ------------------------------------------------------------ voice parameters
"sub_FA7E2C": ("PartRec_UpdateRepeatCounter", "PROVEN", [
    "body: dt = (0x00F2F3) - part[+0x82] (the 32-bit tick and its last value);",
    "dt >= 0x19 resets part[+0x86] and part[+0x87] to 0; otherwise part[+0x86] is",
    "incremented and part[+0x87] set to 0 / 0x10 / 0x20 for the 1st / 2nd / 3rd+",
    "note inside the 25-tick window; part[+0x82] is then restamped with the tick."]),
"sub_FA814C": ("Voice_ComputePitch_FromToneRecord", "PROVEN", [
    "body: writes voice[+0x08] = tone_object[+0x0C] and voice[+0x06] =",
    "Pitch_FoldOctavesIntoRange(that + (elem[+0x04] << 8) + 2*elem[+0x05],",
    "obj[+0x09], obj[+0x0A]) -- the SAME two fields Voice_ComputePitch writes,",
    "and it never reads voice[+0x05], so the result does not depend on the note",
    "played."]),
"sub_FA866B": ("VoiceParam_Build0100_0140_On36_Arm1", "PROVEN", [
    "arm 1 of VoiceParam_DispatchOn_17_36's six-entry table at 0xFA8C05",
    "(`calr 0xfa866b` at 0xFA8C24).  It writes voice_record[+0x3F] and [+0x41],",
    "which Voice_StagePair_Reg0100_0140_* copy into staging words 0x00D766 and",
    "0x00D768 -- struct offsets +0x08 and +0x0A, i.e. registers 0x0100 and 0x0140",
    "(Dev10C_WriteAllChanRegs, 0xFB719B / 0xFB71AE)."]),
"sub_FA8759": ("VoiceParam_Build0100_0140_On36_Arm2", "PROVEN", [
    "arm 2 of the same table (`calr 0xfa8759` at 0xFA8C2A); same two outputs."]),
"sub_FA888C": ("VoiceParam_Build0100_0140_On36_Arm3", "PROVEN", [
    "arm 3 of the same table (`calr 0xfa888c` at 0xFA8C30); same two outputs."]),
"sub_FA8997": ("VoiceParam_Build0100_0140_On36_Arm4", "PROVEN", [
    "arm 4 of the same table (`calr 0xfa8997` at 0xFA8C36); same two outputs."]),
"sub_FA8A79": ("VoiceParam_Build0100_0140_On36_Arm5", "PROVEN", [
    "arm 5 of the same table (`calr 0xfa8a79` at 0xFA8C3C); same two outputs."]),
"sub_FA8C44": ("VoiceParam_Build0100_0140_On11_Arm1", "PROVEN", [
    "arm 1 of VoiceParam_DispatchOn_17_11's six-entry table at 0xFA9032",
    "(`calr 0xfa8c44` at 0xFA9061); writes the same voice[+0x3F] / [+0x41] pair."]),
"sub_FA8CEF": ("VoiceParam_Build0100_0140_On11_Arm2", "PROVEN", [
    "arm 2 of the same table (`calr 0xfa8cef` at 0xFA9067); same two outputs."]),
"sub_FA8D9B": ("VoiceParam_Build0100_0140_On11_Arm3", "PROVEN", [
    "arm 3 of the same table (`calr 0xfa8d9b` at 0xFA906D); same two outputs."]),
"sub_FA8E47": ("VoiceParam_Build0100_0140_On11_Arm4", "PROVEN", [
    "arm 4 of the same table (`calr 0xfa8e47` at 0xFA9073); same two outputs."]),
"sub_FA8EF7": ("VoiceParam_Build0100_0140_On11_Arm5", "PROVEN", [
    "arm 5 of the same table (`calr 0xfa8ef7` at 0xFA9079); same two outputs."]),
"sub_FA981B": ("EnvRec_LoadSlot", "PROVEN", [
    "body: fills bytes +0..+7 of the 9-byte sub-record at 0x4CCF + 27*chan +",
    "9*slot from a part-record field group and a tone-record group -- the same",
    "record EnvRec_ClearSlot zeroes and EGEnv_Eval_* read.  Its twelve callers",
    "are the six Voice_Restage_* and the three Voice_RecomputeEnv_* routines."]),
"sub_FAA2B6": ("Voice_ComputeField0029_AB", "PROVEN", [
    "body: writes voice_record[+0x29] as a packed word -- bits 8..0 the 9-bit",
    "value 0xFF - 4*level, bits 11..9 and 14..12 two 3-bit codes derived from the",
    "part's byte +0x19.  Its two callers are VoiceRegs_Stage_A and _B."]),
"sub_FAA3B5": ("Voice_Field0029_EncodeSelector", "PROVEN", [
    "body: 0 -> 7; 5 -> 6 when either nibble of the companion byte is 5; else",
    "n - 1.  Its two callers are both inside Voice_ComputeField0029_CD, which",
    "shifts the two results left by 9 and by 12 into voice_record[+0x29]."]),
"sub_FAA3EB": ("Voice_ComputeField0029_CD", "PROVEN", [
    "the C/D counterpart of Voice_ComputeField0029_AB -- same output field, same",
    "field layout, via Voice_Field0029_EncodeSelector.  Its two callers are",
    "VoiceRegs_Stage_C and _D."]),
"sub_FAB48A": ("KeyScale_LevelFromPitch", "PROVEN", [
    "body: a four-breakpoint piecewise-linear curve on voice[+0x08] >> 8 (the",
    "note number of the computed pitch) against tone[+0x1E..+0x21}; the slope",
    "constant is -64 (`muls WA,0xffc0`) and the out-of-range value is -512.  Its",
    "one caller adds the result into the level accumulator."]),
"sub_FAB517": ("VelScale_LevelFromVelocity", "PROVEN", [
    "byte-for-byte the same curve one field over: the input is",
    "voice[+0x0C] & 0x7F -- the velocity -- and the breakpoints are",
    "tone[+0x22..+0x25]."]),
"sub_FAB5A5": ("Voice_ComputeLevelBase_AB", "PROVEN", [
    "body: writes voice_record[+0x0D] -- the level accumulator that",
    "Voice_StageLevel_Reg0080_AB/_CD turn into register 0x0080 -- from the",
    "velocity curve (VelCurve_Lookup), the tone's sensitivity byte,",
    "ScaleClampedDelta_Shr5_b, KeyScale_LevelFromPitch, VelScale_LevelFromVelocity",
    "and three global trims, and clears voice[+0x2F].  Callers: VoiceRegs_Stage_A",
    "and _B."]),
"sub_FAB6D5": ("Voice_ComputeLevelBase_CD", "PROVEN", [
    "the C/D counterpart: the same accumulator, the same two output fields",
    "(voice[+0x0D] written, voice[+0x2F] cleared), a shorter term list.",
    "Callers: VoiceRegs_Stage_C and _D."]),
"sub_FAB79D": ("Voice_StageLevel_Reg0080_AB", "PROVEN", [
    "body: forms voice[+0x0D] + tone[+0x17] - 100 (or voice[+0x0D] - 512 when",
    "that byte is zero) + a signed byte, and calls Voice_StageLevel_Reg0080 --",
    "its only call.  Callers: VoiceRegs_Stage_A and _B (plus the controller-driven",
    "Voice_RestageReg0080_ForList)."]),
"sub_FAB7E0": ("Voice_StageLevel_Reg0080_CD", "PROVEN", [
    "the C/D counterpart of Voice_StageLevel_Reg0080_AB, same single call.",
    "Callers: VoiceRegs_Stage_C and _D (plus Voice_RestageReg0080_ForList)."]),
"sub_FABCF9": ("Dev10C_StageSixChanRegs_ForRetire", "PROVEN", [
    "body: writes staging struct offsets +0x2C..+0x36, which",
    "Dev10C_WriteSixChanRegs_FromD78A sends to registers 0x0800, 0x0840, 0x0900,",
    "0x0940, 0x09C0 and 0x0A00 (0xFB7368-0xFB73DE).  +0x2C gets",
    "(voice[+0x43] << 8) | 0x80 and +0x2E gets voice[+0x43] << 8.  Its ONE caller",
    "is Voice_Retire_Mode10."]),
"sub_FABD50": ("Dev10C_StageRegs_0800_0840_FABD50", "PROVEN", [
    "body: writes staging struct +0x2E (register 0x0840) from either",
    "Table_FDEFD9[tone[+0x0E]] << 8 or voice[+0x3B] & 0xFF00, then +0x2C",
    "(register 0x0800) = that value with bit 7 set.  A FOURTH producer of the",
    "same pair, so it keeps the tree's address-suffix spelling alongside",
    "Dev10C_StageRegs_0800_0840_ForNoteOn / _FAB8CC / _FAB9D8."]),
"sub_FABDAC": ("EnvRec_AdvanceSegment", "PROVEN", [
    "body: on a 9-byte envelope sub-record, selects on rec[0] & 0x1C; both arms",
    "increment the step counter rec[+0x08] and compare it with the segment length",
    "rec[+0x07]; the 0x08 arm returns (rec[+0x08] << 8) / rec[+0x07] -- a 0..0x100",
    "interpolation fraction -- and on overrun resets the counter and moves the",
    "state bit.  All three callers are inside Voice_RecomputeAllThreeBaseCurves."]),
# --------------------------------------------------------------- note engine
"sub_FB6BA8": ("MidiProgram_SelectToneForPart", "STRONG", [
    "it is the handler the parser's 0xC0 arm calls, and MidiMsg_SendBootSequence",
    "hands it the literal packet `C0 00 00 00 00` -- 0xC0 is the MIDI status for",
    "PROGRAM CHANGE.  Body: bounds the part index with `cp H,0x21`, stores msg[2]",
    "in part[+0x1B] and a derived byte in part[+0x1C], and then reloads that",
    "part's tone object through sub_FB47C4(part, msg[2], msg[3]).",
    "⚠ GRADE STRONG, not PROVEN: `0xC0 = program change` is the MIDI standard's",
    "meaning, and this message format is MIDI-DERIVED rather than MIDI (the 0x80",
    "arm consumes six bytes and is not note-off).  What the ROM settles on its own",
    "is that the routine selects a part's tone from a two-byte number."]),
}

STAR = "★"

HEADER_RE = re.compile(r"^; (sub_[0-9A-F]{6}) -- 0x[0-9A-F]{6}\.\.")


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
    out, renamed, annotated = [], 0, 0
    for line in lines:
        m = HEADER_RE.match(line)
        if m and m.group(1) in RENAMES:
            new, grade, why = RENAMES[m.group(1)]
            out.append(f"; {STAR} NAMED (wave 17): `{m.group(1)}` is now `{new}`.")
            out.append(f";   GRADE {grade}.  WHY `{new}`:")
            for w in why:
                out.append(f";   {w}")
            annotated += 1
        new_line = rename_code(line, table)
        if new_line != line:
            renamed += 1
        out.append(new_line)
    path.write_text("\n".join(out), encoding="utf-8")
    return renamed, annotated


def report():
    by_file = {}
    for f in FILES:
        txt = f.read_text(encoding="utf-8")
        for old, (new, grade, _why) in sorted(RENAMES.items()):
            if re.search(r"^(?:" + old + "|" + new + r"):", txt, re.M):
                by_file.setdefault(f.name, []).append((old, new, grade))
    for name, rows in by_file.items():
        print(f"\n{name}  ({len(rows)} renamed)")
        for old, new, grade in rows:
            print(f"    {old} -> {new:<44} {grade}")
    print(f"\n  {len(RENAMES)} renames in the table.")


def check():
    bad = []
    for f in FILES:
        txt = f.read_text(encoding="utf-8")
        for old, (new, _g, _w) in RENAMES.items():
            if re.search(r"^" + old + ":", txt, re.M):
                bad.append(f"{f.name}: {old} still defined")
    left = set()
    for f in FILES:
        for line in f.read_text(encoding="utf-8").split("\n"):
            m = re.match(r"^(sub_[0-9A-F]{6}):", line)
            if m:
                left.add(m.group(1))
    print(f"  {len(RENAMES)} renamed, {len(left)} labels still address-form")
    for b in bad:
        print("  FAIL", b)
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    if a.apply:
        for f in FILES:
            r, n = apply_to(f)
            print(f"  {f.name:<26} {r:>3} code line(s) renamed, {n:>3} header(s) annotated")
        return 0
    if a.check:
        return check()
    report()
    return 0


if __name__ == "__main__":
    sys.exit(main())
