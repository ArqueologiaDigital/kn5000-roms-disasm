; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
	.incbin "includes/generated/v7_transplant_FmmWallpaperLoadFunc.bin"
WPLoad_DispatchState:
	.incbin "includes/generated/v7_transplant_WPLoad_DispatchState.bin"
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
	.incbin "includes/generated/v7_transplant_WPLoad_HandleCancel.bin"
WPLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl WPLoad_Return

WPLoad_HandleSuccess:
	.incbin "includes/generated/v7_transplant_WPLoad_HandleSuccess.bin"
WPLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl WPLoad_Return

WPLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl WPLoad_Return

WPLoad_HandleSelection:
	.incbin "includes/generated/v7_transplant_WPLoad_HandleSelection.bin"
WPLoad_Selection_Positive:
	.incbin "includes/generated/v7_transplant_WPLoad_Selection_Positive.bin"
WPLoad_HandleShow:
	.incbin "includes/generated/v7_transplant_WPLoad_HandleShow.bin"
WPLoad_HandleScroll:
	.incbin "includes/generated/v7_transplant_WPLoad_HandleScroll.bin"
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
	.incbin "includes/generated/v7_transplant_WPLoad_PageDown.bin"
WPLoad_StorePosition:
	.incbin "includes/generated/v7_transplant_WPLoad_StorePosition.bin"
WPLoad_PageDown_Boundary:
	.incbin "includes/generated/v7_transplant_WPLoad_PageDown_Boundary.bin"
WPLoad_OpLoad:
	.incbin "includes/generated/v7_transplant_WPLoad_OpLoad.bin"
WPLoad_GetSelection:
	.incbin "includes/generated/v7_transplant_WPLoad_GetSelection.bin"
WPLoad_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_WPLoad_UpdateDisplay.bin"
WPLoad_RedrawPage:
	muls bc, 0xa
	calr DisplaySmfSequenceList

WPLoad_SendState:
	.incbin "includes/generated/v7_transplant_WPLoad_SendState.bin"
WPLoad_DispatchWidget:
	call ApPostEvent

WPLoad_Return:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

WP_ScanAvailability:
	.incbin "includes/generated/v7_transplant_WP_ScanAvailability.bin"
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
	.incbin "includes/generated/v7_transplant_WPScan_MarkAvailable.bin"
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
	.incbin "includes/generated/v7_transplant_WPScan_TypeTwo_Mark.bin"
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
	.incbin "includes/generated/v7_transplant_WPScan_Generic_Mark.bin"
WPScan_LimitReached:
	.incbin "includes/generated/v7_transplant_WPScan_LimitReached.bin"
WPScan_LoopContinue:
	inc 1, iz
	cps iz, 4
	jrl c, WPScan_LoopBody
	pop xiz
	ret

WP_FindNextSlot:
	.incbin "includes/generated/v7_transplant_WP_FindNextSlot.bin"
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
	.incbin "includes/generated/v7_transplant_WPFind_CheckSlot.bin"
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

