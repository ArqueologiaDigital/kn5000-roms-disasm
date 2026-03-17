; =============================================================================
; UI Window Procedures (8K lines)
; =============================================================================
;
; Window procedure handlers for all standard widget types:
; ModeEdit, TitleEdit, StringBox, Label, Bitmap, Icon, Line,
; Frame, EditSw, TextBox, VwBox, ListBox, RadioBox, TempoBox,
; GridBox. The core UI rendering and event dispatch layer.
; =============================================================================

	lda_24 xde, 0x0274b0
	ld32_24 xhl, 0x0274e4
	lds32 xbc, 0

WndScroll_CopyLoop:
	ld xwa, xbc
	ld xix, xde
	add xix, xwa
	ld a, (xhl)
	ld (xix), a
	inc 1, iz
	inc 1, xbc
	cpda16_24 xiz, 160982
	jr c, WndScroll_CopyLoop

WndScroll_InitBuffer:
	ld wa, iz
	extz xwa
	lda_24 xde, 0x0274b0
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	ld32_24 xwa, 0x0274d2
	ld xbc, 0x1E0003A
	call ApFuncCall

WndScroll_InitWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 50)
	ld xbc, 0x1C00017
	lds32 xde, 5
	calr SetDialUp
	ld xwa, (xsp + 50)
	ld xbc, 0x1C00018
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
	sti16_24 0x0274dc, 0xffff
	sti16_24 0x0274e0, 0xffff
	ld16_24 xde, 0x0274d8
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1E00080
	jrl WndScroll_SendAndReturn

WndScroll_BasicWindowProc:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleSelectionChange:
	st16_24 0x0274de, xde
	cpdm16_24 160992, xde
	jrl z, UIDialog_ReturnZeroJmp
	ld xwa, (xsp + 50)
	calr GetClientBox
	ld16_24 xwa, 0x0274da
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA9ED2
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ld16_24 xwa, 0x0274e0
	cp wa, 0xFFFF
	jr z, WndScroll_DrawCurrentItem
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ld16_24 xwa, 0x0274e0
	extz xwa
	div wa, 0xD
	mul wa, 0x18
	ld de, wa
	lda xbc, (xsp + 34)
	ld wa, (xbc + 2)
	add wa, 0xA
	add wa, de
	lda xde, (xsp + 26)
	ld (xde + 2), wa
	ld16_24 xwa, 0x0274e0
	extz xwa
	div wa, 0xD
	ldto_werp HL, 0xE2
	sll hl, 4
	ld wa, (xbc)
	add wa, 0xE
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
	ldw bc, 0xF5
	call DrawFrame

WndScroll_DrawCurrentItem:
	ld16_24 xwa, 0x0274de
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	lda xbc, (xsp + 12)
	ld xwa, (xwa)
	call ConvertStrings
	ld16_24 xwa, 0x0274de
	extz xwa
	div wa, 0xD
	mul wa, 0x18
	ld de, wa
	lda xbc, (xsp + 34)
	ld wa, (xbc + 2)
	add wa, 0xA
	add wa, de
	lda xde, (xsp + 26)
	ld (xde + 2), wa
	ld16_24 xwa, 0x0274de
	extz xwa
	div wa, 0xD
	ldto_werp HL, 0xE2
	sll hl, 4
	ld wa, (xbc)
	add wa, 0xE
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
	ldw bc, 0xF2
	call DrawFrame
	ld16_24 xwa, 0x0274de
	st16_24 0x0274e0, xwa
	jrl UIDialog_ReturnZeroJmp

WndScroll_RepaintAll:
	ld16_24 xwa, 0x0274dc
	cpda16_24 xwa, 160986
	jrl z, UIDialog_ReturnZeroJmp
	sti16_24 0x0274e0, 0xffff
	ld xwa, (xsp + 50)
	calr GetClientBox
	lda xwa, (xsp + 34)
	ldw bc, 0xF5
	call DrawBox
	ld16_24 xwa, 0x0274da
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA9ED2
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	lds iz, 0
	jr WndScroll_ItemCountCheck

WndScroll_DrawSingleItem:
	ld wa, iz
	extz xwa
	div wa, 0xD
	ldto_werp DE, 0xE2
	sll de, 4
	lda xwa, (xsp + 34)
	ld hl, (xwa)
	add hl, 0xE
	add hl, de
	lda xbc, (xsp + 22)
	ld (xbc), hl
	ld de, iz
	extz xde
	div de, 0xD
	mul de, 0x18
	ld hl, de
	ld de, (xwa + 2)
	add de, 0xA
	add de, hl
	ld (xbc + 2), de
	ld hl, iz
	extz xhl
	sll xhl, 2
	add xhl, (xsp + 4)
	lds32 xde, 0
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, (xhl)
	call DrawString
	inc 1, iz

WndScroll_ItemCountCheck:
	ld16_24 xbc, 0x0274e2
	mul bc, 0x3
	ld16_24 xwa, 0x0274da
	add bc, wa
	extz xbc
	add xbc, xbc
	ld xde, 0xEA9EDE
	add xde, xbc
	cp iz, (xde)
	jr ule, WndScroll_DrawSingleItem
	st16_24 0x0274dc, xwa
	jrl UIDialog_ReturnZeroJmp

WndEvt_DispatchByEventCode:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	ld32_24 xbc, 0x0274e4
	dec 1, xwa
	cp xwa, 0x0
	jrl c, UIDialog_ReturnZeroJmp
	cp xwa, 0x8
	jrl ugt, UIDialog_ReturnZeroJmp
	add xwa, xwa
	add xwa, 0xEA9EF6
	ld wa, (xwa)
	lda_24 xix, 0xf9b83f
	jp_dri 8, 0x07, 0xF0, 0xE0

; Window event dispatch by event code
WndEvt_EventCodeDispatch:
	ld16_24	wa, 160984
	cps	wa, 0
	jrl	z, 2252
	dec	1, wa
	st16_24	160984, wa
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	.byte 0xaf
	.ascii "*\"x6"
	pop_sr
	ld16_24	wa, 160984
	ld	bc, wa
	inc	1, bc
	.byte 0xd2, 0xd6
	jrl	ov, -3838
	jrl	nc, 2200
	inc	1, wa
	st16_24	160984, wa
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	770
	ld16_24	bc, 160990
	cps	bc, 0
	jrl	z, 2155
	ld16_24	wa, 160986
	extz	xwa
	sll	xwa, 2
	ld	xde, 15376082
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	dec	1, bc
	st16_24	160990, bc
	extz	xbc
	sll	xbc, 2
	ld	xwa, xbc
	.byte 0xaf, 0x04, 0x80
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	16459328
	ld16_24	wa, 160984
	extz	xwa
	lda_24	xde, 160944
	ld	xbc, xde
	add	xbc, xwa
	ld	a, (xsp+12)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, 29360143
	call	16422496
	ld16_24	de, 160990
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 29360142
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	646
	lda_24	xde, 15376082
	lda	xwa, (xsp+12)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+46)
	cp	xwa, 29360152
	jrl	z, 147
	cp	xwa, 29360154
	jrl	z, 138
	cp	xwa, 29360151
	jr	z, 9
	cp	xwa, 29360153
	jrl	nz, 1992
	ld16_24	bc, 160990
	cp	bc, 13
	jrl	c, 1980
	sub	bc, 13
	st16_24	160990, bc
	ld16_24	wa, 160986
	extz	xwa
	sll	xwa, 2
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	extz	xbc
	sll	xbc, 2
	.byte 0xaf, 0x04, 0x81
	ld	xwa, (xbc)
	ld	xbc, (xsp+8)
	call	16459328
	ld16_24	wa, 160984
	extz	xwa
	lda_24	xde, 160944
	ld	xbc, xde
	add	xbc, xwa
	ld	a, (xsp+12)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, 29360143
	call	16422496
	ld16_24	de, 160990
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 29360142
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	476
	ld16_24	wa, 160986
	extz	xwa
	sll	xwa, 2
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	ld16_24	wa, 160990
	extz	xwa
	sll	xwa, 2
	.byte 0xaf, 0x04, 0x80
	ld	xwa, (xwa)
	ld	xbc, (xsp+8)
	call	16459328
	ld16_24	wa, 160994
	mul	wa, 3
	addda16_24	wa, 160986
	extz	xwa
	add	xwa, xwa
	lda_24	xde, 15376094
	ld	xbc, xde
	add	xbc, xwa
	ld16_24	wa, 160990
	ld	hl, wa
	add	hl, 12
	.byte 0x91, 0xf3
	jr	ugt, 20
	ld	c, (xsp+12)
	cp	c, 90
	jr	z, 5
	cp	c, 122
	jr	nz, 7
	dec	1, wa
	st16_24	160990, wa
	ld16_24	bc, 160994
	mul	bc, 3
	ld16_24	wa, 160986
	add	bc, wa
	extz	xbc
	add	xbc, xbc
	add	xde, xbc
	ld16_24	wa, 160990
	ld	bc, wa
	add	bc, 13
	.byte 0x92, 0xf1
	jrl	ugt, 1732
	ld	bc, wa
	add	bc, 13
	st16_24	160990, bc
	ld16_24	wa, 160986
	extz	xwa
	sll	xwa, 2
	.byte 0x42
	.long Data_SoundEditorCharsLayout
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	extz	xbc
	sll	xbc, 2
	ld	xwa, xbc
	.byte 0xaf, 0x04, 0x80
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	16459328
	lda	xde, (xsp+12)
	ld	c, (xde)
	lda_24	xwa, 160944
	cp	c, 83
	jr	nz, 28
	.byte 0x8a, 0x01
	push	xsp
	.byte 0x50
	jr	nz, 22
	ld16_24	bc, 160984
	extz	xbc
	ld	xde, xwa
	add	xde, xbc
	ld32_24	xwa, 160996
	ld	a, (xwa)
	ld	(xde), a
	jr	11
	ld16_24	de, 160984
	extz	xde
	add	xwa, xde
	ld	(xwa), c
	ld	xwa, 22
	ld	xbc, 29360143
	ld	xde, 160944
	call	16422496
	ld16_24	de, 160990
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 29360142
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	jrl	181
	ld16_24	bc, 160986
	ld	wa, bc
	extz	xwa
	sll	xwa, 2
	ld	xde, 15376082
	add	xde, xwa
	ld	xwa, (xde)
	ld	(xsp+4), xwa
	ld16_24	wa, 160994
	mul	wa, 3
	add	wa, bc
	extz	xwa
	add	xwa, xwa
	ld	xbc, 15376094
	add	xbc, xwa
	ld16_24	wa, 160990
	ld	de, wa
	inc	1, de
	.byte 0x91, 0xf2
	jrl	ugt, 1516
	inc	1, wa
	st16_24	160990, wa
	extz	xwa
	sll	xwa, 2
	.byte 0xaf, 0x04, 0x80
	lda	xbc, (xsp+12)
	ld	xwa, (xwa)
	call	16459328
	lda	xde, (xsp+12)
	ld	c, (xde)
	ld16_24	wa, 160984
	extz	xwa
	cp	c, 83
	jr	nz, 24
	.byte 0x8a, 0x01
	push	xsp
	.byte 0x50
	jr	nz, 18
	ld	xbc, 160944
	add	xbc, xwa
	ld32_24	xwa, 160996
	ld	a, (xwa)
	ld	(xbc), a
	jr	9
	ld	xde, 160944
	add	xde, xwa
	ld	(xde), c
	ld	xwa, 22
	ld	xbc, 29360143
	ld	xde, 160944
	call	16422496
	ld16_24	de, 160990
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 29360142
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, (xsp+46)
	ld	xde, (xsp+42)
	calr	59928
	jrl	1389
	ld16_24	iz, 160982
	dec	1, iz
	.byte 0xd2
	scc16	ov, wa
	push_sr
	.byte 0xf6
	jr	ule, 47
	lda_24	xde, 160944
	ld	bc, iz
	extz	xbc
	ld	xwa, 4294967295
	add	xbc, xwa
	ld	xhl, xbc
	lds32	xwa, 1
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
	.byte 0xd2
	scc16	ov, wa
	push_sr
	.byte 0xf6
	jr	ugt, -31
	ld16_24	wa, 160984
	extz	xwa
	lda_24	xde, 160944
	ld	xbc, xde
	add	xbc, xwa
	ld32_24	xwa, 160996
	ld	a, (xwa)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, 29360143
	call	16422496
	ld16_24	de, 160984
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	jrl	1267
	ld16_24	iz, 160984
	.byte 0xd2, 0xd6
	jrl	ov, -2558
	jr	nc, 47
	lda_24	xde, 160944
	ld	bc, iz
	extz	xbc
	lds32	xwa, 1
	add	xbc, xwa
	ld	xhl, xbc
	ld	xwa, 4294967295
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
	.byte 0xd2, 0xd6
	jrl	ov, -2558
	jr	c, -34
	ld16_24	wa, 160982
	dec	1, wa
	extz	xwa
	lda_24	xde, 160944
	ld	xbc, xde
	add	xbc, xwa
	ld32_24	xwa, 160996
	ld	a, (xwa)
	ld	(xbc), a
	ld	xwa, 22
	ld	xbc, 29360143
	call	16422496
	ld16_24	de, 160984
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	jrl	1149
	.byte 0xd7
	swi	2
	sub	(xwa-34), xwa
	ld16_24	de, 160982
	cps	de, 0
	jr	ule, 28
	lda_24	xhl, 160944
	ld	a, (xbc)
	ld	bc, iz
	extz	xbc
	ld	xix, xhl
	add	xix, xbc
	.byte 0x84, 0xf1
	jr	nz, 9
	.byte 0xd7
	swi	2
	jr	lt, -34
	jr	lt, -38
	.byte 0xf6
	jr	c, -21
	.byte 0xd7
	swi	2
	.byte 0x88
	cp	wa, de
	jrl	z, 1103
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	lds	iz, 0
	cps	de, 0
	jr	ule, 37
	lda_24	xbc, 160944
	ld32_24	xwa, 160996
	ld	a, (xwa)
	ld	hl, de
	sub	hl, iz
	dec	1, hl
	extz	xhl
	ld	xix, xbc
	add	xix, xhl
	.byte 0x84, 0xf1
	jr	nz, 9
	incm	1, (xsp+4)
	inc	1, iz
	cp	iz, de
	jr	c, -25
	.byte 0xd7
	swi	2
	.byte 0x88
	ld	(xsp+6), wa
	ld	wa, (xsp+4)
	add	(xsp+6), wa
	.byte 0x9f, 0x06
	jrl	nc, 25050
	pushw	de
	call	16715392
	ld	(xsp+10), xhl
	.byte 0xd7
	swi	2
	.byte 0x88
	extz	xwa
	ld	xbc, 160944
	add	xbc, xwa
	push	xbc
	ld	xwa, (xsp+14)
	push	xwa
	call	16715597
	ld16_24	wa, 160982
	.byte 0xd7
	swi	2
	.byte 0xa0, 0x9f
	ret
	or	(xwa), xwa
	ccf
	.byte 0xaf
	ccf
	.byte 0x80
	ld	(xwa), 0
	ld	xwa, (xsp+18)
	push	xwa
	ld	wa, (xsp+20)
	extz	xwa
	ld	xbc, 160944
	add	xbc, xwa
	push	xbc
	call	16715597
	ld	xwa, (xsp+26)
	push	xwa
	call	16714482
	lda	xsp, (xsp+22)
	lds	iz, 0
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	ule, 31
	lda_24	xde, 160944
	ld32_24	xhl, 160996
	lds32	xbc, 0
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	.byte 0x9f, 0x06, 0xf6
	jr	c, -19
	.byte 0xd7
	swi	2
	.byte 0x89, 0x9f, 0x04, 0x81, 0x9f, 0x06, 0xa1
	ld16_24	wa, 160982
	ld	iz, wa
	sub	iz, bc
	cp	iz, wa
	jr	nc, 35
	lda_24	xde, 160944
	ld32_24	xhl, 160996
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	.byte 0xd2, 0xd6
	jrl	ov, -2558
	jr	c, -21
	ld	xwa, 22
	ld	xbc, 29360143
	ld	xde, 160944
	call	16422496
	ld16_24	de, 160984
	extz	xde
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	jrl	820
	lds	iz, 0
	.byte 0xd2, 0xd6
	jrl	ov, 16130
	nop
	nop
	jr	ule, 30
	lda_24	xde, 160944
	ld	xhl, xbc
	lds32	xbc, 0
	ld	xwa, xbc
	ld	xix, xde
	add	xix, xwa
	ld	a, (xhl)
	ld	(xix), a
	inc	1, iz
	inc	1, xbc
	.byte 0xd2, 0xd6
	jrl	ov, -2558
	jr	c, -21
	ld	xwa, 22
	ld	xbc, 31457408
	lds32	xde, 0
	call	16422496
	ld	xwa, 22
	ld	xbc, 29360143
	ld	xde, 160944
	call	16422496
	ld	xwa, (xsp+50)
	ld	xbc, 31457408
	lds32	xde, 0
	jrl	731

WndScroll_CopyStringAndSend:
	ld xwa, (xsp + 42)
	push xwa
	pushw 0x2
	pushw 0x74B0
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 50)
	ld xbc, 0x1E00080
	lds32 xde, 0
	jrl WndScroll_SendAndReturn

WndScroll_CopyFromSource:
	pushw 0x2
	pushw 0x74B0
	ld xwa, (xsp + 46)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl UIDialog_ReturnZeroJmp

WndScroll_StoreCallerPtr:
	ld xwa, (xsp + 42)
	st32_24 0x0274d2, xwa
	jrl UIDialog_ReturnZeroJmp

WndScroll_HandleIndexChange:
	ld wa, de
	st16_24 0x0274da, xde
	cpdi16_24 160994, 0
	jr nz, WndScroll_SendSelectionEvents
	ld de, wa
	extz xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002A
	call SendEvent

WndScroll_SendSelectionEvents:
	ld16_24 xde, 0x0274da
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1C0000F
	call SendEvent
	ld16_24 xwa, 0x0274da
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA9BF2
	add xbc, xwa
	ld xde, (xbc)
	ld xwa, 0x1D
	ld xbc, 0x1C0000F
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharInput:
	ld xwa, (xsp + 42)
	st16_24 0x0274d8, xwa
	ld de, wa
	extz xde
	ld xwa, 0x16
	ld xbc, 0x1E00080
	call SendEvent
	ld xwa, 0x16
	ld xbc, 0x1C0000F
	ld xde, 0x274B0
	call SendEvent
	ld16_24 xbc, 0x0274d8
	extz xbc
	lda_24 xde, 0x0274b0
	ld xwa, xde
	add xwa, xbc
	ld a, (xwa)
	ld c, a
	extz bc
	lda_24 xhl, 0xeed778
	ld_srib3 C, 0x07, 0xEC, 0xE4
	bit 0, c
	jr z, WndScroll_CharIsUppercase
	sti16_24 0x0274da, 0x0000
	ldb c, 0x41
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsUppercase:
	bit 1, c
	jr z, WndScroll_CharIsLowercase
	sti16_24 0x0274da, 0x0001
	ldb c, 0x61
	jr WndScroll_ComputeCharOffset

WndScroll_CharIsLowercase:
	bit 2, c
	jr z, WndScroll_CharIsSpace
	cpdi16_24 160986, 2
	jr nz, WndScroll_SetCategoryZero
	sti16_24 0x0274da, 0x0000

WndScroll_SetCategoryZero:
	ldb c, 0x15

WndScroll_ComputeCharOffset:
	ld16_24 xwa, 0x0274d8
	extz xwa
	add xde, xwa
	ld a, (xde)
	sub a, c
	extz wa
	st16_24 0x0274de, xwa
	jrl WndScroll_SendPageEvents

WndScroll_CharIsSpace:
	cp a, 0x20
	jr nz, WndScroll_CharIsUnderscore
	cpdi16_24 160994, 0
	jrl nz, WndScroll_SendPageEvents
	cpdi16_24 160986, 2
	jr nz, WndScroll_SetSpaceOffset
	sti16_24 0x0274da, 0x0000

WndScroll_SetSpaceOffset:
	sti16_24 0x0274de, 0x0025
	jr WndScroll_SendPageEvents

WndScroll_CharIsUnderscore:
	cp a, 0x5F
	jr nz, WndScroll_SearchCharTable
	cpdi16_24 160986, 2
	jr nz, WndScroll_SetUnderscoreOffset
	sti16_24 0x0274da, 0x0000

WndScroll_SetUnderscoreOffset:
	sti16_24 0x0274de, 0x001a
	jr WndScroll_SendPageEvents

WndScroll_SearchCharTable:
	lda_24 xwa, 0xea9e00
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
	ld16_24 xwa, 0x0274d8
	extz xwa
	ld xbc, 0x274B0
	add xbc, xwa
	ld a, (xbc)
	cp a, (xsp + 12)
	jr nz, WndScroll_CharMismatch
	sti16_24 0x0274da, 0x0002
	st16_24 0x0274de, xiz

WndScroll_CharMismatch:
	inc 1, iz

WndScroll_CheckTableEnd:
	ld16_24 xwa, 0x0274e2
	mul wa, 0x3
	inc 2, wa
	extz xwa
	add xwa, xwa
	ld xbc, 0xEA9EDE
	add xbc, xwa
	cp iz, (xbc)
	jr ule, WndScroll_CompareCharLoop

WndScroll_SendPageEvents:
	ld16_24 xde, 0x0274da
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1E0007F
	call SendEvent
	ld16_24 xde, 0x0274de
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1C0000E
	jrl WndScroll_SendAndReturn

WndScroll_HandleCharSet:
	ld16_24 xwa, 0x0274d8
	extz xwa
	ld xbc, 0x274B0
	add xbc, xwa
	ld xwa, (xsp + 42)
	ld (xbc), a
	ld16_24 xde, 0x0274d8
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1E00080
	jrl WndScroll_SendAndReturn

WndScroll_HandleDialPage:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	calr WindowProc
	ld xwa, (xsp + 42)
	srl xwa, 0
	ldi_werp 0xE2, 0
	cps wa, 0
	jrl nz, UIDialog_ReturnZeroJmp
	ld xwa, (xsp + 42)
	ld de, wa
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1E0007F
	call SendEvent
	ld16_24 xwa, 0x0274e2
	mul wa, 0x3
	addda16_24 xwa, 160986
	ld bc, wa
	extz xbc
	add xbc, xbc
	ld xwa, 0xEA9EDE
	add xwa, xbc
	ld wa, (xwa)
	cpdm16_24 160990, xwa
	jr ule, WndScroll_ClampPageCount
	st16_24 0x0274de, xwa

WndScroll_ClampPageCount:
	ld16_24 xwa, 0x0274da
	extz xwa
	sll xwa, 2
	ld xbc, 0xEA9ED2
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 4), xwa
	ld16_24 xwa, 0x0274de
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
	ld32_24 xwa, 0x0274e4
	lds32 xde, 0
	ld e, (xwa)
	ld xwa, (xsp + 50)
	ld xbc, 0x1E00081
	jr WndScroll_SendConfirmEvent

WndScroll_CheckSPMarker:
	ldb d, 0x0
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1E00081

WndScroll_SendConfirmEvent:
	call SendEvent
	ld16_24 xde, 0x0274de
	extz xde
	ld xwa, (xsp + 50)
	ld xbc, 0x1C0000E

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
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x01
	st_dri3l XWA, 0xFD, 0x14, 0x01
	cp xbc, 0x1C00011
	jrl z, ModeEdit_HandleViewUpdate
	cp xbc, 0x1C0000D
	jr z, ModeEdit_HandlePaint
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	jrl ModeEdit_Epilogue

ModeEdit_HandlePaint:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	call GetModeNow
	ld xwa, xhl
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	push xhl
	call GetModeNow
	ldi_werp 0xEE, 0
	pushw hl
	pushw 0xEA
	pushw 0x9F08
	lda xwa, (xsp + 14)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	st_dri3b A, 0xFD, 0x04, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x04, 0x01
	st_dri3b A, 0xFD, 0x0C, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x04, 0x01
	st_dri3b A, 0xFD, 0x0C, 0x01
	lda xde, (xsp + 4)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	call DrawStringCentered
	jrl TitleEdit_ReturnZero

ModeEdit_HandleViewUpdate:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1E00022
	ld_sril XDE, (xsp + 0x0110)
	call SendEvent
	lda xwa, (xiz + 26)
	cp xhl, 0x58
	jrl z, ModeEdit_StoreField3
	ld xwa, (xwa)
	cp xhl, 0x6C
	jrl z, ModeEdit_StoreField2
	cp xhl, 0x61
	jr z, ModeEdit_StoreField1
	cp xhl, 0x6A
	jr z, ModeEdit_StoreField0
	cp xhl, 0x60
	jrl nz, TitleEdit_ReturnZero
	ld xbc, 0x1E0002C
	lds32 xde, 0
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E0002D
	lds32 xde, 0
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E00030
	lds32 xde, 0
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld (xiz + 40), xhl
	jr TitleEdit_ReturnZero

ModeEdit_StoreField0:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField1:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField2:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr TitleEdit_ReturnZero

ModeEdit_StoreField3:
	ld xwa, (xwa)
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

TitleEdit_ReturnZero:
	lds32 xhl, 0

ModeEdit_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

TitleEditProc:
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x01
	st_dri3l XWA, 0xFD, 0x14, 0x01
	cp xbc, 0x1C00011
	jrl z, TitleEdit_HandleViewUpdate
	cp xbc, 0x1C0000D
	jr z, TitleEdit_HandlePaint
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	jrl TitleEdit_Epilogue

TitleEdit_HandlePaint:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	push xhl
	call GetTitleNow
	ldi_werp 0xEE, 0
	pushw hl
	pushw 0xEA
	pushw 0x9F14
	lda xwa, (xsp + 14)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 14)
	st_dri3b A, 0xFD, 0x04, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x04, 0x01
	st_dri3b A, 0xFD, 0x0C, 0x01
	calr GetBoxCenter
	st_dri3b W, 0xFD, 0x04, 0x01
	st_dri3b A, 0xFD, 0x0C, 0x01
	lda xde, (xsp + 4)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	call DrawStringCentered
	jrl StringBox_ReturnZero

TitleEdit_HandleViewUpdate:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr BoxProc
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1E00022
	ld_sril XDE, (xsp + 0x0110)
	call SendEvent
	lda xwa, (xiz + 26)
	cp xhl, 0x58
	jrl z, TitleEdit_StoreFieldX
	ld xwa, (xwa)
	cp xhl, 0x6C
	jrl z, TitleEdit_StoreFieldLC
	cp xhl, 0x4E
	jr z, TitleEdit_StoreFieldNE
	cp xhl, 0x6A
	jr z, TitleEdit_StoreFieldJA
	cp xhl, 0x61
	jrl nz, StringBox_ReturnZero
	ld xbc, 0x1E00032
	lds32 xde, 0
	call SendEvent
	ld (xiz + 30), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E00033
	lds32 xde, 0
	call SendEvent
	ld (xiz + 34), xhl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E00030
	lds32 xde, 0
	call SendEvent
	ld (xiz + 38), hl
	ld xwa, (xiz + 26)
	ld xbc, 0x1E00015
	lds32 xde, 0
	call SendEvent
	ld (xiz + 40), xhl
	jr StringBox_ReturnZero

TitleEdit_StoreFieldJA:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 30)
	ld (xhl), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldNE:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 34)
	ld (xhl + 4), xwa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldLC:
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld wa, (xiz + 38)
	ld (xhl + 8), wa
	jr StringBox_ReturnZero

TitleEdit_StoreFieldX:
	ld xwa, (xwa)
	ld xbc, 0x1E0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 40)
	ld (xhl + 10), xwa

StringBox_ReturnZero:
	lds32 xhl, 0

TitleEdit_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

StringBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000D
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
	pushw 0xF7
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
	cp xbc, 0x1C0000D
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
	pushw 0xF7	; <-- background color
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
	cp xbc, 0x1C0000D
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
	cp xbc, 0x1C0000D
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
	ld xbc, 0x1E000A1
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, VwUserBitmap_DrawFallback
	ld xwa, (xiz + 22)
	ld xbc, 0x1E000A2
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), hl
	ld xwa, (xiz + 22)
	ld xbc, 0x1E000A3
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
	cp xbc, 0x1E000A3
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, 0x1E000A2
	jr z, UserBitmapCheck_ReturnSize
	cp xbc, 0x1E000A1
	jr z, UserBitmapCheck_ReturnTablePtr
	lds32 xhl, 0
	ret

UserBitmapCheck_ReturnTablePtr:
	lda_24 xhl, 0xea9f20
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
	cp xiz, 0x1C00002
	jrl z, VwUserBitmapByName_HandleClose
	cp xiz, 0x1C0000D
	jr z, VwUserBitmapByName_HandlePaint
	cp xiz, 0x1C00001
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
	pushw 0xEA
	pushw 0xA160
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
	cp xbc, 0x1C0000D
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
	ldw bc, 0xC4
	ldw de, 0xF0
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
	cp xbc, 0x1C0000D
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
	cp xwa, 0x1C0000D
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
	cp xwa, 0x1C00007
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
	ld xbc, 0x1E00029
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
	cp de, 0xFFFF
	jr z, EditSw_ReturnZero
	exts xde
	ld xwa, (xsp + 8)
	bit 7, wa
	jr z, EditSw_SendDialDown
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00018
	jr EditSw_SendDialEvent

EditSw_SendDialDown:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00017

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
	lda	xsp, (xsp-28)
	pushw	iz
	call	16409190
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+2), xwa
	lda	xbc, (xsp+18)
	ld	wa, (xwa+32)
	calr	57283
	lda	xwa, (xsp+18)
	lda	xbc, (xsp+12)
	.byte 0x98
	push_sr
	push	xsp
	.byte 0xef
	nop
	jr	z, 20
	.byte 0x90
	push	xsp
	nop
	nop
	jr	nz, 7
	ld	xwa, 15376742
	jr	12
	ld	xwa, 15376746
	jr	5
	ld	xwa, 15376750
	push	xwa
	push	xbc
	call	16715597
	lda	xwa, (xsp+20)
	push	xwa
	call	16715680
	ld	iz, hl
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+22)
	push	xwa
	call	16715680
	lda	xsp, (xsp+16)
	cp	hl, iz
	jr	ule, 23
	lda	xwa, (xsp+12)
	push	xwa
	call	16715680
	inc	1, hl
	pushw	hl
	call	16715392
	inc	6, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+22), xhl
	lda	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+22)
	push	xwa
	call	16715597
	inc	8, xsp
	ld	xbc, (xsp+8)
	ld	xwa, (xbc+22)
	ld	xbc, (xbc+26)
	call	16459473
	ld	(xsp+6), hl
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+26)
	call	16459274
	lda	xbc, (xsp+18)
	ld	wa, hl
	exts	xwa
	divs	wa, 2
	lda	xix, (xsp+22)
	.byte 0x91
	push	xsp
	nop
	nop
	jr	nz, 12
	.byte 0xb4
	push_sr
	swi	6
	swi	7
	ld	de, (xbc+2)
	sub	de, wa
	ld	(xix+2), de
	.byte 0x91
	push	xsp
	push	xsp
	.byte 0x01
	jr	nz, 16
	ldw	de, 318
	.byte 0x9f, 0x06, 0xa2
	ld	(xix), de
	ld	de, (xbc+2)
	sub	de, wa
	ld	(xix+2), de
	.byte 0x99
	push_sr
	push	xsp
	.byte 0xef
	nop
	jr	nz, 25
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
	lda	xde, (xix+4)
	ld	wa, (xsp+6)
	.byte 0x94
	xor	(xwa), w
	jr	lt, -78
	.byte 0x50
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
	cp wa, 0xFF
	jrl z, DrawEditSw_SkipDraw
	cp wa, 0xF
	jrl z, DrawEditSw_SkipDraw
	lda xbc, (xsp + 8)
	calr GetEditSwPoint
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 2)
	cpw (xwa + 2), 0xEF
	jr z, DrawEditSw_SelectVariantC
	cpw (xwa), 0x0
	jr nz, DrawEditSw_SelectVariantA
	ld xwa, 0xEAA172
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantA:
	ld xwa, 0xEAA176
	jr DrawEditSw_CopyVariant

DrawEditSw_SelectVariantC:
	ld xwa, 0xEAA17A

DrawEditSw_CopyVariant:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 2)
	lds32 xbc, 0
	call CalcTotalWidth
	ld iz, hl
	lds32 xwa, 0
	call GetCharHeight
	lda xbc, (xsp + 8)
	ld de, hl
	exts xde
	divs de, 0x2
	lda xwa, (xsp + 12)
	cpw (xbc), 0x0
	jr nz, DrawEditSw_PositionLeft
	ldw (xwa), 0xFFFE
	ld ix, (xbc + 2)
	sub ix, de
	ld (xwa + 2), ix

DrawEditSw_PositionLeft:
	cpw (xbc), 0x13F
	jr nz, DrawEditSw_PositionRight
	ldw ix, 0x13E
	sub ix, iz
	ld (xwa), ix
	ld ix, (xbc + 2)
	sub ix, de
	ld (xwa + 2), ix

DrawEditSw_PositionRight:
	lda xix, (xbc + 2)
	cpw (xix), 0xEF
	jr nz, DrawEditSw_FinalPosition
	ld de, iz
	exts xde
	divs de, 0x2
	ld iy, (xbc)
	sub iy, de
	dec 1, iy
	ld (xwa), iy
	ldw de, 0xF5
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
	pushw 0xF4
	pushw 0xF7
	call DrawString

DrawEditSw_SkipDraw:
	popw iz
	lda xsp, (xsp + 18)
	ret

TextBoxProc:
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), xwa
	cp xbc, 0x1C0000D
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
	lds bc, 0
	ld wa, (xsp + 16)
	add wa, 0x1
	jr ule, TextBox_SetupWordwrap

TextBox_FillBufferLoop:
	stib_dpi 0xF8, 0x00
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
	pushw 0xEA
	pushw 0xA17E
	push xiz
	call StrSearch_Init
	inc 8, xsp
	st_dri3b W, 0x07, 0xF8, 0xEC
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
	ld (xwa), 0xD
	ld wa, (xsp + 14)
	exts xwa
	add xwa, xiz
	ld (xsp + 10), xwa
	stib_dpd 0xE0, 0x00
	ld (xsp + 10), xwa

TextBox_CheckMoreText:
	ld wa, (xsp + 8)
	mrdw3 0x9F, 0x10, 0x40
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
	pushw 0xF7
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
	ld xwa, (xsp + 22)
	push xwa
	call Free
	inc 4, xsp
	lds32 xhl, 0

TextBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret

VwBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xwa
	cp xbc, 0x1E000B2
	jrl z, VwBox_HandleGetColor
	cp xbc, 0x1E000B1
	jrl z, VwBox_HandleGetHeight
	cp xbc, 0x1E00050
	jr z, VwBox_HandleHitTest
	cp xbc, 0x1E00051
	jr z, VwBox_HandleGetWidth
	cp xbc, 0x1E0004E
	jr z, VwBox_HandleGetFocus
	cp xbc, 0x1C0000D
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
	pushw 0xF2
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
	ld xiz, 0x1A
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
	st_dri3b L, 0xFD, 0xEC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x10, 0x01
	st_dri3l XWA, 0xFD, 0x14, 0x01
	cp xbc, 0x1E0003A
	jrl z, PsParaBox_HandleGetText
	cp xbc, 0x1C0000F
	jr z, PsParaBox_HandleConfirm
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr VwBoxProc
	jrl PsParaBox_Epilogue

PsParaBox_HandleConfirm:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	calr VwBoxProc
	st_dri3b A, 0xFD, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0114)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x08, 0x01
	st_dri3b A, 0xFD, 0x04, 0x01
	calr GetBoxCenter
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0110)
	or xwa, xwa
	jr nz, PsParaBox_UseEventText
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1E0003A
	call SendEvent
	cp (xsp + 4), 0x0
	jr nz, PsParaBox_DrawAligned
	jr PsParaBox_ReturnZero

PsParaBox_UseEventText:
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsParaBox_DrawAligned:
	st_dri3b W, 0xFD, 0x08, 0x01
	st_dri3b C, 0xFD, 0x04, 0x01
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
	st_dri3b L, 0xFD, 0x14, 0x01
	ret

AcLswBoxProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xwa
	cp xbc, 0x1C00018
	jrl z, AcLswBox_HandlePageDown
	cp xbc, 0x1C0001A
	jrl z, AcLswBox_HandlePageUp
	cp xbc, 0x1C00017
	jrl z, AcLswBox_HandleScrollDown
	cp xbc, 0x1C00019
	jrl z, AcLswBox_HandleScrollUp
	cp xbc, 0x1C0001C
	jrl z, AcLswBox_HandleWriteBack
	cp xbc, 0x1C0000C
	jr z, AcLswBox_HandleShowHide
	cp xbc, 0x1C0000B
	jr z, AcLswBox_HandleShowHide
	cp xbc, 0x1C00002
	jr z, AcLswBox_HandleClose
	cp xbc, 0x1C00001
	jr z, AcLswBox_HandleCreate
	cp xbc, 0x1E0003A
	jrl nz, AcLswBox_DefaultHandler
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1E00040
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
	ld xbc, 0x1E00042
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
	ld xbc, 0x1E00040
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
	ld xbc, 0x1E00040
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
	ld xbc, 0x1E00083
	call ApFuncCall
	ld xwa, (xsp + 20)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1E0003D
	jrl Ac_SendUIEvent_Common

AcLswBox_HandleScrollDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1E0003D
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageUp:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1E0003D
	ld xde, xhl
	jr Ac_SendUIEvent_Common

AcLswBox_HandlePageDown:
	ld xwa, (xsp + 20)
	ld xde, (xsp + 16)
	calr PsParaBoxProc
	ld xwa, (xsp + 20)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 20)
	ld xbc, 0x1E0003D
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
	cp xbc, 0x1C00018
	jrl z, AcRamBox_HandlePageDown
	cp xbc, 0x1C0001A
	jrl z, AcRamBox_HandlePageUp
	cp xbc, 0x1C00017
	jrl z, AcRamBox_HandleScrollDown
	cp xbc, 0x1C00019
	jrl z, AcRamBox_HandleScrollUp
	cp xbc, 0x1C0001D
	jrl z, AcRamBox_HandleWriteBack
	cp xbc, 0x1E000A7
	jr z, AcRamBox_HandleDataRefresh
	cp xbc, 0x1C0000C
	jr z, AcRamBox_HandleShowHide
	cp xbc, 0x1C0000B
	jr z, AcRamBox_HandleShowHide
	cp xbc, 0x1E0003A
	jrl nz, AcRamBox_DefaultHandler
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1E00045
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
	ld xbc, 0x1E00047
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), xhl
	ld xwa, (xiz + 36)
	ld xbc, 0x1E00046
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
	ld xbc, 0x1E00045
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
	ld xbc, 0x1E00082
	call ApFuncCall
	ld xwa, (xsp + 34)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	jrl AcRamBox_SendUIEvent_Common

AcRamBox_HandleScrollDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageUp:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
	ld xde, xhl
	jr AcRamBox_SendUIEvent_Common

AcRamBox_HandlePageDown:
	ld xwa, (xsp + 34)
	ld xde, (xsp + 30)
	calr PsParaBoxProc
	ld xwa, (xsp + 34)
	call GetViewInstance
	ld xwa, (xhl + 36)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld xwa, (xsp + 34)
	ld xbc, 0x1E0003D
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
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C0001C
	jr z, AcTempoBox_HandleConfirm
	cp xbc, 0x1C0000C
	jr z, AcTempoBox_HandleShowHide
	cp xbc, 0x1C0000B
	jr z, AcTempoBox_HandleShowHide
	cp xbc, 0x1C00002
	jr z, AcTempoBox_HandleClose
	cp xbc, 0x1C00001
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
	ld xwa, 0x2200
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, AcTempoBox_CopyTempoString
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xEA
	pushw 0xA180
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr AcTempoBox_SendConfirmEvent

AcTempoBox_CopyTempoString:
	pushw 0xEA
	pushw 0xA188
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

AcTempoBox_SendConfirmEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	call SendEvent

PsRadioBox_EventReturn:
	lds32 xhl, 0

AcTempoBox_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret

PsRadioBoxProc:
	st_dri3b L, 0xFD, 0xDC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x1C, 0x01
	st_dri3l XBC, 0xFD, 0x20, 0x01
	st_dri3l XWA, 0xFD, 0x24, 0x01
	ld_sril XWA, (xsp + 0x0120)
	cp xwa, 0x1E00053
	jrl z, PsRadioBox_HitTest
	cp xwa, 0x1E0003A
	jrl z, PsRadioBox_GetText
	cp xwa, 0x1E0004D
	jrl z, PsRadioBox_SetIndex
	cp xwa, 0x1C0002A
	jrl z, PsRadioBox_RadioSelect
	cp xwa, 0x1C0001B
	jrl z, PsRadioBox_Release
	cp xwa, 0x1C00007
	jrl z, PsRadioBox_OK
	cp xwa, 0x1C0002C
	jrl z, PsRadioBox_Reset
	cp xwa, 0x1C0000E
	jrl z, PsRadioBox_Select
	cp xwa, 0x1C0000F
	jr z, PsRadioBox_Confirm
	cp xwa, 0x1C0000D
	jrl nz, PsRadioBox_Default
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	st_dri3b A, 0xFD, 0x10, 0x01
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr GetEditSwPoint
	cp_sriw_im 0xFD, 0x12, 0x01, 0xEF, 0x00
	jr z, PsRadioBox_Paint_SendConfirm
	ld xwa, (xsp + 12)
	ld wa, (xwa + 36)
	calr DrawEditSw

PsRadioBox_Paint_SendConfirm:
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Confirm:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	st_dri3b A, 0xFD, 0x14, 0x01
	ld_sril XWA, (xsp + 0x0124)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x14, 0x01
	st_dri3b A, 0xFD, 0x10, 0x01
	calr GetBoxCenter
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xde, (xsp + 16)
	ld_sril XWA, (xsp + 0x011c)
	or xwa, xwa
	jr nz, PsRadioBox_Confirm_CopyText
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0003A
	call SendEvent
	cp (xsp + 16), 0x0
	jr nz, PsRadioBox_Confirm_Draw
	jrl PsRadioBox_ReturnZero

PsRadioBox_Confirm_CopyText:
	ld_sril XWA, (xsp + 0x011c)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsRadioBox_Confirm_Draw:
	calr GetDialFocus
	st_dri3b W, 0xFD, 0x14, 0x01
	st_dri3b A, 0xFD, 0x10, 0x01
	ld (xsp + 12), xbc
	lda xbc, (xsp + 16)
	ld (xsp + 8), xbc
	ld xbc, (xsp + 4)
	lda xde, (xbc + 22)
	lda xiz, (xbc + 28)
	lda xiy, (xbc + 32)
	ld c, (xbc + 34)
	ldfr_berp C, 0xF0
	extz ix
	cp_sril_rm XHL, 0xFD, 0x24, 0x01
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
	cp_sril_rm XHL, 0xFD, 0x24, 0x01
	jr nz, PsRadioBox_Select_GetIndex
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0004E
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Select_GetIndex:
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 38)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0004E
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset:
	ld_sril XWA, (xsp + 0x0124)
	ld_sril XBC, (xsp + 0x0120)
	ld_sril XDE, (xsp + 0x011c)
	calr VwBoxProc
	calr GetDialFocus
	cp_sril_rm XHL, 0xFD, 0x24, 0x01
	jr nz, PsRadioBox_Reset_CheckValue
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_Reset_CheckValue:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PsRadioBox_DispatchAndReturn

PsRadioBox_OK:
	ld_sril XWA, (xsp + 0x0124)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E00053
	ld_sril XDE, (xsp + 0x011c)
	call SendEvent
	or xhl, xhl
	jr z, PsRadioBox_OK_Forward
	ld xwa, (xsp + 12)
	cpw (xwa + 26), 0xFFFF
	jr z, PsRadioBox_OK_Forward
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0004D
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
	cp_sril_rm XWA, 0xFD, 0x1C, 0x01
	jrl nz, PsRadioBox_ReturnZero
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0004D
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
	cpw (xwa), 0xFFFF
	jrl z, PsRadioBox_ReturnZero
	ld_sril XBC, (xsp + 0x011c)
	srl xbc, 0
	ldi_werp 0xE6, 0
	ld wa, (xwa)
	cp wa, bc
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x011c)
	ld bc, (xhl + 42)
	cp bc, wa
	jrl nz, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1E0004D
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
	cp_sril_rm XWA, 0xFD, 0x1C, 0x01
	jr z, PsRadioBox_ReturnZero
	ld_sril XWA, (xsp + 0x011c)
	cps wa, 1
	jr nz, PsRadioBox_SetIndex_Store
	ld de, (xbc + 26)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent
	ld xwa, (xsp + 12)
	ld bc, (xwa + 42)
	extz xbc
	ld wa, (xwa + 26)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00029
	call SendEvent

PsRadioBox_SetIndex_Store:
	ld xwa, (xsp + 12)
	ld xbc, (xwa + 38)
	ld_sril XWA, (xsp + 0x011c)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0124)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00029
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
	st_dri3b L, 0xFD, 0x24, 0x01
	ret

AcStrRadioBoxProc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1E0003A
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
	lds32 xhl, 0

AcStrRadioBox_Epilogue:
	pop xiz
	ret

PsListBoxProc:
	st_dri3b L, 0xFD, 0xD6, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x26, 0x01
	st_dri3l XWA, 0xFD, 0x2A, 0x01
	cp xbc, 0x1E0003A
	jrl z, PsListBox_GetText
	cp xbc, 0x1E0004D
	jrl z, PsListBox_SetIndex
	cp xbc, 0x1E00090
	jrl z, PsListBox_GetCount
	cp xbc, 0x1C0002C
	jrl z, PsListBox_Reset
	cp xbc, 0x1C0000E
	jrl z, PsListBox_Select
	cp xbc, 0x1C0000F
	jr z, PsListBox_Confirm
	cp xbc, 0x1C0000D
	jrl nz, PsListBox_Default
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xwa, (xhl + 38)
	ld iz, (xwa)
	ldw (xwa), 0xFFFF
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld de, iz
	exts xde
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E0003A
	call SendEvent
	jr PsListBox_Confirm_Layout

PsListBox_Confirm_CopyText:
	ld_sril XWA, (xsp + 0x0126)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsListBox_Confirm_Layout:
	ld_sril XWA, (xsp + 0x012a)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	st_dri3b A, 0xFD, 0x1E, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x1E, 0x01
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
	cp a, 0x7C
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
	st_dri3b W, 0xFD, 0x1E, 0x01
	st_dri3b A, 0xFD, 0x1A, 0x01
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
	st_dri3b A, 0xFD, 0x1A, 0x01
	lda xix, (xwa + 32)
	cp de, (xsp + 10)
	jr nz, PsListBox_Confirm_ItemUnfocused
	st_dri3b H, 0xFD, 0x1E, 0x01
	ld (xsp + 18), xbc
	ld xwa, (xiy)
	push xwa
	pushm (xix)
	ld xwa, (xsp + 28)
	pushm (xwa)
	pushw hl
	calr GetDialFocus
	cp_sril_rm XHL, 0xFD, 0x34, 0x01
	scc16 z, wa
	pushw wa
	ld xwa, xiz
	ld xbc, (xsp + 30)
	ld xde, (xsp + 26)
	jr PsListBox_Confirm_RenderText

PsListBox_Confirm_ItemUnfocused:
	st_dri3b W, 0xFD, 0x1E, 0x01
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
	st_dri3b A, 0xFD, 0x1E, 0x01
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
	cp_sril_rm XBC, 0xFD, 0x26, 0x01
	jrl z, PsListBox_ReturnZero
	ld xwa, (xwa)
	cpw (xwa), 0xFFFF
	jrl z, PsListBox_Select_UpdateCurrent
	st_dri3b A, 0xFD, 0x1E, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x1E, 0x01
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
	st_dri3b A, 0xFD, 0x1A, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1E0003A
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
	cp a, 0x7C
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
	st_dri3b B, 0xFD, 0x1E, 0x01
	st_dri3b A, 0xFD, 0x1A, 0x01
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
	cp_sril_rm XHL, 0xFD, 0x2A, 0x01
	jr z, PsListBox_Select_UpdateCurrent
	st_dri3b W, 0xFD, 0x1E, 0x01
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
	st_dri3b A, 0xFD, 0x1E, 0x01
	ld_sril XWA, (xsp + 0x012a)
	calr GetClientBox
	st_dri3b W, 0xFD, 0x1E, 0x01
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
	st_dri3b A, 0xFD, 0x1A, 0x01
	calr GetBoxCenter
	lda xde, (xsp + 26)
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1E0003A
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
	cp a, 0x7C
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
	st_dri3b A, 0xFD, 0x1A, 0x01
	ld xwa, (xsp + 22)
	lda xiy, (xwa + 32)
	st_dri3b B, 0xFD, 0x1E, 0x01
	lda xiz, (xwa + 28)
	ld xwa, (xsp + 4)
	ld a, (xwa + 34)
	ldfr_berp A, 0xF0
	extz ix
	cp_sril_rm XHL, 0xFD, 0x2A, 0x01
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
	st_dri3b W, 0xFD, 0x1E, 0x01
	pushw 0xF2
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
	ld xbc, 0x1C0000E
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
	cp_sril_rm XWA, 0xFD, 0x26, 0x01
	jr z, PsListBox_ReturnZero
	ld wa, (xhl + 36)
	extz xwa
	cp_sril_mr XWA, 0xFD, 0x26, 0x01
	jr nc, PsListBox_ReturnZero
	ld_sril XWA, (xsp + 0x012a)
	ld xbc, 0x1C0000E
	ld_sril XDE, (xsp + 0x0126)

PsListBox_SendEvent:
	call SendEvent
	jr PsListBox_ReturnZero

PsListBox_GetText:
	pushw 0xEA
	pushw 0xA190
	ld_sril XWA, (xsp + 0x012a)
	push xwa
	call Strcpy
	inc 8, xsp

PsListBox_ReturnZero:
	lds32 xhl, 0
	jr PsListBox_Return

PsListBox_Default:
	ld_sril XWA, (xsp + 0x012a)
	ld_sril XDE, (xsp + 0x0126)
	calr VwBoxProc

PsListBox_Return:
	pop xiz
	st_dri3b L, 0xFD, 0x2A, 0x01
	ret

AcListBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xwa
	cp xbc, 0x1E0003A
	jrl z, AcListBox_GetText
	cp xbc, 0x1C00018
	jrl z, AcListBox_ScrollDownInc
	cp xbc, 0x1C0001A
	jrl z, AcListBox_ScrollDownInc
	cp xbc, 0x1C00017
	jr z, AcListBox_ScrollUpDown
	cp xbc, 0x1C00019
	jr z, AcListBox_ScrollUpDown
	cp xbc, 0x1C00001
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
	ld xbc, 0x1C00018
	calr SetDialUp
	ld de, (xiz + 26)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00017
	calr SetDialDown
	lds wa, 1
	jrl AcListBox_EnableDials

AcListBox_ScrollUpDown:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0004D
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00019
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jrl z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	calr SetDialDown
	lds wa, 1
	jr AcListBox_EnableDials

AcListBox_ScrollDownInc:
	ld xwa, (xsp + 12)
	ld xde, (xsp + 8)
	calr PsListBoxProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	exts xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0004D
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1C0001A
	ld xde, (xsp + 8)
	calr SetAutoInc
	ld xwa, (xsp + 4)
	cpw (xwa + 46), 0x0
	jr z, AcListBox_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	calr SetDialUp
	ld xwa, (xsp + 12)
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	calr SetDialDown
	lds wa, 1

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
	st_dri3b L, 0xFD, 0xB2, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x46, 0x01
	st_dri3l XBC, 0xFD, 0x4A, 0x01
	st_dri3l XWA, 0xFD, 0x4E, 0x01
	ld_sril XBC, (xsp + 0x014a)
	cp xbc, 0x1C00018
	jrl z, PsGridBox_Scroll
	ld_sril XWA, (xsp + 0x014a)
	cp xwa, 0x1C0001A
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1C00017
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1C00019
	jrl z, PsGridBox_Scroll
	cp xwa, 0x1C0000E
	jrl z, PsGridBox_Select
	cp xwa, 0x1C0000F
	jrl z, PsGridBox_Confirm
	cp xwa, 0x1C0000D
	jrl z, PsGridBox_Paint
	cp xwa, 0x1C0000C
	jrl z, PsGridBox_ShowHide
	cp xwa, 0x1C0000B
	jrl z, PsGridBox_ShowHide
	cp xwa, 0x1C00002
	jrl z, PsGridBox_Close
	cp xwa, 0x1C00001
	jr z, PsGridBox_Init
	sub xbc, 0x1E0008A
	cp xbc, 0x0
	jrl lt, PsGridBox_Default
	cp xbc, 0x7
	jrl gt, PsGridBox_Default
	add xbc, xbc
	add xbc, 0xEAA248
	ld bc, (xbc)
	lda_24 xix, 0xf9de32
	jp_dri 8, 0x07, 0xF0, 0xE4

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
	cp wa, 0xF0
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
	cp wa, 0xFF
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
	cp bc, 0xFF
	ret gt
	ret

DrawDesignBox_ByteData:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	-11516
	cps	hl, 0
	jr	z, 22
	cpdi16_24	197710, 0
	jr	z, 58
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	75
	jr	45
	ldw	wa, 14
	calr	-11786
	ld	xwa, xhl
	lda_24	xbc, 16437881
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
	calr	-12041
	pop	xiz
	inc	6, xsp
	ret
	lda	xhl, (xwa+4)
	lda	xbc, (xwa+8)
	ld	de, (xwa+12)
	cpdi16_24	197710, 0
	ret	z
	ld	xwa, xhl
	calr	1
	ret
	lda	xsp, (xsp-52)
	push	xiz
	ld	(xsp+46), de
	ld	(xsp+48), xbc
	ld	(xsp+52), xwa
	ld	(xsp+20), 0
	ld	xde, 4294967295
	ld	xwa, (xsp+48)
	ld	bc, (xwa)
	ld	xwa, (xsp+52)
	cp	bc, (xwa)
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+12), xde
	ld	xde, 4294967295
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
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, 12
	ld	xwa, (xsp+48)
	ld	de, (xwa)
	ld	xwa, (xsp+52)
	sub	de, (xwa)
	jr	10
	ld	xwa, (xsp+52)
	ld	de, (xwa)
	ld	xwa, (xsp+48)
	sub	de, (xwa)
	exts	xde
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, 6
	sub	bc, hl
	ld	hl, bc
	jr	2
	sub	hl, bc
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 8
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, 551
	ld	xwa, (xsp+52)
	ld	xiy, xwa
	lda	xix, (xsp+42)
	ldiw
	ldiw
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 87
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 481
	cp	(xsp+20), 3
	jr	ule, 6
	ld	(xsp+20), 0
	jr	45
	cp	(xsp+20), 1
	jr	ugt, 36
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
	ld	xde, 277504
	add	xde, xwa
	ld	wa, (xsp+46)
	ld	(xde), a
	incm8	1, (xsp+20)
	ld	xwa, (xsp+16)
	add	(xsp+44), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, -70
	jrl	408
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, 87
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 387
	cp	(xsp+20), 3
	jr	ule, 6
	ld	(xsp+20), 0
	jr	45
	cp	(xsp+20), 1
	jr	ugt, 36
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
	ld	xde, 277504
	add	xde, xwa
	ld	wa, (xsp+46)
	ld	(xde), a
	incm8	1, (xsp+20)
	ld	xwa, (xsp+12)
	add	(xsp+42), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, -70
	jrl	314
	lda	xwa, (xsp+42)
	ld	(xsp+30), xwa
	ld	xwa, (xsp+8)
	cp	xwa, (xsp+4)
	jrl	le, 151
	ld	xwa, (xsp+4)
	sla	xwa, 0
	ld	xbc, (xsp+8)
	call	16714766
	ld	xiz, xhl
	ld	xwa, (xsp+12)
	ld	xbc, xiz
	call	16714332
	ld	(xsp+12), xhl
	ld	xde, (xsp+30)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 0
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 232
	cp	(xsp+20), 3
	jr	ule, 6
	ld	(xsp+20), 0
	jr	42
	cp	(xsp+20), 1
	jr	ugt, 33
	ld	wa, (xde+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xhl
	ld	xhl, 277504
	add	xhl, xwa
	ld	wa, (xsp+46)
	ld	(xhl), a
	incm8	1, (xsp+20)
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xde+2), wa
	inc	1, xbc
	cp	xbc, (xsp+8)
	jr	le, -81
	jrl	148
	ld	xwa, (xsp+8)
	sla	xwa, 0
	ld	xbc, (xsp+4)
	call	16714766
	ld	xiz, xhl
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	call	16714332
	ld	(xsp+16), xhl
	ld	xde, (xsp+30)
	ld	xwa, xde
	lda	xhl, (xwa+2)
	ld	wa, (xhl)
	exts	xwa
	ld	(xsp+8), xwa
	sla	xwa, 0
	ld	(xsp+8), xwa
	ld	xwa, 32768
	add	(xsp+8), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	lt, 79
	cp	(xsp+20), 3
	jr	ule, 6
	ld	(xsp+20), 0
	jr	41
	cp	(xsp+20), 1
	jr	ugt, 32
	ld	wa, (xhl)
	exts	xwa
	ld	xix, xwa
	sll	xix, 2
	add	xix, xwa
	sll	xix, 6
	ld	wa, (xde)
	exts	xwa
	add	xwa, xix
	ld	xix, 277504
	add	xix, xwa
	ld	wa, (xsp+46)
	ld	(xix), a
	incm8	1, (xsp+20)
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 0
	ld	(xhl), wa
	ld	xwa, (xsp+12)
	add	(xde), wa
	inc	1, xbc
	cp	xbc, (xsp+4)
	jr	le, -79
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
	calr	-11762
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
	cps hl, 0
	jr z, DrawDesignBox_QueuedPath
	cpdi16_24 197710, 0
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
	lda_24 xbc, 0xfad5ac
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
	pop_sr
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
	cpw (xsp + 72), 0xA8
	jr gt, DrawDesignBox_CheckStyleA0
	cpw (xsp + 72), 0xA1
	jrl ge, DrawDesignBox_PartGroupStyle

DrawDesignBox_CheckStyleA0:
	cp wa, 0xA0
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
	cp wa, 0xB
	jr le, Draw_DispatchByPartType
	sub wa, 0xB4
	cp wa, 0xC
	jr lt, Draw_StyledBoxWithFrame
	cp wa, 0x18
	jr gt, Draw_StyledBoxWithFrame

; Draw dispatch by part type
Draw_DispatchByPartType:
	add wa, wa
	lda_24 xix, 0xeaae16
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfad649
	jp_dri 8, 0x07, 0xF0, 0xE0

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
	cpw (xsp + 72), 0xC0
	jr z, DrawDesignBox_ColorsC0C1
	cpw (xsp + 72), 0xC1
	jr nz, DrawDesignBox_ColorsDefault

DrawDesignBox_ColorsC0C1:
	ldw (xsp + 4), 0xFF
	ldw (xsp + 6), 0xF8
	jr DrawDesignBox_ApplyColors

DrawDesignBox_ColorsDefault:
	ldw (xsp + 4), 0xF8
	ldw (xsp + 6), 0xFF

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
	cpw (xsp + 72), 0xC4
	jr z, DrawDesignBox_C4C5FirstPass
	cpw (xsp + 72), 0xC5
	jr nz, DrawDesignBox_C6C7Style

DrawDesignBox_C4C5FirstPass:
	ld xwa, (xsp + 10)
	or xwa, xwa
	jr nz, DrawDesignBox_C4C5Highlight
	ldw (xsp + 4), 0x7
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr nz, DrawDesignBox_C4C5SingleWidth
	ldw (xsp + 4), 0xFF

DrawDesignBox_C4C5SingleWidth:
	ldw (xsp + 6), 0x0
	jr ColorAttribute_SetupReturn

DrawDesignBox_C4C5Highlight:
	ldw (xsp + 4), 0xFF
	ldw (xsp + 6), 0xF8
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
	ldw (xsp + 4), 0xF8

DrawDesignBox_C6C7Shadow:
	ldw (xsp + 6), 0xFF

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
	cpw (xsp + 72), 0xA0
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
	cpw (xsp + 72), 0xB
	jrl z, DrawPartGroup_StyleB
	cpw (xsp + 72), 0xA
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
	cp wa, 0xF
	jr gt, DrawPartGroup_TableJump_DefaultCase

; DrawPartGroup dispatch by type
DrawPartGroup_DispatchByType:
	add wa, wa
	lda_24 xix, 0xeaadf6
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfadb3a
	jp_dri 8, 0x07, 0xF0, 0xE0

DrawPartGroup_TableJump_DefaultCase:
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldi_werp 0xFA, 3
	jrl DrawPartGroup_Loop

DrawPartGroup_Style8:
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldi_werp 0xFA, 7
	jrl DrawPartGroup_Loop

DrawPartGroup_Style9:
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	jrl DrawPartGroup_Loop

DrawPartGroup_StyleA:
	ldw iz, 0xC
	ldw (xsp + 8), 0xD
	ldw (xsp + 10), 0xE
	ldi_erpw 0xFA, 0x0F, 0x00
	jrl DrawPartGroup_Loop

DrawPartGroup_StyleB:
	ldw iz, 0x10
	ldw (xsp + 8), 0x11
	ldw (xsp + 10), 0x12
	ldi_erpw 0xFA, 0x13, 0x00
	jrl DrawPartGroup_Loop
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldi_werp 0xFA, 3
	ldw (xsp + 12), 0x1A
	jrl DrawPartGroup_WithAltFlag
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldi_werp 0xFA, 3
	ldw (xsp + 12), 0x15
	jrl DrawPartGroup_WithFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldi_werp 0xFA, 7
	ldw (xsp + 12), 0x1B
	jrl DrawPartGroup_WithAltFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldi_werp 0xFA, 7
	ldw (xsp + 12), 0x16
	jrl DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x1C
	jrl DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x17
	jrl DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x1D
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x18
	jrl DrawPartGroup_WithFlag
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldi_werp 0xFA, 3
	ldw (xsp + 12), 0x1E
	jr DrawPartGroup_WithAltFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldi_werp 0xFA, 7
	ldw (xsp + 12), 0x1F
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x20
	jr DrawPartGroup_WithAltFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x21

DrawPartGroup_WithAltFlag:
	ldw (xsp + 16), 0x1
	jr DrawPartGroup_Loop
	lds iz, 0
	ldw (xsp + 8), 0x1
	ldw (xsp + 10), 0x2
	ldi_werp 0xFA, 3
	ldw (xsp + 12), 0x22
	jr DrawPartGroup_WithFlag
	lds iz, 4
	ldw (xsp + 8), 0x5
	ldw (xsp + 10), 0x6
	ldi_werp 0xFA, 7
	ldw (xsp + 12), 0x23
	jr DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
	ldw (xsp + 12), 0x24
	jr DrawPartGroup_WithFlag
	ldw iz, 0x8
	ldw (xsp + 8), 0x9
	ldw (xsp + 10), 0xA
	ldi_erpw 0xFA, 0x0B, 0x00
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
	ldto_werp WA, 0xFA
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
	ldto_werp BC, 0xFA
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
	cpw (xsp + 72), 0xCA
	jr z, DrawPartGroup_StyleCA
	ldw iz, 0x28
	ldw (xsp + 8), 0x29
	ldw (xsp + 10), 0x2A
	ldi_erpw 0xFA, 0x2B, 0x00
	ldw (xsp + 4), 0xFF
	ldw (xsp + 6), 0xF8
	jr DrawPartGroup_DrawCAFrames

DrawPartGroup_StyleCA:
	ldw iz, 0x30
	ldw (xsp + 8), 0x31
	ldw (xsp + 10), 0x32
	ldi_erpw 0xFA, 0x33, 0x00
	ldw (xsp + 6), 0xFF
	ldw (xsp + 4), 0xF8

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
	ldto_werp WA, 0xFA
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
	ldto_werp BC, 0xFA
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
	ldw de, 0xFF
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
	ldw de, 0xFF
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
	ldw de, 0xF8
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
	ldw de, 0xF8
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
	ldw de, 0xFF
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
	ldw de, 0xFF
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	ldw de, 0xF8
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
	ldw de, 0xF8
	jrl DrawFunc_DrawLineAndReturn
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ldw wa, 0x2A
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	ldw wa, 0x2B
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
	ldw bc, 0x2B
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
	ldw bc, 0x2A
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
	ldw de, 0xFF
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
	ldw de, 0xFF
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
	ldw de, 0xF8
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
	ldw de, 0xF8
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
	ldw de, 0xFF
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
	ldw de, 0xFF
	calr DrawLine_Impl
	lda xwa, (xsp + 50)
	ld xbc, (xsp + 74)
	lda xde, (xbc + 4)
	ld bc, (xde)
	ld (xwa), bc
	lda xbc, (xsp + 46)
	ld de, (xde)
	ld (xbc), de
	ldw de, 0xF8
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
	ldw de, 0xF8
	jrl DrawFunc_DrawLineAndReturn
	ldw wa, 0x2C
	ld xbc, xhl
	ld xde, xiy
	call GetFrameSPSize
	lda xbc, (xsp + 34)
	lda xde, (xsp + 26)
	ldw wa, 0x2D
	call GetFrameSPSize
	lda xbc, (xsp + 32)
	lda xde, (xsp + 24)
	ldw wa, 0x2E
	call GetFrameSPSize
	lda xbc, (xsp + 30)
	lda xde, (xsp + 22)
	ldw wa, 0x2F
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
	ldw bc, 0x2C
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
	ldw bc, 0x2F
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
	ldw bc, 0x2D
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
	ldw bc, 0x2E
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
	ldw de, 0xFF
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
	ldw de, 0xF8
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
	ldw de, 0xFF
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
	ldw de, 0xF8

DrawFunc_DrawLineAndReturn:
	calr DrawLine_Impl

DrawFunc_Epilogue74:
	pop xiz
	lda xsp, (xsp + 74)
	ret

Gfx_ImageDecodeByteData:
	dec	4, xsp
	push	xiz
	ld32_24	xbc, 197714
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
	lda_24	xde, 277504
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
	pushw 0x9600
	pushw 0x0
	ld xwa, 0x56800
	push xwa
	call Memset
	pushw 0x9600
	pushw 0x0
	ld xwa, 0x5FE00
	push xwa
	call Memset
	pushw 0x400
	pushw 0x0
	ld xwa, 0x69400
	push xwa
	call Memset
	lda xsp, (xsp + 24)
	jrl Flash_SaveSplashScreen

Gfx_LoadSplashBMP:
	st_dri3b L, 0xFD, 0xAA, 0xFB
	pushw iz
	st_dri3b W, 0xFD, 0x4A, 0x04
	ld xbc, 0xE
	call FileIO_ReadBlock
	ld iz, hl
	cp iz, 0xE
	jrl nz, SplashScreen_Return
	pushw 0x2
	pushw 0xEA
	pushw 0xAE48
	st_dri3b W, 0xFD, 0x50, 0x04
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, FileIO_ControllerValidationFailed
	st_dri3b W, 0xFD, 0x22, 0x04
	ld xbc, 0x28
	call FileIO_ReadBlock
	ld iz, hl
	cp iz, 0x28
	jrl nz, SplashScreen_Return
	st_dri3b A, 0xFD, 0x22, 0x04
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
	ld_sril XWA, (xsp + 0x0454)
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
	ld xde, 0x69400
	ld xbc, 0x69400
	ld xhl, 0x69800

SplashBMP_ClearPalette:
	ld xwa, 0xFF000000
	st_dpil XWA, 0xE6
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
	ldfr_berp A, 0xF0
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
	st_dpil XIX, 0xEA
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xbc, (xsp + 6)
	cp xbc, (xsp + 30)
	jr c, SplashBMP_DecodePalette

SplashBMP_ReadInfoHeader:
	st_dri3b A, 0xFD, 0x22, 0x04
	ld xwa, (xbc + 4)
	ld (xsp + 14), xwa
	ld xwa, (xbc + 8)
	ld (xsp + 2), xwa
	ld xwa, 0x8
	mrdw3 0x99, 0x0E, 0x50
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
	cp xwa, 0xF0
	jr le, SplashBMP_PrepareRowBuffer
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xwa, (xsp + 2)
	sub xwa, 0xF0
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
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xwa, (xsp + 2)
	sub xwa, 0xF0
	cp (xsp + 6), xwa
	jr lt, SplashBMP_SkipExcessRows

SplashBMP_ClampHeight:
	ld xwa, 0xF0
	ld (xsp + 2), xwa

SplashBMP_PrepareRowBuffer:
	ld xwa, 0x140
	ld (xsp + 30), xwa
	ld xbc, (xsp + 2)
	dec 1, xbc
	ld xwa, (xsp + 30)
	call Math_MultiplyAccumulate
	ld (xsp + 30), xhl
	add xhl, 0x56800
	ld (xsp + 22), xhl
	lds32 xwa, 0
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
	ld_sriw DE, (xsp + 0x0430)
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
	lds32 xwa, 0
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
	lds32 xwa, 1
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
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xwa, (xsp + 6)
	cp xwa, (xsp + 2)
	jrl lt, SplashBMP_ReadRowLoop

SplashBMP_PadRows:
	ld xbc, (xsp + 2)
	cp xbc, 0xF0
	jr ge, SplashBMP_Finish
	ld xwa, 0x140
	add (xsp + 30), xwa
	ld xwa, 0x56800
	ld (xsp + 26), xwa
	ld xwa, (xsp + 30)
	add xwa, 0x56800
	ld (xsp + 22), xwa
	ld (xsp + 6), xbc
	cp xbc, 0xF0
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
	lds32 xwa, 1
	add (xsp + 6), xwa
	ld xwa, (xsp + 6)
	cp xwa, 0xF0
	jr lt, SplashBMP_PadCopyLoop

SplashBMP_Finish:
	calr Gfx_DecodeImageToBuffer
	calr Flash_SaveSplashScreen
	lds wa, 2
	calr ChangePalette
	lds hl, 1

SplashBMP_Return:
	popw iz
	st_dri3b L, 0xFD, 0x56, 0x04
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
	mrdw3 0x9F, 0x16, 0x56
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
	lds32 xbc, 0
	ld xwa, (xsp + 18)
	cp xwa, 0x0
	jr le, SplashData_4bppFree

SplashData_4bppLoop:
	ld xde, xbc
	add xde, (xsp + 28)
	ld xix, (xsp + 10)
	ld a, (xix)
	and a, 0xF0
	srl a, 4
	ld (xde), a
	ld xhl, xbc
	inc 1, xhl
	add xhl, (xsp + 28)
	ld_spib E, 0xF0
	ld (xsp + 10), xix
	and e, 0xF
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
	lds32 xbc, 0
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
	ld_spib E, 0xF0
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
	st_dri3b L, 0xFD, 0xD4, 0xFB
	push xiz
	st_dri3b A, 0xFD, 0x30, 0x02
	ld (xsp + 32), xbc
	ld xwa, (xsp + 32)
	st_dri3b W, 0xE1, 0x00, 0x02
	ld (xsp + 40), xwa

ImageDecode_ClearPaletteLoop:
	stiw_dpi 0xE5, 0x00, 0x00
	cp xbc, xwa
	jr c, ImageDecode_ClearPaletteLoop
	ld xhl, 0x56800
	lds ix, 0

ImageDecode_RowLoop:
	lds iy, 0

ImageDecode_PixelLoop:
	ld_spib C, 0xEC
	extz bc
	add bc, bc
	ld xwa, (xsp + 32)
	inc_sriw 1, 0x07, 0xE0, 0xE4
	inc 1, iy
	cp iy, 0x140
	jr lt, ImageDecode_PixelLoop
	inc 1, ix
	cp ix, 0xF0
	jr lt, ImageDecode_RowLoop
	st_dri3b W, 0xFD, 0x30, 0x01
	ld (xsp + 28), xwa
	ldb c, 0x0
	ld xde, (xsp + 28)
	ld xwa, xde
	st_dri3b W, 0xE1, 0x00, 0x01
	ld (xsp + 44), xwa

ImageDecode_SecondPassSetup:
	lda_dpi XHL, 0xE8
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
	ld xwa, xbc
	ld xbc, 0xF4240
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, 0x13D620
	call Math_DivideSigned32
	ld bc, hl
	exts xbc
	ld xwa, xbc
	cp xbc, 0xA
	jr z, PaletteReduce_SpecialCase
	cp xwa, 0x9
	jr z, PaletteReduce_SpecialCase
	or xwa, xwa
	jr nz, PaletteReduce_StartSortPass
	lds32 xbc, 1
	jr PaletteReduce_StartSortPass

PaletteReduce_SpecialCase:
	ld xbc, 0xB

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
	ld_spib A, 0xE8
	ldfr_berp A, 0xF0
	extz ix
	ld b, c
	ld xwa, (xsp + 32)
	lda_dri3 XDE, 0x07, 0xE0, 0xF0
	inc 1, c
	cp xde, xhl
	jr c, PaletteReduce_RemapPixels
	cpw (xsp + 18), 0xC0
	jrl le, ImageDecode_CopyPaletteToDAC
	ld xwa, 0xC0
	ld (xsp + 4), xwa
	ld wa, (xsp + 18)
	exts xwa
	ld (xsp + 36), xwa
	cp xwa, 0xC0
	jrl le, ImageDecode_CopyPaletteToDAC

PaletteReduce_HighColorReduce:
	ld xwa, 0x7FFFFFFF
	ld (xsp + 12), xwa
	lds32 xwa, 0
	ld (xsp + 16), xwa
	ld (xsp + 8), xwa

PaletteReduce_FindClosest:
	ld xwa, (xsp + 8)
	sll xwa, 2
	add xwa, 0x69400
	ld xwa, (xwa)
	ld (xsp + 44), xwa
	and xwa, 0xFF00
	srl xwa, 8
	ld xde, xwa
	ld xwa, (xsp + 4)
	sll xwa, 2
	add xwa, 0x69400
	ld xwa, (xwa)
	ld (xsp + 40), xwa
	and xwa, 0xFF00
	srl xwa, 8
	ld xbc, xwa
	sub xbc, xde
	ld xwa, xbc
	call Math_MultiplyAccumulate
	ld (xsp + 24), xhl
	ld xde, (xsp + 44)
	and xde, 0xFF
	ld xbc, (xsp + 40)
	and xbc, 0xFF
	sub xbc, xde
	ld xwa, xbc
	call Math_MultiplyAccumulate
	ld (xsp + 20), xhl
	ld xwa, (xsp + 24)
	add (xsp + 20), xwa
	ld xwa, (xsp + 44)
	and xwa, 0xFF0000
	srl xwa, 0
	ld xbc, (xsp + 40)
	and xbc, 0xFF0000
	srl xbc, 0
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
	lds32 xwa, 1
	add (xsp + 8), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0xC0
	jrl lt, PaletteReduce_FindClosest
	ld xwa, (xsp + 4)
	add xwa, (xsp + 28)
	ld c, (xwa)
	extz bc
	ld xwa, (xsp + 16)
	ld e, a
	ld xwa, (xsp + 32)
	lda_dri3 XIY, 0x07, 0xE0, 0xE4
	lds32 xwa, 1
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 36)
	jrl lt, PaletteReduce_HighColorReduce

ImageDecode_CopyPaletteToDAC:
	ld xde, 0x696FC
	ld xbc, 0x6977C
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
	cp xwa, 0xC0
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
	ld_srib3 A, 0x07, 0xE0, 0xE8
	ld (xbc), a
	cp (xbc), 0xC0
	jr nc, ImageDecode_PixelHighBank
	addmi8 (xhl), 0x20
	jr ImageDecode_PixelNext

ImageDecode_PixelHighBank:
	cp (xhl), 0xE0
	jr nc, ImageDecode_PixelNext
	ld (xhl), 0x0

ImageDecode_PixelNext:
	inc 1, xhl
	inc 1, xbc
	inc 1, iy
	cp iy, 0x140
	jr lt, ImageDecode_ProcessPixels
	inc 1, ix
	cp ix, 0xF0
	jr lt, ImageDecode_ProcessRowsOuter
	pop xiz
	st_dri3b L, 0xFD, 0x2C, 0x04
	ret

Flash_SaveSplashScreen:
	lds wa, 1
	ld xbc, 0x56800
	ld xde, 0x3C0000
	call Flash_EraseSectorAndWrite
	ld xwa, 0x3D0000
	push xwa
	lds wa, 1
	ld xbc, 0x66800
	ldw de, 0x3000
	call FlashWrite_Entry
	ret

CaptureLcd:
	st_dri3b L, 0xFD, 0xBA, 0xFB
	pushw iz
	st_dri3b W, 0xFD, 0x3A, 0x04
	pushw 0xEA
	pushw 0xAE4C
	push xwa
	call Strcpy
	st_dri3b A, 0xFD, 0x42, 0x04
	ld xwa, 0x13036
	ld (xbc + 2), xwa
	ldw (xbc + 6), 0x0
	ldw (xbc + 8), 0x0
	ld xwa, 0x436
	ld (xbc + 10), xwa
	st_dri3b A, 0xFD, 0x1A, 0x04
	ld xwa, 0x28
	ld (xbc), xwa
	ld xwa, 0x140
	ld (xbc + 4), xwa
	ld xwa, 0xF0
	ld (xbc + 8), xwa
	ldw (xbc + 12), 0x1
	ldw (xbc + 14), 0x8
	lds32 xwa, 0
	ld (xbc + 16), xwa
	ld xwa, 0x12C00
	ld (xbc + 20), xwa
	lds32 xwa, 0
	ld (xbc + 24), xwa
	ld (xbc + 28), xwa
	ld xwa, 0x100
	ld (xbc + 32), xwa
	ld (xbc + 36), xwa
	ld32_24 xwa, 0x03044a
	push xwa
	pushw 0xEA
	pushw 0xAE50
	lda xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 20)
	lds32 xwa, 1
	addm32_24 0x03044a, xwa
	call GetDiskSizeInfo
	call GetEncodedFileSizeData
	lda xwa, (xsp + 2)
	ld xbc, 0xEAAE5E
	call FileIO_OpenWithMode
	cps hl, 0
	jrl nz, CaptureLcd_WriteFailed
	st_dri3b W, 0xFD, 0x3A, 0x04
	ld xbc, 0xE
	call FileIO_WriteByte_Impl
	cp xhl, 0xE
	jrl nz, FileIO_ClosePath
	st_dri3b W, 0xFD, 0x12, 0x04
	ld xbc, 0x28
	call FileIO_WriteByte_Impl
	cp xhl, 0x28
	jrl nz, FileIO_ClosePath
	lds iz, 0
	ld32_24 xwa, 0x03ef94
	or xwa, xwa
	jr z, CaptureLcd_WritePaletteNoOr94

CaptureLcd_WritePaletteOr94:
	ld wa, iz
	call Table_LookupDword
	ld de, iz
	sla de, 2
	lda xwa, (xsp + 18)
	ld xbc, xhl
	and xbc, 0xFF0000	; is this a mask for Red?
	srl xbc, 0
	lda_dri3 XHL, 0x07, 0xE0, 0xE8
	ld bc, iz
	sla bc, 2
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld xbc, xhl
	and xbc, 0xFF00	; is this a mask for Green?
	srl xbc, 8
	ld (xwa + 1), c
	and xhl, 0xFF	; is this a mask for Blue?
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
	and xbc, 0xFF0000	; is this a mask for Red?
	srl xbc, 0
	lda_dri3 XHL, 0x07, 0xE0, 0xE8
	ld bc, iz
	sla bc, 2
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld xbc, xhl
	and xbc, 0xFF00	; is this a mask for Green?
	srl xbc, 8
	ld (xwa + 1), c
	and xhl, 0xFF	; is this a mask for Blue?
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
	ldw iz, 0xEF

CaptureLcd_WriteRowLoop:
	ld wa, iz
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	lda_24 xwa, 0x043c00
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
	st_dri3b L, 0xFD, 0x46, 0x04
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
	lda_24 xbc, 0xfaf232
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
	st16_24 0x03ef9c, xwa
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	add xbc, xbc
	ld xwa, 0xEAAE62
	add xwa, xbc
	ld xwa, (xwa)
	st32_24 0x03ef98, xwa
	st32_24 0x030452, xwa
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
	lda_24 xbc, 0xfaf282
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
	ld16_24 xwa, 0x03ef9c
	cps wa, 2
	jr z, WallPalette_Done
	cps wa, 0
	jr nz, WallPalette_SetupLoop
	inc 1, iz

WallPalette_SetupLoop:
	ldi_erpw 0xFA, 0xE0, 0x00

WallPalette_IterateEntries:
	ldto_werp BC, 0xFA
	sub bc, 0xE0
	ld wa, iz
	call GetWallPaletteRGB
	ld xbc, xhl
	ldto_werp WA, 0xFA
	call SetPaletteRGB
	inc1_werp 0xFA
	cp_erpw 0xFA, 0xF0, 0x00
	jr c, WallPalette_IterateEntries
	sti16_24 0x030462, 0x0001

WallPalette_Done:
	pop xiz
	ret

; =============================================================================
; ChangePalette - Switch VGA DAC palette
;
; Loads a new 256-color palette from the palette table at 0xEAAE66.
; Each palette entry in the table is 10 bytes. The function iterates
; over all 256 DAC entries, loading RGB values from the selected palette
; and writing them to VGA DAC registers.
;
; Input:
;   WA = palette index (low byte selects palette from table)
;
; Key addresses:
;   0xEAAE66 - Palette table base (10 bytes per palette entry)
;   0x03EF94 - Current palette data pointer (cached)
;   0x03EF9E - Current palette index (cached)
;   0x030460 - Palette update flag (set to 1 to trigger VRAM update)
;
; The palette loop at UIRender_IterateCallbacks iterates 0x20..0xE0 (palette entries),
; looking up each entry's RGB values via a secondary table at 0x03EF14.
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
	lda_24 xbc, 0xfaf2ee
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
	lda_24 xwa, 0xeaae66
	add xwa, xbc
	ld xwa, (xwa)
	st32_24 0x03ef94, xwa
	ldi_erpw 0xFA, 0x20, 0x00

UIRender_IterateCallbacks:
	ldto_werp WA, 0xFA
	ldto_werp BC, 0xFA
	extz xbc
	sll xbc, 2
	addda32_24 xbc, 257940
	ld xbc, (xbc)
	call SetPaletteRGB
	inc1_werp 0xFA
	cp_erpw 0xFA, 0xE0, 0x00
	jr c, UIRender_IterateCallbacks
	st16_24 0x03ef9e, xiz
	sti16_24 0x030460, 0x0001
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
; The KN5000 uses 16 palette banks of 16 colors each (0x00-0x0F, 0x10-0x1F,
; ..., 0xE0-0xEF). This function:
;
; 1. Saves OFFSCREEN_BUFFER_1 (0x43C00) -> temp buffer at 0x56800 (full screen)
; 2. Saves next 38400 words -> temp at 0x5FE00
; 3. Iterates over all 76800 pixels (320√ó240):
;    - If pixel >= 0xE0: subtract 0x90 (wrap to lower bank)
;    - If pixel < 0xE0: add 0x10 (shift to next higher bank)
; 4. Saves modified buffer -> 0x69800 and 0x72E00
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
	lda_24 xbc, 0xfaf35e
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr __jrt_nop_FAF360
__jrt_nop_FAF360:

PaletteBankRotate_Impl:
	push xiz
	lda_24 xwa, 0x043c00
	ld xiz, xwa
	pushw 0x9600
	push xwa
	ld xwa, 0x56800
	push xwa
	call Mem_Copy
	add xiz, 0x9600
	pushw 0x9600
	push xiz
	ld xwa, 0x5FE00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	lda_24 xwa, 0x043c00
	ld xbc, xwa
	lds de, 0

PaletteBankRotate_RowLoop:
	lds hl, 0

PaletteBankRotate_ColLoop:
	cp (xbc), 0xE0
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
	cp de, 0xF0
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
	ld xwa, 0x72E00
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
	cps hl, 0
	jr z, ClipBlit_Replace_Deferred
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ClipBlit_Replace_Impl
	jr t, ClipBlit_Replace_Return
ClipBlit_Replace_Deferred:
	ldw wa, 0x000A
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24	xbc, 16446494
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
	ldw (xsp + 4), 0x013F
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
	cp wa, 0x00F0
	jr lt, ClipBlit_Replace_CalcVRAMAddr
	ldw (xsp + 6), 0x00EF
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
	lda_24	xwa, 277504
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
	ld xwa, (xsp + 28)
	ld wa, (xwa + 2)
	exts xwa
	ld xbc, (xsp + 8)
	sub xbc, xwa
	pushw bc
	call Math_AbsInt16
	add hl, hl
	lda_24	xwa, 15380116
	ld_rrw	de, xwa, hl
	ldw bc, 0x001E
	sub bc, de
	ld xwa, (xsp + 18)
	lda_rr	xhl, xwa, bc
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
	lds32	xwa, 1
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
	ldw wa, 0x000A
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24	xbc, 16446848
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
	ldw (xsp + 4), 0x013F
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
	cp wa, 0x00F0
	jr lt, ClipBlit_Direct_CalcVRAMAddr
	ldw (xsp + 6), 0x00EF
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
	lda_24	xwa, 277504
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
	lds32	xwa, 1
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
	ld8_24 a, 0x03efa8
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jr z, ColorBlit_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit_Impl
	jr ColorBlit_Return

ColorBlit_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaf6cd
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld8_24 c, 0x03efa8
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
	st8_24	257962, c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
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
	ldw (xde), 0x13F

ColorBlit_ClampRight:
	lda xde, (xwa + 6)
	ld (xsp + 4), xde
	cpw (xde), 0xF0
	jr lt, ColorBlit_ClampBottom
	ld xde, (xsp + 4)
	ldw (xde), 0xEF

ColorBlit_ClampBottom:
	ld ix, (xhl)
	cp bc, 0xF7
	jrl z, ColorBlit_PopReturn
	ld8_24 e, 0x03efaa
	cps e, 2
	jrl z, ColorBlit_Mode2_Entry
	cps e, 1
	jrl z, ColorBlit_Mode1_Entry
	cps e, 0
	jrl nz, ColorBlit_Epilogue
	ld hl, ix
	cp bc, 0xF5
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
	lda_24 xiz, 0x043c00
	add xiz, xde
	ld ix, (xwa)
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr gt, ColorBlit_Mode0_NextRow

ColorBlit_Mode0_PixelLoop:
	andmi8 (xiz), 0x60
	ld de, bc
	and de, 0x9F
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
	lda_24 xiy, 0x043c00
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	addda32_24 xiz, 197714
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit_ModeF5_NextRow

ColorBlit_ModeF5_PixelLoop:
	andmi8 (xiy), 0x60
	ld c, (xiz)
	and c, 0x9F
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
	lda_24 xde, 0x043c00
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
	lda_24 xde, 0x043c00
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
	ld8_24 a, 0x03efa8
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jr z, ColorBlit2_Return
	ld xwa, xiz
	ld bc, (xsp + 4)
	calr ColorBlit2_Impl
	jr ColorBlit2_Return

ColorBlit2_Deferred:
	ldw wa, 0x10
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfaf919
	ld (xwa), xbc
	ld xiy, xiz
	lda xix, (xwa + 4)
	lds bc, 4
	ldirw
	ld bc, (xsp + 4)
	ld (xwa + 12), bc
	ld8_24 c, 0x03efa8
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
	st8_24	257962, c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
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
	ldw (xde), 0x13F

ColorBlit2_ClampRight:
	lda xde, (xwa + 6)
	ld (xsp + 4), xde
	cpw (xde), 0xF0
	jr lt, ColorBlit2_ClampBottom
	ld xde, (xsp + 4)
	ldw (xde), 0xEF

ColorBlit2_ClampBottom:
	ld ix, (xhl)
	cp bc, 0xF7
	jrl z, ColorBlit2_PopReturn
	ld8_24 e, 0x03efaa
	cps e, 2
	jrl z, ColorBlit2_Mode2_Entry
	cps e, 1
	jrl z, ColorBlit2_Mode1_Entry
	cps e, 0
	jrl nz, ColorBlit2_Epilogue
	ld hl, ix
	cp bc, 0xF5
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
	lda_24 xiz, 0x043c00
	add xiz, xde
	ld ix, (xwa)
	ld xde, (xsp + 8)
	cp ix, (xde)
	jr gt, ColorBlit2_Mode0_NextRow

ColorBlit2_Mode0_PixelLoop:
	andmi8 (xiz), 0x60
	ld de, bc
	and de, 0x9F
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
	lda_24 xiy, 0x043c00
	add xiy, xbc
	ld bc, (xwa)
	exts xbc
	ld xiz, xde
	add xiz, xbc
	addda32_24 xiz, 197714
	ld ix, (xwa)
	ld xbc, (xsp + 8)
	cp ix, (xbc)
	jr gt, ColorBlit2_ModeF5_NextRow

ColorBlit2_ModeF5_PixelLoop:
	andmi8 (xiy), 0x60
	ld c, (xiz)
	and c, 0x9F
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
	lda_24 xiy, 0x043c00
	add xiy, xde
	ld bc, (xwa)
	st_dri3b E, 0x07, 0xF4, 0xE4
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
	cp bc, 0xEF
	jr nz, ColorBlit2_Mode2_ClippedEntry
	ld xbc, (xsp + 8)
	ld bc, (xbc)
	sub bc, (xwa)
	cp bc, 0x13F
	jr nz, ColorBlit2_Mode2_ClippedEntry
	lda_24 xbc, 0x043c00
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
	cp xde, 0x12C00
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
	lda_24 xde, 0x043c00
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
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	43484
	cps	hl, 0
	jr	z, 32
	ld8_24	a, 257960
	st8_24	257962, a
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	jr	z, 60
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	87
	jr	47
	ldw	wa, 20
	calr	43204
	ld	xwa, xhl
	lda_24	xbc, 16448429
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	lds	bc, 4
	.byte 0x95
	scf
	ld	xbc, (xsp+6)
	ld	(xwa+12), xbc
	ld	bc, (xsp+4)
	ld	(xwa+16), bc
	ld8_24	c, 257960
	ld	(xwa+18), c
	calr	42947
	pop	xiz
	inc	6, xsp
	ret
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	xhl, (xbc+12)
	ld	de, (xbc+16)
	ld	c, (xbc+18)
	st8_24	257962, c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	ret	z
	ld	xbc, xhl
	calr	1
	ret
	lda	xsp, (xsp-30)
	pushw	iz
	ld	(xsp+22), de
	ld	(xsp+24), xbc
	ld	(xsp+28), xwa
	ld8_24	a, 257962
	cps	a, 2
	jrl	z, 560
	cps	a, 1
	jrl	z, 381
	cps	a, 0
	jrl	nz, 722
	.byte 0xbf
	ei	2
	nop
	nop
	jrl	351
	.byte 0xbf
	ldio	2, 0
	nop
	jrl	321
	lda	xwa, (xsp+18)
	ld	(xsp+10), xwa
	ld	xwa, (xsp+28)
	ld	bc, (xwa)
	.byte 0x9f, 0x06
	sub	(xbc), l
	ldwio	32, 57845
	.byte 0x51
	ld	(xsp+14), xwa
	ld	bc, (xde)
	.byte 0x9f
	ldio	129, 175
	ret
	ldb	w, 176
	.byte 0x51
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
	ld32_24	xhl, 197714
	ld	xwa, (xsp+14)
	ld	wa, (xwa)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	lda_24	xbc, 277504
	.byte 0xbf
	push_sr
	inc	6, l
	jr	nov, -81
	ldwio	37, 5791
	ldb	h, 175
	ldwio	32, 8336
	exts	xwa
	add	xwa, xde
	ld	xix, xbc
	add	xix, xwa
	cp	iz, 245
	jr	z, 31
	.byte 0x84
	push	xix
	jr	f, -34
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xix), a
	ld	bc, iz
	and	bc, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, bc
	jr	nz, 50
	jrl	159
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
	.byte 0x84
	push	xix
	jr	f, -125
	ldb	a, 201
	.byte 0xcc
	add	(xsp-124), bc
	ld	c, (xhl)
	and	c, 128
	ld	a, (xix)
	and	a, 128
	cp	a, c
	jr	z, 112
	.byte 0x84
	push	xiy
	jr	f, 104
	jr	ugt, -81
	ldwio	37, 41682
	.byte 0xef
	pop_sr
	ldb	h, 175
	ldwio	32, 8336
	exts	xwa
	add	xwa, xde
	ld	xix, xbc
	add	xix, xwa
	cp	iz, 245
	jr	z, 30
	.byte 0x84
	push	xix
	jr	f, -34
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xix), a
	ld	bc, iz
	and	bc, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, bc
	jr	nz, 49
	jr	50
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
	.byte 0x84
	push	xix
	jr	f, -125
	ldb	a, 201
	.byte 0xcc
	add	(xsp-124), bc
	ld	c, (xhl)
	and	c, 128
	ld	a, (xix)
	and	a, 128
	cp	a, c
	jr	z, 3
	.byte 0x84
	push	xiy
	jr	f, -113
	push_sr
	ldb	a, 143
	push_sr
	.byte 0x89
	ld	xwa, (xsp+10)
	incm	1, (xwa)
	incm8	1, (xsp+4)
	.byte 0x8f, 0x04
	push	xsp
	ldio	119, 244
	swi	6
	lds32	xwa, 1
	add	(xsp+24), xwa
	incm	1, (xsp+8)
	ld	xwa, (xsp+28)
	lda	xde, (xwa+2)
	ld	bc, (xde)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, -340
	incm	8, (xsp+6)
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	.byte 0x90, 0xa1
	cp	(xsp+6), bc
	jrl	c, -365
	jrl	346
	.byte 0xbf
	ei	2
	nop
	nop
	jrl	149
	.byte 0xbf
	ldio	2, 0
	nop
	jr	120
	lda	xde, (xsp+18)
	ld	xwa, (xsp+28)
	ld	wa, (xwa)
	.byte 0x9f, 0x06, 0x80
	ld	(xde), wa
	lda	xhl, (xde+2)
	ld	wa, (xix)
	.byte 0x9f
	ldio	128, 179
	.byte 0x50
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
	lda_24	xix, 277504
	ld	wa, (xhl)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	.byte 0xbf
	push_sr
	inc	6, l
	rcf
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	ld	xbc, xix
	add	xbc, xwa
	.byte 0xb1
	dec	6, l
	push_a
	jr	14
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	ld	xbc, xix
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xbd
	jr	2
	.byte 0xb1, 0xb5
	ld	a, (xsp+2)
	add	(xsp+2), a
	incm	1, (xde)
	incm8	1, (xsp+4)
	.byte 0x8f, 0x04
	push	xsp
	ldio	103, 179
	lds32	xwa, 1
	add	(xsp+24), xwa
	incm	1, (xsp+8)
	ld	xwa, (xsp+28)
	lda	xix, (xwa+2)
	ld	bc, (xix)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, -139
	incm	8, (xsp+6)
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	.byte 0x90, 0xa1
	cp	(xsp+6), bc
	jrl	c, -163
	jrl	172
	.byte 0xbf
	ei	2
	nop
	nop
	jrl	150
	.byte 0xbf
	ldio	2, 0
	nop
	jr	121
	lda	xde, (xsp+18)
	ld	xwa, (xsp+28)
	ld	wa, (xwa)
	.byte 0x9f, 0x06, 0x80
	ld	(xde), wa
	lda	xhl, (xde+2)
	ld	wa, (xix)
	.byte 0x9f
	ldio	128, 179
	.byte 0x50
	ld	xwa, (xsp+24)
	ld	a, (xwa)
	ld	(xsp+2), a
	ld	(xsp+4), 0
	ld	wa, (xhl)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	.byte 0xbf
	push_sr
	inc	6, l
	zcf
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	dec	6, l
	.byte 0x17
	jr	17
	ld	wa, (xde)
	exts	xwa
	add	xwa, xbc
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xbe
	jr	2
	.byte 0xb1, 0xb6
	ld	a, (xsp+2)
	add	(xsp+2), a
	incm	1, (xde)
	incm8	1, (xsp+4)
	.byte 0x8f, 0x04
	push	xsp
	ldio	103, 178
	lds32	xwa, 1
	add	(xsp+24), xwa
	incm	1, (xsp+8)
	ld	xwa, (xsp+28)
	lda	xix, (xwa+2)
	ld	bc, (xix)
	ld	wa, (xwa+6)
	sub	wa, bc
	cp	(xsp+8), wa
	jrl	c, -140
	incm	8, (xsp+6)
	ld	xwa, (xsp+28)
	ld	bc, (xwa+4)
	.byte 0x90, 0xa1
	cp	(xsp+6), bc
	jrl	c, -164
	ld	xwa, (xsp+28)
	calr	43162
	popw	iz
	lda	xsp, (xsp+30)
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	42583
	cps	hl, 0
	jr	z, 32
	ld8_24	a, 257960
	st8_24	257962, a
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	jr	z, 66
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	93
	jr	53
	ldw	wa, 16
	calr	42303
	ld	xwa, xhl
	lda_24	xbc, 16449336
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	xbc, (xsp+6)
	ld	xiy, xbc
	lda	xix, (xwa+8)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld8_24	c, 257960
	ld	(xwa+14), c
	calr	42040
	pop	xiz
	inc	6, xsp
	ret
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	lda	xhl, (xbc+8)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	st8_24	257962, c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	ret	z
	ld	xbc, xhl
	calr	1
	ret
	lda	xsp, (xsp-72)
	push	xiz
	ld	(xsp+66), de
	ld	(xsp+68), xbc
	ld	(xsp+72), xwa
	ld	xwa, (xsp+72)
	calr	53867
	cps	hl, 0
	jrl	z, 1855
	ld	xwa, (xsp+68)
	calr	53856
	cps	hl, 0
	jrl	z, 1844
	ld	xde, 4294967295
	ld	xwa, (xsp+68)
	ld	bc, (xwa)
	ld	xwa, (xsp+72)
	.byte 0x90, 0xf1
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+12), xde
	ld	xde, 4294967295
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
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, 12
	ld	xwa, (xsp+68)
	ld	de, (xwa)
	ld	xwa, (xsp+72)
	.byte 0x90, 0xa2
	jr	10
	ld	xwa, (xsp+72)
	ld	de, (xwa)
	ld	xwa, (xsp+68)
	.byte 0x90
	or	(xde), xde
	zcf
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, 6
	sub	bc, hl
	ld	hl, bc
	jr	2
	sub	hl, bc
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 8
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, 1705
	ld	xwa, (xsp+72)
	ld	xiy, xwa
	lda	xix, (xsp+62)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld8_24	a, 257962
	ld	(xsp+20), a
	lda_24	xwa, 277504
	ld	(xsp+38), xwa
	ld	(xsp+30), xwa
	ld	xwa, (xsp+8)
	sla	xwa, 0
	ld	xbc, (xsp+4)
	call	16714766
	ld	(xsp+34), xhl
	lda	xwa, (xsp+62)
	ld	(xsp+42), xwa
	ld	xwa, (xsp+4)
	sla	xwa, 0
	ld	xbc, (xsp+8)
	call	16714766
	ld	xix, (xsp+42)
	lda	xwa, (xix+2)
	ld	(xsp+46), xwa
	ld	wa, (xwa)
	exts	xwa
	sla	xwa, 0
	ld	(xsp+50), xwa
	ld	xwa, 32768
	add	(xsp+50), xwa
	.byte 0x8f
	push_a
	push	xsp
	push_sr
	jrl	z, 1199
	.byte 0x8f
	push_a
	push	xsp
	.byte 0x01
	jrl	z, 801
	.byte 0x8f
	push_a
	push	xsp
	nop
	jrl	nz, 1554
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jrl	nz, 189
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
	.byte 0x9f
	ld	xde, 1711338815
	ld	xsp, 145729769
	ldb	w, 232
	.byte 0xcf
	nop
	nop
	nop
	nop
	jrl	lt, 1494
	.byte 0x83
	push	xix
	jr	f, -97
	ld	xde, 2681002016
	nop
	add	(xhl), a
	ld	de, (xsp+66)
	and	de, 128
	ld	a, (xhl)
	and	a, 128
	extz	wa
	cp	wa, de
	jr	z, 3
	.byte 0x83
	push	xiy
	jr	f, -81
	rcf
	ldb	w, 232
	.byte 0xec
	push_sr
	.byte 0xaf
	rcf
	or	(xwa), w
	.byte 0xec, 0x06
	add	xhl, xwa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	scc8	t, b
	.byte 0x9d
	halt
	ld	wa, (xde)
	exts	xwa
	ld	xix, xbc
	add	xix, xwa
	addda32_24	xix, 197714
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 1410
	.byte 0x83
	push	xix
	jr	f, -124
	ldb	a, 201
	.byte 0xcc
	add	(xsp-125), bc
	ld	e, (xix)
	and	e, 128
	ld	a, (xhl)
	and	a, 128
	cp	a, e
	jr	z, 3
	.byte 0x83
	push	xiy
	jr	f, -81
	rcf
	ldb	w, 232
	.byte 0xec
	push_sr
	.byte 0xaf
	rcf
	or	(xwa), w
	.byte 0xec, 0x06
	add	xhl, xwa
	add	xix, xwa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	scc8	t, h
	popw	iy
	halt
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	nz, 171
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
	.byte 0x9f
	ld	xde, 1711338815
	push	xix
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 1294
	.byte 0x83
	push	xix
	jr	f, -97
	ld	xde, 2681002016
	nop
	add	(xhl), a
	ld	de, (xsp+66)
	and	de, 128
	ld	a, (xhl)
	and	a, 128
	extz	wa
	cp	wa, de
	jr	z, 3
	.byte 0x83
	push	xiy
	jr	f, -81
	incf
	or	(xhl), a
	jr	lt, -81
	.byte 0x04, 0xf1
	jr	le, -43
	jrl	1248
	ld	wa, (xde)
	exts	xwa
	ld	xix, xbc
	add	xix, xwa
	addda32_24	xix, 197714
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 1221
	.byte 0x83
	push	xix
	jr	f, -124
	ldb	a, 201
	.byte 0xcc
	add	(xsp-125), bc
	ld	e, (xix)
	and	e, 128
	ld	a, (xhl)
	and	a, 128
	cp	a, e
	jr	z, 3
	.byte 0x83
	push	xiy
	jr	f, -81
	incf
	sub	(xhl), l
	incf
	or	(xix), a
	jr	lt, -81
	.byte 0x04, 0xf1
	jr	le, -40
	jrl	1178
	ld	xwa, (xsp+8)
	.byte 0xaf, 0x04, 0xf0
	jrl	le, 211
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	16714332
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 0
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 1117
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
	.byte 0x9f
	ld	xde, 1711338815
	.byte 0x1c, 0x84
	push	xix
	jr	f, -37
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xix), a
	and	hl, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, hl
	.ascii "n6h7‚R"
	.byte 0x04
	pop_sr
	ldb	h, 149
	ldb	c, 235
	zcf
	ld	wa, (xiy+2)
	exts	xwa
	ld	xiy, xwa
	sll	xiy, 2
	add	xiy, xwa
	sll	xiy, 6
	add	xiy, xhl
	add	xiz, xiy
	.byte 0x84
	push	xix
	jr	f, -122
	ldb	a, 201
	.byte 0xcc
	add	(xsp-124), bc
	ld	l, (xiz)
	and	l, 128
	ld	a, (xix)
	and	a, 128
	cp	a, l
	jr	z, 3
	.byte 0x84
	push	xiy
	jr	f, -81
	incf
	ldb	w, 175
	.byte 0x04, 0x88
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xde), wa
	ld	xhl, (xsp+16)
	ld	xwa, (xsp+50)
	add	(xwa), hl
	inc	1, xbc
	.byte 0xaf
	ldio	241, 114
	jr	ov, -1
	jrl	958
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	16714332
	ld	(xsp+16), xhl
	ld	xde, (xsp+42)
	ld	xwa, (xsp+46)
	ld	(xsp+46), xwa
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 916
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
	.byte 0x9f
	ld	xde, 1711338815
	.byte 0x1c, 0x85
	push	xix
	jr	f, -37
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xiy), a
	and	hl, 128
	ld	a, (xiy)
	and	a, 128
	extz	wa
	cp	wa, hl
	.ascii "n6h7"
	ld32_24	xiz, 197714
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
	.byte 0x85
	push	xix
	jr	f, -122
	ldb	a, 201
	.byte 0xcc
	add	(xsp-123), bc
	ld	l, (xiz)
	and	l, 128
	ld	a, (xiy)
	and	a, 128
	cp	a, l
	jr	z, 3
	.byte 0x85
	push	xiy
	jr	f, -81
	rcf
	ldb	w, 175
	ldio	136, 175
	ldio	35, 235
	.byte 0xed
	nop
	ld	xwa, (xsp+46)
	ld	(xwa), hl
	ld	xwa, (xsp+12)
	add	(xde), wa
	inc	1, xbc
	.byte 0xaf, 0x04, 0xf1
	jrl	le, -153
	jrl	760
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 79
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
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 708
	.byte 0xb2
	inc	6, l
	.byte 0x04, 0xb2, 0xbd
	jr	2
	.byte 0xb2, 0xb5
	ld	xwa, (xsp+16)
	sla	xwa, 2
	.byte 0xaf
	rcf
	or	(xwa), w
	.byte 0xec, 0x06
	add	xde, xwa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	.byte 0xe1
	jrl	674
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, 68
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
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 622
	.byte 0xb2
	inc	6, l
	.byte 0x04, 0xb2, 0xbd
	jr	2
	.byte 0xb2, 0xb5, 0xaf
	incf
	or	(xde), a
	jr	lt, -81
	.byte 0x04, 0xf1
	jr	le, -20
	jrl	599
	ld	xwa, (xsp+8)
	.byte 0xaf, 0x04, 0xf0
	jr	le, 119
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	16714332
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 0
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 539
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
	.byte 0xb4
	inc	6, l
	.byte 0x04, 0xb4, 0xb5
	jr	2
	.byte 0xb4, 0xbd
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xhl), wa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	.byte 0xc0
	jrl	472
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	16714332
	ld	(xsp+16), xhl
	ld	xhl, (xsp+42)
	ld	xde, (xsp+46)
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 433
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
	.byte 0xb4
	inc	6, l
	.byte 0x04, 0xb4, 0xb5
	jr	2
	.byte 0xb4, 0xbd
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 0
	ld	(xde), wa
	ld	xwa, (xsp+12)
	add	(xhl), wa
	inc	1, xbc
	.byte 0xaf, 0x04, 0xf1
	jr	le, -61
	jrl	369
	ld	xwa, (xsp+46)
	ld	wa, (xwa)
	exts	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 62
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 317
	.byte 0xb2
	inc	6, l
	.byte 0x04, 0xb2, 0xb6
	jr	2
	.byte 0xb2, 0xbe
	ld	xwa, (xsp+16)
	sla	xwa, 2
	.byte 0xaf
	rcf
	or	(xwa), w
	.byte 0xec, 0x06
	add	xde, xwa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	.byte 0xe1
	jrl	283
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, 51
	ld	xwa, (xsp+42)
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xbc
	ld	xde, (xsp+30)
	add	xde, xwa
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 248
	.byte 0xb2
	inc	6, l
	.byte 0x04, 0xb2, 0xb6
	jr	2
	.byte 0xb2, 0xbe, 0xaf
	incf
	or	(xde), a
	jr	lt, -81
	.byte 0x04, 0xf1
	jr	le, -20
	jrl	225
	ld	xwa, (xsp+8)
	.byte 0xaf, 0x04, 0xf0
	jr	le, 118
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	call	16714332
	ld	(xsp+12), xhl
	ld	xde, (xsp+42)
	ld	xwa, xde
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 0
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 165
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
	.byte 0xb4
	inc	6, l
	.byte 0x04, 0xb4, 0xb6
	jr	2
	.byte 0xb4, 0xbe
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xde), wa
	ld	xwa, (xsp+16)
	add	(xhl), wa
	inc	1, xbc
	.byte 0xaf
	ldio	241, 98
	.byte 0xc0
	jr	99
	ld	xwa, (xsp+16)
	ld	xbc, (xsp+34)
	call	16714332
	ld	(xsp+16), xhl
	ld	xhl, (xsp+42)
	ld	xde, (xsp+46)
	ld	xwa, (xsp+50)
	ld	(xsp+8), xwa
	lds32	xbc, 0
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jr	lt, 61
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
	.byte 0xb4
	inc	6, l
	.byte 0x04, 0xb4, 0xb6
	jr	2
	.byte 0xb4, 0xbe
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	sra	xwa, 0
	ld	(xde), wa
	ld	xwa, (xsp+12)
	add	(xhl), wa
	inc	1, xbc
	.byte 0xaf, 0x04, 0xf1
	jr	le, -61
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
	calr	41137
	pop	xiz
	lda	xsp, (xsp+72)
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), xbc
	ld	xiz, xwa
	calr	40558
	cps	hl, 0
	jr	z, 32
	ld8_24	a, 257960
	st8_24	257962, a
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	jr	z, 66
	ld	xwa, xiz
	ld	xbc, (xsp+6)
	ld	de, (xsp+4)
	calr	93
	jr	53
	ldw	wa, 16
	calr	40278
	ld	xwa, xhl
	lda_24	xbc, 16451361
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	xbc, (xsp+6)
	ld	xiy, xbc
	lda	xix, (xwa+8)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld8_24	c, 257960
	ld	(xwa+14), c
	calr	40015
	pop	xiz
	inc	6, xsp
	ret
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	lda	xhl, (xbc+8)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	st8_24	257962, c
	.byte 0xd2
	popw	iz
	.byte 0x04
	pop_sr
	push	xsp
	nop
	nop
	ret	z
	ld	xbc, xhl
	calr	1
	ret
	lda	xsp, (xsp-56)
	push	xiz
	ld	(xsp+50), de
	ld	(xsp+52), xbc
	ld	(xsp+56), xwa
	ld	(xsp+24), 0
	ld	xde, 4294967295
	ld	xwa, (xsp+52)
	ld	bc, (xwa)
	ld	xwa, (xsp+56)
	.byte 0x90, 0xf1
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+12), xde
	ld	xde, 4294967295
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
	jr	le, 2
	lds32	xde, 1
	ld	(xsp+16), xde
	ld	xwa, (xsp+12)
	cp	xwa, 1
	jr	nz, 12
	ld	xwa, (xsp+52)
	ld	de, (xwa)
	ld	xwa, (xsp+56)
	.byte 0x90, 0xa2
	jr	10
	ld	xwa, (xsp+56)
	ld	de, (xwa)
	ld	xwa, (xsp+52)
	.byte 0x90
	or	(xde), xde
	zcf
	ld	(xsp+4), xde
	ld	xwa, (xsp+16)
	cp	xwa, 1
	jr	nz, 6
	sub	bc, hl
	ld	hl, bc
	jr	2
	sub	hl, bc
	exts	xhl
	ld	(xsp+8), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 8
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	z, 1328
	ld	xwa, (xsp+56)
	ld	xiy, xwa
	lda	xix, (xsp+46)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jrl	nz, 298
	lds32	xwa, 0
	ld	(xsp+20), xwa
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 1254
	.byte 0x8f
	push_f
	push	xsp
	pop_sr
	jr	ule, 7
	ld	(xsp+24), 0
	jrl	245
	.byte 0x8f
	push_f
	push	xsp
	.byte 0x01
	jrl	ugt, 235
	ld8_24	a, 257962
	cps	a, 2
	jrl	z, 184
	cps	a, 1
	jrl	z, 136
	cps	a, 0
	jrl	nz, 215
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
	lda_24	xhl, 277504
	add	xhl, xwa
	.byte 0x9f
	ldw	de, 62783
	nop
	jr	z, 31
	.byte 0x83
	push	xix
	jr	f, -36
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xhl), a
	ld	bc, ix
	and	bc, 128
	ld	a, (xhl)
	and	a, 128
	extz	wa
	cp	wa, bc
	jr	nz, 55
	jrl	141
	ld32_24	xix, 197714
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
	.byte 0x83
	push	xix
	jr	f, -124
	ldb	a, 201
	.byte 0xcc
	add	(xsp-125), bc
	ld	c, (xix)
	and	c, 128
	ld	a, (xhl)
	and	a, 128
	cp	a, c
	jr	z, 89
	.byte 0x83
	.ascii "=`hTø"
	pushw	iz
	ldw	wa, 664
	ldb	a, 233
	zcf
	ld	xde, xbc
	sll	xde, 2
	add	xde, xbc
	sll	xde, 6
	ld	wa, (xwa)
	exts	xwa
	add	xwa, xde
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xb5
	jr	45
	.byte 0xb1, 0xbd
	jr	41
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
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xb6
	jr	2
	.byte 0xb1, 0xbe
	incm8	1, (xsp+24)
	ld	xwa, (xsp+16)
	add	(xsp+48), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	.byte 0xaf
	ldio	240, 114
	.byte 0xea
	swi	6
	jrl	973
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jrl	nz, 298
	lds32	xwa, 0
	ld	(xsp+20), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 948
	.byte 0x8f
	push_f
	push	xsp
	pop_sr
	jr	ule, 7
	ld	(xsp+24), 0
	jrl	245
	.byte 0x8f
	push_f
	push	xsp
	.byte 0x01
	jrl	ugt, 235
	ld8_24	a, 257962
	cps	a, 2
	jrl	z, 184
	cps	a, 1
	jrl	z, 136
	cps	a, 0
	jrl	nz, 215
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
	lda_24	xhl, 277504
	add	xhl, xwa
	.byte 0x9f
	ldw	de, 62783
	nop
	jr	z, 31
	.byte 0x83
	push	xix
	jr	f, -36
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xhl), a
	ld	bc, ix
	and	bc, 128
	ld	a, (xhl)
	and	a, 128
	extz	wa
	cp	wa, bc
	jr	nz, 55
	jrl	141
	ld32_24	xix, 197714
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
	.byte 0x83
	push	xix
	jr	f, -124
	ldb	a, 201
	.byte 0xcc
	add	(xsp-125), bc
	ld	c, (xix)
	and	c, 128
	ld	a, (xhl)
	and	a, 128
	cp	a, c
	jr	z, 89
	.byte 0x83
	push	xiy
	jr	f, 104
	.byte 0x54
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
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xb5
	jr	45
	.byte 0xb1, 0xbd
	jr	41
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
	lda_24	xbc, 277504
	add	xbc, xwa
	.byte 0xb1
	inc	6, l
	.byte 0x04, 0xb1, 0xb6
	jr	2
	.byte 0xb1, 0xbe
	incm8	1, (xsp+24)
	ld	xwa, (xsp+12)
	add	(xsp+46), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	.byte 0xaf, 0x04, 0xf0
	jrl	le, -278
	jrl	667
	lda	xwa, (xsp+46)
	ld	(xsp+34), xwa
	ld	xwa, (xsp+8)
	.byte 0xaf, 0x04, 0xf0
	jrl	le, 322
	.byte 0xaf, 0x04
	.long NakaInst_Ballads
	ld	xbc, (xsp+8)
	call	16714766
	ld	xiz, xhl
	ld	xwa, (xsp+12)
	ld	xbc, xiz
	call	16714332
	ld	(xsp+12), xhl
	ld	xbc, (xsp+34)
	ld	xwa, xbc
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+4), xwa
	sla	xwa, 0
	ld	(xsp+4), xwa
	ld	xwa, 32768
	add	(xsp+4), xwa
	lds32	xwa, 0
	ld	(xsp+20), xwa
	ld	xwa, (xsp+8)
	cp	xwa, 0
	jrl	lt, 582
	.byte 0x8f
	push_f
	push	xsp
	pop_sr
	jr	ule, 7
	ld	(xsp+24), 0
	jrl	202
	.byte 0x8f
	push_f
	push	xsp
	.byte 0x01
	jrl	ugt, 192
	ld8_24	a, 257962
	.byte 0xc7, 0xf0, 0x99
	ld	wa, (xbc+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	lda_24	xde, 277504
	.byte 0xc7, 0xf0
	scc16	z, de
	.byte 0x8c
	nop
	.byte 0xc7, 0xf0
	inc	6, bc
	jrl	ule, -3897
	scc16	nz, wa
	.byte 0x93
	nop
	ld	xiz, xbc
	ld	iy, (xsp+50)
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xhl
	ld	xix, xde
	add	xix, xwa
	.byte 0x9f
	ldw	de, 62783
	nop
	jr	z, 30
	.byte 0x84
	push	xix
	jr	f, -35
	and	(xwa-40), d
	.byte 0x9f
	nop
	add	(xix), a
	ld	de, iy
	and	de, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, de
	jr	nz, 54
	jr	95
	ld32_24	xiy, 197714
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
	.byte 0x84
	push	xix
	jr	f, -123
	ldb	a, 201
	.byte 0xcc
	add	(xsp-124), bc
	ld	e, (xiy)
	and	e, 128
	ld	a, (xix)
	and	a, 128
	cp	a, e
	jr	z, 43
	.byte 0x84
	push	xiy
	jr	f, 104
	ldb	h, 145
	ldb	w, 232
	zcf
	add	xwa, xhl
	add	xde, xwa
	.byte 0xb2
	inc	6, l
	.byte 0x04, 0xb2, 0xb5
	jr	22
	.byte 0xb2, 0xbd
	jr	18
	ld	wa, (xbc)
