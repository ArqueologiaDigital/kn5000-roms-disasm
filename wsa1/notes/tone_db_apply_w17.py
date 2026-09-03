#!/usr/bin/env python3
"""WAVE 17, lane w17/tone-db -- apply this lane's names to
   prom_c/tone_db/tone_db_module.s, and record every refusal beside the routine
   it is about.

WHAT QUESTION THIS ANSWERS
    "Did the rename touch a comment?"  It must not.  This tree's comment gate
    (scripts/analysis/assert_comments_preserved.py) requires the base commit's
    comments to be a SUBSEQUENCE of the new file's, so a pass that rewrote
    `Calls: 0xFB828E = sub_FB828E` to spell the new name would go red -- and
    correctly, because that is an edit to somebody else's sentence.

    So this applier is deliberately narrower than round 12's:
      * it renames ONLY in the code half of a line (everything before the first
        `;`), never inside a comment;
      * it INSERTS its documentation block above the separator line that
        precedes the label, and REMOVES NOTHING.  The generator's
        "Unknown: what the routine is FOR" paragraph therefore survives above
        every W17 `Name:` line, and each block says so in as many words.
      * ⚠ the CONSEQUENCE, stated rather than hidden: the generated
        `Called from:` / `Calls:` lines in this file go on spelling the old
        `sub_XXXXXX`.  Their ADDRESSES are authoritative and the file header
        carries the full old -> new table.

RUN
    python3 notes/tone_db_apply_w17.py --apply    # idempotent
    python3 notes/tone_db_apply_w17.py --verify
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "tone_db", "tone_db_module.s")

TAG = "W17 -- "

# (old, new, what it does, the evidence, what is still unknown)
NAMES = [

("sub_FB828E", "MemCopyBytes",
 "copies n bytes from src to dst, one byte at a time.  Same argument "
 "convention as MemCopyWords (0xF9A038): (XIZ+0x08) source, (XIZ+0x0C) "
 "destination, (XIZ+0x10) byte count -- source first, which is NOT C's order.",
 "the whole body is the loop: 0xFB8298 compares the counter against "
 "(XIZ+0x10), 0xFB82A7/0xFB82AA load a byte through (XIZ+0x08), 0xFB82AE/"
 "0xFB82B1 store it through (XIZ+0x0C), and 0xFB82B3-0xFB82BA add ONE to both "
 "pointers.  Nothing else is in the routine.  Its 8 call sites all push "
 "(count, dst, src) in that order and the counts they push are prom_d record "
 "sizes: 217, 81, 408, 64, and the directory's own stride words +0xEA / +0xF0.",
 "nothing about this routine; it is a memcpy."),

("sub_FB82C3", "ToneDB_ResolveWaveSelectRecord",
 "turns the last two bytes of a 16-byte wave-catalogue row into the address "
 "of a 43-byte WAVE-SELECT RECORD, through one of three (index map, record "
 "array, stride word) triples in prom_d's directory, in the internal image or "
 "in the expansion board's.",
 "★ THIS IS A READER OF SLOTS prom_d's HEADER LISTS AS HAVING NONE.  Round "
 "3's census matched `base load; load (base+slot)` and this routine SPILLS "
 "the base to its frame first (0xFB82ED/0xFB82F2 and 0xFB82F5/0xFB82FA), so "
 "the pair never occurs and the site was invisible.  Decoded: arg0 has bit 7 "
 "cleared (0xFB82CA) giving 0..127; arg1 is split three ways -- bits 0:3 "
 "(0xFB82D5), bits 4:5 (0xFB82E0) and bits 6:7 (0xFB8358).  Bits 6:7 pick the "
 "triple: 0x00 and 0xC0 take slot +0x0C / +0x18 / +0xEA (0xFB8369, 0xFB836F, "
 "0xFB837A), 0x40 takes +0x14 / +0x20 / +0xF0 (0xFB8398, 0xFB839E, 0xFB83A9) "
 "and 0x80 takes +0x10 / +0x1C / +0xEA (0xFB83C6, 0xFB83CC, 0xFB83D7).  Bit 5 "
 "switches the whole walk to 0x00D80D / 0x00D811, the expansion board's copy "
 "(0xFB8303, 0xFB8310, 0xFB8318), and when no board is present the fallback "
 "arm at 0xFB8326 sets a flag that forces the index to 127 or 0.  The "
 "arithmetic is then 0xFB840F `sll 0x07,BC` (bits 0:3 are a BANK of 128), "
 "0xFB8412 + the 7-bit field, 0xFB8415 `mul BC,0x0002` (the map entry is an "
 "LE16), 0xFB841F the entry, 0xFB8424 `mul XWA,(XIZ+0xee)` by the stride word "
 "and 0xFB8427/0xFB842A the array offset and the base.  8 banks x 128 = 1024, "
 "which is exactly the entry count prom_d gives each of those index maps.",
 "the MEANING of any byte inside the record it returns, except +0x0B "
 "(see ToneStage_ApplyWaveSelTailPreset).  And what bit 4 of arg1 is for: the "
 "code masks bits 4:5 together and treats 0x00 and 0x10 identically, and 0x20 "
 "and 0x30 identically, so bit 4 is READ and never acted on."),

("sub_FB8432", "ToneStage_LoadElementWaveSelect_FromCatalogueRow",
 "copies the 43-byte wave-select record a catalogue row names into element "
 "slot e of the RAM tone-record staging image.",
 "0xFB8440 calls ToneDB_ResolveWaveSelectRecord with the caller's two "
 "catalogue-row bytes; 0xFB8446-0xFB8459 form 0x0087D2 + 0x21D + 43*e; "
 "0xFB845C-0xFB8461 read the directory's stride word +0xEA as the length; "
 "0xFB846E copies.  541 = 217 + 4*81, so the destination is the element's "
 "slot in the wave-select array that follows the four element blocks.",
 "which of the 43 bytes the catalogue row's choice actually changes."),

("sub_FB8478", "ToneStage_LoadPercWaveSelect_FromCatalogueRow",
 "the percussion twin: copies the catalogue row's 43-byte wave-select record "
 "into sub-slot j of drum-instrument slot n of the staging image.",
 "same call to ToneDB_ResolveWaveSelectRecord at 0xFB8487, then "
 "0xFB848D-0xFB84A5 form 0x0087D2 + 0x4A1 + 150*n + 43*j, and 0xFB84AE-"
 "0xFB84B3 take the length from stride word +0xF0.  0x4A1 - 0x461 = 0x40, so "
 "the sub-array starts 64 bytes into a 150-byte drum-instrument record and "
 "64 + 2*43 = 150 exactly.",
 "as above."),

("sub_FB84CB", "ToneStage_LoadToneRecord_FromPart",
 "assembles a part's tone into the RAM staging image at 0x0087D2: the "
 "217-byte head from the part record's own pointer, then the four 81-byte "
 "element blocks from the four per-element pointers.",
 "0xFB84D5/0xFB84DB read the 32-bit pointer at part record +0x00 (the record "
 "array is 0x1523, stride 0x012C); 0xFB84E3 `lda XBC,0x0087d2` and 0xFB84EB "
 "`push 0x00d9` copy 217 bytes there.  The loop 0xFB84FB..0xFB854A runs e = "
 "0..3 and reads the pointer at 0x1523 + 0x012C*part + 0x88 + 0x29*e "
 "(0xFB8508 `ld C,0x29`, 0xFB851A `add WA,0x0088`, 0xFB8520), copying 81 "
 "bytes (0xFB853E `push 0x0051`) to 0x0087D2 + 0xD9 + 81*e.  0x88 + 4*41 = "
 "300 exactly, so the four 41-byte sub-records tile the part record.",
 "every field inside the 217-byte head except +0xD0 and +0x23/+0x24."),

("sub_FB8550", "ToneStage_LoadKitRecord_FromPart",
 "copies a drum part's whole 408-byte DRUM-KIT RECORD into the kit staging "
 "image at 0x008A9B.",
 "0xFB8559/0xFB855F read the pointer at part record +0x00; 0xFB8567 `lda "
 "XBC,0x008a9b`; 0xFB856F `push 0x0198` -- 408, which is prom_d's own "
 "drum-kit record size (16 name + 136 common + 128 x 2).  And 0x0087D2 + 713 "
 "= 0x008A9B, so this image sits immediately after the tone-record image with "
 "no slack.",
 "the 136-byte common part of a kit record."),

("sub_FB857E", "ToneStage_LoadPercInstHead",
 "resolves the drum-instrument record for one kit-map entry and copies its "
 "64-byte HEAD into drum-instrument slot n of the staging image.",
 "0xFB8582-0xFB85C0 build a 2-bit selector from part record +0x1C (compared "
 "against 0x28) and +0x1B bit 0; 0xFB85D5 calls "
 "DrumKit_ResolveInstrumentRecord; 0xFB85DC-0xFB85E9 form 0x0087D2 + 0x461 + "
 "150*n and 0xFB85F4 `push 0x0040` copies 64 bytes.  0x0087D2 + 0x461 = "
 "0x008C33, which is the array base ToneRec_GetElementBlock loads at "
 "0xFB4331, and 64 + 2*43 = 150 = prom_d's stride word +0xEE.",
 "the 64 bytes' fields, and what the 2-bit selector selects between."),

("sub_FB8603", "ToneStage_LoadElementWaveSelect_FromToneRecord",
 "the same destination as "
 "ToneStage_LoadElementWaveSelect_FromCatalogueRow, but the source is the "
 "tone's OWN wave-select record rather than a catalogue row's.",
 "0xFB8615 reads the pointer at part record +0x00, 0xFB8626 reads part record "
 "+0x1C, 0xFB862E calls 0xFB44A5 with (that byte, e, the record), and "
 "0xFB8635-0xFB8642 form 0x0087D2 + 0x21D + 43*e with the length again taken "
 "from stride word +0xEA (0xFB864B).  ToneStage_LoadPart calls it in a e = "
 "0..3 loop (0xFB879D) immediately after ToneStage_LoadToneRecord_FromPart.",
 "what 0xFB44A5 does with part record +0x1C; that routine is unnamed and is "
 "not this lane's file."),

("sub_FB8668", "ToneStage_LoadPercWaveSelect_FromInstRecord",
 "the percussion twin of the above: sub-slot j of drum-instrument slot n, "
 "from the resolved instrument record rather than from a catalogue row.",
 "0xFB8676 calls 0xFB454C with (j, the record pointer the caller passed); "
 "0xFB867D-0xFB8695 form 0x0087D2 + 0x4A1 + 150*n + 43*j and 0xFB869E-"
 "0xFB86A3 take the length from stride word +0xF0.  ToneStage_LoadPart calls "
 "it with j = 0..1 (`cp (XIZ+0xf3),0x02` at 0xFB897D), which is the second "
 "witness for two wave-select records per drum-instrument record.",
 "as above."),

("sub_FB86BB", "ToneStage_SwitchToPart",
 "tears down the part whose tone is currently in the RAM staging image "
 "(0x00D734) and builds the argument part's tone there instead -- melodic "
 "parts through the tone-record path, drum parts through the kit path.",
 "0xFB86C1 reads 0x00D734 and 0xFB86C9/0xFB86CF skip the teardown when it "
 "equals the argument or is >= 0x21 (33 parts).  Both halves branch on "
 "tone_record[+0x10] & 0xC0 (0xFB8719 and 0xFB876B).  The MELODIC arm "
 "(0xFB8779) calls ToneStage_LoadToneRecord_FromPart then "
 "ToneStage_LoadElementWaveSelect_FromToneRecord for e = 0..3, mirrors part "
 "record +0x09 bit 15 into 0x0088A2 = 0x0087D2 + 0xD0 bit 7 (0xFB87B7-"
 "0xFB87C5), builds a 4 x 5 table at 0x0087D2 + 0x4F6C out of per-element "
 "sub-record +0x36 & 7 and element block +0x4D..+0x50 (0xFB87FA-0xFB8870), "
 "and copies part record +0x17/+0x18 to 0x0087F5/0x0087F6 -- which are "
 "0x0087D2 + 0x23 and + 0x24.  The DRUM arm (0xFB88AC) calls "
 "ToneStage_LoadKitRecord_FromPart and then, for note = 0..127 (`cp "
 "(XIZ+0xf4),0x80` at 0xFB8900), reads the kit record's TWO bytes at +0x98 + "
 "2*note and +0x99 + 2*note (0xFB891C, 0xFB892A) and passes them separately "
 "to ToneStage_LoadPercInstHead and DrumKit_ResolveInstrumentRecord, then "
 "ToneStage_LoadPercWaveSelect_FromInstRecord for j = 0..1; it ends by "
 "copying part record +0x17/+0x18 to 0x008ABB/0x008ABC, which are 0x008A9B + "
 "0x20 and + 0x21.  16 + 136 = 0x98 and 0x98 + 2*128 = 408, so the note map "
 "is the whole tail of prom_d's drum-kit record.",
 "what bits 7:6 of tone_record[+0x10] mean beyond selecting these arms -- "
 "prom_d's own note says the byte is 0x80 in all 18 drum kits and 0x10 in 248 "
 "of 254 melodic records, and this routine's 0x80 arm IS the drum one, which "
 "agrees but does not name the other three values.  And what the 4 x 5 table "
 "at 0x0087D2 + 0x4F6C is for."),

("sub_FBAAA2", "ToneStage_EnsurePartLoaded",
 "the gate in front of ToneStage_SwitchToPart: if bit 0 of the part record's "
 "16-bit field +0x04 is already set the staging image is up to date and "
 "nothing happens; otherwise it sets the bit, rebuilds the image and "
 "re-copies part record +0x17/+0x18 into the tone or kit record.",
 "0xFBAAB2/0xFBAABA read the LE16 at 0x1523 + 0x012C*part + 4 and test bit 0 "
 "(0xFBAABF) and, for part >= 0x21, bit 1 as well (0xFBAAD8); 0xFBAB1B sets "
 "bit 0; 0xFBAB27 calls ToneStage_SwitchToPart.  The tail branches on "
 "tone_record[+0x10] & 0xC0 exactly as ToneStage_SwitchToPart does and writes "
 "the same two bytes at record +0x23/+0x24 (melodic, 0xFBABA9/0xFBABB9) or "
 "+0x20/+0x21 (drum, 0xFBABEF/0xFBABFF) -- through the part's own pointer "
 "this time, which is the second, independent witness that the pointer at "
 "part record +0x00 IS the staging image while the part is loaded.  Eight of "
 "ToneMsg_Dispatch's arms and eight of ToneEdit_Dispatch's call it first.",
 "what part record +0x04's other bits are, and what +0x17/+0x18 hold."),

("sub_FBAF38", "ToneRec_LoadDspParams_AlgoTypes0to3",
 "scatters seven bytes of one DSP_AlgoDescriptor_Records row into the part's "
 "tone record at +0xD1..+0xD5, +0xD7 and +0xD8.",
 "0xFBAF48 takes the tone record through part record +0x00; 0xFBAF50 `ld "
 "C,0x27` and 0xFBAF57 `add XBC,0x00fdf4f1` index prom_c's own "
 "DSP_AlgoDescriptor_Records (0xFDF4F1, 12 records x 39 bytes) by the "
 "caller's type; the seven stores are +0x00->+0xD1, +0x01->+0xD2, "
 "+0x1A->+0xD3, +0x1C->+0xD4, +0x1B->+0xD5, +0x0E->+0xD7, +0x12->+0xD8.  "
 "★ THE NAME IS THE CALL GRAPH, not the routine's own text: the type is an "
 "ARGUMENT, and all four of this routine's call sites are arms 0, 1, 2 and 3 "
 "of ToneRec_LoadDspParams_ByAlgoType (0xFBB3CB, 0xFBB3DA, 0xFBB3E9, "
 "0xFBB3F8), each passing its own arm number.  No other site in the image "
 "reaches it.",
 "what any of the eight tone-record bytes IS.  The map is decoded; the "
 "meaning is not."),

("sub_FBAFD0", "ToneRec_LoadDspParams_AlgoTypes4and5",
 "the same, with a different map: +0x00->+0xD1, +0x01->+0xD2, +0x03->+0xD3, "
 "+0x04->+0xD4, +0x1A->+0xD5, +0x1C->+0xD6, +0x0E->+0xD7, +0x12->+0xD8 -- "
 "eight bytes, and the only one of the eight maps that writes +0xD6.",
 "0xFBAFE8 `ld C,0x27` and 0xFBAFEF `add XBC,0x00fdf4f1`; both call sites are "
 "arms 4 and 5 of ToneRec_LoadDspParams_ByAlgoType (0xFBB407, 0xFBB416).",
 "as above."),

("sub_FBB078", "ToneRec_LoadDspParams_AlgoType6",
 "the same, map +0x06->+0xD1, +0x07->+0xD2, +0x08->+0xD3, +0x1B->+0xD4, "
 "+0x0E->+0xD7, +0x12->+0xD8.",
 "0xFBB090 `ld C,0x27`, 0xFBB097 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 6 (0xFBB425).",
 "as above."),

("sub_FBB101", "ToneRec_LoadDspParams_AlgoType7",
 "the same, for algorithm type 7.",
 "0xFBB119 `ld C,0x27`, 0xFBB120 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 7 (0xFBB434).",
 "as above."),

("sub_FBB189", "ToneRec_LoadDspParams_AlgoType8",
 "the same, for algorithm type 8.",
 "0xFBB1A1 `ld C,0x27`, 0xFBB1A8 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 8 (0xFBB443).",
 "as above."),

("sub_FBB212", "ToneRec_LoadDspParams_AlgoType9",
 "the same, for algorithm type 9.",
 "0xFBB22A `ld C,0x27`, 0xFBB231 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 9 (0xFBB452).",
 "as above."),

("sub_FBB29B", "ToneRec_LoadDspParams_AlgoType10",
 "the same, for algorithm type 10.",
 "0xFBB2B2 `ld C,0x27`, 0xFBB2B9 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 10 (0xFBB460).",
 "as above."),

("sub_FBB315", "ToneRec_LoadDspParams_AlgoType11",
 "the same, for algorithm type 11.",
 "0xFBB32C `ld C,0x27`, 0xFBB333 `add XBC,0x00fdf4f1`; its one call site is "
 "arm 11 (0xFBB46E).",
 "as above."),

("sub_FBB39F", "ToneRec_LoadDspParams_ByAlgoType",
 "★ reads the DSP ALGORITHM TYPE out of tone record +0xD0 and applies that "
 "type's row of DSP_AlgoDescriptor_Records to tone record +0xD1..+0xD8.",
 "0xFBB3AE takes the tone record through part record +0x00; 0xFBB3B3 `ld "
 "C,(XWA+0x00d0)`; 0xFBB3B8 `and C,0x0f`; 0xFBB47D `cp BC,0x000b` bounds it "
 "at 11 and the table at 0xFBB48C has TWELVE entries.  prom_c's own "
 "DSP_AlgoDescriptor_Records is 12 records of 39 bytes "
 "(0xFDF4F1..0xFDF6C4), and arm k passes the literal k to a helper that "
 "indexes that table at stride 0x27.  Three more routines in this module read "
 "the same byte with the same mask and switch on it (0xFBB4D3/0xFBB4D8, "
 "0xFBB590/0xFBB595, 0xFBB659/0xFBB65E, 0xFBB70C/0xFBB711).  "
 "⚠ NULL, printed rather than left implicit: this module has 18 computed-goto "
 "tables and TWO of them have 12 arms, so `12 arms` alone is weak.  What "
 "carries the reading is that the arms pass their own index into a table "
 "whose base and stride are separate literals in the helper.",
 "what bits 4:6 of +0xD0 are.  Bit 7 is set and cleared by "
 "ToneStage_SwitchToPart from part record +0x09 bit 15, and the low nibble is "
 "this; bits 4:6 are read by nothing found here."),

("sub_FBC725", "ToneStage_ApplyWaveSelTailPreset",
 "★ overwrites bytes 13..42 of element e's staged wave-select record from a "
 "row of prom_d's ToneDB_WaveSelTailPresets -- unless the record's own +0x0B "
 "low six bits are 0, in which case the tone's own record supplies them.",
 "0xFBC72B-0xFBC738 form 0x0087D2 + 0x21D + 43*e; 0xFBC741 `ld A,(XBC+0x0b)`; "
 "0xFBC744 `and A,0x3f`; 0xFBC74E `jr NZ` sends a NON-zero preset to "
 "0xFBC7A9, which loads directory slot +0x3C (0xFBC7B6) and scales the preset "
 "by the stride word +0xEA (0xFBC7BE) -- 43.  Preset 0 instead resolves the "
 "part's own tone record (0xFBC779 ToneDB_ResolveToneRecord) and its own "
 "wave-select record (0xFBC79E).  Either way 0xFBC7CE/0xFBC7D6 copy source "
 "+0x0B over the destination's, and the loop at 0xFBC7DE runs i = 13 "
 "(0xFBC7D9 `ld (XIZ+0xf0),0x000d`) up to the stride word +0xEA (0xFBC7E3), "
 "so 30 of the 43 bytes are replaced.",
 "⚠ WHAT THIS DOES NOT SETTLE.  prom_d round 12's Q31 asked whether the panel "
 "variable at 0x2808..0x280B IS this field, and refused to say so because no "
 "instruction chain carries one into the other.  Nothing here supplies that "
 "chain: this says what prom_c DOES with the field, not where its value comes "
 "from.  And no byte of the 30-byte tail is named."),

("sub_FBC80E", "ToneStage_ApplyPercWaveSelTailPreset",
 "the percussion twin: the same +0x0B & 0x3F preset, applied to sub-slot j of "
 "drum-instrument slot n of the staging image.",
 "0xFBC814-0xFBC82C form 0x0087D2 + 0x4A1 + 150*n + 43*j; 0xFBC835 `ld "
 "C,(XWA+0x0b)`; 0xFBC838 `and C,0x3f`.  Preset 0 resolves the part's tone "
 "record (0xFBC87B), rebuilds the same 2-bit selector "
 "ToneStage_LoadPercInstHead builds, reads the kit record's byte pair at "
 "+0x98 + 2*n / +0x99 + 2*n (0xFBC8AE, 0xFBC8BD) and resolves the instrument "
 "record; non-zero takes directory slot +0x40, prom_d's alias of +0x3C, with "
 "stride word +0xF0.",
 "as for the melodic twin."),

("sub_FBD858", "ToneQuery_ReplyPartStagingFlags",
 "replies ONE byte: the low two bits of part record +0x04 when the requested "
 "part is the current one (0x00D733), and 0 otherwise.",
 "0xFBD85C `ld C,(0x00d733)`, 0xFBD861 compares it with the request's part; "
 "0xFBD86F/0xFBD873 read the LE16 at 0x1523 + 0x012C*part + 4 and 0xFBD878 "
 "masks it with 0x03; 0xFBD87B (or 0xFBD882 on the other arm) stores it at "
 "0x00D94B, which round 12 established as the first PAYLOAD byte of the reply "
 "buffer at 0x00D945; 0xFBD888 returns length 1.  Bit 0 of that field is the "
 "one ToneStage_EnsurePartLoaded sets when it stages a part.",
 "what bit 1 is.  ToneStage_EnsurePartLoaded tests it, for parts >= 0x21 "
 "only, and nothing found here sets it."),

("sub_FBAC24", "ToneEdit_Dispatch",
 "the tone-EDIT command dispatcher: 27 arms on request byte +0x02, with the "
 "part index in +0x01 and up to three operand bytes in +0x03..+0x05.",
 "0xFBAC2C reads request +0x02; 0xFBAEB5 `cp BC,0x001a` bounds it at 26 and "
 "the table at 0xFBAEC8 has 27 entries, eight of which are the "
 "no-operation arm 0xFBAEAD.  Arm 13 (0xFBAD77) is the one that MOVES the "
 "selection: `ld C,(0x00d733)` / `ld (0x00d734),C` / `ld (0x00d733),A` from "
 "request +0x01, then ToneStage_EnsurePartLoaded -- which is what makes "
 "0x00D733 the current part and 0x00D734 the previously current one, the "
 "value ToneStage_SwitchToPart tears down.  Arms 9, 10, 20, 21 and 22 build a "
 "16-bit index as (request[+3] << 8) | request[+4] and hand it to the five "
 "catalogue selectors ToneDB_SourceNameList1_SelectEntry, "
 "ToneDB_SourceNameList2_SelectEntry, "
 "ToneDB_DrumSourceNameList_SelectEntry, "
 "ToneDB_PercSourceNameList1_SelectEntry and "
 "ToneDB_PercSourceNameList2_SelectEntry, which is why the catalogues' "
 "bounds are 16-bit.",
 "what each arm's operands mean.  The dispatch shape is decoded; 19 of the "
 "27 arms lead to routines this lane has not named."),

("sub_FC2600", "ToneMsg_Dispatch",
 "the whole module's entry point from the MIDI/link message path: bit 3 of "
 "request[0] chooses the WRITE table or the QUERY table and bits 0:2 choose "
 "one of eight arms in it.",
 "0xFC2607/0xFC260C read request[0] and mask 0x07; 0xFC2614 tests bit 3 "
 "(`and W,0x08`) and 0xFC2617 branches to the query half.  Two 8-entry tables, "
 "at 0xFC2754 (write) and 0xFC27EA (query), each guarded by `cp BC,7`.  The "
 "WRITE arms are ToneEdit_Dispatch, sub_FBB793, sub_FBC39D (twice, with a "
 "literal 0/1 and 2/3 chosen by request[2] bit 7), sub_FBC958, sub_FBCD17, "
 "sub_FBD46B and sub_FBD6FC; all but the first call "
 "ToneStage_EnsurePartLoaded on request[+0x01] first, which is what makes "
 "request[+0x01] the part index for the whole protocol.  The QUERY arms are "
 "ToneQuery_Dispatch, LinkQuery_ReplyPartRecordBytes and the six "
 "LinkQuery_Reply*Bytes routines.  Its single caller is "
 "MidiIn_ParseRingAndDispatch (0xFB079B).",
 "what request bytes beyond +0x05 carry, and the panel-side names of the "
 "sixteen arms -- those live in prom_a, which this lane does not own."),

("sub_FC2388", "LinkQuery_ReplyToneRecordBytes",
 "replies request[+0x03] raw bytes of the part's TONE RECORD, starting at "
 "offset request[+0x02].",
 "0xFC2393-0xFC23B6 copy the request's first six bytes back into the reply "
 "buffer at 0x00D945, which is round 12's echo; 0xFC23C0/0xFC23C6 take the "
 "pointer at part record +0x00 and 0xFC23D5 adds request[+0x02]; the loop at "
 "0xFC23DF copies request[+0x03] bytes to 0x00D945 + 6 + i; 0xFC241E `inc "
 "6,BC` makes the length payload + 6 and 0xFC2425 sends it on the channel in "
 "request[+0x04].",
 "nothing about the routine; what the bytes MEAN is the tone record's "
 "question, not this one's."),

("sub_FC206F", "LinkQuery_ReplyElementBlockBytes_Elements01",
 "the same, over an 81-byte ELEMENT PARAMETER BLOCK: bit 7 of request[+0x02] "
 "picks element 0 or element 1 and the low seven bits are the offset.",
 "0xFC20BD/0xFC20C1 read the pointer at part record +0x88 (element 0's "
 "sub-record +0x00) and 0xFC20CA/0xFC20DD read the one at +0xB1 = 0x88 + 41 "
 "(element 1's); the selector is `and A,0x80` at 0xFC20A8 and the offset is "
 "`res 0x07,A` at 0xFC2100.  Same echo, same length arithmetic and same "
 "sender as LinkQuery_ReplyToneRecordBytes.",
 "as above."),

("sub_FC2160", "LinkQuery_ReplyElementBlockBytes_Elements23",
 "elements 2 and 3 of the same object: part record +0xDA = 0x88 + 2*41 and "
 "+0x103 = 0x88 + 3*41.",
 "0xFC21B2 `add WA,0x00da` and 0xFC21CE `add WA,0x0103`, selected by `and "
 "A,0x80` at 0xFC2199.  Every other instruction is "
 "LinkQuery_ReplyElementBlockBytes_Elements01's.",
 "as above."),

("sub_FC2251", "LinkQuery_ReplyElementWaveSelectBytes",
 "the same again, over the 43-byte WAVE-SELECT record each per-element "
 "sub-record points at from its +0x04, with bits 6:7 of request[+0x02] "
 "choosing among all four elements.",
 "0xFC228A `and A,0xc0`; the four arms read the pointers at part record "
 "+0x8C, +0xB5, +0xDE and +0x107 (0xFC22A4, 0xFC22C1, 0xFC22DD, 0xFC22F9), "
 "which are 0x8C + 41*e for e = 0..3, i.e. offset +0x04 of each 41-byte "
 "sub-record.  That the target is 43 bytes long is "
 "PartElement_SetWaveSelectPointer_ToRomDefault's doing: it fills the same "
 "field with Table_FE14A0, and Table_FE14A0 is 43 bytes.",
 "as above."),

("sub_FC10BE", "ToneQuery_ReplyToneDspAlgoByte",
 "★ LIFTS HALF OF ROUND 12's REFUSAL.  It resolves the tone record for "
 "(program, bank) and replies with ONE byte, the record's +0xD0 -- and +0xD0 "
 "is no longer an offset `no reader in either image interprets`: its LOW "
 "NIBBLE is the DSP ALGORITHM TYPE and its bit 7 is a flag "
 "ToneStage_SwitchToPart mirrors from part record +0x09.",
 "the reply itself is round 12's decode, unchanged: 0xFC10C8 "
 "ToneDB_ResolveToneRecord, 0xFC10CF `ld C,(XIY+0x00d0)`, 0xFC10D4 the store "
 "at 0x00D94B, length 1.  What is new is the READER of that byte: "
 "ToneRec_LoadDspParams_ByAlgoType loads it at 0xFBB3B3, masks 0x0F at "
 "0xFBB3B8, bounds it at 11 (0xFBB47D `cp BC,0x000b`) and uses it as a "
 "12-arm computed goto whose arms index prom_c's own 12-record, 39-byte "
 "DSP_AlgoDescriptor_Records at 0xFDF4F1; three more routines in this module "
 "read the same byte with the same mask.",
 "bits 4:6 of +0xD0, which nothing found here reads.  ⚠ AND ROUND 12's "
 "REFUSAL WAS RIGHT ON ITS OWN FACTS -- `prom_d names bytes +0x00..+0x0F of a "
 "tone record and nothing else` was true when it was written.  What changed "
 "is the reader, not the argument."),

("sub_FC2930", "PartElement_SetWaveSelectPointer_ToRomDefault",
 "points one part element's wave-select pointer (sub-record +0x04) at "
 "prom_c's own 43-byte Table_FE14A0.",
 "0xFC2935-0xFC2947 form 0x1523 + 0x012C*part + 0x8C + 0x29*e -- 0x8C is 0x88 "
 "+ 4, so this is the SECOND pointer of the per-element sub-record -- and "
 "0xFC294D/0xFC2952 store `lda XBC,0xfe14a0` into it.  prom_c's own "
 "data_tables/tail_data_zone.s gives Table_FE14A0 as 43 bytes "
 "(0xFE14A0..0xFE14CA), which is the wave-select record size, and there is a "
 "byte-identical second copy at 0xFE20A5.  Its one caller is inside "
 "sub_FB47C4 (0xFB48CF).",
 "what makes 0xFE14A0 the right default -- its bytes are `7f 7f 7f 00 ...`, "
 "and no field of a wave-select record is named."),
]

# (old, why it was NOT named -- a derived reason, not a shrug)
REFUSALS = [

("sub_FB84CB_PLACEHOLDER", ""),   # replaced below; see REFUSALS_REAL
]

REFUSALS_REAL = [

("sub_FB8CEC",
 "967 bytes, one caller (ToneEdit_Dispatch arm 0), and it reaches "
 "Voice_ApplyParamChange_Dispatch.  What it IS turns on what its second "
 "argument -- request[+0x04] -- selects, and that is a value the panel "
 "supplies; nothing in this module constrains it.  A name from `arm 0 of the "
 "edit dispatcher` would be a name from POSITION."),

("sub_FB9414",
 "the only writer of 0x00D735 in this module.  0x00D735 is already documented "
 "in this file as `the current index` a drum-instrument lookup uses, but the "
 "routine sets it from request[+0x04] without interpreting it, so naming it "
 "would restate its one store."),

("sub_FB9AC2",
 "sets bit 2 of part record +0x04 when part record +0x1C is below 0x20, then "
 "calls 0xFB47C4 and 0xFB6681.  Bit 0 of that field is named "
 "(ToneStage_EnsurePartLoaded sets it); bit 2 has no reader anywhere this "
 "lane searched, so the routine would be named for a flag whose meaning is "
 "the open question."),

("sub_FB9B69",
 "3,897 bytes, the largest routine in the module, and the one that reads "
 "directory slots +0xAC, +0xB0 and +0xB4 -- the three TEMPLATE slots.  It is "
 "reachable only from ToneEdit_Dispatch arm 26.  A single name for a routine "
 "that long is a summary, and this lane did not decode enough of it to write "
 "an honest one."),

("sub_FBB4BF", "sub_FBB57C", "sub_FBB645", "sub_FBB6F8"),

("sub_FBB765",
 "46 bytes, the module's only routine called from outside it other than "
 "ToneMsg_Dispatch, sub_FC28B5 and sub_FC2930.  It reads 0x0088A2 -- which "
 "IS tone record +0xD0 in the staging image -- and 0x00D733, and calls "
 "ToneStage_EnsurePartLoaded.  Not named because what it RETURNS is not "
 "traced past its one caller, sub_FAFBEC, which is unnamed too."),

("sub_FBB793",
 "2,152 bytes, ToneMsg_Dispatch write arm 1, and the caller of "
 "ToneRec_LoadDspParams_ByAlgoType and of the three "
 "Voice_RecomputeEnv_AndWriteSlot* routines.  Same reason as sub_FB9B69: too "
 "large to name from what this lane decoded."),

("sub_FBBFFB",
 "calls ToneStage_LoadElementWaveSelect_FromCatalogueRow, so it is on the "
 "wave-select path, but its four arguments are unconstrained by anything in "
 "this module and its one caller (sub_FBC39D) is itself unnamed."),

("sub_FBC10A", "sub_FBC31B", "sub_FBC39D", "sub_FBC958", "sub_FBCBA7",
 "sub_FBCD17", "sub_FBD0A2", "sub_FBD1D3", "sub_FBD3E8", "sub_FBD46B",
 "sub_FBD6FC"),

("sub_FBD943", "sub_FBD9D4", "sub_FBDA2C", "sub_FBDBCE"),

("sub_FBDCD3", "sub_FBF280", "sub_FBFFD4"),

("sub_FC2430", "sub_FC24F6"),

("sub_FC28B5", "sub_FC29BF", "sub_FC2A3C", "sub_FC320B", "sub_FC3241"),

("sub_FC0F83",
 "ROUND 12's REFUSAL STANDS, and this lane adds one fact to it rather than "
 "overturning it: the RAM source it can pick, 0x0087D2 + 0x4F64, is INSIDE "
 "the tone staging image this lane framed -- 0x4F61 is where the 128th "
 "150-byte drum-instrument record ends (0x461 + 128*150), so those eight "
 "bytes are in the image's TAIL, three bytes below the 4 x 5 table "
 "ToneStage_SwitchToPart builds at +0x4F6C.  That places the bytes; it still "
 "does not say what they are, and the 8-byte ROM constant at 0xFE1365 is "
 "still `00 F5 00 00 00 00 00 00`."),

("sub_FC1B6E",
 "ROUND 12's REFUSAL STANDS -- the record sub_FB42B0 returns is still "
 "unidentified and sub_FB42B0 is still unnamed -- but two of its cited "
 "offsets now have names: part record +0x1B is a PROGRAM number and +0x1C a "
 "BANK selector.  That is prom_c's own Voice_GetOctaveShift decode "
 "(directory slot +0x6C indexed by +0x1C, slot +0xA8 indexed by +0x1B), and "
 "this module agrees with it at eight independent sites -- every call to "
 "ToneDB_ResolveToneRecord in this file pushes exactly that pair, in that "
 "order (0xFBC771/0xFBC761, 0xFBC854/0xFBC86D)."),

("sub_FC2AAF", "sub_FC2C2D", "sub_FC2CD5", "sub_FC2DA3", "sub_FC2E4B",
 "sub_FC2F1A", "sub_FC2FE9", "sub_FC30B7", "sub_FC3178", "sub_FC31BF"),
]

# The refusal text for the groups above, keyed by the first member.
GROUP_WHY = {
 "sub_FBB4BF":
 "★ WHAT IS ESTABLISHED: this routine reads tone record +0xD0, masks 0x0F "
 "and uses the result as a computed-goto index, exactly as "
 "ToneRec_LoadDspParams_ByAlgoType does -- so it too is switching on the DSP "
 "ALGORITHM TYPE.  ⚠ WHY IT IS STILL NOT NAMED: every arm's work is done by a "
 "routine OUTSIDE this module (0xFACC75 / 0xFACDC1 / 0xFACD1B / 0xFACE14), "
 "all four of which are `sub_XXXXXX` in prom_c/wsa1_prom_c.s.  A name here "
 "would be inherited from an unnamed callee.  Four routines, same shape: "
 "0xFBB4BF, 0xFBB57C, 0xFBB645, 0xFBB6F8.",

 "sub_FBC10A":
 "the write-arm subtree of ToneMsg_Dispatch below arms 2..7.  Each is reached "
 "from exactly one dispatcher arm and each writes through helpers this lane "
 "did not decode.  Naming any of them `arm N` would be naming from POSITION, "
 "which this tree has had to correct before.  What IS recorded, on "
 "ToneMsg_Dispatch's own header, is which arm reaches which -- that is the "
 "fact, and it costs nothing to state without inventing a name.",

 "sub_FBD943":
 "arithmetic leaves of sub_FBDCD3 and sub_FBF280, called 6 and 12 times each. "
 "sub_FBD9D4 halves the low byte of a 16-bit value with a carry into the high "
 "byte; sub_FBDA2C and sub_FBDBCE call Multiply32 and one unnamed scaler "
 "each.  They are recognisably fixed-point helpers, but the UNIT of the "
 "quantity is what a name would have to assert and nothing here supplies it.",

 "sub_FBDCD3":
 "the two largest computed-goto routines in the module (5,549 and 3,412 "
 "bytes, 51 and 6 arms) and their caller.  sub_FBDCD3 writes 24 absolute "
 "addresses in 0x008829..0x008856, a 46-byte run of RAM this lane did not "
 "identify; sub_FBFFD4 writes the reply payload at 0x00D94B.  Too large to "
 "name from what was decoded.",

 "sub_FC2430":
 "two query arms that reply bytes of an object 0xFB49EB returns, and "
 "0xFB49EB is unnamed and outside this file.  sub_FC24F6 additionally indexes "
 "that object at +0x12 + 23*request[+0x02] and calls 0xFB456F.  Naming these "
 "means naming 0xFB49EB first; that is a chain to attack from the other end, "
 "not a gap to paper over.",

 "sub_FC28B5":
 "five routines with no decoded consumer.  Three of them -- 0xFC29BF, "
 "0xFC2A3C, 0xFC320B -- have NO literal call site anywhere in the image (a "
 "register-indirect call would be invisible to that scan, so this is `not "
 "found`, not `dead`).  0xFC28B5 is called once from sub_FB6BA8 and 0xFC3241 "
 "once from ToneQuery_Dispatch, and neither caller's argument is pinned.",

 "sub_FC2AAF":
 "★ WHAT IS ESTABLISHED: all ten write to, or read, a RAM array of 23-byte "
 "records at 0x0000DC0E indexed by the part (`ld C,0x17` / `mul BC,(XIZ+"
 "0x08)`), and sub_FC2DA3 mirrors `field is non-zero` for the LE16s at "
 "+0x00, +0x02, +0x04 and +0x06 of that record into bits 0..3 of part record "
 "+0x06.  sub_FC2C2D fills +0x0C, +0x0E and +0x10 by summing four ROM tables "
 "at 0xFE1376 / 0xFE138A / 0xFE139C / 0xFE13AE / 0xFE13C2.  ⚠ WHY NOT NAMED: "
 "nothing found here says what the 23-byte record IS.  `four values, a "
 "non-zero flag each, and a sum of four curve tables` is consistent with "
 "several readings and this lane will not pick one.",
}



HEADER_ANCHOR = "; >>> END OF EXTRACTION HEADER"

HEADER = """\
; ==============================================================================
; ★★ WAVE 17, LANE w17/tone-db -- THE READER SIDE OF THE TONE DATABASE
; ==============================================================================
;
; ⚠ THE SENTENCE ABOVE ("EVERY LINE BELOW THIS HEADER IS VERBATIM") NO LONGER
; HOLDS, and this block is where that is said.  It is kept unedited because
; scripts/analysis/assert_comments_preserved.py requires insertions only, and
; because it was TRUE of the split it describes.  What wave 17 changed:
;
;   * 31 routines were RENAMED.  The rename touched CODE ONLY -- label
;     definitions and branch operands.  No comment was altered.
;   * 79 documentation blocks were INSERTED, one per `sub_XXXXXX` routine: 31
;     `★ W17 -- NAME AND EVIDENCE` and 48 `★ W17 -- NOT NAMED`.  Nothing was
;     removed, so every generated `Unknown:  what the routine is FOR.` still
;     stands above the block that supersedes it, and each block says so.
;   * ⚠ THE PRICE, stated rather than hidden: the generated `Called from:` /
;     `Calls:` / `Arms:` lines throughout this file STILL SPELL THE OLD NAMES.
;     They are comments and the gate forbids editing them.  Their ADDRESSES are
;     authoritative; the table below is how to resolve a stale spelling.
;
; ------------------------------------------------------------------------------
; THE RENAME TABLE -- old -> new, in address order
; ------------------------------------------------------------------------------
%(table)s
;
; ------------------------------------------------------------------------------
; ★ WHAT THIS MODULE IS, in one paragraph
; ------------------------------------------------------------------------------
; It is the TONE EDITOR and the TONE QUERY SERVER.  ToneMsg_Dispatch (0xFC2600)
; is its one entry point from MidiIn_ParseRingAndDispatch; bit 3 of request[0]
; splits it into eight WRITE arms and eight QUERY arms.  Every write arm but the
; first calls ToneStage_EnsurePartLoaded on request[+0x01], which is what makes
; request[+0x01] the part index for the whole protocol.  Staging means: copy the
; part's tone out of prom_d (or the expansion board, or another part's edit
; buffer) into ONE RAM area, edit it there, and answer queries out of it.
;
; ------------------------------------------------------------------------------
; ★★ THE RAM TONE STAGING IMAGE AT 0x0087D2 -- three regions that TILE
; ------------------------------------------------------------------------------
;   0x0087D2 + 0x0000   713 B          one whole TONE RECORD, 4 elements:
;                                        +0x000  217 B   head
;                                        +0x0D9  4 x 81  element parameter blocks
;                                        +0x21D  4 x 43  wave-select records
;   0x0087D2 + 0x02C9   408 B          one whole DRUM-KIT RECORD  (= 0x008A9B)
;                                        +0x000   16 B   name
;                                        +0x010  136 B   common
;                                        +0x098  128 x 2 note -> instrument
;   0x0087D2 + 0x0461   128 x 150 B    DRUM-INSTRUMENT RECORDS   (= 0x008C33)
;                                        +0x00    64 B   head
;                                        +0x40   2 x 43  wave-select records
;   0x0087D2 + 0x4F61   tail           the 8 bytes sub_FC0F83 can reply from
;                                      (+0x4F64) and the 4 x 5 table
;                                      ToneStage_SwitchToPart builds (+0x4F6C)
;
; 713, 408 and 150 are prom_d's OWN record sizes; 0x2C9 = 713 and 0x461 = 713 +
; 408 are prom_c's own instruction literals; 0x008C33 is separately spelled as
; an `lda` operand at 0xFB4331.  The three regions are consecutive with no
; slack, and that is the strongest single fact this lane established.
; Reproduced by notes/tone_db_naming_w17.py Q1.
;
; ------------------------------------------------------------------------------
; ★ THE PART RECORD -- 33 records of 300 bytes at RAM 0x00001523
; ------------------------------------------------------------------------------
; 300 = 0x88 + 4*41, EXACTLY, so the four per-element sub-records tile the
; record with nothing left over.  The fields this module reads:
;      +0x00  ptr32   the part's TONE RECORD (== 0x0087D2 while staged)
;      +0x04  LE16    flags; bit 0 = staged, bit 1 tested for part >= 0x21,
;                     bit 2 set by sub_FB9AC2
;      +0x06  LE16    bits 0..3 mirror `field non-zero` of the 0x0000DC0E record
;      +0x09  LE16    bit 15 -> tone record +0xD0 bit 7; bit 14 read by four
;                     algorithm-type dispatchers
;      +0x17  byte    -> tone record +0x23  (kit record +0x20)
;      +0x18  byte    -> tone record +0x24  (kit record +0x21)
;      +0x1B  byte    PROGRAM number      (Voice_GetOctaveShift's decode)
;      +0x1C  byte    BANK selector       (ditto; compared against 0x28 and 0x20)
;      +0x88 + 41*e   the per-element sub-record, e = 0..3:
;                       +0x00  ptr32  the 81-byte ELEMENT PARAMETER BLOCK
;                       +0x04  ptr32  the 43-byte WAVE-SELECT RECORD
;                       +0x36  byte   low 3 bits -> staging image +0x4F6C + 5*e
;
; ------------------------------------------------------------------------------
; ⚠ A COMMENT IN THIS FILE THAT THIS LANE BELIEVES IS WRONG -- REPORTED, NOT
;   EDITED.  Adjudication is not this lane's to make and the gate forbids the
;   edit; `python3 notes/tone_db_naming_w17.py --wrong` prints the whole case.
; ------------------------------------------------------------------------------
; The Evidence: line of ToneDB_SourceNameList1_SelectEntry (and the matching one
; on ToneDB_SourceNameList2_SelectEntry) says the catalogue row's bytes 14 and
; 15 are stored "at +0x02 and +0x03 of the part element record at 0x1523 +
; 0x012C*part + 0x29*element + 0x88".
;
; That address is not the destination.  0xFB914B is `ld XBC,(XIY+0x1523)`, a
; 32-bit LOAD from it, and 0xFB9150 is `ld (XBC+0x02),A` -- a store two bytes
; past the value LOADED.  The same field is the SOURCE of an 81-byte copy at
; 0xFB8520/0xFB853E, so what it points at is an 81-byte ELEMENT PARAMETER
; BLOCK.  The two bytes therefore land at +0x02/+0x03 of an ELEMENT BLOCK, not
; of the 41-byte part-element sub-record -- which also makes them the first
; identified field of that block.
; ==============================================================================
"""


def header_block():
    rows = []
    for old, new, _w, _e, _u in sorted(NAMES, key=lambda t: t[0]):
        rows.append(";   0x%s  %-13s -> %s" % (old[4:], old, new))
    return (HEADER % {"table": "\n".join(rows)}).split("\n")


def _wrap(s, w=64):
    out, line = [], ""
    for word in s.split():
        if line and len(line) + 1 + len(word) > w:
            out.append(line)
            line = word
        else:
            line = (line + " " + word) if line else word
    if line:
        out.append(line)
    return out


def _block(kind, body, first_pad):
    o = []
    for i, c in enumerate(_wrap(body)):
        o.append("; %s%s" % (first_pad if i == 0 else " " * len(first_pad), c))
    o[0] = "; " + kind + o[0][2 + len(first_pad):] if False else o[0]
    return o


def _field(label, body):
    pad = " " * len(label)
    lines = _wrap(body)
    return ["; %s%s" % (label if i == 0 else pad, c) for i, c in enumerate(lines)]


def apply_names():
    text = open(SRC, encoding="utf-8").read()

    # 1. rename, in the CODE half of a line only.
    table = {o: n for o, n, _w, _e, _u in NAMES}
    live = {o: n for o, n in table.items()
            if re.search(r"^" + re.escape(o) + r":", text, re.M)}
    pat = re.compile(r"(?<![A-Za-z0-9_])(" +
                     "|".join(re.escape(o) for o in live) + r")(?![0-9A-Za-z])")
    out = []
    renamed = 0
    for line in text.split("\n"):
        if line.lstrip().startswith(";") or not live:
            out.append(line)
            continue
        head, sep, tail = line.partition(";")
        new_head, k = pat.subn(lambda m: live[m.group(1)], head)
        renamed += k
        out.append(new_head + sep + tail)
    lines = out

    # 2. insert the documentation block above the separator line that
    #    precedes each label.  Nothing is removed.
    def insert_above_label(lines, label, block):
        try:
            j = next(k for k, l in enumerate(lines) if l.startswith(label + ":"))
        except StopIteration:
            print("  MISSING %s" % label)
            return lines, False
        i = j - 1
        while i >= 0 and lines[i].startswith(";"):
            i -= 1
        if any(TAG in lines[k] for k in range(i + 1, j)):
            return lines, False
        at = j
        while at - 1 > i and lines[at - 1].startswith("; ---"):
            at -= 1
        return lines[:at] + block + lines[at:], True

    named = 0
    for old, new, what, ev, unk in NAMES:
        blk = (["; " + "=" * 74,
                "; ★ " + TAG + "NAME AND EVIDENCE.  This block is ADDED, never"
                " substituted:"] +
               _field("          ", "the generator's `Unknown:  what the routine"
                      " is FOR.` paragraph above is kept VERBATIM because"
                      " scripts/analysis/assert_comments_preserved.py requires"
                      " insertions only.  Where the two disagree, this block is"
                      " the later reading.") +
               _field("Name:     ", what) +
               _field("Evidence: ", ev) +
               _field("Unknown:  ", unk) +
               _field("Named:    ", "WAVE 17, lane w17/tone-db -- it was `%s`. "
                      "Every literal cited above is re-read from the ROM at the"
                      " address it is cited at by notes/tone_db_naming_w17.py"
                      " (102 checks)." % old) +
               ["; " + "=" * 74])
        lines, ok = insert_above_label(lines, new, blk)
        named += 1 if ok else 0

    # 3. refusals
    groups = []
    for entry in REFUSALS_REAL:
        if isinstance(entry, tuple) and len(entry) == 2 and isinstance(entry[1], str) \
                and entry[0].startswith("sub_") and " " in entry[1]:
            groups.append(([entry[0]], entry[1]))
        else:
            members = list(entry)
            groups.append((members, GROUP_WHY[members[0]]))

    refused = 0
    for members, why in groups:
        for m in members:
            blk = (["; " + "-" * 74,
                    "; ★ " + TAG + "NOT NAMED, and this is what was tried."] +
                   _field("NotNamed: ", why) +
                   _field("          ", "Nothing above this line was changed;"
                          " the routine keeps its address name."
                          "  notes/tone_db_apply_w17.py") +
                   ["; " + "-" * 74])
            lines, ok = insert_above_label(lines, m, blk)
            refused += 1 if ok else 0

    # 4. the file header block
    if not any("WAVE 17, LANE w17/tone-db" in l for l in lines):
        k = next(i for i, l in enumerate(lines) if l.startswith(HEADER_ANCHOR))
        lines = lines[:k + 1] + [""] + header_block() + lines[k + 1:]

    open(SRC, "w", encoding="utf-8").write("\n".join(lines))
    print("  renamed %d code references over %d labels; %d name blocks, "
          "%d refusal blocks inserted" % (renamed, len(live), named, refused))


def verify():
    text = open(SRC, encoding="utf-8").read()
    bad = 0
    for old, new, _w, _e, _u in NAMES:
        if not re.search(r"^" + re.escape(new) + r":", text, re.M):
            print("  MISSING label %s" % new)
            bad += 1
        for m in re.finditer(r"^(?!\s*;).*" + re.escape(old) + r"(?![0-9A-Za-z])",
                             text, re.M):
            if ";" in m.group(0) and old in m.group(0).split(";", 1)[1] \
                    and old not in m.group(0).split(";", 1)[0]:
                continue
            print("  STALE code reference to %s: %s" % (old, m.group(0)[:70]))
            bad += 1
    n = text.count(TAG)
    print("  %d W17 blocks present, %d problems" % (n, bad))
    return 1 if bad else 0


if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    apply_names()
    sys.exit(verify())
