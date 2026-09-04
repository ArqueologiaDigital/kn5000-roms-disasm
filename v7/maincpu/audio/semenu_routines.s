; =============================================================================
; Sound Editor Menu (SeMenu)
; =============================================================================
;
; Event handling and navigation for the Sound Editor menu system.
; Manages dialog boxes, notification handlers, object registration,
; and display flushing for sound editing screens.
; =============================================================================

SeMenu_SendEvent:
	dec 2, xsp
	ld (xsp), c
	cp (xsp), 0x0
	jr nz, SeMenu_SendEvent_Indirect
	extz wa
	call UI_PostModeChangeEvent
	jr SeMenu_SendEvent_StoreAndReturn

SeMenu_SendEvent_Indirect:
	call UI_PostRefreshEvent

SeMenu_SendEvent_StoreAndReturn:
	ld a, (xsp)
	extz wa
	calr SeMenu_StoreEventId
	inc 2, xsp
	ret

SeMenu_LoadRawAddr:
	.byte 0xb0, 0x14, 0x9c, 0x8c	; ldmi16 (xwa), 0x8d38 (v7 displacement)

	ret



SeMenu_TriggerNotification:
	ld (0x7ea6:16), a
	ld (0xe316:16), 0xee
	set 6, (0xe318:16)
	ret
SeMenu_ClearNotification:
	ld (0xe316:16), a
	set 1, (0xe318:16)
	ret
SeMenu_StoreEventId:
	ld (1688:16), a
	ret

SeMenu_LoadObjectPtr_Data:
	.byte 0xb0
	push_a
	.byte 0x98, 0x06
	ret

SeMenu_LoadMasterPtr:
	ld	c, (35998:24)
	ld	(xwa), c
	ret
SeMenu_FlushDisplayObj:
	ld xde, xwa
	ld xbc, xde
	lda xhl, (1689:16)
	lda xix, (xde + 9)

SeMenu_FlushDisplayObj_CopyLoop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xec
	cp xbc, xix
	jr c, SeMenu_FlushDisplayObj_CopyLoop
	lds wa, 0
	lds bc, 6
	jp sendCOMM

SeMenu_RegisterElement_Extended:
	lda xsp, (xsp - 20)
	ld (xsp + 12), xde
	ld (xsp + 16), c
	ld (xsp + 18), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterElement_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterElement_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xbc, (xsp)
	ldb a, 0x80
	ld (xbc), a
	set 3, a
	ld (xbc), a
	ld a, (xsp + 10)
	ld (xbc + 1), a
	ld a, (xsp + 16)
	ld (xbc + 2), a
	ld (xbc + 3), 0x1
	ld xwa, (xsp + 12)
	ld a, (xwa)
	ld (xbc + 4), a
	ld a, (xsp + 24)
	ld (xbc + 5), a
	ld a, (xsp + 18)
	extz wa
	calr SeMenu_SetObjectFlags
	lda xwa, (xsp)
	calr SeMenu_FlushDisplayObj
	lds hl, 0
	lda xsp, (xsp + 20)
	retd 0x2

SeMenu_RegisterElement_Type1:
	lda xsp, (xsp - 18)
	ld (xsp + 12), e
	ld (xsp + 14), c
	ld (xsp + 16), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterElement_Type1_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterElement_Type1_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xbc, (xsp)
	ld (xbc), 0x80
	ld a, (xsp + 10)
	ld (xbc + 1), a
	ld a, (xsp + 14)
	ld (xbc + 2), a
	ld a, (xsp + 12)
	ld (xbc + 3), a
	ld (xbc + 4), 0x1
	ld a, (xsp + 22)
	ld (xbc + 5), a
	ld a, (xsp + 16)
	extz wa
	calr SeMenu_SetObjectFlags
	lda xwa, (xsp)
	calr SeMenu_FlushDisplayObj
	lds hl, 0
	lda xsp, (xsp + 18)
	retd 0x2
	lda xsp, (xsp - 16)
	ld (xsp + 12), c
	ld (xsp + 14), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterElement_Type1_AltLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterElement_Type1_AltLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x80
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 2), 0x1
	ld c, (xsp + 14)
	ld (xwa + 3), c
	ld (xwa + 4), 0x1
	ld c, (xsp + 12)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lds hl, 0
	lda xsp, (xsp + 16)
	ret

SeMenu_InitDisplayField:
	lda xsp, (xsp - 18)
	ld (xsp + 14), c
	ld (xsp + 16), a
	lda xwa, (xsp)
	calr SeMenu_LoadObjEntries
	lda xbc, (xsp + 2)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_InitDisplayField_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_InitDisplayField_ClearLoop
	lda xwa, (xsp + 12)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp + 2)
	ld (xwa), 0x80
	ld c, (xsp + 12)
	ld (xwa + 1), c
	lda xbc, (xwa + 2)
	cp (xsp), 0x0
	jr nz, SeMenu_InitDisplayField_Branch1
	ld (xbc), 0x9
	jr SeMenu_InitDisplayField_Continue

SeMenu_InitDisplayField_Branch1:
	ld (xbc), 0x12

SeMenu_InitDisplayField_Continue:
	ld c, (xsp + 16)
	dec 1, c
	ld (xwa + 3), c
	ld (xwa + 4), 0x1
	ld c, (xsp + 14)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 18)
	ret

SeMenu_InitDisplayField_Alt:
	lda xsp, (xsp - 20)
	ld (xsp + 14), e
	ld (xsp + 16), c
	ld (xsp + 18), a
	lda xwa, (xsp)
	calr SeMenu_LoadObjEntries
	lda xbc, (xsp + 2)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_InitDisplayField_Alt_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_InitDisplayField_Alt_ClearLoop
	lda xwa, (xsp + 12)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp + 2)
	ld (xwa), 0x80
	ld c, (xsp + 12)
	ld (xwa + 1), c
	lda xbc, (xwa + 2)
	cp (xsp), 0x0
	jr nz, SeMenu_InitDisplayField_Alt_Branch1
	ld (xbc), 0xa
	jr SeMenu_InitDisplayField_Alt_Continue

SeMenu_InitDisplayField_Alt_Branch1:
	ld (xbc), 0x13

SeMenu_InitDisplayField_Alt_Continue:
	lda xhl, (xwa + 3)
	ld e, (xsp + 16)
	dec 1, e
	ld (xhl), e
	sll e, 4
	ld (xhl), e
	ld c, (xsp + 18)
	dec 1, c
	add e, c
	ld (xhl), e
	ld (xwa + 4), 0x1
	ld c, (xsp + 14)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 20)
	ret

SeMenu_RegisterValueDisplay:
	lda xsp, (xsp - 16)
	ld (xsp + 12), c
	ld (xsp + 14), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterValueDisplay_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterValueDisplay_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x80
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 2), 0x10
	ld c, (xsp + 14)
	ld (xwa + 3), c
	ld (xwa + 4), 0x1
	ld c, (xsp + 12)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 16)
	ret

SeMenu_RegisterElement_Type2:
	lda xsp, (xsp - 18)
	ld (xsp + 12), e
	ld (xsp + 14), c
	ld (xsp + 16), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterElement_Type2_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterElement_Type2_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	lda xde, (xwa + 2)
	ld c, (xsp + 14)
	ld (xde), c
	cp (xsp + 16), 0x0
	jr nz, SeMenu_RegisterElement_Type2_SetMode
	ld (xwa), 0x86
	jr SeMenu_RegisterElement_Type2_Finalize

SeMenu_RegisterElement_Type2_SetMode:
	cp (xsp + 16), 0x1
	jr nz, SeMenu_RegisterElement_Type2_SetMode2
	ld (xwa), 0x87
	jr SeMenu_RegisterElement_Type2_Finalize

SeMenu_RegisterElement_Type2_SetMode2:
	cp (xsp + 16), 0x2
	jr nz, SeMenu_RegisterElement_Type2_Branch
	ld (xwa), 0x87
	ld c, (xde)
	set 6, c
	ld (xde), c
	jr SeMenu_RegisterElement_Type2_Finalize

SeMenu_RegisterElement_Type2_Branch:
	ld (xwa), 0x85

SeMenu_RegisterElement_Type2_Finalize:
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld c, (xsp + 12)
	ld (xwa + 3), c
	ld (xwa + 4), 0x1
	ld c, (xsp + 22)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 18)
	retd 0x2

SeMenu_RegisterParamDisplay:
	lda xsp, (xsp - 14)
	ld (xsp + 12), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_RegisterParamDisplay_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_RegisterParamDisplay_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x80
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 3), 0x0
	ld (xwa + 4), 0x1
	ld c, (xsp + 12)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 14)
	ret

SeMenu_RegisterParamDisplay_Data:
	lda	xsp, (xsp-20)
	pushw	iz
	ld	iz, bc
	ld	(xsp+20), a
	lda	xwa, (xsp+12)
	calr	12557
	lda	xbc, (xsp+2)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+14)
	calr	64769
	lda	xhl, (xsp+16)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	stb_erp a, 248
	and a, 255
	ld	(xde), a
	lda	xwa, (xsp+2)
	ld	(xwa), 136
	ld	c, (xsp+14)
	ld	(xwa+1), c
	lda	xbc, (xwa+2)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 5
	ld	(xbc), 9
	jr	3
	ld	(xbc), 21
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	ld	c, (xsp+20)
	dec	1, c
	ld	(xwa+5), c
	calr	64706
	popw	iz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	pushw	iz
	ld	iz, de
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+12)
	calr	12441
	lda	xbc, (xsp+2)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+14)
	calr	64653
	lda	xhl, (xsp+16)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	stb_erp a, 248
	and a, 255
	ld	(xde), a
	lda	xwa, (xsp+2)
	ld	(xwa), 136
	ld	c, (xsp+14)
	ld	(xwa+1), c
	lda	xbc, (xwa+2)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 5
	ld	(xbc), 10
	jr	3
	ld	(xbc), 22
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	lda	xhl, (xwa+5)
	ld	e, (xsp+20)
	dec	1, e
	ld	(xhl), e
	sll	e, 4
	ld	(xhl), e
	ld	c, (xsp+22)
	dec	1, c
	add	e, c
	ld	(xhl), e
	calr	64574
	popw	iz
	lda	xsp, (xsp+22)
	ret

SeMenu_SetupDisplayObject:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 4)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_SetupDisplayObject_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetupDisplayObject_ClearLoop
	lda xwa, (xsp + 14)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp + 4)
	ld (xwa), 0x88
	ld c, (xsp + 14)
	ld (xwa + 1), c
	ld (xwa + 2), 0x13
	ld (xwa + 3), 0x0
	ld c, (xiz)
	ld (xwa + 4), c
	ld (xwa + 5), 0x0
	calr SeMenu_FlushDisplayObj
	pop xiz
	lda xsp, (xsp + 12)
	ret

SeMenu_SetupDisplayObject_Data:
	lda	xsp, (xsp-16)
	pushw	iz
	ld	iz, wa
	lda	xbc, (xsp+2)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+12)
	calr	64468
	lda	xhl, (xsp+14)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	stb_erp a, 248
	and a, 255
	ld	(xde), a
	lda	xwa, (xsp+2)
	ld	(xwa), 136
	ld	c, (xsp+12)
	ld	(xwa+1), c
	ld	(xwa+2), 20
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	ld	(xwa+5), 0
	calr	64422
	popw	iz
	lda	xsp, (xsp+16)
	ret

SeMenu_SetupDisplayObject_Alt1:
	lda xsp, (xsp - 20)
	ld (xsp + 12), xde
	ld (xsp + 16), c
	ld (xsp + 18), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_SetupDisplayObject_Alt1_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetupDisplayObject_Alt1_ClearLoop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	lda xde, (xwa + 2)
	ld c, (xsp + 16)
	ld (xde), c
	cp (xsp + 18), 0x0
	jr nz, SeMenu_SetupDisplayObject_Alt2
	ld (xwa), 0x8e
	jr SeMenu_SetupDisplayObject_Alt2_Continue

SeMenu_SetupDisplayObject_Alt2:
	cp (xsp + 18), 0x1
	jr nz, SeMenu_SetupDisplayObject_Alt2_ClearLoop
	ld (xwa), 0x8f
	jr SeMenu_SetupDisplayObject_Alt2_Continue

SeMenu_SetupDisplayObject_Alt2_ClearLoop:
	cp (xsp + 18), 0x2
	jr nz, SeMenu_SetupDisplayObject_Alt2_Branch
	ld (xwa), 0x8f
	ld c, (xde)
	set 6, c
	ld (xde), c
	jr SeMenu_SetupDisplayObject_Alt2_Continue

SeMenu_SetupDisplayObject_Alt2_Branch:
	ld (xwa), 0x8d

SeMenu_SetupDisplayObject_Alt2_Continue:
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 3), 0x1
	ld xbc, (xsp + 12)
	ld c, (xbc)
	ld (xwa + 4), c
	ld c, (xsp + 24)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 20)
	retd 0x2
	lda xsp, (xsp - 14)
	ld (xsp + 12), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_SetupDisplayObject_Alt3:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetupDisplayObject_Alt3
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x88
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x0
	ld c, (xsp + 12)
	ld (xwa + 4), c
	ld (xwa + 5), 0x0
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 14)
	ret

SeMenu_ClearDisplayBuffer:
	lda xsp, (xsp - 12)
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_ClearDisplayBuffer_Loop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_ClearDisplayBuffer_Loop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x88
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 2), 0xd
	ld (xwa + 3), 0x0
	ld (xwa + 4), 0x0
	ld (xwa + 5), 0x0
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 12)
	ret

SeMenu_InitDisplayColumn:
	lda xsp, (xsp - 10)
	lda xde, (xsp)
	ld xhl, xde
	lda xix, (xde + 9)

SeMenu_InitDisplayColumn_Loop:
	stib_dsp 0xec, 0x00
	cp xhl, xix
	jr c, SeMenu_InitDisplayColumn_Loop
	ld (xde), 0x80
	ld (xde + 1), 0x0
	ld (xde + 2), 0xb
	ld (xde + 3), a
	ld (xde + 4), 0x1
	ld (xde + 5), c
	ld xwa, xde
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 10)
	ret

SeMenu_InitDisplayColumn_Data:
	lda	xsp, (xsp-18)
	ld	(xsp+12), xbc
	ld	(xsp+16), a
	lda	xbc, (xsp)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+10)
	calr	64091
	lda	xwa, (xsp)
	ld	(xwa), 136
	ld	c, (xsp+10)
	ld	(xwa+1), c
	ld	(xwa+2), 11
	ld	c, (xsp+16)
	dec	1, c
	ld	(xwa+3), c
	ld	xbc, (xsp+12)
	ld	c, (xbc)
	ld	(xwa+4), c
	ld	(xwa+5), 255
	calr	64061
	lda	xsp, (xsp+18)
	ret

SeMenu_SetDisplayValue:
	lda xsp, (xsp - 14)
	ld (xsp + 12), a
	lda xbc, (xsp)
	ld xwa, xbc
	lda xbc, (xbc + 9)

SeMenu_SetDisplayValue_Loop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetDisplayValue_Loop
	lda xwa, (xsp + 10)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp)
	ld (xwa), 0x80
	ld c, (xsp + 10)
	ld (xwa + 1), c
	ld (xwa + 2), 0xc
	ld (xwa + 3), 0x0
	ld (xwa + 4), 0x1
	ld c, (xsp + 12)
	ld (xwa + 5), c
	calr SeMenu_FlushDisplayObj
	lda xsp, (xsp + 14)
	ret
SeMenu_SetDisplayValue_Data:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp)
	calr	-1561
	ld	c, (xsp+8)
	ld	a, c
	extz	wa
	div	a, 20
	ld	e, a
	ld	a, c
	extz	wa
	div	a, 20
	ld	c, w
	cps	e, 0
	jr	z, 4
	ldb	e, 17
	jr	2
	ldb	e, 16
	lda	xwa, (xsp+2)
	ld	(xwa), e
	ld	(xwa+1), c
	ld	c, (xsp)
	ld	(xwa+2), c
	call	16703634
	lda	xwa, (xsp+2)
	ld	e, (xwa+3)
	ld	c, (xwa+4)
	.byte 0x87, 0x3f, 0x01
	jr	nz, 8
	lda	xwa, (63952:16)
	ld	(xwa), e
	jr	19
	.byte 0x87, 0x3f, 0x02
	jr	nz, 8
	lda	xwa, (63978:16)
	ld	(xwa), e
	jr	6
	lda	xwa, (63926:16)
	ld	(xwa), e
	ld	(xwa+1), c
	extz	bc
	pushw	bc
	extz	de
	pushw	de
	ld	a, (xsp+4)
	extz	wa
	pushw	wa
	call	15789342
	lda	xsp, (xsp+16)
	ret
SeMenu_InitTrackInfo:
	dec 0,XSP
	lda XWA, (XSP)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp + 0x02)
	ld (XWA),0x0f
	ld (XWA+0x01),0x0f
	ld C,(XSP)
	ld (XWA+0x02),C
	call 0xfee092
	lda xwa, (xsp + 0x02)
	ld E,(XWA+0x03)
	ld C,(XWA+0x04)
	cp (XSP),0x01
	jr nz, SeMenu_InitTrackInfo_Part1
	lda xwa, (0xf9d0:16)
	ld (XWA),E
	jr t, SeMenu_InitTrackInfo_Store
SeMenu_InitTrackInfo_Part1:
	cp (xsp), 0x2
	jr nz, SeMenu_InitTrackInfo_Part2
	lda xwa, (0xf9ea:16)
	ld (xwa), e
	jr SeMenu_InitTrackInfo_Store

SeMenu_InitTrackInfo_Part2:
	lda xwa, (0xf9b6:16)
	ld (xwa), e

SeMenu_InitTrackInfo_Store:
	ld (xwa + 1), c
	extz bc
	pushw bc
	extz de
	pushw de
	ld a, (xsp + 4)
	extz wa
	pushw wa
	call SeMenu_DisplayPartValue
	lda xsp, (xsp + 14)
	ret

SeMenu_SetObjectFlags:
	lda xde, (xbc + 2)
	cp a, 0x44
	jrl z, SeMenu_SetFlags_Type0x4x
	cp a, 0x43
	jrl z, SeMenu_SetFlags_Type0x4x
	cp a, 0x42
	jr z, SeMenu_SetFlags_Type0x4x
	cp a, 0x41
	jr z, SeMenu_SetFlags_Type0x4x
	cp a, 0x34
	jr z, SeMenu_SetFlags_Type0x3x
	cp a, 0x33
	jr z, SeMenu_SetFlags_Type0x3x
	cp a, 0x32
	jr z, SeMenu_SetFlags_Type0x3x
	cp a, 0x31
	jr z, SeMenu_SetFlags_Type0x3x
	cp a, 0x24
	jr z, SeMenu_SetFlags_Type0x2x
	cp a, 0x23
	jr z, SeMenu_SetFlags_Type0x2x
	cp a, 0x22
	jr z, SeMenu_SetFlags_Type0x2x
	cp a, 0x21
	jr z, SeMenu_SetFlags_Type0x2x
	cp a, 0x14
	jr z, SeMenu_SetFlags_Type0x1x
	cp a, 0x13
	jr z, SeMenu_SetFlags_Type0x1x
	cp a, 0x12
	jr z, SeMenu_SetFlags_Type0x1x
	cp a, 0x11
	jr z, SeMenu_SetFlags_Type0x1x
	cps a, 4
	jr z, SeMenu_SetFlags_Type4
	cps a, 3
	jr z, SeMenu_SetFlags_Type3
	cps a, 2
	jr z, SeMenu_SetFlags_Type2
	cps a, 1
	jr z, SeMenu_SetFlags_Type1
	cps a, 0
	ret nz
	ldb a, 0x0
	jr SeMenu_SetFlags_SetCarryAndStore

SeMenu_SetFlags_Type1:
	ldb a, 0x1
	jr SeMenu_SetFlags_SetCarryAndStore

SeMenu_SetFlags_Type2:
	ldb a, 0x1
	jr SeMenu_SetFlags_SetCarryAndStore_Alt

SeMenu_SetFlags_Type3:
	ormi8 (xbc), 0x3
	ret

SeMenu_SetFlags_Type4:
	ormi8 (xbc), 0x3
	jr SeMenu_SetFlags_SetBit7_DE

SeMenu_SetFlags_Type0x1x:
	ldb a, 0x2

SeMenu_SetFlags_SetCarryAndStore:
	scf
	mri_d2 0xb1, 0x2c
	ret

SeMenu_SetFlags_Type0x2x:
	setm 2, (xbc)
	setm 6, (xde)
	ret

SeMenu_SetFlags_Type0x3x:
	ldb a, 0x2

SeMenu_SetFlags_SetCarryAndStore_Alt:
	scf
	mri_d2 0xb1, 0x2c

SeMenu_SetFlags_SetBit7_DE:
	setm 7, (xde)
	ret

SeMenu_SetFlags_Type0x4x:
	setm 2, (xbc)
	ormi8 (xde), 0xc0
	ret

SeMenu_SetupMenuDisplay:
	lda xsp, (xsp - 14)
	pushw_erp 0xfa
	ld (xsp + 14), a
	lda xwa, (xsp + 10)
	calr SeMenu_LoadObjEntries
	lda xwa, (xsp + 8)
	calr SeMenu_LoadRawAddr
	lda xbc, (xsp + 12)
	cp (xsp + 10), 0x0
	jr nz, SeMenu_SetupMenuDisplay_ValidatePart
	cp (xsp + 8), 0x22
	jr nz, SeMenu_SetupMenuDisplay_ValidatePart
	lds wa, 0
	calr SeMenu_LoadPartParam
	jr SeMenu_SetupMenuDisplay_ConfigObj

SeMenu_SetupMenuDisplay_ValidatePart:
	ld xwa, xbc
	calr SeMenu_ValidatePartNumber

SeMenu_SetupMenuDisplay_ConfigObj:
	lda xwa, (xsp + 6)
	calr SeMenu_SetupMenuDisplay_Finalize
	lda xde, (xsp + 2)
	ld xwa, xde
	lda xbc, (xde + 4)

SeMenu_SetupMenuDisplay_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetupMenuDisplay_ClearLoop
	cp (xsp + 6), 0x0
	jr z, SeMenu_SetupMenuDisplay_Data
	cp (xsp + 14), 0x0
	jr nz, SeMenu_SetupMenuDisplay_Section2

SeMenu_SetupMenuDisplay_Data:
	ldib_erp 0xfb, 0

SeMenu_SetupMenuDisplay_Data2:
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	lda xde, (xsp + 2)
	exts xbc
	add xbc, xde
	calr SeMenu_LoadParamByte
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr c, SeMenu_SetupMenuDisplay_Data2
	jr SeMenu_SetupMenuDisplay_Section2_Loop

SeMenu_SetupMenuDisplay_Section2:
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 12)
	dec 1, c
	extz bc
	exts xbc
	add xbc, xde
	calr SeMenu_LoadParamByte

SeMenu_SetupMenuDisplay_Section2_Loop:
	ldib_erp 0xfb, 0
	cp (xsp + 10), 0x0
	jr nz, SeMenu_SetupMenuDisplay_Section3

SeMenu_SetupMenuDisplay_Section2_End:
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	lda xde, (xsp + 2)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	pushw 0x7f
	ldw bc, 0x17
	calr SeMenu_RegisterElement_Extended
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr c, SeMenu_SetupMenuDisplay_Section2_End
	jr SeMenu_SetupMenuDisplay_Section3_Loop

SeMenu_SetupMenuDisplay_Section3:
	stb_erp E, 0xfb
	extz de
	ld wa, de
	muls wa, 0x15
	extz xwa
	lda xwa, (xwa + 16)
	inc 5, xwa
	ld c, a
	lda xwa, (xsp + 2)
	exts xde
	add xde, xwa
	pushw 0x7f
	lds wa, 0
	calr SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, SeMenu_SetupMenuDisplay_Section3

SeMenu_SetupMenuDisplay_Section3_Loop:
	popw_erp 0xfa
	lda xsp, (xsp + 14)
	ret

SeMenu_SetupMenuDisplay_Section3_End:
	cps	a, 0
	scc8	nz, a
	ld	(1628:16), a
	ret

SeMenu_SetupMenuDisplay_Finalize:
	ldmi16 (xwa), 0x65c
	ret

SeMenu_SetupMenuDisplay_Finalize_Data:
	cps	a, 1
	jr	c, 9
	cps	a, 4
	jr	ugt, 5
	ld	(1629:16), a
	ret
	ld	(1629:16), 1
	ret

SeMenu_ValidatePartNumber:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld c, (1629:16)
	cps c, 1
	jr c, SeMenu_ValidatePartNumber_Default
	cps c, 4
	jr ugt, SeMenu_ValidatePartNumber_Default
	ld xwa, (xsp + 2)
	ld (xwa), c
	jr SeMenu_ValidatePartNumber_CheckEnabled

SeMenu_ValidatePartNumber_Default:
	ld xwa, (xsp + 2)
	ld (xwa), 0x1
	ld (1629:16), 1

SeMenu_ValidatePartNumber_CheckEnabled:
	ld xwa, (xsp + 2)
	ld a, (xwa)
	extz wa
	calr SeMenu_IsPartEnabled
	cps hl, 0
	jr nz, SeMenu_ValidatePartNumber_End
	ldib_erp 0xfb, 1

SeMenu_ValidatePartNumber_ScanLoop:
	stb_erp A, 0xfb
	extz wa
	calr SeMenu_IsPartEnabled
	cps hl, 0
	jr z, SeMenu_ValidatePartNumber_NextPart
	stb_erp C, 0xfb
	jr SeMenu_ValidatePartNumber_Store

SeMenu_ValidatePartNumber_NextPart:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, SeMenu_ValidatePartNumber_ScanLoop
	ldb c, 0x1

SeMenu_ValidatePartNumber_Store:
	ld xwa, (xsp + 2)
	ld (xwa), c
	ld (1629:16), c

SeMenu_ValidatePartNumber_End:
	popw_erp 0xfa
	inc 4, xsp
	ret

SeMenu_StorePartMask:
	ld (1630:16), a
	ret

SeMenu_PartMask_Data:
	.byte 0xb0
	push_a
	pop	xiz
	ei	14
	dec	8, xsp
	ld	(xsp+4), c
	ld	(xsp+6), a
	.byte 0x8f, 0x06
	push	xsp
	normal
	jr	c, 6
	.byte 0x8f, 0x06
	push	xsp
	max
	jr	ule, 2
	jr	77
	lda	xwa, (xsp)
	calr	10987
	ld	a, (xsp+6)
	.byte 0x8f, 0x06
	and	(xbc), a
	jr	gt, -55
	.byte 0x8b
	extz	bc
	lds	wa, 1
	calr	122
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 10
	ld	a, l
	cpl	a
	and	(1630:16), a
	jr	4
	orddm8	1630, l
	.byte 0xbf
	push	sr
	push_a
	pop	xiz
	.byte 0x06
	extz	hl
	lda	xde, (xsp+2)
	.byte 0x87
	push	xsp
	nop
	jr	nz, 11
	pushw	hl
	lds	wa, 0
	ldw	bc, 17
	calr	63197
	jr	9
	pushw	hl
	lds	wa, 0
	ldw	bc, 13
	calr	64276
	inc	8, xsp
	ret

SeMenu_IsPartEnabled:
	cps a, 1
	jr c, SeMenu_IsPartEnabled_OutOfRange
	cps a, 4
	jr ule, SeMenu_IsPartEnabled_CheckMask

SeMenu_IsPartEnabled_OutOfRange:
	lds hl, 0
	ret

SeMenu_IsPartEnabled_CheckMask:
	ld c, a
	add c, a
	dec 2, c
	extz bc
	lds wa, 1
	calr SeMenu_BitShiftMask
	ld a, (1630:16)
	and a, l
	cps a, 0
	scc16 nz, hl
	ret

SeMenu_StorePartParam:
	extz wa
	lda xde, (1632:16)
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_LoadPartParam:
	extz wa
	lda xde, (1632:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ret

SeMenu_BitShift_Stub:
	ret

SeMenu_BitShiftMask:
	ld l, a
	lds de, 0
	extz bc
	cps bc, 0
	ret ule

SeMenu_BitShiftMask_Loop:
	add l, l
	inc 1, de
	cp de, bc
	jr c, SeMenu_BitShiftMask_Loop
	ret

SeMenu_BitShiftMask_End:
	ld	l, a
	lds	de, 0
	extz	bc
	cps	bc, 0
	ret	ule
	srl	l, 1
	inc	1, de
	cp	de, bc
	jr	c, -9
	ret
	.byte 0x88, 0x06
	push	xsp
	nop
	jr	z, 12
	.byte 0x88
	reti
	push	xsp
	reti
	jr	ugt, 6
	.byte 0x88
	ldwio	63, 0x6e00
	pop	sr
	ldb	l, 0
	ret
	.byte 0x88
	push	63
	nop
	jr	lt, 5
	calr	6
	jr	3
	calr	179
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xwa+3)
	ld	(xsp+6), xbc
	ld	c, (xwa+6)
	ld	(xsp+10), c
	ld	c, (xwa+7)
	ld	(xsp+12), c
	ld	c, (xwa+8)
	ld	(xsp+14), c
	ld	c, (xwa+9)
	ld	(xsp+16), c
	ld	a, (xwa+10)
	ld	(xsp+18), a
	ld	a, (xiz)
	ld	(xsp+4), a
	ld	a, (xsp+10)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	65401
	cpl	l
	and	(xsp+4), l
	ld	a, (xiz)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	65403
	ld	(xiz), l
	ld	a, (xsp+10)
	and	(xiz), a
	ld	c, (xsp+18)
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	le, 55
	ld	a, (xiz)
	.byte 0x8f
	ret
	.byte 0xf1
	jr	z, 55
	ld	a, (xsp+14)
	.byte 0x86
	and	(xbc), xhl
	.byte 0xf1
	jr	ugt, 5
	ld	a, (xsp+14)
	jr	60
	ld	a, (xsp+18)
	add	(xiz), a
	ld	a, (xiz)
	.byte 0x8f
	ldwio	193, 4824
	ld	c, (xsp+12)
	extz	bc
	calr	65327
	ld	xwa, (xsp+6)
	ld	(xwa), l
	ld	c, (xsp+4)
	or	(xwa), c
	lds	hl, 1
	jr	9
	ld	a, (xiz)
	cp	a, (xsp+16)
	jr	nz, 7
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	ld	a, (xsp+16)
	sub	a, c
	.byte 0x86, 0xf1
	jr	c, -57
	ld	a, (xsp+16)
	ld	(xiz), a
	jr	-59
	lda	xsp, (xsp-16)
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xwa+3)
	ld	(xsp+6), xbc
	ld	c, (xwa+6)
	ld	(xsp+10), c
	ld	c, (xwa+7)
	ld	(xsp+12), c
	ld	c, (xwa+8)
	ld	(xsp+14), c
	ld	c, (xwa+9)
	ld	(xsp+16), c
	ld	a, (xwa+10)
	ld	(xsp+18), a
	ld	a, (xiz)
	ld	(xsp+4), a
	ld	a, (xsp+10)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	65223
	cpl	l
	and	(xsp+4), l
	ld	a, (xiz)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	65225
	ld	(xiz), l
	ld	a, (xsp+10)
	and	(xiz), a
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	le, 62
	ld	a, (xiz)
	.byte 0x8f
	ret
	.byte 0xf1
	jr	z, 62
	ld	c, (xiz)
	ld	a, (xsp+14)
	sub	a, c
	ld	c, a
	ld	a, (xsp+18)
	cp	c, a
	jr	ugt, 5
	ld	a, (xsp+14)
	jr	63
	ld	a, (xsp+18)
	add	(xiz), a
	ld	a, (xiz)
	.byte 0x8f
	ldwio	193, 4824
	ld	c, (xsp+12)
	extz	bc
	calr	65145
	ld	xwa, (xsp+6)
	ld	(xwa), l
	ld	c, (xsp+4)
	or	(xwa), c
	lds	hl, 1
	jr	9
	ld	a, (xiz)
	cp	a, (xsp+16)
	jr	nz, 7
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	ld	c, (xiz)
	ld	a, (xsp+16)
	.byte 0x8f
	ccf
	and	(xbc), xhl
	.byte 0xf1
	jr	lt, -60
	ld	a, (xsp+16)
	ld	(xiz), a
	jr	-62
	dec	2, xsp
	lda	xwa, (xsp)
	calr	64794
	.byte 0x87
	push	xsp
	nop
	jr	z, 4
	lds	wa, 0
	jr	2
	lds	wa, 1
	calr	64771
	lds	wa, 1
	calr	64532
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	inc	2, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	calr	64781
	lda	xwa, (xsp)
	calr	10361
	lda	xde, (xsp+4)
	.byte 0x87
	push	xsp
	nop
	jr	nz, 16
	ld	a, (xsp+2)
	extz	wa
	pushw	7
	ldw	bc, 54
	calr	62610
	jr	29
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	ld	c, a
	pushw	7
	lds	wa, 0
	calr	63669
	.byte 0x8f, 0x04
	pop_f
	xor	(xix+6), c
	.byte 0xa8
	inc	6, xsp
	ret

SeMenu_TransferPartValues:
	cps c, 0
	jr z, SeMenu_TransferPartValues_Loop
	cps c, 4
	jr ule, SeMenu_TransferPartValues_InnerLoop

SeMenu_TransferPartValues_Loop:
	ldw hl, 0xffff
	ret

SeMenu_TransferPartValues_InnerLoop:
	dec 1, c
	extz bc
	sla bc, 2
	cps a, 0
	jr nz, SeMenu_TransferPartValues_Data2
	extz xbc
	lda xbc, (xbc + 59)
	ld (xde), c

SeMenu_TransferPartValues_Data:
	lds hl, 0
	ret

SeMenu_TransferPartValues_Data2:
	cps a, 2
	jr nz, SeMenu_TransferPartValues_AltEntry
	ld xwa, 0x4b
	jr SeMenu_TransferPartValues_AltLoop

SeMenu_TransferPartValues_AltEntry:
	cps a, 1
	jr nz, SeMenu_TransferPartValues_Loop
	ld xwa, 0x2b

SeMenu_TransferPartValues_AltLoop:
	lda_dri XWA, 0x07, 0xe0, 0xe4
	ld (xde), a
	jr SeMenu_TransferPartValues_Data
	cps a, 1
	jr nz, SeMenu_TransferPartValues_AltData
	ldb a, 0x6

SeMenu_TransferPartValues_AltInner:
	ld (xbc), a
	lds hl, 0
	ret

SeMenu_TransferPartValues_AltData:
	cps a, 0
	jr nz, SeMenu_TransferPartValues_End
	ldb a, 0x26
	jr SeMenu_TransferPartValues_AltInner

SeMenu_TransferPartValues_End:
	cps a, 2
	jr nz, SeMenu_TransferPartValues_End2
	ldb a, 0x38
	jr SeMenu_TransferPartValues_AltInner

SeMenu_TransferPartValues_End2:
	ldw hl, 0xffff
	ret

SeMenu_TransferPartValues_EndData:
	cps	a, 1
	jr	nz, 23
	ld	a, (1678:16)
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	ld	(1678:16), 1
	ld	a, (1678:16)
	jr	56
	cps	a, 0
	jr	nz, 23
	ld	a, (1677:16)
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	ld	(1677:16), 1
	ld	a, (1677:16)
	jr	29
	cps	a, 2
	jr	nz, 23
	ld	a, (1679:16)
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	ld	(1679:16), 1
	ld	a, (1679:16)
	jr	2
	ldb	a, 1
	ld	(xbc), a
	ret
	cps	a, 0
	jr	nz, 12
	lda	xwa, (1677:16)
	cps	c, 0
	jr	z, 24
	decm8	1, (xwa)
	jr	22
	cps	a, 1
	jr	nz, 6
	lda	xwa, (1678:16)
	jr	-18
	cps	a, 2
	ret	nz
	lda	xwa, (1679:16)
	jr	-28
	incm8	1, (xwa)
	.byte 0x80
	push	xsp
	nop
	jr	nz, 3
	ld	(xwa), 4
	.byte 0x80
	push	xsp
	halt
	ret	nz
	ld	(xwa), 1
	ret
	ld	c, (1685:16)
	cps	c, 1
	jr	c, 4
	cps	c, 6
	jr	ule, 2
	ldb	c, 1
	ld	(xwa), c
	ret
	ld	(1685:16), a
	ret
	cps	a, 6
	jr	z, 16
	cps	a, 5
	jr	z, 8
	cps	a, 2
	jr	nz, 12
	ldb	a, 26
	jr	10
	ldb	a, 35
	jr	6
	ldb	a, 38
	jr	2
	ldb	a, 23
	ld	(xbc), a
	ret
	cps	a, 6
	jr	z, 16
	cps	a, 5
	jr	z, 8
	cps	a, 2
	jr	nz, 12
	ldb	a, 24
	jr	10
	ldb	a, 33
	jr	6
	ldb	a, 36
	jr	2
	ldb	a, 21
	ld	(xbc), a
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	9966
	lda	xbc, (xsp+16)
	ldw	wa, 11
	calr	64629
	lda	xwa, (xsp+2)
	ld	c, (xsp+16)
	ld	(xwa), c
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 127
	ld	(xwa+9), 0
	ld	c, (xsp+20)
	ld	(xwa+10), c
	calr	64651
	cps	l, 0
	jr	z, 69
	ld	a, (xsp+22)
	inc	2, a
	ldb_erp a, 251
	ldw	wa, 127
	lds	bc, 0
	calr	64592
	stb_erp c, 251
	extz	bc
	extz	hl
	lda	xde, (xsp+5)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 8
	pushw	hl
	lds	wa, 0
	calr	62153
	jr	6
	pushw	hl
	lds	wa, 3
	calr	63235
	ld	c, (xsp+5)
	extz	bc
	ldw	wa, 11
	calr	64522
	pushw	11
	pushw	59
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	lda	xsp, (xsp+22)
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+6), e
	ld	(xsp+8), c
	ld	(xsp+10), a
	ld	xiz, (xsp+16)
	ld	xwa, xiz
	calr	64551
	extz	hl
	cps	hl, 0
	jr	nz, 4
	ldb	l, 0
	jr	83
	lda	xwa, (xsp+4)
	calr	9808
	ld	a, (xiz+6)
	extz	wa
	ld	c, (xiz+7)
	extz	bc
	calr	64483
	extz	hl
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+20)
	extz	bc
	lda	xde, (xiz+3)
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 6
	pushw	hl
	calr	62041
	jr	4
	pushw	hl
	calr	63125
	ld	a, (xsp+8)
	extz	wa
	ld	c, (xiz+3)
	extz	bc
	calr	64410
	ld	a, (xsp+8)
	extz	wa
	pushw	wa
	ld	a, (xsp+12)
	extz	wa
	pushw	wa
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ldb	l, 1
	pop	xiz
	inc	8, xsp
	retd	6
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	calr	64130
	ld	a, (xsp)
	.byte 0x8f
	push	sr
	.byte 0xf1
	jr	z, 12
	ld	a, (xsp+2)
	extz	wa
	calr	64324
	cps	hl, 0
	jr	nz, 4
	ldb	l, 0
	jr	10
	ld	a, (xsp+2)
	extz	wa
	calr	64080
	ldb	l, 1
	inc	4, xsp
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+10)
	extz	wa
	calr	64286
	cps	hl, 0
	jrl	z, 136
	ld	a, (xsp+10)
	inc	4, a
	ld	(xsp), a
	extz	wa
	lda	xbc, (xsp+6)
	calr	64314
	lda	xbc, (xsp+6)
	ld	a, (xbc)
	bit	5, a
	jr	nz, 40
	set	5, a
	ld	(xbc), a
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xsp+4)
	calr	64947
	lda	xde, (xsp+6)
	ld	c, (xde)
	and	c, 63
	ld	(xde), c
	ld	a, (xsp+4)
	dec	1, a
	sll	a, 6
	or	c, a
	ld	(xde), c
	jr	15
	bit	4, a
	jr	z, 5
	and	a, 15
	jr	3
	set	4, a
	ld	(xbc), a
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xsp+2)
	calr	64866
	ld	a, (xsp+10)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+6)
	pushw	240
	calr	61818
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	calr	64194
	ld	a, (xsp)
	extz	wa
	pushw	wa
	pushw	42
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-12)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+10), c
	ld	(xsp+12), a
	cp	(xsp+12), 1
	jr	c, 6
	.byte 0x8f
	incf
	push	xsp
	max
	jr	ule, 3
	jrl	204
	lda	xwa, (xsp+4)
	calr	9484
	lda	xbc, (xsp+6)
	ldw	wa, 13
	calr	64147
	lda	xbc, (xsp+8)
	ldw	wa, 12
	calr	64138
	ld	a, (xsp+12)
	.byte 0x8f
	incf
	and	(xbc), a
	jr	gt, -65
	push	sr
	ld	xbc, 0xd821088f
	ccf
	ld	c, (xsp+2)
	extz	bc
	calr	64149
	ldb_erp l, 251
	stb_erp a, 251
	and a, 3
	.byte 0xc7
	swi	2
	.byte 0x99, 0x8f
	ldwio	63, 0x6e00
	ex_ff
	cpib_erp 250, 0
	jr z, 27
	cpib_erp 250, 1
	jr	nz, 5
	ldib_erp 250, 3
	jr	30
	cpib_erp 250, 3
	jr nz, 25
	jr	116
	cpib_erp 250, 0
	jr z, 111
	cpib_erp 250, 3
	jr nz, 5
	ldib_erp 250, 1
	jr	8
	cpib_erp 250, 1
	jr nz, 3
	ldib_erp 250, 0
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 3
	calr	64057
	ldb_erp l, 251
	stb_erp a, 251
	cpl	a
	and	(xsp+8), a
	stb_erp a, 250
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	calr	64033
	or	(xsp+8), l
	ld	c, (xsp+6)
	extz	bc
	stb_erp a, 251
	extz	wa
	lda	xde, (xsp+8)
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 8
	pushw	wa
	lds	wa, 0
	calr	61588
	jr	6
	pushw	wa
	lds	wa, 3
	calr	62670
	ld	c, (xsp+8)
	extz	bc
	ldw	wa, 12
	calr	63957
	pushw	12
	pushw	59
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	lda	xsp, (xsp+12)
	ret

SeMenu_InitObjEntry:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	lda xwa, (xsp + 4)
	calr SeMenu_ValidatePartNumber
	ld a, (xsp + 4)
	ld (xiz), a
	sll a, 4
	ld (xiz), a
	incm8 1, (xiz)
	pop xiz
	inc 2, xsp
	ret

SeMenu_ReadObjData:
	ldmi16 (xwa), 0x693
	ret

SeMenu_SetCurrentStep:
	ld (1683:16), a
	ret

SeMenu_ResetSubIndex:
	ld (1684:16), 0
	ret

SeMenu_AdvanceSubIndex:
	ld l, (1684:16)
	inc 1, l
	ld (1684:16), l
	ret

SeMenu_ReadObjParam_Data:
	ld	(1684:16), a
	ret

SeMenu_ReadObjParam:
	ldmi16 (xwa), 0x694
	ret

SeMenu_CheckObjEnabled:
	ldw hl, 0xffff
	cp (0x020c33:24), a
	ret nz
	lds hl, 0
	ret

SeMenu_CheckObjValid:
	ldw hl, 0xffff
	cp (0x020c35:24), a
	ret nz
	lds hl, 0
	ret

SeMenu_FillEntryTable:
	lda xhl, (0x020c33:24)
	ld c, (xhl + 3)
	ldb_erp C, 0xe6
	ldib_erp 0xea, 0
	cpib_erp 0xe6, 0
	ret ule
	lds de, 6

SeMenu_FillEntryTable_Loop:
	ld ix, de
	ldw bc, 0xfffa
	add ix, bc
	ld bc, de
	ldb_sri C, 0x07, 0xec, 0xe4
	stb_dri C, 0x07, 0xe0, 0xf0
	inc1b_erp 0xea
	inc 1, de
	stb_erp C, 0xea
	cpb_erp C, 0xe6
	jr c, SeMenu_FillEntryTable_Loop
	ret

SeMenu_FillObjTable:
	ld xhl, xwa
	lda xde, (0x020c39:24)
	ld xbc, xde
	lda xde, (xde + 25)

SeMenu_FillObjTable_Loop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xec
	cp xbc, xde
	jr c, SeMenu_FillObjTable_Loop
	ret

SeMenu_SetupPartDisplay:
	cps a, 1
	jr nz, SeMenu_SetupPartDisplay_Alt
	ldb w, 0x0
	cps e, 0
	ret ule
	lda xix, (0x020bf3:24)
	lds hl, 0

SeMenu_SetupPartDisplay_Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Loop
	ret

SeMenu_SetupPartDisplay_Alt:
	cps a, 2
	jr nz, SeMenu_SetupPartDisplay_Mode2
	ldb w, 0x0
	cps e, 0
	ret ule
	lda xix, (0x020c03:24)
	lds hl, 0

SeMenu_SetupPartDisplay_AltLoop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_AltLoop
	ret

SeMenu_SetupPartDisplay_Mode2:
	cps a, 3
	jr nz, SeMenu_SetupPartDisplay_Mode3
	ldb w, 0x0
	cps e, 0
	ret ule
	lda xix, (0x020c13:24)
	lds hl, 0

SeMenu_SetupPartDisplay_Mode2Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Mode2Loop
	ret

SeMenu_SetupPartDisplay_Mode3:
	cps a, 4
	ret nz
	ldb w, 0x0
	cps e, 0
	ret ule
	lda xix, (0x020c23:24)
	lds hl, 0

SeMenu_SetupPartDisplay_Mode3Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Mode3Loop
	ret

SeMenu_SetupPartDisplay_End:
	cps a, 1
	jr nz, 32
	ldb w, 0
	cps e, 0
	ret ule
	lda xix, (134131:24)
	lds hl, 0
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, -18
	ret
	cps a, 2
	jr nz, 32
	ldb w, 0
	cps e, 0
	ret ule
	lda xix, (134147:24)
	lds hl, 0
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, -18
	ret
	cps a, 3
	jr nz, 32
	ldb w, 0
	cps e, 0
	ret ule
	lda xix, (134163:24)
	lds hl, 0
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, -18
	ret
	cps a, 4
	ret nz
	ldb w, 0
	cps e, 0
	ret ule
	lda xix, (134179:24)
	lds hl, 0
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, -18
	ret
	ld XHL,(XSP+0x04)
	bit 0x0f,BC
	jr z, .Lc_f07315
	ldb C, 0x01
	jr t, .Lc_f07317
.Lc_f07315:
	ldb C, 0x00
.Lc_f07317:
	ld (XHL),C
	ld C,A
	cp WA,0x0010
	jr ugt, .Lc_f07327
.Lc_f07321:
	ld (XDE),C
.Lc_f07323:
	lds hl, 0
	jr t, .Lc_f07349
.Lc_f07327:
	cp WA,0x0011
	jr c, .Lc_f0733c
	cp WA,0x0018
	jr ugt, .Lc_f0733c
	sub C,0x11
	ld (XDE),C
	set 7,(XHL)
	jr t, .Lc_f07323
.Lc_f0733c:
	cp WA,0x0019
	jr nz, .Lc_f07346
	ldb C, 0x10
	jr t, .Lc_f07321
.Lc_f07346:
	ldw HL, 0xffff
.Lc_f07349:
	retd 0x0004
	.byte 0xe9, 0x8b, 0x22, 0x00, 0xcd, 0xd8, 0xb0, 0xf3
	.byte 0xc5, 0xec, 0x23, 0xf5, 0xe0, 0x43, 0xca, 0x61
	.byte 0xcd, 0xf2, 0x67, 0xf4, 0x0e, 0xbf, 0xf0, 0x37
	.byte 0xd7, 0xfa, 0x04, 0xbf, 0x0e, 0x60, 0xbf, 0x06
	.byte 0x30, 0x1e, 0x1b, 0xee, 0x8f, 0x06, 0x3f, 0x01
	.byte 0x6e, 0x08, 0xf1, 0xd0, 0xf9, 0x30, 0x80, 0x25
	.byte 0x68, 0x14, 0x8f, 0x06, 0x3f, 0x02, 0x6e, 0x08
	.byte 0xf1, 0xea, 0xf9, 0x30, 0x80, 0x25, 0x68, 0x06
	.byte 0xf1, 0xb6, 0xf9, 0x30, 0x80, 0x25, 0x88, 0x01
	.byte 0x23, 0xbf, 0x08, 0x30, 0xb8, 0x03, 0x45, 0xb8
	.byte 0x04, 0x43, 0x8f, 0x06, 0x23, 0xb8, 0x02, 0x43
	.byte 0x1d, 0x1b, 0xe0, 0xfe, 0xbf, 0x08, 0x31, 0x81
	.byte 0x21, 0xc7, 0xfb, 0x99, 0x89, 0x01, 0x21, 0xbf
	.byte 0x02, 0x41, 0xc7, 0xfb, 0xcf, 0x10, 0x66, 0x14
	.byte 0xc7, 0xfb, 0xcf, 0x11, 0x66, 0x0e, 0xaf, 0x0e
	.byte 0x20, 0xb0, 0x14, 0xad, 0x06, 0x80, 0x3f, 0x27
	.byte 0x6b, 0x43, 0x68, 0x4c, 0xbf, 0x04, 0x30, 0x1e
	.byte 0xa6, 0x21, 0x8f, 0x04, 0x3f, 0x00, 0x6e, 0x29
	.byte 0xc7, 0xfb, 0xcf, 0x11, 0x6e, 0x05, 0xc7, 0xfb
	.byte 0xa9, 0x68, 0x03, 0xc7, 0xfb, 0xa8, 0xaf, 0x0e
	.byte 0x20, 0x8f, 0x02, 0x23, 0xb0, 0x43, 0xc7, 0xfb
	.byte 0x8b, 0xcb, 0x08, 0x14, 0x80, 0x8b, 0x80, 0x19
	.byte 0xad, 0x06, 0xd8, 0xa9, 0x1e, 0x74, 0x21, 0x68
	.byte 0x17, 0xaf, 0x0e, 0x20, 0xb0, 0x14, 0xad, 0x06
	.byte 0x80, 0x3f, 0x27, 0x63, 0x0b, 0xaf, 0x0e, 0x20
	.byte 0xb0, 0x00, 0x00, 0xf1, 0xad, 0x06, 0x00, 0x00
	.byte 0xd7, 0xfa, 0x05, 0xbf, 0x10, 0x37, 0x0e, 0xb0
	.byte 0x14, 0xad, 0x06, 0x0e, 0xf1, 0xad, 0x06, 0x41
	.byte 0x0e, 0xc9, 0xcf, 0x0f, 0xb0, 0xfb, 0xd8, 0x12
	.byte 0xf2, 0xf3, 0x0b, 0x02, 0x32, 0xf3, 0x07, 0xe8
	.byte 0xe0, 0x43, 0x0e, 0xc9, 0xcf, 0x0f, 0xb0, 0xfb
	.byte 0xd8, 0x12, 0xf2, 0xf3, 0x0b, 0x02, 0x32, 0xc3
	.byte 0x07, 0xe8, 0xe0, 0x21, 0xb1, 0x41, 0x0e, 0xd8
	.byte 0x12, 0x1b, 0x18, 0x91, 0xf9, 0xcb, 0x69, 0xcd
	.byte 0xe3, 0xd9, 0x12, 0xc9, 0xd8, 0x6e, 0x06, 0xd9
	.byte 0x88, 0x1b, 0x60, 0x91, 0xf9, 0xd9, 0x88, 0x1b
	.byte 0x4c, 0x91, 0xf9, 0xef, 0x6a, 0xb7, 0x41, 0xd8
	.byte 0xa9, 0x1e, 0xdb, 0xff, 0x87, 0x23, 0xd9, 0x12
	.byte 0xd8, 0xa8, 0xda, 0xa8, 0x1e, 0xd6, 0xff, 0x87
	.byte 0x23, 0xd9, 0x12, 0xd8, 0xa9, 0x32, 0x80, 0x00
	.byte 0x1e, 0xca, 0xff, 0xef, 0x62, 0x0e
	ld L,A
	res 0x07,L
	ldb E, 0xff
	cps l, 0
	jr nz, .Lc_f0749f
	ldb E, 0x01
.Lc_f0749f:
	ld (XBC),E
	bit 0x07,A
	ret Z
	.byte 0x81, 0x21, 0xc9, 0x09, 0x03, 0xb1, 0x41, 0x0e
	.byte 0xc9, 0xcf, 0x61, 0x67, 0x04, 0xb1, 0x00, 0x20
	.byte 0x0e, 0xd8, 0x12, 0xf2, 0x07, 0xe1, 0xe0, 0x32
	.byte 0xc3, 0x07, 0xe8, 0xe0, 0x21, 0xb1, 0x41, 0x0e
	.byte 0xc9, 0xcf, 0x82, 0x67, 0x05, 0xb1, 0x00, 0x00
	.byte 0x68, 0x0e, 0xd8, 0x12, 0xf2, 0x68, 0xe1, 0xe0
	.byte 0x32, 0xc3, 0x07, 0xe8, 0xe0, 0x21, 0xb1, 0x41
	.byte 0x81, 0x3f, 0x5f, 0xb0, 0xf3, 0xb1, 0x00, 0x00
	.byte 0x0e, 0xef, 0x6e, 0xd7, 0xfa, 0x04, 0xbf, 0x06
	.byte 0x41, 0xbf, 0x02, 0x30, 0x1e, 0x8c, 0x20, 0xc7
	.byte 0xfa, 0xaa, 0x8f, 0x02, 0x3f, 0x00, 0x6e, 0x03
	.byte 0xc7, 0xfa, 0xac, 0xbf, 0x04, 0x30, 0x1e, 0x09
	.byte 0xf5, 0x8f, 0x04, 0x21, 0xd8, 0x12, 0x1e, 0xd2
	.byte 0xf5, 0xdb, 0xd8, 0x66, 0x09, 0x8f, 0x06, 0x21
	.byte 0xd8, 0x12, 0xd9, 0xa8, 0x68, 0x3c, 0xc7, 0xfb
	.byte 0xa9, 0xc7, 0xfa, 0xd9, 0x67, 0x28, 0xc7, 0xfb
	.byte 0x89, 0xd8, 0x12, 0x1e, 0xb5, 0xf5, 0xdb, 0xd8
	.byte 0x66, 0x11, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0x1e
	.byte 0xc5, 0xf4, 0x8f, 0x06, 0x21, 0xd8, 0x12, 0xd9
	.byte 0xa8, 0x68, 0x17, 0xc7, 0xfb, 0x61, 0xc7, 0xfb
	.byte 0x89, 0xc7, 0xfa, 0xf1, 0x63, 0xd8, 0xd8, 0xa9
	.byte 0x1e, 0xac, 0xf4, 0x8f, 0x06, 0x21, 0xd8, 0x12
	.byte 0xd9, 0xa8, 0x1e, 0xeb, 0xeb, 0xd7, 0xfa, 0x05
	.byte 0xef, 0x66, 0x0e
SeMenu_ApplyPartEdit:
	lda xsp, (xsp - 14)
	pushw_erp 0xfa
	ld (xsp + 14), a
	lda xwa, (xsp + 6)
	calr SeMenu_LoadObjEntries
	cp (xsp + 6), 0x0
	jr nz, SeMenu_ApplyPartEdit_Store
	ld c, (xsp + 14)
	inc 5, c
	ld a, (xsp + 14)
	add a, 0xb
	ld (xsp + 4), a
	ld (xsp + 2), 0xb
	jr SeMenu_ApplyPartEdit_Data

SeMenu_ApplyPartEdit_Store:
	ld c, (xsp + 14)
	inc 8, c
	ld a, (xsp + 14)
	add a, 0xc
	ld (xsp + 4), a
	ld (xsp + 2), 0xc

SeMenu_ApplyPartEdit_Data:
	ld a, c
	extz wa
	lda xbc, (xsp + 8)
	calr SeMenu_LoadPartParam
	lda xhl, (xsp + 8)
	ld a, (xhl)
	ld c, a
	res 7, c
	ld a, c
	ld (xhl), c
	lda xde, (xhl + 1)
	inc 2, xhl
	cp c, 0x40
	jr nc, SeMenu_ApplyPartEdit_Alt
	ldb a, 0x40
	sub a, c
	ld (xde), a
	ld (xhl), 0x1
	jr SeMenu_ApplyPartEdit_End

SeMenu_ApplyPartEdit_Alt:
	cp a, 0x40
	jr nz, SeMenu_ApplyPartEdit_AltStore
	ld (xde), 0x0
	ld (xhl), 0x0
	jr SeMenu_ApplyPartEdit_End

SeMenu_ApplyPartEdit_AltStore:
	sub a, 0x40
	ld (xde), a
	ld (xhl), 0x2

SeMenu_ApplyPartEdit_End:
	ld a, (xsp + 4)
	extz wa
	ld c, (xde)
	extz bc
	calr SeMenu_StorePartParam
	ld a, (xsp + 10)
	extz wa
	ld c, (xsp + 14)
	add c, (xsp + 14)
	dec 2, c
	extz bc
	calr SeMenu_BitShiftMask
	ld (xsp + 4), l
	ld a, (xsp + 14)
	add a, (xsp + 14)
	dec 2, a
	ld c, a
	extz bc
	lds wa, 3
	calr SeMenu_BitShiftMask
	ldb_erp L, 0xfb
	ld a, (xsp + 2)
	extz wa
	lda xbc, (xsp + 11)
	calr SeMenu_LoadPartParam
	lda xde, (xsp + 11)
	stb_erp L, 0xfb
	cpl l
	ld c, (xde)
	and c, l
	ld (xde), c
	or c, (xsp + 4)
	ld (xde), c
	ld a, (xsp + 2)
	extz wa
	extz bc
	calr SeMenu_StorePartParam
	popw_erp 0xfa
	lda xsp, (xsp + 14)
	ret
SeMenu_ApplyPartEdit_Data2:
	dec	2, xsp
	ld	(xsp), c
	res	7, a
	cps	a, 0
	scc	z, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	-2140
	.byte 0x87, 0x3f, 0x01
	jr	nz, 11
	ldb	a, 42
	extz	wa
	lds	bc, 1
	calr	-5406
	jr	18
	.byte 0x87, 0x3f, 0x00
	jr	nz, 4
	ldb	a, 47
	jr	-18
	.byte 0x87, 0x3f, 0x02
	jr	nz, 4
	ldb	a, 57
	jr	-27
	inc	2, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2283
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2392
	lda	xbc, (xsp)
	lds	wa, 4
	calr	-2965
	lda	xbc, (xsp)
	ld	(xbc+6), 3
	ld	(xbc+7), 6
	ld	(xbc+8), 3
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-561
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 4
	lds	de, 0
	calr	-1996
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 16
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 2
	calr	8712
	lds	wa, 3
	calr	-645
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2408
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2517
	lda	xbc, (xsp)
	lds	wa, 4
	calr	-3090
	lda	xbc, (xsp)
	ld	(xbc+6), 31
	ld	(xbc+7), 0
	ld	(xbc+8), 30
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-686
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 4
	lds	de, 0
	calr	-2121
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 16
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 2
	calr	8587
	lds	wa, 4
	calr	-770
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2533
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2642
	lda	xbc, (xsp)
	lds	wa, 2
	calr	-3215
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-811
	ld	a, (xsp+12)
	inc	1, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 2
	lds	de, 0
	calr	-2246
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 16
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 1
	calr	8462
	lds	wa, 5
	calr	-895
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2658
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2767
	lda	xbc, (xsp)
	lds	wa, 1
	calr	-3340
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-936
	ld	a, (xsp+12)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 1
	lds	de, 0
	calr	-2369
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 16
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 0
	calr	8339
	lds	wa, 6
	calr	-1018
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2781
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2890
	lda	xbc, (xsp)
	lds	wa, 3
	calr	-3463
	lda	xbc, (xsp)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1059
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 3
	lds	de, 0
	calr	-2494
	lds	wa, 7
	calr	-1121
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-2884
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	-2993
	lda	xbc, (xsp)
	lds	wa, 3
	calr	-3566
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 7
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1162
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 3
	lds	de, 0
	calr	-2597
	ldw	wa, 8
	calr	-1225
	lda	xsp, (xsp+20)
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	lds	wa, 0
	calr	-3639
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 11
	.byte 0x87, 0x3f, 0x00
	jr	z, 30
	lds	wa, 0
	lds	bc, 0
	jr	9
	.byte 0x87, 0x3f, 0x01
	jr	z, 19
	lds	wa, 0
	lds	bc, 1
	calr	-3681
	pushw 0
	pushw 40
	call	15789873
	inc	4, xsp
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	-3700
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	-3969
	lda	xbc, (xsp)
	lds	wa, 3
	calr	-3719
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1315
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	lds	bc, 3
	calr	-2751
	calr	2598
	lds	wa, 1
	calr	-1381
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	-3800
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	-4069
	lda	xbc, (xsp)
	lds	wa, 4
	calr	-3819
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1415
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	lds	bc, 4
	calr	-2851
	calr	2498
	lds	wa, 2
	calr	-1481
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	-4161
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	-3912
	lda	xbc, (xsp+2)
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 35
	ldib_erp	250, 2
	lds	wa, 2
	calr	-3929
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp	a, 251
	jr	33
	ldib_erp	250, 5
	lds	wa, 5
	calr	-3964
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp	a, 251
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	-1567
	stb_erp	c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp	a, 251
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 55
	calr	-3006
	calr	2343
	lds	wa, 3
	calr	-1636
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	-4058
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	-4327
	lda	xbc, (xsp)
	lds	wa, 6
	calr	-4077
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1673
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	lds	bc, 6
	calr	-3109
	calr	2240
	lds	wa, 4
	calr	-1739
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	-4419
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	-4170
	lda	xbc, (xsp+2)
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 37
	ldi_erpb	250, 10
	ldw	wa, 10
	calr	-4189
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp	a, 251
	jr	33
	ldib_erp	250, 7
	lds	wa, 7
	calr	-4224
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp	a, 251
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	-1827
	stb_erp	c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp	a, 251
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 55
	calr	-3266
	calr	2083
	lds	wa, 5
	calr	-1896
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	-4318
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 75
	lda	xwa, (xsp+12)
	calr	-4587
	lda	xbc, (xsp)
	ldw	wa, 8
	calr	-4338
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-1934
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	ldw	bc, 8
	calr	-3371
	calr	1978
	lds	wa, 6
	calr	-2001
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	-4681
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	-4432
	lda	xbc, (xsp+2)
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 35
	ldib_erp	250, 1
	lds	wa, 1
	calr	-4449
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp	a, 251
	jr	35
	ldi_erpb	250, 9
	ldw	wa, 9
	calr	-4486
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp	a, 251
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	-2089
	stb_erp	c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp	a, 251
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 55
	calr	-3528
	calr	1821
	lds	wa, 7
	calr	-2158
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	-4835
	lda	xbc, (xsp)
	lds	wa, 3
	calr	-4585
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2181
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 3
	calr	-3617
	lda	xbc, (xsp+12)
	lds	wa, 3
	calr	-4645
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	-4669
	lds	wa, 2
	lds	bc, 1
	calr	3288
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	-4672
	.byte 0x8f, 0x0c, 0x3f, 0x00
	jr	z, 20
	ldw	wa, 9
	lds	bc, 0
	calr	-4699
	pushw 9
	pushw 41
	call	15789873
	inc	4, xsp
	lds	wa, 2
	calr	-2305
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	-4979
	lda	xbc, (xsp)
	lds	wa, 4
	calr	-4729
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2325
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 4
	calr	-3761
	lda	xbc, (xsp+12)
	lds	wa, 4
	calr	-4789
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	-4813
	lds	wa, 2
	lds	bc, 1
	calr	3144
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	-4816
	.byte 0x8f, 0x0c, 0x3f, 0x01
	jr	z, 20
	ldw	wa, 9
	lds	bc, 1
	calr	-4843
	pushw 9
	pushw 41
	call	15789873
	inc	4, xsp
	lds	wa, 3
	calr	-2449
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	-5123
	lda	xbc, (xsp)
	lds	wa, 5
	calr	-4873
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2469
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 5
	calr	-3905
	lda	xbc, (xsp+12)
	lds	wa, 5
	calr	-4933
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	-4957
	lds	wa, 2
	lds	bc, 1
	calr	3000
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	-4960
	.byte 0x8f, 0x0c, 0x3f, 0x02
	jr	z, 20
	ldw	wa, 9
	lds	bc, 2
	calr	-4987
	pushw 9
	pushw 41
	call	15789873
	inc	4, xsp
	lds	wa, 4
	calr	-2593
	lda	xsp, (xsp+20)
	ret
	dec	6, xsp
	ld	(xsp+4), c
	extz	wa
	pushw 127
	lds	bc, 2
	lds	de, 0
	calr	6424
	cps	l, 1
	jr	nz, 50
	lda	xwa, (xsp+2)
	calr	-5279
	lda	xbc, (xsp)
	lds	wa, 2
	calr	-5029
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp)
	pushw 127
	calr	-7448
	pushw 2
	pushw 41
	call	15789873
	inc	4, xsp
	lds	wa, 2
	lds	bc, 1
	calr	2885
	lds	wa, 5
	calr	-2673
	inc	6, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	-5346
	lda	xbc, (xsp)
	lds	wa, 0
	calr	-5096
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2692
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 0
	calr	-4128
	lds	wa, 7
	calr	-2755
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	-5429
	lda	xbc, (xsp)
	lds	wa, 1
	calr	-5179
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2775
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 1
	calr	-4211
	ldw	wa, 8
	calr	-2839
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-24)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+22), c
	ld	(xsp+24), a
	lda	xwa, (xsp+14)
	calr	5605
	lda	xbc, (xsp+18)
	lds	wa, 0
	calr	-5267
	lda	xbc, (xsp+18)
	ld	a, (xbc)
	ldb_erp	a, 251
	extz	wa
	calr	-5280
	lda	xbc, (xsp+2)
	ld	a, (xsp+18)
	ld	(xbc), a
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	lda	xwa, (xbc+8)
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	nz, 5
	ld	(xwa), 27
	jr	3
	ld	(xwa), 3
	ld	(xbc+9), 0
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xbc+10)
	calr	-2895
	lda	xwa, (xsp+2)
	calr	-5279
	cps	l, 0
	jr	z, 109
	stb_erp	a, 251
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	calr	-5364
	stb_erp	a, 251
	extz	wa
	.byte 0x8f, 0x16, 0x3f, 0x02
	jr	nz, 6
	pushw	wa
	pushw 59
	jr	10
	.byte 0x8f, 0x16, 0x3f, 0x03
	jr	nz, 10
	pushw	wa
	pushw 60
	call	15789873
	inc	4, xsp
	lda	xbc, (xsp+16)
	ldw	wa, 13
	calr	-5393
	incm8	1, (xsp+16)
	lda	xbc, (xsp+2)
	ld	a, (xbc+6)
	extz	wa
	ld	c, (xbc+7)
	extz	bc
	calr	-5396
	ld	c, (xsp+16)
	extz	bc
	extz	hl
	lda	xde, (xsp+5)
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	nz, 8
	pushw	hl
	lds	wa, 0
	calr	-7835
	jr	6
	pushw	hl
	lds	wa, 3
	calr	-6753
	lds	wa, 2
	calr	-3049
	pop qiz
	lda	xsp, (xsp+24)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	ldw	wa, 13
	calr	-5468
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp)
	calr	-3045
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	exts	bc
	calr	-4610
	lds	wa, 4
	calr	-3097
	inc	6, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	res	7, c
	cps	c, 0
	scc	nz, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	-4171
	ld	a, (xsp)
	inc	4, a
	extz	wa
	calr	-3129
	inc	2, xsp
	ret
	lda	xsp, (xsp-22)
	push	xiz
	.byte 0x0b, 0x90, 0x00, 0x0b, 0x00, 0x01, 0x0b, 0x3b, 0x00, 0x0b, 0x33, 0x00
	call	15790367
	inc	8, xsp
	lda	xbc, (xsp+18)
	lds	wa, 2
	calr	-5560
	lda	xbc, (xsp+19)
	lds	wa, 3
	calr	-5568
	lda	xbc, (xsp+20)
	lds	wa, 4
	calr	-5576
	lda	xbc, (xsp+21)
	lds	wa, 5
	calr	-5584
	lda	xbc, (xsp+22)
	lds	wa, 6
	calr	-5592
	lda	xwa, (xsp+24)
	calr	5266
	lda	xbc, (xsp+16)
	.byte 0x8f, 0x18, 0x3f, 0x00
	jr	nz, 15
	lds	wa, 0
	calr	-5612
	lda	xbc, (xsp+17)
	lds	wa, 1
	calr	-5620
	jr	33
	lds	wa, 1
	calr	-5627
	ld	(xsp+17), 100
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	-5639
	.byte 0xbf, 0x0e, 0xcd
	jr	nz, 11
	lda	xwa, (xsp+16)
	ld	(xwa+5), 0
	ld	(xwa+6), 0
	lda	xbc, (xsp+16)
	ld	xwa, xbc
	lda	xde, (xbc+6)
	ld	l, (xwa)
	res	7, l
	ld	(xwa), l
	cp	l, 100
	jr	ule, 3
	ld	(xwa), 100
	inc	1, xwa
	cp	xwa, xde
	jr	ule, -21
	ld	a, (xbc+1)
	extz	wa
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	mul	wa, 87
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	extz	xwa
	div	wa, 100
	ld	(xsp+6), wa
	ld	e, (xbc)
	ld	a, e
	extz	wa
	ld	(xsp+4), wa
	ld	wa, (xsp+4)
	.byte 0x9f, 0x06, 0x40
	ld	(xsp+4), wa
	ldb	l, 100
	sub	l, e
	extz	hl
	cps	hl, 0
	jr	nz, 12
	.byte 0x9f, 0x04, 0x38, 0x10, 0x27
	ldw	(xsp+6), 0
	jr	10
	ld	wa, (xsp+4)
	extz	xwa
	div	xwa, xhl
	ld	(xsp+4), wa
	ld	a, (xbc+3)
	extz	wa
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	mul	wa, 87
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	extz	xwa
	div	wa, 100
	ld	(xsp+10), wa
	ld	e, (xbc+2)
	ld	a, e
	extz	wa
	ld	(xsp+8), wa
	ld	wa, (xsp+10)
	.byte 0x9f, 0x06, 0xf0
	jr	c, 16
	ld	hl, (xsp+10)
	.byte 0x9f, 0x06, 0xa3
	ld	wa, (xsp+8)
	mul	xwa, xhl
	ld	(xsp+8), wa
	jr	14
	ld	hl, (xsp+6)
	.byte 0x9f, 0x0a, 0xa3
	ld	wa, (xsp+8)
	mul	xwa, xhl
	ld	(xsp+8), wa
	ldb	l, 100
	sub	l, e
	extz	hl
	cps	hl, 0
	jr	nz, 13
	.byte 0x9f, 0x08, 0x38, 0x10, 0x27
	ld	wa, (xsp+6)
	ld	(xsp+10), wa
	jr	10
	ld	wa, (xsp+8)
	extz	xwa
	div	xwa, xhl
	ld	(xsp+8), wa
	ld	a, (xbc+5)
	extz	wa
	ld	qiz, wa
	mul	wa, 87
	ld	qiz, wa
	extz	xwa
	div	wa, 100
	ld	qiz, wa
	ld	e, (xbc+4)
	ldb_erp	e, 248
	extz	iz
	ld	wa, qiz
	.byte 0x9f, 0x0a, 0xf0
	jr	c, 14
	ld	hl, qiz
	.byte 0x9f, 0x0a, 0xa3
	ld	wa, iz
	mul	xwa, xhl
	ld	iz, wa
	jr	12
	ld	hl, (xsp+10)
	sub	hl, qiz
	ld	wa, iz
	mul	xwa, xhl
	ld	iz, wa
	ldb	l, 100
	sub	l, e
	extz	hl
	cps	hl, 0
	jr	nz, 12
	add	iz, 10000
	ld	wa, (xsp+10)
	ld	qiz, wa
	jr	8
	ld	wa, iz
	extz	xwa
	div	xwa, xhl
	ld	iz, wa
	ld	c, (xbc+6)
	ld	e, c
	extz	de
	mul	de, qiz
	ldb	l, 100
	sub	l, c
	extz	hl
	cps	hl, 0
	jr	nz, 6
	add	de, 10000
	jr	4
	extz	xde
	div	xde, xhl
	ld	bc, (xsp+4)
	.byte 0x9f, 0x08, 0x81
	add	bc, iz
	extz	xbc
	div	bc, 162
	ld	wa, de
	extz	xwa
	div	wa, 45
	ld	de, wa
	cp	bc, de
	jr	c, 5
	ld	(xsp+12), c
	jr	3
	ld	(xsp+12), e
	.byte 0x8f, 0x0c, 0x3f, 0x05
	jr	ule, 4
	ld	(xsp+12), 5
	incm8	1, (xsp+12)
	ld	c, (xsp+12)
	extz	bc
	ld	wa, (xsp+4)
	extz	xwa
	div	xwa, xbc
	ld	(xsp+4), wa
	.byte 0x9f, 0x04, 0x38, 0x33, 0x00
	ld	wa, (xsp+8)
	extz	xwa
	div	xwa, xbc
	ld	(xsp+8), wa
	ld	wa, (xsp+4)
	add	(xsp+8), wa
	ld	wa, iz
	extz	xwa
	div	xwa, xbc
	ld	iz, wa
	.byte 0x9f, 0x08, 0x86
	ldw	wa, 146
	.byte 0x9f, 0x06, 0xa0
	ld	(xsp+6), wa
	ldw	wa, 146
	.byte 0x9f, 0x0a, 0xa0
	ld	(xsp+10), wa
	ldw	wa, 146
	sub	wa, qiz
	ld	qiz, wa
	.byte 0x9f, 0x06, 0x04
	ldw	wa, 51
	ldw	bc, 146
	ld	de, (xsp+6)
	calr	127
	ld	bc, hl
	cps	bc, 0
	jr	nz, 58
	.byte 0x9f, 0x0a, 0x04
	ld	wa, (xsp+6)
	ld	bc, (xsp+8)
	ld	de, (xsp+10)
	calr	106
	ld	bc, hl
	cps	bc, 0
	jr	nz, 37
	.byte 0xd7, 0xfa, 0x04
	ld	wa, (xsp+10)
	ld	bc, (xsp+12)
	ld	de, iz
	calr	86
	ld	bc, hl
	cps	bc, 0
	jr	nz, 17
	.byte 0xd7, 0xfa, 0x04
	ld	wa, iz
	ld	bc, qiz
	ldw	de, 213
	calr	66
	ld	bc, qiz
	ld	l, (xsp+22)
	ld	e, l
	extz	de
	ldw	ix, 146
	sub	ix, bc
	mul	xde, xix
	ldb	a, 100
	sub	a, l
	ld	l, a
	extz	hl
	cps	hl, 0
	jr	nz, 6
	add	de, 10000
	jr	4
	extz	xde
	div	xde, xhl
	ld	l, (xsp+12)
	extz	hl
	extz	xde
	div	xde, xhl
	add	de, 213
	pushw 146
	ldw	wa, 214
	calr	5
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	pushw	iz
	lds	iz, 0
	ld	ix, bc
	ld	iy, (xsp+6)
	ld	hl, iy
	sub	hl, ix
	cp	wa, 213
	jr	nc, 38
	cp	de, 213
	jr	ule, 72
	sub	de, wa
	ld	ix, de
	ldw	de, 213
	sub	de, wa
	ld	iy, de
	ld	de, hl
	muls	xde, xiy
	ld	hl, de
	exts	xde
	divs	xde, xix
	ld	hl, de
	add	hl, bc
	ld	iy, hl
	ldw	de, 213
	jr	38
	dec	1, wa
	cp	de, 258
	jr	ule, 32
	sub	de, wa
	ld	ix, de
	ldw	de, 258
	sub	de, wa
	ld	iy, de
	ld	de, hl
	muls	xde, xiy
	ld	hl, de
	exts	xde
	divs	xde, xix
	ld	hl, de
	add	hl, bc
	ld	iy, hl
	ldw	de, 258
	ld	iz, iy
	pushw	iy
	calr	1177
	ld	hl, iz
	popw	iz
	retd	0x0002
	lda	xsp, (xsp-32)
	push	xiz
	.byte 0x0b, 0x90, 0x00, 0x0b, 0x00, 0x01, 0x0b, 0x3b, 0x00, 0x0b, 0x33, 0x00
	call	15790367
	inc	8, xsp
	lda	xbc, (xsp+30)
	lds	wa, 3
	calr	-6402
	lda	xbc, (xsp+31)
	lds	wa, 5
	calr	-6410
	lda	xbc, (xsp+32)
	lds	wa, 7
	calr	-6418
	lda	xbc, (xsp+33)
	ldw	wa, 9
	calr	-6427
	lda	xbc, (xsp+30)
	ld	xwa, xbc
	inc	4, xbc
	ld	e, (xwa)
	res	7, e
	ld	(xwa), e
	cp	e, 100
	jr	ule, 3
	ld	(xwa), 100
	inc	1, xwa
	cp	xwa, xbc
	jr	c, -21
	lda	xbc, (xsp+22)
	lds	wa, 2
	calr	-6463
	lda	xwa, (xsp+22)
	calr	988
	lda	xbc, (xsp+22)
	ld	a, (xbc)
	add	a, 50
	exts	wa
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	muls	wa, 87
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	exts	xwa
	divs	wa, 100
	ld	(xsp+6), wa
	inc	1, xbc
	lds	wa, 4
	calr	-6511
	lda	xwa, (xsp+23)
	calr	940
	lda	xbc, (xsp+22)
	ld	a, (xbc+1)
	add	a, 50
	exts	wa
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	muls	wa, 87
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	exts	xwa
	divs	wa, 100
	ld	(xsp+10), wa
	lds	wa, 2
	calr	-6558
	lda	xbc, (xsp+23)
	lds	wa, 4
	calr	-6566
	lda	xbc, (xsp+22)
	ld	a, (xbc+1)
	.byte 0x81, 0xa1
	exts	wa
	lda	xbc, (xsp+28)
	calr	1950
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+8), wa
	ld	c, (xsp+30)
	ld	e, c
	extz	de
	ld	wa, (xsp+8)
	muls	xwa, xde
	ld	(xsp+8), wa
	ldb	a, 100
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0x9f, 0x08, 0x38, 0x10, 0x27
	ld	wa, (xsp+6)
	ld	(xsp+10), wa
	jr	12
	extz	bc
	ld	wa, (xsp+8)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+8), wa
	lda	xbc, (xsp+24)
	lds	wa, 6
	calr	-6648
	lda	xwa, (xsp+24)
	calr	803
	lda	xbc, (xsp+22)
	ld	a, (xbc+2)
	add	a, 50
	exts	wa
	ld	(xsp+14), wa
	ld	wa, (xsp+14)
	muls	wa, 87
	ld	(xsp+14), wa
	ld	wa, (xsp+14)
	exts	xwa
	divs	wa, 100
	ld	(xsp+14), wa
	inc	1, xbc
	lds	wa, 4
	calr	-6697
	lda	xbc, (xsp+24)
	lds	wa, 6
	calr	-6705
	lda	xbc, (xsp+22)
	ld	a, (xbc+2)
	.byte 0x89, 0x01, 0xa1
	exts	wa
	lda	xbc, (xsp+28)
	calr	1810
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+12), wa
	ld	c, (xsp+31)
	ld	e, c
	extz	de
	ld	wa, (xsp+12)
	muls	xwa, xde
	ld	(xsp+12), wa
	ldb	a, 100
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0x9f, 0x0c, 0x38, 0x10, 0x27
	ld	wa, (xsp+10)
	ld	(xsp+14), wa
	jr	12
	extz	bc
	ld	wa, (xsp+12)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+12), wa
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	-6789
	lda	xwa, (xsp+25)
	calr	662
	lda	xbc, (xsp+22)
	ld	a, (xbc+3)
	add	a, 50
	exts	wa
	ld	(xsp+18), wa
	ld	wa, (xsp+18)
	muls	wa, 87
	ld	(xsp+18), wa
	ld	wa, (xsp+18)
	exts	xwa
	divs	wa, 100
	ld	(xsp+18), wa
	inc	2, xbc
	lds	wa, 6
	calr	-6838
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	-6847
	lda	xbc, (xsp+22)
	ld	a, (xbc+3)
	.byte 0x89, 0x02, 0xa1
	exts	wa
	lda	xbc, (xsp+28)
	calr	1668
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+16), wa
	ld	c, (xsp+32)
	ld	e, c
	extz	de
	ld	wa, (xsp+16)
	muls	xwa, xde
	ld	(xsp+16), wa
	ldb	a, 100
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0x9f, 0x10, 0x38, 0x10, 0x27
	ld	wa, (xsp+14)
	ld	(xsp+18), wa
	jr	12
	extz	bc
	ld	wa, (xsp+16)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+16), wa
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	-6931
	lda	xwa, (xsp+26)
	calr	520
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	add	a, 50
	exts	wa
	ld	(xsp+20), wa
	ld	wa, (xsp+20)
	muls	wa, 87
	ld	(xsp+20), wa
	ld	wa, (xsp+20)
	exts	xwa
	divs	wa, 100
	ld	(xsp+20), wa
	inc	3, xbc
	ldw	wa, 8
	calr	-6981
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	-6990
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89, 0x03, 0xa1
	exts	wa
	lda	xbc, (xsp+28)
	calr	1525
	ld	a, (xsp+28)
	extz	wa
	ld	qiz, wa
	ld	c, (xsp+33)
	ld	e, c
	extz	de
	ld	wa, qiz
	muls	xwa, xde
	ld	qiz, wa
	ldb	a, 100
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0xd7, 0xfa, 0xc8, 0x10, 0x27
	ld	wa, (xsp+18)
	ld	(xsp+20), wa
	jr	12
	extz	bc
	ld	wa, qiz
	exts	xwa
	divs	xwa, xbc
	ld	qiz, wa
	ld	wa, (xsp+8)
	.byte 0x9f, 0x0c, 0x80, 0x9f, 0x10, 0x80
	ld	bc, wa
	extz	xbc
	div	bc, 162
	ld	wa, qiz
	extz	xwa
	div	wa, 45
	cps	bc, 5
	jr	ule, 2
	lds	bc, 5
	cps	wa, 5
	jr	ule, 2
	lds	wa, 5
	cp	bc, wa
	jr	c, 5
	ld	(xsp+4), c
	jr	3
	ld	(xsp+4), a
	incm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, (xsp+8)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+8), wa
	.byte 0x9f, 0x08, 0x38, 0x33, 0x00
	ld	wa, (xsp+12)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+12), wa
	ld	wa, (xsp+8)
	add	(xsp+12), wa
	ld	wa, (xsp+16)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+16), wa
	ld	wa, (xsp+12)
	add	(xsp+16), wa
	ldw	wa, 145
	.byte 0x9f, 0x06, 0xa0
	ld	(xsp+6), wa
	ldw	wa, 145
	.byte 0x9f, 0x0a, 0xa0
	ld	(xsp+10), wa
	ldw	wa, 145
	.byte 0x9f, 0x0e, 0xa0
	ld	(xsp+14), wa
	ldw	wa, 145
	.byte 0x9f, 0x12, 0xa0
	ld	(xsp+18), wa
	ldw	wa, 145
	.byte 0x9f, 0x14, 0xa0
	ld	(xsp+20), wa
	ld	bc, (xsp+6)
	ld	de, (xsp+8)
	ld	wa, (xsp+10)
	pushw	wa
	ldw	wa, 51
	calr	-965
	ld	iz, hl
	cps	iz, 0
	jr	nz, 60
	ld	wa, (xsp+8)
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	ld	hl, (xsp+14)
	pushw	hl
	calr	-987
	ld	iz, hl
	cps	iz, 0
	jr	nz, 38
	ld	wa, (xsp+12)
	ld	bc, (xsp+14)
	ld	de, (xsp+16)
	ld	hl, (xsp+18)
	pushw	hl
	calr	-1009
	ld	iz, hl
	cps	iz, 0
	jr	nz, 16
	ld	wa, (xsp+16)
	ld	bc, (xsp+18)
	pushw	bc
	ldw	de, 213
	calr	-1028
	ld	iz, (xsp+18)
	lda	xbc, (xsp+22)
	ldw	wa, 96
	sub	wa, iz
	ld	(xbc+3), a
	inc	4, xbc
	ldw	wa, 10
	calr	-7316
	lda	xwa, (xsp+26)
	calr	135
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89, 0x03, 0xa1
	exts	wa
	lda	xbc, (xsp+28)
	calr	1193
	ld	a, (xsp+28)
	extz	wa
	ld	qiz, wa
	ld	c, (xsp+33)
	ld	e, c
	extz	de
	ld	wa, qiz
	muls	xwa, xde
	ld	qiz, wa
	ldb	a, 100
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0xd7, 0xfa, 0xc8, 0x10, 0x27
	ld	wa, (xsp+18)
	ld	(xsp+20), wa
	jr	12
	extz	bc
	ld	wa, qiz
	exts	xwa
	divs	xwa, xbc
	ld	qiz, wa
	ld	c, (xsp+4)
	extz	bc
	ld	wa, qiz
	exts	xwa
	divs	xwa, xbc
	ld	qiz, wa
	.byte 0xd7, 0xfa, 0xc8, 0xd5, 0x00
	ld	de, qiz
	ld	wa, (xsp+20)
	pushw	wa
	ldw	wa, 214
	ld	bc, iz
	calr	-1166
	cps	hl, 0
	jr	nz, 16
	inc 1, qiz
	ld	wa, qiz
	ld	bc, (xsp+20)
	pushw	bc
	ldw	de, 258
	calr	-1186
	pop	xiz
	lda	xsp, (xsp+32)
	ret
	dec 4,XSP
	push XIZ
	ld XIZ,XWA
	lda xwa, (xsp + 0x04)
	calr SeMenu_LoadRawAddr
	cp (XIZ),0x32
	jr le, .Lc_f08845
	ld (XIZ),0x32
.Lc_f08845:
	cp (XIZ),0xce
	jr ge, .Lc_f0884d
	ld (XIZ),0xce
.Lc_f0884d:
	lda xbc, (xsp + 0x06)
	lds wa, 1
	calr SeMenu_LoadPartParam
	ld E,(XIZ)
	exts DE
	cp (XSP+0x04),0x37
	jr z, .Lc_f08884
	cp (XSP+0x06),0x00
	jr lt, .Lc_f0886e
	ld C,(XSP+0x06)
	exts BC
	muls xde, xbc
	jr t, .Lc_f0887c
.Lc_f0886e:
	ld C,(XSP+0x06)
	neg C
	ld (XSP+0x06),C
	exts BC
	muls xde, xbc
	neg DE
.Lc_f0887c:
	exts XDE
	divs DE,0x0032
	ld (XIZ),E
.Lc_f08884:
	pop XIZ
	inc 4,XSP
	ret
	lda	xsp, (xsp-10)
	pushw	iz
	ld	(xsp+6), de
	ld	(xsp+8), bc
	ld	(xsp+10), wa
	lda	xbc, (xsp+2)
	lds	wa, 1
	calr	-7564
	lda	xwa, (xsp+4)
	calr	-10046
	ld	iz, (xsp+16)
	.byte 0x8f, 0x04, 0x3f, 0x37
	jrl	nz, 281
	ld	a, (xsp+2)
	exts	wa
	muls	wa, 43
	exts	xwa
	divs	wa, 50
	sub	(xsp+8), wa
	sub	iz, wa
	ld	wa, (xsp+10)
	.byte 0x9f, 0x06, 0xf0
	jr	nz, 51
	.byte 0x9f, 0x08, 0x3f, 0x3b, 0x00
	jr	nc, 7
	ldw	(xsp+8), 59
	jr	12
	.byte 0x9f, 0x08, 0x3f, 0x92, 0x00
	jr	ule, 5
	ldw	(xsp+8), 146
	cp	iz, 59
	jr	nc, 6
	ldw	iz, 59
	jrl	215
	cp	iz, 146
	jrl	ule, 208
	ldw	iz, 146
	jrl	202
	.byte 0x9f, 0x08, 0x3f, 0x3b, 0x00
	jr	c, 20
	.byte 0x9f, 0x08, 0x3f, 0x92, 0x00
	jr	ugt, 13
	cp	iz, 59
	jr	c, 7
	cp	iz, 146
	jrl	ule, 175
	.byte 0x9f, 0x08, 0x3f, 0x3b, 0x00
	jr	nc, 7
	cp	iz, 59
	jrl	c, 177
	.byte 0x9f, 0x08, 0x3f, 0x92, 0x00
	jr	ule, 7
	cp	iz, 146
	jrl	ugt, 163
	ld	wa, (xsp+6)
	.byte 0x9f, 0x0a, 0xa0
	cp	(xsp+8), iz
	jr	nc, 68
	cp	iz, 146
	jr	ule, 25
	ldw	bc, 146
	.byte 0x9f, 0x08, 0xa1
	ld	de, iz
	.byte 0x9f, 0x08, 0xa2
	calr	139
	ld	wa, (xsp+10)
	add	wa, hl
	ld	(xsp+6), wa
	ldw	iz, 146
	.byte 0x9f, 0x08, 0x3f, 0x3b, 0x00
	jr	nc, 98
	ld	wa, (xsp+6)
	.byte 0x9f, 0x0a, 0xa0
	ldw	bc, 59
	.byte 0x9f, 0x08, 0xa1
	ld	de, iz
	.byte 0x9f, 0x08, 0xa2
	calr	101
	add	(xsp+10), hl
	ldw	(xsp+8), 59
	jr	68
	cp	iz, 59
	jr	nc, 26
	ld	bc, (xsp+8)
	sub	bc, 59
	ld	de, (xsp+8)
	sub	de, iz
	calr	70
	ld	wa, (xsp+10)
	add	wa, hl
	ld	(xsp+6), wa
	ldw	iz, 59
	.byte 0x9f, 0x08, 0x3f, 0x92, 0x00
	jr	ule, 29
	ld	wa, (xsp+6)
	.byte 0x9f, 0x0a, 0xa0
	ld	bc, (xsp+8)
	sub	bc, 146
	ld	de, (xsp+8)
	sub	de, iz
	calr	31
	add	(xsp+10), hl
	ldw	(xsp+8), 146
	pushw	iz
	.byte 0x9f, 0x08, 0x04, 0x9f, 0x0c, 0x04, 0x9f, 0x10, 0x04
	call	15789522
	inc	8, xsp
	popw	iz
	lda	xsp, (xsp+10)
	retd	0x0002
	mul xwa, xbc
	extz XWA
	div xwa, xde
	ld HL,WA
	ret
	cp A,0x14
	jr nc, .Lc_f089ef
	ldb A, 0x14
	jr t, .Lc_f089f6
.Lc_f089ef:
	cp A,0x6c
	jr ule, .Lc_f089f6
	ldb A, 0x6c
.Lc_f089f6:
	sub A,0x0c
	ld L,A
	extz HL
	div L,0x0c
	extz WA
	div A,0x0c
	ld A,W
	extz WA
	lda xde, (GUI_DisplayStructData_0x1110:24)
	ldb_dri e, 0x07, 0xe8, 0xe0
	mul L,0x1c
	add L,E
	sub L,0x12
	extz HL
	ld (XBC),HL
	ret
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), c
	ld	(xsp+30), a
	pushw 121
	pushw 254
	pushw 73
	pushw 48
	call	15790367
	inc	8, xsp
	lda	xbc, (xsp+18)
	ldw	wa, 10
	calr	-7988
	ld	a, (xsp+30)
	extz	wa
	lda	xbc, (xsp+24)
	.byte 0x8f, 0x1c, 0x3f, 0x01
	jr	nz, 63
	calr	-8005
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-123
	.byte 0x9f, 0x0e, 0x38, 0x30, 0x00
	ldw	(xsp+16), 48
	ldw	(xsp+4), 48
	ldw	(xsp+12), 254
	ldw	(xsp+6), 254
	ld	wa, (xsp+14)
	sub	wa, 48
	ld	(xsp+8), wa
	ldw	(xsp+10), 254
	ld	wa, (xsp+14)
	sub	(xsp+10), wa
	jrl	145
	calr	-8068
	ld	a, (xsp+30)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+26)
	calr	-8081
	ld	a, (xsp+30)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+22)
	calr	-8094
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xsp+14)
	calr	-212
	ld	a, (xsp+26)
	extz	wa
	lda	xbc, (xsp+16)
	calr	-223
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	-234
	.byte 0x9f, 0x0e, 0x38, 0x30, 0x00, 0x9f, 0x10, 0x38, 0x30, 0x00, 0x9f, 0x0c, 0x38, 0x30, 0x00
	ld	wa, (xsp+16)
	.byte 0x9f, 0x0e, 0xf0
	jr	ule, 8
	ld	wa, (xsp+14)
	dec	1, wa
	ld	(xsp+16), wa
	ld	wa, (xsp+14)
	.byte 0x9f, 0x0c, 0xf0
	jr	ule, 8
	ld	wa, (xsp+14)
	inc	1, wa
	ld	(xsp+12), wa
	ld	wa, (xsp+16)
	ld	(xsp+4), wa
	ld	wa, (xsp+12)
	ld	(xsp+6), wa
	ld	wa, (xsp+14)
	ld	(xsp+8), wa
	ld	wa, (xsp+4)
	sub	(xsp+8), wa
	ld	wa, (xsp+6)
	ld	(xsp+10), wa
	ld	wa, (xsp+14)
	sub	(xsp+10), wa
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	nz, 63
	pushw 97
	pushw 254
	pushw 97
	pushw 48
	call	15789522
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x18, 0x04, 0x0b, 0x61, 0x00, 0x9f, 0x1c, 0x04
	call	15789577
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x16, 0x04, 0x0b, 0x61, 0x00, 0x9f, 0x1a, 0x04
	call	15789577
	lda	xsp, (xsp+24)
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x08, 0x04, 0x0b, 0x61, 0x00
	jrl	239
	ld	a, (xsp+18)
	exts	wa
	lda	xbc, (xsp+20)
	calr	242
	ldw	hl, 25
	muls	hl, 50
	ld	c, (xsp+20)
	extz	bc
	exts	xhl
	divs	xhl, xbc
	ld	ix, (xsp+8)
	muls	xix, xbc
	exts	xix
	divs	ix, 50
	ld	de, (xsp+10)
	muls	xde, xbc
	exts	xde
	divs	de, 50
	ldw	iz, 97
	ldw	qiz, 97
	ld	bc, hl
	cp	(xsp+8), bc
	jr	ule, 22
	ldw	iz, 72
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	lt, 3
	ldw	iz, 122
	ld	wa, (xsp+14)
	sub	wa, hl
	ld	(xsp+16), wa
	jr	12
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	lt, 4
	add	iz, ix
	jr	2
	sub	iz, ix
	cp	(xsp+10), bc
	jr	ule, 26
	ldw	qiz, 122
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	lt, 5
	ldw	qiz, 72
	ld	wa, (xsp+14)
	add	wa, hl
	ld	(xsp+12), wa
	jr	24
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	lt, 10
	ld	wa, qiz
	sub	wa, de
	ld	qiz, wa
	jr	8
	ld	wa, qiz
	add	wa, de
	ld	qiz, wa
	pushw	iz
	.byte 0x9f, 0x12, 0x04
	pushw	iz
	pushw 48
	call	15789522
	.byte 0xd7, 0xfa, 0x04, 0x9f, 0x16, 0x04
	pushw	iz
	.byte 0x9f, 0x1e, 0x04
	call	15789522
	.byte 0xd7, 0xfa, 0x04, 0x0b, 0xfe, 0x00, 0xd7, 0xfa, 0x04, 0x9f, 0x22, 0x04
	call	15789522
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x28, 0x04, 0x0b, 0x61, 0x00, 0x9f, 0x2c, 0x04
	call	15789577
	lda	xsp, (xsp+32)
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x06, 0x04
	pushw	iz
	.byte 0x9f, 0x0a, 0x04
	call	15789577
	inc	8, xsp
	.byte 0x0b, 0x79, 0x00, 0x9f, 0x08, 0x04, 0xd7, 0xfa, 0x04, 0x9f, 0x0c, 0x04
	call	15789577
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+28)
	ret
	cps a, 0
	jr ge, .Lc_f08c6b
	neg A
.Lc_f08c6b:
	ld (XBC),A
	ret
	lda	xsp, (xsp-28)
	ld	(xsp+22), e
	ld	(xsp+24), c
	ld	(xsp+26), a
	ld	a, (xsp+24)
	extz	wa
	calr	-8609
	cps	hl, 0
	jrl	z, 376
	ld	a, (xsp+24)
	extz	wa
	add	wa, wa
	lda	xbc, (14737659:24)
	ld_rrw	wa, xbc, wa
	ld	(xsp), wa
	ldw	(xsp+2), 20
	.byte 0x8f, 0x1a, 0x3f, 0x00
	jr	nz, 10
	ldw	(xsp+4), 39
	ldw	wa, 247
	jr	8
	ldw	(xsp+4), 48
	ldw	wa, 241
	.byte 0x97, 0x04
	pushw	wa
	ld	wa, (xsp+4)
	.byte 0x9f, 0x06, 0xa0
	pushw	wa
	.byte 0x9f, 0x0a, 0x04
	call	15790367
	inc	8, xsp
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+18)
	calr	-8644
	ld	a, (xsp+22)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+20)
	calr	-8657
	ld	a, (xsp+22)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+16)
	calr	-8670
	ld	a, (xsp+22)
	inc	3, a
	extz	wa
	lda	xbc, (xsp+14)
	calr	-8683
	.byte 0xbf, 0x12, 0xb7, 0xbf, 0x14, 0xb7, 0xbf, 0x10, 0xb7, 0xbf, 0x0e, 0xb7, 0x8f, 0x1a, 0x3f, 0x00
	jr	nz, 46
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	calr	-819
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+10)
	calr	-830
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+8)
	calr	-841
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xsp+6)
	calr	-852
	jr	120
	ld	a, (xsp+20)
	extz	wa
	ld	(xsp+12), wa
	ld	wa, (xsp+12)
	mul	wa, 192
	ld	(xsp+12), wa
	ld	wa, (xsp+12)
	extz	xwa
	div	wa, 127
	ld	(xsp+12), wa
	ld	a, (xsp+18)
	extz	wa
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	mul	wa, 192
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	extz	xwa
	div	wa, 127
	ld	(xsp+10), wa
	ld	a, (xsp+16)
	extz	wa
	ld	(xsp+8), wa
	ld	wa, (xsp+8)
	mul	wa, 192
	ld	(xsp+8), wa
	ld	wa, (xsp+8)
	extz	xwa
	div	wa, 127
	ld	(xsp+8), wa
	ld	a, (xsp+14)
	extz	wa
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	mul	wa, 192
	ld	(xsp+6), wa
	ld	wa, (xsp+6)
	extz	xwa
	div	wa, 127
	ld	(xsp+6), wa
	ld	wa, (xsp+4)
	add	(xsp+12), wa
	add	(xsp+10), wa
	add	(xsp+8), wa
	add	(xsp+6), wa
	ld	wa, (xsp)
	.byte 0x9f, 0x02, 0xa0
	pushw	wa
	.byte 0x9f, 0x0c, 0x04, 0x9f, 0x04, 0x04, 0x9f, 0x12, 0x04
	call	15789522
	ld	wa, (xsp+8)
	.byte 0x9f, 0x0a, 0xa0
	pushw	wa
	.byte 0x9f, 0x12, 0x04
	pushw	wa
	.byte 0x9f, 0x18, 0x04
	call	15789522
	.byte 0x9f, 0x10, 0x04, 0x9f, 0x18, 0x04
	ld	wa, (xsp+20)
	.byte 0x9f, 0x16, 0xa0
	pushw	wa
	.byte 0x9f, 0x1e, 0x04
	call	15789522
	lda	xsp, (xsp+24)
	lda	xsp, (xsp+28)
	ret
	dec	8, xsp
	ld	(xsp+2), e
	ld	(xsp+4), c
	ld	(xsp+6), a
	lda	xbc, (xsp)
	lds	wa, 0
	calr	-8964
	ld	a, (xsp+4)
	.byte 0x87, 0xf1
	jr	z, 56
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	nz, 12
	ld	a, (xsp+4)
	extz	wa
	calr	-9033
	cps	hl, 0
	jr	z, 38
	ld	a, (xsp+4)
	extz	wa
	calr	-9273
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	calr	-9020
	pushw 0
	ld	a, (xsp+8)
	extz	wa
	pushw	wa
	call	15789873
	inc	4, xsp
	lds	wa, 1
	calr	-9551
	inc	8, xsp
	ret
	lda xsp, (xsp - 0x10)
	push XIZ
	ld (XSP+0x10),C
	ld (XSP+0x12),A
	ldw (XSP+0x04), 0x004d
	cp (XSP+0x10),0x00
	jr nz, .Lc_f08e71
	ldw (XSP+0x04), 0x0028
.Lc_f08e71:
	lda xbc, (xsp + 0x0e)
	lds wa, 2
	calr SeMenu_LoadPartParam
	res 7,(XSP+0x0e)
	lda xbc, (xsp + 0x0c)
	lds wa, 3
	calr SeMenu_LoadPartParam
	and (XSP+0x0c),0x07
	cp (XSP+0x0c),0x05
	jr ule, .Lc_f08e92
	ld (XSP+0x0c),0x05
.Lc_f08e92:
	ld WA,(XSP+0x04)
	add WA,0x0035
	ld (XSP+0x06),WA
	ldw (XSP+0x08), 0x001a
	ld WA,(XSP+0x04)
	add (XSP+0x08),WA
	ld A,(XSP+0x0e)
	extz WA
	add WA,0x0056
	ld QIZ,WA
	cp (XSP+0x10),0x00
	jr nz, .Lc_f08ecb
	ld C,(XSP+0x0c)
	mul C,0x03
	ld WA,(XSP+0x08)
	sub WA,BC
	inc 6,WA
	ld (XSP+0x0a),WA
	jr t, .Lc_f08edd
.Lc_f08ecb:
	ld C,(XSP+0x0c)
	mul C,0x06
	ld WA,(XSP+0x08)
	sub WA,BC
	add WA,0x000c
	ld (XSP+0x0a),WA
.Lc_f08edd:
	ld IZ,(XSP+0x06)
	sub IZ,(XSP+0x0a)
	.byte 0x9f, 0x06, 0x04, 0x0b, 0xe8, 0x00, 0x9f, 0x08, 0x04, 0x0b, 0x43, 0x00
	call	15790367
	inc	8, xsp
	.byte 0x8f, 0x12, 0x3f, 0x00
	jr	nz, 115
	.byte 0x9f, 0x08, 0x04
	ld	wa, qiz
	sub	wa, 10
	pushw	wa
	.byte 0x9f, 0x0c, 0x04, 0x0b, 0x43, 0x00
	call	15789522
	.byte 0x9f, 0x12, 0x04, 0xd7, 0xfa, 0x04, 0x9f, 0x14, 0x04
	ld	wa, qiz
	sub	wa, 10
	pushw	wa
	call	15789522
	lda	xsp, (xsp+16)
	ldw	de, 232
	sub	de, qiz
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 21
	cp	iz, de
	jr	ugt, 7
	ld	bc, qiz
	add	bc, iz
	jr	22
	ldw	bc, 232
	ld	wa, (xsp+10)
	add	wa, de
	jr	27
	ld	bc, iz
	srl	bc, 1
	cp	bc, de
	jr	ugt, 8
	add	bc, qiz
	ld	wa, (xsp+6)
	jr	10
	ldw	bc, 232
	ld	wa, de
	add	wa, wa
	.byte 0x9f, 0x0a, 0x80
	pushw	wa
	pushw	bc
	.byte 0x9f, 0x0e, 0x04, 0xd7, 0xfa, 0x04
	jr	116
	ld	de, qiz
	sub	de, 67
	.byte 0x8f, 0x10, 0x3f, 0x00
	jr	nz, 21
	cp	iz, de
	jr	ugt, 7
	ld	bc, qiz
	sub	bc, iz
	jr	24
	ldw	bc, 67
	ld	wa, (xsp+10)
	add	wa, de
	jr	29
	ld	wa, iz
	srl	wa, 1
	cp	wa, de
	jr	ugt, 10
	ld	bc, qiz
	sub	bc, wa
	ld	wa, (xsp+6)
	jr	10
	ldw	bc, 67
	ld	wa, de
	add	wa, wa
	.byte 0x9f, 0x0a, 0x80, 0x9f, 0x0a, 0x04, 0xd7, 0xfa, 0x04
	pushw	wa
	pushw	bc
	call	15789522
	.byte 0x9f, 0x10, 0x04
	ld	wa, qiz
	add	wa, 10
	pushw	wa
	.byte 0x9f, 0x16, 0x04, 0xd7, 0xfa, 0x04
	call	15789522
	lda	xsp, (xsp+16)
	.byte 0x9f, 0x08, 0x04, 0x0b, 0xe8, 0x00, 0x9f, 0x0c, 0x04
	ld	wa, qiz
	add	wa, 10
	pushw	wa
	call	15789522
	inc	8, xsp
	.byte 0x9f, 0x06, 0x04, 0xd7, 0xfa, 0x04, 0x9f, 0x0e, 0x04, 0xd7, 0xfa, 0x04
	call	15789577
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	lda	xbc, (xsp+14)
	lds	wa, 4
	calr	-9466
	.byte 0xbf, 0x0e, 0xb7
	lda	xbc, (xsp+12)
	lds	wa, 5
	calr	-9477
	lda	xbc, (xsp+10)
	lds	wa, 5
	calr	-9485
	lds	wa, 1
	lds	bc, 7
	calr	-9476
	ld	(xsp+4), l
	.byte 0xbf, 0x0c, 0xb7
	ldw	(xsp+6), 171
	ldw	(xsp+8), 26
	.byte 0x9f, 0x08, 0x38, 0x76, 0x00
	ld	a, (xsp+14)
	extz	wa
	add	wa, 86
	ld	qiz, wa
	ld	a, (xsp+12)
	.byte 0x8f, 0x0c, 0x81
	extz	wa
	ld	iz, (xsp+8)
	sub	iz, wa
	add	iz, 14
	.byte 0x8f, 0x0c, 0x3f, 0x00
	jr	nz, 3
	ld	iz, (xsp+6)
	pushw 171
	pushw 232
	pushw 118
	pushw 67
	call	15790367
	inc	8, xsp
	ld	a, (xsp+10)
	.byte 0x8f, 0x04, 0xc1
	jr	z, 49
	.byte 0x9f, 0x08, 0x04
	ld	wa, qiz
	dec	6, wa
	pushw	wa
	.byte 0x9f, 0x0c, 0x04, 0x0b, 0x43, 0x00
	call	15789522
	pushw	iz
	.byte 0xd7, 0xfa, 0x04, 0x9f, 0x14, 0x04
	ld	wa, qiz
	dec	6, wa
	pushw	wa
	call	15789522
	lda	xsp, (xsp+16)
	pushw	iz
	pushw 232
	pushw	iz
	.byte 0xd7, 0xfa, 0x04
	jr	44
	pushw	iz
	push	xiz
	pushw 67
	call	15789522
	.byte 0x9f, 0x10, 0x04
	ld	wa, qiz
	inc	6, wa
	pushw	wa
	pushw	iz
	.byte 0xd7, 0xfa, 0x04
	call	15789522
	lda	xsp, (xsp+16)
	.byte 0x9f, 0x08, 0x04, 0x0b, 0xe8, 0x00, 0x9f, 0x0c, 0x04
	ld	wa, qiz
	inc	6, wa
	pushw	wa
	call	15789522
	inc	8, xsp
	.byte 0x9f, 0x06, 0x04
	push	xiz
	.byte 0xd7, 0xfa, 0x04
	call	15789577
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda xsp, (xsp - 0x16)
	push XIZ
	lda xbc, (xsp + 0x18)
	lds wa, 2
	calr SeMenu_LoadPartParam
	res 7,(XSP+0x18)
	lda xbc, (xsp + 0x16)
	lds wa, 3
	calr SeMenu_LoadPartParam
	and (XSP+0x16),0x07
	cp (XSP+0x16),0x05
	jr ule, .Lc_f09114
	ld (XSP+0x16),0x05
.Lc_f09114:
	lda xbc, (xsp + 0x14)
	lds wa, 4
	calr SeMenu_LoadPartParam
	res 7,(XSP+0x14)
	lda xbc, (xsp + 0x12)
	lds wa, 5
	calr SeMenu_LoadPartParam
	and (XSP+0x12),0x07
	cp (XSP+0x12),0x05
	jr ule, .Lc_f09135
	ld (XSP+0x12),0x05
.Lc_f09135:
	ld A,(XSP+0x18)
	cp A,(XSP+0x14)
	jr c, .Lc_f09145
	ld (XSP+0x18),0x4f
	ld (XSP+0x14),0x50
.Lc_f09145:
	ldw (XSP+0x06), 0x0082
	ldw (XSP+0x0a), 0x001a
	.byte 0x9f, 0x0a, 0x38, 0x4d, 0x00
	ld	a, (xsp+24)
	ldb_erp	a, 248
	extz	iz
	add	iz, 86
	ld	a, (xsp+20)
	extz	wa
	add	wa, 86
	ld	(xsp+8), wa
	ld	c, (xsp+22)
	mul	c, 3
	ld	wa, (xsp+10)
	sub	wa, bc
	inc	6, wa
	ld	(xsp+12), wa
	ldw	qiz, 130
	ld	wa, qiz
	.byte 0x9f, 0x0c, 0xa0
	ld	qiz, wa
	ld	c, (xsp+18)
	mul	c, 3
	ld	wa, (xsp+10)
	sub	wa, bc
	inc	6, wa
	ld	(xsp+14), wa
	ldw	(xsp+16), 130
	ld	wa, (xsp+14)
	sub	(xsp+16), wa
	ld	wa, (xsp+8)
	sub	wa, iz
	cp	wa, 20
	scc	c, a
	ld	(xsp+4), a
	pushw 130
	pushw 232
	pushw 77
	pushw 67
	call	15790367
	inc	8, xsp
	ld	bc, iz
	sub	bc, 67
	ld	wa, qiz
	cp	wa, bc
	jr	ugt, 10
	ld	de, iz
	sub	de, qiz
	ld	wa, (xsp+6)
	jr	8
	ldw	de, 67
	ld	wa, (xsp+12)
	add	wa, bc
	.byte 0x9f, 0x0c, 0x04
	pushw	iz
	pushw	wa
	pushw	de
	call	15789522
	inc	8, xsp
	.byte 0x8f, 0x04, 0x3f, 0x01
	jr	nz, 12
	.byte 0x9f, 0x0e, 0x04, 0x9f, 0x0a, 0x04, 0x9f, 0x10, 0x04
	pushw	iz
	jr	63
	.byte 0x9f, 0x0a, 0x04
	ld	wa, iz
	add	wa, 10
	pushw	wa
	.byte 0x9f, 0x10, 0x04
	pushw	iz
	call	15789522
	.byte 0x9f, 0x12, 0x04
	ld	wa, (xsp+18)
	sub	wa, 10
	pushw	wa
	.byte 0x9f, 0x16, 0x04
	ld	wa, iz
	add	wa, 10
	pushw	wa
	call	15789522
	lda	xsp, (xsp+16)
	.byte 0x9f, 0x0e, 0x04, 0x9f, 0x0a, 0x04, 0x9f, 0x0e, 0x04
	ld	wa, (xsp+14)
	sub	wa, 10
	pushw	wa
	call	15789522
	inc	8, xsp
	ldw	bc, 232
	.byte 0x9f, 0x08, 0xa1
	cp	(xsp+16), bc
	jr	ugt, 11
	ld	de, (xsp+8)
	.byte 0x9f, 0x10, 0x82
	ld	wa, (xsp+6)
	jr	8
	ldw	de, 232
	ld	wa, (xsp+14)
	add	wa, bc
	pushw	wa
	pushw	de
	.byte 0x9f, 0x12, 0x04, 0x9f, 0x0e, 0x04
	call	15789522
	.byte 0x9f, 0x0e, 0x04
	pushw	iz
	.byte 0x9f, 0x18, 0x04
	pushw	iz
	call	15789577
	.byte 0x9f, 0x16, 0x04, 0x9f, 0x1a, 0x04, 0x9f, 0x22, 0x04, 0x9f, 0x1e, 0x04
	call	15789577
	lda	xsp, (xsp+24)
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	lda	xde, (1698:16)
	st_rrw	bc, xde, wa
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	lda	xde, (1698:16)
	ld_rrw	wa, xde, wa
	ld	(xbc), wa
	ret
	ld	(1706:16), wa
	ret
	.byte 0xb0, 0x16, 0xaa, 0x06
	ret
	ld	(1708:16), a
	ret
	.byte 0xb0, 0x14, 0xac, 0x06
	ret
SeMenu_ProcessEffect:
	lda xsp, (xsp - 38)
	pushw_erp 0xfa
	ld (xsp + 38), a
	lda xwa, (xsp + 2)
	calr SeMenu_FillObjTable
	cp (xsp + 38), 0x0
	jr nz, SeMenu_ProcessEffect_AltPath
	lda xde, (xsp + 2)
	ld c, (xde + 1)
	extz bc
	sll bc, 8
	ld a, (xde)
	extz wa
	add bc, wa
	ld (1706:16), bc
	mrdb5 0x8a, 0x02, 0x19, 0xac, 0x06
	ldib_erp 0xfb, 0
	jr SeMenu_ProcessEffect_CompareLoop

SeMenu_ProcessEffect_StoreLoop:
	stb_erp A, 0xfb
	add a, 0x12
	extz wa
	stb_erp C, 0xfb
	inc 3, c
	extz bc
	ldb_sri C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_LoopEnd
	inc1b_erp 0xfb

SeMenu_ProcessEffect_CompareLoop:
	lda xde, (xsp + 2)
	stb_erp A, 0xfb
	cp a, (xde + 2)
	jr c, SeMenu_ProcessEffect_StoreLoop

SeMenu_ProcessEffect_LoopEnd:
	jrl SeMenu_ProcessEffect_Data3

SeMenu_ProcessEffect_AltPath:
	cp (xsp + 38), 0x2
	jr nz, SeMenu_ProcessEffect_AltStore
	lda xde, (xsp + 2)
	ld c, (xde + 1)
	extz bc
	sll bc, 8
	ld a, (xde)
	extz wa
	add bc, wa
	ld (1714:16), bc
	jrl SeMenu_ProcessEffect_Data3

SeMenu_ProcessEffect_AltStore:
	lda xde, (xsp + 2)
	lda xbc, (xde + 2)
	ld a, (xde + 1)
	ld l, a
	extz hl
	cp (xsp + 38), 0x3
	jr nz, SeMenu_ProcessEffect_AltEnd
	sll hl, 8
	ld a, (xde)
	extz wa
	add hl, wa
	ld (1706:16), hl
	mrib4 0x81, 0x19, 0xac, 0x06
	ldib_erp 0xfb, 0
	jr SeMenu_ProcessEffect_AltData2

SeMenu_ProcessEffect_AltData:
	stb_erp A, 0xfb
	add a, 0x11
	extz wa
	stb_erp C, 0xfb
	inc 3, c
	extz bc
	ldb_sri C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_AltBranch
	inc1b_erp 0xfb

SeMenu_ProcessEffect_AltData2:
	lda xde, (xsp + 2)
	stb_erp A, 0xfb
	cp a, (xde + 2)
	jr c, SeMenu_ProcessEffect_AltData

SeMenu_ProcessEffect_AltBranch:
	jr SeMenu_ProcessEffect_Data3

SeMenu_ProcessEffect_AltEnd:
	sll hl, 8
	ld a, (xde)
	extz wa
	add hl, wa
	ld (1706:16), hl
	mrib4 0x81, 0x19, 0xac, 0x06
	ldib_erp 0xfb, 0
	jr SeMenu_ProcessEffect_Section2_End

SeMenu_ProcessEffect_Section2:
	stb_erp A, 0xfb
	add a, 0xc
	extz wa
	stb_erp C, 0xfb
	inc 3, c
	extz bc
	ldb_sri C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_Data3
	inc1b_erp 0xfb

SeMenu_ProcessEffect_Section2_End:
	lda xde, (xsp + 2)
	stb_erp A, 0xfb
	cp a, (xde + 2)
	jr c, SeMenu_ProcessEffect_Section2

SeMenu_ProcessEffect_Data3:
	popw_erp 0xfa
	lda xsp, (xsp + 38)
	ret

SeMenu_ApplyFilter:
	lda xsp, (xsp - 40)
	ld (xsp + 38), a
	lda xwa, (xsp)
	calr SeMenu_LoadObjEntries
	lda xwa, (xsp + 2)
	calr SeMenu_FillObjTable
	ld c, (xsp + 15)
	extz bc
	cp (xsp), 0x0
	jr nz, SeMenu_ApplyFilter_AltPart
	ld a, (xsp + 38)
	add a, 0xd
	extz wa
	calr SeMenu_StorePartParam
	ld a, (xsp + 38)
	extz wa
	lda xbc, (xsp + 2)
	ldw de, 0xd
	jr SeMenu_ApplyFilter_SetupDisplay

SeMenu_ApplyFilter_AltPart:
	ld a, (xsp + 38)
	add a, 0xe
	extz wa
	calr SeMenu_StorePartParam
	ld a, (xsp + 38)
	inc 1, a
	extz wa
	lda xbc, (xsp + 2)
	ldw de, 0xd

SeMenu_ApplyFilter_SetupDisplay:
	calr SeMenu_SetupPartDisplay
	ld a, (xsp + 38)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (1698:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
	lda xhl, (xsp + 2)
	ld c, (xhl + 15)
	extz bc
	ld (xde), bc
	sll bc, 8
	ld (xde), bc
	ld a, (xhl + 14)
	extz wa
	add bc, wa
	ld (xde), bc
	lda xsp, (xsp + 40)
	ret

SeMenu_ApplySynthParam:
	lda xsp, (xsp - 36)
	lda xwa, (xsp)
	calr SeMenu_FillObjTable
	lda xbc, (xsp)
	lds wa, 1
	ldw de, 0xd
	calr SeMenu_SetupPartDisplay
	lda xde, (xsp)
	ld c, (xde + 15)
	extz bc
	sll bc, 8
	ld a, (xde + 14)
	extz wa
	add bc, wa
	ld (1712:16), bc
	lda xsp, (xsp + 36)
	ret

SeMenu_ApplySynthParam_Alt:
	lda xsp, (xsp - 38)
	ld (xsp + 36), a
	lda xwa, (xsp)
	calr SeMenu_FillObjTable
	ld a, (xsp + 36)
	extz wa
	lda xbc, (xsp)
	ldw de, 0xd
	calr SeMenu_SetupPartDisplay
	ld a, (xsp + 36)
	inc 7, a
	extz wa
	ld c, (xsp + 13)
	extz bc
	calr SeMenu_StorePartParam
	ld a, (xsp + 36)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (1698:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
	lda xhl, (xsp)
	ld c, (xhl + 15)
	extz bc
	ld (xde), bc
	sll bc, 8
	ld (xde), bc
	ld a, (xhl + 14)
	extz wa
	add bc, wa
	ld (xde), bc
	lda xsp, (xsp + 38)
	ret

SeMenu_ApplySynthParam_Data:
	dec	8, xsp
	push	xiz
	ld	(xsp+6), xde
	ld	(xsp+10), c
	cps	a, 1
	jr	nz, 6
	ldi_erpb 250, 12
	jr	12
	ldi_erpb 250, 18
	cps	a, 3
	jr	nz, 4
	ldi_erpb 250, 17
	lds	iz, 0
	.byte 0xc7
	swi	3
	.byte 0xa8, 0x8f
	ldwio	63, 0x6300
	ldb	w, 199
	swi	2
	cp	(xbc-57), c
	xor	(xbc), w
	ccf
	lda	xbc, (xsp+4)
	calr	54767
	ld	a, (xsp+4)
	extz	wa
	add	iz, wa
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	.byte 0x89, 0x8f
	ldwio	241, 0xe067
	ld	xwa, (xsp+6)
	ld	(xwa), iz
	pop	xiz
	inc	8, xsp
	ret
	dec	2, xsp
	push	xiz
	ld	xiz, xde
	lda	xde, (xsp+4)
	cps	a, 3
	jr	nz, 11
	add	c, 14
	extz	bc
	ld	wa, bc
	ld	xbc, xde
	jr	23
	cps	a, 1
	jr	nz, 10
	inc	7, c
	extz	bc
	ld	wa, bc
	ld	xbc, xde
	jr	9
	add	c, 13
	extz	bc
	ld	wa, bc
	ld	xbc, xde
	calr	54691
	ld	a, (xsp+4)
	.byte 0xb6
	ld	xbc, 0x0e62ef5e

SeMenu_SetSelectedRow:
	ld (1711:16), a
	ret

SeMenu_SetSelectedRow_Data:
	.byte 0xb0
	push_a
	.byte 0xaf, 0x06
	ret

SeMenu_LoadObjEntries:
	ldmi16 (xwa), 0x6ae
	ret

SeMenu_SetMode:
	ld (1710:16), a
	ret

SeMenu_SetMode_Data:
	ld	(1712:16), wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xb0, 0x06
	ret
	ld	(1714:16), wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xb2, 0x06
	ret

SeMenu_LoadSoundBankCfg:
	ldmi16 (xwa), 0x6b4
	ret

SeMenu_SetSoundBank:
	ld (1716:16), a
	ret

SeMenu_LoadFilterType:
	ldmi16 (xwa), 0x6b5
	ret

SeMenu_SetFilterParam1:
	ld (1717:16), a
	ret

SeMenu_LoadFilterParam2:
	ldmi16 (xwa), 0x6b6
	ret

SeMenu_SetFilterMode:
	ld (1718:16), a
	ret

SeMenu_SetFilterCoeff:
	ld (1721:16), a
	ret

SeMenu_LoadEditParam:
	ldmi16 (xwa), 0x6b9
	ret

SeMenu_SetupSoundBankPair:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xbc
	ld xiz, xwa
	lda xwa, (xsp + 6)
	calr SeMenu_LoadSoundBankCfg
	cp (xsp + 6), 0x0
	jr nz, SeMenu_SetupSoundBankPair_NonZero
	ld (xiz), 0x24
	ld xwa, (xsp + 10)
	ld (xwa), 0x24
	ld a, (xiz)
	extz wa
	calr SeMenu_SetFilterParam1
	ld xwa, (xsp + 10)
	ld a, (xwa)
	extz wa
	calr SeMenu_SetFilterCoeff
	lds wa, 1
	calr SeMenu_SetSoundBank
	jr SeMenu_SetupSoundBankPair_End

SeMenu_SetupSoundBankPair_NonZero:
	.byte 0xbf, 0x04, 0x30, 0x1e, 0xb0, 0xff, 0x8f, 0x04
	.byte 0x3f, 0x01, 0x6e, 0x5d, 0xbf, 0x08, 0x30, 0x1e
	.byte 0x7c, 0xcb, 0x8f, 0x08, 0x21, 0xd8, 0x12, 0xd9
	.byte 0xa8, 0xda, 0xa8, 0x1d, 0x2d, 0x5e, 0xfe, 0xb6
	.byte 0x47, 0x8f, 0x08, 0x21, 0xd8, 0x12, 0xd9, 0xa8
	.byte 0xda, 0xa9, 0x1d, 0x2d, 0x5e, 0xfe, 0xaf, 0x0a
	.byte 0x20, 0xb0, 0x47, 0x86, 0x3f, 0xff, 0x6e, 0x14
	.byte 0x8f, 0x08, 0x21, 0xd8, 0x12, 0xd9, 0xa9, 0xda
	.byte 0xa9, 0x1d, 0x2d, 0x5e, 0xfe, 0xb6, 0x47, 0xaf
	.byte 0x0a, 0x20, 0xb0, 0x47
SeMenu_SetupSoundBankPair_CheckValid:
	cp (xiz), 0xff
	jr z, SeMenu_SetupSoundBankPair_Invalid
	ld a, (xiz)
	extz wa
	calr SeMenu_SetFilterParam1
	ld xwa, (xsp + 10)
	ld a, (xwa)
	extz wa
	calr SeMenu_SetFilterCoeff

SeMenu_SetupSoundBankPair_Invalid:
	lds wa, 0
	calr SeMenu_SetFilterMode
	jr SeMenu_SetupSoundBankPair_End

SeMenu_SetupSoundBankPair_Direct:
	ld xwa, xiz
	calr SeMenu_LoadFilterType
	ld xwa, (xsp + 10)
	calr SeMenu_LoadEditParam

SeMenu_SetupSoundBankPair_End:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeMenu_ComputeParamTableAddr:
	dec 1, a
	extz wa
	mul wa, 0xa
	ld xde, xbc
	extz xwa
	add xwa, 0x205f3
	ld xhl, xwa
	lda xbc, (xbc + 10)

SeMenu_ComputeParamTableAddr_ScanLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	cp xde, xbc
	jr c, SeMenu_ComputeParamTableAddr_ScanLoop
	ret

SeMenu_ComputeParamTableAddr_Data:
	dec	1, a
	extz	wa
	mul	wa, 10
	extz	xwa
	add	xwa, 0x0205f3
	ld	xde, xwa
	lda	xhl, (xwa+10)
	ldb_spi a, 232
	lda_dpi xbc, 228
	cp xde, xhl
	jr c, -10
	ret

SeMenu_HandleMenuChange:
	lda xsp, (xsp - 20)
	lda xwa, (xsp + 18)
	calr SeMenu_ReadObjData
	cp (xsp + 18), 0x0
	jr nz, SeMenu_HandleMenuChange_NonZero
	calr SeMenu_ResetSubIndex
	calr SeMenu_AdvanceSubIndex
	lda xwa, (xsp)
	calr SeMenu_ReadObjParam
	lda xwa, (xsp)
	calr SeMenu_SetupDisplayObject
	pushw 0x10
	lds wa, 0
	lds bc, 0
	ldw de, 0xa
	calr SeMenu_RegisterElement_Type2
	lds wa, 1
	calr SeMenu_SetCurrentStep
	jr SeMenu_HandleMenuChange_End

SeMenu_HandleMenuChange_NonZero:
	lda xwa, (xsp)
	calr SeMenu_ReadObjParam
	lda xwa, (xsp + 2)
	calr SeMenu_FillEntryTable
	ld a, (xsp)
	extz wa
	lda xbc, (xsp + 2)
	calr SeMenu_ComputeParamTableAddr
	calr SeMenu_AdvanceSubIndex
	cp l, 0x7f
	jr ugt, SeMenu_HandleMenuChange_Overflow
	lda xwa, (xsp)
	calr SeMenu_ReadObjParam
	lda xwa, (xsp)
	calr SeMenu_SetupDisplayObject
	pushw 0x10
	lds wa, 0
	lds bc, 0
	ldw de, 0xa
	calr SeMenu_RegisterElement_Type2
	jr SeMenu_HandleMenuChange_End

SeMenu_HandleMenuChange_Overflow:
	lds wa, 0
	calr SeMenu_SetCurrentStep
	calr SeMenu_ResetSubIndex
	ldw wa, 0x98
	lds bc, 0
	calr SeMenu_SendEvent

SeMenu_HandleMenuChange_End:
	lda xsp, (xsp + 20)
	ret

SeMenu_HandleMenuChange_Data:
	.byte 0xb0
	push_a
	.byte 0xb7, 0x06
	ret
	ld	(1719:16), a
	ret

SeMenu_LoadPatchStatus:
	ldmi16 (xwa), 0x6b8
	ret

SeMenu_SetPatchBank:
	ld (1720:16), a
	ret

SeMenu_PatchBank_Data:
	dec	8, xsp
	ld	(xsp+2), e
	ld	(xsp+4), c
	ld	(xsp+6), a
	lda	xwa, (xsp)
	calr	51762
	ld	a, (xsp+6)
	extz	wa
	lda	xix, (0xf9b6:16)
	lda	xhl, (0xf9d0:16)
	lda	xde, (0xf9ea:16)
	ld	bc, wa
	extz	xbc
	add	xbc, xde
	ld	de, wa
	extz	xde
	add	xde, xhl
	ld	hl, wa
	extz	xhl
	add	xhl, xix
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	nz, 31
	.byte 0x87
	push	xsp
	normal
	jr	nz, 7
	ld	a, (xsp+4)
	or	(xde), a
	jr	44
	.byte 0x87
	push	xsp
	push	sr
	jr	nz, 7
	ld	a, (xsp+4)
	or	(xbc), a
	jr	32
	ld	a, (xsp+4)
	or	(xhl), a
	jr	25
	ld	a, (xsp+4)
	cpl	a
	.byte 0x87
	push	xsp
	normal
	jr	nz, 4
	and	(xde), a
	jr	11
	.byte 0x87
	push	xsp
	push	sr
	jr	nz, 4
	and	(xbc), a
	jr	2
	and	(xhl), a
	inc	8, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+6), e
	ld	(xsp+8), c
	ld	(xsp+10), a
	ld	a, (xsp+8)
	extz	wa
	lda	xbc, (xsp+4)
	calr	54077
	ld	a, (xsp+4)
	and	a, 128
	ld	(xsp), a
	.byte 0xbf, 0x04, 0xb7, 0x8f, 0x06
	push	xsp
	nop
	jr	z, 10
	.byte 0x8f, 0x06
	push	xsp
	incf
	jr	nc, 4
	ld	(xsp+6), 12
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	z, 10
	.byte 0x8f
	rcf
	push	xsp
	incf
	jr	nc, 4
	ld	(xsp+16), 0
	ld	a, (xsp+10)
	res	7, a
	cps	a, 0
	jr	nz, 116
	.byte 0x8f, 0x04
	push	xsp
	jrl	nc, 31855
	ld	a, (xsp+4)
	cp	a, (xsp+16)
	jr	nc, 116
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 4
	ld	(xsp+4), 11
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+2)
	calr	56422
	ld	a, (xsp+4)
	.byte 0x8f
	push	sr
	.byte 0x81
	ld	(xsp+4), a
	.byte 0x8f, 0x04
	push	xsp
	incf
	jr	nc, 6
	ld	(xsp+4), 0
	jr	10
	.byte 0x8f, 0x04
	push	xsp
	jrl	nc, 1123
	ld	(xsp+4), 127
	ld	a, (xsp+4)
	.byte 0x8f, 0x06, 0xf1
	jr	nc, 6
	ld	a, (xsp+6)
	ld	(xsp+4), a
	ld	a, (xsp+4)
	cp	a, (xsp+16)
	jr	ule, 6
	ld	a, (xsp+16)
	ld	(xsp+4), a
	ld	a, (xsp)
	or	(xsp+4), a
	ld	a, (xsp+8)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	calr	53899
	ldb	l, 1
	jr	16
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 8
	ld	a, (xsp+4)
	.byte 0x8f, 0x06, 0xf1
	jr	ugt, -116
	ldb	l, 0
	lda	xsp, (xsp+12)
	retd	2

SeMenu_SetEditEnable:
	cps a, 1
	jr nz, SeMenu_SetEditEnable_Clear
	set 2, (0x28a7:16)
	ret

SeMenu_SetEditEnable_Clear:
	res 2, (0x28a7:16)
	ret

SeMenu_OrPartConfig:
	ordm8_24 (0x0205f2), a
	ret

SeMenu_OrPartConfig_Data:
	.incbin "includes/romslices/v7_transplant_SeMenu_OrPartConfig_Data_head.bin"
	ld l, (0x00e31c:24)
	and L,0x08
	ret
SeMenu_StoreParamByte:
	dec 1, a
	extz wa
	lda xde, (1722:16)
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_LoadParamByte:
	dec 1, a
	extz wa
	lda xde, (1722:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ret

SeMenu_SetConfirmState:
	ld (1732:16), a
	ret

SeMenu_LoadConfirmData:
	ldmi16 (xwa), 0x6c4
	ret

SeMenu_ReturnZero:
	ldb l, 0x0
	ret

SeMenu_SetDisplayState:
	ld (1733:16), a
	ret

SeMenu_DisplayState_Data:
	.byte 0xb0
	push_a
	.byte 0xc5, 0x06
	ret
	ld	(1626:16), a
	ret
	.byte 0xb0
	push_a
	pop	xde
	ei	14

SeMenu_StoreEffectParam:
	extz wa
	lda xde, (1726:16)
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_StoreEffectParam_Data:
	extz	wa
	lda	xde, (1726:16)
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	ret

SeMenu_StoreEffectCoeff:
	extz wa
	lda xde, (1729:16)
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_StoreEffectCoeff_Data:
	extz	wa
	lda	xde, (1729:16)
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	ret
	lda	xsp, (xsp-40)
	ld	xiy, GUI_DisplayStructData_0x120C
	lda	xix, (xsp+22)
	.byte 0x85
	rcf
	ldiw
	ld	xiy, GUI_DisplayStructData_0x120F
	lda	xix, (xsp+18)
	.byte 0x85
	rcf
	ldiw
	ld	(xsp), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+34)
	lda_rr xbc, xbc, wa
	calr 65448
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+26)
	lda_rr xbc, xbc, wa
	calr 65461
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	push	sr
	jr	ule, -37
	lda	xde, (xsp+30)
	lda	xbc, (xsp+34)
	ld	a, (xbc)
	res	7, a
	ld	(xde), a
	lda	xwa, (xde+1)
	ld	(xsp+14), xwa
	lda	xwa, (xbc+1)
	ld	(xsp+10), xwa
	ld	l, (xwa)
	res	7, l
	ld	xwa, (xsp+14)
	ld	(xwa), l
	lda	xwa, (xde+2)
	ld	(xsp+6), xwa
	lda	xwa, (xbc+2)
	ld	(xsp+2), xwa
	ld	l, (xwa)
	and	l, 31
	ld	xwa, (xsp+6)
	ld	(xwa), l
	ld	(xsp), 0
	ld	l, (xsp)
	extz	hl
	lda_rr xiy, xde, hl
	ld	a, (xiy)
	ldb_erp	a, 238
	lda	xwa, (xsp+26)
	lda_rr xix, xwa, hl
	ld w, (xix)
	sla	w, 1
	stb_erp a, 238
	add	a, w
	ldb_erp a, 238
	ldb_erp a, 238
	ld	(xiy), a
	lda	xwa, (xsp+22)
	ld_rrb l, xwa, hl
	stb_erp a, 238
	cp	a, l
	jr	ule, 12
	.byte 0x84
	push	xsp
	nop
	jr	ge, 5
	ld	(xiy), 0
	jr	2
	ld	(xiy), l
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	push	sr
	jr	ule, -74
	ld	a, (xbc)
	and	a, 128
	or	(xde), a
	ld	xwa, (xsp+10)
	ld	c, (xwa)
	and	c, 128
	ld	xwa, (xsp+14)
	or	(xwa), c
	ld	xwa, (xsp+2)
	ld	c, (xwa)
	and	c, 224
	ld	xwa, (xsp+6)
	or	(xwa), c
	lda	xde, (xsp+38)
	lds	wa, 0
	lds	bc, 1
	calr	54052
	ld	(xsp), 0
	ld	e, (xsp)
	extz	de
	lda	xbc, (xsp+18)
	ld	a, (xsp+38)
	.byte 0xc3
	reti
	.byte 0xe4
	add	xbc, xwa
	ld	c, a
	extz	bc
	lda	xwa, (xsp+30)
	exts	xde
	add	xde, xwa
	pushw	255
	lds	wa, 0
	calr	51048
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	pop	sr
	jr	c, -41
	lda	xsp, (xsp+40)
	ret

SeMenu_RefreshPartDisplay:
	lda xwa, (0xf9b6:16)
	ld c, (xwa)
	ld a, (xwa + 1)
	extz wa
	pushw wa
	extz bc
	pushw bc
	pushw 0x0
	call SeMenu_DisplayPartValue
	lda xwa, (0xf9d0:16)
	ld c, (xwa)
	ld a, (xwa + 1)
	extz wa
	pushw wa
	extz bc
	pushw bc
	pushw 0x1
	call SeMenu_DisplayPartValue
	lda xwa, (0xf9ea:16)
	ld c, (xwa)
	ld a, (xwa + 1)
	extz wa
	pushw wa
	extz bc
	pushw bc
	pushw 0x2
	call SeMenu_DisplayPartValue
	lda xsp, (xsp + 18)
	ret

SeMenu_RefreshPartDisplay_Data:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 13 B byte-exact. v9/v10 name offset +13 into
	; this same label SeMenu_RefreshPartDisplay_Data_0xD -- exactly where these
	; 13 bytes end -- and v9/v10's own bytes at offsets 0 and 6 are the identical
	; "stdi8 (1709),0 / ret" pair this decodes to. Structural match, not just a
	; clean decode.
	ld	(1709:16), 0
	ret
	ld	(1709:16), 0
	ret
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f09ad1
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x1222:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f09ad1:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f09aff
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x126A:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f09aff:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f09b2d
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x12B2:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f09b2d:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f09b5b
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x12FA:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f09b5b:
	inc 4,XSP
	ret
	.incbin "includes/romslices/v7_fix_semenu_refreshpartdisplay_data_mid1.bin"
	nop
	call SeMenu_LoadPartParam
	cp (XSP+0x10),0x01
	jrl nz, .Lc_f09d3a
	lda xbc, (xsp + 0x0e)
	ldw WA, 0x000e
	call SeMenu_LoadPartParam
	and (XSP+0x0e),0x1f
	lda xbc, (xsp + 0x02)
	ld A,(XSP+0x0e)
	extz WA
	lda xde, (GUI_DisplayStructData_0x1342:24)
	ldb_dri a, 0x07, 0xe8, 0xe0
	ld (XBC),A
	ld (XBC+0x06),0x1f
	ld (XBC+0x07),0x00
	ld (XBC+0x08),0x0c
	ld (XBC+0x09),0x00
	ld A,(XSP+0x12)
	extz WA
	lda xbc, (xbc + 0x0a)
	call SeMenu_SetupPartDisplay_End_0x219
	lda xwa, (xsp + 0x02)
	call SeMenu_BitShiftMask_End_0x14
	cps l, 1
	jr nz, .Lc_f09d35
	ld A,(XSP+0x05)
	extz WA
	lda xbc, (GUI_DisplayStructData_0x1362:24)
	ldb_dri c, 0x07, 0xe4, 0xe0
	ld (XSP+0x0e),C
	extz BC
	ldw WA, 0x000e
	call SeMenu_StorePartParam
	lda xde, (xsp + 0x0e)
	pushw 0x001f
	lds wa, 0
	ldw BC, 0x0013
	call SeMenu_RegisterElement_Extended
	pushw 0x000e
	pushw 0x0027
	call SeMenu_ShowConfirmDialog
	inc 4,XSP
.Lc_f09d35:
	lds wa, 6
	jrl t, .Lc_f09dba
.Lc_f09d3a:
	lda xbc, (xsp + 0x02)
	cp (XSP+0x10),0x02
	jr nz, .Lc_f09d65
	ldi_erpb 0xfb, 0x0f
	ldi_erpb 0xfa, 0x29
	ldw WA, 0x000f
	call SeMenu_LoadPartParam
	lda xwa, (xsp + 0x02)
	ld (XWA+0x06),0x0f
	ld (XWA+0x07),0x00
	ld (XWA+0x08),0x0a
	ld XBC,XWA
	jr t, .Lc_f09d90
.Lc_f09d65:
	ldi_erpb 0xfb, 0x10
	ldi_erpb 0xfa, 0x2a
	ldw WA, 0x0010
	call SeMenu_LoadPartParam
	lda xbc, (xsp + 0x02)
	ld (XBC+0x06),0x0f
	lda xwa, (xbc + 0x07)
	cp (XSP+0x10),0x03
	jr nz, .Lc_f09d89
	ld (XWA),0x04
	jr t, .Lc_f09d8c
.Lc_f09d89:
	ld (XWA),0x00
.Lc_f09d8c:
	ld (XBC+0x08),0x0a
.Lc_f09d90:
	ld (XBC+0x09),0x06
	ld A,(XSP+0x12)
	extz WA
	lda xbc, (xsp + 0x0c)
	call SeMenu_SetupPartDisplay_End_0x219
	ld_erpb_rr c, 0xfb
	extz BC
	ld_erpb_rr a, 0xfa
	extz WA
	pushw wa
	lda xwa, (xsp + 0x04)
	push XWA
	ldw WA, 0x0027
	lds de, 0
	call SeMenu_TransferPartValues_EndData_0x169
	lds wa, 6
.Lc_f09dba:
	call SeMenu_SetupPartDisplay_End_0x1F6
	pop QIZ
	lda xsp, (xsp + 0x12)
	ret
	.incbin "includes/romslices/v7_fix_semenu_refreshpartdisplay_data_tail.bin"
