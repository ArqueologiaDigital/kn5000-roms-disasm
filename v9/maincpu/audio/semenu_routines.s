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
	ldmi16 (xwa), 0x8d38
	ret

SeMenu_TriggerNotification:
	stda8 32578, a
	stdi8 58332, 238
	setda 6, 58334
	ret

SeMenu_ClearNotification:
	stda8 58332, a
	setda 1, 58334
	ret

SeMenu_StoreEventId:
	stda8 1688, a
	ret

SeMenu_LoadObjectPtr_Data:
	.byte 0xb0
	push_a
	.byte 0x98, 0x06
	ret

SeMenu_LoadMasterPtr:
	ld8_24 c, 0x008d3a
	ld (xwa), c
	ret

SeMenu_FlushDisplayObj:
	ld xde, xwa
	ld xbc, xde
	ldada xhl, 1689
	lda xix, (xde + 9)

SeMenu_FlushDisplayObj_CopyLoop:
	ld_spib A, 0xe4
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	.byte 0xf5, 0xe0
	nop
	nop
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+14)
	calr	64769
	lda	xhl, (xsp+16)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	.byte 0xc7
	swi	0
	and	(xbc-55), d
	swi	7
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
	.byte 0xf5, 0xe0
	nop
	nop
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+14)
	calr	64653
	lda	xhl, (xsp+16)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	.byte 0xc7
	swi	0
	and	(xbc-55), d
	swi	7
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
	stib_dpi 0xe0, 0x00
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
	.byte 0xf5, 0xe0
	nop
	nop
	cp	xwa, xbc
	jr	c, -8
	lda	xwa, (xsp+12)
	calr	64468
	lda	xhl, (xsp+14)
	ld	wa, iz
	srl	wa, 8
	ld	(xhl), a
	lda	xde, (xhl+1)
	.byte 0xc7
	swi	0
	and	(xbc-55), d
	swi	7
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xe0, 0x00
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
	stib_dpi 0xec, 0x00
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
	.byte 0xf5, 0xe0
	nop
	nop
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
	stib_dpi 0xe0, 0x00
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
	calr	63975
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
	call	SndParam_ApplyProgramChange
	lda	xwa, (xsp+2)
	ld	e, (xwa+3)
	ld	c, (xwa+4)
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	nz, 8
	ldada	xwa, 63952
	ld	(xwa), e
	jr	19
	.byte 0x87
	push	xsp
	push_sr
	jr	nz, 8
	ldada	xwa, 63978
	ld	(xwa), e
	jr	6
	ldada	xwa, 63926
	ld	(xwa), e
	ld	(xwa+1), c
	extz	bc
	pushw	bc
	extz	de
	pushw	de
	ld	a, (xsp+4)
	extz	wa
	pushw	wa
	call	SeMenu_DisplayPartValue
	lda	xsp, (xsp+16)
	ret

SeMenu_InitTrackInfo:
	dec 8, xsp
	lda xwa, (xsp)
	calr SeMenu_LoadMasterPtr
	lda xwa, (xsp + 2)
	ld (xwa), 0xf
	ld (xwa + 1), 0xf
	ld c, (xsp)
	ld (xwa + 2), c
	call SndParam_ApplyProgramChange
	lda xwa, (xsp + 2)
	ld e, (xwa + 3)
	ld c, (xwa + 4)
	cp (xsp), 0x1
	jr nz, SeMenu_InitTrackInfo_Part1
	ldada xwa, 63952
	ld (xwa), e
	jr SeMenu_InitTrackInfo_Store

SeMenu_InitTrackInfo_Part1:
	cp (xsp), 0x2
	jr nz, SeMenu_InitTrackInfo_Part2
	ldada xwa, 63978
	ld (xwa), e
	jr SeMenu_InitTrackInfo_Store

SeMenu_InitTrackInfo_Part2:
	ldada xwa, 63926
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
	mrid2 0xb1, 0x2c
	ret

SeMenu_SetFlags_Type0x2x:
	setm 2, (xbc)
	setm 6, (xde)
	ret

SeMenu_SetFlags_Type0x3x:
	ldb a, 0x2

SeMenu_SetFlags_SetCarryAndStore_Alt:
	scf
	mrid2 0xb1, 0x2c

SeMenu_SetFlags_SetBit7_DE:
	setm 7, (xde)
	ret

SeMenu_SetFlags_Type0x4x:
	setm 2, (xbc)
	ormi8 (xde), 0xc0
	ret

SeMenu_SetupMenuDisplay:
	lda xsp, (xsp - 14)
	push_werp 0xfa
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
	stib_dpi 0xe0, 0x00
	cp xwa, xbc
	jr c, SeMenu_SetupMenuDisplay_ClearLoop
	cp (xsp + 6), 0x0
	jr z, SeMenu_SetupMenuDisplay_Data
	cp (xsp + 14), 0x0
	jr nz, SeMenu_SetupMenuDisplay_Section2

SeMenu_SetupMenuDisplay_Data:
	ldi_berp 0xfb, 0

SeMenu_SetupMenuDisplay_Data2:
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lda xde, (xsp + 2)
	exts xbc
	add xbc, xde
	calr SeMenu_LoadParamByte
	inc1_berp 0xfb
	cpi_berp 0xfb, 4
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
	ldi_berp 0xfb, 0
	cp (xsp + 10), 0x0
	jr nz, SeMenu_SetupMenuDisplay_Section3

SeMenu_SetupMenuDisplay_Section2_End:
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lda xde, (xsp + 2)
	st_dri3b B, 0x07, 0xe8, 0xe4
	pushw 0x7f
	ldw bc, 0x17
	calr SeMenu_RegisterElement_Extended
	inc1_berp 0xfb
	cpi_berp 0xfb, 4
	jr c, SeMenu_SetupMenuDisplay_Section2_End
	jr SeMenu_SetupMenuDisplay_Section3_Loop

SeMenu_SetupMenuDisplay_Section3:
	ldto_berp E, 0xfb
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
	inc1_berp 0xfb
	cpi_berp 0xfb, 2
	jr c, SeMenu_SetupMenuDisplay_Section3

SeMenu_SetupMenuDisplay_Section3_Loop:
	pop_werp 0xfa
	lda xsp, (xsp + 14)
	ret

SeMenu_SetupMenuDisplay_Section3_End:
	cps	a, 0
	scc8	nz, a
	stda8	1628, a
	ret

SeMenu_SetupMenuDisplay_Finalize:
	ldmi16 (xwa), 0x65c
	ret

SeMenu_SetupMenuDisplay_Finalize_Data:
	cps	a, 1
	jr	c, 9
	cps	a, 4
	jr	ugt, 5
	stda8	1629, a
	ret
	stdi8	1629, 1
	ret

SeMenu_ValidatePartNumber:
	dec 4, xsp
	push_werp 0xfa
	ld (xsp + 2), xwa
	ldda8 c, 1629
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
	stdi8 1629, 1

SeMenu_ValidatePartNumber_CheckEnabled:
	ld xwa, (xsp + 2)
	ld a, (xwa)
	extz wa
	calr SeMenu_IsPartEnabled
	cps hl, 0
	jr nz, SeMenu_ValidatePartNumber_End
	ldi_berp 0xfb, 1

SeMenu_ValidatePartNumber_ScanLoop:
	ldto_berp A, 0xfb
	extz wa
	calr SeMenu_IsPartEnabled
	cps hl, 0
	jr z, SeMenu_ValidatePartNumber_NextPart
	ldto_berp C, 0xfb
	jr SeMenu_ValidatePartNumber_Store

SeMenu_ValidatePartNumber_NextPart:
	inc1_berp 0xfb
	cpi_berp 0xfb, 4
	jr ule, SeMenu_ValidatePartNumber_ScanLoop
	ldb c, 0x1

SeMenu_ValidatePartNumber_Store:
	ld xwa, (xsp + 2)
	ld (xwa), c
	stda8 1629, c

SeMenu_ValidatePartNumber_End:
	pop_werp 0xfa
	inc 4, xsp
	ret

SeMenu_StorePartMask:
	stda8 1630, a
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
	.byte 0x01
	jr	c, 6
	.byte 0x8f, 0x06
	push	xsp
	.byte 0x04
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
	anddm8	1630, a
	jr	4
	orddm8	1630, l
	.byte 0xbf
	push_sr
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
	ldda8 a, 1630
	and a, l
	cps a, 0
	scc16 nz, hl
	ret

SeMenu_StorePartParam:
	extz wa
	ldada xde, 1632
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_LoadPartParam:
	extz wa
	ldada xde, 1632
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
	ldwio	63, 28160
	pop_sr
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
	call	15790154
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
	st_dri3b W, 0x07, 0xe0, 0xe4
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
	ldda8	a, 1678
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	stdi8	1678, 1
	ldda8	a, 1678
	jr	56
	cps	a, 0
	jr	nz, 23
	ldda8	a, 1677
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	stdi8	1677, 1
	ldda8	a, 1677
	jr	29
	cps	a, 2
	jr	nz, 23
	ldda8	a, 1679
	cps	a, 1
	jr	c, 4
	cps	a, 4
	jr	ule, 5
	stdi8	1679, 1
	ldda8	a, 1679
	jr	2
	ldb	a, 1
	ld	(xbc), a
	ret
	cps	a, 0
	jr	nz, 12
	ldada	xwa, 1677
	cps	c, 0
	jr	z, 24
	decm8	1, (xwa)
	jr	22
	cps	a, 1
	jr	nz, 6
	ldada	xwa, 1678
	jr	-18
	cps	a, 2
	ret	nz
	ldada	xwa, 1679
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
	ldda8	c, 1685
	cps	c, 1
	jr	c, 4
	cps	c, 6
	jr	ule, 2
	ldb	c, 1
	ld	(xwa), c
	ret
	stda8	1685, a
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
	.byte 0xc7
	swi	3
	.byte 0x99
	ldw	wa, 127
	lds	bc, 0
	calr	64592
	.byte 0xc7
	swi	3
	.byte 0x8b
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
	.byte 0xd7
	swi	2
	halt
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
	push_sr
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
	.byte 0x04
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
	push_sr
	ld	xbc, 3626043535
	ccf
	ld	c, (xsp+2)
	extz	bc
	calr	64149
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	and	(xbc-55), d
	pop_sr
	.byte 0xc7
	swi	2
	.byte 0x99, 0x8f
	ldwio	63, 28160
	ex_ff
	.byte 0xc7
	swi	2
	inc	6, wa
	jp	14285511
	jr	nz, 5
	.byte 0xc7
	swi	2
	.byte 0xab
	jr	30
	.byte 0xc7
	swi	2
	dec	6, hl
	pop_f
	jr	116
	.byte 0xc7
	swi	2
	inc	6, wa
	jr	nc, -57
	swi	2
	dec	6, hl
	halt
	.byte 0xc7
	swi	2
	.byte 0xa9
	jr	8
	.byte 0xc7
	swi	2
	dec	6, bc
	pop_sr
	.byte 0xc7
	swi	2
	.byte 0xa8
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 3
	calr	64057
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0x89
	cpl	a
	and	(xsp+8), a
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	calr	64033
	or	(xsp+8), l
	ld	c, (xsp+6)
	extz	bc
	.byte 0xc7
	swi	3
	.byte 0x89
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
	.byte 0xd7
	swi	2
	halt
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
	stda8 1683, a
	ret

SeMenu_ResetSubIndex:
	stdi8 1684, 0
	ret

SeMenu_AdvanceSubIndex:
	ldda8 l, 1684
	inc 1, l
	stda8 1684, l
	ret

SeMenu_ReadObjParam_Data:
	stda8	1684, a
	ret

SeMenu_ReadObjParam:
	ldmi16 (xwa), 0x694
	ret

SeMenu_CheckObjEnabled:
	ldw hl, 0xffff
	cpdm8_24 134195, a
	ret nz
	lds hl, 0
	ret

SeMenu_CheckObjValid:
	ldw hl, 0xffff
	cpdm8_24 134197, a
	ret nz
	lds hl, 0
	ret

SeMenu_FillEntryTable:
	lda_24 xhl, 0x020c33
	ld c, (xhl + 3)
	ldfr_berp C, 0xe6
	ldi_berp 0xea, 0
	cpi_berp 0xe6, 0
	ret ule
	lds de, 6

SeMenu_FillEntryTable_Loop:
	ld ix, de
	ldw bc, 0xfffa
	add ix, bc
	ld bc, de
	ld_srib3 C, 0x07, 0xec, 0xe4
	lda_dri3 XHL, 0x07, 0xe0, 0xf0
	inc1_berp 0xea
	inc 1, de
	ldto_berp C, 0xea
	cp_berp C, 0xe6
	jr c, SeMenu_FillEntryTable_Loop
	ret

SeMenu_FillObjTable:
	ld xhl, xwa
	lda_24 xde, 0x020c39
	ld xbc, xde
	lda xde, (xde + 25)

SeMenu_FillObjTable_Loop:
	ld_spib A, 0xe4
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
	lda_24 xix, 0x020bf3
	lds hl, 0

SeMenu_SetupPartDisplay_Loop:
	ld_srib3 A, 0x07, 0xe4, 0xec
	lda_dri3 XBC, 0x07, 0xf0, 0xec
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
	lda_24 xix, 0x020c03
	lds hl, 0

SeMenu_SetupPartDisplay_AltLoop:
	ld_srib3 A, 0x07, 0xe4, 0xec
	lda_dri3 XBC, 0x07, 0xf0, 0xec
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
	lda_24 xix, 0x020c13
	lds hl, 0

SeMenu_SetupPartDisplay_Mode2Loop:
	ld_srib3 A, 0x07, 0xe4, 0xec
	lda_dri3 XBC, 0x07, 0xf0, 0xec
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
	lda_24 xix, 0x020c23
	lds hl, 0

SeMenu_SetupPartDisplay_Mode3Loop:
	ld_srib3 A, 0x07, 0xe4, 0xec
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Mode3Loop
	ret

SeMenu_SetupPartDisplay_End:
	cps	a, 1
	jr	nz, 32
	ldb	w, 0
	cps	e, 0
	ret	ule
	lda_24	xix, 134131
	lds	hl, 0
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 243
	reti
	.byte 0xe4, 0xec
	ld	xbc, 1641767368
	cp	w, e
	jr	c, -18
	ret
	cps	a, 2
	jr	nz, 32
	ldb	w, 0
	cps	e, 0
	ret	ule
	lda_24	xix, 134147
	lds	hl, 0
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 243
	reti
	.byte 0xe4, 0xec
	ld	xbc, 1641767368
	cp	w, e
	jr	c, -18
	ret
	cps	a, 3
	jr	nz, 32
	ldb	w, 0
	cps	e, 0
	ret	ule
	lda_24	xix, 134163
	lds	hl, 0
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 243
	reti
	.byte 0xe4, 0xec
	ld	xbc, 1641767368
	cp	w, e
	jr	c, -18
	ret
	cps	a, 4
	ret	nz
	ldb	w, 0
	cps	e, 0
	ret	ule
	lda_24	xix, 134179
	lds	hl, 0
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 243
	reti
	.byte 0xe4, 0xec
	ld	xbc, 1641767368
	cp	w, e
	jr	c, -18
	ret
	ld	xhl, (xsp+4)
	bit	15, bc
	jr	z, 4
	ldb	c, 1
	jr	2
	ldb	c, 0
	ld	(xhl), c
	ld	c, a
	cp	wa, 16
	jr	ugt, 6
	ld	(xde), c
	lds	hl, 0
	jr	34
	cp	wa, 17
	jr	c, 15
	cp	wa, 24
	jr	ugt, 9
	sub	c, 17
	ld	(xde), c
	.byte 0xb3, 0xbf
	jr	-25
	cp	wa, 25
	jr	nz, 4
	ldb	c, 16
	jr	-37
	ldw	hl, 65535
	retd	4
	ld	xhl, xbc
	ldb	b, 0
	cps	e, 0
	ret	ule
	.byte 0xc5, 0xec
	ldb	c, 245
	.byte 0xe0
	ld	xhl, 4073546186
	jr	c, -12
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+14), xwa
	lda	xwa, (xsp+6)
	calr	60955
	.byte 0x8f, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 8
	ldada	xwa, 63952
	ld	e, (xwa)
	jr	20
	.byte 0x8f, 0x06
	push	xsp
	push_sr
	jr	nz, 8
	ldada	xwa, 63978
	ld	e, (xwa)
	jr	6
	ldada	xwa, 63926
	ld	e, (xwa)
	ld	c, (xwa+1)
	lda	xwa, (xsp+8)
	ld	(xwa+3), e
	ld	(xwa+4), c
	ld	c, (xsp+6)
	ld	(xwa+2), c
	call	SndParam_FetchOscTableEntry
	lda	xbc, (xsp+8)
	ld	a, (xbc)
	.byte 0xc7
	swi	3
	.byte 0x99
	ld	a, (xbc+1)
	ld	(xsp+2), a
	.byte 0xc7
	swi	3
	.byte 0xcf
	rcf
	jr	z, 20
	.byte 0xc7
	swi	3
	.byte 0xcf
	scf
	jr	z, 14
	ld	xwa, (xsp+14)
	.byte 0xb0
	push_a
	.byte 0xad, 0x06, 0x80
	.ascii "?'kChL¿"
	.byte 0x04
	ldw	wa, 42526
	ldb	a, 143
	.byte 0x04
	push	xsp
	nop
	jr	nz, 41
	.byte 0xc7
	swi	3
	.byte 0xcf
	scf
	jr	nz, 5
	.byte 0xc7
	swi	3
	.byte 0xa9
	jr	3
	.byte 0xc7
	swi	3
	.byte 0xa8
	ld	xwa, (xsp+14)
	ld	c, (xsp+2)
	ld	(xwa), c
	.byte 0xc7
	swi	3
	.byte 0x8b
	mul	c, 20
	add	(xwa), c
	.byte 0x80
	pop_f
	xor	(xiy+6), xwa
	.byte 0xa9
	calr	8564
	jr	23
	ld	xwa, (xsp+14)
	.byte 0xb0
	push_a
	.byte 0xad, 0x06, 0x80
	push	xsp
	ldb	l, 99
	pushw	3759
	ldb	w, 176
	nop
	nop
	stdi8	1709, 0
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+16)
	ret
	.byte 0xb0
	push_a
	.byte 0xad, 0x06
	ret
	stda8	1709, a
	ret
	cp	a, 15
	ret	ugt
	extz	wa
	lda_24	xde, 134131
	.byte 0xf3
	reti
	or	xwa, xwa
	ld	xhl, 265275662
	ret	ugt
	extz	wa
	lda_24	xde, 134131
	.byte 0xc3
	reti
	or	xwa, xwa
	ldb	a, 177
	ld	xbc, 454219790
	ldb	e, 149
	swi	1
	dec	1, c
	or	c, e
	extz	bc
	cps	a, 0
	jr	nz, 6
	ld	wa, bc
	jp	UI_PostDialValueEvent
	ld	wa, bc
	jp	UI_PostDialRangeEvent
	dec	2, xsp
	ld	(xsp), a
	lds	wa, 1
	calr	65499
	ld	c, (xsp)
	extz	bc
	lds	wa, 0
	lds	de, 0
	calr	65494
	ld	c, (xsp)
	extz	bc
	lds	wa, 1
	ldw	de, 128
	calr	65482
	inc	2, xsp
	ret
	ld	l, a
	res	7, l
	ldb	e, 255
	cps	l, 0
	jr	nz, 2
	ldb	e, 1
	ld	(xbc), e
	bit	7, a
	ret	z
	ld	a, (xbc)
	muls	a, 3
	ld	(xbc), a
	ret
	cp	a, 97
	jr	c, 4
	ld	(xbc), 32
	ret
	extz	wa
	lda_24	xde, 14737671
	.byte 0xc3
	reti
	or	xwa, xwa
	ldb	a, 177
	ld	xbc, 2194655502
	jr	c, 5
	ld	(xbc), 0
	jr	14
	extz	wa
	lda_24	xde, 14737768
	.byte 0xc3
	reti
	or	xwa, xwa
	ldb	a, 177
	ld	xbc, 2959032193
	.byte 0xf3
	ld	(xbc), 0
	ret
	dec	6, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+6), a
	lda	xwa, (xsp+2)
	calr	8332
	.byte 0xc7
	swi	2
	.byte 0xaa, 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 3
	.byte 0xc7
	swi	2
	.byte 0xac
	lda	xwa, (xsp+4)
	calr	62729
	ld	a, (xsp+4)
	extz	wa
	calr	62930
	cps	hl, 0
	jr	z, 9
	ld	a, (xsp+6)
	extz	wa
	lds	bc, 0
	jr	60
	.byte 0xc7
	swi	3
	cp	(xbc-57), xde
	inc	7, bc
	pushw	wa
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	calr	62901
	cps	hl, 0
	jr	z, 17
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	calr	62661
	ld	a, (xsp+6)
	extz	wa
	lds	bc, 0
	jr	23
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	cp	(xbc-57), b
	.byte 0xf1
	jr	ule, -40
	lds	wa, 1
	calr	62636
	ld	a, (xsp+6)
	extz	wa
	lds	bc, 0
	calr	60395
	.byte 0xd7
	swi	2
	halt
	inc	6, xsp
	ret

SeMenu_ApplyPartEdit:
	lda xsp, (xsp - 14)
	push_werp 0xfa
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
	ldfr_berp L, 0xfb
	ld a, (xsp + 2)
	extz wa
	lda xbc, (xsp + 11)
	calr SeMenu_LoadPartParam
	lda xde, (xsp + 11)
	ldto_berp L, 0xfb
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
	pop_werp 0xfa
	lda xsp, (xsp + 14)
	ret

SeMenu_ApplyPartEdit_Data2:
	dec	2, xsp
	ld	(xsp), c
	res	7, a
	cps	a, 0
	scc8	z, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	63396
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	nz, 11
	ldb	a, 42
	extz	wa
	lds	bc, 1
	calr	60130
	jr	18
	.byte 0x87
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 47
	jr	-18
	.byte 0x87
	push	xsp
	push_sr
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
	calr	63253
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	63144
	lda	xbc, (xsp)
	lds	wa, 4
	calr	62571
	lda	xbc, (xsp)
	ld	(xbc+6), 3
	ld	(xbc+7), 6
	ld	(xbc+8), 3
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64975
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080*"
	lds	bc, 4
	lds	de, 0
	calr	63540
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	.byte 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 2
	calr	8712
	lds	wa, 3
	calr	64891
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	63128
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	63019
	lda	xbc, (xsp)
	lds	wa, 4
	calr	62446
	lda	xbc, (xsp)
	ld	(xbc+6), 31
	ld	(xbc+7), 0
	ld	(xbc+8), 30
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64850
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080*"
	lds	bc, 4
	lds	de, 0
	calr	63415
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	.byte 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 2
	calr	8587
	lds	wa, 4
	calr	64766
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	63003
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	62894
	lda	xbc, (xsp)
	lds	wa, 2
	calr	62321
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64725
	ld	a, (xsp+12)
	inc	1, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 2
	lds	de, 0
	calr	63290
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	.byte 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 1
	calr	8462
	lds	wa, 5
	calr	64641
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	62878
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	62769
	lda	xbc, (xsp)
	lds	wa, 1
	calr	62196
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64600
	ld	a, (xsp+12)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080*"
	lds	bc, 1
	lds	de, 0
	calr	63167
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	.byte 0x01
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	lds	wa, 0
	calr	8339
	lds	wa, 6
	calr	64518
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	62755
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	62646
	lda	xbc, (xsp)
	lds	wa, 3
	calr	62073
	lda	xbc, (xsp)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64477
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 3
	lds	de, 0
	calr	63042
	lds	wa, 7
	calr	64415
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	62652
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	62543
	lda	xbc, (xsp)
	lds	wa, 3
	calr	61970
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 7
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64374
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	lds	bc, 3
	lds	de, 0
	calr	62939
	ldw	wa, 8
	calr	64311
	lda	xsp, (xsp+20)
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	lds	wa, 0
	calr	61897
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 11
	.byte 0x87
	push	xsp
	nop
	jr	z, 30
	lds	wa, 0
	lds	bc, 0
	jr	9
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 0
	lds	bc, 1
	calr	61855
	pushw	0
	pushw	40
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	61836
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	61567
	lda	xbc, (xsp)
	lds	wa, 3
	calr	61817
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64221
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "0807"
	lds	bc, 3
	calr	62785
	calr	2598
	lds	wa, 1
	calr	64155
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	61736
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	61467
	lda	xbc, (xsp)
	lds	wa, 4
	calr	61717
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	64121
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	lds	bc, 4
	calr	62685
	calr	2498
	lds	wa, 2
	calr	64055
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	61375
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	61624
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 35
	.byte 0xc7
	swi	2
	sub	(xde-40), xde
	calr	61607
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	.byte 0xc7
	swi	3
	ld	bc, (xbc+104)
	.byte 0xc7
	swi	2
	sub	(xiy-40), xiy
	calr	61572
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	.byte 0xc7
	swi	3
	.byte 0x99
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	63969
	.byte 0xc7
	swi	2
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "0807"
	calr	62530
	calr	2343
	lds	wa, 3
	calr	63900
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	61478
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 73
	lda	xwa, (xsp+12)
	calr	61209
	lda	xbc, (xsp)
	lds	wa, 6
	calr	61459
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	63863
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	lds	bc, 6
	calr	62427
	calr	2240
	lds	wa, 4
	calr	63797
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	61117
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	61366
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 37
	.byte 0xc7
	swi	2
	pop_sr
	ldwio	48, 10
	calr	61347
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	.byte 0xc7
	swi	3
	ld	bc, (xbc+104)
	.byte 0xc7
	swi	2
	sub	(xsp-40), xsp
	calr	61312
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	.byte 0xc7
	swi	3
	.byte 0x99
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	63709
	.byte 0xc7
	swi	2
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 55
	calr	62270
	calr	2083
	lds	wa, 5
	calr	63640
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	61218
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 75
	lda	xwa, (xsp+12)
	calr	60949
	lda	xbc, (xsp)
	ldw	wa, 8
	calr	61198
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	63602
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "0807"
	ldw	bc, 8
	calr	62165
	calr	1978
	lds	wa, 6
	calr	63535
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), e
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+14)
	calr	60855
	lda	xbc, (xsp+16)
	lds	wa, 0
	calr	61104
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 35
	.byte 0xc7
	swi	2
	sub	(xbc-40), xbc
	calr	61087
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	.byte 0xc7
	swi	3
	ld	hl, (xbc+104)
	.byte 0xc7
	swi	2
	pop_sr
	push	48
	push	0
	calr	61050
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	.byte 0xc7
	swi	3
	.byte 0x99
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	63447
	.byte 0xc7
	swi	2
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "0807"
	calr	62008
	calr	1821
	lds	wa, 7
	calr	63378
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	60701
	lda	xbc, (xsp)
	lds	wa, 3
	calr	60951
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	63355
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080)"
	lds	bc, 3
	calr	61919
	lda	xbc, (xsp+12)
	lds	wa, 3
	calr	60891
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	60867
	lds	wa, 2
	lds	bc, 1
	calr	3288
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	60864
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 20
	ldw	wa, 9
	lds	bc, 0
	calr	60837
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	calr	63231
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	60557
	lda	xbc, (xsp)
	lds	wa, 4
	calr	60807
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	63211
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080)"
	lds	bc, 4
	calr	61775
	lda	xbc, (xsp+12)
	lds	wa, 4
	calr	60747
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	60723
	lds	wa, 2
	lds	bc, 1
	calr	3144
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	60720
	cp	(xsp+12), 1
	jr	z, 20
	ldw	wa, 9
	lds	bc, 1
	calr	60693
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 3
	calr	63087
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	60413
	lda	xbc, (xsp)
	lds	wa, 5
	calr	60663
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	63067
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080)"
	lds	bc, 5
	calr	61631
	lda	xbc, (xsp+12)
	lds	wa, 5
	calr	60603
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	60579
	lds	wa, 2
	lds	bc, 1
	calr	3000
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	60576
	.byte 0x8f
	incf
	push	xsp
	push_sr
	jr	z, 20
	ldw	wa, 9
	lds	bc, 2
	calr	60549
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 4
	calr	62943
	lda	xsp, (xsp+20)
	ret
	dec	6, xsp
	ld	(xsp+4), c
	extz	wa
	pushw	127
	lds	bc, 2
	lds	de, 0
	calr	6424
	cps	l, 1
	jr	nz, 50
	lda	xwa, (xsp+2)
	calr	60257
	lda	xbc, (xsp)
	lds	wa, 2
	calr	60507
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp)
	pushw	127
	calr	58088
	pushw	2
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	lds	bc, 1
	calr	2885
	lds	wa, 5
	calr	62863
	inc	6, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	60190
	lda	xbc, (xsp)
	lds	wa, 0
	calr	60440
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	62844
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "080)"
	lds	bc, 0
	calr	61408
	lds	wa, 7
	calr	62781
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	60107
	lda	xbc, (xsp)
	lds	wa, 1
	calr	60357
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	62761
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	lds	bc, 1
	calr	61325
	ldw	wa, 8
	calr	62697
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-24)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+22), c
	ld	(xsp+24), a
	lda	xwa, (xsp+14)
	calr	5605
	lda	xbc, (xsp+18)
	lds	wa, 0
	calr	60269
	lda	xbc, (xsp+18)
	ld	a, (xbc)
	.byte 0xc7
	swi	3
	.byte 0x99
	extz	wa
	calr	60256
	lda	xbc, (xsp+2)
	ld	a, (xsp+18)
	ld	(xbc), a
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	lda	xwa, (xbc+8)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 5
	ld	(xwa), 27
	jr	3
	ld	(xwa), 3
	ld	(xbc+9), 0
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xbc+10)
	calr	62641
	lda	xwa, (xsp+2)
	calr	60257
	cps	l, 0
	jr	z, 109
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	calr	60172
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	.byte 0x8f
	ex_ff
	push	xsp
	push_sr
	jr	nz, 6
	pushw	wa
	pushw	59
	jr	10
	.byte 0x8f
	ex_ff
	push	xsp
	pop_sr
	jr	nz, 10
	pushw	wa
	pushw	60
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lda	xbc, (xsp+16)
	ldw	wa, 13
	calr	60143
	incm8	1, (xsp+16)
	lda	xbc, (xsp+2)
	ld	a, (xbc+6)
	extz	wa
	ld	c, (xbc+7)
	extz	bc
	calr	60140
	ld	c, (xsp+16)
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
	calr	57701
	jr	6
	pushw	hl
	lds	wa, 3
	calr	58783
	lds	wa, 2
	calr	62487
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+24)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	ldw	wa, 13
	calr	60068
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp)
	calr	62491
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	exts	bc
	calr	60926
	lds	wa, 4
	calr	62439
	inc	6, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	res	7, c
	cps	c, 0
	scc8	nz, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	61365
	ld	a, (xsp)
	inc	4, a
	extz	wa
	calr	62407
	inc	2, xsp
	ret
	lda	xsp, (xsp-22)
	push	xiz
	pushw	144
	pushw	256
	pushw	59
	pushw	51
	call	15790409
	inc	8, xsp
	lda	xbc, (xsp+18)
	lds	wa, 2
	calr	59976
	lda	xbc, (xsp+19)
	lds	wa, 3
	calr	59968
	lda	xbc, (xsp+20)
	lds	wa, 4
	calr	59960
	lda	xbc, (xsp+21)
	lds	wa, 5
	calr	59952
	lda	xbc, (xsp+22)
	lds	wa, 6
	calr	59944
	lda	xwa, (xsp+24)
	calr	5266
	lda	xbc, (xsp+16)
	.byte 0x8f
	push_f
	push	xsp
	nop
	jr	nz, 15
	lds	wa, 0
	calr	59924
	lda	xbc, (xsp+17)
	lds	wa, 1
	calr	59916
	jr	33
	lds	wa, 1
	calr	59909
	ld	(xsp+17), 100
	lda	xbc, (xsp+14)
	lds	wa, 0
	calr	59897
	.byte 0xbf
	ret
	dec	6, e
	pushw	4287
	ldw	wa, 1464
	nop
	nop
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
	.byte 0x9f, 0x06
	ld	xwa, 659555519
	jr	ov, -51
	xor	(xsp), xhl
	ccf
	cps	hl, 0
	jr	nz, 12
	.byte 0x9f, 0x04
	push	xwa
	rcf
	ldb	l, 191
	ei	2
	nop
	nop
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
	.byte 0x9f
	ldwio	163, 2207
	ldb	w, 219
	ld	xwa, 659556543
	jr	ov, -51
	xor	(xsp), xhl
	ccf
	cps	hl, 0
	jr	nz, 13
	.byte 0x9f
	ldio	56, 16
	ldb	l, 159
	.byte 0x06
	ldb	w, 191
	ldwio	80, 2664
	ld	wa, (xsp+8)
	extz	xwa
	div	xwa, xhl
	ld	(xsp+8), wa
	ld	a, (xbc+5)
	extz	wa
	.byte 0xd7
	swi	2
	.byte 0x98
	mul	wa, 87
	.byte 0xd7
	swi	2
	.byte 0x98
	extz	xwa
	div	wa, 100
	.byte 0xd7
	swi	2
	.byte 0x98
	ld	e, (xbc+4)
	.byte 0xc7
	swi	0
	.byte 0x9d
	extz	iz
	.byte 0xd7
	swi	2
	.byte 0x88, 0x9f
	ldwio	240, 3687
	.byte 0xd7
	swi	2
	.byte 0x8b, 0x9f
	ldwio	163, 35038
	mul	xwa, xhl
	ld	iz, wa
	jr	12
	ld	hl, (xsp+10)
	.byte 0xd7
	swi	2
	xor	(xhl), xiz
	.byte 0x88
	mul	xwa, xhl
	ld	iz, wa
	ldb	l, 100
	sub	l, e
	extz	hl
	cps	hl, 0
	jr	nz, 12
	add	iz, 10000
	ld	wa, (xsp+10)
	.byte 0xd7
	swi	2
	.byte 0x98
	jr	8
	ld	wa, iz
	extz	xwa
	div	xwa, xhl
	ld	iz, wa
	ld	c, (xbc+6)
	ld	e, c
	extz	de
	.byte 0xd7
	swi	2
	ld	xde, 2815124519
	extz	hl
	cps	hl, 0
	jr	nz, 6
	add	de, 10000
	jr	4
	extz	xde
	div	xde, xhl
	ld	bc, (xsp+4)
	.byte 0x9f
	ldio	129, 222
	or	(xbc), a
	ccf
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
	.byte 0x8f
	incf
	push	xsp
	halt
	jr	ule, 4
	ld	(xsp+12), 5
	incm8	1, (xsp+12)
	ld	c, (xsp+12)
	extz	bc
	ld	wa, (xsp+4)
	extz	xwa
	div	xwa, xbc
	ld	(xsp+4), wa
	.byte 0x9f, 0x04
	push	xwa
	ldw	hl, 40704
	ldio	32, 232
	ccf
	div	xwa, xbc
	ld	(xsp+8), wa
	ld	wa, (xsp+4)
	add	(xsp+8), wa
	ld	wa, iz
	extz	xwa
	div	xwa, xbc
	ld	iz, wa
	.byte 0x9f
	ldio	134, 48
	.byte 0x92
	nop
	.byte 0x9f, 0x06, 0xa0
	ld	(xsp+6), wa
	ldw	wa, 146
	.byte 0x9f
	ldwio	160, 2751
	.byte 0x50
	ldw	wa, 146
	.byte 0xd7
	swi	2
	.byte 0xa0, 0xd7
	swi	2
	.byte 0x98, 0x9f
	ei	4
	ldw	wa, 51
	ldw	bc, 146
	ld	de, (xsp+6)
	calr	127
	ld	bc, hl
	cps	bc, 0
	jr	nz, 58
	.byte 0x9f
	ldwio	4, 1695
	ldb	w, 159
	ldio	33, 159
	ldwio	34, 27166
	nop
	ld	bc, hl
	cps	bc, 0
	jr	nz, 37
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	wa, (xsp+10)
	ld	bc, (xsp+12)
	ld	de, iz
	calr	86
	ld	bc, hl
	cps	bc, 0
	jr	nz, 17
	.byte 0xd7
	swi	2
	.byte 0x04
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
	pushw	146
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
	retd	2
	lda	xsp, (xsp-32)
	push	xiz
	pushw	144
	pushw	256
	pushw	59
	pushw	51
	call	15790409
	inc	8, xsp
	lda	xbc, (xsp+30)
	lds	wa, 3
	calr	59134
	lda	xbc, (xsp+31)
	lds	wa, 5
	calr	59126
	lda	xbc, (xsp+32)
	lds	wa, 7
	calr	59118
	lda	xbc, (xsp+33)
	ldw	wa, 9
	calr	59109
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
	calr	59073
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
	calr	59025
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
	calr	58978
	lda	xbc, (xsp+23)
	lds	wa, 4
	calr	58970
	lda	xbc, (xsp+22)
	ld	a, (xbc+1)
	.byte 0x81
	xor	(xbc), xwa
	zcf
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
	.byte 0x9f
	ldio	56, 16
	ldb	l, 159
	.byte 0x06
	ldb	w, 191
	ldwio	80, 3176
	extz	bc
	ld	wa, (xsp+8)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+8), wa
	lda	xbc, (xsp+24)
	lds	wa, 6
	calr	58888
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
	calr	58839
	lda	xbc, (xsp+24)
	lds	wa, 6
	calr	58831
	lda	xbc, (xsp+22)
	ld	a, (xbc+2)
	.byte 0x89, 0x01
	xor	(xbc), xwa
	zcf
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
	.byte 0x9f
	incf
	push	xwa
	rcf
	ldb	l, 159
	ldwio	32, 3775
	.byte 0x50
	jr	12
	extz	bc
	ld	wa, (xsp+12)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+12), wa
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	58747
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
	calr	58698
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	58689
	lda	xbc, (xsp+22)
	ld	a, (xbc+3)
	.byte 0x89
	push_sr
	xor	(xbc), xwa
	zcf
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
	.byte 0x9f
	rcf
	push	xwa
	rcf
	ldb	l, 159
	ret
	ldb	w, 191
	ccf
	.byte 0x50
	jr	12
	extz	bc
	ld	wa, (xsp+16)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+16), wa
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	58605
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
	calr	58555
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	58546
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89
	pop_sr
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	1525
	ld	a, (xsp+28)
	extz	wa
	.byte 0xd7
	swi	2
	ld	bc, (xwa-113)
	ldb	c, 203
	.byte 0x8d
	extz	de
	.byte 0xd7
	swi	2
	.byte 0x88
	muls	xwa, xde
	.byte 0xd7
	swi	2
	incm	4, (xwa+33)
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0xd7
	swi	2
	.byte 0xc8
	rcf
	ldb	l, 159
	ccf
	ldb	w, 191
	push_a
	.byte 0x50
	jr	12
	extz	bc
	.byte 0xd7
	swi	2
	.byte 0x88
	exts	xwa
	divs	xwa, xbc
	.byte 0xd7
	swi	2
	.byte 0x98
	ld	wa, (xsp+8)
	.byte 0x9f
	incf
	.byte 0x80, 0x9f
	rcf
	xor	(xwa), w
	.byte 0x89
	extz	xbc
	div	bc, 162
	.byte 0xd7
	swi	2
	.byte 0x88
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
	.byte 0x9f
	ldio	56, 51
	nop
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
	.byte 0x9f
	ldwio	160, 2751
	.byte 0x50
	ldw	wa, 145
	.byte 0x9f
	ret
	.byte 0xa0
	ld	(xsp+14), wa
	ldw	wa, 145
	.byte 0x9f
	ccf
	.byte 0xa0
	ld	(xsp+18), wa
	ldw	wa, 145
	.byte 0x9f
	push_a
	.byte 0xa0
	ld	(xsp+20), wa
	ld	bc, (xsp+6)
	ld	de, (xsp+8)
	ld	wa, (xsp+10)
	pushw	wa
	ldw	wa, 51
	calr	64571
	ld	iz, hl
	cps	iz, 0
	jr	nz, 60
	ld	wa, (xsp+8)
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	ld	hl, (xsp+14)
	pushw	hl
	calr	64549
	ld	iz, hl
	cps	iz, 0
	jr	nz, 38
	ld	wa, (xsp+12)
	ld	bc, (xsp+14)
	ld	de, (xsp+16)
	ld	hl, (xsp+18)
	pushw	hl
	calr	64527
	ld	iz, hl
	cps	iz, 0
	jr	nz, 16
	ld	wa, (xsp+16)
	ld	bc, (xsp+18)
	pushw	bc
	ldw	de, 213
	calr	64508
	ld	iz, (xsp+18)
	lda	xbc, (xsp+22)
	ldw	wa, 96
	sub	wa, iz
	ld	(xbc+3), a
	inc	4, xbc
	ldw	wa, 10
	calr	58220
	lda	xwa, (xsp+26)
	calr	135
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89
	pop_sr
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	1193
	ld	a, (xsp+28)
	extz	wa
	.byte 0xd7
	swi	2
	ld	bc, (xwa-113)
	ldb	c, 203
	.byte 0x8d
	extz	de
	.byte 0xd7
	swi	2
	.byte 0x88
	muls	xwa, xde
	.byte 0xd7
	swi	2
	incm	4, (xwa+33)
	sub	a, c
	ld	c, a
	cps	c, 0
	jr	nz, 13
	.byte 0xd7
	swi	2
	.byte 0xc8
	rcf
	ldb	l, 159
	ccf
	ldb	w, 191
	push_a
	.byte 0x50
	jr	12
	extz	bc
	.byte 0xd7
	swi	2
	.byte 0x88
	exts	xwa
	divs	xwa, xbc
	.byte 0xd7
	swi	2
	.byte 0x98
	ld	c, (xsp+4)
	extz	bc
	.byte 0xd7
	swi	2
	.byte 0x88
	exts	xwa
	divs	xwa, xbc
	.byte 0xd7
	swi	2
	cp	(xwa-41), de
	xor	e, w
	nop
	.byte 0xd7
	swi	2
	.byte 0x8a
	ld	wa, (xsp+20)
	pushw	wa
	ldw	wa, 214
	ld	bc, iz
	calr	64370
	cps	hl, 0
	jr	nz, 16
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	.byte 0x88
	ld	bc, (xsp+20)
	pushw	bc
	ldw	de, 258
	calr	64350
	pop	xiz
	lda	xsp, (xsp+32)
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	lda	xwa, (xsp+4)
	calr	55592
	.byte 0x86
	push	xsp
	ldw	de, 866
	ld	(xiz), 50
	.byte 0x86
	push	xsp
	dec	1, h
	pop_sr
	ld	(xiz), 206
	lda	xbc, (xsp+6)
	lds	wa, 1
	calr	58044
	ld	e, (xiz)
	exts	de
	.byte 0x8f, 0x04
	.ascii "?7f%"
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	lt, 9
	ld	c, (xsp+6)
	exts	bc
	muls	xde, xbc
	jr	14
	ld	c, (xsp+6)
	neg	c
	ld	(xsp+6), c
	exts	bc
	muls	xde, xbc
	neg	de
	exts	xde
	divs	de, 50
	ld	(xiz), e
	pop	xiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	pushw	iz
	ld	(xsp+6), de
	ld	(xsp+8), bc
	ld	(xsp+10), wa
	lda	xbc, (xsp+2)
	lds	wa, 1
	calr	57972
	lda	xwa, (xsp+4)
	calr	55490
	ld	iz, (xsp+16)
	.byte 0x8f, 0x04
	push	xsp
	.byte 0x37
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
	.byte 0x9f
	ldio	63, 59
	nop
	jr	nc, 7
	.byte 0xbf
	ldio	2, 59
	nop
	jr	12
	.byte 0x9f
	ldio	63, 146
	nop
	jr	ule, 5
	.byte 0xbf
	ldio	2, 146
	nop
	cp	iz, 59
	jr	nc, 6
	ldw	iz, 59
	jrl	215
	cp	iz, 146
	jrl	ule, 208
	ldw	iz, 146
	jrl	202
	.byte 0x9f
	ldio	63, 59
	nop
	jr	c, 20
	.byte 0x9f
	ldio	63, 146
	nop
	jr	ugt, 13
	cp	iz, 59
	jr	c, 7
	cp	iz, 146
	jrl	ule, 175
	.byte 0x9f
	ldio	63, 59
	nop
	jr	nc, 7
	cp	iz, 59
	jrl	c, 177
	.byte 0x9f
	ldio	63, 146
	nop
	jr	ule, 7
	cp	iz, 146
	jrl	ugt, 163
	ld	wa, (xsp+6)
	.byte 0x9f
	ldwio	160, 2207
	swi	6
	jr	nc, 68
	cp	iz, 146
	jr	ule, 25
	ldw	bc, 146
	.byte 0x9f
	ldio	161, 222
	.byte 0x8a, 0x9f
	ldio	162, 30
	.byte 0x8b
	nop
	ld	wa, (xsp+10)
	add	wa, hl
	ld	(xsp+6), wa
	ldw	iz, 146
	.byte 0x9f
	ldio	63, 59
	nop
	jr	nc, 98
	ld	wa, (xsp+6)
	.byte 0x9f
	ldwio	160, 15153
	nop
	.byte 0x9f
	ldio	161, 222
	.byte 0x8a, 0x9f
	ldio	162, 30
	jr	mi, 0
	add	(xsp+10), hl
	.byte 0xbf
	ldio	2, 59
	nop
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
	.byte 0x9f
	ldio	63, 146
	nop
	jr	ule, 29
	ld	wa, (xsp+6)
	.byte 0x9f
	ldwio	160, 2207
	ldb	a, 217
	adc	b, b
	nop
	ld	de, (xsp+8)
	sub	de, iz
	calr	31
	add	(xsp+10), hl
	.byte 0xbf
	ldio	2, 146
	nop
	pushw	iz
	.byte 0x9f
	ldio	4, 159
	incf
	.byte 0x04, 0x9f
	rcf
	.byte 0x04
	call	15789564
	inc	8, xsp
	popw	iz
	lda	xsp, (xsp+10)
	retd	2
	mul	xwa, xbc
	extz	xwa
	div	xwa, xde
	ld	hl, wa
	ret
	cp	a, 20
	jr	nc, 4
	ldb	a, 20
	jr	7
	cp	a, 108
	jr	ule, 2
	ldb	a, 108
	sub	a, 12
	ld	l, a
	extz	hl
	div	l, 12
	extz	wa
	div	a, 12
	ld	a, w
	extz	wa
	lda_24	xde, 14737646
	.byte 0xc3
	reti
	or	xwa, xwa
	ldb	e, 207
	ldio	28, 205
	and	(xsp), l
	extz	b
	extz	hl
	ld	(xbc), hl
	ret
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), c
	ld	(xsp+30), a
	pushw	121
	pushw	254
	pushw	73
	pushw	48
	call	15790409
	inc	8, xsp
	lda	xbc, (xsp+18)
	ldw	wa, 10
	calr	57548
	ld	a, (xsp+30)
	extz	wa
	lda	xbc, (xsp+24)
	.byte 0x8f, 0x1c
	push	xsp
	.byte 0x01
	jr	nz, 63
	calr	57531
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xsp+14)
	calr	65413
	.byte 0x9f
	ret
	push	xwa
	ldw	wa, 48896
	rcf
	push_sr
	ldw	wa, 48896
	.byte 0x04
	push_sr
	ldw	wa, 48896
	incf
	push_sr
	swi	6
	nop
	.byte 0xbf
	ei	2
	swi	6
	nop
	ld	wa, (xsp+14)
	sub	wa, 48
	ld	(xsp+8), wa
	.byte 0xbf
	ldwio	2, 254
	ld	wa, (xsp+14)
	sub	(xsp+10), wa
	jrl	145
	calr	57468
	ld	a, (xsp+30)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+26)
	calr	57455
	ld	a, (xsp+30)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+22)
	calr	57442
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xsp+14)
	calr	65324
	ld	a, (xsp+26)
	extz	wa
	lda	xbc, (xsp+16)
	calr	65313
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	65302
	.byte 0x9f
	ret
	push	xwa
	ldw	wa, 40704
	rcf
	push	xwa
	ldw	wa, 40704
	incf
	push	xwa
	ldw	wa, 40704
	rcf
	ldb	w, 159
	ret
	.byte 0xf0
	jr	ule, 8
	ld	wa, (xsp+14)
	dec	1, wa
	ld	(xsp+16), wa
	ld	wa, (xsp+14)
	.byte 0x9f
	incf
	.byte 0xf0
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
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	nz, 63
	pushw	97
	pushw	254
	pushw	97
	pushw	48
	call	15789564
	pushw	121
	.byte 0x9f
	push_f
	.byte 0x04
	pushw	97
	.byte 0x9f, 0x1c, 0x04
	call	15789619
	pushw	121
	.byte 0x9f
	ex_ff
	.byte 0x04
	pushw	97
	.byte 0x9f, 0x1a, 0x04
	call	15789619
	lda	xsp, (xsp+24)
	pushw	121
	.byte 0x9f
	ldio	4, 11
	jr	lt, 0
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
	.byte 0xd7
	swi	2
	pop_sr
	jr	lt, 0
	ld	bc, hl
	cp	(xsp+8), bc
	jr	ule, 22
	ldw	iz, 72
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	lt, 3
	ldw	iz, 122
	ld	wa, (xsp+14)
	sub	wa, hl
	ld	(xsp+16), wa
	jr	12
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	lt, 4
	add	iz, ix
	jr	2
	sub	iz, ix
	cp	(xsp+10), bc
	jr	ule, 26
	.byte 0xd7
	swi	2
	pop_sr
	jrl	gt, -28928
	ccf
	push	xsp
	nop
	jr	lt, 5
	.byte 0xd7
	swi	2
	pop_sr
	popw	wa
	nop
	ld	wa, (xsp+14)
	add	wa, hl
	ld	(xsp+12), wa
	jr	24
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	lt, 10
	.byte 0xd7
	swi	2
	.byte 0x88
	sub	wa, de
	.byte 0xd7
	swi	2
	.byte 0x98
	jr	8
	.byte 0xd7
	swi	2
	.byte 0x88
	add	wa, de
	.byte 0xd7
	swi	2
	.byte 0x98
	pushw	iz
	.byte 0x9f
	ccf
	.byte 0x04
	pushw	iz
	pushw	48
	call	15789564
	.byte 0xd7
	swi	2
	.byte 0x04, 0x9f
	ex_ff
	.byte 0x04
	pushw	iz
	.byte 0x9f
	calr	7428
	swi	4
	cp	xwa, xiy
	.byte 0xd7
	swi	2
	.byte 0x04
	pushw	254
	.byte 0xd7
	swi	2
	.byte 0x04, 0x9f
	ldb	b, 4
	call	15789564
	pushw	121
	.byte 0x9f
	pushw	wa
	.byte 0x04
	pushw	97
	.byte 0x9f
	pushw	ix
	.byte 0x04
	call	15789619
	lda	xsp, (xsp+32)
	pushw	121
	.byte 0x9f
	ei	4
	pushw	iz
	.byte 0x9f
	ldwio	4, 13085
	cp	xwa, xiz
	inc	8, xsp
	pushw	121
	.byte 0x9f
	ldio	4, 215
	swi	2
	.byte 0x04, 0x9f
	incf
	.byte 0x04
	call	15789619
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+28)
	ret
	cps	a, 0
	jr	ge, 2
	neg	a
	ld	(xbc), a
	ret
	lda	xsp, (xsp-28)
	ld	(xsp+22), e
	ld	(xsp+24), c
	ld	(xsp+26), a
	ld	a, (xsp+24)
	extz	wa
	calr	56927
	cps	hl, 0
	jrl	z, 376
	ld	a, (xsp+24)
	extz	wa
	add	wa, wa
	lda_24	xbc, 14737659
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 183
	.byte 0x50, 0xbf
	push_sr
	push_sr
	push_a
	nop
	.byte 0x8f, 0x1a
	push	xsp
	nop
	jr	nz, 10
	.byte 0xbf, 0x04
	push_sr
	ldb	l, 0
	ldw	wa, 247
	jr	8
	.byte 0xbf, 0x04
	push_sr
	ldw	wa, 12288
	.byte 0xf1
	nop
	.byte 0x97, 0x04
	pushw	wa
	ld	wa, (xsp+4)
	.byte 0x9f, 0x06, 0xa0
	pushw	wa
	.byte 0x9f
	ldwio	4, 18717
	stda32	61424, xwa
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+18)
	calr	56892
	ld	a, (xsp+22)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+20)
	calr	56879
	ld	a, (xsp+22)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+16)
	calr	56866
	ld	a, (xsp+22)
	inc	3, a
	extz	wa
	lda	xbc, (xsp+14)
	calr	56853
	.byte 0xbf
	ccf
	.byte 0xb7, 0xbf
	push_a
	.byte 0xb7, 0xbf
	rcf
	.byte 0xb7, 0xbf
	ret
	.byte 0xb7, 0x8f, 0x1a
	push	xsp
	nop
	jr	nz, 46
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	calr	64717
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+10)
	calr	64706
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+8)
	calr	64695
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xsp+6)
	calr	64684
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
	.byte 0x9f
	push_sr
	.byte 0xa0
	pushw	wa
	.byte 0x9f
	incf
	.byte 0x04, 0x9f, 0x04, 0x04, 0x9f
	ccf
	.byte 0x04
	call	15789564
	ld	wa, (xsp+8)
	.byte 0x9f
	ldwio	160, 40744
	ccf
	.byte 0x04
	pushw	wa
	.byte 0x9f
	push_f
	.byte 0x04
	call	15789564
	.byte 0x9f
	rcf
	.byte 0x04, 0x9f
	push_f
	.byte 0x04
	ld	wa, (xsp+20)
	.byte 0x9f
	ex_ff
	.byte 0xa0
	pushw	wa
	.byte 0x9f
	calr	7428
	swi	4
	cp	xwa, xiy
	lda	xsp, (xsp+24)
	lda	xsp, (xsp+28)
	ret
	dec	8, xsp
	ld	(xsp+2), e
	ld	(xsp+4), c
	ld	(xsp+6), a
	lda	xbc, (xsp)
	lds	wa, 0
	calr	56572
	ld	a, (xsp+4)
	.byte 0x87, 0xf1
	jr	z, 56
	.byte 0x8f
	push_sr
	push	xsp
	.byte 0x01
	jr	nz, 12
	ld	a, (xsp+4)
	extz	wa
	calr	56503
	cps	hl, 0
	jr	z, 38
	ld	a, (xsp+4)
	extz	wa
	calr	56263
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	calr	56516
	pushw	0
	ld	a, (xsp+8)
	extz	wa
	pushw	wa
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 1
	calr	55985
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), c
	ld	(xsp+18), a
	.byte 0xbf, 0x04
	push_sr
	popw	iy
	nop
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 5
	.byte 0xbf, 0x04
	push_sr
	pushw	wa
	nop
	lda	xbc, (xsp+14)
	lds	wa, 2
	calr	56472
	.byte 0xbf
	ret
	.byte 0xb7
	lda	xbc, (xsp+12)
	lds	wa, 3
	calr	56461
	.byte 0x8f
	incf
	push	xix
	reti
	.byte 0x8f
	incf
	push	xsp
	halt
	jr	ule, 4
	ld	(xsp+12), 5
	ld	wa, (xsp+4)
	add	wa, 53
	ld	(xsp+6), wa
	.byte 0xbf
	ldio	2, 26
	nop
	ld	wa, (xsp+4)
	add	(xsp+8), wa
	ld	a, (xsp+14)
	extz	wa
	add	wa, 86
	.byte 0xd7
	swi	2
	.byte 0x98, 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 18
	ld	c, (xsp+12)
	mul	c, 3
	ld	wa, (xsp+8)
	sub	wa, bc
	inc	6, wa
	ld	(xsp+10), wa
	jr	18
	ld	c, (xsp+12)
	mul	c, 6
	ld	wa, (xsp+8)
	sub	wa, bc
	add	wa, 12
	ld	(xsp+10), wa
	ld	iz, (xsp+6)
	.byte 0x9f
	ldwio	166, 1695
	.byte 0x04
	pushw	232
	.byte 0x9f
	ldio	4, 11
	ld	xhl, 4048100608
	.byte 0xf0
	inc	8, xsp
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	nz, 115
	.byte 0x9f
	ldio	4, 215
	swi	2
	and	(xwa-40), b
	ldwio	0, 40744
	incf
	.byte 0x04
	pushw	67
	call	15789564
	.byte 0x9f
	ccf
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04, 0x9f
	push_a
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), b
	ldwio	0, 7464
	swi	4
	cp	xwa, xiy
	lda	xsp, (xsp+16)
	ldw	de, 232
	.byte 0xd7
	swi	2
	add	(xde), xsp
	rcf
	push	xsp
	nop
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
	.byte 0xd7
	swi	2
	.byte 0x81
	ld	wa, (xsp+6)
	jr	10
	ldw	bc, 232
	ld	wa, de
	add	wa, wa
	.byte 0x9f
	ldwio	128, 10536
	.byte 0x9f
	ret
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	jr	116
	.byte 0xd7
	swi	2
	and	(xde-38), b
	ld	xhl, 1058049792
	nop
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
	.byte 0x9f
	ldwio	128, 2719
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	pushw	wa
	pushw	bc
	call	15789564
	.byte 0x9f
	rcf
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), w
	ldwio	0, 40744
	ex_ff
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	call	15789564
	lda	xsp, (xsp+16)
	.byte 0x9f
	ldio	4, 11
	.byte 0xe8
	nop
	.byte 0x9f
	incf
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), w
	ldwio	0, 7464
	swi	4
	cp	xwa, xiy
	inc	8, xsp
	.byte 0x9f
	ei	4
	.byte 0xd7
	swi	2
	.byte 0x04, 0x9f
	ret
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	call	15789619
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	lda	xbc, (xsp+14)
	lds	wa, 4
	calr	56070
	.byte 0xbf
	ret
	.byte 0xb7
	lda	xbc, (xsp+12)
	lds	wa, 5
	calr	56059
	lda	xbc, (xsp+10)
	lds	wa, 5
	calr	56051
	lds	wa, 1
	lds	bc, 7
	calr	56060
	ld	(xsp+4), l
	.byte 0xbf
	incf
	.byte 0xb7, 0xbf
	ei	2
	.byte 0xab
	nop
	.byte 0xbf
	ldio	2, 26
	nop
	.byte 0x9f
	ldio	56, 118
	nop
	ld	a, (xsp+14)
	extz	wa
	add	wa, 86
	.byte 0xd7
	swi	2
	.byte 0x98
	ld	a, (xsp+12)
	.byte 0x8f
	incf
	xor	(xbc), w
	ccf
	ld	iz, (xsp+8)
	sub	iz, wa
	add	iz, 14
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 3
	ld	iz, (xsp+6)
	.byte 0x0b, 0xab
	.long NakaObj_FmuteVol_DataEntry
	pushw	118
	pushw	67
	call	15790409
	inc	8, xsp
	ld	a, (xsp+10)
	.byte 0x8f, 0x04, 0xc1
	jr	z, 49
	.byte 0x9f
	ldio	4, 215
	swi	2
	decm8	6, (xwa-40)
	pushw	wa
	.byte 0x9f
	incf
	.byte 0x04
	pushw	67
	call	15789564
	pushw	iz
	.byte 0xd7
	swi	2
	.byte 0x04, 0x9f
	push_a
	.byte 0x04, 0xd7
	swi	2
	decm8	6, (xwa-40)
	pushw	wa
	call	15789564
	lda	xsp, (xsp+16)
	pushw	iz
	pushw	232
	pushw	iz
	.byte 0xd7
	swi	2
	.byte 0x04
	jr	44
	pushw	iz
	push	xiz
	pushw	67
	call	15789564
	.byte 0x9f
	rcf
	.byte 0x04, 0xd7
	swi	2
	incm8	6, (xwa-40)
	pushw	wa
	pushw	iz
	.byte 0xd7
	swi	2
	.byte 0x04
	call	15789564
	lda	xsp, (xsp+16)
	.byte 0x9f, 0x08
	.long NakaInst_data_E80B04
	.byte 0x9f
	incf
	.byte 0x04, 0xd7
	swi	2
	incm8	6, (xwa-40)
	pushw	wa
	call	15789564
	inc	8, xsp
	.byte 0x9f
	ei	4
	push	xiz
	.byte 0xd7
	swi	2
	.byte 0x04
	call	15789619
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-22)
	push	xiz
	lda	xbc, (xsp+24)
	lds	wa, 2
	calr	55830
	.byte 0xbf
	push_f
	.byte 0xb7
	lda	xbc, (xsp+22)
	lds	wa, 3
	calr	55819
	.byte 0x8f
	ex_ff
	push	xix
	reti
	.byte 0x8f
	ex_ff
	push	xsp
	halt
	jr	ule, 4
	ld	(xsp+22), 5
	lda	xbc, (xsp+20)
	lds	wa, 4
	calr	55797
	.byte 0xbf
	push_a
	.byte 0xb7
	lda	xbc, (xsp+18)
	lds	wa, 5
	calr	55786
	.byte 0x8f
	ccf
	push	xix
	reti
	.byte 0x8f
	ccf
	push	xsp
	halt
	jr	ule, 4
	ld	(xsp+18), 5
	ld	a, (xsp+24)
	.byte 0x8f
	push_a
	.byte 0xf1
	jr	c, 8
	ld	(xsp+24), 79
	ld	(xsp+20), 80
	.byte 0xbf
	ei	2
	.byte 0x82
	nop
	.byte 0xbf
	ldwio	2, 26
	.byte 0x9f
	ldwio	56, 77
	ld	a, (xsp+24)
	.byte 0xc7
	swi	0
	.byte 0x99
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
	.byte 0xd7
	swi	2
	pop_sr
	.byte 0x82
	nop
	.byte 0xd7
	swi	2
	.byte 0x88, 0x9f
	incf
	.byte 0xa0, 0xd7
	swi	2
	.byte 0x98
	ld	c, (xsp+18)
	mul	c, 3
	ld	wa, (xsp+10)
	sub	wa, bc
	inc	6, wa
	ld	(xsp+14), wa
	.byte 0xbf
	rcf
	push_sr
	.byte 0x82
	nop
	ld	wa, (xsp+14)
	sub	(xsp+16), wa
	ld	wa, (xsp+8)
	sub	wa, iz
	cp	wa, 20
	scc8	c, a
	ld	(xsp+4), a
	pushw	130
	pushw	232
	pushw	77
	pushw	67
	call	15790409
	inc	8, xsp
	ld	bc, iz
	sub	bc, 67
	.byte 0xd7
	swi	2
	.byte 0x88
	cp	wa, bc
	jr	ugt, 10
	ld	de, iz
	.byte 0xd7
	swi	2
	.byte 0xa2
	ld	wa, (xsp+6)
	jr	8
	ldw	de, 67
	ld	wa, (xsp+12)
	add	wa, bc
	.byte 0x9f
	incf
	.byte 0x04
	pushw	iz
	pushw	wa
	pushw	de
	call	15789564
	inc	8, xsp
	.byte 0x8f, 0x04
	push	xsp
	.byte 0x01
	jr	nz, 12
	.byte 0x9f
	ret
	.byte 0x04, 0x9f
	ldwio	4, 4255
	.byte 0x04
	pushw	iz
	jr	63
	.byte 0x9f
	ldwio	4, 35038
	add	wa, 10
	pushw	wa
	.byte 0x9f
	rcf
	.byte 0x04
	pushw	iz
	call	15789564
	.byte 0x9f
	ccf
	.byte 0x04
	ld	wa, (xsp+18)
	sub	wa, 10
	pushw	wa
	.byte 0x9f
	ex_ff
	.byte 0x04
	ld	wa, iz
	add	wa, 10
	pushw	wa
	call	15789564
	lda	xsp, (xsp+16)
	.byte 0x9f
	ret
	.byte 0x04, 0x9f
	ldwio	4, 3743
	.byte 0x04
	ld	wa, (xsp+14)
	sub	wa, 10
	pushw	wa
	call	15789564
	inc	8, xsp
	ldw	bc, 232
	.byte 0x9f
	ldio	161, 159
	rcf
	swi	1
	jr	ugt, 11
	ld	de, (xsp+8)
	.byte 0x9f
	rcf
	.byte 0x82
	ld	wa, (xsp+6)
	jr	8
	ldw	de, 232
	ld	wa, (xsp+14)
	add	wa, bc
	pushw	wa
	pushw	de
	.byte 0x9f
	ccf
	.byte 0x04, 0x9f
	ret
	.byte 0x04
	call	15789564
	.byte 0x9f
	ret
	.byte 0x04
	pushw	iz
	.byte 0x9f
	push_f
	.byte 0x04
	pushw	iz
	call	15789619
	.byte 0x9f
	ex_ff
	.byte 0x04, 0x9f, 0x1a, 0x04, 0x9f
	ldb	b, 4
	.byte 0x9f
	calr	7428
	ldw	hl, 61678
	lda	xsp, (xsp+24)
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	ldada	xde, 1698
	.byte 0xf3
	reti
	or	xwa, xwa
	.byte 0x51
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	ldada	xde, 1698
	.byte 0xd3
	reti
	or	xwa, xwa
	ldb	w, 177
	.byte 0x50
	ret
	stda16	1706, wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xaa, 0x06
	ret
	stda8	1708, a
	ret
	.byte 0xb0
	push_a
	.byte 0xac, 0x06
	ret

SeMenu_ProcessEffect:
	lda xsp, (xsp - 38)
	push_werp 0xfa
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
	stda16 1706, xbc
	mrdb5 0x8a, 0x02, 0x19, 0xac, 0x06
	ldi_berp 0xfb, 0
	jr SeMenu_ProcessEffect_CompareLoop

SeMenu_ProcessEffect_StoreLoop:
	ldto_berp A, 0xfb
	add a, 0x12
	extz wa
	ldto_berp C, 0xfb
	inc 3, c
	extz bc
	ld_srib3 C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_LoopEnd
	inc1_berp 0xfb

SeMenu_ProcessEffect_CompareLoop:
	lda xde, (xsp + 2)
	ldto_berp A, 0xfb
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
	stda16 1714, xbc
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
	stda16 1706, xhl
	mrib4 0x81, 0x19, 0xac, 0x06
	ldi_berp 0xfb, 0
	jr SeMenu_ProcessEffect_AltData2

SeMenu_ProcessEffect_AltData:
	ldto_berp A, 0xfb
	add a, 0x11
	extz wa
	ldto_berp C, 0xfb
	inc 3, c
	extz bc
	ld_srib3 C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_AltBranch
	inc1_berp 0xfb

SeMenu_ProcessEffect_AltData2:
	lda xde, (xsp + 2)
	ldto_berp A, 0xfb
	cp a, (xde + 2)
	jr c, SeMenu_ProcessEffect_AltData

SeMenu_ProcessEffect_AltBranch:
	jr SeMenu_ProcessEffect_Data3

SeMenu_ProcessEffect_AltEnd:
	sll hl, 8
	ld a, (xde)
	extz wa
	add hl, wa
	stda16 1706, xhl
	mrib4 0x81, 0x19, 0xac, 0x06
	ldi_berp 0xfb, 0
	jr SeMenu_ProcessEffect_Section2_End

SeMenu_ProcessEffect_Section2:
	ldto_berp A, 0xfb
	add a, 0xc
	extz wa
	ldto_berp C, 0xfb
	inc 3, c
	extz bc
	ld_srib3 C, 0x07, 0xe8, 0xe4
	extz bc
	calr SeMenu_StorePartParam
	cp_erpb 0xfb, 0x14
	jr ugt, SeMenu_ProcessEffect_Data3
	inc1_berp 0xfb

SeMenu_ProcessEffect_Section2_End:
	lda xde, (xsp + 2)
	ldto_berp A, 0xfb
	cp a, (xde + 2)
	jr c, SeMenu_ProcessEffect_Section2

SeMenu_ProcessEffect_Data3:
	pop_werp 0xfa
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
	ldada xbc, 1698
	st_dri3b B, 0x07, 0xe4, 0xe0
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
	stda16 1712, xbc
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
	ldada xbc, 1698
	st_dri3b B, 0x07, 0xe4, 0xe0
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
	.byte 0xc7
	swi	2
	pop_sr
	incf
	jr	12
	.byte 0xc7
	swi	2
	pop_sr
	ccf
	cps	a, 3
	jr	nz, 4
	.byte 0xc7
	swi	2
	pop_sr
	scf
	lds	iz, 0
	.byte 0xc7
	swi	3
	.byte 0xa8, 0x8f
	ldwio	63, 25344
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
	ldwio	241, 57447
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
	stda8 1711, a
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
	stda8 1710, a
	ret

SeMenu_SetMode_Data:
	stda16	1712, wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xb0, 0x06
	ret
	stda16	1714, wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xb2, 0x06
	ret

SeMenu_LoadSoundBankCfg:
	ldmi16 (xwa), 0x6b4
	ret

SeMenu_SetSoundBank:
	stda8 1716, a
	ret

SeMenu_LoadFilterType:
	ldmi16 (xwa), 0x6b5
	ret

SeMenu_SetFilterParam1:
	stda8 1717, a
	ret

SeMenu_LoadFilterParam2:
	ldmi16 (xwa), 0x6b6
	ret

SeMenu_SetFilterMode:
	stda8 1718, a
	ret

SeMenu_SetFilterCoeff:
	stda8 1721, a
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
	lda xwa, (xsp + 4)
	calr SeMenu_LoadFilterParam2
	cp (xsp + 4), 0x1
	jr nz, SeMenu_SetupSoundBankPair_Direct
	lda xwa, (xsp + 8)
	calr SeMenu_LoadMasterPtr
	ld a, (xsp + 8)
	extz wa
	lds bc, 0
	lds de, 0
	call SndParam_UpdateChannelTuning
	ld (xiz), l
	ld a, (xsp + 8)
	extz wa
	lds bc, 0
	lds de, 1
	call SndParam_UpdateChannelTuning
	ld xwa, (xsp + 10)
	ld (xwa), l
	cp (xiz), 0xff
	jr nz, SeMenu_SetupSoundBankPair_CheckValid
	ld a, (xsp + 8)
	extz wa
	lds bc, 1
	lds de, 1
	call SndParam_UpdateChannelTuning
	ld (xiz), l
	ld xwa, (xsp + 10)
	ld (xwa), l

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
	ld_spib A, 0xe8
	lda_dpi XBC, 0xec
	cp xde, xbc
	jr c, SeMenu_ComputeParamTableAddr_ScanLoop
	ret

SeMenu_ComputeParamTableAddr_Data:
	dec	1, a
	extz	wa
	mul	wa, 10
	extz	xwa
	add	xwa, 132595
	ld	xde, xwa
	lda	xhl, (xwa+10)
	.byte 0xc5, 0xe8
	ldb	a, 245
	.byte 0xe4
	ld	xbc, 4134007531
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
	stda8	1719, a
	ret

SeMenu_LoadPatchStatus:
	ldmi16 (xwa), 0x6b8
	ret

SeMenu_SetPatchBank:
	stda8 1720, a
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
	ldada	xix, 63926
	ldada	xhl, 63952
	ldada	xde, 63978
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
	push_sr
	push	xsp
	.byte 0x01
	jr	nz, 31
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	nz, 7
	ld	a, (xsp+4)
	or	(xde), a
	jr	44
	.byte 0x87
	push	xsp
	push_sr
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
	.byte 0x01
	jr	nz, 4
	and	(xde), a
	jr	11
	.byte 0x87
	push	xsp
	push_sr
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
	push_sr
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
	setda 2, 10407
	ret

SeMenu_SetEditEnable_Clear:
	resda 2, 10407
	ret

SeMenu_OrPartConfig:
	ordm8_24 132594, a
	ret

SeMenu_OrPartConfig_Data:
	.long Pad_BeforeBitmap_Dredt0d
	chgm	2, (xhl+14)
	anddm32_24	2556131, xsp
	mul	d, 14

SeMenu_StoreParamByte:
	dec 1, a
	extz wa
	ldada xde, 1722
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_LoadParamByte:
	dec 1, a
	extz wa
	ldada xde, 1722
	extz xwa
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ret

SeMenu_SetConfirmState:
	stda8 1732, a
	ret

SeMenu_LoadConfirmData:
	ldmi16 (xwa), 0x6c4
	ret

SeMenu_ReturnZero:
	ldb l, 0x0
	ret

SeMenu_SetDisplayState:
	stda8 1733, a
	ret

SeMenu_DisplayState_Data:
	.byte 0xb0
	push_a
	.byte 0xc5, 0x06
	ret
	stda8	1626, a
	ret
	.byte 0xb0
	push_a
	pop	xde
	ei	14

SeMenu_StoreEffectParam:
	extz wa
	ldada xde, 1726
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_StoreEffectParam_Data:
	extz	wa
	ldada	xde, 1726
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	ret

SeMenu_StoreEffectCoeff:
	extz wa
	ldada xde, 1729
	extz xwa
	add xwa, xde
	ld (xwa), c
	ret

SeMenu_StoreEffectCoeff_Data:
	extz	wa
	ldada	xde, 1729
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	ret
	lda	xsp, (xsp-40)
	ld	xiy, 14737898
	lda	xix, (xsp+22)
	.byte 0x85
	rcf
	ldiw
	ld	xiy, 14737901
	lda	xix, (xsp+18)
	.byte 0x85
	rcf
	ldiw
	ld	(xsp), 0
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+34)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 43038
	swi	7
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+26)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 46366
	swi	7
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	push_sr
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
	.byte 0xf3
	reti
	sla	xwa, 53
	ld	a, (xiy)
	.byte 0xc7, 0xee, 0x99
	lda	xwa, (xsp+26)
	.byte 0xf3
	reti
	.byte 0xe0, 0xec
	ldw	ix, 8324
	sla	w, 1
	.byte 0xc7
	ld	xbc, xiz
	add	a, w
	.byte 0xc7, 0xee
	or	(xbc-57), iz
	.byte 0x99
	ld	(xiy), a
	lda	xwa, (xsp+22)
	.byte 0xc3
	reti
	.byte 0xe0, 0xec
	ldb	l, 199
	ld	xbc, xiz
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
	push_sr
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
	pop_sr
	jr	c, -41
	lda	xsp, (xsp+40)
	ret

SeMenu_RefreshPartDisplay:
	ldada xwa, 63926
	ld c, (xwa)
	ld a, (xwa + 1)
	extz wa
	pushw wa
	extz bc
	pushw bc
	pushw 0x0
	call SeMenu_DisplayPartValue
	ldada xwa, 63952
	ld c, (xwa)
	ld a, (xwa + 1)
	extz wa
	pushw wa
	extz bc
	pushw bc
	pushw 0x1
	call SeMenu_DisplayPartValue
	ldada xwa, 63978
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
	stdi8	1709, 0
	ret
	stdi8	1709, 0
	ret
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737920
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737992
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14738064
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14738136
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+14)
	mul	a, 3
	.byte 0xc7
	swi	3
	cp	(xbc-57), hl
	jr	gt, -57
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 24
	ld	(xbc+9), 232
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	4
	.byte 0xbf, 0x04
	.asciz "080'"
	call	15757111
	lds	wa, 2
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+14)
	mul	a, 3
	.byte 0xc7
	swi	3
	cp	(xbc-57), hl
	jr	ge, -57
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	5
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	call	15757111
	lds	wa, 3
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+14)
	mul	a, 3
	.byte 0xc7
	swi	3
	.byte 0x99
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 7
	ld	(xbc+7), 0
	ld	(xbc+8), 7
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	6
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	call	15757111
	lds	wa, 4
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xbc, (xsp+16)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	.byte 0x8f
	rcf
	push	xsp
	.byte 0x01
	jrl	nz, 132
	lda	xbc, (xsp+14)
	ldw	wa, 14
	call	SeMenu_LoadPartParam
	.byte 0x8f
	ret
	push	xix
	.byte 0x1f
	lda	xbc, (xsp+2)
	ld	a, (xsp+14)
	extz	wa
	lda_24	xde, 14738208
	.byte 0xc3
	reti
	or	xwa, xwa
	ldb	a, 177
	ld	xbc, 520095417
	ld	(xbc+7), 0
	ld	(xbc+8), 12
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	lda	xwa, (xsp+2)
	call	15756146
	cps	l, 1
	jr	nz, 54
	ld	a, (xsp+5)
	extz	wa
	lda_24	xbc, 14738240
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 191
	ret
	ld	xhl, 238031577
	nop
	call	SeMenu_StorePartParam
	lda	xde, (xsp+14)
	pushw	31
	lds	wa, 0
	ldw	bc, 19
	call	SeMenu_RegisterElement_Extended
	pushw	14
	pushw	39
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 6
	jrl	128
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	push_sr
	jr	nz, 34
	.byte 0xc7
	swi	3
	pop_sr
	retd	64199
	pop_sr
	pushw	bc
	ldw	wa, 15
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 15
	ld	(xwa+7), 0
	ld	(xwa+8), 10
	ld	xbc, xwa
	jr	43
	.byte 0xc7
	swi	3
	pop_sr
	rcf
	.byte 0xc7
	swi	2
	pop_sr
	pushw	de
	ldw	wa, 16
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 15
	lda	xwa, (xbc+7)
	.byte 0x8f
	rcf
	push	xsp
	pop_sr
	jr	nz, 5
	ld	(xwa), 4
	jr	3
	ld	(xwa), 0
	ld	(xbc+8), 10
	ld	(xbc+9), 6
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	lds	de, 0
	call	15757111
	lds	wa, 6
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 40
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	ret	z
	ldw	wa, 39
	lds	bc, 1
	lds	de, 1
	call	15765037
	ret
	cps	a, 0
	jr	nz, 9
	ldw	wa, 42
	lds	bc, 0
	jp	SeMenu_SendEvent
	ldw	wa, 39
	lds	bc, 2
	lds	de, 1
	jp	15765037
	dec	2, xsp
	cps	a, 0
	jr	nz, 41
	lda	xbc, (xsp)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	ule, 38
	decm8	1, (xsp)
	ld	c, (xsp)
	extz	bc
	ldw	wa, 13
	call	SeMenu_StorePartParam
	pushw	13
	pushw	39
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	jr	11
	ldw	wa, 39
	lds	bc, 3
	lds	de, 1
	call	15765037
	inc	2, xsp
	ret
	dec	2, xsp
	cps	a, 0
	jr	nz, 41
	lda	xbc, (xsp)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	.byte 0x04
	jr	nc, 38
	incm8	1, (xsp)
	ld	c, (xsp)
	extz	bc
	ldw	wa, 13
	call	SeMenu_StorePartParam
	pushw	13
	pushw	39
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	jr	11
	ldw	wa, 39
	lds	bc, 4
	lds	de, 1
	call	15765037
	inc	2, xsp
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 9
	lds	de, 0
	jp	15759774
	extz	wa
	ldw	bc, 10
	lds	de, 0
	jp	15759874
	extz	wa
	ldw	bc, 8
	ldw	de, 11
	jp	15759974
	extz	wa
	ldw	bc, 12
	lds	de, 0
	jp	15760132
	extz	wa
	ldw	bc, 16
	ldw	de, 13
	jp	15760232
	extz	wa
	ldw	bc, 14
	lds	de, 0
	jp	15760392
	extz	wa
	lds	bc, 7
	ldw	de, 15
	jp	15760494
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 39
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 40
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 42
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 40
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 6
	lds	wa, 0
	jp	15759718
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 40
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 6
	lds	wa, 1
	jp	15759718
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 40
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	ldw	wa, 41
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 20
	jp	15760654
	extz	wa
	ldw	bc, 21
	jp	15760798
	extz	wa
	ldw	bc, 22
	jp	15760942
	extz	wa
	ldw	bc, 19
	jp	15761086
	extz	wa
	ldw	bc, 17
	jp	15761165
	extz	wa
	ldw	bc, 18
	jp	15761248
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 39
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 41
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 42
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 41
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 41
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 41
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	ldw	wa, 40
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	lds	bc, 1
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	lds	bc, 1
	jp	15759013
	extz	wa
	lds	bc, 1
	jp	15759138
	extz	wa
	lds	bc, 1
	jp	15759263
	extz	wa
	lds	bc, 1
	jp	15759388
	extz	wa
	lds	bc, 1
	jp	15759511
	extz	wa
	lds	bc, 1
	jp	15759614
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 40
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	jr	nz, 9
	ldw	wa, 39
	lds	bc, 0
	jp	SeMenu_SendEvent
	lds	wa, 1
	lds	bc, 1
	jp	15757276
	cps	a, 0
	ret	z
	lds	wa, 1
	lds	bc, 2
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	lds	bc, 3
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	lds	bc, 4
	call	15757276
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret

