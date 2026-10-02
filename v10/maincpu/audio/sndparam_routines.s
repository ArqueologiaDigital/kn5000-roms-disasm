; =============================================================================
; Sound Parameter Routines
; =============================================================================
;
; Sound parameter probe, match, and heap allocation. Provides
; lookup and comparison services for sound preset data.
; =============================================================================

SndParam_ProbeCheckMatch:
	ld bc, 0:i3
	cp xiz, xde
	jr z, SndParam_ProbeMatchFound
	ldw bc, 0xffff
	jr SndParam_ProbeAdvance

SndParam_ProbeMatchFound:
	cp bc, 0xffff
	jr z, SndParam_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7ff
	jr ugt, SndParam_DispatchCallback
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7ff
	ldto_werp IX, 0xe2

SndParam_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, NakaData_RomEnd
	jr nz, SndParam_ProbeCheckMatch

SndParam_DispatchCallback:
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, SndParam_NotFound
	cpw (xsp + 10), 0x5
	jr z, SndParam_DispatchTypeDE5
	ld c, (xwa + 13)
	cp c, 0x9
	jr nc, SndParam_NotFound
	extz bc
	sla bc, 2
	lda xde, (SndParam_DispatchCallback_Data:24)
	lda	xhl, (xde+bc)
	ld bc, (xsp + 12)
	ld de, (xsp + 10)
	ld xhl, (xhl)
	call (xhl)
	ld xbc, xhl
	cpw (xbc), 0xffff
	jr z, SndParam_NotFound
	ld wa, (xbc + 2)
	cp wa, 1:i3
	jr z, SndParam_CallbackType1
	cp wa, 0:i3
	jr nz, SndParam_Epilogue
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType0
	jr SndParam_Epilogue

SndParam_CallbackType1:
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType1
	jr SndParam_Epilogue

SndParam_NotFound:
	ldw (xsp + 4), 0xffff

SndParam_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 10)
	ret

SndParam_DispatchTypeDE5:
	ld c, (xwa + 16)
	cp c, 6:i3
	jr nc, SndParam_Epilogue
	extz bc
	sla bc, 2
	lda xde, (SndParam_DispatchTypeDE5_Data:24)
	lda	xde, (xde+bc)
	ld bc, (xsp + 12)
	ld xhl, (xde)
	call (xhl)
	ld (xsp + 4), hl
	jr SndParam_Epilogue

SndParam_NotifyAndReturn:
	pushw iz
	ld iz, de
	calr SndParam_EncodeAddress
	ld xwa, xhl
	ld bc, iz
	ld de, (xsp + 6)
	calr SoundParam_NotifyChange
	popw iz
	retd 0x2

SndParam_LookupByKey:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), de
	ld (xsp + 12), bc
	ldw (xsp + 4), 0x0
	ld xiz, xwa
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 16
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld ix, hl
	jr SndParam_Lkp2_ProbeEntry

SndParam_Lkp2_ProbeCheck:
	ld bc, 0:i3
	cp xiz, xde
	jr z, SndParam_Lkp2_MatchFound
	ldw bc, 0xffff
	jr SndParam_Lkp2_ProbeAdvance

SndParam_Lkp2_MatchFound:
	cp bc, 0xffff
	jr z, SndParam_Lkp2_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_Lkp2_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7ff
	jr ugt, SndParam_Lkp2_Dispatch
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7ff
	ldto_werp IX, 0xe2

SndParam_Lkp2_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, NakaData_RomEnd
	jr nz, SndParam_Lkp2_ProbeCheck

SndParam_Lkp2_Dispatch:
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, SndParam_Lkp2_NotFound
	ld a, (xwa + 14)
	cp a, 0x8
	jr nc, SndParam_Lkp2_NotFound
	extz wa
	sla wa, 2
	lda xbc, (SndParam_Lkp2_Dispatch_Data:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 6)
	ld bc, (xsp + 12)
	ld de, (xsp + 10)
	ld xhl, (xhl)
	call (xhl)
	ld xbc, xhl
	cpw (xbc), 0xffff
	jr z, SndParam_Lkp2_NotFound
	ld wa, (xbc + 2)
	cp wa, 1:i3
	jr z, SndParam_Lkp2_CallType1
	cp wa, 0:i3
	jr nz, SndParam_Lkp2_Epilogue
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType0
	jr SndParam_Lkp2_Epilogue

SndParam_Lkp2_CallType1:
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType1
	jr SndParam_Lkp2_Epilogue

SndParam_Lkp2_NotFound:
	ldw (xsp + 4), 0xffff

SndParam_Lkp2_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 10)
	ret

SndParam_WrapNotify2:
	pushw	iz
	ld	iz, de
	calr	SndParam_EncodeAddress
	ld	xwa, xhl
	ld	bc, iz
	ld	de, (xsp+6)
	calr	SndParam_LookupByKey
	popw	iz
	retd	2

SndParam_LookupReadOnly:
	dec 6, xsp
	push xiz
	ldw (xsp + 4), 0xffff
	ld xiz, xwa
	ld xwa, 0:i3
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 16
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld ix, hl
	jr SndParam_RO_ProbeEntry

SndParam_RO_ProbeCheck:
	ld bc, 0:i3
	cp xiz, xde
	jr z, SndParam_RO_MatchFound
	ldw bc, 0xffff
	jr SndParam_RO_ProbeAdvance

SndParam_RO_MatchFound:
	cp bc, 0xffff
	jr z, SndParam_RO_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_RO_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7ff
	jr ugt, SndParam_RO_Dispatch
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7ff
	ldto_werp IX, 0xe2

SndParam_RO_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, NakaData_RomEnd
	jr nz, SndParam_RO_ProbeCheck

SndParam_RO_Dispatch:
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, SndParam_RO_Epilogue
	ld a, (xwa + 12)
	cp a, 7:i3
	jr nc, SndParam_RO_Epilogue
	extz wa
	sla wa, 2
	lda xbc, (SndParam_RO_Dispatch_Data:24)
	lda	xbc, (xbc+wa)
	ld xwa, (xsp + 6)
	ld xhl, (xbc)
	call (xhl)
	ld (xsp + 4), hl

SndParam_RO_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	inc 6, xsp
	ret

SndParam_LookupViaEncode:
	calr SndParam_EncodeAddress
	ld xwa, xhl
	jrl SndParam_LookupReadOnly

SndParam_ResolveWidget:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld (xsp + 22), xwa
	ld xbc, (xsp + 22)
	lda xwa, (xbc + 2)
	ld (xsp + 10), xwa
	ld a, (xwa)
	extz wa
	ld (xsp + 4), wa
	ld e, (xbc)
	ld xwa, xbc
	ld c, (xwa + 1)
	inc 3, xwa
	ld (xsp + 6), xwa
	ld a, (xwa)
	extz de
	extz bc
	extz wa
	ld l, e
	ld e, a
	ld b, 0x0:opc
	extz xbc
	sll xbc, 8
	ld h, 0x0:opc
	extz xhl
	sll xhl, 16
	or xhl, xbc
	ld d, 0x0:opc
	extz xde
	ld xiz, xde
	or xiz, xhl
	ld xde, xiz
	srl xde, 8
	ld xhl, xde
	and xhl, 0xf
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 4
	and xhl, 0xf
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 8
	and xhl, 0xf
	add xhl, xwa
	ld xbc, xhl
	sll xbc, 9
	add xbc, xhl
	srl xde, 12
	ld xhl, xde
	and xhl, 0xf
	add xhl, xbc
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	sll hl, 2
	lda xwa, (0x97d8:16)
	extz xhl
	add xhl, xwa
	ld xde, (xhl)
	or xde, xde
	jrl z, SndParam_RW_NoEntry
	ld xix, (xde)
	ldw hl, 0xffff
	ld xwa, xix
	srl xwa, 8
	ld xbc, xiz
	srl xbc, 8
	cp xbc, xwa
	jr nz, SndParam_RW_CheckFirstMatch
	ld xwa, xiz
	srl xwa, 16
	cp xwa, 0xb1
	jr z, SndParam_RW_ExactMatch
	ld xwa, xix
	and xwa, 0xff
	and xwa, xiz
	and xwa, 0xff
	jr z, SndParam_RW_CheckFirstMatch

SndParam_RW_ExactMatch:
	ld hl, 0:i3
	jr SndParam_RW_FoundCallback

SndParam_RW_CheckFirstMatch:
	cp hl, 0xffff
	jr nz, SndParam_RW_FoundCallback
	ld xwa, (xde + 8)
	or xwa, xwa
	jr z, SndParam_RW_NoEntry

SndParam_RW_ChainNext:
	ld xde, (xde + 8)
	ld xix, xiz
	ld xiy, (xde)
	ldw hl, 0xffff
	ld xwa, xiy
	srl xwa, 8
	cp xbc, xwa
	jr nz, SndParam_RW_ChainCheckFirst
	ld xwa, xix
	srl xwa, 16
	cp xwa, 0xb1
	jr z, SndParam_RW_ChainExactMatch
	ld xwa, xiy
	and xwa, 0xff
	and xwa, xix
	and xwa, 0xff
	jr z, SndParam_RW_ChainCheckFirst

SndParam_RW_ChainExactMatch:
	ld hl, 0:i3
	jr SndParam_RW_FoundCallback

SndParam_RW_ChainCheckFirst:
	cp hl, 0xffff
	jr z, SndParam_RW_ChainContinue

SndParam_RW_FoundCallback:
	ld xwa, (xde + 4)
	jr SndParam_RW_ProcessResult

SndParam_RW_ChainContinue:
	ld xwa, (xde + 8)
	or xwa, xwa
	jr nz, SndParam_RW_ChainNext

SndParam_RW_NoEntry:
	ld xwa, 0:i3

SndParam_RW_ProcessResult:
	ld xiz, xwa
	or xwa, xwa
	jr z, SndParam_RW_Fail
	ld xwa, (xsp + 18)
	ld xbc, (xiz)
	ld (xwa), xbc
	ld xwa, (xsp + 22)
	cp (xwa), 0xb1
	jr z, SndParam_RW_HandleB1Type
	ld a, (xiz + 15)
	inc 3, a
	extz wa
	sla wa, 2
	lda xbc, (SndParam_RW_ProcessResult_Data:24)
	lda	xde, (xbc+wa)
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld xix, (xde)
	call (xix)
	ld xwa, (xsp + 14)
	ld (xwa), hl
	ld c, (xiz + 6)
	cpl c
	ld xwa, (xsp + 22)
	and (xwa + 3), c
	jr SndParam_RW_Success

SndParam_RW_HandleB1Type:
	ld xwa, (xsp + 10)
	ld c, (xwa)
	res 7, c
	extz bc
	ld xwa, (xsp + 6)
	ld a, (xwa)
	res 7, a
	extz wa
	sla wa, 7
	ld de, wa
	or de, bc
	ld xwa, (xsp + 14)
	ld (xwa), de

SndParam_RW_Success:
	ld hl, 0:i3
	jr SndParam_RW_Epilogue

SndParam_RW_Fail:
	ldw hl, 0xffff

SndParam_RW_Epilogue:
	pop xiz
	lda xsp, (xsp + 22)
	ret

SndParam_ResolveWidgetEx_Data:
	lda	xsp, (xsp-14)
	push	xiz
	ld	(xsp+10), xde
	ld	xde, xbc
	ld	(xsp+14), xwa
	ldw	(xsp+4), 0
	ld	xwa, (xsp+14)
	ld	xiy, SndParam_RW_Fail_Data
	ld	xix, xwa
	ldiw
	ldiw
	ld	xiz, (xde)
	ld	xwa, 0:i3
	ld	(xsp+6), xwa
	ld	xhl, xiz
	and	xhl, 255
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 8
	and	xhl, 255
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 16
	and	xhl, 31
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 2047
	call	DivMod32
	ld	ix, hl
	jr	SndParam_ResolveWidget_Join2
SndParam_ResolveWidget_Loop:
	ld	bc, 0:i3
	cp	xiz, xde
	jr	z, SndParam_ResolveWidget_Skip
	ldw	bc, 0xffff
	jr	SndParam_ResolveWidget_Join
SndParam_ResolveWidget_Skip:
	cp	bc, 0xffff
	jr	z, SndParam_ResolveWidget_Join
	ld	xwa, (xwa+4)
	ld	(xsp+6), xwa
SndParam_ResolveWidget_Join:
	inc	1, hl
	cp	hl, 2047
	jr	ugt, SndParam_ResolveWidget_Skip2
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld ix, qwa
SndParam_ResolveWidget_Join2:
	ld bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, 0x034100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_ResolveWidget_Loop
SndParam_ResolveWidget_Skip2:
	ld	xwa, (xsp+6)
	or	xwa, xwa
	jr	z, SndParam_ResolveWidget_Skip3
	ld	xhl, (xsp+14)
	ld	c, (xwa+4)
	ld	(xhl), c
	ld	c, (xwa+5)
	ld	(xhl+1), c
	lda	xde, (xhl+3)
	ld	c, (xwa+6)
	ld	(xde), c
	cp	(xhl), 177
	jr	z, SndParam_ResolveWidget_Skip4
	ld	xbc, (xsp+10)
	ld	bc, (xbc)
	ld	e, (xwa+15)
	extz	de
	sla	de, 2
	lda	xhl, (SndParam_RW_ProcessResult_Data:24)
	exts	xde
	add	xde, xhl
	ld	xix, (xde)
	call	(xix)
	ld	xwa, (xsp+14)
	ld	(xwa+2), l
	jr	SndParam_ResolveWidget_Join3
SndParam_ResolveWidget_Skip4:
	ld	xhl, (xsp+10)
	ld	bc, (xhl)
	and	bc, 127
	ld	xwa, (xsp+14)
	ld	(xwa+2), c
	ld	wa, (xhl)
	sra	wa, 7
	and	wa, 127
	ld	(xde), a
	jr	SndParam_ResolveWidget_Join3
SndParam_ResolveWidget_Skip3:
	ldw	(xsp+4), 65535
SndParam_ResolveWidget_Join3:
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+14)
	ret

SndParam_DecodeMidiAddr:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld (xsp + 22), xwa
	ldw (xsp + 4), 0xffff
	ld xwa, (xsp + 22)
	ld xiz, (xwa)
	ld (xsp + 6), xiz
	ld xwa, 0:i3
	ld (xsp + 10), xwa
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 16
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld ix, hl
	jr SndParam_DMA_ProbeEntry

SndParam_DMA_ProbeCheck:
	ld bc, 0:i3
	cp (xsp + 6), xde
	jr z, SndParam_DMA_MatchFound
	ldw bc, 0xffff
	jr SndParam_DMA_ProbeAdvance

SndParam_DMA_MatchFound:
	cp bc, 0xffff
	jr z, SndParam_DMA_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 10), xwa

SndParam_DMA_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7ff
	jr ugt, SndParam_DMA_ExtractFields
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7ff
	ldto_werp IX, 0xe2

SndParam_DMA_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, NakaData_RomEnd
	jr nz, SndParam_DMA_ProbeCheck

SndParam_DMA_ExtractFields:
	ld xwa, (xsp + 10)
	or xwa, xwa
	jrl z, SndParam_DMA_Epilogue
	ld xbc, (xsp + 22)
	ld xwa, (xbc)
	cp xwa, 0x8000
	jr c, SndParam_DMA_Zone2Check
	ld xwa, (xbc)
	cp xwa, 0x17fff
	jr ugt, SndParam_DMA_Zone2Check
	sub xiz, 0x8000
	ld xwa, xiz
	srl xwa, 10
	and xwa, 0x3f
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	ld xbc, xiz
	and xbc, 0x3ff
	ld xwa, (xsp + 14)
	ld (xwa), bc
	ldw (xsp + 4), 0x0

SndParam_DMA_Zone2Check:
	ld xbc, (xsp + 22)
	ld xwa, (xbc)
	cp xwa, 0x18000
	jr c, SndParam_DMA_Epilogue
	ld xwa, (xbc)
	cp xwa, 0x27fff
	jr ugt, SndParam_DMA_Epilogue
	sub xiz, 0x8000
	ld xwa, xiz
	srl xwa, 10
	and xwa, 0x3f
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	ld xbc, xiz
	and xbc, 0x3ff
	add bc, 0x400
	ld xwa, (xsp + 14)
	ld (xwa), bc
	ldw (xsp + 4), 0x0

SndParam_DMA_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 22)
	ret

SndParam_ResolveWidgetVariant2_Data:
	dec	8, xsp
	push	xiz
	ld	xbc, 0:i3
	ld	(xsp+4), xbc
	ld	xiz, xwa
	ld	xwa, 0:i3
	ld	(xsp+8), xwa
	ld	xhl, xiz
	and	xhl, 255
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 8
	and	xhl, 255
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 16
	and	xhl, 31
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 2047
	call	DivMod32
	ld	ix, hl
	jr	SndParam_DecodeMidiAddr_Join2
SndParam_DecodeMidiAddr_Loop:
	ld	bc, 0:i3
	cp	xiz, xde
	jr	z, SndParam_DecodeMidiAddr_Skip
	ldw	bc, 0xffff
	jr	SndParam_DecodeMidiAddr_Join
SndParam_DecodeMidiAddr_Skip:
	cp	bc, 0xffff
	jr	z, SndParam_DecodeMidiAddr_Join
	ld	xwa, (xwa+4)
	ld	(xsp+8), xwa
SndParam_DecodeMidiAddr_Join:
	inc	1, hl
	cp	hl, 2047
	jr	ugt, SndParam_DecodeMidiAddr_Skip2
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld ix, qwa
SndParam_DecodeMidiAddr_Join2:
	ld bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, 0x034100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_DecodeMidiAddr_Loop
SndParam_DecodeMidiAddr_Skip2:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	z, SndParam_DecodeMidiAddr_Skip3
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_DMA_Zone2Check_Data:24)
	ld	l, (xwa+5)
	extz	hl
	ld_rrl	xwa, xde, bc
	lda_rr	xwa, xwa, hl
	ld	(xsp+4), xwa
SndParam_DecodeMidiAddr_Skip3:
	ld	xhl, (xsp+4)
	pop	xiz
	inc	8, xsp
	ret

SndParam_ReturnNotFound:
	ldw hl, 0xffff
	ret

SndParam_ReadRegField:
	ldw hl, 0xffff
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda xde, (SndParam_DMA_Zone2Check_Data:24)
	ld	xde, (xde+bc)
	or xde, xde
	ret z
	ld c, (xwa + 5)
	extz bc
	ld	l, (xde+bc)
	extz hl
	ld e, (xwa + 6)
	extz de
	ld c, (xwa + 10)
	extz bc
	xor hl, bc
	and hl, de
	ld a, (xwa + 9)
	and a, 0xf
	ret z
	sraa hl
	ret

SndParam_ReadRegWithLUT:
	ld e, (xwa + 11)
	ld c, e
	sla c, 2
	lda xhl, (SndParam_ReadRegWithLUT_Data:24)
	ld	xbc, (xhl+c)
	ld c, (xbc)
	cp e, 2:i3
	jr nz, SndParam_ReadRegMasked
	ld a, c
	sll a, 6
	and a, 0x40
	ld l, a
	extz hl
	srl c, 1
	res 7, c
	sll c, 7
	extz bc
	add hl, bc
	cp hl, 0x3fc0
	ret lt
	ldw hl, 0x3fff
	jr SndParam_ReadRegReturn

SndParam_ReadRegMasked:
	ld l, (xwa + 6)
	and l, c
	extz hl

SndParam_ReadRegReturn:
	ret

SndParam_CompareRegField:
	ld xbc, xwa
	ld a, (xbc + 4)
	extz wa
	sla wa, 2
	lda xde, (SndParam_DMA_Zone2Check_Data:24)
	ld	xde, (xde+wa)
	or xde, xde
	jr z, SndParam_CompareNotFound
	ld a, (xbc + 5)
	extz wa
	ld	l, (xde+wa)
	ld e, (xbc + 6)
	ld a, (xbc + 10)
	xor l, a
	and l, e
	ld a, (xbc + 9)
	and a, 0xf
	jr z, SndParam_CompareShifted
	srla l

SndParam_CompareShifted:
	ld a, (xbc + 11)
	sla a, 2
	lda xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cp l, (xbc + 1)
	jr nz, SndParam_CompareStatus5
	ld xwa, 3:i3
	jr SndParam_CompareAddOffset

SndParam_CompareStatus5:
	ld xwa, 5:i3
	cp l, (xbc + 2)
	jr nz, SndParam_CompareAddOffset
	ld xwa, 4:i3

SndParam_CompareAddOffset:
	add xbc, xwa
	ld l, (xbc)
	extz hl
	ret

SndParam_CompareNotFound:
	ldw hl, 0xffff
	ret

SndParam_ReadRegWord:
	ldw hl, 0xffff
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda xde, (SndParam_DMA_Zone2Check_Data:24)
	ld	xde, (xde+bc)
	or xde, xde
	ret z
	ld c, (xwa + 5)
	extz bc
	add bc, bc
	ld	de, (xde+bc)
	ld a, (xwa + 11)
	sla a, 2
	lda xbc, (SndParam_ReadRegWord_Data:24)
	ld	xwa, (xbc+a)
	ld hl, 0:i3

SndParam_ReadRegScanLoop:
	cp DE, (xwa+)
	ret z
	inc 1, hl
	cp hl, 5:i3
	jr le, SndParam_ReadRegScanLoop
	ld hl, 0:i3
	ret

SndParam_ReadRegBitfield:
	ld l, 0x0:opc
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda xde, (SndParam_DMA_Zone2Check_Data:24)
	ld	xix, (xde+bc)
	or xix, xix
	jr z, SndParam_BitfieldReturn
	ld c, (xwa + 5)
	extz bc
	ld de, bc
	inc 1, de
	bit	2, (xix+de)
	jr nz, SndParam_BitfieldPendingWrite
	ld	l, (xix+bc)
	ld c, (xwa + 6)
	ld b, c
	ld e, (xwa + 10)
	xor l, e
	and l, b
	ld e, (xwa + 9)
	ld a, e
	and a, 0xf
	jr z, SndParam_BitfieldZeroCheck
	srla l

SndParam_BitfieldZeroCheck:
	jr z, SndParam_BitfieldReturn
	ld a, e
	and a, 0xf
	jr z, SndParam_BitfieldNoShift
	srla c

SndParam_BitfieldNoShift:
	xor l, c
	jr SndParam_BitfieldReturn

SndParam_BitfieldPendingWrite:
	ld l, 0x3:opc

SndParam_BitfieldReturn:
	extz hl
	ret

SndParam_ReadRegAddress:
	ldw hl, 0xffff
	ld a, (xwa + 4)
	extz wa
	sla wa, 2
	lda xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld	xwa, (xbc+wa)
	or xwa, xwa
	ret z
	ld wa, (xwa + 8)
	and wa, 0x1ff
	ld hl, wa
	ret

SndParam_ResetDefaultTable:
	ld xiy, SndParam_ResetDefaultTable_Data
	ld xix, 0x96d4
	ld bc, 6:i3
	ldirw
	lda xhl, (0x96d4:16)
	ldw (xhl), 0xffff
	ret

SndParam_RegisterEntry_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+12), de
	ld	xde, xwa
	ld	a, c
	ldfr_berp	a, 230
	lda	xwa, (xde+4)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xhl, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xhl, xhl, wa
	or xhl, xhl
	jrl	z, SndParam_RegisterEntry_Data_Skip3
	ld	a, (xde+7)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	le, SndParam_RegisterEntry_Data_Skip
	ldfr_berp	a, 230
SndParam_RegisterEntry_Data_Skip:
	ld	a, (xde+8)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	ge, 3
	ldfr_berp	a, 230
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96e0
	ld	bc, 6:i3
	ldirw
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	6
	xor	b, c
	lda	xix, (xde+6)
	lda	xwa, (0x96e6:16)
	ld	(xsp+8), xwa
	cpw	(xsp+12), 4
	jr	nz, 11
	ld	c, (xix)
	and	c, b
	ld	xwa, (xsp+8)
	ld	(xwa), c
	jr	57
	lda	xiy, (xde+5)
	ld	a, (xiy)
	extz	wa
	lda_rr xiz, xhl, wa
	ld w, (xiz)
	ldfr_berp w, 231
	ld c, (xix)
	ldfr_berp	c, 230
	ldto_berp	a, 230
	and	a, b
	ldfr_berp	a, 230
	cpl	c
	and	w, c
	ld	(xiz), w
	ld	a, (xiy)
	extz	wa
	lda_rr xhl, xhl, wa
	ld c, (xhl)
	orb_erp	c, 230
	ld	(xhl), c
	ld	xwa, (xsp+8)
	ld	(xwa), c
	lda	xhl, (0x96e0:16)
	ldto_berp	a, 231
	cp	a, (xhl+6)
	jr	nz, SndParam_RegisterEntry_Data_Skip2
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterEntry_Data_Join
SndParam_RegisterEntry_Data_Skip2:
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xhl+4), a
	ld	a, (xde+5)
	ld	(xhl+5), a
	ld	a, (xix)
	ld	(xhl+7), a
	jr	SndParam_RegisterEntry_Data_Join
SndParam_RegisterEntry_Data_Skip3:
	ldw	(0x96e0:16), 0xffff
SndParam_RegisterEntry_Data_Join:
	ld	xhl, 0x96e0
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterEntryAlt_Data:
	dec	8, xsp
	pushw	iz
	ld	hl, de
	ld	xde, xwa
	ld	a, c
	ldfr_berp	a, 230
	lda	xwa, (xde+4)
	ld	(xsp+6), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xix, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xix, wa
	ld (xsp+2), xwa
	or xwa, xwa
	jrl	z, SndParam_RegisterEntryAlt_Data_Skip2
	ld	a, (xde+7)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	le, SndParam_RegisterEntryAlt_Data_Skip
	ldfr_berp	a, 230
SndParam_RegisterEntryAlt_Data_Skip:
	ld	a, (xde+8)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	ge, 3
	ldfr_berp	a, 230
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96ec
	ld	bc, 6:i3
	ldirw
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	6
	xor	b, c
	lda	xix, (xde+6)
	lda	xiy, (0x96f2:16)
	cp	hl, 4:i3
	jr	nz, 8
	ld	a, (xix)
	and	a, b
	ld	(xiy), a
	jr	50
	ld	c, (xix)
	ldfr_berp	c, 230
	ldto_berp	a, 230
	and	a, b
	ldfr_berp	a, 230
	lda	xhl, (xde+5)
	ld	a, (xhl)
	extz	wa
	ld	iz, wa
	cpl	c
	ld	xwa, (xsp+2)
	.byte 0xc3
	reti
	.byte 0xe0
	swi	0
	add	c, c
	ld	c, 217:opc
	ccf
	lda_rr xhl, xwa, bc
	ld a, (xhl)
	orb_erp	a, 230
	ld	(xhl), a
	ld	(xiy), a
	lda	xbc, (0x96ec:16)
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	SndParam_RegisterEntryAlt_Data_Join
SndParam_RegisterEntryAlt_Data_Skip2:
	ldw	(0x96ec:16), 0xffff
SndParam_RegisterEntryAlt_Data_Join:
	ld	xhl, 0x96ec
	popw	iz
	inc	8, xsp
	ret
SndParam_UpdateEntry_Data:
	ld	de, bc
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96f8
	ld	bc, 6:i3
	ldirw
	lda	xhl, (0x96f8:16)
	lda	xiy, (xwa+4)
	ld	c, (xiy)
	ld	(xhl+4), c
	ld	c, (xwa+5)
	ld	(xhl+5), c
	ld	c, e
	ldfr_berp	c, 234
	lda	xbc, (xhl+6)
	lda	xix, (xhl+7)
	cp	(xiy), 177
	jr	nz, SndParam_UpdateEntry_Data_Skip
	ldto_berp	a, 234
	res	7, a
	ld	(xbc), a
	sra	de, 7
	ld	(xix), e
	jr	SndParam_UpdateEntry_Data_Return
SndParam_UpdateEntry_Data_Skip:
	lda	xiy, (xwa+6)
	ld	e, (xiy)
	ldto_berp	a, 234
	and	a, e
	ld	(xbc), a
	ld	a, (xiy)
	ld	(xix), a
SndParam_UpdateEntry_Data_Return:
	ret
SndParam_RegisterMultiField_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+12), de
	ld	hl, bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+8), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterMultiField_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9704
	ld	bc, 6:i3
	ldirw
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld_rr8l	xbc, xbc, a
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, 2
	ld	xwa, 2:i3
	add	xbc, xwa
	ld	l, (xbc)
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	xor	c, l
	ld	h, c
	lda	xix, (xde+6)
	lda	xbc, (0x970a:16)
	cpw	(xsp+12), 4
	jr	nz, 8
	ld	a, (xix)
	and	a, h
	ld	(xbc), a
	jr	56
	lda	xiy, (xde+5)
	ld	a, (xiy)
	ldfr_berp	a, 248
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	ldfr_berp w, 238
	ld a, (xix)
	ld	l, a
	and	l, h
	cpl	a
	and	w, a
	ld	(xiz), w
	ld	a, (xiy)
	ldfr_berp	a, 244
	extz	iy
	ld	xwa, (xsp+4)
	exts	xiy
	add	xiy, xwa
	ld	a, (xiy)
	or	a, l
	ld	(xiy), a
	ld	(xbc), a
	lda	xbc, (0x9704:16)
	ldto_berp	a, 238
	.byte 0x89, 0x06, 0xf1
	jr	nz, SndParam_RegisterMultiField_Data_Skip
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterMultiField_Data_Join
SndParam_RegisterMultiField_Data_Skip:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	SndParam_RegisterMultiField_Data_Join
SndParam_RegisterMultiField_Data_Skip2:
	ldw	(0x9704:16), 0xffff
SndParam_RegisterMultiField_Data_Join:
	ld	xhl, 0x9704
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterBitfield_Data:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), de
	ld	de, bc
	lda	xhl, (xwa+4)
	ld	c, (xhl)
	extz	bc
	sla	bc, 2
	lda	xix, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xiz, xix, bc
	or xiz, xiz
	jrl	z, SndParam_RegisterBitfield_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9710
	ld	bc, 6:i3
	ldirw
	lda	xix, (0x9710:16)
	ldw	(xix+2), 1
	ld	c, (xwa+7)
	extz	bc
	cp	bc, de
	jr	le, SndParam_RegisterBitfield_Data_Skip
	ld	de, bc
SndParam_RegisterBitfield_Data_Skip:
	ld	c, (xwa+8)
	extz	bc
	cp	bc, de
	jr	ge, SndParam_RegisterBitfield_Data_Skip2
	ld	de, bc
SndParam_RegisterBitfield_Data_Skip2:
	ld	c, (xwa+11)
	sla	c, 2
	lda	xiy, (SndParam_ReadRegWord_Data:24)
	ld_rr8l xiy, xiy, c
	exts xde
	add	xde, xde
	add	xde, xiy
	ld	de, (xde)
	lda	xiy, (xwa+5)
	ld	c, (xiy)
	extz	bc
	add	bc, bc
	exts	xbc
	add	xbc, xiz
	cp	(xbc), de
	jr	z, SndParam_RegisterBitfield_Data_Join
	cpw	(xsp+4), 4
	jr	z, SndParam_RegisterBitfield_Data_Skip4
	ld	(xbc), de
SndParam_RegisterBitfield_Data_Skip4:
	ld	c, (xhl)
	ld	(xix+4), c
	ld	c, (xiy)
	ld	(xix+5), c
	ld	c, e
	ld	(xix+6), c
	lda	xbc, (xwa+6)
	ld	a, (xbc)
	ld	(xix+7), a
	ld	a, (xhl)
	ld	(xix+8), a
	ld	a, (xiy)
	inc	1, a
	ld	(xix+9), a
	srl	de, 8
	ld	(xix+10), e
	ld	a, (xbc)
	ld	(xix+11), a
	jr	SndParam_RegisterBitfield_Data_Join
SndParam_RegisterBitfield_Data_Skip3:
	ldw	(0x9710:16), 0xffff
SndParam_RegisterBitfield_Data_Join:
	ld	xhl, 0x9710
	pop	xiz
	inc	2, xsp
	ret
SndParam_RegisterLinked_Data:
	lda	xsp, (xsp-18)
	ld	(xsp+16), de
	ld	de, bc
	ld	xhl, xwa
	ld	a, e
	ldfr_berp	a, 230
	lda	xwa, (xhl+4)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xix, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xix, wa
	ld (xsp), xwa
	or xwa, xwa
	jrl	z, SndParam_RegisterLinked_Data_Skip4
	ld	a, (xhl+7)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	le, SndParam_RegisterLinked_Data_Skip
	ldfr_berp	a, 230
SndParam_RegisterLinked_Data_Skip:
	ld	a, (xhl+8)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	ge, SndParam_RegisterLinked_Data_Skip2
	ldfr_berp	a, 230
SndParam_RegisterLinked_Data_Skip2:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x971c
	ld	bc, 6:i3
	ldirw
	lda	xwa, (0x971c:16)
	ld	(xsp+8), xwa
	lda	xix, (xwa+5)
	ld	a, (xhl+5)
	ld	(xix), a
	cp	de, 3:i3
	jr	nz, 9
	inc	1, a
	ld	(xix), a
	ldib_erp	230, 1
	jr	26
	cpib_erp 230, 0
	jr z, 21
	ld	c, (xhl+6)
	ld	a, (xhl+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	7
	ldto_berp	a, 230
	xor	a, c
	ldfr_berp	a, 230
	ld	e, (xhl+10)
	ldto_berp	c, 230
	ld	a, (xhl+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	6
	ld	xwa, (xsp+8)
	inc	6, xwa
	ld	(xsp+12), xwa
	xor	e, c
	ld	d, e
	lda	xbc, (xhl+6)
	cpw	(xsp+16), 4
	jr	nz, 11
	ld	c, (xbc)
	and	c, d
	ld	xwa, (xsp+12)
	ld	(xwa), c
	jr	SndParam_RegisterLinked_Data_Join
	ld	a, (xix)
	ldfr_berp	a, 244
	extz	iy
	ld	xwa, (xsp)
	exts	xiy
	add	xiy, xwa
	ld	w, (xiy)
	ld	e, w
	ld	c, (xbc)
	ldfr_berp	c, 230
	ldto_berp	a, 230
	and	a, d
	ldfr_berp	a, 230
	cpl	c
	and	w, c
	ld	(xiy), w
	ld	c, (xix)
	extz	bc
	ld	xwa, (xsp)
	lda_rr xix, xwa, bc
	ld c, (xix)
	orb_erp	c, 230
	ld	(xix), c
	ld	xwa, (xsp+12)
	ld	(xwa), c
SndParam_RegisterLinked_Data_Join:
	ld	xbc, (xsp+12)
	.byte 0x81, 0xf5
	jr	nz, SndParam_RegisterLinked_Data_Skip3
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterLinked_Data_Join2
SndParam_RegisterLinked_Data_Skip3:
	ld	xwa, (xsp+4)
	ld	xde, (xsp+8)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	c, (xhl+6)
	ld	(xde+7), c
	jr	SndParam_RegisterLinked_Data_Join2
SndParam_RegisterLinked_Data_Skip4:
	ldw	(0x971c:16), 0xffff
SndParam_RegisterLinked_Data_Join2:
	ld	xhl, 0x971c
	lda	xsp, (xsp+18)
	ret
SndParam_RegisterLinked2_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+12), de
	ld	hl, bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+8), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterLinked2_Data_Skip5
	ld	a, (xde+7)
	cp	a, l
	jr	ule, SndParam_RegisterLinked2_Data_Skip2
	ld	l, a
SndParam_RegisterLinked2_Data_Skip2:
	ld	a, (xde+8)
	cp	a, l
	jr	nc, SndParam_RegisterLinked2_Data_Skip3
	ld	l, a
SndParam_RegisterLinked2_Data_Skip3:
	lda	xbc, (SndParam_ResetDefaultTable_Data_2:24)
	ld	a, (xde+11)
	cp	a, 255
	jr	z, 10
	sla	a, 2
	ld_rr8l xiy, xbc, a
	jr 2
	ld	xiy, (xbc)
	extz	hl
	ld	xix, xiy
	ld	bc, 0:i3
	cpw	(xiy+4), 0
	jr	le, 20
	ld	xwa, (xix)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	ldx
	jr	nz, 4
	ld	wa, bc
	jr	10
	inc	1, bc
	.byte 0x9c, 0x04, 0xf1
	jr	lt, -20
	ld	wa, (xix+7)
	ld	xhl, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, 6
	ld	xwa, (xhl)
	ld	l, (xwa)
	jr	SndParam_RegisterLinked2_Data_Join2
	ld	wa, (xhl+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterLinked2_Data_Skip4
	ld	xwa, (xhl)
	ld_rrb l, xwa, bc
	jr SndParam_RegisterLinked2_Data_Join2
SndParam_RegisterLinked2_Data_Skip4:
	ld bc, wa
	dec	1, bc
	ld	xwa, (xhl)
	ld_rrb	l, xwa, bc
SndParam_RegisterLinked2_Data_Join2:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38696
	ld	bc, 6:i3
	ldirw
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	xor	c, l
	ld	h, c
	lda	xbc, (xde+6)
	lda	xix, (0x972e:16)
	cpw	(xsp+12), 4
	jr	nz, 8
	ld	a, (xbc)
	and	a, h
	ld	(xix), a
	jr	56
	lda	xiy, (xde+5)
	ld	a, (xiy)
	ldfr_berp	a, 248
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	ldfr_berp w, 238
	ld a, (xbc)
	ld	l, a
	and	l, h
	cpl	a
	and	w, a
	ld	(xiz), w
	ld	a, (xiy)
	ldfr_berp	a, 244
	extz	iy
	ld	xwa, (xsp+4)
	exts	xiy
	add	xiy, xwa
	ld	a, (xiy)
	or	a, l
	ld	(xiy), a
	ld	(xix), a
	lda	xix, (0x9728:16)
	ldto_berp	a, 238
	.byte 0x8c, 0x06, 0xf1
	jr	nz, SndParam_RegisterLinked2_Data_Skip
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterLinked2_Data_Join
SndParam_RegisterLinked2_Data_Skip:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xix+4), a
	ld	a, (xde+5)
	ld	(xix+5), a
	ld	a, (xbc)
	ld	(xix+7), a
	jr	SndParam_RegisterLinked2_Data_Join
SndParam_RegisterLinked2_Data_Skip5:
	ldw	(0x9728:16), 0xffff
SndParam_RegisterLinked2_Data_Join:
	ld	xhl, 0x9728
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterSimple_Data:
	dec	6, xsp
	push	xiz
	ld	(xsp+8), de
	ld	de, bc
	inc	4, xwa
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xiz, xbc, wa
	or xiz, xiz
	jr	z, SndParam_RegisterSimple_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9734
	ld	bc, 6:i3
	ldirw
	cp	de, 40
	jr	ge, SndParam_RegisterSimple_Data_Skip
	ldw	de, 40
	jr	SndParam_RegisterSimple_Data_Join
SndParam_RegisterSimple_Data_Skip:
	cp	de, 300
	jr	le, SndParam_RegisterSimple_Data_Join
	ldw	de, 300
SndParam_RegisterSimple_Data_Join:
	ld	a, e
	ldfr_berp	a, 234
	lda	xwa, (0x9734:16)
	lda	xbc, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	lda	xiy, (xwa+7)
	cpw	(xsp+8), 4
	jr	nz, SndParam_RegisterSimple_Data_Skip2
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	ldto_berp	a, 234
	ld	(xix), a
	sra	de, 8
	ld	(xiy), e
	jr	SndParam_RegisterSimple_Data_Join2
SndParam_RegisterSimple_Data_Skip2:
	inc	8, xiz
	ld	wa, de
	.byte 0x96, 0xf0
	jr	z, SndParam_RegisterSimple_Data_Join2
	ld	(xiz), de
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	ldto_berp	a, 234
	ld	(xix), a
	ld	(xiy), 255
	jr	SndParam_RegisterSimple_Data_Join2
SndParam_RegisterSimple_Data_Skip3:
	ldw	(0x9734:16), 0xffff
SndParam_RegisterSimple_Data_Join2:
	ld	xhl, 0x9734
	pop	xiz
	inc	6, xsp
	ret
SndParam_DeregisterEntry_Data:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9740
	ld	bc, 6:i3
	ldirw
	lda	xhl, (0x9740:16)
	ldw	(xhl), 0xffff
	ret
SndParam_RegisterChained_Data:
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+18), de
	ld	de, bc
	ld	xhl, xwa
	lda	xwa, (xhl+4)
	ld	(xsp+14), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xiz, xbc, wa
	or xiz, xiz
	jrl	z, SndParam_RegisterChained_Data_Skip
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x974c
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xhl+5)
	ld	(xsp+10), xwa
	ld	a, (xwa)
	extz	wa
	lda_rr xix, xiz, wa
	ld a, (xix)
	ldfr_berp	a, 234
	extz	wa
	ld	(xsp+4), wa
	ld	bc, wa
	lda	xiy, (xhl+9)
	lda	xwa, (xhl+6)
	ld	(xsp+6), xwa
	ld	a, (xwa)
	ldfr_berp	a, 230
	extz	wa
	ld	qwa, wa
	and	wa, bc
	ld qwa, wa
	ld a, (xiy)
	ld bc, qwa
	and a, 15
	jr z, 2
	.byte 0xd9
	swi	5
	add	bc, de
	ld	a, (xhl+7)
	extz	wa
	cp	wa, bc
	jr	le, 2
	ld	bc, wa
	ld	a, (xhl+8)
	extz	wa
	cp	wa, bc
	jr	ge, 2
	ld	bc, wa
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda	xbc, (0x9752:16)
	cpw	(xsp+18), 4
	jr	nz, 24
	andb_erp	e, 234
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	or	l, e
	ld	(xbc), l
	jr	41
	ldto_berp	a, 234
	and	a, e
	ldfr_berp	a, 234
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	extz	wa
	lda_rr xhl, xiz, wa
	ld a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
	lda	xbc, (0x974c:16)
	ld	wa, (xsp+4)
	.byte 0x89, 0x06, 0xf1
	jr	z, 32
	ld	xwa, (xsp+14)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	SndParam_RegisterChained_Data_Join
SndParam_RegisterChained_Data_Skip:
	ldw	(0x974c:16), 0xffff
SndParam_RegisterChained_Data_Join:
	ld	xhl, 0x974c
	pop	xiz
	lda	xsp, (xsp+16)
	ret
SndParam_RegisterChained2_Data:
	lda	xsp, (xsp-14)
	push	xiz
	ld	(xsp+16), de
	ld	hl, bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+12), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xiz, xbc, wa
	or xiz, xiz
	jrl	z, SndParam_RegisterChained2_Data_Skip
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9758
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xde+5)
	ld	(xsp+8), xwa
	ld	a, (xwa)
	extz	wa
	lda_rr xix, xiz, wa
	ld a, (xix)
	ldfr_berp a, 238
	ldto_berp c, 238
	extz	bc
	lda	xiy, (xde+9)
	lda	xwa, (xde+6)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	ldfr_berp	a, 230
	extz	wa
	ld	qwa, wa
	and	wa, bc
	ld qwa, wa
	ld a, (xiy)
	ld bc, qwa
	and a, 15
	jr z, 2
	.byte 0xd9
	swi	5
	add	bc, hl
	ld	a, (xde+7)
	extz	wa
	cp	wa, bc
	jr	le, 2
	ld	bc, wa
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
	jr	ge, 2
	ld	bc, wa
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda	xbc, (0x975e:16)
	cpw	(xsp+16), 4
	jr	nz, 24
	andb_erp	e, 238
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	or	l, e
	ld	(xbc), l
	jr	41
	ldto_berp	a, 238
	and	a, e
	ldfr_berp	a, 238
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	extz	wa
	lda_rr xhl, xiz, wa
	ld a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
	lda	xbc, (0x9758:16)
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	SndParam_RegisterChained2_Data_Join
SndParam_RegisterChained2_Data_Skip:
	ldw	(0x9758:16), 0xffff
SndParam_RegisterChained2_Data_Join:
	ld	xhl, 0x9758
	pop	xiz
	lda	xsp, (xsp+14)
	ret
SndParam_RegisterComplex_Data:
	lda	xsp, (xsp-16)
	ld	(xsp+8), de
	ld	(xsp+10), bc
	ld	(xsp+12), xwa
	ld	xwa, (xsp+12)
	ld	a, (xwa+4)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xbc, wa
	ld (xsp), xwa
	or xwa, xwa
	jrl	z, SndParam_RegisterComplex_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9764
	ld	bc, 6:i3
	ldirw
	ld	xwa, (xsp+12)
	calr	SndParam_CompareRegField
	ld	xwa, (xsp+12)
	ld	a, (xwa+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld_rr8l	xbc, xbc, a
	cpw	(xsp+10), 0
	jr	lt, SndParam_RegisterComplex_Data_Skip3
	ld	a, (xbc)
	extz	wa
	ld	(xsp+10), wa
	jr	SndParam_RegisterComplex_Data_Join
SndParam_RegisterComplex_Data_Skip3:
	ld	a, (xbc)
	extz	wa
	sub	(xsp+10), wa
SndParam_RegisterComplex_Data_Join:
	add	hl, (xsp+10)
	ld	xwa, (xsp+12)
	ld	a, (xwa+7)
	extz	wa
	cp	wa, hl
	jr	le, SndParam_RegisterComplex_Data_Skip4
	ld	hl, wa
SndParam_RegisterComplex_Data_Skip4:
	ld	xwa, (xsp+12)
	ld	a, (xwa+8)
	extz	wa
	cp	wa, hl
	jr	ge, SndParam_RegisterComplex_Data_Skip5
	ld	hl, wa
SndParam_RegisterComplex_Data_Skip5:
	ld	e, (xbc)
	extz	de
	ld	xwa, 1:i3
	cp	hl, de
	jr	lt, SndParam_RegisterComplex_Data_Skip
	ld	xwa, 2:i3
SndParam_RegisterComplex_Data_Skip:
	ld	xde, xbc
	add	xde, xwa
	ld	d, (xde)
	ld	xiy, (xsp+12)
	lda	xwa, (xiy+5)
	ld	(xsp+4), xwa
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	ld_rrb a, xwa, hl
	ldfr_berp a, 234
	lda xix, (38756:16)
	lda xhl, (xix+6)
	ldto_berp e, 234
	ld a, e
	ld	(xhl), a
	ld	a, (xiy+9)
	and	a, 15
	jr	z, 2
	.byte 0xcc
	swi	6
	ld	a, (xiy+10)
	xor	a, d
	ldfr_berp a, 235
	inc 6, xiy
	ld	w, (xiy)
	ld	d, w
	andb_erp	d, 235
	cpl	w
	and	e, w
	ld	a, e
	ld	(xhl), a
	or	e, d
	ld	(xhl), e
	ldto_berp	a, 234
	cp	a, e
	jr	z, SndParam_RegisterComplex_Data_Join3
	cpw	(xsp+8), 4
	jr	z, SndParam_RegisterComplex_Data_Skip6
	ld	xwa, (xsp+4)
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp)
	st_rrb	e, xwa, bc
	jr	SndParam_RegisterComplex_Data_Join2
SndParam_RegisterComplex_Data_Skip6:
	cp	(xbc+6), 1
	jr	nz, SndParam_RegisterComplex_Data_Join2
	ld	a, (xiy)
	ld	(xhl), a
SndParam_RegisterComplex_Data_Join2:
	ld	xwa, (xsp+12)
	ld	a, (xwa+4)
	ld	(xix+4), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xix+5), a
	ld	a, (xiy)
	ld	(xix+7), a
	jr	SndParam_RegisterComplex_Data_Join3
SndParam_RegisterComplex_Data_Skip2:
	ldw	(0x9764:16), 0xffff
SndParam_RegisterComplex_Data_Join3:
	ld	xhl, 0x9764
	lda	xsp, (xsp+16)
	ret
SndParam_NotifyQuick_Data:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), bc
	ld	xiz, xwa
	ld	a, (xiz+4)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xbc, wa
	or xwa, xwa
	jr	z, SndParam_NotifyQuick_Data_Skip3
	ld	xwa, xiz
	calr	SndParam_ReadRegWord
	ld	bc, hl
	add	bc, (xsp+6)
	ld	a, (xiz+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_NotifyQuick_Data_Skip
	ld	bc, wa
SndParam_NotifyQuick_Data_Skip:
	ld	a, (xiz+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_NotifyQuick_Data_Skip2
	ld	bc, wa
SndParam_NotifyQuick_Data_Skip2:
	ld	xwa, xiz
	ld	de, (xsp+4)
	calr	SndParam_RegisterBitfield_Data
	ld	(0x9770:16), xhl
SndParam_NotifyQuick_Data_Skip3:
	ld	xhl, (0x9770:16)
	pop	xiz
	inc	4, xsp
	ret
SndParam_RegisterDual_Data:
	lda	xsp, (xsp-20)
	ld	(xsp+16), de
	ld	(xsp+18), bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+12), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xbc, wa
	ld (xsp), xwa
	or xwa, xwa
	jrl	z, SndParam_RegisterDual_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9774
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xde+5)
	ld	(xsp+8), xwa
	ld	c, (xwa)
	extz	bc
	lda	xwa, (xde+6)
	ld	(xsp+4), xwa
	ld	l, (xwa)
	ld	h, l
	ld	xwa, (xsp)
	ld_rrb a, xwa, bc
	ldfr_berp a, 238
	andb_erp h, 238
	ld	c, h
	ld	h, (xde+9)
	ld	a, h
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	7
	ld	w, c
	lda	xbc, (SndParam_ResetDefaultTable_Data_2:24)
	ld	a, (xde+11)
	cp	a, 255
	jr	z, 10
	sla	a, 2
	ld_rr8l xiy, xbc, a
	jr 2
	ld	xiy, (xbc)
	ld	a, w
	extz	wa
	ld	xix, xiy
	ld	w, a
	ld	de, 0:i3
	cpw	(xiy+4), 0
	jr	le, 20
	ld	xbc, (xix)
	.byte 0xc3
	reti
	.byte 0xe4
	cp	xwa, xwa
	jr	nz, 4
	ld	wa, de
	jr	10
	inc	1, de
	.byte 0x9c, 0x04, 0xf2
	jr	lt, -20
	ld	wa, (xix+7)
	add	wa, (xsp+18)
	ld	xde, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, 6
	ld	xwa, (xde)
	ld	e, (xwa)
	jr	SndParam_RegisterDual_Data_Join
	ld	wa, (xde+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterDual_Data_Skip
	ld	xwa, (xde)
	ld_rrb e, xwa, bc
	jr SndParam_RegisterDual_Data_Join
SndParam_RegisterDual_Data_Skip:
	ld bc, wa
	dec	1, bc
	ld	xwa, (xde)
	ld_rrb e, xwa, bc
SndParam_RegisterDual_Data_Join:
	ldto_berp b, 238
	ldto_berp	a, 238
	ldfr_berp	a, 230
	cpl	l
	ldto_berp	a, 230
	and	a, l
	ldfr_berp a, 230
	ld a, h
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ldto_berp	a, 230
	or	a, e
	ldfr_berp	a, 230
	lda	xde, (0x9774:16)
	ldto_berp	a, 230
	ld	(xde+6), a
	cpw	(xsp+16), 4
	jr	z, 17
	ld	xwa, (xsp+8)
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	ldto_berp c, 230
	st_rrb c, xwa, hl
	ldto_berp a, 230
	cp a, b
	jr	z, SndParam_RegisterDual_Data_Join2
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xde+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xde+7), a
	jr	SndParam_RegisterDual_Data_Join2
SndParam_RegisterDual_Data_Skip2:
	ldw	(0x9774:16), 0xffff
SndParam_RegisterDual_Data_Join2:
	ld	xhl, 0x9774
	lda	xsp, (xsp+20)
	ret
SndParam_RegisterOffset_Data:
	lda	xsp, (xsp-10)
	pushw	iz
	ld	(xsp+8), de
	ld	(xsp+10), bc
	lda	xde, (xwa+4)
	ld	a, (xde)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl xwa, xbc, wa
	or xwa, xwa
	jrl	z, SndParam_RegisterOffset_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9780
	ld	bc, 6:i3
	ldirw
	lda	xiy, (xwa+8)
	ld	iz, (xiy)
	ld	bc, iz
	and	bc, 511
	add	bc, (xsp+10)
	cp	bc, 40
	jr	ge, SndParam_RegisterOffset_Data_Skip
	ldw	bc, 40
	jr	SndParam_RegisterOffset_Data_Join
SndParam_RegisterOffset_Data_Skip:
	cp	bc, 300
	jr	le, SndParam_RegisterOffset_Data_Join
	ldw	bc, 300
SndParam_RegisterOffset_Data_Join:
	ld	a, c
	ld	(xsp+2), a
	ld	a, (xde)
	ldfr_berp	a, 230
	lda	xwa, (0x9780:16)
	lda	xde, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	inc	7, xwa
	ld	(xsp+4), xwa
	cpw	(xsp+8), 4
	jr	nz, SndParam_RegisterOffset_Data_Skip2
	cp	iz, bc
	jr	z, SndParam_RegisterOffset_Data_Join2
	ldto_berp	a, 230
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	sra	bc, 8
	and	bc, 1
	ld	xwa, (xsp+4)
	ld	(xwa), c
	jr	SndParam_RegisterOffset_Data_Join2
SndParam_RegisterOffset_Data_Skip2:
	ld	(xiy), bc
	cp	iz, bc
	jr	z, SndParam_RegisterOffset_Data_Join2
	ldto_berp	a, 230
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	ld	xwa, (xsp+4)
	ld	(xwa), 255
	jr	SndParam_RegisterOffset_Data_Join2
SndParam_RegisterOffset_Data_Skip3:
	ldw	(0x9780:16), 0xffff
SndParam_RegisterOffset_Data_Join2:
	ld	xhl, 0x9780
	popw	iz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterWide_Data:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+22), de
	ld	(xsp+24), bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+18), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_DMA_Zone2Check_Data:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterWide_Data_Skip4
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x978c
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xde+5)
	ld	(xsp+14), xwa
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp+4)
	lda_rr xix, xwa, bc
	ld l, (xix)
	ld	c, l
	extz	bc
	ld	(xsp+8), bc
	lda	xiy, (xde+9)
	lda	xwa, (xde+6)
	ld	(xsp+10), xwa
	ld	a, (xwa)
	ldfr_berp	a, 230
	extz	wa
	ld	iz, wa
	and	iz, bc
	ld	a, (xiy)
	ld	bc, iz
	and	a, 15
	jr	z, 2
	.byte 0xd9
	swi	5
	.byte 0x9f
	push_f
	add	(xbc), b
	reti
	ld	a, 216:opc
	ccf
	cp	wa, bc
	jr	le, 2
	ld	bc, wa
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
	jr	ge, 2
	ld	bc, wa
	ld	xwa, (xsp+18)
	ld	h, (xwa)
	lda	xiz, (0x978c:16)
	lda	xde, (xiz+6)
	cpw	(xsp+22), 4
	jr	nz, SndParam_RegisterWide_Data_Skip3
	ld	xbc, xiz
	ld	(xiz+4), h
	ld	xwa, (xsp+14)
	ld	a, (xwa)
	ld	(xiz+5), a
	lda	xwa, (xiz+7)
	cpw	(xsp+24), 0
	jr	le, SndParam_RegisterWide_Data_Skip
	ld	(xwa), 2
	ld	(xde), 2
	jr	SndParam_RegisterWide_Data_Join
SndParam_RegisterWide_Data_Skip:
	cpw	(xsp+24), 0
	jr	ge, SndParam_RegisterWide_Data_Skip2
	ld	(xwa), 1
	ld	(xde), 1
	jr	4
SndParam_RegisterWide_Data_Skip2:
	ldw	(xbc), 0xffff
SndParam_RegisterWide_Data_Join:
	ld	xhl, xbc
	jr	79
SndParam_RegisterWide_Data_Skip3:
	ldto_berp	w, 230
	cpl	w
	and	l, w
	ld	(xix), l
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcb
	swi	6
	ld	l, c
	ld	xiy, (xsp+14)
	ld	c, (xiy)
	extz	bc
	ld	xwa, (xsp+4)
	lda_rr xix, xwa, bc
	ld c, (xix)
	or	c, l
	ld	(xix), c
	ld	(xde), c
	ld	wa, (xsp+8)
	cp	a, c
	jr	z, SndParam_RegisterWide_Data_Join2
	ld	(xiz+4), h
	ld	a, (xiy)
	ld	(xiz+5), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xiz+7), a
	jr	SndParam_RegisterWide_Data_Join2
SndParam_RegisterWide_Data_Skip4:
	ldw	(0x978c:16), 0xffff
SndParam_RegisterWide_Data_Join2:
	ld	xhl, 0x978c
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SndParam_EncodeFieldDirect_Data:
	ld	de, bc
	ld	xbc, xwa
	ld	l, e
	ld	a, (xbc+7)
	cp	a, l
	jr	ule, 2
	ld	l, a
	ld	a, (xbc+8)
	cp	a, l
	jr	nc, 2
	ld	l, a
	ld	a, (xbc+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	ld	a, (xbc+10)
	xor	a, l
	ld	l, (xbc+6)
	and	l, a
	extz	hl
	ret
SndParam_EncodeFieldSub_Data:
	ld	hl, bc
	ld	xbc, xwa
	ld	a, (xbc+11)
	sla	a, 2
	lda	xde, (Naka_SubDispatch_B_Table:24)
	ld_rr8l	xde, xde, a
	ld	xwa, 1:i3
	cp	l, (xde)
	jr	c, 2
	ld	xwa, 2:i3
	add	xde, xwa
	ld	l, (xde)
	ld	a, (xbc+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	ld	a, (xbc+10)
	xor	a, l
	ld	l, (xbc+6)
	and	l, a
	extz	hl
	ret
SndParam_ClampReverbTime:
	ld	xwa, (SndParam_ClampReverbTime_Data:24)
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, 5
	ldw	hl, 40
	jr	SndParam_ClampReverbTime_Return
	cp	hl, 300
	ret	ule
	ldw	hl, 300
SndParam_ClampReverbTime_Return:
	ret
SndParam_DecodeField_Data:
	ld	hl, bc
	ld	xde, xwa
	ld	c, (xde+6)
	ld	a, (xde+10)
	xor	a, l
	and	a, c
	ld	l, a
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	7
	ld	a, (xde+7)
	cp	a, l
	jr	ule, 2
	ld	l, a
	ld	a, (xde+8)
	cp	a, l
	jr	nc, 2
	ld	l, a
	extz	hl
	ret
SndParam_DecodeFieldAlt_Data:
	ld	hl, bc
	ld	xde, xwa
	ld	c, (xde+6)
	ld	a, (xde+10)
	xor	a, l
	and	a, c
	ld	l, a
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	7
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld_rr8l	xbc, xbc, a
	cp	l, (xbc+1)
	jr	nz, 4
	ld	xwa, 3:i3
	jr	9
	ld	xwa, 5:i3
	cp	l, (xbc+2)
	jr	nz, 2
	ld	xwa, 4:i3
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret
SndParam_ClampDelayTime:
	ld	xwa, (SndParam_ClampReverbTime_Data:24)
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, SndParam_ClampDelayTime_Skip
	ldw	hl, 40
	jr	SndParam_ClampDelayTime_Return
SndParam_ClampDelayTime_Skip:
	cp	hl, 300
	ret	ule
	ldw	hl, 300
SndParam_ClampDelayTime_Return:
	ret
SndParam_ReturnInvalid:
	ldw	hl, 0xffff
	ret
SndParam_WriteFieldDirect_Data:
	dec	4, xsp
	ld	hl, bc
	ld	xde, xwa
	lda	xbc, (xsp)
	ld	a, (xde+4)
	ld	(xbc), a
	ld	a, (xde+5)
	ld	(xbc+1), a
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xdb
	swi	4
	ld	a, (xde+10)
	extz	wa
	ld	ix, wa
	xor	ix, hl
	inc	6, xde
	ld	a, (xde)
	extz	wa
	and	wa, ix
	ld	(xbc+2), a
	ld	a, (xde)
	ld	(xbc+3), a
	ld	xwa, xbc
	calr	SndParam_WriteFieldDirect_Data_Helper
	ld	hl, 0:i3
	inc	4, xsp
	ret
SndParam_WriteFieldSub_Data:
	dec	4, xsp
	ld	hl, bc
	ld	xde, xwa
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld_rr8l	xbc, xbc, a
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, 2
	ld	xwa, 2:i3
	add	xbc, xwa
	ld	l, (xbc)
	lda	xbc, (xsp)
	ld	a, (xde+4)
	ld	(xbc), a
	ld	a, (xde+5)
	ld	(xbc+1), a
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	ld	a, (xde+10)
	xor	a, l
	ld	l, a
	inc	6, xde
	ld	a, (xde)
	and	a, l
	ld	(xbc+2), a
	ld	a, (xde)
	ld	(xbc+3), a
	ld	xwa, xbc
	calr	354
	ld	hl, 0:i3
	inc	4, xsp
	ret
SndParam_PackAndWrite:
	dec	4, xsp
	lda	xhl, (xsp)
	ld	e, (xwa+4)
	ld	(xhl), e
	ld	a, (xwa+5)
	ld	(xhl+1), a
	ld	wa, bc
	and	wa, 127
	ld	(xhl+2), a
	sra	bc, 7
	and	bc, 127
	ld	(xhl+3), c
	ld	xwa, xhl
	calr	SndParam_WriteFieldDirect_Data_Helper
	ld	hl, 0:i3
	inc	4, xsp
	ret
SndParam_WriteViaHash_Data:
	ld	a, (xwa+4)
	extz	wa
	add	wa, wa
	lda	xde, (0x9798:16)
	st_rrw	bc, xde, wa
	ld	hl, 0:i3
	ret
SndParam_BatchUpdate_Data:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), bc
	ld	(xsp+22), xwa
	ldib_erp 250, 0
	ldib_erp 249, 0
	ldib_erp 251, 0
	ld	xwa, 8705
	calr	SndParam_LookupReadOnly
	ld	wa, (xsp+20)
	ld	d, a
	lda	xix, (0x9798:16)
	ld	xwa, (xsp+22)
	lda	xbc, (xwa+4)
	cp	hl, 3:i3
	jr	z, SndParam_BatchUpdate_Data_Skip2
	cp	hl, 1:i3
	jr	z, SndParam_BatchUpdate_Data_Skip
	cp	hl, 0:i3
	jrl	nz, SndParam_BatchUpdate_Data_Join
	lda	xwa, (xsp+10)
	ld	e, (xbc)
	ld	(xwa+2), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	ld_rrw bc, xix, bc
	and bc, 127
	ld	(xwa+4), c
	call	SndParam_FetchOscTableEntry
	lda	xbc, (xsp+10)
	ld	a, (xbc+1)
	ldfr_berp a, 250
	res_erpb 250, 7
	srl a, 7
	ldfr_berp a, 249
	ld a, (xbc)
	ldfr_berp a, 251
	bit_erpb 251, 7
	jr z, SndParam_BatchUpdate_Data_Join
	res_erpb 251, 7
	inc1b_erp 250
	jr SndParam_BatchUpdate_Data_Join
SndParam_BatchUpdate_Data_Skip:
	ld	a, (xbc)
	extz	wa
	add	wa, wa
	ld_rrw wa, xix, wa
	and wa, 7
	sll	a, 4
	ldfr_berp a, 250
	ldib_erp 249, 0
	ldfr_berp d, 251
	bit	7, d
	jr	z, SndParam_BatchUpdate_Data_Join
	res_erpb 251, 7
	ldib_erp 249, 1
	jr	SndParam_BatchUpdate_Data_Join
SndParam_BatchUpdate_Data_Skip2:
	lda	xwa, (xsp+4)
	ld	e, (xbc)
	ld	(xwa+5), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	ld_rrw bc, xix, bc
	and bc, 127
	ld	(xwa+4), c
	call	SndParam_ComputeVoiceIndex
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	ldfr_berp	a, 250
	ld	a, (xbc+1)
	ldfr_berp	a, 249
	ld	a, (xbc+2)
	ldfr_berp	a, 251
SndParam_BatchUpdate_Data_Join:
	lda	xwa, (xsp+16)
	ld	(xwa), 129
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa+1), c
	ldto_berp	c, 250
	ld	(xwa+2), c
	ldto_berp	c, 249
	ld	(xwa+3), c
	calr	SndParam_WriteFieldDirect_Data_Helper
	lda	xwa, (xsp+16)
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa), c
	ld	(xwa+1), 0
	ldto_berp	c, 251
	ld	(xwa+2), c
	ld	(xwa+3), 255
	calr	SndParam_WriteFieldDirect_Data_Helper
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SndParam_WriteFieldDirect_Data_Helper:
	ld	c, (xwa)
	ld	b, (xwa+1)
	ld	e, (xwa+2)
	ld	d, (xwa+3)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret

SndParam_WidgetNotifyType0:
	cp (xbc + 4), 0x48
	jr nz, SndParam_WidgetCheckDirty
	cp (xbc + 5), 0x8
	jr nz, SndParam_WidgetCheckDirty
	cp wa, 4:i3
	jr z, SndParam_WidgetCallHandler

SndParam_WidgetCheckDirty:
	cp (xbc + 7), 0x0
	ret z

SndParam_WidgetCallHandler:
	calr SndParam_WidgetDispatch
	ret

SndParam_WidgetDispatch:
	push xiz
	ld xiz, xbc
	ld hl, wa
	ld a, (xiz + 7)
	ldfr_berp A, 0xf0
	extz ix
	ld e, (xiz + 6)
	extz de
	ld c, (xiz + 5)
	extz bc
	ld a, (xiz + 4)
	extz wa
	cp hl, 4:i3
	jr z, SndParam_WidgetCallType4
	cp hl, 3:i3
	jr z, SndParam_WidgetCallType3
	cp hl, 2:i3
	jr z, SndParam_WidgetAppendType2
	cp hl, 1:i3
	jr nz, SndParam_WidgetDispatchDone
	cpw (0x90de:16), 508
	call nc, (SwbtWr_ReinitBothBanks:24)
	lda xbc, (0xbd3c:16)
	ld de, (0x90de:16)
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	ld (xde+), a
	ld a, (xiz + 5)
	ld (xde+), a
	ld a, (xiz + 6)
	ld (xde+), a
	ld a, (xiz + 7)
	ld (xde+), a
	jr SndParam_WidgetAppendTail

SndParam_WidgetAppendType2:
	cpw (0x90de:16), 508
	call nc, (SwbtWr_ReinitOutputBank:24)
	lda xbc, (0xbd3c:16)
	ld de, (0x90de:16)
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	ld (xde+), a
	ld a, (xiz + 5)
	ld (xde+), a
	ld a, (xiz + 6)
	ld (xde+), a
	ld a, (xiz + 7)
	ld (xde+), a

SndParam_WidgetAppendTail:
	ld (xde), 0xff
	incw 4, (0x90de:16)
	jr SndParam_WidgetDispatchDone

SndParam_WidgetCallType3:
	pushw ix
	call AddswbWr
	jr SndParam_WidgetDispatchDone

SndParam_WidgetCallType4:
	pushw ix
	call SwbtWr

SndParam_WidgetDispatchDone:
	pop xiz
	ret

SndParam_WidgetNotifyType1:
	push xiz
	ld xiz, xbc
	ld e, (xiz + 7)
	cp e, 0:i3
	jrl z, SndParam_Widget1_Done
	lda xiy, (xiz + 6)
	ldfr_berp E, 0xf0
	extz ix
	ld c, (xiz + 5)
	extz bc
	ld l, (xiz + 4)
	extz hl
	cp wa, 4:i3
	jrl z, SndParam_Widget1_CallType4
	cp wa, 3:i3
	jrl z, SndParam_Widget1_CallType3
	cp wa, 2:i3
	jr z, SndParam_Widget1_AppendType2
	cp wa, 1:i3
	jrl nz, SndParam_Widget1_Done
	cpw (0x90de:16), 504
	call nc, (SwbtWr_ReinitBothBanks:24)
	lda xbc, (0xbd3c:16)
	ld de, (0x90de:16)
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	ld (xde+), a
	ld a, (xiz + 5)
	ld (xde+), a
	ld a, (xiz + 6)
	ld (xde+), a
	ld a, (xiz + 7)
	ld (xde+), a
	ld a, (xiz + 8)
	ld (xde+), a
	ld a, (xiz + 9)
	ld (xde+), a
	ld a, (xiz + 10)
	ld (xde+), a
	ld a, (xiz + 11)
	ld (xde+), a
	jr SndParam_Widget1_AppendTail

SndParam_Widget1_AppendType2:
	cpw (0x90de:16), 504
	call nc, (SwbtWr_ReinitOutputBank:24)
	lda xbc, (0xbd3c:16)
	ld de, (0x90de:16)
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	ld (xde+), a
	ld a, (xiz + 5)
	ld (xde+), a
	ld a, (xiz + 6)
	ld (xde+), a
	ld a, (xiz + 7)
	ld (xde+), a
	ld a, (xiz + 8)
	ld (xde+), a
	ld a, (xiz + 9)
	ld (xde+), a
	ld a, (xiz + 10)
	ld (xde+), a
	ld a, (xiz + 11)
	ld (xde+), a

SndParam_Widget1_AppendTail:
	ld (xde), 0xff
	incw 8, (0x90de:16)
	jr SndParam_Widget1_Done

SndParam_Widget1_CallType3:
	ld e, (xiy)
	extz de
	pushw ix
	ld wa, hl
	call AddswbWr
	ld a, (xiz + 8)
	extz wa
	ld c, (xiz + 9)
	extz bc
	ld e, (xiz + 10)
	extz de
	ld l, (xiz + 11)
	extz hl
	pushw hl
	call AddswbWr
	jr SndParam_Widget1_Done

SndParam_Widget1_CallType4:
	and e, (xiy)
	extz de
	pushw ix
	ld wa, hl
	call SwbtWr
	ld a, (xiz + 8)
	extz wa
	ld c, (xiz + 9)
	extz bc
	ld l, (xiz + 11)
	ld e, l
	and e, (xiz + 10)
	extz de
	extz hl
	pushw hl
	call SwbtWr

SndParam_Widget1_Done:
	pop xiz
	ret

SndParam_BinarySearch:
	ld	iy, 0:i3
	ld	ix, de
	sub	ix, 1
	jr	c, SndParam_WidgetNotifyType1_Skip3
SndParam_WidgetNotifyType1_Loop:
	ld	hl, iy
	add	hl, ix
	srl	hl, 1
	ld	de, hl
	extz	xde
	add	xde, xbc
	ld	e, (xde)
	cp	a, e
	jr	nz, SndParam_WidgetNotifyType1_Skip
	ld	hl, 0:i3
	ret
SndParam_WidgetNotifyType1_Skip:
	cp	a, e
	jr	ule, SndParam_WidgetNotifyType1_Skip2
	ld	iy, hl
	inc	1, iy
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip2:
	ld	ix, hl
	dec	1, ix
SndParam_WidgetNotifyType1_Join:
	cp	iy, ix
	jr	ule, SndParam_WidgetNotifyType1_Loop
SndParam_WidgetNotifyType1_Skip3:
	ldw	hl, 0xffff
	ret

SndParam_EncodeAddress:
	ld xhl, 0x8000
	and wa, 0x3f
	sll wa, 10
	extz xwa
	add xhl, xwa
	ld wa, bc
	and wa, 0x3ff
	extz xwa
	or xhl, xwa
	cp bc, 0x400
	ret c
	add xhl, 0x10000
	ret

SndParam_InitHashTable:
	lda xbc, (0x034100:24)
	ld xwa, xbc
	lda xde, (xbc+16376)

SndParam_InitHashFillLoop:
	ld xiy, SndParam_InitHashFillLoop_Data
	ld xix, xwa
	ld bc, 4:i3
	ldirw
	inc 8, xwa
	cp xwa, xde
	jr c, SndParam_InitHashFillLoop
	ret

SndParam_RegisterAllWidgets:
	push xiz
	ld xiz, 0:i3

SndParam_RegisterLoop:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, SndParam_RegisterLoop_Data
	add xwa, xbc
	ld xbc, (xwa)
	ld xwa, (xbc)
	calr SndParam_InsertEntry
	inc 1, xiz
	cp xiz, 0x3cc
	jr c, SndParam_RegisterLoop
	pop xiz
	ret

SndParam_InsertEntry:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xbc
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 16
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32

SndParam_InsertProbe:
	ld wa, hl
	extz xwa
	sll xwa, 3
	ld xbc, 0x34100
	add xbc, xwa
	ld xde, (xbc)
	cp xde, NakaData_RomEnd
	jr nz, SndParam_InsertCheckKey
	ld (xbc), xiz
	ld xwa, (xsp + 6)
	ld (xbc + 4), xwa
	ld hl, 0:i3
	jr SndParam_InsertReturn

SndParam_InsertCheckKey:
	ld wa, 0:i3
	cp xiz, xde
	jr z, SndParam_InsertKeyMatch
	ldw wa, 0xffff

SndParam_InsertIncSlot:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x7ff
	jr ule, SndParam_InsertNextSlot
	jr SndParam_InsertFail

SndParam_InsertKeyMatch:
	cp wa, 0xffff
	jr z, SndParam_InsertIncSlot
	jr SndParam_InsertFail

SndParam_InsertNextSlot:
	inc 3, hl
	extz xhl
	div hl, 0x7ff
	ldto_werp WA, 0xee
	ld hl, wa
	cp wa, 0x7ff
	jr c, SndParam_InsertProbe

SndParam_InsertFail:
	ldw hl, 0xffff

SndParam_InsertReturn:
	pop xiz
	inc 6, xsp
	ret

SndParam_ClearHashTable:
	lda xwa, (0x97d8:16)
	ld xbc, xwa
	lda xde, (xwa+8188)

SndParam_ClearLoop:
	ld xwa, 0:i3
	ld (xbc+), XWA
	cp xbc, xde
	jr c, SndParam_ClearLoop
	lda xde, (0x0380f8:24)
	lda xbc, (xde + 2)
	ld xwa, xbc
	lda xbc, (xbc+16384)

SndParam_ClearHeap:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SndParam_ClearHeap
	ldw (xde), 0x0
	ret

SndParam_ReregisterAll:
	push xiz
	ld xiz, 0:i3

SndParam_ReregisterLoop:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, SndParam_RegisterLoop_Data
	add xwa, xbc
	ld xhl, (xwa)
	ld a, (xhl + 4)
	ld c, (xhl + 5)
	ld e, (xhl + 6)
	push xhl
	calr SndParam_AllocAndInsert
	inc 1, xiz
	cp xiz, 0x3cc
	jr c, SndParam_ReregisterLoop
	pop xiz
	ret

SndParam_AllocAndInsert:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), e
	ld (xsp + 18), c
	ld (xsp + 20), a
	ldw wa, 0xc
	calr SndParam_HeapAlloc
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	or xwa, xwa
	jr nz, SndParam_AllocBuildKey
	ld xwa, SndParam_AllocAndInsert_Data
	call Debug_PrintString
	pushw 0x1
	call Boot_HaltInstruction
	inc 2, xsp

SndParam_AllocBuildKey:
	ld xde, 0:i3
	ld e, (xsp + 18)
	sll xde, 8
	ld xwa, 0:i3
	ld a, (xsp + 20)
	sll xwa, 16
	ld xbc, xwa
	or xbc, xde
	ld xwa, 0:i3
	ld a, (xsp + 16)
	ld (xsp + 12), xwa
	or (xsp + 12), xbc
	ld xde, (xsp + 12)
	srl xde, 8
	ld xhl, xde
	and xhl, 0xf
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 4
	and xhl, 0xf
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 8
	and xhl, 0xf
	add xhl, xwa
	ld xbc, xhl
	sll xbc, 9
	add xbc, xhl
	srl xde, 12
	ld xhl, xde
	and xhl, 0xf
	add xhl, xbc
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld bc, hl
	sll hl, 2
	lda xde, (0x97d8:16)
	ld iy, hl
	extz xiy
	add xiy, xde
	ld xwa, (xsp + 8)
	lda xhl, (xwa + 4)
	ld xwa, (xsp + 4)
	lda xix, (xwa + 8)
	ld xiz, (xsp + 26)
	sll bc, 2
	extz xbc
	add xbc, xde
	ld xwa, (xiy)
	or xwa, xwa
	jr nz, SndParam_AllocChainExisting
	ld xwa, (xsp + 8)
	ld xde, (xsp + 12)
	ld (xwa), xde
	ld (xhl), xiz
	ld xwa, (xbc)
	ld (xix), xwa
	ld xwa, (xsp + 4)
	ld (xbc), xwa
	jr SndParam_AllocSuccess

SndParam_AllocChainExisting:
	ld xde, (xbc)
	ld xwa, (xde + 8)
	or xwa, xwa
	jr z, SndParam_AllocAppendToChain

SndParam_AllocChainLoop:
	ld xde, (xde + 8)
	ld xwa, (xde + 8)
	or xwa, xwa
	jr nz, SndParam_AllocChainLoop

SndParam_AllocAppendToChain:
	ld xiy, (xsp + 4)
	ld xbc, (xsp + 12)
	ld (xiy), xbc
	ld (xhl), xiz
	lda xbc, (xde + 8)
	ld xwa, (xbc)
	ld (xix), xwa
	ld (xbc), xiy

SndParam_AllocSuccess:
	ld hl, 0:i3
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x4

SndParam_HeapAlloc:
	cp wa, 0:i3
	jr z, SndParam_HeapAllocFail
	lda xbc, (0x0380f8:24)
	ld de, (xbc)
	add de, wa
	cp de, 0x4000
	jr c, SndParam_HeapAllocOK

SndParam_HeapAllocFail:
	ld xhl, 0:i3
	ret

SndParam_HeapAllocOK:
	ld de, (xbc)
	extz xde
	inc 2, xde
	ld xhl, xbc
	add xhl, xde
	add (xbc), wa
	ret

