; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	.byte 0xef, 0x6e, 0x3e, 0xbf, 0x06, 0x62, 0xe9, 0x8e
	.byte 0xe1, 0x14, 0x81, 0x20, 0xee, 0xcf, 0x18, 0x00
	.byte 0xc0, 0x01, 0x76, 0xa5, 0x01, 0xee, 0xcf, 0x17
	.byte 0x00, 0xc0, 0x01, 0x76, 0x9c, 0x01, 0xee, 0xcf
	.byte 0x0b, 0x00, 0xc0, 0x01, 0x76, 0x7f, 0x01, 0xee
	.byte 0xcf, 0x04, 0x00, 0xe5, 0x01, 0x76, 0x42, 0x01
	.byte 0xee, 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x7e, 0x45
	.byte 0x03, 0xaf, 0x06, 0x20, 0xe8, 0xcf, 0x03, 0x00
	.byte 0x00, 0x00, 0x76, 0x27, 0x01, 0xe8, 0xcf, 0x02
	.byte 0x00, 0x00, 0x00, 0x7e, 0x30, 0x03, 0xf1, 0x62
	.byte 0x84, 0x00, 0x00, 0xd8, 0xa9, 0x1e, 0x7d, 0xc8
	.byte 0x40, 0x26, 0x00, 0x60, 0x00, 0x41, 0x01, 0x00
	.byte 0xc0, 0x01, 0xea, 0xad, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0xd1, 0x64, 0x84, 0x3f, 0x00, 0x00, 0x69, 0x0d
	.byte 0x1d, 0x13, 0x91, 0xf8, 0xdb, 0x12, 0xf1, 0x64
	.byte 0x84, 0x53, 0x1e, 0xb4, 0xc8
WPLoad_DispatchState:
	.byte 0xd1, 0x64, 0x84, 0x20, 0xd8, 0xd9, 0x76, 0x9d
	.byte 0x00, 0xd8, 0xd8, 0x66, 0x7f, 0xd8, 0xdd, 0x66
	.byte 0x3a, 0xd1, 0x6e, 0x84, 0x3f, 0x00, 0x00, 0x69
	.byte 0x13, 0x1d, 0x62, 0xad, 0xf8, 0xf1, 0x6e, 0x84
	.byte 0x53, 0x1d, 0x80, 0x91, 0xf8, 0x1d, 0x2e, 0x91
	.byte 0xf8, 0x1e, 0x88, 0xc8
WPLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jrl WPLoad_DispatchWidget

WPLoad_HandleCancel:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 72
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 0
	ldw	wa, 238
	jr	92
WPLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl WPLoad_Return

WPLoad_HandleSuccess:
	calr	51015
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 72
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 2
	ldw	wa, 238
WPLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl WPLoad_Return

WPLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl WPLoad_Return

WPLoad_HandleSelection:
	ld	xwa, (xsp+6)
	stda32	(33044), xwa
	call	16296968
	stda16	(33048), hl
	cps	hl, 0
	jr	ge, 6
	stdi16	(33048), 0
WPLoad_Selection_Positive:
	ldw_d16	wa, (33048)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33044)
	ld	xbc, 31784962
	jrl	468
WPLoad_HandleShow:
	ldw_d16	bc, (33048)
	exts	xbc
	divs	bc, 10
	muls	bc, 10
	calr	64979
	jrl	452
WPLoad_HandleScroll:
	.byte 0x41, 0x01, 0x00, 0xc5, 0x01, 0xea, 0xa9, 0x1d
	.byte 0x4b, 0x99, 0xfa, 0xd1, 0x18, 0x81, 0x23, 0xbf
	.byte 0x04, 0x53, 0xaf, 0x06, 0x20, 0xe8, 0xe0, 0x6e
	.byte 0x2b, 0xee, 0x88, 0xe8, 0xcf, 0x18, 0x00, 0xc0
	.byte 0x01, 0x6e, 0x0f, 0xdb, 0x88, 0xd8, 0x61, 0xd1
	.byte 0x6e, 0x84, 0xf0, 0x79, 0xee, 0x00, 0xdb, 0x61
	.byte 0x68, 0x47
WPLoad_ScrollUp:
	cp xwa, 0x1c00017
	jrl nz, WPLoad_GetSelection
	cps hl, 0
	jrl le, WPLoad_GetSelection
	dec 1, hl
	jr WPLoad_StorePosition

WPLoad_PageScroll:
	ld xwa, (xsp + 6)
	cp xwa, 0x1
	jr nz, WPLoad_PageDown
	cp hl, 0xa
	jrl lt, WPLoad_GetSelection
	sub hl, 0xa
	jr WPLoad_StorePosition

WPLoad_PageDown:
	ld	xwa, (xsp+6)
	cp	xwa, 2
	jr	nz, 69
	ld	wa, hl
	add	wa, 10
	ldw_d16	de, (33902)
	cp	wa, de
	jr	ge, 13
	add	hl, 10
WPLoad_StorePosition:
	stda16	(33048), hl
	ld	bc, hl
	jrl	158
WPLoad_PageDown_Boundary:
	ld	bc, de
	dec	1, bc
	ld	ix, bc
	exts	xix
	divs	ix, 10
	exts	xhl
	divs	hl, 10
	cp	hl, ix
	jrl	ge, 131
	exts	xde
	divs	de, 10
	ld	wa, qde
	cps	wa, 0
	jr	z, 118
	stda16	(33048), bc
	jr	116
WPLoad_OpLoad:
	ld	xwa, (xsp+6)
	cp	xwa, 3
	jr	nz, 101
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	50767
	call	16287614
	ld	wa, hl
	lds	bc, 1
	calr	51406
	stb_d8	(32422), l
	calr	50841
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 72
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	call	16355504
WPLoad_GetSelection:
	ldw_d16	bc, (33048)
WPLoad_UpdateDisplay:
	cp	(xsp+4), bc
	jrl	z, 143
	ld	wa, bc
	call	16297188
	ldw_d16	wa, (33048)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33044)
	ld	xbc, 31784962
	call	16423243
	ldw_d16	bc, (33048)
	exts	xbc
	divs	bc, 10
	ld	de, (xsp+4)
	exts	xde
	divs	de, 10
	ldda32	xwa, (33044)
	cp	de, bc
	jr	nz, 75
	ld	bc, (xsp+4)
	exts	xbc
	divs	bc, 10
	ld	bc, qbc
	sll	bc, 5
	lda_d16	xhl, (33904)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, 29360143
	call	16423243
	ldw_d16	wa, (33048)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda_d16	xbc, (33904)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33044)
	ld	xbc, 29360143
	call	16423243
	jr	7
WPLoad_RedrawPage:
	muls bc, 0xa
	calr DisplaySmfSequenceList

WPLoad_SendState:
	ldda32	xwa, (33044)
	ld	xbc, 29687809
	lds32	xde, 0
WPLoad_DispatchWidget:
	call ApPostEvent

WPLoad_Return:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

WP_ScanAvailability:
	push	xiz
	call	16289841
	ld	qiz, hl
	stdi16	(35162), 0
	lds	iz, 0
WPScan_LoopBody:
	ld bc, iz
	extz xbc
	ld xwa, Str_SmfConvert_GmToGm_0x2A
	add xwa, xbc
	ld c, (xwa)
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, WPScan_CheckAvail
	slla de

WPScan_CheckAvail:
	andw_erp DE, 0xfa
	jrl z, WPScan_LoopContinue
	cps c, 3
	jr nz, WPScan_TypeNotThree
	call FileIO_ValidateAndOpenFile
	cps hl, 0
	jrl z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, Str_SmfConvert_GmToGm_0x2A
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_MarkAvailable
	slla de

WPScan_MarkAvailable:
	.byte 0xd1, 0x5a, 0x89, 0xea, 0xc1, 0x5c, 0x89, 0x3f
	.byte 0x04, 0x6f, 0x64, 0x68, 0x69
WPScan_TypeNotThree:
	ld a, c
	cps c, 2
	jr nz, WPScan_TypeGeneric
	call FileIO_ValidateFileSignature
	cps hl, 0
	jr z, WPScan_LoopContinue
	call FileIO_ValidateFileWithRegion
	cps hl, 0
	jr nz, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, Str_SmfConvert_GmToGm_0x2A
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_TypeTwo_Mark
	slla de

WPScan_TypeTwo_Mark:
	.byte 0xd1, 0x5a, 0x89, 0xea, 0xc1, 0x5c, 0x89, 0x3f
	.byte 0x04, 0x6f, 0x2b, 0x68, 0x30
WPScan_TypeGeneric:
	call FileIO_ValidateFileSignature
	cps hl, 0
	jr z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, Str_SmfConvert_GmToGm_0x2A
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_Generic_Mark
	slla de

WPScan_Generic_Mark:
	.byte 0xd1, 0x5a, 0x89, 0xea, 0xc1, 0x5c, 0x89, 0x3f
	.byte 0x04, 0x67, 0x07
WPScan_LimitReached:
	.byte 0xc7, 0xf8, 0x89, 0xf1, 0x5c, 0x89, 0x41
WPScan_LoopContinue:
	inc 1, iz
	cps iz, 4
	jrl c, WPScan_LoopBody
	pop xiz
	ret

WP_FindNextSlot:
	pushw	iz
	ldb_d8	a, (35164)
	cps	a, 4
	jr	nc, 66
	ldw_d16	bc, (35162)
	cps	bc, 0
	jr	z, 58
	lds	iz, 1
	extz	wa
	ld	qbc, wa
	lda_24	xde, (15337386)
WPFind_SearchLoop:
	stw_erp HL, 0xe6
	add hl, iz
	and hl, 0x3
	ld wa, hl
	extz xwa
	ld xix, xde
	add xix, xwa
	lds iy, 1
	ld a, (xix)
	and a, 0xf
	jr z, WPFind_CheckSlot
	slla iy

WPFind_CheckSlot:
	and	iy, bc
	jr	z, 8
	stb_d8	(35164), l
	ldb	l, 1
	jr	8
WPFind_NextSlot:
	inc 1, iz
	cps iz, 4
	jr c, WPFind_SearchLoop

WPFind_NotFound:
	ldb l, 0x0

WPFind_Return:
	popw iz
	ret

; -----------------------------------------------------------------------------
; Wallpaper Name Getter Routines
; -----------------------------------------------------------------------------
; These routines retrieve wallpaper display names from various sources:
; - User RAM structures (0x1ed350, 0x1e0000, 0x1e4980, 0x1e4aa7)
; - ROM lookup tables (0xea07ae, 0xea07ea, 0xea083e, 0xea08da)
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
	lda_24 xhl, (0x1ed350); Wallpaper config base address
	extz xbc
	sll xbc, 4	; index * 16
	add xhl, xbc
	lda xhl, (xhl + 16)	; Offset to name field
	lda_dpi XIY, 0xf8	; Store type marker
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0x10	; Copy 16 bytes
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0	; Null terminate
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
	lda_24 xwa, (0x1ed350)
	ld hl, (xwa + 13)	; Get entry size from config
	ld xix, xwa
	mul xhl, xbc	; Calculate offset
	add xix, xhl
	stb_dri A, 0xf1, 0xb2, 0x00	; Offset to name field
	lda_dpi XIY, 0xf8
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from ROM table 1 (0xea07ae)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName1:
	push xiz
	ld xiz, xwa
	lda_dpi XIY, 0xf8
	ld wa, bc
	extz xwa
	sll xwa, 2	; index * 4 (pointer size)
	ld xbc, Str_SmfConvert_GmToGm_0x2E	; ROM table address
	add xbc, xwa
	ld xbc, (xbc)	; Get string pointer
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Simple wallpaper pointer lookup from ROM table 2 (0xea07ea)
; Input: WA = index
; Output: XHL = pointer to name string
WP_GetPresetPtr:
	extz xwa
	sll xwa, 2	; index * 4
	ld xbc, PtrTbl_VariationNames
	add xbc, xwa
	ld xhl, (xbc)
	ret

; Get wallpaper name with bank/memory selection
; Input: XWA = dest buffer, BC = bank, DE = memory slot, stack+8 = type marker
WP_GetBankMemName:
	push xiz
	ld hl, bc
	ld xiz, xwa
	stb_dpi A, 0xf8	; LDA XBC, XIZ+
	ld wa, (xsp + 8)
	ld (xbc), a	; Store type marker
	cps de, 4
	jr nc, WP_GetBankMemName_FromROM
	; From RAM at 0x0948a0
	lda_24 xbc, (0x0948a0)
	sll hl, 2
	add hl, de
	mul hl, 0x60	; Entry size = 96 bytes
	add xbc, xhl
	ld xwa, xiz
	ldw de, 0xd	; Copy 13 bytes
	call FileIO_CopyString_WriteNull
	ld (xiz + 13), 0x0
	jr WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	extz xde
	sll xde, 2
	ld xbc, Str_Variation1_0x8	; ROM table address
	add xbc, xde
	ld xbc, (xbc)
	ld xwa, xiz
	call FileIO_CopyString
WP_GetBankMemName_Format:
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	retd 0x2

; Get wallpaper name from ROM table 3 (0xea08da)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	push xiz
	ld xiz, xwa
	lda_dpi XIY, 0xf8
	ld wa, bc
	extz xwa
	sll xwa, 2
	ld xbc, PtrTbl_DrumKitNames_0x2
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from structure at 0x1e0000 (stride 0x1d6)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName1:
	push xiz
	ld xiz, xwa
	lda_24 xhl, (0x1e0000)
	lda xhl, (xhl + 16)
	mul bc, 0x1d6	; Entry stride
	add xhl, xbc
	lda_dpi XIY, 0xf8
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from RAM at 0x1e4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	push xiz
	ld de, bc
	ld xiz, xwa
	lda_24 xbc, (0x1e4980)
	lda_dpi XIY, 0xf8
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld xwa, xiz
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	pop xiz
	ret

; Get wallpaper name from structure at 0x1e4aa7 (stride 0x50)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetUserName3:
	push xiz
	ld xiz, xwa
	lda_24 xhl, (0x1e4aa7)
	mul bc, 0x50	; Entry stride
	add xhl, xbc
	lda_dpi XIY, 0xf8
	stib_dsp 0xf8, 0x20	; Space character
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0xd	; Copy 13 bytes
	call FileIO_CopyString_WriteNull
	ld (xiz + 13), 0x0
	ld xwa, xiz
	ldw bc, 0xf
	calr TrimAndPadSmfFilename
	pop xiz
	ret

