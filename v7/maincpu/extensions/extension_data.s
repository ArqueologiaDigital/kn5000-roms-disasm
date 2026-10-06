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
; !! THIS IS THE v7 COPY.  This file spans 0xED0008-0xEE0010 in the v7 dump too,
; with the same layout as v10: every v7/v10 difference in the range is a VALUE
; inside a line of the same size -- code pointers into the 0xFA-0xFC code that
; moved between versions, plus a few table values.  The text is v10's with
; those lines rewritten from the v7 dump (pointers resolved to the v7 symbol at
; the v7 address), and with each C-compiled record written as one
; `sndparam_descriptor` macro line (defined above the first run below), because
; the Makefile compiles the C for v10 only.  The records' field values were
; decoded from the v7 dump.  Produced by
; scripts/tools/port_extension_data_from_v10.py.
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
; MainChordPre_RootNames), then the CHORD-TYPE name -- RAM byte 0x8D42, `sla
; wa, 2`, `lda xbc, (0xecff6a:24)`, `ld r, (xrr+rr)` -- then "on" or "  "
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
SeqChanContainer_ChordTypeRef_A:
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
SeqChanContainer_ChordTypeRef_B:
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
; ---------------------------------------------------------------------------
; LANGUAGE-INDEXED STRING TABLES (seven, 0xED04C4-0xED0D17 and 0xED1932)
; ---------------------------------------------------------------------------
; Each LngTable_* is six string pointers indexed by display language --
; 0 EN, 1 DE, 2 FR, 3 ES, 4 IT, 5 ID -- followed by the six strings in
; REVERSE order.  Each is returned, as the answer to event 0x1E0009F, by one
; of the *LngCheck functions of Toshi_ApFunction_Table (`cp xbc, 0x1e0009f` /
; `lda xhl, (<table>:24)` / `ret`, ui/ui_mode_handlers.s and, for
; WallSureLngCheck, display/graphics_text_vga.s), which reach them through
; positional names such as LngTable_InitSettingWarn.  Four tables are
; translated except for Italian, whose entry is the literal "Italian"; the
; three description tables (FactoryResetDesc, StoreSoundBalance,
; StoreTotalSetting) have only EN and DE, the FR/ES/IT/ID slots pointing at
; English copies -- the Str_*_EN0..EN3 labels (kept: positional names are
; built on them) sit on those copies.  Layout checked by
; scripts/analysis/ext_lane_checks.py lng.
; ---------------------------------------------------------------------------
NoteStr3_Blank_3:
	aligned_string "  "
LngTable_Attention:	; returned by AttnLngCheck
	.long Str_Attention_EN	; EN
	.long Str_Attention_DE	; DE
	.long Str_Attention_FR	; FR
	.long Str_Attention_ES	; ES
	.long Str_Attention_IT	; IT
	.long Str_Attention_ID	; ID
Str_Attention_ID:
	aligned_string "PERHATIAN!"
Str_Attention_IT:
	aligned_string "Italian"
Str_Attention_ES:
	aligned_string "ATTENCI0N!"
Str_Attention_FR:
	aligned_string "ATTENTION!"
Str_Attention_DE:
	aligned_string "ACHTUNG!"
Str_Attention_EN:
	aligned_string "ATTENTION!"
LngTable_InitSettingWarn:	; returned by SysSureLngCheck
	.long Str_InitSettingWarn_EN	; EN
	.long Str_InitSettingWarn_DE	; DE
	.long Str_InitSettingWarn_FR	; FR
	.long Str_InitSettingWarn_ES	; ES
	.long Str_InitSettingWarn_IT	; IT
	.long Str_InitSettingWarn_ID	; ID
Str_InitSettingWarn_ID:
	aligned_string "Menggunakan Initial Setting akan menghapus semua data yang telah diset dengan susunan data asli dari pabrik."
Str_InitSettingWarn_IT:
	aligned_string "Italian"
Str_InitSettingWarn_ES:	aligned_string "El uso del ajuste inicial hará que se reemplacen los datos actuales por los ajustes originales de fá brica!"
Str_InitSettingWarn_FR:	aligned_string "La procédure d'initialisation va remplacer tous les réglages effectués par les présélections d'usine"
Str_InitSettingWarn_DE:	aligned_string "Durch das Initialisieren werden alle aktuellen Einstellungen wieder in den Werkszustand zurückversetzt."
Str_InitSettingWarn_EN:	aligned_string "Using Initial Setting will replace any current data with the original factory settings!"
LngTable_AreYouSure:	; returned by SureLngCheck
	.long Str_AreYouSure_EN	; EN
	.long Str_AreYouSure_DE	; DE
	.long Str_AreYouSure_FR	; FR
	.long Str_AreYouSure_ES	; ES
	.long Str_AreYouSure_IT	; IT
	.long Str_AreYouSure_ID	; ID
Str_AreYouSure_ID:
	aligned_string "Apakah Anda sudah yakin ?"
Str_AreYouSure_IT:
	aligned_string "Italian"
Str_AreYouSure_ES:	aligned_string "¿Está seguro?"
Str_AreYouSure_FR:	aligned_string "Etes vous sûr?"
Str_AreYouSure_DE:	aligned_string "SIND SIE SICHER?"
Str_AreYouSure_EN:	aligned_string "Are You Sure?"
LngTable_FactoryResetDesc:	; returned by CtlIniLngCheck
	.long Str_FactoryResetDesc_EN	; EN
	.long Str_FactoryResetDesc_DE	; DE
	.long Str_FactoryResetDesc_EN3	; FR
	.long Str_FactoryResetDesc_EN2	; ES
	.long Str_FactoryResetDesc_EN1	; IT
	.long Str_FactoryResetDesc_EN0	; ID
Str_FactoryResetDesc_EN0:
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN1:
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN2:
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_EN3:
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
Str_FactoryResetDesc_DE:	aligned_string "Setzt die PERFORMANCE Daten, d.h. die von Ihnen erstellten Daten und Einstellungen, auf die Werkseinstellung zurück."
Str_FactoryResetDesc_EN:	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
LngTable_StoreSoundBalance:	; returned by PmemNormLngCheck
	.long Str_StoreSoundBalance_EN	; EN
	.long Str_StoreSoundBalance_DE	; DE
	.long Str_StoreSoundBalance_EN3	; FR
	.long Str_StoreSoundBalance_EN2	; ES
	.long Str_StoreSoundBalance_EN1	; IT
	.long Str_StoreSoundBalance_EN0	; ID
Str_StoreSoundBalance_EN0:
	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN1:
	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN2:
	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_EN3:
	aligned_string "Stores sound & balance settings only."
Str_StoreSoundBalance_DE:
	aligned_string "Speichert nur Klang- und Lautstärkeeinstellungen."
Str_StoreSoundBalance_EN:	aligned_string "Stores sound & balance settings only."
LngTable_StoreTotalSetting:	; returned by PmemExpLngCheck
	.long Str_StoreTotalSetting_EN	; EN
	.long Str_StoreTotalSetting_DE	; DE
	.long Str_StoreTotalSetting_EN3	; FR
	.long Str_StoreTotalSetting_EN2	; ES
	.long Str_StoreTotalSetting_EN1	; IT
	.long Str_StoreTotalSetting_EN0	; ID
Str_StoreTotalSetting_EN0:
	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN1:
	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN2:
	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_EN3:
	aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
Str_StoreTotalSetting_DE:
	aligned_string "Speichert die gesamte Einstellung einschließlich Rhythmus, Transpose & Tempo."
Str_StoreTotalSetting_EN:				aligned_string "Stores to total setting including Rhythm, Transpose & tempo."
MasterSetup_GetNameB_DrawString_Str_Fmtc_Fmtd_Fmtd:	aligned_string "%c:%d/%d  "
; ---------------------------------------------------------------------------
; Event-offset tables and screen strings of the Toshi grid/box procedures
; ---------------------------------------------------------------------------
; Eleven procedures in ui/ui_mode_handlers.s dispatch the seven events
; 0x1C00017-0x1C0001D the same way: `sub x, 0x1c00017`, bounds 0..6, `add
; x, x`, add a table address, `ld wa/bc, (table)`, `lda xix, (<base>:24)`,
; `jp t, (xrr+rr)` -- so each *_EventOffsets table is SEVEN u16 offsets FROM ITS
; BASE LABEL (0 = the base itself).  The procedure names are the originals
; from Toshi_Function_Table / Toshi_ApFunctionName_Table.  The code still
; reaches these tables through positional names Str_StoreTotalSetting_DE_0xNN
; (shared/positional_labels.s), given with each; the targets carry no labels
; in ui_mode_handlers.s, which is why the offsets stay numeric here -- and
; why they differ in v7, whose handlers moved.
; The strings between them are loaded by the same procedures as immediates
; (`ld xwa, Str_StoreTotalSetting_DE_0xNN` then Strcpy): "     " (0x15A),
; "TEMPO" (0x164, 0x16E) by the MstStyle2 name drawers, the 32-space
; blanks (0x188, 0x1AC, 0x1D0, 0x1F4, 0x216) by MstGrid2_OutOfRange_*, and
; "ON "/"OFF" (0x258/0x25C, 0x270/0x26C) by TchSensGrid.
; ---------------------------------------------------------------------------
AcMstStyleAlpGridBoxProc_EventOffsets:	; read by AcMstStyleAlpGridBoxProc via MasterSetup_EventDispatch (AcMstStyleAlpGridBoxProc_EventOffsets)
	.short	AcMstStyleAlp_Boundary_OnIndexswUp - AcMstStyleAlp_Boundary_Skip
	.short	AcMstStyleAlp_Boundary_OnIndexswDown - AcMstStyleAlp_Boundary_Skip
	.short	AcMstStyleAlp_Boundary_OnIndexswUp - AcMstStyleAlp_Boundary_Skip
	.short	AcMstStyleAlp_Boundary_OnIndexswDown - AcMstStyleAlp_Boundary_Skip
	.short	MasterSetup_InheritedProc_Fallback - AcMstStyleAlp_Boundary_Skip
	.short	AcMstStyleAlpGridBoxProc_OnLswData - AcMstStyleAlp_Boundary_Skip
	.short	AcMstStyleAlpGridBoxProc_OnLswData - AcMstStyleAlp_Boundary_Skip
MstStyleAlp_AppendPadChar_Data:
	aligned_string " "
MstStyleAlp_OverflowStr_Str_Blank32:	aligned_string "                                "
MstStyleAlp_AppendPadChar2_Str_Blank1:	aligned_string " "
MstStyleAlpGridCheck_EventOffsets:	; read by MstStyleAlpGridCheck via MstStyleAlp_EventDispatch (MstStyleAlpGridCheck_EventOffsets)
	.short	MstStyleAlp_EventDispatch - MstStyleAlp_EventDispatch
	.short	MstStyleAlp_EventDispatch - MstStyleAlp_EventDispatch
	.short	MstStyleAlp_EventDispatch - MstStyleAlp_EventDispatch
	.short	MstStyleAlp_EventDispatch - MstStyleAlp_EventDispatch
	.short	EffectMode_SendEvent_Return - MstStyleAlp_EventDispatch
	.short	EffectMode_SendEvent_Return - MstStyleAlp_EventDispatch
	.short	EffectMode_SendEvent_Return - MstStyleAlp_EventDispatch
AcMstStyle1GridBoxProc_EventOffsets:	; read by AcMstStyle1GridBoxProc via MstStyle_EventDispatch (AcMstStyle1GridBoxProc_EventOffsets)
	.short	AcMstStyle1GridBoxProc_OnIndexswUp - MstStyle_EventDispatch
	.short	AcMstStyle1GridBoxProc_OnIndexswDown - MstStyle_EventDispatch
	.short	AcMstStyle1GridBoxProc_OnIndexswUp - MstStyle_EventDispatch
	.short	AcMstStyle1GridBoxProc_OnIndexswDown - MstStyle_EventDispatch
	.short	MstStyle_InheritedProc_Fallback - MstStyle_EventDispatch
	.short	MstStyle_ForwardToChild - MstStyle_EventDispatch
	.short	MstStyle_ForwardToChild - MstStyle_EventDispatch
MstStyle1Grid_CellSelect_Data_2:
	aligned_string " "
MstStyle1Grid_OutOfRange_Str_Blank16:	aligned_string "                "
MstStyle1Grid_PadLeft_LoopB_Str_Blank1:	aligned_string " "
MstStyle1GridCheck_EventOffsets:	; read by MstStyle1GridCheck via MstStyle1Grid_EventDispatch (MstStyle1GridCheck_EventOffsets)
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_Epilogue - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
	.short	MstStyle1Grid_EventDispatch - MstStyle1Grid_EventDispatch
MstStyle1Sub_GetNameB_DrawString_Str_Fmtd_Fmtd:	aligned_string "%d/%d"
AcMstStyle1SubGridBoxProc_EventOffsets:	; read by AcMstStyle1SubGridBoxProc via MstStyle1_EventDispatch (AcMstStyle1SubGridBoxProc_EventOffsets)
	.short	AcMstStyle1SubGridBoxProc_OnIndexswUp - MstStyle1_EventDispatch
	.short	AcMstStyle1SubGridBoxProc_OnIndexswDown - MstStyle1_EventDispatch
	.short	AcMstStyle1SubGridBoxProc_OnIndexswUp - MstStyle1_EventDispatch
	.short	AcMstStyle1SubGridBoxProc_OnIndexswDown - MstStyle1_EventDispatch
	.short	MstStyle1Sub_InheritedFallback - MstStyle1_EventDispatch
	.short	MstStyle1Sub_ForwardToChild - MstStyle1_EventDispatch
	.short	MstStyle1Sub_ForwardToChild - MstStyle1_EventDispatch
	aligned_string " "
MstStyle1SubGrid_OutOfRange_Str_Blank16:	aligned_string "                "
MstStyle1SubGrid_PadLeft_LoopB_Str_Blank1:
	aligned_string " "
MstStyle1SubGridCheck_EventOffsets:	; read by MstStyle1SubGridCheck via MstStyle1Sub_EventDispatch (MstStyle1SubGridCheck_EventOffsets)
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
	.short	MstStyle1SubGrid_Epilogue - MstStyle1Sub_EventDispatch
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
	.short	MstStyle1Sub_EventDispatch - MstStyle1Sub_EventDispatch
MstStyle2_GetNameB_DrawString_Str_Fmts:		aligned_string "%s:"
MstStyle2_GetNameB_DrawString_Str_Blank17:	aligned_string "                 "
MstStyle2_GetNameB_DrawString_Str_Blank5:
	aligned_string "     "
MstStyle2_NameB_DrawCurrent_Str_Fmts:	aligned_string "%s:"
MstStyle2_NameB_DrawCurrent_Str_TEMPO:
	aligned_string "TEMPO"
MstStyle2_NameB_DrawLower_Str_Fmts:	aligned_string "%s:"
MstStyle2_NameB_DrawLower_Str_TEMPO:
	aligned_string "TEMPO"
MstStyle2_NameB_Render_Str_Fmts:	aligned_string "%s"
AcMstStyle2GridBoxProc_EventOffsets:	; read by AcMstStyle2GridBoxProc via MstStyle1Page_EventDispatch (AcMstStyle2GridBoxProc_EventOffsets)
	.short	AcMstStyle2GridBoxProc_OnIndexswUp - MstStyle1Page_EventDispatch
	.short	AcMstStyle2GridBoxProc_OnIndexswDown - MstStyle1Page_EventDispatch
	.short	AcMstStyle2GridBoxProc_OnIndexswUp - MstStyle1Page_EventDispatch
	.short	AcMstStyle2GridBoxProc_OnIndexswDown - MstStyle1Page_EventDispatch
	.short	MstStyle2_InheritedFallback - MstStyle1Page_EventDispatch
	.short	MstStyle2_ForwardToChild - MstStyle1Page_EventDispatch
	.short	MstStyle2_ForwardToChild - MstStyle1Page_EventDispatch
MstGrid2_PadLeft_LoopA_Data:
	aligned_string " "
MstGrid2_OutOfRange_LowCol_Str_Blank32:
	aligned_string "                                "
MstGrid2_PadLeft_LoopB_Str_Blank1:	aligned_string " "
MstGrid2_OutOfRange_HighCol_Str_Blank32:
	aligned_string "                                "
MstGrid2_PadLeft_LoopC_Str_Blank1:	aligned_string " "
MstGrid2_OutOfRange_LowCol2_Str_Blank32:
	aligned_string "                                "
MstGrid2_PadLeft_LoopD_Str_Blank1:	aligned_string " "
MstGrid2_OutOfRange_HighCol2_Str_Blank32:
	aligned_string "                                "
MstGrid2_OutOfRange_BeyondMax_Str_Blank32:
	aligned_string "                                "
MstStyle2GridCheck_EventOffsets:	; read by MstStyle2GridCheck via MstGrid2_ScrollJumpTable (MstStyle2GridCheck_EventOffsets)
	.short	MstGrid2_ScrollJumpTable - MstGrid2_ScrollJumpTable
	.short	MstGrid2_ScrollJumpTable - MstGrid2_ScrollJumpTable
	.short	MstGrid2_ScrollJumpTable - MstGrid2_ScrollJumpTable
	.short	MstGrid2_ScrollJumpTable - MstGrid2_ScrollJumpTable
	.short	MstGrid2_Return - MstGrid2_ScrollJumpTable
	.short	MstGrid2_Return - MstGrid2_ScrollJumpTable
	.short	MstGrid2_Return - MstGrid2_ScrollJumpTable
AcTchSensGridBoxProc_EventOffsets:	; read by AcTchSensGridBoxProc via MstStyle2_EventDispatch (AcTchSensGridBoxProc_EventOffsets)
	.short	AcTchSensGridBoxProc_OnIndexswUp - MstStyle2_EventDispatch
	.short	AcTchSensGridBoxProc_OnIndexswDown - MstStyle2_EventDispatch
	.short	AcTchSensGridBoxProc_OnIndexswUp - MstStyle2_EventDispatch
	.short	AcTchSensGridBoxProc_OnIndexswDown - MstStyle2_EventDispatch
	.short	TchSens_InheritedFallback - MstStyle2_EventDispatch
	.short	AcTchSensGridBoxProc_OnLswData - MstStyle2_EventDispatch
	.short	AcTchSensGridBoxProc_OnLswData - MstStyle2_EventDispatch
TchSensGridCheck_OnLswData_Data:
	aligned_string "%3d"
TchSensGridCheck_OnLswData_Str_ON:
	aligned_string "ON "
TchSensGridCheck_OnLswData_Str_OFF:
	aligned_string "OFF"
TchSensGridCheck_OnLswData_Str_Fmt3d:		aligned_string "%3d"
TchSensGridCheck_OnLswData_Str_Fmt3d_2:	aligned_string "%3d"
TchSensGrid_CellSelect_Str_Fmt3d:		aligned_string "%3d"
TchSensGrid_CheckCell_1_4_Str_OFF:
	aligned_string "OFF"
TchSensGrid_CheckCell_1_4_Str_ON:
	aligned_string "ON "
TchSensGrid_CheckCell_1_5_Str_Fmt3d:	aligned_string "%3d"
TchSensGrid_CheckCell_1_6_Str_Fmt3d:	aligned_string "%3d"
TchSensGridCheck_EventOffsets:	; read by TchSensGridCheck via TchSensGrid_EventDispatch (TchSensGridCheck_EventOffsets)
	.short	TchSensGrid_EventDispatch - TchSensGrid_EventDispatch
	.short	TchSensGridCheck_OnIndexswDown - TchSensGrid_EventDispatch
	.short	TchSensGrid_EventDispatch - TchSensGrid_EventDispatch
	.short	TchSensGridCheck_OnIndexswDown - TchSensGrid_EventDispatch
	.short	TchSensGrid_ReturnZero - TchSensGrid_EventDispatch
	.short	TchSensGridCheck_OnLswData - TchSensGrid_EventDispatch
	.short	TchSensGridCheck_OnLswData - TchSensGrid_EventDispatch
AcFSWAssGridBoxProc_EventOffsets:	; read by AcFSWAssGridBoxProc via TchSens_EventDispatch (AcFSWAssGridBoxProc_EventOffsets)
	.short	AcFSWAssGridBoxProc_OnIndexswUp - TchSens_EventDispatch
	.short	AcFSWAssGridBoxProc_OnIndexswDown - TchSens_EventDispatch
	.short	AcFSWAssGridBoxProc_OnIndexswUp - TchSens_EventDispatch
	.short	AcFSWAssGridBoxProc_OnIndexswDown - TchSens_EventDispatch
	.short	FSWAss_InheritedFallback - TchSens_EventDispatch
	.short	AcFSWAssGridBoxProc_OnLswData - TchSens_EventDispatch
	.short	AcFSWAssGridBoxProc_OnLswData - TchSens_EventDispatch
; FswAssign_FunctionCodes / FswAssign_FunctionNames: the foot-switch
; assignable functions.  FSWAssGrid_EventDispatch (ui/ui_mode_handlers.s)
; indexes the codes with `ld c, (xbc+hl)` (FswAssign_FunctionCodes)
; and, after AudioTable_FindMatchIndex, the names with `sla hl, 2` /
; `ld xwa, (xbc+hl)` (FswAssign_FunctionNames).  31 codes -- 0x00
; is OFF, then 0x90.. in the order of the names -- and a 0xFF terminator;
; 31 name pointers, entry k naming code k.
FswAssign_FunctionCodes:
	.byte 0x00, 0x90, 0x91, 0xb3, 0xb4, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xb2, 0x88, 0x92
	.byte 0x93, 0x94, 0x95, 0x40, 0x96, 0x99, 0x97, 0x98, 0xad, 0xb0, 0xb1, 0xb8, 0xb9, 0xb6, 0xb7, 0xff
FswAssign_FunctionNames:
	.long CtrlAssignStr_Off
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
FSWAssGridCheck_OnLswData_Str_Fmts:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts_2:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts_3:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts_4:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts_5:	aligned_string "%s"
FSWAssGrid_EventDispatch_Entry_Str_Fmts_6:	aligned_string "%s"
FSWAssGrid_CellSelect_Str_Fmts:		aligned_string "%s"
FSWAssGrid_CheckCell_1_3_Str_Fmts:	aligned_string "%s"
FSWAssGrid_CheckCell_1_4_Str_Fmts:	aligned_string "%s"
FSWAssGrid_CheckCell_1_5_Str_Fmts:	aligned_string "%s"
FSWAssGrid_CheckCell_1_6_Str_Fmts:	aligned_string "%s"
FSWAssGrid_CheckCell_1_7_Str_Fmts:	aligned_string "%s"
FSWAssGrid_CheckCell_1_8_Str_Fmts:	aligned_string "%s"
FSWAssGridCheck_EventOffsets:	; read by FSWAssGridCheck via FSWAssGrid_EventDispatch (FSWAssGridCheck_EventOffsets)
	.short	FSWAssGrid_EventDispatch - FSWAssGrid_EventDispatch
	.short	FSWAssGridCheck_OnIndexswDown - FSWAssGrid_EventDispatch
	.short	FSWAssGrid_EventDispatch - FSWAssGrid_EventDispatch
	.short	FSWAssGridCheck_OnIndexswDown - FSWAssGrid_EventDispatch
	.short	AudioTable_ReturnZero - FSWAssGrid_EventDispatch
	.short	FSWAssGridCheck_OnLswData - FSWAssGrid_EventDispatch
	.short	FSWAssGridCheck_OnLswData - FSWAssGrid_EventDispatch
FswAsIniFunc_EventOffsets:	; read by FswAsIniFunc via FswAsIni_EventDispatch (FswAsIniFunc_EventOffsets), six entries
	.short	SeqLoadFunc_ReturnZero - FswAsIni_EventDispatch
	.short	FswAsIni_EventDispatch - FswAsIni_EventDispatch
	.short	SeqLoadFunc_ReturnZero - FswAsIni_EventDispatch
	.short	SeqLoadFunc_ReturnZero - FswAsIni_EventDispatch
	.short	SeqLoadFunc_ReturnZero - FswAsIni_EventDispatch
	.short	SeqLoadFunc_ReturnZero - FswAsIni_EventDispatch
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
PmExpFilter_Repaint_Str_FILTER_TYPE:
	aligned_string "FILTER TYPE"
PmExpFilter_Repaint_Str_ON_OFF:
	.byte	0x4f, 0x4e, 0x2f, 0x4f, 0x46, 0x46, 0x00, 0xff
PmExpFilter_DrawCellBank1_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
PmExpFilter_DrawCellBank1_Str_PAGE_2_3:	aligned_string "PAGE 2/3"
PmExpFilter_DrawCellBank2_Str_Fmts:	.byte 0x25, 0x73, 0x00, 0xff
PmExpFilter_DrawCellBank2_Data:
	aligned_string "PAGE 3/3"
AcPmExpFilterGridBoxProc_EventOffsets:	; read by AcPmExpFilterGridBoxProc via PmemPageCtl_EventDispatch (AcPmExpFilterGridBoxProc_EventOffsets)
	.short	AcPmExpFilterGridBoxProc_OnIndexswUp - PmemPageCtl_EventDispatch
	.short	AcPmExpFilterGridBoxProc_OnIndexswDown - PmemPageCtl_EventDispatch
	.short	AcPmExpFilterGridBoxProc_OnIndexswUp - PmemPageCtl_EventDispatch
	.short	AcPmExpFilterGridBoxProc_OnIndexswDown - PmemPageCtl_EventDispatch
	.short	PmExpFilter_DefaultInherited - PmemPageCtl_EventDispatch
	.short	AcPmExpFilterGridBoxProc_OnLswData - PmemPageCtl_EventDispatch
	.short	AcPmExpFilterGridBoxProc_OnLswData - PmemPageCtl_EventDispatch
; PmExpFilter_CellKeys / PmExpFilter_AltKeys: two lists of nine u32 sound-
; parameter KEYS -- all 18 are the +0x00 key of an 18-byte descriptor in this
; file -- that PmExpFilterGridCheck picks with `ld xwa, (xbc+wa)` (cell
; index 2..10) through PmExpFilter_CellKeys / PmExpFilter_AltKeys.
PmExpFilter_CellKeys:
	.long 0x00002900, 0x00002901, 0x00002904
	.long 0x00002902, 0x00002903, 0x0000290a
	.long 0x0000290b, 0x0000290c, 0x0000290d
PmExpFilter_AltKeys:
	.long 0x0000290e, 0x00002905, 0x00002907
	.long 0x00002908, 0x0000290f, 0x00002910
	.long 0x00002909, 0x00002906, 0x00002911
	; ON/OFF cell texts: PmExpFilter_EventDispatch (PmExpFilterGridCheck_OnLswData_Str_OFF..0xA6),
	; PmExpFilterCheck_CellDecode (_0xAA, _0xAE), PmExpFilterCheck_AltDecode (_0xB2, _0xB6)
PmExpFilterGridCheck_OnLswData_Str_OFF:
	aligned_string "OFF"
PmExpFilterGridCheck_OnLswData_Str_ON:
	aligned_string "ON "
PmExpFilterGridCheck_OnLswData_Str_OFF_2:
	aligned_string "OFF"
PmExpFilterGridCheck_OnLswData_Str_ON_2:
	aligned_string "ON "
PmExpFilterCheck_CellDecode_Str_ON:
	aligned_string "ON "
PmExpFilterCheck_CellDecode_Str_OFF:
	aligned_string "OFF"
PmExpFilterCheck_AltDecode_Str_ON:
	aligned_string "ON "
PmExpFilterCheck_AltDecode_Str_OFF:
	aligned_string "OFF"
PmExpFilterCheck_PushDefault_Str_Blank3:	aligned_string "   "
PmExpFilterGridCheck_EventOffsets:	; read by PmExpFilterGridCheck via PmExpFilter_EventDispatch (PmExpFilterGridCheck_EventOffsets)
	.short	PmExpFilter_EventDispatch - PmExpFilter_EventDispatch
	.short	PmExpFilterGridCheck_OnIndexswDown - PmExpFilter_EventDispatch
	.short	PmExpFilter_EventDispatch - PmExpFilter_EventDispatch
	.short	PmExpFilterGridCheck_OnIndexswDown - PmExpFilter_EventDispatch
	.short	SeqLoad_StoreReturnZero - PmExpFilter_EventDispatch
	.short	PmExpFilterGridCheck_OnLswData - PmExpFilter_EventDispatch
	.short	PmExpFilterGridCheck_OnLswData - PmExpFilter_EventDispatch
AcDispTimeSetGridBoxProc_EventOffsets:	; read by AcDispTimeSetGridBoxProc via PmExpFilter2_EventDispatch (AcDispTimeSetGridBoxProc_EventOffsets)
	.short	AcDispTimeSetGridBoxProc_OnIndexswUp - PmExpFilter2_EventDispatch
	.short	AcDispTimeSetGridBoxProc_OnIndexswDown - PmExpFilter2_EventDispatch
	.short	AcDispTimeSetGridBoxProc_OnIndexswUp - PmExpFilter2_EventDispatch
	.short	AcDispTimeSetGridBoxProc_OnIndexswDown - PmExpFilter2_EventDispatch
	.short	DispTimeSet_DefaultInherited - PmExpFilter2_EventDispatch
	.short	AcDispTimeSetGridBoxProc_OnLswData - PmExpFilter2_EventDispatch
	.short	AcDispTimeSetGridBoxProc_OnLswData - PmExpFilter2_EventDispatch
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1437-0xED1452 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=8 near PmExpFilter_CellKeys+9
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1453-0xED146E (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=8 near PmExpFilter_AltKeys+1
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
DispTimeSetGridCheck_OnLswData_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_OnLswData_Str_Fmts_3:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_OnLswData_Str_Fmts_4:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_OnLswData_Str_Fmts_5:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_OnLswData_Str_Fmts_2:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_OnLswData_Str_Fmts_6:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_CellDecode_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_TryRow3_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_TryRow4_Str_Fmts:		.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_TryRow5_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_TryRow6_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetCheck_TryRow7_Str_Fmts:	.byte	0x25, 0x73, 0x00, 0xff
DispTimeSetGridCheck_EventOffsets:	; read by DispTimeSetGridCheck via DispTimeSet_EventDispatch (DispTimeSetGridCheck_EventOffsets)
	.short	DispTimeSet_EventDispatch - DispTimeSet_EventDispatch
	.short	DispTimeSetGridCheck_OnIndexswDown - DispTimeSet_EventDispatch
	.short	DispTimeSet_EventDispatch - DispTimeSet_EventDispatch
	.short	DispTimeSetGridCheck_OnIndexswDown - DispTimeSet_EventDispatch
	.short	DispTimeSet_ReturnZero - DispTimeSet_EventDispatch
	.short	DispTimeSetGridCheck_OnLswData - DispTimeSet_EventDispatch
	.short	DispTimeSetGridCheck_OnLswData - DispTimeSet_EventDispatch
IvPageOverWr_GetName_Data:
	aligned_string "PAGE"
MssName_EventDispatch_Str_Memory_data:	aligned_string "Memory data "
MssName_EventDispatch_Str_Blank2:
	.byte	0x20, 0x20, 0x00, 0xff
MssName_EventDispatch_Str_Blank2_2:	.byte	0x20, 0x20, 0x00, 0xff
MssNameFunc_CaseTable:
	.short	MssNameFunc_OnGetLargeStep - MssName_EventDispatch
	.short	MssNameFunc_OnGetLargeStep - MssName_EventDispatch
	.short	MssName_ReturnZero - MssName_EventDispatch
	.short	MssName_ReturnZero - MssName_EventDispatch
	.short	MssName_ReturnZero - MssName_EventDispatch
	.short	MssNameFunc_OnGetMax - MssName_EventDispatch
	.short	MssNameFunc_OnGetLargeStep - MssName_EventDispatch
	.short	MssNameFunc_OnGetRamAddress - MssName_EventDispatch
	.short	MssNameFunc_OnGetRamSize - MssName_EventDispatch
	.short	MssName_EventDispatch - MssName_EventDispatch
AcPmBkNoBox_Match_Str_Blank8:		aligned_string "        "
AcPmBkNoBox_FormatBankNo_Str_Fmtd_Fmtd:	aligned_string "%d-%d:"
AcBkNoBox_Match_Str_Fmtd:		.byte 0x25, 0x64, 0x3a, 0x00
PmemMode_Paint_Str_PAGE_1_3:
	aligned_string "PAGE 1/3"
AcPmBkEdit_BankChanged_Str_BANK_Fmt2d:
	aligned_string "BANK%2d:"
AcPmBkEdit_BankEdit_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
PmBkNameFunc_CaseTable:
	.short	PmBkNameFunc_OnGetLargeStep - PmBkName_EventDispatch
	.short	PmBkNameFunc_OnGetLargeStep - PmBkName_EventDispatch
	.short	PmBkName_ReturnZero - PmBkName_EventDispatch
	.short	PmBkName_ReturnZero - PmBkName_EventDispatch
	.short	PmBkName_ReturnZero - PmBkName_EventDispatch
	.short	PmBkNameFunc_OnGetMax - PmBkName_EventDispatch
	.short	PmBkName_ReturnZero - PmBkName_EventDispatch
	.short	PmBkName_DataBytes - PmBkName_EventDispatch
	.short	PmBkNameFunc_OnGetLargeStep - PmBkName_EventDispatch
	.short	PmBkName_EventDispatch - PmBkName_EventDispatch
GmOnOffFunc_Data:	.byte	0x00, 0xff
VariScreen_HandlePaint_Str_SOUND:	.byte	0x53, 0x4f, 0x55, 0x4e, 0x44, 0x00
VariScreen_DrawNameString_Str_Fmtd:		.byte	0x25, 0x64, 0x3a, 0x00
VariScreen_DrawRightNameString_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
VariScreen_HandleConfirm_Str_PAGE_Fmtd_Fmtd:	aligned_string "PAGE %d/%d"
VariScreen_ConfirmDrawNameAudio_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
VariScreen_EnumDrawNameAudio_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
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
RVari_Paint_Str_RHYTHM:
	aligned_string "RHYTHM"
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED164E-0xED1662 (20 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=5 near RVari_Paint_Str_RHYTHM+8
RVari_Select_CheckSameBank_Str_Fmts:		aligned_string "%s:"
RVari_Select_CheckSameBank_Str_Fmts_2:		aligned_string "%s:"
RVari_SelectE_SecondItem_Draw_Str_Fmtd:		aligned_string "%d:"
RVari_SelectO_SecondItem_Draw_Str_Fmtd:		aligned_string "%d:"
RVari_ConfirmF_Item_Draw_Str_Fmts:		aligned_string "%s:"
RVari_Confirm_TypeNotF_Str_PAGE_Fmtd_Fmtd:	aligned_string "PAGE %d/%d"
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED166E-0xED167E (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=5 near RVari_Paint_Str_RHYTHM+40
RVari_ConfirmE_Item_Draw_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
RVari_EnumNotifyF_Item_Draw_Str_Fmts:	.byte	0x25, 0x73, 0x3a, 0x00
RVari_EnumNotifyE_Item_Draw_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
PmBank_BankChanged_DrawSlot_Str_Fmtd:	.byte	0x25, 0x64, 0x3a, 0x00
; SelectRect_Table: six screen rectangles {x1, y1, x2, y2}, 8 bytes each,
; read with `sla wa, 3` / `lda xbc, (SelectRect_Table:24)` by PmBank_OnSelect
; and ToneGen_WriteParamByIndex (display/graphics_text_vga.s), which copy the
; four words.  Two of the y1/x2 pairs used to be written as pointers
; (`.long NakaInst_Param_EmptyStr` = {134, 238}, `.long
; NakaData_DescriptorPad_ZeroA` = {154, 230}); neither is one.
SelectRect_Table:
	.short 2, 62, 302, 93
	.short 2, 98, 316, 129
	.short 2, 134, 238, 153
	.short 2, 154, 230, 173
	.short 2, 174, 262, 193
	.short 2, 194, 278, 213
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
; ---------------------------------------------------------------------------
; SOUND-CHECK SCREEN TEXT (0xED1718-0xED18AD) and three WALLPAPER-EDIT blocks
; ---------------------------------------------------------------------------
; The code reaches these through positional names TransposeNoteStr_C_0xNN
; (shared/positional_labels.s); readers, all in display/graphics_text_vga.s:
;   +0x12 "CHECK BY SINE WAVE", +0x26 "Select the mode by sound button...",
;   +0x58 "CHECK MODE:", +0x64 "KEY DOWN INFORMATION ="  -- PmBank_OnPaint
;   +0x7C .. +0x16A the six "(n)..." check-mode lines and their key
;                   legends                               -- ToneGen_ParamWriteDispatch
;   +0x18E six words 0, 86, 174, 221, 267, 313            -- ToneGen_WriteParamByIndex
;   +0x19A, +0x1C6, +0x1F2: three blocks {"DEFAULT", " USER  ", " ERROR ",
;   ten words}, one per Toshi ApFunction WallHomeEditCheck (+0x1B2 words),
;   WallMenuEditCheck (+0x1DE) and WallOthEditCheck (+0x20A); their
;   *_EventDispatch / WallHomeEdit_LoadSndAddr3 helpers read the strings.
; The screen these draw is a factory sound check ("IC304&305", "GENERATOR
; LSI OUTSEL"); how it is entered is not traced here.
; ---------------------------------------------------------------------------
SoundCheck_Text:
	aligned_string "(%s%2d, %3d)"
PmBank_OnPaint_Str_CHECK_BY_SINE_WAVE:
	aligned_string "CHECK BY SINE WAVE"
PmBank_OnPaint_Str_Select_the_mode_by_sound_button:
	aligned_string "Select the mode by sound button of highest line."
PmBank_OnPaint_Str_CHECK_MODE:
	aligned_string "CHECK MODE:"
PmBank_OnPaint_Str_KEY_DOWN_INFORMATION:
	aligned_string "KEY DOWN INFORMATION ="
ToneGen_ParamWriteDispatch_Str_N1_SINE_WAVE_ROM_check_w_o_TOUCH:
	aligned_string "(1)SINE WAVE & ROM check(w/o TOUCH)"
ToneGen_ParamWriteDispatch_Str_C_key_IC304_305_C_7eB_key_IC306:
	aligned_string "C-key=IC304&305,C#~7eB-key=IC306&307"
ToneGen_ParamWriteDispatch_Str_N2_GENERATOR_LSI_OUTSEL_check:
	aligned_string "(2)GENERATOR LSI OUTSEL check"
ToneGen_ParamWriteDispatch_Str_C_key_DIRECT_REV_DSP_C_7eB_key:
	aligned_string "C-key=DIRECT+REV/DSP,C#~7eB-key=REV/DSP"
ToneGen_ParamWriteDispatch_Str_N3_HIGH_SOUND_check_2octave:
	aligned_string "(3)HIGH SOUND check(+2octave)"
ToneGen_ParamWriteDispatch_Str_N4_LOW_SOUND_check_2octave:
	aligned_string "(4)LOW SOUND check(-2octave)"
ToneGen_ParamWriteDispatch_Str_N5_NORMAL_SOUND_check_with_TOUCH:
	aligned_string "(5)NORMAL SOUND check with TOUCH"
ToneGen_ParamWriteDispatch_Str_N6_SINE_WAVE_ROM_check_16dB_DOWN:
	aligned_string "(6)SINE WAVE & ROM check 16dB DOWN"
ToneGen_WriteParamByIndex_CaseTable:
	.short	ToneGen_ParamWriteDispatch - ToneGen_ParamWriteDispatch
	.short	ToneGen_WriteParamByIndex_DrawOutselCheckItem - ToneGen_ParamWriteDispatch
	.short	ToneGen_WriteParamByIndex_DrawHighSoundCheckItem - ToneGen_ParamWriteDispatch
	.short	ToneGen_WriteParamByIndex_DrawLowSoundCheckItem - ToneGen_ParamWriteDispatch
	.short	ToneGen_WriteParamByIndex_DrawNormalSoundCheckItem - ToneGen_ParamWriteDispatch
	.short	ToneGen_WriteParamByIndex_DrawSineWaveMinus16dBItem - ToneGen_ParamWriteDispatch
WallHomeEdit_Text:
	aligned_string "DEFAULT"
WallHomeEdit_PushSndAddr_Str_USER:	aligned_string " USER  "
WallHomeEdit_LoadSndAddr3_Str_ERROR:
	aligned_string " ERROR "
WallHomeEditCheck_CaseTable:
	.short	WallHomeEditCheck_OnGetLargeStep - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_OnGetLargeStep - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_ReturnFalse - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_ReturnFalse - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_ReturnFalse - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_OnGetLargeStep - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_ReturnFalse - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_OnGetRamAddress - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_OnGetRamSize - WallHomeEdit_EventDispatch
	.short	WallHomeEditCheck_OnGetRamString - WallHomeEdit_EventDispatch
WallMenuEdit_Text:
	aligned_string "DEFAULT"
WallMenuEdit_EventDispatch_Str_USER:
	aligned_string " USER  "
WallMenuEdit_EventDispatch_Str_ERROR:
	aligned_string " ERROR "
WallMenuEditCheck_CaseTable:
	.short	WallMenuEditCheck_OnGetLargeStep - WallMenuEdit_EventDispatch
	.short	WallMenuEditCheck_OnGetLargeStep - WallMenuEdit_EventDispatch
	.short	WallOthEditCheck_RetZero - WallMenuEdit_EventDispatch
	.short	WallOthEditCheck_RetZero - WallMenuEdit_EventDispatch
	.short	WallOthEditCheck_RetZero - WallMenuEdit_EventDispatch
	.short	WallMenuEditCheck_OnGetLargeStep - WallMenuEdit_EventDispatch
	.short	WallOthEditCheck_RetZero - WallMenuEdit_EventDispatch
	.short	WallMenuEditCheck_OnGetRamAddress - WallMenuEdit_EventDispatch
	.short	WallMenuEditCheck_OnGetRamSize - WallMenuEdit_EventDispatch
	.short	WallMenuEdit_EventDispatch - WallMenuEdit_EventDispatch
WallOthEdit_Text:
	aligned_string "DEFAULT"
WallOthEdit_EventDispatch_Str_USER:
	aligned_string " USER  "
WallOthEdit_EventDispatch_Str_ERROR:
	aligned_string " ERROR "
WallOthEditCheck_CaseTable:
	.short	WallOthEditCheck_OnGetLargeStep - WallOthEdit_EventDispatch
	.short	WallOthEditCheck_OnGetLargeStep - WallOthEdit_EventDispatch
	.short	WallOthCheckLoop_RetZero - WallOthEdit_EventDispatch
	.short	WallOthCheckLoop_RetZero - WallOthEdit_EventDispatch
	.short	WallOthCheckLoop_RetZero - WallOthEdit_EventDispatch
	.short	WallOthEditCheck_OnGetLargeStep - WallOthEdit_EventDispatch
	.short	WallOthCheckLoop_RetZero - WallOthEdit_EventDispatch
	.short	WallOthEditCheck_OnGetRamAddress - WallOthEdit_EventDispatch
	.short	WallOthEditCheck_OnGetRamSize - WallOthEdit_EventDispatch
	.short	WallOthEdit_EventDispatch - WallOthEdit_EventDispatch
LngTable_UserInitialWallpaper:	; returned by WallSureLngCheck
	.long Str_UserInitialWallpaper_EN	; EN
	.long Str_UserInitialWallpaper_DE	; DE
	.long Str_UserInitialWallpaper_FR	; FR
	.long Str_UserInitialWallpaper_ES	; ES
	.long Str_UserInitialWallpaper_IT	; IT
	.long Str_UserInitialWallpaper_ID	; ID
Str_UserInitialWallpaper_ID:	aligned_string "USER INITIAL akan menggantikan penggunaan kertas tempel (stiker) yang sekarang dengan sticker/kertas tempel yg hitam-licin dan rata!"
Str_UserInitialWallpaper_IT:	aligned_string "Italian"
Str_UserInitialWallpaper_ES:	aligned_string "¡El USER INITIAL cambiará el patrÓn de fondo actual por un \"Plain Black\" (negro sin diseño)!"
Str_UserInitialWallpaper_FR:	aligned_string "USER INITIAL va remplacer votre fond de l'écran par un fond noir !"
Str_UserInitialWallpaper_DE:	aligned_string "USER INITIAL ersetzt das aktuelle Hintergrundbild durch eine schwarze Fläche !"
Str_UserInitialWallpaper_EN:	aligned_string "USER INITIAL will replace the current user wallpaper with the \"Plain Black\" wallpaper!"
MainSysControl_CaseTable:
	.short	MainSysCtrl_DispatchTable - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry6 - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry7 - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry8 - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry4_CopyBitmaps - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry1_AccDemo - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry2_PartInit - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry5_VoiceInit - MainSysCtrl_DispatchTable
	.short	MainSysCtrl_Entry3_Misc - MainSysCtrl_DispatchTable
CntIniFunc_CaseTable:
	.short	CntIniFunc_EventDispatch - CntIniFunc_EventDispatch
	.short	CntIniFunc_ReturnZero - CntIniFunc_EventDispatch
	.short	CntIniFunc_ReturnZero - CntIniFunc_EventDispatch
	.short	CntIniFunc_ReturnZero - CntIniFunc_EventDispatch
	.short	CntIniFunc_ReturnZero - CntIniFunc_EventDispatch
	.short	CntIniFunc_ReturnZero - CntIniFunc_EventDispatch


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
;     `sla hl, 2` then `lda_24 xbc, (AcFreeSplit_LookupNoteLabel_Data)` at 0xFC2DE2 and
;     0xFC2E67. Note number / 12, scaled by 4 = the pointer width.
; The five phantom `jp` operands (NakaData_PartConfig,
; Bitmap_SplitPoint_Gb_0x2B, Bitmap_Dredt0d_0xA8D, SepaOut_FormatData_Tail,
; FILETYPE_SIG_TABLE_2_0x15) were REFERENCES to labels defined elsewhere, not
; definitions here; nothing lost a name.
; -----------------------------------------------------------------------------
SplitNoteStr_C:	aligned_string "C "
	; 0xED1BAA = AcFreeSplit_LookupNoteLabel_Data: octave-digit pointers, index = note / 12
AcFreeSplit_LookupNoteLabel_Data:
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
OctaveDigitStr_0C:					.asciz "0"
OctaveDigitStr_0B:					.asciz "0"
AcFreeSplit_ValueChanged_Str_Blank10:			aligned_string "          "
AcFreeSplit_LookupNoteLabel_Str_SPLIT_Fmts_Fmts:	aligned_string "SPLIT<%s%s>"
AcFreeSplit_CheckSecondKey_Str_Blank10:			aligned_string "          "
AcFreeSplit_LookupSecondNote_Str_SPLIT_Fmts_Fmts:	aligned_string "SPLIT<%s%s>"
AcTranspose_FormatLabel_Data:
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
KeyScaleNoteStr_AFlat:			aligned_string "A~a0"
KeyScaleNoteStr_G:			.byte	0x47, 0x20, 0x00, 0xff
AcTranspose_ValueChanged_Str_Blank4:	.byte	0x20, 0x20, 0x20, 0x20, 0x00, 0xff
AcTranspose_FormatLabel_Str_Fmts:	aligned_string "<%s>"
AcChordBox_HandleChordUpdate_Str_Fmts:	aligned_string "%s"
ChordStr_On:				aligned_string "on"	; MainChordPre appends it when byte 0x8D44 != 0 and bit 1 of 0xCEDE is set
ChordStr_Blank:				aligned_string "  "
; ---------------------------------------------------------------------------
; Toshi_ApFunction_Table -- TOSHI object table: 42 "application function"
; code pointers + NULL (0xED1C9E-0xED1D49)
; ---------------------------------------------------------------------------
; Registered by InitializeToshi (extensions/extension_init.s, 0xFC311A):
;   RegObjTabl 0x1600002, ApFunctionProc, 42, Toshi_ApFunction_Table, 0x122
; which has RegisterObjectTable (ui/ui_widget_defs.s, 0xFA42FB) copy the
; 14-byte descriptor {class +0, proc +4, u16 count +8, table +10} into slot
; 0x122 of the object registry at RAM 0x27ED2 (14 bytes a slot).  An object
; id is (slot << 16) | element; CheckViewObject (0xFA3EB7) reads the table
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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED1D1B-0xED1D3A (31 B), unreached CODE-territory, was disassembled as 19 plausible-but-dead instruction lines; per=70% dist=12 near ChordStr_Blank+129
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
; ---------------------------------------------------------------------------
; TOSHI CLASS INSTANCE-VARIABLE NAME TABLES (28, 0xED20C6-0xED27E3)
; ---------------------------------------------------------------------------
; Field +0x14 of each Toshi_Class_Table record points at one of these: the
; names of the class's instance variables, ""-terminated, the strings
; following each table in reverse order.  The first entry of every table is
; commented with its class and variable count (checked against the class's
; type-signature string by scripts/analysis/ext_lane_checks.py class).
; !! The older labels on the tables are cited by ui_widgets/naka_master_style.c
; and so are kept, but most name the WRONG class -- NakaParam_VariScreen is
; NormScreen's table, NakaParam_RVariScreen is VariScreen's; the comment on
; each first entry is authoritative.  New labels ClassVar_<class>_<var> name
; the strings that had none.
; ---------------------------------------------------------------------------
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED239D-0xED23AE (17 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near NakaParam_AcMstStyleAlpGridBox+7
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED2663-0xED267C (25 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=71% dist=9 near NakaParam_AcMstSong2GridBox+5
NakaParam_VariScreen:
	.long NakaParam_VariScreen_Empty	; NormScreen: 0 variables
NakaParam_VariScreen_Empty:
	aligned_string ""
NakaParam_RVariScreen:
	.long ClassVar_VariScreen_func	; VariScreen: 9 variables
	.long ClassVar_VariScreen_font
	.long ClassVar_VariScreen_fontcolor
	.long ClassVar_VariScreen_page
	.long ClassVar_VariScreen_part
	.long ClassVar_VariScreen_varisu
	.long ParamStr08_nowswno
	.long ParamStr08_nowvari
	.long ParamStr08_oldvari
	.long ParamStr08_Empty
ParamStr08_Empty:
	aligned_string ""
ParamStr08_oldvari:
	aligned_string "oldvari"
ParamStr08_nowvari:
	aligned_string "nowvari"
ParamStr08_nowswno:
	aligned_string "nowswno"
ClassVar_VariScreen_varisu:	aligned_string "varisu"
ClassVar_VariScreen_part:	aligned_string "part"
ClassVar_VariScreen_page:	aligned_string "page"
ClassVar_VariScreen_fontcolor:	aligned_string "fontcolor"
ClassVar_VariScreen_font:	aligned_string "font"
ClassVar_VariScreen_func:	aligned_string "func"
ParamStr_Table_09:
	.long ParamStr09_func	; RVariScreen: 9 variables
	.long ParamStr09_font
	.long ParamStr09_fontcolor
	.long ParamStr09_page
	.long ParamStr09_part
	.long ParamStr09_varisu
	.long ParamStr09_nowswno
	.long ParamStr09_nowvari
	.long ParamStr09_oldvari
	.long ParamStr09_Empty
ParamStr09_Empty:
	aligned_string ""
ParamStr09_oldvari:
	aligned_string "oldvari"
ParamStr09_nowvari:
	aligned_string "nowvari"
ParamStr09_nowswno:
	aligned_string "nowswno"
ParamStr09_varisu:
	aligned_string "varisu"
ParamStr09_part:
	aligned_string "part"
ParamStr09_page:
	aligned_string "page"
ParamStr09_fontcolor:
	aligned_string "fontcolor"
ParamStr09_font:
	aligned_string "font"
ParamStr09_func:
	aligned_string "func"
NakaParam_AcChordBox:
	.long NakaParam_AcChordBox_Empty	; TransposeBox: 0 variables
NakaParam_AcChordBox_Empty:
	aligned_string ""
NakaParam_AcFreeSplitBox:
	.long NakaParam_AcFreeSplitBox_Empty	; ChordBox: 0 variables
NakaParam_AcFreeSplitBox_Empty:
	aligned_string ""
NakaParam_AcBkNoBox:
	.long NakaParam_AcBkNoBox_Empty	; FreeSplitBox: 0 variables
NakaParam_AcBkNoBox_Empty:
	aligned_string ""
NakaParam_AcPmBkNoBox:
	.long NakaParam_AcPmBkNoBox_Empty	; BkNoBox: 0 variables
NakaParam_AcPmBkNoBox_Empty:
	aligned_string ""
NakaParam_PmBankScreen:
	.long NakaParam_PmBankScreen_Empty	; PmBkNoBox: 0 variables
NakaParam_PmBankScreen_Empty:
	aligned_string ""
ParamStr_Table_10:
	.long ParamStr10_func	; PmBankScreen: 6 variables
	.long ParamStr10_font
	.long ParamStr10_fontcolor
	.long ParamStr10_page
	.long ParamStr10_nowbank
	.long ParamStr10_oldbank
	.long ParamStr10_Empty
ParamStr10_Empty:
	aligned_string ""
ParamStr10_oldbank:
	aligned_string "oldbank"
ParamStr10_nowbank:
	aligned_string "nowbank"
ParamStr10_page:
	aligned_string "page"
ParamStr10_fontcolor:
	aligned_string "fontcolor"
ParamStr10_font:
	aligned_string "font"
ParamStr10_func:
	aligned_string "func"
ParamStr_Table_11:
	.long ParamStr11_func	; AcPmBkEditBox: 2 variables
	.long ParamStr11_data
	.long ParamStr11_Empty
ParamStr11_Empty:
	aligned_string ""
ParamStr11_data:
	aligned_string "data"
ParamStr11_func:
	aligned_string "func"
ParamStr_Table_12:
	.long ParamStr12_func	; MsaModeScreen: 5 variables
	.long ParamStr12_font
	.long ParamStr12_fontcolor
	.long ParamStr12_newmsamode
	.long ParamStr12_oldmsamode
	.long ParamStr12_Empty
ParamStr12_Empty:
	aligned_string ""
ParamStr12_oldmsamode:
	aligned_string "oldmsamode"
ParamStr12_newmsamode:
	aligned_string "newmsamode"
ParamStr12_fontcolor:
	aligned_string "fontcolor"
ParamStr12_font:
	aligned_string "font"
ParamStr12_func:
	aligned_string "func"
ParamStr_Table_13:
	.long ParamStr13_func	; PmemModeBox: 5 variables
	.long ParamStr13_font
	.long ParamStr13_fontcolo
	.long ParamStr13_newpmemmode
	.long ParamStr13_oldpmemmode
	.long ParamStr13_Empty
ParamStr13_Empty:
	aligned_string ""
ParamStr13_oldpmemmode:
	aligned_string "oldpmemmode"
ParamStr13_newpmemmode:
	aligned_string "newpmemmode"
ParamStr13_fontcolo:
	aligned_string "fontcolo"
ParamStr13_font:
	aligned_string "font"
ParamStr13_func:
	aligned_string "func"
NakaParam_IvPmemWindowPageCtl:
	.long NakaParam_IvPmemWinPg_page	; IvWindowPageControl: 1 variable
	.long NakaParam_IvPmemWinPg_Empty
NakaParam_IvPmemWinPg_Empty:
	aligned_string ""
NakaParam_IvPmemWinPg_page:
	aligned_string "page"
NakaParam_IvMstStyleWindowPgCtl:
	.long NakaParam_IvMstStyleWinPg_page	; IvPmemWindowPageCtl: 1 variable
	.long NakaParam_IvMstStyleWinPg_Empty
NakaParam_IvMstStyleWinPg_Empty:
	aligned_string ""
NakaParam_IvMstStyleWinPg_page:
	aligned_string "page"
NakaParam_AcTchSensGridBox:
	.long NakaParam_AcTchSens_page	; IvMstStyleWindowPgCtl: 1 variable
	.long NakaParam_AcTchSens_Empty
NakaParam_AcTchSens_Empty:
	aligned_string ""
NakaParam_AcTchSens_page:
	aligned_string "page"
ParamStr_Table_14:
	.long ParamStr14_fixedcol	; AcTchSensGridBox: 3 variables
	.long ParamStr14_fixedrow
	.long ParamStr14_func
	.long ParamStr14_Empty
ParamStr14_Empty:
	aligned_string ""
ParamStr14_func:
	aligned_string "func"
ParamStr14_fixedrow:
	aligned_string "fixedrow"
ParamStr14_fixedcol:
	aligned_string "fixedcol"
ParamStr_Table_15:
	.long ParamStr15_fixedcol	; AcFSWAssGridBox: 3 variables
	.long ParamStr15_fixedrow
	.long ParamStr15_func
	.long ParamStr15_Empty
ParamStr15_Empty:
	aligned_string ""
ParamStr15_func:
	aligned_string "func"
ParamStr15_fixedrow:
	aligned_string "fixedrow"
ParamStr15_fixedcol:
	aligned_string "fixedcol"
ParamStr_Table_16:
	.long ParamStr16_fixedcol	; AcPmExpFilterGridBox: 3 variables
	.long ParamStr16_fixedrow
	.long ParamStr16_func
	.long ParamStr16_Empty
ParamStr16_Empty:
	aligned_string ""
ParamStr16_func:
	aligned_string "func"
ParamStr16_fixedrow:
	aligned_string "fixedrow"
ParamStr16_fixedcol:
	aligned_string "fixedcol"
ParamStr_Table_17:
	.long ParamStr17_fixedcol	; AcDispTimeSetGridBox: 3 variables
	.long ParamStr17_fixedrow
	.long ParamStr17_func
	.long ParamStr17_Empty
ParamStr17_Empty:
	aligned_string ""
ParamStr17_func:
	aligned_string "func"
ParamStr17_fixedrow:
	aligned_string "fixedrow"
ParamStr17_fixedcol:
	aligned_string "fixedcol"
NakaParam_AcMstStyleAlpGridBox:
	.long ClassVar_AcMstSugAlpGridBox_fixedcol	; AcMstSugAlpGridBox: 10 variables
	.long ClassVar_AcMstSugAlpGridBox_fixedrow
	.long ClassVar_AcMstSugAlpGridBox_func
	.long ClassVar_AcMstSugAlpGridBox_nowalph
	.long ClassVar_AcMstSugAlpGridBox_nowalphtop
	.long ClassVar_AcMstSugAlpGridBox_nowalphdtno
	.long MstStyleAlpGrid_nowalphmaxpage
	.long MstStyleAlpGrid_nowalphpage
	.long MstStyleAlpGrid_nowalphselsong
	.long MstStyleAlpGrid_nowttlselsong
	.long MstStyleAlpGrid_Empty
MstStyleAlpGrid_Empty:
	aligned_string ""
MstStyleAlpGrid_nowttlselsong:
	aligned_string "nowttlselsong"
MstStyleAlpGrid_nowalphselsong:
	aligned_string "nowalphselsong"
MstStyleAlpGrid_nowalphpage:
	aligned_string "nowalphpage"
MstStyleAlpGrid_nowalphmaxpage:
	aligned_string "nowalphmaxpage"
ClassVar_AcMstSugAlpGridBox_nowalphdtno:	aligned_string "nowalphdtno"
ClassVar_AcMstSugAlpGridBox_nowalphtop:	aligned_string "nowalphtop"
ClassVar_AcMstSugAlpGridBox_nowalph:	aligned_string "nowalph"
ClassVar_AcMstSugAlpGridBox_func:	aligned_string "func"
ClassVar_AcMstSugAlpGridBox_fixedrow:	aligned_string "fixedrow"
ClassVar_AcMstSugAlpGridBox_fixedcol:	aligned_string "fixedcol"
ParamStr_Table_18:
	.long ParamStr18_fixedcol	; AcMstStyleAlpGridBox: 8 variables
	.long ParamStr18_fixedrow
	.long ParamStr18_func
	.long ParamStr18_nowalph
	.long ParamStr18_nowalphtop
	.long ParamStr18_nowalphdtno
	.long ParamStr18_nowalphmaxpage
	.long ParamStr18_nowalphpage
	.long ParamStr18_Empty
ParamStr18_Empty:
	aligned_string ""
ParamStr18_nowalphpage:
	aligned_string "nowalphpage"
ParamStr18_nowalphmaxpage:
	aligned_string "nowalphmaxpage"
ParamStr18_nowalphdtno:
	aligned_string "nowalphdtno"
ParamStr18_nowalphtop:
	aligned_string "nowalphtop"
ParamStr18_nowalph:
	aligned_string "nowalph"
ParamStr18_func:
	aligned_string "func"
ParamStr18_fixedrow:
	aligned_string "fixedrow"
ParamStr18_fixedcol:
	aligned_string "fixedcol"
NakaParam_AcMstStyle1SubGridBox:
	.long ClassVar_AcMstStyle1GridBox_fixedcol	; AcMstStyle1GridBox: 6 variables
	.long ClassVar_AcMstStyle1GridBox_fixedrow
	.long ParamStr19_func
	.long ParamStr19_nowstylectgdtno
	.long ParamStr19_nowstylectgmaxpage
	.long ParamStr19_nowstylectgpage
	.long ParamStr19_Empty
ParamStr19_Empty:
	aligned_string ""
ParamStr19_nowstylectgpage:
	aligned_string "nowstylectgpage"
ParamStr19_nowstylectgmaxpage:
	aligned_string "nowstylectgmaxpage"
ParamStr19_nowstylectgdtno:
	aligned_string "nowstylectgdtno"
ParamStr19_func:
	aligned_string "func"
ClassVar_AcMstStyle1GridBox_fixedrow:	aligned_string "fixedrow"
ClassVar_AcMstStyle1GridBox_fixedcol:	aligned_string "fixedcol"
ParamStr_Table_20:
	.long ParamStr20_fixedcol	; AcMstStyle1SubGridBox: 6 variables
	.long ParamStr20_fixedrow
	.long ParamStr20_func
	.long ParamStr20_nowstylesubctgdtno
	.long ParamStr20_nowstylesubctgmaxpage
	.long ParamStr20_nowstylesubctgpage
	.long ParamStr20_Empty
ParamStr20_Empty:
	aligned_string ""
ParamStr20_nowstylesubctgpage:
	aligned_string "nowstylesubctgpage"
ParamStr20_nowstylesubctgmaxpage:
	aligned_string "nowstylesubctgmaxpage"
ParamStr20_nowstylesubctgdtno:
	aligned_string "nowstylesubctgdtno"
ParamStr20_func:
	aligned_string "func"
ParamStr20_fixedrow:
	aligned_string "fixedrow"
ParamStr20_fixedcol:
	aligned_string "fixedcol"
ParamStr_Table_21:
	.long ParamStr21_fixedcol	; AcMstStyle2GridBox: 10 variables
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
ParamStr21_Empty:
	aligned_string ""
ParamStr21_nowstylesubsubdtno2:
	aligned_string "nowstylesubsubdtno2"
ParamStr21_nowstylesubsubdtno1:
	aligned_string "nowstylesubsubdtno1"
ParamStr21_nowstyle:
	aligned_string "nowstyle"
ParamStr21_nowstylesubctg:
	aligned_string "nowstylesubctg"
ParamStr21_nowstylesubctgpage:
	aligned_string "nowstylesubctgpage"
ParamStr21_nowstylesubctgmaxpage:
	aligned_string "nowstylesubctgmaxpage"
ParamStr21_nowstylesubctgdtno:
	aligned_string "nowstylesubctgdtno"
ParamStr21_func:
	aligned_string "func"
ParamStr21_fixedrow:
	aligned_string "fixedrow"
ParamStr21_fixedcol:
	aligned_string "fixedcol"
NakaParam_AcMstSong2GridBox:
	.long ClassVar_AcMstSong1GridBox_fixedcol	; AcMstSong1GridBox: 6 variables
	.long ClassVar_AcMstSong1GridBox_fixedrow
	.long MstSong2Grid_func
	.long MstSong2Grid_nowsongctgdtno
	.long MstSong2Grid_nowsongctgmaxpage
	.long MstSong2Grid_nowsongctgpage
	.long ClassVar_AcMstSong1GridBox_End
ClassVar_AcMstSong1GridBox_End:	aligned_string ""
MstSong2Grid_nowsongctgpage:
	aligned_string "nowsongctgpage"
MstSong2Grid_nowsongctgmaxpage:
	aligned_string "nowsongctgmaxpage"
MstSong2Grid_nowsongctgdtno:
	aligned_string "nowsongctgdtno"
MstSong2Grid_func:
	aligned_string "func"
ClassVar_AcMstSong1GridBox_fixedrow:	aligned_string "fixedrow"
ClassVar_AcMstSong1GridBox_fixedcol:	aligned_string "fixedcol"
ParamStr_Table_22:
	.long ClassVar_AcMstSong2GridBox_fixedcol	; AcMstSong2GridBox: 10 variables
	.long ClassVar_AcMstSong2GridBox_fixedrow
	.long ClassVar_AcMstSong2GridBox_func
	.long ClassVar_AcMstSong2GridBox_nowsongsubctgdtno
	.long ParamStr22_nowsongsubctgmaxpage
	.long ParamStr22_nowsongsubctgpage
	.long ParamStr22_nowsongsubctg
	.long ParamStr22_nowsong
	.long ParamStr22_nowsongsubsubdtno1
	.long ParamStr22_nowsongsubsubdtno2
	.long ParamStr22_Empty
ParamStr22_Empty:
	aligned_string ""
ParamStr22_nowsongsubsubdtno2:
	aligned_string "nowsongsubsubdtno2"
ParamStr22_nowsongsubsubdtno1:
	aligned_string "nowsongsubsubdtno1"
ParamStr22_nowsong:
	aligned_string "nowsong"
ParamStr22_nowsongsubctg:
	aligned_string "nowsongsubctg"
ParamStr22_nowsongsubctgpage:
	aligned_string "nowsongsubctgpage"
ParamStr22_nowsongsubctgmaxpage:
	aligned_string "nowsongsubctgmaxpage"
ClassVar_AcMstSong2GridBox_nowsongsubctgdtno:	aligned_string "nowsongsubctgdtno"
ClassVar_AcMstSong2GridBox_func:	aligned_string "func"
ClassVar_AcMstSong2GridBox_fixedrow:	aligned_string "fixedrow"
ClassVar_AcMstSong2GridBox_fixedcol:	aligned_string "fixedcol"
ParamStr_Table_23:
	.long ParamStr23_func	; SineWaveScreen: 5 variables
	.long ParamStr23_font
	.long ParamStr23_fontcolor
	.long ParamStr23_nowswno
	.long ParamStr23_oldswno
	.long ParamStr23_Empty
ParamStr23_Empty:
	aligned_string ""
ParamStr23_oldswno:
	aligned_string "oldswno"
ParamStr23_nowswno:
	aligned_string "nowswno"
ParamStr23_fontcolor:
	aligned_string "fontcolor"
ParamStr23_font:
	aligned_string "font"
ParamStr23_func:
	aligned_string "func"
ParamStr_Table_24:
	.long ParamStr24_page	; IvPageOverWr: 2 variables
	.long ParamStr24_window
	.long ParamStr24_Empty
ParamStr24_Empty:
	aligned_string ""
ParamStr24_window:
	aligned_string "window"
ParamStr24_page:
	aligned_string "page"

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
; ---------------------------------------------------------------------------
; The tail of Toshi_Class_Table's string pool.  Each of the 28 class records
; points at a type-signature string (+0x10) and a class-name string (+0x0C);
; the pool holds them as (signature, name) pairs in REVERSE record order, and
; its first part -- down to "XX" of record 18's signature -- is inside the
; naka_master_style.c blob included above, so this file resumes with "j".
; !! The NakaDesc_* / NakaInst_* labels below are ONE CLASS OFF: each labels
; the signature / name of the class that FOLLOWS its namesake in the pool
; (NakaInst_VariScreen is the string "NormScreen").  They are kept because
; ui_widgets/naka_master_style.c and its .ld cite them by name.  Record
; layout and the check that each signature has one character per variable:
; Toshi_Class_Table's header, scripts/analysis/ext_lane_checks.py class.
; ---------------------------------------------------------------------------
	.byte 0x6a, 0x00	; tail of record 18's signature "XXj"
NakaInst_AcMstSugAlpGridBox:
	aligned_string "AcDispTimeSetGridBox"
NakaDesc_AcDispTimeSetGridBox:	aligned_string "XXj"
NakaInst_AcDispTimeSetGridBox:	aligned_string "AcPmExpFilterGridBox"
NakaDesc_AcPmExpFilterGridBox:	aligned_string "XXj"
NakaInst_AcPmExpFilterGridBox:	aligned_string "AcFSWAssGridBox"
NakaDesc_AcFSWAssGridBox:	aligned_string "XXj"
NakaInst_AcFSWAssGridBox:
	aligned_string "AcTchSensGridBox"
NakaDesc_AcTchSensGridBox:
	aligned_string "n"
NakaInst_AcTchSensGridBox:
	aligned_string "IvMstStyleWindowPgCtl"
NakaDesc_IvMstStyleWindowPgCtl:
	aligned_string "n"
NakaInst_IvMstStyleWindowPgCtl:
	aligned_string "IvPmemWindowPageCtl"
NakaDesc_IvPmemWindowPageCtl:
	aligned_string "n"
NakaInst_IvPmemWindowPageCtl:
	aligned_string "IvWindowPageControl"
NakaDesc_IvWindowPageControl:	aligned_string "kc^nn"
NakaInst_IvWindowPageControl:	aligned_string "PmemModeBox"
NakaDesc_PmemModeBox:	aligned_string "kc^nn"
NakaInst_PmemModeBox:	aligned_string "MsaModeScreen"
NakaDesc_MsaModeScreen:	aligned_string "jr"
NakaInst_MsaModeScreen:
	aligned_string "AcPmBkEditBox"
NakaDesc_AcPmBkEditBox:	aligned_string "kc^nnn"
NakaInst_AcPmBkEditBox:	aligned_string "PmBankScreen"
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
; Registered by InitializeToshi (0xFC294F) with
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
	.long AcMstStyleAlp_Boundary
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
; Registered by InitializeToshi (0xFC294F) with
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
; naka_node -- the first 12 bytes every NAKA widget record shares: the 4-byte
; header {type, 0x00, 0x60, 0x01} and four element-index links (see below).
.macro naka_node type, parent, child, next, prev
	.byte \type, 0x00, 0x60, 0x01
	.short \parent, \child, \next, \prev
.endm
; ---------------------------------------------------------------------------
; NAKA widget records: elements 24-62 of Toshi_Viewable_NORMAL (object-
; registry slot 1, 63 entries, registered by InitializeToshi -- see
; extensions/extension_init.s).  Every entry of that table from 25 to 62
; points at one of the records below, in order; element 24 begins in
; ui_widgets/normal_mode_layout.s and only its last 14 bytes are here.
;
; Common part (`naka_node`): the 4-byte NAKA header, then four element
; indices into the SAME viewable table -- parent, first child, next
; sibling, previous sibling -- NAKA_INDEX_NONE when absent.  That reading
; is checked for all 38 records: every next/prev pair and every child/parent
; pair agree (scripts/analysis/ext_lane_checks.py widgets).  It contradicts
; ui_widgets/naka_types.h, which calls +6 prev_sibling, +8 self_idx and +10
; next_sibling: record 25's +8 is 26, and element 26's +10 is 25.
; +0x0E..+0x14 are a rectangle x1, y1, x2, y2 on the 320x240 screen that
; lies inside the parent's rectangle in every record (same script).  The
; six 0x35 records are root panels: elements 24, 33, 39 and 48 span the
; bottom of the screen, (0,127)-(319,23x), and parent 8, 5, 8 and 8 0x3C
; cells at x = 4, 43, 82, ... (39 px apart); elements 57 and 60 span
; (4,190)-(315,236) and parent two 0x69 records each.  +0x0C (always 8)
; and the fields after the rectangle are not traced to a reader; each 0x35
; panel ends in two consecutive u32 RAM addresses, 0x3F404/0x3F408 for
; element 24 up to 0x3F42C/0x3F430 for element 60.  Record sizes: 0x3C 32 B,
; 0x35 36 B, 0x69 26 B.
; Until 2026-09-25 sixteen of these rectangles' (x2, y2) corners
; were written as POINTERS -- `.long WidgetName_PtrBlock_C` ({42, 235}), _D,
; _E, _F2, _I2, _L, _M2, _N1, `.long SoundName_ToTheBone` and `.long
; Naka_PresentationRootState` (element 39's right/bottom edge {319, 239}).
; None is a pointer: every one is a rectangle corner inside its parent, and
; v7 proves the last one -- it moved Naka_PresentationRootState by -0x2A and
; kept these bytes.
; ---------------------------------------------------------------------------
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED37EF-0xED380A (27 B), unreached CODE-territory, was disassembled as 20 plausible-but-dead instruction lines; per=100% dist=12 near NakaInst_MainVariSet+935
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED382F-0xED384A (27 B), unreached CODE-territory, was disassembled as 20 plausible-but-dead instruction lines; per=100% dist=14 near NakaInst_MainVariSet+999
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3859-0xED386A (17 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1041
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED391D-0xED392E (17 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1237
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED395B-0xED396E (19 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+1299
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED397D-0xED398E (17 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=9 near NakaInst_MainVariSet+1333
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED39D7-0xED39F2 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=12 near NakaInst_MainVariSet+1423
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A01-0xED3A12 (17 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1465
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A13-0xED3A32 (31 B), unreached CODE-territory, was disassembled as 24 plausible-but-dead instruction lines; per=100% dist=15 near NakaInst_MainVariSet+1483
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A37-0xED3A52 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=13 near NakaInst_MainVariSet+1519
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A61-0xED3A72 (17 B), unreached CODE-territory, was disassembled as 15 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1561
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3A77-0xED3A92 (27 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=100% dist=13 near NakaInst_MainVariSet+1583
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3B25-0xED3B36 (17 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=10 near NakaInst_MainVariSet+1757
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3C1F-0xED3C34 (21 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+2007
	; element 24 (0x35), +0x16..+0x23 -- begun in normal_mode_layout.s
	.short 245, 0, 0
	.long 0x0003f404, 0x0003f408
Toshi_NORMAL_Elem25:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 26, NAKA_INDEX_NONE
	.short 8, 277, 128, 315, 235
	.short 7, 193, 0xffff, 0, 7
Toshi_NORMAL_Elem26:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 27, 25
	.short 8, 238, 128, 276, 235
	.short 7, 193, 0xffff, 1, 6
Toshi_NORMAL_Elem27:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 28, 26
	.short 8, 199, 128, 237, 235
	.short 7, 193, 0xffff, 2, 5
Toshi_NORMAL_Elem28:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 29, 27
	.short 8, 160, 128, 198, 235
	.short 7, 193, 0xffff, 19, 4
Toshi_NORMAL_Elem29:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 30, 28
	.short 8, 121, 128, 159, 235
	.short 7, 193, 0xffff, 16, 3
Toshi_NORMAL_Elem30:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 31, 29
	.short 8, 82, 128, 120, 235
	.short 7, 193, 0xffff, 17, 2
Toshi_NORMAL_Elem31:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, 32, 30
	.short 8, 43, 128, 81, 235
	.short 7, 193, 0xffff, 18, 1
Toshi_NORMAL_Elem32:
	naka_node 0x3c, 24, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 31
	.short 8, 4, 128, 42, 235
	.short 7, 193, 0xffff, 20, 0
Toshi_NORMAL_Elem33:
	naka_node 0x35, NAKA_INDEX_NONE, 34, NAKA_INDEX_NONE, NAKA_INDEX_NONE
	.short 8, 0, 127, 319, 239
	.short 245, 0, 0
	.long 0x0003f40c, 0x0003f410
Toshi_NORMAL_Elem34:
	naka_node 0x3c, 33, NAKA_INDEX_NONE, 35, NAKA_INDEX_NONE
	.short 8, 160, 128, 198, 235
	.short 7, 193, 0xffff, 21, 4
Toshi_NORMAL_Elem35:
	naka_node 0x3c, 33, NAKA_INDEX_NONE, 36, 34
	.short 8, 121, 128, 159, 235
	.short 7, 193, 0xffff, 22, 3
Toshi_NORMAL_Elem36:
	naka_node 0x3c, 33, NAKA_INDEX_NONE, 37, 35
	.short 8, 82, 128, 120, 235
	.short 7, 193, 0xffff, 23, 2
Toshi_NORMAL_Elem37:
	naka_node 0x3c, 33, NAKA_INDEX_NONE, 38, 36
	.short 8, 43, 128, 81, 235
	.short 7, 193, 0xffff, 26, 1
Toshi_NORMAL_Elem38:
	naka_node 0x3c, 33, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 37
	.short 8, 4, 128, 42, 235
	.short 7, 193, 0xffff, 27, 0
Toshi_NORMAL_Elem39:
	naka_node 0x35, NAKA_INDEX_NONE, 40, NAKA_INDEX_NONE, NAKA_INDEX_NONE
	.short 8, 0, 127, 319, 239
	.short 245, 0, 0
	.long 0x0003f414, 0x0003f418
Toshi_NORMAL_Elem40:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 41, NAKA_INDEX_NONE
	.short 8, 4, 128, 42, 235
	.short 7, 193, 0xffff, 0, 0
Toshi_NORMAL_Elem41:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 42, 40
	.short 8, 43, 128, 81, 235
	.short 7, 193, 0xffff, 1, 1
Toshi_NORMAL_Elem42:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 43, 41
	.short 8, 82, 128, 120, 235
	.short 7, 193, 0xffff, 2, 2
Toshi_NORMAL_Elem43:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 44, 42
	.short 8, 121, 128, 159, 235
	.short 7, 193, 0xffff, 3, 3
Toshi_NORMAL_Elem44:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 45, 43
	.short 8, 160, 128, 198, 235
	.short 7, 193, 0xffff, 4, 4
Toshi_NORMAL_Elem45:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 46, 44
	.short 8, 199, 128, 237, 235
	.short 7, 193, 0xffff, 5, 5
Toshi_NORMAL_Elem46:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, 47, 45
	.short 8, 238, 128, 276, 235
	.short 7, 193, 0xffff, 6, 6
Toshi_NORMAL_Elem47:
	naka_node 0x3c, 39, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 46
	.short 8, 277, 128, 315, 235
	.short 7, 193, 0xffff, 7, 7
Toshi_NORMAL_Elem48:
	naka_node 0x35, NAKA_INDEX_NONE, 49, NAKA_INDEX_NONE, NAKA_INDEX_NONE
	.short 8, 0, 127, 319, 239
	.short 245, 0, 0
	.long 0x0003f41c, 0x0003f420
Toshi_NORMAL_Elem49:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 50, NAKA_INDEX_NONE
	.short 8, 4, 128, 42, 235
	.short 7, 193, 0xffff, 8, 0
Toshi_NORMAL_Elem50:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 51, 49
	.short 8, 43, 128, 81, 235
	.short 7, 193, 0xffff, 9, 1
Toshi_NORMAL_Elem51:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 52, 50
	.short 8, 82, 128, 120, 235
	.short 7, 193, 0xffff, 10, 2
Toshi_NORMAL_Elem52:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 53, 51
	.short 8, 121, 128, 159, 235
	.short 7, 193, 0xffff, 11, 3
Toshi_NORMAL_Elem53:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 54, 52
	.short 8, 160, 128, 198, 235
	.short 7, 193, 0xffff, 12, 4
Toshi_NORMAL_Elem54:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 55, 53
	.short 8, 199, 128, 237, 235
	.short 7, 193, 0xffff, 13, 5
Toshi_NORMAL_Elem55:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, 56, 54
	.short 8, 238, 128, 276, 235
	.short 7, 193, 0xffff, 14, 6
Toshi_NORMAL_Elem56:
	naka_node 0x3c, 48, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 55
	.short 8, 277, 128, 315, 235
	.short 7, 193, 0xffff, 15, 7
Toshi_NORMAL_Elem57:
	naka_node 0x35, NAKA_INDEX_NONE, 58, NAKA_INDEX_NONE, NAKA_INDEX_NONE
	.short 8, 4, 190, 315, 236
	.short 7, 193, 0
	.long 0x0003f424, 0x0003f428
Toshi_NORMAL_Elem58:
	naka_node 0x69, 57, NAKA_INDEX_NONE, 59, NAKA_INDEX_NONE
	.short 8, 152, 200, 263, 224
	.short 22, 290
Toshi_NORMAL_Elem59:
	naka_node 0x69, 57, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 58
	.short 8, 56, 204, 135, 221
	.short 23, 290
Toshi_NORMAL_Elem60:
	naka_node 0x35, NAKA_INDEX_NONE, 61, NAKA_INDEX_NONE, NAKA_INDEX_NONE
	.short 8, 4, 190, 315, 236
	.short 7, 193, 0
	.long 0x0003f42c, 0x0003f430
Toshi_NORMAL_Elem61:
	naka_node 0x69, 60, NAKA_INDEX_NONE, 62, NAKA_INDEX_NONE
	.short 8, 40, 204, 147, 223
	.short 25, 290
Toshi_NORMAL_Elem62:
	naka_node 0x69, 60, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 61
	.short 8, 160, 200, 272, 224
	.short 24, 290


	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xED3C77-0xED3C8C (21 B), unreached CODE-territory, was disassembled as 18 plausible-but-dead instruction lines; per=100% dist=11 near NakaInst_MainVariSet+2095
.include "ui_widgets/control_menu_screens.s"
; ---------------------------------------------------------------------------
; The "CPU data transmission" error texts: five LABEL (type 0x2B) records,
; elements 8-12 of Toshi_Viewable_TEST1 (object-registry slot 0xF4, 14
; entries, registered by InitializeToshi -- extensions/extension_init.s),
; all children of element 7, the 0x35 panel at 0xED6676 in
; ui_widgets/control_menu_screens.s.  Layout as the NORMAL records above:
; `naka_node` (parent, first child, next, previous -- element indices of the
; same table), +0x0C (8), the text rectangle x1, y1, x2, y2, +0x16 a pointer
; to the record's string, +0x1A..+0x1E three words, then the string.  The
; links are checked by scripts/analysis/ext_lane_checks.py test1.  Element 8
; begins 2 bytes before this file resumes: its type byte 0x2B and the 0x00
; after it are the last two bytes of the control_menu_screens.s blob.
; ---------------------------------------------------------------------------
	.byte 0x60, 0x01	; element 8: header bytes 2-3
	.short 7, NAKA_INDEX_NONE, 9, NAKA_INDEX_NONE
	.short 8, 78, 128, 225, 146
	.long Str_ErrorDialog_Caution
	.short 2, 0, 249
Str_ErrorDialog_Caution:	.asciz "CAUTION!!"	; English text


; ---------------------------------------------------------------------------
; Element 9 of Toshi_Viewable_TEST1: ERROR Message
; "** ERROR in CPU data transmission **"
; CORRECTED 2026-09-25: this used to say "Widget 10 (0x0a)" and "Screen group
; 7, index 10"; 7 is the PARENT element and 0x0a the NEXT sibling (element 10).
; ---------------------------------------------------------------------------
ErrorDialog_CPUTransmissionError:
	naka_node 0x2b, 7, NAKA_INDEX_NONE, 10, 8
	.short 8, 14, 150, 305, 168
	.long Str_ErrorDialog_CPUTransmission
	.short 0, 0, 2
Str_ErrorDialog_CPUTransmission:	aligned_string "** ERROR in CPU data transmission **"


; ---------------------------------------------------------------------------
; Element 10 of Toshi_Viewable_TEST1: Recovery Instruction Line 1
; "Please try turning off and on again."
; (was "Widget 11 (0x0b)" / "Screen group 7, index 11": parent 7, next 11)
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine1:
	naka_node 0x2b, 7, NAKA_INDEX_NONE, 11, 9
	.short 8, 46, 174, 265, 184
	.long Str_ErrorDialog_TryTurningOff
	.short 3, 0, 0
Str_ErrorDialog_TryTurningOff:	aligned_string "Please try turning off and on again."


; ---------------------------------------------------------------------------
; Element 11 of Toshi_Viewable_TEST1: Recovery Instruction Line 2
; "If this message appears again,"
; (was "Widget 12 (0x0c)" / "Screen group 7, index 12": parent 7, next 12;
; its rectangle's y1/x2 pair used to be written `.long
; TechnichordParam_Block3`, an absolute symbol that happens to equal
; 0x00E500BE = {190, 229})
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine2:
	naka_node 0x2b, 7, NAKA_INDEX_NONE, 12, 10
	.short 8, 46, 190, 229, 200
	.long Str_ErrorDialog_AppearsAgain
	.short 3, 0, 0
Str_ErrorDialog_AppearsAgain:	aligned_string "If this message appears again,"


; ---------------------------------------------------------------------------
; Element 12 of Toshi_Viewable_TEST1: Recovery Instruction Line 3
; "this unit needs repairing."
; (was "Widget 13 (end marker 0xffff)" / "Screen group 7, final widget": the
; 0xffff is "no next sibling", i.e. the LAST child of element 7)
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine3:
	naka_node 0x2b, 7, NAKA_INDEX_NONE, NAKA_INDEX_NONE, 11
	.short 8, 46, 206, 205, 216
	.long Str_ErrorDialog_NeedsRepairing
	.short 3, 0, 0
Str_ErrorDialog_NeedsRepairing:	aligned_string "this unit needs repairing."
.include "ui_widgets/extension_device_screens.s"
; ---------------------------------------------------------------------------
; ENCODER LOOKUP TABLES and the BITMASK HANDLER LISTS (0xEDA160-0xEDA615)
; ---------------------------------------------------------------------------
; The lookup tables are named by absolute `.set`s in kn5000_v10_program.s
; (ENCODER_LUT_*; listed also in midi_encoder_constants.s) and read by the
; Encoder_Process* routines of midi/midi_encoder_routines.s, e.g.
; Encoder_ProcessVolume (0xFC64E3): `extz wa` / `lda xbc,
; (ENCODER_LUT_VOLUME:24)` / `ld a, (xrr+rr)` -- one byte per raw controller
; value.  They are monotonic curves, which is why earlier passes wrote whole
; stretches of them as .ascii "!\"#$%&..."; they are bytes, not text.
;
; The eight lists are read by DispatchBitmaskHandlers (audio/
; audio_control_engine.s, 0xFC712B): entries of {u16 mask, u32 handler},
; `and wa, (xiz)` / `call (xiz + 2)` for every mask bit set in the flag word
; the caller passes, `inc 6, xiz`, until a mask of 0xFFFF.
; MIDI_ProcessChangedChannels (0xFC683F) passes four "changed" words and
; MidiChannel_DispatchChanged (0xFC68B2) four others; the callers reach the
; lists through positional names MIDI_ProcessChangedChannels_Data .. _0x4D4
; (shared/positional_labels.s).  Six handlers (0xFC75E3, 0xFC7704, 0xFC7686,
; 0xFC75A6, 0xFC75B7, 0xFC7741) have no label there and stay numeric.
; ---------------------------------------------------------------------------
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA545-0xEDA558 (19 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=100% dist=10 near MidiChanged_ProcessGroup2_Data+13
	; ENCODER_LUT_MODWHEEL, entries 36-127 (0-35 are in the blob above): 92 bytes
	.byte 0x21, 0x22, 0x23, 0x24, 0x25, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2c, 0x2d, 0x2e
	.byte 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3b, 0x3c
	.byte 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b
	.byte 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59
	.byte 0x5a, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67
	.byte 0x68, 0x69, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x71, 0x74, 0x78, 0x7b, 0x7f
	; ENCODER_LUT_VOLUME: 256 bytes
	; Encoder_ProcessVolume (encoder 5, the volume slider) maps the raw 8-bit position through it, then
	; Encoder_ClampScaleAndNormalize scales the result into MIDI_CC_VOLUME_VALUE (0..127)
ENCODER_LUT_VOLUME:
	.byte 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x07, 0x07, 0x08, 0x08
	.byte 0x09, 0x09, 0x0a, 0x0a, 0x0b, 0x0b, 0x0c, 0x0c, 0x0d, 0x0e, 0x0e, 0x0f, 0x0f, 0x10, 0x10, 0x11
	.byte 0x11, 0x12, 0x12, 0x13, 0x14, 0x14, 0x15, 0x15, 0x16, 0x16, 0x17, 0x17, 0x18, 0x18, 0x19, 0x19
	.byte 0x1a, 0x1b, 0x1b, 0x1c, 0x1c, 0x1d, 0x1d, 0x1e, 0x1e, 0x1f, 0x1f, 0x20, 0x21, 0x21, 0x22, 0x22
	.byte 0x23, 0x23, 0x24, 0x24, 0x25, 0x25, 0x26, 0x27, 0x27, 0x28, 0x28, 0x29, 0x29, 0x2a, 0x2a, 0x2b
	.byte 0x2b, 0x2c, 0x2c, 0x2d, 0x2e, 0x2e, 0x2f, 0x2f, 0x30, 0x30, 0x31, 0x31, 0x32, 0x32, 0x33, 0x34
	.byte 0x34, 0x35, 0x35, 0x36, 0x36, 0x37, 0x37, 0x38, 0x38, 0x39, 0x39, 0x3a, 0x3a, 0x3b, 0x3b, 0x3c
	.byte 0x3c, 0x3d, 0x3d, 0x3e, 0x3e, 0x3f, 0x3f, 0x40, 0x40, 0x41, 0x41, 0x42, 0x42, 0x43, 0x43, 0x44
	.byte 0x44, 0x45, 0x45, 0x46, 0x46, 0x47, 0x47, 0x48, 0x48, 0x49, 0x49, 0x4a, 0x4a, 0x4b, 0x4b, 0x4c
	.byte 0x4c, 0x4d, 0x4e, 0x4e, 0x4f, 0x50, 0x51, 0x51, 0x52, 0x53, 0x54, 0x54, 0x55, 0x56, 0x57, 0x57
	.byte 0x58, 0x59, 0x5a, 0x5a, 0x5b, 0x5c, 0x5c, 0x5d, 0x5e, 0x5f, 0x5f, 0x60, 0x61, 0x62, 0x62, 0x63
	.byte 0x64, 0x65, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6d, 0x6e, 0x6f, 0x70, 0x71
	.byte 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80
	.byte 0x82, 0x83, 0x85, 0x87, 0x88, 0x8a, 0x8c, 0x8d, 0x8f, 0x91, 0x92, 0x94, 0x96, 0x97, 0x99, 0x9b
	.byte 0x9d, 0x9f, 0xa1, 0xa3, 0xa5, 0xa7, 0xa9, 0xab, 0xad, 0xaf, 0xb1, 0xb3, 0xb7, 0xba, 0xbe, 0xc1
	.byte 0xc5, 0xc8, 0xcc, 0xd1, 0xd6, 0xdc, 0xe1, 0xe6, 0xe9, 0xec, 0xef, 0xf3, 0xf6, 0xf9, 0xfc, 0xff
	; ENCODER_LUT_BREATH_INDEX: 22 bytes
	; 11 x u16 multipliers (0, 6, 8 ... 40): Encoder_ClampScaleAndNormalize takes entry [ENCODER_VOLUME_MODE]
	; and scales the clamped value by it / 20
ENCODER_LUT_BREATH_INDEX:
	.byte 0x00, 0x00, 0x06, 0x00, 0x08, 0x00, 0x0a, 0x00, 0x0d, 0x00, 0x10, 0x00, 0x13, 0x00, 0x16, 0x00
	.byte 0x19, 0x00, 0x1e, 0x00, 0x28, 0x00
	; ENCODER_LUT_BREATH_VALUE: 256 bytes
	; Encoder_ProcessBreath maps the inverted raw breath-controller value through it
ENCODER_LUT_BREATH_VALUE:
	.byte 0x00, 0x00, 0x00, 0x00, 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18
	.byte 0x1a, 0x1c, 0x1e, 0x20, 0x22, 0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e, 0x30, 0x32, 0x33, 0x34, 0x35
	.byte 0x36, 0x38, 0x3a, 0x3c, 0x3e, 0x3f, 0x40, 0x42, 0x44, 0x45, 0x46, 0x48, 0x4a, 0x4b, 0x4c, 0x4d
	.byte 0x4e, 0x50, 0x51, 0x52, 0x54, 0x55, 0x56, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60
	.byte 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6a, 0x6b, 0x6b, 0x6c, 0x6c, 0x6d
	.byte 0x6d, 0x6e, 0x6e, 0x6f, 0x6f, 0x70, 0x70, 0x71, 0x71, 0x72, 0x72, 0x73, 0x73, 0x74, 0x74, 0x75
	.byte 0x75, 0x76, 0x76, 0x77, 0x77, 0x78, 0x78, 0x79, 0x79, 0x7a, 0x7a, 0x7b, 0x7b, 0x7c, 0x7c, 0x7d
	.byte 0x7d, 0x7d, 0x7e, 0x7e, 0x7e, 0x7f, 0x7f, 0x7f, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x81, 0x81, 0x81, 0x81, 0x82, 0x82
	.byte 0x82, 0x82, 0x83, 0x83, 0x83, 0x84, 0x84, 0x85, 0x85, 0x86, 0x86, 0x87, 0x87, 0x88, 0x88, 0x89
	.byte 0x89, 0x8a, 0x8a, 0x8b, 0x8b, 0x8c, 0x8c, 0x8d, 0x8d, 0x8e, 0x8e, 0x8f, 0x8f, 0x90, 0x90, 0x91
	.byte 0x91, 0x92, 0x92, 0x93, 0x94, 0x95, 0x96, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e
	.byte 0x9f, 0xa0, 0xa1, 0xa2, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xb0, 0xb1
	.byte 0xb2, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xba, 0xbc, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3, 0xc4, 0xc6, 0xc8
	.byte 0xca, 0xcc, 0xcd, 0xce, 0xd0, 0xd2, 0xd4, 0xd6, 0xd8, 0xda, 0xdc, 0xdd, 0xde, 0xe0, 0xe2, 0xe4
	.byte 0xe6, 0xe8, 0xea, 0xec, 0xee, 0xf0, 0xf2, 0xf5, 0xf7, 0xf9, 0xfb, 0xfd, 0xff, 0xff, 0xff, 0xff
	; ENCODER_LUT_BREATH_MULT: 24 bytes
ENCODER_LUT_BREATH_MULT:
	.byte 0x15, 0x00, 0x2b, 0x00, 0x40, 0x00, 0x55, 0x00, 0x6b, 0x00, 0x80, 0x00, 0x95, 0x00, 0xab, 0x00
	.byte 0xc0, 0x00, 0xd5, 0x00, 0xeb, 0x00, 0x00, 0x01
	; ENCODER_LUT_BREATH_OFFSET: 24 bytes
ENCODER_LUT_BREATH_OFFSET:
	.byte 0x55, 0x05, 0xab, 0x0a, 0x00, 0x10, 0x55, 0x15, 0xab, 0x1a, 0x00, 0x20, 0x55, 0x25, 0xab, 0x2a
	.byte 0x00, 0x30, 0x55, 0x35, 0xab, 0x3a, 0x00, 0x40
	; ENCODER_LUT_FOOT: 128 bytes
ENCODER_LUT_FOOT:
	.byte 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e
	.byte 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e
	.byte 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e
	.byte 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e
	.byte 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e
	.byte 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e
	.byte 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e
	.byte 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7d, 0x7f, 0x7f
	; ENCODER_LUT_EXPRESSION: 128 bytes
ENCODER_LUT_EXPRESSION:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
	.byte 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
	.byte 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
	.byte 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
	.byte 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
	.byte 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f
	.byte 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f
	; MIDI_ProcessChangedChannels, group 1: flags 0x8F3A & ~0x8F3C
MIDI_ProcessChangedChannels_Data:
	.short 0x0001
	.long MIDI_ProcessChangedChannels_Data_Target0
	.short 0x0002
	.long MIDI_ProcessChangedChannels_Data_Target1
	.short 0x0004
	.long SndParam_TableLookup_Via4100
	.short 0x0008
	.long SndParam_SetResBit1_ViaPartCC5E
	.short 0x0010
	.long SndParam_SetResBit3_Via4002
	.short 0x0020
	.long SndParam_SetResBit0_ViaPartCC40
	.short 0x0040
	.long SndParam_SetResBit2_ViaPartCC5D
	.short 0x0080
	.long SndParam_SetResBit4_Via4004
	.short 0xffff	; end of list
	.long 0xffffffff
	; MIDI_ProcessChangedChannels, group 2: 0x8F3E & ~0x8F40
MidiChanged_ProcessGroup2_Data:
	.short 0x0001
	.long MidiChanged_ProcessGroup2_Data_Target0
	.short 0x0002
	.long SndParam_VoiceEntryLookup_ViaReg8000
	.short 0x0004
	.long SndParam_GuardedNibbleSet_ViaReg0103
	.short 0x0008
	.long SndParam_SetResBit0_Via028103
	.short 0x0010
	.long SndParam_SetResBit2_ViaRegs0101_0102
	.short 0x0020
	.long SndParam_SetResBit3_ViaRegs0101_0102
	.short 0x0040
	.long SndParam_SetResBit0_Via028100
	.short 0x0080
	.long SndParam_SetResBit1_ViaRegs0100_0101
	.short 0x0100
	.long SndParam_SetResBit5_Via028080
	.short 0x0200
	.long SndParam_VoiceEntryLookup_ViaReg8000
	.short 0xffff	; end of list
	.long 0xffffffff
	; MIDI_ProcessChangedChannels, group 3: 0x8F42 & ~0x8F44
MidiChanged_ProcessGroup3_Data:
	.short 0x0001
	.long SndParam_DecrLookup_Via0300
	.short 0x0004
	.long SndParam_SetResBit7_ViaSelection
	.short 0x0008
	.long SndParam_SetResBit4_Via0400
	.short 0x0010
	.long SndParam_SetResBit7_Via4200
	.short 0x0020
	.long SndParam_MaskShiftMerge_8F58
	.short 0x0040
	.long SndParam_SetResBit7_ViaF9A541
	.short 0x0100
	.long ExtData_VoiceParam_DispatchBytecode
	.short 0x0400
	.long MidiChanged_ProcessGroup3_Data_Target7
	.short 0x1000
	.long MidiChanged_ProcessGroup3_Data_Target8
	.short 0x2000
	.long MidiChanged_ProcessGroup3_Data_Target9
	.short 0x4000
	.long CtrlPanel_SetResBit6_ViaLookup
	.short 0x8000
	.long CtrlPanel_MultiWayBitManip_ViaE0
	.short 0xffff	; end of list
	.long 0xffffffff
	; MIDI_ProcessChangedChannels, group 4: 0x8F46 & ~0x8F48
MidiChanged_ProcessGroup4_Data:
	.short 0x0001
	.long CtrlPanel_SyncBit0_From8F5C
	.short 0x0002
	.long CtrlPanel_SetBit3_OnStyleD0D3
	.short 0xffff	; end of list
	.long 0xffffffff
	; MidiChannel_DispatchChanged, group 1: 0x8F3C
MidiChannel_DispatchChanged_Data:
	.short 0xffff	; end of list
	.long 0xffffffff
	; MidiChannel_DispatchChanged, group 2: 0x8F40
MidiDispatch_CheckGroup2_Data:
	.short 0x0040
	.long CtrlPanel_SetResBit0_ViaLookup4
	.short 0x0008
	.long CtrlPanel_SetResBit0_ViaLookup4C
	.short 0x0004
	.long CtrlPanel_GuardedNibbleSet_8F4E
	.short 0xffff	; end of list
	.long 0xffffffff
	; MidiChannel_DispatchChanged, group 3: 0x8F44
MidiDispatch_CheckGroup3_Data:
	.short 0x0004
	.long CtrlPanel_SetResBit7_ViaLookup4C
	.short 0x2000
	.long CtrlPanel_SetResBit5_ViaLookup4C
	.short 0x4000
	.long CtrlPanel_SetResBit6_ViaLookup4C
	.short 0xffff	; end of list
	.long 0xffffffff
	; MidiChannel_DispatchChanged, group 4: 0x8F48
MidiDispatch_CheckGroup4_Data:
	.short 0xffff	; end of list
	.long 0xffffffff


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
; ---------------------------------------------------------------------------
; Small tables after the LED-row list, each reached through a positional name
; Protocol_values_for_LED_rows_0xNN by one routine of audio/audio_control_engine.s:
;   +0x10  6 bytes         SndParam_TableLookup_Via4100
;   +0x16  17 u16          ExtData_VoiceParam_DispatchBytecode
;   +0x38  6 bytes         MidiChOut_Mode6or3_Mask7
;   +0x3E  8 bytes         MidiChOut_OtherMode_Mask3
;   +0x46  8 u16           UIState_ProcessExtendedMode
;   +0x56  32 u32, 1 << k  CtrlPanel_LookupIndicatorEntry (a bit-mask table)
; ---------------------------------------------------------------------------
AudioCtl_SmallTables:
	.byte 4, 2, 6, 7, 5, 3
ExtData_VoiceParam_DispatchBytecode_CaseTable:
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSound - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSound - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeControl - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeMidi - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeDisk - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeEntertainer - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSeq - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSeqErec - ExtData_VoiceParam_DispatchBytecode_Code
	.short	SndParamF9A541_ResBit7_Code_Epilogue - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSeqReal - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSeq - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSeq - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeCmp - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_Code - ExtData_VoiceParam_DispatchBytecode_Code
	.short	SndParamF9A541_ResBit7_Code_Epilogue - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_ModeSndArg - ExtData_VoiceParam_DispatchBytecode_Code
	.short	ExtData_VoiceParam_DispatchBytecode_Case18 - ExtData_VoiceParam_DispatchBytecode_Code
MidiChOut_Mode6or3_Mask7_Data:
	.byte 1, 2, 4, 1, 2, 4
MidiChOut_OtherMode_Mask3_Data:
	.byte 1, 2, 4, 8, 1, 2, 4, 8
UIState_ProcessExtendedMode_CaseTable:
	.short	UIState_ProcessExtendedMode_Cases - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case1 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case1 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case3 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case4 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case5 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case5 - UIState_ProcessExtendedMode_Cases
	.short	UIState_ProcessExtendedMode_Case7 - UIState_ProcessExtendedMode_Cases
CtrlPanel_LookupIndicatorEntry_Data:
	.long 0x00000001, 0x00000002, 0x00000004, 0x00000008
	.long 0x00000010, 0x00000020, 0x00000040, 0x00000080
	.long 0x00000100, 0x00000200, 0x00000400, 0x00000800
	.long 0x00001000, 0x00002000, 0x00004000, 0x00008000
	.long 0x00010000, 0x00020000, 0x00040000, 0x00080000
	.long 0x00100000, 0x00200000, 0x00400000, 0x00800000
	.long 0x01000000, 0x02000000, 0x04000000, 0x08000000
	.long 0x10000000, 0x20000000, 0x40000000, 0x80000000
; ---------------------------------------------------------------------------
; SOUND-EFFECT PRESETS: 10 reverb, 9 EQ and 9 combined records (0xEDA6EC-0xEDAA63)
; ---------------------------------------------------------------------------
; Reached through ReverbPreset_Table / EQPreset_Table / CombinedPreset_Table
; (after SoundProgram_DispatchTable, below).  The loaders in
; audio/audio_control_engine.s copy a record to RAM and send it to the Sub
; CPU: ReverbPreset_Load (24 B to 0xFC8E, command 0x63, index 0-9),
; EQPreset_Load (24 B to 0xFCA8, command 0x64, index 0-8); the *_FindMatch
; routines compare the RAM copies against every record with Mem_Compare, and
; CombinedPreset_SearchLoop compares 0xFC8E with a combined record's first
; 24 bytes and 0xFCA8 with its second 24 -- a combined preset is one reverb
; record followed by one EQ record.  Byte 22 is 0x63 (99) in all 28 records
; (and byte 46 in the combined ones); `ext_lane_checks.py presets` checks it.
; Every EQ record starts 0x4F (the EQ algorithm) followed by four big-endian
; 16-bit values (ReverbPreset_Load's and EQPreset_Load's own headers in
; audio_control_engine.s name them); kn5000_v10_program.s still holds the
; old absolute names ReverbPreset_1..27 for records 1-27 as `.set`s.
; ---------------------------------------------------------------------------
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA65B-0xEDA66C (17 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=60% dist=7 near MidiChOut_OtherMode_Mask3_Data+7
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA675-0xEDA68D (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near CtrlPanel_LookupIndicatorEntry_Data+9
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA696-0xEDA6AE (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near CtrlPanel_LookupIndicatorEntry_Data+42
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA6B7-0xEDA6CF (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near CtrlPanel_LookupIndicatorEntry_Data+75
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA6D8-0xEDA6F8 (32 B), unreached CODE-territory, was disassembled as 21 plausible-but-dead instruction lines; per=100% dist=11 near CtrlPanel_LookupIndicatorEntry_Data+108
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA700-0xEDA710 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=6 near CtrlPanel_LookupIndicatorEntry_Data+148
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA718-0xEDA728 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+172
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA730-0xEDA740 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=7 near CtrlPanel_LookupIndicatorEntry_Data+196
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA760-0xEDA770 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+244
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA778-0xEDA788 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=7 near CtrlPanel_LookupIndicatorEntry_Data+268
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA820-0xEDA830 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=10 near CtrlPanel_LookupIndicatorEntry_Data+436
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA8B0-0xEDA8C0 (16 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=100% dist=7 near CtrlPanel_LookupIndicatorEntry_Data+580
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA8E0-0xEDA8F0 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=7 near CtrlPanel_LookupIndicatorEntry_Data+628
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA940-0xEDA950 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+724
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA970-0xEDA980 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+772
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA9A0-0xEDA9B0 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+820
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDA9D0-0xEDA9E0 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+868
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDAA00-0xEDAA10 (16 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+916
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xEDAA30-0xEDAA40 (16 B), unreached CODE-territory, was disassembled as 10 plausible-but-dead instruction lines; per=100% dist=8 near CtrlPanel_LookupIndicatorEntry_Data+964
ReverbPreset_0:
	.byte 0x11, 0x32, 0x00, 0x0c, 0x14, 0x32, 0x5d, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_1:
	.byte 0x10, 0x18, 0x00, 0x61, 0x18, 0x63, 0x5e, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_2:
	.byte 0x12, 0x02, 0x00, 0x2d, 0x0c, 0x32, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_3:
	.byte 0x14, 0x2e, 0x00, 0x1d, 0x14, 0x3a, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_4:
	.byte 0x15, 0x20, 0x00, 0x3c, 0x18, 0x50, 0x4e, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_5:
	.byte 0x16, 0x14, 0x00, 0x15, 0x18, 0x34, 0x49, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_6:
	.byte 0x18, 0x21, 0x00, 0x02, 0x00, 0x60, 0x4f, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_7:
	.byte 0x19, 0x2b, 0x00, 0x1a, 0x00, 0x05, 0x3a, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_8:
	.byte 0x1a, 0x0f, 0x00, 0x11, 0x15, 0x17, 0x4f, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
ReverbPreset_9:
	.byte 0x1b, 0x3c, 0x00, 0x1a, 0x12, 0x32, 0x56, 0x12, 0x54, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_0:
	.byte 0x4f, 0x02, 0x1c, 0x03, 0x97, 0x04, 0xd5, 0x05, 0xa2, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_1:
	.byte 0x4f, 0x01, 0xd8, 0x02, 0x84, 0x04, 0xc4, 0x06, 0x58, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_2:
	.byte 0x4f, 0x02, 0x43, 0x03, 0x2a, 0x04, 0x29, 0x04, 0xc0, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_3:
	.byte 0x4f, 0x00, 0xce, 0x03, 0x98, 0x05, 0x18, 0x05, 0x68, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_4:
	.byte 0x4f, 0x00, 0x1c, 0x02, 0x54, 0x03, 0x14, 0x04, 0x02, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_5:
	.byte 0x4f, 0x01, 0xd8, 0x03, 0x98, 0x05, 0x02, 0x05, 0xd8, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_6:
	.byte 0x4f, 0x00, 0x12, 0x01, 0xa8, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_7:
	.byte 0x4f, 0x01, 0xc0, 0x03, 0x98, 0x05, 0x18, 0x06, 0x54, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
EQPreset_8:
	.byte 0x4f, 0x01, 0x1d, 0x04, 0xea, 0x05, 0xf0, 0x06, 0xb0, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_0:
	.byte 0x14, 0x36, 0x00, 0x0b, 0x14, 0x32, 0x4a, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0x1b, 0x02, 0x8e, 0x03, 0x58, 0x04, 0x0f, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_1:
	.byte 0x10, 0x02, 0x00, 0x35, 0x00, 0x54, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0x11, 0x02, 0x83, 0x03, 0x4c, 0x05, 0xe8, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_2:
	.byte 0x10, 0x1c, 0x00, 0x56, 0x00, 0x52, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x02, 0x58, 0x03, 0x18, 0x03, 0xe8, 0x05, 0x0c, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_3:
	.byte 0x12, 0x23, 0x00, 0x31, 0x0c, 0x32, 0x4e, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0x98, 0x02, 0x4b, 0x03, 0xca, 0x05, 0x10, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_4:
	.byte 0x16, 0x2d, 0x00, 0x3a, 0x0c, 0x32, 0x52, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0x98, 0x02, 0x58, 0x04, 0x21, 0x05, 0x22, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_5:
	.byte 0x18, 0x29, 0x00, 0x19, 0x14, 0x32, 0x4a, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0xd8, 0x03, 0x98, 0x04, 0x18, 0x04, 0x8e, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_6:
	.byte 0x19, 0x13, 0x00, 0x12, 0x0a, 0x57, 0x3f, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x01, 0xd8, 0x03, 0x8b, 0x04, 0x5e, 0x05, 0xd8, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_7:
	.byte 0x1b, 0x34, 0x00, 0x59, 0x12, 0x32, 0x4f, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x02, 0x8b, 0x03, 0x92, 0x05, 0x22, 0x05, 0xd1, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
CombinedPreset_8:
	.byte 0x11, 0x23, 0x00, 0x47, 0x14, 0x32, 0x69, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x4f, 0x02, 0x53, 0x02, 0x83, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00
; ---------------------------------------------------------------------------
; SoundProgram_DispatchTable -- 256 handler pointers, one per value of a
; command byte
; ---------------------------------------------------------------------------
; Reader: FileIO_OperationDispatch (audio/audio_control_engine.s, 0xFC84EA)
; walks a byte stream whose base pointer is at RAM 0xC039 and whose cursor
; word is at 0x9133, until the byte at the cursor is 0xFF.  For each 3-byte
; record SndParam_FetchSequencerParams (0xFC8E03) moves byte 0 to RAM 0x9127
; (the command), byte 1 to 0x9128/0x912F and byte 2 to 0x9130; the
; dispatcher then does `ld a, (0x9127)` / `sla wa, 2` / `lda xbc,
; (SoundProgram_DispatchTable)` / `ld r, (xrr+rr)` / `call (xhl)`.
; Entries: 0x00-0x19 ExtData_ToneParam_DispatchHandler; 0x43-0x48, 0x60,
; 0x68, 0x70, 0x72, 0x7A, 0x90, 0x98, 0xA8 and 0xB0 their own handlers;
; 0xB1-0xBD the MidiCh_Iterate* volume / expression / pan loops; every other
; entry is a bare `ret` -- ToshiCmd_DefaultHandler_Ret (0xFC8E02), or for
; 0x20-0x3F FileIO_AllocBuffer (0xFC7F71), which is also a one-byte `ret`
; (0x0E) whatever its name says.  The table and handler names are
; historical; what the command stream encodes beyond this is not traced
; here.  The three tables after it (+0x400, +0x800, +0x880) are indexed by
; the same command byte, or by channel -- see their headers.
; ---------------------------------------------------------------------------
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
; SoundProgram_DispatchTable + 0x400 (PanelTlv_PayloadByTag in
; shared/positional_labels.s): 256 RAM addresses, indexed by the SAME command
; byte.  PanelTlv_PayloadOfTag (audio/audio_control_engine.s, 0xFC9DF4)
; does `sla wa, 2` / `lda xbc, (+0x400)` / `ld r, (xrr+rr)`, and
; SndParam_FetchSequencerParams stores the result at RAM 0x912B next to the
; command byte it fetched; Audio_InitAllDefaults (0xFC747E) stores this
; table's address at RAM 0x90F2.
; 0xFFFFFFFF = no RAM block for that command.  The live entries are 26 bytes
; apart (0xF9B6, 0xF9D0, ...) -- the same spacing as the RAM-bank table
; sndparam_types.h describes.
; (2026-10-06) This is the panel TLV stream's tag -> payload table (docs/kn-disk-file-formats.md, "The
; record container"): entry T = the RAM address of record T's payload.  Renamed from
; Audio_InitAllDefaults_Data; shared/positional_labels.s holds no entry for it.
PanelTlv_PayloadByTag:
	.long 0x0000f9b6, 0x0000f9d0, 0x0000f9ea, 0x0000fa04, 0x0000fa1e, 0x0000fa38, 0x0000fa52, 0x0000fa6c	; [0x00]
	.long 0x0000fa86, 0x0000faa0, 0x0000faba, 0x0000fad4, 0x0000faee, 0x0000fb08, 0x0000fb22, 0x0000fb3c	; [0x08]
	.long 0x0000fb56, 0x0000fb70, 0x0000fb8a, 0x0000fba4, 0x0000fbbe, 0x0000fbd8, 0x0000fbf2, 0x0000fd62	; [0x10]
	.long 0x0000fd7c, 0x0000fc0c, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x18]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x20]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x28]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x30]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x38]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0x0000fc54, 0x0000fc26, 0x0000fc32, 0x0000fc3e, 0x0000fc4a	; [0x40]
	.long 0x0000fc5a, 0x0000ff92, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x48]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x50]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x58]
	.long 0x0000fc6e, 0x0000fc74, 0xffffffff, 0x0000fc8e, 0x0000fca8, 0x0000fcc2, 0x0000fcdc, 0xffffffff	; [0x60]
	.long 0x0000fcf6, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x68]
	.long 0x0000fd02, 0x0000fd2c, 0x0000fd0c, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x70]
	.long 0x0000f9a2, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x78]
	.long 0x0000fd50, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x80]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x88]
	.long 0x0000fc66, 0x0000fdaa, 0x0000fd1c, 0x0000fdb6, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x90]
	.long 0x0000fd96, 0x0000fd30, 0x0000ffa4, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x98]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xa0]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xa8]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xb0]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xb8]
	.long 0x0000fdda, 0x0000fdee, 0x0000fe02, 0x0000fe16, 0x0000fe2a, 0x0000fe3e, 0x0000fe52, 0x0000fe66	; [0xc0]
	.long 0x0000fe7a, 0x0000fe8e, 0x0000fea2, 0x0000feb6, 0x0000feca, 0x0000fede, 0x0000fef2, 0x0000ff06	; [0xc8]
	.long 0x0000ff1a, 0x0000ff2e, 0x0000ff42, 0x0000ff56, 0x0000ff6a, 0x0000ff1a, 0x0000ff56, 0x0000ff7e	; [0xd0]
	.long 0x0000ff7e, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xd8]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xe0]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xe8]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xf0]
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0xf8]
; SoundProgram_DispatchTable + 0x800 (..._0x800): 32 RAM addresses, one per
; channel 0-31: PanelTlv_CompanionOfPart (0xFC9639) does `cp a, 0x1f` /
; `jr ugt` / `sla wa, 2` / `lda xbc, (+0x800)` / `ld r, (xrr+rr)`;
; Audio_InitAllDefaults stores the table's address at RAM 0x9182.
; (2026-10-06) Entry T = the payload of part T's companion record, tag 0xC0 + T (parts 0x15 and 0x16 share
; 0x10's and 0x13's; docs/kn-disk-file-formats.md, "The C0..D4 run is one companion block PER PART").
; Renamed from Audio_InitAllDefaults_Data_2.
PanelTlv_CompanionByPart:
	.long 0x0000fdda, 0x0000fdee, 0x0000fe02, 0x0000fe16, 0x0000fe2a, 0x0000fe3e, 0x0000fe52, 0x0000fe66	; [0x00]
	.long 0x0000fe7a, 0x0000fe8e, 0x0000fea2, 0x0000feb6, 0x0000feca, 0x0000fede, 0x0000fef2, 0x0000ff06	; [0x08]
	.long 0x0000ff1a, 0x0000ff2e, 0x0000ff42, 0x0000ff56, 0x0000ff6a, 0x0000ff1a, 0x0000ff56, 0x0000ff7e	; [0x10]
	.long 0x0000ff7e, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff	; [0x18]
; SoundProgram_DispatchTable + 0x880: four audio (re)initialisation routines.
; midi/midi_dispatch_handlers.s calls the third through it (`ld xhl,
; (MidiSysEx_ProcessBlock_Data:24)` / `call (xhl)`), and entry 6 of
; SystemConfig_PointerTable (ui_widgets/widget_dispatch.s) points at the
; table's head under the `.set` name SoundProgram_ParamPtrTable
; (kn5000_v10_program.s).  Searched for other readers: the positional names
; SoundProgram_ParamPtrTable..0x88C and the literals 0xEDB2E4-0xEDB2F3.
SoundProgram_ParamPtrTable:
	.long Audio_InitAllDefaults
	.long Audio_ReinitToneGenAndOutput
MidiSysEx_ProcessBlock_Data:
	.long Audio_ResetAfterPayloadError
	.long Audio_FullReinitWithPreset
; SoundProgram_DispatchTable + 0x890..+0x907: seven small tables, each read
; through its positional name SoundProgram_DispatchTable_0xNNN by the routine
; named with it (all in audio/audio_control_engine.s).
; ---------------------------------------------------------------------------
; The three preset pointer tables (records: see the header above the records)
; ---------------------------------------------------------------------------
; ReverbPreset_Table: 10 pointers; ReverbPreset_Load and SoundPreset_FindMatch
; (audio/audio_control_engine.s) index it as ReverbPreset_Table.
; Naka_ToshiParam_Table sits ONE ENTRY INTO it, which is how the tree had
; it; the label stays because positional names are built on it:
; EQPreset_Table is EQPreset_Table (9 pointers, EQPreset_Load /
; EQPreset_FindMatch) and CombinedPreset_Table is CombinedPreset_Table
; (9 pointers, CombinedPreset_Load / CombinedPreset_SearchLoop).
; ---------------------------------------------------------------------------
	; +0x890: one 6-byte record.  BitmapTable_ProcessEntry (0xFC7A6A) takes
	; index*6 and reads +0 with `cpw (xwa), 0x50`, +2 (at +0x892) as a
	; command byte for PanelTlv_PayloadOfTag, and +3, +4, +5.
BitmapTable_ProcessEntry_Data:
	.short 0x0050
BitmapTable_ProcessEntry_Data_2:
	.byte 0x43, 0x01, 0x3c, 0x7f
	; +0x896: 12 jump offsets.  ExtData_ToneParam_DispatchHandler (0xFC7D77):
	; `cp wa, 11` / `add wa, wa` / `ld wa, (xix+wa)` / `jp_rr` from 0xFC8570
	; (no label there in audio_control_engine.s, so the offsets are numeric).
ExtData_ToneParam_DispatchHandler_CaseTable:
	.short	ExtData_ToneParam_DispatchHandler_Code - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case1 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case1 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case3 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case4 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case5 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case6 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case7 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case8 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case9 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case10 - ExtData_ToneParam_DispatchHandler_Code
	.short	ExtData_ToneParam_DispatchHandler_Case11 - ExtData_ToneParam_DispatchHandler_Code
	; +0x8AE: 9 jump offsets, ExtData_ToneParam_AltDispatch (0xFC7F9F), from 0xFC8793.
ExtData_ToneParam_AltDispatch_CaseTable:
	.short	ExtData_ToneParam_AltDispatch_Code - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarNibbleFields - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarNibbleFields - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarFootages - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarFootages - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarFootages - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_DrawbarFootages - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_Drawbar1FootAndSwitches - ExtData_ToneParam_AltDispatch_Code
	.short	ExtData_ToneParam_AltDispatch_Code - ExtData_ToneParam_AltDispatch_Code
	; +0x8C0: 9 jump offsets, ExtData_ToneParam_AltBody (0xFC8009), from 0xFC87FD.
ExtData_ToneParam_AltBody_CaseTable:
	.short	ExtData_ToneParam_AltBody_Code - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case1 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case1 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case3 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case4 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case5 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case5 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case7 - ExtData_ToneParam_AltBody_Code
	.short	ExtData_ToneParam_AltBody_Case8 - ExtData_ToneParam_AltBody_Code
	; +0x8D2: 4 bytes, indexed by a value & 3 in ExtData_ToneParam_MultiChannel.
ExtData_ToneParam_MultiChannel_Data:
	.byte 1, 1, 2, 3
	; +0x8D6: 4 bytes, indexed by (RAM 0xFD02) & 3 in ExtData_Voice_MixedHandler.
ExtData_Voice_MixedHandler_Data:
	.byte 0, 1, 2, 4
	; +0x8DA: 26 bytes, 0..24 then 0xFF, read by CtrlPanel_BuildIndicatorBitmask (0xFC8A7E).
CtrlPanel_BuildIndicatorBitmask_Data:
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	.byte 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 0xff
	; +0x8F4: 20 bytes, a channel remap read with `ld a, (xrr+rr)` by
	; VoiceChannels_InitPanFromPreset; its result goes to PanelTlv_PayloadOfTag.
VoiceChannels_InitPanFromPreset_Data:
	.byte 0, 2, 1, 7, 8, 9, 10, 11, 4, 5, 6, 3, 15, 21, 21, 25, 20, 12, 13, 14
ReverbPreset_Table:
	.long ReverbPreset_0
Naka_ToshiParam_Table:
	.long ReverbPreset_1
	.long ReverbPreset_2
	.long ReverbPreset_3
	.long ReverbPreset_4
	.long ReverbPreset_5
	.long ReverbPreset_6
	.long ReverbPreset_7
	.long ReverbPreset_8
	.long ReverbPreset_9
EQPreset_Table:
	.long EQPreset_0
	.long EQPreset_1
	.long EQPreset_2
	.long EQPreset_3
	.long EQPreset_4
	.long EQPreset_5
	.long EQPreset_6
	.long EQPreset_7
	.long EQPreset_8
CombinedPreset_Table:
	.long CombinedPreset_0
	.long CombinedPreset_1
	.long CombinedPreset_2
	.long CombinedPreset_3
	.long CombinedPreset_4
	.long CombinedPreset_5
	.long CombinedPreset_6
	.long CombinedPreset_7
	.long CombinedPreset_8
; Naka_ToshiParam_Table + 0x6C: 32 bytes DataBuf_InitSlotFromPreset
; (midi/midi_dispatch_handlers.s) copies to offset 0x2E0 of a data slot
; (slot 0: RAM 0xF180 + 0x2E0; slot n: 0xAB000 + (n-1) * 0x800 + 0x2E0).
DataSlot_HeaderTemplate:
	.byte 0x5a, 0x5a, 0x00, 0x00, 0x48, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; ---------------------------------------------------------------------------
; Naka_ToshiParam_Table + 0x8C: DEFAULT IMAGE OF RAM 0xF9A0-0xFDA1 (1,026 B)
; ---------------------------------------------------------------------------
; DataBuf_InitSlotFromPreset copies 0xFDA2 - 0xF9A0 bytes from here (it
; pushes the address as `pushw 0xed` / `pushw 0xb3fc`) to a slot; the
; audio_control_engine.s loaders copy parts of it (0x7C bytes, then 0x11E
; from +0x7C) with 0xF9A0 as the destination base, and
; SMF_SlotChain (sequencer/smf_config_routines.s) indexes into it.  RAM
; 0xF9B6 + 26k are the blocks SoundProgram_DispatchTable + 0x400 points at,
; so the rows below are the 22-byte head (0xF9A0) and then 26-byte blocks,
; each tagged with its RAM address.
; ---------------------------------------------------------------------------
SndParamRam_DefaultImage:
	.byte 0x78, 0x12, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00, 0x18	; 0xF9A0
	.byte 0x00, 0x00, 0x00, 0x7f, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x38, 0x00, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x01, 0x00, 0x01, 0x18	; 0xF9B6
	.byte 0x38, 0x00, 0x00, 0x7f, 0x35, 0x00, 0x00, 0x5a, 0x50, 0x40, 0x80, 0x02, 0x38, 0x01, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x01, 0x00, 0x02, 0x18	; 0xF9D0
	.byte 0x06, 0x00, 0x00, 0x71, 0x45, 0x00, 0x00, 0x5a, 0x30, 0x40, 0x80, 0x02, 0x00, 0x02, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x03, 0x18	; 0xF9EA
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x03, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x04, 0x18	; 0xFA04
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x04, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x05, 0x18	; 0xFA1E
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x05, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x06, 0x18	; 0xFA38
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x06, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x07, 0x18	; 0xFA52
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x07, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x08, 0x18	; 0xFA6C
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x08, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x09, 0x18	; 0xFA86
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x09, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0a, 0x18	; 0xFAA0
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0a, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0b, 0x18	; 0xFABA
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0b, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0c, 0x18	; 0xFAD4
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0c, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0d, 0x18	; 0xFAEE
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0d, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0e, 0x18	; 0xFB08
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0e, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0f, 0x18	; 0xFB22
	.byte 0xf0, 0x00, 0x00, 0x64, 0x25, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0x0f, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x10, 0x18	; 0xFB3C
	.byte 0x06, 0x00, 0x00, 0x71, 0x55, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc4, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x11, 0x18	; 0xFB56
	.byte 0x1a, 0x00, 0x00, 0x71, 0x55, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc8, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x12, 0x18	; 0xFB70
	.byte 0x64, 0x00, 0x00, 0x71, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc9, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x13, 0x18	; 0xFB8A
	.byte 0x28, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc2, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x14, 0x18	; 0xFBA4
	.byte 0xf0, 0x00, 0x00, 0x76, 0x05, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xce, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x15, 0x18	; 0xFBBE
	.byte 0x06, 0x00, 0x00, 0x71, 0x45, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc4, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x16, 0x18	; 0xFBD8
	.byte 0x28, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc0, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x19, 0x18	; 0xFBF2
	.byte 0x00, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xcf, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x44, 0x0a	; 0xFC0C
	.byte 0x00, 0x00, 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x45, 0x0a, 0x00, 0x00, 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x46, 0x0a, 0x00, 0x00	; 0xFC26
	.byte 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x47, 0x08, 0xff, 0x00, 0x00, 0x00, 0xc0, 0x00, 0xff, 0xff, 0x43, 0x04, 0x80, 0x3c, 0x00, 0x00, 0x48, 0x0a	; 0xFC40
	.byte 0x60, 0x02, 0x00, 0xe8, 0x00, 0x00, 0x00, 0x00, 0x78, 0x00, 0x90, 0x06, 0x01, 0x00, 0x67, 0x00, 0x40, 0x00, 0x60, 0x04, 0x00, 0x80, 0x00, 0x00, 0x61, 0x18	; 0xFC5A
	.byte 0x01, 0x1e, 0x06, 0x00, 0x54, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x63, 0x18	; 0xFC74
	.byte 0x14, 0x23, 0x00, 0x0b, 0x14, 0x32, 0x46, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x64, 0x18	; 0xFC8E
	.byte 0x4f, 0x01, 0xd8, 0x03, 0x98, 0x05, 0x18, 0x05, 0xd8, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x65, 0x18	; 0xFCA8
	.byte 0x39, 0x32, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x66, 0x18	; 0xFCC2
	.byte 0x58, 0x23, 0x03, 0x9c, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x68, 0x0a	; 0xFCDC
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x70, 0x08, 0x06, 0x3c, 0x05, 0xff, 0x07, 0x02, 0x04, 0x07, 0x72, 0x0e, 0x00, 0x00, 0x00, 0x76	; 0xFCF6
	.byte 0x00, 0x00, 0x00, 0x5a, 0x1d, 0x45, 0x1d, 0x33, 0x00, 0x00, 0x92, 0x0e, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80	; 0xFD10
	.byte 0x71, 0x02, 0x00, 0x00, 0x99, 0x1e, 0x00, 0x00, 0xb6, 0x00, 0x40, 0x96, 0x88, 0x90, 0x91, 0xb3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x82, 0x01, 0x02, 0x81	; 0xFD2A
	.byte 0x00, 0x10, 0x11, 0x12, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x0e, 0x00, 0x0c, 0x04, 0x45, 0x00, 0x20, 0xfa, 0xdf, 0xbf, 0x01, 0x00, 0x00, 0x50, 0x00	; 0xFD44
	.byte 0xff, 0xff, 0x17, 0x18, 0x00, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc0, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00	; 0xFD5E
	.byte 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x76, 0x05, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc1, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00	; 0xFD78
	.byte 0x00, 0x00, 0x98, 0x12, 0x40, 0x00, 0x00, 0x20, 0x76, 0x00, 0x00, 0x20, 0x5c, 0x01, 0x5a, 0x00	; 0xFD92
; 0xEDB7FE-0xEDBA2B (558 B, 468 of them zero) follow the image directly.
; Readers below.  Searched: positional names on Naka_ToshiParam_Table and
; SoundProgram_DispatchTable landing here, 16/24-bit literals in the .s/.c
; sources, and every even address here as a u32 anywhere in the ROM.  It
; may be the image continued past 0xFDA1 and copied by a path with its own
; base; that is a guess.
; Readers (claims_lint.py unread-claims, 2026-10-02): Display_CopyAndRenderBitmaps (0xFC7A28, pushw
;   far pointer)
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x91, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x93, 0x22, 0x06, 0x06, 0x7f, 0x7f, 0x02, 0x05, 0x94, 0x00, 0xff, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3f, 0x3f, 0xff
	.byte 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0xc0, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc1, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc2, 0x12
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xc3, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc4, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc5, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0x12
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xc7, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc9, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xca, 0x12
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xcb, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcc, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xcd, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xce, 0x12
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xcf, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd0, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd1, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd2, 0x12
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xd3, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd4, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xd7, 0x12, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x49, 0x10
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x9a, 0x1a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff
Display_CopyAndRenderBitmaps_Str_HK:	.byte	0x48, 0x4b
	.byte 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x03, 0x50
; Naka_ToshiParam_Table + 0x6BC / 0x6C8 / 0x6CC: three templates the
; audio/sndparam_routines.s code copies with ldirw / ldiw:
;   +0x6BC 12 zero bytes -> RAM 0x96D4 (SndParam_ResetDefaultTable, which
;          then writes 0xFFFF at 0x96D4);
;   +0x6C8 4 zero bytes, the first two words of a new registration
;          (SndParam_RegisterEntry_Data);
;   +0x6CC {u32 0x00FFFFFF, u32 0}: one EMPTY 8-byte hash slot, stamped over
;          the whole {key, record pointer} table at RAM 0x34100 by
;          SndParam_InitHashFillLoop.
SndParam_ResetDefaultTable_Data:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
SndParam_RW_Fail_Data:
	.byte 0x00, 0x00, 0x00, 0x00
SndParam_InitHashFillLoop_Data:
	.long SNDPARAM_HASH_EMPTY_KEY, 0x00000000
; ---------------------------------------------------------------------------
; sndparam_descriptor -- ONE 18-byte sound-parameter descriptor
; ---------------------------------------------------------------------------
; The same record as struct sndparam_descriptor_t in
; v10/maincpu/audio/sndparam_records/sndparam_types.h, field for field and in
; the same order; that header cites, per field, the SndParam_* accessor
; instruction in v10's audio/sndparam_routines.s that reads it.  v10 compiles
; 951 of the 974 records from C; this macro writes the rest -- the 20 records
; in this file the C generator refused because they share a source line with
; a value map -- and, in the v9 and v7 copies of this file, every record
; (the Makefile compiles the C for v10 only).
;
;   +0x00 key (u32, byte +3 always 0)   +0x04 bank_index   +0x05 bank_offset
;   +0x06 mask   +0x07 clamp_min   +0x08 clamp_max   +0x09 shift (low nibble)
;   +0x0A xor_value   +0x0B aux_index (0xff = none)   +0x0C read_accessor
;   +0x0D register_accessor   +0x0E lookup2_accessor   +0x0F codec
;   +0x10 write_accessor   +0x11 unknown_0x11 (sndparam_types.h: read by no
;   instruction of the 0xFCD200-0xFCF000 accessors)
.macro sndparam_descriptor key, bank_index, bank_offset, mask, clamp_min, clamp_max, shift, xor_value, aux_index, read_acc, register_acc, lookup2_acc, codec, write_acc, unknown_0x11
	.long \key
	.byte \bank_index, \bank_offset, \mask, \clamp_min, \clamp_max, \shift, \xor_value, \aux_index
	.byte \read_acc, \register_acc, \lookup2_acc, \codec, \write_acc, \unknown_0x11
.endm
	; WidgetParam_TestMode_Entry (a `.set` in kn5000_v10_program.s names this record)
WidgetParam_TestMode_Entry:
	sndparam_descriptor 0x000000, 145, 0, 0xff, 0, 255, 0, 0x00, 0x00, 1, 7, 5, 0, 0, 0xff
; ---------------------------------------------------------------------------
; VALUE MAPS AND THEIR 10-BYTE DESCRIPTORS (11 of them, 0xEDBA56-0xEDE9FB)
; ---------------------------------------------------------------------------
; The eleven descriptors are the entries of the pointer table at 0xEE0154 in
; ui_widgets/widget_dispatch.s (SndParam_LinkTargetPtrs there, then
; Naka_SubDispatch_A_Table).  The accessors in audio/sndparam_routines.s that
; load that address (`lda xbc, (SndParam_LinkTargetPtrs:24)`, two sites)
; take a record's +0x0B aux_index: 0xFF selects entry 0, anything else is
; `sla a, 2` / `ld xiy, (xbc+a)`; the descriptor is then read at +0x00
; and `ld wa, (xix+7)`.  Descriptor layout, uniform in all 11:
;   +0x00 u32 pointer to the byte map      +0x04 u16 number of map entries
;   +0x06 u8 (0, 128, 255 or 7)             +0x07 u16, UNALIGNED
;   +0x09 u8, always 0xFF
; +0x07 (read by the accessor above) is 0 in six descriptors; in three --
; this one (38 of 78), the PitchBend map (3) and the DspEffect map (5) -- it
; is the index of the map's 0x00 entry; in the Sustain (100 of 201) and Pan
; (8 of 14) maps it is not.  Each map is `count` bytes, most followed by a
; 0xFF.  Names: the
; WidgetParam_MidiCC_* labels are historical (address bucketing, not a
; reader); SndParamValueMap_0 / SndParamValueDesc_0 are entry 0, which no
; older label covered.  scripts/analysis/ext_lane_checks.py vmaps re-checks
; the layout.
; ---------------------------------------------------------------------------
SndParamValueMap_0:
	.byte 0xc0, 0xc1, 0xc3, 0xc4, 0xc6, 0xc8, 0xca, 0xcb, 0xcd, 0xcf, 0xd0, 0xd2, 0xd4, 0xd6, 0xd7, 0xd9
	.byte 0xdb, 0xdc, 0xde, 0xe0, 0xe2, 0xe3, 0xe5, 0xe7, 0xe8, 0xea, 0xec, 0xed, 0xef, 0xf1, 0xf3, 0xf4
	.byte 0xf6, 0xf8, 0xf9, 0xfb, 0xfd, 0xfe, 0x00, 0x02, 0x03, 0x05, 0x07, 0x08, 0x0a, 0x0c, 0x0d, 0x0f
	.byte 0x11, 0x12, 0x14, 0x16, 0x17, 0x19, 0x1b, 0x1c, 0x1e, 0x20, 0x21, 0x23, 0x25, 0x26, 0x28, 0x2a
	.byte 0x2b, 0x2d, 0x2f, 0x30, 0x32, 0x33, 0x35, 0x37, 0x38, 0x3a, 0x3c, 0x3d, 0x3e, 0x3f
SndParamValueDesc_0:
	.long SndParamValueMap_0
	.short 78
	.byte 0x00, 0x26, 0x00, 0xff
	; WidgetParam_SineWave_Entry (a `.set` in kn5000_v10_program.s names this record)
WidgetParam_SineWave_Entry:
	sndparam_descriptor 0x000001, 72, 5, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
;  22 x 18-byte sound-parameter descriptors, 0xEDBAC0-0xEDBC4C, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edbac0.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDBAC0:
	sndparam_descriptor 0x000003, 112, 2, 0xff, 0, 11, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
	sndparam_descriptor 0x000004, 72, 8, 0xff, 40, 255, 0, 0x00, 0x00, 6, 8, 6, 2, 0, 0xff
	sndparam_descriptor 0x000005, 72, 9, 0x01, 0, 1, 0, 0x00, 0x00, 6, 8, 6, 2, 0, 0xff
	sndparam_descriptor 0x0000c0, 145, 3, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0000c1, 145, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000100, 147, 0, 0x0f, 0, 9, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000102, 147, 5, 0xff, 1, 10, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000103, 147, 6, 0x7f, 1, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000104, 147, 6, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000300, 152, 1, 0x7f, 0, 80, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000301, 152, 1, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000302, 152, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000400, 152, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x000401, 152, 3, 0x70, 1, 3, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002100, 128, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002101, 128, 3, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002181, 128, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002182, 128, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002183, 128, 3, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002184, 128, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002200, 128, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002201, 128, 0, 0x03, 0, 3, 0, 0x00, 0x01, 1, 7, 5, 0, 0, 0xff
.set VoiceCtrlR1_Entry_001, SndParamRun_EDBAC0 + 0
.set VoiceCtrlR1_Entry_002, SndParamRun_EDBAC0 + 18
.set VoiceCtrlR1_Entry_003, SndParamRun_EDBAC0 + 36
.set VoiceCtrlR1_Entry_004, SndParamRun_EDBAC0 + 54
.set VoiceCtrlR1_Entry_005, SndParamRun_EDBAC0 + 72
.set VoiceCtrlR1_Entry_006, SndParamRun_EDBAC0 + 90
.set VoiceCtrlR1_Entry_007, SndParamRun_EDBAC0 + 108
.set VoiceCtrlR1_Entry_008, SndParamRun_EDBAC0 + 126
.set VoiceCtrlR1_Entry_009, SndParamRun_EDBAC0 + 144
.set VoiceCtrlR1_Entry_010, SndParamRun_EDBAC0 + 162
.set VoiceCtrlR1_Entry_011, SndParamRun_EDBAC0 + 180
.set VoiceCtrlR1_Entry_012, SndParamRun_EDBAC0 + 198
.set VoiceCtrlR1_Entry_013, SndParamRun_EDBAC0 + 216
.set VoiceCtrlR1_Entry_014, SndParamRun_EDBAC0 + 234
.set VoiceCtrlR1_Entry_015, SndParamRun_EDBAC0 + 252
.set VoiceCtrlR1_Entry_016, SndParamRun_EDBAC0 + 270
.set VoiceCtrlR1_Entry_017, SndParamRun_EDBAC0 + 288
.set VoiceCtrlR1_Entry_018, SndParamRun_EDBAC0 + 306
.set VoiceCtrlR1_Entry_019, SndParamRun_EDBAC0 + 324
.set VoiceCtrlR1_Entry_020, SndParamRun_EDBAC0 + 342
.set VoiceCtrlR1_Entry_021, SndParamRun_EDBAC0 + 360
.set VoiceCtrlR1_Entry_022, SndParamRun_EDBAC0 + 378
VoiceCtrlR1_Entry_023:
	.byte 0x00, 0x01, 0x03
	.byte 0xff
WidgetParam_MidiCC_Program:
	.long VoiceCtrlR1_Entry_023
	.short 3
	.byte 0x00, 0x00, 0x00, 0xff
VoiceCtrlR1_Entry_024:
	sndparam_descriptor 0x002202, 128, 0, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_025:
	sndparam_descriptor 0x002203, 128, 0, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
VoiceCtrlR1_Entry_026:
	sndparam_descriptor 0x002205, 128, 2, 0x18, 0, 3, 3, 0x00, 0x03, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_BankSelect_Map:
	.byte 0x00, 0x01, 0x03
	.byte 0xff
WidgetParam_MidiCC_BankSelect:
	.long WidgetParam_MidiCC_BankSelect_Map
	.short 3
	.byte 0x00, 0x00, 0x00, 0xff
;  78 x 18-byte sound-parameter descriptors, 0xEDBC9E-0xEDC21A, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edbc9e.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDBC9E:
	sndparam_descriptor 0x002280, 128, 1, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002281, 128, 2, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002282, 128, 6, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228a, 128, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228b, 128, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228c, 128, 7, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228d, 128, 8, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228e, 128, 8, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00228f, 128, 8, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002290, 128, 8, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002291, 128, 8, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002294, 128, 8, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002295, 128, 8, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002296, 128, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002298, 128, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002299, 128, 9, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00229a, 128, 1, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002880, 153, 2, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002882, 153, 1, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002881, 153, 3, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002886, 153, 4, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002887, 153, 0, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002888, 153, 5, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002889, 153, 0, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288a, 153, 6, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288b, 153, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288c, 153, 7, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288d, 153, 0, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288e, 153, 8, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00288f, 153, 0, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002890, 153, 9, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002891, 153, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002892, 153, 10, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002893, 153, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002894, 153, 11, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002895, 153, 0, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002896, 153, 12, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002897, 153, 1, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002898, 153, 13, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002899, 153, 1, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00289a, 153, 14, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00289b, 153, 1, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00289c, 153, 15, 0xff, 0, 199, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00289d, 153, 1, 0x08, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002900, 152, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002901, 152, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002902, 152, 7, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002903, 152, 7, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002904, 152, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002905, 152, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002906, 152, 7, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002907, 152, 7, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002908, 152, 8, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002909, 152, 8, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290a, 152, 8, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290b, 152, 8, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290c, 152, 8, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290d, 152, 8, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290e, 152, 8, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00290f, 152, 8, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002910, 152, 9, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002911, 152, 9, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002a00, 112, 5, 0xff, 1, 16, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002a01, 112, 6, 0xff, 1, 16, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002a10, 112, 7, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002a11, 112, 7, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002a12, 112, 7, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002c00, 152, 14, 0x03, 0, 2, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d00, 71, 1, 0x1f, 0, 17, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d01, 71, 0, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d02, 71, 2, 0x7f, 0, 99, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d03, 71, 0, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d04, 71, 3, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d05, 71, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d06, 71, 3, 0xf0, 0, 11, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d07, 71, 0, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d08, 71, 4, 0xc0, 0, 3, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d09, 71, 0, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
.set VoiceCtrlR1_Entry_027, SndParamRun_EDBC9E + 0
.set VoiceCtrlR1_Entry_028, SndParamRun_EDBC9E + 18
.set VoiceCtrlR1_Entry_029, SndParamRun_EDBC9E + 36
.set VoiceCtrlR1_Entry_030, SndParamRun_EDBC9E + 54
.set VoiceCtrlR1_Entry_031, SndParamRun_EDBC9E + 72
.set VoiceCtrlR1_Entry_032, SndParamRun_EDBC9E + 90
.set VoiceCtrlR1_Entry_033, SndParamRun_EDBC9E + 108
.set VoiceCtrlR1_Entry_034, SndParamRun_EDBC9E + 126
.set VoiceCtrlR1_Entry_035, SndParamRun_EDBC9E + 144
.set VoiceCtrlR1_Entry_036, SndParamRun_EDBC9E + 162
.set VoiceCtrlR1_Entry_037, SndParamRun_EDBC9E + 180
.set VoiceCtrlR1_Entry_038, SndParamRun_EDBC9E + 198
.set VoiceCtrlR1_Entry_039, SndParamRun_EDBC9E + 216
.set VoiceCtrlR1_Entry_040, SndParamRun_EDBC9E + 234
.set VoiceCtrlR1_Entry_041, SndParamRun_EDBC9E + 252
.set VoiceCtrlR1_Entry_042, SndParamRun_EDBC9E + 270
.set VoiceCtrlR1_Entry_043, SndParamRun_EDBC9E + 288
.set VoiceCtrlR1_Entry_044, SndParamRun_EDBC9E + 306
.set VoiceCtrlR1_Entry_045, SndParamRun_EDBC9E + 324
.set VoiceCtrlR1_Entry_046, SndParamRun_EDBC9E + 342
.set VoiceCtrlR1_Entry_047, SndParamRun_EDBC9E + 360
.set VoiceCtrlR1_Entry_048, SndParamRun_EDBC9E + 378
.set VoiceCtrlR1_Entry_049, SndParamRun_EDBC9E + 396
.set VoiceCtrlR1_Entry_050, SndParamRun_EDBC9E + 414
.set VoiceCtrlR1_Entry_051, SndParamRun_EDBC9E + 432
.set VoiceCtrlR1_Entry_052, SndParamRun_EDBC9E + 450
.set VoiceCtrlR1_Entry_053, SndParamRun_EDBC9E + 468
.set VoiceCtrlR1_Entry_054, SndParamRun_EDBC9E + 486
.set VoiceCtrlR1_Entry_055, SndParamRun_EDBC9E + 504
.set VoiceCtrlR1_Entry_056, SndParamRun_EDBC9E + 522
.set VoiceCtrlR1_Entry_057, SndParamRun_EDBC9E + 540
.set VoiceCtrlR1_Entry_058, SndParamRun_EDBC9E + 558
.set VoiceCtrlR1_Entry_059, SndParamRun_EDBC9E + 576
.set VoiceCtrlR1_Entry_060, SndParamRun_EDBC9E + 594
.set VoiceCtrlR1_Entry_061, SndParamRun_EDBC9E + 612
.set VoiceCtrlR1_Entry_062, SndParamRun_EDBC9E + 630
.set VoiceCtrlR1_Entry_063, SndParamRun_EDBC9E + 648
.set VoiceCtrlR1_Entry_064, SndParamRun_EDBC9E + 666
.set VoiceCtrlR1_Entry_065, SndParamRun_EDBC9E + 684
.set VoiceCtrlR1_Entry_066, SndParamRun_EDBC9E + 702
.set VoiceCtrlR1_Entry_067, SndParamRun_EDBC9E + 720
.set VoiceCtrlR1_Entry_068, SndParamRun_EDBC9E + 738
.set VoiceCtrlR1_Entry_069, SndParamRun_EDBC9E + 756
.set VoiceCtrlR1_Entry_070, SndParamRun_EDBC9E + 774
.set VoiceCtrlR1_Entry_071, SndParamRun_EDBC9E + 792
.set VoiceCtrlR1_Entry_072, SndParamRun_EDBC9E + 810
.set VoiceCtrlR1_Entry_073, SndParamRun_EDBC9E + 828
.set VoiceCtrlR1_Entry_074, SndParamRun_EDBC9E + 846
.set VoiceCtrlR1_Entry_075, SndParamRun_EDBC9E + 864
.set MidiChParam_Entry_001, SndParamRun_EDBC9E + 882
.set MidiChParam_Entry_002, SndParamRun_EDBC9E + 900
.set MidiChParam_Entry_003, SndParamRun_EDBC9E + 918
.set MidiChParam_Entry_004, SndParamRun_EDBC9E + 936
.set MidiChParam_Entry_005, SndParamRun_EDBC9E + 954
.set MidiChParam_Entry_006, SndParamRun_EDBC9E + 972
.set MidiChParam_Entry_007, SndParamRun_EDBC9E + 990
.set MidiChParam_Entry_008, SndParamRun_EDBC9E + 1008
.set MidiChParam_Entry_009, SndParamRun_EDBC9E + 1026
.set MidiChParam_Entry_010, SndParamRun_EDBC9E + 1044
.set MidiChParam_Entry_011, SndParamRun_EDBC9E + 1062
.set MidiChParam_Entry_012, SndParamRun_EDBC9E + 1080
.set MidiChParam_Entry_013, SndParamRun_EDBC9E + 1098
.set MidiChParam_Entry_014, SndParamRun_EDBC9E + 1116
.set MidiChParam_Entry_015, SndParamRun_EDBC9E + 1134
.set MidiChParam_Entry_016, SndParamRun_EDBC9E + 1152
.set MidiChParam_Entry_017, SndParamRun_EDBC9E + 1170
.set MidiChParam_Entry_018, SndParamRun_EDBC9E + 1188
.set MidiChParam_Entry_019, SndParamRun_EDBC9E + 1206
.set MidiChParam_Entry_020, SndParamRun_EDBC9E + 1224
.set MidiChParam_Entry_021, SndParamRun_EDBC9E + 1242
.set MidiChParam_Entry_022, SndParamRun_EDBC9E + 1260
.set MidiChParam_Entry_023, SndParamRun_EDBC9E + 1278
.set MidiChParam_Entry_024, SndParamRun_EDBC9E + 1296
.set MidiChParam_Entry_025, SndParamRun_EDBC9E + 1314
.set MidiChParam_Entry_026, SndParamRun_EDBC9E + 1332
.set MidiChParam_Entry_027, SndParamRun_EDBC9E + 1350
.set MidiChParam_Entry_028, SndParamRun_EDBC9E + 1368
.set MidiChParam_Entry_029, SndParamRun_EDBC9E + 1386
MidiChParam_Entry_030:
	sndparam_descriptor 0x002d0a, 71, 5, 0x7f, 0, 121, 0, 0x00, 0x0a, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_NameEdit_Map:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c
	.byte 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c
	.byte 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c
	.byte 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c
	.byte 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c
	.byte 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79
	.byte 0xff
WidgetParam_MidiCC_NameEdit:
	.long WidgetParam_MidiCC_NameEdit_Map
	.short 109
	.byte 0x00, 0x00, 0x00, 0xff
;  22 x 18-byte sound-parameter descriptors, 0xEDC2A4-0xEDC430, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc2a4.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDC2A4:
	sndparam_descriptor 0x002d0b, 71, 0, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d0c, 71, 6, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d0d, 71, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d0e, 71, 6, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d0f, 71, 0, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d10, 71, 7, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d11, 71, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d12, 71, 7, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x002d13, 71, 0, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004000, 176, 0, 0x7f, 0, 127, 0, 0x00, 0x01, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x004001, 176, 1, 0x7f, 0, 127, 0, 0x00, 0x00, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x004002, 96, 1, 0x80, 0, 127, 7, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x004003, 112, 0, 0x04, 0, 1, 2, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004004, 96, 1, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004005, 176, 3, 0x7f, 0, 127, 0, 0x00, 0x00, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x004006, 96, 1, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004080, 152, 2, 0x80, 0, 1, 7, 0x00, 0xff, 1, 2, 2, 0, 0, 0xff
	sndparam_descriptor 0x004081, 152, 2, 0x40, 0, 1, 6, 0x00, 0xff, 1, 2, 2, 0, 0, 0xff
	sndparam_descriptor 0x0040c0, 152, 11, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0040c1, 152, 11, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0040e0, 144, 4, 0xff, 40, 88, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
	sndparam_descriptor 0x004100, 144, 0, 0x1f, 0, 5, 0, 0x00, 0x00, 4, 5, 4, 0, 0, 0xff
.set MidiChParam_Entry_031, SndParamRun_EDC2A4 + 0
.set MidiChParam_Entry_032, SndParamRun_EDC2A4 + 18
.set MidiChParam_Entry_033, SndParamRun_EDC2A4 + 36
.set MidiChParam_Entry_034, SndParamRun_EDC2A4 + 54
.set MidiChParam_Entry_035, SndParamRun_EDC2A4 + 72
.set MidiChParam_Entry_036, SndParamRun_EDC2A4 + 90
.set MidiChParam_Entry_037, SndParamRun_EDC2A4 + 108
.set MidiChParam_Entry_038, SndParamRun_EDC2A4 + 126
.set MidiChParam_Entry_039, SndParamRun_EDC2A4 + 144
.set MidiChParam_Entry_040, SndParamRun_EDC2A4 + 162
.set MidiChParam_Entry_041, SndParamRun_EDC2A4 + 180
.set MidiChParam_Entry_042, SndParamRun_EDC2A4 + 198
.set MidiChParam_Entry_043, SndParamRun_EDC2A4 + 216
.set MidiChParam_Entry_044, SndParamRun_EDC2A4 + 234
.set MidiChParam_Entry_045, SndParamRun_EDC2A4 + 252
.set MidiChParam_Entry_046, SndParamRun_EDC2A4 + 270
.set MidiChParam_Entry_047, SndParamRun_EDC2A4 + 288
.set MidiChParam_Entry_048, SndParamRun_EDC2A4 + 306
.set MidiChParam_Entry_049, SndParamRun_EDC2A4 + 324
.set MidiChParam_Entry_050, SndParamRun_EDC2A4 + 342
.set MidiChParam_Entry_051, SndParamRun_EDC2A4 + 360
.set MidiChParam_Entry_052, SndParamRun_EDC2A4 + 378
WidgetParam_MidiCC_SysExcl:
	.byte 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x03, 0x02, 0x01, 0x02, 0x02, 0x02
MidiChParam_Entry_053:
	sndparam_descriptor 0x004140, 67, 0, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_054:
	sndparam_descriptor 0x004141, 67, 1, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_055:
	sndparam_descriptor 0x004142, 67, 1, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_056:
	sndparam_descriptor 0x004180, 112, 0, 0x03, 0, 3, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_057:
	sndparam_descriptor 0x004181, 112, 1, 0x7f, 21, 108, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_058:
	sndparam_descriptor 0x004200, 72, 4, 0x40, 0, 1, 6, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_059:
	sndparam_descriptor 0x004201, 112, 3, 0xff, 0, 255, 0, 0x00, 0x06, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_Volume_Map:
	.byte 0xff, 0x00, 0x01, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e
	.byte 0xff
WidgetParam_MidiCC_Volume:
	.long WidgetParam_MidiCC_Volume_Map
	.short 15
	.byte 0xff, 0x00, 0x00, 0xff
MidiChParam_Entry_060:
	sndparam_descriptor 0x004202, 112, 4, 0x0f, 0, 13, 0, 0x00, 0x08, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_Pan_Map:
	.byte 0x00, 0x01, 0x02, 0x0d, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c
WidgetParam_MidiCC_Pan:
	.long WidgetParam_MidiCC_Pan_Map
	.short 14
	.byte 0x07, 0x08, 0x00, 0xff
MidiChParam_Entry_061:
	sndparam_descriptor 0x004280, 146, 1, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_062:
	sndparam_descriptor 0x004281, 146, 0, 0xff, 0, 128, 0, 0x00, 0x04, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_Expression_Map:
	.byte 0x00, 0x40, 0x41, 0x42, 0x03, 0x04, 0x05, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x80
	.byte 0xff
WidgetParam_MidiCC_Expression:
	.long WidgetParam_MidiCC_Expression_Map
	.short 15
	.byte 0x00, 0x00, 0x00, 0xff
MidiChParam_Entry_063:
	sndparam_descriptor 0x004282, 146, 1, 0x0f, 0, 11, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
MidiChParam_Entry_064:
	sndparam_descriptor 0x004283, 146, 2, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_Sustain_Map:
	.byte 0x00, 0x01, 0x03, 0x04, 0x05, 0x07, 0x08, 0x09, 0x0a, 0x0c, 0x0d, 0x0e, 0x0f, 0x11, 0x12, 0x13
	.byte 0x15, 0x16, 0x17, 0x18, 0x1a, 0x1b, 0x1c, 0x1d, 0x1f, 0x20, 0x21, 0x23, 0x24, 0x25, 0x26, 0x28
	.byte 0x29, 0x2a, 0x2b, 0x2d, 0x2e, 0x2f, 0x31, 0x32, 0x33, 0x34, 0x36, 0x37, 0x38, 0x39, 0x3b, 0x3c
	.byte 0x3d, 0x3f, 0x40, 0x41, 0x42, 0x44, 0x45, 0x46, 0x47, 0x49, 0x4a, 0x4b, 0x4d, 0x4e, 0x4f, 0x50
	.byte 0x52, 0x53, 0x54, 0x55, 0x57, 0x58, 0x59, 0x5b, 0x5c, 0x5d, 0x5e, 0x60, 0x61, 0x62, 0x63, 0x65
	.byte 0x66, 0x67, 0x69, 0x6a, 0x6b, 0x6c, 0x6e, 0x6f, 0x70, 0x71, 0x73, 0x74, 0x75, 0x77, 0x78, 0x79
	.byte 0x7a, 0x7c, 0x7d, 0x7e, 0x80, 0x81, 0x82, 0x83, 0x85, 0x86, 0x87, 0x88, 0x8a, 0x8b, 0x8c, 0x8e
	.byte 0x8f, 0x90, 0x91, 0x93, 0x94, 0x95, 0x96, 0x98, 0x99, 0x9a, 0x9c, 0x9d, 0x9e, 0x9f, 0xa1, 0xa2
	.byte 0xa3, 0xa4, 0xa6, 0xa7, 0xa8, 0xaa, 0xab, 0xac, 0xad, 0xaf, 0xb0, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6
	.byte 0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3, 0xc4, 0xc6, 0xc7, 0xc8, 0xc9, 0xcb
	.byte 0xcc, 0xcd, 0xce, 0xd0, 0xd1, 0xd2, 0xd4, 0xd5, 0xd6, 0xd7, 0xd9, 0xda, 0xdb, 0xdc, 0xde, 0xdf
	.byte 0xe0, 0xe2, 0xe3, 0xe4, 0xe5, 0xe7, 0xe8, 0xe9, 0xea, 0xec, 0xed, 0xee, 0xf0, 0xf1, 0xf2, 0xf3
	.byte 0xf5, 0xf6, 0xf7, 0xf8, 0xfa, 0xfb, 0xfc, 0xfe, 0xff
	.byte 0xff
WidgetParam_MidiCC_Sustain:
	.long WidgetParam_MidiCC_Sustain_Map
	.short 201
	.byte 0x80, 0x64, 0x00, 0xff
;  19 x 18-byte sound-parameter descriptors, 0xEDC634-0xEDC78A, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc634.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDC634:
	sndparam_descriptor 0x004284, 146, 3, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004285, 146, 4, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004286, 146, 5, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004287, 146, 6, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004288, 146, 7, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004289, 146, 8, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x00428a, 146, 9, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x00428b, 146, 10, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x00428c, 146, 11, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x00428d, 146, 12, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x00428e, 146, 13, 0xff, 0, 255, 0, 0x00, 0x05, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x004900, 97, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004a00, 98, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004b00, 99, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004c00, 100, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004d00, 101, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x004e00, 102, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x005000, 128, 10, 0x03, 0, 2, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x005001, 128, 11, 0xff, 0, 255, 0, 0x00, 0x07, 1, 7, 5, 0, 0, 0xff
.set MidiChParam_Entry_065, SndParamRun_EDC634 + 0
.set MidiChParam_Entry_066, SndParamRun_EDC634 + 18
.set MidiChParam_Entry_067, SndParamRun_EDC634 + 36
.set MidiChParam_Entry_068, SndParamRun_EDC634 + 54
.set MidiChParam_Entry_069, SndParamRun_EDC634 + 72
.set MidiChParam_Entry_070, SndParamRun_EDC634 + 90
.set MidiChParam_Entry_071, SndParamRun_EDC634 + 108
.set MidiChParam_Entry_072, SndParamRun_EDC634 + 126
.set MidiChParam_Entry_073, SndParamRun_EDC634 + 144
.set MidiChParam_Entry_074, SndParamRun_EDC634 + 162
.set MidiChParam_Entry_075, SndParamRun_EDC634 + 180
.set MidiChParam_Entry_076, SndParamRun_EDC634 + 198
.set MidiChParam_Entry_077, SndParamRun_EDC634 + 216
.set MidiChParam_Entry_078, SndParamRun_EDC634 + 234
.set MidiChParam_Entry_079, SndParamRun_EDC634 + 252
.set MidiChParam_Entry_080, SndParamRun_EDC634 + 270
.set MidiChParam_Entry_081, SndParamRun_EDC634 + 288
.set MidiChParam_Entry_082, SndParamRun_EDC634 + 306
.set MidiChParam_Entry_083, SndParamRun_EDC634 + 324
MidiChParam_Entry_084:
	.byte 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd
	.byte 0xde, 0xdf, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed
	.byte 0xee, 0xef, 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd
	.byte 0xfe, 0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d
	.byte 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d
	.byte 0x2e, 0x2f, 0x30, 0x31, 0x32
	.byte 0xff
WidgetParam_MidiCC_Reverb:
	.long MidiChParam_Entry_084
	.short 101
	.byte 0x00, 0x00, 0x00, 0xff
;  9 x 18-byte sound-parameter descriptors, 0xEDC7FA-0xEDC89C, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc7fa.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDC7FA:
	sndparam_descriptor 0x005002, 128, 12, 0xff, 1, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008000, 0, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008001, 178, 0, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008007, 0, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008008, 0, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00800a, 0, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00800b, 179, 0, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008020, 0, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008040, 0, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
.set MidiChParam_Entry_085, SndParamRun_EDC7FA + 0
.set SndParam_Part00_Sound, SndParamRun_EDC7FA + 18
.set SndParam_Part00_Modulation, SndParamRun_EDC7FA + 36
.set SndParam_Part00_Volume, SndParamRun_EDC7FA + 54
.set SndParam_Part00_Mute, SndParamRun_EDC7FA + 72
.set SndParam_Part00_Pan, SndParamRun_EDC7FA + 90
.set SndParam_Part00_Expression, SndParamRun_EDC7FA + 108
.set SndParam_Part00_Bank, SndParamRun_EDC7FA + 126
.set SndParam_Part00_Sustain, SndParamRun_EDC7FA + 144
WidgetParam_MidiCC_Chorus:
	.byte 0x40, 0x00, 0x01, 0x00, 0x7f, 0x00, 0x01, 0xff
;  10 x 18-byte sound-parameter descriptors, 0xEDC8A4-0xEDC958, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc8a4.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDC8A4:
	sndparam_descriptor 0x00805b, 0, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00805d, 0, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00805e, 0, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x008078, 174, 0, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008080, 0, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008081, 0, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008082, 0, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0081b0, 177, 0, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0081b2, 180, 0, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008221, 68, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
.set SndParam_Part00_ReverbSend, SndParamRun_EDC8A4 + 0
.set SndParam_Part00_DspEffect, SndParamRun_EDC8A4 + 18
.set SndParam_Part00_DigitalEffect, SndParamRun_EDC8A4 + 36
.set MidiChParam_Entry_097, SndParamRun_EDC8A4 + 54
.set SndParam_Part00_BendRange, SndParamRun_EDC8A4 + 72
.set SndParam_Part00_Tuning, SndParamRun_EDC8A4 + 90
.set SndParam_Part00_KeyShift, SndParamRun_EDC8A4 + 108
.set MidiChParam_Entry_101, SndParamRun_EDC8A4 + 126
.set MidiChParam_Entry_102, SndParamRun_EDC8A4 + 144
.set MidiChParam_Entry_103, SndParamRun_EDC8A4 + 162
MidiChParam_Entry_104:
	sndparam_descriptor 0x0082cc, 68, 1, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_DspEffect_Map:
	.byte 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05
	.byte 0xff
WidgetParam_MidiCC_DspEffect:
	.long WidgetParam_MidiCC_DspEffect_Map
	.short 11
	.byte 0x00, 0x05, 0x00, 0xff
;  460 x 18-byte sound-parameter descriptors, 0xEDC980-0xEDE9D8, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_edc980.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDC980:
	sndparam_descriptor 0x0082cb, 68, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008293, 68, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008294, 68, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008280, 68, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008281, 68, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008282, 68, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008283, 68, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008284, 68, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008285, 68, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008286, 68, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008287, 68, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008288, 68, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0082c0, 68, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0082c1, 68, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008400, 1, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008401, 178, 1, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008407, 1, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008408, 1, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00840a, 1, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00840b, 179, 1, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008420, 1, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008440, 1, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00845b, 1, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00845d, 1, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00845e, 1, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x008478, 174, 1, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008480, 1, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008481, 1, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008482, 1, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0085b0, 177, 1, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0085b2, 180, 1, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008621, 69, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0086cc, 69, 1, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x0086cb, 69, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008693, 69, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008694, 69, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008680, 69, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008681, 69, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008682, 69, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008683, 69, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008684, 69, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008685, 69, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008686, 69, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008687, 69, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008688, 69, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0086c0, 69, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0086c1, 69, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008800, 2, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008801, 178, 2, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008807, 2, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008808, 2, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00880a, 2, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00880b, 179, 2, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008820, 2, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008840, 2, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00885b, 2, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00885d, 2, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00885e, 2, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x008878, 174, 2, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008880, 2, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008881, 2, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008882, 2, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0089b0, 177, 2, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0089b2, 180, 2, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008a21, 70, 8, 0x0f, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008acc, 70, 1, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008acb, 70, 1, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008a93, 70, 2, 0x0f, 0, 15, 0, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008a94, 70, 2, 0xf0, 0, 15, 4, 0x00, 0x09, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x008a80, 70, 3, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a81, 70, 3, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a82, 70, 4, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a83, 70, 4, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a84, 70, 5, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a85, 70, 5, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a86, 70, 6, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a87, 70, 6, 0xf0, 0, 8, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008a88, 70, 7, 0x0f, 0, 8, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008ac0, 70, 7, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008ac1, 70, 7, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c00, 3, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c01, 178, 3, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008c07, 3, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c08, 3, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c0a, 3, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c0b, 179, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008c20, 3, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c40, 3, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x008c5b, 3, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c5d, 3, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c5e, 3, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x008c78, 174, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008c80, 3, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c81, 3, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008c82, 3, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x008db0, 177, 3, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x008db2, 180, 3, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009000, 4, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009001, 178, 4, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009007, 4, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009008, 4, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00900a, 4, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00900b, 179, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009020, 4, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009040, 4, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00905b, 4, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00905d, 4, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00905e, 4, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x009078, 174, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009080, 4, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009081, 4, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009082, 4, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0091b0, 177, 4, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0091b2, 180, 4, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009400, 5, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009401, 178, 5, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009407, 5, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009408, 5, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00940a, 5, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00940b, 179, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009420, 5, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009440, 5, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00945b, 5, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00945d, 5, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00945e, 5, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x009478, 174, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009480, 5, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009481, 5, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009482, 5, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0095b0, 177, 5, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0095b2, 180, 5, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009800, 6, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009801, 178, 6, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009807, 6, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009808, 6, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00980a, 6, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00980b, 179, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009820, 6, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009840, 6, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00985b, 6, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00985d, 6, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00985e, 6, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x009878, 174, 6, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009880, 6, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009881, 6, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009882, 6, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x0099b0, 177, 6, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x0099b2, 180, 6, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009c00, 7, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c01, 178, 7, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009c07, 7, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c08, 7, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c0a, 7, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c0b, 179, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009c20, 7, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c40, 7, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x009c5b, 7, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c5d, 7, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c5e, 7, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x009c78, 174, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009c80, 7, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c81, 7, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009c82, 7, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x009db0, 177, 7, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x009db2, 180, 7, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a000, 8, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a001, 178, 8, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a007, 8, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a008, 8, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a00a, 8, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a00b, 179, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a020, 8, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a040, 8, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a05b, 8, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a05d, 8, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a05e, 8, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a078, 174, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a080, 8, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a081, 8, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a082, 8, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a1b0, 177, 8, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a1b2, 180, 8, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a400, 9, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a401, 178, 9, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a407, 9, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a408, 9, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a40a, 9, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a40b, 179, 9, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a420, 9, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a440, 9, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a45b, 9, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a45d, 9, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a45e, 9, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a478, 174, 9, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a480, 9, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a481, 9, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a482, 9, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a5b0, 177, 9, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a5b2, 180, 9, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a800, 10, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a801, 178, 10, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a807, 10, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a808, 10, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a80a, 10, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a80b, 179, 10, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a820, 10, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a840, 10, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a85b, 10, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a85d, 10, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a85e, 10, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00a878, 174, 10, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a880, 10, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a881, 10, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a882, 10, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00a9b0, 177, 10, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00a9b2, 180, 10, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00ac00, 11, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac01, 178, 11, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00ac07, 11, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac08, 11, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac0a, 11, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac0b, 179, 11, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00ac20, 11, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac40, 11, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00ac5b, 11, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac5d, 11, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac5e, 11, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00ac78, 174, 11, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00ac80, 11, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac81, 11, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ac82, 11, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00adb0, 177, 11, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00adb2, 180, 11, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b000, 12, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b001, 178, 12, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b007, 12, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b008, 12, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b00a, 12, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b00b, 179, 12, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b020, 12, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b040, 12, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b05b, 12, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b05d, 12, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b05e, 12, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b078, 174, 12, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b080, 12, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b081, 12, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b082, 12, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b1b0, 177, 12, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b1b2, 180, 12, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b400, 13, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b401, 178, 13, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b407, 13, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b408, 13, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b40a, 13, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b40b, 179, 13, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b420, 13, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b440, 13, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b45b, 13, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b45d, 13, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b45e, 13, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b478, 174, 13, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b480, 13, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b481, 13, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b482, 13, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b5b0, 177, 13, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b5b2, 180, 13, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b800, 14, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b801, 178, 14, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b807, 14, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b808, 14, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b80a, 14, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b80b, 179, 14, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b820, 14, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b840, 14, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b85b, 14, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b85d, 14, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b85e, 14, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00b878, 174, 14, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b880, 14, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b881, 14, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b882, 14, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00b9b0, 177, 14, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00b9b2, 180, 14, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00bc00, 15, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc01, 178, 15, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00bc07, 15, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc08, 15, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc0a, 15, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc0b, 179, 15, 0x7f, 0, 127, 0, 0x00, 0xff, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00bc20, 15, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc40, 15, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00bc5b, 15, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc5d, 15, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc5e, 15, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00bc78, 174, 15, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00bc80, 15, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc81, 15, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bc82, 15, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00bdb0, 177, 15, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00bdb2, 180, 15, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c000, 16, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00c001, 178, 16, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00c007, 16, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c008, 16, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c00a, 16, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c00b, 179, 16, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c020, 16, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00c040, 16, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c05b, 16, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c05d, 16, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c05e, 16, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c078, 174, 16, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c080, 16, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c081, 16, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c082, 16, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c1b0, 177, 16, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00c1b2, 180, 16, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c400, 17, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00c401, 178, 17, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00c407, 17, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c408, 17, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c40a, 17, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c40b, 179, 17, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c420, 17, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00c440, 17, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c45b, 17, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c45d, 17, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c45e, 17, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c478, 174, 17, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c480, 17, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c481, 17, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c482, 17, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c5b0, 177, 17, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00c5b2, 180, 17, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c800, 18, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00c801, 178, 18, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00c807, 18, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c808, 18, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c80a, 18, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c80b, 179, 18, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00c820, 18, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00c840, 18, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c85b, 18, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c85d, 18, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c85e, 18, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00c878, 174, 18, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00c880, 18, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c881, 18, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c882, 18, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00c9b0, 177, 18, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00c9b2, 180, 18, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00cc00, 19, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00cc01, 178, 19, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00cc07, 19, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc08, 19, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc0a, 19, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00cc0b, 179, 19, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00cc20, 19, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00cc40, 19, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00cc5b, 19, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc5d, 19, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc5e, 19, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00cc78, 174, 19, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00cc80, 19, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc81, 19, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cc82, 19, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00cdb0, 177, 19, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00cdb2, 180, 19, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d000, 20, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d001, 178, 20, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00d007, 20, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d008, 20, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d00a, 20, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00d00b, 179, 20, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00d020, 20, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d040, 20, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00d05b, 20, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d05d, 20, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d05e, 20, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00d078, 174, 20, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d080, 20, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d081, 20, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d082, 20, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d1b0, 177, 20, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00d1b2, 180, 20, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d400, 21, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d401, 178, 21, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d407, 21, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d408, 21, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d40a, 21, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00d40b, 179, 21, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d420, 21, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d440, 21, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00d45b, 21, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d45d, 21, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d45e, 21, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00d478, 174, 21, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d480, 21, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d481, 21, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d482, 21, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d5b0, 177, 21, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d5b2, 180, 21, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d800, 22, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d801, 178, 22, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d807, 22, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d808, 22, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d80a, 22, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00d80b, 179, 22, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d820, 22, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d840, 22, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00d85b, 22, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d85d, 22, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d85e, 22, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 0, 0xff
	sndparam_descriptor 0x00d878, 174, 22, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d880, 22, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d881, 22, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d882, 22, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00d9b0, 177, 22, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00d9b2, 180, 22, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00dc00, 23, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00dc01, 178, 23, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00dc07, 23, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc08, 23, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc0a, 23, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00dc0b, 179, 23, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00dc20, 23, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00dc40, 23, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00dc5b, 23, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc5d, 23, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc5e, 23, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00dc78, 174, 23, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00dc80, 23, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc81, 23, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00dc82, 23, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00ddb0, 177, 23, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00ddb2, 180, 23, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00e000, 24, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 5, 0xff
	sndparam_descriptor 0x00e001, 178, 24, 0x7f, 0, 127, 0, 0x00, 0x03, 2, 3, 0, 0, 1, 0xff
	sndparam_descriptor 0x00e007, 24, 3, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e008, 24, 3, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e00a, 24, 8, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00e00b, 179, 24, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 1, 0xff
	sndparam_descriptor 0x00e020, 24, 1, 0x7f, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 4, 0xff
	sndparam_descriptor 0x00e040, 24, 4, 0x08, 0, 127, 3, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00e05b, 24, 7, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e05d, 24, 5, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e05e, 24, 4, 0x40, 0, 127, 6, 0x00, 0x00, 3, 4, 3, 1, 2, 0xff
	sndparam_descriptor 0x00e078, 174, 24, 0x7f, 0, 127, 0, 0x00, 0xff, 0, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00e080, 24, 11, 0x7f, 0, 12, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e081, 24, 10, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e082, 24, 9, 0x7f, 52, 76, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e1b0, 177, 24, 0x7f, 0, 127, 0, 0x00, 0x02, 2, 3, 0, 0, 3, 0xff
	sndparam_descriptor 0x00e1b2, 180, 24, 0x7f, 0, 127, 0, 0x00, 0x04, 2, 3, 0, 0, 0, 0xff
	sndparam_descriptor 0x00e807, 152, 4, 0x7f, 0, 127, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x00e808, 152, 4, 0x80, 0, 1, 7, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018000, 0, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018001, 0, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018002, 0, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018003, 0, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
.set MidiChParam_Entry_105, SndParamRun_EDC980 + 0
.set MidiChParam_Entry_106, SndParamRun_EDC980 + 18
.set MidiChParam_Entry_107, SndParamRun_EDC980 + 36
.set SndParam_Part00_Drawbar16, SndParamRun_EDC980 + 54
.set SndParam_Part00_Drawbar8, SndParamRun_EDC980 + 72
.set SndParam_Part00_Drawbar5_1_3, SndParamRun_EDC980 + 90
.set SndParam_Part00_Drawbar4, SndParamRun_EDC980 + 108
.set SndParam_Part00_Drawbar2_2_3, SndParamRun_EDC980 + 126
.set SndParam_Part00_Drawbar2, SndParamRun_EDC980 + 144
.set SndParam_Part00_Drawbar1_3_5, SndParamRun_EDC980 + 162
.set SndParam_Part00_Drawbar1_1_3, SndParamRun_EDC980 + 180
.set SndParam_Part00_Drawbar1, SndParamRun_EDC980 + 198
.set VoiceParamEx_Entry_005, SndParamRun_EDC980 + 216
.set VoiceParamEx_Entry_006, SndParamRun_EDC980 + 234
.set SndParam_Part01_Sound, SndParamRun_EDC980 + 252
.set SndParam_Part01_Modulation, SndParamRun_EDC980 + 270
.set SndParam_Part01_Volume, SndParamRun_EDC980 + 288
.set SndParam_Part01_Mute, SndParamRun_EDC980 + 306
.set SndParam_Part01_Pan, SndParamRun_EDC980 + 324
.set SndParam_Part01_Expression, SndParamRun_EDC980 + 342
.set SndParam_Part01_Bank, SndParamRun_EDC980 + 360
.set SndParam_Part01_Sustain, SndParamRun_EDC980 + 378
.set SndParam_Part01_ReverbSend, SndParamRun_EDC980 + 396
.set SndParam_Part01_DspEffect, SndParamRun_EDC980 + 414
.set SndParam_Part01_DigitalEffect, SndParamRun_EDC980 + 432
.set VoiceParamEx_Entry_018, SndParamRun_EDC980 + 450
.set SndParam_Part01_BendRange, SndParamRun_EDC980 + 468
.set SndParam_Part01_Tuning, SndParamRun_EDC980 + 486
.set SndParam_Part01_KeyShift, SndParamRun_EDC980 + 504
.set VoiceParamEx_Entry_022, SndParamRun_EDC980 + 522
.set VoiceParamEx_Entry_023, SndParamRun_EDC980 + 540
.set VoiceParamEx_Entry_024, SndParamRun_EDC980 + 558
.set VoiceParamEx_Entry_025, SndParamRun_EDC980 + 576
.set VoiceParamEx_Entry_026, SndParamRun_EDC980 + 594
.set VoiceParamEx_Entry_027, SndParamRun_EDC980 + 612
.set VoiceParamEx_Entry_028, SndParamRun_EDC980 + 630
.set SndParam_Part01_Drawbar16, SndParamRun_EDC980 + 648
.set SndParam_Part01_Drawbar8, SndParamRun_EDC980 + 666
.set SndParam_Part01_Drawbar5_1_3, SndParamRun_EDC980 + 684
.set SndParam_Part01_Drawbar4, SndParamRun_EDC980 + 702
.set SndParam_Part01_Drawbar2_2_3, SndParamRun_EDC980 + 720
.set SndParam_Part01_Drawbar2, SndParamRun_EDC980 + 738
.set SndParam_Part01_Drawbar1_3_5, SndParamRun_EDC980 + 756
.set SndParam_Part01_Drawbar1_1_3, SndParamRun_EDC980 + 774
.set SndParam_Part01_Drawbar1, SndParamRun_EDC980 + 792
.set VoiceParamEx_Entry_038, SndParamRun_EDC980 + 810
.set VoiceParamEx_Entry_039, SndParamRun_EDC980 + 828
.set SndParam_Part02_Sound, SndParamRun_EDC980 + 846
.set SndParam_Part02_Modulation, SndParamRun_EDC980 + 864
.set SndParam_Part02_Volume, SndParamRun_EDC980 + 882
.set SndParam_Part02_Mute, SndParamRun_EDC980 + 900
.set SndParam_Part02_Pan, SndParamRun_EDC980 + 918
.set SndParam_Part02_Expression, SndParamRun_EDC980 + 936
.set SndParam_Part02_Bank, SndParamRun_EDC980 + 954
.set SndParam_Part02_Sustain, SndParamRun_EDC980 + 972
.set SndParam_Part02_ReverbSend, SndParamRun_EDC980 + 990
.set SndParam_Part02_DspEffect, SndParamRun_EDC980 + 1008
.set SndParam_Part02_DigitalEffect, SndParamRun_EDC980 + 1026
.set VoiceParamEx_Entry_051, SndParamRun_EDC980 + 1044
.set SndParam_Part02_BendRange, SndParamRun_EDC980 + 1062
.set SndParam_Part02_Tuning, SndParamRun_EDC980 + 1080
.set SndParam_Part02_KeyShift, SndParamRun_EDC980 + 1098
.set VoiceParamEx_Entry_055, SndParamRun_EDC980 + 1116
.set VoiceParamEx_Entry_056, SndParamRun_EDC980 + 1134
.set VoiceParamEx_Entry_057, SndParamRun_EDC980 + 1152
.set VoiceParamEx_Entry_058, SndParamRun_EDC980 + 1170
.set VoiceParamEx_Entry_059, SndParamRun_EDC980 + 1188
.set VoiceParamEx_Entry_060, SndParamRun_EDC980 + 1206
.set VoiceParamEx_Entry_061, SndParamRun_EDC980 + 1224
.set SndParam_Part02_Drawbar16, SndParamRun_EDC980 + 1242
.set SndParam_Part02_Drawbar8, SndParamRun_EDC980 + 1260
.set SndParam_Part02_Drawbar5_1_3, SndParamRun_EDC980 + 1278
.set SndParam_Part02_Drawbar4, SndParamRun_EDC980 + 1296
.set SndParam_Part02_Drawbar2_2_3, SndParamRun_EDC980 + 1314
.set SndParam_Part02_Drawbar2, SndParamRun_EDC980 + 1332
.set SndParam_Part02_Drawbar1_3_5, SndParamRun_EDC980 + 1350
.set SndParam_Part02_Drawbar1_1_3, SndParamRun_EDC980 + 1368
.set SndParam_Part02_Drawbar1, SndParamRun_EDC980 + 1386
.set VoiceParamEx_Entry_071, SndParamRun_EDC980 + 1404
.set VoiceParamEx_Entry_072, SndParamRun_EDC980 + 1422
.set SndParam_Part03_Sound, SndParamRun_EDC980 + 1440
.set SndParam_Part03_Modulation, SndParamRun_EDC980 + 1458
.set SndParam_Part03_Volume, SndParamRun_EDC980 + 1476
.set SndParam_Part03_Mute, SndParamRun_EDC980 + 1494
.set SndParam_Part03_Pan, SndParamRun_EDC980 + 1512
.set SndParam_Part03_Expression, SndParamRun_EDC980 + 1530
.set SndParam_Part03_Bank, SndParamRun_EDC980 + 1548
.set SndParam_Part03_Sustain, SndParamRun_EDC980 + 1566
.set SndParam_Part03_ReverbSend, SndParamRun_EDC980 + 1584
.set SndParam_Part03_DspEffect, SndParamRun_EDC980 + 1602
.set SndParam_Part03_DigitalEffect, SndParamRun_EDC980 + 1620
.set VoiceParamEx_Entry_084, SndParamRun_EDC980 + 1638
.set SndParam_Part03_BendRange, SndParamRun_EDC980 + 1656
.set SndParam_Part03_Tuning, SndParamRun_EDC980 + 1674
.set SndParam_Part03_KeyShift, SndParamRun_EDC980 + 1692
.set PartParam_Entry_003, SndParamRun_EDC980 + 1710
.set PartParam_Entry_004, SndParamRun_EDC980 + 1728
.set SndParam_Part04_Sound, SndParamRun_EDC980 + 1746
.set SndParam_Part04_Modulation, SndParamRun_EDC980 + 1764
.set SndParam_Part04_Volume, SndParamRun_EDC980 + 1782
.set SndParam_Part04_Mute, SndParamRun_EDC980 + 1800
.set SndParam_Part04_Pan, SndParamRun_EDC980 + 1818
.set SndParam_Part04_Expression, SndParamRun_EDC980 + 1836
.set SndParam_Part04_Bank, SndParamRun_EDC980 + 1854
.set SndParam_Part04_Sustain, SndParamRun_EDC980 + 1872
.set SndParam_Part04_ReverbSend, SndParamRun_EDC980 + 1890
.set SndParam_Part04_DspEffect, SndParamRun_EDC980 + 1908
.set SndParam_Part04_DigitalEffect, SndParamRun_EDC980 + 1926
.set PartParam_Entry_016, SndParamRun_EDC980 + 1944
.set SndParam_Part04_BendRange, SndParamRun_EDC980 + 1962
.set SndParam_Part04_Tuning, SndParamRun_EDC980 + 1980
.set SndParam_Part04_KeyShift, SndParamRun_EDC980 + 1998
.set PartParam_Entry_020, SndParamRun_EDC980 + 2016
.set PartParam_Entry_021, SndParamRun_EDC980 + 2034
.set SndParam_Part05_Sound, SndParamRun_EDC980 + 2052
.set SndParam_Part05_Modulation, SndParamRun_EDC980 + 2070
.set SndParam_Part05_Volume, SndParamRun_EDC980 + 2088
.set SndParam_Part05_Mute, SndParamRun_EDC980 + 2106
.set SndParam_Part05_Pan, SndParamRun_EDC980 + 2124
.set SndParam_Part05_Expression, SndParamRun_EDC980 + 2142
.set SndParam_Part05_Bank, SndParamRun_EDC980 + 2160
.set SndParam_Part05_Sustain, SndParamRun_EDC980 + 2178
.set SndParam_Part05_ReverbSend, SndParamRun_EDC980 + 2196
.set SndParam_Part05_DspEffect, SndParamRun_EDC980 + 2214
.set SndParam_Part05_DigitalEffect, SndParamRun_EDC980 + 2232
.set PartParam_Entry_033, SndParamRun_EDC980 + 2250
.set SndParam_Part05_BendRange, SndParamRun_EDC980 + 2268
.set SndParam_Part05_Tuning, SndParamRun_EDC980 + 2286
.set SndParam_Part05_KeyShift, SndParamRun_EDC980 + 2304
.set PartParam_Entry_037, SndParamRun_EDC980 + 2322
.set PartParam_Entry_038, SndParamRun_EDC980 + 2340
.set SndParam_Part06_Sound, SndParamRun_EDC980 + 2358
.set SndParam_Part06_Modulation, SndParamRun_EDC980 + 2376
.set SndParam_Part06_Volume, SndParamRun_EDC980 + 2394
.set SndParam_Part06_Mute, SndParamRun_EDC980 + 2412
.set SndParam_Part06_Pan, SndParamRun_EDC980 + 2430
.set SndParam_Part06_Expression, SndParamRun_EDC980 + 2448
.set SndParam_Part06_Bank, SndParamRun_EDC980 + 2466
.set SndParam_Part06_Sustain, SndParamRun_EDC980 + 2484
.set SndParam_Part06_ReverbSend, SndParamRun_EDC980 + 2502
.set SndParam_Part06_DspEffect, SndParamRun_EDC980 + 2520
.set SndParam_Part06_DigitalEffect, SndParamRun_EDC980 + 2538
.set PartParam_Entry_050, SndParamRun_EDC980 + 2556
.set SndParam_Part06_BendRange, SndParamRun_EDC980 + 2574
.set SndParam_Part06_Tuning, SndParamRun_EDC980 + 2592
.set SndParam_Part06_KeyShift, SndParamRun_EDC980 + 2610
.set PartParam_Entry_054, SndParamRun_EDC980 + 2628
.set PartParam_Entry_055, SndParamRun_EDC980 + 2646
.set SndParam_Part07_Sound, SndParamRun_EDC980 + 2664
.set SndParam_Part07_Modulation, SndParamRun_EDC980 + 2682
.set SndParam_Part07_Volume, SndParamRun_EDC980 + 2700
.set SndParam_Part07_Mute, SndParamRun_EDC980 + 2718
.set SndParam_Part07_Pan, SndParamRun_EDC980 + 2736
.set SndParam_Part07_Expression, SndParamRun_EDC980 + 2754
.set SndParam_Part07_Bank, SndParamRun_EDC980 + 2772
.set SndParam_Part07_Sustain, SndParamRun_EDC980 + 2790
.set SndParam_Part07_ReverbSend, SndParamRun_EDC980 + 2808
.set SndParam_Part07_DspEffect, SndParamRun_EDC980 + 2826
.set SndParam_Part07_DigitalEffect, SndParamRun_EDC980 + 2844
.set PartParam_Entry_067, SndParamRun_EDC980 + 2862
.set SndParam_Part07_BendRange, SndParamRun_EDC980 + 2880
.set SndParam_Part07_Tuning, SndParamRun_EDC980 + 2898
.set SndParam_Part07_KeyShift, SndParamRun_EDC980 + 2916
.set PartParam_Entry_071, SndParamRun_EDC980 + 2934
.set PartParam_Entry_072, SndParamRun_EDC980 + 2952
.set SndParam_Part08_Sound, SndParamRun_EDC980 + 2970
.set SndParam_Part08_Modulation, SndParamRun_EDC980 + 2988
.set SndParam_Part08_Volume, SndParamRun_EDC980 + 3006
.set SndParam_Part08_Mute, SndParamRun_EDC980 + 3024
.set SndParam_Part08_Pan, SndParamRun_EDC980 + 3042
.set SndParam_Part08_Expression, SndParamRun_EDC980 + 3060
.set SndParam_Part08_Bank, SndParamRun_EDC980 + 3078
.set SndParam_Part08_Sustain, SndParamRun_EDC980 + 3096
.set SndParam_Part08_ReverbSend, SndParamRun_EDC980 + 3114
.set SndParam_Part08_DspEffect, SndParamRun_EDC980 + 3132
.set SndParam_Part08_DigitalEffect, SndParamRun_EDC980 + 3150
.set PartParam_Entry_084, SndParamRun_EDC980 + 3168
.set SndParam_Part08_BendRange, SndParamRun_EDC980 + 3186
.set SndParam_Part08_Tuning, SndParamRun_EDC980 + 3204
.set SndParam_Part08_KeyShift, SndParamRun_EDC980 + 3222
.set PartParam_Entry_088, SndParamRun_EDC980 + 3240
.set PartParam_Entry_089, SndParamRun_EDC980 + 3258
.set SndParam_Part09_Sound, SndParamRun_EDC980 + 3276
.set SndParam_Part09_Modulation, SndParamRun_EDC980 + 3294
.set SndParam_Part09_Volume, SndParamRun_EDC980 + 3312
.set SndParam_Part09_Mute, SndParamRun_EDC980 + 3330
.set SndParam_Part09_Pan, SndParamRun_EDC980 + 3348
.set SndParam_Part09_Expression, SndParamRun_EDC980 + 3366
.set SndParam_Part09_Bank, SndParamRun_EDC980 + 3384
.set SndParam_Part09_Sustain, SndParamRun_EDC980 + 3402
.set SndParam_Part09_ReverbSend, SndParamRun_EDC980 + 3420
.set SndParam_Part09_DspEffect, SndParamRun_EDC980 + 3438
.set SndParam_Part09_DigitalEffect, SndParamRun_EDC980 + 3456
.set PartParam_Entry_101, SndParamRun_EDC980 + 3474
.set SndParam_Part09_BendRange, SndParamRun_EDC980 + 3492
.set SndParam_Part09_Tuning, SndParamRun_EDC980 + 3510
.set SndParam_Part09_KeyShift, SndParamRun_EDC980 + 3528
.set PartParam_Entry_105, SndParamRun_EDC980 + 3546
.set PartParam_Entry_106, SndParamRun_EDC980 + 3564
.set SndParam_Part0A_Sound, SndParamRun_EDC980 + 3582
.set SndParam_Part0A_Modulation, SndParamRun_EDC980 + 3600
.set SndParam_Part0A_Volume, SndParamRun_EDC980 + 3618
.set SndParam_Part0A_Mute, SndParamRun_EDC980 + 3636
.set SndParam_Part0A_Pan, SndParamRun_EDC980 + 3654
.set SndParam_Part0A_Expression, SndParamRun_EDC980 + 3672
.set SndParam_Part0A_Bank, SndParamRun_EDC980 + 3690
.set SndParam_Part0A_Sustain, SndParamRun_EDC980 + 3708
.set SndParam_Part0A_ReverbSend, SndParamRun_EDC980 + 3726
.set SndParam_Part0A_DspEffect, SndParamRun_EDC980 + 3744
.set SndParam_Part0A_DigitalEffect, SndParamRun_EDC980 + 3762
.set PartParam_Entry_118, SndParamRun_EDC980 + 3780
.set SndParam_Part0A_BendRange, SndParamRun_EDC980 + 3798
.set SndParam_Part0A_Tuning, SndParamRun_EDC980 + 3816
.set SndParam_Part0A_KeyShift, SndParamRun_EDC980 + 3834
.set PartParam_Entry_122, SndParamRun_EDC980 + 3852
.set PartParam_Entry_123, SndParamRun_EDC980 + 3870
.set SndParam_Part0B_Sound, SndParamRun_EDC980 + 3888
.set SndParam_Part0B_Modulation, SndParamRun_EDC980 + 3906
.set SndParam_Part0B_Volume, SndParamRun_EDC980 + 3924
.set SndParam_Part0B_Mute, SndParamRun_EDC980 + 3942
.set SndParam_Part0B_Pan, SndParamRun_EDC980 + 3960
.set SndParam_Part0B_Expression, SndParamRun_EDC980 + 3978
.set SndParam_Part0B_Bank, SndParamRun_EDC980 + 3996
.set SndParam_Part0B_Sustain, SndParamRun_EDC980 + 4014
.set SndParam_Part0B_ReverbSend, SndParamRun_EDC980 + 4032
.set SndParam_Part0B_DspEffect, SndParamRun_EDC980 + 4050
.set SndParam_Part0B_DigitalEffect, SndParamRun_EDC980 + 4068
.set PartParam_Entry_135, SndParamRun_EDC980 + 4086
.set SndParam_Part0B_BendRange, SndParamRun_EDC980 + 4104
.set SndParam_Part0B_Tuning, SndParamRun_EDC980 + 4122
.set SndParam_Part0B_KeyShift, SndParamRun_EDC980 + 4140
.set PartParam_Entry_139, SndParamRun_EDC980 + 4158
.set PartParam_Entry_140, SndParamRun_EDC980 + 4176
.set SndParam_Part0C_Sound, SndParamRun_EDC980 + 4194
.set SndParam_Part0C_Modulation, SndParamRun_EDC980 + 4212
.set SndParam_Part0C_Volume, SndParamRun_EDC980 + 4230
.set SndParam_Part0C_Mute, SndParamRun_EDC980 + 4248
.set SndParam_Part0C_Pan, SndParamRun_EDC980 + 4266
.set SndParam_Part0C_Expression, SndParamRun_EDC980 + 4284
.set SndParam_Part0C_Bank, SndParamRun_EDC980 + 4302
.set SndParam_Part0C_Sustain, SndParamRun_EDC980 + 4320
.set SndParam_Part0C_ReverbSend, SndParamRun_EDC980 + 4338
.set SndParam_Part0C_DspEffect, SndParamRun_EDC980 + 4356
.set SndParam_Part0C_DigitalEffect, SndParamRun_EDC980 + 4374
.set PartParam_Entry_152, SndParamRun_EDC980 + 4392
.set SndParam_Part0C_BendRange, SndParamRun_EDC980 + 4410
.set SndParam_Part0C_Tuning, SndParamRun_EDC980 + 4428
.set SndParam_Part0C_KeyShift, SndParamRun_EDC980 + 4446
.set PartParam_Entry_156, SndParamRun_EDC980 + 4464
.set PartParam_Entry_157, SndParamRun_EDC980 + 4482
.set SndParam_Part0D_Sound, SndParamRun_EDC980 + 4500
.set SndParam_Part0D_Modulation, SndParamRun_EDC980 + 4518
.set SndParam_Part0D_Volume, SndParamRun_EDC980 + 4536
.set SndParam_Part0D_Mute, SndParamRun_EDC980 + 4554
.set SndParam_Part0D_Pan, SndParamRun_EDC980 + 4572
.set SndParam_Part0D_Expression, SndParamRun_EDC980 + 4590
.set SndParam_Part0D_Bank, SndParamRun_EDC980 + 4608
.set SndParam_Part0D_Sustain, SndParamRun_EDC980 + 4626
.set SndParam_Part0D_ReverbSend, SndParamRun_EDC980 + 4644
.set SndParam_Part0D_DspEffect, SndParamRun_EDC980 + 4662
.set SndParam_Part0D_DigitalEffect, SndParamRun_EDC980 + 4680
.set PartParam_Entry_169, SndParamRun_EDC980 + 4698
.set SndParam_Part0D_BendRange, SndParamRun_EDC980 + 4716
.set SndParam_Part0D_Tuning, SndParamRun_EDC980 + 4734
.set SndParam_Part0D_KeyShift, SndParamRun_EDC980 + 4752
.set PartParam_Entry_173, SndParamRun_EDC980 + 4770
.set PartParam_Entry_174, SndParamRun_EDC980 + 4788
.set SndParam_Part0E_Sound, SndParamRun_EDC980 + 4806
.set SndParam_Part0E_Modulation, SndParamRun_EDC980 + 4824
.set SndParam_Part0E_Volume, SndParamRun_EDC980 + 4842
.set SndParam_Part0E_Mute, SndParamRun_EDC980 + 4860
.set SndParam_Part0E_Pan, SndParamRun_EDC980 + 4878
.set SndParam_Part0E_Expression, SndParamRun_EDC980 + 4896
.set SndParam_Part0E_Bank, SndParamRun_EDC980 + 4914
.set SndParam_Part0E_Sustain, SndParamRun_EDC980 + 4932
.set SndParam_Part0E_ReverbSend, SndParamRun_EDC980 + 4950
.set SndParam_Part0E_DspEffect, SndParamRun_EDC980 + 4968
.set SndParam_Part0E_DigitalEffect, SndParamRun_EDC980 + 4986
.set PartParam_Entry_186, SndParamRun_EDC980 + 5004
.set SndParam_Part0E_BendRange, SndParamRun_EDC980 + 5022
.set SndParam_Part0E_Tuning, SndParamRun_EDC980 + 5040
.set SndParam_Part0E_KeyShift, SndParamRun_EDC980 + 5058
.set PartParam_Entry_190, SndParamRun_EDC980 + 5076
.set PartParam_Entry_191, SndParamRun_EDC980 + 5094
.set SndParam_Part0F_Sound, SndParamRun_EDC980 + 5112
.set SndParam_Part0F_Modulation, SndParamRun_EDC980 + 5130
.set SndParam_Part0F_Volume, SndParamRun_EDC980 + 5148
.set SndParam_Part0F_Mute, SndParamRun_EDC980 + 5166
.set SndParam_Part0F_Pan, SndParamRun_EDC980 + 5184
.set SndParam_Part0F_Expression, SndParamRun_EDC980 + 5202
.set SndParam_Part0F_Bank, SndParamRun_EDC980 + 5220
.set SndParam_Part0F_Sustain, SndParamRun_EDC980 + 5238
.set SndParam_Part0F_ReverbSend, SndParamRun_EDC980 + 5256
.set SndParam_Part0F_DspEffect, SndParamRun_EDC980 + 5274
.set SndParam_Part0F_DigitalEffect, SndParamRun_EDC980 + 5292
.set PartParam_Entry_203, SndParamRun_EDC980 + 5310
.set SndParam_Part0F_BendRange, SndParamRun_EDC980 + 5328
.set SndParam_Part0F_Tuning, SndParamRun_EDC980 + 5346
.set SndParam_Part0F_KeyShift, SndParamRun_EDC980 + 5364
.set PartParam_Entry_207, SndParamRun_EDC980 + 5382
.set PartParam_Entry_208, SndParamRun_EDC980 + 5400
.set SndParam_Part10_Sound, SndParamRun_EDC980 + 5418
.set SndParam_Part10_Modulation, SndParamRun_EDC980 + 5436
.set SndParam_Part10_Volume, SndParamRun_EDC980 + 5454
.set SndParam_Part10_Mute, SndParamRun_EDC980 + 5472
.set SndParam_Part10_Pan, SndParamRun_EDC980 + 5490
.set SndParam_Part10_Expression, SndParamRun_EDC980 + 5508
.set SndParam_Part10_Bank, SndParamRun_EDC980 + 5526
.set SndParam_Part10_Sustain, SndParamRun_EDC980 + 5544
.set SndParam_Part10_ReverbSend, SndParamRun_EDC980 + 5562
.set SndParam_Part10_DspEffect, SndParamRun_EDC980 + 5580
.set SndParam_Part10_DigitalEffect, SndParamRun_EDC980 + 5598
.set PartParam_Entry_220, SndParamRun_EDC980 + 5616
.set SndParam_Part10_BendRange, SndParamRun_EDC980 + 5634
.set SndParam_Part10_Tuning, SndParamRun_EDC980 + 5652
.set SndParam_Part10_KeyShift, SndParamRun_EDC980 + 5670
.set PartParam_Entry_224, SndParamRun_EDC980 + 5688
.set PartParam_Entry_225, SndParamRun_EDC980 + 5706
.set SndParam_Part11_Sound, SndParamRun_EDC980 + 5724
.set SndParam_Part11_Modulation, SndParamRun_EDC980 + 5742
.set SndParam_Part11_Volume, SndParamRun_EDC980 + 5760
.set SndParam_Part11_Mute, SndParamRun_EDC980 + 5778
.set SndParam_Part11_Pan, SndParamRun_EDC980 + 5796
.set SndParam_Part11_Expression, SndParamRun_EDC980 + 5814
.set SndParam_Part11_Bank, SndParamRun_EDC980 + 5832
.set SndParam_Part11_Sustain, SndParamRun_EDC980 + 5850
.set SndParam_Part11_ReverbSend, SndParamRun_EDC980 + 5868
.set SndParam_Part11_DspEffect, SndParamRun_EDC980 + 5886
.set SndParam_Part11_DigitalEffect, SndParamRun_EDC980 + 5904
.set ExtPartParam_Entry_237, SndParamRun_EDC980 + 5922
.set SndParam_Part11_BendRange, SndParamRun_EDC980 + 5940
.set SndParam_Part11_Tuning, SndParamRun_EDC980 + 5958
.set SndParam_Part11_KeyShift, SndParamRun_EDC980 + 5976
.set ExtPartParam_Entry_241, SndParamRun_EDC980 + 5994
.set ExtPartParam_Entry_242, SndParamRun_EDC980 + 6012
.set SndParam_Part12_Sound, SndParamRun_EDC980 + 6030
.set SndParam_Part12_Modulation, SndParamRun_EDC980 + 6048
.set SndParam_Part12_Volume, SndParamRun_EDC980 + 6066
.set SndParam_Part12_Mute, SndParamRun_EDC980 + 6084
.set SndParam_Part12_Pan, SndParamRun_EDC980 + 6102
.set SndParam_Part12_Expression, SndParamRun_EDC980 + 6120
.set SndParam_Part12_Bank, SndParamRun_EDC980 + 6138
.set SndParam_Part12_Sustain, SndParamRun_EDC980 + 6156
.set SndParam_Part12_ReverbSend, SndParamRun_EDC980 + 6174
.set SndParam_Part12_DspEffect, SndParamRun_EDC980 + 6192
.set SndParam_Part12_DigitalEffect, SndParamRun_EDC980 + 6210
.set ExtPartParam_Entry_254, SndParamRun_EDC980 + 6228
.set SndParam_Part12_BendRange, SndParamRun_EDC980 + 6246
.set SndParam_Part12_Tuning, SndParamRun_EDC980 + 6264
.set SndParam_Part12_KeyShift, SndParamRun_EDC980 + 6282
.set ExtPartParam_Entry_258, SndParamRun_EDC980 + 6300
.set ExtPartParam_Entry_259, SndParamRun_EDC980 + 6318
.set SndParam_Part13_Sound, SndParamRun_EDC980 + 6336
.set SndParam_Part13_Modulation, SndParamRun_EDC980 + 6354
.set SndParam_Part13_Volume, SndParamRun_EDC980 + 6372
.set SndParam_Part13_Mute, SndParamRun_EDC980 + 6390
.set SndParam_Part13_Pan, SndParamRun_EDC980 + 6408
.set SndParam_Part13_Expression, SndParamRun_EDC980 + 6426
.set SndParam_Part13_Bank, SndParamRun_EDC980 + 6444
.set SndParam_Part13_Sustain, SndParamRun_EDC980 + 6462
.set SndParam_Part13_ReverbSend, SndParamRun_EDC980 + 6480
.set SndParam_Part13_DspEffect, SndParamRun_EDC980 + 6498
.set SndParam_Part13_DigitalEffect, SndParamRun_EDC980 + 6516
.set ExtPartParam_Entry_271, SndParamRun_EDC980 + 6534
.set SndParam_Part13_BendRange, SndParamRun_EDC980 + 6552
.set SndParam_Part13_Tuning, SndParamRun_EDC980 + 6570
.set SndParam_Part13_KeyShift, SndParamRun_EDC980 + 6588
.set ExtPartParam_Entry_275, SndParamRun_EDC980 + 6606
.set ExtPartParam_Entry_276, SndParamRun_EDC980 + 6624
.set SndParam_Part14_Sound, SndParamRun_EDC980 + 6642
.set SndParam_Part14_Modulation, SndParamRun_EDC980 + 6660
.set SndParam_Part14_Volume, SndParamRun_EDC980 + 6678
.set SndParam_Part14_Mute, SndParamRun_EDC980 + 6696
.set SndParam_Part14_Pan, SndParamRun_EDC980 + 6714
.set SndParam_Part14_Expression, SndParamRun_EDC980 + 6732
.set SndParam_Part14_Bank, SndParamRun_EDC980 + 6750
.set SndParam_Part14_Sustain, SndParamRun_EDC980 + 6768
.set SndParam_Part14_ReverbSend, SndParamRun_EDC980 + 6786
.set SndParam_Part14_DspEffect, SndParamRun_EDC980 + 6804
.set SndParam_Part14_DigitalEffect, SndParamRun_EDC980 + 6822
.set ExtPartParam_Entry_288, SndParamRun_EDC980 + 6840
.set SndParam_Part14_BendRange, SndParamRun_EDC980 + 6858
.set SndParam_Part14_Tuning, SndParamRun_EDC980 + 6876
.set SndParam_Part14_KeyShift, SndParamRun_EDC980 + 6894
.set ExtPartParam_Entry_292, SndParamRun_EDC980 + 6912
.set ExtPartParam_Entry_293, SndParamRun_EDC980 + 6930
.set SndParam_Part15_Sound, SndParamRun_EDC980 + 6948
.set SndParam_Part15_Modulation, SndParamRun_EDC980 + 6966
.set SndParam_Part15_Volume, SndParamRun_EDC980 + 6984
.set SndParam_Part15_Mute, SndParamRun_EDC980 + 7002
.set SndParam_Part15_Pan, SndParamRun_EDC980 + 7020
.set SndParam_Part15_Expression, SndParamRun_EDC980 + 7038
.set SndParam_Part15_Bank, SndParamRun_EDC980 + 7056
.set SndParam_Part15_Sustain, SndParamRun_EDC980 + 7074
.set SndParam_Part15_ReverbSend, SndParamRun_EDC980 + 7092
.set SndParam_Part15_DspEffect, SndParamRun_EDC980 + 7110
.set SndParam_Part15_DigitalEffect, SndParamRun_EDC980 + 7128
.set ExtPartParam_Entry_305, SndParamRun_EDC980 + 7146
.set SndParam_Part15_BendRange, SndParamRun_EDC980 + 7164
.set SndParam_Part15_Tuning, SndParamRun_EDC980 + 7182
.set SndParam_Part15_KeyShift, SndParamRun_EDC980 + 7200
.set ExtPartParam_Entry_309, SndParamRun_EDC980 + 7218
.set ExtPartParam_Entry_310, SndParamRun_EDC980 + 7236
.set SndParam_Part16_Sound, SndParamRun_EDC980 + 7254
.set SndParam_Part16_Modulation, SndParamRun_EDC980 + 7272
.set SndParam_Part16_Volume, SndParamRun_EDC980 + 7290
.set SndParam_Part16_Mute, SndParamRun_EDC980 + 7308
.set SndParam_Part16_Pan, SndParamRun_EDC980 + 7326
.set SndParam_Part16_Expression, SndParamRun_EDC980 + 7344
.set SndParam_Part16_Bank, SndParamRun_EDC980 + 7362
.set SndParam_Part16_Sustain, SndParamRun_EDC980 + 7380
.set SndParam_Part16_ReverbSend, SndParamRun_EDC980 + 7398
.set SndParam_Part16_DspEffect, SndParamRun_EDC980 + 7416
.set SndParam_Part16_DigitalEffect, SndParamRun_EDC980 + 7434
.set ExtPartParam_Entry_322, SndParamRun_EDC980 + 7452
.set SndParam_Part16_BendRange, SndParamRun_EDC980 + 7470
.set SndParam_Part16_Tuning, SndParamRun_EDC980 + 7488
.set SndParam_Part16_KeyShift, SndParamRun_EDC980 + 7506
.set ExtPartParam_Entry_326, SndParamRun_EDC980 + 7524
.set ExtPartParam_Entry_327, SndParamRun_EDC980 + 7542
.set SndParam_Part17_Sound, SndParamRun_EDC980 + 7560
.set SndParam_Part17_Modulation, SndParamRun_EDC980 + 7578
.set SndParam_Part17_Volume, SndParamRun_EDC980 + 7596
.set SndParam_Part17_Mute, SndParamRun_EDC980 + 7614
.set SndParam_Part17_Pan, SndParamRun_EDC980 + 7632
.set SndParam_Part17_Expression, SndParamRun_EDC980 + 7650
.set SndParam_Part17_Bank, SndParamRun_EDC980 + 7668
.set SndParam_Part17_Sustain, SndParamRun_EDC980 + 7686
.set SndParam_Part17_ReverbSend, SndParamRun_EDC980 + 7704
.set SndParam_Part17_DspEffect, SndParamRun_EDC980 + 7722
.set SndParam_Part17_DigitalEffect, SndParamRun_EDC980 + 7740
.set ExtPartParam_Entry_339, SndParamRun_EDC980 + 7758
.set SndParam_Part17_BendRange, SndParamRun_EDC980 + 7776
.set SndParam_Part17_Tuning, SndParamRun_EDC980 + 7794
.set SndParam_Part17_KeyShift, SndParamRun_EDC980 + 7812
.set ExtPartParam_Entry_343, SndParamRun_EDC980 + 7830
.set ExtPartParam_Entry_344, SndParamRun_EDC980 + 7848
.set SndParam_Part18_Sound, SndParamRun_EDC980 + 7866
.set SndParam_Part18_Modulation, SndParamRun_EDC980 + 7884
.set SndParam_Part18_Volume, SndParamRun_EDC980 + 7902
.set SndParam_Part18_Mute, SndParamRun_EDC980 + 7920
.set SndParam_Part18_Pan, SndParamRun_EDC980 + 7938
.set SndParam_Part18_Expression, SndParamRun_EDC980 + 7956
.set SndParam_Part18_Bank, SndParamRun_EDC980 + 7974
.set SndParam_Part18_Sustain, SndParamRun_EDC980 + 7992
.set SndParam_Part18_ReverbSend, SndParamRun_EDC980 + 8010
.set SndParam_Part18_DspEffect, SndParamRun_EDC980 + 8028
.set SndParam_Part18_DigitalEffect, SndParamRun_EDC980 + 8046
.set ExtPartParam_Entry_356, SndParamRun_EDC980 + 8064
.set SndParam_Part18_BendRange, SndParamRun_EDC980 + 8082
.set SndParam_Part18_Tuning, SndParamRun_EDC980 + 8100
.set SndParam_Part18_KeyShift, SndParamRun_EDC980 + 8118
.set ExtPartParam_Entry_360, SndParamRun_EDC980 + 8136
.set ExtPartParam_Entry_361, SndParamRun_EDC980 + 8154
.set ExtPartParam_Entry_362, SndParamRun_EDC980 + 8172
.set ExtPartParam_Entry_363, SndParamRun_EDC980 + 8190
.set ExtPartParam_Entry_364, SndParamRun_EDC980 + 8208
.set ExtPartParam_Entry_365, SndParamRun_EDC980 + 8226
.set ExtPartParam_Entry_366, SndParamRun_EDC980 + 8244
.set ExtPartParam_Entry_367, SndParamRun_EDC980 + 8262
ExtPartParam_Entry_368:
	sndparam_descriptor 0x018004, 0, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
WidgetParam_MidiCC_PitchBend_Map:
	.byte 0x05, 0x06, 0x07, 0x00, 0x01, 0x02, 0x03
	.byte 0xff
WidgetParam_MidiCC_PitchBend:
	.long WidgetParam_MidiCC_PitchBend_Map
	.short 7
	.byte 0x00, 0x03, 0x00, 0xff
;  314 x 18-byte sound-parameter descriptors, 0xEDE9FC-0xEE0010, one
;  `sndparam_descriptor` per record (fields: the macro above).  v10
;  compiles the same records from audio/sndparam_records/run_ede9fc.c;
;  the record labels follow the run as `.set` equates, as in v10.
SndParamRun_EDE9FC:
	sndparam_descriptor 0x018200, 0, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
	sndparam_descriptor 0x018201, 0, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018202, 0, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018203, 0, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018204, 0, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018205, 0, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018206, 0, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018400, 1, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018401, 1, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018402, 1, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018403, 1, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018404, 1, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x018600, 1, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018601, 1, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018602, 1, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018603, 1, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018604, 1, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018605, 1, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018606, 1, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018800, 2, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018801, 2, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018802, 2, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018803, 2, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018804, 2, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x018a00, 2, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a01, 2, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a02, 2, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a03, 2, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a04, 2, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a05, 2, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018a06, 2, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018c00, 3, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018c01, 3, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018c02, 3, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018c03, 3, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018c04, 3, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x018e00, 3, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e01, 3, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e02, 3, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e03, 3, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e04, 3, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e05, 3, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x018e06, 3, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019000, 4, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019001, 4, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019002, 4, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019003, 4, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019004, 4, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x019200, 4, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019201, 4, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019202, 4, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019203, 4, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019204, 4, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019205, 4, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019206, 4, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019400, 5, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019401, 5, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019402, 5, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019403, 5, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019404, 5, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x019600, 5, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019601, 5, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019602, 5, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019603, 5, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019604, 5, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019605, 5, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019606, 5, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019800, 6, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019801, 6, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019802, 6, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019803, 6, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019804, 6, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x019a00, 6, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a01, 6, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a02, 6, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a03, 6, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a04, 6, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a05, 6, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019a06, 6, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019c00, 7, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019c01, 7, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019c02, 7, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019c03, 7, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019c04, 7, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x019e00, 7, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e01, 7, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e02, 7, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e03, 7, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e04, 7, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e05, 7, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x019e06, 7, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a000, 8, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a001, 8, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a002, 8, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a003, 8, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a004, 8, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01a200, 8, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a201, 8, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a202, 8, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a203, 8, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a204, 8, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a205, 8, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a206, 8, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a400, 9, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a401, 9, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a402, 9, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a403, 9, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a404, 9, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01a600, 9, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a601, 9, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a602, 9, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a603, 9, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a604, 9, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a605, 9, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a606, 9, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a800, 10, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a801, 10, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a802, 10, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a803, 10, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01a804, 10, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01aa00, 10, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa01, 10, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa02, 10, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa03, 10, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa04, 10, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa05, 10, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01aa06, 10, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ac00, 11, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ac01, 11, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ac02, 11, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ac03, 11, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ac04, 11, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01ae00, 11, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae01, 11, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae02, 11, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae03, 11, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae04, 11, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae05, 11, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ae06, 11, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b000, 12, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b001, 12, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b002, 12, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b003, 12, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b004, 12, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01b200, 12, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b201, 12, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b202, 12, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b203, 12, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b204, 12, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b205, 12, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b206, 12, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b400, 13, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b401, 13, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b402, 13, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b403, 13, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b404, 13, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01b600, 13, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b601, 13, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b602, 13, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b603, 13, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b604, 13, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b605, 13, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b606, 13, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b800, 14, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b801, 14, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b802, 14, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b803, 14, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01b804, 14, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01ba00, 14, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba01, 14, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba02, 14, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba03, 14, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba04, 14, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba05, 14, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ba06, 14, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01bc00, 15, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01bc01, 15, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01bc02, 15, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01bc03, 15, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01bc04, 15, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01be00, 15, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
	sndparam_descriptor 0x01be01, 15, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01be02, 15, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01be03, 15, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01be04, 15, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01be05, 15, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01be06, 15, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c000, 16, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c001, 16, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c002, 16, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c003, 16, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c004, 16, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01c200, 16, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 7, 0, 0, 0xff
	sndparam_descriptor 0x01c201, 16, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c202, 16, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c203, 16, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c204, 16, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c205, 16, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c206, 16, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c400, 17, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c401, 17, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c402, 17, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c403, 17, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c404, 17, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01c600, 17, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c601, 17, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c602, 17, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c603, 17, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c604, 17, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c605, 17, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c606, 17, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c800, 18, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c801, 18, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c802, 18, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c803, 18, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01c804, 18, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01ca00, 18, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca01, 18, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca02, 18, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca03, 18, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca04, 18, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca05, 18, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ca06, 18, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01cc00, 19, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01cc01, 19, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01cc02, 19, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01cc03, 19, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01cc04, 19, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01ce00, 19, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce01, 19, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce02, 19, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce03, 19, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce04, 19, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce05, 19, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01ce06, 19, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d000, 20, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d001, 20, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d002, 20, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d003, 20, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d004, 20, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01d200, 20, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d201, 20, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d202, 20, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d203, 20, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d204, 20, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d205, 20, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d206, 20, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d400, 21, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d401, 21, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d402, 21, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d403, 21, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d404, 21, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01d600, 21, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d601, 21, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d602, 21, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d603, 21, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d604, 21, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d605, 21, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d606, 21, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d800, 22, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d801, 22, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d802, 22, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d803, 22, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01d804, 22, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01da00, 22, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da01, 22, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da02, 22, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da03, 22, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da04, 22, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da05, 22, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01da06, 22, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01dc00, 23, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01dc01, 23, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01dc02, 23, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01dc03, 23, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01dc04, 23, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01de00, 23, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de01, 23, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de02, 23, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de03, 23, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de04, 23, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de05, 23, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01de06, 23, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e000, 24, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e001, 24, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e002, 24, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e003, 24, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e004, 24, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01e200, 24, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e201, 24, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e202, 24, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e203, 24, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e204, 24, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e205, 24, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e206, 24, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e400, 25, 13, 0x20, 0, 1, 5, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e401, 25, 13, 0x0f, 0, 15, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e402, 25, 13, 0x40, 0, 1, 6, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e403, 25, 13, 0x80, 0, 1, 7, 0xff, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e404, 25, 12, 0x07, 0, 127, 0, 0x00, 0x02, 1, 7, 5, 0, 0, 0xff
	sndparam_descriptor 0x01e600, 25, 4, 0x07, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e601, 25, 4, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e602, 25, 12, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e603, 25, 12, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e604, 25, 4, 0x20, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e605, 25, 22, 0x01, 0, 1, 5, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x01e606, 25, 12, 0x10, 0, 1, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028000, 72, 0, 0xff, 0, 255, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028001, 72, 1, 0x7f, 0, 7, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028002, 72, 7, 0x30, 0, 3, 4, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028080, 72, 3, 0x07, 0, 3, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028081, 72, 3, 0x08, 0, 1, 3, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028082, 144, 3, 0x01, 0, 1, 0, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
	sndparam_descriptor 0x028083, 144, 3, 0x02, 0, 1, 1, 0x00, 0xff, 1, 1, 1, 0, 0, 0xff
.set ExtPartParam_Entry_369, SndParamRun_EDE9FC + 0
.set ExtPartParam_Entry_370, SndParamRun_EDE9FC + 18
.set ExtPartParam_Entry_371, SndParamRun_EDE9FC + 36
.set ExtPartParam_Entry_372, SndParamRun_EDE9FC + 54
.set ExtPartParam_Entry_373, SndParamRun_EDE9FC + 72
.set ExtPartParam_Entry_374, SndParamRun_EDE9FC + 90
.set ExtPartParam_Entry_375, SndParamRun_EDE9FC + 108
.set ExtPartParam_Entry_376, SndParamRun_EDE9FC + 126
.set ExtPartParam_Entry_377, SndParamRun_EDE9FC + 144
.set ExtPartParam_Entry_378, SndParamRun_EDE9FC + 162
.set ExtPartParam_Entry_379, SndParamRun_EDE9FC + 180
.set ExtPartParam_Entry_380, SndParamRun_EDE9FC + 198
.set ExtPartParam_Entry_381, SndParamRun_EDE9FC + 216
.set ExtPartParam_Entry_382, SndParamRun_EDE9FC + 234
.set ExtPartParam_Entry_383, SndParamRun_EDE9FC + 252
.set ExtPartParam_Entry_384, SndParamRun_EDE9FC + 270
.set ExtPartParam_Entry_385, SndParamRun_EDE9FC + 288
.set ExtPartParam_Entry_386, SndParamRun_EDE9FC + 306
.set ExtPartParam_Entry_387, SndParamRun_EDE9FC + 324
.set ExtPartParam_Entry_388, SndParamRun_EDE9FC + 342
.set ExtPartParam_Entry_389, SndParamRun_EDE9FC + 360
.set ExtPartParam_Entry_390, SndParamRun_EDE9FC + 378
.set ExtPartParam_Entry_391, SndParamRun_EDE9FC + 396
.set ExtPartParam_Entry_392, SndParamRun_EDE9FC + 414
.set ExtPartParam_Entry_393, SndParamRun_EDE9FC + 432
.set ExtPartParam_Entry_394, SndParamRun_EDE9FC + 450
.set ExtPartParam_Entry_395, SndParamRun_EDE9FC + 468
.set ExtPartParam_Entry_396, SndParamRun_EDE9FC + 486
.set ExtPartParam_Entry_397, SndParamRun_EDE9FC + 504
.set ExtPartParam_Entry_398, SndParamRun_EDE9FC + 522
.set ExtPartParam_Entry_399, SndParamRun_EDE9FC + 540
.set ExtPartParam_Entry_400, SndParamRun_EDE9FC + 558
.set ExtPartParam_Entry_401, SndParamRun_EDE9FC + 576
.set ExtPartParam_Entry_402, SndParamRun_EDE9FC + 594
.set ExtPartParam_Entry_403, SndParamRun_EDE9FC + 612
.set ExtPartParam_Entry_404, SndParamRun_EDE9FC + 630
.set ExtPartParam_Entry_405, SndParamRun_EDE9FC + 648
.set ExtPartParam_Entry_406, SndParamRun_EDE9FC + 666
.set ExtPartParam_Entry_407, SndParamRun_EDE9FC + 684
.set ExtPartParam_Entry_408, SndParamRun_EDE9FC + 702
.set ExtPartParam_Entry_409, SndParamRun_EDE9FC + 720
.set ExtPartParam_Entry_410, SndParamRun_EDE9FC + 738
.set ExtPartParam_Entry_411, SndParamRun_EDE9FC + 756
.set ExtPartParam_Entry_412, SndParamRun_EDE9FC + 774
.set ExtPartParam_Entry_413, SndParamRun_EDE9FC + 792
.set ExtPartParam_Entry_414, SndParamRun_EDE9FC + 810
.set ExtPartParam_Entry_415, SndParamRun_EDE9FC + 828
.set ExtPartParam_Entry_416, SndParamRun_EDE9FC + 846
.set ExtPartParam_Entry_417, SndParamRun_EDE9FC + 864
.set ExtPartParam_Entry_418, SndParamRun_EDE9FC + 882
.set ExtPartParam_Entry_419, SndParamRun_EDE9FC + 900
.set ExtPartParam_Entry_420, SndParamRun_EDE9FC + 918
.set ExtPartParam_Entry_421, SndParamRun_EDE9FC + 936
.set ExtPartParam_Entry_422, SndParamRun_EDE9FC + 954
.set ExtPartParam_Entry_423, SndParamRun_EDE9FC + 972
.set ExtPartParam_Entry_424, SndParamRun_EDE9FC + 990
.set ExtPartParam_Entry_425, SndParamRun_EDE9FC + 1008
.set ExtPartParam_Entry_426, SndParamRun_EDE9FC + 1026
.set ExtPartParam_Entry_427, SndParamRun_EDE9FC + 1044
.set ExtPartParam_Entry_428, SndParamRun_EDE9FC + 1062
.set ExtPartParam_Entry_429, SndParamRun_EDE9FC + 1080
.set ExtPartParam_Entry_430, SndParamRun_EDE9FC + 1098
.set ExtPartParam_Entry_431, SndParamRun_EDE9FC + 1116
.set ExtPartParam_Entry_432, SndParamRun_EDE9FC + 1134
.set ExtPartParam_Entry_433, SndParamRun_EDE9FC + 1152
.set ExtPartParam_Entry_434, SndParamRun_EDE9FC + 1170
.set ExtPartParam_Entry_435, SndParamRun_EDE9FC + 1188
.set ExtPartParam_Entry_436, SndParamRun_EDE9FC + 1206
.set ExtPartParam_Entry_437, SndParamRun_EDE9FC + 1224
.set ExtPartParam_Entry_438, SndParamRun_EDE9FC + 1242
.set ExtPartParam_Entry_439, SndParamRun_EDE9FC + 1260
.set ExtPartParam_Entry_440, SndParamRun_EDE9FC + 1278
.set ExtPartParam_Entry_441, SndParamRun_EDE9FC + 1296
.set ExtPartParam_Entry_442, SndParamRun_EDE9FC + 1314
.set ExtPartParam_Entry_443, SndParamRun_EDE9FC + 1332
.set ExtPartParam_Entry_444, SndParamRun_EDE9FC + 1350
.set ExtPartParam_Entry_445, SndParamRun_EDE9FC + 1368
.set ExtPartParam_Entry_446, SndParamRun_EDE9FC + 1386
.set ExtPartParam_Entry_447, SndParamRun_EDE9FC + 1404
.set ExtPartParam_Entry_448, SndParamRun_EDE9FC + 1422
.set ExtPartParam_Entry_449, SndParamRun_EDE9FC + 1440
.set ExtPartParam_Entry_450, SndParamRun_EDE9FC + 1458
.set ExtPartParam_Entry_451, SndParamRun_EDE9FC + 1476
.set ExtPartParam_Entry_452, SndParamRun_EDE9FC + 1494
.set ExtPartParam_Entry_453, SndParamRun_EDE9FC + 1512
.set ExtPartParam_Entry_454, SndParamRun_EDE9FC + 1530
.set SeqMixParam_Entry_001, SndParamRun_EDE9FC + 1548
.set SeqMixParam_Entry_002, SndParamRun_EDE9FC + 1566
.set SeqMixParam_Entry_003, SndParamRun_EDE9FC + 1584
.set SeqMixParam_Entry_004, SndParamRun_EDE9FC + 1602
.set SeqMixParam_Entry_005, SndParamRun_EDE9FC + 1620
.set SeqMixParam_Entry_006, SndParamRun_EDE9FC + 1638
.set SeqMixParam_Entry_007, SndParamRun_EDE9FC + 1656
.set SeqMixParam_Entry_008, SndParamRun_EDE9FC + 1674
.set SeqMixParam_Entry_009, SndParamRun_EDE9FC + 1692
.set SeqMixParam_Entry_010, SndParamRun_EDE9FC + 1710
.set SeqMixParam_Entry_011, SndParamRun_EDE9FC + 1728
.set SeqMixParam_Entry_012, SndParamRun_EDE9FC + 1746
.set SeqMixParam_Entry_013, SndParamRun_EDE9FC + 1764
.set SeqMixParam_Entry_014, SndParamRun_EDE9FC + 1782
.set SeqMixParam_Entry_015, SndParamRun_EDE9FC + 1800
.set SeqMixParam_Entry_016, SndParamRun_EDE9FC + 1818
.set SeqMixParam_Entry_017, SndParamRun_EDE9FC + 1836
.set SeqMixParam_Entry_018, SndParamRun_EDE9FC + 1854
.set SeqMixParam_Entry_019, SndParamRun_EDE9FC + 1872
.set SeqMixParam_Entry_020, SndParamRun_EDE9FC + 1890
.set SeqMixParam_Entry_021, SndParamRun_EDE9FC + 1908
.set SeqMixParam_Entry_022, SndParamRun_EDE9FC + 1926
.set SeqMixParam_Entry_023, SndParamRun_EDE9FC + 1944
.set SeqMixParam_Entry_024, SndParamRun_EDE9FC + 1962
.set SeqMixParam_Entry_025, SndParamRun_EDE9FC + 1980
.set SeqMixParam_Entry_026, SndParamRun_EDE9FC + 1998
.set SeqMixParam_Entry_027, SndParamRun_EDE9FC + 2016
.set SeqMixParam_Entry_028, SndParamRun_EDE9FC + 2034
.set SeqMixParam_Entry_029, SndParamRun_EDE9FC + 2052
.set SeqMixParam_Entry_030, SndParamRun_EDE9FC + 2070
.set SeqMixParam_Entry_031, SndParamRun_EDE9FC + 2088
.set SeqMixParam_Entry_032, SndParamRun_EDE9FC + 2106
.set SeqMixParam_Entry_033, SndParamRun_EDE9FC + 2124
.set SeqMixParam_Entry_034, SndParamRun_EDE9FC + 2142
.set SeqMixParam_Entry_035, SndParamRun_EDE9FC + 2160
.set SeqMixParam_Entry_036, SndParamRun_EDE9FC + 2178
.set SeqMixParam_Entry_037, SndParamRun_EDE9FC + 2196
.set SeqMixParam_Entry_038, SndParamRun_EDE9FC + 2214
.set SeqMixParam_Entry_039, SndParamRun_EDE9FC + 2232
.set SeqMixParam_Entry_040, SndParamRun_EDE9FC + 2250
.set SeqMixParam_Entry_041, SndParamRun_EDE9FC + 2268
.set SeqMixParam_Entry_042, SndParamRun_EDE9FC + 2286
.set SeqMixParam_Entry_043, SndParamRun_EDE9FC + 2304
.set SeqMixParam_Entry_044, SndParamRun_EDE9FC + 2322
.set SeqMixParam_Entry_045, SndParamRun_EDE9FC + 2340
.set SeqMixParam_Entry_046, SndParamRun_EDE9FC + 2358
.set SeqMixParam_Entry_047, SndParamRun_EDE9FC + 2376
.set SeqMixParam_Entry_048, SndParamRun_EDE9FC + 2394
.set SeqMixParam_Entry_049, SndParamRun_EDE9FC + 2412
.set SeqMixParam_Entry_050, SndParamRun_EDE9FC + 2430
.set SeqMixParam_Entry_051, SndParamRun_EDE9FC + 2448
.set SeqMixParam_Entry_052, SndParamRun_EDE9FC + 2466
.set SeqMixParam_Entry_053, SndParamRun_EDE9FC + 2484
.set SeqMixParam_Entry_054, SndParamRun_EDE9FC + 2502
.set SeqMixParam_Entry_055, SndParamRun_EDE9FC + 2520
.set SeqMixParam_Entry_056, SndParamRun_EDE9FC + 2538
.set SeqMixParam_Entry_057, SndParamRun_EDE9FC + 2556
.set SeqMixParam_Entry_058, SndParamRun_EDE9FC + 2574
.set SeqMixParam_Entry_059, SndParamRun_EDE9FC + 2592
.set SeqMixParam_Entry_060, SndParamRun_EDE9FC + 2610
.set SeqMixParam_Entry_061, SndParamRun_EDE9FC + 2628
.set SeqMixParam_Entry_062, SndParamRun_EDE9FC + 2646
.set SeqMixParam_Entry_063, SndParamRun_EDE9FC + 2664
.set SeqMixParam_Entry_064, SndParamRun_EDE9FC + 2682
.set SeqMixParam_Entry_065, SndParamRun_EDE9FC + 2700
.set SeqMixParam_Entry_066, SndParamRun_EDE9FC + 2718
.set SeqMixParam_Entry_067, SndParamRun_EDE9FC + 2736
.set SeqMixParam_Entry_068, SndParamRun_EDE9FC + 2754
.set SeqMixParam_Entry_069, SndParamRun_EDE9FC + 2772
.set SeqMixParam_Entry_070, SndParamRun_EDE9FC + 2790
.set SeqMixParam_Entry_071, SndParamRun_EDE9FC + 2808
.set SeqMixParam_Entry_072, SndParamRun_EDE9FC + 2826
.set SeqMixParam_Entry_073, SndParamRun_EDE9FC + 2844
.set SeqMixParam_Entry_074, SndParamRun_EDE9FC + 2862
.set SeqMixParam_Entry_075, SndParamRun_EDE9FC + 2880
.set SeqMixParam_Entry_076, SndParamRun_EDE9FC + 2898
.set SeqMixParam_Entry_077, SndParamRun_EDE9FC + 2916
.set SeqMixParam_Entry_078, SndParamRun_EDE9FC + 2934
.set SeqMixParam_Entry_079, SndParamRun_EDE9FC + 2952
.set SeqMixParam_Entry_080, SndParamRun_EDE9FC + 2970
.set SeqMixParam_Entry_081, SndParamRun_EDE9FC + 2988
.set SeqMixParam_Entry_082, SndParamRun_EDE9FC + 3006
.set SeqMixParam_Entry_083, SndParamRun_EDE9FC + 3024
.set SeqMixParam_Entry_084, SndParamRun_EDE9FC + 3042
.set SeqMixParam_Entry_085, SndParamRun_EDE9FC + 3060
.set SeqMixParam_Entry_086, SndParamRun_EDE9FC + 3078
.set SeqMixParam_Entry_087, SndParamRun_EDE9FC + 3096
.set SeqMixParam_Entry_088, SndParamRun_EDE9FC + 3114
.set SeqMixParam_Entry_089, SndParamRun_EDE9FC + 3132
.set SeqMixParam_Entry_090, SndParamRun_EDE9FC + 3150
.set SeqMixParam_Entry_091, SndParamRun_EDE9FC + 3168
.set SeqMixParam_Entry_092, SndParamRun_EDE9FC + 3186
.set SeqMixParam_Entry_093, SndParamRun_EDE9FC + 3204
.set SeqMixParam_Entry_094, SndParamRun_EDE9FC + 3222
.set SeqMixParam_Entry_095, SndParamRun_EDE9FC + 3240
.set SeqMixParam_Entry_096, SndParamRun_EDE9FC + 3258
.set SeqMixParam_Entry_097, SndParamRun_EDE9FC + 3276
.set SeqMixParam_Entry_098, SndParamRun_EDE9FC + 3294
.set SeqMixParam_Entry_099, SndParamRun_EDE9FC + 3312
.set SeqMixParam_Entry_100, SndParamRun_EDE9FC + 3330
.set SeqMixParam_Entry_101, SndParamRun_EDE9FC + 3348
.set SeqMixParam_Entry_102, SndParamRun_EDE9FC + 3366
.set SeqMixParam_Entry_103, SndParamRun_EDE9FC + 3384
.set SeqMixParam_Entry_104, SndParamRun_EDE9FC + 3402
.set SeqMixParam_Entry_105, SndParamRun_EDE9FC + 3420
.set SeqMixParam_Entry_106, SndParamRun_EDE9FC + 3438
.set SeqMixParam_Entry_107, SndParamRun_EDE9FC + 3456
.set SeqMixParam_Entry_108, SndParamRun_EDE9FC + 3474
.set SeqMixParam_Entry_109, SndParamRun_EDE9FC + 3492
.set SeqMixParam_Entry_110, SndParamRun_EDE9FC + 3510
.set SeqMixParam_Entry_111, SndParamRun_EDE9FC + 3528
.set SeqMixParam_Entry_112, SndParamRun_EDE9FC + 3546
.set SeqMixParam_Entry_113, SndParamRun_EDE9FC + 3564
.set SeqMixParam_Entry_114, SndParamRun_EDE9FC + 3582
.set SeqMixParam_Entry_115, SndParamRun_EDE9FC + 3600
.set SeqMixParam_Entry_116, SndParamRun_EDE9FC + 3618
.set SeqMixParam_Entry_117, SndParamRun_EDE9FC + 3636
.set SeqMixParam_Entry_118, SndParamRun_EDE9FC + 3654
.set SeqMixParam_Entry_119, SndParamRun_EDE9FC + 3672
.set SeqMixParam_Entry_120, SndParamRun_EDE9FC + 3690
.set SeqMixParam_Entry_121, SndParamRun_EDE9FC + 3708
.set SeqMixParam_Entry_122, SndParamRun_EDE9FC + 3726
.set SeqMixParam_Entry_123, SndParamRun_EDE9FC + 3744
.set SeqMixParam_Entry_124, SndParamRun_EDE9FC + 3762
.set SeqMixParam_Entry_125, SndParamRun_EDE9FC + 3780
.set SeqMixParam_Entry_126, SndParamRun_EDE9FC + 3798
.set SeqMixParam_Entry_127, SndParamRun_EDE9FC + 3816
.set SeqMixParam_Entry_128, SndParamRun_EDE9FC + 3834
.set SeqMixParam_Entry_129, SndParamRun_EDE9FC + 3852
.set SeqMixParam_Entry_130, SndParamRun_EDE9FC + 3870
.set SeqMixParam_Entry_131, SndParamRun_EDE9FC + 3888
.set SeqMixParam_Entry_132, SndParamRun_EDE9FC + 3906
.set SeqMixParam_Entry_133, SndParamRun_EDE9FC + 3924
.set SeqMixParam_Entry_134, SndParamRun_EDE9FC + 3942
.set SeqMixParam_Entry_135, SndParamRun_EDE9FC + 3960
.set SeqMixParam_Entry_136, SndParamRun_EDE9FC + 3978
.set SeqMixParam_Entry_137, SndParamRun_EDE9FC + 3996
.set SeqMixParam_Entry_138, SndParamRun_EDE9FC + 4014
.set SeqMixParam_Entry_139, SndParamRun_EDE9FC + 4032
.set SeqMixParam_Entry_140, SndParamRun_EDE9FC + 4050
.set SeqMixParam_Entry_141, SndParamRun_EDE9FC + 4068
.set SeqMixParam_Entry_142, SndParamRun_EDE9FC + 4086
.set SeqMixParam_Entry_143, SndParamRun_EDE9FC + 4104
.set SeqMixParam_Entry_144, SndParamRun_EDE9FC + 4122
.set SeqMixParam_Entry_145, SndParamRun_EDE9FC + 4140
.set SeqMixParam_Entry_146, SndParamRun_EDE9FC + 4158
.set SeqMixParam_Entry_147, SndParamRun_EDE9FC + 4176
.set SeqMixParam_Entry_148, SndParamRun_EDE9FC + 4194
.set SeqMixParam_Entry_149, SndParamRun_EDE9FC + 4212
.set SeqMixParam_Entry_150, SndParamRun_EDE9FC + 4230
.set SeqMixParam_Entry_151, SndParamRun_EDE9FC + 4248
.set SeqMixParam_Entry_152, SndParamRun_EDE9FC + 4266
.set SeqMixParam_Entry_153, SndParamRun_EDE9FC + 4284
.set SeqMixParam_Entry_154, SndParamRun_EDE9FC + 4302
.set SeqMixParam_Entry_155, SndParamRun_EDE9FC + 4320
.set SeqMixParam_Entry_156, SndParamRun_EDE9FC + 4338
.set SeqMixParam_Entry_157, SndParamRun_EDE9FC + 4356
.set SeqMixParam_Entry_158, SndParamRun_EDE9FC + 4374
.set SeqMixParam_Entry_159, SndParamRun_EDE9FC + 4392
.set SeqMixParam_Entry_160, SndParamRun_EDE9FC + 4410
.set SeqMixParam_Entry_161, SndParamRun_EDE9FC + 4428
.set SeqMixParam_Entry_162, SndParamRun_EDE9FC + 4446
.set SeqMixParam_Entry_163, SndParamRun_EDE9FC + 4464
.set SeqMixParam_Entry_164, SndParamRun_EDE9FC + 4482
.set SeqMixParam_Entry_165, SndParamRun_EDE9FC + 4500
.set SeqMixParam_Entry_166, SndParamRun_EDE9FC + 4518
.set SeqMixParam_Entry_167, SndParamRun_EDE9FC + 4536
.set SeqMixParam_Entry_168, SndParamRun_EDE9FC + 4554
.set SeqMixParam_Entry_169, SndParamRun_EDE9FC + 4572
.set SeqMixParam_Entry_170, SndParamRun_EDE9FC + 4590
.set SeqMixParam_Entry_171, SndParamRun_EDE9FC + 4608
.set SeqMixParam_Entry_172, SndParamRun_EDE9FC + 4626
.set SeqMixParam_Entry_173, SndParamRun_EDE9FC + 4644
.set SeqMixParam_Entry_174, SndParamRun_EDE9FC + 4662
.set SeqMixParam_Entry_175, SndParamRun_EDE9FC + 4680
.set SeqMixParam_Entry_176, SndParamRun_EDE9FC + 4698
.set SeqMixParam_Entry_177, SndParamRun_EDE9FC + 4716
.set SeqMixParam_Entry_178, SndParamRun_EDE9FC + 4734
.set SeqMixParam_Entry_179, SndParamRun_EDE9FC + 4752
.set SeqMixParam_Entry_180, SndParamRun_EDE9FC + 4770
.set SeqMixParam_Entry_181, SndParamRun_EDE9FC + 4788
.set SeqMixParam_Entry_182, SndParamRun_EDE9FC + 4806
.set SeqMixParam_Entry_183, SndParamRun_EDE9FC + 4824
.set SeqMixParam_Entry_184, SndParamRun_EDE9FC + 4842
.set SeqMixParam_Entry_185, SndParamRun_EDE9FC + 4860
.set SeqMixParam_Entry_186, SndParamRun_EDE9FC + 4878
.set SeqMixParam_Entry_187, SndParamRun_EDE9FC + 4896
.set SeqMixParam_Entry_188, SndParamRun_EDE9FC + 4914
.set SeqMixParam_Entry_189, SndParamRun_EDE9FC + 4932
.set SeqMixParam_Entry_190, SndParamRun_EDE9FC + 4950
.set SeqMixParam_Entry_191, SndParamRun_EDE9FC + 4968
.set SeqMixParam_Entry_192, SndParamRun_EDE9FC + 4986
.set SeqMixParam_Entry_193, SndParamRun_EDE9FC + 5004
.set SeqMixParam_Entry_194, SndParamRun_EDE9FC + 5022
.set SeqMixParam_Entry_195, SndParamRun_EDE9FC + 5040
.set SeqMixParam_Entry_196, SndParamRun_EDE9FC + 5058
.set SeqMixParam_Entry_197, SndParamRun_EDE9FC + 5076
.set SeqMixParam_Entry_198, SndParamRun_EDE9FC + 5094
.set SeqMixParam_Entry_199, SndParamRun_EDE9FC + 5112
.set SeqMixParam_Entry_200, SndParamRun_EDE9FC + 5130
.set SeqMixParam_Entry_201, SndParamRun_EDE9FC + 5148
.set SeqMixParam_Entry_202, SndParamRun_EDE9FC + 5166
.set SeqMixParam_Entry_203, SndParamRun_EDE9FC + 5184
.set SeqMixParam_Entry_204, SndParamRun_EDE9FC + 5202
.set SeqMixParam_Entry_205, SndParamRun_EDE9FC + 5220
.set SeqMixParam_Entry_206, SndParamRun_EDE9FC + 5238
.set SeqMixParam_Entry_207, SndParamRun_EDE9FC + 5256
.set SeqMixParam_Entry_208, SndParamRun_EDE9FC + 5274
.set SeqMixParam_Entry_209, SndParamRun_EDE9FC + 5292
.set SeqMixParam_Entry_210, SndParamRun_EDE9FC + 5310
.set SeqMixParam_Entry_211, SndParamRun_EDE9FC + 5328
.set SeqMixParam_Entry_212, SndParamRun_EDE9FC + 5346
.set SeqMixParam_Entry_213, SndParamRun_EDE9FC + 5364
.set SeqMixParam_Entry_214, SndParamRun_EDE9FC + 5382
.set SeqMixParam_Entry_215, SndParamRun_EDE9FC + 5400
.set SeqMixParam_Entry_216, SndParamRun_EDE9FC + 5418
.set SeqMixParam_Entry_217, SndParamRun_EDE9FC + 5436
.set SeqMixParam_Entry_218, SndParamRun_EDE9FC + 5454
.set SeqMixParam_Entry_219, SndParamRun_EDE9FC + 5472
.set SeqMixParam_Entry_220, SndParamRun_EDE9FC + 5490
.set SeqMixParam_Entry_221, SndParamRun_EDE9FC + 5508
.set SeqMixParam_Entry_222, SndParamRun_EDE9FC + 5526
.set SeqMixParam_Entry_223, SndParamRun_EDE9FC + 5544
.set SeqMixParam_Entry_224, SndParamRun_EDE9FC + 5562
.set SeqMixParam_Entry_225, SndParamRun_EDE9FC + 5580
.set SeqMixParam_Entry_226, SndParamRun_EDE9FC + 5598
.set SeqMixParam_Entry_227, SndParamRun_EDE9FC + 5616
.set SeqMixParam_Entry_228, SndParamRun_EDE9FC + 5634
