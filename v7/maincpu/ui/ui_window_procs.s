; =============================================================================
; UI Window Procedures (8K lines)
; =============================================================================
;
; Window procedure handlers for all standard widget types:
; ModeEdit, TitleEdit, StringBox, Label, Bitmap, Icon, Line,
; Frame, EditSw, TextBox, VwBox, ListBox, RadioBox, TempoBox,
; GridBox. The core UI rendering and event dispatch layer.
; =============================================================================

	lda_24 xde, (0x0274b0)
	ldl_da xhl, (0x0274e4)
	lds32 xbc, 0

WndScroll_CopyLoop:
	ld xwa, xbc
	ld xix, xde
	add xix, xwa
	ld a, (xhl)
	ld (xix), a
	inc 1, iz
	inc 1, xbc
	cpda16_24 xiz, (0x0274d6)
	jr c, WndScroll_CopyLoop

WndScroll_InitBuffer:
	ld wa, iz
	extz xwa
	lda_24 xde, (0x0274b0)
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	ldl_da xwa, (0x0274d2)
	ld xbc, 0x1e0003a
	call ApFuncCall

WndScroll_InitWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 50)
	ld xbc, 0x1c00017
	lds32 xde, 5
	calr SetDialUp
	ld xwa, (xsp + 50)
	ld xbc, 0x1c00018
	lds32 xde, 3
	calr SetDialDown
	lds wa, 1
	calr SetDialEnable
	jrl UIDialog_ReturnZeroJmp

WndScroll_InitSelectionTrack:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	stiw_da (0x0274dc), 0xffff
	stiw_da (0x0274e0), 0xffff
	ldw_da xde, (0x0274d8)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1e00080
	jrl WndScroll_SendAndReturn

WndScroll_BasicWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleSelectionChange:
	.byte 0xf2, 0xde, 0x74, 0x02, 0x52, 0xd2, 0xe0, 0x74
	.byte 0x02, 0xfa, 0x76, 0xf9, 0x0a, 0xaf, 0x32, 0x20
	.byte 0x1e, 0xbb, 0xdf, 0xd2, 0xda, 0x74, 0x02, 0x20
	.byte 0xe8, 0x12, 0xe8, 0xee, 0x02, 0x41, 0xd2, 0x9e
	.byte 0xea, 0x00, 0xe8, 0x81, 0xa1, 0x20, 0xbf, 0x04
	.byte 0x60, 0xd2, 0xe0, 0x74, 0x02, 0x20, 0xd8, 0xcf
	.byte 0xff, 0xff, 0x66, 0x7b, 0xe8, 0x12, 0xe8, 0xee
	.byte 0x02, 0xaf, 0x04, 0x80, 0xbf, 0x0c, 0x31, 0xa0
	.byte 0x20, 0x1d, 0x33, 0x22, 0xfb, 0xd2, 0xe0, 0x74
	.byte 0x02, 0x20, 0xe8, 0x12, 0xd8, 0x0a, 0x0d, 0x00
	.byte 0xd8, 0x08, 0x18, 0x00, 0xd8, 0x8a, 0xbf, 0x22
	.byte 0x31, 0x99, 0x02, 0x20, 0xd8, 0xc8, 0x0a, 0x00
	.byte 0xda, 0x80, 0xbf, 0x1a, 0x32, 0xba, 0x02, 0x50
	.byte 0xd2, 0xe0, 0x74, 0x02, 0x20, 0xe8, 0x12, 0xd8
	.byte 0x0a, 0x0d, 0x00, 0xd7, 0xe2, 0x8b, 0xdb, 0xee
	.byte 0x04, 0x91, 0x20, 0xd8, 0xc8, 0x0e, 0x00, 0xdb
	.byte 0x80, 0xd8, 0x69, 0xb2, 0x50, 0xbf, 0x0c, 0x30
	.byte 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x64, 0xdb
	.byte 0xee, 0x03, 0xbf, 0x1a, 0x30, 0x90, 0x21, 0xdb
	.byte 0x81, 0xd9, 0x62, 0xb8, 0x04, 0x51, 0x98, 0x02
	.byte 0x21, 0xd9, 0xc8, 0x11, 0x00, 0xb8, 0x06, 0x51
	.byte 0x31, 0xf5, 0x00, 0x1d, 0xd1, 0xaf, 0xfa
WndScroll_DrawCurrentItem:
	.byte 0xd2, 0xde, 0x74, 0x02, 0x20, 0xe8, 0x12, 0xe8
	.byte 0xee, 0x02, 0xaf, 0x04, 0x80, 0xbf, 0x0c, 0x31
	.byte 0xa0, 0x20, 0x1d, 0x33, 0x22, 0xfb, 0xd2, 0xde
	.byte 0x74, 0x02, 0x20, 0xe8, 0x12, 0xd8, 0x0a, 0x0d
	.byte 0x00, 0xd8, 0x08, 0x18, 0x00, 0xd8, 0x8a, 0xbf
	.byte 0x22, 0x31, 0x99, 0x02, 0x20, 0xd8, 0xc8, 0x0a
	.byte 0x00, 0xda, 0x80, 0xbf, 0x1a, 0x32, 0xba, 0x02
	.byte 0x50, 0xd2, 0xde, 0x74, 0x02, 0x20, 0xe8, 0x12
	.byte 0xd8, 0x0a, 0x0d, 0x00, 0xd7, 0xe2, 0x8b, 0xdb
	.byte 0xee, 0x04, 0x91, 0x20, 0xd8, 0xc8, 0x0e, 0x00
	.byte 0xdb, 0x80, 0xd8, 0x69, 0xb2, 0x50, 0xbf, 0x0c
	.byte 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x64
	.byte 0xdb, 0xee, 0x03, 0xbf, 0x1a, 0x30, 0x90, 0x21
	.byte 0xdb, 0x81, 0xd9, 0x62, 0xb8, 0x04, 0x51, 0x98
	.byte 0x02, 0x21, 0xd9, 0xc8, 0x11, 0x00, 0xb8, 0x06
	.byte 0x51, 0x31, 0xf2, 0x00, 0x1d, 0xd1, 0xaf, 0xfa
	.byte 0xd2, 0xde, 0x74, 0x02, 0x20, 0xf2, 0xe0, 0x74
	.byte 0x02, 0x50, 0x78, 0xca, 0x09
WndScroll_RepaintAll:
	ldw_da xwa, (0x0274dc)
	cpda16_24 xwa, (0x0274da)
	jrl z, UIDialog_ReturnZeroJmp
	stiw_da (0x0274e0), 0xffff
	ld xwa, (xsp + 50)
	calr GetClientBox
	lda xwa, (xsp + 34)
	ldw bc, 0xf5
	call DrawBox
	ldw_da xwa, (0x0274da)
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	lds iz, 0
	jr WndScroll_ItemCountCheck

WndScroll_DrawSingleItem:
	ld wa, iz
	extz xwa
	div wa, 0xd
	stw_erp DE, 0xe2
	sll de, 4
	lda xwa, (xsp + 34)
	ld hl, (xwa)
	add hl, 0xe
	add hl, de
	lda xbc, (xsp + 22)
	ld (xbc), hl
	ld de, iz
	extz xde
	div de, 0xd
	mul de, 0x18
	ld hl, de
	ld de, (xwa + 2)
	add de, 0xa
	add de, hl
	ld (xbc + 2), de
	ld hl, iz
	extz xhl
	sll xhl, 2
	add xhl, (xsp + 4)
	lds32 xde, 0
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, (xhl)
	call DrawString
	inc 1, iz

WndScroll_ItemCountCheck:
	ldw_da xbc, (0x0274e2)
	mul bc, 0x3
	ldw_da xwa, (0x0274da)
	add bc, wa
	extz xbc
	add xbc, xbc
	ld xde, Data_SoundEditorCharsLayout_0xC
	add xde, xbc
	cp iz, (xde)
	jr ule, WndScroll_DrawSingleItem
	stw_da (0x0274dc), xwa
	jrl UIDialog_ReturnZeroJmp

WndEvt_DispatchByEventCode:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	ldl_da xbc, (0x0274e4)
	dec 1, xwa
	cp xwa, 0x0
	jrl c, UIDialog_ReturnZeroJmp
	cp xwa, 0x8
	jrl ugt, UIDialog_ReturnZeroJmp
	add xwa, xwa
	add xwa, Data_SoundEditorCharsLayout_0x24
	ld wa, (xwa)
	lda_24 xix, (WndEvt_EventCodeDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; Window event dispatch by event code
WndEvt_EventCodeDispatch:
	.byte 0xd2, 0xd8, 0x74, 0x02, 0x20, 0xd8, 0xd8, 0x76
	.byte 0xcc, 0x08, 0xd8, 0x69, 0xf2, 0xd8, 0x74, 0x02
	.byte 0x50, 0xd8, 0x8a, 0xea, 0x12, 0xaf, 0x32, 0x20
	.byte 0x41, 0x80, 0x00, 0xe0, 0x01, 0x1d, 0x53, 0x92
	.byte 0xfa, 0xaf, 0x32, 0x20, 0xaf, 0x2e, 0x21, 0xaf
	.byte 0x2a, 0x22, 0x78, 0x36, 0x03, 0xd2, 0xd8, 0x74
	.byte 0x02, 0x20, 0xd8, 0x89, 0xd9, 0x61, 0xd2, 0xd6
	.byte 0x74, 0x02, 0xf1, 0x7f, 0x98, 0x08, 0xd8, 0x61
	.byte 0xf2, 0xd8, 0x74, 0x02, 0x50, 0xd8, 0x8a, 0xea
	.byte 0x12, 0xaf, 0x32, 0x20, 0x41, 0x80, 0x00, 0xe0
	.byte 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xaf, 0x32, 0x20
	.byte 0xaf, 0x2e, 0x21, 0xaf, 0x2a, 0x22, 0x78, 0x02
	.byte 0x03, 0xd2, 0xde, 0x74, 0x02, 0x21, 0xd9, 0xd8
	.byte 0x76, 0x6b, 0x08, 0xd2, 0xda, 0x74, 0x02, 0x20
	.byte 0xe8, 0x12, 0xe8, 0xee, 0x02, 0x42, 0xd2, 0x9e
	.byte 0xea, 0x00, 0xe8, 0x82, 0xa2, 0x20, 0xbf, 0x04
	.byte 0x60, 0xd9, 0x69, 0xf2, 0xde, 0x74, 0x02, 0x51
	.byte 0xe9, 0x12, 0xe9, 0xee, 0x02, 0xe9, 0x88, 0xaf
	.byte 0x04, 0x80, 0xbf, 0x0c, 0x31, 0xa0, 0x20, 0x1d
	.byte 0x33, 0x22, 0xfb, 0xd2, 0xd8, 0x74, 0x02, 0x20
	.byte 0xe8, 0x12, 0xf2, 0xb0, 0x74, 0x02, 0x32, 0xea
	.byte 0x89, 0xe8, 0x81, 0x8f, 0x0c, 0x21, 0xb1, 0x41
	.byte 0x40, 0x16, 0x00, 0x00, 0x00, 0x41, 0x0f, 0x00
	.byte 0xc0, 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xd2, 0xde
	.byte 0x74, 0x02, 0x22, 0xea, 0x12, 0xaf, 0x32, 0x20
	.byte 0x41, 0x0e, 0x00, 0xc0, 0x01, 0x1d, 0x53, 0x92
	.byte 0xfa, 0xaf, 0x32, 0x20, 0xaf, 0x2e, 0x21, 0xaf
	.byte 0x2a, 0x22, 0x78, 0x86, 0x02, 0xf2, 0xd2, 0x9e
	.byte 0xea, 0x32, 0xbf, 0x0c, 0x30, 0xbf, 0x08, 0x60
	.byte 0xaf, 0x2e, 0x20, 0xe8, 0xcf, 0x18, 0x00, 0xc0
	.byte 0x01, 0x76, 0x93, 0x00, 0xe8, 0xcf, 0x1a, 0x00
	.byte 0xc0, 0x01, 0x76, 0x8a, 0x00, 0xe8, 0xcf, 0x17
	.byte 0x00, 0xc0, 0x01, 0x66, 0x09, 0xe8, 0xcf, 0x19
	.byte 0x00, 0xc0, 0x01, 0x7e, 0xc8, 0x07, 0xd2, 0xde
	.byte 0x74, 0x02, 0x21, 0xd9, 0xcf, 0x0d, 0x00, 0x77
	.byte 0xbc, 0x07, 0xd9, 0xca, 0x0d, 0x00, 0xf2, 0xde
	.byte 0x74, 0x02, 0x51, 0xd2, 0xda, 0x74, 0x02, 0x20
	.byte 0xe8, 0x12, 0xe8, 0xee, 0x02, 0xe8, 0x82, 0xa2
	.byte 0x20, 0xbf, 0x04, 0x60, 0xe9, 0x12, 0xe9, 0xee
	.byte 0x02, 0xaf, 0x04, 0x81, 0xa1, 0x20, 0xaf, 0x08
	.byte 0x21, 0x1d, 0x33, 0x22, 0xfb, 0xd2, 0xd8, 0x74
	.byte 0x02, 0x20, 0xe8, 0x12, 0xf2, 0xb0, 0x74, 0x02
	.byte 0x32, 0xea, 0x89, 0xe8, 0x81, 0x8f, 0x0c, 0x21
	.byte 0xb1, 0x41, 0x40, 0x16, 0x00, 0x00, 0x00, 0x41
	.byte 0x0f, 0x00, 0xc0, 0x01, 0x1d, 0x53, 0x92, 0xfa
	.byte 0xd2, 0xde, 0x74, 0x02, 0x22, 0xea, 0x12, 0xaf
	.byte 0x32, 0x20, 0x41, 0x0e, 0x00, 0xc0, 0x01, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xaf, 0x32, 0x20, 0xaf, 0x2e
	.byte 0x21, 0xaf, 0x2a, 0x22, 0x78, 0xdc, 0x01, 0xd2
	.byte 0xda, 0x74, 0x02, 0x20, 0xe8, 0x12, 0xe8, 0xee
	.byte 0x02, 0xe8, 0x82, 0xa2, 0x20, 0xbf, 0x04, 0x60
	.byte 0xd2, 0xde, 0x74, 0x02, 0x20, 0xe8, 0x12, 0xe8
	.byte 0xee, 0x02, 0xaf, 0x04, 0x80, 0xa0, 0x20, 0xaf
	.byte 0x08, 0x21, 0x1d, 0x33, 0x22, 0xfb, 0xd2, 0xe2
	.byte 0x74, 0x02, 0x20, 0xd8, 0x08, 0x03, 0x00, 0xd2
	.byte 0xda, 0x74, 0x02, 0x80, 0xe8, 0x12, 0xe8, 0x80
	.byte 0xf2, 0xde, 0x9e, 0xea, 0x32, 0xea, 0x89, 0xe8
	.byte 0x81, 0xd2, 0xde, 0x74, 0x02, 0x20, 0xd8, 0x8b
	.byte 0xdb, 0xc8, 0x0c, 0x00, 0x91, 0xf3, 0x6b, 0x14
	.byte 0x8f, 0x0c, 0x23, 0xcb, 0xcf, 0x5a, 0x66, 0x05
	.byte 0xcb, 0xcf, 0x7a, 0x6e, 0x07, 0xd8, 0x69, 0xf2
	.byte 0xde, 0x74, 0x02, 0x50, 0xd2, 0xe2, 0x74, 0x02
	.byte 0x21, 0xd9, 0x08, 0x03, 0x00, 0xd2, 0xda, 0x74
	.byte 0x02, 0x20, 0xd8, 0x81, 0xe9, 0x12, 0xe9, 0x81
	.byte 0xe9, 0x82, 0xd2, 0xde, 0x74, 0x02, 0x20, 0xd8
	.byte 0x89, 0xd9, 0xc8, 0x0d, 0x00, 0x92, 0xf1, 0x7b
	.byte 0xc4, 0x06, 0xd8, 0x89, 0xd9, 0xc8, 0x0d, 0x00
	.byte 0xf2, 0xde, 0x74, 0x02, 0x51, 0xd2, 0xda, 0x74
	.byte 0x02, 0x20, 0xe8, 0x12, 0xe8, 0xee, 0x02, 0x42
	.byte 0xd2, 0x9e, 0xea, 0x00, 0xe8, 0x82, 0xa2, 0x20
	.byte 0xbf, 0x04, 0x60, 0xe9, 0x12, 0xe9, 0xee, 0x02
	.byte 0xe9, 0x88, 0xaf, 0x04, 0x80, 0xbf, 0x0c, 0x31
	.byte 0xa0, 0x20, 0x1d, 0x33, 0x22, 0xfb, 0xbf, 0x0c
	.byte 0x32, 0x82, 0x23, 0xf2, 0xb0, 0x74, 0x02, 0x30
	.byte 0xcb, 0xcf, 0x53, 0x6e, 0x1c, 0x8a, 0x01, 0x3f
	.byte 0x50, 0x6e, 0x16, 0xd2, 0xd8, 0x74, 0x02, 0x21
	.byte 0xe9, 0x12, 0xe8, 0x8a, 0xe9, 0x82, 0xe2, 0xe4
	.byte 0x74, 0x02, 0x20, 0x80, 0x21, 0xb2, 0x41, 0x68
	.byte 0x0b, 0xd2, 0xd8, 0x74, 0x02, 0x22, 0xea, 0x12
	.byte 0xea, 0x80, 0xb0, 0x43, 0x40, 0x16, 0x00, 0x00
	.byte 0x00, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0xb0
	.byte 0x74, 0x02, 0x00, 0x1d, 0x53, 0x92, 0xfa, 0xd2
	.byte 0xde, 0x74, 0x02, 0x22, 0xea, 0x12, 0xaf, 0x32
	.byte 0x20, 0x41, 0x0e, 0x00, 0xc0, 0x01, 0x1d, 0x53
	.byte 0x92, 0xfa, 0xaf, 0x32, 0x20, 0xaf, 0x2e, 0x21
	.byte 0xaf, 0x2a, 0x22, 0x78, 0xb5, 0x00, 0xd2, 0xda
	.byte 0x74, 0x02, 0x21, 0xd9, 0x88, 0xe8, 0x12, 0xe8
	.byte 0xee, 0x02, 0x42, 0xd2, 0x9e, 0xea, 0x00, 0xe8
	.byte 0x82, 0xa2, 0x20, 0xbf, 0x04, 0x60, 0xd2, 0xe2
	.byte 0x74, 0x02, 0x20, 0xd8, 0x08, 0x03, 0x00, 0xd9
	.byte 0x80, 0xe8, 0x12, 0xe8, 0x80, 0x41, 0xde, 0x9e
	.byte 0xea, 0x00, 0xe8, 0x81, 0xd2, 0xde, 0x74, 0x02
	.byte 0x20, 0xd8, 0x8a, 0xda, 0x61, 0x91, 0xf2, 0x7b
	.byte 0xec, 0x05, 0xd8, 0x61, 0xf2, 0xde, 0x74, 0x02
	.byte 0x50, 0xe8, 0x12, 0xe8, 0xee, 0x02, 0xaf, 0x04
	.byte 0x80, 0xbf, 0x0c, 0x31, 0xa0, 0x20, 0x1d, 0x33
	.byte 0x22, 0xfb, 0xbf, 0x0c, 0x32, 0x82, 0x23, 0xd2
	.byte 0xd8, 0x74, 0x02, 0x20, 0xe8, 0x12, 0xcb, 0xcf
	.byte 0x53, 0x6e, 0x18, 0x8a, 0x01, 0x3f, 0x50, 0x6e
	.byte 0x12, 0x41, 0xb0, 0x74, 0x02, 0x00, 0xe8, 0x81
	.byte 0xe2, 0xe4, 0x74, 0x02, 0x20, 0x80, 0x21, 0xb1
	.byte 0x41, 0x68, 0x09, 0x42, 0xb0, 0x74, 0x02, 0x00
	.byte 0xe8, 0x82, 0xb2, 0x43, 0x40, 0x16, 0x00, 0x00
	.byte 0x00, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0xb0
	.byte 0x74, 0x02, 0x00, 0x1d, 0x53, 0x92, 0xfa, 0xd2
	.byte 0xde, 0x74, 0x02, 0x22, 0xea, 0x12, 0xaf, 0x32
	.byte 0x20, 0x41, 0x0e, 0x00, 0xc0, 0x01, 0x1d, 0x53
	.byte 0x92, 0xfa, 0xaf, 0x32, 0x20, 0xaf, 0x2e, 0x21
	.byte 0xaf, 0x2a, 0x22, 0x1e, 0x18, 0xea, 0x78, 0x6d
	.byte 0x05, 0xd2, 0xd6, 0x74, 0x02, 0x26, 0xde, 0x69
	.byte 0xd2, 0xd8, 0x74, 0x02, 0xf6, 0x63, 0x2f, 0xf2
	.byte 0xb0, 0x74, 0x02, 0x32, 0xde, 0x89, 0xe9, 0x12
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0xe8, 0x81, 0xe9
	.byte 0x8b, 0xe8, 0xa9, 0xe8, 0x83, 0xea, 0x8c, 0xeb
	.byte 0x84, 0xe9, 0x88, 0xea, 0x8b, 0xe8, 0x83, 0x83
	.byte 0x21, 0xb4, 0x41, 0xde, 0x69, 0xe9, 0x69, 0xd2
	.byte 0xd8, 0x74, 0x02, 0xf6, 0x6b, 0xe1, 0xd2, 0xd8
	.byte 0x74, 0x02, 0x20, 0xe8, 0x12, 0xf2, 0xb0, 0x74
	.byte 0x02, 0x32, 0xea, 0x89, 0xe8, 0x81, 0xe2, 0xe4
	.byte 0x74, 0x02, 0x20, 0x80, 0x21, 0xb1, 0x41, 0x40
	.byte 0x16, 0x00, 0x00, 0x00, 0x41, 0x0f, 0x00, 0xc0
	.byte 0x01, 0x1d, 0x53, 0x92, 0xfa, 0xd2, 0xd8, 0x74
	.byte 0x02, 0x22, 0xea, 0x12, 0xaf, 0x32, 0x20, 0x41
	.byte 0x80, 0x00, 0xe0, 0x01, 0x78, 0xf3, 0x04, 0xd2
	.byte 0xd8, 0x74, 0x02, 0x26, 0xd2, 0xd6, 0x74, 0x02
	.byte 0xf6, 0x6f, 0x2f, 0xf2, 0xb0, 0x74, 0x02, 0x32
	.byte 0xde, 0x89, 0xe9, 0x12, 0xe8, 0xa9, 0xe8, 0x81
	.byte 0xe9, 0x8b, 0x40, 0xff, 0xff, 0xff, 0xff, 0xe8
	.byte 0x83, 0xea, 0x8c, 0xeb, 0x84, 0xe9, 0x88, 0xea
	.byte 0x8b, 0xe8, 0x83, 0x83, 0x21, 0xb4, 0x41, 0xde
	.byte 0x61, 0xe9, 0x61, 0xd2, 0xd6, 0x74, 0x02, 0xf6
	.byte 0x67, 0xde, 0xd2, 0xd6, 0x74, 0x02, 0x20, 0xd8
	.byte 0x69, 0xe8, 0x12, 0xf2, 0xb0, 0x74, 0x02, 0x32
	.byte 0xea, 0x89, 0xe8, 0x81, 0xe2, 0xe4, 0x74, 0x02
	.byte 0x20, 0x80, 0x21, 0xb1, 0x41, 0x40, 0x16, 0x00
	.byte 0x00, 0x00, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x1d
	.byte 0x53, 0x92, 0xfa, 0xd2, 0xd8, 0x74, 0x02, 0x22
	.byte 0xea, 0x12, 0xaf, 0x32, 0x20, 0x41, 0x80, 0x00
	.byte 0xe0, 0x01, 0x78, 0x7d, 0x04, 0xd7, 0xfa, 0xa8
	.byte 0xde, 0xa8, 0xd2, 0xd6, 0x74, 0x02, 0x22, 0xda
	.byte 0xd8, 0x63, 0x1c, 0xf2, 0xb0, 0x74, 0x02, 0x33
	.byte 0x81, 0x21, 0xde, 0x89, 0xe9, 0x12, 0xeb, 0x8c
	.byte 0xe9, 0x84, 0x84, 0xf1, 0x6e, 0x09, 0xd7, 0xfa
	.byte 0x61, 0xde, 0x61, 0xda, 0xf6, 0x67, 0xeb, 0xd7
	.byte 0xfa, 0x88, 0xda, 0xf0, 0x76, 0x4f, 0x04, 0xbf
	.byte 0x04, 0x02, 0x00, 0x00, 0xde, 0xa8, 0xda, 0xd8
	.byte 0x63, 0x25, 0xf2, 0xb0, 0x74, 0x02, 0x31, 0xe2
	.byte 0xe4, 0x74, 0x02, 0x20, 0x80, 0x21, 0xda, 0x8b
	.byte 0xde, 0xa3, 0xdb, 0x69, 0xeb, 0x12, 0xe9, 0x8c
	.byte 0xeb, 0x84, 0x84, 0xf1, 0x6e, 0x09, 0x9f, 0x04
	.byte 0x61, 0xde, 0x61, 0xda, 0xf6, 0x67, 0xe7, 0xd7
	.byte 0xfa, 0x88, 0xbf, 0x06, 0x50, 0x9f, 0x04, 0x20
	.byte 0x9f, 0x06, 0x88, 0x9f, 0x06, 0x7f, 0xda, 0x61
	.byte 0x2a, 0x1d, 0xa3, 0x06, 0xff, 0xbf, 0x0a, 0x63
	.byte 0xd7, 0xfa, 0x88, 0xe8, 0x12, 0x41, 0xb0, 0x74
	.byte 0x02, 0x00, 0xe8, 0x81, 0x39, 0xaf, 0x0e, 0x20
	.byte 0x38, 0x1d, 0x70, 0x07, 0xff, 0xd2, 0xd6, 0x74
	.byte 0x02, 0x20, 0xd7, 0xfa, 0xa0, 0x9f, 0x0e, 0xa0
	.byte 0xe8, 0x12, 0xaf, 0x12, 0x80, 0xb0, 0x00, 0x00
	.byte 0xaf, 0x12, 0x20, 0x38, 0x9f, 0x14, 0x20, 0xe8
	.byte 0x12, 0x41, 0xb0, 0x74, 0x02, 0x00, 0xe8, 0x81
	.byte 0x39, 0x1d, 0x70, 0x07, 0xff, 0xaf, 0x1a, 0x20
	.byte 0x38, 0x1d, 0x15, 0x03, 0xff, 0xbf, 0x16, 0x37
	.byte 0xde, 0xa8, 0x9f, 0x06, 0x3f, 0x00, 0x00, 0x63
	.byte 0x1f, 0xf2, 0xb0, 0x74, 0x02, 0x32, 0xe2, 0xe4
	.byte 0x74, 0x02, 0x23, 0xe9, 0xa8, 0xe9, 0x88, 0xea
	.byte 0x8c, 0xe8, 0x84, 0x83, 0x21, 0xb4, 0x41, 0xde
	.byte 0x61, 0xe9, 0x61, 0x9f, 0x06, 0xf6, 0x67, 0xed
	.byte 0xd7, 0xfa, 0x89, 0x9f, 0x04, 0x81, 0x9f, 0x06
	.byte 0xa1, 0xd2, 0xd6, 0x74, 0x02, 0x20, 0xd8, 0x8e
	.byte 0xd9, 0xa6, 0xd8, 0xf6, 0x6f, 0x23, 0xf2, 0xb0
	.byte 0x74, 0x02, 0x32, 0xe2, 0xe4, 0x74, 0x02, 0x23
	.byte 0xde, 0x89, 0xe9, 0x12, 0xe9, 0x88, 0xea, 0x8c
	.byte 0xe8, 0x84, 0x83, 0x21, 0xb4, 0x41, 0xde, 0x61
	.byte 0xe9, 0x61, 0xd2, 0xd6, 0x74, 0x02, 0xf6, 0x67
	.byte 0xeb, 0x40, 0x16, 0x00, 0x00, 0x00, 0x41, 0x0f
	.byte 0x00, 0xc0, 0x01, 0x42, 0xb0, 0x74, 0x02, 0x00
	.byte 0x1d, 0x53, 0x92, 0xfa, 0xd2, 0xd8, 0x74, 0x02
	.byte 0x22, 0xea, 0x12, 0xaf, 0x32, 0x20, 0x41, 0x80
	.byte 0x00, 0xe0, 0x01, 0x78, 0x34, 0x03, 0xde, 0xa8
	.byte 0xd2, 0xd6, 0x74, 0x02, 0x3f, 0x00, 0x00, 0x63
	.byte 0x1e, 0xf2, 0xb0, 0x74, 0x02, 0x32, 0xe9, 0x8b
	.byte 0xe9, 0xa8, 0xe9, 0x88, 0xea, 0x8c, 0xe8, 0x84
	.byte 0x83, 0x21, 0xb4, 0x41, 0xde, 0x61, 0xe9, 0x61
	.byte 0xd2, 0xd6, 0x74, 0x02, 0xf6, 0x67, 0xeb, 0x40
	.byte 0x16, 0x00, 0x00, 0x00, 0x41, 0x80, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x53, 0x92, 0xfa, 0x40
	.byte 0x16, 0x00, 0x00, 0x00, 0x41, 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0xb0, 0x74, 0x02, 0x00, 0x1d, 0x53
	.byte 0x92, 0xfa, 0xaf, 0x32, 0x20, 0x41, 0x80, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x78, 0xdb, 0x02
WndScroll_CopyStringAndSend:
	ld	xwa, (xsp+42)
	push	xwa
	pushw	2
	pushw	29872
	call	16713584
	inc	8, xsp
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	lds32	xde, 0
	jrl	702
WndScroll_CopyFromSource:
	pushw	2
	pushw	29872
	ld	xwa, (xsp+46)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	687
WndScroll_StoreCallerPtr:
	ld xwa, (xsp + 42)
	stl_da (0x0274d2), xwa
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleIndexChange:
	ld wa, de
	stw_da (0x0274da), xde
	cpw_da (0x0274e2), 0
	jr nz, WndScroll_SendSelectionEvents
	ld de, wa
	extz xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002a
	call SendEvent

WndScroll_SendSelectionEvents:
	ldw_da xde, (0x0274da)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1c0000f
	call SendEvent
	ldw_da xwa, (0x0274da)
	extz xwa
	sll xwa, 2
	ld xbc, DiskWarning_ConfirmStrings_0xF46
	add xbc, xwa
	ld xde, (xbc)
	ld xwa, 0x1d
	ld xbc, 0x1c0000f
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharInput:
	ld xwa, (xsp + 42)
	stw_da (0x0274d8), xwa
	ld de, wa
	extz xde
	ld xwa, 0x16
	ld xbc, 0x1e00080
	call SendEvent
	ld xwa, 0x16
	ld xbc, 0x1c0000f
	ld xde, 0x274b0
	call SendEvent
	ldw_da xbc, (0x0274d8)
	extz xbc
	lda_24 xde, (0x0274b0)
	ld xwa, xde
	add xwa, xbc
	ld a, (xwa)
	ld c, a
	extz bc
	lda_24 xhl, (CharMap_FullPermutation_0x660)
	ldb_sri C, 0x07, 0xec, 0xe4
	bit 0, c
	jr z, WndScroll_CharIsUppercase
	stiw_da (0x0274da), 0x0000
	ldb c, 0x41
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsUppercase:
	bit 1, c
	jr z, WndScroll_CharIsLowercase
	stiw_da (0x0274da), 0x0001
	ldb c, 0x61
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsLowercase:
	bit 2, c
	jr z, WndScroll_CharIsSpace
	cpw_da (0x0274da), 2
	jr nz, WndScroll_SetCategoryZero
	stiw_da (0x0274da), 0x0000

WndScroll_SetCategoryZero:
	ldb c, 0x15

WndScroll_ComputeCharOffset:
	ldw_da xwa, (0x0274d8)
	extz xwa
	add xde, xwa
	ld a, (xde)
	sub a, c
	extz wa
	stw_da (0x0274de), xwa
	jrl WndScroll_SendPageEvents

WndScroll_CharIsSpace:
	cp a, 0x20
	jr nz, WndScroll_CharIsUnderscore
	cpw_da (0x0274e2), 0
	jrl nz, WndScroll_SendPageEvents
	cpw_da (0x0274da), 2
	jr nz, WndScroll_SetSpaceOffset
	stiw_da (0x0274da), 0x0000

WndScroll_SetSpaceOffset:
	stiw_da (0x0274de), 0x0025
	jr WndScroll_SendPageEvents

WndScroll_CharIsUnderscore:
	cp a, 0x5f
	jr nz, WndScroll_SearchCharTable
	cpw_da (0x0274da), 2
	jr nz, WndScroll_SetUnderscoreOffset
	stiw_da (0x0274da), 0x0000

WndScroll_SetUnderscoreOffset:
	stiw_da (0x0274de), 0x001a
	jr WndScroll_SendPageEvents

WndScroll_SearchCharTable:
	lda_24 xwa, (DiskWarning_ConfirmStrings_0x1154)
	ld (xsp + 8), xwa
	lds iz, 0
	jr WndScroll_CheckTableEnd

WndScroll_CompareCharLoop:
	ld wa, iz
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 8)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ldw_da xwa, (0x0274d8)
	extz xwa
	ld xbc, 0x274b0
	add xbc, xwa
	ld a, (xbc)
	cp a, (xsp + 12)
	jr nz, WndScroll_CharMismatch
	stiw_da (0x0274da), 0x0002
	stw_da (0x0274de), xiz

WndScroll_CharMismatch:
	inc 1, iz

WndScroll_CheckTableEnd:
	ldw_da xwa, (0x0274e2)
	mul wa, 0x3
	inc 2, wa
	extz xwa
	add xwa, xwa
	ld xbc, Data_SoundEditorCharsLayout_0xC
	add xbc, xwa
	cp iz, (xbc)
	jr ule, WndScroll_CompareCharLoop

WndScroll_SendPageEvents:
	ldw_da xde, (0x0274da)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1e0007f
	call SendEvent
	ldw_da xde, (0x0274de)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1c0000e
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharSet:
	ldw_da xwa, (0x0274d8)
	extz xwa
	ld xbc, 0x274b0
	add xbc, xwa
	ld xwa, (xsp + 42)
	ld (xbc), a
	ldw_da xde, (0x0274d8)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1e00080
	jrl WndScroll_SendAndReturn

WndScroll_HandleDialPage:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	cps wa, 0
	jrl nz, UIDialog_ReturnZeroJmp
	ld xwa, (xsp + 42)
	ld de, wa
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1e0007f
	call SendEvent
	ldw_da xwa, (0x0274e2)
	mul wa, 0x3
	addda16_24 xwa, (0x0274da)
	ld bc, wa
	extz xbc
	add xbc, xbc
	ld xwa, Data_SoundEditorCharsLayout_0xC
	add xwa, xbc
	ld wa, (xwa)
	cpdm16_24 (0x0274de), xwa
	jr ule, WndScroll_ClampPageCount
	stw_da (0x0274de), xwa

WndScroll_ClampPageCount:
	ldw_da xwa, (0x0274da)
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ldw_da xwa, (0x0274de)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	lda xwa, (xsp + 12)
	ld e, (xwa)
	cp e, 0x53
	jr nz, WndScroll_CheckSPMarker
	cp (xwa + 1), 0x50
	jr nz, WndScroll_CheckSPMarker
	ldl_da xwa, (0x0274e4)
	lds32 xde, 0
	ld e, (xwa)
	ld xwa, (xsp + 50)
	ld xbc, 0x1e00081
	jr WndScroll_SendConfirmEvent

WndScroll_CheckSPMarker:
	ldb d, 0x0
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1e00081

WndScroll_SendConfirmEvent:
	call SendEvent
	ldw_da xde, (0x0274de)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1c0000e

WndScroll_SendAndReturn:
	call SendEvent

UIDialog_ReturnZeroJmp:
	lds32 xhl, 0
	jr WndScroll_Epilogue

WndScroll_ForwardToWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc

WndScroll_Epilogue:
	pop xiz
	lda xsp, (xsp + 50)
	ret

ModeEditProc:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XWA, 0xfd, 0x14, 0x01
	cp xbc, 0x1c00011
	jrl z, ModeEdit_HandleViewUpdate
	cp xbc, 0x1c0000d
	jr z, ModeEdit_HandlePaint
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	jrl ModeEdit_Epilogue

ModeEdit_HandlePaint:
	ld	xwa, (xsp+276)
	ld	xde, (xsp+272)
	calr	54297
	call	16402706
	ld	xwa, xhl
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	push	xhl
	call	16402706
	ld	qhl, 0
	pushw	hl
	pushw	234
	pushw	40712
	lda	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	lda	xbc, (xsp+260)
	ld	xwa, (xsp+276)
	calr	54333
	lda	xwa, (xsp+260)
	lda	xbc, (xsp+268)
	calr	54765
	lda	xwa, (xsp+260)
	lda	xbc, (xsp+268)
	lda	xde, (xsp+4)
	lds32	xhl, 0
	push	xhl
	pushw	0
	pushw	247
	call	16435871
	jrl	233
ModeEdit_HandleViewUpdate:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e00022
	ld_sril XDE, (xsp + 0x0110)
	call SendEvent
	lda xwa, (xiz + 26)
	cp xhl, 0x58
	jrl z, ModeEdit_StoreField3
	ld xwa, (xwa)
	cp xhl, 0x6c
	jrl z, ModeEdit_StoreField2
	cp xhl, 0x61
	jr z, ModeEdit_StoreField1
	cp xhl, 0x6a
	jr z, ModeEdit_StoreField0
	cp xhl, 0x60
	jrl nz, TitleEdit_ReturnZero
	ld xbc, 0x1e0002c
	lds32 xde, 0
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e0002d
	lds32 xde, 0
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e00030
	lds32 xde, 0
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e00015
	lds32 xde, 0
	call SendEvent
	ld (xiz + 40), xhl
	jr TitleEdit_ReturnZero

ModeEdit_StoreField0:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField1:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField2:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField3:
	ld xwa, (xwa)
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

TitleEdit_ReturnZero:
	lds32 xhl, 0

ModeEdit_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

TitleEditProc:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XWA, 0xfd, 0x14, 0x01
	cp xbc, 0x1c00011
	jrl z, TitleEdit_HandleViewUpdate
	cp xbc, 0x1c0000d
	jr z, TitleEdit_HandlePaint
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	jrl TitleEdit_Epilogue

TitleEdit_HandlePaint:
	ld	xwa, (xsp+276)
	ld	xde, (xsp+272)
	calr	53895
	call	16405594
	ld	xwa, xhl
	ld	xbc, 31457301
	lds32	xde, 0
	call	16421459
	push	xhl
	call	16405594
	ld	qhl, 0
	pushw	hl
	pushw	234
	pushw	40724
	lda	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	lda	xbc, (xsp+260)
	ld	xwa, (xsp+276)
	calr	53931
	lda	xwa, (xsp+260)
	lda	xbc, (xsp+268)
	calr	54363
	lda	xwa, (xsp+260)
	lda	xbc, (xsp+268)
	lda	xde, (xsp+4)
	lds32	xhl, 0
	push	xhl
	pushw	0
	pushw	247
	call	16435871
	jrl	233
TitleEdit_HandleViewUpdate:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e00022
	ld_sril XDE, (xsp + 0x0110)
	call SendEvent
	lda xwa, (xiz + 26)
	cp xhl, 0x58
	jrl z, TitleEdit_StoreFieldX
	ld xwa, (xwa)
	cp xhl, 0x6c
	jrl z, TitleEdit_StoreFieldLC
	cp xhl, 0x4e
	jr z, TitleEdit_StoreFieldNE
	cp xhl, 0x6a
	jr z, TitleEdit_StoreFieldJA
	cp xhl, 0x61
	jrl nz, StringBox_ReturnZero
	ld xbc, 0x1e00032
	lds32 xde, 0
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e00033
	lds32 xde, 0
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e00030
	lds32 xde, 0
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, 0x1e00015
	lds32 xde, 0
	call SendEvent
	ld (xiz + 40), xhl
	jr StringBox_ReturnZero

TitleEdit_StoreFieldJA:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldNE:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldLC:
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldX:
	ld xwa, (xwa)
	ld xbc, 0x1e0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

StringBox_ReturnZero:
	lds32 xhl, 0

TitleEdit_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

StringBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, StringBox_HandlePaint
	ld xwa, xiz
	calr BoxProc
	jr StringBox_Epilogue

StringBox_HandlePaint:
	ld xwa, xiz
	calr BoxProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 12)
	ld xwa, xiz
	calr GetClientBox
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 20)
	calr GetBoxCenter
	lda xde, (xsp + 12)
	lda xbc, (xsp + 20)
	ld xhl, (xsp + 8)
	ld xwa, (xhl + 30)
	push xwa
	pushm (xhl + 34)
	pushw 0xf7
	ld xwa, (xsp + 12)
	ld a, (xwa + 36)
	extz wa
	pushw wa
	ld xhl, (xhl + 26)
	ld xwa, xde
	ld xde, xhl
	call DrawStringAlignment
	lds32 xhl, 0

StringBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

LabelProc:	; SysData_F9C4B6
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, Label_HandlePaint
	ld xwa, xiz
	call ViewableProc
	jr Label_Epilogue

Label_HandlePaint:
	ld xwa, xiz
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 14)	; <-- pointer to bounding box(?), (x1, y1, x2, y2 - 16bits each)
	ld xiy, xwa
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	lda xbc, (xsp + 12)
	ld wa, (xwa)
	inc 2, wa
	ld (xbc), wa
	ld wa, (xhl + 16)	; <-- y1(?)
	inc 1, wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 4)
	ld xde, (xhl + 26)	; <-- font selection
	push xde
	pushm (xhl + 30)	; <-- foreground color
	pushw 0xf7	; <-- background color
	ld xde, (xhl + 22)	; <-- string pointer
	call DrawString
	lds32 xhl, 0

Label_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

BitmapProc:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, Bitmap_HandlePaint
	ld xwa, xiz
	call ViewableProc
	jr Bitmap_Epilogue

Bitmap_HandlePaint:
	ld xwa, xiz
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xsp + 4)
	ld bc, (xhl + 14)
	ld (xwa), bc
	ld bc, (xhl + 16)
	ld (xwa + 2), bc
	ld xbc, (xhl + 22)
	call DrawBitmap
	lds32 xhl, 0

Bitmap_Epilogue:
	pop xiz
	inc 4, xsp
	ret

VwUserBitmapProc:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, VwUserBitmap_HandlePaint
	ld xwa, xiz
	call ViewableProc
	jr VwUserBitmap_Epilogue

VwUserBitmap_HandlePaint:
	ld xwa, xiz
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xsp + 10)
	ld wa, (xiz + 14)
	ld (xbc), wa
	ld wa, (xiz + 16)
	ld (xbc + 2), wa
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a1
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, VwUserBitmap_DrawFallback
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a2
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), hl
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a3
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 10)
	pushw hl
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	call DrawBitmapSPFast
	jr VwUserBitmap_ReturnZero

VwUserBitmap_DrawFallback:
	lda xwa, (xsp + 10)
	lds32 xbc, 0
	call DrawBitmap

VwUserBitmap_ReturnZero:
	lds32 xhl, 0

VwUserBitmap_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

UserBitmapCheck:
	cp xbc, 0x1e000a3
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, 0x1e000a2
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, 0x1e000a1
	jr z, UserBitmapCheck_ReturnTablePtr
	lds32 xhl, 0
	ret

UserBitmapCheck_ReturnTablePtr:
	lda_24 xhl, (Data_SoundEditorCharsLayout_0x4E)
	ret

UserBitmapCheck_ReturnSize:
	ld xhl, 0x18
	ret

VwUserBitmapByNameProc:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 24), xde
	ld xiz, xbc
	ld (xsp + 28), xwa
	cp xiz, 0x1c00002
	jrl z, VwUserBitmapByName_HandleClose
	cp xiz, 0x1c0000d
	jr z, VwUserBitmapByName_HandlePaint
	cp xiz, 0x1c00001
	jr z, VwUserBitmapByName_HandleCreate
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call ViewableProc
	jr VwUserBitmapByName_Epilogue

VwUserBitmapByName_HandleCreate:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	jr VwUserBitmapByName_CallViewable

VwUserBitmapByName_HandlePaint:
	ld	xwa, (xsp+28)
	ld	xbc, xiz
	ld	xde, (xsp+24)
	call	16405896
	ld	xwa, (xsp+28)
	call	16408153
	lda	xbc, (xsp+20)
	ld	wa, (xhl+14)
	ld	(xbc), wa
	ld	wa, (xhl+16)
	ld	(xbc+2), wa
	ld	xwa, (xhl+22)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	pushw	234
	pushw	41312
	lda	xwa, (xsp+16)
	push	xwa
	call	16713188
	lda	xsp, (xsp+16)
	lda	xwa, (xsp+4)
	call	16278763
	ld	xbc, xhl
	lda	xwa, (xsp+20)
	or	xbc, xbc
	jr	z, 6
	call	16433802
	jr	26
VwUserBitmapByName_DrawDefault:
	lds32 xbc, 0
	call DrawBitmap
	jr VwUserBitmapByName_ReturnZero

VwUserBitmapByName_HandleClose:
	lds wa, 2
	call ChangePalette
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)

VwUserBitmapByName_CallViewable:
	call ViewableProc

VwUserBitmapByName_ReturnZero:
	lds32 xhl, 0

VwUserBitmapByName_Epilogue:
	pop xiz
	lda xsp, (xsp + 28)
	ret

IconProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, Icon_HandlePaint
	ld xwa, xiz
	call ViewableProc
	jr Icon_Epilogue

Icon_HandlePaint:
	ld xwa, xiz
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	lda xhl, (xsp + 4)
	ld wa, (xiz + 14)
	inc 2, wa
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xiz + 16)
	inc 2, wa
	ld (xde), wa
	lda xwa, (xsp + 8)
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
	lda xwa, (xsp + 4)
	ld xbc, (xiz + 22)
	call DrawIcons
	lds32 xhl, 0

Icon_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

LineProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xwa
	cp xbc, 0x1c0000d
	jr z, Line_HandlePaint
	ld xwa, (xsp + 20)
	call ViewableProc
	jr Line_Epilogue

Line_HandlePaint:
	ld xwa, (xsp + 20)
	call ViewableProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	lda xwa, (xhl + 16)
	ld (xsp + 8), xwa
	lda xwa, (xhl + 18)
	ld (xsp + 4), xwa
	lda xiz, (xhl + 20)
	ld de, (xhl + 14)
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 12)
	lda xix, (xbc + 2)
	lda xiy, (xwa + 2)
	cp (xhl + 24), 0x1
	jr nz, Line_DrawHorizontal
	ld (xwa), de
	ld xde, (xsp + 8)
	ld de, (xde)
	ld (xiy), de
	ld xde, (xsp + 4)
	ld de, (xde)
	ld (xbc), de
	ld de, (xiz)
	ld (xix), de
	jr Line_DrawAndReturn

Line_DrawHorizontal:
	ld (xwa), de
	ld de, (xiz)
	ld (xiy), de
	ld xde, (xsp + 4)
	ld de, (xde)
	ld (xbc), de
	ld xde, (xsp + 8)
	ld de, (xde)
	ld (xix), de

Line_DrawAndReturn:
	ld de, (xhl + 22)
	call DrawLine
	lds32 xhl, 0

Line_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

FrameProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c0000d
	jr z, Frame_HandlePaint
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ViewableProc
	jr Frame_Epilogue

Frame_HandlePaint:
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr nz, Frame_DrawVisible
	lds32 xhl, 1
	jr Frame_Epilogue

Frame_DrawVisible:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 14)
	pushm (xhl + 26)
	ld bc, (xhl + 22)
	ld de, (xhl + 24)
	calr DrawDesignFrame
	lds32 xhl, 0

Frame_Epilogue:
	pop xiz
	inc 8, xsp
	ret

GetClientFrame:
	dec 8, xsp
	push xiz
	ld xiz, xbc
	call GetViewInstance
	lda xiy, (xhl + 14)
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	lda xde, (xsp + 4)
	push xiz
	ld wa, (xhl + 22)
	ld bc, (xhl + 24)
	calr GetClientFrame2
	pop xiz
	inc 8, xsp
	ret

GetClientFrame2:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	lds32 xhl, 0
	ld xiz, (xsp + 10)
	ld xiy, xde
	ld xix, xiz
	lds bc, 4
	ldirw
	cps wa, 0
	jr z, FrameLoop_Cleanup
	cps wa, 1
	jr nz, ClientFrame2_ProcessThickness
	ld hl, (xsp + 4)
	exts xhl

ClientFrame2_ProcessThickness:
	or xhl, xhl
	jr z, FrameLoop_Cleanup
	lds32 xiy, 0
	cp xhl, 0x0
	jr le, FrameLoop_Cleanup
	lda xix, (xiz + 2)
	lda xde, (xiz + 6)
	ld xbc, xiz
	lda xwa, (xiz + 4)

ClientFrame2_InsetLoop:
	incm 1, (xix)
	decm 1, (xde)
	incm 1, (xbc)
	decm 1, (xwa)
	inc 1, xiy
	cp xiy, xhl
	jr lt, ClientFrame2_InsetLoop

FrameLoop_Cleanup:
	pop xiz
	inc 2, xsp
	retd 0x4

DrawDesignFrame:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 12), de
	ld de, bc
	ld xiy, xwa
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	cps de, 1
	jr nz, DesignFrame_Epilogue
	lds32 xiz, 0
	ld wa, (xsp + 12)
	exts xwa
	cp xwa, 0x0
	jr le, DesignFrame_Epilogue

DesignFrame_DrawLoop:
	lda xwa, (xsp + 4)
	ld bc, (xsp + 18)
	call DrawFrame
	lda xwa, (xsp + 4)
	incm 1, (xwa + 2)
	decm 1, (xwa + 6)
	incm 1, (xwa)
	decm 1, (xwa + 4)
	inc 1, xiz
	ld wa, (xsp + 12)
	exts xwa
	cp xiz, xwa
	jr lt, DesignFrame_DrawLoop

DesignFrame_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x2

EditSwProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x1c00007
	jr z, EditSw_HandleOK
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr EditSw_CallLabelProc

EditSw_HandleOK:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 8)
	call SendEvent
	ld xbc, (xsp + 4)
	ld wa, (xbc + 32)
	extz xwa
	cp xwa, xhl
	jr nz, EditSw_ForwardToLabel
	ld xwa, (xbc + 34)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld de, (xwa + 38)
	cp de, 0xffff
	jr z, EditSw_ReturnZero
	exts xde
	ld xwa, (xsp + 8)
	bit 7, wa
	jr z, EditSw_SendDialDown
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018
	jr EditSw_SendDialEvent

EditSw_SendDialDown:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017

EditSw_SendDialEvent:
	call SendEvent

EditSw_ReturnZero:
	lds32 xhl, 0
	jr EditSw_Epilogue

EditSw_ForwardToLabel:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

EditSw_CallLabelProc:
	calr LabelProc

EditSw_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

EditSw_ByteData:
	.byte 0xbf, 0xe4, 0x37, 0x2e, 0x1d, 0x59, 0x5e, 0xfa
	.byte 0xbf, 0x08, 0x63, 0xaf, 0x08, 0x20, 0xbf, 0x02
	.byte 0x60, 0xbf, 0x12, 0x31, 0x98, 0x20, 0x20, 0x1e
	.byte 0xc3, 0xdf, 0xbf, 0x12, 0x30, 0xbf, 0x0c, 0x31
	.byte 0x98, 0x02, 0x3f, 0xef, 0x00, 0x66, 0x14, 0x90
	.byte 0x3f, 0x00, 0x00, 0x6e, 0x07, 0x40, 0x66, 0xa1
	.byte 0xea, 0x00, 0x68, 0x0c, 0x40, 0x6a, 0xa1, 0xea
	.byte 0x00, 0x68, 0x05, 0x40, 0x6e, 0xa1, 0xea, 0x00
	.byte 0x38, 0x39, 0x1d, 0x70, 0x07, 0xff, 0xbf, 0x14
	.byte 0x30, 0x38, 0x1d, 0xc3, 0x07, 0xff, 0xdb, 0x8e
	.byte 0xaf, 0x14, 0x20, 0xa8, 0x16, 0x20, 0x38, 0x1d
	.byte 0xc3, 0x07, 0xff, 0xbf, 0x10, 0x37, 0xde, 0xf3
	.byte 0x63, 0x17, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0xc3
	.byte 0x07, 0xff, 0xdb, 0x61, 0x2b, 0x1d, 0xa3, 0x06
	.byte 0xff, 0xef, 0x66, 0xaf, 0x08, 0x20, 0xb8, 0x16
	.byte 0x63, 0xbf, 0x0c, 0x30, 0x38, 0xaf, 0x0c, 0x20
	.byte 0xa8, 0x16, 0x20, 0x38, 0x1d, 0x70, 0x07, 0xff
	.byte 0xef, 0x60, 0xaf, 0x08, 0x21, 0xa9, 0x16, 0x20
	.byte 0xa9, 0x1a, 0x21, 0x1d, 0xc4, 0x22, 0xfb, 0xbf
	.byte 0x06, 0x53, 0xaf, 0x08, 0x20, 0xa8, 0x1a, 0x20
	.byte 0x1d, 0xfd, 0x21, 0xfb, 0xbf, 0x12, 0x31, 0xdb
	.byte 0x88, 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0xbf
	.byte 0x16, 0x34, 0x91, 0x3f, 0x00, 0x00, 0x6e, 0x0c
	.byte 0xb4, 0x02, 0xfe, 0xff, 0x99, 0x02, 0x22, 0xd8
	.byte 0xa2, 0xbc, 0x02, 0x52, 0x91, 0x3f, 0x3f, 0x01
	.byte 0x6e, 0x10, 0x32, 0x3e, 0x01, 0x9f, 0x06, 0xa2
	.byte 0xb4, 0x52, 0x99, 0x02, 0x22, 0xd8, 0xa2, 0xbc
	.byte 0x02, 0x52, 0x99, 0x02, 0x3f, 0xef, 0x00, 0x6e
	.byte 0x19, 0x9f, 0x06, 0x20, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0x91, 0x21, 0xd8, 0xa1, 0xd9, 0x69
	.byte 0xb4, 0x51, 0x30, 0xf5, 0x00, 0xdb, 0xa0, 0xbc
	.byte 0x02, 0x50, 0xbc, 0x04, 0x32, 0x9f, 0x06, 0x20
	.byte 0x94, 0x80, 0xd8, 0x61, 0xb2, 0x50, 0xbc, 0x06
	.byte 0x35, 0xbc, 0x02, 0x31, 0x91, 0x20, 0xd8, 0x83
	.byte 0xb5, 0x53, 0xaf, 0x08, 0x20, 0x91, 0x21, 0xb8
	.byte 0x10, 0x51, 0x95, 0x21, 0xb8, 0x14, 0x51, 0x94
	.byte 0x21, 0xb8, 0x0e, 0x51, 0xaf, 0x02, 0x20, 0x92
	.byte 0x21, 0xb8, 0x12, 0x51, 0x4e, 0xbf, 0x1c, 0x37
	.byte 0x0e
DrawEditSw:
	lda xsp, (xsp - 18)
	pushw iz
	cp wa, 0xff
	jrl z, DrawEditSw_SkipDraw
	cp wa, 0xf
	jrl z, DrawEditSw_SkipDraw
	lda xbc, (xsp + 8)
	calr GetEditSwPoint
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 2)
	cpw (xwa + 2), 0xef
	jr z, DrawEditSw_SelectVariantC
	cpw (xwa), 0x0
	jr nz, DrawEditSw_SelectVariantA
	ld xwa, Data_SoundEditorCharsLayout_0x2A0
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantA:
	ld xwa, Data_SoundEditorCharsLayout_0x2A4
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantC:
	ld xwa, Data_SoundEditorCharsLayout_0x2A8

DrawEditSw_CopyVariant:
	.byte 0x38, 0x39, 0x1d, 0x70, 0x07, 0xff, 0xef, 0x60
	.byte 0xbf, 0x02, 0x30, 0xe9, 0xa8, 0x1d, 0xc4, 0x22
	.byte 0xfb, 0xdb, 0x8e, 0xe8, 0xa8, 0x1d, 0xfd, 0x21
	.byte 0xfb, 0xbf, 0x08, 0x31, 0xdb, 0x8a, 0xea, 0x13
	.byte 0xda, 0x0b, 0x02, 0x00, 0xbf, 0x0c, 0x30, 0x91
	.byte 0x3f, 0x00, 0x00, 0x6e, 0x0c, 0xb0, 0x02, 0xfe
	.byte 0xff, 0x99, 0x02, 0x24, 0xda, 0xa4, 0xb8, 0x02
	.byte 0x54
DrawEditSw_PositionLeft:
	cpw (xbc), 0x13f
	jr nz, DrawEditSw_PositionRight
	ldw ix, 0x13e
	sub ix, iz
	ld (xwa), ix
	ld ix, (xbc + 2)
	sub ix, de
	ld (xwa + 2), ix

DrawEditSw_PositionRight:
	lda xix, (xbc + 2)
	cpw (xix), 0xef
	jr nz, DrawEditSw_FinalPosition
	ld de, iz
	exts xde
	divs de, 0x2
	ld iy, (xbc)
	sub iy, de
	dec 1, iy
	ld (xwa), iy
	ldw de, 0xf5
	sub de, hl
	ld (xwa + 2), de

DrawEditSw_FinalPosition:
	ld de, (xwa)
	inc 2, de
	ld (xbc), de
	lda xiy, (xwa + 2)
	ld de, (xiy)
	inc 1, de
	ld (xix), de
	ld de, iz
	add de, (xwa)
	inc 1, de
	ld (xwa + 4), de
	add hl, (xiy)
	ld (xwa + 6), hl
	lda xde, (xsp + 2)
	lds32 xhl, 0
	push xhl
	pushw 0xf4
	pushw 0xf7
	call DrawString

DrawEditSw_SkipDraw:
	popw iz
	lda xsp, (xsp + 18)
	ret

TextBoxProc:
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), xwa
	cp xbc, 0x1c0000d
	jr z, TextBox_HandlePaint
	ld xwa, (xsp + 38)
	calr BoxProc
	jrl TextBox_Epilogue

TextBox_HandlePaint:
	ld	xwa, (xsp+38)
	calr	51709
	ld	xwa, (xsp+38)
	call	16408153
	ld	(xsp+18), xhl
	ld	xwa, (xsp+18)
	ld	(xsp+4), xwa
	lda	xbc, (xsp+26)
	ld	xwa, (xsp+38)
	calr	51776
	ld	xwa, (xsp+18)
	ld	xwa, (xwa+26)
	push	xwa
	call	16713667
	ld	xwa, (xsp+22)
	ld	wa, (xwa+38)
	add	wa, hl
	ld	(xsp+20), wa
	inc	1, wa
	pushw	wa
	call	16713379
	inc	6, xsp
	ld	(xsp+22), xhl
	ld	xiz, (xsp+22)
	lds	bc, 0
	ld	wa, (xsp+16)
	add	wa, 1
	jr	ule, 10
TextBox_FillBufferLoop:
	stib_dsp 0xf8, 0x00
	inc 1, bc
	cp bc, wa
	jr c, TextBox_FillBufferLoop

TextBox_SetupWordwrap:
	ld xiz, (xsp + 22)
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 26)
	ld xbc, (xsp + 22)
	call ConvertStrings
	lda xbc, (xsp + 26)
	ld wa, (xbc + 4)
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld bc, (xbc)
	add bc, wa
	ld (xsp + 34), bc
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 30)
	call GetCharDescent
	lda xwa, (xsp + 26)
	ld bc, (xwa + 6)
	sub bc, (xwa + 2)
	sub bc, hl
	ld de, bc
	ld xwa, (xsp + 18)
	ld bc, (xwa + 38)
	extz xde
	div xde, xbc
	ld (xsp + 8), de
	ldw (xsp + 16), 0x0
	cps bc, 0
	jrl ule, TextBox_FreeBuffer

TextBox_DrawLineLoop:
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x7e, 0xa1, 0x3e, 0x1d
	.byte 0xa0, 0x01, 0xff, 0xef, 0x60, 0xf3, 0x07, 0xf8
	.byte 0xec, 0x30, 0xbf, 0x0a, 0x60, 0xb0, 0x00, 0x00
	.byte 0xbf, 0x1a, 0x30, 0x98, 0x04, 0x22, 0x90, 0xa2
	.byte 0xaf, 0x12, 0x20, 0xa8, 0x1e, 0x21, 0xee, 0x88
	.byte 0x1d, 0x4d, 0x23, 0xfb, 0xbf, 0x0e, 0x53, 0x3e
	.byte 0x1d, 0xc3, 0x07, 0xff, 0xef, 0x64, 0x9f, 0x0e
	.byte 0x20, 0xdb, 0xf0, 0x66, 0x17, 0xaf, 0x0a, 0x20
	.byte 0xb0, 0x00, 0x0d, 0x9f, 0x0e, 0x20, 0xe8, 0x13
	.byte 0xee, 0x80, 0xbf, 0x0a, 0x60, 0xf4, 0xe0, 0x00
	.byte 0x00, 0xbf, 0x0a, 0x60
TextBox_CheckMoreText:
	ld wa, (xsp + 8)
	mrdw3 0x9f, 0x10, 0x40
	lda xde, (xsp + 26)
	ld bc, (xde + 2)
	add bc, wa
	ld wa, (xsp + 8)
	exts xwa
	divs wa, 0x2
	add wa, bc
	lda xbc, (xsp + 34)
	ld (xbc + 2), wa
	ld xhl, (xsp + 4)
	ld xwa, (xhl + 30)
	push xwa
	pushm (xhl + 34)
	pushw 0xf7
	ld xwa, xhl
	ld a, (xwa + 36)
	extz wa
	pushw wa
	ld xwa, xde
	ld xde, xiz
	call DrawStringAlignment
	ld xwa, (xsp + 10)
	inc 1, xwa
	ld xiz, xwa
	cp (xwa), 0x0
	jr z, TextBox_FreeBuffer
	incm 1, (xsp + 16)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 16)
	cp bc, (xwa + 38)
	jrl c, TextBox_DrawLineLoop

TextBox_FreeBuffer:
	ld	xwa, (xsp+22)
	push	xwa
	call	16712469
	inc	4, xsp
	lds32	xhl, 0
TextBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret

VwBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xwa
	cp xbc, 0x1e000b2
	jrl z, VwBox_HandleGetColor
	cp xbc, 0x1e000b1
	jrl z, VwBox_HandleGetHeight
	cp xbc, 0x1e00050
	jr z, VwBox_HandleHitTest
	cp xbc, 0x1e00051
	jr z, VwBox_HandleGetWidth
	cp xbc, 0x1e0004e
	jr z, VwBox_HandleGetFocus
	cp xbc, 0x1c0000d
	jrl nz, VwBox_DefaultHandler
	ld xwa, xiz
	ld xde, (xsp + 12)
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 14)
	ld bc, (xhl + 24)
	ld de, (xhl + 22)
	call DrawDesignBox
	jr VwBox_DrawReturnZero

VwBox_HandleGetFocus:
	lda xbc, (xsp + 4)
	ld xwa, xiz
	calr GetClientBox
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xsp + 12)
	lda xwa, (xsp + 4)
	cps bc, 0
	jr z, VwBox_UseFocusColor
	pushw 0xf2
	lds bc, 1
	lds de, 2
	jr VwBox_CallDrawDesignFrame

VwBox_UseFocusColor:
	pushm (xhl + 22)
	lds bc, 1
	lds de, 2

VwBox_CallDrawDesignFrame:
	calr DrawDesignFrame

VwBox_DrawReturnZero:
	lds32 xhl, 0
	jr ViewableProc_Return

VwBox_HandleGetWidth:
	ld xwa, xiz
	ld xiz, 0x1a
	jr VwBox_GetFieldAtOffset

VwBox_HandleHitTest:
	ld xwa, xiz
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp xwa, (xsp + 12)
	scc16 z, hl
	extz xhl
	jr ViewableProc_Return

VwBox_HandleGetHeight:
	ld xwa, xiz
	ld xiz, 0x18
	jr VwBox_GetFieldAtOffset

VwBox_HandleGetColor:
	ld xwa, xiz
	ld xiz, 0x16

VwBox_GetFieldAtOffset:
	call GetViewInstance
	add xhl, xiz
	ld hl, (xhl)
	exts xhl
	jr ViewableProc_Return

VwBox_DefaultHandler:
	ld xwa, xiz
	ld xde, (xsp + 12)
	call ViewableProc

ViewableProc_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PsParaBoxProc:
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XWA, 0xfd, 0x14, 0x01
	cp xbc, 0x1e0003a
	jrl z, PsParaBox_HandleGetText
	cp xbc, 0x1c0000f
	jr z, PsParaBox_HandleConfirm
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr VwBoxProc
	jrl PsParaBox_Epilogue

PsParaBox_HandleConfirm:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr VwBoxProc
	stb_dri A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr GetClientBox
	stb_dri W, 0xfd, 0x08, 0x01
	stb_dri A, 0xfd, 0x04, 0x01
	calr GetBoxCenter
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0110)
	or xwa, xwa
	jr nz, PsParaBox_UseEventText
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e0003a
	call SendEvent
	cp (xsp + 4), 0x0
	jr nz, PsParaBox_DrawAligned
	jr PsParaBox_ReturnZero

PsParaBox_UseEventText:
	ld	xwa, (xsp+272)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsParaBox_DrawAligned:
	stb_dri W, 0xfd, 0x08, 0x01
	stb_dri C, 0xfd, 0x04, 0x01
	lda xde, (xsp + 4)
	ld xbc, (xiz + 28)
	push xbc
	pushm (xiz + 32)
	pushm (xiz + 22)
	ld c, (xiz + 34)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringAlignment
	jr PsParaBox_ReturnZero

PsParaBox_HandleGetText:
	ld_sril XWA, (xsp + 0x0110)
	ld (xwa), 0x0

PsParaBox_ReturnZero:
	lds32 xhl, 0

PsParaBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

AcLswBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xwa
	cp xbc, 0x1c00018
	jrl z, AcLswBox_HandlePageDown
	cp xbc, 0x1c0001a
	jrl z, AcLswBox_HandlePageUp
	cp xbc, 0x1c00017
	jrl z, AcLswBox_HandleScrollDown
	cp xbc, 0x1c00019
	jrl z, AcLswBox_HandleScrollUp
	cp xbc, 0x1c0001c
	jrl z, AcLswBox_HandleWriteBack
	cp xbc, 0x1c0000c
	jr z, AcLswBox_HandleShowHide
	cp xbc, 0x1c0000b
	jr z, AcLswBox_HandleShowHide
	cp xbc, 0x1c00002
	jr z, AcLswBox_HandleClose
	cp xbc, 0x1c00001
	jr z, AcLswBox_HandleCreate
	cp xbc, 0x1e0003a
	jrl nz, AcLswBox_DefaultHandler
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00040
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 4)
	ld (xde), xhl
	ld xwa, (xiz + 40)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 16)
	ld (xde + 8), xwa
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00042
	call ApFuncCall
	jrl AcLswBox_ReturnZeroJmp

AcLswBox_HandleCreate:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	jr AcLswBox_CallPsParaBox

AcLswBox_HandleClose:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)

AcLswBox_CallPsParaBox:
	calr PsParaBoxProc
	jrl AcLswBox_ReturnZeroJmp

AcLswBox_HandleShowHide:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e00040
	lds32 xde, 0
	call ApFuncCall
	ld xwa, xhl
	calr MainLswGet
	jrl AcLswBox_ReturnZeroJmp

AcLswBox_HandleWriteBack:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00040
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 16)
	cp (xwa), xhl
	jrl nz, AcLswBox_ReturnZeroJmp
	lda xde, (xiz + 40)
	ld xbc, (xde)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00083
	call ApFuncCall
	ld xwa, (xsp + 20)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1e0003d
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1e0003d
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1e0003d
	ld xde, xhl

Ac_SendUIEvent_Common:
	call SendEvent

AcLswBox_ReturnZeroJmp:
	lds32 xhl, 0
	jr AcLswBox_Epilogue

AcLswBox_DefaultHandler:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc

AcLswBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

AcRamBoxProc:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 30), xde
	ld (xsp + 34), xwa
	cp xbc, 0x1c00018
	jrl z, AcRamBox_HandlePageDown
	cp xbc, 0x1c0001a
	jrl z, AcRamBox_HandlePageUp
	cp xbc, 0x1c00017
	jrl z, AcRamBox_HandleScrollDown
	cp xbc, 0x1c00019
	jrl z, AcRamBox_HandleScrollUp
	cp xbc, 0x1c0001d
	jrl z, AcRamBox_HandleWriteBack
	cp xbc, 0x1e000a7
	jr z, AcRamBox_HandleDataRefresh
	cp xbc, 0x1c0000c
	jr z, AcRamBox_HandleShowHide
	cp xbc, 0x1c0000b
	jr z, AcRamBox_HandleShowHide
	cp xbc, 0x1e0003a
	jrl nz, AcRamBox_DefaultHandler
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 40)
	ld xwa, (xwa)
	ld (xde + 14), xwa
	ld xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00047
	call ApFuncCall
	jrl AcRamBox_EventReturn

AcRamBox_HandleShowHide:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc

AcRamBox_HandleDataRefresh:
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld bc, hl
	calr MainRamGet
	jrl AcRamBox_EventReturn

AcRamBox_HandleWriteBack:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld xix, (xsp + 30)
	ld xwa, (xix)
	cp xwa, xhl
	jrl nz, AcRamBox_EventReturn
	lda xde, (xiz + 40)
	ld xbc, (xde)
	ld xwa, (xix + 14)
	ld (xbc), xwa
	ld xwa, (xde)
	ld xde, (xwa)
	ld xwa, (xiz + 36)
	ld xbc, 0x1e00082
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1e0003d
	ld xde, xhl

AcRamBox_SendUIEvent_Common:
	call SendEvent

AcRamBox_EventReturn:
	lds32 xhl, 0
	jr AcRamBox_Epilogue

AcRamBox_DefaultHandler:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc

AcRamBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 34)
	ret

AcTempoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcTempoBox_HandleConfirm
	cp xbc, 0x1c0000c
	jr z, AcTempoBox_HandleShowHide
	cp xbc, 0x1c0000b
	jr z, AcTempoBox_HandleShowHide
	cp xbc, 0x1c00002
	jr z, AcTempoBox_HandleClose
	cp xbc, 0x1c00001
	jr z, AcTempoBox_HandleCreate
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	jrl AcTempoBox_Epilogue

AcTempoBox_HandleCreate:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	jr AcTempoBox_CallPsParaBox

AcTempoBox_HandleClose:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz

AcTempoBox_CallPsParaBox:
	calr PsParaBoxProc
	jr PsRadioBox_EventReturn

AcTempoBox_HandleShowHide:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	lds32 xwa, 4
	calr MainLswGet
	jr PsRadioBox_EventReturn

AcTempoBox_HandleConfirm:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, (xiz)
	cp xwa, 0x4
	jr z, AcTempoBox_MatchTempoID
	ld xwa, (xiz)
	cp xwa, 0x2200
	jr nz, PsRadioBox_EventReturn

AcTempoBox_MatchTempoID:
	ld	xwa, 8704
	call	16567398
	cps	hl, 0
	jr	nz, 26
	lds32	xwa, 4
	call	16567398
	pushw	hl
	pushw	234
	pushw	41344
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	jr	16
AcTempoBox_CopyTempoString:
	pushw	234
	pushw	41352
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
AcTempoBox_SendConfirmEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

PsRadioBox_EventReturn:
	lds32 xhl, 0

AcTempoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret

PsRadioBoxProc:
	stb_dri L, 0xfd, 0xdc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x1c, 0x01
	stl_dri XBC, 0xfd, 0x20, 0x01
	stl_dri XWA, 0xfd, 0x24, 0x01
	ld_sril XWA, (xsp + 0x0120)
	cp xwa, 0x1e00053
	jrl z, PsRadioBox_HitTest
	cp xwa, 0x1e0003a
	jrl z, PsRadioBox_GetText
	cp xwa, 0x1e0004d
	jrl z, PsRadioBox_SetIndex
	cp xwa, 0x1c0002a
	jrl z, PsRadioBox_RadioSelect
	cp xwa, 0x1c0001b
	jrl z, PsRadioBox_Release
	cp xwa, 0x1c00007
	jrl z, PsRadioBox_OK
	cp xwa, 0x1c0002c
	jrl z, PsRadioBox_Reset
	cp xwa, 0x1c0000e
	jrl z, PsRadioBox_Select
	cp xwa, 0x1c0000f
	jr z, PsRadioBox_Confirm
	cp xwa, 0x1c0000d
	jrl nz, PsRadioBox_Default
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	stb_dri A, 0xfd, 0x10, 0x01
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	cpiw_sri 0xfd, 0x12, 0x01, 0xef, 0x00
	jr z, PsRadioBox_Paint_SendConfirm
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr DrawEditSw

PsRadioBox_Paint_SendConfirm:
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Confirm:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	stb_dri A, 0xfd, 0x14, 0x01
	ld_sril XWA, (xsp + 0x0124)
	calr GetClientBox
	stb_dri W, 0xfd, 0x14, 0x01
	stb_dri A, 0xfd, 0x10, 0x01
	calr GetBoxCenter
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xde, (xsp + 16)
	ld_sril XWA, (xsp + 0x011c)
	or xwa, xwa
	jr nz, PsRadioBox_Confirm_CopyText
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0003a
	call SendEvent
	cp (xsp + 16), 0x0
	jr nz, PsRadioBox_Confirm_Draw
	jrl PsRadioBox_ReturnZero

PsRadioBox_Confirm_CopyText:
	ld	xwa, (xsp+284)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsRadioBox_Confirm_Draw:
	calr GetDialFocus
	stb_dri W, 0xfd, 0x14, 0x01
	stb_dri A, 0xfd, 0x10, 0x01
	ld (xsp + 12), xbc
	lda xbc, (xsp + 16)
	ld (xsp + 8), xbc
	ld xbc, (xsp + 4)
	lda xde, (xbc + 22)
	lda xiz, (xbc + 28)
	lda xiy, (xbc + 32)
	ld c, (xbc + 34)
	ldb_erp C, 0xf0
	extz ix
	cpl_sri_rm XHL, 0xfd, 0x24, 0x01
	jr nz, PsRadioBox_Confirm_DrawUnfocused
	ld xbc, (xiz)
	push xbc
	pushm (xiy)
	pushm (xde)
	pushw ix
	pushw 0x1
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	jr PsRadioBox_Confirm_DrawCall

PsRadioBox_Confirm_DrawUnfocused:
	ld xbc, (xiz)
	push xbc
	pushm (xiy)
	pushm (xde)
	pushw ix
	pushw 0x0
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)

PsRadioBox_Confirm_DrawCall:
	call DrawStringReverse
	jrl PsRadioBox_ReturnZero

PsRadioBox_Select:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	calr GetDialFocus
	cpl_sri_rm XHL, 0xfd, 0x24, 0x01
	jr nz, PsRadioBox_Select_GetIndex
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0004e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Select_GetIndex:
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 38)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0004e
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	calr GetDialFocus
	cpl_sri_rm XHL, 0xfd, 0x24, 0x01
	jr nz, PsRadioBox_Reset_CheckValue
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset_CheckValue:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_OK:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e00053
	ld_sril XDE, (xsp + 0x011c)
	call SendEvent
	or xhl, xhl
	jr z, PsRadioBox_OK_Forward
	ld xwa, (xsp + 12)
	cpw (xwa + 26), 0xffff
	jr z, PsRadioBox_OK_Forward
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0004d
	lds32 xde, 1
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_OK_Forward:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	jrl PsRadioBox_CallVwBoxProc

PsRadioBox_Release:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x1c, 0x01
	jrl nz, PsRadioBox_ReturnZero
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0004d
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_RadioSelect:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	lda xwa, (xhl + 26)
	cpw (xwa), 0xffff
	jrl z, PsRadioBox_ReturnZero
	ld_sril XBC, (xsp + 0x011c)
	srl xbc, 0
	ldiw_erp 0xe6, 0
	ld wa, (xwa)
	cp wa, bc
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x011c)
	ld bc, (xhl + 42)
	cp bc, wa
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1e0004d
	lds32 xde, 1
	jr PsRadioBox_DispatchAndReturn

PsRadioBox_SetIndex:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xbc, (xsp + 12)
	ld xwa, (xbc + 38)
	ld wa, (xwa)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x1c, 0x01
	jr z, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x011c)
	cps wa, 1
	jr nz, PsRadioBox_SetIndex_Store
	ld de, (xbc + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld xwa, (xsp + 12)
	ld bc, (xwa + 42)
	extz xbc
	ld wa, (xwa + 26)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, 0x1c00029
	call SendEvent

PsRadioBox_SetIndex_Store:
	ld xwa, (xsp + 12)
	ld xbc, (xwa + 38)
	ld_sril XWA, (xsp + 0x011c)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1c0000e
	lds32 xde, 0

PsRadioBox_DispatchAndReturn:
	call SendEvent
	jr PsRadioBox_ReturnZero

PsRadioBox_GetText:
	ld_sril XWA, (xsp + 0x011c)
	ld (xwa), 0x0

PsRadioBox_ReturnZero:
	lds32 xhl, 0
	jr PsRadioBox_Return

PsRadioBox_HitTest:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld_sril XDE, (xsp + 0x011c)
	call SendEvent
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	extz xwa
	cp xwa, xhl
	scc16 z, hl
	extz xhl
	jr PsRadioBox_Return

PsRadioBox_Default:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)

PsRadioBox_CallVwBoxProc:
	calr VwBoxProc

PsRadioBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x24, 0x01
	ret

AcStrRadioBoxProc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1e0003a
	jr z, AcStrRadioBox_GetText
	ld xde, xiz
	calr PsRadioBoxProc
	jr AcStrRadioBox_Epilogue

AcStrRadioBox_GetText:
	call	16408153
	ld	xwa, (xhl+44)
	push	xwa
	push	xiz
	call	16713584
	inc	8, xsp
	lds32	xhl, 0
AcStrRadioBox_Epilogue:
	pop xiz
	ret

PsListBoxProc:
	stb_dri L, 0xfd, 0xd6, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x26, 0x01
	stl_dri XWA, 0xfd, 0x2a, 0x01
	cp xbc, 0x1e0003a
	jrl z, PsListBox_GetText
	cp xbc, 0x1e0004d
	jrl z, PsListBox_SetIndex
	cp xbc, 0x1e00090
	jrl z, PsListBox_GetCount
	cp xbc, 0x1c0002c
	jrl z, PsListBox_Reset
	cp xbc, 0x1c0000e
	jrl z, PsListBox_Select
	cp xbc, 0x1c0000f
	jr z, PsListBox_Confirm
	cp xbc, 0x1c0000d
	jrl nz, PsListBox_Default
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld iz, (xwa)
	ldw (xwa), 0xffff
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld de, iz
	exts xde
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1c0000e
	jrl PsListBox_SendEvent

PsListBox_Confirm:
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc
	lda xde, (xsp + 26)
	ld_sril XWA, (xsp + 0x0126)
	or xwa, xwa
	jr nz, PsListBox_Confirm_CopyText
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1e0003a
	call SendEvent
	jr PsListBox_Confirm_Layout

PsListBox_Confirm_CopyText:
	ld	xwa, (xsp+294)
	push	xwa
	push	xde
	call	16713584
	inc	8, xsp
PsListBox_Confirm_Layout:
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	stb_dri A, 0xfd, 0x1e, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	stb_dri W, 0xfd, 0x1e, 0x01
	lda xhl, (xwa + 6)
	ld de, (xwa + 2)
	ld wa, (xhl)
	sub wa, de
	lda xix, (xiz + 36)
	ld bc, (xix)
	extz xwa
	div xwa, xbc
	ld (xsp + 8), wa
	add de, (xsp + 8)
	inc 3, de
	ld (xhl), de
	ldw (xsp + 12), 0x0
	ldw (xsp + 10), 0x0
	cpw (xix), 0x0
	jrl ule, PsListBox_ReturnZero

PsListBox_Confirm_ItemLoop:
	ld wa, (xsp + 12)
	extz xwa
	lda xde, (xsp + 26)
	ld (xsp + 14), xde
	add (xsp + 14), xwa
	jr PsListBox_Confirm_ScanLoop

PsListBox_Confirm_ScanPipe:
	cp a, 0x7c
	jr nz, PsListBox_Confirm_AdvanceChar
	ld (xbc), 0x0
	incm 1, (xsp + 12)
	jr PsListBox_Confirm_DrawItem

PsListBox_Confirm_AdvanceChar:
	incm 1, (xsp + 12)

PsListBox_Confirm_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsListBox_Confirm_ScanPipe

PsListBox_Confirm_DrawItem:
	stb_dri W, 0xfd, 0x1e, 0x01
	stb_dri A, 0xfd, 0x1a, 0x01
	calr GetBoxCenter
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 38)
	ld de, (xwa)
	lda xwa, (xbc + 22)
	ld (xsp + 22), xwa
	lda xiy, (xbc + 28)
	ld xwa, xbc
	ld l, (xwa + 34)
	extz hl
	stb_dri A, 0xfd, 0x1a, 0x01
	lda xix, (xwa + 32)
	cp de, (xsp + 10)
	jr nz, PsListBox_Confirm_ItemUnfocused
	stb_dri H, 0xfd, 0x1e, 0x01
	ld (xsp + 18), xbc
	ld xwa, (xiy)
	push xwa
	pushm (xix)
	ld xwa, (xsp + 28)
	pushm (xwa)
	pushw hl
	calr GetDialFocus
	cpl_sri_rm XHL, 0xfd, 0x34, 0x01
	scc16 z, wa
	pushw wa
	ld xwa, xiz
	ld xbc, (xsp + 30)
	ld xde, (xsp + 26)
	jr PsListBox_Confirm_RenderText

PsListBox_Confirm_ItemUnfocused:
	stb_dri W, 0xfd, 0x1e, 0x01
	ld xde, (xiy)
	push xde
	pushm (xix)
	ld xde, (xsp + 28)
	pushm (xde)
	pushw hl
	pushw 0x0
	ld xde, (xsp + 26)

PsListBox_Confirm_RenderText:
	call DrawStringReverse
	stb_dri A, 0xfd, 0x1e, 0x01
	ld wa, (xsp + 8)
	add (xbc + 2), wa
	add (xbc + 6), wa
	incm 1, (xsp + 10)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 10)
	cp bc, (xwa + 36)
	jrl c, PsListBox_Confirm_ItemLoop
	jrl PsListBox_ReturnZero

PsListBox_Select:
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 4), xwa
	lda xwa, (xwa + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x26, 0x01
	jrl z, PsListBox_ReturnZero
	ld xwa, (xwa)
	cpw (xwa), 0xffff
	jrl z, PsListBox_Select_UpdateCurrent
	stb_dri A, 0xfd, 0x1e, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	stb_dri W, 0xfd, 0x1e, 0x01
	lda xiy, (xwa + 6)
	lda xix, (xwa + 2)
	ld hl, (xix)
	ld bc, (xiy)
	sub bc, hl
	ld de, bc
	extz xde
	ld xbc, (xsp + 22)
	mrdw3 0x99, 0x24, 0x52
	ld (xsp + 8), de
	ld xde, (xbc + 38)
	ld bc, (xsp + 8)
	mriw2 0x92, 0x49
	inc 1, bc
	add hl, bc
	ld (xix), hl
	incm 1, (xwa)
	decm 1, (xwa + 4)
	ld bc, (xix)
	add bc, (xsp + 8)
	inc 1, bc
	ld (xiy), bc
	stb_dri A, 0xfd, 0x1a, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1e0003a
	call SendEvent
	ldw (xsp + 12), 0x0
	ldw (xsp + 10), 0x0
	jr PsListBox_Select_CheckDone

PsListBox_Select_ScanItems:
	ld wa, (xsp + 12)
	extz xwa
	lda xde, (xsp + 26)
	ld (xsp + 14), xde
	add (xsp + 14), xwa
	jr PsListBox_Select_ScanLoop

PsListBox_Select_CheckPipe:
	cp a, 0x7c
	jr nz, PsListBox_Select_NextChar
	ld (xbc), 0x0
	incm 1, (xsp + 12)
	jr PsListBox_Select_NextItem

PsListBox_Select_NextChar:
	incm 1, (xsp + 12)

PsListBox_Select_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsListBox_Select_CheckPipe

PsListBox_Select_NextItem:
	incm 1, (xsp + 10)

PsListBox_Select_CheckDone:
	ld xhl, (xsp + 4)
	ld xwa, (xhl + 38)
	ld wa, (xwa)
	cp (xsp + 10), wa
	jr ule, PsListBox_Select_ScanItems
	stb_dri B, 0xfd, 0x1e, 0x01
	stb_dri A, 0xfd, 0x1a, 0x01
	ld xwa, (xhl + 28)
	push xwa
	pushm (xhl + 32)
	ld xwa, xhl
	pushm (xwa + 22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	calr GetDialFocus
	cpl_sri_rm XHL, 0xfd, 0x2a, 0x01
	jr z, PsListBox_Select_UpdateCurrent
	stb_dri W, 0xfd, 0x1e, 0x01
	ld xbc, (xsp + 4)
	pushm (xbc + 22)
	lds bc, 1
	lds de, 2
	calr DrawDesignFrame

PsListBox_Select_UpdateCurrent:
	ld xwa, (xsp + 22)
	ld xbc, (xwa + 38)
	ld_sril XWA, (xsp + 0x0126)
	ld (xbc), wa
	stb_dri A, 0xfd, 0x1e, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	stb_dri W, 0xfd, 0x1e, 0x01
	lda xiy, (xwa + 6)
	lda xix, (xwa + 2)
	ld hl, (xix)
	ld bc, (xiy)
	sub bc, hl
	ld de, bc
	extz xde
	ld xbc, (xsp + 22)
	mrdw3 0x99, 0x24, 0x52
	ld (xsp + 8), de
	ld xde, (xbc + 38)
	ld bc, (xsp + 8)
	mriw2 0x92, 0x49
	inc 1, bc
	add hl, bc
	ld (xix), hl
	incm 1, (xwa)
	decm 1, (xwa + 4)
	ld bc, (xix)
	add bc, (xsp + 8)
	inc 1, bc
	ld (xiy), bc
	stb_dri A, 0xfd, 0x1a, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1e0003a
	call SendEvent
	ldw (xsp + 12), 0x0
	ldw (xsp + 10), 0x0
	jr PsListBox_SelectUpd_CheckDone

PsListBox_SelectUpd_ScanItems:
	ld wa, (xsp + 12)
	extz xwa
	lda xde, (xsp + 26)
	ld (xsp + 14), xde
	add (xsp + 14), xwa
	jr PsListBox_SelectUpd_ScanLoop

PsListBox_SelectUpd_CheckPipe:
	cp a, 0x7c
	jr nz, PsListBox_SelectUpd_NextChar
	ld (xbc), 0x0
	incm 1, (xsp + 12)
	jr PsListBox_SelectUpd_NextItem

PsListBox_SelectUpd_NextChar:
	incm 1, (xsp + 12)

PsListBox_SelectUpd_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cps a, 0
	jr nz, PsListBox_SelectUpd_CheckPipe

PsListBox_SelectUpd_NextItem:
	incm 1, (xsp + 10)

PsListBox_SelectUpd_CheckDone:
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 38)
	ld wa, (xwa)
	cp (xsp + 10), wa
	jr ule, PsListBox_SelectUpd_ScanItems
	calr GetDialFocus
	stb_dri A, 0xfd, 0x1a, 0x01
	ld xwa, (xsp + 22)
	lda xiy, (xwa + 32)
	stb_dri B, 0xfd, 0x1e, 0x01
	lda xiz, (xwa + 28)
	ld xwa, (xsp + 4)
	ld a, (xwa + 34)
	ldb_erp A, 0xf0
	extz ix
	cpl_sri_rm XHL, 0xfd, 0x2a, 0x01
	jr nz, PsListBox_SelectUpd_DrawUnfocused
	ld xwa, (xiz)
	push xwa
	pushm (xiy)
	ld xwa, (xsp + 10)
	pushm (xwa + 22)
	pushw ix
	pushw 0x1
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	jrl PsListBox_ReturnZero

PsListBox_SelectUpd_DrawUnfocused:
	ld xwa, (xiz)
	push xwa
	pushm (xiy)
	ld xwa, (xsp + 28)
	pushm (xwa + 22)
	pushw ix
	pushw 0x0
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	stb_dri W, 0xfd, 0x1e, 0x01
	pushw 0xf2
	lds bc, 1
	lds de, 2
	calr DrawDesignFrame
	jrl PsListBox_ReturnZero

PsListBox_Reset:
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1c0000e
	jr PsListBox_SendEvent

PsListBox_GetCount:
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld hl, (xwa)
	exts xhl
	jr PsListBox_Return

PsListBox_SetIndex:
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld wa, (xwa)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x26, 0x01
	jr z, PsListBox_ReturnZero
	ld wa, (xhl + 36)
	extz xwa
	cpl_sri_mr XWA, 0xfd, 0x26, 0x01
	jr nc, PsListBox_ReturnZero
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1c0000e
	ld_sril XDE, (xsp + 0x0126)

PsListBox_SendEvent:
	call SendEvent
	jr PsListBox_ReturnZero

PsListBox_GetText:
	pushw	234
	pushw	41360
	ld	xwa, (xsp+298)
	push	xwa
	call	16713584
	inc	8, xsp
PsListBox_ReturnZero:
	lds32 xhl, 0
	jr PsListBox_Return

PsListBox_Default:
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc

PsListBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x2a, 0x01
	ret

AcListBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xwa
	cp xbc, 0x1e0003a
	jrl z, AcListBox_GetText
	cp xbc, 0x1c00018
	jrl z, AcListBox_ScrollDownInc
	cp xbc, 0x1c0001a
	jrl z, AcListBox_ScrollDownInc
	cp xbc, 0x1c00017
	jr z, AcListBox_ScrollUpDown
	cp xbc, 0x1c00019
	jr z, AcListBox_ScrollUpDown
	cp xbc, 0x1c00001
	jrl nz, AcListBox_Default
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	cpw (xiz + 46), 0x0
	jrl z, AcListBox_ReturnZero
	ld de, (xiz + 26)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00018
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00017
	calr SetDialDown
	lds wa, 1
	jrl AcListBox_EnableDials

AcListBox_ScrollUpDown:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0004d
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00019
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	calr SetDialDown
	lds wa, 1
	jr AcListBox_EnableDials

AcListBox_ScrollDownInc:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0004d
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	calr SetDialDown
	lds wa, 1

AcListBox_EnableDials:
	calr SetDialEnable
	jr AcListBox_ReturnZero

AcListBox_GetText:
	ld	xwa, (xsp+12)
	call	16408153
	ld	xwa, (xhl+42)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
AcListBox_ReturnZero:
	lds32 xhl, 0
	jr AcListBox_Return

AcListBox_Default:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc

AcListBox_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PsGridBoxProc:
	stb_dri L, 0xfd, 0xb2, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x46, 0x01
	stl_dri XBC, 0xfd, 0x4a, 0x01
	stl_dri XWA, 0xfd, 0x4e, 0x01
	ld_sril XBC, (xsp + 0x014a)
	cp xbc, 0x1c00018
	jrl z, PsGridBox_Scroll
	ld_sril XWA, (xsp + 0x014a)
	cp xwa, 0x1c0001a
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1c00017
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1c00019
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1c0000e
	jrl z, PsGridBox_Select
	cp xwa, 0x1c0000f
	jrl z, PsGridBox_Confirm
	cp xwa, 0x1c0000d
	jrl z, PsGridBox_Paint
	cp xwa, 0x1c0000c
	jrl z, PsGridBox_ShowHide
	cp xwa, 0x1c0000b
	jrl z, PsGridBox_ShowHide
	cp xwa, 0x1c00002
	jrl z, PsGridBox_Close
	cp xwa, 0x1c00001
	jr z, PsGridBox_Init
	sub xbc, 0x1e0008a
	cp xbc, 0x0
	jrl lt, PsGridBox_Default
	cp xbc, 0x7
	jrl gt, PsGridBox_Default
	add xbc, xbc
	add xbc, Data_SoundEditorCharsLayout_0x376
	ld bc, (xbc)
	lda_24 xix, (PsGridBox_Init)
	jp_ind 8, 0x07, 0xf0, 0xe4

	.include "ui/psgridbox_routines.s"
	.include "ui/ui_widget_defs.s"
IsPointOnScreen:
	cpw (xwa), 0x0
	jr lt, IsPointOnScreen_OutOfBounds
	cpw (xwa), 0x140
	jr ge, IsPointOnScreen_OutOfBounds
	ld wa, (xwa + 2)
	cps wa, 0
	jr lt, IsPointOnScreen_OutOfBounds
	cp wa, 0xf0
	jr lt, IsPointOnScreen_InBounds

IsPointOnScreen_OutOfBounds:
	lds hl, 0
	ret

IsPointOnScreen_InBounds:
	lds hl, 1
	ret

IsColorValid:
	cps wa, 0
	jr lt, IsColorValid_Check256
	cp wa, 0xff
	jr le, IsColorValid_Valid

IsColorValid_Check256:
	cp wa, 0x100
	jr lt, IsColorValid_Invalid
	cp wa, 0x100
	jr gt, IsColorValid_Invalid

IsColorValid_Valid:
	lds hl, 1
	ret

IsColorValid_Invalid:
	lds hl, 0
	ret

ClampColorToRange:
	ld hl, bc
	cps bc, 0
	ret lt
	cp bc, 0xff
	ret gt
	ret

DrawDesignBox_ByteData:
	.byte 0xef, 0x6e, 0x3e, 0xbf, 0x04, 0x52, 0xbf, 0x06
	.byte 0x61, 0xe8, 0x8e, 0x1e, 0x04, 0xd3, 0xdb, 0xd8
	.byte 0x66, 0x16, 0xd2, 0x4e, 0x04, 0x03, 0x3f, 0x00
	.byte 0x00, 0x66, 0x3a, 0xee, 0x88, 0xaf, 0x06, 0x21
	.byte 0x9f, 0x04, 0x22, 0x1e, 0x4b, 0x00, 0x68, 0x2d
	.byte 0x30, 0x0e, 0x00, 0x1e, 0xf6, 0xd1, 0xeb, 0x88
	.byte 0xf2, 0x6c, 0xce, 0xfa, 0x31, 0xb0, 0x61, 0xee
	.byte 0x8d, 0xb8, 0x04, 0x34, 0x95, 0x10, 0x95, 0x10
	.byte 0xaf, 0x06, 0x21, 0xe9, 0x8d, 0xb8, 0x08, 0x34
	.byte 0x95, 0x10, 0x95, 0x10, 0x9f, 0x04, 0x21, 0xb8
	.byte 0x0c, 0x51, 0x1e, 0xf7, 0xd0, 0x5e, 0xef, 0x66
	.byte 0x0e, 0xb8, 0x04, 0x33, 0xb8, 0x08, 0x31, 0x98
	.byte 0x0c, 0x22, 0xd2, 0x4e, 0x04, 0x03, 0x3f, 0x00
	.byte 0x00, 0xb0, 0xf6, 0xeb, 0x88, 0x1e, 0x01, 0x00
	.byte 0x0e, 0xbf, 0xcc, 0x37, 0x3e, 0xbf, 0x2e, 0x52
	.byte 0xbf, 0x30, 0x61, 0xbf, 0x34, 0x60, 0xbf, 0x14
	.byte 0x00, 0x00, 0x42, 0xff, 0xff, 0xff, 0xff, 0xaf
	.byte 0x30, 0x20, 0x90, 0x21, 0xaf, 0x34, 0x20, 0x90
	.byte 0xf1, 0x62, 0x02, 0xea, 0xa9, 0xbf, 0x0c, 0x62
	.byte 0x42, 0xff, 0xff, 0xff, 0xff, 0xaf, 0x30, 0x20
	.byte 0xe8, 0x62, 0xbf, 0x16, 0x60, 0xaf, 0x34, 0x20
	.byte 0xe8, 0x62, 0xbf, 0x1a, 0x60, 0xaf, 0x16, 0x20
	.byte 0x90, 0x21, 0xaf, 0x1a, 0x20, 0x90, 0x23, 0xdb
	.byte 0xf1, 0x62, 0x02, 0xea, 0xa9, 0xbf, 0x10, 0x62
	.byte 0xaf, 0x0c, 0x20, 0xe8, 0xcf, 0x01, 0x00, 0x00
	.byte 0x00, 0x6e, 0x0c, 0xaf, 0x30, 0x20, 0x90, 0x22
	.byte 0xaf, 0x34, 0x20, 0x90, 0xa2, 0x68, 0x0a, 0xaf
	.byte 0x34, 0x20, 0x90, 0x22, 0xaf, 0x30, 0x20, 0x90
	.byte 0xa2, 0xea, 0x13, 0xbf, 0x04, 0x62, 0xaf, 0x10
	.byte 0x20, 0xe8, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x6e
	.byte 0x06, 0xdb, 0xa1, 0xd9, 0x8b, 0x68, 0x02, 0xd9
	.byte 0xa3, 0xeb, 0x13, 0xbf, 0x08, 0x63, 0xaf, 0x04
	.byte 0x20, 0xe8, 0xe0, 0x6e, 0x08, 0xaf, 0x08, 0x20
	.byte 0xe8, 0xe0, 0x76, 0x27, 0x02, 0xaf, 0x34, 0x20
	.byte 0xe8, 0x8d, 0xbf, 0x2a, 0x34, 0x95, 0x10, 0x95
	.byte 0x10, 0xaf, 0x04, 0x20, 0xe8, 0xe0, 0x6e, 0x57
	.byte 0xe9, 0xa8, 0xaf, 0x08, 0x20, 0xe8, 0xcf, 0x00
	.byte 0x00, 0x00, 0x00, 0x71, 0xe1, 0x01, 0x8f, 0x14
	.byte 0x3f, 0x03, 0x63, 0x06, 0xbf, 0x14, 0x00, 0x00
	.byte 0x68, 0x2d, 0x8f, 0x14, 0x3f, 0x01, 0x6b, 0x24
	.byte 0xbf, 0x2a, 0x30, 0x98, 0x02, 0x22, 0xea, 0x13
	.byte 0xea, 0x8b, 0xeb, 0xee, 0x02, 0xea, 0x83, 0xeb
	.byte 0xee, 0x06, 0x90, 0x20, 0xe8, 0x13, 0xeb, 0x80
	.byte 0x42, 0x00, 0x3c, 0x04, 0x00, 0xe8, 0x82, 0x9f
	.byte 0x2e, 0x20, 0xb2, 0x41, 0x8f, 0x14, 0x61, 0xaf
	.byte 0x10, 0x20, 0x9f, 0x2c, 0x88, 0xe9, 0x61, 0xaf
	.byte 0x08, 0xf1, 0x62, 0xba, 0x78, 0x98, 0x01, 0xaf
	.byte 0x08, 0x20, 0xe8, 0xe0, 0x6e, 0x57, 0xe9, 0xa8
	.byte 0xaf, 0x04, 0x20, 0xe8, 0xcf, 0x00, 0x00, 0x00
	.byte 0x00, 0x71, 0x83, 0x01, 0x8f, 0x14, 0x3f, 0x03
	.byte 0x63, 0x06, 0xbf, 0x14, 0x00, 0x00, 0x68, 0x2d
	.byte 0x8f, 0x14, 0x3f, 0x01, 0x6b, 0x24, 0xbf, 0x2a
	.byte 0x30, 0x98, 0x02, 0x22, 0xea, 0x13, 0xea, 0x8b
	.byte 0xeb, 0xee, 0x02, 0xea, 0x83, 0xeb, 0xee, 0x06
	.byte 0x90, 0x20, 0xe8, 0x13, 0xeb, 0x80, 0x42, 0x00
	.byte 0x3c, 0x04, 0x00, 0xe8, 0x82, 0x9f, 0x2e, 0x20
	.byte 0xb2, 0x41, 0x8f, 0x14, 0x61, 0xaf, 0x0c, 0x20
	.byte 0x9f, 0x2a, 0x88, 0xe9, 0x61, 0xaf, 0x04, 0xf1
	.byte 0x62, 0xba, 0x78, 0x3a, 0x01, 0xbf, 0x2a, 0x30
	.byte 0xbf, 0x1e, 0x60, 0xaf, 0x08, 0x20, 0xaf, 0x04
	.byte 0xf0, 0x72, 0x97, 0x00, 0xaf, 0x04, 0x20, 0xe8
	.byte 0xec, 0x00, 0xaf, 0x08, 0x21, 0x1d, 0x31, 0x04
	.byte 0xff, 0xeb, 0x8e, 0xaf, 0x0c, 0x20, 0xee, 0x89
	.byte 0x1d, 0x7f, 0x02, 0xff, 0xbf, 0x0c, 0x63, 0xaf
	.byte 0x1e, 0x22, 0xea, 0x88, 0x90, 0x20, 0xe8, 0x13
	.byte 0xbf, 0x04, 0x60, 0xe8, 0xec, 0x00, 0xbf, 0x04
	.byte 0x60, 0x40, 0x00, 0x80, 0x00, 0x00, 0xaf, 0x04
	.byte 0x88, 0xe9, 0xa8, 0xaf, 0x08, 0x20, 0xe8, 0xcf
	.byte 0x00, 0x00, 0x00, 0x00, 0x71, 0xe8, 0x00, 0x8f
	.byte 0x14, 0x3f, 0x03, 0x63, 0x06, 0xbf, 0x14, 0x00
	.byte 0x00, 0x68, 0x2a, 0x8f, 0x14, 0x3f, 0x01, 0x6b
	.byte 0x21, 0x9a, 0x02, 0x20, 0xe8, 0x13, 0xe8, 0x8b
	.byte 0xeb, 0xee, 0x02, 0xe8, 0x83, 0xeb, 0xee, 0x06
	.byte 0x92, 0x20, 0xe8, 0x13, 0xeb, 0x80, 0x43, 0x00
	.byte 0x3c, 0x04, 0x00, 0xe8, 0x83, 0x9f, 0x2e, 0x20
	.byte 0xb3, 0x41, 0x8f, 0x14, 0x61, 0xaf, 0x0c, 0x20
	.byte 0xaf, 0x04, 0x88, 0xaf, 0x04, 0x20, 0xe8, 0xed
	.byte 0x00, 0xb2, 0x50, 0xaf, 0x10, 0x20, 0x9a, 0x02
	.byte 0x88, 0xe9, 0x61, 0xaf, 0x08, 0xf1, 0x62, 0xaf
	.byte 0x78, 0x94, 0x00, 0xaf, 0x08, 0x20, 0xe8, 0xec
	.byte 0x00, 0xaf, 0x04, 0x21, 0x1d, 0x31, 0x04, 0xff
	.byte 0xeb, 0x8e, 0xaf, 0x10, 0x20, 0xee, 0x89, 0x1d
	.byte 0x7f, 0x02, 0xff, 0xbf, 0x10, 0x63, 0xaf, 0x1e
	.byte 0x22, 0xea, 0x88, 0xb8, 0x02, 0x33, 0x93, 0x20
	.byte 0xe8, 0x13, 0xbf, 0x08, 0x60, 0xe8, 0xec, 0x00
	.byte 0xbf, 0x08, 0x60, 0x40, 0x00, 0x80, 0x00, 0x00
	.byte 0xaf, 0x08, 0x88, 0xe9, 0xa8, 0xaf, 0x04, 0x20
	.byte 0xe8, 0xcf, 0x00, 0x00, 0x00, 0x00, 0x61, 0x4f
	.byte 0x8f, 0x14, 0x3f, 0x03, 0x63, 0x06, 0xbf, 0x14
	.byte 0x00, 0x00, 0x68, 0x29, 0x8f, 0x14, 0x3f, 0x01
	.byte 0x6b, 0x20, 0x93, 0x20, 0xe8, 0x13, 0xe8, 0x8c
	.byte 0xec, 0xee, 0x02, 0xe8, 0x84, 0xec, 0xee, 0x06
	.byte 0x92, 0x20, 0xe8, 0x13, 0xec, 0x80, 0x44, 0x00
	.byte 0x3c, 0x04, 0x00, 0xe8, 0x84, 0x9f, 0x2e, 0x20
	.byte 0xb4, 0x41, 0x8f, 0x14, 0x61, 0xaf, 0x10, 0x20
	.byte 0xaf, 0x08, 0x88, 0xaf, 0x08, 0x20, 0xe8, 0xed
	.byte 0x00, 0xb3, 0x50, 0xaf, 0x0c, 0x20, 0x92, 0x88
	.byte 0xe9, 0x61, 0xaf, 0x04, 0xf1, 0x62, 0xb1, 0xbf
	.byte 0x22, 0x30, 0xaf, 0x1a, 0x21, 0x91, 0x21, 0xb8
	.byte 0x02, 0x51, 0xaf, 0x34, 0x21, 0x91, 0x21, 0xb0
	.byte 0x51, 0xaf, 0x30, 0x21, 0x91, 0x21, 0xb8, 0x04
	.byte 0x51, 0xaf, 0x16, 0x21, 0x91, 0x21, 0xb8, 0x06
	.byte 0x51, 0x1e, 0x0e, 0xd2, 0x5e, 0xbf, 0x34, 0x37
	.byte 0x0e
DrawDesignBox:	; SysData_FAD559
	dec 4, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawDesignBox_QueuedPath
	cpw_da (0x03044e), 0
	jr z, DrawDesignBox_DirectEpilogue
	ld xwa, xiz
	ld bc, (xsp + 6)
	ld de, (xsp + 4)
	calr DrawDesignBox_Impl
	jr DrawDesignBox_DirectEpilogue

DrawDesignBox_QueuedPath:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (DrawDesignBox_QueueCallback)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 6)
	ld (xwa + 12), bc
	ld bc, (xsp + 4)
	ld (xwa + 14), bc
	calr DisplayCmd_DequeueAndExecute

DrawDesignBox_DirectEpilogue:
	pop xiz
	inc 4, xsp
	ret

DrawDesignBox_QueueCallback:
	lda	xhl, (xwa+4)
	ld	bc, (xwa+12)
	ld	de, (xwa+14)
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop	sr
	push	xsp
	nop
	nop
	ret	z
	ld	xwa, xhl
	calr	1
	ret

DrawDesignBox_Impl:
	lda xsp, (xsp - 74)
	push xiz
	ld (xsp + 70), de
	ld (xsp + 72), bc
	ld (xsp + 74), xwa
	lds32 xwa, 0
	ld (xsp + 14), xwa
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 62)
	lds bc, 4
	ldirw
	ld wa, (xsp + 72)
	cpw (xsp + 72), 0xa8
	jr gt, DrawDesignBox_CheckStyleA0
	cpw (xsp + 72), 0xa1
	jrl ge, DrawDesignBox_PartGroupStyle

DrawDesignBox_CheckStyleA0:
	cp wa, 0xa0
	jrl z, DrawDesignBox_IconStyle
	cp wa, 0x88
	jr gt, DrawDesignBox_CheckStyle80
	cp wa, 0x81
	jrl ge, DrawDesignBox_PartGroupStyle

DrawDesignBox_CheckStyle80:
	cp wa, 0x80
	jrl z, DrawDesignBox_IconStyle
	lda xbc, (xsp + 36)
	ld xhl, xbc
	lda xde, (xsp + 28)
	ld xiy, xde
	cps wa, 0
	jr mi, Draw_StyledBoxWithFrame
	cp wa, 0xb
	jr le, Draw_DispatchByPartType
	sub wa, 0xb4
	cp wa, 0xc
	jr lt, Draw_StyledBoxWithFrame
	cp wa, 0x18
	jr gt, Draw_StyledBoxWithFrame

; Draw dispatch by part type
Draw_DispatchByPartType:
	add wa, wa
	lda_24 xix, (Str_No_0xB00)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (Draw_StyledBoxWithFrame)
	jp_ind 8, 0x07, 0xf0, 0xe0

Draw_StyledBoxWithFrame:
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	jrl DrawFunc_Epilogue74
	lda xwa, (xsp + 62)
	decm 1, (xwa + 4)
	decm 1, (xwa + 6)
	lda xwa, (xsp + 62)
	decm 1, (xwa + 4)
	decm 1, (xwa + 6)
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 62)
	lds bc, 0
	calr DrawFrame_Impl
	cpw (xsp + 72), 0x2
	jr nz, DrawDesignBox_After2Frame
	lda xwa, (xsp + 62)
	incm 1, (xwa + 2)
	decm 1, (xwa + 6)
	incm 1, (xwa)
	decm 1, (xwa + 4)
	lds bc, 0
	calr DrawFrame_Impl

DrawDesignBox_After2Frame:
	cpw (xsp + 72), 0x3
	jr nz, DrawDesignBox_After3Frame
	lda xwa, (xsp + 62)
	incm 2, (xwa + 2)
	decm 2, (xwa + 6)
	incm 2, (xwa)
	decm 2, (xwa + 4)
	lds bc, 0
	calr DrawFrame_Impl

DrawDesignBox_After3Frame:
	cpw (xsp + 72), 0x4
	jr nz, DrawDesignBox_4FrameCross
	lda xwa, (xsp + 50)
	lda xhl, (xsp + 62)
	lda xde, (xhl + 4)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xhl + 2)
	inc 1, bc
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	inc 1, de
	ld (xbc), de
	ld de, (xhl + 6)
	inc 1, de
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde + 6)
	inc 1, bc
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	lds de, 0
	calr DrawLine_Impl

DrawDesignBox_4FrameCross:
	cpw (xsp + 72), 0x5
	jrl nz, DrawFunc_Epilogue74
	lda xiy, (xsp + 62)
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 62)
	lda xhl, (xsp + 54)
	lda xde, (xhl + 4)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde)
	inc 2, bc
	ld (xwa + 4), bc
	ld bc, (xhl + 2)
	inc 2, bc
	ld (xwa + 2), bc
	ld bc, (xhl + 6)
	inc 2, bc
	ld (xwa + 6), bc
	lds bc, 0
	calr DrawFrame_Impl
	lda xwa, (xsp + 62)
	lda xde, (xsp + 54)
	ld bc, (xde)
	inc 2, bc
	ld (xwa), bc
	ld bc, (xde + 6)
	inc 1, bc
	ld (xwa + 2), bc
	lds bc, 0
	calr DrawFrame_Impl
	jrl DrawFunc_Epilogue74
	lds32 xwa, 1
	ld (xsp + 14), xwa
	lds32 xwa, 1
	add (xsp + 14), xwa
	cpw (xsp + 72), 0xc0
	jr z, DrawDesignBox_ColorsC0C1
	cpw (xsp + 72), 0xc1
	jr nz, DrawDesignBox_ColorsDefault

DrawDesignBox_ColorsC0C1:
	ldw (xsp + 4), 0xff
	ldw (xsp + 6), 0xf8
	jr DrawDesignBox_ApplyColors

DrawDesignBox_ColorsDefault:
	ldw (xsp + 4), 0xf8
	ldw (xsp + 6), 0xff

DrawDesignBox_ApplyColors:
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lds32 xwa, 0
	ld (xsp + 10), xwa
	ld xwa, (xsp + 14)
	cp xwa, 0x0
	jrl le, DrawFunc_Epilogue74

DrawDesignBox_BorderLoop:
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	lda xhl, (xde + 2)
	ld bc, (xhl)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde + 4)
	ld (xbc), de
	ld de, (xhl)
	ld (xbc + 2), de
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde + 4)
	ld (xwa), bc
	ld bc, (xde + 6)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xbc, (xsp + 46)
	lda xde, (xsp + 62)
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 6)
	ld (xbc + 2), wa
	lda xwa, (xsp + 50)
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	decm 1, (xbc + 2)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 62)
	incm 1, (xwa + 2)
	decm 1, (xwa + 6)
	incm 1, (xwa)
	decm 1, (xwa + 4)
	lds32 xwa, 1
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	cp xwa, (xsp + 14)
	jrl lt, DrawDesignBox_BorderLoop
	jrl DrawFunc_Epilogue74
	lds32 xwa, 1
	ld (xsp + 14), xwa
	lds32 xwa, 1
	add (xsp + 14), xwa
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lds32 xwa, 0
	ld (xsp + 10), xwa
	ld xwa, (xsp + 14)
	cp xwa, 0x0
	jrl le, DrawFunc_Epilogue74

DrawDesignBox_BorderC4C5Check:
	cpw (xsp + 72), 0xc4
	jr z, DrawDesignBox_C4C5FirstPass
	cpw (xsp + 72), 0xc5
	jr nz, DrawDesignBox_C6C7Style

DrawDesignBox_C4C5FirstPass:
	ld xwa, (xsp + 10)
	or xwa, xwa
	jr nz, DrawDesignBox_C4C5Highlight
	ldw (xsp + 4), 0x7
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr nz, DrawDesignBox_C4C5SingleWidth
	ldw (xsp + 4), 0xff

DrawDesignBox_C4C5SingleWidth:
	ldw (xsp + 6), 0x0
	jr ColorAttribute_SetupReturn

DrawDesignBox_C4C5Highlight:
	ldw (xsp + 4), 0xff
	ldw (xsp + 6), 0xf8
	jr ColorAttribute_SetupReturn

DrawDesignBox_C6C7Style:
	ld xwa, (xsp + 10)
	or xwa, xwa
	jr nz, DrawDesignBox_C6C7NonFirst
	ldw (xsp + 4), 0x0
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr z, DrawDesignBox_C6C7Shadow
	ldw (xsp + 6), 0x7
	jr ColorAttribute_SetupReturn

DrawDesignBox_C6C7NonFirst:
	ldw (xsp + 4), 0xf8

DrawDesignBox_C6C7Shadow:
	ldw (xsp + 6), 0xff

ColorAttribute_SetupReturn:
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	lda xhl, (xde + 2)
	ld bc, (xhl)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde + 4)
	ld (xbc), de
	ld de, (xhl)
	ld (xbc + 2), de
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde + 4)
	ld (xwa), bc
	ld bc, (xde + 6)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xbc, (xsp + 46)
	lda xde, (xsp + 62)
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 6)
	ld (xbc + 2), wa
	lda xwa, (xsp + 50)
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	decm 1, (xbc + 2)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 62)
	incm 1, (xwa + 2)
	decm 1, (xwa + 6)
	incm 1, (xwa)
	decm 1, (xwa + 4)
	lds32 xwa, 1
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	cp xwa, (xsp + 14)
	jrl lt, DrawDesignBox_BorderC4C5Check
	jrl DrawFunc_Epilogue74

DrawDesignBox_IconStyle:
	ldw (xsp + 16), 0x0
	ldw (xsp + 14), 0x0
	cpw (xsp + 72), 0xa0
	jr z, DrawDesignBox_IconA0
	cpw (xsp + 72), 0x80
	jr nz, DrawDesignBox_IconCheckFlags
	ldw (xsp + 12), 0x19
	ldw (xsp + 16), 0x1
	jr DrawDesignBox_IconGetFrameSize

DrawDesignBox_IconA0:
	ldw (xsp + 12), 0x14
	ldw (xsp + 14), 0x1

DrawDesignBox_IconCheckFlags:
	cpw (xsp + 16), 0x1
	jr z, DrawDesignBox_IconGetFrameSize
	cpw (xsp + 14), 0x1
	jr nz, DrawDesignBox_IconCheckLeft

DrawDesignBox_IconGetFrameSize:
	lda xbc, (xsp + 20)
	lda xde, (xsp + 18)
	ld wa, (xsp + 12)
	call GetFrameSPSize

DrawDesignBox_IconCheckLeft:
	cpw (xsp + 16), 0x0
	jr z, DrawDesignBox_IconCheckRight
	lda xwa, (xsp + 50)
	lda xhl, (xsp + 62)
	ld bc, (xhl)
	ld (xwa), bc
	ld de, (xhl + 2)
	ld bc, (xhl + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld bc, (xsp + 18)
	exts xbc
	divs bc, 0x2
	sub de, bc
	inc 1, de
	ld (xwa + 2), de
	ld bc, (xsp + 12)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl

DrawDesignBox_IconCheckRight:
	cpw (xsp + 14), 0x0
	jr z, DrawDesignBox_IconAdjustFrame
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 62)
	ld de, (xbc + 4)
	sub de, (xsp + 20)
	inc 1, de
	ld (xwa), de
	ld de, (xbc + 2)
	ld bc, (xbc + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld bc, (xsp + 18)
	exts xbc
	divs bc, 0x2
	sub de, bc
	inc 1, de
	ld (xwa + 2), de
	ld bc, (xsp + 12)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl

DrawDesignBox_IconAdjustFrame:
	lda xwa, (xsp + 62)
	incm 1, (xwa + 2)
	decm 1, (xwa + 6)
	cpw (xsp + 16), 0x0
	jr nz, DrawDesignBox_IconLeftWidth
	lds bc, 1
	jr DrawDesignBox_IconApplyAdjust

DrawDesignBox_IconLeftWidth:
	ld bc, (xsp + 20)

DrawDesignBox_IconApplyAdjust:
	add (xwa), bc
	ld bc, (xwa)
	ld (xsp + 50), bc
	lda xbc, (xwa + 4)
	cpw (xsp + 14), 0x0
	jr nz, DrawDesignBox_IconAdjustRight
	ld de, (xbc)
	dec 1, de
	ld (xbc), de
	jr DrawDesignBox_IconComputeFill

DrawDesignBox_IconAdjustRight:
	ld de, (xbc)
	sub de, (xsp + 20)
	ld (xbc), de

DrawDesignBox_IconComputeFill:
	ld (xsp + 46), de
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 64)
	ld bc, (xde)
	dec 1, bc
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	dec 1, de
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 68)
	ld bc, (xde)
	inc 1, bc
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	inc 1, de
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	lda xhl, (xsp + 62)
	ld bc, (xhl + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	ld (xbc + 2), de
	cpw (xsp + 16), 0x0
	jr nz, DrawDesignBox_IconLeftBorder
	ld de, (xhl)
	dec 1, de
	ld (xwa), de
	ld de, (xhl)
	dec 1, de
	ld (xbc), de
	lds de, 0
	calr DrawLine_Impl

DrawDesignBox_IconLeftBorder:
	cpw (xsp + 14), 0x0
	jrl nz, DrawFunc_Epilogue74
	lda xwa, (xsp + 50)
	lda xde, (xsp + 66)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	inc 1, de
	ld (xbc), de
	lds de, 0
	jrl DrawFunc_DrawLineAndReturn

DrawDesignBox_PartGroupStyle:
	ldw (xsp + 16), 0x0
	ldw (xsp + 14), 0x0
	ld wa, (xsp + 72)
	cpw (xsp + 72), 0xb
	jrl z, DrawPartGroup_StyleB
	cpw (xsp + 72), 0xa
	jrl z, DrawPartGroup_StyleA
	cpw (xsp + 72), 0x9
	jr z, DrawPartGroup_Style9
	cpw (xsp + 72), 0x8
	jr z, DrawPartGroup_Style8
	cpw (xsp + 72), 0x7
	jr z, DrawPartGroup_TableJump_DefaultCase
	sub wa, 0x81
	cps wa, 0
	jr lt, DrawPartGroup_TableJump_DefaultCase
	cps wa, 7
	jr le, DrawPartGroup_DispatchByType
	sub wa, 0x18
	cp wa, 0x8
	jr lt, DrawPartGroup_TableJump_DefaultCase
	cp wa, 0xf
	jr gt, DrawPartGroup_TableJump_DefaultCase

; DrawPartGroup dispatch by type
DrawPartGroup_DispatchByType:
	add wa, wa
	lda_24 xix, (Str_No_0xAE0)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (DrawPartGroup_TableJump_DefaultCase)
	jp_ind 8, 0x07, 0xf0, 0xe0

DrawPartGroup_TableJump_DefaultCase:
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	jrl DrawPartGroup_Loop

DrawPartGroup_Style8:
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	jrl DrawPartGroup_Loop

DrawPartGroup_Style9:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	jrl DrawPartGroup_Loop

DrawPartGroup_StyleA:
	ldw iz, 0xc
	ldw (xsp + 8), 0xd
	ldw (xsp + 10), 0xe
	ldi_erpw 0xfa, 0x0f, 0x00
	jrl DrawPartGroup_Loop

DrawPartGroup_StyleB:
	ldw iz, 0x10
	ldw (xsp + 8), 0x11
	ldw (xsp + 10), 0x12
	ldi_erpw 0xfa, 0x13, 0x00
	jrl DrawPartGroup_Loop
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x1a
	jrl DrawPartGroup_WithAltFlag
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x15
	jrl DrawPartGroup_WithFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x1b
	jrl DrawPartGroup_WithAltFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x16
	jrl DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x1c
	jrl DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x17
	jrl DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x1d
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x18
	jrl DrawPartGroup_WithFlag
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x1e
	jr DrawPartGroup_WithAltFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x1f
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x20
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x21

DrawPartGroup_WithAltFlag:
	ldw (xsp + 16), 0x1
	jr DrawPartGroup_Loop
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x22
	jr DrawPartGroup_WithFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x23
	jr DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x24
	jr DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x25

DrawPartGroup_WithFlag:
	ldw (xsp + 14), 0x1

DrawPartGroup_Loop:
	lda xbc, (xsp + 36)
	lda xde, (xsp + 28)
	ld wa, iz
	call GetFrameSPSize
	lda xbc, (xsp + 34)
	lda xde, (xsp + 26)
	ld wa, (xsp + 8)
	call GetFrameSPSize
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ld wa, (xsp + 10)
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	stw_erp WA, 0xfa
	call GetFrameSPSize
	cpw (xsp + 16), 0x1
	jr z, DrawPartGroup_CheckAltFlag
	cpw (xsp + 14), 0x1
	jr nz, DrawPartGroup_CopyBoxRect

DrawPartGroup_CheckAltFlag:
	lda xbc, (xsp + 20)
	lda xde, (xsp + 18)
	ld wa, (xsp + 12)
	call GetFrameSPSize

DrawPartGroup_CopyBoxRect:
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	cpw (xsp + 16), 0x0
	jr nz, DrawPartGroup_NoLeftFlag
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde + 2)
	inc 1, bc
	ld (xwa + 2), bc
	ld bc, iz
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	inc 1, bc
	ld (xwa), bc
	ld bc, (xde + 6)
	sub bc, (xsp + 22)
	ld (xwa + 2), bc
	stw_erp BC, 0xfa
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	incm 1, (xsp + 62)
	ld wa, (xsp + 36)
	inc 1, wa
	add (xsp + 54), wa
	jr DrawPartGroup_DrawSides

DrawPartGroup_NoLeftFlag:
	lda xwa, (xsp + 50)
	lda xhl, (xsp + 62)
	ld bc, (xhl)
	ld (xwa), bc
	ld de, (xhl + 2)
	ld bc, (xhl + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld bc, (xsp + 18)
	exts xbc
	divs bc, 0x2
	sub de, bc
	inc 1, de
	ld (xwa + 2), de
	ld bc, (xsp + 12)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	ld wa, (xsp + 20)
	add (xsp + 62), wa
	ld wa, (xsp + 20)
	add (xsp + 54), wa

DrawPartGroup_DrawSides:
	lda xhl, (xsp + 62)
	lda xbc, (xhl + 2)
	lda xde, (xhl + 4)
	cpw (xsp + 14), 0x0
	jr nz, DrawPartGroup_CenterRightIcon
	lda xwa, (xsp + 50)
	ld de, (xde)
	sub de, (xsp + 34)
	ld (xwa), de
	ld bc, (xbc)
	inc 1, bc
	ld (xwa + 2), bc
	ld bc, (xsp + 8)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 62)
	ld de, (xbc + 4)
	sub de, (xsp + 32)
	ld (xwa), de
	ld bc, (xbc + 6)
	sub bc, (xsp + 24)
	ld (xwa + 2), bc
	ld bc, (xsp + 10)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	decm 1, (xsp + 66)
	ld wa, (xsp + 34)
	inc 1, wa
	sub (xsp + 58), wa
	jr DrawPartGroup_FillAndBorder

DrawPartGroup_CenterRightIcon:
	lda xwa, (xsp + 50)
	ld de, (xde)
	sub de, (xsp + 20)
	inc 1, de
	ld (xwa), de
	ld de, (xbc)
	ld bc, (xhl + 6)
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	ld bc, (xsp + 18)
	exts xbc
	divs bc, 0x2
	sub de, bc
	inc 1, de
	ld (xwa + 2), de
	ld bc, (xsp + 12)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	ld wa, (xsp + 20)
	sub (xsp + 66), wa
	ld wa, (xsp + 20)
	sub (xsp + 58), wa

DrawPartGroup_FillAndBorder:
	lda xwa, (xsp + 62)
	ld bc, (xsp + 28)
	inc 1, bc
	add (xwa + 2), bc
	ld bc, (xsp + 22)
	inc 1, bc
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incm 1, (xwa + 2)
	ld xbc, (xsp + 74)
	ld bc, (xbc + 2)
	add bc, (xsp + 28)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	sub bc, (xsp + 24)
	dec 1, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	dec 1, bc
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xbc, (xsp + 50)
	cpw (xsp + 16), 0x0
	jr nz, DrawPartGroup_CheckLeftTopCorner
	ld xwa, (xsp + 74)
	ld wa, (xwa)
	add wa, (xsp + 36)
	inc 1, wa
	ld (xbc), wa
	jr DrawPartGroup_SetTopLeftX

DrawPartGroup_CheckLeftTopCorner:
	ld xwa, (xsp + 74)
	ld wa, (xwa)
	add wa, (xsp + 20)
	ld (xbc), wa

DrawPartGroup_SetTopLeftX:
	lda xbc, (xsp + 46)
	ld xwa, (xsp + 74)
	inc 4, xwa
	cpw (xsp + 14), 0x0
	jr nz, DrawPartGroup_CheckRightBR
	ld wa, (xwa)
	sub wa, (xsp + 34)
	dec 1, wa
	ld (xbc), wa
	jr DrawPartGroup_DrawBorderLines

DrawPartGroup_CheckRightBR:
	ld wa, (xwa)
	sub wa, (xsp + 20)
	ld (xbc), wa

DrawPartGroup_DrawBorderLines:
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 2)
	ld bc, (xde)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl + 2)
	add bc, (xsp + 28)
	inc 1, bc
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	sub de, (xsp + 24)
	dec 1, de
	ld (xbc + 2), de
	cpw (xsp + 16), 0x0
	jr nz, DrawPartGroup_DrawLeftBorder
	ld de, (xhl)
	ld (xwa), de
	ld de, (xhl)
	ld (xbc), de
	lds de, 0
	calr DrawLine_Impl

DrawPartGroup_DrawLeftBorder:
	cpw (xsp + 14), 0x0
	jrl nz, DrawFunc_Epilogue74
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	lds de, 0
	jrl DrawFunc_DrawLineAndReturn
	cpw (xsp + 72), 0xca
	jr z, DrawPartGroup_StyleCA
	ldw iz, 0x28
	ldw (xsp + 8), 0x29
	ldw (xsp + 10), 0x2a
	ldi_erpw 0xfa, 0x2b, 0x00
	ldw (xsp + 4), 0xff
	ldw (xsp + 6), 0xf8
	jr DrawPartGroup_DrawCAFrames

DrawPartGroup_StyleCA:
	ldw iz, 0x30
	ldw (xsp + 8), 0x31
	ldw (xsp + 10), 0x32
	ldi_erpw 0xfa, 0x33, 0x00
	ldw (xsp + 6), 0xff
	ldw (xsp + 4), 0xf8

DrawPartGroup_DrawCAFrames:
	ld wa, iz
	call GetFrameSPSize
	lda xbc, (xsp + 34)
	lda xde, (xsp + 26)
	ld wa, (xsp + 8)
	call GetFrameSPSize
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ld wa, (xsp + 10)
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	stw_erp WA, 0xfa
	call GetFrameSPSize
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ld bc, iz
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 6)
	sub bc, (xsp + 22)
	inc 1, bc
	ld (xwa + 2), bc
	stw_erp BC, 0xfa
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xbc, (xsp + 62)
	incm 2, (xbc)
	ld wa, (xsp + 36)
	add (xsp + 54), wa
	lda xwa, (xsp + 50)
	ld de, (xbc + 4)
	sub de, (xsp + 34)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 2)
	ld (xwa + 2), bc
	ld bc, (xsp + 8)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 62)
	ld de, (xbc + 4)
	sub de, (xsp + 32)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 6)
	sub bc, (xsp + 24)
	inc 1, bc
	ld (xwa + 2), bc
	ld bc, (xsp + 10)
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 62)
	decm 2, (xwa + 4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 22)
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incm 2, (xwa + 2)
	ld xbc, (xsp + 74)
	ld bc, (xbc + 2)
	add bc, (xsp + 28)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	sub bc, (xsp + 24)
	ld (xwa + 2), bc
	ld bc, (xde)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	add bc, (xsp + 36)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	sub de, (xsp + 34)
	ld (xbc), de
	inc 2, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incm 1, (xbc + 2)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc + 2), de
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	decm 1, (xbc + 2)
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl + 2)
	add bc, (xsp + 28)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	sub de, (xsp + 24)
	ld (xbc + 2), de
	ld de, (xhl)
	ld (xwa), de
	ld de, (xhl)
	ld (xbc), de
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa)
	lda xbc, (xsp + 38)
	incm 1, (xbc)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	ld de, (xsp + 6)
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa)
	lda xbc, (xsp + 38)
	decm 1, (xbc)
	ld de, (xsp + 6)
	jrl DrawFunc_DrawLineAndReturn
	ldw wa, 0x28
	ld xbc, xhl
	ld xde, xiy
	call GetFrameSPSize
	lda xbc, (xsp + 34)
	lda xde, (xsp + 26)
	ldw wa, 0x29
	call GetFrameSPSize
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ldw bc, 0x28
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xbc, (xsp + 62)
	incm 2, (xbc)
	ld wa, (xsp + 36)
	add (xsp + 54), wa
	lda xwa, (xsp + 50)
	ld de, (xbc + 4)
	sub de, (xsp + 34)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 2)
	ld (xwa + 2), bc
	ldw bc, 0x29
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 62)
	decm 2, (xwa + 4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incm 2, (xwa + 2)
	ld xbc, (xsp + 74)
	ld bc, (xbc + 2)
	add bc, (xsp + 28)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	add bc, (xsp + 36)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	sub de, (xsp + 34)
	ld (xbc), de
	inc 2, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	ldw de, 0xff
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incm 1, (xbc + 2)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	ld (xbc), de
	inc 6, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	decm 1, (xbc + 2)
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl + 2)
	add bc, (xsp + 28)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	dec 1, de
	ld (xbc + 2), de
	ld de, (xhl)
	ld (xwa), de
	ld de, (xhl)
	ld (xbc), de
	ldw de, 0xff
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa)
	lda xbc, (xsp + 38)
	incm 1, (xbc)
	decm 1, (xbc + 2)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa)
	lda xbc, (xsp + 38)
	decm 1, (xbc)
	ldw de, 0xf8
	jrl DrawFunc_DrawLineAndReturn
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ldw wa, 0x2a
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	ldw wa, 0x2b
	call GetFrameSPSize
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 6)
	sub bc, (xsp + 22)
	inc 1, bc
	ld (xwa + 2), bc
	ldw bc, 0x2b
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xbc, (xsp + 62)
	incm 2, (xbc)
	ld wa, (xsp + 30)
	add (xsp + 54), wa
	lda xwa, (xsp + 50)
	ld de, (xbc + 4)
	sub de, (xsp + 32)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 6)
	sub bc, (xsp + 24)
	inc 1, bc
	ld (xwa + 2), bc
	ldw bc, 0x2a
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 62)
	decm 2, (xwa + 4)
	ld bc, (xsp + 32)
	sub (xsp + 58), bc
	ld bc, (xsp + 22)
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	sub bc, (xsp + 24)
	ld (xwa + 2), bc
	ld bc, (xde)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	ld (xbc), de
	inc 2, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	ldw de, 0xff
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incm 1, (xbc + 2)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	add bc, (xsp + 30)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	sub de, (xsp + 32)
	ld (xbc), de
	inc 6, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	decm 1, (xbc + 2)
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	sub de, (xsp + 24)
	ld (xbc + 2), de
	ld de, (xhl)
	ld (xwa), de
	ld de, (xhl)
	ld (xbc), de
	ldw de, 0xff
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa)
	lda xbc, (xsp + 38)
	incm 1, (xbc)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa)
	lda xbc, (xsp + 38)
	decm 1, (xbc)
	incm 1, (xwa + 2)
	ldw de, 0xf8
	jrl DrawFunc_DrawLineAndReturn
	ldw wa, 0x2c
	ld xbc, xhl
	ld xde, xiy
	call GetFrameSPSize
	lda xbc, (xsp + 34)
	lda xde, (xsp + 26)
	ldw wa, 0x2d
	call GetFrameSPSize
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ldw wa, 0x2e
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	ldw wa, 0x2f
	call GetFrameSPSize
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ldw bc, 0x2c
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xde, (xsp + 62)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 6)
	sub bc, (xsp + 22)
	inc 1, bc
	ld (xwa + 2), bc
	ldw bc, 0x2f
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xbc, (xsp + 62)
	incm 2, (xbc)
	ld wa, (xsp + 36)
	add (xsp + 54), wa
	lda xwa, (xsp + 50)
	ld de, (xbc + 4)
	sub de, (xsp + 34)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 2)
	ld (xwa + 2), bc
	ldw bc, 0x2d
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 62)
	ld de, (xbc + 4)
	sub de, (xsp + 32)
	inc 1, de
	ld (xwa), de
	ld bc, (xbc + 6)
	sub bc, (xsp + 24)
	inc 1, bc
	ld (xwa + 2), bc
	ldw bc, 0x2e
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xwa, (xsp + 62)
	decm 2, (xwa + 4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 22)
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incm 2, (xwa + 2)
	ld xbc, (xsp + 74)
	ld bc, (xbc + 2)
	add bc, (xsp + 28)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	sub bc, (xsp + 24)
	ld (xwa + 2), bc
	ld bc, (xde)
	ld (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl)
	add bc, (xsp + 36)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 4)
	sub de, (xsp + 34)
	ld (xbc), de
	inc 2, xhl
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	ld (xbc + 2), de
	lds de, 7
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incm 1, (xbc + 2)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc + 2), de
	lds de, 0
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa + 2)
	lda xbc, (xsp + 38)
	decm 1, (xbc + 2)
	ldw de, 0xf8
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xhl, (xsp + 74)
	ld bc, (xhl + 2)
	add bc, (xsp + 28)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xhl + 6)
	sub de, (xsp + 24)
	ld (xbc + 2), de
	ld de, (xhl)
	ld (xwa), de
	ld de, (xhl)
	ld (xbc), de
	lds de, 7
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	incm 1, (xwa)
	lda xbc, (xsp + 38)
	incm 1, (xbc)
	ldw de, 0xff
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	lds de, 0
	calr DrawLine_Impl
	lda xiy, (xsp + 50)
	lda xix, (xsp + 42)
	ldiw
	ldiw
	lda xiy, (xsp + 46)
	lda xix, (xsp + 38)
	ldiw
	ldiw
	lda xwa, (xsp + 42)
	decm 1, (xwa)
	lda xbc, (xsp + 38)
	decm 1, (xbc)
	ldw de, 0xf8

DrawFunc_DrawLineAndReturn:
	calr DrawLine_Impl

DrawFunc_Epilogue74:
	pop xiz
	lda xsp, (xsp + 74)
	ret

Gfx_ImageDecodeByteData:
	dec	4, xsp
	push	xiz
	ldl_da	xbc, (0x030452)
	ld	(xsp+4), xbc
	ld	ix, (xwa+2)
	jr	59
	ld	bc, ix
	extz	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	bc, (xwa)
	exts	xbc
	add	xbc, xde
	lda_24	xde, (0x043c00)
	ld	xiz, xde
	add	xiz, xbc
	ld	iy, (xwa)
	jr	17
	ld	xhl, xiz
	ld	xbc, xiz
	sub	xbc, xde
	inc	1, xiz
	.byte 0xaf, 0x04, 0x81
	ld	c, (xbc)
	ld	(xhl), c
	inc	1, iy
	ld	bc, (xwa+4)
	cp	iy, bc
	jr	ule, -24
	inc	1, ix
	ld	bc, (xwa+6)
	cp	ix, bc
	jr	ule, -66
	calr	48943
	pop	xiz
	inc	4, xsp
	ret

Gfx_ClearFrameBuffers:
	pushw	38400
	pushw	0
	ld	xwa, 354304
	push	xwa
	call	16713757
	pushw	38400
	pushw	0
	ld	xwa, 392704
	push	xwa
	call	16713757
	pushw	1024
	pushw	0
	ld	xwa, 431104
	push	xwa
	call	16713757
	lda	xsp, (xsp+24)
	jrl	1950
Gfx_LoadSplashBMP:
	.byte 0xf3, 0xfd, 0xaa, 0xfb, 0x37, 0x2e, 0xf3, 0xfd
	.byte 0x4a, 0x04, 0x30, 0x41, 0x0e, 0x00, 0x00, 0x00
	.byte 0x1d, 0x67, 0x89, 0xf8, 0xdb, 0x8e, 0xde, 0xcf
	.byte 0x0e, 0x00, 0x7e, 0xfc, 0x01, 0x0b, 0x02, 0x00
	.byte 0x0b, 0xea, 0x00, 0x0b, 0x48, 0xae, 0xf3, 0xfd
	.byte 0x50, 0x04, 0x30, 0x38, 0x1d, 0xe4, 0x04, 0xff
	.byte 0xef, 0xc8, 0x0a, 0x00, 0x00, 0x00, 0xdb, 0xd8
	.byte 0x6e, 0x5a, 0xf3, 0xfd, 0x22, 0x04, 0x30, 0x41
	.byte 0x28, 0x00, 0x00, 0x00, 0x1d, 0x67, 0x89, 0xf8
	.byte 0xdb, 0x8e, 0xde, 0xcf, 0x28, 0x00, 0x7e, 0xc8
	.byte 0x01, 0xf3, 0xfd, 0x22, 0x04, 0x31, 0xa1, 0x20
	.byte 0xe8, 0xcf, 0x28, 0x00, 0x00, 0x00, 0x6e, 0x34
	.byte 0x99, 0x0c, 0x3f, 0x01, 0x00, 0x6e, 0x2d, 0x99
	.byte 0x0e, 0x3f, 0x08, 0x00, 0x6b, 0x26, 0xa9, 0x20
	.byte 0x20, 0xe8, 0xcf, 0x00, 0x01, 0x00, 0x00, 0x6b
	.byte 0x1b, 0xe3, 0xfd, 0x54, 0x04, 0x20, 0xbf, 0x1e
	.byte 0x60, 0x40, 0x36, 0x00, 0x00, 0x00, 0xaf, 0x1e
	.byte 0xa8, 0xaf, 0x1e, 0x20, 0xe8, 0xcf, 0x00, 0x04
	.byte 0x00, 0x00, 0x63, 0x06
FileIO_ControllerValidationFailed:
	ldw hl, 0x8047
	jrl SplashBMP_Return

SplashBMP_ValidateSize:
	lda xwa, (xsp + 34)
	ld xbc, (xsp + 30)
	call FileIO_ReadBlock
	ld iz, hl
	ld wa, iz
	exts xwa
	cp xwa, (xsp + 30)
	jrl nz, SplashScreen_Return
	ld xwa, (xsp + 30)
	srl xwa, 2
	ld (xsp + 30), xwa
	ld xde, 0x69400
	ld xbc, 0x69400
	ld xhl, 0x69800

SplashBMP_ClearPalette:
	ld xwa, 0xff000000
	stl_dpi XWA, 0xe6
	cp xbc, xhl
	jr c, SplashBMP_ClearPalette
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xwa, (xsp + 30)
	cp xwa, 0x0
	jr ule, SplashBMP_ReadInfoHeader
	lda xhl, (xsp + 34)

SplashBMP_DecodePalette:
	ld xbc, (xsp + 6)
	sll xbc, 2
	ld xwa, xbc
	ld xix, xhl
	add xix, xwa
	ld a, (xix)
	lds32 xix, 0
	ldb_erp A, 0xf0
	sll xix, 8
	ld xwa, xbc
	ld xiy, xhl
	add xiy, xwa
	lds32 xwa, 0
	ld a, (xiy + 1)
	add xix, xwa
	sll xix, 8
	ld xwa, xhl
	add xwa, xbc
	ld a, (xwa + 2)
	extz wa
	extz xwa
	add xix, xwa
	stl_dpi XIX, 0xea
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xbc, (xsp + 6)
	cp xbc, (xsp + 30)
	jr c, SplashBMP_DecodePalette

SplashBMP_ReadInfoHeader:
	.byte 0xf3, 0xfd, 0x22, 0x04, 0x31, 0xa9, 0x04, 0x20
	.byte 0xbf, 0x0e, 0x60, 0xa9, 0x08, 0x20, 0xbf, 0x02
	.byte 0x60, 0x40, 0x08, 0x00, 0x00, 0x00, 0x99, 0x0e
	.byte 0x50, 0xe8, 0x12, 0xbf, 0x1e, 0x60, 0xe8, 0xec
	.byte 0x02, 0xe8, 0x89, 0xe8, 0x69, 0xaf, 0x0e, 0x80
	.byte 0x1d, 0x31, 0x04, 0xff, 0xbf, 0x12, 0x63, 0xeb
	.byte 0xec, 0x02, 0xbf, 0x12, 0x63, 0xeb, 0x88, 0xaf
	.byte 0x1e, 0x21, 0x1d, 0x7f, 0x02, 0xff, 0x2b, 0x1d
	.byte 0xa3, 0x06, 0xff, 0xef, 0x62, 0xbf, 0x1e, 0x63
	.byte 0xaf, 0x1e, 0x20, 0xbf, 0x1a, 0x60, 0xaf, 0x02
	.byte 0x20, 0xe8, 0xcf, 0xf0, 0x00, 0x00, 0x00, 0x62
	.byte 0x46, 0xe8, 0xa8, 0xbf, 0x06, 0x60, 0xaf, 0x02
	.byte 0x20, 0xe8, 0xca, 0xf0, 0x00, 0x00, 0x00, 0x62
	.byte 0x2e
SplashBMP_SkipExcessRows:
	ld xwa, (xsp + 30)
	ld xbc, (xsp + 18)
	call FileIO_ReadBlock
	ld iz, hl
	ld wa, iz
	exts xwa
	cp xwa, (xsp + 18)
	jr z, SplashBMP_CheckSkipCount
	ld xwa, (xsp + 30)
	push xwa
	jr SplashBMP_FreeOnError

SplashBMP_CheckSkipCount:
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xwa, (xsp + 2)
	sub xwa, 0xf0
	cp (xsp + 6), xwa
	jr lt, SplashBMP_SkipExcessRows

SplashBMP_ClampHeight:
	ld xwa, 0xf0
	ld (xsp + 2), xwa

SplashBMP_PrepareRowBuffer:
	ld	xwa, 320
	ld	(xsp+30), xwa
	ld	xbc, (xsp+2)
	dec	1, xbc
	ld	xwa, (xsp+30)
	call	16712319
	ld	(xsp+30), xhl
	add	xhl, 354304
	ld	(xsp+22), xhl
	lds32	xwa, 0
	ld	(xsp+6), xwa
	ld	xwa, (xsp+2)
	cp	xwa, 0
	jrl	le, 205
SplashBMP_ReadRowLoop:
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 18)
	call FileIO_ReadBlock
	ld iz, hl
	ld wa, iz
	exts xwa
	cp xwa, (xsp + 18)
	jr z, SplashBMP_ProcessRow
	ld xwa, (xsp + 26)
	push xwa

SplashBMP_FreeOnError:
	call	16712469
	inc	4, xsp
SplashScreen_Return:
	ld hl, iz
	jrl SplashBMP_Return

SplashBMP_ProcessRow:
	ldw_sri0 DE, (xsp + 0x0430)
	ld xwa, (xsp + 26)
	ld xbc, (xsp + 18)
	calr Gfx_ProcessSplashData
	ld xwa, (xsp + 14)
	cp xwa, 0x140
	jr lt, SplashBMP_WideImage
	pushw 0x140
	ld xwa, (xsp + 28)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	jr SplashBMP_CopyToFramebuffer

SplashBMP_WideImage:
	lds32	xwa, 0
	ld	(xsp+10), xwa
	ld	xbc, (xsp+14)
	ld	xwa, 320
	call	16712753
	cp	xhl, 0
	jr	le, 51
SplashBMP_TileNarrow:
	.byte 0xaf, 0x0e, 0x20, 0x28, 0xaf, 0x1c, 0x20, 0x38
	.byte 0xaf, 0x10, 0x20, 0xaf, 0x14, 0x21, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x1c, 0x83, 0x3b, 0x1d, 0xbc
	.byte 0x05, 0xff, 0xbf, 0x0a, 0x37, 0xe8, 0xa9, 0xaf
	.byte 0x0a, 0x88, 0xaf, 0x0e, 0x21, 0x40, 0x40, 0x01
	.byte 0x00, 0x00, 0x1d, 0x31, 0x04, 0xff, 0xaf, 0x0a
	.byte 0xfb, 0x61, 0xcd
SplashBMP_CopyRemainder:
	.byte 0xaf, 0x0a, 0x20, 0xaf, 0x0e, 0x21, 0x1d, 0x7f
	.byte 0x02, 0xff, 0x40, 0x40, 0x01, 0x00, 0x00, 0xeb
	.byte 0xa0, 0x28, 0xaf, 0x1c, 0x20, 0x38, 0xaf, 0x1c
	.byte 0x83, 0x3b
SplashBMP_CopyToFramebuffer:
	.byte 0x1d, 0xbc, 0x05, 0xff, 0xbf, 0x0a, 0x37, 0x40
	.byte 0x40, 0x01, 0x00, 0x00, 0xaf, 0x16, 0xa8, 0xe8
	.byte 0xa9, 0xaf, 0x06, 0x88, 0xaf, 0x06, 0x20, 0xaf
	.byte 0x02, 0xf0, 0x71, 0x33, 0xff
SplashBMP_PadRows:
	ld xbc, (xsp + 2)
	cp xbc, 0xf0
	jr ge, SplashBMP_Finish
	ld xwa, 0x140
	add (xsp + 30), xwa
	ld xwa, 0x56800
	ld (xsp + 26), xwa
	ld xwa, (xsp + 30)
	add xwa, 0x56800
	ld (xsp + 22), xwa
	ld (xsp + 6), xbc
	cp xbc, 0xf0
	jr ge, SplashBMP_Finish

SplashBMP_PadCopyLoop:
	pushw	320
	ld	xwa, (xsp+28)
	push	xwa
	ld	xwa, (xsp+28)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	ld	xwa, 320
	add	(xsp+26), xwa
	add	(xsp+22), xwa
	lds32	xwa, 1
	add	(xsp+6), xwa
	ld	xwa, (xsp+6)
	cp	xwa, 240
	jr	lt, -45
SplashBMP_Finish:
	calr Gfx_DecodeImageToBuffer
	calr Flash_SaveSplashScreen
	lds wa, 2
	calr ChangePalette
	lds hl, 1

SplashBMP_Return:
	popw iz
	stb_dri L, 0xfd, 0x56, 0x04
	ret

Gfx_ProcessSplashData:
	.byte 0xbf, 0xe4, 0x37, 0x3e, 0xbf, 0x16, 0x52, 0xbf
	.byte 0x18, 0x61, 0xbf, 0x1c, 0x60, 0x9f, 0x16, 0x3f
	.byte 0x18, 0x00, 0x76, 0x66, 0x01, 0x46, 0x08, 0x00
	.byte 0x00, 0x00, 0x9f, 0x16, 0x56, 0xde, 0x88, 0xe8
	.byte 0x12, 0xaf, 0x18, 0x21, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xbf, 0x12, 0x63, 0x9f, 0x16, 0x3f, 0x01, 0x00
	.byte 0x66, 0x73, 0x9f, 0x16, 0x3f, 0x04, 0x00, 0x7e
	.byte 0x41, 0x01, 0xbf, 0x08, 0x56, 0xaf, 0x12, 0x20
	.byte 0xbf, 0x04, 0x60, 0x2b, 0x1d, 0xa3, 0x06, 0xff
	.byte 0xbf, 0x10, 0x63, 0xaf, 0x10, 0x21, 0xbf, 0x0c
	.byte 0x61, 0xaf, 0x14, 0x20, 0x28, 0xaf, 0x20, 0x20
	.byte 0x38, 0x39, 0x1d, 0xbc, 0x05, 0xff, 0xbf, 0x0c
	.byte 0x37, 0xe9, 0xa8, 0xaf, 0x12, 0x20, 0xe8, 0xcf
	.byte 0x00, 0x00, 0x00, 0x00, 0x62, 0x30
SplashData_4bppLoop:
	ld xde, xbc
	add xde, (xsp + 28)
	ld xix, (xsp + 10)
	ld a, (xix)
	and a, 0xf0
	srl a, 4
	ld (xde), a
	ld xhl, xbc
	inc 1, xhl
	add xhl, (xsp + 28)
	ldb_spi E, 0xf0
	ld (xsp + 10), xix
	and e, 0xf
	ld (xhl), e
	ld wa, (xsp + 8)
	extz xwa
	add xbc, xwa
	cp xbc, (xsp + 4)
	jr lt, SplashData_4bppLoop

SplashData_4bppFree:
	ld xwa, (xsp + 14)
	push xwa
	jrl SplashData_FreeTempBuffer

SplashData_1bppSetup:
	ld	(xsp+8), iz
	ld	xwa, (xsp+18)
	ld	(xsp+4), xwa
	pushw	hl
	call	16713379
	ld	(xsp+16), xhl
	ld	xbc, (xsp+16)
	ld	(xsp+12), xbc
	ld	xwa, (xsp+20)
	pushw	wa
	ld	xwa, (xsp+32)
	push	xwa
	push	xbc
	call	16713148
	lda	xsp, (xsp+12)
	lds32	xbc, 0
	ld	xwa, (xsp+18)
	cp	xwa, 0
	jrl	le, 151
SplashData_1bppLoop:
	ld xde, xbc
	add xde, (xsp + 28)
	ld xix, (xsp + 10)
	ld a, (xix)
	and a, 0x80
	srl a, 7
	ld (xde), a
	ld xde, xbc
	inc 1, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x40
	srl a, 6
	ld (xde), a
	ld xde, xbc
	inc 2, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x20
	srl a, 5
	ld (xde), a
	ld xde, xbc
	inc 3, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x10
	srl a, 4
	ld (xde), a
	ld xde, xbc
	inc 4, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x8
	srl a, 3
	ld (xde), a
	ld xde, xbc
	inc 5, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x4
	srl a, 2
	ld (xde), a
	ld xde, xbc
	inc 6, xde
	add xde, (xsp + 28)
	ld a, (xix)
	and a, 0x2
	srl a, 1
	ld (xde), a
	ld xhl, xbc
	inc 7, xhl
	add xhl, (xsp + 28)
	ldb_spi E, 0xf0
	ld (xsp + 10), xix
	and e, 0x1
	ld (xhl), e
	ld wa, (xsp + 8)
	extz xwa
	add xbc, xwa
	cp xbc, (xsp + 4)
	jrl lt, SplashData_1bppLoop

SplashData_1bppFree:
	ld xwa, (xsp + 14)
	push xwa

SplashData_FreeTempBuffer:
	call	16712469
	inc	4, xsp
SplashData_Epilogue:
	pop xiz
	lda xsp, (xsp + 28)
	ret

Gfx_DecodeImageToBuffer:
	stb_dri L, 0xfd, 0xd4, 0xfb
	push xiz
	stb_dri A, 0xfd, 0x30, 0x02
	ld (xsp + 32), xbc
	ld xwa, (xsp + 32)
	stb_dri W, 0xe1, 0x00, 0x02
	ld (xsp + 40), xwa

ImageDecode_ClearPaletteLoop:
	stiw_dsp 0xe5, 0x00, 0x00
	cp xbc, xwa
	jr c, ImageDecode_ClearPaletteLoop
	ld xhl, 0x56800
	lds ix, 0

ImageDecode_RowLoop:
	lds iy, 0

ImageDecode_PixelLoop:
	ldb_spi C, 0xec
	extz bc
	add bc, bc
	ld xwa, (xsp + 32)
	inc_sriw 1, 0x07, 0xe0, 0xe4
	inc 1, iy
	cp iy, 0x140
	jr lt, ImageDecode_PixelLoop
	inc 1, ix
	cp ix, 0xf0
	jr lt, ImageDecode_RowLoop
	stb_dri W, 0xfd, 0x30, 0x01
	ld (xsp + 28), xwa
	ldb c, 0x0
	ld xde, (xsp + 28)
	ld xwa, xde
	stb_dri W, 0xe1, 0x00, 0x01
	ld (xsp + 44), xwa

ImageDecode_SecondPassSetup:
	lda_dpi XHL, 0xe8
	inc 1, c
	cp xde, xwa
	jr c, ImageDecode_SecondPassSetup
	ldw (xsp + 18), 0x0
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 40)

ImageDecode_CountNonZero:
	cpw (xwa), 0x0
	jr z, ImageDecode_CheckNextEntry
	incm 1, (xsp + 18)

ImageDecode_CheckNextEntry:
	inc 2, xwa
	cp xwa, xbc
	jr c, ImageDecode_CountNonZero
	ld xbc, 0x100

ImageDecode_PaletteReduceLoop:
	ld	xwa, xbc
	ld	xbc, 1000000
	call	16712319
	ld	xwa, xhl
	ld	xbc, 1300000
	call	16712753
	ld	bc, hl
	exts	xbc
	ld	xwa, xbc
	cp	xbc, 10
	jr	z, 16
	cp	xwa, 9
	jr	z, 8
	or	xwa, xwa
	jr	nz, 9
	lds32	xbc, 1
	jr	5
PaletteReduce_SpecialCase:
	ld xbc, 0xb

PaletteReduce_StartSortPass:
	lds32 xwa, 0
	ld (xsp + 20), xwa
	ld xwa, 0x100
	sub xwa, xbc
	ld (xsp + 24), xwa
	lds32 xhl, 0
	ld xwa, (xsp + 24)
	cp xwa, 0x0
	jr le, PaletteReduce_CheckDone

PaletteReduce_SortCompare:
	ld xiz, xhl
	add xiz, xbc
	ld (xsp + 40), xhl
	ld xwa, xhl
	add xwa, xwa
	ld xix, (xsp + 32)
	add xix, xwa
	ld (xsp + 36), xiz
	ld xwa, xiz
	add xwa, xwa
	ld xiy, (xsp + 32)
	add xiy, xwa
	ld wa, (xiy)
	ld de, (xix)
	cp de, wa
	jr nc, PaletteReduce_NoSwap
	ld (xix), wa
	ld (xiy), de
	ld xix, xhl
	add xix, (xsp + 28)
	ld e, (xix)
	add xiz, (xsp + 28)
	ld a, (xiz)
	ld (xix), a
	ld (xiz), e
	ld xix, (xsp + 40)
	sll xix, 2
	add xix, 0x69400
	ld xwa, (xix)
	ld xiy, (xsp + 36)
	sll xiy, 2
	add xiy, 0x69400
	ld xde, (xiy)
	ld (xix), xde
	ld (xiy), xwa
	lds32 xwa, 1
	add (xsp + 20), xwa

PaletteReduce_NoSwap:
	inc 1, xhl
	cp xhl, (xsp + 24)
	jr lt, PaletteReduce_SortCompare

PaletteReduce_CheckDone:
	ld xwa, (xsp + 20)
	or xwa, xwa
	jrl nz, ImageDecode_PaletteReduceLoop
	cp xbc, 0x1
	jrl gt, ImageDecode_PaletteReduceLoop
	lda xwa, (xsp + 48)
	ld (xsp + 32), xwa
	ldb c, 0x0
	ld xde, (xsp + 28)
	ld xhl, (xsp + 44)

PaletteReduce_RemapPixels:
	ldb_spi A, 0xe8
	ldb_erp A, 0xf0
	extz ix
	ld b, c
	ld xwa, (xsp + 32)
	lda_dri XDE, 0x07, 0xe0, 0xf0
	inc 1, c
	cp xde, xhl
	jr c, PaletteReduce_RemapPixels
	cpw (xsp + 18), 0xc0
	jrl le, ImageDecode_CopyPaletteToDAC
	ld xwa, 0xc0
	ld (xsp + 4), xwa
	ld wa, (xsp + 18)
	exts xwa
	ld (xsp + 36), xwa
	cp xwa, 0xc0
	jrl le, ImageDecode_CopyPaletteToDAC

PaletteReduce_HighColorReduce:
	ld xwa, 0x7fffffff
	ld (xsp + 12), xwa
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

PaletteReduce_FindClosest:
	.byte 0xaf, 0x08, 0x20, 0xe8, 0xee, 0x02, 0xe8, 0xc8
	.byte 0x00, 0x94, 0x06, 0x00, 0xa0, 0x20, 0xbf, 0x2c
	.byte 0x60, 0xe8, 0xcc, 0x00, 0xff, 0x00, 0x00, 0xe8
	.byte 0xef, 0x08, 0xe8, 0x8a, 0xaf, 0x04, 0x20, 0xe8
	.byte 0xee, 0x02, 0xe8, 0xc8, 0x00, 0x94, 0x06, 0x00
	.byte 0xa0, 0x20, 0xbf, 0x28, 0x60, 0xe8, 0xcc, 0x00
	.byte 0xff, 0x00, 0x00, 0xe8, 0xef, 0x08, 0xe8, 0x89
	.byte 0xea, 0xa1, 0xe9, 0x88, 0x1d, 0x7f, 0x02, 0xff
	.byte 0xbf, 0x18, 0x63, 0xaf, 0x2c, 0x22, 0xea, 0xcc
	.byte 0xff, 0x00, 0x00, 0x00, 0xaf, 0x28, 0x21, 0xe9
	.byte 0xcc, 0xff, 0x00, 0x00, 0x00, 0xea, 0xa1, 0xe9
	.byte 0x88, 0x1d, 0x7f, 0x02, 0xff, 0xbf, 0x14, 0x63
	.byte 0xaf, 0x18, 0x20, 0xaf, 0x14, 0x88, 0xaf, 0x2c
	.byte 0x20, 0xe8, 0xcc, 0x00, 0x00, 0xff, 0x00, 0xe8
	.byte 0xef, 0x00, 0xaf, 0x28, 0x21, 0xe9, 0xcc, 0x00
	.byte 0x00, 0xff, 0x00, 0xe9, 0xef, 0x00, 0xe8, 0xa1
	.byte 0xe9, 0x88, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x14
	.byte 0x83, 0xaf, 0x0c, 0xfb, 0x62, 0x09, 0xbf, 0x0c
	.byte 0x63, 0xaf, 0x08, 0x20, 0xbf, 0x10, 0x60
PaletteReduce_UpdateMinDist:
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xc0
	jrl lt, PaletteReduce_FindClosest
	ld xwa, (xsp + 4)
	add xwa, (xsp + 28)
	ld c, (xwa)
	extz bc
	ld xwa, (xsp + 16)
	ld e, a
	ld xwa, (xsp + 32)
	lda_dri XIY, 0x07, 0xe0, 0xe4
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 36)
	jrl lt, PaletteReduce_HighColorReduce

ImageDecode_CopyPaletteToDAC:
	ld xde, 0x696fc
	ld xbc, 0x6977c
	lds32 xwa, 0
	ld (xsp + 4), xwa

ImageDecode_PaletteCopyLoop:
	ld xwa, (xde)
	ld (xbc), xwa
	dec 4, xde
	dec 4, xbc
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp xwa, 0xc0
	jr lt, ImageDecode_PaletteCopyLoop
	ld xhl, 0x56800
	lds ix, 0

ImageDecode_ProcessRowsOuter:
	lds iy, 0
	ld xbc, xhl

ImageDecode_ProcessPixels:
	ld e, (xbc)
	extz de
	ld xwa, (xsp + 32)
	ldb_sri A, 0x07, 0xe0, 0xe8
	ld (xbc), a
	cp (xbc), 0xc0
	jr nc, ImageDecode_PixelHighBank
	addmi8 (xhl), 0x20
	jr ImageDecode_PixelNext

ImageDecode_PixelHighBank:
	cp (xhl), 0xe0
	jr nc, ImageDecode_PixelNext
	ld (xhl), 0x0

ImageDecode_PixelNext:
	inc 1, xhl
	inc 1, xbc
	inc 1, iy
	cp iy, 0x140
	jr lt, ImageDecode_ProcessPixels
	inc 1, ix
	cp ix, 0xf0
	jr lt, ImageDecode_ProcessRowsOuter
	pop xiz
	stb_dri L, 0xfd, 0x2c, 0x04
	ret

Flash_SaveSplashScreen:
	lds wa, 1
	ld xbc, 0x56800
	ld xde, 0x3c0000
	call Flash_EraseSectorAndWrite
	ld xwa, 0x3d0000
	push xwa
	lds wa, 1
	ld xbc, 0x66800
	ldw de, 0x3000
	call FlashWrite
	ret

CaptureLcd:
	.byte 0xf3, 0xfd, 0xba, 0xfb, 0x37, 0x2e, 0xf3, 0xfd
	.byte 0x3a, 0x04, 0x30, 0x0b, 0xea, 0x00, 0x0b, 0x4c
	.byte 0xae, 0x38, 0x1d, 0x70, 0x07, 0xff, 0xf3, 0xfd
	.byte 0x42, 0x04, 0x31, 0x40, 0x36, 0x30, 0x01, 0x00
	.byte 0xb9, 0x02, 0x60, 0xb9, 0x06, 0x02, 0x00, 0x00
	.byte 0xb9, 0x08, 0x02, 0x00, 0x00, 0x40, 0x36, 0x04
	.byte 0x00, 0x00, 0xb9, 0x0a, 0x60, 0xf3, 0xfd, 0x1a
	.byte 0x04, 0x31, 0x40, 0x28, 0x00, 0x00, 0x00, 0xb1
	.byte 0x60, 0x40, 0x40, 0x01, 0x00, 0x00, 0xb9, 0x04
	.byte 0x60, 0x40, 0xf0, 0x00, 0x00, 0x00, 0xb9, 0x08
	.byte 0x60, 0xb9, 0x0c, 0x02, 0x01, 0x00, 0xb9, 0x0e
	.byte 0x02, 0x08, 0x00, 0xe8, 0xa8, 0xb9, 0x10, 0x60
	.byte 0x40, 0x00, 0x2c, 0x01, 0x00, 0xb9, 0x14, 0x60
	.byte 0xe8, 0xa8, 0xb9, 0x18, 0x60, 0xb9, 0x1c, 0x60
	.byte 0x40, 0x00, 0x01, 0x00, 0x00, 0xb9, 0x20, 0x60
	.byte 0xb9, 0x24, 0x60, 0xe2, 0x4a, 0x04, 0x03, 0x20
	.byte 0x38, 0x0b, 0xea, 0x00, 0x0b, 0x50, 0xae, 0xbf
	.byte 0x12, 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf
	.byte 0x14, 0x37, 0xe8, 0xa9, 0xe2, 0x4a, 0x04, 0x03
	.byte 0x88, 0x1d, 0x13, 0x91, 0xf8, 0x1d, 0x70, 0x94
	.byte 0xf8, 0xbf, 0x02, 0x30, 0x41, 0x5e, 0xae, 0xea
	.byte 0x00, 0x1d, 0xba, 0x87, 0xf8, 0xdb, 0xd8, 0x7e
	.byte 0x12, 0x01, 0xf3, 0xfd, 0x3a, 0x04, 0x30, 0x41
	.byte 0x0e, 0x00, 0x00, 0x00, 0x1d, 0x1b, 0x8a, 0xf8
	.byte 0xeb, 0xcf, 0x0e, 0x00, 0x00, 0x00, 0x7e, 0xf7
	.byte 0x00, 0xf3, 0xfd, 0x12, 0x04, 0x30, 0x41, 0x28
	.byte 0x00, 0x00, 0x00, 0x1d, 0x1b, 0x8a, 0xf8, 0xeb
	.byte 0xcf, 0x28, 0x00, 0x00, 0x00, 0x7e, 0xe0, 0x00
	.byte 0xde, 0xa8, 0xe2, 0x94, 0xef, 0x03, 0x20, 0xe8
	.byte 0xe0, 0x66, 0x4d
CaptureLcd_WritePaletteOr94:
	ld wa, iz
	call Table_LookupDword
	ld de, iz
	sla de, 2
	lda xwa, (xsp + 18)
	ld xbc, xhl
	and xbc, 0xff0000	; is this a mask for Red?
	srl xbc, 0
	lda_dri XHL, 0x07, 0xe0, 0xe8
	ld bc, iz
	sla bc, 2
	stb_dri W, 0x07, 0xe0, 0xe4
	ld xbc, xhl
	and xbc, 0xff00	; is this a mask for Green?
	srl xbc, 8
	ld (xwa + 1), c
	and xhl, 0xff	; is this a mask for Blue?
	ld (xwa + 2), l
	ld (xwa + 3), 0x0
	inc 1, iz
	cp iz, 0x100
	jr lt, CaptureLcd_WritePaletteOr94
	jr CaptureLcd_WritePixelData

CaptureLcd_WritePaletteNoOr94:
	ld wa, iz
	call Table_LookupDword
	ld de, iz
	sla de, 2
	lda xwa, (xsp + 18)
	ld xbc, xhl
	and xbc, 0xff0000	; is this a mask for Red?
	srl xbc, 0
	lda_dri XHL, 0x07, 0xe0, 0xe8
	ld bc, iz
	sla bc, 2
	stb_dri W, 0x07, 0xe0, 0xe4
	ld xbc, xhl
	and xbc, 0xff00	; is this a mask for Green?
	srl xbc, 8
	ld (xwa + 1), c
	and xhl, 0xff	; is this a mask for Blue?
	ld (xwa + 2), l
	ld (xwa + 3), 0x0
	inc 1, iz
	cp iz, 0x100
	jr lt, CaptureLcd_WritePaletteNoOr94

CaptureLcd_WritePixelData:
	lda xwa, (xsp + 18)
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	cp xhl, 0x400
	jr nz, FileIO_ClosePath
	ldw iz, 0xef

CaptureLcd_WriteRowLoop:
	ld wa, iz
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	lda_24 xwa, (0x043c00)
	add xwa, xbc
	ld xbc, 0x140
	call FileIO_WriteByte_Impl
	cp xhl, 0x140
	jr z, CaptureLcd_NextRow

FileIO_ClosePath:
	call FileIO_CloseHandle

CaptureLcd_WriteFailed:
	lds hl, 0
	jr CaptureLcd_Epilogue

CaptureLcd_NextRow:
	sub iz, 0x1
	jr ge, CaptureLcd_WriteRowLoop
	call FileIO_CloseHandle
	lds hl, 1

CaptureLcd_Epilogue:
	popw iz
	stb_dri L, 0xfd, 0x46, 0x04
	ret

ChangeWall:
	pushw iz
	ld iz, wa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ChangeWall_QueuedPath
	ld wa, iz
	calr ChangeWall_Impl
	jr ChangeWall_Epilogue

ChangeWall_QueuedPath:
	lds wa, 6
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (ChangeWall_QueueCallback)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DisplayCmd_DequeueAndExecute

ChangeWall_Epilogue:
	popw iz
	ret

ChangeWall_QueueCallback:
	ld	wa, (xwa+4)
	jr	0

ChangeWall_Impl:
	stw_da (0x03ef9c), xwa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, Str_No_0xB4C
	add xwa, xbc
	ld xwa, (xwa)
	stl_da (0x03ef98), xwa
	stl_da (0x030452), xwa
	ret

ChangeWallPalette:
	pushw iz
	ld iz, wa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ChangeWallPalette_QueuedPath
	ld wa, iz
	calr ChangeWallPalette_Impl
	jr ChangeWallPalette_Epilogue

ChangeWallPalette_QueuedPath:
	lds wa, 6
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (ChangeWallPalette_QueueCallback)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DisplayCmd_DequeueAndExecute

ChangeWallPalette_Epilogue:
	popw iz
	ret

ChangeWallPalette_QueueCallback:
	ld	wa, (xwa+4)
	jr	0

ChangeWallPalette_Impl:
	push xiz
	ld iz, wa
	ldw_da xwa, (0x03ef9c)
	cps wa, 2
	jr z, WallPalette_Done
	cps wa, 0
	jr nz, WallPalette_SetupLoop
	inc 1, iz

WallPalette_SetupLoop:
	ldi_erpw 0xfa, 0xe0, 0x00

WallPalette_IterateEntries:
	stw_erp BC, 0xfa
	sub bc, 0xe0
	ld wa, iz
	call GetWallPaletteRGB
	ld xbc, xhl
	stw_erp WA, 0xfa
	call SetPaletteRGB
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0xf0, 0x00
	jr c, WallPalette_IterateEntries
	stiw_da (0x030462), 0x0001

WallPalette_Done:
	pop xiz
	ret

; =============================================================================
; ChangePalette - Switch VGA DAC palette
;
; Loads a new 256-color palette from the palette table at 0xeaae66.
; Each palette entry in the table is 10 bytes. The function iterates
; over all 256 DAC entries, loading RGB values from the selected palette
; and writing them to VGA DAC registers.
;
; Input:
;   WA = palette index (low byte selects palette from table)
;
; Key addresses:
;   0xeaae66 - Palette table base (10 bytes per palette entry)
;   0x03ef94 - Current palette data pointer (cached)
;   0x03ef9e - Current palette index (cached)
;   0x030460 - Palette update flag (set to 1 to trigger VRAM update)
;
; The palette loop at UIRender_IterateCallbacks iterates 0x20..0xE0 (palette entries),
; looking up each entry's RGB values via a secondary table at 0x03ef14.
; =============================================================================
ChangePalette:
	pushw iz
	ld iz, wa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ChangePalette_QueuedPath
	ld wa, iz
	calr ChangePalette_Impl
	jr ChangePalette_Epilogue

ChangePalette_QueuedPath:
	lds wa, 6
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (ChangePalette_QueueCallback)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DisplayCmd_DequeueAndExecute

ChangePalette_Epilogue:
	popw iz
	ret

ChangePalette_QueueCallback:
	ld	wa, (xwa+4)
	jr	0

ChangePalette_Impl:
	push xiz
	ld iz, wa
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	lda_24 xwa, (Str_No_0xB50)
	add xwa, xbc
	ld xwa, (xwa)
	stl_da (0x03ef94), xwa
	ldi_erpw 0xfa, 0x20, 0x00

UIRender_IterateCallbacks:
	stw_erp WA, 0xfa
	stw_erp BC, 0xfa
	extz xbc
	sll xbc, 2
	addda32_24 xbc, (0x03ef94)
	ld xbc, (xbc)
	call SetPaletteRGB
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0xe0, 0x00
	jr c, UIRender_IterateCallbacks
	stw_da (0x03ef9e), xiz
	stiw_da (0x030460), 0x0001
	pop xiz
	ret

UIRender_RetStub1:
	ret

UIRender_RetStub2:
	ret

; =============================================================================
; PaletteBankRotate - Palette bank rotation fade effect
;
; Creates a fade effect by rotating pixel color indices through palette banks.
; The KN5000 uses 16 palette banks of 16 colors each (0x00-0x0f, 0x10-0x1f,
; ..., 0xe0-0xef). This function:
;
; 1. Saves OFFSCREEN_BUFFER_1 (0x43c00) -> temp buffer at 0x56800 (full screen)
; 2. Saves next 38400 words -> temp at 0x5fe00
; 3. Iterates over all 76800 pixels (320×240):
;    - If pixel >= 0xe0: subtract 0x90 (wrap to lower bank)
;    - If pixel < 0xe0: add 0x10 (shift to next higher bank)
; 4. Saves modified buffer -> 0x69800 and 0x72e00
;
; This shifts all pixels one palette bank forward, creating a brightness
; or color transition when combined with palette interpolation. The effect
; is applied uniformly across the entire screen buffer.
;
; Screen iteration: outer loop DE=0..0xEF (rows), inner loop HL=0..0x13F (cols)
; =============================================================================
PaletteBankRotate:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, PaletteBankRotate_Impl
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (PaletteBankRotate_0x18)
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr PaletteBankRotate_Impl

PaletteBankRotate_Impl:
	push	xiz
	lda_24	xwa, (277504)
	ld	xiz, xwa
	pushw	38400
	push	xwa
	ld	xwa, 354304
	push	xwa
	call	16713148
	add	xiz, 38400
	pushw	38400
	push	xiz
	ld	xwa, 392704
	push	xwa
	call	16713148
	lda	xsp, (xsp+20)
	lda_24	xwa, (277504)
	ld	xbc, xwa
	lds	de, 0
PaletteBankRotate_RowLoop:
	lds hl, 0

PaletteBankRotate_ColLoop:
	cp (xbc), 0xe0
	jr c, PaletteBankRotate_LowBank
	submi8 (xbc), 0x90
	jr PaletteBankRotate_NextCol

PaletteBankRotate_LowBank:
	addmi8 (xbc), 0x10

PaletteBankRotate_NextCol:
	inc	1, xbc
	inc	1, hl
	cp	hl, 320
	jr	lt, -23
	inc	1, de
	cp	de, 240
	jr	lt, -33
	ld	xiz, xwa
	pushw	38400
	push	xwa
	ld	xwa, 432128
	push	xwa
	call	16713148
	add	xiz, 38400
	pushw	38400
	push	xiz
	ld	xwa, 470528
	push	xwa
	call	16713148
	lda	xsp, (xsp+20)
	pop	xiz
	ret
ClipBlit_Replace:
	; --- VRAM display rendering function pair 1: wrapper (FAF3E0-FAF41D) ---
	dec	2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ClipBlit_Replace_Deferred
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ClipBlit_Replace_Impl
	jr t, ClipBlit_Replace_Return
ClipBlit_Replace_Deferred:
	ldw wa, 0x000a
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24	xbc, (ClipBlit_Replace_ParamBlock)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld bc, (xsp + 4)
	ld (xwa + 8), bc
	calr DisplayCmd_DequeueAndExecute
ClipBlit_Replace_Return:
	pop xiz
	inc	2, xsp
	ret
ClipBlit_Replace_ParamBlock:
	; --- Callback stub (FAF41E-FAF427) ---
	lda xde, (xwa + 4)
	ld bc, (xwa + 8)
	ld xwa, xde
	jr t, ClipBlit_Replace_Impl
ClipBlit_Replace_Impl:
	; --- Main rendering routine 1 (FAF428-FAF541) ---
	lda	xsp, (xsp-28)
	push xiz
	ld (xsp + 28), xwa
	ld (xsp + 6), bc
	add (xsp + 6), bc
	ld wa, (xsp + 6)
	ld (xsp + 4), wa
	ld xwa, (xsp + 28)
	ld wa, (xwa)
	ld qiz, wa
	sub wa, bc
	ld qiz, wa
	cp	qiz, 0
	jr ge, ClipBlit_Replace_ClipRight
	ld wa, qiz
	add (xsp + 4), wa
	ld	qiz, 0
	jr t, ClipBlit_Replace_ClipY
ClipBlit_Replace_ClipRight:
	ld wa, qiz
	add wa, (xsp + 6)
	cp wa, 0x0140
	jr lt, ClipBlit_Replace_ClipY
	ldw (xsp + 4), 0x013f
	ld wa, qiz
	sub (xsp + 4), wa
ClipBlit_Replace_ClipY:
	ld xwa, (xsp + 28)
	ld iz, (xwa + 2)
	sub iz, bc
	jr ge, ClipBlit_Replace_ClipBottom
	add (xsp + 6), iz
	lds	iz, 0
	jr t, ClipBlit_Replace_CalcVRAMAddr
ClipBlit_Replace_ClipBottom:
	ld wa, iz
	add wa, (xsp + 6)
	cp wa, 0x00f0
	jr lt, ClipBlit_Replace_CalcVRAMAddr
	ldw (xsp + 6), 0x00ef
	sub (xsp + 6), iz
ClipBlit_Replace_CalcVRAMAddr:
	ld de, iz
	exts xde
	ld xbc, xde
	sll xbc, 2
	add xbc, xde
	sll xbc, 6
	.byte 0xf3
	reti
	.byte 0xe4
	swi	2
	.byte 0x33
	lda_24	xwa, (0x043c00)
	add xwa, xhl
	ld (xsp + 16), xwa
	ld xwa, 0x00056800
	ld (xsp + 12), xwa
	ld wa, qiz
	exts xwa
	add xbc, xwa
	add (xsp + 12), xbc
	ld (xsp + 8), xde
	jr t, ClipBlit_Replace_ScanlineCond
ClipBlit_Replace_ScanlineLoop:
	.byte 0xaf, 0x1c, 0x20, 0x98, 0x02, 0x20, 0xe8, 0x13
	.byte 0xaf, 0x08, 0x21, 0xe8, 0xa1, 0x29, 0x1d, 0x61
	.byte 0x08, 0xff, 0xdb, 0x83, 0xf2, 0x94, 0xae, 0xea
	.byte 0x30, 0xd3, 0x07, 0xe0, 0xec, 0x22, 0x31, 0x1e
	.byte 0x00, 0xda, 0xa1, 0xaf, 0x12, 0x20, 0xf3, 0x07
	.byte 0xe0, 0xe4, 0x33, 0xaf, 0x0e, 0x20, 0xe9, 0x13
	.byte 0xe8, 0x81, 0xda, 0x82, 0x2a, 0x39, 0x3b, 0x1d
	.byte 0xbc, 0x05, 0xff, 0xbf, 0x0c, 0x37, 0x40, 0x40
	.byte 0x01, 0x00, 0x00, 0xaf, 0x0c, 0x88, 0xaf, 0x10
	.byte 0x88, 0xe8, 0xa9, 0xaf, 0x08, 0x88
ClipBlit_Replace_ScanlineCond:
	ld de, iz
	add de, (xsp + 6)
	ld wa, de
	exts xwa
	cp (xsp + 8), xwa
	jr c, ClipBlit_Replace_ScanlineLoop
	lda xwa, (xsp + 20)
	ld (xwa + 2), iz
	ld bc, qiz
	ld (xwa), bc
	ld bc, qiz
	add bc, (xsp + 4)
	ld (xwa + 4), bc
	ld (xwa + 6), de
	calr	45605
	pop xiz
	lda	xsp, (xsp+28)
	ret
ClipBlit_Direct:
	; --- VRAM display rendering function pair 2: wrapper (FAF542-FAF57F) ---
	dec	2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ClipBlit_Direct_Deferred
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ClipBlit_Direct_Impl
	jr t, ClipBlit_Direct_Return
ClipBlit_Direct_Deferred:
	ldw wa, 0x000a
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24	xbc, (ClipBlit_Direct_ParamBlock)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld bc, (xsp + 4)
	ld (xwa + 8), bc
	calr DisplayCmd_DequeueAndExecute
ClipBlit_Direct_Return:
	pop xiz
	inc	2, xsp
	ret
ClipBlit_Direct_ParamBlock:
	; --- Callback stub 2 (FAF580-FAF589) ---
	lda xde, (xwa + 4)
	ld bc, (xwa + 8)
	ld xwa, xde
	jr t, ClipBlit_Direct_Impl
ClipBlit_Direct_Impl:
	; --- Main rendering routine 2 (FAF58A-FAF673) ---
	lda	xsp, (xsp-26)
	pushw iz
	ld (xsp + 6), bc
	add (xsp + 6), bc
	ld de, (xsp + 6)
	ld (xsp + 4), de
	ld de, (xwa)
	sub de, bc
	ld (xsp + 2), de
	cpw (xsp + 2), 0x0000
	jr ge, ClipBlit_Direct_ClipRight
	ld de, (xsp + 2)
	add (xsp + 4), de
	ldw (xsp + 2), 0x0000
	jr t, ClipBlit_Direct_ClipY
ClipBlit_Direct_ClipRight:
	ld de, (xsp + 2)
	add de, (xsp + 6)
	cp de, 0x0140
	jr lt, ClipBlit_Direct_ClipY
	ldw (xsp + 4), 0x013f
	ld de, (xsp + 2)
	sub (xsp + 4), de
ClipBlit_Direct_ClipY:
	ld iz, (xwa + 2)
	sub iz, bc
	jr ge, ClipBlit_Direct_ClipBottom
	add (xsp + 6), iz
	lds	iz, 0
	jr t, ClipBlit_Direct_CalcVRAMAddr
ClipBlit_Direct_ClipBottom:
	ld wa, iz
	add wa, (xsp + 6)
	cp wa, 0x00f0
	jr lt, ClipBlit_Direct_CalcVRAMAddr
	ldw (xsp + 6), 0x00ef
	sub (xsp + 6), iz
ClipBlit_Direct_CalcVRAMAddr:
	ld de, iz
	exts xde
	ld xbc, xde
	sll xbc, 2
	add xbc, xde
	sll xbc, 6
	ld wa, (xsp + 2)
	lda_rr	xhl, xbc, wa
	lda_24	xwa, (0x043c00)
	add xwa, xhl
	ld (xsp + 16), xwa
	ld xwa, 0x00069800
	ld (xsp + 12), xwa
	ld wa, (xsp + 2)
	exts xwa
	add xbc, xwa
	add (xsp + 12), xbc
	ld (xsp + 8), xde
	jr t, ClipBlit_Direct_ScanlineCond
ClipBlit_Direct_ScanlineLoop:
	ld	wa, (xsp+4)
	pushw	wa
	ld	xwa, (xsp+14)
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	ld	xwa, 320
	add	(xsp+12), xwa
	add	(xsp+16), xwa
	lds32	xwa, 1
	add	(xsp+8), xwa
ClipBlit_Direct_ScanlineCond:
	ld de, iz
	add de, (xsp + 6)
	ld wa, de
	exts xwa
	cp (xsp + 8), xwa
	jr c, ClipBlit_Direct_ScanlineLoop
	lda xwa, (xsp + 20)
	ld (xwa + 2), iz
	ld bc, (xsp + 2)
	ld (xwa), bc
	ld bc, (xsp + 2)
	add bc, (xsp + 4)
	ld (xwa + 4), bc
	ld (xwa + 6), de
	calr	45299
	popw iz
	lda	xsp, (xsp+26)
	ret


ColorBlit:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ColorBlit_Deferred
	ldb_da a, (0x03efa8)
	stb_da (0x03efaa), a
	cpw_da (0x03044e), 0
	jr z, ColorBlit_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit_Impl
	jr ColorBlit_Return

ColorBlit_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (ColorBlit_CallbackBlock)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ldb_da c, (0x03efa8)
	ld (xwa + 14), c
	calr DisplayCmd_DequeueAndExecute

ColorBlit_Return:
	pop xiz
	inc 2, xsp
	ret

ColorBlit_CallbackBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	stb_da	(0x03efaa), c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop	sr
	push	xsp
	nop
	nop
	ret	z
	ld	bc, de
	calr	1
	ret

ColorBlit_Impl:
	dec 8, xsp
	push xiz
	lda xhl, (xwa + 2)
	cpw (xhl), 0x0
	jr ge, ColorBlit_ClampTop
	ldw (xhl), 0x0

ColorBlit_ClampTop:
	cpw (xwa), 0x0
	jr ge, ColorBlit_ClampLeft
	ldw (xwa), 0x0

ColorBlit_ClampLeft:
	lda xde, (xwa + 4)
	ld (xsp + 8), xde
	cpw (xde), 0x140
	jr lt, ColorBlit_ClampRight
	ld xde, (xsp + 8)
	ldw (xde), 0x13f

ColorBlit_ClampRight:
	lda xde, (xwa + 6)
	ld (xsp + 4), xde
	cpw (xde), 0xf0
	jr lt, ColorBlit_ClampBottom
	ld xde, (xsp + 4)
	ldw (xde), 0xef

ColorBlit_ClampBottom:
	ld ix, (xhl)
	cp bc, 0xf7
	jrl z, ColorBlit_PopReturn
	ldb_da e, (0x03efaa)
	cps e, 2
	jrl z, ColorBlit_Mode2_Entry
	cps e, 1
	jrl z, ColorBlit_Mode1_Entry
	cps e, 0
	jrl nz, ColorBlit_Epilogue
	ld hl, ix
	cp bc, 0xf5
	jr z, ColorBlit_ModeF5_Entry
	ld xde, (xsp + 4)
	cp ix, (xde)
	jrl gt, ColorBlit_Epilogue

ColorBlit_Mode0_RowLoop:
	ld de, hl
	exts xde
	ld xix, xde
	sll xix, 2
	add xix, xde
	sll xix, 6
	ld de, (xwa)
	exts xde
	add xde, xix
	lda_24 xiz, (0x043c00)
	add xiz, xde
	ld ix, (xwa)
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr gt, ColorBlit_Mode0_NextRow

ColorBlit_Mode0_PixelLoop:
	andmi8 (xiz), 0x60
	ld de, bc
	and de, 0x9f
	add (xiz), e
	ld iy, bc
	and iy, 0x80
	ld e, (xiz)
	and e, 0x80
	extz de
	cp de, iy
	jr z, ColorBlit_Mode0_PixelSignOK
	xormi8 (xiz), 0x60

ColorBlit_Mode0_PixelSignOK:
	inc 1, xiz
	inc 1, ix
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr le, ColorBlit_Mode0_PixelLoop

ColorBlit_Mode0_NextRow:
	inc 1, hl
	ld xde, (xsp + 4)
	cp hl, (xde)
	jr le, ColorBlit_Mode0_RowLoop
	jrl ColorBlit_Epilogue

ColorBlit_ModeF5_Entry:
	ld xbc, (xsp + 4)
	cp ix, (xbc)
	jrl gt, ColorBlit_Epilogue

ColorBlit_ModeF5_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xde
	lda_24 xiy, (0x043c00)
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	addda32_24 xiz, (0x030452)
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_ModeF5_NextRow

ColorBlit_ModeF5_PixelLoop:
	andmi8 (xiy), 0x60
	ld c, (xiz)
	and c, 0x9f
	add (xiy), c
	ld e, (xiz)
	and e, 0x80
	ld c, (xiy)
	and c, 0x80
	cp c, e
	jr z, ColorBlit_ModeF5_PixelSignOK
	xormi8 (xiy), 0x60

ColorBlit_ModeF5_PixelSignOK:
	inc 1, xiy
	inc 1, xiz
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit_ModeF5_PixelLoop

ColorBlit_ModeF5_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit_ModeF5_RowLoop
	jrl ColorBlit_Epilogue

ColorBlit_Mode1_Entry:
	ld hl, ix
	ld xbc, (xsp + 4)
	cp ix, (xbc)
	jrl gt, ColorBlit_Epilogue

ColorBlit_Mode1_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xde
	lda_24 xde, (0x043c00)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_Mode1_NextRow

ColorBlit_Mode1_PixelLoop:
	bitm 7, (xde)
	jr z, ColorBlit_Mode1_SetBit5
	resm 5, (xde)
	jr ColorBlit_Mode1_NextPixel

ColorBlit_Mode1_SetBit5:
	setm 5, (xde)

ColorBlit_Mode1_NextPixel:
	inc 1, xde
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit_Mode1_PixelLoop

ColorBlit_Mode1_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit_Mode1_RowLoop
	jr ColorBlit_Epilogue

ColorBlit_Mode2_Entry:
	ld hl, ix
	ld xbc, (xsp + 4)
	cp ix, (xbc)
	jr gt, ColorBlit_Epilogue

ColorBlit_Mode2_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xde
	lda_24 xde, (0x043c00)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_Mode2_NextRow

ColorBlit_Mode2_PixelLoop:
	bitm 7, (xde)
	jr z, ColorBlit_Mode2_SetBit6
	resm 6, (xde)
	jr ColorBlit_Mode2_NextPixel

ColorBlit_Mode2_SetBit6:
	setm 6, (xde)

ColorBlit_Mode2_NextPixel:
	inc 1, xde
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit_Mode2_PixelLoop

ColorBlit_Mode2_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit_Mode2_RowLoop

ColorBlit_Epilogue:
	calr SetChangeRect

ColorBlit_PopReturn:
	pop xiz
	inc 8, xsp
	ret

ColorBlit2:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, ColorBlit2_Deferred
	ldb_da a, (0x03efa8)
	stb_da (0x03efaa), a
	cpw_da (0x03044e), 0
	jr z, ColorBlit2_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit2_Impl
	jr ColorBlit2_Return

ColorBlit2_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, (ColorBlit2_CallbackBlock)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ldb_da c, (0x03efa8)
	ld (xwa + 14), c
	calr DisplayCmd_DequeueAndExecute

ColorBlit2_Return:
	pop xiz
	inc 2, xsp
	ret

ColorBlit2_CallbackBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	stb_da	(0x03efaa), c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop	sr
	push	xsp
	nop
	nop
	ret	z
	ld	bc, de
	calr	1
	ret

ColorBlit2_Impl:
	dec 8, xsp
	push xiz
	lda xhl, (xwa + 2)
	cpw (xhl), 0x0
	jr ge, ColorBlit2_ClampTop
	ldw (xhl), 0x0

ColorBlit2_ClampTop:
	cpw (xwa), 0x0
	jr ge, ColorBlit2_ClampLeft
	ldw (xwa), 0x0

ColorBlit2_ClampLeft:
	lda xde, (xwa + 4)
	ld (xsp + 8), xde
	cpw (xde), 0x140
	jr lt, ColorBlit2_ClampRight
	ld xde, (xsp + 8)
	ldw (xde), 0x13f

ColorBlit2_ClampRight:
	lda xde, (xwa + 6)
	ld (xsp + 4), xde
	cpw (xde), 0xf0
	jr lt, ColorBlit2_ClampBottom
	ld xde, (xsp + 4)
	ldw (xde), 0xef

ColorBlit2_ClampBottom:
	ld ix, (xhl)
	cp bc, 0xf7
	jrl z, ColorBlit2_PopReturn
	ldb_da e, (0x03efaa)
	cps e, 2
	jrl z, ColorBlit2_Mode2_Entry
	cps e, 1
	jrl z, ColorBlit2_Mode1_Entry
	cps e, 0
	jrl nz, ColorBlit2_Epilogue
	ld hl, ix
	cp bc, 0xf5
	jr z, ColorBlit2_ModeF5_Entry
	ld xde, (xsp + 4)
	cp ix, (xde)
	jrl gt, ColorBlit2_Epilogue

ColorBlit2_Mode0_RowLoop:
	ld de, hl
	exts xde
	ld xix, xde
	sll xix, 2
	add xix, xde
	sll xix, 6
	ld de, (xwa)
	exts xde
	add xde, xix
	lda_24 xiz, (0x043c00)
	add xiz, xde
	ld ix, (xwa)
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr gt, ColorBlit2_Mode0_NextRow

ColorBlit2_Mode0_PixelLoop:
	andmi8 (xiz), 0x60
	ld de, bc
	and de, 0x9f
	add (xiz), e
	ld iy, bc
	and iy, 0x80
	ld e, (xiz)
	and e, 0x80
	extz de
	cp de, iy
	jr z, ColorBlit2_Mode0_PixelSignOK
	xormi8 (xiz), 0x60

ColorBlit2_Mode0_PixelSignOK:
	inc 1, xiz
	inc 1, ix
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr le, ColorBlit2_Mode0_PixelLoop

ColorBlit2_Mode0_NextRow:
	inc 1, hl
	ld xde, (xsp + 4)
	cp hl, (xde)
	jr le, ColorBlit2_Mode0_RowLoop
	jrl ColorBlit2_Epilogue

ColorBlit2_ModeF5_Entry:
	ld xbc, (xsp + 4)
	cp ix, (xbc)
	jrl gt, ColorBlit2_Epilogue

ColorBlit2_ModeF5_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xde
	lda_24 xiy, (0x043c00)
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	addda32_24 xiz, (0x030452)
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_ModeF5_NextRow

ColorBlit2_ModeF5_PixelLoop:
	andmi8 (xiy), 0x60
	ld c, (xiz)
	and c, 0x9f
	add (xiy), c
	ld e, (xiz)
	and e, 0x80
	ld c, (xiy)
	and c, 0x80
	cp c, e
	jr z, ColorBlit2_ModeF5_PixelSignOK
	xormi8 (xiy), 0x60

ColorBlit2_ModeF5_PixelSignOK:
	inc 1, xiy
	inc 1, xiz
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit2_ModeF5_PixelLoop

ColorBlit2_ModeF5_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit2_ModeF5_RowLoop
	jrl ColorBlit2_Epilogue

ColorBlit2_Mode1_Entry:
	ld hl, ix
	ld xbc, (xsp + 4)
	cp ix, (xbc)
	jrl gt, ColorBlit2_Epilogue

ColorBlit2_Mode1_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	lda_24 xiy, (0x043c00)
	add xiy, xde
	ld bc, (xwa)
	stb_dri E, 0x07, 0xf4, 0xe4
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_Mode1_NextRow

ColorBlit2_Mode1_PixelLoop:
	bitm 7, (xiy)
	jr z, ColorBlit2_Mode1_ResBit5
	setm 5, (xiy)
	jr ColorBlit2_Mode1_NextPixel

ColorBlit2_Mode1_ResBit5:
	resm 5, (xiy)

ColorBlit2_Mode1_NextPixel:
	inc 1, xiy
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit2_Mode1_PixelLoop

ColorBlit2_Mode1_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit2_Mode1_RowLoop
	jrl ColorBlit2_Epilogue

ColorBlit2_Mode2_Entry:
	ld xbc, (xsp + 4)
	ld de, (xbc)
	ld iy, ix
	ld bc, de
	sub bc, ix
	cp bc, 0xef
	jr nz, ColorBlit2_Mode2_ClippedEntry
	ld xbc, (xsp + 8)
	ld bc, (xbc)
	sub bc, (xwa)
	cp bc, 0x13f
	jr nz, ColorBlit2_Mode2_ClippedEntry
	lda_24 xbc, (0x043c00)
	lds32 xde, 0

ColorBlit2_Mode2_FullscreenLoop:
	bitm 7, (xbc)
	jr z, ColorBlit2_Mode2_FullscreenRes6
	setm 6, (xbc)
	jr ColorBlit2_Mode2_FullscreenNext

ColorBlit2_Mode2_FullscreenRes6:
	resm 6, (xbc)

ColorBlit2_Mode2_FullscreenNext:
	inc 1, xbc
	inc 1, xde
	cp xde, 0x12c00
	jr c, ColorBlit2_Mode2_FullscreenLoop
	jr ColorBlit2_Epilogue

ColorBlit2_Mode2_ClippedEntry:
	ld hl, iy
	cp iy, de
	jr gt, ColorBlit2_Epilogue

ColorBlit2_Mode2_RowLoop:
	ld bc, hl
	exts xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	sll xde, 6
	ld bc, (xwa)
	exts xbc
	add xbc, xde
	lda_24 xde, (0x043c00)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_Mode2_NextRow

ColorBlit2_Mode2_PixelLoop:
	bitm 7, (xde)
	jr z, ColorBlit2_Mode2_ResBit6
	setm 6, (xde)
	jr ColorBlit2_Mode2_NextPixel

ColorBlit2_Mode2_ResBit6:
	resm 6, (xde)

ColorBlit2_Mode2_NextPixel:
	inc 1, xde
	inc 1, ix
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr le, ColorBlit2_Mode2_PixelLoop

ColorBlit2_Mode2_NextRow:
	inc 1, hl
	ld xbc, (xsp + 4)
	cp hl, (xbc)
	jr le, ColorBlit2_Mode2_RowLoop

ColorBlit2_Epilogue:
	calr SetChangeRect

ColorBlit2_PopReturn:
	pop xiz
	inc 8, xsp
	ret

ColorBlit2_LargeCodeBlock:
	.incbin "includes/generated/v7_fix_colorblit2_largecodeblock.bin"
