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
	cp xiz, 0x1e0008d
	jrl z, AcGridBox_CellSelect
	cp xiz, 0x1e0008b
	jrl z, AcGridBox_GetRowText
	cp xiz, 0x1e0008a
	jrl z, AcGridBox_GetColText
	cp xiz, 0x1c00001
	jr z, AcGridBox_Init
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, AcGridBox_Default
	cp xwa, 0x6
	jrl gt, AcGridBox_Default
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x386
	ld wa, (xwa)
	lda_24 xix, (AcGridBox_Init)
	jp_ind 8, 0x07, 0xf0, 0xe0

AcGridBox_Init:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	calr SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	calr SetDialDown
	lds wa, 1
	jrl AcGridBox_EnableDials
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollUp_Alt
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00019
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollUp_Alt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
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
	ld xbc, 0x1c00019
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	calr SetDialDown
	lds wa, 1
	jrl AcGridBox_EnableDials
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	calr PsGridBoxProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcGridBox_ScrollDown_Alt
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	calr SetAutoInc
	jrl AcGridBox_ReturnZero

AcGridBox_ScrollDown_Alt:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
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
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	calr SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	calr SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	calr SetDialDown
	lds wa, 1

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
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	19
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
	cp xbc, 0x1e0008d
	jr z, GridCheck_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jr lt, GridCheck_Return
	cp xwa, 0x6
	jr gt, GridCheck_Return
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x39A
	ld wa, (xwa)
	lda_24 xix, (GridCheck_JumpEnd)
	jp_ind 8, 0x07, 0xf0, 0xe0

GridCheck_JumpEnd:
	jr	t, 0x3d

GridCheck_CellSelect:
	.byte 0xbf, 0x0a, 0x31, 0xea, 0x88, 0xe8, 0xef, 0x00
	.byte 0xd7, 0xe2, 0xa8, 0xb1, 0x50, 0xb9, 0x02, 0x30
	.byte 0xb0, 0x52, 0xb7, 0x32, 0xb9, 0x04, 0x62, 0x90
	.byte 0x04, 0x91, 0x04, 0x0b, 0xea, 0x00, 0x0b, 0x66
	.byte 0xa2, 0x3a, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x1d, 0xc3, 0x40, 0xfa, 0xeb, 0x88, 0xbf
	.byte 0x0a, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xeb, 0xa8
GridCheck_Return:
	lda xsp, (xsp + 18)
	ret

PsEditBoxProc:
	stb_dri L, 0xfd, 0xe4, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x18, 0x02
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x1c, 0x02
	cp xiz, 0x1e0003c
	jrl z, PsEditBox_CanScroll
	cp xiz, 0x1c00018
	jrl z, PsEditBox_ScrollDown
	cp xiz, 0x1c00017
	jrl z, PsEditBox_ScrollUp
	cp xiz, 0x1c0001b
	jrl z, PsEditBox_Release
	cp xiz, 0x1c00007
	jrl z, PsEditBox_OK
	cp xiz, 0x1e0003a
	jrl z, PsEditBox_GetText
	cp xiz, 0x1c0000f
	jrl z, PsEditBox_Confirm
	cp xiz, 0x1c0000e
	jrl z, PsEditBox_Select
	cp xiz, 0x1c0000d
	jrl z, PsEditBox_Paint
	cp xiz, 0x1c00001
	jrl z, PsEditBox_Init
	cp xiz, 0x1e0004d
	jrl nz, PsEditBox_Default
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld xiz, xhl
	lda xwa, (xiz + 46)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x18, 0x02
	jr z, PsEditBox_SetIndex_CheckDial
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x0218)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c00017
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c00018
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
	ld xbc, 0x1c00017
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c00018
	calr SetDialDown
	lds wa, 1

PsEditBox_Init_EnableDials:
	calr SetDialEnable

PsEditBox_ReturnZero:
	lds32 xhl, 0
	jrl PsEditBox_Return

PsEditBox_Paint:
	.byte 0xe3, 0xfd, 0x1c, 0x02, 0x20, 0xee, 0x89, 0xe3
	.byte 0xfd, 0x18, 0x02, 0x22, 0x1e, 0x4e, 0xdf, 0xe3
	.byte 0xfd, 0x1c, 0x02, 0x20, 0x1d, 0x59, 0x5e, 0xfa
	.byte 0xbf, 0x08, 0x63, 0xaf, 0x08, 0x20, 0xbf, 0x04
	.byte 0x60, 0x98, 0x2a, 0x20, 0x1e, 0xd7, 0xdc, 0xf3
	.byte 0xfd, 0x0c, 0x02, 0x31, 0xe3, 0xfd, 0x1c, 0x02
	.byte 0x20, 0x1e, 0x20, 0xa8, 0xf3, 0xfd, 0x0c, 0x01
	.byte 0x31, 0xaf, 0x08, 0x20, 0xa8, 0x1c, 0x20, 0x1d
	.byte 0x33, 0x22, 0xfb, 0xf3, 0xfd, 0x0c, 0x01, 0x30
	.byte 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xaf, 0x0c, 0x20
	.byte 0x98, 0x28, 0x26, 0xdb, 0x86, 0xf3, 0xfd, 0x10
	.byte 0x01, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef
	.byte 0x60, 0xf3, 0xfd, 0x0c, 0x02, 0x30, 0xb8, 0x04
	.byte 0x32, 0x92, 0x21, 0x90, 0xa1, 0xdb, 0x41, 0xe9
	.byte 0x12, 0xde, 0x51, 0x90, 0x23, 0xd9, 0x83, 0xb2
	.byte 0x53, 0xf3, 0xfd, 0x14, 0x02, 0x31, 0x1e, 0x90
	.byte 0xa9, 0xf3, 0xfd, 0x0c, 0x02, 0x30, 0xf3, 0xfd
	.byte 0x14, 0x02, 0x32, 0xaf, 0x08, 0x23, 0xab, 0x20
	.byte 0x21, 0x39, 0x9b, 0x24, 0x04, 0xaf, 0x0a, 0x21
	.byte 0x99, 0x16, 0x04, 0x89, 0x26, 0x23, 0xd9, 0x12
	.byte 0x29, 0xab, 0x1c, 0x23, 0xea, 0x89, 0xeb, 0x8a
	.byte 0x1d, 0x3c, 0xcc, 0xfa, 0xe3, 0xfd, 0x1c, 0x02
	.byte 0x20, 0x41, 0x0e, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x78, 0x84, 0x01
PsEditBox_Select:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	cpw (xhl + 42), 0xff
	jrl z, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1e0004e
	jrl PsEditBox_Dispatch

PsEditBox_Confirm:
	.byte 0xe3, 0xfd, 0x1c, 0x02, 0x20, 0x1d, 0x59, 0x5e
	.byte 0xfa, 0xbf, 0x08, 0x63, 0xf3, 0xfd, 0x0c, 0x02
	.byte 0x31, 0xe3, 0xfd, 0x1c, 0x02, 0x20, 0x1e, 0x5b
	.byte 0xa7, 0xf3, 0xfd, 0x0c, 0x01, 0x31, 0xaf, 0x08
	.byte 0x20, 0xa8, 0x1c, 0x20, 0x1d, 0x33, 0x22, 0xfb
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x30, 0x38, 0x1d, 0xc3
	.byte 0x07, 0xff, 0xef, 0x64, 0xaf, 0x08, 0x20, 0x98
	.byte 0x28, 0x21, 0xd9, 0x8d, 0xdb, 0x85, 0xf3, 0xfd
	.byte 0x0c, 0x02, 0x30, 0xb8, 0x04, 0x33, 0x93, 0x22
	.byte 0xda, 0x8c, 0x90, 0xa4, 0xdc, 0x41, 0xe9, 0x12
	.byte 0xdd, 0x51, 0xd9, 0xa2, 0xb0, 0x52, 0x93, 0x6e
	.byte 0xf3, 0xfd, 0x14, 0x02, 0x31, 0x1e, 0xd1, 0xa8
	.byte 0xbf, 0x0c, 0x32, 0xe3, 0xfd, 0x18, 0x02, 0x20
	.byte 0xe8, 0xe0, 0x6e, 0x17, 0xe3, 0xfd, 0x1c, 0x02
	.byte 0x20, 0x41, 0x3a, 0x00, 0xe0, 0x01, 0x1d, 0x53
	.byte 0x92, 0xfa, 0x8f, 0x0c, 0x3f, 0x00, 0x6e, 0x10
	.byte 0x78, 0x98, 0xfe
PsEditBox_Confirm_CopyText:
	ld	xwa, (xsp+536)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsEditBox_Confirm_Render:
	ld xiy, (xsp + 8)
	ld xbc, (xiy + 32)
	stb_dri W, 0xfd, 0x0c, 0x02
	stb_dri C, 0xfd, 0x14, 0x02
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
	cpl_sri_rm XWA, 0xfd, 0x18, 0x02
	jr nz, PsEditBox_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, PsEditBox_OK_Forward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1e0004d
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
	cpl_sri_rm XWA, 0xfd, 0x18, 0x02
	jrl nz, PsEditBox_ReturnZero
	ld xwa, (xhl + 46)
	cpw (xwa), 0x0
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1e0004d
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
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c00019
	ld_sril XDE, (xsp + 0x0218)
	jr PsEditBox_SetAutoInc

PsEditBox_ScrollDown:
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0218)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x0218)
	call SendEvent
	or xhl, xhl
	jrl z, PsEditBox_ReturnZero
	ld_sril XWA, (xsp + 0x021c)
	ld xbc, 0x1c0001a
	ld_sril XDE, (xsp + 0x0218)

PsEditBox_SetAutoInc:
	calr SetAutoInc
	jrl PsEditBox_ReturnZero

PsEditBox_CanScroll:
	ld_sril XWA, (xsp + 0x021c)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x18, 0x02
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
	stb_dri L, 0xfd, 0x1c, 0x02
	ret

PsNumEditBoxProc:
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 34), xde
	ld (xsp + 38), xbc
	ld (xsp + 42), xwa
	ld xwa, (xsp + 38)
	cp xwa, 0x1c0000f
	jr z, PsNumEditBox_Confirm
	ld xwa, (xsp + 42)
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	calr PsEditBoxProc
	jr PsNumEditBox_Return

PsNumEditBox_Confirm:
	.byte 0xaf, 0x2a, 0x20, 0x1d, 0x59, 0x5e, 0xfa, 0xeb
	.byte 0x8e, 0x0b, 0xea, 0x00, 0x0b, 0x7a, 0xa2, 0xbf
	.byte 0x1c, 0x30, 0x38, 0x1d, 0x70, 0x07, 0xff, 0x9e
	.byte 0x32, 0x04, 0x0b, 0xea, 0x00, 0x0b, 0x7c, 0xa2
	.byte 0xbf, 0x1c, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff
	.byte 0xbf, 0x20, 0x30, 0x38, 0xbf, 0x2e, 0x30, 0x38
	.byte 0x1d, 0xe4, 0x05, 0xff, 0xbf, 0x1a, 0x37, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x80, 0xa2, 0xbf, 0x1c, 0x30
	.byte 0x38, 0x1d, 0xe4, 0x05, 0xff, 0xaf, 0x2a, 0x20
	.byte 0x38, 0xbf, 0x24, 0x30, 0x38, 0xbf, 0x14, 0x30
	.byte 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x14, 0x37
	.byte 0xbf, 0x04, 0x32, 0xaf, 0x2a, 0x20, 0xaf, 0x26
	.byte 0x21, 0x1e, 0x38, 0xfb, 0xeb, 0xa8
PsNumEditBox_Return:
	pop xiz
	lda xsp, (xsp + 42)
	ret

PsTblEditBoxProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	stl_dri XBC, 0xfd, 0x08, 0x01
	ld xiz, xwa
	ld_sril XWA, (xsp + 0x0108)
	cp xwa, 0x1c0000f
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
	ld xbc, 0x1e0004c
	call ApFuncCall
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0108)
	calr PsEditBoxProc
	lds32 xhl, 0

PsTblEditBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret

PasTableCheck:
	cp	xbc, 31457356
	jr	nz, 22
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, 15377026
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PasTableCheck_Return:
	lds32 xhl, 0
	ret

AcOnOffBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, AcOnOff_ScrollDown
	cp xbc, 0x1c00017
	jrl z, AcOnOff_ScrollUp
	cp xbc, 0x1e0006b
	jr z, AcOnOff_GetValue
	cp xbc, 0x1e0003b
	jr z, AcOnOff_SetValue
	cp xbc, 0x1e0003a
	jr z, AcOnOff_GetText
	cp xbc, 0x1c0000d
	jrl nz, AcOnOff_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcOnOff_Dispatch

AcOnOff_GetText:
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xhl+50)
	ld	wa, (xwa)
	extz	xwa
	sll	xwa, 2
	ld	xbc, 15377050
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	129
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1e0003b
	lds32 xde, 1
	jr AcOnOff_Dispatch

AcOnOff_ScrollDown:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsEditBoxProc
	ld xwa, xiz
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcOnOff_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1e0003b
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
	cp xbc, 0x1c00018
	jrl z, AcNumEdit_ScrollDown
	cp xbc, 0x1c0001a
	jrl z, AcNumEdit_AutoIncDown
	cp xbc, 0x1c00017
	jrl z, AcNumEdit_ScrollUp
	cp xbc, 0x1c00019
	jrl z, AcNumEdit_AutoIncUp
	cp xbc, 0x1e0006b
	jrl z, AcNumEdit_GetValue
	cp xbc, 0x1e0003d
	jrl z, AcNumEdit_AddDelta
	cp xbc, 0x1e0003b
	jrl z, AcNumEdit_SetValue
	cp xbc, 0x1e0003a
	jr z, AcNumEdit_GetText
	cp xbc, 0x1c0000d
	jrl nz, AcNumEdit_Default
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcNumEdit_Dispatch

AcNumEdit_GetText:
	.byte 0xaf, 0x20, 0x20, 0x1d, 0x59, 0x5e, 0xfa, 0xbf
	.byte 0x04, 0x63, 0x0b, 0xea, 0x00, 0x0b, 0xaa, 0xa2
	.byte 0xbf, 0x16, 0x30, 0x38, 0x1d, 0x70, 0x07, 0xff
	.byte 0xaf, 0x0c, 0x20, 0x98, 0x36, 0x04, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xac, 0xa2, 0xbf, 0x16, 0x30, 0x38
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x1a, 0x30, 0x38
	.byte 0xbf, 0x28, 0x30, 0x38, 0x1d, 0xe4, 0x05, 0xff
	.byte 0xbf, 0x1a, 0x37, 0x0b, 0xea, 0x00, 0x0b, 0xb0
	.byte 0xa2, 0xbf, 0x16, 0x30, 0x38, 0x1d, 0xe4, 0x05
	.byte 0xff, 0xaf, 0x0c, 0x20, 0xa8, 0x32, 0x20, 0x90
	.byte 0x04, 0xbf, 0x1c, 0x30, 0x38, 0xaf, 0x2a, 0x20
	.byte 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x12, 0x37
	.byte 0x78, 0x5e, 0x01
AcNumEdit_SetValue:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xbc, (xhl + 50)
	ld xwa, (xsp + 28)
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jrl z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003d
	jrl AcNumEdit_Dispatch

AcNumEdit_ScrollUp:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003d
	jr AcNumEdit_Dispatch

AcNumEdit_AutoIncDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 60)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003d
	jr AcNumEdit_Dispatch

AcNumEdit_ScrollDown:
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	calr PsEditBoxProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 28)
	call SendEvent
	or xhl, xhl
	jr z, AcNumEdit_ReturnZero
	ld de, (xiz + 62)
	neg de
	exts xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0003d

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
	cp xbc, 0x1c00031
	jrl z, AcLswEdit_ResetBtn
	cp xbc, 0x1c00018
	jrl z, AcLswEdit_ScrollDown
	cp xbc, 0x1c0001a
	jrl z, AcLswEdit_AutoIncDown
	cp xbc, 0x1c00017
	jrl z, AcLswEdit_ScrollUp
	cp xbc, 0x1c00019
	jrl z, AcLswEdit_AutoIncUp
	cp xbc, 0x1c0001c
	jrl z, AcLswEdit_Match
	cp xbc, 0x1c0000c
	jrl z, AcLswEdit_ShowHide
	cp xbc, 0x1c0000b
	jrl z, AcLswEdit_ShowHide
	cp xbc, 0x1c00002
	jrl z, AcLswEdit_Close
	cp xbc, 0x1c00001
	jrl z, AcLswEdit_Init
	cp xbc, 0x1e0003d
	jrl z, AcLswEdit_AddDelta
	cp xbc, 0x1e0003b
	jr z, AcLswEdit_SetValue
	cp xbc, 0x1e0003a
	jrl nz, AcLswEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00040
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
	ld xbc, 0x1e00042
	call ApFuncCall
	jrl AcLswEdit_ReturnZero

AcLswEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00040
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
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
	ld xbc, 0x1e00040
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 8), wa
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
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
	ld xbc, 0x1e00040
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
	ld xbc, 0x1e00040
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
	ld xbc, 0x1e00083
	call ApFuncCall
	ld xwa, (xsp + 26)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003d
	jrl AcLswEdit_Dispatch

AcLswEdit_ScrollUp:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003d
	jrl AcLswEdit_Dispatch

AcLswEdit_AutoIncDown:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003d
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AcLswEdit_Dispatch

AcLswEdit_ResetBtn:
	ld xwa, (xsp + 26)
	ld xde, (xsp + 22)
	calr PsEditBoxProc
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e000b8
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e000b9
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003b

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
	.byte 0x3e, 0xe8, 0x8e, 0xe9, 0xcf, 0x83, 0x00, 0xe0
	.byte 0x01, 0x66, 0x4f, 0xe9, 0xcf, 0x3f, 0x00, 0xe0
	.byte 0x01, 0x66, 0x3f, 0xe9, 0xcf, 0x3e, 0x00, 0xe0
	.byte 0x01, 0x66, 0x3b, 0xe9, 0xcf, 0x41, 0x00, 0xe0
	.byte 0x01, 0x66, 0x2f, 0xe9, 0xcf, 0x40, 0x00, 0xe0
	.byte 0x01, 0x66, 0x20, 0xe9, 0xcf, 0x42, 0x00, 0xe0
	.byte 0x01, 0x6e, 0x27, 0x9a, 0x04, 0x04, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xb2, 0xa2, 0xaa, 0x08, 0x20, 0x38
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0a, 0x37, 0xee
	.byte 0x8b, 0x68, 0x11
LswEditCheck_GetAddr:
	ld xhl, 0x1f47
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
	dec	8, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), bc
	ld	(xsp+8), xwa
	pushw	12
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	(xiz), xwa
	ld	wa, (xsp+6)
	ld	(xiz+4), wa
	ld	wa, (xsp+4)
	ld	(xiz+6), wa
	lds32	xwa, 0
	ld	(xiz+8), xwa
	ld	xwa, 20971522
	ld	xbc, 31457367
	ld	xde, xiz
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, xiz
	call	16402006
	lds	hl, 0
	pop	xiz
	inc	8, xsp
	ret
MainLswPartPut:
	dec	8, xsp
	pushw	iz
	ld	(xsp+6), de
	ld	(xsp+8), bc
	ld	iz, wa
	pushw	12
	call	16713379
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	bc, (xsp+8)
	extz	xbc
	ld	de, iz
	extz	xde
	sll	xde, 0
	add	xde, xbc
	ld	xwa, (xsp+2)
	ld	(xwa), xde
	ld	bc, (xsp+6)
	ld	(xwa+4), bc
	ld	bc, (xsp+14)
	ld	(xwa+6), bc
	lds32	xbc, 0
	ld	(xwa+8), xbc
	ld	xwa, 20971522
	ld	xbc, 31457370
	ld	xde, (xsp+2)
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, (xsp+2)
	call	16402006
	lds	hl, 0
	popw	iz
	inc	8, xsp
	retd	2
MainLswAdd:
	dec	8, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), bc
	ld	(xsp+8), xwa
	pushw	12
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	(xiz), xwa
	ld	wa, (xsp+6)
	ld	(xiz+4), wa
	ld	wa, (xsp+4)
	ld	(xiz+6), wa
	lds32	xwa, 0
	ld	(xiz+8), xwa
	ld	xwa, 20971522
	ld	xbc, 31457368
	ld	xde, xiz
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, xiz
	call	16402006
	lds	hl, 0
	pop	xiz
	inc	8, xsp
	ret
MainLswPartAdd:
	dec	8, xsp
	pushw	iz
	ld	(xsp+6), de
	ld	(xsp+8), bc
	ld	iz, wa
	pushw	12
	call	16713379
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	bc, (xsp+8)
	extz	xbc
	ld	de, iz
	extz	xde
	sll	xde, 0
	add	xde, xbc
	ld	xwa, (xsp+2)
	ld	(xwa), xde
	ld	bc, (xsp+6)
	ld	(xwa+4), bc
	ld	bc, (xsp+14)
	ld	(xwa+6), bc
	lds32	xbc, 0
	ld	(xwa+8), xbc
	ld	xwa, 20971522
	ld	xbc, 31457371
	ld	xde, (xsp+2)
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, (xsp+2)
	call	16402006
	lds	hl, 0
	popw	iz
	inc	8, xsp
	retd	2
MainLswGet:
	.byte 0xef, 0x6c, 0x3e, 0xbf, 0x04, 0x60, 0x0b, 0x0c
	.byte 0x00, 0x1d, 0xa3, 0x06, 0xff, 0xef, 0x62, 0xeb
	.byte 0x8e, 0xaf, 0x04, 0x20, 0xb6, 0x60, 0xbe, 0x04
	.byte 0x02, 0x00, 0x00, 0xbe, 0x06, 0x02, 0x00, 0x00
	.byte 0xe8, 0xa8, 0xbe, 0x08, 0x60, 0x40, 0x02, 0x00
	.byte 0x40, 0x01, 0x41, 0x59, 0x00, 0xe0, 0x01, 0xee
	.byte 0x8a, 0x1d, 0x25, 0x45, 0xfa, 0x40, 0x03, 0x00
	.byte 0x40, 0x01, 0x41, 0x23, 0x00, 0xe0, 0x01, 0xee
	.byte 0x8a, 0x1d, 0x25, 0x45, 0xfa, 0xdb, 0xa8, 0x5e
	.byte 0xef, 0x64, 0x0e
MainLswPartGet:
	.byte 0xef, 0x6e, 0x2e, 0xbf, 0x06, 0x51, 0xd8, 0x8e
	.byte 0x0b, 0x0c, 0x00, 0x1d, 0xa3, 0x06, 0xff, 0xef
	.byte 0x62, 0xbf, 0x02, 0x63, 0x9f, 0x06, 0x21, 0xe9
	.byte 0x12, 0xde, 0x8a, 0xea, 0x12, 0xea, 0xee, 0x00
	.byte 0xe9, 0x82, 0xaf, 0x02, 0x20, 0xb0, 0x62, 0xb8
	.byte 0x04, 0x02, 0x00, 0x00, 0xb8, 0x06, 0x02, 0x00
	.byte 0x00, 0xe9, 0xa8, 0xb8, 0x08, 0x61, 0x40, 0x02
	.byte 0x00, 0x40, 0x01, 0x41, 0x5c, 0x00, 0xe0, 0x01
	.byte 0xaf, 0x02, 0x22, 0x1d, 0x25, 0x45, 0xfa, 0x40
	.byte 0x03, 0x00, 0x40, 0x01, 0x41, 0x23, 0x00, 0xe0
	.byte 0x01, 0xaf, 0x02, 0x22, 0x1d, 0x25, 0x45, 0xfa
	.byte 0xdb, 0xa8, 0x4e, 0xef, 0x66, 0x0e
SetLswFilter:
	add xwa, xbc
	stl_da (0x0276c6), xwa
	ret

ResetLswFilter:
	add xwa, xbc
	stl_da (0x0276c6), xwa
	ret

AcRamEditBoxProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld (xsp + 34), xwa
	cp xbc, 0x1c00018
	jrl z, AcRamEdit_ScrollDown
	cp xbc, 0x1c0001a
	jrl z, AcRamEdit_AutoIncDown
	cp xbc, 0x1c00017
	jrl z, AcRamEdit_ScrollUp
	cp xbc, 0x1c00019
	jrl z, AcRamEdit_AutoIncUp
	cp xbc, 0x1c0001d
	jrl z, AcRamEdit_Assign
	cp xbc, 0x1c0000c
	jrl z, AcRamEdit_ShowHide
	cp xbc, 0x1c0000b
	jrl z, AcRamEdit_ShowHide
	cp xbc, 0x1e0003d
	jrl z, AcRamEdit_AddDelta
	cp xbc, 0x1e0003b
	jr z, AcRamEdit_SetValue
	cp xbc, 0x1e0003a
	jrl nz, AcRamEdit_Default
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00045
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
	ld xbc, 0x1e00047
	call ApFuncCall
	jrl AcRamEdit_ReturnZero

AcRamEdit_SetValue:
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
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
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 8)
	ld (xwa + 4), hl
	ld xbc, (xsp + 30)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 14), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
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
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00046
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
	ld xbc, 0x1e00045
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
	ld xbc, 0x1e00082
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	jrl AcRamEdit_Dispatch

AcRamEdit_ScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	jrl AcRamEdit_Dispatch

AcRamEdit_AutoIncDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsEditBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AcRamEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
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
	cp xbc, 0x1e00082
	jr z, RamEditCheck_NotHandled
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jr lt, RamEditCheck_NotHandled
	cp xwa, 0x9
	jr gt, RamEditCheck_NotHandled
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x3E8
	ld wa, (xwa)
	lda_24 xix, (RamEditCheck_JumpStart)
	jp_ind 8, 0x07, 0xf0, 0xe0

RamEditCheck_JumpStart:
	ld	xwa, (xde+14)
	push	xwa
	pushw	234
	pushw	41654
	ld	xwa, (xde+18)
	push	xwa
	call	16712341
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
	lda_24	xhl, (161482)
	jr	2
RamEditCheck_NotHandled:
	lds32 xhl, 0
	pop xiz
	ret

MainRamPut:
	.byte 0xef, 0x6c, 0x3e, 0xe8, 0x8e, 0x0b, 0x16, 0x00
	.byte 0x1d, 0xa3, 0x06, 0xff, 0xef, 0x62, 0xbf, 0x04
	.byte 0x63, 0xaf, 0x04, 0x20, 0xee, 0x8d, 0xe8, 0x8c
	.byte 0x31, 0x0b, 0x00, 0x95, 0x11, 0x40, 0x08, 0x00
	.byte 0x40, 0x01, 0x41, 0x69, 0x00, 0xe0, 0x01, 0xaf
	.byte 0x04, 0x22, 0x1d, 0x56, 0x46, 0xfa, 0x40, 0x03
	.byte 0x00, 0x40, 0x01, 0x41, 0x23, 0x00, 0xe0, 0x01
	.byte 0xaf, 0x04, 0x22, 0x1d, 0x56, 0x46, 0xfa, 0x5e
	.byte 0xef, 0x64, 0x0e
MainRamAdd:
	.byte 0xef, 0x6c, 0x3e, 0xe8, 0x8e, 0x0b, 0x16, 0x00
	.byte 0x1d, 0xa3, 0x06, 0xff, 0xef, 0x62, 0xbf, 0x04
	.byte 0x63, 0xaf, 0x04, 0x20, 0xee, 0x8d, 0xe8, 0x8c
	.byte 0x31, 0x0b, 0x00, 0x95, 0x11, 0x40, 0x08, 0x00
	.byte 0x40, 0x01, 0x41, 0x6a, 0x00, 0xe0, 0x01, 0xaf
	.byte 0x04, 0x22, 0x1d, 0x56, 0x46, 0xfa, 0x40, 0x03
	.byte 0x00, 0x40, 0x01, 0x41, 0x23, 0x00, 0xe0, 0x01
	.byte 0xaf, 0x04, 0x22, 0x1d, 0x56, 0x46, 0xfa, 0x5e
	.byte 0xef, 0x64, 0x0e
MainRamGet:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), bc
	ld	(xsp+6), xwa
	pushw	22
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, (xsp+6)
	ld	(xiz), xwa
	ld	wa, (xsp+4)
	ld	(xiz+4), wa
	lds32	xwa, 0
	ld	(xiz+6), xwa
	ld	(xiz+10), xwa
	ld	(xiz+14), xwa
	ld	(xiz+18), xwa
	ld	xwa, 20971528
	ld	xbc, 31457384
	ld	xde, xiz
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, xiz
	call	16402006
	pop	xiz
	inc	6, xsp
	ret
AcBitEditBoxProc:
	lda xsp, (xsp - 26)
	push xiz
	ld (xsp + 22), xde
	ld (xsp + 26), xwa
	cp xbc, 0x1c00018
	jrl z, AcBitEdit_ScrollDown
	cp xbc, 0x1c00017
	jrl z, AcBitEdit_ScrollUp
	cp xbc, 0x1c00024
	jrl z, AcBitEdit_Assign
	cp xbc, 0x1c0000c
	jrl z, AcBitEdit_ShowHide
	cp xbc, 0x1c0000b
	jrl z, AcBitEdit_ShowHide
	cp xbc, 0x1e0003d
	jr z, AcBitEdit_SetValue
	cp xbc, 0x1e0003b
	jr z, AcBitEdit_SetValue
	cp xbc, 0x1e0003a
	jrl nz, AcBitEdit_Default
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00063
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
	ld xbc, 0x1e00062
	call ApFuncCall
	jrl AcBitEdit_ReturnZero

AcBitEdit_SetValue:
	ld xwa, (xsp + 26)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00063
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00064
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
	ld xbc, 0x1e00063
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00064
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
	ld xbc, 0x1e00063
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 22)
	ld xwa, (xwa)
	cp xwa, xhl
	jrl nz, AcBitEdit_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00064
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00065
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollUp_SetOne
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003b
	lds32 xde, 0
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollUp_SetOne:
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003b
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
	ld xbc, 0x1e0003c
	ld xde, (xsp + 22)
	call SendEvent
	or xhl, xhl
	jr z, AcBitEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00065
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, AcBitEdit_ScrollDown_SetZero
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003b
	lds32 xde, 1
	jr AcBitEdit_Dispatch

AcBitEdit_ScrollDown_SetZero:
	ld xwa, (xsp + 26)
	ld xbc, 0x1e0003b
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
	.byte 0x3e, 0xe8, 0x8e, 0xe9, 0xcf, 0x65, 0x00, 0xe0
	.byte 0x01, 0x66, 0x49, 0xe9, 0xcf, 0x64, 0x00, 0xe0
	.byte 0x01, 0x66, 0x3a, 0xe9, 0xcf, 0x63, 0x00, 0xe0
	.byte 0x01, 0x66, 0x2b, 0xe9, 0xcf, 0x62, 0x00, 0xe0
	.byte 0x01, 0x6e, 0x31, 0x9a, 0x08, 0x20, 0xd8, 0xcc
	.byte 0x01, 0x00, 0xd8, 0xec, 0x02, 0xf2, 0xce, 0xa2
	.byte 0xea, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x38
	.byte 0xaa, 0x0a, 0x20, 0x38, 0x1d, 0x70, 0x07, 0xff
	.byte 0xef, 0x60, 0xee, 0x8b, 0x68, 0x10
BitEditCheck_GetAddr:
	lda_24 xhl, (0x0276ce)
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
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	pushw	14
	call	16713379
	ld	(xsp+6), xhl
	pushw	14
	push	xiz
	ld	xwa, (xsp+12)
	push	xwa
	call	16713148
	lda	xsp, (xsp+12)
	ld	xwa, 20971527
	ld	xbc, 31457383
	ld	xde, (xsp+4)
	call	16402006
	ld	xwa, 20971523
	ld	xbc, 31457315
	ld	xde, (xsp+4)
	call	16402006
	pop	xiz
	inc	4, xsp
	ret
MainBitGet:
	.byte 0xef, 0x68, 0x3e, 0xbf, 0x04, 0x61, 0xbf, 0x08
	.byte 0x60, 0x0b, 0x0e, 0x00, 0x1d, 0xa3, 0x06, 0xff
	.byte 0xef, 0x62, 0xeb, 0x8e, 0xaf, 0x08, 0x20, 0xb6
	.byte 0x60, 0xaf, 0x04, 0x20, 0xbe, 0x04, 0x60, 0xbe
	.byte 0x08, 0x02, 0x00, 0x00, 0xe8, 0xa8, 0xbe, 0x0a
	.byte 0x60, 0x40, 0x07, 0x00, 0x40, 0x01, 0x41, 0x66
	.byte 0x00, 0xe0, 0x01, 0xee, 0x8a, 0x1d, 0x56, 0x46
	.byte 0xfa, 0x40, 0x03, 0x00, 0x40, 0x01, 0x41, 0x23
	.byte 0x00, 0xe0, 0x01, 0xee, 0x8a, 0x1d, 0x56, 0x46
	.byte 0xfa, 0x5e, 0xef, 0x60, 0x0e
PsMenuBoxProc:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xwa
	cp xbc, 0x1e00053
	jrl z, PsMenuBox_HitTest
	cp xbc, 0x1c0000f
	jr z, PsMenuBox_Confirm
	cp xbc, 0x1c0000d
	jr z, PsMenuBox_Paint
	cp xbc, 0x1e0003a
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
	stb_dri A, 0xfd, 0x0c, 0x01
	ld xwa, xiz
	calr GetClientBox
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri A, 0xfd, 0x08, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 8)
	ld_sril XWA, (xsp + 0x0114)
	or xwa, xwa
	jr nz, PsMenuBox_Confirm_CopyText
	ld xwa, xiz
	ld xbc, 0x1e0003a
	call SendEvent
	cp (xsp + 8), 0x0
	jr nz, PsMenuBox_Confirm_Render
	jr PsMenuBox_ReturnZero

PsMenuBox_Confirm_CopyText:
	ld	xwa, (xsp+276)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsMenuBox_Confirm_Render:
	stb_dri C, 0xfd, 0x0c, 0x01
	stb_dri A, 0xfd, 0x08, 0x01
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
	ld xbc, 0x1e00029
	ld_sril XDE, (xsp + 0x0114)
	call SendEvent
	ld wa, (xiz + 36)
	extz xwa
	cp xwa, xhl
	jrl nz, PsMenuBox_ReturnZero
	lds32 xhl, 1

PsMenuBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

AcTitleMenuProc:
	stb_dri L, 0xfd, 0xcc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x30, 0x01
	stl_dri XBC, 0xfd, 0x34, 0x01
	ld xiz, xwa
	ld_sril XWA, (xsp + 0x0134)
	cp xwa, 0x1c00007
	jrl z, AcTitleMenu_OK
	cp xwa, 0x1c0000f
	jr z, AcTitleMenu_Confirm
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcTitleMenu_OK_Dispatch

AcTitleMenu_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	stb_dri A, 0xfd, 0x1c, 0x01
	ld xwa, xiz
	calr GetClientBox
	stb_dri E, 0xfd, 0x1c, 0x01
	stb_dri D, 0xfd, 0x14, 0x01
	lds bc, 4
	ldirw
	stb_dri A, 0xfd, 0x28, 0x01
	ld xwa, (xsp + 8)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 8)
	lda xde, (xwa + 50)	; ICON ID
	stb_dri A, 0xfd, 0x2c, 0x01
	ld xwa, (xde)	; <--- here we get the ID of the selected menu item's icon
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIcon

	cpiw_sri 0xfd, 0x28, 0x01, 0x00, 0x00
	jr nz, AcTitleMenu_Confirm_NoIcon

	ldw wa, 0x20
	jr AcTitleMenu_Confirm_SetLeft

AcTitleMenu_Confirm_NoIcon:
	lds wa, 4

AcTitleMenu_Confirm_SetLeft:
	ldw_sri0 HL, (xsp + 0x011c)
	add hl, wa
	ld (xbc), hl
	stw_dri HL, 0xfd, 0x14, 0x01
	stb_dri A, 0xfd, 0x18, 0x01
	ld xwa, (xde)	; also ICON ID here
	or xwa, xwa
	jr z, AcTitleMenu_Confirm_NoIconRight

	cpiw_sri 0xfd, 0x28, 0x01, 0x00, 0x00
	jr z, AcTitleMenu_Confirm_NoIconRight

	ldw wa, 0x1c
	jr AcTitleMenu_Confirm_SetRight

AcTitleMenu_Confirm_NoIconRight:
	lds wa, 4

AcTitleMenu_Confirm_SetRight:
	.byte 0xd3, 0xfd, 0x20, 0x01, 0x22, 0xd8, 0xa2, 0xb1
	.byte 0x52, 0xbf, 0x0c, 0x31, 0xaf, 0x08, 0x20, 0xa8
	.byte 0x2a, 0x20, 0x1d, 0x33, 0x22, 0xfb, 0xbf, 0x0c
	.byte 0x30, 0xf3, 0xfd, 0x14, 0x01, 0x31, 0x99, 0x04
	.byte 0x22, 0x91, 0xa2, 0xaf, 0x08, 0x21, 0xa9, 0x1c
	.byte 0x21, 0x1d, 0x4d, 0x23, 0xfb, 0xbf, 0x06, 0x53
	.byte 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x64, 0x9f, 0x06, 0x22, 0xf3, 0xfd, 0x28
	.byte 0x01, 0x31, 0xaf, 0x08, 0x24, 0xbc, 0x32, 0x30
	.byte 0xdb, 0xf2, 0x6e, 0x68, 0xa0, 0x20, 0xe8, 0xe0
	.byte 0x66, 0x1e, 0x91, 0x3f, 0x00, 0x00, 0x66, 0x18
	.byte 0xbf, 0x0c, 0x30, 0xac, 0x1c, 0x21, 0x1d, 0xc4
	.byte 0x22, 0xfb, 0xd3, 0xfd, 0x18, 0x01, 0x20, 0xdb
	.byte 0xa0, 0xd8, 0x6d, 0xf3, 0xfd, 0x2c, 0x01, 0x50
AcTitleMenu_Confirm_SingleLine:
	stb_dri W, 0xfd, 0x1c, 0x01
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
	stb_dri A, 0xfd, 0x2c, 0x01
	ld (xbc + 2), wa
	stb_dri W, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xf7
	jrl AcTitleMenu_Confirm_RenderTop

AcTitleMenu_Confirm_MultiLine:
	.byte 0x9f, 0x06, 0x23, 0xdb, 0x69, 0xbf, 0x0c, 0x32
	.byte 0xf3, 0x07, 0xe8, 0xec, 0x00, 0x00, 0xa0, 0x20
	.byte 0xe8, 0xe0, 0x66, 0x45, 0x91, 0x3f, 0x00, 0x00
	.byte 0x66, 0x3f, 0x9f, 0x06, 0x20, 0xe8, 0x13, 0xea
	.byte 0x80, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xdb, 0x8e
	.byte 0xbf, 0x10, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x60, 0xaf, 0x08, 0x20, 0xa8, 0x1c, 0x21
	.byte 0xbf, 0x0c, 0x30, 0xde, 0xf3, 0x6b, 0x08, 0x9f
	.byte 0x06, 0x22, 0xf3, 0x07, 0xe0, 0xe8, 0x30
AcTitleMenu_Confirm_MultiAdjust:
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0118)
	sub wa, hl
	dec 5, wa
	stw_dri WA, 0xfd, 0x2c, 0x01

AcTitleMenu_Confirm_RenderBottom:
	stb_dri W, 0xfd, 0x1c, 0x01
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
	stb_dri A, 0xfd, 0x2c, 0x01
	ld (xbc + 2), wa
	stb_dri W, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xf7
	call DrawString
	stb_dri W, 0xfd, 0x1c, 0x01
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
	stb_dri A, 0xfd, 0x2c, 0x01
	ld (xbc + 2), wa
	stb_dri W, 0xfd, 0x14, 0x01
	lda xhl, (xsp + 12)
	ld de, (xsp + 6)
	exts xde
	add xde, xhl
	ld xix, (xsp + 8)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xf7

AcTitleMenu_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)	; ICON ID
	or xwa, xwa
	jrl z, AcTitleMenu_OK_Done

	stb_dri A, 0xfd, 0x24, 0x01
	stb_dri W, 0xfd, 0x1c, 0x01
	cpiw_sri 0xfd, 0x28, 0x01, 0x00, 0x00
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
	stb_dri W, 0xfd, 0x1c, 0x01
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xb
	stb_dri C, 0xfd, 0x24, 0x01
	lda xde, (xhl + 2)
	ld (xde), bc
	stb_dri W, 0xfd, 0x0c, 0x01
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
	stb_dri W, 0xfd, 0x24, 0x01
	ld xbc, (xsp + 8)
	ld xbc, (xbc + 50)	; <-- ICON ID
	call DrawIcons
	jrl AcTitleMenu_OK_Done

AcTitleMenu_OK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld_sril XDE, (xsp + 0x0130)
	call SendEvent
	cps hl, 0
	jrl z, AcTitleMenu_OK_Default
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	cp xwa, 0xffffffff
	jrl z, AcTitleMenu_OK_Default
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x160001d
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckMode
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckMode:
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600040
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckScreen
	ld xwa, (xsp + 8)
	ld xde, (xwa + 46)
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckScreen:
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600041
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_CheckWindow
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr AcTitleMenu_OK_Dispatch

AcTitleMenu_OK_CheckWindow:
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600042
	call SendEvent
	cp xhl, 0x1
	jr nz, AcTitleMenu_OK_Done
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 46)
	ld xbc, 0x1c00001
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
	stb_dri L, 0xfd, 0x34, 0x01
	ret

VwMenuBoxProc:
	stb_dri L, 0xfd, 0xd6, 0xfe
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000f
	jr z, VwMenuBox_Confirm
	cp xbc, 0x1c0000d
	jr z, VwMenuBox_Paint
	ld xwa, xiz
	calr PsMenuBoxProc
	jrl VwMenuBox_Return

VwMenuBox_Paint:
	ld xwa, xiz
	calr PsMenuBoxProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jrl VwMenuBox_ReturnZero

VwMenuBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 6), xhl
	stb_dri A, 0xfd, 0x1a, 0x01
	ld xwa, xiz
	calr GetClientBox
	stb_dri E, 0xfd, 0x1a, 0x01
	stb_dri D, 0xfd, 0x12, 0x01
	lds bc, 4
	ldirw
	stb_dri A, 0xfd, 0x26, 0x01
	ld xwa, (xsp + 6)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 28)
	call GetCharHeight
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	lda xde, (xwa + 46)
	stb_dri A, 0xfd, 0x2a, 0x01
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIcon
	cpiw_sri 0xfd, 0x26, 0x01, 0x00, 0x00
	jr nz, VwMenuBox_Confirm_NoIcon
	ldw wa, 0x20
	jr VwMenuBox_Confirm_SetLeft

VwMenuBox_Confirm_NoIcon:
	lds wa, 4

VwMenuBox_Confirm_SetLeft:
	ldw_sri0 HL, (xsp + 0x011a)
	add hl, wa
	ld (xbc), hl
	stw_dri HL, 0xfd, 0x12, 0x01
	stb_dri A, 0xfd, 0x16, 0x01
	ld xwa, (xde)
	or xwa, xwa
	jr z, VwMenuBox_Confirm_NoIconRight
	cpiw_sri 0xfd, 0x26, 0x01, 0x00, 0x00
	jr z, VwMenuBox_Confirm_NoIconRight
	ldw wa, 0x1c
	jr VwMenuBox_Confirm_SetRight

VwMenuBox_Confirm_NoIconRight:
	lds wa, 4

VwMenuBox_Confirm_SetRight:
	.byte 0xd3, 0xfd, 0x1e, 0x01, 0x22, 0xd8, 0xa2, 0xb1
	.byte 0x52, 0xbf, 0x0a, 0x31, 0xaf, 0x06, 0x20, 0xa8
	.byte 0x2a, 0x20, 0x1d, 0x33, 0x22, 0xfb, 0xbf, 0x0a
	.byte 0x30, 0xf3, 0xfd, 0x12, 0x01, 0x31, 0x99, 0x04
	.byte 0x22, 0x91, 0xa2, 0xaf, 0x06, 0x21, 0xa9, 0x1c
	.byte 0x21, 0x1d, 0x4d, 0x23, 0xfb, 0xdb, 0x8e, 0xbf
	.byte 0x0a, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef
	.byte 0x64, 0xde, 0x8a, 0xf3, 0xfd, 0x26, 0x01, 0x31
	.byte 0xaf, 0x06, 0x24, 0xbc, 0x2e, 0x30, 0xdb, 0xf2
	.byte 0x6e, 0x68, 0xa0, 0x20, 0xe8, 0xe0, 0x66, 0x1e
	.byte 0x91, 0x3f, 0x00, 0x00, 0x66, 0x18, 0xbf, 0x0a
	.byte 0x30, 0xac, 0x1c, 0x21, 0x1d, 0xc4, 0x22, 0xfb
	.byte 0xd3, 0xfd, 0x16, 0x01, 0x20, 0xdb, 0xa0, 0xd8
	.byte 0x6d, 0xf3, 0xfd, 0x2a, 0x01, 0x50
VwMenuBox_Confirm_SingleLine:
	stb_dri W, 0xfd, 0x1a, 0x01
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
	stb_dri A, 0xfd, 0x2a, 0x01
	ld (xbc + 2), wa
	stb_dri W, 0xfd, 0x12, 0x01
	lda xde, (xsp + 10)
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xf7
	jrl VwMenuBox_Confirm_RenderTop

VwMenuBox_Confirm_MultiLine:
	.byte 0xde, 0x8b, 0xdb, 0x69, 0xbf, 0x0a, 0x32, 0xf3
	.byte 0x07, 0xe8, 0xec, 0x00, 0x00, 0xa0, 0x20, 0xe8
	.byte 0xe0, 0x66, 0x42, 0x91, 0x3f, 0x00, 0x00, 0x66
	.byte 0x3c, 0xf3, 0x07, 0xe8, 0xf8, 0x30, 0x38, 0x1d
	.byte 0xc3, 0x07, 0xff, 0xd7, 0xfa, 0x9b, 0xbf, 0x0e
	.byte 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x60
	.byte 0xaf, 0x06, 0x20, 0xa8, 0x1c, 0x21, 0xbf, 0x0a
	.byte 0x30, 0xd7, 0xfa, 0xf3, 0x6b, 0x05, 0xf3, 0x07
	.byte 0xe0, 0xf8, 0x30
VwMenuBox_Confirm_MultiAdjust:
	call CalcTotalWidth
	ldw_sri0 WA, (xsp + 0x0116)
	sub wa, hl
	dec 5, wa
	stw_dri WA, 0xfd, 0x2a, 0x01

VwMenuBox_Confirm_RenderBottom:
	stb_dri W, 0xfd, 0x1a, 0x01
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
	stb_dri A, 0xfd, 0x2a, 0x01
	ld (xbc + 2), wa
	stb_dri W, 0xfd, 0x12, 0x01
	lda xde, (xsp + 10)
	stb_dri B, 0x07, 0xe8, 0xf8
	ld xix, (xsp + 6)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0xf7

VwMenuBox_Confirm_RenderTop:
	call DrawString
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 46)
	or xwa, xwa
	jrl z, VwMenuBox_ReturnZero
	stb_dri A, 0xfd, 0x22, 0x01
	stb_dri W, 0xfd, 0x1a, 0x01
	cpiw_sri 0xfd, 0x26, 0x01, 0x00, 0x00
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
	stb_dri W, 0xfd, 0x1a, 0x01
	ld bc, (xwa + 2)
	ld wa, (xwa + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	sub bc, 0xb
	stb_dri C, 0xfd, 0x22, 0x01
	lda xde, (xhl + 2)
	ld (xde), bc
	stb_dri W, 0xfd, 0x0a, 0x01
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
	stb_dri W, 0xfd, 0x22, 0x01
	ld xbc, (xsp + 6)
	ld xbc, (xbc + 46)
	call DrawIcons

VwMenuBox_ReturnZero:
	lds32 xhl, 0

VwMenuBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x2a, 0x01
	ret

PsEditSwBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xwa
	cp xbc, 0x1e0009c
	jrl z, PsEditSwBox_Repaint
	cp xbc, 0x1e00053
	jr z, PsEditSwBox_HitTest
	cp xbc, 0x1c0000f
	jr z, PsEditSwBox_Confirm
	cp xbc, 0x1c0000d
	jr z, PsEditSwBox_Paint
	cp xbc, 0x1e0003a
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
	cps hl, 0
	jrl z, PsEditSwBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
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
	ld xbc, 0x1c0000c
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
	lds32 xhl, 0

PsEditSwBox_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

PsEditSwBox_InlineData:
	dec	6, xsp
	push	xiz
	ld	(xsp+8), de
	ld	xiz, xbc
	lda	xbc, (xsp+4)
	calr	40500
	lda	xwa, (xsp+4)
	cpw	(xwa), 0
	jr	nz, 41
	lda	xbc, (xwa+2)
	ld	wa, (xbc)
	sub	wa, 9
	ld	(xiz+2), wa
	ld	wa, (xbc)
	inc	8, wa
	ld	(xiz+6), wa
	ld	wa, (xsp+8)
	calr	36090
	ldw	wa, 8
	cps	hl, 0
	jr	z, 2
	lds	wa, 0
	ld	(xiz), wa
	ldw	(xiz+4), 38
	lda	xwa, (xsp+4)
	cpw	(xwa), 319
	jr	nz, 46
	lda	xbc, (xwa+2)
	ld	wa, (xbc)
	sub	wa, 9
	ld	(xiz+2), wa
	ld	wa, (xbc)
	inc	8, wa
	ld	(xiz+6), wa
	ldw	(xiz), 281
	ld	wa, (xsp+8)
	calr	36054
	lda	xwa, (xiz+4)
	cps	hl, 0
	jr	z, 6
	ldw	(xwa), 319
	jr	4
	ldw	(xwa), 311
	lda	xbc, (xsp+4)
	cpw	(xbc+2), 239
	jr	nz, 27
	ldw	(xiz+2), 216
	ldw	(xiz+6), 238
	ld	wa, (xbc)
	sub	wa, 16
	ld	(xiz), wa
	ld	wa, (xbc)
	add	wa, 15
	ld	(xiz+4), wa
	pop	xiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	pushw	iz
	ld	(xsp+10), xde
	ld	iz, bc
	cp	wa, iz
	jr	c, 2
	.byte 0xd8, 0xbe
	lda	xbc, (xsp+6)
	calr	40333
	lda	xbc, (xsp+2)
	ld	wa, iz
	calr	40325
	lda	xbc, (xsp+6)
	cpw	(xbc+2), 239
	jr	nz, 31
	ld	xwa, (xsp+10)
	ldw	(xwa+2), 216
	.byte 0xb8
	.long Naka_SubDispatch_B_Table_0x6E
	ld	bc, (xbc)
	sub	bc, 16
	ld	(xwa), bc
	ld	bc, (xsp+2)
	add	bc, 15
	ld	(xwa+4), bc
	popw	iz
	lda	xsp, (xsp+12)
	ret

ButtonState_PaintProc:
	stb_dri L, 0xfd, 0xd6, 0xfe
	push xiz
	lda_dri XHL, 0xfd, 0x28, 0x01
	stl_dri XWA, 0xfd, 0x2a, 0x01
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld (xsp + 4), xhl
	stb_dri A, 0xfd, 0x20, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	stb_dri E, 0xfd, 0x20, 0x01
	stb_dri D, 0xfd, 0x18, 0x01
	lds bc, 4
	ldirw
	stb_dri C, 0xfd, 0x10, 0x01
	stb_dri W, 0xfd, 0x20, 0x01
	ld bc, (xwa)
	ld (xhl), bc
	stb_dri D, 0xfd, 0x0c, 0x01
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
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x10, 0x01
	stb_dri A, 0xfd, 0x0c, 0x01
	cpib_sri 0xfd, 0x28, 0x01, 0x0b
	jrl z, ButtonState_Paint_Default
	cpib_sri 0xfd, 0x28, 0x01, 0x0e
	jrl z, ButtonState_Paint_EventConfirm
	cpib_sri 0xfd, 0x28, 0x01, 0x03
	jrl nz, ButtonState_DispatchDSP
	lds de, 0
	call DrawLine
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x9b
	ld (xbc + 1), 0x0
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	call DrawStringCentered
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ldw_sri0 BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x98
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	jrl ButtonState_Paint_DrawAndReturn

ButtonState_Paint_EventConfirm:
	lds de, 0
	call DrawLine
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	lda xbc, (xsp + 12)
	ld (xbc), 0x85
	ld (xbc + 1), 0x0
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	call DrawStringCentered
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ldw_sri0 BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	ld (xsp + 12), 0x81
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	lda xde, (xsp + 12)
	ld xix, (xsp + 4)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	ld xhl, xix
	pushm (xhl + 22)
	jrl ButtonState_Paint_DrawAndReturn

ButtonState_Paint_Default:
	ld (xsp + 8), xwa
	ld xiz, xbc
	ld_sril XWA, (xsp + 0x012a)
	calr GetFrameColor
	ld de, hl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	call DrawLine
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	dec 1, bc
	ld (xwa + 6), bc
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	ld xde, xhl
	pushm (xde + 22)
	ld xde, Data_SoundEditorCharsLayout_0x410
	call DrawStringCentered
	stb_dri W, 0xfd, 0x18, 0x01
	ldw_sri0 BC, (xsp + 0x0112)
	inc 1, bc
	ld (xwa + 2), bc
	ldw_sri0 BC, (xsp + 0x0126)
	ld (xwa + 6), bc
	stb_dri A, 0xfd, 0x14, 0x01
	calr GetBoxCenter
	stb_dri W, 0xfd, 0x18, 0x01
	stb_dri A, 0xfd, 0x14, 0x01
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	ld xde, xhl
	pushm (xde + 22)
	ld xde, Data_SoundEditorCharsLayout_0x414

ButtonState_Paint_DrawAndReturn:
	call DrawStringCentered
	jrl ButtonState_Paint_Return

; ButtonState event dispatch via DSP handler table
ButtonState_DispatchDSP:
	ldb_sri0 A, (xsp + 0x0128)
	extz wa
	cps wa, 0
	jrl mi, ButtonState_Paint_DrawAligned
	cp wa, 0x10
	jrl gt, ButtonState_Paint_DrawAligned
	add wa, wa
	lda_24 xix, (Str_No_0x4)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (ButtonState_DispatchDSP_InlineData)
	jp_ind 8, 0x07, 0xf0, 0xe0

ButtonState_DispatchDSP_InlineData:
	lda	xde, (xsp+12)
	ld	xwa, (xsp+298)
	ld	xbc, 31457338
	call	16421459
	jr	100
	ld	xwa, 15377130
	jr	82
	ld	xwa, 15377134
	jr	75
	ld	xwa, 15377138
	jr	68
	ld	xwa, 15377142
	jr	61
	ld	xwa, 15377146
	jr	54
	ld	xwa, 15377150
	jr	47
	ld	xwa, 15377154
	jr	40
	ld	xwa, 15377158
	jr	33
	ld	xwa, 15377160
	jr	26
	ld	xwa, 15377162
	jr	19
	ld	xwa, 15377166
	jr	12
	ld	xwa, 15377170
	jr	5
	ld	xwa, 15377174
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
ButtonState_Paint_DrawAligned:
	stb_dri W, 0xfd, 0x20, 0x01
	stb_dri C, 0xfd, 0x14, 0x01
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

ButtonState_Paint_Return:
	pop xiz
	stb_dri L, 0xfd, 0x2a, 0x01
	ret

PsWideESBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xde
	cp xbc, 0x1e00053
	jrl z, PsWideESBox_GetRange
	cp xbc, 0x1e00052
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
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ldw_erp WA, 0xfa
	ld xwa, (xsp + 20)
	ld iz, wa
	stw_erp WA, 0xfa
	cp wa, iz
	jr c, PsWideESBox_ComputePoints
	stw_erp HL, 0xfa
	stw_erp WA, 0xfa
	ex16 wa, iz
	ldw_erp WA, 0xfa

PsWideESBox_ComputePoints:
	lda xbc, (xsp + 16)
	stw_erp WA, 0xfa
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
	lds32 xhl, 0
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
	ldw_erp DE, 0xfa
	ld iz, bc
	jr PsWideESBox_GetRange_SendEvent

PsWideESBox_GetRange_SwapMax:
	ldw_erp BC, 0xfa
	ld iz, de

PsWideESBox_GetRange_SendEvent:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 20)
	call SendEvent
	cpw_erp HL, 0xfa
	jr c, UIViewFrame_ZeroReturn
	cp hl, iz
	jr ugt, UIViewFrame_ZeroReturn
	lds32 xhl, 1

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
	cp xwa, 0x1c00030
	jrl z, AcIndexEdit_Reset
	cp xwa, 0x1c00007
	jr z, AcIndexEdit_OK
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1e00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, AcIndexEdit_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jrl AcIndexEdit_SendAndReturn

AcIndexEdit_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jrl AcIndexEdit_SendAndReturn

AcIndexEdit_OK:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jrl z, AcIndexEdit_Fallthrough
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 6)
	call SendEvent
	cps hl, 0
	jrl z, AcIndexEdit_Fallthrough
	ld xwa, xiz
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jrl z, AcIndexEdit_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600021
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
	cps wa, 0
	jrl mi, AcIndexEdit_ReturnZeroJmp
	cp wa, 0x10
	jrl gt, AcIndexEdit_ReturnZeroJmp
	lda_24 xix, (Str_No_0x26)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	extz wa
	sll wa, 1
	ld xix, Str_No_0x38
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (AcIndexEdit_DispatchDSP_InlineData)
	jp_ind 8, 0x07, 0xf0, 0xe0

AcIndexEdit_DispatchDSP_InlineData:
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	bit	7, wa
	jr	z, 13
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00018
	jrl	161
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00017
	jrl	148
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00017
	jrl	130
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00018
	jr	t, 0x71

AcIndexEdit_Fallthrough:
	ld xwa, xiz
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	jr AcIndexEdit_InheritedProc

AcIndexEdit_Reset:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, AcIndexEdit_FallthroughAlt
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 6)
	call SendEvent
	cps hl, 0
	jr z, AcIndexEdit_FallthroughAlt
	ld xwa, xiz
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), hl
	cpw (xsp + 4), 0xffff
	jr z, AcIndexEdit_ReturnZeroJmp
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	ld xde, (xsp + 6)
	call SendEvent
	ld xde, (xsp + 6)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call SendEvent
	ld de, (xsp + 4)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00031

AcIndexEdit_SendAndReturn:
	call SendEvent

AcIndexEdit_ReturnZeroJmp:
	lds32 xhl, 0
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
	cp xwa, 0x1c00007
	jr z, AcFuncEdit_OK
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1e00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, AcFuncEdit_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr AcFuncEdit_Paint_SendConfirm

AcFuncEdit_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1c0000f

AcFuncEdit_Paint_SendConfirm:
	call SendEvent
	jr AcFuncEdit_ReturnZero

AcFuncEdit_OK:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, AcFuncEdit_Fallthrough
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	cps hl, 0
	jr z, AcFuncEdit_Fallthrough
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600021
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
	lds32 xhl, 0
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
	cp xbc, 0x1e0003a
	jr z, VwEditSwBox_GetText
	cp xbc, 0x1c0000d
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
	ld xbc, 0x1e00014
	ld xde, 0x1600021
	call SendEvent
	or xhl, xhl
	jr z, VwEditSwBox_Paint_AltOffset
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr VwEditSwBox_Paint_SendConfirm

VwEditSwBox_Paint_AltOffset:
	ld xwa, xiz
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 38)
	ld xwa, xiz
	ld xbc, 0x1c0000f

VwEditSwBox_Paint_SendConfirm:
	call SendEvent
	jr VwEditSwBox_ReturnZero

VwEditSwBox_GetText:
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600021
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
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
VwEditSwBox_ReturnZero:
	lds32 xhl, 0

VwEditSwBox_Return:
	pop xiz
	inc 4, xsp
	ret

PsPageBoxProc:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x14, 0x01
	cp xbc, 0x1e0007f
	jrl z, PsPageBox_SetValue
	cp xbc, 0x1e00056
	jrl z, PsPageBox_GetValue
	cp xbc, 0x1e00055
	jrl z, PsPageBox_ReturnOne
	cp xbc, 0x1e00054
	jrl z, PsPageBox_ReturnOne
	cp xbc, 0x1e00053
	jrl z, PsPageBox_HitTest
	cp xbc, 0x1c0000f
	jr z, PsPageBox_Confirm
	cp xbc, 0x1c00001
	jrl nz, PsPageBox_Default
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	call SendEvent
	jrl UIVwBox_ZeroReturn

PsPageBox_Confirm:
	ld_sril XWA, (xsp + 0x0114)
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
	ld xbc, 0x1c0001e
	call SendEvent

PsPageBox_Confirm_DrawValue:
	.byte 0xaf, 0x04, 0x20, 0xa8, 0x1c, 0x20, 0x90, 0x26
	.byte 0xe3, 0xfd, 0x14, 0x01, 0x20, 0x41, 0x55, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa
	.byte 0x2b, 0x2e, 0x0b, 0xea, 0x00, 0x0b, 0x54, 0xa3
	.byte 0xbf, 0x10, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff
	.byte 0xbf, 0x0c, 0x37, 0xf3, 0xfd, 0x0c, 0x01, 0x31
	.byte 0xe3, 0xfd, 0x14, 0x01, 0x20, 0x1e, 0xbf, 0x81
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x30, 0xf3, 0xfd, 0x08
	.byte 0x01, 0x31, 0x1e, 0x6f, 0x83, 0xf3, 0xfd, 0x0c
	.byte 0x01, 0x30, 0xf3, 0xfd, 0x08, 0x01, 0x31, 0xbf
	.byte 0x08, 0x32, 0xeb, 0xa8, 0x3b, 0x0b, 0x00, 0x00
	.byte 0xaf, 0x0a, 0x23, 0x9b, 0x16, 0x04, 0x1d, 0x9f
	.byte 0xca, 0xfa, 0x68, 0x42
PsPageBox_HitTest:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, xiz
	call SendEvent
	cp xhl, 0x10
	scc16 z, hl
	extz xhl
	jr UI_VwBox_Return

PsPageBox_ReturnOne:
	lds32 xhl, 1
	jr UI_VwBox_Return

PsPageBox_GetValue:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld hl, (xwa)
	exts xhl
	jr UI_VwBox_Return

PsPageBox_SetValue:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xbc, (xhl + 28)
	ld wa, iz
	ld (xbc), wa

UIVwBox_ZeroReturn:
	lds32 xhl, 0
	jr UI_VwBox_Return

PsPageBox_Default:
	ld_sril XWA, (xsp + 0x0114)
	ld xde, xiz
	calr VwBoxProc

UI_VwBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

AcWindowPageProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1c00007
	jr z, AcWindowPage_OK
	cp xiz, 0x1e00055
	jr z, AcWindowPage_GetMax
	cp xiz, 0x1e00054
	jr z, AcWindowPage_GetMin
	cp xiz, 0x1c0000d
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcWindowPage_Default
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00056
	lds32 xde, 0
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000f
	ld xde, xhl

AcWindowPage_SendConfirm:
	call SendEvent
	lds32 xhl, 0
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
	cp xbc, 0x1e0009c
	jrl z, PsToggleBox_Repaint
	cp xbc, 0x1e0006b
	jrl z, PsToggleBox_GetValue
	cp xbc, 0x1e0003b
	jrl z, PsToggleBox_SetValue
	cp xbc, 0x1e0006c
	jrl z, PsToggleBox_Toggle
	cp xbc, 0x1e00053
	jrl z, PsToggleBox_HitTest
	cp xbc, 0x1c0000f
	jr z, PsToggleBox_Confirm
	cp xbc, 0x1c0000d
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
	ld xbc, 0x1c0000f
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
	lds de, 7
	jr PsToggleBox_Confirm_DrawOffBox

PsToggleBox_Confirm_OffLarge:
	ldw bc, 0xc1
	lds de, 7

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
	cps hl, 0
	jrl z, PsToggleBox_ReturnZero
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr PsToggleBox_Toggle_Dispatch

PsToggleBox_Toggle_SetOn:
	ld xwa, (xsp + 28)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000c
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
	cp xwa, 0x1c00007
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
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcFuncToggle_Default
	ld xwa, xiz
	ld xbc, 0x1e0006c
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, 0x1e0003b
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
	cp xiz, 0x1e00050
	jrl z, AcIndexToggle_CanScrollEvt
	cp xiz, 0x1e00051
	jrl z, AcIndexToggle_GetIndex
	cp xiz, 0x1c0002a
	jrl z, AcIndexToggle_Select
	cp xiz, 0x1c0001b
	jrl z, AcIndexToggle_Release
	cp xiz, 0x1c00007
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
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcIndexToggle_OK_Default
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0xffff
	jr z, AcIndexToggle_OK_SetValue
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent

AcIndexToggle_OK_SetValue:
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0003b
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c00029
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
	ld xbc, 0x1e0003b
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
	cpw (xwa), 0xffff
	jr z, AcIndexToggle_ReturnZero
	ld xbc, (xsp + 8)
	srl xbc, 0
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
	ld xbc, 0x1c0001b
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0003b
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
	cp xbc, 0x1e00053
	jrl z, PsWideToggle_HitTest
	cp xbc, 0x1e00052
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
	ldiw_erp 0xe2, 0
	ldw_erp WA, 0xfa
	ld xwa, (xsp + 20)
	ld iz, wa
	stw_erp WA, 0xfa
	cp wa, iz
	jr c, PsWideToggle_GetBounds_CalcPts
	stw_erp HL, 0xfa
	stw_erp WA, 0xfa
	ex16 wa, iz
	ldw_erp WA, 0xfa

PsWideToggle_GetBounds_CalcPts:
	lda xbc, (xsp + 16)
	stw_erp WA, 0xfa
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
	ldw_erp DE, 0xfa
	ld iz, bc
	jr PsWideToggle_HitTest_Check

PsWideToggle_HitTest_SwapOrder:
	ldw_erp BC, 0xfa
	ld iz, de

PsWideToggle_HitTest_Check:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 20)
	call SendEvent
	cpw_erp HL, 0xfa
	jr c, PsWideToggle_ReturnZero
	cp hl, iz
	jr ugt, PsWideToggle_ReturnZero
	lds32 xhl, 1

PsWideToggle_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

PsInvisibleBoxProc:
	cp xbc, 0x1e0003a
	jr z, PsInvisibleBox_GetText
	cp xbc, 0x1c0000f
	jr z, PsInvisibleBox_ReturnZero
	cp xbc, 0x1c0000d
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
	cp xiz, 0x1c0001e
	jr z, IvPageControl_PageChange
	cp xiz, 0x1e0003a
	jr z, IvPageControl_GetText
	cp xiz, 0x1c0000d
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr IvPageControl_Dispatch

IvPageControl_GetText:
	pushw	234
	pushw	41824
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	86
IvPageControl_PageChange:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageControl_PageChange_Init
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld xbc, 0x1c00002
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
	ld xbc, 0x1c00001
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
	cp xbc, 0x1c00034
	jrl z, IvMainEditSw_BtnRecord
	cp xbc, 0x1c00033
	jr z, IvMainEditSw_BtnDelete
	cp xbc, 0x1c00032
	jr z, IvMainEditSw_BtnCancel
	cp xbc, 0x1c0002b
	jr z, IvMainEditSw_BtnOK
	cp xbc, 0x1e0003a
	jr z, IvMainEditSw_GetText
	cp xbc, 0x1c0000d
	jr nz, IvMainEditSw_Default
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr IvMainEditSw_ReturnZero

IvMainEditSw_GetText:
	pushw	234
	pushw	41830
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	78
IvMainEditSw_BtnOK:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1c00007
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnCancel:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1c00008
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnDelete:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1c00009
	ld xde, (xsp + 4)
	jr IvMainEditSw_DispatchChild

IvMainEditSw_BtnRecord:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ld xbc, 0x1c00030
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
	cp xbc, 0x1e00053
	jr z, IvExit_HitTest
	cp xbc, 0x1e0003a
	jr z, IvExit_GetText
	cp xbc, 0x1c0000d
	jr z, IvExit_Paint
	ld xwa, xiz
	calr PsInvisibleBoxProc
	jr IvExit_Return

IvExit_Paint:
	ld xwa, xiz
	calr PsInvisibleBoxProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr IvExit_ReturnZero

IvExit_GetText:
	pushw	234
	pushw	41836
	push	xde
	call	16713584
	inc	8, xsp
IvExit_ReturnZero:
	lds32 xhl, 0
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
	cp xwa, 0x1c00007
	jr z, IvExitMode_OK
	cp xwa, 0x1e0003a
	jr z, IvExitMode_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitMode_DefaultTail

IvExitMode_GetText:
	pushw	234
	pushw	41842
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	114
IvExitMode_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitMode_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitMode_OK_SaveCheck
	ld xde, (xiz + 22)
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	call PostEvent
	jr IvExitMode_OK_Forward

IvExitMode_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
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
	cp xwa, 0x1c00007
	jr z, IvExitScreen_OK
	cp xwa, 0x1e0003a
	jr z, IvExitScreen_GetText
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvExitScreen_DefaultTail

IvExitScreen_GetText:
	pushw	234
	pushw	41848
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	111
IvExitScreen_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitScreen_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitScreen_OK_SaveCheck
	ld xwa, (xiz + 22)
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	jr IvExitScreen_OK_Forward

IvExitScreen_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
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
	cp xiz, 0x1c00007
	jr z, IvExitWindow_OK
	cp xiz, 0x1e0003a
	jr z, IvExitWindow_GetText
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvExitWindow_DefaultTail

IvExitWindow_GetText:
	pushw	234
	pushw	41854
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	119
IvExitWindow_OK:
	ld xwa, (xsp + 8)
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitWindow_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvExitWindow_OK_SaveCheck
	ld xwa, 0xffffffff
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	jr IvExitWindow_OK_Forward

IvExitWindow_OK_SaveCheck:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
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
	cp xwa, 0x1c00001
	jr z, IvFixWin_Init
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1c0000f
	ld xde, Str_No_0x6E
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
	cp xiz, 0x1c00002
	jr z, IvNaming_Close
	cp xiz, 0x1c00001
	jr z, IvNaming_Init
	cp xiz, 0x1c0000d
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
	ld xbc, 0x1c0000f
	ld xde, Str_No_0x74
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
	ld xbc, 0x1e0007b
	call SendEvent
	ld xwa, 0xa
	ld xbc, xiz
	lds32 xde, 0

IvNaming_Dispatch:
	call SendEvent
	jr IvNaming_ReturnZero

IvNaming_Close:
	ld xwa, 0xa
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
	ld xhl, 0xa
	ret

NamingCheck:
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, (257902)
	cp	xbc, 31457404
	jr	z, 32
	cp	xbc, 31457412
	jr	z, 20
	cp	xbc, 31457338
	jr	nz, 12
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
	ld	xhl, xiz
	jr	13
NamingCheck_NotHandled:
	lds32 xhl, 0
	jr NamingCheck_Return

NamingCheck_GetStrLen:
	push	xwa
	call	16713667
	inc	4, xsp
	extz	xhl
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
	cp xwa, 0x1c00001
	jr z, IvTrackSwitch_Init
	cp xwa, 0x1c0000d
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
	ld xbc, 0x1c0000f
	ld xde, Str_No_0x7A
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
	srl xbc, 0
	and xbc, 0xfff
	ld xhl, xwa
	ldiw_erp 0xee, 0
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, (0x027edc)
	add xbc, xde
	ld xde, (xbc)
	extz xhl
	sll xhl, 2
	add xhl, xde
	ld xiz, (xhl)
	ld xix, xiz
	ld xbc, 0x1e00085
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
	cp xbc, 0x1c0000d
	jr z, DefaultClass_Paint
	cp xbc, 0x1e00085
	jr z, DefaultClass_ReturnOne
	ld xwa, xiz
	call InheritedProc
	jr DefaultClass_Return

DefaultClass_ReturnOne:
	lds32 xhl, 1
	jr DefaultClass_Return

DefaultClass_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, Str_No_0x80
	call SendEvent
	lds32 xhl, 0

DefaultClass_Return:
	pop xiz
	ret

IvInterruptProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e000b6
	jrl z, IvInterrupt_CheckActive
	cp xiz, 0x1e0009d
	jrl z, IvInterrupt_GetInterval
	cp xiz, 0x1e0003a
	jr z, IvInterrupt_GetText
	cp xiz, 0x1c0000d
	jr z, IvInterrupt_Paint
	cp xiz, 0x1c00001
	jr z, IvInterrupt_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	jrl ReminderProc_Return

IvInterrupt_Init:
	ld xwa, (xsp + 8)
	ld xbc, 0x1e0009d
	lds32 xde, 0
	call SendEvent
	cps hl, 1
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr IvInterrupt_ReturnZero

IvInterrupt_GetText:
	pushw	234
	pushw	41884
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
IvInterrupt_ReturnZero:
	lds32 xhl, 0
	jr ReminderProc_Return

IvInterrupt_GetInterval:
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld hl, (xhl + 22)
	extz xhl
	jr ReminderProc_Return

IvInterrupt_CheckActive:
	ld xwa, (xsp + 8)
	ld xbc, 0x1e0009d
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
	cp	xbc, 31457437
	jr	z, 25
	cp	xbc, 31457338
	jrl	nz, -216
	pushw	234
	pushw	41890
	push	xde
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	ret
IvIntReminder_GetInterval:
	lds32 xhl, 0
	ldb_da l, (0x0340e6)
	ret

IvIntCompleteProc:
	cp	xbc, 31457437
	jr	z, 25
	cp	xbc, 31457338
	jrl	nz, -257
	pushw	234
	pushw	41896
	push	xde
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	ret
IvIntComplete_GetInterval:
	lds32 xhl, 0
	ldb_da l, (0x0340e8)
	ret

IvIntErrorProc:
	cp	xbc, 31457437
	jr	z, 25
	cp	xbc, 31457338
	jrl	nz, -298
	pushw	234
	pushw	41902
	push	xde
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	ret
IvIntError_GetInterval:
	lds32 xhl, 0
	ldb_da l, (0x0340ec)
	ret

IvIntVariProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0009d
	jr z, IvIntVari_GetInterval
	cp xiz, 0x1e0003a
	jr z, IvIntVari_GetText
	cp xiz, 0x1c00002
	jr z, IvIntVari_Close
	cp xiz, 0x1c00001
	jr z, IvIntVari_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr IvIntVari_Return

IvIntVari_Init:
	lds wa, 1
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvIntVari_ForwardToInterrupt

IvIntVari_Close:
	lds wa, 0
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvIntVari_ForwardToInterrupt:
	calr IvInterruptProc
	jr IvIntVari_ReturnZero

IvIntVari_GetText:
	pushw	234
	pushw	41908
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
IvIntVari_ReturnZero:
	lds32 xhl, 0
	jr IvIntVari_Return

IvIntVari_GetInterval:
	lds32 xhl, 0
	ldb_da l, (0x0340ee)

IvIntVari_Return:
	pop xiz
	inc 8, xsp
	ret

IvIntEasySetProc:
	cp	xbc, 31457437
	jr	z, 25
	cp	xbc, 31457338
	jrl	nz, -461
	pushw	234
	pushw	41914
	push	xde
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	ret
IvIntEasySet_GetInterval:
	lds32 xhl, 0
	ldb_da l, (0x0340f0)
	ret

IvIntWelcomeProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0009d
	jr z, IvIntWelcome_ReturnOne
	cp xiz, 0x1e0003a
	jr z, IvIntWelcome_GetText
	cp xiz, 0x1c00002
	jr z, IvIntWelcome_Close
	cp xiz, 0x1c00001
	jr z, IvIntWelcome_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr IvInterruptProc
	jr IvIntWelcome_Return

IvIntWelcome_Init:
	lds wa, 1
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvIntWelcome_ForwardToInterrupt

IvIntWelcome_Close:
	lds wa, 0
	call SetVariFlag
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvIntWelcome_ForwardToInterrupt:
	calr IvInterruptProc
	jr IvIntWelcome_ReturnZero

IvIntWelcome_GetText:
	pushw	234
	pushw	41920
	ld	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
IvIntWelcome_ReturnZero:
	lds32 xhl, 0
	jr IvIntWelcome_Return

IvIntWelcome_ReturnOne:
	lds32 xhl, 1

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
	cp xiz, 0x1c00007
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1c0000c
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1c0000b
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1c00002
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1c00001
	jr z, IvShowHide_ProcessSpecialEvent
	cp xiz, 0x1c0000d
	jr nz, IvShowHide_Default
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsInvisibleBoxProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	ld xde, Str_No_0xB0
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
	lds32 xhl, 0
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
	cp xbc, 0x1c00020
	jrl z, AcSoundName_VolumeChange
	cp xbc, 0x1c0002f
	jrl z, AcSoundName_ResetPart
	cp xbc, 0x1c0001c
	jr z, AcSoundName_PartChange
	cp xbc, 0x1c0000c
	jr z, AcSoundName_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcSoundName_ShowHide
	cp xbc, 0x1c00002
	jr z, AcSoundName_Close
	cp xbc, 0x1c00001
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
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	jrl AcRhythm_SendPartEvent

AcSoundName_ShowHide_DefaultPart:
	call GetPartSelect
	extz xhl
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
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
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
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
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
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
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
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
	ld xbc, 0x1c0000f
	jr AcSoundName_VolumeChange_SendConfirm

AcSoundName_VolumeChange_DefaultPart:
	call GetPartSelect
	ld xwa, (xsp + 4)
	cp (xwa), hl
	jr nz, AcRhythm_ReturnZeroJmp
	ld xde, (xwa + 2)
	ld xwa, xiz
	ld xbc, 0x1c0000f

AcSoundName_VolumeChange_SendConfirm:
	call SendEvent

AcRhythm_ReturnZeroJmp:
	lds32 xhl, 0
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
	cp xbc, 0x1c00021
	jrl z, AcRhythmName_Confirm
	cp xbc, 0x1c0001c
	jr z, AcRhythmName_PartChange
	cp xbc, 0x1c0000c
	jr z, AcRhythmName_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcRhythmName_ShowHide
	cp xbc, 0x1c00002
	jr z, AcRhythmName_Close
	cp xbc, 0x1c00001
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
	ld xwa, 0x1400005
	ld xbc, 0x1e0005f
	lds32 xde, 0
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
	ld xwa, 0x1400005
	ld xbc, 0x1e0005f
	lds32 xde, 0

AcRhythmName_CallMainFunc:
	call FuncCall
	jr PsParaBox_ZeroReturn

AcRhythmName_Confirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	calr PsParaBoxProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, (xsp + 4)
	call SendEvent

PsParaBox_ZeroReturn:
	lds32 xhl, 0
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
	cp xbc, 0x1c00022
	jr z, AcPmemName_Confirm
	cp xbc, 0x1c0001c
	jr z, AcPmemName_PartChange
	cp xbc, 0x1c0000c
	jr z, AcPmemName_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcPmemName_ShowHide
	cp xbc, 0x1c00002
	jr z, AcPmemName_Close
	cp xbc, 0x1c00001
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
	ld xwa, 0x1400006
	ld xbc, 0x1e00060
	lds32 xde, 0
	jr AcPmemName_CallMainFunc

AcPmemName_PartChange:
	ld xwa, (xsp + 44)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, (xiz)
	cp xwa, 0x300
	jrl nz, PsParaBox_EventReturn
	ld xwa, 0x1400006
	ld xbc, 0x1e00060
	lds32 xde, 0

AcPmemName_CallMainFunc:
	call MainFuncCall
	jrl PsParaBox_EventReturn

AcPmemName_Confirm:
	.byte 0xaf, 0x2c, 0x20, 0xee, 0x8a, 0x1e, 0xa9, 0xa6
	.byte 0xbe, 0x02, 0x31, 0x91, 0x20, 0xd8, 0x69, 0xd8
	.byte 0xef, 0x03, 0xd8, 0x61, 0xc9, 0x88, 0xbe, 0x04
	.byte 0x32, 0xa2, 0x25, 0xc8, 0x8f, 0xdb, 0x12, 0xbf
	.byte 0x04, 0x34, 0x85, 0x3f, 0x00, 0x66, 0x3e, 0x96
	.byte 0x3f, 0x00, 0x00, 0x66, 0x24, 0xc8, 0xee, 0x03
	.byte 0xc8, 0x68, 0xc8, 0x89, 0xd8, 0x12, 0x91, 0x21
	.byte 0xd8, 0xa1, 0xa2, 0x20, 0x38, 0xd9, 0x12, 0x29
	.byte 0x2b, 0x0b, 0xea, 0x00, 0x0b, 0xcc, 0xa3, 0x3c
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x10, 0x37, 0x68
	.byte 0x23
AcPmemName_Confirm_ZeroIndex:
	ld	xwa, (xde)
	push	xwa
	pushw	hl
	pushw	234
	pushw	41950
	push	xix
	call	16712341
	lda	xsp, (xsp+14)
	jr	15
AcPmemName_Confirm_EmptySlot:
	pushw	hl
	pushw	234
	pushw	41966
	push	xix
	call	16712341
	lda	xsp, (xsp+10)
AcPmemName_Confirm_SendEvent:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 44)
	ld xbc, 0x1c0000f
	call SendEvent

PsParaBox_EventReturn:
	lds32 xhl, 0
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
	cp xwa, 0x1e00061
	jrl z, AcMixerVol_EncoderUpdate
	cp xwa, 0x1c00030
	jrl z, AcMixerVol_Reset
	cp xwa, 0x1c00027
	jrl z, AcMixerVol_FastScroll
	cp xwa, 0x1c00007
	jrl z, AcMixerVol_OK
	cp xwa, 0x1c0001c
	jrl z, AcMixerVol_ValueChange
	cp xwa, 0x1c00023
	jrl z, AcMixerVol_PartSelect
	cp xwa, 0x1c0000f
	jrl z, AcMixerVol_Confirm
	cp xwa, 0x1c0000d
	jr z, AcMixerVol_Paint
	cp xwa, 0x1c0000c
	jr z, AcMixerVol_ShowHide
	cp xwa, 0x1c0000b
	jr z, AcMixerVol_ShowHide
	cp xwa, 0x1c00002
	jr z, AcMixerVol_Close
	cp xwa, 0x1c00001
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
	ld xhl, Str_No_0xF4
	add xhl, xde
	ld xde, (xhl)
	lds32 xhl, 3
	push xhl
	pushw 0xff
	pushw 0x8
	call DrawStringCentered
	ld xwa, (xsp + 44)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld de, (xwa + 28)
	extz xde
	ld xwa, (xsp + 44)
	ld xbc, 0x1e00061
	jrl UIList_SendEvent

AcMixerVol_Confirm:
	.byte 0xaf, 0x2c, 0x20, 0xaf, 0x28, 0x21, 0xaf, 0x24
	.byte 0x22, 0x1e, 0x03, 0xa4, 0xaf, 0x2c, 0x20, 0x1d
	.byte 0x59, 0x5e, 0xfa, 0xbf, 0x08, 0x63, 0xaf, 0x08
	.byte 0x20, 0x98, 0x1c, 0x20, 0xe8, 0x12, 0xe8, 0x89
	.byte 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0x81, 0x40
	.byte 0x0c, 0xa5, 0xea, 0x00, 0xe9, 0x80, 0xa0, 0x20
	.byte 0x1d, 0x66, 0xcc, 0xfc, 0xbf, 0x04, 0x53, 0xaf
	.byte 0x08, 0x20, 0x98, 0x1c, 0x20, 0xe8, 0x12, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0x81
	.byte 0xf2, 0x10, 0xa5, 0xea, 0x30, 0xe9, 0x80, 0xa0
	.byte 0x20, 0x1d, 0x66, 0xcc, 0xfc, 0xbf, 0x06, 0x53
	.byte 0xbf, 0x18, 0x31, 0xaf, 0x2c, 0x20, 0x1d, 0xd0
	.byte 0x91, 0xf9, 0xbf, 0x18, 0x32, 0x9a, 0x04, 0x20
	.byte 0x92, 0xa0, 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00
	.byte 0x92, 0x23, 0xd8, 0x83, 0xbf, 0x20, 0x31, 0xb1
	.byte 0x53, 0x9a, 0x02, 0x20, 0xd8, 0x64, 0xb9, 0x02
	.byte 0x50, 0x9f, 0x04, 0x04, 0x0b, 0xea, 0x00, 0x0b
	.byte 0xb0, 0xa6, 0xbf, 0x18, 0x30, 0x38, 0x1d, 0x95
	.byte 0x02, 0xff, 0xbf, 0x0a, 0x37, 0xbf, 0x18, 0x30
	.byte 0xbf, 0x20, 0x31, 0xbf, 0x12, 0x32, 0xeb, 0xab
	.byte 0x3b, 0x0b, 0x00, 0x00, 0xaf, 0x0e, 0x23, 0x9b
	.byte 0x16, 0x04, 0x1d, 0x9f, 0xca, 0xfa, 0xbf, 0x20
	.byte 0x30, 0xbf, 0x18, 0x32, 0x92, 0x21, 0xd9, 0x64
	.byte 0xb0, 0x51, 0x9a, 0x02, 0x21, 0xd9, 0xc8, 0x0a
	.byte 0x00, 0xb8, 0x02, 0x51, 0xe9, 0xaa, 0x1d, 0x06
	.byte 0xba, 0xfa, 0xbf, 0x20, 0x30, 0x31, 0x80, 0x00
	.byte 0x9f, 0x04, 0xa1, 0xd9, 0x09, 0x24, 0x00, 0xe9
	.byte 0x13, 0xd9, 0x0b, 0x80, 0x00, 0x98, 0x02, 0x89
	.byte 0xe9, 0xab, 0x1d, 0x06, 0xba, 0xfa, 0x9f, 0x06
	.byte 0x3f, 0x01, 0x00, 0x7e, 0x3e, 0x03, 0xbf, 0x18
	.byte 0x31, 0xaf, 0x2c, 0x20, 0x1d, 0xd0, 0x91, 0xf9
	.byte 0xbf, 0x20, 0x31, 0xbf, 0x18, 0x30, 0x90, 0x22
	.byte 0xda, 0xc8, 0x11, 0x00, 0xb1, 0x52, 0x98, 0x02
	.byte 0x22, 0xda, 0xc8, 0x1f, 0x00, 0xb9, 0x02, 0x52
	.byte 0x91, 0x22, 0xda, 0xca, 0x0c, 0x00, 0xb0, 0x52
	.byte 0x91, 0x22, 0xda, 0xc8, 0x0c, 0x00, 0xb8, 0x04
	.byte 0x52, 0x98, 0x06, 0x38, 0x12, 0x00, 0xea, 0xab
	.byte 0x3a, 0x0b, 0xfb, 0x00, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x01, 0x00, 0x42, 0xb4, 0xa6
	.byte 0xea, 0x00, 0x1d, 0x77, 0xcc, 0xfa, 0x78, 0xeb
	.byte 0x02
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
	srl xwa, 0
	ldiw_erp 0xe2, 0
	srl wa, 8
	ldb w, 0x0
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
	lda_24 xde, (Str_No_0x30E)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	ld xbc, 0x1e00061
	jrl UIList_SendEvent

AcMixerVol_OK:
	.byte 0xaf, 0x2c, 0x20, 0x1d, 0x59, 0x5e, 0xfa, 0xbf
	.byte 0x08, 0x63, 0x40, 0x24, 0x00, 0x60, 0x02, 0x41
	.byte 0x29, 0x00, 0xe0, 0x01, 0xaf, 0x24, 0x22, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xaf, 0x08, 0x21, 0x99, 0x1e
	.byte 0x20, 0xe8, 0x12, 0xeb, 0xf0, 0x7e, 0x96, 0x00
	.byte 0x99, 0x1c, 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x02, 0xe8, 0x81, 0xe9, 0x81, 0xf2, 0x10
	.byte 0xa5, 0xea, 0x30, 0xe9, 0x80, 0xa0, 0x20, 0x1d
	.byte 0x66, 0xcc, 0xfc, 0xbf, 0x06, 0x53, 0xaf, 0x08
	.byte 0x20, 0xb8, 0x1c, 0x30, 0x9f, 0x06, 0x3f, 0x00
	.byte 0x00, 0x66, 0x2c, 0x90, 0x21, 0xe9, 0x12, 0xe9
	.byte 0x88, 0xe8, 0xee, 0x02, 0xe9, 0x80, 0xe8, 0x80
	.byte 0x41, 0x0c, 0xa5, 0xea, 0x00, 0xe8, 0x81, 0xa9
	.byte 0x04, 0x20, 0x99, 0x08, 0x22, 0xd9, 0xa8, 0x1e
	.byte 0x16, 0xcd, 0xaf, 0x2c, 0x20, 0x41, 0x27, 0x00
	.byte 0xc0, 0x01, 0xaf, 0x24, 0x22, 0x68, 0x38
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
	lds bc, 1

AcMixerVol_OK_ApplyDelta:
	calr MainLswAdd
	ld xwa, (xsp + 44)
	ld xbc, 0x1c00027
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
	ld xbc, 0x1e00029
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
	lds bc, 4

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
	ld xbc, 0x1e00029
	ld xde, (xsp + 36)
	call SendEvent
	ld xwa, (xsp + 8)
	ld wa, (xwa + 30)
	extz xwa
	cp xwa, xhl
	jr nz, AcMixerVol_Reset_Fallthrough
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	ld xde, (xsp + 36)
	call SendEvent
	ld xde, (xsp + 36)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
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
	lds bc, 1
	calr MainLswPut

AcMixerVol_Reset_Fallthrough:
	ld xwa, (xsp + 44)
	ld xbc, (xsp + 40)
	ld xde, (xsp + 36)
	jr UIList_VwBoxCall

AcMixerVol_EncoderUpdate:
	ld	xwa, (xsp+36)
	lds	bc, 0
	call	16567590
	ld	(xsp+15), l
	ld	xwa, (xsp+36)
	ldw	bc, 32
	call	16567590
	lda	xwa, (xsp+12)
	ld	(xwa+4), l
	ld	xbc, (xsp+36)
	ld	(xwa+2), c
	call	16703515
	lda	xbc, (xsp+12)
	ld	e, (xbc+1)
	extz	de
	ld	a, (xbc)
	extz	wa
	sll	wa, 8
	add	wa, de
	ld	bc, wa
	extz	xbc
	sll	xbc, 0
	ld	xwa, (xsp+36)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+44)
	ld	xbc, 29360163
UIList_SendEvent:
	call SendEvent

UIList_ReturnZeroJmp:
	lds32 xhl, 0
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
	cp	xwa, 0x01c00027
	jr	z, 18
	cp	xwa, 0x01c00007
	jr	nz, 21
	ld	hl, (xsp+4)
	bit	7, bc
	jr	nz, 7
	jr	13
	bit	7, bc
	jr	z, 8
	mul	hl, 0xffff
	jr	2
	lds	hl, 0
	retd	2

DbMemoProc:
	lda xsp, (xsp - 106)
	push xiz
	ld (xsp + 102), xde
	ld (xsp + 106), xwa
	cp xbc, 0x1c00025
	jr z, DbMemo_DrawContent
	cp xbc, 0x1c0000d
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
	ldw bc, 0xc6
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 106)
	ld xbc, 0x1c00025
	ld xde, Str_No_0x3A4
	call SendEvent

DbMemo_ReturnZero:
	lds32 xhl, 0

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

DbMemo_DrawContent_Loop:
	.byte 0xbf, 0x56, 0x30, 0xbf, 0x46, 0x31, 0x1d, 0x46
	.byte 0xb6, 0xfa, 0xbf, 0x4e, 0x30, 0xd9, 0xaf, 0x1d
	.byte 0x66, 0xae, 0xfa, 0x9f, 0x04, 0x04, 0xaf, 0x08
	.byte 0x20, 0x38, 0xbf, 0x10, 0x30, 0x38, 0x1d, 0x16
	.byte 0x05, 0xff, 0xbf, 0x0a, 0x37, 0x9f, 0x04, 0x20
	.byte 0xe8, 0x12, 0xbf, 0x0a, 0x32, 0xea, 0x89, 0xe8
	.byte 0x81, 0xb1, 0x00, 0x00, 0xbf, 0x5e, 0x30, 0xbf
	.byte 0x4a, 0x31, 0xeb, 0xab, 0x3b, 0x0b, 0x00, 0x00
	.byte 0x0b, 0x07, 0x00, 0x1d, 0xbd, 0xc6, 0xfa, 0xbf
	.byte 0x0a, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef
	.byte 0x64, 0x9f, 0x04, 0xf3, 0x7e, 0x24, 0xff, 0x9f
	.byte 0x04, 0x20, 0xe8, 0x12, 0xaf, 0x06, 0x88, 0x68
	.byte 0x9f, 0xef, 0x6c, 0x3e, 0xbf, 0x04, 0x60, 0x38
	.byte 0x1d, 0xc3, 0x07, 0xff, 0xdb, 0x61, 0x2b, 0x1d
	.byte 0xa3, 0x06, 0xff, 0xeb, 0x8e, 0xaf, 0x0a, 0x20
	.byte 0x38, 0x3e, 0x1d, 0x70, 0x07, 0xff, 0xbf, 0x0e
	.byte 0x37, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x25
	.byte 0x00, 0xc0, 0x01, 0xee, 0x8a, 0x1d, 0x45, 0x93
	.byte 0xfa, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x23
	.byte 0x00, 0xe0, 0x01, 0xee, 0x8a, 0x1d, 0x45, 0x93
	.byte 0xfa, 0x5e, 0xef, 0x64, 0x0e
DbMemo_TrailingData:
	ret

DbMemoryDumpProc:
	lda xsp, (xsp - 120)
	push xiz
	ld (xsp + 112), xde
	ld (xsp + 116), xbc
	ld (xsp + 120), xwa
	ld xwa, (xsp + 116)
	cp xwa, 0x1c00007
	jrl z, DbMemDump_OK
	cp xwa, 0x1c0000f
	jrl z, DbMemDump_Confirm
	cp xwa, 0x1c0000e
	jrl z, DbMemDump_Select
	cp xwa, 0x1c0000d
	jr z, DbMemDump_Paint
	cp xwa, 0x1c00002
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
	ldw bc, 0xc6
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 120)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_Select:
	ld xwa, (xsp + 120)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, 0x1c0000e
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0x78
	ld_sril XBC, (xsp + 0x0080)
	ld_sril XDE, (xsp + 0x0080)
	call SetApTimer
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_Confirm:
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

DbMemDump_Confirm_RowLoop:
	.byte 0x9f, 0x04, 0x21, 0xd9, 0x08, 0x09, 0x00, 0xbf
	.byte 0x68, 0x30, 0x98, 0x02, 0x22, 0xd9, 0x82, 0xda
	.byte 0x61, 0xbf, 0x64, 0x31, 0xb9, 0x02, 0x52, 0x90
	.byte 0x20, 0xb1, 0x50, 0xaf, 0x06, 0x20, 0xa8, 0x16
	.byte 0x21, 0x9f, 0x04, 0x20, 0xd8, 0xee, 0x03, 0xe8
	.byte 0x12, 0xe8, 0x8e, 0xa1, 0x86, 0x0b, 0x08, 0x00
	.byte 0x3e, 0xbf, 0x10, 0x30, 0x38, 0x1d, 0xbc, 0x05
	.byte 0xff, 0xde, 0x88, 0x28, 0xee, 0x88, 0xe8, 0xef
	.byte 0x00, 0x28, 0x0b, 0xea, 0x00, 0x0b, 0xc6, 0xa6
	.byte 0xbf, 0x26, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff
	.byte 0xbf, 0x16, 0x37, 0xbf, 0x68, 0x30, 0xbf, 0x64
	.byte 0x31, 0xbf, 0x14, 0x32, 0xeb, 0xab, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x07, 0x00, 0x1d, 0xbd, 0xc6
	.byte 0xfa, 0xbf, 0x0a, 0x31, 0x89, 0x07, 0x21, 0xd8
	.byte 0x12, 0x28, 0x89, 0x06, 0x21, 0xd8, 0x12, 0x28
	.byte 0x89, 0x05, 0x21, 0xd8, 0x12, 0x28, 0x89, 0x04
	.byte 0x21, 0xd8, 0x12, 0x28, 0x89, 0x03, 0x21, 0xd8
	.byte 0x12, 0x28, 0x89, 0x02, 0x21, 0xd8, 0x12, 0x28
	.byte 0x89, 0x01, 0x21, 0xd8, 0x12, 0x28, 0x81, 0x21
	.byte 0xd8, 0x12, 0x28, 0x0b, 0xea, 0x00, 0x0b, 0xd2
	.byte 0xa6, 0xbf, 0x28, 0x30, 0x38, 0x1d, 0x95, 0x02
	.byte 0xff, 0xbf, 0x18, 0x37, 0xbf, 0x64, 0x31, 0x91
	.byte 0x38, 0x30, 0x00, 0xbf, 0x68, 0x30, 0xbf, 0x14
	.byte 0x32, 0xeb, 0xab, 0x3b, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x07, 0x00, 0x1d, 0xbd, 0xc6, 0xfa, 0xbf, 0x0a
	.byte 0x32, 0xea, 0x88, 0xba, 0x08, 0x31
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
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawString
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x10
	jrl c, DbMemDump_Confirm_RowLoop
	jrl UI_NameCapture_ReturnSuccess

DbMemDump_OK:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
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
	add xwa, Str_No_0x3E4
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 120)
	ld xbc, (xsp + 116)
	ld xde, (xsp + 112)
	call SetAutoInc

UI_NameCapture_ReturnSuccess:
	lds32 xhl, 0

DbMemDump_Return:
	pop xiz
	lda xsp, (xsp + 120)
	ret

CaptureLcdCheck:
	cp xbc, 0x1c00007
	call_24 z, CaptureLcd
	lds32 xhl, 0
	ret

PsCursorBoxProc:
	stb_dri L, 0xfd, 0xd6, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x2a, 0x02
	ld xiz, xwa
	cp xbc, 0x1e00080
	jrl z, PsCursorBox_SetCursor
	cp xbc, 0x1c0000f
	jr z, PsCursorBox_Confirm
	cp xbc, 0x1c0000e
	jr z, PsCursorBox_Select
	cp xbc, 0x1c00001
	jr z, PsCursorBox_Init
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	jrl PsCursorBox_Return

PsCursorBox_Init:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 36)
	ldw (xwa), 0xffff
	jrl ScrollBox_ReturnZero

PsCursorBox_Select:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x022a)
	calr PsParaBoxProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x2a, 0x02
	jrl z, ScrollBox_ReturnZero
	jrl PsCursorBox_StoreCursor

PsCursorBox_Confirm:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 14), xhl
	stb_dri B, 0xfd, 0x12, 0x01
	ld_sril XWA, (xsp + 0x022a)
	or xwa, xwa
	jr nz, PsCursorBox_Confirm_CopyText
	ld xwa, xiz
	ld xbc, 0x1e0003a
	call SendEvent
	cpib_sri 0xfd, 0x12, 0x01, 0x00
	jr nz, PsCursorBox_Confirm_CheckCursor
	jrl ScrollBox_ReturnZero

PsCursorBox_Confirm_CopyText:
	ld	xwa, (xsp+554)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsCursorBox_Confirm_CheckCursor:
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	cpw (xwa), 0xffff
	jrl z, ScrollBox_ReturnZero
	stb_dri A, 0xfd, 0x22, 0x02
	ld xwa, xiz
	call GetClientBox
	stb_dri W, 0xfd, 0x22, 0x02
	stb_dri A, 0xfd, 0x12, 0x02
	call GetBoxCenter
	stb_dri E, 0xfd, 0x22, 0x02
	stb_dri D, 0xfd, 0x1a, 0x02
	lds bc, 4
	ldirw
	ld xbc, (xsp + 14)
	ld xwa, (xbc + 28)
	ld (xsp + 6), xwa
	ld wa, (xbc + 22)
	ld (xsp + 12), wa
	ld wa, (xbc + 32)
	ld (xsp + 10), wa
	stb_dri W, 0xfd, 0x12, 0x01
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld xwa, (xsp + 6)
	call GetCharHeight
	ld iz, hl
	ld xwa, (xsp + 6)
	call GetCharDescent
	ldw_erp HL, 0xfa
	ld xwa, (xsp + 6)
	call GetCenteredDelta
	stb_dri B, 0xfd, 0x12, 0x02
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
	stb_dri W, 0xfd, 0x22, 0x02
	cps c, 2
	jr z, PsCursorBox_Confirm_AlignRight
	cps c, 1
	jr z, PsCursorBox_Confirm_AlignLeft
	cps c, 0
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
	stb_dri W, 0xfd, 0x12, 0x01
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	stb_dri H, 0x07, 0xe4, 0xe0
	ld (xiz + 1), 0x0
	ld xwa, xiz
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ld (xsp + 4), hl
	ld (xiz), 0x0
	lda xwa, (xsp + 18)
	ld xbc, (xsp + 6)
	call CalcTotalWidth
	ldw_sri0 BC, (xsp + 0x0212)
	add bc, hl
	stb_dri W, 0xfd, 0x1a, 0x02
	ld (xwa), bc
	add bc, (xsp + 4)
	ld (xwa + 4), bc
	stb_dri A, 0xfd, 0x16, 0x02
	call GetBoxCenter
	stb_dri W, 0xfd, 0x12, 0x01
	lda xbc, (xsp + 18)
	call ConvertStrings
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 36)
	lda xbc, (xsp + 18)
	ld wa, (xwa)
	stb_dri H, 0x07, 0xe4, 0xe0
	ld (xiz + 1), 0x0
	stb_dri W, 0xfd, 0x22, 0x02
	ld bc, (xsp + 12)
	call DrawBox
	stb_dri W, 0xfd, 0x22, 0x02
	stb_dri A, 0xfd, 0x12, 0x02
	stb_dri B, 0xfd, 0x12, 0x01
	ld xhl, (xsp + 6)
	push xhl
	pushm (xsp + 14)
	pushw 0xf7
	call DrawString
	stb_dri W, 0xfd, 0x1a, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
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

PsCursorBox_SetCursor:
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 36)

PsCursorBox_StoreCursor:
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x022a)
	ld (xbc), wa

ScrollBox_ReturnZero:
	lds32 xhl, 0

PsCursorBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x2a, 0x02
	ret

DbDebugMenuProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld (xsp + 24), xbc
	ld xiz, xwa
	ld xwa, (xsp + 24)
	cp xwa, 0x1c00007
	jrl z, DbDebugMenu_OK
	cp xwa, 0x1c0000f
	jrl z, DbDebugMenu_Confirm
	cp xwa, 0x1c0000d
	jrl z, DbDebugMenu_Paint
	cp xwa, 0x1c00002
	jr z, DbDebugMenu_Close
	cp xwa, 0x1c00001
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
	lda_24 xde, (Str_No_0x42E)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	cp xwa, 0xffffffff
	jrl z, PsMenuBox_ZeroReturn
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl PsMenuBox_SendEvent

DbDebugMenu_Close:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xde, (Str_No_0x42E)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_Close_CallMenu
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 0
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lda_24 xhl, (Str_No_0x3FC)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 3
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawStringCentered
	jrl PsMenuBox_ZeroReturn

DbDebugMenu_OK:
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 20)
	call SendEvent
	cps hl, 0
	jrl z, DbDebugMenu_OK_HitTestFail
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 42)
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xde, (Str_No_0x42E)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_OK_Advance
	ld xwa, (xbc)
	ld wa, (xwa)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent

DbDebugMenu_OK_Advance:
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 42)
	ld xde, xwa
	ld xbc, (xwa)
	incm 1, (xbc)
	ld xbc, (xwa)
	ld wa, (xbc)
	sla wa, 2
	lda_24 xhl, (Str_No_0x3FC)
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	cp (xwa), 0x0
	jr nz, DbDebugMenu_OK_CheckValid
	ldw (xbc), 0x0

DbDebugMenu_OK_CheckValid:
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, (Str_No_0x42E)
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr z, DbDebugMenu_OK_NoHandler
	ld xwa, (xbc)
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr PsMenuBox_SendEvent

DbDebugMenu_OK_NoHandler:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jr PsMenuBox_SendEvent

DbDebugMenu_OK_HitTestFail:
	ld xwa, (xsp + 20)
	cp xwa, 0xf
	jr nz, DbDebugMenu_Default
	lds32 xwa, 7
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0

PsMenuBox_SendEvent:
	call SendEvent

PsMenuBox_ZeroReturn:
	lds32 xhl, 0
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
	stb_dri L, 0xfd, 0x4e, 0xff
	push xiz
	stl_dri XDE, 0xfd, 0xae, 0x00
	ld xde, xbc
	stl_dri XWA, 0xfd, 0xb2, 0x00
	ld xiy, Str_No_0x43A
	lda xix, (xsp + 38)
	ldw bc, 0x28
	ldirw
	ld xiy, Str_No_0x4DA
	lda xix, (xsp + 18)
	ldw bc, 0xa
	ldirw
	ld xiy, Str_No_0x504
	lda xix, (xsp + 8)
	lds bc, 5
	ldirw
	cp xde, 0x1e00053
	jrl z, PsTrkSw_HitTest
	cp xde, 0x1c0000e
	jrl z, PsTrkSw_Select
	cp xde, 0x1c0000f
	jrl z, PsTrkSw_Confirm
	cp xde, 0x1c0000c
	jr z, PsTrkSw_ShowHide
	cp xde, 0x1c0000b
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
	ld xbc, 0x1e00010
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
	ld xbc, 0x1c0000f
	call SendEvent
	ld xwa, (xiz + 32)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x00b2)
	ld xbc, 0x1c0000e
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
	ldiw_erp 0xe2, 0
	ld bc, wa
	cp bc, 0xffff
	jr z, PsTrkSw_Confirm_SetSub
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 24)
	ld (xwa), bc

PsTrkSw_Confirm_SetSub:
	ld_sril XBC, (xsp + 0x00ae)
	cp bc, 0xffff
	jr z, PsTrkSw_Confirm_DrawGeometry
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld (xwa), bc

PsTrkSw_Confirm_DrawGeometry:
	.byte 0xf3, 0xfd, 0xa6, 0x00, 0x31, 0xe3, 0xfd, 0xb2
	.byte 0x00, 0x20, 0x1d, 0x89, 0x5e, 0xfa, 0xf3, 0xfd
	.byte 0xa6, 0x00, 0x31, 0xf3, 0xfd, 0x9e, 0x00, 0x32
	.byte 0x30, 0xcb, 0x00, 0x1d, 0xf2, 0x91, 0xf9, 0xf3
	.byte 0xfd, 0x9e, 0x00, 0x35, 0xf3, 0xfd, 0x96, 0x00
	.byte 0x34, 0xd9, 0xac, 0x95, 0x11, 0xf3, 0xfd, 0x8e
	.byte 0x00, 0x34, 0xf3, 0xfd, 0x9e, 0x00, 0x30, 0x90
	.byte 0x21, 0xb4, 0x51, 0xf3, 0xfd, 0x8a, 0x00, 0x35
	.byte 0x98, 0x04, 0x21, 0xb5, 0x51, 0xb8, 0x06, 0x33
	.byte 0x98, 0x02, 0x22, 0x93, 0x21, 0xda, 0xa1, 0xe9
	.byte 0x13, 0xd9, 0x0b, 0x02, 0x00, 0xda, 0x8e, 0xd9
	.byte 0x86, 0xbc, 0x02, 0x32, 0xb2, 0x56, 0xbd, 0x02
	.byte 0x56, 0x92, 0x21, 0xd9, 0x69, 0xb3, 0x51, 0x92
	.byte 0x21, 0xd9, 0x61, 0xf3, 0xfd, 0x98, 0x00, 0x51
	.byte 0xf3, 0xfd, 0x92, 0x00, 0x31, 0x1d, 0x8d, 0x93
	.byte 0xf9, 0xf3, 0xfd, 0x96, 0x00, 0x30, 0xf3, 0xfd
	.byte 0x86, 0x00, 0x31, 0x1d, 0x8d, 0x93, 0xf9, 0xaf
	.byte 0x04, 0x20, 0x98, 0x16, 0x20, 0xd8, 0x61, 0x28
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x24, 0xa8, 0xbf, 0x7c
	.byte 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xaf, 0x04, 0x20, 0xa8, 0x18, 0x21, 0x98
	.byte 0x16, 0x3f, 0x08, 0x00, 0x7f, 0x82, 0x00, 0x91
	.byte 0x3f, 0x00, 0x00, 0x66, 0x46, 0xf3, 0xfd, 0xa6
	.byte 0x00, 0x30, 0x31, 0xcb, 0x00, 0xda, 0xa8, 0x1d
	.byte 0x4c, 0xd1, 0xfa, 0xf3, 0xfd, 0x8e, 0x00, 0x30
	.byte 0xf3, 0xfd, 0x8a, 0x00, 0x31, 0xda, 0xa8, 0x1d
	.byte 0x7d, 0xa5, 0xfa, 0xf3, 0xfd, 0x9e, 0x00, 0x30
	.byte 0xf3, 0xfd, 0x92, 0x00, 0x31, 0xbf, 0x76, 0x32
	.byte 0xeb, 0xa8, 0x3b, 0x0b, 0x07, 0x00, 0x0b, 0xf7
	.byte 0x00, 0x1d, 0x9f, 0xca, 0xfa, 0xf3, 0xfd, 0x96
	.byte 0x00, 0x30, 0xd9, 0xaf, 0x1d, 0x66, 0xae, 0xfa
	.byte 0x78, 0xb5, 0x00
PsTrkSw_Confirm_DrawOff:
	stb_dri W, 0xfd, 0xa6, 0x00
	ldw bc, 0xcb
	lds de, 7
	call DrawDesignBox
	stb_dri W, 0xfd, 0x8e, 0x00
	stb_dri A, 0xfd, 0x8a, 0x00
	lds de, 0
	call DrawLine
	stb_dri W, 0xfd, 0x9e, 0x00
	stb_dri A, 0xfd, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8Plus:
	cpw (xbc), 0x0
	jr z, PsTrkSw_Confirm_Track8PlusOff
	stb_dri W, 0xfd, 0xa6, 0x00
	ldw bc, 0xcc
	lds de, 7
	call DrawDesignBox
	stb_dri W, 0xfd, 0x8e, 0x00
	stb_dri A, 0xfd, 0x8a, 0x00
	lds de, 0
	call DrawLine
	stb_dri W, 0xfd, 0x9e, 0x00
	lds bc, 0
	call DrawBox
	stb_dri W, 0xfd, 0x9e, 0x00
	stb_dri A, 0xfd, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x7
	pushw 0xf7
	jr PsTrkSw_Confirm_DrawMark

PsTrkSw_Confirm_Track8PlusOff:
	stb_dri W, 0xfd, 0xa6, 0x00
	ldw bc, 0xcc
	lds de, 7
	call DrawDesignBox
	stb_dri W, 0xfd, 0x8e, 0x00
	stb_dri A, 0xfd, 0x8a, 0x00
	lds de, 0
	call DrawLine
	stb_dri W, 0xfd, 0x9e, 0x00
	stb_dri A, 0xfd, 0x92, 0x00
	lda xde, (xsp + 118)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7

PsTrkSw_Confirm_DrawMark:
	call DrawStringCentered

PsTrkSw_Confirm_DrawSecondary:
	stb_dri W, 0xfd, 0x96, 0x00
	stb_dri A, 0xfd, 0x86, 0x00
	ld xde, (xsp + 4)
	ld xde, (xde + 28)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 38)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7
	jrl PsTrkSw_DrawAndReturn

PsTrkSw_Select:
	ld_sril XWA, (xsp + 0x00b2)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld_sril XBC, (xsp + 0x00ae)
	cp bc, 0xffff
	jr z, PsTrkSw_Select_CalcPos
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 32)
	ld (xwa), bc

PsTrkSw_Select_CalcPos:
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 22)
	stb_dri W, 0xfd, 0xa8, 0x00
	cpw (xbc), 0x8
	jr nc, PsTrkSw_Select_SetE3
	ldw (xwa), 0x96
	jr PsTrkSw_Select_DrawBox

PsTrkSw_Select_SetE3:
	ldw (xwa), 0xe3

PsTrkSw_Select_DrawBox:
	stb_dri W, 0xfd, 0xa6, 0x00
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
	stb_dri A, 0xfd, 0x92, 0x00
	call GetBoxCenter
	stb_dri W, 0xfd, 0xa6, 0x00
	ld xbc, (xsp + 4)
	ld xbc, (xbc + 32)
	ld bc, (xbc)
	sla bc, 1
	lda xde, (xsp + 8)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	call DrawBox
	stb_dri W, 0xfd, 0xa6, 0x00
	stb_dri A, 0xfd, 0x92, 0x00
	ld xde, (xsp + 4)
	ld xde, (xde + 32)
	ld de, (xde)
	sla de, 2
	lda xhl, (xsp + 18)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7

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
	cpl_sri_rm XWA, 0xfd, 0xae, 0x00
	jrl nz, PsTrkSw_ReturnZero
	jr PsTrkSw_HitTest_Match

PsTrkSw_HitTest_Track8Plus:
	ld wa, (xwa)
	add wa, 0x78
	extz xwa
	cpl_sri_rm XWA, 0xfd, 0xae, 0x00
	jrl nz, PsTrkSw_ReturnZero

PsTrkSw_HitTest_Match:
	lds32 xhl, 1

PsTrkSw_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0xb2, 0x00
	ret

PsTrkSw_TrailingData:
	.incbin "includes/generated/v7_transplant_PsTrkSw_TrailingData.bin"
AcTrackSwitchProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1c0002e
	jrl z, AcTrkSw_OK
	cp xiz, 0x1c0002d
	jrl z, AcTrkSw_ReturnZero
	cp xiz, 0x1c00007
	jr z, AcTrkSw_SpecialDispatch
	cp xiz, 0x1c0000c
	jr z, AcTrkSw_Catchall
	cp xiz, 0x1c0000b
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
	ld xwa, 0x140000a
	ld xbc, 0x1e00092
	jr AcTrkSw_SpecialDispatch_CheckPart

AcTrkSw_SpecialDispatch:
	ld xwa, (xsp + 8)
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, AcTrkSw_SpecialDispatch_SetPart
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld de, (xhl + 22)
	extz xde
	ld xwa, 0x140000a
	ld xbc, 0x1e00093

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
	srl xwa, 0
	and xwa, 0xfff
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	and xwa, 0xff
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
	ld xbc, 0x1c0000f
	jr AcTrkSw_OK_SendConfirm

AcTrkSw_OK:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	calr PsTrackSwitchProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xsp + 4)
	srl xwa, 0
	and xwa, 0xfff
	cp wa, (xhl + 22)
	jr nz, PsTextBox_ZeroReturn
	ld xwa, (xsp + 4)
	ldiw_erp 0xe2, 0
	ld de, wa
	exts xde
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000e

AcTrkSw_OK_SendConfirm:
	call SendEvent

PsTextBox_ZeroReturn:
	lds32 xhl, 0

AcTrkSw_OK_Return:
	pop xiz
	inc 8, xsp
	ret

PsTextBoxProc:
	lda xsp, (xsp - 40)
	push xiz
	ld (xsp + 40), xde
	ld xiz, xwa
	cp xbc, 0x1e00089
	jrl z, AcTrkSw_Select_HighTrack
	cp xbc, 0x1c0000f
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
	ld xbc, 0x1e00089
	lds32 xde, 0
	call SendEvent
	ld (xsp + 16), xhl
	cp (xhl), 0x0
	jr nz, AcTrkSw_Reset_DrawTrack
	jrl AcTrkSw_Select_LowTrack

AcTrkSw_Reset_UpdateIndex:
	ld xwa, (xsp + 40)
	ld (xsp + 16), xwa

AcTrkSw_Reset_DrawTrack:
	.byte 0xaf, 0x10, 0x20, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xaf, 0x18, 0x20, 0x98, 0x24, 0x26, 0xdb, 0x86
	.byte 0xde, 0x88, 0xd8, 0x61, 0x28, 0x1d, 0xa3, 0x06
	.byte 0xff, 0xbf, 0x1e, 0x63, 0xaf, 0x1e, 0x21, 0xbf
	.byte 0x10, 0x61, 0xde, 0x88, 0xd8, 0x61, 0x28, 0x0b
	.byte 0x00, 0x00, 0x39, 0x1d, 0x1d, 0x08, 0xff, 0xbf
	.byte 0x0e, 0x37, 0xaf, 0x10, 0x20, 0xaf, 0x18, 0x21
	.byte 0x1d, 0x33, 0x22, 0xfb, 0xbf, 0x1c, 0x31, 0x99
	.byte 0x04, 0x20, 0x91, 0xa0, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0x91, 0x21, 0xd8, 0x81, 0xbf, 0x24
	.byte 0x51, 0xaf, 0x14, 0x20, 0xa8, 0x1c, 0x20, 0x1d
	.byte 0x0a, 0x22, 0xfb, 0xbf, 0x1c, 0x30, 0x98, 0x06
	.byte 0x21, 0x98, 0x02, 0xa1, 0xdb, 0xa1, 0xd9, 0x8a
	.byte 0xaf, 0x14, 0x20, 0x98, 0x24, 0x21, 0xea, 0x12
	.byte 0xd9, 0x52, 0xbf, 0x08, 0x52, 0xbf, 0x12, 0x02
	.byte 0x00, 0x00, 0xd9, 0xd8, 0x73, 0xb6, 0x00
AcTrkSw_Select:
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x28, 0xa8, 0xaf, 0x0e
	.byte 0x20, 0x38, 0x1d, 0xa0, 0x01, 0xff, 0xef, 0x60
	.byte 0xaf, 0x0a, 0x20, 0xf3, 0x07, 0xe0, 0xec, 0x30
	.byte 0xbf, 0x0e, 0x60, 0xb0, 0x00, 0x00, 0xbf, 0x1c
	.byte 0x30, 0x98, 0x04, 0x22, 0x90, 0xa2, 0xaf, 0x14
	.byte 0x20, 0xa8, 0x1c, 0x21, 0xaf, 0x0a, 0x20, 0x1d
	.byte 0x4d, 0x23, 0xfb, 0xdb, 0x8e, 0xaf, 0x0a, 0x20
	.byte 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x64, 0xde
	.byte 0x88, 0xdb, 0xf0, 0x66, 0x18, 0xaf, 0x0e, 0x20
	.byte 0xb0, 0x00, 0x0d, 0xaf, 0x0a, 0x20, 0xf3, 0x07
	.byte 0xe0, 0xf8, 0x30, 0xbf, 0x0e, 0x60, 0xf4, 0xe0
	.byte 0x00, 0x00, 0xbf, 0x0e, 0x60
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
	pushm (xhl + 32)
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
	incm 1, (xsp + 18)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 18)
	cp bc, (xwa + 36)
	jrl c, AcTrkSw_Select

AcTrkSw_Select_CheckTrackNum:
	ld	xwa, (xsp+24)
	push	xwa
	call	16712469
	inc	4, xsp
AcTrkSw_Select_LowTrack:
	lds32 xhl, 0
	jr AcTrkSw_Select_DrawTrack

AcTrkSw_Select_HighTrack:
	lda_24 xhl, (Str_No_0x514)

AcTrkSw_Select_DrawTrack:
	pop xiz
	lda xsp, (xsp + 40)
	ret

AcLanguageTextProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00089
	jr z, AcTrkSw_ShowHide_CheckDirty
	cp xbc, 0x1c0000d
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
	ld xbc, 0x1e0009f
	lds32 xde, 0
	call ApFuncCall
	ldb_da a, (0x0340e4)
	extz wa
	sla wa, 2
	ld_sril3 XDE, 0x07, 0xec, 0xe0
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0
	jr AcTrkSw_ShowHide_Refresh

AcTrkSw_ShowHide_CheckDirty:
	lda_24 xhl, (Str_No_0x51E)

AcTrkSw_ShowHide_Refresh:
	pop xiz
	ret

LanguageCheck:
	cp xbc, 0x1e0009f
	jr nz, ObjectProc_ClassDispatch
	lda_24 xhl, (Str_No_0x52E)
	ret

; ObjectProc class dispatch with dual handler
ObjectProc_ClassDispatch:
	lds32 xhl, 0
	ret

TrTransposeBoxProc:
	jp AcTranspose_ParamData_End

TrChordBoxProc:
	jp AcChordBoxProc_Entry

ObjectProc:
	stb_dri L, 0xfd, 0x70, 0xff
	push xiz
	stl_dri XDE, 0xfd, 0x88, 0x00
	stl_dri XBC, 0xfd, 0x8c, 0x00
	stl_dri XWA, 0xfd, 0x90, 0x00
	ld_sril XWA, (xsp + 0x0090)
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027ed6)
	add xwa, xbc
	ld xix, (xwa)
	ld_sril XWA, (xsp + 0x0090)
	ld xbc, 0x1e00000
	lds32 xde, 0
	call (xix)
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x008c)
	sub xwa, 0x1e00010
	cp xwa, 0x0
	jrl lt, ExitWindow_Init
	cp xwa, 0x13
	jrl gt, ExitWindow_Init
	add xwa, xwa
	add xwa, Str_No_0x58E
	ld wa, (xwa)
	lda_24 xix, (AcTrkSw_Return)
	jp_ind 8, 0x07, 0xf0, 0xe0

AcTrkSw_Return:
	.byte 0xee, 0x8b, 0x78, 0xaa, 0x02, 0xee, 0x88, 0x41
	.byte 0x01, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x78, 0x55, 0x02, 0xee, 0x88, 0x41, 0x02
	.byte 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22
	.byte 0x78, 0x46, 0x02, 0xee, 0x88, 0x41, 0x03, 0x00
	.byte 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x78
	.byte 0x37, 0x02, 0xee, 0x88, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x78, 0x28
	.byte 0x02, 0xee, 0x88, 0x41, 0x04, 0x00, 0xe0, 0x01
	.byte 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x78, 0x19, 0x02
	.byte 0xe3, 0xfd, 0x88, 0x00, 0x20, 0xb0, 0x00, 0x00
	.byte 0xee, 0x88, 0x41, 0x05, 0x00, 0xe0, 0x01, 0xe3
	.byte 0xfd, 0x88, 0x00, 0x22, 0x1e, 0x7e, 0x06, 0xbf
	.byte 0x04, 0x63, 0xe3, 0xfd, 0x90, 0x00, 0x20, 0x41
	.byte 0x14, 0x00, 0xe0, 0x01, 0x42, 0x10, 0x00, 0x60
	.byte 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xeb, 0xe3, 0x66
	.byte 0x12, 0x0b, 0xea, 0x00, 0x0b, 0x90, 0xa8, 0xe3
	.byte 0xfd, 0x8c, 0x00, 0x20, 0x38, 0x1d, 0xe4, 0x05
	.byte 0xff, 0xef, 0x60, 0xaf, 0x04, 0x23, 0x78, 0x16
	.byte 0x02, 0xee, 0x88, 0x41, 0x06, 0x00, 0xe0, 0x01
	.byte 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x78, 0xc1, 0x01
	.byte 0xbf, 0x08, 0x32, 0xe3, 0xfd, 0x90, 0x00, 0x20
	.byte 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d, 0x53, 0x92
	.byte 0xfa, 0xbf, 0x08, 0x31, 0xe9, 0x8b, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x20, 0xa0, 0x83, 0xb8, 0x04, 0x32
	.byte 0x83, 0x3f, 0x59, 0x6e, 0x0b, 0x0b, 0xea, 0x00
	.byte 0x0b, 0x94, 0xa8, 0xa2, 0x20, 0x38, 0x68, 0x15
	.byte 0xe3, 0xfd, 0x88, 0x00, 0x20, 0xa0, 0x81, 0xa2
	.byte 0x20, 0x81, 0x3f, 0x5a, 0x6e, 0x10, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x9a, 0xa8, 0x38, 0x1d, 0x70, 0x07
	.byte 0xff, 0xef, 0x60, 0x78, 0xa3, 0x01, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xa2, 0xa8, 0x38, 0x1d, 0x70, 0x07
	.byte 0xff, 0xef, 0x60, 0xee, 0x88, 0x41, 0x07, 0x00
	.byte 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x78
	.byte 0x57, 0x01, 0xbf, 0x08, 0x32, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xe3, 0xfd, 0x88, 0x00, 0x20
	.byte 0x98, 0x08, 0x21, 0xe9, 0x12, 0xbf, 0x08, 0x30
	.byte 0xe9, 0x80, 0x80, 0x21, 0xc9, 0xca, 0x41, 0x20
	.byte 0x00, 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60
	.byte 0x02, 0x41, 0x08, 0x00, 0xe0, 0x01, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x22, 0x78, 0xb8, 0x00, 0xbf, 0x08
	.byte 0x32, 0xe3, 0xfd, 0x90, 0x00, 0x20, 0x41, 0x19
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xe3
	.byte 0xfd, 0x90, 0x00, 0x21, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x20, 0xb8, 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0
	.byte 0x81, 0x81, 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00
	.byte 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02
	.byte 0x41, 0x09, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88
	.byte 0x00, 0x22, 0x68, 0x7a, 0xbf, 0x08, 0x32, 0xe3
	.byte 0xfd, 0x90, 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0
	.byte 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x21, 0xe3, 0xfd, 0x88, 0x00, 0x20, 0xb8
	.byte 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0, 0x81, 0x81
	.byte 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00, 0xe8, 0x12
	.byte 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02, 0x41, 0x0a
	.byte 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22
	.byte 0x68, 0x3c, 0xbf, 0x08, 0x32, 0xe3, 0xfd, 0x90
	.byte 0x00, 0x20, 0x41, 0x19, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xe3, 0xfd, 0x90, 0x00, 0x21
	.byte 0xe3, 0xfd, 0x88, 0x00, 0x20, 0xb8, 0x08, 0x61
	.byte 0xbf, 0x08, 0x31, 0xa0, 0x81, 0x81, 0x21, 0xc9
	.byte 0xca, 0x41, 0x20, 0x00, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x00, 0x00, 0x60, 0x02, 0x41, 0x0b, 0x00, 0xe0
	.byte 0x01, 0xe3, 0xfd, 0x88, 0x00, 0x22, 0x1d, 0x53
	.byte 0x92, 0xfa, 0x78, 0x8c, 0x00, 0xbf, 0x08, 0x32
	.byte 0xe3, 0xfd, 0x90, 0x00, 0x20, 0x41, 0x19, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xe3, 0xfd
	.byte 0x90, 0x00, 0x21, 0xe3, 0xfd, 0x88, 0x00, 0x20
	.byte 0xb8, 0x08, 0x61, 0xbf, 0x08, 0x31, 0xa0, 0x81
	.byte 0x81, 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00, 0xe8
	.byte 0x12, 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02, 0x41
	.byte 0x0c, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x1d, 0x53, 0x92, 0xfa, 0x68, 0x60, 0xee
	.byte 0x88, 0x41, 0x0d, 0x00, 0xe0, 0x01, 0xe3, 0xfd
	.byte 0x88, 0x00, 0x22, 0x68, 0x0c, 0xee, 0x88, 0x41
	.byte 0x0e, 0x00, 0xe0, 0x01, 0xe3, 0xfd, 0x88, 0x00
	.byte 0x22, 0x1e, 0x79, 0x04, 0x68, 0x41, 0xbf, 0x08
	.byte 0x32, 0xe3, 0xfd, 0x90, 0x00, 0x20, 0x41, 0x19
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xbf
	.byte 0x08, 0x30, 0xe3, 0xfd, 0x88, 0x00, 0x80, 0xeb
	.byte 0xa8, 0x80, 0x27, 0x68, 0x22, 0xe3, 0xfd, 0x88
	.byte 0x00, 0x20, 0x38, 0x1d, 0x15, 0x03, 0xff, 0xef
	.byte 0x64, 0xeb, 0xa8, 0x68, 0x12
ExitWindow_Init:
	ld_sril XWA, (xsp + 0x0090)
	ld_sril XBC, (xsp + 0x008c)
	ld_sril XDE, (xsp + 0x0088)
	calr InheritedProc
	pop xiz
	stb_dri L, 0xfd, 0x90, 0x00
	ret

InitializeObjectTable:
	lda xsp, (xsp - 14)
	pushw iz
	stiw_da (0x02bc12), 0x0000
	lda_24 xwa, (0x027ed2)
	lda xbc, (xwa + 10)
	lda xde, (xwa + 8)
	lda xhl, (xwa + 4)
	ld xix, xwa
	stb_dri E, 0xe1, 0x40, 0x3d

ExitWindow_Paint:
	ld xwa, 0xffffffff
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
	jr c, ExitWindow_Paint
	lda_24 xbc, (0x0328fc)
	ld xwa, xbc
	stb_dri B, 0xe5, 0xc0, 0x01

ExitWindow_Confirm:
	ld xiy, Str_No_0x5B6
	ld xix, xwa
	lds bc, 7
	ldirw
	lda xwa, (xwa + 14)
	cp xwa, xde
	jr c, ExitWindow_Confirm
	lda_24 xbc, (0x032abc)
	ld xwa, xbc
	stb_dri B, 0xe5, 0x00, 0x16

ExitWindow_OK:
	ld xiy, Str_No_0x5C6
	ld xix, xwa
	ldw bc, 0xb
	ldirw
	lda xwa, (xwa + 22)
	cp xwa, xde
	jr c, ExitWindow_OK
	lda xbc, (xsp + 2)
	ld xwa, 0x1600005
	ld (xbc), xwa
	lda_24 xwa, (SupportClassProc)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x37
	lda_24 xwa, (NakaInst_IT_Off_0x8)
	ld (xbc + 10), xwa
	ldw wa, 0x260
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, 0x1600006
	ld (xbc), xwa
	lda_24 xwa, (ModeProc)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x20
	lda_24 xwa, (0x0328fc)
	ld (xbc + 10), xwa
	ldw wa, 0x180
	calr RegisterObjectTable
	lda xbc, (xsp + 2)
	ld xwa, 0x1600007
	ld (xbc), xwa
	lda_24 xwa, (TitleProc)
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0x100
	lda_24 xwa, (0x032abc)
	ld (xbc + 10), xwa
	ldw wa, 0x1a0
	calr RegisterObjectTable
	lds iz, 0

ExitWindow_Return:
	lda xbc, (xsp + 2)
	ld xwa, 0x1600010
	ld (xbc), xwa
	lda_24 xwa, (ViewableProc)
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
	.byte 0xef, 0x6e, 0x3e, 0xbf, 0x08, 0x51, 0xde, 0xa8
	.byte 0xd7, 0xfa, 0x98, 0x9f, 0x08, 0xf0, 0x6b, 0x2f
	.byte 0xf2, 0xd2, 0x7e, 0x02, 0x30, 0xbf, 0x04, 0x60
	.byte 0xd7, 0xfa, 0x88, 0xe8, 0x12, 0x41, 0x0e, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
InputDialog_GetText:
	ld xwa, (xsp + 4)
	add xwa, xhl
	add iz, (xwa + 8)
	inc1w_erp 0xfa
	add xhl, 0xe
	stw_erp WA, 0xfa
	cp wa, (xsp + 8)
	jr ule, InputDialog_GetText

InputDialog_GetText_CopyAndReturn:
	ld hl, iz
	pop xiz
	inc 6, xsp
	ret

CheckViewObject:
	ld xbc, xwa
	srl xbc, 0
	and xbc, 0xfff
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, (0x027edc)
	add xbc, xde
	ld xbc, (xbc)
	or xbc, xbc
	jr nz, InputDialog_Paint
	lds hl, 0
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
	and xhl, 0xfff
	ld de, hl
	ld wa, de
	extz xwa
	ld (xsp + 8), xwa
	sla xwa, 3
	sub xwa, (xsp + 8)
	add xwa, xbc
	ld xbc, xwa
	lda_24 xhl, (0x027ed2)
	ld (xsp + 4), xhl
	add xhl, xbc
	ld xiz, (xhl + 10)
	lds iy, 0

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
	lda_24 xwa, (Str_No_0x5DE)
	ld (xix), xwa
	incm 1, (xhl + 8)
	ld xhl, (xsp + 8)
	sll xhl, 0
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
	srl xwa, 0
	and xwa, 0xfff
	ld hl, wa
	ld bc, hl
	extz xbc
	ld xwa, xbc
	sll xwa, 3
	sub xwa, xbc
	add xwa, xwa
	lda_24 xix, (0x027ed2)
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
	lda_24 xwa, (Str_No_0x5E0)
	ld (xde), xwa
	decm 1, (xbc + 8)
	pop xiz
	ret

InheritedProc:
	dec 4, xsp
	push xiz
	ldl_da xhl, (0x02bc14)
	ld (xsp + 4), xhl
	srl xhl, 0
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
	lda_24 xix, (0x027ed2)
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
	stl_da (0x02bc14), xiy
	ld xhl, xiy
	srl xhl, 0
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
	stl_da (0x02bc14), xbc
	jr RootObject_GetterBlock

TitleWidget_Init:
	lds32 xwa, 0

; GetRootObject/Event/Param block
RootObject_GetterBlock:
	ld xhl, xwa
	pop xiz
	inc 4, xsp
	ret

GetRootObject:
	ldl_da xhl, (0x02bc18)
	ret

GetRootEvent:
	ldl_da xhl, (0x02bc1c)
	ret

GetRootParam:
	ldl_da xhl, (0x02bc20)
	ret

SetRootObject:
	stl_da (0x02bc18), xwa
	ret

SetRootEvent:
	stl_da (0x02bc1c), xwa
	ret

SetRootParam:
	stl_da (0x02bc20), xwa
	ret

GetFocusObject:
	ldl_da xhl, (0x02bc24)
	ret

GetFocusEvent:
	ldl_da xhl, (0x02bc28)
	ret

GetFocusParam:
	ldl_da xhl, (0x02bc2c)
	ret

ClassProc:
	stb_dri L, 0xfd, 0xea, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x12, 0x01
	stl_dri XBC, 0xfd, 0x16, 0x01
	ld xbc, xwa
	srl xbc, 0
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
	lda_24 xiy, (0x027ed2)
	ld xbc, xiy
	add xbc, xde
	ld xbc, (xbc + 10)
	ld (xsp + 4), xbc
	ld_sril XIX, (xsp + 0x0116)
	ld (xsp + 14), xix
	stb_dri B, 0xfd, 0x92, 0x00
	cp xix, 0x1e0000e
	jrl z, TitleWidget_OK_Forward
	cp xix, 0x1e0000d
	jrl z, TitleWidget_OK
	ld bc, (xsp + 8)
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 3
	add xhl, (xsp + 4)
	cp xix, 0x1e0000f
	jr z, TitleWidget_Paint
	ld xbc, xix
	cp xbc, 0x1e00015
	jr z, ClassProc_Event_LoadFromOffset
	ld xiz, xhl
	inc 4, xhl
	ld xbc, (xsp + 14)
	sub xbc, 0x1e00000
	cp xbc, 0x0
	jrl lt, TitleWidget_OK_AdvanceDone
	cp xbc, 0x7
	jrl gt, TitleWidget_OK_AdvanceDone
	add xbc, xbc
	add xbc, Str_No_0x5E2
	ld bc, (xbc)
	lda_24 xix, (ClassProc_Event_LoadFromWA)
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	ld hl, (xiz + 8)
	extz xhl
	jrl ClassProc_ReturnWithStatus
	ld_sril XBC, (xsp + 0x0112)
	ld xde, xwa
	cp xwa, 0xffffffff
	jrl z, ClassProc_ReturnZeroJmp

TitleWidget_Paint_CheckState:
	cp xde, xbc
	jr nz, TitleWidget_Paint_DrawText
	lds32 xhl, 1
	jrl ClassProc_ReturnWithStatus

TitleWidget_Paint_DrawText:
	.byte 0xea, 0x88, 0xe8, 0xef, 0x00, 0xe8, 0xcc, 0xff
	.byte 0x0f, 0x00, 0x00, 0xe8, 0x12, 0xe8, 0x8b, 0xeb
	.byte 0xee, 0x03, 0xe8, 0xa3, 0xeb, 0x83, 0xed, 0x88
	.byte 0xeb, 0x80, 0xa8, 0x0a, 0x20, 0xbf, 0x04, 0x60
	.byte 0xd7, 0xea, 0xa8, 0xda, 0x88, 0xe8, 0x12, 0xe8
	.byte 0x8a, 0xea, 0x82, 0xe8, 0x82, 0xea, 0xee, 0x03
	.byte 0xaf, 0x04, 0x82, 0xaa, 0x04, 0x22, 0xea, 0xcf
	.byte 0xff, 0xff, 0xff, 0xff, 0x6e, 0xb9, 0x78, 0xaa
	.byte 0x01, 0xae, 0x10, 0x20, 0x38, 0x3a, 0x1d, 0x70
	.byte 0x07, 0xff, 0xef, 0x60, 0xe8, 0xa8, 0xbf, 0x0a
	.byte 0x60, 0x68, 0x1b
TitleWidget_Select:
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1e00025
	call SendEvent
	lds32 xwa, 1
	add (xsp + 10), xwa

TitleWidget_Confirm:
	.byte 0xf3, 0xfd, 0x92, 0x00, 0x32, 0xea, 0x88, 0xaf
	.byte 0x0a, 0x80, 0x80, 0x21, 0xc9, 0xd8, 0x6e, 0xd5
	.byte 0xe3, 0xfd, 0x12, 0x01, 0x20, 0x38, 0x3a, 0x1d
	.byte 0xe4, 0x05, 0xff, 0xf3, 0xfd, 0x9a, 0x00, 0x30
	.byte 0x38, 0xe3, 0xfd, 0x1e, 0x01, 0x20, 0x38, 0x1d
	.byte 0x70, 0x07, 0xff, 0xbf, 0x10, 0x37, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xe9, 0x81, 0xe8
	.byte 0x81, 0xe9, 0xee, 0x03, 0xaf, 0x04, 0x81, 0xa9
	.byte 0x04, 0x21, 0xe9, 0xcf, 0xff, 0xff, 0xff, 0xff
	.byte 0x76, 0x32, 0x01, 0xe9, 0x88, 0x41, 0x05, 0x00
	.byte 0xe0, 0x01, 0xe3, 0xfd, 0x12, 0x01, 0x22, 0x1e
	.byte 0x49, 0xfe, 0x78, 0x20, 0x01, 0x41, 0x19, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xf3, 0xfd
	.byte 0x92, 0x00, 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x64, 0xeb, 0x12, 0x78, 0x79, 0x01, 0xa3
	.byte 0x21, 0xe9, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x0f, 0xe9, 0x88, 0x41, 0x07, 0x00, 0xe0, 0x01
	.byte 0xe3, 0xfd, 0x12, 0x01, 0x22, 0x1e, 0x13, 0xfe
TitleWidget_Confirm_DrawLayout:
	.byte 0xe3, 0xfd, 0x12, 0x01, 0x20, 0xa8, 0x04, 0x20
	.byte 0x80, 0x3f, 0x00, 0x7e, 0xdf, 0x00, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xe9, 0x81, 0xe8
	.byte 0x81, 0xe9, 0xee, 0x03, 0xaf, 0x04, 0x81, 0xa9
	.byte 0x10, 0x20, 0x38, 0xf3, 0xfd, 0x96, 0x00, 0x30
	.byte 0x38, 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60, 0xe8
	.byte 0xa8, 0xbf, 0x0a, 0x60, 0x68, 0x1b
TitleWidget_Confirm_DrawRow:
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1e00025
	call SendEvent
	lds32 xwa, 1
	add (xsp + 10), xwa

TitleWidget_Confirm_DrawRowLoop:
	stb_dri B, 0xfd, 0x92, 0x00
	ld xwa, xde
	add xwa, (xsp + 10)
	ld a, (xwa)
	cps a, 0
	jr nz, TitleWidget_Confirm_DrawRow
	lds32 xwa, 0
	ld (xsp + 14), xwa
	ld (xsp + 10), xwa
	jr TitleWidget_Confirm_DrawItem

TitleWidget_Confirm_DrawRowNext:
	.byte 0x9f, 0x08, 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xe9
	.byte 0x81, 0xe8, 0x81, 0xe9, 0xee, 0x03, 0xaf, 0x04
	.byte 0x81, 0xaf, 0x0e, 0x20, 0xe8, 0xee, 0x02, 0xa9
	.byte 0x14, 0x80, 0xa0, 0x20, 0x38, 0xbf, 0x16, 0x30
	.byte 0x38, 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60, 0xf3
	.byte 0xfd, 0x92, 0x00, 0x30, 0xaf, 0x0a, 0x80, 0x80
	.byte 0x21, 0xc9, 0xca, 0x41, 0x20, 0x00, 0xe8, 0x12
	.byte 0xe8, 0xc8, 0x00, 0x00, 0x60, 0x02, 0xbf, 0x12
	.byte 0x32, 0x41, 0x26, 0x00, 0xe0, 0x01, 0x1d, 0x53
	.byte 0x92, 0xfa, 0xaf, 0x0e, 0x8b, 0xe3, 0xfd, 0x12
	.byte 0x01, 0x21, 0xa1, 0x20, 0xe8, 0xe0, 0x6e, 0x10
	.byte 0xbf, 0x12, 0x30, 0x38, 0xa9, 0x04, 0x20, 0x38
	.byte 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60, 0x68, 0x1a
TitleWidget_Confirm_SkipEmpty:
	lds32 xbc, 1
	add (xsp + 10), xbc
	ld_sril XWA, (xsp + 0x0112)
	sub (xwa), xbc

TitleWidget_Confirm_DrawItem:
	stb_dri W, 0xfd, 0x92, 0x00
	add xwa, (xsp + 10)
	cp (xwa), 0x0
	jrl nz, TitleWidget_Confirm_DrawRowNext

ClassProc_ReturnZeroJmp:
	lds32 xhl, 0
	jr ClassProc_ReturnWithStatus

TitleWidget_OK:
	ld xbc, 0x1e00019
	call SendEvent
	stb_dri A, 0xfd, 0x92, 0x00
	ld_sril XWA, (xsp + 0x0112)
	add xbc, (xwa)
	ld a, (xbc)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1e0000d
	ld_sril XDE, (xsp + 0x0112)
	jr TitleWidget_OK_Advance

TitleWidget_OK_Forward:
	ld xbc, 0x1e00019
	call SendEvent
	stb_dri W, 0xfd, 0x92, 0x00
	add_sril_rm XWA, 0xfd, 0x12, 0x01
	ld a, (xwa)
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1e0000e
	ld_sril XDE, (xsp + 0x0112)

TitleWidget_OK_Advance:
	call SendEvent
	jr ClassProc_ReturnWithStatus

TitleWidget_OK_AdvanceDone:
	ld_sril XBC, (xsp + 0x0116)
	ld_sril XDE, (xsp + 0x0112)
	calr ObjectProc

ClassProc_ReturnWithStatus:
	pop xiz
	stb_dri L, 0xfd, 0x16, 0x01
	ret

SupportClassProc:
	push xiz
	ld xix, xwa
	ld xhl, xix
	srl xhl, 0
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
	lda_24 xhl, (0x027edc)
	add xhl, xiy
	ld xiy, (xhl)
	extz xiz
	ld xhl, xiz
	add xhl, xhl
	add xhl, xiz
	sll xhl, 2
	add xhl, xiy
	cp xbc, 0x1e00027
	jr z, TitleWidget_Default
	cp xbc, 0x1e0000f
	jr z, SupportClass_PopIzRet
	cp xbc, 0x1e00000
	jr nz, SupportClass_VirtualDispatch
	ld xhl, 0x1600005
	jr SupportClass_PopIzRet

TitleWidget_Default:
	ld hl, (xhl + 6)
	extz xhl
	jr SupportClass_PopIzRet

; SupportClass virtual dispatch with type check
SupportClass_VirtualDispatch:
	cp xix, 0x1600005
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
	srl xde, 0
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
	lda_24 xiy, (0x027ed2)
	ld xix, xiy
	add xix, xiz
	ld xix, (xix + 10)
	extz xde
	sll xde, 2
	cp xbc, 0x1e00015
	jr z, FunctionProc_Dispatch
	ld xhl, xde
	add xhl, xix
	cp xbc, 0x1e0002a
	jr z, ResourceWidget_Init_Loop
	cp xbc, 0x1e0000f
	jr z, FuncProc_PopIzSkip4Ret
	cp xbc, 0x1e00000
	jr z, ResourceWidget_Init
	ld xde, (xsp + 4)
	calr ObjectProc
	jr FuncProc_PopIzSkip4Ret

ResourceWidget_Init:
	ld xhl, 0x1600001
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
	srl xhl, 0
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
	lda_24 xhl, (0x027edc)
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
	cp xbc, 0x1e00015
	jr z, ApFuncCall_VirtualDispatch
	cp xbc, 0x1e00000
	jrl nz, FunctionProc
	ld xhl, 0x1600002
	ret

; ApFuncCall object ID lookup dispatch
ApFuncCall_VirtualDispatch:
	ld xbc, xwa
	srl xbc, 0
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
	lda_24 xwa, (0x027edc)
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
	ld xbc, 0x1e00014
	ld xde, 0x1600002
	call SendEvent
	or xhl, xhl
	jr z, ResourceWidget_ReturnZero
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xfff
	ld xde, xiz
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	lds32 xhl, 0

ResourceWidget_Return:
	pop xiz
	inc 8, xsp
	ret

DefaultFunction:
	lds32 xhl, 0
	ret

MainFunctionProc:
	cp xbc, 0x1e00015
	jr z, MainFuncCall_DispatchDSP
	cp xbc, 0x1e00000
	jrl nz, FunctionProc
	ld xhl, 0x1600003
	ret

; MainFuncCall DSP variant dispatch
MainFuncCall_DispatchDSP:
	ld xbc, xwa
	srl xbc, 0
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
	lda_24 xwa, (0x027edc)
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
	lda_24 xbc, (0x027edc)
	add xbc, xde
	ld xbc, (xbc)
	ld (xsp + 4), xbc
	ld xbc, xiz
	cp xiz, 0x1c00013
	jrl z, ObjectEnum_Default
	cp xiz, 0x1c00014
	jrl z, ObjectEnum_Close
	cp xiz, 0x1e00015
	jrl z, ObjectEnum_Init
	cp xiz, 0x1e0000f
	jr z, NakaWidget_Return
	cp xiz, 0x1e00000
	jr z, NakaWidget_ReturnZero
	sub xbc, 0x1e0002b
	cp xbc, 0x0
	jrl lt, GetMode_DispatchDSP
	cp xbc, 0x5
	jrl gt, GetMode_DispatchDSP
	add xbc, xbc
	add xbc, Str_No_0x5F2
	ld bc, (xbc)
	lda_24 xix, (NakaWidget_ReturnZero)
	jp_ind 8, 0x07, 0xf0, 0xe4

NakaWidget_ReturnZero:
	ld xhl, 0x1600006
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
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	add xbc, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, 0x1e0002a
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
	ldl_da xhl, (0x03ef82)
	jrl GetMode_Epilogue10
	ldl_da xhl, (0x03ef86)
	jrl GetMode_Epilogue10

ObjectEnum_Close:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b0
	lds32 xde, 0
	call SendEvent
	ldl_da xwa, (0x03ef8a)
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, ObjectEnum_Paint

ObjectEnum_Destroy:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	ldl_da xwa, (0x03ef8a)
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, ObjectEnum_Destroy

ObjectEnum_Paint:
	ld xwa, (xsp + 10)
	ldl_da xde, (0x03ef82)
	lda_24 xbc, (0x027ed2)
	cp xwa, xde
	jr nz, ObjectEnum_OK
	ld xwa, 0x1800001
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x1
	ld_sril XWA, (xbc + 0x150a)
	ld (xsp + 4), xwa

ObjectEnum_OK:
	stl_da (0x03ef86), xde
	ldl_da xwa, (0x03ef8a)
	stl_da (0x03ef8e), xwa
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
	stl_da (0x03ef82), xwa
	ld xwa, (xde)
	stl_da (0x03ef8a), xwa
	jr ObjectEnum_OK_DispatchInline

ObjectEnum_OK_Dispatch:
	ld xwa, 0x1800000
	stl_da (0x03ef82), xwa
	ld xwa, 0x1a00000
	stl_da (0x03ef8a), xwa

ObjectEnum_OK_DispatchInline:
	.byte 0xe2, 0x8a, 0xef, 0x03, 0x20, 0xe8, 0x8a, 0xea
	.byte 0xef, 0x00, 0xea, 0xcc, 0xff, 0x0f, 0x00, 0x00
	.byte 0xd7, 0xe2, 0xa8, 0xbf, 0x08, 0x50, 0xda, 0x88
	.byte 0xe8, 0x12, 0xe8, 0x8a, 0xea, 0xee, 0x03, 0xe8
	.byte 0xa2, 0xea, 0x82, 0xea, 0x81, 0xa9, 0x0a, 0x26
	.byte 0x9f, 0x08, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xee, 0x83
	.byte 0xbb, 0x12, 0x02, 0xff, 0xff, 0xbb, 0x14, 0x02
	.byte 0xff, 0xff, 0x40, 0xff, 0xff, 0xff, 0xff, 0xbb
	.byte 0x0e, 0x60, 0xe2, 0x82, 0xef, 0x03, 0x22, 0x40
	.byte 0x01, 0x00, 0x40, 0x01, 0x41, 0x14, 0x00, 0xc0
	.byte 0x01, 0x1e, 0xa1, 0xfd, 0xe2, 0x8a, 0xef, 0x03
	.byte 0x22, 0x40, 0x01, 0x00, 0x40, 0x01, 0x41, 0x15
	.byte 0x00, 0xc0, 0x01, 0x1e, 0x8f, 0xfd, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x9a, 0x00, 0xe0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0x68, 0x28
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
	ld xwa, 0x1400001
	ld xbc, xiz
	ld xde, (xsp + 10)
	calr MainFuncCall

ObjectEnum_Return:
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
	ldl_da xhl, (0x03ef82)
	ret

GetModeOld:
	ldl_da xhl, (0x03ef86)
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
	ld xwa, 0x1200000
	ld (xbc), xwa
	ld xwa, 0xffffffff
	ld (xbc + 4), xwa
	ldw (xbc + 8), 0xffff
	lda_24 xwa, (Str_No_0x5FE)
	ld (xbc + 10), xwa
	ret

RegisterTitle:
	.byte 0xef, 0x6c, 0x3e, 0xbf, 0x04, 0x62, 0xe9, 0x8e
	.byte 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02
	.byte 0xff, 0x41, 0xbc, 0x2a, 0x03, 0x00, 0xeb, 0x81
	.byte 0xb1, 0x66, 0xaf, 0x04, 0x20, 0xb9, 0x04, 0x60
	.byte 0x9f, 0x10, 0x20, 0xb9, 0x08, 0x50, 0xaf, 0x0c
	.byte 0x20, 0xb9, 0x0a, 0x60, 0x40, 0xff, 0xff, 0xff
	.byte 0xff, 0xb9, 0x0e, 0x60, 0xb9, 0x12, 0x02, 0xff
	.byte 0xff, 0xb9, 0x14, 0x02, 0xff, 0xff, 0x5e, 0xef
	.byte 0x64, 0x0f, 0x06, 0x00
UnregisteredTitle:
	.byte 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02
	.byte 0xff, 0x41, 0xbc, 0x2a, 0x03, 0x00, 0xeb, 0x81
	.byte 0x40, 0x00, 0x00, 0x20, 0x01, 0xb1, 0x60, 0x40
	.byte 0xff, 0xff, 0xff, 0xff, 0xb9, 0x04, 0x60, 0xb9
	.byte 0x08, 0x02, 0xff, 0xff, 0xf2, 0x16, 0xa9, 0xea
	.byte 0x30, 0xb9, 0x0a, 0x60, 0x40, 0xff, 0xff, 0xff
	.byte 0xff, 0xb9, 0x0e, 0x60, 0xb9, 0x12, 0x02, 0xff
	.byte 0xff, 0xb9, 0x14, 0x02, 0xff, 0xff, 0x0e
TitleProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld xiz, xbc
	ld (xsp + 34), xwa
	ld xwa, (xsp + 34)
	srl xwa, 0
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
	lda_24 xwa, (0x027ed2)
	ld (xsp + 14), xwa
	add xwa, xbc
	lda xwa, (xwa + 10)
	ld (xsp + 24), xwa
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	ld xde, xiz
	ldw_da xwa, (0x02bc30)
	and wa, 0x11
	ld (xsp + 28), wa
	cp xiz, 0x1c00013
	jrl z, EnumList_HitTest_Match
	cp xiz, 0x1e000b7
	jrl z, EnumList_HitTest
	ld xwa, (xsp + 30)
	sll xwa, 3
	sub xwa, (xsp + 30)
	add xwa, xwa
	ld xbc, Str_No_0x602
	add xbc, xwa
	ld xwa, (xbc + 8)
	cp xiz, 0x1e000a6
	jrl z, EnumList_OK_ScrollUp_Wrap
	cp xiz, 0x1e000a5
	jrl z, EnumList_OK_ScrollDown_Done
	cp xiz, 0x1e0009e
	jrl z, EnumList_OK_ScrollDown
	cp xiz, 0x1e0007a
	jrl z, EnumList_OK_Next
	cp xiz, 0x1e0009b
	jrl z, EnumList_Return
	cp xiz, 0x1e0009a
	jrl z, EnumList_Paint
	cp xiz, 0x1e000aa
	jrl z, EnumList_Confirm_Forward
	cp xiz, 0x1e000b3
	jrl z, EnumList_ValueChange_A
	cp xiz, 0x1e00098
	jrl z, EnumList_PartChange_B
	cp xiz, 0x1e00079
	jrl z, EnumList_ShowHide_B
	ldw_da xwa, (0x02bc32)
	exts xwa
	ld (xsp + 18), xwa
	ld wa, (xsp + 28)
	ld (xsp + 28), wa
	cp xiz, 0x1e00078
	jrl z, EnumList_ShowHide_A
	cp xiz, 0x1e00099
	jrl z, EnumList_Close
	cp xiz, 0x1e00077
	jrl z, EnumList_Init_TypeB
	cp xiz, 0x1e00076
	jrl z, EnumList_Init
	ldl_da xwa, (0x03ef8a)
	cp xiz, 0x1c00028
	jrl z, EventDispatch_Return
	cp xiz, 0x1c00016
	jrl z, EventDispatch_OK
	cp xiz, 0x1c00015
	jrl z, EventDispatch_SelectMatch
	cp xiz, 0x1e00015
	jrl z, EventDispatch_Select
	cp xiz, 0x1e0000f
	jr z, EventDispatch_ScanLoop
	cp xiz, 0x1e00000
	jr z, TitleProc_EventDispatch
	sub xde, 0x1e00030
	cp xde, 0x0
	jrl lt, EnumList_Select_Send
	cp xde, 0x5
	jrl gt, EnumList_Select_Send
	add xde, xde
	add xde, Str_No_0x6AA
	ld de, (xde)
	lda_24 xix, (TitleProc_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8

; TitleProc event dispatch
TitleProc_EventDispatch:
	ld xhl, 0x1600007
	jrl TitleFunc_Epilogue34

EventDispatch_ScanLoop:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x78, 0xd0, 0x08, 0x9f, 0x16, 0x20, 0xe8
	.byte 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x04, 0x83, 0xa3, 0x20, 0x41
	.byte 0x2a, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x53
	.byte 0x92, 0xfa, 0x78, 0xaf, 0x08, 0x9f, 0x16, 0x20
	.byte 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d
	.byte 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83, 0xa3, 0x23
	.byte 0x78, 0x99, 0x08, 0x9f, 0x16, 0x20, 0xe8, 0x12
	.byte 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02
	.byte 0xff, 0xaf, 0x04, 0x83, 0xab, 0x04, 0x23, 0x78
	.byte 0x82, 0x08, 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0x9b, 0x08, 0x23, 0xeb, 0x13
	.byte 0x78, 0x69, 0x08
EventDispatch_Select:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0xab, 0x0a, 0x23, 0x78, 0x52, 0x08, 0xe2
	.byte 0x8a, 0xef, 0x03, 0x23, 0x78, 0x4a, 0x08, 0xe2
	.byte 0x8e, 0xef, 0x03, 0x23, 0x78, 0x42, 0x08
EventDispatch_SelectMatch:
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, EventDispatch_ConfirmHandler

EventDispatch_SelectDone:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00028
	lds32 xde, 0
	call SendEvent
	ldl_da xwa, (0x03ef8a)
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, EventDispatch_SelectDone

EventDispatch_ConfirmHandler:
	.byte 0xe2, 0x8a, 0xef, 0x03, 0x20, 0xf2, 0x8e, 0xef
	.byte 0x03, 0x60, 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0xab, 0x04, 0x20, 0xe8, 0xcf
	.byte 0xff, 0xff, 0xff, 0xff, 0x66, 0x0a, 0xaf, 0x1e
	.byte 0x20, 0xf2, 0x8a, 0xef, 0x03, 0x60, 0x68, 0x0a
EventDispatch_ConfirmSetup:
	ld xwa, 0x1a00000
	stl_da (0x03ef8a), xwa

EventDispatch_ConfirmForward:
	ldw (xhl + 18), 0xffff
	ldw (xhl + 20), 0xffff
	ld xwa, 0xffffffff
	ld (xhl + 14), xwa
	ldl_da xde, (0x03ef8a)
	ld xwa, 0x1400001
	ld xbc, 0x1c00015
	jrl EnumList_OK_CheckHitTest

EventDispatch_OK:
	.byte 0x9f, 0x0c, 0x26, 0xee, 0x12, 0xee, 0x88, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0xee, 0x88, 0x9b, 0x12, 0x3f
	.byte 0xff, 0xff, 0x76, 0xbe, 0x00, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x20, 0xe8, 0x13, 0xe8, 0xc8
	.byte 0x00, 0x00, 0xa0, 0x01, 0xbf, 0x08, 0x60, 0x9b
	.byte 0x14, 0x20, 0xe8, 0x13, 0xe8, 0xc8, 0x00, 0x00
	.byte 0xa0, 0x01, 0xbf, 0x12, 0x60, 0xaf, 0x08, 0x20
	.byte 0xe8, 0xef, 0x00, 0xe8, 0xcc, 0xff, 0x0f, 0x00
	.byte 0x00, 0xd8, 0x89, 0xaf, 0x08, 0x20, 0xd7, 0xe2
	.byte 0xa8, 0xbf, 0x0c, 0x50, 0xd9, 0x88, 0xe8, 0x12
	.byte 0xe8, 0x89, 0xe9, 0xee, 0x03, 0xe8, 0xa1, 0xe9
	.byte 0x81, 0xaf, 0x0e, 0x20, 0xe9, 0x80, 0xa8, 0x0a
	.byte 0x20, 0xbf, 0x04, 0x60, 0x9f, 0x0c, 0x20, 0xe8
	.byte 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x04, 0x83, 0xaf, 0x12, 0x21
	.byte 0xd9, 0x88, 0xbb, 0x14, 0x50, 0xe9, 0xcf, 0xff
	.byte 0xff, 0xff, 0xff, 0x66, 0x46, 0xaf, 0x12, 0x20
	.byte 0xe8, 0xef, 0x00, 0xe8, 0xcc, 0xff, 0x0f, 0x00
	.byte 0x00, 0xd8, 0x89, 0xaf, 0x12, 0x20, 0xd7, 0xe2
	.byte 0xa8, 0xbf, 0x0c, 0x50, 0xd9, 0x88, 0xe8, 0x12
	.byte 0xe8, 0x89, 0xe9, 0xee, 0x03, 0xe8, 0xa1, 0xe9
	.byte 0x81, 0xaf, 0x0e, 0x20, 0xe9, 0x80, 0xa8, 0x0a
	.byte 0x20, 0xbf, 0x04, 0x60, 0x9f, 0x0c, 0x20, 0xe8
	.byte 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x04, 0x83, 0xaf, 0x08, 0x20
	.byte 0xbb, 0x12, 0x50
EventDispatch_OKDone:
	.byte 0xaf, 0x18, 0x20, 0xa0, 0x20, 0xbf, 0x04, 0x60
	.byte 0xe2, 0x8a, 0xef, 0x03, 0x20, 0xf2, 0x8e, 0xef
	.byte 0x03, 0x60, 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0xab, 0x04, 0x20, 0xe8, 0xcf
	.byte 0xff, 0xff, 0xff, 0xff, 0x66, 0x0a, 0xaf, 0x1e
	.byte 0x20, 0xf2, 0x8a, 0xef, 0x03, 0x60, 0x68, 0x0a
EventDispatch_Default:
	ld xwa, 0x1a00000
	stl_da (0x03ef8a), xwa

EventDispatch_DefaultProc:
	.byte 0xe2, 0x8e, 0xef, 0x03, 0x20, 0xbb, 0x12, 0x50
	.byte 0xe2, 0x8e, 0xef, 0x03, 0x20, 0xe8, 0x89, 0xe9
	.byte 0xef, 0x00, 0xe9, 0xcc, 0xff, 0x0f, 0x00, 0x00
	.byte 0xd7, 0xe2, 0xa8, 0xbf, 0x0c, 0x50, 0xd9, 0x88
	.byte 0xe8, 0x12, 0xe8, 0x89, 0xe9, 0xee, 0x03, 0xe8
	.byte 0xa1, 0xe9, 0x81, 0xaf, 0x0e, 0x20, 0xe9, 0x80
	.byte 0xa8, 0x0a, 0x20, 0xbf, 0x04, 0x60, 0x9f, 0x0c
	.byte 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00, 0x00
	.byte 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83, 0xe2
	.byte 0x8a, 0xef, 0x03, 0x20, 0xbb, 0x14, 0x50, 0xe2
	.byte 0x8a, 0xef, 0x03, 0x22, 0x40, 0x01, 0x00, 0x40
	.byte 0x01, 0x41, 0x16, 0x00, 0xc0, 0x01, 0x1e, 0x34
	.byte 0xf8, 0xd8, 0xa9, 0x1e, 0x3f, 0x06, 0xd8, 0xaa
	.byte 0x1e, 0x8e, 0x06, 0x30, 0x10, 0x00, 0x78, 0x6c
	.byte 0x05
EventDispatch_Return:
	.byte 0xe8, 0x89, 0xe9, 0xef, 0x00, 0xe9, 0xcc, 0xff
	.byte 0x0f, 0x00, 0x00, 0xd7, 0xe2, 0xa8, 0xbf, 0x0c
	.byte 0x50, 0xd9, 0x88, 0xe8, 0x12, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x03, 0xe8, 0xa1, 0xe9, 0x81, 0xaf, 0x0e
	.byte 0x20, 0xe9, 0x80, 0xa8, 0x0a, 0x20, 0xbf, 0x04
	.byte 0x60, 0xaf, 0x22, 0x20, 0x41, 0x9a, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0x9f
	.byte 0x0c, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00
	.byte 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83
	.byte 0xbb, 0x12, 0x31, 0x91, 0x20, 0xd8, 0xcf, 0xff
	.byte 0xff, 0x76, 0xc0, 0x05, 0xe2, 0x8a, 0xef, 0x03
	.byte 0x20, 0xf2, 0x8e, 0xef, 0x03, 0x60, 0x91, 0x20
	.byte 0xe8, 0x13, 0xe8, 0xc8, 0x00, 0x00, 0xa0, 0x01
	.byte 0xf2, 0x8a, 0xef, 0x03, 0x60, 0xe8, 0x8a, 0x40
	.byte 0x01, 0x00, 0x40, 0x01, 0x41, 0x28, 0x00, 0xc0
	.byte 0x01, 0x1e, 0xa8, 0xf7, 0x9f, 0x0c, 0x20, 0xe8
	.byte 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x04, 0x83, 0xbb, 0x12, 0x02
	.byte 0xff, 0xff, 0x9f, 0x0c, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xeb, 0x88, 0xaf, 0x04, 0x80, 0xb8, 0x14, 0x02
	.byte 0xff, 0xff, 0xaf, 0x04, 0x83, 0x40, 0xff, 0xff
	.byte 0xff, 0xff, 0xbb, 0x0e, 0x60, 0xe2, 0x8a, 0xef
	.byte 0x03, 0x20, 0xe8, 0x89, 0xe9, 0xef, 0x00, 0xe9
	.byte 0xcc, 0xff, 0x0f, 0x00, 0x00, 0xd7, 0xe2, 0xa8
	.byte 0xbf, 0x0c, 0x50, 0xd9, 0x88, 0xe8, 0x12, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x03, 0xe8, 0xa1, 0xe9, 0x81
	.byte 0xf2, 0xdc, 0x7e, 0x02, 0x30, 0xe9, 0x80, 0xa0
	.byte 0x20, 0xbf, 0x04, 0x60, 0x9f, 0x0c, 0x20, 0xe8
	.byte 0x12, 0x41, 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x04, 0x83, 0xbb, 0x14, 0x02
	.byte 0xff, 0xff, 0xd2, 0x32, 0xbc, 0x02, 0x20, 0xe8
	.byte 0x13, 0x41, 0x28, 0x00, 0xc0, 0x01, 0x39, 0xe9
	.byte 0xa8, 0x39, 0xaf, 0x2a, 0x21, 0x42, 0xff, 0xff
	.byte 0xff, 0xff, 0x1d, 0x4a, 0x9e, 0xfa, 0x9f, 0x0c
	.byte 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00, 0x00
	.byte 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83, 0x9b
	.byte 0x12, 0x3f, 0xff, 0xff, 0x7e, 0xe5, 0x04, 0x30
	.byte 0x12, 0x00, 0x78, 0x37, 0x04
EnumList_Init:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0xbb, 0x0e, 0x31, 0xa1, 0x20, 0xe8, 0xcf
	.byte 0xff, 0xff, 0xff, 0xff, 0x6e, 0x05, 0xab, 0x04
	.byte 0x20, 0xb1, 0x60
EnumList_Init_CheckType:
	ld xhl, (xbc)
	jrl TitleFunc_Epilogue34

EnumList_Init_TypeB:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0xaf, 0x1e, 0x20, 0xbb, 0x0e, 0x60, 0x78
	.byte 0x9d, 0x04
EnumList_Close:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x76, 0x84
	.byte 0x04, 0x9f, 0x1c, 0x3f, 0x00, 0x00, 0x7e, 0x7c
	.byte 0x04, 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8
	.byte 0xa8, 0x38, 0xaf, 0x1a, 0x20, 0xaf, 0x2a, 0x21
	.byte 0x42, 0xff, 0xff, 0xff, 0xff, 0x78, 0xf0, 0x02
EnumList_ShowHide_A:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x76, 0x4c
	.byte 0x04, 0x9f, 0x1c, 0x3f, 0x00, 0x00, 0x7e, 0x44
	.byte 0x04, 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8
	.byte 0xa8, 0x38, 0xaf, 0x1a, 0x20, 0xaf, 0x2a, 0x21
	.byte 0x42, 0xff, 0xff, 0xff, 0xff, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0x78, 0x29, 0x04
EnumList_ShowHide_B:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x76, 0x10
	.byte 0x04, 0x9f, 0x1c, 0x3f, 0x00, 0x00, 0x6e, 0x1a
	.byte 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8
	.byte 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff
	.byte 0xff, 0xff, 0xff, 0x1d, 0x07, 0x9e, 0xfa, 0x78
	.byte 0xef, 0x03
EnumList_PartChange_A:
	ld xwa, 0x1c00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	call ResetApTimer
	cps hl, 0
	jrl nz, TitleProc_ReturnZero
	ld xwa, 0x1c00028
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 0
	ld xbc, (xsp + 42)
	ld xde, 0xffffffff
	jrl EnumList_OK_ScrollUp

EnumList_PartChange_B:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x76, 0xa4
	.byte 0x03, 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8
	.byte 0xa8, 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42
	.byte 0xff, 0xff, 0xff, 0xff, 0x1d, 0x4a, 0x9e, 0xfa
	.byte 0x78, 0x8a, 0x03
EnumList_ValueChange_A:
	.byte 0xaf, 0x1e, 0x20, 0xe8, 0xe0, 0x66, 0x38, 0x9f
	.byte 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00
	.byte 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83
	.byte 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x66, 0x17, 0x40
	.byte 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8, 0x38
	.byte 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff, 0xff
	.byte 0xff, 0xff, 0x1d, 0x4a, 0x9e, 0xfa
EnumList_ValueChange_B:
	ldw wa, 0x10
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_ValueChange_Done:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x66, 0x32
	.byte 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8
	.byte 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff
	.byte 0xff, 0xff, 0xff, 0x1d, 0x07, 0x9e, 0xfa, 0xdb
	.byte 0xd8, 0x6e, 0x17, 0x40, 0x28, 0x00, 0xc0, 0x01
	.byte 0x38, 0xe8, 0xa8, 0x38, 0xe8, 0xa8, 0xaf, 0x2a
	.byte 0x21, 0x42, 0xff, 0xff, 0xff, 0xff, 0x1d, 0x28
	.byte 0x9d, 0xfa
EnumList_Confirm_Init:
	ldw wa, 0x10
	jrl TitleProc_ClearAndReturn

EnumList_Confirm_Forward:
	ldw_da xwa, (0x02bc30)
	and wa, 0x1
	cps wa, 0
	scc16 nz, hl
	exts xhl
	jrl TitleFunc_Epilogue34

EnumList_Paint:
	.byte 0xaf, 0x1e, 0x20, 0xe8, 0xe0, 0x66, 0x37, 0x9f
	.byte 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00, 0x00
	.byte 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04, 0x83
	.byte 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x66, 0x17, 0x40
	.byte 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8, 0x38
	.byte 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff, 0xff
	.byte 0xff, 0xff, 0x1d, 0x4a, 0x9e, 0xfa
EnumList_Paint_DrawEntry:
	lds wa, 1
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_Paint_Loop:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x66, 0x32
	.byte 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8
	.byte 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff
	.byte 0xff, 0xff, 0xff, 0x1d, 0x07, 0x9e, 0xfa, 0xdb
	.byte 0xd8, 0x6e, 0x17, 0x40, 0x28, 0x00, 0xc0, 0x01
	.byte 0x38, 0xe8, 0xa8, 0x38, 0xe8, 0xa8, 0xaf, 0x2a
	.byte 0x21, 0x42, 0xff, 0xff, 0xff, 0xff, 0x1d, 0x28
	.byte 0x9d, 0xfa
EnumList_ReturnZero:
	lds wa, 1
	jrl TitleProc_ClearAndReturn

EnumList_Return:
	.byte 0xd2, 0x30, 0xbc, 0x02, 0x20, 0xd8, 0x33, 0x00
	.byte 0x66, 0x4c, 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff
	.byte 0x66, 0x63, 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38
	.byte 0xe8, 0xa8, 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21
	.byte 0x42, 0xff, 0xff, 0xff, 0xff, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0xdb, 0xd8, 0x6e, 0x48, 0x40, 0x28, 0x00
	.byte 0xc0, 0x01, 0x38, 0xe8, 0xa8, 0x38, 0xe8, 0xa8
	.byte 0xaf, 0x2a, 0x21, 0x42, 0xff, 0xff, 0xff, 0xff
	.byte 0x1d, 0x28, 0x9d, 0xfa, 0x68, 0x2f
EnumList_OK:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0x66, 0x17
	.byte 0x40, 0x28, 0x00, 0xc0, 0x01, 0x38, 0xe8, 0xa8
	.byte 0x38, 0xe8, 0xa8, 0xaf, 0x2a, 0x21, 0x42, 0xff
	.byte 0xff, 0xff, 0xff, 0x1d, 0x4a, 0x9e, 0xfa
TitleProc_ToggleFlag:
	ldw_da xde, (0x02bc30)
	xor de, 0x1
	stw_da (0x02bc30), xde
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1e000ba

EnumList_OK_CheckHitTest:
	calr MainFuncCall
	jrl TitleProc_ReturnZero

EnumList_OK_Next:
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0x9b, 0x12, 0x3f, 0xff, 0xff, 0xdb, 0x7e
	.byte 0xeb, 0x12, 0x78, 0xa9, 0x01
EnumList_OK_ScrollDown:
	ld xwa, (xsp + 30)
	or xwa, xwa
	jr z, EnumList_OK_ScrollDown_Wrap
	lds wa, 4
	calr TitleProc_SetResourceDirtyFlag
	jrl TitleProc_ReturnZero

EnumList_OK_ScrollDown_Wrap:
	lds wa, 4
	jrl TitleProc_ClearAndReturn

EnumList_OK_ScrollDown_Done:
	ld xbc, (xbc)
	ld xde, 0x1e000b7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff

EnumList_OK_ScrollUp:
	call SetApTimer
	jrl TitleProc_ReturnZero

EnumList_OK_ScrollUp_Wrap:
	ld xbc, (xbc)
	ld xde, 0x1e000b7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff
	call KillApTimer
	cps hl, 0
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
	ld xde, 0x1e000b7
	push xde
	ld xde, (xsp + 34)
	push xde
	ld xde, 0xffffffff
	call KillApTimer
	cps hl, 0
	jr nz, EnumList_OK_ScrollUp_Done
	jrl TitleProc_ReturnZero

EnumList_HitTest:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b7
	call DeleteEvent
	ld xbc, (xsp + 30)
	sll xbc, 3
	sub xbc, (xsp + 30)
	add xbc, xbc
	lda_24 xwa, (Str_No_0x606)
	add xwa, xbc
	ld xwa, (xwa)
	cp xwa, 0x1c00015
	jr nz, EnumList_HitTest_Loop
	calr GetModeNow
	cp xhl, 0x1800001
	jrl z, TitleProc_ReturnZero

EnumList_HitTest_Loop:
	calr GetModeNow
	cp xhl, 0x1800013
	jrl z, TitleProc_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
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
	.byte 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41, 0x16, 0x00
	.byte 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x83, 0xa3, 0x20, 0xee, 0x89, 0xaf, 0x1e, 0x22
	.byte 0x1e, 0x97, 0xf2, 0x40, 0x01, 0x00, 0x40, 0x01
	.byte 0xee, 0x89, 0xaf, 0x1e, 0x22, 0x1e, 0x8a, 0xf2
	.byte 0xaf, 0x1e, 0x20, 0xe8, 0xcf, 0x03, 0x00, 0x00
	.byte 0x00, 0x66, 0x5f, 0xe8, 0xcf, 0x02, 0x00, 0x00
	.byte 0x00, 0x66, 0x1e, 0xe8, 0xcf, 0x08, 0x00, 0x00
	.byte 0x00, 0x6e, 0x5f, 0xe2, 0x82, 0xef, 0x03, 0x20
	.byte 0xf2, 0x86, 0xef, 0x03, 0x60, 0xe2, 0x8a, 0xef
	.byte 0x03, 0x20, 0xf2, 0x8e, 0xef, 0x03, 0x60, 0x68
	.byte 0x49
EnumList_HitTest_NoMatch:
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x39, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa
	.byte 0xd2, 0x30, 0xbc, 0x02, 0x20, 0xd8, 0x33, 0x05
	.byte 0x66, 0x2f, 0x9f, 0x16, 0x20, 0xe8, 0x12, 0x41
	.byte 0x16, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xaf, 0x04, 0x83, 0xa3, 0x20, 0xee, 0x89, 0x42
	.byte 0x09, 0x00, 0x00, 0x00, 0x1e, 0x22, 0xf2, 0x68
	.byte 0x10
EnumList_Select:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0003a
	lds32 xde, 0
	call SendEvent

TitleProc_ReturnZero:
	lds32 xhl, 0
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
	ldl_da xhl, (0x03ef8a)
	ret

GetTitleOld:
	ldl_da xhl, (0x03ef8e)
	ret

SetInterruptTime:
	pushw iz
	ld iz, wa
	ldw_da xwa, (0x02bc30)
	bit 1, wa
	jr z, EnumList_Reset
	cps iz, 2
	jr nz, EnumList_Reset
	lds wa, 1
	calr TitleProc_SetResourceDirtyFlag

EnumList_Reset:
	ld wa, iz
	extz xwa
	add xwa, xwa
	ld xbc, Str_No_0x6B6
	add xbc, xwa
	ld wa, (xbc)
	stw_da (0x02bc32), xwa
	popw iz
	ret

CheckNotDrawFlag:
	ldw_da xwa, (0x02bc30)
	and wa, 0x4
	cps wa, 0
	scc16 z, hl
	ret

SetVariFlag:
	cps wa, 0
	jr z, EnumList_Reset_CheckPart
	ldw wa, 0x8
	jr TitleProc_SetResourceDirtyFlag

EnumList_Reset_CheckPart:
	ldw wa, 0x8
	jr TitleProc_ClearResourceDirtyFlag

SetNotDrawFlag:
	cps wa, 0
	jr z, EnumList_Reset_Send
	lds wa, 4
	jr TitleProc_SetResourceDirtyFlag

EnumList_Reset_Send:
	lds wa, 4
	jr TitleProc_ClearResourceDirtyFlag

TitleProc_SetResourceDirtyFlag:
	ordm16_24 (0x02bc30), xwa
	ldw_da xde, (0x02bc30)
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1e000ba
	jrl MainFuncCall

TitleProc_ClearResourceDirtyFlag:
	cpl wa
	anddm16_24 (0x02bc30), xwa
	ldw_da xde, (0x02bc30)
	extz xde
	ld xwa, 0x1400001
	ld xbc, 0x1e000ba
	jrl MainFuncCall

ResEventProc:
	ld xhl, xwa
	srl xhl, 0
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
	lda_24 xhl, (0x027edc)
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, 0x1e00015
	jr z, EnumList_Reset_Return
	cp xbc, 0x1e00000
	jrl nz, ObjectProc
	ld xhl, 0x160000c
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
	srl xhl, 0
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
	lda_24 xhl, (0x027edc)
	add xhl, xix
	ld xhl, (xhl)
	cp xbc, 0x1e00015
	jr z, ViewableProc_VirtualDispatch
	cp xbc, 0x1e00000
	jrl nz, ObjectProc
	ld xhl, 0x160000d
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
	cp xiy, 0x1e00052
	jrl z, Viewable_GetBoundsY
	cp xiy, 0x1e0004f
	jrl z, Viewable_GetBoundsX
	cp xiy, 0x1e000b5
	jrl z, Viewable_MatchClass
	cp xiy, 0x1e00024
	jrl z, Viewable_Dispatch
	cp xiy, 0x1e0009c
	jrl z, Viewable_SetVisible
	cp xiy, 0x1e00039
	jrl z, Viewable_GetClass
	cp xiy, 0x1e00038
	jrl z, Viewable_GetChild
	cp xiy, 0x1e00037
	jrl z, Viewable_GetOwner
	cp xiy, 0x1e00036
	jrl z, Viewable_GetParent
	cp xiy, 0x1e0000f
	jrl z, Viewable_GetInstance
	ld xwa, xiz
	lda_24 xde, (0x027ed2)
	ld xbc, xiz
	ldiw_erp 0xe6, 0
	ld (xsp + 10), bc
	srl xwa, 0
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
	cp xiy, 0x1e00016
	jrl z, Viewable_SetName
	ld hl, (xsp + 10)
	extz xhl
	sll xhl, 2
	ld xwa, xiy
	cp xwa, 0x1e00015
	jrl z, Viewable_GetName
	cp xwa, 0x1c00037
	jrl z, Viewable_PostEvent
	cp xwa, 0x1c00002
	jr z, Viewable_InitClose
	cp xwa, 0x1c00001
	jr z, Viewable_InitClose
	cp xwa, 0x1e00000
	jr z, Viewable_GetClassProc
	ld xwa, (xsp + 6)
	sub xwa, 0x1c0000b
	cp xwa, 0x0
	jrl lt, Viewable_DefaultDispatch
	cp xwa, 0x6
	jrl gt, Viewable_DefaultDispatch
	add xwa, xwa
	add xwa, Str_No_0x6D0
	ld wa, (xwa)
	lda_24 xix, (Viewable_GetClassProc)
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	ld xwa, xiz
	calr GetVisible
	cps hl, 0
	jr z, Viewable_Show_DispatchChild
	ld xwa, xiz
	ld xbc, 0x1c0000d
	lds32 xde, 0
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
	ld xwa, xiz
	calr GetVisible
	cps hl, 0
	jr z, Viewable_ReturnZero
	ld xwa, xiz
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	calr View_GetSuperViewInstance
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr z, Viewable_ReturnZero
	ld xbc, 0x1c0000b
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
	.byte 0xbf, 0x04, 0x64, 0xaf, 0x10, 0x20, 0x38, 0x1d
	.byte 0xc3, 0x07, 0xff, 0xbf, 0x0c, 0x53, 0x9f, 0x0e
	.byte 0x20, 0xe8, 0x12, 0xe8, 0xee, 0x02, 0xaf, 0x08
	.byte 0x80, 0xa0, 0x20, 0x38, 0x1d, 0xc3, 0x07, 0xff
	.byte 0xef, 0x60, 0x9f, 0x08, 0xf3, 0x6f, 0x1e, 0xaf
	.byte 0x10, 0x20, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xdb
	.byte 0x61, 0x2b, 0x1d, 0xa3, 0x06, 0xff, 0xef, 0x66
	.byte 0x9f, 0x0a, 0x20, 0xe8, 0x12, 0xe8, 0xee, 0x02
	.byte 0xaf, 0x04, 0x80, 0xb0, 0x63
Viewable_SetName_Copy:
	.byte 0xaf, 0x10, 0x20, 0x38, 0x9f, 0x0e, 0x20, 0xe8
	.byte 0x12, 0xe8, 0xee, 0x02, 0xaf, 0x08, 0x80, 0xa0
	.byte 0x20, 0x38, 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60
	.byte 0x78, 0x40, 0xff
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
	ld xbc, 0x1e00014
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
	lds32 xhl, 1
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
	srl xwa, 0
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
	cps iz, 0
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
	cps wa, 0
	scc16 nz, hl
	ret

SetConst:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
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
	cps wa, 0
	scc16 nz, hl
	ret

SetVisible:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
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
	cps wa, 0
	scc16 z, hl
	ret

SetMovable:
	pushw iz
	ld iz, bc
	calr GetViewInstance
	lda xwa, (xhl + 12)
	cps iz, 0
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
	cps wa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	sll xwa, 0
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
	cp xwa, 0xffffffff
	jr z, FrameDraw_TopEdge
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
	ldw (xhl + 10), 0xffff
	ld xwa, (xsp + 12)
	lds bc, 1
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
	lds bc, 1
	calr SetChange
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 8), 0xffff
	ld xwa, (xsp + 12)
	lds bc, 1
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
	lds bc, 1
	calr SetChange

FrameDraw_CheckInner:
	ld xwa, (xsp + 12)
	calr GetViewInstance
	ldw (xhl + 4), 0xffff
	ld xwa, (xsp + 12)
	lds bc, 1
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
	lds bc, 1
	calr SetChange
	ld xwa, (xsp + 8)
	calr GetViewInstance
	ld wa, iz
	ld (xhl + 4), wa
	ld xwa, (xsp + 8)
	lds bc, 1
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
	srl xbc, 0
	and xbc, 0xfff
	ldiw_erp 0xe2, 0
	ld de, wa
	ld wa, bc
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	cp xbc, 0x1e00000
	jrl nz, ObjectProc
	ld xhl, 0x160000f
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
	cp xiz, 0x1e0000c
	jr z, BoxStyle0_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle0_Setup
	cp xiz, 0x1e00009
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
BoxStyle0_Return:

uwordProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, BoxStyle1_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle1_Setup
	cp xiz, 0x1e00009
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
	cp xiz, 0x1e0000c
	jr z, BoxStyle2_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle2_Setup
	cp xiz, 0x1e00009
	jr nz, BoxStyle2_CalcWidth

BoxStyle2_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
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
BoxStyle2_Return:

scharProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, BoxStyle3_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle3_Setup
	cp xiz, 0x1e00009
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
	cp xiz, 0x1e0000c
	jr z, BoxStyle4_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle4_Setup
	cp xiz, 0x1e00009
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
BoxStyle4_Return:

ulongProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, BoxStyle5_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle5_Setup
	cp xiz, 0x1e00009
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
	cp xiz, 0x1e0000c
	jr z, BoxStyle6_CalcHeight
	cp xiz, 0x1e0000b
	jr z, BoxStyle6_Setup
	cp xiz, 0x1e00009
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
BoxStyle6_Return:

pBoolProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 239
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 174
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	11952
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	11936
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	wa, (xwa)
	ld	(xhl), wa
	jr	102
BoxStyle7_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x6E8

BoxStyle7_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle7_InnerFill:
	lds32 xhl, 0
	jr BoxStyle7_DoneAlt

BoxStyle7_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle7_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle7_DoneAlt

BoxStyle7_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle7_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle7_Done:
	ld xhl, xiz

BoxStyle7_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle7_Return:

pSwordProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 239
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 174
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	11636
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	11620
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	wa, (xwa)
	ld	(xhl), wa
	jr	102
BoxStyle8_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x6FA

BoxStyle8_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle8_InnerFill:
	lds32 xhl, 0
	jr BoxStyle8_DoneAlt

BoxStyle8_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle8_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle8_DoneAlt

BoxStyle8_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle8_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle8_Done:
	ld xhl, xiz

BoxStyle8_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle8_Return:

pUwordProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 239
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 174
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	11320
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	11304
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	wa, (xwa)
	ld	(xhl), wa
	jr	102
BoxStyle9_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x70C

BoxStyle9_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle9_InnerFill:
	lds32 xhl, 0
	jr BoxStyle9_DoneAlt

BoxStyle9_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld bc, (xwa)
	extz xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle9_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle9_DoneAlt

BoxStyle9_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle9_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), wa

BoxStyle9_Done:
	ld xhl, xiz

BoxStyle9_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle9_Return:

pScharProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 241
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 176
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	11004
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	10988
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	a, (xwa)
	ld	(xhl), a
	jr	102
BoxStyle10_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x71E

BoxStyle10_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle10_InnerFill:
	lds32 xhl, 0
	jr BoxStyle10_DoneAlt

BoxStyle10_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	ld c, (xwa)
	exts bc
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle10_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle10_DoneAlt

BoxStyle10_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle10_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

BoxStyle10_Done:
	ld xhl, xiz

BoxStyle10_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle10_Return:

pUcharProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 239
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 174
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	10686
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	10670
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	a, (xwa)
	ld	(xhl), a
	jr	102
BoxStyle11_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x730

BoxStyle11_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle11_InnerFill:
	lds32 xhl, 0
	jr BoxStyle11_DoneAlt

BoxStyle11_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xwa, (xhl)
	lds32 xbc, 0
	ld c, (xwa)
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

BoxStyle11_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle11_DoneAlt

BoxStyle11_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle11_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), a

BoxStyle11_Done:
	ld xhl, xiz

BoxStyle11_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle11_Return:

pSlongProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 237
	cp	xiz, 31457291
	jrl	z, 192
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	lda	xde, (xwa+8)
	cp	xiz, 31457289
	jr	z, 110
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 172
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	10370
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	10354
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	xwa, (xwa)
	ld	(xhl), xwa
	jr	102
BoxStyle12_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x742

BoxStyle12_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle12_InnerFill:
	lds32 xhl, 0
	jr BoxStyle12_DoneAlt

BoxStyle12_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

BoxStyle12_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle12_DoneAlt

BoxStyle12_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle12_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

BoxStyle12_Done:
	ld xhl, xiz

BoxStyle12_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle12_Return:

pUlongProc:
	lda	xsp, (xsp-268)
	push	xiz
	ld	(xsp+264), xde
	ld	xiz, xbc
	ld	(xsp+268), xwa
	cp	xiz, 31457292
	jrl	z, 243
	cp	xiz, 31457291
	jrl	z, 198
	lda	xhl, (xsp+8)
	ld	xwa, (xsp+264)
	lda	xbc, (xwa+4)
	cp	xiz, 31457289
	jr	z, 113
	lda	xde, (xwa+8)
	cp	xiz, 31457290
	jr	z, 56
	cp	xiz, 31457288
	jrl	nz, 178
	ld	xwa, (xbc)
	ld	bc, (xde)
	calr	10056
	ld	(xsp+4), xhl
	ld	xbc, (xsp+264)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	10040
	ld	xiz, xhl
	pushw	4
	call	16713379
	inc	2, xsp
	ld	(xiz), xhl
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	xwa, (xwa)
	ld	(xhl), xwa
	jr	108
BoxStyle13_Setup:
	ld xiz, (xbc)
	ld (xsp + 4), xiz
	ld (xbc), xhl
	ld xwa, (xde)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
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
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	ld xbc, 0x1e00018
	ld_sril XDE, (xsp + 0x0108)
	call SendEvent
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa + 4), xiz
	ld xwa, (xwa + 8)
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	ld xwa, Str_No_0x754

BoxStyle13_CheckInner:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+16)
BoxStyle13_InnerFill:
	lds32 xhl, 0
	jr BoxStyle13_DoneAlt

BoxStyle13_CalcHeight:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xbc)
	ld (xwa), xbc

BoxStyle13_CalcHeight2:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr BoxStyle13_DoneAlt

BoxStyle13_Execute:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, BoxStyle13_Done
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 4)
	ld (xbc), xwa

BoxStyle13_Done:
	ld xhl, xiz

BoxStyle13_DoneAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
BoxStyle13_Return:

RECTWProc:
	lda xsp, (xsp - 128)
	push xiz
	cp xbc, 0x1e00025
	jr z, EdgeDraw_TopLeft
	calr CommonIDProc
	jr EdgeDraw_TopRight

EdgeDraw_TopLeft:
	ld	xiz, xde
	push	xiz
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lds	ix, 0
	lds	iy, 0
	lda	xhl, (xsp+4)
	lds32	xde, 0
	jr	51
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
	cps c, 0
	jr nz, EdgeDraw_TopLeft_Inner
	ld (xwa), 0x0
	lds32 xhl, 0

EdgeDraw_TopRight:
	pop xiz
	stb_dri L, 0xfd, 0x80, 0x00
	ret

RectX1Proc:
	stb_dri L, 0xfd, 0xf4, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x08, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x0c, 0x01
	cp xiz, 0x1e0000c
	jrl z, EdgeDraw_BottomLeft_Draw
	cp xiz, 0x1e0000b
	jr z, EdgeDraw_BottomLeft_Inner
	cp xiz, 0x1e00009
	jr z, EdgeDraw_BottomLeft_Inner
	cp xiz, 0x1e00028
	jr z, EdgeDraw_TopRight_Done
	cp xiz, 0x1e00026
	jr z, EdgeDraw_TopRight_Inner
	cp xiz, 0x1e00025
	jr z, EdgeDraw_BottomLeft
	jr EdgeDraw_BottomLeft_Done

EdgeDraw_TopRight_Inner:
	pushw	234
	pushw	43632
	ld	xwa, (xsp+268)
	push	xwa
	call	16713188
	inc	8, xsp
	jr	45
EdgeDraw_TopRight_Done:
	pushw	234
	pushw	43638
	lda	xwa, (xsp+12)
	push	xwa
	call	16713584
	ld	xwa, (xsp+272)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713188
	lda	xwa, (xsp+24)
	push	xwa
	ld	xwa, (xsp+284)
	push	xwa
	call	16713584
	lda	xsp, (xsp+24)
EdgeDraw_BottomLeft:
	lds32 xhl, 0
	jr EdgeDraw_BottomLeft_FinishAlt

EdgeDraw_BottomLeft_Inner:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld_sril XWA, (xsp + 0x0108)
	ld (xwa), xbc

EdgeDraw_BottomLeft_Done:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	jr EdgeDraw_BottomLeft_FinishAlt

EdgeDraw_BottomLeft_Draw:
	ld_sril XWA, (xsp + 0x010c)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, EdgeDraw_BottomLeft_Finish
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

EdgeDraw_BottomLeft_Finish:
	ld xhl, (xsp + 4)

EdgeDraw_BottomLeft_FinishAlt:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
EdgeDraw_BottomLeft_Return:

RectY1Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1e0000c
	jr z, EdgeDraw_BottomRight_Done
	cp xiz, 0x1e0000b
	jr z, EdgeDraw_BottomRight_Check
	cp xiz, 0x1e00009
	jr z, EdgeDraw_BottomRight_Check
	cp xiz, 0x1e00026
	jr z, EdgeDraw_BottomRight
	cp xiz, 0x1e00025
	jr z, EdgeDraw_BottomRight_Inner
	jr EdgeDraw_BottomRight_Draw

EdgeDraw_BottomRight:
	pushw	234
	pushw	43640
	ld	xwa, (xsp+12)
	push	xwa
	call	16713188
	inc	8, xsp
EdgeDraw_BottomRight_Inner:
	lds32 xhl, 0
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
	cp xiz, 0x1e0000c
	jr z, TabDraw_TopEdge_Done
	cp xiz, 0x1e0000b
	jr z, TabDraw_TopEdge_CalcHeight
	cp xiz, 0x1e00009
	jr z, TabDraw_TopEdge_Inner
	cp xiz, 0x1e00026
	jr z, TabDraw_TopEdge
	cp xiz, 0x1e00025
	jr nz, TabDraw_TopEdge_CalcWidth
	jr TabDraw_TopEdge_Execute

TabDraw_TopEdge:
	pushw	234
	pushw	43646
	ld	xwa, (xsp+12)
	push	xwa
	call	16713188
	inc	8, xsp
	jr	60
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
	.byte 0xaf, 0x08, 0x20, 0x1e, 0x5a, 0x24, 0xbb, 0xfc
	.byte 0x31, 0x0b, 0x0a, 0x00, 0xaf, 0x0a, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x93, 0x20, 0x91, 0xa0, 0xd8
	.byte 0x61, 0x28, 0x1d, 0x06, 0x06, 0xff, 0xef, 0x60
TabDraw_TopEdge_Execute:
	lds32 xhl, 0
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
TabDraw_BottomEdge_Return:

RectY2Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1e0000c
	jrl z, EdgeVariant_A_Return
	cp xiz, 0x1e0000b
	jr z, EdgeVariant_A_Execute
	cp xiz, 0x1e00009
	jr z, EdgeVariant_A_CalcHeight
	cp xiz, 0x1e00028
	jr z, EdgeVariant_A_CalcWidth
	cp xiz, 0x1e00026
	jr z, EdgeVariant_A_Setup
	cp xiz, 0x1e00025
	jr nz, EdgeVariant_A_CalcHeight2
	jr EdgeVariant_A_Done

EdgeVariant_A_Setup:
	pushw	234
	pushw	43654
	ld	xwa, (xsp+12)
	push	xwa
	call	16713188
	inc	8, xsp
	lds32	xhl, 1
	jr	127
EdgeVariant_A_CalcWidth:
	pushw	234
	pushw	43662
	ld	xwa, (xsp+12)
	push	xwa
	call	16713188
	inc	8, xsp
	jr	60
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
	.byte 0xaf, 0x08, 0x20, 0x1e, 0x83, 0x23, 0xbb, 0xfc
	.byte 0x31, 0x0b, 0x0a, 0x00, 0xaf, 0x0a, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x93, 0x20, 0x91, 0xa0, 0xd8
	.byte 0x61, 0x28, 0x1d, 0x06, 0x06, 0xff, 0xef, 0x60
EdgeVariant_A_Done:
	lds32 xhl, 0
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
	stb_dri L, 0xfd, 0x7c, 0xff
	pushw iz
	stl_dri XDE, 0xfd, 0x82, 0x00
	cp xbc, 0x1e00025
	jr z, EdgeVariant_B_CalcWidth
	ld_sril XDE, (xsp + 0x0082)
	calr CommonIDProc
	jr EdgeVariant_C_Setup

EdgeVariant_B_CalcWidth:
	ld	xwa, (xsp+130)
	push	xwa
	lda	xwa, (xsp+6)
	push	xwa
	call	16713584
	inc	8, xsp
	lds	iy, 0
	lds	iz, 0
	lda	xix, (xsp+2)
	lds32	xbc, 0
	jr	32
EdgeVariant_B_CalcHeight:
	cp a, 0x55
	jr nz, EdgeVariant_B_Done
	ld (xde), 0x56
	inc 1, iy
	ld wa, iy
	extz xwa
	add_sril_rm XWA, 0xfd, 0x82, 0x00
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
	add_sril_rm XDE, 0xfd, 0x82, 0x00
	ld a, (xhl)
	cps a, 0
	jr nz, EdgeVariant_B_CalcHeight
	ld (xde), 0x0
	lds32 xhl, 0

EdgeVariant_C_Setup:
	popw iz
	stb_dri L, 0xfd, 0x84, 0x00
	ret
EdgeVariant_C_Prologue:

PointXProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x08, 0x01
	cp xiz, 0x1e0000c
	jrl z, EdgeVariant_C_Execute
	cp xiz, 0x1e0000b
	jr z, EdgeVariant_C_InnerFill
	cp xiz, 0x1e00009
	jr z, EdgeVariant_C_InnerFill
	cp xiz, 0x1e00028
	jr z, EdgeVariant_C_CalcHeight
	cp xiz, 0x1e00026
	jr z, EdgeVariant_C_CalcWidth
	cp xiz, 0x1e00025
	jr z, EdgeVariant_C_CheckInner
	jr EdgeVariant_C_CalcHeight2

EdgeVariant_C_CalcWidth:
	pushw	234
	pushw	43664
	ld	xwa, (xsp+264)
	push	xwa
	call	16713188
	inc	8, xsp
	jr	45
EdgeVariant_C_CalcHeight:
	pushw	234
	pushw	43668
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	ld	xwa, (xsp+268)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	16713188
	lda	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+280)
	push	xwa
	call	16713584
	lda	xsp, (xsp+24)
EdgeVariant_C_CheckInner:
	lds32 xhl, 0
	jr EdgeVariant_C_Return

EdgeVariant_C_InnerFill:
	ld_sril XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld bc, (xhl)
	exts xbc
	ld_sril XWA, (xsp + 0x0104)
	ld (xwa), xbc

EdgeVariant_C_CalcHeight2:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	calr CommonIDProc
	jr EdgeVariant_C_Return

EdgeVariant_C_Execute:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	calr CommonIDProc
	ld xiz, xhl
	or xiz, xiz
	jr nz, EdgeVariant_C_Done
	ld_sril XWA, (xsp + 0x0104)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0104)
	ld xwa, (xwa + 4)
	ld (xhl), wa

EdgeVariant_C_Done:
	ld xhl, xiz

EdgeVariant_C_Return:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret

PointYProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, ShadowBox_A_Execute
	cp xiz, 0x1e0000b
	jr z, ShadowBox_A_InnerFill
	cp xiz, 0x1e00009
	jr z, ShadowBox_A_InnerFill
	cp xiz, 0x1e00028
	jr z, ShadowBox_A_CalcWidth
	cp xiz, 0x1e00026
	jr z, ShadowBox_A_Setup
	cp xiz, 0x1e00025
	jr z, ShadowBox_A_CheckInner
	jr ShadowBox_A_CalcHeight

ShadowBox_A_Setup:
	pushw	234
	pushw	43670
	ld	xwa, (xsp+8)
	push	xwa
	call	16713188
	inc	8, xsp
	lds32	xhl, 1
	jr	81
ShadowBox_A_CalcWidth:
	pushw	234
	pushw	43674
	ld	xwa, (xsp+8)
	push	xwa
	call	16713188
	inc	8, xsp
ShadowBox_A_CheckInner:
	lds32 xhl, 0
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
	stb_dri L, 0xfd, 0xec, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x14, 0x11
	cp xiz, 0x1e0000c
	jr z, ShadowBox_A_Return
	cp xiz, 0x1e0000e
	jr z, ShadowBox_A_Return
	cp xiz, 0x1e0000d
	jr nz, ShadowBox_A_DrawEdge

ShadowBox_A_Return:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, 0x160
	ld (xsp + 8), xwa

ShadowBox_A_CheckAlt:
	ld xbc, (xsp + 8)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, ShadowBox_A_DrawInner

ShadowBox_A_DrawAlt:
	ld xwa, (xsp + 12)
	sll xwa, 2
	stb_dri A, 0xfd, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xsp + 8)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 12), xwa
	inc 1, xde
	cp xde, xhl
	jr c, ShadowBox_A_DrawAlt

ShadowBox_A_DrawInner:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x17f
	jr ule, ShadowBox_A_CheckAlt

ShadowBox_A_DrawEdge:
	cp xiz, 0x1e0000c
	jrl z, ShadowBox_B_CalcHeight
	cp xiz, 0x1e0000b
	jr z, ShadowBox_B_CalcWidth
	cp xiz, 0x1e00009
	jr z, ShadowBox_B_CalcWidth
	cp xiz, 0x1e00028
	jr z, ShadowBox_B_Prologue
	cp xiz, 0x1e0000e
	jr z, ShadowBox_B_Setup
	cp xiz, 0x1e0000d
	jrl nz, ShadowBox_C_Return
	ld_sril XIZ, (xsp + 0x1110)
	ld xwa, (xiz + 8)
	sll xwa, 2
	stb_dri A, 0xfd, 0x10, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1e00015
	lds32 xde, 0
	jr ShadowBox_B_CheckInner

ShadowBox_B_Setup:
	ld xhl, (xsp + 12)
	jrl ViewFlagProc_Return

ShadowBox_B_Prologue:
	pushw	234
	pushw	43676
	lda	xwa, (xsp+20)
	push	xwa
	call	16713584
	ld	xwa, (xsp+4376)
	push	xwa
	lda	xwa, (xsp+28)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+16)
	push	xwa
	ld	xwa, (xsp+4372)
	push	xwa
	jr	35
ShadowBox_B_CalcWidth:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld (xiz), xbc
	ld xwa, xbc
	ld xbc, 0x1e00015
	lds32 xde, 0

ShadowBox_B_CheckInner:
	call ClassProc
	push xhl
	ld xwa, (xiz + 4)
	push xwa

ShadowBox_B_InnerFill:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jrl	148
ShadowBox_B_CalcHeight:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, ShadowBox_C_CalcWidth

ShadowBox_B_Execute:
	ld	xwa, (xiz+4)
	push	xwa
	ld	xwa, (xsp+12)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	xbc, 31457301
	lds32	xde, 0
	call	16400597
	push	xhl
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 25
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+272)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	(xiz+4), xwa
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	20
ShadowBox_C_Setup:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 12)
	jr c, ShadowBox_B_Execute

ShadowBox_C_CalcWidth:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, ShadowBox_C_Execute

ShadowBox_C_CalcHeight:
	ld_sril XIZ, (xsp + 0x1110)
	ld_sril XWA, (xsp + 0x1110)
	calr IDCursorAdvance
	ld xwa, (xiz + 4)
	ld (xhl), xwa

ShadowBox_C_Execute:
	ld xhl, (xsp + 4)
	jr ViewFlagProc_Return

ShadowBox_C_Return:
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc

ViewFlagProc_Return:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x11
	ret

ViewFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_A_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_A_Setup
	cp xiz, 0x1e00009
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
FrameVariant_A_Return:

ColorIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_B_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_B_Setup
	cp xiz, 0x1e00009
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
	cp xiz, 0x1e0000c
	jr z, FrameVariant_C_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_C_Setup
	cp xiz, 0x1e00009
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
FrameVariant_C_Return:

AlignmentIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_D_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_D_Setup
	cp xiz, 0x1e00009
	jr nz, FrameVariant_D_CalcWidth

FrameVariant_D_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
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
FrameVariant_D_Return:

EditSwStyleIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_E_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_E_Setup
	cp xiz, 0x1e00009
	jr nz, FrameVariant_E_CalcWidth

FrameVariant_E_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
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
	cp xiz, 0x1e00029
	jr z, FrameVariant_F_CheckAlt
	cp xiz, 0x1e0000c
	jr z, FrameVariant_F_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_F_Setup
	cp xiz, 0x1e00009
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
	cp xiz, 0x1e0000c
	jr z, FrameVariant_G_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_G_Setup
	cp xiz, 0x1e00009
	jr nz, FrameVariant_G_CalcWidth

FrameVariant_G_Setup:
	ld xwa, (xsp + 4)
	calr IDCursorAdvance
	lds32 xbc, 0
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
FrameVariant_G_Return:

FrameIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_H_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_H_Setup
	cp xiz, 0x1e00009
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
FrameVariant_H_Return:

UserIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_I_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_I_Setup
	cp xiz, 0x1e00009
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
FrameVariant_I_Return:

PartIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_J_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_J_Setup
	cp xiz, 0x1e00009
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
FrameVariant_J_Return:

TrackIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_K_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_K_Setup
	cp xiz, 0x1e00009
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
FrameVariant_K_Return:

IntTimeIDProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0000c
	jr z, FrameVariant_L_CalcHeight
	cp xiz, 0x1e0000b
	jr z, FrameVariant_L_Setup
	cp xiz, 0x1e00009
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
FrameVariant_L_Return:

StringProc:
	stb_dri L, 0xfd, 0xc6, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x3a, 0x01
	ld_sril XDE, (xsp + 0x013a)
	inc 4, xde
	cp xbc, 0x1e0000c
	jrl z, ScrollBar_Draw
	cp xbc, 0x1e0000b
	jrl z, ScrollBar_CalcThumb
	cp xbc, 0x1e00009
	jrl z, ScrollBar_CalcThumb
	cp xbc, 0x1e00028
	jr z, ScrollBar_CalcRange
	cp xbc, 0x1e00008
	jr z, ScrollBar_Setup
	ld_sril XDE, (xsp + 0x013a)
	calr CommonIDProc
	jrl ScrollBar_Return

ScrollBar_Setup:
	ld	xwa, (xde)
	ld	xbc, (xsp+314)
	ld	bc, (xbc+8)
	calr	6585
	ld	(xsp+6), xhl
	ld	xbc, (xsp+314)
	ld	xwa, (xbc)
	ld	bc, (xbc+8)
	calr	6569
	ld	(xsp+10), xhl
	ld	xwa, (xsp+6)
	ld	xwa, (xwa)
	push	xwa
	call	16713667
	inc	1, hl
	pushw	hl
	call	16713379
	inc	6, xsp
	ld	xwa, (xsp+10)
	ld	(xwa), xhl
	ld	xwa, (xsp+6)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+14)
	jrl	151
ScrollBar_CalcRange:
	pushw	234
	pushw	43680
	lda	xwa, (xsp+18)
	push	xwa
	call	16713584
	ld	xwa, (xsp+322)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	call	16713188
	pushw	234
	pushw	43682
	lda	xwa, (xsp+34)
	push	xwa
	call	16713188
	lda	xsp, (xsp+24)
	lda	xwa, (xsp+14)
	push	xwa
	ld	xwa, (xsp+318)
	push	xwa
	jr	97
ScrollBar_CalcThumb:
	ld_sril XWA, (xsp + 0x013a)
	calr IDCursorAdvance
	ld xbc, (xhl)
	ld_sril XWA, (xsp + 0x013a)
	stl_dpi XBC, 0xe2
	push xbc
	jr ScrollBar_ReturnAlt

ScrollBar_Draw:
	.byte 0xa2, 0x20, 0xbf, 0x04, 0x60, 0xe3, 0xfd, 0x3a
	.byte 0x01, 0x20, 0x1e, 0x9b, 0x19, 0xbf, 0x08, 0x63
	.byte 0xaf, 0x08, 0x20, 0xa0, 0x26, 0xaf, 0x04, 0x20
	.byte 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xbf, 0x10, 0x53
	.byte 0x3e, 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x60, 0x9f
	.byte 0x0c, 0xf3, 0x6f, 0x16, 0xaf, 0x04, 0x20, 0x38
	.byte 0x1d, 0xc3, 0x07, 0xff, 0xdb, 0x61, 0x2b, 0x1d
	.byte 0xa3, 0x06, 0xff, 0xef, 0x66, 0xaf, 0x08, 0x20
	.byte 0xb0, 0x63
ScrollBar_ReturnZero:
	ld xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 12)

ScrollBar_ReturnAlt:
	ld xwa, (xwa)
	push xwa

ScrollBar_ReturnAlt2:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
ScrollBar_Return:
	pop xiz
	stb_dri L, 0xfd, 0x3a, 0x01
	ret

FontIDProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x08, 0x01
	cp xbc, 0x1e0000c
	jrl z, SliderH_DrawTrack
	cp xbc, 0x1e0000b
	jr z, SliderH_CalcRange
	cp xbc, 0x1e00009
	jr z, SliderH_CalcRange
	cp xbc, 0x1e00028
	jr z, SliderH_Prologue
	cp xbc, 0x1e0000e
	jr z, SliderH_Setup
	cp xbc, 0x1e0000d
	jrl nz, SliderH_ReturnAlt4
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, 0x3efac
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr SliderH_CalcThumb

SliderH_Setup:
	ldw_da xhl, (NakaData_WidgetNames_0x624)
	exts xhl
	jrl SliderH_ReturnAlt5

SliderH_Prologue:
	pushw	234
	pushw	43684
	lda	xwa, (xsp+12)
	push	xwa
	call	16713584
	ld	xwa, (xsp+272)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+268)
	push	xwa
	jr	41
SliderH_CalcRange:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, 0x3efac
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

SliderH_CalcThumb:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

SliderH_CalcThumb_Clamp:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	93
SliderH_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr SliderH_ReturnAlt

SliderH_DrawThumb:
	push	xwa
	ld	xwa, (xsp+268)
	ld	xwa, (xwa+4)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 7
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	31
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
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

SliderH_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr SliderH_ReturnAlt5

SliderH_ReturnAlt4:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

SliderH_ReturnAlt5:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret
SliderH_Return:

IconIDProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x08, 0x01
	cp xbc, 0x1e0000c
	jrl z, SliderV_DrawTrack
	cp xbc, 0x1e0000b
	jr z, SliderV_CalcRange
	cp xbc, 0x1e00009
	jr z, SliderV_CalcRange
	cp xbc, 0x1e00028
	jr z, SliderV_Prologue
	cp xbc, 0x1e0000e
	jr z, SliderV_Setup
	cp xbc, 0x1e0000d
	jrl nz, SliderV_Return
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, Str_InitializeRoot_0x12
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr SliderV_CalcThumb

SliderV_Setup:
	ldw_da xhl, (Str_InitializeRoot_0x10)
	extz xhl
	jrl BitmapIDProc_Return

SliderV_Prologue:
	pushw	234
	pushw	43688
	lda	xwa, (xsp+12)
	push	xwa
	call	16713584
	ld	xwa, (xsp+272)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+268)
	push	xwa
	jr	41
SliderV_CalcRange:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, Str_InitializeRoot_0x12
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

SliderV_CalcThumb:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

SliderV_CalcThumb_Clamp:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	93
SliderV_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr SliderV_ReturnAlt

SliderV_DrawThumb:
	push	xwa
	ld	xwa, (xsp+268)
	ld	xwa, (xwa+4)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 7
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	31
SliderV_ReturnZero:
	inc 1, xiz

SliderV_ReturnAlt:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, Str_InitializeRoot_0x12
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, SliderV_DrawThumb
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, SliderV_ReturnAlt3

SliderV_ReturnAlt2:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

SliderV_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr BitmapIDProc_Return

SliderV_Return:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

BitmapIDProc_Return:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret

BitmapIDProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x08, 0x01
	cp xbc, 0x1e0000c
	jrl z, DrawHelper_A_DrawTrack
	cp xbc, 0x1e0000b
	jr z, DrawHelper_A_CalcRange
	cp xbc, 0x1e00009
	jr z, DrawHelper_A_CalcRange
	cp xbc, 0x1e00028
	jr z, DrawHelper_A_Prologue
	cp xbc, 0x1e0000e
	jr z, DrawHelper_A_Setup
	cp xbc, 0x1e0000d
	jrl nz, DrawHelper_A_Return
	ld_sril XWA, (xsp + 0x0108)
	ld xwa, (xwa + 8)
	sll xwa, 2
	ld xbc, Data_CharMapFormatBlock_0x22C
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	jr DrawHelper_A_CalcThumb

DrawHelper_A_Setup:
	ldw_da xhl, (Data_CharMapFormatBlock_0x22A)
	extz xhl
	jrl ApFuncIDProc_Return

DrawHelper_A_Prologue:
	pushw	234
	pushw	43696
	lda	xwa, (xsp+12)
	push	xwa
	call	16713584
	ld	xwa, (xsp+272)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+268)
	push	xwa
	jr	41
DrawHelper_A_CalcRange:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	sll xwa, 2
	ld xbc, Data_CharMapFormatBlock_0x22C
	add xbc, xwa
	ld xwa, (xbc)
	push xwa

DrawHelper_A_CalcThumb:
	ld_sril XWA, (xsp + 0x010c)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_A_ClampThumb:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jr	93
DrawHelper_A_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	lds32 xiz, 0
	jr DrawHelper_A_ReturnAlt

DrawHelper_A_DrawThumb:
	push	xwa
	ld	xwa, (xsp+268)
	ld	xwa, (xwa+4)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 7
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	31
DrawHelper_A_ReturnZero:
	inc 1, xiz

DrawHelper_A_ReturnAlt:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, Data_CharMapFormatBlock_0x22C
	add xwa, xbc
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, DrawHelper_A_DrawThumb
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, DrawHelper_A_ReturnAlt3

DrawHelper_A_ReturnAlt2:
	ld_sril XWA, (xsp + 0x0108)
	calr IDCursorAdvance
	ld (xhl), xiz

DrawHelper_A_ReturnAlt3:
	ld xhl, (xsp + 4)
	jr ApFuncIDProc_Return

DrawHelper_A_Return:
	ld_sril XDE, (xsp + 0x0108)
	calr CommonIDProc

ApFuncIDProc_Return:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret
DrawHelper_B_Setup:

ApFuncIDProc:
	stb_dri L, 0xfd, 0xe8, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x11
	cp xiz, 0x1e0000c
	jr z, DrawHelper_B_CalcRange
	cp xiz, 0x1e0000e
	jr z, DrawHelper_B_CalcRange
	cp xiz, 0x1e0000d
	jr nz, DrawHelper_B_ReturnAlt

DrawHelper_B_CalcRange:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld xwa, 0x120
	ld (xsp + 12), xwa

DrawHelper_B_CalcThumb:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, DrawHelper_B_ReturnZero

DrawHelper_B_DrawTrack:
	ld xwa, (xsp + 16)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, DrawHelper_B_DrawTrack

DrawHelper_B_ReturnZero:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x13f
	jr ule, DrawHelper_B_CalcThumb

DrawHelper_B_ReturnAlt:
	cp xiz, 0x1e0000c
	jrl z, DrawHelper_C_DrawTrack
	cp xiz, 0x1e0000b
	jr z, DrawHelper_C_Setup
	cp xiz, 0x1e00009
	jr z, DrawHelper_C_Setup
	cp xiz, 0x1e00028
	jr z, DrawHelper_B_FinishAlt
	cp xiz, 0x1e0000e
	jr z, DrawHelper_B_Finish
	cp xiz, 0x1e0000d
	jrl nz, DrawHelper_C_Return
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1e00015
	lds32 xde, 0
	jr DrawHelper_C_CalcRange

DrawHelper_B_Finish:
	ld xhl, (xsp + 16)
	jrl MainFuncIDProc_Return

DrawHelper_B_FinishAlt:
	pushw	234
	pushw	43700
	lda	xwa, (xsp+24)
	push	xwa
	call	16713584
	ld	xwa, (xsp+4380)
	push	xwa
	lda	xwa, (xsp+32)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+4376)
	push	xwa
	jr	44
DrawHelper_C_Setup:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, 0x1e00015
	lds32 xde, 0

DrawHelper_C_CalcRange:
	call ApFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_C_CalcThumb:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jrl	168
DrawHelper_C_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, DrawHelper_C_ReturnAlt2

DrawHelper_C_ReturnZero:
	ld	xwa, (xsp+12)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	xbc, 31457301
	lds32	xde, 0
	call	16401759
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	push	xhl
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 28
	ld	xwa, (xsp+12)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xbc)
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+8), xwa
	jr	20
DrawHelper_C_ReturnAlt:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, DrawHelper_C_ReturnZero

DrawHelper_C_ReturnAlt2:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawHelper_C_ReturnAlt4

DrawHelper_C_ReturnAlt3:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

DrawHelper_C_ReturnAlt4:
	ld xhl, (xsp + 8)
	jr MainFuncIDProc_Return

DrawHelper_C_Return:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

MainFuncIDProc_Return:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x11
	ret

MainFuncIDProc:
	stb_dri L, 0xfd, 0xe8, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x11
	cp xiz, 0x1e0000c
	jr z, DrawHelper_D_Setup
	cp xiz, 0x1e0000e
	jr z, DrawHelper_D_Setup
	cp xiz, 0x1e0000d
	jr nz, DrawHelper_D_ReturnAlt

DrawHelper_D_Setup:
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld xwa, 0x140
	ld (xsp + 12), xwa

DrawHelper_D_CalcRange:
	ld xbc, (xsp + 12)
	ld wa, bc
	call CountObject
	extz xhl
	lds32 xde, 0
	cp xhl, 0x0
	jr ule, DrawHelper_D_ReturnZero

DrawHelper_D_DrawTrack:
	ld xwa, (xsp + 16)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xsp + 12)
	sll xwa, 0
	add xwa, xde
	ld (xbc), xwa
	lds32 xwa, 1
	add (xsp + 16), xwa
	inc 1, xde
	cp xde, xhl
	jr c, DrawHelper_D_DrawTrack

DrawHelper_D_ReturnZero:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x15f
	jr ule, DrawHelper_D_CalcRange

DrawHelper_D_ReturnAlt:
	cp xiz, 0x1e0000c
	jrl z, DrawHelper_E_DrawTrack
	cp xiz, 0x1e0000b
	jr z, DrawHelper_E_Setup
	cp xiz, 0x1e00009
	jr z, DrawHelper_E_Setup
	cp xiz, 0x1e00028
	jr z, DrawHelper_D_FinishAlt
	cp xiz, 0x1e0000e
	jr z, DrawHelper_D_Finish
	cp xiz, 0x1e0000d
	jrl nz, DrawHelper_E_Return
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 8)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
	add xbc, xwa
	ld xwa, (xbc)
	ld xbc, 0x1e00015
	lds32 xde, 0
	jr DrawHelper_E_CalcRange

DrawHelper_D_Finish:
	ld xhl, (xsp + 16)
	jrl ViewIDProc_Return

DrawHelper_D_FinishAlt:
	pushw	234
	pushw	43704
	lda	xwa, (xsp+24)
	push	xwa
	call	16713584
	ld	xwa, (xsp+4380)
	push	xwa
	lda	xwa, (xsp+32)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+4376)
	push	xwa
	jr	44
DrawHelper_E_Setup:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xbc, (xhl)
	ld (xwa), xbc
	ld xwa, (xwa)
	ld xbc, 0x1e00015
	lds32 xde, 0

DrawHelper_E_CalcRange:
	call MainFunctionProc
	push xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

DrawHelper_E_CalcThumb:
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
	jrl	168
DrawHelper_E_DrawTrack:
	ld xwa, 0xffffffff
	ld (xsp + 8), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, DrawHelper_E_ReturnAlt2

DrawHelper_E_ReturnZero:
	ld	xwa, (xsp+12)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	xbc, 31457301
	lds32	xde, 0
	call	16401931
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	push	xhl
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 28
	ld	xwa, (xsp+12)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xbc)
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+8), xwa
	jr	20
DrawHelper_E_ReturnAlt:
	lds32 xwa, 1
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	cp xwa, (xsp + 16)
	jr c, DrawHelper_E_ReturnZero

DrawHelper_E_ReturnAlt2:
	ld xwa, (xsp + 8)
	or xwa, xwa
	jr nz, DrawHelper_E_ReturnAlt4

DrawHelper_E_ReturnAlt3:
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	ld_sril XWA, (xsp + 0x1114)
	calr IDCursorAdvance
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 4)
	ld (xhl), xwa

DrawHelper_E_ReturnAlt4:
	ld xhl, (xsp + 8)
	jr ViewIDProc_Return

DrawHelper_E_Return:
	ld_sril XWA, (xsp + 0x1118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1114)
	calr CommonIDProc

ViewIDProc_Return:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x11
	ret

ViewIDProc:
	stb_dri L, 0xfd, 0xe8, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x11
	cp xiz, 0x1e0000c
	jr z, ViewID_EnumFill
	cp xiz, 0x1e0000e
	jr z, ViewID_EnumFill
	cp xiz, 0x1e0000d
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
	stb_dri A, 0xfd, 0x14, 0x01
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
	cp xwa, 0xff
	jr ule, ViewID_EnumFill_OuterLoop

ViewID_EventSwitch:
	.byte 0xee, 0xcf, 0x0c, 0x00, 0xe0, 0x01, 0x76, 0xc0
	.byte 0x01, 0xee, 0xcf, 0x0b, 0x00, 0xe0, 0x01, 0x76
	.byte 0xff, 0x00, 0xee, 0xcf, 0x09, 0x00, 0xe0, 0x01
	.byte 0x76, 0xf6, 0x00, 0xee, 0xcf, 0x28, 0x00, 0xe0
	.byte 0x01, 0x76, 0xc1, 0x00, 0xee, 0xcf, 0x0e, 0x00
	.byte 0xe0, 0x01, 0x76, 0xb0, 0x00, 0xee, 0xcf, 0x0d
	.byte 0x00, 0xe0, 0x01, 0x7e, 0x2c, 0x02, 0xe3, 0xfd
	.byte 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60, 0xa8, 0x08
	.byte 0x20, 0xaf, 0x10, 0xf0, 0x6e, 0x16, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xbc, 0xaa, 0xaf, 0x08, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xef
	.byte 0x60, 0x78, 0x68, 0x01
ViewID_Select_Lookup:
	.byte 0xe8, 0xee, 0x02, 0xf3, 0xfd, 0x14, 0x01, 0x31
	.byte 0xe8, 0x81, 0xa1, 0x20, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x88, 0x55, 0xfa, 0x83
	.byte 0x3f, 0x00, 0x66, 0x18, 0x3b, 0x0b, 0xea, 0x00
	.byte 0x0b, 0xc4, 0xaa, 0xaf, 0x0c, 0x20, 0xa8, 0x04
	.byte 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x78, 0x34, 0x01
ViewID_Select_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+8)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xde, (xsp+4)
	ld	xwa, (xde+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43722
	ld	xwa, (xde+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jrl	231
ViewID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ViewID_Return

ViewID_GetInfoStr:
	pushw	234
	pushw	43730
	lda	xwa, (xsp+24)
	push	xwa
	call	16713584
	ld	xwa, (xsp+4380)
	push	xwa
	lda	xwa, (xsp+32)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+4376)
	push	xwa
	jrl	173
ViewID_GetCurrent:
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0x1e, 0x6a, 0x10
	.byte 0x93, 0x21, 0xe9, 0x13, 0xaf, 0x04, 0x22, 0xb2
	.byte 0x61, 0xa2, 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff
	.byte 0xff, 0x66, 0x7d, 0xaa, 0x08, 0x20, 0xe8, 0xef
	.byte 0x00, 0xe8, 0xcc, 0xff, 0x0f, 0x00, 0x00, 0xe8
	.byte 0x12, 0xe8, 0xee, 0x00, 0xe8, 0x89, 0xa2, 0x81
	.byte 0xe9, 0x88, 0x41, 0x15, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x88, 0x55, 0xfa, 0x83, 0x3f, 0x00
	.byte 0x66, 0x17, 0x3b, 0x0b, 0xea, 0x00, 0x0b, 0xda
	.byte 0xaa, 0xaf, 0x0c, 0x20, 0xa8, 0x04, 0x20, 0x38
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c, 0x37, 0x68
	.byte 0x52
ViewID_GetCurrent_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+8)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xbc, (xsp+4)
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43744
	ld	xwa, (xbc+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jr	19
ViewID_GetCurrent_None:
	pushw 0xea
	pushw 0xaae8
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

ViewID_StrCpy:
	call	16713584
	inc	8, xsp
ViewID_ReturnZero:
	lds32 xhl, 0
	jrl ViewID_Return

ViewID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jr ule, ViewID_EnumOpen_NotFound

ViewID_EnumOpen_ScanLoop:
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	xbc, 31457301
	lds32	xde, 0
	call	16405896
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	push	xhl
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 28
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xbc)
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+12), xwa
	jr	20
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
	stb_dri L, 0xfd, 0x18, 0x11
	ret
ViewID_Epilogue:

ScreenIDProc:
	stb_dri L, 0xfd, 0xe8, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x11
	cp xiz, 0x1e0000c
	jr z, ScreenID_EnumFill
	cp xiz, 0x1e0000e
	jr z, ScreenID_EnumFill
	cp xiz, 0x1e0000d
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
	ld xbc, 0x1e00014
	ld xde, 0x1600033
	call SendEvent
	or xhl, xhl
	jr z, ScreenID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
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
	cp xwa, 0xff
	jr ule, ScreenID_EnumFill_OuterLoop

ScreenID_EventSwitch:
	.byte 0xee, 0xcf, 0x0c, 0x00, 0xe0, 0x01, 0x76, 0x8a
	.byte 0x01, 0xee, 0xcf, 0x0b, 0x00, 0xe0, 0x01, 0x76
	.byte 0xdf, 0x00, 0xee, 0xcf, 0x09, 0x00, 0xe0, 0x01
	.byte 0x76, 0xd6, 0x00, 0xee, 0xcf, 0x28, 0x00, 0xe0
	.byte 0x01, 0x76, 0x6a, 0x01, 0xee, 0xcf, 0x0e, 0x00
	.byte 0xe0, 0x01, 0x76, 0xbc, 0x00, 0xee, 0xcf, 0x0d
	.byte 0x00, 0xe0, 0x01, 0x7e, 0x94, 0x02, 0xe3, 0xfd
	.byte 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60, 0xa8, 0x08
	.byte 0x20, 0xaf, 0x10, 0xf0, 0x6e, 0x16, 0x0b, 0xea
	.byte 0x00, 0x0b, 0xf0, 0xaa, 0xaf, 0x08, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xef
	.byte 0x60, 0x78, 0x32, 0x01
ScreenID_Select_Lookup:
	.byte 0xe8, 0xee, 0x02, 0xf3, 0xfd, 0x14, 0x01, 0x31
	.byte 0xe8, 0x81, 0xa1, 0x20, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x88, 0x55, 0xfa, 0x83
	.byte 0x3f, 0x00, 0x66, 0x18, 0x3b, 0x0b, 0xea, 0x00
	.byte 0x0b, 0xf8, 0xaa, 0xaf, 0x0c, 0x20, 0xa8, 0x04
	.byte 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x78, 0xfe, 0x00
ScreenID_Select_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xde, (xsp+4)
	ld	xwa, (xde+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43774
	ld	xwa, (xde+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jrl	165
ScreenID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl ScreenID_Return

ScreenID_GetCurrent:
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0x1e, 0x62, 0x0d
	.byte 0xaf, 0x04, 0x22, 0xa3, 0x21, 0xb2, 0x61, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x69, 0xea, 0x89, 0xa1, 0x20, 0x41, 0x15, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x88, 0x55, 0xfa
	.byte 0x83, 0x3f, 0x00, 0x66, 0x17, 0x3b, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x06, 0xab, 0xaf, 0x0c, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf
	.byte 0x0c, 0x37, 0x68, 0x51
ScreenID_GetCurrent_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xbc, (xsp+4)
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43788
	ld	xwa, (xbc+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jr	19
ScreenID_GetCurrent_None:
	pushw	234
	pushw	43796
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+4)
	push	xwa
	call	16713584
	inc	8, xsp
ScreenID_ReturnZero:
	lds32 xhl, 0
	jrl ScreenID_Return

ScreenID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, ScreenID_EnumOpen_NotFound

ScreenID_EnumOpen_ScanLoop:
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xee, 0x02, 0xf3, 0xfd
	.byte 0x14, 0x01, 0x31, 0xe8, 0x81, 0xa1, 0x20, 0x41
	.byte 0x15, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x88
	.byte 0x55, 0xfa, 0x83, 0x3f, 0x00, 0x66, 0x14, 0x3b
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x1c, 0xab, 0xbf, 0x1c
	.byte 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x68, 0x50
ScreenID_EnumOpen_ScanNoName:
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43810
	lda	xwa, (xsp+30)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
ScreenID_EnumOpen_Compare:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 28
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xbc)
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+12), xwa
	jr	69
ScreenID_EnumOpen_ScanNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jrl c, ScreenID_EnumOpen_ScanLoop

ScreenID_EnumOpen_NotFound:
	ld	xwa, (xsp+12)
	or	xwa, xwa
	jr	z, 41
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	pushw	234
	pushw	43818
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 18
	ld	xwa, (xsp+4)
	ld	xbc, 4294967295
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+12), xwa
	jr	7
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
	stb_dri L, 0xfd, 0x18, 0x11
	ret
ScreenID_Epilogue:

WindowIDProc:
	stb_dri L, 0xfd, 0xe8, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x11
	cp xiz, 0x1e0000c
	jr z, WindowID_EnumFill
	cp xiz, 0x1e0000e
	jr z, WindowID_EnumFill
	cp xiz, 0x1e0000d
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
	ld xbc, 0x1e00014
	ld xde, 0x1600035
	call SendEvent
	or xhl, xhl
	jr z, WindowID_EnumFill_InnerNext
	ld xwa, (xsp + 16)
	sll xwa, 2
	stb_dri A, 0xfd, 0x14, 0x01
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
	cp xwa, 0xff
	jr ule, WindowID_EnumFill_OuterLoop

WindowID_EventSwitch:
	.byte 0xee, 0xcf, 0x0c, 0x00, 0xe0, 0x01, 0x76, 0x8a
	.byte 0x01, 0xee, 0xcf, 0x0b, 0x00, 0xe0, 0x01, 0x76
	.byte 0xdf, 0x00, 0xee, 0xcf, 0x09, 0x00, 0xe0, 0x01
	.byte 0x76, 0xd6, 0x00, 0xee, 0xcf, 0x28, 0x00, 0xe0
	.byte 0x01, 0x76, 0x6a, 0x01, 0xee, 0xcf, 0x0e, 0x00
	.byte 0xe0, 0x01, 0x76, 0xbc, 0x00, 0xee, 0xcf, 0x0d
	.byte 0x00, 0xe0, 0x01, 0x7e, 0x94, 0x02, 0xe3, 0xfd
	.byte 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60, 0xa8, 0x08
	.byte 0x20, 0xaf, 0x10, 0xf0, 0x6e, 0x16, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x32, 0xab, 0xaf, 0x08, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xef
	.byte 0x60, 0x78, 0x32, 0x01
WindowID_Select_Lookup:
	.byte 0xe8, 0xee, 0x02, 0xf3, 0xfd, 0x14, 0x01, 0x31
	.byte 0xe8, 0x81, 0xa1, 0x20, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x88, 0x55, 0xfa, 0x83
	.byte 0x3f, 0x00, 0x66, 0x18, 0x3b, 0x0b, 0xea, 0x00
	.byte 0x0b, 0x3a, 0xab, 0xaf, 0x0c, 0x20, 0xa8, 0x04
	.byte 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x78, 0xfe, 0x00
WindowID_Select_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xde, (xsp+4)
	ld	xwa, (xde+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43840
	ld	xwa, (xde+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jrl	165
WindowID_EnumCount:
	ld xhl, (xsp + 16)
	inc 1, xhl
	jrl WindowID_Return

WindowID_GetCurrent:
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0xbf, 0x04, 0x60
	.byte 0xe3, 0xfd, 0x14, 0x11, 0x20, 0x1e, 0xd2, 0x09
	.byte 0xaf, 0x04, 0x22, 0xa3, 0x21, 0xb2, 0x61, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x69, 0xea, 0x89, 0xa1, 0x20, 0x41, 0x15, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x88, 0x55, 0xfa
	.byte 0x83, 0x3f, 0x00, 0x66, 0x17, 0x3b, 0x0b, 0xea
	.byte 0x00, 0x0b, 0x48, 0xab, 0xaf, 0x0c, 0x20, 0xa8
	.byte 0x04, 0x20, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf
	.byte 0x0c, 0x37, 0x68, 0x51
WindowID_GetCurrent_NoName:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xbc, (xsp+4)
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43854
	ld	xwa, (xbc+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	jr	19
WindowID_GetCurrent_None:
	pushw	234
	pushw	43862
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+4)
	push	xwa
	call	16713584
	inc	8, xsp
WindowID_ReturnZero:
	lds32 xhl, 0
	jrl WindowID_Return

WindowID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 12), xwa
	ld_sril XWA, (xsp + 0x1114)
	ld (xsp + 4), xwa
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 16)
	cp xwa, 0x0
	jrl ule, WindowID_EnumOpen_NotFound

WindowID_EnumOpen_ScanLoop:
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xee, 0x02, 0xf3, 0xfd
	.byte 0x14, 0x01, 0x31, 0xe8, 0x81, 0xa1, 0x20, 0x41
	.byte 0x15, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x88
	.byte 0x55, 0xfa, 0x83, 0x3f, 0x00, 0x66, 0x14, 0x3b
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x5e, 0xab, 0xbf, 0x1c
	.byte 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x68, 0x50
WindowID_EnumOpen_ScanNoName:
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	srl	xwa, 0
	and	xwa, 4095
	extz	xwa
	add	xwa, 27262976
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	qwa, 0
	pushw	wa
	push	xhl
	pushw	234
	pushw	43876
	lda	xwa, (xsp+30)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
WindowID_EnumOpen_Compare:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 28
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+276)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xbc)
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+12), xwa
	jr	69
WindowID_EnumOpen_ScanNext:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, (xsp + 16)
	jrl c, WindowID_EnumOpen_ScanLoop

WindowID_EnumOpen_NotFound:
	ld	xwa, (xsp+12)
	or	xwa, xwa
	jr	z, 41
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	pushw	234
	pushw	43884
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 18
	ld	xwa, (xsp+4)
	ld	xbc, 4294967295
	ld	(xwa+4), xbc
	lds32	xwa, 0
	ld	(xsp+12), xwa
	jr	7
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
	stb_dri L, 0xfd, 0x18, 0x11
	ret
WindowID_Epilogue:

ModeIDProc:
	stb_dri L, 0xfd, 0xec, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x14, 0x11
	cp xiz, 0x1e0000c
	jr z, ModeID_BuildTable
	cp xiz, 0x1e0000e
	jr z, ModeID_BuildTable
	cp xiz, 0x1e0000d
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
	stb_dri A, 0xfd, 0x10, 0x01
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
	cp xwa, 0x19f
	jr ule, ModeID_BuildTable_OuterLoop

ModeID_EventDispatch:
	cp xiz, 0x1e0000c
	jrl z, ModeID_EnumOpen
	cp xiz, 0x1e0000b
	jrl z, ModeID_GetNext
	cp xiz, 0x1e00009
	jr z, ModeID_GetCurrent
	cp xiz, 0x1e0000e
	jr z, ModeID_EnumCount
	cp xiz, 0x1e0000d
	jr z, ModeID_EnumFill
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl ModeID_Return

ModeID_EnumFill:
	.byte 0xe3, 0xfd, 0x10, 0x11, 0x26, 0xae, 0x08, 0x20
	.byte 0xe8, 0xee, 0x02, 0xf3, 0xfd, 0x10, 0x01, 0x31
	.byte 0xe8, 0x81, 0xa1, 0x20, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0xae
	.byte 0x04, 0x21, 0x83, 0x3f, 0x00, 0x6e, 0x15, 0xae
	.byte 0x08, 0x20, 0x38, 0x0b, 0xea, 0x00, 0x0b, 0x74
	.byte 0xab, 0x39, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x78, 0x94, 0x00
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
	ld xbc, 0x1e00015
	lds32 xde, 0
	call SendEvent
	cp (xhl), 0x0
	jr nz, ModeID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, Str_No_0x866
	jr ModeID_GetCurrent_SendAudio

ModeID_GetCurrent_HasName:
	push xhl
	ld xwa, Str_No_0x86A

ModeID_GetCurrent_SendAudio:
	push	xwa
	ld	xwa, (xiz+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+12)
	jr	72
ModeID_GetNext:
	.byte 0xe3, 0xfd, 0x10, 0x11, 0x26, 0xe3, 0xfd, 0x10
	.byte 0x11, 0x20, 0x1e, 0xa4, 0x06, 0xa3, 0x21, 0xb6
	.byte 0x61, 0xe9, 0x88, 0x41, 0x15, 0x00, 0xe0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0xbe, 0x04
	.byte 0x30, 0x83, 0x3f, 0x00, 0x6e, 0x18, 0xa6, 0x21
	.byte 0xd7, 0xe6, 0xa8, 0x29, 0x0b, 0xea, 0x00, 0x0b
	.byte 0x90, 0xab, 0xa0, 0x20, 0x38, 0x1d, 0x95, 0x02
	.byte 0xff, 0xbf, 0x0a, 0x37, 0x68, 0x0a
ModeID_GetNext_HasName:
	push xhl
	ld xwa, (xwa)
	push xwa

ModeID_Strcpy:
	call	16713584
	inc	8, xsp
ModeID_ReturnZero:
	lds32 xhl, 0
	jrl ModeID_Return

ModeID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld_sril XIZ, (xsp + 0x1110)
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, ModeID_EnumOpen_CheckResult

ModeID_EnumOpen_SearchLoop:
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xee, 0x02, 0xf3, 0xfd
	.byte 0x10, 0x01, 0x31, 0xe8, 0x81, 0xa1, 0x20, 0x41
	.byte 0x15, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x53
	.byte 0x92, 0xfa, 0x3b, 0xbf, 0x14, 0x30, 0x38, 0x1d
	.byte 0x70, 0x07, 0xff, 0xef, 0x60, 0xbf, 0x10, 0x31
	.byte 0x81, 0x3f, 0x00, 0x6e, 0x12, 0xaf, 0x08, 0x20
	.byte 0x38, 0x0b, 0xea, 0x00, 0x0b, 0x98, 0xab, 0x39
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c, 0x37
ModeID_EnumOpen_Compare:
	ld	xwa, (xiz+4)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 25
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+272)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	(xiz+4), xwa
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	20
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
	stb_dri L, 0xfd, 0x14, 0x11
	ret

TitleIDProc:
	stb_dri L, 0xfd, 0xec, 0xee
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x11
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x14, 0x11
	cp xiz, 0x1e0000c
	jr z, TitleID_BuildTable
	cp xiz, 0x1e0000e
	jr z, TitleID_BuildTable
	cp xiz, 0x1e0000d
	jr nz, TitleID_EventDispatch

TitleID_BuildTable:
	lds32 xwa, 0
	ld (xsp + 12), xwa
	ld xwa, 0x1a0
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
	stb_dri A, 0xfd, 0x10, 0x01
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
	cp xwa, 0x1bf
	jr ule, TitleID_BuildTable_OuterLoop

TitleID_EventDispatch:
	cp xiz, 0x1e0000c
	jrl z, TitleID_EnumOpen
	cp xiz, 0x1e0000b
	jrl z, TitleID_GetNext
	cp xiz, 0x1e00009
	jr z, TitleID_GetCurrent
	cp xiz, 0x1e0000e
	jr z, TitleID_EnumCount
	cp xiz, 0x1e0000d
	jr z, TitleID_EnumFill
	ld_sril XWA, (xsp + 0x1114)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x1110)
	calr CommonIDProc
	jrl TitleID_Return

TitleID_EnumFill:
	.byte 0xe3, 0xfd, 0x10, 0x11, 0x26, 0xae, 0x08, 0x20
	.byte 0xe8, 0xee, 0x02, 0xf3, 0xfd, 0x10, 0x01, 0x31
	.byte 0xe8, 0x81, 0xa1, 0x20, 0x41, 0x15, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0xae
	.byte 0x04, 0x21, 0x83, 0x3f, 0x00, 0x6e, 0x15, 0xae
	.byte 0x08, 0x20, 0x38, 0x0b, 0xea, 0x00, 0x0b, 0xa0
	.byte 0xab, 0x39, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c
	.byte 0x37, 0x78, 0x94, 0x00
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
	ld xbc, 0x1e00015
	lds32 xde, 0
	call SendEvent
	cp (xhl), 0x0
	jr nz, TitleID_GetCurrent_HasName
	ld xwa, (xiz)
	push xwa
	ld xwa, Str_No_0x892
	jr TitleID_GetCurrent_SendAudio

TitleID_GetCurrent_HasName:
	push xhl
	ld xwa, Str_No_0x896

TitleID_GetCurrent_SendAudio:
	push	xwa
	ld	xwa, (xiz+4)
	push	xwa
	call	16712341
	lda	xsp, (xsp+12)
	jr	72
TitleID_GetNext:
	.byte 0xe3, 0xfd, 0x10, 0x11, 0x26, 0xe3, 0xfd, 0x10
	.byte 0x11, 0x20, 0x1e, 0x5e, 0x04, 0xa3, 0x21, 0xb6
	.byte 0x61, 0xe9, 0x88, 0x41, 0x15, 0x00, 0xe0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0xbe, 0x04
	.byte 0x30, 0x83, 0x3f, 0x00, 0x6e, 0x18, 0xa6, 0x21
	.byte 0xd7, 0xe6, 0xa8, 0x29, 0x0b, 0xea, 0x00, 0x0b
	.byte 0xbc, 0xab, 0xa0, 0x20, 0x38, 0x1d, 0x95, 0x02
	.byte 0xff, 0xbf, 0x0a, 0x37, 0x68, 0x0a
TitleID_GetNext_HasName:
	push xhl
	ld xwa, (xwa)
	push xwa

TitleID_Strcpy:
	call	16713584
	inc	8, xsp
TitleID_ReturnZero:
	lds32 xhl, 0
	jrl TitleID_Return

TitleID_EnumOpen:
	ld xwa, 0xffffffff
	ld (xsp + 4), xwa
	ld_sril XIZ, (xsp + 0x1110)
	lds32 xwa, 0
	ld (xsp + 8), xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr ule, TitleID_EnumOpen_CheckResult

TitleID_EnumOpen_SearchLoop:
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xee, 0x02, 0xf3, 0xfd
	.byte 0x10, 0x01, 0x31, 0xe8, 0x81, 0xa1, 0x20, 0x41
	.byte 0x15, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x53
	.byte 0x92, 0xfa, 0x3b, 0xbf, 0x14, 0x30, 0x38, 0x1d
	.byte 0x70, 0x07, 0xff, 0xef, 0x60, 0xbf, 0x10, 0x31
	.byte 0x81, 0x3f, 0x00, 0x6e, 0x12, 0xaf, 0x08, 0x20
	.byte 0x38, 0x0b, 0xea, 0x00, 0x0b, 0xc4, 0xab, 0x39
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0c, 0x37
TitleID_EnumOpen_Compare:
	ld	xwa, (xiz+4)
	push	xwa
	lda	xwa, (xsp+20)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	nz, 25
	ld	xwa, (xsp+8)
	sll	xwa, 2
	lda	xbc, (xsp+272)
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	(xiz+4), xwa
	lds32	xwa, 0
	ld	(xsp+4), xwa
	jr	20
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
	stb_dri L, 0xfd, 0x14, 0x11
	ret

NameProc:
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xbc, xwa
	lda xhl, (xiz + 4)
	ld xwa, (xiz + 8)
	cp xde, 0x1e0000c
	jr z, ConstFlagProc_Init
	cp xde, 0x1e0000b
	jr z, NameProc_GetText_CopyStr
	cp xde, 0x1e00009
	jr z, NameProc_GetText
	cp xde, 0x1e00028
	jr z, NameProc_Init_SetPtr
	cp xde, 0x1e00026
	jr z, NameProc_Init
	cp xde, 0x1e00025
	jr z, NameProc_Return
	ld xwa, xbc
	ld xbc, xde
	ld xde, xiz
	calr CommonIDProc
	jr ConstFlagProc_ReturnZero

NameProc_Init:
	ld xwa, Str_No_0x8B6
	jr NameProc_Close

NameProc_Init_SetPtr:
	ld xwa, Str_No_0x8BC

NameProc_Close:
	push xwa
	push xiz
	jr NameProc_DefaultForward

NameProc_GetText:
	pushw 0xea
	pushw 0xabd4
	jr NameProc_ReturnZero

NameProc_GetText_CopyStr:
	ld xbc, 0x1e00015
	lds32 xde, 0
	call SendEvent
	push xhl
	lda xhl, (xiz + 4)

NameProc_ReturnZero:
	ld xwa, (xhl)
	push xwa

NameProc_DefaultForward:
	call	16713584
	inc	8, xsp
NameProc_Return:
	lds32 xhl, 0
	jr ConstFlagProc_ReturnZero

ConstFlagProc_Init:
	ld xde, (xhl)
	ld xbc, 0x1e00016
	call SendEvent

ConstFlagProc_ReturnZero:
	pop xiz
	ret
ConstFlagProc_Return:

ConstFlagProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	cp xbc, 0x1e0000c
	jrl z, ConstFlagProc_Default_Result
	cp xbc, 0x1e0000b
	jr z, ConstFlagProc_Default
	cp xbc, 0x1e00009
	jr z, ConstFlagProc_SetValue_Check
	cp xbc, 0x1e00028
	jr z, ConstFlagProc_GetValue_Set
	cp xbc, 0x1e00026
	jr z, ConstFlagProc_GetValue
	cp xbc, 0x1e00025
	jr z, ConstFlagProc_Default_Forward
	ld xwa, (xsp + 8)
	ld xde, (xsp + 4)
	calr CommonIDProc
	jr ConstFlagProc_Default_Done

ConstFlagProc_GetValue:
	ld xwa, Str_No_0x8C0
	jr ConstFlagProc_SetValue

ConstFlagProc_GetValue_Set:
	ld xwa, Str_No_0x8C8

ConstFlagProc_SetValue:
	push xwa
	ld xwa, (xsp + 8)
	push xwa
	jr ConstFlagProc_SetValue_Store

ConstFlagProc_SetValue_Check:
	pushw 0xea
	pushw 0xabe0
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 4)
	push xwa

ConstFlagProc_SetValue_Store:
	call	16713584
	inc	8, xsp
	jr	33
ConstFlagProc_Default:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 8)
	call GetConst
	exts xhl
	ld xwa, (xsp + 4)
	ld (xwa + 8), xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1e0000d
	ld xde, (xsp + 4)
	call SendEvent

ConstFlagProc_Default_Forward:
	lds32 xhl, 0
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
ConstFlagProc_Default_DoneAlt:

ObjectIDProc:
	jrl slongProc

pFuncProc:
	jrl DrawHelper_B_Setup
ConstFlagProc_Epilogue:

pProcProc:
	jrl DrawHelper_B_Setup

pPropProc:
	jrl BoxStyle4_Return
; WidgetType dispatch (pStringProc/EventIDProc)
WidgetType_DispatchDSP:
pStringProc:
	jrl BoxStyle4_Return

EventIDProc:
	jrl slongProc

CommonIDProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld xiz, xbc
	ld (xsp + 20), xwa
	ld xwa, (xsp + 20)
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 12), xhl
	ld xde, xiz
	cp xiz, 0x1e00028
	jrl z, CommonIDProc_ReturnZero
	cp xiz, 0x1e00026
	jr z, CommonIDProc_CheckAvail
	cp xiz, 0x1e00025
	jrl z, CommonIDProc_ReturnZero
	ld xwa, (xsp + 12)
	lda xbc, (xwa + 4)
	sub xde, 0x1e00008
	cp xde, 0x0
	jrl lt, CommonIDProc_Default
	cp xde, 0x6
	jrl gt, CommonIDProc_Default
	add xde, xde
	add xde, Str_No_0x8CE
	ld de, (xde)
	lda_24 xix, (CommonIDProc_JumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe8
CommonIDProc_JumpTable:
	ld	xwa, (xsp+16)
	ld	(xsp+4), xwa
	ld	xbc, (xwa+8)
	sll	xbc, 3
	ld	xwa, (xsp+12)
	add	xbc, (xwa+8)
	ld	xwa, (xbc)
	push	xwa
	jr	24
	ld	hl, (xbc)
	extz	xhl
	jrl	278

CommonIDProc_CheckAvail:
	.byte 0xeb, 0xa9, 0x78, 0x11, 0x01, 0xaf, 0x10, 0x20
	.byte 0xbf, 0x04, 0x60, 0x0b, 0xea, 0x00, 0x0b, 0xe2
	.byte 0xab, 0xaf, 0x08, 0x20, 0xa8, 0x04, 0x20, 0x38
	.byte 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60, 0x68, 0x58
	.byte 0xaf, 0x10, 0x20, 0xbf, 0x04, 0x60, 0x0b, 0x0a
	.byte 0x00, 0xaf, 0x06, 0x21, 0xa9, 0x04, 0x20, 0x38
	.byte 0xa1, 0x20, 0x38, 0x1d, 0xe1, 0x07, 0xff, 0xbf
	.byte 0x0a, 0x37, 0xaf, 0x0c, 0x20, 0x98, 0x04, 0x3f
	.byte 0x00, 0x00, 0x66, 0x34, 0xde, 0xa8, 0xa8, 0x08
	.byte 0x21, 0xaf, 0x04, 0x20, 0xa0, 0x20, 0xea, 0xa8
	.byte 0x68, 0x1b
CommonIDProc_SearchLoop_Compare:
	.byte 0xab, 0x04, 0xf0, 0x6e, 0x12, 0xa3, 0x20, 0x38
	.byte 0xaf, 0x08, 0x20, 0xa8, 0x04, 0x20, 0x38, 0x1d
	.byte 0x70, 0x07, 0xff, 0xef, 0x60, 0x68, 0x0f
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
	.byte 0xaf, 0x04, 0x20, 0xa8, 0x04, 0x20, 0x38, 0xa1
	.byte 0x20, 0x38, 0x1d, 0x58, 0x07, 0xff, 0xef, 0x60
	.byte 0xdb, 0xd8, 0x6e, 0x18, 0xde, 0x89, 0xe9, 0x12
	.byte 0xe9, 0xee, 0x03, 0xaf, 0x0c, 0x20, 0xa8, 0x08
	.byte 0x81, 0xaf, 0x04, 0x20, 0xa9, 0x04, 0x21, 0xb8
	.byte 0x04, 0x61, 0x68, 0x16
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
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+4)
	push	xwa
	call	16712217
	inc	4, xsp
	ld	xwa, (xsp+4)
	ld	(xwa+4), xhl
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
	stb_dri L, 0xfd, 0xfa, 0xfe
	push xiz
	stw_dri BC, 0xfd, 0x08, 0x01
	ld xiz, xwa
	lda xde, (xsp + 8)
	ld xwa, xiz
	ld xbc, 0x1e00019
	call SendEvent
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lds iz, 0
	ldiw_erp 0xfa, 0
	cpiw_sri 0xfd, 0x08, 0x01, 0x00, 0x00
	jr ule, IDCountHelper_Done

IDCountHelper_Loop:
	lda xwa, (xsp + 8)
	ldb_sri A, 0x07, 0xe0, 0xfa
	sub a, 0x41
	ldb w, 0x0
	extz xwa
	add xwa, 0x2600000
	ld xbc, 0x1e00027
	lds32 xde, 0
	call SendEvent
	ld wa, iz
	add wa, hl
	ld iz, wa
	inc1w_erp 0xfa
	stw_erp WA, 0xfa
	cpw_sri_rm WA, 0xfd, 0x08, 0x01
	jr c, IDCountHelper_Loop

IDCountHelper_Done:
	ld xwa, (xsp + 4)
	stb_dri C, 0x07, 0xe0, 0xf8
	pop xiz
	stb_dri L, 0xfd, 0x06, 0x01
	ret

IDCursorAdvance:
	stb_dri L, 0xfd, 0x78, 0xff
	pushw iz
	ld (xsp + 2), xwa
	ld xwa, (xwa + 8)
	lda xde, (xsp + 10)
	ld xbc, 0x1e00019
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
	ld xbc, 0x1e00027
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
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	add xhl, (xsp + 6)
	popw iz
	stb_dri L, 0xfd, 0x88, 0x00
	ret

InitializeEventQueue:
	ret

DispatchEvent:	; SysData_FA9585
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr GetEvent
	cps hl, 0
	jrl z, EventHandler_DispatchLoop

; EventHandler dual-phase dispatch
EventHandler_ObjectDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xffffffff
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027ed6)
	add xwa, xbc
	ld xhl, (xwa)
	or xhl, xhl
	jrl z, EventHandler_ContinueProc
	ld xwa, (xsp + 8)
	stl_da (0x02bc24), xwa
	stl_da (0x02bc18), xwa
	ld xwa, (xsp + 4)
	stl_da (0x02bc28), xwa
	stl_da (0x02bc1c), xwa
	ld xwa, (xsp)
	stl_da (0x02bc2c), xwa
	stl_da (0x02bc20), xwa
	ld xwa, (xsp + 8)
	ld xix, xhl
	ld xbc, 0x1e00000
	lds32 xde, 0
	call (xix)
	stl_da (0x02bc14), xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	cpw_da (0x03ef4e), 0
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
	srl xwa, 0
	and xwa, 0xfff
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027ed6)
	add xwa, xbc
	ld xhl, (xwa)
	ldl_da xwa, (0x02bc24)
	ld (xsp + 12), xwa
	ldl_da xwa, (0x02bc28)
	ld (xsp + 16), xwa
	ldl_da xwa, (0x02bc2c)
	ld (xsp + 8), xwa
	stl_da (0x02bc24), xiz
	ld xwa, (xsp + 24)
	stl_da (0x02bc28), xwa
	ld xwa, (xsp + 20)
	stl_da (0x02bc2c), xwa
	ldl_da xwa, (0x02bc14)
	ld (xsp + 4), xwa
	ld xix, xhl
	ld xwa, xiz
	ld xbc, 0x1e00000
	lds32 xde, 0
	call (xix)
	stl_da (0x02bc14), xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	stl_da (0x02bc14), xwa
	ld xwa, (xsp + 12)
	stl_da (0x02bc24), xwa
	ld xwa, (xsp + 16)
	stl_da (0x02bc28), xwa
	ld xwa, (xsp + 8)
	stl_da (0x02bc2c), xwa
	cpw_da (0x03ef4e), 0
	jr z, EventRoute_DispatchJump
	lds wa, 3
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
	lds wa, 4
	call TaskSched_WaitForEvent
	ldw_da xbc, (0x02ec34)
	ldw_da xde, (0x02ec36)
	ld wa, de
	inc 1, wa
	cp wa, bc
	jr z, EventRoute_CheckOwner
	ld wa, de
	sub wa, 0x3ff
	cp wa, bc
	jr nz, EventRoute_OwnerMatchDone

EventRoute_CheckOwner:
	lds wa, 4
	call TaskSched_SignalEvent
	pop xiz
	inc 8, xsp

EventRoute_OwnerMatch:
	jr EventRoute_OwnerMatch

EventRoute_OwnerMatchDone:
	incdi16_24 1, (0x02f840)
	ld bc, de
	muls bc, 0xc
	lda_24 xwa, (0x02bc34)
	exts xbc
	add xbc, xwa
	ld (xbc), xiz
	ld xwa, (xsp + 8)
	ld (xbc + 4), xwa
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	cp de, 0x3ff
	jr nz, PostEvent_Prologue
	stiw_da (0x02ec36), 0x0000
	jr PostEvent_AllocSlot

PostEvent_Prologue:
	incdi16_24 1, (0x02ec36)

PostEvent_AllocSlot:
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
	ldw_da xwa, (0x02ec34)
	cpda16_24 xwa, (0x02ec36)
	jr nz, PostEvent_FillSlot
	lds wa, 4
	call TaskSched_SignalEvent
	lds hl, 0
	jr GetEvent_Prologue

PostEvent_FillSlot:
	decdi16_24 1, (0x02f840)
	ldw_da xwa, (0x02ec34)
	ld (xsp + 4), wa
	ld bc, (xsp + 4)
	muls bc, 0xc
	lda_24 xwa, (0x02bc34)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	ld (xiz), xwa
	cp xwa, 0xffffffff
	jr nz, PostEvent_LinkSlot
	calr GetCurrentTarget
	ld (xiz), xhl

PostEvent_LinkSlot:
	ld bc, (xsp + 4)
	muls bc, 0xc
	lda_24 xwa, (0x02bc34)
	stb_dri B, 0x07, 0xe0, 0xe4
	ld xwa, (xsp + 10)
	ld xbc, (xde + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 6)
	ld xbc, (xde + 8)
	ld (xwa), xbc
	cpw (xsp + 4), 0x3ff
	jr nz, PostEvent_ReturnZero
	stiw_da (0x02ec34), 0x0000
	jr PostEvent_Return

PostEvent_ReturnZero:
	incdi16_24 1, (0x02ec34)

PostEvent_Return:
	lds wa, 4
	call TaskSched_SignalEvent
	lds hl, 1

GetEvent_Prologue:
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
	ldw_da xbc, (0x02ec36)
	ldw_da xwa, (0x02ec34)
	cp wa, bc
	jr nz, GetEvent_ScanLoop
	lds wa, 4
	jr GetEvent_Return

GetEvent_ScanLoop:
	ld ix, wa
	cp wa, bc
	jr z, GetEvent_ReturnOne
	lda_24 xiy, (0x02bc34)

GetEvent_ScanMatch:
	ld wa, ix
	muls wa, 0xc
	stb_dri C, 0x07, 0xf4, 0xe0
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, GetEvent_ScanDone
	cp (xhl), xiz
	jr nz, GetEvent_ScanDone
	ld xwa, 0x1c00000
	ld (xde), xwa

GetEvent_ScanDone:
	cp ix, bc
	jr z, GetEvent_ReturnOne
	cp ix, 0x3ff
	jr nz, GetEvent_ReturnZero
	lds ix, 0
	jr GetEvent_ReturnZeroAlt

GetEvent_ReturnZero:
	inc 1, ix

GetEvent_ReturnZeroAlt:
	cp ix, bc
	jr nz, GetEvent_ScanMatch

GetEvent_ReturnOne:
	lds wa, 4

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
	lds wa, 4
	call TaskSched_WaitForEvent
	ldw_da xbc, (0x02ec36)
	ldw_da xwa, (0x02ec34)
	cp wa, bc
	jr nz, DeleteEvent_Prologue
	lds wa, 4
	jr DeleteEvent_Epilogue

DeleteEvent_Prologue:
	ld hl, wa
	cp wa, bc
	jr z, DeleteEvent_Return
	lda_24 xix, (0x02bc34)

DeleteEvent_ScanLoop:
	ld wa, hl
	muls wa, 0xc
	stb_dri E, 0x07, 0xf0, 0xe0
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop2
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop2
	ld xwa, 0x1c00000
	ld (xde), xwa

ObjectSearch_ContinueLoop2:
	cp hl, bc
	jr z, DeleteEvent_Return
	cp hl, 0x3ff
	jr nz, DeleteEvent_Match
	lds hl, 0
	jr DeleteEvent_CheckNext

DeleteEvent_Match:
	inc 1, hl

DeleteEvent_CheckNext:
	cp hl, bc
	jr nz, DeleteEvent_ScanLoop

DeleteEvent_Return:
	lds wa, 4

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
	lds	wa, 4
	call TaskSched_WaitForEvent				; acquire lock/semaphore (id=4)
	ldw_da	bc, (0x02ec36)
	ldw_da	de, (0x02ec34)
	cp de, bc				; compare read/write positions
	jr nz, DeleteSpecEvent_Prologue			; buffer not empty, process events
	; --- Buffer empty: release lock, dispatch directly ---
	lds	wa, 4
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
	lda_24 xwa, (0x02bc34); XWA = base of registration table
	lda_rr	xwa, xwa, bc
	lda xbc, (xwa + 4)			; XBC = pointer to entry+4 (event code)
	ld xde, (xbc)				; XDE = registered event code
	cp xde, 0x01c00038			; compare with key press event
	jr nz, DeleteSpecEvent_Match			; no match, skip this entry
	; --- Event code matches: check filter ---
	lda xde, (xwa + 8)			; XDE = pointer to entry+8 (filter)
	ld xwa, (xde)				; XWA = registered filter value
	lds	wa, 0
	ld xiy, (xsp + 12)			; XIY = original event param
	and xiy, 0xffff0000			; isolate upper 16 bits
	cp xiy, xwa				; compare filter with event param upper bits
	jr nz, DeleteSpecEvent_Match			; no match
	; --- Filter matches: update registration and accumulate bits ---
	ld xwa, 0x01c00000			; mark as active (clear low 16 bits)
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
	stb_erp	a, 251
	and a, c				; clear bits in QIZH where filter has 1s
	ldb_erp	a, 251
	and e, b				; E = filter & filter (= filter)
	stb_erp	a, 251
	add a, e				; set bits in QIZH where filter has 1s
	ldb_erp	a, 251
	or (xsp + 8), b				; accumulate filter byte 0 into (xsp+8)
DeleteSpecEvent_Match:
	; --- Advance to next registration entry ---
	cp ix, hl				; reached end sentinel?
	jr z, DeleteSpecEvent_Epilogue			; yes, done scanning
	cp ix, 0x03ff				; check for index wrap
	jr nz, DeleteSpecEvent_CheckNext			; no wrap needed
	lds	ix, 0
	jr DeleteSpecEvent_Return				; skip increment
DeleteSpecEvent_CheckNext:
	inc 1, ix				; next entry index
DeleteSpecEvent_Return:
	cp ix, hl				; check end again
	jr nz, DeleteSpecEvent_ScanLoop			; continue scanning
DeleteSpecEvent_Epilogue:
	; --- Done scanning: release lock and reassemble event param ---
	lds	wa, 4
	call TaskSched_SignalEvent				; release lock/semaphore
	ld c, (xsp + 6)				; C = param byte 0
	cpl c					; C = ~param byte 0
	stb_erp	a, 251
	and a, c				; clear bits
	ldb_erp	a, 251
	ld c, (xsp + 10)			; C = param byte 1
	and c, (xsp + 6)			; C = byte1 & byte0
	stb_erp	a, 251
	add a, c				; accumulate
	ldb_erp	a, 251
	ld a, (xsp + 6)				; A = param byte 0
	or (xsp + 8), a				; accumulate into (xsp+8)
	; --- Build final XDE from accumulated data ---
	ld xwa, 0xffff0000			; mask for upper 16 bits
	and (xsp + 2), xwa			; keep upper 16 bits of working param
	lds32	xbc, 0
	stb_erp	c, 251
	sll xbc, 8				; shift QIZH value into byte 1 position
	lds32	xwa, 0
	ld a, (xsp + 8)				; A = accumulator byte
	add xwa, xbc				; merge
	add (xsp + 2), xwa			; merge into working param
	; --- Dispatch event ---
	ld xwa, (xsp + 20)			; restore target workspace
	ld xbc, (xsp + 16)			; restore event code
	ld xde, (xsp + 2)			; load modified event param
MainSendEvent_Prologue:
	calr	744
	pop qiz					; restore QIZ
	lda xsp, (xsp + 22)			; deallocate stack frame
	ret


GetCurrentTarget:
	ldl_da xhl, (0x02f83c)
	ret

SetCurrentTarget:
	cp xwa, 0xffffffff
	ret z
	stl_da (0x02f83c), xwa
	ret

MainDispatchEvent:
	lda xsp, (xsp - 12)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xde, (xsp)
	calr MainGetEvent
	cps hl, 0
	jr z, MainSendEvent_Dispatch

; MainSendEvent object dispatch
MainSendEvent_VirtualDispatch:
	ld xwa, (xsp + 8)
	cp xwa, 0xffffffff
	jr z, MainSendEvent_Return
	ld xwa, (xsp + 8)
	srl xwa, 0
	and xwa, 0xfff
	ld xde, (xsp + 8)
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	cps hl, 0
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
	lds32 xhl, 0
	jr MainPostEvent_Return

; MainPostEvent queued dispatch with validation
MainPostEvent_VirtualDispatch:
	ld xwa, xiz
	ld xbc, 0x1e00014
	ld xde, 0x1600003
	calr SendEvent
	or xhl, xhl
	jr z, MainPostEvent_ReturnZero
	ld xwa, xiz
	srl xwa, 0
	and xwa, 0xfff
	ld xde, xiz
	ldiw_erp 0xea, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
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
	lds32 xhl, 0

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
	lds wa, 7
	jr MainPostEvent_Allocate

MainPostEvent_VirtDispatch_Prologue:
	lds wa, 7
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, MainGetEvent_ScanMatch
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 7

MainPostEvent_Allocate:
	call TaskSched_WaitForEvent
	ldw_da xwa, (0x02f83a)
	ld de, wa
	inc 1, de
	ldw_da xbc, (0x02f838)
	cp de, bc
	jr z, MainPostEvent_VirtDispatch_Prologue
	sub wa, 0xff
	cp wa, bc
	jr z, MainPostEvent_VirtDispatch_Prologue
	incdi16_24 1, (0x02f842)
	ldw_da xwa, (0x02f83a)
	muls wa, 0xc
	lda_24 xbc, (0x02ec38)
	stl_dri XIZ, 0x07, 0xe4, 0xe0
	ldw_da xwa, (0x02f83a)
	muls wa, 0xc
	stb_dri B, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ldw_da xwa, (0x02f83a)
	muls wa, 0xc
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ldw_da xwa, (0x02f83a)
	cp wa, 0xff
	jr nz, MainGetEvent_Prologue
	stiw_da (0x02f83a), 0x0000
	jr MainGetEvent_ScanLoop

MainGetEvent_Prologue:
	inc 1, wa
	stw_da (0x02f83a), xwa

MainGetEvent_ScanLoop:
	lds wa, 7
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
	lds wa, 7
	call TaskSched_WaitForEvent
	ldw_da xwa, (0x02f838)
	cpda16_24 xwa, (0x02f83a)
	jr nz, MainGetEvent_ScanDone
	lds wa, 7
	call TaskSched_SignalEvent
	lds hl, 0
	jr MainGetEvent_Return

MainGetEvent_ScanDone:
	decdi16_24 1, (0x02f842)
	ldw_da xde, (0x02f838)
	ld bc, de
	muls bc, 0xc
	lda_24 xwa, (0x02ec38)
	stb_dri C, 0x07, 0xe0, 0xe4
	ld xwa, (xhl)
	ld (xiz), xwa
	ld xwa, (xsp + 8)
	ld xbc, (xhl + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 4)
	ld xbc, (xhl + 8)
	ld (xwa), xbc
	cp de, 0xff
	jr nz, MainGetEvent_ReturnZero
	stiw_da (0x02f838), 0x0000
	jr MainGetEvent_ReturnZeroAlt

MainGetEvent_ReturnZero:
	incdi16_24 1, (0x02f838)

MainGetEvent_ReturnZeroAlt:
	lds wa, 7
	call TaskSched_SignalEvent
	lds hl, 1

MainGetEvent_Return:
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
	ldw_da xbc, (0x02f83a)
	ldw_da xwa, (0x02f838)
	cp wa, bc
	jr nz, MainDeleteEvent_Prologue
	lds wa, 7
	jr MainDeleteEvent_Epilogue

MainDeleteEvent_Prologue:
	ld ix, wa
	cp wa, bc
	jr z, MainDeleteEvent_ReturnAlt
	lda_24 xiy, (0x02ec38)

MainDeleteEvent_ScanLoop:
	ld wa, ix
	muls wa, 0xc
	stb_dri C, 0x07, 0xf4, 0xe0
	lda xde, (xhl + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 4)
	jr nz, MainDeleteEvent_Match
	cp (xhl), xiz
	jr nz, MainDeleteEvent_Match
	ld xwa, 0x1c00000
	ld (xde), xwa

MainDeleteEvent_Match:
	cp ix, bc
	jr z, MainDeleteEvent_ReturnAlt
	cp ix, 0x3ff
	jr nz, MainDeleteEvent_CheckNext
	lds ix, 0
	jr MainDeleteEvent_Return

MainDeleteEvent_CheckNext:
	inc 1, ix

MainDeleteEvent_Return:
	cp ix, bc
	jr nz, MainDeleteEvent_ScanLoop

MainDeleteEvent_ReturnAlt:
	lds wa, 7

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
	lds wa, 7
	call TaskSched_WaitForEvent
	ldw_da xbc, (0x02f83a)
	ldw_da xwa, (0x02f838)
	cp wa, bc
	jr nz, MainDeleteSpecEvent_Prologue
	lds wa, 7
	jr MainDeleteSpecEvent_Epilogue

MainDeleteSpecEvent_Prologue:
	ld hl, wa
	cp wa, bc
	jr z, MainDeleteSpecEvent_Return
	lda_24 xix, (0x02ec38)

MainDeleteSpecEvent_ScanLoop:
	ld wa, hl
	muls wa, 0xc
	stb_dri E, 0x07, 0xf0, 0xe0
	lda xde, (xiy + 4)
	ld xwa, (xde)
	cp xwa, (xsp + 8)
	jr nz, ObjectSearch_ContinueLoop
	cp (xiy), xiz
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, (xiy + 8)
	cp xwa, (xsp + 4)
	jr nz, ObjectSearch_ContinueLoop
	ld xwa, 0x1c00000
	ld (xde), xwa

ObjectSearch_ContinueLoop:
	cp hl, bc
	jr z, MainDeleteSpecEvent_Return
	cp hl, 0x3ff
	jr nz, MainDeleteSpecEvent_Match
	lds hl, 0
	jr MainDeleteSpecEvent_CheckNext

MainDeleteSpecEvent_Match:
	inc 1, hl

MainDeleteSpecEvent_CheckNext:
	cp hl, bc
	jr nz, MainDeleteSpecEvent_ScanLoop

MainDeleteSpecEvent_Return:
	lds wa, 7

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
	lds wa, 4
	jr ObjectSearch_Continue

ObjectSearch_CheckLoop:
	lds wa, 4
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, ApDeliveryEvent_Prologue
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 4

ObjectSearch_Continue:
	call TaskSched_WaitForEvent
	ldw_da xwa, (0x02ec36)
	ld de, wa
	inc 1, de
	ldw_da xbc, (0x02ec34)
	cp de, bc
	jr z, ObjectSearch_CheckLoop
	sub wa, 0x3ff
	cp wa, bc
	jr z, ObjectSearch_CheckLoop
	incdi16_24 1, (0x02f840)
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	lda_24 xbc, (0x02bc34)
	stl_dri XIZ, 0x07, 0xe4, 0xe0
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	stb_dri B, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 8)
	ld (xde + 4), xwa
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 4)
	ld (xbc + 8), xwa
	ldw_da xwa, (0x02ec36)
	cp wa, 0x3ff
	jr nz, ApPostEvent_ReturnZero
	stiw_da (0x02ec36), 0x0000
	jr ApPostEvent_Return

ApPostEvent_ReturnZero:
	inc 1, wa
	stw_da (0x02ec36), xwa

ApPostEvent_Return:
	lds wa, 4
	call TaskSched_SignalEvent
	lds wa, 2
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
	lds wa, 4
	jr ApDeliveryEvent_Deliver

ApDeliveryEvent_ScanLoop:
	lds wa, 4
	call TaskSched_SignalEvent
	call Boot_CheckConfigFlag7
	cps hl, 0
	jrl z, ApTimer_Deliver
	lds wa, 3
	call TaskSched_YieldToQueue
	lds wa, 4

ApDeliveryEvent_Deliver:
	call	15670909
	ldw_da	wa, (191542)
	ld	de, wa
	inc	1, de
	ldw_da	bc, (191540)
	cp	de, bc
	jr	z, -45
	sub	wa, 1023
	cp	wa, bc
	jr	z, -53
	cp	xiz, 4294967295
	jr	z, 44
	pushw	12
	call	16713379
	inc	2, xsp
	ld	(xsp+4), xhl
	ld	(xhl), xiz
	ld	xwa, (xsp+12)
	ld	(xhl+4), xwa
	ld	xwa, (xsp+8)
	ld	(xhl+8), xwa
	ld	xiz, 4294967295
	ld	xwa, 29360183
	ld	(xsp+12), xwa
	ld	(xsp+8), xhl
	jr	5
ApDeliveryEvent_ReturnZero:
	lds32 xwa, 0
	ld (xsp + 4), xwa

ApDeliveryEvent_Return:
	incdi16_24 1, (0x02f840)
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	lda_24 xbc, (0x02bc34)
	stl_dri XIZ, 0x07, 0xe4, 0xe0
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	stb_dri B, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 12)
	ld (xde + 4), xwa
	ldw_da xwa, (0x02ec36)
	muls wa, 0xc
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 8)
	ld (xbc + 8), xwa
	ldw_da xwa, (0x02ec36)
	cp wa, 0x3ff
	jr nz, ApTimer_Prologue
	stiw_da (0x02ec36), 0x0000
	jr ApTimer_ScanLoop

ApTimer_Prologue:
	inc 1, wa
	stw_da (0x02ec36), xwa

ApTimer_ScanLoop:
	lds wa, 4
	call TaskSched_SignalEvent
	lds wa, 2
	call TaskSched_SignalEvent
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr z, ApTimer_Deliver
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 4)
	calr ApPostEvent

ApTimer_Deliver:
	pop xiz
	lda xsp, (xsp + 12)
	ret

InitializeTimer:
	lds32 xwa, 0
	stl_da (0x030444), xwa
	stiw_da (0x030448), 0xffff
	lda_24 xwa, (0x02f844)
	lda xbc, (xwa + 8)
	lda xde, (xwa + 2)
	ld xhl, xwa
	stb_dri D, 0xe1, 0x00, 0x0c

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
	cpw_da (0x030448), 0xffff
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
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	lda_24 xhl, (0x02f844)
	stb_dri D, 0x07, 0xec, 0xe0
	lda xwa, (xix + 2)
	cp xiz, 0xffffffff
	jr nz, SetApTimer_Prologue
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	stb_dri C, 0x07, 0xec, 0xe0
	ld xwa, 0xffffffff
	ld (xhl + 8), xwa
	stw_da (0x030448), xbc
	cp bc, 0xffff
	jrl z, ApTimer_IncrementCounter
	jr SetApTimer_Allocate

SetApTimer_Prologue:
	ld xbc, xiz
	srl xbc, 0
	and xbc, 0xfff
	extz xbc
	ld xde, xbc
	sll xde, 3
	sub xde, xbc
	add xde, xde
	lda_24 xbc, (0x027ed6)
	add xbc, xde
	ld xde, (xbc)
	or xde, xde
	jr nz, RootContext_Setup
	ld xde, xhl
	ld bc, (xwa)
	ldw (xix), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	stb_dri C, 0x07, 0xec, 0xe0
	ld xwa, 0xffffffff
	ld (xhl + 8), xwa
	stw_da (0x030448), xbc
	cp bc, 0xffff
	jrl z, ApTimer_IncrementCounter

SetApTimer_Allocate:
	muls bc, 0x18
	stiw_ind 0x07, 0xe8, 0xe4, 0xff, 0xff
	jrl SetApTimer_Return

; RootContext setup handler
RootContext_Setup:
	stl_da (0x02bc24), xiz
	stl_da (0x02bc18), xiz
	ld xwa, (xsp + 4)
	stl_da (0x02bc28), xwa
	stl_da (0x02bc1c), xwa
	ld xwa, (xsp + 8)
	stl_da (0x02bc2c), xwa
	stl_da (0x02bc20), xwa
	ld xix, xde
	ld xwa, xiz
	ld xbc, 0x1e00000
	lds32 xde, 0
	call (xix)
	stl_da (0x02bc14), xhl
	ld xwa, xhl
	srl xwa, 0
	and xwa, 0xfff
	ldiw_erp 0xee, 0
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xwa, (0x027edc)
	add xwa, xbc
	ld xde, (xwa)
	extz xhl
	ld xbc, xhl
	add xbc, xbc
	add xbc, xhl
	sll xbc, 3
	add xbc, xde
	ld xde, (xbc)
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	lda_24 xhl, (0x02f844)
	exts xwa
	add xwa, xhl
	ld bc, (xwa + 2)
	ldw (xwa), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	exts xwa
	add xwa, xhl
	ldw (xwa + 2), 0xffff
	ldw_da xwa, (0x030448)
	muls wa, 0x18
	stb_dri D, 0x07, 0xec, 0xe0
	ld xwa, 0xffffffff
	ld (xix + 8), xwa
	stw_da (0x030448), xbc
	cp bc, 0xffff
	jr z, ApTimer_VirtualDispatch
	muls bc, 0x18
	stiw_ind 0x07, 0xec, 0xe4, 0xff, 0xff

; ApTimer dispatcher
ApTimer_VirtualDispatch:
	ld xhl, xde
	ld xwa, xiz
	ld xbc, (xsp + 4)
	ld xde, (xsp + 8)
	call (xhl)
	cpw_da (0x030448), 0xffff
	jr z, ApTimer_IncrementCounter

SetApTimer_Return:
	ldw_da xbc, (0x030448)
	muls bc, 0x18
	lda_24 xwa, (0x02f844)
	exts xbc
	add xbc, xwa
	ld xwa, (xbc + 4)
	cpda32_24 xwa, (0x030444)
	jrl ule, ApTimer_VirtDispatch_Prologue

ApTimer_IncrementCounter:
	lds32 xwa, 1
	addl_da 0x030444, xwa
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

ResetApTimer_Prologue:
	ld wa, bc
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 3
	lda_24 xhl, (0x02f844)
	ld (xsp + 4), xhl
	add xhl, xde
	lda xix, (xhl + 8)
	ld xwa, (xix)
	cp xwa, 0xffffffff
	jrl nz, ResetApTimer_ReturnOne
	lda xde, (xhl + 4)
	ldl_da xwa, (0x030444)
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
	ldw_da xix, (0x030448)
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
	stb_dri W, 0x07, 0xe0, 0xf4
	ld (xwa + 2), bc

ResetApTimer_NotFound:
	cp ix, 0xffff
	jr z, ResetApTimer_ReturnZero
	ld de, ix
	muls de, 0x18
	ld xwa, (xsp + 4)
	stw_dri BC, 0x07, 0xe0, 0xe8

ResetApTimer_ReturnZero:
	cpda16_24 xix, (0x030448)
	jr nz, ResetApTimer_ReturnOneDone

ResetApTimer_ReturnAlt:
	stw_da (0x030448), xbc
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
	cps hl, 0
	jr z, KillApTimer_ReturnZero
	ld xwa, (xsp + 24)
	push xwa
	push xiz
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	calr SetApTimer
	lds hl, 1
	jr KillApTimer_Return

KillApTimer_ReturnZero:
	lds hl, 0

KillApTimer_Return:
	pop xiz
	lda xsp, (xsp + 12)
	retd 0x8

KillApTimer:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ldw_da xix, (0x030448)
	cp ix, 0xffff
	jrl z, KillApTimer_CheckNextEntry_Return
	lda_24 xiy, (0x02f844)

KillApTimer_CheckNextEntry_Loop:
	ld wa, ix
	muls wa, 0x18
	stb_dri C, 0x07, 0xf4, 0xe0
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
	stw_dri WA, 0x07, 0xf4, 0xf8

KillApTimer_CheckNextEntry_Match:
	cpw (xhl), 0xffff
	jr z, KillApTimer_CheckNextEntry_Unlink
	ld wa, (xhl)
	muls wa, 0x18
	stb_dri E, 0x07, 0xf4, 0xe0
	ld wa, (xbc)
	ld (xiy + 2), wa

KillApTimer_CheckNextEntry_Unlink:
	cpda16_24 xix, (0x030448)
	jr nz, KillApTimer_CheckNextEntry_Done
	ld wa, (xbc)
	stw_da (0x030448), xwa

KillApTimer_CheckNextEntry_Done:
	ld xwa, 0xffffffff
	ld (xde), xwa
	ldw (xbc), 0xffff
	ldw (xhl), 0xffff
	lds hl, 1
	jr KillApTimer_CheckNextEntry_Epilogue

ApTimer_KillApTimer_CheckNextEntry:
	ld ix, (xiz)
	cp ix, 0xffff
	jrl nz, KillApTimer_CheckNextEntry_Loop

KillApTimer_CheckNextEntry_Return:
	lds hl, 0

KillApTimer_CheckNextEntry_Epilogue:
	pop xiz
	inc 4, xsp
	retd 0x8
	push xiz

DrawTask_EventLoop:
	calr DrawTask_Dispatch
	ld xiz, xhl
	cpw_da (0x03ef4e), 0
	jr z, DrawTask_FuncDispatch
	lds wa, 5
	lds bc, 3
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
	cpw_da (0x03ef4e), 0
	jr z, DrawTask_EventLoop
	lds wa, 5
	lds bc, 3
	call TaskSched_ChangePriority
	jr DrawTask_EventLoop

DrawTask_DequeueLoop:
	ldw_da xwa, (0x030450)
	stw_da (0x03044e), xwa
	lds wa, 1
	call Audio_Lock_Acquire
	jr DrawTask_EventLoop

InitDrawTask:
	jr DrawTask_DequeueLoop_Check

DrawTask_DequeueLoop_Check:
	lds wa, 3
	call TaskSched_WaitForEvent
	calr DisplayCmd_ScanQueue_Continue
	lds wa, 3
	jp TaskSched_SignalEvent

DrawTask_Dispatch:
	push xiz
	lds wa, 3
	call TaskSched_WaitForEvent
	calr DisplayCmd_Execute
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

DisplayCmd_ScanQueue:
	lds wa, 3
	call TaskSched_WaitForEvent
	ld xwa, (xsp + 4)
	calr DisplayCmd_Execute_Type2
	ld xiz, xhl
	lds wa, 3
	call TaskSched_SignalEvent
	or xiz, xiz
	jr nz, DisplayCmd_ScanQueue_Match
	lds wa, 5
	lds bc, 2
	call TaskSched_ChangePriority

DisplayCmd_ScanQueue_Match:
	or xiz, xiz
	jr z, DisplayCmd_ScanQueue
	ld xhl, xiz
	pop xiz
	inc 4, xsp
	ret

DisplayCmd_ScanQueue_MatchDone:
	ret

DisplayCmd_ScanQueue_Continue:
	lda_24 xde, (0x03247c)
	ldw (xde - 10), 0x0
	ldw (xde - 8), 0x0
	ldw (xde - 4), 0x0
	ldw (xde - 6), 0x0
	ldw (xde - 2), 0x7f
	lda_24 xwa, (0x030466)
	stl_da (0x032466), xwa
	stl_da (0x03246a), xwa
	ret

DisplayCmd_Execute:
	lda_24 xde, (0x03247c)
	ld ix, (xde - 8)
	cp ix, (xde - 4)
	jr nz, DisplayCmd_Execute_Type1
	lds32 xhl, 0
	ret

DisplayCmd_Execute_Type1:
	ld_sril3 XHL, 0x07, 0xe8, 0xf0
	minc4_16 ix, 0x7c
	ld (xde - 8), ix
	incm 4, (xde - 2)
	ret

DisplayCmd_Execute_Type2:
	lda_24 xde, (0x03247c)
	cpw (xde - 2), 0x4
	jr gt, DisplayCmd_Execute_Type3
	lda_dd8l XHL, (0x00)
	ret

DisplayCmd_Execute_Type3:
	ld ix, (xde - 4)
	stl_dri XWA, 0x07, 0xe8, 0xf0
	minc4_16 ix, 0x7c
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

DisplayCmd_Return:
	ldw_da xix, (0x032474)
	stw_da (0x032472), xix
	ret

DrawQueue_Alloc_Prologue:
	lda_24 xde, (0x03247c)
	ld ix, (xde - 10)
	cp ix, (xde - 4)
	jr nz, DrawQueue_Alloc_FindSlot
	lds32 xhl, 0
	ret

DrawQueue_Alloc_FindSlot:
	ld_sril3 XHL, 0x07, 0xe8, 0xf0
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
	lds wa, 4
	call Audio_Lock_Acquire
	ld de, iz
	extz xde
	lda_24 xhl, (0x030466)
	ldl_da xbc, (0x03246a)
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xde
	ld de, iz
	extz xde
	cp xwa, 0x2000
	jr ge, DrawFunc_Prologue
	ld xiz, xbc
	add xbc, xde
	stl_da (0x03246a), xbc
	jr DrawFunc_CallHandler

DrawFunc_Prologue:
	ld xiz, xhl
	add xhl, xde
	stl_da (0x03246a), xhl

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
	jr z, DrawFunc_CheckStack
	push xiz
	ld xhl, xiz
	call (xhl)
	pop xiz
	jr DrawFunc_StackSetup

DrawFunc_CheckStack:
	lds wa, 3
	call TaskSched_WaitForEvent
	calr DisplayCmd_Return
	jr DrawFunc_DispatchDone

DrawFunc_Dispatch:
	lda xbc, (xhl + 4)
	cp xiz, (xbc)
	jr nz, DrawFunc_DispatchDone
	lds32 xwa, 0
	ld (xbc), xwa

DrawFunc_DispatchDone:
	calr DrawQueue_Alloc_Prologue
	or xhl, xhl
	jr nz, DrawFunc_Dispatch
	lds wa, 3
	call TaskSched_SignalEvent
	ldw wa, 0x8
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (DrawFunc_StackHandler)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DisplayCmd_DequeueAndExecute

DrawFunc_StackSetup:
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
	lda_24 xbc, (DrawFunc_StackHandler)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr DisplayCmd_DequeueAndExecute

DrawFunc_XspCheck_Prologue:
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
	cp xsp, 0x1c032
	jr lt, DrawFunc_XspCheck_Loop
	cp xsp, 0x1d032
	jr gt, DrawFunc_XspCheck_Loop
	inc 1, xhl

DrawFunc_XspCheck_Loop:
	ret

InitializeGraphics:
	.byte 0xef, 0x68, 0x3e, 0x1e, 0xf8, 0xfd, 0xd8, 0xad
	.byte 0x1d, 0x72, 0x1b, 0xef, 0xf2, 0x92, 0xef, 0x03
	.byte 0x02, 0x01, 0x00, 0x1d, 0x6c, 0x24, 0xfb, 0xd8
	.byte 0xa8, 0x1e, 0xa8, 0x4c, 0xd8, 0xaa, 0x1e, 0x5f
	.byte 0x4d, 0xd8, 0xa8, 0x1e, 0xee, 0x4c, 0xf2, 0x00
	.byte 0x3c, 0x04, 0x30, 0xe8, 0x8e, 0x0b, 0x00, 0x96
	.byte 0x0b, 0x00, 0x00, 0x38, 0x1d, 0x1d, 0x08, 0xff
	.byte 0xee, 0xc8, 0x00, 0x96, 0x00, 0x00, 0x0b, 0x00
	.byte 0x96, 0x0b, 0x00, 0x00, 0x3e, 0x1d, 0x1d, 0x08
	.byte 0xff, 0xbf, 0x10, 0x37, 0xbf, 0x04, 0x30, 0xb8
	.byte 0x02, 0x02, 0x00, 0x00, 0xb0, 0x02, 0x00, 0x00
	.byte 0xb8, 0x04, 0x02, 0x3f, 0x01, 0xb8, 0x06, 0x02
	.byte 0xef, 0x00, 0x1e, 0xb6, 0x01, 0x1e, 0x6e, 0x00
	.byte 0x1e, 0x04, 0x00, 0x5e, 0xef, 0x60, 0x0e
LcdOn:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, InitGraphics_SetupVRAM_Loop
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (InitGraphics_SetupVRAM)
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute

InitGraphics_SetupVRAM:
	jr InitGraphics_SetupVRAM_Loop

InitGraphics_SetupVRAM_Loop:
	stiw_da (0x030464), 0x0001
	jp VGA_ScreenUnblank

; LcdOff - Disable LCD display output (clears flag at 0x030464)
LcdOff:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, LcdOn_Return
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (LcdOn_Done)
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute

LcdOn_Done:
	jr LcdOn_Return

LcdOn_Return:
	call VGA_ScreenBlank
	stiw_da (0x030464), 0x0000
	ret


LcdOff_Done:
	cpw_da (0x030464), 0
	ret z

	call VGA_ScreenUnblank
	ret


LcdOff_Return:
	cpw_da (0x030464), 0
	ret z

	call VGA_ScreenBlank
	ret
LcdOff_Epilogue:


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
	cps hl, 0
	jr z, UpdateScreen_Prologue
	calr Gfx_BlitDirtyRegions
	ldw_da xwa, (0x030450)
	cps wa, 0
	ret nz
	stw_da (0x03044e), xwa
	ret

UpdateScreen_Prologue:
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (UpdateScreen_CheckDirty)
	ld (xwa), xbc
	calr DisplayCmd_DequeueAndExecute
	ret

UpdateScreen_CheckDirty:
	.byte 0x1e, 0x0f, 0x00, 0xd2, 0x50, 0x04, 0x03, 0x20
	.byte 0xd8, 0xd8, 0xb0, 0xfe, 0xf2, 0x4e, 0x04, 0x03
	.byte 0x50, 0x0e

Gfx_BlitDirtyRegions:
	dec 8, xsp
	pushw iz
	cpw_da (0x03ef92), 0
	jrl z, SetChangeRect_Prologue
	cpw_da (0x03045e), 0
	jrl z, SetChangeRect_Prologue
	cpw_da (0x030460), 0
	jr z, Gfx_BlitDirty_ScanMatch
	ldw_da xwa, (0x03ef9e)
	cps wa, 4
	jr nz, Gfx_BlitDirty_Prologue
	cpw_da (0x03efa0), 4
	jr z, Display_CheckScreenDimensions
	cps wa, 4
	jr nz, Display_CheckScreenDimensions

Gfx_BlitDirty_Prologue:
	calr LcdOn_Return
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	lds iz, 0

Gfx_BlitDirty_ScanLoop:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	stb_erp A, 0xf8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0x100
	jr c, Gfx_BlitDirty_ScanLoop
	jr Display_CheckScreenDimensions

Gfx_BlitDirty_ScanMatch:
	cpw_da (0x030462), 0
	jr z, Display_CheckScreenDimensions
	lda xwa, (xsp + 6)
	ld (xsp + 2), xwa
	ldw iz, 0xe0

Gfx_BlitDirty_ScanDone:
	ld wa, iz
	call Table_LookupDword
	ld (xsp + 6), xhl
	stb_erp A, 0xf8
	extz wa
	ld xbc, (xsp + 2)
	call VGA_WritePaletteEntry
	inc 1, iz
	cp iz, 0xf0
	jr c, Gfx_BlitDirty_ScanDone

Display_CheckScreenDimensions:
	lda_24 xwa, (0x030456)
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
	cpw_da (0x030460), 0
	jr z, Display_CheckDim_CheckHeight
	calr InitGraphics_SetupVRAM_Loop
	ldw_da xwa, (0x03ef9e)
	stw_da (0x03efa0), xwa
	stiw_da (0x030460), 0x0000
	jr Display_CheckDim_Done

Display_CheckDim_CheckHeight:
	cpw_da (0x030462), 0
	jr z, Display_CheckDim_Return

Display_CheckDim_Done:
	stiw_da (0x030462), 0x0000

Display_CheckDim_Return:
	stiw_da (0x03045e), 0x0000
	lda_24 xwa, (0x030456)
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
	cpw_da (0x03ef4e), 0
	jr z, SetChangeRect_ClampLeft
	lds wa, 5
	lds bc, 3
	call TaskSched_ChangePriority

SetChangeRect_ClampLeft:
	stiw_da (0x03045e), 0x0001
	lda_24 xde, (0x030456)
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
	cps hl, 0
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
	lds hl, 0

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
	cps hl, 0
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
	addda32_24 xbc, (0x030452)
	ld a, (xbc)
	ldb_erp A, 0xf8
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
	stb_erp A, 0xf8
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
	cp iz, 0xf7
	jrl z, DrawLine_Epilogue
	cp iz, 0xf5
	jr nz, ModifyPixel_Prologue
	ld xwa, (xsp + 4)
	ld bc, (xwa + 2)
	muls bc, 0x140
	add bc, (xwa)
	extz xbc
	addda32_24 xbc, (0x030452)
	ld a, (xbc)
	ldb_erp A, 0xf8
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
	stb_erp C, 0xf8
	cpw (xsp + 2), 0x205
	jrl z, ModifyPixelEx_Prologue
	lda_24 xde, (0x043c00)
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
