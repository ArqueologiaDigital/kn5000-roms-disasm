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
; !! THIS IS THE v9 COPY.  The ROM bytes of this file's whole range,
; 0xED0008-0xEE0010, are IDENTICAL in the v9 and v10 dumps (0 differing bytes),
; and so is this text, except that the Makefile compiles the C structs above
; for v10 only: here each of those 951 records is one `sndparam_descriptor`
; macro line (defined above the first run below) with the same fields in the
; same order.  Produced by scripts/tools/port_extension_data_from_v10.py.
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

; ---------------------------------------------------------------------------
; CHORD-TYPE NAMES: the tail of the chord-type pointer table, then the names
; ---------------------------------------------------------------------------
; Reader: MainChordPre (kn5000_v10_program.s, 0xFC304E) builds the chord
; display string with Strcat: the root-note name (RAM byte 0x8D40 x4 into
; Naka_MemoryC_Screens), then the CHORD-TYPE name -- RAM byte 0x8D42, `sla
; wa, 2`, `lda xbc, (0xecff6a:24)`, `ld_sril3` -- then "on" or "  "
; (ChordStr_On / ChordStr_Blank, loaded as the immediates 0xED1C96 and
; 0xED1C9A).  The pointer table it indexes is 64 entries, 0xECFF6A-0xED0069:
; entries 0-39 lie in MemScreen_Blank's blob in ui_widgets/style_bitmaps.s
; (naka_style_bitmaps.c), so this file BEGINS with the high half of entry 39
; (0x00ED00FA) and holds entries 40-63.  Entry k points at the name of chord
; type k; the 64 names follow in REVERSE order of k, NUL-terminated and
; 0xFF-padded to even addresses (`scripts/analysis/ext_lane_checks.py chord`
; re-checks all of it on the v10, v9 and v7 dumps).
;
; Glyph escapes: "~9e" is SHARP and "~a0" is FLAT in these strings (the
; note-name tables below settle it: NoteNameStr_Table_0 spells C#, D#, F#, G#,
; A# with ~9e, SplitNoteStr_* spells Db, Eb, Ab, Bb with ~a0 and F# with ~9e;
; `ext_lane_checks.py sharp`).  The older
; ChordTypeStr_* labels below read the two the other way round in several
; places (ChordTypeStr_7_Flat9 is "7 (#9)", ChordTypeStr_M7_Sharp5 is
; "M7(b5)"); they are kept because ui_widgets/naka_style_bitmaps.c cites them
; by name, and the entry index in each new ChordTypeStr_TypeNN label is the
; reliable identity.  ExtData_ChordTypeTable_Top keeps its old name because
; naka_perf_style_link.ld and naka_extension_device_link.ld name the address.
; ---------------------------------------------------------------------------
ExtData_ChordTypeTable_Top:
	.short 0x00ed	; high half of entry 39, begun in style_bitmaps.s
	.long ChordTypeStr_Type40
	.long ChordTypeStr_Type41
	.long ChordTypeStr_Type42
	.long ChordTypeStr_Type43
	.long ChordTypeStr_Type44
	.long ChordTypeStr_Type45
	.long ChordTypeStr_Type46
	.long ChordTypeStr_Type47
	.long ChordTypeStr_Type48
	.long ChordTypeStr_Type49
	.long ChordTypeStr_Type50
	.long ChordTypeStr_Type51
	.long ChordTypeStr_Type52
	.long ChordTypeStr_Type53
	.long ChordTypeStr_Type54
	.long ChordTypeStr_Type55
	.long ChordTypeStr_Type56
	.long ChordTypeStr_Type57
	.long ChordTypeStr_Type58
	.long ChordTypeStr_Type59
	.long ChordTypeStr_Type60
	.long ChordTypeStr_Blank_2
	.long ChordTypeStr_Blank_1
	.long ChordTypeStr_Blank_0
ChordTypeStr_Blank_0:		aligned_string "     "
ChordTypeStr_Blank_1:		aligned_string "     "
ChordTypeStr_Blank_2:		aligned_string "     "
ChordTypeStr_Type60:		aligned_string "     "
ChordTypeStr_Type59:		aligned_string "     "
ChordTypeStr_Type58:		aligned_string "     "
ChordTypeStr_Type57:		aligned_string "     "
ChordTypeStr_Type56:		aligned_string "     "
ChordTypeStr_Type55:		aligned_string "     "
ChordTypeStr_Type54:		aligned_string "     "
ChordTypeStr_Type53:		aligned_string "     "
ChordTypeStr_Type52:		aligned_string "     "
ChordTypeStr_Type51:		aligned_string "     "
ChordTypeStr_Type50:		aligned_string "     "
ChordTypeStr_Type49:		aligned_string "     "
ChordTypeStr_Type48:		aligned_string "     "
ChordTypeStr_Type47:		aligned_string "     "
ChordTypeStr_Type46:		aligned_string "     "
ChordTypeStr_Type45:		aligned_string "     "
ChordTypeStr_Type44:		aligned_string "     "
ChordTypeStr_Type43:		aligned_string "     "
ChordTypeStr_Type42:		aligned_string "     "
ChordTypeStr_Type41:		aligned_string "madd9"
ChordTypeStr_Type40:		aligned_string " add9"
ChordTypeStr_Type39:		aligned_string "+7~9e11"
ChordTypeStr_Type38:		aligned_string "m7 11"
ChordTypeStr_Type37:		aligned_string "7 ~9e11"
ChordTypeStr_Type36:		aligned_string "  ~a013"
ChordTypeStr_Type35:		aligned_string "   13"
ChordTypeStr_Type34:		aligned_string "~9e9~a013"
ChordTypeStr_Flat9_Flat13:	aligned_string "~a09~a013"
ChordTypeStr_Sharp9_Flat13:	aligned_string "  ~a013"
ChordTypeStr_Flat13_Only:	aligned_string "~9e9 13"
ChordTypeStr_Sharp9_13:		aligned_string "~a09 13"
ChordTypeStr_9_Flat5:		aligned_string "9~9e5  "
ChordTypeStr_13_Only:		aligned_string "   13"
ChordTypeStr_mM7_Sharp5:	aligned_string "mM7~a05"
ChordTypeStr_M7_Flat5:		aligned_string "M7~9e5 "
ChordTypeStr_M7_Sharp5:		aligned_string "M7~a05 "
ChordTypeStr_7_Flat9:		aligned_string "7 ~9e9 "
ChordTypeStr_sus4:		aligned_string "sus4 "
ChordTypeStr_69:		aligned_string "m69  "
ChordTypeStr_Type21:		aligned_string "m79  "
ChordTypeStr_Type20:		aligned_string "m ~a05 "
ChordTypeStr_Type19:		aligned_string "m6   "
ChordTypeStr_Type18:		aligned_string "69   "
ChordTypeStr_M7_9:		aligned_string "M79  "
ChordTypeStr_Type16:		aligned_string "7 ~a09 "
ChordTypeStr_Type15:		aligned_string "79   "
ChordTypeStr_Type14:		aligned_string "7 ~a05 "
ChordTypeStr_Type13:		aligned_string "  ~a05 "
ChordTypeStr_Type12:		aligned_string "aug7 "
ChordTypeStr_Type11:		aligned_string "6    "
ChordTypeStr_7sus4:		aligned_string "7sus4"
ChordTypeStr_Type09:		aligned_string "mM7  "
ChordTypeStr_Type08:		aligned_string "m7~a05 "
ChordTypeStr_Type07:		aligned_string "dim  "
ChordTypeStr_Type06:		aligned_string "min7 "
ChordTypeStr_Type05:		aligned_string "min  "
ChordTypeStr_Type04:		aligned_string "aug  "
ChordTypeStr_Type03:		aligned_string "Maj7 "
ChordTypeStr_Type02:		aligned_string "7    "
ChordTypeStr_Type01:		aligned_string "     "
ChordTypeStr_Type00:		aligned_string "     "
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
	aligned_string "%s"
ChordStr_On:	aligned_string "on"	; MainChordPre appends it when byte 0x8D44 != 0 and bit 1 of 0xCEDE is set
ChordStr_Blank:	aligned_string "  "
; ---------------------------------------------------------------------------
; Toshi_ApFunction_Table -- TOSHI object table: 42 "application function"
; code pointers + NULL (0xED1C9E-0xED1D49)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (extensions/extension_init.s, 0xFC311A):
;   RegObjTabl 0x1600002, ApFunctionProc, 42, Toshi_ApFunction_Table, 0x122
; which has RegisterObjectTable (ui/ui_widget_defs.s, 0xFA42FB) copy the
; 14-byte descriptor {class +0, proc +4, u16 count +8, table +10} into slot
; 0x122 of the object registry at RAM 0x27ED2 (14 bytes a slot).  An object
; id is (slot << 16) | element; CheckViewObject (0xFA42C4) reads the table
; pointer at +10 and indexes it with `extz xwa` / `sll xwa, 2` / `ld xwa, (xwa)`
; -- one 4-byte pointer per element, 0 = no object.  Slot 0x422 (= 0x122 +
; 0x300, the pairing RegisterObject 0xFA431A uses for an object's name) is
; Toshi_ApFunctionName_Table below: entry k there is the NAME of entry k here,
; and scripts/tools/ext_retype_toshi_object_tables.py --check verifies that
; every pointer lands on the routine of exactly that name (v10 and v7).
Toshi_ApFunction_Table:
	.long PmBkNameFunc
	.long PmBankNamingCheck
	.long PmNamingCheck
	.long MssNameFunc
	.long SystemInitOkFunc
	.long SysIniNoFunc
	.long SysIniYesFunc
	.long SysSureShowHideFunc
	.long AttnLngCheck
	.long SysSureLngCheck
	.long SureLngCheck
	.long TchSensGridCheck
	.long FSWAssGridCheck
	.long PmExpFilterGridCheck
	.long DispTimeSetGridCheck
	.long MstSugAlpGridCheck
	.long MstStyleAlpGridCheck
	.long MstStyle1GridCheck
	.long MstStyle1SubGridCheck
	.long MstStyle2GridCheck
	.long MstSong1GridCheck
	.long MstSong2GridCheck
	.long BitmapFinpic
	.long BitmapFinst
	.long BitmapFoutpic
	.long BitmapFoutst
	.long GmOnOffFunc
	.long DispTimeSetOKFunc
	.long SystemInitMDFunc
	.long WallHomeEditCheck
	.long WallMenuEditCheck
	.long WallOthEditCheck
	.long WallSetOKFunc
	.long WallUsrIniFunc
	.long WallUsrIniNoFunc
	.long WallUsrIniYesFunc
	.long WallUsrShowHideFunc
	.long WallSureShowHideFunc
	.long WallSureLngCheck
	.long CtlIniLngCheck
	.long PmemNormLngCheck
	.long PmemExpLngCheck
	.long 0
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1D1B-0xED1D3A (31 B), unreached CODE-territory, was disassembled as 19 plausible-but-dead instruction lines; per=70% dist=12 near KeyScaleNoteStr_G_0x18+129
; Toshi_ApFunctionName_Table -- object-registry slot 0x422 (InitializeToshi:
; RegObjTabl 0x1600002, ApFunctionProc, 42, Toshi_ApFunctionName_Table, 0x422):
; the name of each Toshi_ApFunction_Table entry, same index, then "" as the
; terminator.  The strings follow in REVERSE order.
Toshi_ApFunctionName_Table:
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

; ---------------------------------------------------------------------------
; Toshi_Class_Table -- TOSHI object-registry slot 0x162: 28 class records of
; 24 bytes (0xED27E4-0xED2A83), registered by InitializeToshi with
;   RegObjTable 0x1600004, ClassProc, Toshi_Class_Count, Toshi_Class_Table, 0x162
; (count word Toshi_Class_Count = 28, after the class-name strings).  Record
; shape, read off the bytes -- all 28 records agree:
;   +0x00 class procedure (record 0: NormScreenProc; every one is a *Proc
;         routine in 0xFB-0xFC code)
;   +0x04 u16 (0x12..0x54)      +0x06 u16, always 0x0160
;   +0x08 u16, +0x0A u16 -- +0x0A is 0 for a class with no variables and
;         rises by exactly 4 per extra 'n' variable (instance-variable
;         storage size, by inference; not traced to a reader)
;   +0x0C class-name string ("NormScreen", "VariScreen", ...)
;   +0x10 type-signature string, ONE character per instance variable
;         ("kc^nnnnnn" for VariScreen's 9 variables)
;   +0x14 the class's instance-variable NAME table ("func", "font", ...,
;         "" terminated); its length equals the signature's in all 28.
; Only record 0's +0x00 is in this file: the table's other 668 bytes, and
; the name/signature strings after it, are the start of
; NakaData_MasterStyleGrid (ui_widgets/master_style_grid_screens.s,
; naka_master_style.c), included right below.
; ---------------------------------------------------------------------------
Toshi_Class_Table:
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
; Toshi class count: 28 -- read by InitializeToshi's first registration,
;   RegObjTable 0x1600004, ClassProc, Toshi_Class_Count, Toshi_Class_Table, 0x162
; whose count argument is loaded FROM this address (`ldw_da`), not immediate.
Toshi_Class_Count:	.short 28
; ---------------------------------------------------------------------------
; Toshi_ResEvent_Table -- object-registry slot 0x1C2: 8 event-name string
; pointers + NULL, registered by InitializeToshi with
;   RegObjTable 0x160000c, ResEventProc, Toshi_ResEvent_Count, Toshi_ResEvent_Table, 0x1c2
; (the count word follows the strings).  The strings are the EV_* event
; names; they follow in reverse order.
; ---------------------------------------------------------------------------
Toshi_ResEvent_Table:
	.long EventNameStr_EV_CHORDSHOW
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
EventNameStr_EV_CHORDSHOW:	aligned_string "EV_CHORDSHOW"
Toshi_ResEvent_Count:	.short 8
; ---------------------------------------------------------------------------
; Toshi_ResMethod_Table -- object-registry slot 0x1E2: 26 method-name string
; pointers + NULL, registered by InitializeToshi with
;   RegObjTable 0x160000d, ResMethodProc, Toshi_ResMethod_Count, Toshi_ResMethod_Table, 0x1e2
; (the count word follows the strings).  The strings are the MT_* method
; names; they follow in reverse order.
; ---------------------------------------------------------------------------
Toshi_ResMethod_Table:
	.long MethodNameStr_MT_VariWrite
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
MethodNameStr_MT_VariWrite:	aligned_string "MT_VariWrite"
Toshi_ResMethod_Count:	.short 26
; ---------------------------------------------------------------------------
; Toshi_Function_Table -- TOSHI object table: 28 screen/box procedure
; pointers + NULL (0xED2F66-0xED2FD9)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (0xFC311A) with
;   RegObjTabl 0x1600001, FunctionProc, 28, Toshi_Function_Table, 0x102
; into object-registry slot 0x102 (layout and indexing: see
; Toshi_ApFunction_Table).  Its names are Toshi_FunctionName_Table (slot
; 0x402); entry k there names entry k here -- verified for all 28 in v10 by
; scripts/tools/ext_retype_toshi_object_tables.py --check (in v7 for 27: v7
; labels entry 19's routine only AcMstStyleAlp_Boundary).
Toshi_Function_Table:
	.long NormScreenProc
	.long VariScreenProc
	.long RVariScreenProc
	.long AcTransposeBoxProc
	.long AcFreeSplitBoxProc
	.long AcChordBoxProc
	.long PmBankScreenProc
	.long AcPmBkEditBoxProc
	.long MsaModeScreenProc
	.long PmemModeBoxProc
	.long AcBkNoBoxProc
	.long AcPmBkNoBoxProc
	.long IvWindowPageControlProc
	.long IvPmemWindowPageCtlProc
	.long AcTchSensGridBoxProc
	.long AcFSWAssGridBoxProc
	.long AcPmExpFilterGridBoxProc
	.long AcDispTimeSetGridBoxProc
	.long AcMstSugAlpGridBoxProc
	.long AcMstStyleAlpGridBoxProc
	.long IvMstStyleWindowPgCtlProc
	.long AcMstStyle1GridBoxProc
	.long AcMstStyle1SubGridBoxProc
	.long AcMstStyle2GridBoxProc
	.long AcMstSong1GridBoxProc
	.long AcMstSong2GridBoxProc
	.long SineWaveScreenProc
	.long IvPageOverWrProc
	.long 0
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2F90-0xED2FAB (27 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=67% dist=14 near MethodNameStr_MT_SvariIni+70
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2FAC-0xED2FC6 (26 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=13 near MethodNameStr_MT_SvariIni+98
; Toshi_FunctionName_Table -- object-registry slot 0x402 (InitializeToshi:
; RegObjTabl 0x1600001, FunctionProc, 28, Toshi_FunctionName_Table, 0x402):
; the name of each Toshi_Function_Table entry, same index; strings follow in
; reverse order.
Toshi_FunctionName_Table:
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
; ---------------------------------------------------------------------------
; Toshi_MainFunction_Table -- TOSHI object table: 20 "main function" code
; pointers + NULL (0xED3292-0xED32E5)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (0xFC311A) with
;   RegObjTabl 0x1600003, MainFunctionProc, 20, Toshi_MainFunction_Table, 0x142
; into object-registry slot 0x142 (layout and indexing: see
; Toshi_ApFunction_Table).  Its names are Toshi_MainFunctionName_Table (slot
; 0x442), whose strings sit in ui_widgets/normal_mode_layout.s; entry k there
; names entry k here -- verified for all 20, in v10 and v7, by
; scripts/tools/ext_retype_toshi_object_tables.py --check.
Toshi_MainFunction_Table:
	.long MainVariSet
	.long MainSvariIni
	.long MainGetSndName
	.long MainRvariIni
	.long MainGetRhyName
	.long MainGetSndGrpName
	.long MainGetRhyGrpName
	.long MainChordPre
	.long MainPmGet
	.long OneTchFUNC
	.long MainSysControl
	.long CntIniFunc
	.long FswAsIniFunc
	.long MainMssSetUp
	.long MainTimeFlashFunc
	.long MainWallSetFlashFunc
	.long TEST2FUNC
	.long TEST3FUNC
	.long TEST4FUNC
	.long TEST6FUNC
	.long 0
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED32CC-0xED32DE (18 B), unreached CODE-territory, was disassembled as 8 plausible-but-dead instruction lines; per=100% dist=9 near ProcNameStr_NormScreenProc+74
; Toshi_MainFunctionName_Table -- object-registry slot 0x442 (InitializeToshi:
; RegObjTabl 0x1600003, MainFunctionProc, 20, Toshi_MainFunctionName_Table,
; 0x442): the name of each Toshi_MainFunction_Table entry, same index, then ""
; as the terminator.  The 20 name strings are the NakaInst_* cells of
; ui_widgets/normal_mode_layout.s (naka_normal_mode.c), included just below.
Toshi_MainFunctionName_Table:
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
NakaInstTable8_NullTerm:	aligned_string ""
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


	.short 319, 239	; right/bottom edge of the 320x240 screen, NOT a pointer (was `.long Naka_PresentationRootState`: v7 moved that routine, not this value)
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
; ---------------------------------------------------------------------------
; sndparam_descriptor -- ONE 18-byte sound-parameter descriptor
; ---------------------------------------------------------------------------
; v10 compiles these records from C (v10/maincpu/audio/sndparam_records/
; run_*.c, struct sndparam_descriptor_t in sndparam_types.h); the Makefile does
; that for v10 only, so this copy writes each record as one macro line with
; the SAME fields in the SAME order.  sndparam_types.h cites, per field, the
; SndParam_* accessor instruction that reads it -- in v10's
; audio/sndparam_routines.s; the record layout is the same in this version
; because the records are byte-for-byte the v10 ones (see the file header).
;
;   +0x00 key (u32, byte +3 always 0)   +0x04 bank_index   +0x05 bank_offset
;   +0x06 mask   +0x07 clamp_min   +0x08 clamp_max   +0x09 shift (low nibble)
;   +0x0A xor_value   +0x0B aux_index (0xff = none)   +0x0C read_accessor
;   +0x0D register_accessor   +0x0E lookup2_accessor   +0x0F codec
;   +0x10 write_accessor   +0x11 unknown_0x11 (no reader found in v10)
.macro sndparam_descriptor key, bank_index, bank_offset, mask, clamp_min, clamp_max, shift, xor_value, aux_index, read_acc, register_acc, lookup2_acc, codec, write_acc, unknown_0x11
	.long \key
	.byte \bank_index, \bank_offset, \mask, \clamp_min, \clamp_max, \shift, \xor_value, \aux_index
	.byte \read_acc, \register_acc, \lookup2_acc, \codec, \write_acc, \unknown_0x11
.endm
;  22 x 18-byte sound-parameter descriptors, 0xEDBAC0-0xEDBC4C, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edbac0.c.
SndParamRun_EDBAC0:
VoiceCtrlR1_Entry_001:	sndparam_descriptor 0x000003, 112, 2, 0xff, 0, 11, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
VoiceCtrlR1_Entry_002:	sndparam_descriptor 0x000004, 72, 8, 0xff, 40, 255, 0, 0x00, 0x00, 6, 8, 6, 2, 0, 0xff
VoiceCtrlR1_Entry_003:	sndparam_descriptor 0x000005, 72, 9, 0x01, 0, 1, 0, 0x00, 0x00, 6, 8, 6, 2, 0, 0xff
VoiceCtrlR1_Entry_004:	sndparam_descriptor 0x0000c0, 145, 3, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_005:	sndparam_descriptor 0x0000c1, 145, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_006:	sndparam_descriptor 0x000100, 147, 0, 0x0f, 0, 9, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_007:	sndparam_descriptor 0x000102, 147, 5, 0xff, 1, 10, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_008:	sndparam_descriptor 0x000103, 147, 6, 0x7f, 1, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_009:	sndparam_descriptor 0x000104, 147, 6, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_010:	sndparam_descriptor 0x000300, 152, 1, 0x7f, 0, 80, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_011:	sndparam_descriptor 0x000301, 152, 1, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_012:	sndparam_descriptor 0x000302, 152, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_013:	sndparam_descriptor 0x000400, 152, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_014:	sndparam_descriptor 0x000401, 152, 3, 0x70, 1, 3, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_015:	sndparam_descriptor 0x002100, 128, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_016:	sndparam_descriptor 0x002101, 128, 3, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_017:	sndparam_descriptor 0x002181, 128, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_018:	sndparam_descriptor 0x002182, 128, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_019:	sndparam_descriptor 0x002183, 128, 3, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_020:	sndparam_descriptor 0x002184, 128, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_021:	sndparam_descriptor 0x002200, 128, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_022:	sndparam_descriptor 0x002201, 128, 0, 0x03, 0, 3, 0, 0x00, 0x01, 1, 7, 5, 0, 0, 0xff
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
;  78 x 18-byte sound-parameter descriptors, 0xEDBC9E-0xEDC21A, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edbc9e.c.
SndParamRun_EDBC9E:
VoiceCtrlR1_Entry_027:	sndparam_descriptor 0x002280, 128, 1, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_028:	sndparam_descriptor 0x002281, 128, 2, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_029:	sndparam_descriptor 0x002282, 128, 6, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_030:	sndparam_descriptor 0x00228a, 128, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_031:	sndparam_descriptor 0x00228b, 128, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_032:	sndparam_descriptor 0x00228c, 128, 7, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_033:	sndparam_descriptor 0x00228d, 128, 8, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_034:	sndparam_descriptor 0x00228e, 128, 8, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_035:	sndparam_descriptor 0x00228f, 128, 8, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_036:	sndparam_descriptor 0x002290, 128, 8, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_037:	sndparam_descriptor 0x002291, 128, 8, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_038:	sndparam_descriptor 0x002294, 128, 8, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_039:	sndparam_descriptor 0x002295, 128, 8, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_040:	sndparam_descriptor 0x002296, 128, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_041:	sndparam_descriptor 0x002298, 128, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_042:	sndparam_descriptor 0x002299, 128, 9, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_043:	sndparam_descriptor 0x00229a, 128, 1, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_044:	sndparam_descriptor 0x002880, 153, 2, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_045:	sndparam_descriptor 0x002882, 153, 1, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_046:	sndparam_descriptor 0x002881, 153, 3, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_047:	sndparam_descriptor 0x002886, 153, 4, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_048:	sndparam_descriptor 0x002887, 153, 0, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_049:	sndparam_descriptor 0x002888, 153, 5, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_050:	sndparam_descriptor 0x002889, 153, 0, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_051:	sndparam_descriptor 0x00288a, 153, 6, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_052:	sndparam_descriptor 0x00288b, 153, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_053:	sndparam_descriptor 0x00288c, 153, 7, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_054:	sndparam_descriptor 0x00288d, 153, 0, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_055:	sndparam_descriptor 0x00288e, 153, 8, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_056:	sndparam_descriptor 0x00288f, 153, 0, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_057:	sndparam_descriptor 0x002890, 153, 9, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_058:	sndparam_descriptor 0x002891, 153, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_059:	sndparam_descriptor 0x002892, 153, 10, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_060:	sndparam_descriptor 0x002893, 153, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_061:	sndparam_descriptor 0x002894, 153, 11, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_062:	sndparam_descriptor 0x002895, 153, 0, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_063:	sndparam_descriptor 0x002896, 153, 12, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_064:	sndparam_descriptor 0x002897, 153, 1, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_065:	sndparam_descriptor 0x002898, 153, 13, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_066:	sndparam_descriptor 0x002899, 153, 1, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_067:	sndparam_descriptor 0x00289a, 153, 14, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_068:	sndparam_descriptor 0x00289b, 153, 1, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_069:	sndparam_descriptor 0x00289c, 153, 15, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_070:	sndparam_descriptor 0x00289d, 153, 1, 0x08, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_071:	sndparam_descriptor 0x002900, 152, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_072:	sndparam_descriptor 0x002901, 152, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_073:	sndparam_descriptor 0x002902, 152, 7, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_074:	sndparam_descriptor 0x002903, 152, 7, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_075:	sndparam_descriptor 0x002904, 152, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_001:	sndparam_descriptor 0x002905, 152, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_002:	sndparam_descriptor 0x002906, 152, 7, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_003:	sndparam_descriptor 0x002907, 152, 7, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_004:	sndparam_descriptor 0x002908, 152, 8, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_005:	sndparam_descriptor 0x002909, 152, 8, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_006:	sndparam_descriptor 0x00290a, 152, 8, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_007:	sndparam_descriptor 0x00290b, 152, 8, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_008:	sndparam_descriptor 0x00290c, 152, 8, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_009:	sndparam_descriptor 0x00290d, 152, 8, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_010:	sndparam_descriptor 0x00290e, 152, 8, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_011:	sndparam_descriptor 0x00290f, 152, 8, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_012:	sndparam_descriptor 0x002910, 152, 9, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_013:	sndparam_descriptor 0x002911, 152, 9, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_014:	sndparam_descriptor 0x002a00, 112, 5, 0xff, 1, 16, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_015:	sndparam_descriptor 0x002a01, 112, 6, 0xff, 1, 16, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_016:	sndparam_descriptor 0x002a10, 112, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_017:	sndparam_descriptor 0x002a11, 112, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_018:	sndparam_descriptor 0x002a12, 112, 7, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_019:	sndparam_descriptor 0x002c00, 152, 14, 0x03, 0, 2, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_020:	sndparam_descriptor 0x002d00, 71, 1, 0x1f, 0, 17, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_021:	sndparam_descriptor 0x002d01, 71, 0, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_022:	sndparam_descriptor 0x002d02, 71, 2, 0x7f, 0, 99, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_023:	sndparam_descriptor 0x002d03, 71, 0, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_024:	sndparam_descriptor 0x002d04, 71, 3, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_025:	sndparam_descriptor 0x002d05, 71, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_026:	sndparam_descriptor 0x002d06, 71, 3, 0xf0, 0, 11, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_027:	sndparam_descriptor 0x002d07, 71, 0, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_028:	sndparam_descriptor 0x002d08, 71, 4, 0xc0, 0, 3, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_029:	sndparam_descriptor 0x002d09, 71, 0, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_030:
	.byte 0x0a, 0x2d, 0x00, 0x00, 0x47, 0x05, 0x7f, 0x00, 0x79, 0x00, 0x00, 0x0a, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x0f, 0x1d, 0x1e, 0x1f, 0x20
	.ascii "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyÿ"
WidgetParam_MidiCC_NameEdit:
	.byte 0x2c, 0xc2, 0xed, 0x00, 0x6d, 0x00, 0x00, 0x00, 0x00, 0xff
;  22 x 18-byte sound-parameter descriptors, 0xEDC2A4-0xEDC430, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc2a4.c.
SndParamRun_EDC2A4:
MidiChParam_Entry_031:	sndparam_descriptor 0x002d0b, 71, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_032:	sndparam_descriptor 0x002d0c, 71, 6, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_033:	sndparam_descriptor 0x002d0d, 71, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_034:	sndparam_descriptor 0x002d0e, 71, 6, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_035:	sndparam_descriptor 0x002d0f, 71, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_036:	sndparam_descriptor 0x002d10, 71, 7, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_037:	sndparam_descriptor 0x002d11, 71, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_038:	sndparam_descriptor 0x002d12, 71, 7, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_039:	sndparam_descriptor 0x002d13, 71, 0, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_040:	sndparam_descriptor 0x004000, 176, 0, 0x7f, 0, 127, 0, 0x00, 0x01, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_041:	sndparam_descriptor 0x004001, 176, 1, 0x7f, 0, 127, 0, 0x00, 0x00, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_042:	sndparam_descriptor 0x004002, 96, 1, 0x80, 0, 127, 7, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
MidiChParam_Entry_043:	sndparam_descriptor 0x004003, 112, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_044:	sndparam_descriptor 0x004004, 96, 1, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_045:	sndparam_descriptor 0x004005, 176, 3, 0x7f, 0, 127, 0, 0x00, 0x00, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_046:	sndparam_descriptor 0x004006, 96, 1, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_047:	sndparam_descriptor 0x004080, 152, 2, 0x80, 0, 1, 7, 0x00, 0xff, 1, 2, 2, 0, 0, 0xff
MidiChParam_Entry_048:	sndparam_descriptor 0x004081, 152, 2, 0x40, 0, 1, 6, 0x00, 0xff, 1, 2, 2, 0, 0, 0xff
MidiChParam_Entry_049:	sndparam_descriptor 0x0040c0, 152, 11, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_050:	sndparam_descriptor 0x0040c1, 152, 11, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_051:	sndparam_descriptor 0x0040e0, 144, 4, 0xff, 40, 88, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
MidiChParam_Entry_052:	sndparam_descriptor 0x004100, 144, 0, 0x1f, 0, 5, 0, 0x00, 0x00, 4, 5, 4, 0, 0, 0xff
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
;  19 x 18-byte sound-parameter descriptors, 0xEDC634-0xEDC78A, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc634.c.
SndParamRun_EDC634:
MidiChParam_Entry_065:	sndparam_descriptor 0x004284, 146, 3, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_066:	sndparam_descriptor 0x004285, 146, 4, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_067:	sndparam_descriptor 0x004286, 146, 5, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_068:	sndparam_descriptor 0x004287, 146, 6, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_069:	sndparam_descriptor 0x004288, 146, 7, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_070:	sndparam_descriptor 0x004289, 146, 8, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_071:	sndparam_descriptor 0x00428a, 146, 9, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_072:	sndparam_descriptor 0x00428b, 146, 10, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_073:	sndparam_descriptor 0x00428c, 146, 11, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_074:	sndparam_descriptor 0x00428d, 146, 12, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_075:	sndparam_descriptor 0x00428e, 146, 13, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_076:	sndparam_descriptor 0x004900, 97, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_077:	sndparam_descriptor 0x004a00, 98, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_078:	sndparam_descriptor 0x004b00, 99, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_079:	sndparam_descriptor 0x004c00, 100, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_080:	sndparam_descriptor 0x004d00, 101, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_081:	sndparam_descriptor 0x004e00, 102, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_082:	sndparam_descriptor 0x005000, 128, 10, 0x03, 0, 2, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_083:	sndparam_descriptor 0x005001, 128, 11, 0xff, 0, 255, 0, 0x00, 0x07, 1, 7, 5, 0, 0, 0xff
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
;  9 x 18-byte sound-parameter descriptors, 0xEDC7FA-0xEDC89C, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc7fa.c.
SndParamRun_EDC7FA:
MidiChParam_Entry_085:	sndparam_descriptor 0x005002, 128, 12, 0xff, 1, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_086:	sndparam_descriptor 0x008000, 0, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_087:	sndparam_descriptor 0x008001, 178, 0, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_088:	sndparam_descriptor 0x008007, 0, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_089:	sndparam_descriptor 0x008008, 0, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_090:	sndparam_descriptor 0x00800a, 0, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_091:	sndparam_descriptor 0x00800b, 179, 0, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_092:	sndparam_descriptor 0x008020, 0, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_093:	sndparam_descriptor 0x008040, 0, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
WidgetParam_MidiCC_Chorus:
	.byte 0x40, 0x00, 0x01, 0x00, 0x7f, 0x00, 0x01, 0xff
;  10 x 18-byte sound-parameter descriptors, 0xEDC8A4-0xEDC958, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc8a4.c.
SndParamRun_EDC8A4:
MidiChParam_Entry_094:	sndparam_descriptor 0x00805b, 0, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_095:	sndparam_descriptor 0x00805d, 0, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_096:	sndparam_descriptor 0x00805e, 0, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
MidiChParam_Entry_097:	sndparam_descriptor 0x008078, 174, 0, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
MidiChParam_Entry_098:	sndparam_descriptor 0x008080, 0, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_099:	sndparam_descriptor 0x008081, 0, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_100:	sndparam_descriptor 0x008082, 0, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_101:	sndparam_descriptor 0x0081b0, 177, 0, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_102:	sndparam_descriptor 0x0081b2, 180, 0, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
MidiChParam_Entry_103:	sndparam_descriptor 0x008221, 68, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_104:
	.byte 0xcc, 0x82, 0x00, 0x00, 0x44, 0x01, 0x0f, 0x00, 0x0f, 0x00, 0x00, 0x09, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff
WidgetParam_MidiCC_DspEffect:
	.byte 0x6a, 0xc9, 0xed, 0x00, 0x0b, 0x00, 0x00, 0x05, 0x00, 0xff
;  460 x 18-byte sound-parameter descriptors, 0xEDC980-0xEDE9D8, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc980.c.
SndParamRun_EDC980:
MidiChParam_Entry_105:	sndparam_descriptor 0x0082cb, 68, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_106:	sndparam_descriptor 0x008293, 68, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_107:	sndparam_descriptor 0x008294, 68, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
MidiChParam_Entry_108:	sndparam_descriptor 0x008280, 68, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_109:	sndparam_descriptor 0x008281, 68, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_110:	sndparam_descriptor 0x008282, 68, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_111:	sndparam_descriptor 0x008283, 68, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_112:	sndparam_descriptor 0x008284, 68, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_001:	sndparam_descriptor 0x008285, 68, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_002:	sndparam_descriptor 0x008286, 68, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_003:	sndparam_descriptor 0x008287, 68, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_004:	sndparam_descriptor 0x008288, 68, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_005:	sndparam_descriptor 0x0082c0, 68, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_006:	sndparam_descriptor 0x0082c1, 68, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_007:	sndparam_descriptor 0x008400, 1, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_008:	sndparam_descriptor 0x008401, 178, 1, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_009:	sndparam_descriptor 0x008407, 1, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_010:	sndparam_descriptor 0x008408, 1, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_011:	sndparam_descriptor 0x00840a, 1, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_012:	sndparam_descriptor 0x00840b, 179, 1, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_013:	sndparam_descriptor 0x008420, 1, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_014:	sndparam_descriptor 0x008440, 1, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_015:	sndparam_descriptor 0x00845b, 1, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_016:	sndparam_descriptor 0x00845d, 1, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_017:	sndparam_descriptor 0x00845e, 1, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_018:	sndparam_descriptor 0x008478, 174, 1, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_019:	sndparam_descriptor 0x008480, 1, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_020:	sndparam_descriptor 0x008481, 1, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_021:	sndparam_descriptor 0x008482, 1, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_022:	sndparam_descriptor 0x0085b0, 177, 1, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_023:	sndparam_descriptor 0x0085b2, 180, 1, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_024:	sndparam_descriptor 0x008621, 69, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_025:	sndparam_descriptor 0x0086cc, 69, 1, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_026:	sndparam_descriptor 0x0086cb, 69, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_027:	sndparam_descriptor 0x008693, 69, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_028:	sndparam_descriptor 0x008694, 69, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_029:	sndparam_descriptor 0x008680, 69, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_030:	sndparam_descriptor 0x008681, 69, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_031:	sndparam_descriptor 0x008682, 69, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_032:	sndparam_descriptor 0x008683, 69, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_033:	sndparam_descriptor 0x008684, 69, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_034:	sndparam_descriptor 0x008685, 69, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_035:	sndparam_descriptor 0x008686, 69, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_036:	sndparam_descriptor 0x008687, 69, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_037:	sndparam_descriptor 0x008688, 69, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_038:	sndparam_descriptor 0x0086c0, 69, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_039:	sndparam_descriptor 0x0086c1, 69, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_040:	sndparam_descriptor 0x008800, 2, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_041:	sndparam_descriptor 0x008801, 178, 2, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_042:	sndparam_descriptor 0x008807, 2, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_043:	sndparam_descriptor 0x008808, 2, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_044:	sndparam_descriptor 0x00880a, 2, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_045:	sndparam_descriptor 0x00880b, 179, 2, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_046:	sndparam_descriptor 0x008820, 2, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_047:	sndparam_descriptor 0x008840, 2, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_048:	sndparam_descriptor 0x00885b, 2, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_049:	sndparam_descriptor 0x00885d, 2, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_050:	sndparam_descriptor 0x00885e, 2, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_051:	sndparam_descriptor 0x008878, 174, 2, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_052:	sndparam_descriptor 0x008880, 2, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_053:	sndparam_descriptor 0x008881, 2, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_054:	sndparam_descriptor 0x008882, 2, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_055:	sndparam_descriptor 0x0089b0, 177, 2, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_056:	sndparam_descriptor 0x0089b2, 180, 2, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_057:	sndparam_descriptor 0x008a21, 70, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_058:	sndparam_descriptor 0x008acc, 70, 1, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_059:	sndparam_descriptor 0x008acb, 70, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_060:	sndparam_descriptor 0x008a93, 70, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_061:	sndparam_descriptor 0x008a94, 70, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
VoiceParamEx_Entry_062:	sndparam_descriptor 0x008a80, 70, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_063:	sndparam_descriptor 0x008a81, 70, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_064:	sndparam_descriptor 0x008a82, 70, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_065:	sndparam_descriptor 0x008a83, 70, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_066:	sndparam_descriptor 0x008a84, 70, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_067:	sndparam_descriptor 0x008a85, 70, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_068:	sndparam_descriptor 0x008a86, 70, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_069:	sndparam_descriptor 0x008a87, 70, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_070:	sndparam_descriptor 0x008a88, 70, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_071:	sndparam_descriptor 0x008ac0, 70, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_072:	sndparam_descriptor 0x008ac1, 70, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_073:	sndparam_descriptor 0x008c00, 3, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_074:	sndparam_descriptor 0x008c01, 178, 3, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_075:	sndparam_descriptor 0x008c07, 3, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_076:	sndparam_descriptor 0x008c08, 3, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_077:	sndparam_descriptor 0x008c0a, 3, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_078:	sndparam_descriptor 0x008c0b, 179, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_079:	sndparam_descriptor 0x008c20, 3, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_080:	sndparam_descriptor 0x008c40, 3, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_081:	sndparam_descriptor 0x008c5b, 3, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_082:	sndparam_descriptor 0x008c5d, 3, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceParamEx_Entry_083:	sndparam_descriptor 0x008c5e, 3, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
VoiceParamEx_Entry_084:	sndparam_descriptor 0x008c78, 174, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
VoiceParamEx_Entry_085:	sndparam_descriptor 0x008c80, 3, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_001:	sndparam_descriptor 0x008c81, 3, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_002:	sndparam_descriptor 0x008c82, 3, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_003:	sndparam_descriptor 0x008db0, 177, 3, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_004:	sndparam_descriptor 0x008db2, 180, 3, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_005:	sndparam_descriptor 0x009000, 4, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_006:	sndparam_descriptor 0x009001, 178, 4, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_007:	sndparam_descriptor 0x009007, 4, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_008:	sndparam_descriptor 0x009008, 4, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_009:	sndparam_descriptor 0x00900a, 4, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_010:	sndparam_descriptor 0x00900b, 179, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_011:	sndparam_descriptor 0x009020, 4, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_012:	sndparam_descriptor 0x009040, 4, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_013:	sndparam_descriptor 0x00905b, 4, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_014:	sndparam_descriptor 0x00905d, 4, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_015:	sndparam_descriptor 0x00905e, 4, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_016:	sndparam_descriptor 0x009078, 174, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_017:	sndparam_descriptor 0x009080, 4, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_018:	sndparam_descriptor 0x009081, 4, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_019:	sndparam_descriptor 0x009082, 4, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_020:	sndparam_descriptor 0x0091b0, 177, 4, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_021:	sndparam_descriptor 0x0091b2, 180, 4, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_022:	sndparam_descriptor 0x009400, 5, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_023:	sndparam_descriptor 0x009401, 178, 5, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_024:	sndparam_descriptor 0x009407, 5, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_025:	sndparam_descriptor 0x009408, 5, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_026:	sndparam_descriptor 0x00940a, 5, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_027:	sndparam_descriptor 0x00940b, 179, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_028:	sndparam_descriptor 0x009420, 5, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_029:	sndparam_descriptor 0x009440, 5, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_030:	sndparam_descriptor 0x00945b, 5, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_031:	sndparam_descriptor 0x00945d, 5, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_032:	sndparam_descriptor 0x00945e, 5, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_033:	sndparam_descriptor 0x009478, 174, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_034:	sndparam_descriptor 0x009480, 5, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_035:	sndparam_descriptor 0x009481, 5, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_036:	sndparam_descriptor 0x009482, 5, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_037:	sndparam_descriptor 0x0095b0, 177, 5, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_038:	sndparam_descriptor 0x0095b2, 180, 5, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_039:	sndparam_descriptor 0x009800, 6, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_040:	sndparam_descriptor 0x009801, 178, 6, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_041:	sndparam_descriptor 0x009807, 6, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_042:	sndparam_descriptor 0x009808, 6, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_043:	sndparam_descriptor 0x00980a, 6, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_044:	sndparam_descriptor 0x00980b, 179, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_045:	sndparam_descriptor 0x009820, 6, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_046:	sndparam_descriptor 0x009840, 6, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_047:	sndparam_descriptor 0x00985b, 6, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_048:	sndparam_descriptor 0x00985d, 6, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_049:	sndparam_descriptor 0x00985e, 6, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_050:	sndparam_descriptor 0x009878, 174, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_051:	sndparam_descriptor 0x009880, 6, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_052:	sndparam_descriptor 0x009881, 6, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_053:	sndparam_descriptor 0x009882, 6, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_054:	sndparam_descriptor 0x0099b0, 177, 6, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_055:	sndparam_descriptor 0x0099b2, 180, 6, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_056:	sndparam_descriptor 0x009c00, 7, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_057:	sndparam_descriptor 0x009c01, 178, 7, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_058:	sndparam_descriptor 0x009c07, 7, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_059:	sndparam_descriptor 0x009c08, 7, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_060:	sndparam_descriptor 0x009c0a, 7, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_061:	sndparam_descriptor 0x009c0b, 179, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_062:	sndparam_descriptor 0x009c20, 7, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_063:	sndparam_descriptor 0x009c40, 7, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_064:	sndparam_descriptor 0x009c5b, 7, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_065:	sndparam_descriptor 0x009c5d, 7, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_066:	sndparam_descriptor 0x009c5e, 7, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_067:	sndparam_descriptor 0x009c78, 174, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_068:	sndparam_descriptor 0x009c80, 7, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_069:	sndparam_descriptor 0x009c81, 7, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_070:	sndparam_descriptor 0x009c82, 7, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_071:	sndparam_descriptor 0x009db0, 177, 7, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_072:	sndparam_descriptor 0x009db2, 180, 7, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_073:	sndparam_descriptor 0x00a000, 8, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_074:	sndparam_descriptor 0x00a001, 178, 8, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_075:	sndparam_descriptor 0x00a007, 8, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_076:	sndparam_descriptor 0x00a008, 8, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_077:	sndparam_descriptor 0x00a00a, 8, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_078:	sndparam_descriptor 0x00a00b, 179, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_079:	sndparam_descriptor 0x00a020, 8, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_080:	sndparam_descriptor 0x00a040, 8, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_081:	sndparam_descriptor 0x00a05b, 8, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_082:	sndparam_descriptor 0x00a05d, 8, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_083:	sndparam_descriptor 0x00a05e, 8, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_084:	sndparam_descriptor 0x00a078, 174, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_085:	sndparam_descriptor 0x00a080, 8, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_086:	sndparam_descriptor 0x00a081, 8, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_087:	sndparam_descriptor 0x00a082, 8, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_088:	sndparam_descriptor 0x00a1b0, 177, 8, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_089:	sndparam_descriptor 0x00a1b2, 180, 8, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_090:	sndparam_descriptor 0x00a400, 9, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_091:	sndparam_descriptor 0x00a401, 178, 9, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_092:	sndparam_descriptor 0x00a407, 9, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_093:	sndparam_descriptor 0x00a408, 9, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_094:	sndparam_descriptor 0x00a40a, 9, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_095:	sndparam_descriptor 0x00a40b, 179, 9, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_096:	sndparam_descriptor 0x00a420, 9, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_097:	sndparam_descriptor 0x00a440, 9, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_098:	sndparam_descriptor 0x00a45b, 9, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_099:	sndparam_descriptor 0x00a45d, 9, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_100:	sndparam_descriptor 0x00a45e, 9, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_101:	sndparam_descriptor 0x00a478, 174, 9, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_102:	sndparam_descriptor 0x00a480, 9, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_103:	sndparam_descriptor 0x00a481, 9, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_104:	sndparam_descriptor 0x00a482, 9, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_105:	sndparam_descriptor 0x00a5b0, 177, 9, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_106:	sndparam_descriptor 0x00a5b2, 180, 9, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_107:	sndparam_descriptor 0x00a800, 10, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_108:	sndparam_descriptor 0x00a801, 178, 10, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_109:	sndparam_descriptor 0x00a807, 10, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_110:	sndparam_descriptor 0x00a808, 10, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_111:	sndparam_descriptor 0x00a80a, 10, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_112:	sndparam_descriptor 0x00a80b, 179, 10, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_113:	sndparam_descriptor 0x00a820, 10, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_114:	sndparam_descriptor 0x00a840, 10, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_115:	sndparam_descriptor 0x00a85b, 10, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_116:	sndparam_descriptor 0x00a85d, 10, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_117:	sndparam_descriptor 0x00a85e, 10, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_118:	sndparam_descriptor 0x00a878, 174, 10, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_119:	sndparam_descriptor 0x00a880, 10, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_120:	sndparam_descriptor 0x00a881, 10, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_121:	sndparam_descriptor 0x00a882, 10, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_122:	sndparam_descriptor 0x00a9b0, 177, 10, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_123:	sndparam_descriptor 0x00a9b2, 180, 10, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_124:	sndparam_descriptor 0x00ac00, 11, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_125:	sndparam_descriptor 0x00ac01, 178, 11, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_126:	sndparam_descriptor 0x00ac07, 11, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_127:	sndparam_descriptor 0x00ac08, 11, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_128:	sndparam_descriptor 0x00ac0a, 11, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_129:	sndparam_descriptor 0x00ac0b, 179, 11, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_130:	sndparam_descriptor 0x00ac20, 11, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_131:	sndparam_descriptor 0x00ac40, 11, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_132:	sndparam_descriptor 0x00ac5b, 11, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_133:	sndparam_descriptor 0x00ac5d, 11, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_134:	sndparam_descriptor 0x00ac5e, 11, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_135:	sndparam_descriptor 0x00ac78, 174, 11, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_136:	sndparam_descriptor 0x00ac80, 11, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_137:	sndparam_descriptor 0x00ac81, 11, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_138:	sndparam_descriptor 0x00ac82, 11, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_139:	sndparam_descriptor 0x00adb0, 177, 11, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_140:	sndparam_descriptor 0x00adb2, 180, 11, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_141:	sndparam_descriptor 0x00b000, 12, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_142:	sndparam_descriptor 0x00b001, 178, 12, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_143:	sndparam_descriptor 0x00b007, 12, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_144:	sndparam_descriptor 0x00b008, 12, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_145:	sndparam_descriptor 0x00b00a, 12, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_146:	sndparam_descriptor 0x00b00b, 179, 12, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_147:	sndparam_descriptor 0x00b020, 12, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_148:	sndparam_descriptor 0x00b040, 12, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_149:	sndparam_descriptor 0x00b05b, 12, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_150:	sndparam_descriptor 0x00b05d, 12, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_151:	sndparam_descriptor 0x00b05e, 12, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_152:	sndparam_descriptor 0x00b078, 174, 12, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_153:	sndparam_descriptor 0x00b080, 12, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_154:	sndparam_descriptor 0x00b081, 12, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_155:	sndparam_descriptor 0x00b082, 12, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_156:	sndparam_descriptor 0x00b1b0, 177, 12, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_157:	sndparam_descriptor 0x00b1b2, 180, 12, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_158:	sndparam_descriptor 0x00b400, 13, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_159:	sndparam_descriptor 0x00b401, 178, 13, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_160:	sndparam_descriptor 0x00b407, 13, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_161:	sndparam_descriptor 0x00b408, 13, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_162:	sndparam_descriptor 0x00b40a, 13, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_163:	sndparam_descriptor 0x00b40b, 179, 13, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_164:	sndparam_descriptor 0x00b420, 13, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_165:	sndparam_descriptor 0x00b440, 13, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_166:	sndparam_descriptor 0x00b45b, 13, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_167:	sndparam_descriptor 0x00b45d, 13, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_168:	sndparam_descriptor 0x00b45e, 13, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_169:	sndparam_descriptor 0x00b478, 174, 13, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_170:	sndparam_descriptor 0x00b480, 13, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_171:	sndparam_descriptor 0x00b481, 13, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_172:	sndparam_descriptor 0x00b482, 13, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_173:	sndparam_descriptor 0x00b5b0, 177, 13, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_174:	sndparam_descriptor 0x00b5b2, 180, 13, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_175:	sndparam_descriptor 0x00b800, 14, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_176:	sndparam_descriptor 0x00b801, 178, 14, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_177:	sndparam_descriptor 0x00b807, 14, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_178:	sndparam_descriptor 0x00b808, 14, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_179:	sndparam_descriptor 0x00b80a, 14, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_180:	sndparam_descriptor 0x00b80b, 179, 14, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_181:	sndparam_descriptor 0x00b820, 14, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_182:	sndparam_descriptor 0x00b840, 14, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_183:	sndparam_descriptor 0x00b85b, 14, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_184:	sndparam_descriptor 0x00b85d, 14, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_185:	sndparam_descriptor 0x00b85e, 14, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_186:	sndparam_descriptor 0x00b878, 174, 14, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_187:	sndparam_descriptor 0x00b880, 14, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_188:	sndparam_descriptor 0x00b881, 14, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_189:	sndparam_descriptor 0x00b882, 14, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_190:	sndparam_descriptor 0x00b9b0, 177, 14, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_191:	sndparam_descriptor 0x00b9b2, 180, 14, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_192:	sndparam_descriptor 0x00bc00, 15, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_193:	sndparam_descriptor 0x00bc01, 178, 15, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_194:	sndparam_descriptor 0x00bc07, 15, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_195:	sndparam_descriptor 0x00bc08, 15, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_196:	sndparam_descriptor 0x00bc0a, 15, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_197:	sndparam_descriptor 0x00bc0b, 179, 15, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_198:	sndparam_descriptor 0x00bc20, 15, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_199:	sndparam_descriptor 0x00bc40, 15, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_200:	sndparam_descriptor 0x00bc5b, 15, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_201:	sndparam_descriptor 0x00bc5d, 15, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_202:	sndparam_descriptor 0x00bc5e, 15, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
PartParam_Entry_203:	sndparam_descriptor 0x00bc78, 174, 15, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_204:	sndparam_descriptor 0x00bc80, 15, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_205:	sndparam_descriptor 0x00bc81, 15, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_206:	sndparam_descriptor 0x00bc82, 15, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_207:	sndparam_descriptor 0x00bdb0, 177, 15, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_208:	sndparam_descriptor 0x00bdb2, 180, 15, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_209:	sndparam_descriptor 0x00c000, 16, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
PartParam_Entry_210:	sndparam_descriptor 0x00c001, 178, 16, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
PartParam_Entry_211:	sndparam_descriptor 0x00c007, 16, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_212:	sndparam_descriptor 0x00c008, 16, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_213:	sndparam_descriptor 0x00c00a, 16, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
PartParam_Entry_214:	sndparam_descriptor 0x00c00b, 179, 16, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
PartParam_Entry_215:	sndparam_descriptor 0x00c020, 16, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
PartParam_Entry_216:	sndparam_descriptor 0x00c040, 16, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
PartParam_Entry_217:	sndparam_descriptor 0x00c05b, 16, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_218:	sndparam_descriptor 0x00c05d, 16, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_219:	sndparam_descriptor 0x00c05e, 16, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
PartParam_Entry_220:	sndparam_descriptor 0x00c078, 174, 16, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
PartParam_Entry_221:	sndparam_descriptor 0x00c080, 16, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_222:	sndparam_descriptor 0x00c081, 16, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_223:	sndparam_descriptor 0x00c082, 16, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
PartParam_Entry_224:	sndparam_descriptor 0x00c1b0, 177, 16, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
PartParam_Entry_225:	sndparam_descriptor 0x00c1b2, 180, 16, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
PartParam_Entry_226:	sndparam_descriptor 0x00c400, 17, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
PartParam_Entry_227:	sndparam_descriptor 0x00c401, 178, 17, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_228:	sndparam_descriptor 0x00c407, 17, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_229:	sndparam_descriptor 0x00c408, 17, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_230:	sndparam_descriptor 0x00c40a, 17, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_231:	sndparam_descriptor 0x00c40b, 179, 17, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_232:	sndparam_descriptor 0x00c420, 17, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
ExtPartParam_Entry_233:	sndparam_descriptor 0x00c440, 17, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_234:	sndparam_descriptor 0x00c45b, 17, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_235:	sndparam_descriptor 0x00c45d, 17, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_236:	sndparam_descriptor 0x00c45e, 17, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_237:	sndparam_descriptor 0x00c478, 174, 17, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_238:	sndparam_descriptor 0x00c480, 17, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_239:	sndparam_descriptor 0x00c481, 17, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_240:	sndparam_descriptor 0x00c482, 17, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_241:	sndparam_descriptor 0x00c5b0, 177, 17, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_242:	sndparam_descriptor 0x00c5b2, 180, 17, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_243:	sndparam_descriptor 0x00c800, 18, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
ExtPartParam_Entry_244:	sndparam_descriptor 0x00c801, 178, 18, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_245:	sndparam_descriptor 0x00c807, 18, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_246:	sndparam_descriptor 0x00c808, 18, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_247:	sndparam_descriptor 0x00c80a, 18, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_248:	sndparam_descriptor 0x00c80b, 179, 18, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_249:	sndparam_descriptor 0x00c820, 18, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
ExtPartParam_Entry_250:	sndparam_descriptor 0x00c840, 18, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_251:	sndparam_descriptor 0x00c85b, 18, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_252:	sndparam_descriptor 0x00c85d, 18, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_253:	sndparam_descriptor 0x00c85e, 18, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_254:	sndparam_descriptor 0x00c878, 174, 18, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_255:	sndparam_descriptor 0x00c880, 18, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_256:	sndparam_descriptor 0x00c881, 18, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_257:	sndparam_descriptor 0x00c882, 18, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_258:	sndparam_descriptor 0x00c9b0, 177, 18, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_259:	sndparam_descriptor 0x00c9b2, 180, 18, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_260:	sndparam_descriptor 0x00cc00, 19, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
ExtPartParam_Entry_261:	sndparam_descriptor 0x00cc01, 178, 19, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_262:	sndparam_descriptor 0x00cc07, 19, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_263:	sndparam_descriptor 0x00cc08, 19, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_264:	sndparam_descriptor 0x00cc0a, 19, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_265:	sndparam_descriptor 0x00cc0b, 179, 19, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_266:	sndparam_descriptor 0x00cc20, 19, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
ExtPartParam_Entry_267:	sndparam_descriptor 0x00cc40, 19, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_268:	sndparam_descriptor 0x00cc5b, 19, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_269:	sndparam_descriptor 0x00cc5d, 19, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_270:	sndparam_descriptor 0x00cc5e, 19, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_271:	sndparam_descriptor 0x00cc78, 174, 19, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_272:	sndparam_descriptor 0x00cc80, 19, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_273:	sndparam_descriptor 0x00cc81, 19, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_274:	sndparam_descriptor 0x00cc82, 19, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_275:	sndparam_descriptor 0x00cdb0, 177, 19, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_276:	sndparam_descriptor 0x00cdb2, 180, 19, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_277:	sndparam_descriptor 0x00d000, 20, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_278:	sndparam_descriptor 0x00d001, 178, 20, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_279:	sndparam_descriptor 0x00d007, 20, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_280:	sndparam_descriptor 0x00d008, 20, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_281:	sndparam_descriptor 0x00d00a, 20, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_282:	sndparam_descriptor 0x00d00b, 179, 20, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_283:	sndparam_descriptor 0x00d020, 20, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_284:	sndparam_descriptor 0x00d040, 20, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_285:	sndparam_descriptor 0x00d05b, 20, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_286:	sndparam_descriptor 0x00d05d, 20, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_287:	sndparam_descriptor 0x00d05e, 20, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_288:	sndparam_descriptor 0x00d078, 174, 20, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_289:	sndparam_descriptor 0x00d080, 20, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_290:	sndparam_descriptor 0x00d081, 20, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_291:	sndparam_descriptor 0x00d082, 20, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_292:	sndparam_descriptor 0x00d1b0, 177, 20, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_293:	sndparam_descriptor 0x00d1b2, 180, 20, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_294:	sndparam_descriptor 0x00d400, 21, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_295:	sndparam_descriptor 0x00d401, 178, 21, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_296:	sndparam_descriptor 0x00d407, 21, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_297:	sndparam_descriptor 0x00d408, 21, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_298:	sndparam_descriptor 0x00d40a, 21, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_299:	sndparam_descriptor 0x00d40b, 179, 21, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_300:	sndparam_descriptor 0x00d420, 21, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_301:	sndparam_descriptor 0x00d440, 21, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
ExtPartParam_Entry_302:	sndparam_descriptor 0x00d45b, 21, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_303:	sndparam_descriptor 0x00d45d, 21, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_304:	sndparam_descriptor 0x00d45e, 21, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
ExtPartParam_Entry_305:	sndparam_descriptor 0x00d478, 174, 21, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_306:	sndparam_descriptor 0x00d480, 21, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_307:	sndparam_descriptor 0x00d481, 21, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_308:	sndparam_descriptor 0x00d482, 21, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_309:	sndparam_descriptor 0x00d5b0, 177, 21, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_310:	sndparam_descriptor 0x00d5b2, 180, 21, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_311:	sndparam_descriptor 0x00d800, 22, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_312:	sndparam_descriptor 0x00d801, 178, 22, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_313:	sndparam_descriptor 0x00d807, 22, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_314:	sndparam_descriptor 0x00d808, 22, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_315:	sndparam_descriptor 0x00d80a, 22, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_316:	sndparam_descriptor 0x00d80b, 179, 22, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_317:	sndparam_descriptor 0x00d820, 22, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_318:	sndparam_descriptor 0x00d840, 22, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
ExtPartParam_Entry_319:	sndparam_descriptor 0x00d85b, 22, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_320:	sndparam_descriptor 0x00d85d, 22, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_321:	sndparam_descriptor 0x00d85e, 22, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
ExtPartParam_Entry_322:	sndparam_descriptor 0x00d878, 174, 22, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_323:	sndparam_descriptor 0x00d880, 22, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_324:	sndparam_descriptor 0x00d881, 22, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_325:	sndparam_descriptor 0x00d882, 22, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_326:	sndparam_descriptor 0x00d9b0, 177, 22, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_327:	sndparam_descriptor 0x00d9b2, 180, 22, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_328:	sndparam_descriptor 0x00dc00, 23, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
ExtPartParam_Entry_329:	sndparam_descriptor 0x00dc01, 178, 23, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_330:	sndparam_descriptor 0x00dc07, 23, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_331:	sndparam_descriptor 0x00dc08, 23, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_332:	sndparam_descriptor 0x00dc0a, 23, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_333:	sndparam_descriptor 0x00dc0b, 179, 23, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_334:	sndparam_descriptor 0x00dc20, 23, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
ExtPartParam_Entry_335:	sndparam_descriptor 0x00dc40, 23, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_336:	sndparam_descriptor 0x00dc5b, 23, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_337:	sndparam_descriptor 0x00dc5d, 23, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_338:	sndparam_descriptor 0x00dc5e, 23, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_339:	sndparam_descriptor 0x00dc78, 174, 23, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_340:	sndparam_descriptor 0x00dc80, 23, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_341:	sndparam_descriptor 0x00dc81, 23, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_342:	sndparam_descriptor 0x00dc82, 23, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_343:	sndparam_descriptor 0x00ddb0, 177, 23, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_344:	sndparam_descriptor 0x00ddb2, 180, 23, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_345:	sndparam_descriptor 0x00e000, 24, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
ExtPartParam_Entry_346:	sndparam_descriptor 0x00e001, 178, 24, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
ExtPartParam_Entry_347:	sndparam_descriptor 0x00e007, 24, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_348:	sndparam_descriptor 0x00e008, 24, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_349:	sndparam_descriptor 0x00e00a, 24, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_350:	sndparam_descriptor 0x00e00b, 179, 24, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
ExtPartParam_Entry_351:	sndparam_descriptor 0x00e020, 24, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
ExtPartParam_Entry_352:	sndparam_descriptor 0x00e040, 24, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_353:	sndparam_descriptor 0x00e05b, 24, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_354:	sndparam_descriptor 0x00e05d, 24, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_355:	sndparam_descriptor 0x00e05e, 24, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
ExtPartParam_Entry_356:	sndparam_descriptor 0x00e078, 174, 24, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_357:	sndparam_descriptor 0x00e080, 24, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_358:	sndparam_descriptor 0x00e081, 24, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_359:	sndparam_descriptor 0x00e082, 24, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_360:	sndparam_descriptor 0x00e1b0, 177, 24, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
ExtPartParam_Entry_361:	sndparam_descriptor 0x00e1b2, 180, 24, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
ExtPartParam_Entry_362:	sndparam_descriptor 0x00e807, 152, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_363:	sndparam_descriptor 0x00e808, 152, 4, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_364:	sndparam_descriptor 0x018000, 0, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_365:	sndparam_descriptor 0x018001, 0, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_366:	sndparam_descriptor 0x018002, 0, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_367:	sndparam_descriptor 0x018003, 0, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_368:
	.byte 0x04, 0x80, 0x01, 0x00, 0x00, 0x0c, 0x07, 0x00, 0x7f, 0x00, 0x00, 0x02, 0x01, 0x07, 0x05, 0x00
	.byte 0x00, 0xff, 0x05, 0x06, 0x07, 0x00, 0x01, 0x02, 0x03, 0xff
WidgetParam_MidiCC_PitchBend:
	.byte 0xea, 0xe9, 0xed, 0x00, 0x07, 0x00, 0x00, 0x03, 0x00, 0xff
;  314 x 18-byte sound-parameter descriptors, 0xEDE9FC-0xEE0010, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_ede9fc.c.
SndParamRun_EDE9FC:
ExtPartParam_Entry_369:	sndparam_descriptor 0x018200, 0, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
ExtPartParam_Entry_370:	sndparam_descriptor 0x018201, 0, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_371:	sndparam_descriptor 0x018202, 0, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_372:	sndparam_descriptor 0x018203, 0, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_373:	sndparam_descriptor 0x018204, 0, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_374:	sndparam_descriptor 0x018205, 0, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_375:	sndparam_descriptor 0x018206, 0, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_376:	sndparam_descriptor 0x018400, 1, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_377:	sndparam_descriptor 0x018401, 1, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_378:	sndparam_descriptor 0x018402, 1, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_379:	sndparam_descriptor 0x018403, 1, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_380:	sndparam_descriptor 0x018404, 1, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_381:	sndparam_descriptor 0x018600, 1, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_382:	sndparam_descriptor 0x018601, 1, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_383:	sndparam_descriptor 0x018602, 1, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_384:	sndparam_descriptor 0x018603, 1, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_385:	sndparam_descriptor 0x018604, 1, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_386:	sndparam_descriptor 0x018605, 1, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_387:	sndparam_descriptor 0x018606, 1, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_388:	sndparam_descriptor 0x018800, 2, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_389:	sndparam_descriptor 0x018801, 2, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_390:	sndparam_descriptor 0x018802, 2, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_391:	sndparam_descriptor 0x018803, 2, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_392:	sndparam_descriptor 0x018804, 2, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_393:	sndparam_descriptor 0x018a00, 2, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_394:	sndparam_descriptor 0x018a01, 2, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_395:	sndparam_descriptor 0x018a02, 2, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_396:	sndparam_descriptor 0x018a03, 2, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_397:	sndparam_descriptor 0x018a04, 2, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_398:	sndparam_descriptor 0x018a05, 2, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_399:	sndparam_descriptor 0x018a06, 2, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_400:	sndparam_descriptor 0x018c00, 3, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_401:	sndparam_descriptor 0x018c01, 3, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_402:	sndparam_descriptor 0x018c02, 3, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_403:	sndparam_descriptor 0x018c03, 3, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_404:	sndparam_descriptor 0x018c04, 3, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_405:	sndparam_descriptor 0x018e00, 3, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_406:	sndparam_descriptor 0x018e01, 3, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_407:	sndparam_descriptor 0x018e02, 3, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_408:	sndparam_descriptor 0x018e03, 3, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_409:	sndparam_descriptor 0x018e04, 3, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_410:	sndparam_descriptor 0x018e05, 3, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_411:	sndparam_descriptor 0x018e06, 3, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_412:	sndparam_descriptor 0x019000, 4, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_413:	sndparam_descriptor 0x019001, 4, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_414:	sndparam_descriptor 0x019002, 4, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_415:	sndparam_descriptor 0x019003, 4, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_416:	sndparam_descriptor 0x019004, 4, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_417:	sndparam_descriptor 0x019200, 4, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_418:	sndparam_descriptor 0x019201, 4, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_419:	sndparam_descriptor 0x019202, 4, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_420:	sndparam_descriptor 0x019203, 4, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_421:	sndparam_descriptor 0x019204, 4, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_422:	sndparam_descriptor 0x019205, 4, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_423:	sndparam_descriptor 0x019206, 4, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_424:	sndparam_descriptor 0x019400, 5, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_425:	sndparam_descriptor 0x019401, 5, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_426:	sndparam_descriptor 0x019402, 5, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_427:	sndparam_descriptor 0x019403, 5, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_428:	sndparam_descriptor 0x019404, 5, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_429:	sndparam_descriptor 0x019600, 5, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_430:	sndparam_descriptor 0x019601, 5, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_431:	sndparam_descriptor 0x019602, 5, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_432:	sndparam_descriptor 0x019603, 5, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_433:	sndparam_descriptor 0x019604, 5, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_434:	sndparam_descriptor 0x019605, 5, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_435:	sndparam_descriptor 0x019606, 5, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_436:	sndparam_descriptor 0x019800, 6, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_437:	sndparam_descriptor 0x019801, 6, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_438:	sndparam_descriptor 0x019802, 6, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_439:	sndparam_descriptor 0x019803, 6, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_440:	sndparam_descriptor 0x019804, 6, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_441:	sndparam_descriptor 0x019a00, 6, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_442:	sndparam_descriptor 0x019a01, 6, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_443:	sndparam_descriptor 0x019a02, 6, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_444:	sndparam_descriptor 0x019a03, 6, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_445:	sndparam_descriptor 0x019a04, 6, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_446:	sndparam_descriptor 0x019a05, 6, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_447:	sndparam_descriptor 0x019a06, 6, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_448:	sndparam_descriptor 0x019c00, 7, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_449:	sndparam_descriptor 0x019c01, 7, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_450:	sndparam_descriptor 0x019c02, 7, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_451:	sndparam_descriptor 0x019c03, 7, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_452:	sndparam_descriptor 0x019c04, 7, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
ExtPartParam_Entry_453:	sndparam_descriptor 0x019e00, 7, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
ExtPartParam_Entry_454:	sndparam_descriptor 0x019e01, 7, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_001:	sndparam_descriptor 0x019e02, 7, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_002:	sndparam_descriptor 0x019e03, 7, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_003:	sndparam_descriptor 0x019e04, 7, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_004:	sndparam_descriptor 0x019e05, 7, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_005:	sndparam_descriptor 0x019e06, 7, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_006:	sndparam_descriptor 0x01a000, 8, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_007:	sndparam_descriptor 0x01a001, 8, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_008:	sndparam_descriptor 0x01a002, 8, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_009:	sndparam_descriptor 0x01a003, 8, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_010:	sndparam_descriptor 0x01a004, 8, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_011:	sndparam_descriptor 0x01a200, 8, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_012:	sndparam_descriptor 0x01a201, 8, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_013:	sndparam_descriptor 0x01a202, 8, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_014:	sndparam_descriptor 0x01a203, 8, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_015:	sndparam_descriptor 0x01a204, 8, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_016:	sndparam_descriptor 0x01a205, 8, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_017:	sndparam_descriptor 0x01a206, 8, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_018:	sndparam_descriptor 0x01a400, 9, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_019:	sndparam_descriptor 0x01a401, 9, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_020:	sndparam_descriptor 0x01a402, 9, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_021:	sndparam_descriptor 0x01a403, 9, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_022:	sndparam_descriptor 0x01a404, 9, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_023:	sndparam_descriptor 0x01a600, 9, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_024:	sndparam_descriptor 0x01a601, 9, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_025:	sndparam_descriptor 0x01a602, 9, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_026:	sndparam_descriptor 0x01a603, 9, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_027:	sndparam_descriptor 0x01a604, 9, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_028:	sndparam_descriptor 0x01a605, 9, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_029:	sndparam_descriptor 0x01a606, 9, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_030:	sndparam_descriptor 0x01a800, 10, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_031:	sndparam_descriptor 0x01a801, 10, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_032:	sndparam_descriptor 0x01a802, 10, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_033:	sndparam_descriptor 0x01a803, 10, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_034:	sndparam_descriptor 0x01a804, 10, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_035:	sndparam_descriptor 0x01aa00, 10, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_036:	sndparam_descriptor 0x01aa01, 10, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_037:	sndparam_descriptor 0x01aa02, 10, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_038:	sndparam_descriptor 0x01aa03, 10, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_039:	sndparam_descriptor 0x01aa04, 10, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_040:	sndparam_descriptor 0x01aa05, 10, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_041:	sndparam_descriptor 0x01aa06, 10, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_042:	sndparam_descriptor 0x01ac00, 11, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_043:	sndparam_descriptor 0x01ac01, 11, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_044:	sndparam_descriptor 0x01ac02, 11, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_045:	sndparam_descriptor 0x01ac03, 11, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_046:	sndparam_descriptor 0x01ac04, 11, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_047:	sndparam_descriptor 0x01ae00, 11, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_048:	sndparam_descriptor 0x01ae01, 11, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_049:	sndparam_descriptor 0x01ae02, 11, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_050:	sndparam_descriptor 0x01ae03, 11, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_051:	sndparam_descriptor 0x01ae04, 11, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_052:	sndparam_descriptor 0x01ae05, 11, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_053:	sndparam_descriptor 0x01ae06, 11, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_054:	sndparam_descriptor 0x01b000, 12, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_055:	sndparam_descriptor 0x01b001, 12, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_056:	sndparam_descriptor 0x01b002, 12, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_057:	sndparam_descriptor 0x01b003, 12, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_058:	sndparam_descriptor 0x01b004, 12, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_059:	sndparam_descriptor 0x01b200, 12, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_060:	sndparam_descriptor 0x01b201, 12, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_061:	sndparam_descriptor 0x01b202, 12, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_062:	sndparam_descriptor 0x01b203, 12, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_063:	sndparam_descriptor 0x01b204, 12, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_064:	sndparam_descriptor 0x01b205, 12, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_065:	sndparam_descriptor 0x01b206, 12, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_066:	sndparam_descriptor 0x01b400, 13, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_067:	sndparam_descriptor 0x01b401, 13, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_068:	sndparam_descriptor 0x01b402, 13, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_069:	sndparam_descriptor 0x01b403, 13, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_070:	sndparam_descriptor 0x01b404, 13, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_071:	sndparam_descriptor 0x01b600, 13, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_072:	sndparam_descriptor 0x01b601, 13, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_073:	sndparam_descriptor 0x01b602, 13, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_074:	sndparam_descriptor 0x01b603, 13, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_075:	sndparam_descriptor 0x01b604, 13, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_076:	sndparam_descriptor 0x01b605, 13, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_077:	sndparam_descriptor 0x01b606, 13, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_078:	sndparam_descriptor 0x01b800, 14, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_079:	sndparam_descriptor 0x01b801, 14, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_080:	sndparam_descriptor 0x01b802, 14, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_081:	sndparam_descriptor 0x01b803, 14, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_082:	sndparam_descriptor 0x01b804, 14, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_083:	sndparam_descriptor 0x01ba00, 14, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_084:	sndparam_descriptor 0x01ba01, 14, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_085:	sndparam_descriptor 0x01ba02, 14, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_086:	sndparam_descriptor 0x01ba03, 14, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_087:	sndparam_descriptor 0x01ba04, 14, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_088:	sndparam_descriptor 0x01ba05, 14, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_089:	sndparam_descriptor 0x01ba06, 14, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_090:	sndparam_descriptor 0x01bc00, 15, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_091:	sndparam_descriptor 0x01bc01, 15, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_092:	sndparam_descriptor 0x01bc02, 15, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_093:	sndparam_descriptor 0x01bc03, 15, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_094:	sndparam_descriptor 0x01bc04, 15, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_095:	sndparam_descriptor 0x01be00, 15, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
SeqMixParam_Entry_096:	sndparam_descriptor 0x01be01, 15, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_097:	sndparam_descriptor 0x01be02, 15, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_098:	sndparam_descriptor 0x01be03, 15, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_099:	sndparam_descriptor 0x01be04, 15, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_100:	sndparam_descriptor 0x01be05, 15, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_101:	sndparam_descriptor 0x01be06, 15, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_102:	sndparam_descriptor 0x01c000, 16, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_103:	sndparam_descriptor 0x01c001, 16, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_104:	sndparam_descriptor 0x01c002, 16, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_105:	sndparam_descriptor 0x01c003, 16, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_106:	sndparam_descriptor 0x01c004, 16, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_107:	sndparam_descriptor 0x01c200, 16, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
SeqMixParam_Entry_108:	sndparam_descriptor 0x01c201, 16, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_109:	sndparam_descriptor 0x01c202, 16, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_110:	sndparam_descriptor 0x01c203, 16, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_111:	sndparam_descriptor 0x01c204, 16, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_112:	sndparam_descriptor 0x01c205, 16, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_113:	sndparam_descriptor 0x01c206, 16, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_114:	sndparam_descriptor 0x01c400, 17, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_115:	sndparam_descriptor 0x01c401, 17, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_116:	sndparam_descriptor 0x01c402, 17, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_117:	sndparam_descriptor 0x01c403, 17, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_118:	sndparam_descriptor 0x01c404, 17, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_119:	sndparam_descriptor 0x01c600, 17, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_120:	sndparam_descriptor 0x01c601, 17, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_121:	sndparam_descriptor 0x01c602, 17, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_122:	sndparam_descriptor 0x01c603, 17, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_123:	sndparam_descriptor 0x01c604, 17, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_124:	sndparam_descriptor 0x01c605, 17, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_125:	sndparam_descriptor 0x01c606, 17, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_126:	sndparam_descriptor 0x01c800, 18, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_127:	sndparam_descriptor 0x01c801, 18, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_128:	sndparam_descriptor 0x01c802, 18, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_129:	sndparam_descriptor 0x01c803, 18, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_130:	sndparam_descriptor 0x01c804, 18, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_131:	sndparam_descriptor 0x01ca00, 18, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_132:	sndparam_descriptor 0x01ca01, 18, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_133:	sndparam_descriptor 0x01ca02, 18, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_134:	sndparam_descriptor 0x01ca03, 18, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_135:	sndparam_descriptor 0x01ca04, 18, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_136:	sndparam_descriptor 0x01ca05, 18, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_137:	sndparam_descriptor 0x01ca06, 18, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_138:	sndparam_descriptor 0x01cc00, 19, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_139:	sndparam_descriptor 0x01cc01, 19, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_140:	sndparam_descriptor 0x01cc02, 19, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_141:	sndparam_descriptor 0x01cc03, 19, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_142:	sndparam_descriptor 0x01cc04, 19, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_143:	sndparam_descriptor 0x01ce00, 19, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_144:	sndparam_descriptor 0x01ce01, 19, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_145:	sndparam_descriptor 0x01ce02, 19, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_146:	sndparam_descriptor 0x01ce03, 19, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_147:	sndparam_descriptor 0x01ce04, 19, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_148:	sndparam_descriptor 0x01ce05, 19, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_149:	sndparam_descriptor 0x01ce06, 19, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_150:	sndparam_descriptor 0x01d000, 20, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_151:	sndparam_descriptor 0x01d001, 20, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_152:	sndparam_descriptor 0x01d002, 20, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_153:	sndparam_descriptor 0x01d003, 20, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_154:	sndparam_descriptor 0x01d004, 20, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_155:	sndparam_descriptor 0x01d200, 20, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_156:	sndparam_descriptor 0x01d201, 20, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_157:	sndparam_descriptor 0x01d202, 20, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_158:	sndparam_descriptor 0x01d203, 20, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_159:	sndparam_descriptor 0x01d204, 20, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_160:	sndparam_descriptor 0x01d205, 20, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_161:	sndparam_descriptor 0x01d206, 20, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_162:	sndparam_descriptor 0x01d400, 21, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_163:	sndparam_descriptor 0x01d401, 21, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_164:	sndparam_descriptor 0x01d402, 21, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_165:	sndparam_descriptor 0x01d403, 21, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_166:	sndparam_descriptor 0x01d404, 21, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_167:	sndparam_descriptor 0x01d600, 21, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_168:	sndparam_descriptor 0x01d601, 21, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_169:	sndparam_descriptor 0x01d602, 21, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_170:	sndparam_descriptor 0x01d603, 21, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_171:	sndparam_descriptor 0x01d604, 21, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_172:	sndparam_descriptor 0x01d605, 21, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_173:	sndparam_descriptor 0x01d606, 21, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_174:	sndparam_descriptor 0x01d800, 22, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_175:	sndparam_descriptor 0x01d801, 22, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_176:	sndparam_descriptor 0x01d802, 22, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_177:	sndparam_descriptor 0x01d803, 22, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_178:	sndparam_descriptor 0x01d804, 22, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_179:	sndparam_descriptor 0x01da00, 22, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_180:	sndparam_descriptor 0x01da01, 22, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_181:	sndparam_descriptor 0x01da02, 22, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_182:	sndparam_descriptor 0x01da03, 22, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_183:	sndparam_descriptor 0x01da04, 22, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_184:	sndparam_descriptor 0x01da05, 22, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_185:	sndparam_descriptor 0x01da06, 22, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_186:	sndparam_descriptor 0x01dc00, 23, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_187:	sndparam_descriptor 0x01dc01, 23, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_188:	sndparam_descriptor 0x01dc02, 23, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_189:	sndparam_descriptor 0x01dc03, 23, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_190:	sndparam_descriptor 0x01dc04, 23, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_191:	sndparam_descriptor 0x01de00, 23, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_192:	sndparam_descriptor 0x01de01, 23, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_193:	sndparam_descriptor 0x01de02, 23, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_194:	sndparam_descriptor 0x01de03, 23, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_195:	sndparam_descriptor 0x01de04, 23, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_196:	sndparam_descriptor 0x01de05, 23, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_197:	sndparam_descriptor 0x01de06, 23, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_198:	sndparam_descriptor 0x01e000, 24, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_199:	sndparam_descriptor 0x01e001, 24, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_200:	sndparam_descriptor 0x01e002, 24, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_201:	sndparam_descriptor 0x01e003, 24, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_202:	sndparam_descriptor 0x01e004, 24, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_203:	sndparam_descriptor 0x01e200, 24, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_204:	sndparam_descriptor 0x01e201, 24, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_205:	sndparam_descriptor 0x01e202, 24, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_206:	sndparam_descriptor 0x01e203, 24, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_207:	sndparam_descriptor 0x01e204, 24, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_208:	sndparam_descriptor 0x01e205, 24, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_209:	sndparam_descriptor 0x01e206, 24, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_210:	sndparam_descriptor 0x01e400, 25, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_211:	sndparam_descriptor 0x01e401, 25, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_212:	sndparam_descriptor 0x01e402, 25, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_213:	sndparam_descriptor 0x01e403, 25, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_214:	sndparam_descriptor 0x01e404, 25, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
SeqMixParam_Entry_215:	sndparam_descriptor 0x01e600, 25, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_216:	sndparam_descriptor 0x01e601, 25, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_217:	sndparam_descriptor 0x01e602, 25, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_218:	sndparam_descriptor 0x01e603, 25, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_219:	sndparam_descriptor 0x01e604, 25, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_220:	sndparam_descriptor 0x01e605, 25, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_221:	sndparam_descriptor 0x01e606, 25, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_222:	sndparam_descriptor 0x028000, 72, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_223:	sndparam_descriptor 0x028001, 72, 1, 0x7f, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_224:	sndparam_descriptor 0x028002, 72, 7, 0x30, 0, 3, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_225:	sndparam_descriptor 0x028080, 72, 3, 0x07, 0, 3, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_226:	sndparam_descriptor 0x028081, 72, 3, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_227:	sndparam_descriptor 0x028082, 144, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
SeqMixParam_Entry_228:	sndparam_descriptor 0x028083, 144, 3, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
