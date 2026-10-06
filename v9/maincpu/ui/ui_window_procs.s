; =============================================================================
; UI Window Procedures (8K lines)
; =============================================================================
;
; Window procedure handlers for all standard widget types:
; ModeEdit, TitleEdit, StringBox, Label, Bitmap, Icon, Line,
; Frame, EditSw, TextBox, VwBox, ListBox, RadioBox, TempoBox,
; GridBox. The core UI rendering and event dispatch layer.
; =============================================================================

	lda xde, (0x0274b0:24)
	ld xhl, (0x0274e4:24)
	ld xbc, 0:i3

WndScroll_CopyLoop:
	ld xwa, xbc
	ld xix, xde
	add xix, xwa
	ld a, (xhl)
	ld (xix), a
	inc 1, iz
	inc 1, xbc
	cp iz, (0x0274d6:24)
	jr c, WndScroll_CopyLoop

WndScroll_InitBuffer:
	ld wa, iz
	extz xwa
	lda xde, (0x0274b0:24)
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	ld xwa, (0x0274d2:24)
	ld xbc, EVT_GET_STRING
	call ApFuncCall

WndScroll_InitWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 50)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 5:i3
	calr SetDialUp
	ld xwa, (xsp + 50)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 3:i3
	calr SetDialDown
	ld wa, 1:i3
	calr SetDialEnable
	jrl UIDialog_ReturnZeroJmp

WndScroll_InitSelectionTrack:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ldw (0x0274dc:24), 0xffff
	ldw (0x0274e0:24), 0xffff
	ld de, (0x0274d8:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_CURSOR
	jrl WndScroll_SendAndReturn

WndScroll_BasicWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleSelectionChange:
	ld (0x0274de:24), de
	cp (0x0274e0:24), de
	jrl z, UIDialog_ReturnZeroJmp
	ld xwa, (xsp + 50)
	calr GetClientBox
	ld wa, (0x0274da:24)
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ld wa, (0x0274e0:24)
	cp wa, 0xffff
	jr z, WndScroll_DrawCurrentItem
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ld wa, (0x0274e0:24)
	extz xwa
	div wa, 0xd
	mul wa, 0x18
	ld de, wa
	lda xbc, (xsp + 34)
	ld wa, (xbc + 2)
	add wa, 0xa
	add wa, de
	lda xde, (xsp + 26)
	ld (xde + 2), wa
	ld wa, (0x0274e0:24)
	extz xwa
	div wa, 0xd
	ldto_werp HL, 0xe2
	sll hl, 4
	ld wa, (xbc)
	add wa, 0xe
	add wa, hl
	dec 1, wa
	ld (xde), wa
	lda xwa, (xsp + 12)
	push xwa
	call Strlen
	inc 4, xsp
	sll hl, 3
	lda xwa, (xsp + 26)
	ld bc, (xwa)
	add bc, hl
	inc 2, bc
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0x11
	ld (xwa + 6), bc
	ldw bc, 0xf5
	call DrawFrame

WndScroll_DrawCurrentItem:
	ld wa, (0x0274de:24)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ld wa, (0x0274de:24)
	extz xwa
	div wa, 0xd
	mul wa, 0x18
	ld de, wa
	lda xbc, (xsp + 34)
	ld wa, (xbc + 2)
	add wa, 0xa
	add wa, de
	lda xde, (xsp + 26)
	ld (xde + 2), wa
	ld wa, (0x0274de:24)
	extz xwa
	div wa, 0xd
	ldto_werp HL, 0xe2
	sll hl, 4
	ld wa, (xbc)
	add wa, 0xe
	add wa, hl
	dec 1, wa
	ld (xde), wa
	lda xwa, (xsp + 12)
	push xwa
	call Strlen
	inc 4, xsp
	sll hl, 3
	lda xwa, (xsp + 26)
	ld bc, (xwa)
	add bc, hl
	inc 2, bc
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0x11
	ld (xwa + 6), bc
	ldw bc, 0xf2
	call DrawFrame
	ld wa, (0x0274de:24)
	ld (0x0274e0:24), wa
	jrl UIDialog_ReturnZeroJmp

WndScroll_RepaintAll:
	ld wa, (0x0274dc:24)
	cp wa, (0x0274da:24)
	jrl z, UIDialog_ReturnZeroJmp
	ldw (0x0274e0:24), 0xffff
	ld xwa, (xsp + 50)
	calr GetClientBox
	lda xwa, (xsp + 34)
	ldw bc, 0xf5
	call DrawBox
	ld wa, (0x0274da:24)
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ld iz, 0:i3
	jr WndScroll_ItemCountCheck

WndScroll_DrawSingleItem:
	ld wa, iz
	extz xwa
	div wa, 0xd
	ldto_werp DE, 0xe2
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
	ld xde, 0:i3
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, (xhl)
	call DrawString
	inc 1, iz

WndScroll_ItemCountCheck:
	ld bc, (0x0274e2:24)
	mul bc, 0x3
	ld wa, (0x0274da:24)
	add bc, wa
	extz xbc
	add xbc, xbc
	ld xde, WndScroll_ItemCountCheck_Str_Chr25
	add xde, xbc
	cp iz, (xde)
	jr ule, WndScroll_DrawSingleItem
	ld (0x0274dc:24), wa
	jrl UIDialog_ReturnZeroJmp

WndEvt_DispatchByEventCode:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	ld xbc, (0x0274e4:24)
	dec 1, xwa
	cp xwa, 0x0
	jrl c, UIDialog_ReturnZeroJmp
	cp xwa, 0x8
	jrl ugt, UIDialog_ReturnZeroJmp
	add xwa, xwa
	add xwa, WndEvt_DispatchByEventCode_CaseTable
	ld wa, (xwa)
	lda xix, (WndEvt_EventCodeDispatch:24)
; Computed jump: target = WndEvt_EventCodeDispatch + WndEvt_DispatchByEventCode_CaseTable[i], WndEvt_DispatchByEventCode_CaseTable = 16-bit offsets (9 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> WndEvt_EventCodeDispatch
;   1 -> WndEvt_DispatchByEventCode_Case1
;   2 -> WndEvt_DispatchByEventCode_Case2
;   3 -> WndEvt_DispatchByEventCode_Case3
;   4 -> WndEvt_DispatchByEventCode_Case4
;   5 -> WndEvt_DispatchByEventCode_Case5
;   6 -> WndEvt_DispatchByEventCode_Case6
;   7 -> WndEvt_DispatchByEventCode_Case7
;   8 -> WndEvt_DispatchByEventCode_Case8
	jp	t, (xix+wa)

; Window event dispatch by event code
WndEvt_EventCodeDispatch:
	ld	wa, (0x0274d8:24)
	cp	wa, 0:i3
	jrl	z, UIDialog_ReturnZeroJmp
	dec	1, wa
	ld	(0x0274d8:24), wa
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	WndEvt_EventCodeDispatch_Join3
WndEvt_DispatchByEventCode_Case1:
	ld	wa, (0x0274d8:24)
	ld	bc, wa
	inc	1, bc
	cp bc, (160982:24)
	jrl	nc, UIDialog_ReturnZeroJmp
	inc	1, wa
	ld	(0x0274d8:24), wa
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	WndEvt_EventCodeDispatch_Join3
WndEvt_DispatchByEventCode_Case2:
	ld	bc, (0x0274de:24)
	cp	bc, 0:i3
	jrl	z, UIDialog_ReturnZeroJmp
	ld	wa, (0x0274da:24)
	extz	xwa
	sll	xwa, 2
	ld	xde, Data_SoundEditorCharsLayout
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	dec	1, bc
	ld	(0x0274de:24), bc
	extz	xbc
	sll	xbc, 2
	ld	xwa, xbc
	add xwa, (xsp+0x04)	; F9B8CE (add xwa,(xsp+0x04))
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	ConvertStrings
	ld	wa, (0x0274d8:24)
	extz	xwa
	lda	xde, (0x0274b0:24)
	ld	xbc, xde
	add	xbc, xwa
	ld	a, (xsp+12)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	ld	de, (0x0274de:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SELE_DRAW
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	WndEvt_EventCodeDispatch_Join3
WndEvt_DispatchByEventCode_Case3:
	lda	xde, (Data_SoundEditorCharsLayout:24)
	lda	xwa, (xsp+12)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+46)
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, WndEvt_EventCodeDispatch_Skip2
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, WndEvt_EventCodeDispatch_Skip2
	cp	xwa, EVT_INDEXSW_UP
	jr	z, WndEvt_EventCodeDispatch_Skip
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	nz, UIDialog_ReturnZeroJmp
WndEvt_EventCodeDispatch_Skip:
	ld	bc, (0x0274de:24)
	cp	bc, 13
	jrl	c, UIDialog_ReturnZeroJmp
	sub	bc, 13
	ld	(0x0274de:24), bc
	ld	wa, (0x0274da:24)
	extz	xwa
	sll	xwa, 2
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	extz	xbc
	sll	xbc, 2
	add	xbc, (xsp+4)
	ld	xwa, (xbc)
	ld	xbc, (xsp+8)
	call	ConvertStrings
	ld	wa, (0x0274d8:24)
	extz	xwa
	lda	xde, (0x0274b0:24)
	ld	xbc, xde
	add	xbc, xwa
	ld	a, (xsp+12)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	ld	de, (0x0274de:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SELE_DRAW
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	WndEvt_EventCodeDispatch_Join3
WndEvt_EventCodeDispatch_Skip2:
	ld	wa, (0x0274da:24)
	extz	xwa
	sll	xwa, 2
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	ld	wa, (0x0274de:24)
	extz	xwa
	sll	xwa, 2
	add	xwa, (xsp+4)
	ld	xwa, (xwa)
	ld	xbc, (xsp+8)
	call	ConvertStrings
	ld	wa, (0x0274e2:24)
	mul	wa, 3
	add	wa, (0x0274da:24)
	extz	xwa
	add	xwa, xwa
	lda	xde, (WndScroll_ItemCountCheck_Str_Chr25:24)
	ld	xbc, xde
	add	xbc, xwa
	ld	wa, (0x0274de:24)
	ld	hl, wa
	add	hl, 12
	cp	hl, (xbc)
	jr	ugt, WndEvt_EventCodeDispatch_Skip4
	ld	c, (xsp+12)
	cp	c, 90
	jr	z, WndEvt_EventCodeDispatch_Skip3
	cp	c, 122
	jr	nz, WndEvt_EventCodeDispatch_Skip4
WndEvt_EventCodeDispatch_Skip3:
	dec	1, wa
	ld	(0x0274de:24), wa
WndEvt_EventCodeDispatch_Skip4:
	ld	bc, (0x0274e2:24)
	mul	bc, 3
	ld	wa, (0x0274da:24)
	add	bc, wa
	extz	xbc
	add	xbc, xbc
	add	xde, xbc
	ld	wa, (0x0274de:24)
	ld	bc, wa
	add	bc, 13
	cp	bc, (xde)
	jrl	ugt, UIDialog_ReturnZeroJmp
	ld	bc, wa
	add	bc, 13
	ld	(0x0274de:24), bc
	ld	wa, (0x0274da:24)
	extz	xwa
	sll	xwa, 2
	ld	xde, Data_SoundEditorCharsLayout
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	extz	xbc
	sll	xbc, 2
	ld	xwa, xbc
	add	xwa, (xsp+4)
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	ConvertStrings
	lda	xde, (xsp+12)
	ld	c, (xde)
	lda	xwa, (0x0274b0:24)
	cp	c, 83
	jr	nz, WndEvt_EventCodeDispatch_Skip5
	cp	(xde+1), 80
	jr	nz, WndEvt_EventCodeDispatch_Skip5
	ld	bc, (0x0274d8:24)
	extz	xbc
	ld	xde, xwa
	add	xde, xbc
	ld	xwa, (0x0274e4:24)
	ld	a, (xwa)
	ld	(xde), a
	jr	WndEvt_EventCodeDispatch_Join
WndEvt_EventCodeDispatch_Skip5:
	ld	de, (0x0274d8:24)
	extz	xde
	add	xwa, xde
	ld	(xwa), c
WndEvt_EventCodeDispatch_Join:
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x0274b0
	call	SendEvent
	ld	de, (0x0274de:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SELE_DRAW
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	WndEvt_EventCodeDispatch_Join3
WndEvt_DispatchByEventCode_Case4:
	ld	bc, (0x0274da:24)
	ld	wa, bc
	extz	xwa
	sll	xwa, 2
	ld	xde, Data_SoundEditorCharsLayout
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	ld	wa, (0x0274e2:24)
	mul	wa, 3
	add	wa, bc
	extz	xwa
	add	xwa, xwa
	ld	xbc, WndScroll_ItemCountCheck_Str_Chr25
	add	xbc, xwa
	ld	wa, (0x0274de:24)
	ld	de, wa
	inc	1, de
	cp	de, (xbc)
	jrl	ugt, UIDialog_ReturnZeroJmp
	inc	1, wa
	ld	(0x0274de:24), wa
	extz	xwa
	sll	xwa, 2
	add	xwa, (xsp+4)
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	ConvertStrings
	lda	xde, (xsp+12)
	ld	c, (xde)
	ld	wa, (0x0274d8:24)
	extz	xwa
	cp	c, 83
	jr	nz, WndEvt_EventCodeDispatch_Skip6
	cp	(xde+1), 80
	jr	nz, WndEvt_EventCodeDispatch_Skip6
	ld	xbc, 0x0274b0
	add	xbc, xwa
	ld	xwa, (0x0274e4:24)
	ld	a, (xwa)
	ld	(xbc), a
	jr	WndEvt_EventCodeDispatch_Join2
WndEvt_EventCodeDispatch_Skip6:
	ld	xde, 0x0274b0
	add	xde, xwa
	ld	(xde), c
WndEvt_EventCodeDispatch_Join2:
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x0274b0
	call	SendEvent
	ld	de, (0x0274de:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SELE_DRAW
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
WndEvt_EventCodeDispatch_Join3:
	calr	SetAutoInc
	jrl	UIDialog_ReturnZeroJmp
WndEvt_DispatchByEventCode_Case5:
	ld	iz, (0x0274d6:24)
	dec	1, iz
	cp iz, (160984:24)
	jr	ule, WndEvt_EventCodeDispatch_Skip7
	lda	xde, (0x0274b0:24)
	ld	bc, iz
	extz	xbc
	ld	xwa, 0xffffffff
	add	xbc, xwa
WndEvt_EventCodeDispatch_Loop:
	ld	xhl, xbc
	ld	xwa, 1:i3
	add	xhl, xwa
	ld	xix, xde
	add	xix, xhl
	ld	xwa, xbc
	ld	xhl, xde
	add	xhl, xwa
	ld	a, (xhl)
	ld	(xix), a
	dec	1, iz
	dec	1, xbc
	cp iz, (160984:24)
	jr	ugt, WndEvt_EventCodeDispatch_Loop
WndEvt_EventCodeDispatch_Skip7:
	ld	wa, (0x0274d8:24)
	extz	xwa
	lda	xde, (0x0274b0:24)
	ld	xbc, xde
	add	xbc, xwa
	ld	xwa, (0x0274e4:24)
	ld	a, (xwa)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	ld	de, (0x0274d8:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	jrl	WndScroll_SendAndReturn
WndEvt_DispatchByEventCode_Case6:
	ld	iz, (0x0274d8:24)
	cp iz, (160982:24)
	jr	nc, WndEvt_EventCodeDispatch_Skip8
	lda	xde, (0x0274b0:24)
	ld	bc, iz
	extz	xbc
	ld	xwa, 1:i3
	add	xbc, xwa
WndEvt_EventCodeDispatch_Loop2:
	ld	xhl, xbc
	ld	xwa, 0xffffffff
	add	xhl, xwa
	ld	xix, xde
	add	xix, xhl
	ld	xwa, xbc
	ld	xhl, xde
	add	xhl, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	cp iz, (160982:24)
	jr	c, WndEvt_EventCodeDispatch_Loop2
WndEvt_EventCodeDispatch_Skip8:
	ld	wa, (0x0274d6:24)
	dec	1, wa
	extz	xwa
	lda	xde, (0x0274b0:24)
	ld	xbc, xde
	add	xbc, xwa
	ld	xwa, (0x0274e4:24)
	ld	a, (xwa)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	ld	de, (0x0274d8:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	jrl	WndScroll_SendAndReturn
WndEvt_DispatchByEventCode_Case7:
	ld qiz, 0
	ld iz, 0:i3
	ld	de, (0x0274d6:24)
	cp	de, 0:i3
	jr	ule, WndEvt_EventCodeDispatch_Skip9
	lda	xhl, (0x0274b0:24)
	ld	a, (xbc)
WndEvt_EventCodeDispatch_Skip8_Loop:
	ld	bc, iz
	extz	xbc
	ld	xix, xhl
	add	xix, xbc
	cp	a, (xix)
	jr	nz, WndEvt_EventCodeDispatch_Skip9
	inc 1, qiz
	inc 1, iz
	cp iz, de
	jr	c, WndEvt_EventCodeDispatch_Skip8_Loop
WndEvt_EventCodeDispatch_Skip9:
	ld wa, qiz
	cp	wa, de
	jrl	z, UIDialog_ReturnZeroJmp
	ldw	(xsp+4), 0
	ld	iz, 0:i3
	cp	de, 0:i3
	jr	ule, WndEvt_EventCodeDispatch_Skip10
	lda	xbc, (0x0274b0:24)
	ld	xwa, (0x0274e4:24)
	ld	a, (xwa)
WndEvt_EventCodeDispatch_Loop3:
	ld	hl, de
	sub	hl, iz
	dec	1, hl
	extz	xhl
	ld	xix, xbc
	add	xix, xhl
	cp	a, (xix)
	jr	nz, WndEvt_EventCodeDispatch_Skip10
	incw	1, (xsp+4)
	inc	1, iz
	cp	iz, de
	jr	c, WndEvt_EventCodeDispatch_Loop3
WndEvt_EventCodeDispatch_Skip10:
	ld wa, qiz
	ld	(xsp+6), wa
	ld	wa, (xsp+4)
	add	(xsp+6), wa
	srlw	(xsp+6)
	inc	1, de
	pushw	de
	call	Malloc
	ld	(xsp+10), xhl
	ld	wa, qiz
	extz	xwa
	ld	xbc, 0x0274b0
	add	xbc, xwa
	push	xbc
	ld	xwa, (xsp+14)
	push	xwa
	call	Strcpy
	ld	wa, (0x0274d6:24)
	sub	wa, qiz
	sub	wa, (xsp+14)
	extz	xwa
	add	xwa, (xsp+18)
	ld	(xwa), 0
	ld	xwa, (xsp+18)
	push	xwa
	ld	wa, (xsp+20)
	extz	xwa
	ld	xbc, 0x0274b0
	add	xbc, xwa
	push	xbc
	call	Strcpy
	ld	xwa, (xsp+26)
	push	xwa
	call	Free
	lda	xsp, (xsp+22)
	ld	iz, 0:i3
	cpw	(xsp+6), 0
	jr	ule, WndEvt_EventCodeDispatch_Skip10_Skip
	lda	xde, (0x0274b0:24)
	ld	xhl, (0x0274e4:24)
	ld	xbc, 0:i3
WndEvt_EventCodeDispatch_Skip10_Loop:
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	cp	iz, (xsp+6)
	jr	c, WndEvt_EventCodeDispatch_Skip10_Loop
WndEvt_EventCodeDispatch_Skip10_Skip:
	ld	bc, qiz
	add	bc, (xsp+4)
	sub	bc, (xsp+6)
	ld	wa, (0x0274d6:24)
	ld	iz, wa
	sub	iz, bc
	cp	iz, wa
	jr	nc, WndEvt_EventCodeDispatch_Skip10_Skip2
	lda	xde, (0x0274b0:24)
	ld	xhl, (0x0274e4:24)
	ld	bc, iz
	extz	xbc
WndEvt_EventCodeDispatch_Loop4:
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	cp iz, (160982:24)
	jr	c, WndEvt_EventCodeDispatch_Loop4
WndEvt_EventCodeDispatch_Skip10_Skip2:
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x0274b0
	call	SendEvent
	ld	de, (0x0274d8:24)
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	jrl	WndScroll_SendAndReturn
WndEvt_DispatchByEventCode_Case8:
	ld	iz, 0:i3
	cpw	(0x0274d6:24), 0
	jr	ule, WndEvt_EventCodeDispatch_Loop4_Skip
	lda	xde, (0x0274b0:24)
	ld	xhl, xbc
	ld	xbc, 0:i3
WndEvt_EventCodeDispatch_Loop5:
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	cp iz, (160982:24)
	jr	c, WndEvt_EventCodeDispatch_Loop5
WndEvt_EventCodeDispatch_Loop4_Skip:
	ld	xwa, 22
	ld	xbc, EVT_SET_CURSOR
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, 22
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0x0274b0
	call	SendEvent
	ld	xwa, (xsp+50)
	ld	xbc, EVT_SET_CURSOR
	ld	xde, 0:i3
	jrl	WndScroll_SendAndReturn

WndScroll_CopyStringAndSend:
	ld xwa, (xsp + 42)
	push xwa
	pushw 0x2
	pushw 0x74b0
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_CURSOR
	ld xde, 0:i3
	jrl WndScroll_SendAndReturn

WndScroll_CopyFromSource:
	pushw 0x2
	pushw 0x74b0
	ld xwa, (xsp + 46)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl UIDialog_ReturnZeroJmp

WndScroll_StoreCallerPtr:
	ld xwa, (xsp + 42)
	ld (0x0274d2:24), xwa
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleIndexChange:
	ld wa, de
	ld (0x0274da:24), de
	cpw (0x0274e2:24), 0
	jr nz, WndScroll_SendSelectionEvents
	ld de, wa
	extz xde
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	call SendEvent

WndScroll_SendSelectionEvents:
	ld de, (0x0274da:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld wa, (0x0274da:24)
	extz xwa
	sll xwa, 2
	ld xbc, WndScroll_SendSelectionEvents_PtrTable
	add xbc, xwa
	ld xde, (xbc)
	ld xwa, 0x1d
	ld xbc, EVT_PARA_DRAW
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharInput:
	ld xwa, (xsp + 42)
	ld (0x0274d8:24), wa
	ld de, wa
	extz xde
	ld xwa, 0x16
	ld xbc, EVT_SET_CURSOR
	call SendEvent
	ld xwa, 0x16
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x274b0
	call SendEvent
	ld bc, (0x0274d8:24)
	extz xbc
	lda xde, (0x0274b0:24)
	ld xwa, xde
	add xwa, xbc
	ld a, (xwa)
	ld c, a
	extz bc
	lda xhl, (CType_ClassTable:24)
	ld	c, (xhl+bc)
	bit 0, c
	jr z, WndScroll_CharIsUppercase
	ldw (0x0274da:24), 0x0000
	ld c, 0x41:opc
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsUppercase:
	bit 1, c
	jr z, WndScroll_CharIsLowercase
	ldw (0x0274da:24), 0x0001
	ld c, 0x61:opc
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsLowercase:
	bit 2, c
	jr z, WndScroll_CharIsSpace
	cpw (0x0274da:24), 2
	jr nz, WndScroll_SetCategoryZero
	ldw (0x0274da:24), 0x0000

WndScroll_SetCategoryZero:
	ld c, 0x15:opc

WndScroll_ComputeCharOffset:
	ld wa, (0x0274d8:24)
	extz xwa
	add xde, xwa
	ld a, (xde)
	sub a, c
	extz wa
	ld (0x0274de:24), wa
	jrl WndScroll_SendPageEvents

WndScroll_CharIsSpace:
	cp a, 0x20
	jr nz, WndScroll_CharIsUnderscore
	cpw (0x0274e2:24), 0
	jrl nz, WndScroll_SendPageEvents
	cpw (0x0274da:24), 2
	jr nz, WndScroll_SetSpaceOffset
	ldw (0x0274da:24), 0x0000

WndScroll_SetSpaceOffset:
	ldw (0x0274de:24), 0x0025
	jr WndScroll_SendPageEvents

WndScroll_CharIsUnderscore:
	cp a, 0x5f
	jr nz, WndScroll_SearchCharTable
	cpw (0x0274da:24), 2
	jr nz, WndScroll_SetUnderscoreOffset
	ldw (0x0274da:24), 0x0000

WndScroll_SetUnderscoreOffset:
	ldw (0x0274de:24), 0x001a
	jr WndScroll_SendPageEvents

WndScroll_SearchCharTable:
	lda xwa, (WndScroll_SearchCharTable_PtrTable:24)
	ld (xsp + 8), xwa
	ld iz, 0:i3
	jr WndScroll_CheckTableEnd

WndScroll_CompareCharLoop:
	ld wa, iz
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 8)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ld wa, (0x0274d8:24)
	extz xwa
	ld xbc, 0x274b0
	add xbc, xwa
	ld a, (xbc)
	cp a, (xsp + 12)
	jr nz, WndScroll_CharMismatch
	ldw (0x0274da:24), 0x0002
	ld (0x0274de:24), iz

WndScroll_CharMismatch:
	inc 1, iz

WndScroll_CheckTableEnd:
	ld wa, (0x0274e2:24)
	mul wa, 0x3
	inc 2, wa
	extz xwa
	add xwa, xwa
	ld xbc, WndScroll_ItemCountCheck_Str_Chr25
	add xbc, xwa
	cp iz, (xbc)
	jr ule, WndScroll_CompareCharLoop

WndScroll_SendPageEvents:
	ld de, (0x0274da:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_PAGE
	call SendEvent
	ld de, (0x0274de:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SELE_DRAW
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharSet:
	ld wa, (0x0274d8:24)
	extz xwa
	ld xbc, 0x274b0
	add xbc, xwa
	ld xwa, (xsp + 42)
	ld (xbc), a
	ld de, (0x0274d8:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_CURSOR
	jrl WndScroll_SendAndReturn

WndScroll_HandleDialPage:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 0:i3
	jrl nz, UIDialog_ReturnZeroJmp
	ld xwa, (xsp + 42)
	ld de, wa
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_PAGE
	call SendEvent
	ld wa, (0x0274e2:24)
	mul wa, 0x3
	add wa, (0x0274da:24)
	ld bc, wa
	extz xbc
	add xbc, xbc
	ld xwa, WndScroll_ItemCountCheck_Str_Chr25
	add xwa, xbc
	ld wa, (xwa)
	cp (0x0274de:24), wa
	jr ule, WndScroll_ClampPageCount
	ld (0x0274de:24), wa

WndScroll_ClampPageCount:
	ld wa, (0x0274da:24)
	extz xwa
	sll xwa, 2
	ld xbc, Data_SoundEditorCharsLayout
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ld wa, (0x0274de:24)
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
	ld xwa, (0x0274e4:24)
	ld xde, 0:i3
	ld e, (xwa)
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_CHARA
	jr WndScroll_SendConfirmEvent

WndScroll_CheckSPMarker:
	ld d, 0x0:opc
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SET_CHARA

WndScroll_SendConfirmEvent:
	call SendEvent
	ld de, (0x0274de:24)
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, EVT_SELE_DRAW

WndScroll_SendAndReturn:
	call SendEvent

UIDialog_ReturnZeroJmp:
	ld xhl, 0:i3
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
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+272), xde
	ld	(xsp+276), xwa
	cp xbc, EVT_CHANGE_PROPERTY
	jrl z, ModeEdit_HandleViewUpdate
	cp xbc, EVT_DRAW
	jr z, ModeEdit_HandlePaint
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	jrl ModeEdit_Epilogue

ModeEdit_HandlePaint:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	call GetModeNow
	ld xwa, xhl
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	push xhl
	call GetModeNow
	ldiw_erp 0xee, 0
	pushw hl
	pushw ModeEdit_HandlePaint_Data@hi16
	pushw ModeEdit_HandlePaint_Data@lo16
	lda xwa, (xsp + 14)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	lda xbc, (xsp+260)
	ld XWA, (xsp + 0x0114)
	calr GetClientBox
	lda xwa, (xsp+260)
	lda xbc, (xsp+268)
	calr GetBoxCenter
	lda xwa, (xsp+260)
	lda xbc, (xsp+268)
	lda xde, (xsp + 4)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringCentered
	jrl TitleEdit_ReturnZero

ModeEdit_HandleViewUpdate:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_GET_PROP_CHAR
	ld XDE, (xsp + 0x0110)
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
	ld xbc, EVT_GET_MODE_PROC_ID
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_START_TITLE
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_USER_ID
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 40), xhl
	jr TitleEdit_ReturnZero

ModeEdit_StoreField0:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField1:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField2:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField3:
	ld xwa, (xwa)
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

TitleEdit_ReturnZero:
	ld xhl, 0:i3

ModeEdit_Epilogue:
	pop xiz
	lda xsp, (xsp+276)
	ret

TitleEditProc:
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+272), xde
	ld	(xsp+276), xwa
	cp xbc, EVT_CHANGE_PROPERTY
	jrl z, TitleEdit_HandleViewUpdate
	cp xbc, EVT_DRAW
	jr z, TitleEdit_HandlePaint
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	jrl TitleEdit_Epilogue

TitleEdit_HandlePaint:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	push xhl
	call GetTitleNow
	ldiw_erp 0xee, 0
	pushw hl
	pushw TitleEdit_HandlePaint_Str_N0x_Fmt2X_Fmts@hi16
	pushw TitleEdit_HandlePaint_Str_N0x_Fmt2X_Fmts@lo16
	lda xwa, (xsp + 14)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	lda xbc, (xsp+260)
	ld XWA, (xsp + 0x0114)
	calr GetClientBox
	lda xwa, (xsp+260)
	lda xbc, (xsp+268)
	calr GetBoxCenter
	lda xwa, (xsp+260)
	lda xbc, (xsp+268)
	lda xde, (xsp + 4)
	ld xhl, 0:i3
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringCentered
	jrl StringBox_ReturnZero

TitleEdit_HandleViewUpdate:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr BoxProc
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_GET_PROP_CHAR
	ld XDE, (xsp + 0x0110)
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
	ld xbc, EVT_GET_TITLE_PROC_ID
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_START_SCREEN
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_USER_ID
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, EVT_GET_NAME
	ld xde, 0:i3
	call SendEvent
	ld (xiz + 40), xhl
	jr StringBox_ReturnZero

TitleEdit_StoreFieldJA:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldNE:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldLC:
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldX:
	ld xwa, (xwa)
	ld xbc, EVT_GET_INSTANCE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

StringBox_ReturnZero:
	ld xhl, 0:i3

TitleEdit_Epilogue:
	pop xiz
	lda xsp, (xsp+276)
	ret

StringBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	pushw	(xhl+34)
	pushw 0xf7
	ld xwa, (xsp + 12)
	ld a, (xwa + 36)
	extz wa
	pushw wa
	ld xhl, (xhl + 26)
	ld xwa, xde
	ld xde, xhl
	call DrawStringAlignment
	ld xhl, 0:i3

StringBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 20)
	ret

LabelProc:	; SysData_F9C4B6
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	ld bc, 4:i3
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
	pushw	(xhl+30)	; <-- foreground color
	pushw 0xf7	; <-- background color
	ld xde, (xhl + 22)	; <-- string pointer
	call DrawString
	ld xhl, 0:i3

Label_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

BitmapProc:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	ld xhl, 0:i3

Bitmap_Epilogue:
	pop xiz
	inc 4, xsp
	ret

VwUserBitmapProc:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	ld xbc, EVT_GET_BITMAP_DATA
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, VwUserBitmap_DrawFallback
	ld xwa, (xiz + 22)
	ld xbc, EVT_GET_BITMAP_WIDTH
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), hl
	ld xwa, (xiz + 22)
	ld xbc, EVT_GET_BITMAP_HEIGHT
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 10)
	pushw hl
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	call DrawBitmapSPFast
	jr VwUserBitmap_ReturnZero

VwUserBitmap_DrawFallback:
	lda xwa, (xsp + 10)
	ld xbc, 0:i3
	call DrawBitmap

VwUserBitmap_ReturnZero:
	ld xhl, 0:i3

VwUserBitmap_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

UserBitmapCheck:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, UserBitmapCheck_ReturnTablePtr
	ld xhl, 0:i3
	ret

UserBitmapCheck_ReturnTablePtr:
	lda xhl, (UserBitmapCheck_ReturnTablePtr_Data:24)
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
	cp xiz, EVT_HIDE
	jrl z, VwUserBitmapByName_HandleClose
	cp xiz, EVT_DRAW
	jr z, VwUserBitmapByName_HandlePaint
	cp xiz, EVT_SHOW
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
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call ViewableProc
	ld xwa, (xsp + 28)
	call GetViewInstance
	lda xbc, (xsp + 20)
	ld wa, (xhl + 14)
	ld (xbc), wa
	ld wa, (xhl + 16)
	ld (xbc + 2), wa
	ld xwa, (xhl + 22)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	pushw VwUserBitmapByName_HandlePaint_Data@hi16
	pushw VwUserBitmapByName_HandlePaint_Data@lo16
	lda xwa, (xsp + 16)
	push xwa
	call Strcat
	lda xsp, (xsp + 16)
	lda xwa, (xsp + 4)
	call FDemo_LinkedListLookupField
	ld xbc, xhl
	lda xwa, (xsp + 20)
	or xbc, xbc
	jr z, VwUserBitmapByName_DrawDefault
	call DrawBitmapFile
	jr VwUserBitmapByName_ReturnZero

VwUserBitmapByName_DrawDefault:
	ld xbc, 0:i3
	call DrawBitmap
	jr VwUserBitmapByName_ReturnZero

VwUserBitmapByName_HandleClose:
	ld wa, 2:i3
	call ChangePalette
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)

VwUserBitmapByName_CallViewable:
	call ViewableProc

VwUserBitmapByName_ReturnZero:
	ld xhl, 0:i3

VwUserBitmapByName_Epilogue:
	pop xiz
	lda xsp, (xsp + 28)
	ret

IconProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
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
	ld xhl, 0:i3

Icon_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

LineProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), xwa
	cp xbc, EVT_DRAW
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
	ld xhl, 0:i3

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
	cp xwa, EVT_DRAW
	jr z, Frame_HandlePaint
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ViewableProc
	jr Frame_Epilogue

Frame_HandlePaint:
	ld xwa, xiz
	call GetVisible
	cp hl, 0:i3
	jr nz, Frame_DrawVisible
	ld xhl, 1:i3
	jr Frame_Epilogue

Frame_DrawVisible:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ViewableProc
	ld xwa, xiz
	call GetViewInstance
	lda xwa, (xhl + 14)
	pushw	(xhl+26)
	ld bc, (xhl + 22)
	ld de, (xhl + 24)
	calr DrawDesignFrame
	ld xhl, 0:i3

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
	ld bc, 4:i3
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
	ld xhl, 0:i3
	ld xiz, (xsp + 10)
	ld xiy, xde
	ld xix, xiz
	ld bc, 4:i3
	ldirw
	cp wa, 0:i3
	jr z, FrameLoop_Cleanup
	cp wa, 1:i3
	jr nz, ClientFrame2_ProcessThickness
	ld hl, (xsp + 4)
	exts xhl

ClientFrame2_ProcessThickness:
	or xhl, xhl
	jr z, FrameLoop_Cleanup
	ld xiy, 0:i3
	cp xhl, 0x0
	jr le, FrameLoop_Cleanup
	lda xix, (xiz + 2)
	lda xde, (xiz + 6)
	ld xbc, xiz
	lda xwa, (xiz + 4)

ClientFrame2_InsetLoop:
	incw 1, (xix)
	decw	1, (xde)
	incw 1, (xbc)
	decw	1, (xwa)
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
	ld bc, 4:i3
	ldirw
	cp de, 1:i3
	jr nz, DesignFrame_Epilogue
	ld xiz, 0:i3
	ld wa, (xsp + 12)
	exts xwa
	cp xwa, 0x0
	jr le, DesignFrame_Epilogue

DesignFrame_DrawLoop:
	lda xwa, (xsp + 4)
	ld bc, (xsp + 18)
	call DrawFrame
	lda xwa, (xsp + 4)
	incw 1, (xwa + 2)
	decw	1, (xwa+6)
	incw 1, (xwa)
	decw	1, (xwa+4)
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
	cp xwa, EVT_SW_IN
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
	ld xbc, EVT_MAKE_EDIT_SW_ID
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
	ld xbc, EVT_INDEXSW_DOWN
	jr EditSw_SendDialEvent

EditSw_SendDialDown:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP

EditSw_SendDialEvent:
	call SendEvent

EditSw_ReturnZero:
	ld xhl, 0:i3
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
	lda	xsp, (xsp-28)
	pushw	iz
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+2), xwa
	lda	xbc, (xsp+18)
	ld	wa, (xwa+32)
	calr	GetEditSwPoint
	lda	xwa, (xsp+18)
	lda	xbc, (xsp+12)
	cpw	(xwa+2), 239
	jr	z, DrawDesignFrame_Skip2
	cpw	(xwa), 0
	jr	nz, DrawDesignFrame_Skip
	ld	xwa, EditSw_ByteData_Str_N7f
	jr	DrawDesignFrame_Join
DrawDesignFrame_Skip:
	ld	xwa, EditSw_ByteData_Str_N80
	jr	DrawDesignFrame_Join
DrawDesignFrame_Skip2:
	ld	xwa, EditSw_ByteData_Str_N81
DrawDesignFrame_Join:
	push	xwa
	push	xbc
	call	Strcpy
	lda	xwa, (xsp+20)
	push	xwa
	call	Strlen
	ld	iz, hl
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+22)
	push	xwa
	call	Strlen
	lda	xsp, (xsp+16)
	cp	hl, iz
	jr	ule, DrawDesignFrame_Skip3
	lda	xwa, (xsp+12)
	push	xwa
	call	Strlen
	inc	1, hl
	pushw	hl
	call	Malloc
	inc	6, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+22), xhl
DrawDesignFrame_Skip3:
	lda	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+22)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xbc, (xsp+8)
	ld	xwa, (xbc+22)
	ld	xbc, (xbc+26)
	call	CalcTotalWidth
	ld	(xsp+6), hl
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+26)
	call	GetCharHeight
	lda	xbc, (xsp+18)
	ld	wa, hl
	exts	xwa
	divs	wa, 2
	lda	xix, (xsp+22)
	cpw	(xbc), 0
	jr	nz, DrawDesignFrame_Skip4
	ldw	(xix), 65534
	ld	de, (xbc+2)
	sub	de, wa
	ld	(xix+2), de
DrawDesignFrame_Skip4:
	cpw	(xbc), 319
	jr	nz, DrawDesignFrame_Skip5
	ldw	de, 318
	sub	de, (xsp+6)	; F9CA23 (sub de,(xsp+0x06))
	ld	(xix), de
	ld	de, (xbc+2)
	sub	de, wa
	ld	(xix+2), de
DrawDesignFrame_Skip5:
	cpw	(xbc+2), 239
	jr	nz, DrawDesignFrame_Skip6
	ld	wa, (xsp+6)
	exts	xwa
	divs	wa, 2
	ld	bc, (xbc)
	sub	bc, wa
	dec	1, bc
	ld	(xix), bc
	ldw	wa, 245
	sub	wa, hl
	ld	(xix+2), wa
DrawDesignFrame_Skip6:
	lda	xde, (xix+4)
	ld	wa, (xsp+6)
	add	wa, (xix)
	inc	1, wa
	ld	(xde), wa
	lda	xiy, (xix+6)
	lda	xbc, (xix+2)
	ld	wa, (xbc)
	add	hl, wa
	ld	(xiy), hl
	ld	xwa, (xsp+8)
	ld	bc, (xbc)
	ld	(xwa+16), bc
	ld	bc, (xiy)
	ld	(xwa+20), bc
	ld	bc, (xix)
	ld	(xwa+14), bc
	ld	xwa, (xsp+2)
	ld	bc, (xde)
	ld	(xwa+18), bc
	popw	iz
	lda	xsp, (xsp+28)
	ret

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
	ld xwa, DrawEditSw_Str_N7f
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantA:
	ld xwa, DrawEditSw_SelectVariantA_Str_N80
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantC:
	ld xwa, DrawEditSw_SelectVariantC_Str_N81

DrawEditSw_CopyVariant:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 2)
	ld xbc, 0:i3
	call CalcTotalWidth
	ld iz, hl
	ld xwa, 0:i3
	call GetCharHeight
	lda xbc, (xsp + 8)
	ld de, hl
	exts xde
	divs de, 0x2
	lda xwa, (xsp + 12)
	cpw (xbc), 0x0
	jr nz, DrawEditSw_PositionLeft
	ldw (xwa), 0xfffe
	ld ix, (xbc + 2)
	sub ix, de
	ld (xwa + 2), ix

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
	ld xhl, 0:i3
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
	cp xbc, EVT_DRAW
	jr z, TextBox_HandlePaint
	ld xwa, (xsp + 38)
	calr BoxProc
	jrl TextBox_Epilogue

TextBox_HandlePaint:
	ld xwa, (xsp + 38)
	calr BoxProc
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 18), xhl
	ld xwa, (xsp + 18)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 26)
	ld xwa, (xsp + 38)
	calr GetClientBox
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 26)
	push xwa
	call Strlen
	ld xwa, (xsp + 22)
	ld wa, (xwa + 38)
	add wa, hl
	ld (xsp + 20), wa
	inc 1, wa
	pushw wa
	call Malloc
	inc 6, xsp
	ld (xsp + 22), xhl
	ld xiz, (xsp + 22)
	ld bc, 0:i3
	ld wa, (xsp + 16)
	add wa, 0x1
	jr ule, TextBox_SetupWordwrap

TextBox_FillBufferLoop:
	ld (xiz+), 0x00
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
	div xde, bc
	ld (xsp + 8), de
	ldw (xsp + 16), 0x0
	cp bc, 0:i3
	jrl ule, TextBox_FreeBuffer

TextBox_DrawLineLoop:
	pushw TextBox_DrawLineLoop_Data@hi16
	pushw TextBox_DrawLineLoop_Data@lo16
	push xiz
	call StrSearch_Init
	inc 8, xsp
	lda	xwa, (xiz+hl)
	ld (xsp + 10), xwa
	ld (xwa), 0x0
	lda xwa, (xsp + 26)
	ld de, (xwa + 4)
	sub de, (xwa)
	ld xwa, (xsp + 18)
	ld xbc, (xwa + 30)
	ld xwa, xiz
	call WordwrapStrings
	ld (xsp + 14), hl
	push xiz
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 14)
	cp wa, hl
	jr z, TextBox_CheckMoreText
	ld xwa, (xsp + 10)
	ld (xwa), 0xd
	ld wa, (xsp + 14)
	exts xwa
	add xwa, xiz
	ld (xsp + 10), xwa
	ld (-xwa), 0x00
	ld (xsp + 10), xwa

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
	pushw	(xhl+34)
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
	incw 1, (xsp + 16)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 16)
	cp bc, (xwa + 38)
	jrl c, TextBox_DrawLineLoop

TextBox_FreeBuffer:
	ld xwa, (xsp + 22)
	push xwa
	call Free
	inc 4, xsp
	ld xhl, 0:i3

TextBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret

VwBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xwa
	cp xbc, EVT_GET_BOX_COLOR
	jrl z, VwBox_HandleGetColor
	cp xbc, EVT_GET_BOX_BORDER
	jrl z, VwBox_HandleGetHeight
	cp xbc, EVT_CHECK_INDEX
	jr z, VwBox_HandleHitTest
	cp xbc, EVT_GET_INDEX
	jr z, VwBox_HandleGetWidth
	cp xbc, EVT_DRAW_SELECTED
	jr z, VwBox_HandleGetFocus
	cp xbc, EVT_DRAW
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
	cp bc, 0:i3
	jr z, VwBox_UseFocusColor
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr VwBox_CallDrawDesignFrame

VwBox_UseFocusColor:
	pushw	(xhl+22)
	ld bc, 1:i3
	ld de, 2:i3

VwBox_CallDrawDesignFrame:
	calr DrawDesignFrame

VwBox_DrawReturnZero:
	ld xhl, 0:i3
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
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+272), xde
	ld	(xsp+276), xwa
	cp xbc, EVT_GET_STRING
	jrl z, PsParaBox_HandleGetText
	cp xbc, EVT_PARA_DRAW
	jr z, PsParaBox_HandleConfirm
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr VwBoxProc
	jrl PsParaBox_Epilogue

PsParaBox_HandleConfirm:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	calr VwBoxProc
	lda xbc, (xsp+264)
	ld XWA, (xsp + 0x0114)
	calr GetClientBox
	lda xwa, (xsp+264)
	lda xbc, (xsp+260)
	calr GetBoxCenter
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0110)
	or xwa, xwa
	jr nz, PsParaBox_UseEventText
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp (xsp + 4), 0x0
	jr nz, PsParaBox_DrawAligned
	jr PsParaBox_ReturnZero

PsParaBox_UseEventText:
	ld XWA, (xsp + 0x0110)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsParaBox_DrawAligned:
	lda xwa, (xsp+264)
	lda xhl, (xsp+260)
	lda xde, (xsp + 4)
	ld xbc, (xiz + 28)
	push xbc
	pushw	(xiz+32)
	pushw	(xiz+22)
	ld c, (xiz + 34)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringAlignment
	jr PsParaBox_ReturnZero

PsParaBox_HandleGetText:
	ld XWA, (xsp + 0x0110)
	ld (xwa), 0x0

PsParaBox_ReturnZero:
	ld xhl, 0:i3

PsParaBox_Epilogue:
	pop xiz
	lda xsp, (xsp+276)
	ret

AcLswBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xwa
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcLswBox_HandlePageDown
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcLswBox_HandlePageUp
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcLswBox_HandleScrollDown
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcLswBox_HandleScrollUp
	cp xbc, EVT_LSW_DATA
	jrl z, AcLswBox_HandleWriteBack
	cp xbc, EVT_REPAINT
	jr z, AcLswBox_HandleShowHide
	cp xbc, EVT_PAINT
	jr z, AcLswBox_HandleShowHide
	cp xbc, EVT_HIDE
	jr z, AcLswBox_HandleClose
	cp xbc, EVT_SHOW
	jr z, AcLswBox_HandleCreate
	cp xbc, EVT_GET_STRING
	jrl nz, AcLswBox_DefaultHandler
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 4)
	ld (xde), xhl
	ld xwa, (xiz + 40)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 16)
	ld (xde + 8), xwa
	ld xwa, (xiz + 36)
	ld xbc, EVT_GET_LSW_STRING
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
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
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
	ld xbc, EVT_GET_LSW_ADDRESS
	ld xde, 0:i3
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
	ld xbc, EVT_LSW_DATA_REQ
	call ApFuncCall
	ld xwa, (xsp + 20)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, EVT_CALC_PARAM
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, EVT_CALC_PARAM
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl

Ac_SendUIEvent_Common:
	call SendEvent

AcLswBox_ReturnZeroJmp:
	ld xhl, 0:i3
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
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcRamBox_HandlePageDown
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcRamBox_HandlePageUp
	cp xbc, EVT_INDEXSW_UP
	jrl z, AcRamBox_HandleScrollDown
	cp xbc, EVT_INDEXSW_UP_AIC
	jrl z, AcRamBox_HandleScrollUp
	cp xbc, EVT_RAM_DATA
	jrl z, AcRamBox_HandleWriteBack
	cp xbc, EVT_REFRESH_PARA_DRAW
	jr z, AcRamBox_HandleDataRefresh
	cp xbc, EVT_REPAINT
	jr z, AcRamBox_HandleShowHide
	cp xbc, EVT_PAINT
	jr z, AcRamBox_HandleShowHide
	cp xbc, EVT_GET_STRING
	jrl nz, AcRamBox_DefaultHandler
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	ld xwa, (xiz + 40)
	ld xwa, (xwa)
	ld (xde + 14), xwa
	ld xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xiz + 36)
	ld xbc, EVT_GET_RAM_STRING
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 36)
	ld xbc, EVT_GET_RAM_SIZE
	ld xde, 0:i3
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
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
	ld xbc, EVT_RAM_DATA_REQ
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_LARGE_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, EVT_GET_SMALL_STEP
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl

AcRamBox_SendUIEvent_Common:
	call SendEvent

AcRamBox_EventReturn:
	ld xhl, 0:i3
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
	lda xsp, (xsp-260)
	push xiz
	ld xiz, xde
	ld	(xsp+260), xwa
	cp xbc, EVT_LSW_DATA
	jr z, AcTempoBox_HandleConfirm
	cp xbc, EVT_REPAINT
	jr z, AcTempoBox_HandleShowHide
	cp xbc, EVT_PAINT
	jr z, AcTempoBox_HandleShowHide
	cp xbc, EVT_HIDE
	jr z, AcTempoBox_HandleClose
	cp xbc, EVT_SHOW
	jr z, AcTempoBox_HandleCreate
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	jrl AcTempoBox_Epilogue

AcTempoBox_HandleCreate:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	jr AcTempoBox_CallPsParaBox

AcTempoBox_HandleClose:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz

AcTempoBox_CallPsParaBox:
	calr PsParaBoxProc
	jr PsRadioBox_EventReturn

AcTempoBox_HandleShowHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, 4:i3
	calr MainLswGet
	jr PsRadioBox_EventReturn

AcTempoBox_HandleConfirm:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	calr PsParaBoxProc
	ld xwa, (xiz)
	cp xwa, 0x4
	jr z, AcTempoBox_MatchTempoID
	ld xwa, (xiz)
	cp xwa, 0x2200
	jr nz, PsRadioBox_EventReturn

AcTempoBox_MatchTempoID:
	ld xwa, 0x2200
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr nz, AcTempoBox_CopyTempoString
	ld xwa, 4:i3
	call SndParam_LookupReadOnly
	pushw hl
	pushw AcTempoBox_MatchTempoID_Str_aa_Fmt3d@hi16
	pushw AcTempoBox_MatchTempoID_Str_aa_Fmt3d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	jr AcTempoBox_SendConfirmEvent

AcTempoBox_CopyTempoString:
	pushw AcTempoBox_CopyTempoString_Str_aa@hi16
	pushw AcTempoBox_CopyTempoString_Str_aa@lo16
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

AcTempoBox_SendConfirmEvent:
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsRadioBox_EventReturn:
	ld xhl, 0:i3

AcTempoBox_Epilogue:
	pop xiz
	lda xsp, (xsp+260)
	ret

PsRadioBoxProc:
	lda xsp, (xsp-292)
	push xiz
	ld	(xsp+284), xde
	ld	(xsp+288), xbc
	ld	(xsp+292), xwa
	ld XWA, (xsp + 0x0120)
	cp xwa, EVT_CHECK_EDIT_SW
	jrl z, PsRadioBox_HitTest
	cp xwa, EVT_GET_STRING
	jrl z, PsRadioBox_GetText
	cp xwa, EVT_SET_SELECTED
	jrl z, PsRadioBox_SetIndex
	cp xwa, EVT_YOU_ARE_SELECTED
	jrl z, PsRadioBox_RadioSelect
	cp xwa, EVT_INDEX_SELECT
	jrl z, PsRadioBox_Release
	cp xwa, EVT_SW_IN
	jrl z, PsRadioBox_OK
	cp xwa, EVT_CHANGE_DIAL_FOCUS
	jrl z, PsRadioBox_Reset
	cp xwa, EVT_SELE_DRAW
	jrl z, PsRadioBox_Select
	cp xwa, EVT_PARA_DRAW
	jr z, PsRadioBox_Confirm
	cp xwa, EVT_DRAW
	jrl nz, PsRadioBox_Default
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	lda xbc, (xsp+272)
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	cpw	(xsp+274), 0x00ef
	jr z, PsRadioBox_Paint_SendConfirm
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr DrawEditSw

PsRadioBox_Paint_SendConfirm:
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Confirm:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	calr VwBoxProc
	lda xbc, (xsp+276)
	ld XWA, (xsp + 0x0124)
	calr GetClientBox
	lda xwa, (xsp+276)
	lda xbc, (xsp+272)
	calr GetBoxCenter
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xde, (xsp + 16)
	ld XWA, (xsp + 0x011c)
	or xwa, xwa
	jr nz, PsRadioBox_Confirm_CopyText
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp (xsp + 16), 0x0
	jr nz, PsRadioBox_Confirm_Draw
	jrl PsRadioBox_ReturnZero

PsRadioBox_Confirm_CopyText:
	ld XWA, (xsp + 0x011c)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsRadioBox_Confirm_Draw:
	calr GetDialFocus
	lda xwa, (xsp+276)
	lda xbc, (xsp+272)
	ld (xsp + 12), xbc
	lda xbc, (xsp + 16)
	ld (xsp + 8), xbc
	ld xbc, (xsp + 4)
	lda xde, (xbc + 22)
	lda xiz, (xbc + 28)
	lda xiy, (xbc + 32)
	ld c, (xbc + 34)
	ldfr_berp C, 0xf0
	extz ix
	cp	xhl, (xsp+292)
	jr nz, PsRadioBox_Confirm_DrawUnfocused
	ld xbc, (xiz)
	push xbc
	pushw	(xiy)
	pushw	(xde)
	pushw ix
	pushw 0x1
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)
	jr PsRadioBox_Confirm_DrawCall

PsRadioBox_Confirm_DrawUnfocused:
	ld xbc, (xiz)
	push xbc
	pushw	(xiy)
	pushw	(xde)
	pushw ix
	pushw 0x0
	ld xbc, (xsp + 24)
	ld xde, (xsp + 20)

PsRadioBox_Confirm_DrawCall:
	call DrawStringReverse
	jrl PsRadioBox_ReturnZero

PsRadioBox_Select:
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	calr GetDialFocus
	cp	xhl, (xsp+292)
	jr nz, PsRadioBox_Select_GetIndex
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_DRAW_SELECTED
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Select_GetIndex:
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 38)
	ld de, (xwa)
	exts xde
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_DRAW_SELECTED
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	calr VwBoxProc
	calr GetDialFocus
	cp	xhl, (xsp+292)
	jr nz, PsRadioBox_Reset_CheckValue
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset_CheckValue:
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, PsRadioBox_ReturnZero
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_OK:
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_CHECK_EDIT_SW
	ld XDE, (xsp + 0x011c)
	call SendEvent
	or xhl, xhl
	jr z, PsRadioBox_OK_Forward
	ld xwa, (xsp + 12)
	cpw (xwa + 26), 0xffff
	jr z, PsRadioBox_OK_Forward
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_OK_Forward:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	jrl PsRadioBox_CallVwBoxProc

PsRadioBox_Release:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+284)
	jrl nz, PsRadioBox_ReturnZero
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, PsRadioBox_ReturnZero
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_RadioSelect:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	lda xwa, (xhl + 26)
	cpw (xwa), 0xffff
	jrl z, PsRadioBox_ReturnZero
	ld XBC, (xsp + 0x011c)
	srl xbc, 16
	ldiw_erp 0xe6, 0
	ld wa, (xwa)
	cp wa, bc
	jrl nz, PsRadioBox_ReturnZero
	ld XWA, (xsp + 0x011c)
	ld bc, (xhl + 42)
	cp bc, wa
	jrl nz, PsRadioBox_ReturnZero
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	jr PsRadioBox_DispatchAndReturn

PsRadioBox_SetIndex:
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xbc, (xsp + 12)
	ld xwa, (xbc + 38)
	ld wa, (xwa)
	exts xwa
	cp	xwa, (xsp+284)
	jr z, PsRadioBox_ReturnZero
	ld XWA, (xsp + 0x011c)
	cp wa, 1:i3
	jr nz, PsRadioBox_SetIndex_Store
	ld de, (xbc + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld xwa, (xsp + 12)
	ld bc, (xwa + 42)
	extz xbc
	ld wa, (xwa + 26)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, EVT_I_AM_SELECTED
	call SendEvent

PsRadioBox_SetIndex_Store:
	ld xwa, (xsp + 12)
	ld xbc, (xwa + 38)
	ld XWA, (xsp + 0x011c)
	ld (xbc), wa
	ld XWA, (xsp + 0x0124)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3

PsRadioBox_DispatchAndReturn:
	call SendEvent
	jr PsRadioBox_ReturnZero

PsRadioBox_GetText:
	ld XWA, (xsp + 0x011c)
	ld (xwa), 0x0

PsRadioBox_ReturnZero:
	ld xhl, 0:i3
	jr PsRadioBox_Return

PsRadioBox_HitTest:
	ld XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld XDE, (xsp + 0x011c)
	call SendEvent
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	extz xwa
	cp xwa, xhl
	scc16 z, hl
	extz xhl
	jr PsRadioBox_Return

PsRadioBox_Default:
	ld XWA, (xsp + 0x0124)
	ld XBC, (xsp + 0x0120)
	ld XDE, (xsp + 0x011c)

PsRadioBox_CallVwBoxProc:
	calr VwBoxProc

PsRadioBox_Return:
	pop xiz
	lda xsp, (xsp+292)
	ret

AcStrRadioBoxProc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_GET_STRING
	jr z, AcStrRadioBox_GetText
	ld xde, xiz
	calr PsRadioBoxProc
	jr AcStrRadioBox_Epilogue

AcStrRadioBox_GetText:
	call GetViewInstance
	ld xwa, (xhl + 44)
	push xwa
	push xiz
	call Strcpy
	inc 8, xsp
	ld xhl, 0:i3

AcStrRadioBox_Epilogue:
	pop xiz
	ret

PsListBoxProc:
	lda xsp, (xsp-298)
	push xiz
	ld	(xsp+294), xde
	ld	(xsp+298), xwa
	cp xbc, EVT_GET_STRING
	jrl z, PsListBox_GetText
	cp xbc, EVT_SET_SELECTED
	jrl z, PsListBox_SetIndex
	cp xbc, EVT_GET_SELECTED
	jrl z, PsListBox_GetCount
	cp xbc, EVT_CHANGE_DIAL_FOCUS
	jrl z, PsListBox_Reset
	cp xbc, EVT_SELE_DRAW
	jrl z, PsListBox_Select
	cp xbc, EVT_PARA_DRAW
	jr z, PsListBox_Confirm
	cp xbc, EVT_DRAW
	jrl nz, PsListBox_Default
	ld XWA, (xsp + 0x012a)
	ld XDE, (xsp + 0x0126)
	calr VwBoxProc
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld iz, (xwa)
	ldw (xwa), 0xffff
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld de, iz
	exts xde
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_SELE_DRAW
	jrl PsListBox_SendEvent

PsListBox_Confirm:
	ld XWA, (xsp + 0x012a)
	ld XDE, (xsp + 0x0126)
	calr VwBoxProc
	lda xde, (xsp + 26)
	ld XWA, (xsp + 0x0126)
	or xwa, xwa
	jr nz, PsListBox_Confirm_CopyText
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_GET_STRING
	call SendEvent
	jr PsListBox_Confirm_Layout

PsListBox_Confirm_CopyText:
	ld XWA, (xsp + 0x0126)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsListBox_Confirm_Layout:
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	lda xbc, (xsp+286)
	ld XWA, (xsp + 0x012a)
	calr GetClientBox
	lda xwa, (xsp+286)
	lda xhl, (xwa + 6)
	ld de, (xwa + 2)
	ld wa, (xhl)
	sub wa, de
	lda xix, (xiz + 36)
	ld bc, (xix)
	extz xwa
	div xwa, bc
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
	incw 1, (xsp + 12)
	jr PsListBox_Confirm_DrawItem

PsListBox_Confirm_AdvanceChar:
	incw 1, (xsp + 12)

PsListBox_Confirm_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cp a, 0:i3
	jr nz, PsListBox_Confirm_ScanPipe

PsListBox_Confirm_DrawItem:
	lda xwa, (xsp+286)
	lda xbc, (xsp+282)
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
	lda xbc, (xsp+282)
	lda xix, (xwa + 32)
	cp de, (xsp + 10)
	jr nz, PsListBox_Confirm_ItemUnfocused
	lda xiz, (xsp+286)
	ld (xsp + 18), xbc
	ld xwa, (xiy)
	push xwa
	pushw	(xix)
	ld xwa, (xsp + 28)
	pushw	(xwa)
	pushw hl
	calr GetDialFocus
	cp	xhl, (xsp+308)
	scc16 z, wa
	pushw wa
	ld xwa, xiz
	ld xbc, (xsp + 30)
	ld xde, (xsp + 26)
	jr PsListBox_Confirm_RenderText

PsListBox_Confirm_ItemUnfocused:
	lda xwa, (xsp+286)
	ld xde, (xiy)
	push xde
	pushw	(xix)
	ld xde, (xsp + 28)
	pushw	(xde)
	pushw hl
	pushw 0x0
	ld xde, (xsp + 26)

PsListBox_Confirm_RenderText:
	call DrawStringReverse
	lda xbc, (xsp+286)
	ld wa, (xsp + 8)
	add (xbc + 2), wa
	add (xbc + 6), wa
	incw 1, (xsp + 10)
	ld xwa, (xsp + 4)
	ld bc, (xsp + 10)
	cp bc, (xwa + 36)
	jrl c, PsListBox_Confirm_ItemLoop
	jrl PsListBox_ReturnZero

PsListBox_Select:
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 4), xwa
	lda xwa, (xwa + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp	xbc, (xsp+294)
	jrl z, PsListBox_ReturnZero
	ld xwa, (xwa)
	cpw (xwa), 0xffff
	jrl z, PsListBox_Select_UpdateCurrent
	lda xbc, (xsp+286)
	ld XWA, (xsp + 0x012a)
	calr GetClientBox
	lda xwa, (xsp+286)
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
	incw 1, (xwa)
	decw	1, (xwa+4)
	ld bc, (xix)
	add bc, (xsp + 8)
	inc 1, bc
	ld (xiy), bc
	lda xbc, (xsp+282)
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_GET_STRING
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
	incw 1, (xsp + 12)
	jr PsListBox_Select_NextItem

PsListBox_Select_NextChar:
	incw 1, (xsp + 12)

PsListBox_Select_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cp a, 0:i3
	jr nz, PsListBox_Select_CheckPipe

PsListBox_Select_NextItem:
	incw 1, (xsp + 10)

PsListBox_Select_CheckDone:
	ld xhl, (xsp + 4)
	ld xwa, (xhl + 38)
	ld wa, (xwa)
	cp (xsp + 10), wa
	jr ule, PsListBox_Select_ScanItems
	lda xde, (xsp+286)
	lda xbc, (xsp+282)
	ld xwa, (xhl + 28)
	push xwa
	pushw	(xhl+32)
	ld xwa, xhl
	pushw	(xwa+22)
	ld a, (xwa + 34)
	extz wa
	pushw wa
	pushw 0x0
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	calr GetDialFocus
	cp	xhl, (xsp+298)
	jr z, PsListBox_Select_UpdateCurrent
	lda xwa, (xsp+286)
	ld xbc, (xsp + 4)
	pushw	(xbc+22)
	ld bc, 1:i3
	ld de, 2:i3
	calr DrawDesignFrame

PsListBox_Select_UpdateCurrent:
	ld xwa, (xsp + 22)
	ld xbc, (xwa + 38)
	ld XWA, (xsp + 0x0126)
	ld (xbc), wa
	lda xbc, (xsp+286)
	ld XWA, (xsp + 0x012a)
	calr GetClientBox
	lda xwa, (xsp+286)
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
	incw 1, (xwa)
	decw	1, (xwa+4)
	ld bc, (xix)
	add bc, (xsp + 8)
	inc 1, bc
	ld (xiy), bc
	lda xbc, (xsp+282)
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_GET_STRING
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
	incw 1, (xsp + 12)
	jr PsListBox_SelectUpd_NextItem

PsListBox_SelectUpd_NextChar:
	incw 1, (xsp + 12)

PsListBox_SelectUpd_ScanLoop:
	ld wa, (xsp + 12)
	extz xwa
	ld xbc, xde
	add xbc, xwa
	ld a, (xbc)
	cp a, 0:i3
	jr nz, PsListBox_SelectUpd_CheckPipe

PsListBox_SelectUpd_NextItem:
	incw 1, (xsp + 10)

PsListBox_SelectUpd_CheckDone:
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 38)
	ld wa, (xwa)
	cp (xsp + 10), wa
	jr ule, PsListBox_SelectUpd_ScanItems
	calr GetDialFocus
	lda xbc, (xsp+282)
	ld xwa, (xsp + 22)
	lda xiy, (xwa + 32)
	lda xde, (xsp+286)
	lda xiz, (xwa + 28)
	ld xwa, (xsp + 4)
	ld a, (xwa + 34)
	ldfr_berp A, 0xf0
	extz ix
	cp	xhl, (xsp+298)
	jr nz, PsListBox_SelectUpd_DrawUnfocused
	ld xwa, (xiz)
	push xwa
	pushw	(xiy)
	ld xwa, (xsp + 10)
	pushw	(xwa+22)
	pushw ix
	pushw 0x1
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	jrl PsListBox_ReturnZero

PsListBox_SelectUpd_DrawUnfocused:
	ld xwa, (xiz)
	push xwa
	pushw	(xiy)
	ld xwa, (xsp + 28)
	pushw	(xwa+22)
	pushw ix
	pushw 0x0
	ld xwa, xde
	ld xde, (xsp + 26)
	call DrawStringReverse
	lda xwa, (xsp+286)
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	calr DrawDesignFrame
	jrl PsListBox_ReturnZero

PsListBox_Reset:
	ld XWA, (xsp + 0x012a)
	ld XDE, (xsp + 0x0126)
	calr VwBoxProc
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld de, (xwa)
	exts xde
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_SELE_DRAW
	jr PsListBox_SendEvent

PsListBox_GetCount:
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld hl, (xwa)
	exts xhl
	jr PsListBox_Return

PsListBox_SetIndex:
	ld XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld wa, (xwa)
	exts xwa
	cp	xwa, (xsp+294)
	jr z, PsListBox_ReturnZero
	ld wa, (xhl + 36)
	extz xwa
	cp	(xsp+294), xwa
	jr nc, PsListBox_ReturnZero
	ld XWA, (xsp + 0x012a)
	ld xbc, EVT_SELE_DRAW
	ld XDE, (xsp + 0x0126)

PsListBox_SendEvent:
	call SendEvent
	jr PsListBox_ReturnZero

PsListBox_GetText:
	pushw PsListBox_GetText_Str_No_My_Car_Day_Memory_AyaSam@hi16
	pushw PsListBox_GetText_Str_No_My_Car_Day_Memory_AyaSam@lo16
	ld XWA, (xsp + 0x012a)
	push xwa
	call Strcpy
	inc 8, xsp

PsListBox_ReturnZero:
	ld xhl, 0:i3
	jr PsListBox_Return

PsListBox_Default:
	ld XWA, (xsp + 0x012a)
	ld XDE, (xsp + 0x0126)
	calr VwBoxProc

PsListBox_Return:
	pop xiz
	lda xsp, (xsp+298)
	ret

AcListBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xwa
	cp xbc, EVT_GET_STRING
	jrl z, AcListBox_GetText
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, AcListBox_ScrollDownInc
	cp xbc, EVT_INDEXSW_DOWN_AIC
	jrl z, AcListBox_ScrollDownInc
	cp xbc, EVT_INDEXSW_UP
	jr z, AcListBox_ScrollUpDown
	cp xbc, EVT_INDEXSW_UP_AIC
	jr z, AcListBox_ScrollUpDown
	cp xbc, EVT_SHOW
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
	ld xbc, EVT_INDEXSW_DOWN
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP
	calr SetDialDown
	ld wa, 1:i3
	jrl AcListBox_EnableDials

AcListBox_ScrollUpDown:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_SELECTED
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	calr SetDialDown
	ld wa, 1:i3
	jr AcListBox_EnableDials

AcListBox_ScrollDownInc:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_SELECTED
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	calr SetDialDown
	ld wa, 1:i3

AcListBox_EnableDials:
	calr SetDialEnable
	jr AcListBox_ReturnZero

AcListBox_GetText:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xhl + 42)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp

AcListBox_ReturnZero:
	ld xhl, 0:i3
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
	lda xsp, (xsp-334)
	push xiz
	ld	(xsp+326), xde
	ld	(xsp+330), xbc
	ld	(xsp+334), xwa
	ld XBC, (xsp + 0x014a)
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, PsGridBox_Scroll
	ld XWA, (xsp + 0x014a)
	cp xwa, EVT_INDEXSW_DOWN_AIC
	jrl z, PsGridBox_Scroll
	cp xwa, EVT_INDEXSW_UP
	jrl z, PsGridBox_Scroll
	cp xwa, EVT_INDEXSW_UP_AIC
	jrl z, PsGridBox_Scroll
	cp xwa, EVT_SELE_DRAW
	jrl z, PsGridBox_Select
	cp xwa, EVT_PARA_DRAW
	jrl z, PsGridBox_Confirm
	cp xwa, EVT_DRAW
	jrl z, PsGridBox_Paint
	cp xwa, EVT_REPAINT
	jrl z, PsGridBox_ShowHide
	cp xwa, EVT_PAINT
	jrl z, PsGridBox_ShowHide
	cp xwa, EVT_HIDE
	jrl z, PsGridBox_Close
	cp xwa, EVT_SHOW
	jr z, PsGridBox_Init
	sub xbc, EVT_GET_FIXED_COL_STR
	cp xbc, 0x0
	jrl lt, PsGridBox_Default
	cp xbc, 0x7
	jrl gt, PsGridBox_Default
	add xbc, xbc
	add xbc, PsGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (PsGridBox_Init:24)
; Computed jump: target = PsGridBox_Init + PsGridBoxProc_CaseTable[i], PsGridBoxProc_CaseTable = 16-bit offsets (8 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e0008a:
;   0x1e0008a -> 0xf9e7f5
;   0x1e0008b -> 0xf9e7fc
;   0x1e0008c -> 0xf9e6b9
;   0x1e0008d -> 0xf9e7b3
;   0x1e0008e -> 0xf9e811
;   0x1e0008f -> 0xf9e8ed
;   0x1e00090 -> PsGridBox_Default
;   0x1e00091 -> 0xf9e90d
	jp	t, (xix+bc)

	.include "ui/psgridbox_routines.s"
	.include "ui/ui_widget_defs.s"
IsPointOnScreen:
	cpw (xwa), 0x0
	jr lt, IsPointOnScreen_OutOfBounds
	cpw (xwa), 0x140
	jr ge, IsPointOnScreen_OutOfBounds
	ld wa, (xwa + 2)
	cp wa, 0:i3
	jr lt, IsPointOnScreen_OutOfBounds
	cp wa, 0xf0
	jr lt, IsPointOnScreen_InBounds

IsPointOnScreen_OutOfBounds:
	ld hl, 0:i3
	ret

IsPointOnScreen_InBounds:
	ld hl, 1:i3
	ret

IsColorValid:
	cp wa, 0:i3
	jr lt, IsColorValid_Check256
	cp wa, 0xff
	jr le, IsColorValid_Valid

IsColorValid_Check256:
	cp wa, 0x100
	jr lt, IsColorValid_Invalid
	cp wa, 0x100
	jr gt, IsColorValid_Invalid

IsColorValid_Valid:
	ld hl, 1:i3
	ret

IsColorValid_Invalid:
	ld hl, 0:i3
	ret

ClampColorToRange:
	ld hl, bc
	cp bc, 0:i3
	ret lt
	cp bc, 0xff
	ret gt
	ret

DrawDesignBox_ByteData:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, ClampColorToRange_Skip
	cpw	(0x03044e:24), 0
	jr	z, ClampColorToRange_Epilogue
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	ClampColorToRange_Helper
	jr	ClampColorToRange_Epilogue
ClampColorToRange_Skip:
	ldw	wa, 14
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (DrawDesignBox_ByteData_Code:24)
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	ldiw
	ldiw
	ld	xbc, (xsp+6)
	ld	xiy, xbc
	lda	xix, (xwa+8)
	ldiw
	ldiw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	calr	DrawRing_Post
ClampColorToRange_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
DrawDesignBox_ByteData_Code:
	lda	xhl, (xwa+4)
	lda	xbc, (xwa+8)
	ld	de, (xwa+12)
	cpw	(0x03044e:24), 0
	ret	z
	ld	xwa, xhl
	calr	ClampColorToRange_Helper
	ret
ClampColorToRange_Helper:
	lda	xsp, (xsp-52)
	push	xiz
	ld	(xsp+46), de
	ld	(xsp+48), xbc
	ld	(xsp+52), xwa
	ld	(xsp+20), 0
	ld	xde, 0xffffffff
	ld	xwa, (xsp+48)
	ld	bc, (xwa)
	ld	xwa, (xsp+52)
	cp	bc, (xwa)
	jr	le, ClampColorToRange_Skip2
	ld	xde, 1:i3
ClampColorToRange_Skip2:
	ld	(xsp+12), xde
	ld	xde, 0xffffffff
	ld	xwa, (xsp+48)
	inc	2, xwa
	ld	(xsp+22), xwa
	ld	xwa, (xsp+52)
	inc	2, xwa
	ld	(xsp+26), xwa
	ld	xwa, (xsp+22)
	ld	bc, (xwa)
	ld	xwa, (xsp+26)
	ld	hl, (xwa)
	cp	bc, hl
	jr	le, ClampColorToRange_Skip3
	ld	xde, 1:i3
ClampColorToRange_Skip3:
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, ClampColorToRange_Skip4
	ld	xwa, (xsp+48)
	ld	de, (xwa)
	ld	xwa, (xsp+52)
	sub	de, (xwa)
	jr	ClampColorToRange_Join
ClampColorToRange_Skip4:
	ld	xwa, (xsp+52)
	ld	de, (xwa)
	ld	xwa, (xsp+48)
	sub	de, (xwa)
ClampColorToRange_Join:
	exts	xde
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, ClampColorToRange_Skip5
	sub	bc, hl
	ld	hl, bc
	jr	ClampColorToRange_Join2
ClampColorToRange_Skip5:
	sub	hl, bc
ClampColorToRange_Join2:
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, ClampColorToRange_Skip6
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, ClampColorToRange_Epilogue2
ClampColorToRange_Skip6:
	ld	xwa, (xsp+52)
	ld	xiy, xwa
	lda	xix, (xsp+42)
	ldiw
	ldiw
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, ClampColorToRange_Skip9
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, ClampColorToRange_Join7
ClampColorToRange_Loop:
	cp	(xsp+20), 3
	jr	ule, ClampColorToRange_Skip7
	ld	(xsp+20), 0
	jr	ClampColorToRange_Join3
ClampColorToRange_Skip7:
	cp	(xsp+20), 1
	jr	ugt, ClampColorToRange_Skip8
	lda	xwa, (xsp+42)
	ld	de, (xwa+2)
	exts	xde
	ld	xhl, xde
	sll	xhl, 2
	add	xhl, xde
	sll	xhl, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xhl
	ld	xde, OFFSCREEN_BUFFER_1
	add	xde, xwa
	ld	wa, (xsp+46)
	ld	(xde), a
ClampColorToRange_Skip8:
	inc	1, (xsp+20)
ClampColorToRange_Join3:
	ld	xwa, (xsp+16)
	add	(xsp+44), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, ClampColorToRange_Loop
	jrl	ClampColorToRange_Join7
ClampColorToRange_Skip9:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, ClampColorToRange_Skip12
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, ClampColorToRange_Join7
ClampColorToRange_Loop2:
	cp	(xsp+20), 3
	jr	ule, ClampColorToRange_Skip10
	ld	(xsp+20), 0
	jr	ClampColorToRange_Join4
ClampColorToRange_Skip10:
	cp	(xsp+20), 1
	jr	ugt, ClampColorToRange_Skip11
	lda	xwa, (xsp+42)
	ld	de, (xwa+2)
	exts	xde
	ld	xhl, xde
	sll	xhl, 2
	add	xhl, xde
	sll	xhl, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xhl
	ld	xde, OFFSCREEN_BUFFER_1
	add	xde, xwa
	ld	wa, (xsp+46)
	ld	(xde), a
ClampColorToRange_Skip11:
	inc	1, (xsp+20)
ClampColorToRange_Join4:
	ld	xwa, (xsp+12)
	add	(xsp+42), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, ClampColorToRange_Loop2
	jrl	ClampColorToRange_Join7
ClampColorToRange_Skip12:
	lda	xwa, (xsp+42)
	ld	(xsp+30), xwa
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jrl	le, ClampColorToRange_Skip15
	ld	xwa, (xsp+4)
	sla	xwa, 16
	ld	xbc, (xsp+8)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+12)
	ld	xbc, xiz
	call	Math_MultiplyAccumulate
	ld	(xsp+12), xhl
	ld	xde, (xsp+30)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 16
	ld	(xsp+4), xwa
	ld	xwa, 0x8000
	add	(xsp+4), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, ClampColorToRange_Join7
ClampColorToRange_Loop3:
	cp	(xsp+20), 3
	jr	ule, ClampColorToRange_Skip13
	ld	(xsp+20), 0
	jr	ClampColorToRange_Join5
ClampColorToRange_Skip13:
	cp	(xsp+20), 1
	jr	ugt, ClampColorToRange_Skip14
	ld	wa, (xde+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xhl
	ld	xhl, OFFSCREEN_BUFFER_1
	add	xhl, xwa
	ld	wa, (xsp+46)
	ld	(xhl), a
ClampColorToRange_Skip14:
	inc	1, (xsp+20)
ClampColorToRange_Join5:
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 16
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xde+2), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, ClampColorToRange_Loop3
	jrl	ClampColorToRange_Join7
ClampColorToRange_Skip15:
	ld	xwa, (xsp+8)
	sla	xwa, 16
	ld	xbc, (xsp+4)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xde, (xsp+30)
	ld	xwa, xde
	lda	xhl, (xwa+2)
	ld	wa, (xhl)
	exts	xwa
	ld	(xsp+8), xwa
	sla	xwa, 16
	ld	(xsp+8), xwa
	ld	xwa, 0x8000
	add	(xsp+8), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	lt, ClampColorToRange_Join7
ClampColorToRange_Loop4:
	cp	(xsp+20), 3
	jr	ule, ClampColorToRange_Skip16
	ld	(xsp+20), 0
	jr	ClampColorToRange_Join6
ClampColorToRange_Skip16:
	cp	(xsp+20), 1
	jr	ugt, ClampColorToRange_Skip17
	ld	wa, (xhl)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xix
	ld	xix, OFFSCREEN_BUFFER_1
	add	xix, xwa
	ld	wa, (xsp+46)
	ld	(xix), a
ClampColorToRange_Skip17:
	inc	1, (xsp+20)
ClampColorToRange_Join6:
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 16
	ld	(xhl), wa
	ld	xwa, (xsp+12)
	add	(xde), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, ClampColorToRange_Loop4
ClampColorToRange_Join7:
	lda	xwa, (xsp+34)
	ld	xbc, (xsp+26)
	ld	bc, (xbc)
	ld	(xwa+2), bc
	ld	xbc, (xsp+52)
	ld	bc, (xbc)
	ld	(xwa), bc
	ld	xbc, (xsp+48)
	ld	bc, (xbc)
	ld	(xwa+4), bc
	ld	xbc, (xsp+22)
	ld	bc, (xbc)
	ld	(xwa+6), bc
	calr	SetChangeRect
ClampColorToRange_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+52)
	ret

DrawDesignBox:	; SysData_FAD559
	dec 4, xsp
	push xiz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, DrawDesignBox_QueuedPath
	cpw (0x03044e:24), 0
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
	lda xbc, (DrawDesignBox_QueueCallback:24)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ld bc, 4:i3
	ldirw
	ld bc, (xsp + 6)
	ld (xwa + 12), bc
	ld bc, (xsp + 4)
	ld (xwa + 14), bc
	calr DrawRing_Post

DrawDesignBox_DirectEpilogue:
	pop xiz
	inc 4, xsp
	ret

DrawDesignBox_QueueCallback:
	lda	xhl, (xwa+4)
	ld	bc, (xwa+12)
	ld	de, (xwa+14)
	cpw	(0x03044e:24), 0
	ret	z
	ld	xwa, xhl
	calr	DrawDesignBox_Impl
	ret

DrawDesignBox_Impl:
	lda xsp, (xsp - 74)
	push xiz
	ld (xsp + 70), de
	ld (xsp + 72), bc
	ld (xsp + 74), xwa
	ld xwa, 0:i3
	ld (xsp + 14), xwa
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 62)
	ld bc, 4:i3
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
	cp wa, 0:i3
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
	lda xix, (Draw_DispatchByPartType_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (Draw_StyledBoxWithFrame:24)
	jp	t, (xix+wa)

Draw_StyledBoxWithFrame:
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	jrl DrawFunc_Epilogue74
DrawDesignBox_Impl_Case185:
	lda xwa, (xsp + 62)
	decw	1, (xwa+4)
	decw	1, (xwa+6)
DrawDesignBox_Impl_Case184:
	lda xwa, (xsp + 62)
	decw	1, (xwa+4)
	decw	1, (xwa+6)
DrawDesignBox_Impl_Case181:	; cases 181, 182, 183
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 62)
	ld bc, 0:i3
	calr DrawFrame_Impl
	cpw (xsp + 72), 0x2
	jr nz, DrawDesignBox_After2Frame
	lda xwa, (xsp + 62)
	incw 1, (xwa + 2)
	decw	1, (xwa+6)
	incw 1, (xwa)
	decw	1, (xwa+4)
	ld bc, 0:i3
	calr DrawFrame_Impl

DrawDesignBox_After2Frame:
	cpw (xsp + 72), 0x3
	jr nz, DrawDesignBox_After3Frame
	lda xwa, (xsp + 62)
	incw 2, (xwa + 2)
	decw	2, (xwa+6)
	incw 2, (xwa)
	decw	2, (xwa+4)
	ld bc, 0:i3
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
	ld de, 0:i3
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
	ld de, 0:i3
	calr DrawLine_Impl

DrawDesignBox_4FrameCross:
	cpw (xsp + 72), 0x5
	jrl nz, DrawFunc_Epilogue74
	lda xiy, (xsp + 62)
	lda xix, (xsp + 54)
	ld bc, 4:i3
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
	ld bc, 0:i3
	calr DrawFrame_Impl
	lda xwa, (xsp + 62)
	lda xde, (xsp + 54)
	ld bc, (xde)
	inc 2, bc
	ld (xwa), bc
	ld bc, (xde + 6)
	inc 1, bc
	ld (xwa + 2), bc
	ld bc, 0:i3
	calr DrawFrame_Impl
	jrl DrawFunc_Epilogue74
DrawDesignBox_Impl_Case193:	; cases 193, 195
	ld xwa, 1:i3
	ld (xsp + 14), xwa
DrawDesignBox_Impl_Case192:	; cases 192, 194
	ld xwa, 1:i3
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
	ld xwa, 0:i3
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
	decw	1, (xbc+2)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 62)
	incw 1, (xwa + 2)
	decw	1, (xwa+6)
	incw 1, (xwa)
	decw	1, (xwa+4)
	ld xwa, 1:i3
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	cp xwa, (xsp + 14)
	jrl lt, DrawDesignBox_BorderLoop
	jrl DrawFunc_Epilogue74
DrawDesignBox_Impl_Case197:	; cases 197, 199
	ld xwa, 1:i3
	ld (xsp + 14), xwa
DrawDesignBox_Impl_Case196:	; cases 196, 198
	ld xwa, 1:i3
	add (xsp + 14), xwa
	lda xwa, (xsp + 62)
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	ld xwa, 0:i3
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
	decw	1, (xbc+2)
	ld de, (xsp + 4)
	calr DrawLine_Impl
	lda xwa, (xsp + 62)
	incw 1, (xwa + 2)
	decw	1, (xwa+6)
	incw 1, (xwa)
	decw	1, (xwa+4)
	ld xwa, 1:i3
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
	incw 1, (xwa + 2)
	decw	1, (xwa+6)
	cpw (xsp + 16), 0x0
	jr nz, DrawDesignBox_IconLeftWidth
	ld bc, 1:i3
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
	ld de, 0:i3
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
	ld de, 0:i3
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
	ld de, 0:i3
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
	ld de, 0:i3
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
	cp wa, 0:i3
	jr lt, DrawPartGroup_TableJump_DefaultCase
	cp wa, 7:i3
	jr le, DrawPartGroup_DispatchByType
	sub wa, 0x18
	cp wa, 0x8
	jr lt, DrawPartGroup_TableJump_DefaultCase
	cp wa, 0xf
	jr gt, DrawPartGroup_TableJump_DefaultCase

; DrawPartGroup dispatch by type
DrawPartGroup_DispatchByType:
	add wa, wa
	lda xix, (DrawPartGroup_DispatchByType_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (DrawPartGroup_TableJump_DefaultCase:24)
	jp	t, (xix+wa)

DrawPartGroup_TableJump_DefaultCase:
	ld iz, 0:i3
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	jrl DrawPartGroup_Loop

DrawPartGroup_Style8:
	ld iz, 4:i3
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
DrawDesignBox_PartGroupStyle_Case24:
	ld iz, 0:i3
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x1a
	jrl DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case32:
	ld iz, 0:i3
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x15
	jrl DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case25:
	ld iz, 4:i3
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x1b
	jrl DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case33:
	ld iz, 4:i3
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x16
	jrl DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case26:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x1c
	jrl DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case34:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x17
	jrl DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case27:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x1d
	jr DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case35:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x18
	jrl DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case28:
	ld iz, 0:i3
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x1e
	jr DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case29:
	ld iz, 4:i3
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x1f
	jr DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case30:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x20
	jr DrawPartGroup_WithAltFlag
DrawDesignBox_PartGroupStyle_Case31:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x21

DrawPartGroup_WithAltFlag:
	ldw (xsp + 16), 0x1
	jr DrawPartGroup_Loop
DrawDesignBox_PartGroupStyle_Case36:
	ld iz, 0:i3
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldiw_erp 0xfa, 3
	ldw (xsp + 12), 0x22
	jr DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case37:
	ld iz, 4:i3
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldiw_erp 0xfa, 7
	ldw (xsp + 12), 0x23
	jr DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case38:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xa
	ldi_erpw 0xfa, 0x0b, 0x00
	ldw (xsp + 12), 0x24
	jr DrawPartGroup_WithFlag
DrawDesignBox_PartGroupStyle_Case39:
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
	ldto_werp WA, 0xfa
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
	ld bc, 4:i3
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
	ldto_werp BC, 0xfa
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	incw 1, (xsp + 62)
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
	decw	1, (xsp+66)
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
	incw 1, (xwa + 2)
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
	ld de, 0:i3
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 6)
	ld bc, (xde)
	ld (xwa + 2), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc + 2), de
	ld de, 0:i3
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
	ld de, 0:i3
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
	ld de, 0:i3
	jrl DrawFunc_DrawLineAndReturn
DrawDesignBox_Impl_Case201:	; cases 201, 202
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
	ldto_werp WA, 0xfa
	call GetFrameSPSize
	ld xwa, (xsp + 74)
	ld xiy, xwa
	lda xix, (xsp + 54)
	ld bc, 4:i3
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
	ldto_werp BC, 0xfa
	ld de, (xsp + 70)
	calr DrawFrameSP_Impl
	lda xbc, (xsp + 62)
	incw 2, (xbc)
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
	decw	2, (xwa+4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 22)
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incw 2, (xwa + 2)
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
	incw 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incw 1, (xbc + 2)
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
	decw	1, (xwa+2)
	lda xbc, (xsp + 38)
	decw	1, (xbc+2)
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
	incw 1, (xwa)
	lda xbc, (xsp + 38)
	incw 1, (xbc)
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
	decw	1, (xwa)
	lda xbc, (xsp + 38)
	decw	1, (xbc)
	ld de, (xsp + 6)
	jrl DrawFunc_DrawLineAndReturn
DrawDesignBox_Impl_Case203:
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
	ld bc, 4:i3
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
	incw 2, (xbc)
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
	decw	2, (xwa+4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incw 2, (xwa + 2)
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
	incw 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incw 1, (xbc + 2)
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
	decw	1, (xwa+2)
	lda xbc, (xsp + 38)
	decw	1, (xbc+2)
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
	incw 1, (xwa)
	lda xbc, (xsp + 38)
	incw 1, (xbc)
	decw	1, (xbc+2)
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
	decw	1, (xwa)
	lda xbc, (xsp + 38)
	decw	1, (xbc)
	ldw de, 0xf8
	jrl DrawFunc_DrawLineAndReturn
DrawDesignBox_Impl_Case204:
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
	ld bc, 4:i3
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
	incw 2, (xbc)
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
	decw	2, (xwa+4)
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
	incw 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incw 1, (xbc + 2)
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
	decw	1, (xwa+2)
	lda xbc, (xsp + 38)
	decw	1, (xbc+2)
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
	incw 1, (xwa)
	lda xbc, (xsp + 38)
	incw 1, (xbc)
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
	decw	1, (xwa)
	lda xbc, (xsp + 38)
	decw	1, (xbc)
	incw 1, (xwa + 2)
	ldw de, 0xf8
	jrl DrawFunc_DrawLineAndReturn
DrawDesignBox_Impl_Case200:
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
	ld bc, 4:i3
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
	incw 2, (xbc)
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
	decw	2, (xwa+4)
	ld bc, (xsp + 34)
	sub (xsp + 58), bc
	ld bc, (xsp + 28)
	add (xwa + 2), bc
	ld bc, (xsp + 22)
	sub (xwa + 6), bc
	ld bc, (xsp + 70)
	calr DrawBox_Impl
	lda xwa, (xsp + 54)
	incw 2, (xwa + 2)
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
	ld de, 7:i3
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
	incw 1, (xwa + 2)
	lda xbc, (xsp + 38)
	incw 1, (xbc + 2)
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
	ld de, 0:i3
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
	decw	1, (xwa+2)
	lda xbc, (xsp + 38)
	decw	1, (xbc+2)
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
	ld de, 7:i3
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
	incw 1, (xwa)
	lda xbc, (xsp + 38)
	incw 1, (xbc)
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
	ld de, 0:i3
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
	decw	1, (xwa)
	lda xbc, (xsp + 38)
	decw	1, (xbc)
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
	ld	xbc, (0x030452:24)
	ld	(xsp+4), xbc
	ld	ix, (xwa+2)
	jr	DrawDesignBox_Impl_Join2
DrawDesignBox_Impl_Loop:
	ld	bc, ix
	extz	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	bc, (xwa)
	exts	xbc
	add	xbc, xde
	lda	xde, (OFFSCREEN_BUFFER_1:24)
	ld	xiz, xde
	add	xiz, xbc
	ld	iy, (xwa)
	jr	DrawDesignBox_Impl_Join
DrawDesignBox_Impl_Loop2:
	ld	xhl, xiz
	ld	xbc, xiz
	sub	xbc, xde
	inc	1, xiz
	add	xbc, (xsp+4)
	ld	c, (xbc)
	ld	(xhl), c
	inc	1, iy
DrawDesignBox_Impl_Join:
	ld	bc, (xwa+4)
	cp	iy, bc
	jr	ule, DrawDesignBox_Impl_Loop2
	inc	1, ix
DrawDesignBox_Impl_Join2:
	ld	bc, (xwa+6)
	cp	ix, bc
	jr	ule, DrawDesignBox_Impl_Loop
	calr	SetChangeRect
	pop	xiz
	inc	4, xsp
	ret

Gfx_ClearFrameBuffers:
	pushw 0x9600
	pushw 0x0
	ld xwa, OFFSCREEN_BUFFER_2
	push xwa
	call Memset
	pushw 0x9600
	pushw 0x0
	ld xwa, OFFSCREEN_BUFFER_3
	push xwa
	call Memset
	pushw 0x400
	pushw 0x0
	ld xwa, OFFSCREEN_BUFFER_4
	push xwa
	call Memset
	lda xsp, (xsp + 24)
	jrl Flash_SaveSplashScreen

Gfx_LoadSplashBMP:
	lda xsp, (xsp-1110)
	pushw iz
	lda xwa, (xsp+1098)
	ld xbc, 0xe
	call FileIO_ReadBlock
	ld iz, hl
	cp iz, 0xe
	jrl nz, SplashScreen_Return
	pushw 0x2
	pushw Gfx_LoadSplashBMP_Data@hi16
	pushw Gfx_LoadSplashBMP_Data@lo16
	lda xwa, (xsp+1104)
	push xwa
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, FileIO_ControllerValidationFailed
	lda xwa, (xsp+1058)
	ld xbc, 0x28
	call FileIO_ReadBlock
	ld iz, hl
	cp iz, 0x28
	jrl nz, SplashScreen_Return
	lda xbc, (xsp+1058)
	ld xwa, (xbc)
	cp xwa, 0x28
	jr nz, FileIO_ControllerValidationFailed
	cpw (xbc + 12), 0x1
	jr nz, FileIO_ControllerValidationFailed
	cpw (xbc + 14), 0x8
	jr ugt, FileIO_ControllerValidationFailed
	ld xwa, (xbc + 32)
	cp xwa, 0x100
	jr ugt, FileIO_ControllerValidationFailed
	ld XWA, (xsp + 0x0454)
	ld (xsp + 30), xwa
	ld xwa, 0x36
	sub (xsp + 30), xwa
	ld xwa, (xsp + 30)
	cp xwa, 0x400
	jr ule, SplashBMP_ValidateSize

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
	ld xde, OFFSCREEN_BUFFER_4
	ld xbc, OFFSCREEN_BUFFER_4
	ld xhl, 0x69800

SplashBMP_ClearPalette:
	ld xwa, 0xff000000
	ld (xbc+), XWA
	cp xbc, xhl
	jr c, SplashBMP_ClearPalette
	ld xwa, 0:i3
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
	ld xix, 0:i3
	ldfr_berp A, 0xf0
	sll xix, 8
	ld xwa, xbc
	ld xiy, xhl
	add xiy, xwa
	ld xwa, 0:i3
	ld a, (xiy + 1)
	add xix, xwa
	sll xix, 8
	ld xwa, xhl
	add xwa, xbc
	ld a, (xwa + 2)
	extz wa
	extz xwa
	add xix, xwa
	ld (xde+), XIX
	ld xwa, 1:i3
	add (xsp + 6), xwa
	ld xbc, (xsp + 6)
	cp xbc, (xsp + 30)
	jr c, SplashBMP_DecodePalette

SplashBMP_ReadInfoHeader:
	lda xbc, (xsp+1058)
	ld xwa, (xbc + 4)
	ld (xsp + 14), xwa
	ld xwa, (xbc + 8)
	ld (xsp + 2), xwa
	ld xwa, 0x8
	mrdw3 0x99, 0x0e, 0x50
	extz xwa
	ld (xsp + 30), xwa
	sla xwa, 2
	ld xbc, xwa
	dec 1, xwa
	add xwa, (xsp + 14)
	call Math_DivideSigned32
	ld (xsp + 18), xhl
	sla xhl, 2
	ld (xsp + 18), xhl
	ld xwa, xhl
	ld xbc, (xsp + 30)
	call Math_MultiplyAccumulate
	pushw hl
	call Malloc
	inc 2, xsp
	ld (xsp + 30), xhl
	ld xwa, (xsp + 30)
	ld (xsp + 26), xwa
	ld xwa, (xsp + 2)
	cp xwa, 0xf0
	jr le, SplashBMP_PrepareRowBuffer
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld xwa, (xsp + 2)
	sub xwa, 0xf0
	jr le, SplashBMP_ClampHeight

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
	ld xwa, 1:i3
	add (xsp + 6), xwa
	ld xwa, (xsp + 2)
	sub xwa, 0xf0
	cp (xsp + 6), xwa
	jr lt, SplashBMP_SkipExcessRows

SplashBMP_ClampHeight:
	ld xwa, 0xf0
	ld (xsp + 2), xwa

SplashBMP_PrepareRowBuffer:
	ld xwa, 0x140
	ld (xsp + 30), xwa
	ld xbc, (xsp + 2)
	dec 1, xbc
	ld xwa, (xsp + 30)
	call Math_MultiplyAccumulate
	ld (xsp + 30), xhl
	add xhl, OFFSCREEN_BUFFER_2
	ld (xsp + 22), xhl
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld xwa, (xsp + 2)
	cp xwa, 0x0
	jrl le, SplashBMP_PadRows

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
	call Free
	inc 4, xsp

SplashScreen_Return:
	ld hl, iz
	jrl SplashBMP_Return

SplashBMP_ProcessRow:
	ld	de, (xsp+1072)
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
	ld xwa, 0:i3
	ld (xsp + 10), xwa
	ld xbc, (xsp + 14)
	ld xwa, 0x140
	call Math_DivideSigned32
	cp xhl, 0x0
	jr le, SplashBMP_CopyRemainder

SplashBMP_TileNarrow:
	ld xwa, (xsp + 14)
	pushw wa
	ld xwa, (xsp + 28)
	push xwa
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 20)
	call Math_MultiplyAccumulate
	add xhl, (xsp + 28)
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 1:i3
	add (xsp + 10), xwa
	ld xbc, (xsp + 14)
	ld xwa, 0x140
	call Math_DivideSigned32
	cp (xsp + 10), xhl
	jr lt, SplashBMP_TileNarrow

SplashBMP_CopyRemainder:
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call Math_MultiplyAccumulate
	ld xwa, 0x140
	sub xwa, xhl
	pushw wa
	ld xwa, (xsp + 28)
	push xwa
	add xhl, (xsp + 28)
	push xhl

SplashBMP_CopyToFramebuffer:
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x140
	sub (xsp + 22), xwa
	ld xwa, 1:i3
	add (xsp + 6), xwa
	ld xwa, (xsp + 6)
	cp xwa, (xsp + 2)
	jrl lt, SplashBMP_ReadRowLoop

SplashBMP_PadRows:
	ld xbc, (xsp + 2)
	cp xbc, 0xf0
	jr ge, SplashBMP_Finish
	ld xwa, 0x140
	add (xsp + 30), xwa
	ld xwa, OFFSCREEN_BUFFER_2
	ld (xsp + 26), xwa
	ld xwa, (xsp + 30)
	add xwa, OFFSCREEN_BUFFER_2
	ld (xsp + 22), xwa
	ld (xsp + 6), xbc
	cp xbc, 0xf0
	jr ge, SplashBMP_Finish

SplashBMP_PadCopyLoop:
	pushw 0x140
	ld xwa, (xsp + 28)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x140
	add (xsp + 26), xwa
	add (xsp + 22), xwa
	ld xwa, 1:i3
	add (xsp + 6), xwa
	ld xwa, (xsp + 6)
	cp xwa, 0xf0
	jr lt, SplashBMP_PadCopyLoop

SplashBMP_Finish:
	calr Gfx_DecodeImageToBuffer
	calr Flash_SaveSplashScreen
	ld wa, 2:i3
	calr ChangePalette
	ld hl, 1:i3

SplashBMP_Return:
	popw iz
	lda xsp, (xsp+1110)
	ret

Gfx_ProcessSplashData:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 22), de
	ld (xsp + 24), xbc
	ld (xsp + 28), xwa
	cpw (xsp + 22), 0x18
	jrl z, SplashData_Epilogue
	ld xiz, 0x8
	mrdw3 0x9f, 0x16, 0x56
	ld wa, iz
	extz xwa
	ld xbc, (xsp + 24)
	call Math_MultiplyAccumulate
	ld (xsp + 18), xhl
	cpw (xsp + 22), 0x1
	jr z, SplashData_1bppSetup
	cpw (xsp + 22), 0x4
	jrl nz, SplashData_Epilogue
	ld (xsp + 8), iz
	ld xwa, (xsp + 18)
	ld (xsp + 4), xwa
	pushw hl
	call Malloc
	ld (xsp + 16), xhl
	ld xbc, (xsp + 16)
	ld (xsp + 12), xbc
	ld xwa, (xsp + 20)
	pushw wa
	ld xwa, (xsp + 32)
	push xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld xbc, 0:i3
	ld xwa, (xsp + 18)
	cp xwa, 0x0
	jr le, SplashData_4bppFree

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
	ld E, (xix+)
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
	ld (xsp + 8), iz
	ld xwa, (xsp + 18)
	ld (xsp + 4), xwa
	pushw hl
	call Malloc
	ld (xsp + 16), xhl
	ld xbc, (xsp + 16)
	ld (xsp + 12), xbc
	ld xwa, (xsp + 20)
	pushw wa
	ld xwa, (xsp + 32)
	push xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld xbc, 0:i3
	ld xwa, (xsp + 18)
	cp xwa, 0x0
	jrl le, SplashData_1bppFree

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
	ld E, (xix+)
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
	call Free
	inc 4, xsp

SplashData_Epilogue:
	pop xiz
	lda xsp, (xsp + 28)
	ret

Gfx_DecodeImageToBuffer:
	lda xsp, (xsp-1068)
	push xiz
	lda xbc, (xsp+560)
	ld (xsp + 32), xbc
	ld xwa, (xsp + 32)
	lda xwa, (xwa+512)
	ld (xsp + 40), xwa

ImageDecode_ClearPaletteLoop:
	ldw (xbc+), 0x0000
	cp xbc, xwa
	jr c, ImageDecode_ClearPaletteLoop
	ld xhl, OFFSCREEN_BUFFER_2
	ld ix, 0:i3

ImageDecode_RowLoop:
	ld iy, 0:i3

ImageDecode_PixelLoop:
	ld C, (xhl+)
	extz bc
	add bc, bc
	ld xwa, (xsp + 32)
	incw	1, (xwa+bc)
	inc 1, iy
	cp iy, 0x140
	jr lt, ImageDecode_PixelLoop
	inc 1, ix
	cp ix, 0xf0
	jr lt, ImageDecode_RowLoop
	lda xwa, (xsp+304)
	ld (xsp + 28), xwa
	ld c, 0x0:opc
	ld xde, (xsp + 28)
	ld xwa, xde
	lda xwa, (xwa+256)
	ld (xsp + 44), xwa

ImageDecode_SecondPassSetup:
	ld (xde+), c
	inc 1, c
	cp xde, xwa
	jr c, ImageDecode_SecondPassSetup
	ldw (xsp + 18), 0x0
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 40)

ImageDecode_CountNonZero:
	cpw (xwa), 0x0
	jr z, ImageDecode_CheckNextEntry
	incw 1, (xsp + 18)

ImageDecode_CheckNextEntry:
	inc 2, xwa
	cp xwa, xbc
	jr c, ImageDecode_CountNonZero
	ld xbc, 0x100

ImageDecode_PaletteReduceLoop:
	ld xwa, xbc
	ld xbc, 0xf4240
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, 0x13d620
	call Math_DivideSigned32
	ld bc, hl
	exts xbc
	ld xwa, xbc
	cp xbc, 0xa
	jr z, PaletteReduce_SpecialCase
	cp xwa, 0x9
	jr z, PaletteReduce_SpecialCase
	or xwa, xwa
	jr nz, PaletteReduce_StartSortPass
	ld xbc, 1:i3
	jr PaletteReduce_StartSortPass

PaletteReduce_SpecialCase:
	ld xbc, 0xb

PaletteReduce_StartSortPass:
	ld xwa, 0:i3
	ld (xsp + 20), xwa
	ld xwa, 0x100
	sub xwa, xbc
	ld (xsp + 24), xwa
	ld xhl, 0:i3
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
	add xix, OFFSCREEN_BUFFER_4
	ld xwa, (xix)
	ld xiy, (xsp + 36)
	sll xiy, 2
	add xiy, OFFSCREEN_BUFFER_4
	ld xde, (xiy)
	ld (xix), xde
	ld (xiy), xwa
	ld xwa, 1:i3
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
	ld c, 0x0:opc
	ld xde, (xsp + 28)
	ld xhl, (xsp + 44)

PaletteReduce_RemapPixels:
	ld A, (xde+)
	ldfr_berp A, 0xf0
	extz ix
	ld b, c
	ld xwa, (xsp + 32)
	ld	(xwa+ix), b
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
	ld xwa, 0:i3
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

PaletteReduce_FindClosest:
	ld xwa, (xsp + 8)
	sll xwa, 2
	add xwa, OFFSCREEN_BUFFER_4
	ld xwa, (xwa)
	ld (xsp + 44), xwa
	and xwa, 0xff00
	srl xwa, 8
	ld xde, xwa
	ld xwa, (xsp + 4)
	sll xwa, 2
	add xwa, OFFSCREEN_BUFFER_4
	ld xwa, (xwa)
	ld (xsp + 40), xwa
	and xwa, 0xff00
	srl xwa, 8
	ld xbc, xwa
	sub xbc, xde
	ld xwa, xbc
	call Math_MultiplyAccumulate
	ld (xsp + 24), xhl
	ld xde, (xsp + 44)
	and xde, 0xff
	ld xbc, (xsp + 40)
	and xbc, 0xff
	sub xbc, xde
	ld xwa, xbc
	call Math_MultiplyAccumulate
	ld (xsp + 20), xhl
	ld xwa, (xsp + 24)
	add (xsp + 20), xwa
	ld xwa, (xsp + 44)
	and xwa, MASK_BITS16_23
	srl xwa, 16
	ld xbc, (xsp + 40)
	and xbc, MASK_BITS16_23
	srl xbc, 16
	sub xbc, xwa
	ld xwa, xbc
	call Math_MultiplyAccumulate
	add xhl, (xsp + 20)
	cp (xsp + 12), xhl
	jr le, PaletteReduce_UpdateMinDist
	ld (xsp + 12), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 16), xwa

PaletteReduce_UpdateMinDist:
	ld xwa, 1:i3
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
	ld	(xwa+bc), e
	ld xwa, 1:i3
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 36)
	jrl lt, PaletteReduce_HighColorReduce

ImageDecode_CopyPaletteToDAC:
	ld xde, 0x696fc
	ld xbc, 0x6977c
	ld xwa, 0:i3
	ld (xsp + 4), xwa

ImageDecode_PaletteCopyLoop:
	ld xwa, (xde)
	ld (xbc), xwa
	dec 4, xde
	dec 4, xbc
	ld xwa, 1:i3
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp xwa, 0xc0
	jr lt, ImageDecode_PaletteCopyLoop
	ld xhl, OFFSCREEN_BUFFER_2
	ld ix, 0:i3

ImageDecode_ProcessRowsOuter:
	ld iy, 0:i3
	ld xbc, xhl

ImageDecode_ProcessPixels:
	ld e, (xbc)
	extz de
	ld xwa, (xsp + 32)
	ld	a, (xwa+de)
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
	lda xsp, (xsp+1068)
	ret

Flash_SaveSplashScreen:
	ld wa, 1:i3
	ld xbc, OFFSCREEN_BUFFER_2
	ld xde, 0x3c0000
	call Flash_EraseSectorAndWrite
	ld xwa, 0x3d0000
	push xwa
	ld wa, 1:i3
	ld xbc, 0x66800
	ldw de, 0x3000
	call FlashWrite
	ret

CaptureLcd:
	lda xsp, (xsp-1094)
	pushw iz
	lda xwa, (xsp+1082)
	pushw CaptureLcd_Str_BM@hi16
	pushw CaptureLcd_Str_BM@lo16
	push xwa
	call Strcpy
	lda xbc, (xsp+1090)
	ld xwa, 0x13036
	ld (xbc + 2), xwa
	ldw (xbc + 6), 0x0
	ldw (xbc + 8), 0x0
	ld xwa, 0x436
	ld (xbc + 10), xwa
	lda xbc, (xsp+1050)
	ld xwa, 0x28
	ld (xbc), xwa
	ld xwa, 0x140
	ld (xbc + 4), xwa
	ld xwa, 0xf0
	ld (xbc + 8), xwa
	ldw (xbc + 12), 0x1
	ldw (xbc + 14), 0x8
	ld xwa, 0:i3
	ld (xbc + 16), xwa
	ld xwa, 0x12c00
	ld (xbc + 20), xwa
	ld xwa, 0:i3
	ld (xbc + 24), xwa
	ld (xbc + 28), xwa
	ld xwa, 0x100
	ld (xbc + 32), xwa
	ld (xbc + 36), xwa
	ld xwa, (0x03044a:24)
	push xwa
	pushw CaptureLcd_Str_HKLCD_Fmt3d_BMP@hi16
	pushw CaptureLcd_Str_HKLCD_Fmt3d_BMP@lo16
	lda xwa, (xsp + 18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 20)
	ld xwa, 1:i3
	add (0x03044a:24), xwa
	call GetDiskSizeInfo
	call GetEncodedFileSizeData
	lda xwa, (xsp + 2)
	ld xbc, CaptureLcd_Str_wb
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl nz, CaptureLcd_WriteFailed
	lda xwa, (xsp+1082)
	ld xbc, 0xe
	call FileIO_WriteByte_Impl
	cp xhl, 0xe
	jrl nz, FileIO_ClosePath
	lda xwa, (xsp+1042)
	ld xbc, 0x28
	call FileIO_WriteByte_Impl
	cp xhl, 0x28
	jrl nz, FileIO_ClosePath
	ld iz, 0:i3
	ld xwa, (PALETTE_DATA_PTR_CACHED:24)
	or xwa, xwa
	jr z, CaptureLcd_WritePaletteNoOr94

CaptureLcd_WritePaletteOr94:
	ld wa, iz
	call Table_LookupDword
	ld de, iz
	sla de, 2
	lda xwa, (xsp + 18)
	ld xbc, xhl
	and xbc, MASK_BITS16_23	; is this a mask for Red?
	srl xbc, 16
	ld	(xwa+de), c
	ld bc, iz
	sla bc, 2
	lda	xwa, (xwa+bc)
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
	and xbc, MASK_BITS16_23	; is this a mask for Red?
	srl xbc, 16
	ld	(xwa+de), c
	ld bc, iz
	sla bc, 2
	lda	xwa, (xwa+bc)
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
	lda xwa, (OFFSCREEN_BUFFER_1:24)
	add xwa, xbc
	ld xbc, 0x140
	call FileIO_WriteByte_Impl
	cp xhl, 0x140
	jr z, CaptureLcd_NextRow

FileIO_ClosePath:
	call FileIO_CloseHandle

CaptureLcd_WriteFailed:
	ld hl, 0:i3
	jr CaptureLcd_Epilogue

CaptureLcd_NextRow:
	sub iz, 0x1
	jr ge, CaptureLcd_WriteRowLoop
	call FileIO_CloseHandle
	ld hl, 1:i3

CaptureLcd_Epilogue:
	popw iz
	lda xsp, (xsp+1094)
	ret

ChangeWall:
	pushw iz
	ld iz, wa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, ChangeWall_QueuedPath
	ld wa, iz
	calr ChangeWall_Impl
	jr ChangeWall_Epilogue

ChangeWall_QueuedPath:
	ld wa, 6:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (ChangeWall_QueueCallback:24)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DrawRing_Post

ChangeWall_Epilogue:
	popw iz
	ret

ChangeWall_QueueCallback:
	ld	wa, (xwa+4)
	jr	ChangeWall_Impl

ChangeWall_Impl:
	ld (0x03ef9c:24), wa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, ChangeWall_Impl_Data
	add xwa, xbc
	ld xwa, (xwa)
	ld (0x03ef98:24), xwa
	ld (0x030452:24), xwa
	ret

ChangeWallPalette:
	pushw iz
	ld iz, wa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, ChangeWallPalette_QueuedPath
	ld wa, iz
	calr ChangeWallPalette_Impl
	jr ChangeWallPalette_Epilogue

ChangeWallPalette_QueuedPath:
	ld wa, 6:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (ChangeWallPalette_QueueCallback:24)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DrawRing_Post

ChangeWallPalette_Epilogue:
	popw iz
	ret

ChangeWallPalette_QueueCallback:
	ld	wa, (xwa+4)
	jr	ChangeWallPalette_Impl

ChangeWallPalette_Impl:
	push xiz
	ld iz, wa
	ld wa, (0x03ef9c:24)
	cp wa, 2:i3
	jr z, WallPalette_Done
	cp wa, 0:i3
	jr nz, WallPalette_SetupLoop
	inc 1, iz

WallPalette_SetupLoop:
	ldi_erpw 0xfa, 0xe0, 0x00

WallPalette_IterateEntries:
	ldto_werp BC, 0xfa
	sub bc, 0xe0
	ld wa, iz
	call GetWallPaletteRGB
	ld xbc, xhl
	ldto_werp WA, 0xfa
	call SetPaletteRGB
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0xf0, 0x00
	jr c, WallPalette_IterateEntries
	ldw (0x030462:24), 0x0001

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
	cp hl, 0:i3
	jr z, ChangePalette_QueuedPath
	ld wa, iz
	calr ChangePalette_Impl
	jr ChangePalette_Epilogue

ChangePalette_QueuedPath:
	ld wa, 6:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (ChangePalette_QueueCallback:24)
	ld (xwa), xbc
	ld (xwa + 4), iz
	calr DrawRing_Post

ChangePalette_Epilogue:
	popw iz
	ret

ChangePalette_QueueCallback:
	ld	wa, (xwa+4)
	jr	ChangePalette_Impl

ChangePalette_Impl:
	push xiz
	ld iz, wa
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	lda xwa, (ChangePalette_Impl_Data:24)
	add xwa, xbc
	ld xwa, (xwa)
	ld (PALETTE_DATA_PTR_CACHED:24), xwa
	ldi_erpw 0xfa, 0x20, 0x00

UIRender_IterateCallbacks:
	ldto_werp WA, 0xfa
	ldto_werp BC, 0xfa
	extz xbc
	sll xbc, 2
	add xbc, (PALETTE_DATA_PTR_CACHED:24)
	ld xbc, (xbc)
	call SetPaletteRGB
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0xe0, 0x00
	jr c, UIRender_IterateCallbacks
	ld (PALETTE_INDEX_CACHED:24), iz
	ldw (PALETTE_UPDATE_FLAG:24), 0x0001
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
	cp hl, 0:i3
	jr nz, PaletteBankRotate_Impl
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (PaletteBankRotate_Code:24)
	ld (xwa), xbc
	jrl DrawRing_Post
PaletteBankRotate_Code:
	jr PaletteBankRotate_Impl

PaletteBankRotate_Impl:
	push xiz
	lda xwa, (OFFSCREEN_BUFFER_1:24)
	ld xiz, xwa
	pushw 0x9600
	push xwa
	ld xwa, OFFSCREEN_BUFFER_2
	push xwa
	call Mem_Copy
	add xiz, 0x9600
	pushw 0x9600
	push xiz
	ld xwa, OFFSCREEN_BUFFER_3
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	lda xwa, (OFFSCREEN_BUFFER_1:24)
	ld xbc, xwa
	ld de, 0:i3

PaletteBankRotate_RowLoop:
	ld hl, 0:i3

PaletteBankRotate_ColLoop:
	cp (xbc), 0xe0
	jr c, PaletteBankRotate_LowBank
	submi8 (xbc), 0x90
	jr PaletteBankRotate_NextCol

PaletteBankRotate_LowBank:
	addmi8 (xbc), 0x10

PaletteBankRotate_NextCol:
	inc 1, xbc
	inc 1, hl
	cp hl, 0x140
	jr lt, PaletteBankRotate_ColLoop
	inc 1, de
	cp de, 0xf0
	jr lt, PaletteBankRotate_RowLoop
	ld xiz, xwa
	pushw 0x9600
	push xwa
	ld xwa, 0x69800
	push xwa
	call Mem_Copy
	add xiz, 0x9600
	pushw 0x9600
	push xiz
	ld xwa, 0x72e00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	pop xiz
	ret

ClipBlit_Replace:
	; --- VRAM display rendering function pair 1: wrapper (FAF3E0-FAF41D) ---
	dec	2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, ClipBlit_Replace_Deferred
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ClipBlit_Replace_Impl
	jr t, ClipBlit_Replace_Return
ClipBlit_Replace_Deferred:
	ldw wa, 0x000a
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda	xbc, (ClipBlit_Replace_ParamBlock:24)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld bc, (xsp + 4)
	ld (xwa + 8), bc
	calr DrawRing_Post
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
	ld	iz, 0:i3
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
	lda_rrq xhl, xbc, qiz
	lda	xwa, (OFFSCREEN_BUFFER_1:24)
	add xwa, xhl
	ld (xsp + 16), xwa
	ld xwa, OFFSCREEN_BUFFER_2
	ld (xsp + 12), xwa
	ld wa, qiz
	exts xwa
	add xbc, xwa
	add (xsp + 12), xbc
	ld (xsp + 8), xde
	jr t, ClipBlit_Replace_ScanlineCond
ClipBlit_Replace_ScanlineLoop:
	ld xwa, (xsp + 28)
	ld wa, (xwa + 2)
	exts xwa
	ld xbc, (xsp + 8)
	sub xbc, xwa
	pushw bc
	call Math_AbsInt16
	add hl, hl
	lda	xwa, (ClipBlit_Replace_ScanlineLoop_Data:24)
	ld	de, (xwa+hl)
	ldw bc, 0x001e
	sub bc, de
	ld xwa, (xsp + 18)
	lda	xhl, (xwa+bc)
	ld xwa, (xsp + 14)
	exts xbc
	add xbc, xwa
	add de, de
	pushw de
	push xbc
	push xhl
	call Mem_Copy
	lda	xsp, (xsp+12)
	ld xwa, 0x00000140
	add (xsp + 12), xwa
	add (xsp + 16), xwa
	ld	xwa, 1:i3
	add (xsp + 8), xwa
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
	calr	SetChangeRect
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
	cp hl, 0:i3
	jr z, ClipBlit_Direct_Deferred
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ClipBlit_Direct_Impl
	jr t, ClipBlit_Direct_Return
ClipBlit_Direct_Deferred:
	ldw wa, 0x000a
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda	xbc, (ClipBlit_Direct_ParamBlock:24)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ldiw
	ldiw
	ld bc, (xsp + 4)
	ld (xwa + 8), bc
	calr DrawRing_Post
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
	ld	iz, 0:i3
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
	lda	xhl, (xbc+wa)
	lda	xwa, (OFFSCREEN_BUFFER_1:24)
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
	ld wa, (xsp + 4)
	pushw wa
	ld xwa, (xsp + 14)
	push xwa
	ld xwa, (xsp + 22)
	push xwa
	call Mem_Copy
	lda	xsp, (xsp+10)
	ld xwa, 0x00000140
	add (xsp + 12), xwa
	add (xsp + 16), xwa
	ld	xwa, 1:i3
	add (xsp + 8), xwa
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
	calr	SetChangeRect
	popw iz
	lda	xsp, (xsp+26)
	ret


ColorBlit:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xiz, xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr z, ColorBlit_Deferred
	ld a, (COLORBLIT_MODE:24)
	ld (COLORBLIT_MODE_ACTIVE:24), a
	cpw (0x03044e:24), 0
	jr z, ColorBlit_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit_Impl
	jr ColorBlit_Return

ColorBlit_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (ColorBlit_CallbackBlock:24)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ld bc, 4:i3
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld c, (COLORBLIT_MODE:24)
	ld (xwa + 14), c
	calr DrawRing_Post

ColorBlit_Return:
	pop xiz
	inc 2, xsp
	ret

ColorBlit_CallbackBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(0x03044e:24), 0
	ret	z
	ld	bc, de
	calr	ColorBlit_Impl
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
	ld e, (COLORBLIT_MODE_ACTIVE:24)
	cp e, 2:i3
	jrl z, ColorBlit_Mode2_Entry
	cp e, 1:i3
	jrl z, ColorBlit_Mode1_Entry
	cp e, 0:i3
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
	lda xiz, (OFFSCREEN_BUFFER_1:24)
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
	lda xiy, (OFFSCREEN_BUFFER_1:24)
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	add xiz, (0x030452:24)
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
	lda xde, (OFFSCREEN_BUFFER_1:24)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_Mode1_NextRow

ColorBlit_Mode1_PixelLoop:
	bit	7, (xde)
	jr z, ColorBlit_Mode1_SetBit5
	res	5, (xde)
	jr ColorBlit_Mode1_NextPixel

ColorBlit_Mode1_SetBit5:
	set	5, (xde)

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
	lda xde, (OFFSCREEN_BUFFER_1:24)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_Mode2_NextRow

ColorBlit_Mode2_PixelLoop:
	bit	7, (xde)
	jr z, ColorBlit_Mode2_SetBit6
	res	6, (xde)
	jr ColorBlit_Mode2_NextPixel

ColorBlit_Mode2_SetBit6:
	set	6, (xde)

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
	cp hl, 0:i3
	jr z, ColorBlit2_Deferred
	ld a, (COLORBLIT_MODE:24)
	ld (COLORBLIT_MODE_ACTIVE:24), a
	cpw (0x03044e:24), 0
	jr z, ColorBlit2_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit2_Impl
	jr ColorBlit2_Return

ColorBlit2_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (ColorBlit2_CallbackBlock:24)
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	ld bc, 4:i3
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld c, (COLORBLIT_MODE:24)
	ld (xwa + 14), c
	calr DrawRing_Post

ColorBlit2_Return:
	pop xiz
	inc 2, xsp
	ret

ColorBlit2_CallbackBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(0x03044e:24), 0
	ret	z
	ld	bc, de
	calr	ColorBlit2_Impl
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
	ld e, (COLORBLIT_MODE_ACTIVE:24)
	cp e, 2:i3
	jrl z, ColorBlit2_Mode2_Entry
	cp e, 1:i3
	jrl z, ColorBlit2_Mode1_Entry
	cp e, 0:i3
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
	lda xiz, (OFFSCREEN_BUFFER_1:24)
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
	lda xiy, (OFFSCREEN_BUFFER_1:24)
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	add xiz, (0x030452:24)
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
	lda xiy, (OFFSCREEN_BUFFER_1:24)
	add xiy, xde
	ld bc, (xwa)
	lda	xiy, (xiy+bc)
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_Mode1_NextRow

ColorBlit2_Mode1_PixelLoop:
	bit	7, (xiy)
	jr z, ColorBlit2_Mode1_ResBit5
	set	5, (xiy)
	jr ColorBlit2_Mode1_NextPixel

ColorBlit2_Mode1_ResBit5:
	res	5, (xiy)

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
	lda xbc, (OFFSCREEN_BUFFER_1:24)
	ld xde, 0:i3

ColorBlit2_Mode2_FullscreenLoop:
	bit	7, (xbc)
	jr z, ColorBlit2_Mode2_FullscreenRes6
	set	6, (xbc)
	jr ColorBlit2_Mode2_FullscreenNext

ColorBlit2_Mode2_FullscreenRes6:
	res	6, (xbc)

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
	lda xde, (OFFSCREEN_BUFFER_1:24)
	add xde, xbc
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_Mode2_NextRow

ColorBlit2_Mode2_PixelLoop:
	bit	7, (xde)
	jr z, ColorBlit2_Mode2_ResBit6
	set	6, (xde)
	jr ColorBlit2_Mode2_NextPixel

ColorBlit2_Mode2_ResBit6:
	res	6, (xde)

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


; =============================================================================
; DrawMonoBitmap - draw a 1-bpp bitmap into OFFSCREEN_BUFFER_1 in fg/bg colours
;
; Input:
;   XWA = pointer to a rectangle: word[0]=x0, word[2]=y0, word[4]=x1, word[6]=y1
;   XBC = pointer to the bitmap: one byte per (8-pixel column group, row),
;         MSB = leftmost pixel; for each group x = 0, 8, 16 .. < x1-x0 the
;         rows y = 0 .. < y1-y0 are consumed in order (column-major strips)
;   DE  = foreground colour (used where a bit is 1)
; The background colour (bit 0) is the word at 0x03efa2 (stored by
; DirmdEmulator_Dispatch_Code_Helper in display/graphics_text_vga.s).
; Colour 0xf5 means "copy the pixel from the buffer whose address is at
; 0x030452" instead of writing a fixed colour (the same convention as DrawLine).
;
; Same draw-task idiom as DrawLine / DrawBox (ui/drawing_primitives.s): the
; draw mode byte at 0x03efa8 is latched into 0x03efaa; if the caller is not the
; draw task (IS_XSP_INSIDE_4K_REGION_AT_1C032 returns 0) the call is queued as a
; 20-byte DrawQueue_Alloc record {+0 DrawMonoBitmap_ParamBlock, +4 rect (4
; words), +12 bitmap pointer, +16 colour, +18 draw mode} and posted to the draw
; task's ring (RAM 0x03247C) by DrawRing_Post, which retries while the ring is
; full; the draw task later runs it through DrawTask_FuncDispatch (`ld xhl,(xiz);
; ld xwa,xiz; call (xhl)`).  Nothing is drawn while the word at 0x03044e is 0.
;
; DrawMonoBitmap_Impl dispatches on the latched draw mode (0x03efaa):
;   0  pixel = (pixel & 0x60) | (colour & 0x9f)   -- bits 5-6 of the buffer
;      pixel are preserved, the rest is the colour
;   1  bit 5 of the pixel := its bit 7 XOR the bitmap bit   (_Impl_Mode1)
;   2  bit 6 likewise                                       (_Impl_Mode2)
;   other  nothing is drawn
; and always finishes with SetChangeRect(rect).
; Derived from the ROM code below (v10 0xFAFB48); caller:
; display/graphics_text_vga.s (the character-cell renderer that divides a cell
; index by 40 and multiplies by 8 to build the rectangle).
; =============================================================================
; ColorBlit2_LargeCodeBlock: previous name of this label, kept only because it is still referenced by display/graphics_text_vga.s and shared/positional_labels.s (owned by another lane)
ColorBlit2_LargeCodeBlock:
DrawMonoBitmap:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, DrawMonoBitmap_DeferredPath
	ld	a, (COLORBLIT_MODE:24)
	ld	(COLORBLIT_MODE_ACTIVE:24), a
	cpw	(0x03044e:24), 0
	jr	z, DrawMonoBitmap_Return
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	DrawMonoBitmap_Impl
	jr	DrawMonoBitmap_Return
DrawMonoBitmap_DeferredPath:
	ldw	wa, 20
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (DrawMonoBitmap_ParamBlock:24)
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	ld	bc, 4:i3
	ldirw
	ld	xbc, (xsp+6)
	ld	(xwa+12), xbc
	ld	bc, (xsp+4)
	ld	(xwa+16), bc
	ld	c, (COLORBLIT_MODE:24)
	ld	(xwa+18), c
	calr	DrawRing_Post
DrawMonoBitmap_Return:
	pop	xiz
	inc	6, xsp
	ret
DrawMonoBitmap_ParamBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	xhl, (xbc+12)
	ld	de, (xbc+16)
	ld	c, (xbc+18)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(0x03044e:24), 0
	ret	z
	ld	xbc, xhl
	calr	DrawMonoBitmap_Impl
	ret
DrawMonoBitmap_Impl:
	lda	xsp, (xsp-30)
	pushw	iz
	ld	(xsp+22), de
	ld	(xsp+24), xbc
	ld	(xsp+28), xwa
	ld	a, (COLORBLIT_MODE_ACTIVE:24)
	cp	a, 2:i3
	jrl	z, DrawMonoBitmap_Impl_Mode2
	cp	a, 1:i3
	jrl	z, DrawMonoBitmap_Impl_Mode1
	cp	a, 0:i3
	jrl	nz, DrawMonoBitmap_Impl_Done
	ldw	(xsp+6), 0
	jrl	DrawMonoBitmap_Impl_Join3
DrawMonoBitmap_Impl_Loop:
	ldw	(xsp+8), 0
	jrl	DrawMonoBitmap_Impl_Join2
DrawMonoBitmap_Impl_Loop2:
	lda	xwa, (xsp+18)
	ld	(xsp+10), xwa
	ld	xwa, (xsp+28)
	ld	bc, (xwa)
	add	bc, (xsp+6)
	ld	xwa, (xsp+10)
	ld	(xwa+), bc
	ld	(xsp+14), xwa
	ld	bc, (xde)
	add	bc, (xsp+8)
	ld	xwa, (xsp+14)
	ld	(xwa), bc
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
DrawMonoBitmap_Impl_Loop3:
	ld	xhl, (0x030452:24)
	ld	xwa, (xsp+14)
	ld	wa, (xwa)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	bit	7, (xsp+2)
	jr	z, DrawMonoBitmap_Impl_Skip3
	ld	xiy, (xsp+10)
	ld	iz, (xsp+22)
	ld	xwa, (xsp+10)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	ld	xix, xbc
	add	xix, xwa
	cp	iz, 245
	jr	z, DrawMonoBitmap_Impl_Skip
	and	(xix), 0x60
	ld	wa, iz
	and	wa, 0x9f
	add	(xix), a
	ld	bc, iz
	and	bc, 0x80
	ld	a, (xix)
	and	a, 0x80
	extz	wa
	cp	wa, bc
	jr	nz, DrawMonoBitmap_Impl_Skip2
	jrl	DrawMonoBitmap_Impl_Join
DrawMonoBitmap_Impl_Skip:
	ld	bc, (xiy)
	exts	xbc
	ld	wa, (xiy+2)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	add	xde, xbc
	add	xhl, xde
	and	(xix), 0x60
	ld	a, (xhl)
	and	a, 0x9f
	add	(xix), a
	ld	c, (xhl)
	and	c, 0x80
	ld	a, (xix)
	and	a, 0x80
	cp	a, c
	jr	z, DrawMonoBitmap_Impl_Join
DrawMonoBitmap_Impl_Skip2:
	xor	(xix), 0x60
	jr	DrawMonoBitmap_Impl_Join
DrawMonoBitmap_Impl_Skip3:
	ld	xiy, (xsp+10)
	ld	iz, (0x03efa2:24)
	ld	xwa, (xsp+10)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	ld	xix, xbc
	add	xix, xwa
	cp	iz, 245
	jr	z, DrawMonoBitmap_Impl_Skip4
	and	(xix), 0x60
	ld	wa, iz
	and	wa, 0x9f
	add	(xix), a
	ld	bc, iz
	and	bc, 0x80
	ld	a, (xix)
	and	a, 0x80
	extz	wa
	cp	wa, bc
	jr	nz, DrawMonoBitmap_Impl_Skip5
	jr	DrawMonoBitmap_Impl_Join
DrawMonoBitmap_Impl_Skip4:
	ld	bc, (xiy)
	exts	xbc
	ld	wa, (xiy+2)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	add	xde, xbc
	add	xhl, xde
	and	(xix), 0x60
	ld	a, (xhl)
	and	a, 0x9f
	add	(xix), a
	ld	c, (xhl)
	and	c, 0x80
	ld	a, (xix)
	and	a, 0x80
	cp	a, c
	jr	z, DrawMonoBitmap_Impl_Join
DrawMonoBitmap_Impl_Skip5:
	xor	(xix), 0x60
DrawMonoBitmap_Impl_Join:
	ld	a, (xsp+2)
	add	(xsp+2), a
	ld	xwa, (xsp+10)
	incw	1, (xwa)
	inc	1, (xsp+4)
	cp	(xsp+4), 8
	jrl	c, DrawMonoBitmap_Impl_Loop3
	ld	xwa, 1:i3
	add	(xsp+24), xwa
	incw	1, (xsp+8)
DrawMonoBitmap_Impl_Join2:
	ld	xwa, (xsp+28)
	lda	xde, (xwa+2)
	ld	bc, (xde)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, DrawMonoBitmap_Impl_Loop2
	incw	8, (xsp+6)
DrawMonoBitmap_Impl_Join3:
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	sub	bc, (xwa)
	cp	(xsp+6), bc
	jrl	c, DrawMonoBitmap_Impl_Loop
	jrl	DrawMonoBitmap_Impl_Done
DrawMonoBitmap_Impl_Mode1:
	ldw	(xsp+6), 0
	jrl	DrawMonoBitmap_Impl_Join7
DrawMonoBitmap_Impl_Loop4:
	ldw	(xsp+8), 0
	jr	DrawMonoBitmap_Impl_Join6
DrawMonoBitmap_Impl_Loop5:
	lda	xde, (xsp+18)
	ld	xwa, (xsp+28)
	ld	wa, (xwa)
	add	wa, (xsp+6)
	ld	(xde), wa
	lda	xhl, (xde+2)
	ld	wa, (xix)
	add	wa, (xsp+8)
	ld	(xhl), wa
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
DrawMonoBitmap_Impl_Loop6:
	lda	xix, (OFFSCREEN_BUFFER_1:24)
	ld	wa, (xhl)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	bit	7, (xsp+2)
	jr	z, DrawMonoBitmap_Impl_Skip6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	ld	xbc, xix
	add	xbc, xwa
	bit	7, (xbc)
	jr	nz, DrawMonoBitmap_Impl_Skip7
	jr	DrawMonoBitmap_Impl_Join4
DrawMonoBitmap_Impl_Skip6:
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	ld	xbc, xix
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawMonoBitmap_Impl_Skip7
DrawMonoBitmap_Impl_Join4:
	set	5, (xbc)
	jr	DrawMonoBitmap_Impl_Join5
DrawMonoBitmap_Impl_Skip7:
	res	5, (xbc)
DrawMonoBitmap_Impl_Join5:
	ld	a, (xsp+2)
	add	(xsp+2), a
	incw	1, (xde)
	inc	1, (xsp+4)
	cp	(xsp+4), 8
	jr	c, DrawMonoBitmap_Impl_Loop6
	ld	xwa, 1:i3
	add	(xsp+24), xwa
	incw	1, (xsp+8)
DrawMonoBitmap_Impl_Join6:
	ld	xwa, (xsp+28)
	lda	xix, (xwa+2)
	ld	bc, (xix)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, DrawMonoBitmap_Impl_Loop5
	incw	8, (xsp+6)
DrawMonoBitmap_Impl_Join7:
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	sub	bc, (xwa)
	cp	(xsp+6), bc
	jrl	c, DrawMonoBitmap_Impl_Loop4
	jrl	DrawMonoBitmap_Impl_Done
DrawMonoBitmap_Impl_Mode2:
	ldw	(xsp+6), 0
	jrl	DrawMonoBitmap_Impl_Join11
DrawMonoBitmap_Impl_Loop7:
	ldw	(xsp+8), 0
	jr	DrawMonoBitmap_Impl_Join10
DrawMonoBitmap_Impl_Loop8:
	lda	xde, (xsp+18)
	ld	xwa, (xsp+28)
	ld	wa, (xwa)
	add	wa, (xsp+6)
	ld	(xde), wa
	lda	xhl, (xde+2)
	ld	wa, (xix)
	add	wa, (xsp+8)
	ld	(xhl), wa
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
DrawMonoBitmap_Impl_Loop9:
	ld	wa, (xhl)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	bit	7, (xsp+2)
	jr	z, DrawMonoBitmap_Impl_Skip8
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	nz, DrawMonoBitmap_Impl_Skip9
	jr	DrawMonoBitmap_Impl_Join8
DrawMonoBitmap_Impl_Skip8:
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawMonoBitmap_Impl_Skip9
DrawMonoBitmap_Impl_Join8:
	set	6, (xbc)
	jr	DrawMonoBitmap_Impl_Join9
DrawMonoBitmap_Impl_Skip9:
	res	6, (xbc)
DrawMonoBitmap_Impl_Join9:
	ld	a, (xsp+2)
	add	(xsp+2), a
	incw	1, (xde)
	inc	1, (xsp+4)
	cp	(xsp+4), 8
	jr	c, DrawMonoBitmap_Impl_Loop9
	ld	xwa, 1:i3
	add	(xsp+24), xwa
	incw	1, (xsp+8)
DrawMonoBitmap_Impl_Join10:
	ld	xwa, (xsp+28)
	lda	xix, (xwa+2)
	ld	bc, (xix)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, DrawMonoBitmap_Impl_Loop8
	incw	8, (xsp+6)
DrawMonoBitmap_Impl_Join11:
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	sub	bc, (xwa)
	cp	(xsp+6), bc
	jrl	c, DrawMonoBitmap_Impl_Loop7
DrawMonoBitmap_Impl_Done:
	ld	xwa, (xsp+28)
	calr	SetChangeRect
	popw	iz
	lda	xsp, (xsp+30)
	ret

; =============================================================================
; DrawLineWithMode - draw a line between two points, honouring the draw mode
;
; Input:
;   XWA = pointer to point A: word[0]=x, word[2]=y
;   XBC = pointer to point B: word[0]=x, word[2]=y
;   DE  = colour (0xf5 = copy the pixel from the buffer at (0x030452))
;
; Wrapper / deferred path as in DrawMonoBitmap, with a 16-byte queue record
; {+0 DrawLineWithMode_ParamBlock, +4 point A, +8 point B, +12 colour,
; +14 draw mode}.
;
; DrawLineWithMode_Impl returns at once unless IsPointOnScreen accepts both
; points and at least one delta is non-zero.  It walks the longer axis one
; pixel at a time and the other in 16.16 fixed point: the slope comes from
; Math_DivideSigned32 on the delta shifted left 16 (`sla 0` = 16), rounded by
; adding 0x8000.  Pixel writes follow the latched draw mode (0x03efaa): 0 writes
; the colour into bits 0-4,7 keeping bits 5-6 (as DrawMonoBitmap).  Mode 1
; (_Impl_Mode1) writes bit 5 from the pixel's bit 7: the axis-aligned paths
; (_Loop7/_Loop8) SET bit 5 when bit 7 is set (else clear it) and the general
; paths (_Loop9/_Loop10) CLEAR it when bit 7 is set (else set it) -- opposite
; polarity, as the ROM has it.  Mode 2 (_Impl_Mode2): all four paths clear bit 6
; when bit 7 is set and set it otherwise.  Other modes draw nothing.
; It ends with SetChangeRect over the rectangle spanned by the two points
; (_Impl_Done).  DrawLine's wrapper (ui/drawing_primitives.s) does not latch the
; draw mode byte; this one does.
; Derived from the ROM code below (v10 0xFAFECD).  Callers:
; display/graphics_text_vga.s (as DrawLineWithMode) and,
; directly into _Impl, the image's root .s (as
; DrawLineWithMode_Impl).
; =============================================================================
; DrawLineWithMode: previous name of this label, kept only because it is still referenced by display/graphics_text_vga.s (owned by another lane)
DrawLineWithMode:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, DrawLineWithMode_DeferredPath
	ld	a, (COLORBLIT_MODE:24)
	ld	(COLORBLIT_MODE_ACTIVE:24), a
	cpw	(0x03044e:24), 0
	jr	z, DrawLineWithMode_Return
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	DrawLineWithMode_Impl
	jr	DrawLineWithMode_Return
DrawLineWithMode_DeferredPath:
	ldw	wa, 16
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (DrawLineWithMode_ParamBlock:24)
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	ldiw
	ldiw
	ld	xbc, (xsp+6)
	ld	xiy, xbc
	lda	xix, (xwa+8)
	ldiw
	ldiw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld	c, (COLORBLIT_MODE:24)
	ld	(xwa+14), c
	calr	DrawRing_Post
DrawLineWithMode_Return:
	pop	xiz
	inc	6, xsp
	ret
DrawLineWithMode_ParamBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	lda	xhl, (xbc+8)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(0x03044e:24), 0
	ret	z
	ld	xbc, xhl
	calr	DrawLineWithMode_Impl
	ret
; DrawLineWithMode_Impl: previous name of this label, kept only because it is still referenced by kn5000_v10_program.s (owned by another lane)
DrawLineWithMode_Impl:
	lda	xsp, (xsp-72)
	push	xiz
	ld	(xsp+66), de
	ld	(xsp+68), xbc
	ld	(xsp+72), xwa
	ld	xwa, (xsp+72)
	calr	IsPointOnScreen
	cp	hl, 0:i3
	jrl	z, DrawLineWithMode_Impl_Epilogue
	ld	xwa, (xsp+68)
	calr	IsPointOnScreen
	cp	hl, 0:i3
	jrl	z, DrawLineWithMode_Impl_Epilogue
	ld	xde, 0xffffffff
	ld	xwa, (xsp+68)
	ld	bc, (xwa)
	ld	xwa, (xsp+72)
	cp	bc, (xwa)
	jr	le, DrawLineWithMode_Impl_Skip
	ld	xde, 1:i3
DrawLineWithMode_Impl_Skip:
	ld	(xsp+12), xde
	ld	xde, 0xffffffff
	ld	xwa, (xsp+68)
	inc	2, xwa
	ld	(xsp+22), xwa
	ld	xwa, (xsp+72)
	inc	2, xwa
	ld	(xsp+26), xwa
	ld	xwa, (xsp+22)
	ld	bc, (xwa)
	ld	xwa, (xsp+26)
	ld	hl, (xwa)
	cp	bc, hl
	jr	le, DrawLineWithMode_Impl_Skip2
	ld	xde, 1:i3
DrawLineWithMode_Impl_Skip2:
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, DrawLineWithMode_Impl_Skip3
	ld	xwa, (xsp+68)
	ld	de, (xwa)
	ld	xwa, (xsp+72)
	sub	de, (xwa)
	jr	DrawLineWithMode_Impl_Join
DrawLineWithMode_Impl_Skip3:
	ld	xwa, (xsp+72)
	ld	de, (xwa)
	ld	xwa, (xsp+68)
	sub	de, (xwa)
DrawLineWithMode_Impl_Join:
	exts	xde
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, DrawLineWithMode_Impl_Skip4
	sub	bc, hl
	ld	hl, bc
	jr	DrawLineWithMode_Impl_Join2
DrawLineWithMode_Impl_Skip4:
	sub	hl, bc
DrawLineWithMode_Impl_Join2:
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, DrawLineWithMode_Impl_Skip5
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, DrawLineWithMode_Impl_Epilogue
DrawLineWithMode_Impl_Skip5:
	ld	xwa, (xsp+72)
	ld	xiy, xwa
	lda	xix, (xsp+62)
	ldiw
	ldiw
	ld	a, (COLORBLIT_MODE_ACTIVE:24)
	ld	(xsp+20), a
	lda	xwa, (OFFSCREEN_BUFFER_1:24)
	ld	(xsp+38), xwa
	ld	(xsp+30), xwa
	ld	xwa, (xsp+8)
	sla	xwa, 16
	ld	xbc, (xsp+4)
	call	Math_DivideSigned32
	ld	(xsp+34), xhl
	lda	xwa, (xsp+62)
	ld	(xsp+42), xwa
	ld	xwa, (xsp+4)
	sla	xwa, 16
	ld	xbc, (xsp+8)
	call	Math_DivideSigned32
	ld	xix, (xsp+42)
	lda	xwa, (xix+2)
	ld	(xsp+46), xwa
	ld	wa, (xwa)
	exts	xwa
	sla	xwa, 16
	ld	(xsp+50), xwa
	ld	xwa, 32768
	add	(xsp+50), xwa
	cp	(xsp+20), 2
	jrl	z, DrawLineWithMode_Impl_Mode2
	cp	(xsp+20), 1
	jrl	z, DrawLineWithMode_Impl_Mode1
	cp	(xsp+20), 0
	jrl	nz, DrawLineWithMode_Impl_Done
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jrl	nz, DrawLineWithMode_Impl_Skip9
	ld	xde, (xsp+42)
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	wa, (xix)
	exts	xwa
	add	xwa, xbc
	ld	xhl, (xsp+30)
	add	xhl, xwa
	cpw	(xsp+66), 245
	jr	z, DrawLineWithMode_Impl_Skip7
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop:
	and	(xhl), 0x60
	ld	wa, (xsp+66)
	and	wa, 0x9f
	add	(xhl), a
	ld	de, (xsp+66)
	and	de, 0x80
	ld	a, (xhl)
	and	a, 0x80
	extz	wa
	cp	wa, de
	jr	z, DrawLineWithMode_Impl_Skip6
	xor	(xhl), 0x60
DrawLineWithMode_Impl_Skip6:
	ld	xwa, (xsp+16)
	sla	xwa, 2
	add	xwa, (xsp+16)
	sla	xwa, 6
	add	xhl, xwa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip7:
	ld	wa, (xde)
	exts	xwa
	ld	xix, xbc
	add	xix, xwa
	add	xix, (0x030452:24)
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop2:
	and	(xhl), 0x60
	ld	a, (xix)
	and	a, 0x9f
	add	(xhl), a
	ld	e, (xix)
	and	e, 0x80
	ld	a, (xhl)
	and	a, 0x80
	cp	a, e
	jr	z, DrawLineWithMode_Impl_Skip8
	xor	(xhl), 0x60
DrawLineWithMode_Impl_Skip8:
	ld	xwa, (xsp+16)
	sla	xwa, 2
	add	xwa, (xsp+16)
	sla	xwa, 6
	add	xhl, xwa
	add	xix, xwa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop2
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip9:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	nz, DrawLineWithMode_Impl_Skip13
	ld	xde, (xsp+42)
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xhl, (xsp+30)
	add	xhl, xwa
	cpw	(xsp+66), 245
	jr	z, DrawLineWithMode_Impl_Skip11
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop3:
	and	(xhl), 0x60
	ld	wa, (xsp+66)
	and	wa, 0x9f
	add	(xhl), a
	ld	de, (xsp+66)
	and	de, 0x80
	ld	a, (xhl)
	and	a, 0x80
	extz	wa
	cp	wa, de
	jr	z, DrawLineWithMode_Impl_Skip10
	xor	(xhl), 0x60
DrawLineWithMode_Impl_Skip10:
	add	xhl, (xsp+12)
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop3
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip11:
	ld	wa, (xde)
	exts	xwa
	ld	xix, xbc
	add	xix, xwa
	add	xix, (0x030452:24)
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop4:
	and	(xhl), 0x60
	ld	a, (xix)
	and	a, 0x9f
	add	(xhl), a
	ld	e, (xix)
	and	e, 0x80
	ld	a, (xhl)
	and	a, 0x80
	cp	a, e
	jr	z, DrawLineWithMode_Impl_Skip12
	xor	(xhl), 0x60
DrawLineWithMode_Impl_Skip12:
	add	xhl, (xsp+12)
	add	xix, (xsp+12)
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop4
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip13:
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jrl	le, DrawLineWithMode_Impl_Skip16
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	Math_MultiplyAccumulate
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 16
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop5:
	ld	xiy, xde
	ld	hl, (xsp+66)
	lda	xwa, (xde+2)
	ld	(xsp+50), xwa
	ld	wa, (xwa)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xix
	ld	xix, (xsp+38)
	add	xix, xwa
	cpw	(xsp+66), 245
	jr	z, DrawLineWithMode_Impl_Skip14
	and	(xix), 0x60
	ld	wa, hl
	and	wa, 0x9f
	add	(xix), a
	and	hl, 0x80
	ld	a, (xix)
	and	a, 0x80
	extz	wa
	cp	wa, hl
	jr	nz, DrawLineWithMode_Impl_Skip15
	jr	DrawLineWithMode_Impl_Join3
DrawLineWithMode_Impl_Skip14:
	ld	xiz, (0x030452:24)
	ld	hl, (xiy)
	exts	xhl
	ld	wa, (xiy+2)
	exts	xwa
	ld	xiy, xwa
	sll	xiy, 2
	add	xiy, xwa
	sll	xiy, 6
	add	xiy, xhl
	add	xiz, xiy
	and	(xix), 0x60
	ld	a, (xiz)
	and	a, 0x9f
	add	(xix), a
	ld	l, (xiz)
	and	l, 0x80
	ld	a, (xix)
	and	a, 0x80
	cp	a, l
	jr	z, DrawLineWithMode_Impl_Join3
DrawLineWithMode_Impl_Skip15:
	xor	(xix), 0x60
DrawLineWithMode_Impl_Join3:
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 16
	ld	(xde), wa
	ld	xhl, (xsp+16)
	ld	xwa, (xsp+50)
	add	(xwa), hl
	inc	1, xbc
	cp	xbc, (xsp+8)
	jrl	le, DrawLineWithMode_Impl_Loop5
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip16:
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xde, (xsp+42)
	ld	xwa, (xsp+46)
	ld	(xsp+46), xwa
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop6:
	ld	xix, xde
	ld	hl, (xsp+66)
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xiy, xwa
	sll	xiy, 2
	add	xiy, xwa
	sll	xiy, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xiy
	ld	xiy, (xsp+38)
	add	xiy, xwa
	cpw	(xsp+66), 245
	jr	z, DrawLineWithMode_Impl_Skip17
	and	(xiy), 0x60
	ld	wa, hl
	and	wa, 0x9f
	add	(xiy), a
	and	hl, 0x80
	ld	a, (xiy)
	and	a, 0x80
	extz	wa
	cp	wa, hl
	jr	nz, DrawLineWithMode_Impl_Skip18
	jr	DrawLineWithMode_Impl_Join4
DrawLineWithMode_Impl_Skip17:
	ld	xiz, (0x030452:24)
	ld	hl, (xix)
	exts	xhl
	ld	wa, (xix+2)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	add	xix, xhl
	add	xiz, xix
	and	(xiy), 0x60
	ld	a, (xiz)
	and	a, 0x9f
	add	(xiy), a
	ld	l, (xiz)
	and	l, 0x80
	ld	a, (xiy)
	and	a, 0x80
	cp	a, l
	jr	z, DrawLineWithMode_Impl_Join4
DrawLineWithMode_Impl_Skip18:
	xor	(xiy), 0x60
DrawLineWithMode_Impl_Join4:
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xhl, (xsp+8)
	sra	xhl, 16
	ld	xwa, (xsp+46)
	ld	(xwa), hl
	ld	xwa, (xsp+12)
	add	(xde), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jrl	le, DrawLineWithMode_Impl_Loop6
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Mode1:
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, DrawLineWithMode_Impl_Skip20
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop7:
	bit	7, (xde)
	jr	z, DrawLineWithMode_Impl_Skip19
	set	5, (xde)
	jr	DrawLineWithMode_Impl_Join5
DrawLineWithMode_Impl_Skip19:
	res	5, (xde)
DrawLineWithMode_Impl_Join5:
	ld	xwa, (xsp+16)
	sla	xwa, 2
	add	xwa, (xsp+16)
	sla	xwa, 6
	add	xde, xwa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop7
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip20:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, DrawLineWithMode_Impl_Skip22
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop8:
	bit	7, (xde)
	jr	z, DrawLineWithMode_Impl_Skip21
	set	5, (xde)
	jr	DrawLineWithMode_Impl_Join6
DrawLineWithMode_Impl_Skip21:
	res	5, (xde)
DrawLineWithMode_Impl_Join6:
	add	xde, (xsp+12)
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop8
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip22:
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Skip24
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	Math_MultiplyAccumulate
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 16
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop9:
	lda	xhl, (xde+2)
	ld	wa, (xhl)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xix
	ld	xix, (xsp+38)
	add	xix, xwa
	bit	7, (xix)
	jr	z, DrawLineWithMode_Impl_Skip23
	res	5, (xix)
	jr	DrawLineWithMode_Impl_Join7
DrawLineWithMode_Impl_Skip23:
	set	5, (xix)
DrawLineWithMode_Impl_Join7:
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 16
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xhl), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop9
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip24:
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xhl, (xsp+42)
	ld	xde, (xsp+46)
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop10:
	ld	wa, (xde)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xhl)
	exts	xwa
	add	xwa, xix
	ld	xix, (xsp+38)
	add	xix, xwa
	bit	7, (xix)
	jr	z, DrawLineWithMode_Impl_Skip25
	res	5, (xix)
	jr	DrawLineWithMode_Impl_Join8
DrawLineWithMode_Impl_Skip25:
	set	5, (xix)
DrawLineWithMode_Impl_Join8:
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 16
	ld	(xde), wa
	ld	xwa, (xsp+12)
	add	(xhl), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop10
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Mode2:
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, DrawLineWithMode_Impl_Skip27
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop11:
	bit	7, (xde)
	jr	z, DrawLineWithMode_Impl_Skip26
	res	6, (xde)
	jr	DrawLineWithMode_Impl_Join9
DrawLineWithMode_Impl_Skip26:
	set	6, (xde)
DrawLineWithMode_Impl_Join9:
	ld	xwa, (xsp+16)
	sla	xwa, 2
	add	xwa, (xsp+16)
	sla	xwa, 6
	add	xde, xwa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop11
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip27:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, DrawLineWithMode_Impl_Skip29
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop12:
	bit	7, (xde)
	jr	z, DrawLineWithMode_Impl_Skip28
	res	6, (xde)
	jr	DrawLineWithMode_Impl_Join10
DrawLineWithMode_Impl_Skip28:
	set	6, (xde)
DrawLineWithMode_Impl_Join10:
	add	xde, (xsp+12)
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop12
	jrl	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip29:
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Skip31
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	Math_MultiplyAccumulate
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 16
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop13:
	lda	xhl, (xde+2)
	ld	wa, (xhl)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xix
	ld	xix, (xsp+38)
	add	xix, xwa
	bit	7, (xix)
	jr	z, DrawLineWithMode_Impl_Skip30
	res	6, (xix)
	jr	DrawLineWithMode_Impl_Join11
DrawLineWithMode_Impl_Skip30:
	set	6, (xix)
DrawLineWithMode_Impl_Join11:
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 16
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xhl), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, DrawLineWithMode_Impl_Loop13
	jr	DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Skip31:
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xhl, (xsp+42)
	ld	xde, (xsp+46)
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	ld	xbc, 0:i3
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	lt, DrawLineWithMode_Impl_Done
DrawLineWithMode_Impl_Loop14:
	ld	wa, (xde)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xhl)
	exts	xwa
	add	xwa, xix
	ld	xix, (xsp+38)
	add	xix, xwa
	bit	7, (xix)
	jr	z, DrawLineWithMode_Impl_Skip32
	res	6, (xix)
	jr	DrawLineWithMode_Impl_Join12
DrawLineWithMode_Impl_Skip32:
	set	6, (xix)
DrawLineWithMode_Impl_Join12:
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 16
	ld	(xde), wa
	ld	xwa, (xsp+12)
	add	(xhl), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, DrawLineWithMode_Impl_Loop14
DrawLineWithMode_Impl_Done:
	lda	xwa, (xsp+54)
	ld	xbc, (xsp+26)
	ld	bc, (xbc)
	ld	(xwa+2), bc
	ld	xbc, (xsp+72)
	ld	bc, (xbc)
	ld	(xwa), bc
	ld	xbc, (xsp+68)
	ld	bc, (xbc)
	ld	(xwa+4), bc
	ld	xbc, (xsp+22)
	ld	bc, (xbc)
	ld	(xwa+6), bc
	calr	SetChangeRect
DrawLineWithMode_Impl_Epilogue:
	pop	xiz
	lda	xsp, (xsp+72)
	ret

; =============================================================================
; DrawDottedLineWithMode - DrawLineWithMode with a dotted pattern
;
; Same inputs, queue record layout (+0 DrawDottedLineWithMode_ParamBlock) and
; algorithm as DrawLineWithMode, plus a pattern counter at (xsp+0x18) of the
; _Impl frame: per pixel step, counter 0 and 1 draw and increment, 2 and 3 skip
; and increment, and at 4 the counter is reset to 0 WITHOUT drawing or
; incrementing -- two pixels on, three off.  The draw-mode test is made per
; pixel inside the loop.
; The routine continues past the end of this file into the image's root .s
; (kn5000_v10_program.s), which branches back into it.
; Derived from the ROM code below (v10 0xFB06B6).  Caller:
; display/graphics_text_vga.s (as DrawDottedLineWithMode).
; =============================================================================
; DrawDottedLineWithMode: previous name of this label, kept only because it is still referenced by display/graphics_text_vga.s (owned by another lane)
DrawDottedLineWithMode:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, DrawDottedLineWithMode_DeferredPath
	ld	a, (COLORBLIT_MODE:24)
	ld	(COLORBLIT_MODE_ACTIVE:24), a
	cpw	(0x03044e:24), 0
	jr	z, DrawDottedLineWithMode_Return
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	DrawDottedLineWithMode_Impl
	jr	DrawDottedLineWithMode_Return
DrawDottedLineWithMode_DeferredPath:
	ldw	wa, 16
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (DrawDottedLineWithMode_ParamBlock:24)
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	ldiw
	ldiw
	ld	xbc, (xsp+6)
	ld	xiy, xbc
	lda	xix, (xwa+8)
	ldiw
	ldiw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld	c, (COLORBLIT_MODE:24)
	ld	(xwa+14), c
	calr	DrawRing_Post
DrawDottedLineWithMode_Return:
	pop	xiz
	inc	6, xsp
	ret
DrawDottedLineWithMode_ParamBlock:
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	lda	xhl, (xbc+8)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	ld	(COLORBLIT_MODE_ACTIVE:24), c
	cpw	(0x03044e:24), 0
	ret	z
	ld	xbc, xhl
	calr	DrawDottedLineWithMode_Impl
	ret
DrawDottedLineWithMode_Impl:
	lda	xsp, (xsp-56)
	push	xiz
	ld	(xsp+50), de
	ld	(xsp+52), xbc
	ld	(xsp+56), xwa
	ld	(xsp+24), 0
	ld	xde, 0xffffffff
	ld	xwa, (xsp+52)
	ld	bc, (xwa)
	ld	xwa, (xsp+56)
	cp	bc, (xwa)
	jr	le, DrawDottedLineWithMode_Impl_Skip
	ld	xde, 1:i3
DrawDottedLineWithMode_Impl_Skip:
	ld	(xsp+12), xde
	ld	xde, 0xffffffff
	ld	xwa, (xsp+52)
	inc	2, xwa
	ld	(xsp+26), xwa
	ld	xwa, (xsp+56)
	inc	2, xwa
	ld	(xsp+30), xwa
	ld	xwa, (xsp+26)
	ld	bc, (xwa)
	ld	xwa, (xsp+30)
	ld	hl, (xwa)
	cp	bc, hl
	jr	le, DrawDottedLineWithMode_Impl_Skip2
	ld	xde, 1:i3
DrawDottedLineWithMode_Impl_Skip2:
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, DrawDottedLineWithMode_Impl_Skip3
	ld	xwa, (xsp+52)
	ld	de, (xwa)
	ld	xwa, (xsp+56)
	sub	de, (xwa)
	jr	DrawDottedLineWithMode_Impl_Join
DrawDottedLineWithMode_Impl_Skip3:
	ld	xwa, (xsp+56)
	ld	de, (xwa)
	ld	xwa, (xsp+52)
	sub	de, (xwa)
DrawDottedLineWithMode_Impl_Join:
	exts	xde
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, DrawDottedLineWithMode_Impl_Skip4
	sub	bc, hl
	ld	hl, bc
	jr	DrawDottedLineWithMode_Impl_Join2
DrawDottedLineWithMode_Impl_Skip4:
	sub	hl, bc
DrawDottedLineWithMode_Impl_Join2:
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, DrawDottedLineWithMode_Impl_Skip5
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, DrawDottedLineWithMode_Impl_Epilogue
DrawDottedLineWithMode_Impl_Skip5:
	ld	xwa, (xsp+56)
	ld	xiy, xwa
	lda	xix, (xsp+46)
	ldiw
	ldiw
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jrl	nz, DrawDottedLineWithMode_Impl_Skip13
	ld	xwa, 0:i3
	ld	(xsp+20), xwa
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawDottedLineWithMode_Impl_Join11
DrawDottedLineWithMode_Impl_Loop:
	cp	(xsp+24), 3
	jr	ule, DrawDottedLineWithMode_Impl_Skip6
	ld	(xsp+24), 0
	jrl	DrawDottedLineWithMode_Impl_Join4
DrawDottedLineWithMode_Impl_Skip6:
	cp	(xsp+24), 1
	jrl	ugt, DrawDottedLineWithMode_Impl_Join3
	ld	a, (COLORBLIT_MODE_ACTIVE:24)
	cp	a, 2:i3
	jrl	z, DrawDottedLineWithMode_Impl_Skip11
	cp	a, 1:i3
	jrl	z, DrawDottedLineWithMode_Impl_Skip9
	cp	a, 0:i3
	jrl	nz, DrawDottedLineWithMode_Impl_Join3
	lda	xwa, (xsp+46)
	ld	xiy, xwa
	ld	ix, (xsp+50)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xhl, (OFFSCREEN_BUFFER_1:24)
	add	xhl, xwa
	cpw	(xsp+50), 245
	jr	z, DrawDottedLineWithMode_Impl_Skip7
	and	(xhl), 0x60
	ld	wa, ix
	and	wa, 0x9f
	add	(xhl), a
	ld	bc, ix
	and	bc, 0x80
	ld	a, (xhl)
	and	a, 0x80
	extz	wa
	cp	wa, bc
	jr	nz, DrawDottedLineWithMode_Impl_Skip8
	jrl	DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip7:
	ld	xix, (0x030452:24)
	ld	bc, (xiy)
	exts	xbc
	ld	wa, (xiy+2)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	add	xde, xbc
	add	xix, xde
	and	(xhl), 0x60
	ld	a, (xix)
	and	a, 0x9f
	add	(xhl), a
	ld	c, (xix)
	and	c, 0x80
	ld	a, (xhl)
	and	a, 0x80
	cp	a, c
	jr	z, DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip8:
	xor	(xhl), 0x60
	jr	DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip9:
	lda	xwa, (xsp+46)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawDottedLineWithMode_Impl_Skip10
	res	5, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip10:
	set	5, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip11:
	lda	xwa, (xsp+46)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawDottedLineWithMode_Impl_Skip12
	res	6, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join3
DrawDottedLineWithMode_Impl_Skip12:
	set	6, (xbc)
DrawDottedLineWithMode_Impl_Join3:
	inc	1, (xsp+24)
DrawDottedLineWithMode_Impl_Join4:
	ld	xwa, (xsp+16)
	add	(xsp+48), wa
	ld	xwa, 1:i3
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+8)
	jrl	le, DrawDottedLineWithMode_Impl_Loop
	jrl	DrawDottedLineWithMode_Impl_Join11
DrawDottedLineWithMode_Impl_Skip13:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	nz, DrawDottedLineWithMode_Impl_Skip21
	ld	xwa, 0:i3
	ld	(xsp+20), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, DrawDottedLineWithMode_Impl_Join11
DrawDottedLineWithMode_Impl_Entry:
	cp	(xsp+24), 3
	jr	ule, DrawDottedLineWithMode_Impl_Skip14
	ld	(xsp+24), 0
	jrl	DrawDottedLineWithMode_Impl_Join6
DrawDottedLineWithMode_Impl_Skip14:
	cp	(xsp+24), 1
	jrl	ugt, DrawDottedLineWithMode_Impl_Join5
	ld	a, (COLORBLIT_MODE_ACTIVE:24)
	cp	a, 2:i3
	jrl	z, DrawDottedLineWithMode_Impl_Skip19
	cp	a, 1:i3
	jrl	z, DrawDottedLineWithMode_Impl_Skip17
	cp	a, 0:i3
	jrl	nz, DrawDottedLineWithMode_Impl_Join5
	lda	xwa, (xsp+46)
	ld	xiy, xwa
	ld	ix, (xsp+50)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xhl, (OFFSCREEN_BUFFER_1:24)
	add	xhl, xwa
	cpw	(xsp+50), 245
	jr	z, DrawDottedLineWithMode_Impl_Skip15
	and	(xhl), 0x60
	ld	wa, ix
	and	wa, 0x9f
	add	(xhl), a
	ld	bc, ix
	and	bc, 0x80
	ld	a, (xhl)
	and	a, 0x80
	extz	wa
	cp	wa, bc
	jr	nz, DrawDottedLineWithMode_Impl_Skip16
	jrl	DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip15:
	ld	xix, (0x030452:24)
	ld	bc, (xiy)
	exts	xbc
	ld	wa, (xiy+2)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	add	xde, xbc
	add	xix, xde
	and	(xhl), 0x60
	ld	a, (xix)
	and	a, 0x9f
	add	(xhl), a
	ld	c, (xix)
	and	c, 0x80
	ld	a, (xhl)
	and	a, 0x80
	cp	a, c
	jr	z, DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip16:
	xor	(xhl), 0x60
	jr	DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip17:
	lda	xwa, (xsp+46)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawDottedLineWithMode_Impl_Skip18
	res	5, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip18:
	set	5, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip19:
	lda	xwa, (xsp+46)
	ld	bc, (xwa+2)
	exts	xbc
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda	xbc, (OFFSCREEN_BUFFER_1:24)
	add	xbc, xwa
	bit	7, (xbc)
	jr	z, DrawDottedLineWithMode_Impl_Skip20
	res	6, (xbc)
	jr	DrawDottedLineWithMode_Impl_Join5
DrawDottedLineWithMode_Impl_Skip20:
	set	6, (xbc)
DrawDottedLineWithMode_Impl_Join5:
	inc	1, (xsp+24)
DrawDottedLineWithMode_Impl_Join6:
	ld	xwa, (xsp+12)
	add	(xsp+46), wa
	ld	xwa, 1:i3
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+4)
	jrl	le, DrawDottedLineWithMode_Impl_Entry
	jrl	DrawDottedLineWithMode_Impl_Join11
DrawDottedLineWithMode_Impl_Skip21:
	lda	xwa, (xsp+46)
	ld	(xsp+34), xwa
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jrl	le, DrawDottedLineWithMode_Impl_Skip29
	ld	xwa, (xsp+4)
	sla	xwa, 16
	ld	xbc, (xsp+8)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+12)
	ld	xbc, xiz
	call	Math_MultiplyAccumulate
	ld	(xsp+12), xhl
	ld	xbc, (xsp+34)
	ld	xwa, xbc
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 16
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	ld	xwa, 0:i3
	ld	(xsp+20), xwa
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, DrawDottedLineWithMode_Impl_Join11
; ColorBlit2_LargeCodeBlock_Entry2: previous name of this label, kept only because it is still referenced by kn5000_v10_program.s (owned by another lane)
ColorBlit2_LargeCodeBlock_Entry2:
	cp	(xsp+24), 3
	jr	ule, DrawDottedLineWithMode_Impl_Skip22
	ld	(xsp+24), 0
	jrl	DrawDottedLineWithMode_Impl_Join8
DrawDottedLineWithMode_Impl_Skip22:
	cp	(xsp+24), 1
	jrl	ugt, DrawDottedLineWithMode_Impl_Join7
	ld	a, (COLORBLIT_MODE_ACTIVE:24)
	ldfr_berp	a, 240	; ld ixl, a
	ld	wa, (xbc+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	lda	xde, (OFFSCREEN_BUFFER_1:24)
	cpib_erp	240, 2	; cp ixl, 2
	jrl	z, DrawDottedLineWithMode_Impl_Skip27
	cpib_erp	240, 1	; cp ixl, 1
	jr	z, DrawDottedLineWithMode_Impl_Skip25
	cpib_erp	240, 0	; cp ixl, 0
	jrl	nz, DrawDottedLineWithMode_Impl_Join7
	ld	xiz, xbc
	ld	iy, (xsp+50)
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xhl
	ld	xix, xde
	add	xix, xwa
	cpw	(xsp+50), 245
	jr	z, DrawDottedLineWithMode_Impl_Skip23
	and	(xix), 0x60
	ld	wa, iy
	and	wa, 0x9f
	add	(xix), a
	ld	de, iy
	and	de, 0x80
	ld	a, (xix)
	and	a, 0x80
	extz	wa
	cp	wa, de
	jr	nz, DrawDottedLineWithMode_Impl_Skip24
	jr	DrawDottedLineWithMode_Impl_Join7
DrawDottedLineWithMode_Impl_Skip23:
	ld	xiy, (0x030452:24)
	ld	de, (xiz)
	exts	xde
	ld	wa, (xiz+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	add	xhl, xde
	add	xiy, xhl
	and	(xix), 0x60
	ld	a, (xiy)
	and	a, 0x9f
	add	(xix), a
	ld	e, (xiy)
	and	e, 0x80
	ld	a, (xix)
	and	a, 0x80
	cp	a, e
	jr	z, DrawDottedLineWithMode_Impl_Join7
DrawDottedLineWithMode_Impl_Skip24:
	xor	(xix), 0x60
	jr	DrawDottedLineWithMode_Impl_Join7
DrawDottedLineWithMode_Impl_Skip25:
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xhl
	add	xde, xwa
	bit	7, (xde)
	jr	z, DrawDottedLineWithMode_Impl_Skip26
	res	5, (xde)
	jr	DrawDottedLineWithMode_Impl_Join7
DrawDottedLineWithMode_Impl_Skip26:
	set	5, (xde)
	jr	DrawDottedLineWithMode_Impl_Join7
DrawDottedLineWithMode_Impl_Skip27:
	ld	wa, (xbc)
