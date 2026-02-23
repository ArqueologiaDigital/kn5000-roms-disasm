; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xde
	ld xiz, xbc
	ldda32 xwa, 33200
	cp xiz, 0x1C00018
	jrl z, LABEL_F8EAE9
	cp xiz, 0x1C00017
	jrl z, LABEL_F8EAE9
	cp xiz, 0x1C0000B
	jrl z, LABEL_F8EAD5
	cp xiz, 0x1E50004
	jrl z, LABEL_F8EAA1
	cp xiz, 0x1C00013
	jrl nz, LABEL_F8ECAD
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jrl z, LABEL_F8EA9B
	cp xwa, 0x2
	jrl nz, LABEL_F8ECAD
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34048, 0
	jr ge, LABEL_F8E9AC
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8E9AC:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8EA52
	cps wa, 0
	jr z, LABEL_F8EA38
	cps wa, 5
	jr z, LABEL_F8E9F7
	cpdi16 34058, 0
	jr ge, LABEL_F8E9D8
	call LABEL_F8B16F
	stda16 34058, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8E9D8:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jrl LABEL_F8ECA9

LABEL_F8E9F7:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x48
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8EA94

LABEL_F8EA38:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	call 0xF99490
	jrl LABEL_F8ECAD

LABEL_F8EA52:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x48
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8EA94:
	call LABEL_F994BD
	jrl LABEL_F8ECAD

LABEL_F8EA9B:
	calr CancelOperationCleanup
	jrl LABEL_F8ECAD

LABEL_F8EAA1:
	ld xwa, (xsp + 6)
	stda32 33200, xwa
	call LABEL_F8B015
	stda16 33204, xhl
	cps hl, 0
	jr ge, LABEL_F8EABA
	stdi16 33204, 0

LABEL_F8EABA:
	ldda16 xwa, 33204
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33200
	ld xbc, 0x1E50002
	jrl LABEL_F8ECA9

LABEL_F8EAD5:
	ldda16 xbc, 33204
	exts xbc
	divs bc, 0xA
	muls bc, 0xA
	calr DisplaySmfSequenceList
	jrl LABEL_F8ECAD

LABEL_F8EAE9:
	ld xbc, 0x1C50001
	lds32 xde, 1
	call 0xFA9D58
	ldda16 xhl, 33204
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, LABEL_F8EB2D
	ld xwa, xiz
	cp xwa, 0x1C00018
	jr nz, LABEL_F8EB1B
	ld wa, hl
	inc 1, wa
	cpda16 xwa, 34058
	jrl ge, LABEL_F8EC05
	inc 1, hl
	jr LABEL_F8EB62

LABEL_F8EB1B:
	cp xwa, 0x1C00017
	jrl nz, LABEL_F8EC05
	cps hl, 0
	jrl le, LABEL_F8EC05
	dec 1, hl
	jr LABEL_F8EB62

LABEL_F8EB2D:
	ld xwa, (xsp + 6)
	cp xwa, 0x1
	jr nz, LABEL_F8EB45
	cp hl, 0xA
	jrl lt, LABEL_F8EC05
	sub hl, 0xA
	jr LABEL_F8EB62

LABEL_F8EB45:
	ld xwa, (xsp + 6)
	cp xwa, 0x2
	jr nz, LABEL_F8EB95
	ld wa, hl
	add wa, 0xA
	ldda16 xde, 34058
	cp wa, de
	jr ge, LABEL_F8EB6B
	add hl, 0xA

LABEL_F8EB62:
	stda16 33204, xhl
	ld bc, hl
	jrl LABEL_F8EC09

LABEL_F8EB6B:
	ld bc, de
	dec 1, bc
	ld ix, bc
	exts xix
	divs ix, 0xA
	exts xhl
	divs hl, 0xA
	cp hl, ix
	jrl ge, LABEL_F8EC05
	exts xde
	divs de, 0xA
	ldto_werp WA, 0xEA
	cps wa, 0
	jr z, LABEL_F8EC05
	stda16 33204, xbc
	jr LABEL_F8EC09

LABEL_F8EB95:
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jr nz, LABEL_F8EC05
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F88B8B
	ld wa, hl
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x48
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LABEL_F8EC05:
	ldda16 xbc, 33204

LABEL_F8EC09:
	cp (xsp + 4), bc
	jrl z, LABEL_F8EC9E
	ld wa, bc
	call LABEL_F8B0F1
	ldda16 xwa, 33204
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33200
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldda16 xbc, 33204
	exts xbc
	divs bc, 0xA
	ld de, (xsp + 4)
	exts xde
	divs de, 0xA
	ldda32 xwa, 33200
	cp de, bc
	jr nz, LABEL_F8EC97
	ld bc, (xsp + 4)
	exts xbc
	divs bc, 0xA
	ldto_werp BC, 0xE6
	sll bc, 5
	ldada xhl, 34060
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xwa, 33204
	exts xwa
	divs wa, 0xA
	ldto_werp WA, 0xE2
	sll wa, 5
	ldada xbc, 34060
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 33200
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jr LABEL_F8EC9E

LABEL_F8EC97:
	muls bc, 0xA
	calr DisplaySmfSequenceList

LABEL_F8EC9E:
	ldda32 xwa, 33200
	ld xbc, 0x1C50001
	lds32 xde, 0

LABEL_F8ECA9:
	call 0xFA9D58

LABEL_F8ECAD:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

LABEL_F8ECB3:
	push xiz
	call 0xF8943E
	ldfr_werp HL, 0xFA
	stdi16 35318, 0
	lds iz, 0

LABEL_F8ECC3:
	ld bc, iz
	extz xbc
	ld xwa, 0xEA07AA
	add xwa, xbc
	ld c, (xwa)
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F8ECDB
	slla de

LABEL_F8ECDB:
	and_werp DE, 0xFA
	jrl z, LABEL_F8ED7A
	cps c, 3
	jr nz, LABEL_F8ED11
	call LABEL_F872E5
	cps hl, 0
	jrl z, LABEL_F8ED7A
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, LABEL_F8ED04
	slla de

LABEL_F8ED04:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr nc, LABEL_F8ED73
	jr LABEL_F8ED7A

LABEL_F8ED11:
	ld a, c
	cps c, 2
	jr nz, LABEL_F8ED4A
	call LABEL_F87218
	cps hl, 0
	jr z, LABEL_F8ED7A
	call LABEL_F87366
	cps hl, 0
	jr nz, LABEL_F8ED7A
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, LABEL_F8ED3D
	slla de

LABEL_F8ED3D:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr nc, LABEL_F8ED73
	jr LABEL_F8ED7A

LABEL_F8ED4A:
	call LABEL_F87218
	cps hl, 0
	jr z, LABEL_F8ED7A
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, LABEL_F8ED68
	slla de

LABEL_F8ED68:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr c, LABEL_F8ED7A

LABEL_F8ED73:
	ldto_berp A, 0xF8
	stda8 35320, a

LABEL_F8ED7A:
	inc 1, iz
	cps iz, 4
	jrl c, LABEL_F8ECC3
	pop xiz
	ret

LABEL_F8ED83:
	pushw iz
	ldda8 a, 35320
	cps a, 4
	jr nc, LABEL_F8EDCE
	ldda16 xbc, 35318
	cps bc, 0
	jr z, LABEL_F8EDCE
	lds iz, 1
	extz wa
	ldfr_werp WA, 0xE6
	ldada_24 xde, 15337386

LABEL_F8EDA0:
	ldto_werp HL, 0xE6
	add hl, iz
	and hl, 0x3
	ld wa, hl
	extz xwa
	ld xix, xde
	add xix, xwa
	lds iy, 1
	ld a, (xix)
	and a, 0xF
	jr z, LABEL_F8EDBC
	slla iy

LABEL_F8EDBC:
	and iy, bc
	jr z, LABEL_F8EDC8
	stda8 35320, l
	ldb l, 0x1
	jr LABEL_F8EDD0

LABEL_F8EDC8:
	inc 1, iz
	cps iz, 4
	jr c, LABEL_F8EDA0

LABEL_F8EDCE:
	ldb l, 0x0

LABEL_F8EDD0:
	popw iz
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
	push xiz
	ld xiz, xwa
	ldada_24 xhl, 2020176	; Wallpaper config base address
	extz xbc
	sll xbc, 4	; index * 16
	add xhl, xbc
	lda xhl, (xhl + 16)	; Offset to name field
	x_dpi2_s45 0xF8	; Store type marker
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0x10	; Copy 16 bytes
	call LABEL_F890F2
	ldmi8 (xiz + 16), 0x0	; Null terminate
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name with calculated offset
; Input: XWA = dest buffer, BC = multiplier, E = type marker
WP_GetNameByOffset:
	push xiz
	ld xiz, xwa
	ldada_24 xwa, 2020176
	ld hl, (xwa + 13)	; Get entry size from config
	ld xix, xwa
	mul xhl, xbc	; Calculate offset
	add xix, xhl
	st_a_dri3 0xF1, 0xB2, 0x00	; Offset to name field
	x_dpi2_s45 0xF8
	ld xwa, xiz
	ldw de, 0x10
	call LABEL_F890F2
	ldmi8 (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from ROM table 1 (0xEA07AE)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName1:
	push xiz
	ld xiz, xwa
	x_dpi2_s45 0xF8
	ld wa, bc
	extz xwa
	sll xwa, 2	; index * 4 (pointer size)
	ld xbc, 0xEA07AE	; ROM table address
	add xbc, xwa
	ld xbc, (xbc)	; Get string pointer
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Simple wallpaper pointer lookup from ROM table 2 (0xEA07EA)
; Input: WA = index
; Output: XHL = pointer to name string
WP_GetPresetPtr:
	extz xwa
	sll xwa, 2	; index * 4
	ld xbc, 0xEA07EA
	add xbc, xwa
	ld xhl, (xbc)
	ret

; Get wallpaper name with bank/memory selection
; Input: XWA = dest buffer, BC = bank, DE = memory slot, stack+8 = type marker
WP_GetBankMemName:
	push xiz
	ld hl, bc
	ld xiz, xwa
	x_dpi2_s31 0xF8	; LDA XBC, XIZ+
	ld wa, (xsp + 8)
	ld (xbc), a	; Store type marker
	cps de, 4
	jr nc, WP_GetBankMemName_FromROM
	; From RAM at 0x0948A0
	ldada_24 xbc, 608416
	sll hl, 2
	add hl, de
	mul hl, 0x60	; Entry size = 96 bytes
	add xbc, xhl
	ld xwa, xiz
	ldw de, 0xD	; Copy 13 bytes
	call LABEL_F890F2
	ldmi8 (xiz + 13), 0x0
	jr WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	extz xde
	sll xde, 2
	ld xbc, 0xEA083E	; ROM table address
	add xbc, xde
	ld xbc, (xbc)
	ld xwa, xiz
	call LABEL_F890DC
WP_GetBankMemName_Format:
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	retd 0x2

; Get wallpaper name from ROM table 3 (0xEA08DA)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	push xiz
	ld xiz, xwa
	x_dpi2_s45 0xF8
	ld wa, bc
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA08DA
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from structure at 0x1E0000 (stride 0x1D6)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName1:
	push xiz
	ld xiz, xwa
	ldada_24 xhl, 1966080
	lda xhl, (xhl + 16)
	mul bc, 0x1D6	; Entry stride
	add xhl, xbc
	x_dpi2_s45 0xF8
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0x10
	call LABEL_F890F2
	ldmi8 (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from RAM at 0x1E4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	push xiz
	ld de, bc
	ld xiz, xwa
	ldada_24 xbc, 1984896
	x_dpi2_s45 0xF8
	ld xwa, xiz
	ldw de, 0x10
	call LABEL_F890F2
	ldmi8 (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from structure at 0x1E4AA7 (stride 0x50)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName3:
	push xiz
	ld xiz, xwa
	ldada_24 xhl, 1985191
	mul bc, 0x50	; Entry stride
	add xhl, xbc
	x_dpi2_s45 0xF8
	x_dpi3_o00_t1 0xF8, 0x20	; Space character
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0xD	; Copy 13 bytes
	call LABEL_F890F2
	ldmi8 (xiz + 13), 0x0
	ld xwa, xiz
	ldw bc, 0xF
	calr TrimAndPadSmfFilename
	pop xiz
	ret

