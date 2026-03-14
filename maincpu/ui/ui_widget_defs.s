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
	cp xiz, 0x1E0008D
	jrl z, AcGridBox_CellSelect
	cp xiz, 0x1E0008B
	jrl z, AcGridBox_GetRowText
	cp xiz, 0x1E0008A
	jrl z, AcGridBox_GetColText
	cp xiz, 0x1C00001
	jr z, AcGridBox_Init
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, AcGridBox_Default
	cp xwa, 0x6
	jrl gt, AcGridBox_Default
	add xwa, xwa
	add xwa, 0xEAA258
	ld wa, (xwa)
	lda_24 xix, 0xf9e9b3
	jp_dri 8, 0x07, 0xF0, 0xE0

AcGridBox_Init:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	calr SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	calr SetDialDown
	lds wa, 1
	jrl AcGridBox_EnableDials
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollUp_Alt
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00019
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollUp_Alt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00019
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	calr SetDialDown
	lds wa, 1
	jrl AcGridBox_EnableDials
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollDown_Alt
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0001A
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollDown_Alt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C0001A
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	calr SetDialDown
	lds wa, 1

AcGridBox_EnableDials:
	calr SetDialEnable
	jr AcGridBox_ReturnZero

AcGridBox_GetColText:
	ld xwa, (xsp + 16)
	ld xiz, 0x3E
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
	lds32 xhl, 0
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
	cp xbc, 0x1E0008D
	jr z, GridCheck_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jr lt, GridCheck_Return
	cp xwa, 0x6
	jr gt, GridCheck_Return
	add xwa, xwa
	add xwa, 0xEAA26C
	ld wa, (xwa)
	lda_24 xix, 0xf9ebfc
	jp_dri 8, 0x07, 0xF0, 0xE0

GridCheck_JumpEnd:
	jr	t, 0x3d

GridCheck_CellSelect:
	lda xbc, (xsp + 10)
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	pushm (xwa)
	pushm (xbc)
	pushw 0xEA
	pushw 0xA266
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 10)
	ld xbc, 0x1E0008C
	call SendEvent
	lds32 xhl, 0

GridCheck_Return:
	lda xsp, (xsp + 18)
	ret

PsEditBoxProc:
	st_dri3b L, 0xFD, 0xE4, 0xFD
	push xiz
	st_dri3l XDE, 0xFD, 0x18, 0x02
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x1C, 0x02
	cp xiz, 0x1E0003C
	jrl z, PsEditBox_CanScroll
	cp xiz, 0x1C00018
	jrl z, PsEditBox_ScrollDown
	cp xiz, 0x1C00017
	jrl z, PsEditBox_ScrollUp
	cp xiz, 0x1C0001B
	jrl z, PsEditBox_Release
	cp xiz, 0x1C00007
	jrl z, PsEditBox_OK
	cp xiz, 0x1E0003A
	jrl z, PsEditBox_GetText
	cp xiz, 0x1C0000F
	jrl z, PsEditBox_Confirm
	cp xiz, 0x1C0000E
	jrl z, PsEditBox_Select
	cp xiz, 0x1C0000D
	jrl z, PsEditBox_Paint
	cp xiz, 0x1C00001
	jrl z, PsEditBox_Init
	cp xiz, 0x1E0004D
	jrl nz, PsEditBox_Default
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 46)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp_sril_rm XBC, 0xFD, 0x18, 0x02
	jr z, PsEditBox_SetIndex_CheckDial
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x0218)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent

PsEditBox_SetIndex_CheckDial:
	ld xwa, (xiz + 46)
	cpw (xwa), 0x1
	jrl nz, PsEditBox_ReturnZero
	cpw (xiz + 44), 0x0
	jr z, PsEditBox_ReturnZero
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C00017
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C00018
	calr SetDialDown
	lds wa, 1
	jr PsEditBox_Init_EnableDials

PsEditBox_Init:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 46)
	cpw (xwa), 0x0
	jr z, PsEditBox_ReturnZero
	cpw (xiz + 44), 0x0
	jr z, PsEditBox_ReturnZero
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C00017
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C00018
	calr SetDialDown
	lds wa, 1

PsEditBox_Init_EnableDials:
	calr SetDialEnable

PsEditBox_ReturnZero:
	lds32 xhl, 0
	jrl PsEditBox_Return

PsEditBox_Paint:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld wa, (xwa + 42)
	calr DrawEditSw
	st_dri3b A, 0xFD, 0x0C, 0x02
	ld_sril XWA, (xsp + 0x021c)
	calr GetClientBox
	st_dri3b A, 0xFD, 0x0C, 0x01
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call ConvertStrings
	st_dri3b W, 0xFD, 0x0C, 0x01
	push xwa
	call Strlen
	ld xwa, (xsp + 12)
	ld iz, (xwa + 40)
	add iz, hl
	st_dri3b W, 0xFD, 0x10, 0x01
	push xwa
	call Strlen
	inc 8, xsp
	st_dri3b W, 0xFD, 0x0C, 0x02
	lda xde, (xwa + 4)
	ld bc, (xde)
	sub bc, (xwa)
	mul xbc, xhl
	extz xbc
	div xbc, xiz
	ld hl, (xwa)
	add hl, bc
	ld (xde), hl
	st_dri3b A, 0xFD, 0x14, 0x02
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x0C, 0x02
	st_dri3b B, 0xFD, 0x14, 0x02
	ld xhl, (xsp + 8)
	ld xbc, (xhl + 32)
	push xbc
	pushm (xhl + 36)
	ld xbc, (xsp + 10)
	pushm (xbc + 22)
	ld c, (xbc + 38)
	extz bc
	pushw bc
	ld xhl, (xhl + 28)
	ld xbc, xde
	ld xde, xhl
	call DrawStringAlignment
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PsEditBox_Dispatch

PsEditBox_Select:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	cpw (xhl + 42), 0xFF
	jrl z, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0004E
	jrl PsEditBox_Dispatch

PsEditBox_Confirm:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld (xsp + 8), xhl
	st_dri3b A, 0xFD, 0x0C, 0x02
	ld_sril XWA, (xsp + 0x021c)
	calr GetClientBox
	st_dri3b A, 0xFD, 0x0C, 0x01
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call ConvertStrings
	st_dri3b W, 0xFD, 0x0C, 0x01
	push xwa
	call Strlen
	inc 4, xsp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 40)
	ld iy, bc
	add iy, hl
	st_dri3b W, 0xFD, 0x0C, 0x02
	lda xhl, (xwa + 4)
	ld de, (xhl)
	ld ix, de
	sub ix, (xwa)
	mul xbc, xix
	extz xbc
	div xbc, xiy
	sub de, bc
	ld (xwa), de
	decm 6, (xhl)
	st_dri3b A, 0xFD, 0x14, 0x02
	calr GetBoxCenter
	lda xde, (xsp + 12)
	ld_sril XWA, (xsp + 0x0218)
	or xwa, xwa
	jr nz, PsEditBox_Confirm_CopyText
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0003A
	call SendEvent
	cp (xsp + 12), 0x0
	jr nz, PsEditBox_Confirm_Render
	jrl PsEditBox_ReturnZero

PsEditBox_Confirm_CopyText:
	ld_sril XWA, (xsp + 0x0218)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsEditBox_Confirm_Render:
	ld xiy, (xsp + 8)
	ld xbc, (xiy + 32)
	st_dri3b W, 0xFD, 0x0C, 0x02
	st_dri3b C, 0xFD, 0x14, 0x02
	lda xde, (xsp + 12)
	push xbc
	pushm (xiy + 36)
	pushm (xiy + 22)
	ld c, (xiy + 38)
	extz bc
	pushw bc
	lds ix, 0
	ld xbc, (xiy + 46)
	cpw (xbc), 0x0
	jr z, PsEditBox_Confirm_SetFocus
	cpw (xiy + 44), 0x0
	jr z, PsEditBox_Confirm_SetFocus
	lds ix, 1

PsEditBox_Confirm_SetFocus:
	pushw ix
	ld xbc, xhl
	call DrawStringReverse
	jrl PsEditBox_ReturnZero

PsEditBox_GetText:
	ld_sril XWA, (xsp + 0x0218)
	ld (xwa), 0x0
	jrl PsEditBox_ReturnZero

PsEditBox_OK:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 42)
	extz xwa
	cp_sril_rm XWA, 0xFD, 0x18, 0x02
	jr nz, PsEditBox_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xFFFF
	jr z, PsEditBox_OK_Forward
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0004D
	lds32 xde, 1
	jr PsEditBox_Dispatch

PsEditBox_OK_Forward:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	jrl PsEditBox_DefaultTail

PsEditBox_Release:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp_sril_rm XWA, 0xFD, 0x18, 0x02
	jrl nz, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	cpw (xwa), 0x0
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0004D
	lds32 xde, 0

PsEditBox_Dispatch:
	call SendEvent
	jrl PsEditBox_ReturnZero

PsEditBox_ScrollUp:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C00019
	ld_sril XDE, (xsp + 0x0218)
	jr PsEditBox_SetAutoInc

PsEditBox_ScrollDown:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1C0001A
	ld_sril XDE, (xsp + 0x0218)

PsEditBox_SetAutoInc:
	calr SetAutoInc
	jrl PsEditBox_ReturnZero

PsEditBox_CanScroll:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp_sril_rm XWA, 0xFD, 0x18, 0x02
	jrl nz, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	cpw (xwa), 0x1
	jrl nz, PsEditBox_ReturnZero
	lds32 xhl, 1
	jr PsEditBox_Return

PsEditBox_Default:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)

PsEditBox_DefaultTail:
	calr VwBoxProc

PsEditBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x1C, 0x02
	ret

PsNumEditBoxProc:
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 34), xde
	ld (xsp + 38), xbc
	ld (xsp + 42), xwa
	ld xwa, (xsp + 38)
	cp xwa, 0x1C0000F
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
	pushw 0xEA
	pushw 0xA27A
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	pushm (xiz + 50)
	pushw 0xEA
	pushw 0xA27C
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xwa, (xsp + 32)
	push xwa
	lda xwa, (xsp + 46)
	push xwa
	call Strcat
	lda xsp, (xsp + 26)
	pushw 0xEA
	pushw 0xA280
	lda xwa, (xsp + 28)
	push xwa
	call Strcat
	ld xwa, (xsp + 42)
	push xwa
	lda xwa, (xsp + 36)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 20)
	lda xde, (xsp + 4)
	ld xwa, (xsp + 42)
	ld xbc, (xsp + 38)
	calr PsEditBoxProc
	lds32 xhl, 0

PsNumEditBox_Return:
	pop xiz
	lda xsp, (xsp + 42)
	ret

PsTblEditBoxProc:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x04, 0x01
	st_dri3l XBC, 0xFD, 0x08, 0x01
	ld xiz, xwa
	ld_sril XWA, (xsp + 0x0108)
	cp xwa, 0x1C0000F
	jr z, PsTblEditBox_Confirm
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0108)
	ld_sril XDE, (xsp + 0x0104)
	calr PsEditBoxProc
	jr PsTblEditBox_Return

PsTblEditBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld (xde), xwa
	ld xwa, (xhl + 50)
	ld xbc, 0x1E0004C
	call ApFuncCall
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0108)
	calr PsEditBoxProc
	lds32 xhl, 0

PsTblEditBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret

PasTableCheck:
	cp xbc, 0x1E0004C
	jr nz, PasTableCheck_Return
	ld xwa, (xde)
	sll xwa, 2
	ld xbc, 0xEAA282
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PasTableCheck_Return:
	lds32 xhl, 0
	ret

AcOnOffBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1C00018
	jrl z, AcOnOff_ScrollDown
	cp xbc, 0x1C00017
	jrl z, AcOnOff_ScrollUp
	cp xbc, 0x1E0006B
	jr z, AcOnOff_GetValue
	cp xbc, 0x1E0003B
	jr z, AcOnOff_SetValue
	cp xbc, 0x1E0003A
	jr z, AcOnOff_GetText
	cp xbc, 0x1C0000D
	jrl nz, AcOnOff_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcOnOff_Dispatch

AcOnOff_GetText:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld wa, (xwa)
	extz xwa
	sll xwa, 2
	ld xbc, 0xEAA29A
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
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
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 1
	jr AcOnOff_Dispatch

AcOnOff_ScrollDown:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, 0x1E0003C
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 0

AcOnOff_Dispatch:
	call SendEvent

AcOnOff_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1C00018
	jrl z, AcNumEdit_ScrollDown
	cp xbc, 0x1C0001A
	jrl z, AcNumEdit_AutoIncDown
	cp xbc, 0x1C00017
	jrl z, AcNumEdit_ScrollUp
	cp xbc, 0x1C00019
	jrl z, AcNumEdit_AutoIncUp
	cp xbc, 0x1E0006B
	jrl z, AcNumEdit_GetValue
	cp xbc, 0x1E0003D
	jrl z, AcNumEdit_AddDelta
	cp xbc, 0x1E0003B
	jrl z, AcNumEdit_SetValue
	cp xbc, 0x1E0003A
	jr z, AcNumEdit_GetText
	cp xbc, 0x1C0000D
	jrl nz, AcNumEdit_Default
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcNumEdit_Dispatch

AcNumEdit_GetText:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	pushw 0xEA
	pushw 0xA2AA
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	ld xwa, (xsp + 12)
	pushm (xwa + 54)
	pushw 0xEA
	pushw 0xA2AC
	lda xwa, (xsp + 22)
	push xwa
	call Audio_SendCommand
	lda xwa, (xsp + 26)
	push xwa
	lda xwa, (xsp + 40)
	push xwa
	call Strcat
	lda xsp, (xsp + 26)
	pushw 0xEA
	pushw 0xA2B0
	lda xwa, (xsp + 22)
	push xwa
	call Strcat
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 50)
	pushm (xwa)
	lda xwa, (xsp + 28)
	push xwa
	ld xwa, (xsp + 42)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 18)
	jrl AcNumEdit_ReturnZero

AcNumEdit_SetValue:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xbc, (xhl + 50)
	ld xwa, (xsp + 28)
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000F
	lds32 xde, 0
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
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
	ld xbc, 0x1E0003C
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jrl z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003D
	jrl AcNumEdit_Dispatch

AcNumEdit_ScrollUp:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003D
	jr AcNumEdit_Dispatch

AcNumEdit_AutoIncDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003D
	jr AcNumEdit_Dispatch

AcNumEdit_ScrollDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1E0003D

AcNumEdit_Dispatch:
	call SendEvent

AcNumEdit_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1C00031
	jrl z, AcLswEdit_ResetBtn
	cp xbc, 0x1C00018
	jrl z, AcLswEdit_ScrollDown
	cp xbc, 0x1C0001A
	jrl z, AcLswEdit_AutoIncDown
	cp xbc, 0x1C00017
	jrl z, AcLswEdit_ScrollUp
	cp xbc, 0x1C00019
	jrl z, AcLswEdit_AutoIncUp
	cp xbc, 0x1C0001C
	jrl z, AcLswEdit_Match
	cp xbc, 0x1C0000C
	jrl z, AcLswEdit_ShowHide
	cp xbc, 0x1C0000B
	jrl z, AcLswEdit_ShowHide
	cp xbc, 0x1C00002
	jrl z, AcLswEdit_Close
	cp xbc, 0x1C00001
	jrl z, AcLswEdit_Init
	cp xbc, 0x1E0003D
	jrl z, AcLswEdit_AddDelta
	cp xbc, 0x1E0003B
	jr z, AcLswEdit_SetValue
	cp xbc, 0x1E0003A
	jrl nz, AcLswEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00040
	lds32 xde, 0
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
	ld xbc, 0x1E00042
	call ApFuncCall
	jrl AcLswEdit_ReturnZero

AcLswEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00040
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00041
	lds32 xde, 0
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
	ld xbc, 0x1E00040
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00041
	lds32 xde, 0
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
	ld xbc, 0x1E00040
	lds32 xde, 0
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
	ld xbc, 0x1E00040
	lds32 xde, 0
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
	ld xbc, 0x1E00083
	call ApFuncCall
	ld xwa, (xsp + 26)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcLswEdit_Dispatch

AcLswEdit_AutoIncUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003D
	jrl AcLswEdit_Dispatch

AcLswEdit_ScrollUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003D
	jrl AcLswEdit_Dispatch

AcLswEdit_AutoIncDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003D
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
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003D
	ld xde, xhl
	jr AcLswEdit_Dispatch

AcLswEdit_ResetBtn:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E000B8
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E000B9
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003B

AcLswEdit_Dispatch:
	call SendEvent

AcLswEdit_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1E00083
	jr z, LswEditCheck_NotHandled
	cp xbc, 0x1E0003F
	jr z, LswEditCheck_StepOne
	cp xbc, 0x1E0003E
	jr z, LswEditCheck_StepFour
	cp xbc, 0x1E00041
	jr z, LswEditCheck_StepOne
	cp xbc, 0x1E00040
	jr z, LswEditCheck_GetAddr
	cp xbc, 0x1E00042
	jr nz, LswEditCheck_NotHandled
	pushm (xde + 4)
	pushw 0xEA
	pushw 0xA2B2
	ld xwa, (xde + 8)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jr LswEditCheck_Return

LswEditCheck_GetAddr:
	ld xhl, 0x1F47
	jr LswEditCheck_Return

LswEditCheck_StepOne:
	lds32 xhl, 1
	jr LswEditCheck_Return

LswEditCheck_StepFour:
	lds32 xhl, 4
	jr LswEditCheck_Return

LswEditCheck_NotHandled:
	lds32 xhl, 0

LswEditCheck_Return:
	pop xiz
	ret

MainLswPut:
	dec 8, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld wa, (xsp + 6)
	ld (xiz + 4), wa
	ld wa, (xsp + 4)
	ld (xiz + 6), wa
	lds32 xwa, 0
	ld (xiz + 8), xwa
	ld xwa, 0x1400002
	ld xbc, 0x1E00057
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, xiz
	call MainFuncCall
	lds hl, 0
	pop xiz
	inc 8, xsp
	ret

MainLswPartPut:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), de
	ld (xsp + 8), bc
	ld iz, wa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 8)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 0
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ld bc, (xsp + 6)
	ld (xwa + 4), bc
	ld bc, (xsp + 14)
	ld (xwa + 6), bc
	lds32 xbc, 0
	ld (xwa + 8), xbc
	ld xwa, 0x1400002
	ld xbc, 0x1E0005A
	ld xde, (xsp + 2)
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, (xsp + 2)
	call MainFuncCall
	lds hl, 0
	popw iz
	inc 8, xsp
	retd 0x2

MainLswAdd:
	dec 8, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld wa, (xsp + 6)
	ld (xiz + 4), wa
	ld wa, (xsp + 4)
	ld (xiz + 6), wa
	lds32 xwa, 0
	ld (xiz + 8), xwa
	ld xwa, 0x1400002
	ld xbc, 0x1E00058
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, xiz
	call MainFuncCall
	lds hl, 0
	pop xiz
	inc 8, xsp
	ret

MainLswPartAdd:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), de
	ld (xsp + 8), bc
	ld iz, wa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 8)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 0
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ld bc, (xsp + 6)
	ld (xwa + 4), bc
	ld bc, (xsp + 14)
	ld (xwa + 6), bc
	lds32 xbc, 0
	ld (xwa + 8), xbc
	ld xwa, 0x1400002
	ld xbc, 0x1E0005B
	ld xde, (xsp + 2)
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, (xsp + 2)
	call MainFuncCall
	lds hl, 0
	popw iz
	inc 8, xsp
	retd 0x2

MainLswGet:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld (xiz), xwa
	ldw (xiz + 4), 0x0
	ldw (xiz + 6), 0x0
	lds32 xwa, 0
	ld (xiz + 8), xwa
	ld xwa, 0x1400002
	ld xbc, 0x1E00059
	ld xde, xiz
	call FuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, xiz
	call FuncCall
	lds hl, 0
	pop xiz
	inc 4, xsp
	ret

MainLswPartGet:
	dec 6, xsp
	pushw iz
	ld (xsp + 6), bc
	ld iz, wa
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld bc, (xsp + 6)
	extz xbc
	ld de, iz
	extz xde
	sll xde, 0
	add xde, xbc
	ld xwa, (xsp + 2)
	ld (xwa), xde
	ldw (xwa + 4), 0x0
	ldw (xwa + 6), 0x0
	lds32 xbc, 0
	ld (xwa + 8), xbc
	ld xwa, 0x1400002
	ld xbc, 0x1E0005C
	ld xde, (xsp + 2)
	call FuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, (xsp + 2)
	call FuncCall
	lds hl, 0
	popw iz
	inc 6, xsp
	ret

SetLswFilter:
	add xwa, xbc
	st32_24 0x0276c6, xwa
	ret

ResetLswFilter:
	add xwa, xbc
	st32_24 0x0276c6, xwa
	ret

AcRamEditBoxProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld (xsp + 34), xwa
	cp xbc, 0x1C00018
	jrl z, AcRamEdit_ScrollDown
	cp xbc, 0x1C0001A
	jrl z, AcRamEdit_AutoIncDown
	cp xbc, 0x1C00017
	jrl z, AcRamEdit_ScrollUp
	cp xbc, 0x1C00019
	jrl z, AcRamEdit_AutoIncUp
	cp xbc, 0x1C0001D
	jrl z, AcRamEdit_Assign
	cp xbc, 0x1C0000C
	jrl z, AcRamEdit_ShowHide
	cp xbc, 0x1C0000B
	jrl z, AcRamEdit_ShowHide
	cp xbc, 0x1E0003D
	jrl z, AcRamEdit_AddDelta
	cp xbc, 0x1E0003B
	jr z, AcRamEdit_SetValue
	cp xbc, 0x1E0003A
	jrl nz, AcRamEdit_Default
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 54)
	ld xwa, (xwa)
	ld (xde + 14), xwa
	ld xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00047
	call ApFuncCall
	jrl AcRamEdit_ReturnZero

AcRamEdit_SetValue:
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00044
	lds32 xde, 0
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00044
	lds32 xde, 0
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00046
	lds32 xde, 0
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
	ld xbc, 0x1E00045
	lds32 xde, 0
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
	ld xbc, 0x1E00082
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcRamEdit_Dispatch

AcRamEdit_AutoIncUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	jrl AcRamEdit_Dispatch

AcRamEdit_ScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	jrl AcRamEdit_Dispatch

AcRamEdit_AutoIncDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
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
	ld xbc, 0x1E0003C
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	ld xde, xhl

AcRamEdit_Dispatch:
	call SendEvent

AcRamEdit_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1E00082
	jr z, RamEditCheck_NotHandled
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, RamEditCheck_NotHandled
	cp xwa, 0x9
	jr gt, RamEditCheck_NotHandled
	add xwa, xwa
	add xwa, 0xEAA2BA
	ld wa, (xwa)
	lda_24 xix, 0xf9fe0d
	jp_dri 8, 0x07, 0xF0, 0xE0

RamEditCheck_JumpStart:
	ld	xwa, (xde+14)
	push	xwa
	pushw	234
	pushw	41654
	ld	xwa, (xde+18)
	push	xwa
	call	16714354
	lda	xsp, (xsp+12)
	ld	xhl, xiz
	jr	31
	lds32	xhl, 4
	jr	27
	lds32	xhl, 1
	jr	23
	ld	xhl, 16
	jr	16
	ld	xhl, 4294967267
	jr	9
	lda_24	xhl, 161482
	jr	2

RamEditCheck_NotHandled:
	lds32 xhl, 0
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
	ldw bc, 0xB
	ldirw
	ld xwa, 0x1400008
	ld xbc, 0x1E00069
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
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
	ldw bc, 0xB
	ldirw
	ld xwa, 0x1400008
	ld xbc, 0x1E0006A
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
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
	lds32 xwa, 0
	ld (xiz + 6), xwa
	ld (xiz + 10), xwa
	ld (xiz + 14), xwa
	ld (xiz + 18), xwa
	ld xwa, 0x1400008
	ld xbc, 0x1E00068
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
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
	cp xbc, 0x1C00018
	jrl z, AcBitEdit_ScrollDown
	cp xbc, 0x1C00017
	jrl z, AcBitEdit_ScrollUp
	cp xbc, 0x1C00024
	jrl z, AcBitEdit_Assign
	cp xbc, 0x1C0000C
	jrl z, AcBitEdit_ShowHide
	cp xbc, 0x1C0000B
	jrl z, AcBitEdit_ShowHide
	cp xbc, 0x1E0003D
	jr z, AcBitEdit_SetValue
	cp xbc, 0x1E0003B
	jr z, AcBitEdit_SetValue
	cp xbc, 0x1E0003A
	jrl nz, AcBitEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00063
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 54)
	ld wa, (xwa)
	ld (xde + 8), wa
	ld xwa, (xsp + 22)
	ld (xde + 10), xwa
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00062
	call ApFuncCall
	jrl AcBitEdit_ReturnZero

AcBitEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00063
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00064
	lds32 xde, 0
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
	ld xbc, 0x1E00063
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00064
	lds32 xde, 0
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
	ld xbc, 0x1E00063
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 22)
	ld xwa, (xwa)
	cp xwa, xhl
	jrl nz, AcBitEdit_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00064
	lds32 xde, 0
	call ApFuncCall
	ld xde, (xsp + 22)
	cp (xde + 4), xhl
	jrl nz, AcBitEdit_ReturnZero
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 54)
	ld wa, (xde + 8)
	ld (xbc), wa
	ld xwa, (xsp + 26)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcBitEdit_Dispatch

AcBitEdit_ScrollUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00065
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollUp_SetOne
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003B
	lds32 xde, 0
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollUp_SetOne:
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003B
	lds32 xde, 1
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003C
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00065
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollDown_SetZero
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003B
	lds32 xde, 1
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollDown_SetZero:
	ld xwa, (xsp + 26)
	ld xbc, 0x1E0003B
	lds32 xde, 0

AcBitEdit_Dispatch:
	call SendEvent

AcBitEdit_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1E00065
	jr z, BitEditCheck_NotHandled
	cp xbc, 0x1E00064
	jr z, BitEditCheck_GetMask
	cp xbc, 0x1E00063
	jr z, BitEditCheck_GetAddr
	cp xbc, 0x1E00062
	jr nz, BitEditCheck_NotHandled
	ld wa, (xde + 8)
	and wa, 0x1
	sla wa, 2
	lda_24 xbc, 0xeaa2ce
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr BitEditCheck_Return

BitEditCheck_GetAddr:
	lda_24 xhl, 0x0276ce
	jr BitEditCheck_Return

BitEditCheck_GetMask:
	ld xhl, 0x8000
	jr BitEditCheck_Return

BitEditCheck_NotHandled:
	lds32 xhl, 0

BitEditCheck_Return:
	pop xiz
	ret

MainBitPut:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	pushw 0xE
	call Malloc
	ld (xsp + 6), xhl
	pushw 0xE
	push xiz
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld xwa, 0x1400007
	ld xbc, 0x1E00067
	ld xde, (xsp + 4)
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
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
	pushw 0xE
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld (xiz), xwa
	ld xwa, (xsp + 4)
	ld (xiz + 4), xwa
	ldw (xiz + 8), 0x0
	lds32 xwa, 0
	ld (xiz + 10), xwa
	ld xwa, 0x1400007
	ld xbc, 0x1E00066
	ld xde, xiz
	call MainFuncCall
	ld xwa, 0x1400003
	ld xbc, 0x1E00023
	ld xde, xiz
	call MainFuncCall
	pop xiz
	inc 8, xsp
	ret

PsMenuBoxProc:
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x01
	ld xiz, xwa
	cp xbc, 0x1E00053
	jrl z, PsMenuBox_HitTest
	cp xbc, 0x1C0000F
	jr z, PsMenuBox_Confirm
	cp xbc, 0x1C0000D
	jr z, PsMenuBox_Paint
	cp xbc, 0x1E0003A
	jr z, PsMenuBox_GetText
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0114)
	calr VwBoxProc
	jrl PsMenuBox_Return

PsMenuBox_GetText:
	ld_sril XWA, (xsp + 0x0114)
	ld (xwa), 0x0

PsMenuBox_ReturnZero:
	lds32 xhl, 0
	jrl PsMenuBox_Return

PsMenuBox_Paint:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0114)
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
	st_dri3b A, 0xFD, 0x0C, 0x01
	ld xwa, xiz
	calr GetClientBox
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b A, 0xFD, 0x08, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 8)
	ld_sril XWA, (xsp + 0x0114)
	or xwa, xwa
	jr nz, PsMenuBox_Confirm_CopyText
	ld xwa, xiz
	ld xbc, 0x1E0003A
	call SendEvent
	cp (xsp + 8), 0x0
	jr nz, PsMenuBox_Confirm_Render
	jr PsMenuBox_ReturnZero

PsMenuBox_Confirm_CopyText:
	ld_sril XWA, (xsp + 0x0114)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsMenuBox_Confirm_Render:
	st_dri3b C, 0xFD, 0x0C, 0x01
	st_dri3b A, 0xFD, 0x08, 0x01
	lda xde, (xsp + 8)
	ld xix, (xsp + 4)
	ld xwa, (xix + 28)
	push xwa
	pushm (xix + 32)
	ld xwa, xix
	pushm (xwa + 22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringAlignment
	jrl PsMenuBox_ReturnZero

PsMenuBox_HitTest:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jrl z, PsMenuBox_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld_sril XDE, (xsp + 0x0114)
	call SendEvent
	ld wa, (xiz + 36)
	extz xwa
	cp xwa, xhl
	jrl nz, PsMenuBox_ReturnZero
	lds32 xhl, 1

PsMenuBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

AcTitleMenuProc:
	st_dri3b L, 0xFD, 0xCC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x30, 0x01
	st_dri3l XBC, 0xFD, 0x34, 0x01
	ld xiz, xwa
	ld_sril XWA, (xsp + 0x0134)
	cp xwa, 0x1C00007
	jrl z, AcTitleMenu_OK
	cp xwa, 0x1C0000F
	jr z, AcTitleMenu_Confirm
	cp xwa, 0x1C0000D
	jr z, AcTitleMenu_Paint
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0134)
	ld_sril XDE, (xsp + 0x0130)
	jrl AcTitleMenu_DefaultTail

AcTitleMenu_Paint:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0134)
	ld_sril XDE, (xsp + 0x0130)
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcTitleMenu_OK_Dispatch

AcTitleMenu_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	st_dri3b A, 0xFD, 0x1C, 0x01
	ld xwa, xiz
	calr GetClientBox
	st_dri3b E, 0xFD, 0x1C, 0x01
	st_dri3b D, 0xFD, 0x14, 0x01
	lds bc, 4
	ldirw
	st_dri3b A, 0xFD, 0x28, 0x01
	ld xwa, (xsp + 8)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 8)
	lda xde, (xwa + 50)	; ICON ID
	st_dri3b A, 0xFD, 0x2C, 0x01
	ld xwa, (xde)	; <--- here we get the ID of the selected menu item's icon
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIcon

	cp_sriw_im 0xFD, 0x28, 0x01, 0x00, 0x00
	jr nz, AcTitleMenu_Confirm_NoIcon

	ldw wa, 0x20
	jr AcTitleMenu_Confirm_SetLeft

AcTitleMenu_Confirm_NoIcon:
	lds wa, 4

AcTitleMenu_Confirm_SetLeft:
	ld_sriw HL, (xsp + 0x011c)
	add hl, wa
	ld (xbc), hl
	st_dri3w HL, 0xFD, 0x14, 0x01
	st_dri3b A, 0xFD, 0x18, 0x01
	ld xwa, (xde)	; also ICON ID here
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIconRight

	cp_sriw_im 0xFD, 0x28, 0x01, 0x00, 0x00
	jr z, AcTitleMenu_Confirm_NoIconRight

	ldw wa, 0x1C
	jr AcTitleMenu_Confirm_SetRight

AcTitleMenu_Confirm_NoIconRight:
	lds wa, 4

AcTitleMenu_Confirm_SetRight:
	ld_sriw DE, (xsp + 0x0120)
	sub de, wa
	ld (xbc), de
	lda xbc, (xsp + 12)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 42)
	call ConvertStrings
	lda xwa, (xsp + 12)
	st_dri3b A, 0xFD, 0x14, 0x01
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
	st_dri3b A, 0xFD, 0x28, 0x01
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
	ld_sriw WA, (xsp + 0x0118)
	sub wa, hl
	dec 5, wa
	st_dri3w WA, 0xFD, 0x2C, 0x01

AcTitleMenu_Confirm_SingleLine:
	st_dri3b W, 0xFD, 0x1C, 0x01
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
	st_dri3b A, 0xFD, 0x2C, 0x01
	ld (xbc + 2), wa
	st_dri3b W, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xF7
	jrl AcTitleMenu_Confirm_RenderTop

AcTitleMenu_Confirm_MultiLine:
	ld hl, (xsp + 6)
	dec 1, hl
	lda xde, (xsp + 12)
	stib_dri 0x07, 0xE8, 0xEC, 0x00
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
	st_dri3b W, 0x07, 0xE0, 0xE8

AcTitleMenu_Confirm_MultiAdjust:
	call CalcTotalWidth
	ld_sriw WA, (xsp + 0x0118)
	sub wa, hl
	dec 5, wa
	st_dri3w WA, 0xFD, 0x2C, 0x01

AcTitleMenu_Confirm_RenderBottom:
	st_dri3b W, 0xFD, 0x1C, 0x01
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
	st_dri3b A, 0xFD, 0x2C, 0x01
	ld (xbc + 2), wa
	st_dri3b W, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xF7
	call DrawString
	st_dri3b W, 0xFD, 0x1C, 0x01
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
	st_dri3b A, 0xFD, 0x2C, 0x01
	ld (xbc + 2), wa
	st_dri3b W, 0xFD, 0x14, 0x01
	lda xhl, (xsp + 12)
	ld de, (xsp + 6)
	exts xde
	add xde, xhl
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xF7

AcTitleMenu_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)	; ICON ID
	or xwa, xwa
	jrl z, AcTitleMenu_OK_Done

	st_dri3b A, 0xFD, 0x24, 0x01
	st_dri3b W, 0xFD, 0x1C, 0x01
	cp_sriw_im 0xFD, 0x28, 0x01, 0x00, 0x00
	jr z, AcTitleMenu_Confirm_IconNoOrient
	ld wa, (xwa + 4)
	sub wa, 0x1A
	ld (xbc), wa
	jr AcTitleMenu_Confirm_DrawIcon

AcTitleMenu_Confirm_IconNoOrient:
	ld wa, (xwa)
	inc 2, wa
	ld (xbc), wa

AcTitleMenu_Confirm_DrawIcon:
	st_dri3b W, 0xFD, 0x1C, 0x01
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xB
	st_dri3b C, 0xFD, 0x24, 0x01
	lda xde, (xhl + 2)
	ld (xde), bc
	st_dri3b W, 0xFD, 0x0C, 0x01
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
	ldw bc, 0xC4
	ldw de, 0xF0
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x24, 0x01
	ld xbc, (xsp + 8)
	ld xbc, (xbc + 50)	; <-- ICON ID
	call DrawIcons
	jrl AcTitleMenu_OK_Done

AcTitleMenu_OK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld_sril XDE, (xsp + 0x0130)
	call SendEvent
	cps hl, 0
	jrl z, AcTitleMenu_OK_Default
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	cp xwa, 0xFFFFFFFF
	jrl z, AcTitleMenu_OK_Default
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x160001D
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckMode
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckMode:
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600040
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckScreen
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckScreen:
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600041
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckWindow
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckWindow:
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600042
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_Done
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, 0x1C00001
	lds32 xde, 0

AcTitleMenu_OK_Dispatch:
	call SendEvent

AcTitleMenu_OK_Done:
	lds32 xhl, 0
	jr AcTitleMenu_Return

AcTitleMenu_OK_Default:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0134)
	ld_sril XDE, (xsp + 0x0130)

AcTitleMenu_DefaultTail:
	calr PsMenuBoxProc

AcTitleMenu_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x34, 0x01
	ret

VwMenuBoxProc:
	st_dri3b L, 0xFD, 0xD6, 0xFE
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000F
	jr z, VwMenuBox_Confirm
	cp xbc, 0x1C0000D
	jr z, VwMenuBox_Paint
	ld xwa, xiz
	calr PsMenuBoxProc
	jrl VwMenuBox_Return

VwMenuBox_Paint:
	ld xwa, xiz
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jrl VwMenuBox_ReturnZero

VwMenuBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 6), xhl
	st_dri3b A, 0xFD, 0x1A, 0x01
	ld xwa, xiz
	calr GetClientBox
	st_dri3b E, 0xFD, 0x1A, 0x01
	st_dri3b D, 0xFD, 0x12, 0x01
	lds bc, 4
	ldirw
	st_dri3b A, 0xFD, 0x26, 0x01
	ld xwa, (xsp + 6)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	lda xde, (xwa + 46)
	st_dri3b A, 0xFD, 0x2A, 0x01
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIcon
	cp_sriw_im 0xFD, 0x26, 0x01, 0x00, 0x00
	jr nz, VwMenuBox_Confirm_NoIcon
	ldw wa, 0x20
	jr VwMenuBox_Confirm_SetLeft

VwMenuBox_Confirm_NoIcon:
	lds wa, 4

VwMenuBox_Confirm_SetLeft:
	ld_sriw HL, (xsp + 0x011a)
	add hl, wa
	ld (xbc), hl
	st_dri3w HL, 0xFD, 0x12, 0x01
	st_dri3b A, 0xFD, 0x16, 0x01
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIconRight
	cp_sriw_im 0xFD, 0x26, 0x01, 0x00, 0x00
	jr z, VwMenuBox_Confirm_NoIconRight
	ldw wa, 0x1C
	jr VwMenuBox_Confirm_SetRight

VwMenuBox_Confirm_NoIconRight:
	lds wa, 4

VwMenuBox_Confirm_SetRight:
	ld_sriw DE, (xsp + 0x011e)
	sub de, wa
	ld (xbc), de
	lda xbc, (xsp + 10)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 42)
	call ConvertStrings
	lda xwa, (xsp + 10)
	st_dri3b A, 0xFD, 0x12, 0x01
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
	st_dri3b A, 0xFD, 0x26, 0x01
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
	ld_sriw WA, (xsp + 0x0116)
	sub wa, hl
	dec 5, wa
	st_dri3w WA, 0xFD, 0x2A, 0x01

VwMenuBox_Confirm_SingleLine:
	st_dri3b W, 0xFD, 0x1A, 0x01
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
	st_dri3b A, 0xFD, 0x2A, 0x01
	ld (xbc + 2), wa
	st_dri3b W, 0xFD, 0x12, 0x01
	lda xde, (xsp + 10)
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xF7
	jrl VwMenuBox_Confirm_RenderTop

VwMenuBox_Confirm_MultiLine:
	ld hl, iz
	dec 1, hl
	lda xde, (xsp + 10)
	stib_dri 0x07, 0xE8, 0xEC, 0x00
	ld xwa, (xwa)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_RenderBottom
	cpw (xbc), 0x0
	jr z, VwMenuBox_Confirm_RenderBottom
	st_dri3b W, 0x07, 0xE8, 0xF8
	push xwa
	call Strlen
	ldfr_werp HL, 0xFA
	lda xwa, (xsp + 14)
	push xwa
	call Strlen
	inc 8, xsp
	ld xwa, (xsp + 6)
	ld xbc, (xwa + 28)
	lda xwa, (xsp + 10)
	cp_werp HL, 0xFA
	jr ugt, VwMenuBox_Confirm_MultiAdjust
	st_dri3b W, 0x07, 0xE0, 0xF8

VwMenuBox_Confirm_MultiAdjust:
	call CalcTotalWidth
	ld_sriw WA, (xsp + 0x0116)
	sub wa, hl
	dec 5, wa
	st_dri3w WA, 0xFD, 0x2A, 0x01

VwMenuBox_Confirm_RenderBottom:
	st_dri3b W, 0xFD, 0x1A, 0x01
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
	st_dri3b A, 0xFD, 0x2A, 0x01
	ld (xbc + 2), wa
	st_dri3b W, 0xFD, 0x12, 0x01
	lda xde, (xsp + 10)
	st_dri3b B, 0x07, 0xE8, 0xF8
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xF7

VwMenuBox_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 46)
	or xwa, xwa
	jrl z, VwMenuBox_ReturnZero
	st_dri3b A, 0xFD, 0x22, 0x01
	st_dri3b W, 0xFD, 0x1A, 0x01
	cp_sriw_im 0xFD, 0x26, 0x01, 0x00, 0x00
	jr z, VwMenuBox_Confirm_IconNoOrient
	ld wa, (xwa + 4)
	sub wa, 0x1A
	ld (xbc), wa
	jr VwMenuBox_Confirm_DrawIcon

VwMenuBox_Confirm_IconNoOrient:
	ld wa, (xwa)
	inc 2, wa
	ld (xbc), wa

VwMenuBox_Confirm_DrawIcon:
	st_dri3b W, 0xFD, 0x1A, 0x01
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xB
	st_dri3b C, 0xFD, 0x22, 0x01
	lda xde, (xhl + 2)
	ld (xde), bc
	st_dri3b W, 0xFD, 0x0A, 0x01
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
	ldw bc, 0xC4
	ldw de, 0xF0
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x22, 0x01
	ld xbc, (xsp + 6)
	ld xbc, (xbc + 46)
	call DrawIcons

VwMenuBox_ReturnZero:
	lds32 xhl, 0

VwMenuBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x2A, 0x01
	ret

PsEditSwBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xwa
	cp xbc, 0x1E0009C
	jrl z, PsEditSwBox_Repaint
	cp xbc, 0x1E00053
	jr z, PsEditSwBox_HitTest
	cp xbc, 0x1C0000F
	jr z, PsEditSwBox_Confirm
	cp xbc, 0x1C0000D
	jr z, PsEditSwBox_Paint
	cp xbc, 0x1E0003A
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
	cpw (xsp + 18), 0xEF
	jrl z, PsEditSwBox_ReturnZero
	ld wa, (xiz + 36)
	calr DrawEditSw
	jrl PsEditSwBox_ReturnZero

PsEditSwBox_Confirm:
	ld xwa, (xsp + 20)
	ld c, a
	extz bc
	ld xwa, xiz
	calr LABEL_FA0BDC
	jrl PsEditSwBox_ReturnZero

PsEditSwBox_HitTest:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jrl z, PsEditSwBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 20)
	call SendEvent
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	extz xwa
	cp xwa, xhl
	jr nz, PsEditSwBox_ReturnZero
	lds32 xhl, 1
	jr PsEditSwBox_Return

PsEditSwBox_Repaint:
	ld xwa, xiz
	ld xde, (xsp + 20)
	calr VwBoxProc
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, PsEditSwBox_Repaint_UpdateBounds
	ld xwa, xiz
	ld xbc, 0x1C0000C
	lds32 xde, 0
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
	cpw (xwa + 2), 0xEF
	jr z, PsEditSwBox_Repaint_Render
	lda xbc, (xsp + 8)
	cpw (xwa), 0x13F
	jr z, PsEditSwBox_Repaint_ClampRight
	ldw (xbc), 0x0
	jr PsEditSwBox_Repaint_Render

PsEditSwBox_Repaint_ClampRight:
	ldw (xbc + 4), 0x13F

PsEditSwBox_Repaint_Render:
	lda xwa, (xsp + 8)
	ldw bc, 0xF5
	call DrawBox

PsEditSwBox_ReturnZero:
	lds32 xhl, 0

PsEditSwBox_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

LABEL_FA0AF1:
	.byte 0xef, 0x6e, 0x3e, 0xbf, 0x08, 0x52, 0xe9, 0x8e
	.byte 0xbf, 0x04, 0x31, 0x1e, 0x34, 0x9e, 0xbf, 0x04
	.byte 0x30, 0x90, 0x3f, 0x00, 0x00, 0x6e, 0x29, 0xb8
	.byte 0x02, 0x31, 0x91, 0x20, 0xd8, 0xca, 0x09, 0x00
	.byte 0xbe, 0x02, 0x50, 0x91, 0x20, 0xd8, 0x60, 0xbe
	.byte 0x06, 0x50, 0x9f, 0x08, 0x20, 0x1e, 0xfa, 0x8c
	.byte 0x30, 0x08, 0x00, 0xdb, 0xd8, 0x66, 0x02, 0xd8
	.byte 0xa8, 0xb6, 0x50, 0xbe, 0x04, 0x02, 0x26, 0x00
	.byte 0xbf, 0x04, 0x30, 0x90, 0x3f, 0x3f, 0x01, 0x6e
	.byte 0x2e, 0xb8, 0x02, 0x31, 0x91, 0x20, 0xd8, 0xca
	.byte 0x09, 0x00, 0xbe, 0x02, 0x50, 0x91, 0x20, 0xd8
	.byte 0x60, 0xbe, 0x06, 0x50, 0xb6, 0x02, 0x19, 0x01
	.byte 0x9f, 0x08, 0x20, 0x1e, 0xd6, 0x8c, 0xbe, 0x04
	.byte 0x30, 0xdb, 0xd8, 0x66, 0x06, 0xb0, 0x02, 0x3f
	.byte 0x01, 0x68, 0x04, 0xb0, 0x02, 0x37, 0x01, 0xbf
	.byte 0x04, 0x31, 0x99, 0x02, 0x3f, 0xef, 0x00, 0x6e
	.byte 0x1b, 0xbe, 0x02, 0x02, 0xd8, 0x00, 0xbe, 0x06
	.byte 0x02, 0xee, 0x00, 0x91, 0x20, 0xd8, 0xca, 0x10
	.byte 0x00, 0xb6, 0x50, 0x91, 0x20, 0xd8, 0xc8, 0x0f
	.byte 0x00, 0xbe, 0x04, 0x50, 0x5e, 0xef, 0x66, 0x0e
	.byte 0xbf, 0xf4, 0x37, 0x2e, 0xbf, 0x0a, 0x62, 0xd9
	.byte 0x8e, 0xde, 0xf0, 0x67, 0x02, 0xd8, 0xbe, 0xbf
	.byte 0x06, 0x31, 0x1e, 0x8d, 0x9d, 0xbf, 0x02, 0x31
	.byte 0xde, 0x88, 0x1e, 0x85, 0x9d, 0xbf, 0x06, 0x31
	.byte 0x99, 0x02, 0x3f, 0xef, 0x00, 0x6e, 0x1f, 0xaf
	.byte 0x0a, 0x20, 0xb8, 0x02, 0x02, 0xd8, 0x00, 0xb8
	.long LABEL_EE0206
	ld	bc, (xbc)
	sub	bc, 16
	ld	(xwa), bc
	ld	bc, (xsp+2)
	add	bc, 15
	ld	(xwa+4), bc
	popw	iz
	lda	xsp, (xsp+12)
	ret

LABEL_FA0BDC:
	st_dri3b L, 0xFD, 0xD6, 0xFE
	push xiz
	lda_dri3 XHL, 0xFD, 0x28, 0x01
	st_dri3l XWA, 0xFD, 0x2A, 0x01
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld (xsp + 4), xhl
	st_dri3b A, 0xFD, 0x20, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	st_dri3b E, 0xFD, 0x20, 0x01
	st_dri3b D, 0xFD, 0x18, 0x01
	lds bc, 4
	ldirw
	st_dri3b C, 0xFD, 0x10, 0x01
	st_dri3b W, 0xFD, 0x20, 0x01
	ld bc, (xwa)
	ld (xhl), bc
	st_dri3b D, 0xFD, 0x0C, 0x01
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
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x10, 0x01
	st_dri3b A, 0xFD, 0x0C, 0x01
	cp_srib_im 0xFD, 0x28, 0x01, 0x0B
	jrl z, LABEL_FA0D80
	cp_srib_im 0xFD, 0x28, 0x01, 0x0E
	jrl z, LABEL_FA0CF7
	cp_srib_im 0xFD, 0x28, 0x01, 0x03
	jrl nz, ButtonState_DispatchDSP
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x9B
	ld (xbc + 1), 0x0
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	call DrawStringCentered
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ld_sriw BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x98
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	jrl LABEL_FA0E0E

LABEL_FA0CF7:
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x85
	ld (xbc + 1), 0x0
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	call DrawStringCentered
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ld_sriw BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x81
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	jrl LABEL_FA0E0E

LABEL_FA0D80:
	ld (xsp + 8), xwa
	ld xiz, xbc
	ld_sril XWA, (xsp + 0x012a)
	calr GetFrameColor
	ld de, hl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	call DrawLine
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	ld xde, xhl
	pushm (xde + 22)
	ld xde, 0xEAA2E2
	call DrawStringCentered
	st_dri3b W, 0xFD, 0x18, 0x01
	ld_sriw BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ld_sriw BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	st_dri3b A, 0xFD, 0x14, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x18, 0x01
	st_dri3b A, 0xFD, 0x14, 0x01
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	ld xde, xhl
	pushm (xde + 22)
	ld xde, 0xEAA2E6

LABEL_FA0E0E:
	call DrawStringCentered
	jrl LABEL_FA0EDD

; ButtonState event dispatch via DSP handler table
ButtonState_DispatchDSP:
	ld_srib A, (xsp + 0x0128)
	extz wa
	cps wa, 0
	jrl mi, LABEL_FA0EB5
	cp wa, 0x10
	jrl gt, LABEL_FA0EB5
	add wa, wa
	lda_24 xix, 0xeaa31a
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfa0e3e
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_FA0E3E:
	.byte 0xbf, 0x0c, 0x32
	ld	xwa, (xsp+298)
	.byte 0x41, 0x3a, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96
	.byte 0xfa, 0x68, 0x64, 0x40, 0xea, 0xa2, 0xea, 0x00
	.byte 0x68, 0x52, 0x40, 0xee, 0xa2, 0xea, 0x00, 0x68
	.byte 0x4b, 0x40, 0xf2, 0xa2, 0xea, 0x00, 0x68, 0x44
	.byte 0x40, 0xf6, 0xa2, 0xea, 0x00, 0x68, 0x3d, 0x40
	.long LABEL_EAA2FA
	.byte 0x68, 0x36, 0x40, 0xfe
	.byte 0xa2, 0xea, 0x00, 0x68, 0x2f, 0x40, 0x02, 0xa3
	.byte 0xea, 0x00, 0x68, 0x28, 0x40, 0x06, 0xa3, 0xea
	.byte 0x00, 0x68, 0x21, 0x40, 0x08, 0xa3, 0xea, 0x00
	.byte 0x68, 0x1a, 0x40, 0x0a, 0xa3, 0xea, 0x00, 0x68
	.byte 0x13, 0x40, 0x0e, 0xa3, 0xea, 0x00, 0x68, 0x0c
	.byte 0x40, 0x12, 0xa3, 0xea, 0x00, 0x68, 0x05, 0x40
	.long LABEL_EAA316
	.byte 0x38, 0xbf, 0x10, 0x30
	.byte 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60

LABEL_FA0EB5:
	st_dri3b W, 0xFD, 0x20, 0x01
	st_dri3b C, 0xFD, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xbc, (xix + 28)
	push xbc
	pushm (xix + 32)
	ld xbc, xix
	pushm (xbc + 22)
	ld c, (xbc + 34)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringAlignment

LABEL_FA0EDD:
	pop xiz
	st_dri3b L, 0xFD, 0x2A, 0x01
	ret

PsWideESBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	cp xbc, 0x1E00053
	jrl z, LABEL_FA0F77
	cp xbc, 0x1E00052
	jr z, LABEL_FA0F05
	ld xde, (xsp + 20)
	calr PsEditSwBoxProc
	jrl LABEL_FA0FB3

LABEL_FA0F05:
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 20)
	srl xwa, 0
	ldi_werp 0xE2, 0
	ldfr_werp WA, 0xFA
	ld xwa, (xsp + 20)
	ld iz, wa
	ldto_werp WA, 0xFA
	cp wa, iz
	jr c, LABEL_FA0F35
	ldto_werp HL, 0xFA
	ldto_werp WA, 0xFA
	ex16 wa, iz
	ldfr_werp WA, 0xFA

LABEL_FA0F35:
	lda xbc, (xsp + 16)
	ldto_werp WA, 0xFA
	calr GetEditSwPoint
	lda xbc, (xsp + 12)
	ld wa, iz
	calr GetEditSwPoint
	lda xbc, (xsp + 16)
	cpw (xbc + 2), 0xEF
	jr nz, UIViewFrame_ZeroReturn
	ld xwa, (xsp + 8)
	ldw (xwa + 16), 0xD8
	ldw (xwa + 20), 0xEE
	ld bc, (xbc)
	sub bc, 0x10
	ld (xwa + 14), bc
	ld bc, (xsp + 12)
	add bc, 0xF
	ld xwa, (xsp + 4)
	ld (xwa + 18), bc

UIViewFrame_ZeroReturn:
	lds32 xhl, 0
	jr LABEL_FA0FB3

LABEL_FA0F77:
	call GetViewInstance
	lda xwa, (xhl + 36)
	lda xhl, (xhl + 38)
	ld bc, (xhl)
	ld de, (xwa)
	ld wa, de
	cp wa, (xhl)
	jr nc, LABEL_FA0F92
	ldfr_werp DE, 0xFA
	ld iz, bc
	jr LABEL_FA0F97

LABEL_FA0F92:
	ldfr_werp BC, 0xFA
	ld iz, de

LABEL_FA0F97:
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 20)
	call SendEvent
	cp_werp HL, 0xFA
	jr c, UIViewFrame_ZeroReturn
	cp hl, iz
	jr ugt, UIViewFrame_ZeroReturn
	lds32 xhl, 1

LABEL_FA0FB3:
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
	cp xwa, 0x1C00030
	jrl z, LABEL_FA111C
	cp xwa, 0x1C00007
	jr z, LABEL_FA1035
	cp xwa, 0x1C0000D
	jr z, LABEL_FA0FEB
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	jrl LABEL_FA1193

LABEL_FA0FEB:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA1020
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	jrl LABEL_FA1183

LABEL_FA1020:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	jrl LABEL_FA1183

LABEL_FA1035:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jrl z, LABEL_FA1112
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 6)
	call SendEvent
	cps hl, 0
	jrl z, LABEL_FA1112
	ld xwa, xiz
	ld xbc, 0x1E00051
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xFFFF
	jrl z, AcIndexEdit_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA1088
	ld xwa, xiz
	ld xiz, 0x28
	jr AcIndexEdit_DispatchDSP

LABEL_FA1088:
	ld xwa, xiz
	ld xiz, 0x26

; AcIndexEdit widget dispatch with view lookup
AcIndexEdit_DispatchDSP:
	call GetViewInstance
	add xhl, xiz
	ld a, (xhl)
	extz wa
	cps wa, 0
	jrl mi, AcIndexEdit_ReturnZeroJmp
	cp wa, 0x10
	jrl gt, AcIndexEdit_ReturnZeroJmp
	lda_24 xix, 0xeaa33c
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	extz wa
	sll wa, 1
	ld xix, 0xEAA34E
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfa10c8
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_FA10C8:
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	bit	7, wa
	jr	z, 13
	ld	xwa, 4294967295
	ld	xbc, 29360152
	jrl	161
	ld	xwa, 4294967295
	ld	xbc, 29360151
	jrl	148
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 4294967295
	ld	xbc, 29360151
	jrl	130
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 4294967295
	ld	xbc, 29360152
	jr	t, 0x71

LABEL_FA1112:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	jr LABEL_FA1193

LABEL_FA111C:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, LABEL_FA118B
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 6)
	call SendEvent
	cps hl, 0
	jr z, LABEL_FA118B
	ld xwa, xiz
	ld xbc, 0x1E00051
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xFFFF
	jr z, AcIndexEdit_ReturnZeroJmp
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	ld xde, (xsp + 6)
	call SendEvent
	ld xde, (xsp + 6)
	set 7, de
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call SendEvent
	ld de, (xsp + 4)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00031

LABEL_FA1183:
	call SendEvent

AcIndexEdit_ReturnZeroJmp:
	lds32 xhl, 0
	jr LABEL_FA1197

LABEL_FA118B:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)

LABEL_FA1193:
	call InheritedProc

LABEL_FA1197:
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
	cp xwa, 0x1C00007
	jr z, LABEL_FA1211
	cp xwa, 0x1C0000D
	jr z, LABEL_FA11C5
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl LABEL_FA1271

LABEL_FA11C5:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA11F9
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	jr LABEL_FA120B

LABEL_FA11F9:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1C0000F

LABEL_FA120B:
	call SendEvent
	jr LABEL_FA1265

LABEL_FA1211:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, LABEL_FA1269
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	cps hl, 0
	jr z, LABEL_FA1269
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA1252
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 42)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr LABEL_FA1261

LABEL_FA1252:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

LABEL_FA1261:
	call ApFuncCall

LABEL_FA1265:
	lds32 xhl, 0
	jr LABEL_FA1275

LABEL_FA1269:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

LABEL_FA1271:
	call InheritedProc

LABEL_FA1275:
	pop xiz
	inc 8, xsp
	ret

VwEditSwBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1E0003A
	jr z, LABEL_FA12E6
	cp xbc, 0x1C0000D
	jr z, LABEL_FA129D
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl LABEL_FA131F

LABEL_FA129D:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA12CE
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	jr LABEL_FA12E0

LABEL_FA12CE:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1C0000F

LABEL_FA12E0:
	call SendEvent
	jr LABEL_FA131D

LABEL_FA12E6:
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA1303
	ld xwa, xiz
	ld xiz, 0x2A
	jr LABEL_FA130A

LABEL_FA1303:
	ld xwa, xiz
	ld xiz, 0x28

LABEL_FA130A:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

LABEL_FA131D:
	lds32 xhl, 0

LABEL_FA131F:
	pop xiz
	inc 4, xsp
	ret

PsPageBoxProc:
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x14, 0x01
	cp xbc, 0x1E0007F
	jrl z, LABEL_FA147C
	cp xbc, 0x1E00056
	jrl z, LABEL_FA146A
	cp xbc, 0x1E00055
	jrl z, LABEL_FA1466
	cp xbc, 0x1E00054
	jrl z, LABEL_FA1466
	cp xbc, 0x1E00053
	jrl z, LABEL_FA144A
	cp xbc, 0x1C0000F
	jr z, LABEL_FA13B6
	cp xbc, 0x1C00001
	jrl nz, LABEL_FA1490
	ld_sril XWA, (xsp + 0x0114)
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
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	call SendEvent
	jrl UIVwBox_ZeroReturn

LABEL_FA13B6:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld (xsp + 4), xhl
	or xiz, xiz
	jr z, LABEL_FA13E6
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	ld xwa, (xbc)
	ld de, iz
	ld (xwa), de
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	call SendEvent

LABEL_FA13E6:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld iz, (xwa)
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1E00055
	lds32 xde, 0
	call SendEvent
	pushw hl
	pushw iz
	pushw 0xEA
	pushw 0xA354
	lda xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	st_dri3b A, 0xFD, 0x0C, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b A, 0xFD, 0x08, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b A, 0xFD, 0x08, 0x01
	lda xde, (xsp + 8)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringCentered
	jr UIVwBox_ZeroReturn

LABEL_FA144A:
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, xiz
	call SendEvent
	cp xhl, 0x10
	scc16 z, hl
	extz xhl
	jr UI_VwBox_Return

LABEL_FA1466:
	lds32 xhl, 1
	jr UI_VwBox_Return

LABEL_FA146A:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld hl, (xwa)
	exts xhl
	jr UI_VwBox_Return

LABEL_FA147C:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xbc, (xhl + 28)
	ld wa, iz
	ld (xbc), wa

UIVwBox_ZeroReturn:
	lds32 xhl, 0
	jr UI_VwBox_Return

LABEL_FA1490:
	ld_sril XWA, (xsp + 0x0114)
	ld xde, xiz
	calr VwBoxProc

UI_VwBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

AcWindowPageProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_FA150E
	cp xiz, 0x1E00055
	jr z, LABEL_FA14FA
	cp xiz, 0x1E00054
	jr z, LABEL_FA14F0
	cp xiz, 0x1C0000D
	jr z, LABEL_FA14D8
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jrl LABEL_FA1588

LABEL_FA14D8:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsPageBoxProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl LABEL_FA1578

LABEL_FA14F0:
	ld xwa, (xsp + 12)
	ld xiz, 0x20
	jr LABEL_FA1502

LABEL_FA14FA:
	ld xwa, (xsp + 12)
	ld xiz, 0x22

LABEL_FA1502:
	call GetViewInstance
	add xhl, xiz
	ld hl, (xhl)
	exts xhl
	jr PsToggleBoxProc_Epilogue

LABEL_FA150E:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, LABEL_FA1580
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00056
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 32)
	lda xde, (xwa + 34)
	ld xwa, (xsp + 8)
	bit 7, wa
	jr z, LABEL_FA1562
	cp hl, (xbc)
	jr le, LABEL_FA1552
	dec 1, hl
	jr LABEL_FA1554

LABEL_FA1552:
	ld hl, (xde)

LABEL_FA1554:
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1C0000F
	ld xde, xhl
	jr LABEL_FA1578

LABEL_FA1562:
	cp hl, (xde)
	jr ge, LABEL_FA156A
	inc 1, hl
	jr LABEL_FA156C

LABEL_FA156A:
	ld hl, (xbc)

LABEL_FA156C:
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1C0000F
	ld xde, xhl

LABEL_FA1578:
	call SendEvent
	lds32 xhl, 0
	jr PsToggleBoxProc_Epilogue

LABEL_FA1580:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

LABEL_FA1588:
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
	cp xbc, 0x1E0009C
	jrl z, PsToggleBox_Repaint
	cp xbc, 0x1E0006B
	jrl z, PsToggleBox_GetValue
	cp xbc, 0x1E0003B
	jrl z, PsToggleBox_SetValue
	cp xbc, 0x1E0006C
	jrl z, PsToggleBox_Toggle
	cp xbc, 0x1E00053
	jrl z, PsToggleBox_HitTest
	cp xbc, 0x1C0000F
	jr z, PsToggleBox_Confirm
	cp xbc, 0x1C0000D
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
	cpw (xsp + 18), 0xEF
	jr z, PsToggleBox_Paint_SendConfirm
	ld wa, (xiz + 38)
	calr DrawEditSw

PsToggleBox_Paint_SendConfirm:
	ld xwa, (xiz + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 28)
	ld xbc, 0x1C0000F
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
	ldw bc, 0xCA
	ldw de, 0xA
	jr PsToggleBox_Confirm_DrawOn

PsToggleBox_Confirm_OnLarge:
	ldw bc, 0xC3
	ldw de, 0xA

PsToggleBox_Confirm_DrawOn:
	call DrawDesignBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 20)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 22)
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, (xhl + 26)
	jr PsToggleBox_Confirm_RenderText

PsToggleBox_Confirm_DrawOff:
	cpw (xbc), 0x7
	jr ugt, PsToggleBox_Confirm_OffLarge
	ldw bc, 0xC9
	lds de, 7
	jr PsToggleBox_Confirm_DrawOffBox

PsToggleBox_Confirm_OffLarge:
	ldw bc, 0xC1
	lds de, 7

PsToggleBox_Confirm_DrawOffBox:
	call DrawDesignBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 20)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 22)
	push xde
	pushw 0x0
	pushw 0xF7
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
	cps hl, 0
	jrl z, PsToggleBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 24)
	call SendEvent
	ld xwa, (xsp + 4)
	ld wa, (xwa + 38)
	extz xwa
	cp xwa, xhl
	jrl nz, PsToggleBox_ReturnZero
	lds32 xhl, 1
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr PsToggleBox_Toggle_Dispatch

PsToggleBox_Toggle_SetOn:
	ld xwa, (xsp + 28)
	ld xbc, 0x1C0000F
	lds32 xde, 1

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
	ld xbc, 0x1C0000F
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
	cps hl, 0
	jr z, PsToggleBox_Repaint_UpdateBounds
	ld xwa, (xsp + 28)
	ld xbc, 0x1C0000C
	lds32 xde, 0
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
	cpw (xwa + 2), 0xEF
	jr z, PsToggleBox_Repaint_Render
	lda xbc, (xsp + 8)
	cpw (xwa), 0x13F
	jr z, PsToggleBox_Repaint_ClampRight
	ldw (xbc), 0x0
	jr PsToggleBox_Repaint_Render

PsToggleBox_Repaint_ClampRight:
	ldw (xbc + 4), 0x13F

PsToggleBox_Repaint_Render:
	lda xwa, (xsp + 8)
	ldw bc, 0xF5
	call DrawBox

PsToggleBox_ReturnZero:
	lds32 xhl, 0
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
	cp xwa, 0x1C00007
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
	ld xbc, 0x1E00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcFuncToggle_Default
	ld xwa, xiz
	ld xbc, 0x1E0006C
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, 0x1E0003B
	call ApFuncCall
	lds32 xhl, 0
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
	cp xiz, 0x1E00050
	jrl z, AcIndexToggle_CanScrollEvt
	cp xiz, 0x1E00051
	jrl z, AcIndexToggle_GetIndex
	cp xiz, 0x1C0002A
	jrl z, AcIndexToggle_Select
	cp xiz, 0x1C0001B
	jrl z, AcIndexToggle_Release
	cp xiz, 0x1C00007
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
	cps hl, 0
	jr z, AcIndexToggle_OK_Default
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcIndexToggle_OK_Default
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0xFFFF
	jr z, AcIndexToggle_OK_SetValue
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent

AcIndexToggle_OK_SetValue:
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0003B
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 4)
	ld bc, (xwa + 42)
	extz xbc
	ld wa, (xwa + 40)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00029
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
	ld xbc, 0x1E0003B
	lds32 xde, 0
	jr AcIndexToggle_Dispatch

AcIndexToggle_Select:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr PsToggleBoxProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 40)
	cpw (xwa), 0xFFFF
	jr z, AcIndexToggle_ReturnZero
	ld xbc, (xsp + 8)
	srl xbc, 0
	ldi_werp 0xE6, 0
	ld de, (xwa)
	ld wa, de
	cp wa, bc
	jr nz, AcIndexToggle_ReturnZero
	ld xwa, (xsp + 8)
	ld bc, (xhl + 42)
	cp bc, wa
	jr nz, AcIndexToggle_ReturnZero
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0003B
	lds32 xde, 1

AcIndexToggle_Dispatch:
	call SendEvent

AcIndexToggle_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1E00053
	jrl z, PsWideToggle_HitTest
	cp xbc, 0x1E00052
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
	srl xwa, 0
	ldi_werp 0xE2, 0
	ldfr_werp WA, 0xFA
	ld xwa, (xsp + 20)
	ld iz, wa
	ldto_werp WA, 0xFA
	cp wa, iz
	jr c, PsWideToggle_GetBounds_CalcPts
	ldto_werp HL, 0xFA
	ldto_werp WA, 0xFA
	ex16 wa, iz
	ldfr_werp WA, 0xFA

PsWideToggle_GetBounds_CalcPts:
	lda xbc, (xsp + 16)
	ldto_werp WA, 0xFA
	calr GetEditSwPoint
	lda xbc, (xsp + 12)
	ld wa, iz
	calr GetEditSwPoint
	lda xbc, (xsp + 16)
	cpw (xbc + 2), 0xEF
	jr nz, PsWideToggle_ReturnZero
	ld xwa, (xsp + 8)
	ldw (xwa + 16), 0xD8
	ldw (xwa + 20), 0xEE
	ld bc, (xbc)
	sub bc, 0x10
	ld (xwa + 14), bc
	ld bc, (xsp + 12)
	add bc, 0xF
	ld xwa, (xsp + 4)
	ld (xwa + 18), bc

PsWideToggle_ReturnZero:
	lds32 xhl, 0
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
	ldfr_werp DE, 0xFA
	ld iz, bc
	jr PsWideToggle_HitTest_Check

PsWideToggle_HitTest_SwapOrder:
	ldfr_werp BC, 0xFA
	ld iz, de

PsWideToggle_HitTest_Check:
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 20)
	call SendEvent
	cp_werp HL, 0xFA
	jr c, PsWideToggle_ReturnZero
	cp hl, iz
	jr ugt, PsWideToggle_ReturnZero
	lds32 xhl, 1

PsWideToggle_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

PsInvisibleBoxProc:
	cp xbc, 0x1E0003A
	jr z, PsInvisibleBox_GetText
	cp xbc, 0x1C0000F
	jr z, PsInvisibleBox_ReturnZero
	cp xbc, 0x1C0000D
	jr z, PsInvisibleBox_ReturnZero
	jp ViewableProc

PsInvisibleBox_GetText:
	ld (xde), 0x0

PsInvisibleBox_ReturnZero:
	lds32 xhl, 0
	ret

IvPageControlProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1C0001E
	jr z, IvPageControl_PageChange
	cp xiz, 0x1E0003A
	jr z, IvPageControl_GetText
	cp xiz, 0x1C0000D
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr IvPageControl_Dispatch

IvPageControl_GetText:
	pushw 0xEA
	pushw 0xA360
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
	ld xbc, 0x1E00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageControl_PageChange_Init
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld xbc, 0x1C00002
	lds32 xde, 0
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
	ld xbc, 0x1C00001
	lds32 xde, 0

IvPageControl_Dispatch:
	call SendEvent

IvPageControl_ReturnZero:
	lds32 xhl, 0

IvPageControl_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvMainEditSwProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1C00034
	jrl z, IvMainEditSw_BtnRecord
	cp xbc, 0x1C00033
	jr z, IvMainEditSw_BtnDelete
	cp xbc, 0x1C00032
	jr z, IvMainEditSw_BtnCancel
	cp xbc, 0x1C0002B
	jr z, IvMainEditSw_BtnOK
	cp xbc, 0x1E0003A
	jr z, IvMainEditSw_GetText
	cp xbc, 0x1C0000D
	jr nz, IvMainEditSw_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr IvMainEditSw_ReturnZero

IvMainEditSw_GetText:
	pushw 0xEA
	pushw 0xA366
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr IvMainEditSw_ReturnZero

IvMainEditSw_BtnOK:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1C00007
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnCancel:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1C00008
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnDelete:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1C00009
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnRecord:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1C00030
	ld xde, (xsp + 4)

IvMainEditSw_DispatchChild:
	call MainFuncCall

IvMainEditSw_ReturnZero:
	lds32 xhl, 0
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
	cp xbc, 0x1E00053
	jr z, IvExit_HitTest
	cp xbc, 0x1E0003A
	jr z, IvExit_GetText
	cp xbc, 0x1C0000D
	jr z, IvExit_Paint
	ld xwa, xiz
	calr PsInvisibleBoxProc
	jr IvExit_Return

IvExit_Paint:
	ld xwa, xiz
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr IvExit_ReturnZero

IvExit_GetText:
	pushw 0xEA
	pushw 0xA36C
	push xde
	call Strcpy
	inc 8, xsp

IvExit_ReturnZero:
	lds32 xhl, 0
	jr IvExit_Return

IvExit_HitTest:
	cp xde, 0xF
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
	cp xwa, 0x1C00007
	jr z, IvExitMode_OK
	cp xwa, 0x1E0003A
	jr z, IvExitMode_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitMode_DefaultTail

IvExitMode_GetText:
	pushw 0xEA
	pushw 0xA372
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvExitMode_Return

IvExitMode_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitMode_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitMode_OK_SaveCheck
	ld xde, (xiz + 22)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	call PostEvent
	jr IvExitMode_OK_Forward

IvExitMode_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0009A
	lds32 xde, 0
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
	cp xwa, 0x1C00007
	jr z, IvExitScreen_OK
	cp xwa, 0x1E0003A
	jr z, IvExitScreen_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitScreen_DefaultTail

IvExitScreen_GetText:
	pushw 0xEA
	pushw 0xA378
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvExitScreen_Return

IvExitScreen_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitScreen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitScreen_OK_SaveCheck
	ld xwa, (xiz + 22)
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent
	jr IvExitScreen_OK_Forward

IvExitScreen_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0009A
	lds32 xde, 0
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
	cp xiz, 0x1C00007
	jr z, IvExitWindow_OK
	cp xiz, 0x1E0003A
	jr z, IvExitWindow_GetText
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvExitWindow_DefaultTail

IvExitWindow_GetText:
	pushw 0xEA
	pushw 0xA37E
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvExitWindow_Return

IvExitWindow_OK:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitWindow_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitWindow_OK_SaveCheck
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call PostEvent
	jr IvExitWindow_OK_Forward

IvExitWindow_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0009A
	lds32 xde, 0
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
	cp xwa, 0x1C00001
	jr z, IvFixWin_Init
	cp xwa, 0x1C0000D
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
	ld xbc, 0x1C0000F
	ld xde, 0xEAA384
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
	lds32 xhl, 0

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
	cp xiz, 0x1C00002
	jr z, IvNaming_Close
	cp xiz, 0x1C00001
	jr z, IvNaming_Init
	cp xiz, 0x1C0000D
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
	ld xbc, 0x1C0000F
	ld xde, 0xEAA38A
	jr IvNaming_Dispatch

IvNaming_Init:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xde, (xhl + 22)
	ld xwa, 0xA
	ld xbc, 0x1E0007B
	call SendEvent
	ld xwa, 0xA
	ld xbc, xiz
	lds32 xde, 0

IvNaming_Dispatch:
	call SendEvent
	jr IvNaming_ReturnZero

IvNaming_Close:
	ld xwa, 0xA
	ld xbc, xiz
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

IvNaming_ReturnZero:
	lds32 xhl, 0

IvNaming_Return:
	pop xiz
	inc 8, xsp
	ret

GetNamingWindowID:
	ld xhl, 0xA
	ret

NamingCheck:
	push xiz
	ld xiz, xwa
	lda_24 xwa, 0x03ef6e
	cp xbc, 0x1E0007C
	jr z, NamingCheck_GetStrLen
	cp xbc, 0x1E00084
	jr z, NamingCheck_NotHandled
	cp xbc, 0x1E0003A
	jr nz, NamingCheck_NotHandled
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr NamingCheck_Return

NamingCheck_NotHandled:
	lds32 xhl, 0
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
	cp xwa, 0x1C00001
	jr z, IvTrackSwitch_Init
	cp xwa, 0x1C0000D
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
	ld xbc, 0x1C0000F
	ld xde, 0xEAA390
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
	lds32 xhl, 0

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
	cp xwa, 0xFFFFFF
	jr ule, IvCatchEvent_Lookup
	cp xwa, 0x3000000
	jr c, IvCatchEvent_Forward
	cp xwa, 0x3FFFFFF
	jr ugt, IvCatchEvent_Forward

IvCatchEvent_Lookup:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ld xhl, xwa
	ldi_werp 0xEE, 0
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, 0x027edc
	add xbc, xde
	ld xde, (xbc)
	extz xhl
	sll xhl, 2
	add xhl, xde
	ld xiz, (xhl)
	ld xix, xiz
	ld xbc, 0x1E00085
	lds32 xde, 0
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
	cp xbc, 0x1C0000D
	jr z, LABEL_FA212D
	cp xbc, 0x1E00085
	jr z, LABEL_FA2129
	ld xwa, xiz
	call InheritedProc
	jr LABEL_FA2145

LABEL_FA2129:
	lds32 xhl, 1
	jr LABEL_FA2145

LABEL_FA212D:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	ld xde, 0xEAA396
	call SendEvent
	lds32 xhl, 0

LABEL_FA2145:
	pop xiz
	ret

IvInterruptProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E000B6
	jrl z, LABEL_FA21F6
	cp xiz, 0x1E0009D
	jrl z, LABEL_FA21E8
	cp xiz, 0x1E0003A
	jr z, LABEL_FA21D4
	cp xiz, 0x1C0000D
	jr z, LABEL_FA21B9
	cp xiz, 0x1C00001
	jr z, LABEL_FA218A
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jrl ReminderProc_Return

LABEL_FA218A:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E0009D
	lds32 xde, 0
	call SendEvent
	cps hl, 1
	jr nz, LABEL_FA21A6
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld hl, (xhl + 22)

LABEL_FA21A6:
	ld wa, hl
	call SetInterruptTime
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jr LABEL_FA21E4

LABEL_FA21B9:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr LABEL_FA21E4

LABEL_FA21D4:
	pushw 0xEA
	pushw 0xA39C
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

LABEL_FA21E4:
	lds32 xhl, 0
	jr ReminderProc_Return

LABEL_FA21E8:
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld hl, (xhl + 22)
	extz xhl
	jr ReminderProc_Return

LABEL_FA21F6:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E0009D
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	scc16 z, hl
	extz xhl

ReminderProc_Return:
	pop xiz
	inc 8, xsp
	ret

IvIntReminderProc:
	cp xbc, 0x1E0009D
	jr z, LABEL_FA222F
	cp xbc, 0x1E0003A
	jrl nz, IvInterruptProc
	pushw 0xEA
	pushw 0xA3A2
	push xde
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	ret

LABEL_FA222F:
	lds32 xhl, 0
	ld8_24 l, 0x0340e6
	ret

IvIntCompleteProc:
	cp xbc, 0x1E0009D
	jr z, LABEL_FA2258
	cp xbc, 0x1E0003A
	jrl nz, IvInterruptProc
	pushw 0xEA
	pushw 0xA3A8
	push xde
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	ret

LABEL_FA2258:
	lds32 xhl, 0
	ld8_24 l, 0x0340e8
	ret

IvIntErrorProc:
	cp xbc, 0x1E0009D
	jr z, LABEL_FA2281
	cp xbc, 0x1E0003A
	jrl nz, IvInterruptProc
	pushw 0xEA
	pushw 0xA3AE
	push xde
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	ret

LABEL_FA2281:
	lds32 xhl, 0
	ld8_24 l, 0x0340ec
	ret

IvIntVariProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0009D
	jr z, LABEL_FA22F8
	cp xiz, 0x1E0003A
	jr z, LABEL_FA22E4
	cp xiz, 0x1C00002
	jr z, LABEL_FA22D1
	cp xiz, 0x1C00001
	jr z, LABEL_FA22C1
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr LABEL_FA22FF

LABEL_FA22C1:
	lds wa, 1
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr LABEL_FA22DF

LABEL_FA22D1:
	lds wa, 0
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

LABEL_FA22DF:
	calr IvInterruptProc
	jr LABEL_FA22F4

LABEL_FA22E4:
	pushw 0xEA
	pushw 0xA3B4
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

LABEL_FA22F4:
	lds32 xhl, 0
	jr LABEL_FA22FF

LABEL_FA22F8:
	lds32 xhl, 0
	ld8_24 l, 0x0340ee

LABEL_FA22FF:
	pop xiz
	inc 8, xsp
	ret

IvIntEasySetProc:
	cp xbc, 0x1E0009D
	jr z, LABEL_FA2324
	cp xbc, 0x1E0003A
	jrl nz, IvInterruptProc
	pushw 0xEA
	pushw 0xA3BA
	push xde
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	ret

LABEL_FA2324:
	lds32 xhl, 0
	ld8_24 l, 0x0340f0
	ret

IvIntWelcomeProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0009D
	jr z, LABEL_FA239B
	cp xiz, 0x1E0003A
	jr z, LABEL_FA2387
	cp xiz, 0x1C00002
	jr z, LABEL_FA2374
	cp xiz, 0x1C00001
	jr z, LABEL_FA2364
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr LABEL_FA239D

LABEL_FA2364:
	lds wa, 1
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr LABEL_FA2382

LABEL_FA2374:
	lds wa, 0
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

LABEL_FA2382:
	calr IvInterruptProc
	jr LABEL_FA2397

LABEL_FA2387:
	pushw 0xEA
	pushw 0xA3C0
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

LABEL_FA2397:
	lds32 xhl, 0
	jr LABEL_FA239D

LABEL_FA239B:
	lds32 xhl, 1

LABEL_FA239D:
	pop xiz
	inc 8, xsp
	ret

IvShowHideProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1C0000C
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1C0000B
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1C00002
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1C00001
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1C0000D
	jr nz, LABEL_FA241C
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	ld xde, 0xEAA3C6
	call SendEvent
	jr LABEL_FA2418

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

LABEL_FA2418:
	lds32 xhl, 0
	jr LABEL_FA2427

LABEL_FA241C:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc

LABEL_FA2427:
	pop xiz
	inc 8, xsp
	ret

AcSoundNameProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1C00020
	jrl z, LABEL_FA2571
	cp xbc, 0x1C0002F
	jrl z, LABEL_FA2544
	cp xbc, 0x1C0001C
	jr z, LABEL_FA24BD
	cp xbc, 0x1C0000C
	jr z, LABEL_FA2480
	cp xbc, 0x1C0000B
	jr z, LABEL_FA2480
	cp xbc, 0x1C00002
	jr z, LABEL_FA2475
	cp xbc, 0x1C00001
	jrl nz, LABEL_FA25BA
	ld xwa, xiz
	ld xde, (xsp + 4)
	jr LABEL_FA247A

LABEL_FA2475:
	ld xwa, xiz
	ld xde, (xsp + 4)

LABEL_FA247A:
	calr PsParaBoxProc
	jrl AcRhythm_ReturnZeroJmp

LABEL_FA2480:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xFF
	jr z, LABEL_FA24A8
	ld de, (xwa)
	extz xde
	ld xwa, 0x1400004
	ld xbc, 0x1E0005E
	jrl AcRhythm_SendPartEvent

LABEL_FA24A8:
	call GetPartSelect
	extz xhl
	ld xwa, 0x1400004
	ld xbc, 0x1E0005E
	ld xde, xhl
	jrl AcRhythm_SendPartEvent

LABEL_FA24BD:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xFF
	jr z, LABEL_FA2503
	ld de, (xwa)
	extz xde
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 4)
	cp xhl, (xwa)
	jr z, LABEL_FA24F7
	add xbc, 0x8020
	cp xbc, (xwa)
	jrl nz, AcRhythm_ReturnZeroJmp

LABEL_FA24F7:
	ld xwa, 0x1400004
	ld xbc, 0x1E0005E
	jr AcRhythm_SendPartEvent

LABEL_FA2503:
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8000
	ld xwa, (xsp + 4)
	cp (xwa), xhl
	jr z, LABEL_FA2530
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8020
	ld xwa, (xsp + 4)
	cp (xwa), xhl
	jrl nz, AcRhythm_ReturnZeroJmp

LABEL_FA2530:
	call GetPartSelect
	extz xhl
	ld xwa, 0x1400004
	ld xbc, 0x1E0005E
	ld xde, xhl
	jr AcRhythm_SendPartEvent

LABEL_FA2544:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	cpw (xhl + 36), 0xFF
	jr nz, AcRhythm_ReturnZeroJmp
	call GetPartSelect
	extz xhl
	ld xwa, 0x1400004
	ld xbc, 0x1E0005E
	ld xde, xhl

AcRhythm_SendPartEvent:
	call FuncCall
	jr AcRhythm_ReturnZeroJmp

LABEL_FA2571:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 36)
	cpw (xbc), 0xFF
	jr z, LABEL_FA259D
	ld xde, (xsp + 4)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, AcRhythm_ReturnZeroJmp
	ld xde, (xde + 2)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	jr LABEL_FA25B2

LABEL_FA259D:
	call GetPartSelect
	ld xwa, (xsp + 4)
	cp (xwa), hl
	jr nz, AcRhythm_ReturnZeroJmp
	ld xde, (xwa + 2)
	ld xwa, xiz
	ld xbc, 0x1C0000F

LABEL_FA25B2:
	call SendEvent

AcRhythm_ReturnZeroJmp:
	lds32 xhl, 0
	jr LABEL_FA25C2

LABEL_FA25BA:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc

LABEL_FA25C2:
	pop xiz
	inc 4, xsp
	ret

AcRhythmNameProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1C00021
	jrl z, LABEL_FA2657
	cp xbc, 0x1C0001C
	jr z, LABEL_FA2626
	cp xbc, 0x1C0000C
	jr z, LABEL_FA2610
	cp xbc, 0x1C0000B
	jr z, LABEL_FA2610
	cp xbc, 0x1C00002
	jr z, LABEL_FA2606
	cp xbc, 0x1C00001
	jr nz, LABEL_FA2671
	ld xwa, xiz
	ld xde, (xsp + 4)
	jr LABEL_FA260B

LABEL_FA2606:
	ld xwa, xiz
	ld xde, (xsp + 4)

LABEL_FA260B:
	calr PsParaBoxProc
	jr PsParaBox_ZeroReturn

LABEL_FA2610:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, 0x1400005
	ld xbc, 0x1E0005F
	lds32 xde, 0
	jr LABEL_FA2651

LABEL_FA2626:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	cp xwa, 0x28000
	jr z, LABEL_FA2645
	ld xwa, (xbc)
	cp xwa, 0x28001
	jr nz, PsParaBox_ZeroReturn

LABEL_FA2645:
	ld xwa, 0x1400005
	ld xbc, 0x1E0005F
	lds32 xde, 0

LABEL_FA2651:
	call FuncCall
	jr PsParaBox_ZeroReturn

LABEL_FA2657:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	ld xde, (xsp + 4)
	call SendEvent

PsParaBox_ZeroReturn:
	lds32 xhl, 0
	jr LABEL_FA2679

LABEL_FA2671:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc

LABEL_FA2679:
	pop xiz
	inc 4, xsp
	ret

AcPmemNameProc:
	lda xsp, (xsp - 44)
	push xiz
	ld xiz, xde
	ld (xsp + 44), xwa
	cp xbc, 0x1C00022
	jr z, LABEL_FA2705
	cp xbc, 0x1C0001C
	jr z, LABEL_FA26DF
	cp xbc, 0x1C0000C
	jr z, LABEL_FA26C9
	cp xbc, 0x1C0000B
	jr z, LABEL_FA26C9
	cp xbc, 0x1C00002
	jr z, LABEL_FA26BE
	cp xbc, 0x1C00001
	jrl nz, LABEL_FA278C
	ld xwa, (xsp + 44)
	ld xde, xiz
	jr LABEL_FA26C3

LABEL_FA26BE:
	ld xwa, (xsp + 44)
	ld xde, xiz

LABEL_FA26C3:
	calr PsParaBoxProc
	jrl PsParaBox_EventReturn

LABEL_FA26C9:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, 0x1400006
	ld xbc, 0x1E00060
	lds32 xde, 0
	jr LABEL_FA26FE

LABEL_FA26DF:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, (xiz)
	cp xwa, 0x300
	jrl nz, PsParaBox_EventReturn
	ld xwa, 0x1400006
	ld xbc, 0x1E00060
	lds32 xde, 0

LABEL_FA26FE:
	call MainFuncCall
	jrl PsParaBox_EventReturn

LABEL_FA2705:
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
	jr z, LABEL_FA276A
	cpw (xiz), 0x0
	jr z, LABEL_FA2756
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
	pushw 0xEA
	pushw 0xA3CC
	push xix
	call Audio_SendCommand
	lda xsp, (xsp + 16)
	jr LABEL_FA2779

LABEL_FA2756:
	ld xwa, (xde)
	push xwa
	pushw hl
	pushw 0xEA
	pushw 0xA3DE
	push xix
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jr LABEL_FA2779

LABEL_FA276A:
	pushw hl
	pushw 0xEA
	pushw 0xA3EE
	push xix
	call Audio_SendCommand
	lda xsp, (xsp + 10)

LABEL_FA2779:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 44)
	ld xbc, 0x1C0000F
	call SendEvent

PsParaBox_EventReturn:
	lds32 xhl, 0
	jr LABEL_FA2794

LABEL_FA278C:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc

LABEL_FA2794:
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
	cp xwa, 0x1E00061
	jrl z, LABEL_FA2CB0
	cp xwa, 0x1C00030
	jrl z, LABEL_FA2C36
	cp xwa, 0x1C00027
	jrl z, LABEL_FA2BCC
	cp xwa, 0x1C00007
	jrl z, LABEL_FA2B02
	cp xwa, 0x1C0001C
	jrl z, LABEL_FA2A93
	cp xwa, 0x1C00023
	jrl z, LABEL_FA2A18
	cp xwa, 0x1C0000F
	jrl z, LABEL_FA28D7
	cp xwa, 0x1C0000D
	jr z, LABEL_FA2836
	cp xwa, 0x1C0000C
	jr z, LABEL_FA2827
	cp xwa, 0x1C0000B
	jr z, LABEL_FA2827
	cp xwa, 0x1C00002
	jr z, LABEL_FA281C
	cp xwa, 0x1C00001
	jrl nz, LABEL_FA2D07
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr LABEL_FA2830

LABEL_FA281C:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr LABEL_FA2830

LABEL_FA2827:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)

LABEL_FA2830:
	calr VwBoxProc
	jrl UIList_ReturnZeroJmp

LABEL_FA2836:
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
	incm 3, (xwa)
	decm 3, (xde)
	decm 1, (xhl)
	ldw bc, 0x8
	call DrawBox
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 32)
	ld xde, (xsp + 8)
	ld de, (xde + 28)
	extz xde
	sll xde, 2
	ld xhl, 0xEAA40A
	add xhl, xde
	ld xde, (xhl)
	lds32 xhl, 3
	push xhl
	pushw 0xFF
	pushw 0x8
	call DrawStringCentered
	ld xwa, (xsp + 44)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld de, (xwa + 28)
	extz xde
	ld xwa, (xsp + 44)
	ld xbc, 0x1E00061
	jrl UIList_SendEvent

LABEL_FA28D7:
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
	ld xwa, 0xEAA50C
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
	lda_24 xwa, 0xeaa510
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
	pushm (xsp + 4)
	pushw 0xEA
	pushw 0xA6B0
	lda xwa, (xsp + 24)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 24)
	lda xbc, (xsp + 32)
	lda xde, (xsp + 18)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	ld xhl, (xsp + 14)
	pushm (xhl + 22)
	call DrawStringCentered
	lda xwa, (xsp + 32)
	lda xde, (xsp + 24)
	ld bc, (xde)
	inc 4, bc
	ld (xwa), bc
	ld bc, (xde + 2)
	add bc, 0xA
	ld (xwa + 2), bc
	lds32 xbc, 2
	call DrawBitmapFast
	lda xwa, (xsp + 32)
	ldw bc, 0x80
	sub bc, (xsp + 4)
	muls bc, 0x24
	exts xbc
	divs bc, 0x80
	add (xwa + 2), bc
	lds32 xbc, 3
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
	add de, 0x1F
	ld (xbc + 2), de
	ld de, (xbc)
	sub de, 0xC
	ld (xwa), de
	ld de, (xbc)
	add de, 0xC
	ld (xwa + 4), de
	addmi16 (xwa + 6), 0x12
	lds32 xde, 3
	push xde
	pushw 0xFB
	pushw 0x0
	pushw 0x0
	pushw 0x1
	ld xde, 0xEAA6B4
	call DrawStringReverse
	jrl UIList_ReturnZeroJmp

LABEL_FA2A18:
	ld xwa, (xsp + 44)
	call GetViewInstance
	lda xbc, (xhl + 28)
	ld xwa, (xsp + 36)
	cp wa, (xbc)
	jrl nz, UIList_ReturnZeroJmp
	ld wa, (xbc)
	cp wa, 0x1B
	jr nz, LABEL_FA2A39
	ldw (xsp + 10), 0x13
	jr LABEL_FA2A5C

LABEL_FA2A39:
	cp wa, 0x1A
	jr nz, LABEL_FA2A46
	ldw (xsp + 10), 0x12
	jr LABEL_FA2A5C

LABEL_FA2A46:
	ld xwa, (xsp + 36)
	srl xwa, 0
	ldi_werp 0xE2, 0
	srl wa, 8
	ldb w, 0x0
	and a, 0x1F
	extz wa
	ld (xsp + 10), wa

LABEL_FA2A5C:
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 44)
	call GetClientBox
	lda xwa, (xsp + 32)
	lda xde, (xsp + 24)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde + 2)
	add bc, 0x3D
	ld (xwa + 2), bc
	ld bc, (xsp + 10)
	sla bc, 2
	lda_24 xde, 0xeaa624
	ld_sril3 XBC, 0x07, 0xE8, 0xE4
	call DrawBitmapFast
	jrl UIList_ReturnZeroJmp

LABEL_FA2A93:
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
	ld xbc, 0xEAA50C
	add xbc, xwa
	ld xhl, (xsp + 36)
	ld xwa, (xhl)
	cp xwa, (xbc)
	jr z, LABEL_FA2ACB
	ld xwa, (xhl)
	cp xwa, (xbc + 4)
	jr nz, LABEL_FA2AD8

LABEL_FA2ACB:
	ld xwa, (xsp + 44)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl UIList_SendEvent

LABEL_FA2AD8:
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 36)
	cp xhl, (xwa)
	jr z, LABEL_FA2AF7
	add xbc, 0x8020
	cp xbc, (xwa)
	jrl nz, UIList_ReturnZeroJmp

LABEL_FA2AF7:
	ld xwa, (xsp + 44)
	ld xbc, 0x1E00061
	jrl UIList_SendEvent

LABEL_FA2B02:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 36)
	call SendEvent
	ld xbc, (xsp + 8)
	ld wa, (xbc + 30)
	extz xwa
	cp xwa, xhl
	jrl nz, LABEL_FA2BC0
	ld wa, (xbc + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0xeaa510
	add xwa, xbc
	ld xwa, (xwa)
	call SndParam_LookupReadOnly
	ld (xsp + 6), hl
	ld xwa, (xsp + 8)
	lda xwa, (xwa + 28)
	cpw (xsp + 6), 0x0
	jr z, LABEL_FA2B81
	ld bc, (xwa)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, 0xEAA50C
	add xbc, xwa
	ld xwa, (xbc + 4)
	ld de, (xbc + 8)
	lds bc, 0
	calr MainLswPut
	ld xwa, (xsp + 44)
	ld xbc, 0x1C00027
	ld xde, (xsp + 36)
	jr LABEL_FA2BB9

LABEL_FA2B81:
	ld bc, (xwa)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, 0xEAA50C
	add xbc, xwa
	ld de, (xbc + 8)
	ld xwa, (xsp + 36)
	bit 7, wa
	jr z, LABEL_FA2BA7
	ld xwa, (xbc)
	ldw bc, 0xFFFF
	jr LABEL_FA2BAB

LABEL_FA2BA7:
	ld xwa, (xbc)
	lds bc, 1

LABEL_FA2BAB:
	calr MainLswAdd
	ld xwa, (xsp + 44)
	ld xbc, 0x1C00027
	ld xde, (xsp + 36)

LABEL_FA2BB9:
	call SetAutoInc
	jrl UIList_ReturnZeroJmp

LABEL_FA2BC0:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jrl UIList_VwBoxCall

LABEL_FA2BCC:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 36)
	call SendEvent
	ld wa, (xiz + 30)
	extz xwa
	cp xwa, xhl
	jr nz, LABEL_FA2C2A
	ld wa, (xiz + 28)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, (xsp + 36)
	bit 7, wa
	jr z, LABEL_FA2C16
	ld xde, 0xEAA50C
	add xde, xbc
	ld xwa, (xde)
	ld de, (xde + 8)
	ldw bc, 0xFFFC
	jr LABEL_FA2C24

LABEL_FA2C16:
	ld xde, 0xEAA50C
	add xde, xbc
	ld xwa, (xde)
	ld de, (xde + 8)
	lds bc, 4

LABEL_FA2C24:
	calr MainLswAdd
	jrl UIList_ReturnZeroJmp

LABEL_FA2C2A:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jrl UIList_VwBoxCall

LABEL_FA2C36:
	ld xwa, (xsp + 44)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 36)
	call SendEvent
	ld xwa, (xsp + 8)
	ld wa, (xwa + 30)
	extz xwa
	cp xwa, xhl
	jr nz, LABEL_FA2CA5
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	ld xde, (xsp + 36)
	call SendEvent
	ld xde, (xsp + 36)
	set 7, de
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00009
	call SendEvent
	ld xwa, (xsp + 8)
	ld bc, (xwa + 28)
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, 0xEAA50C
	add xbc, xwa
	ld xwa, (xbc + 4)
	ld de, (xbc + 8)
	lds bc, 1
	calr MainLswPut

LABEL_FA2CA5:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr UIList_VwBoxCall

LABEL_FA2CB0:
	ld xwa, (xsp + 36)
	lds bc, 0
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
	sll xbc, 0
	ld xwa, (xsp + 36)
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, (xsp + 44)
	ld xbc, 0x1C00023

UIList_SendEvent:
	call SendEvent

UIList_ReturnZeroJmp:
	lds32 xhl, 0
	jr LABEL_FA2D13

LABEL_FA2D07:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)

UIList_VwBoxCall:
	calr VwBoxProc

LABEL_FA2D13:
	pop xiz
	lda xsp, (xsp + 44)
	ret

LABEL_FA2D18:
	ld	hl, de
	cp	xwa, 29360167
	jr	z, 18
	cp	xwa, 29360135
	jr	nz, 21
	ld	hl, (xsp+4)
	bit	7, bc
	jr	nz, 7
	jr	13
	bit	7, bc
	jr	z, 8
	mul	hl, 65535
	jr	2
	lds	hl, 0
	retd	2

DbMemoProc:
	lda xsp, (xsp - 106)
	push xiz
	ld (xsp + 102), xde
	ld (xsp + 106), xwa
	cp xbc, 0x1C00025
	jr z, LABEL_FA2DC2
	cp xbc, 0x1C0000D
	jr z, LABEL_FA2D6A
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	jr LABEL_FA2DBD

LABEL_FA2D6A:
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	ld xwa, (xsp + 106)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 14)
	ldw bc, 0xC5
	lds de, 7
	call DrawDesignBox
	lda xiy, (xiz + 14)
	lda xix, (xsp + 94)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 94)
	incm 4, (xwa + 2)
	incm 4, (xwa)
	decm 4, (xwa + 4)
	decm 4, (xwa + 6)
	ldw bc, 0xC6
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 106)
	ld xbc, 0x1C00025
	ld xde, 0xEAA6BA
	call SendEvent

LABEL_FA2DBB:
	lds32 xhl, 0

LABEL_FA2DBD:
	pop xiz
	lda xsp, (xsp + 106)
	ret

LABEL_FA2DC2:
	ld xwa, (xsp + 106)
	ld xde, (xsp + 102)
	call ViewableProc
	ld xwa, (xsp + 106)
	call GetViewInstance
	lda xiy, (xhl + 14)
	lda xix, (xsp + 94)
	lds bc, 4
	ldirw
	lda xhl, (xsp + 94)
	lda xde, (xhl + 2)
	incm 5, (xde)
	incm 5, (xhl)
	lda xwa, (xhl + 4)
	decm 5, (xwa)
	lda xbc, (xhl + 6)
	decm 5, (xbc)
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
	lds bc, 4
	ldirw
	incm 8, (xsp + 88)
	lda xiy, (xsp + 94)
	lda xix, (xsp + 78)
	lds bc, 4
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

LABEL_FA2E40:
	lda xwa, (xsp + 86)
	lda xbc, (xsp + 70)
	call MovePixels
	lda xwa, (xsp + 78)
	lds bc, 7
	call DrawBox
	pushm (xsp + 4)
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
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	lda xwa, (xsp + 10)
	push xwa
	call Strlen
	inc 4, xsp
	cp hl, (xsp + 4)
	jrl nz, LABEL_FA2DBB
	ld wa, (xsp + 4)
	extz xwa
	add (xsp + 6), xwa
	jr LABEL_FA2E40
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00025
	ld xde, xiz
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	call PostEvent
	pop xiz
	inc 4, xsp
	ret

LABEL_FA2EE5:
	.byte 0x0e

DbMemoryDumpProc:
	lda xsp, (xsp - 120)
	push xiz
	ld (xsp + 112), xde
	ld (xsp + 116), xbc
	ld (xsp + 120), xwa
	ld xwa, (xsp + 116)
	cp xwa, 0x1C00007
	jrl z, LABEL_FA30ED
	cp xwa, 0x1C0000F
	jrl z, LABEL_FA2FBE
	cp xwa, 0x1C0000E
	jrl z, LABEL_FA2F91
	cp xwa, 0x1C0000D
	jr z, LABEL_FA2F3D
	cp xwa, 0x1C00002
	jr z, LABEL_FA2F2D
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	jrl LABEL_FA314F

LABEL_FA2F2D:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call ViewableProc
	jrl UI_NameCapture_ReturnSuccess

LABEL_FA2F3D:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call ViewableProc
	ld xwa, (xsp + 120)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 14)
	ldw bc, 0xC5
	lds de, 7
	call DrawDesignBox
	lda xiy, (xiz + 14)
	lda xix, (xsp + 104)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 104)
	incm 4, (xwa + 2)
	incm 4, (xwa)
	decm 4, (xwa + 4)
	decm 4, (xwa + 6)
	ldw bc, 0xC6
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 120)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	jrl UI_NameCapture_ReturnSuccess

LABEL_FA2F91:
	ld xwa, (xsp + 120)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, 0x1C0000E
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0x78
	ld_sril XBC, (xsp + 0x0080)
	ld_sril XDE, (xsp + 0x0080)
	call SetApTimer
	jrl UI_NameCapture_ReturnSuccess

LABEL_FA2FBE:
	ld xwa, (xsp + 120)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	lda xiy, (xwa + 14)
	lda xix, (xsp + 104)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 104)
	incm 5, (xwa + 2)
	incm 5, (xwa)
	decm 5, (xwa + 4)
	decm 5, (xwa + 6)
	ldw (xsp + 4), 0x0

LABEL_FA2FE8:
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
	srl xwa, 0
	pushw wa
	pushw 0xEA
	pushw 0xA6C6
	lda xwa, (xsp + 38)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 22)
	lda xwa, (xsp + 104)
	lda xbc, (xsp + 100)
	lda xde, (xsp + 20)
	lds32 xhl, 3
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
	pushw 0xEA
	pushw 0xA6D2
	lda xwa, (xsp + 40)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 24)
	lda xbc, (xsp + 100)
	addmi16 (xbc), 0x30
	lda xwa, (xsp + 104)
	lda xde, (xsp + 20)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	lda xde, (xsp + 10)
	ld xwa, xde
	lda xbc, (xde + 8)

LABEL_FA30B6:
	cp (xwa), 0x20
	jr nc, LABEL_FA30BE
	ld (xwa), 0x2E

LABEL_FA30BE:
	inc 1, xwa
	cp xwa, xbc
	jr c, LABEL_FA30B6
	ld (xde + 8), 0x0
	lda xbc, (xsp + 100)
	addmi16 (xbc), 0x96
	lda xwa, (xsp + 104)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x10
	jrl c, LABEL_FA2FE8
	jrl UI_NameCapture_ReturnSuccess

LABEL_FA30ED:
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 112)
	call SendEvent
	ld xwa, xhl
	cp xhl, 0x10
	jr z, LABEL_FA313F
	dec 2, xwa
	cp xwa, 0x0
	jr c, LABEL_FA3146
	cp xwa, 0x5
	jr ugt, LABEL_FA3146
	sll xwa, 2
	add xwa, 0xEAA6FA
	ld xwa, (xwa)
	ld xiz, xwa

LABEL_FA3127:
	ld xwa, (xsp + 120)
	call GetViewInstance
	lda xde, (xhl + 22)
	ld xbc, (xde)
	ld xwa, (xsp + 112)
	bit 7, wa
	jr z, LABEL_FA3155
	sub (xbc), xiz
	jr LABEL_FA3157

LABEL_FA313F:
	ld xiz, 0x80
	jr LABEL_FA3127

LABEL_FA3146:
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)

LABEL_FA314F:
	call ViewableProc
	jr LABEL_FA317D

LABEL_FA3155:
	add (xbc), xiz

LABEL_FA3157:
	ld xbc, (xde)
	ld xwa, 0xFFFFFF
	and (xbc), xwa
	ld xwa, (xsp + 120)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call SetAutoInc

UI_NameCapture_ReturnSuccess:
	lds32 xhl, 0

LABEL_FA317D:
	pop xiz
	lda xsp, (xsp + 120)
	ret

CaptureLcdCheck:
	cp xbc, 0x1C00007
	call_24 z, 0xFAF030
	lds32 xhl, 0
	ret

PsCursorBoxProc:
	st_dri3b L, 0xFD, 0xD6, 0xFD
	push xiz
	st_dri3l XDE, 0xFD, 0x2A, 0x02
	ld xiz, xwa
	cp xbc, 0x1E00080
	jrl z, LABEL_FA33D3
	cp xbc, 0x1C0000F
	jr z, LABEL_FA3209
	cp xbc, 0x1C0000E
	jr z, LABEL_FA31E5
	cp xbc, 0x1C00001
	jr z, LABEL_FA31CB
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	jrl LABEL_FA33E7

LABEL_FA31CB:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 36)
	ldw (xwa), 0xFFFF
	jrl ScrollBox_ReturnZero

LABEL_FA31E5:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp_sril_rm XBC, 0xFD, 0x2A, 0x02
	jrl z, ScrollBox_ReturnZero
	jrl LABEL_FA33DC

LABEL_FA3209:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 14), xhl
	st_dri3b B, 0xFD, 0x12, 0x01
	ld_sril XWA, (xsp + 0x022a)
	or xwa, xwa
	jr nz, LABEL_FA3236
	ld xwa, xiz
	ld xbc, 0x1E0003A
	call SendEvent
	cp_srib_im 0xFD, 0x12, 0x01, 0x00
	jr nz, LABEL_FA3243
	jrl ScrollBox_ReturnZero

LABEL_FA3236:
	ld_sril XWA, (xsp + 0x022a)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

LABEL_FA3243:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	cpw (xwa), 0xFFFF
	jrl z, ScrollBox_ReturnZero
	st_dri3b A, 0xFD, 0x22, 0x02
	ld xwa, xiz
	call GetClientBox
	st_dri3b W, 0xFD, 0x22, 0x02
	st_dri3b A, 0xFD, 0x12, 0x02
	call GetBoxCenter
	st_dri3b E, 0xFD, 0x22, 0x02
	st_dri3b D, 0xFD, 0x1A, 0x02
	lds bc, 4
	ldirw
	ld xbc, (xsp + 14)
	ld xwa, (xbc + 28)
	ld (xsp + 6), xwa
	ld wa, (xbc + 22)
	ld (xsp + 12), wa
	ld wa, (xbc + 32)
	ld (xsp + 10), wa
	st_dri3b W, 0xFD, 0x12, 0x01
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	call GetCharHeight
	ld iz, hl
	ld xwa, (xsp + 6)
	call GetCharDescent
	ldfr_werp HL, 0xFA
	ld xwa, (xsp + 6)
	call GetCenteredDelta
	st_dri3b B, 0xFD, 0x12, 0x02
	lda xbc, (xde + 2)
	ld wa, iz
	sub_werp WA, 0xFA
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
	st_dri3b W, 0xFD, 0x22, 0x02
	cps c, 2
	jr z, LABEL_FA3300
	cps c, 1
	jr z, LABEL_FA32F8
	cps c, 0
	jr nz, UI_ScrollBox_ComputeLayout
	ld wa, (xsp + 4)
	exts xwa
	divs wa, 0x2
	sub (xde), wa
	jr UI_ScrollBox_ComputeLayout

LABEL_FA32F8:
	ld wa, (xwa)
	inc 4, wa
	ld (xde), wa
	jr UI_ScrollBox_ComputeLayout

LABEL_FA3300:
	ld wa, (xwa + 4)
	dec 4, wa
	sub wa, (xsp + 4)
	ld (xde), wa

UI_ScrollBox_ComputeLayout:
	st_dri3b W, 0xFD, 0x12, 0x01
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	st_dri3b H, 0x07, 0xE4, 0xE0
	ld (xiz + 1), 0x0
	ld xwa, xiz
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld (xiz), 0x0
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld_sriw BC, (xsp + 0x0212)
	add bc, hl
	st_dri3b W, 0xFD, 0x1A, 0x02
	ld (xwa), bc
	add bc, (xsp + 4)
	ld (xwa + 4), bc
	st_dri3b A, 0xFD, 0x16, 0x02
	call GetBoxCenter
	st_dri3b W, 0xFD, 0x12, 0x01
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	st_dri3b H, 0x07, 0xE4, 0xE0
	ld (xiz + 1), 0x0
	st_dri3b W, 0xFD, 0x22, 0x02
	ld bc, (xsp + 12)
	call DrawBox
	st_dri3b W, 0xFD, 0x22, 0x02
	st_dri3b A, 0xFD, 0x12, 0x02
	st_dri3b B, 0xFD, 0x12, 0x01
	ld xhl, (xsp + 6)
	push xhl
	pushm (xsp + 14)
	pushw 0xF7
	call DrawString
	st_dri3b W, 0xFD, 0x1A, 0x02
	st_dri3b B, 0xFD, 0x16, 0x02
	ld xbc, (xsp + 6)
	push xbc
	pushm (xsp + 14)
	pushm (xsp + 18)
	ld xbc, (xsp + 22)
	ld c, (xbc + 34)
	extz bc
	pushw bc
	pushw 0x1
	ld xbc, xde
	ld xde, xiz
	call DrawStringReverse
	jr ScrollBox_ReturnZero

LABEL_FA33D3:
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)

LABEL_FA33DC:
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x022a)
	ld (xbc), wa

ScrollBox_ReturnZero:
	lds32 xhl, 0

LABEL_FA33E7:
	pop xiz
	st_dri3b L, 0xFD, 0x2A, 0x02
	ret

DbDebugMenuProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xbc
	ld xiz, xwa
	ld xwa, (xsp + 24)
	cp xwa, 0x1C00007
	jrl z, LABEL_FA351C
	cp xwa, 0x1C0000F
	jrl z, LABEL_FA34D5
	cp xwa, 0x1C0000D
	jrl z, LABEL_FA34BE
	cp xwa, 0x1C00002
	jr z, LABEL_FA3477
	cp xwa, 0x1C00001
	jr z, LABEL_FA3433
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	jrl LABEL_FA35FC

LABEL_FA3433:
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
	lda_24 xde, 0xeaa744
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	cp xwa, 0xFFFFFFFF
	jrl z, PsMenuBox_ZeroReturn
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	ld xbc, 0x1C00001
	lds32 xde, 0
	jrl PsMenuBox_SendEvent

LABEL_FA3477:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xde, 0xeaa744
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA34B0
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent

LABEL_FA34B0:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	calr PsMenuBoxProc
	jrl PsMenuBox_ZeroReturn

LABEL_FA34BE:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl PsMenuBox_SendEvent

LABEL_FA34D5:
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
	lda_24 xhl, 0xeaa712
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	lds32 xhl, 3
	push xhl
	pushw 0xFF
	pushw 0xF7
	call DrawStringCentered
	jrl PsMenuBox_ZeroReturn

LABEL_FA351C:
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 20)
	call SendEvent
	cps hl, 0
	jrl z, LABEL_FA35C8
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xde, 0xeaa744
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA356E
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent

LABEL_FA356E:
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 42)
	ld xde, xwa
	ld xbc, (xwa)
	incm 1, (xbc)
	ld xbc, (xwa)
	ld wa, (xbc)
	sla wa, 2
	lda_24 xhl, 0xeaa712
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
	cp (xwa), 0x0
	jr nz, LABEL_FA3594
	ldw (xbc), 0x0

LABEL_FA3594:
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0xeaa744
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, (xbc)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA35BA
	ld xwa, (xbc)
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr PsMenuBox_SendEvent

LABEL_FA35BA:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jr PsMenuBox_SendEvent

LABEL_FA35C8:
	ld xwa, (xsp + 20)
	cp xwa, 0xF
	jr nz, LABEL_FA35F4
	lds32 xwa, 7
	ld xbc, 0x1C00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0

PsMenuBox_SendEvent:
	call SendEvent

PsMenuBox_ZeroReturn:
	lds32 xhl, 0
	jr LABEL_FA35FF

LABEL_FA35F4:
	ld xwa, xiz
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)

LABEL_FA35FC:
	calr PsMenuBoxProc

LABEL_FA35FF:
	pop xiz
	lda xsp, (xsp + 24)
	ret

PsTrackSwitchProc:
	st_dri3b L, 0xFD, 0x4E, 0xFF
	push xiz
	st_dri3l XDE, 0xFD, 0xAE, 0x00
	ld xde, xbc
	st_dri3l XWA, 0xFD, 0xB2, 0x00
	ld xiy, 0xEAA750
	lda xix, (xsp + 38)
	ldw bc, 0x28
	ldirw
	ld xiy, 0xEAA7F0
	lda xix, (xsp + 18)
	ldw bc, 0xA
	ldirw
	ld xiy, 0xEAA81A
	lda xix, (xsp + 8)
	lds bc, 5
	ldirw
	cp xde, 0x1E00053
	jrl z, PsTrkSw_HitTest
	cp xde, 0x1C0000E
	jrl z, PsTrkSw_Select
	cp xde, 0x1C0000F
	jrl z, PsTrkSw_Confirm
	cp xde, 0x1C0000C
	jr z, PsTrkSw_ShowHide
	cp xde, 0x1C0000B
	jr z, PsTrkSw_ShowHide
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, xde
	ld_sril XDE, (xsp + 0x00ae)
	call ViewableProc
	jrl PsTrkSw_Epilogue

PsTrkSw_ShowHide:
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, xde
	ld_sril XDE, (xsp + 0x00ae)
	call ViewableProc
	ld_sril XWA, (xsp + 0x00b2)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, 0x1E00010
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x1600058
	jr nz, PsTrkSw_ReturnZero
	ld xwa, (xiz + 28)
	ld bc, (xwa)
	extz xbc
	ld xwa, (xiz + 24)
	ld wa, (xwa)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, 0x1C0000F
	call SendEvent
	ld xwa, (xiz + 32)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, 0x1C0000E
	call SendEvent

PsTrkSw_ReturnZero:
	lds32 xhl, 0
	jrl PsTrkSw_Epilogue

PsTrkSw_Confirm:
	ld_sril XWA, (xsp + 0x00b2)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld_sril XWA, (xsp + 0x00ae)
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld bc, wa
	cp bc, 0xFFFF
	jr z, PsTrkSw_Confirm_SetSub
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld (xwa), bc

PsTrkSw_Confirm_SetSub:
	ld_sril XBC, (xsp + 0x00ae)
	cp bc, 0xFFFF
	jr z, PsTrkSw_Confirm_DrawGeometry
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld (xwa), bc

PsTrkSw_Confirm_DrawGeometry:
	st_dri3b A, 0xFD, 0xA6, 0x00
	ld_sril XWA, (xsp + 0x00b2)
	call GetBox
	st_dri3b A, 0xFD, 0xA6, 0x00
	st_dri3b B, 0xFD, 0x9E, 0x00
	ldw wa, 0xCB
	call GetClientBox2
	st_dri3b E, 0xFD, 0x9E, 0x00
	st_dri3b D, 0xFD, 0x96, 0x00
	lds bc, 4
	ldirw
	st_dri3b D, 0xFD, 0x8E, 0x00
	st_dri3b W, 0xFD, 0x9E, 0x00
	ld bc, (xwa)
	ld (xix), bc
	st_dri3b E, 0xFD, 0x8A, 0x00
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
	st_dri3w BC, 0xFD, 0x98, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	call GetBoxCenter
	st_dri3b W, 0xFD, 0x96, 0x00
	st_dri3b A, 0xFD, 0x86, 0x00
	call GetBoxCenter
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	inc 1, wa
	pushw wa
	pushw 0xEA
	pushw 0xA824
	lda xwa, (xsp + 124)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 24)
	cpw (xwa + 22), 0x8
	jrl nc, PsTrkSw_Confirm_Track8Plus
	cpw (xbc), 0x0
	jr z, PsTrkSw_Confirm_DrawOff
	st_dri3b W, 0xFD, 0xA6, 0x00
	ldw bc, 0xCB
	lds de, 0
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x8E, 0x00
	st_dri3b A, 0xFD, 0x8A, 0x00
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x9E, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x7
	pushw 0xF7
	call DrawStringCentered
	st_dri3b W, 0xFD, 0x96, 0x00
	lds bc, 7
	call DrawBox
	jrl PsTrkSw_Confirm_DrawSecondary

PsTrkSw_Confirm_DrawOff:
	st_dri3b W, 0xFD, 0xA6, 0x00
	ldw bc, 0xCB
	lds de, 7
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x8E, 0x00
	st_dri3b A, 0xFD, 0x8A, 0x00
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x9E, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8Plus:
	cpw (xbc), 0x0
	jr z, PsTrkSw_Confirm_Track8PlusOff
	st_dri3b W, 0xFD, 0xA6, 0x00
	ldw bc, 0xCC
	lds de, 7
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x8E, 0x00
	st_dri3b A, 0xFD, 0x8A, 0x00
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x9E, 0x00
	lds bc, 0
	call DrawBox
	st_dri3b W, 0xFD, 0x9E, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x7
	pushw 0xF7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8PlusOff:
	st_dri3b W, 0xFD, 0xA6, 0x00
	ldw bc, 0xCC
	lds de, 7
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x8E, 0x00
	st_dri3b A, 0xFD, 0x8A, 0x00
	lds de, 0
	call DrawLine
	st_dri3b W, 0xFD, 0x9E, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7

PsTrkSw_Confirm_DrawMark:
	call DrawStringCentered

PsTrkSw_Confirm_DrawSecondary:
	st_dri3b W, 0xFD, 0x96, 0x00
	st_dri3b A, 0xFD, 0x86, 0x00
	ld xde, (xsp + 4)
	ld xde, (xde + 28)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 38)
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	jrl PsTrkSw_DrawAndReturn

PsTrkSw_Select:
	ld_sril XWA, (xsp + 0x00b2)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x00ae)
	cp bc, 0xFFFF
	jr z, PsTrkSw_Select_CalcPos
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 32)
	ld (xwa), bc

PsTrkSw_Select_CalcPos:
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 22)
	st_dri3b W, 0xFD, 0xA8, 0x00
	cpw (xbc), 0x8
	jr nc, PsTrkSw_Select_SetE3
	ldw (xwa), 0x96
	jr PsTrkSw_Select_DrawBox

PsTrkSw_Select_SetE3:
	ldw (xwa), 0xE3

PsTrkSw_Select_DrawBox:
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld bc, (xbc)
	and bc, 0x7
	mul bc, 0x28
	inc 2, bc
	ld (xwa), bc
	add bc, 0x23
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0xB
	ld (xwa + 6), bc
	st_dri3b A, 0xFD, 0x92, 0x00
	call GetBoxCenter
	st_dri3b W, 0xFD, 0xA6, 0x00
	ld xbc, (xsp + 4)
	ld xbc, (xbc + 32)
	ld bc, (xbc)
	sla bc, 1
	lda xde, (xsp + 8)
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
	call DrawBox
	st_dri3b W, 0xFD, 0xA6, 0x00
	st_dri3b A, 0xFD, 0x92, 0x00
	ld xde, (xsp + 4)
	ld xde, (xde + 32)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 18)
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7

PsTrkSw_DrawAndReturn:
	call DrawStringCentered
	jrl PsTrkSw_ReturnZero

PsTrkSw_HitTest:
	ld_sril XWA, (xsp + 0x00b2)
	call GetViewInstance
	lda xwa, (xhl + 22)
	cpw (xwa), 0x8
	jr nc, PsTrkSw_HitTest_Track8Plus
	ld wa, (xwa)
	extz xwa
	cp_sril_rm XWA, 0xFD, 0xAE, 0x00
	jrl nz, PsTrkSw_ReturnZero
	jr PsTrkSw_HitTest_Match

PsTrkSw_HitTest_Track8Plus:
	ld wa, (xwa)
	add wa, 0x78
	extz xwa
	cp_sril_rm XWA, 0xFD, 0xAE, 0x00
	jrl nz, PsTrkSw_ReturnZero

PsTrkSw_HitTest_Match:
	lds32 xhl, 1

PsTrkSw_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0xB2, 0x00
	ret

PsTrkSw_TrailingData:
	.byte 0xef, 0x68, 0x3e, 0xe8, 0x8e, 0xee, 0x88, 0x1d
	.byte 0x66, 0x62, 0xfa, 0xbb, 0x16, 0x32, 0xbf, 0x04
	.byte 0x31, 0xb9, 0x02, 0x30, 0x92, 0x3f, 0x08, 0x00
	.byte 0x6f, 0x06, 0xb0, 0x02, 0xa4, 0x00, 0x68, 0x04
	.byte 0xb0, 0x02, 0xc4, 0x00, 0x92, 0x20, 0xd8, 0xcc
	.byte 0x07, 0x00, 0xd8, 0x08, 0x28, 0x00, 0xd8, 0x64
	.byte 0xb1, 0x50, 0xd8, 0xc8, 0x1f, 0x00, 0xb9, 0x04
	.byte 0x50, 0x99, 0x02, 0x20, 0xd8, 0xc8, 0x1c, 0x00
	.byte 0xb9, 0x06, 0x50, 0xee, 0x88, 0x1d, 0xa7, 0x62
	.byte 0xfa, 0x5e, 0xef, 0x60, 0x0e

AcTrackSwitchProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C0002E
	jrl z, LABEL_FA3B1E
	cp xiz, 0x1C0002D
	jrl z, LABEL_FA3AD3
	cp xiz, 0x1C00007
	jr z, LABEL_FA3A95
	cp xiz, 0x1C0000C
	jr z, LABEL_FA3A72
	cp xiz, 0x1C0000B
	jr z, LABEL_FA3A72
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr LABEL_FA3ACD

LABEL_FA3A72:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld de, (xhl + 22)
	extz xde
	ld xwa, 0x140000A
	ld xbc, 0x1E00092
	jr LABEL_FA3ABE

LABEL_FA3A95:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA3AC5
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld de, (xhl + 22)
	extz xde
	ld xwa, 0x140000A
	ld xbc, 0x1E00093

LABEL_FA3ABE:
	call MainFuncCall
	jrl PsTextBox_ZeroReturn

LABEL_FA3AC5:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

LABEL_FA3ACD:
	calr PsTrackSwitchProc
	jrl LABEL_FA3B59

LABEL_FA3AD3:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xsp + 4)
	srl xwa, 0
	and xwa, 0xFFF
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	and xwa, 0xFF
	ld bc, wa
	extz xbc
	ld xwa, (xsp + 4)
	srl wa, 8
	ldb w, 0x0
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	jr LABEL_FA3B53

LABEL_FA3B1E:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xsp + 4)
	srl xwa, 0
	and xwa, 0xFFF
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	ldi_werp 0xE2, 0
	ld de, wa
	exts xde
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000E

LABEL_FA3B53:
	call SendEvent

PsTextBox_ZeroReturn:
	lds32 xhl, 0

LABEL_FA3B59:
	pop xiz
	inc 8, xsp
	ret

PsTextBoxProc:
	lda xsp, (xsp - 40)
	push xiz
	ld (xsp + 40), xde
	ld xiz, xwa
	cp xbc, 0x1E00089
	jrl z, LABEL_FA3D0A
	cp xbc, 0x1C0000F
	jr z, LABEL_FA3B82
	ld xwa, xiz
	ld xde, (xsp + 40)
	calr VwBoxProc
	jrl LABEL_FA3D0F

LABEL_FA3B82:
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
	jr nz, LABEL_FA3BC1
	ld xwa, xiz
	ld xbc, 0x1E00089
	lds32 xde, 0
	call SendEvent
	ld (xsp + 16), xhl
	cp (xhl), 0x0
	jr nz, LABEL_FA3BC7
	jrl LABEL_FA3D06

LABEL_FA3BC1:
	ld xwa, (xsp + 40)
	ld (xsp + 16), xwa

LABEL_FA3BC7:
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
	div xde, xbc
	ld (xsp + 8), de
	ldw (xsp + 18), 0x0
	cps bc, 0
	jrl ule, LABEL_FA3CFC

LABEL_FA3C46:
	pushw 0xEA
	pushw 0xA828
	ld xwa, (xsp + 14)
	push xwa
	call StrSearch_Init
	inc 8, xsp
	ld xwa, (xsp + 10)
	st_dri3b W, 0x07, 0xE0, 0xEC
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
	jr z, LABEL_FA3CA3
	ld xwa, (xsp + 14)
	ld (xwa), 0xD
	ld xwa, (xsp + 10)
	st_dri3b W, 0x07, 0xE0, 0xF8
	ld (xsp + 14), xwa
	stib_dpd 0xE0, 0x00
	ld (xsp + 14), xwa

LABEL_FA3CA3:
	ld wa, (xsp + 8)
	mrdw3 0x9F, 0x12, 0x40
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
	pushm (xhl + 32)
	pushw 0xF7
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
	jr z, LABEL_FA3CFC
	incm 1, (xsp + 18)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 18)
	cp bc, (xwa + 36)
	jrl c, LABEL_FA3C46

LABEL_FA3CFC:
	ld xwa, (xsp + 24)
	push xwa
	call Free
	inc 4, xsp

LABEL_FA3D06:
	lds32 xhl, 0
	jr LABEL_FA3D0F

LABEL_FA3D0A:
	lda_24 xhl, 0xeaa82a

LABEL_FA3D0F:
	pop xiz
	lda xsp, (xsp + 40)
	ret

AcLanguageTextProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00089
	jr z, LABEL_FA3D65
	cp xbc, 0x1C0000D
	jr z, LABEL_FA3D2E
	ld xwa, xiz
	calr PsTextBoxProc
	jr LABEL_FA3D6A

LABEL_FA3D2E:
	ld xwa, xiz
	calr PsTextBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld xbc, 0x1E0009F
	lds32 xde, 0
	call ApFuncCall
	ld8_24 a, 0x0340e4
	extz wa
	sla wa, 2
	ld_sril3 XDE, 0x07, 0xEC, 0xE0
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	lds32 xhl, 0
	jr LABEL_FA3D6A

LABEL_FA3D65:
	lda_24 xhl, 0xeaa834

LABEL_FA3D6A:
	pop xiz
	ret

LanguageCheck:
	cp xbc, 0x1E0009F
	jr nz, ObjectProc_ClassDispatch
	lda_24 xhl, 0xeaa844
	ret

; ObjectProc class dispatch with dual handler
ObjectProc_ClassDispatch:
	lds32 xhl, 0
	ret

TrTransposeBoxProc:
	jp LABEL_FC2EC3

TrChordBoxProc:
	jp LABEL_FC2FBB

ObjectProc:
	st_dri3b L, 0xFD, 0x70, 0xFF
	push xiz
	st_dri3l XDE, 0xFD, 0x88, 0x00
	st_dri3l XBC, 0xFD, 0x8C, 0x00
	st_dri3l XWA, 0xFD, 0x90, 0x00
	ld_sril XWA, (xsp + 0x0090)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027ed6
	add xwa, xbc
	ld xix, (xwa)
	ld_sril XWA, (xsp + 0x0090)
	ld xbc, 0x1E00000
	lds32 xde, 0
	call (xix)
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x008c)
	sub xwa, 0x1E00010
	cp xwa, 0x0
	jrl lt, LABEL_FA409A
	cp xwa, 0x13
	jrl gt, LABEL_FA409A
	add xwa, xwa
	add xwa, 0xEAA8A4
	ld wa, (xwa)
	lda_24 xix, 0xfa3dfd
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_FA3DFD:
	.byte 0xee, 0x8b, 0x78, 0xaa, 0x02, 0xee, 0x88, 0x41
	.byte 0x01, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x78, 0x55, 0x02, 0xee, 0x88, 0x41, 0x02
	.byte 0x00, 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x78, 0x46, 0x02, 0xee, 0x88, 0x41, 0x03, 0x00
	.byte 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x78
	.byte 0x37, 0x02, 0xee, 0x88, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01
	ld	xde, (xsp+136)
	.byte 0x78, 0x28
	.byte 0x02, 0xee, 0x88, 0x41, 0x04, 0x00, 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x78, 0x19, 0x02
	ld	xwa, (xsp+136)
	.byte 0xb0, 0x00, 0x00
	.byte 0xee, 0x88, 0x41, 0x05, 0x00, 0xe0, 0x01, 0xe3
	.byte 0xfd, 0x88, 0x00, 0x22, 0x1e, 0x7e, 0x06, 0xbf
	.byte 0x04, 0x63
	ld	xwa, (xsp+144)
	.byte 0x41
	.byte 0x14, 0x00, 0xe0, 0x01, 0x42, 0x10, 0x00, 0x60
	.byte 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xeb, 0xe3, 0x66
	.long Data_DiskFuncPtrTbl_EA0B12
	.byte 0x0b, 0x90, 0xa8, 0xe3
	.byte 0xfd, 0x8c, 0x00, 0x20, 0x38, 0x1d, 0xc1, 0x0d
	.byte 0xff, 0xef, 0x60, 0xaf, 0x04, 0x23, 0x78, 0x16
	.byte 0x02, 0xee, 0x88, 0x41, 0x06, 0x00, 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x78, 0xc1, 0x01
	.byte 0xbf, 0x08, 0x32
	ld	xwa, (xsp+144)
	.byte 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x08, 0x31, 0xe9, 0x8b, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x20, 0xa0, 0x83, 0xb8, 0x04, 0x32
	.byte 0x83, 0x3f, 0x59, 0x6e, 0x0b, 0x0b, 0xea, 0x00
	.byte 0x0b, 0x94, 0xa8, 0xa2, 0x20, 0x38, 0x68, 0x15
	ld	xwa, (xsp+136)
	.byte 0xa0, 0x81, 0xa2
	.byte 0x20, 0x81, 0x3f, 0x5a, 0x6e, 0x10, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x9a, 0xa8, 0x38, 0x1d, 0x4d, 0x0f
	.byte 0xff, 0xef, 0x60, 0x78, 0xa3, 0x01, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xa2, 0xa8, 0x38, 0x1d, 0x4d, 0x0f
	.byte 0xff, 0xef, 0x60, 0xee, 0x88, 0x41, 0x07, 0x00
	.byte 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x78
	.byte 0x57, 0x01, 0xbf, 0x08, 0x32, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x60, 0x96, 0xfa
	ld	xwa, (xsp+136)
	.byte 0x98, 0x08, 0x21, 0xe9, 0x12, 0xbf, 0x08, 0x30
	.byte 0xe9, 0x80, 0x80, 0x21, 0xc9, 0xca, 0x41, 0x20
	.byte 0x00, 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60
	.byte 0x02, 0x41, 0x08, 0x00, 0xe0, 0x01, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x22, 0x78, 0xb8, 0x00, 0xbf, 0x08
	.byte 0x32
	ld	xwa, (xsp+144)
	.byte 0x41, 0x19
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xe3
	.byte 0xfd, 0x90, 0x00, 0x21, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x20, 0xb8, 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0
	.byte 0x81, 0x81, 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00
	.byte 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02
	.byte 0x41, 0x09, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88
	.byte 0x00, 0x22, 0x68, 0x7a, 0xbf, 0x08, 0x32, 0xe3
	.byte 0xfd, 0x90, 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0
	.byte 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x21
	ld	xwa, (xsp+136)
	.byte 0xb8
	.byte 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0, 0x81, 0x81
	.byte 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00, 0xe8, 0x12
	.byte 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02, 0x41, 0x0a
	.byte 0x00, 0xe0, 0x01
	ld	xde, (xsp+136)
	.byte 0x68, 0x3c, 0xbf, 0x08, 0x32, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x60, 0x96, 0xfa
	ld	xbc, (xsp+144)
	ld	xwa, (xsp+136)
	.byte 0xb8, 0x08, 0x61
	.byte 0xbf, 0x08, 0x31, 0xa0, 0x81, 0x81, 0x21, 0xc9
	.byte 0xca, 0x41, 0x20, 0x00, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x00, 0x00, 0x60, 0x02, 0x41, 0x0b, 0x00, 0xe0
	.byte 0x01
	ld	xde, (xsp+136)
	.byte 0x1d, 0x60
	.byte 0x96, 0xfa, 0x78, 0x8c, 0x00, 0xbf, 0x08, 0x32
	ld	xwa, (xsp+144)
	.byte 0x41, 0x19, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xe3, 0xfd
	.byte 0x90, 0x00, 0x21
	ld	xwa, (xsp+136)
	.byte 0xb8, 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0, 0x81
	.byte 0x81, 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00, 0xe8
	.byte 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02, 0x41
	.byte 0x0c, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x1d, 0x60, 0x96, 0xfa, 0x68, 0x60, 0xee
	.byte 0x88, 0x41, 0x0d, 0x00, 0xe0, 0x01, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x22, 0x68, 0x0c, 0xee, 0x88, 0x41
	.byte 0x0e, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x1e, 0x79, 0x04, 0x68, 0x41, 0xbf, 0x08
	.byte 0x32
	ld	xwa, (xsp+144)
	.byte 0x41, 0x19
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xbf
	.byte 0x08, 0x30
	add	xwa, (xsp+136)
	.byte 0xeb
	.byte 0xa8, 0x80, 0x27, 0x68, 0x22, 0xe3, 0xfd, 0x88
	.byte 0x00, 0x20, 0x38, 0x1d, 0xf2, 0x0a, 0xff, 0xef
	.byte 0x64, 0xeb, 0xa8, 0x68, 0x12

LABEL_FA409A:
	ld_sril XWA, (xsp + 0x0090)
	ld_sril XBC, (xsp + 0x008c)
	ld_sril XDE, (xsp + 0x0088)
	calr InheritedProc
	pop xiz
	st_dri3b L, 0xFD, 0x90, 0x00
	ret

InitializeObjectTable:
	lda xsp, (xsp - 14)
	pushw iz
	sti16_24 0x02bc12, 0x0000
	lda_24 xwa, 0x027ed2
	lda xbc, (xwa + 10)
	lda xde, (xwa + 8)
	lda xhl, (xwa + 4)
	ld xix, xwa
	st_dri3b E, 0xE1, 0x40, 0x3D

LABEL_FA40D3:
	ld xwa, 0xFFFFFFFF
	ld (xix), xwa
	lds32 xwa, 0
	ld (xhl), xwa
	ldw (xde), 0x0
	ld (xbc), xwa
	lda xix, (xix + 14)
	lda xhl, (xhl + 14)
	lda xde, (xde + 14)
	lda xbc, (xbc + 14)
	cp xix, xiy
	jr c, LABEL_FA40D3
	lda_24 xbc, 0x0328fc
	ld xwa, xbc
	st_dri3b B, 0xE5, 0xC0, 0x01

LABEL_FA4100:
	ld xiy, 0xEAA8CC
	ld xix, xwa
	lds bc, 7
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, LABEL_FA4100
	lda_24 xbc, 0x032abc
	ld xwa, xbc
	st_dri3b B, 0xE5, 0x00, 0x16

LABEL_FA411E:
	ld xiy, 0xEAA8DC
	ld xix, xwa
	ldw bc, 0xB
	ldirw
	lda xwa, (xwa + 22)
	cp xwa, xde
	jr c, LABEL_FA411E
	lda xbc, (xsp + 2)
	ld xwa, 0x1600005
	ld (xbc), xwa
	lda_24 xwa, 0xfa4836
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x37
	lda_24 xwa, 0xeb7690
	ld (xbc + 10), xwa
	ldw wa, 0x260
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, 0x1600006
	ld (xbc), xwa
	lda_24 xwa, 0xfa4a6d
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x20
	lda_24 xwa, 0x0328fc
	ld (xbc + 10), xwa
	ldw wa, 0x180
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, 0x1600007
	ld (xbc), xwa
	lda_24 xwa, 0xfa4e03
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x100
	lda_24 xwa, 0x032abc
	ld (xbc + 10), xwa
	ldw wa, 0x1A0
	calr RegisterObjectTable
	lds iz, 0

LABEL_FA41A2:
	lda xbc, (xsp + 2)
	ld xwa, 0x1600010
	ld (xbc), xwa
	lda_24 xwa, 0xfa5995
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x0
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xde, 0x276D2
	add xde, xwa
	ld (xbc + 10), xde
	ld wa, iz
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xde, 0x27AD2
	add xde, xwa
	ld (xbc + 10), xde
	ld wa, iz
	add wa, 0x300
	calr RegisterObjectTable
	inc 1, iz
	cp iz, 0x100
	jr c, LABEL_FA41A2
	lds32 xwa, 0
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
	lds iz, 0
	ldfr_werp WA, 0xFA
	cp wa, (xsp + 8)
	jr ugt, LABEL_FA42BE
	lda_24 xwa, 0x027ed2
	ld (xsp + 4), xwa
	ldto_werp WA, 0xFA
	extz xwa
	ld xbc, 0xE
	call Math_MultiplyAccumulate

LABEL_FA42A5:
	ld xwa, (xsp + 4)
	add xwa, xhl
	add iz, (xwa + 8)
	inc1_werp 0xFA
	add xhl, 0xE
	ldto_werp WA, 0xFA
	cp wa, (xsp + 8)
	jr ule, LABEL_FA42A5

LABEL_FA42BE:
	ld hl, iz
	pop xiz
	inc 6, xsp
	ret

CheckViewObject:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, 0x027edc
	add xbc, xde
	ld xbc, (xbc)
	or xbc, xbc
	jr nz, LABEL_FA42EA
	lds hl, 0
	ret

LABEL_FA42EA:
	ldi_werp 0xE2, 0
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
	cp wa, 0x45F
	ret ugt
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	add xde, xde
	ld xix, 0x27ED2
	add xix, xde	; XIX = 27ed2h + 14 * XWA
	ld xiy, xbc
	lds bc, 7
	ldirw
	ret

RegisterObject:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	call GetCurrentTarget
	srl xhl, 0
	and xhl, 0xFFF
	ld de, hl
	ld wa, de
	extz xwa
	ld (xsp + 8), xwa
	sla xwa, 3
	sub xwa, (xsp + 8)
	add xwa, xbc
	ld xbc, xwa
	lda_24 xhl, 0x027ed2
	ld (xsp + 4), xhl
	add xhl, xbc
	ld xiz, (xhl + 10)
	lds iy, 0

LABEL_FA4353:
	ld wa, iy
	extz xwa
	ld (xsp + 12), xwa
	sla xwa, 2
	ld xix, xwa
	ld xbc, xix
	add xbc, xiz
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, LABEL_FA43A1
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
	lda_24 xwa, 0xeaa8f4
	ld (xix), xwa
	incm 1, (xhl + 8)
	ld xhl, (xsp + 8)
	sll xhl, 0
	add xhl, (xsp + 12)
	jr UnRegisterObject_Epilogue

LABEL_FA43A1:
	inc 1, iy
	cp iy, 0x400
	jr c, LABEL_FA4353
	ld xhl, 0xFFFFFFFF

; UnRegisterObject epilogue handler
UnRegisterObject_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

UnRegisterObject:
	push xiz
	srl xwa, 0
	and xwa, 0xFFF
	ld hl, wa
	ld bc, hl
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	lda_24 xix, 0x027ed2
	ld xbc, xix
	add xbc, xwa
	ld xiz, (xbc + 10)
	extz xde
	sll xde, 2
	ld xiy, xde
	add xiy, xiz
	lds32 xwa, 0
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
	lda_24 xwa, 0xeaa8f6
	ld (xde), xwa
	decm 1, (xbc + 8)
	pop xiz
	ret

InheritedProc:
	dec 4, xsp
	push xiz
	ld32_24 xhl, 0x02bc14
	ld (xsp + 4), xhl
	srl xhl, 0
	and xhl, 0xFFF
	ld iz, hl
	ld xhl, (xsp + 4)
	ldi_werp 0xEE, 0
	ld iy, hl
	ld hl, iz
	extz xhl
	ld xiz, xhl
	sll xiz, 3
	sub xiz, xhl
	add xiz, xiz
	lda_24 xix, 0x027ed2
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
	cp xiy, 0xFFFFFFFF
	jr z, LABEL_FA44A4
	st32_24 0x02bc14, xiy
	ld xhl, xiy
	srl xhl, 0
	and xhl, 0xFFF
	ld iz, hl
	ld xhl, xiy
	ldi_werp 0xEE, 0
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
	st32_24 0x02bc14, xbc
	jr RootObject_GetterBlock

LABEL_FA44A4:
	lds32 xwa, 0

; GetRootObject/Event/Param block
RootObject_GetterBlock:
	ld xhl, xwa
	pop xiz
	inc 4, xsp
	ret

GetRootObject:
	ld32_24 xhl, 0x02bc18
	ret

GetRootEvent:
	ld32_24 xhl, 0x02bc1c
	ret

GetRootParam:
	ld32_24 xhl, 0x02bc20
	ret

SetRootObject:
	st32_24 0x02bc18, xwa
	ret

SetRootEvent:
	st32_24 0x02bc1c, xwa
	ret

SetRootParam:
	st32_24 0x02bc20, xwa
	ret

GetFocusObject:
	ld32_24 xhl, 0x02bc24
	ret

GetFocusEvent:
	ld32_24 xhl, 0x02bc28
	ret

GetFocusParam:
	ld32_24 xhl, 0x02bc2c
	ret

ClassProc:
	st_dri3b L, 0xFD, 0xEA, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x12, 0x01
	st_dri3l XBC, 0xFD, 0x16, 0x01
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ld de, bc
	ld xbc, xwa
	ldi_werp 0xE6, 0
	ld (xsp + 8), bc
	ld bc, de
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xiy, 0x027ed2
	ld xbc, xiy
	add xbc, xde
	ld xbc, (xbc + 10)
	ld (xsp + 4), xbc
	ld_sril XIX, (xsp + 0x0116)
	ld (xsp + 14), xix
	st_dri3b B, 0xFD, 0x92, 0x00
	cp xix, 0x1E0000E
	jrl z, LABEL_FA47F0
	cp xix, 0x1E0000D
	jrl z, LABEL_FA47C0
	ld bc, (xsp + 8)
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 3
	add xhl, (xsp + 4)
	cp xix, 0x1E0000F
	jr z, LABEL_FA45AD
	ld xbc, xix
	cp xbc, 0x1E00015
	jr z, ClassProc_Event_LoadFromOffset
	ld xiz, xhl
	inc 4, xhl
	ld xbc, (xsp + 14)
	sub xbc, 0x1E00000
	cp xbc, 0x0
	jrl lt, LABEL_FA4822
	cp xbc, 0x7
	jrl gt, LABEL_FA4822
	add xbc, xbc
	add xbc, 0xEAA8F8
	ld bc, (xbc)
	lda_24 xix, 0xfa4598
	jp_dri 8, 0x07, 0xF0, 0xE4
;-----------------------------------------------------------------------------
; ClassProc_EventHandlers - Dispatch table for UI event types
;
; Jumped to via: JP T, XIX + BC where XIX = 0xFA4598
; BC offset comes from table at 0xEAA8F8 indexed by event type (0-7)
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

LABEL_FA45AD:
	jrl ClassProc_ReturnWithStatus
	ld hl, (xiz + 8)
	extz xhl
	jrl ClassProc_ReturnWithStatus
	ld_sril XBC, (xsp + 0x0112)
	ld xde, xwa
	cp xwa, 0xFFFFFFFF
	jrl z, ClassProc_ReturnZeroJmp

LABEL_FA45C8:
	cp xde, xbc
	jr nz, LABEL_FA45D1
	lds32 xhl, 1
	jrl ClassProc_ReturnWithStatus

LABEL_FA45D1:
	ld xwa, xde
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	ld xwa, xiy
	add xwa, xhl
	ld xwa, (xwa + 10)
	ld (xsp + 4), xwa
	ldi_werp 0xEA, 0
	ld wa, de
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 3
	add xde, (xsp + 4)
	ld xde, (xde + 4)
	cp xde, 0xFFFFFFFF
	jr nz, LABEL_FA45C8
	jrl ClassProc_ReturnZeroJmp
	ld xwa, (xiz + 16)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	lds32 xwa, 0
	ld (xsp + 10), xwa
	jr LABEL_FA463F

LABEL_FA4624:
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E00025
	call SendEvent
	lds32 xwa, 1
	add (xsp + 10), xwa

LABEL_FA463F:
	st_dri3b B, 0xFD, 0x92, 0x00
	ld xwa, xde
	add xwa, (xsp + 10)
	ld a, (xwa)
	cps a, 0
	jr nz, LABEL_FA4624
	ld_sril XWA, (xsp + 0x0112)
	push xwa
	push xde
	call Strcat
	st_dri3b W, 0xFD, 0x9A, 0x00
	push xwa
	ld_sril XWA, (xsp + 0x011e)
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
	cp xbc, 0xFFFFFFFF
	jrl z, ClassProc_ReturnZeroJmp
	ld xwa, xbc
	ld xbc, 0x1E00005
	ld_sril XDE, (xsp + 0x0112)
	calr ClassProc
	jrl ClassProc_ReturnZeroJmp
	ld xbc, 0x1E00019
	call SendEvent
	st_dri3b W, 0xFD, 0x92, 0x00
	push xwa
	call Strlen
	inc 4, xsp
	extz xhl
	jrl ClassProc_ReturnWithStatus
	ld xbc, (xhl)
	cp xbc, 0xFFFFFFFF
	jr z, LABEL_FA46CF
	ld xwa, xbc
	ld xbc, 0x1E00007
	ld_sril XDE, (xsp + 0x0112)
	calr ClassProc

LABEL_FA46CF:
	ld_sril XWA, (xsp + 0x0112)
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
	st_dri3b W, 0xFD, 0x96, 0x00
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xwa, 0
	ld (xsp + 10), xwa
	jr LABEL_FA4720

LABEL_FA4705:
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E00025
	call SendEvent
	lds32 xwa, 1
	add (xsp + 10), xwa

LABEL_FA4720:
	st_dri3b B, 0xFD, 0x92, 0x00
	ld xwa, xde
	add xwa, (xsp + 10)
	ld a, (xwa)
	cps a, 0
	jr nz, LABEL_FA4705
	lds32 xwa, 0
	ld (xsp + 14), xwa
	ld (xsp + 10), xwa
	jr LABEL_FA47AE

LABEL_FA473A:
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
	st_dri3b W, 0xFD, 0x92, 0x00
	add xwa, (xsp + 10)
	ld a, (xwa)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	lda xde, (xsp + 18)
	ld xbc, 0x1E00026
	call SendEvent
	add (xsp + 14), xhl
	ld_sril XBC, (xsp + 0x0112)
	ld xwa, (xbc)
	or xwa, xwa
	jr nz, LABEL_FA47A2
	lda xwa, (xsp + 18)
	push xwa
	ld xwa, (xbc + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	jr ClassProc_ReturnZeroJmp

LABEL_FA47A2:
	lds32 xbc, 1
	add (xsp + 10), xbc
	ld_sril XWA, (xsp + 0x0112)
	sub (xwa), xbc

LABEL_FA47AE:
	st_dri3b W, 0xFD, 0x92, 0x00
	add xwa, (xsp + 10)
	cp (xwa), 0x0
	jrl nz, LABEL_FA473A

ClassProc_ReturnZeroJmp:
	lds32 xhl, 0
	jr ClassProc_ReturnWithStatus

LABEL_FA47C0:
	ld xbc, 0x1E00019
	call SendEvent
	st_dri3b A, 0xFD, 0x92, 0x00
	ld_sril XWA, (xsp + 0x0112)
	add xbc, (xwa)
	ld a, (xbc)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E0000D
	ld_sril XDE, (xsp + 0x0112)
	jr LABEL_FA481C

LABEL_FA47F0:
	ld xbc, 0x1E00019
	call SendEvent
	st_dri3b W, 0xFD, 0x92, 0x00
	add_sril_rm XWA, 0xFD, 0x12, 0x01
	ld a, (xwa)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E0000E
	ld_sril XDE, (xsp + 0x0112)

LABEL_FA481C:
	call SendEvent
	jr ClassProc_ReturnWithStatus

LABEL_FA4822:
	ld_sril XBC, (xsp + 0x0116)
	ld_sril XDE, (xsp + 0x0112)
	calr ObjectProc

ClassProc_ReturnWithStatus:
	pop xiz
	st_dri3b L, 0xFD, 0x16, 0x01
	ret

SupportClassProc:
	push xiz
	ld xix, xwa
	ld xhl, xix
	srl xhl, 0
	and xhl, 0xFFF
	ld iy, hl
	ld xhl, xwa
	ldi_werp 0xEE, 0
	ld iz, hl
	ld hl, iy
	extz xhl
	ld xiy, xhl
	sll xiy, 3
	sub xiy, xhl
	add xiy, xiy
	lda_24 xhl, 0x027edc
	add xhl, xiy
	ld xiy, (xhl)
	extz xiz
	ld xhl, xiz
	add xhl, xhl
	add xhl, xiz
	sll xhl, 2
	add xhl, xiy
	cp xbc, 0x1E00027
	jr z, LABEL_FA488F
	cp xbc, 0x1E0000F
	jr z, SupportClass_PopIzRet
	cp xbc, 0x1E00000
	jr nz, SupportClass_VirtualDispatch
	ld xhl, 0x1600005
	jr SupportClass_PopIzRet

LABEL_FA488F:
	ld hl, (xhl + 6)
	extz xhl
	jr SupportClass_PopIzRet

; SupportClass virtual dispatch with type check
SupportClass_VirtualDispatch:
	cp xix, 0x1600005
	jr z, LABEL_FA48A4
	ld xix, (xhl)
	call (xix)
	jr SupportClass_PopIzRet

LABEL_FA48A4:
	calr ObjectProc

SupportClass_PopIzRet:
	pop xiz
	ret

FunctionProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xde, xwa
	srl xde, 0
	and xde, 0xFFF
	ld hl, de
	ld xde, xwa
	ldi_werp 0xEA, 0
	ld ix, hl
	extz xix
	ld xiz, xix
	sll xiz, 3
	sub xiz, xix
	add xiz, xiz
	lda_24 xiy, 0x027ed2
	ld xix, xiy
	add xix, xiz
	ld xix, (xix + 10)
	extz xde
	sll xde, 2
	cp xbc, 0x1E00015
	jr z, FunctionProc_Dispatch
	ld xhl, xde
	add xhl, xix
	cp xbc, 0x1E0002A
	jr z, LABEL_FA4912
	cp xbc, 0x1E0000F
	jr z, FuncProc_PopIzSkip4Ret
	cp xbc, 0x1E00000
	jr z, LABEL_FA490B
	ld xde, (xsp + 4)
	calr ObjectProc
	jr FuncProc_PopIzSkip4Ret

LABEL_FA490B:
	ld xhl, 0x1600001
	jr FuncProc_PopIzSkip4Ret

LABEL_FA4912:
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
	srl xhl, 0
	and xhl, 0xFFF
	ld ix, hl
	ld xhl, xwa
	ldi_werp 0xEE, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda_24 xhl, 0x027edc
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
	cp xbc, 0x1E00015
	jr z, ApFuncCall_VirtualDispatch
	cp xbc, 0x1E00000
	jrl nz, FunctionProc
	ld xhl, 0x1600002
	ret

; ApFuncCall object ID lookup dispatch
ApFuncCall_VirtualDispatch:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
	ld de, wa
	add bc, 0x300
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	ld xbc, 0x1E00014
	ld xde, 0x1600002
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA4A0F
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	ld xde, xiz
	ldi_werp 0xEA, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	jr LABEL_FA4A11

LABEL_FA4A0F:
	lds32 xhl, 0

LABEL_FA4A11:
	pop xiz
	inc 8, xsp
	ret

DefaultFunction:
	lds32 xhl, 0
	ret

MainFunctionProc:
	cp xbc, 0x1E00015
	jr z, MainFuncCall_DispatchDSP
	cp xbc, 0x1E00000
	jrl nz, FunctionProc
	ld xhl, 0x1600003
	ret

; MainFuncCall DSP variant dispatch
MainFuncCall_DispatchDSP:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
	ld de, wa
	add bc, 0x300
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
	add xwa, xbc
	ld xbc, (xwa)
	extz xde
	sll xde, 2
	add xde, xbc
	ld xhl, (xde)
	ret

MainFuncCall:
	call MainPostEvent
	lds32 xhl, 0
	ret

DefMainFunction:
	lds32 xhl, 0
	ret

ModeProc:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xde
	ld xiz, xbc
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ld de, bc
	ld xbc, xwa
	ldi_werp 0xE6, 0
	ld (xsp + 8), bc
	ld bc, de
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, 0x027edc
	add xbc, xde
	ld xbc, (xbc)
	ld (xsp + 4), xbc
	ld xbc, xiz
	cp xiz, 0x1C00013
	jrl z, LABEL_FA4CE6
	cp xiz, 0x1C00014
	jrl z, LABEL_FA4BA7
	cp xiz, 0x1E00015
	jrl z, LABEL_FA4B80
	cp xiz, 0x1E0000F
	jr z, LABEL_FA4B05
	cp xiz, 0x1E00000
	jr z, LABEL_FA4AFD
	sub xbc, 0x1E0002B
	cp xbc, 0x0
	jrl lt, GetMode_DispatchDSP
	cp xbc, 0x5
	jrl gt, GetMode_DispatchDSP
	add xbc, xbc
	add xbc, 0xEAA908
	ld bc, (xbc)
	lda_24 xix, 0xfa4afd
	jp_dri 8, 0x07, 0xF0, 0xE4

LABEL_FA4AFD:
	ld xhl, 0x1600006
	jrl GetMode_Epilogue10

LABEL_FA4B05:
	ld wa, (xsp + 8)
	extz xwa
	ld xhl, xwa
	sll xhl, 3
	sub xhl, xwa
	add xhl, xhl
	add xhl, (xsp + 4)
	jrl GetMode_Epilogue10
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, 0x1E0002A
	lds32 xde, 0
	call SendEvent
	jrl GetMode_Epilogue10
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc)
	jrl GetMode_Epilogue10
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc + 4)
	jrl GetMode_Epilogue10
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

LABEL_FA4B80:
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xhl, (xbc + 10)
	jrl GetMode_Epilogue10
	ld32_24 xhl, 0x03ef82
	jrl GetMode_Epilogue10
	ld32_24 xhl, 0x03ef86
	jrl GetMode_Epilogue10

LABEL_FA4BA7:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000B0
	lds32 xde, 0
	call SendEvent
	ld32_24 xwa, 0x03ef8a
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA4BEF

LABEL_FA4BCB:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00028
	lds32 xde, 0
	call SendEvent
	ld32_24 xwa, 0x03ef8a
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, LABEL_FA4BCB

LABEL_FA4BEF:
	ld xwa, (xsp + 10)
	ld32_24 xde, 0x03ef82
	lda_24 xbc, 0x027ed2
	cp xwa, xde
	jr nz, LABEL_FA4C15
	ld xwa, 0x1800001
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x1
	ld_sril XWA, (xbc + 0x150a)
	ld (xsp + 4), xwa

LABEL_FA4C15:
	st32_24 0x03ef86, xde
	ld32_24 xwa, 0x03ef8a
	st32_24 0x03ef8e, xwa
	ld wa, (xsp + 8)
	extz xwa
	ld xde, xwa
	sll xde, 3
	sub xde, xwa
	add xde, xde
	add xde, (xsp + 4)
	inc 4, xde
	ld xwa, (xde)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA4C52
	ld xwa, (xsp + 10)
	st32_24 0x03ef82, xwa
	ld xwa, (xde)
	st32_24 0x03ef8a, xwa
	jr LABEL_FA4C66

LABEL_FA4C52:
	ld xwa, 0x1800000
	st32_24 0x03ef82, xwa
	ld xwa, 0x1A00000
	st32_24 0x03ef8a, xwa

LABEL_FA4C66:
	ld32_24 xwa, 0x03ef8a
	ld xde, xwa
	srl xde, 0
	and xde, 0xFFF
	ldi_werp 0xE2, 0
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
	ldw (xhl + 18), 0xFFFF
	ldw (xhl + 20), 0xFFFF
	ld xwa, 0xFFFFFFFF
	ld (xhl + 14), xwa
	ld32_24 xde, 0x03ef82
	ld xwa, 0x1400001
	ld xbc, 0x1C00014
	calr MainFuncCall
	ld32_24 xde, 0x03ef8a
	ld xwa, 0x1400001
	ld xbc, 0x1C00015
	calr MainFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call SendEvent
	jr LABEL_FA4D0E

LABEL_FA4CE6:
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
	ld xwa, 0x1400001
	ld xbc, xiz
	ld xde, (xsp + 10)
	calr MainFuncCall

LABEL_FA4D0E:
	lds32 xhl, 0
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
	ld32_24 xhl, 0x03ef82
	ret

GetModeOld:
	ld32_24 xhl, 0x03ef86
	ret

RegisterMode:
	ld xhl, xwa
	ld xwa, xhl
	sll xwa, 3
	sub xwa, xhl
	add xwa, xwa
	ld xhl, 0x328FC
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
	ld xbc, 0x328FC
	add xbc, xwa
	ld xwa, 0x1200000
	ld (xbc), xwa
	ld xwa, 0xFFFFFFFF
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0xFFFF
	lda_24 xwa, 0xeaa914
	ld (xbc + 10), xwa
	ret

RegisterTitle:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xbc, 0x32ABC
	add xbc, xhl
	ld (xbc), xiz
	ld xwa, (xsp + 4)
	ld (xbc + 4), xwa
	ld wa, (xsp + 16)
	ld (xbc + 8), wa
	ld xwa, (xsp + 12)
	ld (xbc + 10), xwa
	ld xwa, 0xFFFFFFFF
	ld (xbc + 14), xwa
	ldw (xbc + 18), 0xFFFF
	ldw (xbc + 20), 0xFFFF
	pop xiz
	inc 4, xsp
	retd 0x6

UnregisteredTitle:
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xbc, 0x32ABC
	add xbc, xhl
	ld xwa, 0x1200000
	ld (xbc), xwa
	ld xwa, 0xFFFFFFFF
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0xFFFF
	lda_24 xwa, 0xeaa916
	ld (xbc + 10), xwa
	ld xwa, 0xFFFFFFFF
	ld (xbc + 14), xwa
	ldw (xbc + 18), 0xFFFF
	ldw (xbc + 20), 0xFFFF
	ret

TitleProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld xiz, xbc
	ld (xsp + 34), xwa
	ld xwa, (xsp + 34)
	srl xwa, 0
	and xwa, 0xFFF
	ld bc, wa
	ld xwa, (xsp + 34)
	ldi_werp 0xE2, 0
	ld (xsp + 22), wa
	ld wa, (xsp + 22)
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027ed2
	ld (xsp + 14), xwa
	add xwa, xbc
	lda xwa, (xwa + 10)
	ld (xsp + 24), xwa
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld xde, xiz
	ld16_24 xwa, 0x02bc30
	and wa, 0x11
	ld (xsp + 28), wa
	cp xiz, 0x1C00013
	jrl z, LABEL_FA57B1
	cp xiz, 0x1E000B7
	jrl z, LABEL_FA5730
	ld xwa, (xsp + 30)
	sll xwa, 3
	sub xwa, (xsp + 30)
	add xwa, xwa
	ld xbc, 0xEAA918
	add xbc, xwa
	ld xwa, (xbc + 8)
	cp xiz, 0x1E000A6
	jrl z, LABEL_FA56E5
	cp xiz, 0x1E000A5
	jrl z, LABEL_FA56CD
	cp xiz, 0x1E0009E
	jrl z, LABEL_FA56B9
	cp xiz, 0x1E0007A
	jrl z, LABEL_FA569C
	cp xiz, 0x1E0009B
	jrl z, LABEL_FA55F7
	cp xiz, 0x1E0009A
	jrl z, LABEL_FA556A
	cp xiz, 0x1E000AA
	jrl z, LABEL_FA5558
	cp xiz, 0x1E000B3
	jrl z, LABEL_FA54C9
	cp xiz, 0x1E00098
	jrl z, LABEL_FA5496
	cp xiz, 0x1E00079
	jrl z, LABEL_FA542A
	ld16_24 xwa, 0x02bc32
	exts xwa
	ld (xsp + 18), xwa
	ld wa, (xsp + 28)
	ld (xsp + 28), wa
	cp xiz, 0x1E00078
	jrl z, LABEL_FA53EE
	cp xiz, 0x1E00099
	jrl z, LABEL_FA53B6
	cp xiz, 0x1E00077
	jrl z, LABEL_FA539C
	cp xiz, 0x1E00076
	jrl z, LABEL_FA5374
	ld32_24 xwa, 0x03ef8a
	cp xiz, 0x1C00028
	jrl z, LABEL_FA523F
	cp xiz, 0x1C00016
	jrl z, LABEL_FA50B1
	cp xiz, 0x1C00015
	jrl z, LABEL_FA5020
	cp xiz, 0x1E00015
	jrl z, LABEL_FA4FF9
	cp xiz, 0x1E0000F
	jr z, LABEL_FA4F7E
	cp xiz, 0x1E00000
	jr z, TitleProc_EventDispatch
	sub xde, 0x1E00030
	cp xde, 0x0
	jrl lt, LABEL_FA5857
	cp xde, 0x5
	jrl gt, LABEL_FA5857
	add xde, xde
	add xde, 0xEAA9C0
	ld de, (xde)
	lda_24 xix, 0xfa4f76
	jp_dri 8, 0x07, 0xF0, 0xE8

; TitleProc event dispatch
TitleProc_EventDispatch:
	ld xhl, 0x1600007
	jrl TitleFunc_Epilogue34

LABEL_FA4F7E:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	jrl TitleFunc_Epilogue34
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl)
	ld xbc, 0x1E0002A
	lds32 xde, 0
	call SendEvent
	jrl TitleFunc_Epilogue34
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl)
	jrl TitleFunc_Epilogue34
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl + 4)
	jrl TitleFunc_Epilogue34
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld hl, (xhl + 8)
	exts xhl
	jrl TitleFunc_Epilogue34

LABEL_FA4FF9:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xhl, (xhl + 10)
	jrl TitleFunc_Epilogue34
	ld32_24 xhl, 0x03ef8a
	jrl TitleFunc_Epilogue34
	ld32_24 xhl, 0x03ef8e
	jrl TitleFunc_Epilogue34

LABEL_FA5020:
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, LABEL_FA5053

LABEL_FA502F:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00028
	lds32 xde, 0
	call SendEvent
	ld32_24 xwa, 0x03ef8a
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, LABEL_FA502F

LABEL_FA5053:
	ld32_24 xwa, 0x03ef8a
	st32_24 0x03ef8e, xwa
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA5083
	ld xwa, (xsp + 30)
	st32_24 0x03ef8a, xwa
	jr LABEL_FA508D

LABEL_FA5083:
	ld xwa, 0x1A00000
	st32_24 0x03ef8a, xwa

LABEL_FA508D:
	ldw (xhl + 18), 0xFFFF
	ldw (xhl + 20), 0xFFFF
	ld xwa, 0xFFFFFFFF
	ld (xhl + 14), xwa
	ld32_24 xde, 0x03ef8a
	ld xwa, 0x1400001
	ld xbc, 0x1C00015
	jrl LABEL_FA5696

LABEL_FA50B1:
	ld iz, (xsp + 12)
	extz xiz
	ld xwa, xiz
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, xiz
	cpw (xhl + 18), 0xFFFF
	jrl z, LABEL_FA518C
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld wa, (xhl + 18)
	exts xwa
	add xwa, 0x1A00000
	ld (xsp + 8), xwa
	ld wa, (xhl + 20)
	exts xwa
	add xwa, 0x1A00000
	ld (xsp + 18), xwa
	ld xwa, (xsp + 8)
	srl xwa, 0
	and xwa, 0xFFF
	ld bc, wa
	ld xwa, (xsp + 8)
	ldi_werp 0xE2, 0
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
	cp xbc, 0xFFFFFFFF
	jr z, LABEL_FA518C
	ld xwa, (xsp + 18)
	srl xwa, 0
	and xwa, 0xFFF
	ld bc, wa
	ld xwa, (xsp + 18)
	ldi_werp 0xE2, 0
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

LABEL_FA518C:
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld32_24 xwa, 0x03ef8a
	st32_24 0x03ef8e, xwa
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA51C4
	ld xwa, (xsp + 30)
	st32_24 0x03ef8a, xwa
	jr LABEL_FA51CE

LABEL_FA51C4:
	ld xwa, 0x1A00000
	st32_24 0x03ef8a, xwa

LABEL_FA51CE:
	ld32_24 xwa, 0x03ef8e
	ld (xhl + 18), wa
	ld32_24 xwa, 0x03ef8e
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
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
	ld32_24 xwa, 0x03ef8a
	ld (xhl + 20), wa
	ld32_24 xde, 0x03ef8a
	ld xwa, 0x1400001
	ld xbc, 0x1C00016
	calr MainFuncCall
	lds wa, 1
	calr SetInterruptTime
	lds wa, 2
	calr TitleProc_SetResourceDirtyFlag
	ldw wa, 0x10
	jrl TitleProc_ClearAndReturn

LABEL_FA523F:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
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
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	lda xbc, (xhl + 18)
	ld wa, (xbc)
	cp wa, 0xFFFF
	jrl z, TitleProc_ReturnZero
	ld32_24 xwa, 0x03ef8a
	st32_24 0x03ef8e, xwa
	ld wa, (xbc)
	exts xwa
	add xwa, 0x1A00000
	st32_24 0x03ef8a, xwa
	ld xde, xwa
	ld xwa, 0x1400001
	ld xbc, 0x1C00028
	calr MainFuncCall
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ldw (xhl + 18), 0xFFFF
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	ld xwa, xhl
	add xwa, (xsp + 4)
	ldw (xwa + 20), 0xFFFF
	add xhl, (xsp + 4)
	ld xwa, 0xFFFFFFFF
	ld (xhl + 14), xwa
	ld32_24 xwa, 0x03ef8a
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
	ld (xsp + 12), wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
	add xwa, xbc
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ldw (xhl + 20), 0xFFFF
	ld16_24 xwa, 0x02bc32
	exts xwa
	ld xbc, 0x1C00028
	push xbc
	lds32 xbc, 0
	push xbc
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call KillApTimer
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jrl nz, TitleProc_ReturnZero
	ldw wa, 0x12
	jrl TitleProc_ClearAndReturn

LABEL_FA5374:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	lda xbc, (xhl + 14)
	ld xwa, (xbc)
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_FA5397
	ld xwa, (xhl + 4)
	ld (xbc), xwa

LABEL_FA5397:
	ld xhl, (xbc)
	jrl TitleFunc_Epilogue34

LABEL_FA539C:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xsp + 30)
	ld (xhl + 14), xwa
	jrl TitleProc_ReturnZero

LABEL_FA53B6:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jrl nz, TitleProc_ReturnZero
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	jrl LABEL_FA56DE

LABEL_FA53EE:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jrl nz, TitleProc_ReturnZero
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	jrl TitleProc_ReturnZero

LABEL_FA542A:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jrl z, TitleProc_ReturnZero
	cpw (xsp + 28), 0x0
	jr nz, LABEL_FA5464
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	jrl TitleProc_ReturnZero

LABEL_FA5464:
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	cps hl, 0
	jrl nz, TitleProc_ReturnZero
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	jrl LABEL_FA56DE

LABEL_FA5496:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jrl z, TitleProc_ReturnZero
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call KillApTimer
	jrl TitleProc_ReturnZero

LABEL_FA54C9:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, LABEL_FA5508
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, LABEL_FA54FF
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call KillApTimer

LABEL_FA54FF:
	ldw wa, 0x10
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

LABEL_FA5508:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, LABEL_FA5552
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	cps hl, 0
	jr nz, LABEL_FA5552
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call SetApTimer

LABEL_FA5552:
	ldw wa, 0x10
	jrl TitleProc_ClearAndReturn

LABEL_FA5558:
	ld16_24 xwa, 0x02bc30
	and wa, 0x1
	cps wa, 0
	scc16 nz, hl
	exts xhl
	jrl TitleFunc_Epilogue34

LABEL_FA556A:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, LABEL_FA55A8
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, LABEL_FA55A0
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call KillApTimer

LABEL_FA55A0:
	lds wa, 1
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

LABEL_FA55A8:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, LABEL_FA55F2
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	cps hl, 0
	jr nz, LABEL_FA55F2
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call SetApTimer

LABEL_FA55F2:
	lds wa, 1
	jrl TitleProc_ClearAndReturn

LABEL_FA55F7:
	ld16_24 xwa, 0x02bc30
	bit 0, wa
	jr z, LABEL_FA564D
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, TitleProc_ToggleFlag
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call ResetApTimer
	cps hl, 0
	jr nz, TitleProc_ToggleFlag
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call SetApTimer
	jr TitleProc_ToggleFlag

LABEL_FA564D:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	jr z, TitleProc_ToggleFlag
	ld xwa, 0x1C00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xFFFFFFFF
	call KillApTimer

TitleProc_ToggleFlag:
	ld16_24 xde, 0x02bc30
	xor de, 0x1
	st16_24 0x02bc30, xde
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1E000BA

LABEL_FA5696:
	calr MainFuncCall
	jrl TitleProc_ReturnZero

LABEL_FA569C:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	cpw (xhl + 18), 0xFFFF
	scc16 nz, hl
	extz xhl
	jrl TitleFunc_Epilogue34

LABEL_FA56B9:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, LABEL_FA56C8
	lds wa, 4
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

LABEL_FA56C8:
	lds wa, 4
	jrl TitleProc_ClearAndReturn

LABEL_FA56CD:
	ld xbc, (xbc)
	ld xde, 0x1E000B7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xFFFFFFFF

LABEL_FA56DE:
	call SetApTimer
	jrl TitleProc_ReturnZero

LABEL_FA56E5:
	ld xbc, (xbc)
	ld xde, 0x1E000B7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xFFFFFFFF
	call KillApTimer
	cps hl, 0
	jrl z, TitleProc_ReturnZero

LABEL_FA56FF:
	ld xwa, (xsp + 30)
	sll xwa, 3
	sub xwa, (xsp + 30)
	add xwa, xwa
	ld xbc, 0xEAA918
	add xbc, xwa
	ld xwa, (xbc + 8)
	ld xbc, (xbc)
	ld xde, 0x1E000B7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xFFFFFFFF
	call KillApTimer
	cps hl, 0
	jr nz, LABEL_FA56FF
	jrl TitleProc_ReturnZero

LABEL_FA5730:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E000B7
	call DeleteEvent
	ld xbc, (xsp + 30)
	sll xbc, 3
	sub xbc, (xsp + 30)
	add xbc, xbc
	lda_24 xwa, 0xeaa91c
	add xwa, xbc
	ld xwa, (xwa)
	cp xwa, 0x1C00015
	jr nz, LABEL_FA5766
	calr GetModeNow
	cp xhl, 0x1800001
	jrl z, TitleProc_ReturnZero

LABEL_FA5766:
	calr GetModeNow
	cp xhl, 0x1800013
	jrl z, TitleProc_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call SendEvent
	ldw wa, 0x20
	calr TitleProc_SetResourceDirtyFlag
	ld xbc, (xsp + 30)
	sll xbc, 3
	sub xbc, (xsp + 30)
	add xbc, xbc
	ld xwa, 0xEAA918
	add xwa, xbc
	ld xbc, (xwa + 4)
	ld xde, (xwa)
	ld xwa, 0xFFFFFFFF
	call SendEvent
	ldw wa, 0x20

TitleProc_ClearAndReturn:
	calr TitleProc_ClearResourceDirtyFlag
	jrl TitleProc_ReturnZero

LABEL_FA57B1:
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x16
	call Math_MultiplyAccumulate
	add xhl, (xsp + 4)
	ld xwa, (xhl)
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr MainFuncCall
	ld xwa, 0x1400001
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr MainFuncCall
	ld xwa, (xsp + 30)
	cp xwa, 0x3
	jr z, LABEL_FA5843
	cp xwa, 0x2
	jr z, LABEL_FA580A
	cp xwa, 0x8
	jr nz, TitleProc_ReturnZero
	ld32_24 xwa, 0x03ef82
	st32_24 0x03ef86, xwa
	ld32_24 xwa, 0x03ef8a
	st32_24 0x03ef8e, xwa
	jr TitleProc_ReturnZero

LABEL_FA580A:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00039
	lds32 xde, 0
	call SendEvent
	ld16_24 xwa, 0x02bc30
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

LABEL_FA5843:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0003A
	lds32 xde, 0
	call SendEvent

TitleProc_ReturnZero:
	lds32 xhl, 0
	jr TitleFunc_Epilogue34

LABEL_FA5857:
	ld xwa, (xsp + 34)
	ld xbc, xiz
	ld xde, (xsp + 30)
	calr ObjectProc

TitleFunc_Epilogue34:
	pop xiz
	lda xsp, (xsp + 34)
	ret

GetTitleNow:
	ld32_24 xhl, 0x03ef8a
	ret

GetTitleOld:
	ld32_24 xhl, 0x03ef8e
	ret

SetInterruptTime:
	pushw iz
	ld iz, wa
	ld16_24 xwa, 0x02bc30
	bit 1, wa
	jr z, LABEL_FA5889
	cps iz, 2
	jr nz, LABEL_FA5889
	lds wa, 1
	calr TitleProc_SetResourceDirtyFlag

LABEL_FA5889:
	ld wa, iz
	extz xwa
	add xwa, xwa
	ld xbc, 0xEAA9CC
	add xbc, xwa
	ld wa, (xbc)
	st16_24 0x02bc32, xwa
	popw iz
	ret

CheckNotDrawFlag:
	ld16_24 xwa, 0x02bc30
	and wa, 0x4
	cps wa, 0
	scc16 z, hl
	ret

SetVariFlag:
	cps wa, 0
	jr z, LABEL_FA58B6
	ldw wa, 0x8
	jr TitleProc_SetResourceDirtyFlag

LABEL_FA58B6:
	ldw wa, 0x8
	jr TitleProc_ClearResourceDirtyFlag

SetNotDrawFlag:
	cps wa, 0
	jr z, LABEL_FA58C3
	lds wa, 4
	jr TitleProc_SetResourceDirtyFlag

LABEL_FA58C3:
	lds wa, 4
	jr TitleProc_ClearResourceDirtyFlag

TitleProc_SetResourceDirtyFlag:
	ordm16_24 179248, xwa
	ld16_24 xde, 0x02bc30
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1E000BA
	jrl MainFuncCall

TitleProc_ClearResourceDirtyFlag:
	cpl wa
	anddm16_24 179248, xwa
	ld16_24 xde, 0x02bc30
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1E000BA
	jrl MainFuncCall

ResEventProc:
	ld xhl, xwa
	srl xhl, 0
	and xhl, 0xFFF
	ld ix, hl
	ld xhl, xwa
	ldi_werp 0xEE, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda_24 xhl, 0x027edc
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, 0x1E00015
	jr z, LABEL_FA593C
	cp xbc, 0x1E00000
	jrl nz, ObjectProc
	ld xhl, 0x160000C
	ret

LABEL_FA593C:
	ld wa, iy
	extz xwa
	sll xwa, 2
	add xwa, xhl
	ld xhl, (xwa)
	ret

ResMethodProc:
	ld xhl, xwa
	srl xhl, 0
	and xhl, 0xFFF
	ld ix, hl
	ld xhl, xwa
	ldi_werp 0xEE, 0
	ld iy, hl
	ld hl, ix
	extz xhl
	ld xix, xhl
	sll xix, 3
	sub xix, xhl
	add xix, xix
	lda_24 xhl, 0x027edc
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, 0x1E00015
	jr z, ViewableProc_VirtualDispatch
	cp xbc, 0x1E00000
	jrl nz, ObjectProc
	ld xhl, 0x160000D
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
	cp xiy, 0x1E00052
	jrl z, Viewable_GetBoundsY
	cp xiy, 0x1E0004F
	jrl z, Viewable_GetBoundsX
	cp xiy, 0x1E000B5
	jrl z, Viewable_MatchClass
	cp xiy, 0x1E00024
	jrl z, Viewable_Dispatch
	cp xiy, 0x1E0009C
	jrl z, Viewable_SetVisible
	cp xiy, 0x1E00039
	jrl z, Viewable_GetClass
	cp xiy, 0x1E00038
	jrl z, Viewable_GetChild
	cp xiy, 0x1E00037
	jrl z, Viewable_GetOwner
	cp xiy, 0x1E00036
	jrl z, Viewable_GetParent
	cp xiy, 0x1E0000F
	jrl z, Viewable_GetInstance
	ld xwa, xiz
	lda_24 xde, 0x027ed2
	ld xbc, xiz
	ldi_werp 0xE6, 0
	ld (xsp + 10), bc
	srl xwa, 0
	and xwa, 0xFFF
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
	cp xiy, 0x1E00016
	jrl z, Viewable_SetName
	ld hl, (xsp + 10)
	extz xhl
	sll xhl, 2
	ld xwa, xiy
	cp xwa, 0x1E00015
	jrl z, Viewable_GetName
	cp xwa, 0x1C00037
	jrl z, Viewable_PostEvent
	cp xwa, 0x1C00002
	jr z, Viewable_InitClose
	cp xwa, 0x1C00001
	jr z, Viewable_InitClose
	cp xwa, 0x1E00000
	jr z, Viewable_GetClassProc
	ld xwa, (xsp + 6)
	sub xwa, 0x1C0000B
	cp xwa, 0x0
	jrl lt, Viewable_DefaultDispatch
	cp xwa, 0x6
	jrl gt, Viewable_DefaultDispatch
	add xwa, xwa
	add xwa, 0xEAA9E6
	ld wa, (xwa)
	lda_24 xix, 0xfa5aa3
	jp_dri 8, 0x07, 0xF0, 0xE0

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
	cp xwa, 0xFFFFFFFF
	jr z, Viewable_InitClose_ToChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent

Viewable_InitClose_ToChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr Viewable_Show_DispatchTail
	ld xwa, xiz
	calr GetVisible
	cps hl, 0
	jr z, Viewable_Show_DispatchChild
	ld xwa, xiz
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr z, Viewable_Show_DispatchChild
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	call SendEvent

Viewable_Show_DispatchChild:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr z, Viewable_ReturnZero
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	jr Viewable_Show_DispatchTail
	ld xwa, xiz
	calr GetVisible
	cps hl, 0
	jr z, Viewable_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr z, Viewable_ReturnZero
	ld xbc, 0x1C0000B
	ld xde, (xsp + 16)

Viewable_Show_DispatchTail:
	call SendEvent

Viewable_ReturnZero:
	lds32 xhl, 0
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
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
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
	ld xbc, 0x1E00014
	ld xde, (xsp + 16)
	call SendEvent
	or xhl, xhl
	jr nz, Viewable_MatchClass_Found
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
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
	lds32 xhl, 1
	jrl Viewable_Return

Viewable_MatchClass_ToOwner:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
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
	ldw (xix), 0x9C
	lda xiz, (xiy + 2)
	ld wa, (xiz)
	sub wa, 0xD
	ld (xde), wa
	ld wa, (xiz)
	add wa, 0xC
	ld (xhl), wa

Viewable_GetBoundsX_Right:
	cpw (xiy), 0x13F
	jrl nz, Viewable_ReturnZero
	ldw (xbc), 0xA3
	ldw (xix), 0x137
	lda xbc, (xiy + 2)
	ld wa, (xbc)
	sub wa, 0xD
	ld (xde), wa
	ld wa, (xbc)
	add wa, 0xC
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
	cpw (xiy), 0x13F
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
	cpw (xiy + 2), 0xEF
	jrl nz, Viewable_ReturnZero
	ldw (xde), 0xD8
	ldw (xhl), 0xEE
	ld wa, (xiy)
	sub wa, 0x10
	ld (xbc), wa
	ld wa, (xiy)
	add wa, 0xF
	ld (xix), wa
	jrl Viewable_ReturnZero

Viewable_DefaultDispatch:
	ld xwa, (xsp + 20)
	srl xwa, 0
	and xwa, 0xFFF
	cp wa, 0x1E0
	jr c, Viewable_Default_ToOwner
	cp wa, 0x1FF
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
	cp xwa, 0xFFFFFFFF
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
	cp xwa, 0xFFFFFFFF
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
	cps iz, 0
	jr z, LABEL_FA5E4F
	ormi16 (xwa), 0x4
	jr LABEL_FA5E53

LABEL_FA5E4F:
	andmi16 (xwa), 0xFFFB

LABEL_FA5E53:
	popw iz
	ret

GetChange:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x4
	cps wa, 0
	scc16 nz, hl
	ret

SetConst:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
	jr z, LABEL_FA5E77
	ormi16 (xwa), 0x8
	jr LABEL_FA5E7B

LABEL_FA5E77:
	andmi16 (xwa), 0xFFF7

LABEL_FA5E7B:
	popw iz
	ret

GetConst:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x8
	cps wa, 0
	scc16 nz, hl
	ret

SetVisible:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
	jr z, LABEL_FA5E9F
	andmi16 (xwa), 0xFFFE
	jr LABEL_FA5EA3

LABEL_FA5E9F:
	ormi16 (xwa), 0x1

LABEL_FA5EA3:
	popw iz
	ret

GetVisible:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x1
	cps wa, 0
	scc16 z, hl
	ret

SetMovable:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
	jr z, LABEL_FA5EC7
	andmi16 (xwa), 0xFFFD
	jr LABEL_FA5ECB

LABEL_FA5EC7:
	ormi16 (xwa), 0x2

LABEL_FA5ECB:
	popw iz
	ret

GetMovable:
	calr GetViewInstance
	ld wa, (xhl + 12)
	and wa, 0x2
	cps wa, 0
	scc16 z, hl
	ret

NextView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 8)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA5F07
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA5F0C

LABEL_FA5F07:
	ld xhl, 0xFFFFFFFF

LABEL_FA5F0C:
	pop xiz
	ret

View_GetNextSibling:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 8)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA5F39
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA5F3E

LABEL_FA5F39:
	ld xhl, 0xFFFFFFFF

LABEL_FA5F3E:
	pop xiz
	ret

PrevView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 10)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA5F6B
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA5F70

LABEL_FA5F6B:
	ld xhl, 0xFFFFFFFF

LABEL_FA5F70:
	pop xiz
	ret

View_ResolveInstanceAddr:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 10)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA5F9D
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA5FA2

LABEL_FA5F9D:
	ld xhl, 0xFFFFFFFF

LABEL_FA5FA2:
	pop xiz
	ret

SuperView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 4)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA5FCF
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA5FD4

LABEL_FA5FCF:
	ld xhl, 0xFFFFFFFF

LABEL_FA5FD4:
	pop xiz
	ret

View_GetParentOffset:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 4)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA6001
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA6006

LABEL_FA6001:
	ld xhl, 0xFFFFFFFF

LABEL_FA6006:
	pop xiz
	ret

SubView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 6)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA6033
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA6038

LABEL_FA6033:
	ld xhl, 0xFFFFFFFF

LABEL_FA6038:
	pop xiz
	ret

View_GetSuperViewInstance:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr GetViewInstance
	lda xwa, (xhl + 6)
	cpw (xwa), 0xFFFF
	jr z, LABEL_FA6065
	ld bc, (xwa)
	exts xbc
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	add xwa, xbc
	ld xhl, xwa
	jr LABEL_FA606A

LABEL_FA6065:
	ld xhl, 0xFFFFFFFF

LABEL_FA606A:
	pop xiz
	ret

Link:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xbc
	ld xiz, xwa
	calr View_GetNextSibling
	cp xhl, 0xFFFFFFFF
	jr z, LABEL_FA6093

LABEL_FA607F:
	ld xwa, xiz
	calr View_GetNextSibling
	ld xiz, xhl
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xFFFFFFFF
	jr nz, LABEL_FA607F

LABEL_FA6093:
	ld xwa, xiz
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 8), wa
	ld xwa, xiz
	lds bc, 1
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
	lds bc, 1
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
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA6111
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	calr View_GetNextSibling
	ld (xiz + 8), hl
	ld xwa, (xsp + 8)
	lds bc, 1
	calr SetChange
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 10), 0xFFFF
	ld xwa, (xsp + 12)
	lds bc, 1
	calr SetChange

LABEL_FA6111:
	ld xwa, (xsp + 12)
	calr View_GetNextSibling
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA614C
	ld xwa, (xsp + 4)
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 10), wa
	ld xwa, (xsp + 4)
	lds bc, 1
	calr SetChange
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 8), 0xFFFF
	ld xwa, (xsp + 12)
	lds bc, 1
	calr SetChange

LABEL_FA614C:
	ld xwa, (xsp + 12)
	calr View_GetParentOffset
	ld xiz, xhl
	cp xiz, 0xFFFFFFFF
	jr z, LABEL_FA6192
	ld xwa, xiz
	calr GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	calr View_GetSuperViewInstance
	cp xhl, (xsp + 12)
	jr nz, LABEL_FA617F
	ld xbc, (xsp + 4)
	ld xwa, (xsp + 8)
	ld (xwa + 6), bc
	ld xwa, (xsp + 12)
	lds bc, 1
	calr SetChange

LABEL_FA617F:
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 4), 0xFFFF
	ld xwa, (xsp + 12)
	lds bc, 1
	calr SetChange

LABEL_FA6192:
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

LABEL_FA61B1:
	calr GetLinkView
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_FA61F4

LABEL_FA61BE:
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_FA61FD
	ld xwa, xiz
	calr GetViewInstance
	ld xwa, (xsp + 8)
	ld (xhl + 6), wa
	ld xwa, xiz
	lds bc, 1
	calr SetChange
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld wa, iz
	ld (xhl + 4), wa
	ld xwa, (xsp + 8)
	lds bc, 1
	calr SetChange
	jr LABEL_FA6203

LABEL_FA61F4:
	cp xwa, xiz
	jr nz, LABEL_FA61B1
	ld xiz, (xsp + 4)
	jr LABEL_FA61BE

LABEL_FA61FD:
	ld xbc, (xsp + 8)
	calr Link

LABEL_FA6203:
	pop xiz
	inc 8, xsp
	ret

GetLinkView:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	calr View_GetSuperViewInstance
	cp xhl, 0xFFFFFFFF
	jr z, LABEL_FA621E
	ld xwa, xiz
	calr View_GetSuperViewInstance
	jr LABEL_FA6264

LABEL_FA621E:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xFFFFFFFF
	jr z, LABEL_FA622F
	ld xwa, xiz
	jr LABEL_FA6261

LABEL_FA622F:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xFFFFFFFF
	jr nz, LABEL_FA625F

LABEL_FA623C:
	ld xwa, xiz
	calr View_GetParentOffset
	ld xiz, xhl
	cp xiz, 0xFFFFFFFF
	jr nz, LABEL_FA6252
	ld xhl, 0xFFFFFFFF
	jr LABEL_FA6264

LABEL_FA6252:
	ld xwa, xiz
	calr View_GetNextSibling
	cp xhl, 0xFFFFFFFF
	jr z, LABEL_FA623C

LABEL_FA625F:
	ld xwa, xiz

LABEL_FA6261:
	calr View_GetNextSibling

LABEL_FA6264:
	pop xiz
	ret

GetViewInstance:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xFFF
	ldi_werp 0xE2, 0
	ld de, wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	lds bc, 4
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
	lds bc, 4
	ldirw
	ld xwa, xiz
	lds bc, 1
	calr SetChange
	pop xiz
	inc 4, xsp
	ret

ResNameProc:
	cp xbc, 0x1E00000
	jrl nz, ObjectProc
	ld xhl, 0x160000F
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
	cp xiz, 0x1E0000C
	jr z, LABEL_FA632B
	cp xiz, 0x1E0000B
	jr z, LABEL_FA630F
	cp xiz, 0x1E00009
	jr nz, LABEL_FA631E

LABEL_FA630F:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA631E:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA634C

LABEL_FA632B:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA634A
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA634A:
	ld xhl, xiz

LABEL_FA634C:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA6350:

uwordProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA638F
	cp xiz, 0x1E0000B
	jr z, LABEL_FA6373
	cp xiz, 0x1E00009
	jr nz, LABEL_FA6382

LABEL_FA6373:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA6382:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA63B0

LABEL_FA638F:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA63AE
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA63AE:
	ld xhl, xiz

LABEL_FA63B0:
	pop xiz
	inc 8, xsp
	ret

ucharProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA63F3
	cp xiz, 0x1E0000B
	jr z, LABEL_FA63D7
	cp xiz, 0x1E00009
	jr nz, LABEL_FA63E6

LABEL_FA63D7:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA63E6:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA6414

LABEL_FA63F3:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6412
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

LABEL_FA6412:
	ld xhl, xiz

LABEL_FA6414:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA6418:

scharProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA6459
	cp xiz, 0x1E0000B
	jr z, LABEL_FA643B
	cp xiz, 0x1E00009
	jr nz, LABEL_FA644C

LABEL_FA643B:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld c, (xhl)
	exts bc
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA644C:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA647A

LABEL_FA6459:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6478
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

LABEL_FA6478:
	ld xhl, xiz

LABEL_FA647A:
	pop xiz
	inc 8, xsp
	ret

slongProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA64BB
	cp xiz, 0x1E0000B
	jr z, LABEL_FA64A1
	cp xiz, 0x1E00009
	jr nz, LABEL_FA64AE

LABEL_FA64A1:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc

LABEL_FA64AE:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA64DC

LABEL_FA64BB:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA64DA
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

LABEL_FA64DA:
	ld xhl, xiz

LABEL_FA64DC:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA64E0:

ulongProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA651D
	cp xiz, 0x1E0000B
	jr z, LABEL_FA6503
	cp xiz, 0x1E00009
	jr nz, LABEL_FA6510

LABEL_FA6503:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc

LABEL_FA6510:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA653E

LABEL_FA651D:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA653C
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

LABEL_FA653C:
	ld xhl, xiz

LABEL_FA653E:
	pop xiz
	inc 8, xsp
	ret

boolProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA6581
	cp xiz, 0x1E0000B
	jr z, LABEL_FA6565
	cp xiz, 0x1E00009
	jr nz, LABEL_FA6574

LABEL_FA6565:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA6574:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA65A2

LABEL_FA6581:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA65A0
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA65A0:
	ld xhl, xiz

LABEL_FA65A2:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA65A6:

pBoolProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA66B0
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA668A
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA664E
	cp xiz, 0x1E0000A
	jr z, LABEL_FA6620
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA669F
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA6686

LABEL_FA6620:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAA9F4
	jr LABEL_FA667A

LABEL_FA664E:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAA9FE

LABEL_FA667A:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA6686:
	lds32 xhl, 0
	jr LABEL_FA66DB

LABEL_FA668A:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA669F:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA66DB

LABEL_FA66B0:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA66D9
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

LABEL_FA66D9:
	ld xhl, xiz

LABEL_FA66DB:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA66E2:

pSwordProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA67EC
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA67C6
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA678A
	cp xiz, 0x1E0000A
	jr z, LABEL_FA675C
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA67DB
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA67C2

LABEL_FA675C:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA04
	jr LABEL_FA67B6

LABEL_FA678A:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA10

LABEL_FA67B6:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA67C2:
	lds32 xhl, 0
	jr LABEL_FA6817

LABEL_FA67C6:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA67DB:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6817

LABEL_FA67EC:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6815
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

LABEL_FA6815:
	ld xhl, xiz

LABEL_FA6817:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA681E:

pUwordProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6928
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA6902
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA68C6
	cp xiz, 0x1E0000A
	jr z, LABEL_FA6898
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA6917
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA68FE

LABEL_FA6898:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA16
	jr LABEL_FA68F2

LABEL_FA68C6:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA22

LABEL_FA68F2:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA68FE:
	lds32 xhl, 0
	jr LABEL_FA6953

LABEL_FA6902:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	extz xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA6917:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6953

LABEL_FA6928:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6951
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

LABEL_FA6951:
	ld xhl, xiz

LABEL_FA6953:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA695A:

pScharProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6A66
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA6A3E
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA6A02
	cp xiz, 0x1E0000A
	jr z, LABEL_FA69D4
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA6A55
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA6A3A

LABEL_FA69D4:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA28
	jr LABEL_FA6A2E

LABEL_FA6A02:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA34

LABEL_FA6A2E:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA6A3A:
	lds32 xhl, 0
	jr LABEL_FA6A91

LABEL_FA6A3E:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld c, (xwa)
	exts bc
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA6A55:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6A91

LABEL_FA6A66:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6A8F
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

LABEL_FA6A8F:
	ld xhl, xiz

LABEL_FA6A91:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA6A98:

pUcharProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6BA2
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA6B7C
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA6B40
	cp xiz, 0x1E0000A
	jr z, LABEL_FA6B12
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA6B91
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA6B78

LABEL_FA6B12:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA3A
	jr LABEL_FA6B6C

LABEL_FA6B40:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA46

LABEL_FA6B6C:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA6B78:
	lds32 xhl, 0
	jr LABEL_FA6BCD

LABEL_FA6B7C:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	lds32 xbc, 0
	ld c, (xwa)
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA6B91:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6BCD

LABEL_FA6BA2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6BCB
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

LABEL_FA6BCB:
	ld xhl, xiz

LABEL_FA6BCD:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA6BD4:

pSlongProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6CDC
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA6CB8
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	lda xde, (xwa + 8)
	cp xiz, 0x1E00009
	jr z, LABEL_FA6C7C
	cp xiz, 0x1E0000A
	jr z, LABEL_FA6C4E
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA6CCB
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA6CB4

LABEL_FA6C4E:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA4C
	jr LABEL_FA6CA8

LABEL_FA6C7C:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA58

LABEL_FA6CA8:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA6CB4:
	lds32 xhl, 0
	jr LABEL_FA6D07

LABEL_FA6CB8:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

LABEL_FA6CCB:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6D07

LABEL_FA6CDC:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6D05
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

LABEL_FA6D05:
	ld xhl, xiz

LABEL_FA6D07:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA6D0E:

pUlongProc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6E1C
	cp xiz, 0x1E0000B
	jrl z, LABEL_FA6DF8
	lda xhl, (xsp + 8)
	ld_sril XWA, (xsp + 0x0108)
	lda xbc, (xwa + 4)
	cp xiz, 0x1E00009
	jr z, LABEL_FA6DB6
	lda xde, (xwa + 8)
	cp xiz, 0x1E0000A
	jr z, LABEL_FA6D88
	cp xiz, 0x1E00008
	jrl nz, LABEL_FA6E0B
	ld xwa, (xbc)
	ld bc, (xde)
	calr IDCountHelper
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x0108)
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
	jr LABEL_FA6DF4

LABEL_FA6D88:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA5E
	jr LABEL_FA6DE8

LABEL_FA6DB6:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	ld xbc, 0x1E00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, 0xEAAA6A

LABEL_FA6DE8:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

LABEL_FA6DF4:
	lds32 xhl, 0
	jr LABEL_FA6E47

LABEL_FA6DF8:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

LABEL_FA6E0B:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6E47

LABEL_FA6E1C:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA6E45
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

LABEL_FA6E45:
	ld xhl, xiz

LABEL_FA6E47:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA6E4E:

RECTWProc:
	lda xsp, (xsp - 128)
	push xiz
	cp xbc, 0x1E00025
	jr z, LABEL_FA6E5F
	calr CommonIDProc
	jr LABEL_FA6EC1

LABEL_FA6E5F:
	ld xiz, xde
	push xiz
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds ix, 0
	lds iy, 0
	lda xhl, (xsp + 4)
	lds32 xde, 0
	jr LABEL_FA6EAA

LABEL_FA6E77:
	cp c, 0x50
	jr nz, LABEL_FA6EA2
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
	jr LABEL_FA6EA4

LABEL_FA6EA2:
	ld (xwa), c

LABEL_FA6EA4:
	inc 1, iy
	inc 1, xde
	inc 1, ix

LABEL_FA6EAA:
	ld xwa, xde
	ld xbc, xhl
	add xbc, xwa
	ld wa, ix
	extz xwa
	ld c, (xbc)
	add xwa, xiz
	cps c, 0
	jr nz, LABEL_FA6E77
	ld (xwa), 0x0
	lds32 xhl, 0

LABEL_FA6EC1:
	pop xiz
	st_dri3b L, 0xFD, 0x80, 0x00
	ret

RectX1Proc:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x0C, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA6F76
	cp xiz, 0x1E0000B
	jr z, LABEL_FA6F52
	cp xiz, 0x1E00009
	jr z, LABEL_FA6F52
	cp xiz, 0x1E00028
	jr z, LABEL_FA6F21
	cp xiz, 0x1E00026
	jr z, LABEL_FA6F0D
	cp xiz, 0x1E00025
	jr z, LABEL_FA6F4E
	jr LABEL_FA6F65

LABEL_FA6F0D:
	pushw 0xEA
	pushw 0xAA70
	ld_sril XWA, (xsp + 0x010c)
	push xwa
	call Strcat
	inc 8, xsp
	jr LABEL_FA6F4E

LABEL_FA6F21:
	pushw 0xEA
	pushw 0xAA76
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xwa, (xsp + 24)
	push xwa
	ld_sril XWA, (xsp + 0x011c)
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)

LABEL_FA6F4E:
	lds32 xhl, 0
	jr LABEL_FA6FB2

LABEL_FA6F52:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

LABEL_FA6F65:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr LABEL_FA6FB2

LABEL_FA6F76:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA6FAF
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, xhl
	inc 4, xbc
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld de, wa
	sub de, (xhl)
	ld (xhl), wa
	ld wa, (xbc)
	add wa, de
	ld (xbc), wa

LABEL_FA6FAF:
	ld xhl, (xsp + 4)

LABEL_FA6FB2:
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret
LABEL_FA6FB9:

RectY1Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA701F
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7003
	cp xiz, 0x1E00009
	jr z, LABEL_FA7003
	cp xiz, 0x1E00026
	jr z, LABEL_FA6FEF
	cp xiz, 0x1E00025
	jr z, LABEL_FA6FFF
	jr LABEL_FA7012

LABEL_FA6FEF:
	pushw 0xEA
	pushw 0xAA78
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp

LABEL_FA6FFF:
	lds32 xhl, 0
	jr LABEL_FA7053

LABEL_FA7003:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

LABEL_FA7012:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr LABEL_FA7053

LABEL_FA701F:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA7050
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

LABEL_FA7050:
	ld xhl, (xsp + 4)

LABEL_FA7053:
	pop xiz
	lda xsp, (xsp + 12)
	ret

RectX2Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA70E0
	cp xiz, 0x1E0000B
	jr z, LABEL_FA70BC
	cp xiz, 0x1E00009
	jr z, LABEL_FA70A0
	cp xiz, 0x1E00026
	jr z, LABEL_FA708E
	cp xiz, 0x1E00025
	jr nz, LABEL_FA70AF
	jr LABEL_FA70DC

LABEL_FA708E:
	pushw 0xEA
	pushw 0xAA7E
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	jr LABEL_FA70DC

LABEL_FA70A0:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

LABEL_FA70AF:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr LABEL_FA710D

LABEL_FA70BC:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	pushw 0xA
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 4)
	push xwa
	ld wa, (xhl)
	sub wa, (xbc)
	inc 1, wa
	pushw wa
	call Itoa_Safe
	inc 8, xsp

LABEL_FA70DC:
	lds32 xhl, 0
	jr LABEL_FA710D

LABEL_FA70E0:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA710A
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	add wa, (xbc)
	dec 1, wa
	ld (xhl), wa

LABEL_FA710A:
	ld xhl, (xsp + 4)

LABEL_FA710D:
	pop xiz
	lda xsp, (xsp + 12)
	ret
LABEL_FA7112:

RectY2Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA71B7
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7193
	cp xiz, 0x1E00009
	jr z, LABEL_FA7177
	cp xiz, 0x1E00028
	jr z, LABEL_FA7165
	cp xiz, 0x1E00026
	jr z, LABEL_FA7151
	cp xiz, 0x1E00025
	jr nz, LABEL_FA7186
	jr LABEL_FA71B3

LABEL_FA7151:
	pushw 0xEA
	pushw 0xAA86
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	lds32 xhl, 1
	jr POINTWProc_Return

LABEL_FA7165:
	pushw 0xEA
	pushw 0xAA8E
	ld xwa, (xsp + 12)
	push xwa
	call Strcat
	inc 8, xsp
	jr LABEL_FA71B3

LABEL_FA7177:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

LABEL_FA7186:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr POINTWProc_Return

LABEL_FA7193:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	pushw 0xA
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 4)
	push xwa
	ld wa, (xhl)
	sub wa, (xbc)
	inc 1, wa
	pushw wa
	call Itoa_Safe
	inc 8, xsp

LABEL_FA71B3:
	lds32 xhl, 0
	jr POINTWProc_Return

LABEL_FA71B7:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA71E1
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	lda xbc, (xhl - 4)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	add wa, (xbc)
	dec 1, wa
	ld (xhl), wa

LABEL_FA71E1:
	ld xhl, (xsp + 4)

POINTWProc_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

POINTWProc:
	st_dri3b L, 0xFD, 0x7C, 0xFF
	pushw iz
	st_dri3l XDE, 0xFD, 0x82, 0x00
	cp xbc, 0x1E00025
	jr z, LABEL_FA7206
	ld_sril XDE, (xsp + 0x0082)
	calr CommonIDProc
	jr LABEL_FA725B

LABEL_FA7206:
	ld_sril XWA, (xsp + 0x0082)
	push xwa
	lda xwa, (xsp + 6)
	push xwa
	call Strcpy
	inc 8, xsp
	lds iy, 0
	lds iz, 0
	lda xix, (xsp + 2)
	lds32 xbc, 0
	jr LABEL_FA7241

LABEL_FA7221:
	cp a, 0x55
	jr nz, LABEL_FA7239
	ld (xde), 0x56
	inc 1, iy
	ld wa, iy
	extz xwa
	add_sril_rm XWA, 0xFD, 0x82, 0x00
	ld (xwa), 0x57
	jr LABEL_FA723B

LABEL_FA7239:
	ld (xde), a

LABEL_FA723B:
	inc 1, iz
	inc 1, xbc
	inc 1, iy

LABEL_FA7241:
	ld xwa, xbc
	ld xhl, xix
	add xhl, xwa
	ld de, iy
	extz xde
	add_sril_rm XDE, 0xFD, 0x82, 0x00
	ld a, (xhl)
	cps a, 0
	jr nz, LABEL_FA7221
	ld (xde), 0x0
	lds32 xhl, 0

LABEL_FA725B:
	popw iz
	st_dri3b L, 0xFD, 0x84, 0x00
	ret
LABEL_FA7262:

PointXProc:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x04, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x08, 0x01
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA7310
	cp xiz, 0x1E0000B
	jr z, LABEL_FA72EC
	cp xiz, 0x1E00009
	jr z, LABEL_FA72EC
	cp xiz, 0x1E00028
	jr z, LABEL_FA72BB
	cp xiz, 0x1E00026
	jr z, LABEL_FA72A7
	cp xiz, 0x1E00025
	jr z, LABEL_FA72E8
	jr LABEL_FA72FF

LABEL_FA72A7:
	pushw 0xEA
	pushw 0xAA90
	ld_sril XWA, (xsp + 0x0108)
	push xwa
	call Strcat
	inc 8, xsp
	jr LABEL_FA72E8

LABEL_FA72BB:
	pushw 0xEA
	pushw 0xAA94
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x010c)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcat
	lda xwa, (xsp + 20)
	push xwa
	ld_sril XWA, (xsp + 0x0118)
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)

LABEL_FA72E8:
	lds32 xhl, 0
	jr LABEL_FA7339

LABEL_FA72EC:
	ld_sril XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld_sril XWA, (xsp + 0x0104)
	ld (xwa), xbc

LABEL_FA72FF:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	calr CommonIDProc
	jr LABEL_FA7339

LABEL_FA7310:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7337
	ld_sril XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0104)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA7337:
	ld xhl, xiz

LABEL_FA7339:
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret

PointYProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA73C1
	cp xiz, 0x1E0000B
	jr z, LABEL_FA73A5
	cp xiz, 0x1E00009
	jr z, LABEL_FA73A5
	cp xiz, 0x1E00028
	jr z, LABEL_FA7391
	cp xiz, 0x1E00026
	jr z, LABEL_FA737D
	cp xiz, 0x1E00025
	jr z, LABEL_FA73A1
	jr LABEL_FA73B4

LABEL_FA737D:
	pushw 0xEA
	pushw 0xAA96
	ld xwa, (xsp + 8)
	push xwa
	call Strcat
	inc 8, xsp
	lds32 xhl, 1
	jr IDCursorProc_Return

LABEL_FA7391:
	pushw 0xEA
	pushw 0xAA9A
	ld xwa, (xsp + 8)
	push xwa
	call Strcat
	inc 8, xsp

LABEL_FA73A1:
	lds32 xhl, 0
	jr IDCursorProc_Return

LABEL_FA73A5:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA73B4:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr IDCursorProc_Return

LABEL_FA73C1:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA73E0
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA73E0:
	ld xhl, xiz

IDCursorProc_Return:
	pop xiz
	inc 8, xsp
	ret

ClassIDProc:
	st_dri3b L, 0xFD, 0xEC, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x14, 0x11
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7410
	cp xiz, 0x1E0000E
	jr z, LABEL_FA7410
	cp xiz, 0x1E0000D
	jr nz, LABEL_FA7464

LABEL_FA7410:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, 0x160
	ld (xsp + 8), xwa

LABEL_FA741D:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, LABEL_FA7454

LABEL_FA7432:
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, LABEL_FA7432

LABEL_FA7454:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x17F
	jr ule, LABEL_FA741D

LABEL_FA7464:
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA7512
	cp xiz, 0x1E0000B
	jr z, LABEL_FA74E4
	cp xiz, 0x1E00009
	jr z, LABEL_FA74E4
	cp xiz, 0x1E00028
	jr z, LABEL_FA74B9
	cp xiz, 0x1E0000E
	jr z, LABEL_FA74B3
	cp xiz, 0x1E0000D
	jrl nz, LABEL_FA7597
	ld_sril XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	jr LABEL_FA74FE

LABEL_FA74B3:
	ld xhl, (xsp + 12)
	jrl ViewFlagProc_Return

LABEL_FA74B9:
	pushw 0xEA
	pushw 0xAA9C
	lda xwa, (xsp + 20)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x1118)
	push xwa
	lda xwa, (xsp + 28)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 16)
	push xwa
	ld_sril XWA, (xsp + 0x1114)
	push xwa
	jr LABEL_FA7507

LABEL_FA74E4:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0

LABEL_FA74FE:
	call ClassProc
	push xhl
	ld xwa, (xiz + 4)
	push xwa

LABEL_FA7507:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jrl ViewFlagProc_Return

LABEL_FA7512:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, LABEL_FA7579

LABEL_FA752A:
	ld xwa, (xiz + 4)
	push xwa
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ClassProc
	push xhl
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA756C
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr LABEL_FA7580

LABEL_FA756C:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, LABEL_FA752A

LABEL_FA7579:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA7592

LABEL_FA7580:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

LABEL_FA7592:
	ld xhl, (xsp + 4)
	jr ViewFlagProc_Return

LABEL_FA7597:
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc

ViewFlagProc_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x11
	ret

ViewFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA75EC
	cp xiz, 0x1E0000B
	jr z, LABEL_FA75D0
	cp xiz, 0x1E00009
	jr nz, LABEL_FA75DF

LABEL_FA75D0:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA75DF:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA760D

LABEL_FA75EC:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA760B
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA760B:
	ld xhl, xiz

LABEL_FA760D:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA7611:

ColorIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7650
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7634
	cp xiz, 0x1E00009
	jr nz, LABEL_FA7643

LABEL_FA7634:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA7643:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA7671

LABEL_FA7650:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA766F
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA766F:
	ld xhl, xiz

LABEL_FA7671:
	pop xiz
	inc 8, xsp
	ret

BorderIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA76B4
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7698
	cp xiz, 0x1E00009
	jr nz, LABEL_FA76A7

LABEL_FA7698:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA76A7:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA76D5

LABEL_FA76B4:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA76D3
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA76D3:
	ld xhl, xiz

LABEL_FA76D5:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA76D9:

AlignmentIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7718
	cp xiz, 0x1E0000B
	jr z, LABEL_FA76FC
	cp xiz, 0x1E00009
	jr nz, LABEL_FA770B

LABEL_FA76FC:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA770B:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA7739

LABEL_FA7718:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7737
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

LABEL_FA7737:
	ld xhl, xiz

LABEL_FA7739:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA773D:

EditSwStyleIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA777C
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7760
	cp xiz, 0x1E00009
	jr nz, LABEL_FA776F

LABEL_FA7760:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA776F:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA779D

LABEL_FA777C:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA779B
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

LABEL_FA779B:
	ld xhl, xiz

LABEL_FA779D:
	pop xiz
	inc 8, xsp
	ret

EditSwIDProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1E00029
	jr z, LABEL_FA7811
	cp xiz, 0x1E0000C
	jr z, LABEL_FA77E9
	cp xiz, 0x1E0000B
	jr z, LABEL_FA77CD
	cp xiz, 0x1E00009
	jr nz, LABEL_FA77DC

LABEL_FA77CD:
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 8)
	ld (xwa), xbc

LABEL_FA77DC:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	jr LABEL_FA783D

LABEL_FA77E9:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, LABEL_FA780C
	ld xwa, (xsp + 8)
	calr IDCursorAdvance
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA780C:
	ld xhl, (xsp + 4)
	jr LABEL_FA783D

LABEL_FA7811:
	ld xwa, (xsp + 8)
	ld bc, wa
	ld hl, bc
	sub hl, 0x80
	cp xwa, 0x80
	jr c, LABEL_FA782C
	cp xwa, 0x87
	jr ule, LABEL_FA7837

LABEL_FA782C:
	ld xwa, (xsp + 8)
	cp xwa, 0x90
	jr nz, LABEL_FA7839

LABEL_FA7837:
	jr LABEL_FA783B

LABEL_FA7839:
	ld hl, bc

LABEL_FA783B:
	extz xhl

LABEL_FA783D:
	pop xiz
	lda xsp, (xsp + 12)
	ret

LineModeIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7881
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7865
	cp xiz, 0x1E00009
	jr nz, LABEL_FA7874

LABEL_FA7865:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
	ld c, (xhl)
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA7874:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA78A2

LABEL_FA7881:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA78A0
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), a

LABEL_FA78A0:
	ld xhl, xiz

LABEL_FA78A2:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA78A6:

FrameIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA78E5
	cp xiz, 0x1E0000B
	jr z, LABEL_FA78C9
	cp xiz, 0x1E00009
	jr nz, LABEL_FA78D8

LABEL_FA78C9:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA78D8:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA7906

LABEL_FA78E5:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7904
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA7904:
	ld xhl, xiz

LABEL_FA7906:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA790A:

UserIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7949
	cp xiz, 0x1E0000B
	jr z, LABEL_FA792D
	cp xiz, 0x1E00009
	jr nz, LABEL_FA793C

LABEL_FA792D:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA793C:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA796A

LABEL_FA7949:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7968
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA7968:
	ld xhl, xiz

LABEL_FA796A:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA796E:

PartIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA79AD
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7991
	cp xiz, 0x1E00009
	jr nz, LABEL_FA79A0

LABEL_FA7991:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA79A0:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA79CE

LABEL_FA79AD:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA79CC
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA79CC:
	ld xhl, xiz

LABEL_FA79CE:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA79D2:

TrackIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7A11
	cp xiz, 0x1E0000B
	jr z, LABEL_FA79F5
	cp xiz, 0x1E00009
	jr nz, LABEL_FA7A04

LABEL_FA79F5:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA7A04:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA7A32

LABEL_FA7A11:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7A30
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA7A30:
	ld xhl, xiz

LABEL_FA7A32:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA7A36:

IntTimeIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7A75
	cp xiz, 0x1E0000B
	jr z, LABEL_FA7A59
	cp xiz, 0x1E00009
	jr nz, LABEL_FA7A68

LABEL_FA7A59:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld bc, (xhl)
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa), xbc

LABEL_FA7A68:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA7A96

LABEL_FA7A75:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA7A94
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

LABEL_FA7A94:
	ld xhl, xiz

LABEL_FA7A96:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA7A9A:

StringProc:
	st_dri3b L, 0xFD, 0xC6, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x3A, 0x01
	ld_sril XDE, (xsp + 0x013a)
	inc 4, xde
	cp xbc, 0x1E0000C
	jrl z, LABEL_FA7B74
	cp xbc, 0x1E0000B
	jrl z, LABEL_FA7B5F
	cp xbc, 0x1E00009
	jrl z, LABEL_FA7B5F
	cp xbc, 0x1E00028
	jr z, LABEL_FA7B26
	cp xbc, 0x1E00008
	jr z, LABEL_FA7AE2
	ld_sril XDE, (xsp + 0x013a)
	calr CommonIDProc
	jrl LABEL_FA7BC8

LABEL_FA7AE2:
	ld xwa, (xde)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 8)
	calr IDCountHelper
	ld (xsp + 6), xhl
	ld_sril XBC, (xsp + 0x013a)
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
	jrl LABEL_FA7BBD

LABEL_FA7B26:
	pushw 0xEA
	pushw 0xAAA0
	lda xwa, (xsp + 18)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x0142)
	push xwa
	lda xwa, (xsp + 26)
	push xwa
	call Strcat
	pushw 0xEA
	pushw 0xAAA2
	lda xwa, (xsp + 34)
	push xwa
	call Strcat
	lda xsp, (xsp + 24)
	lda xwa, (xsp + 14)
	push xwa
	ld_sril XWA, (xsp + 0x013e)
	push xwa
	jr LABEL_FA7BC0

LABEL_FA7B5F:
	ld_sril XWA, (xsp + 0x013a)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x013a)
	st_dpil XBC, 0xE2
	push xbc
	jr LABEL_FA7BBD

LABEL_FA7B74:
	ld xwa, (xde)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x013a)
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
	jr nc, LABEL_FA7BB6
	ld xwa, (xsp + 4)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld xwa, (xsp + 8)
	ld (xwa), xhl

LABEL_FA7BB6:
	ld xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 12)

LABEL_FA7BBD:
	ld xwa, (xwa)
	push xwa

LABEL_FA7BC0:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0

LABEL_FA7BC8:
	pop xiz
	st_dri3b L, 0xFD, 0x3A, 0x01
	ret

FontIDProc:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	cp xbc, 0x1E0000C
	jrl z, LABEL_FA7C8B
	cp xbc, 0x1E0000B
	jr z, LABEL_FA7C58
	cp xbc, 0x1E00009
	jr z, LABEL_FA7C58
	cp xbc, 0x1E00028
	jr z, LABEL_FA7C2D
	cp xbc, 0x1E0000E
	jr z, LABEL_FA7C23
	cp xbc, 0x1E0000D
	jrl nz, LABEL_FA7CE0
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, 0x3EFAC
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr LABEL_FA7C78

LABEL_FA7C23:
	ld16_24 xhl, 0xeada94
	exts xhl
	jrl LABEL_FA7CE8

LABEL_FA7C2D:
	pushw 0xEA
	pushw 0xAAA4
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	push xwa
	jr LABEL_FA7C81

LABEL_FA7C58:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, 0x3EFAC
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

LABEL_FA7C78:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA7C81:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr LABEL_FA7CE8

LABEL_FA7C8B:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr LABEL_FA7CB4

LABEL_FA7C97:
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA7CB2
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr LABEL_FA7CD1

LABEL_FA7CB2:
	inc 1, xiz

LABEL_FA7CB4:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0x3EFAC
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, LABEL_FA7C97
	ld xwa, (xsp + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA7CDB

LABEL_FA7CD1:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

LABEL_FA7CDB:
	ld xhl, (xsp + 4)
	jr LABEL_FA7CE8

LABEL_FA7CE0:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

LABEL_FA7CE8:
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret
LABEL_FA7CEF:

IconIDProc:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	cp xbc, 0x1E0000C
	jrl z, LABEL_FA7DAB
	cp xbc, 0x1E0000B
	jr z, LABEL_FA7D78
	cp xbc, 0x1E00009
	jr z, LABEL_FA7D78
	cp xbc, 0x1E00028
	jr z, LABEL_FA7D4D
	cp xbc, 0x1E0000E
	jr z, LABEL_FA7D43
	cp xbc, 0x1E0000D
	jrl nz, LABEL_FA7E00
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, 0xEB193C
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr LABEL_FA7D98

LABEL_FA7D43:
	ld16_24 xhl, 0xeb193a
	extz xhl
	jrl BitmapIDProc_Return

LABEL_FA7D4D:
	pushw 0xEA
	pushw 0xAAA8
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	push xwa
	jr LABEL_FA7DA1

LABEL_FA7D78:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, 0xEB193C
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

LABEL_FA7D98:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA7DA1:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr BitmapIDProc_Return

LABEL_FA7DAB:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr LABEL_FA7DD4

LABEL_FA7DB7:
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA7DD2
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr LABEL_FA7DF1

LABEL_FA7DD2:
	inc 1, xiz

LABEL_FA7DD4:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0xEB193C
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, LABEL_FA7DB7
	ld xwa, (xsp + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA7DFB

LABEL_FA7DF1:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

LABEL_FA7DFB:
	ld xhl, (xsp + 4)
	jr BitmapIDProc_Return

LABEL_FA7E00:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

BitmapIDProc_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret

BitmapIDProc:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x08, 0x01
	cp xbc, 0x1E0000C
	jrl z, LABEL_FA7ECB
	cp xbc, 0x1E0000B
	jr z, LABEL_FA7E98
	cp xbc, 0x1E00009
	jr z, LABEL_FA7E98
	cp xbc, 0x1E00028
	jr z, LABEL_FA7E6D
	cp xbc, 0x1E0000E
	jr z, LABEL_FA7E63
	cp xbc, 0x1E0000D
	jrl nz, LABEL_FA7F20
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, 0xEAB3CC
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr LABEL_FA7EB8

LABEL_FA7E63:
	ld16_24 xhl, 0xeab3ca
	extz xhl
	jrl ApFuncIDProc_Return

LABEL_FA7E6D:
	pushw 0xEA
	pushw 0xAAB0
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 8)
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	push xwa
	jr LABEL_FA7EC1

LABEL_FA7E98:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, 0xEAB3CC
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

LABEL_FA7EB8:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA7EC1:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr ApFuncIDProc_Return

LABEL_FA7ECB:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr LABEL_FA7EF4

LABEL_FA7ED7:
	push xwa
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA7EF2
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr LABEL_FA7F11

LABEL_FA7EF2:
	inc 1, xiz

LABEL_FA7EF4:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0xEAB3CC
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, LABEL_FA7ED7
	ld xwa, (xsp + 4)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA7F1B

LABEL_FA7F11:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

LABEL_FA7F1B:
	ld xhl, (xsp + 4)
	jr ApFuncIDProc_Return

LABEL_FA7F20:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

ApFuncIDProc_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret
LABEL_FA7F2F:

ApFuncIDProc:
	st_dri3b L, 0xFD, 0xE8, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x11
	cp xiz, 0x1E0000C
	jr z, LABEL_FA7F59
	cp xiz, 0x1E0000E
	jr z, LABEL_FA7F59
	cp xiz, 0x1E0000D
	jr nz, LABEL_FA7FAD

LABEL_FA7F59:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld xwa, 0x120
	ld (xsp + 12), xwa

LABEL_FA7F66:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, LABEL_FA7F9D

LABEL_FA7F7B:
	ld xwa, (xsp + 16)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, LABEL_FA7F7B

LABEL_FA7F9D:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x13F
	jr ule, LABEL_FA7F66

LABEL_FA7FAD:
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA8067
	cp xiz, 0x1E0000B
	jr z, LABEL_FA8030
	cp xiz, 0x1E00009
	jr z, LABEL_FA8030
	cp xiz, 0x1E00028
	jr z, LABEL_FA8005
	cp xiz, 0x1E0000E
	jr z, LABEL_FA7FFF
	cp xiz, 0x1E0000D
	jrl nz, LABEL_FA8100
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	jr LABEL_FA8050

LABEL_FA7FFF:
	ld xhl, (xsp + 16)
	jrl MainFuncIDProc_Return

LABEL_FA8005:
	pushw 0xEA
	pushw 0xAAB4
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld_sril XWA, (xsp + 0x1118)
	push xwa
	jr LABEL_FA805C

LABEL_FA8030:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, 0x1E00015
	lds32 xde, 0

LABEL_FA8050:
	call ApFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA805C:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jrl MainFuncIDProc_Return

LABEL_FA8067:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 8), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, LABEL_FA80DC

LABEL_FA8087:
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ApFunctionProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA80CF
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 8), xwa
	jr LABEL_FA80E3

LABEL_FA80CF:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, LABEL_FA8087

LABEL_FA80DC:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, LABEL_FA80FB

LABEL_FA80E3:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

LABEL_FA80FB:
	ld xhl, (xsp + 8)
	jr MainFuncIDProc_Return

LABEL_FA8100:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

MainFuncIDProc_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x11
	ret

MainFuncIDProc:
	st_dri3b L, 0xFD, 0xE8, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x11
	cp xiz, 0x1E0000C
	jr z, LABEL_FA8140
	cp xiz, 0x1E0000E
	jr z, LABEL_FA8140
	cp xiz, 0x1E0000D
	jr nz, LABEL_FA8194

LABEL_FA8140:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld xwa, 0x140
	ld (xsp + 12), xwa

LABEL_FA814D:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, LABEL_FA8184

LABEL_FA8162:
	ld xwa, (xsp + 16)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, LABEL_FA8162

LABEL_FA8184:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x15F
	jr ule, LABEL_FA814D

LABEL_FA8194:
	cp xiz, 0x1E0000C
	jrl z, LABEL_FA824E
	cp xiz, 0x1E0000B
	jr z, LABEL_FA8217
	cp xiz, 0x1E00009
	jr z, LABEL_FA8217
	cp xiz, 0x1E00028
	jr z, LABEL_FA81EC
	cp xiz, 0x1E0000E
	jr z, LABEL_FA81E6
	cp xiz, 0x1E0000D
	jrl nz, LABEL_FA82E7
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	jr LABEL_FA8237

LABEL_FA81E6:
	ld xhl, (xsp + 16)
	jrl ViewIDProc_Return

LABEL_FA81EC:
	pushw 0xEA
	pushw 0xAAB8
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld_sril XWA, (xsp + 0x1118)
	push xwa
	jr LABEL_FA8243

LABEL_FA8217:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, 0x1E00015
	lds32 xde, 0

LABEL_FA8237:
	call MainFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA8243:
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jrl ViewIDProc_Return

LABEL_FA824E:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 8), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, LABEL_FA82C3

LABEL_FA826E:
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call MainFunctionProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, LABEL_FA82B6
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 8), xwa
	jr LABEL_FA82CA

LABEL_FA82B6:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, LABEL_FA826E

LABEL_FA82C3:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, LABEL_FA82E2

LABEL_FA82CA:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

LABEL_FA82E2:
	ld xhl, (xsp + 8)
	jr ViewIDProc_Return

LABEL_FA82E7:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

ViewIDProc_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x11
	ret

ViewIDProc:
	st_dri3b L, 0xFD, 0xE8, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x11
	cp xiz, 0x1E0000C
	jr z, ViewID_EnumFill
	cp xiz, 0x1E0000E
	jr z, ViewID_EnumFill
	cp xiz, 0x1E0000D
	jr nz, ViewID_EventSwitch

ViewID_EnumFill:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

ViewID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, ViewID_EnumFill_OuterNext
	lds32 xwa, 0
	ld (xsp + 12), xwa

ViewID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, ViewID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa

ViewID_EnumFill_InnerNext:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, ViewID_EnumFill_InnerLoop

ViewID_EnumFill_OuterNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xFF
	jr ule, ViewID_EnumFill_OuterLoop

ViewID_EventSwitch:
	cp xiz, 0x1E0000C
	jrl z, ViewID_EnumOpen
	cp xiz, 0x1E0000B
	jrl z, ViewID_GetCurrent
	cp xiz, 0x1E00009
	jrl z, ViewID_GetCurrent
	cp xiz, 0x1E00028
	jrl z, ViewID_GetInfoStr
	cp xiz, 0x1E0000E
	jrl z, ViewID_EnumCount
	cp xiz, 0x1E0000D
	jrl nz, ViewID_Default
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, ViewID_Select_Lookup
	pushw 0xEA
	pushw 0xAABC
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	jrl ViewID_ReturnZero

ViewID_Select_Lookup:
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, ViewID_Select_NoName
	push xhl
	pushw 0xEA
	pushw 0xAAC4
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jrl ViewID_ReturnZero

ViewID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAACA
	ld xwa, (xde + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jrl ViewID_ReturnZero

ViewID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ViewID_Return

ViewID_GetInfoStr:
	pushw 0xEA
	pushw 0xAAD2
	lda xwa, (xsp + 24)
	push xwa
	call Strcpy
	ld_sril XWA, (xsp + 0x111c)
	push xwa
	lda xwa, (xsp + 32)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 20)
	push xwa
	ld_sril XWA, (xsp + 0x1118)
	push xwa
	jrl ViewID_StrCpy

ViewID_GetCurrent:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld xde, (xsp + 4)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xFFFFFFFF
	jr z, ViewID_GetCurrent_None
	ld xwa, (xde + 8)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	sll xwa, 0
	ld xbc, xwa
	add xbc, (xde)
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, ViewID_GetCurrent_NoName
	push xhl
	pushw 0xEA
	pushw 0xAADA
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr ViewID_ReturnZero

ViewID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAAE0
	ld xwa, (xbc + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jr ViewID_ReturnZero

ViewID_GetCurrent_None:
	pushw 0xEA
	pushw 0xAAE8
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

ViewID_StrCpy:
	call Strcpy
	inc 8, xsp

ViewID_ReturnZero:
	lds32 xhl, 0
	jrl ViewID_Return

ViewID_EnumOpen:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, ViewID_EnumOpen_NotFound

ViewID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	push xhl
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, ViewID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 12), xwa
	jr ViewID_EnumOpen_Store

ViewID_EnumOpen_ScanNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jr c, ViewID_EnumOpen_ScanLoop

ViewID_EnumOpen_NotFound:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, ViewID_EnumOpen_Return

ViewID_EnumOpen_Store:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), wa

ViewID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr ViewID_Return

ViewID_Default:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

ViewID_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x11
	ret
ViewID_Epilogue:

ScreenIDProc:
	st_dri3b L, 0xFD, 0xE8, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x11
	cp xiz, 0x1E0000C
	jr z, ScreenID_EnumFill
	cp xiz, 0x1E0000E
	jr z, ScreenID_EnumFill
	cp xiz, 0x1E0000D
	jrl nz, ScreenID_EventSwitch

ScreenID_EnumFill:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

ScreenID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, ScreenID_EnumFill_OuterNext
	lds32 xwa, 0
	ld (xsp + 12), xwa

ScreenID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, ScreenID_EnumFill_InnerNext
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	ld xbc, 0x1E00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr z, ScreenID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa

ScreenID_EnumFill_InnerNext:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, ScreenID_EnumFill_InnerLoop

ScreenID_EnumFill_OuterNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xFF
	jr ule, ScreenID_EnumFill_OuterLoop

ScreenID_EventSwitch:
	cp xiz, 0x1E0000C
	jrl z, ScreenID_EnumOpen
	cp xiz, 0x1E0000B
	jrl z, ScreenID_GetCurrent
	cp xiz, 0x1E00009
	jrl z, ScreenID_GetCurrent
	cp xiz, 0x1E00028
	jrl z, ScreenID_ReturnZero
	cp xiz, 0x1E0000E
	jrl z, ScreenID_EnumCount
	cp xiz, 0x1E0000D
	jrl nz, ScreenID_Default
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, ScreenID_Select_Lookup
	pushw 0xEA
	pushw 0xAAF0
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	jrl ScreenID_ReturnZero

ScreenID_Select_Lookup:
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_Select_NoName
	push xhl
	pushw 0xEA
	pushw 0xAAF8
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jrl ScreenID_ReturnZero

ScreenID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAAFE
	ld xwa, (xde + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jrl ScreenID_ReturnZero

ScreenID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ScreenID_Return

ScreenID_GetCurrent:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xde, (xsp + 4)
	ld xbc, (xhl)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xFFFFFFFF
	jr z, ScreenID_GetCurrent_None
	ld xbc, xde
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_GetCurrent_NoName
	push xhl
	pushw 0xEA
	pushw 0xAB06
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr ScreenID_ReturnZero

ScreenID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAB0C
	ld xwa, (xbc + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jr ScreenID_ReturnZero

ScreenID_GetCurrent_None:
	pushw 0xEA
	pushw 0xAB14
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp

ScreenID_ReturnZero:
	lds32 xhl, 0
	jrl ScreenID_Return

ScreenID_EnumOpen:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, ScreenID_EnumOpen_NotFound

ScreenID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, ScreenID_EnumOpen_ScanNoName
	push xhl
	pushw 0xEA
	pushw 0xAB1C
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr ScreenID_EnumOpen_Compare

ScreenID_EnumOpen_ScanNoName:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAB22
	lda xwa, (xsp + 30)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)

ScreenID_EnumOpen_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, ScreenID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 12), xwa
	jr ScreenID_EnumOpen_Store

ScreenID_EnumOpen_ScanNext:
	lds32 xwa, 1
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
	pushw 0xEA
	pushw 0xAB2A
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, ScreenID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xbc, 0xFFFFFFFF
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 12), xwa
	jr ScreenID_EnumOpen_Store

ScreenID_EnumOpen_CheckEmpty:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, ScreenID_EnumOpen_Return

ScreenID_EnumOpen_Store:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

ScreenID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr ScreenID_Return

ScreenID_Default:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

ScreenID_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x11
	ret
ScreenID_Epilogue:

WindowIDProc:
	st_dri3b L, 0xFD, 0xE8, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x11
	cp xiz, 0x1E0000C
	jr z, WindowID_EnumFill
	cp xiz, 0x1E0000E
	jr z, WindowID_EnumFill
	cp xiz, 0x1E0000D
	jrl nz, WindowID_EventSwitch

WindowID_EnumFill:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

WindowID_EnumFill_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	or xhl, xhl
	jr z, WindowID_EnumFill_OuterNext
	lds32 xwa, 0
	ld (xsp + 12), xwa

WindowID_EnumFill_InnerLoop:
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	call GetViewInstance
	or xhl, xhl
	jr z, WindowID_EnumFill_InnerNext
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	ld xbc, 0x1E00014
	ld xde, 0x1600035
	call SendEvent
	or xhl, xhl
	jr z, WindowID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, (xsp + 12)
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa

WindowID_EnumFill_InnerNext:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x400
	jr c, WindowID_EnumFill_InnerLoop

WindowID_EnumFill_OuterNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xFF
	jr ule, WindowID_EnumFill_OuterLoop

WindowID_EventSwitch:
	cp xiz, 0x1E0000C
	jrl z, WindowID_EnumOpen
	cp xiz, 0x1E0000B
	jrl z, WindowID_GetCurrent
	cp xiz, 0x1E00009
	jrl z, WindowID_GetCurrent
	cp xiz, 0x1E00028
	jrl z, WindowID_ReturnZero
	cp xiz, 0x1E0000E
	jrl z, WindowID_EnumCount
	cp xiz, 0x1E0000D
	jrl nz, WindowID_Default
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	cp xwa, (xsp + 16)
	jr nz, WindowID_Select_Lookup
	pushw 0xEA
	pushw 0xAB32
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	jrl WindowID_ReturnZero

WindowID_Select_Lookup:
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_Select_NoName
	push xhl
	pushw 0xEA
	pushw 0xAB3A
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jrl WindowID_ReturnZero

WindowID_Select_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xde, (xsp + 4)
	ld xwa, (xde + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAB40
	ld xwa, (xde + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jrl WindowID_ReturnZero

WindowID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl WindowID_Return

WindowID_GetCurrent:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xde, (xsp + 4)
	ld xbc, (xhl)
	ld (xde), xbc
	ld xwa, (xde)
	cp xwa, 0xFFFFFFFF
	jr z, WindowID_GetCurrent_None
	ld xbc, xde
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_GetCurrent_NoName
	push xhl
	pushw 0xEA
	pushw 0xAB48
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr WindowID_ReturnZero

WindowID_GetCurrent_NoName:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAB4E
	ld xwa, (xbc + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	jr WindowID_ReturnZero

WindowID_GetCurrent_None:
	pushw 0xEA
	pushw 0xAB56
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp

WindowID_ReturnZero:
	lds32 xhl, 0
	jrl WindowID_Return

WindowID_EnumOpen:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, WindowID_EnumOpen_NotFound

WindowID_EnumOpen_ScanLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call ViewableProc
	cp (xhl), 0x0
	jr z, WindowID_EnumOpen_ScanNoName
	push xhl
	pushw 0xEA
	pushw 0xAB5E
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr WindowID_EnumOpen_Compare

WindowID_EnumOpen_ScanNoName:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	add xwa, 0x1A00000
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ldi_werp 0xE2, 0
	pushw wa
	push xhl
	pushw 0xEA
	pushw 0xAB64
	lda xwa, (xsp + 30)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)

WindowID_EnumOpen_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	lda xwa, (xsp + 24)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, WindowID_EnumOpen_ScanNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xbc)
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 12), xwa
	jr WindowID_EnumOpen_Store

WindowID_EnumOpen_ScanNext:
	lds32 xwa, 1
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
	pushw 0xEA
	pushw 0xAB6C
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, WindowID_EnumOpen_CheckEmpty
	ld xwa, (xsp + 4)
	ld xbc, 0xFFFFFFFF
	ld (xwa + 4), xbc
	lds32 xwa, 0
	ld (xsp + 12), xwa
	jr WindowID_EnumOpen_Store

WindowID_EnumOpen_CheckEmpty:
	ld xwa, (xsp + 12)
	or xwa, xwa
	jr nz, WindowID_EnumOpen_Return

WindowID_EnumOpen_Store:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

WindowID_EnumOpen_Return:
	ld xhl, (xsp + 12)
	jr WindowID_Return

WindowID_Default:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

WindowID_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x11
	ret
WindowID_Epilogue:

ModeIDProc:
	st_dri3b L, 0xFD, 0xEC, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x14, 0x11
	cp xiz, 0x1E0000C
	jr z, ModeID_BuildTable
	cp xiz, 0x1E0000E
	jr z, ModeID_BuildTable
	cp xiz, 0x1E0000D
	jr nz, ModeID_EventDispatch

ModeID_BuildTable:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, 0x180
	ld (xsp + 8), xwa

ModeID_BuildTable_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, ModeID_BuildTable_NextGroup

ModeID_BuildTable_InnerLoop:
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, ModeID_BuildTable_InnerLoop

ModeID_BuildTable_NextGroup:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x19F
	jr ule, ModeID_BuildTable_OuterLoop

ModeID_EventDispatch:
	cp xiz, 0x1E0000C
	jrl z, ModeID_EnumOpen
	cp xiz, 0x1E0000B
	jrl z, ModeID_GetNext
	cp xiz, 0x1E00009
	jr z, ModeID_GetCurrent
	cp xiz, 0x1E0000E
	jr z, ModeID_EnumCount
	cp xiz, 0x1E0000D
	jr z, ModeID_EnumFill
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl ModeID_Return

ModeID_EnumFill:
	ld_sril XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xbc, (xiz + 4)
	cp (xhl), 0x0
	jr nz, ModeID_EnumFill_HasName
	ld xwa, (xiz + 8)
	push xwa
	pushw 0xEA
	pushw 0xAB74
	push xbc
	call Audio_SendCommand
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
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	cp (xhl), 0x0
	jr nz, ModeID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, 0xEAAB7C
	jr ModeID_GetCurrent_SendAudio

ModeID_GetCurrent_HasName:
	push xhl
	ld xwa, 0xEAAB80

ModeID_GetCurrent_SendAudio:
	push xwa
	ld xwa, (xiz + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr ModeID_ReturnZero

ModeID_GetNext:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	lda xwa, (xiz + 4)
	cp (xhl), 0x0
	jr nz, ModeID_GetNext_HasName
	ld xbc, (xiz)
	ldi_werp 0xE6, 0
	pushw bc
	pushw 0xEA
	pushw 0xAB90
	ld xwa, (xwa)
	push xwa
	call Audio_SendCommand
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
	lds32 xhl, 0
	jrl ModeID_Return

ModeID_EnumOpen:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	ld_sril XIZ, (xsp + 0x1110)
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, ModeID_EnumOpen_CheckResult

ModeID_EnumOpen_SearchLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
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
	pushw 0xEA
	pushw 0xAB98
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)

ModeID_EnumOpen_Compare:
	ld xwa, (xiz + 4)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, ModeID_EnumOpen_SearchNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr ModeID_EnumOpen_UpdateCursor

ModeID_EnumOpen_SearchNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, ModeID_EnumOpen_SearchLoop

ModeID_EnumOpen_CheckResult:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, ModeID_EnumOpen_Return

ModeID_EnumOpen_UpdateCursor:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

ModeID_EnumOpen_Return:
	ld xhl, (xsp + 4)

ModeID_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x11
	ret

TitleIDProc:
	st_dri3b L, 0xFD, 0xEC, 0xEE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x11
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x14, 0x11
	cp xiz, 0x1E0000C
	jr z, TitleID_BuildTable
	cp xiz, 0x1E0000E
	jr z, TitleID_BuildTable
	cp xiz, 0x1E0000D
	jr nz, TitleID_EventDispatch

TitleID_BuildTable:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, 0x1A0
	ld (xsp + 8), xwa

TitleID_BuildTable_OuterLoop:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, TitleID_BuildTable_NextGroup

TitleID_BuildTable_InnerLoop:
	ld xwa, (xsp + 12)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, TitleID_BuildTable_InnerLoop

TitleID_BuildTable_NextGroup:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1BF
	jr ule, TitleID_BuildTable_OuterLoop

TitleID_EventDispatch:
	cp xiz, 0x1E0000C
	jrl z, TitleID_EnumOpen
	cp xiz, 0x1E0000B
	jrl z, TitleID_GetNext
	cp xiz, 0x1E00009
	jr z, TitleID_GetCurrent
	cp xiz, 0x1E0000E
	jr z, TitleID_EnumCount
	cp xiz, 0x1E0000D
	jr z, TitleID_EnumFill
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl TitleID_Return

TitleID_EnumFill:
	ld_sril XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld xbc, (xiz + 4)
	cp (xhl), 0x0
	jr nz, TitleID_EnumFill_HasName
	ld xwa, (xiz + 8)
	push xwa
	pushw 0xEA
	pushw 0xABA0
	push xbc
	call Audio_SendCommand
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
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	cp (xhl), 0x0
	jr nz, TitleID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, 0xEAABA8
	jr TitleID_GetCurrent_SendAudio

TitleID_GetCurrent_HasName:
	push xhl
	ld xwa, 0xEAABAC

TitleID_GetCurrent_SendAudio:
	push xwa
	ld xwa, (xiz + 4)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr TitleID_ReturnZero

TitleID_GetNext:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	lda xwa, (xiz + 4)
	cp (xhl), 0x0
	jr nz, TitleID_GetNext_HasName
	ld xbc, (xiz)
	ldi_werp 0xE6, 0
	pushw bc
	pushw 0xEA
	pushw 0xABBC
	ld xwa, (xwa)
	push xwa
	call Audio_SendCommand
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
	lds32 xhl, 0
	jrl TitleID_Return

TitleID_EnumOpen:
	ld xwa, 0xFFFFFFFF
	ld (xsp + 4), xwa
	ld_sril XIZ, (xsp + 0x1110)
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, TitleID_EnumOpen_CheckResult

TitleID_EnumOpen_SearchLoop:
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1E00015
	lds32 xde, 0
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
	pushw 0xEA
	pushw 0xABC4
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)

TitleID_EnumOpen_Compare:
	ld xwa, (xiz + 4)
	push xwa
	lda xwa, (xsp + 20)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr nz, TitleID_EnumOpen_SearchNext
	ld xwa, (xsp + 8)
	sll xwa, 2
	st_dri3b A, 0xFD, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld (xiz + 4), xwa
	lds32 xwa, 0
	ld (xsp + 4), xwa
	jr TitleID_EnumOpen_UpdateCursor

TitleID_EnumOpen_SearchNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, TitleID_EnumOpen_SearchLoop

TitleID_EnumOpen_CheckResult:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, TitleID_EnumOpen_Return

TitleID_EnumOpen_UpdateCursor:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

TitleID_EnumOpen_Return:
	ld xhl, (xsp + 4)

TitleID_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x11
	ret

NameProc:
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xbc, xwa
	lda xhl, (xiz + 4)
	ld xwa, (xiz + 8)
	cp xde, 0x1E0000C
	jr z, LABEL_FA9231
	cp xde, 0x1E0000B
	jr z, LABEL_FA9215
	cp xde, 0x1E00009
	jr z, LABEL_FA920D
	cp xde, 0x1E00028
	jr z, LABEL_FA9204
	cp xde, 0x1E00026
	jr z, LABEL_FA91FD
	cp xde, 0x1E00025
	jr z, LABEL_FA922D
	ld xwa, xbc
	ld xbc, xde
	ld xde, xiz
	calr CommonIDProc
	jr LABEL_FA923C

LABEL_FA91FD:
	ld xwa, 0xEAABCC
	jr LABEL_FA9209

LABEL_FA9204:
	ld xwa, 0xEAABD2

LABEL_FA9209:
	push xwa
	push xiz
	jr LABEL_FA9227

LABEL_FA920D:
	pushw 0xEA
	pushw 0xABD4
	jr LABEL_FA9224

LABEL_FA9215:
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	push xhl
	lda xhl, (xiz + 4)

LABEL_FA9224:
	ld xwa, (xhl)
	push xwa

LABEL_FA9227:
	call Strcpy
	inc 8, xsp

LABEL_FA922D:
	lds32 xhl, 0
	jr LABEL_FA923C

LABEL_FA9231:
	ld xde, (xhl)
	ld xbc, 0x1E00016
	call SendEvent

LABEL_FA923C:
	pop xiz
	ret
LABEL_FA923E:

ConstFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	cp xbc, 0x1E0000C
	jrl z, LABEL_FA92D0
	cp xbc, 0x1E0000B
	jr z, LABEL_FA92AB
	cp xbc, 0x1E00009
	jr z, LABEL_FA9296
	cp xbc, 0x1E00028
	jr z, LABEL_FA928A
	cp xbc, 0x1E00026
	jr z, LABEL_FA9283
	cp xbc, 0x1E00025
	jr z, LABEL_FA92CC
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr LABEL_FA92EE

LABEL_FA9283:
	ld xwa, 0xEAABD6
	jr LABEL_FA928F

LABEL_FA928A:
	ld xwa, 0xEAABDE

LABEL_FA928F:
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	jr LABEL_FA92A3

LABEL_FA9296:
	pushw 0xEA
	pushw 0xABE0
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

LABEL_FA92A3:
	call Strcpy
	inc 8, xsp
	jr LABEL_FA92CC

LABEL_FA92AB:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	call GetConst
	exts xhl
	ld xwa, (xsp + 4)
	ld (xwa + 8), xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1E0000D
	ld xde, (xsp + 4)
	call SendEvent

LABEL_FA92CC:
	lds32 xhl, 0
	jr LABEL_FA92EE

LABEL_FA92D0:
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, LABEL_FA92EC
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 8)
	ld xbc, (xbc + 4)
	call SetConst

LABEL_FA92EC:
	ld xhl, xiz

LABEL_FA92EE:
	pop xiz
	inc 8, xsp
	ret
LABEL_FA92F2:

ObjectIDProc:
	jrl slongProc

pFuncProc:
	jrl LABEL_FA7F2F
LABEL_FA92F8:

pProcProc:
	jrl LABEL_FA7F2F

pPropProc:
	jrl LABEL_FA64E0
; WidgetType dispatch (pStringProc/EventIDProc)
WidgetType_DispatchDSP:
pStringProc:
	jrl LABEL_FA64E0

EventIDProc:
	jrl slongProc

CommonIDProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld xiz, xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 12), xhl
	ld xde, xiz
	cp xiz, 0x1E00028
	jrl z, CommonIDProc_ReturnZero
	cp xiz, 0x1E00026
	jr z, CommonIDProc_CheckAvail
	cp xiz, 0x1E00025
	jrl z, CommonIDProc_ReturnZero
	ld xwa, (xsp + 12)
	lda xbc, (xwa + 4)
	sub xde, 0x1E00008
	cp xde, 0x0
	jrl lt, CommonIDProc_Default
	cp xde, 0x6
	jrl gt, CommonIDProc_Default
	add xde, xde
	add xde, 0xEAABE4
	ld de, (xde)
	lda_24 xix, 0xfa936f
	jp_dri 8, 0x07, 0xF0, 0xE8
CommonIDProc_JumpTable:
	.byte 0xaf, 0x10, 0x20, 0xbf, 0x04, 0x60, 0xa8, 0x08
	.byte 0x21, 0xe9, 0xee, 0x03, 0xaf, 0x0c, 0x20, 0xa8
	.byte 0x08, 0x81, 0xa1, 0x20, 0x38, 0x68, 0x18, 0x91
	.byte 0x23, 0xeb, 0x12, 0x78, 0x16, 0x01

CommonIDProc_CheckAvail:
	lds32 xhl, 1
	jrl CommonIDProc_Epilogue
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	pushw 0xEA
	pushw 0xABE2
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CommonIDProc_ReturnZero
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	pushw 0xA
	ld xbc, (xsp + 6)
	ld xwa, (xbc + 4)
	push xwa
	ld xwa, (xbc)
	push xwa
	call LABEL_FF0FBE
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 12)
	cpw (xwa + 4), 0x0
	jr z, CommonIDProc_ReturnZero
	lds iz, 0
	ld xbc, (xwa + 8)
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	lds32 xde, 0
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
	lds32 xhl, 0
	jrl CommonIDProc_Epilogue
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	cpw (xbc), 0x0
	jr z, CommonIDProc_EnumSearch_Atoi
	lds iz, 0
	jr CommonIDProc_EnumSearch_Check

CommonIDProc_EnumSearch_Compare:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	push xwa
	ld xwa, (xbc)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
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
	ld xwa, 0xFFFFFFFF
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
	st_dri3b L, 0xFD, 0xFA, 0xFE
	push xiz
	st_dri3w BC, 0xFD, 0x08, 0x01
	ld xiz, xwa
	lda xde, (xsp + 8)
	ld xwa, xiz
	ld xbc, 0x1E00019
	call SendEvent
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lds iz, 0
	ldi_werp 0xFA, 0
	cp_sriw_im 0xFD, 0x08, 0x01, 0x00, 0x00
	jr ule, IDCountHelper_Done

IDCountHelper_Loop:
	lda xwa, (xsp + 8)
	ld_srib3 A, 0x07, 0xE0, 0xFA
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E00027
	lds32 xde, 0
	call SendEvent
	ld wa, iz
	add wa, hl
	ld iz, wa
	inc1_werp 0xFA
	ldto_werp WA, 0xFA
	cp_sriw_rm WA, 0xFD, 0x08, 0x01
	jr c, IDCountHelper_Loop

IDCountHelper_Done:
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xF8
	pop xiz
	st_dri3b L, 0xFD, 0x06, 0x01
	ret

IDCursorAdvance:
	st_dri3b L, 0xFD, 0x78, 0xFF
	pushw iz
	ld (xsp + 2), xwa
	ld xwa, (xwa + 8)
	lda xde, (xsp + 10)
	ld xbc, 0x1E00019
	call SendEvent
	lds32 xwa, 0
	ld (xsp + 6), xwa
	lds iz, 0
	jr IDCursorAdvance_Check

IDCursorAdvance_Loop:
	lda xwa, (xsp + 10)
	add xwa, xbc
	ld a, (xwa)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1E00027
	lds32 xde, 0
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
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	add xhl, (xsp + 6)
	popw iz
	st_dri3b L, 0xFD, 0x88, 0x00
	ret

InitializeEventQueue:
	ret

DispatchEvent:	; LABEL_FA9585
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr GetEvent
	cps hl, 0
	jrl z, LABEL_FA965C

; EventHandler dual-phase dispatch
EventHandler_ObjectDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xFFFFFFFF
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027ed6
	add xwa, xbc
	ld xhl, (xwa)
	or xhl, xhl
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	st32_24 0x02bc24, xwa
	st32_24 0x02bc18, xwa
	ld xwa, (xsp + 4)
	st32_24 0x02bc28, xwa
	st32_24 0x02bc1c, xwa
	ld xwa, (xsp)
	st32_24 0x02bc2c, xwa
	st32_24 0x02bc20, xwa
	ld xwa, (xsp + 8)
	ld xix, xhl
	ld xbc, 0x1E00000
	lds32 xde, 0
	call (xix)
	st32_24 0x02bc14, xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xFFF
	ldi_werp 0xEE, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	cpdi16_24 257870, 0
	jr z, EventHandler_ContinueProc
	lds wa, 3
	call TaskSched_YieldToQueue

EventHandler_ContinueProc:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr GetEvent
	cps hl, 0
	jrl nz, EventHandler_ObjectDispatch

LABEL_FA965C:
	lda xsp, (xsp + 12)
	ret

SendEvent:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xbc
	ld xiz, xwa
	cp xiz, 0xFFFFFFFF
	jr nz, EventRoute_ObjectDispatch
	calr GetCurrentTarget
	ld xiz, xhl

; EventRoute dual dispatch with context setup
EventRoute_ObjectDispatch:
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027ed6
	add xwa, xbc
	ld xhl, (xwa)
	ld32_24 xwa, 0x02bc24
	ld (xsp + 12), xwa
	ld32_24 xwa, 0x02bc28
	ld (xsp + 16), xwa
	ld32_24 xwa, 0x02bc2c
	ld (xsp + 8), xwa
	st32_24 0x02bc24, xiz
	ld xwa, (xsp + 24)
	st32_24 0x02bc28, xwa
	ld xwa, (xsp + 20)
	st32_24 0x02bc2c, xwa
	ld32_24 xwa, 0x02bc14
	ld (xsp + 4), xwa
	ld xix, xhl
	ld xwa, xiz
	ld xbc, 0x1E00000
	lds32 xde, 0
	call (xix)
	st32_24 0x02bc14, xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xFFF
	ldi_werp 0xEE, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	st32_24 0x02bc14, xwa
	ld xwa, (xsp + 12)
	st32_24 0x02bc24, xwa
	ld xwa, (xsp + 16)
	st32_24 0x02bc28, xwa
	ld xwa, (xsp + 8)
	st32_24 0x02bc2c, xwa
	cpdi16_24 257870, 0
	jr z, LABEL_FA974B
	lds wa, 3
	call TaskSched_YieldToQueue

LABEL_FA974B:
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
	lds wa, 4
	call TaskSched_WaitForEvent
	ld16_24 xbc, 0x02ec34
	ld16_24 xde, 0x02ec36
	ld wa, de
	inc 1, wa
	cp wa, bc
	jr z, LABEL_FA977F
	ld wa, de
	sub wa, 0x3FF
	cp wa, bc
	jr nz, LABEL_FA978A

LABEL_FA977F:
	lds wa, 4
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp

LABEL_FA9788:
	jr LABEL_FA9788

LABEL_FA978A:
	incdi16_24 1, 194624
	ld bc, de
	muls bc, 0xC
	lda_24 xwa, 0x02bc34
	exts xbc
	add xbc, xwa
	ld (xbc), xiz
	ld xwa, (xsp + 8)
	ld (xbc + 4), xwa
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	cp de, 0x3FF
	jr nz, LABEL_FA97BB
	sti16_24 0x02ec36, 0x0000
	jr LABEL_FA97C0

LABEL_FA97BB:
	incdi16_24 1, 191542

LABEL_FA97C0:
	lds wa, 4
	call TaskSched_SignalEvent
	lds wa, 2
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
	lds wa, 4
	call TaskSched_WaitForEvent
	ld16_24 xwa, 0x02ec34
	cpda16_24 xwa, 191542
	jr nz, LABEL_FA97F8
	lds wa, 4
	call TaskSched_SignalEvent
	lds hl, 0
	jr LABEL_FA9863

LABEL_FA97F8:
	decdi16_24 1, 194624
	ld16_24 xwa, 0x02ec34
	ld (xsp + 4), wa
	ld bc, (xsp + 4)
	muls bc, 0xC
	lda_24 xwa, 0x02bc34
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	ld (xiz), xwa
	cp xwa, 0xFFFFFFFF
	jr nz, LABEL_FA9825
	calr GetCurrentTarget
	ld (xiz), xhl

LABEL_FA9825:
	ld bc, (xsp + 4)
	muls bc, 0xC
	lda_24 xwa, 0x02bc34
	st_dri3b B, 0x07, 0xE0, 0xE4
	ld xwa, (xsp + 10)
	ld xbc, (xde + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 6)
	ld xbc, (xde + 8)
	ld (xwa), xbc
	cpw (xsp + 4), 0x3FF
	jr nz, LABEL_FA9856
	sti16_24 0x02ec34, 0x0000
	jr LABEL_FA985B

LABEL_FA9856:
	incdi16_24 1, 191540

LABEL_FA985B:
	lds wa, 4
	call TaskSched_SignalEvent
	lds hl, 1

LABEL_FA9863:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DeleteEvent:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	lds wa, 4
	call TaskSched_WaitForEvent
	ld16_24 xbc, 0x02ec36
	ld16_24 xwa, 0x02ec34
	cp wa, bc
	jr nz, LABEL_FA9888
	lds wa, 4
	jr LABEL_FA98C9

LABEL_FA9888:
	ld ix, wa
	cp wa, bc
	jr z, LABEL_FA98C7
	lda_24 xiy, 0x02bc34

LABEL_FA9893:
	ld wa, ix
	muls wa, 0xC
	st_dri3b C, 0x07, 0xF4, 0xE0
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, LABEL_FA98B3
	cp (xhl), xiz
	jr nz, LABEL_FA98B3
	ld xwa, 0x1C00000
	ld (xde), xwa

LABEL_FA98B3:
	cp ix, bc
	jr z, LABEL_FA98C7
	cp ix, 0x3FF
	jr nz, LABEL_FA98C1
	lds ix, 0
	jr LABEL_FA98C3

LABEL_FA98C1:
	inc 1, ix

LABEL_FA98C3:
	cp ix, bc
	jr nz, LABEL_FA9893

LABEL_FA98C7:
	lds wa, 4

LABEL_FA98C9:
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
	lds wa, 4
	call TaskSched_WaitForEvent
	ld16_24 xbc, 0x02ec36
	ld16_24 xwa, 0x02ec34
	cp wa, bc
	jr nz, LABEL_FA98F4
	lds wa, 4
	jr LABEL_FA993D

LABEL_FA98F4:
	ld hl, wa
	cp wa, bc
	jr z, LABEL_FA993B
	lda_24 xix, 0x02bc34

LABEL_FA98FF:
	ld wa, hl
	muls wa, 0xC
	st_dri3b E, 0x07, 0xF0, 0xE0
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop2
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, 0x1C00000
	ld (xde), xwa

ObjectSearch_ContinueLoop2:
	cp hl, bc
	jr z, LABEL_FA993B
	cp hl, 0x3FF
	jr nz, LABEL_FA9935
	lds hl, 0
	jr LABEL_FA9937

LABEL_FA9935:
	inc 1, hl

LABEL_FA9937:
	cp hl, bc
	jr nz, LABEL_FA98FF

LABEL_FA993B:
	lds wa, 4

LABEL_FA993D:
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp
	ret

; =============================================================================
; EventDispatch_Direct -- Direct event dispatch for key press routing
;
; Called from KeyPress_StateDispatch (F98697) with:
;   XWA = target workspace (0xFFFFFFFF = broadcast)
;   XBC = event code (e.g. 0x01C00038 = key press)
;   XDE = event parameter (packed key data)
;
; If the event ring buffer (at 0x02EC34/0x02EC36) is empty, delegates
; directly to BroadcastEvent (FA9D58) with the original parameters.
;
; If events are queued, scans the registration table (0x02BC34, 12-byte
; entries) for handlers registered for event 0x01C00038 whose filter
; (upper 16 bits) matches the event parameter. Updates matched entries
; and accumulates result bits in QIZH, then dispatches via FA9D58.
;
; Stack frame: 22 bytes local + QIZ save
;   (XSP+0x14) = saved XWA (target)
;   (XSP+0x10) = saved XBC (event code)
;   (XSP+0x0C) = saved XDE (event param)
;   (XSP+0x0A) = param byte 1 (srl 8 of XDE & 0xFF)
;   (XSP+0x08) = accumulator byte
;   (XSP+0x06) = param byte 0 (XDE & 0xFF)
;   (XSP+0x02) = working copy of event param
; =============================================================================
LABEL_FA9945:
	lda xsp, (xsp - 22)			; allocate 22 bytes stack frame
	push qiz				; save QIZ
	ld (xsp + 12), xde			; save event param
	ld (xsp + 16), xbc			; save event code
	ld (xsp + 20), xwa			; save target workspace
	; --- Check if ring buffer is empty ---
	lds	wa, 4
	call TaskSched_WaitForEvent				; acquire lock/semaphore (id=4)
	ld16_24	bc, 191542
	ld16_24	de, 191540
	cp de, bc				; compare read/write positions
	jr nz, LABEL_FA997A			; buffer not empty, process events
	; --- Buffer empty: release lock, dispatch directly ---
	lds	wa, 4
	call TaskSched_SignalEvent				; release lock/semaphore (id=4)
	ld xwa, (xsp + 20)			; restore target
	ld xbc, (xsp + 16)			; restore event code
	ld xde, (xsp + 12)			; restore event param
	jrl LABEL_FA9A6D			; jump to dispatch via FA9D58
LABEL_FA997A:
	; --- Buffer not empty: extract param bytes from XDE ---
	ld xwa, (xsp + 12)			; XWA = event param (XDE)
	ld (xsp + 2), xwa			; save working copy
	and xwa, 0x000000FF			; isolate low byte
	ld (xsp + 6), a				; param byte 0 = XDE & 0xFF
	ld xwa, (xsp + 2)			; reload working copy
	srl xwa, 8				; shift right 8 bits
	and xwa, 0x000000FF			; isolate byte
	ld (xsp + 10), a			; param byte 1 = (XDE >> 8) & 0xFF
	.byte 0xc7, 0xfb, 0xa8			; ld qizh, 0  [QIZH not in LLVM]
	ld (xsp + 8), 0x00			; clear accumulator byte
	; --- Scan registration table ---
	ld ix, de				; IX = write position (start)
	ld hl, bc				; HL = read position (end/sentinel)
	cp de, bc				; check if already at end
	jr z, LABEL_FA9A23			; empty range, skip scan
LABEL_FA99A7:
	ld bc, ix				; BC = current index
	muls bc, 0x000C				; BC = index * 12 (entry size)
	lda_24 xwa, 0x02BC34			; XWA = base of registration table
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x30	; lda xwa, (xwa + bc)  [reg+reg, not in LLVM]
	lda xbc, (xwa + 4)			; XBC = pointer to entry+4 (event code)
	ld xde, (xbc)				; XDE = registered event code
	cp xde, 0x01C00038			; compare with key press event
	jr nz, LABEL_FA9A0F			; no match, skip this entry
	; --- Event code matches: check filter ---
	lda xde, (xwa + 8)			; XDE = pointer to entry+8 (filter)
	ld xwa, (xde)				; XWA = registered filter value
	lds	wa, 0
	ld xiy, (xsp + 12)			; XIY = original event param
	and xiy, 0xFFFF0000			; isolate upper 16 bits
	cp xiy, xwa				; compare filter with event param upper bits
	jr nz, LABEL_FA9A0F			; no match
	; --- Filter matches: update registration and accumulate bits ---
	ld xwa, 0x01C00000			; mark as active (clear low 16 bits)
	ld (xbc), xwa				; write updated event code to entry+4
	ld xwa, (xde)				; reload filter value
	ld xbc, xwa				; copy to XBC
	and xbc, 0x000000FF			; XBC low byte = filter byte 0
	ld b, c					; B = filter byte 0
	srl xwa, 8				; shift filter right 8
	and xwa, 0x000000FF			; isolate byte
	ld e, a					; E = filter byte 1
	ld c, b					; C = filter byte 0
	cpl c					; C = ~filter byte 0 (complement)
	.byte 0xc7, 0xfb, 0x89			; ld a, qizh
	and a, c				; clear bits in QIZH where filter has 1s
	.byte 0xc7, 0xfb, 0x99			; ld qizh, a
	and e, b				; E = filter & filter (= filter)
	.byte 0xc7, 0xfb, 0x89			; ld a, qizh
	add a, e				; set bits in QIZH where filter has 1s
	.byte 0xc7, 0xfb, 0x99			; ld qizh, a
	or (xsp + 8), b				; accumulate filter byte 0 into (xsp+8)
LABEL_FA9A0F:
	; --- Advance to next registration entry ---
	cp ix, hl				; reached end sentinel?
	jr z, LABEL_FA9A23			; yes, done scanning
	cp ix, 0x03FF				; check for index wrap
	jr nz, LABEL_FA9A1D			; no wrap needed
	lds	ix, 0
	jr LABEL_FA9A1F				; skip increment
LABEL_FA9A1D:
	inc 1, ix				; next entry index
LABEL_FA9A1F:
	cp ix, hl				; check end again
	jr nz, LABEL_FA99A7			; continue scanning
LABEL_FA9A23:
	; --- Done scanning: release lock and reassemble event param ---
	lds	wa, 4
	call TaskSched_SignalEvent				; release lock/semaphore
	ld c, (xsp + 6)				; C = param byte 0
	cpl c					; C = ~param byte 0
	.byte 0xc7, 0xfb, 0x89			; ld a, qizh
	and a, c				; clear bits
	.byte 0xc7, 0xfb, 0x99			; ld qizh, a
	ld c, (xsp + 10)			; C = param byte 1
	and c, (xsp + 6)			; C = byte1 & byte0
	.byte 0xc7, 0xfb, 0x89			; ld a, qizh
	add a, c				; accumulate
	.byte 0xc7, 0xfb, 0x99			; ld qizh, a
	ld a, (xsp + 6)				; A = param byte 0
	or (xsp + 8), a				; accumulate into (xsp+8)
	; --- Build final XDE from accumulated data ---
	ld xwa, 0xFFFF0000			; mask for upper 16 bits
	and (xsp + 2), xwa			; keep upper 16 bits of working param
	lds32	xbc, 0
	.byte 0xc7, 0xfb, 0x8b			; ld c, qizh
	sll xbc, 8				; shift QIZH value into byte 1 position
	lds32	xwa, 0
	ld a, (xsp + 8)				; A = accumulator byte
	add xwa, xbc				; merge
	add (xsp + 2), xwa			; merge into working param
	; --- Dispatch event ---
	ld xwa, (xsp + 20)			; restore target workspace
	ld xbc, (xsp + 16)			; restore event code
	ld xde, (xsp + 2)			; load modified event param
LABEL_FA9A6D:
	calr	744
	pop qiz					; restore QIZ
	lda xsp, (xsp + 22)			; deallocate stack frame
	ret


GetCurrentTarget:
	ld32_24 xhl, 0x02f83c
	ret

SetCurrentTarget:
	cp xwa, 0xFFFFFFFF
	ret z
	st32_24 0x02f83c, xwa
	ret

MainDispatchEvent:
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr MainGetEvent
	cps hl, 0
	jr z, LABEL_FA9AF0

; MainSendEvent object dispatch
MainSendEvent_VirtualDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xFFFFFFFF
	jr z, LABEL_FA9AE1
	ld xwa, (xsp + 8)
	srl xwa, 0
	and xwa, 0xFFF
	ld xde, (xsp + 8)
	ldi_werp 0xEA, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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

LABEL_FA9AE1:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr MainGetEvent
	cps hl, 0
	jr nz, MainSendEvent_VirtualDispatch

LABEL_FA9AF0:
	lda xsp, (xsp + 12)
	ret

MainSendEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	cp xiz, 0xFFFFFFFF
	jr nz, MainPostEvent_VirtualDispatch
	lds32 xhl, 0
	jr LABEL_FA9B59

; MainPostEvent queued dispatch with validation
MainPostEvent_VirtualDispatch:
	ld xwa, xiz
	ld xbc, 0x1E00014
	ld xde, 0x1600003
	calr SendEvent
	or xhl, xhl
	jr z, LABEL_FA9B57
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xFFF
	ld xde, xiz
	ldi_werp 0xEA, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
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
	jr LABEL_FA9B59

LABEL_FA9B57:
	lds32 xhl, 0

LABEL_FA9B59:
	pop xiz
	inc 8, xsp
	ret

MainPostEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	lds wa, 7
	jr LABEL_FA9B83

LABEL_FA9B6C:
	lds wa, 7
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, LABEL_FA9C02
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 7

LABEL_FA9B83:
	call TaskSched_WaitForEvent
	ld16_24 xwa, 0x02f83a
	ld de, wa
	inc 1, de
	ld16_24 xbc, 0x02f838
	cp de, bc
	jr z, LABEL_FA9B6C
	sub wa, 0xFF
	cp wa, bc
	jr z, LABEL_FA9B6C
	incdi16_24 1, 194626
	ld16_24 xwa, 0x02f83a
	muls wa, 0xC
	lda_24 xbc, 0x02ec38
	st_dri3l XIZ, 0x07, 0xE4, 0xE0
	ld16_24 xwa, 0x02f83a
	muls wa, 0xC
	st_dri3b B, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ld16_24 xwa, 0x02f83a
	muls wa, 0xC
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ld16_24 xwa, 0x02f83a
	cp wa, 0xFF
	jr nz, LABEL_FA9BF5
	sti16_24 0x02f83a, 0x0000
	jr LABEL_FA9BFC

LABEL_FA9BF5:
	inc 1, wa
	st16_24 0x02f83a, xwa

LABEL_FA9BFC:
	lds wa, 7
	call TaskSched_SignalEvent

LABEL_FA9C02:
	pop xiz
	inc 8, xsp
	ret

MainGetEvent:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	lds wa, 7
	call TaskSched_WaitForEvent
	ld16_24 xwa, 0x02f838
	cpda16_24 xwa, 194618
	jr nz, LABEL_FA9C2D
	lds wa, 7
	call TaskSched_SignalEvent
	lds hl, 0
	jr LABEL_FA9C77

LABEL_FA9C2D:
	decdi16_24 1, 194626
	ld16_24 xde, 0x02f838
	ld bc, de
	muls bc, 0xC
	lda_24 xwa, 0x02ec38
	st_dri3b C, 0x07, 0xE0, 0xE4
	ld xwa, (xhl)
	ld (xiz), xwa
	ld xwa, (xsp + 8)
	ld xbc, (xhl + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 4)
	ld xbc, (xhl + 8)
	ld (xwa), xbc
	cp de, 0xFF
	jr nz, LABEL_FA9C6A
	sti16_24 0x02f838, 0x0000
	jr LABEL_FA9C6F

LABEL_FA9C6A:
	incdi16_24 1, 194616

LABEL_FA9C6F:
	lds wa, 7
	call TaskSched_SignalEvent
	lds hl, 1

LABEL_FA9C77:
	pop xiz
	inc 8, xsp
	ret

MainDeleteEvent:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	lds wa, 7
	call TaskSched_WaitForEvent
	ld16_24 xbc, 0x02f83a
	ld16_24 xwa, 0x02f838
	cp wa, bc
	jr nz, LABEL_FA9C9B
	lds wa, 7
	jr LABEL_FA9CDC

LABEL_FA9C9B:
	ld ix, wa
	cp wa, bc
	jr z, LABEL_FA9CDA
	lda_24 xiy, 0x02ec38

LABEL_FA9CA6:
	ld wa, ix
	muls wa, 0xC
	st_dri3b C, 0x07, 0xF4, 0xE0
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, LABEL_FA9CC6
	cp (xhl), xiz
	jr nz, LABEL_FA9CC6
	ld xwa, 0x1C00000
	ld (xde), xwa

LABEL_FA9CC6:
	cp ix, bc
	jr z, LABEL_FA9CDA
	cp ix, 0x3FF
	jr nz, LABEL_FA9CD4
	lds ix, 0
	jr LABEL_FA9CD6

LABEL_FA9CD4:
	inc 1, ix

LABEL_FA9CD6:
	cp ix, bc
	jr nz, LABEL_FA9CA6

LABEL_FA9CDA:
	lds wa, 7

LABEL_FA9CDC:
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
	lds wa, 7
	call TaskSched_WaitForEvent
	ld16_24 xbc, 0x02f83a
	ld16_24 xwa, 0x02f838
	cp wa, bc
	jr nz, LABEL_FA9D07
	lds wa, 7
	jr LABEL_FA9D50

LABEL_FA9D07:
	ld hl, wa
	cp wa, bc
	jr z, LABEL_FA9D4E
	lda_24 xix, 0x02ec38

LABEL_FA9D12:
	ld wa, hl
	muls wa, 0xC
	st_dri3b E, 0x07, 0xF0, 0xE0
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, 0x1C00000
	ld (xde), xwa

ObjectSearch_ContinueLoop:
	cp hl, bc
	jr z, LABEL_FA9D4E
	cp hl, 0x3FF
	jr nz, LABEL_FA9D48
	lds hl, 0
	jr LABEL_FA9D4A

LABEL_FA9D48:
	inc 1, hl

LABEL_FA9D4A:
	cp hl, bc
	jr nz, LABEL_FA9D12

LABEL_FA9D4E:
	lds wa, 7

LABEL_FA9D50:
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
	lds wa, 4
	jr LABEL_FA9D7E

LABEL_FA9D67:
	lds wa, 4
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, LABEL_FA9E03
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 4

LABEL_FA9D7E:
	call TaskSched_WaitForEvent
	ld16_24 xwa, 0x02ec36
	ld de, wa
	inc 1, de
	ld16_24 xbc, 0x02ec34
	cp de, bc
	jr z, LABEL_FA9D67
	sub wa, 0x3FF
	cp wa, bc
	jr z, LABEL_FA9D67
	incdi16_24 1, 194624
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	lda_24 xbc, 0x02bc34
	st_dri3l XIZ, 0x07, 0xE4, 0xE0
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	st_dri3b B, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ld16_24 xwa, 0x02ec36
	cp wa, 0x3FF
	jr nz, LABEL_FA9DF0
	sti16_24 0x02ec36, 0x0000
	jr LABEL_FA9DF7

LABEL_FA9DF0:
	inc 1, wa
	st16_24 0x02ec36, xwa

LABEL_FA9DF7:
	lds wa, 4
	call TaskSched_SignalEvent
	lds wa, 2
	call TaskSched_SignalEvent

LABEL_FA9E03:
	pop xiz
	inc 8, xsp
	ret

ApDeliveryEvent:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	lds wa, 4
	jr LABEL_FA9E2E

LABEL_FA9E17:
	lds wa, 4
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, LABEL_FA9F03
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 4

LABEL_FA9E2E:
	call TaskSched_WaitForEvent
	ld16_24 xwa, 0x02ec36
	ld de, wa
	inc 1, de
	ld16_24 xbc, 0x02ec34
	cp de, bc
	jr z, LABEL_FA9E17
	sub wa, 0x3FF
	cp wa, bc
	jr z, LABEL_FA9E17
	cp xiz, 0xFFFFFFFF
	jr z, LABEL_FA9E80
	pushw 0xC
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld (xhl), xiz
	ld xwa, (xsp + 12)
	ld (xhl + 4), xwa
	ld xwa, (xsp + 8)
	ld (xhl + 8), xwa
	ld xiz, 0xFFFFFFFF
	ld xwa, 0x1C00037
	ld (xsp + 12), xwa
	ld (xsp + 8), xhl
	jr LABEL_FA9E85

LABEL_FA9E80:
	lds32 xwa, 0
	ld (xsp + 4), xwa

LABEL_FA9E85:
	incdi16_24 1, 194624
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	lda_24 xbc, 0x02bc34
	st_dri3l XIZ, 0x07, 0xE4, 0xE0
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	st_dri3b B, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 12)
	ld (xde + 4), xwa
	ld16_24 xwa, 0x02ec36
	muls wa, 0xC
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 8)
	ld (xbc + 8), xwa
	ld16_24 xwa, 0x02ec36
	cp wa, 0x3FF
	jr nz, LABEL_FA9ED9
	sti16_24 0x02ec36, 0x0000
	jr LABEL_FA9EE0

LABEL_FA9ED9:
	inc 1, wa
	st16_24 0x02ec36, xwa

LABEL_FA9EE0:
	lds wa, 4
	call TaskSched_SignalEvent
	lds wa, 2
	call TaskSched_SignalEvent
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, LABEL_FA9F03
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, (xsp + 4)
	calr ApPostEvent

LABEL_FA9F03:
	pop xiz
	lda xsp, (xsp + 12)
	ret

InitializeTimer:
	lds32 xwa, 0
	st32_24 0x030444, xwa
	sti16_24 0x030448, 0xffff
	lda_24 xwa, 0x02f844
	lda xbc, (xwa + 8)
	lda xde, (xwa + 2)
	ld xhl, xwa
	st_dri3b D, 0xE1, 0x00, 0x0C

LABEL_FA9F28:
	ldw (xhl), 0xFFFF
	ldw (xde), 0xFFFF
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	lda xhl, (xhl + 24)
	lda xde, (xde + 24)
	lda xbc, (xbc + 24)
	cp xhl, xix
	jr c, LABEL_FA9F28
	ret
LABEL_FA9F45:

ApTimer:
	dec 8, xsp
	push xiz
	cpdi16_24 197704, 65535
	jrl nz, LABEL_FAA10D
	jrl ApTimer_IncrementCounter

LABEL_FA9F55:
	ld xiz, (xbc + 12)
	ld xwa, (xbc + 16)
	ld (xsp + 4), xwa
	ld xwa, (xbc + 20)
	ld (xsp + 8), xwa
	cp xiz, 0xFFFFFFFF
	jr nz, LABEL_FA9F71
	calr GetCurrentTarget
	ld xiz, xhl

LABEL_FA9F71:
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	lda_24 xhl, 0x02f844
	st_dri3b D, 0x07, 0xEC, 0xE0
	lda xwa, (xix + 2)
	cp xiz, 0xFFFFFFFF
	jr nz, LABEL_FA9FCD
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	st_dri3b C, 0x07, 0xEC, 0xE0
	ld xwa, 0xFFFFFFFF
	ld (xhl + 8), xwa
	st16_24 0x030448, xbc
	cp bc, 0xFFFF
	jrl z, ApTimer_IncrementCounter
	jr LABEL_FAA02C

LABEL_FA9FCD:
	ld xbc, xiz
	srl xbc, 0
	and xbc, 0xFFF
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, 0x027ed6
	add xbc, xde
	ld xde, (xbc)
	or xde, xde
	jr nz, RootContext_Setup
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	st_dri3b C, 0x07, 0xEC, 0xE0
	ld xwa, 0xFFFFFFFF
	ld (xhl + 8), xwa
	st16_24 0x030448, xbc
	cp bc, 0xFFFF
	jrl z, ApTimer_IncrementCounter

LABEL_FAA02C:
	muls bc, 0x18
	stiw_dri 0x07, 0xE8, 0xE4, 0xFF, 0xFF
	jrl LABEL_FAA10D

; RootContext setup handler
RootContext_Setup:
	st32_24 0x02bc24, xiz
	st32_24 0x02bc18, xiz
	ld xwa, (xsp + 4)
	st32_24 0x02bc28, xwa
	st32_24 0x02bc1c, xwa
	ld xwa, (xsp + 8)
	st32_24 0x02bc2c, xwa
	st32_24 0x02bc20, xwa
	ld xix, xde
	ld xwa, xiz
	ld xbc, 0x1E00000
	lds32 xde, 0
	call (xix)
	st32_24 0x02bc14, xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xFFF
	ldi_werp 0xEE, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0x027edc
	add xwa, xbc
	ld xde, (xwa)
	extz xhl
	ld xbc, xhl
	add xbc, xbc
	add xbc, xhl
	sll xbc, 3
	add xbc, xde
	ld xde, (xbc)
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	lda_24 xhl, 0x02f844
	exts xwa
	add xwa, xhl
	ld bc, (xwa + 2)
	ldw (xwa), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xFFFF
	ld16_24 xwa, 0x030448
	muls wa, 0x18
	st_dri3b D, 0x07, 0xEC, 0xE0
	ld xwa, 0xFFFFFFFF
	ld (xix + 8), xwa
	st16_24 0x030448, xbc
	cp bc, 0xFFFF
	jr z, ApTimer_VirtualDispatch
	muls bc, 0x18
	stiw_dri 0x07, 0xEC, 0xE4, 0xFF, 0xFF

; ApTimer dispatcher
ApTimer_VirtualDispatch:
	ld xhl, xde
	ld xwa, xiz
	ld xbc, (xsp + 4)
	ld xde, (xsp + 8)
	call (xhl)
	cpdi16_24 197704, 65535
	jr z, ApTimer_IncrementCounter

LABEL_FAA10D:
	ld16_24 xbc, 0x030448
	muls bc, 0x18
	lda_24 xwa, 0x02f844
	exts xbc
	add xbc, xwa
	ld xwa, (xbc + 4)
	cpda32_24 xwa, 197700
	jrl ule, LABEL_FA9F55

ApTimer_IncrementCounter:
	lds32 xwa, 1
	addm32_24 0x030444, xwa
	pop xiz
	inc 8, xsp
	ret

SetApTimer:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	lds bc, 0

LABEL_FAA144:
	ld wa, bc
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 3
	lda_24 xhl, 0x02f844
	ld (xsp + 4), xhl
	add xhl, xde
	lda xix, (xhl + 8)
	ld xwa, (xix)
	cp xwa, 0xFFFFFFFF
	jrl nz, LABEL_FAA1F8
	lda xde, (xhl + 4)
	ld32_24 xwa, 0x030444
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
	ld16_24 xix, 0x030448
	cp ix, 0xFFFF
	jr z, LABEL_FAA1F1
	ldw iy, 0xFFFF
	jr LABEL_FAA1A8

LABEL_FAA19D:
	ld iy, ix
	ld ix, (xiz + 2)
	cp ix, 0xFFFF
	jr z, LABEL_FAA1BC

LABEL_FAA1A8:
	ld iz, ix
	muls iz, 0x18
	ld xwa, (xsp + 4)
	exts xiz
	add xiz, xwa
	ld xwa, (xiz + 4)
	cp xwa, (xde)
	jr ule, LABEL_FAA19D

LABEL_FAA1BC:
	ld (xhl), iy
	ld (xhl + 2), ix
	cp iy, 0xFFFF
	jr z, LABEL_FAA1D6
	muls iy, 0x18
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xF4
	ld (xwa + 2), bc

LABEL_FAA1D6:
	cp ix, 0xFFFF
	jr z, LABEL_FAA1EA
	ld de, ix
	muls de, 0x18
	ld xwa, (xsp + 4)
	st_dri3w BC, 0x07, 0xE0, 0xE8

LABEL_FAA1EA:
	cpda16_24 xix, 197704
	jr nz, LABEL_FAA201

LABEL_FAA1F1:
	st16_24 0x030448, xbc
	jr LABEL_FAA201

LABEL_FAA1F8:
	inc 1, bc
	cp bc, 0x80
	jrl c, LABEL_FAA144

LABEL_FAA201:
	cp bc, 0x80
	jr nz, LABEL_FAA20D
	pop xiz
	lda xsp, (xsp + 16)

LABEL_FAA20B:
	jr LABEL_FAA20B

LABEL_FAA20D:
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
	cps hl, 0
	jr z, LABEL_FAA24E
	ld xwa, (xsp + 24)
	push xwa
	push xiz
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	calr SetApTimer
	lds hl, 1
	jr LABEL_FAA250

LABEL_FAA24E:
	lds hl, 0

LABEL_FAA250:
	pop xiz
	lda xsp, (xsp + 12)
	retd 0x8

KillApTimer:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld16_24 xix, 0x030448
	cp ix, 0xFFFF
	jrl z, LABEL_FAA2F2
	lda_24 xiy, 0x02f844

LABEL_FAA26E:
	ld wa, ix
	muls wa, 0x18
	st_dri3b C, 0x07, 0xF4, 0xE0
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
	cp wa, 0xFFFF
	jr z, LABEL_FAA2B2
	muls wa, 0x18
	ld iz, wa
	ld wa, (xhl)
	st_dri3w WA, 0x07, 0xF4, 0xF8

LABEL_FAA2B2:
	cpw (xhl), 0xFFFF
	jr z, LABEL_FAA2C8
	ld wa, (xhl)
	muls wa, 0x18
	st_dri3b E, 0x07, 0xF4, 0xE0
	ld wa, (xbc)
	ld (xiy + 2), wa

LABEL_FAA2C8:
	cpda16_24 xix, 197704
	jr nz, LABEL_FAA2D6
	ld wa, (xbc)
	st16_24 0x030448, xwa

LABEL_FAA2D6:
	ld xwa, 0xFFFFFFFF
	ld (xde), xwa
	ldw (xbc), 0xFFFF
	ldw (xhl), 0xFFFF
	lds hl, 1
	jr LABEL_FAA2F4

ApTimer_KillApTimer_CheckNextEntry:
	ld ix, (xiz)
	cp ix, 0xFFFF
	jrl nz, LABEL_FAA26E

LABEL_FAA2F2:
	lds hl, 0

LABEL_FAA2F4:
	pop xiz
	inc 4, xsp
	retd 0x8
	push xiz

DrawTask_EventLoop:
	calr LABEL_FAA356
	ld xiz, xhl
	cpdi16_24 257870, 0
	jr z, DrawTask_FuncDispatch
	lds wa, 5
	lds bc, 3
	call TaskSched_ChangePriority

; DrawTask function dispatch with priority
DrawTask_FuncDispatch:
	or xiz, xiz
	jr z, LABEL_FAA333
	ld xhl, (xiz)
	ld xwa, xiz
	call (xhl)
	ld xwa, xiz
	calr DrawFunc_Return
	cpdi16_24 257870, 0
	jr z, DrawTask_EventLoop
	lds wa, 5
	lds bc, 3
	call TaskSched_ChangePriority
	jr DrawTask_EventLoop

LABEL_FAA333:
	ld16_24 xwa, 0x030450
	st16_24 0x03044e, xwa
	lds wa, 1
	call Audio_Lock_Acquire
	jr DrawTask_EventLoop

InitDrawTask:
	jr __jrt_nop_FAA347
__jrt_nop_FAA347:

LABEL_FAA347:
	lds wa, 3
	call TaskSched_WaitForEvent
	calr LABEL_FAA39D
	lds wa, 3
	jp TaskSched_SignalEvent

LABEL_FAA356:
	push xiz
	lds wa, 3
	call TaskSched_WaitForEvent
	calr LABEL_FAA3CB
	ld xiz, xhl
	lds wa, 3
	call TaskSched_SignalEvent
	ld xhl, xiz
	pop xiz
	ret


; ============================================================================
; DisplayCmd_DequeueAndExecute - Dequeue and execute display commands
; ============================================================================
; Input:  XWA = display context pointer
; Output: XHL = result (0 = no commands, non-zero = command data pointer)
; Waits for display event (event 3), dequeues a command from the draw queue,
; signals completion, and adjusts task priority when the queue is empty.
; Core display refresh loop using TaskSched_WaitForEvent/SignalEvent.
; ============================================================================
DisplayCmd_DequeueAndExecute:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa

LABEL_FAA372:
	lds wa, 3
	call TaskSched_WaitForEvent
	ld xwa, (xsp + 4)
	calr LABEL_FAA3EB
	ld xiz, xhl
	lds wa, 3
	call TaskSched_SignalEvent
	or xiz, xiz
	jr nz, LABEL_FAA392
	lds wa, 5
	lds bc, 2
	call TaskSched_ChangePriority

LABEL_FAA392:
	or xiz, xiz
	jr z, LABEL_FAA372
	ld xhl, xiz
	pop xiz
	inc 4, xsp
	ret

LABEL_FAA39C:
	.byte 0x0e

LABEL_FAA39D:
	lda_24 xde, 0x03247c
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x7F
	lda_24 xwa, 0x030466
	st32_24 0x032466, xwa
	st32_24 0x03246a, xwa
	ret

LABEL_FAA3CB:
	lda_24 xde, 0x03247c
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, LABEL_FAA3DB
	lds32 xhl, 0
	ret

LABEL_FAA3DB:
	ld_sril3 XHL, 0x07, 0xE8, 0xF0
	minc4_16 ix, 0x7C
	ld (xde - 8), ix
	incm 4, (xde - 2)
	ret

LABEL_FAA3EB:
	lda_24 xde, 0x03247c
	cpw (xde - 2), 0x4
	jr gt, LABEL_FAA3FB
	lda_dd8l XHL, 0x00
	ret

LABEL_FAA3FB:
	ld ix, (xde - 4)
	st_dri3l XWA, 0x07, 0xE8, 0xF0
	minc4_16 ix, 0x7C
	ld (xde - 4), ix
	decm 4, (xde - 2)
	ld hl, ix
	extz xhl
	add xhl, xde
	push xhl
	ldb a, 0x1
	call Audio_Lock_Release
	pop xhl
	ret

LABEL_FAA41C:
	ld16_24 xix, 0x032474
	st16_24 0x032472, xix
	ret

LABEL_FAA427:
	lda_24 xde, 0x03247c
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, LABEL_FAA437
	lds32 xhl, 0
	ret

LABEL_FAA437:
	ld_sril3 XHL, 0x07, 0xE8, 0xF0
	minc4_16 ix, 0x7C
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
	lds wa, 4
	call Audio_Lock_Acquire
	ld de, iz
	extz xde
	lda_24 xhl, 0x030466
	ld32_24 xbc, 0x03246a
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xde
	ld de, iz
	extz xde
	cp xwa, 0x2000
	jr ge, LABEL_FAA478
	ld xiz, xbc
	add xbc, xde
	st32_24 0x03246a, xbc
	jr DrawFunc_CallHandler

LABEL_FAA478:
	ld xiz, xhl
	add xhl, xde
	st32_24 0x03246a, xhl

; DrawFunc handler with audio lock release
DrawFunc_CallHandler:
	lds wa, 4
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
	cps hl, 0
	jr z, LABEL_FAA49E
	push xiz
	ld xhl, xiz
	call (xhl)
	pop xiz
	jr LABEL_FAA4D6

LABEL_FAA49E:
	lds wa, 3
	call TaskSched_WaitForEvent
	calr LABEL_FAA41C
	jr LABEL_FAA4B4

LABEL_FAA4A9:
	lda xbc, (xhl + 4)
	cp xiz, (xbc)
	jr nz, LABEL_FAA4B4
	lds32 xwa, 0
	ld (xbc), xwa

LABEL_FAA4B4:
	calr LABEL_FAA427
	or xhl, xhl
	jr nz, LABEL_FAA4A9
	lds wa, 3
	call TaskSched_SignalEvent
	ldw wa, 0x8
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaa4d8
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DisplayCmd_DequeueAndExecute

LABEL_FAA4D6:
	pop xiz
	ret

; DrawFunc stack handler
DrawFunc_StackHandler:
	push	xiz
	ld	xiz, xwa
	ld	xwa, (xiz+4)
	or	xwa, xwa
	jr	z, 7
	push	xiz
	ld	xhl, (xiz+4)
	call	(xhl)
	pop	xiz
	pop	xiz
	ret
	ret

DrawFunc_StackEntry:
	ld xwa, (xsp + 4)
	jr DrawFunc
	push xiz
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, LABEL_FAA503
	push xiz
	ld xhl, xiz
	call (xhl)
	pop xiz
	jr LABEL_FAA518

LABEL_FAA503:
	ldw wa, 0x8
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaa4d8
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DisplayCmd_DequeueAndExecute

LABEL_FAA518:
	pop xiz
	ret

; DrawFunc XSP region check variant
DrawFunc_XspCheck:
	push	xiz
	ld	xiz, xwa
	ld	xwa, (xiz+4)
	or	xwa, xwa
	jr	z, 7
	push	xiz
	ld	xhl, (xiz+4)
	call	(xhl)
	pop	xiz
	pop	xiz
	ret
	ld	xwa, (xsp+4)
	jr	-65


IS_XSP_INSIDE_4K_REGION_AT_1C032:
	xor xhl, xhl
	cp xsp, 0x1C032
	jr lt, LABEL_FAA546
	cp xsp, 0x1D032
	jr gt, LABEL_FAA546
	inc 1, xhl

LABEL_FAA546:
	ret

InitializeGraphics:
	dec 8, xsp
	push xiz
	calr InitDrawTask
	lds wa, 5
	call Show_ScreenGroup
	sti16_24 0x03ef92, 0x0001
	call InitPaletteRGB
	lds wa, 0
	calr ChangeWall
	lds wa, 2
	calr ChangePalette
	lds wa, 0
	calr ChangeWallPalette
	lda_24 xwa, 0x043c00
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
	ldw (xwa + 4), 0x13F
	ldw (xwa + 6), 0xEF
	calr SetChangeRect
	calr UpdateScreen
	calr LcdOn
	pop xiz
	inc 8, xsp
	ret

; LcdOn - Enable LCD display output (sets flag at 0x030464)
LcdOn:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, LABEL_FAA5D0
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaa5ce
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute

LABEL_FAA5CE:
	jr __jrt_nop_FAA5D0
__jrt_nop_FAA5D0:

LABEL_FAA5D0:
	sti16_24 0x030464, 0x0001
	jp LABEL_FB318A

; LcdOff - Disable LCD display output (clears flag at 0x030464)
LcdOff:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, LABEL_FAA5F5
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaa5f3
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute

LABEL_FAA5F3:
	jr __jrt_nop_FAA5F5
__jrt_nop_FAA5F5:

LABEL_FAA5F5:
	call LABEL_FB319A
	sti16_24 0x030464, 0x0000
	ret


LABEL_FAA601:
	cpdi16_24 197732, 0
	ret z

	call LABEL_FB318A
	ret


LABEL_FAA60F:
	cpdi16_24 197732, 0
	ret z

	call LABEL_FB319A
	ret
LABEL_FAA61D:


; =============================================================================
; UpdateScreen - Blit offscreen buffer to VRAM (main display update)
;
; Called from the main loop to copy changed regions from OFFSCREEN_BUFFER_1
; (0x43C00) to VIDEO_RAM (0x1A0000). The actual blit is performed by
; Gfx_BlitDirtyRegions which:
;
; 1. Checks if palette update is pending (0x03EF9E palette index)
;    - Full palette update: iterates all 256 DAC entries (0x00-0xFF)
;    - Partial palette update: iterates entries 0xE0-0xEF only
; 2. Examines dirty bounding box at 0x030456:
;    - If full screen (0,0)-(319,239): calls full-screen blit (0xFB30A9)
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
	cps hl, 0
	jr z, LABEL_FAA636
	calr Gfx_BlitDirtyRegions
	ld16_24 xwa, 0x030450
	cps wa, 0
	ret nz
	st16_24 0x03044e, xwa
	ret

LABEL_FAA636:
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaa648
	ld (xwa), xbc
	calr DisplayCmd_DequeueAndExecute
	ret

LABEL_FAA648:
	.byte 0x1e, 0x0f, 0x00, 0xd2, 0x50, 0x04, 0x03, 0x20
	.byte 0xd8, 0xd8, 0xb0, 0xfe, 0xf2, 0x4e, 0x04, 0x03
	.byte 0x50, 0x0e

Gfx_BlitDirtyRegions:
	dec 8, xsp
	pushw iz
	cpdi16_24 257938, 0
	jrl z, LABEL_FAA75D
	cpdi16_24 197726, 0
	jrl z, LABEL_FAA75D
	cpdi16_24 197728, 0
	jr z, LABEL_FAA6BA
	ld16_24 xwa, 0x03ef9e
	cps wa, 4
	jr nz, LABEL_FAA690
	cpdi16_24 257952, 4
	jr z, Display_CheckScreenDimensions
	cps wa, 4
	jr nz, Display_CheckScreenDimensions

LABEL_FAA690:
	calr LABEL_FAA5F5
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	lds iz, 0

LABEL_FAA69B:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	ldto_berp A, 0xF8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0x100
	jr c, LABEL_FAA69B
	jr Display_CheckScreenDimensions

LABEL_FAA6BA:
	cpdi16_24 197730, 0
	jr z, Display_CheckScreenDimensions
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	ldw iz, 0xE0

LABEL_FAA6CC:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	ldto_berp A, 0xF8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0xF0
	jr c, LABEL_FAA6CC

Display_CheckScreenDimensions:
	lda_24 xwa, 0x030456
	ld bc, (xwa + 6)
	sub bc, (xwa + 2)
	cp bc, 0xEF
	jr nz, LABEL_FAA70B
	ld bc, (xwa + 4)
	sub bc, (xwa)
	cp bc, 0x13F
	jr nz, LABEL_FAA70B
	call AllBOut
	jr LABEL_FAA70F

LABEL_FAA70B:
	call DisplayBuffer_Process

LABEL_FAA70F:
	cpdi16_24 197728, 0
	jr z, LABEL_FAA72E
	calr LABEL_FAA5D0
	ld16_24 xwa, 0x03ef9e
	st16_24 0x03efa0, xwa
	sti16_24 0x030460, 0x0000
	jr LABEL_FAA737

LABEL_FAA72E:
	cpdi16_24 197730, 0
	jr z, LABEL_FAA73E

LABEL_FAA737:
	sti16_24 0x030462, 0x0000

LABEL_FAA73E:
	sti16_24 0x03045e, 0x0000
	lda_24 xwa, 0x030456
	ldw (xwa + 2), 0xF0
	ldw (xwa), 0x140
	ldw (xwa + 4), 0xFFFF
	ldw (xwa + 6), 0xFFFF

LABEL_FAA75D:
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
; The bounding box is maintained at 0x030456-0x03045C and an update flag
; is set at 0x03045E.
;
; Input:
;   XWA = pointer to 8-byte rect structure {x_min, y_min, x_max, y_max}
; =============================================================================
SetChangeRect:
	push xiz
	ld xiz, xwa
	cpdi16_24 257870, 0
	jr z, LABEL_FAA776
	lds wa, 5
	lds bc, 3
	call TaskSched_ChangePriority

LABEL_FAA776:
	sti16_24 0x03045e, 0x0001
	lda_24 xde, 0x030456
	lda xbc, (xde + 2)
	ld wa, (xiz + 2)
	cp (xbc), wa
	jr le, LABEL_FAA78E
	ld (xbc), wa

LABEL_FAA78E:
	ld wa, (xde)
	cp wa, (xiz)
	jr le, LABEL_FAA798
	ld wa, (xiz)
	ld (xde), wa

LABEL_FAA798:
	lda xbc, (xde + 4)
	ld wa, (xiz + 4)
	cp (xbc), wa
	jr ge, LABEL_FAA7A4
	ld (xbc), wa

LABEL_FAA7A4:
	lda xbc, (xde + 6)
	ld wa, (xiz + 6)
	cp (xbc), wa
	jr ge, LABEL_FAA7B0
	ld (xbc), wa

LABEL_FAA7B0:
	pop xiz
	ret

; =============================================================================
; ReadPixel - Read a pixel color from offscreen buffer 1
;
; Reads the 8-bit color index at (x, y) from OFFSCREEN_BUFFER_1 (0x43C00).
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
	cps hl, 0
	jr z, LABEL_FAA7E0
	ld wa, (xiz + 2)
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xiz)
	exts xwa
	add xwa, xbc
	ld xbc, 0x43C00
	add xbc, xwa
	ld l, (xbc)
	extz hl
	jr LABEL_FAA7E2

LABEL_FAA7E0:
	lds hl, 0

LABEL_FAA7E2:
	pop xiz
	ret

; =============================================================================
; ModifyPixel - Write a pixel to offscreen buffer 1
;
; Sets a single pixel at (x, y) in OFFSCREEN_BUFFER_1 (0x43C00).
; Color 0xF7 is treated as transparent (no-op). Color 0xF5 triggers a
; read-back from a secondary buffer (at address stored at 0x0304B2).
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
	cps hl, 0
	jr z, LABEL_FAA840
	cp iz, 0xF7
	jr z, LABEL_FAA840
	cp iz, 0xF5
	jr nz, LABEL_FAA81C
	ld xwa, (xsp + 2)
	ld bc, (xwa + 2)
	muls bc, 0x140
	add bc, (xwa)
	extz xbc
	addda32_24 xbc, 197714
	ld a, (xbc)
	ldfr_berp A, 0xF8
	extz iz

LABEL_FAA81C:
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
	ld xbc, 0x43C00
	add xbc, xwa
	ldto_berp A, 0xF8
	ld (xbc), a

LABEL_FAA840:
	popw iz
	inc 4, xsp
	ret

; =============================================================================
; ModifyPixelEx - Extended pixel operation with multiple drawing modes
;
; Performs a pixel operation at (x, y) in OFFSCREEN_BUFFER_1 (0x43C00)
; using one of several drawing modes specified by DE.
;
; Input:
;   XWA = pointer to coordinate pair: word[0]=x, word[2]=y
;   BC  = color index (low byte)
;   DE  = drawing mode:
;         < 0x201: use translated buffer pointer
;         0x201: direct write  — buffer[y*320+x] = color
;         0x202: clear pixel   — buffer[y*320+x] = 0x00
;         0x203: OR operation  — buffer[y*320+x] |= color
;         0x204: AND operation — buffer[y*320+x] &= color
;         0x205: XOR operation — buffer[y*320+x] ^= color
;
; Special colors:
;   0xF7 = transparent (no-op)
;   0xF5 = read-back from secondary buffer (0x0304B2)
; =============================================================================
ModifyPixelEx:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), de
	ld iz, bc
	ld (xsp + 4), xwa
	ld xwa, (xsp + 4)
	calr IsPointOnScreen
	cps hl, 0
	jrl z, DrawLine_Epilogue
	ld wa, iz
	calr IsColorValid
	cps hl, 0
	jrl z, DrawLine_Epilogue
	ld xwa, (xsp + 4)
	ld bc, iz
	calr ClampColorToRange
	ld iz, hl
	cp iz, 0xF7
	jrl z, DrawLine_Epilogue
	cp iz, 0xF5
	jr nz, LABEL_FAA895
	ld xwa, (xsp + 4)
	ld bc, (xwa + 2)
	muls bc, 0x140
	add bc, (xwa)
	extz xbc
	addda32_24 xbc, 197714
	ld a, (xbc)
	ldfr_berp A, 0xF8
	extz iz

LABEL_FAA895:
	cpw (xsp + 2), 0x201
	jr ge, LABEL_FAA8CF
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
	ld xbc, 0x43C00
	add xbc, xwa
	ld wa, (xsp + 2)
	ld (xbc), a
	jrl DrawLine_Epilogue

LABEL_FAA8CF:
	ldto_berp C, 0xF8
	cpw (xsp + 2), 0x205
	jrl z, LABEL_FAA965
	lda_24 xde, 0x043c00
	cpw (xsp + 2), 0x204
	jr z, LABEL_FAA947
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
	jr z, LABEL_FAA938
	cpw (xsp + 2), 0x202
	jr z, LABEL_FAA91D
	cpw (xsp + 2), 0x201
	jr nz, DrawLine_Epilogue
	ld wa, (xiy)
	exts xwa
	add xwa, xde
	add xhl, xwa
	ld (xhl), c
	jr DrawLine_Epilogue

LABEL_FAA91D:
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

LABEL_FAA938:
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	add xhl, xwa
	or (xhl), c
	jr DrawLine_Epilogue

LABEL_FAA947:
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

LABEL_FAA965:
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
	ld xde, 0x43C00
	add xde, xwa
	xor (xde), c

	.include "ui/drawing_primitives.s"
