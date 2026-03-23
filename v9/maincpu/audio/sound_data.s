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
;          +12 .long  sentinel (0xFFFFFFFF = end-of-descriptor)
;   3. Sound data section pointer table (16 entries, one per instrument category)
;   4. Sound category name table (18 x 16-char fixed-width, space-padded)
;   5. Per-category instrument data includes
;
; ===========================================================================

; --- Instrument Sound Data & Category Metadata ---
; Possibly a region identifier: "HK" (Hong Kong variant?), 16-byte padded string + version + sentinels.
; Unreferenced -- may be accessed via computed address or unused.
SoundData_RegionID:	.ascii "HK              "
	.byte 0x01, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff

SoundData_CategoryDescPtr:
	.long SoundData_CategoryDesc

SoundData_CategoryDesc:
	.long SOUND_CATEGORY_NAMES
	.byte 0x12, 0x00, 0x00, 0x00
	.byte 0x28, 0x00, 0x00, 0x00
	.byte 0xff, 0xff, 0xff, 0xff

; Sound data section pointers (16 entries)
; Each pointer references a sound data block for a category
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

SOUND_DATA_PIANO:
	.incbin "includes/generated/sound_data_piano.bin"
SOUND_DATA_GUITAR:
	.incbin "includes/generated/sound_data_guitar.bin"
SOUND_DATA_STRINGS_VOCAL:
	.incbin "includes/generated/sound_data_strings_vocal.bin"
SOUND_DATA_BRASS_PTRS:		.include "audio/sound_data_brass.s"
SOUND_DATA_FLUTE:
	.incbin "includes/generated/sound_data_flute.bin"
SOUND_DATA_FLUTE_EXTRA:
	.incbin "includes/generated/sound_data_flute_extra.bin"
SOUND_DATA_SAX_REED:
	.incbin "includes/generated/sound_data_sax_reed.bin"
SOUND_DATA_MALLET_ORCH_PERC:
	.incbin "includes/generated/sound_data_mallet_orch_perc.bin"
SOUND_DATA_WORLD_PERC:		.include "audio/sound_data_world_perc.s"
SOUND_DATA_ORGAN_ACCORDION:
	.incbin "includes/generated/sound_data_organ_accordion.bin"
SOUND_DATA_ORCHESTRAL_PAD:
	.incbin "includes/generated/sound_data_orchestral_pad.bin"
SOUND_DATA_SYNTH:
	.incbin "includes/generated/sound_data_synth.bin"
SOUND_DATA_BASS:
	.incbin "includes/generated/sound_data_bass.bin"
SOUND_DATA_DIGITAL_DRAWBAR:
	.incbin "includes/generated/sound_data_digital_drawbar.bin"
SOUND_DATA_ACCORDION_REG:
	.incbin "includes/generated/sound_data_accordion_reg.bin"
SOUND_DATA_GM_SPECIAL:
	.incbin "includes/generated/sound_data_gm_special.bin"
SOUND_DATA_DRUM_KITS:
	.incbin "includes/generated/sound_data_drum_kits.bin"
