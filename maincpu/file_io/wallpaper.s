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
	jrl z, WPLoad_HandleScroll
	cp xiz, 0x1C00017
	jrl z, WPLoad_HandleScroll
	cp xiz, 0x1C0000B
	jrl z, WPLoad_HandleShow
	cp xiz, 0x1E50004
	jrl z, WPLoad_HandleSelection
	cp xiz, 0x1C00013
	jrl nz, WPLoad_Return
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jrl z, WPLoad_HandleAbort
	cp xwa, 0x2
	jrl nz, WPLoad_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	cpdi16 34048, 0
	jr ge, WPLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

WPLoad_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, WPLoad_HandleSuccess
	cps wa, 0
	jr z, WPLoad_HandleError
	cps wa, 5
	jr z, WPLoad_HandleCancel
	cpdi16 34058, 0
	jr ge, WPLoad_ContinueWait
	call LABEL_F8B16F
	stda16 34058, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

WPLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jrl WPLoad_DispatchWidget

WPLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x48
	call UI_PostModeChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 0
	ldw wa, 0xEE
	jr WPLoad_CallStatusDisplay

WPLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7D
	call UI_PostModeChangeEvent
	jrl WPLoad_Return

WPLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x48
	call UI_PostModeChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 2
	ldw wa, 0xEE

WPLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl WPLoad_Return

WPLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl WPLoad_Return

WPLoad_HandleSelection:
	ld xwa, (xsp + 6)
	stda32 33200, xwa
	call LABEL_F8B015
	stda16 33204, xhl
	cps hl, 0
	jr ge, WPLoad_Selection_Positive
	stdi16 33204, 0

WPLoad_Selection_Positive:
	ldda16 xwa, 33204
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33200
	ld xbc, 0x1E50002
	jrl WPLoad_DispatchWidget

WPLoad_HandleShow:
	ldda16 xbc, 33204
	exts xbc
	divs bc, 0xA
	muls bc, 0xA
	calr DisplaySmfSequenceList
	jrl WPLoad_Return

WPLoad_HandleScroll:
	ld xbc, 0x1C50001
	lds32 xde, 1
	call ApPostEvent
	ldda16 xhl, 33204
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, WPLoad_PageScroll
	ld xwa, xiz
	cp xwa, 0x1C00018
	jr nz, WPLoad_ScrollUp
	ld wa, hl
	inc 1, wa
	cpda16 xwa, 34058
	jrl ge, WPLoad_GetSelection
	inc 1, hl
	jr WPLoad_StorePosition

WPLoad_ScrollUp:
	cp xwa, 0x1C00017
	jrl nz, WPLoad_GetSelection
	cps hl, 0
	jrl le, WPLoad_GetSelection
	dec 1, hl
	jr WPLoad_StorePosition

WPLoad_PageScroll:
	ld xwa, (xsp + 6)
	cp xwa, 0x1
	jr nz, WPLoad_PageDown
	cp hl, 0xA
	jrl lt, WPLoad_GetSelection
	sub hl, 0xA
	jr WPLoad_StorePosition

WPLoad_PageDown:
	ld xwa, (xsp + 6)
	cp xwa, 0x2
	jr nz, WPLoad_OpLoad
	ld wa, hl
	add wa, 0xA
	ldda16 xde, 34058
	cp wa, de
	jr ge, WPLoad_PageDown_Boundary
	add hl, 0xA

WPLoad_StorePosition:
	stda16 33204, xhl
	ld bc, hl
	jrl WPLoad_UpdateDisplay

WPLoad_PageDown_Boundary:
	ld bc, de
	dec 1, bc
	ld ix, bc
	exts xix
	divs ix, 0xA
	exts xhl
	divs hl, 0xA
	cp hl, ix
	jrl ge, WPLoad_GetSelection
	exts xde
	divs de, 0xA
	ldto_werp WA, 0xEA
	cps wa, 0
	jr z, WPLoad_GetSelection
	stda16 33204, xbc
	jr WPLoad_UpdateDisplay

WPLoad_OpLoad:
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jr nz, WPLoad_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call LoadFromSecondaryPage
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 32578, l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x48
	call UI_PostModeChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xEE
	call SoundCtrl_SendCommand

WPLoad_GetSelection:
	ldda16 xbc, 33204

WPLoad_UpdateDisplay:
	cp (xsp + 4), bc
	jrl z, WPLoad_SendState
	ld wa, bc
	call LABEL_F8B0F1
	ldda16 xwa, 33204
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33200
	ld xbc, 0x1E50002
	call ApPostEvent
	ldda16 xbc, 33204
	exts xbc
	divs bc, 0xA
	ld de, (xsp + 4)
	exts xde
	divs de, 0xA
	ldda32 xwa, 33200
	cp de, bc
	jr nz, WPLoad_RedrawPage
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
	call ApPostEvent
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
	call ApPostEvent
	jr WPLoad_SendState

WPLoad_RedrawPage:
	muls bc, 0xA
	calr DisplaySmfSequenceList

WPLoad_SendState:
	ldda32 xwa, 33200
	ld xbc, 0x1C50001
	lds32 xde, 0

WPLoad_DispatchWidget:
	call ApPostEvent

WPLoad_Return:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

WP_ScanAvailability:
	push xiz
	call CheckFileSystemStatus
	ldfr_werp HL, 0xFA
	stdi16 35318, 0
	lds iz, 0

WPScan_LoopBody:
	ld bc, iz
	extz xbc
	ld xwa, 0xEA07AA
	add xwa, xbc
	ld c, (xwa)
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, WPScan_CheckAvail
	slla de

WPScan_CheckAvail:
	and_werp DE, 0xFA
	jrl z, WPScan_LoopContinue
	cps c, 3
	jr nz, WPScan_TypeNotThree
	call LABEL_F872E5
	cps hl, 0
	jrl z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, WPScan_MarkAvailable
	slla de

WPScan_MarkAvailable:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr nc, WPScan_LimitReached
	jr WPScan_LoopContinue

WPScan_TypeNotThree:
	ld a, c
	cps c, 2
	jr nz, WPScan_TypeGeneric
	call LABEL_F87218
	cps hl, 0
	jr z, WPScan_LoopContinue
	call LABEL_F87366
	cps hl, 0
	jr nz, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, WPScan_TypeTwo_Mark
	slla de

WPScan_TypeTwo_Mark:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr nc, WPScan_LimitReached
	jr WPScan_LoopContinue

WPScan_TypeGeneric:
	call LABEL_F87218
	cps hl, 0
	jr z, WPScan_LoopContinue
	ld wa, iz
	extz xwa
	ld xbc, 0xEA07AA
	add xbc, xwa
	lds de, 1
	ld a, (xbc)
	and a, 0xF
	jr z, WPScan_Generic_Mark
	slla de

WPScan_Generic_Mark:
	orddm16 35318, xde
	cpdi8 35320, 4
	jr c, WPScan_LoopContinue

WPScan_LimitReached:
	ldto_berp A, 0xF8
	stda8 35320, a

WPScan_LoopContinue:
	inc 1, iz
	cps iz, 4
	jrl c, WPScan_LoopBody
	pop xiz
	ret

WP_FindNextSlot:
	pushw iz
	ldda8 a, 35320
	cps a, 4
	jr nc, WPFind_NotFound
	ldda16 xbc, 35318
	cps bc, 0
	jr z, WPFind_NotFound
	lds iz, 1
	extz wa
	ldfr_werp WA, 0xE6
	lda_24 xde, 0xea07aa

WPFind_SearchLoop:
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
	jr z, WPFind_CheckSlot
	slla iy

WPFind_CheckSlot:
	and iy, bc
	jr z, WPFind_NextSlot
	stda8 35320, l
	ldb l, 0x1
	jr WPFind_Return

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
	lda_24 xhl, 0x1ed350                  ; Wallpaper config base address
	extz xbc
	sll xbc, 4	; index * 16
	add xhl, xbc
	lda xhl, (xhl + 16)	; Offset to name field
	lda_dpi XIY, 0xF8	; Store type marker
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
	lda_24 xwa, 0x1ed350
	ld hl, (xwa + 13)	; Get entry size from config
	ld xix, xwa
	mul xhl, xbc	; Calculate offset
	add xix, xhl
	st_dri3b A, 0xF1, 0xB2, 0x00	; Offset to name field
	lda_dpi XIY, 0xF8
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
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
	lda_dpi XIY, 0xF8
	ld wa, bc
	extz xwa
	sll xwa, 2	; index * 4 (pointer size)
	ld xbc, 0xEA07AE	; ROM table address
	add xbc, xwa
	ld xbc, (xbc)	; Get string pointer
	ld xwa, xiz
	call FileIO_CopyString
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
	st_dpib A, 0xF8	; LDA XBC, XIZ+
	ld wa, (xsp + 8)
	ld (xbc), a	; Store type marker
	cps de, 4
	jr nc, WP_GetBankMemName_FromROM
	; From RAM at 0x0948A0
	lda_24 xbc, 0x0948a0
	sll hl, 2
	add hl, de
	mul hl, 0x60	; Entry size = 96 bytes
	add xbc, xhl
	ld xwa, xiz
	ldw de, 0xD	; Copy 13 bytes
	call FileIO_CopyString_WriteNull
	ld (xiz + 13), 0x0
	jr WP_GetBankMemName_Format
WP_GetBankMemName_FromROM:
	extz xde
	sll xde, 2
	ld xbc, 0xEA083E	; ROM table address
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

; Get wallpaper name from ROM table 3 (0xEA08DA)
; Input: XWA = dest buffer, BC = index, E = type marker
WP_GetPresetName3:
	push xiz
	ld xiz, xwa
	lda_dpi XIY, 0xF8
	ld wa, bc
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA08DA
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, xiz
	call FileIO_CopyString
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
	lda_24 xhl, 0x1e0000
	lda xhl, (xhl + 16)
	mul bc, 0x1D6	; Entry stride
	add xhl, xbc
	lda_dpi XIY, 0xF8
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

; Get wallpaper name from RAM at 0x1E4980
; Input: XWA = dest buffer, BC = (unused), E = type marker
WP_GetUserName2:
	push xiz
	ld de, bc
	ld xiz, xwa
	lda_24 xbc, 0x1e4980
	lda_dpi XIY, 0xF8
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
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
	lda_24 xhl, 0x1e4aa7
	mul bc, 0x50	; Entry stride
	add xhl, xbc
	lda_dpi XIY, 0xF8
	stib_dpi 0xF8, 0x20	; Space character
	ld xwa, xiz
	ld xbc, xhl
	ldw de, 0xD	; Copy 13 bytes
	call FileIO_CopyString_WriteNull
	ld (xiz + 13), 0x0
	ld xwa, xiz
	ldw bc, 0xF
	calr TrimAndPadSmfFilename
	pop xiz
	ret

