; =============================================================================
; Graphics, Text & VGA Routines
; =============================================================================
;
; VGA palette initialization, text rendering engine, string
; layout, character set handling, and VRAM blit operations.
; The low-level graphics API used by all UI subsystems.
; =============================================================================

	add xwa, xbc
	lda xiz, (0x043c00:24)
	add xiz, xwa
	ld hl, 0:i3
	cpw (xsp + 24), 0x0
	jr ule, TextRender_AdvancePointerAndUpdateLine

TextRender_PixelLoop:
	ld bc, (xde)
	add bc, hl
	ld (xix), bc
	ld XIY, (xsp + 0x013a)
	cp bc, (xiy)
	jr lt, TextRender_BitMask6_Return
	ld wa, (xix)
	cp wa, (xiy + 4)
	jr gt, TextRender_AdvancePointerAndUpdateLine
	ld wa, 7:i3
	sub wa, hl
	ld iy, 1:i3
	and a, 0xf
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
	ld xwa, 1:i3
	add (xsp + 16), xwa
	incw 1, (xsp + 28)

TextRender_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_XorMode_DrawPixel

TextRender_AdvanceToNextLine:
	ld wa, (xsp + 24)
	add_sriw_mr WA, 0xfd, 0x2a, 0x01
	incw 1, (xsp + 26)
	ld wa, (xsp + 26)
	cp wa, (xsp + 22)
	jrl c, TextRender_ScanLineLoop

TextRender_AdvanceStringPointer:
	ld xwa, 1:i3
	add (xsp + 30), xwa
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jrl nz, TextRender_CharEncodeAndDraw

TextRender_Finalize:
	lda_dri XWA, 0xfd, 0x2e, 0x01
	calr SetChangeRect

TextRender_PopAndReturn:
	pop xiz
	lda_dri XSP, 0xfd, 0x3a, 0x01
	retd 0x8
DirmdEmulator_Dispatch_Code_Helper:
	ld (0x03efa2:24), wa
	ret

GraphicsRender_ByteData:
	ld	(0x03efa4:24), wa
	ret
DirmdEmulator_Dispatch_Code_Helper2:
	pushw	iz
	ld	iz, wa
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	z, GraphicsRender_ByteData_Skip
	ld	wa, iz
	calr	GraphicsRender_ByteData_Helper
	jr	GraphicsRender_ByteData_Epilogue
GraphicsRender_ByteData_Skip:
	ld	wa, 6:i3
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (GraphicsRender_ByteData_0x2D:24)
	ld	(xwa), xbc
	ld	(xwa+4), iz
	calr	DisplayCmd_DequeueAndExecute
GraphicsRender_ByteData_Epilogue:
	popw	iz
	ret
	ld	wa, (xwa+4)
	jr	GraphicsRender_ByteData_Helper
GraphicsRender_ByteData_Helper:
	dec	4, xsp
	pushw	iz
	ld	(0x03efa6:24), wa
	call	Table_LookupDword
	ld	(xsp+2), xhl
	ldw	iz, 64
GraphicsRender_ByteData_Loop:
	ld	wa, iz
	ld	xbc, (xsp+2)
	call	SetPaletteRGB
	inc	1, iz
	cp	iz, 192
	jr	c, GraphicsRender_ByteData_Loop
	ldw	(0x03ef9e:24), 4
	ldw	(0x030460:24), 1
	popw	iz
	inc	4, xsp
	ret
DirmdEmulator_Dispatch_Code_Helper3:
	calr	IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp	hl, 0:i3
	jr	nz, GraphicsRender_ByteData_Join
	ld	wa, 4:i3
	calr	DrawQueue_Alloc
	ld	xwa, xhl
	lda	xbc, (GraphicsRender_ByteData_0x7F:24)
	ld	(xwa), xbc
	jrl	DisplayCmd_DequeueAndExecute
	jr	GraphicsRender_ByteData_Join
GraphicsRender_ByteData_Join:
	pushw	iz
	ldw	iz, 32
GraphicsRender_ByteData_Loop2:
	ld	wa, iz
	sub	wa, 32
	extz	xwa
	ld	xbc, Str_No_0xBBE
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	call	Table_LookupDword
	ld	xbc, xhl
	ld	wa, iz
	call	SetPaletteRGB
	inc	1, iz
	cp	iz, 64
	jr	c, GraphicsRender_ByteData_Loop2
	ldw	iz, 192
GraphicsRender_ByteData_Loop3:
	ld	wa, iz
	sub	wa, 192
	extz	xwa
	ld	xbc, Pad_AfterStr_No
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	call	Table_LookupDword
	ld	xbc, xhl
	ld	wa, iz
	call	SetPaletteRGB
	inc	1, iz
	cp	iz, 224
	jr	c, GraphicsRender_ByteData_Loop3
	ldw	(0x03ef9e:24), 4
	ldw	(0x030460:24), 1
	popw	iz
	ret

Display_DeferOrDrawWall:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr nz, Display_DeferOrDrawWall_Direct
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (Display_DeferOrDrawWall_0x18:24)
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr Display_DeferOrDrawWall_Direct

Display_DeferOrDrawWall_Direct:
	ldw (0x03ef92:24), 0x0000
	ld wa, 0:i3
	calr SetNeedUpdate
	jrl DrawWall

Display_DeferOrUpdateScreen:
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cp hl, 0:i3
	jr nz, Display_DeferOrUpdateScreen_Direct
	ld wa, 4:i3
	calr DrawQueue_Alloc
	ld xwa, xhl
	lda xbc, (Display_DeferOrUpdateScreen_0x18:24)
	ld (xwa), xbc
	jrl DisplayCmd_DequeueAndExecute
	jr Display_DeferOrUpdateScreen_Direct

Display_DeferOrUpdateScreen_Direct:
	ldw (0x03ef92:24), 0x0001
	ld wa, 1:i3
	calr SetNeedUpdate
	jrl UpdateScreen
	ret

GraphicsRender_RetStub:
	ret

GraphicsRender_ShortByteBlock:
	lda	xbc, (xwa+1)
	jr	GraphicsRender_ProcessEntries
	lda	xbc, (xwa+1)
	jr	t, GraphicsRender_Start

GraphicsRender_ProcessEntries:
	lda_dri XSP, 0xfd, 0x6a, 0xff
	push xiz
	stl_dri XBC, 0xfd, 0x96, 0x00
	ld xiz, xwa
	ld xiy, Str_No_0xBFE
	lda xix, (xsp + 6)
	ldw bc, 0x48
	ldirw
	cpl_sri_mr XIZ, 0xfd, 0x96, 0x00
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld xwa, xiz
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	lda_dri XIZ, 0x07, 0xf8, 0xe0
	cpl_sri_mr XIZ, 0xfd, 0x96, 0x00
	jr ugt, GraphicsRender_ProcessEntry_Loop

GraphicsRender_ProcessEntries_Done:
	pop xiz
	lda_dri XSP, 0xfd, 0x96, 0x00
	ret

GraphicsRender_Start:
	lda xsp, (xsp - 54)
	push xiz
	ld (xsp + 54), xbc
	ld xiz, xwa
	ld xiy, Str_No_0xC8E
	lda xix, (xsp + 6)
	ldw bc, 0x18
	ldirw
	cp (xsp + 54), xiz
	jr ule, GraphicsRender_Start_Done

GraphicsRender_Start_EntryLoop:
	ld c, (xiz)
	ld a, (xiz + 1)
	ld (xsp + 4), a
	cp c, 0xb
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld xwa, xiz
	ld xhl, (xbc)
	call (xhl)
	ld a, (xsp + 4)
	extz wa
	lda_dri XIZ, 0x07, 0xf8, 0xe0
	cp (xsp + 54), xiz
	jr ugt, GraphicsRender_Start_EntryLoop

GraphicsRender_Start_Done:
	pop xiz
	lda xsp, (xsp + 54)
	ret

DrawText_LayoutAndRender:
	lda_dri XSP, 0xfd, 0xee, 0xfe
	push xiz
	ld xiy, Str_No_0xCBE
	lda_dri XIX, 0xfd, 0x0e, 0x01
	ld bc, 4:i3
	ldirw
	ld hl, (xwa + 2)
	ld c, (xwa + 1)
	dec 4, c
	extz bc
	ld (xsp + 4), bc
	lda_dri XBC, 0xfd, 0x0a, 0x01
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
	ld iy, 0:i3
	cpw (xsp + 4), 0x0
	jr ule, DrawText_NullTerminate
	lda xhl, (xsp + 10)
	ld xde, 4:i3

DrawText_CopyCharLoop:
	ld xix, xde
	ld xbc, 0xfffffffc
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
	lda_dri XWA, 0xfd, 0x0e, 0x01
	ld xbc, 0:i3
	push xbc
	pushw_da 0xa4, 0xef, 0x03
	pushw_da 0xa2, 0xef, 0x03
	ld xbc, (xsp + 14)
	calr DrawText_QueueOrDirect
	pop xiz
	lda_dri XSP, 0xfd, 0x12, 0x01
	ret

DrawText_LayoutAndRender_Variant1:
	lda xsp, (xsp-274)
	push	xiz
	ld	xiy, Str_No_0xCC6
	lda	xix, (xsp+270)
	ld	bc, 4:i3
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
	ld	iy, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_LayoutAndRender_Variant1_Skip
	lda	xhl, (xsp+10)
	ld	xde, 4:i3
DrawText_LayoutAndRender_Variant1_Loop2:
	ld	xix, xde
	ld	xbc, 0xfffffffc
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
	jr	c, DrawText_LayoutAndRender_Variant1_Loop2
DrawText_LayoutAndRender_Variant1_Skip:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	ld	xbc, 1:i3
	push	xbc
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	ld	xbc, (xsp+14)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+274)
	ret
	lda xsp, (xsp-274)
	push	xiz
	ld	xiy, Str_No_0xCCE
	lda	xix, (xsp+270)
	ld	bc, 4:i3
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
	ld	iy, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_LayoutAndRender_Variant1_Skip2
	lda	xhl, (xsp+10)
	ld	xde, 4:i3
DrawText_LayoutAndRender_Variant1_Loop3:
	ld	xix, xde
	ld	xbc, 0xfffffffc
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
	jr	c, DrawText_LayoutAndRender_Variant1_Loop3
DrawText_LayoutAndRender_Variant1_Skip2:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	ld	xbc, 2:i3
	push	xbc
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	ld	xbc, (xsp+14)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+274)
	ret
	lda xsp, (xsp-274)
	push	xiz
	ld	xiy, Str_No_0xCD6
	lda	xix, (xsp+270)
	ld	bc, 4:i3
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
	ld	iy, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_LayoutAndRender_Variant1_Skip3
	lda	xhl, (xsp+10)
	ld	xde, 6:i3
DrawText_LayoutAndRender_Variant1_Loop4:
	ld	xix, xde
	ld	xbc, 0xfffffffa
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
	jr	c, DrawText_LayoutAndRender_Variant1_Loop4
DrawText_LayoutAndRender_Variant1_Skip3:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	ld	xbc, 3:i3
	push	xbc
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	ld	xbc, (xsp+14)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+274)
	ret
	lda xsp, (xsp-274)
	push	xiz
	ld	xiy, Str_No_0xCDE
	lda	xix, (xsp+270)
	ld	bc, 4:i3
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
	ld	iy, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_LayoutAndRender_Variant1_Skip4
	lda	xhl, (xsp+10)
	ld	xde, 6:i3
DrawText_LayoutAndRender_Variant1_Loop:
	ld	xix, xde
	ld	xbc, 0xfffffffa
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
	jr	c, DrawText_LayoutAndRender_Variant1_Loop
DrawText_LayoutAndRender_Variant1_Skip4:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	ld	xbc, 4:i3
	push	xbc
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	ld	xbc, (xsp+14)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+274)
	ret
	lda xsp, (xsp-274)
	push	xiz
	ld	xiy, Str_No_0xCE6
	lda	xix, (xsp+270)
	ld	bc, 4:i3
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
	ld	iy, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_LayoutAndRender_Variant1_Skip5
	lda	xhl, (xsp+10)
	ld	xde, 4:i3
DrawText_LayoutAndRender_Variant1_Loop5:
	ld	xix, xde
	ld	xbc, 0xfffffffc
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
	jr	c, DrawText_LayoutAndRender_Variant1_Loop5
DrawText_LayoutAndRender_Variant1_Skip5:
	ld	wa, iy
	extz	xwa
	lda	xde, (xsp+10)
	ld	xbc, xde
	add	xbc, xwa
	ld	(xbc), 0
	lda	xwa, (xsp+270)
	ld	xbc, 6:i3
	push	xbc
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	ld	xbc, (xsp+14)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+274)
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	ld	xwa, xbc
	ld	bc, de
	calr	DrawText_LayoutAndRender_Variant1_Helper3
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
	ld	bc, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper3
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper2
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
	ld	bc, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper3
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld	de, (0x03efa4:24)
	calr	DrawText_LayoutAndRender_Variant1_Helper
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
	ld bc, qbc
	sll bc, 3
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
	ld	de, (0x03efa4:24)
	ld	xwa, xhl
	calr	ColorBlit2_LargeCodeBlock
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
	ld bc, qbc
	sll bc, 3
	ld	(xhl), bc
	ld	a, (xwa+2)
	ldb_erp a, 248
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
	calr	DrawDesignBox
	lda	xwa, (xsp+10)
	ld	bc, iz
	inc	2, bc
	extz	xbc
	calr	DrawIcons
	popw	iz
	lda	xsp, (xsp+12)
	ret
	dec	8, xsp
	push	qiz
	lda	xbc, (xsp+2)
	ld	de, (xwa+2)
	ld	(xbc), de
	ld	de, (xwa+4)
	ld	(xbc+2), de
	ld	de, (xwa+6)
	ld	(xbc+4), de
	ld	wa, (xwa+8)
	ld	(xbc+6), wa
	ld	a, (0x03efa8:24)
	ldb_erp	a, 251
	stib_da	(0x3efa8), 1
	ld	de, (0x03efa4:24)
	ld	xwa, xbc
	ld	bc, de
	calr	ColorBlit
	stb_erp	a, 251
	stb_da	(0x3efa8), a
	pop	qiz
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
	stw_erp DE, 0xea
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
	ld bc, (0x03efa2:24)
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
	ld	de, (0x03efa2:24)
	ld	xwa, xbc
	ld	bc, de
	calr	ColorBlit2
	inc	8, xsp
	ret

DrawText_ExtendedLayout:
	lda_dri XSP, 0xfd, 0xe4, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x1c, 0x01
	ld xiy, Str_No_0xDFE
	lda_dri XIX, 0xfd, 0x14, 0x01
	ld bc, 4:i3
	ldirw
	ld XDE, (xsp + 0x011c)
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
	and a, 0xf
	jr z, DrawText_ExtLayout_SkipShift
	srla c

DrawText_ExtLayout_SkipShift:
	ld (xsp + 6), c
	ld wa, (xde + 13)
	ld (xsp + 10), wa
	ld wa, (xde + 11)
	ld (xsp + 4), wa
	lda_dri XWA, 0xfd, 0x10, 0x01
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
	ld hl, 0:i3
	cpw (xsp + 4), 0x0
	jr ule, DrawText_ExtLayout_NullAndDraw
	lda xwa, (xde + 7)
	ld (xsp + 8), xwa
	lda xix, (xsp + 16)
	ld a, (xsp + 6)
	extz wa
	mrdw3 0x9f, 0x04, 0x40
	ld xbc, xwa
	ld xde, 0:i3

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
	ld XWA, (xsp + 0x011c)
	ld a, (xwa + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda xbc, (Str_No_0xCEE:24)
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	lda_dri XWA, 0xfd, 0x14, 0x01
	push xbc
	pushw_da 0xa4, 0xef, 0x03
	pushw_da 0xa2, 0xef, 0x03
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr DrawText_QueueOrDirect
	pop xiz
	lda_dri XSP, 0xfd, 0x1c, 0x01
	ret

DrawText_ExtLayout_Variant1:
	lda	xsp, (xsp-284)
	push	xiz
	ld	(xsp+284), xwa
	ld	xiy, Str_No_0xE06
	lda	xix, (xsp+276)
	ld	bc, 4:i3
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
	jr	z, DrawText_ExtendedLayout_Skip2
	srla c	; srl A,C
DrawText_ExtendedLayout_Skip2:
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
	ld	hl, 0:i3
	cpw	(xsp+4), 0
	jr	ule, DrawText_ExtendedLayout_Skip
	ld	xbc, xde
	lda	xwa, (xbc+7)
	ld	(xsp+8), xwa
	lda	xix, (xsp+16)
	ld	a, (xsp+6)
	extz	wa
	mul	xwa, (xsp+4)
	ld	xbc, xwa
	ld	xde, 0:i3
DrawText_ExtendedLayout_Loop:
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
	jr	c, DrawText_ExtendedLayout_Loop
DrawText_ExtendedLayout_Skip:
	extz	xhl
	lda	xwa, (xsp+16)
	ld	(xsp+8), xwa
	add	xwa, xhl
	ld	(xwa), 0
	ld	xwa, (xsp+284)
	ld	a, (xwa+6)
	and	a, 15
	extz	wa
	lda	xbc, (Str_No_0xDEE:24)
	ld_rrb	c, xbc, wa
	extz	bc
	extz	xbc
	lda	xwa, (xsp+276)
	push	xbc
	pushw	(0x03efa4:24)
	pushw	(0x03efa2:24)
	ld	xbc, (xsp+20)
	ld	xde, (xsp+16)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+284)
	ret

DrawFunc_Init:
	lda_dri XSP, 0xfd, 0xf4, 0xfe
	push xiz
	ld xiz, xwa
	ld xiy, Str_No_0xE0E
	lda_dri XIX, 0xfd, 0x08, 0x01
	ld bc, 4:i3
	ldirw
	ld wa, (xiz + 2)
	extz xwa
	ld e, (xiz + 4)
	ld c, (xiz + 5)
	ld l, (xwa)
	and l, e
	ld a, c
	and a, 0xf
	jr z, DrawFunc_Init_SkipShift
	srla l

DrawFunc_Init_SkipShift:
	ld de, (xiz + 7)
	ld a, (xiz + 9)
	ldb_erp A, 0xf0
	extz ix
	lda_dri XBC, 0xfd, 0x04, 0x01
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
	cp ix, 2:i3
	jr z, DrawFunc_Init_FontTable2
	cp ix, 1:i3
	jr nz, DrawFunc_Init_FontTable0
	ld xwa, Str_No_0xE16
	jr DrawFunc_Init_PushFontAndDraw

DrawFunc_Init_FontTable2:
	ld xwa, Str_No_0xE1A
	jr DrawFunc_Init_PushFontAndDraw

DrawFunc_Init_FontTable0:
	ld xwa, Str_No_0xE1E

DrawFunc_Init_PushFontAndDraw:
	push xwa
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	ld a, (xiz + 6)
	and a, 0x3f
	extz wa
	sla wa, 2
	lda xbc, (Str_No_0xCEE:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	lda_dri XWA, 0xfd, 0x08, 0x01
	lda_dri XBC, 0xfd, 0x04, 0x01
	lda xde, (xsp + 4)
	push xhl
	pushw_da 0xa4, 0xef, 0x03
	pushw_da 0xa2, 0xef, 0x03
	calr DrawText_QueueOrDirect
	pop xiz
	lda_dri XSP, 0xfd, 0x0c, 0x01
	ret

DrawFunc_Init_Variant1:
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Str_No_0xE22
	lda	xix, (xsp+264)
	ld	bc, 4:i3
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
	jr	z, DrawFunc_Init_Skip12
	srla e	; srl A,E
DrawFunc_Init_Skip12:
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
	jr	z, DrawFunc_Init_Skip4
	cp	a, 128
	jr	nc, DrawFunc_Init_Skip
	cp	e, 128
	jr	c, DrawFunc_Init_Skip
	ld	a, 128:opc
	sub	e, 128
DrawFunc_Init_Skip:
	cp	e, a
	jr	ule, DrawFunc_Init_Skip2
	ld	(xsp+4), 43
	sub	e, a
	jr	DrawFunc_Init_Join
DrawFunc_Init_Skip2:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
DrawFunc_Init_Join:
	ld	c, e
	extz	bc
	lda	xde, (xsp+5)
	cp	hl, 2:i3
	jr	z, DrawFunc_Init_Skip3
	pushw	bc
	cp	hl, 1:i3
	jr	nz, DrawFunc_Init_Skip13
	ld	xwa, Str_No_0xE2A
	jr	DrawFunc_Init_Entry
DrawFunc_Init_Skip3:
	pushw	bc
	pushw	234
	pushw 0xb144
	push	xde
	jr	DrawFunc_Init_Join8
DrawFunc_Init_Skip13:
	ld	xwa, 0xeab148
DrawFunc_Init_Entry:
	push	xwa
	push	xde
	jr	DrawFunc_Init_Join8
DrawFunc_Init_Skip4:
	pushw	0
	cp	hl, 2:i3
	jr	z, DrawFunc_Init_Skip5
	cp	hl, 1:i3
	jr	nz, DrawFunc_Init_Skip6
	ld	xwa, Str_No_0xE36
	jr	DrawFunc_Init_Join2
DrawFunc_Init_Skip5:
	ld	xwa, Str_No_0xE3A
	jr	DrawFunc_Init_Join2
DrawFunc_Init_Skip6:
	ld	xwa, Str_No_0xE3E
DrawFunc_Init_Join2:
	push	xwa
	lda	xwa, (xsp+10)
	push	xwa
DrawFunc_Init_Join8:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xCEE:24)
	ld_rrl	xhl, xbc, wa
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Str_No_0xE42
	lda	xix, (xsp+264)
	ld	bc, 4:i3
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
	cp	hl, 2:i3
	jr	z, DrawFunc_Init_Entry2
	cp	hl, 1:i3
	jr	nz, DrawFunc_Init_Entry3
	pushm	(xix)
	ld	xwa, Str_No_0xE4A
	jr	DrawFunc_Init_Join3
DrawFunc_Init_Entry2:
	pushm	(xix)
	ld	xwa, Str_No_0xE4E
	jr	DrawFunc_Init_Join3
DrawFunc_Init_Entry3:
	pushm	(xix)
	ld	xwa, Str_No_0xE52
DrawFunc_Init_Join3:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 63
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_No_0xCEE:24)
	ld_rrl xhl, xbc, wa
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Str_No_0xE56
	lda	xix, (xsp+264)
	ld	bc, 4:i3
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
	jr	z, DrawFunc_Init_Skip14
	srla e	; srl A,E
DrawFunc_Init_Skip14:
	ld	l, (xiz+11)
	lda	xbc, (xsp+260)
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	extz	de
	lda	xbc, (xsp+4)
	pushw	de
	cp	l, 2:i3
	jr	z, DrawFunc_Init_Skip15
	cp	l, 1:i3
	jr	nz, DrawFunc_Init_Skip16
	ld	xwa, Str_No_0xE5E
	jr	DrawFunc_Init_Join4
DrawFunc_Init_Skip15:
	ld	xwa, Str_No_0xE62
	jr	DrawFunc_Init_Join4
DrawFunc_Init_Skip16:
	ld	xwa, Str_No_0xE66
DrawFunc_Init_Join4:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	lda	xbc, (Str_No_0xDEE:24)
	ld	xhl, 0:i3
	ld_rrb l, xbc, wa
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Str_No_0xE6A
	lda	xix, (xsp+264)
	ld	bc, 4:i3
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
	jr	z, DrawFunc_Init_Skip17
	srla e	; srl A,E
DrawFunc_Init_Skip17:
	ld	l, (xiz+11)
	lda	xbc, (xsp+260)
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	ld	a, (xiz+12)
	cp	a, e
	jr	z, DrawFunc_Init_Skip18
	cp	a, 128
	jr	nc, DrawFunc_Init_Skip7
	cp	e, 128
	jr	c, DrawFunc_Init_Skip7
	ld	a, 128:opc
	sub	e, 128
DrawFunc_Init_Skip7:
	cp	e, a
	jr	ule, DrawFunc_Init_Skip8
	ld	(xsp+4), 43
	sub	e, a
	jr	DrawFunc_Init_Join5
DrawFunc_Init_Skip8:
	ld	(xsp+4), 45
	sub	a, e
	ld	e, a
DrawFunc_Init_Join5:
	extz	de
	lda	xbc, (xsp+5)
	pushw	de
	cp	l, 2:i3
	jr	z, DrawFunc_Init_Entry4
	cp	l, 1:i3
	jr	nz, DrawFunc_Init_Skip9
	ld	xwa, Str_No_0xE72
	jr	DrawFunc_Init_Entry5
DrawFunc_Init_Entry4:
	ld	xwa, FmtStr_pct2d
	jr	DrawFunc_Init_Entry5
DrawFunc_Init_Skip9:
	ld	xwa, Str_No_0xE7A
DrawFunc_Init_Entry5:
	push	xwa
	push	xbc
	jr	DrawFunc_Init_Join9
DrawFunc_Init_Skip18:
	lda	xbc, (xsp+4)
	pushw	0
	cp	l, 2:i3
	jr	z, DrawFunc_Init_Skip10
	cp	l, 1:i3
	jr	nz, DrawFunc_Init_Skip11
	ld	xwa, Str_No_0xE7E
	jr	DrawFunc_Init_Join6
DrawFunc_Init_Skip10:
	ld	xwa, Str_No_0xE82
	jr	DrawFunc_Init_Join6
DrawFunc_Init_Skip11:
	ld	xwa, Str_No_0xE86
DrawFunc_Init_Join6:
	push	xwa
	push	xbc
DrawFunc_Init_Join9:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	lda	xbc, (Str_No_0xDEE:24)
	ld	xhl, 0:i3
	ld_rrb	l, xbc, wa
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+268)
	ret
	lda xsp, (xsp-268)
	push	xiz
	ld	xiz, xwa
	ld	xiy, Data_CharMapFormatBlock
	lda	xix, (xsp+264)
	ld	bc, 4:i3
	ldirw
	ld	de, (xiz+2)
	extz	xde
	ld	l, (xiz+11)
	lda	xbc, (xsp+260)
	ld	wa, (xiz+7)
	ld	(xbc), wa
	ld	wa, (xiz+9)
	ld	(xbc+2), wa
	lda	xbc, (xsp+4)
	cp	l, 2:i3
	jr	z, DrawFunc_Init_Skip19
	cp	l, 1:i3
	jr	nz, DrawFunc_Init_Skip20
	pushm	(xde)
	ld	xwa, Data_CharMapFormatBlock_0x8
	jr	DrawFunc_Init_Join10
DrawFunc_Init_Skip19:
	pushm	(xde)
	pushw	234
	pushw	0xb1ac
	push	xbc
	jr	DrawFunc_Init_Join7
DrawFunc_Init_Skip20:
	pushm	(xde)
	ld	xwa, Data_CharMapFormatBlock_0x10
DrawFunc_Init_Join10:
	push	xwa
	push	xbc
DrawFunc_Init_Join7:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	a, (xiz+6)
	and	a, 15
	extz	wa
	lda	xbc, (Str_No_0xDEE:24)
	ld	xhl, 0:i3
	ld_rrb l, xbc, wa
	lda	xwa, (xsp+264)
	lda	xbc, (xsp+260)
	lda	xde, (xsp+4)
	push	xhl
	pushdi_24	(0x3efa4)
	pushdi_24	(0x3efa2)
	calr	DrawText_QueueOrDirect
	pop	xiz
	lda	xsp, (xsp+268)
	ret

ColorBlit_WithPaletteSave:
	dec 8, xsp
	pushw_erp 0xfa
	ld xbc, xwa
	ld wa, (xbc + 2)
	extz xwa
	ld l, (xbc + 4)
	ld e, (xbc + 5)
	ld a, (xwa)
	and a, l
	ld l, a
	ld a, e
	and a, 0xf
	jr z, ColorBlit_PalSave_SkipShift
	srla l

ColorBlit_PalSave_SkipShift:
	sll l, 2
	extz hl
	add hl, hl
	ld xbc, (xbc + 7)
	lda_dri XDE, 0x07, 0xe4, 0xec
	lda xwa, (xsp + 2)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	ld bc, (xde + 4)
	ld (xwa + 4), bc
	ld bc, (xde + 6)
	ld (xwa + 6), bc
	ld c, (0x03efa8:24)
	ldb_erp C, 0xfb
	ld (0x03efa8:24), 0x01
	ld bc, (0x03efa4:24)
	calr ColorBlit
	stb_erp A, 0xfb
	ld (0x03efa8:24), a
	popw_erp 0xfa
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
	jr	z, ColorBlit_Variant_ByteData_Skip
	srla l	; srl A,L
ColorBlit_Variant_ByteData_Skip:
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
	ld bc, qbc
	sll bc, 3
	ld	(xwa), bc
	ld	bc, (xde)
	add	bc, (xhl+4)
	ld	(xwa+6), bc
	ld	bc, (xhl+2)
	sll	bc, 3
	ld	de, (xwa)
	add	de, bc
	ld	(xwa+4), de
	ld	bc, (0x03efa2:24)
	calr	ColorBlit2
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
	jr	z, ColorBlit_Variant_ByteData_Skip2
	srla l	; srl A,L
ColorBlit_Variant_ByteData_Skip2:
	sll	l, 2
	extz	hl
	add	hl, hl
	ld	xbc, (xbc+7)
	lda_rr xde, xbc, hl
	lda xwa, (xsp)
	ld	bc, (xde)
	ld	(xwa), bc
	ld	bc, (xde+2)
	ld	(xwa+2), bc
	ld	bc, (xde+4)
	ld	(xwa+4), bc
	ld	bc, (xde+6)
	ld	(xwa+6), bc
	ld	bc, (0x03efa2:24)
	calr	ColorBlit2
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
; The font glyph table is in ROM at 0x945c00 (Table Data ROM).
; Each entry is 16 bytes:
;   +0x00: word  char_width    (pixels per character)
;   +0x02: word  char_height   (pixels)
;   +0x04: word  descent       (below baseline)
;   +0x06: word  ascent        (above baseline)
;   +0x08: long  glyph_ptr     (pointer to 1bpp bitmap data)
;   +0x0c: long  kerning_ptr   (0 = fixed-width; else per-char width table)
;
; Lookup: entry_addr = 0x945c00 + (font_id << 4)
; =============================================================================

; GetCharHeight - Return character height for a font
; Input:  XWA = font_id
; Output: HL = character height in pixels
GetCharHeight:
	sll xwa, 4		; font_id * 16
	add xwa, 0x945c00	; + table base
	ld hl, (xwa + 2)	; height at offset +2
	ret

; GetCharDescent - Return character descent for a font
; Input:  XWA = font_id
; Output: HL = descent in pixels (below baseline)
GetCharDescent:
	sll xwa, 4		; font_id * 16
	add xwa, 0x945c00	; + table base
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
	ldw hl, 0xffff
	jr GetCenteredDelta_Return

GetCenteredDelta_RetZero:
	ld hl, 0:i3

GetCenteredDelta_Return:
	ret

; =============================================================================
; ConvertStrings - Convert control-code strings to displayable characters
;
; Processes a null-terminated input string (XWA) and outputs displayable
; characters to the buffer (XBC). Handles:
;   - 0x7e escape prefix: next two bytes are hex digits forming a char code
;     e.g., 0x7e 0x33 0x41 -> character 0x3a (colon)
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
	cp (xiz), 0x7e		; Check for escape prefix
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
	ld xwa, 1:i3
	add (xsp + 4), xwa
	jr ConvertStrings_MainLoop

ConvertStringsEx:
	ld xde, xwa

ConvertStringsEx_Loop:
	cp (xde), 0x7e
	jr nz, ConvertStringsEx_CopyChar
	ld a, (xde)
	ld (xbc+), a
	ld (xbc+), 0x34
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
	add xiz, 0x945c00
	ld xwa, (xsp + 8)
	push xwa
	call Strlen
	inc 4, xsp
	ld xbc, (xiz + 12)
	or xbc, xbc
	jr nz, CalcTotalWidth_KerningLoop_Init
	mriw2 0x96, 0x4b
	ld iz, hl
	jr CalcTotalWidth_FreeAndReturn

CalcTotalWidth_KerningLoop_Init:
	ld iz, 0:i3
	ld xix, xbc
	ld de, 0:i3
	cp hl, 0:i3
	jr le, CalcTotalWidth_FreeAndReturn

CalcTotalWidth_KerningLoop:
	ld xwa, (xsp + 4)
	ldb_sri A, 0x07, 0xe0, 0xe8
	sub a, 0x20
	extz wa
	sla wa, 2
	lda_dri XIX, 0x07, 0xf0, 0xe0
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
	incw 1, (xsp + 4)
	cp (xiz), 0x0
	jr nz, Wordwrap_ScanWordChars

Wordwrap_CheckSpaces:
	cp (xiz), 0x0
	jr z, Wordwrap_MeasureWidth

Wordwrap_SkipSpaces:
	cp (xiz), 0x20
	jr nz, Wordwrap_MeasureWidth
	inc 1, xiz
	incw 1, (xsp + 4)
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
	stib_ind 0x07, 0xe0, 0xe4, 0x00
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
; Output: L = 0x00-0x0f (value), or 0x00 if invalid
HexCharToNibble:
	cp a, 0x30		; '0'
	jr c, HexCharToNibble_CheckLower
	cp a, 0x39		; '9'
	jr ugt, HexCharToNibble_CheckLower
	sub a, 0x30		; '0'-'9' -> 0-9
	ld l, a
	ret

HexCharToNibble_CheckLower:
	cp a, 0x61		; 'a'
	jr c, HexCharToNibble_CheckUpper
	cp a, 0x66		; 'f'
	jr ugt, HexCharToNibble_CheckUpper
	sub a, 0x57		; 'a'-'f' -> 10-15
	ld l, a
	ret

HexCharToNibble_CheckUpper:
	cp a, 0x41		; 'A'
	jr c, HexCharToNibble_Invalid
	cp a, 0x46		; 'F'
	jr ugt, HexCharToNibble_Invalid
	sub a, 0x37		; 'A'-'F' -> 10-15
	ld l, a
	ret

HexCharToNibble_Invalid:
	ld l, 0x0:opc		; Invalid -> 0
	ret

FontGlyph_ByteData:
	ld	a, (xwa)
	extz	wa
	lda	xde, (Data_CharMapFormatBlock_0x14:24)
	ld_rrb	a, xde, wa
	ld	(xbc), a
	ret
	ld	e, (xwa)
	cp	e, 32
	jr	z, FontGlyph_ByteData_Skip
	cp	e, 0:i3
	jr	nz, FontGlyph_ByteData_Skip2
FontGlyph_ByteData_Skip:
	ld	a, (xwa)
	ld	(xbc), a
	ret
FontGlyph_ByteData_Skip2:
	ld	de, 0:i3
	lda	xhl, (Data_CharMapFormatBlock_0x14:24)
	ld	a, (xwa)
FontGlyph_ByteData_Loop:
	cpb_sri_mr A, 0x07, 0xec, 0xe8	; cp (XHL+DE),A
	jr	nz, FontGlyph_ByteData_Skip3
	ld	a, e
	ld	(xbc), a
	jr	FontGlyph_ByteData_Join
FontGlyph_ByteData_Skip3:
	inc	1, de
	cp	de, 256
	jr	lt, FontGlyph_ByteData_Loop
FontGlyph_ByteData_Join:
	cp	de, 256
	ret	nz
	ld	(xbc), 32
	ret

; =============================================================================
; InitPaletteRGB - Initialize 256-color palette from ROM data
;
; Copies palette RGB data from ROM (0xeb37de) to RAM (0x0324fc).
; The palette data is stored as packed RGB bytes.
; =============================================================================
InitPaletteRGB:
	lda xde, (0x0324fc:24)
	lda xwa, (0xeb37de:24)
	ld xbc, xwa
	lda_dri XHL, 0xe1, 0x00, 0x04

InitPaletteRGB_CopyLoop:
	ld XWA, (xbc+)
	ld (xde+), XWA
	cp xbc, xhl
	jr c, InitPaletteRGB_CopyLoop
	ret

SetPaletteRGB:
	exts xwa
	sll xwa, 2
	ld xde, 0x324fc
	add xde, xwa
	ld (xde), xbc
	ret

Table_LookupDword:
	exts xwa
	sll xwa, 2
	ld xbc, 0x324fc
	add xbc, xwa
	ld xhl, (xbc)
	ret

GetWallPaletteRGB:
	extz xwa
	sll xwa, 2
	ld xde, 0x3f1e4
	add xde, xwa
	ld xde, (xde)
	extz xbc
	sll xbc, 2
	add xde, xbc
	ld xhl, (xde)
	ret

InitializeRoot:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xeada92, 0xeac9ee, 0x160
	RegObjTable 0x160000c, 0xfa58fb, 0xeaebb0, 0xeae7b6, 0x1c0
	RegObjTable 0x160000d, 0xfa5948, 0xeafa6c, 0xeaebb2, 0x1e0
	RegObjTabl 0x1600002, ApFunctionProc, 0xc, 0xeab2b4, 0x120
	RegObjTabl 0x1600002, ApFunctionProc, 0xc, 0xeab2e8, 0x420
	RegObjTabl 0x1600001, FunctionProc, 0x160, 0xeafa6e, 0x100
	RegObjTabl 0x1600001, FunctionProc, 0x160, WidgetName_InitPtrTable, 0x400
	RegObjTabl 0x1600003, MainFunctionProc, 0xd, 0xeb3698, 0x140
	RegObjTabl 0x1600003, MainFunctionProc, 0xd, 0xeb36d0, 0x440
	RegObjTabl 0x1600010, ViewableProc, 0x33, 0xeb3374, 0x0
	RegObjTabl 0x160000f, ResNameProc, 0x33, 0xeb346c, 0x300
	RegObjTabl 0x1600010, ViewableProc, 0x9, 0xeb3444, 0xff
	RegObjTabl 0x160000f, ResNameProc, 0x9, 0xeb362a, 0x3ff

	RegMode 0x0, 0xeb, 0x3682, 0x0, 0x1200000, 0x1a00000

	RegTitle 0x0, 0xeb, 0x3688, 0x0, 0x1200000, 0x0
	RegTitle 0x0, 0xeb, 0x368e, 0xff, 0x1400009, 0xff0000

	lda xsp, (xsp + 14)
	ret


.macro _VGA_WRITE regnum, value
	.if \regnum <= 7
	ld wa, \regnum:i3
	.else
	ldw wa, \regnum
	.endif
	.if \value <= 7
	ld bc, \value:i3
	.else
	ldw bc, \value
	.endif
	calr _Write_VGA_Register
.endm


.macro _VGA_READ regnum
	.if \regnum <= 7
	ld wa, \regnum:i3
	.else
	ldw wa, \regnum
	.endif
	calr _Read_VGA_Register
.endm


.macro _PALLETE_WRITE red, green, blue
	ldw wa, 0x3c9
	.if \red <= 7
	ld bc, \red:i3
	.else
	ldw bc, \red
	.endif
	calr _Write_VGA_Register
	.if \green <= 7
	ld bc, \green:i3
	.else
	ldw bc, \green
	.endif
	calr _Write_VGA_Register
	.if \blue <= 7
	ld bc, \blue:i3
	.else
	ldw bc, \blue
	.endif
	calr _Write_VGA_Register
.endm


.macro _VGA_ATTRIBUTE field, value
	_VGA_WRITE 0x3c0, \field
	_VGA_WRITE 0x3c0, \value
.endm


.macro _VGA_SEQUENCER field, value
	_VGA_WRITE 0x3c4, \field
	_VGA_WRITE 0x3c5, \value
.endm


.macro _VGA_GFX_CONTROLLER field, value
	_VGA_WRITE 0x3ce, \field
	_VGA_WRITE 0x3cf, \value
.endm


.macro _VGA_COLOR_CRTC field, value
	_VGA_WRITE 0x3d4, \field
	_VGA_WRITE 0x3d5, \value
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
	cp l, 4:i3
	jr nz, VGA_Init_ExtSeq0F_44

	; For byte-matching purposes, the following instructions
	; are equivalent to: _VGA_SEQUENCER 0fh, 000h
	_VGA_WRITE 0x3c4, 0xf
	ldw wa, 0x3c5
	ld bc, 0:i3
	; but omitting the final "CALR _Write_VGA_Register"

	jr VGA_Init_WriteExtSeq


VGA_Init_ExtSeq0F_44:
	; For byte-matching purposes, the following instructions
	; are equivalent to: _VGA_SEQUENCER 0fh, 044h
	_VGA_WRITE 0x3c4, 0xf
	ldw wa, 0x3c5
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
	lda xbc, (0xe3e8:16)
	ld iz, wa
	extz xiz
	add xiz, xbc
	bitm 3, (xiz)
	jr z, VGA_Palette_LowNibble
	cp (xiz), 0xf0
	jr nc, VGA_Palette_HighNibble
	ld a, (xiz)
	srl a, 4
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_Palette_WriteRed

VGA_Palette_HighNibble:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3c9
	jr VGA_Palette_WriteRed

VGA_Palette_LowNibble:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3c9

VGA_Palette_WriteRed:
	calr _Write_VGA_Register
	ld e, (xiz + 1)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_Palette_GreenLow
	cp e, 0xf0
	jr nc, VGA_Palette_GreenHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_Palette_WriteGreen

VGA_Palette_GreenHigh:
	ldw wa, 0x3c9
	jr VGA_Palette_WriteGreen

VGA_Palette_GreenLow:
	ldw wa, 0x3c9

VGA_Palette_WriteGreen:
	calr _Write_VGA_Register
	ld e, (xiz + 2)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_Palette_BlueLow
	cp e, 0xf0
	jr nc, VGA_Palette_BlueHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_Palette_WriteBlue

VGA_Palette_BlueHigh:
	ldw wa, 0x3c9
	jr VGA_Palette_WriteBlue

VGA_Palette_BlueLow:
	ldw wa, 0x3c9

VGA_Palette_WriteBlue:
	calr _Write_VGA_Register
	incw 1, (xsp + 4)
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
	pushw 0x1a
	pushw 0x0
	call Memset
	pushw 0x9600
	pushw 0x0
	lda xwa, (0x1a9600:24); Is this a second video page?
	push xwa
	call Memset
	lda xsp, (xsp + 16)
	ret

_Write_VGA_Register:
	ld de, 0:i3

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
	pushw 0x3c00
	pushw 0x1a
	pushw 0x0
	call Mem_Copy
	pushw 0x9600
	lda xwa, (0x04d200:24)
	push xwa
	lda xwa, (0x1a9600:24); Is this a second video page?
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
	ld xwa, 2:i3
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
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	srl xwa, 1
	add xwa, xwa
	ld xbc, 0x1a0000
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
	ld xbc, 0x43c00
	add xbc, xwa
	push xbc
	srl xwa, 1
	add xwa, xwa
	ld xbc, 0x1a0000
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
	ldw wa, 0x3c5
	ld bc, 1:i3
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
	ldw wa, 0x3c5
	ldw bc, 0x21
	jrl _Write_VGA_Register


VGA_WritePaletteEntry:
	push xiz
	ld xiz, xbc
	ld c, a
	extz bc
	ldw wa, 0x3c8
	calr _Write_VGA_Register
	bitm 3, (xiz)
	jr z, VGA_WritePalEntry_RedLow
	cp (xiz), 0xf0
	jr nc, VGA_WritePalEntry_RedHigh
	ld a, (xiz)
	srl a, 4
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteRed

VGA_WritePalEntry_RedHigh:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteRed

VGA_WritePalEntry_RedLow:
	ld c, (xiz)
	srl c, 4
	extz bc
	ldw wa, 0x3c9

VGA_WritePalEntry_WriteRed:
	calr _Write_VGA_Register
	ld e, (xiz + 1)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_WritePalEntry_GreenLow
	cp e, 0xf0
	jr nc, VGA_WritePalEntry_GreenHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteGreen

VGA_WritePalEntry_GreenHigh:
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteGreen

VGA_WritePalEntry_GreenLow:
	ldw wa, 0x3c9

VGA_WritePalEntry_WriteGreen:
	calr _Write_VGA_Register
	ld e, (xiz + 2)
	ld a, e
	srl a, 4
	ld c, a
	extz bc
	bit 3, e
	jr z, VGA_WritePalEntry_BlueLow
	cp e, 0xf0
	jr nc, VGA_WritePalEntry_BlueHigh
	inc 1, a
	ld c, a
	extz bc
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteBlue

VGA_WritePalEntry_BlueHigh:
	ldw wa, 0x3c9
	jr VGA_WritePalEntry_WriteBlue

VGA_WritePalEntry_BlueLow:
	ldw wa, 0x3c9

VGA_WritePalEntry_WriteBlue:
	calr _Write_VGA_Register
	pop xiz
	ret

VGA_CRTCTiming_ByteData:
	dec	4, xsp
	push	qiz
	ld	(xsp+2), xwa
	ldib_erp 251, 0
VGA_WritePaletteEntry_Join:
	stb_erp a, 251
	extz	wa
	ld	xbc, (xsp+2)
	calr	VGA_WritePaletteEntry
	ld	xwa, 4:i3
	add	(xsp+2), xwa
	inc1b_erp 251
	jr VGA_WritePaletteEntry_Join
	ldw	wa, 964
	ld	bc, 6:i3
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 1:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 4:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 16
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 23
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 5:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 6:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 37
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 19
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 8
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 0:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 28
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 17
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 3:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 2:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 5:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 17
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 3:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 8
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 170
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 16
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 8
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 1:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 19
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 6:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 13
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 1:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 0:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 37
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 15
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 17
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 14
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 0:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 51
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 8
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 17
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 247
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 16
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 10
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 251
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 34
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 14
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 1:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 100
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 3:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 5:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 43
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 7:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 88
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 7:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 11
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 1:i3
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 13
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 13
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 15
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 58
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 9
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 17
	calr	_Write_VGA_Register
	ldw	wa, 964
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 965
	ldw	bc, 12
	calr	_Write_VGA_Register
	ldw	wa, 964
	ld	bc, 6:i3
	calr	_Write_VGA_Register
	ldw	wa, 965
	ld	bc, 0:i3
	jrl	_Write_VGA_Register

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
	ldw wa, 0x3c5
	ld bc, 0:i3
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
	ldw wa, 0x3c5
	ld bc, 0:i3
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
	ldw wa, 0x3c8
	ld bc, 0:i3
	calr _Write_VGA_Register
	ld xiz, 0:i3

	.include "ui/bitmap_out_routines.s"
	.include "ui/ui_mode_handlers.s"
PmBankScreenProc:
	lda_dri XSP, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x01
	cp xiz, 0x1c00007
	jrl z, PmBank_OK
	cp xiz, 0x1c20002
	jrl z, PmBank_BankChanged
	cp xiz, 0x1c0000f
	jrl z, PmBank_Confirm
	cp xiz, 0x1c0000e
	jrl z, PmBank_Select
	cp xiz, 0x1c0000d
	jr z, PmBank_Paint
	cp xiz, 0x1e2000e
	jr z, PmBank_EnumNotify
	cp xiz, 0x1c0000b
	jr z, PmBank_Show
	cp xiz, 0x1c00001
	jrl nz, PmBank_Default
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr PmBank_ForwardToHandler

PmBank_Show:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld xwa, 0x1420008
	ld xbc, 0x1e2000f
	ld xde, 0:i3
	jrl PmBank_DispatchBankSelect

PmBank_EnumNotify:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld XWA, (xsp + 0x0114)
	ldb_erp A, 0xfb
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	call SendEvent
	ld xde, 0:i3
	stb_erp E, 0xfb
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000e
	call SendEvent
	jrl PmBank_ReturnZero

PmBank_Paint:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PmBank_ForwardToHandler:
	call InheritedProc
	jrl PmBank_ReturnZero

PmBank_Select:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
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
	ld XWA, (xsp + 0x0114)
	extz wa
	ld (xbc), wa
	ld xwa, (xhl)
	lda xbc, (SeqChan_Map_10ch:24)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_dri XBC, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr PmBank_Select_DrawFirstRow

PmBank_Select_RightSide:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

PmBank_Select_DrawFirstRow:
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	stl_dri XWA, 0xfd, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld XDE, (xsp + 0x0114)
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	lda xbc, (SeqChan_Map_10ch:24)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_dri XBC, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_Select_SecondRightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr PmBank_Select_DrawSecondRow

PmBank_Select_SecondRightSide:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

PmBank_Select_DrawSecondRow:
	ldw bc, 0xc1
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	exts xwa
	stl_dri XWA, 0xfd, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld XDE, (xsp + 0x0114)
	jrl PmBank_DispatchBankSelect

PmBank_Confirm:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ldib_erp 0xfb, 0

PmBank_Confirm_Loop:
	ld xwa, 0:i3
	stb_erp A, 0xfb
	stl_dri XWA, 0xfd, 0x14, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld XDE, (xsp + 0x0114)
	call MainFuncCall
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x09
	jr ule, PmBank_Confirm_Loop
	jrl PmBank_ReturnZero

PmBank_BankChanged:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), 0xff
	ld (xsp + 6), 0xf5
	ld xbc, (xhl + 48)
	ld XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	cp wa, (xbc)
	jr nz, PmBank_BankChanged_Lookup
	ld (xsp + 4), 0x0
	ld (xsp + 6), 0x7

PmBank_BankChanged_Lookup:
	ld XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	lda xbc, (SeqChan_Map_10ch:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	lda xbc, (SeqChan_Map_10ch:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_dri XBC, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	lda_dri XDE, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, PmBank_BankChanged_RightSide
	ldw (xde), 0x8
	ldw (xwa), 0x1e
	jr PmBank_BankChanged_DrawSlot

PmBank_BankChanged_RightSide:
	ldw (xde), 0xa3
	ldw (xwa), 0xbe

PmBank_BankChanged_DrawSlot:
	decm 8, (xbc)
	ld XWA, (xsp + 0x0114)
	ld a, (xwa)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xed
	pushw 0x167a
	lda xwa, (xsp + 14)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda_dri XWA, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
	lda xde, (xsp + 8)
	ld xbc, 3:i3
	push xbc
	ld c, (xsp + 8)
	extz bc
	pushw bc
	ld c, (xsp + 12)
	extz bc
	pushw bc
	ld xbc, xhl
	call DrawStringLeftJustify
	lda_dri XDE, 0xfd, 0x08, 0x01
	lda xbc, (xde + 2)
	ld hl, (xbc)
	add hl, 0xc
	ld (xbc), hl
	lda_dri XWA, 0xfd, 0x0c, 0x01
	sub hl, 0xf
	ld (xwa + 2), hl
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, PmBank_BankChanged_SecondRight
	ldw (xwa), 0x10
	ldw (xbc), 0x9c
	jr PmBank_BankChanged_DrawIndicator

PmBank_BankChanged_SecondRight:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

PmBank_BankChanged_DrawIndicator:
	ld XBC, (xsp + 0x0114)
	lda xhl, (xbc + 1)
	ld xbc, 1:i3
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
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld XWA, (xsp + 0x0114)
	cp xwa, 0xc
	jrl z, PmBank_OK_Slot9
	cp xwa, 0xb
	jrl z, PmBank_OK_Slot8
	cp xwa, 0xa
	jrl z, PmBank_OK_Slot7
	cp xwa, 0x9
	jrl z, PmBank_OK_Slot6
	cp xwa, 0x8
	jrl z, PmBank_OK_Slot5
	cp xwa, 0x8c
	jrl z, PmBank_OK_Slot4
	cp xwa, 0x8b
	jrl z, PmBank_OK_Slot3
	cp xwa, 0x8a
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d1
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	ld xde, 0:i3
	call SendEvent
	cp hl, 0:i3
	jr z, PmBank_OK_Forward
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	ld xde, 1:i3
	call PostEvent

PmBank_OK_Forward:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jrl PmBank_CallHandler

PmBank_OK_Slot0:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 0:i3
	jrl PmBank_DispatchBankSelect

PmBank_OK_Slot1:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 1:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot2:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 2:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot3:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 3:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot4:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 4:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot5:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 5:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot6:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 6:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot7:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 7:i3
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot8:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 0x8
	jr PmBank_DispatchBankSelect

PmBank_OK_Slot9:
	ld xwa, 0x1420008
	ld xbc, 0x1e20011
	ld xde, 0x9

PmBank_DispatchBankSelect:
	call MainFuncCall

PmBank_ReturnZero:
	ld xhl, 0:i3
	jr PmBank_Epilogue

PmBank_Default:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PmBank_CallHandler:
	call InheritedProc

PmBank_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x18, 0x01
	ret
PmBank_Boundary:

SineWaveScreenProc:
	lda_dri XSP, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x01
	cp xiz, 0x1c00007
	jrl z, PmBank_OnEnumNotify
	cp xiz, 0x1c0000f
	jrl z, PmBank_OnConfirm
	cp xiz, 0x1c0000e
	jrl z, PmBank_OnSelect
	cp xiz, 0x1c0000d
	jrl z, PmBank_OnPaint
	cp xiz, 0x1e20017
	jr z, PmBank_DrawRegionInfo
	cp xiz, 0x1e20002
	jr z, PmBank_OnBankChanged
	cp xiz, 0x1c0000b
	jr z, PmBank_InitDisplay
	cp xiz, 0x1c00001
	jrl nz, PmBank_DefaultPassthrough
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr PmBank_CallInherited

PmBank_InitDisplay:
	ld xwa, 0x1420001
	ld xbc, 0x1e20001
	ld xde, 0:i3
	call MainFuncCall
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PmBank_CallInherited:
	call InheritedProc
	jrl ToneGen_InitDone

PmBank_OnBankChanged:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xde, (xhl + 48)
	lda xbc, (xhl + 44)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld XWA, (xsp + 0x0114)
	ld a, (xwa)
	extz wa
	ld (xbc), wa
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	jrl PmBank_SendEventAndDone

PmBank_DrawRegionInfo:
	ld a, (0x8d86:16)
	extz wa
	pushw wa
	ld c, (0x8d84:16)
	ld a, c
	extz wa
	div a, 0xc
	dec 2, a
	extz wa
	pushw wa
	extz bc
	div c, 0xc
	ld a, b
	extz wa
	sla wa, 2
	lda xbc, (ParamStr_Table_05:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1718
	lda xwa, (xsp + 20)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)
	lda_dri XBC, 0xfd, 0x08, 0x01
	ldw (xbc), 0xe6
	lda xhl, (xbc + 2)
	ldw (xhl), 0xdc
	lda_dri XWA, 0xfd, 0x0c, 0x01
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
	ld xhl, 0:i3
	push xhl
	pushw 0xff
	pushw 0xf5
	call DrawString
	jrl ToneGen_InitDone

PmBank_OnPaint:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	lda_dri XBC, 0xfd, 0x08, 0x01
	ldw (xbc), 0xa
	lda xhl, (xbc + 2)
	ldw (xhl), 0x6
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0xca
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	ld xde, 4:i3
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, TransposeNoteStr_C_0x12
	call DrawString
	lda_dri XBC, 0xfd, 0x08, 0x01
	ldw (xbc), 0x8
	lda xhl, (xbc + 2)
	ldw (xhl), 0x1c
	lda_dri XWA, 0xfd, 0x0c, 0x01
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
	ld xde, 3:i3
	push xde
	pushw 0xfb
	pushw 0xf7
	ld xde, TransposeNoteStr_C_0x26
	call DrawString
	lda_dri XBC, 0xfd, 0x08, 0x01
	ldw (xbc), 0x0
	lda xhl, (xbc + 2)
	ldw (xhl), 0x2a
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x5c
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	ld xde, 0:i3
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, TransposeNoteStr_C_0x58
	call DrawString
	lda_dri XBC, 0xfd, 0x08, 0x01
	ldw (xbc), 0x28
	lda xhl, (xbc + 2)
	ldw (xhl), 0xdc
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0xb8
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	ld xde, 0:i3
	push xde
	pushw 0xff
	pushw 0xf5
	ld xde, TransposeNoteStr_C_0x64
	call DrawString
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	ld xde, 0:i3

PmBank_SendEventAndDone:
	call SendEvent
	jrl ToneGen_InitDone

PmBank_OnSelect:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	sla wa, 3
	lda xbc, (VariationStr_V1_0x3C:24)
	lda_dri XIY, 0x07, 0xe4, 0xe0
	lda_dri XIX, 0xfd, 0x0c, 0x01
	ld bc, 4:i3
	ldirw
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	ld wa, (xwa)
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	sla wa, 3
	lda xbc, (VariationStr_V1_0x3C:24)
	lda_dri XIY, 0x07, 0xe4, 0xe0
	lda_dri XIX, 0xfd, 0x0c, 0x01
	ld bc, 4:i3
	ldirw
	lda_dri XWA, 0xfd, 0x0c, 0x01
	ldw bc, 0xc1
	ld de, 7:i3
	call DrawDesignBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	ld bc, 0:i3
	jr PmBank_WriteLastParam

PmBank_OnConfirm:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, 0:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 1:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 2:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 3:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 4:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 5:i3
	ldw bc, 0xff
	calr ToneGen_WriteParamByIndex
	ld wa, 6:i3
	ldw bc, 0xff

PmBank_WriteLastParam:
	calr ToneGen_WriteParamByIndex

ToneGen_InitDone:
	ld xhl, 0:i3
	jr PmBank_OnDefault

PmBank_OnEnumNotify:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr PmBank_CallInheritedDirect

PmBank_DefaultPassthrough:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PmBank_CallInheritedDirect:
	call InheritedProc

PmBank_OnDefault:
	pop xiz
	lda_dri XSP, 0xfd, 0x18, 0x01
	ret

ToneGen_WriteParamByIndex:
	lda xsp, (xsp - 12)
	pushw iz
	ld iz, bc
	ld bc, wa
	ld wa, iz
	lda xiy, (VariationStr_V1_0x3C:24)
	cp bc, 5:i3
	jrl ugt, ToneGen_WriteParam_Return
	add bc, bc
	lda xix, (TransposeNoteStr_C_0x18E:24)
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda xix, (ToneGen_ParamWriteDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
; ToneGen_WriteParamByIndex dispatch table
ToneGen_ParamWriteDispatch:
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xde, (xsp+2)
	lda	xbc, (xsp+6)
	ld	hl, (xbc)
	inc	1, hl
	ld	(xde), hl
	ld	hl, (xbc+2)
	inc	1, hl
	ld	(xde+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xbc
	ld	xbc, xde
	ld	xde, TransposeNoteStr_C_0x7C
	call	DrawString
	lda	xbc, (xsp+2)
	lda	xwa, (xsp+6)
	ld	de, (xwa)
	add	de, 9
	ld	(xbc), de
	ld	de, (xwa+2)
	add	de, 15
	ld	(xbc+2), de
	ld	xde, 7:i3
	push	xde
	pushw	iz
	pushw	247
	ld	xde, TransposeNoteStr_C_0xA0
	jrl	ToneGen_WriteParamByIndex_Join
	inc	8, xiy
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xde, (xsp+2)
	lda	xbc, (xsp+6)
	ld	hl, (xbc)
	inc	1, hl
	ld	(xde), hl
	ld	hl, (xbc+2)
	inc	1, hl
	ld	(xde+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xbc
	ld	xbc, xde
	ld	xde, TransposeNoteStr_C_0xC6
	call	DrawString
	lda	xbc, (xsp+2)
	lda	xwa, (xsp+6)
	ld	de, (xwa)
	add	de, 9
	ld	(xbc), de
	ld	de, (xwa+2)
	add	de, 15
	ld	(xbc+2), de
	ld	xde, 7:i3
	push	xde
	pushw	iz
	pushw	247
	ld	xde, TransposeNoteStr_C_0xE4
	jrl	ToneGen_WriteParamByIndex_Join
	lda	xiy, (xiy+16)
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xde
	ld	xde, TransposeNoteStr_C_0x10C
	jrl	ToneGen_WriteParamByIndex_Join
	lda	xiy, (xiy+24)
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xde
	ld	xde, TransposeNoteStr_C_0x12A
	jr	ToneGen_WriteParamByIndex_Join
	lda	xiy, (xiy+32)
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xde
	ld	xde, TransposeNoteStr_C_0x148
	jr	ToneGen_WriteParamByIndex_Join
	lda	xiy, (xiy+40)
	lda	xix, (xsp+6)
	ld	bc, 4:i3
	ldirw
	lda	xbc, (xsp+2)
	lda	xde, (xsp+6)
	ld	hl, (xde)
	inc	1, hl
	ld	(xbc), hl
	ld	hl, (xde+2)
	inc	2, hl
	ld	(xbc+2), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	wa
	pushw	247
	ld	xwa, xde
	ld	xde, TransposeNoteStr_C_0x16A
ToneGen_WriteParamByIndex_Join:
	call	DrawString

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
	cp xbc, 0x1e00082
	jrl z, WallHomeEditCheck_ReturnFalse
	cp xbc, 0x1c00002
	jr z, WallHomeEdit_EventDispatch
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jr lt, WallHomeEditCheck_ReturnFalse
	cp xwa, 0x9
	jr gt, WallHomeEditCheck_ReturnFalse
	add xwa, xwa
	add xwa, TransposeNoteStr_C_0x1B2
	ld wa, (xwa)
	lda xix, (WallHomeEdit_EventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; WallHomeEditCheck event dispatch
WallHomeEdit_EventDispatch:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, WallHomeEditCheck_ReturnFalse
	ldw wa, 0x8
	call PanelDisplay_DispatchByMode
	cp hl, 0:i3
	jr z, WallHomeEditCheck_ReturnFalse
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call PostEvent
	ld (0x7f42:16), 72
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	ld xwa, 0x142000f
	ld xbc, 0x1e20015
	ld xde, xiz
	call MainFuncCall

WallHomeEditCheck_ReturnFalse:
	ld xhl, 0:i3
	jr WallHome_PopIzSkip4Ret
	ld xde, (xiz + 14)
	lda xwa, (xiz + 18)
	cp xde, 0x1
	jr z, WallHomeEdit_PushSndAddr
	ld xbc, (xwa)
	or xde, xde
	jr nz, WallHomeEdit_LoadSndAddr3
	ld xwa, TransposeNoteStr_C_0x19A
	jr WallHomeEdit_PushAddr

WallHomeEdit_PushSndAddr:
	pushw 0xed
	pushw 0x18b6
	ld xwa, (xwa)
	push xwa
	jr WallHomeEdit_CallAudio

WallHomeEdit_LoadSndAddr3:
	ld xwa, TransposeNoteStr_C_0x1AA

WallHomeEdit_PushAddr:
	push xwa
	push xbc

WallHomeEdit_CallAudio:
	call Sprintf_Locked
	inc 8, xsp
	ld xhl, (xsp + 4)
	jr WallHome_PopIzSkip4Ret
	ld xhl, 1:i3
	jr WallHome_PopIzSkip4Ret
	lda xhl, (0x0340fa:24)
	jr WallHome_PopIzSkip4Ret
	ld xhl, 2:i3

WallHome_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

WallMenuEditCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1e00082
	jr z, WallOthEditCheck_RetZero
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jr lt, WallOthEditCheck_RetZero
	cp xwa, 0x9
	jr gt, WallOthEditCheck_RetZero
	add xwa, xwa
	add xwa, TransposeNoteStr_C_0x1DE
	ld wa, (xwa)
	lda xix, (WallMenuEdit_EventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; WallMenuEditCheck event dispatch
WallMenuEdit_EventDispatch:
	ld	xwa, (xde+14)
	ld	xbc, (xde+18)
	cp	xwa, 1
	jr	z, ToneGen_WriteParamByIndex_Skip
	or	xwa, xwa
	jr	nz, ToneGen_WriteParamByIndex_Skip2
	ld	xwa, TransposeNoteStr_C_0x1C6
	jr	ToneGen_WriteParamByIndex_Join2
ToneGen_WriteParamByIndex_Skip:
	ld	xwa, TransposeNoteStr_C_0x1CE
	jr	ToneGen_WriteParamByIndex_Join2
ToneGen_WriteParamByIndex_Skip2:
	ld	xwa, TransposeNoteStr_C_0x1D6
ToneGen_WriteParamByIndex_Join2:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	ld	xhl, xiz
	jr	ToneGen_WriteParamByIndex_Epilogue
	ld	xhl, 1:i3
	jr	ToneGen_WriteParamByIndex_Epilogue
	lda	xhl, (0x0340fc:24)
	jr	ToneGen_WriteParamByIndex_Epilogue
	ld	xhl, 2:i3
	jr	ToneGen_WriteParamByIndex_Epilogue

WallOthEditCheck_RetZero:
	ld xhl, 0:i3
ToneGen_WriteParamByIndex_Epilogue:
	pop xiz
	ret

WallOthEditCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1e00082
	jr z, WallOthCheckLoop_RetZero
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jr lt, WallOthCheckLoop_RetZero
	cp xwa, 0x9
	jr gt, WallOthCheckLoop_RetZero
	add xwa, xwa
	add xwa, TransposeNoteStr_C_0x20A
	ld wa, (xwa)
	lda xix, (WallOthEdit_EventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; WallOthEditCheck event dispatch
WallOthEdit_EventDispatch:
	ld	xwa, (xde+14)
	ld	xbc, (xde+18)
	cp	xwa, 1
	jr	z, ToneGen_WriteParamByIndex_Skip3
	or	xwa, xwa
	jr	nz, ToneGen_WriteParamByIndex_Skip4
	ld	xwa, TransposeNoteStr_C_0x1F2
	jr	ToneGen_WriteParamByIndex_Join3
ToneGen_WriteParamByIndex_Skip3:
	ld	xwa, TransposeNoteStr_C_0x1FA
	jr	ToneGen_WriteParamByIndex_Join3
ToneGen_WriteParamByIndex_Skip4:
	ld	xwa, TransposeNoteStr_C_0x202
ToneGen_WriteParamByIndex_Join3:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	ld	xhl, xiz
	jr	ToneGen_WriteParamByIndex_Epilogue2
	ld	xhl, 1:i3
	jr	ToneGen_WriteParamByIndex_Epilogue2
	lda	xhl, (0x0340fe:24)
	jr	ToneGen_WriteParamByIndex_Epilogue2
	ld	xhl, 2:i3
	jr	ToneGen_WriteParamByIndex_Epilogue2

WallOthCheckLoop_RetZero:
	ld xhl, 0:i3
ToneGen_WriteParamByIndex_Epilogue2:
	pop xiz
	ret

WallSetOKFunc:
	cp xbc, 0x1c00007
	jr nz, WallSetOK_ReturnZero
	ld xwa, 0x142000f
	ld xbc, 0x1e20014
	call MainFuncCall

WallSetOK_ReturnZero:
	ld xhl, 0:i3
	ret

MainWallSetFlashFunc:
	cp xbc, 0x1e20016
	jr z, MainWallFlash_ClearAndRestore
	cp xbc, 0x1e20015
	jr z, MainWallFlash_DispatchAudio
	cp xbc, 0x1e20014
	jrl nz, MainWallFlash_ReturnZero
	ld (0x7f42:16), 40
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent
	ldw wa, 0x8
	call CtrlPanel_IndicatorJumpTable
	ld (0x7f42:16), 35
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	jr MainWallFlash_PostEvent

MainWallFlash_DispatchAudio:
	ldw wa, 0x8
	call Audio_DispatchCommand
	jr MainWallFlash_ReturnZero

MainWallFlash_ClearAndRestore:
	ld (0x7f42:16), 40
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent
	call Gfx_ClearFrameBuffers
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00048
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7f42:16), 35
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee

MainWallFlash_PostEvent:
	call ApPostEvent

MainWallFlash_ReturnZero:
	ld xhl, 0:i3
	ret

WallUsrIniFunc:
	cp (0x0340ea:24), 0x00
	jr nz, WallUsrIni_PostBootEvent
	ld xwa, 0x142000f
	ld xbc, 0x1e20016
	call MainFuncCall
	jr WallUsrIni_ReturnZero

WallUsrIni_PostBootEvent:
	ld xwa, 0x48000f
	ld xbc, 0x1c00001
	ld xde, 0:i3
	call PostEvent

WallUsrIni_ReturnZero:
	ld xhl, 0:i3
	ret

WallSureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, WallSureLng_ReturnZero
	lda xhl, (TransposeNoteStr_C_0x21E:24)
	ret

WallSureLng_ReturnZero:
	ld xhl, 0:i3
	ret

WallUsrIniNoFunc:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00048
	call PostEvent
	ld xhl, 0:i3
	ret

WallUsrIniYesFunc:
	ld xwa, 0x142000f
	ld xbc, 0x1e20016
	call MainFuncCall
	ld xhl, 0:i3
	ret

WallSureShowHideFunc:
	ld xhl, 0:i3
	ret

WallUsrShowHideFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1c00002
	jr nz, MainVariSet_ReturnZero
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr nz, MainVariSet_ReturnZero
	ldw wa, 0x8
	call PanelDisplay_DispatchByMode
	cp hl, 0:i3
	jr z, MainVariSet_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call PostEvent
	ld (0x7f42:16), 72
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	ld xwa, 0x142000f
	ld xbc, 0x1e20015
	ld xde, xiz
	call MainFuncCall

MainVariSet_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

MainVariSet:
	push xiz
	cp xbc, 0x1e20000
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
	ld bc, 0:i3
	call SwbtWr
	ld wa, 1:i3
	call BitMapOut_StorePresetValue

MainVariSet_Done:
	ld xhl, 0:i3
	pop xiz
	ret

MainSvariIni:
	push xiz
	cp xbc, 0x1e20001
	jr nz, MainSvariIni_ReturnZero
	pushw 0x6
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld a, (0x8d3a:16)
	extz wa
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xiz + 3), l
	ld a, (0x8d3a:16)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	ld (xiz + 4), l
	ldmi16 (xiz + 2), 0x8d3a
	ld xwa, xiz
	call SndParam_FetchOscTableEntry
	ld a, (xiz)
	extz wa
	call CharMap_ActivePreamb_Prologue2
	ld (xiz + 3), l
	ldmi16 (xiz + 4), 0x8d3a
	ld xwa, 0xffffffff
	ld xbc, 0x1e20002
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainSvariIni_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

MainRvariIni:
	push xiz
	cp xbc, 0x1e20007
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
	ld xwa, 0xffffffff
	ld xbc, 0x1e20008
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainRvariIni_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

MainGetSndGrpName:
	dec 6, xsp
	push xiz
	cp xbc, 0x1e20004
	jr nz, MainGetSndGrpName_ReturnZero
	pushw 0x12
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld a, (0x8d3a:16)
	extz wa
	ld bc, 0:i3
	call SndParam_LookupViaEncode
	ld (xsp + 7), l
	ld a, (0x8d3a:16)
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 4)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8d3a
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 4)
	extz wa
	ld xbc, xiz
	call StoreDRAMInit_LoadDRAM
	ld xwa, 0xffffffff
	ld xbc, 0x1e20006
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainGetSndGrpName_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	inc 6, xsp
	ret

MainGetSndName:
	dec 6, xsp
	push xiz
	ld xiz, xde
	cp xbc, 0x1e20003
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
	ld xwa, 0xffffffff
	ld xbc, 0x1e20005
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 6)
	call ApPostEvent

MainGetSndName_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	inc 6, xsp
	ret

MainGetRhyGrpName:
	dec 6, xsp
	push xiz
	cp xbc, 0x1e2000a
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
	ld xwa, 0xffffffff
	ld xbc, 0x1e2000c
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainGetRhyGrpName_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	inc 6, xsp
	ret

MainGetRhyName:
	dec 6, xsp
	push xiz
	ld xiz, xde
	cp xbc, 0x1e20009
	jr nz, MainGetRhyName_ReturnZero
	pushw 0xf
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
	pushw 0xd
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
	ld xwa, 0xffffffff
	ld xbc, 0x1e2000b
	ld xde, (xsp + 6)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 6)
	call ApPostEvent

MainGetRhyName_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	inc 6, xsp
	ret

MainPmGet:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 6), xde
	cp xbc, 0x1e20012
	jrl z, MainPmGet_HandleBankDisplay
	cp xbc, 0x1e20011
	jr z, MainPmGet_HandleCheckBit2
	cp xbc, 0x1e20010
	jr z, MainPmGet_HandleBankData
	cp xbc, 0x1e2000f
	jrl nz, MainPmGet_ReturnZero
	call BitMapOut_PrepareRender_CheckBit1
	ld h, 0x0:opc
	extz xhl
	ld (xsp + 6), xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1e2000e
	ld xde, (xsp + 6)
	jrl MainPmGet_PostEvent

MainPmGet_HandleBankData:
	pushw 0x12
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 6)
	ldb_erp A, 0xfb
	ld xde, (xsp + 2)
	stb_erp C, 0xfb
	ld (xde), c
	stb_erp A, 0xfb
	extz wa
	lda xbc, (xde + 1)
	call BitMapOut_UpdateWidget_PostDraw
	ld xwa, 0xffffffff
	ld xbc, 0x1c20002
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 2)
	jr MainPmGet_PostEvent

MainPmGet_HandleCheckBit2:
	ld xwa, (xsp + 6)
	ldb_erp A, 0xfb
	extz wa
	call BitMapOut_PrepareRender_CheckBit2
	ld xde, 0:i3
	stb_erp E, 0xfb
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000e
	jr MainPmGet_PostEvent

MainPmGet_HandleBankDisplay:
	pushw 0x13
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, (xsp + 6)
	ldb_erp A, 0xfb
	ld xwa, (xsp + 2)
	stb_erp C, 0xfb
	ld (xwa), c
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	ld xbc, (xsp + 2)
	ld (xbc + 1), l
	stb_erp A, 0xfb
	extz wa
	inc 2, xbc
	call BitMapOut_UpdateDisplayWidget
	ld xwa, 0xffffffff
	ld xbc, 0x1c20003
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 2)

MainPmGet_PostEvent:
	call ApPostEvent

MainPmGet_ReturnZero:
	ld xhl, 0:i3
	popw_erp 0xfa
	inc 8, xsp
	ret

MainSysControl:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xde
	cp xbc, 0x1e20013
	jr nz, MainSysControl_PostDispatchFinalize
	ld (0x7f42:16), 40
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld xwa, (xsp + 2)
	ldb_erp A, 0xfb
	push xde
	push xhl
	push xix
	push xiz
	call SubCPU_PayloadErrorStore
	pop xiz
	pop xix
	pop xhl
	pop xde
	stb_erp A, 0xfb
	extz wa
	cp wa, 0:i3
	jr mi, MainSysControl_PostDispatchFinalize
	cp wa, 0x8
	jr gt, MainSysControl_PostDispatchFinalize
	add wa, wa
	lda xix, (TransposeNoteStr_C_0x40E:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (MainSysCtrl_DispatchTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; MainSysControl dispatch table
MainSysCtrl_DispatchTable:
	; --- Dispatch table: 9 call entries (54 bytes) ---
	ld	wa, 2:i3
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
	call VoiceData_ExtendedParamSetup_0x27
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry7:
	call VoiceData_ExtendedParamSetup_0x40
	jr t, MainSysControl_PostDispatchFinalize
MainSysCtrl_Entry8:
	call VoiceData_ExtendedParamSetup_0xAF


MainSysControl_PostDispatchFinalize:
	call RefreshSwEvent
	call CPanel_InitButtonState_SaveRegs
	ld bc, 0:i3

MainSysCtrl_DelayOuter:
	ld wa, 0:i3

MainSysCtrl_DelayInner:
	inc 1, wa
	cp wa, 0x100
	jr c, MainSysCtrl_DelayInner
	inc 1, bc
	cp bc, 0x1000
	jr c, MainSysCtrl_DelayOuter
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7f42:16), 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld xhl, 0:i3
	popw_erp 0xfa
	inc 4, xsp
	ret

CntIniFunc:
	cp xbc, 0x1c00013
	jr nz, CntIniFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CntIniFunc_ReturnZero
	cp xde, 0x5
	jr ugt, CntIniFunc_ReturnZero
	add xde, xde
	add xde, TransposeNoteStr_C_0x420
	ld de, (xde)
	lda xix, (CntIniFunc_EventDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CntIniFunc event dispatch
CntIniFunc_EventDispatch:
	call	AccWrap_PlayModeDispatch
	call	AccompSeq_StopSequence

CntIniFunc_ReturnZero:
	ld xhl, 0:i3
	ret

MainMssSetUp:
	cp xbc, 0x1e20019
	jr z, MainMssSetUp_ClearMode
	cp xbc, 0x1e20018
	jr nz, MainMssSetUp_ReturnZero
	ld (0x8d56:16), de
	incw 1, (0x8d56:16)
	ld (0x8d4e:16), 7
	jr MainMssSetUp_ReturnZero

MainMssSetUp_ClearMode:
	ld (0x8d4e:16), 0

MainMssSetUp_ReturnZero:
	ld xhl, 0:i3
	ret
MainMssSetUp_End:

AcFreeSplitBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcFreeSplit_ValueChanged
	cp xbc, 0x1c0000c
	jr z, AcFreeSplit_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcFreeSplit_ShowHide
	cp xbc, 0x1c00002
	jr z, AcFreeSplit_Release
	cp xbc, 0x1c00001
	jr z, AcFreeSplit_Init
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcFreeSplit_PopAndReturn

AcFreeSplit_Init:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x4180
	call SetLswFilter
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_Release:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x4180
	call ResetLswFilter
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_ShowHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x4180
	call MainLswGet
	jrl UI_AccChordBoxProc_Return

AcFreeSplit_ValueChanged:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	ld (0x0340c0:24), xwa
	cp xwa, 0x4180
	jr nz, AcFreeSplit_CheckSecondKey
	cpw (xiz + 4), 0x0
	jr z, AcFreeSplit_LookupNoteLabel
	pushw 0xed
	pushw 0x1bec
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcFreeSplit_SendConfirmEvent

AcFreeSplit_LookupNoteLabel:
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xc
	sla hl, 2
	lda xbc, (SplitNoteStr_C_0x4:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xc
	stw_erp WA, 0xee
	sla wa, 2
	lda xbc, (ParamStr_Table_06:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1bf8
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

AcFreeSplit_SendConfirmEvent:
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	jrl AcFreeSplit_SendEventAndReturn

AcFreeSplit_CheckSecondKey:
	cp xwa, 0x4181
	jr nz, UI_AccChordBoxProc_Return
	ld xwa, 0x4180
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, AcFreeSplit_LookupSecondNote
	pushw 0xed
	pushw 0x1c04
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcFreeSplit_SendSecondConfirm

AcFreeSplit_LookupSecondNote:
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xc
	sla hl, 2
	lda xbc, (SplitNoteStr_C_0x4:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	ld xwa, 0x4181
	call SndParam_LookupReadOnly
	exts xhl
	divs hl, 0xc
	stw_erp WA, 0xee
	sla wa, 2
	lda xbc, (ParamStr_Table_06:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1c10
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 16)

AcFreeSplit_SendSecondConfirm:
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f

AcFreeSplit_SendEventAndReturn:
	call SendEvent

UI_AccChordBoxProc_Return:
	ld xhl, 0:i3

AcFreeSplit_PopAndReturn:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

AcTranspose_ParamData:
	ld	xhl, 0x01020004
	ret
AcTranspose_ParamData_End:

AcTransposeBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcTranspose_ValueChanged
	cp xbc, 0x1c0000c
	jr z, AcTranspose_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcTranspose_ShowHide
	cp xbc, 0x1c00002
	jr z, AcTranspose_Release
	cp xbc, 0x1c00001
	jr z, AcTranspose_Init
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl UI_EventHandler_PopAndReturn

AcTranspose_Init:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 3:i3
	call SetLswFilter
	jrl UI_EventHandler_InitReturnZero

AcTranspose_Release:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 3:i3
	call ResetLswFilter
	jr UI_EventHandler_InitReturnZero

AcTranspose_ShowHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 3:i3
	call MainLswGet
	jr UI_EventHandler_InitReturnZero

AcTranspose_ValueChanged:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x3
	jr nz, UI_EventHandler_InitReturnZero
	lda xbc, (xsp + 4)
	ld wa, (xiz + 4)
	cp wa, 5:i3
	jr nz, AcTranspose_FormatLabel
	cp (0x8d3c:16), 0
	jr nz, AcTranspose_FormatLabel
	pushw 0xed
	pushw 0x1c86
	push xbc
	call Strcpy
	inc 8, xsp
	jr ChordProc_SendRefreshEvent

AcTranspose_FormatLabel:
	sla wa, 2
	lda xde, (OctaveDigitStr_0B_0x32:24)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1c8c
	push xbc
