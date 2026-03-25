; Extension Device Data Tables & NAKA Widget Descriptors
; Extension subsystem (codename "TOSHI"): chord type tables, MSP configuration,
; accompaniment parameters, and UI widget descriptors for expansion devices

ExtData_ChordTypeTable_Top:
	.long SeqVoice_ValidateState_StoreChannel
	.byte 0xed
	nop
	.byte 0xee
	nop
	.long NakaData_PartConfig
	.long SepaOut_FormatData_Tail
	.byte 0xed
	nop
	.byte 0xdc
	nop
	.byte 0xed
	nop
	.byte 0xd6
	nop
	.byte 0xed
	nop
	.byte 0xd0
	nop
	.byte 0xed
	nop
	.byte 0xca
	nop
	.byte 0xed
	nop
	.byte 0xc4
	nop
	.byte 0xed
	nop
	.byte 0xbe
	nop
	.byte 0xed
	nop
	.byte 0xb8
	nop
	.byte 0xed
	nop
	.byte 0xb2
	nop
ExtData_ChordTypeTable_Mid:
	.byte 0xed
	nop
	.byte 0xac
	nop
	.byte 0xed
	nop
	.byte 0xa6
	nop
	.byte 0xed
	nop
	.byte 0xa0
	nop
	.byte 0xed
	nop
	.byte 0x9a
	nop
	.byte 0xed
	nop
	.byte 0x94
	nop
	.byte 0xed
	nop
	.byte 0x8e
	nop
	.byte 0xed
	nop
	.byte 0x88
	nop
	.byte 0xed
	nop
	.byte 0x82
	nop
	.byte 0xed
	nop
	jrl	nov, -4864
	nop
	jrl	z, -4864
	nop
	jrl	f, -4864
	nop
	jr	gt, 0
	.byte 0xed
ExtData_ChordType_NullByte:
	nop
ChordTypeStr_Blank_0:	aligned_string "     "
ChordTypeStr_Blank_1:	aligned_string "     "
ChordTypeStr_Blank_2:	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	aligned_string "     "
	aligned_string "     "
	jr	pl, 0x61
	jr	ov, 100
	push	xbc
	nop
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
ChordTypeStr_69:	jr	pl, 0x36
	push	xbc
	ldb	w, 32
	nop
	aligned_string "m79  "
	aligned_string "m ~a05 "
	aligned_string "m6   "
	aligned_string "69   "
	popw	iy
	.byte 0x37
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
	jr	pl, 0x69
	jr	nz, 32
	ldb	w, 0
	aligned_string "aug  "
	aligned_string "Maj7 "
	aligned_string "7    "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	aligned_string "     "
	or	(xwa+2), iy
	nop
	.byte 0x94
	push	sr
	.byte 0xed
	nop
	or	(xiz+2), e
	nop
	or	(xde+2), e
	nop
	.byte 0x84
	push	sr
	.byte 0xed
	nop
	.byte 0x80
	push	sr
	.byte 0xed
	nop
	jrl	nov, -4862
	nop
	jrl	z, -4862
	nop
	jrl	le, -4862
	nop
	jr	nov, 2
	.byte 0xed
	nop
	jr	2
	.byte 0xed
	nop
	jr	le, 2
	.byte 0xed
	nop
	pop	xiz
	push	sr
	.byte 0xed
	nop
	pop	xde
	push	sr
	.byte 0xed
	nop
	.byte 0x56
	push	sr
	.byte 0xed
	nop
	.byte 0x52
	push	sr
	.byte 0xed
	nop
	ldb	w, 32
	nop
	swi	7
	ldb	w, 32
	nop
	swi	7
	ldb	w, 32
	nop
	swi	7
	.byte 0x42
	ldb	w, 0
	swi	7
	aligned_string "B~a0"
	.byte 0x41
	ldb	w, 0
	swi	7
	aligned_string "A~a0"
	ld	xsp, 0x47ff0020
	jrl	nz, 12385
	nop
	swi	7
	ld	xiz, 0x45ff0020
	ldb	w, 0
	swi	7
	aligned_string "E~a0"
	ld	xix, 0x44ff0020
	jrl	nz, 12385
	nop
	swi	7
	ld	xhl, 0x20ff0020
	ldb	w, 0
	swi	7
	ldb	b, 3
	.byte 0xed
	nop
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
	ldb	w, 32
	nop
	swi	7
NoteStr0_Blank_1:
	ldb	w, 32
	nop
	swi	7
NoteStr0_Blank_2:
	ldb	w, 32
	nop
	swi	7
NoteStr0_B:
	.byte 0x42
	ldb	w, 0
	swi	7
NoteStr0_ASharp:	aligned_string "A~9e"
NoteStr0_A:
	.byte 0x41
	ldb	w, 0
	swi	7
NoteStr0_GSharp:	aligned_string "G~9e"
NoteStr0_G:
	.byte 0x47
	ldb	w, 0
	swi	7
NoteStr0_FSharp:	aligned_string "F~9e"
NoteStr0_F:	aligned_string "F "
NoteStr0_E:
	.byte 0x45
	ldb	w, 0
	swi	7
NoteStr0_DSharp:	aligned_string "D~9e"
NoteStr0_D:
	.byte 0x44
	ldb	w, 0
	swi	7
NoteStr0_CSharp:	aligned_string "C~9e"
NoteStr0_C:
	.byte 0x43
	ldb	w, 0
	swi	7
NoteStr0_Blank_3:
	ldb	w, 32
	nop
	swi	7


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
	ldb	w, 32
	nop
	swi	7
NoteStr1_Blank_1:
	ldb	w, 32
	nop
	swi	7
NoteStr1_Blank_2:
	ldb	w, 32
	nop
	swi	7
NoteStr1_B:
	.byte 0x42
	ldb	w, 0
	swi	7
NoteStr1_AFlat:
	ld	xbc, 0x65397e
	swi	7
NoteStr1_A:
	.byte 0x41
	ldb	w, 0
	swi	7
NoteStr1_ASharp:	aligned_string "A~a0"
NoteStr1_G:	aligned_string "G "
NoteStr1_FSharp:	aligned_string "F~9e"
NoteStr1_F:
	.byte 0x46
	ldb	w, 0
	swi	7
NoteStr1_E:
	.byte 0x45
	ldb	w, 0
	swi	7
NoteStr1_DSharp:	aligned_string "D~9e"
NoteStr1_D:	aligned_string "D "
NoteStr1_CSharp:	aligned_string "C~9e"
NoteStr1_C:
	.byte 0x43
	ldb	w, 0
	swi	7
NoteStr1_Blank_3:
	ldb	w, 32
	nop
	swi	7


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
	ldb	w, 32
	nop
	swi	7
NoteStr2_Blank_1:
	ldb	w, 32
	nop
	swi	7
NoteStr2_Blank_2:
	ldb	w, 32
	nop
	swi	7
NoteStr2_B:
	.byte 0x42
	ldb	w, 0
	swi	7
NoteStr2_BFlat:	aligned_string "B~a0"
NoteStr2_A:	aligned_string "A "
NoteStr2_GSharp:	aligned_string "G~9e"
NoteStr2_G:
	.byte 0x47
	ldb	w, 0
	swi	7
NoteStr2_FSharp:	aligned_string "F~9e"
NoteStr2_F:
	.byte 0x46
	ldb	w, 0
	swi	7
NoteStr2_E:	aligned_string "E "
NoteStr2_DSharp:	aligned_string "D~9e"
NoteStr2_D:
	.byte 0x44
	ldb	w, 0
	swi	7
NoteStr2_CSharp:	aligned_string "C~9e"
NoteStr2_C:
	.byte 0x43
	ldb	w, 0
	swi	7
NoteStr2_Blank_3:
	ldb	w, 32
	nop
	swi	7


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
	ldb	w, 32
	nop
	swi	7
NoteStr3_Blank_1:
	ldb	w, 32
	nop
	swi	7
NoteStr3_Blank_2:
	ldb	w, 32
	nop
	swi	7
NoteStr3_B:
	.byte 0x42
	ldb	w, 0
	swi	7
NoteStr3_AFlat:	aligned_string "A~9e"
NoteStr3_A:
	.byte 0x41
	ldb	w, 0
	swi	7
NoteStr3_GSharp:	aligned_string "G~9e"
NoteStr3_G:
	.byte 0x47
	ldb	w, 0
	swi	7
NoteStr3_FSharp:	aligned_string "F~9e"
NoteStr3_F:
	.byte 0x46
	ldb	w, 0
	swi	7
NoteStr3_E:
	.byte 0x45
	ldb	w, 0
	swi	7
NoteStr3_EFlat:	aligned_string "E~a0"
NoteStr3_D:
	.byte 0x44
	ldb	w, 0
	swi	7
NoteStr3_CSharp:	aligned_string "C~9e"
NoteStr3_C:
	.byte 0x43
	ldb	w, 0
	swi	7
NoteStr3_Blank_3:
	ldb	w, 32
	nop
	swi	7
	ccf
	halt
	.byte 0xed
	nop
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
	.byte 0xe6, 0x06, 0xed
	nop
	jrl	nz, -4858
	nop
	push_f
	.byte 0x06, 0xed
	nop
	or	(xix+5), xiy
	nop
	.byte 0xa4
	halt
	.byte 0xed
	nop
	ldw	iz, 0xed05
	nop
Str_InitSettingWarn_ID:	aligned_string "Menggunakan Initial Setting akan menghapus semua data yang telah diset dengan susunan data asli dari pabrik."
Str_InitSettingWarn_IT:	aligned_string "Italian"
	aligned_string "El uso del ajuste inicial hará que se reemplacen los datos actuales por los ajustes originales de fá brica!"
	aligned_string "La procédure d'initialisation va remplacer tous les réglages effectués par les présélections d'usine"
	.byte 0x44, 0x75
	aligned_string "rch das Initialisieren werden alle aktuellen Einstellungen wieder in den Werkszustand zurückversetzt."
	aligned_string "Using Initial Setting will replace any current data with the original factory settings!"
	or	(xwa+7), xiy
	nop
	.byte 0x96
	reti
	.byte 0xed
	nop
	.byte 0x86
	reti
	.byte 0xed
	nop
	jrl	-4857
	nop
	jrl	f, -4857
	nop
	.byte 0x56
	reti
	.byte 0xed
	nop
Str_AreYouSure_ID:	aligned_string "Apakah Anda sudah yakin ?"
Str_AreYouSure_IT:	aligned_string "Italian"
	.byte 0xbf, 0x45
	jrl	ule, -7820
	aligned_string " seguro?"
	.byte 0x45, 0x74
	.ascii "es vous s"
	swi	3
	jrl	le, 63
	swi	7
	aligned_string "SIND SIE SICHER?"
	aligned_string "Are You Sure?"
	.byte 0x04
	ldwio	237, 0x8e00
	push	237
	nop
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
	jr	ugt, 46
	nop
	swi	7
	aligned_string "                               Resets the PERFORMANCE or individual sections to the original factory settings."
	.byte 0x56
	pushw	237
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
	.byte 0xda
	incf
	.byte 0xed
	nop
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
	.byte 0xef
	push	sr
	call	0x02ef05
	call	0x082705
	swi	5
	reti
	swi	5
	reti
	ldb	w, 0
	aligned_string "                                "
	ldb	w, 0
	.zero 8
	.byte 0xf1, 0x01, 0xf1, 0x01
	stdi8	0x5901, 101
	.byte 0x01
	pop	xbc
	nop
	jr	mi, 1
	rcf
	pop	sr
	swi	0
	push	sr
	swi	0
	push	sr
	ldb	w, 0
	aligned_string "                "
	ldb	w, 0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jr	gt, 1
	nop
	nop
	nop
	nop
	aligned_string "%d/%d"
	.byte 0xcc, 0x01
	swi	2
	push	sr
	.byte 0xcc, 0x01
	swi	2
	push	sr
	pushw	bc
	halt
	scf
	halt
	scf
	halt
	ldb	w, 0
	aligned_string "                "
	ldb	w, 0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop	xiz
	.byte 0x01
	nop
	nop
	nop
	nop
	ldb	e, 115
	push	xde
	nop
	aligned_string "                 "
	ldb	w, 0x20
	ldb	w, 32
	ldb	w, 0
	ldb	e, 115
	push	xde
	nop
	aligned_string "TEMPO"
	ldb	e, 0x73
	push	xde
	nop
	aligned_string "TEMPO"
	ldb	e, 115
	nop
	swi	7
	pop	xde
	halt
	jr	gt, 7
	pop	xde
	halt
	jr	gt, 7
	.byte 0xae
	pushw	2966
	.byte 0x96
	pushw	32
	aligned_string "                                "
	ldb	w, 0
	aligned_string "                                "
	ldb	w, 0
	aligned_string "                                "
	ldb	w, 0
	aligned_string "                                "
	aligned_string "                                "
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0xdb
	push	sr
	.byte 0xdb
	push	sr
	.byte 0xdb
	push	sr
	jr	gt, 0
	ldb	l, 1
	jr	gt, 0
	ldb	l, 1
	ldw	ix, 3074
	push	sr
	incf
	push	sr
	ldb	e, 51
	jr	ov, 0
	popw	sp
	popw	iz
	ldb	w, 0
	popw	sp
	ld	xiz, 0x33250046
	jr	ov, 0
	ldb	e, 51
	jr	ov, 0
	ldb	e, 51
	jr	ov, 0
	popw	sp
	ld	xiz, 0x4e4f0046
	ldb	w, 0
	ldb	e, 51
	jr	ov, 0
	ldb	e, 51
	jr	ov, 0
	nop
	nop
	jrl	nov, 0
	nop
	jrl	nov, -2048
	push	sr
	swi	6
	nop
	swi	6
	nop
	jr	gt, 0
	ret
	.byte 0x01
	jr	gt, 0
	ret
	.byte 0x01
	push	sr
	push	sr
	.byte 0xda, 0x01, 0xda, 0x01
	nop
	.byte 0x90, 0x91, 0xb3, 0xb4, 0xc0
	andda8	d, 0xc3c2
	.byte 0xc5, 0xc6, 0xc7, 0xb2, 0x88, 0x92, 0x93, 0x94
	.byte 0x95
	ld	xwa, 0x98979996
	.byte 0xad, 0xb0, 0xb1, 0xb8, 0xb9, 0xb6, 0xb7
	swi	7
	.byte 0xdc
	scf
	.byte 0xed
	nop


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
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	nop
	nop
	pushw	sp
	push	sr
	nop
	nop
	pushw	sp
	push	sr
	.byte 0xea
	ldio	91, 4
	pop	xhl
	.byte 0x04
	di
	nop
	nop
	di
	di
	di
	di
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
	popw	sp
	popw	iz
	pushw	sp
	popw	sp
	ld	xiz, 0x25ff0046
	jrl	ule, -256
	aligned_string "PAGE 2/3"
	ldb	e, 115
	nop
	swi	7
	aligned_string "PAGE 3/3"
	.byte 0xbe
	push	sr
	.byte 0xa7
	pop	sr
	.byte 0xbe
	push	sr
	.byte 0xa7
	pop	sr
	popw	iz
	halt
	push	w
	push	w
	nop
	pushw	bc
	nop
	nop
	.byte 0x01
	pushw	bc
	nop
	nop
	.byte 0x04
	pushw	bc
	nop
	nop
	push	sr
	pushw	bc
	nop
	nop
	pop	sr
	pushw	bc
	nop
	nop
	ldwio	41, 0
	pushw	41
	nop
	incf
	pushw	bc
	nop
	nop
	decf
	pushw	bc
	nop
	nop
	ret
	pushw	bc
	nop
	nop
	halt
	pushw	bc
	nop
	nop
	reti
	pushw	bc
	nop
	nop
	ldio	41, 0
	nop
	retd	41
	nop
	rcf
	pushw	bc
	nop
	nop
	push	41
	nop
	nop
	.byte 0x06
	pushw	bc
	nop
	nop
	scf
	pushw	bc
	nop
	nop
	popw	sp
	ld	xiz, 0x4e4f0046
	ldb	w, 0
	popw	sp
	ld	xiz, 0x4e4f0046
	ldb	w, 0
	popw	sp
	popw	iz
	ldb	w, 0
	popw	sp
	ld	xiz, 0x4e4f0046
	ldb	w, 0
	popw	sp
	ld	xiz, 0x20200046
	ldb	w, 0
	nop
	nop
	jrl	nov, 0
	nop
	jrl	nov, -26880
	push	sr
	swi	2
	nop
	swi	2
	nop
	.byte 0xd5
	nop
	jrl	ge, -11007
	nop
	jrl	ge, 27905
	push	sr
	.byte 0x45
	push	sr
	.byte 0x45
	push	sr
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
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	ldb	e, 115
	nop
	swi	7
	nop
	nop
	ldw	iz, 1
	nop
	ldw	iz, 0xbc01
	halt
	.byte 0x83
	push	sr
	.byte 0x83
	push	sr
	aligned_string "PAGE"
	aligned_string "Memory data "
	ldb	w, 32
	nop
	swi	7
	ldb	w, 32
	nop
	swi	7
	.byte 0xa4
	nop
	.byte 0xa4
	nop
	.byte 0xb9
	nop
	.byte 0xb9
	nop
	.byte 0xb9
	nop
	.byte 0xa8
	nop
	.byte 0xa4
	nop
	.byte 0xaf
	nop
	ld	(xiy), 0
	nop
	aligned_string "        "
	aligned_string "%d-%d:"
	ldb	e, 100
	push	xde
	nop
	aligned_string "PAGE 1/3"
	aligned_string "BANK%2d:"
	ldb	e, 100
	push	xde
	nop
	.byte 0x01
	nop
	.byte 0x01
	nop
	ldwio	0, 10
	ldwio	0, 4
	ldwio	0, 13
	.byte 0x01
	nop
	nop
	nop
	nop
	swi	7
	.byte 0x53
	popw	sp
	.byte 0x55
	popw	iz
	ld	xix, 0x3a642500
	nop
	ldb	e, 100
	push	xde
	nop
	aligned_string "PAGE %d/%d"
	ldb	e, 100
	push	xde
	nop
	ldb	e, 100
	push	xde
	nop
ParamStr_Table_04:
	.long VariationStr_V1
	.long VariationStr_V2
	.long VariationStr_V3
	.long VariationStr_V4
VariationStr_V4:
	.byte 0x56
	ldw	ix, 0xff00
VariationStr_V3:
	.byte 0x56
	ldw	hl, 0xff00
VariationStr_V2:
	.byte 0x56
	ldw	de, 0xff00
VariationStr_V1:
	.byte 0x56
	ldw	bc, 0xff00
	aligned_string "RHYTHM"
	ldb	e, 115
	push	xde
	nop
	ldb	e, 115
	push	xde
	nop
	ldb	e, 100
	push	xde
	nop
	ldb	e, 100
	push	xde
	nop
	ldb	e, 115
	push	xde
	nop
	aligned_string "PAGE %d/%d"
	ldb	e, 100
	push	xde
	nop
	ldb	e, 115
	push	xde
	nop
	ldb	e, 100
	push	xde
	nop
	ldb	e, 100
	push	xde
	nop
	push	sr
	nop
	push	xiz
	nop
	pushw	iz
	.byte 0x01
	pop	xiy
	nop
	push	sr
	nop
	jr	le, 0
	push	xix
	.byte 0x01, 0x81
	nop
	push	sr
	nop
	.long NakaInst_Param_EmptyStr
	.byte 0x99
	nop
	push	sr
	nop
	.long NakaData_DescriptorPad_ZeroA
	.byte 0xad
	nop
	push	sr
	nop
	.byte 0xae
	nop
	ei	1
	.byte 0xc1
	nop
	push	sr
	nop
	xorda8_24	e, 0x011600
	nop
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
	.byte 0x42
	ldb	w, 0
	swi	7
TransposeNoteStr_BFlat:	aligned_string "B~a0"
TransposeNoteStr_A:
	.byte 0x41
	ldb	w, 0
	swi	7
TransposeNoteStr_AFlat:	aligned_string "A~a0"
TransposeNoteStr_G:
	.byte 0x47
	ldb	w, 0
	swi	7
TransposeNoteStr_FSharp:	aligned_string "F~9e"
TransposeNoteStr_F:
	.byte 0x46
	ldb	w, 0
	swi	7
TransposeNoteStr_E:
	.byte 0x45
	ldb	w, 0
	swi	7
TransposeNoteStr_EFlat:	aligned_string "E~a0"
TransposeNoteStr_D:
	.byte 0x44
	ldb	w, 0
	swi	7
TransposeNoteStr_DFlat:	aligned_string "D~a0"
TransposeNoteStr_C:
	.byte 0x43
	ldb	w, 0
	swi	7
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
	nop
	nop
	.byte 0x56
	nop
	.byte 0xae
	nop
	.byte 0xdd
	nop
	pushw	0x3901
	.byte 0x01
	aligned_string "DEFAULT"
	ldb	w, 0x55
	aligned_string "SER  "
	ldb	w, 0x45
	aligned_string "RROR "
	.byte 0x9c
	nop
	.byte 0x9c
	nop
	jr	f, 0
	jr	f, 0
	jr	f, 0
	.byte 0x9c
	nop
	jr	f, 0
	.byte 0xa0
	nop
	.byte 0xa7
	nop
	jr	ov, 0x00
	aligned_string "DEFAULT"
	aligned_string " USER  "
	aligned_string " ERROR "
	ldw	bc, 0x3100
	nop
	ld	xwa, 0x40004000
	nop
	ldw	bc, 0x4000
	nop
	ldw	iy, 0x3c00
	nop
	nop
	nop
	aligned_string "DEFAULT"
	ldb	w, 0x55
	aligned_string "SER  "
	ldb	w, 0x45
	aligned_string "RROR "
	ldw	bc, 0x3100
	nop
	ld	xwa, 0x40004000
	nop
	ldw	bc, 0x4000
	nop
	ldw	iy, 0x3c00
	nop
	nop
	nop
	.byte 0xca, 0x1a, 0xed
	nop
	jrl	gt, -4838
	nop
	ldw	iz, 0xed1a
	nop
	.byte 0xd8
	pop_f
	.byte 0xed
	nop
	.byte 0xd0
	pop_f
	.byte 0xed
	nop
	popw	de
	pop_f
	.byte 0xed
	nop
	aligned_string "USER INITIAL akan menggantikan penggunaan kertas tempel (stiker) yang sekarang dengan sticker/kertas tempel yg hitam-licin dan rata!"
	aligned_string "Italian"
	.byte 0xa1
	.ascii "El USER INITIAL cambiará el patrÓn de fondo actual por un \"Plain Black\" (negro sin dise"
	.byte 0xf1
	jr	nc, 41
	ldb	a, 0
	swi	7
	.byte 0x55, 0x53
	aligned_string "ER INITIAL va remplacer votre fond de l'écran par un fond noir !"
	aligned_string "USER INITIAL ersetzt das aktuelle Hintergrundbild durch eine schwarze Fläche !"
	.asciz "USER INITIAL will replace the current user wallpaper with the \"Plain Black\" wallpaper!"
	swi	7
	nop
	nop
	ldb	h, 0
	pushw	ix
	nop
	ldw	de, 6656
	nop
	ldio	0, 14
	nop
	ldb	w, 0
	push_a
	nop
	nop
	nop
	ldio	0, 8
	nop
	ldio	0, 8
	nop
	.byte 0x08
	nop


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
	.byte 0x42
	ldb	w, 0
	swi	7
SplitNoteStr_BFlat:	aligned_string "B~a0"
SplitNoteStr_A:
	.byte 0x41
	ldb	w, 0
	swi	7
SplitNoteStr_AFlat:	aligned_string "A~a0"
SplitNoteStr_G:
	.byte 0x47
	ldb	w, 0
	swi	7
SplitNoteStr_FSharp:	aligned_string "F~9e"
SplitNoteStr_F:	aligned_string "F "
SplitNoteStr_E:
	.byte 0x45
	ldb	w, 0
	swi	7
SplitNoteStr_EFlat:	aligned_string "E~a0"
SplitNoteStr_D:
	.byte 0x44
	ldb	w, 0
	swi	7
SplitNoteStr_DFlat:	aligned_string "D~a0"
SplitNoteStr_C:
	ld	xhl, 0xeaff0020
	jp	NakaData_PartConfig
	jp	Bitmap_SplitPoint_Gb_0x2B
	jp	Bitmap_Dredt0d_0xA8D
	jp	SepaOut_FormatData_Tail
	jp	FILETYPE_SIG_TABLE_2_0x15
	jp	0xde00ed
	jp	0xdc00ed
	jp	0xda00ed
	jp	0xd800ed
	jp	0xd600ed
	.byte 0x1b, 0xed
	nop
OctaveDigitStr_8:
	push	xwa
	nop
	.byte 0x37
	nop
OctaveDigitStr_6:
	.byte 0x36
	nop
OctaveDigitStr_5:
	.byte 0x35
	nop
OctaveDigitStr_4:
	ldw	ix, 0x3300
	nop
OctaveDigitStr_2:
	.byte 0x32
	nop
OctaveDigitStr_1:
	.byte 0x31
	nop
OctaveDigitStr_0A:
	ldw	wa, 0x3000
	nop
OctaveDigitStr_0B:
	.byte 0x30
	nop
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
	.byte 0x46
	ldb	w, 0
	swi	7
KeyScaleNoteStr_E:	aligned_string "E "
KeyScaleNoteStr_EFlat:	aligned_string "E~a0"
KeyScaleNoteStr_D:
	.byte 0x44
	ldb	w, 0
	swi	7
KeyScaleNoteStr_DFlat:	aligned_string "D~a0"
KeyScaleNoteStr_C:
	.byte 0x43
	ldb	w, 0
	swi	7
KeyScaleNoteStr_B:	aligned_string "B "
KeyScaleNoteStr_BFlat:	aligned_string "B~a0"
KeyScaleNoteStr_A:
	.byte 0x41
	ldb	w, 0
	swi	7
KeyScaleNoteStr_AFlat:	aligned_string "A~a0"
KeyScaleNoteStr_G:	.byte 0x47, 0x20, 0x00, 0xff, 0x20, 0x20
	ldb	w, 32
	nop
	swi	7
	aligned_string "<%s>"
	ldb	e, 115
	nop
	swi	7
	jr	nc, 110
	nop
	swi	7
	ldb	w, 32
	nop
	swi	7
	.byte 0xc3, 0xe0
	swi	3
	nop
	ldw	iy, 0xfbd2
	nop
	ldw	bc, 0xfbd1
	nop
	swi	3
	.byte 0xd2
	swi	3
	nop
	popw	wa
	jrl	nc, 251
	cp	(xix+127), c
	nop
	.byte 0xa2
	jrl	nc, 251
	.byte 0xb8
	jrl	nc, 251
	.byte 0xbb
	jrl	nc, 251
	scc8	nc, d
	swi	3
	nop
	scc16	nc, iy
	swi	3
	nop
	jr	lt, -86
	swi	3
	nop
	retd	0xfbb0
	nop
	.byte 0x37
	cpdm8	251, b
	.byte 0xc6
	swi	3
	nop
	ldb	e, 128
	swi	3
	nop
	.byte 0xd5, 0x88
	swi	3
	nop
	cp	(xsp-114), c
	nop
	adc	xiy, xix
	swi	3
	nop
	.byte 0xc1
	cp	(xhl), xhl
	nop
	.byte 0xe5
	cp	(xiz), xhl
	nop
	sub	xiz, xix
	swi	3
	nop
	popw	de
	jrl	nz, 251
	jrl	c, -1154
	nop
	.byte 0xa4
	jrl	nz, 251
	.byte 0xd1
	jrl	nz, 251
	.byte 0x01
	cpdm32	251, xwa
	.byte 0xcc
	swi	3
	nop
	swi	6
	jrl	nz, 251
	ld	xiy, 0x3700fc24
	ldb	e, 252
	nop
	.byte 0xb2
	ldb	e, 252
	nop
	pushw	iy
	ldb	h, 252
	nop
	reti
	ldb	l, 252
	nop
	ld	xhl, 0x5900fc27
	ldb	l, 252
	nop
	jr	pl, 39
	swi	4
	nop
	jr	gt, 39
	swi	4
	nop
	ldw	de, 0xfc27
	nop
	.byte 0xee
	jrl	nc, 251
	swi	7
	jrl	nc, 251
	rcf
	cp	(xwa), c
	nop
	nop
	nop
	nop
	nop
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
	nop
	swi	7
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
	ldw	de, 0xed21
	nop
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
	jr	nz, 0x6f
	aligned_string "wswno"
	aligned_string "varisu"
	jrl	f, 29281
	jrl	ov, -256
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
	pushw	iz
	ldb	d, 237
	nop
	ldb	d, 36
	.byte 0xed
	nop
	calr	60708
	nop
	ex_ff
	ldb	d, 237
	nop
	ldwio	36, 237
	swi	6
	ldb	c, 237
	nop
	.byte 0xee
	ldb	c, 237
	nop
	.byte 0xe2
	ldb	c, 237
	nop
	andda16_24	ix, 0xed23
	ldb	c, 237
	nop
	.byte 0xc2
	ldb	c, 237
	nop
MstStyleAlpGrid_Empty:
	nop
	swi	7
MstStyleAlpGrid_nowttlselsong:	aligned_string "nowttlselsong"
MstStyleAlpGrid_nowalphselsong:	aligned_string "nowalphselsong"
MstStyleAlpGrid_nowalphpage:	aligned_string "nowalphpage"
MstStyleAlpGrid_nowalphmaxpage:	jr	nz, 0x6f
	aligned_string "walphmaxpage"
	aligned_string "nowalphdtno"
	aligned_string "nowalphtop"
	aligned_string "nowalph"
	jr	z, 0x75
	jr	nz, 99
	nop
	swi	7
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
	ex_ff
	ldb	e, 237
	nop
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
	jr	z, 0x75
	jr	nz, 99
	nop
	swi	7
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
	.byte 0xbe
	ldb	h, 237
	nop
	.byte 0xb4
	ldb	h, 237
	nop
	or	(xiz+38), xiy
	nop
	or	(xiz+38), iy
	nop
	or	(xix+38), e
	nop
	jrl	nov, -4826
	nop
	jrl	gt, -4826
	nop
MstSong2Grid_Empty:
	nop
	swi	7
MstSong2Grid_nowsongctgpage:	aligned_string "nowsongctgpage"
MstSong2Grid_nowsongctgmaxpage:	aligned_string "nowsongctgmaxpage"
MstSong2Grid_nowsongctgdtno:	jr	nz, 0x6f
	aligned_string "wsongctgdtno"
	jr	z, 117
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
	jr	nz, 0x6f
	aligned_string "wsongsubctgmaxpage"
	aligned_string "nowsongsubctgdtno"
	jr	z, 0x75
	jr	nz, 99
	nop
	swi	7
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
	jr	gt, 0x00
	aligned_string "AcDispTimeSetGridBox"
NakaDesc_AcDispTimeSetGridBox:
	pop	xwa
	pop	xwa
	jr	gt, 0
NakaInst_AcDispTimeSetGridBox:	aligned_string "AcPmExpFilterGridBox"
NakaDesc_AcPmExpFilterGridBox:
	pop	xwa
	pop	xwa
	jr	gt, 0
NakaInst_AcPmExpFilterGridBox:	aligned_string "AcFSWAssGridBox"
NakaDesc_AcFSWAssGridBox:
	pop	xwa
	pop	xwa
	jr	gt, 0x00
	aligned_string "AcTchSensGridBox"
	jr	nz, 0
	aligned_string "IvMstStyleWindowPgCtl"
	jr	nz, 0
	aligned_string "IvPmemWindowPageCtl"
	jr	nz, 0x00
	aligned_string "IvWindowPageControl"
NakaDesc_IvWindowPageControl:	aligned_string "kc^nn"
NakaInst_IvWindowPageControl:	aligned_string "PmemModeBox"
NakaDesc_PmemModeBox:	aligned_string "kc^nn"
NakaInst_PmemModeBox:	aligned_string "MsaModeScreen"
NakaDesc_MsaModeScreen:
	jr	gt, 0x72
	nop
	swi	7
	aligned_string "AcPmBkEditBox"
NakaDesc_AcPmBkEditBox:	aligned_string "kc^nnn"
NakaInst_AcPmBkEditBox:	.asciz "PmBankScreen"
	swi	7
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
	.byte 0x1c
	nop
	.byte 0x84
	pushw	iy
	.byte 0xed
	nop
ParamStr_Table_25:
	.long EventNameStr_EV_CHORDDSP
	.long EventNameStr_EV_PMBKNAME
	.long EventNameStr_EV_PMNAME
	.long EventNameStr_EV_FRTPAGECHANGE
	.long EventNameStr_EV_SUBCTSHOW
	.long EventNameStr_EV_PAGESET
	.long EventNameStr_EV_TVARIPAINT
	nop
	nop
	nop
	nop
EventNameStr_EV_TVARIPAINT:	aligned_string "EV_TVARIPAINT"
EventNameStr_EV_PAGESET:	aligned_string "EV_PAGESET"
EventNameStr_EV_SUBCTSHOW:	aligned_string "EV_SUBCTSHOW"
EventNameStr_EV_FRTPAGECHANGE:	aligned_string "EV_FRTPAGECHANGE"
EventNameStr_EV_PMNAME:	aligned_string "EV_PMNAME"
EventNameStr_EV_PMBKNAME:	aligned_string "EV_PMBKNAME"
EventNameStr_EV_CHORDDSP:	aligned_string "EV_CHORDDSP"
	aligned_string "EV_CHORDSHOW"
	ldio	0, 86
	pushw	sp
	.byte 0xed
	nop
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
	nop
	nop
	nop
	nop
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
	.byte 0x1a
	nop
	jr	le, -51
	swi	3
	nop
	.byte 0xe7, 0xe1
	swi	3
	nop
	push_f
	.byte 0xf5
	swi	3
	nop
	.byte 0xc3
	pushw	iz
	swi	4
	nop
	pushw	0xfc2d
	nop
	.byte 0xbb
	pushw	sp
	swi	4
	nop
	ldb	b, 26
	swi	4
	nop
	push	xiy
	.byte 0xdb
	swi	3
	nop
	.byte 0xc3, 0xd5
	swi	3
	nop
	ld	xbc, 0xeb00fbd8
	.byte 0xd4
	swi	3
	nop
	xor	xhl, xix
	swi	3
	nop
	stdi8	0xfbcd, 208
	ld	(xbc-5), 187
	cp	(xsp), xhl
	nop
	cp	(xhl-83), hl
	nop
	popw	ix
	ld	(xhl-5), 18
	.byte 0xc4
	swi	3
	nop
	ldb	a, 128
	swi	3
	nop
	pushw	wa
	cp	(xwa), c
	nop
	sub	xiz, xsp
	swi	3
	nop
	pushw	0xfb8b
	nop
	push	xiy
	cp	(xwa), hl
	nop
	cp	(xiy-105), c
	nop
	.byte 0xe1
	cp	(xiz), xhl
	nop
	sub	xiz, xwa
	swi	3
	nop
	ldb	h, 31
	swi	4
	nop
	ldb	b, 208
	swi	3
	nop
	nop
	nop
	nop
	nop
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
	nop
	swi	7
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
	.byte 0xd9
	ldb	l, 252
	nop
	pop_a
	pushw	wa
	swi	4
	nop
	pop	xiz
	pushw	bc
	swi	4
	nop
	.byte 0x87
	pushw	wa
	swi	4
	nop
	ld	xix, 0xec00fc2a
	pushw	wa
	swi	4
	nop
	.byte 0xca
	pushw	bc
	swi	4
	nop
	popw	iz
	ldw	wa, 252
	.byte 0xb9
	pushw	de
	swi	4
	nop
	nop
	jr	ule, -5
	nop
	.byte 0xbf
	pushw	hl
	swi	4
	nop
	cp	(xhl+44), xix
	nop
	pop	xbc
	ld	(xbc-5), 228
	pushw	ix
	swi	4
	nop
	scf
	.byte 0xcd
	swi	3
	nop
	ld	xiz, 0x4400fc26
	jrl	pl, 251
	jrl	-1155
	nop
	cp	(xix+125), xhl
	nop
	.byte 0xe0
	jrl	pl, 251
	nop
	nop
	nop
	nop
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
	swi	7
.include "ui_widgets/normal_mode_layout.s"
	stib_dsp 0x00, 0x00
	nop
	nop
	.byte 0x04, 0xf4
	pop	sr
	nop
	ldio	244, 3
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	.byte 0x1a
	nop
	swi	7
	swi	7
	ldio	0, 21
	.byte 0x01, 0x80
	nop
	push	xhl
	.byte 0x01, 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	nop
	nop
	reti
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	jp	6400
	ldio	0, 238
	nop
	.byte 0x80
	nop
	push_a
	.byte 0x01, 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	.byte 0x01
	nop
	di


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	.byte 0x1c
	nop
	.byte 0x1a
	nop
	ldio	0, 199
	nop
	.byte 0x80
	nop
	.byte 0xed
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	push	sr
	nop
	halt
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	call	6912
	ldio	0, 160
	nop
	.byte 0x80
	nop
	.byte 0xc6
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	zcf
	nop
	.byte 0x04
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	calr	7168
	nop
	ldio	0, 121
	nop
	.byte 0x80
	nop
	.byte 0x9f
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	rcf
	nop
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	.byte 0x1f
	nop
	call	2048
	.byte 0x52
	nop
	.byte 0x80
	nop
	jrl	-5376
	nop
	reti
	nop
	cpdm8	0xff00, l
	scf
	nop
	push	sr
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	ldb	w, 0
	calr	2048
	nop
	pushw	hl
	nop
	.byte 0x80
	nop
	.byte 0x51
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	ccf
	nop
	.byte 0x01
	nop


	push	xix
	nop
	jr	f, 1
	push_f
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x1f
	nop
	ldio	0, 4
	nop
	.byte 0x80
	nop
	pushw	de
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	push_a
	nop
	nop
	nop


	ldw	iy, 0x6000
	.byte 0x01
	swi	7
	swi	7
	ldb	b, 0
	swi	7
	swi	7
	swi	7
	swi	7
	ldio	0, 0
	nop
	jrl	nc, 16128
	.byte 0x01, 0xef
	nop
	.byte 0xf5
	nop
	nop
	nop
	nop
	nop
	incf
	.byte 0xf4
	pop	sr
	nop
	rcf
	.byte 0xf4
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	a, 0
	swi	7
	swi	7
	ldb	c, 0
	swi	7
	swi	7
	ldio	0, 160
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_I2
	reti
	nop
	cpdm8	0xff00, l
	pop_a
	nop
	.byte 0x04
	nop


	push	xix
	nop
	jr	f, 1
	ldb	a, 0
	swi	7
	swi	7
	ldb	d, 0
	ldb	b, 0
	ldio	0, 121
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_F2
	reti
	nop
	cpdm8	0xff00, l
	ex_ff
	nop
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	a, 0
	swi	7
	swi	7
	ldb	e, 0
	ldb	c, 0
	ldio	0, 82
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_E
	reti
	nop
	cpdm8	0xff00, l
	.byte 0x17
	nop
	push	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	a, 0
	swi	7
	swi	7
	ldb	h, 0
	ldb	d, 0
	ldio	0, 43
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_D
	reti
	nop
	cpdm8	0xff00, l
	.byte 0x1a
	nop
	.byte 0x01
	nop


	push	xix
	nop
	jr	f, 1
	ldb	a, 0
	swi	7
	swi	7
	swi	7
	swi	7
	ldb	e, 0
	ldio	0, 4
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_C
	reti
	nop
	cpdm8	0xff00, l
	jp	0


	ldw	iy, 0x6000
	.byte 0x01
	swi	7
	swi	7
	pushw	wa
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	ldio	0, 0
	nop
	.byte 0x7f
	nop
	.long Naka_PresentationRootState
	stib_dsp 0x00, 0x00
	nop
	nop
	push_a
	.byte 0xf4
	pop	sr
	nop
	push_f
	.byte 0xf4
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	bc
	nop
	swi	7
	swi	7
	ldio	0, 4
	nop
	.byte 0x80
	nop
	pushw	de
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	nop
	nop
	nop
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	de
	nop
	pushw	wa
	nop
	ldio	0, 43
	nop
	.byte 0x80
	nop
	.byte 0x51
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	.byte 0x01
	nop
	.byte 0x01
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	hl
	nop
	pushw	bc
	nop
	ldio	0, 82
	nop
	.byte 0x80
	nop
	jrl	-5376
	nop
	reti
	nop
	cpdm8	0xff00, l
	push	sr
	nop
	push	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	ix
	nop
	pushw	de
	nop
	ldio	0, 121
	nop
	.byte 0x80
	nop
	.byte 0x9f
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	pop	sr
	nop
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	iy
	nop
	pushw	hl
	nop
	ldio	0, 160
	nop
	.byte 0x80
	nop
	.byte 0xc6
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	.byte 0x04
	nop
	.byte 0x04
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	iz
	nop
	pushw	ix
	nop
	ldio	0, 199
	nop
	.byte 0x80
	nop
	.byte 0xed
	nop
	.byte 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	halt
	nop
	halt
	nop


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	pushw	sp
	nop
	pushw	iy
	nop
	ldio	0, 238
	nop
	.byte 0x80
	nop
	push_a
	.byte 0x01, 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	di
	di


	push	xix
	nop
	jr	f, 1
	ldb	l, 0
	swi	7
	swi	7
	swi	7
	swi	7
	pushw	iz
	nop
	ldio	0, 21
	.byte 0x01, 0x80
	nop
	push	xhl
	.byte 0x01, 0xeb
	nop
	reti
	nop
	cpdm8	0xff00, l
	reti
	nop
	reti
	nop


	ldw	iy, 0x6000
	.byte 0x01
	swi	7
	swi	7
	ldw	bc, 0xff00
	swi	7
	swi	7
	swi	7
	ldio	0, 0
	nop
	jrl	nc, 16128
	.byte 0x01, 0xef
	nop
	.byte 0xf5
	nop
	nop
	nop
	nop
	nop
	.byte 0x1c, 0xf4
	pop	sr
	nop
	ldb	w, 244
	pop	sr
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	ldw	de, 0xff00
	swi	7
	ldio	0, 4
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_C
	reti
	nop
	cpdm8	0xff00, l
	ldio	0, 0
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	ldw	hl, 0x3100
	nop
	ldio	0, 43
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_D
	reti
	nop
	cpdm8	0xff00, l
	push	0
	.byte 0x01
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	ldw	ix, 0x3200
	nop
	ldio	0, 82
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_E
	reti
	nop
	cpdm8	0xff00, l
	ldwio	0, 2


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	ldw	iy, 0x3300
	nop
	ldio	0, 121
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_F2
	reti
	nop
	cpdm8	0xff00, l
	pushw	768
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	ldw	iz, 0x3400
	nop
	ldio	0, 160
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_I2
	reti
	nop
	cpdm8	0xff00, l
	incf
	nop
	.byte 0x04
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	.byte 0x37
	nop
	ldw	iy, 2048
	nop
	.byte 0xc7
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_L
	reti
	nop
	cpdm8	0xff00, l
	decf
	nop
	halt
	nop


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	push	xwa
	nop
	ldw	iz, 2048
	nop
	.byte 0xee
	nop
	.byte 0x80
	nop
	.long WidgetName_PtrBlock_M2
	reti
	nop
	cpdm8	0xff00, l
	ret
	nop
	di


	push	xix
	nop
	jr	f, 1
	ldw	wa, 0xff00
	swi	7
	swi	7
	swi	7
	.byte 0x37
	nop
	ldio	0, 21
	.byte 0x01, 0x80
	nop
	.long WidgetName_PtrBlock_N1
	reti
	nop
	cpdm8	0xff00, l
	retd	1792
	nop


	ldw	iy, 0x6000
	.byte 0x01
	swi	7
	swi	7
	push	xde
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	ldio	0, 4
	nop
	.byte 0xbe
	nop
	.long SoundName_ToTheBone
	reti
	nop
	.byte 0xc1
	nop
	nop
	nop
	ldb	d, 244
	pop	sr
	nop
	pushw	wa
	.byte 0xf4
	pop	sr
	nop


	jr	ge, 0
	jr	f, 1
	push	xbc
	nop
	swi	7
	swi	7
	push	xhl
	nop
	swi	7
	swi	7
	ldio	0, 152
	nop
	.byte 0xc8
	nop
	reti
	.byte 0x01, 0xe0
	nop
	ex_ff
	nop
	ldb	b, 1


	jr	ge, 0
	jr	f, 1
	push	xbc
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	push	xde
	nop
	ldio	0, 56
	nop
	.byte 0xcc
	nop
	.byte 0x87
	nop
	.byte 0xdd
	nop
	.byte 0x17
	nop
	ldb	b, 1


	ldw	iy, 0x6000
	.byte 0x01
	swi	7
	swi	7
	push	xiy
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	ldio	0, 4
	nop
	.byte 0xbe
	nop
	.long SoundName_ToTheBone
	reti
	nop
	.byte 0xc1
	nop
	nop
	nop
	pushw	ix
	.byte 0xf4
	pop	sr
	nop
	ldw	wa, 1012
	nop


	jr	ge, 0
	jr	f, 1
	push	xix
	nop
	swi	7
	swi	7
	push	xiz
	nop
	swi	7
	swi	7
	ldio	0, 40
	nop
	.byte 0xcc
	nop
	.byte 0x93
	nop
	.byte 0xdf
	nop
	pop_f
	nop
	ldb	b, 1


	jr	ge, 0
	jr	f, 1
	push	xix
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	push	xiy
	nop
	ldio	0, 160
	nop
	.byte 0xc8
	nop
	rcf
	.byte 0x01, 0xe0
	nop
	push_f
	nop
	ldb	b, 1
.include "ui_widgets/control_menu_screens.s"
	jr	f, 0x01
	reti
	nop
	swi	7
	swi	7
	push	0
	swi	7
	swi	7
	ldio	0, 78
	nop
	.byte 0x80
	nop
	.byte 0xe1
	nop
	.byte 0x92
	nop
	.long Str_ErrorDialog_Caution
	push	sr
	nop
	nop
	nop
	swi	1
	nop
Str_ErrorDialog_Caution:	.asciz "CAUTION!!"	; English text


; ---------------------------------------------------------------------------
; Widget 10 (0x0a): ERROR Message
; "** ERROR in CPU data transmission **"
; Screen group 7, index 10 - Main error message
; ---------------------------------------------------------------------------
ErrorDialog_CPUTransmissionError:
	pushw	hl
	nop
	jr	f, 0x01
	reti
	nop
	swi	7
	swi	7
	ldwio	0, 8
	ldio	0, 14
	nop
	.byte 0x96
	nop
	ldw	bc, 0xa801
	nop
	.byte 0xe4
	jr	z, -19
	nop
	nop
	nop
	nop
	nop
	push	sr
	nop
	aligned_string "** ERROR in CPU data transmission **"


; ---------------------------------------------------------------------------
; Widget 11 (0x0b): Recovery Instruction Line 1
; "Please try turning off and on again."
; Screen group 7, index 11
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine1:
	pushw	hl
	nop
	jr	f, 0x01
	reti
	nop
	swi	7
	swi	7
	pushw	2304
	nop
	ldio	0, 46
	nop
	.byte 0xae
	nop
	push	1
	.byte 0xb8
	nop
	.long Str_ErrorDialog_TryTurningOff
	pop	sr
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
	pushw	hl
	nop
	jr	f, 0x01
	reti
	nop
	swi	7
	swi	7
	incf
	nop
	ldwio	0, 8
	pushw	iz
	nop
	.long TechnichordParam_Block3
	.byte 0xc8
	nop
	jrl	f, -4761
	nop
	pop	sr
	nop
	nop
	nop
	nop
	nop
	aligned_string "If this message appears again,"


; ---------------------------------------------------------------------------
; Widget 13 (end marker 0xffff): Recovery Instruction Line 3
; "this unit needs repairing."
; Screen group 7, final widget
; ---------------------------------------------------------------------------
ErrorDialog_RecoveryLine3:
	pushw	hl
	nop
	jr	f, 0x01
	reti
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	pushw	2048
	nop
	pushw	iz
	nop
	.byte 0xce
	nop
	.byte 0xcd
	nop
	.byte 0xd8
	nop
	ld	(xwa), xsp
	.byte 0xed
	nop
	pop	sr
	nop
	nop
	nop
	nop
	nop
	aligned_string "this unit needs repairing."
.include "ui_widgets/extension_device_screens.s"
	.ascii "!\"#$%%&'()*+,,-./01234456789:;;<=>?@ABCCDEFGHIJKKLMNOPQRRSTUVWXYZZ[\\]^_`abbcdefghiijklmqtx{"
	jrl	nc, 256
	.byte 0x01
	push	sr
	push	sr
	pop	sr
	pop	sr
	.byte 0x04, 0x04
	halt
	halt
	ei	7
	reti
	ldio	8, 9
	push	10
	ldwio	11, 3083
	incf
	decf
	ret
	ret
	retd	4111
	rcf
	scf
	scf
	ccf
	ccf
	zcf
	push_a
	push_a
	pop_a
	pop_a
	ex_ff
	ex_ff
	.byte 0x17, 0x17
	push_f
	push_f
	pop_f
	pop_f
	.byte 0x1a
	jp	0x1c1c1b
	call	0x1e1e1d
	.byte 0x1f, 0x1f, 0x20
	.ascii "!!\"\"##$$%%&''(())**++,,-..//0011223445566778899::;;<<==>>??@@AABBCCDDEEFFGGHHIIJJKKLLMNNOPQQRSTTUVWWXYZZ[\\\\]^__`abbcdeefghijklmmnopqrstuvwxyzz{|}~"
	jrl	nc, -32128
	.byte 0x83, 0x85
	add	(xsp), w
	add	(xde-116), e
	.byte 0x8f, 0x91, 0x92, 0x94, 0x96, 0x97, 0x99, 0x9b
	.byte 0x9d, 0x9f, 0xa1, 0xa3, 0xa5
	sub	(xsp), xbc
	sub	(xhl-83), xsp
	.byte 0xb1, 0xb3, 0xb7, 0xba, 0xbe
	anddm8	0xc8c5, d
	.byte 0xd1, 0xd6
	or	bc, ix
	.byte 0xe6
	sla	xbc, 239
	.byte 0xf3, 0xf6
	swi	1
	swi	4
	swi	7
	nop
	nop
	di
	ldio	0, 10
	nop
	decf
	nop
	rcf
	nop
	zcf
	nop
	ex_ff
	nop
	pop_f
	nop
	calr	10240
	nop
	nop
	nop
	nop
	nop
	push	sr
	.byte 0x04, 0x06
	ldio	10, 12
	ret
	rcf
	ccf
	push_a
	ex_ff
	push_f
	.byte 0x1a, 0x1c
	calr	8736
	.byte 0x24
	.ascii "&(*,.0234568:<>?@BDEFHJKLMNPQRTUVXYZ[\\]^_`abcdefghijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}}~~~"
	jrl	nc, 32639
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x81, 0x81, 0x81, 0x81
	.byte 0x82, 0x82, 0x82, 0x82, 0x83, 0x83, 0x83, 0x84
	.byte 0x84, 0x85, 0x85, 0x86, 0x86, 0x87
	add	(xsp), w
	add	(xwa-119), a
	add	(xde-118), c
	add	(xhl-116), d
	add	(xiy-115), h
	add	(xiz-113), l
	.byte 0x90, 0x90, 0x91, 0x91, 0x92, 0x92, 0x93, 0x94
	.byte 0x95, 0x96, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b
	.byte 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa4
	.byte 0xa5, 0xa6
	sub	(xsp), xwa
	sub	(xde-85), xix
	.byte 0xad, 0xae, 0xb0, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6
	.byte 0xb7, 0xb8, 0xba, 0xbc, 0xbe, 0xbf, 0xc0
	anddm8_24	0xc6c4c3, w
	and	b, 205
	xor	w, h
	xordm16_24	0xd8d6d4, de
	cps	ix, 5
	or	wa, iz
	.byte 0xe2, 0xe4, 0xe6, 0xe8
	sla	xde, 238
	.byte 0xf0, 0xf2, 0xf5
	ldx
	swi	1
	swi	3
	swi	5
	swi	7
	swi	7
	swi	7
	swi	7
	pop_a
	nop
	pushw	hl
	nop
	ld	xwa, 0x6b005500
	nop
	.byte 0x80
	nop
	.byte 0x95
	nop
	.byte 0xab
	nop
	.byte 0xc0
	nop
	.byte 0xd5
	nop
	.byte 0xeb
	nop
	nop
	.byte 0x01, 0x55
	halt
	.byte 0xab
	ldwio	0, 0x5510
	pop_a
	.byte 0xab, 0x1a
	nop
	ldb	w, 85
	ldb	e, 171
	pushw	de
	nop
	ldw	wa, 0x3555
	.byte 0xab
	push	xde
	nop
	ld	xwa, 0x02010000
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	4368
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	.byte 0x17
	push_f
	pop_f
	.byte 0x1a
	jp	0x1e1d1c
	.byte 0x1f
	.ascii " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{}"
	jrl	nc, 127
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	4368
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	.byte 0x17
	push_f
	pop_f
	.byte 0x1a
	jp	0x1e1d1c
	.byte 0x1f
	.ascii " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	jrl	nc, 1
	.byte 0xe3
	jrl	mi, 252
	push	sr
	nop
	.byte 0x04
	jrl	c, 252
	.byte 0x04
	nop
	.long SndParam_TableLookup_Via4100
	ldio	0, 29
	jrl	ule, 252
	rcf
	nop
	.byte 0xbc
	jrl	le, 252
	ldb	w, 0
	jrl	ge, -909
	nop
	.byte 0x40
	nop
	.long SndParam_SetResBit2_ViaPartCC5D
	.byte 0x80
	nop
	scc16	le, bc
	swi	4
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x01
	nop
	.byte 0x86
	jrl	z, 252
	push	sr
	nop
	.long SndParam_VoiceEntryLookup_ViaReg8000
	.byte 0x04
	nop
	cp	(xiz+115), ix
	nop
	ldio	0, 217
	jrl	ule, 252
	rcf
	nop
	jr	gt, 114
	swi	4
	nop
	ldb	w, 0
	.long SndParam_SetResBit3_ViaRegs0101_0102
	ld	xwa, 0xfc722400
	nop
	.byte 0x80
	nop
	ld	xbc, 0xfc72
	.byte 0x01, 0xf6
	jrl	ule, 252
	nop
	push	sr
	.long SndParam_VoiceEntryLookup_ViaReg8000
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x01
	nop
	cp	(xsp+116), ix
	nop
	.byte 0x04
	nop
	.byte 0xe4
	jrl	ov, 252
	.byte 0x08
	nop
	.long SndParam_SetResBit4_Via0400
	rcf
	nop
	jr	nz, 116
	swi	4
	nop
	ldb	w, 0
	cp	(xhl+116), d
	nop
	ld	xwa, 0xfc750100
	nop
	nop
	.byte 0x01
	.long ExtData_VoiceParam_DispatchBytecode
	nop
	.byte 0x04, 0xa6
	jrl	mi, 252
	nop
	rcf
	.byte 0xb7
	jrl	mi, 252
	nop
	ldb	w, 65
	jrl	c, 252
	nop
	.byte 0x40
	.long CtrlPanel_SetResBit6_ViaLookup
	nop
	.byte 0x80
	jrl	mi, -905
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x01
	nop
	.byte 0xbf
	jrl	c, 252
	push	sr
	nop
	.long CtrlPanel_SetBit3_OnStyleD0D3
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	ld	xwa, 0xfc77f000
	nop
	.byte 0x08
	nop
	.long CtrlPanel_SetResBit0_ViaLookup4C
	.byte 0x04
	nop
	jrl	-904
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x04
	nop
	.byte 0xe6
	jrl	252
	nop
	.byte 0x20
	.long CtrlPanel_SetResBit5_ViaLookup4C
	nop
	ld	xwa, CtrlPanel_SetResBit6_ViaLookup4C
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
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
	.byte 0xc0
	andda8	d, 0xc3c2
	.byte 0xc8
	nop
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	ldio	10, 11
	incf

	swi	7
	.byte 0x04
	push	sr
	ei	7
	halt
	pop	sr
	ldb	c, 0
	ldb	c, 0
	pushw	hl
	nop
	ldb	l, 0
	pushw	sp
	nop
	ldw	hl, 3072
	nop
	.byte 0x1f
	nop
	push	xix
	nop
	rcf
	nop
	incf
	nop
	incf
	nop
	.byte 0x04
	nop
	nop
	nop
	push	xix
	nop
	ldio	0, 55
	nop
	.byte 0x01
	push	sr
	.byte 0x04, 0x01
	push	sr
	.byte 0x04, 0x01
	push	sr
	.byte 0x04
	ldio	1, 2
	.byte 0x04
	ldio	0, 0
	ldw	ix, 0x3400
	nop
	ret
	nop
	ldb	l, 0
	reti
	nop
	reti
	nop
	pushw	iz
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 0x80000000
	scf
	ldw	de, 3072
	push_a
	ldw	de, 93
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	rcf
	push_f
	nop
	jr	lt, 24
	jr	ule, 94
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	ccf
	push	sr
	nop
	pushw	iy
	incf
	ldw	de, 80
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	push_a
	pushw	iz
	nop
	call	0x503a14
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	pop_a
	ldb	w, 0
	push	xix
	push_f
	.byte 0x50
	popw	iz
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	ex_ff
	push_a
	nop
	pop_a
	push_f
	ldw	ix, 73
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	push_f
	ldb	a, 0
	push	sr
	nop
	jr	f, 79
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	pop_f
	pushw	hl
	nop
	.byte 0x1a
	nop
	halt
	push	xde
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	.byte 0x1a
	retd	4352
	pop_a
	.byte 0x17
	popw	sp
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	jp	0x1a003c
	ccf
	ldw	de, 4694
	.byte 0x54
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	push	sr
	.byte 0x1c
	pop	sr
	.byte 0x97, 0x04, 0xd5
	halt
	.byte 0xa2, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01, 0xd8
	push	sr
	.byte 0x84, 0x04, 0xc4, 0x06
	pop	xwa
	.byte 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	push	sr
	ld	xhl, 0x29042a03
	.byte 0x04, 0xc0, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	nop
	ld	h, 152
	halt
	push_f
	halt
	jr	84
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	nop
	.byte 0x1c
	push	sr
	.byte 0x54
	pop	sr
	push_a
	.byte 0x04
	push	sr
	.byte 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	ld	wa, 1432
	push	sr
	halt
	div	xix, xwa
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	nop
	ccf
	.byte 0x01, 0xa8
	halt
	push_f
	halt
	div	xix, xwa
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01, 0xc0
	pop	sr
	.byte 0x98
	halt
	push_f
	.byte 0x06, 0x54, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	call	0x05ea04
	.byte 0xf0, 0x06
	ld	(xwa), ix
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	push_a
	ldw	iz, 2816
	push_a
	ldw	de, 74
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	jp	0x038e02
	pop	xwa
	.byte 0x04
	retd	84
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	rcf
	push	sr
	nop
	ldw	iy, 0x5400
	jr	ov, 0
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	scf
	push	sr
	.byte 0x83
	pop	sr
	popw	ix
	halt
	.byte 0xe8, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	rcf
	.byte 0x1c
	nop
	.byte 0x56
	nop
	.byte 0x52
	jr	ov, 0
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	push	sr
	pop	xwa
	pop	sr
	push_f
	pop	sr
	.byte 0xe8
	halt
	incf
	.byte 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	ccf
	ldb	c, 0
	ldw	bc, 0x320c
	popw	iz
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01, 0x98
	push	sr
	popw	hl
	pop	sr
	pop	b
	rcf
	.byte 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	ex_ff
	pushw	iy
	nop
	push	xde
	incf
	ldw	de, 82
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01, 0x98
	push	sr
	pop	xwa
	.byte 0x04
	ldb	a, 5
	ldb	b, 84
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	push_f
	pushw	bc
	nop
	pop_f
	push_a
	ldw	de, 74
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	ld	wa, 1176
	push_f
	.byte 0x04, 0x8e, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	pop_f
	zcf
	nop
	ccf
	ldwio	87, 63
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	.byte 0x01
	ld	wa, 1163
	pop	xiz
	halt
	div	xix, xwa
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	jp	0x590034
	ccf
	ldw	de, 79
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	push	sr
	.byte 0x8b
	pop	sr
	.byte 0x92
	halt
	ldb	b, 5
	.byte 0xd1, 0x54
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	scf
	ldb	c, 0
	ld	xsp, 0x693214
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
	popw	sp
	push	sr
	.byte 0x53
	push	sr
	.byte 0x83
	halt
	push_f
	halt
	div	xix, xwa
	nop
	nop
	.zero 8
	nop
	nop
	jr	ule, 0
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
	nop
	.byte 0x00, 0x18, 0x00, 0x00, 0x00, 0x7f, 0x35, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x38, 0x00
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x01, 0x00, 0x01, 0x18, 0x38, 0x00, 0x00, 0x7f
	.byte 0x35, 0x00, 0x00, 0x5a, 0x50, 0x40, 0x80, 0x02
	.byte 0x38, 0x01, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x01, 0x00, 0x02, 0x18, 0x06, 0x00
	.byte 0x00, 0x71, 0x45, 0x00, 0x00, 0x5a, 0x30, 0x40
	.byte 0x80, 0x02, 0x00, 0x02, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x03, 0x18
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x20, 0x03, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x04, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x04
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x00, 0x00, 0x05, 0x18, 0x00, 0x00, 0x00, 0x64
	.byte 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02
	.byte 0x20, 0x05, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x06, 0x18, 0x00, 0x00
	.byte 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x20, 0x06, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x07, 0x18
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x20, 0x07, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x08, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x08
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x00, 0x00, 0x09, 0x18, 0x00, 0x00, 0x00, 0x64
	.byte 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02
	.byte 0x20, 0x09, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x0a, 0x18, 0x00, 0x00
	.byte 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x20, 0x0a, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0b, 0x18
	.byte 0x00, 0x00, 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x20, 0x0b, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x0c, 0x18, 0x00, 0x00, 0x00, 0x64, 0x35, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x20, 0x0c
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x00, 0x00, 0x0d, 0x18, 0x00, 0x00, 0x00, 0x64
	.byte 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02
	.byte 0x20, 0x0d, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x0e, 0x18, 0x00, 0x00
	.byte 0x00, 0x64, 0x35, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x20, 0x0e, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x0f, 0x18
	.byte 0xf0, 0x00, 0x00, 0x64, 0x25, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x00, 0x0f, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x10, 0x18, 0x06, 0x00, 0x00, 0x71, 0x55, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xc4
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x00, 0x00, 0x11, 0x18, 0x1a, 0x00, 0x00, 0x71
	.byte 0x55, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02
	.byte 0x00, 0xc8, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x12, 0x18, 0x64, 0x00
	.byte 0x00, 0x71, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x00, 0xc9, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x13, 0x18
	.byte 0x28, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x00, 0xc2, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x14, 0x18, 0xf0, 0x00, 0x00, 0x76, 0x05, 0x00
	.byte 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02, 0x00, 0xce
	.byte 0x80, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00
	.byte 0x00, 0x00, 0x15, 0x18, 0x06, 0x00, 0x00, 0x71
	.byte 0x45, 0x00, 0x00, 0x5a, 0x40, 0x40, 0x80, 0x02
	.byte 0x00, 0xc4, 0x80, 0x00, 0x00, 0x80, 0x80, 0x80
	.byte 0x80, 0x00, 0x00, 0x00, 0x16, 0x18, 0x28, 0x00
	.byte 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a, 0x40, 0x40
	.byte 0x80, 0x02, 0x00, 0xc0, 0x80, 0x00, 0x00, 0x80
	.byte 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x19, 0x18
	.byte 0x00, 0x00, 0x00, 0x76, 0x15, 0x00, 0x00, 0x5a
	.byte 0x40, 0x40, 0x80, 0x02, 0x00, 0xcf, 0x80, 0x00
	.byte 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00
	.byte 0x44, 0x0a, 0x00, 0x00, 0x00, 0x88, 0x80, 0x80
	.byte 0x00, 0x00, 0x00, 0x00, 0x45, 0x0a, 0x00, 0x00
	.byte 0x00, 0x88, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00
	.byte 0x46, 0x0a, 0x00, 0x00, 0x00, 0x88, 0x80, 0x80
	.byte 0x00, 0x00, 0x00, 0x00, 0x47, 0x08, 0xff, 0x00
	.byte 0x00, 0x00, 0xc0, 0x00, 0xff, 0xff, 0x43, 0x04
	.byte 0x80, 0x3c, 0x00, 0x00, 0x48, 0x0a, 0x60, 0x02
	.byte 0x00, 0xe8, 0x00, 0x00, 0x00, 0x00, 0x78, 0x00
	.byte 0x90, 0x06, 0x01, 0x00, 0x67, 0x00, 0x40, 0x00
	.byte 0x60, 0x04, 0x00, 0x80, 0x00, 0x00, 0x61, 0x18
	.byte 0x01, 0x1e, 0x06, 0x00, 0x54, 0x4b, 0x00, 0x00
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
	.byte 0x91, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00
	.byte 0x01, 0x07, 0x05, 0x00, 0x00, 0xff, 0xc0, 0xc1
	.byte 0xc3, 0xc4, 0xc6, 0xc8, 0xca, 0xcb, 0xcd, 0xcf
	.byte 0xd0, 0xd2, 0xd4, 0xd6, 0xd7, 0xd9, 0xdb, 0xdc
	.byte 0xde, 0xe0, 0xe2
	or	(xbc-5913), xde
	.byte 0xec, 0xed, 0xef, 0xf1, 0xf3, 0xf4, 0xf6, 0xf8
	.byte 0xf9, 0xfb, 0xfd, 0xfe, 0x00, 0x02, 0x03, 0x05
	.byte 0x07, 0x08, 0x0a, 0x0c, 0x0d, 0x0f, 0x11, 0x12
	.byte 0x14, 0x16, 0x17, 0x19, 0x1b, 0x1c, 0x1e, 0x20
	.ascii "!#%&(*+-/023578:<=>?V"
	.byte 0xba, 0xed, 0x00
	.byte 0x4e, 0x00, 0x00, 0x26, 0x00, 0xff, 0x01, 0x00
	.byte 0x00, 0x00, 0x48, 0x05, 0x01, 0x00, 0x01, 0x00
	.byte 0x00, 0xff, 0x01, 0x01, 0x01, 0x00, 0x00, 0xff
VoiceCtrlR1_Entry_001:
	pop	sr
	nop
	nop
	nop
	jrl	f, -254
	nop
	pushw	0
	swi	7
	.byte 0x01, 0x01
	reti
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_002:
	.byte 0x04
	nop
	nop
	nop
	popw	wa
	ldio	255, 40
	swi	7
	nop
	nop
	nop
	.byte 0x06
	ldio	6, 2
	nop
	swi	7
VoiceCtrlR1_Entry_003:
	halt
	nop
	nop
	nop
	popw	wa
	push	1
	nop
	.byte 0x01
	nop
	nop
	nop
	.byte 0x06
	ldio	6, 2
	nop
	swi	7
VoiceCtrlR1_Entry_004:
	.byte 0xc0
	nop
	nop
	nop
	.byte 0x91
	pop	sr
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_005:
	.byte 0xc1
	nop
	nop
	nop
	.byte 0x91
	pop	sr
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_006:
	nop
	.byte 0x01
	nop
	nop
	.byte 0x93
	nop
	retd	2304
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_007:
	push	sr
	.byte 0x01
	nop
	nop
	.byte 0x93
	halt
	swi	7
	.byte 0x01
	ldwio	0, 0xff00
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_008:
	pop	sr
	.byte 0x01
	nop
	nop
	.byte 0x93, 0x06
	jrl	nc, 32513
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_009:
	.byte 0x04, 0x01
	nop
	nop
	.byte 0x93, 0x06, 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_010:
	nop
	pop	sr
	nop
	nop
	.byte 0x98, 0x01
	jrl	nc, 20480
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_011:
	.byte 0x01
	pop	sr
	nop
	nop
	.byte 0x98, 0x01, 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_012:
	push	sr
	pop	sr
	nop
	nop
	.byte 0x98
	nop
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_013:
	nop
	.byte 0x04
	nop
	nop
	.byte 0x98
	pop	sr
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_014:
	.byte 0x01, 0x04
	nop
	nop
	.byte 0x98
	pop	sr
	jrl	f, 769
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_015:
	nop
	ldb	a, 0
	nop
	.byte 0x80
	pop	sr
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_016:
	.byte 0x01
	ldb	a, 0
	nop
	.byte 0x80
	pop	sr
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_017:
	ld	a, (xbc)
	nop
	nop
	.byte 0x80
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_018:
	ld	a, (xde)
	nop
	nop
	.byte 0x80
	nop
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_019:
	ld	a, (xhl)
	nop
	nop
	.byte 0x80
	pop	sr
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_020:
	ld	a, (xix)
	nop
	nop
	.byte 0x80
	nop
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_021:
	nop
	ldb	b, 0
	nop
	.byte 0x80
	nop
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_022:
	.byte 0x01
	ldb	b, 0
	nop
	.byte 0x80
	nop
	pop	sr
	nop
	pop	sr
	nop
	nop
	.byte 0x01, 0x01
	reti
	halt
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_023:
	nop
	.byte 0x01
	pop	sr
	swi	7
WidgetParam_MidiCC_Program:
	.long VoiceCtrlR1_Entry_023
	pop	sr
	nop
	nop
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_024:
	push	sr
	ldb	b, 0
	nop
	.byte 0x80
	nop
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_025:
	pop	sr
	ldb	b, 0
	nop
	.byte 0x80
	nop
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_026:
	halt
	ldb	b, 0
	nop
	.byte 0x80
	push	sr
	push_f
	nop
	pop	sr
	pop	sr
	nop
	pop	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
	nop
	.byte 0x01
	pop	sr
	swi	7
WidgetParam_MidiCC_BankSelect:
	.byte 0x90
	ld	(xix-19), 3
	nop
	nop
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_027:
	ld	b, (xwa)
	nop
	nop
	.byte 0x80, 0x01
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_028:
	ld	b, (xbc)
	nop
	nop
	.byte 0x80
	push	sr
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_029:
	ld	b, (xde)
	nop
	nop
	.byte 0x80, 0x06
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_030:
	.byte 0x8a
	ldb	b, 0
	nop
	.byte 0x80
	reti
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_031:
	.byte 0x8b
	ldb	b, 0
	nop
	.byte 0x80
	reti
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_032:
	.byte 0x8c
	ldb	b, 0
	nop
	.byte 0x80
	reti
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_033:
	.byte 0x8d
	ldb	b, 0
	nop
	.byte 0x80
	ldio	128, 0
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_034:
	.byte 0x8e
	ldb	b, 0
	nop
	.byte 0x80
	ldio	4, 0
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_035:
	.byte 0x8f
	ldb	b, 0
	nop
	.byte 0x80
	ldio	8, 0
	.byte 0x01
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_036:
	ld	de, (xwa)
	nop
	nop
	.byte 0x80
	ldio	16, 0
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_037:
	ld	de, (xbc)
	nop
	nop
	.byte 0x80
	ldio	1, 0
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_038:
	ld	de, (xix)
	nop
	nop
	.byte 0x80
	ldio	32, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_039:
	ld	de, (xiy)
	nop
	nop
	.byte 0x80
	ldio	2, 0
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_040:
	ld	de, (xiz)
	nop
	nop
	.byte 0x80
	reti
	push	sr
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_041:
	.byte 0x98
	ldb	b, 0
	nop
	.byte 0x80
	reti
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_042:
	.byte 0x99
	ldb	b, 0
	nop
	.byte 0x80
	push	1
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_043:
	.byte 0x9a
	ldb	b, 0
	nop
	.byte 0x80, 0x01, 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_044:
	.byte 0x80
	pushw	wa
	nop
	nop
	.byte 0x99
	push	sr
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_045:
	.byte 0x82
	pushw	wa
	nop
	nop
	.byte 0x99, 0x01
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_046:
	.byte 0x81
	pushw	wa
	nop
	nop
	.byte 0x99
	pop	sr
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_047:
	.byte 0x86
	pushw	wa
	nop
	nop
	.byte 0x99, 0x04
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_048:
	.byte 0x87
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_049:
	.byte 0x88
	pushw	wa
	nop
	nop
	.byte 0x99
	halt
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_050:
	.byte 0x89
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	push	sr
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_051:
	.byte 0x8a
	pushw	wa
	nop
	nop
	.byte 0x99, 0x06
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_052:
	.byte 0x8b
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_053:
	.byte 0x8c
	pushw	wa
	nop
	nop
	.byte 0x99
	reti
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_054:
	.byte 0x8d
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_055:
	.byte 0x8e
	pushw	wa
	nop
	nop
	.byte 0x99
	ldio	255, 0
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_056:
	.byte 0x8f
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_057:
	.byte 0x90
	pushw	wa
	nop
	nop
	.byte 0x99
	push	255
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_058:
	.byte 0x91
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_059:
	.byte 0x92
	pushw	wa
	nop
	nop
	.byte 0x99
	ldwio	255, 0xc700
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_060:
	.byte 0x93
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_061:
	.byte 0x94
	pushw	wa
	nop
	nop
	.byte 0x99
	pushw	255
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_062:
	.byte 0x95
	pushw	wa
	nop
	nop
	.byte 0x99
	nop
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_063:
	.byte 0x96
	pushw	wa
	nop
	nop
	.byte 0x99
	incf
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_064:
	.byte 0x97
	pushw	wa
	nop
	nop
	.byte 0x99, 0x01, 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_065:
	.byte 0x98
	pushw	wa
	nop
	nop
	.byte 0x99
	decf
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_066:
	.byte 0x99
	pushw	wa
	nop
	nop
	.byte 0x99, 0x01
	push	sr
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_067:
	.byte 0x9a
	pushw	wa
	nop
	nop
	.byte 0x99
	ret
	swi	7
	nop
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_068:
	.byte 0x9b
	pushw	wa
	nop
	nop
	.byte 0x99, 0x01, 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_069:
	.byte 0x9c
	pushw	wa
	nop
	nop
	.byte 0x99
	retd	255
	.byte 0xc7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_070:
	.byte 0x9d
	pushw	wa
	nop
	nop
	.byte 0x99, 0x01
	ldio	0, 1
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_071:
	nop
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_072:
	.byte 0x01
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	push	sr
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_073:
	push	sr
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_074:
	pop	sr
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceCtrlR1_Entry_075:
	.byte 0x04
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_001:
	halt
	pushw	bc
	nop
	nop
	ld	wa, (xwa+7)
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_002:
	ei	41
	nop
	nop
	.byte 0x98
	reti
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_003:
	reti
	pushw	bc
	nop
	nop
	.byte 0x98
	reti
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_004:
	ldio	41, 0
	nop
	.byte 0x98
	ldio	1, 0
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_005:
	push	41
	nop
	nop
	.byte 0x98
	ldio	2, 0
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_006:
	ldwio	41, 0
	.byte 0x98
	ldio	4, 0
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_007:
	pushw	41
	nop
	.byte 0x98
	ldio	8, 0
	.byte 0x01
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_008:
	incf
	pushw	bc
	nop
	nop
	.byte 0x98
	ldio	16, 0
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_009:
	decf
	pushw	bc
	nop
	nop
	ld	wa, (xwa+8)
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_010:
	ret
	pushw	bc
	nop
	nop
	.byte 0x98
	ldio	64, 0
	.byte 0x01
	di
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_011:
	retd	41
	nop
	.byte 0x98
	ldio	128, 0
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_012:
	rcf
	pushw	bc
	nop
	nop
	.byte 0x98
	push	1
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_013:
	scf
	pushw	bc
	nop
	nop
	.byte 0x98
	push	2
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_014:
	nop
	pushw	de
	nop
	nop
	jrl	f, -251
	.byte 0x01
	rcf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_015:
	.byte 0x01
	pushw	de
	nop
	nop
	jrl	f, -250
	.byte 0x01
	rcf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_016:
	rcf
	pushw	de
	nop
	nop
	jrl	f, 263
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_017:
	scf
	pushw	de
	nop
	nop
	jrl	f, 519
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_018:
	ccf
	pushw	de
	nop
	nop
	jrl	f, 1031
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_019:
	nop
	pushw	ix
	nop
	nop
	.byte 0x98
	ret
	pop	sr
	nop
	push	sr
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_020:
	nop
	pushw	iy
	nop
	nop
	ld	xsp, 0x11001f01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_021:
	.byte 0x01
	pushw	iy
	nop
	nop
	ld	xsp, 0x01000100
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_022:
	push	sr
	pushw	iy
	nop
	nop
	ld	xsp, 0x63007f02
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_023:
	pop	sr
	pushw	iy
	nop
	nop
	ld	xsp, 0x01000200
	.byte 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_024:
	.byte 0x04
	pushw	iy
	nop
	nop
	ld	xsp, 0x07000703
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_025:
	halt
	pushw	iy
	nop
	nop
	ld	xsp, 0x01000400
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_026:
	ei	45
	nop
	nop
	ld	xsp, 0x0b00f003
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_027:
	reti
	pushw	iy
	nop
	nop
	ld	xsp, 0x01000800
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_028:
	ldio	45, 0
	nop
	ld	xsp, 0x0300c004
	di
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_029:
	push	45
	nop
	nop
	ld	xsp, 0x01001000
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_030:
	ldwio	45, 0
	ld	xsp, 0x79007f05
	nop
	nop
	ldwio	1, 1287
	nop
	nop
	swi	7
	nop
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	7709
	.byte 0x1f, 0x20
	.ascii "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyÿ"
WidgetParam_MidiCC_NameEdit:
	pushw	ix
	.byte 0xc2, 0xed
	nop
	jr	pl, 0
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_031:
	pushw	45
	nop
	ld	xsp, 0x01002000
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_032:
	incf
	pushw	iy
	nop
	nop
	ld	xsp, 0xff00ff06
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_033:
	decf
	pushw	iy
	nop
	nop
	ld	xsp, 0x7f007f06
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_034:
	ret
	pushw	iy
	nop
	nop
	ld	xsp, 0x01008006
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_035:
	retd	45
	nop
	ld	xsp, 0x01004000
	di
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_036:
	rcf
	pushw	iy
	nop
	nop
	ld	xsp, 0xff00ff07
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_037:
	scf
	pushw	iy
	nop
	nop
	ld	xsp, 0x7f007f07
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_038:
	ccf
	pushw	iy
	nop
	nop
	ld	xsp, 0x01008007
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_039:
	zcf
	pushw	iy
	nop
	nop
	ld	xsp, 0x01008000
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_040:
	nop
	ld	xwa, 0xb00000
	jrl	nc, 32512
	nop
	nop
	.byte 0x01
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_041:
	.byte 0x01
	ld	xwa, 0x01b00000
	jrl	nc, 32512
	nop
	nop
	nop
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_042:
	push	sr
	.byte 0x40


	nop
	nop
	jr	f, 1
	.byte 0x80
	nop
	jrl	nc, 7
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
MidiChParam_Entry_043:
	pop	sr
	ld	xwa, 0x700000
	.byte 0x04
	nop
	.byte 0x01
	push	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_044:
	.byte 0x04, 0x40


	nop
	nop
	jr	f, 1
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_045:
	halt
	ld	xwa, 0x03b00000
	jrl	nc, 32512
	nop
	nop
	nop
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_046:
	.byte 0x06, 0x40


	nop
	nop
	jr	f, 1
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_047:
	.byte 0x80
	ld	xwa, 0x02980000
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01
	push	sr
	push	sr
	nop
	nop
	swi	7
MidiChParam_Entry_048:
	.byte 0x81
	ld	xwa, 0x02980000
	ld	xwa, 0x060100
	swi	7
	.byte 0x01
	push	sr
	push	sr
	nop
	nop
	swi	7
MidiChParam_Entry_049:
	.byte 0xc0
	ld	xwa, 0x0b980000
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_050:
	.byte 0xc1
	ld	xwa, 0x0b980000
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_051:
	.byte 0xe0
	ld	xwa, 0x04900000
	swi	7
	pushw	wa
	pop	xwa
	nop
	nop
	swi	7
	.byte 0x01, 0x01
	reti
	nop
	nop
	swi	7
MidiChParam_Entry_052:
	nop
	ld	xbc, 0x900000
	.byte 0x1f
	nop
	halt
	nop
	nop
	nop
	.byte 0x04
	halt
	.byte 0x04
	nop
	nop
	swi	7
WidgetParam_MidiCC_SysExcl:
	.byte 0x01
	nop
	push	sr
	nop
	pop	sr
	nop
	pop	sr
	push	sr
	.byte 0x01
	push	sr
	push	sr
	push	sr
MidiChParam_Entry_053:
	ld	xwa, 0x43000041
	nop
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_054:
	ld	xbc, 0x43000041
	.byte 0x01
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_055:
	ld	xde, 0x43000041
	.byte 0x01, 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_056:
	.byte 0x80
	ld	xbc, 0x700000
	pop	sr
	nop
	pop	sr
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_057:
	.byte 0x81
	ld	xbc, 0x01700000
	jrl	nc, 27669
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_058:
	nop
	ld	xde, 0x04480000
	ld	xwa, 0x060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_059:
	.byte 0x01
	ld	xde, 0x03700000
	swi	7
	nop
	swi	7
	nop
	nop
	ei	1
	reti
	halt
	nop
	nop
	swi	7
	swi	7
	nop
	.byte 0x01
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	swi	7
WidgetParam_MidiCC_Volume:
	.byte 0xba, 0xc4, 0xed
	nop
	retd	0xff00
	nop
	nop
	swi	7
MidiChParam_Entry_060:
	push	sr
	ld	xde, 0x04700000
	retd	3328
	nop
	nop
	ldio	1, 7
	halt
	nop
	nop
	swi	7
	nop
	.byte 0x01
	push	sr
	decf
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	.byte 0x0b
	incf
WidgetParam_MidiCC_Pan:
	.byte 0xe6, 0xc4, 0xed
	nop
	ret
	nop
	reti
	ldio	0, 255
MidiChParam_Entry_061:
	.byte 0x80
	ld	xde, 0x01920000
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_062:
	.byte 0x81
	ld	xde, 0x920000
	swi	7
	nop
	.byte 0x80
	nop
	nop
	.byte 0x04, 0x01
	reti
	halt
	nop
	nop
	swi	7
	nop
	ld	xwa, 0x04034241
	halt
	rcf
	scf
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	cp	(xwa), l
WidgetParam_MidiCC_Expression:
	ldb	b, 197
	.byte 0xed
	nop
	retd	0
	nop
	nop
	swi	7
MidiChParam_Entry_063:
	.byte 0x82
	ld	xde, 0x01920000
	retd	2816
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_064:
	.byte 0x83
	ld	xde, 0x02920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
	nop
	.byte 0x01
	pop	sr
	.byte 0x04
	halt
	reti
	ldio	9, 10
	incf
	decf
	ret
	retd	4625
	zcf
	pop_a
	ex_ff
	.byte 0x17
	push_f
	.byte 0x1a
	jp	0x1f1d1c
	.ascii " !#$%&()*+-./12346789;<=?@ABDEFGIJKMNOPRSTUWXY[\\]^`abcefgijklnopqstuwxyz|}~€‚ƒ…†‡ˆŠ‹ŒŽ‘“”•–˜™šœžŸ¡¢"
	.byte 0xa3, 0xa4, 0xa6
	sub	(xsp), xwa
	sub	(xde-85), xix
	.byte 0xad, 0xaf, 0xb0, 0xb1, 0xb2, 0xb4, 0xb5, 0xb6
	.byte 0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe, 0xbf, 0xc0
	andda8_24	l, 0xc6c4c3
	adc	w, 203
	xor	d, 206
	.byte 0xd0, 0xd1, 0xd2, 0xd4, 0xd5, 0xd6, 0xd7
	cps	bc, 2
	cps	hl, 4
	cps	iz, 7
	.byte 0xe0, 0xe2, 0xe3, 0xe4, 0xe5, 0xe7, 0xe8, 0xe9
	sla	xde, 237
	cp	xwa, xiz
	.byte 0xf1, 0xf2, 0xf3, 0xf5, 0xf6
	ldx
	swi	0
	swi	2
	swi	3
	swi	4
	swi	6
	swi	7
	swi	7
WidgetParam_MidiCC_Sustain:
	jr	f, -59
	.byte 0xed
	nop
	.byte 0xc9
	nop
	incm8	4, (xwa)
	nop
	swi	7
MidiChParam_Entry_065:
	.byte 0x84
	ld	xde, 0x03920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_066:
	.byte 0x85
	ld	xde, 0x04920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_067:
	.byte 0x86
	ld	xde, 0x05920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_068:
	.byte 0x87
	ld	xde, 0x06920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_069:
	.byte 0x88
	ld	xde, 0x07920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_070:
	.byte 0x89
	ld	xde, 0x08920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_071:
	.byte 0x8a
	ld	xde, 0x09920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_072:
	.byte 0x8b
	ld	xde, 0x0a920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_073:
	.byte 0x8c
	ld	xde, 0x0b920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_074:
	.byte 0x8d
	ld	xde, 0x0c920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_075:
	.byte 0x8e
	ld	xde, 0x0d920000
	swi	7
	nop
	swi	7
	nop
	nop
	halt
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_076:
	nop
	popw	bc
	nop
	nop
	jr	lt, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_077:
	nop
	popw	de
	nop
	nop
	jr	le, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_078:
	nop
	popw	hl
	nop
	nop
	jr	ule, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_079:
	nop
	popw	ix
	nop
	nop
	jr	ov, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_080:
	nop
	popw	iy
	nop
	nop
	jr	mi, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_081:
	nop
	popw	iz
	nop
	nop
	jr	z, 0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_082:
	nop
	.byte 0x50
	nop
	nop
	.byte 0x80
	ldwio	3, 512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_083:
	.byte 0x01, 0x50
	nop
	nop
	.byte 0x80
	pushw	255
	swi	7
	nop
	nop
	reti
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_084:
	cp	h, 208
	.byte 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7
	cps	wa, 1
	cps	de, 3
	cps	ix, 5
	cps	iz, 7
	.byte 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7
	.byte 0xe8, 0xe9, 0xea
	sla	xhl, 237
	srl	xiz, 240
	.byte 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6
	ldx
	swi	0
	swi	1
	swi	2
	swi	3
	swi	4
	swi	5
	swi	6
	swi	7
	nop
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	4368
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	.byte 0x17
	push_f
	pop_f
	.byte 0x1a
	jp	0x1e1d1c
	.byte 0x1f
	.ascii " !\"#$%&'()*+,-./012ÿ"
WidgetParam_MidiCC_Reverb:
	.long MidiChParam_Entry_084
	jr	mi, 0
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_085:
	push	sr
	.byte 0x50
	nop
	nop
	.byte 0x80
	incf
	swi	7
	.byte 0x01
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_086:
	nop
	.byte 0x80
	nop
	nop
	nop
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_087:
	.byte 0x01, 0x80
	nop
	nop
	ld	(xde), 127
	nop
	jrl	nc, 0
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_088:
	reti
	.byte 0x80
	nop
	nop
	nop
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_089:
	ldio	128, 0
	nop
	nop
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_090:
	ldwio	128, 0
	nop
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_091:
	pushw	128
	nop
	ld	(xhl), 127
	nop
	jrl	nc, 0
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_092:
	ldb	w, 128
	nop
	nop
	nop
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_093:
	ld	xwa, 128
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
WidgetParam_MidiCC_Chorus:
	ld	xwa, 0x7f000100
	nop
	.byte 0x01
	swi	7
MidiChParam_Entry_094:
	pop	xhl
	.byte 0x80
	nop
	nop
	nop
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_095:
	pop	xiy
	.byte 0x80
	nop
	nop
	nop
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_096:
	pop	xiz
	.byte 0x80
	nop
	nop
	nop
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
MidiChParam_Entry_097:
	jrl	128
	nop
	.byte 0xae
	nop
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_098:
	.byte 0x80, 0x80
	nop
	nop
	nop
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_099:
	.byte 0x81, 0x80
	nop
	nop
	nop
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_100:
	.byte 0x82, 0x80
	nop
	nop
	nop
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_101:
	.byte 0xb0, 0x81
	nop
	nop
	ld	(xbc), 127
	nop
	jrl	nc, 0
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_102:
	.byte 0xb2, 0x81
	nop
	nop
	ld	(xix), 127
	nop
	jrl	nc, 0
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
MidiChParam_Entry_103:
	ldb	a, 130
	nop
	nop
	ld	xix, 0x01000f08
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_104:
	add	b, d
	nop
	nop
	ld	xix, 0x0f000f01
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
	pushw	3340
	ret
	retd	256
	push	sr
	pop	sr
	.byte 0x04
	halt
	swi	7
WidgetParam_MidiCC_DspEffect:
	jr	gt, -55
	.byte 0xed
	nop
	pushw	0
	halt
	nop
	swi	7
MidiChParam_Entry_105:
	add	b, c
	nop
	nop
	ld	xix, 0x0f00f001
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_106:
	.byte 0x93, 0x82
	nop
	nop
	ld	xix, 0x0f000f02
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_107:
	.byte 0x94, 0x82
	nop
	nop
	ld	xix, 0x0f00f002
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
MidiChParam_Entry_108:
	.byte 0x80, 0x82
	nop
	nop
	ld	xix, 0x08000f03
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_109:
	.byte 0x81, 0x82
	nop
	nop
	ld	xix, 0x0800f003
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_110:
	.byte 0x82, 0x82
	nop
	nop
	ld	xix, 0x08000f04
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_111:
	.byte 0x83, 0x82
	nop
	nop
	ld	xix, 0x0800f004
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
MidiChParam_Entry_112:
	.byte 0x84, 0x82
	nop
	nop
	ld	xix, 0x08000f05
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_001:
	.byte 0x85, 0x82
	nop
	nop
	ld	xix, 0x0800f005
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_002:
	.byte 0x86, 0x82
	nop
	nop
	ld	xix, 0x08000f06
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_003:
	.byte 0x87, 0x82
	nop
	nop
	ld	xix, 0x0800f006
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_004:
	.byte 0x88, 0x82
	nop
	nop
	ld	xix, 0x08000f07
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_005:
	.byte 0xc0, 0x82
	nop
	nop
	ld	xix, 0x01001007
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_006:
	.byte 0xc1, 0x82
	nop
	nop
	ld	xix, 0x01002007
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_007:
	nop
	.byte 0x84
	nop
	nop
	.byte 0x01
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_008:
	.byte 0x01, 0x84
	nop
	nop
	.byte 0xb2, 0x01
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_009:
	reti
	.byte 0x84
	nop
	nop
	.byte 0x01
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_010:
	ldio	132, 0
	nop
	.byte 0x01
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_011:
	ldwio	132, 0
	.byte 0x01
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_012:
	pushw	132
	nop
	.byte 0xb3, 0x01
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_013:
	ldb	w, 132
	nop
	nop
	.byte 0x01, 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_014:
	ld	xwa, 0x01000084
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_015:
	pop	xhl
	.byte 0x84
	nop
	nop
	.byte 0x01
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_016:
	pop	xiy
	.byte 0x84
	nop
	nop
	.byte 0x01
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_017:
	pop	xiz
	.byte 0x84
	nop
	nop
	.byte 0x01, 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_018:
	jrl	132
	nop
	.byte 0xae, 0x01
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_019:
	.byte 0x80, 0x84
	nop
	nop
	.byte 0x01
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_020:
	.byte 0x81, 0x84
	nop
	nop
	.byte 0x01
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_021:
	.byte 0x82, 0x84
	nop
	nop
	.byte 0x01
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_022:
	.byte 0xb0, 0x85
	nop
	nop
	.byte 0xb1, 0x01
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_023:
	.byte 0xb2, 0x85
	nop
	nop
	.byte 0xb4, 0x01
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_024:
	ldb	a, 134
	nop
	nop
	ld	xiy, 0x01000f08
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_025:
	add	h, d
	nop
	nop
	ld	xiy, 0x0f000f01
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_026:
	add	h, c
	nop
	nop
	ld	xiy, 0x0f00f001
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_027:
	.byte 0x93, 0x86
	nop
	nop
	ld	xiy, 0x0f000f02
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_028:
	.byte 0x94, 0x86
	nop
	nop
	ld	xiy, 0x0f00f002
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_029:
	.byte 0x80, 0x86
	nop
	nop
	ld	xiy, 0x08000f03
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_030:
	.byte 0x81, 0x86
	nop
	nop
	ld	xiy, 0x0800f003
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_031:
	.byte 0x82, 0x86
	nop
	nop
	ld	xiy, 0x08000f04
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_032:
	.byte 0x83, 0x86
	nop
	nop
	ld	xiy, 0x0800f004
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_033:
	.byte 0x84, 0x86
	nop
	nop
	ld	xiy, 0x08000f05
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_034:
	.byte 0x85, 0x86
	nop
	nop
	ld	xiy, 0x0800f005
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_035:
	.byte 0x86, 0x86
	nop
	nop
	ld	xiy, 0x08000f06
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_036:
	.byte 0x87, 0x86
	nop
	nop
	ld	xiy, 0x0800f006
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_037:
	.byte 0x88, 0x86
	nop
	nop
	ld	xiy, 0x08000f07
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_038:
	.byte 0xc0, 0x86
	nop
	nop
	ld	xiy, 0x01001007
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_039:
	.byte 0xc1, 0x86
	nop
	nop
	ld	xiy, 0x01002007
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_040:
	nop
	.byte 0x88
	nop
	nop
	push	sr
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_041:
	.byte 0x01, 0x88
	nop
	nop
	.byte 0xb2
	push	sr
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_042:
	reti
	.byte 0x88
	nop
	nop
	push	sr
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_043:
	ldio	136, 0
	nop
	push	sr
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_044:
	ldwio	136, 0
	push	sr
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_045:
	pushw	136
	nop
	.byte 0xb3
	push	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_046:
	ldb	w, 136
	nop
	nop
	push	sr
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_047:
	ld	xwa, 0x02000088
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_048:
	pop	xhl
	.byte 0x88
	nop
	nop
	push	sr
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_049:
	pop	xiy
	.byte 0x88
	nop
	nop
	push	sr
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_050:
	pop	xiz
	.byte 0x88
	nop
	nop
	push	sr
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_051:
	jrl	136
	nop
	.byte 0xae
	push	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_052:
	add	(xwa), w
	nop
	nop
	push	sr
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_053:
	add	(xbc), w
	nop
	nop
	push	sr
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_054:
	add	(xde), w
	nop
	nop
	push	sr
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_055:
	.byte 0xb0, 0x89
	nop
	nop
	.byte 0xb1
	push	sr
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_056:
	.byte 0xb2, 0x89
	nop
	nop
	.byte 0xb4
	push	sr
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_057:
	ldb	a, 138
	nop
	nop
	ld	xiz, 0x01000f08
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_058:
	ld	b, d
	nop
	nop
	ld	xiz, 0x0f000f01
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_059:
	ld	b, c
	nop
	nop
	ld	xiz, 0x0f00f001
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_060:
	add	(xhl), de
	nop
	nop
	ld	xiz, 0x0f000f02
	nop
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_061:
	add	(xix), de
	nop
	nop
	ld	xiz, 0x0f00f002
	.byte 0x04
	nop
	push	1
	reti
	halt
	nop
	nop
	swi	7
VoiceParamEx_Entry_062:
	add	(xwa), b
	nop
	nop
	ld	xiz, 0x08000f03
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_063:
	add	(xbc), b
	nop
	nop
	ld	xiz, 0x0800f003
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_064:
	add	(xde), b
	nop
	nop
	ld	xiz, 0x08000f04
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_065:
	add	(xhl), b
	nop
	nop
	ld	xiz, 0x0800f004
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_066:
	add	(xix), b
	nop
	nop
	ld	xiz, 0x08000f05
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_067:
	add	(xiy), b
	nop
	nop
	ld	xiz, 0x0800f005
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_068:
	add	(xiz), b
	nop
	nop
	ld	xiz, 0x08000f06
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_069:
	add	(xsp), b
	nop
	nop
	ld	xiz, 0x0800f006
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_070:
	.byte 0x88, 0x8a
	nop
	nop
	ld	xiz, 0x08000f07
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_071:
	.byte 0xc0, 0x8a
	nop
	nop
	ld	xiz, 0x01001007
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_072:
	.byte 0xc1, 0x8a
	nop
	nop
	ld	xiz, 0x01002007
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_073:
	nop
	.byte 0x8c
	nop
	nop
	pop	sr
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_074:
	.byte 0x01, 0x8c
	nop
	nop
	.byte 0xb2
	pop	sr
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_075:
	reti
	.byte 0x8c
	nop
	nop
	pop	sr
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_076:
	ldio	140, 0
	nop
	pop	sr
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_077:
	ldwio	140, 0
	pop	sr
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_078:
	pushw	140
	nop
	.byte 0xb3
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_079:
	ldb	w, 140
	nop
	nop
	pop	sr
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_080:
	ld	xwa, 0x0300008c
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_081:
	pop	xhl
	.byte 0x8c
	nop
	nop
	pop	sr
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_082:
	pop	xiy
	.byte 0x8c
	nop
	nop
	pop	sr
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
VoiceParamEx_Entry_083:
	pop	xiz
	.byte 0x8c
	nop
	nop
	pop	sr
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
VoiceParamEx_Entry_084:
	jrl	140
	nop
	.byte 0xae
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
VoiceParamEx_Entry_085:
	add	(xwa), d
	nop
	nop
	pop	sr
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_001:
	add	(xbc), d
	nop
	nop
	pop	sr
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_002:
	add	(xde), d
	nop
	nop
	pop	sr
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_003:
	.byte 0xb0, 0x8d
	nop
	nop
	.byte 0xb1
	pop	sr
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_004:
	.byte 0xb2, 0x8d
	nop
	nop
	.byte 0xb4
	pop	sr
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_005:
	nop
	.byte 0x90
	nop
	nop
	.byte 0x04
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_006:
	.byte 0x01, 0x90
	nop
	nop
	.byte 0xb2, 0x04
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_007:
	reti
	.byte 0x90
	nop
	nop
	.byte 0x04
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_008:
	ldio	144, 0
	nop
	.byte 0x04
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_009:
	ldwio	144, 0
	.byte 0x04
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_010:
	pushw	144
	nop
	.byte 0xb3, 0x04
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_011:
	ldb	w, 144
	nop
	nop
	.byte 0x04, 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_012:
	ld	xwa, 0x04000090
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_013:
	pop	xhl
	.byte 0x90
	nop
	nop
	.byte 0x04
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_014:
	pop	xiy
	.byte 0x90
	nop
	nop
	.byte 0x04
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_015:
	pop	xiz
	.byte 0x90
	nop
	nop
	.byte 0x04, 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_016:
	jrl	144
	nop
	.byte 0xae, 0x04
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_017:
	.byte 0x80, 0x90
	nop
	nop
	.byte 0x04
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_018:
	.byte 0x81, 0x90
	nop
	nop
	.byte 0x04
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_019:
	.byte 0x82, 0x90
	nop
	nop
	.byte 0x04
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_020:
	.byte 0xb0, 0x91
	nop
	nop
	.byte 0xb1, 0x04
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_021:
	.byte 0xb2, 0x91
	nop
	nop
	.byte 0xb4, 0x04
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_022:
	nop
	.byte 0x94
	nop
	nop
	halt
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_023:
	.byte 0x01, 0x94
	nop
	nop
	.byte 0xb2
	halt
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_024:
	reti
	.byte 0x94
	nop
	nop
	halt
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_025:
	ldio	148, 0
	nop
	halt
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_026:
	ldwio	148, 0
	halt
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_027:
	pushw	148
	nop
	.byte 0xb3
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_028:
	ldb	w, 148
	nop
	nop
	halt
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_029:
	ld	xwa, 0x05000094
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_030:
	pop	xhl
	.byte 0x94
	nop
	nop
	halt
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_031:
	pop	xiy
	.byte 0x94
	nop
	nop
	halt
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_032:
	pop	xiz
	.byte 0x94
	nop
	nop
	halt
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_033:
	jrl	148
	nop
	.byte 0xae
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_034:
	.byte 0x80, 0x94
	nop
	nop
	halt
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_035:
	.byte 0x81, 0x94
	nop
	nop
	halt
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_036:
	.byte 0x82, 0x94
	nop
	nop
	halt
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_037:
	.byte 0xb0, 0x95
	nop
	nop
	.byte 0xb1
	halt
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_038:
	.byte 0xb2, 0x95
	nop
	nop
	.byte 0xb4
	halt
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_039:
	nop
	.byte 0x98
	nop
	nop
	di
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_040:
	.byte 0x01, 0x98
	nop
	nop
	.byte 0xb2, 0x06
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_041:
	reti
	.byte 0x98
	nop
	nop
	ei	3
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_042:
	ldio	152, 0
	nop
	ei	3
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_043:
	ldwio	152, 0
	.byte 0x06
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_044:
	pushw	152
	nop
	.byte 0xb3, 0x06
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_045:
	ldb	w, 152
	nop
	nop
	ei	1
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_046:
	ld	xwa, 0x06000098
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_047:
	pop	xhl
	.byte 0x98
	nop
	nop
	ei	7
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_048:
	pop	xiy
	.byte 0x98
	nop
	nop
	ei	5
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_049:
	pop	xiz
	.byte 0x98
	nop
	nop
	ei	4
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_050:
	jrl	152
	nop
	.byte 0xae, 0x06
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_051:
	.byte 0x80, 0x98
	nop
	nop
	.byte 0x06
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_052:
	.byte 0x81, 0x98
	nop
	nop
	.byte 0x06
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_053:
	.byte 0x82, 0x98
	nop
	nop
	.byte 0x06
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_054:
	.byte 0xb0, 0x99
	nop
	nop
	.byte 0xb1, 0x06
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_055:
	.byte 0xb2, 0x99
	nop
	nop
	.byte 0xb4, 0x06
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_056:
	nop
	.byte 0x9c
	nop
	nop
	reti
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_057:
	.byte 0x01, 0x9c
	nop
	nop
	.byte 0xb2
	reti
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_058:
	reti
	.byte 0x9c
	nop
	nop
	reti
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_059:
	ldio	156, 0
	nop
	reti
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_060:
	ldwio	156, 0
	reti
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_061:
	pushw	156
	nop
	.byte 0xb3
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_062:
	ldb	w, 156
	nop
	nop
	reti
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_063:
	ld	xwa, 0x0700009c
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_064:
	pop	xhl
	.byte 0x9c
	nop
	nop
	reti
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_065:
	pop	xiy
	.byte 0x9c
	nop
	nop
	reti
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_066:
	pop	xiz
	.byte 0x9c
	nop
	nop
	reti
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_067:
	jrl	156
	nop
	.byte 0xae
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_068:
	.byte 0x80, 0x9c
	nop
	nop
	reti
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_069:
	.byte 0x81, 0x9c
	nop
	nop
	reti
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_070:
	.byte 0x82, 0x9c
	nop
	nop
	reti
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_071:
	.byte 0xb0, 0x9d
	nop
	nop
	.byte 0xb1
	reti
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_072:
	.byte 0xb2, 0x9d
	nop
	nop
	.byte 0xb4
	reti
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_073:
	nop
	.byte 0xa0
	nop
	nop
	ldio	0, 255
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_074:
	.byte 0x01, 0xa0
	nop
	nop
	.byte 0xb2
	ldio	127, 0
	jrl	nc, 0
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_075:
	reti
	.byte 0xa0
	nop
	nop
	ldio	3, 127
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_076:
	ldio	160, 0
	nop
	ldio	3, 128
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_077:
	ldwio	160, 0
	ldio	8, 127
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_078:
	pushw	160
	nop
	.byte 0xb3
	ldio	127, 0
	jrl	nc, 0
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_079:
	ldb	w, 160
	nop
	nop
	ldio	1, 127
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_080:
	ld	xwa, 0x080000a0
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_081:
	pop	xhl
	.byte 0xa0
	nop
	nop
	ldio	7, 127
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_082:
	pop	xiy
	.byte 0xa0
	nop
	nop
	ldio	5, 127
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_083:
	pop	xiz
	.byte 0xa0
	nop
	nop
	ldio	4, 64
	nop
	jrl	nc, 6
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_084:
	jrl	160
	nop
	.byte 0xae
	ldio	127, 0
	jrl	nc, 0
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_085:
	.byte 0x80, 0xa0
	nop
	nop
	ldio	11, 127
	nop
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_086:
	.byte 0x81, 0xa0
	nop
	nop
	ldio	10, 255
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_087:
	.byte 0x82, 0xa0
	nop
	nop
	ldio	9, 127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_088:
	.byte 0xb0, 0xa1
	nop
	nop
	.byte 0xb1
	ldio	127, 0
	jrl	nc, 0
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_089:
	.byte 0xb2, 0xa1
	nop
	nop
	.byte 0xb4
	ldio	127, 0
	jrl	nc, 0
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_090:
	nop
	.byte 0xa4
	nop
	nop
	push	0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_091:
	.byte 0x01, 0xa4
	nop
	nop
	.byte 0xb2
	push	127
	nop
	jrl	nc, 0
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_092:
	reti
	.byte 0xa4
	nop
	nop
	push	3
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_093:
	ldio	164, 0
	nop
	push	3
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_094:
	ldwio	164, 0
	push	8
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_095:
	pushw	164
	nop
	.byte 0xb3
	push	127
	nop
	jrl	nc, 0
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_096:
	ldb	w, 164
	nop
	nop
	push	1
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_097:
	ld	xwa, 0x090000a4
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_098:
	pop	xhl
	.byte 0xa4
	nop
	nop
	push	7
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_099:
	pop	xiy
	.byte 0xa4
	nop
	nop
	push	5
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_100:
	pop	xiz
	.byte 0xa4
	nop
	nop
	push	4
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_101:
	jrl	164
	nop
	.byte 0xae
	push	127
	nop
	jrl	nc, 0
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_102:
	.byte 0x80, 0xa4
	nop
	nop
	push	11
	jrl	nc, 3072
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_103:
	.byte 0x81, 0xa4
	nop
	nop
	push	10
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_104:
	.byte 0x82, 0xa4
	nop
	nop
	push	9
	jrl	nc, 19508
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_105:
	.byte 0xb0, 0xa5
	nop
	nop
	.byte 0xb1
	push	127
	nop
	jrl	nc, 0
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_106:
	.byte 0xb2, 0xa5
	nop
	nop
	.byte 0xb4
	push	127
	nop
	jrl	nc, 0
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_107:
	nop
	.byte 0xa8
	nop
	nop
	ldwio	0, 255
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_108:
	.byte 0x01, 0xa8
	nop
	nop
	.byte 0xb2
	ldwio	127, 0x7f00
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_109:
	reti
	.byte 0xa8
	nop
	nop
	ldwio	3, 127
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_110:
	ldio	168, 0
	nop
	ldwio	3, 128
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_111:
	ldwio	168, 0
	ldwio	8, 127
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_112:
	pushw	168
	nop
	.byte 0xb3
	ldwio	127, 0x7f00
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_113:
	ldb	w, 168
	nop
	nop
	ldwio	1, 127
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_114:
	ld	xwa, 0x0a0000a8
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_115:
	pop	xhl
	.byte 0xa8
	nop
	nop
	ldwio	7, 127
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_116:
	pop	xiy
	.byte 0xa8
	nop
	nop
	ldwio	5, 127
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_117:
	pop	xiz
	.byte 0xa8
	nop
	nop
	ldwio	4, 64
	jrl	nc, 6
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_118:
	jrl	168
	nop
	.byte 0xae
	ldwio	127, 0x7f00
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_119:
	sub	(xwa), w
	nop
	nop
	ldwio	11, 127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_120:
	sub	(xbc), w
	nop
	nop
	ldwio	10, 255
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_121:
	sub	(xde), w
	nop
	nop
	ldwio	9, 0x347f
	popw	ix
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_122:
	.byte 0xb0, 0xa9
	nop
	nop
	.byte 0xb1
	ldwio	127, 0x7f00
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_123:
	.byte 0xb2, 0xa9
	nop
	nop
	.byte 0xb4
	ldwio	127, 0x7f00
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_124:
	nop
	.byte 0xac
	nop
	nop
	pushw	0xff00
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_125:
	.byte 0x01, 0xac
	nop
	nop
	.byte 0xb2
	pushw	127
	jrl	nc, 0
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_126:
	reti
	.byte 0xac
	nop
	nop
	pushw	0x7f03
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_127:
	ldio	172, 0
	nop
	pushw	0x8003
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_128:
	ldwio	172, 0
	pushw	0x7f08
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_129:
	pushw	172
	nop
	.byte 0xb3
	pushw	127
	jrl	nc, 0
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_130:
	ldb	w, 172
	nop
	nop
	pushw	0x7f01
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_131:
	ld	xwa, 0x0b0000ac
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_132:
	pop	xhl
	.byte 0xac
	nop
	nop
	pushw	0x7f07
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_133:
	pop	xiy
	.byte 0xac
	nop
	nop
	pushw	0x7f05
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_134:
	pop	xiz
	.byte 0xac
	nop
	nop
	pushw	0x4004
	nop
	jrl	nc, 6
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_135:
	jrl	172
	nop
	.byte 0xae
	pushw	127
	jrl	nc, 0
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_136:
	sub	(xwa), d
	nop
	nop
	pushw	0x7f0b
	nop
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_137:
	sub	(xbc), d
	nop
	nop
	pushw	0xff0a
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_138:
	sub	(xde), d
	nop
	nop
	pushw	0x7f09
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_139:
	.byte 0xb0, 0xad
	nop
	nop
	.byte 0xb1
	pushw	127
	jrl	nc, 0
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_140:
	.byte 0xb2, 0xad
	nop
	nop
	.byte 0xb4
	pushw	127
	jrl	nc, 0
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_141:
	nop
	ld	(xwa), 0
	incf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_142:
	.byte 0x01
	ld	(xwa), 0
	.byte 0xb2
	incf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_143:
	reti
	ld	(xwa), 0
	incf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_144:
	ldio	176, 0
	nop
	incf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_145:
	ldwio	176, 0
	incf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_146:
	pushw	176
	nop
	.byte 0xb3
	incf
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_147:
	ldb	w, 176
	nop
	nop
	incf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_148:
	ld	xwa, 0x0c0000b0
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_149:
	pop	xhl
	ld	(xwa), 0
	incf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_150:
	pop	xiy
	ld	(xwa), 0
	incf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_151:
	pop	xiz
	ld	(xwa), 0
	incf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_152:
	jrl	176
	nop
	.byte 0xae
	incf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_153:
	.byte 0x80
	ld	(xwa), 0
	incf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_154:
	.byte 0x81
	ld	(xwa), 0
	incf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_155:
	.byte 0x82
	ld	(xwa), 0
	incf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_156:
	.byte 0xb0
	ld	(xbc), 0
	.byte 0xb1
	incf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_157:
	.byte 0xb2
	ld	(xbc), 0
	.byte 0xb4
	incf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_158:
	nop
	ld	(xix), 0
	decf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_159:
	.byte 0x01
	ld	(xix), 0
	.byte 0xb2
	decf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_160:
	reti
	ld	(xix), 0
	decf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_161:
	ldio	180, 0
	nop
	decf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_162:
	ldwio	180, 0
	decf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_163:
	pushw	180
	nop
	.byte 0xb3
	decf
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_164:
	ldb	w, 180
	nop
	nop
	decf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_165:
	ld	xwa, 0x0d0000b4
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_166:
	pop	xhl
	ld	(xix), 0
	decf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_167:
	pop	xiy
	ld	(xix), 0
	decf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_168:
	pop	xiz
	ld	(xix), 0
	decf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_169:
	jrl	180
	nop
	.byte 0xae
	decf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_170:
	.byte 0x80
	ld	(xix), 0
	decf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_171:
	.byte 0x81
	ld	(xix), 0
	decf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_172:
	.byte 0x82
	ld	(xix), 0
	decf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_173:
	.byte 0xb0
	ld	(xiy), 0
	.byte 0xb1
	decf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_174:
	.byte 0xb2
	ld	(xiy), 0
	.byte 0xb4
	decf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_175:
	nop
	.byte 0xb8
	nop
	nop
	ret
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_176:
	.byte 0x01, 0xb8
	nop
	nop
	.byte 0xb2
	ret
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_177:
	reti
	.byte 0xb8
	nop
	nop
	ret
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_178:
	ldio	184, 0
	nop
	ret
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_179:
	ldwio	184, 0
	ret
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_180:
	pushw	184
	nop
	.byte 0xb3
	ret
	jrl	nc, 32512
	nop
	nop
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_181:
	ldb	w, 184
	nop
	nop
	ret
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_182:
	ld	xwa, 0x0e0000b8
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_183:
	pop	xhl
	.byte 0xb8
	nop
	nop
	ret
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_184:
	pop	xiy
	.byte 0xb8
	nop
	nop
	ret
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_185:
	pop	xiz
	.byte 0xb8
	nop
	nop
	ret
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_186:
	jrl	184
	nop
	.byte 0xae
	ret
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_187:
	.byte 0x80, 0xb8
	nop
	nop
	ret
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_188:
	.byte 0x81, 0xb8
	nop
	nop
	ret
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_189:
	.byte 0x82, 0xb8
	nop
	nop
	ret
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_190:
	.byte 0xb0, 0xb9
	nop
	nop
	.byte 0xb1
	ret
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_191:
	.byte 0xb2, 0xb9
	nop
	nop
	.byte 0xb4
	ret
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_192:
	nop
	.byte 0xbc
	nop
	nop
	retd	0xff00
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_193:
	.byte 0x01, 0xbc
	nop
	nop
	.byte 0xb2
	retd	127
	jrl	nc, 0
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_194:
	reti
	.byte 0xbc
	nop
	nop
	retd	0x7f03
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_195:
	ldio	188, 0
	nop
	retd	0x8003
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_196:
	ldwio	188, 0
	retd	0x7f08
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_197:
	pushw	188
	nop
	.byte 0xb3
	retd	127
	jrl	nc, 0
	swi	7
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_198:
	ldb	w, 188
	nop
	nop
	retd	0x7f01
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_199:
	ld	xwa, 0x0f0000bc
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_200:
	pop	xhl
	.byte 0xbc
	nop
	nop
	retd	0x7f07
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_201:
	pop	xiy
	.byte 0xbc
	nop
	nop
	retd	0x7f05
	nop
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_202:
	pop	xiz
	.byte 0xbc
	nop
	nop
	retd	0x4004
	nop
	jrl	nc, 6
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
PartParam_Entry_203:
	jrl	188
	nop
	.byte 0xae
	retd	127
	jrl	nc, 0
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_204:
	.byte 0x80, 0xbc
	nop
	nop
	retd	0x7f0b
	nop
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_205:
	.byte 0x81, 0xbc
	nop
	nop
	retd	0xff0a
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_206:
	.byte 0x82, 0xbc
	nop
	nop
	retd	0x7f09
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_207:
	.byte 0xb0, 0xbd
	nop
	nop
	.byte 0xb1
	retd	127
	jrl	nc, 0
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_208:
	.byte 0xb2, 0xbd
	nop
	nop
	.byte 0xb4
	retd	127
	jrl	nc, 0
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_209:
	nop
	.byte 0xc0
	nop
	nop
	rcf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
PartParam_Entry_210:
	.byte 0x01, 0xc0
	nop
	nop
	.byte 0xb2
	rcf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
PartParam_Entry_211:
	reti
	.byte 0xc0
	nop
	nop
	rcf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_212:
	ldio	192, 0
	nop
	rcf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_213:
	ldwio	192, 0
	rcf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
PartParam_Entry_214:
	pushw	192
	nop
	.byte 0xb3
	rcf
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
PartParam_Entry_215:
	ldb	w, 192
	nop
	nop
	rcf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
PartParam_Entry_216:
	ld	xwa, 0x100000c0
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
PartParam_Entry_217:
	pop	xhl
	.byte 0xc0
	nop
	nop
	rcf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_218:
	pop	xiy
	.byte 0xc0
	nop
	nop
	rcf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_219:
	pop	xiz
	.byte 0xc0
	nop
	nop
	rcf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
PartParam_Entry_220:
	jrl	192
	nop
	.byte 0xae
	rcf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_221:
	.byte 0x80, 0xc0
	nop
	nop
	rcf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_222:
	.byte 0x81, 0xc0
	nop
	nop
	rcf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_223:
	.byte 0x82, 0xc0
	nop
	nop
	rcf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
PartParam_Entry_224:
	.byte 0xb0, 0xc1
	nop
	nop
	.byte 0xb1
	rcf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
PartParam_Entry_225:
	.byte 0xb2, 0xc1
	nop
	nop
	.byte 0xb4
	rcf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
PartParam_Entry_226:
	nop
	.byte 0xc4
	nop
	nop
	scf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
PartParam_Entry_227:
	.byte 0x01, 0xc4
	nop
	nop
	.byte 0xb2
	scf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_228:
	reti
	.byte 0xc4
	nop
	nop
	scf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_229:
	ldio	196, 0
	nop
	scf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_230:
	ldwio	196, 0
	scf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_231:
	pushw	196
	nop
	.byte 0xb3
	scf
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_232:
	ldb	w, 196
	nop
	nop
	scf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
ExtPartParam_Entry_233:
	ld	xwa, 0x110000c4
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_234:
	pop	xhl
	.byte 0xc4
	nop
	nop
	scf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_235:
	pop	xiy
	.byte 0xc4
	nop
	nop
	scf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_236:
	pop	xiz
	.byte 0xc4
	nop
	nop
	scf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_237:
	jrl	196
	nop
	.byte 0xae
	scf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_238:
	.byte 0x80, 0xc4
	nop
	nop
	scf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_239:
	.byte 0x81, 0xc4
	nop
	nop
	scf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_240:
	.byte 0x82, 0xc4
	nop
	nop
	scf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_241:
	.byte 0xb0, 0xc5
	nop
	nop
	.byte 0xb1
	scf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_242:
	.byte 0xb2, 0xc5
	nop
	nop
	.byte 0xb4
	scf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_243:
	nop
	.byte 0xc8
	nop
	nop
	ccf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
ExtPartParam_Entry_244:
	.byte 0x01, 0xc8
	nop
	nop
	.byte 0xb2
	ccf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_245:
	reti
	.byte 0xc8
	nop
	nop
	ccf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_246:
	ldio	200, 0
	nop
	ccf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_247:
	ldwio	200, 0
	ccf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_248:
	pushw	200
	nop
	.byte 0xb3
	ccf
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_249:
	ldb	w, 200
	nop
	nop
	ccf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
ExtPartParam_Entry_250:
	ld	xwa, 0x120000c8
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_251:
	pop	xhl
	.byte 0xc8
	nop
	nop
	ccf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_252:
	pop	xiy
	.byte 0xc8
	nop
	nop
	ccf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_253:
	pop	xiz
	.byte 0xc8
	nop
	nop
	ccf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_254:
	jrl	200
	nop
	.byte 0xae
	ccf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_255:
	and	(xwa), w
	nop
	nop
	ccf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_256:
	and	(xbc), w
	nop
	nop
	ccf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_257:
	and	(xde), w
	nop
	nop
	ccf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_258:
	.byte 0xb0, 0xc9
	nop
	nop
	.byte 0xb1
	ccf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_259:
	.byte 0xb2, 0xc9
	nop
	nop
	.byte 0xb4
	ccf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_260:
	nop
	.byte 0xcc
	nop
	nop
	zcf
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
ExtPartParam_Entry_261:
	.byte 0x01, 0xcc
	nop
	nop
	.byte 0xb2
	zcf
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_262:
	reti
	.byte 0xcc
	nop
	nop
	zcf
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_263:
	ldio	204, 0
	nop
	zcf
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_264:
	ldwio	204, 0
	zcf
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_265:
	pushw	204
	nop
	.byte 0xb3
	zcf
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_266:
	ldb	w, 204
	nop
	nop
	zcf
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
ExtPartParam_Entry_267:
	ld	xwa, 0x130000cc
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_268:
	pop	xhl
	.byte 0xcc
	nop
	nop
	zcf
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_269:
	pop	xiy
	.byte 0xcc
	nop
	nop
	zcf
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_270:
	pop	xiz
	.byte 0xcc
	nop
	nop
	zcf
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_271:
	jrl	204
	nop
	.byte 0xae
	zcf
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_272:
	and	(xwa), d
	nop
	nop
	zcf
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_273:
	and	(xbc), d
	nop
	nop
	zcf
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_274:
	and	(xde), d
	nop
	nop
	zcf
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_275:
	.byte 0xb0, 0xcd
	nop
	nop
	.byte 0xb1
	zcf
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_276:
	.byte 0xb2, 0xcd
	nop
	nop
	.byte 0xb4
	zcf
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_277:
	nop
	.byte 0xd0
	nop
	nop
	push_a
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_278:
	.byte 0x01, 0xd0
	nop
	nop
	.byte 0xb2
	push_a
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_279:
	reti
	.byte 0xd0
	nop
	nop
	push_a
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_280:
	ldio	208, 0
	nop
	push_a
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_281:
	ldwio	208, 0
	push_a
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_282:
	pushw	208
	nop
	.byte 0xb3
	push_a
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_283:
	ldb	w, 208
	nop
	nop
	push_a
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_284:
	ld	xwa, 0x140000d0
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_285:
	pop	xhl
	.byte 0xd0
	nop
	nop
	push_a
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_286:
	pop	xiy
	.byte 0xd0
	nop
	nop
	push_a
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_287:
	pop	xiz
	.byte 0xd0
	nop
	nop
	push_a
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_288:
	jrl	208
	nop
	.byte 0xae
	push_a
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_289:
	.byte 0x80, 0xd0
	nop
	nop
	push_a
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_290:
	.byte 0x81, 0xd0
	nop
	nop
	push_a
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_291:
	.byte 0x82, 0xd0
	nop
	nop
	push_a
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_292:
	.byte 0xb0, 0xd1
	nop
	nop
	.byte 0xb1
	push_a
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_293:
	.byte 0xb2, 0xd1
	nop
	nop
	.byte 0xb4
	push_a
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_294:
	nop
	.byte 0xd4
	nop
	nop
	pop_a
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_295:
	.byte 0x01, 0xd4
	nop
	nop
	.byte 0xb2
	pop_a
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_296:
	reti
	.byte 0xd4
	nop
	nop
	pop_a
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_297:
	ldio	212, 0
	nop
	pop_a
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_298:
	ldwio	212, 0
	pop_a
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_299:
	pushw	212
	nop
	.byte 0xb3
	pop_a
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_300:
	ldb	w, 212
	nop
	nop
	pop_a
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_301:
	ld	xwa, 0x150000d4
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
ExtPartParam_Entry_302:
	pop	xhl
	.byte 0xd4
	nop
	nop
	pop_a
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_303:
	pop	xiy
	.byte 0xd4
	nop
	nop
	pop_a
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_304:
	pop	xiz
	.byte 0xd4
	nop
	nop
	pop_a
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
ExtPartParam_Entry_305:
	jrl	212
	nop
	.byte 0xae
	pop_a
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_306:
	.byte 0x80, 0xd4
	nop
	nop
	pop_a
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_307:
	.byte 0x81, 0xd4
	nop
	nop
	pop_a
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_308:
	.byte 0x82, 0xd4
	nop
	nop
	pop_a
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_309:
	.byte 0xb0, 0xd5
	nop
	nop
	.byte 0xb1
	pop_a
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_310:
	.byte 0xb2, 0xd5
	nop
	nop
	.byte 0xb4
	pop_a
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_311:
	nop
	.byte 0xd8
	nop
	nop
	ex_ff
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_312:
	.byte 0x01, 0xd8
	nop
	nop
	.byte 0xb2
	ex_ff
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_313:
	reti
	.byte 0xd8
	nop
	nop
	ex_ff
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_314:
	ldio	216, 0
	nop
	ex_ff
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_315:
	ldwio	216, 0
	ex_ff
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_316:
	pushw	216
	nop
	.byte 0xb3
	ex_ff
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_317:
	ldb	w, 216
	nop
	nop
	ex_ff
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_318:
	ld	xwa, 0x160000d8
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
ExtPartParam_Entry_319:
	pop	xhl
	.byte 0xd8
	nop
	nop
	ex_ff
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_320:
	pop	xiy
	.byte 0xd8
	nop
	nop
	ex_ff
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_321:
	pop	xiz
	.byte 0xd8
	nop
	nop
	ex_ff
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	nop
	swi	7
ExtPartParam_Entry_322:
	jrl	216
	nop
	.byte 0xae
	ex_ff
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_323:
	xor	(xwa), w
	nop
	nop
	ex_ff
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_324:
	xor	(xbc), w
	nop
	nop
	ex_ff
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_325:
	xor	(xde), w
	nop
	nop
	ex_ff
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_326:
	.byte 0xb0, 0xd9
	nop
	nop
	.byte 0xb1
	ex_ff
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_327:
	.byte 0xb2, 0xd9
	nop
	nop
	.byte 0xb4
	ex_ff
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_328:
	nop
	.byte 0xdc
	nop
	nop
	ldf	0
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
ExtPartParam_Entry_329:
	.byte 0x01, 0xdc
	nop
	nop
	.byte 0xb2, 0x17
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_330:
	reti
	.byte 0xdc
	nop
	nop
	ldf	3
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_331:
	ldio	220, 0
	nop
	.byte 0x17
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_332:
	ldwio	220, 0
	.byte 0x17
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_333:
	pushw	220
	nop
	.byte 0xb3, 0x17
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_334:
	ldb	w, 220
	nop
	nop
	.byte 0x17, 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
ExtPartParam_Entry_335:
	ld	xwa, 0x170000dc
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_336:
	pop	xhl
	.byte 0xdc
	nop
	nop
	ldf	7
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_337:
	pop	xiy
	.byte 0xdc
	nop
	nop
	ldf	5
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_338:
	pop	xiz
	.byte 0xdc
	nop
	nop
	.byte 0x17, 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_339:
	jrl	220
	nop
	.byte 0xae, 0x17
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_340:
	xor	(xwa), d
	nop
	nop
	.byte 0x17
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_341:
	xor	(xbc), d
	nop
	nop
	.byte 0x17
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_342:
	xor	(xde), d
	nop
	nop
	.byte 0x17
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_343:
	.byte 0xb0, 0xdd
	nop
	nop
	.byte 0xb1, 0x17
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_344:
	.byte 0xb2, 0xdd
	nop
	nop
	.byte 0xb4, 0x17
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_345:
	nop
	.byte 0xe0
	nop
	nop
	push_f
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	halt
	swi	7
ExtPartParam_Entry_346:
	.byte 0x01, 0xe0
	nop
	nop
	.byte 0xb2
	push_f
	jrl	nc, 32512
	nop
	nop
	pop	sr
	push	sr
	pop	sr
	nop
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_347:
	reti
	.byte 0xe0
	nop
	nop
	push_f
	pop	sr
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_348:
	ldio	224, 0
	nop
	push_f
	pop	sr
	.byte 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_349:
	ldwio	224, 0
	push_f
	ldio	127, 0
	jrl	nc, 0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_350:
	pushw	224
	nop
	.byte 0xb3
	push_f
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x01
	swi	7
ExtPartParam_Entry_351:
	ldb	w, 224
	nop
	nop
	push_f
	.byte 0x01
	jrl	nc, -256
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	.byte 0x04
	swi	7
ExtPartParam_Entry_352:
	ld	xwa, 0x180000e0
	.byte 0x04
	ldio	0, 127
	pop	sr
	nop
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_353:
	pop	xhl
	.byte 0xe0
	nop
	nop
	push_f
	reti
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_354:
	pop	xiy
	.byte 0xe0
	nop
	nop
	push_f
	halt
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_355:
	pop	xiz
	.byte 0xe0
	nop
	nop
	push_f
	.byte 0x04
	ld	xwa, 0x067f00
	nop
	pop	sr
	.byte 0x04
	pop	sr
	.byte 0x01
	push	sr
	swi	7
ExtPartParam_Entry_356:
	jrl	224
	nop
	.byte 0xae
	push_f
	jrl	nc, 32512
	nop
	nop
	swi	7
	nop
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_357:
	.byte 0x80, 0xe0
	nop
	nop
	push_f
	pushw	127
	incf
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_358:
	.byte 0x81, 0xe0
	nop
	nop
	push_f
	ldwio	255, 0xff00
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_359:
	.byte 0x82, 0xe0
	nop
	nop
	push_f
	push	127
	ldw	ix, 76
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_360:
	.byte 0xb0, 0xe1
	nop
	nop
	.byte 0xb1
	push_f
	jrl	nc, 32512
	nop
	nop
	push	sr
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	swi	7
ExtPartParam_Entry_361:
	.byte 0xb2, 0xe1
	nop
	nop
	.byte 0xb4
	push_f
	jrl	nc, 32512
	nop
	nop
	.byte 0x04
	push	sr
	pop	sr
	nop
	nop
	nop
	swi	7
ExtPartParam_Entry_362:
	reti
	.byte 0xe8
	nop
	nop
	.byte 0x98, 0x04
	jrl	nc, 32512
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_363:
	ldio	232, 0
	nop
	.byte 0x98, 0x04, 0x80
	nop
	.byte 0x01
	reti
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_364:
	nop
	.byte 0x80, 0x01
	nop
	nop
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_365:
	.byte 0x01, 0x80, 0x01
	nop
	nop
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_366:
	push	sr
	.byte 0x80, 0x01
	nop
	nop
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_367:
	pop	sr
	.byte 0x80, 0x01
	nop
	nop
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_368:
	.byte 0x04, 0x80, 0x01
	nop
	nop
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
	halt
	ei	7
	nop
	.byte 0x01
	push	sr
	pop	sr
	swi	7
WidgetParam_MidiCC_PitchBend:
	.byte 0xea
	sra	xbc, 0
	reti
	nop
	nop
	pop	sr
	nop
	swi	7
ExtPartParam_Entry_369:
	nop
	.byte 0x82, 0x01
	nop
	nop
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01
	reti
	nop
	nop
	swi	7
ExtPartParam_Entry_370:
	.byte 0x01, 0x82, 0x01
	nop
	nop
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_371:
	push	sr
	.byte 0x82, 0x01
	nop
	nop
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_372:
	pop	sr
	.byte 0x82, 0x01
	nop
	nop
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_373:
	.byte 0x04, 0x82, 0x01
	nop
	nop
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_374:
	halt
	.byte 0x82, 0x01
	nop
	nop
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_375:
	.byte 0x06, 0x82, 0x01
	nop
	nop
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_376:
	nop
	.byte 0x84, 0x01
	nop
	.byte 0x01
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_377:
	.byte 0x01, 0x84, 0x01
	nop
	.byte 0x01
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_378:
	push	sr
	.byte 0x84, 0x01
	nop
	.byte 0x01
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_379:
	pop	sr
	.byte 0x84, 0x01
	nop
	.byte 0x01
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_380:
	.byte 0x04, 0x84, 0x01
	nop
	.byte 0x01
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_381:
	nop
	.byte 0x86, 0x01
	nop
	.byte 0x01, 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_382:
	.byte 0x01, 0x86, 0x01
	nop
	.byte 0x01, 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_383:
	push	sr
	.byte 0x86, 0x01
	nop
	.byte 0x01
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_384:
	pop	sr
	.byte 0x86, 0x01
	nop
	.byte 0x01
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_385:
	.byte 0x04, 0x86, 0x01
	nop
	.byte 0x01, 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_386:
	halt
	.byte 0x86, 0x01
	nop
	.byte 0x01
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_387:
	.byte 0x06, 0x86, 0x01
	nop
	.byte 0x01
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_388:
	nop
	.byte 0x88, 0x01
	nop
	push	sr
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_389:
	.byte 0x01, 0x88, 0x01
	nop
	push	sr
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_390:
	push	sr
	.byte 0x88, 0x01
	nop
	push	sr
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_391:
	pop	sr
	.byte 0x88, 0x01
	nop
	push	sr
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_392:
	.byte 0x04, 0x88, 0x01
	nop
	push	sr
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_393:
	nop
	.byte 0x8a, 0x01
	nop
	push	sr
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_394:
	.byte 0x01, 0x8a, 0x01
	nop
	push	sr
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_395:
	push	sr
	.byte 0x8a, 0x01
	nop
	push	sr
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_396:
	pop	sr
	.byte 0x8a, 0x01
	nop
	push	sr
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_397:
	.byte 0x04, 0x8a, 0x01
	nop
	push	sr
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_398:
	halt
	.byte 0x8a, 0x01
	nop
	push	sr
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_399:
	.byte 0x06, 0x8a, 0x01
	nop
	push	sr
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_400:
	nop
	.byte 0x8c, 0x01
	nop
	pop	sr
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_401:
	.byte 0x01, 0x8c, 0x01
	nop
	pop	sr
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_402:
	push	sr
	.byte 0x8c, 0x01
	nop
	pop	sr
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_403:
	pop	sr
	.byte 0x8c, 0x01
	nop
	pop	sr
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_404:
	.byte 0x04, 0x8c, 0x01
	nop
	pop	sr
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_405:
	nop
	.byte 0x8e, 0x01
	nop
	pop	sr
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_406:
	.byte 0x01, 0x8e, 0x01
	nop
	pop	sr
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_407:
	push	sr
	.byte 0x8e, 0x01
	nop
	pop	sr
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_408:
	pop	sr
	.byte 0x8e, 0x01
	nop
	pop	sr
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_409:
	.byte 0x04, 0x8e, 0x01
	nop
	pop	sr
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_410:
	halt
	.byte 0x8e, 0x01
	nop
	pop	sr
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_411:
	.byte 0x06, 0x8e, 0x01
	nop
	pop	sr
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_412:
	nop
	.byte 0x90, 0x01
	nop
	.byte 0x04
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_413:
	.byte 0x01, 0x90, 0x01
	nop
	.byte 0x04
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_414:
	push	sr
	.byte 0x90, 0x01
	nop
	.byte 0x04
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_415:
	pop	sr
	.byte 0x90, 0x01
	nop
	.byte 0x04
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_416:
	.byte 0x04, 0x90, 0x01
	nop
	.byte 0x04
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_417:
	nop
	.byte 0x92, 0x01
	nop
	.byte 0x04, 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_418:
	.byte 0x01, 0x92, 0x01
	nop
	.byte 0x04, 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_419:
	push	sr
	.byte 0x92, 0x01
	nop
	.byte 0x04
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_420:
	pop	sr
	.byte 0x92, 0x01
	nop
	.byte 0x04
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_421:
	.byte 0x04, 0x92, 0x01
	nop
	.byte 0x04, 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_422:
	halt
	.byte 0x92, 0x01
	nop
	.byte 0x04
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_423:
	.byte 0x06, 0x92, 0x01
	nop
	.byte 0x04
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_424:
	nop
	.byte 0x94, 0x01
	nop
	halt
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_425:
	.byte 0x01, 0x94, 0x01
	nop
	halt
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_426:
	push	sr
	.byte 0x94, 0x01
	nop
	halt
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_427:
	pop	sr
	.byte 0x94, 0x01
	nop
	halt
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_428:
	.byte 0x04, 0x94, 0x01
	nop
	halt
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_429:
	nop
	.byte 0x96, 0x01
	nop
	halt
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_430:
	.byte 0x01, 0x96, 0x01
	nop
	halt
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_431:
	push	sr
	.byte 0x96, 0x01
	nop
	halt
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_432:
	pop	sr
	.byte 0x96, 0x01
	nop
	halt
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_433:
	.byte 0x04, 0x96, 0x01
	nop
	halt
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_434:
	halt
	.byte 0x96, 0x01
	nop
	halt
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_435:
	.byte 0x06, 0x96, 0x01
	nop
	halt
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_436:
	nop
	.byte 0x98, 0x01
	nop
	ei	13
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_437:
	.byte 0x01, 0x98, 0x01
	nop
	ei	13
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_438:
	push	sr
	.byte 0x98, 0x01
	nop
	ei	13
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_439:
	pop	sr
	.byte 0x98, 0x01
	nop
	ei	13
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_440:
	.byte 0x04, 0x98, 0x01
	nop
	ei	12
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_441:
	nop
	.byte 0x9a, 0x01
	nop
	ei	4
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_442:
	.byte 0x01, 0x9a, 0x01
	nop
	ei	4
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_443:
	push	sr
	.byte 0x9a, 0x01
	nop
	ei	12
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_444:
	pop	sr
	.byte 0x9a, 0x01
	nop
	ei	12
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_445:
	.byte 0x04, 0x9a, 0x01
	nop
	ei	4
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_446:
	halt
	.byte 0x9a, 0x01
	nop
	ei	22
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_447:
	.byte 0x06, 0x9a, 0x01
	nop
	ei	12
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_448:
	nop
	.byte 0x9c, 0x01
	nop
	reti
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_449:
	.byte 0x01, 0x9c, 0x01
	nop
	reti
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_450:
	push	sr
	.byte 0x9c, 0x01
	nop
	reti
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_451:
	pop	sr
	.byte 0x9c, 0x01
	nop
	reti
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_452:
	.byte 0x04, 0x9c, 0x01
	nop
	reti
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
ExtPartParam_Entry_453:
	nop
	.byte 0x9e, 0x01
	nop
	reti
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
ExtPartParam_Entry_454:
	.byte 0x01, 0x9e, 0x01
	nop
	reti
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_001:
	push	sr
	.byte 0x9e, 0x01
	nop
	reti
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_002:
	pop	sr
	.byte 0x9e, 0x01
	nop
	reti
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_003:
	.byte 0x04, 0x9e, 0x01
	nop
	reti
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_004:
	halt
	.byte 0x9e, 0x01
	nop
	reti
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_005:
	.byte 0x06, 0x9e, 0x01
	nop
	reti
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_006:
	nop
	.byte 0xa0, 0x01
	nop
	ldio	13, 32
	nop
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_007:
	.byte 0x01, 0xa0, 0x01
	nop
	ldio	13, 15
	nop
	retd	0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_008:
	push	sr
	.byte 0xa0, 0x01
	nop
	ldio	13, 64
	nop
	.byte 0x01, 0x06
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_009:
	pop	sr
	.byte 0xa0, 0x01
	nop
	ldio	13, 128
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_010:
	.byte 0x04, 0xa0, 0x01
	nop
	ldio	12, 7
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_011:
	nop
	.byte 0xa2, 0x01
	nop
	ldio	4, 7
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_012:
	.byte 0x01, 0xa2, 0x01
	nop
	ldio	4, 16
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_013:
	push	sr
	.byte 0xa2, 0x01
	nop
	ldio	12, 8
	nop
	.byte 0x01
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_014:
	pop	sr
	.byte 0xa2, 0x01
	nop
	ldio	12, 32
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_015:
	.byte 0x04, 0xa2, 0x01
	nop
	ldio	4, 32
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_016:
	halt
	.byte 0xa2, 0x01
	nop
	ldio	22, 1
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_017:
	.byte 0x06, 0xa2, 0x01
	nop
	ldio	12, 16
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_018:
	nop
	.byte 0xa4, 0x01
	nop
	push	13
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_019:
	.byte 0x01, 0xa4, 0x01
	nop
	push	13
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_020:
	push	sr
	.byte 0xa4, 0x01
	nop
	push	13
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_021:
	pop	sr
	.byte 0xa4, 0x01
	nop
	push	13
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_022:
	.byte 0x04, 0xa4, 0x01
	nop
	push	12
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_023:
	nop
	.byte 0xa6, 0x01
	nop
	push	4
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_024:
	.byte 0x01, 0xa6, 0x01
	nop
	push	4
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_025:
	push	sr
	.byte 0xa6, 0x01
	nop
	push	12
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_026:
	pop	sr
	.byte 0xa6, 0x01
	nop
	push	12
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_027:
	.byte 0x04, 0xa6, 0x01
	nop
	push	4
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_028:
	halt
	.byte 0xa6, 0x01
	nop
	push	22
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_029:
	.byte 0x06, 0xa6, 0x01
	nop
	push	12
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_030:
	nop
	.byte 0xa8, 0x01
	nop
	ldwio	13, 32
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_031:
	.byte 0x01, 0xa8, 0x01
	nop
	ldwio	13, 15
	retd	0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_032:
	push	sr
	.byte 0xa8, 0x01
	nop
	ldwio	13, 64
	.byte 0x01, 0x06
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_033:
	pop	sr
	.byte 0xa8, 0x01
	nop
	ldwio	13, 128
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_034:
	.byte 0x04, 0xa8, 0x01
	nop
	ldwio	12, 7
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_035:
	nop
	.byte 0xaa, 0x01
	nop
	ldwio	4, 7
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_036:
	.byte 0x01, 0xaa, 0x01
	nop
	ldwio	4, 16
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_037:
	push	sr
	.byte 0xaa, 0x01
	nop
	ldwio	12, 8
	.byte 0x01
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_038:
	pop	sr
	.byte 0xaa, 0x01
	nop
	ldwio	12, 32
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_039:
	.byte 0x04, 0xaa, 0x01
	nop
	ldwio	4, 32
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_040:
	halt
	.byte 0xaa, 0x01
	nop
	ldwio	22, 1
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_041:
	.byte 0x06, 0xaa, 0x01
	nop
	ldwio	12, 16
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_042:
	nop
	.byte 0xac, 0x01
	nop
	pushw	8205
	nop
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_043:
	.byte 0x01, 0xac, 0x01
	nop
	pushw	3853
	nop
	retd	0
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_044:
	push	sr
	.byte 0xac, 0x01
	nop
	pushw	0x400d
	nop
	.byte 0x01, 0x06
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_045:
	pop	sr
	.byte 0xac, 0x01
	nop
	pushw	0x800d
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_046:
	.byte 0x04, 0xac, 0x01
	nop
	pushw	1804
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_047:
	nop
	.byte 0xae, 0x01
	nop
	pushw	1796
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_048:
	.byte 0x01, 0xae, 0x01
	nop
	pushw	4100
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_049:
	push	sr
	.byte 0xae, 0x01
	nop
	pushw	2060
	nop
	.byte 0x01
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_050:
	pop	sr
	.byte 0xae, 0x01
	nop
	pushw	8204
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_051:
	.byte 0x04, 0xae, 0x01
	nop
	pushw	8196
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_052:
	halt
	.byte 0xae, 0x01
	nop
	pushw	278
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_053:
	.byte 0x06, 0xae, 0x01
	nop
	pushw	4108
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_054:
	nop
	.byte 0xb0, 0x01
	nop
	incf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_055:
	.byte 0x01, 0xb0, 0x01
	nop
	incf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_056:
	push	sr
	.byte 0xb0, 0x01
	nop
	incf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_057:
	pop	sr
	.byte 0xb0, 0x01
	nop
	incf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_058:
	.byte 0x04, 0xb0, 0x01
	nop
	incf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_059:
	nop
	.byte 0xb2, 0x01
	nop
	incf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_060:
	.byte 0x01, 0xb2, 0x01
	nop
	incf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_061:
	push	sr
	.byte 0xb2, 0x01
	nop
	incf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_062:
	pop	sr
	.byte 0xb2, 0x01
	nop
	incf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_063:
	.byte 0x04, 0xb2, 0x01
	nop
	incf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_064:
	halt
	.byte 0xb2, 0x01
	nop
	incf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_065:
	.byte 0x06, 0xb2, 0x01
	nop
	incf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_066:
	nop
	.byte 0xb4, 0x01
	nop
	decf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_067:
	.byte 0x01, 0xb4, 0x01
	nop
	decf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_068:
	push	sr
	.byte 0xb4, 0x01
	nop
	decf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_069:
	pop	sr
	.byte 0xb4, 0x01
	nop
	decf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_070:
	.byte 0x04, 0xb4, 0x01
	nop
	decf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_071:
	nop
	.byte 0xb6, 0x01
	nop
	decf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_072:
	.byte 0x01, 0xb6, 0x01
	nop
	decf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_073:
	push	sr
	.byte 0xb6, 0x01
	nop
	decf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_074:
	pop	sr
	.byte 0xb6, 0x01
	nop
	decf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_075:
	.byte 0x04, 0xb6, 0x01
	nop
	decf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_076:
	halt
	.byte 0xb6, 0x01
	nop
	decf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_077:
	.byte 0x06, 0xb6, 0x01
	nop
	decf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_078:
	nop
	ld	(xwa+1), 14
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_079:
	.byte 0x01
	ld	(xwa+1), 14
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_080:
	push	sr
	ld	(xwa+1), 14
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_081:
	pop	sr
	ld	(xwa+1), 14
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_082:
	.byte 0x04
	ld	(xwa+1), 14
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_083:
	nop
	ld	(xde+1), 14
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_084:
	.byte 0x01
	ld	(xde+1), 14
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_085:
	push	sr
	ld	(xde+1), 14
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_086:
	pop	sr
	ld	(xde+1), 14
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_087:
	.byte 0x04
	ld	(xde+1), 14
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_088:
	halt
	ld	(xde+1), 14
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_089:
	.byte 0x06
	ld	(xde+1), 14
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_090:
	nop
	ld	(xix+1), 15
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_091:
	.byte 0x01
	ld	(xix+1), 15
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_092:
	push	sr
	ld	(xix+1), 15
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_093:
	pop	sr
	ld	(xix+1), 15
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_094:
	.byte 0x04
	ld	(xix+1), 15
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_095:
	nop
	ld	(xiz+1), 15
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01
	reti
	nop
	nop
	swi	7
SeqMixParam_Entry_096:
	.byte 0x01
	ld	(xiz+1), 15
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_097:
	push	sr
	ld	(xiz+1), 15
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_098:
	pop	sr
	ld	(xiz+1), 15
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_099:
	.byte 0x04
	ld	(xiz+1), 15
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_100:
	halt
	ld	(xiz+1), 15
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_101:
	.byte 0x06
	ld	(xiz+1), 15
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_102:
	nop
	.byte 0xc0, 0x01
	nop
	rcf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_103:
	.byte 0x01, 0xc0, 0x01
	nop
	rcf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_104:
	push	sr
	.byte 0xc0, 0x01
	nop
	rcf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_105:
	pop	sr
	.byte 0xc0, 0x01
	nop
	rcf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_106:
	.byte 0x04, 0xc0, 0x01
	nop
	rcf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_107:
	nop
	.byte 0xc2, 0x01
	nop
	rcf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01
	reti
	nop
	nop
	swi	7
SeqMixParam_Entry_108:
	.byte 0x01, 0xc2, 0x01
	nop
	rcf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_109:
	push	sr
	.byte 0xc2, 0x01
	nop
	rcf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_110:
	pop	sr
	.byte 0xc2, 0x01
	nop
	rcf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_111:
	.byte 0x04, 0xc2, 0x01
	nop
	rcf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_112:
	halt
	.byte 0xc2, 0x01
	nop
	rcf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_113:
	.byte 0x06, 0xc2, 0x01
	nop
	rcf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_114:
	nop
	.byte 0xc4, 0x01
	nop
	scf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_115:
	.byte 0x01, 0xc4, 0x01
	nop
	scf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_116:
	push	sr
	.byte 0xc4, 0x01
	nop
	scf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_117:
	pop	sr
	.byte 0xc4, 0x01
	nop
	scf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_118:
	.byte 0x04, 0xc4, 0x01
	nop
	scf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_119:
	nop
	.byte 0xc6, 0x01
	nop
	scf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_120:
	.byte 0x01, 0xc6, 0x01
	nop
	scf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_121:
	push	sr
	.byte 0xc6, 0x01
	nop
	scf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_122:
	pop	sr
	.byte 0xc6, 0x01
	nop
	scf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_123:
	.byte 0x04, 0xc6, 0x01
	nop
	scf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_124:
	halt
	.byte 0xc6, 0x01
	nop
	scf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_125:
	.byte 0x06, 0xc6, 0x01
	nop
	scf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_126:
	nop
	.byte 0xc8, 0x01
	nop
	ccf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_127:
	.byte 0x01, 0xc8, 0x01
	nop
	ccf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_128:
	push	sr
	.byte 0xc8, 0x01
	nop
	ccf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_129:
	pop	sr
	.byte 0xc8, 0x01
	nop
	ccf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_130:
	.byte 0x04, 0xc8, 0x01
	nop
	ccf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_131:
	nop
	.byte 0xca, 0x01
	nop
	ccf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_132:
	.byte 0x01, 0xca, 0x01
	nop
	ccf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_133:
	push	sr
	.byte 0xca, 0x01
	nop
	ccf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_134:
	pop	sr
	.byte 0xca, 0x01
	nop
	ccf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_135:
	.byte 0x04, 0xca, 0x01
	nop
	ccf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_136:
	halt
	.byte 0xca, 0x01
	nop
	ccf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_137:
	.byte 0x06, 0xca, 0x01
	nop
	ccf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_138:
	nop
	.byte 0xcc, 0x01
	nop
	zcf
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_139:
	.byte 0x01, 0xcc, 0x01
	nop
	zcf
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_140:
	push	sr
	.byte 0xcc, 0x01
	nop
	zcf
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_141:
	pop	sr
	.byte 0xcc, 0x01
	nop
	zcf
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_142:
	.byte 0x04, 0xcc, 0x01
	nop
	zcf
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_143:
	nop
	.byte 0xce, 0x01
	nop
	zcf
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_144:
	.byte 0x01, 0xce, 0x01
	nop
	zcf
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_145:
	push	sr
	.byte 0xce, 0x01
	nop
	zcf
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_146:
	pop	sr
	.byte 0xce, 0x01
	nop
	zcf
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_147:
	.byte 0x04, 0xce, 0x01
	nop
	zcf
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_148:
	halt
	.byte 0xce, 0x01
	nop
	zcf
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_149:
	.byte 0x06, 0xce, 0x01
	nop
	zcf
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_150:
	nop
	.byte 0xd0, 0x01
	nop
	push_a
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_151:
	.byte 0x01, 0xd0, 0x01
	nop
	push_a
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_152:
	push	sr
	.byte 0xd0, 0x01
	nop
	push_a
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_153:
	pop	sr
	.byte 0xd0, 0x01
	nop
	push_a
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_154:
	.byte 0x04, 0xd0, 0x01
	nop
	push_a
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_155:
	nop
	.byte 0xd2, 0x01
	nop
	push_a
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_156:
	.byte 0x01, 0xd2, 0x01
	nop
	push_a
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_157:
	push	sr
	.byte 0xd2, 0x01
	nop
	push_a
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_158:
	pop	sr
	.byte 0xd2, 0x01
	nop
	push_a
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_159:
	.byte 0x04, 0xd2, 0x01
	nop
	push_a
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_160:
	halt
	.byte 0xd2, 0x01
	nop
	push_a
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_161:
	.byte 0x06, 0xd2, 0x01
	nop
	push_a
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_162:
	nop
	.byte 0xd4, 0x01
	nop
	pop_a
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_163:
	.byte 0x01, 0xd4, 0x01
	nop
	pop_a
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_164:
	push	sr
	.byte 0xd4, 0x01
	nop
	pop_a
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_165:
	pop	sr
	.byte 0xd4, 0x01
	nop
	pop_a
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_166:
	.byte 0x04, 0xd4, 0x01
	nop
	pop_a
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_167:
	nop
	.byte 0xd6, 0x01
	nop
	pop_a
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_168:
	.byte 0x01, 0xd6, 0x01
	nop
	pop_a
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_169:
	push	sr
	.byte 0xd6, 0x01
	nop
	pop_a
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_170:
	pop	sr
	.byte 0xd6, 0x01
	nop
	pop_a
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_171:
	.byte 0x04, 0xd6, 0x01
	nop
	pop_a
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_172:
	halt
	.byte 0xd6, 0x01
	nop
	pop_a
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_173:
	.byte 0x06, 0xd6, 0x01
	nop
	pop_a
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_174:
	nop
	.byte 0xd8, 0x01
	nop
	ex_ff
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_175:
	.byte 0x01, 0xd8, 0x01
	nop
	ex_ff
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_176:
	push	sr
	.byte 0xd8, 0x01
	nop
	ex_ff
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_177:
	pop	sr
	.byte 0xd8, 0x01
	nop
	ex_ff
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_178:
	.byte 0x04, 0xd8, 0x01
	nop
	ex_ff
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_179:
	nop
	.byte 0xda, 0x01
	nop
	ex_ff
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_180:
	.byte 0x01, 0xda, 0x01
	nop
	ex_ff
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_181:
	push	sr
	.byte 0xda, 0x01
	nop
	ex_ff
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_182:
	pop	sr
	.byte 0xda, 0x01
	nop
	ex_ff
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_183:
	.byte 0x04, 0xda, 0x01
	nop
	ex_ff
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_184:
	halt
	.byte 0xda, 0x01
	nop
	ex_ff
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_185:
	.byte 0x06, 0xda, 0x01
	nop
	ex_ff
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_186:
	nop
	.byte 0xdc, 0x01
	nop
	ldf	13
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_187:
	.byte 0x01, 0xdc, 0x01
	nop
	ldf	13
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_188:
	push	sr
	.byte 0xdc, 0x01
	nop
	ldf	13
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_189:
	pop	sr
	.byte 0xdc, 0x01
	nop
	ldf	13
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_190:
	.byte 0x04, 0xdc, 0x01
	nop
	ldf	12
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_191:
	nop
	.byte 0xde, 0x01
	nop
	.byte 0x17, 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_192:
	.byte 0x01, 0xde, 0x01
	nop
	.byte 0x17, 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_193:
	push	sr
	.byte 0xde, 0x01
	nop
	ldf	12
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_194:
	pop	sr
	.byte 0xde, 0x01
	nop
	ldf	12
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_195:
	.byte 0x04, 0xde, 0x01
	nop
	.byte 0x17, 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_196:
	halt
	.byte 0xde, 0x01
	nop
	ldf	22
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_197:
	.byte 0x06, 0xde, 0x01
	nop
	ldf	12
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_198:
	nop
	.byte 0xe0, 0x01
	nop
	push_f
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_199:
	.byte 0x01, 0xe0, 0x01
	nop
	push_f
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_200:
	push	sr
	.byte 0xe0, 0x01
	nop
	push_f
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_201:
	pop	sr
	.byte 0xe0, 0x01
	nop
	push_f
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_202:
	.byte 0x04, 0xe0, 0x01
	nop
	push_f
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_203:
	nop
	.byte 0xe2, 0x01
	nop
	push_f
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_204:
	.byte 0x01, 0xe2, 0x01
	nop
	push_f
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_205:
	push	sr
	.byte 0xe2, 0x01
	nop
	push_f
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_206:
	pop	sr
	.byte 0xe2, 0x01
	nop
	push_f
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_207:
	.byte 0x04, 0xe2, 0x01
	nop
	push_f
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_208:
	halt
	.byte 0xe2, 0x01
	nop
	push_f
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_209:
	.byte 0x06, 0xe2, 0x01
	nop
	push_f
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_210:
	nop
	.byte 0xe4, 0x01
	nop
	pop_f
	decf
	ldb	w, 0
	.byte 0x01
	halt
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_211:
	.byte 0x01, 0xe4, 0x01
	nop
	pop_f
	decf
	retd	3840
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_212:
	push	sr
	.byte 0xe4, 0x01
	nop
	pop_f
	decf
	ld	xwa, 0xff060100
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_213:
	pop	sr
	.byte 0xe4, 0x01
	nop
	pop_f
	decf
	.byte 0x80
	nop
	.byte 0x01
	reti
	swi	7
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_214:
	.byte 0x04, 0xe4, 0x01
	nop
	pop_f
	incf
	reti
	nop
	jrl	nc, 0
	push	sr
	.byte 0x01
	reti
	halt
	nop
	nop
	swi	7
SeqMixParam_Entry_215:
	nop
	.byte 0xe6, 0x01
	nop
	pop_f
	.byte 0x04
	reti
	nop
	reti
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_216:
	.byte 0x01, 0xe6, 0x01
	nop
	pop_f
	.byte 0x04
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_217:
	push	sr
	.byte 0xe6, 0x01
	nop
	pop_f
	incf
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_218:
	pop	sr
	.byte 0xe6, 0x01
	nop
	pop_f
	incf
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_219:
	.byte 0x04, 0xe6, 0x01
	nop
	pop_f
	.byte 0x04
	ldb	w, 0
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_220:
	halt
	.byte 0xe6, 0x01
	nop
	pop_f
	ex_ff
	.byte 0x01
	nop
	.byte 0x01
	halt
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_221:
	.byte 0x06, 0xe6, 0x01
	nop
	pop_f
	incf
	rcf
	nop
	.byte 0x01, 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_222:
	nop
	.byte 0x80
	push	sr
	nop
	popw	wa
	nop
	swi	7
	nop
	swi	7
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_223:
	.byte 0x01, 0x80
	push	sr
	nop
	popw	wa
	.byte 0x01
	jrl	nc, 1792
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_224:
	push	sr
	.byte 0x80
	push	sr
	nop
	popw	wa
	reti
	ldw	wa, 768
	.byte 0x04
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_225:
	.byte 0x80, 0x80
	push	sr
	nop
	popw	wa
	pop	sr
	reti
	nop
	pop	sr
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_226:
	.byte 0x81, 0x80
	push	sr
	nop
	popw	wa
	pop	sr
	ldio	0, 1
	pop	sr
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_227:
	.byte 0x82, 0x80
	push	sr
	nop
	.byte 0x90
	pop	sr
	.byte 0x01
	nop
	.byte 0x01
	nop
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
SeqMixParam_Entry_228:
	.byte 0x83, 0x80
	push	sr
	nop
	.byte 0x90
	pop	sr
	push	sr
	nop
	.byte 0x01, 0x01
	nop
	swi	7
	.byte 0x01, 0x01, 0x01
	nop
	nop
	swi	7
