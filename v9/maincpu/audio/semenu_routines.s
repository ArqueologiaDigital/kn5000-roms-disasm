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
	ld (0x7f42:16), a
	ld (0xe3dc:16), 238
	set 6, (0xe3de:16)
	ret

SeMenu_ClearNotification:
	ld (0xe3dc:16), a
	set 1, (0xe3de:16)
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
	ld c, (0x008d3a:24)
	ld (xwa), c
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
	ld wa, 0:i3
	ld bc, 6:i3
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
	ld a, 0x80:opc
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
	ld hl, 0:i3
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
	ld hl, 0:i3
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
	ld hl, 0:i3
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
	calr	SeMenu_LoadObjEntries
	lda	xbc, (xsp+2)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
SeMenu_RegisterParamDisplay_Data_Loop:
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, SeMenu_RegisterParamDisplay_Data_Loop
	lda	xwa, (xsp+14)
	calr	SeMenu_LoadMasterPtr
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
	calr	SeMenu_FlushDisplayObj
	popw	iz
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-22)
	pushw	iz
	ld	iz, de
	ld	(xsp+20), c
	ld	(xsp+22), a
	lda	xwa, (xsp+12)
	calr	SeMenu_LoadObjEntries
	lda	xbc, (xsp+2)
	ld	xwa, xbc
	lda	xbc, (xbc+9)
SeMenu_RegisterParamDisplay_Data_Loop2:
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, SeMenu_RegisterParamDisplay_Data_Loop2
	lda	xwa, (xsp+14)
	calr	SeMenu_LoadMasterPtr
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
	calr	SeMenu_FlushDisplayObj
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
SeMenu_SetupDisplayObject_Data_Loop:
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, SeMenu_SetupDisplayObject_Data_Loop
	lda	xwa, (xsp+12)
	calr	SeMenu_LoadMasterPtr
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
	calr	SeMenu_FlushDisplayObj
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
SeMenu_InitDisplayColumn_Data_Loop:
	stib_dsp 224, 0
	cp	xwa, xbc
	jr	c, SeMenu_InitDisplayColumn_Data_Loop
	lda	xwa, (xsp+10)
	calr	SeMenu_LoadMasterPtr
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
	calr	SeMenu_FlushDisplayObj
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
	calr	SeMenu_LoadMasterPtr
	ld	c, (xsp+8)
	ld	a, c
	extz	wa
	div	a, 20
	ld	e, a
	ld	a, c
	extz	wa
	div	a, 20
	ld	c, w
	cp	e, 0:i3
	jr	z, SeMenu_SetDisplayValue_Data_Skip
	ld	e, 17:opc
	jr	2
SeMenu_SetDisplayValue_Data_Skip:
	ld	e, 16:opc
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
	normal
	jr	nz, 8
	lda	xwa, (0xf9d0:16)
	ld	(xwa), e
	jr	19
	.byte 0x87
	push	xsp
	push	sr
	jr	nz, 8
	lda	xwa, (0xf9ea:16)
	ld	(xwa), e
	jr	6
	lda	xwa, (0xf9b6:16)
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
	lda xwa, (0xf9d0:16)
	ld (xwa), e
	jr SeMenu_InitTrackInfo_Store

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
	cp a, 4:i3
	jr z, SeMenu_SetFlags_Type4
	cp a, 3:i3
	jr z, SeMenu_SetFlags_Type3
	cp a, 2:i3
	jr z, SeMenu_SetFlags_Type2
	cp a, 1:i3
	jr z, SeMenu_SetFlags_Type1
	cp a, 0:i3
	ret nz
	ld a, 0x0:opc
	jr SeMenu_SetFlags_SetCarryAndStore

SeMenu_SetFlags_Type1:
	ld a, 0x1:opc
	jr SeMenu_SetFlags_SetCarryAndStore

SeMenu_SetFlags_Type2:
	ld a, 0x1:opc
	jr SeMenu_SetFlags_SetCarryAndStore_Alt

SeMenu_SetFlags_Type3:
	ormi8 (xbc), 0x3
	ret

SeMenu_SetFlags_Type4:
	ormi8 (xbc), 0x3
	jr SeMenu_SetFlags_SetBit7_DE

SeMenu_SetFlags_Type0x1x:
	ld a, 0x2:opc

SeMenu_SetFlags_SetCarryAndStore:
	scf
	mri_d2 0xb1, 0x2c
	ret

SeMenu_SetFlags_Type0x2x:
	setm 2, (xbc)
	setm 6, (xde)
	ret

SeMenu_SetFlags_Type0x3x:
	ld a, 0x2:opc

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
	ld wa, 0:i3
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
	ld wa, 0:i3
	calr SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, SeMenu_SetupMenuDisplay_Section3

SeMenu_SetupMenuDisplay_Section3_Loop:
	popw_erp 0xfa
	lda xsp, (xsp + 14)
	ret

SeMenu_SetupMenuDisplay_Section3_End:
	cp	a, 0:i3
	scc8	nz, a
	ld	(1628:16), a
	ret

SeMenu_SetupMenuDisplay_Finalize:
	ldmi16 (xwa), 0x65c
	ret

SeMenu_SetupMenuDisplay_Finalize_Data:
	cp	a, 1:i3
	jr	c, SeMenu_SetupMenuDisplay_Finalize_Data_Skip
	cp	a, 4:i3
	jr	ugt, SeMenu_SetupMenuDisplay_Finalize_Data_Skip
	ld	(1629:16), a
	ret
SeMenu_SetupMenuDisplay_Finalize_Data_Skip:
	ld	(1629:16), 1
	ret

SeMenu_ValidatePartNumber:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld c, (1629:16)
	cp c, 1:i3
	jr c, SeMenu_ValidatePartNumber_Default
	cp c, 4:i3
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
	cp hl, 0:i3
	jr nz, SeMenu_ValidatePartNumber_End
	ldib_erp 0xfb, 1

SeMenu_ValidatePartNumber_ScanLoop:
	stb_erp A, 0xfb
	extz wa
	calr SeMenu_IsPartEnabled
	cp hl, 0:i3
	jr z, SeMenu_ValidatePartNumber_NextPart
	stb_erp C, 0xfb
	jr SeMenu_ValidatePartNumber_Store

SeMenu_ValidatePartNumber_NextPart:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, SeMenu_ValidatePartNumber_ScanLoop
	ld c, 0x1:opc

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
	ld	wa, 1:i3
	calr	122
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, SeMenu_PartMask_Data_Code_Skip
	ld	a, l
	cpl	a
	and	(1630:16), a
	jr	SeMenu_PartMask_Data_Code_Entry
SeMenu_PartMask_Data_Code_Skip:
	or	(1630:16), l
SeMenu_PartMask_Data_Code_Entry:
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
	jr	nz, SeMenu_PartMask_Data_Code_Skip2
	pushw	hl
	ld	wa, 0:i3
	ldw	bc, 17
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_PartMask_Data_Code_Epilogue
SeMenu_PartMask_Data_Code_Skip2:
	pushw	hl
	ld	wa, 0:i3
	ldw	bc, 13
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_PartMask_Data_Code_Epilogue:
	inc	8, xsp
	ret

SeMenu_IsPartEnabled:
	cp a, 1:i3
	jr c, SeMenu_IsPartEnabled_OutOfRange
	cp a, 4:i3
	jr ule, SeMenu_IsPartEnabled_CheckMask

SeMenu_IsPartEnabled_OutOfRange:
	ld hl, 0:i3
	ret

SeMenu_IsPartEnabled_CheckMask:
	ld c, a
	add c, a
	dec 2, c
	extz bc
	ld wa, 1:i3
	calr SeMenu_BitShiftMask
	ld a, (1630:16)
	and a, l
	cp a, 0:i3
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
	ld de, 0:i3
	extz bc
	cp bc, 0:i3
	ret ule

SeMenu_BitShiftMask_Loop:
	add l, l
	inc 1, de
	cp de, bc
	jr c, SeMenu_BitShiftMask_Loop
	ret

SeMenu_BitShiftMask_End:
	ld	l, a
	ld	de, 0:i3
	extz	bc
	cp	bc, 0:i3
	ret	ule
	srl	l, 1
	inc	1, de
	cp	de, bc
	jr	c, -9
	ret
SeMenu_TransferPartValues_EndData_Helper:
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
	ldw	(63:8), 0x6e00:io
	pop	sr
	ld	l, 0:opc
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
	calr	SeMenu_BitShiftMask
	cpl	l
	and	(xsp+4), l
	ld	a, (xiz)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	SeMenu_BitShiftMask_End
	ld	(xiz), l
	ld	a, (xsp+10)
	and	(xiz), a
	ld	c, (xsp+18)
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	le, SeMenu_BitShiftMask_End_Skip
	ld	a, (xiz)
	.byte 0x8f
	ret
	.byte 0xf1
	jr	z, SeMenu_BitShiftMask_End_Skip2
	ld	a, (xsp+14)
	.byte 0x86
	and	(xbc), xhl
	.byte 0xf1
	jr	ugt, SeMenu_BitShiftMask_End_Loop
	ld	a, (xsp+14)
	jr	SeMenu_BitShiftMask_End_Join2
SeMenu_BitShiftMask_End_Loop:
	ld	a, (xsp+18)
	add	(xiz), a
SeMenu_BitShiftMask_End_Join:
	ld	a, (xiz)
	.byte 0x8f
	ldw	(193:8), 4824:io
	ld	c, (xsp+12)
	extz	bc
	calr	SeMenu_BitShiftMask
	ld	xwa, (xsp+6)
	ld	(xwa), l
	ld	c, (xsp+4)
	or	(xwa), c
	ld	hl, 1:i3
	jr	SeMenu_BitShiftMask_End_Epilogue
SeMenu_BitShiftMask_End_Skip:
	ld	a, (xiz)
	cp	a, (xsp+16)
	jr	nz, SeMenu_BitShiftMask_End_Skip3
SeMenu_BitShiftMask_End_Skip2:
	ld	hl, 0:i3
SeMenu_BitShiftMask_End_Epilogue:
	pop	xiz
	lda	xsp, (xsp+16)
	ret
SeMenu_BitShiftMask_End_Skip3:
	ld	a, (xsp+16)
	sub	a, c
	.byte 0x86, 0xf1
	jr	c, SeMenu_BitShiftMask_End_Loop
	ld	a, (xsp+16)
SeMenu_BitShiftMask_End_Join2:
	ld	(xiz), a
	jr	SeMenu_BitShiftMask_End_Join
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
	calr	SeMenu_BitShiftMask
	cpl	l
	and	(xsp+4), l
	ld	a, (xiz)
	extz	wa
	ld	c, (xsp+12)
	extz	bc
	calr	SeMenu_BitShiftMask_End
	ld	(xiz), l
	ld	a, (xsp+10)
	and	(xiz), a
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	le, SeMenu_BitShiftMask_End_Skip4
	ld	a, (xiz)
	.byte 0x8f
	ret
	.byte 0xf1
	jr	z, SeMenu_BitShiftMask_End_Skip5
	ld	c, (xiz)
	ld	a, (xsp+14)
	sub	a, c
	ld	c, a
	ld	a, (xsp+18)
	cp	c, a
	jr	ugt, SeMenu_BitShiftMask_End_Loop2
	ld	a, (xsp+14)
	jr	SeMenu_BitShiftMask_End_Join4
SeMenu_BitShiftMask_End_Loop2:
	ld	a, (xsp+18)
	add	(xiz), a
SeMenu_BitShiftMask_End_Join3:
	ld	a, (xiz)
	.byte 0x8f
	ldw	(193:8), 4824:io
	ld	c, (xsp+12)
	extz	bc
	calr	SeMenu_BitShiftMask
	ld	xwa, (xsp+6)
	ld	(xwa), l
	ld	c, (xsp+4)
	or	(xwa), c
	ld	hl, 1:i3
	jr	SeMenu_BitShiftMask_End_Epilogue2
SeMenu_BitShiftMask_End_Skip4:
	ld	a, (xiz)
	cp	a, (xsp+16)
	jr	nz, SeMenu_BitShiftMask_End_Skip6
SeMenu_BitShiftMask_End_Skip5:
	ld	hl, 0:i3
SeMenu_BitShiftMask_End_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+16)
	ret
SeMenu_BitShiftMask_End_Skip6:
	ld	c, (xiz)
	ld	a, (xsp+16)
	.byte 0x8f
	ccf
	and	(xbc), xhl
	.byte 0xf1
	jr	lt, SeMenu_BitShiftMask_End_Loop2
	ld	a, (xsp+16)
SeMenu_BitShiftMask_End_Join4:
	ld	(xiz), a
	jr	SeMenu_BitShiftMask_End_Join3
	dec	2, xsp
	lda	xwa, (xsp)
	calr	SeMenu_SetupMenuDisplay_Finalize
	.byte 0x87
	push	xsp
	nop
	jr	z, SeMenu_BitShiftMask_End_Skip7
	ld	wa, 0:i3
	jr	SeMenu_BitShiftMask_End_Join5
SeMenu_BitShiftMask_End_Skip7:
	ld	wa, 1:i3
SeMenu_BitShiftMask_End_Join5:
	calr	SeMenu_SetupMenuDisplay_Section3_End
	ld	wa, 1:i3
	calr	SeMenu_SetupMenuDisplay
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	inc	2, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	calr	SeMenu_ValidatePartNumber
	lda	xwa, (xsp)
	calr	SeMenu_LoadObjEntries
	lda	xde, (xsp+4)
	.byte 0x87
	push	xsp
	nop
	jr	nz, SeMenu_BitShiftMask_End_Skip8
	ld	a, (xsp+2)
	extz	wa
	pushw	7
	ldw	bc, 54
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_BitShiftMask_End_Entry
SeMenu_BitShiftMask_End_Skip8:
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	ld	c, a
	pushw	7
	ld	wa, 0:i3
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_BitShiftMask_End_Entry:
	.byte 0x8f, 0x04
	pop_f
	xor	(xix+6), c
	.byte 0xa8
	inc	6, xsp
	ret

SeMenu_TransferPartValues:
	cp c, 0:i3
	jr z, SeMenu_TransferPartValues_Loop
	cp c, 4:i3
	jr ule, SeMenu_TransferPartValues_InnerLoop

SeMenu_TransferPartValues_Loop:
	ldw hl, 0xffff
	ret

SeMenu_TransferPartValues_InnerLoop:
	dec 1, c
	extz bc
	sla bc, 2
	cp a, 0:i3
	jr nz, SeMenu_TransferPartValues_Data2
	extz xbc
	lda xbc, (xbc + 59)
	ld (xde), c

SeMenu_TransferPartValues_Data:
	ld hl, 0:i3
	ret

SeMenu_TransferPartValues_Data2:
	cp a, 2:i3
	jr nz, SeMenu_TransferPartValues_AltEntry
	ld xwa, 0x4b
	jr SeMenu_TransferPartValues_AltLoop

SeMenu_TransferPartValues_AltEntry:
	cp a, 1:i3
	jr nz, SeMenu_TransferPartValues_Loop
	ld xwa, 0x2b

SeMenu_TransferPartValues_AltLoop:
	lda_dri XWA, 0x07, 0xe0, 0xe4
	ld (xde), a
	jr SeMenu_TransferPartValues_Data
SeMenu_TransferPartValues_EndData_Helper2:
	cp a, 1:i3
	jr nz, SeMenu_TransferPartValues_AltData
	ld a, 0x6:opc

SeMenu_TransferPartValues_AltInner:
	ld (xbc), a
	ld hl, 0:i3
	ret

SeMenu_TransferPartValues_AltData:
	cp a, 0:i3
	jr nz, SeMenu_TransferPartValues_End
	ld a, 0x26:opc
	jr SeMenu_TransferPartValues_AltInner

SeMenu_TransferPartValues_End:
	cp a, 2:i3
	jr nz, SeMenu_TransferPartValues_End2
	ld a, 0x38:opc
	jr SeMenu_TransferPartValues_AltInner

SeMenu_TransferPartValues_End2:
	ldw hl, 0xffff
	ret

SeMenu_TransferPartValues_EndData:
	cp	a, 1:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip3
	ld	a, (1678:16)
	cp	a, 1:i3
	jr	c, SeMenu_TransferPartValues_EndData_Skip
	cp	a, 4:i3
	jr	ule, SeMenu_TransferPartValues_EndData_Skip2
SeMenu_TransferPartValues_EndData_Skip:
	ld	(1678:16), 1
SeMenu_TransferPartValues_EndData_Skip2:
	ld	a, (1678:16)
	jr	SeMenu_TransferPartValues_EndData_Join
SeMenu_TransferPartValues_EndData_Skip3:
	cp	a, 0:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip6
	ld	a, (1677:16)
	cp	a, 1:i3
	jr	c, SeMenu_TransferPartValues_EndData_Skip4
	cp	a, 4:i3
	jr	ule, SeMenu_TransferPartValues_EndData_Skip5
SeMenu_TransferPartValues_EndData_Skip4:
	ld	(1677:16), 1
SeMenu_TransferPartValues_EndData_Skip5:
	ld	a, (1677:16)
	jr	SeMenu_TransferPartValues_EndData_Join
SeMenu_TransferPartValues_EndData_Skip6:
	cp	a, 2:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip9
	ld	a, (1679:16)
	cp	a, 1:i3
	jr	c, SeMenu_TransferPartValues_EndData_Skip7
	cp	a, 4:i3
	jr	ule, SeMenu_TransferPartValues_EndData_Skip8
SeMenu_TransferPartValues_EndData_Skip7:
	ld	(1679:16), 1
SeMenu_TransferPartValues_EndData_Skip8:
	ld	a, (1679:16)
	jr	SeMenu_TransferPartValues_EndData_Join
SeMenu_TransferPartValues_EndData_Skip9:
	ld	a, 1:opc
SeMenu_TransferPartValues_EndData_Join:
	ld	(xbc), a
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip10
	lda	xwa, (1677:16)
	cp	c, 0:i3
	jr	z, SeMenu_TransferPartValues_EndData_Skip12
	decm8	1, (xwa)
	jr	SeMenu_TransferPartValues_EndData_Entry
SeMenu_TransferPartValues_EndData_Skip10:
	cp	a, 1:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip11
	lda	xwa, (1678:16)
	jr	-18
SeMenu_TransferPartValues_EndData_Skip11:
	cp	a, 2:i3
	ret	nz
	lda	xwa, (1679:16)
	jr	-28
SeMenu_TransferPartValues_EndData_Skip12:
	incm8	1, (xwa)
SeMenu_TransferPartValues_EndData_Entry:
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
	cp	c, 1:i3
	jr	c, 4
	cp	c, 6:i3
	jr	ule, 2
	ld	c, 1:opc
	ld	(xwa), c
	ret
	ld	(1685:16), a
	ret
	cp	a, 6:i3
	jr	z, SeMenu_TransferPartValues_EndData_Skip14
	cp	a, 5:i3
	jr	z, SeMenu_TransferPartValues_EndData_Skip13
	cp	a, 2:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip15
	ld	a, 26:opc
	jr	SeMenu_TransferPartValues_EndData_Join2
SeMenu_TransferPartValues_EndData_Skip13:
	ld	a, 35:opc
	jr	SeMenu_TransferPartValues_EndData_Join2
SeMenu_TransferPartValues_EndData_Skip14:
	ld	a, 38:opc
	jr	SeMenu_TransferPartValues_EndData_Join2
SeMenu_TransferPartValues_EndData_Skip15:
	ld	a, 23:opc
SeMenu_TransferPartValues_EndData_Join2:
	ld	(xbc), a
	ret
	cp	a, 6:i3
	jr	z, SeMenu_TransferPartValues_EndData_Skip17
	cp	a, 5:i3
	jr	z, SeMenu_TransferPartValues_EndData_Skip16
	cp	a, 2:i3
	jr	nz, 12
	ld	a, 24:opc
	jr	10
SeMenu_TransferPartValues_EndData_Skip16:
	ld	a, 33:opc
	jr	6
SeMenu_TransferPartValues_EndData_Skip17:
	ld	a, 36:opc
	jr	2
	ld	a, 21:opc
	ld	(xbc), a
	ret
SeMenu_ApplyPartEdit_Helper:
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
	calr	SeMenu_TransferPartValues_EndData_Helper
	cp	l, 0:i3
	jr	z, SeMenu_TransferPartValues_EndData_Epilogue
	ld	a, (xsp+22)
	inc	2, a
	ldb_erp a, 251
	ldw	wa, 127
	ld	bc, 0:i3
	calr	SeMenu_BitShiftMask
	stb_erp c, 251
	extz	bc
	extz	hl
	lda	xde, (xsp+5)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, SeMenu_TransferPartValues_EndData_Skip18
	pushw	hl
	ld	wa, 0:i3
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_TransferPartValues_EndData_Join3
SeMenu_TransferPartValues_EndData_Skip18:
	pushw	hl
	ld	wa, 3:i3
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_TransferPartValues_EndData_Join3:
	ld	c, (xsp+5)
	extz	bc
	ldw	wa, 11
	calr	SeMenu_StorePartParam
	pushw	11
	pushw	59
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_TransferPartValues_EndData_Epilogue:
	pop qiz
	lda	xsp, (xsp+22)
	ret
SeMenu_ApplyPartEdit_Helper2:
	dec	8, xsp
	push	xiz
	ld	(xsp+6), e
	ld	(xsp+8), c
	ld	(xsp+10), a
	ld	xiz, (xsp+16)
	ld	xwa, xiz
	calr	SeMenu_TransferPartValues_EndData_Helper
	extz	hl
	cp	hl, 0:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip19
	ld	l, 0:opc
	jr	SeMenu_TransferPartValues_EndData_Epilogue2
SeMenu_TransferPartValues_EndData_Skip19:
	lda	xwa, (xsp+4)
	calr	SeMenu_LoadObjEntries
	ld	a, (xiz+6)
	extz	wa
	ld	c, (xiz+7)
	extz	bc
	calr	SeMenu_BitShiftMask
	extz	hl
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+20)
	extz	bc
	lda	xde, (xiz+3)
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, SeMenu_TransferPartValues_EndData_Skip20
	pushw	hl
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_TransferPartValues_EndData_Join4
SeMenu_TransferPartValues_EndData_Skip20:
	pushw	hl
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_TransferPartValues_EndData_Join4:
	ld	a, (xsp+8)
	extz	wa
	ld	c, (xiz+3)
	extz	bc
	calr	SeMenu_StorePartParam
	ld	a, (xsp+8)
	extz	wa
	pushw	wa
	ld	a, (xsp+12)
	extz	wa
	pushw	wa
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	l, 1:opc
SeMenu_TransferPartValues_EndData_Epilogue2:
	pop	xiz
	inc	8, xsp
	retd	6
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	calr	SeMenu_ValidatePartNumber
	ld	a, (xsp)
	.byte 0x8f
	push	sr
	.byte 0xf1
	jr	z, SeMenu_TransferPartValues_EndData_Skip21
	ld	a, (xsp+2)
	extz	wa
	calr	SeMenu_IsPartEnabled
	cp	hl, 0:i3
	jr	nz, SeMenu_TransferPartValues_EndData_Skip22
SeMenu_TransferPartValues_EndData_Skip21:
	ld	l, 0:opc
	jr	SeMenu_TransferPartValues_EndData_Epilogue3
SeMenu_TransferPartValues_EndData_Skip22:
	ld	a, (xsp+2)
	extz	wa
	calr	SeMenu_SetupMenuDisplay_Finalize_Data
	ld	l, 1:opc
SeMenu_TransferPartValues_EndData_Epilogue3:
	inc	4, xsp
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+10)
	extz	wa
	calr	SeMenu_IsPartEnabled
	cp	hl, 0:i3
	jrl	z, SeMenu_TransferPartValues_EndData_Epilogue4
	ld	a, (xsp+10)
	inc	4, a
	ld	(xsp), a
	extz	wa
	lda	xbc, (xsp+6)
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+6)
	ld	a, (xbc)
	bit	5, a
	jr	nz, SeMenu_TransferPartValues_EndData_Skip23
	set	5, a
	ld	(xbc), a
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xsp+4)
	calr	SeMenu_TransferPartValues_EndData
	lda	xde, (xsp+6)
	ld	c, (xde)
	and	c, 63
	ld	(xde), c
	ld	a, (xsp+4)
	dec	1, a
	sll	a, 6
	or	c, a
	ld	(xde), c
	jr	SeMenu_TransferPartValues_EndData_Join6
SeMenu_TransferPartValues_EndData_Skip23:
	bit	4, a
	jr	z, SeMenu_TransferPartValues_EndData_Skip24
	and	a, 15
	jr	SeMenu_TransferPartValues_EndData_Join5
SeMenu_TransferPartValues_EndData_Skip24:
	set	4, a
SeMenu_TransferPartValues_EndData_Join5:
	ld	(xbc), a
SeMenu_TransferPartValues_EndData_Join6:
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xsp+2)
	calr	SeMenu_TransferPartValues_EndData_Helper2
	ld	a, (xsp+10)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+6)
	pushw	240
	calr	SeMenu_RegisterElement_Extended
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
SeMenu_TransferPartValues_EndData_Epilogue4:
	lda	xsp, (xsp+14)
	ret
SeMenu_ApplyPartEdit_Helper3:
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
	ldw	(63:8), 0x6e00:io
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
	jr z, SeMenu_TransferPartValues_EndData_Epilogue5
	cpib_erp 250, 3
	jr nz, SeMenu_TransferPartValues_EndData_Skip25
	ldib_erp 250, 1
	jr	SeMenu_TransferPartValues_EndData_Join7
SeMenu_TransferPartValues_EndData_Skip25:
	cpib_erp 250, 1
	jr nz, SeMenu_TransferPartValues_EndData_Join7
	ldib_erp 250, 0
SeMenu_TransferPartValues_EndData_Join7:
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 3:i3
	calr	SeMenu_BitShiftMask
	ldb_erp l, 251
	stb_erp a, 251
	cpl	a
	and	(xsp+8), a
	stb_erp a, 250
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	calr	SeMenu_BitShiftMask
	or	(xsp+8), l
	ld	c, (xsp+6)
	extz	bc
	stb_erp a, 251
	extz	wa
	lda	xde, (xsp+8)
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, SeMenu_TransferPartValues_EndData_Skip26
	pushw	wa
	ld	wa, 0:i3
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_TransferPartValues_EndData_Join8
SeMenu_TransferPartValues_EndData_Skip26:
	pushw	wa
	ld	wa, 3:i3
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_TransferPartValues_EndData_Join8:
	ld	c, (xsp+8)
	extz	bc
	ldw	wa, 12
	calr	SeMenu_StorePartParam
	pushw	12
	pushw	59
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_TransferPartValues_EndData_Epilogue5:
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
	ld hl, 0:i3
	ret

SeMenu_CheckObjValid:
	ldw hl, 0xffff
	cp (0x020c35:24), a
	ret nz
	ld hl, 0:i3
	ret

SeMenu_FillEntryTable:
	lda xhl, (0x020c33:24)
	ld c, (xhl + 3)
	ldb_erp C, 0xe6
	ldib_erp 0xea, 0
	cpib_erp 0xe6, 0
	ret ule
	ld de, 6:i3

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
	cp a, 1:i3
	jr nz, SeMenu_SetupPartDisplay_Alt
	ld w, 0x0:opc
	cp e, 0:i3
	ret ule
	lda xix, (0x020bf3:24)
	ld hl, 0:i3

SeMenu_SetupPartDisplay_Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Loop
	ret

SeMenu_SetupPartDisplay_Alt:
	cp a, 2:i3
	jr nz, SeMenu_SetupPartDisplay_Mode2
	ld w, 0x0:opc
	cp e, 0:i3
	ret ule
	lda xix, (0x020c03:24)
	ld hl, 0:i3

SeMenu_SetupPartDisplay_AltLoop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_AltLoop
	ret

SeMenu_SetupPartDisplay_Mode2:
	cp a, 3:i3
	jr nz, SeMenu_SetupPartDisplay_Mode3
	ld w, 0x0:opc
	cp e, 0:i3
	ret ule
	lda xix, (0x020c13:24)
	ld hl, 0:i3

SeMenu_SetupPartDisplay_Mode2Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Mode2Loop
	ret

SeMenu_SetupPartDisplay_Mode3:
	cp a, 4:i3
	ret nz
	ld w, 0x0:opc
	cp e, 0:i3
	ret ule
	lda xix, (0x020c23:24)
	ld hl, 0:i3

SeMenu_SetupPartDisplay_Mode3Loop:
	ldb_sri A, 0x07, 0xe4, 0xec
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, w
	inc 1, hl
	cp w, e
	jr c, SeMenu_SetupPartDisplay_Mode3Loop
	ret

SeMenu_SetupPartDisplay_End:
	cp	a, 1:i3
	jr	nz, SeMenu_SetupPartDisplay_End_Skip
	ld	w, 0:opc
	cp	e, 0:i3
	ret	ule
	lda	xix, (0x020bf3:24)
	ld	hl, 0:i3
SeMenu_SetupPartDisplay_End_Loop:
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp	w, e
	jr	c, SeMenu_SetupPartDisplay_End_Loop
	ret
SeMenu_SetupPartDisplay_End_Skip:
	cp	a, 2:i3
	jr	nz, SeMenu_SetupPartDisplay_End_Skip2
	ld	w, 0:opc
	cp	e, 0:i3
	ret	ule
	lda	xix, (0x020c03:24)
	ld	hl, 0:i3
SeMenu_SetupPartDisplay_End_Loop2:
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp	w, e
	jr	c, SeMenu_SetupPartDisplay_End_Loop2
	ret
SeMenu_SetupPartDisplay_End_Skip2:
	cp	a, 3:i3
	jr	nz, SeMenu_SetupPartDisplay_End_Skip3
	ld	w, 0:opc
	cp	e, 0:i3
	ret	ule
	lda	xix, (0x020c13:24)
	ld	hl, 0:i3
SeMenu_SetupPartDisplay_End_Loop3:
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp	w, e
	jr	c, SeMenu_SetupPartDisplay_End_Loop3
	ret
SeMenu_SetupPartDisplay_End_Skip3:
	cp	a, 4:i3
	ret	nz
	ld	w, 0:opc
	cp	e, 0:i3
	ret	ule
	lda	xix, (0x020c23:24)
	ld	hl, 0:i3
SeMenu_SetupPartDisplay_End_Loop4:
	ld_rrb a, xix, hl
	st_rrb a, xbc, hl
	inc 1, w
	inc 1, hl
	cp	w, e
	jr	c, SeMenu_SetupPartDisplay_End_Loop4
	ret
	ld	xhl, (xsp+4)
	bit	15, bc
	jr	z, SeMenu_SetupPartDisplay_End_Skip4
	ld	c, 1:opc
	jr	SeMenu_SetupPartDisplay_End_Join
SeMenu_SetupPartDisplay_End_Skip4:
	ld	c, 0:opc
SeMenu_SetupPartDisplay_End_Join:
	ld	(xhl), c
	ld	c, a
	cp	wa, 16
	jr	ugt, SeMenu_SetupPartDisplay_End_Skip5
SeMenu_SetupPartDisplay_End_Join2:
	ld	(xde), c
SeMenu_SetupPartDisplay_End_Join3:
	ld	hl, 0:i3
	jr	SeMenu_SetupPartDisplay_End_Return
SeMenu_SetupPartDisplay_End_Skip5:
	cp	wa, 17
	jr	c, SeMenu_SetupPartDisplay_End_Skip6
	cp	wa, 24
	jr	ugt, SeMenu_SetupPartDisplay_End_Skip6
	sub	c, 17
	ld	(xde), c
	.byte 0xb3, 0xbf
	jr	SeMenu_SetupPartDisplay_End_Join3
SeMenu_SetupPartDisplay_End_Skip6:
	cp	wa, 25
	jr	nz, SeMenu_SetupPartDisplay_End_Skip7
	ld	c, 16:opc
	jr	SeMenu_SetupPartDisplay_End_Join2
SeMenu_SetupPartDisplay_End_Skip7:
	ldw	hl, 0xffff
SeMenu_SetupPartDisplay_End_Return:
	retd	4
	ld	xhl, xbc
	ld	b, 0:opc
	cp	e, 0:i3
	ret	ule
	ldb_spi c, 236
	lda_dpi xhl, 224
	inc 1, b
	cp b, e
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
	normal
	jr	nz, 8
	lda	xwa, (0xf9d0:16)
	ld	e, (xwa)
	jr	20
	.byte 0x8f, 0x06
	push	xsp
	push	sr
	jr	nz, 8
	lda	xwa, (0xf9ea:16)
	ld	e, (xwa)
	jr	6
	lda	xwa, (0xf9b6:16)
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
	ldb_erp a, 251
	ld	a, (xbc+1)
	ld	(xsp+2), a
	cp_erpb 251, 16
	jr	z, 20
	cp_erpb 251, 17
	jr	z, 14
	ld	xwa, (xsp+14)
	.byte 0xb0
	push_a
	.byte 0xad, 0x06, 0x80
	.ascii "?'kChL¿"
	.byte 0x04
	ldw	wa, 0xa61e
	ld	a, 143:opc
	max
	push	xsp
	nop
	jr	nz, 41
	cp_erpb 251, 17
	jr	nz, 5
	ldib_erp 251, 1
	jr	3
	ldib_erp 251, 0
	ld	xwa, (xsp+14)
	ld	c, (xsp+2)
	ld	(xwa), c
	stb_erp c, 251
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
	ld	l, 99:opc
	pushw	3759
	ld	w, 176:opc
	nop
	nop
	ld	(1709:16), 0
	pop qiz
	lda	xsp, (xsp+16)
	ret
	.byte 0xb0
	push_a
	.byte 0xad, 0x06
	ret
	ld	(1709:16), a
	ret
	cp	a, 15
	ret	ugt
	extz	wa
	lda	xde, (0x020bf3:24)
	st_rrb c, xde, wa
	ret
	cp a, 15
	ret	ugt
	extz	wa
	lda	xde, (0x020bf3:24)
	.byte 0xc3
	reti
	or	xwa, xwa
	ld	a, 177:opc
	ld	xbc, 0x1b12d80e
	ld	e, 149:opc
	swi	1
SeMenu_SetupPartDisplay_End_Sub:
	dec	1, c
	or	c, e
	extz	bc
	cp	a, 0:i3
	jr	nz, 6
	ld	wa, bc
	jp	UI_PostDialValueEvent
	ld	wa, bc
	jp	UI_PostDialRangeEvent
SeMenu_ApplyPartEdit_Helper4:
	dec	2, xsp
	ld	(xsp), a
	ld	wa, 1:i3
	calr	65499
	ld	c, (xsp)
	extz	bc
	ld	wa, 0:i3
	ld	de, 0:i3
	calr	SeMenu_SetupPartDisplay_End_Sub
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	ldw	de, 128
	calr	SeMenu_SetupPartDisplay_End_Sub
	inc	2, xsp
	ret
SeMenu_ApplyPartEdit_Helper5:
	ld	l, a
	res	7, l
	ld	e, 255:opc
	cp	l, 0:i3
	jr	nz, SeMenu_SetupPartDisplay_End_Skip8
	ld	e, 1:opc
SeMenu_SetupPartDisplay_End_Skip8:
	ld	(xbc), e
	bit	7, a
	ret	z
	ld	a, (xbc)
	muls	a, 3
	ld	(xbc), a
	ret
	cp	a, 97
	jr	c, SeMenu_SetupPartDisplay_End_Skip9
	ld	(xbc), 32
	ret
SeMenu_SetupPartDisplay_End_Skip9:
	extz	wa
	lda	xde, (GUI_DisplayStructData_0x1129:24)
	ld_rrb a, xde, wa
	ld (xbc), a
	ret
	cp a, 130
	jr	c, 5
	ld	(xbc), 0
	jr	14
	extz	wa
	lda	xde, (GUI_DisplayStructData_0x118A:24)
	.byte 0xc3
	reti
	or	xwa, xwa
	ld	a, 177:opc
	ld	xbc, 0xb05f3f81
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
	push	sr
	push	xsp
	nop
	jr	nz, 3
	ldib_erp 250, 4
	lda	xwa, (xsp+4)
	calr	62729
	ld	a, (xsp+4)
	extz	wa
	calr	62930
	cp	hl, 0:i3
	jr	z, 9
	ld	a, (xsp+6)
	extz	wa
	ld	bc, 0:i3
	jr	SeMenu_SetupPartDisplay_End_Join4
	ldib_erp 251, 1
	cpib_erp 250, 1
	jr c, SeMenu_SetupPartDisplay_End_Skip11
SeMenu_SetupPartDisplay_End_Loop5:
	stb_erp a, 251
	extz	wa
	calr	SeMenu_IsPartEnabled
	cp	hl, 0:i3
	jr	z, SeMenu_SetupPartDisplay_End_Skip10
	stb_erp a, 251
	extz	wa
	calr	SeMenu_SetupMenuDisplay_Finalize_Data
	ld	a, (xsp+6)
	extz	wa
	ld	bc, 0:i3
	jr	SeMenu_SetupPartDisplay_End_Join4
SeMenu_SetupPartDisplay_End_Skip10:
	inc1b_erp 251
	stb_erp a, 251
	cpb_erp a, 250
	jr	ule, SeMenu_SetupPartDisplay_End_Loop5
SeMenu_SetupPartDisplay_End_Skip11:
	ld	wa, 1:i3
	calr	SeMenu_SetupMenuDisplay_Finalize_Data
	ld	a, (xsp+6)
	extz	wa
	ld	bc, 0:i3
SeMenu_SetupPartDisplay_End_Join4:
	calr	SeMenu_SendEvent
	pop qiz
	inc	6, xsp
	ret

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
	ld a, 0x40:opc
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
	ld wa, 3:i3
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
	cp	a, 0:i3
	scc8	z, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	63396
	.byte 0x87
	push	xsp
	normal
	jr	nz, 11
	ld	a, 42:opc
SeMenu_ApplyPartEdit_Join:
	extz	wa
	ld	bc, 1:i3
	calr	60130
	jr	18
	.byte 0x87
	push	xsp
	nop
	jr	nz, 4
	ld	a, 47:opc
	jr	-18
	.byte 0x87
	push	xsp
	push	sr
	jr	nz, SeMenu_ApplyPartEdit_Epilogue
	ld	a, 57:opc
	jr	SeMenu_ApplyPartEdit_Join
SeMenu_ApplyPartEdit_Epilogue:
	inc	2, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 3
	ld	(xbc+7), 6
	ld	(xbc+8), 3
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080*"
	ld	bc, 4:i3
	ld	de, 0:i3
	calr	63540
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	ld	wa, 2:i3
	calr	8712
	ld	wa, 3:i3
	calr	64891
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 31
	ld	(xbc+7), 0
	ld	(xbc+8), 30
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	inc	3, a
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080*"
	ld	bc, 4:i3
	ld	de, 0:i3
	calr	63415
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	ld	wa, 2:i3
	calr	8587
	ld	wa, 4:i3
	calr	64766
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 2:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	inc	1, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	ld	bc, 2:i3
	ld	de, 0:i3
	calr	63290
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	ld	wa, 1:i3
	calr	8462
	ld	wa, 5:i3
	calr	64641
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 1:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080*"
	ld	bc, 1:i3
	ld	de, 0:i3
	calr	63167
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 16
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	nz, 10
	ld	c, (xsp+3)
	extz	bc
	ld	wa, 0:i3
	calr	8339
	ld	wa, 6:i3
	calr	64518
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	ld	bc, 3:i3
	ld	de, 0:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	ld	wa, 7:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_TransferPartValues_EndData
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+14)
	extz	bc
	lda	xde, (xsp+12)
	calr	SeMenu_TransferPartValues
	lda	xbc, (xsp)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 7
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+12)
	inc	2, a
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 42
	ld	bc, 3:i3
	ld	de, 0:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	ldw	wa, 8
	calr	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+20)
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	calr	61897
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 11
	.byte 0x87
	push	xsp
	nop
	jr	z, 30
	ld	wa, 0:i3
	ld	bc, 0:i3
	jr	9
	.byte 0x87
	push	xsp
	normal
	jr	z, 19
	ld	wa, 0:i3
	ld	bc, 1:i3
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
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, SeMenu_ApplyPartEdit_Epilogue2
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "0807"
	ld	bc, 3:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	calr	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 1:i3
	calr	SeMenu_ApplyPartEdit_Helper4
SeMenu_ApplyPartEdit_Epilogue2:
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, SeMenu_ApplyPartEdit_Epilogue3
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	ld	bc, 4:i3
	calr	62685
	calr	2498
	ld	wa, 2:i3
	calr	64055
SeMenu_ApplyPartEdit_Epilogue3:
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
	ld	wa, 0:i3
	calr	61624
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Skip
	ldib_erp 250, 2
	ld wa, 2:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp a, 251
	jr SeMenu_ApplyPartEdit_Join2
SeMenu_ApplyPartEdit_Skip:
	ldib_erp 250, 5
	ld wa, 5:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp a, 251
SeMenu_ApplyPartEdit_Join2:
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	SeMenu_ApplyPartEdit_Helper5
	stb_erp c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp a, 251
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "0807"
	calr	SeMenu_ApplyPartEdit_Helper2
	calr	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 3:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, SeMenu_ApplyPartEdit_Epilogue4
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 6:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 55
	ld	bc, 6:i3
	calr	62427
	calr	2240
	ld	wa, 4:i3
	calr	63797
SeMenu_ApplyPartEdit_Epilogue4:
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
	ld	wa, 0:i3
	calr	61366
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Skip2
	ldi_erpb 250, 10
	ldw wa, 10
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp a, 251
	jr SeMenu_ApplyPartEdit_Join3
SeMenu_ApplyPartEdit_Skip2:
	ldib_erp 250, 7
	ld wa, 7:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp a, 251
SeMenu_ApplyPartEdit_Join3:
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	SeMenu_ApplyPartEdit_Helper5
	stb_erp c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp a, 251
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 55
	calr	SeMenu_ApplyPartEdit_Helper2
	calr	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 5:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, SeMenu_ApplyPartEdit_Epilogue5
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ldw	wa, 8
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "0807"
	ldw	bc, 8
	calr	62165
	calr	1978
	ld	wa, 6:i3
	calr	63535
SeMenu_ApplyPartEdit_Epilogue5:
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
	ld	wa, 0:i3
	calr	61104
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Skip3
	ldib_erp 250, 1
	ld wa, 1:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 255
	ld	(xwa+7), 0
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	a, (xsp+20)
	ldb_erp a, 251
	jr SeMenu_ApplyPartEdit_Join4
SeMenu_ApplyPartEdit_Skip3:
	ldi_erpb 250, 9
	ldw wa, 9
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	a, (xsp+18)
	ldb_erp a, 251
SeMenu_ApplyPartEdit_Join4:
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+12)
	calr	SeMenu_ApplyPartEdit_Helper5
	stb_erp c, 250
	extz	bc
	ld	e, (xsp+14)
	extz	de
	stb_erp a, 251
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "0807"
	calr	SeMenu_ApplyPartEdit_Helper2
	calr	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 7:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	pop qiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080)"
	ld	bc, 3:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	calr	60891
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	60867
	ld	wa, 2:i3
	ld	bc, 1:i3
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
	ld	bc, 0:i3
	calr	60837
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	calr	63231
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080)"
	ld	bc, 4:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	SeMenu_StorePartParam
	ld	wa, 2:i3
	ld	bc, 1:i3
	calr	SeMenu_ApplyPartEdit_Helper11
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	SeMenu_LoadPartParam
	cp	(xsp+12), 1
	jr	z, SeMenu_ApplyPartEdit_Skip4
	ldw	wa, 9
	ld	bc, 1:i3
	calr	SeMenu_StorePartParam
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_ApplyPartEdit_Skip4:
	ld	wa, 3:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), c
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 5:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+14)
	extz	de
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080)"
	ld	bc, 5:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	lda	xbc, (xsp+12)
	ld	wa, 5:i3
	calr	60603
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	calr	60579
	ld	wa, 2:i3
	ld	bc, 1:i3
	calr	3000
	lda	xbc, (xsp+12)
	ldw	wa, 9
	calr	60576
	.byte 0x8f
	incf
	push	xsp
	push	sr
	jr	z, 20
	ldw	wa, 9
	ld	bc, 2:i3
	calr	60549
	pushw	9
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 4:i3
	calr	62943
	lda	xsp, (xsp+20)
	ret
	dec	6, xsp
	ld	(xsp+4), c
	extz	wa
	pushw	127
	ld	bc, 2:i3
	ld	de, 0:i3
	calr	SeMenu_ApplyPartEdit_Helper13
	cp	l, 1:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip5
	lda	xwa, (xsp+2)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp)
	pushw	127
	calr	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	41
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	ld	bc, 1:i3
	calr	SeMenu_ApplyPartEdit_Helper11
SeMenu_ApplyPartEdit_Skip5:
	ld	wa, 5:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	inc	6, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080)"
	ld	bc, 0:i3
	calr	SeMenu_ApplyPartEdit_Helper2
	ld	wa, 7:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+14), c
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	calr	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	e, (xsp+12)
	extz	de
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 41
	ld	bc, 1:i3
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
	ld	wa, 0:i3
	calr	60269
	lda	xbc, (xsp+18)
	ld	a, (xbc)
	ldb_erp a, 251
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
	jr	nz, SeMenu_ApplyPartEdit_Skip6
	ld	(xwa), 27
	jr	SeMenu_ApplyPartEdit_Join5
SeMenu_ApplyPartEdit_Skip6:
	ld	(xwa), 3
SeMenu_ApplyPartEdit_Join5:
	ld	(xbc+9), 0
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xbc+10)
	calr	SeMenu_ApplyPartEdit_Helper5
	lda	xwa, (xsp+2)
	calr	SeMenu_TransferPartValues_EndData_Helper
	cp	l, 0:i3
	jr	z, SeMenu_ApplyPartEdit_Epilogue6
	stb_erp a, 251
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	calr	SeMenu_StorePartParam
	stb_erp a, 251
	extz	wa
	.byte 0x8f
	ex_ff
	push	xsp
	push	sr
	jr	nz, SeMenu_ApplyPartEdit_Entry
	pushw	wa
	pushw	59
	jr	SeMenu_ApplyPartEdit_Join6
SeMenu_ApplyPartEdit_Entry:
	.byte 0x8f
	ex_ff
	push	xsp
	pop	sr
	jr	nz, SeMenu_ApplyPartEdit_Skip7
	pushw	wa
	pushw	60
SeMenu_ApplyPartEdit_Join6:
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_ApplyPartEdit_Skip7:
	lda	xbc, (xsp+16)
	ldw	wa, 13
	calr	SeMenu_LoadPartParam
	incm8	1, (xsp+16)
	lda	xbc, (xsp+2)
	ld	a, (xbc+6)
	extz	wa
	ld	c, (xbc+7)
	extz	bc
	calr	SeMenu_BitShiftMask
	ld	c, (xsp+16)
	extz	bc
	extz	hl
	lda	xde, (xsp+5)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Skip8
	pushw	hl
	ld	wa, 0:i3
	calr	SeMenu_RegisterElement_Extended
	jr	SeMenu_ApplyPartEdit_Join7
SeMenu_ApplyPartEdit_Skip8:
	pushw	hl
	ld	wa, 3:i3
	calr	SeMenu_SetupDisplayObject_Alt1
SeMenu_ApplyPartEdit_Join7:
	ld	wa, 2:i3
	calr	SeMenu_ApplyPartEdit_Helper4
SeMenu_ApplyPartEdit_Epilogue6:
	pop qiz
	lda	xsp, (xsp+24)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	ldw	wa, 13
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp)
	calr	SeMenu_ApplyPartEdit_Helper5
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp)
	exts	bc
	calr	SeMenu_ApplyPartEdit_Helper
	ld	wa, 4:i3
	calr	SeMenu_ApplyPartEdit_Helper4
	inc	6, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	res	7, c
	cp	c, 0:i3
	scc8	nz, c
	ld	a, (xsp)
	extz	wa
	extz	bc
	calr	SeMenu_ApplyPartEdit_Helper3
	ld	a, (xsp)
	inc	4, a
	extz	wa
	calr	SeMenu_ApplyPartEdit_Helper4
	inc	2, xsp
	ret
	lda	xsp, (xsp-22)
	push	xiz
	pushw	144
	pushw	256
	pushw	59
	pushw	51
	call	SeMenu_ShowConfirmDialog_Data_0x1BF
	inc	8, xsp
	lda	xbc, (xsp+18)
	ld	wa, 2:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+19)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+20)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+21)
	ld	wa, 5:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+22)
	ld	wa, 6:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+24)
	calr	SeMenu_LoadObjEntries
	lda	xbc, (xsp+16)
	.byte 0x8f
	push_f
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Skip9
	ld	wa, 0:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+17)
	ld	wa, 1:i3
	calr	SeMenu_LoadPartParam
	jr	33
SeMenu_ApplyPartEdit_Skip9:
	ld	wa, 1:i3
	calr	59909
	ld	(xsp+17), 100
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
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
SeMenu_ApplyPartEdit_Loop:
	ld	l, (xwa)
	res	7, l
	ld	(xwa), l
	cp	l, 100
	jr	ule, 3
	ld	(xwa), 100
	inc	1, xwa
	cp	xwa, xde
	jr	ule, SeMenu_ApplyPartEdit_Loop
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
	ld	xwa, 0x275004bf
	jr	ov, -51
	xor	(xsp), xhl
	ccf
	cp	hl, 0:i3
	jr	nz, 12
	.byte 0x9f, 0x04
	push	xwa
	rcf
	ld	l, 191:opc
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
	jr	c, SeMenu_ApplyPartEdit_Skip10
	ld	hl, (xsp+10)
	.byte 0x9f, 0x06, 0xa3
	ld	wa, (xsp+8)
	mul	xwa, xhl
	ld	(xsp+8), wa
	jr	14
SeMenu_ApplyPartEdit_Skip10:
	ld	hl, (xsp+6)
	.byte 0x9f
	ldw	(163:8), 2207:io
	ld	w, 219:opc
	ld	xwa, 0x275008bf
	jr	ov, -51
	xor	(xsp), xhl
	ccf
	cp	hl, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip11
	.byte 0x9f
	ld	(56:8), 16:io
	ld	l, 159:opc
	.byte 0x06
	ld	w, 191:opc
	ldw	(80:8), 2664:io
SeMenu_ApplyPartEdit_Skip11:
	ld	wa, (xsp+8)
	extz	xwa
	div	xwa, xhl
	ld	(xsp+8), wa
	ld	a, (xbc+5)
	extz	wa
	ld qiz, wa
	mul	wa, 87
	ld qiz, wa
	extz	xwa
	div	wa, 100
	ld qiz, wa
	ld	e, (xbc+4)
	ldb_erp e, 248
	extz	iz
	.byte 0xd7
	swi	2
	.byte 0x88, 0x9f
	ldw	(240:8), 3687:io
	.byte 0xd7
	swi	2
	.byte 0x8b, 0x9f
	ldw	(163:8), 0x88de:io
	mul	xwa, xhl
	ld	iz, wa
	jr	12
	ld	hl, (xsp+10)
	sub hl, qiz
	ld wa, iz
	mul	xwa, xhl
	ld	iz, wa
	ld	l, 100:opc
	sub	l, e
	extz	hl
	cp	hl, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip12
	add	iz, 0x2710
	ld	wa, (xsp+10)
	ld qiz, wa
	jr	SeMenu_ApplyPartEdit_Join8
SeMenu_ApplyPartEdit_Skip12:
	ld	wa, iz
	extz	xwa
	div	xwa, xhl
	ld	iz, wa
SeMenu_ApplyPartEdit_Join8:
	ld	c, (xbc+6)
	ld	e, c
	extz	de
	mul de, qiz
	ld l, 100:opc
	sub l, c
	extz	hl
	cp	hl, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip13
	add	de, 0x2710
	jr	SeMenu_ApplyPartEdit_Join9
SeMenu_ApplyPartEdit_Skip13:
	extz	xde
	div	xde, xhl
SeMenu_ApplyPartEdit_Join9:
	ld	bc, (xsp+4)
	.byte 0x9f
	ld	(129:8), 222:io
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
	ldw	hl, 0x9f00
	ld	(32:8), 232:io
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
	ld	(134:8), 48:io
	.byte 0x92
	nop
	.byte 0x9f, 0x06, 0xa0
	ld	(xsp+6), wa
	ldw	wa, 146
	.byte 0x9f
	ldw	(160:8), 2751:io
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
	cp	bc, 0:i3
	jr	nz, 58
	.byte 0x9f
	ldw	(4:8), 1695:io
	ld	w, 159:opc
	ld	(33:8), 159:io
	ldw	(34:8), 0x6a1e:io
	nop
	ld	bc, hl
	cp	bc, 0:i3
	jr	nz, 37
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	wa, (xsp+10)
	ld	bc, (xsp+12)
	ld	de, iz
	calr	86
	ld	bc, hl
	cp	bc, 0:i3
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
	ld	a, 100:opc
	sub	a, l
	ld	l, a
	extz	hl
	cp	hl, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip14
	add	de, 0x2710
	jr	SeMenu_ApplyPartEdit_Join10
SeMenu_ApplyPartEdit_Skip14:
	extz	xde
	div	xde, xhl
SeMenu_ApplyPartEdit_Join10:
	ld	l, (xsp+12)
	extz	hl
	extz	xde
	div	xde, xhl
	add	de, 213
	pushw	146
	ldw	wa, 214
	calr	SeMenu_ApplyPartEdit_Helper6
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SeMenu_ApplyPartEdit_Helper6:
	pushw	iz
	ld	iz, 0:i3
	ld	ix, bc
	ld	iy, (xsp+6)
	ld	hl, iy
	sub	hl, ix
	cp	wa, 213
	jr	nc, SeMenu_ApplyPartEdit_Skip15
	cp	de, 213
	jr	ule, SeMenu_ApplyPartEdit_Skip16
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
	jr	SeMenu_ApplyPartEdit_Join11
SeMenu_ApplyPartEdit_Skip15:
	dec	1, wa
	cp	de, 258
	jr	ule, SeMenu_ApplyPartEdit_Skip16
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
SeMenu_ApplyPartEdit_Join11:
	ld	iz, iy
SeMenu_ApplyPartEdit_Skip16:
	pushw	iy
	calr	SeMenu_ApplyPartEdit_Helper9
	ld	hl, iz
	popw	iz
	retd	2
SeMenu_ApplyPartEdit_Helper7:
	lda	xsp, (xsp-32)
	push	xiz
	pushw	144
	pushw	256
	pushw	59
	pushw	51
	call	SeMenu_ShowConfirmDialog_Data_0x1BF
	inc	8, xsp
	lda	xbc, (xsp+30)
	ld	wa, 3:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+31)
	ld	wa, 5:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+32)
	ld	wa, 7:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+33)
	ldw	wa, 9
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+30)
	ld	xwa, xbc
	inc	4, xbc
SeMenu_ApplyPartEdit_Loop2:
	ld	e, (xwa)
	res	7, e
	ld	(xwa), e
	cp	e, 100
	jr	ule, SeMenu_ApplyPartEdit_Skip17
	ld	(xwa), 100
SeMenu_ApplyPartEdit_Skip17:
	inc	1, xwa
	cp	xwa, xbc
	jr	c, SeMenu_ApplyPartEdit_Loop2
	lda	xbc, (xsp+22)
	ld	wa, 2:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+22)
	calr	SeMenu_ApplyPartEdit_Helper8
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
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+23)
	calr	SeMenu_ApplyPartEdit_Helper8
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
	ld	wa, 2:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+23)
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+22)
	ld	a, (xbc+1)
	.byte 0x81
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	SeMenu_ApplyPartEdit_Helper12
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+8), wa
	ld	c, (xsp+30)
	ld	e, c
	extz	de
	ld	wa, (xsp+8)
	muls	xwa, xde
	ld	(xsp+8), wa
	ld	a, 100:opc
	sub	a, c
	ld	c, a
	cp	c, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip18
	.byte 0x9f
	ld	(56:8), 16:io
	ld	l, 159:opc
	.byte 0x06
	ld	w, 191:opc
	ldw	(80:8), 3176:io
SeMenu_ApplyPartEdit_Skip18:
	extz	bc
	ld	wa, (xsp+8)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+8), wa
	lda	xbc, (xsp+24)
	ld	wa, 6:i3
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+24)
	calr	SeMenu_ApplyPartEdit_Helper8
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
	ld	wa, 4:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+24)
	ld	wa, 6:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+22)
	ld	a, (xbc+2)
	.byte 0x89, 0x01
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	SeMenu_ApplyPartEdit_Helper12
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+12), wa
	ld	c, (xsp+31)
	ld	e, c
	extz	de
	ld	wa, (xsp+12)
	muls	xwa, xde
	ld	(xsp+12), wa
	ld	a, 100:opc
	sub	a, c
	ld	c, a
	cp	c, 0:i3
	jr	nz, 13
	.byte 0x9f
	incf
	push	xwa
	rcf
	ld	l, 159:opc
	ldw	(32:8), 3775:io
	.byte 0x50
	jr	12
	extz	bc
	ld	wa, (xsp+12)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+12), wa
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+25)
	calr	SeMenu_ApplyPartEdit_Helper8
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
	ld	wa, 6:i3
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+25)
	ldw	wa, 8
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+22)
	ld	a, (xbc+3)
	.byte 0x89
	push	sr
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	SeMenu_ApplyPartEdit_Helper12
	ld	a, (xsp+28)
	extz	wa
	ld	(xsp+16), wa
	ld	c, (xsp+32)
	ld	e, c
	extz	de
	ld	wa, (xsp+16)
	muls	xwa, xde
	ld	(xsp+16), wa
	ld	a, 100:opc
	sub	a, c
	ld	c, a
	cp	c, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip19
	.byte 0x9f
	rcf
	push	xwa
	rcf
	ld	l, 159:opc
	ret
	ld	w, 191:opc
	ccf
	.byte 0x50
	jr	SeMenu_ApplyPartEdit_Join12
SeMenu_ApplyPartEdit_Skip19:
	extz	bc
	ld	wa, (xsp+16)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+16), wa
SeMenu_ApplyPartEdit_Join12:
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+26)
	calr	SeMenu_ApplyPartEdit_Helper8
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
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+26)
	ldw	wa, 10
	calr	SeMenu_LoadPartParam
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89
	pop	sr
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	SeMenu_ApplyPartEdit_Helper12
	ld	a, (xsp+28)
	extz	wa
	ld qiz, wa
	ld c, (xsp+33)
	ld e, c
	extz	de
	ld wa, qiz
	muls	xwa, xde
	ld qiz, wa
	ld a, 100:opc
	sub	a, c
	ld	c, a
	cp	c, 0:i3
	jr	nz, 13
	.byte 0xd7
	swi	2
	.byte 0xc8
	rcf
	ld	l, 159:opc
	ccf
	ld	w, 191:opc
	push_a
	.byte 0x50
	jr	12
	extz	bc
	ld wa, qiz
	exts	xwa
	divs	xwa, xbc
	ld qiz, wa
	ld	wa, (xsp+8)
	.byte 0x9f
	incf
	.byte 0x80, 0x9f
	rcf
	xor	(xwa), w
	.byte 0x89
	extz	xbc
	div	bc, 162
	ld wa, qiz
	extz	xwa
	div	wa, 45
	cp	bc, 5:i3
	jr	ule, 2
	ld	bc, 5:i3
	cp	wa, 5:i3
	jr	ule, 2
	ld	wa, 5:i3
	cp	bc, wa
	jr	c, SeMenu_ApplyPartEdit_Skip20
	ld	(xsp+4), c
	jr	SeMenu_ApplyPartEdit_Join13
SeMenu_ApplyPartEdit_Skip20:
	ld	(xsp+4), a
SeMenu_ApplyPartEdit_Join13:
	incm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, (xsp+8)
	exts	xwa
	divs	xwa, xbc
	ld	(xsp+8), wa
	.byte 0x9f
	ld	(56:8), 51:io
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
	ldw	(160:8), 2751:io
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
	calr	SeMenu_ApplyPartEdit_Helper6
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip21
	ld	wa, (xsp+8)
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	ld	hl, (xsp+14)
	pushw	hl
	calr	SeMenu_ApplyPartEdit_Helper6
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip21
	ld	wa, (xsp+12)
	ld	bc, (xsp+14)
	ld	de, (xsp+16)
	ld	hl, (xsp+18)
	pushw	hl
	calr	SeMenu_ApplyPartEdit_Helper6
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, SeMenu_ApplyPartEdit_Skip21
	ld	wa, (xsp+16)
	ld	bc, (xsp+18)
	pushw	bc
	ldw	de, 213
	calr	SeMenu_ApplyPartEdit_Helper6
	ld	iz, (xsp+18)
SeMenu_ApplyPartEdit_Skip21:
	lda	xbc, (xsp+22)
	ldw	wa, 96
	sub	wa, iz
	ld	(xbc+3), a
	inc	4, xbc
	ldw	wa, 10
	calr	SeMenu_LoadPartParam
	lda	xwa, (xsp+26)
	calr	SeMenu_ApplyPartEdit_Helper8
	lda	xbc, (xsp+22)
	ld	a, (xbc+4)
	.byte 0x89
	pop	sr
	xor	(xbc), xwa
	zcf
	lda	xbc, (xsp+28)
	calr	SeMenu_ApplyPartEdit_Helper12
	ld	a, (xsp+28)
	extz	wa
	ld qiz, wa
	ld c, (xsp+33)
	ld e, c
	extz	de
	ld wa, qiz
	muls	xwa, xde
	ld qiz, wa
	ld a, 100:opc
	sub	a, c
	ld	c, a
	cp	c, 0:i3
	jr	nz, 13
	.byte 0xd7
	swi	2
	.byte 0xc8
	rcf
	ld	l, 159:opc
	ccf
	ld	w, 191:opc
	push_a
	.byte 0x50
	jr	12
	extz	bc
	ld wa, qiz
	exts	xwa
	divs	xwa, xbc
	ld qiz, wa
	ld	c, (xsp+4)
	extz	bc
	ld wa, qiz
	exts	xwa
	divs	xwa, xbc
	.byte 0xd7
	swi	2
	cp	(xwa-41), de
	xor	e, w
	nop
	ld de, qiz
	ld	wa, (xsp+20)
	pushw	wa
	ldw	wa, 214
	ld	bc, iz
	calr	64370
	cp	hl, 0:i3
	jr	nz, 16
	inc 1, qiz
	ld wa, qiz
	ld	bc, (xsp+20)
	pushw	bc
	ldw	de, 258
	calr	SeMenu_ApplyPartEdit_Helper6
	pop	xiz
	lda	xsp, (xsp+32)
	ret
SeMenu_ApplyPartEdit_Helper8:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	lda	xwa, (xsp+4)
	calr	SeMenu_LoadRawAddr
	.byte 0x86
	push	xsp
	ldw	de, 866
	ld	(xiz), 50
	.byte 0x86
	push	xsp
	dec	1, h
	pop	sr
	ld	(xiz), 206
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	calr	SeMenu_LoadPartParam
	ld	e, (xiz)
	exts	de
	.byte 0x8f, 0x04
	.ascii "?7f%"
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	lt, SeMenu_ApplyPartEdit_Skip22
	ld	c, (xsp+6)
	exts	bc
	muls	xde, xbc
	jr	SeMenu_ApplyPartEdit_Join14
SeMenu_ApplyPartEdit_Skip22:
	ld	c, (xsp+6)
	neg	c
	ld	(xsp+6), c
	exts	bc
	muls	xde, xbc
	neg	de
SeMenu_ApplyPartEdit_Join14:
	exts	xde
	divs	de, 50
	ld	(xiz), e
	pop	xiz
	inc	4, xsp
	ret
SeMenu_ApplyPartEdit_Helper9:
	lda	xsp, (xsp-10)
	pushw	iz
	ld	(xsp+6), de
	ld	(xsp+8), bc
	ld	(xsp+10), wa
	lda	xbc, (xsp+2)
	ld	wa, 1:i3
	calr	57972
	lda	xwa, (xsp+4)
	calr	55490
	ld	iz, (xsp+16)
	.byte 0x8f, 0x04
	push	xsp
	ldw sp, 6526
	normal
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
	ld	(63:8), 59:io
	nop
	jr	nc, 7
	ldw (xsp+8), 59
	jr	SeMenu_ApplyPartEdit_Join15
	.byte 0x9f
	ld	(63:8), 146:io
	nop
	jr	ule, SeMenu_ApplyPartEdit_Join15
	ldw (xsp+8), 146
SeMenu_ApplyPartEdit_Join15:
	cp	iz, 59
	jr	nc, SeMenu_ApplyPartEdit_Skip23
	ldw	iz, 59
	jrl	SeMenu_ApplyPartEdit_Join16
SeMenu_ApplyPartEdit_Skip23:
	cp	iz, 146
	jrl	ule, SeMenu_ApplyPartEdit_Join16
	ldw	iz, 146
	jrl	SeMenu_ApplyPartEdit_Join16
	.byte 0x9f
	ld	(63:8), 59:io
	nop
	jr	c, SeMenu_ApplyPartEdit_Entry2
	.byte 0x9f
	ld	(63:8), 146:io
	nop
	jr	ugt, SeMenu_ApplyPartEdit_Entry2
	cp	iz, 59
	jr	c, SeMenu_ApplyPartEdit_Entry2
	cp	iz, 146
	jrl	ule, SeMenu_ApplyPartEdit_Join16
SeMenu_ApplyPartEdit_Entry2:
	.byte 0x9f
	ld	(63:8), 59:io
	nop
	jr	nc, 7
	cp	iz, 59
	jrl	c, 177
	.byte 0x9f
	ld	(63:8), 146:io
	nop
	jr	ule, 7
	cp	iz, 146
	jrl	ugt, 163
	ld	wa, (xsp+6)
	.byte 0x9f
	ldw	(160:8), 2207:io
	swi	6
	jr	nc, 68
	cp	iz, 146
	jr	ule, 25
	ldw	bc, 146
	.byte 0x9f
	ld	(161:8), 222:io
	.byte 0x8a, 0x9f
	ld	(162:8), 30:io
	.byte 0x8b
	nop
	ld	wa, (xsp+10)
	add	wa, hl
	ld	(xsp+6), wa
	ldw	iz, 146
	.byte 0x9f
	ld	(63:8), 59:io
	nop
	jr	nc, 98
	ld	wa, (xsp+6)
	.byte 0x9f
	ldw	(160:8), 0x3b31:io
	nop
	.byte 0x9f
	ld	(161:8), 222:io
	.byte 0x8a, 0x9f
	ld	(162:8), 30:io
	jr	mi, 0
	add	(xsp+10), hl
	ldw (xsp+8), 59
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
	ld	(63:8), 146:io
	nop
	jr	ule, SeMenu_ApplyPartEdit_Join16
	ld	wa, (xsp+6)
	.byte 0x9f
	ldw	(160:8), 2207:io
	ld	a, 217:opc
	adc	b, b
	nop
	ld	de, (xsp+8)
	sub	de, iz
	calr	31
	add	(xsp+10), hl
	ldw (xsp+8), 146
SeMenu_ApplyPartEdit_Join16:
	pushw	iz
	.byte 0x9f
	ld	(4:8), 159:io
	incf
	.byte 0x04, 0x9f
	rcf
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0x7F
	inc	8, xsp
	popw	iz
	lda	xsp, (xsp+10)
	retd	2
	mul	xwa, xbc
	extz	xwa
	div	xwa, xde
	ld	hl, wa
	ret
SeMenu_ApplyPartEdit_Helper10:
	cp	a, 20
	jr	nc, SeMenu_ApplyPartEdit_Skip24
	ld	a, 20:opc
	jr	SeMenu_ApplyPartEdit_Join17
SeMenu_ApplyPartEdit_Skip24:
	cp	a, 108
	jr	ule, SeMenu_ApplyPartEdit_Join17
	ld	a, 108:opc
SeMenu_ApplyPartEdit_Join17:
	sub	a, 12
	ld	l, a
	extz	hl
	div	l, 12
	extz	wa
	div	a, 12
	ld	a, w
	extz	wa
	lda	xde, (GUI_DisplayStructData_0x1110:24)
	ld_rrb e, xde, wa
	mul l, 28
	add l, e
	sub l, 18
	extz	hl
	ld	(xbc), hl
	ret
SeMenu_ApplyPartEdit_Helper11:
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), c
	ld	(xsp+30), a
	pushw	121
	pushw	254
	pushw	73
	pushw	48
	call	SeMenu_ShowConfirmDialog_Data_0x1BF
	inc	8, xsp
	lda	xbc, (xsp+18)
	ldw	wa, 10
	calr	SeMenu_LoadPartParam
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
	ldw	wa, 0xbf00
	rcf
	push	sr
	ldw	wa, 0xbf00
	max
	push	sr
	ldw	wa, 0xbf00
	incf
	push	sr
	swi	6
	nop
	ldw (xsp+6), 254
	ld	wa, (xsp+14)
	sub	wa, 48
	ld	(xsp+8), wa
	ldw (xsp+10), 254
	ld	wa, (xsp+14)
	sub	(xsp+10), wa
	jrl	145
	calr	57468
	ld	a, (xsp+30)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+26)
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+30)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+22)
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+24)
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_ApplyPartEdit_Helper10
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
	ldw	wa, 0x9f00
	rcf
	push	xwa
	ldw	wa, 0x9f00
	incf
	push	xwa
	ldw	wa, 0x9f00
	rcf
	ld	w, 159:opc
	ret
	call_dd8 99
	ld	wa, (xsp+14)
	dec	1, wa
	ld	(xsp+16), wa
	ld	wa, (xsp+14)
	.byte 0x9f
	incf
	call_dd8 99
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
	jr	nz, SeMenu_ApplyPartEdit_Skip25
	pushw	97
	pushw	254
	pushw	97
	pushw	48
	call	SeMenu_DisplayPartValue_Data_0x7F
	pushw	121
	.byte 0x9f
	push_f
	.byte 0x04
	pushw	97
	.byte 0x9f, 0x1c, 0x04
	call	SeMenu_DisplayPartValue_Data_0xB6
	pushw	121
	.byte 0x9f
	ex_ff
	.byte 0x04
	pushw	97
	.byte 0x9f, 0x1a, 0x04
	call	SeMenu_DisplayPartValue_Data_0xB6
	lda	xsp, (xsp+24)
	pushw	121
	.byte 0x9f
	ld	(4:8), 11:io
	jr	lt, 0
	jrl	239
SeMenu_ApplyPartEdit_Skip25:
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
	ldw qiz, 97
	ld	bc, hl
	cp	(xsp+8), bc
	jr	ule, SeMenu_ApplyPartEdit_Entry3
	ldw	iz, 72
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	lt, SeMenu_ApplyPartEdit_Skip26
	ldw	iz, 122
SeMenu_ApplyPartEdit_Skip26:
	ld	wa, (xsp+14)
	sub	wa, hl
	ld	(xsp+16), wa
	jr	12
SeMenu_ApplyPartEdit_Entry3:
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
	pop	sr
	jrl	gt, -28928
	ccf
	push	xsp
	nop
	jr	lt, 5
	ldw qiz, 72
	ld	wa, (xsp+14)
	add	wa, hl
	ld	(xsp+12), wa
	jr	24
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	lt, SeMenu_ApplyPartEdit_Skip27
	ld wa, qiz
	sub	wa, de
	ld qiz, wa
	jr	8
SeMenu_ApplyPartEdit_Skip27:
	ld wa, qiz
	add	wa, de
	ld qiz, wa
	pushw	iz
	.byte 0x9f
	ccf
	.byte 0x04
	pushw	iz
	pushw	48
	call	SeMenu_DisplayPartValue_Data_0x7F
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
	ld	b, 4:opc
	call	SeMenu_DisplayPartValue_Data_0x7F
	pushw	121
	.byte 0x9f
	pushw	wa
	.byte 0x04
	pushw	97
	.byte 0x9f
	pushw	ix
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0xB6
	lda	xsp, (xsp+32)
	pushw	121
	.byte 0x9f
	ei	4
	pushw	iz
	.byte 0x9f
	ldw	(4:8), 0x331d:io
	cp	xwa, xiz
	inc	8, xsp
	pushw	121
	.byte 0x9f
	ld	(4:8), 215:io
	swi	2
	.byte 0x04, 0x9f
	incf
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0xB6
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+28)
	ret
SeMenu_ApplyPartEdit_Helper12:
	cp	a, 0:i3
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
	calr	SeMenu_IsPartEnabled
	cp	hl, 0:i3
	jrl	z, SeMenu_ApplyPartEdit_Epilogue7
	ld	a, (xsp+24)
	extz	wa
	add	wa, wa
	lda	xbc, (GUI_DisplayStructData_0x111D:24)
	ld_rrw wa, xbc, wa
	ld (xsp), wa
	ldw (xsp+2), 20
	.byte 0x8f, 0x1a
	push	xsp
	nop
	jr	nz, SeMenu_ApplyPartEdit_Entry4
	.byte 0xbf, 0x04
	push	sr
	ld	l, 0:opc
	ldw	wa, 247
	jr	SeMenu_ApplyPartEdit_Entry5
SeMenu_ApplyPartEdit_Entry4:
	.byte 0xbf, 0x04
	push	sr
	ldw	wa, 0x3000
	.byte 0xf1
	nop
SeMenu_ApplyPartEdit_Entry5:
	.byte 0x97, 0x04
	pushw	wa
	ld	wa, (xsp+4)
	.byte 0x9f, 0x06, 0xa0
	pushw	wa
	.byte 0x9f
	ldw	(4:8), 0x491d:io
	ld	(0xeff0:16), xwa
	ld	a, (xsp+22)
	extz	wa
	lda	xbc, (xsp+18)
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+22)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+20)
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+22)
	inc	2, a
	extz	wa
	lda	xbc, (xsp+16)
	calr	SeMenu_LoadPartParam
	ld	a, (xsp+22)
	inc	3, a
	extz	wa
	lda	xbc, (xsp+14)
	calr	SeMenu_LoadPartParam
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
	jr	nz, SeMenu_ApplyPartEdit_Skip28
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	calr	SeMenu_ApplyPartEdit_Helper10
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+10)
	calr	SeMenu_ApplyPartEdit_Helper10
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xsp+8)
	calr	SeMenu_ApplyPartEdit_Helper10
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xsp+6)
	calr	SeMenu_ApplyPartEdit_Helper10
	jr	SeMenu_ApplyPartEdit_Join18
SeMenu_ApplyPartEdit_Skip28:
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
SeMenu_ApplyPartEdit_Join18:
	ld	wa, (xsp+4)
	add	(xsp+12), wa
	add	(xsp+10), wa
	add	(xsp+8), wa
	add	(xsp+6), wa
	ld	wa, (xsp)
	.byte 0x9f
	push	sr
	.byte 0xa0
	pushw	wa
	.byte 0x9f
	incf
	.byte 0x04, 0x9f, 0x04, 0x04, 0x9f
	ccf
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0x7F
	ld	wa, (xsp+8)
	.byte 0x9f
	ldw	(160:8), 0x9f28:io
	ccf
	max
	pushw	wa
	.byte 0x9f
	push_f
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0x7F
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
SeMenu_ApplyPartEdit_Epilogue7:
	lda	xsp, (xsp+28)
	ret
	dec	8, xsp
	ld	(xsp+2), e
	ld	(xsp+4), c
	ld	(xsp+6), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	calr	56572
	ld	a, (xsp+4)
	.byte 0x87, 0xf1
	jr	z, 56
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	nz, 12
	ld	a, (xsp+4)
	extz	wa
	calr	56503
	cp	hl, 0:i3
	jr	z, 38
	ld	a, (xsp+4)
	extz	wa
	calr	56263
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	calr	SeMenu_StorePartParam
	pushw	0
	ld	a, (xsp+8)
	extz	wa
	pushw	wa
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 1:i3
	calr	SeMenu_SetupMenuDisplay
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), c
	ld	(xsp+18), a
	.byte 0xbf, 0x04
	push	sr
	popw	iy
	nop
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 5
	.byte 0xbf, 0x04
	push	sr
	pushw	wa
	nop
	lda	xbc, (xsp+14)
	ld	wa, 2:i3
	calr	56472
	.byte 0xbf
	ret
	.byte 0xb7
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
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
	ldw (xsp+8), 26
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
	ldw	(166:8), 1695:io
	max
	pushw	232
	.byte 0x9f
	ld	(4:8), 11:io
	ld	xhl, 0xf1491d00
	.byte 0xf0
	inc	8, xsp
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	nz, 115
	.byte 0x9f
	ld	(4:8), 215:io
	swi	2
	and	(xwa-40), b
	ldw	(0:8), 0x9f28:io
	incf
	.byte 0x04
	pushw	67
	call	SeMenu_DisplayPartValue_Data_0x7F
	.byte 0x9f
	ccf
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04, 0x9f
	push_a
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), b
	ldw	(0:8), 7464:io
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
	add bc, qiz
	ld	wa, (xsp+6)
	jr	10
	ldw	bc, 232
	ld	wa, de
	add	wa, wa
	.byte 0x9f
	ldw	(128:8), 0x2928:io
	.byte 0x9f
	ret
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	jr	116
	.byte 0xd7
	swi	2
	and	(xde-38), b
	ld	xhl, 0x3f108f00
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
	ldw	(128:8), 2719:io
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	pushw	wa
	pushw	bc
	call	SeMenu_DisplayPartValue_Data_0x7F
	.byte 0x9f
	rcf
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), w
	ldw	(0:8), 0x9f28:io
	ex_ff
	.byte 0x04, 0xd7
	swi	2
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0x7F
	lda	xsp, (xsp+16)
	.byte 0x9f
	ld	(4:8), 11:io
	.byte 0xe8
	nop
	.byte 0x9f
	incf
	.byte 0x04, 0xd7
	swi	2
	and	(xwa-40), w
	ldw	(0:8), 7464:io
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
	call	SeMenu_DisplayPartValue_Data_0xB6
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	lda	xbc, (xsp+14)
	ld	wa, 4:i3
	calr	56070
	.byte 0xbf
	ret
	.byte 0xb7
	lda	xbc, (xsp+12)
	ld	wa, 5:i3
	calr	56059
	lda	xbc, (xsp+10)
	ld	wa, 5:i3
	calr	56051
	ld	wa, 1:i3
	ld	bc, 7:i3
	calr	56060
	ld	(xsp+4), l
	.byte 0xbf
	incf
	.byte 0xb7, 0xbf
	ei	2
	.byte 0xab
	nop
	ldw (xsp+8), 26
	.byte 0x9f
	ld	(56:8), 118:io
	nop
	ld	a, (xsp+14)
	extz	wa
	add	wa, 86
	ld qiz, wa
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
	call	SeMenu_ShowConfirmDialog_Data_0x1BF
	inc	8, xsp
	ld	a, (xsp+10)
	.byte 0x8f, 0x04, 0xc1
	jr	z, 49
	.byte 0x9f
	ld	(4:8), 215:io
	swi	2
	decm8	6, (xwa-40)
	pushw	wa
	.byte 0x9f
	incf
	.byte 0x04
	pushw	67
	call	SeMenu_DisplayPartValue_Data_0x7F
	pushw	iz
	.byte 0xd7
	swi	2
	.byte 0x04, 0x9f
	push_a
	.byte 0x04, 0xd7
	swi	2
	decm8	6, (xwa-40)
	pushw	wa
	call	SeMenu_DisplayPartValue_Data_0x7F
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
	call	SeMenu_DisplayPartValue_Data_0x7F
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
	call	SeMenu_DisplayPartValue_Data_0x7F
	lda	xsp, (xsp+16)
	.byte 0x9f, 0x08
	.long NakaInst_data_E80B04
	.byte 0x9f
	incf
	.byte 0x04, 0xd7
	swi	2
	incm8	6, (xwa-40)
	pushw	wa
	call	SeMenu_DisplayPartValue_Data_0x7F
	inc	8, xsp
	.byte 0x9f
	ei	4
	push	xiz
	.byte 0xd7
	swi	2
	.byte 0x04
	call	SeMenu_DisplayPartValue_Data_0xB6
	inc	8, xsp
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-22)
	push	xiz
	lda	xbc, (xsp+24)
	ld	wa, 2:i3
	calr	55830
	.byte 0xbf
	push_f
	.byte 0xb7
	lda	xbc, (xsp+22)
	ld	wa, 3:i3
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
	ld	wa, 4:i3
	calr	55797
	.byte 0xbf
	push_a
	.byte 0xb7
	lda	xbc, (xsp+18)
	ld	wa, 5:i3
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
	ldw (xsp+6), 130
	ldw (xsp+10), 26
	.byte 0x9f
	ldw	(56:8), 77:io
	ld	a, (xsp+24)
	ldb_erp a, 248
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
	ldw qiz, 130
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
	ldw (xsp+16), 130
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
	call	SeMenu_ShowConfirmDialog_Data_0x1BF
	inc	8, xsp
	ld	bc, iz
	sub	bc, 67
	ld wa, qiz
	cp	wa, bc
	jr	ugt, 10
	ld	de, iz
	sub de, qiz
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
	call	SeMenu_DisplayPartValue_Data_0x7F
	inc	8, xsp
	.byte 0x8f, 0x04
	push	xsp
	normal
	jr	nz, 12
	.byte 0x9f
	ret
	.byte 0x04, 0x9f
	ldw	(4:8), 4255:io
	.byte 0x04
	pushw	iz
	jr	63
	.byte 0x9f
	ldw	(4:8), 0x88de:io
	add	wa, 10
	pushw	wa
	.byte 0x9f
	rcf
	.byte 0x04
	pushw	iz
	call	SeMenu_DisplayPartValue_Data_0x7F
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
	call	SeMenu_DisplayPartValue_Data_0x7F
	lda	xsp, (xsp+16)
	.byte 0x9f
	ret
	.byte 0x04, 0x9f
	ldw	(4:8), 3743:io
	.byte 0x04
	ld	wa, (xsp+14)
	sub	wa, 10
	pushw	wa
	call	SeMenu_DisplayPartValue_Data_0x7F
	inc	8, xsp
	ldw	bc, 232
	.byte 0x9f
	ld	(161:8), 159:io
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
	call	SeMenu_DisplayPartValue_Data_0x7F
	.byte 0x9f
	ret
	.byte 0x04
	pushw	iz
	.byte 0x9f
	push_f
	.byte 0x04
	pushw	iz
	call	SeMenu_DisplayPartValue_Data_0xB6
	.byte 0x9f
	ex_ff
	.byte 0x04, 0x9f, 0x1a, 0x04, 0x9f
	ld	b, 4:opc
	.byte 0x9f
	calr	7428
	ldw	hl, 0xf0ee
	lda	xsp, (xsp+24)
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	lda	xde, (1698:16)
	st_rrw bc, xde, wa
	ret
	dec	1, a
	extz	wa
	add	wa, wa
	lda	xde, (1698:16)
	ld_rrw wa, xde, wa
	ld (xbc), wa
	ret
	ld	(1706:16), wa
	ret
	.byte 0xb0
	ex_ff
	.byte 0xaa, 0x06
	ret
	ld	(1708:16), a
	ret
	.byte 0xb0
	push_a
	.byte 0xac, 0x06
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
	ld wa, 1:i3
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
	cp	a, 1:i3
	jr	nz, 6
	ldi_erpb 250, 12
	jr	12
	ldi_erpb 250, 18
	cp	a, 3:i3
	jr	nz, 4
	ldi_erpb 250, 17
	ld	iz, 0:i3
	.byte 0xc7
	swi	3
	.byte 0xa8, 0x8f
	ldw	(63:8), 0x6300:io
	ld	w, 199:opc
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
	ldw	(241:8), 0xe067:io
	ld	xwa, (xsp+6)
	ld	(xwa), iz
	pop	xiz
	inc	8, xsp
	ret
	dec	2, xsp
	push	xiz
	ld	xiz, xde
	lda	xde, (xsp+4)
	cp	a, 3:i3
	jr	nz, 11
	add	c, 14
	extz	bc
	ld	wa, bc
	ld	xbc, xde
	jr	SeMenu_ApplySynthParam_Data_Join
	cp	a, 1:i3
	jr	nz, SeMenu_ApplySynthParam_Data_Skip
	inc	7, c
	extz	bc
	ld	wa, bc
	ld	xbc, xde
	jr	SeMenu_ApplySynthParam_Data_Join
SeMenu_ApplySynthParam_Data_Skip:
	add	c, 13
	extz	bc
	ld	wa, bc
	ld	xbc, xde
SeMenu_ApplySynthParam_Data_Join:
	calr	SeMenu_LoadPartParam
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
	ld wa, 1:i3
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
	ld bc, 0:i3
	ld de, 0:i3
	call SndParam_UpdateChannelTuning
	ld (xiz), l
	ld a, (xsp + 8)
	extz wa
	ld bc, 0:i3
	ld de, 1:i3
	call SndParam_UpdateChannelTuning
	ld xwa, (xsp + 10)
	ld (xwa), l
	cp (xiz), 0xff
	jr nz, SeMenu_SetupSoundBankPair_CheckValid
	ld a, (xsp + 8)
	extz wa
	ld bc, 1:i3
	ld de, 1:i3
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
	ld wa, 0:i3
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
SeMenu_ComputeParamTableAddr_Loop:
	ldb_spi a, 232
	lda_dpi xbc, 228
	cp xde, xhl
	jr c, SeMenu_ComputeParamTableAddr_Loop
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
	ld wa, 0:i3
	ld bc, 0:i3
	ldw de, 0xa
	calr SeMenu_RegisterElement_Type2
	ld wa, 1:i3
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
	ld wa, 0:i3
	ld bc, 0:i3
	ldw de, 0xa
	calr SeMenu_RegisterElement_Type2
	jr SeMenu_HandleMenuChange_End

SeMenu_HandleMenuChange_Overflow:
	ld wa, 0:i3
	calr SeMenu_SetCurrentStep
	calr SeMenu_ResetSubIndex
	ldw wa, 0x98
	ld bc, 0:i3
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
	calr	SeMenu_LoadMasterPtr
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
SeMenu_ApplyPartEdit_Helper13:
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
	cp	a, 0:i3
	jr	nz, 116
	.byte 0x8f, 0x04
	push	xsp
	jrl	nc, 31855
	ld	a, (xsp+4)
	cp	a, (xsp+16)
	jr	nc, 116
SeMenu_PatchBank_Data_Entry:
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
	jr	ule, SeMenu_PatchBank_Data_Skip
	ld	a, (xsp+16)
	ld	(xsp+4), a
SeMenu_PatchBank_Data_Skip:
	ld	a, (xsp)
	or	(xsp+4), a
	ld	a, (xsp+8)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	calr	SeMenu_StorePartParam
	ld	l, 1:opc
	jr	SeMenu_PatchBank_Data_Epilogue
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, SeMenu_PatchBank_Data_Skip2
	ld	a, (xsp+4)
	.byte 0x8f, 0x06, 0xf1
	jr	ugt, SeMenu_PatchBank_Data_Entry
SeMenu_PatchBank_Data_Skip2:
	ld	l, 0:opc
SeMenu_PatchBank_Data_Epilogue:
	lda	xsp, (xsp+12)
	retd	2

SeMenu_SetEditEnable:
	cp a, 1:i3
	jr nz, SeMenu_SetEditEnable_Clear
	set 2, (0x28a7:16)
	ret

SeMenu_SetEditEnable_Clear:
	res 2, (0x28a7:16)
	ret

SeMenu_OrPartConfig:
	or (0x0205f2:24), a
	ret

SeMenu_OrPartConfig_Data:
	.long Pad_BeforeBitmap_Dredt0d
	chgm	2, (xhl+14)
	and	(0x2700e3:24), xsp
	mul	d, 14

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
	ld l, 0x0:opc
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
SeMenu_StoreEffectCoeff_Data_Loop:
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+34)
	lda_rr xbc, xbc, wa
	calr SeMenu_StoreEffectParam_Data
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+26)
	lda_rr xbc, xbc, wa
	calr SeMenu_StoreEffectCoeff_Data
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	push	sr
	jr	ule, SeMenu_StoreEffectCoeff_Data_Loop
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
SeMenu_StoreEffectCoeff_Data_Loop2:
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
	jr	ule, SeMenu_StoreEffectCoeff_Data_Join
	.byte 0x84
	push	xsp
	nop
	jr	ge, SeMenu_StoreEffectCoeff_Data_Skip
	ld	(xiy), 0
	jr	SeMenu_StoreEffectCoeff_Data_Join
SeMenu_StoreEffectCoeff_Data_Skip:
	ld	(xiy), l
SeMenu_StoreEffectCoeff_Data_Join:
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	push	sr
	jr	ule, SeMenu_StoreEffectCoeff_Data_Loop2
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
	ld	wa, 0:i3
	ld	bc, 1:i3
	calr	54052
	ld	(xsp), 0
SeMenu_StoreEffectCoeff_Data_Loop3:
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
	ld	wa, 0:i3
	calr	51048
	incm8	1, (xsp)
	.byte 0x87
	push	xsp
	pop	sr
	jr	c, SeMenu_StoreEffectCoeff_Data_Loop3
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
	ld	(1709:16), 0
	ret
	ld	(1709:16), 0
	ret
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, SeMenu_RefreshPartDisplay_Epilogue
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x1222:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_RefreshPartDisplay_Epilogue:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, SeMenu_RefreshPartDisplay_Epilogue2
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x126A:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_RefreshPartDisplay_Epilogue2:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, SeMenu_RefreshPartDisplay_Epilogue3
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x12B2:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_RefreshPartDisplay_Epilogue3:
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, SeMenu_RefreshPartDisplay_Epilogue4
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x12FA:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_RefreshPartDisplay_Epilogue4:
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
	ldb_erp a, 251
	decb_erp 251, 2
	stb_erp a, 251
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
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	4
	.byte 0xbf, 0x04
	.asciz "080'"
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
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
	ldb_erp a, 251
	dec1b_erp 251
	stb_erp a, 251
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
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	5
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
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
	ldb_erp a, 251
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
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	6
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
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
	normal
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
	lda	xde, (GUI_DisplayStructData_0x1342:24)
	ld_rrb a, xde, wa
	ld (xbc), a
	ld (xbc+6), 31
	ld	(xbc+7), 0
	ld	(xbc+8), 12
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xwa, (xsp+2)
	call	SeMenu_BitShiftMask_End_0x14
	cp	l, 1:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip
	ld	a, (xsp+5)
	extz	wa
	lda	xbc, (GUI_DisplayStructData_0x1362:24)
	ld_rrb c, xbc, wa
	ld (xsp+14), c
	extz bc
	ldw wa, 14
	call	SeMenu_StorePartParam
	lda	xde, (xsp+14)
	pushw	31
	ld	wa, 0:i3
	ldw	bc, 19
	call	SeMenu_RegisterElement_Extended
	pushw	14
	pushw	39
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_RefreshPartDisplay_Skip:
	ld	wa, 6:i3
	jrl	SeMenu_RefreshPartDisplay_Join3
	lda	xbc, (xsp+2)
	.byte 0x8f
	rcf
	push	xsp
	push	sr
	jr	nz, SeMenu_RefreshPartDisplay_Skip2
	ldi_erpb 251, 15
	ldi_erpb 250, 41
	ldw	wa, 15
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 15
	ld	(xwa+7), 0
	ld	(xwa+8), 10
	ld	xbc, xwa
	jr	SeMenu_RefreshPartDisplay_Join2
SeMenu_RefreshPartDisplay_Skip2:
	ldi_erpb 251, 16
	ldi_erpb 250, 42
	ldw	wa, 16
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 15
	lda	xwa, (xbc+7)
	.byte 0x8f
	rcf
	push	xsp
	pop	sr
	jr	nz, SeMenu_RefreshPartDisplay_Skip3
	ld	(xwa), 4
	jr	SeMenu_RefreshPartDisplay_Join
SeMenu_RefreshPartDisplay_Skip3:
	ld	(xwa), 0
SeMenu_RefreshPartDisplay_Join:
	ld	(xbc+8), 10
SeMenu_RefreshPartDisplay_Join2:
	ld	(xbc+9), 6
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	stb_erp a, 250
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 39
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 6:i3
SeMenu_RefreshPartDisplay_Join3:
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 40
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	z
	ldw	wa, 39
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip4
	ldw	wa, 42
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeMenu_RefreshPartDisplay_Skip4:
	ldw	wa, 39
	ld	bc, 2:i3
	ld	de, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x17C1
	dec	2, xsp
	cp	a, 0:i3
	jr	nz, 41
	lda	xbc, (xsp)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	normal
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
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	inc	2, xsp
	ret
	dec	2, xsp
	cp	a, 0:i3
	jr	nz, 41
	lda	xbc, (xsp)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	max
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
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	inc	2, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 9
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x332
	extz	wa
	ldw	bc, 10
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x396
	extz	wa
	ldw	bc, 8
	ldw	de, 11
	jp	SeMenu_ApplyPartEdit_Data2_0x3FA
	extz	wa
	ldw	bc, 12
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x498
	extz	wa
	ldw	bc, 16
	ldw	de, 13
	jp	SeMenu_ApplyPartEdit_Data2_0x4FC
	extz	wa
	ldw	bc, 14
	ld	de, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x59C
	extz	wa
	ld	bc, 7:i3
	ldw	de, 15
	jp	SeMenu_ApplyPartEdit_Data2_0x602
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip5
	ldw	wa, 39
	ld	bc, 0:i3
	jr	SeMenu_RefreshPartDisplay_Join4
SeMenu_RefreshPartDisplay_Skip5:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 40
	ld	bc, 1:i3
SeMenu_RefreshPartDisplay_Join4:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip6
	ldw	wa, 42
	ld	bc, 0:i3
	jr	SeMenu_RefreshPartDisplay_Join5
SeMenu_RefreshPartDisplay_Skip6:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 40
	ld	bc, 1:i3
SeMenu_RefreshPartDisplay_Join5:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip7
	ld	wa, 0:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x2FA
SeMenu_RefreshPartDisplay_Skip7:
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 40
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip8
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x2FA
SeMenu_RefreshPartDisplay_Skip8:
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 40
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 41
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 20
	jp	SeMenu_ApplyPartEdit_Data2_0x6A2
	extz	wa
	ldw	bc, 21
	jp	SeMenu_ApplyPartEdit_Data2_0x732
	extz	wa
	ldw	bc, 22
	jp	SeMenu_ApplyPartEdit_Data2_0x7C2
	extz	wa
	ldw	bc, 19
	jp	SeMenu_ApplyPartEdit_Data2_0x852
	extz	wa
	ldw	bc, 17
	jp	SeMenu_ApplyPartEdit_Data2_0x8A1
	extz	wa
	ldw	bc, 18
	jp	SeMenu_ApplyPartEdit_Data2_0x8F4
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip9
	ldw	wa, 39
	ld	bc, 0:i3
	jr	SeMenu_RefreshPartDisplay_Join6
SeMenu_RefreshPartDisplay_Skip9:
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 41
	ld	bc, 1:i3
SeMenu_RefreshPartDisplay_Join6:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip10
	ldw	wa, 42
	ld	bc, 0:i3
	jr	SeMenu_RefreshPartDisplay_Join7
SeMenu_RefreshPartDisplay_Skip10:
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 41
	ld	bc, 1:i3
SeMenu_RefreshPartDisplay_Join7:
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 41
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 41
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 40
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x39
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0xB6
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x133
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x1B0
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x22B
	extz	wa
	ld	bc, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x292
	cp	a, 0:i3
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 40
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	jr	nz, SeMenu_RefreshPartDisplay_Skip11
	ldw	wa, 39
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
SeMenu_RefreshPartDisplay_Skip11:
	ld	wa, 1:i3
	ld	bc, 1:i3
	jp	SeMenu_TransferPartValues_EndData_0x20E
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	ld	bc, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x20E
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret

