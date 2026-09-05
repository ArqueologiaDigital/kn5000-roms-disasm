; Extension Device Data Tables & NAKA Widget Descriptors
; Extension subsystem (codename "TOSHI"): chord type tables, MSP configuration,
; accompaniment parameters, and UI widget descriptors for expansion devices
;
; ---------------------------------------------------------------------------
; THE 18-BYTE SOUND-PARAMETER DESCRIPTOR (0xEDBA44-0xEE0154, 974 records)
; ---------------------------------------------------------------------------
; CORRECTED 2026-09-02.  This header used to say "0xEDCAD6-0xEE0010, 956
; records" and to describe the fields only as statistical CLASSES (VARY / FLAG
; / CONST).  Both were wrong or incomplete:
;
;   * the pointer table is at 0xEE0198 and holds 974 record pointers, not 956;
;     the first two (0xEE0198, 0xEE019C) name two SHORT auxiliary tables of
;     8 and 12 bytes, and SndParam_RegisterAllWidgets iterates the other 972
;     from 0xEE01A0 with `cp xiz, 0x3cc`;
;   * the block starts at 0xEDBA44, 0x1092 bytes lower than stated, and ends at
;     0xEE0154 -- which is 0x144 bytes INSIDE ui_widgets/widget_dispatch.s,
;     because this file ends at 0xEE0010;
;   * every field except +0x11 has a reader.  See
;     audio/sndparam_records/sndparam_types.h for the C struct and, per field,
;     the instruction in audio/sndparam_routines.s that reads it: the u32 hash
;     key at +0x00, the RAM-bank index and byte offset at +0x04/+0x05, the
;     mask / clamp-min / clamp-max / shift / xor at +0x06..+0x0A, the auxiliary
;     record index at +0x0B, and the four bounds-checked accessor indices plus
;     the codec selector at +0x0C..+0x10.  +0x11 has NO reader anywhere in the
;     0xFCD200-0xFCF000 accessor region.
;
; 951 of the 974 records are now C structs, compiled byte-exact by
; `clang -target tlcs900` and .incbin'd in nine runs below and one in
; ui_widgets/widget_dispatch.s (see scripts/generators/gen_sndparam_records_c.py).
; The 23 that are not are in runs of 1-7 records whose last record ends in the
; middle of a source line that continues into an unrelated auxiliary table; the
; generator refuses those rather than guessing where to cut.
;
; SURVIVING FROM THE OLD HEADER, still true and still worth keeping:
;
; !! BYTE FIELDS, NOT u16 (except the +0x00 key).  Reading the record as nine
; little-endian u16s fails: the high halves at +0x01, +0x05, +0x0B, +0x0D and
; +0x11 are set in 93-100% of records.  Do not "improve" these rows to `.hword`.
;
; !! WHY THIS BLOCK LOOKS LIKE CODE TO A STATISTIC.  Before this file was
; re-typed, 1,590 of its 1,721 `.byte` runs beginning with an undecodable byte
; started INSIDE one of these records, clustered at a few field offsets --
; +0x0C alone 48.0%, +0x08 17.5%, +0x00 9.2%, +0x05 7.2% -- and 0x01/0x04 were
; 97.9% of them.  That is the value 1 in a low-valued parameter field, not an
; opcode.  Nothing calls or jumps to any address in this file: 0 of the 59,849
; absolute call/jp/jr targets named anywhere in v10/maincpu land inside it.
;
; !! THE RECORD LABELS ARE NOT EVIDENCE.  ExtPartParam_*, SeqMixParam_*,
; PartParam_*, MidiChParam_*, VoiceParamEx_* and VoiceCtrlR1_* were assigned by
; ADDRESS-RANGE BUCKETING in commits feda55d9 and 16f0917a, not by any reader.
; Nothing distinguishes the six kinds structurally and no code references any
; of the labels -- they exist only so the pointer table can name them.
; ---------------------------------------------------------------------------

ExtData_ChordTypeTable_Top:
	.long SeqVoice_ValidateState_StoreChannel
	.long 0x00EE00ED
	.long NakaData_PartConfig
	.long SepaOut_FormatData_Tail
	.byte 0xed, 0x00, 0xdc, 0x00, 0xed, 0x00, 0xd6, 0x00, 0xed, 0x00, 0xd0, 0x00, 0xed, 0x00, 0xca, 0x00
	.byte 0xed, 0x00, 0xc4, 0x00, 0xed, 0x00, 0xbe, 0x00, 0xed, 0x00, 0xb8, 0x00, 0xed, 0x00, 0xb2, 0x00
ExtData_ChordTypeTable_Mid:
	.byte 0xed, 0x00, 0xac, 0x00, 0xed, 0x00, 0xa6, 0x00, 0xed, 0x00, 0xa0, 0x00, 0xed, 0x00, 0x9a, 0x00
	.byte 0xed, 0x00, 0x94, 0x00, 0xed, 0x00, 0x8e, 0x00, 0xed, 0x00, 0x88, 0x00, 0xed, 0x00, 0x82, 0x00
	.byte 0xed, 0x00, 0x7c, 0x00, 0xed, 0x00, 0x76, 0x00, 0xed, 0x00, 0x70, 0x00, 0xed, 0x00, 0x6a, 0x00
	.byte 0xed
ExtData_ChordType_NullByte:
	aligned_string ""
ChordTypeStr_Blank_0:	aligned_string "     "
ChordTypeStr_Blank_1:	aligned_string "     "
ChordTypeStr_Blank_2:	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	aligned_string "madd9"
	aligned_string " add9"
	aligned_string "+7~9e11"
	aligned_string "m7 11"
	aligned_string "7 ~9e11"
	aligned_string "  ~a013"
	aligned_string "   13"
	aligned_string "~9e9~a013"
ChordTypeStr_Flat9_Flat13:	aligned_string "~a09~a013"
ChordTypeStr_Sharp9_Flat13:	aligned_string "  ~a013"
ChordTypeStr_Flat13_Only:	aligned_string "~9e9 13"
ChordTypeStr_Sharp9_13:	aligned_string "~a09 13"
ChordTypeStr_9_Flat5:	aligned_string "9~9e5  "
ChordTypeStr_13_Only:	aligned_string "   13"
ChordTypeStr_mM7_Sharp5:	aligned_string "mM7~a05"
ChordTypeStr_M7_Flat5:	aligned_string "M7~9e5 "
ChordTypeStr_M7_Sharp5:	aligned_string "M7~a05 "
ChordTypeStr_7_Flat9:	aligned_string "7 ~9e9 "
ChordTypeStr_sus4:	aligned_string "sus4 "
ChordTypeStr_69:	aligned_string "m69  "
	aligned_string "m79  "
	aligned_string "m ~a05 "
	aligned_string "m6   "
	aligned_string "69   "
	.byte 0x4d, 0x37
ChordTypeStr_M7_9:	.byte 0x39, 0x20, 0x20, 0x00
	aligned_string "7 ~a09 "
	aligned_string "79   "
	aligned_string "7 ~a05 "
	aligned_string "  ~a05 "
	aligned_string "aug7 "
	aligned_string "6    "
	.byte 0x37, 0x73
ChordTypeStr_7sus4:	.byte 0x75, 0x73, 0x34, 0x00
	aligned_string "mM7  "
	aligned_string "m7~a05 "
	aligned_string "dim  "
	aligned_string "min7 "
	aligned_string "min  "
	aligned_string "aug  "
	aligned_string "Maj7 "
	aligned_string "7    "
	aligned_string "     "
	aligned_string "     "
	.byte 0x98, 0x02, 0xed, 0x00, 0x94, 0x02, 0xed, 0x00, 0x8e, 0x02, 0xed, 0x00, 0x8a, 0x02, 0xed, 0x00
	.byte 0x84, 0x02, 0xed, 0x00, 0x80, 0x02, 0xed, 0x00, 0x7c, 0x02, 0xed, 0x00, 0x76, 0x02, 0xed, 0x00
	.byte 0x72, 0x02, 0xed, 0x00, 0x6c, 0x02, 0xed, 0x00, 0x68, 0x02, 0xed, 0x00, 0x62, 0x02, 0xed, 0x00
	.byte 0x5e, 0x02, 0xed, 0x00, 0x5a, 0x02, 0xed, 0x00, 0x56, 0x02, 0xed, 0x00, 0x52, 0x02, 0xed, 0x00
	.byte 0x20, 0x20, 0x00, 0xff
	.byte 0x20, 0x20, 0x00, 0xff
	.byte 0x20, 0x20, 0x00, 0xff
	.byte 0x42, 0x20, 0x00, 0xff
	aligned_string "B~a0"
	aligned_string "A "
	aligned_string "A~a0"
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED0272-0xED0284 (18 B), unreached CODE-territory, was disassembled as 7 plausible-but-dead instruction lines; per=75% dist=9 near ChordTypeStr_7sus4+162
	aligned_string "G "
	aligned_string "G~a0"
	aligned_string "F "
	aligned_string "E "
	aligned_string "E~a0"
	.byte 0x44, 0x20, 0x00, 0xff
	.byte 0x44, 0x7e, 0x61, 0x30, 0x00, 0xff
	.byte 0x43, 0x20, 0x00, 0xff
	.byte 0x20, 0x20, 0x00, 0xff
	.byte 0x22, 0x03, 0xed, 0x00
NoteNameStr_Table_0:
	.long NoteStr0_C
	.long NoteStr0_CSharp
	.long NoteStr0_D
	.long NoteStr0_DSharp
	.long NoteStr0_E
	.long NoteStr0_F
	.long NoteStr0_FSharp
	.long NoteStr0_G
	.long NoteStr0_GSharp
	.long NoteStr0_A
	.long NoteStr0_ASharp
	.long NoteStr0_B
	.long NoteStr0_Blank_2
	.long NoteStr0_Blank_1
	.long NoteStr0_Blank_0
NoteStr0_Blank_0:
	aligned_string "  "
NoteStr0_Blank_1:
	aligned_string "  "
NoteStr0_Blank_2:
	aligned_string "  "
NoteStr0_B:
	aligned_string "B "
NoteStr0_ASharp:	aligned_string "A~9e"
NoteStr0_A:
	aligned_string "A "
NoteStr0_GSharp:	aligned_string "G~9e"
NoteStr0_G:
	aligned_string "G "
NoteStr0_FSharp:	aligned_string "F~9e"
NoteStr0_F:	aligned_string "F "
NoteStr0_E:
	aligned_string "E "
NoteStr0_DSharp:	aligned_string "D~9e"
NoteStr0_D:
	aligned_string "D "
NoteStr0_CSharp:	aligned_string "C~9e"
NoteStr0_C:
	aligned_string "C "
NoteStr0_Blank_3:
	aligned_string "  "


NoteNameStr_Table_1:
	.long NoteStr1_Blank_3
	.long NoteStr1_C
	.long NoteStr1_CSharp
	.long NoteStr1_D
	.long NoteStr1_DSharp
	.long NoteStr1_E
	.long NoteStr1_F
	.long NoteStr1_FSharp
	.long NoteStr1_G
	.long NoteStr1_ASharp
	.long NoteStr1_A
	.long NoteStr1_AFlat
	.long NoteStr1_B
	.long NoteStr1_Blank_2
	.long NoteStr1_Blank_1
	.long NoteStr1_Blank_0
NoteStr1_Blank_0:
	aligned_string "  "
NoteStr1_Blank_1:
	aligned_string "  "
NoteStr1_Blank_2:
	aligned_string "  "
NoteStr1_B:
	aligned_string "B "
NoteStr1_AFlat:
	aligned_string "A~9e"
NoteStr1_A:
	aligned_string "A "
NoteStr1_ASharp:	aligned_string "A~a0"
NoteStr1_G:	aligned_string "G "
NoteStr1_FSharp:	aligned_string "F~9e"
NoteStr1_F:
	aligned_string "F "
NoteStr1_E:
	aligned_string "E "
NoteStr1_DSharp:	aligned_string "D~9e"
NoteStr1_D:	aligned_string "D "
NoteStr1_CSharp:	aligned_string "C~9e"
NoteStr1_C:
	aligned_string "C "
NoteStr1_Blank_3:
	aligned_string "  "


NoteNameStr_Table_2:
	.long NoteStr2_Blank_3
	.long NoteStr2_C
	.long NoteStr2_CSharp
	.long NoteStr2_D
	.long NoteStr2_DSharp
	.long NoteStr2_E
	.long NoteStr2_F
	.long NoteStr2_FSharp
	.long NoteStr2_G
	.long NoteStr2_GSharp
	.long NoteStr2_A
	.long NoteStr2_BFlat
	.long NoteStr2_B
	.long NoteStr2_Blank_2
	.long NoteStr2_Blank_1
	.long NoteStr2_Blank_0
NoteStr2_Blank_0:
	aligned_string "  "
NoteStr2_Blank_1:
	aligned_string "  "
NoteStr2_Blank_2:
	aligned_string "  "
NoteStr2_B:
	aligned_string "B "
NoteStr2_BFlat:	aligned_string "B~a0"
NoteStr2_A:	aligned_string "A "
NoteStr2_GSharp:	aligned_string "G~9e"
NoteStr2_G:
	aligned_string "G "
NoteStr2_FSharp:	aligned_string "F~9e"
NoteStr2_F:
	aligned_string "F "
NoteStr2_E:	aligned_string "E "
NoteStr2_DSharp:	aligned_string "D~9e"
NoteStr2_D:
	aligned_string "D "
NoteStr2_CSharp:	aligned_string "C~9e"
NoteStr2_C:
	aligned_string "C "
NoteStr2_Blank_3:
	aligned_string "  "


NoteNameStr_Table_3:
	.long NoteStr3_Blank_3
	.long NoteStr3_C
	.long NoteStr3_CSharp
	.long NoteStr3_D
	.long NoteStr3_EFlat
	.long NoteStr3_E
	.long NoteStr3_F
	.long NoteStr3_FSharp
	.long NoteStr3_G
	.long NoteStr3_GSharp
	.long NoteStr3_A
	.long NoteStr3_AFlat
	.long NoteStr3_B
	.long NoteStr3_Blank_2
	.long NoteStr3_Blank_1
	.long NoteStr3_Blank_0
NoteStr3_Blank_0:
	aligned_string "  "
NoteStr3_Blank_1:
	aligned_string "  "
NoteStr3_Blank_2:
	aligned_string "  "
NoteStr3_B:
	aligned_string "B "
NoteStr3_AFlat:	aligned_string "A~9e"
NoteStr3_A:
	aligned_string "A "
NoteStr3_GSharp:	aligned_string "G~9e"
NoteStr3_G:
	aligned_string "G "
NoteStr3_FSharp:	aligned_string "F~9e"
NoteStr3_F:
	aligned_string "F "
NoteStr3_E:
	aligned_string "E "
NoteStr3_EFlat:	aligned_string "E~a0"
NoteStr3_D:
	aligned_string "D "
NoteStr3_CSharp:	aligned_string "C~9e"
NoteStr3_C:
	aligned_string "C "
NoteStr3_Blank_3:
	.byte 0x20, 0x20, 0x00, 0xff, 0x12, 0x05, 0xed, 0x00
Str_Attention_Multilingual:
	.long Str_Attention_DE
	.long Str_Attention_FR
	.long Str_Attention_ES
	.long Str_Attention_IT
	.long Str_Attention_ID
Str_Attention_ID:	aligned_string "PERHATIAN!"
Str_Attention_IT:	aligned_string "Italian"
Str_Attention_ES:	aligned_string "ATTENCI0N!"
Str_Attention_FR:	aligned_string "ATTENTION!"
Str_Attention_DE:	aligned_string "ACHTUNG!"
Str_Attention_EN:	aligned_string "ATTENTION!"
	.byte 0xe6, 0x06, 0xed, 0x00, 0x7e, 0x06, 0xed, 0x00, 0x18, 0x06, 0xed, 0x00, 0xac, 0x05, 0xed, 0x00
	.byte 0xa4, 0x05, 0xed, 0x00, 0x36, 0x05, 0xed, 0x00
Str_InitSettingWarn_ID:	aligned_string "Menggunakan Initial Setting akan menghapus semua data yang telah diset dengan susunan data asli dari pabrik."
Str_InitSettingWarn_IT:	aligned_string "Italian"
	aligned_string "El uso del ajuste inicial hará que se reemplacen los datos actuales por los ajustes originales de fá brica!"
	aligned_string "La procédure d'initialisation va remplacer tous les réglages effectués par les présélections d'usine"
	.byte 0x44, 0x75
	aligned_string "rch das Initialisieren werden alle aktuellen Einstellungen wieder in den Werkszustand zurückversetzt."
	aligned_string "Using Initial Setting will replace any current data with the original factory settings!"
	.byte 0xa8, 0x07, 0xed, 0x00, 0x96, 0x07, 0xed, 0x00, 0x86, 0x07, 0xed, 0x00, 0x78, 0x07, 0xed, 0x00
	.byte 0x70, 0x07, 0xed, 0x00, 0x56, 0x07, 0xed, 0x00
Str_AreYouSure_ID:	aligned_string "Apakah Anda sudah yakin ?"
Str_AreYouSure_IT:	aligned_string "Italian"
	.byte 0xbf, 0x45, 0x73, 0x74, 0xe1
	aligned_string " seguro?"
	.byte 0x45, 0x74
	.ascii "es vous s"
	.byte 0xfb, 0x72, 0x3f, 0x00, 0xff
	aligned_string "SIND SIE SICHER?"
	aligned_string "Are You Sure?"
	.byte 0x04, 0x0a, 0xed, 0x00, 0x8e, 0x09, 0xed, 0x00
Str_FactoryResetDesc_Multilingual:
	.long Str_FactoryResetDesc_EN3
	.long Str_FactoryResetDesc_EN2
	.long Str_FactoryResetDesc_EN1
	.long Str_FactoryResetDesc_EN0
Str_FactoryResetDesc_EN0:	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN1:	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN2:	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN3:	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
	.byte 0x53, 0x65
	.ascii "tzt die PERFORMANCE Daten, d.h. die von Ihnen erstellten Daten und Einstellungen, auf die Werkseinstellung zurüc"
	.byte 0x6b, 0x2e, 0x00, 0xff
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
	.byte 0x56, 0x0b, 0xed, 0x00
Str_StoreSoundBalance_Multilingual:
	.long Str_StoreSoundBalance_DE
	.long Str_StoreSoundBalance_EN3
	.long Str_StoreSoundBalance_EN2
	.long Str_StoreSoundBalance_EN1
	.long Str_StoreSoundBalance_EN0
Str_StoreSoundBalance_EN0:	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN1:	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN2:	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN3:	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_DE:	.asciz "Speichert nur Klang- und Lautstärkeeinstellungen."
	aligned_string "Stores sound & balance settings only."
	.byte 0xda, 0x0c, 0xed, 0x00
Str_StoreTotalSetting_Multilingual:
	.long Str_StoreTotalSetting_DE
	.long Str_StoreTotalSetting_EN3
	.long Str_StoreTotalSetting_EN2
	.long Str_StoreTotalSetting_EN1
	.long Str_StoreTotalSetting_EN0
Str_StoreTotalSetting_EN0:	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN1:	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN2:	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN3:	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_DE:	.asciz "Speichert die gesamte Einstellung einschließlich Rhythmus, Transpose & Tempo."
	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
	aligned_string "%c:%d/%d  "
	.byte 0xef, 0x02, 0x1d, 0x05, 0xef, 0x02, 0x1d, 0x05, 0x27, 0x08, 0xfd, 0x07, 0xfd, 0x07, 0x20, 0x00
	aligned_string "                                "
	ld w, 0:opc
	.zero 8
	.byte 0xf1, 0x01, 0xf1, 0x01, 0xf1, 0x01, 0x59, 0x00, 0x65, 0x01, 0x59, 0x00, 0x65, 0x01, 0x10, 0x03
	.byte 0xf8, 0x02, 0xf8, 0x02, 0x20, 0x00
	aligned_string "                "
	.byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6a, 0x01, 0x00, 0x00, 0x00, 0x00
	aligned_string "%d/%d"
	.byte 0xcc, 0x01, 0xfa, 0x02, 0xcc, 0x01, 0xfa, 0x02, 0x29, 0x05, 0x11, 0x05, 0x11, 0x05, 0x20, 0x00
	aligned_string "                "
	ld w, 0:opc
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop xiz
	normal
	nop
	nop
	nop
	nop
	ld e, 115:opc
	push xde
	nop
	aligned_string "                 "
	ld w, 32:opc
	ld w, 32:opc
	ld w, 0:opc
	ld e, 115:opc
	push xde
	nop
	aligned_string "TEMPO"
	ld e, 115:opc
	push xde
	nop
	aligned_string "TEMPO"
	.byte 0x25, 0x73, 0x00, 0xff, 0x5a, 0x05, 0x6a, 0x07, 0x5a, 0x05, 0x6a, 0x07, 0xae, 0x0b, 0x96, 0x0b
	.byte 0x96, 0x0b, 0x20, 0x00
	aligned_string "                                "
	ld w, 0:opc
	aligned_string "                                "
	ld w, 0:opc
	aligned_string "                                "
	ld w, 0:opc
	aligned_string "                                "
	aligned_string "                                "
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdb, 0x02, 0xdb, 0x02, 0xdb, 0x02, 0x6a, 0x00
	.byte 0x27, 0x01, 0x6a, 0x00, 0x27, 0x01, 0x34, 0x02, 0x0c, 0x02, 0x0c, 0x02, 0x25, 0x33, 0x64, 0x00
	.byte 0x4f, 0x4e, 0x20, 0x00, 0x4f, 0x46, 0x46, 0x00, 0x25, 0x33, 0x64, 0x00, 0x25, 0x33, 0x64, 0x00
	.byte 0x25, 0x33, 0x64, 0x00, 0x4f, 0x46, 0x46, 0x00, 0x4f, 0x4e, 0x20, 0x00, 0x25, 0x33, 0x64, 0x00
	.byte 0x25, 0x33, 0x64, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x7c, 0x00, 0xf8, 0x02, 0xfe, 0x00
	.byte 0xfe, 0x00, 0x6a, 0x00, 0x0e, 0x01, 0x6a, 0x00, 0x0e, 0x01, 0x02, 0x02, 0xda, 0x01, 0xda, 0x01
	.byte 0x00, 0x90, 0x91, 0xb3, 0xb4, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xb2, 0x88, 0x92
	.byte 0x93, 0x94, 0x95, 0x40, 0x96, 0x99, 0x97, 0x98, 0xad, 0xb0, 0xb1, 0xb8, 0xb9, 0xb6, 0xb7, 0xff
	.byte 0xdc, 0x11, 0xed, 0x00


NoteNameStr_Table_4:
	.long CtrlAssignStr_PMemIncrement
	.long CtrlAssignStr_PMemDecrement
	.long CtrlAssignStr_PMemBankInc
	.long CtrlAssignStr_PMemBankDec
	.long CtrlAssignStr_PanelMemory1
	.long CtrlAssignStr_PanelMemory2
	.long CtrlAssignStr_PanelMemory3
	.long CtrlAssignStr_PanelMemory4
	.long CtrlAssignStr_PanelMemory5
	.long CtrlAssignStr_PanelMemory6
	.long CtrlAssignStr_PanelMemory7
	.long CtrlAssignStr_PanelMemory8
	.long CtrlAssignStr_PMemIncDec
	.long CtrlAssignStr_StartStop
	.long CtrlAssignStr_FillIn1
	.long CtrlAssignStr_FillIn2
	.long CtrlAssignStr_IntroEnding1
	.long CtrlAssignStr_IntroEnding2
	.long CtrlAssignStr_Sustain
	.long CtrlAssignStr_Glide
	.long CtrlAssignStr_TechniChord
	.long CtrlAssignStr_DigitalEffect
	.long CtrlAssignStr_DspEffect
	.long CtrlAssignStr_RotarySlowFast
	.long CtrlAssignStr_PunchRecord
	.long CtrlAssignStr_ApcHold
	.long CtrlAssignStr_FadeIn
	.long CtrlAssignStr_FadeOut
	.long CtrlAssignStr_TotalExpression
	.long CtrlAssignStr_PartExpression
CtrlAssignStr_PartExpression:	aligned_string "PART EXPRESSION "
CtrlAssignStr_TotalExpression:	aligned_string "TOTAL EXPRESSION"
CtrlAssignStr_FadeOut:	aligned_string "    FADE OUT    "
CtrlAssignStr_FadeIn:	aligned_string "    FADE IN     "
CtrlAssignStr_ApcHold:	aligned_string "   APC HOLD     "
CtrlAssignStr_PunchRecord:	aligned_string "  PUNCH RECORD  "
CtrlAssignStr_RotarySlowFast:	aligned_string "ROTARY SLOW/FAST"
CtrlAssignStr_DspEffect:	aligned_string "  DSP EFFECT    "
CtrlAssignStr_DigitalEffect:	aligned_string "DIGITAL EFFECT  "
CtrlAssignStr_TechniChord:	aligned_string " TECHNI-CHORD   "
CtrlAssignStr_Glide:	aligned_string "     GLIDE      "
CtrlAssignStr_Sustain:	aligned_string "    SUSTAIN     "
CtrlAssignStr_IntroEnding2:	aligned_string "INTRO&ENDING 2  "
CtrlAssignStr_IntroEnding1:	aligned_string "INTRO&ENDING 1  "
CtrlAssignStr_FillIn2:	aligned_string "   FILL IN 2    "
CtrlAssignStr_FillIn1:	aligned_string "   FILL IN 1    "
CtrlAssignStr_StartStop:	aligned_string "  START/STOP    "
CtrlAssignStr_PMemIncDec:	aligned_string "P.MEM INC.+DEC. "
CtrlAssignStr_PanelMemory8:	aligned_string "PANEL MEMORY 8  "
CtrlAssignStr_PanelMemory7:	aligned_string "PANEL MEMORY 7  "
CtrlAssignStr_PanelMemory6:	aligned_string "PANEL MEMORY 6  "
CtrlAssignStr_PanelMemory5:	aligned_string "PANEL MEMORY 5  "
CtrlAssignStr_PanelMemory4:	aligned_string "PANEL MEMORY 4  "
CtrlAssignStr_PanelMemory3:	aligned_string "PANEL MEMORY 3  "
CtrlAssignStr_PanelMemory2:	aligned_string "PANEL MEMORY 2  "
CtrlAssignStr_PanelMemory1:	aligned_string "PANEL MEMORY 1  "
CtrlAssignStr_PMemBankDec:	aligned_string "P.MEM BANK DEC. "
CtrlAssignStr_PMemBankInc:	aligned_string "P.MEM BANK INC. "
CtrlAssignStr_PMemDecrement:	aligned_string "P.MEM DECREMENT "
CtrlAssignStr_PMemIncrement:	aligned_string "P.MEM INCREMENT "
CtrlAssignStr_Off:	aligned_string "      OFF       "
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED11EE-0xED1226 (56 B), unreached CODE-territory, was disassembled as 42 plausible-but-dead instruction lines; per=100% dist=4 near CtrlAssignStr_Off+18
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x00, 0x00, 0x2f, 0x02, 0x00, 0x00, 0x2f, 0x02
	.byte 0xea, 0x08, 0x5b, 0x04, 0x5b, 0x04, 0x06, 0x00, 0x00, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00
	.byte 0x06, 0x00
ParamStr_Table_01:
	.long ParamStr01_RhythmSelection
	.long ParamStr01_Tempo
	.long ParamStr01_ApcMemory
	.long ParamStr01_SplitPoint
	.long ParamStr01_Transpose
	.long ParamStr01_FootContSetting
	.long ParamStr01_MicLevelReverb
	.long ParamStr01_FadeInOutSetting
	.long ParamStr01_R1R2Octave
ParamStr01_R1R2Octave:	aligned_string "   R1/R2 OCTAVE    "
ParamStr01_FadeInOutSetting:	aligned_string "FADE IN/OUT SETTING"
ParamStr01_MicLevelReverb:	aligned_string "MIC LEVEL & REVERB "
ParamStr01_FootContSetting:	aligned_string "FOOT CONT. SETTING "
ParamStr01_Transpose:	aligned_string "     TRANSPOSE     "
ParamStr01_SplitPoint:	aligned_string "    SPLIT POINT    "
ParamStr01_ApcMemory:	aligned_string "   APC & MEMORY    "
ParamStr01_Tempo:	aligned_string "       TEMPO       "
ParamStr01_RhythmSelection:	aligned_string " RHYTHM SELECTION  "
ParamStr_Table_02:
	.long ParamStr02_Vocalist
	.long ParamStr02_Midi
	.long ParamStr02_Reverb
	.long ParamStr02_DspEffect
	.long ParamStr02_AcousticIllusion
	.long ParamStr02_Equalizer
	.long ParamStr02_Part4_16Setting
	.long ParamStr02_KeyScale
	.long ParamStr02_MspBank
ParamStr02_MspBank:	aligned_string "     MSP BANK      "
ParamStr02_KeyScale:	aligned_string "     KEY SCALE     "
ParamStr02_Part4_16Setting:	aligned_string " PART4-16 SETTING  "
ParamStr02_Equalizer:	aligned_string "     EQUALIZER     "
ParamStr02_AcousticIllusion:	aligned_string " ACOUSTIC ILLUSION "
ParamStr02_DspEffect:	aligned_string "    DSP EFFECT     "
ParamStr02_Reverb:	aligned_string "      REVERB       "
ParamStr02_Midi:	aligned_string "       MIDI        "
ParamStr02_Vocalist:	aligned_string "     VOCALIST      "
	aligned_string "FILTER TYPE"
	.byte 0x4f, 0x4e, 0x2f, 0x4f, 0x46, 0x46, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	aligned_string "PAGE 2/3"
	.byte 0x25, 0x73, 0x00, 0xff
	aligned_string "PAGE 3/3"
	.byte 0xbe, 0x02, 0xa7, 0x03, 0xbe, 0x02, 0xa7, 0x03, 0x4e, 0x05, 0xc8, 0x04, 0xc8, 0x04, 0x00, 0x29
	.byte 0x00, 0x00, 0x01, 0x29, 0x00, 0x00, 0x04, 0x29, 0x00, 0x00, 0x02, 0x29, 0x00, 0x00, 0x03, 0x29
	.byte 0x00, 0x00, 0x0a, 0x29, 0x00, 0x00, 0x0b, 0x29, 0x00, 0x00, 0x0c, 0x29, 0x00, 0x00, 0x0d, 0x29
	.byte 0x00, 0x00, 0x0e, 0x29, 0x00, 0x00, 0x05, 0x29, 0x00, 0x00, 0x07, 0x29, 0x00, 0x00, 0x08, 0x29
	.byte 0x00, 0x00, 0x0f, 0x29, 0x00, 0x00, 0x10, 0x29, 0x00, 0x00, 0x09, 0x29, 0x00, 0x00, 0x06, 0x29
	.byte 0x00, 0x00, 0x11, 0x29, 0x00, 0x00, 0x4f, 0x46, 0x46, 0x00, 0x4f, 0x4e, 0x20, 0x00, 0x4f, 0x46
	.byte 0x46, 0x00, 0x4f, 0x4e, 0x20, 0x00, 0x4f, 0x4e, 0x20, 0x00, 0x4f, 0x46, 0x46, 0x00, 0x4f, 0x4e
	.byte 0x20, 0x00, 0x4f, 0x46, 0x46, 0x00, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00
	.byte 0x7c, 0x00, 0x97, 0x02, 0xfa, 0x00, 0xfa, 0x00, 0xd5, 0x00, 0x79, 0x01, 0xd5, 0x00, 0x79, 0x01
	.byte 0x6d, 0x02, 0x45, 0x02, 0x45, 0x02
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1437-0xED1452 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=8 near ParamStr02_Vocalist_0x52+9
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1453-0xED146E (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=8 near ParamStr02_Vocalist_0x76+1
ParamStr_Table_03:
	.long FadeTimeStr_Off
	.long FadeTimeStr_Default
	.long FadeTimeStr_Hold
	.long FadeTimeStr_1sec
	.long FadeTimeStr_2sec
	.long FadeTimeStr_3sec
	.long FadeTimeStr_4sec
	.long FadeTimeStr_5sec
	.long FadeTimeStr_6sec
	.long FadeTimeStr_7sec
	.long FadeTimeStr_8sec
	.long FadeTimeStr_9sec
	.long FadeTimeStr_10sec
FadeTimeStr_10sec:	aligned_string "10 sec "
FadeTimeStr_9sec:	aligned_string " 9 sec "
FadeTimeStr_8sec:	aligned_string " 8 sec "
FadeTimeStr_7sec:	aligned_string " 7 sec "
FadeTimeStr_6sec:	aligned_string " 6 sec "
FadeTimeStr_5sec:	aligned_string " 5 sec "
FadeTimeStr_4sec:	aligned_string " 4 sec "
FadeTimeStr_3sec:	aligned_string " 3 sec "
FadeTimeStr_2sec:	aligned_string " 2 sec "
FadeTimeStr_1sec:	aligned_string " 1 sec "
FadeTimeStr_Hold:	aligned_string " HOLD  "
FadeTimeStr_Default:	aligned_string "DEFAULT"
FadeTimeStr_Off:	aligned_string "  OFF  "
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1552-0xED1582 (48 B), unreached CODE-territory, was disassembled as 36 plausible-but-dead instruction lines; per=100% dist=4 near FadeTimeStr_Off+8
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff, 0x25, 0x73, 0x00, 0xff
	.byte 0x00, 0x00, 0x36, 0x01, 0x00, 0x00, 0x36, 0x01, 0xbc, 0x05, 0x83, 0x02, 0x83, 0x02
	aligned_string "PAGE"
	aligned_string "Memory data "
	.byte 0x20, 0x20, 0x00, 0xff, 0x20, 0x20, 0x00, 0xff, 0xa4, 0x00, 0xa4, 0x00, 0xb9, 0x00, 0xb9, 0x00
	.byte 0xb9, 0x00, 0xa8, 0x00, 0xa4, 0x00, 0xaf, 0x00, 0xb5, 0x00, 0x00, 0x00
	aligned_string "        "
	aligned_string "%d-%d:"
	.byte 0x25, 0x64, 0x3a, 0x00
	aligned_string "PAGE 1/3"
	aligned_string "BANK%2d:"
	.byte 0x25, 0x64, 0x3a, 0x00, 0x01, 0x00, 0x01, 0x00, 0x0a, 0x00, 0x0a, 0x00, 0x0a, 0x00, 0x04, 0x00
	.byte 0x0a, 0x00, 0x0d, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0xff, 0x53, 0x4f, 0x55, 0x4e, 0x44, 0x00
	.byte 0x25, 0x64, 0x3a, 0x00, 0x25, 0x64, 0x3a, 0x00
	aligned_string "PAGE %d/%d"
	.byte 0x25, 0x64, 0x3a, 0x00, 0x25, 0x64, 0x3a, 0x00
ParamStr_Table_04:
	.long VariationStr_V1
	.long VariationStr_V2
	.long VariationStr_V3
	.long VariationStr_V4
VariationStr_V4:
	.byte 0x56, 0x34, 0x00, 0xff
VariationStr_V3:
	.byte 0x56, 0x33, 0x00, 0xff
VariationStr_V2:
	.byte 0x56, 0x32, 0x00, 0xff
VariationStr_V1:
	.byte 0x56, 0x31, 0x00, 0xff
	aligned_string "RHYTHM"
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED164E-0xED1662 (20 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=5 near VariationStr_V1_0x4+8
	ld e, 115:opc
	push xde
	nop
	ld e, 115:opc
	push xde
	nop
	ld e, 100:opc
	push xde
	nop
	ld e, 100:opc
	push xde
	nop
	ld e, 115:opc
	push xde
	nop
	aligned_string "PAGE %d/%d"
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED166E-0xED167E (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=5 near VariationStr_V1_0x4+40
	.byte 0x25, 0x64, 0x3a, 0x00, 0x25, 0x73, 0x3a, 0x00, 0x25, 0x64, 0x3a, 0x00, 0x25, 0x64, 0x3a, 0x00
	.byte 0x02, 0x00, 0x3e, 0x00, 0x2e, 0x01, 0x5d, 0x00, 0x02, 0x00, 0x62, 0x00, 0x3c, 0x01, 0x81, 0x00
	.byte 0x02, 0x00
	.long NakaInst_Param_EmptyStr
	.byte 0x99, 0x00, 0x02, 0x00
	.long NakaData_DescriptorPad_ZeroA
	.byte 0xad, 0x00, 0x02, 0x00, 0xae, 0x00, 0x06, 0x01, 0xc1, 0x00, 0x02, 0x00, 0xc2, 0x00, 0x16, 0x01
	.byte 0xd5, 0x00
ParamStr_Table_05:
	.long TransposeNoteStr_C
	.long TransposeNoteStr_DFlat
	.long TransposeNoteStr_D
	.long TransposeNoteStr_EFlat
	.long TransposeNoteStr_E
	.long TransposeNoteStr_F
	.long TransposeNoteStr_FSharp
	.long TransposeNoteStr_G
	.long TransposeNoteStr_AFlat
	.long TransposeNoteStr_A
	.long TransposeNoteStr_BFlat
	.long TransposeNoteStr_B
TransposeNoteStr_B:
	aligned_string "B "
TransposeNoteStr_BFlat:	aligned_string "B~a0"
TransposeNoteStr_A:
	aligned_string "A "
TransposeNoteStr_AFlat:	aligned_string "A~a0"
TransposeNoteStr_G:
	aligned_string "G "
TransposeNoteStr_FSharp:	aligned_string "F~9e"
TransposeNoteStr_F:
	aligned_string "F "
TransposeNoteStr_E:
	aligned_string "E "
TransposeNoteStr_EFlat:	aligned_string "E~a0"
TransposeNoteStr_D:
	aligned_string "D "
TransposeNoteStr_DFlat:	aligned_string "D~a0"
TransposeNoteStr_C:
	aligned_string "C "
	aligned_string "(%s%2d, %3d)"
	aligned_string "CHECK BY SINE WAVE"
	aligned_string "Select the mode by sound button of highest line."
	aligned_string "CHECK MODE:"
	aligned_string "KEY DOWN INFORMATION ="
	aligned_string "(1)SINE WAVE & ROM check(w/o TOUCH)"
	aligned_string "C-key=IC304&305,C#~7eB-key=IC306&307"
	aligned_string "(2)GENERATOR LSI OUTSEL check"
	aligned_string "C-key=DIRECT+REV/DSP,C#~7eB-key=REV/DSP"
	aligned_string "(3)HIGH SOUND check(+2octave)"
	aligned_string "(4)LOW SOUND check(-2octave)"
	aligned_string "(5)NORMAL SOUND check with TOUCH"
	aligned_string "(6)SINE WAVE & ROM check 16dB DOWN"
	.byte 0x00, 0x00, 0x56, 0x00, 0xae, 0x00, 0xdd, 0x00, 0x0b, 0x01, 0x39, 0x01
	aligned_string "DEFAULT"
	aligned_string " USER  "
	aligned_string " ERROR "
	.byte 0x9c, 0x00, 0x9c, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x9c, 0x00, 0x60, 0x00, 0xa0, 0x00
	.byte 0xa7, 0x00, 0x64, 0x00
	aligned_string "DEFAULT"
	aligned_string " USER  "
	aligned_string " ERROR "
	ldw bc, 12544
	nop
	ld xwa, 1073758208
	nop
	ldw bc, 16384
	nop
	ldw iy, 15360
	nop
	nop
	nop
	aligned_string "DEFAULT"
	aligned_string " USER  "
	aligned_string " ERROR "
	.byte 0x31, 0x00, 0x31, 0x00, 0x40, 0x00, 0x40, 0x00, 0x40, 0x00, 0x31, 0x00, 0x40, 0x00, 0x35, 0x00
	.byte 0x3c, 0x00, 0x00, 0x00, 0xca, 0x1a, 0xed, 0x00, 0x7a, 0x1a, 0xed, 0x00, 0x36, 0x1a, 0xed, 0x00
	.byte 0xd8, 0x19, 0xed, 0x00, 0xd0, 0x19, 0xed, 0x00, 0x4a, 0x19, 0xed, 0x00
	aligned_string "USER INITIAL akan menggantikan penggunaan kertas tempel (stiker) yang sekarang dengan sticker/kertas tempel yg hitam-licin dan rata!"
	aligned_string "Italian"
	.byte 0xa1
	.ascii "El USER INITIAL cambiará el patrÓn de fondo actual por un \"Plain Black\" (negro sin dise"
	.byte 0xf1, 0x6f, 0x29, 0x21, 0x00, 0xff, 0x55, 0x53
	aligned_string "ER INITIAL va remplacer votre fond de l'écran par un fond noir !"
	aligned_string "USER INITIAL ersetzt das aktuelle Hintergrundbild durch eine schwarze Fläche !"
	.asciz "USER INITIAL will replace the current user wallpaper with the \"Plain Black\" wallpaper!"
	.byte 0xff, 0x00, 0x00, 0x26, 0x00, 0x2c, 0x00, 0x32, 0x00, 0x1a, 0x00, 0x08, 0x00, 0x0e, 0x00, 0x20
	.byte 0x00, 0x14, 0x00, 0x00, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00


ParamStr_Table_06:
	.long SplitNoteStr_C
	.long SplitNoteStr_DFlat
	.long SplitNoteStr_D
	.long SplitNoteStr_EFlat
	.long SplitNoteStr_E
	.long SplitNoteStr_F
	.long SplitNoteStr_FSharp
	.long SplitNoteStr_G
	.long SplitNoteStr_AFlat
	.long SplitNoteStr_A
	.long SplitNoteStr_BFlat
	.long SplitNoteStr_B
SplitNoteStr_B:
	aligned_string "B "
SplitNoteStr_BFlat:	aligned_string "B~a0"
SplitNoteStr_A:
	aligned_string "A "
SplitNoteStr_AFlat:	aligned_string "A~a0"
SplitNoteStr_G:
	aligned_string "G "
SplitNoteStr_FSharp:	aligned_string "F~9e"
SplitNoteStr_F:	aligned_string "F "
SplitNoteStr_E:
	aligned_string "E "
SplitNoteStr_EFlat:	aligned_string "E~a0"
SplitNoteStr_D:
	aligned_string "D "
SplitNoteStr_DFlat:	aligned_string "D~a0"
; -----------------------------------------------------------------------------
; ** RE-FRAMED 2026-08-30 (lane B4): this was CODE territory and it is DATA.
; The tree read the pointer table below ONE BYTE LATE, from 0xED1BAB, which
; turned each 4-byte pointer into a `jp` whose high byte was the LOW byte of
; the NEXT entry -- so the phantom entry points marched downward in steps of
; exactly 0x020000. An arithmetic progression of entry points 128 KiB apart is
; not a jump table.
;
; It is a table because:
;   * all 11 entries land on the 2-byte NUL-terminated digit cells right below
;     it, and the last entry (0x00ED1BD6) is exactly the first byte past the
;     table's own end (0xED1BAA + 11*4);
;   * display/graphics_text_vga.s indexes THIS address -- `divs hl, 0xc` then
;     `sla hl, 2` then `lda_24 xbc, (SplitNoteStr_C_0x4)` at 0xFC2DE2 and
;     0xFC2E67. Note number / 12, scaled by 4 = the pointer width.
; The five phantom `jp` operands (NakaData_PartConfig,
; Bitmap_SplitPoint_Gb_0x2B, Bitmap_Dredt0d_0xA8D, SepaOut_FormatData_Tail,
; FILETYPE_SIG_TABLE_2_0x15) were REFERENCES to labels defined elsewhere, not
; definitions here; nothing lost a name.
; -----------------------------------------------------------------------------
SplitNoteStr_C:	aligned_string "C "
	; 0xED1BAA = SplitNoteStr_C_0x4: octave-digit pointers, index = note / 12
	.long OctaveDigitStr_0B
	.long OctaveDigitStr_0C
	.long OctaveDigitStr_0A
	.long OctaveDigitStr_1
	.long OctaveDigitStr_2
	.long OctaveDigitStr_3
	.long OctaveDigitStr_4
	.long OctaveDigitStr_5
	.long OctaveDigitStr_6
	.long OctaveDigitStr_7
	.long OctaveDigitStr_8
	; the cells themselves, 2 bytes each, in DESCENDING digit order
OctaveDigitStr_8:	.asciz "8"
OctaveDigitStr_7:	.asciz "7"
OctaveDigitStr_6:	.asciz "6"
OctaveDigitStr_5:	.asciz "5"
OctaveDigitStr_4:	.asciz "4"
OctaveDigitStr_3:	.asciz "3"
OctaveDigitStr_2:	.asciz "2"
OctaveDigitStr_1:	.asciz "1"
OctaveDigitStr_0A:	.asciz "0"
; ** 0xED1BE8 only became visible when the table above stopped being framed as
; code, so it could not be called _0B: that name (0xED1BEA) is already in use
; and is aliased by positional_labels.s. Hence A, C, B in address order.
OctaveDigitStr_0C:	.asciz "0"
OctaveDigitStr_0B:	.asciz "0"
	aligned_string "          "
	aligned_string "SPLIT<%s%s>"
	aligned_string "          "
	aligned_string "SPLIT<%s%s>"
	.long KeyScaleNoteStr_G
ParamStr_Table_07:
	.long KeyScaleNoteStr_AFlat
	.long KeyScaleNoteStr_A
	.long KeyScaleNoteStr_BFlat
	.long KeyScaleNoteStr_B
	.long KeyScaleNoteStr_C
	.long KeyScaleNoteStr_DFlat
	.long KeyScaleNoteStr_D
	.long KeyScaleNoteStr_EFlat
	.long KeyScaleNoteStr_E
	.long KeyScaleNoteStr_F
	.long KeyScaleNoteStr_FSharp
KeyScaleNoteStr_FSharp:	aligned_string "F~9e"
KeyScaleNoteStr_F:
	aligned_string "F "
KeyScaleNoteStr_E:	aligned_string "E "
KeyScaleNoteStr_EFlat:	aligned_string "E~a0"
KeyScaleNoteStr_D:
	aligned_string "D "
KeyScaleNoteStr_DFlat:	aligned_string "D~a0"
KeyScaleNoteStr_C:
	aligned_string "C "
KeyScaleNoteStr_B:	aligned_string "B "
KeyScaleNoteStr_BFlat:	aligned_string "B~a0"
KeyScaleNoteStr_A:
	aligned_string "A "
KeyScaleNoteStr_AFlat:	aligned_string "A~a0"
KeyScaleNoteStr_G:	.byte 0x47, 0x20, 0x00, 0xff, 0x20, 0x20, 0x20, 0x20, 0x00, 0xff
	aligned_string "<%s>"
	.byte 0x25, 0x73, 0x00, 0xff, 0x6f, 0x6e, 0x00, 0xff, 0x20, 0x20, 0x00, 0xff, 0xc3, 0xe0, 0xfb, 0x00
	.byte 0x35, 0xd2, 0xfb, 0x00, 0x31, 0xd1, 0xfb, 0x00, 0xfb, 0xd2, 0xfb, 0x00, 0x48, 0x7f, 0xfb, 0x00
	.byte 0x8c, 0x7f, 0xfb, 0x00, 0xa2, 0x7f, 0xfb, 0x00, 0xb8, 0x7f, 0xfb, 0x00, 0xbb, 0x7f, 0xfb, 0x00
	.byte 0xcc, 0x7f, 0xfb, 0x00, 0xdd, 0x7f, 0xfb, 0x00, 0x61, 0xaa, 0xfb, 0x00, 0x0f, 0xb0, 0xfb, 0x00
	.byte 0x37, 0xc1, 0xfb, 0x00, 0xfa, 0xc6, 0xfb, 0x00, 0x25, 0x80, 0xfb, 0x00, 0xd5, 0x88, 0xfb, 0x00
	.byte 0x8f, 0x8e, 0xfb, 0x00, 0xec, 0x95, 0xfb, 0x00, 0xc1, 0xa3, 0xfb, 0x00, 0xe5, 0xa6, 0xfb, 0x00
	.byte 0xec, 0xa6, 0xfb, 0x00, 0x4a, 0x7e, 0xfb, 0x00, 0x77, 0x7e, 0xfb, 0x00, 0xa4, 0x7e, 0xfb, 0x00
	.byte 0xd1, 0x7e, 0xfb, 0x00, 0x01, 0xe1, 0xfb, 0x00, 0xf8, 0xcc, 0xfb, 0x00, 0xfe, 0x7e, 0xfb, 0x00
	.byte 0x45, 0x24, 0xfc, 0x00, 0x37, 0x25, 0xfc, 0x00, 0xb2, 0x25, 0xfc, 0x00, 0x2d, 0x26, 0xfc, 0x00
	.byte 0x07, 0x27, 0xfc, 0x00, 0x43, 0x27, 0xfc, 0x00, 0x59, 0x27, 0xfc, 0x00, 0x6d, 0x27, 0xfc, 0x00
	.byte 0x6a, 0x27, 0xfc, 0x00, 0x32, 0x27, 0xfc, 0x00, 0xee, 0x7f, 0xfb, 0x00, 0xff, 0x7f, 0xfb, 0x00
	.byte 0x10, 0x80, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1D1B-0xED1D3A (31 B), unreached CODE-territory, was disassembled as 19 plausible-but-dead instruction lines; per=70% dist=12 near KeyScaleNoteStr_G_0x18+129
NoteNameStr_Table_5:
	.long FuncNameStr_PmBkNameFunc
	.long FuncNameStr_PmBankNamingCheck
	.long FuncNameStr_PmNamingCheck
	.long FuncNameStr_MssNameFunc
	.long FuncNameStr_SystemInitOkFunc
	.long FuncNameStr_SysIniNoFunc
	.long FuncNameStr_SysIniYesFunc
	.long FuncNameStr_SysSureShowHideFunc
	.long FuncNameStr_AttnLngCheck
	.long FuncNameStr_SysSureLngCheck
	.long FuncNameStr_SureLngCheck
	.long FuncNameStr_TchSensGridCheck
	.long FuncNameStr_FSWAssGridCheck
	.long FuncNameStr_PmExpFilterGridCheck
	.long FuncNameStr_DispTimeSetGridCheck
	.long FuncNameStr_MstSugAlpGridCheck
	.long FuncNameStr_MstStyleAlpGridCheck
	.long FuncNameStr_MstStyle1GridCheck
	.long FuncNameStr_MstStyle1SubGridCheck
	.long FuncNameStr_MstStyle2GridCheck
	.long FuncNameStr_MstSong1GridCheck
	.long FuncNameStr_MstSong2GridCheck
	.long FuncNameStr_BitmapFinpic
	.long FuncNameStr_BitmapFinst
	.long FuncNameStr_BitmapFoutpic
	.long FuncNameStr_BitmapFoutst
	.long FuncNameStr_GmOnOffFunc
	.long FuncNameStr_DispTimeSetOKFunc
	.long FuncNameStr_SystemInitMDFunc
	.long FuncNameStr_WallHomeEditCheck
	.long FuncNameStr_WallMenuEditCheck
	.long FuncNameStr_WallOthEditCheck
	.long FuncNameStr_WallSetOKFunc
	.long FuncNameStr_WallUsrIniFunc
	.long FuncNameStr_WallUsrIniNoFunc
	.long FuncNameStr_WallUsrIniYesFunc
	.long FuncNameStr_WallUsrShowHideFunc
	.long FuncNameStr_WallSureShowHideFunc
	.long FuncNameStr_WallSureLngCheck
	.long FuncNameStr_CtlIniLngCheck
	.long FuncNameStr_PmemNormLngCheck
	.long FuncNameStr_PmemExpLngCheck
	.long FuncNameStr_NullTerm
FuncNameStr_NullTerm:
	aligned_string ""
FuncNameStr_PmemExpLngCheck:	aligned_string "PmemExpLngCheck"
FuncNameStr_PmemNormLngCheck:	aligned_string "PmemNormLngCheck"
FuncNameStr_CtlIniLngCheck:	aligned_string "CtlIniLngCheck"
FuncNameStr_WallSureLngCheck:	aligned_string "WallSureLngCheck"
FuncNameStr_WallSureShowHideFunc:	aligned_string "WallSureShowHideFunc"
FuncNameStr_WallUsrShowHideFunc:	aligned_string "WallUsrShowHideFunc"
FuncNameStr_WallUsrIniYesFunc:	aligned_string "WallUsrIniYesFunc"
FuncNameStr_WallUsrIniNoFunc:	aligned_string "WallUsrIniNoFunc"
FuncNameStr_WallUsrIniFunc:	aligned_string "WallUsrIniFunc"
FuncNameStr_WallSetOKFunc:	aligned_string "WallSetOKFunc"
FuncNameStr_WallOthEditCheck:	aligned_string "WallOthEditCheck"
FuncNameStr_WallMenuEditCheck:	aligned_string "WallMenuEditCheck"
FuncNameStr_WallHomeEditCheck:	aligned_string "WallHomeEditCheck"
FuncNameStr_SystemInitMDFunc:	aligned_string "SystemInitMDFunc"
FuncNameStr_DispTimeSetOKFunc:	aligned_string "DispTimeSetOKFunc"
FuncNameStr_GmOnOffFunc:	aligned_string "GmOnOffFunc"
FuncNameStr_BitmapFoutst:	aligned_string "BitmapFoutst"
FuncNameStr_BitmapFoutpic:	aligned_string "BitmapFoutpic"
FuncNameStr_BitmapFinst:	aligned_string "BitmapFinst"
FuncNameStr_BitmapFinpic:	aligned_string "BitmapFinpic"
FuncNameStr_MstSong2GridCheck:	aligned_string "MstSong2GridCheck"
FuncNameStr_MstSong1GridCheck:	aligned_string "MstSong1GridCheck"
FuncNameStr_MstStyle2GridCheck:	aligned_string "MstStyle2GridCheck"
FuncNameStr_MstStyle1SubGridCheck:	aligned_string "MstStyle1SubGridCheck"
FuncNameStr_MstStyle1GridCheck:	aligned_string "MstStyle1GridCheck"
FuncNameStr_MstStyleAlpGridCheck:	aligned_string "MstStyleAlpGridCheck"
FuncNameStr_MstSugAlpGridCheck:	aligned_string "MstSugAlpGridCheck"
FuncNameStr_DispTimeSetGridCheck:	aligned_string "DispTimeSetGridCheck"
FuncNameStr_PmExpFilterGridCheck:	aligned_string "PmExpFilterGridCheck"
FuncNameStr_FSWAssGridCheck:	aligned_string "FSWAssGridCheck"
FuncNameStr_TchSensGridCheck:	aligned_string "TchSensGridCheck"
FuncNameStr_SureLngCheck:	aligned_string "SureLngCheck"
FuncNameStr_SysSureLngCheck:	aligned_string "SysSureLngCheck"
FuncNameStr_AttnLngCheck:	aligned_string "AttnLngCheck"
FuncNameStr_SysSureShowHideFunc:	aligned_string "SysSureShowHideFunc"
FuncNameStr_SysIniYesFunc:	aligned_string "SysIniYesFunc"
FuncNameStr_SysIniNoFunc:	aligned_string "SysIniNoFunc"
FuncNameStr_SystemInitOkFunc:	aligned_string "SystemInitOkFunc"
FuncNameStr_MssNameFunc:	aligned_string "MssNameFunc"
FuncNameStr_PmNamingCheck:	aligned_string "PmNamingCheck"
FuncNameStr_PmBankNamingCheck:	aligned_string "PmBankNamingCheck"
FuncNameStr_PmBkNameFunc:	aligned_string "PmBkNameFunc"
NakaParam_VariScreen:
	.long NakaParam_VariScreen_Empty
NakaParam_VariScreen_Empty:	aligned_string ""
NakaParam_RVariScreen:
	.byte 0x32, 0x21, 0xed, 0x00
ParamStr_Table_08:
	.long ParamStr08_func
	.long ParamStr08_font
	.long ParamStr08_fontcolor
	.long ParamStr08_page
	.long ParamStr08_varisupart
	.long ParamStr08_nowswno
	.long ParamStr08_nowvari
	.long ParamStr08_oldvari
	.long ParamStr08_Empty
ParamStr08_Empty:	aligned_string ""
ParamStr08_oldvari:	aligned_string "oldvari"
ParamStr08_nowvari:	aligned_string "nowvari"
ParamStr08_nowswno:
	aligned_string "nowswno"
	aligned_string "varisu"
	aligned_string "part"
	aligned_string "page"
	aligned_string "fontcolor"
	aligned_string "font"
	aligned_string "func"


ParamStr_Table_09:
	.long ParamStr09_func
	.long ParamStr09_font
	.long ParamStr09_fontcolor
	.long ParamStr09_page
	.long ParamStr09_part
	.long ParamStr09_varisu
	.long ParamStr09_nowswno
	.long ParamStr09_nowvari
	.long ParamStr09_oldvari
	.long ParamStr09_Empty
ParamStr09_Empty:	aligned_string ""
ParamStr09_oldvari:	aligned_string "oldvari"
ParamStr09_nowvari:	aligned_string "nowvari"
ParamStr09_nowswno:	aligned_string "nowswno"
ParamStr09_varisu:	aligned_string "varisu"
ParamStr09_part:	aligned_string "part"
ParamStr09_page:	aligned_string "page"
ParamStr09_fontcolor:	aligned_string "fontcolor"
ParamStr09_font:	aligned_string "font"
ParamStr09_func:	aligned_string "func"
NakaParam_AcChordBox:
	.long NakaParam_AcChordBox_Empty
NakaParam_AcChordBox_Empty:	aligned_string ""
NakaParam_AcFreeSplitBox:
	.long NakaParam_AcFreeSplitBox_Empty
NakaParam_AcFreeSplitBox_Empty:	aligned_string ""
NakaParam_AcBkNoBox:
	.long NakaParam_AcBkNoBox_Empty
NakaParam_AcBkNoBox_Empty:	aligned_string ""
NakaParam_AcPmBkNoBox:
	.long NakaParam_AcPmBkNoBox_Empty
NakaParam_AcPmBkNoBox_Empty:	aligned_string ""
NakaParam_PmBankScreen:
	.long NakaParam_PmBankScreen_Empty
NakaParam_PmBankScreen_Empty:	aligned_string ""
ParamStr_Table_10:
	.long ParamStr10_func
	.long ParamStr10_font
	.long ParamStr10_fontcolor
	.long ParamStr10_page
	.long ParamStr10_nowbank
	.long ParamStr10_oldbank
	.long ParamStr10_Empty
ParamStr10_Empty:	aligned_string ""
ParamStr10_oldbank:	aligned_string "oldbank"
ParamStr10_nowbank:	aligned_string "nowbank"
ParamStr10_page:	aligned_string "page"
ParamStr10_fontcolor:	aligned_string "fontcolor"
ParamStr10_font:	aligned_string "font"
ParamStr10_func:	aligned_string "func"
ParamStr_Table_11:
	.long ParamStr11_func
	.long ParamStr11_data
	.long ParamStr11_Empty
ParamStr11_Empty:	aligned_string ""
ParamStr11_data:	aligned_string "data"
ParamStr11_func:	aligned_string "func"
ParamStr_Table_12:
	.long ParamStr12_func
	.long ParamStr12_font
	.long ParamStr12_fontcolor
	.long ParamStr12_newmsamode
	.long ParamStr12_oldmsamode
	.long ParamStr12_Empty
ParamStr12_Empty:	aligned_string ""
ParamStr12_oldmsamode:	aligned_string "oldmsamode"
ParamStr12_newmsamode:	aligned_string "newmsamode"
ParamStr12_fontcolor:	aligned_string "fontcolor"
ParamStr12_font:	aligned_string "font"
ParamStr12_func:	aligned_string "func"


ParamStr_Table_13:
	.long ParamStr13_func
	.long ParamStr13_font
	.long ParamStr13_fontcolo
	.long ParamStr13_newpmemmode
	.long ParamStr13_oldpmemmode
	.long ParamStr13_Empty
ParamStr13_Empty:	aligned_string ""
ParamStr13_oldpmemmode:	aligned_string "oldpmemmode"
ParamStr13_newpmemmode:	aligned_string "newpmemmode"
ParamStr13_fontcolo:	aligned_string "fontcolo"
ParamStr13_font:	aligned_string "font"
ParamStr13_func:	aligned_string "func"
NakaParam_IvPmemWindowPageCtl:
	.long NakaParam_IvPmemWinPg_page
	.long NakaParam_IvPmemWinPg_Empty
NakaParam_IvPmemWinPg_Empty:	aligned_string ""
NakaParam_IvPmemWinPg_page:	aligned_string "page"
NakaParam_IvMstStyleWindowPgCtl:
	.long NakaParam_IvMstStyleWinPg_page
	.long NakaParam_IvMstStyleWinPg_Empty
NakaParam_IvMstStyleWinPg_Empty:	aligned_string ""
NakaParam_IvMstStyleWinPg_page:	aligned_string "page"
NakaParam_AcTchSensGridBox:
	.long NakaParam_AcTchSens_page
	.long NakaParam_AcTchSens_Empty
NakaParam_AcTchSens_Empty:	aligned_string ""
NakaParam_AcTchSens_page:	aligned_string "page"
ParamStr_Table_14:
	.long ParamStr14_fixedcol
	.long ParamStr14_fixedrow
	.long ParamStr14_func
	.long ParamStr14_Empty
ParamStr14_Empty:	aligned_string ""
ParamStr14_func:	aligned_string "func"
ParamStr14_fixedrow:	aligned_string "fixedrow"
ParamStr14_fixedcol:	aligned_string "fixedcol"


ParamStr_Table_15:
	.long ParamStr15_fixedcol
	.long ParamStr15_fixedrow
	.long ParamStr15_func
	.long ParamStr15_Empty
ParamStr15_Empty:	aligned_string ""
ParamStr15_func:	aligned_string "func"
ParamStr15_fixedrow:	aligned_string "fixedrow"
ParamStr15_fixedcol:	aligned_string "fixedcol"


ParamStr_Table_16:
	.long ParamStr16_fixedcol
	.long ParamStr16_fixedrow
	.long ParamStr16_func
	.long ParamStr16_Empty
ParamStr16_Empty:	aligned_string ""
ParamStr16_func:	aligned_string "func"
ParamStr16_fixedrow:	aligned_string "fixedrow"
ParamStr16_fixedcol:	aligned_string "fixedcol"


ParamStr_Table_17:
	.long ParamStr17_fixedcol
	.long ParamStr17_fixedrow
	.long ParamStr17_func
	.long ParamStr17_Empty
ParamStr17_Empty:	aligned_string ""
ParamStr17_func:	aligned_string "func"
ParamStr17_fixedrow:	aligned_string "fixedrow"
ParamStr17_fixedcol:	aligned_string "fixedcol"
NakaParam_AcMstStyleAlpGridBox:
	.byte 0x2e, 0x24, 0xed, 0x00, 0x24, 0x24, 0xed, 0x00, 0x1e, 0x24, 0xed, 0x00, 0x16, 0x24, 0xed, 0x00
	.byte 0x0a, 0x24, 0xed, 0x00, 0xfe, 0x23, 0xed, 0x00, 0xee, 0x23, 0xed, 0x00, 0xe2, 0x23, 0xed, 0x00
	.byte 0xd2, 0x23, 0xed, 0x00, 0xc4, 0x23, 0xed, 0x00, 0xc2, 0x23, 0xed, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED239D-0xED23AE (17 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near NakaParam_AcMstStyleAlpGridBox+7
MstStyleAlpGrid_Empty:
	aligned_string ""
MstStyleAlpGrid_nowttlselsong:	aligned_string "nowttlselsong"
MstStyleAlpGrid_nowalphselsong:	aligned_string "nowalphselsong"
MstStyleAlpGrid_nowalphpage:	aligned_string "nowalphpage"
MstStyleAlpGrid_nowalphmaxpage:	aligned_string "nowalphmaxpage"
	aligned_string "nowalphdtno"
	aligned_string "nowalphtop"
	aligned_string "nowalph"
	aligned_string "func"
	aligned_string "fixedrow"
	aligned_string "fixedcol"


ParamStr_Table_18:
	.long ParamStr18_fixedcol
	.long ParamStr18_fixedrow
	.long ParamStr18_func
	.long ParamStr18_nowalph
	.long ParamStr18_nowalphtop
	.long ParamStr18_nowalphdtno
	.long ParamStr18_nowalphmaxpage
	.long ParamStr18_nowalphpage
	.long ParamStr18_Empty
ParamStr18_Empty:	aligned_string ""
ParamStr18_nowalphpage:	aligned_string "nowalphpage"
ParamStr18_nowalphmaxpage:	aligned_string "nowalphmaxpage"
ParamStr18_nowalphdtno:	aligned_string "nowalphdtno"
ParamStr18_nowalphtop:	aligned_string "nowalphtop"
ParamStr18_nowalph:	aligned_string "nowalph"
ParamStr18_func:	aligned_string "func"
ParamStr18_fixedrow:	aligned_string "fixedrow"
ParamStr18_fixedcol:	aligned_string "fixedcol"
NakaParam_AcMstStyle1SubGridBox:
	.byte 0x16, 0x25, 0xed, 0x00
ParamStr_Table_19:
	.long ParamStr19_fixedcol
	.long ParamStr19_func
	.long ParamStr19_nowstylectgdtno
	.long ParamStr19_nowstylectgmaxpage
	.long ParamStr19_nowstylectgpage
	.long ParamStr19_Empty
ParamStr19_Empty:	aligned_string ""
ParamStr19_nowstylectgpage:	aligned_string "nowstylectgpage"
ParamStr19_nowstylectgmaxpage:	aligned_string "nowstylectgmaxpage"
ParamStr19_nowstylectgdtno:	aligned_string "nowstylectgdtno"
ParamStr19_func:
	jr z, 117
	jr nz, 99
	nop
	swi 7
	aligned_string "fixedrow"
	aligned_string "fixedcol"


ParamStr_Table_20:
	.long ParamStr20_fixedcol
	.long ParamStr20_fixedrow
	.long ParamStr20_func
	.long ParamStr20_nowstylesubctgdtno
	.long ParamStr20_nowstylesubctgmaxpage
	.long ParamStr20_nowstylesubctgpage
	.long ParamStr20_Empty
ParamStr20_Empty:	aligned_string ""
ParamStr20_nowstylesubctgpage:	aligned_string "nowstylesubctgpage"
ParamStr20_nowstylesubctgmaxpage:	aligned_string "nowstylesubctgmaxpage"
ParamStr20_nowstylesubctgdtno:	aligned_string "nowstylesubctgdtno"
ParamStr20_func:	aligned_string "func"
ParamStr20_fixedrow:	aligned_string "fixedrow"
ParamStr20_fixedcol:	aligned_string "fixedcol"


ParamStr_Table_21:
	.long ParamStr21_fixedcol
	.long ParamStr21_fixedrow
	.long ParamStr21_func
	.long ParamStr21_nowstylesubctgdtno
	.long ParamStr21_nowstylesubctgmaxpage
	.long ParamStr21_nowstylesubctgpage
	.long ParamStr21_nowstylesubctg
	.long ParamStr21_nowstyle
	.long ParamStr21_nowstylesubsubdtno1
	.long ParamStr21_nowstylesubsubdtno2
	.long ParamStr21_Empty
ParamStr21_Empty:	aligned_string ""
ParamStr21_nowstylesubsubdtno2:	aligned_string "nowstylesubsubdtno2"
ParamStr21_nowstylesubsubdtno1:	aligned_string "nowstylesubsubdtno1"
ParamStr21_nowstyle:	aligned_string "nowstyle"
ParamStr21_nowstylesubctg:	aligned_string "nowstylesubctg"
ParamStr21_nowstylesubctgpage:	aligned_string "nowstylesubctgpage"
ParamStr21_nowstylesubctgmaxpage:	aligned_string "nowstylesubctgmaxpage"
ParamStr21_nowstylesubctgdtno:	aligned_string "nowstylesubctgdtno"
ParamStr21_func:	aligned_string "func"
ParamStr21_fixedrow:	aligned_string "fixedrow"
ParamStr21_fixedcol:	aligned_string "fixedcol"
NakaParam_AcMstSong2GridBox:
	.byte 0xbe, 0x26, 0xed, 0x00, 0xb4, 0x26, 0xed, 0x00, 0xae, 0x26, 0xed, 0x00, 0x9e, 0x26, 0xed, 0x00
	.byte 0x8c, 0x26, 0xed, 0x00, 0x7c, 0x26, 0xed, 0x00, 0x7a, 0x26, 0xed, 0x00, 0x00, 0xff
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2663-0xED267C (25 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=71% dist=9 near NakaParam_AcMstSong2GridBox+5
MstSong2Grid_nowsongctgpage:	aligned_string "nowsongctgpage"
MstSong2Grid_nowsongctgmaxpage:	aligned_string "nowsongctgmaxpage"
MstSong2Grid_nowsongctgdtno:	aligned_string "nowsongctgdtno"
	jr z, 117
MstSong2Grid_func:	.byte 0x6e, 0x63, 0x00, 0xff
	aligned_string "fixedrow"
	aligned_string "fixedcol"


ParamStr_Table_22:
	.long ParamStr22_fixedcol
	.long ParamStr22_fixedrow
	.long ParamStr22_func
	.long ParamStr22_nowsongsubctgdtno
	.long ParamStr22_nowsongsubctgmaxpage
	.long ParamStr22_nowsongsubctgpage
	.long ParamStr22_nowsongsubctg
	.long ParamStr22_nowsong
	.long ParamStr22_nowsongsubsubdtno1
	.long ParamStr22_nowsongsubsubdtno2
	.long ParamStr22_Empty
ParamStr22_Empty:	aligned_string ""
ParamStr22_nowsongsubsubdtno2:	aligned_string "nowsongsubsubdtno2"
ParamStr22_nowsongsubsubdtno1:	aligned_string "nowsongsubsubdtno1"
ParamStr22_nowsong:	aligned_string "nowsong"
ParamStr22_nowsongsubctg:	aligned_string "nowsongsubctg"
ParamStr22_nowsongsubctgpage:	aligned_string "nowsongsubctgpage"
ParamStr22_nowsongsubctgmaxpage:
	aligned_string "nowsongsubctgmaxpage"
	aligned_string "nowsongsubctgdtno"
	aligned_string "func"
	aligned_string "fixedrow"
	aligned_string "fixedcol"


ParamStr_Table_23:
	.long ParamStr23_func
	.long ParamStr23_font
	.long ParamStr23_fontcolor
	.long ParamStr23_nowswno
	.long ParamStr23_oldswno
	.long ParamStr23_Empty
ParamStr23_Empty:	aligned_string ""
ParamStr23_oldswno:	aligned_string "oldswno"
ParamStr23_nowswno:	aligned_string "nowswno"
ParamStr23_fontcolor:	aligned_string "fontcolor"
ParamStr23_font:	aligned_string "font"
ParamStr23_func:	aligned_string "func"
ParamStr_Table_24:
	.long ParamStr24_page
	.long ParamStr24_window
	.long ParamStr24_Empty
ParamStr24_Empty:	aligned_string ""
ParamStr24_window:	aligned_string "window"
ParamStr24_page:	aligned_string "page"

ExtData_NormScreenProc_Ptr:
	.long NormScreenProc
.include "ui_widgets/master_style_grid_screens.s"
	.byte 0x6a, 0x00
	aligned_string "AcDispTimeSetGridBox"
NakaDesc_AcDispTimeSetGridBox:
	pop xwa
	pop xwa
	jr gt, 0
NakaInst_AcDispTimeSetGridBox:	aligned_string "AcPmExpFilterGridBox"
NakaDesc_AcPmExpFilterGridBox:
	pop xwa
	pop xwa
	jr gt, 0
NakaInst_AcPmExpFilterGridBox:	aligned_string "AcFSWAssGridBox"
NakaDesc_AcFSWAssGridBox:
	pop xwa
	pop xwa
	jr gt, 0
	aligned_string "AcTchSensGridBox"
	jr nz, 0
	aligned_string "IvMstStyleWindowPgCtl"
	.byte 0x6e, 0x00
	aligned_string "IvPmemWindowPageCtl"
	.byte 0x6e, 0x00
	aligned_string "IvWindowPageControl"
NakaDesc_IvWindowPageControl:	aligned_string "kc^nn"
NakaInst_IvWindowPageControl:	aligned_string "PmemModeBox"
NakaDesc_PmemModeBox:	aligned_string "kc^nn"
NakaInst_PmemModeBox:	aligned_string "MsaModeScreen"
NakaDesc_MsaModeScreen:
	jr gt, 114
	nop
	swi 7
	aligned_string "AcPmBkEditBox"
NakaDesc_AcPmBkEditBox:	aligned_string "kc^nnn"
NakaInst_AcPmBkEditBox:	.asciz "PmBankScreen"
	swi 7
NakaDesc_PmBankScreen:	aligned_string ""
NakaInst_PmBankScreen:	aligned_string "PmBkNoBox"
NakaDesc_AcPmBkNoBox:	aligned_string ""
NakaInst_AcPmBkNoBox:	aligned_string "BkNoBox"
NakaDesc_AcBkNoBox:	aligned_string ""
NakaInst_AcBkNoBox:	aligned_string "FreeSplitBox"
NakaDesc_AcFreeSplitBox:	aligned_string ""
NakaInst_AcFreeSplitBox:	aligned_string "ChordBox"
NakaDesc_AcChordBox:	aligned_string ""
NakaInst_AcChordBox:	aligned_string "TransposeBox"
NakaDesc_AcTransposeBox:	aligned_string "kc^nnnnnn"
NakaInst_AcTransposeBox:	aligned_string "RVariScreen"
NakaDesc_RVariScreen:	aligned_string "kc^nnnnnn"
NakaInst_RVariScreen:	aligned_string "VariScreen"
NakaDesc_VariScreen:	aligned_string ""
NakaInst_VariScreen:	aligned_string "NormScreen"
	.byte 0x1c, 0x00, 0x84, 0x2d, 0xed, 0x00
ParamStr_Table_25:
	.long EventNameStr_EV_CHORDDSP
	.long EventNameStr_EV_PMBKNAME
	.long EventNameStr_EV_PMNAME
	.long EventNameStr_EV_FRTPAGECHANGE
	.long EventNameStr_EV_SUBCTSHOW
	.long EventNameStr_EV_PAGESET
	.long EventNameStr_EV_TVARIPAINT
	.byte 0x00, 0x00, 0x00, 0x00
EventNameStr_EV_TVARIPAINT:	aligned_string "EV_TVARIPAINT"
EventNameStr_EV_PAGESET:	aligned_string "EV_PAGESET"
EventNameStr_EV_SUBCTSHOW:	aligned_string "EV_SUBCTSHOW"
EventNameStr_EV_FRTPAGECHANGE:	aligned_string "EV_FRTPAGECHANGE"
EventNameStr_EV_PMNAME:	aligned_string "EV_PMNAME"
EventNameStr_EV_PMBKNAME:	aligned_string "EV_PMBKNAME"
EventNameStr_EV_CHORDDSP:	aligned_string "EV_CHORDDSP"
	aligned_string "EV_CHORDSHOW"
	.byte 0x08, 0x00, 0x56, 0x2f, 0xed, 0x00
NoteNameStr_Table_6:
	.long MethodNameStr_MT_SvariIni
	.long MethodNameStr_MT_SvariSet
	.long MethodNameStr_MT_GetSndName
	.long MethodNameStr_MT_GetSndGrpName
	.long MethodNameStr_MT_SOUNDNAME
	.long MethodNameStr_MT_SOUNDGRPNAME
	.long MethodNameStr_MT_RvariIni
	.long MethodNameStr_MT_RvariSet
	.long MethodNameStr_MT_GetRhyName
	.long MethodNameStr_MT_GetRhyGrpName
	.long MethodNameStr_MT_RHYTHMNAME
	.long MethodNameStr_MT_RHYTHMGRPNAME
	.long MethodNameStr_MT_ChordPre
	.long MethodNameStr_MT_PMBANKSET
	.long MethodNameStr_MT_PmBankSet
	.long MethodNameStr_MT_PmBankName
	.long MethodNameStr_MT_PmBankMk
	.long MethodNameStr_MT_PmName
	.long MethodNameStr_MT_SYSINI
	.long MethodNameStr_MT_FLASHWRITE
	.long MethodNameStr_MT_FLASHLOAD
	.long MethodNameStr_MT_WALLINI
	.long MethodNameStr_MT_KEYINFO
	.long MethodNameStr_MT_OTPCNTSET
	.long MethodNameStr_MT_OTPCNTRESET
	.byte 0x00, 0x00, 0x00, 0x00
MethodNameStr_MT_OTPCNTRESET:	aligned_string "MT_OTPCNTRESET"
MethodNameStr_MT_OTPCNTSET:	aligned_string "MT_OTPCNTSET"
MethodNameStr_MT_KEYINFO:	aligned_string "MT_KEYINFO"
MethodNameStr_MT_WALLINI:	aligned_string "MT_WALLINI"
MethodNameStr_MT_FLASHLOAD:	aligned_string "MT_FLASHLOAD"
MethodNameStr_MT_FLASHWRITE:	aligned_string "MT_FLASHWRITE"
MethodNameStr_MT_SYSINI:	aligned_string "MT_SYSINI"
MethodNameStr_MT_PmName:	aligned_string "MT_PmName"
MethodNameStr_MT_PmBankMk:	aligned_string "MT_PmBankMk"
MethodNameStr_MT_PmBankName:	aligned_string "MT_PmBankName"
MethodNameStr_MT_PmBankSet:	aligned_string "MT_PmBankSet"
MethodNameStr_MT_PMBANKSET:	aligned_string "MT_PMBANKSET"
MethodNameStr_MT_ChordPre:	aligned_string "MT_ChordPre"
MethodNameStr_MT_RHYTHMGRPNAME:	aligned_string "MT_RHYTHMGRPNAME"
MethodNameStr_MT_RHYTHMNAME:	aligned_string "MT_RHYTHMNAME"
MethodNameStr_MT_GetRhyGrpName:	aligned_string "MT_GetRhyGrpName"
MethodNameStr_MT_GetRhyName:	aligned_string "MT_GetRhyName"
MethodNameStr_MT_RvariSet:	aligned_string "MT_RvariSet"
MethodNameStr_MT_RvariIni:	aligned_string "MT_RvariIni"
MethodNameStr_MT_SOUNDGRPNAME:	aligned_string "MT_SOUNDGRPNAME"
MethodNameStr_MT_SOUNDNAME:	aligned_string "MT_SOUNDNAME"
MethodNameStr_MT_GetSndGrpName:	aligned_string "MT_GetSndGrpName"
MethodNameStr_MT_GetSndName:	aligned_string "MT_GetSndName"
MethodNameStr_MT_SvariSet:	aligned_string "MT_SvariSet"
MethodNameStr_MT_SvariIni:	aligned_string "MT_SvariIni"
	aligned_string "MT_VariWrite"
	.byte 0x1a, 0x00, 0x62, 0xcd, 0xfb, 0x00, 0xe7, 0xe1, 0xfb, 0x00, 0x18, 0xf5, 0xfb, 0x00, 0xc3, 0x2e
	.byte 0xfc, 0x00, 0x0b, 0x2d, 0xfc, 0x00, 0xbb, 0x2f, 0xfc, 0x00, 0x22, 0x1a, 0xfc, 0x00, 0x3d, 0xdb
	.byte 0xfb, 0x00, 0xc3, 0xd5, 0xfb, 0x00, 0x41, 0xd8, 0xfb, 0x00, 0xeb, 0xd4, 0xfb, 0x00, 0xec, 0xd3
	.byte 0xfb, 0x00, 0xf1, 0xcd, 0xfb, 0x00, 0xd0, 0xb9, 0xfb, 0x00, 0xbb, 0xa7, 0xfb, 0x00, 0x9b, 0xad
	.byte 0xfb, 0x00, 0x4c, 0xbb, 0xfb, 0x00, 0x12, 0xc4, 0xfb, 0x00, 0x21, 0x80, 0xfb, 0x00, 0x28, 0x80
	.byte 0xfb, 0x00, 0xef, 0xa6, 0xfb, 0x00, 0x0b, 0x8b, 0xfb, 0x00, 0x3d, 0x90, 0xfb, 0x00, 0x8d, 0x97
	.byte 0xfb, 0x00, 0xe1, 0xa6, 0xfb, 0x00, 0xe8, 0xa6, 0xfb, 0x00, 0x26, 0x1f, 0xfc, 0x00, 0x22, 0xd0
	.byte 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2F90-0xED2FAB (27 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=67% dist=14 near MethodNameStr_MT_SvariIni+70
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2FAC-0xED2FC6 (26 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=13 near MethodNameStr_MT_SvariIni+98
NoteNameStr_Table_7:
	.long ProcNameStr_NormScreenProc
	.long ProcNameStr_VariScreenProc
	.long ProcNameStr_RVariScreenProc
	.long ProcNameStr_AcTransposeBoxProc
	.long ProcNameStr_AcFreeSplitBoxProc
	.long ProcNameStr_AcChordBoxProc
	.long ProcNameStr_PmBankScreenProc
	.long ProcNameStr_AcPmBkEditBoxProc
	.long ProcNameStr_MsaModeScreenProc
	.long ProcNameStr_PmemModeBoxProc
	.long ProcNameStr_AcBkNoBoxProc
	.long ProcNameStr_AcPmBkNoBoxProc
	.long ProcNameStr_IvWindowPageControlProc
	.long ProcNameStr_IvPmemWindowPageCtlProc
	.long ProcNameStr_AcTchSensGridBoxProc
	.long ProcNameStr_AcFSWAssGridBoxProc
	.long ProcNameStr_AcPmExpFilterGridBoxProc
	.long ProcNameStr_AcDispTimeSetGridBoxProc
	.long ProcNameStr_AcMstSugAlpGridBoxProc
	.long ProcNameStr_AcMstStyleAlpGridBoxProc
	.long ProcNameStr_IvMstStyleWindowPgCtlProc
	.long ProcNameStr_AcMstStyle1GridBoxProc
	.long ProcNameStr_AcMstStyle1SubGridBoxProc
	.long ProcNameStr_AcMstStyle2GridBoxProc
	.long ProcNameStr_AcMstSong1GridBoxProc
	.long ProcNameStr_AcMstSong2GridBoxProc
	.long ProcNameStr_SineWaveScreenProc
	.long ProcNameStr_IvPageOverWrProc
	.long ProcNameStr_NullTerm
ProcNameStr_NullTerm:
	aligned_string ""
ProcNameStr_IvPageOverWrProc:	aligned_string "IvPageOverWrProc"
ProcNameStr_SineWaveScreenProc:	aligned_string "SineWaveScreenProc"
ProcNameStr_AcMstSong2GridBoxProc:	aligned_string "AcMstSong2GridBoxProc"
ProcNameStr_AcMstSong1GridBoxProc:	aligned_string "AcMstSong1GridBoxProc"
ProcNameStr_AcMstStyle2GridBoxProc:	aligned_string "AcMstStyle2GridBoxProc"
ProcNameStr_AcMstStyle1SubGridBoxProc:	aligned_string "AcMstStyle1SubGridBoxProc"
ProcNameStr_AcMstStyle1GridBoxProc:	aligned_string "AcMstStyle1GridBoxProc"
ProcNameStr_IvMstStyleWindowPgCtlProc:	aligned_string "IvMstStyleWindowPgCtlProc"
ProcNameStr_AcMstStyleAlpGridBoxProc:	aligned_string "AcMstStyleAlpGridBoxProc"
ProcNameStr_AcMstSugAlpGridBoxProc:	aligned_string "AcMstSugAlpGridBoxProc"
ProcNameStr_AcDispTimeSetGridBoxProc:	aligned_string "AcDispTimeSetGridBoxProc"
ProcNameStr_AcPmExpFilterGridBoxProc:	aligned_string "AcPmExpFilterGridBoxProc"
ProcNameStr_AcFSWAssGridBoxProc:	aligned_string "AcFSWAssGridBoxProc"
ProcNameStr_AcTchSensGridBoxProc:	aligned_string "AcTchSensGridBoxProc"
ProcNameStr_IvPmemWindowPageCtlProc:	aligned_string "IvPmemWindowPageCtlProc"
ProcNameStr_IvWindowPageControlProc:	aligned_string "IvWindowPageControlProc"
ProcNameStr_AcPmBkNoBoxProc:	aligned_string "AcPmBkNoBoxProc"
ProcNameStr_AcBkNoBoxProc:	aligned_string "AcBkNoBoxProc"
ProcNameStr_PmemModeBoxProc:	aligned_string "PmemModeBoxProc"
ProcNameStr_MsaModeScreenProc:	aligned_string "MsaModeScreenProc"
ProcNameStr_AcPmBkEditBoxProc:	aligned_string "AcPmBkEditBoxProc"
ProcNameStr_PmBankScreenProc:	aligned_string "PmBankScreenProc"
ProcNameStr_AcChordBoxProc:	aligned_string "AcChordBoxProc"
ProcNameStr_AcFreeSplitBoxProc:	aligned_string "AcFreeSplitBoxProc"
ProcNameStr_AcTransposeBoxProc:	aligned_string "AcTransposeBoxProc"
ProcNameStr_RVariScreenProc:	aligned_string "RVariScreenProc"
ProcNameStr_VariScreenProc:	aligned_string "VariScreenProc"
ProcNameStr_NormScreenProc:	aligned_string "NormScreenProc"
	.byte 0xd9, 0x27, 0xfc, 0x00, 0x15, 0x28, 0xfc, 0x00, 0x5e, 0x29, 0xfc, 0x00, 0x87, 0x28, 0xfc, 0x00
	.byte 0x44, 0x2a, 0xfc, 0x00, 0xec, 0x28, 0xfc, 0x00, 0xca, 0x29, 0xfc, 0x00, 0x4e, 0x30, 0xfc, 0x00
	.byte 0xb9, 0x2a, 0xfc, 0x00, 0x00, 0x63, 0xfb, 0x00, 0xbf, 0x2b, 0xfc, 0x00, 0xab, 0x2c, 0xfc, 0x00
	.byte 0x59, 0xb9, 0xfb, 0x00, 0xe4, 0x2c, 0xfc, 0x00, 0x11, 0xcd, 0xfb, 0x00, 0x46, 0x26, 0xfc, 0x00
	.byte 0x44, 0x7d, 0xfb, 0x00, 0x78, 0x7d, 0xfb, 0x00, 0xac, 0x7d, 0xfb, 0x00, 0xe0, 0x7d, 0xfb, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED32CC-0xED32DE (18 B), unreached CODE-territory, was disassembled as 8 plausible-but-dead instruction lines; per=100% dist=9 near ProcNameStr_NormScreenProc+74
NoteNameStr_Table_8:
	.long NakaInst_MainVariSet
	.long NakaInst_MainSvariIni
	.long NakaInst_MainGetSndName
	.long NakaInst_MainRvariIni
	.long NakaInst_MainGetRhyName
	.long NakaInst_MainGetSndGrpName
	.long NakaInst_MainGetRhyGrpName
	.long NakaInst_MainChordPre
	.long NakaInst_MainPmGet
	.long NakaInst_OneTchFUNC
	.long NakaInst_MainSysControl
	.long NakaInst_CntIniFunc
	.long NakaInst_FswAsIniFunc
	.long NakaInst_MainMssSetUp
	.long NakaInst_MainTimeFlashFunc
	.long NakaInst_MainWallSetFlashFunc
	.long NakaInst_TEST2FUNC
	.long NakaInst_TEST3FUNC
	.long NakaInst_TEST4FUNC
	.long NakaInst_TEST6FUNC
	.long NakaInstTable8_NullTerm
NakaInstTable8_NullTerm:
	nop
	swi 7
.include "ui_widgets/normal_mode_layout.s"
	.byte 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0xf4, 0x03, 0x00, 0x08, 0xf4, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1a, 0x00, 0xff, 0xff, 0x08, 0x00, 0x15, 0x01
	.byte 0x80, 0x00, 0x3b, 0x01, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x00, 0x00, 0x07, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1b, 0x00, 0x19, 0x00, 0x08, 0x00, 0xee, 0x00
	.byte 0x80, 0x00, 0x14, 0x01, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x01, 0x00, 0x06, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1c, 0x00, 0x1a, 0x00, 0x08, 0x00, 0xc7, 0x00
	.byte 0x80, 0x00, 0xed, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x02, 0x00, 0x05, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1d, 0x00, 0x1b, 0x00, 0x08, 0x00, 0xa0, 0x00
	.byte 0x80, 0x00, 0xc6, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x13, 0x00, 0x04, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1e, 0x00, 0x1c, 0x00, 0x08, 0x00, 0x79, 0x00
	.byte 0x80, 0x00, 0x9f, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x10, 0x00, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x1f, 0x00, 0x1d, 0x00, 0x08, 0x00, 0x52, 0x00
	.byte 0x80, 0x00, 0x78, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x11, 0x00, 0x02, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0x20, 0x00, 0x1e, 0x00, 0x08, 0x00, 0x2b, 0x00
	.byte 0x80, 0x00, 0x51, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x12, 0x00, 0x01, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x18, 0x00, 0xff, 0xff, 0xff, 0xff, 0x1f, 0x00, 0x08, 0x00, 0x04, 0x00
	.byte 0x80, 0x00, 0x2a, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x14, 0x00, 0x00, 0x00
	.byte 0x35, 0x00, 0x60, 0x01, 0xff, 0xff, 0x22, 0x00, 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x00, 0x00
	.byte 0x7f, 0x00, 0x3f, 0x01, 0xef, 0x00, 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0xf4, 0x03, 0x00
	.byte 0x10, 0xf4, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x21, 0x00, 0xff, 0xff, 0x23, 0x00, 0xff, 0xff, 0x08, 0x00, 0xa0, 0x00
	.byte 0x80, 0x00


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED37EF-0xED380A (27 B), unreached CODE-territory, was disassembled as 20 plausible-but-dead instruction lines; per=100% dist=12 near NakaInst_MainVariSet+935


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED382F-0xED384A (27 B), unreached CODE-territory, was disassembled as 20 plausible-but-dead instruction lines; per=100% dist=14 near NakaInst_MainVariSet+999
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3859-0xED386A (17 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1041










	.long WidgetName_PtrBlock_I2
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x15, 0x00, 0x04, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x21, 0x00, 0xff, 0xff, 0x24, 0x00, 0x22, 0x00, 0x08, 0x00, 0x79, 0x00
	.byte 0x80, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED391D-0xED392E (17 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1237
	.long WidgetName_PtrBlock_F2
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x16, 0x00, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x21, 0x00, 0xff, 0xff, 0x25, 0x00, 0x23, 0x00, 0x08, 0x00, 0x52, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_E
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x17, 0x00, 0x02, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x21, 0x00, 0xff, 0xff, 0x26, 0x00, 0x24, 0x00, 0x08, 0x00, 0x2b, 0x00
	.byte 0x80, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED395B-0xED396E (19 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+1299
	.long WidgetName_PtrBlock_D
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x1a, 0x00, 0x01, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x21, 0x00, 0xff, 0xff, 0xff, 0xff, 0x25, 0x00, 0x08, 0x00, 0x04, 0x00
	.byte 0x80, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED397D-0xED398E (17 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=9 near NakaInst_MainVariSet+1333
	.long WidgetName_PtrBlock_C
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x1b, 0x00, 0x00, 0x00
	.byte 0x35, 0x00, 0x60, 0x01, 0xff, 0xff, 0x28, 0x00, 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x00, 0x00
	.byte 0x7f, 0x00


	.long Naka_PresentationRootState
	.byte 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0xf4, 0x03, 0x00, 0x18, 0xf4, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x29, 0x00, 0xff, 0xff, 0x08, 0x00, 0x04, 0x00
	.byte 0x80, 0x00, 0x2a, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2a, 0x00, 0x28, 0x00, 0x08, 0x00, 0x2b, 0x00
	.byte 0x80, 0x00, 0x51, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x01, 0x00, 0x01, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2b, 0x00, 0x29, 0x00, 0x08, 0x00, 0x52, 0x00
	.byte 0x80, 0x00, 0x78, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x02, 0x00, 0x02, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2c, 0x00, 0x2a, 0x00, 0x08, 0x00, 0x79, 0x00
	.byte 0x80, 0x00, 0x9f, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x03, 0x00, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2d, 0x00, 0x2b, 0x00, 0x08, 0x00, 0xa0, 0x00
	.byte 0x80, 0x00, 0xc6, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x04, 0x00, 0x04, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2e, 0x00, 0x2c, 0x00, 0x08, 0x00, 0xc7, 0x00
	.byte 0x80, 0x00, 0xed, 0x00, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x05, 0x00, 0x05, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0x2f, 0x00, 0x2d, 0x00, 0x08, 0x00, 0xee, 0x00
	.byte 0x80, 0x00, 0x14, 0x01, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x06, 0x00, 0x06, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x27, 0x00, 0xff, 0xff, 0xff, 0xff, 0x2e, 0x00, 0x08, 0x00, 0x15, 0x01
	.byte 0x80, 0x00, 0x3b, 0x01, 0xeb, 0x00, 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x07, 0x00, 0x07, 0x00
	.byte 0x35, 0x00, 0x60, 0x01, 0xff, 0xff, 0x31, 0x00, 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x00, 0x00
	.byte 0x7f, 0x00, 0x3f, 0x01, 0xef, 0x00, 0xf5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1c, 0xf4, 0x03, 0x00
	.byte 0x20, 0xf4, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x32, 0x00, 0xff, 0xff, 0x08, 0x00, 0x04, 0x00
	.byte 0x80, 0x00


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED39D7-0xED39F2 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=12 near NakaInst_MainVariSet+1423
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A01-0xED3A12 (17 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1465
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A13-0xED3A32 (31 B), unreached CODE-territory, was disassembled as 24 plausible-but-dead instruction lines; per=100% dist=15 near NakaInst_MainVariSet+1483
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A37-0xED3A52 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=13 near NakaInst_MainVariSet+1519
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A61-0xED3A72 (17 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1561
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A77-0xED3A92 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=13 near NakaInst_MainVariSet+1583






	.long WidgetName_PtrBlock_C
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x08, 0x00, 0x00, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x33, 0x00, 0x31, 0x00, 0x08, 0x00, 0x2b, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_D
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x09, 0x00, 0x01, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x34, 0x00, 0x32, 0x00, 0x08, 0x00, 0x52, 0x00
	.byte 0x80, 0x00
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3B25-0xED3B36 (17 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1757
	.long WidgetName_PtrBlock_E
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0a, 0x00, 0x02, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x35, 0x00, 0x33, 0x00, 0x08, 0x00, 0x79, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_F2
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0b, 0x00, 0x03, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x36, 0x00, 0x34, 0x00, 0x08, 0x00, 0xa0, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_I2
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0c, 0x00, 0x04, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x37, 0x00, 0x35, 0x00, 0x08, 0x00, 0xc7, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_L
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0d, 0x00, 0x05, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0x38, 0x00, 0x36, 0x00, 0x08, 0x00, 0xee, 0x00
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_M2
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0e, 0x00, 0x06, 0x00
	.byte 0x3c, 0x00, 0x60, 0x01, 0x30, 0x00, 0xff, 0xff, 0xff, 0xff, 0x37, 0x00, 0x08, 0x00, 0x15, 0x01
	.byte 0x80, 0x00


	.long WidgetName_PtrBlock_N1
	.byte 0x07, 0x00, 0xc1, 0x00, 0xff, 0xff, 0x0f, 0x00, 0x07, 0x00
	.byte 0x35, 0x00, 0x60, 0x01, 0xff, 0xff, 0x3a, 0x00, 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x04, 0x00
	.byte 0xbe, 0x00


	.long SoundName_ToTheBone
	.byte 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00, 0x24, 0xf4, 0x03, 0x00, 0x28, 0xf4, 0x03, 0x00
	.byte 0x69, 0x00, 0x60, 0x01, 0x39, 0x00, 0xff, 0xff, 0x3b, 0x00, 0xff, 0xff, 0x08, 0x00, 0x98, 0x00
	.byte 0xc8, 0x00, 0x07, 0x01, 0xe0, 0x00, 0x16, 0x00, 0x22, 0x01
	.byte 0x69, 0x00, 0x60, 0x01, 0x39, 0x00, 0xff, 0xff, 0xff, 0xff, 0x3a, 0x00, 0x08, 0x00, 0x38, 0x00
	.byte 0xcc, 0x00, 0x87, 0x00, 0xdd, 0x00, 0x17, 0x00, 0x22, 0x01
	.byte 0x35, 0x00, 0x60, 0x01, 0xff, 0xff, 0x3d, 0x00, 0xff, 0xff, 0xff, 0xff, 0x08, 0x00, 0x04, 0x00
	.byte 0xbe, 0x00


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3C1F-0xED3C34 (21 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+2007


	.long SoundName_ToTheBone
	.byte 0x07, 0x00, 0xc1, 0x00, 0x00, 0x00, 0x2c, 0xf4, 0x03, 0x00, 0x30, 0xf4, 0x03, 0x00
	.byte 0x69, 0x00, 0x60, 0x01, 0x3c, 0x00, 0xff, 0xff, 0x3e, 0x00, 0xff, 0xff, 0x08, 0x00, 0x28, 0x00
	.byte 0xcc, 0x00, 0x93, 0x00, 0xdf, 0x00, 0x19, 0x00, 0x22, 0x01
	.byte 0x69, 0x00, 0x60, 0x01, 0x3c, 0x00, 0xff, 0xff, 0xff, 0xff, 0x3d, 0x00, 0x08, 0x00, 0xa0, 0x00
	.byte 0xc8, 0x00, 0x10, 0x01, 0xe0, 0x00, 0x18, 0x00, 0x22, 0x01


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3C77-0xED3C8C (21 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+2095
.include "ui_widgets/control_menu_screens.s"
	.byte 0x60, 0x01, 0x07, 0x00, 0xff, 0xff, 0x09, 0x00, 0xff, 0xff, 0x08, 0x00, 0x4e, 0x00, 0x80, 0x00
	.byte 0xe1, 0x00, 0x92, 0x00
	.long Str_ErrorDialog_Caution
	push sr
	nop
	nop
	nop
	swi 1
	nop
Str_ErrorDialog_Caution:	.asciz "CAUTION!!"	; English text


; ---------------------------------------------------------------------------
; Widget 10 (0x0a): ERROR Message
; "** ERROR in CPU data transmission **"
; Screen group 7, index 10 - Main error message
; ---------------------------------------------------------------------------
ErrorDialog_CPUTransmissionError:
	.byte 0x2b, 0x00, 0x60, 0x01, 0x07, 0x00, 0xff, 0xff, 0x0a, 0x00, 0x08, 0x00, 0x08, 0x00, 0x0e, 0x00
	.byte 0x96, 0x00, 0x31, 0x01, 0xa8, 0x00, 0xe4, 0x66, 0xed, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00
	aligned_string "** ERROR in CPU data transmission **"


; ---------------------------------------------------------------------------
; Widget 11 (0x0b): Recovery Instruction Line 1
; "Please try turning off and on again."
; Screen group 7, index 11
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine1:
	.byte 0x2b, 0x00, 0x60, 0x01, 0x07, 0x00, 0xff, 0xff, 0x0b, 0x00, 0x09, 0x00, 0x08, 0x00, 0x2e, 0x00
	.byte 0xae, 0x00, 0x09, 0x01, 0xb8, 0x00
	.long Str_ErrorDialog_TryTurningOff
	pop sr
	nop
	nop
	nop
	nop
	nop
Str_ErrorDialog_TryTurningOff:	aligned_string "Please try turning off and on again."


; ---------------------------------------------------------------------------
; Widget 12 (0x0c): Recovery Instruction Line 2
; "If this message appears again,"
; Screen group 7, index 12
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine2:
	.byte 0x2b, 0x00, 0x60, 0x01, 0x07, 0x00, 0xff, 0xff, 0x0c, 0x00, 0x0a, 0x00, 0x08, 0x00, 0x2e, 0x00
	.long TechnichordParam_Block3
	.byte 0xc8, 0x00, 0x70, 0x67, 0xed, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00
	aligned_string "If this message appears again,"


; ---------------------------------------------------------------------------
; Widget 13 (end marker 0xffff): Recovery Instruction Line 3
; "this unit needs repairing."
; Screen group 7, final widget
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine3:
	.byte 0x2b, 0x00, 0x60, 0x01, 0x07, 0x00, 0xff, 0xff, 0xff, 0xff, 0x0b, 0x00, 0x08, 0x00, 0x2e, 0x00
	.byte 0xce, 0x00, 0xcd, 0x00, 0xd8, 0x00, 0xb0, 0x67, 0xed, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00
	aligned_string "this unit needs repairing."
.include "ui_widgets/extension_device_screens.s"
	.ascii "!\"#$%%&'()*+,,-./01234456789:;;<=>?@ABCCDEFGHIJKKLMNOPQRRSTUVWXYZZ[\\]^_`abbcdefghiijklmqtx{"
	.byte 0x7f, 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x07, 0x07, 0x08
	.byte 0x08, 0x09, 0x09, 0x0a, 0x0a, 0x0b, 0x0b, 0x0c, 0x0c, 0x0d, 0x0e, 0x0e, 0x0f, 0x0f, 0x10, 0x10
	.byte 0x11, 0x11, 0x12, 0x12, 0x13, 0x14, 0x14, 0x15, 0x15, 0x16, 0x16, 0x17, 0x17, 0x18, 0x18, 0x19
	.byte 0x19, 0x1a, 0x1b, 0x1b, 0x1c, 0x1c, 0x1d, 0x1d, 0x1e, 0x1e, 0x1f, 0x1f, 0x20
	.ascii "!!\"\"##$$%%&''(())**++,,-..//0011223445566778899::;;<<==>>??@@AABBCCDDEEFFGGHHIIJJKKLLMNNOPQQRSTTUVWWXYZZ[\\\\]^__`abbcdeefghijklmmnopqrstuvwxyzz{|}~"
	.byte 0x7f, 0x80, 0x82, 0x83, 0x85, 0x87, 0x88, 0x8a, 0x8c, 0x8d, 0x8f, 0x91, 0x92, 0x94, 0x96, 0x97
	.byte 0x99, 0x9b, 0x9d, 0x9f, 0xa1, 0xa3, 0xa5, 0xa7, 0xa9, 0xab, 0xad, 0xaf, 0xb1, 0xb3, 0xb7, 0xba
	.byte 0xbe, 0xc1, 0xc5, 0xc8, 0xcc, 0xd1, 0xd6, 0xdc, 0xe1, 0xe6, 0xe9, 0xec, 0xef, 0xf3, 0xf6, 0xf9
	.byte 0xfc, 0xff, 0x00, 0x00, 0x06, 0x00, 0x08, 0x00, 0x0a, 0x00, 0x0d, 0x00, 0x10, 0x00, 0x13, 0x00
	.byte 0x16, 0x00, 0x19, 0x00, 0x1e, 0x00, 0x28, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x04, 0x06, 0x08
	.byte 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e, 0x20, 0x22, 0x24
	.ascii "&(*,.0234568:<>?@BDEFHJKLMNPQRTUVXYZ[\\]^_`abcdefghijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}}~~~"
	.byte 0x7f, 0x7f, 0x7f, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x81, 0x81, 0x81, 0x81, 0x82, 0x82, 0x82, 0x82, 0x83, 0x83, 0x83, 0x84
	.byte 0x84, 0x85, 0x85, 0x86, 0x86, 0x87, 0x87, 0x88, 0x88, 0x89, 0x89, 0x8a, 0x8a, 0x8b, 0x8b, 0x8c
	.byte 0x8c, 0x8d, 0x8d, 0x8e, 0x8e, 0x8f, 0x8f, 0x90, 0x90, 0x91, 0x91, 0x92, 0x92, 0x93, 0x94, 0x95
	.byte 0x96, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa4, 0xa5
	.byte 0xa6, 0xa7, 0xa8, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xb0, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8
	.byte 0xba, 0xbc, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3, 0xc4, 0xc6, 0xc8, 0xca, 0xcc, 0xcd, 0xce, 0xd0, 0xd2
	.byte 0xd4, 0xd6, 0xd8, 0xda, 0xdc, 0xdd, 0xde, 0xe0, 0xe2, 0xe4, 0xe6, 0xe8, 0xea, 0xec, 0xee, 0xf0
	.byte 0xf2, 0xf5, 0xf7, 0xf9, 0xfb, 0xfd, 0xff, 0xff, 0xff, 0xff, 0x15, 0x00, 0x2b, 0x00, 0x40, 0x00
	.byte 0x55, 0x00, 0x6b, 0x00, 0x80, 0x00, 0x95, 0x00, 0xab, 0x00, 0xc0, 0x00, 0xd5, 0x00, 0xeb, 0x00
	.byte 0x00, 0x01, 0x55, 0x05, 0xab, 0x0a, 0x00, 0x10, 0x55, 0x15, 0xab, 0x1a, 0x00, 0x20, 0x55, 0x25
	.byte 0xab, 0x2a, 0x00, 0x30, 0x55, 0x35, 0xab, 0x3a, 0x00, 0x40, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14
	.byte 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
	.ascii " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{}"
	.byte 0x7f, 0x7f, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d
	.byte 0x1e, 0x1f
	.ascii " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	.byte 0x7f, 0x01, 0x00, 0xe3, 0x75, 0xfc, 0x00, 0x02, 0x00, 0x04, 0x77, 0xfc, 0x00, 0x04, 0x00
	.long SndParam_TableLookup_Via4100
	.byte 0x08, 0x00, 0x1d, 0x73, 0xfc, 0x00, 0x10, 0x00, 0xbc, 0x72, 0xfc, 0x00, 0x20, 0x00, 0x79, 0x73
	.byte 0xfc, 0x00, 0x40, 0x00
	.long SndParam_SetResBit2_ViaPartCC5D
	.byte 0x80, 0x00, 0xd9, 0x72, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01, 0x00, 0x86, 0x76
	.byte 0xfc, 0x00, 0x02, 0x00
	.long SndParam_VoiceEntryLookup_ViaReg8000
	.byte 0x04
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA545-0xEDA558 (19 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=100% dist=10 near ENCODER_LUT_MODWHEEL_0x3FC+13
	.byte 0x00, 0x9e, 0x73, 0xfc, 0x00, 0x08, 0x00, 0xd9, 0x73, 0xfc, 0x00, 0x10
	.byte 0x00, 0x6a, 0x72, 0xfc, 0x00, 0x20, 0x00
	.long SndParam_SetResBit3_ViaRegs0101_0102
	.byte 0x40, 0x00, 0x24, 0x72, 0xfc, 0x00, 0x80, 0x00, 0x41, 0x72, 0xfc, 0x00, 0x00, 0x01, 0xf6, 0x73
	.byte 0xfc, 0x00, 0x00, 0x02
	.long SndParam_VoiceEntryLookup_ViaReg8000
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01, 0x00, 0x9f, 0x74, 0xfc, 0x00, 0x04, 0x00, 0xe4, 0x74
	.byte 0xfc, 0x00, 0x08, 0x00
	.long SndParam_SetResBit4_Via0400
	.byte 0x10, 0x00, 0x6e, 0x74, 0xfc, 0x00, 0x20, 0x00, 0x8b, 0x74, 0xfc, 0x00, 0x40, 0x00, 0x01, 0x75
	.byte 0xfc, 0x00, 0x00, 0x01
	.long ExtData_VoiceParam_DispatchBytecode
	.byte 0x00, 0x04, 0xa6, 0x75, 0xfc, 0x00, 0x00, 0x10, 0xb7, 0x75, 0xfc, 0x00, 0x00, 0x20, 0x41, 0x77
	.byte 0xfc, 0x00, 0x00, 0x40
	.long CtrlPanel_SetResBit6_ViaLookup
	.byte 0x00, 0x80, 0x75, 0x77, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01, 0x00, 0xbf, 0x77
	.byte 0xfc, 0x00, 0x02, 0x00
	.long CtrlPanel_SetBit3_OnStyleD0D3
	.byte 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0x40, 0x00, 0xf0, 0x77, 0xfc, 0x00, 0x08, 0x00
	.long CtrlPanel_SetResBit0_ViaLookup4C
	.byte 0x04, 0x00, 0x78, 0x78, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x04, 0x00, 0xe6, 0x78
	.byte 0xfc, 0x00, 0x00, 0x20
	.long CtrlPanel_SetResBit5_ViaLookup4C
	.byte 0x00, 0x40, 0x20, 0x79, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.fill 6, 1, 0xff


Protocol_values_for_LED_rows:
	; LED row lookup table: maps internal index (0-14) to protocol row value
	; Used by Set_LEDs (FC71B2) to translate row index to serial protocol value
	;
	; Index 0-5: Left Panel (CPL)
	;   0: 0xc0 = COMPOSER:MEMORY/MENU, SOUND ARR:SET/ON, MUSIC STYLIST, FADE IN/OUT, DISPLAY HOLD
	;   1: 0xc1 = U.S. TRAD, COUNTRY, LATIN, MARCH&WALTZ, PARTY TIME, SHOWTIME, WORLD, CUSTOM
	;   2: 0xc2 = STANDARD ROCK, R&ROLL&BLUES, POP&BALLAD, FUNK&FUSION, SOUL, BIG BAND, JAZZ, MSP:MENU
	;   3: 0xc3 = VARIATION 1-4, MUSIC STYLE ARRANGER, AUTO PLAY CHORD
	;   4: 0xc4 = FILL IN 1/2, INTRO&ENDING 1/2, SPLIT POINT (L/C/R), TEMPO/PROGRAM
	;   5: 0xc8 = OTHER PARTS/TR
	;
	; Index 6-14: Right Panel (CPR)
	;   6: 0x00 = SUSTAIN, DIGITAL/DSP/REVERB EFFECT, ACOUSTIC ILLUSION, SEQ:PLAY/EASY REC/MENU
	;   7: 0x01 = PIANO, GUITAR, STRINGS&VOCAL, BRASS, FLUTE, SAX&REED, MALLET, WORLD PERC
	;   8: 0x02 = ORGAN, ORCHESTRAL PAD, SYNTH, BASS, DIGITAL DRAWBAR, ACCORDION REG, GM, DRUMS
	;   9: 0x03 = PANEL MEMORY 1-8
	;  10: 0x04 = PART:LEFT/R2/R1, ENTERTAINER, CONDUCTOR:L/R2/R1, TECHNI CHORD
	;  11: 0x08 = MENU:SOUND/CONTROL/MIDI/DISK
	;  12: 0x0a = MEMORY A, MEMORY B
	;  13: 0x0b = SYNCHRO&BREAK, R1/R2 OCTAVE -/+, BANK VIEW
	;  14: 0x0c = START/STOP BEAT 1-4
	.byte 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x08, 0x0a, 0x0b, 0x0c, 0xff
	.byte 0x04, 0x02, 0x06, 0x07, 0x05, 0x03, 0x23, 0x00, 0x23, 0x00, 0x2b, 0x00, 0x27, 0x00, 0x2f, 0x00
	.byte 0x33, 0x00, 0x0c, 0x00, 0x1f, 0x00, 0x3c, 0x00, 0x10, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x04, 0x00
	.byte 0x00, 0x00, 0x3c, 0x00, 0x08, 0x00, 0x37, 0x00, 0x01, 0x02, 0x04, 0x01, 0x02, 0x04, 0x01, 0x02
	.byte 0x04, 0x08, 0x01, 0x02, 0x04, 0x08, 0x00, 0x00, 0x34, 0x00, 0x34, 0x00, 0x0e, 0x00, 0x27, 0x00
	.byte 0x07, 0x00, 0x07, 0x00, 0x2e, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x04, 0x00
	.byte 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x40, 0x00
	.byte 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x40
	.byte 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00
	.byte 0x04, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00
	.byte 0x40, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00
	.byte 0x00, 0x04, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00
	.byte 0x00, 0x40, 0x00, 0x00, 0x00, 0x80
	.byte 0x11, 0x32, 0x00, 0x0c, 0x14, 0x32, 0x5d, 0x00, 0x00, 0x00, 0x00, 0x00

	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA65B-0xEDA66C (17 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=60% dist=7 near Protocol_values_for_LED_rows_0x3E+7
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA675-0xEDA68D (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near Protocol_values_for_LED_rows_0x56+9
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA696-0xEDA6AE (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near Protocol_values_for_LED_rows_0x56+42
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA6B7-0xEDA6CF (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near Protocol_values_for_LED_rows_0x56+75
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA6D8-0xEDA6F8 (32 B), unreached CODE-territory, was disassembled as 21 plausible-but-dead instruction lines; per=100% dist=11 near Protocol_values_for_LED_rows_0x56+108
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA700-0xEDA710 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=6 near Protocol_values_for_LED_rows_0x56+148
	.byte 0x00, 0x00, 0x63, 0x00, 0x10, 0x18, 0x00, 0x61, 0x18, 0x63, 0x5e, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA718-0xEDA728 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+172
	.byte 0x00, 0x00, 0x63, 0x00, 0x12, 0x02, 0x00, 0x2d, 0x0c, 0x32, 0x50, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA730-0xEDA740 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=7 near Protocol_values_for_LED_rows_0x56+196
	.byte 0x00, 0x00, 0x63, 0x00, 0x14, 0x2e, 0x00, 0x1d, 0x14, 0x3a, 0x50, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x15, 0x20, 0x00, 0x3c, 0x18, 0x50, 0x4e, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA760-0xEDA770 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+244
	.byte 0x00, 0x00, 0x63, 0x00, 0x16, 0x14, 0x00, 0x15, 0x18, 0x34, 0x49, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA778-0xEDA788 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=7 near Protocol_values_for_LED_rows_0x56+268
	.byte 0x00, 0x00, 0x63, 0x00, 0x18, 0x21, 0x00, 0x02, 0x00, 0x60, 0x4f, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x19, 0x2b, 0x00, 0x1a, 0x00, 0x05, 0x3a, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x1a, 0x0f, 0x00, 0x11, 0x15, 0x17, 0x4f, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x1b, 0x3c, 0x00, 0x1a, 0x12, 0x32, 0x56, 0x12, 0x54, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x02, 0x1c, 0x03, 0x97, 0x04, 0xd5, 0x05, 0xa2, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0xd8, 0x02, 0x84, 0x04, 0xc4, 0x06, 0x58, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x02, 0x43, 0x03, 0x2a, 0x04, 0x29, 0x04, 0xc0, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA820-0xEDA830 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=10 near Protocol_values_for_LED_rows_0x56+436
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x00, 0xce, 0x03, 0x98, 0x05, 0x18, 0x05
	.byte 0x68, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x00, 0x1c, 0x02, 0x54, 0x03, 0x14, 0x04, 0x02, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0xd8, 0x03, 0x98, 0x05, 0x02, 0x05, 0xd8, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x00, 0x12, 0x01, 0xa8, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0xc0, 0x03, 0x98, 0x05, 0x18, 0x06, 0x54, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0x1d, 0x04, 0xea, 0x05, 0xf0, 0x06, 0xb0, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA8B0-0xEDA8C0 (16 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=100% dist=7 near Protocol_values_for_LED_rows_0x56+580
	.byte 0x00, 0x00, 0x63, 0x00, 0x14, 0x36, 0x00, 0x0b, 0x14, 0x32, 0x4a, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0x1b, 0x02, 0x8e, 0x03, 0x58, 0x04, 0x0f, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA8E0-0xEDA8F0 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=7 near Protocol_values_for_LED_rows_0x56+628
	.byte 0x00, 0x00, 0x63, 0x00, 0x10, 0x02, 0x00, 0x35, 0x00, 0x54, 0x64, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0x11, 0x02, 0x83, 0x03, 0x4c, 0x05, 0xe8, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
	.byte 0x10, 0x1c, 0x00, 0x56, 0x00, 0x52, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x02, 0x58, 0x03, 0x18, 0x03, 0xe8, 0x05, 0x0c, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA940-0xEDA950 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+724
	.byte 0x00, 0x00, 0x63, 0x00, 0x12, 0x23, 0x00, 0x31, 0x0c, 0x32, 0x4e, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0x98, 0x02, 0x4b, 0x03, 0xca, 0x05, 0x10, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA970-0xEDA980 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+772
	.byte 0x00, 0x00, 0x63, 0x00, 0x16, 0x2d, 0x00, 0x3a, 0x0c, 0x32, 0x52, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0x98, 0x02, 0x58, 0x04, 0x21, 0x05, 0x22, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA9A0-0xEDA9B0 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+820
	.byte 0x00, 0x00, 0x63, 0x00, 0x18, 0x29, 0x00, 0x19, 0x14, 0x32, 0x4a, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0xd8, 0x03, 0x98, 0x04, 0x18, 0x04, 0x8e, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA9D0-0xEDA9E0 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+868
	.byte 0x00, 0x00, 0x63, 0x00, 0x19, 0x13, 0x00, 0x12, 0x0a, 0x57, 0x3f, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x01, 0xd8, 0x03, 0x8b, 0x04, 0x5e, 0x05, 0xd8, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDAA00-0xEDAA10 (16 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+916
	.byte 0x00, 0x00, 0x63, 0x00, 0x1b, 0x34, 0x00, 0x59, 0x12, 0x32, 0x4f, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x02, 0x8b, 0x03, 0x92, 0x05, 0x22, 0x05, 0xd1, 0x54, 0x00, 0x00
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDAA30-0xEDAA40 (16 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near Protocol_values_for_LED_rows_0x56+964
	.byte 0x00, 0x00, 0x63, 0x00, 0x11, 0x23, 0x00, 0x47, 0x14, 0x32, 0x69, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x4f, 0x02, 0x53, 0x02, 0x83, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00
SoundProgram_DispatchTable:
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ExtData_ToneParam_DispatchHandler
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long FileIO_AllocBuffer
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_ToneParam_CheckMode
	.long ExtData_ToneParam_AltDispatch
	.long ExtData_ToneParam_AltDispatch
	.long ExtData_ToneParam_AltDispatch
	.long ExtData_ToneParam_AltEntry
	.long ExtData_ToneParam_AltBody
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_CheckMode
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_RetEntry
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_MixedHandler
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_CheckMode3
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_RetEntry2
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_ToneParam_MultiChannel
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_FullHandler
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_CopyAndJump
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ExtData_Voice_CompareAndDispatch
	.long MidiCh_IterateVolume_Reverse
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateExpression
	.long MidiCh_IteratePan_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long MidiCh_IterateVolume_Forward
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.long ToshiCmd_DefaultHandler_Ret
	.byte 0xb6, 0xf9, 0x00, 0x00
	.byte 0xd0, 0xf9, 0x00, 0x00, 0xea, 0xf9, 0x00, 0x00
	.byte 0x04, 0xfa, 0x00, 0x00, 0x1e, 0xfa, 0x00, 0x00
	.byte 0x38, 0xfa, 0x00, 0x00, 0x52, 0xfa, 0x00, 0x00
	.byte 0x6c, 0xfa, 0x00, 0x00, 0x86, 0xfa, 0x00, 0x00
	.byte 0xa0, 0xfa, 0x00, 0x00, 0xba, 0xfa, 0x00, 0x00
	.byte 0xd4, 0xfa, 0x00, 0x00, 0xee, 0xfa, 0x00, 0x00
	.byte 0x08, 0xfb, 0x00, 0x00, 0x22, 0xfb, 0x00, 0x00
	.byte 0x3c, 0xfb, 0x00, 0x00, 0x56, 0xfb, 0x00, 0x00
	.byte 0x70, 0xfb, 0x00, 0x00, 0x8a, 0xfb, 0x00, 0x00
	.byte 0xa4, 0xfb, 0x00, 0x00, 0xbe, 0xfb, 0x00, 0x00
	.byte 0xd8, 0xfb, 0x00, 0x00, 0xf2, 0xfb, 0x00, 0x00
	.byte 0x62, 0xfd, 0x00, 0x00, 0x7c, 0xfd, 0x00, 0x00
	.byte 0x0c, 0xfc, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0x54, 0xfc, 0x00, 0x00, 0x26, 0xfc, 0x00, 0x00
	.byte 0x32, 0xfc, 0x00, 0x00, 0x3e, 0xfc, 0x00, 0x00
	.byte 0x4a, 0xfc, 0x00, 0x00, 0x5a, 0xfc, 0x00, 0x00
	.byte 0x92, 0xff, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x6e, 0xfc, 0x00, 0x00
	.byte 0x74, 0xfc, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x8e, 0xfc, 0x00, 0x00, 0xa8, 0xfc, 0x00, 0x00
	.byte 0xc2, 0xfc, 0x00, 0x00, 0xdc, 0xfc, 0x00, 0x00
	.byte 0xff, 0xff, 0xff, 0xff, 0xf6, 0xfc, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x02, 0xfd, 0x00, 0x00
	.byte 0x2c, 0xfd, 0x00, 0x00, 0x0c, 0xfd, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xa2, 0xf9, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x50, 0xfd, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x66, 0xfc, 0x00, 0x00
	.byte 0xaa, 0xfd, 0x00, 0x00, 0x1c, 0xfd, 0x00, 0x00
	.byte 0xb6, 0xfd, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x96, 0xfd, 0x00, 0x00
	.byte 0x30, 0xfd, 0x00, 0x00, 0xa4, 0xff, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xda, 0xfd, 0x00, 0x00
	.byte 0xee, 0xfd, 0x00, 0x00, 0x02, 0xfe, 0x00, 0x00
	.byte 0x16, 0xfe, 0x00, 0x00, 0x2a, 0xfe, 0x00, 0x00
	.byte 0x3e, 0xfe, 0x00, 0x00, 0x52, 0xfe, 0x00, 0x00
	.byte 0x66, 0xfe, 0x00, 0x00, 0x7a, 0xfe, 0x00, 0x00
	.byte 0x8e, 0xfe, 0x00, 0x00, 0xa2, 0xfe, 0x00, 0x00
	.byte 0xb6, 0xfe, 0x00, 0x00, 0xca, 0xfe, 0x00, 0x00
	.byte 0xde, 0xfe, 0x00, 0x00, 0xf2, 0xfe, 0x00, 0x00
	.byte 0x06, 0xff, 0x00, 0x00, 0x1a, 0xff, 0x00, 0x00
	.byte 0x2e, 0xff, 0x00, 0x00, 0x42, 0xff, 0x00, 0x00
	.byte 0x56, 0xff, 0x00, 0x00, 0x6a, 0xff, 0x00, 0x00
	.byte 0x1a, 0xff, 0x00, 0x00, 0x56, 0xff, 0x00, 0x00
	.byte 0x7e, 0xff, 0x00, 0x00, 0x7e, 0xff, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xda, 0xfd, 0x00, 0x00
	.byte 0xee, 0xfd, 0x00, 0x00, 0x02, 0xfe, 0x00, 0x00
	.byte 0x16, 0xfe, 0x00, 0x00, 0x2a, 0xfe, 0x00, 0x00
	.byte 0x3e, 0xfe, 0x00, 0x00, 0x52, 0xfe, 0x00, 0x00
	.byte 0x66, 0xfe, 0x00, 0x00, 0x7a, 0xfe, 0x00, 0x00
	.byte 0x8e, 0xfe, 0x00, 0x00, 0xa2, 0xfe, 0x00, 0x00
	.byte 0xb6, 0xfe, 0x00, 0x00, 0xca, 0xfe, 0x00, 0x00
	.byte 0xde, 0xfe, 0x00, 0x00, 0xf2, 0xfe, 0x00, 0x00
	.byte 0x06, 0xff, 0x00, 0x00, 0x1a, 0xff, 0x00, 0x00
	.byte 0x2e, 0xff, 0x00, 0x00, 0x42, 0xff, 0x00, 0x00
	.byte 0x56, 0xff, 0x00, 0x00, 0x6a, 0xff, 0x00, 0x00
	.byte 0x1a, 0xff, 0x00, 0x00, 0x56, 0xff, 0x00, 0x00
	.byte 0x7e, 0xff, 0x00, 0x00, 0x7e, 0xff, 0x00, 0x00
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x49, 0x7c, 0xfc, 0x00
	.long Audio_ReinitToneGenAndOutput
	.long Audio_ResetAfterPayloadError
	.long Audio_FullReinitWithPreset
	.byte 0x50, 0x00, 0x43, 0x01
	.byte 0x3c, 0x7f, 0x00, 0x00, 0x20, 0x00, 0x20, 0x00
	.byte 0x02, 0x00, 0x05, 0x00, 0x08, 0x00, 0x0b, 0x00
	.byte 0x0e, 0x00, 0x11, 0x00, 0x14, 0x00, 0x17, 0x00
	.byte 0x1a, 0x00, 0x00, 0x00, 0x02, 0x00, 0x02, 0x00
	.byte 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00
	.byte 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00
	.byte 0x10, 0x00, 0x02, 0x00, 0x04, 0x00, 0x07, 0x00
	.byte 0x07, 0x00, 0x0a, 0x00, 0x0d, 0x00, 0x01, 0x01
	.byte 0x02, 0x03, 0x00, 0x01, 0x02, 0x04, 0x00, 0x01
	.byte 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
	.byte 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11
	.byte 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0xff
	.byte 0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x04, 0x05, 0x06, 0x03, 0x0f, 0x15, 0x15, 0x19
	.byte 0x14, 0x0c, 0x0d, 0x0e, 0xec, 0xa6, 0xed, 0x00
Naka_ToshiParam_Table:
	.long ToshiParam_Entry_01
	.long ToshiParam_Entry_02
	.long ToshiParam_Entry_03
	.long ToshiParam_Entry_04
	.long ToshiParam_Entry_05
	.long ToshiParam_Entry_06
	.long ToshiParam_Entry_07
	.long ToshiParam_Entry_08
	.long ToshiParam_Entry_09
	.long ToshiParam_Entry_10
	.long ToshiParam_Entry_11
	.long ToshiParam_Entry_12
	.long ToshiParam_Entry_13
	.long ToshiParam_Entry_14
	.long ToshiParam_Entry_15
	.long ToshiParam_Entry_16
	.long ToshiParam_Entry_17
	.long ToshiParam_Entry_18
	.long ToshiParam_Entry_19
	.long ToshiParam_Entry_20
	.long ToshiParam_Entry_21
	.long ToshiParam_Entry_22
	.long ToshiParam_Entry_23
	.long ToshiParam_Entry_24
	.long ToshiParam_Entry_25
	.long ToshiParam_Entry_26
	.long ToshiParam_Entry_27
	.byte 0x5a, 0x5a, 0x00, 0x00
	.byte 0x48, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 16
	.byte 0x00, 0x00, 0x00, 0x00, 0x78, 0x12, 0x20, 0x20
	.asciz "              "
	.byte 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x7f, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x38
	.byte 0x00, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x01, 0x00, 0x01, 0x18, 0x38, 0x00, 0x00
	.byte 0x7f, 0x35, 0x00, 0x00, 0x5a, 0x50, 0x40, 0x80, 0x02, 0x38, 0x01, 0x80, 0x00, 0x00, 0x80, 0x80
	.byte 0x80, 0x80, 0x00, 0x01, 0x00, 0x02, 0x18, 0x06, 0x00, 0x00, 0x71, 0x45, 0x00, 0x00, 0x5a, 0x30
	.byte 0x40, 0x80, 0x02, 0x00, 0x02, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x03
	.byte 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x03, 0x80
	.byte 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x04, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35
	.byte 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x04, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80
	.byte 0x00, 0x00, 0x00, 0x05, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80
	.byte 0x02, 0x20, 0x05, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x06, 0x18, 0x00
	.byte 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x06, 0x80, 0x00, 0x00
	.byte 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x07, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00
	.byte 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x07, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00
	.byte 0x00, 0x08, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20
	.byte 0x08, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x09, 0x18, 0x00, 0x00, 0x00
	.byte 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x09, 0x80, 0x00, 0x00, 0x80, 0x80
	.byte 0x80, 0x80, 0x00, 0x00, 0x00, 0x0a, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40
	.byte 0x40, 0x80, 0x02, 0x20, 0x0a, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0b
	.byte 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0b, 0x80
	.byte 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0c, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35
	.byte 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0c, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80
	.byte 0x00, 0x00, 0x00, 0x0d, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80
	.byte 0x02, 0x20, 0x0d, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0e, 0x18, 0x00
	.byte 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0e, 0x80, 0x00, 0x00
	.byte 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0f, 0x18, 0xf0, 0x00, 0x00, 0x64, 0x25, 0x00, 0x00
	.byte 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0x0f, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00
	.byte 0x00, 0x10, 0x18, 0x06, 0x00, 0x00, 0x71, 0x55, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00
	.byte 0xc4, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x11, 0x18, 0x1a, 0x00, 0x00
	.byte 0x71, 0x55, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc8, 0x80, 0x00, 0x00, 0x80, 0x80
	.byte 0x80, 0x80, 0x00, 0x00, 0x00, 0x12, 0x18, 0x64, 0x00, 0x00, 0x71, 0x15, 0x00, 0x00, 0x5a, 0x40
	.byte 0x40, 0x80, 0x02, 0x00, 0xc9, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x13
	.byte 0x18, 0x28, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc2, 0x80
	.byte 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x14, 0x18, 0xf0, 0x00, 0x00, 0x76, 0x05
	.byte 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xce, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80
	.byte 0x00, 0x00, 0x00, 0x15, 0x18, 0x06, 0x00, 0x00, 0x71, 0x45, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80
	.byte 0x02, 0x00, 0xc4, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x16, 0x18, 0x28
	.byte 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc0, 0x80, 0x00, 0x00
	.byte 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x19, 0x18, 0x00, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00
	.byte 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xcf, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00
	.byte 0x00, 0x44, 0x0a, 0x00, 0x00, 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x45, 0x0a, 0x00
	.byte 0x00, 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x46, 0x0a, 0x00, 0x00, 0x00, 0x88, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x00, 0x47, 0x08, 0xff, 0x00, 0x00, 0x00, 0xc0, 0x00, 0xff, 0xff, 0x43
	.byte 0x04, 0x80, 0x3c, 0x00, 0x00, 0x48, 0x0a, 0x60, 0x02, 0x00, 0xe8, 0x00, 0x00, 0x00, 0x00, 0x78
	.byte 0x00, 0x90, 0x06, 0x01, 0x00, 0x67, 0x00, 0x40, 0x00, 0x60, 0x04, 0x00, 0x80, 0x00, 0x00, 0x61
	.byte 0x18, 0x01, 0x1e, 0x06, 0x00, 0x54, 0x4b, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x63, 0x18, 0x14, 0x23, 0x00, 0x0b, 0x14, 0x32
	.byte 0x46, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x63, 0x00, 0x64, 0x18, 0x4f, 0x01, 0xd8, 0x03
	.byte 0x98, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x63, 0x00, 0x65, 0x18, 0x39, 0x32
	.byte 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x66, 0x18
	.byte 0x58, 0x23, 0x03, 0x9c, 0x54, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x68, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x70, 0x08, 0x06, 0x3c
	.byte 0x05, 0xff, 0x07, 0x02, 0x04, 0x07, 0x72, 0x0e
	.byte 0x00, 0x00, 0x00, 0x76, 0x00, 0x00, 0x00, 0x5a
	.byte 0x1d, 0x45, 0x1d, 0x33, 0x00, 0x00, 0x92, 0x0e
	.byte 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x71, 0x02
	.byte 0x00, 0x00, 0x99, 0x1e, 0x00, 0x00, 0xb6, 0x00
	.byte 0x40, 0x96, 0x88, 0x90, 0x91, 0xb3, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x82, 0x01, 0x02, 0x81
	.byte 0x00, 0x10, 0x11, 0x12, 0x13, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x80, 0x0e, 0x00, 0x0c, 0x04, 0x45
	.byte 0x00, 0x20, 0xfa, 0xdf, 0xbf, 0x01, 0x00, 0x00
	.byte 0x50, 0x00, 0xff, 0xff, 0x17, 0x18, 0x00, 0x00
	.byte 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x00, 0xc0, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x18, 0x18
	.byte 0x00, 0x00, 0x00, 0x76, 0x05, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x00, 0xc1, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x98, 0x12, 0x40, 0x00, 0x00, 0x20, 0x76, 0x00
	.byte 0x00, 0x20, 0x5c, 0x01, 0x5a, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x91, 0x0a, 0x00, 0x00
	.zero 8
	.byte 0x93, 0x22, 0x06, 0x06, 0x7f, 0x7f, 0x02, 0x05
	.byte 0x94, 0x00, 0xff
	.ascii "                ??ÿÿÿ"
	.byte 0xff, 0x00, 0x00, 0x00, 0xc0, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xc1, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xc2, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xc3, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xc4, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xc5, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xc6, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xc7, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xc8, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xc9, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xca, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xcb, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xcc, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xcd, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xce, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xcf, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xd0, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xd1, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xd2, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xd3, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xd4, 0x12, 0x00, 0x00
	.zero 16
	.byte 0xd7, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x49, 0x10, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9a, 0x1a
	.zero 24
	.byte 0x00, 0x00, 0xff, 0xff, 0x48, 0x4b, 0x20, 0x00
	.zero 8
	.byte 0x00, 0xc0, 0x03, 0x50, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00
	.zero 8
	.byte 0x91, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00, 0x01, 0x07, 0x05, 0x00, 0x00, 0xff, 0xc0, 0xc1
	.byte 0xc3, 0xc4, 0xc6, 0xc8, 0xca, 0xcb, 0xcd, 0xcf, 0xd0, 0xd2, 0xd4, 0xd6, 0xd7, 0xd9, 0xdb, 0xdc
	.byte 0xde, 0xe0, 0xe2, 0xe3, 0xe5, 0xe7, 0xe8, 0xea, 0xec, 0xed, 0xef, 0xf1, 0xf3, 0xf4, 0xf6, 0xf8
	.byte 0xf9, 0xfb, 0xfd, 0xfe, 0x00, 0x02, 0x03, 0x05, 0x07, 0x08, 0x0a, 0x0c, 0x0d, 0x0f, 0x11, 0x12
	.byte 0x14, 0x16, 0x17, 0x19, 0x1b, 0x1c, 0x1e, 0x20
	.ascii "!#%&(*+-/023578:<=>?V"
	.byte 0xba, 0xed, 0x00
	.byte 0x4e, 0x00, 0x00, 0x26, 0x00, 0xff, 0x01, 0x00
	.byte 0x00, 0x00, 0x48, 0x05, 0x01, 0x00, 0x01, 0x00
	.byte 0x00, 0xff, 0x01, 0x01, 0x01, 0x00, 0x00, 0xff
;  22 x 18-byte sound-parameter descriptors, 0xEDBAC0-0xEDBC4C.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edbac0.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 22 labels are kept as absolute equates so the pointer table in
;  ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDBAC0:
	.incbin "includes/generated/sndparam_run_edbac0.bin"
VoiceCtrlR1_Entry_001 = SndParamRun_EDBAC0 + 0
VoiceCtrlR1_Entry_002 = SndParamRun_EDBAC0 + 18
VoiceCtrlR1_Entry_003 = SndParamRun_EDBAC0 + 36
VoiceCtrlR1_Entry_004 = SndParamRun_EDBAC0 + 54
VoiceCtrlR1_Entry_005 = SndParamRun_EDBAC0 + 72
VoiceCtrlR1_Entry_006 = SndParamRun_EDBAC0 + 90
VoiceCtrlR1_Entry_007 = SndParamRun_EDBAC0 + 108
VoiceCtrlR1_Entry_008 = SndParamRun_EDBAC0 + 126
VoiceCtrlR1_Entry_009 = SndParamRun_EDBAC0 + 144
VoiceCtrlR1_Entry_010 = SndParamRun_EDBAC0 + 162
VoiceCtrlR1_Entry_011 = SndParamRun_EDBAC0 + 180
VoiceCtrlR1_Entry_012 = SndParamRun_EDBAC0 + 198
VoiceCtrlR1_Entry_013 = SndParamRun_EDBAC0 + 216
VoiceCtrlR1_Entry_014 = SndParamRun_EDBAC0 + 234
VoiceCtrlR1_Entry_015 = SndParamRun_EDBAC0 + 252
VoiceCtrlR1_Entry_016 = SndParamRun_EDBAC0 + 270
VoiceCtrlR1_Entry_017 = SndParamRun_EDBAC0 + 288
VoiceCtrlR1_Entry_018 = SndParamRun_EDBAC0 + 306
VoiceCtrlR1_Entry_019 = SndParamRun_EDBAC0 + 324
VoiceCtrlR1_Entry_020 = SndParamRun_EDBAC0 + 342
VoiceCtrlR1_Entry_021 = SndParamRun_EDBAC0 + 360
VoiceCtrlR1_Entry_022 = SndParamRun_EDBAC0 + 378
VoiceCtrlR1_Entry_023:
	.byte 0x00, 0x01, 0x03, 0xff
WidgetParam_MidiCC_Program:
	.long VoiceCtrlR1_Entry_023
	.byte 0x03, 0x00, 0x00, 0x00, 0x00, 0xff
VoiceCtrlR1_Entry_024:
	.byte 0x02, 0x22, 0x00, 0x00, 0x80, 0x00, 0x08, 0x00, 0x01, 0x03, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
VoiceCtrlR1_Entry_025:
	.byte 0x03, 0x22, 0x00, 0x00, 0x80, 0x00, 0x10, 0x00, 0x01, 0x04, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
VoiceCtrlR1_Entry_026:
	.byte 0x05, 0x22, 0x00, 0x00, 0x80, 0x02, 0x18, 0x00, 0x03, 0x03, 0x00, 0x03, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x01, 0x03, 0xff
WidgetParam_MidiCC_BankSelect:
	.byte 0x90, 0xbc, 0xed, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0xff
;  78 x 18-byte sound-parameter descriptors, 0xEDBC9E-0xEDC21A.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edbc9e.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 78 record labels are kept as absolute equates so the pointer
;  table in ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDBC9E:
	.incbin "includes/generated/sndparam_run_edbc9e.bin"
VoiceCtrlR1_Entry_027 = SndParamRun_EDBC9E + 0
VoiceCtrlR1_Entry_028 = SndParamRun_EDBC9E + 18
VoiceCtrlR1_Entry_029 = SndParamRun_EDBC9E + 36
VoiceCtrlR1_Entry_030 = SndParamRun_EDBC9E + 54
VoiceCtrlR1_Entry_031 = SndParamRun_EDBC9E + 72
VoiceCtrlR1_Entry_032 = SndParamRun_EDBC9E + 90
VoiceCtrlR1_Entry_033 = SndParamRun_EDBC9E + 108
VoiceCtrlR1_Entry_034 = SndParamRun_EDBC9E + 126
VoiceCtrlR1_Entry_035 = SndParamRun_EDBC9E + 144
VoiceCtrlR1_Entry_036 = SndParamRun_EDBC9E + 162
VoiceCtrlR1_Entry_037 = SndParamRun_EDBC9E + 180
VoiceCtrlR1_Entry_038 = SndParamRun_EDBC9E + 198
VoiceCtrlR1_Entry_039 = SndParamRun_EDBC9E + 216
VoiceCtrlR1_Entry_040 = SndParamRun_EDBC9E + 234
VoiceCtrlR1_Entry_041 = SndParamRun_EDBC9E + 252
VoiceCtrlR1_Entry_042 = SndParamRun_EDBC9E + 270
VoiceCtrlR1_Entry_043 = SndParamRun_EDBC9E + 288
VoiceCtrlR1_Entry_044 = SndParamRun_EDBC9E + 306
VoiceCtrlR1_Entry_045 = SndParamRun_EDBC9E + 324
VoiceCtrlR1_Entry_046 = SndParamRun_EDBC9E + 342
VoiceCtrlR1_Entry_047 = SndParamRun_EDBC9E + 360
VoiceCtrlR1_Entry_048 = SndParamRun_EDBC9E + 378
VoiceCtrlR1_Entry_049 = SndParamRun_EDBC9E + 396
VoiceCtrlR1_Entry_050 = SndParamRun_EDBC9E + 414
VoiceCtrlR1_Entry_051 = SndParamRun_EDBC9E + 432
VoiceCtrlR1_Entry_052 = SndParamRun_EDBC9E + 450
VoiceCtrlR1_Entry_053 = SndParamRun_EDBC9E + 468
VoiceCtrlR1_Entry_054 = SndParamRun_EDBC9E + 486
VoiceCtrlR1_Entry_055 = SndParamRun_EDBC9E + 504
VoiceCtrlR1_Entry_056 = SndParamRun_EDBC9E + 522
VoiceCtrlR1_Entry_057 = SndParamRun_EDBC9E + 540
VoiceCtrlR1_Entry_058 = SndParamRun_EDBC9E + 558
VoiceCtrlR1_Entry_059 = SndParamRun_EDBC9E + 576
VoiceCtrlR1_Entry_060 = SndParamRun_EDBC9E + 594
VoiceCtrlR1_Entry_061 = SndParamRun_EDBC9E + 612
VoiceCtrlR1_Entry_062 = SndParamRun_EDBC9E + 630
VoiceCtrlR1_Entry_063 = SndParamRun_EDBC9E + 648
VoiceCtrlR1_Entry_064 = SndParamRun_EDBC9E + 666
VoiceCtrlR1_Entry_065 = SndParamRun_EDBC9E + 684
VoiceCtrlR1_Entry_066 = SndParamRun_EDBC9E + 702
VoiceCtrlR1_Entry_067 = SndParamRun_EDBC9E + 720
VoiceCtrlR1_Entry_068 = SndParamRun_EDBC9E + 738
VoiceCtrlR1_Entry_069 = SndParamRun_EDBC9E + 756
VoiceCtrlR1_Entry_070 = SndParamRun_EDBC9E + 774
VoiceCtrlR1_Entry_071 = SndParamRun_EDBC9E + 792
VoiceCtrlR1_Entry_072 = SndParamRun_EDBC9E + 810
VoiceCtrlR1_Entry_073 = SndParamRun_EDBC9E + 828
VoiceCtrlR1_Entry_074 = SndParamRun_EDBC9E + 846
VoiceCtrlR1_Entry_075 = SndParamRun_EDBC9E + 864
MidiChParam_Entry_001 = SndParamRun_EDBC9E + 882
MidiChParam_Entry_002 = SndParamRun_EDBC9E + 900
MidiChParam_Entry_003 = SndParamRun_EDBC9E + 918
MidiChParam_Entry_004 = SndParamRun_EDBC9E + 936
MidiChParam_Entry_005 = SndParamRun_EDBC9E + 954
MidiChParam_Entry_006 = SndParamRun_EDBC9E + 972
MidiChParam_Entry_007 = SndParamRun_EDBC9E + 990
MidiChParam_Entry_008 = SndParamRun_EDBC9E + 1008
MidiChParam_Entry_009 = SndParamRun_EDBC9E + 1026
MidiChParam_Entry_010 = SndParamRun_EDBC9E + 1044
MidiChParam_Entry_011 = SndParamRun_EDBC9E + 1062
MidiChParam_Entry_012 = SndParamRun_EDBC9E + 1080
MidiChParam_Entry_013 = SndParamRun_EDBC9E + 1098
MidiChParam_Entry_014 = SndParamRun_EDBC9E + 1116
MidiChParam_Entry_015 = SndParamRun_EDBC9E + 1134
MidiChParam_Entry_016 = SndParamRun_EDBC9E + 1152
MidiChParam_Entry_017 = SndParamRun_EDBC9E + 1170
MidiChParam_Entry_018 = SndParamRun_EDBC9E + 1188
MidiChParam_Entry_019 = SndParamRun_EDBC9E + 1206
MidiChParam_Entry_020 = SndParamRun_EDBC9E + 1224
MidiChParam_Entry_021 = SndParamRun_EDBC9E + 1242
MidiChParam_Entry_022 = SndParamRun_EDBC9E + 1260
MidiChParam_Entry_023 = SndParamRun_EDBC9E + 1278
MidiChParam_Entry_024 = SndParamRun_EDBC9E + 1296
MidiChParam_Entry_025 = SndParamRun_EDBC9E + 1314
MidiChParam_Entry_026 = SndParamRun_EDBC9E + 1332
MidiChParam_Entry_027 = SndParamRun_EDBC9E + 1350
MidiChParam_Entry_028 = SndParamRun_EDBC9E + 1368
MidiChParam_Entry_029 = SndParamRun_EDBC9E + 1386
MidiChParam_Entry_030:
	.byte 0x0a, 0x2d, 0x00, 0x00, 0x47, 0x05, 0x7f, 0x00, 0x79, 0x00, 0x00, 0x0a, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x0f, 0x1d, 0x1e, 0x1f, 0x20
	.ascii "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyÿ"
WidgetParam_MidiCC_NameEdit:
	.byte 0x2c, 0xc2, 0xed, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x00, 0xff
;  22 x 18-byte sound-parameter descriptors, 0xEDC2A4-0xEDC430.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edc2a4.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 22 labels are kept as absolute equates so the pointer table in
;  ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDC2A4:
	.incbin "includes/generated/sndparam_run_edc2a4.bin"
MidiChParam_Entry_031 = SndParamRun_EDC2A4 + 0
MidiChParam_Entry_032 = SndParamRun_EDC2A4 + 18
MidiChParam_Entry_033 = SndParamRun_EDC2A4 + 36
MidiChParam_Entry_034 = SndParamRun_EDC2A4 + 54
MidiChParam_Entry_035 = SndParamRun_EDC2A4 + 72
MidiChParam_Entry_036 = SndParamRun_EDC2A4 + 90
MidiChParam_Entry_037 = SndParamRun_EDC2A4 + 108
MidiChParam_Entry_038 = SndParamRun_EDC2A4 + 126
MidiChParam_Entry_039 = SndParamRun_EDC2A4 + 144
MidiChParam_Entry_040 = SndParamRun_EDC2A4 + 162
MidiChParam_Entry_041 = SndParamRun_EDC2A4 + 180
MidiChParam_Entry_042 = SndParamRun_EDC2A4 + 198
MidiChParam_Entry_043 = SndParamRun_EDC2A4 + 216
MidiChParam_Entry_044 = SndParamRun_EDC2A4 + 234
MidiChParam_Entry_045 = SndParamRun_EDC2A4 + 252
MidiChParam_Entry_046 = SndParamRun_EDC2A4 + 270
MidiChParam_Entry_047 = SndParamRun_EDC2A4 + 288
MidiChParam_Entry_048 = SndParamRun_EDC2A4 + 306
MidiChParam_Entry_049 = SndParamRun_EDC2A4 + 324
MidiChParam_Entry_050 = SndParamRun_EDC2A4 + 342
MidiChParam_Entry_051 = SndParamRun_EDC2A4 + 360
MidiChParam_Entry_052 = SndParamRun_EDC2A4 + 378
WidgetParam_MidiCC_SysExcl:
	.byte 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x03, 0x02, 0x01, 0x02, 0x02, 0x02
MidiChParam_Entry_053:
	.byte 0x40, 0x41, 0x00, 0x00, 0x43, 0x00, 0x80, 0x00, 0x01, 0x07, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_054:
	.byte 0x41, 0x41, 0x00, 0x00, 0x43, 0x01, 0x7f, 0x00, 0x7f, 0x00, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_055:
	.byte 0x42, 0x41, 0x00, 0x00, 0x43, 0x01, 0x80, 0x00, 0x01, 0x07, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_056:
	.byte 0x80, 0x41, 0x00, 0x00, 0x70, 0x00, 0x03, 0x00, 0x03, 0x00, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_057:
	.byte 0x81, 0x41, 0x00, 0x00, 0x70, 0x01, 0x7f, 0x15, 0x6c, 0x00, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_058:
	.byte 0x00, 0x42, 0x00, 0x00, 0x48, 0x04, 0x40, 0x00, 0x01, 0x06, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_059:
	.byte 0x01, 0x42, 0x00, 0x00, 0x70, 0x03, 0xff, 0x00, 0xff, 0x00, 0x00, 0x06, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0xff, 0x00, 0x01, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0xff
WidgetParam_MidiCC_Volume:
	.byte 0xba, 0xc4, 0xed, 0x00, 0x0f, 0x00, 0xff, 0x00, 0x00, 0xff
MidiChParam_Entry_060:
	.byte 0x02, 0x42, 0x00, 0x00, 0x70, 0x04, 0x0f, 0x00, 0x0d, 0x00, 0x00, 0x08, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x01, 0x02, 0x0d, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
WidgetParam_MidiCC_Pan:
	.byte 0xe6, 0xc4, 0xed, 0x00, 0x0e, 0x00, 0x07, 0x08, 0x00, 0xff
MidiChParam_Entry_061:
	.byte 0x80, 0x42, 0x00, 0x00, 0x92, 0x01, 0x80, 0x00, 0x01, 0x07, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_062:
	.byte 0x81, 0x42, 0x00, 0x00, 0x92, 0x00, 0xff, 0x00, 0x80, 0x00, 0x00, 0x04, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x40, 0x41, 0x42, 0x03, 0x04, 0x05, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16
	.byte 0x80, 0xff
WidgetParam_MidiCC_Expression:
	.byte 0x22, 0xc5, 0xed, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00, 0xff
MidiChParam_Entry_063:
	.byte 0x82, 0x42, 0x00, 0x00, 0x92, 0x01, 0x0f, 0x00, 0x0b, 0x00, 0x00, 0xff, 0x01, 0x01, 0x01, 0x00
	.byte 0x00, 0xff
MidiChParam_Entry_064:
	.byte 0x83, 0x42, 0x00, 0x00, 0x92, 0x02, 0xff, 0x00, 0xff, 0x00, 0x00, 0x05, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x01, 0x03, 0x04, 0x05, 0x07, 0x08, 0x09, 0x0a, 0x0c, 0x0d, 0x0e, 0x0f, 0x11
	.byte 0x12, 0x13, 0x15, 0x16, 0x17, 0x18, 0x1a, 0x1b, 0x1c, 0x1d, 0x1f
	.ascii " !#$%&()*+-./12346789;<=?@ABDEFGIJKMNOPRSTUWXY[\\]^`abcefgijklnopqstuwxyz|}~€‚ƒ…†‡ˆŠ‹ŒŽ‘“”•–˜™šœžŸ¡¢"
	.byte 0xa3, 0xa4, 0xa6, 0xa7, 0xa8, 0xaa, 0xab, 0xac, 0xad, 0xaf, 0xb0, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6
	.byte 0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3, 0xc4, 0xc6, 0xc7, 0xc8, 0xc9, 0xcb
	.byte 0xcc, 0xcd, 0xce, 0xd0, 0xd1, 0xd2, 0xd4, 0xd5, 0xd6, 0xd7, 0xd9, 0xda, 0xdb, 0xdc, 0xde, 0xdf
	.byte 0xe0, 0xe2, 0xe3, 0xe4, 0xe5, 0xe7, 0xe8, 0xe9, 0xea, 0xec, 0xed, 0xee, 0xf0, 0xf1, 0xf2, 0xf3
	.byte 0xf5, 0xf6, 0xf7, 0xf8, 0xfa, 0xfb, 0xfc, 0xfe, 0xff, 0xff
WidgetParam_MidiCC_Sustain:
	.byte 0x60, 0xc5, 0xed, 0x00, 0xc9, 0x00, 0x80, 0x64, 0x00, 0xff
;  19 x 18-byte sound-parameter descriptors, 0xEDC634-0xEDC78A.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edc634.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 19 labels are kept as absolute equates so the pointer table in
;  ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDC634:
	.incbin "includes/generated/sndparam_run_edc634.bin"
MidiChParam_Entry_065 = SndParamRun_EDC634 + 0
MidiChParam_Entry_066 = SndParamRun_EDC634 + 18
MidiChParam_Entry_067 = SndParamRun_EDC634 + 36
MidiChParam_Entry_068 = SndParamRun_EDC634 + 54
MidiChParam_Entry_069 = SndParamRun_EDC634 + 72
MidiChParam_Entry_070 = SndParamRun_EDC634 + 90
MidiChParam_Entry_071 = SndParamRun_EDC634 + 108
MidiChParam_Entry_072 = SndParamRun_EDC634 + 126
MidiChParam_Entry_073 = SndParamRun_EDC634 + 144
MidiChParam_Entry_074 = SndParamRun_EDC634 + 162
MidiChParam_Entry_075 = SndParamRun_EDC634 + 180
MidiChParam_Entry_076 = SndParamRun_EDC634 + 198
MidiChParam_Entry_077 = SndParamRun_EDC634 + 216
MidiChParam_Entry_078 = SndParamRun_EDC634 + 234
MidiChParam_Entry_079 = SndParamRun_EDC634 + 252
MidiChParam_Entry_080 = SndParamRun_EDC634 + 270
MidiChParam_Entry_081 = SndParamRun_EDC634 + 288
MidiChParam_Entry_082 = SndParamRun_EDC634 + 306
MidiChParam_Entry_083 = SndParamRun_EDC634 + 324
MidiChParam_Entry_084:
	.byte 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd
	.byte 0xde, 0xdf, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed
	.byte 0xee, 0xef, 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd
	.byte 0xfe, 0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d
	.byte 0x1e, 0x1f
	.ascii " !\"#$%&'()*+,-./012ÿ"
WidgetParam_MidiCC_Reverb:
	.long MidiChParam_Entry_084
	.byte 0x65, 0x00, 0x00, 0x00, 0x00, 0xff
;  9 x 18-byte sound-parameter descriptors, 0xEDC7FA-0xEDC89C.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edc7fa.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 9 labels are kept as absolute equates so the pointer table in
;  ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDC7FA:
	.incbin "includes/generated/sndparam_run_edc7fa.bin"
MidiChParam_Entry_085 = SndParamRun_EDC7FA + 0
MidiChParam_Entry_086 = SndParamRun_EDC7FA + 18
MidiChParam_Entry_087 = SndParamRun_EDC7FA + 36
MidiChParam_Entry_088 = SndParamRun_EDC7FA + 54
MidiChParam_Entry_089 = SndParamRun_EDC7FA + 72
MidiChParam_Entry_090 = SndParamRun_EDC7FA + 90
MidiChParam_Entry_091 = SndParamRun_EDC7FA + 108
MidiChParam_Entry_092 = SndParamRun_EDC7FA + 126
MidiChParam_Entry_093 = SndParamRun_EDC7FA + 144
WidgetParam_MidiCC_Chorus:
	.byte 0x40, 0x00, 0x01, 0x00, 0x7f, 0x00, 0x01, 0xff
;  10 x 18-byte sound-parameter descriptors, 0xEDC8A4-0xEDC958.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edc8a4.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 10 labels are kept as absolute equates so the pointer table in
;  ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDC8A4:
	.incbin "includes/generated/sndparam_run_edc8a4.bin"
MidiChParam_Entry_094 = SndParamRun_EDC8A4 + 0
MidiChParam_Entry_095 = SndParamRun_EDC8A4 + 18
MidiChParam_Entry_096 = SndParamRun_EDC8A4 + 36
MidiChParam_Entry_097 = SndParamRun_EDC8A4 + 54
MidiChParam_Entry_098 = SndParamRun_EDC8A4 + 72
MidiChParam_Entry_099 = SndParamRun_EDC8A4 + 90
MidiChParam_Entry_100 = SndParamRun_EDC8A4 + 108
MidiChParam_Entry_101 = SndParamRun_EDC8A4 + 126
MidiChParam_Entry_102 = SndParamRun_EDC8A4 + 144
MidiChParam_Entry_103 = SndParamRun_EDC8A4 + 162
MidiChParam_Entry_104:
	.byte 0xcc, 0x82, 0x00, 0x00, 0x44, 0x01, 0x0f, 0x00, 0x0f, 0x00, 0x00, 0x09, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff
WidgetParam_MidiCC_DspEffect:
	.byte 0x6a, 0xc9, 0xed, 0x00, 0x0b, 0x00, 0x00, 0x05, 0x00, 0xff
;  460 x 18-byte sound-parameter descriptors, 0xEDC980-0xEDE9D8.
;  The record structure and every field name are in
;  audio/sndparam_records/run_edc980.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 460 record labels are kept as absolute equates so the pointer
;  table in ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDC980:
	.incbin "includes/generated/sndparam_run_edc980.bin"
MidiChParam_Entry_105 = SndParamRun_EDC980 + 0
MidiChParam_Entry_106 = SndParamRun_EDC980 + 18
MidiChParam_Entry_107 = SndParamRun_EDC980 + 36
MidiChParam_Entry_108 = SndParamRun_EDC980 + 54
MidiChParam_Entry_109 = SndParamRun_EDC980 + 72
MidiChParam_Entry_110 = SndParamRun_EDC980 + 90
MidiChParam_Entry_111 = SndParamRun_EDC980 + 108
MidiChParam_Entry_112 = SndParamRun_EDC980 + 126
VoiceParamEx_Entry_001 = SndParamRun_EDC980 + 144
VoiceParamEx_Entry_002 = SndParamRun_EDC980 + 162
VoiceParamEx_Entry_003 = SndParamRun_EDC980 + 180
VoiceParamEx_Entry_004 = SndParamRun_EDC980 + 198
VoiceParamEx_Entry_005 = SndParamRun_EDC980 + 216
VoiceParamEx_Entry_006 = SndParamRun_EDC980 + 234
VoiceParamEx_Entry_007 = SndParamRun_EDC980 + 252
VoiceParamEx_Entry_008 = SndParamRun_EDC980 + 270
VoiceParamEx_Entry_009 = SndParamRun_EDC980 + 288
VoiceParamEx_Entry_010 = SndParamRun_EDC980 + 306
VoiceParamEx_Entry_011 = SndParamRun_EDC980 + 324
VoiceParamEx_Entry_012 = SndParamRun_EDC980 + 342
VoiceParamEx_Entry_013 = SndParamRun_EDC980 + 360
VoiceParamEx_Entry_014 = SndParamRun_EDC980 + 378
VoiceParamEx_Entry_015 = SndParamRun_EDC980 + 396
VoiceParamEx_Entry_016 = SndParamRun_EDC980 + 414
VoiceParamEx_Entry_017 = SndParamRun_EDC980 + 432
VoiceParamEx_Entry_018 = SndParamRun_EDC980 + 450
VoiceParamEx_Entry_019 = SndParamRun_EDC980 + 468
VoiceParamEx_Entry_020 = SndParamRun_EDC980 + 486
VoiceParamEx_Entry_021 = SndParamRun_EDC980 + 504
VoiceParamEx_Entry_022 = SndParamRun_EDC980 + 522
VoiceParamEx_Entry_023 = SndParamRun_EDC980 + 540
VoiceParamEx_Entry_024 = SndParamRun_EDC980 + 558
VoiceParamEx_Entry_025 = SndParamRun_EDC980 + 576
VoiceParamEx_Entry_026 = SndParamRun_EDC980 + 594
VoiceParamEx_Entry_027 = SndParamRun_EDC980 + 612
VoiceParamEx_Entry_028 = SndParamRun_EDC980 + 630
VoiceParamEx_Entry_029 = SndParamRun_EDC980 + 648
VoiceParamEx_Entry_030 = SndParamRun_EDC980 + 666
VoiceParamEx_Entry_031 = SndParamRun_EDC980 + 684
VoiceParamEx_Entry_032 = SndParamRun_EDC980 + 702
VoiceParamEx_Entry_033 = SndParamRun_EDC980 + 720
VoiceParamEx_Entry_034 = SndParamRun_EDC980 + 738
VoiceParamEx_Entry_035 = SndParamRun_EDC980 + 756
VoiceParamEx_Entry_036 = SndParamRun_EDC980 + 774
VoiceParamEx_Entry_037 = SndParamRun_EDC980 + 792
VoiceParamEx_Entry_038 = SndParamRun_EDC980 + 810
VoiceParamEx_Entry_039 = SndParamRun_EDC980 + 828
VoiceParamEx_Entry_040 = SndParamRun_EDC980 + 846
VoiceParamEx_Entry_041 = SndParamRun_EDC980 + 864
VoiceParamEx_Entry_042 = SndParamRun_EDC980 + 882
VoiceParamEx_Entry_043 = SndParamRun_EDC980 + 900
VoiceParamEx_Entry_044 = SndParamRun_EDC980 + 918
VoiceParamEx_Entry_045 = SndParamRun_EDC980 + 936
VoiceParamEx_Entry_046 = SndParamRun_EDC980 + 954
VoiceParamEx_Entry_047 = SndParamRun_EDC980 + 972
VoiceParamEx_Entry_048 = SndParamRun_EDC980 + 990
VoiceParamEx_Entry_049 = SndParamRun_EDC980 + 1008
VoiceParamEx_Entry_050 = SndParamRun_EDC980 + 1026
VoiceParamEx_Entry_051 = SndParamRun_EDC980 + 1044
VoiceParamEx_Entry_052 = SndParamRun_EDC980 + 1062
VoiceParamEx_Entry_053 = SndParamRun_EDC980 + 1080
VoiceParamEx_Entry_054 = SndParamRun_EDC980 + 1098
VoiceParamEx_Entry_055 = SndParamRun_EDC980 + 1116
VoiceParamEx_Entry_056 = SndParamRun_EDC980 + 1134
VoiceParamEx_Entry_057 = SndParamRun_EDC980 + 1152
VoiceParamEx_Entry_058 = SndParamRun_EDC980 + 1170
VoiceParamEx_Entry_059 = SndParamRun_EDC980 + 1188
VoiceParamEx_Entry_060 = SndParamRun_EDC980 + 1206
VoiceParamEx_Entry_061 = SndParamRun_EDC980 + 1224
VoiceParamEx_Entry_062 = SndParamRun_EDC980 + 1242
VoiceParamEx_Entry_063 = SndParamRun_EDC980 + 1260
VoiceParamEx_Entry_064 = SndParamRun_EDC980 + 1278
VoiceParamEx_Entry_065 = SndParamRun_EDC980 + 1296
VoiceParamEx_Entry_066 = SndParamRun_EDC980 + 1314
VoiceParamEx_Entry_067 = SndParamRun_EDC980 + 1332
VoiceParamEx_Entry_068 = SndParamRun_EDC980 + 1350
VoiceParamEx_Entry_069 = SndParamRun_EDC980 + 1368
VoiceParamEx_Entry_070 = SndParamRun_EDC980 + 1386
VoiceParamEx_Entry_071 = SndParamRun_EDC980 + 1404
VoiceParamEx_Entry_072 = SndParamRun_EDC980 + 1422
VoiceParamEx_Entry_073 = SndParamRun_EDC980 + 1440
VoiceParamEx_Entry_074 = SndParamRun_EDC980 + 1458
VoiceParamEx_Entry_075 = SndParamRun_EDC980 + 1476
VoiceParamEx_Entry_076 = SndParamRun_EDC980 + 1494
VoiceParamEx_Entry_077 = SndParamRun_EDC980 + 1512
VoiceParamEx_Entry_078 = SndParamRun_EDC980 + 1530
VoiceParamEx_Entry_079 = SndParamRun_EDC980 + 1548
VoiceParamEx_Entry_080 = SndParamRun_EDC980 + 1566
VoiceParamEx_Entry_081 = SndParamRun_EDC980 + 1584
VoiceParamEx_Entry_082 = SndParamRun_EDC980 + 1602
VoiceParamEx_Entry_083 = SndParamRun_EDC980 + 1620
VoiceParamEx_Entry_084 = SndParamRun_EDC980 + 1638
VoiceParamEx_Entry_085 = SndParamRun_EDC980 + 1656
PartParam_Entry_001 = SndParamRun_EDC980 + 1674
PartParam_Entry_002 = SndParamRun_EDC980 + 1692
PartParam_Entry_003 = SndParamRun_EDC980 + 1710
PartParam_Entry_004 = SndParamRun_EDC980 + 1728
PartParam_Entry_005 = SndParamRun_EDC980 + 1746
PartParam_Entry_006 = SndParamRun_EDC980 + 1764
PartParam_Entry_007 = SndParamRun_EDC980 + 1782
PartParam_Entry_008 = SndParamRun_EDC980 + 1800
PartParam_Entry_009 = SndParamRun_EDC980 + 1818
PartParam_Entry_010 = SndParamRun_EDC980 + 1836
PartParam_Entry_011 = SndParamRun_EDC980 + 1854
PartParam_Entry_012 = SndParamRun_EDC980 + 1872
PartParam_Entry_013 = SndParamRun_EDC980 + 1890
PartParam_Entry_014 = SndParamRun_EDC980 + 1908
PartParam_Entry_015 = SndParamRun_EDC980 + 1926
PartParam_Entry_016 = SndParamRun_EDC980 + 1944
PartParam_Entry_017 = SndParamRun_EDC980 + 1962
PartParam_Entry_018 = SndParamRun_EDC980 + 1980
PartParam_Entry_019 = SndParamRun_EDC980 + 1998
PartParam_Entry_020 = SndParamRun_EDC980 + 2016
PartParam_Entry_021 = SndParamRun_EDC980 + 2034
PartParam_Entry_022 = SndParamRun_EDC980 + 2052
PartParam_Entry_023 = SndParamRun_EDC980 + 2070
PartParam_Entry_024 = SndParamRun_EDC980 + 2088
PartParam_Entry_025 = SndParamRun_EDC980 + 2106
PartParam_Entry_026 = SndParamRun_EDC980 + 2124
PartParam_Entry_027 = SndParamRun_EDC980 + 2142
PartParam_Entry_028 = SndParamRun_EDC980 + 2160
PartParam_Entry_029 = SndParamRun_EDC980 + 2178
PartParam_Entry_030 = SndParamRun_EDC980 + 2196
PartParam_Entry_031 = SndParamRun_EDC980 + 2214
PartParam_Entry_032 = SndParamRun_EDC980 + 2232
PartParam_Entry_033 = SndParamRun_EDC980 + 2250
PartParam_Entry_034 = SndParamRun_EDC980 + 2268
PartParam_Entry_035 = SndParamRun_EDC980 + 2286
PartParam_Entry_036 = SndParamRun_EDC980 + 2304
PartParam_Entry_037 = SndParamRun_EDC980 + 2322
PartParam_Entry_038 = SndParamRun_EDC980 + 2340
PartParam_Entry_039 = SndParamRun_EDC980 + 2358
PartParam_Entry_040 = SndParamRun_EDC980 + 2376
PartParam_Entry_041 = SndParamRun_EDC980 + 2394
PartParam_Entry_042 = SndParamRun_EDC980 + 2412
PartParam_Entry_043 = SndParamRun_EDC980 + 2430
PartParam_Entry_044 = SndParamRun_EDC980 + 2448
PartParam_Entry_045 = SndParamRun_EDC980 + 2466
PartParam_Entry_046 = SndParamRun_EDC980 + 2484
PartParam_Entry_047 = SndParamRun_EDC980 + 2502
PartParam_Entry_048 = SndParamRun_EDC980 + 2520
PartParam_Entry_049 = SndParamRun_EDC980 + 2538
PartParam_Entry_050 = SndParamRun_EDC980 + 2556
PartParam_Entry_051 = SndParamRun_EDC980 + 2574
PartParam_Entry_052 = SndParamRun_EDC980 + 2592
PartParam_Entry_053 = SndParamRun_EDC980 + 2610
PartParam_Entry_054 = SndParamRun_EDC980 + 2628
PartParam_Entry_055 = SndParamRun_EDC980 + 2646
PartParam_Entry_056 = SndParamRun_EDC980 + 2664
PartParam_Entry_057 = SndParamRun_EDC980 + 2682
PartParam_Entry_058 = SndParamRun_EDC980 + 2700
PartParam_Entry_059 = SndParamRun_EDC980 + 2718
PartParam_Entry_060 = SndParamRun_EDC980 + 2736
PartParam_Entry_061 = SndParamRun_EDC980 + 2754
PartParam_Entry_062 = SndParamRun_EDC980 + 2772
PartParam_Entry_063 = SndParamRun_EDC980 + 2790
PartParam_Entry_064 = SndParamRun_EDC980 + 2808
PartParam_Entry_065 = SndParamRun_EDC980 + 2826
PartParam_Entry_066 = SndParamRun_EDC980 + 2844
PartParam_Entry_067 = SndParamRun_EDC980 + 2862
PartParam_Entry_068 = SndParamRun_EDC980 + 2880
PartParam_Entry_069 = SndParamRun_EDC980 + 2898
PartParam_Entry_070 = SndParamRun_EDC980 + 2916
PartParam_Entry_071 = SndParamRun_EDC980 + 2934
PartParam_Entry_072 = SndParamRun_EDC980 + 2952
PartParam_Entry_073 = SndParamRun_EDC980 + 2970
PartParam_Entry_074 = SndParamRun_EDC980 + 2988
PartParam_Entry_075 = SndParamRun_EDC980 + 3006
PartParam_Entry_076 = SndParamRun_EDC980 + 3024
PartParam_Entry_077 = SndParamRun_EDC980 + 3042
PartParam_Entry_078 = SndParamRun_EDC980 + 3060
PartParam_Entry_079 = SndParamRun_EDC980 + 3078
PartParam_Entry_080 = SndParamRun_EDC980 + 3096
PartParam_Entry_081 = SndParamRun_EDC980 + 3114
PartParam_Entry_082 = SndParamRun_EDC980 + 3132
PartParam_Entry_083 = SndParamRun_EDC980 + 3150
PartParam_Entry_084 = SndParamRun_EDC980 + 3168
PartParam_Entry_085 = SndParamRun_EDC980 + 3186
PartParam_Entry_086 = SndParamRun_EDC980 + 3204
PartParam_Entry_087 = SndParamRun_EDC980 + 3222
PartParam_Entry_088 = SndParamRun_EDC980 + 3240
PartParam_Entry_089 = SndParamRun_EDC980 + 3258
PartParam_Entry_090 = SndParamRun_EDC980 + 3276
PartParam_Entry_091 = SndParamRun_EDC980 + 3294
PartParam_Entry_092 = SndParamRun_EDC980 + 3312
PartParam_Entry_093 = SndParamRun_EDC980 + 3330
PartParam_Entry_094 = SndParamRun_EDC980 + 3348
PartParam_Entry_095 = SndParamRun_EDC980 + 3366
PartParam_Entry_096 = SndParamRun_EDC980 + 3384
PartParam_Entry_097 = SndParamRun_EDC980 + 3402
PartParam_Entry_098 = SndParamRun_EDC980 + 3420
PartParam_Entry_099 = SndParamRun_EDC980 + 3438
PartParam_Entry_100 = SndParamRun_EDC980 + 3456
PartParam_Entry_101 = SndParamRun_EDC980 + 3474
PartParam_Entry_102 = SndParamRun_EDC980 + 3492
PartParam_Entry_103 = SndParamRun_EDC980 + 3510
PartParam_Entry_104 = SndParamRun_EDC980 + 3528
PartParam_Entry_105 = SndParamRun_EDC980 + 3546
PartParam_Entry_106 = SndParamRun_EDC980 + 3564
PartParam_Entry_107 = SndParamRun_EDC980 + 3582
PartParam_Entry_108 = SndParamRun_EDC980 + 3600
PartParam_Entry_109 = SndParamRun_EDC980 + 3618
PartParam_Entry_110 = SndParamRun_EDC980 + 3636
PartParam_Entry_111 = SndParamRun_EDC980 + 3654
PartParam_Entry_112 = SndParamRun_EDC980 + 3672
PartParam_Entry_113 = SndParamRun_EDC980 + 3690
PartParam_Entry_114 = SndParamRun_EDC980 + 3708
PartParam_Entry_115 = SndParamRun_EDC980 + 3726
PartParam_Entry_116 = SndParamRun_EDC980 + 3744
PartParam_Entry_117 = SndParamRun_EDC980 + 3762
PartParam_Entry_118 = SndParamRun_EDC980 + 3780
PartParam_Entry_119 = SndParamRun_EDC980 + 3798
PartParam_Entry_120 = SndParamRun_EDC980 + 3816
PartParam_Entry_121 = SndParamRun_EDC980 + 3834
PartParam_Entry_122 = SndParamRun_EDC980 + 3852
PartParam_Entry_123 = SndParamRun_EDC980 + 3870
PartParam_Entry_124 = SndParamRun_EDC980 + 3888
PartParam_Entry_125 = SndParamRun_EDC980 + 3906
PartParam_Entry_126 = SndParamRun_EDC980 + 3924
PartParam_Entry_127 = SndParamRun_EDC980 + 3942
PartParam_Entry_128 = SndParamRun_EDC980 + 3960
PartParam_Entry_129 = SndParamRun_EDC980 + 3978
PartParam_Entry_130 = SndParamRun_EDC980 + 3996
PartParam_Entry_131 = SndParamRun_EDC980 + 4014
PartParam_Entry_132 = SndParamRun_EDC980 + 4032
PartParam_Entry_133 = SndParamRun_EDC980 + 4050
PartParam_Entry_134 = SndParamRun_EDC980 + 4068
PartParam_Entry_135 = SndParamRun_EDC980 + 4086
PartParam_Entry_136 = SndParamRun_EDC980 + 4104
PartParam_Entry_137 = SndParamRun_EDC980 + 4122
PartParam_Entry_138 = SndParamRun_EDC980 + 4140
PartParam_Entry_139 = SndParamRun_EDC980 + 4158
PartParam_Entry_140 = SndParamRun_EDC980 + 4176
PartParam_Entry_141 = SndParamRun_EDC980 + 4194
PartParam_Entry_142 = SndParamRun_EDC980 + 4212
PartParam_Entry_143 = SndParamRun_EDC980 + 4230
PartParam_Entry_144 = SndParamRun_EDC980 + 4248
PartParam_Entry_145 = SndParamRun_EDC980 + 4266
PartParam_Entry_146 = SndParamRun_EDC980 + 4284
PartParam_Entry_147 = SndParamRun_EDC980 + 4302
PartParam_Entry_148 = SndParamRun_EDC980 + 4320
PartParam_Entry_149 = SndParamRun_EDC980 + 4338
PartParam_Entry_150 = SndParamRun_EDC980 + 4356
PartParam_Entry_151 = SndParamRun_EDC980 + 4374
PartParam_Entry_152 = SndParamRun_EDC980 + 4392
PartParam_Entry_153 = SndParamRun_EDC980 + 4410
PartParam_Entry_154 = SndParamRun_EDC980 + 4428
PartParam_Entry_155 = SndParamRun_EDC980 + 4446
PartParam_Entry_156 = SndParamRun_EDC980 + 4464
PartParam_Entry_157 = SndParamRun_EDC980 + 4482
PartParam_Entry_158 = SndParamRun_EDC980 + 4500
PartParam_Entry_159 = SndParamRun_EDC980 + 4518
PartParam_Entry_160 = SndParamRun_EDC980 + 4536
PartParam_Entry_161 = SndParamRun_EDC980 + 4554
PartParam_Entry_162 = SndParamRun_EDC980 + 4572
PartParam_Entry_163 = SndParamRun_EDC980 + 4590
PartParam_Entry_164 = SndParamRun_EDC980 + 4608
PartParam_Entry_165 = SndParamRun_EDC980 + 4626
PartParam_Entry_166 = SndParamRun_EDC980 + 4644
PartParam_Entry_167 = SndParamRun_EDC980 + 4662
PartParam_Entry_168 = SndParamRun_EDC980 + 4680
PartParam_Entry_169 = SndParamRun_EDC980 + 4698
PartParam_Entry_170 = SndParamRun_EDC980 + 4716
PartParam_Entry_171 = SndParamRun_EDC980 + 4734
PartParam_Entry_172 = SndParamRun_EDC980 + 4752
PartParam_Entry_173 = SndParamRun_EDC980 + 4770
PartParam_Entry_174 = SndParamRun_EDC980 + 4788
PartParam_Entry_175 = SndParamRun_EDC980 + 4806
PartParam_Entry_176 = SndParamRun_EDC980 + 4824
PartParam_Entry_177 = SndParamRun_EDC980 + 4842
PartParam_Entry_178 = SndParamRun_EDC980 + 4860
PartParam_Entry_179 = SndParamRun_EDC980 + 4878
PartParam_Entry_180 = SndParamRun_EDC980 + 4896
PartParam_Entry_181 = SndParamRun_EDC980 + 4914
PartParam_Entry_182 = SndParamRun_EDC980 + 4932
PartParam_Entry_183 = SndParamRun_EDC980 + 4950
PartParam_Entry_184 = SndParamRun_EDC980 + 4968
PartParam_Entry_185 = SndParamRun_EDC980 + 4986
PartParam_Entry_186 = SndParamRun_EDC980 + 5004
PartParam_Entry_187 = SndParamRun_EDC980 + 5022
PartParam_Entry_188 = SndParamRun_EDC980 + 5040
PartParam_Entry_189 = SndParamRun_EDC980 + 5058
PartParam_Entry_190 = SndParamRun_EDC980 + 5076
PartParam_Entry_191 = SndParamRun_EDC980 + 5094
PartParam_Entry_192 = SndParamRun_EDC980 + 5112
PartParam_Entry_193 = SndParamRun_EDC980 + 5130
PartParam_Entry_194 = SndParamRun_EDC980 + 5148
PartParam_Entry_195 = SndParamRun_EDC980 + 5166
PartParam_Entry_196 = SndParamRun_EDC980 + 5184
PartParam_Entry_197 = SndParamRun_EDC980 + 5202
PartParam_Entry_198 = SndParamRun_EDC980 + 5220
PartParam_Entry_199 = SndParamRun_EDC980 + 5238
PartParam_Entry_200 = SndParamRun_EDC980 + 5256
PartParam_Entry_201 = SndParamRun_EDC980 + 5274
PartParam_Entry_202 = SndParamRun_EDC980 + 5292
PartParam_Entry_203 = SndParamRun_EDC980 + 5310
PartParam_Entry_204 = SndParamRun_EDC980 + 5328
PartParam_Entry_205 = SndParamRun_EDC980 + 5346
PartParam_Entry_206 = SndParamRun_EDC980 + 5364
PartParam_Entry_207 = SndParamRun_EDC980 + 5382
PartParam_Entry_208 = SndParamRun_EDC980 + 5400
PartParam_Entry_209 = SndParamRun_EDC980 + 5418
PartParam_Entry_210 = SndParamRun_EDC980 + 5436
PartParam_Entry_211 = SndParamRun_EDC980 + 5454
PartParam_Entry_212 = SndParamRun_EDC980 + 5472
PartParam_Entry_213 = SndParamRun_EDC980 + 5490
PartParam_Entry_214 = SndParamRun_EDC980 + 5508
PartParam_Entry_215 = SndParamRun_EDC980 + 5526
PartParam_Entry_216 = SndParamRun_EDC980 + 5544
PartParam_Entry_217 = SndParamRun_EDC980 + 5562
PartParam_Entry_218 = SndParamRun_EDC980 + 5580
PartParam_Entry_219 = SndParamRun_EDC980 + 5598
PartParam_Entry_220 = SndParamRun_EDC980 + 5616
PartParam_Entry_221 = SndParamRun_EDC980 + 5634
PartParam_Entry_222 = SndParamRun_EDC980 + 5652
PartParam_Entry_223 = SndParamRun_EDC980 + 5670
PartParam_Entry_224 = SndParamRun_EDC980 + 5688
PartParam_Entry_225 = SndParamRun_EDC980 + 5706
PartParam_Entry_226 = SndParamRun_EDC980 + 5724
PartParam_Entry_227 = SndParamRun_EDC980 + 5742
ExtPartParam_Entry_228 = SndParamRun_EDC980 + 5760
ExtPartParam_Entry_229 = SndParamRun_EDC980 + 5778
ExtPartParam_Entry_230 = SndParamRun_EDC980 + 5796
ExtPartParam_Entry_231 = SndParamRun_EDC980 + 5814
ExtPartParam_Entry_232 = SndParamRun_EDC980 + 5832
ExtPartParam_Entry_233 = SndParamRun_EDC980 + 5850
ExtPartParam_Entry_234 = SndParamRun_EDC980 + 5868
ExtPartParam_Entry_235 = SndParamRun_EDC980 + 5886
ExtPartParam_Entry_236 = SndParamRun_EDC980 + 5904
ExtPartParam_Entry_237 = SndParamRun_EDC980 + 5922
ExtPartParam_Entry_238 = SndParamRun_EDC980 + 5940
ExtPartParam_Entry_239 = SndParamRun_EDC980 + 5958
ExtPartParam_Entry_240 = SndParamRun_EDC980 + 5976
ExtPartParam_Entry_241 = SndParamRun_EDC980 + 5994
ExtPartParam_Entry_242 = SndParamRun_EDC980 + 6012
ExtPartParam_Entry_243 = SndParamRun_EDC980 + 6030
ExtPartParam_Entry_244 = SndParamRun_EDC980 + 6048
ExtPartParam_Entry_245 = SndParamRun_EDC980 + 6066
ExtPartParam_Entry_246 = SndParamRun_EDC980 + 6084
ExtPartParam_Entry_247 = SndParamRun_EDC980 + 6102
ExtPartParam_Entry_248 = SndParamRun_EDC980 + 6120
ExtPartParam_Entry_249 = SndParamRun_EDC980 + 6138
ExtPartParam_Entry_250 = SndParamRun_EDC980 + 6156
ExtPartParam_Entry_251 = SndParamRun_EDC980 + 6174
ExtPartParam_Entry_252 = SndParamRun_EDC980 + 6192
ExtPartParam_Entry_253 = SndParamRun_EDC980 + 6210
ExtPartParam_Entry_254 = SndParamRun_EDC980 + 6228
ExtPartParam_Entry_255 = SndParamRun_EDC980 + 6246
ExtPartParam_Entry_256 = SndParamRun_EDC980 + 6264
ExtPartParam_Entry_257 = SndParamRun_EDC980 + 6282
ExtPartParam_Entry_258 = SndParamRun_EDC980 + 6300
ExtPartParam_Entry_259 = SndParamRun_EDC980 + 6318
ExtPartParam_Entry_260 = SndParamRun_EDC980 + 6336
ExtPartParam_Entry_261 = SndParamRun_EDC980 + 6354
ExtPartParam_Entry_262 = SndParamRun_EDC980 + 6372
ExtPartParam_Entry_263 = SndParamRun_EDC980 + 6390
ExtPartParam_Entry_264 = SndParamRun_EDC980 + 6408
ExtPartParam_Entry_265 = SndParamRun_EDC980 + 6426
ExtPartParam_Entry_266 = SndParamRun_EDC980 + 6444
ExtPartParam_Entry_267 = SndParamRun_EDC980 + 6462
ExtPartParam_Entry_268 = SndParamRun_EDC980 + 6480
ExtPartParam_Entry_269 = SndParamRun_EDC980 + 6498
ExtPartParam_Entry_270 = SndParamRun_EDC980 + 6516
ExtPartParam_Entry_271 = SndParamRun_EDC980 + 6534
ExtPartParam_Entry_272 = SndParamRun_EDC980 + 6552
ExtPartParam_Entry_273 = SndParamRun_EDC980 + 6570
ExtPartParam_Entry_274 = SndParamRun_EDC980 + 6588
ExtPartParam_Entry_275 = SndParamRun_EDC980 + 6606
ExtPartParam_Entry_276 = SndParamRun_EDC980 + 6624
ExtPartParam_Entry_277 = SndParamRun_EDC980 + 6642
ExtPartParam_Entry_278 = SndParamRun_EDC980 + 6660
ExtPartParam_Entry_279 = SndParamRun_EDC980 + 6678
ExtPartParam_Entry_280 = SndParamRun_EDC980 + 6696
ExtPartParam_Entry_281 = SndParamRun_EDC980 + 6714
ExtPartParam_Entry_282 = SndParamRun_EDC980 + 6732
ExtPartParam_Entry_283 = SndParamRun_EDC980 + 6750
ExtPartParam_Entry_284 = SndParamRun_EDC980 + 6768
ExtPartParam_Entry_285 = SndParamRun_EDC980 + 6786
ExtPartParam_Entry_286 = SndParamRun_EDC980 + 6804
ExtPartParam_Entry_287 = SndParamRun_EDC980 + 6822
ExtPartParam_Entry_288 = SndParamRun_EDC980 + 6840
ExtPartParam_Entry_289 = SndParamRun_EDC980 + 6858
ExtPartParam_Entry_290 = SndParamRun_EDC980 + 6876
ExtPartParam_Entry_291 = SndParamRun_EDC980 + 6894
ExtPartParam_Entry_292 = SndParamRun_EDC980 + 6912
ExtPartParam_Entry_293 = SndParamRun_EDC980 + 6930
ExtPartParam_Entry_294 = SndParamRun_EDC980 + 6948
ExtPartParam_Entry_295 = SndParamRun_EDC980 + 6966
ExtPartParam_Entry_296 = SndParamRun_EDC980 + 6984
ExtPartParam_Entry_297 = SndParamRun_EDC980 + 7002
ExtPartParam_Entry_298 = SndParamRun_EDC980 + 7020
ExtPartParam_Entry_299 = SndParamRun_EDC980 + 7038
ExtPartParam_Entry_300 = SndParamRun_EDC980 + 7056
ExtPartParam_Entry_301 = SndParamRun_EDC980 + 7074
ExtPartParam_Entry_302 = SndParamRun_EDC980 + 7092
ExtPartParam_Entry_303 = SndParamRun_EDC980 + 7110
ExtPartParam_Entry_304 = SndParamRun_EDC980 + 7128
ExtPartParam_Entry_305 = SndParamRun_EDC980 + 7146
ExtPartParam_Entry_306 = SndParamRun_EDC980 + 7164
ExtPartParam_Entry_307 = SndParamRun_EDC980 + 7182
ExtPartParam_Entry_308 = SndParamRun_EDC980 + 7200
ExtPartParam_Entry_309 = SndParamRun_EDC980 + 7218
ExtPartParam_Entry_310 = SndParamRun_EDC980 + 7236
ExtPartParam_Entry_311 = SndParamRun_EDC980 + 7254
ExtPartParam_Entry_312 = SndParamRun_EDC980 + 7272
ExtPartParam_Entry_313 = SndParamRun_EDC980 + 7290
ExtPartParam_Entry_314 = SndParamRun_EDC980 + 7308
ExtPartParam_Entry_315 = SndParamRun_EDC980 + 7326
ExtPartParam_Entry_316 = SndParamRun_EDC980 + 7344
ExtPartParam_Entry_317 = SndParamRun_EDC980 + 7362
ExtPartParam_Entry_318 = SndParamRun_EDC980 + 7380
ExtPartParam_Entry_319 = SndParamRun_EDC980 + 7398
ExtPartParam_Entry_320 = SndParamRun_EDC980 + 7416
ExtPartParam_Entry_321 = SndParamRun_EDC980 + 7434
ExtPartParam_Entry_322 = SndParamRun_EDC980 + 7452
ExtPartParam_Entry_323 = SndParamRun_EDC980 + 7470
ExtPartParam_Entry_324 = SndParamRun_EDC980 + 7488
ExtPartParam_Entry_325 = SndParamRun_EDC980 + 7506
ExtPartParam_Entry_326 = SndParamRun_EDC980 + 7524
ExtPartParam_Entry_327 = SndParamRun_EDC980 + 7542
ExtPartParam_Entry_328 = SndParamRun_EDC980 + 7560
ExtPartParam_Entry_329 = SndParamRun_EDC980 + 7578
ExtPartParam_Entry_330 = SndParamRun_EDC980 + 7596
ExtPartParam_Entry_331 = SndParamRun_EDC980 + 7614
ExtPartParam_Entry_332 = SndParamRun_EDC980 + 7632
ExtPartParam_Entry_333 = SndParamRun_EDC980 + 7650
ExtPartParam_Entry_334 = SndParamRun_EDC980 + 7668
ExtPartParam_Entry_335 = SndParamRun_EDC980 + 7686
ExtPartParam_Entry_336 = SndParamRun_EDC980 + 7704
ExtPartParam_Entry_337 = SndParamRun_EDC980 + 7722
ExtPartParam_Entry_338 = SndParamRun_EDC980 + 7740
ExtPartParam_Entry_339 = SndParamRun_EDC980 + 7758
ExtPartParam_Entry_340 = SndParamRun_EDC980 + 7776
ExtPartParam_Entry_341 = SndParamRun_EDC980 + 7794
ExtPartParam_Entry_342 = SndParamRun_EDC980 + 7812
ExtPartParam_Entry_343 = SndParamRun_EDC980 + 7830
ExtPartParam_Entry_344 = SndParamRun_EDC980 + 7848
ExtPartParam_Entry_345 = SndParamRun_EDC980 + 7866
ExtPartParam_Entry_346 = SndParamRun_EDC980 + 7884
ExtPartParam_Entry_347 = SndParamRun_EDC980 + 7902
ExtPartParam_Entry_348 = SndParamRun_EDC980 + 7920
ExtPartParam_Entry_349 = SndParamRun_EDC980 + 7938
ExtPartParam_Entry_350 = SndParamRun_EDC980 + 7956
ExtPartParam_Entry_351 = SndParamRun_EDC980 + 7974
ExtPartParam_Entry_352 = SndParamRun_EDC980 + 7992
ExtPartParam_Entry_353 = SndParamRun_EDC980 + 8010
ExtPartParam_Entry_354 = SndParamRun_EDC980 + 8028
ExtPartParam_Entry_355 = SndParamRun_EDC980 + 8046
ExtPartParam_Entry_356 = SndParamRun_EDC980 + 8064
ExtPartParam_Entry_357 = SndParamRun_EDC980 + 8082
ExtPartParam_Entry_358 = SndParamRun_EDC980 + 8100
ExtPartParam_Entry_359 = SndParamRun_EDC980 + 8118
ExtPartParam_Entry_360 = SndParamRun_EDC980 + 8136
ExtPartParam_Entry_361 = SndParamRun_EDC980 + 8154
ExtPartParam_Entry_362 = SndParamRun_EDC980 + 8172
ExtPartParam_Entry_363 = SndParamRun_EDC980 + 8190
ExtPartParam_Entry_364 = SndParamRun_EDC980 + 8208
ExtPartParam_Entry_365 = SndParamRun_EDC980 + 8226
ExtPartParam_Entry_366 = SndParamRun_EDC980 + 8244
ExtPartParam_Entry_367 = SndParamRun_EDC980 + 8262
ExtPartParam_Entry_368:
	.byte 0x04, 0x80, 0x01, 0x00, 0x00, 0x0c, 0x07, 0x00, 0x7f, 0x00, 0x00, 0x02, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x05, 0x06, 0x07, 0x00, 0x01, 0x02, 0x03, 0xff
WidgetParam_MidiCC_PitchBend:
	.byte 0xea, 0xe9, 0xed, 0x00, 0x07, 0x00, 0x00, 0x03, 0x00, 0xff
;  314 x 18-byte sound-parameter descriptors, 0xEDE9FC-0xEE0010.
;  The record structure and every field name are in
;  audio/sndparam_records/run_ede9fc.c + sndparam_types.h, which
;  `clang -target tlcs900` compiles to the byte-identical blob below.
;  The 314 record labels are kept as absolute equates so the pointer
;  table in ui_widgets/widget_dispatch.s still resolves them.
SndParamRun_EDE9FC:
	.incbin "includes/generated/sndparam_run_ede9fc.bin"
ExtPartParam_Entry_369 = SndParamRun_EDE9FC + 0
ExtPartParam_Entry_370 = SndParamRun_EDE9FC + 18
ExtPartParam_Entry_371 = SndParamRun_EDE9FC + 36
ExtPartParam_Entry_372 = SndParamRun_EDE9FC + 54
ExtPartParam_Entry_373 = SndParamRun_EDE9FC + 72
ExtPartParam_Entry_374 = SndParamRun_EDE9FC + 90
ExtPartParam_Entry_375 = SndParamRun_EDE9FC + 108
ExtPartParam_Entry_376 = SndParamRun_EDE9FC + 126
ExtPartParam_Entry_377 = SndParamRun_EDE9FC + 144
ExtPartParam_Entry_378 = SndParamRun_EDE9FC + 162
ExtPartParam_Entry_379 = SndParamRun_EDE9FC + 180
ExtPartParam_Entry_380 = SndParamRun_EDE9FC + 198
ExtPartParam_Entry_381 = SndParamRun_EDE9FC + 216
ExtPartParam_Entry_382 = SndParamRun_EDE9FC + 234
ExtPartParam_Entry_383 = SndParamRun_EDE9FC + 252
ExtPartParam_Entry_384 = SndParamRun_EDE9FC + 270
ExtPartParam_Entry_385 = SndParamRun_EDE9FC + 288
ExtPartParam_Entry_386 = SndParamRun_EDE9FC + 306
ExtPartParam_Entry_387 = SndParamRun_EDE9FC + 324
ExtPartParam_Entry_388 = SndParamRun_EDE9FC + 342
ExtPartParam_Entry_389 = SndParamRun_EDE9FC + 360
ExtPartParam_Entry_390 = SndParamRun_EDE9FC + 378
ExtPartParam_Entry_391 = SndParamRun_EDE9FC + 396
ExtPartParam_Entry_392 = SndParamRun_EDE9FC + 414
ExtPartParam_Entry_393 = SndParamRun_EDE9FC + 432
ExtPartParam_Entry_394 = SndParamRun_EDE9FC + 450
ExtPartParam_Entry_395 = SndParamRun_EDE9FC + 468
ExtPartParam_Entry_396 = SndParamRun_EDE9FC + 486
ExtPartParam_Entry_397 = SndParamRun_EDE9FC + 504
ExtPartParam_Entry_398 = SndParamRun_EDE9FC + 522
ExtPartParam_Entry_399 = SndParamRun_EDE9FC + 540
ExtPartParam_Entry_400 = SndParamRun_EDE9FC + 558
ExtPartParam_Entry_401 = SndParamRun_EDE9FC + 576
ExtPartParam_Entry_402 = SndParamRun_EDE9FC + 594
ExtPartParam_Entry_403 = SndParamRun_EDE9FC + 612
ExtPartParam_Entry_404 = SndParamRun_EDE9FC + 630
ExtPartParam_Entry_405 = SndParamRun_EDE9FC + 648
ExtPartParam_Entry_406 = SndParamRun_EDE9FC + 666
ExtPartParam_Entry_407 = SndParamRun_EDE9FC + 684
ExtPartParam_Entry_408 = SndParamRun_EDE9FC + 702
ExtPartParam_Entry_409 = SndParamRun_EDE9FC + 720
ExtPartParam_Entry_410 = SndParamRun_EDE9FC + 738
ExtPartParam_Entry_411 = SndParamRun_EDE9FC + 756
ExtPartParam_Entry_412 = SndParamRun_EDE9FC + 774
ExtPartParam_Entry_413 = SndParamRun_EDE9FC + 792
ExtPartParam_Entry_414 = SndParamRun_EDE9FC + 810
ExtPartParam_Entry_415 = SndParamRun_EDE9FC + 828
ExtPartParam_Entry_416 = SndParamRun_EDE9FC + 846
ExtPartParam_Entry_417 = SndParamRun_EDE9FC + 864
ExtPartParam_Entry_418 = SndParamRun_EDE9FC + 882
ExtPartParam_Entry_419 = SndParamRun_EDE9FC + 900
ExtPartParam_Entry_420 = SndParamRun_EDE9FC + 918
ExtPartParam_Entry_421 = SndParamRun_EDE9FC + 936
ExtPartParam_Entry_422 = SndParamRun_EDE9FC + 954
ExtPartParam_Entry_423 = SndParamRun_EDE9FC + 972
ExtPartParam_Entry_424 = SndParamRun_EDE9FC + 990
ExtPartParam_Entry_425 = SndParamRun_EDE9FC + 1008
ExtPartParam_Entry_426 = SndParamRun_EDE9FC + 1026
ExtPartParam_Entry_427 = SndParamRun_EDE9FC + 1044
ExtPartParam_Entry_428 = SndParamRun_EDE9FC + 1062
ExtPartParam_Entry_429 = SndParamRun_EDE9FC + 1080
ExtPartParam_Entry_430 = SndParamRun_EDE9FC + 1098
ExtPartParam_Entry_431 = SndParamRun_EDE9FC + 1116
ExtPartParam_Entry_432 = SndParamRun_EDE9FC + 1134
ExtPartParam_Entry_433 = SndParamRun_EDE9FC + 1152
ExtPartParam_Entry_434 = SndParamRun_EDE9FC + 1170
ExtPartParam_Entry_435 = SndParamRun_EDE9FC + 1188
ExtPartParam_Entry_436 = SndParamRun_EDE9FC + 1206
ExtPartParam_Entry_437 = SndParamRun_EDE9FC + 1224
ExtPartParam_Entry_438 = SndParamRun_EDE9FC + 1242
ExtPartParam_Entry_439 = SndParamRun_EDE9FC + 1260
ExtPartParam_Entry_440 = SndParamRun_EDE9FC + 1278
ExtPartParam_Entry_441 = SndParamRun_EDE9FC + 1296
ExtPartParam_Entry_442 = SndParamRun_EDE9FC + 1314
ExtPartParam_Entry_443 = SndParamRun_EDE9FC + 1332
ExtPartParam_Entry_444 = SndParamRun_EDE9FC + 1350
ExtPartParam_Entry_445 = SndParamRun_EDE9FC + 1368
ExtPartParam_Entry_446 = SndParamRun_EDE9FC + 1386
ExtPartParam_Entry_447 = SndParamRun_EDE9FC + 1404
ExtPartParam_Entry_448 = SndParamRun_EDE9FC + 1422
ExtPartParam_Entry_449 = SndParamRun_EDE9FC + 1440
ExtPartParam_Entry_450 = SndParamRun_EDE9FC + 1458
ExtPartParam_Entry_451 = SndParamRun_EDE9FC + 1476
ExtPartParam_Entry_452 = SndParamRun_EDE9FC + 1494
ExtPartParam_Entry_453 = SndParamRun_EDE9FC + 1512
ExtPartParam_Entry_454 = SndParamRun_EDE9FC + 1530
SeqMixParam_Entry_001 = SndParamRun_EDE9FC + 1548
SeqMixParam_Entry_002 = SndParamRun_EDE9FC + 1566
SeqMixParam_Entry_003 = SndParamRun_EDE9FC + 1584
SeqMixParam_Entry_004 = SndParamRun_EDE9FC + 1602
SeqMixParam_Entry_005 = SndParamRun_EDE9FC + 1620
SeqMixParam_Entry_006 = SndParamRun_EDE9FC + 1638
SeqMixParam_Entry_007 = SndParamRun_EDE9FC + 1656
SeqMixParam_Entry_008 = SndParamRun_EDE9FC + 1674
SeqMixParam_Entry_009 = SndParamRun_EDE9FC + 1692
SeqMixParam_Entry_010 = SndParamRun_EDE9FC + 1710
SeqMixParam_Entry_011 = SndParamRun_EDE9FC + 1728
SeqMixParam_Entry_012 = SndParamRun_EDE9FC + 1746
SeqMixParam_Entry_013 = SndParamRun_EDE9FC + 1764
SeqMixParam_Entry_014 = SndParamRun_EDE9FC + 1782
SeqMixParam_Entry_015 = SndParamRun_EDE9FC + 1800
SeqMixParam_Entry_016 = SndParamRun_EDE9FC + 1818
SeqMixParam_Entry_017 = SndParamRun_EDE9FC + 1836
SeqMixParam_Entry_018 = SndParamRun_EDE9FC + 1854
SeqMixParam_Entry_019 = SndParamRun_EDE9FC + 1872
SeqMixParam_Entry_020 = SndParamRun_EDE9FC + 1890
SeqMixParam_Entry_021 = SndParamRun_EDE9FC + 1908
SeqMixParam_Entry_022 = SndParamRun_EDE9FC + 1926
SeqMixParam_Entry_023 = SndParamRun_EDE9FC + 1944
SeqMixParam_Entry_024 = SndParamRun_EDE9FC + 1962
SeqMixParam_Entry_025 = SndParamRun_EDE9FC + 1980
SeqMixParam_Entry_026 = SndParamRun_EDE9FC + 1998
SeqMixParam_Entry_027 = SndParamRun_EDE9FC + 2016
SeqMixParam_Entry_028 = SndParamRun_EDE9FC + 2034
SeqMixParam_Entry_029 = SndParamRun_EDE9FC + 2052
SeqMixParam_Entry_030 = SndParamRun_EDE9FC + 2070
SeqMixParam_Entry_031 = SndParamRun_EDE9FC + 2088
SeqMixParam_Entry_032 = SndParamRun_EDE9FC + 2106
SeqMixParam_Entry_033 = SndParamRun_EDE9FC + 2124
SeqMixParam_Entry_034 = SndParamRun_EDE9FC + 2142
SeqMixParam_Entry_035 = SndParamRun_EDE9FC + 2160
SeqMixParam_Entry_036 = SndParamRun_EDE9FC + 2178
SeqMixParam_Entry_037 = SndParamRun_EDE9FC + 2196
SeqMixParam_Entry_038 = SndParamRun_EDE9FC + 2214
SeqMixParam_Entry_039 = SndParamRun_EDE9FC + 2232
SeqMixParam_Entry_040 = SndParamRun_EDE9FC + 2250
SeqMixParam_Entry_041 = SndParamRun_EDE9FC + 2268
SeqMixParam_Entry_042 = SndParamRun_EDE9FC + 2286
SeqMixParam_Entry_043 = SndParamRun_EDE9FC + 2304
SeqMixParam_Entry_044 = SndParamRun_EDE9FC + 2322
SeqMixParam_Entry_045 = SndParamRun_EDE9FC + 2340
SeqMixParam_Entry_046 = SndParamRun_EDE9FC + 2358
SeqMixParam_Entry_047 = SndParamRun_EDE9FC + 2376
SeqMixParam_Entry_048 = SndParamRun_EDE9FC + 2394
SeqMixParam_Entry_049 = SndParamRun_EDE9FC + 2412
SeqMixParam_Entry_050 = SndParamRun_EDE9FC + 2430
SeqMixParam_Entry_051 = SndParamRun_EDE9FC + 2448
SeqMixParam_Entry_052 = SndParamRun_EDE9FC + 2466
SeqMixParam_Entry_053 = SndParamRun_EDE9FC + 2484
SeqMixParam_Entry_054 = SndParamRun_EDE9FC + 2502
SeqMixParam_Entry_055 = SndParamRun_EDE9FC + 2520
SeqMixParam_Entry_056 = SndParamRun_EDE9FC + 2538
SeqMixParam_Entry_057 = SndParamRun_EDE9FC + 2556
SeqMixParam_Entry_058 = SndParamRun_EDE9FC + 2574
SeqMixParam_Entry_059 = SndParamRun_EDE9FC + 2592
SeqMixParam_Entry_060 = SndParamRun_EDE9FC + 2610
SeqMixParam_Entry_061 = SndParamRun_EDE9FC + 2628
SeqMixParam_Entry_062 = SndParamRun_EDE9FC + 2646
SeqMixParam_Entry_063 = SndParamRun_EDE9FC + 2664
SeqMixParam_Entry_064 = SndParamRun_EDE9FC + 2682
SeqMixParam_Entry_065 = SndParamRun_EDE9FC + 2700
SeqMixParam_Entry_066 = SndParamRun_EDE9FC + 2718
SeqMixParam_Entry_067 = SndParamRun_EDE9FC + 2736
SeqMixParam_Entry_068 = SndParamRun_EDE9FC + 2754
SeqMixParam_Entry_069 = SndParamRun_EDE9FC + 2772
SeqMixParam_Entry_070 = SndParamRun_EDE9FC + 2790
SeqMixParam_Entry_071 = SndParamRun_EDE9FC + 2808
SeqMixParam_Entry_072 = SndParamRun_EDE9FC + 2826
SeqMixParam_Entry_073 = SndParamRun_EDE9FC + 2844
SeqMixParam_Entry_074 = SndParamRun_EDE9FC + 2862
SeqMixParam_Entry_075 = SndParamRun_EDE9FC + 2880
SeqMixParam_Entry_076 = SndParamRun_EDE9FC + 2898
SeqMixParam_Entry_077 = SndParamRun_EDE9FC + 2916
SeqMixParam_Entry_078 = SndParamRun_EDE9FC + 2934
SeqMixParam_Entry_079 = SndParamRun_EDE9FC + 2952
SeqMixParam_Entry_080 = SndParamRun_EDE9FC + 2970
SeqMixParam_Entry_081 = SndParamRun_EDE9FC + 2988
SeqMixParam_Entry_082 = SndParamRun_EDE9FC + 3006
SeqMixParam_Entry_083 = SndParamRun_EDE9FC + 3024
SeqMixParam_Entry_084 = SndParamRun_EDE9FC + 3042
SeqMixParam_Entry_085 = SndParamRun_EDE9FC + 3060
SeqMixParam_Entry_086 = SndParamRun_EDE9FC + 3078
SeqMixParam_Entry_087 = SndParamRun_EDE9FC + 3096
SeqMixParam_Entry_088 = SndParamRun_EDE9FC + 3114
SeqMixParam_Entry_089 = SndParamRun_EDE9FC + 3132
SeqMixParam_Entry_090 = SndParamRun_EDE9FC + 3150
SeqMixParam_Entry_091 = SndParamRun_EDE9FC + 3168
SeqMixParam_Entry_092 = SndParamRun_EDE9FC + 3186
SeqMixParam_Entry_093 = SndParamRun_EDE9FC + 3204
SeqMixParam_Entry_094 = SndParamRun_EDE9FC + 3222
SeqMixParam_Entry_095 = SndParamRun_EDE9FC + 3240
SeqMixParam_Entry_096 = SndParamRun_EDE9FC + 3258
SeqMixParam_Entry_097 = SndParamRun_EDE9FC + 3276
SeqMixParam_Entry_098 = SndParamRun_EDE9FC + 3294
SeqMixParam_Entry_099 = SndParamRun_EDE9FC + 3312
SeqMixParam_Entry_100 = SndParamRun_EDE9FC + 3330
SeqMixParam_Entry_101 = SndParamRun_EDE9FC + 3348
SeqMixParam_Entry_102 = SndParamRun_EDE9FC + 3366
SeqMixParam_Entry_103 = SndParamRun_EDE9FC + 3384
SeqMixParam_Entry_104 = SndParamRun_EDE9FC + 3402
SeqMixParam_Entry_105 = SndParamRun_EDE9FC + 3420
SeqMixParam_Entry_106 = SndParamRun_EDE9FC + 3438
SeqMixParam_Entry_107 = SndParamRun_EDE9FC + 3456
SeqMixParam_Entry_108 = SndParamRun_EDE9FC + 3474
SeqMixParam_Entry_109 = SndParamRun_EDE9FC + 3492
SeqMixParam_Entry_110 = SndParamRun_EDE9FC + 3510
SeqMixParam_Entry_111 = SndParamRun_EDE9FC + 3528
SeqMixParam_Entry_112 = SndParamRun_EDE9FC + 3546
SeqMixParam_Entry_113 = SndParamRun_EDE9FC + 3564
SeqMixParam_Entry_114 = SndParamRun_EDE9FC + 3582
SeqMixParam_Entry_115 = SndParamRun_EDE9FC + 3600
SeqMixParam_Entry_116 = SndParamRun_EDE9FC + 3618
SeqMixParam_Entry_117 = SndParamRun_EDE9FC + 3636
SeqMixParam_Entry_118 = SndParamRun_EDE9FC + 3654
SeqMixParam_Entry_119 = SndParamRun_EDE9FC + 3672
SeqMixParam_Entry_120 = SndParamRun_EDE9FC + 3690
SeqMixParam_Entry_121 = SndParamRun_EDE9FC + 3708
SeqMixParam_Entry_122 = SndParamRun_EDE9FC + 3726
SeqMixParam_Entry_123 = SndParamRun_EDE9FC + 3744
SeqMixParam_Entry_124 = SndParamRun_EDE9FC + 3762
SeqMixParam_Entry_125 = SndParamRun_EDE9FC + 3780
SeqMixParam_Entry_126 = SndParamRun_EDE9FC + 3798
SeqMixParam_Entry_127 = SndParamRun_EDE9FC + 3816
SeqMixParam_Entry_128 = SndParamRun_EDE9FC + 3834
SeqMixParam_Entry_129 = SndParamRun_EDE9FC + 3852
SeqMixParam_Entry_130 = SndParamRun_EDE9FC + 3870
SeqMixParam_Entry_131 = SndParamRun_EDE9FC + 3888
SeqMixParam_Entry_132 = SndParamRun_EDE9FC + 3906
SeqMixParam_Entry_133 = SndParamRun_EDE9FC + 3924
SeqMixParam_Entry_134 = SndParamRun_EDE9FC + 3942
SeqMixParam_Entry_135 = SndParamRun_EDE9FC + 3960
SeqMixParam_Entry_136 = SndParamRun_EDE9FC + 3978
SeqMixParam_Entry_137 = SndParamRun_EDE9FC + 3996
SeqMixParam_Entry_138 = SndParamRun_EDE9FC + 4014
SeqMixParam_Entry_139 = SndParamRun_EDE9FC + 4032
SeqMixParam_Entry_140 = SndParamRun_EDE9FC + 4050
SeqMixParam_Entry_141 = SndParamRun_EDE9FC + 4068
SeqMixParam_Entry_142 = SndParamRun_EDE9FC + 4086
SeqMixParam_Entry_143 = SndParamRun_EDE9FC + 4104
SeqMixParam_Entry_144 = SndParamRun_EDE9FC + 4122
SeqMixParam_Entry_145 = SndParamRun_EDE9FC + 4140
SeqMixParam_Entry_146 = SndParamRun_EDE9FC + 4158
SeqMixParam_Entry_147 = SndParamRun_EDE9FC + 4176
SeqMixParam_Entry_148 = SndParamRun_EDE9FC + 4194
SeqMixParam_Entry_149 = SndParamRun_EDE9FC + 4212
SeqMixParam_Entry_150 = SndParamRun_EDE9FC + 4230
SeqMixParam_Entry_151 = SndParamRun_EDE9FC + 4248
SeqMixParam_Entry_152 = SndParamRun_EDE9FC + 4266
SeqMixParam_Entry_153 = SndParamRun_EDE9FC + 4284
SeqMixParam_Entry_154 = SndParamRun_EDE9FC + 4302
SeqMixParam_Entry_155 = SndParamRun_EDE9FC + 4320
SeqMixParam_Entry_156 = SndParamRun_EDE9FC + 4338
SeqMixParam_Entry_157 = SndParamRun_EDE9FC + 4356
SeqMixParam_Entry_158 = SndParamRun_EDE9FC + 4374
SeqMixParam_Entry_159 = SndParamRun_EDE9FC + 4392
SeqMixParam_Entry_160 = SndParamRun_EDE9FC + 4410
SeqMixParam_Entry_161 = SndParamRun_EDE9FC + 4428
SeqMixParam_Entry_162 = SndParamRun_EDE9FC + 4446
SeqMixParam_Entry_163 = SndParamRun_EDE9FC + 4464
SeqMixParam_Entry_164 = SndParamRun_EDE9FC + 4482
SeqMixParam_Entry_165 = SndParamRun_EDE9FC + 4500
SeqMixParam_Entry_166 = SndParamRun_EDE9FC + 4518
SeqMixParam_Entry_167 = SndParamRun_EDE9FC + 4536
SeqMixParam_Entry_168 = SndParamRun_EDE9FC + 4554
SeqMixParam_Entry_169 = SndParamRun_EDE9FC + 4572
SeqMixParam_Entry_170 = SndParamRun_EDE9FC + 4590
SeqMixParam_Entry_171 = SndParamRun_EDE9FC + 4608
SeqMixParam_Entry_172 = SndParamRun_EDE9FC + 4626
SeqMixParam_Entry_173 = SndParamRun_EDE9FC + 4644
SeqMixParam_Entry_174 = SndParamRun_EDE9FC + 4662
SeqMixParam_Entry_175 = SndParamRun_EDE9FC + 4680
SeqMixParam_Entry_176 = SndParamRun_EDE9FC + 4698
SeqMixParam_Entry_177 = SndParamRun_EDE9FC + 4716
SeqMixParam_Entry_178 = SndParamRun_EDE9FC + 4734
SeqMixParam_Entry_179 = SndParamRun_EDE9FC + 4752
SeqMixParam_Entry_180 = SndParamRun_EDE9FC + 4770
SeqMixParam_Entry_181 = SndParamRun_EDE9FC + 4788
SeqMixParam_Entry_182 = SndParamRun_EDE9FC + 4806
SeqMixParam_Entry_183 = SndParamRun_EDE9FC + 4824
SeqMixParam_Entry_184 = SndParamRun_EDE9FC + 4842
SeqMixParam_Entry_185 = SndParamRun_EDE9FC + 4860
SeqMixParam_Entry_186 = SndParamRun_EDE9FC + 4878
SeqMixParam_Entry_187 = SndParamRun_EDE9FC + 4896
SeqMixParam_Entry_188 = SndParamRun_EDE9FC + 4914
SeqMixParam_Entry_189 = SndParamRun_EDE9FC + 4932
SeqMixParam_Entry_190 = SndParamRun_EDE9FC + 4950
SeqMixParam_Entry_191 = SndParamRun_EDE9FC + 4968
SeqMixParam_Entry_192 = SndParamRun_EDE9FC + 4986
SeqMixParam_Entry_193 = SndParamRun_EDE9FC + 5004
SeqMixParam_Entry_194 = SndParamRun_EDE9FC + 5022
SeqMixParam_Entry_195 = SndParamRun_EDE9FC + 5040
SeqMixParam_Entry_196 = SndParamRun_EDE9FC + 5058
SeqMixParam_Entry_197 = SndParamRun_EDE9FC + 5076
SeqMixParam_Entry_198 = SndParamRun_EDE9FC + 5094
SeqMixParam_Entry_199 = SndParamRun_EDE9FC + 5112
SeqMixParam_Entry_200 = SndParamRun_EDE9FC + 5130
SeqMixParam_Entry_201 = SndParamRun_EDE9FC + 5148
SeqMixParam_Entry_202 = SndParamRun_EDE9FC + 5166
SeqMixParam_Entry_203 = SndParamRun_EDE9FC + 5184
SeqMixParam_Entry_204 = SndParamRun_EDE9FC + 5202
SeqMixParam_Entry_205 = SndParamRun_EDE9FC + 5220
SeqMixParam_Entry_206 = SndParamRun_EDE9FC + 5238
SeqMixParam_Entry_207 = SndParamRun_EDE9FC + 5256
SeqMixParam_Entry_208 = SndParamRun_EDE9FC + 5274
SeqMixParam_Entry_209 = SndParamRun_EDE9FC + 5292
SeqMixParam_Entry_210 = SndParamRun_EDE9FC + 5310
SeqMixParam_Entry_211 = SndParamRun_EDE9FC + 5328
SeqMixParam_Entry_212 = SndParamRun_EDE9FC + 5346
SeqMixParam_Entry_213 = SndParamRun_EDE9FC + 5364
SeqMixParam_Entry_214 = SndParamRun_EDE9FC + 5382
SeqMixParam_Entry_215 = SndParamRun_EDE9FC + 5400
SeqMixParam_Entry_216 = SndParamRun_EDE9FC + 5418
SeqMixParam_Entry_217 = SndParamRun_EDE9FC + 5436
SeqMixParam_Entry_218 = SndParamRun_EDE9FC + 5454
SeqMixParam_Entry_219 = SndParamRun_EDE9FC + 5472
SeqMixParam_Entry_220 = SndParamRun_EDE9FC + 5490
SeqMixParam_Entry_221 = SndParamRun_EDE9FC + 5508
SeqMixParam_Entry_222 = SndParamRun_EDE9FC + 5526
SeqMixParam_Entry_223 = SndParamRun_EDE9FC + 5544
SeqMixParam_Entry_224 = SndParamRun_EDE9FC + 5562
SeqMixParam_Entry_225 = SndParamRun_EDE9FC + 5580
SeqMixParam_Entry_226 = SndParamRun_EDE9FC + 5598
SeqMixParam_Entry_227 = SndParamRun_EDE9FC + 5616
SeqMixParam_Entry_228 = SndParamRun_EDE9FC + 5634
