; =============================================================================
; Graphics, Text & VGA Routines
; =============================================================================
;
; VGA palette initialization, text rendering engine, string
; layout, character set handling, and VRAM blit operations.
; The low-level graphics API used by all UI subsystems.
; =============================================================================

	add xwa, xbc
	lda_24 xiz, 0x043c00
	add xiz, xwa
	lds hl, 0
	cpw (xsp + 24), 0x0
	jr ule, TextRender_AdvancePointerAndUpdateLine

TextRender_PixelLoop:
	ld bc, (xde)
	add bc, hl
	ld (xix), bc
	ld_sril XIY, (xsp + 0x013a)
	cp bc, (xiy)
	jr lt, TextRender_BitMask6_Return
	ld wa, (xix)
	cp wa, (xiy + 4)
	jr gt, TextRender_AdvancePointerAndUpdateLine
	lds wa, 7
	sub wa, hl
	lds iy, 1
	and a, 0xF
	jr z, TextRender_CheckBitMask
	slaa iy

TextRender_CheckBitMask:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	and wa, iy
	jr z, TextRender_BitMask6_Return
	bitm 7, (xiz)
	jr z, TextRender_SetBit6
	resm 6, (xiz)
	jr TextRender_BitMask6_Return

TextRender_SetBit6:
	setm 6, (xiz)

TextRender_BitMask6_Return:
	inc 1, hl
	inc 1, xiz
	cp hl, (xsp + 24)
	jr c, TextRender_PixelLoop

TextRender_AdvancePointerAndUpdateLine:
	lds32 xwa, 1
	add (xsp + 16), xwa
	incm 1, (xsp + 28)

TextRender_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_XorMode_DrawPixel

TextRender_AdvanceToNextLine:
	ld wa, (xsp + 24)
	add_sriw_mr WA, 0xFD, 0x2A, 0x01
	incm 1, (xsp + 26)
	ld wa, (xsp + 26)
	cp wa, (xsp + 22)
	jrl c, TextRender_ScanLineLoop

TextRender_AdvanceStringPointer:
	lds32 xwa, 1
	add (xsp + 30), xwa
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jrl nz, TextRender_CharEncodeAndDraw

TextRender_Finalize:
	st_dri3b W, 0xFD, 0x2E, 0x01
	calr SetChangeRect

TextRender_PopAndReturn:
	pop xiz
	st_dri3b L, 0xFD, 0x3A, 0x01
	retd 0x8
	st16_24 0x03efa2, xwa
	ret

GraphicsRender_ByteData:
	st16_24	257956, wa
	ret
	pushw	iz
	ld	iz, wa
	calr	-28458
	cps	hl, 0
	jr	z, 7
	ld	wa, iz
	calr	29
	jr	20
	lds	wa, 6
	calr	-28712
	ld	xwa, xhl
	lda_24	xbc, 16454781
	ld	(xwa), xbc
	ld	(xwa+4), iz
	calr	-28943
	popw	iz
	ret
	ld	wa, (xwa+4)
	jr	0
	dec	4, xsp
	pushw	iz
	st16_24	257958, wa
	call	16459940
	ld	(xsp+2), xhl
	ldw	iz, 64
	ld	wa, iz
	ld	xbc, (xsp+2)
	call	16459925
	inc	1, iz
	cp	iz, 192
	jr	c, -17
	sti16_24	257950, 4
	sti16_24	197728, 1
	popw	iz
	inc	4, xsp
	ret
	calr	-28552
	cps	hl, 0
	jr	nz, 19
	lds	wa, 4
	calr	-28799
	ld	xwa, xhl
	lda_24	xbc, 16454863
	ld	(xwa), xbc
	jrl	-29027
	jr	0
	pushw	iz
	ldw	iz, 32
	ld	wa, iz
	sub	wa, 32
	extz	xwa
	ld	xbc, 15380180
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	call	16459940
	ld	xbc, xhl
	ld	wa, iz
	call	16459925
	inc	1, iz
	cp	iz, 64
	jr	c, -39
	ldw	iz, 192
	ld	wa, iz
	sub	wa, 192
	extz	xwa
	.byte 0x41
	.long LABEL_EAAEF4
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	call	16459940
	ld	xbc, xhl
	ld	wa, iz
	call	16459925
	inc	1, iz
	.long GUI_DisplayStructData
	jr	c, -39
	sti16_24	257950, 4
	sti16_24	197728, 1
	popw	iz
	ret

Display_DeferOrDrawWall:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, Display_DeferOrDrawWall_Direct
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfb154e
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr __jrt_nop_FB1550
__jrt_nop_FB1550:

Display_DeferOrDrawWall_Direct:
	sti16_24 0x03ef92, 0x0000
	lds wa, 0
	calr SetNeedUpdate
	jrl DrawWall

Display_DeferOrUpdateScreen:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr nz, Display_DeferOrUpdateScreen_Direct
	lds wa, 4
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda_24 xbc, 0xfb1577
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr __jrt_nop_FB1579
__jrt_nop_FB1579:

Display_DeferOrUpdateScreen_Direct:
	sti16_24 0x03ef92, 0x0001
	lds wa, 1
	calr SetNeedUpdate
	jrl UpdateScreen
	ret

GraphicsRender_RetStub:
	ret

GraphicsRender_ShortByteBlock:
	lda	xbc, (xwa+1)
	jr	5
	lda	xbc, (xwa+1)
	jr	t, 0x62

GraphicsRender_ProcessEntries:
	st_dri3b L, 0xFD, 0x6A, 0xFF
	push xiz
	st_dri3l XBC, 0xFD, 0x96, 0x00
	ld xiz, xwa
	ld xiy, 0xEAAF14
	lda xix, (xsp + 6)
	ldw bc, 0x48
	ldirw
	cp_sril_mr XIZ, 0xFD, 0x96, 0x00
	jr ule, GraphicsRender_ProcessEntries_Done

GraphicsRender_ProcessEntry_Loop:
	ld c, (xiz)
	ld a, (xiz + 1)
	ld (xsp + 4), a
	cp c, 0x23
	jr ule, VoiceMidi_EventHandler
	ld xwa, xiz
	calr GraphicsRender_RetStub
	jr GraphicsRender_ProcessEntries_Done

; Voice MIDI event handler dispatch
VoiceMidi_EventHandler:
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	st_dri3b H, 0x07, 0xF8, 0xE0
	cp_sril_mr XIZ, 0xFD, 0x96, 0x00
	jr ugt, GraphicsRender_ProcessEntry_Loop

GraphicsRender_ProcessEntries_Done:
	pop xiz
	st_dri3b L, 0xFD, 0x96, 0x00
	ret

GraphicsRender_Start:
	lda xsp, (xsp - 54)
	push xiz
	ld (xsp + 54), xbc
	ld xiz, xwa
	ld xiy, 0xEAAFA4
	lda xix, (xsp + 6)
	ldw bc, 0x18
	ldirw
	cp (xsp + 54), xiz
	jr ule, GraphicsRender_Start_Done

GraphicsRender_Start_EntryLoop:
	ld c, (xiz)
	ld a, (xiz + 1)
	ld (xsp + 4), a
	cp c, 0xB
	jr ule, VoiceMidi_AltEventHandler
	ld xwa, xiz
	calr GraphicsRender_RetStub
	jr GraphicsRender_Start_Done

; Voice MIDI alt event handler dispatch
VoiceMidi_AltEventHandler:
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld xwa, xiz
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	st_dri3b H, 0x07, 0xF8, 0xE0
	cp (xsp + 54), xiz
	jr ugt, GraphicsRender_Start_EntryLoop

GraphicsRender_Start_Done:
	pop xiz
	lda xsp, (xsp + 54)
	ret

DrawText_LayoutAndRender:
	st_dri3b L, 0xFD, 0xEE, 0xFE
	push xiz
	ld xiy, 0xEAAFD4
	st_dri3b D, 0xFD, 0x0E, 0x01
	lds bc, 4
	ldirw
	ld hl, (xwa + 2)
	ld c, (xwa + 1)
	dec 4, c
	extz bc
	ld (xsp + 4), bc
	st_dri3b A, 0xFD, 0x0A, 0x01
	ld (xsp + 6), xbc
	ld de, hl
	extz xde
	div de, 0x28
	ld xbc, (xsp + 6)
	ld (xbc + 2), de
	muls de, 0x28
	sub hl, de
	sll hl, 3
	ld (xbc), hl
	lds iy, 0
	cpw (xsp + 4), 0x0
	jr ule, DrawText_NullTerminate
	lda xhl, (xsp + 10)
	lds32 xde, 4

DrawText_CopyCharLoop:
	ld xix, xde
	ld xbc, 0xFFFFFFFC
	add xix, xbc
	ld xiz, xhl
	add xiz, xix
	ld xbc, xde
	add xbc, xwa
	ld c, (xbc)
	ld (xiz), c
	inc 1, iy
	inc 1, xde
	cp iy, (xsp + 4)
	jr c, DrawText_CopyCharLoop

DrawText_NullTerminate:
	ld wa, iy
	extz xwa
	lda xde, (xsp + 10)
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	st_dri3b W, 0xFD, 0x0E, 0x01
	lds32 xbc, 0
	push xbc
	push_sd24w 0xA4, 0xEF, 0x03
	push_sd24w 0xA2, 0xEF, 0x03
	ld xbc, (xsp + 14)
	calr DrawText_QueueOrDirect
	pop xiz
	st_dri3b L, 0xFD, 0x12, 0x01
	ret

DrawText_LayoutAndRender_Variant1:
	.byte 0xf3, 0xfd, 0xee, 0xfe, 0x37
	push	xiz
	ld	xiy, 15380444
	lda	xix, (xsp+270)
	lds	bc, 4
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	extz	bc
	ld	(xsp+4), bc
	lda	xbc, (xsp+266)
	ld	(xsp+6), xbc
	ld	de, hl
	extz	xde
	div	de, 40
	ld	xbc, (xsp+6)
	ld	(xbc+2), de
	muls	de, 40
	sub	hl, de
	sll	hl, 3
	ld	(xbc), hl
	lds	iy, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 35
	lda	xhl, (xsp+10)
	lds32	xde, 4
	ld	xix, xde
	ld	xbc, 4294967292
	add	xix, xbc
	ld	xiz, xhl
	add	xiz, xix
	ld	xbc, xde
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xiz), c
	inc	1, iy
	inc	1, xde
	cp	iy, (xsp+4)
	jr	c, -30
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x30
	lds32	xbc, 1
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+14)
	calr	-2302
	pop	xiz
	.byte 0xf3, 0xfd, 0x12, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xee, 0xfe, 0x37
	push	xiz
	ld	xiy, 15380452
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	extz	bc
	ld	(xsp+4), bc
	.byte 0xf3, 0xfd, 0x0a, 0x01, 0x31
	ld	(xsp+6), xbc
	ld	de, hl
	extz	xde
	div	de, 40
	ld	xbc, (xsp+6)
	ld	(xbc+2), de
	muls	de, 40
	sub	hl, de
	sll	hl, 3
	ld	(xbc), hl
	lds	iy, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 35
	lda	xhl, (xsp+10)
	lds32	xde, 4
	ld	xix, xde
	ld	xbc, 4294967292
	add	xix, xbc
	ld	xiz, xhl
	add	xiz, xix
	ld	xbc, xde
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xiz), c
	inc	1, iy
	inc	1, xde
	cp	iy, (xsp+4)
	jr	c, -30
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x30
	lds32	xbc, 2
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+14)
	calr	-2457
	pop	xiz
	.byte 0xf3, 0xfd, 0x12, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xee, 0xfe, 0x37
	push	xiz
	ld	xiy, 15380460
	lda	xix, (xsp+270)
	lds	bc, 4
	ldirw
	ld	c, (xwa+1)
	dec	6, c
	extz	bc
	ld	(xsp+4), bc
	.byte 0xf3, 0xfd, 0x0a, 0x01, 0x31
	ld	(xsp+6), xbc
	ld	de, (xwa+4)
	ld	xbc, (xsp+6)
	ld	(xbc+2), de
	ld	de, (xwa+2)
	ld	(xbc), de
	lds	iy, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 35
	lda	xhl, (xsp+10)
	lds32	xde, 6
	ld	xix, xde
	ld	xbc, 4294967290
	add	xix, xbc
	ld	xiz, xhl
	add	xiz, xix
	ld	xbc, xde
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xiz), c
	inc	1, iy
	inc	1, xde
	cp	iy, (xsp+4)
	jr	c, -30
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x30
	lds32	xbc, 3
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+14)
	calr	-2598
	pop	xiz
	.byte 0xf3, 0xfd, 0x12, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xee, 0xfe, 0x37
	push	xiz
	ld	xiy, 15380468
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	c, (xwa+1)
	dec	6, c
	extz	bc
	ld	(xsp+4), bc
	lda	xbc, (xsp+266)
	ld	(xsp+6), xbc
	ld	de, (xwa+4)
	ld	xbc, (xsp+6)
	ld	(xbc+2), de
	ld	de, (xwa+2)
	ld	(xbc), de
	lds	iy, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 35
	lda	xhl, (xsp+10)
	lds32	xde, 6
	ld	xix, xde
	ld	xbc, 4294967290
	add	xix, xbc
	ld	xiz, xhl
	add	xiz, xix
	ld	xbc, xde
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xiz), c
	inc	1, iy
	inc	1, xde
	cp	iy, (xsp+4)
	jr	c, -30
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	lds32	xbc, 4
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+14)
	calr	-2739
	pop	xiz
	.byte 0xf3, 0xfd, 0x12, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xee, 0xfe, 0x37
	push	xiz
	ld	xiy, 15380476
	lda	xix, (xsp+270)
	lds	bc, 4
	ldirw
	ld	hl, (xwa+2)
	ld	c, (xwa+1)
	dec	4, c
	extz	bc
	ld	(xsp+4), bc
	lda	xbc, (xsp+266)
	ld	(xsp+6), xbc
	ld	de, hl
	extz	xde
	div	de, 40
	ld	xbc, (xsp+6)
	ld	(xbc+2), de
	muls	de, 40
	sub	hl, de
	sll	hl, 3
	ld	(xbc), hl
	lds	iy, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 35
	lda	xhl, (xsp+10)
	lds32	xde, 4
	ld	xix, xde
	ld	xbc, 4294967292
	add	xix, xbc
	ld	xiz, xhl
	add	xiz, xix
	ld	xbc, xde
	add	xbc, xwa
	ld	c, (xbc)
	ld	(xiz), c
	inc	1, iy
	inc	1, xde
	cp	iy, (xsp+4)
	jr	c, -30
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	.byte 0xf3, 0xfd, 0x0e, 0x01, 0x30
	lds32	xbc, 6
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+14)
	calr	-2894
	pop	xiz
	.byte 0xf3, 0xfd, 0x12, 0x01, 0x37
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-6958
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7000
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7042
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5059
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5101
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xde, xwa
	lda	xwa, (xsp+4)
	ld	bc, (xde+2)
	ld	(xwa), bc
	ld	bc, (xde+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp)
	ld	hl, (xde+6)
	ld	(xbc), hl
	ld	de, (xde+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5143
	inc	8, xsp
	ret
	dec	8, xsp
	lda	xbc, (xsp)
	ld	de, (xwa+2)
	ld	(xbc), de
	ld	de, (xwa+4)
	ld	(xbc+2), de
	ld	de, (xwa+6)
	ld	(xbc+4), de
	ld	wa, (xwa+8)
	ld	(xbc+6), wa
	ld16_24	de, 257956
	ld	xwa, xbc
	ld	bc, de
	calr	-3555
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	xiz, xwa
	lda	xwa, (xsp+12)
	ld	bc, (xiz+2)
	ld	(xwa), bc
	ld	bc, (xiz+4)
	ld	(xwa+2), bc
	ld	bc, (xiz+6)
	ld	(xwa+4), bc
	ld	bc, (xiz+8)
	ld	(xwa+6), bc
	ld16_24	bc, 257956
	calr	-3598
	lda	xwa, (xsp+8)
	lda	xde, (xiz+6)
	ld	bc, (xde)
	inc	1, bc
	ld	(xwa), bc
	ld	bc, (xiz+4)
	inc	1, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xde)
	inc	1, de
	ld	(xbc), de
	ld	de, (xiz+8)
	inc	1, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7298
	lda	xwa, (xsp+8)
	lda	xde, (xiz+6)
	ld	bc, (xde)
	inc	2, bc
	ld	(xwa), bc
	ld	bc, (xiz+4)
	inc	2, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xde)
	inc	2, de
	ld	(xbc), de
	ld	de, (xiz+8)
	inc	2, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7343
	lda	xwa, (xsp+8)
	ld	bc, (xiz+2)
	inc	1, bc
	ld	(xwa), bc
	lda	xhl, (xiz+8)
	ld	bc, (xhl)
	inc	1, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xiz+6)
	inc	1, de
	ld	(xbc), de
	ld	de, (xhl)
	inc	1, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7388
	lda	xwa, (xsp+8)
	ld	bc, (xiz+2)
	inc	2, bc
	ld	(xwa), bc
	lda	xhl, (xiz+8)
	ld	bc, (xhl)
	inc	2, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xiz+6)
	inc	2, de
	ld	(xbc), de
	ld	de, (xhl)
	inc	2, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7433
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	dec	8, xsp
	push	xiz
	ld	xiz, xwa
	lda	xwa, (xsp+8)
	ld	bc, (xiz+2)
	ld	(xwa), bc
	lda	xhl, (xiz+4)
	ld	bc, (xhl)
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xiz+6)
	ld	(xbc), de
	ld	de, (xhl)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5455
	lda	xwa, (xsp+8)
	ld	bc, (xiz+2)
	ld	(xwa), bc
	lda	xhl, (xiz+8)
	ld	bc, (xhl)
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xiz+6)
	ld	(xbc), de
	ld	de, (xhl)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5492
	lda	xwa, (xsp+8)
	lda	xde, (xiz+2)
	ld	bc, (xde)
	ld	(xwa), bc
	ld	bc, (xiz+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xde)
	ld	(xbc), de
	ld	de, (xiz+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5529
	lda	xwa, (xsp+8)
	lda	xde, (xiz+6)
	ld	bc, (xde)
	ld	(xwa), bc
	ld	bc, (xiz+4)
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xde)
	ld	(xbc), de
	ld	de, (xiz+8)
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-5566
	pop	xiz
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	xiz, xwa
	lda	xwa, (xsp+12)
	ld	bc, (xiz+2)
	ld	(xwa), bc
	ld	bc, (xiz+4)
	ld	(xwa+2), bc
	ld	bc, (xiz+6)
	ld	(xwa+4), bc
	ld	bc, (xiz+8)
	ld	(xwa+6), bc
	ld16_24	bc, 257956
	calr	-3980
	lda	xwa, (xsp+8)
	lda	xde, (xiz+6)
	ld	bc, (xde)
	inc	1, bc
	ld	(xwa), bc
	ld	bc, (xiz+4)
	inc	1, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xde)
	inc	1, de
	ld	(xbc), de
	ld	de, (xiz+8)
	inc	1, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7680
	lda	xwa, (xsp+8)
	ld	bc, (xiz+2)
	inc	1, bc
	ld	(xwa), bc
	lda	xhl, (xiz+8)
	ld	bc, (xhl)
	inc	1, bc
	ld	(xwa+2), bc
	lda	xbc, (xsp+4)
	ld	de, (xiz+6)
	inc	1, de
	ld	(xbc), de
	ld	de, (xhl)
	inc	1, de
	ld	(xbc+2), de
	ld16_24	de, 257956
	calr	-7725
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	dec	8, xsp
	lda	xhl, (xsp)
	lda	xde, (xhl+2)
	lda	xix, (xwa+6)
	ld	bc, (xix)
	extz	xbc
	div	bc, 40
	ld	(xde), bc
	ld	bc, (xix)
	extz	xbc
	div	bc, 40
	ld	bc, qbc
	sll	bc, 3
	ld	(xhl), bc
	ld	bc, (xde)
	add	bc, (xwa+10)
	ld	(xhl+6), bc
	ld	bc, (xwa+8)
	sll	bc, 3
	ld	de, (xhl)
	add	de, bc
	ld	(xhl+4), de
	ld	xbc, (xwa+2)
	ld16_24	de, 257956
	ld	xwa, xhl
	calr	-8701
	inc	8, xsp
	ret
	lda	xsp, (xsp-12)
	pushw	iz
	lda	xhl, (xsp+10)
	lda	xde, (xhl+2)
	lda	xix, (xwa+3)
	ld	bc, (xix)
	extz	xbc
	div	bc, 40
	ld	(xde), bc
	ld	bc, (xix)
	extz	xbc
	div	bc, 40
	ld	bc, qbc
	sll	bc, 3
	ld	(xhl), bc
	ld	a, (xwa+2)
	.byte 0xc7, 0xf8, 0x99
	extz	iz
	lda	xwa, (xsp+2)
	ld	bc, (xhl)
	dec	2, bc
	ld	(xwa), bc
	ld	bc, (xhl)
	add	bc, 25
	ld	(xwa+4), bc
	ld	bc, (xde)
	dec	2, bc
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 25
	ld	(xwa+6), bc
	ldw	bc, 196
	ldw	de, 240
	calr	-18505
	lda	xwa, (xsp+10)
	ld	bc, iz
	inc	2, bc
	extz	xbc
	calr	-24175
	popw	iz
	lda	xsp, (xsp+12)
	ret
	dec	8, xsp
	push qiz
	lda	xbc, (xsp+2)
	ld	de, (xwa+2)
	ld	(xbc), de
	ld	de, (xwa+4)
	ld	(xbc+2), de
	ld	de, (xwa+6)
	ld	(xbc+4), de
	ld	wa, (xwa+8)
	ld	(xbc+6), wa
	ld8_24	a, 257960
	.byte 0xc7, 0xfb, 0x99
	sti8_24	257960, 1
	ld16_24	de, 257956
	ld	xwa, xbc
	ld	bc, de
	calr	-10104
	.byte 0xc7, 0xfb, 0x89
	st8_24	257960, a
	pop qiz
	inc	8, xsp
	ret

ColorBlit_ComputeRectAndBlit:
	dec 8, xsp
	ld xbc, xwa
	lda xwa, (xsp)
	lda xhl, (xwa + 2)
	lda xix, (xbc + 2)
	ld de, (xix)
	extz xde
	div de, 0x28
	ld (xhl), de
	ld de, (xix)
	extz xde
	div de, 0x28
	ldto_werp DE, 0xEA
	sll de, 3
	ld (xwa), de
	ld de, (xhl)
	add de, (xbc + 6)
	ld (xwa + 6), de
	ld bc, (xbc + 4)
	sll bc, 3
	ld de, (xwa)
	add de, bc
	ld (xwa + 4), de
	ld16_24 xbc, 0x03efa2
	calr ColorBlit2
	inc 8, xsp
	ret

ColorBlit_ByteData:
	dec	8, xsp
	lda	xbc, (xsp)
	ld	de, (xwa+2)
	ld	(xbc), de
	ld	de, (xwa+4)
	ld	(xbc+2), de
	ld	de, (xwa+6)
	ld	(xbc+4), de
	ld	wa, (xwa+8)
	ld	(xbc+6), wa
	ld16_24	de, 257954
	ld	xwa, xbc
	ld	bc, de
	calr	-9639
	.byte 0xef
	jr	f, 0x0e

DrawText_ExtendedLayout:
	st_dri3b L, 0xFD, 0xE4, 0xFE
	push xiz
	st_dri3l XWA, 0xFD, 0x1C, 0x01
	ld xiy, 0xEAB114
	st_dri3b D, 0xFD, 0x14, 0x01
	lds bc, 4
	ldirw
	ld_sril XDE, (xsp + 0x011c)
	ld iy, (xde + 2)
	extz xiy
	ld c, (xde + 4)
	ld a, (xde + 5)
	ld (xsp + 14), a
	ld a, (xiy)
	and a, c
	ld (xsp + 6), a
	ld a, (xsp + 14)
	ld c, (xsp + 6)
	and a, 0xF
	jr z, DrawText_ExtLayout_SkipShift
	srla c

DrawText_ExtLayout_SkipShift:
	ld (xsp + 6), c
	ld wa, (xde + 13)
	ld (xsp + 10), wa
	ld wa, (xde + 11)
	ld (xsp + 4), wa
	st_dri3b W, 0xFD, 0x10, 0x01
	ld (xsp + 12), xwa
	ld bc, (xsp + 10)
	extz xbc
	div bc, 0x28
	ld xhl, (xsp + 12)
	ld (xhl + 2), bc
	muls bc, 0x28
	ld wa, bc
	ld bc, (xsp + 10)
	sub bc, wa
	sll bc, 3
	ld (xhl), bc
	lds hl, 0
	cpw (xsp + 4), 0x0
	jr ule, DrawText_ExtLayout_NullAndDraw
	lda xwa, (xde + 7)
	ld (xsp + 8), xwa
	lda xix, (xsp + 16)
	ld a, (xsp + 6)
	extz wa
	mrdw3 0x9F, 0x04, 0x40
	ld xbc, xwa
	lds32 xde, 0

DrawText_ExtLayout_CopyLoop:
	ld xwa, (xsp + 8)
	ld xiy, (xwa)
	ld xiz, xix
	add xiz, xde
	ld xwa, xbc
	add xwa, xiy
	ld a, (xwa)
	ld (xiz), a
	inc 1, hl
	inc 1, xde
	inc 1, xbc
	cp hl, (xsp + 4)
	jr c, DrawText_ExtLayout_CopyLoop

DrawText_ExtLayout_NullAndDraw:
	extz xhl
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	add xwa, xhl
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x011c)
	ld a, (xwa + 6)
	and a, 0x3F
	extz wa
	sla wa, 2
	lda_24 xbc, 0xeab004
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	st_dri3b W, 0xFD, 0x14, 0x01
	push xbc
	push_sd24w 0xA4, 0xEF, 0x03
	push_sd24w 0xA2, 0xEF, 0x03
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr DrawText_QueueOrDirect
	pop xiz
	st_dri3b L, 0xFD, 0x1C, 0x01
	ret

DrawText_ExtLayout_Variant1:
	.byte 0xf3, 0xfd, 0xe4, 0xfe, 0x37
	push	xiz
	ld	(xsp+284), xwa
	ld	xiy, 15380764
	lda	xix, (xsp+276)
	lds	bc, 4
	ldirw
	ld	xde, (xsp+284)
	ld	iy, (xde+2)
	extz	xiy
	ld	c, (xde+4)
	ld	a, (xde+5)
	ld	(xsp+14), a
	ld	a, (xiy)
	and	a, c
	ld	(xsp+6), a
	ld	a, (xsp+14)
	ld	c, (xsp+6)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xff
	ld	(xsp+6), c
	lda	xwa, (xsp+272)
	ld	(xsp+12), xwa
	ld	xbc, (xsp+12)
	ld	wa, (xde+13)
	ld	(xbc), wa
	ld	wa, (xde+15)
	ld	(xbc+2), wa
	ld	wa, (xde+11)
	ld	(xsp+4), wa
	lds	hl, 0
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	ule, 51
	ld	xbc, xde
	lda	xwa, (xbc+7)
	ld	(xsp+8), xwa
	lda	xix, (xsp+16)
	ld	a, (xsp+6)
	extz	wa
	.byte 0x9f, 0x04, 0x40
	ld	xbc, xwa
	lds32	xde, 0
	ld	xwa, (xsp+8)
	ld	xiy, (xwa)
	ld	xiz, xix
	add	xiz, xde
	ld	xwa, xbc
	add	xwa, xiy
	ld	a, (xwa)
	ld	(xiz), a
	inc	1, hl
	inc	1, xde
	inc	1, xbc
	cp	hl, (xsp+4)
	jr	c, -28
	extz	xhl
	lda	xwa, (xsp+16)
	ld	(xsp+8), xwa
	add	xwa, xhl
	ld	(xwa), 0
	ld	xwa, (xsp+284)
	ld	a, (xwa+6)
	and	a, 15
	extz	wa
	lda_24	xbc, 15380740
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x23
	extz	bc
	extz	xbc
	lda	xwa, (xsp+276)
	push	xbc
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	-4542
	pop	xiz
	.byte 0xf3, 0xfd, 0x1c, 0x01, 0x37
	ret

DrawFunc_Init:
	st_dri3b L, 0xFD, 0xF4, 0xFE
	push xiz
	ld xiz, xwa
	ld xiy, 0xEAB124
	st_dri3b D, 0xFD, 0x08, 0x01
	lds bc, 4
	ldirw
	ld wa, (xiz + 2)
	extz xwa
	ld e, (xiz + 4)
	ld c, (xiz + 5)
	ld l, (xwa)
	and l, e
	ld a, c
	and a, 0xF
	jr z, DrawFunc_Init_SkipShift
	srla l

DrawFunc_Init_SkipShift:
	ld de, (xiz + 7)
	ld a, (xiz + 9)
	ldfr_berp A, 0xF0
	extz ix
	st_dri3b A, 0xFD, 0x04, 0x01
	ld wa, de
	extz xwa
	div wa, 0x28
	ld (xbc + 2), wa
	muls wa, 0x28
	sub de, wa
	sll de, 3
	ld (xbc), de
	extz hl
	lda xbc, (xsp + 4)
	pushw hl
	cps ix, 2
	jr z, DrawFunc_Init_FontTable2
	cps ix, 1
	jr nz, DrawFunc_Init_FontTable0
	ld xwa, 0xEAB12C
	jr DrawFunc_Init_PushFontAndDraw

DrawFunc_Init_FontTable2:
	ld xwa, 0xEAB130
	jr DrawFunc_Init_PushFontAndDraw

DrawFunc_Init_FontTable0:
	ld xwa, 0xEAB134

DrawFunc_Init_PushFontAndDraw:
	push xwa
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld a, (xiz + 6)
	and a, 0x3F
	extz wa
	sla wa, 2
	lda_24 xbc, 0xeab004
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	st_dri3b W, 0xFD, 0x08, 0x01
	st_dri3b A, 0xFD, 0x04, 0x01
	lda xde, (xsp + 4)
	push xhl
	push_sd24w 0xA4, 0xEF, 0x03
	push_sd24w 0xA2, 0xEF, 0x03
	calr DrawText_QueueOrDirect
	pop xiz
	st_dri3b L, 0xFD, 0x0C, 0x01
	ret

DrawFunc_Init_Variant1:
	.byte 0xf3, 0xfd, 0xf4, 0xfe, 0x37
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15380792
	.byte 0xf3, 0xfd, 0x08, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xff
	ld	ix, (xiz+7)
	ld	l, (xiz+9)
	extz	hl
	lda	xbc, (xsp+260)
	ld	wa, ix
	extz	xwa
	div	wa, 40
	ld	(xbc+2), wa
	muls	wa, 40
	sub	ix, wa
	sll	ix, 3
	ld	(xbc), ix
	ld	a, (xiz+10)
	cp	a, e
	jr	z, 77
	cp	a, 128
	jr	nc, 10
	cp	e, 128
	jr	c, 5
	ldb	a, 128
	sub	e, 128
	cp	e, a
	jr	ule, 8
	ld	(xsp+4), 43
	sub	e, a
	jr	8
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
	ld	c, e
	extz	bc
	lda	xde, (xsp+5)
	cps	hl, 2
	jr	z, 12
	pushw	bc
	cps	hl, 1
	jr	nz, 17
	ld	xwa, 15380800
	jr	15
	pushw	bc
	pushw 234
	pushw 0xb144
	.ascii ":h,@H"
	.byte 0xb1, 0xea, 0x00
	.ascii "8:h#"
	pushw 0
	cps	hl, 2
	.byte 0x66, 0x0b
	cps	hl, 1
	.byte 0x6e, 0x0e
	ld	xwa, 15380812
	.byte 0x68, 0x0c
	ld	xwa, 15380816
	.byte 0x68, 0x05
	ld	xwa, 15380820
	push xwa
	.byte 0xbf, 0x0a, 0x30
	push xwa
	call	16714354
	.byte 0xbf, 0x0a, 0x37
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	.byte 0xf2, 0x04, 0xb0, 0xea, 0x31, 0xe3, 0x07, 0xe4
	.byte 0xe0, 0x23, 0xf3, 0xfd, 0x08, 0x01, 0x30
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	calr	-4987
	pop	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xf4, 0xfe, 0x37
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15380824
	.byte 0xf3, 0xfd, 0x08, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	ix, (xiz+2)
	extz	xix
	ld	de, (xiz+7)
	ld	l, (xiz+9)
	extz	hl
	lda	xbc, (xsp+260)
	ld	wa, de
	extz	xwa
	div	wa, 40
	ld	(xbc+2), wa
	muls	wa, 40
	sub	de, wa
	sll	de, 3
	ld	(xbc), de
	lda	xbc, (xsp+4)
	cps	hl, 2
	jr	z, 13
	cps	hl, 1
	jr	nz, 18
	.byte 0x94, 0x04
	ld	xwa, 15380832
	jr	16
	.byte 0x94, 0x04
	ld	xwa, 15380836
	jr	7
	.byte 0x94, 0x04
	ld	xwa, 15380840
	push	xwa
	push	xbc
	call	16714354
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15380484
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x23
	lda	xwa, (xsp+264)
	.byte 0xf3, 0xfd, 0x04, 0x01, 0x31
	lda	xde, (xsp+4)
	push	xhl
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	calr	-5149
	pop	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xf4, 0xfe, 0x37
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15380844
	.byte 0xf3, 0xfd, 0x08, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xff
	ld	l, (xiz+11)
	.byte 0xf3, 0xfd, 0x04, 0x01, 0x31
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	extz	de
	lda	xbc, (xsp+4)
	pushw	de
	cps	l, 2
	jr	z, 11
	cps	l, 1
	jr	nz, 14
	ld	xwa, 15380852
	jr	12
	ld	xwa, 15380856
	jr	5
	ld	xwa, 15380860
	push	xwa
	push	xbc
	call	16714354
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	lda_24	xbc, 15380740
	lds32	xhl, 0
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x27
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	calr	-5312
	pop	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xf4, 0xfe, 0x37
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15380864
	lda	xix, (xsp+264)
	lds	bc, 4
	ldirw
	ld	wa, (xiz+2)
	extz	xwa
	ld	e, (xiz+4)
	ld	c, (xiz+5)
	ld	a, (xwa)
	and	a, e
	ld	e, a
	ld	a, c
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xff
	ld	l, (xiz+11)
	lda	xbc, (xsp+260)
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	ld	a, (xiz+12)
	cp	a, e
	jr	z, 72
	cp	a, 128
	jr	nc, 10
	cp	e, 128
	jr	c, 5
	ldb	a, 128
	sub	e, 128
	cp	e, a
	jr	ule, 8
	ld	(xsp+4), 43
	sub	e, a
	jr	8
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
	extz	de
	lda	xbc, (xsp+5)
	pushw	de
	cps	l, 2
	jr	z, 11
	cps	l, 1
	jr	nz, 14
	ld	xwa, 15380872
	jr	12
	.byte 0x40
	.long LABEL_EAB18C
	jr	5
	ld	xwa, 15380880
	.ascii "89h#�"
	.byte 0x04
	ldw	bc, 11
	nop
	.byte 0xcf, 0xda, 0x66, 0x0b, 0xcf, 0xd9, 0x6e, 0x0e
	ld	xwa, 15380884
	.byte 0x68, 0x0c
	ld	xwa, 15380888
	.byte 0x68, 0x05
	ld	xwa, 15380892
	push xwa
	push xbc
	call	16714354
	.byte 0xbf, 0x0a, 0x37
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	.byte 0xf2, 0x04, 0xb1, 0xea, 0x31
	lds32	xhl, 0
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x27, 0xf3, 0xfd, 0x08
	.byte 0x01, 0x30
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	calr	-5554
	pop	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x37
	ret
	.byte 0xf3, 0xfd, 0xf4, 0xfe, 0x37
	push	xiz
	ld	xiz, xwa
	.byte 0x45
	.long Data_CharMapFormatBlock
	.byte 0xf3, 0xfd, 0x08, 0x01, 0x34
	lds	bc, 4
	ldirw
	ld	de, (xiz+2)
	extz	xde
	ld	l, (xiz+11)
	.byte 0xf3, 0xfd, 0x04, 0x01, 0x31
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	lda	xbc, (xsp+4)
	cps	l, 2
	jr	z, 13
	cps	l, 1
	jr	nz, 20
	.byte 0x92, 0x04
	ld	xwa, 15380904
	jr	18
	.byte 0x92, 0x04
	pushw 234
	pushw 45484
	push	xbc
	jr	9
	.byte 0x92, 0x04
	ld	xwa, 15380912
	push	xwa
	push	xbc
	call	16714354
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	lda_24	xbc, 15380740
	lds32	xhl, 0
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x27
	lda	xwa, (xsp+264)
	.byte 0xf3, 0xfd, 0x04, 0x01, 0x31
	lda	xde, (xsp+4)
	push	xhl
	.byte 0xd2, 0xa4, 0xef, 0x03, 0x04, 0xd2, 0xa2, 0xef, 0x03, 0x04
	calr	-5701
	pop	xiz
	.byte 0xf3, 0xfd, 0x0c, 0x01, 0x37
	ret

ColorBlit_WithPaletteSave:
	dec 8, xsp
	push_werp 0xFA
	ld xbc, xwa
	ld wa, (xbc + 2)
	extz xwa
	ld l, (xbc + 4)
	ld e, (xbc + 5)
	ld a, (xwa)
	and a, l
	ld l, a
	ld a, e
	and a, 0xF
	jr z, ColorBlit_PalSave_SkipShift
	srla l

ColorBlit_PalSave_SkipShift:
	sll l, 2
	extz hl
	add hl, hl
	ld xbc, (xbc + 7)
	st_dri3b B, 0x07, 0xE4, 0xEC
	lda xwa, (xsp + 2)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ld bc, (xde + 4)
	ld (xwa + 4), bc
	ld bc, (xde + 6)
	ld (xwa + 6), bc
	ld8_24 c, 0x03efa8
	ldfr_berp C, 0xFB
	sti8_24 0x03efa8, 0x01
	ld16_24 xbc, 0x03efa4
	calr ColorBlit
	ldto_berp A, 0xFB
	st8_24 0x03efa8, a
	pop_werp 0xFA
	inc 8, xsp
	ret

ColorBlit_Variant_ByteData:
	dec	8, xsp
	ld	xbc, xwa
	ld	wa, (xbc+2)
	extz	xwa
	ld	l, (xbc+4)
	ld	e, (xbc+5)
	ld	a, (xwa)
	and	a, l
	ld	l, a
	ld	a, e
	and	a, 15
	jr	z, 2
	.byte 0xcf, 0xff
	mul	l, 3
	extz	hl
	add	hl, hl
	ld	xbc, (xbc+7)
	exts	xhl
	add	xhl, xbc
	lda	xwa, (xsp)
	lda	xde, (xwa+2)
	ld	bc, (xhl)
	extz	xbc
	div	bc, 40
	ld	(xde), bc
	ld	bc, (xhl)
	extz	xbc
	div	bc, 40
	ld	bc, qbc
	sll	bc, 3
	ld	(xwa), bc
	ld	bc, (xde)
	add	bc, (xhl+4)
	ld	(xwa+6), bc
	ld	bc, (xhl+2)
	sll	bc, 3
	ld	de, (xwa)
	add	de, bc
	ld	(xwa+4), de
	ld16_24	bc, 257954
	calr	-11488
	inc	8, xsp
	ret
	dec	8, xsp
	ld	xbc, xwa
	ld	wa, (xbc+2)
	extz	xwa
	ld	l, (xbc+4)
	ld	e, (xbc+5)
	ld	a, (xwa)
	and	a, l
	ld	l, a
	ld	a, e
	and	a, 15
	jr	z, 2
	.byte 0xcf, 0xff
	sll	l, 2
	extz	hl
	add	hl, hl
	ld	xbc, (xbc+7)
	.byte 0xf3, 0x07, 0xe4, 0xec, 0x32
	lda	xwa, (xsp)
	ld	bc, (xde)
	ld	(xwa), bc
	ld	bc, (xde+2)
	ld	(xwa+2), bc
	ld	bc, (xde+4)
	ld	(xwa+4), bc
	ld	bc, (xde+6)
	ld	(xwa+6), bc
	ld16_24	bc, 257954
	calr	-11568
	inc	8, xsp
	ret

GetFrameSPSize:
	ld hl, wa
	extz xhl
	sll xhl, 3
	add xhl, 0x934000
	ld wa, (xhl)
	ld (xbc), wa
	ld wa, (xhl + 2)
	ld (xde), wa
	ret

; =============================================================================
; Font Glyph Table Access Functions
;
; The font glyph table is in ROM at 0x945C00 (Table Data ROM).
; Each entry is 16 bytes:
;   +0x00: word  char_width    (pixels per character)
;   +0x02: word  char_height   (pixels)
;   +0x04: word  descent       (below baseline)
;   +0x06: word  ascent        (above baseline)
;   +0x08: long  glyph_ptr     (pointer to 1bpp bitmap data)
;   +0x0C: long  kerning_ptr   (0 = fixed-width; else per-char width table)
;
; Lookup: entry_addr = 0x945C00 + (font_id << 4)
; =============================================================================

; GetCharHeight - Return character height for a font
; Input:  XWA = font_id
; Output: HL = character height in pixels
GetCharHeight:
	sll xwa, 4		; font_id * 16
	add xwa, 0x945C00	; + table base
	ld hl, (xwa + 2)	; height at offset +2
	ret

; GetCharDescent - Return character descent for a font
; Input:  XWA = font_id
; Output: HL = descent in pixels (below baseline)
GetCharDescent:
	sll xwa, 4		; font_id * 16
	add xwa, 0x945C00	; + table base
	ld hl, (xwa + 4)	; descent at offset +4
	ret

GetCenteredDelta:
	cp xwa, 0x7
	jr z, GetCenteredDelta_RetNeg1
	cp xwa, 0x5
	jr z, GetCenteredDelta_RetNeg1
	or xwa, xwa
	jr nz, GetCenteredDelta_RetZero

GetCenteredDelta_RetNeg1:
	ldw hl, 0xFFFF
	jr GetCenteredDelta_Return

GetCenteredDelta_RetZero:
	lds hl, 0

GetCenteredDelta_Return:
	ret

; =============================================================================
; ConvertStrings - Convert control-code strings to displayable characters
;
; Processes a null-terminated input string (XWA) and outputs displayable
; characters to the buffer (XBC). Handles:
;   - 0x7E escape prefix: next two bytes are hex digits forming a char code
;     e.g., 0x7E 0x33 0x41 → character 0x3A (colon)
;   - Characters < 0x20: mapped to 0x20 (space)
;   - Characters >= 0x20: copied as-is
;   - 0x00: null terminator (copied and returns)
;
; Input:
;   XWA = pointer to source string (null-terminated)
;   XBC = pointer to output buffer
; =============================================================================
ConvertStrings:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa

ConvertStrings_MainLoop:
	cp (xiz), 0x7E		; Check for escape prefix
	jr nz, ConvertStrings_CheckNull
	inc 1, xiz
	cp (xiz), 0x0
	jr z, ConvertStrings_NullTerminate
	ld a, (xiz)
	extz wa
	calr HexCharToNibble
	sll l, 4
	ld xwa, (xsp + 4)
	ld (xwa), l
	inc 1, xiz
	cp (xiz), 0x0
	jr z, ConvertStrings_NullTerminate
	ld a, (xiz)
	extz wa
	calr HexCharToNibble
	ld xwa, (xsp + 4)
	add (xwa), l
	jr ConvertStrings_AdvancePointer

ConvertStrings_NullTerminate:
	ld xwa, (xsp + 4)
	ld (xwa), 0x0
	jr ConvertStrings_PopAndReturn

ConvertStrings_CheckNull:
	cp (xiz), 0x0
	jr nz, ConvertStrings_CheckPrintable
	ld xwa, (xsp + 4)
	ld c, (xiz)
	ld (xwa), c

ConvertStrings_PopAndReturn:
	pop xiz
	inc 4, xsp
	ret

ConvertStrings_CheckPrintable:
	cp (xiz), 0x20
	jr nc, ConvertStrings_CopyChar
	ld xwa, (xsp + 4)
	ld (xwa), 0x20
	jr ConvertStrings_AdvancePointer

ConvertStrings_CopyChar:
	ld xwa, (xsp + 4)
	ld c, (xiz)
	ld (xwa), c

ConvertStrings_AdvancePointer:
	inc 1, xiz
	lds32 xwa, 1
	add (xsp + 4), xwa
	jr ConvertStrings_MainLoop

ConvertStringsEx:
	ld xde, xwa

ConvertStringsEx_Loop:
	cp (xde), 0x7E
	jr nz, ConvertStringsEx_CopyChar
	ld a, (xde)
	lda_dpi XBC, 0xE4
	stib_dpi 0xE4, 0x34
	addmi8 (xbc), 0x30
	jr ConvertStringsEx_Advance

ConvertStringsEx_CopyChar:
	ld a, (xde)
	ld (xbc), a
	cp (xde), 0x0
	ret z

ConvertStringsEx_Advance:
	inc 1, xde
	inc 1, xbc
	jr ConvertStringsEx_Loop

; =============================================================================
; CalcTotalWidth - Calculate pixel width of a rendered string
;
; Computes the total width in pixels that a string will occupy when rendered
; with the specified font. Supports both fixed-width and kerning-enabled fonts.
;
; For fixed-width fonts: width = char_count * char_width
; For kerning fonts: width = sum of per-character kerning values
;
; Characters are offset by 0x20 before kerning table lookup.
;
; Input:
;   XWA = pointer to null-terminated string
;   XBC = font_id
;
; Output:
;   HL = total width in pixels
; =============================================================================
CalcTotalWidth:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xbc
	ld xiz, xwa
	push xiz
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, xiz
	ld xbc, (xsp + 8)
	calr ConvertStrings
	ld xiz, (xsp + 12)
	sll xiz, 4
	add xiz, 0x945C00
	ld xwa, (xsp + 8)
	push xwa
	call Strlen
	inc 4, xsp
	ld xbc, (xiz + 12)
	or xbc, xbc
	jr nz, CalcTotalWidth_KerningLoop_Init
	mriw2 0x96, 0x4B
	ld iz, hl
	jr CalcTotalWidth_FreeAndReturn

CalcTotalWidth_KerningLoop_Init:
	lds iz, 0
	ld xix, xbc
	lds de, 0
	cps hl, 0
	jr le, CalcTotalWidth_FreeAndReturn

CalcTotalWidth_KerningLoop:
	ld xwa, (xsp + 4)
	ld_srib3 A, 0x07, 0xE0, 0xE8
	sub a, 0x20
	extz wa
	sla wa, 2
	st_dri3b D, 0x07, 0xF0, 0xE0
	ld a, (xix)
	extz wa
	add iz, wa
	ld xix, xbc
	inc 1, de
	cp de, hl
	jr lt, CalcTotalWidth_KerningLoop

CalcTotalWidth_FreeAndReturn:
	ld xwa, (xsp + 8)
	push xwa
	call Free
	inc 4, xsp
	ld hl, iz
	pop xiz
	lda xsp, (xsp + 12)
	ret

; =============================================================================
; WordwrapStrings - Find word-wrap break point for text layout
;
; Scans a string to find the longest substring that fits within a specified
; pixel width when rendered with the given font. Breaks at word boundaries
; (spaces, 0x20). Used for multi-line text layout.
;
; Input:
;   XWA = pointer to null-terminated string
;   XBC = font_id
;   DE  = maximum width in pixels
;
; Output:
;   HL = character offset of the word-wrap break point
; =============================================================================
WordwrapStrings:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 16), de
	ld (xsp + 18), xbc
	ld (xsp + 22), xwa
	ldw (xsp + 4), 0x0
	ldw (xsp + 10), 0x0
	ld xiz, (xsp + 22)
	push xiz
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	inc 6, xsp
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld (xsp + 6), xwa
	cp (xiz), 0x0
	jr z, Wordwrap_FreeAndReturn

Wordwrap_ScanWordStart:
	cp (xiz), 0x0
	jr z, Wordwrap_CheckSpaces

Wordwrap_ScanWordChars:
	cp (xiz), 0x20
	jr z, Wordwrap_CheckSpaces
	inc 1, xiz
	incm 1, (xsp + 4)
	cp (xiz), 0x0
	jr nz, Wordwrap_ScanWordChars

Wordwrap_CheckSpaces:
	cp (xiz), 0x0
	jr z, Wordwrap_MeasureWidth

Wordwrap_SkipSpaces:
	cp (xiz), 0x20
	jr nz, Wordwrap_MeasureWidth
	inc 1, xiz
	incm 1, (xsp + 4)
	cp (xiz), 0x0
	jr nz, Wordwrap_SkipSpaces

Wordwrap_MeasureWidth:
	ld xwa, (xsp + 22)
	push xwa
	ld xwa, (xsp + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 6)
	ld bc, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE4, 0x00
	ld xwa, (xsp + 6)
	ld xbc, (xsp + 18)
	calr CalcTotalWidth
	cp hl, (xsp + 16)
	jr gt, Wordwrap_CheckEndOfString
	ld wa, (xsp + 4)
	ld (xsp + 10), wa

Wordwrap_CheckEndOfString:
	cp (xiz), 0x0
	jr nz, Wordwrap_ScanWordStart

Wordwrap_FreeAndReturn:
	ld xwa, (xsp + 12)
	push xwa
	call Free
	inc 4, xsp
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 22)
	ret

; HexDigitToValue - Convert ASCII hex digit to 4-bit value
; Input:  A = ASCII character ('0'-'9', 'a'-'f', 'A'-'F')
; Output: L = 0x00-0x0F (value), or 0x00 if invalid
HexCharToNibble:
	cp a, 0x30		; '0'
	jr c, HexCharToNibble_CheckLower
	cp a, 0x39		; '9'
	jr ugt, HexCharToNibble_CheckLower
	sub a, 0x30		; '0'-'9' → 0-9
	ld l, a
	ret

HexCharToNibble_CheckLower:
	cp a, 0x61		; 'a'
	jr c, HexCharToNibble_CheckUpper
	cp a, 0x66		; 'f'
	jr ugt, HexCharToNibble_CheckUpper
	sub a, 0x57		; 'a'-'f' → 10-15
	ld l, a
	ret

HexCharToNibble_CheckUpper:
	cp a, 0x41		; 'A'
	jr c, HexCharToNibble_Invalid
	cp a, 0x46		; 'F'
	jr ugt, HexCharToNibble_Invalid
	sub a, 0x37		; 'A'-'F' → 10-15
	ld l, a
	ret

HexCharToNibble_Invalid:
	ldb l, 0x0		; Invalid → 0
	ret

FontGlyph_ByteData:
	ld	a, (xwa)
	extz	wa
	lda_24	xde, 15380916
	.byte 0xc3, 0x07, 0xe8, 0xe0, 0x21
	ld	(xbc), a
	ret
	ld	e, (xwa)
	cp	e, 32
	jr	z, 4
	cps	e, 0
	jr	nz, 5
	ld	a, (xwa)
	ld	(xbc), a
	ret
	lds	de, 0
	lda_24	xhl, 15380916
	ld	a, (xwa)
	.byte 0xc3, 0x07, 0xec, 0xe8, 0xf9
	jr	nz, 6
	ld	a, e
	ld	(xbc), a
	jr	8
	inc	1, de
	cp	de, 256
	jr	lt, -21
	cp	de, 256
	ret	nz
	ld	(xbc), 32
	ret

; =============================================================================
; InitPaletteRGB - Initialize 256-color palette from ROM data
;
; Copies palette RGB data from ROM (0xEB37DE) to RAM (0x0324FC).
; The palette data is stored as packed RGB bytes.
; =============================================================================
InitPaletteRGB:
	lda_24 xde, 0x0324fc
	lda_24 xwa, 0xeb37de
	ld xbc, xwa
	st_dri3b C, 0xE1, 0x00, 0x04

InitPaletteRGB_CopyLoop:
	ld_spil XWA, 0xE6
	st_dpil XWA, 0xEA
	cp xbc, xhl
	jr c, InitPaletteRGB_CopyLoop
	ret

SetPaletteRGB:
	exts xwa
	sll xwa, 2
	ld xde, 0x324FC
	add xde, xwa
	ld (xde), xbc
	ret

Table_LookupDword:
	exts xwa
	sll xwa, 2
	ld xbc, 0x324FC
	add xbc, xwa
	ld xhl, (xbc)
	ret

GetWallPaletteRGB:
	extz xwa
	sll xwa, 2
	ld xde, 0x3F1E4
	add xde, xwa
	ld xde, (xde)
	extz xbc
	sll xbc, 2
	add xde, xbc
	ld xhl, (xde)
	ret

InitializeRoot:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xFA44E2, 0xEADA92, 0xEAC9EE, 0x160
	RegObjTable 0x160000c, 0xFA58FB, 0xEAEBB0, 0xEAE7B6, 0x1c0
	RegObjTable 0x160000d, 0xFA5948, 0xEAFA6C, 0xEAEBB2, 0x1e0
	RegObjTabl 0x1600002, 0xFA496C, 0xc, 0xEAB2B4, 0x120
	RegObjTabl 0x1600002, 0xFA496C, 0xc, 0xEAB2E8, 0x420
	RegObjTabl 0x1600001, 0xFA48A9, 0x160, 0xEAFA6E, 0x100
	RegObjTabl 0x1600001, 0xFA48A9, 0x160, 0xEAFFF2, 0x400
	RegObjTabl 0x1600003, 0xFA4A18, 0xd, 0xEB3698, 0x140
	RegObjTabl 0x1600003, 0xFA4A18, 0xd, 0xEB36D0, 0x440
	RegObjTabl 0x1600010, 0xFA5995, 0x33, 0xEB3374, 0x0
	RegObjTabl 0x160000f, 0xFA62CB, 0x33, 0xEB346C, 0x300
	RegObjTabl 0x1600010, 0xFA5995, 0x9, 0xEB3444, 0xff
	RegObjTabl 0x160000f, 0xFA62CB, 0x9, 0xEB362A, 0x3ff

	RegMode 0x0, 0xeb, 0x3682, 0x0, 0x1200000, 0x1a00000

	RegTitle 0x0, 0xeb, 0x3688, 0x0, 0x1200000, 0x0
	RegTitle 0x0, 0xeb, 0x368e, 0xff, 0x1400009, 0xff0000

	lda xsp, (xsp + 14)
	ret


.macro _VGA_WRITE regnum, value
	.if \regnum <= 7
	lds wa, \regnum
	.else
	ldw wa, \regnum
	.endif
	.if \value <= 7
	lds bc, \value
	.else
	ldw bc, \value
	.endif
	calr _Write_VGA_Register
.endm


.macro _VGA_READ regnum
	.if \regnum <= 7
	lds wa, \regnum
	.else
	ldw wa, \regnum
	.endif
	calr _Read_VGA_Register
.endm


.macro _PALLETE_WRITE red, green, blue
	ldw wa, 0x3C9
	.if \red <= 7
	lds bc, \red
	.else
	ldw bc, \red
	.endif
	calr _Write_VGA_Register
	.if \green <= 7
	lds bc, \green
	.else
	ldw bc, \green
	.endif
	calr _Write_VGA_Register
	.if \blue <= 7
	lds bc, \blue
	.else
	ldw bc, \blue
	.endif
	calr _Write_VGA_Register
.endm


.macro _VGA_ATTRIBUTE field, value
	_VGA_WRITE 0x3C0, \field
	_VGA_WRITE 0x3C0, \value
.endm


.macro _VGA_SEQUENCER field, value
	_VGA_WRITE 0x3C4, \field
	_VGA_WRITE 0x3C5, \value
.endm


.macro _VGA_GFX_CONTROLLER field, value
	_VGA_WRITE 0x3CE, \field
	_VGA_WRITE 0x3CF, \value
.endm


.macro _VGA_COLOR_CRTC field, value
	_VGA_WRITE 0x3D4, \field
	_VGA_WRITE 0x3D5, \value
.endm


VGA_Initialize:
	dec 2, xsp
	push xiz

	_VGA_WRITE 0x3c3, 0x1
	_VGA_WRITE 0x3c2, 0xe3

	_VGA_SEQUENCER 0x0, 0x0
	_VGA_SEQUENCER 0x1, 0x21
	_VGA_SEQUENCER 0x0, 0x3
	_VGA_SEQUENCER 0x2, 0xf
	_VGA_SEQUENCER 0x3, 0x0
	_VGA_SEQUENCER 0x4, 0x6

	_VGA_GFX_CONTROLLER GC_ENABLE_SET_RESET, 0x0
	_VGA_GFX_CONTROLLER GC_DATA_ROTATE, 0x0
	_VGA_GFX_CONTROLLER GC_READ_MAP_SELECT, 0x0
	_VGA_GFX_CONTROLLER GC_GRAPHICS_MODE, 0x0
	_VGA_GFX_CONTROLLER GC_MISC_GRAPHICS, 0x1
	_VGA_GFX_CONTROLLER GC_BIT_MASK, 0xff

	_VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x0	; Unlock protected registers
	_VGA_COLOR_CRTC CRTC_OVERFLOW, 0x10
	_VGA_COLOR_CRTC CRTC_PRESET_ROW_SCAN, 0x0
	_VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 0x40
	_VGA_COLOR_CRTC CRTC_START_ADDR_HIGH, 0x0
	_VGA_COLOR_CRTC CRTC_START_ADDR_LOW, 0x0
	_VGA_COLOR_CRTC CRTC_VERT_DISP_END, 0xef
	_VGA_COLOR_CRTC CRTC_OFFSET, 0x14
	_VGA_COLOR_CRTC CRTC_UNDERLINE_LOC, 0x0
	_VGA_COLOR_CRTC CRTC_MODE_CONTROL, 0xe3
	_VGA_COLOR_CRTC CRTC_LINE_COMPARE, 0xff

	_VGA_READ 0x3da
	_VGA_ATTRIBUTE 0x0, 0x0
	_VGA_ATTRIBUTE 0x1, 0x1
	_VGA_ATTRIBUTE 0x2, 0x2
	_VGA_ATTRIBUTE 0x3, 0x3
	_VGA_ATTRIBUTE 0x4, 0x4
	_VGA_ATTRIBUTE 0x5, 0x5
	_VGA_ATTRIBUTE 0x6, 0x14
	_VGA_ATTRIBUTE 0x7, 0x7
	_VGA_ATTRIBUTE 0x8, 0x38
	_VGA_ATTRIBUTE 0x9, 0x39
	_VGA_ATTRIBUTE 0xa, 0x3a
	_VGA_ATTRIBUTE 0xb, 0x3b
	_VGA_ATTRIBUTE 0xc, 0x3c
	_VGA_ATTRIBUTE 0xd, 0x3d
	_VGA_ATTRIBUTE 0xe, 0x3e
	_VGA_ATTRIBUTE 0xf, 0x3f
	_VGA_ATTRIBUTE ATTR_MODE_CONTROL, 0x1
	_VGA_ATTRIBUTE ATTR_OVERSCAN_COLOR, 0x0
	_VGA_ATTRIBUTE ATTR_COLOR_PLANE_ENABLE, 0xf
	_VGA_ATTRIBUTE ATTR_HORIZ_PIXEL_PAN, 0x0
	_VGA_ATTRIBUTE 0x34, 0x0	; ATTR_COLOR_SELECT + 20h (Palette Address Source bit)

	_VGA_SEQUENCER 0x6, 0x1

	_VGA_COLOR_CRTC CRTC_HORIZ_TOTAL, 0x50
	_VGA_COLOR_CRTC CRTC_HORIZ_DISP_END, 0x27
	_VGA_COLOR_CRTC CRTC_START_HORIZ_RETRACE, 0x28
	_VGA_COLOR_CRTC CRTC_END_HORIZ_RETRACE, 0x29
	_VGA_COLOR_CRTC CRTC_VERT_TOTAL, 0xf3
	_VGA_COLOR_CRTC CRTC_OVERFLOW, 0x0
	_VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 0x0
	_VGA_COLOR_CRTC CRTC_VERT_RETRACE_START, 0xf2
	_VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x3
	_VGA_COLOR_CRTC CRTC_START_VERT_BLANK, 0xef
	_VGA_COLOR_CRTC CRTC_END_VERT_BLANK, 0xf3

	_VGA_SEQUENCER 0x8, 0x1
	_VGA_SEQUENCER 0xd, 0x3
	call Get_Region_Code
	cps l, 4
	jr nz, VGA_Init_ExtSeq0F_44

	; For byte-matching purposes, the following instructions
	; are equivalent to: _VGA_SEQUENCER 0fh, 000h
	_VGA_WRITE 0x3c4, 0xf
	ldw wa, 0x3C5
	lds bc, 0
	; but omitting the final "CALR _Write_VGA_Register"

	jr VGA_Init_WriteExtSeq


VGA_Init_ExtSeq0F_44:
	; For byte-matching purposes, the following instructions
	; are equivalent to: _VGA_SEQUENCER 0fh, 044h
	_VGA_WRITE 0x3c4, 0xf
	ldw wa, 0x3C5
	ldw bc, 0x44
VGA_Init_WriteExtSeq:
	calr _Write_VGA_Register

VGA_Init_FinalRegs:
	_VGA_SEQUENCER 0x13, 0x1

	_VGA_COLOR_CRTC 0x19, 0x0	; MN89304-specific register
	_VGA_COLOR_CRTC 0x1a, 0x10	; MN89304-specific register

	_VGA_SEQUENCER 0x7, 0x20
	_VGA_SEQUENCER 0x6, 0x0

	_VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x80	; Lock protected registers 0-7

	_VGA_WRITE 0x3c6, 0xff
	_VGA_WRITE 0x3c8, 0x0

	ldw (xsp + 4), 0x0

VGA_Palette_Loop:
	ld wa, (xsp + 4)
	sll wa, 2
	ldada xbc, 58344
	ld iz, wa
	extz xiz
	add xiz, xbc
	bitm 3, (xiz)
	jr z, VGA_Palette_LowNibble
	cp (xiz), 0xF0
	jr nc, VGA_Palette_HighNibble
	ld a, (xiz)
	srl a, 4
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_Palette_WriteRed

VGA_Palette_HighNibble:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3C9
	jr VGA_Palette_WriteRed

VGA_Palette_LowNibble:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3C9

VGA_Palette_WriteRed:
	calr _Write_VGA_Register
	ld e, (xiz + 1)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_Palette_GreenLow
	cp e, 0xF0
	jr nc, VGA_Palette_GreenHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_Palette_WriteGreen

VGA_Palette_GreenHigh:
	ldw wa, 0x3C9
	jr VGA_Palette_WriteGreen

VGA_Palette_GreenLow:
	ldw wa, 0x3C9

VGA_Palette_WriteGreen:
	calr _Write_VGA_Register
	ld e, (xiz + 2)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_Palette_BlueLow
	cp e, 0xF0
	jr nc, VGA_Palette_BlueHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_Palette_WriteBlue

VGA_Palette_BlueHigh:
	ldw wa, 0x3C9
	jr VGA_Palette_WriteBlue

VGA_Palette_BlueLow:
	ldw wa, 0x3C9

VGA_Palette_WriteBlue:
	calr _Write_VGA_Register
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x100
	jrl c, VGA_Palette_Loop
	calr VGA_ConfigExtSequencer
	calr VGA_ClearVRAM
	_VGA_SEQUENCER 0x1, 0x1
	pop xiz
	inc 2, xsp
	ret

VGA_Stub_1:
	ret

VGA_Stub_2:
	ret

VGA_Stub_3:
	ret

VGA_ClearVRAM:
	pushw 0x9600
	pushw 0x0
	pushw 0x1A
	pushw 0x0
	call Memset
	pushw 0x9600
	pushw 0x0
	lda_24 xwa, 0x1a9600                  ; Is this a second video page?
	push xwa
	call Memset
	lda xsp, (xsp + 16)
	ret

_Write_VGA_Register:
	lds de, 0

VGA_WriteReg_Delay:
	inc 1, de
	cp de, 0x80
	jr c, VGA_WriteReg_Delay
	extz xwa
	ld xde, 0x170000
	add xde, xwa
	ld (xde), c
	ret

_Read_VGA_Register:
	extz xwa
	ld xbc, 0x170000
	add xbc, xwa
	ld l, (xbc)
	ret

AllBOut:
	pushw 0x9600
	pushw 0x4
	pushw 0x3C00
	pushw 0x1A
	pushw 0x0
	call Mem_Copy
	pushw 0x9600
	lda_24 xwa, 0x04d200
	push xwa
	lda_24 xwa, 0x1a9600                  ; Is this a second video page?
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	ret

DisplayBuffer_Process:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xwa
	ld xbc, (xsp + 12)
	ld wa, (xbc)
	srl wa, 1
	add wa, wa
	extz xwa
	ld (xsp + 8), xwa
	ld wa, (xbc + 4)
	srl wa, 1
	add wa, wa
	extz xwa
	ld (xsp + 4), xwa
	ld xwa, (xsp + 8)
	sub (xsp + 4), xwa
	lds32 xwa, 2
	add (xsp + 4), xwa
	ld iz, (xbc + 2)
	extz xiz
	jr DisplayBuf_CheckEvenRowEnd

DisplayBuf_CopyEvenRow:
	ld xwa, (xsp + 4)
	pushw wa
	ld xwa, xiz
	sll xwa, 2
	add xwa, xiz
	sll xwa, 6
	add xwa, (xsp + 10)
	ld xbc, 0x43C00
	add xbc, xwa
	push xbc
	srl xwa, 1
	add xwa, xwa
	ld xbc, 0x1A0000
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, xiz

DisplayBuf_CheckEvenRowEnd:
	ld xwa, (xsp + 12)
	ld wa, (xwa + 6)
	srl wa, 1
	extz xwa
	cp xiz, xwa
	jr ule, DisplayBuf_CopyEvenRow
	ld xiz, xwa
	jr DisplayBuf_CheckOddRowEnd

DisplayBuf_CopyOddRow:
	ld xwa, (xsp + 4)
	pushw wa
	ld xwa, xiz
	sll xwa, 2
	add xwa, xiz
	sll xwa, 6
	add xwa, (xsp + 10)
	ld xbc, 0x43C00
	add xbc, xwa
	push xbc
	srl xwa, 1
	add xwa, xwa
	ld xbc, 0x1A0000
	add xbc, xwa
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, xiz

DisplayBuf_CheckOddRowEnd:
	ld xwa, (xsp + 12)
	ld wa, (xwa + 6)
	extz xwa
	cp xiz, xwa
	jr ule, DisplayBuf_CopyOddRow
	pop xiz
	lda xsp, (xsp + 12)
	ret


; =============================================================================
; VGA_ScreenUnblank (VGA_ScreenUnblank) - Enable display output
;
; Writes VGA Sequencer register 01h = 01h (screen on, no blanking).
; Sequencer register 01h bit 5: 0=display on, 1=display blanked.
; Value 0x01 = 8-dot character clocks, display active.
; =============================================================================
VGA_ScreenUnblank:
	; For byte-matching purposes:
	; This is equivalent to:
	;
	; _VGA_SEQUENCER 01h, 001h
	; RET
	;
	_VGA_WRITE 0x3c4, 0x1
	ldw wa, 0x3C5
	lds bc, 1
	jrl _Write_VGA_Register

; =============================================================================
; VGA_ScreenBlank (VGA_ScreenBlank) - Blank display output
;
; Writes VGA Sequencer register 01h = 21h (screen blanked).
; Bit 5 = 1: blanks display during VRAM updates to prevent tearing.
; Used during large screen updates and palette changes.
; =============================================================================
VGA_ScreenBlank:
	; For byte-matching purposes:
	; This is equivalent to:
	;
	; _VGA_SEQUENCER 01h, 021h
	; RET
	;
	_VGA_WRITE 0x3c4, 0x1
	ldw wa, 0x3C5
	ldw bc, 0x21
	jrl _Write_VGA_Register


VGA_WritePaletteEntry:
	push xiz
	ld xiz, xbc
	ld c, a
	extz bc
	ldw wa, 0x3C8
	calr _Write_VGA_Register
	bitm 3, (xiz)
	jr z, VGA_WritePalEntry_RedLow
	cp (xiz), 0xF0
	jr nc, VGA_WritePalEntry_RedHigh
	ld a, (xiz)
	srl a, 4
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteRed

VGA_WritePalEntry_RedHigh:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteRed

VGA_WritePalEntry_RedLow:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3C9

VGA_WritePalEntry_WriteRed:
	calr _Write_VGA_Register
	ld e, (xiz + 1)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_WritePalEntry_GreenLow
	cp e, 0xF0
	jr nc, VGA_WritePalEntry_GreenHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteGreen

VGA_WritePalEntry_GreenHigh:
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteGreen

VGA_WritePalEntry_GreenLow:
	ldw wa, 0x3C9

VGA_WritePalEntry_WriteGreen:
	calr _Write_VGA_Register
	ld e, (xiz + 2)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_WritePalEntry_BlueLow
	cp e, 0xF0
	jr nc, VGA_WritePalEntry_BlueHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteBlue

VGA_WritePalEntry_BlueHigh:
	ldw wa, 0x3C9
	jr VGA_WritePalEntry_WriteBlue

VGA_WritePalEntry_BlueLow:
	ldw wa, 0x3C9

VGA_WritePalEntry_WriteBlue:
	calr _Write_VGA_Register
	pop xiz
	ret

VGA_CRTCTiming_ByteData:
	dec	4, xsp
	push qiz
	ld	(xsp+2), xwa
	.byte 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89
	extz	wa
	ld	xbc, (xsp+2)
	calr	-175
	lds32	xwa, 4
	add	(xsp+2), xwa
	.byte 0xc7, 0xfb, 0x61
	jr	-21
	ldw	wa, 964
	lds	bc, 6
	calr	-485
	ldw	wa, 965
	lds	bc, 1
	calr	-493
	ldw	wa, 964
	ldw	bc, 9
	calr	-502
	ldw	wa, 965
	lds	bc, 4
	calr	-510
	ldw	wa, 964
	ldw	bc, 10
	calr	-519
	ldw	wa, 965
	ldw	bc, 16
	calr	-528
	ldw	wa, 964
	ldw	bc, 11
	calr	-537
	ldw	wa, 965
	ldw	bc, 23
	calr	-546
	ldw	wa, 964
	ldw	bc, 12
	calr	-555
	ldw	wa, 965
	lds	bc, 5
	calr	-563
	ldw	wa, 964
	ldw	bc, 9
	calr	-572
	ldw	wa, 965
	lds	bc, 6
	calr	-580
	ldw	wa, 964
	ldw	bc, 10
	calr	-589
	ldw	wa, 965
	ldw	bc, 37
	calr	-598
	ldw	wa, 964
	ldw	bc, 11
	calr	-607
	ldw	wa, 965
	ldw	bc, 19
	calr	-616
	ldw	wa, 964
	ldw	bc, 12
	calr	-625
	ldw	wa, 965
	ldw	bc, 8
	calr	-634
	ldw	wa, 964
	ldw	bc, 9
	calr	-643
	ldw	wa, 965
	lds	bc, 0
	calr	-651
	ldw	wa, 964
	ldw	bc, 10
	calr	-660
	ldw	wa, 965
	ldw	bc, 28
	calr	-669
	ldw	wa, 964
	ldw	bc, 11
	calr	-678
	ldw	wa, 965
	ldw	bc, 17
	calr	-687
	ldw	wa, 964
	ldw	bc, 12
	calr	-696
	ldw	wa, 965
	lds	bc, 3
	calr	-704
	ldw	wa, 964
	ldw	bc, 9
	calr	-713
	ldw	wa, 965
	lds	bc, 2
	calr	-721
	ldw	wa, 964
	ldw	bc, 10
	calr	-730
	ldw	wa, 965
	lds	bc, 5
	calr	-738
	ldw	wa, 964
	ldw	bc, 11
	calr	-747
	ldw	wa, 965
	ldw	bc, 17
	calr	-756
	ldw	wa, 964
	ldw	bc, 12
	calr	-765
	ldw	wa, 965
	lds	bc, 3
	calr	-773
	ldw	wa, 964
	ldw	bc, 9
	calr	-782
	ldw	wa, 965
	ldw	bc, 8
	calr	-791
	ldw	wa, 964
	ldw	bc, 10
	calr	-800
	ldw	wa, 965
	ldw	bc, 170
	calr	-809
	ldw	wa, 964
	ldw	bc, 11
	calr	-818
	ldw	wa, 965
	ldw	bc, 16
	calr	-827
	ldw	wa, 964
	ldw	bc, 12
	calr	-836
	ldw	wa, 965
	ldw	bc, 8
	calr	-845
	ldw	wa, 964
	ldw	bc, 9
	calr	-854
	ldw	wa, 965
	ldw	bc, 10
	calr	-863
	ldw	wa, 964
	ldw	bc, 10
	calr	-872
	ldw	wa, 965
	lds	bc, 1
	calr	-880
	ldw	wa, 964
	ldw	bc, 11
	calr	-889
	ldw	wa, 965
	ldw	bc, 19
	calr	-898
	ldw	wa, 964
	ldw	bc, 12
	calr	-907
	ldw	wa, 965
	lds	bc, 6
	calr	-915
	ldw	wa, 964
	ldw	bc, 9
	calr	-924
	ldw	wa, 965
	ldw	bc, 13
	calr	-933
	ldw	wa, 964
	ldw	bc, 10
	calr	-942
	ldw	wa, 965
	lds	bc, 1
	calr	-950
	ldw	wa, 964
	ldw	bc, 9
	calr	-959
	ldw	wa, 965
	ldw	bc, 12
	calr	-968
	ldw	wa, 964
	ldw	bc, 10
	calr	-977
	ldw	wa, 965
	lds	bc, 0
	calr	-985
	ldw	wa, 964
	ldw	bc, 11
	calr	-994
	ldw	wa, 965
	ldw	bc, 37
	calr	-1003
	ldw	wa, 964
	ldw	bc, 12
	calr	-1012
	ldw	wa, 965
	ldw	bc, 12
	calr	-1021
	ldw	wa, 964
	ldw	bc, 9
	calr	-1030
	ldw	wa, 965
	ldw	bc, 15
	calr	-1039
	ldw	wa, 964
	ldw	bc, 10
	calr	-1048
	ldw	wa, 965
	ldw	bc, 17
	calr	-1057
	ldw	wa, 964
	ldw	bc, 9
	calr	-1066
	ldw	wa, 965
	ldw	bc, 14
	calr	-1075
	ldw	wa, 964
	ldw	bc, 10
	calr	-1084
	ldw	wa, 965
	lds	bc, 0
	calr	-1092
	ldw	wa, 964
	ldw	bc, 11
	calr	-1101
	ldw	wa, 965
	ldw	bc, 51
	calr	-1110
	ldw	wa, 964
	ldw	bc, 12
	calr	-1119
	ldw	wa, 965
	ldw	bc, 8
	calr	-1128
	ldw	wa, 964
	ldw	bc, 9
	calr	-1137
	ldw	wa, 965
	ldw	bc, 17
	calr	-1146
	ldw	wa, 964
	ldw	bc, 10
	calr	-1155
	ldw	wa, 965
	ldw	bc, 247
	calr	-1164
	ldw	wa, 964
	ldw	bc, 9
	calr	-1173
	ldw	wa, 965
	ldw	bc, 16
	calr	-1182
	ldw	wa, 964
	ldw	bc, 10
	calr	-1191
	ldw	wa, 965
	ldw	bc, 251
	calr	-1200
	ldw	wa, 964
	ldw	bc, 11
	calr	-1209
	ldw	wa, 965
	ldw	bc, 34
	calr	-1218
	ldw	wa, 964
	ldw	bc, 12
	calr	-1227
	ldw	wa, 965
	ldw	bc, 14
	calr	-1236
	ldw	wa, 964
	ldw	bc, 9
	calr	-1245
	ldw	wa, 965
	lds	bc, 1
	calr	-1253
	ldw	wa, 964
	ldw	bc, 12
	calr	-1262
	ldw	wa, 965
	ldw	bc, 100
	calr	-1271
	ldw	wa, 964
	ldw	bc, 9
	calr	-1280
	ldw	wa, 965
	lds	bc, 3
	calr	-1288
	ldw	wa, 964
	ldw	bc, 12
	calr	-1297
	ldw	wa, 965
	ldw	bc, 9
	calr	-1306
	ldw	wa, 964
	ldw	bc, 9
	calr	-1315
	ldw	wa, 965
	lds	bc, 5
	calr	-1323
	ldw	wa, 964
	ldw	bc, 12
	calr	-1332
	ldw	wa, 965
	ldw	bc, 43
	calr	-1341
	ldw	wa, 964
	ldw	bc, 9
	calr	-1350
	ldw	wa, 965
	lds	bc, 7
	calr	-1358
	ldw	wa, 964
	ldw	bc, 12
	calr	-1367
	ldw	wa, 965
	ldw	bc, 88
	calr	-1376
	ldw	wa, 964
	ldw	bc, 9
	calr	-1385
	ldw	wa, 965
	ldw	bc, 9
	calr	-1394
	ldw	wa, 964
	ldw	bc, 12
	calr	-1403
	ldw	wa, 965
	lds	bc, 7
	calr	-1411
	ldw	wa, 964
	ldw	bc, 9
	calr	-1420
	ldw	wa, 965
	ldw	bc, 11
	calr	-1429
	ldw	wa, 964
	ldw	bc, 12
	calr	-1438
	ldw	wa, 965
	lds	bc, 1
	calr	-1446
	ldw	wa, 964
	ldw	bc, 9
	calr	-1455
	ldw	wa, 965
	ldw	bc, 13
	calr	-1464
	ldw	wa, 964
	ldw	bc, 12
	calr	-1473
	ldw	wa, 965
	ldw	bc, 13
	calr	-1482
	ldw	wa, 964
	ldw	bc, 9
	calr	-1491
	ldw	wa, 965
	ldw	bc, 15
	calr	-1500
	ldw	wa, 964
	ldw	bc, 12
	calr	-1509
	ldw	wa, 965
	ldw	bc, 58
	calr	-1518
	ldw	wa, 964
	ldw	bc, 9
	calr	-1527
	ldw	wa, 965
	ldw	bc, 17
	calr	-1536
	ldw	wa, 964
	ldw	bc, 12
	calr	-1545
	ldw	wa, 965
	ldw	bc, 12
	calr	-1554
	ldw	wa, 964
	lds	bc, 6
	calr	-1562
	ldw	wa, 965
	lds	bc, 0
	jrl	-1570

VGA_ConfigExtSequencer:
	_VGA_SEQUENCER 0x6, 0x1

	_VGA_SEQUENCER 0x9, 0x4
	_VGA_SEQUENCER 0xa, 0x10
	_VGA_SEQUENCER 0xb, 0x13
	_VGA_SEQUENCER 0xc, 0x5

	_VGA_SEQUENCER 0x9, 0x6
	_VGA_SEQUENCER 0xa, 0x15
	_VGA_SEQUENCER 0xb, 0x64
	_VGA_SEQUENCER 0xc, 0x7

	_VGA_SEQUENCER 0x9, 0x0
	_VGA_SEQUENCER 0xa, 0x1c
	_VGA_SEQUENCER 0xb, 0x11
	_VGA_SEQUENCER 0xc, 0x3

	_VGA_SEQUENCER 0x9, 0x2
	_VGA_SEQUENCER 0xa, 0x5
	_VGA_SEQUENCER 0xb, 0x11
	_VGA_SEQUENCER 0xc, 0x3

	_VGA_SEQUENCER 0x9, 0x8
	_VGA_SEQUENCER 0xa, 0x92
	_VGA_SEQUENCER 0xb, 0x13
	_VGA_SEQUENCER 0xc, 0x8

	_VGA_SEQUENCER 0x9, 0xa
	_VGA_SEQUENCER 0xa, 0x1
	_VGA_SEQUENCER 0xb, 0x14
	_VGA_SEQUENCER 0xc, 0x6

	_VGA_SEQUENCER 0x9, 0xd
	_VGA_SEQUENCER 0xa, 0x1

	_VGA_SEQUENCER 0x9, 0xc
	_VGA_SEQUENCER 0xa, 0x0
	_VGA_SEQUENCER 0xb, 0x72
	_VGA_SEQUENCER 0xc, 0x9

	_VGA_SEQUENCER 0x9, 0xf
	_VGA_SEQUENCER 0xa, 0x11

	_VGA_SEQUENCER 0x9, 0xe
	_VGA_SEQUENCER 0xa, 0x0
	_VGA_SEQUENCER 0xb, 0x13
	_VGA_SEQUENCER 0xc, 0x8

	_VGA_SEQUENCER 0x9, 0x11
	_VGA_SEQUENCER 0xa, 0xff

	_VGA_SEQUENCER 0x9, 0x10
	_VGA_SEQUENCER 0xa, 0xfe
	_VGA_SEQUENCER 0xb, 0x73
	_VGA_SEQUENCER 0xc, 0xf

	_VGA_SEQUENCER 0x9, 0x1
	_VGA_SEQUENCER 0xc, 0x74

	_VGA_SEQUENCER 0x9, 0x3
	_VGA_SEQUENCER 0xc, 0x9

	_VGA_SEQUENCER 0x9, 0x5
	_VGA_SEQUENCER 0xc, 0x2b

	_VGA_SEQUENCER 0x9, 0x7
	_VGA_SEQUENCER 0xc, 0x68

	_VGA_SEQUENCER 0x9, 0x9
	_VGA_SEQUENCER 0xc, 0x5

	_VGA_SEQUENCER 0x9, 0xb
	_VGA_SEQUENCER 0xc, 0x1

	_VGA_SEQUENCER 0x9, 0xd
	_VGA_SEQUENCER 0xc, 0xc

	_VGA_SEQUENCER 0x9, 0xf
	_VGA_SEQUENCER 0xc, 0x3a

	_VGA_SEQUENCER 0x9, 0x11
	_VGA_SEQUENCER 0xc, 0xd

	; For byte-matching purposes:
	; This is equivalent to:
	;
	; _VGA_SEQUENCER 06h, 000h
	; RET
	;
	_VGA_WRITE 0x3c4, 0x6
	ldw wa, 0x3C5
	lds bc, 0
	jrl _Write_VGA_Register


; who calls here?
VGA_ConfigExtSequencer_Alt:
	_VGA_SEQUENCER 0x6, 0x1
	_VGA_SEQUENCER 0x9, 0x4
	_VGA_SEQUENCER 0xa, 0x10
	_VGA_SEQUENCER 0xb, 0x21
	_VGA_WRITE 0x3c5, 0x24
	_VGA_SEQUENCER 0xc, 0x5

	_VGA_SEQUENCER 0x9, 0x6
	_VGA_SEQUENCER 0xa, 0x15
	_VGA_SEQUENCER 0xb, 0x64
	_VGA_SEQUENCER 0xc, 0x7

	_VGA_SEQUENCER 0x9, 0x0
	_VGA_SEQUENCER 0xa, 0x1c
	_VGA_SEQUENCER 0xb, 0x21
	_VGA_WRITE 0x3c5, 0x12
	_VGA_SEQUENCER 0xc, 0x3

	_VGA_SEQUENCER 0x9, 0x2
	_VGA_SEQUENCER 0xa, 0x5
	_VGA_SEQUENCER 0xb, 0x22
	_VGA_WRITE 0x3c5, 0x11
	_VGA_SEQUENCER 0xc, 3

	_VGA_SEQUENCER 0x9, 0x8
	_VGA_SEQUENCER 0xa, 0x92
	_VGA_SEQUENCER 0xb, 0x73
	_VGA_WRITE 0x3c5, 0x13
	_VGA_SEQUENCER 0xc, 0x8

	_VGA_SEQUENCER 0x9, 0xa
	_VGA_SEQUENCER 0xa, 0x1
	_VGA_SEQUENCER 0xb, 0x24
	_VGA_WRITE 0x3c5, 0x32
	_VGA_SEQUENCER 0xc, 0x7

	_VGA_SEQUENCER 0x9, 0xd
	_VGA_SEQUENCER 0xa, 0x0

	_VGA_SEQUENCER 0x9, 0xc
	_VGA_SEQUENCER 0xa, 0x1
	_VGA_SEQUENCER 0xb, 0x27
	_VGA_WRITE 0x3c5, 0x35
	_VGA_SEQUENCER 0xc, 0xd

	_VGA_SEQUENCER 0x9, 0xf
	_VGA_SEQUENCER 0xa, 0x11

	_VGA_SEQUENCER 0x9, 0xe
	_VGA_SEQUENCER 0xa, 0x0
	_VGA_SEQUENCER 0xb, 0x32
	_VGA_SEQUENCER 0xc, 0x8

	_VGA_SEQUENCER 0x9, 0x11
	_VGA_SEQUENCER 0xa, 0x33

	_VGA_SEQUENCER 0x9, 0x10
	_VGA_SEQUENCER 0xa, 0x33
	_VGA_SEQUENCER 0xb, 0x25
	_VGA_SEQUENCER 0xc, 0xf

	_VGA_SEQUENCER 0x9, 0x1
	_VGA_SEQUENCER 0xc, 0x74

	_VGA_SEQUENCER 0x9, 0x3
	_VGA_SEQUENCER 0xc, 0xa

	_VGA_SEQUENCER 0x9, 0x5
	_VGA_SEQUENCER 0xc, 0x2c

	_VGA_SEQUENCER 0x9, 0x7
	_VGA_SEQUENCER 0xc, 0x69

	_VGA_SEQUENCER 0x9, 0x9
	_VGA_SEQUENCER 0xc, 0x5

	_VGA_SEQUENCER 0x9, 0xb
	_VGA_SEQUENCER 0xc, 0x1

	_VGA_SEQUENCER 0x9, 0xd
	_VGA_SEQUENCER 0xc, 0xd

	_VGA_SEQUENCER 0x9, 0xf
	_VGA_SEQUENCER 0xc, 0x3b

	_VGA_SEQUENCER 0x9, 0x11
	_VGA_SEQUENCER 0xc, 0x8

	; For byte-matching purposes:
	; This is equivalent to:
	;
	; _VGA_SEQUENCER 06h, 000h
	; RET
	;
	_VGA_WRITE 0x3c4, 0x6
	ldw wa, 0x3C5
	lds bc, 0
	jrl _Write_VGA_Register


BitMapOut:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xwa
	ld xbc, (xsp + 16)
	lda xwa, (xbc + 14)
	ld (xsp + 8), xwa
	ld (xsp + 4), xbc
	ld xwa, xbc
	ld xwa, (xwa + 10)
	add (xsp + 4), xwa
	ldw wa, 0x3C8
	lds bc, 0
	calr _Write_VGA_Register
	lds32 xiz, 0

	.include "ui/bitmap_out_routines.s"
	.include "ui/ui_mode_handlers.s"
PmBankScreenProc:
	st_dri3b L, 0xFD, 0xE8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x01
	cp xiz, 0x1C00007
	jrl z, PmBank_OK
	cp xiz, 0x1C20002
	jrl z, PmBank_BankChanged
	cp xiz, 0x1C0000F
	jrl z, PmBank_Confirm
	cp xiz, 0x1C0000E
	jrl z, PmBank_Select
	cp xiz, 0x1C0000D
	jr z, PmBank_Paint
	cp xiz, 0x1E2000E
	jr z, PmBank_EnumNotify
	cp xiz, 0x1C0000B
	jr z, PmBank_Show
	cp xiz, 0x1C00001
	jrl nz, PmBank_Default
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr PmBank_ForwardToHandler

PmBank_Show:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld xwa, 0x1420008
	ld xbc, 0x1E2000F
	lds32 xde, 0
	jrl PmBank_DispatchBankSelect

PmBank_EnumNotify:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x0114)
	ldfr_berp A, 0xFB
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1C0000E
	call SendEvent
	jrl PmBank_ReturnZero

PmBank_Paint:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PmBank_ForwardToHandler:
	call InheritedProc
	jrl PmBank_ReturnZero

PmBank_Select:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 52)
	ld xbc, (xhl)
	lda xde, (xwa + 48)
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), wa
	ld xbc, (xde)
	ld_sril XWA, (xsp + 0x0114)
	extz wa
	ld (xbc), wa
	ld xwa, (xhl)
	lda_24 xbc, 0xecfdb6
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x08, 0x01
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr PmBank_Select_DrawFirstRow

PmBank_Select_RightSide:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

PmBank_Select_DrawFirstRow:
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	st_dri3l XWA, 0xFD, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1E20010
	ld_sril XDE, (xsp + 0x0114)
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	lda_24 xbc, 0xecfdb6
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x08, 0x01
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_Select_SecondRightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr PmBank_Select_DrawSecondRow

PmBank_Select_SecondRightSide:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

PmBank_Select_DrawSecondRow:
	ldw bc, 0xC1
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	exts xwa
	st_dri3l XWA, 0xFD, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1E20010
	ld_sril XDE, (xsp + 0x0114)
	jrl PmBank_DispatchBankSelect

PmBank_Confirm:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ldi_berp 0xFB, 0

PmBank_Confirm_Loop:
	lds32 xwa, 0
	ldto_berp A, 0xFB
	st_dri3l XWA, 0xFD, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1E20010
	ld_sril XDE, (xsp + 0x0114)
	call MainFuncCall
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x09
	jr ule, PmBank_Confirm_Loop
	jrl PmBank_ReturnZero

PmBank_BankChanged:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), 0xFF
	ld (xsp + 6), 0xF5
	ld xbc, (xhl + 48)
	ld_sril XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	cp wa, (xbc)
	jr nz, PmBank_BankChanged_Lookup
	ld (xsp + 4), 0x0
	ld (xsp + 6), 0x7

PmBank_BankChanged_Lookup:
	ld_sril XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0xecfdb6
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	call DrawEditSw
	ld_sril XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0xecfdb6
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x08, 0x01
	call GetEditSwPoint
	st_dri3b B, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_BankChanged_RightSide
	ldw (xde), 0x8
	ldw (xwa), 0x1E
	jr PmBank_BankChanged_DrawSlot

PmBank_BankChanged_RightSide:
	ldw (xde), 0xA3
	ldw (xwa), 0xBE

PmBank_BankChanged_DrawSlot:
	decm 8, (xbc)
	ld_sril XWA, (xsp + 0x0114)
	ld a, (xwa)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xED
	pushw 0x167A
	lda xwa, (xsp + 14)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xde, (xsp + 8)
	lds32 xbc, 3
	push xbc
	ld c, (xsp + 8)
	extz bc
	pushw bc
	ld c, (xsp + 12)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringLeftJustify
	st_dri3b B, 0xFD, 0x08, 0x01
	lda xbc, (xde + 2)
	ld hl, (xbc)
	add hl, 0xC
	ld (xbc), hl
	st_dri3b W, 0xFD, 0x0C, 0x01
	sub hl, 0xF
	ld (xwa + 2), hl
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, PmBank_BankChanged_SecondRight
	ldw (xwa), 0x10
	ldw (xbc), 0x9C
	jr PmBank_BankChanged_DrawIndicator

PmBank_BankChanged_SecondRight:
	ldw (xwa), 0xAB
	ldw (xbc), 0x137

PmBank_BankChanged_DrawIndicator:
	ld_sril XBC, (xsp + 0x0114)
	lda xhl, (xbc + 1)
	lds32 xbc, 1
	push xbc
	ld c, (xsp + 8)
	extz bc
	pushw bc
	ld c, (xsp + 12)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xhl
	call DrawStringLeftJustify
	jrl PmBank_ReturnZero

PmBank_OK:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x0114)
	cp xwa, 0xC
	jrl z, PmBank_OK_Slot9
	cp xwa, 0xB
	jrl z, PmBank_OK_Slot8
	cp xwa, 0xA
	jrl z, PmBank_OK_Slot7
	cp xwa, 0x9
	jrl z, PmBank_OK_Slot6
	cp xwa, 0x8
	jrl z, PmBank_OK_Slot5
	cp xwa, 0x8C
	jrl z, PmBank_OK_Slot4
	cp xwa, 0x8B
	jrl z, PmBank_OK_Slot3
	cp xwa, 0x8A
	jrl z, PmBank_OK_Slot2
	cp xwa, 0x89
	jr z, PmBank_OK_Slot1
	cp xwa, 0x88
	jr z, PmBank_OK_Slot0
	cp xwa, 0x10
	jr z, PmBank_OK_SaveDelete
	cp xwa, 0x90
	jr nz, PmBank_OK_Forward

PmBank_OK_SaveDelete:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D1
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E000AA
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	jr z, PmBank_OK_Forward
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call PostEvent

PmBank_OK_Forward:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jrl PmBank_CallHandler

PmBank_OK_Slot0:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 0
	jrl PmBank_DispatchBankSelect

PmBank_OK_Slot1:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 1
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot2:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 2
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot3:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot4:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 4
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot5:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 5
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot6:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 6
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot7:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	lds32 xde, 7
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot8:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	ld xde, 0x8
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot9:
	ld xwa, 0x1420008
	ld xbc, 0x1E20011
	ld xde, 0x9

PmBank_DispatchBankSelect:
	call MainFuncCall

PmBank_ReturnZero:
	lds32 xhl, 0
	jr PmBank_Epilogue

PmBank_Default:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PmBank_CallHandler:
	call InheritedProc

PmBank_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x01
	ret
PmBank_Boundary:

SineWaveScreenProc:
	st_dri3b L, 0xFD, 0xE8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x01
	cp xiz, 0x1C00007
	jrl z, PmBank_OnEnumNotify
	cp xiz, 0x1C0000F
	jrl z, PmBank_OnConfirm
	cp xiz, 0x1C0000E
	jrl z, PmBank_OnSelect
	cp xiz, 0x1C0000D
	jrl z, PmBank_OnPaint
	cp xiz, 0x1E20017
	jr z, PmBank_DrawRegionInfo
	cp xiz, 0x1E20002
	jr z, PmBank_OnBankChanged
	cp xiz, 0x1C0000B
	jr z, PmBank_InitDisplay
	cp xiz, 0x1C00001
	jrl nz, PmBank_DefaultPassthrough
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr PmBank_CallInherited

PmBank_InitDisplay:
	ld xwa, 0x1420001
	ld xbc, 0x1E20001
	lds32 xde, 0
	call MainFuncCall
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PmBank_CallInherited:
	call InheritedProc
	jrl ToneGen_InitDone

PmBank_OnBankChanged:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xde, (xhl + 48)
	lda xbc, (xhl + 44)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld_sril XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PmBank_SendEventAndDone

PmBank_DrawRegionInfo:
	ldda8 a, 36230
	extz wa
	pushw wa
	ldda8 c, 36228
	ld a, c
	extz wa
	div a, 0xC
	dec 2, a
	extz wa
	pushw wa
	extz bc
	div c, 0xC
	ld a, b
	extz wa
	sla wa, 2
	lda_24 xbc, 0xed16ae
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1718
	lda xwa, (xsp + 20)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)
	st_dri3b A, 0xFD, 0x08, 0x01
	ldw (xbc), 0xE6
	lda xhl, (xbc + 2)
	ldw (xhl), 0xDC
	st_dri3b W, 0xFD, 0x0C, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x59
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lda xde, (xsp + 8)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	pushw 0xF5
	call DrawString
	jrl ToneGen_InitDone

PmBank_OnPaint:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	st_dri3b A, 0xFD, 0x08, 0x01
	ldw (xbc), 0xA
	lda xhl, (xbc + 2)
	ldw (xhl), 0x6
	st_dri3b W, 0xFD, 0x0C, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0xCA
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lds32 xde, 4
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, 0xED1726
	call DrawString
	st_dri3b A, 0xFD, 0x08, 0x01
	ldw (xbc), 0x8
	lda xhl, (xbc + 2)
	ldw (xhl), 0x1C
	st_dri3b W, 0xFD, 0x0C, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x128
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	lds32 xde, 3
	push xde
	pushw 0xFB
	pushw 0xF7
	ld xde, 0xED173A
	call DrawString
	st_dri3b A, 0xFD, 0x08, 0x01
	ldw (xbc), 0x0
	lda xhl, (xbc + 2)
	ldw (xhl), 0x2A
	st_dri3b W, 0xFD, 0x0C, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x5C
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lds32 xde, 0
	push xde
	pushw 0xFF
	pushw 0xF7
	ld xde, 0xED176C
	call DrawString
	st_dri3b A, 0xFD, 0x08, 0x01
	ldw (xbc), 0x28
	lda xhl, (xbc + 2)
	ldw (xhl), 0xDC
	st_dri3b W, 0xFD, 0x0C, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0xB8
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lds32 xde, 0
	push xde
	pushw 0xFF
	pushw 0xF5
	ld xde, 0xED1778
	call DrawString
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1C0000F
	lds32 xde, 0

PmBank_SendEventAndDone:
	call SendEvent
	jrl ToneGen_InitDone

PmBank_OnSelect:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	sla wa, 3
	lda_24 xbc, 0xed167e
	st_dri3b E, 0x07, 0xE4, 0xE0
	st_dri3b D, 0xFD, 0x0C, 0x01
	lds bc, 4
	ldirw
	st_dri3b W, 0xFD, 0x0C, 0x01
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	sla wa, 3
	lda_24 xbc, 0xed167e
	st_dri3b E, 0x07, 0xE4, 0xE0
	st_dri3b D, 0xFD, 0x0C, 0x01
	lds bc, 4
	ldirw
	st_dri3b W, 0xFD, 0x0C, 0x01
	ldw bc, 0xC1
	lds de, 7
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	lds bc, 0
	jr PmBank_WriteLastParam

PmBank_OnConfirm:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	lds wa, 0
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 1
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 2
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 3
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 4
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 5
	ldw bc, 0xFF
	calr ToneGen_WriteParamByIndex
	lds wa, 6
	ldw bc, 0xFF

PmBank_WriteLastParam:
	calr ToneGen_WriteParamByIndex

ToneGen_InitDone:
	lds32 xhl, 0
	jr PmBank_OnDefault

PmBank_OnEnumNotify:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr PmBank_CallInheritedDirect

PmBank_DefaultPassthrough:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PmBank_CallInheritedDirect:
	call InheritedProc

PmBank_OnDefault:
	pop xiz
	st_dri3b L, 0xFD, 0x18, 0x01
	ret

ToneGen_WriteParamByIndex:
	lda xsp, (xsp - 12)
	pushw iz
	ld iz, bc
	ld bc, wa
	ld wa, iz
	lda_24 xiy, 0xed167e
	cps bc, 5
	jrl ugt, ToneGen_WriteParam_Return
	add bc, bc
	lda_24 xix, 0xed18a2
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xfc22d7
	jp_dri 8, 0x07, 0xF0, 0xE4
; ToneGen_WriteParamByIndex dispatch table
ToneGen_ParamWriteDispatch:
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xde, (xsp+2)
	lda	xbc, (xsp+6)
	ld	hl, (xbc)
	inc	1, hl
	ld	(xde), hl
	ld	hl, (xbc+2)
	inc	1, hl
	ld	(xde+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xbc
	ld	xbc, xde
	ld	xde, 15538064
	call	16435914
	lda	xbc, (xsp+2)
	lda	xwa, (xsp+6)
	ld	de, (xwa)
	add	de, 9
	ld	(xbc), de
	ld	de, (xwa+2)
	add	de, 15
	ld	(xbc+2), de
	lds32	xde, 7
	push	xde
	pushw	iz
	pushw 247
	ld	xde, 15538100
	jrl	271
	inc	8, xiy
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xde, (xsp+2)
	lda	xbc, (xsp+6)
	ld	hl, (xbc)
	inc	1, hl
	ld	(xde), hl
	ld	hl, (xbc+2)
	inc	1, hl
	ld	(xde+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xbc
	ld	xbc, xde
	ld	xde, 15538138
	call	16435914
	lda	xbc, (xsp+2)
	lda	xwa, (xsp+6)
	ld	de, (xwa)
	add	de, 9
	ld	(xbc), de
	ld	de, (xwa+2)
	add	de, 15
	ld	(xbc+2), de
	lds32	xde, 7
	push	xde
	pushw	iz
	pushw 247
	ld	xde, 15538168
	jrl	183
	lda	xiy, (xiy+16)
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xde
	ld	xde, 15538208
	jrl	136
	lda	xiy, (xiy+24)
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xde
	ld	xde, 15538238
	jr	90
	lda	xiy, (xiy+32)
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xde
	ld	xde, 15538268
	jr	44
	lda	xiy, (xiy+40)
	lda	xix, (xsp+6)
	lds	bc, 4
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	lds32	xhl, 0
	push	xhl
	pushw	wa
	pushw 247
	ld	xwa, xde
	ld	xde, 15538302
	call	16435914

ToneGen_WriteParam_Return:
	popw iz
	lda xsp, (xsp + 12)
	ret

WallHomeEditCheck:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jrl z, WallHomeEditCheck_ReturnFalse
	cp xbc, 0x1C00002
	jr z, WallHomeEdit_EventDispatch
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, WallHomeEditCheck_ReturnFalse
	cp xwa, 0x9
	jr gt, WallHomeEditCheck_ReturnFalse
	add xwa, xwa
	add xwa, 0xED18C6
	ld wa, (xwa)
	lda_24 xix, 0xfc248a
	jp_dri 8, 0x07, 0xF0, 0xE0

; WallHomeEditCheck event dispatch
WallHomeEdit_EventDispatch:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, WallHomeEditCheck_ReturnFalse
	ldw wa, 0x8
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jr z, WallHomeEditCheck_ReturnFalse
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x142000F
	ld xbc, 0x1E20015
	ld xde, xiz
	call MainFuncCall

WallHomeEditCheck_ReturnFalse:
	lds32 xhl, 0
	jr WallHome_PopIzSkip4Ret
	ld xde, (xiz + 14)
	lda xwa, (xiz + 18)
	cp xde, 0x1
	jr z, WallHomeEdit_PushSndAddr
	ld xbc, (xwa)
	or xde, xde
	jr nz, WallHomeEdit_LoadSndAddr3
	ld xwa, 0xED18AE
	jr WallHomeEdit_PushAddr

WallHomeEdit_PushSndAddr:
	pushw 0xED
	pushw 0x18B6
	ld xwa, (xwa)
	push xwa
	jr WallHomeEdit_CallAudio

WallHomeEdit_LoadSndAddr3:
	ld xwa, 0xED18BE

WallHomeEdit_PushAddr:
	push xwa
	push xbc

WallHomeEdit_CallAudio:
	call Audio_SendCommand
	inc 8, xsp
	ld xhl, (xsp + 4)
	jr WallHome_PopIzSkip4Ret
	lds32 xhl, 1
	jr WallHome_PopIzSkip4Ret
	lda_24 xhl, 0x0340fa
	jr WallHome_PopIzSkip4Ret
	lds32 xhl, 2

WallHome_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

WallMenuEditCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, WallOthEditCheck_RetZero
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, WallOthEditCheck_RetZero
	cp xwa, 0x9
	jr gt, WallOthEditCheck_RetZero
	add xwa, xwa
	add xwa, 0xED18F2
	ld wa, (xwa)
	lda_24 xix, 0xfc256e
	jp_dri 8, 0x07, 0xF0, 0xE0

; WallMenuEditCheck event dispatch
WallMenuEdit_EventDispatch:
	ld	xwa, (xde+14)
	ld	xbc, (xde+18)
	cp	xwa, 1
	jr	z, 11
	or	xwa, xwa
	jr	nz, 14
	ld	xwa, 15538394
	jr	12
	ld	xwa, 15538402
	jr	5
	ld	xwa, 15538410
	push	xwa
	push	xbc
	call	16714354
	inc	8, xsp
	ld	xhl, xiz
	jr	17
	lds32	xhl, 1
	jr	13
	lda_24	xhl, 213244
	jr	6
	lds32	xhl, 2
	jr	2

WallOthEditCheck_RetZero:
	lds32 xhl, 0
	pop xiz
	ret

WallOthEditCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, WallOthCheckLoop_RetZero
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, WallOthCheckLoop_RetZero
	cp xwa, 0x9
	jr gt, WallOthCheckLoop_RetZero
	add xwa, xwa
	add xwa, 0xED191E
	ld wa, (xwa)
	lda_24 xix, 0xfc25e9
	jp_dri 8, 0x07, 0xF0, 0xE0

; WallOthEditCheck event dispatch
WallOthEdit_EventDispatch:
	ld	xwa, (xde+14)
	ld	xbc, (xde+18)
	cp	xwa, 1
	jr	z, 11
	or	xwa, xwa
	jr	nz, 14
	ld	xwa, 15538438
	jr	12
	ld	xwa, 15538446
	jr	5
	ld	xwa, 15538454
	push	xwa
	push	xbc
	call	16714354
	inc	8, xsp
	ld	xhl, xiz
	jr	17
	lds32	xhl, 1
	jr	13
	lda_24	xhl, 213246
	jr	6
	lds32	xhl, 2
	jr	2

WallOthCheckLoop_RetZero:
	lds32 xhl, 0
	pop xiz
	ret

WallSetOKFunc:
	cp xbc, 0x1C00007
	jr nz, WallSetOK_ReturnZero
	ld xwa, 0x142000F
	ld xbc, 0x1E20014
	call MainFuncCall

WallSetOK_ReturnZero:
	lds32 xhl, 0
	ret

MainWallSetFlashFunc:
	cp xbc, 0x1E20016
	jr z, MainWallFlash_ClearAndRestore
	cp xbc, 0x1E20015
	jr z, MainWallFlash_DispatchAudio
	cp xbc, 0x1E20014
	jrl nz, MainWallFlash_ReturnZero
	stdi8 32578, 40
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call ApPostEvent
	ldw wa, 0x8
	call CtrlPanel_IndicatorJumpTable
	stdi8 32578, 35
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	jr MainWallFlash_PostEvent

MainWallFlash_DispatchAudio:
	ldw wa, 0x8
	call Audio_DispatchCommand
	jr MainWallFlash_ReturnZero

MainWallFlash_ClearAndRestore:
	stdi8 32578, 40
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call ApPostEvent
	call Gfx_ClearFrameBuffers
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00048
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 35
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE

MainWallFlash_PostEvent:
	call ApPostEvent

MainWallFlash_ReturnZero:
	lds32 xhl, 0
	ret

WallUsrIniFunc:
	cpi8_24 0x0340ea, 0x00
	jr nz, WallUsrIni_PostBootEvent
	ld xwa, 0x142000F
	ld xbc, 0x1E20016
	call MainFuncCall
	jr WallUsrIni_ReturnZero

WallUsrIni_PostBootEvent:
	ld xwa, 0x48000F
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent

WallUsrIni_ReturnZero:
	lds32 xhl, 0
	ret

WallSureLngCheck:
	cp xbc, 0x1E0009F
	jr nz, WallSureLng_ReturnZero
	lda_24 xhl, 0xed1932
	ret

WallSureLng_ReturnZero:
	lds32 xhl, 0
	ret

WallUsrIniNoFunc:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00048
	call PostEvent
	lds32 xhl, 0
	ret

WallUsrIniYesFunc:
	ld xwa, 0x142000F
	ld xbc, 0x1E20016
	call MainFuncCall
	lds32 xhl, 0
	ret

WallSureShowHideFunc:
	lds32 xhl, 0
	ret

WallUsrShowHideFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1C00002
	jr nz, MainVariSet_ReturnZero
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, MainVariSet_ReturnZero
	ldw wa, 0x8
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jr z, MainVariSet_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x142000F
	ld xbc, 0x1E20015
	ld xde, xiz
	call MainFuncCall

MainVariSet_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

MainVariSet:
	push xiz
	cp xbc, 0x1E20000
	jr nz, MainVariSet_Done
	ld xiz, xde
	ld a, (xiz)
	extz wa
	ld c, (xiz + 2)
	extz bc
	ld e, (xiz + 3)
	extz de
	call MIDI_DistributeParamToChannels
	ld a, (xiz)
	extz wa
	ld e, (xiz + 2)
	extz de
	ld c, (xiz + 3)
	extz bc
	pushw bc
	lds bc, 0
	call SwbtWr
	lds wa, 1
	call BitMapOut_StorePresetValue

MainVariSet_Done:
	lds32 xhl, 0
	pop xiz
	ret

MainSvariIni:
	push xiz
	cp xbc, 0x1E20001
	jr nz, MainSvariIni_ReturnZero
	pushw 0x6
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ldda8 a, 36154
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xiz + 3), l
	ldda8 a, 36154
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xiz + 4), l
	ldmi16 (xiz + 2), 0x8D3A
	ld xwa, xiz
	call SndParam_FetchOscTableEntry
	ld a, (xiz)
	extz wa
	call CharMap_ActivePreamb_Prologue2
	ld (xiz + 3), l
	ldmi16 (xiz + 4), 0x8D3A
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E20002
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	call ApPostEvent

MainSvariIni_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

MainRvariIni:
	push xiz
	cp xbc, 0x1E20007
	jr nz, MainRvariIni_ReturnZero
	pushw 0x6
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xiz + 3), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 2), 0x48
	ld xwa, xiz
	call SndParam_ResolveVoiceEntry
	ld a, (xiz)
	extz wa
	call AccVoice_GetChannelCount_Wrap
	ld (xiz + 3), l
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E20008
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	call ApPostEvent

MainRvariIni_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

MainGetSndGrpName:
	dec 6, xsp
	push xiz
	cp xbc, 0x1E20004
	jr nz, MainGetSndGrpName_ReturnZero
	pushw 0x12
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ldda8 a, 36154
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 7), l
	ldda8 a, 36154
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 4)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8D3A
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 4)
	extz wa
	ld xbc, xiz
	call StoreDRAMInit_LoadDRAM
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E20006
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	call ApPostEvent

MainGetSndGrpName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

MainGetSndName:
	dec 6, xsp
	push xiz
	ld xiz, xde
	cp xbc, 0x1E20003
	jr nz, MainGetSndName_ReturnZero
	pushw 0x12
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld a, (xiz + 3)
	ld (xsp + 4), a
	ld xwa, xiz
	call SndParam_ApplyProgramChange
	ld a, (xiz + 3)
	extz wa
	ld c, (xiz + 4)
	extz bc
	ld xde, (xsp + 6)
	inc 1, xde
	call SndParam_ApplyProgramChangeAsync
	ld xwa, (xsp + 6)
	ld (xwa + 17), 0x0
	ld c, (xsp + 4)
	ld (xwa), c
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E20005
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, (xsp + 6)
	call ApPostEvent

MainGetSndName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

MainGetRhyGrpName:
	dec 6, xsp
	push xiz
	cp xbc, 0x1E2000A
	jr nz, MainGetRhyGrpName_ReturnZero
	pushw 0x11
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 7), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 4)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	ld a, (xsp + 4)
	extz wa
	call AccVoice_CopyFromROM_Wrap
	extz xhl
	pushw 0x10
	push xhl
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 16), 0x0
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E2000C
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	call ApPostEvent

MainGetRhyGrpName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

MainGetRhyName:
	dec 6, xsp
	push xiz
	ld xiz, xde
	cp xbc, 0x1E20009
	jr nz, MainGetRhyName_ReturnZero
	pushw 0xF
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld xbc, xiz
	ld a, (xbc + 3)
	ld (xsp + 4), a
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xD
	push xhl
	ld xwa, (xsp + 12)
	inc 1, xwa
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	ld (xwa + 14), 0x0
	ld c, (xsp + 4)
	ld (xwa), c
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E2000B
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, (xsp + 6)
	call ApPostEvent

MainGetRhyName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 6, xsp
	ret

MainPmGet:
	dec 8, xsp
	push_werp 0xFA
	ld (xsp + 6), xde
	cp xbc, 0x1E20012
	jrl z, MainPmGet_HandleBankDisplay
	cp xbc, 0x1E20011
	jr z, MainPmGet_HandleCheckBit2
	cp xbc, 0x1E20010
	jr z, MainPmGet_HandleBankData
	cp xbc, 0x1E2000F
	jrl nz, MainPmGet_ReturnZero
	call BitMapOut_PrepareRender_CheckBit1
	ldb h, 0x0
	extz xhl
	ld (xsp + 6), xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E2000E
	ld xde, (xsp + 6)
	jrl MainPmGet_PostEvent

MainPmGet_HandleBankData:
	pushw 0x12
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 6)
	ldfr_berp A, 0xFB
	ld xde, (xsp + 2)
	ldto_berp C, 0xFB
	ld (xde), c
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xde + 1)
	call BitMapOut_UpdateWidget_PostDraw
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20002
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, (xsp + 2)
	jr MainPmGet_PostEvent

MainPmGet_HandleCheckBit2:
	ld xwa, (xsp + 6)
	ldfr_berp A, 0xFB
	extz wa
	call BitMapOut_PrepareRender_CheckBit2
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000E
	jr MainPmGet_PostEvent

MainPmGet_HandleBankDisplay:
	pushw 0x13
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 6)
	ldfr_berp A, 0xFB
	ld xwa, (xsp + 2)
	ldto_berp C, 0xFB
	ld (xwa), c
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	ld xbc, (xsp + 2)
	ld (xbc + 1), l
	ldto_berp A, 0xFB
	extz wa
	inc 2, xbc
	call BitMapOut_UpdateDisplayWidget
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20003
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, (xsp + 2)

MainPmGet_PostEvent:
	call ApPostEvent

MainPmGet_ReturnZero:
	lds32 xhl, 0
	pop_werp 0xFA
	inc 8, xsp
	ret

MainSysControl:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), xde
	cp xbc, 0x1E20013
	jr nz, MainSysControl_PostDispatchFinalize
	stdi8 32578, 40
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	ld xwa, (xsp + 2)
	ldfr_berp A, 0xFB
	push xde
	push xhl
	push xix
	push xiz
	call SubCPU_PayloadErrorStore
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldto_berp A, 0xFB
	extz wa
	cps wa, 0
	jr mi, MainSysControl_PostDispatchFinalize
	cp wa, 0x8
	jr gt, MainSysControl_PostDispatchFinalize
	add wa, wa
	lda_24 xix, 0xed1b22
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfc2c12
	jp_dri 8, 0x07, 0xF0, 0xE0

; MainSysControl dispatch table
MainSysCtrl_DispatchTable:
	; --- Dispatch table: 9 call entries (54 bytes) ---
	lds	wa, 2
	call ScreenGroup_DispatchAlt
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry1_AccDemo:
	call AccDemo_InitDone
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry2_PartInit:
	call Part_InitFromPreset
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry3_Misc:
	call SendPartDataBlock_DoGetError
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry4_CopyBitmaps:
	call Display_CopyAndRenderBitmaps
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry5_VoiceInit:
	call Voice_InitBankDataSafe
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry6:
	call 0xFC7EA9
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry7:
	call 0xFC7EC2
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry8:
	call 0xFC7F31


MainSysControl_PostDispatchFinalize:
	call RefreshSwEvent
	call CPanel_InitButtonState_SaveRegs
	lds bc, 0

MainSysCtrl_DelayOuter:
	lds wa, 0

MainSysCtrl_DelayInner:
	inc 1, wa
	cp wa, 0x100
	jr c, MainSysCtrl_DelayInner
	inc 1, bc
	cp bc, 0x1000
	jr c, MainSysCtrl_DelayOuter
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	ld xde, 0x1800001
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 35
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	lds32 xhl, 0
	pop_werp 0xFA
	inc 4, xsp
	ret

CntIniFunc:
	cp xbc, 0x1C00013
	jr nz, CntIniFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CntIniFunc_ReturnZero
	cp xde, 0x5
	jr ugt, CntIniFunc_ReturnZero
	add xde, xde
	add xde, 0xED1B34
	ld de, (xde)
	lda_24 xix, 0xfc2cd9
	jp_dri 8, 0x07, 0xF0, 0xE8
; CntIniFunc event dispatch
CntIniFunc_EventDispatch:
	call	16095929
	call	16180794

CntIniFunc_ReturnZero:
	lds32 xhl, 0
	ret

MainMssSetUp:
	cp xbc, 0x1E20019
	jr z, MainMssSetUp_ClearMode
	cp xbc, 0x1E20018
	jr nz, MainMssSetUp_ReturnZero
	stda16 36182, xde
	incdi16 1, 36182
	stdi8 36174, 7
	jr MainMssSetUp_ReturnZero

MainMssSetUp_ClearMode:
	stdi8 36174, 0

MainMssSetUp_ReturnZero:
	lds32 xhl, 0
	ret
MainMssSetUp_End:

AcFreeSplitBoxProc:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C0001C
	jr z, AcFreeSplit_ValueChanged
	cp xbc, 0x1C0000C
	jr z, AcFreeSplit_ShowHide
	cp xbc, 0x1C0000B
	jr z, AcFreeSplit_ShowHide
	cp xbc, 0x1C00002
	jr z, AcFreeSplit_Release
	cp xbc, 0x1C00001
	jr z, AcFreeSplit_Init
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcFreeSplit_PopAndReturn

AcFreeSplit_Init:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x4180
	call SetLswFilter
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_Release:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x4180
	call ResetLswFilter
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_ShowHide:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x4180
	call MainLswGet
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_ValueChanged:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	st32_24 0x0340c0, xwa
	cp xwa, 0x4180
	jr nz, AcFreeSplit_CheckSecondKey
	cpw (xiz + 4), 0x0
	jr z, AcFreeSplit_LookupNoteLabel
	pushw 0xED
	pushw 0x1BEC
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcFreeSplit_SendConfirmEvent

AcFreeSplit_LookupNoteLabel:
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xC
	sla hl, 2
	lda_24 xbc, 0xed1baa
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xC
	ldto_werp WA, 0xEE
	sla wa, 2
	lda_24 xbc, 0xed1b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1BF8
	lda xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

AcFreeSplit_SendConfirmEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	jrl AcFreeSplit_SendEventAndReturn

AcFreeSplit_CheckSecondKey:
	cp xwa, 0x4181
	jr nz, UI_AccChordBoxProc_Return
	ld xwa, 0x4180
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, AcFreeSplit_LookupSecondNote
	pushw 0xED
	pushw 0x1C04
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcFreeSplit_SendSecondConfirm

AcFreeSplit_LookupSecondNote:
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xC
	sla hl, 2
	lda_24 xbc, 0xed1baa
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xC
	ldto_werp WA, 0xEE
	sla wa, 2
	lda_24 xbc, 0xed1b40
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1C10
	lda xwa, (xsp + 16)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)

AcFreeSplit_SendSecondConfirm:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F

AcFreeSplit_SendEventAndReturn:
	call SendEvent

UI_AccChordBoxProc_Return:
	lds32 xhl, 0

AcFreeSplit_PopAndReturn:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret

AcTranspose_ParamData:
	ld	xhl, 16908292
	ret
AcTranspose_ParamData_End:

AcTransposeBoxProc:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C0001C
	jr z, AcTranspose_ValueChanged
	cp xbc, 0x1C0000C
	jr z, AcTranspose_ShowHide
	cp xbc, 0x1C0000B
	jr z, AcTranspose_ShowHide
	cp xbc, 0x1C00002
	jr z, AcTranspose_Release
	cp xbc, 0x1C00001
	jr z, AcTranspose_Init
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl UI_EventHandler_PopAndReturn

AcTranspose_Init:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	lds32 xbc, 3
	call SetLswFilter
	jrl UI_EventHandler_InitReturnZero

AcTranspose_Release:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	lds32 xbc, 3
	call ResetLswFilter
	jr UI_EventHandler_InitReturnZero

AcTranspose_ShowHide:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	lds32 xwa, 3
	call MainLswGet
	jr UI_EventHandler_InitReturnZero

AcTranspose_ValueChanged:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x3
	jr nz, UI_EventHandler_InitReturnZero
	lda xbc, (xsp + 4)
	ld wa, (xiz + 4)
	cps wa, 5
	jr nz, AcTranspose_FormatLabel
	cpdi8 36156, 0
	jr nz, AcTranspose_FormatLabel
	pushw 0xED
	pushw 0x1C86
	push xbc
	call Strcpy
	inc 8, xsp
	jr ChordProc_SendRefreshEvent

AcTranspose_FormatLabel:
	sla wa, 2
	lda_24 xde, 0xed1c1c
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1C8C
	push xbc
