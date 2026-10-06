; ===========================================================================
; Sound Data Section - Instrument Category Metadata & Sound Data Includes
; ===========================================================================
;
; This file contains:
;   1. Region identifier string (16-byte padded, possibly "HK" = Hong Kong variant)
;   2. Category table descriptor structure:
;        +0: pointer to SoundData_CategoryDesc
;        SoundData_CategoryDesc layout:
;          +0  .long  pointer to SOUND_CATEGORY_NAMES string table
;          +4  .long  entry count (18 = number of categories)
;          +8  .long  stride or field offset (0x28 = 40)
;          +8  = 40 SOUNDS PER CATEGORY: FetchOscTableEntry_Prologue bounds the
;                slot with it and multiplies the category by it (see below).
;          +12 .long  0xffffffff; no instruction found reads +0x0C.  It is NOT an
;                end-of-descriptor sentinel: the same base pointer is indexed
;                at +0x10..+0x4C by the readers listed below.
;   3. +0x10..+0x4C: sixteen TABLE POINTERS (SOUND_DATA_SECTION_PTRS), each
;      read at its fixed descriptor offset by its own routine.  They are
;      NOT one per instrument category: the labels SOUND_DATA_PIANO ...
;      SOUND_DATA_DRUM_KITS were given by pairing slot k with category-name
;      k, and no reader indexes this array by category.  (Corrected
;      2026-09-25; the old line said "16 entries, one per instrument
;      category".)
;   4. Sound category name table (18 x 16-char fixed-width, space-padded)
;   5. The tables themselves, compiled from audio/sound_data_*.c or written
;      in audio/sound_data_brass.s / sound_data_world_perc.s.
;
; HOW THE FIRMWARE REACHES ALL OF THIS -- one pointer, one RAM cell.
;   Param_SignExtendRetu_Block (v10/v9 0xFEEBE6, v7 0xFEE417) does
;       ld xwa, (SoundData_CategoryDescPtr)  /  ld (RAM), xwa
;   with RAM = 0xE14E in v10/v9 and 0xE0B2 in v7.  Every other access goes
;   through that cell: `ld xr, (0xe14e)` occurs exactly 14 times in v10
;   (0xFEE467 .. 0xFEEA46), and `ld xr, (0xe0b2)` 14 times in v7, each at
;   the v10 address - 0x7CF.  No instruction holds 0xE023B0 (the pointer
;   array) or any of its slot addresses directly.
;
;   ⚠ v7 addresses below are where the CODE is (found by byte search: each
;   routine matches v10 except for its RAM / call operands).  The v7 source
;   currently puts most of the same-named labels 0x41A bytes higher; see
;   scripts/analysis/v7_label_drift.py for the measurement.
;
; THE SOUND-SELECTION RECORD.  The readers share one small record, passed in
; XWA or XIZ; the offsets each reader uses are:
;   +0 category (0..17)   +1 slot within the category (0..39)
;   +2 voice index (0..127) in the +0x18/+0x1C/+0x30 readers, the part
;      number in Sound_Navigate
;   +3 program number     +4 bank number     +5 part number
; Sound_Navigate (0xF98E13 / 0xF98A06) fills +3/+4 from a part's parameters
; 0x00 and 0x20 (SndParam_LookupViaEncode) and reads +0/+1 back.
;
; "MODE 1" below means SndParam_LookupReadOnly(0xC0) returned 1 (v10/v9
; 0xFCD437, v7 0xFCCC66).  Four readers pick slot +k in mode 0 and +k+0x10 in
; mode 1.  In mode 1 the tables hold 128 sounds in 12 categories plus 8 drum
; kits -- 128 is the General MIDI program count, so mode 1 is probably the GM
; mode; that is an inference from the counts, no reader names it.
;
; PROOF THAT THE PAIRS ARE INVERSE MAPS (scripts/analysis/sound_data_map_proof.py,
; run on all three dumps, identical result):
;   +0x14 grid -> (program, bank) -> +0x10 bank map -> (category, slot):
;         368 of 368 populated cells come back to themselves
;   +0x24 grid -> +0x20 bank map (mode 1):          136 of 136
;   +0x1C list  -> (program, bank) -> +0x18 -> voice index:  128 of 128
;   +0x2C list  -> +0x28 (mode 1):                  128 of 128
;   and the +0x3C table (normal parts) sums to 368 sounds, the +0x48 table
;   (mode 1) to 128 -- the same totals, counted a different way.
;
; ===========================================================================

; --- Instrument Sound Data & Category Metadata ---
; Possibly a region identifier: "HK" (Hong Kong variant?), 16-byte padded string + version + sentinels.
; Unreferenced -- may be accessed via computed address or unused.
SoundData_RegionID:	.ascii "HK              "
	.byte 0x01, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff

; The only pointer to the descriptor.  Read by Param_SignExtendRetu_Block
; (v10/v9 0xFEEBE6, v7 0xFEE417) into RAM 0xE14E (v7: 0xE0B2); see above.
SoundData_CategoryDescPtr:
	.long SoundData_CategoryDesc

; Descriptor header.  Readers of each field (v10/v9 / v7 addresses):
;   +0x00 SOUND_CATEGORY_NAMES: StoreDRAMInit_LoadDRAM (0xFEE608 / 0xFEDE39)
;         copies the 16-byte name of category A to XBC; A > +0x04 - 1 gets
;         the 16-byte string "WRONG SW NUMBER!" (v10 0xEED298) instead.
;   +0x04 18, the category count: StoreDRAMInit_LoadDRAM's bound, and the
;         value ApplyProgramChangeAs_DoLookupRe (0xFEE770 / 0xFEDFA1) returns
;         as the bound on record +0 (mode 1 returns 0x80, or 0x89 for part 15).
;   +0x08 40, sounds per category: FetchOscTableEntry_Prologue (0xFEE808 /
;         0xFEE039) clamps record +1 below it and computes cat*40 + slot.
;   +0x0C 0xFFFFFFFF: no instruction found reads it.
SoundData_CategoryDesc:
	.long SOUND_CATEGORY_NAMES
	.long 18
	.long 40
	.long 0xffffffff

; Sound data section pointers (16 entries)
; Descriptor slots +0x10..+0x4C.  The reader of each (v10/v9 / v7), with the
; record it consumes; mode-1 twins are read by the same routine as their
; mode-0 slot:
;   +0x10 / +0x20  ApplyProgramChangeAs_LoadDRAM2 0xFEE798 / 0xFEDFC9
;                  (bank, program) -> (category, slot)
;   +0x14 / +0x24  FetchOscTableEntry_Prologue 0xFEE808 / 0xFEE039
;                  (category, slot) -> (program, bank)
;   +0x18 / +0x28  ApplyProgramChange_LoadDRAM 0xFEE87F / 0xFEE0B0
;                  (bank, program) -> voice index
;   +0x1C / +0x2C  SndParam_LookupOscEnvelope 0xFEE8F1 / 0xFEE122
;                  voice index -> (program, bank).  Nothing found indexes
;                  +0x2C: in mode 1 SndParam_CheckAndApplyMode (0xFEE99F /
;                  0xFEE1D0) calls SndParam_ApplyVoiceValue instead.
;   +0x30          SndParam_LookupOscEnvelope and SndParam_LookupAndDispatch
;                  (0xFEEA24 / 0xFEE255): voice index -> 2 bytes, part 15
;   +0x34          SndParam_LookupByPartAndNote 0xFEE9EA / 0xFEE21B
;   +0x38          SndParam_LookupFromPointerTable 0xFEE9BD / 0xFEE1EE
;   +0x3C .. +0x4C CharMap_ActivePreamb_Prologue 0xFEE43F / 0xFEDC70
; The slot labels below are historical (slot k paired with category k).
SOUND_DATA_SECTION_PTRS:
	.long SOUND_DATA_PIANO
	.long SOUND_DATA_GUITAR
	.long SOUND_DATA_STRINGS_VOCAL
	.long SOUND_DATA_BRASS_PTRS
	.long SOUND_DATA_FLUTE
	.long SOUND_DATA_SAX_REED
	.long SOUND_DATA_MALLET_ORCH_PERC
	.long SOUND_DATA_WORLD_PERC
	.long SOUND_DATA_ORGAN_ACCORDION
	.long SOUND_DATA_ORCHESTRAL_PAD
	.long SOUND_DATA_SYNTH
	.long SOUND_DATA_BASS
	.long SOUND_DATA_DIGITAL_DRAWBAR
	.long SOUND_DATA_ACCORDION_REG
	.long SOUND_DATA_GM_SPECIAL
	.long SOUND_DATA_DRUM_KITS

; Sound category names - fixed-width string table for the sound selection UI
; 18 entries x 16 characters each, space-padded and centered
; Referenced via structure at E023A0: pointer, count=18, field=0x28
SOUND_CATEGORY_NAMES:
	.ascii "     PIANO      "	;  0: Piano
	.ascii "     GUITAR     "	;  1: Guitar
	.ascii "STRINGS & VOCAL "	;  2: Strings & Vocal
	.ascii "     BRASS      "	;  3: Brass
	.ascii "     FLUTE      "	;  4: Flute
	.ascii "   SAX & REED   "	;  5: Sax & Reed
	.ascii "MALLET&ORCH PERC"	;  6: Mallet & Orch Perc
	.ascii "   WORLD PERC   "	;  7: World Perc
	.ascii "ORGAN&ACCORDION "	;  8: Organ & Accordion
	.ascii " ORCHESTRAL PAD "	;  9: Orchestral Pad
	.ascii "     SYNTH      "	; 10: Synth
	.ascii "      BASS      "	; 11: Bass
	.ascii "DIGITAL DRAWBAR "	; 12: Digital Drawbar
	.ascii " ACCORDION REG. "	; 13: Accordion Reg.
	.ascii "   GM SPECIAL   "	; 14: GM Special
	.ascii "   DRUM KITS    "	; 15: Drum Kits
	.ascii "    MEMORY A    "	; 16: Memory A
	.ascii "    MEMORY B    "	; 17: Memory B

; Descriptor slot +0x10 (mode 0): BANK/PROGRAM -> CATEGORY/SLOT map, 8,320 B.
; Reader ApplyProgramChangeAs_LoadDRAM2 (v10/v9 0xFEE798, v7 0xFEDFC9), entered
; from SndParam_FetchOscTableEntry (0xFEE7EA / 0xFEE01B) with DE = 0x400:
;   blk    = table[record+4]                 128-byte bank header, one byte
;                                            per bank number
;   rec    = table + 0x80 + blk*0x400 + record[+3]*4
;   record[+0] = low byte of rec word +0     category 0..17
;   record[+1] = low byte of rec word +2     slot 0..39
; So 8 blocks (header values 0..7; 0x80 + 8*0x400 = 8,320 B, which is also
; the distance to the next label) of 256 four-byte records.  Header bytes
; 8..127 are 0: every other bank number reads block 0.
; Inverse of slot +0x14 (SOUND_DATA_GUITAR): 368/368 cells round-trip.
SOUND_DATA_PIANO:	.incbin "includes/generated/sound_data_piano.bin"

; Descriptor slot +0x14 (mode 0): CATEGORY/SLOT -> PROGRAM/BANK grid, 1,440 B.
; Reader FetchOscTableEntry_Prologue (v10/v9 0xFEE808, v7 0xFEE039), entered
; from SndParam_ApplyProgramChange (0xFEE861 / 0xFEE092):
;   w = record[+0] if below the ApplyProgramChangeAs_DoLookupRe bound else 0
;   l = record[+1] if below descriptor +0x08 (40) else 0
;   e = table + 2*(w*40 + l);  record[+3] = e[0];  record[+4] = e[1]
; 18 x 40 x 2 = 1,440 B, the distance to the next label.  A cell of 0x0000
; other than (0,0) is an empty slot: 368 cells are populated, exactly the
; sum of the per-category counts in slot +0x3C (SOUND_DATA_BASS).
SOUND_DATA_GUITAR:	.incbin "includes/generated/sound_data_guitar.bin"

; Descriptor slot +0x18 (mode 0): BANK/PROGRAM -> VOICE INDEX map, 8,320 B.
; Reader ApplyProgramChange_LoadDRAM (v10/v9 0xFEE87F, v7 0xFEE0B0), entered
; from SndParam_ComputeVoiceIndex (0xFEE8D3 / 0xFEE104) with DE = 0x400.  Same
; addressing as slot +0x10 (header byte per bank, 0x400-byte blocks, record
; = program*4), but it stores record[+0] = 0, record[+2] = low byte of word
; +0 (a voice index 0..127) and record[+1] = low byte of word +2 (0 in every
; record).  8 blocks, 8,320 B to the next label.  Its inverse is slot +0x1C
; (SOUND_DATA_BRASS_PTRS): 128/128 voice indices round-trip.
SOUND_DATA_STRINGS_VOCAL:	.incbin "includes/generated/sound_data_strings_vocal.bin"

SOUND_DATA_BRASS_PTRS:		.include "audio/sound_data_brass.s"

; Descriptor slot +0x20 (MODE 1 twin of +0x10): BANK/PROGRAM -> CATEGORY/SLOT.
; Same reader as SOUND_DATA_PIANO (ApplyProgramChangeAs_LoadDRAM2) but with
; DE = 0x200: blocks of 128 four-byte records.  The table is 7,296 B =
; 0x80 + 14*0x200 and runs on through SOUND_DATA_FLUTE_EXTRA, which is not a
; separate object (see there).  Header: banks 0..9 -> blocks 0..9, bank 16
; -> 10, 24 -> 11, 32 -> 12, 120 -> 13, all others -> block 0.
; Inverse of slot +0x24 (SOUND_DATA_SAX_REED): 136/136 cells round-trip.
SOUND_DATA_FLUTE:	.incbin "includes/generated/sound_data_flute.bin"
; NOT a separate table: the last 4,798 B of the 7,296-byte slot +0x20 table
; above (it begins mid-record, 0x942 bytes into the record area).  The label
; exists only because sequencer/sequencer_engine.s SoundData_HandlerDispatch
; spells `call PartParam_Handler_03 / jrl AppEvent_PopIzSkip2Ret` (bytes
; 1d a9 04 f2 78 e0 00 at v10 0xF451D6) as `.byte 0x1d, 0xa9, 0x04` +
; `.long SOUND_DATA_FLUTE_EXTRA` -- a phantom reference.  Kept until that
; file is corrected, because removing it would break its assembly.
SOUND_DATA_FLUTE_EXTRA:	.incbin "includes/generated/sound_data_flute_extra.bin"

; Descriptor slot +0x24 (MODE 1 twin of +0x14): CATEGORY/SLOT -> PROGRAM/BANK
; grid, 1,440 B, same reader and layout as SOUND_DATA_GUITAR.  136 cells are
; populated: the 128 sounds of the slot +0x48 table plus 8 drum kits (slot
; +0x4C, category 15).
SOUND_DATA_SAX_REED:	.incbin "includes/generated/sound_data_sax_reed.bin"

; Descriptor slot +0x28 (MODE 1 twin of +0x18): BANK/PROGRAM -> VOICE INDEX,
; same reader as SOUND_DATA_STRINGS_VOCAL with DE = 0x200: 7,296 B =
; 0x80 + 14*0x200, same 14-block bank header as slot +0x20.  Its inverse is
; slot +0x2C (SOUND_DATA_WORLD_PERC): 128/128.
SOUND_DATA_MALLET_ORCH_PERC:	.incbin "includes/generated/sound_data_mallet_orch_perc.bin"

SOUND_DATA_WORLD_PERC:		.include "audio/sound_data_world_perc.s"

; Descriptor slot +0x30: VOICE INDEX -> 2 bytes, 128 x 2 = 256 B.
; Readers (v10/v9 / v7):
;   SndParam_LookupOscEnvelope (0xFEE8F1 / 0xFEE122) uses it instead of slot
;     +0x1C when record[+5] == 15 or SndParam_LookupViaEncode(record[+5], 0)
;     >= 0xF0: record[+3] = t[2*v], record[+4] = t[2*v+1], v = record[+2];
;   SndParam_LookupAndDispatch (0xFEEA24 / 0xFEE255), when its bank argument
;     is 0x78: (A, C) = (t[2*A], t[2*A+1]).
; Every entry is (b, 0) with b one of 0xF0-0xF3, 0xF5, 0xF7, 0xFC, 0xFD.
SOUND_DATA_ORGAN_ACCORDION:	.incbin "includes/generated/sound_data_organ_accordion.bin"

; Descriptor slot +0x34: VOICE INDEX -> signed byte, 128 B.
; Reader SndParam_LookupByPartAndNote (v10/v9 0xFEE9EA, v7 0xFEE21B): puts
; its A/C arguments in record +3/+4, calls SndParam_ComputeVoiceIndex (slot
; +0x18/+0x28) and returns L = t[record[+2]].  The caller at v10 0xF24D8C
; (MidiNoteOn_NonDrumLookupA, sequencer/smf_tonegen_core.s) adds L to the
; byte at RAM 0x0FAC.  Values are 0, 12 and 0xF4 (-12) only -- the shape of
; an octave shift in semitones; what the sum is used for is not traced.
SOUND_DATA_ORCHESTRAL_PAD:	.incbin "includes/generated/sound_data_orchestral_pad.bin"

; Descriptor slot +0x38: PROGRAM-CHANGE REMAP, 128 x 2 = 256 B.
; Reader SndParam_LookupFromPointerTable (v10/v9 0xFEE9BD, v7 0xFEE1EE),
; called from Dispatch_Prologue (0xFED8AB / 0xFED0DC) for a MIDI message with
; status 0xCn: t[2*p] and t[2*p+1] for program p.  Dispatch_Prologue then
; sends, through MIDI_SendSinglePacket,
;   Bn 00 (t[2p] >> 7)          bank select MSB
;   Bn 20 ((t[2p+1] & 7) << 4)  bank select LSB
;   Cn (t[2p] & 0x7F)           program change
SOUND_DATA_SYNTH:	.incbin "includes/generated/sound_data_synth.bin"

; Descriptor slots +0x3C..+0x4C: FIVE PER-CATEGORY "LAST SOUND" TABLES, 18 B
; each (the DRUM_KITS object below carries more data after its 18 bytes).
; Reader CharMap_ActivePreamb_Prologue (v10/v9 0xFEE43F, v7 0xFEDC70) returns
; L = t[C] for category C, choosing t by mode and part:
;   mode 0: part 15 -> +0x40, part 20 -> +0x44, any other part -> +0x3C
;   mode 1: part 15 -> +0x4C, any other part -> +0x48
; Its caller GetSoundBankCount (0xF98FAA / 0xF98B9D) sign-extends L, and
; Sound_Navigate (0xF98E13 / 0xF98A06) steps through categories 0..17,
; moving its position by L+1 per category and skipping a category whose
; value is 0xFFFF.  So each byte is
; the LAST SLOT INDEX of that category for that part class, 0xFF = category
; not offered.  Pinned independently: +0x3C sums to 368 sounds and +0x48 to
; 128, the populated-cell counts of the +0x14 and +0x24 grids.
SOUND_DATA_BASS:	.incbin "includes/generated/sound_data_bass.bin"
SOUND_DATA_DIGITAL_DRAWBAR:	.incbin "includes/generated/sound_data_digital_drawbar.bin"
SOUND_DATA_ACCORDION_REG:	.incbin "includes/generated/sound_data_accordion_reg.bin"
SOUND_DATA_GM_SPECIAL:	.incbin "includes/generated/sound_data_gm_special.bin"
; Slot +0x4C (mode 1, part 15): first 18 bytes as above.  The 195 bytes
; after them are loaded by display/scoop_display.s at +0x12
; (Scoop_CallDisplayHelper_SingleTableList, 8 bytes: Scoop_CallDisplayHelper_DisplayList_Code
; hands it to UIRender_SingleTable in XIY, with +0x1A as the end bound in XIX), +0x1A
; (Scoop_CallDisplayHelper_DisplayList_Data) and +0x3A
; (Scoop_TrackTypeNameField) -- labels since 2026-10-03, positional `.set`
; aliases before -- and are described, without a cited reader, in
; audio/sound_data_drum_kits.c; the +0x4C reader never indexes past byte 17.
SOUND_DATA_DRUM_KITS:				.incbin "includes/generated/sound_data_drum_kits.bin", 0x0, 0x12
Scoop_CallDisplayHelper_SingleTableList:	.incbin "includes/generated/sound_data_drum_kits.bin", 0x12, 0x8
Scoop_CallDisplayHelper_DisplayList_Data:	.incbin "includes/generated/sound_data_drum_kits.bin", 0x1A, 0x20
Scoop_TrackTypeNameField:		.incbin "includes/generated/sound_data_drum_kits.bin", 0x3A, 0x9B
