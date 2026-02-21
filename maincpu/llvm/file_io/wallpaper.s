; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	dec 6, XSP
	push XIZ
	ld (XSP + 0x6), XDE
	ld XIZ, XBC
	ld XWA, (0x81B0)
	cp XIZ, 0x1c00018
	jrl Z, LABEL_F8EAE9
	cp XIZ, 0x1c00017
	jrl Z, LABEL_F8EAE9
	cp XIZ, 0x1c0000b
	jrl Z, LABEL_F8EAD5
	cp XIZ, 0x1e50004
	jrl Z, LABEL_F8EAA1
	cp XIZ, 0x1c00013
	jrl NZ, LABEL_F8ECAD
	ld XWA, (XSP + 0x6)
	cp XWA, 0x3
	jrl Z, LABEL_F8EA9B
	cp XWA, 0x2
	jrl NZ, LABEL_F8ECAD
	ld (0x84FE), 0x0
	ld WA, 1
	CALR InitializeOperationState
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	cpw (0x8500), 0x0
	jr GE, LABEL_F8E9AC
	call GetDiskSizeInfo
	extz HL
	ld (0x8500), HL
	CALR SignalProgressUpdate

LABEL_F8E9AC:
	ld WA, (0x8500)
	cp WA, 1
	jrl Z, LABEL_F8EA52
	cp WA, 0
	jr Z, LABEL_F8EA38
	cp WA, 5
	jr Z, LABEL_F8E9F7
	cpw (0x850A), 0x0
	jr GE, LABEL_F8E9D8
	call LABEL_F8B16F
	ld (0x850A), HL
	call LABEL_F8958D
	call GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F8E9D8:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1c0000a
	ld XDE, 0
	jrl LABEL_F8ECA9

LABEL_F8E9F7:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 0x48
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x0
	ld WA, 0xee
	jr LABEL_F8EA94

LABEL_F8EA38:
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld WA, 0x7d
	call UI_PostModeChangeEvent
	jrl LABEL_F8ECAD

LABEL_F8EA52:
	CALR ResetProgressIndication
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 0x48
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld (0x7F42), 0x2
	ld WA, 0xee

LABEL_F8EA94:
	call LABEL_F994BD
	jrl LABEL_F8ECAD

LABEL_F8EA9B:
	CALR CancelOperationCleanup
	jrl LABEL_F8ECAD

LABEL_F8EAA1:
	ld XWA, (XSP + 0x6)
	ld (0x81B0), XWA
	call LABEL_F8B015
	ld (0x81B4), HL
	cp HL, 0
	jr GE, LABEL_F8EABA
	ldw (0x81B4), 0x0

LABEL_F8EABA:
	ld WA, (0x81B4)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x81B0)
	ld XBC, 0x1e50002
	jrl LABEL_F8ECA9

LABEL_F8EAD5:
	ld BC, (0x81B4)
	exts XBC
	DIVS_BC 0xa
	MULS_BC 0xa
	CALR DisplaySmfSequenceList
	jrl LABEL_F8ECAD

LABEL_F8EAE9:
	ld XBC, 0x1c50001
	ld XDE, 1
	call ApPostEvent
	ld HL, (0x81B4)
	ld (XSP + 0x4), HL
	ld XWA, (XSP + 0x6)
	or XWA, XWA
	jr NZ, LABEL_F8EB2D
	ld XWA, XIZ
	cp XWA, 0x1c00018
	jr NZ, LABEL_F8EB1B
	ld WA, HL
	inc 1, WA
	cp WA, (0x850A)
	jrl GE, LABEL_F8EC05
	inc 1, HL
	jr LABEL_F8EB62

LABEL_F8EB1B:
	cp XWA, 0x1c00017
	jrl NZ, LABEL_F8EC05
	cp HL, 0
	jrl LE, LABEL_F8EC05
	dec 1, HL
	jr LABEL_F8EB62

LABEL_F8EB2D:
	ld XWA, (XSP + 0x6)
	cp XWA, 0x1
	jr NZ, LABEL_F8EB45
	cp HL, 0xa
	jrl LT, LABEL_F8EC05
	sub HL, 0xa
	jr LABEL_F8EB62

LABEL_F8EB45:
	ld XWA, (XSP + 0x6)
	cp XWA, 0x2
	jr NZ, LABEL_F8EB95
	ld WA, HL
	add WA, 0xa
	ld DE, (0x850A)
	cp WA, DE
	jr GE, LABEL_F8EB6B
	add HL, 0xa

LABEL_F8EB62:
	ld (0x81B4), HL
	ld BC, HL
	jrl LABEL_F8EC09

LABEL_F8EB6B:
	ld BC, DE
	dec 1, BC
	ld IX, BC
	exts XIX
	DIVS_IX 0xa
	exts XHL
	DIVS_HL 0xa
	cp HL, IX
	jrl GE, LABEL_F8EC05
	exts XDE
	DIVS_DE 0xa
	ld WA, QDE
	cp WA, 0
	jr Z, LABEL_F8EC05
	ld (0x81B4), BC
	jr LABEL_F8EC09

LABEL_F8EB95:
	ld XWA, (XSP + 0x6)
	cp XWA, 0x3
	jr NZ, LABEL_F8EC05
	ld XWA, 0x600026
	ld XBC, 0x1c00001
	ld XDE, 5
	call ApPostEvent
	ld WA, 0
	CALR InitializeOperationState
	call LABEL_F88B8B
	ld WA, HL
	ld BC, 1
	CALR LABEL_F8B48E
	ld (0x7F42), L
	CALR SignalProgressUpdate
	ld XWA, 0x600026
	ld XBC, 0x1c00002
	ld XDE, 0
	call ApPostEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 1
	call ApPostEvent
	ld WA, 0x48
	call UI_PostModeChangeEvent
	ld XWA, 0xffffffff
	ld XBC, 0x1e0009e
	ld XDE, 0
	call ApPostEvent
	ld WA, 0xee
	call LABEL_F994BD

LABEL_F8EC05:
	ld BC, (0x81B4)

LABEL_F8EC09:
	cp (XSP + 0x4), BC
	jrl Z, LABEL_F8EC9E
	ld WA, BC
	call LABEL_F8B0F1
	ld WA, (0x81B4)
	exts XWA
	DIVS_WA 0xa
	ld DE, QWA
	exts XDE
	ld XWA, (0x81B0)
	ld XBC, 0x1e50002
	call ApPostEvent
	ld BC, (0x81B4)
	exts XBC
	DIVS_BC 0xa
	ld DE, (XSP + 0x4)
	exts XDE
	DIVS_DE 0xa
	ld XWA, (0x81B0)
	cp DE, BC
	jr NZ, LABEL_F8EC97
	ld BC, (XSP + 0x4)
	exts XBC
	DIVS_BC 0xa
	ld BC, QBC
	sll BC, 5
	lda XHL, 0x850C
	ld DE, BC
	extz XDE
	add XDE, XHL
	ld XBC, 0x1c0000f
	call ApPostEvent
	ld WA, (0x81B4)
	exts XWA
	DIVS_WA 0xa
	ld WA, QWA
	sll WA, 5
	lda XBC, 0x850C
	ld DE, WA
	extz XDE
	add XDE, XBC
	ld XWA, (0x81B0)
	ld XBC, 0x1c0000f
	call ApPostEvent
	jr LABEL_F8EC9E

LABEL_F8EC97:
	MULS_BC 0xa
	CALR DisplaySmfSequenceList

LABEL_F8EC9E:
	ld XWA, (0x81B0)
	ld XBC, 0x1c50001
	ld XDE, 0

LABEL_F8ECA9:
	call ApPostEvent

LABEL_F8ECAD:
	ld XHL, 0
	pop XIZ
	inc 6, XSP
	ret

LABEL_F8ECB3:
	push XIZ
	call CheckFileSystemStatus
	ld QIZ, HL
	ldw (0x89F6), 0x0
	ld IZ, 0

LABEL_F8ECC3:
	ld BC, IZ
	extz XBC
	ld XWA, 0xea07aa
	add XWA, XBC
	ld C, (XWA)
	ld DE, 1
	ld A, C
	and A, 0xf
	jr Z, LABEL_F8ECDB
	sll DE, A

LABEL_F8ECDB:
	and DE, QIZ
	jrl Z, LABEL_F8ED7A
	cp C, 3
	jr NZ, LABEL_F8ED11
	call LABEL_F872E5
	cp HL, 0
	jrl Z, LABEL_F8ED7A
	ld WA, IZ
	extz XWA
	ld XBC, 0xea07aa
	add XBC, XWA
	ld DE, 1
	ld A, (XBC)
	and A, 0xf
	jr Z, LABEL_F8ED04
	sll DE, A

LABEL_F8ED04:
	or (0x89F6), DE
	cp (0x89F8), 0x4
	jr NC, LABEL_F8ED73
	jr LABEL_F8ED7A

LABEL_F8ED11:
	ld A, C
	cp C, 2
	jr NZ, LABEL_F8ED4A
	call LABEL_F87218
	cp HL, 0
	jr Z, LABEL_F8ED7A
	call LABEL_F87366
	cp HL, 0
	jr NZ, LABEL_F8ED7A
	ld WA, IZ
	extz XWA
	ld XBC, 0xea07aa
	add XBC, XWA
	ld DE, 1
	ld A, (XBC)
	and A, 0xf
	jr Z, LABEL_F8ED3D
	sll DE, A

LABEL_F8ED3D:
	or (0x89F6), DE
	cp (0x89F8), 0x4
	jr NC, LABEL_F8ED73
	jr LABEL_F8ED7A

LABEL_F8ED4A:
	call LABEL_F87218
	cp HL, 0
	jr Z, LABEL_F8ED7A
	ld WA, IZ
	extz XWA
	ld XBC, 0xea07aa
	add XBC, XWA
	ld DE, 1
	ld A, (XBC)
	and A, 0xf
	jr Z, LABEL_F8ED68
	sll DE, A

LABEL_F8ED68:
	or (0x89F6), DE
	cp (0x89F8), 0x4
	jr C, LABEL_F8ED7A

LABEL_F8ED73:
	ld A, IZL
	ld (0x89F8), A

LABEL_F8ED7A:
	inc 1, IZ
	cp IZ, 4
	jrl C, LABEL_F8ECC3
	pop XIZ
	ret

LABEL_F8ED83:
	push IZ
	ld A, (0x89F8)
	cp A, 4
	jr NC, LABEL_F8EDCE
	ld BC, (0x89F6)
	cp BC, 0
	jr Z, LABEL_F8EDCE
	ld IZ, 1
	extz WA
	ld QBC, WA
	lda XDE, 0xEA07AA

LABEL_F8EDA0:
	ld HL, QBC
	add HL, IZ
	and HL, 0x3
	ld WA, HL
	extz XWA
	ld XIX, XDE
	add XIX, XWA
	ld IY, 1
	ld A, (XIX)
	and A, 0xf
	jr Z, LABEL_F8EDBC
	sll IY, A

LABEL_F8EDBC:
	and IY, BC
	jr Z, LABEL_F8EDC8
	ld (0x89F8), L
	LD_L 0x1
	jr LABEL_F8EDD0

LABEL_F8EDC8:
	inc 1, IZ
	cp IZ, 4
	jr C, LABEL_F8EDA0

LABEL_F8EDCE:
	LD_L 0x0

LABEL_F8EDD0:
	pop IZ
	ret

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
	push XIZ
	ld XIZ, XWA
	lda XHL, 0x1ED350	; Wallpaper config base address
	extz XBC
	sll XBC, 4	; index * 16
	add XHL, XBC
	lda XHL, XHL + 0x10	; Offset to name field
	ld (XIZ+), E	; Store type marker
	ld XWA, XIZ
	ld XBC, XHL
	ld DE, 0x10	; Copy 16 bytes
	call LABEL_F890F2
	ld (XIZ + 0x10), 0x0	; Null terminate
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Get wallpaper name with calculated offset
; Input: XWA = dest buffer, BC = multiplier, E = type marker
WP_GetNameByOffset:
	push XIZ
	ld XIZ, XWA
	lda XWA, 0x1ED350
	ld HL, (XWA + 0xD)	; Get entry size from config
	ld XIX, XWA
	mul XHL, BC	; Calculate offset
	add XIX, XHL
	lda XBC, XIX + 0xB2	; Offset to name field
	ld (XIZ+), E
	ld XWA, XIZ
	ld DE, 0x10
	call LABEL_F890F2
	ld (XIZ + 0x10), 0x0
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Get wallpaper name from ROM table 1 (0xEA07AE)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName1:
	push XIZ
	ld XIZ, XWA
	ld (XIZ+), E
	ld WA, BC
	extz XWA
	sll XWA, 2	; index * 4 (pointer size)
	ld XBC, 0xEA07AE	; ROM table address
	add XBC, XWA
	ld XBC, (XBC)	; Get string pointer
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Simple wallpaper pointer lookup from ROM table 2 (0xEA07EA)
; Input: WA = index
; Output: XHL = pointer to name string
WP_GetPresetPtr:
	extz XWA
	sll XWA, 2	; index * 4
	ld XBC, 0xEA07EA
	add XBC, XWA
	ld XHL, (XBC)
	ret

; Get wallpaper name with bank/memory selection
; Input: XWA = dest buffer, BC = bank, DE = memory slot, stack+8 = type marker
WP_GetBankMemName:
	push XIZ
	ld HL, BC
	ld XIZ, XWA
	.byte 0xf5, 0xf8, 0x31	; LDA XBC, XIZ+
	ld WA, (XSP + 0x8)
	ld (XBC), A	; Store type marker
	cp DE, 4
	jr NC, WP_GetBankMemName_FromROM
	; From RAM at 0x0948A0
	lda XBC, 0x948A0
	sll HL, 2
	add HL, DE
	MUL_HL 0x60	; Entry size = 96 bytes
	add XBC, XHL
	ld XWA, XIZ
	ld DE, 0xD	; Copy 13 bytes
	call LABEL_F890F2
	ld (XIZ + 0xD), 0x0
	jr WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	extz XDE
	sll XDE, 2
	ld XBC, 0xEA083E	; ROM table address
	add XBC, XDE
	ld XBC, (XBC)
	ld XWA, XIZ
	call LABEL_F890DC
WP_GetBankMemName_Format:
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	retd 2

; Get wallpaper name from ROM table 3 (0xEA08DA)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	push XIZ
	ld XIZ, XWA
	ld (XIZ+), E
	ld WA, BC
	extz XWA
	sll XWA, 2
	ld XBC, 0xEA08DA
	add XBC, XWA
	ld XBC, (XBC)
	ld XWA, XIZ
	call LABEL_F890DC
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Get wallpaper name from structure at 0x1E0000 (stride 0x1D6)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName1:
	push XIZ
	ld XIZ, XWA
	lda XHL, 0x1E0000
	lda XHL, XHL + 0x10
	MUL_BC 0x1D6	; Entry stride
	add XHL, XBC
	ld (XIZ+), E
	ld XWA, XIZ
	ld XBC, XHL
	ld DE, 0x10
	call LABEL_F890F2
	ld (XIZ + 0x10), 0x0
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Get wallpaper name from RAM at 0x1E4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	push XIZ
	ld DE, BC
	ld XIZ, XWA
	lda XBC, 0x1E4980
	ld (XIZ+), E
	ld XWA, XIZ
	ld DE, 0x10
	call LABEL_F890F2
	ld (XIZ + 0x10), 0x0
	ld XWA, XIZ
	ld BC, 0x10
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

; Get wallpaper name from structure at 0x1E4AA7 (stride 0x50)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName3:
	push XIZ
	ld XIZ, XWA
	lda XHL, 0x1E4AA7
	MUL_BC 0x50	; Entry stride
	add XHL, XBC
	ld (XIZ+), E
	ld (XIZ+), 0x20	; Space character
	ld XWA, XIZ
	ld XBC, XHL
	ld DE, 0xD	; Copy 13 bytes
	call LABEL_F890F2
	ld (XIZ + 0xD), 0x0
	ld XWA, XIZ
	ld BC, 0xF
	CALR TrimAndPadSmfFilename
	pop XIZ
	ret

