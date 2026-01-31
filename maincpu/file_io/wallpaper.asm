; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	DEC 6, XSP
	PUSH XIZ
	LD (XSP + 006h), XDE
	LD XIZ, XBC
	LD XWA, (81B0h)
	CP XIZ, 01c00018h
	JRL Z, LABEL_F8EAE9
	CP XIZ, 01c00017h
	JRL Z, LABEL_F8EAE9
	CP XIZ, 01c0000bh
	JRL Z, LABEL_F8EAD5
	CP XIZ, 01e50004h
	JRL Z, LABEL_F8EAA1
	CP XIZ, 01c00013h
	JRL NZ, LABEL_F8ECAD
	LD XWA, (XSP + 006h)
	CP XWA, 00000003h
	JRL Z, LABEL_F8EA9B
	CP XWA, 00000002h
	JRL NZ, LABEL_F8ECAD
	LD (84FEh), 000h
	LD WA, 1
	CALR LABEL_F8B204
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CPW (8500h), 0000h
	JR GE, LABEL_F8E9AC
	CALL LABEL_F89520
	EXTZ HL
	LD (8500h), HL
	CALR LABEL_F8B260

LABEL_F8E9AC:
	LD WA, (8500h)
	CP WA, 1
	JRL Z, LABEL_F8EA52
	CP WA, 0
	JR Z, LABEL_F8EA38
	CP WA, 5
	JR Z, LABEL_F8E9F7
	CPW (850Ah), 0000h
	JR GE, LABEL_F8E9D8
	CALL LABEL_F8B16F
	LD (850Ah), HL
	CALL LABEL_F8958D
	CALL LABEL_F8953B
	CALR LABEL_F8B260

LABEL_F8E9D8:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	JRL T, LABEL_F8ECA9

LABEL_F8E9F7:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD WA, 0048h
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 000h
	LD WA, 00eeh
	JR T, LABEL_F8EA94

LABEL_F8EA38:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 007dh
	CALL LABEL_F99490
	JRL T, LABEL_F8ECAD

LABEL_F8EA52:
	CALR LABEL_F8B19C
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD WA, 0048h
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD (7F42h), 002h
	LD WA, 00eeh

LABEL_F8EA94:
	CALL LABEL_F994BD
	JRL T, LABEL_F8ECAD

LABEL_F8EA9B:
	CALR LABEL_F8B244
	JRL T, LABEL_F8ECAD

LABEL_F8EAA1:
	LD XWA, (XSP + 006h)
	LD (81B0h), XWA
	CALL LABEL_F8B015
	LD (81B4h), HL
	CP HL, 0
	JR GE, LABEL_F8EABA
	LDW (81B4h), 0000h

LABEL_F8EABA:
	LD WA, (81B4h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (81B0h)
	LD XBC, 01e50002h
	JRL T, LABEL_F8ECA9

LABEL_F8EAD5:
	LD BC, (81B4h)
	EXTS XBC
	DIVS_BC 000ah
	MULS_BC 000ah
	CALR LABEL_F8E8B9
	JRL T, LABEL_F8ECAD

LABEL_F8EAE9:
	LD XBC, 01c50001h
	LD XDE, 1
	CALL ApPostEvent
	LD HL, (81B4h)
	LD (XSP + 004h), HL
	LD XWA, (XSP + 006h)
	OR XWA, XWA
	JR NZ, LABEL_F8EB2D
	LD XWA, XIZ
	CP XWA, 01c00018h
	JR NZ, LABEL_F8EB1B
	LD WA, HL
	INC 1, WA
	CP WA, (850Ah)
	JRL GE, LABEL_F8EC05
	INC 1, HL
	JR T, LABEL_F8EB62

LABEL_F8EB1B:
	CP XWA, 01c00017h
	JRL NZ, LABEL_F8EC05
	CP HL, 0
	JRL LE, LABEL_F8EC05
	DEC 1, HL
	JR T, LABEL_F8EB62

LABEL_F8EB2D:
	LD XWA, (XSP + 006h)
	CP XWA, 00000001h
	JR NZ, LABEL_F8EB45
	CP HL, 000ah
	JRL LT, LABEL_F8EC05
	SUB HL, 000ah
	JR T, LABEL_F8EB62

LABEL_F8EB45:
	LD XWA, (XSP + 006h)
	CP XWA, 00000002h
	JR NZ, LABEL_F8EB95
	LD WA, HL
	ADD WA, 000ah
	LD DE, (850Ah)
	CP WA, DE
	JR GE, LABEL_F8EB6B
	ADD HL, 000ah

LABEL_F8EB62:
	LD (81B4h), HL
	LD BC, HL
	JRL T, LABEL_F8EC09

LABEL_F8EB6B:
	LD BC, DE
	DEC 1, BC
	LD IX, BC
	EXTS XIX
	DIVS_IX 000ah
	EXTS XHL
	DIVS_HL 000ah
	CP HL, IX
	JRL GE, LABEL_F8EC05
	EXTS XDE
	DIVS_DE 000ah
	LD WA, QDE
	CP WA, 0
	JR Z, LABEL_F8EC05
	LD (81B4h), BC
	JR T, LABEL_F8EC09

LABEL_F8EB95:
	LD XWA, (XSP + 006h)
	CP XWA, 00000003h
	JR NZ, LABEL_F8EC05
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR LABEL_F8B204
	CALL LABEL_F88B8B
	LD WA, HL
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	CALR LABEL_F8B260
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 1
	CALL ApPostEvent
	LD WA, 0048h
	CALL LABEL_F99490
	LD XWA, 0ffffffffh
	LD XBC, 01e0009eh
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00eeh
	CALL LABEL_F994BD

LABEL_F8EC05:
	LD BC, (81B4h)

LABEL_F8EC09:
	CP (XSP + 004h), BC
	JRL Z, LABEL_F8EC9E
	LD WA, BC
	CALL LABEL_F8B0F1
	LD WA, (81B4h)
	EXTS XWA
	DIVS_WA 000ah
	LD DE, QWA
	EXTS XDE
	LD XWA, (81B0h)
	LD XBC, 01e50002h
	CALL ApPostEvent
	LD BC, (81B4h)
	EXTS XBC
	DIVS_BC 000ah
	LD DE, (XSP + 004h)
	EXTS XDE
	DIVS_DE 000ah
	LD XWA, (81B0h)
	CP DE, BC
	JR NZ, LABEL_F8EC97
	LD BC, (XSP + 004h)
	EXTS XBC
	DIVS_BC 000ah
	LD BC, QBC
	SLL 5, BC
	LDA XHL, 850Ch
	LD DE, BC
	EXTZ XDE
	ADD XDE, XHL
	LD XBC, 01c0000fh
	CALL ApPostEvent
	LD WA, (81B4h)
	EXTS XWA
	DIVS_WA 000ah
	LD WA, QWA
	SLL 5, WA
	LDA XBC, 850Ch
	LD DE, WA
	EXTZ XDE
	ADD XDE, XBC
	LD XWA, (81B0h)
	LD XBC, 01c0000fh
	CALL ApPostEvent
	JR T, LABEL_F8EC9E

LABEL_F8EC97:
	MULS_BC 000ah
	CALR LABEL_F8E8B9

LABEL_F8EC9E:
	LD XWA, (81B0h)
	LD XBC, 01c50001h
	LD XDE, 0

LABEL_F8ECA9:
	CALL ApPostEvent

LABEL_F8ECAD:
	LD XHL, 0
	POP XIZ
	INC 6, XSP
	RET

LABEL_F8ECB3:
	PUSH XIZ
	CALL LABEL_F8943E
	LD QIZ, HL
	LDW (89F6h), 0000h
	LD IZ, 0

LABEL_F8ECC3:
	LD BC, IZ
	EXTZ XBC
	LD XWA, 00ea07aah
	ADD XWA, XBC
	LD C, (XWA)
	LD DE, 1
	LD A, C
	AND A, 00fh
	JR Z, LABEL_F8ECDB
	SLL A, DE

LABEL_F8ECDB:
	AND DE, QIZ
	JRL Z, LABEL_F8ED7A
	CP C, 3
	JR NZ, LABEL_F8ED11
	CALL LABEL_F872E5
	CP HL, 0
	JRL Z, LABEL_F8ED7A
	LD WA, IZ
	EXTZ XWA
	LD XBC, 00ea07aah
	ADD XBC, XWA
	LD DE, 1
	LD A, (XBC)
	AND A, 00fh
	JR Z, LABEL_F8ED04
	SLL A, DE

LABEL_F8ED04:
	OR (89F6h), DE
	CP (89F8h), 004h
	JR NC, LABEL_F8ED73
	JR T, LABEL_F8ED7A

LABEL_F8ED11:
	LD A, C
	CP C, 2
	JR NZ, LABEL_F8ED4A
	CALL LABEL_F87218
	CP HL, 0
	JR Z, LABEL_F8ED7A
	CALL LABEL_F87366
	CP HL, 0
	JR NZ, LABEL_F8ED7A
	LD WA, IZ
	EXTZ XWA
	LD XBC, 00ea07aah
	ADD XBC, XWA
	LD DE, 1
	LD A, (XBC)
	AND A, 00fh
	JR Z, LABEL_F8ED3D
	SLL A, DE

LABEL_F8ED3D:
	OR (89F6h), DE
	CP (89F8h), 004h
	JR NC, LABEL_F8ED73
	JR T, LABEL_F8ED7A

LABEL_F8ED4A:
	CALL LABEL_F87218
	CP HL, 0
	JR Z, LABEL_F8ED7A
	LD WA, IZ
	EXTZ XWA
	LD XBC, 00ea07aah
	ADD XBC, XWA
	LD DE, 1
	LD A, (XBC)
	AND A, 00fh
	JR Z, LABEL_F8ED68
	SLL A, DE

LABEL_F8ED68:
	OR (89F6h), DE
	CP (89F8h), 004h
	JR C, LABEL_F8ED7A

LABEL_F8ED73:
	LD A, IZL
	LD (89F8h), A

LABEL_F8ED7A:
	INC 1, IZ
	CP IZ, 4
	JRL C, LABEL_F8ECC3
	POP XIZ
	RET

LABEL_F8ED83:
	PUSH IZ
	LD A, (89F8h)
	CP A, 4
	JR NC, LABEL_F8EDCE
	LD BC, (89F6h)
	CP BC, 0
	JR Z, LABEL_F8EDCE
	LD IZ, 1
	EXTZ WA
	LD QBC, WA
	LDA XDE, 0EA07AAh

LABEL_F8EDA0:
	LD HL, QBC
	ADD HL, IZ
	AND HL, 0003h
	LD WA, HL
	EXTZ XWA
	LD XIX, XDE
	ADD XIX, XWA
	LD IY, 1
	LD A, (XIX)
	AND A, 00fh
	JR Z, LABEL_F8EDBC
	SLL A, IY

LABEL_F8EDBC:
	AND IY, BC
	JR Z, LABEL_F8EDC8
	LD (89F8h), L
	LD_L 001h
	JR T, LABEL_F8EDD0

LABEL_F8EDC8:
	INC 1, IZ
	CP IZ, 4
	JR C, LABEL_F8EDA0

LABEL_F8EDCE:
	LD_L 000h

LABEL_F8EDD0:
	POP IZ
	RET

; -----------------------------------------------------------------------------
; Wallpaper Name Getter Routines
; -----------------------------------------------------------------------------
; These routines retrieve wallpaper display names from various sources:
; - User RAM structures (0x1ED350, 0x1E0000, 0x1E4980, 0x1E4AA7)
; - ROM lookup tables (0xEA07AE, 0xEA07EA, 0xEA083E, 0xEA08DA)
;
; Common calling convention:
;   XWA = destination buffer pointer
;   BC = index or selection parameter
;   E = type marker byte
; -----------------------------------------------------------------------------

; Get wallpaper name from config structure by index
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetConfigName:
	PUSH XIZ
	LD XIZ, XWA
	LDA XHL, 01ED350h		; Wallpaper config base address
	EXTZ XBC
	SLL 4, XBC			; index * 16
	ADD XHL, XBC
	LDA XHL, XHL + 010h		; Offset to name field
	LD (XIZ+), E			; Store type marker
	LD XWA, XIZ
	LD XBC, XHL
	LD DE, 0010h			; Copy 16 bytes
	CALL LABEL_F890F2
	LD (XIZ + 010h), 000h		; Null terminate
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Get wallpaper name with calculated offset
; Input: XWA = dest buffer, BC = multiplier, E = type marker
WP_GetNameByOffset:
	PUSH XIZ
	LD XIZ, XWA
	LDA XWA, 01ED350h
	LD HL, (XWA + 00Dh)		; Get entry size from config
	LD XIX, XWA
	MUL XHL, BC			; Calculate offset
	ADD XIX, XHL
	LDA XBC, XIX + 0B2h		; Offset to name field
	LD (XIZ+), E
	LD XWA, XIZ
	LD DE, 0010h
	CALL LABEL_F890F2
	LD (XIZ + 010h), 000h
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Get wallpaper name from ROM table 1 (0xEA07AE)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName1:
	PUSH XIZ
	LD XIZ, XWA
	LD (XIZ+), E
	LD WA, BC
	EXTZ XWA
	SLL 2, XWA			; index * 4 (pointer size)
	LD XBC, 0EA07AEh		; ROM table address
	ADD XBC, XWA
	LD XBC, (XBC)			; Get string pointer
	LD XWA, XIZ
	CALL LABEL_F890DC
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Simple wallpaper pointer lookup from ROM table 2 (0xEA07EA)
; Input: WA = index
; Output: XHL = pointer to name string
WP_GetPresetPtr:
	EXTZ XWA
	SLL 2, XWA			; index * 4
	LD XBC, 0EA07EAh
	ADD XBC, XWA
	LD XHL, (XBC)
	RET

; Get wallpaper name with bank/memory selection
; Input: XWA = dest buffer, BC = bank, DE = memory slot, stack+8 = type marker
WP_GetBankMemName:
	PUSH XIZ
	LD HL, BC
	LD XIZ, XWA
	db 0f5h, 0f8h, 031h		; LDA XBC, XIZ+
	LD WA, (XSP + 008h)
	LD (XBC), A			; Store type marker
	CP DE, 4
	JR NC, WP_GetBankMemName_FromROM
	; From RAM at 0x0948A0
	LDA XBC, 0948A0h
	SLL 2, HL
	ADD HL, DE
	MUL_HL 0060h			; Entry size = 96 bytes
	ADD XBC, XHL
	LD XWA, XIZ
	LD DE, 000Dh			; Copy 13 bytes
	CALL LABEL_F890F2
	LD (XIZ + 00Dh), 000h
	JR T, WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	EXTZ XDE
	SLL 2, XDE
	LD XBC, 0EA083Eh		; ROM table address
	ADD XBC, XDE
	LD XBC, (XBC)
	LD XWA, XIZ
	CALL LABEL_F890DC
WP_GetBankMemName_Format:
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RETD 2

; Get wallpaper name from ROM table 3 (0xEA08DA)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	PUSH XIZ
	LD XIZ, XWA
	LD (XIZ+), E
	LD WA, BC
	EXTZ XWA
	SLL 2, XWA
	LD XBC, 0EA08DAh
	ADD XBC, XWA
	LD XBC, (XBC)
	LD XWA, XIZ
	CALL LABEL_F890DC
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Get wallpaper name from structure at 0x1E0000 (stride 0x1D6)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName1:
	PUSH XIZ
	LD XIZ, XWA
	LDA XHL, 01E0000h
	LDA XHL, XHL + 010h
	MUL_BC 01D6h			; Entry stride
	ADD XHL, XBC
	LD (XIZ+), E
	LD XWA, XIZ
	LD XBC, XHL
	LD DE, 0010h
	CALL LABEL_F890F2
	LD (XIZ + 010h), 000h
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Get wallpaper name from RAM at 0x1E4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	PUSH XIZ
	LD DE, BC
	LD XIZ, XWA
	LDA XBC, 01E4980h
	LD (XIZ+), E
	LD XWA, XIZ
	LD DE, 0010h
	CALL LABEL_F890F2
	LD (XIZ + 010h), 000h
	LD XWA, XIZ
	LD BC, 0010h
	CALR LABEL_F8DF96
	POP XIZ
	RET

; Get wallpaper name from structure at 0x1E4AA7 (stride 0x50)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName3:
	PUSH XIZ
	LD XIZ, XWA
	LDA XHL, 01E4AA7h
	MUL_BC 0050h			; Entry stride
	ADD XHL, XBC
	LD (XIZ+), E
	LD (XIZ+), 020h			; Space character
	LD XWA, XIZ
	LD XBC, XHL
	LD DE, 000Dh			; Copy 13 bytes
	CALL LABEL_F890F2
	LD (XIZ + 00Dh), 000h
	LD XWA, XIZ
	LD BC, 000Fh
	CALR LABEL_F8DF96
	POP XIZ
	RET

