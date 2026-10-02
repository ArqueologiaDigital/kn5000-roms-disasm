; =============================================================================
; UI Widget Definitions (19K lines)
; =============================================================================
;
; Grid box implementations, exit window handling, title/resource
; widgets, event dispatch loops, and object enumeration. Defines
; the widget infrastructure used by all UI screens.
; =============================================================================

AcGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xbc
	ld (xsp + 16), xwa
	ld xwa, xiz
	cp xiz, EVT_REQUEST_GRID_DRAW
	jrl z, AcGridBox_CellSelect
	cp xiz, EVT_GET_FIXED_ROW_STR
	jrl z, AcGridBox_GetRowText
	cp xiz, EVT_GET_FIXED_COL_STR
	jrl z, AcGridBox_GetColText
	cp xiz, EVT_SHOW
	jr z, AcGridBox_Init
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, AcGridBox_Default
	cp xwa, 0x6
	jrl gt, AcGridBox_Default
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x386
	ld wa, (xwa)
	lda xix, (AcGridBox_Init:24)
; Computed jump: target = AcGridBox_Init + Data_SoundEditorCharsLayout_0x386[i], Data_SoundEditorCharsLayout_0x386 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcGridBoxProc_Evt1C00017
;   0x1c00018 -> AcGridBoxProc_Evt1C00018
;   0x1c00019 -> AcGridBoxProc_Evt1C00017
;   0x1c0001a -> AcGridBoxProc_Evt1C00018
;   0x1c0001b -> AcGridBox_Default
;   0x1c0001c -> AcGridBox_CellSelect
;   0x1c0001d -> AcGridBox_CellSelect
	jp	t, (xix+wa)

AcGridBox_Init:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	calr SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	calr SetDialDown
	ld wa, 1:i3
	jrl AcGridBox_EnableDials
AcGridBoxProc_Evt1C00017:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollUp_Alt
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollUp_Alt:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, AcGridBox_ReturnZero
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	calr SetDialDown
	ld wa, 1:i3
	jrl AcGridBox_EnableDials
AcGridBoxProc_Evt1C00018:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollDown_Alt
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollDown_Alt:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ReturnZero
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	calr SetDialDown
	ld wa, 1:i3

AcGridBox_EnableDials:
	calr SetDialEnable
	jr AcGridBox_ReturnZero

AcGridBox_GetColText:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr AcGridBox_CopyText

AcGridBox_GetRowText:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

AcGridBox_CopyText:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcGridBox_ReturnZero

AcGridBox_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall

AcGridBox_ReturnZero:
	ld xhl, 0:i3
	jr AcGridBox_Return

AcGridBox_Default:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc

AcGridBox_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

GridCheck:
	lda xsp, (xsp - 18)
	ld xwa, xbc
	cp xbc, EVT_REQUEST_GRID_DRAW
	jr z, GridCheck_CellSelect
	ld xhl, 0:i3
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jr lt, GridCheck_Return
	cp xwa, 0x6
	jr gt, GridCheck_Return
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x39A
	ld wa, (xwa)
	lda xix, (GridCheck_JumpEnd:24)
; Computed jump: target = GridCheck_JumpEnd + Data_SoundEditorCharsLayout_0x39A[i], Data_SoundEditorCharsLayout_0x39A = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> GridCheck_JumpEnd
;   0x1c00018 -> GridCheck_JumpEnd
;   0x1c00019 -> GridCheck_JumpEnd
;   0x1c0001a -> GridCheck_JumpEnd
;   0x1c0001b -> GridCheck_Return
;   0x1c0001c -> GridCheck_JumpEnd
;   0x1c0001d -> GridCheck_JumpEnd
	jp	t, (xix+wa)

GridCheck_JumpEnd:
	jr	t, GridCheck_Return

GridCheck_CellSelect:
	lda xbc, (xsp + 10)
	ld xwa, xde
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	pushw	(xwa)
	pushw	(xbc)
	pushw 0xea
	pushw 0xa266
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 10)
	ld xbc, EVT_GRID_DRAW
	call SendEvent
	ld xhl, 0:i3

GridCheck_Return:
	lda xsp, (xsp + 18)
	ret

PsEditBoxProc:
	lda xsp, (xsp-540)
	push xiz
	ld	(xsp+536), xde
	ld xiz, xbc
	ld	(xsp+540), xwa
	cp xiz, EVT_CHECK_SELECTED
	jrl z, PsEditBox_CanScroll
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, PsEditBox_ScrollDown
	cp xiz, EVT_INDEXSW_UP
	jrl z, PsEditBox_ScrollUp
	cp xiz, EVT_INDEX_SELECT
	jrl z, PsEditBox_Release
	cp xiz, EVT_SW_IN
	jrl z, PsEditBox_OK
	cp xiz, EVT_GET_STRING
	jrl z, PsEditBox_GetText
	cp xiz, EVT_PARA_DRAW
	jrl z, PsEditBox_Confirm
	cp xiz, EVT_SELE_DRAW
	jrl z, PsEditBox_Select
	cp xiz, EVT_DRAW
	jrl z, PsEditBox_Paint
	cp xiz, EVT_SHOW
	jrl z, PsEditBox_Init
	cp xiz, EVT_SET_SELECTED
	jrl nz, PsEditBox_Default
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 46)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp	xbc, (xsp+536)
	jr z, PsEditBox_SetIndex_CheckDial
	ld xbc, (xwa)
	ld XWA, (xsp + 0x0218)
	ld (xbc), wa
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent

PsEditBox_SetIndex_CheckDial:
	ld xwa, (xiz + 46)
	cpw (xwa), 0x1
	jrl nz, PsEditBox_ReturnZero
	cpw (xiz + 44), 0x0
	jr z, PsEditBox_ReturnZero
	ld de, (xiz + 26)
	exts xde
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_UP
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_DOWN
	calr SetDialDown
	ld wa, 1:i3
	jr PsEditBox_Init_EnableDials

PsEditBox_Init:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 46)
	cpw (xwa), 0x0
	jr z, PsEditBox_ReturnZero
	cpw (xiz + 44), 0x0
	jr z, PsEditBox_ReturnZero
	ld de, (xiz + 26)
	exts xde
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_UP
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_DOWN
	calr SetDialDown
	ld wa, 1:i3

PsEditBox_Init_EnableDials:
	calr SetDialEnable

PsEditBox_ReturnZero:
	ld xhl, 0:i3
	jrl PsEditBox_Return

PsEditBox_Paint:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld wa, (xwa + 42)
	calr DrawEditSw
	lda xbc, (xsp+524)
	ld XWA, (xsp + 0x021c)
	calr GetClientBox
	lda xbc, (xsp+268)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call ConvertStrings
	lda xwa, (xsp+268)
	push xwa
	call Strlen
	ld xwa, (xsp + 12)
	ld iz, (xwa + 40)
	add iz, hl
	lda xwa, (xsp+272)
	push xwa
	call Strlen
	inc 8, xsp
	lda xwa, (xsp+524)
	lda xde, (xwa + 4)
	ld bc, (xde)
	sub bc, (xwa)
	mul xbc, hl
	extz xbc
	div xbc, iz
	ld hl, (xwa)
	add hl, bc
	ld (xde), hl
	lda xbc, (xsp+532)
	calr GetBoxCenter
	lda xwa, (xsp+524)
	lda xde, (xsp+532)
	ld xhl, (xsp + 8)
	ld xbc, (xhl + 32)
	push xbc
	pushw	(xhl+36)
	ld xbc, (xsp + 10)
	pushw	(xbc+22)
	ld c, (xbc + 38)
	extz bc
	pushw bc
	ld xhl, (xhl + 28)
	ld xbc, xde
	ld xde, xhl
	call DrawStringAlignment
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jrl PsEditBox_Dispatch

PsEditBox_Select:
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	cpw (xhl + 42), 0xff
	jrl z, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	ld de, (xwa)
	exts xde
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_DRAW_SELECTED
	jrl PsEditBox_Dispatch

PsEditBox_Confirm:
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld (xsp + 8), xhl
	lda xbc, (xsp+524)
	ld XWA, (xsp + 0x021c)
	calr GetClientBox
	lda xbc, (xsp+268)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call ConvertStrings
	lda xwa, (xsp+268)
	push xwa
	call Strlen
	inc 4, xsp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 40)
	ld iy, bc
	add iy, hl
	lda xwa, (xsp+524)
	lda xhl, (xwa + 4)
	ld de, (xhl)
	ld ix, de
	sub ix, (xwa)
	mul xbc, ix
	extz xbc
	div xbc, iy
	sub de, bc
	ld (xwa), de
	decw	6, (xhl)
	lda xbc, (xsp+532)
	calr GetBoxCenter
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x0218)
	or xwa, xwa
	jr nz, PsEditBox_Confirm_CopyText
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp (xsp + 12), 0x0
	jr nz, PsEditBox_Confirm_Render
	jrl PsEditBox_ReturnZero

PsEditBox_Confirm_CopyText:
	ld XWA, (xsp + 0x0218)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsEditBox_Confirm_Render:
	ld xiy, (xsp + 8)
	ld xbc, (xiy + 32)
	lda xwa, (xsp+524)
	lda xhl, (xsp+532)
	lda xde, (xsp + 12)
	push xbc
	pushw	(xiy+36)
	pushw	(xiy+22)
	ld c, (xiy + 38)
	extz bc
	pushw bc
	ld ix, 0:i3
	ld xbc, (xiy + 46)
	cpw (xbc), 0x0
	jr z, PsEditBox_Confirm_SetFocus
	cpw (xiy + 44), 0x0
	jr z, PsEditBox_Confirm_SetFocus
	ld ix, 1:i3

PsEditBox_Confirm_SetFocus:
	pushw ix
	ld xbc, xhl
	call DrawStringReverse
	jrl PsEditBox_ReturnZero

PsEditBox_GetText:
	ld XWA, (xsp + 0x0218)
	ld (xwa), 0x0
	jrl PsEditBox_ReturnZero

PsEditBox_OK:
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 42)
	extz xwa
	cp	xwa, (xsp+536)
	jr nz, PsEditBox_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, PsEditBox_OK_Forward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	jr PsEditBox_Dispatch

PsEditBox_OK_Forward:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	jrl PsEditBox_DefaultTail

PsEditBox_Release:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+536)
	jrl nz, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	cpw (xwa), 0x0
	jrl z, PsEditBox_ReturnZero
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3

PsEditBox_Dispatch:
	call SendEvent
	jrl PsEditBox_ReturnZero

PsEditBox_ScrollUp:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_CHECK_SELECTED
	ld XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld XDE, (xsp + 0x0218)
	jr PsEditBox_SetAutoInc

PsEditBox_ScrollDown:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_CHECK_SELECTED
	ld XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld XWA, (xsp + 0x021c)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld XDE, (xsp + 0x0218)

PsEditBox_SetAutoInc:
	calr SetAutoInc
	jrl PsEditBox_ReturnZero

PsEditBox_CanScroll:
	ld XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+536)
	jrl nz, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	cpw (xwa), 0x1
	jrl nz, PsEditBox_ReturnZero
	ld xhl, 1:i3
	jr PsEditBox_Return

PsEditBox_Default:
	ld XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0218)

PsEditBox_DefaultTail:
	calr VwBoxProc

PsEditBox_Return:
	pop xiz
	lda xsp, (xsp+540)
	ret

PsNumEditBoxProc:
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 34), xde
	ld (xsp + 38), xbc
	ld (xsp + 42), xwa
	ld xwa, (xsp + 38)
	cp xwa, EVT_PARA_DRAW
	jr z, PsNumEditBox_Confirm
	ld xwa, (xsp + 42)
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	calr PsEditBoxProc
	jr PsNumEditBox_Return

PsNumEditBox_Confirm:
	ld xwa, (xsp + 42)
	call GetViewInstance
	ld xiz, xhl
	pushw PsNumEditBox_Confirm_Str_Chr25@hi16
	pushw PsNumEditBox_Confirm_Str_Chr25@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	pushw	(xiz+50)
	pushw PsNumEditBox_Confirm_Str_Fmtd@hi16
	pushw PsNumEditBox_Confirm_Str_Fmtd@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xwa, (xsp + 32)
	push xwa
	lda xwa, (xsp + 46)
	push xwa
	call Strcat
	lda xsp, (xsp + 26)
	pushw PsNumEditBox_Confirm_Str_d@hi16
	pushw PsNumEditBox_Confirm_Str_d@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Strcat
	ld xwa, (xsp + 42)
	push xwa
	lda xwa, (xsp + 36)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 20)
	lda xde, (xsp + 4)
	ld xwa, (xsp + 42)
	ld xbc, (xsp + 38)
	calr PsEditBoxProc
	ld xhl, 0:i3

PsNumEditBox_Return:
	pop xiz
	lda xsp, (xsp + 42)
	ret

PsTblEditBoxProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+260), xde
	ld	(xsp+264), xbc
	ld xiz, xwa
	ld XWA, (xsp + 0x0108)
	cp xwa, EVT_PARA_DRAW
	jr z, PsTblEditBox_Confirm
	ld xwa, xiz
	ld XBC, (xsp + 0x0108)
	ld XDE, (xsp + 0x0104)
	calr PsEditBoxProc
	jr PsTblEditBox_Return

PsTblEditBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld (xde), xwa
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_TABLE_STRING
	call ApFuncCall
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld XBC, (xsp + 0x0108)
	calr PsEditBoxProc
	ld xhl, 0:i3

PsTblEditBox_Return:
	pop xiz
	lda xsp, (xsp+264)
	ret

PasTableCheck:
	cp xbc, EVT_GET_TABLE_STRING
	jr nz, PasTableCheck_Return
	ld xwa, (xde)
	sll xwa, 2
	ld xbc, PasTableCheck_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PasTableCheck_Return:
	ld xhl, 0:i3
	ret

AcOnOffBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcOnOff_ScrollDown
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcOnOff_ScrollUp
	cp xbc, EVT_GET_PARAM
	jr z, AcOnOff_GetValue
	cp xbc, EVT_SET_PARAM
	jr z, AcOnOff_SetValue
	cp xbc, EVT_GET_STRING
	jr z, AcOnOff_GetText
	cp xbc, EVT_DRAW
	jrl nz, AcOnOff_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcOnOff_Dispatch

AcOnOff_GetText:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld wa, (xwa)
	extz xwa
	sll xwa, 2
	ld xbc, AcOnOff_GetText_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AcOnOff_ReturnZero

AcOnOff_SetValue:
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 50)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp xbc, (xsp + 4)
	jr z, AcOnOff_ReturnZero
	ld xbc, (xwa)
	ld xwa, (xsp + 4)
	ld (xbc), wa
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr AcOnOff_Dispatch

AcOnOff_GetValue:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld hl, (xwa)
	exts xhl
	jr AcOnOff_Return

AcOnOff_ScrollUp:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	jr AcOnOff_Dispatch

AcOnOff_ScrollDown:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3

AcOnOff_Dispatch:
	call SendEvent

AcOnOff_ReturnZero:
	ld xhl, 0:i3
	jr AcOnOff_Return

AcOnOff_Default:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc

AcOnOff_Return:
	pop xiz
	inc 4, xsp
	ret

AcNumEditBoxProc:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 28), xde
	ld (xsp + 32), xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcNumEdit_ScrollDown
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcNumEdit_AutoIncDown
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcNumEdit_ScrollUp
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcNumEdit_AutoIncUp
	cp xbc, EVT_GET_PARAM
	jrl z, AcNumEdit_GetValue
	cp xbc, EVT_CALC_PARAM
	jrl z, AcNumEdit_AddDelta
	cp xbc, EVT_SET_PARAM
	jrl z, AcNumEdit_SetValue
	cp xbc, EVT_GET_STRING
	jr z, AcNumEdit_GetText
	cp xbc, EVT_DRAW
	jrl nz, AcNumEdit_Default
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcNumEdit_Dispatch

AcNumEdit_GetText:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	pushw AcNumEdit_GetText_Str_Chr25@hi16
	pushw AcNumEdit_GetText_Str_Chr25@lo16
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	ld xwa, (xsp + 12)
	pushw	(xwa+54)
	pushw AcNumEdit_GetText_Str_Fmtd@hi16
	pushw AcNumEdit_GetText_Str_Fmtd@lo16
	lda xwa, (xsp + 22)
	push xwa
	call Sprintf_Locked
	lda xwa, (xsp + 26)
	push xwa
	lda xwa, (xsp + 40)
	push xwa
	call Strcat
	lda xsp, (xsp + 26)
	pushw AcNumEdit_GetText_Str_d@hi16
	pushw AcNumEdit_GetText_Str_d@lo16
	lda xwa, (xsp + 22)
	push xwa
	call Strcat
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 50)
	pushw	(xwa)
	lda xwa, (xsp + 28)
	push xwa
	ld xwa, (xsp + 42)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 18)
	jrl AcNumEdit_ReturnZero

AcNumEdit_SetValue:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xbc, (xhl + 50)
	ld xwa, (xsp + 28)
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcNumEdit_Dispatch

AcNumEdit_AddDelta:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xde, (xsp + 28)
	ld xwa, xde
	lda xbc, (xhl + 50)
	cp xde, 0x0
	jr le, AcNumEdit_AddDelta_Negative
	ld xbc, (xbc)
	ld hl, (xhl + 56)
	sub hl, (xbc)
	ld de, wa
	cp hl, wa
	jrl lt, AcNumEdit_ReturnZero
	ld wa, (xbc)
	add de, wa
	ld (xbc), de
	ld xwa, (xsp + 32)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcNumEdit_Dispatch

AcNumEdit_AddDelta_Negative:
	ld xbc, (xbc)
	ld hl, (xhl + 58)
	sub hl, (xbc)
	ld de, wa
	cp hl, wa
	jrl gt, AcNumEdit_ReturnZero
	ld wa, (xbc)
	add de, wa
	ld (xbc), de
	ld xwa, (xsp + 32)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcNumEdit_Dispatch

AcNumEdit_GetValue:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld hl, (xwa)
	exts xhl
	jrl AcNumEdit_Return

AcNumEdit_AutoIncUp:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jrl z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_CALC_PARAM
	jrl AcNumEdit_Dispatch

AcNumEdit_ScrollUp:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_CALC_PARAM
	jr AcNumEdit_Dispatch

AcNumEdit_AutoIncDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_CALC_PARAM
	jr AcNumEdit_Dispatch

AcNumEdit_ScrollDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_CALC_PARAM

AcNumEdit_Dispatch:
	call SendEvent

AcNumEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcNumEdit_Return

AcNumEdit_Default:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc

AcNumEdit_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

AcLswEditBoxProc:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 22), xde
	ld (xsp + 26), xwa
	cp xbc, EVT_INDEXSW_BOTH
	jrl z, AcLswEdit_ResetBtn
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcLswEdit_ScrollDown
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcLswEdit_AutoIncDown
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcLswEdit_ScrollUp
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcLswEdit_AutoIncUp
	cp xbc, EVT_LSW_DATA
	jrl z, AcLswEdit_Match
	cp xbc, EVT_REPAINT
	jrl z, AcLswEdit_ShowHide
	cp xbc, EVT_PAINT
	jrl z, AcLswEdit_ShowHide
	cp xbc, EVT_HIDE
	jrl z, AcLswEdit_Close
	cp xbc, EVT_SHOW
	jrl z, AcLswEdit_Init
	cp xbc, EVT_CALC_PARAM
	jrl z, AcLswEdit_AddDelta
	cp xbc, EVT_SET_PARAM
	jr z, AcLswEdit_SetValue
	cp xbc, EVT_GET_STRING
	jrl nz, AcLswEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 10)
	ld (xde), xhl
	ld xbc, (xsp + 6)
	ld xwa, (xbc + 54)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 22)
	ld (xde + 8), xwa
	ld xwa, (xbc + 50)
	ld xbc, EVT_GET_LSW_STRING
	call ApFuncCall
	jrl AcLswEdit_ReturnZero

AcLswEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld bc, (xsp + 8)
	ld de, hl
	calr MainLswPut
	jrl AcLswEdit_ReturnZero

AcLswEdit_AddDelta:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld bc, (xsp + 8)
	ld de, hl
	calr MainLswAdd
	jrl AcLswEdit_ReturnZero

AcLswEdit_Init:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	jr AcLswEdit_ForwardEdit

AcLswEdit_Close:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)

AcLswEdit_ForwardEdit:
	calr PsEditBoxProc
	jrl AcLswEdit_ReturnZero

AcLswEdit_ShowHide:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	calr MainLswGet
	jrl AcLswEdit_ReturnZero

AcLswEdit_Match:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 22)
	cp (xwa), xhl
	jrl nz, AcLswEdit_ReturnZero
	ld xhl, (xsp + 6)
	lda xde, (xhl + 54)
	ld xbc, (xde)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_LSW_DATA_REQ
	call ApFuncCall
	ld xwa, (xsp + 26)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcLswEdit_Dispatch

AcLswEdit_AutoIncUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CALC_PARAM
	jrl AcLswEdit_Dispatch

AcLswEdit_ScrollUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CALC_PARAM
	jrl AcLswEdit_Dispatch

AcLswEdit_AutoIncDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jrl AcLswEdit_Dispatch

AcLswEdit_ScrollDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr AcLswEdit_Dispatch

AcLswEdit_ResetBtn:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_CHECK_INIT_DATA
	ld xde, 0:i3
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_INIT_DATA
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_SET_PARAM

AcLswEdit_Dispatch:
	call SendEvent

AcLswEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcLswEdit_Return

AcLswEdit_Default:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc

AcLswEdit_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

LswEditCheck:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_LSW_DATA_REQ
	jr z, LswEditCheck_NotHandled
	cp xbc, EVT_GET_SMALL_STEP
	jr z, LswEditCheck_StepOne
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswEditCheck_StepFour
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswEditCheck_StepOne
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, LswEditCheck_GetAddr
	cp xbc, EVT_GET_LSW_STRING
	jr nz, LswEditCheck_NotHandled
	pushw	(xde+4)
	pushw LswEditCheck_Str_Fmt3d@hi16
	pushw LswEditCheck_Str_Fmt3d@lo16
	ld xwa, (xde + 8)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jr LswEditCheck_Return

LswEditCheck_GetAddr:
	ld xhl, 0x1f47
	jr LswEditCheck_Return

LswEditCheck_StepOne:
	ld xhl, 1:i3
	jr LswEditCheck_Return

LswEditCheck_StepFour:
	ld xhl, 4:i3
	jr LswEditCheck_Return

LswEditCheck_NotHandled:
	ld xhl, 0:i3

LswEditCheck_Return:
	pop xiz
	ret

MainLswPut:
	dec 8, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld wa, (xsp + 6)
	ld (xiz + 4), wa
	ld wa, (xsp + 4)
	ld (xiz + 6), wa
	ld xwa, 0:i3
	ld (xiz + 8), xwa
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_PUT
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	ld hl, 0:i3
	pop xiz
	inc 8, xsp
	ret

MainLswPartPut:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), de
	ld (xsp + 8), bc
	ld iz, wa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 8)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 16
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ld bc, (xsp + 6)
	ld (xwa + 4), bc
	ld bc, (xsp + 14)
	ld (xwa + 6), bc
	ld xbc, 0:i3
	ld (xwa + 8), xbc
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_PART_PUT
	ld xde, (xsp + 2)
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 2)
	call MainFuncCall
	ld hl, 0:i3
	popw iz
	inc 8, xsp
	retd 0x2

MainLswAdd:
	dec 8, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld wa, (xsp + 6)
	ld (xiz + 4), wa
	ld wa, (xsp + 4)
	ld (xiz + 6), wa
	ld xwa, 0:i3
	ld (xiz + 8), xwa
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_ADD
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	ld hl, 0:i3
	pop xiz
	inc 8, xsp
	ret

MainLswPartAdd:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), de
	ld (xsp + 8), bc
	ld iz, wa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 8)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 16
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ld bc, (xsp + 6)
	ld (xwa + 4), bc
	ld bc, (xsp + 14)
	ld (xwa + 6), bc
	ld xbc, 0:i3
	ld (xwa + 8), xbc
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_PART_ADD
	ld xde, (xsp + 2)
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 2)
	call MainFuncCall
	ld hl, 0:i3
	popw iz
	inc 8, xsp
	retd 0x2

MainLswGet:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld (xiz), xwa
	ldw (xiz + 4), 0x0
	ldw (xiz + 6), 0x0
	ld xwa, 0:i3
	ld (xiz + 8), xwa
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_GET
	ld xde, xiz
	call FuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call FuncCall
	ld hl, 0:i3
	pop xiz
	inc 4, xsp
	ret

MainLswPartGet:
	dec 6, xsp
	pushw iz
	ld (xsp + 6), bc
	ld iz, wa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 6)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 16
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ldw (xwa + 4), 0x0
	ldw (xwa + 6), 0x0
	ld xbc, 0:i3
	ld (xwa + 8), xbc
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_LSW_PART_GET
	ld xde, (xsp + 2)
	call FuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 2)
	call FuncCall
	ld hl, 0:i3
	popw iz
	inc 6, xsp
	ret

SetLswFilter:
	add xwa, xbc
	ld (0x0276c6:24), xwa
	ret

ResetLswFilter:
	add xwa, xbc
	ld (0x0276c6:24), xwa
	ret

AcRamEditBoxProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld (xsp + 34), xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcRamEdit_ScrollDown
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcRamEdit_AutoIncDown
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcRamEdit_ScrollUp
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcRamEdit_AutoIncUp
	cp xbc, EVT_RAM_DATA
	jrl z, AcRamEdit_Assign
	cp xbc, EVT_REPAINT
	jrl z, AcRamEdit_ShowHide
	cp xbc, EVT_PAINT
	jrl z, AcRamEdit_ShowHide
	cp xbc, EVT_CALC_PARAM
	jrl z, AcRamEdit_AddDelta
	cp xbc, EVT_SET_PARAM
	jr z, AcRamEdit_SetValue
	cp xbc, EVT_GET_STRING
	jrl nz, AcRamEdit_Default
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 54)
	ld xwa, (xwa)
	ld (xde + 14), xwa
	ld xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_RAM_STRING
	call ApFuncCall
	jrl AcRamEdit_ReturnZero

AcRamEdit_SetValue:
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_RAM_SIZE
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_MAX
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_MIN
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 10), xhl
	calr MainRamPut
	jrl AcRamEdit_ReturnZero

AcRamEdit_AddDelta:
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_RAM_SIZE
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_MAX
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_MIN
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 10), xhl
	calr MainRamAdd
	jrl AcRamEdit_ReturnZero

AcRamEdit_ShowHide:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_RAM_SIZE
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld bc, hl
	calr MainRamGet
	jrl AcRamEdit_ReturnZero

AcRamEdit_Assign:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld xix, (xsp + 30)
	ld xwa, (xix)
	cp xwa, xhl
	jrl nz, AcRamEdit_ReturnZero
	lda xde, (xiz + 54)
	ld xbc, (xde)
	ld xwa, (xix + 14)
	ld (xbc), xwa
	ld xwa, (xde)
	ld xde, (xwa)
	ld xwa, (xiz + 50)
	ld xbc, EVT_RAM_DATA_REQ
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcRamEdit_Dispatch

AcRamEdit_AutoIncUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	jrl AcRamEdit_Dispatch

AcRamEdit_ScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	jrl AcRamEdit_Dispatch

AcRamEdit_AutoIncDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr AcRamEdit_Dispatch

AcRamEdit_ScrollDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl

AcRamEdit_Dispatch:
	call SendEvent

AcRamEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcRamEdit_Return

AcRamEdit_Default:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc

AcRamEdit_Return:
	pop xiz
	lda xsp, (xsp + 34)
	ret

RamEditCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_RAM_DATA_REQ
	jr z, RamEditCheck_NotHandled
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, RamEditCheck_NotHandled
	cp xwa, 0x9
	jr gt, RamEditCheck_NotHandled
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x3E8
	ld wa, (xwa)
	lda xix, (RamEditCheck_JumpStart:24)
; Computed jump: target = RamEditCheck_JumpStart + Data_SoundEditorCharsLayout_0x3E8[i], Data_SoundEditorCharsLayout_0x3E8 = 16-bit offsets (10 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e0003e:
;   0x1e0003e -> RamEditCheck_Evt1E0003E
;   0x1e0003f -> RamEditCheck_Evt1E0003F
;   0x1e00040 -> RamEditCheck_NotHandled
;   0x1e00041 -> RamEditCheck_NotHandled
;   0x1e00042 -> RamEditCheck_NotHandled
;   0x1e00043 -> RamEditCheck_Evt1E00043
;   0x1e00044 -> RamEditCheck_Evt1E00044
;   0x1e00045 -> RamEditCheck_Evt1E00045
;   0x1e00046 -> RamEditCheck_Evt1E0003E
;   0x1e00047 -> RamEditCheck_JumpStart
	jp	t, (xix+wa)

RamEditCheck_JumpStart:
	ld	xwa, (xde+14)
	push	xwa
	pushw	RamEditCheck_JumpStart_Str_Fmt3d@hi16
	pushw	RamEditCheck_JumpStart_Str_Fmt3d@lo16
	ld	xwa, (xde+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr	ResetLswFilter_Epilogue
RamEditCheck_Evt1E0003E:
	ld	xhl, 4:i3
	jr	ResetLswFilter_Epilogue
RamEditCheck_Evt1E0003F:
	ld	xhl, 1:i3
	jr	ResetLswFilter_Epilogue
RamEditCheck_Evt1E00043:
	ld	xhl, 16
	jr	ResetLswFilter_Epilogue
RamEditCheck_Evt1E00044:
	ld	xhl, 0xffffffe3
	jr	ResetLswFilter_Epilogue
RamEditCheck_Evt1E00045:
	lda	xhl, (0x0276ca:24)
	jr	ResetLswFilter_Epilogue

RamEditCheck_NotHandled:
	ld xhl, 0:i3
ResetLswFilter_Epilogue:
	pop xiz
	ret

MainRamPut:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xiy, xiz
	ld xix, xwa
	ldw bc, 0xb
	ldirw
	ld xwa, NAKA_MAINFUNC_MainRamControl
	ld xbc, EVT_RAM_PUT
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 4)
	call MainFuncCall
	pop xiz
	inc 4, xsp
	ret

MainRamAdd:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xiy, xiz
	ld xix, xwa
	ldw bc, 0xb
	ldirw
	ld xwa, NAKA_MAINFUNC_MainRamControl
	ld xbc, EVT_RAM_ADD
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 4)
	call MainFuncCall
	pop xiz
	inc 4, xsp
	ret

MainRamGet:
	dec 6, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), xwa
	pushw 0x16
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 6)
	ld (xiz), xwa
	ld wa, (xsp + 4)
	ld (xiz + 4), wa
	ld xwa, 0:i3
	ld (xiz + 6), xwa
	ld (xiz + 10), xwa
	ld (xiz + 14), xwa
	ld (xiz + 18), xwa
	ld xwa, NAKA_MAINFUNC_MainRamControl
	ld xbc, EVT_RAM_GET
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	pop xiz
	inc 6, xsp
	ret

AcBitEditBoxProc:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 22), xde
	ld (xsp + 26), xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcBitEdit_ScrollDown
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcBitEdit_ScrollUp
	cp xbc, EVT_BIT_DATA
	jrl z, AcBitEdit_Assign
	cp xbc, EVT_REPAINT
	jrl z, AcBitEdit_ShowHide
	cp xbc, EVT_PAINT
	jrl z, AcBitEdit_ShowHide
	cp xbc, EVT_CALC_PARAM
	jr z, AcBitEdit_SetValue
	cp xbc, EVT_SET_PARAM
	jr z, AcBitEdit_SetValue
	cp xbc, EVT_GET_STRING
	jrl nz, AcBitEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 54)
	ld wa, (xwa)
	ld (xde + 8), wa
	ld xwa, (xsp + 22)
	ld (xde + 10), xwa
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT_STRING
	call ApFuncCall
	jrl AcBitEdit_ReturnZero

AcBitEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), xhl
	ld xbc, (xsp + 22)
	ld (xwa + 8), bc
	calr MainBitPut
	jrl AcBitEdit_ReturnZero

AcBitEdit_ShowHide:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_BIT
	ld xde, 0:i3
	call ApFuncCall
	ld xbc, xhl
	ld xwa, (xsp + 4)
	calr MainBitGet
	jrl AcBitEdit_ReturnZero

AcBitEdit_Assign:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_BIT_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 22)
	ld xwa, (xwa)
	cp xwa, xhl
	jrl nz, AcBitEdit_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_BIT
	ld xde, 0:i3
	call ApFuncCall
	ld xde, (xsp + 22)
	cp (xde + 4), xhl
	jrl nz, AcBitEdit_ReturnZero
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 54)
	ld wa, (xde + 8)
	ld (xbc), wa
	ld xwa, (xsp + 26)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcBitEdit_Dispatch

AcBitEdit_ScrollUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_DIRECTION
	ld xde, 0:i3
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollUp_SetOne
	ld xwa, (xsp + 26)
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollUp_SetOne:
	ld xwa, (xsp + 26)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 26)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_DIRECTION
	ld xde, 0:i3
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollDown_SetZero
	ld xwa, (xsp + 26)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollDown_SetZero:
	ld xwa, (xsp + 26)
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3

AcBitEdit_Dispatch:
	call SendEvent

AcBitEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcBitEdit_Return

AcBitEdit_Default:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc

AcBitEdit_Return:
	pop xiz
	lda xsp, (xsp + 26)
	ret

BitEditCheck:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_DIRECTION
	jr z, BitEditCheck_NotHandled
	cp xbc, EVT_GET_BIT
	jr z, BitEditCheck_GetMask
	cp xbc, EVT_GET_BIT_ADDRESS
	jr z, BitEditCheck_GetAddr
	cp xbc, EVT_GET_BIT_STRING
	jr nz, BitEditCheck_NotHandled
	ld wa, (xde + 8)
	and wa, 0x1
	sla wa, 2
	lda xbc, (BitEditCheck_PtrTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr BitEditCheck_Return

BitEditCheck_GetAddr:
	lda xhl, (0x0276ce:24)
	jr BitEditCheck_Return

BitEditCheck_GetMask:
	ld xhl, 0x8000
	jr BitEditCheck_Return

BitEditCheck_NotHandled:
	ld xhl, 0:i3

BitEditCheck_Return:
	pop xiz
	ret

MainBitPut:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	pushw 0xe
	call Malloc
	ld (xsp + 6), xhl
	pushw 0xe
	push xiz
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld xwa, NAKA_MAINFUNC_MainBitControl
	ld xbc, EVT_BIT_PUT
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 4)
	call MainFuncCall
	pop xiz
	inc 4, xsp
	ret

MainBitGet:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	pushw 0xe
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld xwa, (xsp + 4)
	ld (xiz + 4), xwa
	ldw (xiz + 8), 0x0
	ld xwa, 0:i3
	ld (xiz + 10), xwa
	ld xwa, NAKA_MAINFUNC_MainBitControl
	ld xbc, EVT_BIT_GET
	ld xde, xiz
	call MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainAutoFree
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call MainFuncCall
	pop xiz
	inc 8, xsp
	ret

PsMenuBoxProc:
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+276), xde
	ld xiz, xwa
	cp xbc, EVT_CHECK_EDIT_SW
	jrl z, PsMenuBox_HitTest
	cp xbc, EVT_PARA_DRAW
	jr z, PsMenuBox_Confirm
	cp xbc, EVT_DRAW
	jr z, PsMenuBox_Paint
	cp xbc, EVT_GET_STRING
	jr z, PsMenuBox_GetText
	ld xwa, xiz
	ld XDE, (xsp + 0x0114)
	calr VwBoxProc
	jrl PsMenuBox_Return

PsMenuBox_GetText:
	ld XWA, (xsp + 0x0114)
	ld (xwa), 0x0

PsMenuBox_ReturnZero:
	ld xhl, 0:i3
	jrl PsMenuBox_Return

PsMenuBox_Paint:
	ld xwa, xiz
	ld XDE, (xsp + 0x0114)
	calr VwBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld wa, (xhl + 36)
	calr DrawEditSw
	jr PsMenuBox_ReturnZero

PsMenuBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp+268)
	ld xwa, xiz
	calr GetClientBox
	lda xwa, (xsp+268)
	lda xbc, (xsp+264)
	calr GetBoxCenter
	lda xde, (xsp + 8)
	ld XWA, (xsp + 0x0114)
	or xwa, xwa
	jr nz, PsMenuBox_Confirm_CopyText
	ld xwa, xiz
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp (xsp + 8), 0x0
	jr nz, PsMenuBox_Confirm_Render
	jr PsMenuBox_ReturnZero

PsMenuBox_Confirm_CopyText:
	ld XWA, (xsp + 0x0114)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsMenuBox_Confirm_Render:
	lda xhl, (xsp+268)
	lda xbc, (xsp+264)
	lda xde, (xsp + 8)
	ld xix, (xsp + 4)
	ld xwa, (xix + 28)
	push xwa
	pushw	(xix+32)
	ld xwa, xix
	pushw	(xwa+22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringAlignment
	jrl PsMenuBox_ReturnZero

PsMenuBox_HitTest:
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jrl z, PsMenuBox_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld XDE, (xsp + 0x0114)
	call SendEvent
	ld wa, (xiz + 36)
	extz xwa
	cp xwa, xhl
	jrl nz, PsMenuBox_ReturnZero
	ld xhl, 1:i3

PsMenuBox_Return:
	pop xiz
	lda xsp, (xsp+276)
	ret

AcTitleMenuProc:
	lda xsp, (xsp-308)
	push xiz
	ld	(xsp+304), xde
	ld	(xsp+308), xbc
	ld xiz, xwa
	ld XWA, (xsp + 0x0134)
	cp xwa, EVT_SW_IN
	jrl z, AcTitleMenu_OK
	cp xwa, EVT_PARA_DRAW
	jr z, AcTitleMenu_Confirm
	cp xwa, EVT_DRAW
	jr z, AcTitleMenu_Paint
	ld xwa, xiz
	ld XBC, (xsp + 0x0134)
	ld XDE, (xsp + 0x0130)
	jrl AcTitleMenu_DefaultTail

AcTitleMenu_Paint:
	ld xwa, xiz
	ld XBC, (xsp + 0x0134)
	ld XDE, (xsp + 0x0130)
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcTitleMenu_OK_Dispatch

AcTitleMenu_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	lda xbc, (xsp+284)
	ld xwa, xiz
	calr GetClientBox
	lda xiy, (xsp+284)
	lda xix, (xsp+276)
	ld bc, 4:i3
	ldirw
	lda xbc, (xsp+296)
	ld xwa, (xsp + 8)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 8)
	lda xde, (xwa + 50)	; ICON ID
	lda xbc, (xsp+300)
	ld xwa, (xde)	; <--- here we get the ID of the selected menu item's icon
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIcon

	cpw	(xsp+296), 0x0000
	jr nz, AcTitleMenu_Confirm_NoIcon

	ldw wa, 0x20
	jr AcTitleMenu_Confirm_SetLeft

AcTitleMenu_Confirm_NoIcon:
	ld wa, 4:i3

AcTitleMenu_Confirm_SetLeft:
	ld	hl, (xsp+284)
	add hl, wa
	ld (xbc), hl
	ld	(xsp+276), hl
	lda xbc, (xsp+280)
	ld xwa, (xde)	; also ICON ID here
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIconRight

	cpw	(xsp+296), 0x0000
	jr z, AcTitleMenu_Confirm_NoIconRight

	ldw wa, 0x1c
	jr AcTitleMenu_Confirm_SetRight

AcTitleMenu_Confirm_NoIconRight:
	ld wa, 4:i3

AcTitleMenu_Confirm_SetRight:
	ld	de, (xsp+288)
	sub de, wa
	ld (xbc), de
	lda xbc, (xsp + 12)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 42)
	call ConvertStrings
	lda xwa, (xsp + 12)
	lda xbc, (xsp+276)
	ld de, (xbc + 4)
	sub de, (xbc)
	ld xbc, (xsp + 8)
	ld xbc, (xbc + 28)
	call WordwrapStrings
	ld (xsp + 6), hl
	lda xwa, (xsp + 12)
	push xwa
	call Strlen
	inc 4, xsp
	ld de, (xsp + 6)
	lda xbc, (xsp+296)
	ld xix, (xsp + 8)
	lda xwa, (xix + 50)
	cp de, hl
	jr nz, AcTitleMenu_Confirm_MultiLine
	ld xwa, (xwa)	; <-- ICON ID
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_SingleLine

	cpw (xbc), 0x0
	jr z, AcTitleMenu_Confirm_SingleLine

	lda xwa, (xsp + 12)
	ld xbc, (xix + 28)
	call CalcTotalWidth
	ld	wa, (xsp+280)
	sub wa, hl
	dec 5, wa
	ld	(xsp+300), wa

AcTitleMenu_Confirm_SingleLine:
	lda xwa, (xsp+284)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld wa, bc
	inc 2, wa
	lda xbc, (xsp+300)
	ld (xbc + 2), wa
	lda xwa, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	pushw 0xf7
	jrl AcTitleMenu_Confirm_RenderTop

AcTitleMenu_Confirm_MultiLine:
	ld hl, (xsp + 6)
	dec 1, hl
	lda xde, (xsp + 12)
	ld	(xde+hl), 0x00
	ld xwa, (xwa)
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_RenderBottom
	cpw (xbc), 0x0
	jr z, AcTitleMenu_Confirm_RenderBottom
	ld wa, (xsp + 6)
	exts xwa
	add xwa, xde
	push xwa
	call Strlen
	ld iz, hl
	lda xwa, (xsp + 16)
	push xwa
	call Strlen
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 28)
	lda xwa, (xsp + 12)
	cp hl, iz
	jr ugt, AcTitleMenu_Confirm_MultiAdjust
	ld de, (xsp + 6)
	lda	xwa, (xwa+de)

AcTitleMenu_Confirm_MultiAdjust:
	call CalcTotalWidth
	ld	wa, (xsp+280)
	sub wa, hl
	dec 5, wa
	ld	(xsp+300), wa

AcTitleMenu_Confirm_RenderBottom:
	lda xwa, (xsp+284)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x4
	add bc, wa
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld wa, bc
	inc 2, wa
	lda xbc, (xsp+300)
	ld (xbc + 2), wa
	lda xwa, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	pushw 0xf7
	call DrawString
	lda xwa, (xsp+284)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x4
	muls wa, 0x3
	add bc, wa
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld wa, bc
	inc 2, wa
	lda xbc, (xsp+300)
	ld (xbc + 2), wa
	lda xwa, (xsp+276)
	lda xhl, (xsp + 12)
	ld de, (xsp + 6)
	exts xde
	add xde, xhl
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	pushw 0xf7

AcTitleMenu_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)	; ICON ID
	or xwa, xwa
	jrl z, AcTitleMenu_OK_Done

	lda xbc, (xsp+292)
	lda xwa, (xsp+284)
	cpw	(xsp+296), 0x0000
	jr z, AcTitleMenu_Confirm_IconNoOrient
	ld wa, (xwa + 4)
	sub wa, 0x1a
	ld (xbc), wa
	jr AcTitleMenu_Confirm_DrawIcon

AcTitleMenu_Confirm_IconNoOrient:
	ld wa, (xwa)
	inc 2, wa
	ld (xbc), wa

AcTitleMenu_Confirm_DrawIcon:
	lda xwa, (xsp+284)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xb
	lda xhl, (xsp+292)
	lda xde, (xhl + 2)
	ld (xde), bc
	lda xwa, (xsp+268)
	ld bc, (xhl)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xde)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x19
	ld (xwa + 6), bc
	ldw bc, 0xc4
	ldw de, 0xf0
	call DrawDesignBox
	lda xwa, (xsp+292)
	ld xbc, (xsp + 8)
	ld xbc, (xbc + 50)	; <-- ICON ID
	call DrawIcons
	jrl AcTitleMenu_OK_Done

AcTitleMenu_OK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld XDE, (xsp + 0x0130)
	call SendEvent
	cp hl, 0:i3
	jrl z, AcTitleMenu_OK_Default
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	cp xwa, 0xffffffff
	jrl z, AcTitleMenu_OK_Default
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_AcTitleMenu
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckMode
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckMode:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_AcModeMenu
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckScreen
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckScreen:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_AcScreenMenu
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckWindow
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckWindow:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_AcWindowMenu
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_Done
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, EVT_SHOW
	ld xde, 0:i3

AcTitleMenu_OK_Dispatch:
	call SendEvent

AcTitleMenu_OK_Done:
	ld xhl, 0:i3
	jr AcTitleMenu_Return

AcTitleMenu_OK_Default:
	ld xwa, xiz
	ld XBC, (xsp + 0x0134)
	ld XDE, (xsp + 0x0130)

AcTitleMenu_DefaultTail:
	calr PsMenuBoxProc

AcTitleMenu_Return:
	pop xiz
	lda xsp, (xsp+308)
	ret

VwMenuBoxProc:
	lda xsp, (xsp-298)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_PARA_DRAW
	jr z, VwMenuBox_Confirm
	cp xbc, EVT_DRAW
	jr z, VwMenuBox_Paint
	ld xwa, xiz
	calr PsMenuBoxProc
	jrl VwMenuBox_Return

VwMenuBox_Paint:
	ld xwa, xiz
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jrl VwMenuBox_ReturnZero

VwMenuBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 6), xhl
	lda xbc, (xsp+282)
	ld xwa, xiz
	calr GetClientBox
	lda xiy, (xsp+282)
	lda xix, (xsp+274)
	ld bc, 4:i3
	ldirw
	lda xbc, (xsp+294)
	ld xwa, (xsp + 6)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	lda xde, (xwa + 46)
	lda xbc, (xsp+298)
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIcon
	cpw	(xsp+294), 0x0000
	jr nz, VwMenuBox_Confirm_NoIcon
	ldw wa, 0x20
	jr VwMenuBox_Confirm_SetLeft

VwMenuBox_Confirm_NoIcon:
	ld wa, 4:i3

VwMenuBox_Confirm_SetLeft:
	ld	hl, (xsp+282)
	add hl, wa
	ld (xbc), hl
	ld	(xsp+274), hl
	lda xbc, (xsp+278)
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIconRight
	cpw	(xsp+294), 0x0000
	jr z, VwMenuBox_Confirm_NoIconRight
	ldw wa, 0x1c
	jr VwMenuBox_Confirm_SetRight

VwMenuBox_Confirm_NoIconRight:
	ld wa, 4:i3

VwMenuBox_Confirm_SetRight:
	ld	de, (xsp+286)
	sub de, wa
	ld (xbc), de
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 42)
	call ConvertStrings
	lda xwa, (xsp + 10)
	lda xbc, (xsp+274)
	ld de, (xbc + 4)
	sub de, (xbc)
	ld xbc, (xsp + 6)
	ld xbc, (xbc + 28)
	call WordwrapStrings
	ld iz, hl
	lda xwa, (xsp + 10)
	push xwa
	call Strlen
	inc 4, xsp
	ld de, iz
	lda xbc, (xsp+294)
	ld xix, (xsp + 6)
	lda xwa, (xix + 46)
	cp de, hl
	jr nz, VwMenuBox_Confirm_MultiLine
	ld xwa, (xwa)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_SingleLine
	cpw (xbc), 0x0
	jr z, VwMenuBox_Confirm_SingleLine
	lda xwa, (xsp + 10)
	ld xbc, (xix + 28)
	call CalcTotalWidth
	ld	wa, (xsp+278)
	sub wa, hl
	dec 5, wa
	ld	(xsp+298), wa

VwMenuBox_Confirm_SingleLine:
	lda xwa, (xsp+282)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld wa, bc
	inc 2, wa
	lda xbc, (xsp+298)
	ld (xbc + 2), wa
	lda xwa, (xsp+274)
	lda xde, (xsp + 10)
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	pushw 0xf7
	jrl VwMenuBox_Confirm_RenderTop

VwMenuBox_Confirm_MultiLine:
	ld hl, iz
	dec 1, hl
	lda xde, (xsp + 10)
	ld	(xde+hl), 0x00
	ld xwa, (xwa)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_RenderBottom
	cpw (xbc), 0x0
	jr z, VwMenuBox_Confirm_RenderBottom
	lda	xwa, (xde+iz)
	push xwa
	call Strlen
	ldfr_werp HL, 0xfa
	lda xwa, (xsp + 14)
	push xwa
	call Strlen
	inc 8, xsp
	ld xwa, (xsp + 6)
	ld xbc, (xwa + 28)
	lda xwa, (xsp + 10)
	cpw_erp HL, 0xfa
	jr ugt, VwMenuBox_Confirm_MultiAdjust
	lda	xwa, (xwa+iz)

VwMenuBox_Confirm_MultiAdjust:
	call CalcTotalWidth
	ld	wa, (xsp+278)
	sub wa, hl
	dec 5, wa
	ld	(xsp+298), wa

VwMenuBox_Confirm_RenderBottom:
	lda xwa, (xsp+282)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x4
	muls wa, 0x3
	add bc, wa
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	ld wa, bc
	inc 2, wa
	lda xbc, (xsp+298)
	ld (xbc + 2), wa
	lda xwa, (xsp+274)
	lda xde, (xsp + 10)
	lda	xde, (xde+iz)
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	pushw 0xf7

VwMenuBox_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 46)
	or xwa, xwa
	jrl z, VwMenuBox_ReturnZero
	lda xbc, (xsp+290)
	lda xwa, (xsp+282)
	cpw	(xsp+294), 0x0000
	jr z, VwMenuBox_Confirm_IconNoOrient
	ld wa, (xwa + 4)
	sub wa, 0x1a
	ld (xbc), wa
	jr VwMenuBox_Confirm_DrawIcon

VwMenuBox_Confirm_IconNoOrient:
	ld wa, (xwa)
	inc 2, wa
	ld (xbc), wa

VwMenuBox_Confirm_DrawIcon:
	lda xwa, (xsp+282)
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xb
	lda xhl, (xsp+290)
	lda xde, (xhl + 2)
	ld (xde), bc
	lda xwa, (xsp+266)
	ld bc, (xhl)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xde)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x19
	ld (xwa + 6), bc
	ldw bc, 0xc4
	ldw de, 0xf0
	call DrawDesignBox
	lda xwa, (xsp+290)
	ld xbc, (xsp + 6)
	ld xbc, (xbc + 46)
	call DrawIcons

VwMenuBox_ReturnZero:
	ld xhl, 0:i3

VwMenuBox_Return:
	pop xiz
	lda xsp, (xsp+298)
	ret

PsEditSwBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xwa
	cp xbc, EVT_SET_VISIBLE
	jrl z, PsEditSwBox_Repaint
	cp xbc, EVT_CHECK_EDIT_SW
	jr z, PsEditSwBox_HitTest
	cp xbc, EVT_PARA_DRAW
	jr z, PsEditSwBox_Confirm
	cp xbc, EVT_DRAW
	jr z, PsEditSwBox_Paint
	cp xbc, EVT_GET_STRING
	jr z, PsEditSwBox_GetText
	ld xwa, xiz
	ld xde, (xsp + 20)
	calr VwBoxProc
	jrl PsEditSwBox_Return

PsEditSwBox_GetText:
	ld xwa, (xsp + 20)
	ld (xwa), 0x0
	jrl PsEditSwBox_ReturnZero

PsEditSwBox_Paint:
	ld xwa, xiz
	ld xde, (xsp + 20)
	calr VwBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xsp + 16)
	ld wa, (xiz + 36)
	calr GetEditSwPoint
	cpw (xsp + 18), 0xef
	jrl z, PsEditSwBox_ReturnZero
	ld wa, (xiz + 36)
	calr DrawEditSw
	jrl PsEditSwBox_ReturnZero

PsEditSwBox_Confirm:
	ld xwa, (xsp + 20)
	ld c, a
	extz bc
	ld xwa, xiz
	calr ButtonState_PaintProc
	jrl PsEditSwBox_ReturnZero

PsEditSwBox_HitTest:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jrl z, PsEditSwBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 20)
	call SendEvent
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	extz xwa
	cp xwa, xhl
	jr nz, PsEditSwBox_ReturnZero
	ld xhl, 1:i3
	jr PsEditSwBox_Return

PsEditSwBox_Repaint:
	ld xwa, xiz
	ld xde, (xsp + 20)
	calr VwBoxProc
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jr z, PsEditSwBox_Repaint_UpdateBounds
	ld xwa, xiz
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call SendEvent
	jr PsEditSwBox_ReturnZero

PsEditSwBox_Repaint_UpdateBounds:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 8)
	ld xwa, xiz
	call GetBox
	lda xbc, (xsp + 16)
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	lda xwa, (xsp + 16)
	cpw (xwa + 2), 0xef
	jr z, PsEditSwBox_Repaint_Render
	lda xbc, (xsp + 8)
	cpw (xwa), 0x13f
	jr z, PsEditSwBox_Repaint_ClampRight
	ldw (xbc), 0x0
	jr PsEditSwBox_Repaint_Render

PsEditSwBox_Repaint_ClampRight:
	ldw (xbc + 4), 0x13f

PsEditSwBox_Repaint_Render:
	lda xwa, (xsp + 8)
	ldw bc, 0xf5
	call DrawBox

PsEditSwBox_ReturnZero:
	ld xhl, 0:i3

PsEditSwBox_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

; -----------------------------------------------------------------------------
; PsEditSwBox_CalcEdgeSwitchRect -- code (was named PsEditSwBox_InlineData)
; WA = edit-switch index, XBC = rect {x0,y0,x1,y1} to fill, DE = value given
; to BoxLeftCheck / BoxRightCheck (ui/ui_control_panel.s: 1 for 0x80-0x88 /
; 0xa0-0xa8).  point = GetEditSwPoint(WA).  A switch on the left edge
; (point.x == 0) gets x0 = 0 if BoxLeftCheck(DE) else 8, x1 = 38; one on the
; right edge (point.x == 319) gets x0 = 281, x1 = 319 if BoxRightCheck(DE)
; else 311; both span y = point.y-9 .. point.y+8.  One on the bottom edge
; (point.y == 239) gets x = point.x-16 .. point.x+15, y = 216 .. 238.
; No caller was found (see scripts/renaming/uiproc_misc_names.py).
; -----------------------------------------------------------------------------
PsEditSwBox_CalcEdgeSwitchRect:
	dec	6, xsp
	push	xiz
	ld	(xsp+8), de
	ld	xiz, xbc
	lda	xbc, (xsp+4)
	calr	GetEditSwPoint
	lda	xwa, (xsp+4)
	cpw	(xwa), 0
	jr	nz, PsEditSwBox_CalcEdgeSwitchRect_Skip2
	lda	xbc, (xwa+2)
	ld	wa, (xbc)
	sub	wa, 9
	ld	(xiz+2), wa
	ld	wa, (xbc)
	inc	8, wa
	ld	(xiz+6), wa
	ld	wa, (xsp+8)
	calr	BoxLeftCheck
	ldw	wa, 8
	cp	hl, 0:i3
	jr	z, PsEditSwBox_CalcEdgeSwitchRect_Skip
	ld	wa, 0:i3
PsEditSwBox_CalcEdgeSwitchRect_Skip:
	ld	(xiz), wa
	ldw	(xiz+4), 38
PsEditSwBox_CalcEdgeSwitchRect_Skip2:
	lda	xwa, (xsp+4)
	cpw	(xwa), 319
	jr	nz, PsEditSwBox_CalcEdgeSwitchRect_Join
	lda	xbc, (xwa+2)
	ld	wa, (xbc)
	sub	wa, 9
	ld	(xiz+2), wa
	ld	wa, (xbc)
	inc	8, wa
	ld	(xiz+6), wa
	ldw	(xiz), 281
	ld	wa, (xsp+8)
	calr	BoxRightCheck
	lda	xwa, (xiz+4)
	cp	hl, 0:i3
	jr	z, PsEditSwBox_CalcEdgeSwitchRect_Skip3
	ldw	(xwa), 319
	jr	PsEditSwBox_CalcEdgeSwitchRect_Join
PsEditSwBox_CalcEdgeSwitchRect_Skip3:
	ldw	(xwa), 311
PsEditSwBox_CalcEdgeSwitchRect_Join:
	lda	xbc, (xsp+4)
	cpw	(xbc+2), 239
	jr	nz, PsEditSwBox_CalcEdgeSwitchRect_Epilogue
	ldw	(xiz+2), 216
	ldw	(xiz+6), 238
	ld	wa, (xbc)
	sub	wa, 16
	ld	(xiz), wa
	ld	wa, (xbc)
	add	wa, 15
	ld	(xiz+4), wa
PsEditSwBox_CalcEdgeSwitchRect_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	pushw	iz
	ld	(xsp+10), xde
	ld	iz, bc
	cp	wa, iz
	jr	c, PsEditSwBoxProc_Skip4
	ex16	iz, wa
PsEditSwBoxProc_Skip4:
	lda	xbc, (xsp+6)
	calr	GetEditSwPoint
	lda	xbc, (xsp+2)
	ld	wa, iz
	calr	GetEditSwPoint
	lda	xbc, (xsp+6)
	cpw	(xbc+2), 239
	jr	nz, PsEditSwBoxProc_Epilogue2
	ld	xwa, (xsp+10)
	ldw	(xwa+2), 216
	ldw	(xwa+6), 238
	ld	bc, (xbc)
	sub	bc, 16
	ld	(xwa), bc
	ld	bc, (xsp+2)
	add	bc, 15
	ld	(xwa+4), bc
PsEditSwBoxProc_Epilogue2:
	popw	iz
	lda	xsp, (xsp+12)
	ret

ButtonState_PaintProc:
	lda xsp, (xsp-298)
	push xiz
	ld	(xsp+296), c
	ld	(xsp+298), xwa
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp+288)
	ld XWA, (xsp + 0x012a)
	calr GetClientBox
	lda xiy, (xsp+288)
	lda xix, (xsp+280)
	ld bc, 4:i3
	ldirw
	lda xhl, (xsp+272)
	lda xwa, (xsp+288)
	ld bc, (xwa)
	ld (xhl), bc
	lda xix, (xsp+268)
	ld bc, (xwa + 4)
	ld (xix), bc
	ld de, (xwa + 2)
	ld bc, (xwa + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld (xhl + 2), de
	ld (xix + 2), de
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+272)
	lda xbc, (xsp+268)
	cp	(xsp+296), 0x0b
	jrl z, ButtonState_Paint_Default
	cp	(xsp+296), 0x0e
	jrl z, ButtonState_Paint_EventConfirm
	cp	(xsp+296), 0x03
	jrl nz, ButtonState_DispatchDSP
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x9b
	ld (xbc + 1), 0x0
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	ld xhl, xix
	pushw	(xhl+22)
	call DrawStringCentered
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	inc 1, bc
	ld (xwa + 2), bc
	ld	bc, (xsp+294)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x98
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	ld xhl, xix
	pushw	(xhl+22)
	jrl ButtonState_Paint_DrawAndReturn

ButtonState_Paint_EventConfirm:
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x85
	ld (xbc + 1), 0x0
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	ld xhl, xix
	pushw	(xhl+22)
	call DrawStringCentered
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	inc 1, bc
	ld (xwa + 2), bc
	ld	bc, (xsp+294)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x81
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushw	(xix+32)
	ld xhl, xix
	pushw	(xhl+22)
	jrl ButtonState_Paint_DrawAndReturn

ButtonState_Paint_Default:
	ld (xsp + 8), xwa
	ld xiz, xbc
	ld XWA, (xsp + 0x012a)
	calr GetFrameColor
	ld de, hl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	call DrawLine
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushw	(xhl+32)
	ld xde, xhl
	pushw	(xde+22)
	ld xde, ButtonState_Paint_EventConfirm_Str_ON
	call DrawStringCentered
	lda xwa, (xsp+280)
	ld	bc, (xsp+274)
	inc 1, bc
	ld (xwa + 2), bc
	ld	bc, (xsp+294)
	ld (xwa + 6), bc
	lda xbc, (xsp+276)
	calr GetBoxCenter
	lda xwa, (xsp+280)
	lda xbc, (xsp+276)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushw	(xhl+32)
	ld xde, xhl
	pushw	(xde+22)
	ld xde, ButtonState_Paint_EventConfirm_Str_OFF

ButtonState_Paint_DrawAndReturn:
	call DrawStringCentered
	jrl ButtonState_Paint_Return

; ButtonState event dispatch via DSP handler table
ButtonState_DispatchDSP:
	ld	a, (xsp+296)
	extz wa
	cp wa, 0:i3
	jrl mi, ButtonState_Paint_DrawAligned
	cp wa, 0x10
	jrl gt, ButtonState_Paint_DrawAligned
	add wa, wa
	lda xix, (Str_No_0x4:24)
	ld	wa, (xix+wa)
	lda xix, (ButtonState_DispatchDSP_InlineData:24)
	jp	t, (xix+wa)

ButtonState_DispatchDSP_InlineData:
	lda	xde, (xsp+12)
	ld	xwa, (xsp+298)
	ld	xbc, EVT_GET_STRING
	call	SendEvent
	jr	ButtonState_Paint_DrawAligned
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N9b
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N98
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N85
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N81
	jr	ButtonState_PaintProc_Join
	ld	xwa, NakaInst_OK
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_OFF
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_OK
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_Lt
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_Gt
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N7f
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_N80
	jr	ButtonState_PaintProc_Join
	ld	xwa, ButtonState_DispatchDSP_InlineData_Str_YES
	jr	ButtonState_PaintProc_Join
	ld	xwa, Str_No
ButtonState_PaintProc_Join:
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp

ButtonState_Paint_DrawAligned:
	lda xwa, (xsp+288)
	lda xhl, (xsp+276)
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xbc, (xix + 28)
	push xbc
	pushw	(xix+32)
	ld xbc, xix
	pushw	(xbc+22)
	ld c, (xbc + 34)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringAlignment

ButtonState_Paint_Return:
	pop xiz
	lda xsp, (xsp+298)
	ret

PsWideESBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	cp xbc, EVT_CHECK_EDIT_SW
	jrl z, PsWideESBox_GetRange
	cp xbc, EVT_SET_EDIT_SW_RECT
	jr z, PsWideESBox_GetEditRange
	ld xde, (xsp + 20)
	calr PsEditSwBoxProc
	jrl PsWideESBox_Return

PsWideESBox_GetEditRange:
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 20)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ldfr_werp WA, 0xfa
	ld xwa, (xsp + 20)
	ld iz, wa
	ldto_werp WA, 0xfa
	cp wa, iz
	jr c, PsWideESBox_ComputePoints
	ldto_werp HL, 0xfa
	ldto_werp WA, 0xfa
	ex16 wa, iz
	ldfr_werp WA, 0xfa

PsWideESBox_ComputePoints:
	lda xbc, (xsp + 16)
	ldto_werp WA, 0xfa
	calr GetEditSwPoint
	lda xbc, (xsp + 12)
	ld wa, iz
	calr GetEditSwPoint
	lda xbc, (xsp + 16)
	cpw (xbc + 2), 0xef
	jr nz, UIViewFrame_ZeroReturn
	ld xwa, (xsp + 8)
	ldw (xwa + 16), 0xd8
	ldw (xwa + 20), 0xee
	ld bc, (xbc)
	sub bc, 0x10
	ld (xwa + 14), bc
	ld bc, (xsp + 12)
	add bc, 0xf
	ld xwa, (xsp + 4)
	ld (xwa + 18), bc

UIViewFrame_ZeroReturn:
	ld xhl, 0:i3
	jr PsWideESBox_Return

PsWideESBox_GetRange:
	call GetViewInstance
	lda xwa, (xhl + 36)
	lda xhl, (xhl + 38)
	ld bc, (xhl)
	ld de, (xwa)
	ld wa, de
	cp wa, (xhl)
	jr nc, PsWideESBox_GetRange_SwapMax
	ldfr_werp DE, 0xfa
	ld iz, bc
	jr PsWideESBox_GetRange_SendEvent

PsWideESBox_GetRange_SwapMax:
	ldfr_werp BC, 0xfa
	ld iz, de

PsWideESBox_GetRange_SendEvent:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 20)
	call SendEvent
	cpw_erp HL, 0xfa
	jr c, UIViewFrame_ZeroReturn
	cp hl, iz
	jr ugt, UIViewFrame_ZeroReturn
	ld xhl, 1:i3

PsWideESBox_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

AcIndexEditSwProc:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), xbc
	ld xiz, xwa
	ld xwa, (xsp + 10)
	cp xwa, EVT_SW_BOTH
	jrl z, AcIndexEdit_Reset
	cp xwa, EVT_SW_IN
	jr z, AcIndexEdit_OK
	cp xwa, EVT_DRAW
	jr z, AcIndexEdit_Paint
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	jrl AcIndexEdit_InheritedProc

AcIndexEdit_Paint:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, AcIndexEdit_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	jrl AcIndexEdit_SendAndReturn

AcIndexEdit_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	jrl AcIndexEdit_SendAndReturn

AcIndexEdit_OK:
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jrl z, AcIndexEdit_Fallthrough
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 6)
	call SendEvent
	cp hl, 0:i3
	jrl z, AcIndexEdit_Fallthrough
	ld xwa, xiz
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jrl z, AcIndexEdit_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, AcIndexEdit_OK_AltView
	ld xwa, xiz
	ld xiz, 0x28
	jr AcIndexEdit_DispatchDSP

AcIndexEdit_OK_AltView:
	ld xwa, xiz
	ld xiz, 0x26

; AcIndexEdit widget dispatch with view lookup
AcIndexEdit_DispatchDSP:
	call GetViewInstance
	add xhl, xiz
	ld a, (xhl)
	extz wa
	cp wa, 0:i3
	jrl mi, AcIndexEdit_ReturnZeroJmp
	cp wa, 0x10
	jrl gt, AcIndexEdit_ReturnZeroJmp
	lda xix, (Str_No_0x26:24)
	ld	wa, (xix+wa)
	extz wa
	sll wa, 1
	ld xix, Str_No_0x38
	ld	wa, (xix+wa)
	lda xix, (AcIndexEdit_DispatchDSP_InlineData:24)
	jp	t, (xix+wa)

AcIndexEdit_DispatchDSP_InlineData:
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	bit	7, wa
	jr	z, ButtonState_PaintProc_Skip
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INDEXSW_DOWN
	jrl	AcIndexEdit_SendAndReturn
ButtonState_PaintProc_Skip:
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INDEXSW_UP
	jrl	AcIndexEdit_SendAndReturn
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INDEXSW_UP
	jrl	AcIndexEdit_SendAndReturn
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INDEXSW_DOWN
	jr	t, AcIndexEdit_SendAndReturn

AcIndexEdit_Fallthrough:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	jr AcIndexEdit_InheritedProc

AcIndexEdit_Reset:
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jr z, AcIndexEdit_FallthroughAlt
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 6)
	call SendEvent
	cp hl, 0:i3
	jr z, AcIndexEdit_FallthroughAlt
	ld xwa, xiz
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jr z, AcIndexEdit_ReturnZeroJmp
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	ld xde, (xsp + 6)
	call SendEvent
	ld xde, (xsp + 6)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call SendEvent
	ld de, (xsp + 4)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_BOTH

AcIndexEdit_SendAndReturn:
	call SendEvent

AcIndexEdit_ReturnZeroJmp:
	ld xhl, 0:i3
	jr AcIndexEdit_Return

AcIndexEdit_FallthroughAlt:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)

AcIndexEdit_InheritedProc:
	call InheritedProc

AcIndexEdit_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

AcFuncEditSwProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SW_IN
	jr z, AcFuncEdit_OK
	cp xwa, EVT_DRAW
	jr z, AcFuncEdit_Paint
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl AcFuncEdit_InheritedProc

AcFuncEdit_Paint:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, AcFuncEdit_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	jr AcFuncEdit_Paint_SendConfirm

AcFuncEdit_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW

AcFuncEdit_Paint_SendConfirm:
	call SendEvent
	jr AcFuncEdit_ReturnZero

AcFuncEdit_OK:
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jr z, AcFuncEdit_Fallthrough
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	cp hl, 0:i3
	jr z, AcFuncEdit_Fallthrough
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, AcFuncEdit_OK_AltFunc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 42)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcFuncEdit_OK_CallFunc

AcFuncEdit_OK_AltFunc:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

AcFuncEdit_OK_CallFunc:
	call ApFuncCall

AcFuncEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcFuncEdit_Return

AcFuncEdit_Fallthrough:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

AcFuncEdit_InheritedProc:
	call InheritedProc

AcFuncEdit_Return:
	pop xiz
	inc 8, xsp
	ret

VwEditSwBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_GET_STRING
	jr z, VwEditSwBox_GetText
	cp xbc, EVT_DRAW
	jr z, VwEditSwBox_Paint
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl VwEditSwBox_Return

VwEditSwBox_Paint:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, VwEditSwBox_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	jr VwEditSwBox_Paint_SendConfirm

VwEditSwBox_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	ld xde, 0:i3
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW

VwEditSwBox_Paint_SendConfirm:
	call SendEvent
	jr VwEditSwBox_ReturnZero

VwEditSwBox_GetText:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_PsWideESBox
	call SendEvent
	or xhl, xhl
	jr z, VwEditSwBox_GetText_AltView
	ld xwa, xiz
	ld xiz, 0x2a
	jr VwEditSwBox_GetText_CopyStr

VwEditSwBox_GetText_AltView:
	ld xwa, xiz
	ld xiz, 0x28

VwEditSwBox_GetText_CopyStr:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

VwEditSwBox_ReturnZero:
	ld xhl, 0:i3

VwEditSwBox_Return:
	pop xiz
	inc 4, xsp
	ret

PsPageBoxProc:
	lda xsp, (xsp-276)
	push xiz
	ld xiz, xde
	ld	(xsp+276), xwa
	cp xbc, EVT_SET_PAGE
	jrl z, PsPageBox_SetValue
	cp xbc, EVT_GET_PAGE_NOW
	jrl z, PsPageBox_GetValue
	cp xbc, EVT_GET_PAGE_MAX
	jrl z, PsPageBox_ReturnOne
	cp xbc, EVT_GET_PAGE_MIN
	jrl z, PsPageBox_ReturnOne
	cp xbc, EVT_CHECK_EDIT_SW
	jrl z, PsPageBox_HitTest
	cp xbc, EVT_PARA_DRAW
	jr z, PsPageBox_Confirm
	cp xbc, EVT_SHOW
	jrl nz, PsPageBox_Default
	ld XWA, (xsp + 0x0114)
	ld xde, xiz
	calr VwBoxProc
	cp xiz, 0x4
	jr z, UI_VwBox_SendCurrentValue
	cp xiz, 0x3
	jr z, UI_VwBox_SendCurrentValue
	cp xiz, 0x5
	jr z, UI_VwBox_SendCurrentValue
	or xiz, xiz
	jrl nz, UIVwBox_ZeroReturn

UI_VwBox_SendCurrentValue:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_CHANGE
	call SendEvent
	jrl UIVwBox_ZeroReturn

PsPageBox_Confirm:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld (xsp + 4), xhl
	or xiz, xiz
	jr z, PsPageBox_Confirm_DrawValue
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	ld xwa, (xbc)
	ld de, iz
	ld (xwa), de
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_CHANGE
	call SendEvent

PsPageBox_Confirm_DrawValue:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld iz, (xwa)
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_GET_PAGE_MAX
	ld xde, 0:i3
	call SendEvent
	pushw hl
	pushw iz
	pushw PsPageBox_Confirm_DrawValue_Str_PAGE_Fmtd_Fmtd@hi16
	pushw PsPageBox_Confirm_DrawValue_Str_PAGE_Fmtd_Fmtd@lo16
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xbc, (xsp+268)
	ld XWA, (xsp + 0x0114)
	calr GetClientBox
	lda xwa, (xsp+268)
	lda xbc, (xsp+264)
	calr GetBoxCenter
	lda xwa, (xsp+268)
	lda xbc, (xsp+264)
	lda xde, (xsp + 8)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	ld xhl, (xsp + 10)
	pushw	(xhl+22)
	call DrawStringCentered
	jr UIVwBox_ZeroReturn

PsPageBox_HitTest:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, xiz
	call SendEvent
	cp xhl, 0x10
	scc16 z, hl
	extz xhl
	jr UI_VwBox_Return

PsPageBox_ReturnOne:
	ld xhl, 1:i3
	jr UI_VwBox_Return

PsPageBox_GetValue:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld hl, (xwa)
	exts xhl
	jr UI_VwBox_Return

PsPageBox_SetValue:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xbc, (xhl + 28)
	ld wa, iz
	ld (xbc), wa

UIVwBox_ZeroReturn:
	ld xhl, 0:i3
	jr UI_VwBox_Return

PsPageBox_Default:
	ld XWA, (xsp + 0x0114)
	ld xde, xiz
	calr VwBoxProc

UI_VwBox_Return:
	pop xiz
	lda xsp, (xsp+276)
	ret

AcWindowPageProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_SW_IN
	jr z, AcWindowPage_OK
	cp xiz, EVT_GET_PAGE_MAX
	jr z, AcWindowPage_GetMax
	cp xiz, EVT_GET_PAGE_MIN
	jr z, AcWindowPage_GetMin
	cp xiz, EVT_DRAW
	jr z, AcWindowPage_Paint
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jrl AcWindowPage_DefaultCall

AcWindowPage_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsPageBoxProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcWindowPage_SendConfirm

AcWindowPage_GetMin:
	ld xwa, (xsp + 12)
	ld xiz, 0x20
	jr AcWindowPage_GetViewOffset

AcWindowPage_GetMax:
	ld xwa, (xsp + 12)
	ld xiz, 0x22

AcWindowPage_GetViewOffset:
	call GetViewInstance
	add xhl, xiz
	ld hl, (xhl)
	exts xhl
	jr PsToggleBoxProc_Epilogue

AcWindowPage_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcWindowPage_Default
	ld xwa, (xsp + 12)
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 32)
	lda xde, (xwa + 34)
	ld xwa, (xsp + 8)
	bit 7, wa
	jr z, AcWindowPage_OK_IncrCheck
	cp hl, (xbc)
	jr le, AcWindowPage_OK_DecrWrap
	dec 1, hl
	jr AcWindowPage_OK_DecrDone

AcWindowPage_OK_DecrWrap:
	ld hl, (xde)

AcWindowPage_OK_DecrDone:
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, xhl
	jr AcWindowPage_SendConfirm

AcWindowPage_OK_IncrCheck:
	cp hl, (xde)
	jr ge, AcWindowPage_OK_IncrWrap
	inc 1, hl
	jr AcWindowPage_OK_IncrDone

AcWindowPage_OK_IncrWrap:
	ld hl, (xbc)

AcWindowPage_OK_IncrDone:
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, xhl

AcWindowPage_SendConfirm:
	call SendEvent
	ld xhl, 0:i3
	jr PsToggleBoxProc_Epilogue

AcWindowPage_Default:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcWindowPage_DefaultCall:
	calr PsPageBoxProc

; PsToggleBoxProc epilogue handler
PsToggleBoxProc_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PsToggleBoxProc:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 24), xde
	ld (xsp + 28), xwa
	cp xbc, EVT_SET_VISIBLE
	jrl z, PsToggleBox_Repaint
	cp xbc, EVT_GET_PARAM
	jrl z, PsToggleBox_GetValue
	cp xbc, EVT_SET_PARAM
	jrl z, PsToggleBox_SetValue
	cp xbc, EVT_TOGGLE_PARAM
	jrl z, PsToggleBox_Toggle
	cp xbc, EVT_CHECK_EDIT_SW
	jrl z, PsToggleBox_HitTest
	cp xbc, EVT_PARA_DRAW
	jr z, PsToggleBox_Confirm
	cp xbc, EVT_DRAW
	jrl nz, PsToggleBox_Default
	ld xwa, (xsp + 28)
	ld xde, (xsp + 24)
	call ViewableProc
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xsp + 16)
	ld wa, (xiz + 38)
	calr GetEditSwPoint
	cpw (xsp + 18), 0xef
	jr z, PsToggleBox_Paint_SendConfirm
	ld wa, (xiz + 38)
	calr DrawEditSw

PsToggleBox_Paint_SendConfirm:
	ld xwa, (xiz + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 28)
	ld xbc, EVT_PARA_DRAW
	jrl PsToggleBox_SetValue_Dispatch

PsToggleBox_Confirm:
	ld xwa, (xsp + 28)
	ld xde, (xsp + 24)
	call ViewableProc
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 34)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp xbc, (xsp + 24)
	jr z, PsToggleBox_Confirm_Layout
	ld xbc, (xwa)
	ld xwa, (xsp + 24)
	ld (xbc), wa

PsToggleBox_Confirm_Layout:
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 28)
	call GetClientBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 20)
	calr GetBoxCenter
	ld xbc, (xsp + 4)
	ld xde, (xbc + 34)
	lda xwa, (xbc + 14)
	lda xbc, (xbc + 38)
	cpw (xde), 0x0
	jr z, PsToggleBox_Confirm_DrawOff
	cpw (xbc), 0x7
	jr ugt, PsToggleBox_Confirm_OnLarge
	ldw bc, 0xca
	ldw de, 0xa
	jr PsToggleBox_Confirm_DrawOn

PsToggleBox_Confirm_OnLarge:
	ldw bc, 0xc3
	ldw de, 0xa

PsToggleBox_Confirm_DrawOn:
	call DrawDesignBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 20)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 22)
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, (xhl + 26)
	jr PsToggleBox_Confirm_RenderText

PsToggleBox_Confirm_DrawOff:
	cpw (xbc), 0x7
	jr ugt, PsToggleBox_Confirm_OffLarge
	ldw bc, 0xc9
	ld de, 7:i3
	jr PsToggleBox_Confirm_DrawOffBox

PsToggleBox_Confirm_OffLarge:
	ldw bc, 0xc1
	ld de, 7:i3

PsToggleBox_Confirm_DrawOffBox:
	call DrawDesignBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 20)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 22)
	push xde
	pushw 0x0
	pushw 0xf7
	ld xde, (xhl + 30)

PsToggleBox_Confirm_RenderText:
	call DrawStringCentered
	jrl PsToggleBox_ReturnZero

PsToggleBox_HitTest:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 28)
	call GetVisible
	cp hl, 0:i3
	jrl z, PsToggleBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 24)
	call SendEvent
	ld xwa, (xsp + 4)
	ld wa, (xwa + 38)
	extz xwa
	cp xwa, xhl
	jrl nz, PsToggleBox_ReturnZero
	ld xhl, 1:i3
	jrl PsToggleBox_Return

PsToggleBox_Toggle:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 34)
	cpw (xwa), 0x0
	jr z, PsToggleBox_Toggle_SetOn
	ld xwa, (xsp + 28)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr PsToggleBox_Toggle_Dispatch

PsToggleBox_Toggle_SetOn:
	ld xwa, (xsp + 28)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3

PsToggleBox_Toggle_Dispatch:
	call SendEvent
	ld xhl, (xsp + 4)
	jr PsToggleBox_GetValue_Read

PsToggleBox_SetValue:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xbc, (xhl + 34)
	ld xwa, (xsp + 24)
	cp wa, (xbc)
	jrl z, PsToggleBox_ReturnZero
	ld xwa, (xsp + 28)
	ld xbc, EVT_PARA_DRAW
	ld xde, (xsp + 24)

PsToggleBox_SetValue_Dispatch:
	call SendEvent
	jr PsToggleBox_ReturnZero

PsToggleBox_GetValue:
	ld xwa, (xsp + 28)
	call GetViewInstance

PsToggleBox_GetValue_Read:
	ld xwa, (xhl + 34)
	ld hl, (xwa)
	exts xhl
	jr PsToggleBox_Return

PsToggleBox_Repaint:
	ld xwa, (xsp + 28)
	ld xde, (xsp + 24)
	call ViewableProc
	ld xwa, (xsp + 28)
	call GetVisible
	cp hl, 0:i3
	jr z, PsToggleBox_Repaint_UpdateBounds
	ld xwa, (xsp + 28)
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call SendEvent
	jr PsToggleBox_ReturnZero

PsToggleBox_Repaint_UpdateBounds:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 28)
	call GetBox
	lda xbc, (xsp + 20)
	ld xwa, (xsp + 4)
	ld wa, (xwa + 38)
	calr GetEditSwPoint
	lda xwa, (xsp + 20)
	cpw (xwa + 2), 0xef
	jr z, PsToggleBox_Repaint_Render
	lda xbc, (xsp + 8)
	cpw (xwa), 0x13f
	jr z, PsToggleBox_Repaint_ClampRight
	ldw (xbc), 0x0
	jr PsToggleBox_Repaint_Render

PsToggleBox_Repaint_ClampRight:
	ldw (xbc + 4), 0x13f

PsToggleBox_Repaint_Render:
	lda xwa, (xsp + 8)
	ldw bc, 0xf5
	call DrawBox

PsToggleBox_ReturnZero:
	ld xhl, 0:i3
	jr PsToggleBox_Return

PsToggleBox_Default:
	ld xwa, (xsp + 28)
	ld xde, (xsp + 24)
	call ViewableProc

PsToggleBox_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

AcFuncToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, EVT_SW_IN
	jr z, AcFuncToggle_OK
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcFuncToggle_DefaultTail

AcFuncToggle_OK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcFuncToggle_Default
	ld xwa, xiz
	ld xbc, EVT_TOGGLE_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, EVT_SET_PARAM
	call ApFuncCall
	ld xhl, 0:i3
	jr AcFuncToggle_Return

AcFuncToggle_Default:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcFuncToggle_DefaultTail:
	calr PsToggleBoxProc

AcFuncToggle_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcIndexToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_CHECK_INDEX
	jrl z, AcIndexToggle_CanScrollEvt
	cp xiz, EVT_GET_INDEX
	jrl z, AcIndexToggle_GetIndex
	cp xiz, EVT_YOU_ARE_SELECTED
	jrl z, AcIndexToggle_Select
	cp xiz, EVT_INDEX_SELECT
	jrl z, AcIndexToggle_Release
	cp xiz, EVT_SW_IN
	jr z, AcIndexToggle_OK
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr AcIndexToggle_DefaultTail

AcIndexToggle_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	call GetVisible
	cp hl, 0:i3
	jr z, AcIndexToggle_OK_Default
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcIndexToggle_OK_Default
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0xffff
	jr z, AcIndexToggle_OK_SetValue
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent

AcIndexToggle_OK_SetValue:
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld bc, (xwa + 42)
	extz xbc
	ld wa, (xwa + 40)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, EVT_I_AM_SELECTED
	jrl AcIndexToggle_Dispatch

AcIndexToggle_OK_Default:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcIndexToggle_DefaultTail:
	calr PsToggleBoxProc
	jrl AcIndexToggle_Return

AcIndexToggle_Release:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsToggleBoxProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 40)
	exts xwa
	cp xwa, (xsp + 8)
	jr nz, AcIndexToggle_ReturnZero
	ld xwa, (xhl + 34)
	cpw (xwa), 0x0
	jr z, AcIndexToggle_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	jr AcIndexToggle_Dispatch

AcIndexToggle_Select:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsToggleBoxProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 40)
	cpw (xwa), 0xffff
	jr z, AcIndexToggle_ReturnZero
	ld xbc, (xsp + 8)
	srl xbc, 16
	ldiw_erp 0xe6, 0
	ld de, (xwa)
	ld wa, de
	cp wa, bc
	jr nz, AcIndexToggle_ReturnZero
	ld xwa, (xsp + 8)
	ld bc, (xhl + 42)
	cp bc, wa
	jr nz, AcIndexToggle_ReturnZero
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3

AcIndexToggle_Dispatch:
	call SendEvent

AcIndexToggle_ReturnZero:
	ld xhl, 0:i3
	jr AcIndexToggle_Return

AcIndexToggle_GetIndex:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld hl, (xhl + 40)
	exts xhl
	jr AcIndexToggle_Return

AcIndexToggle_CanScrollEvt:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 40)
	exts xwa
	cp xwa, (xsp + 8)
	scc16 z, hl
	extz xhl

AcIndexToggle_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PsWideToggleProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	cp xbc, EVT_CHECK_EDIT_SW
	jrl z, PsWideToggle_HitTest
	cp xbc, EVT_SET_EDIT_SW_RECT
	jr z, PsWideToggle_GetBounds
	ld xde, (xsp + 20)
	calr PsToggleBoxProc
	jrl PsWideToggle_Return

PsWideToggle_GetBounds:
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 20)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ldfr_werp WA, 0xfa
	ld xwa, (xsp + 20)
	ld iz, wa
	ldto_werp WA, 0xfa
	cp wa, iz
	jr c, PsWideToggle_GetBounds_CalcPts
	ldto_werp HL, 0xfa
	ldto_werp WA, 0xfa
	ex16 wa, iz
	ldfr_werp WA, 0xfa

PsWideToggle_GetBounds_CalcPts:
	lda xbc, (xsp + 16)
	ldto_werp WA, 0xfa
	calr GetEditSwPoint
	lda xbc, (xsp + 12)
	ld wa, iz
	calr GetEditSwPoint
	lda xbc, (xsp + 16)
	cpw (xbc + 2), 0xef
	jr nz, PsWideToggle_ReturnZero
	ld xwa, (xsp + 8)
	ldw (xwa + 16), 0xd8
	ldw (xwa + 20), 0xee
	ld bc, (xbc)
	sub bc, 0x10
	ld (xwa + 14), bc
	ld bc, (xsp + 12)
	add bc, 0xf
	ld xwa, (xsp + 4)
	ld (xwa + 18), bc

PsWideToggle_ReturnZero:
	ld xhl, 0:i3
	jr PsWideToggle_Return

PsWideToggle_HitTest:
	call GetViewInstance
	lda xwa, (xhl + 38)
	lda xhl, (xhl + 40)
	ld bc, (xhl)
	ld de, (xwa)
	ld wa, de
	cp wa, (xhl)
	jr nc, PsWideToggle_HitTest_SwapOrder
	ldfr_werp DE, 0xfa
	ld iz, bc
	jr PsWideToggle_HitTest_Check

PsWideToggle_HitTest_SwapOrder:
	ldfr_werp BC, 0xfa
	ld iz, de

PsWideToggle_HitTest_Check:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 20)
	call SendEvent
	cpw_erp HL, 0xfa
	jr c, PsWideToggle_ReturnZero
	cp hl, iz
	jr ugt, PsWideToggle_ReturnZero
	ld xhl, 1:i3

PsWideToggle_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

PsInvisibleBoxProc:
	cp xbc, EVT_GET_STRING
	jr z, PsInvisibleBox_GetText
	cp xbc, EVT_PARA_DRAW
	jr z, PsInvisibleBox_ReturnZero
	cp xbc, EVT_DRAW
	jr z, PsInvisibleBox_ReturnZero
	jp ViewableProc

PsInvisibleBox_GetText:
	ld (xde), 0x0

PsInvisibleBox_ReturnZero:
	ld xhl, 0:i3
	ret

IvPageControlProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_PAGE_CHANGE
	jr z, IvPageControl_PageChange
	cp xiz, EVT_GET_STRING
	jr z, IvPageControl_GetText
	cp xiz, EVT_DRAW
	jr z, IvPageControl_Paint
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsInvisibleBoxProc
	jrl IvPageControl_Return

IvPageControl_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr IvPageControl_Dispatch

IvPageControl_GetText:
	pushw IvPageControl_GetText_Str_PAGE@hi16
	pushw IvPageControl_GetText_Str_PAGE@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr IvPageControl_ReturnZero

IvPageControl_PageChange:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld xbc, EVT_CHECK_SHOW_WINDOW
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvPageControl_PageChange_Init
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent

IvPageControl_PageChange_Init:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsInvisibleBoxProc
	ld xbc, (xsp + 4)
	ld wa, (xbc + 22)
	exts xwa
	cp xwa, (xsp + 8)
	jr nz, IvPageControl_ReturnZero
	ld xwa, (xbc + 24)
	ld xbc, EVT_SHOW
	ld xde, 0:i3

IvPageControl_Dispatch:
	call SendEvent

IvPageControl_ReturnZero:
	ld xhl, 0:i3

IvPageControl_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvMainEditSwProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_SEND_SW_BOTH
	jrl z, IvMainEditSw_BtnRecord
	cp xbc, EVT_SEND_SW_OFF
	jr z, IvMainEditSw_BtnDelete
	cp xbc, EVT_SEND_SW_ON
	jr z, IvMainEditSw_BtnCancel
	cp xbc, EVT_SEND_SW_IN
	jr z, IvMainEditSw_BtnOK
	cp xbc, EVT_GET_STRING
	jr z, IvMainEditSw_GetText
	cp xbc, EVT_DRAW
	jr nz, IvMainEditSw_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvMainEditSw_ReturnZero

IvMainEditSw_GetText:
	pushw IvMainEditSw_GetText_Str_MnSw@hi16
	pushw IvMainEditSw_GetText_Str_MnSw@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr IvMainEditSw_ReturnZero

IvMainEditSw_BtnOK:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, EVT_SW_IN
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnCancel:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, EVT_SW_ON
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnDelete:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, EVT_SW_OFF
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnRecord:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, EVT_SW_BOTH
	ld xde, (xsp + 4)

IvMainEditSw_DispatchChild:
	call MainFuncCall

IvMainEditSw_ReturnZero:
	ld xhl, 0:i3
	jr IvMainEditSw_Return

IvMainEditSw_Default:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

IvMainEditSw_Return:
	pop xiz
	inc 4, xsp
	ret

IvExitProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_CHECK_EDIT_SW
	jr z, IvExit_HitTest
	cp xbc, EVT_GET_STRING
	jr z, IvExit_GetText
	cp xbc, EVT_DRAW
	jr z, IvExit_Paint
	ld xwa, xiz
	calr PsInvisibleBoxProc
	jr IvExit_Return

IvExit_Paint:
	ld xwa, xiz
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvExit_ReturnZero

IvExit_GetText:
	pushw IvExit_GetText_Str_EXIT@hi16
	pushw IvExit_GetText_Str_EXIT@lo16
	push xde
	call Strcpy
	inc 8, xsp

IvExit_ReturnZero:
	ld xhl, 0:i3
	jr IvExit_Return

IvExit_HitTest:
	cp xde, 0xf
	scc16 z, hl
	extz xhl

IvExit_Return:
	pop xiz
	ret

IvExitModeProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SW_IN
	jr z, IvExitMode_OK
	cp xwa, EVT_GET_STRING
	jr z, IvExitMode_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitMode_DefaultTail

IvExitMode_GetText:
	pushw IvExitMode_GetText_Str_ExMD@hi16
	pushw IvExitMode_GetText_Str_ExMD@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr IvExitMode_Return

IvExitMode_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitMode_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, IvExitMode_OK_SaveCheck
	ld xde, (xiz + 22)
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	call PostEvent
	jr IvExitMode_OK_Forward

IvExitMode_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent

IvExitMode_OK_Forward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvExitMode_DefaultTail:
	calr IvExitProc

IvExitMode_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvExitScreenProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SW_IN
	jr z, IvExitScreen_OK
	cp xwa, EVT_GET_STRING
	jr z, IvExitScreen_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitScreen_DefaultTail

IvExitScreen_GetText:
	pushw IvExitScreen_GetText_Str_ExSC@hi16
	pushw IvExitScreen_GetText_Str_ExSC@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr IvExitScreen_Return

IvExitScreen_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitScreen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, IvExitScreen_OK_SaveCheck
	ld xwa, (xiz + 22)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call PostEvent
	jr IvExitScreen_OK_Forward

IvExitScreen_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent

IvExitScreen_OK_Forward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvExitScreen_DefaultTail:
	calr IvExitProc

IvExitScreen_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvExitWindowProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvExitWindow_OK
	cp xiz, EVT_GET_STRING
	jr z, IvExitWindow_GetText
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvExitWindow_DefaultTail

IvExitWindow_GetText:
	pushw IvExitWindow_GetText_Str_ExWn@hi16
	pushw IvExitWindow_GetText_Str_ExWn@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr IvExitWindow_Return

IvExitWindow_OK:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitWindow_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, IvExitWindow_OK_SaveCheck
	ld xwa, 0xffffffff
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	jr IvExitWindow_OK_Forward

IvExitWindow_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent

IvExitWindow_OK_Forward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvExitWindow_DefaultTail:
	calr IvExitProc

IvExitWindow_Return:
	pop xiz
	inc 8, xsp
	ret

IvFixWinProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SHOW
	jr z, IvFixWin_Init
	cp xwa, EVT_DRAW
	jr z, IvFixWin_Paint
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jr IvFixWin_Return

IvFixWin_Paint:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, IvFixWin_Paint_Str_FWin
	jr IvFixWin_Dispatch

IvFixWin_Init:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvFixWin_Init_DispatchChild
	cp xwa, 0x5
	jr z, IvFixWin_Init_DispatchChild
	or xwa, xwa
	jr nz, IvFixWin_ReturnZero

IvFixWin_Init_DispatchChild:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvFixWin_Dispatch:
	call SendEvent

IvFixWin_ReturnZero:
	ld xhl, 0:i3

IvFixWin_Return:
	pop xiz
	inc 8, xsp
	ret

IvNamingProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_HIDE
	jr z, IvNaming_Close
	cp xiz, EVT_SHOW
	jr z, IvNaming_Init
	cp xiz, EVT_DRAW
	jr z, IvNaming_Paint
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jr IvNaming_Return

IvNaming_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, IvNaming_Paint_Str_Name
	jr IvNaming_Dispatch

IvNaming_Init:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xde, (xhl + 22)
	ld xwa, 0xa
	ld xbc, EVT_SET_AP_FUNCTION
	call SendEvent
	ld xwa, 0xa
	ld xbc, xiz
	ld xde, 0:i3

IvNaming_Dispatch:
	call SendEvent
	jr IvNaming_ReturnZero

IvNaming_Close:
	ld xwa, 0xa
	ld xbc, xiz
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

IvNaming_ReturnZero:
	ld xhl, 0:i3

IvNaming_Return:
	pop xiz
	inc 8, xsp
	ret

GetNamingWindowID:
	ld xhl, 0xa
	ret

NamingCheck:
	push xiz
	ld xiz, xwa
	lda xwa, (0x03ef6e:24)
	cp xbc, EVT_GET_STRING_LENGTH
	jr z, NamingCheck_GetStrLen
	cp xbc, EVT_GET_NAMING_MODE
	jr z, NamingCheck_NotHandled
	cp xbc, EVT_GET_STRING
	jr nz, NamingCheck_NotHandled
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr NamingCheck_Return

NamingCheck_NotHandled:
	ld xhl, 0:i3
	jr NamingCheck_Return

NamingCheck_GetStrLen:
	push xwa
	call Strlen
	inc 4, xsp
	extz xhl

NamingCheck_Return:
	pop xiz
	ret

IvTrackSwitchProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SHOW
	jr z, IvTrackSwitch_Init
	cp xwa, EVT_DRAW
	jr z, IvTrackSwitch_Paint
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jr IvTrackSwitch_Return

IvTrackSwitch_Paint:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, IvTrackSwitch_Paint_Str_TrSw
	jr IvTrackSwitch_Dispatch

IvTrackSwitch_Init:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, 0x20
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvTrackSwitch_Dispatch:
	call SendEvent
	ld xhl, 0:i3

IvTrackSwitch_Return:
	pop xiz
	inc 8, xsp
	ret

IvCatchEventProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 16)
	cp xwa, NakaData_RomEnd
	jr ule, IvCatchEvent_Lookup
	cp xwa, 0x3000000
	jr c, IvCatchEvent_Forward
	cp xwa, 0x3ffffff
	jr ugt, IvCatchEvent_Forward

IvCatchEvent_Lookup:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ld xhl, xwa
	ldiw_erp 0xee, 0
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda xbc, (0x027edc:24)
	add xbc, xde
	ld xde, (xbc)
	extz xhl
	sll xhl, 2
	add xhl, xde
	ld xiz, (xhl)
	ld xix, xiz
	ld xbc, EVT_ARE_YOU_CLASS_PROC
	ld xde, 0:i3
	call (xix)
	or xhl, xhl
	jr z, IvCatchEvent_NoCallback
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call (xiz)
	jr IvCatchEvent_Return

IvCatchEvent_NoCallback:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall

IvCatchEvent_Forward:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsInvisibleBoxProc

IvCatchEvent_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

DefaultClassProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
	jr z, DefaultClass_Paint
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr z, DefaultClass_ReturnOne
	ld xwa, xiz
	call InheritedProc
	jr DefaultClass_Return

DefaultClass_ReturnOne:
	ld xhl, 1:i3
	jr DefaultClass_Return

DefaultClass_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, DefaultClass_Paint_Str_CcEv
	call SendEvent
	ld xhl, 0:i3

DefaultClass_Return:
	pop xiz
	ret

IvInterruptProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_INTERRUPT_OFF
	jrl z, IvInterrupt_CheckActive
	cp xiz, EVT_GET_INTERRUPT_TIME
	jrl z, IvInterrupt_GetInterval
	cp xiz, EVT_GET_STRING
	jr z, IvInterrupt_GetText
	cp xiz, EVT_DRAW
	jr z, IvInterrupt_Paint
	cp xiz, EVT_SHOW
	jr z, IvInterrupt_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jrl ReminderProc_Return

IvInterrupt_Init:
	ld xwa, (xsp + 8)
	ld xbc, EVT_GET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent
	cp hl, 1:i3
	jr nz, IvInterrupt_Init_SetTimer
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld hl, (xhl + 22)

IvInterrupt_Init_SetTimer:
	ld wa, hl
	call SetInterruptTime
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jr IvInterrupt_ReturnZero

IvInterrupt_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvInterrupt_ReturnZero

IvInterrupt_GetText:
	pushw IvInterrupt_GetText_Str_IntT@hi16
	pushw IvInterrupt_GetText_Str_IntT@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvInterrupt_ReturnZero:
	ld xhl, 0:i3
	jr ReminderProc_Return

IvInterrupt_GetInterval:
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld hl, (xhl + 22)
	extz xhl
	jr ReminderProc_Return

IvInterrupt_CheckActive:
	ld xwa, (xsp + 8)
	ld xbc, EVT_GET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent
	cp hl, 0:i3
	scc16 z, hl
	extz xhl

ReminderProc_Return:
	pop xiz
	inc 8, xsp
	ret

IvIntReminderProc:
	cp xbc, EVT_GET_INTERRUPT_TIME
	jr z, IvIntReminder_GetInterval
	cp xbc, EVT_GET_STRING
	jrl nz, IvInterruptProc
	pushw IvIntReminderProc_Str_iRem@hi16
	pushw IvIntReminderProc_Str_iRem@lo16
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	ret

IvIntReminder_GetInterval:
	ld xhl, 0:i3
	ld l, (0x0340e6:24)
	ret

IvIntCompleteProc:
	cp xbc, EVT_GET_INTERRUPT_TIME
	jr z, IvIntComplete_GetInterval
	cp xbc, EVT_GET_STRING
	jrl nz, IvInterruptProc
	pushw IvIntCompleteProc_Str_iCmp@hi16
	pushw IvIntCompleteProc_Str_iCmp@lo16
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	ret

IvIntComplete_GetInterval:
	ld xhl, 0:i3
	ld l, (0x0340e8:24)
	ret

IvIntErrorProc:
	cp xbc, EVT_GET_INTERRUPT_TIME
	jr z, IvIntError_GetInterval
	cp xbc, EVT_GET_STRING
	jrl nz, IvInterruptProc
	pushw IvIntErrorProc_Str_iErr@hi16
	pushw IvIntErrorProc_Str_iErr@lo16
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	ret

IvIntError_GetInterval:
	ld xhl, 0:i3
	ld l, (0x0340ec:24)
	ret

IvIntVariProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_GET_INTERRUPT_TIME
	jr z, IvIntVari_GetInterval
	cp xiz, EVT_GET_STRING
	jr z, IvIntVari_GetText
	cp xiz, EVT_HIDE
	jr z, IvIntVari_Close
	cp xiz, EVT_SHOW
	jr z, IvIntVari_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr IvIntVari_Return

IvIntVari_Init:
	ld wa, 1:i3
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvIntVari_ForwardToInterrupt

IvIntVari_Close:
	ld wa, 0:i3
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvIntVari_ForwardToInterrupt:
	calr IvInterruptProc
	jr IvIntVari_ReturnZero

IvIntVari_GetText:
	pushw IvIntVari_GetText_Str_iVar@hi16
	pushw IvIntVari_GetText_Str_iVar@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvIntVari_ReturnZero:
	ld xhl, 0:i3
	jr IvIntVari_Return

IvIntVari_GetInterval:
	ld xhl, 0:i3
	ld l, (0x0340ee:24)

IvIntVari_Return:
	pop xiz
	inc 8, xsp
	ret

IvIntEasySetProc:
	cp xbc, EVT_GET_INTERRUPT_TIME
	jr z, IvIntEasySet_GetInterval
	cp xbc, EVT_GET_STRING
	jrl nz, IvInterruptProc
	pushw IvIntEasySetProc_Str_iEsy@hi16
	pushw IvIntEasySetProc_Str_iEsy@lo16
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	ret

IvIntEasySet_GetInterval:
	ld xhl, 0:i3
	ld l, (0x0340f0:24)
	ret

IvIntWelcomeProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_GET_INTERRUPT_TIME
	jr z, IvIntWelcome_ReturnOne
	cp xiz, EVT_GET_STRING
	jr z, IvIntWelcome_GetText
	cp xiz, EVT_HIDE
	jr z, IvIntWelcome_Close
	cp xiz, EVT_SHOW
	jr z, IvIntWelcome_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr IvIntWelcome_Return

IvIntWelcome_Init:
	ld wa, 1:i3
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvIntWelcome_ForwardToInterrupt

IvIntWelcome_Close:
	ld wa, 0:i3
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvIntWelcome_ForwardToInterrupt:
	calr IvInterruptProc
	jr IvIntWelcome_ReturnZero

IvIntWelcome_GetText:
	pushw IvIntWelcome_GetText_Str_iVar@hi16
	pushw IvIntWelcome_GetText_Str_iVar@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvIntWelcome_ReturnZero:
	ld xhl, 0:i3
	jr IvIntWelcome_Return

IvIntWelcome_ReturnOne:
	ld xhl, 1:i3

IvIntWelcome_Return:
	pop xiz
	inc 8, xsp
	ret

IvShowHideProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, EVT_REPAINT
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, EVT_PAINT
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, EVT_HIDE
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, EVT_SHOW
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, EVT_DRAW
	jr nz, IvShowHide_Default
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, IvShowHideProc_Str_Show
	call SendEvent
	jr IvShowHide_ReturnZero

IvShowHide_ProcessSpecialEvent:
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call ApFuncCall
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

IvShowHide_ReturnZero:
	ld xhl, 0:i3
	jr IvShowHide_Return

IvShowHide_Default:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

IvShowHide_Return:
	pop xiz
	inc 8, xsp
	ret

AcSoundNameProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_SOUND_NAME
	jrl z, AcSoundName_VolumeChange
	cp xbc, EVT_PART_SELECT
	jrl z, AcSoundName_ResetPart
	cp xbc, EVT_LSW_DATA
	jr z, AcSoundName_PartChange
	cp xbc, EVT_REPAINT
	jr z, AcSoundName_ShowHide
	cp xbc, EVT_PAINT
	jr z, AcSoundName_ShowHide
	cp xbc, EVT_HIDE
	jr z, AcSoundName_Close
	cp xbc, EVT_SHOW
	jrl nz, AcSoundName_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	jr AcSoundName_ForwardParaBox

AcSoundName_Close:
	ld xwa, xiz
	ld xde, (xsp + 4)

AcSoundName_ForwardParaBox:
	calr PsParaBoxProc
	jrl AcRhythm_ReturnZeroJmp

AcSoundName_ShowHide:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xff
	jr z, AcSoundName_ShowHide_DefaultPart
	ld de, (xwa)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	jrl AcRhythm_SendPartEvent

AcSoundName_ShowHide_DefaultPart:
	call GetPartSelect
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	ld xde, xhl
	jrl AcRhythm_SendPartEvent

AcSoundName_PartChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xff
	jr z, AcSoundName_PartChange_DefaultPart
	ld de, (xwa)
	extz xde
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 4)
	cp xhl, (xwa)
	jr z, AcSoundName_PartChange_SendEvent
	add xbc, 0x8020
	cp xbc, (xwa)
	jrl nz, AcRhythm_ReturnZeroJmp

AcSoundName_PartChange_SendEvent:
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	jr AcRhythm_SendPartEvent

AcSoundName_PartChange_DefaultPart:
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8000
	ld xwa, (xsp + 4)
	cp (xwa), xhl
	jr z, AcSoundName_PartChange_DefaultSend
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8020
	ld xwa, (xsp + 4)
	cp (xwa), xhl
	jrl nz, AcRhythm_ReturnZeroJmp

AcSoundName_PartChange_DefaultSend:
	call GetPartSelect
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	ld xde, xhl
	jr AcRhythm_SendPartEvent

AcSoundName_ResetPart:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	cpw (xhl + 36), 0xff
	jr nz, AcRhythm_ReturnZeroJmp
	call GetPartSelect
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	ld xde, xhl

AcRhythm_SendPartEvent:
	call FuncCall
	jr AcRhythm_ReturnZeroJmp

AcSoundName_VolumeChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 36)
	cpw (xbc), 0xff
	jr z, AcSoundName_VolumeChange_DefaultPart
	ld xde, (xsp + 4)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, AcRhythm_ReturnZeroJmp
	ld xde, (xde + 2)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	jr AcSoundName_VolumeChange_SendConfirm

AcSoundName_VolumeChange_DefaultPart:
	call GetPartSelect
	ld xwa, (xsp + 4)
	cp (xwa), hl
	jr nz, AcRhythm_ReturnZeroJmp
	ld xde, (xwa + 2)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW

AcSoundName_VolumeChange_SendConfirm:
	call SendEvent

AcRhythm_ReturnZeroJmp:
	ld xhl, 0:i3
	jr AcSoundName_Return

AcSoundName_Default:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc

AcSoundName_Return:
	pop xiz
	inc 4, xsp
	ret

AcRhythmNameProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_RHYTHM_NAME
	jrl z, AcRhythmName_Confirm
	cp xbc, EVT_LSW_DATA
	jr z, AcRhythmName_PartChange
	cp xbc, EVT_REPAINT
	jr z, AcRhythmName_ShowHide
	cp xbc, EVT_PAINT
	jr z, AcRhythmName_ShowHide
	cp xbc, EVT_HIDE
	jr z, AcRhythmName_Close
	cp xbc, EVT_SHOW
	jr nz, AcRhythmName_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	jr AcRhythmName_ForwardParaBox

AcRhythmName_Close:
	ld xwa, xiz
	ld xde, (xsp + 4)

AcRhythmName_ForwardParaBox:
	calr PsParaBoxProc
	jr PsParaBox_ZeroReturn

AcRhythmName_ShowHide:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, NAKA_MAINFUNC_MainGetRhythmName
	ld xbc, EVT_GET_RHYTHM_NAME
	ld xde, 0:i3
	jr AcRhythmName_CallMainFunc

AcRhythmName_PartChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	cp xwa, 0x28000
	jr z, AcRhythmName_PartChange_Send
	ld xwa, (xbc)
	cp xwa, 0x28001
	jr nz, PsParaBox_ZeroReturn

AcRhythmName_PartChange_Send:
	ld xwa, NAKA_MAINFUNC_MainGetRhythmName
	ld xbc, EVT_GET_RHYTHM_NAME
	ld xde, 0:i3

AcRhythmName_CallMainFunc:
	call FuncCall
	jr PsParaBox_ZeroReturn

AcRhythmName_Confirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, (xsp + 4)
	call SendEvent

PsParaBox_ZeroReturn:
	ld xhl, 0:i3
	jr AcRhythmName_Return

AcRhythmName_Default:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc

AcRhythmName_Return:
	pop xiz
	inc 4, xsp
	ret

AcPmemNameProc:
	lda xsp, (xsp - 44)
	push xiz
	ld xiz, xde
	ld (xsp + 44), xwa
	cp xbc, EVT_PMEM_NAME
	jr z, AcPmemName_Confirm
	cp xbc, EVT_LSW_DATA
	jr z, AcPmemName_PartChange
	cp xbc, EVT_REPAINT
	jr z, AcPmemName_ShowHide
	cp xbc, EVT_PAINT
	jr z, AcPmemName_ShowHide
	cp xbc, EVT_HIDE
	jr z, AcPmemName_Close
	cp xbc, EVT_SHOW
	jrl nz, AcPmemName_Default
	ld xwa, (xsp + 44)
	ld xde, xiz
	jr AcPmemName_ForwardParaBox

AcPmemName_Close:
	ld xwa, (xsp + 44)
	ld xde, xiz

AcPmemName_ForwardParaBox:
	calr PsParaBoxProc
	jrl PsParaBox_EventReturn

AcPmemName_ShowHide:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, NAKA_MAINFUNC_MainGetPmemName
	ld xbc, EVT_GET_PMEM_NAME
	ld xde, 0:i3
	jr AcPmemName_CallMainFunc

AcPmemName_PartChange:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, (xiz)
	cp xwa, 0x300
	jrl nz, PsParaBox_EventReturn
	ld xwa, NAKA_MAINFUNC_MainGetPmemName
	ld xbc, EVT_GET_PMEM_NAME
	ld xde, 0:i3

AcPmemName_CallMainFunc:
	call MainFuncCall
	jrl PsParaBox_EventReturn

AcPmemName_Confirm:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	lda xbc, (xiz + 2)
	ld wa, (xbc)
	dec 1, wa
	srl wa, 3
	inc 1, wa
	ld w, a
	lda xde, (xiz + 4)
	ld xiy, (xde)
	ld l, w
	extz hl
	lda xix, (xsp + 4)
	cp (xiy), 0x0
	jr z, AcPmemName_Confirm_EmptySlot
	cpw (xiz), 0x0
	jr z, AcPmemName_Confirm_ZeroIndex
	sll w, 3
	dec 8, w
	ld a, w
	extz wa
	ld bc, (xbc)
	sub bc, wa
	ld xwa, (xde)
	push xwa
	extz bc
	pushw bc
	pushw hl
	pushw AcPmemName_Confirm_Str_PMEM_Fmt2d_Fmtd_Fmt16s@hi16
	pushw AcPmemName_Confirm_Str_PMEM_Fmt2d_Fmtd_Fmt16s@lo16
	push xix
	call Sprintf_Locked
	lda xsp, (xsp + 16)
	jr AcPmemName_Confirm_SendEvent

AcPmemName_Confirm_ZeroIndex:
	ld xwa, (xde)
	push xwa
	pushw hl
	pushw AcPmemName_Confirm_ZeroIndex_Str_PMEM_Fmt2d_Fmt16s@hi16
	pushw AcPmemName_Confirm_ZeroIndex_Str_PMEM_Fmt2d_Fmt16s@lo16
	push xix
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jr AcPmemName_Confirm_SendEvent

AcPmemName_Confirm_EmptySlot:
	pushw hl
	pushw AcPmemName_Confirm_EmptySlot_Str_PMEM_Fmt2d@hi16
	pushw AcPmemName_Confirm_EmptySlot_Str_PMEM_Fmt2d@lo16
	push xix
	call Sprintf_Locked
	lda xsp, (xsp + 10)

AcPmemName_Confirm_SendEvent:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 44)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsParaBox_EventReturn:
	ld xhl, 0:i3
	jr AcPmemName_Return

AcPmemName_Default:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc

AcPmemName_Return:
	pop xiz
	lda xsp, (xsp + 44)
	ret

AcMixerVolProc:
	lda xsp, (xsp - 44)
	push xiz
	ld (xsp + 36), xde
	ld (xsp + 40), xbc
	ld (xsp + 44), xwa
	ld xwa, (xsp + 40)
	cp xwa, EVT_GET_SOUND_SW_NO
	jrl z, AcMixerVol_EncoderUpdate
	cp xwa, EVT_SW_BOTH
	jrl z, AcMixerVol_Reset
	cp xwa, EVT_SW_IN_AIC
	jrl z, AcMixerVol_FastScroll
	cp xwa, EVT_SW_IN
	jrl z, AcMixerVol_OK
	cp xwa, EVT_LSW_DATA
	jrl z, AcMixerVol_ValueChange
	cp xwa, EVT_SOUND_SW_NO
	jrl z, AcMixerVol_PartSelect
	cp xwa, EVT_PARA_DRAW
	jrl z, AcMixerVol_Confirm
	cp xwa, EVT_DRAW
	jr z, AcMixerVol_Paint
	cp xwa, EVT_REPAINT
	jr z, AcMixerVol_ShowHide
	cp xwa, EVT_PAINT
	jr z, AcMixerVol_ShowHide
	cp xwa, EVT_HIDE
	jr z, AcMixerVol_Close
	cp xwa, EVT_SHOW
	jrl nz, AcMixerVol_DefaultForward
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr AcMixerVol_ForwardVwBox

AcMixerVol_Close:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr AcMixerVol_ForwardVwBox

AcMixerVol_ShowHide:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)

AcMixerVol_ForwardVwBox:
	calr VwBoxProc
	jrl UIList_ReturnZeroJmp

AcMixerVol_Paint:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	calr VwBoxProc
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 44)
	call GetClientBox
	lda xwa, (xsp + 24)
	lda xde, (xwa + 4)
	ld bc, (xde)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xix, (xsp + 32)
	ld (xix), hl
	lda xhl, (xwa + 6)
	ld bc, (xhl)
	dec 5, bc
	ld (xix + 2), bc
	ld bc, (xhl)
	sub bc, 0x9
	ld (xwa + 2), bc
	incw 3, (xwa)
	decw	3, (xde)
	decw	1, (xhl)
	ldw bc, 0x8
	call DrawBox
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 32)
	ld xde, (xsp + 8)
	ld de, (xde + 28)
	extz xde
	sll xde, 2
	ld xhl, AcMixerVol_Paint_PtrTable
	add xhl, xde
	ld xde, (xhl)
	ld xhl, 3:i3
	push xhl
	pushw 0xff
	pushw 0x8
	call DrawStringCentered
	ld xwa, (xsp + 44)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld de, (xwa + 28)
	extz xde
	ld xwa, (xsp + 44)
	ld xbc, EVT_GET_SOUND_SW_NO
	jrl UIList_SendEvent

AcMixerVol_Confirm:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	calr VwBoxProc
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld wa, (xwa + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, Str_No_0x1F6
	add xwa, xbc
	ld xwa, (xwa)
	call SndParam_LookupReadOnly
	ld (xsp + 4), hl
	ld xwa, (xsp + 8)
	ld wa, (xwa + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	lda xwa, (Str_No_0x1FA:24)
	add xwa, xbc
	ld xwa, (xwa)
	call SndParam_LookupReadOnly
	ld (xsp + 6), hl
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 44)
	call GetClientBox
	lda xde, (xsp + 24)
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld hl, (xde)
	add hl, wa
	lda xbc, (xsp + 32)
	ld (xbc), hl
	ld wa, (xde + 2)
	inc 4, wa
	ld (xbc + 2), wa
	pushw	(xsp+4)
	pushw AcMixerVol_Confirm_Str_Fmt3d@hi16
	pushw AcMixerVol_Confirm_Str_Fmt3d@lo16
	lda xwa, (xsp + 24)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 32)
	lda xde, (xsp + 18)
	ld xhl, 3:i3
	push xhl
	pushw 0x0
	ld xhl, (xsp + 14)
	pushw	(xhl+22)
	call DrawStringCentered
	lda xwa, (xsp + 32)
	lda xde, (xsp + 24)
	ld bc, (xde)
	inc 4, bc
	ld (xwa), bc
	ld bc, (xde + 2)
	add bc, 0xa
	ld (xwa + 2), bc
	ld xbc, 2:i3
	call DrawBitmapFast
	lda xwa, (xsp + 32)
	ldw bc, 0x80
	sub bc, (xsp + 4)
	muls bc, 0x24
	exts xbc
	divs bc, 0x80
	add (xwa + 2), bc
	ld xbc, 3:i3
	call DrawBitmapFast
	cpw (xsp + 6), 0x1
	jrl nz, UIList_ReturnZeroJmp
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 44)
	call GetClientBox
	lda xbc, (xsp + 32)
	lda xwa, (xsp + 24)
	ld de, (xwa)
	add de, 0x11
	ld (xbc), de
	ld de, (xwa + 2)
	add de, 0x1f
	ld (xbc + 2), de
	ld de, (xbc)
	sub de, 0xc
	ld (xwa), de
	ld de, (xbc)
	add de, 0xc
	ld (xwa + 4), de
	addiw_da (xwa + 6), 0x12
	ld xde, 3:i3
	push xde
	pushw 0xfb
	pushw 0x0
	pushw 0x0
	pushw 0x1
	ld xde, AcMixerVol_Confirm_Str_MUTE
	call DrawStringReverse
	jrl UIList_ReturnZeroJmp

AcMixerVol_PartSelect:
	ld xwa, (xsp + 44)
	call GetViewInstance
	lda xbc, (xhl + 28)
	ld xwa, (xsp + 36)
	cp wa, (xbc)
	jrl nz, UIList_ReturnZeroJmp
	ld wa, (xbc)
	cp wa, 0x1b
	jr nz, AcMixerVol_PartSelect_Ch1A
	ldw (xsp + 10), 0x13
	jr AcMixerVol_PartSelect_DrawIcon

AcMixerVol_PartSelect_Ch1A:
	cp wa, 0x1a
	jr nz, AcMixerVol_PartSelect_Default
	ldw (xsp + 10), 0x12
	jr AcMixerVol_PartSelect_DrawIcon

AcMixerVol_PartSelect_Default:
	ld xwa, (xsp + 36)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	srl wa, 8
	ld w, 0x0:opc
	and a, 0x1f
	extz wa
	ld (xsp + 10), wa

AcMixerVol_PartSelect_DrawIcon:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 44)
	call GetClientBox
	lda xwa, (xsp + 32)
	lda xde, (xsp + 24)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde + 2)
	add bc, 0x3d
	ld (xwa + 2), bc
	ld bc, (xsp + 10)
	sla bc, 2
	lda xde, (Str_No_0x30E:24)
	ld	xbc, (xde+bc)
	call DrawBitmapFast
	jrl UIList_ReturnZeroJmp

AcMixerVol_ValueChange:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	calr VwBoxProc
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld de, (xhl + 28)
	extz xde
	ld xwa, xde
	sll xwa, 2
	add xwa, xde
	add xwa, xwa
	ld xbc, Str_No_0x1F6
	add xbc, xwa
	ld xhl, (xsp + 36)
	ld xwa, (xhl)
	cp xwa, (xbc)
	jr z, AcMixerVol_ValueChange_Match
	ld xwa, (xhl)
	cp xwa, (xbc + 4)
	jr nz, AcMixerVol_ValueChange_CheckAddr

AcMixerVol_ValueChange_Match:
	ld xwa, (xsp + 44)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl UIList_SendEvent

AcMixerVol_ValueChange_CheckAddr:
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 36)
	cp xhl, (xwa)
	jr z, AcMixerVol_ValueChange_SendUpdate
	add xbc, 0x8020
	cp xbc, (xwa)
	jrl nz, UIList_ReturnZeroJmp

AcMixerVol_ValueChange_SendUpdate:
	ld xwa, (xsp + 44)
	ld xbc, EVT_GET_SOUND_SW_NO
	jrl UIList_SendEvent

AcMixerVol_OK:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 36)
	call SendEvent
	ld xbc, (xsp + 8)
	ld wa, (xbc + 30)
	extz xwa
	cp xwa, xhl
	jrl nz, AcMixerVol_OK_Fallthrough
	ld wa, (xbc + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	lda xwa, (Str_No_0x1FA:24)
	add xwa, xbc
	ld xwa, (xwa)
	call SndParam_LookupReadOnly
	ld (xsp + 6), hl
	ld xwa, (xsp + 8)
	lda xwa, (xwa + 28)
	cpw (xsp + 6), 0x0
	jr z, AcMixerVol_OK_Mute
	ld bc, (xwa)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, Str_No_0x1F6
	add xbc, xwa
	ld xwa, (xbc + 4)
	ld de, (xbc + 8)
	ld bc, 0:i3
	calr MainLswPut
	ld xwa, (xsp + 44)
	ld xbc, EVT_SW_IN_AIC
	ld xde, (xsp + 36)
	jr AcMixerVol_OK_SetAutoInc

AcMixerVol_OK_Mute:
	ld bc, (xwa)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, Str_No_0x1F6
	add xbc, xwa
	ld de, (xbc + 8)
	ld xwa, (xsp + 36)
	bit 7, wa
	jr z, AcMixerVol_OK_Increment
	ld xwa, (xbc)
	ldw bc, 0xffff
	jr AcMixerVol_OK_ApplyDelta

AcMixerVol_OK_Increment:
	ld xwa, (xbc)
	ld bc, 1:i3

AcMixerVol_OK_ApplyDelta:
	calr MainLswAdd
	ld xwa, (xsp + 44)
	ld xbc, EVT_SW_IN_AIC
	ld xde, (xsp + 36)

AcMixerVol_OK_SetAutoInc:
	call SetAutoInc
	jrl UIList_ReturnZeroJmp

AcMixerVol_OK_Fallthrough:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jrl UIList_VwBoxCall

AcMixerVol_FastScroll:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 36)
	call SendEvent
	ld wa, (xiz + 30)
	extz xwa
	cp xwa, xhl
	jr nz, AcMixerVol_FastScroll_Fallthrough
	ld wa, (xiz + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 36)
	bit 7, wa
	jr z, AcMixerVol_FastScroll_Increment
	ld xde, Str_No_0x1F6
	add xde, xbc
	ld xwa, (xde)
	ld de, (xde + 8)
	ldw bc, 0xfffc
	jr AcMixerVol_FastScroll_Apply

AcMixerVol_FastScroll_Increment:
	ld xde, Str_No_0x1F6
	add xde, xbc
	ld xwa, (xde)
	ld de, (xde + 8)
	ld bc, 4:i3

AcMixerVol_FastScroll_Apply:
	calr MainLswAdd
	jrl UIList_ReturnZeroJmp

AcMixerVol_FastScroll_Fallthrough:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jrl UIList_VwBoxCall

AcMixerVol_Reset:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 36)
	call SendEvent
	ld xwa, (xsp + 8)
	ld wa, (xwa + 30)
	extz xwa
	cp xwa, xhl
	jr nz, AcMixerVol_Reset_Fallthrough
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	ld xde, (xsp + 36)
	call SendEvent
	ld xde, (xsp + 36)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call SendEvent
	ld xwa, (xsp + 8)
	ld bc, (xwa + 28)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, Str_No_0x1F6
	add xbc, xwa
	ld xwa, (xbc + 4)
	ld de, (xbc + 8)
	ld bc, 1:i3
	calr MainLswPut

AcMixerVol_Reset_Fallthrough:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr UIList_VwBoxCall

AcMixerVol_EncoderUpdate:
	ld xwa, (xsp + 36)
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 15), l
	ld xwa, (xsp + 36)
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 12)
	ld (xwa + 4), l
	ld xbc, (xsp + 36)
	ld (xwa + 2), c
	call SndParam_FetchOscTableEntry
	lda xbc, (xsp + 12)
	ld e, (xbc + 1)
	extz de
	ld a, (xbc)
	extz wa
	sll wa, 8
	add wa, de
	ld bc, wa
	extz xbc
	sll xbc, 16
	ld xwa, (xsp + 36)
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, (xsp + 44)
	ld xbc, EVT_SOUND_SW_NO

UIList_SendEvent:
	call SendEvent

UIList_ReturnZeroJmp:
	ld xhl, 0:i3
	jr AcMixerVol_Return

AcMixerVol_DefaultForward:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)

UIList_VwBoxCall:
	calr VwBoxProc

AcMixerVol_Return:
	pop xiz
	lda xsp, (xsp + 44)
	ret

ScrollDelta_ComputeDirection:
	ld	hl, de
	cp	xwa, EVT_SW_IN_AIC
	jr	z, IvInterruptProc_Skip
	cp	xwa, EVT_SW_IN
	jr	nz, IvInterruptProc_Skip3
	ld	hl, (xsp+4)
	bit	7, bc
	jr	nz, IvInterruptProc_Skip2
	jr	IvInterruptProc_Return
IvInterruptProc_Skip:
	bit	7, bc
	jr	z, IvInterruptProc_Return
IvInterruptProc_Skip2:
	mul	hl, 0xffff
	jr	IvInterruptProc_Return
IvInterruptProc_Skip3:
	ld	hl, 0:i3
IvInterruptProc_Return:
	retd	2

DbMemoProc:
	lda xsp, (xsp - 106)
	push xiz
	ld (xsp + 102), xde
	ld (xsp + 106), xwa
	cp xbc, EVT_MEMO_DRAW
	jr z, DbMemo_DrawContent
	cp xbc, EVT_DRAW
	jr z, DbMemo_Paint
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	jr DbMemo_Return

DbMemo_Paint:
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	ld xwa, (xsp + 106)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 14)
	ldw bc, 0xc5
	ld de, 7:i3
	call DrawDesignBox
	lda xiy, (xiz + 14)
	lda xix, (xsp + 94)
	ld bc, 4:i3
	ldirw
	lda xwa, (xsp + 94)
	incw 4, (xwa + 2)
	incw 4, (xwa)
	decw	4, (xwa+4)
	decw	4, (xwa+6)
	ldw bc, 0xc6
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xsp + 106)
	ld xbc, EVT_MEMO_DRAW
	ld xde, DbMemo_Paint_Str_Debug_Time
	call SendEvent

DbMemo_ReturnZero:
	ld xhl, 0:i3

DbMemo_Return:
	pop xiz
	lda xsp, (xsp + 106)
	ret

DbMemo_DrawContent:
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	ld xwa, (xsp + 106)
	call GetViewInstance
	lda xiy, (xhl + 14)
	lda xix, (xsp + 94)
	ld bc, 4:i3
	ldirw
	lda xhl, (xsp + 94)
	lda xde, (xhl + 2)
	incw 5, (xde)
	incw 5, (xhl)
	lda xwa, (xhl + 4)
	decw	5, (xwa)
	lda xbc, (xhl + 6)
	decw	5, (xbc)
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x6
	ld (xsp + 4), wa
	lda xix, (xsp + 74)
	ld wa, (xhl)
	ld (xix), wa
	ld wa, (xbc)
	dec 8, wa
	ld (xix + 2), wa
	lda xiy, (xsp + 94)
	lda xix, (xsp + 86)
	ld bc, 4:i3
	ldirw
	incw 8, (xsp + 88)
	lda xiy, (xsp + 94)
	lda xix, (xsp + 78)
	ld bc, 4:i3
	ldirw
	lda xbc, (xsp + 78)
	ld wa, (xbc + 6)
	dec 8, wa
	ld (xbc + 2), wa
	lda xbc, (xsp + 70)
	ld wa, (xhl)
	ld (xbc), wa
	ld wa, (xde)
	ld (xbc + 2), wa
	ld xwa, (xsp + 102)
	ld (xsp + 6), xwa

DbMemo_DrawContent_Loop:
	lda xwa, (xsp + 86)
	lda xbc, (xsp + 70)
	call MovePixels
	lda xwa, (xsp + 78)
	ld bc, 7:i3
	call DrawBox
	pushw	(xsp+4)
	ld xwa, (xsp + 8)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 4)
	extz xwa
	lda xde, (xsp + 10)
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	lda xwa, (xsp + 94)
	lda xbc, (xsp + 74)
	ld xhl, 3:i3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	lda xwa, (xsp + 10)
	push xwa
	call Strlen
	inc 4, xsp
	cp hl, (xsp + 4)
	jrl nz, DbMemo_ReturnZero
	ld wa, (xsp + 4)
	extz xwa
	add (xsp + 6), xwa
	jr DbMemo_DrawContent_Loop
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	ld xiz, xhl
	ld xwa, (xsp + 10)
	push xwa
	push xiz
	call Strcpy
	lda xsp, (xsp + 14)
	ld xwa, 0xffffffff
	ld xbc, EVT_MEMO_DRAW
	ld xde, xiz
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	call PostEvent
	pop xiz
	inc 4, xsp
	ret

; DbMemo_LoneRet -- a single `ret` instruction (was named DbMemo_TrailingData);
; no caller was found (see scripts/renaming/uiproc_misc_names.py).
DbMemo_LoneRet:
	ret

DbMemoryDumpProc:
	lda xsp, (xsp - 120)
	push xiz
	ld (xsp + 112), xde
	ld (xsp + 116), xbc
	ld (xsp + 120), xwa
	ld xwa, (xsp + 116)
	cp xwa, EVT_SW_IN
	jrl z, DbMemDump_OK
	cp xwa, EVT_PARA_DRAW
	jrl z, DbMemDump_Confirm
	cp xwa, EVT_SELE_DRAW
	jrl z, DbMemDump_Select
	cp xwa, EVT_DRAW
	jr z, DbMemDump_Paint
	cp xwa, EVT_HIDE
	jr z, DbMemDump_Close
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	jrl DbMemDump_DefaultProc

DbMemDump_Close:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call ViewableProc
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_Paint:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call ViewableProc
	ld xwa, (xsp + 120)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 14)
	ldw bc, 0xc5
	ld de, 7:i3
	call DrawDesignBox
	lda xiy, (xiz + 14)
	lda xix, (xsp + 104)
	ld bc, 4:i3
	ldirw
	lda xwa, (xsp + 104)
	incw 4, (xwa + 2)
	incw 4, (xwa)
	decw	4, (xwa+4)
	decw	4, (xwa+6)
	ldw bc, 0xc6
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xsp + 120)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_Select:
	ld xwa, (xsp + 120)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, EVT_SELE_DRAW
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0x78
	ld	xbc, (xsp+128)
	ld	xde, (xsp+128)
	call SetApTimer
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_Confirm:
	ld xwa, (xsp + 120)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	lda xiy, (xwa + 14)
	lda xix, (xsp + 104)
	ld bc, 4:i3
	ldirw
	lda xwa, (xsp + 104)
	incw 5, (xwa + 2)
	incw 5, (xwa)
	decw	5, (xwa+4)
	decw	5, (xwa+6)
	ldw (xsp + 4), 0x0

DbMemDump_Confirm_RowLoop:
	ld bc, (xsp + 4)
	mul bc, 0x9
	lda xwa, (xsp + 104)
	ld de, (xwa + 2)
	add de, bc
	inc 1, de
	lda xbc, (xsp + 100)
	ld (xbc + 2), de
	ld wa, (xwa)
	ld (xbc), wa
	ld xwa, (xsp + 6)
	ld xbc, (xwa + 22)
	ld wa, (xsp + 4)
	sll wa, 3
	extz xwa
	ld xiz, xwa
	add xiz, (xbc)
	pushw 0x8
	push xiz
	lda xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ld wa, iz
	pushw wa
	ld xwa, xiz
	srl xwa, 16
	pushw wa
	pushw DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt4X@hi16
	pushw DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt4X@lo16
	lda xwa, (xsp + 38)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 22)
	lda xwa, (xsp + 104)
	lda xbc, (xsp + 100)
	lda xde, (xsp + 20)
	ld xhl, 3:i3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	lda xbc, (xsp + 10)
	ld a, (xbc + 7)
	extz wa
	pushw wa
	ld a, (xbc + 6)
	extz wa
	pushw wa
	ld a, (xbc + 5)
	extz wa
	pushw wa
	ld a, (xbc + 4)
	extz wa
	pushw wa
	ld a, (xbc + 3)
	extz wa
	pushw wa
	ld a, (xbc + 2)
	extz wa
	pushw wa
	ld a, (xbc + 1)
	extz wa
	pushw wa
	ld a, (xbc)
	extz wa
	pushw wa
	pushw DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt2X_Fmt2X_Fmt2X_Fmt2X@hi16
	pushw DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt2X_Fmt2X_Fmt2X_Fmt2X@lo16
	lda xwa, (xsp + 40)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 100)
	addiw_da (xbc), 0x30
	lda xwa, (xsp + 104)
	lda xde, (xsp + 20)
	ld xhl, 3:i3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	lda xde, (xsp + 10)
	ld xwa, xde
	lda xbc, (xde + 8)

DbMemDump_Confirm_SanitizeLoop:
	cp (xwa), 0x20
	jr nc, DbMemDump_Confirm_SanitizeNext
	ld (xwa), 0x2e

DbMemDump_Confirm_SanitizeNext:
	inc 1, xwa
	cp xwa, xbc
	jr c, DbMemDump_Confirm_SanitizeLoop
	ld (xde + 8), 0x0
	lda xbc, (xsp + 100)
	addiw_da (xbc), 0x96
	lda xwa, (xsp + 104)
	ld xhl, 3:i3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x10
	jrl c, DbMemDump_Confirm_RowLoop
	jrl UI_NameCapture_ReturnSuccess

; DbMemDump_StepTable -- the memory-dump debugger's step-size table.  Six u32
; entries at Str_No + 0x3E4 (v10: 0xEAA6FA), the hex-digit weights
; 0x100000, 0x10000, 0x1000, 0x100, 0x10, 0x1, indexed 0..5 by the
; `cp xwa, 0x5` / `sll xwa, 2` below.  Not a string.  It is a label of its own
; in the Str_No run (disk_warning_strings.s) since 2026-10-02, when the run
; was cut at every address code reaches; it was a `.set` alias before.
DbMemDump_OK:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 112)
	call SendEvent
	ld xwa, xhl
	cp xhl, 0x10
	jr z, DbMemDump_OK_PageSize
	dec 2, xwa
	cp xwa, 0x0
	jr c, DbMemDump_OK_DefaultFallthrough
	cp xwa, 0x5
	jr ugt, DbMemDump_OK_DefaultFallthrough
	sll xwa, 2
	add xwa, DbMemDump_StepTable
	ld xwa, (xwa)
	ld xiz, xwa

DbMemDump_OK_AdjustAddr:
	ld xwa, (xsp + 120)
	call GetViewInstance
	lda xde, (xhl + 22)
	ld xbc, (xde)
	ld xwa, (xsp + 112)
	bit 7, wa
	jr z, DbMemDump_OK_AddOffset
	sub (xbc), xiz
	jr DbMemDump_OK_ClampAndConfirm

DbMemDump_OK_PageSize:
	ld xiz, 0x80
	jr DbMemDump_OK_AdjustAddr

DbMemDump_OK_DefaultFallthrough:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)

DbMemDump_DefaultProc:
	call ViewableProc
	jr DbMemDump_Return

DbMemDump_OK_AddOffset:
	add (xbc), xiz

DbMemDump_OK_ClampAndConfirm:
	ld xbc, (xde)
	ld xwa, NakaData_RomEnd
	and (xbc), xwa
	ld xwa, (xsp + 120)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call SetAutoInc

UI_NameCapture_ReturnSuccess:
	ld xhl, 0:i3

DbMemDump_Return:
	pop xiz
	lda xsp, (xsp + 120)
	ret

CaptureLcdCheck:
	cp xbc, EVT_SW_IN
	call z, (CaptureLcd:24)
	ld xhl, 0:i3
	ret

PsCursorBoxProc:
	lda xsp, (xsp-554)
	push xiz
	ld	(xsp+554), xde
	ld xiz, xwa
	cp xbc, EVT_SET_CURSOR
	jrl z, PsCursorBox_SetCursor
	cp xbc, EVT_PARA_DRAW
	jr z, PsCursorBox_Confirm
	cp xbc, EVT_SELE_DRAW
	jr z, PsCursorBox_Select
	cp xbc, EVT_SHOW
	jr z, PsCursorBox_Init
	ld xwa, xiz
	ld XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	jrl PsCursorBox_Return

PsCursorBox_Init:
	ld xwa, xiz
	ld XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 36)
	ldw (xwa), 0xffff
	jrl ScrollBox_ReturnZero

PsCursorBox_Select:
	ld xwa, xiz
	ld XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp	xbc, (xsp+554)
	jrl z, ScrollBox_ReturnZero
	jrl PsCursorBox_StoreCursor

PsCursorBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 14), xhl
	lda xde, (xsp+274)
	ld XWA, (xsp + 0x022a)
	or xwa, xwa
	jr nz, PsCursorBox_Confirm_CopyText
	ld xwa, xiz
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp	(xsp+274), 0x00
	jr nz, PsCursorBox_Confirm_CheckCursor
	jrl ScrollBox_ReturnZero

PsCursorBox_Confirm_CopyText:
	ld XWA, (xsp + 0x022a)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsCursorBox_Confirm_CheckCursor:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	cpw (xwa), 0xffff
	jrl z, ScrollBox_ReturnZero
	lda xbc, (xsp+546)
	ld xwa, xiz
	call GetClientBox
	lda xwa, (xsp+546)
	lda xbc, (xsp+530)
	call GetBoxCenter
	lda xiy, (xsp+546)
	lda xix, (xsp+538)
	ld bc, 4:i3
	ldirw
	ld xbc, (xsp + 14)
	ld xwa, (xbc + 28)
	ld (xsp + 6), xwa
	ld wa, (xbc + 22)
	ld (xsp + 12), wa
	ld wa, (xbc + 32)
	ld (xsp + 10), wa
	lda xwa, (xsp+274)
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	call GetCharHeight
	ld iz, hl
	ld xwa, (xsp + 6)
	call GetCharDescent
	ldfr_werp HL, 0xfa
	ld xwa, (xsp + 6)
	call GetCenteredDelta
	lda xde, (xsp+530)
	lda xbc, (xde + 2)
	ld wa, iz
	subw_erp WA, 0xfa
	ld ix, wa
	exts xix
	divs ix, 0x2
	ld wa, (xbc)
	sub wa, ix
	ld (xbc), wa
	add wa, hl
	ld (xbc), wa
	ld xwa, (xsp + 14)
	ld c, (xwa + 34)
	lda xwa, (xsp+546)
	cp c, 2:i3
	jr z, PsCursorBox_Confirm_AlignRight
	cp c, 1:i3
	jr z, PsCursorBox_Confirm_AlignLeft
	cp c, 0:i3
	jr nz, UI_ScrollBox_ComputeLayout
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub (xde), wa
	jr UI_ScrollBox_ComputeLayout

PsCursorBox_Confirm_AlignLeft:
	ld wa, (xwa)
	inc 4, wa
	ld (xde), wa
	jr UI_ScrollBox_ComputeLayout

PsCursorBox_Confirm_AlignRight:
	ld wa, (xwa + 4)
	dec 4, wa
	sub wa, (xsp + 4)
	ld (xde), wa

UI_ScrollBox_ComputeLayout:
	lda xwa, (xsp+274)
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	lda	xiz, (xbc+wa)
	ld (xiz + 1), 0x0
	ld xwa, xiz
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld (xiz), 0x0
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld	bc, (xsp+530)
	add bc, hl
	lda xwa, (xsp+538)
	ld (xwa), bc
	add bc, (xsp + 4)
	ld (xwa + 4), bc
	lda xbc, (xsp+534)
	call GetBoxCenter
	lda xwa, (xsp+274)
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	lda	xiz, (xbc+wa)
	ld (xiz + 1), 0x0
	lda xwa, (xsp+546)
	ld bc, (xsp + 12)
	call DrawBox
	lda xwa, (xsp+546)
	lda xbc, (xsp+530)
	lda xde, (xsp+274)
	ld xhl, (xsp + 6)
	push xhl
	pushw	(xsp+14)
	pushw 0xf7
	call DrawString
	lda xwa, (xsp+538)
	lda xde, (xsp+534)
	ld xbc, (xsp + 6)
	push xbc
	pushw	(xsp+14)
	pushw	(xsp+18)
	ld xbc, (xsp + 22)
	ld c, (xbc + 34)
	extz bc
	pushw bc
	pushw 0x1
	ld xbc, xde
	ld xde, xiz
	call DrawStringReverse
	jr ScrollBox_ReturnZero

PsCursorBox_SetCursor:
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)

PsCursorBox_StoreCursor:
	ld xbc, (xwa)
	ld XWA, (xsp + 0x022a)
	ld (xbc), wa

ScrollBox_ReturnZero:
	ld xhl, 0:i3

PsCursorBox_Return:
	pop xiz
	lda xsp, (xsp+554)
	ret

DbDebugMenuProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xbc
	ld xiz, xwa
	ld xwa, (xsp + 24)
	cp xwa, EVT_SW_IN
	jrl z, DbDebugMenu_OK
	cp xwa, EVT_PARA_DRAW
	jrl z, DbDebugMenu_Confirm
	cp xwa, EVT_DRAW
	jrl z, DbDebugMenu_Paint
	cp xwa, EVT_HIDE
	jr z, DbDebugMenu_Close
	cp xwa, EVT_SHOW
	jr z, DbDebugMenu_Init
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	jrl DbDebugMenu_DefaultCall

DbDebugMenu_Init:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	calr PsMenuBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda xde, (DbDebugMenu_Init_Str_N1:24)
	ld	xwa, (xde+wa)
	cp xwa, 0xffffffff
	jrl z, PsMenuBox_ZeroReturn
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld	xwa, (xde+wa)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jrl PsMenuBox_SendEvent

DbDebugMenu_Close:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda xde, (DbDebugMenu_Init_Str_N1:24)
	ld	xwa, (xde+wa)
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_Close_CallMenu
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld	xwa, (xde+wa)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent

DbDebugMenu_Close_CallMenu:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	calr PsMenuBoxProc
	jrl PsMenuBox_ZeroReturn

DbDebugMenu_Paint:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl PsMenuBox_SendEvent

DbDebugMenu_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 8)
	ld xwa, xiz
	call GetClientBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 16)
	call GetBoxCenter
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 16)
	ld xde, (xsp + 4)
	ld xde, (xde + 42)
	ld de, (xde)
	sla de, 2
	lda xhl, (DbDebugMenu_Confirm_PtrTable:24)
	ld	xde, (xhl+de)
	ld xhl, 3:i3
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawStringCentered
	jrl PsMenuBox_ZeroReturn

DbDebugMenu_OK:
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 20)
	call SendEvent
	cp hl, 0:i3
	jrl z, DbDebugMenu_OK_HitTestFail
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda xde, (DbDebugMenu_Init_Str_N1:24)
	ld	xwa, (xde+wa)
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_OK_Advance
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld	xwa, (xde+wa)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent

DbDebugMenu_OK_Advance:
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 42)
	ld xde, xwa
	ld xbc, (xwa)
	incw 1, (xbc)
	ld xbc, (xwa)
	ld wa, (xbc)
	sla wa, 2
	lda xhl, (DbDebugMenu_Confirm_PtrTable:24)
	ld	xwa, (xhl+wa)
	cp (xwa), 0x0
	jr nz, DbDebugMenu_OK_CheckValid
	ldw (xbc), 0x0

DbDebugMenu_OK_CheckValid:
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 2
	lda xbc, (DbDebugMenu_Init_Str_N1:24)
	lda	xbc, (xbc+wa)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_OK_NoHandler
	ld xwa, (xbc)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr PsMenuBox_SendEvent

DbDebugMenu_OK_NoHandler:
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jr PsMenuBox_SendEvent

DbDebugMenu_OK_HitTestFail:
	ld xwa, (xsp + 20)
	cp xwa, 0xf
	jr nz, DbDebugMenu_Default
	ld xwa, 7:i3
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3

PsMenuBox_SendEvent:
	call SendEvent

PsMenuBox_ZeroReturn:
	ld xhl, 0:i3
	jr DbDebugMenu_Return

DbDebugMenu_Default:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)

DbDebugMenu_DefaultCall:
	calr PsMenuBoxProc

DbDebugMenu_Return:
	pop xiz
	lda xsp, (xsp + 24)
	ret

PsTrackSwitchProc:
	lda xsp, (xsp-178)
	push xiz
	ld	(xsp+174), xde
	ld xde, xbc
	ld	(xsp+178), xwa
	ld xiy, PsTrackSwitchProc_PtrTable
	lda xix, (xsp + 38)
	ldw bc, 0x28
	ldirw
	ld xiy, PsTrackSwitchProc_PtrTable_2
	lda xix, (xsp + 18)
	ldw bc, 0xa
	ldirw
	ld xiy, Str_No_0x504
	lda xix, (xsp + 8)
	ld bc, 5:i3
	ldirw
	cp xde, EVT_CHECK_EDIT_SW
	jrl z, PsTrkSw_HitTest
	cp xde, EVT_SELE_DRAW
	jrl z, PsTrkSw_Select
	cp xde, EVT_PARA_DRAW
	jrl z, PsTrkSw_Confirm
	cp xde, EVT_REPAINT
	jr z, PsTrkSw_ShowHide
	cp xde, EVT_PAINT
	jr z, PsTrkSw_ShowHide
	ld	xwa, (xsp+178)
	ld xbc, xde
	ld	xde, (xsp+174)
	call ViewableProc
	jrl PsTrkSw_Epilogue

PsTrkSw_ShowHide:
	ld	xwa, (xsp+178)
	ld xbc, xde
	ld	xde, (xsp+174)
	call ViewableProc
	ld	xwa, (xsp+178)
	call GetViewInstance
	ld xiz, xhl
	ld	xwa, (xsp+178)
	ld xbc, EVT_GET_CLASS
	ld xde, 0:i3
	call SendEvent
	cp xhl, NAKA_CLASS_PsTrackSwitch
	jr nz, PsTrkSw_ReturnZero
	ld xwa, (xiz + 28)
	ld bc, (xwa)
	extz xbc
	ld xwa, (xiz + 24)
	ld wa, (xwa)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld	xwa, (xsp+178)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xwa, (xiz + 32)
	ld de, (xwa)
	exts xde
	ld	xwa, (xsp+178)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

PsTrkSw_ReturnZero:
	ld xhl, 0:i3
	jrl PsTrkSw_Epilogue

PsTrkSw_Confirm:
	ld	xwa, (xsp+178)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld	xwa, (xsp+174)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld bc, wa
	cp bc, 0xffff
	jr z, PsTrkSw_Confirm_SetSub
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld (xwa), bc

PsTrkSw_Confirm_SetSub:
	ld	xbc, (xsp+174)
	cp bc, 0xffff
	jr z, PsTrkSw_Confirm_DrawGeometry
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld (xwa), bc

PsTrkSw_Confirm_DrawGeometry:
	lda xbc, (xsp+166:16)
	ld	xwa, (xsp+178)
	call GetBox
	lda xbc, (xsp+166:16)
	lda xde, (xsp+158:16)
	ldw wa, 0xcb
	call GetClientBox2
	lda xiy, (xsp+158:16)
	lda xix, (xsp+150:16)
	ld bc, 4:i3
	ldirw
	lda xix, (xsp+142:16)
	lda xwa, (xsp+158:16)
	ld bc, (xwa)
	ld (xix), bc
	lda xiy, (xsp+138:16)
	ld bc, (xwa + 4)
	ld (xiy), bc
	lda xhl, (xwa + 6)
	ld de, (xwa + 2)
	ld bc, (xhl)
	sub bc, de
	exts xbc
	divs bc, 0x2
	ld iz, de
	add iz, bc
	lda xde, (xix + 2)
	ld (xde), iz
	ld (xiy + 2), iz
	ld bc, (xde)
	dec 1, bc
	ld (xhl), bc
	ld bc, (xde)
	inc 1, bc
	ld	(xsp+152), bc
	lda xbc, (xsp+146:16)
	call GetBoxCenter
	lda xwa, (xsp+150:16)
	lda xbc, (xsp+134:16)
	call GetBoxCenter
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	inc 1, wa
	pushw wa
	pushw PsTrkSw_Confirm_DrawGeometry_Str_Fmtd@hi16
	pushw PsTrkSw_Confirm_DrawGeometry_Str_Fmtd@lo16
	lda xwa, (xsp + 124)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 24)
	cpw (xwa + 22), 0x8
	jrl nc, PsTrkSw_Confirm_Track8Plus
	cpw (xbc), 0x0
	jr z, PsTrkSw_Confirm_DrawOff
	lda xwa, (xsp+166:16)
	ldw bc, 0xcb
	ld de, 0:i3
	call DrawDesignBox
	lda xwa, (xsp+142:16)
	lda xbc, (xsp+138:16)
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+158:16)
	lda xbc, (xsp+146:16)
	lda xde, (xsp + 118)
	ld xhl, 0:i3
	push xhl
	pushw 0x7
	pushw 0xf7
	call DrawStringCentered
	lda xwa, (xsp+150:16)
	ld bc, 7:i3
	call DrawBox
	jrl PsTrkSw_Confirm_DrawSecondary

PsTrkSw_Confirm_DrawOff:
	lda xwa, (xsp+166:16)
	ldw bc, 0xcb
	ld de, 7:i3
	call DrawDesignBox
	lda xwa, (xsp+142:16)
	lda xbc, (xsp+138:16)
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+158:16)
	lda xbc, (xsp+146:16)
	lda xde, (xsp + 118)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8Plus:
	cpw (xbc), 0x0
	jr z, PsTrkSw_Confirm_Track8PlusOff
	lda xwa, (xsp+166:16)
	ldw bc, 0xcc
	ld de, 7:i3
	call DrawDesignBox
	lda xwa, (xsp+142:16)
	lda xbc, (xsp+138:16)
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+158:16)
	ld bc, 0:i3
	call DrawBox
	lda xwa, (xsp+158:16)
	lda xbc, (xsp+146:16)
	lda xde, (xsp + 118)
	ld xhl, 0:i3
	push xhl
	pushw 0x7
	pushw 0xf7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8PlusOff:
	lda xwa, (xsp+166:16)
	ldw bc, 0xcc
	ld de, 7:i3
	call DrawDesignBox
	lda xwa, (xsp+142:16)
	lda xbc, (xsp+138:16)
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp+158:16)
	lda xbc, (xsp+146:16)
	lda xde, (xsp + 118)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7

PsTrkSw_Confirm_DrawMark:
	call DrawStringCentered

PsTrkSw_Confirm_DrawSecondary:
	lda xwa, (xsp+150:16)
	lda xbc, (xsp+134:16)
	ld xde, (xsp + 4)
	ld xde, (xde + 28)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 38)
	ld	xde, (xhl+de)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7
	jrl PsTrkSw_DrawAndReturn

PsTrkSw_Select:
	ld	xwa, (xsp+178)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld	xbc, (xsp+174)
	cp bc, 0xffff
	jr z, PsTrkSw_Select_CalcPos
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 32)
	ld (xwa), bc

PsTrkSw_Select_CalcPos:
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 22)
	lda xwa, (xsp+168:16)
	cpw (xbc), 0x8
	jr nc, PsTrkSw_Select_SetE3
	ldw (xwa), 0x96
	jr PsTrkSw_Select_DrawBox

PsTrkSw_Select_SetE3:
	ldw (xwa), 0xe3

PsTrkSw_Select_DrawBox:
	lda xwa, (xsp+166:16)
	ld bc, (xbc)
	and bc, 0x7
	mul bc, 0x28
	inc 2, bc
	ld (xwa), bc
	add bc, 0x23
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0xb
	ld (xwa + 6), bc
	lda xbc, (xsp+146:16)
	call GetBoxCenter
	lda xwa, (xsp+166:16)
	ld xbc, (xsp + 4)
	ld xbc, (xbc + 32)
	ld bc, (xbc)
	sla bc, 1
	lda xde, (xsp + 8)
	ld	bc, (xde+bc)
	call DrawBox
	lda xwa, (xsp+166:16)
	lda xbc, (xsp+146:16)
	ld xde, (xsp + 4)
	ld xde, (xde + 32)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 18)
	ld	xde, (xhl+de)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7

PsTrkSw_DrawAndReturn:
	call DrawStringCentered
	jrl PsTrkSw_ReturnZero

PsTrkSw_HitTest:
	ld	xwa, (xsp+178)
	call GetViewInstance
	lda xwa, (xhl + 22)
	cpw (xwa), 0x8
	jr nc, PsTrkSw_HitTest_Track8Plus
	ld wa, (xwa)
	extz xwa
	cp	xwa, (xsp+174)
	jrl nz, PsTrkSw_ReturnZero
	jr PsTrkSw_HitTest_Match

PsTrkSw_HitTest_Track8Plus:
	ld wa, (xwa)
	add wa, 0x78
	extz xwa
	cp	xwa, (xsp+174)
	jrl nz, PsTrkSw_ReturnZero

PsTrkSw_HitTest_Match:
	ld xhl, 1:i3

PsTrkSw_Epilogue:
	pop xiz
	lda xsp, (xsp+178:16)
	ret

; -----------------------------------------------------------------------------
; PsTrackSwitch_SetBoxFromIndex -- code (was named PsTrkSw_TrailingData)
; XWA = track-switch widget.  n = word +22 of its view instance
; (GetViewInstance); the widget's box becomes x = (n & 7)*40 + 4 .. +31,
; y = 164 (n < 8) or 196 (n >= 8) .. +28, stored with SetBox: two rows of
; eight switches.  No caller was found (see scripts/renaming/uiproc_misc_names.py).
; -----------------------------------------------------------------------------
PsTrackSwitch_SetBoxFromIndex:
	dec	8, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, xiz
	call	GetViewInstance
	lda	xde, (xhl+22)
	lda	xbc, (xsp+4)
	lda	xwa, (xbc+2)
	cpw	(xde), 8
	jr	nc, PsTrackSwitch_SetBoxFromIndex_Skip
	ldw	(xwa), 164
	jr	PsTrackSwitch_SetBoxFromIndex_Join
PsTrackSwitch_SetBoxFromIndex_Skip:
	ldw	(xwa), 196
PsTrackSwitch_SetBoxFromIndex_Join:
	ld	wa, (xde)
	and	wa, 7
	mul	wa, 40
	inc	4, wa
	ld	(xbc), wa
	add	wa, 31
	ld	(xbc+4), wa
	ld	wa, (xbc+2)
	add	wa, 28
	ld	(xbc+6), wa
	ld	xwa, xiz
	call	SetBox
	pop	xiz
	inc	8, xsp
	ret

AcTrackSwitchProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_TRSW_COMMAND
	jrl z, AcTrkSw_OK
	cp xiz, EVT_TRSW_PART
	jrl z, AcTrkSw_ReturnZero
	cp xiz, EVT_SW_IN
	jr z, AcTrkSw_SpecialDispatch
	cp xiz, EVT_REPAINT
	jr z, AcTrkSw_Catchall
	cp xiz, EVT_PAINT
	jr z, AcTrkSw_Catchall
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr AcTrkSw_SpecialDispatch_SendEvent

AcTrkSw_Catchall:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld de, (xhl + 22)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainTrSwControl
	ld xbc, EVT_REQUEST_TRACK_SWITCH
	jr AcTrkSw_SpecialDispatch_CheckPart

AcTrkSw_SpecialDispatch:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcTrkSw_SpecialDispatch_SetPart
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld de, (xhl + 22)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainTrSwControl
	ld xbc, EVT_TOGGLE_TRACK_SWITCH

AcTrkSw_SpecialDispatch_CheckPart:
	call MainFuncCall
	jrl PsTextBox_ZeroReturn

AcTrkSw_SpecialDispatch_SetPart:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

AcTrkSw_SpecialDispatch_SendEvent:
	calr PsTrackSwitchProc
	jrl AcTrkSw_OK_Return

AcTrkSw_ReturnZero:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xsp + 4)
	srl xwa, 16
	and xwa, 0xfff
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	and xwa, 0xff
	ld bc, wa
	extz xbc
	ld xwa, (xsp + 4)
	srl wa, 8
	ld w, 0x0:opc
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	jr AcTrkSw_OK_SendConfirm

AcTrkSw_OK:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xsp + 4)
	srl xwa, 16
	and xwa, 0xfff
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	ldiw_erp 0xe2, 0
	ld de, wa
	exts xde
	ld xwa, (xsp + 8)
	ld xbc, EVT_SELE_DRAW

AcTrkSw_OK_SendConfirm:
	call SendEvent

PsTextBox_ZeroReturn:
	ld xhl, 0:i3

AcTrkSw_OK_Return:
	pop xiz
	inc 8, xsp
	ret

PsTextBoxProc:
	lda xsp, (xsp - 40)
	push xiz
	ld (xsp + 40), xde
	ld xiz, xwa
	cp xbc, EVT_GET_STR_PTR
	jrl z, AcTrkSw_Select_HighTrack
	cp xbc, EVT_PARA_DRAW
	jr z, AcTrkSw_Reset
	ld xwa, xiz
	ld xde, (xsp + 40)
	calr VwBoxProc
	jrl AcTrkSw_Select_DrawTrack

AcTrkSw_Reset:
	ld xwa, xiz
	ld xde, (xsp + 40)
	calr VwBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 20), xhl
	ld xwa, (xsp + 20)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 28)
	ld xwa, xiz
	call GetClientBox
	ld xwa, (xsp + 40)
	or xwa, xwa
	jr nz, AcTrkSw_Reset_UpdateIndex
	ld xwa, xiz
	ld xbc, EVT_GET_STR_PTR
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 16), xhl
	cp (xhl), 0x0
	jr nz, AcTrkSw_Reset_DrawTrack
	jrl AcTrkSw_Select_LowTrack

AcTrkSw_Reset_UpdateIndex:
	ld xwa, (xsp + 40)
	ld (xsp + 16), xwa

AcTrkSw_Reset_DrawTrack:
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	ld xwa, (xsp + 24)
	ld iz, (xwa + 36)
	add iz, hl
	ld wa, iz
	inc 1, wa
	pushw wa
	call Malloc
	ld (xsp + 30), xhl
	ld xbc, (xsp + 30)
	ld (xsp + 16), xbc
	ld wa, iz
	inc 1, wa
	pushw wa
	pushw 0x0
	push xbc
	call Memset
	lda xsp, (xsp + 14)
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 24)
	call ConvertStrings
	lda xbc, (xsp + 28)
	ld wa, (xbc + 4)
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld bc, (xbc)
	add bc, wa
	ld (xsp + 36), bc
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 28)
	call GetCharDescent
	lda xwa, (xsp + 28)
	ld bc, (xwa + 6)
	sub bc, (xwa + 2)
	sub bc, hl
	ld de, bc
	ld xwa, (xsp + 20)
	ld bc, (xwa + 36)
	extz xde
	div xde, bc
	ld (xsp + 8), de
	ldw (xsp + 18), 0x0
	cp bc, 0:i3
	jrl ule, AcTrkSw_Select_CheckTrackNum

AcTrkSw_Select:
	pushw 0xea
	pushw 0xa828
	ld xwa, (xsp + 14)
	push xwa
	call StrSearch_Init
	inc 8, xsp
	ld xwa, (xsp + 10)
	lda	xwa, (xwa+hl)
	ld (xsp + 14), xwa
	ld (xwa), 0x0
	lda xwa, (xsp + 28)
	ld de, (xwa + 4)
	sub de, (xwa)
	ld xwa, (xsp + 20)
	ld xbc, (xwa + 28)
	ld xwa, (xsp + 10)
	call WordwrapStrings
	ld iz, hl
	ld xwa, (xsp + 10)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, iz
	cp wa, hl
	jr z, AcTrkSw_Select_Paint
	ld xwa, (xsp + 14)
	ld (xwa), 0xd
	ld xwa, (xsp + 10)
	lda	xwa, (xwa+iz)
	ld (xsp + 14), xwa
	ld (-xwa), 0x00
	ld (xsp + 14), xwa

AcTrkSw_Select_Paint:
	ld wa, (xsp + 8)
	mrdw3 0x9f, 0x12, 0x40
	lda xde, (xsp + 28)
	ld bc, (xde + 2)
	add bc, wa
	ld wa, (xsp + 8)
	exts xwa
	divs wa, 0x2
	add wa, bc
	lda xbc, (xsp + 36)
	ld (xbc + 2), wa
	ld xhl, (xsp + 4)
	ld xwa, (xhl + 28)
	push xwa
	pushw	(xhl+32)
	pushw 0xf7
	ld xwa, xhl
	ld a, (xwa + 34)
	extz wa
	pushw wa
	ld xwa, xde
	ld xde, (xsp + 20)
	call DrawStringAlignment
	ld xwa, (xsp + 14)
	inc 1, xwa
	ld (xsp + 10), xwa
	cp (xwa), 0x0
	jr z, AcTrkSw_Select_CheckTrackNum
	incw 1, (xsp + 18)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 18)
	cp bc, (xwa + 36)
	jrl c, AcTrkSw_Select

AcTrkSw_Select_CheckTrackNum:
	ld xwa, (xsp + 24)
	push xwa
	call Free
	inc 4, xsp

AcTrkSw_Select_LowTrack:
	ld xhl, 0:i3
	jr AcTrkSw_Select_DrawTrack

AcTrkSw_Select_HighTrack:
	lda xhl, (AcTrkSw_Select_HighTrack_Str_PsTextBox:24)

AcTrkSw_Select_DrawTrack:
	pop xiz
	lda xsp, (xsp + 40)
	ret

AcLanguageTextProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STR_PTR
	jr z, AcTrkSw_ShowHide_CheckDirty
	cp xbc, EVT_DRAW
	jr z, AcTrkSw_ShowHide
	ld xwa, xiz
	calr PsTextBoxProc
	jr AcTrkSw_ShowHide_Refresh

AcTrkSw_ShowHide:
	ld xwa, xiz
	calr PsTextBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld xbc, EVT_GET_LANGUAGE_PTR
	ld xde, 0:i3
	call ApFuncCall
	ld a, (0x0340e4:24)
	extz wa
	sla wa, 2
	ld	xde, (xhl+wa)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld xhl, 0:i3
	jr AcTrkSw_ShowHide_Refresh

AcTrkSw_ShowHide_CheckDirty:
	lda xhl, (AcTrkSw_ShowHide_CheckDirty_Str_AcLanguageText:24)

AcTrkSw_ShowHide_Refresh:
	pop xiz
	ret

LanguageCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, ObjectProc_ClassDispatch
	lda xhl, (LanguageCheck_PtrTable:24)
	ret

; ObjectProc class dispatch with dual handler
ObjectProc_ClassDispatch:
	ld xhl, 0:i3
	ret

TrTransposeBoxProc:
	jp AcTranspose_ParamData_End

TrChordBoxProc:
	jp AcChordBoxProc_Entry

ObjectProc:
	lda xsp, (xsp-144)
	push xiz
	ld	(xsp+136), xde
	ld	(xsp+140), xbc
	ld	(xsp+144), xwa
	ld	xwa, (xsp+144)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027ed6:24)
	add xwa, xbc
	ld xix, (xwa)
	ld	xwa, (xsp+144)
	ld xbc, EVT_GET_CLASS_SP
	ld xde, 0:i3
	call (xix)
	ld xiz, xhl
	ld	xwa, (xsp+140)
	sub xwa, EVT_GET_CLASS
	cp xwa, 0x0
	jrl lt, ExitWindow_Init
	cp xwa, 0x13
	jrl gt, ExitWindow_Init
	add xwa, xwa
	add xwa, Str_No_0x58E
	ld wa, (xwa)
	lda xix, (AcTrkSw_Return:24)
; Computed jump: target = AcTrkSw_Return + Str_No_0x58E[i], Str_No_0x58E = 16-bit offsets (20 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e00010:
;   0x1e00010 -> AcTrkSw_Return
;   0x1e00011 -> ObjectProc_Evt1E00011
;   0x1e00012 -> ObjectProc_Evt1E00012
;   0x1e00013 -> ObjectProc_Evt1E00013
;   0x1e00014 -> ObjectProc_Evt1E00014
;   0x1e00015 -> ExitWindow_Init
;   0x1e00016 -> ExitWindow_Init
;   0x1e00017 -> ObjectProc_Evt1E00017
;   0x1e00018 -> ObjectProc_Evt1E00018
;   0x1e00019 -> ObjectProc_Evt1E00019
;   0x1e0001a -> ObjectProc_Evt1E0001A
;   0x1e0001b -> ObjectProc_Evt1E0001B
;   0x1e0001c -> ObjectProc_Evt1E0001C
;   0x1e0001d -> ObjectProc_Evt1E0001D
;   0x1e0001e -> ObjectProc_Evt1E0001E
;   0x1e0001f -> ObjectProc_Evt1E0001F
;   0x1e00020 -> ObjectProc_Evt1E00020
;   0x1e00021 -> ObjectProc_Evt1E00021
;   0x1e00022 -> ObjectProc_Evt1E00022
;   0x1e00023 -> ObjectProc_Evt1E00023
	jp	t, (xix+wa)

AcTrkSw_Return:
	ld	xhl, xiz
	jrl	ObjectProc_Join5
ObjectProc_Evt1E00011:
	ld	xwa, xiz
	ld	xbc, EVT_GET_PARENT_CLASS_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00013:
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROCEDURE_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00021:
	ld	xwa, xiz
	ld	xbc, EVT_GET_INSTANCE_SIZE_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00012:
	ld	xwa, xiz
	ld	xbc, EVT_GET_NAME
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00014:
	ld	xwa, xiz
	ld	xbc, EVT_CHECK_CLASS_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00019:
	ld	xwa, (xsp+136)
	ld	(xwa), 0
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROP_STRING_EX
	ld	xde, (xsp+136)
	calr	ClassProc
	ld	(xsp+4), xhl
	ld	xwa, (xsp+144)
	ld	xbc, EVT_CHECK_CLASS
	ld	xde, NAKA_CLASS_Viewable
	call	SendEvent
	or	xhl, xhl
	jr	z, ObjectProc_Skip3
	pushw	ObjectProc_Evt1E00019_Str_YZ@hi16
	pushw ObjectProc_Evt1E00019_Str_YZ@lo16
	ld	xwa, (xsp+140)
	push	xwa
	call	Strcat
	inc	8, xsp
ObjectProc_Skip3:
	ld	xhl, (xsp+4)
	jrl	ObjectProc_Join5
ObjectProc_Evt1E00017:
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROP_COUNT_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E00018:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	lda	xbc, (xsp+8)
	ld	xhl, xbc
	ld	xwa, (xsp+136)
	add	xhl, (xwa)
	lda	xde, (xwa+4)
	cp	(xhl), 89
	jr	nz, ObjectProc_Skip
	pushw ObjectProc_Evt1E00018_Str_name@hi16
	pushw ObjectProc_Evt1E00018_Str_name@lo16
	ld	xwa, (xde)
	push	xwa
	jr	ObjectProc_Join
ObjectProc_Skip:
	ld	xwa, (xsp+136)
	add	xbc, (xwa)
	ld	xwa, (xde)
	cp	(xbc), 90
	jr	nz, ObjectProc_Skip2
	pushw ObjectProc_Evt1E00018_Str_romram@hi16
	pushw ObjectProc_Evt1E00018_Str_romram@lo16
	push	xwa
ObjectProc_Join:
	call	Strcpy
	inc	8, xsp
	jrl	ObjectProc_Join4
ObjectProc_Skip2:
	pushw ObjectProc_Evt1E00018_Str_Empty@hi16
	pushw ObjectProc_Evt1E00018_Str_Empty@lo16
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROP_NAME_SP
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join3
ObjectProc_Evt1E0001A:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	ld	xwa, (xsp+136)
	ld	bc, (xwa+8)
	extz	xbc
	lda	xwa, (xsp+8)
	add	xwa, xbc
	ld	a, (xwa)
	sub	a, 65
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x02600000
	ld	xbc, EVT_COPY_PROPERTY_EX
	ld	xde, (xsp+136)
	jrl	ObjectProc_Join2
ObjectProc_Evt1E0001B:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	ld	xbc, (xsp+144)
	ld	xwa, (xsp+136)
	ld	(xwa+8), xbc
	lda	xbc, (xsp+8)
	add	xbc, (xwa)
	ld	a, (xbc)
	sub	a, 65
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x02600000
	ld	xbc, EVT_DUMP_PROPERTY_EX
	ld	xde, (xsp+136)
	jr	ObjectProc_Join2
ObjectProc_Evt1E0001C:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	ld	xbc, (xsp+144)
	ld	xwa, (xsp+136)
	ld	(xwa+8), xbc
	lda	xbc, (xsp+8)
	add	xbc, (xwa)
	ld	a, (xbc)
	sub	a, 65
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x02600000
	ld	xbc, EVT_DUMP_POINTER_EX
	ld	xde, (xsp+136)
	jr	ObjectProc_Join2
ObjectProc_Evt1E0001D:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	ld	xbc, (xsp+144)
	ld	xwa, (xsp+136)
	ld	(xwa+8), xbc
	lda	xbc, (xsp+8)
	add	xbc, (xwa)
	ld	a, (xbc)
	sub	a, 65
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x02600000
	ld	xbc, EVT_GET_PROPERTY_EX
	ld	xde, (xsp+136)
ObjectProc_Join2:
	call	SendEvent
	jrl	ObjectProc_Join4
ObjectProc_Evt1E0001E:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	ld	xbc, (xsp+144)
	ld	xwa, (xsp+136)
	ld	(xwa+8), xbc
	lda	xbc, (xsp+8)
	add	xbc, (xwa)
	ld	a, (xbc)
	sub	a, 65
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x02600000
	ld	xbc, EVT_SET_PROPERTY_EX
	ld	xde, (xsp+136)
	call	SendEvent
	jr	ObjectProc_Join5
ObjectProc_Evt1E0001F:
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROP_DATA_SP
	ld	xde, (xsp+136)
	jr	ObjectProc_Join3
ObjectProc_Evt1E00020:
	ld	xwa, xiz
	ld	xbc, EVT_GET_PROP_DATA_COUNT_SP
	ld	xde, (xsp+136)
ObjectProc_Join3:
	calr	ClassProc
	jr	ObjectProc_Join5
ObjectProc_Evt1E00022:
	lda	xde, (xsp+8)
	ld	xwa, (xsp+144)
	ld	xbc, EVT_GET_PROP_STRING
	call	SendEvent
	lda	xwa, (xsp+8)
	add	xwa, (xsp+136)
	ld	xhl, 0:i3
	ld	l, (xwa)
	jr	ObjectProc_Join5
ObjectProc_Evt1E00023:
	ld	xwa, (xsp+136)
	push	xwa
	call	Free
	inc	4, xsp
ObjectProc_Join4:
	ld	xhl, 0:i3
	jr	ObjectProc_Join5

ExitWindow_Init:
	ld	xwa, (xsp+144)
	ld	xbc, (xsp+140)
	ld	xde, (xsp+136)
	calr InheritedProc
ObjectProc_Join5:
	pop xiz
	lda xsp, (xsp+144:16)
	ret

InitializeObjectTable:
	lda xsp, (xsp - 14)
	pushw iz
	ldw (0x02bc12:24), 0x0000
	lda xwa, (0x027ed2:24)
	lda xbc, (xwa + 10)
	lda xde, (xwa + 8)
	lda xhl, (xwa + 4)
	ld xix, xwa
	lda xiy, (xwa+15680)

ExitWindow_Paint:
	ld xwa, 0xffffffff
	ld (xix), xwa
	ld xwa, 0:i3
	ld (xhl), xwa
	ldw (xde), 0x0
	ld (xbc), xwa
	lda xix, (xix + 14)
	lda xhl, (xhl + 14)
	lda xde, (xde + 14)
	lda xbc, (xbc + 14)
	cp xix, xiy
	jr c, ExitWindow_Paint
	lda xbc, (0x0328fc:24)
	ld xwa, xbc
	lda xde, (xbc+448)

ExitWindow_Confirm:
	ld xiy, Str_No_0x5B6
	ld xix, xwa
	ld bc, 7:i3
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, ExitWindow_Confirm
	lda xbc, (0x032abc:24)
	ld xwa, xbc
	lda xde, (xbc+5632)

ExitWindow_OK:
	ld xiy, Str_No_0x5C6
	ld xix, xwa
	ldw bc, 0xb
	ldirw
	lda xwa, (xwa + 22)
	cp xwa, xde
	jr c, ExitWindow_OK
	lda xbc, (xsp + 2)
	ld xwa, NAKA_CLASS_SupportClass
	ld (xbc), xwa
	lda xwa, (SupportClassProc:24)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x37
	lda xwa, (NakaInst_IT_Off_0x8:24)
	ld (xbc + 10), xwa
	ldw wa, 0x260
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, NAKA_CLASS_Mode
	ld (xbc), xwa
	lda xwa, (ModeProc:24)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x20
	lda xwa, (0x0328fc:24)
	ld (xbc + 10), xwa
	ldw wa, 0x180
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, NAKA_CLASS_Title
	ld (xbc), xwa
	lda xwa, (TitleProc:24)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x100
	lda xwa, (0x032abc:24)
	ld (xbc + 10), xwa
	ldw wa, 0x1a0
	calr RegisterObjectTable
	ld iz, 0:i3

ExitWindow_Return:
	lda xbc, (xsp + 2)
	ld xwa, NAKA_CLASS_Viewable
	ld (xbc), xwa
	lda xwa, (ViewableProc:24)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x0
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xde, 0x276d2
	add xde, xwa
	ld (xbc + 10), xde
	ld wa, iz
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xde, 0x27ad2
	add xde, xwa
	ld (xbc + 10), xde
	ld wa, iz
	add wa, 0x300
	calr RegisterObjectTable
	inc 1, iz
	cp iz, 0x100
	jr c, ExitWindow_Return
	ld xwa, 0:i3
	call SetCurrentTarget
	call InitializeMurai
	call InitializeToshi
	call InitializeEast
	call InitializeSuna
	call InitializeCheap
	call InitializeScoop
	call InitializeYoko
	call InitializeKubo
	call InitializeHama
	call InitializeKSS
	call InitializeNaka
	call InitializeUser12
	call InitializeUser13
	call InitializeUser14
	call InitializeUser15
	call InitializeUser16
	call InitializeUser17
	call InitializeUser18
	call InitializeUser19
	call InitializeUser20
	call InitializeUser21
	call InitializeUser22
	call InitializeUser23
	call InitializeUser24
	call InitializeUser25
	call InitializeUser26
	call InitializeUser27
	call InitializeUser28
	call InitializeUser29
	call InitializeUser30
	call InitializeUser31
	call InitializeRoot
	popw iz
	lda xsp, (xsp + 14)
	ret

CountObject:
	dec 6, xsp
	push xiz
	ld (xsp + 8), bc
	ld iz, 0:i3
	ldfr_werp WA, 0xfa
	cp wa, (xsp + 8)
	jr ugt, InputDialog_GetText_CopyAndReturn
	lda xwa, (0x027ed2:24)
	ld (xsp + 4), xwa
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, 0xe
	call Math_MultiplyAccumulate

InputDialog_GetText:
	ld xwa, (xsp + 4)
	add xwa, xhl
	add iz, (xwa + 8)
	inc1w_erp 0xfa
	add xhl, 0xe
	ldto_werp WA, 0xfa
	cp wa, (xsp + 8)
	jr ule, InputDialog_GetText

InputDialog_GetText_CopyAndReturn:
	ld hl, iz
	pop xiz
	inc 6, xsp
	ret

CheckViewObject:
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda xbc, (0x027edc:24)
	add xbc, xde
	ld xbc, (xbc)
	or xbc, xbc
	jr nz, InputDialog_Paint
	ld hl, 0:i3
	ret

InputDialog_Paint:
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	scc16 nz, hl
	ret


; inputs:
;   XBC = ?
;   WA = offset in the registry where the table will start to be copied to ("registered")
;
; note: Each object in the registry takes up 14 bytes.
;
RegisterObjectTable:
	cp wa, 0x45f
	ret ugt
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	add xde, xde
	ld xix, 0x27ed2
	add xix, xde	; XIX = 27ed2h + 14 * XWA
	ld xiy, xbc
	ld bc, 7:i3
	ldirw
	ret

RegisterObject:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	call GetCurrentTarget
	srl xhl, 16
	and xhl, 0xfff
	ld de, hl
	ld wa, de
	extz xwa
	ld (xsp + 8), xwa
	sla xwa, 3
	sub xwa, (xsp + 8)
	add xwa, xbc
	ld xbc, xwa
	lda xhl, (0x027ed2:24)
	ld (xsp + 4), xhl
	add xhl, xbc
	ld xiz, (xhl + 10)
	ld iy, 0:i3

InputDialog_Confirm:
	ld wa, iy
	extz xwa
	ld (xsp + 12), xwa
	sla xwa, 2
	ld xix, xwa
	ld xbc, xix
	add xbc, xiz
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, InputDialog_Return
	ld xwa, (xsp + 16)
	ld (xbc), xwa
	ld xbc, (xsp + 20)
	ld (xwa), xbc
	add de, 0x300
	extz xde
	ld xbc, xde
	sll xbc, 3
	sub xbc, xde
	add xbc, xbc
	ld xwa, (xsp + 4)
	add xwa, xbc
	ld xwa, (xwa + 10)
	add xix, xwa
	lda xwa, (Str_No_0x5DE:24)
	ld (xix), xwa
	incw 1, (xhl + 8)
	ld xhl, (xsp + 8)
	sll xhl, 16
	add xhl, (xsp + 12)
	jr UnRegisterObject_Epilogue

InputDialog_Return:
	inc 1, iy
	cp iy, 0x400
	jr c, InputDialog_Confirm
	ld xhl, 0xffffffff

; UnRegisterObject epilogue handler
UnRegisterObject_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

UnRegisterObject:
	push xiz
	srl xwa, 16
	and xwa, 0xfff
	ld hl, wa
	ld bc, hl
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	lda xix, (0x027ed2:24)
	ld xbc, xix
	add xbc, xwa
	ld xiz, (xbc + 10)
	extz xde
	sll xde, 2
	ld xiy, xde
	add xiy, xiz
	ld xwa, 0:i3
	ld (xiy), xwa
	add hl, 0x300
	ld wa, hl
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	add xix, xhl
	ld xwa, (xix + 10)
	add xde, xwa
	lda xwa, (Str_No_0x5E0:24)
	ld (xde), xwa
	decw	1, (xbc+8)
	pop xiz
	ret

InheritedProc:
	dec 4, xsp
	push xiz
	ld xhl, (0x02bc14:24)
	ld (xsp + 4), xhl
	srl xhl, 16
	and xhl, 0xfff
	ld iz, hl
	ld xhl, (xsp + 4)
	ldiw_erp 0xee, 0
	ld iy, hl
	ld hl, iz
	extz xhl
	ld xiz, xhl
	sll xiz, 3
	sub xiz, xhl
	add xiz, xiz
	lda xix, (0x027ed2:24)
	ld xhl, xix
	add xhl, xiz
	ld xiz, (xhl + 10)
	ld hl, iy
	extz xhl
	ld xiy, xhl
	add xiy, xiy
	add xiy, xhl
	sll xiy, 3
	add xiy, xiz
	ld xiy, (xiy + 4)
	cp xiy, 0xffffffff
	jr z, TitleWidget_Init
	ld (0x02bc14:24), xiy
	ld xhl, xiy
	srl xhl, 16
	and xhl, 0xfff
	ld iz, hl
	ld xhl, xiy
	ldiw_erp 0xee, 0
	ld iy, hl
	ld hl, iz
	extz xhl
	ld xiz, xhl
	sll xiz, 3
	sub xiz, xhl
	add xiz, xiz
	add xix, xiz
	ld xiz, (xix + 10)
	ld hl, iy
	extz xhl
	ld xix, xhl
	add xix, xix
	add xix, xhl
	sll xix, 3
	add xix, xiz
	ld xhl, (xix)
	call (xhl)
	ld xwa, xhl
	ld xbc, (xsp + 4)
	ld (0x02bc14:24), xbc
	jr RootObject_GetterBlock

TitleWidget_Init:
	ld xwa, 0:i3

; GetRootObject/Event/Param block
RootObject_GetterBlock:
	ld xhl, xwa
	pop xiz
	inc 4, xsp
	ret

GetRootObject:
	ld xhl, (0x02bc18:24)
	ret

GetRootEvent:
	ld xhl, (0x02bc1c:24)
	ret

GetRootParam:
	ld xhl, (0x02bc20:24)
	ret

SetRootObject:
	ld (0x02bc18:24), xwa
	ret

SetRootEvent:
	ld (0x02bc1c:24), xwa
	ret

SetRootParam:
	ld (0x02bc20:24), xwa
	ret

GetFocusObject:
	ld xhl, (0x02bc24:24)
	ret

GetFocusEvent:
	ld xhl, (0x02bc28:24)
	ret

GetFocusParam:
	ld xhl, (0x02bc2c:24)
	ret

ClassProc:
	lda xsp, (xsp-278)
	push xiz
	ld	(xsp+274), xde
	ld	(xsp+278), xbc
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ld de, bc
	ld xbc, xwa
	ldiw_erp 0xe6, 0
	ld (xsp + 8), bc
	ld bc, de
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda xiy, (0x027ed2:24)
	ld xbc, xiy
	add xbc, xde
	ld xbc, (xbc + 10)
	ld (xsp + 4), xbc
	ld XIX, (xsp + 0x0116)
	ld (xsp + 14), xix
	lda xde, (xsp+146:16)
	cp xix, EVT_GET_PROP_DATA_COUNT_SP
	jrl z, TitleWidget_OK_Forward
	cp xix, EVT_GET_PROP_DATA_SP
	jrl z, TitleWidget_OK
	ld bc, (xsp + 8)
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 3
	add xhl, (xsp + 4)
	cp xix, EVT_GET_INSTANCE
	jr z, TitleWidget_Paint
	ld xbc, xix
	cp xbc, EVT_GET_NAME
	jr z, ClassProc_Event_LoadFromOffset
	ld xiz, xhl
	inc 4, xhl
	ld xbc, (xsp + 14)
	sub xbc, EVT_GET_CLASS_SP
	cp xbc, 0x0
	jrl lt, TitleWidget_OK_AdvanceDone
	cp xbc, 0x7
	jrl gt, TitleWidget_OK_AdvanceDone
	add xbc, xbc
	add xbc, Str_No_0x5E2
	ld bc, (xbc)
	lda xix, (ClassProc_Event_LoadFromWA:24)
; Computed jump: target = ClassProc_Event_LoadFromWA + Str_No_0x5E2[i], Str_No_0x5E2 = 16-bit offsets (8 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e00000:
;   0x1e00000 -> ClassProc_Event_LoadFromWA
;   0x1e00001 -> ClassProc_Event_LoadFromHL
;   0x1e00002 -> ClassProc_Event_LoadFromIZ
;   0x1e00003 -> ClassProc_Evt1E00003
;   0x1e00004 -> ClassProc_Evt1E00004
;   0x1e00005 -> ClassProc_Evt1E00005
;   0x1e00006 -> ClassProc_Evt1E00006
;   0x1e00007 -> ClassProc_Evt1E00007
	jp	t, (xix+bc)
;-----------------------------------------------------------------------------
; ClassProc_EventHandlers - Dispatch table for UI event types
;
; Jumped to via: JP T, XIX + BC where XIX = 0xfa4598
; BC offset comes from table at 0xeaa8f8 indexed by event type (0-7)
;
; Each handler loads XHL from a different source, then jumps to common code
;-----------------------------------------------------------------------------
ClassProc_Event_LoadFromWA:	; FA4598 - Event handler: load XHL from XWA
	ld xhl, xwa
	jrl ClassProc_ReturnWithStatus

ClassProc_Event_LoadFromHL:	; FA459D - Event handler: load XHL from (XHL)
	ld xhl, (xhl)
	jrl ClassProc_ReturnWithStatus

ClassProc_Event_LoadFromIZ:	; FA45A2 - Event handler: load XHL from (XIZ)
	ld xhl, (xiz)
	jrl ClassProc_ReturnWithStatus

ClassProc_Event_LoadFromOffset:	; FA45A7 - Event handler: load XHL from (XHL+0Ch)
	ld xhl, (xhl + 12)
	jrl ClassProc_ReturnWithStatus

TitleWidget_Paint:
	jrl ClassProc_ReturnWithStatus
ClassProc_Evt1E00003:
	ld hl, (xiz + 8)
	extz xhl
	jrl ClassProc_ReturnWithStatus
ClassProc_Evt1E00004:
	ld XBC, (xsp + 0x0112)
	ld xde, xwa
	cp xwa, 0xffffffff
	jrl z, ClassProc_ReturnZeroJmp

TitleWidget_Paint_CheckState:
	cp xde, xbc
	jr nz, TitleWidget_Paint_DrawText
	ld xhl, 1:i3
	jrl ClassProc_ReturnWithStatus

TitleWidget_Paint_DrawText:
	ld xwa, xde
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	ld xwa, xiy
	add xwa, xhl
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ldiw_erp 0xea, 0
	ld wa, de
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 3
	add xde, (xsp + 4)
	ld xde, (xde + 4)
	cp xde, 0xffffffff
	jr nz, TitleWidget_Paint_CheckState
	jrl ClassProc_ReturnZeroJmp
ClassProc_Evt1E00005:
	ld xwa, (xiz + 16)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ld xwa, 0:i3
	ld (xsp + 10), xwa
	jr TitleWidget_Confirm

TitleWidget_Select:
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_CHECK_PROP_STRING
	call SendEvent
	ld xwa, 1:i3
	add (xsp + 10), xwa

TitleWidget_Confirm:
	lda xde, (xsp+146:16)
	ld xwa, xde
	add xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0:i3
	jr nz, TitleWidget_Select
	ld XWA, (xsp + 0x0112)
	push xwa
	push xde
	call Strcat
	lda xwa, (xsp+154:16)
	push xwa
	ld XWA, (xsp + 0x011e)
	push xwa
	call Strcpy
	lda xsp, (xsp + 16)
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 3
	add xbc, (xsp + 4)
	ld xbc, (xbc + 4)
	cp xbc, 0xffffffff
	jrl z, ClassProc_ReturnZeroJmp
	ld xwa, xbc
	ld xbc, EVT_GET_PROP_STRING_EX
	ld XDE, (xsp + 0x0112)
	calr ClassProc
	jrl ClassProc_ReturnZeroJmp
ClassProc_Evt1E00006:
	ld xbc, EVT_GET_PROP_STRING
	call SendEvent
	lda xwa, (xsp+146:16)
	push xwa
	call Strlen
	inc 4, xsp
	extz xhl
	jrl ClassProc_ReturnWithStatus
ClassProc_Evt1E00007:
	ld xbc, (xhl)
	cp xbc, 0xffffffff
	jr z, TitleWidget_Confirm_DrawLayout
	ld xwa, xbc
	ld xbc, EVT_GET_PROP_NAME_SP
	ld XDE, (xsp + 0x0112)
	calr ClassProc

TitleWidget_Confirm_DrawLayout:
	ld XWA, (xsp + 0x0112)
	ld xwa, (xwa + 4)
	cp (xwa), 0x0
	jrl nz, ClassProc_ReturnZeroJmp
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 3
	add xbc, (xsp + 4)
	ld xwa, (xbc + 16)
	push xwa
	lda xwa, (xsp+150:16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, 0:i3
	ld (xsp + 10), xwa
	jr TitleWidget_Confirm_DrawRowLoop

TitleWidget_Confirm_DrawRow:
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_CHECK_PROP_STRING
	call SendEvent
	ld xwa, 1:i3
	add (xsp + 10), xwa

TitleWidget_Confirm_DrawRowLoop:
	lda xde, (xsp+146:16)
	ld xwa, xde
	add xwa, (xsp + 10)
	ld a, (xwa)
	cp a, 0:i3
	jr nz, TitleWidget_Confirm_DrawRow
	ld xwa, 0:i3
	ld (xsp + 14), xwa
	ld (xsp + 10), xwa
	jr TitleWidget_Confirm_DrawItem

TitleWidget_Confirm_DrawRowNext:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 3
	add xbc, (xsp + 4)
	ld xwa, (xsp + 14)
	sll xwa, 2
	add xwa, (xbc + 20)
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp+146:16)
	add xwa, (xsp + 10)
	ld a, (xwa)
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	lda xde, (xsp + 18)
	ld xbc, EVT_GET_PROP_MEMBER
	call SendEvent
	add (xsp + 14), xhl
	ld XBC, (xsp + 0x0112)
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, TitleWidget_Confirm_SkipEmpty
	lda xwa, (xsp + 18)
	push xwa
	ld xwa, (xbc + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	jr ClassProc_ReturnZeroJmp

TitleWidget_Confirm_SkipEmpty:
	ld xbc, 1:i3
	add (xsp + 10), xbc
	ld XWA, (xsp + 0x0112)
	sub (xwa), xbc

TitleWidget_Confirm_DrawItem:
	lda xwa, (xsp+146:16)
	add xwa, (xsp + 10)
	cp (xwa), 0x0
	jrl nz, TitleWidget_Confirm_DrawRowNext

ClassProc_ReturnZeroJmp:
	ld xhl, 0:i3
	jr ClassProc_ReturnWithStatus

TitleWidget_OK:
	ld xbc, EVT_GET_PROP_STRING
	call SendEvent
	lda xbc, (xsp+146:16)
	ld XWA, (xsp + 0x0112)
	add xbc, (xwa)
	ld a, (xbc)
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_GET_PROP_DATA_SP
	ld XDE, (xsp + 0x0112)
	jr TitleWidget_OK_Advance

TitleWidget_OK_Forward:
	ld xbc, EVT_GET_PROP_STRING
	call SendEvent
	lda xwa, (xsp+146:16)
	add	xwa, (xsp+274)
	ld a, (xwa)
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_GET_PROP_DATA_COUNT_SP
	ld XDE, (xsp + 0x0112)

TitleWidget_OK_Advance:
	call SendEvent
	jr ClassProc_ReturnWithStatus

TitleWidget_OK_AdvanceDone:
	ld XBC, (xsp + 0x0116)
	ld XDE, (xsp + 0x0112)
	calr ObjectProc

ClassProc_ReturnWithStatus:
	pop xiz
	lda xsp, (xsp+278)
	ret

SupportClassProc:
	push xiz
	ld xix, xwa
	ld xhl, xix
	srl xhl, 16
	and xhl, 0xfff
	ld iy, hl
	ld xhl, xwa
	ldiw_erp 0xee, 0
	ld iz, hl
	ld hl, iy
	extz xhl
	ld xiy, xhl
	sll xiy, 3
	sub xiy, xhl
	add xiy, xiy
	lda xhl, (0x027edc:24)
	add xhl, xiy
	ld xiy, (xhl)
	extz xiz
	ld xhl, xiz
	add xhl, xhl
	add xhl, xiz
	sll xhl, 2
	add xhl, xiy
	cp xbc, EVT_GET_PROP_SIZE
	jr z, TitleWidget_Default
	cp xbc, EVT_GET_INSTANCE
	jr z, SupportClass_PopIzRet
	cp xbc, EVT_GET_CLASS_SP
	jr nz, SupportClass_VirtualDispatch
	ld xhl, NAKA_CLASS_SupportClass
	jr SupportClass_PopIzRet

TitleWidget_Default:
	ld hl, (xhl + 6)
	extz xhl
	jr SupportClass_PopIzRet

; SupportClass virtual dispatch with type check
SupportClass_VirtualDispatch:
	cp xix, NAKA_CLASS_SupportClass
	jr z, TitleWidget_Return
	ld xix, (xhl)
	call (xix)
	jr SupportClass_PopIzRet

TitleWidget_Return:
	calr ObjectProc

SupportClass_PopIzRet:
	pop xiz
	ret

FunctionProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xde, xwa
	srl xde, 16
	and xde, 0xfff
	ld hl, de
	ld xde, xwa
	ldiw_erp 0xea, 0
	ld ix, hl
	extz xix
	ld xiz, xix
	sll xiz, 3
	sub xiz, xix
	add xiz, xiz
	lda xiy, (0x027ed2:24)
	ld xix, xiy
	add xix, xiz
	ld xix, (xix + 10)
	extz xde
	sll xde, 2
	cp xbc, EVT_GET_NAME
	jr z, FunctionProc_Dispatch
	ld xhl, xde
	add xhl, xix
	cp xbc, EVT_GET_FUNCTION
	jr z, ResourceWidget_Init_Loop
	cp xbc, EVT_GET_INSTANCE
	jr z, FuncProc_PopIzSkip4Ret
	cp xbc, EVT_GET_CLASS_SP
	jr z, ResourceWidget_Init
	ld xde, (xsp + 4)
	calr ObjectProc
	jr FuncProc_PopIzSkip4Ret

ResourceWidget_Init:
	ld xhl, NAKA_CLASS_Function
	jr FuncProc_PopIzSkip4Ret

ResourceWidget_Init_Loop:
	ld xhl, (xhl)
	jr FuncProc_PopIzSkip4Ret

; FunctionProc complex heap indexing dispatch
FunctionProc_Dispatch:
	add hl, 0x300
	extz xhl
	ld xbc, xhl
	sll xbc, 3
	sub xbc, xhl
	add xbc, xbc
	add xiy, xbc
	ld xwa, (xiy + 10)
	add xde, xwa
	ld xhl, (xde)

FuncProc_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

FuncCall:
	ld xhl, xwa
	srl xhl, 16
	and xhl, 0xfff
	ld ix, hl
	ld xhl, xwa
	ldiw_erp 0xee, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda xhl, (0x027edc:24)
	add xhl, xix
	ld xix, (xhl)
	ld hl, iy
	extz xhl
	sll xhl, 2
	add xhl, xix
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xhl
	ret

ApFunctionProc:
	cp xbc, EVT_GET_NAME
	jr z, ApFuncCall_VirtualDispatch
	cp xbc, EVT_GET_CLASS_SP
	jrl nz, FunctionProc
	ld xhl, NAKA_CLASS_ApFunction
	ret

; ApFuncCall object ID lookup dispatch
ApFuncCall_VirtualDispatch:
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld de, wa
	add bc, 0x300
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xhl, (xde)
	ret


ApFuncCall:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_ApFunction
	call SendEvent
	or xhl, xhl
	jr z, ResourceWidget_ReturnZero
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	ld xde, xiz
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xix, (xde)
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call (xix)
	jr ResourceWidget_Return

ResourceWidget_ReturnZero:
	ld xhl, 0:i3

ResourceWidget_Return:
	pop xiz
	inc 8, xsp
	ret

DefaultFunction:
	ld xhl, 0:i3
	ret

MainFunctionProc:
	cp xbc, EVT_GET_NAME
	jr z, MainFuncCall_DispatchDSP
	cp xbc, EVT_GET_CLASS_SP
	jrl nz, FunctionProc
	ld xhl, NAKA_CLASS_MainFunction
	ret

; MainFuncCall DSP variant dispatch
MainFuncCall_DispatchDSP:
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld de, wa
	add bc, 0x300
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xhl, (xde)
	ret

MainFuncCall:
	call MainPostEvent
	ld xhl, 0:i3
	ret

DefMainFunction:
	ld xhl, 0:i3
	ret

ModeProc:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xde
	ld xiz, xbc
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ld de, bc
	ld xbc, xwa
	ldiw_erp 0xe6, 0
	ld (xsp + 8), bc
	ld bc, de
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda xbc, (0x027edc:24)
	add xbc, xde
	ld xbc, (xbc)
	ld (xsp + 4), xbc
	ld xbc, xiz
	cp xiz, EVT_ACTIVATE_STATE
	jrl z, ObjectEnum_Default
	cp xiz, EVT_CHANGE_MODE
	jrl z, ObjectEnum_Close
	cp xiz, EVT_GET_NAME
	jrl z, ObjectEnum_Init
	cp xiz, EVT_GET_INSTANCE
	jr z, NakaWidget_Return
	cp xiz, EVT_GET_CLASS_SP
	jr z, NakaWidget_ReturnConst_0x1600006
	sub xbc, EVT_GET_MODE_PROC
	cp xbc, 0x0
	jrl lt, GetMode_DispatchDSP
	cp xbc, 0x5
	jrl gt, GetMode_DispatchDSP
	add xbc, xbc
	add xbc, Str_No_0x5F2
	ld bc, (xbc)
	lda xix, (NakaWidget_ReturnConst_0x1600006:24)
; Computed jump: target = NakaWidget_ReturnConst_0x1600006 + Str_No_0x5F2[i], Str_No_0x5F2 = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e0002b:
;   0x1e0002b -> ModeProc_Evt1E0002B
;   0x1e0002c -> ModeProc_Evt1E0002C
;   0x1e0002d -> ModeProc_Evt1E0002D
;   0x1e0002e -> ModeProc_Evt1E0002E
;   0x1e0002f -> ModeProc_Evt1E0002F
;   0x1e00030 -> ModeProc_Evt1E00030
	jp	t, (xix+bc)

NakaWidget_ReturnConst_0x1600006:
	ld xhl, NAKA_CLASS_Mode
	jrl GetMode_Epilogue10

NakaWidget_Return:
	ld wa, (xsp + 8)
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	add xhl, (xsp + 4)
	jrl GetMode_Epilogue10
ModeProc_Evt1E0002B:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, EVT_GET_FUNCTION
	ld xde, 0:i3
	call SendEvent
	jrl GetMode_Epilogue10
ModeProc_Evt1E0002C:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc)
	jrl GetMode_Epilogue10
ModeProc_Evt1E0002D:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc + 4)
	jrl GetMode_Epilogue10
ModeProc_Evt1E00030:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld hl, (xbc + 8)
	exts xhl
	jrl GetMode_Epilogue10

ObjectEnum_Init:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc + 10)
	jrl GetMode_Epilogue10
ModeProc_Evt1E0002E:
	ld xhl, (0x03ef82:24)
	jrl GetMode_Epilogue10
ModeProc_Evt1E0002F:
	ld xhl, (0x03ef86:24)
	jrl GetMode_Epilogue10

ObjectEnum_Close:
	ld xwa, 0xffffffff
	ld xbc, EVT_REFRESH_AP_TASK
	ld xde, 0:i3
	call SendEvent
	ld xwa, (0x03ef8a:24)
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, ObjectEnum_Paint

ObjectEnum_Destroy:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (0x03ef8a:24)
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, ObjectEnum_Destroy

ObjectEnum_Paint:
	ld xwa, (xsp + 10)
	ld xde, (0x03ef82:24)
	lda xbc, (0x027ed2:24)
	cp xwa, xde
	jr nz, ObjectEnum_OK
	ld xwa, NAKA_MODE_MD_NORMAL
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x1
	ld XWA, (xbc + 0x150a)
	ld (xsp + 4), xwa

ObjectEnum_OK:
	ld (0x03ef86:24), xde
	ld xwa, (0x03ef8a:24)
	ld (0x03ef8e:24), xwa
	ld wa, (xsp + 8)
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	add xde, xde
	add xde, (xsp + 4)
	inc 4, xde
	ld xwa, (xde)
	cp xwa, 0xffffffff
	jr z, ObjectEnum_OK_Dispatch
	ld xwa, (xsp + 10)
	ld (0x03ef82:24), xwa
	ld xwa, (xde)
	ld (0x03ef8a:24), xwa
	jr ObjectEnum_OK_DispatchInline

ObjectEnum_OK_Dispatch:
	ld xwa, NAKA_MODE_MD_PS
	ld (0x03ef82:24), xwa
	ld xwa, TITLE_PS
	ld (0x03ef8a:24), xwa

ObjectEnum_OK_DispatchInline:
	ld xwa, (0x03ef8a:24)
	ld xde, xwa
	srl xde, 16
	and xde, 0xfff
	ldiw_erp 0xe2, 0
	ld (xsp + 8), wa
	ld wa, de
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	add xde, xde
	add xbc, xde
	ld xiz, (xbc + 10)
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, xiz
	ldw (xhl + 18), 0xffff
	ldw (xhl + 20), 0xffff
	ld xwa, 0xffffffff
	ld (xhl + 14), xwa
	ld xde, (0x03ef82:24)
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_CHANGE_MODE
	calr MainFuncCall
	ld xde, (0x03ef8a:24)
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_CHANGE_TITLE
	calr MainFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent
	jr ObjectEnum_Return

ObjectEnum_Default:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, xiz
	ld xde, (xsp + 10)
	calr MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, xiz
	ld xde, (xsp + 10)
	calr MainFuncCall

ObjectEnum_Return:
	ld xhl, 0:i3
	jr GetMode_Epilogue10

; GetMode virtual dispatch via DSP
GetMode_DispatchDSP:
	ld xbc, xiz
	ld xde, (xsp + 10)
	calr ObjectProc

GetMode_Epilogue10:
	pop xiz
	lda xsp, (xsp + 10)
	ret

GetModeNow:
	ld xhl, (0x03ef82:24)
	ret

GetModeOld:
	ld xhl, (0x03ef86:24)
	ret

RegisterMode:
	ld xhl, xwa
	ld xwa, xhl
	sll xwa, 3
	sub xwa, xhl
	add xwa, xwa
	ld xhl, 0x328fc
	add xhl, xwa
	ld (xhl), xbc
	ld (xhl + 4), xde
	ld wa, (xsp + 8)
	ld (xhl + 8), wa
	ld xwa, (xsp + 4)
	ld (xhl + 10), xwa
	retd 0x6

UnregisteredMode:
	ld xbc, xwa
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	ld xbc, 0x328fc
	add xbc, xwa
	ld xwa, NAKA_APFUNC_DefaultFunction
	ld (xbc), xwa
	ld xwa, 0xffffffff
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0xffff
	lda xwa, (Str_No_0x5FE:24)
	ld (xbc + 10), xwa
	ret

RegisterTitle:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xbc, 0x32abc
	add xbc, xhl
	ld (xbc), xiz
	ld xwa, (xsp + 4)
	ld (xbc + 4), xwa
	ld wa, (xsp + 16)
	ld (xbc + 8), wa
	ld xwa, (xsp + 12)
	ld (xbc + 10), xwa
	ld xwa, 0xffffffff
	ld (xbc + 14), xwa
	ldw (xbc + 18), 0xffff
	ldw (xbc + 20), 0xffff
	pop xiz
	inc 4, xsp
	retd 0x6

UnregisteredTitle:
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xbc, 0x32abc
	add xbc, xhl
	ld xwa, NAKA_APFUNC_DefaultFunction
	ld (xbc), xwa
	ld xwa, 0xffffffff
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0xffff
	lda xwa, (Str_No_0x600:24)
	ld (xbc + 10), xwa
	ld xwa, 0xffffffff
	ld (xbc + 14), xwa
	ldw (xbc + 18), 0xffff
	ldw (xbc + 20), 0xffff
	ret

TitleProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld xiz, xbc
	ld (xsp + 34), xwa
	ld xwa, (xsp + 34)
	srl xwa, 16
	and xwa, 0xfff
	ld bc, wa
	ld xwa, (xsp + 34)
	ldiw_erp 0xe2, 0
	ld (xsp + 22), wa
	ld wa, (xsp + 22)
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027ed2:24)
	ld (xsp + 14), xwa
	add xwa, xbc
	lda xwa, (xwa + 10)
	ld (xsp + 24), xwa
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld xde, xiz
	ld wa, (0x02bc30:24)
	and wa, 0x11
	ld (xsp + 28), wa
	cp xiz, EVT_ACTIVATE_STATE
	jrl z, EnumList_HitTest_Match
	cp xiz, EVT_EASY_SET_GO
	jrl z, EnumList_HitTest
	ld xwa, (xsp + 30)
	sll xwa, 3
	sub xwa, (xsp + 30)
	add xwa, xwa
	ld xbc, Str_No_0x602
	add xbc, xwa
	ld xwa, (xbc + 8)
	cp xiz, EVT_EASY_SET_OFF
	jrl z, EnumList_OK_ScrollUp_Wrap
	cp xiz, EVT_EASY_SET_ON
	jrl z, EnumList_OK_ScrollDown_Done
	cp xiz, EVT_SET_NOT_DRAW_FLAG
	jrl z, EnumList_OK_ScrollDown
	cp xiz, EVT_IS_INTERRUPT
	jrl z, EnumList_OK_Next
	cp xiz, EVT_TOGGLE_HOLD
	jrl z, EnumList_Return
	cp xiz, EVT_SET_HOLD
	jrl z, EnumList_Paint
	cp xiz, EVT_CHECK_HOLD
	jrl z, EnumList_Confirm_Forward
	cp xiz, EVT_SET_KEEP
	jrl z, EnumList_ValueChange_A
	cp xiz, EVT_INTERRUPT_HOLD
	jrl z, EnumList_PartChange_B
	cp xiz, EVT_INTERRUPT_EXIT
	jrl z, EnumList_ShowHide_B
	ld wa, (0x02bc32:24)
	exts xwa
	ld (xsp + 18), xwa
	ld wa, (xsp + 28)
	ld (xsp + 28), wa
	cp xiz, EVT_RESET_INTERRUPT_TIME
	jrl z, EnumList_ShowHide_A
	cp xiz, EVT_SET_INTERRUPT_TIME
	jrl z, EnumList_Close
	cp xiz, EVT_SET_RETURN_SCREEN
	jrl z, EnumList_Init_TypeB
	cp xiz, EVT_GET_RETURN_SCREEN
	jrl z, EnumList_Init
	ld xwa, (0x03ef8a:24)
	cp xiz, EVT_RETURN_TITLE
	jrl z, EventDispatch_Return
	cp xiz, EVT_INTERRUPT_TITLE
	jrl z, EventDispatch_OK
	cp xiz, EVT_CHANGE_TITLE
	jrl z, EventDispatch_SelectMatch
	cp xiz, EVT_GET_NAME
	jrl z, EventDispatch_Select
	cp xiz, EVT_GET_INSTANCE
	jr z, EventDispatch_ScanLoop
	cp xiz, EVT_GET_CLASS_SP
	jr z, TitleProc_EventDispatch
	sub xde, EVT_GET_USER_ID
	cp xde, 0x0
	jrl lt, EnumList_Select_Send
	cp xde, 0x5
	jrl gt, EnumList_Select_Send
	add xde, xde
	add xde, TitleProc_Str_j
	ld de, (xde)
	lda xix, (TitleProc_EventDispatch:24)
; Computed jump: target = TitleProc_EventDispatch + TitleProc_Str_j[i], TitleProc_Str_j = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e00030:
;   0x1e00030 -> TitleProc_Evt1E00030
;   0x1e00031 -> TitleProc_Evt1E00031
;   0x1e00032 -> TitleProc_Evt1E00032
;   0x1e00033 -> TitleProc_Evt1E00033
;   0x1e00034 -> TitleProc_Evt1E00034
;   0x1e00035 -> TitleProc_Evt1E00035
	jp	t, (xix+de)

; TitleProc event dispatch
TitleProc_EventDispatch:
	ld xhl, NAKA_CLASS_Title
	jrl TitleFunc_Epilogue34

EventDispatch_ScanLoop:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00031:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl)
	ld xbc, EVT_GET_FUNCTION
	ld xde, 0:i3
	call SendEvent
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00032:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl)
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00033:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl + 4)
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00030:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld hl, (xhl + 8)
	exts xhl
	jrl TitleFunc_Epilogue34

EventDispatch_Select:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl + 10)
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00034:
	ld xhl, (0x03ef8a:24)
	jrl TitleFunc_Epilogue34
TitleProc_Evt1E00035:
	ld xhl, (0x03ef8e:24)
	jrl TitleFunc_Epilogue34

EventDispatch_SelectMatch:
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, EventDispatch_ConfirmHandler

EventDispatch_SelectDone:
	ld xwa, 0xffffffff
	ld xbc, EVT_RETURN_TITLE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (0x03ef8a:24)
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, EventDispatch_SelectDone

EventDispatch_ConfirmHandler:
	ld xwa, (0x03ef8a:24)
	ld (0x03ef8e:24), xwa
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl + 4)
	cp xwa, 0xffffffff
	jr z, EventDispatch_ConfirmSetup
	ld xwa, (xsp + 30)
	ld (0x03ef8a:24), xwa
	jr EventDispatch_ConfirmForward

EventDispatch_ConfirmSetup:
	ld xwa, TITLE_PS
	ld (0x03ef8a:24), xwa

EventDispatch_ConfirmForward:
	ldw (xhl + 18), 0xffff
	ldw (xhl + 20), 0xffff
	ld xwa, 0xffffffff
	ld (xhl + 14), xwa
	ld xde, (0x03ef8a:24)
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_CHANGE_TITLE
	jrl EnumList_OK_CheckHitTest

EventDispatch_OK:
	ld iz, (xsp + 12)
	extz xiz
	ld xwa, xiz
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, xiz
	cpw (xhl + 18), 0xffff
	jrl z, EventDispatch_OKDone
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld wa, (xhl + 18)
	exts xwa
	add xwa, TITLE_PS
	ld (xsp + 8), xwa
	ld wa, (xhl + 20)
	exts xwa
	add xwa, TITLE_PS
	ld (xsp + 18), xwa
	ld xwa, (xsp + 8)
	srl xwa, 16
	and xwa, 0xfff
	ld bc, wa
	ld xwa, (xsp + 8)
	ldiw_erp 0xe2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 14)
	add xwa, xbc
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xbc, (xsp + 18)
	ld wa, bc
	ld (xhl + 20), wa
	cp xbc, 0xffffffff
	jr z, EventDispatch_OKDone
	ld xwa, (xsp + 18)
	srl xwa, 16
	and xwa, 0xfff
	ld bc, wa
	ld xwa, (xsp + 18)
	ldiw_erp 0xe2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 14)
	add xwa, xbc
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xsp + 8)
	ld (xhl + 18), wa

EventDispatch_OKDone:
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld xwa, (0x03ef8a:24)
	ld (0x03ef8e:24), xwa
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl + 4)
	cp xwa, 0xffffffff
	jr z, EventDispatch_Default
	ld xwa, (xsp + 30)
	ld (0x03ef8a:24), xwa
	jr EventDispatch_DefaultProc

EventDispatch_Default:
	ld xwa, TITLE_PS
	ld (0x03ef8a:24), xwa

EventDispatch_DefaultProc:
	ld xwa, (0x03ef8e:24)
	ld (xhl + 18), wa
	ld xwa, (0x03ef8e:24)
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 14)
	add xwa, xbc
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (0x03ef8a:24)
	ld (xhl + 20), wa
	ld xde, (0x03ef8a:24)
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_INTERRUPT_TITLE
	calr MainFuncCall
	ld wa, 1:i3
	calr SetInterruptTime
	ld wa, 2:i3
	calr TitleProc_SetResourceDirtyFlag
	ldw wa, 0x10
	jrl TitleProc_ClearAndReturn

EventDispatch_Return:
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 14)
	add xwa, xbc
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 34)
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	lda xbc, (xhl + 18)
	ld wa, (xbc)
	cp wa, 0xffff
	jrl z, TitleProc_ReturnZero
	ld xwa, (0x03ef8a:24)
	ld (0x03ef8e:24), xwa
	ld wa, (xbc)
	exts xwa
	add xwa, TITLE_PS
	ld (0x03ef8a:24), xwa
	ld xde, xwa
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_RETURN_TITLE
	calr MainFuncCall
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ldw (xhl + 18), 0xffff
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xwa, xhl
	add xwa, (xsp + 4)
	ldw (xwa + 20), 0xffff
	add xhl, (xsp + 4)
	ld xwa, 0xffffffff
	ld (xhl + 14), xwa
	ld xwa, (0x03ef8a:24)
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ldw (xhl + 20), 0xffff
	ld wa, (0x02bc32:24)
	exts xwa
	ld xbc, EVT_RETURN_TITLE
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call KillApTimer
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jrl nz, TitleProc_ReturnZero
	ldw wa, 0x12
	jrl TitleProc_ClearAndReturn

EnumList_Init:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	lda xbc, (xhl + 14)
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr nz, EnumList_Init_CheckType
	ld xwa, (xhl + 4)
	ld (xbc), xwa

EnumList_Init_CheckType:
	ld xhl, (xbc)
	jrl TitleFunc_Epilogue34

EnumList_Init_TypeB:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xsp + 30)
	ld (xhl + 14), xwa
	jrl TitleProc_ReturnZero

EnumList_Close:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jrl nz, TitleProc_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	jrl EnumList_OK_ScrollUp

EnumList_ShowHide_A:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jrl nz, TitleProc_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	jrl TitleProc_ReturnZero

EnumList_ShowHide_B:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jr nz, EnumList_PartChange_A
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	jrl TitleProc_ReturnZero

EnumList_PartChange_A:
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	cp hl, 0:i3
	jrl nz, TitleProc_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	jrl EnumList_OK_ScrollUp

EnumList_PartChange_B:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jrl z, TitleProc_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call KillApTimer
	jrl TitleProc_ReturnZero

EnumList_ValueChange_A:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, EnumList_ValueChange_Done
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, EnumList_ValueChange_B
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call KillApTimer

EnumList_ValueChange_B:
	ldw wa, 0x10
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_ValueChange_Done:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, EnumList_Confirm_Init
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	cp hl, 0:i3
	jr nz, EnumList_Confirm_Init
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call SetApTimer

EnumList_Confirm_Init:
	ldw wa, 0x10
	jrl TitleProc_ClearAndReturn

EnumList_Confirm_Forward:
	ld wa, (0x02bc30:24)
	and wa, 0x1
	cp wa, 0:i3
	scc16 nz, hl
	exts xhl
	jrl TitleFunc_Epilogue34

EnumList_Paint:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, EnumList_Paint_Loop
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, EnumList_Paint_DrawEntry
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call KillApTimer

EnumList_Paint_DrawEntry:
	ld wa, 1:i3
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_Paint_Loop:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, EnumList_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	cp hl, 0:i3
	jr nz, EnumList_ReturnZero
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call SetApTimer

EnumList_ReturnZero:
	ld wa, 1:i3
	jrl TitleProc_ClearAndReturn

EnumList_Return:
	ld wa, (0x02bc30:24)
	bit 0, wa
	jr z, EnumList_OK
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, TitleProc_ToggleFlag
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	cp hl, 0:i3
	jr nz, TitleProc_ToggleFlag
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call SetApTimer
	jr TitleProc_ToggleFlag

EnumList_OK:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	jr z, TitleProc_ToggleFlag
	ld xwa, EVT_RETURN_TITLE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0:i3
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call KillApTimer

TitleProc_ToggleFlag:
	ld de, (0x02bc30:24)
	xor de, 0x1
	ld (0x02bc30:24), de
	extz xde
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_SET_TITLE_FLAG

EnumList_OK_CheckHitTest:
	calr MainFuncCall
	jrl TitleProc_ReturnZero

EnumList_OK_Next:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xffff
	scc16 nz, hl
	extz xhl
	jrl TitleFunc_Epilogue34

EnumList_OK_ScrollDown:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, EnumList_OK_ScrollDown_Wrap
	ld wa, 4:i3
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_OK_ScrollDown_Wrap:
	ld wa, 4:i3
	jrl TitleProc_ClearAndReturn

EnumList_OK_ScrollDown_Done:
	ld xbc, (xbc)
	ld xde, EVT_EASY_SET_GO
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff

EnumList_OK_ScrollUp:
	call SetApTimer
	jrl TitleProc_ReturnZero

EnumList_OK_ScrollUp_Wrap:
	ld xbc, (xbc)
	ld xde, EVT_EASY_SET_GO
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff
	call KillApTimer
	cp hl, 0:i3
	jrl z, TitleProc_ReturnZero

EnumList_OK_ScrollUp_Done:
	ld xwa, (xsp + 30)
	sll xwa, 3
	sub xwa, (xsp + 30)
	add xwa, xwa
	ld xbc, Str_No_0x602
	add xbc, xwa
	ld xwa, (xbc + 8)
	ld xbc, (xbc)
	ld xde, EVT_EASY_SET_GO
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff
	call KillApTimer
	cp hl, 0:i3
	jr nz, EnumList_OK_ScrollUp_Done
	jrl TitleProc_ReturnZero

EnumList_HitTest:
	ld xwa, 0xffffffff
	ld xbc, EVT_EASY_SET_GO
	call DeleteEvent
	ld xbc, (xsp + 30)
	sll xbc, 3
	sub xbc, (xsp + 30)
	add xbc, xbc
	lda xwa, (Str_No_0x606:24)
	add xwa, xbc
	ld xwa, (xwa)
	cp xwa, EVT_CHANGE_TITLE
	jr nz, EnumList_HitTest_Loop
	calr GetModeNow
	cp xhl, NAKA_MODE_MD_NORMAL
	jrl z, TitleProc_ReturnZero

EnumList_HitTest_Loop:
	calr GetModeNow
	cp xhl, NAKA_MODE_MD_DEMO
	jrl z, TitleProc_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent
	ldw wa, 0x20
	calr TitleProc_SetResourceDirtyFlag
	ld xbc, (xsp + 30)
	sll xbc, 3
	sub xbc, (xsp + 30)
	add xbc, xbc
	ld xwa, Str_No_0x602
	add xwa, xbc
	ld xbc, (xwa + 4)
	ld xde, (xwa)
	ld xwa, 0xffffffff
	call SendEvent
	ldw wa, 0x20

TitleProc_ClearAndReturn:
	calr TitleProc_ClearResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_HitTest_Match:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl)
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr MainFuncCall
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr MainFuncCall
	ld xwa, (xsp + 30)
	cp xwa, 0x3
	jr z, EnumList_Select
	cp xwa, 0x2
	jr z, EnumList_HitTest_NoMatch
	cp xwa, 0x8
	jr nz, TitleProc_ReturnZero
	ld xwa, (0x03ef82:24)
	ld (0x03ef86:24), xwa
	ld xwa, (0x03ef8a:24)
	ld (0x03ef8e:24), xwa
	jr TitleProc_ReturnZero

EnumList_HitTest_NoMatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_NEW_TITLE
	ld xde, 0:i3
	call SendEvent
	ld wa, (0x02bc30:24)
	bit 5, wa
	jr z, TitleProc_ReturnZero
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl)
	ld xbc, xiz
	ld xde, 0x9
	calr MainFuncCall
	jr TitleProc_ReturnZero

EnumList_Select:
	ld xwa, 0xffffffff
	ld xbc, EVT_OLD_TITLE
	ld xde, 0:i3
	call SendEvent

TitleProc_ReturnZero:
	ld xhl, 0:i3
	jr TitleFunc_Epilogue34

EnumList_Select_Send:
	ld xwa, (xsp + 34)
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr ObjectProc

TitleFunc_Epilogue34:
	pop xiz
	lda xsp, (xsp + 34)
	ret

GetTitleNow:
	ld xhl, (0x03ef8a:24)
	ret

GetTitleOld:
	ld xhl, (0x03ef8e:24)
	ret

SetInterruptTime:
	pushw iz
	ld iz, wa
	ld wa, (0x02bc30:24)
	bit 1, wa
	jr z, EnumList_Reset
	cp iz, 2:i3
	jr nz, EnumList_Reset
	ld wa, 1:i3
	calr TitleProc_SetResourceDirtyFlag

EnumList_Reset:
	ld wa, iz
	extz xwa
	add xwa, xwa
	ld xbc, Str_No_0x6B6
	add xbc, xwa
	ld wa, (xbc)
	ld (0x02bc32:24), wa
	popw iz
	ret

CheckNotDrawFlag:
	ld wa, (0x02bc30:24)
	and wa, 0x4
	cp wa, 0:i3
	scc16 z, hl
	ret

SetVariFlag:
	cp wa, 0:i3
	jr z, EnumList_Reset_CheckPart
	ldw wa, 0x8
	jr TitleProc_SetResourceDirtyFlag

EnumList_Reset_CheckPart:
	ldw wa, 0x8
	jr TitleProc_ClearResourceDirtyFlag

SetNotDrawFlag:
	cp wa, 0:i3
	jr z, EnumList_Reset_Send
	ld wa, 4:i3
	jr TitleProc_SetResourceDirtyFlag

EnumList_Reset_Send:
	ld wa, 4:i3
	jr TitleProc_ClearResourceDirtyFlag

TitleProc_SetResourceDirtyFlag:
	or (0x02bc30:24), wa
	ld de, (0x02bc30:24)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_SET_TITLE_FLAG
	jrl MainFuncCall

TitleProc_ClearResourceDirtyFlag:
	cpl wa
	and (0x02bc30:24), wa
	ld de, (0x02bc30:24)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_SET_TITLE_FLAG
	jrl MainFuncCall

ResEventProc:
	ld xhl, xwa
	srl xhl, 16
	and xhl, 0xfff
	ld ix, hl
	ld xhl, xwa
	ldiw_erp 0xee, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda xhl, (0x027edc:24)
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, EVT_GET_NAME
	jr z, EnumList_Reset_Return
	cp xbc, EVT_GET_CLASS_SP
	jrl nz, ObjectProc
	ld xhl, NAKA_CLASS_ResEvent
	ret

EnumList_Reset_Return:
	ld wa, iy
	extz xwa
	sll xwa, 2
	add xwa, xhl
	ld xhl, (xwa)
	ret

ResMethodProc:
	ld xhl, xwa
	srl xhl, 16
	and xhl, 0xfff
	ld ix, hl
	ld xhl, xwa
	ldiw_erp 0xee, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda xhl, (0x027edc:24)
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, EVT_GET_NAME
	jr z, ViewableProc_VirtualDispatch
	cp xbc, EVT_GET_CLASS_SP
	jrl nz, ObjectProc
	ld xhl, NAKA_CLASS_ResMethod
	ret

; ViewableProc object dispatch helper
ViewableProc_VirtualDispatch:
	ld wa, iy
	extz xwa
	sll xwa, 2
	add xwa, xhl
	ld xhl, (xwa)
	ret

ViewableProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld xiz, xwa
	ld xiy, (xsp + 20)
	ld (xsp + 6), xiy
	ld xwa, (xsp + 16)
	lda xbc, (xsp + 12)
	cp xiy, EVT_SET_EDIT_SW_RECT
	jrl z, Viewable_GetBoundsY
	cp xiy, EVT_SET_MENU_RECT
	jrl z, Viewable_GetBoundsX
	cp xiy, EVT_SEARCH_LINK
	jrl z, Viewable_MatchClass
	cp xiy, EVT_SEARCH_CLASS
	jrl z, Viewable_Dispatch
	cp xiy, EVT_SET_VISIBLE
	jrl z, Viewable_SetVisible
	cp xiy, EVT_GET_PREVVIEW
	jrl z, Viewable_GetClass
	cp xiy, EVT_GET_NEXTVIEW
	jrl z, Viewable_GetChild
	cp xiy, EVT_GET_SUBVIEW
	jrl z, Viewable_GetOwner
	cp xiy, EVT_GET_SUPERVIEW
	jrl z, Viewable_GetParent
	cp xiy, EVT_GET_INSTANCE
	jrl z, Viewable_GetInstance
	ld xwa, xiz
	lda xde, (0x027ed2:24)
	ld xbc, xiz
	ldiw_erp 0xe6, 0
	ld (xsp + 10), bc
	srl xwa, 16
	and xwa, 0xfff
	ld bc, wa
	add wa, 0x300
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	ld xwa, xde
	add xwa, xhl
	ld xix, (xwa + 10)
	cp xiy, EVT_SET_NAME
	jrl z, Viewable_SetName
	ld hl, (xsp + 10)
	extz xhl
	sll xhl, 2
	ld xwa, xiy
	cp xwa, EVT_GET_NAME
	jrl z, Viewable_GetName
	cp xwa, EVT_DELIVERY_EVENT
	jrl z, Viewable_PostEvent
	cp xwa, EVT_HIDE
	jr z, Viewable_InitClose
	cp xwa, EVT_SHOW
	jr z, Viewable_InitClose
	cp xwa, EVT_GET_CLASS_SP
	jr z, Viewable_GetClassProc
	ld xwa, (xsp + 6)
	sub xwa, EVT_PAINT
	cp xwa, 0x0
	jrl lt, Viewable_DefaultDispatch
	cp xwa, 0x6
	jrl gt, Viewable_DefaultDispatch
	add xwa, xwa
	add xwa, Str_No_0x6D0
	ld wa, (xwa)
	lda xix, (Viewable_GetClassProc:24)
; Computed jump: target = Viewable_GetClassProc + Str_No_0x6D0[i], Str_No_0x6D0 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c0000b:
;   0x1c0000b -> ViewableProc_Evt1C0000B
;   0x1c0000c -> ViewableProc_Evt1C0000C
;   0x1c0000d -> Viewable_ReturnZero
;   0x1c0000e -> Viewable_ReturnZero
;   0x1c0000f -> Viewable_ReturnZero
;   0x1c00010 -> Viewable_DefaultDispatch
;   0x1c00011 -> Viewable_ReturnZero
	jp	t, (xix+wa)

Viewable_GetClassProc:
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xde, xbc
	ld xwa, (xde + 10)
	add xhl, xwa
	ld xwa, (xhl)
	ld xhl, (xwa)
	jrl Viewable_Return

Viewable_InitClose:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_InitClose_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent

Viewable_InitClose_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr Viewable_Show_DispatchTail
ViewableProc_Evt1C0000B:
	ld xwa, xiz
	calr GetVisible
	cp hl, 0:i3
	jr z, Viewable_Show_DispatchChild
	ld xwa, xiz
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_Show_DispatchChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent

Viewable_Show_DispatchChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr Viewable_Show_DispatchTail
ViewableProc_Evt1C0000C:
	ld xwa, xiz
	calr GetVisible
	cp hl, 0:i3
	jr z, Viewable_ReturnZero
	ld xwa, xiz
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_ReturnZero
	ld xbc, EVT_PAINT
	ld xde, (xsp + 16)

Viewable_Show_DispatchTail:
	call SendEvent

Viewable_ReturnZero:
	ld xhl, 0:i3
	jrl Viewable_Return

Viewable_PostEvent:
	ld xde, (xsp + 16)
	cp (xde), xiz
	jr nz, Viewable_PostEvent_ToOwner
	ld xwa, (xde)
	ld xbc, (xde + 4)
	ld xde, (xde + 8)
	call SendEvent
	jrl Viewable_Return

Viewable_PostEvent_ToOwner:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_PostEvent_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl nz, Viewable_Return

Viewable_PostEvent_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jr z, Viewable_ReturnZero
	jrl Viewable_Return

Viewable_GetName:
	add xhl, xix
	ld xhl, (xhl)
	jrl Viewable_Return

Viewable_SetName:
	ld (xsp + 4), xix
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	ld (xsp + 12), hl
	ld wa, (xsp + 14)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 8)
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 8, xsp
	cp hl, (xsp + 8)
	jr nc, Viewable_SetName_Copy
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld wa, (xsp + 10)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	ld (xwa), xhl

Viewable_SetName_Copy:
	ld xwa, (xsp + 16)
	push xwa
	ld wa, (xsp + 14)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 8)
	ld xwa, (xwa)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl Viewable_ReturnZero

Viewable_GetInstance:
	ld xwa, xiz
	calr GetViewInstance
	jrl Viewable_Return

Viewable_GetParent:
	ld xwa, xiz
	calr View_GetParentOffset
	jrl Viewable_Return

Viewable_GetOwner:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	jrl Viewable_Return

Viewable_GetChild:
	ld xwa, xiz
	calr View_GetNextSibling
	jrl Viewable_Return

Viewable_GetClass:
	ld xwa, xiz
	calr View_ResolveInstanceAddr
	jrl Viewable_Return

Viewable_SetVisible:
	ld xbc, (xsp + 16)
	ld xwa, xiz
	calr SetVisible
	jrl Viewable_ReturnZero

Viewable_Dispatch:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jr nz, Viewable_MatchClass_Found
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_Dispatch_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl nz, Viewable_Return

Viewable_Dispatch_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jrl z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl z, Viewable_ReturnZero
	jrl Viewable_Return

Viewable_MatchClass:
	ld xbc, (xsp + 16)
	ld xwa, xiz
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jr z, Viewable_MatchClass_ToOwner

Viewable_MatchClass_Found:
	ld xhl, 1:i3
	jrl Viewable_Return

Viewable_MatchClass_ToOwner:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_MatchClass_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl nz, Viewable_Return

Viewable_MatchClass_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jrl z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl z, Viewable_ReturnZero
	jrl Viewable_Return

Viewable_GetBoundsX:
	call GetEditSwPoint
	ld xwa, xiz
	calr GetViewInstance
	lda xiy, (xsp + 12)
	lda xbc, (xhl + 14)
	lda xde, (xhl + 16)
	lda xix, (xhl + 18)
	lda xhl, (xhl + 20)
	cpw (xiy), 0x0
	jr nz, Viewable_GetBoundsX_Right
	ldw (xbc), 0x8
	ldw (xix), 0x9c
	lda xiz, (xiy + 2)
	ld wa, (xiz)
	sub wa, 0xd
	ld (xde), wa
	ld wa, (xiz)
	add wa, 0xc
	ld (xhl), wa

Viewable_GetBoundsX_Right:
	cpw (xiy), 0x13f
	jrl nz, Viewable_ReturnZero
	ldw (xbc), 0xa3
	ldw (xix), 0x137
	lda xbc, (xiy + 2)
	ld wa, (xbc)
	sub wa, 0xd
	ld (xde), wa
	ld wa, (xbc)
	add wa, 0xc
	ld (xhl), wa
	jrl Viewable_ReturnZero

Viewable_GetBoundsY:
	call GetEditSwPoint
	ld xwa, xiz
	calr GetViewInstance
	lda xiy, (xsp + 12)
	lda xbc, (xhl + 14)
	lda xde, (xhl + 16)
	lda xix, (xhl + 18)
	lda xhl, (xhl + 20)
	cpw (xiy), 0x0
	jr nz, Viewable_GetBoundsY_Right
	lda xiz, (xiy + 2)
	ld wa, (xiz)
	sub wa, 0x9
	ld (xde), wa
	ld wa, (xiz)
	inc 8, wa
	ld (xhl), wa
	ldw (xbc), 0x8
	ldw (xix), 0x26

Viewable_GetBoundsY_Right:
	cpw (xiy), 0x13f
	jr nz, Viewable_GetBoundsY_Bottom
	lda xiz, (xiy + 2)
	ld wa, (xiz)
	sub wa, 0x9
	ld (xde), wa
	ld wa, (xiz)
	inc 8, wa
	ld (xhl), wa
	ldw (xbc), 0x119
	ldw (xix), 0x137

Viewable_GetBoundsY_Bottom:
	cpw (xiy + 2), 0xef
	jrl nz, Viewable_ReturnZero
	ldw (xde), 0xd8
	ldw (xhl), 0xee
	ld wa, (xiy)
	sub wa, 0x10
	ld (xbc), wa
	ld wa, (xiy)
	add wa, 0xf
	ld (xix), wa
	jrl Viewable_ReturnZero

Viewable_DefaultDispatch:
	ld xwa, (xsp + 20)
	srl xwa, 16
	and xwa, 0xfff
	cp wa, 0x1e0
	jr c, Viewable_Default_ToOwner
	cp wa, 0x1ff
	jr ugt, Viewable_Default_ToOwner
	ld xwa, xiz
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr ObjectProc
	jr Viewable_Return

Viewable_Default_ToOwner:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_Default_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jr nz, Viewable_Return

Viewable_Default_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xffffffff
	jrl z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jrl z, Viewable_ReturnZero

Viewable_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

SetChange:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cp iz, 0:i3
	jr z, DrawWidget_Hline_0_Setup
	ormi16 (xwa), 0x4
	jr DrawWidget_Hline_0_Draw

DrawWidget_Hline_0_Setup:
	andmi16 (xwa), 0xfffb

DrawWidget_Hline_0_Draw:
	popw iz
	ret

GetChange:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x4
	cp wa, 0:i3
	scc16 nz, hl
	ret

SetConst:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cp iz, 0:i3
	jr z, DrawWidget_Hline_1_Setup
	ormi16 (xwa), 0x8
	jr DrawWidget_Hline_1_Draw

DrawWidget_Hline_1_Setup:
	andmi16 (xwa), 0xfff7

DrawWidget_Hline_1_Draw:
	popw iz
	ret

GetConst:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x8
	cp wa, 0:i3
	scc16 nz, hl
	ret

SetVisible:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cp iz, 0:i3
	jr z, DrawWidget_Hline_2_Setup
	andmi16 (xwa), 0xfffe
	jr DrawWidget_Hline_2_Draw

DrawWidget_Hline_2_Setup:
	ormi16 (xwa), 0x1

DrawWidget_Hline_2_Draw:
	popw iz
	ret

GetVisible:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x1
	cp wa, 0:i3
	scc16 z, hl
	ret

SetMovable:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cp iz, 0:i3
	jr z, DrawWidget_Hline_3_Setup
	andmi16 (xwa), 0xfffd
	jr DrawWidget_Hline_3_Draw

DrawWidget_Hline_3_Setup:
	ormi16 (xwa), 0x2

DrawWidget_Hline_3_Draw:
	popw iz
	ret

GetMovable:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x2
	cp wa, 0:i3
	scc16 z, hl
	ret

NextView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 8)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_4_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_4_Draw

DrawWidget_Hline_4_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_4_Draw:
	pop xiz
	ret

View_GetNextSibling:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 8)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_5_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_5_Draw

DrawWidget_Hline_5_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_5_Draw:
	pop xiz
	ret

PrevView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 10)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_6_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_6_Draw

DrawWidget_Hline_6_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_6_Draw:
	pop xiz
	ret

View_ResolveInstanceAddr:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 10)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_7_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_7_Draw

DrawWidget_Hline_7_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_7_Draw:
	pop xiz
	ret

SuperView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 4)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_8_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_8_Draw

DrawWidget_Hline_8_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_8_Draw:
	pop xiz
	ret

View_GetParentOffset:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 4)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_9_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_9_Draw

DrawWidget_Hline_9_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_9_Draw:
	pop xiz
	ret

SubView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 6)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_10_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_10_Draw

DrawWidget_Hline_10_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_10_Draw:
	pop xiz
	ret

View_GetSuperViewInstance:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 6)
	cpw (xwa), 0xffff
	jr z, DrawWidget_Hline_11_Setup
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	add xwa, xbc
	ld xhl, xwa
	jr DrawWidget_Hline_11_Draw

DrawWidget_Hline_11_Setup:
	ld xhl, 0xffffffff

DrawWidget_Hline_11_Draw:
	pop xiz
	ret

Link:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xbc
	ld xiz, xwa
	calr View_GetNextSibling
	cp xhl, 0xffffffff
	jr z, DrawWidget_Hline_Return

DrawWidget_Hline_Epilogue:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xiz, xhl
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xffffffff
	jr nz, DrawWidget_Hline_Epilogue

DrawWidget_Hline_Return:
	ld xwa, xiz
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 8), wa
	ld xwa, xiz
	ld bc, 1:i3
	calr SetChange
	ld xwa, xiz
	calr View_GetParentOffset
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld wa, iz
	ld (xhl + 10), wa
	ld xwa, (xsp + 4)
	ld (xhl + 4), wa
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	calr SetChange
	pop xiz
	inc 8, xsp
	ret

Unlink:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	calr View_ResolveInstanceAddr
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	cp xwa, 0xffffffff
	jr z, FrameDraw_TopEdge
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	calr View_GetNextSibling
	ld (xiz + 8), hl
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	calr SetChange
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 10), 0xffff
	ld xwa, (xsp + 12)
	ld bc, 1:i3
	calr SetChange

FrameDraw_TopEdge:
	ld xwa, (xsp + 12)
	calr View_GetNextSibling
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, FrameDraw_BottomEdge
	ld xwa, (xsp + 4)
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 10), wa
	ld xwa, (xsp + 4)
	ld bc, 1:i3
	calr SetChange
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 8), 0xffff
	ld xwa, (xsp + 12)
	ld bc, 1:i3
	calr SetChange

FrameDraw_BottomEdge:
	ld xwa, (xsp + 12)
	calr View_GetParentOffset
	ld xiz, xhl
	cp xiz, 0xffffffff
	jr z, FrameDraw_InnerFill
	ld xwa, xiz
	calr GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	calr View_GetSuperViewInstance
	cp xhl, (xsp + 12)
	jr nz, FrameDraw_CheckInner
	ld xbc, (xsp + 4)
	ld xwa, (xsp + 8)
	ld (xwa + 6), bc
	ld xwa, (xsp + 12)
	ld bc, 1:i3
	calr SetChange

FrameDraw_CheckInner:
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 4), 0xffff
	ld xwa, (xsp + 12)
	ld bc, 1:i3
	calr SetChange

FrameDraw_InnerFill:
	pop xiz
	lda xsp, (xsp + 12)
	ret

SetSuperView:
	dec 8, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 8), xwa
	ld xwa, (xsp + 8)
	calr View_GetParentOffset
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	calr Unlink
	ld xwa, (xsp + 8)

FrameDraw_AltCheckInner:
	calr GetLinkView
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr nz, FrameDraw_Default

FrameDraw_ReturnZero:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr nz, FrameDraw_DefaultInit
	ld xwa, xiz
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 6), wa
	ld xwa, xiz
	ld bc, 1:i3
	calr SetChange
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld wa, iz
	ld (xhl + 4), wa
	ld xwa, (xsp + 8)
	ld bc, 1:i3
	calr SetChange
	jr FrameDraw_DefaultInit_Alt

FrameDraw_Default:
	cp xwa, xiz
	jr nz, FrameDraw_AltCheckInner
	ld xiz, (xsp + 4)
	jr FrameDraw_ReturnZero

FrameDraw_DefaultInit:
	ld xbc, (xsp + 8)
	calr Link

FrameDraw_DefaultInit_Alt:
	pop xiz
	inc 8, xsp
	ret

GetLinkView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr View_GetSuperViewInstance
	cp xhl, 0xffffffff
	jr z, FrameDraw_DefaultCalcWidth
	ld xwa, xiz
	calr View_GetSuperViewInstance
	jr FrameDraw_Return

FrameDraw_DefaultCalcWidth:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xffffffff
	jr z, FrameDraw_DefaultCalcHeight
	ld xwa, xiz
	jr FrameDraw_DefaultReturn

FrameDraw_DefaultCalcHeight:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xffffffff
	jr nz, FrameDraw_DefaultDone

FrameDraw_DefaultSetup:
	ld xwa, xiz
	calr View_GetParentOffset
	ld xiz, xhl
	cp xiz, 0xffffffff
	jr nz, FrameDraw_DefaultExecute
	ld xhl, 0xffffffff
	jr FrameDraw_Return

FrameDraw_DefaultExecute:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xffffffff
	jr z, FrameDraw_DefaultSetup

FrameDraw_DefaultDone:
	ld xwa, xiz

FrameDraw_DefaultReturn:
	calr View_GetNextSibling

FrameDraw_Return:
	pop xiz
	ret

GetViewInstance:
	ld xbc, xwa
	srl xbc, 16
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld de, wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xhl, (xde)
	ret

GetBox:
	push xiz
	ld xiz, xbc
	calr GetViewInstance
	lda xiy, (xhl + 14)
	ld xix, xiz
	ld bc, 4:i3
	ldirw
	pop xiz
	ret

SetBox:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	ld xwa, (xsp + 4)
	ld xiy, xwa
	lda xix, (xhl + 14)
	ld bc, 4:i3
	ldirw
	ld xwa, xiz
	ld bc, 1:i3
	calr SetChange
	pop xiz
	inc 4, xsp
	ret

ResNameProc:
	cp xbc, EVT_GET_CLASS_SP
	jrl nz, ObjectProc
	ld xhl, NAKA_CLASS_ResName
	ret

ResourceProc:
	jrl InheritedProc

ResBitmapProc:
	jrl InheritedProc

ResFrameProc:
	jrl InheritedProc

ResIconProc:
	jrl InheritedProc

ResFontProc:
	jrl InheritedProc

ResStringProc:
	jrl InheritedProc

swordProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle0_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle0_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle0_CalcWidth

BoxStyle0_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

BoxStyle0_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle0_Done

BoxStyle0_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle0_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

BoxStyle0_Execute:
	ld xhl, xiz

BoxStyle0_Done:
	pop xiz
	inc 8, xsp
	ret

uwordProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle1_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle1_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle1_CalcWidth

BoxStyle1_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

BoxStyle1_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle1_Done

BoxStyle1_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle1_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

BoxStyle1_Execute:
	ld xhl, xiz

BoxStyle1_Done:
	pop xiz
	inc 8, xsp
	ret

ucharProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle2_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle2_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle2_CalcWidth

BoxStyle2_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xbc, 0:i3
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

BoxStyle2_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle2_Done

BoxStyle2_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle2_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

BoxStyle2_Execute:
	ld xhl, xiz

BoxStyle2_Done:
	pop xiz
	inc 8, xsp
	ret

scharProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle3_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle3_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle3_CalcWidth

BoxStyle3_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld c, (xhl)
	exts bc
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

BoxStyle3_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle3_Done

BoxStyle3_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle3_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

BoxStyle3_Execute:
	ld xhl, xiz

BoxStyle3_Done:
	pop xiz
	inc 8, xsp
	ret

slongProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle4_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle4_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle4_CalcWidth

BoxStyle4_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc

BoxStyle4_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle4_Done

BoxStyle4_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle4_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

BoxStyle4_Execute:
	ld xhl, xiz

BoxStyle4_Done:
	pop xiz
	inc 8, xsp
	ret

ulongProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle5_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle5_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle5_CalcWidth

BoxStyle5_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc

BoxStyle5_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle5_Done

BoxStyle5_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle5_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

BoxStyle5_Execute:
	ld xhl, xiz

BoxStyle5_Done:
	pop xiz
	inc 8, xsp
	ret

boolProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, BoxStyle6_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, BoxStyle6_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, BoxStyle6_CalcWidth

BoxStyle6_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

BoxStyle6_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr BoxStyle6_Done

BoxStyle6_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle6_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

BoxStyle6_Execute:
	ld xhl, xiz

BoxStyle6_Done:
	pop xiz
	inc 8, xsp
	ret

pBoolProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle7_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle7_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle7_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle7_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle7_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld wa, (xwa)
	ld (xhl), wa
	jr BoxStyle7_InnerFill

BoxStyle7_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x6DE
	jr BoxStyle7_CheckInner

BoxStyle7_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle7_CalcWidth_Str_Fmts_Fmtd

BoxStyle7_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle7_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle7_DoneAlt

BoxStyle7_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle7_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle7_DoneAlt

BoxStyle7_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle7_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle7_Done:
	ld xhl, xiz

BoxStyle7_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pSwordProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle8_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle8_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle8_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle8_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle8_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld wa, (xwa)
	ld (xhl), wa
	jr BoxStyle8_InnerFill

BoxStyle8_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x6EE
	jr BoxStyle8_CheckInner

BoxStyle8_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle8_CalcWidth_Str_Fmts_Fmtd

BoxStyle8_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle8_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle8_DoneAlt

BoxStyle8_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle8_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle8_DoneAlt

BoxStyle8_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle8_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle8_Done:
	ld xhl, xiz

BoxStyle8_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pUwordProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle9_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle9_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle9_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle9_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle9_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld wa, (xwa)
	ld (xhl), wa
	jr BoxStyle9_InnerFill

BoxStyle9_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x700
	jr BoxStyle9_CheckInner

BoxStyle9_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle9_CalcWidth_Str_Fmts_Fmtd

BoxStyle9_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle9_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle9_DoneAlt

BoxStyle9_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	extz xbc
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle9_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle9_DoneAlt

BoxStyle9_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle9_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle9_Done:
	ld xhl, xiz

BoxStyle9_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pScharProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle10_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle10_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle10_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle10_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle10_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld a, (xwa)
	ld (xhl), a
	jr BoxStyle10_InnerFill

BoxStyle10_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x712
	jr BoxStyle10_CheckInner

BoxStyle10_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle10_CalcWidth_Str_Fmts_Fmtd

BoxStyle10_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle10_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle10_DoneAlt

BoxStyle10_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld c, (xwa)
	exts bc
	exts xbc
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle10_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle10_DoneAlt

BoxStyle10_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle10_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

BoxStyle10_Done:
	ld xhl, xiz

BoxStyle10_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pUcharProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle11_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle11_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle11_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle11_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle11_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld a, (xwa)
	ld (xhl), a
	jr BoxStyle11_InnerFill

BoxStyle11_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x724
	jr BoxStyle11_CheckInner

BoxStyle11_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle11_CalcWidth_Str_Fmts_Fmtd

BoxStyle11_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle11_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle11_DoneAlt

BoxStyle11_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld xbc, 0:i3
	ld c, (xwa)
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle11_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle11_DoneAlt

BoxStyle11_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle11_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

BoxStyle11_Done:
	ld xhl, xiz

BoxStyle11_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pSlongProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle12_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle12_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle12_CalcWidth
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle12_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle12_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xwa, (xwa)
	ld (xhl), xwa
	jr BoxStyle12_InnerFill

BoxStyle12_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x736
	jr BoxStyle12_CheckInner

BoxStyle12_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle12_CalcWidth_Str_Fmts_Fmtd

BoxStyle12_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle12_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle12_DoneAlt

BoxStyle12_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

BoxStyle12_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle12_DoneAlt

BoxStyle12_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle12_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

BoxStyle12_Done:
	ld xhl, xiz

BoxStyle12_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

pUlongProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, BoxStyle13_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, BoxStyle13_CalcHeight
	lda xhl, (xsp + 8)
	ld XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, BoxStyle13_CalcWidth
	lda xde, (xwa + 8)
	cp xiz, EVT_DUMP_POINTER_EX
	jr z, BoxStyle13_Setup
	cp xiz, EVT_COPY_PROPERTY_EX
	jrl nz, BoxStyle13_CalcHeight2
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld XBC, (xsp + 0x0108)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld xiz, xhl
	pushw 0x4
	call Malloc
	inc 2, xsp
	ld (xiz), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xwa, (xwa)
	ld (xhl), xwa
	jr BoxStyle13_InnerFill

BoxStyle13_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x748
	jr BoxStyle13_CheckInner

BoxStyle13_CalcWidth:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	ld xbc, EVT_GET_PROP_NAME
	ld XDE, (xsp + 0x0108)
	call SendEvent
	ld XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, BoxStyle13_CalcWidth_Str_Fmts_Fmtd

BoxStyle13_CheckInner:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

BoxStyle13_InnerFill:
	ld xhl, 0:i3
	jr BoxStyle13_DoneAlt

BoxStyle13_CalcHeight:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

BoxStyle13_CalcHeight2:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle13_DoneAlt

BoxStyle13_Execute:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle13_Done
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

BoxStyle13_Done:
	ld xhl, xiz

BoxStyle13_DoneAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

RECTWProc:
	lda xsp, (xsp - 128)
	push xiz
	cp xbc, EVT_CHECK_PROP_STRING
	jr z, EdgeDraw_TopLeft
	calr CommonIDProc
	jr EdgeDraw_TopRight

EdgeDraw_TopLeft:
	ld xiz, xde
	push xiz
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld ix, 0:i3
	ld iy, 0:i3
	lda xhl, (xsp + 4)
	ld xde, 0:i3
	jr EdgeDraw_TopLeft_Return

EdgeDraw_TopLeft_Inner:
	cp c, 0x50
	jr nz, EdgeDraw_TopLeft_Done
	ld (xwa), 0x51
	inc 1, ix
	ld wa, ix
	extz xwa
	add xwa, xiz
	ld (xwa), 0x52
	inc 1, ix
	ld wa, ix
	extz xwa
	add xwa, xiz
	ld (xwa), 0x53
	inc 1, ix
	ld wa, ix
	extz xwa
	add xwa, xiz
	ld (xwa), 0x54
	jr EdgeDraw_TopLeft_Finish

EdgeDraw_TopLeft_Done:
	ld (xwa), c

EdgeDraw_TopLeft_Finish:
	inc 1, iy
	inc 1, xde
	inc 1, ix

EdgeDraw_TopLeft_Return:
	ld xwa, xde
	ld xbc, xhl
	add xbc, xwa
	ld wa, ix
	extz xwa
	ld c, (xbc)
	add xwa, xiz
	cp c, 0:i3
	jr nz, EdgeDraw_TopLeft_Inner
	ld (xwa), 0x0
	ld xhl, 0:i3

EdgeDraw_TopRight:
	pop xiz
	lda xsp, (xsp+128:16)
	ret

RectX1Proc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+264), xde
	ld xiz, xbc
	ld	(xsp+268), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, EdgeDraw_BottomLeft_Draw
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, EdgeDraw_BottomLeft_Inner
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, EdgeDraw_BottomLeft_Inner
	cp xiz, EVT_MAKE_DUMP
	jr z, EdgeDraw_TopRight_Done
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, EdgeDraw_TopRight_Inner
	cp xiz, EVT_CHECK_PROP_STRING
	jr z, EdgeDraw_BottomLeft
	jr EdgeDraw_BottomLeft_Done

EdgeDraw_TopRight_Inner:
	pushw EdgeDraw_TopRight_Inner_Str_left@hi16
	pushw EdgeDraw_TopRight_Inner_Str_left@lo16
	ld XWA, (xsp + 0x010c)
	push xwa
	call Strcat
	inc 8, xsp
	jr EdgeDraw_BottomLeft

EdgeDraw_TopRight_Done:
	pushw EdgeDraw_TopRight_Inner_Str_LBrace@hi16
	pushw EdgeDraw_TopRight_Inner_Str_LBrace@lo16
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xwa, (xsp + 24)
	push xwa
	ld XWA, (xsp + 0x011c)
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)

EdgeDraw_BottomLeft:
	ld xhl, 0:i3
	jr EdgeDraw_BottomLeft_FinishAlt

EdgeDraw_BottomLeft_Inner:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld XWA, (xsp + 0x0108)
	ld (xwa), xbc

EdgeDraw_BottomLeft_Done:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr EdgeDraw_BottomLeft_FinishAlt

EdgeDraw_BottomLeft_Draw:
	ld XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, EdgeDraw_BottomLeft_Finish
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, xhl
	inc 4, xbc
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld de, wa
	sub de, (xhl)
	ld (xhl), wa
	ld wa, (xbc)
	add wa, de
	ld (xbc), wa

EdgeDraw_BottomLeft_Finish:
	ld xhl, (xsp + 4)

EdgeDraw_BottomLeft_FinishAlt:
	pop xiz
	lda xsp, (xsp+268)
	ret

RectY1Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, EdgeDraw_BottomRight_Done
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, EdgeDraw_BottomRight_Check
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, EdgeDraw_BottomRight_Check
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, EdgeDraw_BottomRight
	cp xiz, EVT_CHECK_PROP_STRING
	jr z, EdgeDraw_BottomRight_Inner
	jr EdgeDraw_BottomRight_Draw

EdgeDraw_BottomRight:
	pushw EdgeDraw_BottomRight_Str_top@hi16
	pushw EdgeDraw_BottomRight_Str_top@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp

EdgeDraw_BottomRight_Inner:
	ld xhl, 0:i3
	jr EdgeDraw_BottomRight_FinishAlt

EdgeDraw_BottomRight_Check:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

EdgeDraw_BottomRight_Draw:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr EdgeDraw_BottomRight_FinishAlt

EdgeDraw_BottomRight_Done:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, EdgeDraw_BottomRight_Finish
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld xbc, xhl
	inc 4, xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	ld de, wa
	sub de, (xhl)
	ld (xhl), wa
	ld wa, (xbc)
	add wa, de
	ld (xbc), wa

EdgeDraw_BottomRight_Finish:
	ld xhl, (xsp + 4)

EdgeDraw_BottomRight_FinishAlt:
	pop xiz
	lda xsp, (xsp + 12)
	ret

RectX2Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, TabDraw_TopEdge_Done
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, TabDraw_TopEdge_CalcHeight
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, TabDraw_TopEdge_Inner
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, TabDraw_TopEdge
	cp xiz, EVT_CHECK_PROP_STRING
	jr nz, TabDraw_TopEdge_CalcWidth
	jr TabDraw_TopEdge_Execute

TabDraw_TopEdge:
	pushw TabDraw_TopEdge_Str_width@hi16
	pushw TabDraw_TopEdge_Str_width@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	jr TabDraw_TopEdge_Execute

TabDraw_TopEdge_Inner:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

TabDraw_TopEdge_CalcWidth:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr TabDraw_BottomEdge_Prologue

TabDraw_TopEdge_CalcHeight:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	pushw 0xa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 4)
	push xwa
	ld wa, (xhl)
	sub wa, (xbc)
	inc 1, wa
	pushw wa
	call Itoa_Safe
	inc 8, xsp

TabDraw_TopEdge_Execute:
	ld xhl, 0:i3
	jr TabDraw_BottomEdge_Prologue

TabDraw_TopEdge_Done:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, TabDraw_BottomEdge
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	add wa, (xbc)
	dec 1, wa
	ld (xhl), wa

TabDraw_BottomEdge:
	ld xhl, (xsp + 4)

TabDraw_BottomEdge_Prologue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

RectY2Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, EdgeVariant_A_Return
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, EdgeVariant_A_Execute
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, EdgeVariant_A_CalcHeight
	cp xiz, EVT_MAKE_DUMP
	jr z, EdgeVariant_A_CalcWidth
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, EdgeVariant_A_Setup
	cp xiz, EVT_CHECK_PROP_STRING
	jr nz, EdgeVariant_A_CalcHeight2
	jr EdgeVariant_A_Done

EdgeVariant_A_Setup:
	pushw EdgeVariant_A_Setup_Str_height@hi16
	pushw EdgeVariant_A_Setup_Str_height@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	ld xhl, 1:i3
	jr POINTWProc_Return

EdgeVariant_A_CalcWidth:
	pushw EdgeVariant_A_CalcWidth_Str_RBrace@hi16
	pushw EdgeVariant_A_CalcWidth_Str_RBrace@lo16
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	jr EdgeVariant_A_Done

EdgeVariant_A_CalcHeight:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

EdgeVariant_A_CalcHeight2:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr POINTWProc_Return

EdgeVariant_A_Execute:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	pushw 0xa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 4)
	push xwa
	ld wa, (xhl)
	sub wa, (xbc)
	inc 1, wa
	pushw wa
	call Itoa_Safe
	inc 8, xsp

EdgeVariant_A_Done:
	ld xhl, 0:i3
	jr POINTWProc_Return

EdgeVariant_A_Return:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, EdgeVariant_B_Setup
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	add wa, (xbc)
	dec 1, wa
	ld (xhl), wa

EdgeVariant_B_Setup:
	ld xhl, (xsp + 4)

POINTWProc_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

POINTWProc:
	lda xsp, (xsp-132)
	pushw iz
	ld	(xsp+130), xde
	cp xbc, EVT_CHECK_PROP_STRING
	jr z, EdgeVariant_B_CalcWidth
	ld	xde, (xsp+130)
	calr CommonIDProc
	jr EdgeVariant_C_Setup

EdgeVariant_B_CalcWidth:
	ld	xwa, (xsp+130)
	push xwa
	lda xwa, (xsp + 6)
	push xwa
	call Strcpy
	inc 8, xsp
	ld iy, 0:i3
	ld iz, 0:i3
	lda xix, (xsp + 2)
	ld xbc, 0:i3
	jr EdgeVariant_B_Return

EdgeVariant_B_CalcHeight:
	cp a, 0x55
	jr nz, EdgeVariant_B_Done
	ld (xde), 0x56
	inc 1, iy
	ld wa, iy
	extz xwa
	add	xwa, (xsp+130)
	ld (xwa), 0x57
	jr EdgeVariant_B_DoneAlt

EdgeVariant_B_Done:
	ld (xde), a

EdgeVariant_B_DoneAlt:
	inc 1, iz
	inc 1, xbc
	inc 1, iy

EdgeVariant_B_Return:
	ld xwa, xbc
	ld xhl, xix
	add xhl, xwa
	ld de, iy
	extz xde
	add	xde, (xsp+130)
	ld a, (xhl)
	cp a, 0:i3
	jr nz, EdgeVariant_B_CalcHeight
	ld (xde), 0x0
	ld xhl, 0:i3

EdgeVariant_C_Setup:
	popw iz
	lda xsp, (xsp+132:16)
	ret

PointXProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+260), xde
	ld xiz, xbc
	ld	(xsp+264), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, EdgeVariant_C_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, EdgeVariant_C_InnerFill
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, EdgeVariant_C_InnerFill
	cp xiz, EVT_MAKE_DUMP
	jr z, EdgeVariant_C_CalcHeight
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, EdgeVariant_C_CalcWidth
	cp xiz, EVT_CHECK_PROP_STRING
	jr z, EdgeVariant_C_CheckInner
	jr EdgeVariant_C_CalcHeight2

EdgeVariant_C_CalcWidth:
	pushw EdgeVariant_C_CalcWidth_Str_x@hi16
	pushw EdgeVariant_C_CalcWidth_Str_x@lo16
	ld XWA, (xsp + 0x0108)
	push xwa
	call Strcat
	inc 8, xsp
	jr EdgeVariant_C_CheckInner

EdgeVariant_C_CalcHeight:
	pushw EdgeVariant_C_CalcHeight_Str_LBrace@hi16
	pushw EdgeVariant_C_CalcHeight_Str_LBrace@lo16
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x010c)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcat
	lda xwa, (xsp + 20)
	push xwa
	ld XWA, (xsp + 0x0118)
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)

EdgeVariant_C_CheckInner:
	ld xhl, 0:i3
	jr EdgeVariant_C_Return

EdgeVariant_C_InnerFill:
	ld XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld XWA, (xsp + 0x0104)
	ld (xwa), xbc

EdgeVariant_C_CalcHeight2:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	calr CommonIDProc
	jr EdgeVariant_C_Return

EdgeVariant_C_Execute:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, EdgeVariant_C_Done
	ld XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld XWA, (xsp + 0x0104)
	ld xwa, (xwa + 4)
	ld (xhl), wa

EdgeVariant_C_Done:
	ld xhl, xiz

EdgeVariant_C_Return:
	pop xiz
	lda xsp, (xsp+264)
	ret

PointYProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, ShadowBox_A_Execute
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, ShadowBox_A_InnerFill
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, ShadowBox_A_InnerFill
	cp xiz, EVT_MAKE_DUMP
	jr z, ShadowBox_A_CalcWidth
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, ShadowBox_A_Setup
	cp xiz, EVT_CHECK_PROP_STRING
	jr z, ShadowBox_A_CheckInner
	jr ShadowBox_A_CalcHeight

ShadowBox_A_Setup:
	pushw ShadowBox_A_Setup_Str_y@hi16
	pushw ShadowBox_A_Setup_Str_y@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcat
	inc 8, xsp
	ld xhl, 1:i3
	jr IDCursorProc_Return

ShadowBox_A_CalcWidth:
	pushw ShadowBox_A_CalcWidth_Str_RBrace@hi16
	pushw ShadowBox_A_CalcWidth_Str_RBrace@lo16
	ld xwa, (xsp + 8)
	push xwa
	call Strcat
	inc 8, xsp

ShadowBox_A_CheckInner:
	ld xhl, 0:i3
	jr IDCursorProc_Return

ShadowBox_A_InnerFill:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

ShadowBox_A_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr IDCursorProc_Return

ShadowBox_A_Execute:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, ShadowBox_A_Done
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

ShadowBox_A_Done:
	ld xhl, xiz

IDCursorProc_Return:
	pop xiz
	inc 8, xsp
	ret

ClassIDProc:
	lda xsp, (xsp-4372)
	push xiz
	ld	(xsp+4368), xde
	ld xiz, xbc
	ld	(xsp+4372), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, ShadowBox_A_Return
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ShadowBox_A_Return
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, ShadowBox_A_DrawEdge

ShadowBox_A_Return:
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld xwa, 0x160
	ld (xsp + 8), xwa

ShadowBox_A_CheckAlt:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	ld xde, 0:i3
	cp xhl, 0x0
	jr ule, ShadowBox_A_DrawInner

ShadowBox_A_DrawAlt:
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, xde
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, ShadowBox_A_DrawAlt

ShadowBox_A_DrawInner:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x17f
	jr ule, ShadowBox_A_CheckAlt

ShadowBox_A_DrawEdge:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, ShadowBox_B_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, ShadowBox_B_CalcWidth
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, ShadowBox_B_CalcWidth
	cp xiz, EVT_MAKE_DUMP
	jr z, ShadowBox_B_Prologue
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ShadowBox_B_Setup
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, ShadowBox_C_Return
	ld XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	jr ShadowBox_B_CheckInner

ShadowBox_B_Setup:
	ld xhl, (xsp + 12)
	jrl ViewFlagProc_Return

ShadowBox_B_Prologue:
	pushw ShadowBox_B_Prologue_Str_idc@hi16
	pushw ShadowBox_B_Prologue_Str_idc@lo16
	lda xwa, (xsp + 20)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x1118)
	push xwa
	lda xwa, (xsp + 28)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 16)
	push xwa
	ld XWA, (xsp + 0x1114)
	push xwa
	jr ShadowBox_B_InnerFill

ShadowBox_B_CalcWidth:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3

ShadowBox_B_CheckInner:
	call ClassProc
	push xhl
	ld xwa, (xiz + 4)
	push xwa

ShadowBox_B_InnerFill:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jrl ViewFlagProc_Return

ShadowBox_B_CalcHeight:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, ShadowBox_C_CalcWidth

ShadowBox_B_Execute:
	ld xwa, (xiz + 4)
	push xwa
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ClassProc
	push xhl
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, ShadowBox_C_Setup
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr ShadowBox_C_CalcHeight

ShadowBox_C_Setup:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, ShadowBox_B_Execute

ShadowBox_C_CalcWidth:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, ShadowBox_C_Execute

ShadowBox_C_CalcHeight:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

ShadowBox_C_Execute:
	ld xhl, (xsp + 4)
	jr ViewFlagProc_Return

ShadowBox_C_Return:
	ld XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld XDE, (xsp + 0x1110)
	calr CommonIDProc

ViewFlagProc_Return:
	pop xiz
	lda xsp, (xsp+4372)
	ret

ViewFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_A_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_A_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_A_CalcWidth

FrameVariant_A_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_A_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_A_Done

FrameVariant_A_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_A_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_A_Execute:
	ld xhl, xiz

FrameVariant_A_Done:
	pop xiz
	inc 8, xsp
	ret

ColorIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_B_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_B_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_B_CalcWidth

FrameVariant_B_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_B_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_B_Done

FrameVariant_B_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_B_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_B_Execute:
	ld xhl, xiz

FrameVariant_B_Done:
	pop xiz
	inc 8, xsp
	ret

BorderIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_C_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_C_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_C_CalcWidth

FrameVariant_C_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_C_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_C_Done

FrameVariant_C_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_C_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_C_Execute:
	ld xhl, xiz

FrameVariant_C_Done:
	pop xiz
	inc 8, xsp
	ret

AlignmentIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_D_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_D_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_D_CalcWidth

FrameVariant_D_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xbc, 0:i3
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_D_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_D_Done

FrameVariant_D_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_D_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

FrameVariant_D_Execute:
	ld xhl, xiz

FrameVariant_D_Done:
	pop xiz
	inc 8, xsp
	ret

EditSwStyleIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_E_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_E_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_E_CalcWidth

FrameVariant_E_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xbc, 0:i3
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_E_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_E_Done

FrameVariant_E_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_E_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

FrameVariant_E_Execute:
	ld xhl, xiz

FrameVariant_E_Done:
	pop xiz
	inc 8, xsp
	ret

EditSwIDProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_MAKE_EDIT_SW_ID
	jr z, FrameVariant_F_CheckAlt
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_F_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_F_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_F_CalcWidth

FrameVariant_F_Setup:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

FrameVariant_F_CalcWidth:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr FrameVariant_F_Return

FrameVariant_F_CalcHeight:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, FrameVariant_F_Execute
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_F_Execute:
	ld xhl, (xsp + 4)
	jr FrameVariant_F_Return

FrameVariant_F_CheckAlt:
	ld xwa, (xsp + 8)
	ld bc, wa
	ld hl, bc
	sub hl, 0x80
	cp xwa, 0x80
	jr c, FrameVariant_F_DrawAlt
	cp xwa, 0x87
	jr ule, FrameVariant_F_Done

FrameVariant_F_DrawAlt:
	ld xwa, (xsp + 8)
	cp xwa, 0x90
	jr nz, FrameVariant_F_DoneAlt

FrameVariant_F_Done:
	jr FrameVariant_F_DoneAlt2

FrameVariant_F_DoneAlt:
	ld hl, bc

FrameVariant_F_DoneAlt2:
	extz xhl

FrameVariant_F_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

LineModeIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_G_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_G_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_G_CalcWidth

FrameVariant_G_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xbc, 0:i3
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_G_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_G_Done

FrameVariant_G_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_G_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

FrameVariant_G_Execute:
	ld xhl, xiz

FrameVariant_G_Done:
	pop xiz
	inc 8, xsp
	ret

FrameIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_H_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_H_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_H_CalcWidth

FrameVariant_H_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_H_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_H_Done

FrameVariant_H_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_H_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_H_Execute:
	ld xhl, xiz

FrameVariant_H_Done:
	pop xiz
	inc 8, xsp
	ret

UserIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_I_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_I_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_I_CalcWidth

FrameVariant_I_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_I_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_I_Done

FrameVariant_I_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_I_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_I_Execute:
	ld xhl, xiz

FrameVariant_I_Done:
	pop xiz
	inc 8, xsp
	ret

PartIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_J_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_J_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_J_CalcWidth

FrameVariant_J_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_J_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_J_Done

FrameVariant_J_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_J_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_J_Execute:
	ld xhl, xiz

FrameVariant_J_Done:
	pop xiz
	inc 8, xsp
	ret

TrackIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_K_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_K_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_K_CalcWidth

FrameVariant_K_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_K_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_K_Done

FrameVariant_K_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_K_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_K_Execute:
	ld xhl, xiz

FrameVariant_K_Done:
	pop xiz
	inc 8, xsp
	ret

IntTimeIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, FrameVariant_L_CalcHeight
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, FrameVariant_L_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr nz, FrameVariant_L_CalcWidth

FrameVariant_L_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

FrameVariant_L_CalcWidth:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr FrameVariant_L_Done

FrameVariant_L_CalcHeight:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, FrameVariant_L_Execute
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

FrameVariant_L_Execute:
	ld xhl, xiz

FrameVariant_L_Done:
	pop xiz
	inc 8, xsp
	ret

StringProc:
	lda xsp, (xsp-314)
	push xiz
	ld	(xsp+314), xde
	ld XDE, (xsp + 0x013a)
	inc 4, xde
	cp xbc, EVT_SET_PROPERTY_EX
	jrl z, ScrollBar_Draw
	cp xbc, EVT_GET_PROPERTY_EX
	jrl z, ScrollBar_CalcThumb
	cp xbc, EVT_DUMP_PROPERTY_EX
	jrl z, ScrollBar_CalcThumb
	cp xbc, EVT_MAKE_DUMP
	jr z, ScrollBar_CalcRange
	cp xbc, EVT_COPY_PROPERTY_EX
	jr z, ScrollBar_Setup
	ld XDE, (xsp + 0x013a)
	calr CommonIDProc
	jrl ScrollBar_Return

ScrollBar_Setup:
	ld xwa, (xde)
	ld XBC, (xsp + 0x013a)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld (xsp + 6), xhl
	ld XBC, (xsp + 0x013a)
	ld xwa, (xbc)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld (xsp + 10), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld xwa, (xsp + 10)
	ld (xwa), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa)
	push xwa
	ld xwa, (xsp + 14)
	jrl ScrollBar_ReturnAlt

ScrollBar_CalcRange:
	pushw ScrollBar_CalcRange_Str_DQuote@hi16
	pushw ScrollBar_CalcRange_Str_DQuote@lo16
	lda xwa, (xsp + 18)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x0142)
	push xwa
	lda xwa, (xsp + 26)
	push xwa
	call Strcat
	pushw ScrollBar_CalcRange_Str_DQuote_2@hi16
	pushw ScrollBar_CalcRange_Str_DQuote_2@lo16
	lda xwa, (xsp + 34)
	push xwa
	call Strcat
	lda xsp, (xsp + 24)
	lda xwa, (xsp + 14)
	push xwa
	ld XWA, (xsp + 0x013e)
	push xwa
	jr ScrollBar_ReturnAlt2

ScrollBar_CalcThumb:
	ld XWA, (xsp + 0x013a)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld XWA, (xsp + 0x013a)
	ld (xwa+), XBC
	push xbc
	jr ScrollBar_ReturnAlt

ScrollBar_Draw:
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x013a)
	calr IDCursorAdvance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xiz, (xwa)
	ld xwa, (xsp + 4)
	push xwa
	call Strlen
	ld (xsp + 16), hl
	push xiz
	call Strlen
	inc 8, xsp
	cp hl, (xsp + 12)
	jr nc, ScrollBar_ReturnZero
	ld xwa, (xsp + 4)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld xwa, (xsp + 8)
	ld (xwa), xhl

ScrollBar_ReturnZero:
	ld xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 12)

ScrollBar_ReturnAlt:
	ld xwa, (xwa)
	push xwa

ScrollBar_ReturnAlt2:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3

ScrollBar_Return:
	pop xiz
	lda xsp, (xsp+314)
	ret

FontIDProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+264), xde
	cp xbc, EVT_SET_PROPERTY_EX
	jrl z, SliderH_DrawTrack
	cp xbc, EVT_GET_PROPERTY_EX
	jr z, SliderH_CalcRange
	cp xbc, EVT_DUMP_PROPERTY_EX
	jr z, SliderH_CalcRange
	cp xbc, EVT_MAKE_DUMP
	jr z, SliderH_Prologue
	cp xbc, EVT_GET_PROP_DATA_COUNT_SP
	jr z, SliderH_Setup
	cp xbc, EVT_GET_PROP_DATA_SP
	jrl nz, SliderH_ReturnAlt4
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, 0x3efac
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr SliderH_CalcThumb

SliderH_Setup:
	ld hl, (NakaData_WidgetNames_0x624:24)
	exts xhl
	jrl SliderH_ReturnAlt5

SliderH_Prologue:
	pushw SliderH_Prologue_Str_id@hi16
	pushw SliderH_Prologue_Str_id@lo16
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld XWA, (xsp + 0x010c)
	push xwa
	jr SliderH_CalcThumb_Clamp

SliderH_CalcRange:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, 0x3efac
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

SliderH_CalcThumb:
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

SliderH_CalcThumb_Clamp:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr SliderH_ReturnAlt5

SliderH_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld xiz, 0:i3
	jr SliderH_ReturnAlt

SliderH_DrawThumb:
	push xwa
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, SliderH_ReturnZero
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr SliderH_ReturnAlt2

SliderH_ReturnZero:
	inc 1, xiz

SliderH_ReturnAlt:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0x3efac
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, SliderH_DrawThumb
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, SliderH_ReturnAlt3

SliderH_ReturnAlt2:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

SliderH_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr SliderH_ReturnAlt5

SliderH_ReturnAlt4:
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc

SliderH_ReturnAlt5:
	pop xiz
	lda xsp, (xsp+264)
	ret

IconIDProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+264), xde
	cp xbc, EVT_SET_PROPERTY_EX
	jrl z, SliderV_DrawTrack
	cp xbc, EVT_GET_PROPERTY_EX
	jr z, SliderV_CalcRange
	cp xbc, EVT_DUMP_PROPERTY_EX
	jr z, SliderV_CalcRange
	cp xbc, EVT_MAKE_DUMP
	jr z, SliderV_Prologue
	cp xbc, EVT_GET_PROP_DATA_COUNT_SP
	jr z, SliderV_Setup
	cp xbc, EVT_GET_PROP_DATA_SP
	jrl nz, SliderV_Return
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, IconIDProc_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr SliderV_CalcThumb

SliderV_Setup:
	ld hl, (Str_InitializeRoot_0x10:24)
	extz xhl
	jrl BitmapIDProc_Return

SliderV_Prologue:
	pushw SliderV_Prologue_Str_idICON@hi16
	pushw SliderV_Prologue_Str_idICON@lo16
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld XWA, (xsp + 0x010c)
	push xwa
	jr SliderV_CalcThumb_Clamp

SliderV_CalcRange:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, IconIDProc_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

SliderV_CalcThumb:
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

SliderV_CalcThumb_Clamp:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr BitmapIDProc_Return

SliderV_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld xiz, 0:i3
	jr SliderV_ReturnAlt

SliderV_DrawThumb:
	push xwa
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, SliderV_ReturnZero
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr SliderV_ReturnAlt2

SliderV_ReturnZero:
	inc 1, xiz

SliderV_ReturnAlt:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, IconIDProc_PtrTable
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, SliderV_DrawThumb
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, SliderV_ReturnAlt3

SliderV_ReturnAlt2:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

SliderV_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr BitmapIDProc_Return

SliderV_Return:
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc

BitmapIDProc_Return:
	pop xiz
	lda xsp, (xsp+264)
	ret

BitmapIDProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+264), xde
	cp xbc, EVT_SET_PROPERTY_EX
	jrl z, DrawHelper_A_DrawTrack
	cp xbc, EVT_GET_PROPERTY_EX
	jr z, DrawHelper_A_CalcRange
	cp xbc, EVT_DUMP_PROPERTY_EX
	jr z, DrawHelper_A_CalcRange
	cp xbc, EVT_MAKE_DUMP
	jr z, DrawHelper_A_Prologue
	cp xbc, EVT_GET_PROP_DATA_COUNT_SP
	jr z, DrawHelper_A_Setup
	cp xbc, EVT_GET_PROP_DATA_SP
	jrl nz, DrawHelper_A_Return
	ld XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, BitmapIDProc_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr DrawHelper_A_CalcThumb

DrawHelper_A_Setup:
	ld hl, (DrawHelper_A_Setup_Str_DQuote:24)
	extz xhl
	jrl ApFuncIDProc_Return

DrawHelper_A_Prologue:
	pushw DrawHelper_A_Prologue_Str_id@hi16
	pushw DrawHelper_A_Prologue_Str_id@lo16
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld XWA, (xsp + 0x010c)
	push xwa
	jr DrawHelper_A_ClampThumb

DrawHelper_A_CalcRange:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, BitmapIDProc_PtrTable
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

DrawHelper_A_CalcThumb:
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_A_ClampThumb:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jr ApFuncIDProc_Return

DrawHelper_A_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld xiz, 0:i3
	jr DrawHelper_A_ReturnAlt

DrawHelper_A_DrawThumb:
	push xwa
	ld XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, DrawHelper_A_ReturnZero
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr DrawHelper_A_ReturnAlt2

DrawHelper_A_ReturnZero:
	inc 1, xiz

DrawHelper_A_ReturnAlt:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, BitmapIDProc_PtrTable
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, DrawHelper_A_DrawThumb
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, DrawHelper_A_ReturnAlt3

DrawHelper_A_ReturnAlt2:
	ld XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

DrawHelper_A_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr ApFuncIDProc_Return

DrawHelper_A_Return:
	ld XDE, (xsp + 0x0108)
	calr CommonIDProc

ApFuncIDProc_Return:
	pop xiz
	lda xsp, (xsp+264)
	ret

ApFuncIDProc:
	lda xsp, (xsp-4376)
	push xiz
	ld	(xsp+4372), xde
	ld xiz, xbc
	ld	(xsp+4376), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, DrawHelper_B_CalcRange
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, DrawHelper_B_CalcRange
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, DrawHelper_B_ReturnAlt

DrawHelper_B_CalcRange:
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld xwa, 0x120
	ld (xsp + 12), xwa

DrawHelper_B_CalcThumb:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	ld xde, 0:i3
	cp xhl, 0x0
	jr ule, DrawHelper_B_ReturnZero

DrawHelper_B_DrawTrack:
	ld xwa, (xsp + 16)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 16
	add xwa, xde
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, DrawHelper_B_DrawTrack

DrawHelper_B_ReturnZero:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x13f
	jr ule, DrawHelper_B_CalcThumb

DrawHelper_B_ReturnAlt:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, DrawHelper_C_DrawTrack
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, DrawHelper_C_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, DrawHelper_C_Setup
	cp xiz, EVT_MAKE_DUMP
	jr z, DrawHelper_B_FinishAlt
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, DrawHelper_B_Finish
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, DrawHelper_C_Return
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	jr DrawHelper_C_CalcRange

DrawHelper_B_Finish:
	ld xhl, (xsp + 16)
	jrl MainFuncIDProc_Return

DrawHelper_B_FinishAlt:
	pushw DrawHelper_B_FinishAlt_Str_idf@hi16
	pushw DrawHelper_B_FinishAlt_Str_idf@lo16
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld XWA, (xsp + 0x1118)
	push xwa
	jr DrawHelper_C_CalcThumb

DrawHelper_C_Setup:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3

DrawHelper_C_CalcRange:
	call ApFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_C_CalcThumb:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jrl MainFuncIDProc_Return

DrawHelper_C_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, DrawHelper_C_ReturnAlt2

DrawHelper_C_ReturnZero:
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ApFunctionProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, DrawHelper_C_ReturnAlt
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	jr DrawHelper_C_ReturnAlt3

DrawHelper_C_ReturnAlt:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, DrawHelper_C_ReturnZero

DrawHelper_C_ReturnAlt2:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawHelper_C_ReturnAlt4

DrawHelper_C_ReturnAlt3:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

DrawHelper_C_ReturnAlt4:
	ld xhl, (xsp + 8)
	jr MainFuncIDProc_Return

DrawHelper_C_Return:
	ld XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld XDE, (xsp + 0x1114)
	calr CommonIDProc

MainFuncIDProc_Return:
	pop xiz
	lda xsp, (xsp+4376)
	ret

MainFuncIDProc:
	lda xsp, (xsp-4376)
	push xiz
	ld	(xsp+4372), xde
	ld xiz, xbc
	ld	(xsp+4376), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, DrawHelper_D_Setup
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, DrawHelper_D_Setup
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, DrawHelper_D_ReturnAlt

DrawHelper_D_Setup:
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld xwa, 0x140
	ld (xsp + 12), xwa

DrawHelper_D_CalcRange:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	ld xde, 0:i3
	cp xhl, 0x0
	jr ule, DrawHelper_D_ReturnZero

DrawHelper_D_DrawTrack:
	ld xwa, (xsp + 16)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 16
	add xwa, xde
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, DrawHelper_D_DrawTrack

DrawHelper_D_ReturnZero:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x15f
	jr ule, DrawHelper_D_CalcRange

DrawHelper_D_ReturnAlt:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, DrawHelper_E_DrawTrack
	cp xiz, EVT_GET_PROPERTY_EX
	jr z, DrawHelper_E_Setup
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, DrawHelper_E_Setup
	cp xiz, EVT_MAKE_DUMP
	jr z, DrawHelper_D_FinishAlt
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, DrawHelper_D_Finish
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, DrawHelper_E_Return
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	jr DrawHelper_E_CalcRange

DrawHelper_D_Finish:
	ld xhl, (xsp + 16)
	jrl ViewIDProc_Return

DrawHelper_D_FinishAlt:
	pushw DrawHelper_D_FinishAlt_Str_idf@hi16
	pushw DrawHelper_D_FinishAlt_Str_idf@lo16
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld XWA, (xsp + 0x1118)
	push xwa
	jr DrawHelper_E_CalcThumb

DrawHelper_E_Setup:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3

DrawHelper_E_CalcRange:
	call MainFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_E_CalcThumb:
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3
	jrl ViewIDProc_Return

DrawHelper_E_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, DrawHelper_E_ReturnAlt2

DrawHelper_E_ReturnZero:
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call MainFunctionProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, DrawHelper_E_ReturnAlt
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	jr DrawHelper_E_ReturnAlt3

DrawHelper_E_ReturnAlt:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, DrawHelper_E_ReturnZero

DrawHelper_E_ReturnAlt2:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawHelper_E_ReturnAlt4

DrawHelper_E_ReturnAlt3:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

DrawHelper_E_ReturnAlt4:
	ld xhl, (xsp + 8)
	jr ViewIDProc_Return

DrawHelper_E_Return:
	ld XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld XDE, (xsp + 0x1114)
	calr CommonIDProc

ViewIDProc_Return:
	pop xiz
	lda xsp, (xsp+4376)
	ret

ViewIDProc:
	lda xsp, (xsp-4376)
	push xiz
	ld	(xsp+4372), xde
	ld xiz, xbc
	ld	(xsp+4376), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, ViewID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ViewID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, ViewID_EventSwitch

ViewID_EnumFill:
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

ViewID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, ViewID_EnumFill_OuterNext
	ld xwa, 0:i3
	ld (xsp + 12), xwa

ViewID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, ViewID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 16), xwa

ViewID_EnumFill_InnerNext:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, ViewID_EnumFill_InnerLoop

ViewID_EnumFill_OuterNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xff
	jr ule, ViewID_EnumFill_OuterLoop

ViewID_EventSwitch:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, ViewID_EnumOpen
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, ViewID_GetCurrent
	cp xiz, EVT_DUMP_PROPERTY_EX
	jrl z, ViewID_GetCurrent
	cp xiz, EVT_MAKE_DUMP
	jrl z, ViewID_GetInfoStr
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jrl z, ViewID_EnumCount
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, ViewID_Default
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, ViewID_Select_Lookup
	pushw ViewID_EventSwitch_Str_idNONE@hi16
	pushw ViewID_EventSwitch_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	jrl ViewID_ReturnZero

ViewID_Select_Lookup:
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, ViewID_Select_NoName
	push xhl
	pushw ViewID_Select_Lookup_Str_idi_Fmts@hi16
	pushw ViewID_Select_Lookup_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jrl ViewID_ReturnZero

ViewID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw ViewID_Select_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw ViewID_Select_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xde + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jrl ViewID_ReturnZero

ViewID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ViewID_Return

ViewID_GetInfoStr:
	pushw ViewID_GetInfoStr_Str_sword@hi16
	pushw ViewID_GetInfoStr_Str_sword@lo16
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld XWA, (xsp + 0x1118)
	push xwa
	jrl ViewID_StrCpy

ViewID_GetCurrent:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xde, (xsp + 4)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xffffffff
	jr z, ViewID_GetCurrent_None
	ld xwa, (xde + 8)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	sll xwa, 16
	ld xbc, xwa
	add xbc, (xde)
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, ViewID_GetCurrent_NoName
	push xhl
	pushw ViewID_GetCurrent_Str_idi_Fmts@hi16
	pushw ViewID_GetCurrent_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr ViewID_ReturnZero

ViewID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw ViewID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw ViewID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xbc + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jr ViewID_ReturnZero

ViewID_GetCurrent_None:
	pushw ViewID_GetCurrent_None_Str_idNONE@hi16
	pushw ViewID_GetCurrent_None_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

ViewID_StrCpy:
	call Strcpy
	inc 8, xsp

ViewID_ReturnZero:
	ld xhl, 0:i3
	jrl ViewID_Return

ViewID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, ViewID_EnumOpen_NotFound

ViewID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, ViewID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	jr ViewID_EnumOpen_Store

ViewID_EnumOpen_ScanNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jr c, ViewID_EnumOpen_ScanLoop

ViewID_EnumOpen_NotFound:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, ViewID_EnumOpen_Return

ViewID_EnumOpen_Store:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

ViewID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr ViewID_Return

ViewID_Default:
	ld XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld XDE, (xsp + 0x1114)
	calr CommonIDProc

ViewID_Return:
	pop xiz
	lda xsp, (xsp+4376)
	ret

ScreenIDProc:
	lda xsp, (xsp-4376)
	push xiz
	ld	(xsp+4372), xde
	ld xiz, xbc
	ld	(xsp+4376), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, ScreenID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ScreenID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, ScreenID_EventSwitch

ScreenID_EnumFill:
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

ScreenID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, ScreenID_EnumFill_OuterNext
	ld xwa, 0:i3
	ld (xsp + 12), xwa

ScreenID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, ScreenID_EnumFill_InnerNext
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_Screen
	call SendEvent
	or xhl, xhl
	jr z, ScreenID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 16), xwa

ScreenID_EnumFill_InnerNext:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, ScreenID_EnumFill_InnerLoop

ScreenID_EnumFill_OuterNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xff
	jr ule, ScreenID_EnumFill_OuterLoop

ScreenID_EventSwitch:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, ScreenID_EnumOpen
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, ScreenID_GetCurrent
	cp xiz, EVT_DUMP_PROPERTY_EX
	jrl z, ScreenID_GetCurrent
	cp xiz, EVT_MAKE_DUMP
	jrl z, ScreenID_ReturnZero
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jrl z, ScreenID_EnumCount
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, ScreenID_Default
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, ScreenID_Select_Lookup
	pushw ScreenID_EventSwitch_Str_idNONE@hi16
	pushw ScreenID_EventSwitch_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	jrl ScreenID_ReturnZero

ScreenID_Select_Lookup:
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_Select_NoName
	push xhl
	pushw ScreenID_Select_Lookup_Str_idi_Fmts@hi16
	pushw ScreenID_Select_Lookup_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jrl ScreenID_ReturnZero

ScreenID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw ScreenID_Select_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw ScreenID_Select_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xde + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jrl ScreenID_ReturnZero

ScreenID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ScreenID_Return

ScreenID_GetCurrent:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xde, (xsp + 4)
	ld xbc, (xhl)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xffffffff
	jr z, ScreenID_GetCurrent_None
	ld xbc, xde
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_GetCurrent_NoName
	push xhl
	pushw ScreenID_GetCurrent_Str_idi_Fmts@hi16
	pushw ScreenID_GetCurrent_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr ScreenID_ReturnZero

ScreenID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw ScreenID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw ScreenID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xbc + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jr ScreenID_ReturnZero

ScreenID_GetCurrent_None:
	pushw ScreenID_GetCurrent_None_Str_idNONE@hi16
	pushw ScreenID_GetCurrent_None_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp

ScreenID_ReturnZero:
	ld xhl, 0:i3
	jrl ScreenID_Return

ScreenID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, ScreenID_EnumOpen_NotFound

ScreenID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_EnumOpen_ScanNoName
	push xhl
	pushw ScreenID_EnumOpen_ScanLoop_Str_idi_Fmts@hi16
	pushw ScreenID_EnumOpen_ScanLoop_Str_idi_Fmts@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr ScreenID_EnumOpen_Compare

ScreenID_EnumOpen_ScanNoName:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw ScreenID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd@hi16
	pushw ScreenID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd@lo16
	lda xwa, (xsp + 30)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)

ScreenID_EnumOpen_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, ScreenID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	jr ScreenID_EnumOpen_Store

ScreenID_EnumOpen_ScanNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jrl c, ScreenID_EnumOpen_ScanLoop

ScreenID_EnumOpen_NotFound:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr z, ScreenID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	pushw ScreenID_EnumOpen_NotFound_Str_idNONE@hi16
	pushw ScreenID_EnumOpen_NotFound_Str_idNONE@lo16
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, ScreenID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xbc, 0xffffffff
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	jr ScreenID_EnumOpen_Store

ScreenID_EnumOpen_CheckEmpty:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, ScreenID_EnumOpen_Return

ScreenID_EnumOpen_Store:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

ScreenID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr ScreenID_Return

ScreenID_Default:
	ld XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld XDE, (xsp + 0x1114)
	calr CommonIDProc

ScreenID_Return:
	pop xiz
	lda xsp, (xsp+4376)
	ret

WindowIDProc:
	lda xsp, (xsp-4376)
	push xiz
	ld	(xsp+4372), xde
	ld xiz, xbc
	ld	(xsp+4376), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, WindowID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, WindowID_EnumFill
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, WindowID_EventSwitch

WindowID_EnumFill:
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

WindowID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, WindowID_EnumFill_OuterNext
	ld xwa, 0:i3
	ld (xsp + 12), xwa

WindowID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, WindowID_EnumFill_InnerNext
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_Window
	call SendEvent
	or xhl, xhl
	jr z, WindowID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, (xsp + 12)
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 16), xwa

WindowID_EnumFill_InnerNext:
	ld xwa, 1:i3
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, WindowID_EnumFill_InnerLoop

WindowID_EnumFill_OuterNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xff
	jr ule, WindowID_EnumFill_OuterLoop

WindowID_EventSwitch:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, WindowID_EnumOpen
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, WindowID_GetCurrent
	cp xiz, EVT_DUMP_PROPERTY_EX
	jrl z, WindowID_GetCurrent
	cp xiz, EVT_MAKE_DUMP
	jrl z, WindowID_ReturnZero
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jrl z, WindowID_EnumCount
	cp xiz, EVT_GET_PROP_DATA_SP
	jrl nz, WindowID_Default
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, WindowID_Select_Lookup
	pushw WindowID_EventSwitch_Str_idNONE@hi16
	pushw WindowID_EventSwitch_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	jrl WindowID_ReturnZero

WindowID_Select_Lookup:
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_Select_NoName
	push xhl
	pushw WindowID_Select_Lookup_Str_idi_Fmts@hi16
	pushw WindowID_Select_Lookup_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jrl WindowID_ReturnZero

WindowID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw WindowID_Select_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw WindowID_Select_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xde + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jrl WindowID_ReturnZero

WindowID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl WindowID_Return

WindowID_GetCurrent:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xde, (xsp + 4)
	ld xbc, (xhl)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xffffffff
	jr z, WindowID_GetCurrent_None
	ld xbc, xde
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_GetCurrent_NoName
	push xhl
	pushw WindowID_GetCurrent_Str_idi_Fmts@hi16
	pushw WindowID_GetCurrent_Str_idi_Fmts@lo16
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr WindowID_ReturnZero

WindowID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw WindowID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@hi16
	pushw WindowID_GetCurrent_NoName_Str_idi_Fmts_Fmtd@lo16
	ld xwa, (xbc + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	jr WindowID_ReturnZero

WindowID_GetCurrent_None:
	pushw WindowID_GetCurrent_None_Str_idNONE@hi16
	pushw WindowID_GetCurrent_None_Str_idNONE@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp

WindowID_ReturnZero:
	ld xhl, 0:i3
	jrl WindowID_Return

WindowID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, WindowID_EnumOpen_NotFound

WindowID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_EnumOpen_ScanNoName
	push xhl
	pushw WindowID_EnumOpen_ScanLoop_Str_idi_Fmts@hi16
	pushw WindowID_EnumOpen_ScanLoop_Str_idi_Fmts@lo16
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr WindowID_EnumOpen_Compare

WindowID_EnumOpen_ScanNoName:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	add xwa, TITLE_PS
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xbc)
	ldiw_erp 0xe2, 0
	pushw wa
	push xhl
	pushw WindowID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd@hi16
	pushw WindowID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd@lo16
	lda xwa, (xsp + 30)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)

WindowID_EnumOpen_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, WindowID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+276)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	jr WindowID_EnumOpen_Store

WindowID_EnumOpen_ScanNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jrl c, WindowID_EnumOpen_ScanLoop

WindowID_EnumOpen_NotFound:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr z, WindowID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	pushw WindowID_EnumOpen_NotFound_Str_idNONE@hi16
	pushw WindowID_EnumOpen_NotFound_Str_idNONE@lo16
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, WindowID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xbc, 0xffffffff
	ld (xwa + 4), xbc
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	jr WindowID_EnumOpen_Store

WindowID_EnumOpen_CheckEmpty:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, WindowID_EnumOpen_Return

WindowID_EnumOpen_Store:
	ld XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

WindowID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr WindowID_Return

WindowID_Default:
	ld XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld XDE, (xsp + 0x1114)
	calr CommonIDProc

WindowID_Return:
	pop xiz
	lda xsp, (xsp+4376)
	ret

ModeIDProc:
	lda xsp, (xsp-4372)
	push xiz
	ld	(xsp+4368), xde
	ld xiz, xbc
	ld	(xsp+4372), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, ModeID_BuildTable
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ModeID_BuildTable
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, ModeID_EventDispatch

ModeID_BuildTable:
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld xwa, 0x180
	ld (xsp + 8), xwa

ModeID_BuildTable_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	ld xde, 0:i3
	cp xhl, 0x0
	jr ule, ModeID_BuildTable_NextGroup

ModeID_BuildTable_InnerLoop:
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, xde
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, ModeID_BuildTable_InnerLoop

ModeID_BuildTable_NextGroup:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x19f
	jr ule, ModeID_BuildTable_OuterLoop

ModeID_EventDispatch:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, ModeID_EnumOpen
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, ModeID_GetNext
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, ModeID_GetCurrent
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, ModeID_EnumCount
	cp xiz, EVT_GET_PROP_DATA_SP
	jr z, ModeID_EnumFill
	ld XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl ModeID_Return

ModeID_EnumFill:
	ld XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xiz + 4)
	cp (xhl), 0x0
	jr nz, ModeID_EnumFill_HasName
	ld xwa, (xiz + 8)
	push xwa
	pushw ModeID_EnumFill_Str_Mode_Fmtd@hi16
	pushw ModeID_EnumFill_Str_Mode_Fmtd@lo16
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jrl ModeID_ReturnZero

ModeID_EnumFill_HasName:
	push xhl
	push xbc
	jrl ModeID_Strcpy

ModeID_EnumCount:
	ld xhl, (xsp + 12)
	jrl ModeID_Return

ModeID_GetCurrent:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	cp (xhl), 0x0
	jr nz, ModeID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, ModeID_GetCurrent_Str_Fmtd
	jr ModeID_GetCurrent_SendAudio

ModeID_GetCurrent_HasName:
	push xhl
	ld xwa, ModeID_GetCurrent_HasName_Str_MAKEMODEID_Fmts

ModeID_GetCurrent_SendAudio:
	push xwa
	ld xwa, (xiz + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr ModeID_ReturnZero

ModeID_GetNext:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	lda xwa, (xiz + 4)
	cp (xhl), 0x0
	jr nz, ModeID_GetNext_HasName
	ld xbc, (xiz)
	ldiw_erp 0xe6, 0
	pushw bc
	pushw ModeID_GetNext_Str_Mode_Fmtd@hi16
	pushw ModeID_GetNext_Str_Mode_Fmtd@lo16
	ld xwa, (xwa)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	jr ModeID_ReturnZero

ModeID_GetNext_HasName:
	push xhl
	ld xwa, (xwa)
	push xwa

ModeID_Strcpy:
	call Strcpy
	inc 8, xsp

ModeID_ReturnZero:
	ld xhl, 0:i3
	jrl ModeID_Return

ModeID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld XIZ, (xsp + 0x1110)
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, ModeID_EnumOpen_CheckResult

ModeID_EnumOpen_SearchLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	push xhl
	lda xwa, (xsp + 20)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 16)
	cp (xbc), 0x0
	jr nz, ModeID_EnumOpen_Compare
	ld xwa, (xsp + 8)
	push xwa
	pushw ModeID_EnumOpen_SearchLoop_Str_Mode_Fmtd@hi16
	pushw ModeID_EnumOpen_SearchLoop_Str_Mode_Fmtd@lo16
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)

ModeID_EnumOpen_Compare:
	ld xwa, (xiz + 4)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, ModeID_EnumOpen_SearchNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr ModeID_EnumOpen_UpdateCursor

ModeID_EnumOpen_SearchNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, ModeID_EnumOpen_SearchLoop

ModeID_EnumOpen_CheckResult:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, ModeID_EnumOpen_Return

ModeID_EnumOpen_UpdateCursor:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

ModeID_EnumOpen_Return:
	ld xhl, (xsp + 4)

ModeID_Return:
	pop xiz
	lda xsp, (xsp+4372)
	ret

TitleIDProc:
	lda xsp, (xsp-4372)
	push xiz
	ld	(xsp+4368), xde
	ld xiz, xbc
	ld	(xsp+4372), xwa
	cp xiz, EVT_SET_PROPERTY_EX
	jr z, TitleID_BuildTable
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, TitleID_BuildTable
	cp xiz, EVT_GET_PROP_DATA_SP
	jr nz, TitleID_EventDispatch

TitleID_BuildTable:
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld xwa, 0x1a0
	ld (xsp + 8), xwa

TitleID_BuildTable_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	ld xde, 0:i3
	cp xhl, 0x0
	jr ule, TitleID_BuildTable_NextGroup

TitleID_BuildTable_InnerLoop:
	ld xwa, (xsp + 12)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 16
	add xwa, xde
	ld (xbc), xwa
	ld xwa, 1:i3
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, TitleID_BuildTable_InnerLoop

TitleID_BuildTable_NextGroup:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1bf
	jr ule, TitleID_BuildTable_OuterLoop

TitleID_EventDispatch:
	cp xiz, EVT_SET_PROPERTY_EX
	jrl z, TitleID_EnumOpen
	cp xiz, EVT_GET_PROPERTY_EX
	jrl z, TitleID_GetNext
	cp xiz, EVT_DUMP_PROPERTY_EX
	jr z, TitleID_GetCurrent
	cp xiz, EVT_GET_PROP_DATA_COUNT_SP
	jr z, TitleID_EnumCount
	cp xiz, EVT_GET_PROP_DATA_SP
	jr z, TitleID_EnumFill
	ld XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl TitleID_Return

TitleID_EnumFill:
	ld XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld xbc, (xiz + 4)
	cp (xhl), 0x0
	jr nz, TitleID_EnumFill_HasName
	ld xwa, (xiz + 8)
	push xwa
	pushw TitleID_EnumFill_Str_Title_Fmtd@hi16
	pushw TitleID_EnumFill_Str_Title_Fmtd@lo16
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jrl TitleID_ReturnZero

TitleID_EnumFill_HasName:
	push xhl
	push xbc
	jrl TitleID_Strcpy

TitleID_EnumCount:
	ld xhl, (xsp + 12)
	jrl TitleID_Return

TitleID_GetCurrent:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	cp (xhl), 0x0
	jr nz, TitleID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, TitleID_GetCurrent_Str_Fmtd
	jr TitleID_GetCurrent_SendAudio

TitleID_GetCurrent_HasName:
	push xhl
	ld xwa, TitleID_GetCurrent_HasName_Str_MAKETITLEID_Fmts

TitleID_GetCurrent_SendAudio:
	push xwa
	ld xwa, (xiz + 4)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	jr TitleID_ReturnZero

TitleID_GetNext:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	lda xwa, (xiz + 4)
	cp (xhl), 0x0
	jr nz, TitleID_GetNext_HasName
	ld xbc, (xiz)
	ldiw_erp 0xe6, 0
	pushw bc
	pushw TitleID_GetNext_Str_Title_Fmtd@hi16
	pushw TitleID_GetNext_Str_Title_Fmtd@lo16
	ld xwa, (xwa)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	jr TitleID_ReturnZero

TitleID_GetNext_HasName:
	push xhl
	ld xwa, (xwa)
	push xwa

TitleID_Strcpy:
	call Strcpy
	inc 8, xsp

TitleID_ReturnZero:
	ld xhl, 0:i3
	jrl TitleID_Return

TitleID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld XIZ, (xsp + 0x1110)
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, TitleID_EnumOpen_CheckResult

TitleID_EnumOpen_SearchLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	push xhl
	lda xwa, (xsp + 20)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 16)
	cp (xbc), 0x0
	jr nz, TitleID_EnumOpen_Compare
	ld xwa, (xsp + 8)
	push xwa
	pushw TitleID_EnumOpen_SearchLoop_Str_Title_Fmtd@hi16
	pushw TitleID_EnumOpen_SearchLoop_Str_Title_Fmtd@lo16
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)

TitleID_EnumOpen_Compare:
	ld xwa, (xiz + 4)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, TitleID_EnumOpen_SearchNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	lda xbc, (xsp+272)
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	ld xwa, 0:i3
	ld (xsp + 4), xwa
	jr TitleID_EnumOpen_UpdateCursor

TitleID_EnumOpen_SearchNext:
	ld xwa, 1:i3
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, TitleID_EnumOpen_SearchLoop

TitleID_EnumOpen_CheckResult:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, TitleID_EnumOpen_Return

TitleID_EnumOpen_UpdateCursor:
	ld XIZ, (xsp + 0x1110)
	ld XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

TitleID_EnumOpen_Return:
	ld xhl, (xsp + 4)

TitleID_Return:
	pop xiz
	lda xsp, (xsp+4372)
	ret

NameProc:
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xbc, xwa
	lda xhl, (xiz + 4)
	ld xwa, (xiz + 8)
	cp xde, EVT_SET_PROPERTY_EX
	jr z, ConstFlagProc_Init
	cp xde, EVT_GET_PROPERTY_EX
	jr z, NameProc_GetText_CopyStr
	cp xde, EVT_DUMP_PROPERTY_EX
	jr z, NameProc_GetText
	cp xde, EVT_MAKE_DUMP
	jr z, NameProc_Init_SetPtr
	cp xde, EVT_GET_PROP_MEMBER
	jr z, NameProc_Init
	cp xde, EVT_CHECK_PROP_STRING
	jr z, NameProc_Return
	ld xwa, xbc
	ld xbc, xde
	ld xde, xiz
	calr CommonIDProc
	jr ConstFlagProc_ReturnZero

NameProc_Init:
	ld xwa, NameProc_Init_Str_name
	jr NameProc_Close

NameProc_Init_SetPtr:
	ld xwa, Str_No_0x8BC

NameProc_Close:
	push xwa
	push xiz
	jr NameProc_DefaultForward

NameProc_GetText:
	pushw NameProc_GetText_Str_Empty@hi16
	pushw NameProc_GetText_Str_Empty@lo16
	jr NameProc_ReturnZero

NameProc_GetText_CopyStr:
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	push xhl
	lda xhl, (xiz + 4)

NameProc_ReturnZero:
	ld xwa, (xhl)
	push xwa

NameProc_DefaultForward:
	call Strcpy
	inc 8, xsp

NameProc_Return:
	ld xhl, 0:i3
	jr ConstFlagProc_ReturnZero

ConstFlagProc_Init:
	ld xde, (xhl)
	ld xbc, EVT_SET_NAME
	call SendEvent

ConstFlagProc_ReturnZero:
	pop xiz
	ret

ConstFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	cp xbc, EVT_SET_PROPERTY_EX
	jrl z, ConstFlagProc_Default_Result
	cp xbc, EVT_GET_PROPERTY_EX
	jr z, ConstFlagProc_Default
	cp xbc, EVT_DUMP_PROPERTY_EX
	jr z, ConstFlagProc_SetValue_Check
	cp xbc, EVT_MAKE_DUMP
	jr z, ConstFlagProc_GetValue_Set
	cp xbc, EVT_GET_PROP_MEMBER
	jr z, ConstFlagProc_GetValue
	cp xbc, EVT_CHECK_PROP_STRING
	jr z, ConstFlagProc_Default_Forward
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr ConstFlagProc_Default_Done

ConstFlagProc_GetValue:
	ld xwa, ConstFlagProc_GetValue_Str_romram
	jr ConstFlagProc_SetValue

ConstFlagProc_GetValue_Set:
	ld xwa, Str_No_0x8C8

ConstFlagProc_SetValue:
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	jr ConstFlagProc_SetValue_Store

ConstFlagProc_SetValue_Check:
	pushw ConstFlagProc_SetValue_Check_Str_Empty@hi16
	pushw ConstFlagProc_SetValue_Check_Str_Empty@lo16
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

ConstFlagProc_SetValue_Store:
	call Strcpy
	inc 8, xsp
	jr ConstFlagProc_Default_Forward

ConstFlagProc_Default:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	call GetConst
	exts xhl
	ld xwa, (xsp + 4)
	ld (xwa + 8), xhl
	ld xwa, (xsp + 8)
	ld xbc, EVT_GET_PROP_DATA_SP
	ld xde, (xsp + 4)
	call SendEvent

ConstFlagProc_Default_Forward:
	ld xhl, 0:i3
	jr ConstFlagProc_Default_Done

ConstFlagProc_Default_Result:
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, ConstFlagProc_Default_ResultAlt
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 8)
	ld xbc, (xbc + 4)
	call SetConst

ConstFlagProc_Default_ResultAlt:
	ld xhl, xiz

ConstFlagProc_Default_Done:
	pop xiz
	inc 8, xsp
	ret

ObjectIDProc:
	jrl slongProc

pFuncProc:
	jrl ApFuncIDProc

pProcProc:
	jrl ApFuncIDProc

pPropProc:
	jrl ulongProc
; WidgetType dispatch (pStringProc/EventIDProc)
pStringProc:
	jrl ulongProc

EventIDProc:
	jrl slongProc

CommonIDProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld xiz, xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 12), xhl
	ld xde, xiz
	cp xiz, EVT_MAKE_DUMP
	jrl z, CommonIDProc_ReturnZero
	cp xiz, EVT_GET_PROP_MEMBER
	jr z, CommonIDProc_CheckAvail
	cp xiz, EVT_CHECK_PROP_STRING
	jrl z, CommonIDProc_ReturnZero
	ld xwa, (xsp + 12)
	lda xbc, (xwa + 4)
	sub xde, EVT_COPY_PROPERTY_EX
	cp xde, 0x0
	jrl lt, CommonIDProc_Default
	cp xde, 0x6
	jrl gt, CommonIDProc_Default
	add xde, xde
	add xde, Str_No_0x8CE
	ld de, (xde)
	lda xix, (CommonIDProc_Evt1E0000D:24)
; Computed jump: target = CommonIDProc_Evt1E0000D + Str_No_0x8CE[i], Str_No_0x8CE = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e00008:
;   0x1e00008 -> CommonIDProc_ReturnZero
;   0x1e00009 -> CommonIDProc_Evt1E00009
;   0x1e0000a -> CommonIDProc_Evt1E0000A
;   0x1e0000b -> CommonIDProc_Evt1E00009
;   0x1e0000c -> CommonIDProc_Evt1E0000C
;   0x1e0000d -> CommonIDProc_Evt1E0000D
;   0x1e0000e -> CommonIDProc_Evt1E0000E
	jp	t, (xix+de)
CommonIDProc_Evt1E0000D:
	ld	xwa, (xsp+16)
	ld	(xsp+4), xwa
	ld	xbc, (xwa+8)
	sll	xbc, 3
	ld	xwa, (xsp+12)
	add	xbc, (xwa+8)
	ld	xwa, (xbc)
	push	xwa
	jr	CommonIDProc_Join
CommonIDProc_Evt1E0000E:
	ld	hl, (xbc)
	extz	xhl
	jrl	CommonIDProc_Epilogue

CommonIDProc_CheckAvail:
	ld xhl, 1:i3
	jrl CommonIDProc_Epilogue
CommonIDProc_Evt1E0000A:
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	pushw 0xea
	pushw 0xabe2
CommonIDProc_Join:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CommonIDProc_ReturnZero
CommonIDProc_Evt1E00009:
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	pushw 0xa
	ld xbc, (xsp + 6)
	ld xwa, (xbc + 4)
	push xwa
	ld xwa, (xbc)
	push xwa
	call Strlen_LoadParam
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 12)
	cpw (xwa + 4), 0x0
	jr z, CommonIDProc_ReturnZero
	ld iz, 0:i3
	ld xbc, (xwa + 8)
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xde, 0:i3
	jr CommonIDProc_SearchLoop_Check

CommonIDProc_SearchLoop_Compare:
	cp xwa, (xhl + 4)
	jr nz, CommonIDProc_SearchLoop_Next
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CommonIDProc_ReturnZero

CommonIDProc_SearchLoop_Next:
	inc 1, iz
	inc 8, xde

CommonIDProc_SearchLoop_Check:
	ld xhl, xde
	add xhl, xbc
	ld xix, (xhl)
	cp (xix), 0x0
	jr nz, CommonIDProc_SearchLoop_Compare

CommonIDProc_ReturnZero:
	ld xhl, 0:i3
	jrl CommonIDProc_Epilogue
CommonIDProc_Evt1E0000C:
	ld xwa, 0:i3
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	cpw (xbc), 0x0
	jr z, CommonIDProc_EnumSearch_Atoi
	ld iz, 0:i3
	jr CommonIDProc_EnumSearch_Check

CommonIDProc_EnumSearch_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	ld xwa, (xbc)
	push xwa
	call Strcmp
	inc 8, xsp
	cp hl, 0:i3
	jr nz, CommonIDProc_EnumSearch_Next
	ld bc, iz
	extz xbc
	sll xbc, 3
	ld xwa, (xsp + 12)
	add xbc, (xwa + 8)
	ld xwa, (xsp + 4)
	ld xbc, (xbc + 4)
	ld (xwa + 4), xbc
	jr CommonIDProc_EnumSearch_EndCheck

CommonIDProc_EnumSearch_Next:
	inc 1, iz

CommonIDProc_EnumSearch_Check:
	ld bc, iz
	extz xbc
	sll xbc, 3
	ld xwa, (xsp + 12)
	add xbc, (xwa + 8)
	ld xwa, (xbc)
	cp (xwa), 0x0
	jr nz, CommonIDProc_EnumSearch_Compare

CommonIDProc_EnumSearch_EndCheck:
	ld bc, iz
	extz xbc
	sll xbc, 3
	ld xwa, (xsp + 12)
	add xbc, (xwa + 8)
	ld xwa, (xbc)
	cp (xwa), 0x0
	jr nz, CommonIDProc_EnumSearch_Result
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	jr CommonIDProc_EnumSearch_Result

CommonIDProc_EnumSearch_Atoi:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	call ParseInt32
	inc 4, xsp
	ld xwa, (xsp + 4)
	ld (xwa + 4), xhl

CommonIDProc_EnumSearch_Result:
	ld xhl, (xsp + 8)
	jr CommonIDProc_Epilogue

CommonIDProc_Default:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc

CommonIDProc_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

IDCountHelper:
	lda xsp, (xsp-262)
	push xiz
	ld	(xsp+264), bc
	ld xiz, xwa
	lda xde, (xsp + 8)
	ld xwa, xiz
	ld xbc, EVT_GET_PROP_STRING
	call SendEvent
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld iz, 0:i3
	ldiw_erp 0xfa, 0
	cpw	(xsp+264), 0x0000
	jr ule, IDCountHelper_Done

IDCountHelper_Loop:
	lda xwa, (xsp + 8)
	ld	a, (xwa+qiz)
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_GET_PROP_SIZE
	ld xde, 0:i3
	call SendEvent
	ld wa, iz
	add wa, hl
	ld iz, wa
	inc1w_erp 0xfa
	ldto_werp WA, 0xfa
	cp	wa, (xsp+264)
	jr c, IDCountHelper_Loop

IDCountHelper_Done:
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+iz)
	pop xiz
	lda xsp, (xsp+262)
	ret

IDCursorAdvance:
	lda xsp, (xsp-136)
	pushw iz
	ld (xsp + 2), xwa
	ld xwa, (xwa + 8)
	lda xde, (xsp + 10)
	ld xbc, EVT_GET_PROP_STRING
	call SendEvent
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld iz, 0:i3
	jr IDCursorAdvance_Check

IDCursorAdvance_Loop:
	lda xwa, (xsp + 10)
	add xwa, xbc
	ld a, (xwa)
	sub a, 0x41
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x2600000
	ld xbc, EVT_GET_PROP_SIZE
	ld xde, 0:i3
	call SendEvent
	add (xsp + 6), xhl
	inc 1, iz

IDCursorAdvance_Check:
	ld bc, iz
	extz xbc
	ld xwa, (xsp + 2)
	cp xbc, (xwa)
	jr c, IDCursorAdvance_Loop
	ld xwa, (xwa + 8)
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	add xhl, (xsp + 6)
	popw iz
	lda xsp, (xsp+136:16)
	ret

InitializeEventQueue:
	ret

DispatchEvent:	; SysData_FA9585
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr GetEvent
	cp hl, 0:i3
	jrl z, EventHandler_DispatchLoop

; EventHandler dual-phase dispatch
EventHandler_ObjectDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xffffffff
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027ed6:24)
	add xwa, xbc
	ld xhl, (xwa)
	or xhl, xhl
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	ld (0x02bc24:24), xwa
	ld (0x02bc18:24), xwa
	ld xwa, (xsp + 4)
	ld (0x02bc28:24), xwa
	ld (0x02bc1c:24), xwa
	ld xwa, (xsp)
	ld (0x02bc2c:24), xwa
	ld (0x02bc20:24), xwa
	ld xwa, (xsp + 8)
	ld xix, xhl
	ld xbc, EVT_GET_CLASS_SP
	ld xde, 0:i3
	call (xix)
	ld (0x02bc14:24), xhl
	ld xwa, xhl
	srl xwa, 16
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xde, (xwa)
	extz xhl
	ld xbc, xhl
	add xbc, xbc
	add xbc, xhl
	sll xbc, 3
	add xbc, xde
	ld xhl, (xbc)
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, (xsp)
	call (xhl)
	cpw (0x03ef4e:24), 0
	jr z, EventHandler_ContinueProc
	ld wa, 3:i3
	call TaskSched_YieldToQueue

EventHandler_ContinueProc:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr GetEvent
	cp hl, 0:i3
	jrl nz, EventHandler_ObjectDispatch

EventHandler_DispatchLoop:
	lda xsp, (xsp + 12)
	ret

SendEvent:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xbc
	ld xiz, xwa
	cp xiz, 0xffffffff
	jr nz, EventRoute_ObjectDispatch
	calr GetCurrentTarget
	ld xiz, xhl

; EventRoute dual dispatch with context setup
EventRoute_ObjectDispatch:
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027ed6:24)
	add xwa, xbc
	ld xhl, (xwa)
	ld xwa, (0x02bc24:24)
	ld (xsp + 12), xwa
	ld xwa, (0x02bc28:24)
	ld (xsp + 16), xwa
	ld xwa, (0x02bc2c:24)
	ld (xsp + 8), xwa
	ld (0x02bc24:24), xiz
	ld xwa, (xsp + 24)
	ld (0x02bc28:24), xwa
	ld xwa, (xsp + 20)
	ld (0x02bc2c:24), xwa
	ld xwa, (0x02bc14:24)
	ld (xsp + 4), xwa
	ld xix, xhl
	ld xwa, xiz
	ld xbc, EVT_GET_CLASS_SP
	ld xde, 0:i3
	call (xix)
	ld (0x02bc14:24), xhl
	ld xwa, xhl
	srl xwa, 16
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xde, (xwa)
	extz xhl
	ld xbc, xhl
	add xbc, xbc
	add xbc, xhl
	sll xbc, 3
	add xbc, xde
	ld xhl, (xbc)
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	call (xhl)
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld (0x02bc14:24), xwa
	ld xwa, (xsp + 12)
	ld (0x02bc24:24), xwa
	ld xwa, (xsp + 16)
	ld (0x02bc28:24), xwa
	ld xwa, (xsp + 8)
	ld (0x02bc2c:24), xwa
	cpw (0x03ef4e:24), 0
	jr z, EventRoute_DispatchJump
	ld wa, 3:i3
	call TaskSched_YieldToQueue

EventRoute_DispatchJump:
	ld xhl, xiz
	pop xiz
	lda xsp, (xsp + 24)
	ret
PostEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 4:i3
	call TaskSched_WaitForEvent
	ld bc, (0x02ec34:24)
	ld de, (0x02ec36:24)
	ld wa, de
	inc 1, wa
	cp wa, bc
	jr z, EventRoute_CheckOwner
	ld wa, de
	sub wa, 0x3ff
	cp wa, bc
	jr nz, EventRoute_OwnerMatchDone

EventRoute_CheckOwner:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp

EventRoute_OwnerMatch:
	jr EventRoute_OwnerMatch

EventRoute_OwnerMatchDone:
	incw 1, (0x02f840:24)
	ld bc, de
	muls bc, 0xc
	lda xwa, (0x02bc34:24)
	exts xbc
	add xbc, xwa
	ld (xbc), xiz
	ld xwa, (xsp + 8)
	ld (xbc + 4), xwa
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	cp de, 0x3ff
	jr nz, PostEvent_Prologue
	ldw (0x02ec36:24), 0x0000
	jr PostEvent_AllocSlot

PostEvent_Prologue:
	incw 1, (0x02ec36:24)

PostEvent_AllocSlot:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	ld wa, 2:i3
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp
	ret

GetEvent:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), xbc
	ld xiz, xwa
	ld wa, 4:i3
	call TaskSched_WaitForEvent
	ld wa, (0x02ec34:24)
	cp wa, (0x02ec36:24)
	jr nz, PostEvent_FillSlot
	ld wa, 4:i3
	call TaskSched_SignalEvent
	ld hl, 0:i3
	jr GetEvent_Prologue

PostEvent_FillSlot:
	decw 1, (0x02f840:24)
	ld wa, (0x02ec34:24)
	ld (xsp + 4), wa
	ld bc, (xsp + 4)
	muls bc, 0xc
	lda xwa, (0x02bc34:24)
	ld	xwa, (xwa+bc)
	ld (xiz), xwa
	cp xwa, 0xffffffff
	jr nz, PostEvent_LinkSlot
	calr GetCurrentTarget
	ld (xiz), xhl

PostEvent_LinkSlot:
	ld bc, (xsp + 4)
	muls bc, 0xc
	lda xwa, (0x02bc34:24)
	lda	xde, (xwa+bc)
	ld xwa, (xsp + 10)
	ld xbc, (xde + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 6)
	ld xbc, (xde + 8)
	ld (xwa), xbc
	cpw (xsp + 4), 0x3ff
	jr nz, PostEvent_ReturnOne
	ldw (0x02ec34:24), 0x0000
	jr PostEvent_Return

PostEvent_ReturnOne:
	incw 1, (0x02ec34:24)

PostEvent_Return:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	ld hl, 1:i3

GetEvent_Prologue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DeleteEvent:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld wa, 4:i3
	call TaskSched_WaitForEvent
	ld bc, (0x02ec36:24)
	ld wa, (0x02ec34:24)
	cp wa, bc
	jr nz, GetEvent_ScanLoop
	ld wa, 4:i3
	jr GetEvent_Return

GetEvent_ScanLoop:
	ld ix, wa
	cp wa, bc
	jr z, GetEvent_ReturnOne
	lda xiy, (0x02bc34:24)

GetEvent_ScanMatch:
	ld wa, ix
	muls wa, 0xc
	lda	xhl, (xiy+wa)
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, GetEvent_ScanDone
	cp (xhl), xiz
	jr nz, GetEvent_ScanDone
	ld xwa, EVT_NONE
	ld (xde), xwa

GetEvent_ScanDone:
	cp ix, bc
	jr z, GetEvent_ReturnOne
	cp ix, 0x3ff
	jr nz, GetEvent_ReturnZero
	ld ix, 0:i3
	jr GetEvent_ReturnZeroAlt

GetEvent_ReturnZero:
	inc 1, ix

GetEvent_ReturnZeroAlt:
	cp ix, bc
	jr nz, GetEvent_ScanMatch

GetEvent_ReturnOne:
	ld wa, 4:i3

GetEvent_Return:
	call TaskSched_SignalEvent
	pop xiz
	inc 4, xsp
	ret

DeleteSpecificEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 4:i3
	call TaskSched_WaitForEvent
	ld bc, (0x02ec36:24)
	ld wa, (0x02ec34:24)
	cp wa, bc
	jr nz, DeleteEvent_Prologue
	ld wa, 4:i3
	jr DeleteEvent_Epilogue

DeleteEvent_Prologue:
	ld hl, wa
	cp wa, bc
	jr z, DeleteEvent_Return
	lda xix, (0x02bc34:24)

DeleteEvent_ScanLoop:
	ld wa, hl
	muls wa, 0xc
	lda	xiy, (xix+wa)
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop2
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, EVT_NONE
	ld (xde), xwa

ObjectSearch_ContinueLoop2:
	cp hl, bc
	jr z, DeleteEvent_Return
	cp hl, 0x3ff
	jr nz, DeleteEvent_Match
	ld hl, 0:i3
	jr DeleteEvent_CheckNext

DeleteEvent_Match:
	inc 1, hl

DeleteEvent_CheckNext:
	cp hl, bc
	jr nz, DeleteEvent_ScanLoop

DeleteEvent_Return:
	ld wa, 4:i3

DeleteEvent_Epilogue:
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp
	ret

; =============================================================================
; EventDispatch_Direct -- Direct event dispatch for key press routing
;
; Called from KeyPress_StateDispatch (F98697) with:
;   XWA = target workspace (0xffffffff = broadcast)
;   XBC = event code (e.g. 0x01c00038 = key press)
;   XDE = event parameter (packed key data)
;
; If the event ring buffer (at 0x02ec34/0x02ec36) is empty, delegates
; directly to BroadcastEvent (FA9D58) with the original parameters.
;
; If events are queued, scans the registration table (0x02bc34, 12-byte
; entries) for handlers registered for event 0x01c00038 whose filter
; (upper 16 bits) matches the event parameter. Updates matched entries
; and accumulates result bits in QIZH, then dispatches via FA9D58.
;
; Stack frame: 22 bytes local + QIZ save
;   (XSP+0x14) = saved XWA (target)
;   (XSP+0x10) = saved XBC (event code)
;   (XSP+0x0c) = saved XDE (event param)
;   (XSP+0x0a) = param byte 1 (srl 8 of XDE & 0xff)
;   (XSP+0x08) = accumulator byte
;   (XSP+0x06) = param byte 0 (XDE & 0xff)
;   (XSP+0x02) = working copy of event param
; =============================================================================
EventDispatch_Direct:
	lda xsp, (xsp - 22)			; allocate 22 bytes stack frame
	push qiz				; save QIZ
	ld (xsp + 12), xde			; save event param
	ld (xsp + 16), xbc			; save event code
	ld (xsp + 20), xwa			; save target workspace
	; --- Check if ring buffer is empty ---
	ld	wa, 4:i3
	call TaskSched_WaitForEvent				; acquire lock/semaphore (id=4)
	ld	bc, (0x02ec36:24)
	ld	de, (0x02ec34:24)
	cp de, bc				; compare read/write positions
	jr nz, DeleteSpecEvent_Prologue			; buffer not empty, process events
	; --- Buffer empty: release lock, dispatch directly ---
	ld	wa, 4:i3
	call TaskSched_SignalEvent				; release lock/semaphore (id=4)
	ld xwa, (xsp + 20)			; restore target
	ld xbc, (xsp + 16)			; restore event code
	ld xde, (xsp + 12)			; restore event param
	jrl MainSendEvent_Prologue			; jump to dispatch via FA9D58
DeleteSpecEvent_Prologue:
	; --- Buffer not empty: extract param bytes from XDE ---
	ld xwa, (xsp + 12)			; XWA = event param (XDE)
	ld (xsp + 2), xwa			; save working copy
	and xwa, 0x000000ff			; isolate low byte
	ld (xsp + 6), a				; param byte 0 = XDE & 0xff
	ld xwa, (xsp + 2)			; reload working copy
	srl xwa, 8				; shift right 8 bits
	and xwa, 0x000000ff			; isolate byte
	ld (xsp + 10), a			; param byte 1 = (XDE >> 8) & 0xff
	ldib_erp	251, 0
	ld (xsp + 8), 0x00			; clear accumulator byte
	; --- Scan registration table ---
	ld ix, de				; IX = write position (start)
	ld hl, bc				; HL = read position (end/sentinel)
	cp de, bc				; check if already at end
	jr z, DeleteSpecEvent_Epilogue			; empty range, skip scan
DeleteSpecEvent_ScanLoop:
	ld bc, ix				; BC = current index
	muls bc, 0x000c				; BC = index * 12 (entry size)
	lda xwa, (0x02bc34:24); XWA = base of registration table
	lda_rr	xwa, xwa, bc
	lda xbc, (xwa + 4)			; XBC = pointer to entry+4 (event code)
	ld xde, (xbc)				; XDE = registered event code
	cp xde, EVT_ASSSWB			; compare with key press event
	jr nz, DeleteSpecEvent_Match			; no match, skip this entry
	; --- Event code matches: check filter ---
	lda xde, (xwa + 8)			; XDE = pointer to entry+8 (filter)
	ld xwa, (xde)				; XWA = registered filter value
	ld	wa, 0:i3
	ld xiy, (xsp + 12)			; XIY = original event param
	and xiy, 0xffff0000			; isolate upper 16 bits
	cp xiy, xwa				; compare filter with event param upper bits
	jr nz, DeleteSpecEvent_Match			; no match
	; --- Filter matches: update registration and accumulate bits ---
	ld xwa, EVT_NONE			; mark as active (clear low 16 bits)
	ld (xbc), xwa				; write updated event code to entry+4
	ld xwa, (xde)				; reload filter value
	ld xbc, xwa				; copy to XBC
	and xbc, 0x000000ff			; XBC low byte = filter byte 0
	ld b, c					; B = filter byte 0
	srl xwa, 8				; shift filter right 8
	and xwa, 0x000000ff			; isolate byte
	ld e, a					; E = filter byte 1
	ld c, b					; C = filter byte 0
	cpl c					; C = ~filter byte 0 (complement)
	ldto_berp	a, 251
	and a, c				; clear bits in QIZH where filter has 1s
	ldfr_berp	a, 251
	and e, b				; E = filter & filter (= filter)
	ldto_berp	a, 251
	add a, e				; set bits in QIZH where filter has 1s
	ldfr_berp	a, 251
	or (xsp + 8), b				; accumulate filter byte 0 into (xsp+8)
DeleteSpecEvent_Match:
	; --- Advance to next registration entry ---
	cp ix, hl				; reached end sentinel?
	jr z, DeleteSpecEvent_Epilogue			; yes, done scanning
	cp ix, 0x03ff				; check for index wrap
	jr nz, DeleteSpecEvent_CheckNext			; no wrap needed
	ld	ix, 0:i3
	jr DeleteSpecEvent_Return				; skip increment
DeleteSpecEvent_CheckNext:
	inc 1, ix				; next entry index
DeleteSpecEvent_Return:
	cp ix, hl				; check end again
	jr nz, DeleteSpecEvent_ScanLoop			; continue scanning
DeleteSpecEvent_Epilogue:
	; --- Done scanning: release lock and reassemble event param ---
	ld	wa, 4:i3
	call TaskSched_SignalEvent				; release lock/semaphore
	ld c, (xsp + 6)				; C = param byte 0
	cpl c					; C = ~param byte 0
	ldto_berp	a, 251
	and a, c				; clear bits
	ldfr_berp	a, 251
	ld c, (xsp + 10)			; C = param byte 1
	and c, (xsp + 6)			; C = byte1 & byte0
	ldto_berp	a, 251
	add a, c				; accumulate
	ldfr_berp	a, 251
	ld a, (xsp + 6)				; A = param byte 0
	or (xsp + 8), a				; accumulate into (xsp+8)
	; --- Build final XDE from accumulated data ---
	ld xwa, 0xffff0000			; mask for upper 16 bits
	and (xsp + 2), xwa			; keep upper 16 bits of working param
	ld	xbc, 0:i3
	ldto_berp	c, 251
	sll xbc, 8				; shift QIZH value into byte 1 position
	ld	xwa, 0:i3
	ld a, (xsp + 8)				; A = accumulator byte
	add xwa, xbc				; merge
	add (xsp + 2), xwa			; merge into working param
	; --- Dispatch event ---
	ld xwa, (xsp + 20)			; restore target workspace
	ld xbc, (xsp + 16)			; restore event code
	ld xde, (xsp + 2)			; load modified event param
MainSendEvent_Prologue:
	calr	ApPostEvent
	pop qiz					; restore QIZ
	lda xsp, (xsp + 22)			; deallocate stack frame
	ret


GetCurrentTarget:
	ld xhl, (0x02f83c:24)
	ret

SetCurrentTarget:
	cp xwa, 0xffffffff
	ret z
	ld (0x02f83c:24), xwa
	ret

MainDispatchEvent:
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr MainGetEvent
	cp hl, 0:i3
	jr z, MainSendEvent_Dispatch

; MainSendEvent object dispatch
MainSendEvent_VirtualDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xffffffff
	jr z, MainSendEvent_Return
	ld xwa, (xsp + 8)
	srl xwa, 16
	and xwa, 0xfff
	ld xde, (xsp + 8)
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xhl, (xde)
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, (xsp)
	call (xhl)

MainSendEvent_Return:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr MainGetEvent
	cp hl, 0:i3
	jr nz, MainSendEvent_VirtualDispatch

MainSendEvent_Dispatch:
	lda xsp, (xsp + 12)
	ret

MainSendEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	cp xiz, 0xffffffff
	jr nz, MainPostEvent_VirtualDispatch
	ld xhl, 0:i3
	jr MainPostEvent_Return

; MainPostEvent queued dispatch with validation
MainPostEvent_VirtualDispatch:
	ld xwa, xiz
	ld xbc, EVT_CHECK_CLASS
	ld xde, NAKA_CLASS_MainFunction
	calr SendEvent
	or xhl, xhl
	jr z, MainPostEvent_ReturnZero
	ld xwa, xiz
	srl xwa, 16
	and xwa, 0xfff
	ld xde, xiz
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xix, (xde)
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call (xix)
	jr MainPostEvent_Return

MainPostEvent_ReturnZero:
	ld xhl, 0:i3

MainPostEvent_Return:
	pop xiz
	inc 8, xsp
	ret

MainPostEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 7:i3
	jr MainPostEvent_Allocate

MainPostEvent_VirtDispatch_Prologue:
	ld wa, 7:i3
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cp hl, 0:i3
	jrl z, MainGetEvent_ScanMatch
	ld wa, 3:i3
	call TaskSched_YieldToQueue
	ld wa, 7:i3

MainPostEvent_Allocate:
	call TaskSched_WaitForEvent
	ld wa, (0x02f83a:24)
	ld de, wa
	inc 1, de
	ld bc, (0x02f838:24)
	cp de, bc
	jr z, MainPostEvent_VirtDispatch_Prologue
	sub wa, 0xff
	cp wa, bc
	jr z, MainPostEvent_VirtDispatch_Prologue
	incw 1, (0x02f842:24)
	ld wa, (0x02f83a:24)
	muls wa, 0xc
	lda xbc, (0x02ec38:24)
	ld	(xbc+wa), xiz
	ld wa, (0x02f83a:24)
	muls wa, 0xc
	lda	xde, (xbc+wa)
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ld wa, (0x02f83a:24)
	muls wa, 0xc
	lda	xbc, (xbc+wa)
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ld wa, (0x02f83a:24)
	cp wa, 0xff
	jr nz, MainGetEvent_Prologue
	ldw (0x02f83a:24), 0x0000
	jr MainGetEvent_ScanLoop

MainGetEvent_Prologue:
	inc 1, wa
	ld (0x02f83a:24), wa

MainGetEvent_ScanLoop:
	ld wa, 7:i3
	call TaskSched_SignalEvent

MainGetEvent_ScanMatch:
	pop xiz
	inc 8, xsp
	ret

MainGetEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 7:i3
	call TaskSched_WaitForEvent
	ld wa, (0x02f838:24)
	cp wa, (0x02f83a:24)
	jr nz, MainGetEvent_ScanDone
	ld wa, 7:i3
	call TaskSched_SignalEvent
	ld hl, 0:i3
	jr MainGetEvent_Return

MainGetEvent_ScanDone:
	decw 1, (0x02f842:24)
	ld de, (0x02f838:24)
	ld bc, de
	muls bc, 0xc
	lda xwa, (0x02ec38:24)
	lda	xhl, (xwa+bc)
	ld xwa, (xhl)
	ld (xiz), xwa
	ld xwa, (xsp + 8)
	ld xbc, (xhl + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 4)
	ld xbc, (xhl + 8)
	ld (xwa), xbc
	cp de, 0xff
	jr nz, MainGetEvent_ReturnOne
	ldw (0x02f838:24), 0x0000
	jr MainGetEvent_ReturnOneAlt

MainGetEvent_ReturnOne:
	incw 1, (0x02f838:24)

MainGetEvent_ReturnOneAlt:
	ld wa, 7:i3
	call TaskSched_SignalEvent
	ld hl, 1:i3

MainGetEvent_Return:
	pop xiz
	inc 8, xsp
	ret

MainDeleteEvent:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld wa, 7:i3
	call TaskSched_WaitForEvent
	ld bc, (0x02f83a:24)
	ld wa, (0x02f838:24)
	cp wa, bc
	jr nz, MainDeleteEvent_Prologue
	ld wa, 7:i3
	jr MainDeleteEvent_Epilogue

MainDeleteEvent_Prologue:
	ld ix, wa
	cp wa, bc
	jr z, MainDeleteEvent_ReturnAlt
	lda xiy, (0x02ec38:24)

MainDeleteEvent_ScanLoop:
	ld wa, ix
	muls wa, 0xc
	lda	xhl, (xiy+wa)
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, MainDeleteEvent_Match
	cp (xhl), xiz
	jr nz, MainDeleteEvent_Match
	ld xwa, EVT_NONE
	ld (xde), xwa

MainDeleteEvent_Match:
	cp ix, bc
	jr z, MainDeleteEvent_ReturnAlt
	cp ix, 0x3ff
	jr nz, MainDeleteEvent_CheckNext
	ld ix, 0:i3
	jr MainDeleteEvent_Return

MainDeleteEvent_CheckNext:
	inc 1, ix

MainDeleteEvent_Return:
	cp ix, bc
	jr nz, MainDeleteEvent_ScanLoop

MainDeleteEvent_ReturnAlt:
	ld wa, 7:i3

MainDeleteEvent_Epilogue:
	call TaskSched_SignalEvent
	pop xiz
	inc 4, xsp
	ret

MainDeleteSpecificEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 7:i3
	call TaskSched_WaitForEvent
	ld bc, (0x02f83a:24)
	ld wa, (0x02f838:24)
	cp wa, bc
	jr nz, MainDeleteSpecEvent_Prologue
	ld wa, 7:i3
	jr MainDeleteSpecEvent_Epilogue

MainDeleteSpecEvent_Prologue:
	ld hl, wa
	cp wa, bc
	jr z, MainDeleteSpecEvent_Return
	lda xix, (0x02ec38:24)

MainDeleteSpecEvent_ScanLoop:
	ld wa, hl
	muls wa, 0xc
	lda	xiy, (xix+wa)
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, EVT_NONE
	ld (xde), xwa

ObjectSearch_ContinueLoop:
	cp hl, bc
	jr z, MainDeleteSpecEvent_Return
	cp hl, 0x3ff
	jr nz, MainDeleteSpecEvent_Match
	ld hl, 0:i3
	jr MainDeleteSpecEvent_CheckNext

MainDeleteSpecEvent_Match:
	inc 1, hl

MainDeleteSpecEvent_CheckNext:
	cp hl, bc
	jr nz, MainDeleteSpecEvent_ScanLoop

MainDeleteSpecEvent_Return:
	ld wa, 7:i3

MainDeleteSpecEvent_Epilogue:
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp
	ret

ApPostEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld wa, 4:i3
	jr ObjectSearch_Continue

ObjectSearch_CheckLoop:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cp hl, 0:i3
	jrl z, ApDeliveryEvent_Prologue
	ld wa, 3:i3
	call TaskSched_YieldToQueue
	ld wa, 4:i3

ObjectSearch_Continue:
	call TaskSched_WaitForEvent
	ld wa, (0x02ec36:24)
	ld de, wa
	inc 1, de
	ld bc, (0x02ec34:24)
	cp de, bc
	jr z, ObjectSearch_CheckLoop
	sub wa, 0x3ff
	cp wa, bc
	jr z, ObjectSearch_CheckLoop
	incw 1, (0x02f840:24)
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda xbc, (0x02bc34:24)
	ld	(xbc+wa), xiz
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda	xde, (xbc+wa)
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda	xbc, (xbc+wa)
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ld wa, (0x02ec36:24)
	cp wa, 0x3ff
	jr nz, ApPostEvent_ReturnZero
	ldw (0x02ec36:24), 0x0000
	jr ApPostEvent_Return

ApPostEvent_ReturnZero:
	inc 1, wa
	ld (0x02ec36:24), wa

ApPostEvent_Return:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	ld wa, 2:i3
	call TaskSched_SignalEvent

ApDeliveryEvent_Prologue:
	pop xiz
	inc 8, xsp
	ret

ApDeliveryEvent:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld wa, 4:i3
	jr ApDeliveryEvent_Deliver

ApDeliveryEvent_ScanLoop:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cp hl, 0:i3
	jrl z, ApTimer_Deliver
	ld wa, 3:i3
	call TaskSched_YieldToQueue
	ld wa, 4:i3

ApDeliveryEvent_Deliver:
	call TaskSched_WaitForEvent
	ld wa, (0x02ec36:24)
	ld de, wa
	inc 1, de
	ld bc, (0x02ec34:24)
	cp de, bc
	jr z, ApDeliveryEvent_ScanLoop
	sub wa, 0x3ff
	cp wa, bc
	jr z, ApDeliveryEvent_ScanLoop
	cp xiz, 0xffffffff
	jr z, ApDeliveryEvent_ReturnZero
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld (xhl), xiz
	ld xwa, (xsp + 12)
	ld (xhl + 4), xwa
	ld xwa, (xsp + 8)
	ld (xhl + 8), xwa
	ld xiz, 0xffffffff
	ld xwa, EVT_DELIVERY_EVENT
	ld (xsp + 12), xwa
	ld (xsp + 8), xhl
	jr ApDeliveryEvent_Return

ApDeliveryEvent_ReturnZero:
	ld xwa, 0:i3
	ld (xsp + 4), xwa

ApDeliveryEvent_Return:
	incw 1, (0x02f840:24)
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda xbc, (0x02bc34:24)
	ld	(xbc+wa), xiz
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda	xde, (xbc+wa)
	ld xwa, (xsp + 12)
	ld (xde + 4), xwa
	ld wa, (0x02ec36:24)
	muls wa, 0xc
	lda	xbc, (xbc+wa)
	ld xwa, (xsp + 8)
	ld (xbc + 8), xwa
	ld wa, (0x02ec36:24)
	cp wa, 0x3ff
	jr nz, ApTimer_Prologue
	ldw (0x02ec36:24), 0x0000
	jr ApTimer_ScanLoop

ApTimer_Prologue:
	inc 1, wa
	ld (0x02ec36:24), wa

ApTimer_ScanLoop:
	ld wa, 4:i3
	call TaskSched_SignalEvent
	ld wa, 2:i3
	call TaskSched_SignalEvent
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, ApTimer_Deliver
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, (xsp + 4)
	calr ApPostEvent

ApTimer_Deliver:
	pop xiz
	lda xsp, (xsp + 12)
	ret

InitializeTimer:
	ld xwa, 0:i3
	ld (0x030444:24), xwa
	ldw (0x030448:24), 0xffff
	lda xwa, (0x02f844:24)
	lda xbc, (xwa + 8)
	lda xde, (xwa + 2)
	ld xhl, xwa
	lda xix, (xwa+3072)

ApTimer_DeliverDone:
	ldw (xhl), 0xffff
	ldw (xde), 0xffff
	ld xwa, 0xffffffff
	ld (xbc), xwa
	lda xhl, (xhl + 24)
	lda xde, (xde + 24)
	lda xbc, (xbc + 24)
	cp xhl, xix
	jr c, ApTimer_DeliverDone
	ret
RootContext_InitEventQueue:

ApTimer:
	dec 8, xsp
	push xiz
	cpw (0x030448:24), 0xffff
	jrl nz, SetApTimer_Return
	jrl ApTimer_IncrementCounter

ApTimer_VirtDispatch_Prologue:
	ld xiz, (xbc + 12)
	ld xwa, (xbc + 16)
	ld (xsp + 4), xwa
	ld xwa, (xbc + 20)
	ld (xsp + 8), xwa
	cp xiz, 0xffffffff
	jr nz, ApTimer_VirtDispatch_Return
	calr GetCurrentTarget
	ld xiz, xhl

ApTimer_VirtDispatch_Return:
	ld wa, (0x030448:24)
	muls wa, 0x18
	lda xhl, (0x02f844:24)
	lda	xix, (xhl+wa)
	lda xwa, (xix + 2)
	cp xiz, 0xffffffff
	jr nz, SetApTimer_Prologue
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	lda	xhl, (xhl+wa)
	ld xwa, 0xffffffff
	ld (xhl + 8), xwa
	ld (0x030448:24), bc
	cp bc, 0xffff
	jrl z, ApTimer_IncrementCounter
	jr SetApTimer_Allocate

SetApTimer_Prologue:
	ld xbc, xiz
	srl xbc, 16
	and xbc, 0xfff
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda xbc, (0x027ed6:24)
	add xbc, xde
	ld xde, (xbc)
	or xde, xde
	jr nz, RootContext_Setup
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	lda	xhl, (xhl+wa)
	ld xwa, 0xffffffff
	ld (xhl + 8), xwa
	ld (0x030448:24), bc
	cp bc, 0xffff
	jrl z, ApTimer_IncrementCounter

SetApTimer_Allocate:
	muls bc, 0x18
	ldw	(xde+bc), 0xffff
	jrl SetApTimer_Return

; RootContext setup handler
RootContext_Setup:
	ld (0x02bc24:24), xiz
	ld (0x02bc18:24), xiz
	ld xwa, (xsp + 4)
	ld (0x02bc28:24), xwa
	ld (0x02bc1c:24), xwa
	ld xwa, (xsp + 8)
	ld (0x02bc2c:24), xwa
	ld (0x02bc20:24), xwa
	ld xix, xde
	ld xwa, xiz
	ld xbc, EVT_GET_CLASS_SP
	ld xde, 0:i3
	call (xix)
	ld (0x02bc14:24), xhl
	ld xwa, xhl
	srl xwa, 16
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda xwa, (0x027edc:24)
	add xwa, xbc
	ld xde, (xwa)
	extz xhl
	ld xbc, xhl
	add xbc, xbc
	add xbc, xhl
	sll xbc, 3
	add xbc, xde
	ld xde, (xbc)
	ld wa, (0x030448:24)
	muls wa, 0x18
	lda xhl, (0x02f844:24)
	exts xwa
	add xwa, xhl
	ld bc, (xwa + 2)
	ldw (xwa), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ld wa, (0x030448:24)
	muls wa, 0x18
	lda	xix, (xhl+wa)
	ld xwa, 0xffffffff
	ld (xix + 8), xwa
	ld (0x030448:24), bc
	cp bc, 0xffff
	jr z, ApTimer_VirtualDispatch
	muls bc, 0x18
	ldw	(xhl+bc), 0xffff

; ApTimer dispatcher
ApTimer_VirtualDispatch:
	ld xhl, xde
	ld xwa, xiz
	ld xbc, (xsp + 4)
	ld xde, (xsp + 8)
	call (xhl)
	cpw (0x030448:24), 0xffff
	jr z, ApTimer_IncrementCounter

SetApTimer_Return:
	ld bc, (0x030448:24)
	muls bc, 0x18
	lda xwa, (0x02f844:24)
	exts xbc
	add xbc, xwa
	ld xwa, (xbc + 4)
	cp xwa, (0x030444:24)
	jrl ule, ApTimer_VirtDispatch_Prologue

ApTimer_IncrementCounter:
	ld xwa, 1:i3
	add (0x030444:24), xwa
	pop xiz
	inc 8, xsp
	ret

SetApTimer:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld bc, 0:i3

ResetApTimer_Prologue:
	ld wa, bc
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 3
	lda xhl, (0x02f844:24)
	ld (xsp + 4), xhl
	add xhl, xde
	lda xix, (xhl + 8)
	ld xwa, (xix)
	cp xwa, 0xffffffff
	jrl nz, ResetApTimer_ReturnOne
	lda xde, (xhl + 4)
	ld xwa, (0x030444:24)
	add xwa, (xsp + 16)
	ld (xde), xwa
	ld xwa, (xsp + 12)
	ld (xix), xwa
	ld xwa, (xsp + 8)
	ld (xhl + 12), xwa
	ld xwa, (xsp + 28)
	ld (xhl + 16), xwa
	ld xwa, (xsp + 24)
	ld (xhl + 20), xwa
	ld ix, (0x030448:24)
	cp ix, 0xffff
	jr z, ResetApTimer_ReturnAlt
	ldw iy, 0xffff
	jr ResetApTimer_Match

ResetApTimer_ScanLoop:
	ld iy, ix
	ld ix, (xiz + 2)
	cp ix, 0xffff
	jr z, ResetApTimer_MatchPartial

ResetApTimer_Match:
	ld iz, ix
	muls iz, 0x18
	ld xwa, (xsp + 4)
	exts xiz
	add xiz, xwa
	ld xwa, (xiz + 4)
	cp xwa, (xde)
	jr ule, ResetApTimer_ScanLoop

ResetApTimer_MatchPartial:
	ld (xhl), iy
	ld (xhl + 2), ix
	cp iy, 0xffff
	jr z, ResetApTimer_NotFound
	muls iy, 0x18
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+iy)
	ld (xwa + 2), bc

ResetApTimer_NotFound:
	cp ix, 0xffff
	jr z, ResetApTimer_ReturnZero
	ld de, ix
	muls de, 0x18
	ld xwa, (xsp + 4)
	ld	(xwa+de), bc

ResetApTimer_ReturnZero:
	cp ix, (0x030448:24)
	jr nz, ResetApTimer_ReturnOneDone

ResetApTimer_ReturnAlt:
	ld (0x030448:24), bc
	jr ResetApTimer_ReturnOneDone

ResetApTimer_ReturnOne:
	inc 1, bc
	cp bc, 0x80
	jrl c, ResetApTimer_Prologue

ResetApTimer_ReturnOneDone:
	cp bc, 0x80
	jr nz, ResetApTimer_Epilogue
	pop xiz
	lda xsp, (xsp + 16)

ResetApTimer_Return:
	jr ResetApTimer_Return

ResetApTimer_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x8

ResetApTimer:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 24)
	push xwa
	ld xiz, (xsp + 24)
	push xiz
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	calr KillApTimer
	cp hl, 0:i3
	jr z, KillApTimer_ReturnZero
	ld xwa, (xsp + 24)
	push xwa
	push xiz
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	calr SetApTimer
	ld hl, 1:i3
	jr KillApTimer_Return

KillApTimer_ReturnZero:
	ld hl, 0:i3

KillApTimer_Return:
	pop xiz
	lda xsp, (xsp + 12)
	retd 0x8

KillApTimer:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld ix, (0x030448:24)
	cp ix, 0xffff
	jrl z, KillApTimer_CheckNextEntry_Return
	lda xiy, (0x02f844:24)

KillApTimer_CheckNextEntry_Loop:
	ld wa, ix
	muls wa, 0x18
	lda	xhl, (xiy+wa)
	lda xde, (xhl + 8)
	lda xiz, (xhl + 2)
	cp (xde), xbc
	jr nz, ApTimer_KillApTimer_CheckNextEntry
	ld xwa, (xhl + 12)
	cp xwa, (xsp + 4)
	jr nz, ApTimer_KillApTimer_CheckNextEntry
	ld xwa, (xhl + 16)
	cp xwa, (xsp + 16)
	jr nz, ApTimer_KillApTimer_CheckNextEntry
	ld xwa, (xhl + 20)
	cp xwa, (xsp + 12)
	jr nz, ApTimer_KillApTimer_CheckNextEntry
	ld xbc, xiz
	ld wa, (xiz)
	cp wa, 0xffff
	jr z, KillApTimer_CheckNextEntry_Match
	muls wa, 0x18
	ld iz, wa
	ld wa, (xhl)
	ld	(xiy+iz), wa

KillApTimer_CheckNextEntry_Match:
	cpw (xhl), 0xffff
	jr z, KillApTimer_CheckNextEntry_Unlink
	ld wa, (xhl)
	muls wa, 0x18
	lda	xiy, (xiy+wa)
	ld wa, (xbc)
	ld (xiy + 2), wa

KillApTimer_CheckNextEntry_Unlink:
	cp ix, (0x030448:24)
	jr nz, KillApTimer_CheckNextEntry_Done
	ld wa, (xbc)
	ld (0x030448:24), wa

KillApTimer_CheckNextEntry_Done:
	ld xwa, 0xffffffff
	ld (xde), xwa
	ldw (xbc), 0xffff
	ldw (xhl), 0xffff
	ld hl, 1:i3
	jr KillApTimer_CheckNextEntry_Epilogue

ApTimer_KillApTimer_CheckNextEntry:
	ld ix, (xiz)
	cp ix, 0xffff
	jrl nz, KillApTimer_CheckNextEntry_Loop

KillApTimer_CheckNextEntry_Return:
	ld hl, 0:i3

KillApTimer_CheckNextEntry_Epilogue:
	pop xiz
	inc 4, xsp
	retd 0x8
	push xiz

DrawTask_EventLoop:
	calr DrawTask_Dispatch
	ld xiz, xhl
	cpw (0x03ef4e:24), 0
	jr z, DrawTask_FuncDispatch
	ld wa, 5:i3
	ld bc, 3:i3
	call TaskSched_ChangePriority

; DrawTask function dispatch with priority
DrawTask_FuncDispatch:
	or xiz, xiz
	jr z, DrawTask_DequeueLoop
	ld xhl, (xiz)
	ld xwa, xiz
	call (xhl)
	ld xwa, xiz
	calr DrawFunc_Return
	cpw (0x03ef4e:24), 0
	jr z, DrawTask_EventLoop
	ld wa, 5:i3
	ld bc, 3:i3
	call TaskSched_ChangePriority
	jr DrawTask_EventLoop

DrawTask_DequeueLoop:
	ld wa, (0x030450:24)
	ld (0x03044e:24), wa
	ld wa, 1:i3
	call Audio_Lock_Acquire
	jr DrawTask_EventLoop

InitDrawTask:
	jr DrawTask_DequeueLoop_Check

DrawTask_DequeueLoop_Check:
	ld wa, 3:i3
	call TaskSched_WaitForEvent
	calr DrawRing_Init
	ld wa, 3:i3
	jp TaskSched_SignalEvent

DrawTask_Dispatch:
	push xiz
	ld wa, 3:i3
	call TaskSched_WaitForEvent
	calr DrawRing_TryTake
	ld xiz, xhl
	ld wa, 3:i3
	call TaskSched_SignalEvent
	ld xhl, xiz
	pop xiz
	ret


; ============================================================================
; DrawRing_Post - post one draw command to the draw task's ring, waiting while it is full
; ============================================================================
; Input:  XWA = the command (a DrawQueue_Alloc record pointer)
; Output: XHL = the ring slot it was stored in
; Under event 3 (TaskSched_WaitForEvent / SignalEvent) it calls DrawRing_TryPost, which
; stores XWA at the ring's write index (RAM 0x03247C, 0x80 bytes of u32 entries; fields
; at -10 alloc, -8 read, -4 write, -2 free bytes) when more than 4 bytes are free, and
; returns 0 when the ring is full; then it lowers its priority (TaskSched_ChangePriority
; 5, 2) and tries again.  The draw task takes entries with DrawRing_TryTake and runs them
; through DrawTask_FuncDispatch.  Named DisplayCmd_DequeueAndExecute until 2026-10-02.
; ============================================================================
DrawRing_Post:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa

DrawRing_Post_Retry:
	ld wa, 3:i3
	call TaskSched_WaitForEvent
	ld xwa, (xsp + 4)
	calr DrawRing_TryPost
	ld xiz, xhl
	ld wa, 3:i3
	call TaskSched_SignalEvent
	or xiz, xiz
	jr nz, DrawRing_Post_Check
	ld wa, 5:i3
	ld bc, 2:i3
	call TaskSched_ChangePriority

DrawRing_Post_Check:
	or xiz, xiz
	jr z, DrawRing_Post_Retry
	ld xhl, xiz
	pop xiz
	inc 4, xsp
	ret

DrawRing_Post_Return:
	ret

DrawRing_Init:
	lda xde, (0x03247c:24)
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x7f
	lda xwa, (0x030466:24)
	ld (0x032466:24), xwa
	ld (0x03246a:24), xwa
	ret

DrawRing_TryTake:
	lda xde, (0x03247c:24)
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, DrawRing_TryTake_Load
	ld xhl, 0:i3
	ret

DrawRing_TryTake_Load:
	ld	xhl, (xde+ix)
	minc4_16 ix, 0x7c
	ld (xde - 8), ix
	incw 4, (xde - 2)
	ret

DrawRing_TryPost:
	lda xde, (0x03247c:24)
	cpw (xde - 2), 0x4
	jr gt, DrawRing_TryPost_Store
	lda_dd8l XHL, (0x00)
	ret

DrawRing_TryPost_Store:
	ld ix, (xde - 4)
	ld	(xde+ix), xwa
	minc4_16 ix, 0x7c
	ld (xde - 4), ix
	decw	4, (xde-2)
	ld hl, ix
	extz xhl
	add xhl, xde
	push xhl
	ld a, 0x1:opc
	call Audio_Lock_Release
	pop xhl
	ret

DisplayCmd_Return:
	ld ix, (0x032474:24)
	ld (0x032472:24), ix
	ret

DrawQueue_Alloc_Prologue:
	lda xde, (0x03247c:24)
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, DrawQueue_Alloc_FindSlot
	ld xhl, 0:i3
	ret

DrawQueue_Alloc_FindSlot:
	ld	xhl, (xde+ix)
	minc4_16 ix, 0x7c
	ld (xde - 10), ix
	ret

; ============================================================================
; DrawQueue_Alloc - Allocate space in the draw command queue
; ============================================================================
; Input:  WA = size in bytes to allocate
; Output: XHL = pointer to allocated buffer in draw queue
; Manages a circular buffer at 0x030466 (8KB max, 0x2000 bytes).
; Wraps around when the write pointer would exceed the buffer end.
; Protected by event 4 acquire/release for thread safety.
; ============================================================================
DrawQueue_Alloc:
	push xiz
	ld iz, wa
	ld wa, 4:i3
	call Audio_Lock_Acquire
	ld de, iz
	extz xde
	lda xhl, (0x030466:24)
	ld xbc, (0x03246a:24)
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xde
	ld de, iz
	extz xde
	cp xwa, 0x2000
	jr ge, DrawFunc_Prologue
	ld xiz, xbc
	add xbc, xde
	ld (0x03246a:24), xbc
	jr DrawFunc_CallHandler

DrawFunc_Prologue:
	ld xiz, xhl
	add xhl, xde
	ld (0x03246a:24), xhl

; DrawFunc handler with audio lock release
DrawFunc_CallHandler:
	ld wa, 4:i3
	call Audio_Lock_Release
	ld xhl, xiz
	pop xiz
	ret

DrawFunc_Return:
	ret

DrawFunc:
	push xiz
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, DrawFunc_CheckStack
	push xiz
	ld xhl, xiz
	call (xhl)
	pop xiz
	jr DrawFunc_StackSetup

DrawFunc_CheckStack:
	ld wa, 3:i3
	call TaskSched_WaitForEvent
	calr DisplayCmd_Return
	jr DrawFunc_DispatchDone

DrawFunc_Dispatch:
	lda xbc, (xhl + 4)
	cp xiz, (xbc)
	jr nz, DrawFunc_DispatchDone
	ld xwa, 0:i3
	ld (xbc), xwa

DrawFunc_DispatchDone:
	calr DrawQueue_Alloc_Prologue
	or xhl, xhl
	jr nz, DrawFunc_Dispatch
	ld wa, 3:i3
	call TaskSched_SignalEvent
	ldw wa, 0x8
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (DrawFunc_StackHandler:24)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DrawRing_Post

DrawFunc_StackSetup:
	pop xiz
	ret

; DrawFunc stack handler
DrawFunc_StackHandler:
	push	xiz
	ld	xiz, xwa
	ld	xwa, (xiz+4)
	or	xwa, xwa
	jr	z, DrawFunc_Return_Epilogue
	push	xiz
	ld	xhl, (xiz+4)
	call	(xhl)
	pop	xiz
DrawFunc_Return_Epilogue:
	pop	xiz
	ret
	ret

DrawFunc_StackEntry:
	ld xwa, (xsp + 4)
	jr DrawFunc
DrawFunc_StackEntry_Join:
	push xiz
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, DrawFunc_StackEntry_Prologue
	push xiz
	ld xhl, xiz
	call (xhl)
	pop xiz
	jr DrawFunc_XspCheck_Prologue

DrawFunc_StackEntry_Prologue:
	ldw wa, 0x8
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (DrawFunc_StackHandler:24)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DrawRing_Post

DrawFunc_XspCheck_Prologue:
	pop xiz
	ret

; DrawFunc XSP region check variant
DrawFunc_XspCheck:
	push	xiz
	ld	xiz, xwa
	ld	xwa, (xiz+4)
	or	xwa, xwa
	jr	z, DrawFunc_StackEntry_Epilogue
	push	xiz
	ld	xhl, (xiz+4)
	call	(xhl)
	pop	xiz
DrawFunc_StackEntry_Epilogue:
	pop	xiz
	ret
	ld	xwa, (xsp+4)
	jr	DrawFunc_StackEntry_Join


IS_XSP_INSIDE_4K_REGION_AT_1C032:
	xor xhl, xhl
	cp xsp, 0x1c032
	jr lt, DrawFunc_XspCheck_Loop
	cp xsp, 0x1d032
	jr gt, DrawFunc_XspCheck_Loop
	inc 1, xhl

DrawFunc_XspCheck_Loop:
	ret

InitializeGraphics:
	dec 8, xsp
	push xiz
	calr InitDrawTask
	ld wa, 5:i3
	call Show_ScreenGroup
	ldw (0x03ef92:24), 0x0001
	call InitPaletteRGB
	ld wa, 0:i3
	calr ChangeWall
	ld wa, 2:i3
	calr ChangePalette
	ld wa, 0:i3
	calr ChangeWallPalette
	lda xwa, (0x043c00:24)
	ld xiz, xwa
	pushw 0x9600
	pushw 0x0
	push xwa
	call Memset
	add xiz, 0x9600
	pushw 0x9600
	pushw 0x0
	push xiz
	call Memset
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 4)
	ldw (xwa + 2), 0x0
	ldw (xwa), 0x0
	ldw (xwa + 4), 0x13f
	ldw (xwa + 6), 0xef
	calr SetChangeRect
	calr UpdateScreen
	calr LcdOn
	pop xiz
	inc 8, xsp
	ret

; LcdOn - Enable LCD display output (sets flag at 0x030464)
LcdOn:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr nz, InitGraphics_SetupVRAM_Loop
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (InitGraphics_SetupVRAM:24)
	ld (xwa), xbc
	jrl DrawRing_Post

InitGraphics_SetupVRAM:
	jr InitGraphics_SetupVRAM_Loop

InitGraphics_SetupVRAM_Loop:
	ldw (0x030464:24), 0x0001
	jp VGA_ScreenUnblank

; LcdOff - Disable LCD display output (clears flag at 0x030464)
LcdOff:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr nz, LcdOn_Return
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (LcdOn_Done:24)
	ld (xwa), xbc
	jrl DrawRing_Post

LcdOn_Done:
	jr LcdOn_Return

LcdOn_Return:
	call VGA_ScreenBlank
	ldw (0x030464:24), 0x0000
	ret


LcdOff_Done:
	cpw (0x030464:24), 0
	ret z

	call VGA_ScreenUnblank
	ret


LcdOff_Return:
	cpw (0x030464:24), 0
	ret z

	call VGA_ScreenBlank
	ret


; =============================================================================
; UpdateScreen - Blit offscreen buffer to VRAM (main display update)
;
; Called from the main loop to copy changed regions from OFFSCREEN_BUFFER_1
; (0x43c00) to VIDEO_RAM (0x1a0000). The actual blit is performed by
; Gfx_BlitDirtyRegions which:
;
; 1. Checks if palette update is pending (0x03ef9e palette index)
;    - Full palette update: iterates all 256 DAC entries (0x00-0xff)
;    - Partial palette update: iterates entries 0xe0-0xef only
; 2. Examines dirty bounding box at 0x030456:
;    - If full screen (0,0)-(319,239): calls full-screen blit (0xfb30a9)
;    - Otherwise: calls partial blit (DisplayBuffer_Process) for dirty rows only
; 3. Resets dirty state: clears bounding box, update flags
;
; Dirty bounding box (0x030456): {x_min, y_min, x_max, y_max}
; Frame counter at 0x030450 gates updates (0 = update allowed)
;
; DisplayBuffer_Process (partial blit): copies row-by-row from offscreen to VRAM,
; only for rows within the dirty bounding box. Processes rows in two passes
; (even lines first, then remaining) for potential interlace support.
; =============================================================================
UpdateScreen:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, UpdateScreen_Prologue
	calr Gfx_BlitDirtyRegions
	ld wa, (0x030450:24)
	cp wa, 0:i3
	ret nz
	ld (0x03044e:24), wa
	ret

UpdateScreen_Prologue:
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (UpdateScreen_CheckDirty:24)
	ld (xwa), xbc
	calr DrawRing_Post
	ret

UpdateScreen_CheckDirty:
	calr	Gfx_BlitDirtyRegions
	ld	wa, (0x030450:24)
	cp	wa, 0:i3
	ret	nz
	ld	(0x03044e:24), wa
	ret

Gfx_BlitDirtyRegions:
	dec 8, xsp
	pushw iz
	cpw (0x03ef92:24), 0
	jrl z, SetChangeRect_Prologue
	cpw (0x03045e:24), 0
	jrl z, SetChangeRect_Prologue
	cpw (0x030460:24), 0
	jr z, Gfx_BlitDirty_ScanMatch
	ld wa, (0x03ef9e:24)
	cp wa, 4:i3
	jr nz, Gfx_BlitDirty_Prologue
	cpw (0x03efa0:24), 4
	jr z, Display_CheckScreenDimensions
	cp wa, 4:i3
	jr nz, Display_CheckScreenDimensions

Gfx_BlitDirty_Prologue:
	calr LcdOn_Return
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	ld iz, 0:i3

Gfx_BlitDirty_ScanLoop:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	ldto_berp A, 0xf8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0x100
	jr c, Gfx_BlitDirty_ScanLoop
	jr Display_CheckScreenDimensions

Gfx_BlitDirty_ScanMatch:
	cpw (0x030462:24), 0
	jr z, Display_CheckScreenDimensions
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	ldw iz, 0xe0

Gfx_BlitDirty_ScanDone:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	ldto_berp A, 0xf8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0xf0
	jr c, Gfx_BlitDirty_ScanDone

Display_CheckScreenDimensions:
	lda xwa, (0x030456:24)
	ld bc, (xwa + 6)
	sub bc, (xwa + 2)
	cp bc, 0xef
	jr nz, Display_CheckDim_Prologue
	ld bc, (xwa + 4)
	sub bc, (xwa)
	cp bc, 0x13f
	jr nz, Display_CheckDim_Prologue
	call AllBOut
	jr Display_CheckDim_CheckWidth

Display_CheckDim_Prologue:
	call DisplayBuffer_Process

Display_CheckDim_CheckWidth:
	cpw (0x030460:24), 0
	jr z, Display_CheckDim_CheckHeight
	calr InitGraphics_SetupVRAM_Loop
	ld wa, (0x03ef9e:24)
	ld (0x03efa0:24), wa
	ldw (0x030460:24), 0x0000
	jr Display_CheckDim_Done

Display_CheckDim_CheckHeight:
	cpw (0x030462:24), 0
	jr z, Display_CheckDim_Return

Display_CheckDim_Done:
	ldw (0x030462:24), 0x0000

Display_CheckDim_Return:
	ldw (0x03045e:24), 0x0000
	lda xwa, (0x030456:24)
	ldw (xwa + 2), 0xf0
	ldw (xwa), 0x140
	ldw (xwa + 4), 0xffff
	ldw (xwa + 6), 0xffff

SetChangeRect_Prologue:
	popw iz
	inc 8, xsp
	ret
SetNeedUpdate:
	ret

; =============================================================================
; SetChangeRect - Update bounding box of changed screen region
;
; Expands the dirty rectangle to include the region described by a 4-word
; structure pointed to by XWA: {x_min, y_min, x_max, y_max}.
; The bounding box is maintained at 0x030456-0x03045c and an update flag
; is set at 0x03045e.
;
; Input:
;   XWA = pointer to 8-byte rect structure {x_min, y_min, x_max, y_max}
; =============================================================================
SetChangeRect:
	push xiz
	ld xiz, xwa
	cpw (0x03ef4e:24), 0
	jr z, SetChangeRect_ClampLeft
	ld wa, 5:i3
	ld bc, 3:i3
	call TaskSched_ChangePriority

SetChangeRect_ClampLeft:
	ldw (0x03045e:24), 0x0001
	lda xde, (0x030456:24)
	lda xbc, (xde + 2)
	ld wa, (xiz + 2)
	cp (xbc), wa
	jr le, SetChangeRect_ClampTop
	ld (xbc), wa

SetChangeRect_ClampTop:
	ld wa, (xde)
	cp wa, (xiz)
	jr le, SetChangeRect_ClampRight
	ld wa, (xiz)
	ld (xde), wa

SetChangeRect_ClampRight:
	lda xbc, (xde + 4)
	ld wa, (xiz + 4)
	cp (xbc), wa
	jr ge, SetChangeRect_ClampBottom
	ld (xbc), wa

SetChangeRect_ClampBottom:
	lda xbc, (xde + 6)
	ld wa, (xiz + 6)
	cp (xbc), wa
	jr ge, SetChangeRect_Apply
	ld (xbc), wa

SetChangeRect_Apply:
	pop xiz
	ret

; =============================================================================
; ReadPixel - Read a pixel color from offscreen buffer 1
;
; Reads the 8-bit color index at (x, y) from OFFSCREEN_BUFFER_1 (0x43c00).
;
; Input:
;   XWA = pointer to coordinate pair: word[0]=x, word[2]=y
;
; Output:
;   HL = pixel color (8-bit index, zero-extended to 16-bit)
;        Returns 0 if coordinates fail validation
; =============================================================================
ReadPixel:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr IsPointOnScreen
	cp hl, 0:i3
	jr z, SetChangeRect_Done
	ld wa, (xiz + 2)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xiz)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43c00
	add xbc, xwa
	ld l, (xbc)
	extz hl
	jr SetChangeRect_Return

SetChangeRect_Done:
	ld hl, 0:i3

SetChangeRect_Return:
	pop xiz
	ret

; =============================================================================
; ModifyPixel - Write a pixel to offscreen buffer 1
;
; Sets a single pixel at (x, y) in OFFSCREEN_BUFFER_1 (0x43c00).
; Color 0xf7 is treated as transparent (no-op). Color 0xf5 triggers a
; read-back from a secondary buffer (at address stored at 0x0304b2).
;
; Input:
;   XWA = pointer to coordinate pair: word[0]=x, word[2]=y
;   BC  = color index (low byte)
;
; Address calculation: OFFSCREEN_BUFFER_1 + y*320 + x
; =============================================================================
ModifyPixel:
	dec 4, xsp
	pushw iz
	ld iz, bc
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	calr IsPointOnScreen
	cp hl, 0:i3
	jr z, ReadPixel_Calculate
	cp iz, 0xf7
	jr z, ReadPixel_Calculate
	cp iz, 0xf5
	jr nz, ReadPixel_Prologue
	ld xwa, (xsp + 2)
	ld bc, (xwa + 2)
	muls bc, 0x140
	add bc, (xwa)
	extz xbc
	add xbc, (0x030452:24)
	ld a, (xbc)
	ldfr_berp A, 0xf8
	extz iz

ReadPixel_Prologue:
	ld xde, (xsp + 2)
	ld wa, (xde + 2)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43c00
	add xbc, xwa
	ldto_berp A, 0xf8
	ld (xbc), a

ReadPixel_Calculate:
	popw iz
	inc 4, xsp
	ret

; =============================================================================
; ModifyPixelEx - Extended pixel operation with multiple drawing modes
;
; Performs a pixel operation at (x, y) in OFFSCREEN_BUFFER_1 (0x43c00)
; using one of several drawing modes specified by DE.
;
; Input:
;   XWA = pointer to coordinate pair: word[0]=x, word[2]=y
;   BC  = color index (low byte)
;   DE  = drawing mode:
;         < 0x201: use translated buffer pointer
;         0x201: direct write  -- buffer[y*320+x] = color
;         0x202: clear pixel   -- buffer[y*320+x] = 0x00
;         0x203: OR operation  -- buffer[y*320+x] |= color
;         0x204: AND operation -- buffer[y*320+x] &= color
;         0x205: XOR operation -- buffer[y*320+x] ^= color
;
; Special colors:
;   0xf7 = transparent (no-op)
;   0xf5 = read-back from secondary buffer (0x0304b2)
; =============================================================================
ModifyPixelEx:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), de
	ld iz, bc
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	calr IsPointOnScreen
	cp hl, 0:i3
	jrl z, DrawLine_Epilogue
	ld wa, iz
	calr IsColorValid
	cp hl, 0:i3
	jrl z, DrawLine_Epilogue
	ld xwa, (xsp + 4)
	ld bc, iz
	calr ClampColorToRange
	ld iz, hl
	cp iz, 0xf7
	jrl z, DrawLine_Epilogue
	cp iz, 0xf5
	jr nz, ModifyPixel_Prologue
	ld xwa, (xsp + 4)
	ld bc, (xwa + 2)
	muls bc, 0x140
	add bc, (xwa)
	extz xbc
	add xbc, (0x030452:24)
	ld a, (xbc)
	ldfr_berp A, 0xf8
	extz iz

ModifyPixel_Prologue:
	cpw (xsp + 2), 0x201
	jr ge, ModifyPixel_Calculate
	ld xwa, (xsp + 4)
	ld bc, (xsp + 2)
	calr ClampColorToRange
	ld (xsp + 2), hl
	ld xde, (xsp + 4)
	ld wa, (xde + 2)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43c00
	add xbc, xwa
	ld wa, (xsp + 2)
	ld (xbc), a
	jrl DrawLine_Epilogue

ModifyPixel_Calculate:
	ldto_berp C, 0xf8
	cpw (xsp + 2), 0x205
	jrl z, ModifyPixelEx_Prologue
	lda xde, (0x043c00:24)
	cpw (xsp + 2), 0x204
	jr z, ModifyPixel_Done
	ld xhl, xde
	ld xiy, (xsp + 4)
	lda xix, (xiy + 2)
	ld wa, (xix)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	cpw (xsp + 2), 0x203
	jr z, ModifyPixel_Write
	cpw (xsp + 2), 0x202
	jr z, ModifyPixel_ApplyMode
	cpw (xsp + 2), 0x201
	jr nz, DrawLine_Epilogue
	ld wa, (xiy)
	exts xwa
	add xwa, xde
	add xhl, xwa
	ld (xhl), c
	jr DrawLine_Epilogue

ModifyPixel_ApplyMode:
	ld wa, (xix)
	ld bc, wa
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	exts xwa
	add xwa, xde
	add xhl, xwa
	ld (xhl), 0x0
	jr DrawLine_Epilogue

ModifyPixel_Write:
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	add xhl, xwa
	or (xhl), c
	jr DrawLine_Epilogue

ModifyPixel_Done:
	ld xix, (xsp + 4)
	ld wa, (xix + 2)
	exts xwa
	ld xhl, xwa
	sll xhl, 2
	add xhl, xwa
	sll xhl, 6
	ld wa, (xix)
	exts xwa
	add xwa, xhl
	add xde, xwa
	and (xde), c
	jr DrawLine_Epilogue

ModifyPixelEx_Prologue:
	ld xhl, (xsp + 4)
	ld wa, (xhl + 2)
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld wa, (xhl)
	exts xwa
	add xwa, xde
	ld xde, 0x43c00
	add xde, xwa
	xor (xde), c

	.include "ui/drawing_primitives.s"
