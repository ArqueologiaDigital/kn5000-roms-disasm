; =============================================================================
; file_io/wallpaper.asm - Wallpaper Loading
; =============================================================================
; Wallpaper image loading and display routines.
;
; Key routines:
;   FmmWallpaperLoadFunc             - Wallpaper loading
; =============================================================================

FmmWallpaperLoadFunc:
; [v10] =============================================================================
; [v10] file_io/wallpaper.asm - Wallpaper Loading
; [v10] =============================================================================
; [v10] Wallpaper image loading and display routines.
; [v10] 
; [v10] Key routines:
; [v10] FmmWallpaperLoadFunc             - Wallpaper loading
; [v10] =============================================================================
	dec	6, xsp
	push	xiz
	ld	(xsp + 6), xde
	ld	xiz, xbc
	ld	xwa, (0x8114:16)
	cp	xiz, EVT_INDEXSW_DOWN
	jrl	z, WPLoad_HandleScroll
	cp	xiz, EVT_INDEXSW_UP
	jrl	z, WPLoad_HandleScroll
	cp	xiz, EVT_PAINT
	jrl	z, WPLoad_HandleShow
	cp	xiz, EVT_PS_FILE_NAME_BOX_ID
	jrl	z, WPLoad_HandleSelection
	cp	xiz, EVT_ACTIVATE_STATE
	jrl	nz, WPLoad_Return
	ld	xwa, (xsp + 6)
	cp	xwa, 0x3
	jrl	z, WPLoad_HandleAbort
	cp	xwa, 0x2
	jrl	nz, WPLoad_Return
	ld	(0x8462:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 0x600026
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	.byte	0xd1, 0x64, 0x84, 0x3f, 0x00, 0x00
	jr	ge, WPLoad_DispatchState
	call	GetDiskSizeInfo
	extz	hl
	ld	(0x8464:16), hl
	calr	SignalProgressUpdate
WPLoad_DispatchState:
	ld	wa, (0x8464:16)
	cp	wa, 1:i3
	jrl	z, WPLoad_HandleSuccess
	cp	wa, 0:i3
	jr	z, WPLoad_HandleError
	cp	wa, 5:i3
	jr	z, WPLoad_HandleCancel
	cpw	(0x846e:16), 0
	jr	ge, WPLoad_ContinueWait
	call	FileIO_InitWallpaperNav
	ld	(0x846e:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
WPLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jrl WPLoad_DispatchWidget

WPLoad_HandleCancel:
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ldw	wa, 72
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 0
	ldw	wa, 238
	jr	WPLoad_CallStatusDisplay
WPLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl WPLoad_Return

WPLoad_HandleSuccess:
	calr	ResetProgressIndication
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ldw	wa, 72
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 2
	ldw	wa, 238
WPLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl WPLoad_Return

WPLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl WPLoad_Return

WPLoad_HandleSelection:
	ld	xwa, (xsp+6)
	ld	(33044:16), xwa
	call	FileIO_GetCurrentWallpaperIndex
	ld	(33048:16), hl
	cp	hl, 0:i3
	jr	ge, WPLoad_Selection_Positive
	ldw	(33048:16), 0
WPLoad_Selection_Positive:
	ld	wa, (33048:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33044:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	WPLoad_DispatchWidget
WPLoad_HandleShow:
	ld	bc, (33048:16)
	exts	xbc
	divs	bc, 10
	muls	bc, 10
	calr	DisplaySmfSequenceList
	jrl	WPLoad_Return
WPLoad_HandleScroll:
	ld	xbc, EVT_NOT_POST_AIC
	ld	xde, 1:i3
	call	ApPostEvent
	ld	hl, (33048:16)
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	or	xwa, xwa
	jr	nz, WPLoad_PageScroll	; -> 0xF8E720
	ld	xwa, xiz
	cp	xwa, EVT_INDEXSW_DOWN
	jr	nz, WPLoad_ScrollUp	; -> 0xF8E70E
	ld	wa, hl
	inc	1, wa
	cp	wa, (33902:16)
	jrl	ge, WPLoad_GetSelection	; -> 0xF8E7F8
	inc	1, hl
	jr	WPLoad_StorePosition	; -> 0xF8E755
WPLoad_ScrollUp:
	cp xwa, EVT_INDEXSW_UP
	jrl nz, WPLoad_GetSelection
	cp hl, 0:i3
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
	jr	nz, WPLoad_OpLoad
	ld	wa, hl
	add	wa, 10
	ld	de, (33902:16)
	cp	wa, de
	jr	ge, WPLoad_PageDown_Boundary
	add	hl, 10
WPLoad_StorePosition:
	ld	(33048:16), hl
	ld	bc, hl
	jrl	WPLoad_UpdateDisplay
WPLoad_PageDown_Boundary:
	ld	bc, de
	dec	1, bc
	ld	ix, bc
	exts	xix
	divs	ix, 10
	exts	xhl
	divs	hl, 10
	cp	hl, ix
	jrl	ge, WPLoad_GetSelection
	exts	xde
	divs	de, 10
	ld	wa, qde
	cp	wa, 0:i3
	jr	z, WPLoad_GetSelection
	ld	(33048:16), bc
	jr	WPLoad_UpdateDisplay
WPLoad_OpLoad:
	ld	xwa, (xsp+6)
	cp	xwa, 3
	jr	nz, WPLoad_GetSelection
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	call	LoadFromSecondaryPage
	ld	wa, hl
	ld	bc, 1:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ldw	wa, 72
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	call	SoundCtrl_SendCommand
WPLoad_GetSelection:
	ld	bc, (33048:16)
WPLoad_UpdateDisplay:
	cp	(xsp+4), bc
	jrl	z, WPLoad_SendState
	ld	wa, bc
	call	FileIO_SelectWallpaperByIndex
	ld	wa, (33048:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33044:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	bc, (33048:16)
	exts	xbc
	divs	bc, 10
	ld	de, (xsp+4)
	exts	xde
	divs	de, 10
	ld	xwa, (33044:16)
	cp	de, bc
	jr	nz, WPLoad_RedrawPage
	ld	bc, (xsp+4)
	exts	xbc
	divs	bc, 10
	ld	bc, qbc
	sll	bc, 5
	lda	xhl, (33904:16)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	wa, (33048:16)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda	xbc, (33904:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (33044:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jr	WPLoad_SendState
WPLoad_RedrawPage:
	muls bc, 0xa
	calr DisplaySmfSequenceList

WPLoad_SendState:
	ld	xwa, (33044:16)
	ld	xbc, EVT_NOT_POST_AIC
	ld	xde, 0:i3
WPLoad_DispatchWidget:
	call ApPostEvent

WPLoad_Return:
	ld xhl, 0:i3
	pop xiz
	inc 6, xsp
	ret

WP_ScanAvailability:
	push	xiz
	call	CheckFileSystemStatus
	ld	qiz, hl
	ldw	(35162:16), 0
	ld	iz, 0:i3
WPScan_LoopBody:
	ld bc, iz
	extz xbc
	ld xwa, WPScan_LoopBody_Data
	add xwa, xbc
	ld c, (xwa)
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, WPScan_CheckAvail
	slla de

WPScan_CheckAvail:
	andw_erp DE, 0xfa
	jrl z, WPScan_LoopContinue
	cp c, 3:i3
	jr nz, WPScan_TypeNotThree
	call FileIO_ValidateAndOpenFile
	cp hl, 0:i3
	jrl z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, WPScan_LoopBody_Data
	add xbc, xwa
	ld de, 1:i3
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_MarkAvailable
	slla de

WPScan_MarkAvailable:
	or	(0x895a:16), de
	cp	(0x895c:16), 4
	jr	nc, WPScan_LimitReached
	jr	WPScan_LoopContinue
WPScan_TypeNotThree:
	ld a, c
	cp c, 2:i3
	jr nz, WPScan_TypeGeneric
	call FileIO_ValidateFileSignature
	cp hl, 0:i3
	jr z, WPScan_LoopContinue
	call FileIO_ValidateFileWithRegion
	cp hl, 0:i3
	jr nz, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, WPScan_LoopBody_Data
	add xbc, xwa
	ld de, 1:i3
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_TypeTwo_Mark
	slla de

WPScan_TypeTwo_Mark:
	or	(0x895a:16), de
	cp	(0x895c:16), 4
	jr	nc, WPScan_LimitReached
	jr	WPScan_LoopContinue
WPScan_TypeGeneric:
	call FileIO_ValidateFileSignature
	cp hl, 0:i3
	jr z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, WPScan_LoopBody_Data
	add xbc, xwa
	ld de, 1:i3
	ld a, (xbc)
	and a, 0xf
	jr z, WPScan_Generic_Mark
	slla de

WPScan_Generic_Mark:
	or	(0x895a:16), de
	cp	(0x895c:16), 4
	jr	c, WPScan_LoopContinue
WPScan_LimitReached:
	ldto_berp	A, 0xf8
	ld	(0x895c:16), a
WPScan_LoopContinue:
	inc 1, iz
	cp iz, 4:i3
	jrl c, WPScan_LoopBody
	pop xiz
	ret

WP_FindNextSlot:
	pushw	iz
	ld	a, (35164:16)
	cp	a, 4:i3
	jr	nc, WPFind_NotFound
	ld	bc, (35162:16)
	cp	bc, 0:i3
	jr	z, WPFind_NotFound
	ld	iz, 1:i3
	extz	wa
	ld	qbc, wa
	lda	xde, (WPScan_LoopBody_Data:24)
WPFind_SearchLoop:
	ldto_werp HL, 0xe6
	add hl, iz
	and hl, 0x3
	ld wa, hl
	extz xwa
	ld xix, xde
	add xix, xwa
	ld iy, 1:i3
	ld a, (xix)
	and a, 0xf
	jr z, WPFind_CheckSlot
	slla iy

WPFind_CheckSlot:
	and	iy, bc
	jr	z, WPFind_NextSlot
	ld	(35164:16), l
	ld	l, 1:opc
	jr	WPFind_Return
WPFind_NextSlot:
	inc 1, iz
	cp iz, 4:i3
	jr c, WPFind_SearchLoop

WPFind_NotFound:
	ld l, 0x0:opc

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
	lda xhl, (0x1ed350:24); Wallpaper config base address
	extz xbc
	sll xbc, 4	; index * 16
	add xhl, xbc
	lda xhl, (xhl + 16)	; Offset to name field
	ld (xiz+), e	; Store type marker
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
	lda xwa, (0x1ed350:24)
	ld hl, (xwa + 13)	; Get entry size from config
	ld xix, xwa
	mul xhl, bc	; Calculate offset
	add xix, xhl
	lda xbc, (xix+178:16)	; Offset to name field
	ld (xiz+), e
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
	ld (xiz+), e
	ld wa, bc
	extz xwa
	sll xwa, 2	; index * 4 (pointer size)
	ld xbc, WP_GetPresetName1_PtrTable	; ROM table address
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
	lda xbc, (xiz+:1)	; LDA XBC, XIZ+
	ld wa, (xsp + 8)
	ld (xbc), a	; Store type marker
	cp de, 4:i3
	jr nc, WP_GetBankMemName_FromROM
	; From RAM at 0x0948a0
	lda xbc, (0x0948a0:24)
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
	ld xbc, WP_GetBankMemName_FromROM_PtrTable	; ROM table address
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
	ld (xiz+), e
	ld wa, bc
	extz xwa
	sll xwa, 2
	ld xbc, WP_GetPresetName3_PtrTable
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
	lda xhl, (0x1e0000:24)
	lda xhl, (xhl + 16)
	mul bc, 0x1d6	; Entry stride
	add xhl, xbc
	ld (xiz+), e
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
	lda xbc, (0x1e4980:24)
	ld (xiz+), e
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
	lda xhl, (0x1e4aa7:24)
	mul bc, 0x50	; Entry stride
	add xhl, xbc
	ld (xiz+), e
	ld (xiz+), 0x20	; Space character
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

