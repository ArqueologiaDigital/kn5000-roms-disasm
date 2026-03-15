; =============================================================================
; Sound Parameter Routines
; =============================================================================
;
; Sound parameter probe, match, and heap allocation. Provides
; lookup and comparison services for sound preset data.
; =============================================================================

SndParam_ProbeCheckMatch:
	lds bc, 0
	cp xiz, xde
	jr z, SndParam_ProbeMatchFound
	ldw bc, 0xFFFF
	jr SndParam_ProbeAdvance

SndParam_ProbeMatchFound:
	cp bc, 0xFFFF
	jr z, SndParam_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7FF
	jr ugt, SndParam_DispatchCallback
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7FF
	ldto_werp IX, 0xE2

SndParam_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, 0xFFFFFF
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
	lda_24 xde, 0xee10ec
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld bc, (xsp + 12)
	ld de, (xsp + 10)
	ld xhl, (xhl)
	call (xhl)
	ld xbc, xhl
	cpw (xbc), 0xFFFF
	jr z, SndParam_NotFound
	ld wa, (xbc + 2)
	cps wa, 1
	jr z, SndParam_CallbackType1
	cps wa, 0
	jr nz, SndParam_Epilogue
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType0
	jr SndParam_Epilogue

SndParam_CallbackType1:
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType1
	jr SndParam_Epilogue

SndParam_NotFound:
	ldw (xsp + 4), 0xFFFF

SndParam_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 10)
	ret

SndParam_DispatchTypeDE5:
	ld c, (xwa + 16)
	cps c, 6
	jr nc, SndParam_Epilogue
	extz bc
	sla bc, 2
	lda_24 xde, 0xee1148
	st_dri3b B, 0x07, 0xE8, 0xE4
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
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xFF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xFF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1F
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32
	ld ix, hl
	jr SndParam_Lkp2_ProbeEntry

SndParam_Lkp2_ProbeCheck:
	lds bc, 0
	cp xiz, xde
	jr z, SndParam_Lkp2_MatchFound
	ldw bc, 0xFFFF
	jr SndParam_Lkp2_ProbeAdvance

SndParam_Lkp2_MatchFound:
	cp bc, 0xFFFF
	jr z, SndParam_Lkp2_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_Lkp2_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7FF
	jr ugt, SndParam_Lkp2_Dispatch
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7FF
	ldto_werp IX, 0xE2

SndParam_Lkp2_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, 0xFFFFFF
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
	lda_24 xbc, 0xee1110
	st_dri3b C, 0x07, 0xE4, 0xE0
	ld xwa, (xsp + 6)
	ld bc, (xsp + 12)
	ld de, (xsp + 10)
	ld xhl, (xhl)
	call (xhl)
	ld xbc, xhl
	cpw (xbc), 0xFFFF
	jr z, SndParam_Lkp2_NotFound
	ld wa, (xbc + 2)
	cps wa, 1
	jr z, SndParam_Lkp2_CallType1
	cps wa, 0
	jr nz, SndParam_Lkp2_Epilogue
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType0
	jr SndParam_Lkp2_Epilogue

SndParam_Lkp2_CallType1:
	ld wa, (xsp + 10)
	calr SndParam_WidgetNotifyType1
	jr SndParam_Lkp2_Epilogue

SndParam_Lkp2_NotFound:
	ldw (xsp + 4), 0xFFFF

SndParam_Lkp2_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 10)
	ret

SndParam_WrapNotify2:
	pushw	iz
	ld	iz, de
	calr	6742
	ld	xwa, xhl
	ld	bc, iz
	ld	de, (xsp+6)
	calr	65276
	popw	iz
	retd	2

SndParam_LookupReadOnly:
	dec 6, xsp
	push xiz
	ldw (xsp + 4), 0xFFFF
	ld xiz, xwa
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xFF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xFF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1F
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32
	ld ix, hl
	jr SndParam_RO_ProbeEntry

SndParam_RO_ProbeCheck:
	lds bc, 0
	cp xiz, xde
	jr z, SndParam_RO_MatchFound
	ldw bc, 0xFFFF
	jr SndParam_RO_ProbeAdvance

SndParam_RO_MatchFound:
	cp bc, 0xFFFF
	jr z, SndParam_RO_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 6), xwa

SndParam_RO_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7FF
	jr ugt, SndParam_RO_Dispatch
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7FF
	ldto_werp IX, 0xE2

SndParam_RO_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, 0xFFFFFF
	jr nz, SndParam_RO_ProbeCheck

SndParam_RO_Dispatch:
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, SndParam_RO_Epilogue
	ld a, (xwa + 12)
	cps a, 7
	jr nc, SndParam_RO_Epilogue
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee10d0
	st_dri3b A, 0x07, 0xE4, 0xE0
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
	ldb b, 0x0
	extz xbc
	sll xbc, 8
	ldb h, 0x0
	extz xhl
	sll xhl, 0
	or xhl, xbc
	ldb d, 0x0
	extz xde
	ld xiz, xde
	or xiz, xhl
	ld xde, xiz
	srl xde, 8
	ld xhl, xde
	and xhl, 0xF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 4
	and xhl, 0xF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 8
	and xhl, 0xF
	add xhl, xwa
	ld xbc, xhl
	sll xbc, 9
	add xbc, xhl
	srl xde, 12
	ld xhl, xde
	and xhl, 0xF
	add xhl, xbc
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32
	sll hl, 2
	ldada xwa, 38872
	extz xhl
	add xhl, xwa
	ld xde, (xhl)
	or xde, xde
	jrl z, SndParam_RW_NoEntry
	ld xix, (xde)
	ldw hl, 0xFFFF
	ld xwa, xix
	srl xwa, 8
	ld xbc, xiz
	srl xbc, 8
	cp xbc, xwa
	jr nz, SndParam_RW_CheckFirstMatch
	ld xwa, xiz
	srl xwa, 0
	cp xwa, 0xB1
	jr z, SndParam_RW_ExactMatch
	ld xwa, xix
	and xwa, 0xFF
	and xwa, xiz
	and xwa, 0xFF
	jr z, SndParam_RW_CheckFirstMatch

SndParam_RW_ExactMatch:
	lds hl, 0
	jr SndParam_RW_FoundCallback

SndParam_RW_CheckFirstMatch:
	cp hl, 0xFFFF
	jr nz, SndParam_RW_FoundCallback
	ld xwa, (xde + 8)
	or xwa, xwa
	jr z, SndParam_RW_NoEntry

SndParam_RW_ChainNext:
	ld xde, (xde + 8)
	ld xix, xiz
	ld xiy, (xde)
	ldw hl, 0xFFFF
	ld xwa, xiy
	srl xwa, 8
	cp xbc, xwa
	jr nz, SndParam_RW_ChainCheckFirst
	ld xwa, xix
	srl xwa, 0
	cp xwa, 0xB1
	jr z, SndParam_RW_ChainExactMatch
	ld xwa, xiy
	and xwa, 0xFF
	and xwa, xix
	and xwa, 0xFF
	jr z, SndParam_RW_ChainCheckFirst

SndParam_RW_ChainExactMatch:
	lds hl, 0
	jr SndParam_RW_FoundCallback

SndParam_RW_ChainCheckFirst:
	cp hl, 0xFFFF
	jr z, SndParam_RW_ChainContinue

SndParam_RW_FoundCallback:
	ld xwa, (xde + 4)
	jr SndParam_RW_ProcessResult

SndParam_RW_ChainContinue:
	ld xwa, (xde + 8)
	or xwa, xwa
	jr nz, SndParam_RW_ChainNext

SndParam_RW_NoEntry:
	lds32 xwa, 0

SndParam_RW_ProcessResult:
	ld xiz, xwa
	or xwa, xwa
	jr z, SndParam_RW_Fail
	ld xwa, (xsp + 18)
	ld xbc, (xiz)
	ld (xwa), xbc
	ld xwa, (xsp + 22)
	cp (xwa), 0xB1
	jr z, SndParam_RW_HandleB1Type
	ld a, (xiz + 15)
	inc 3, a
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee1130
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	lds hl, 0
	jr SndParam_RW_Epilogue

SndParam_RW_Fail:
	ldw hl, 0xFFFF

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
	.byte 0xbf, 0x04, 0x02, 0x00, 0x00
	ld	xwa, (xsp+14)
	ld	xiy, 15579704
	ld	xix, xwa
	.byte 0x95, 0x10, 0x95, 0x10
	ld	xiz, (xde)
	lds32	xwa, 0
	ld	(xsp+6), xwa
	ld	xhl, xiz
	and	xhl, 255
	ld	xwa, xhl
	.byte 0xe8, 0xee, 0x09
	add	xwa, xhl
	ld	xhl, xiz
	.byte 0xeb, 0xef, 0x08
	and	xhl, 255
	add	xhl, xwa
	ld	xwa, xhl
	.byte 0xe8, 0xee, 0x09
	add	xwa, xhl
	ld	xhl, xiz
	.byte 0xeb, 0xef, 0x00
	and	xhl, 31
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 2047
	call	16714770
	ld	ix, hl
	jr	44
	lds	bc, 0
	cp	xiz, xde
	jr	z, 5
	ldw	bc, 65535
	jr	12
	cp	bc, 65535
	jr	z, 6
	ld	xwa, (xwa+4)
	ld	(xsp+6), xwa
	inc	1, hl
	cp	hl, 2047
	jr	ugt, 37
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
	ld	bc, ix
	extz	xbc
	.byte 0xe9, 0xee, 0x03
	ld	xwa, 213248
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, 16777215
	jr	nz, -68
	ld	xwa, (xsp+6)
	or	xwa, xwa
	jr	z, 89
	ld	xhl, (xsp+14)
	ld	c, (xwa+4)
	ld	(xhl), c
	ld	c, (xwa+5)
	ld	(xhl+1), c
	lda	xde, (xhl+3)
	ld	c, (xwa+6)
	ld	(xde), c
	.byte 0x83, 0x3f, 0xb1
	jr	z, 34
	ld	xbc, (xsp+10)
	ld	bc, (xbc)
	ld	e, (xwa+15)
	extz	de
	.byte 0xda, 0xec, 0x02
	lda_24	xhl, 15601968
	exts	xde
	add	xde, xhl
	ld	xix, (xde)
	.byte 0xb4, 0xe8
	ld	xwa, (xsp+14)
	ld	(xwa+2), l
	jr	33
	ld	xhl, (xsp+10)
	ld	bc, (xhl)
	and	bc, 127
	ld	xwa, (xsp+14)
	ld	(xwa+2), c
	ld	wa, (xhl)
	.byte 0xd8, 0xed, 0x07
	and	wa, 127
	ld	(xde), a
	jr	5
	.byte 0xbf, 0x04, 0x02, 0xff, 0xff
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
	ldw (xsp + 4), 0xFFFF
	ld xwa, (xsp + 22)
	ld xiz, (xwa)
	ld (xsp + 6), xiz
	lds32 xwa, 0
	ld (xsp + 10), xwa
	ld xhl, xiz
	and xhl, 0xFF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xFF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1F
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32
	ld ix, hl
	jr SndParam_DMA_ProbeEntry

SndParam_DMA_ProbeCheck:
	lds bc, 0
	cp (xsp + 6), xde
	jr z, SndParam_DMA_MatchFound
	ldw bc, 0xFFFF
	jr SndParam_DMA_ProbeAdvance

SndParam_DMA_MatchFound:
	cp bc, 0xFFFF
	jr z, SndParam_DMA_ProbeAdvance
	ld xwa, (xwa + 4)
	ld (xsp + 10), xwa

SndParam_DMA_ProbeAdvance:
	inc 1, hl
	cp hl, 0x7FF
	jr ugt, SndParam_DMA_ExtractFields
	ld wa, ix
	inc 3, wa
	extz xwa
	div wa, 0x7FF
	ldto_werp IX, 0xE2

SndParam_DMA_ProbeEntry:
	ld bc, ix
	extz xbc
	sll xbc, 3
	ld xwa, 0x34100
	add xwa, xbc
	ld xde, (xwa)
	cp xde, 0xFFFFFF
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
	cp xwa, 0x17FFF
	jr ugt, SndParam_DMA_Zone2Check
	sub xiz, 0x8000
	ld xwa, xiz
	srl xwa, 10
	and xwa, 0x3F
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	ld xbc, xiz
	and xbc, 0x3FF
	ld xwa, (xsp + 14)
	ld (xwa), bc
	ldw (xsp + 4), 0x0

SndParam_DMA_Zone2Check:
	ld xbc, (xsp + 22)
	ld xwa, (xbc)
	cp xwa, 0x18000
	jr c, SndParam_DMA_Epilogue
	ld xwa, (xbc)
	cp xwa, 0x27FFF
	jr ugt, SndParam_DMA_Epilogue
	sub xiz, 0x8000
	ld xwa, xiz
	srl xwa, 10
	and xwa, 0x3F
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	ld xbc, xiz
	and xbc, 0x3FF
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
	lds32	xbc, 0
	ld	(xsp+4), xbc
	ld	xiz, xwa
	lds32	xwa, 0
	ld	(xsp+8), xwa
	ld	xhl, xiz
	and	xhl, 255
	ld	xwa, xhl
	.byte 0xe8, 0xee, 0x09
	add	xwa, xhl
	ld	xhl, xiz
	.byte 0xeb, 0xef, 0x08
	and	xhl, 255
	add	xhl, xwa
	ld	xwa, xhl
	.byte 0xe8, 0xee, 0x09
	add	xwa, xhl
	ld	xhl, xiz
	.byte 0xeb, 0xef, 0x00
	and	xhl, 31
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 2047
	call	16714770
	ld	ix, hl
	jr	44
	lds	bc, 0
	cp	xiz, xde
	jr	z, 5
	ldw	bc, 65535
	jr	12
	cp	bc, 65535
	jr	z, 6
	ld	xwa, (xwa+4)
	ld	(xsp+8), xwa
	inc	1, hl
	cp	hl, 2047
	jr	ugt, 37
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
	ld	bc, ix
	extz	xbc
	.byte 0xe9, 0xee, 0x03
	ld	xwa, 213248
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, 16777215
	jr	nz, -68
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	z, 31
	ld	c, (xwa+4)
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15602016
	ld	l, (xwa+5)
	extz	hl
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x20, 0xf3, 0x07, 0xe0, 0xec, 0x30
	ld	(xsp+4), xwa
	ld	xhl, (xsp+4)
	pop	xiz
	inc	8, xsp
	ret

SndParam_ReturnNotFound:
	ldw hl, 0xFFFF
	ret

SndParam_ReadRegField:
	ldw hl, 0xFFFF
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee1160
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	or xde, xde
	ret z
	ld c, (xwa + 5)
	extz bc
	ld_srib3 L, 0x07, 0xE8, 0xE4
	extz hl
	ld e, (xwa + 6)
	extz de
	ld c, (xwa + 10)
	extz bc
	xor hl, bc
	and hl, de
	ld a, (xwa + 9)
	and a, 0xF
	ret z
	sraa hl
	ret

SndParam_ReadRegWithLUT:
	ld e, (xwa + 11)
	ld c, e
	sla c, 2
	lda_24 xhl, 0xee0180
	ld_sril3 XBC, 0x03, 0xEC, 0xE4
	ld c, (xbc)
	cps e, 2
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
	cp hl, 0x3FC0
	ret lt
	ldw hl, 0x3FFF
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
	lda_24 xde, 0xee1160
	ld_sril3 XDE, 0x07, 0xE8, 0xE0
	or xde, xde
	jr z, SndParam_CompareNotFound
	ld a, (xbc + 5)
	extz wa
	ld_srib3 L, 0x07, 0xE8, 0xE0
	ld e, (xbc + 6)
	ld a, (xbc + 10)
	xor l, a
	and l, e
	ld a, (xbc + 9)
	and a, 0xF
	jr z, SndParam_CompareShifted
	srla l

SndParam_CompareShifted:
	ld a, (xbc + 11)
	sla a, 2
	lda_24 xbc, 0xee0198
	ld_sril3 XBC, 0x03, 0xE4, 0xE0
	cp l, (xbc + 1)
	jr nz, SndParam_CompareStatus5
	lds32 xwa, 3
	jr SndParam_CompareAddOffset

SndParam_CompareStatus5:
	lds32 xwa, 5
	cp l, (xbc + 2)
	jr nz, SndParam_CompareAddOffset
	lds32 xwa, 4

SndParam_CompareAddOffset:
	add xbc, xwa
	ld l, (xbc)
	extz hl
	ret

SndParam_CompareNotFound:
	ldw hl, 0xFFFF
	ret

SndParam_ReadRegWord:
	ldw hl, 0xFFFF
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee1160
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	or xde, xde
	ret z
	ld c, (xwa + 5)
	extz bc
	add bc, bc
	ld_sriw3 DE, 0x07, 0xE8, 0xE4
	ld a, (xwa + 11)
	sla a, 2
	lda_24 xbc, 0xee019c
	ld_sril3 XWA, 0x03, 0xE4, 0xE0
	lds hl, 0

SndParam_ReadRegScanLoop:
	cp_spiw DE, 0xE1
	ret z
	inc 1, hl
	cps hl, 5
	jr le, SndParam_ReadRegScanLoop
	lds hl, 0
	ret

SndParam_ReadRegBitfield:
	ldb l, 0x0
	ld c, (xwa + 4)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee1160
	ld_sril3 XIX, 0x07, 0xE8, 0xE4
	or xix, xix
	jr z, SndParam_BitfieldReturn
	ld c, (xwa + 5)
	extz bc
	ld de, bc
	inc 1, de
	bit_dri 2, 0x07, 0xF0, 0xE8
	jr nz, SndParam_BitfieldPendingWrite
	ld_srib3 L, 0x07, 0xF0, 0xE4
	ld c, (xwa + 6)
	ld b, c
	ld e, (xwa + 10)
	xor l, e
	and l, b
	ld e, (xwa + 9)
	ld a, e
	and a, 0xF
	jr z, SndParam_BitfieldZeroCheck
	srla l

SndParam_BitfieldZeroCheck:
	jr z, SndParam_BitfieldReturn
	ld a, e
	and a, 0xF
	jr z, SndParam_BitfieldNoShift
	srla c

SndParam_BitfieldNoShift:
	xor l, c
	jr SndParam_BitfieldReturn

SndParam_BitfieldPendingWrite:
	ldb l, 0x3

SndParam_BitfieldReturn:
	extz hl
	ret

SndParam_ReadRegAddress:
	ldw hl, 0xFFFF
	ld a, (xwa + 4)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee1160
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	or xwa, xwa
	ret z
	ld wa, (xwa + 8)
	and wa, 0x1FF
	ld hl, wa
	ret

SndParam_ResetDefaultTable:
	ld xiy, 0xEDBA2C
	ld xix, 0x96D4
	lds bc, 6
	ldirw
	ldada xhl, 38612
	ldw (xhl), 0xFFFF
	ret

SndParam_RegisterEntry_Data:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+12), de
	ld	xde, xwa
	ld	a, c
	.byte 0xc7, 0xe6, 0x99
	lda	xwa, (xde+4)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	.byte 0xd8, 0xec, 0x02
	lda_24	xhl, 15602016
	.byte 0xe3, 0x07, 0xec, 0xe0, 0x23
	or	xhl, xhl
	jrl	z, 187
	ld	a, (xde+7)
	.byte 0xc7, 0xf0, 0x99
	extz	ix
	.byte 0xd9, 0xf4
	jr	le, 3
	.byte 0xc7, 0xe6, 0x99
	ld	a, (xde+8)
	.byte 0xc7, 0xf0, 0x99
	extz	ix
	.byte 0xd9, 0xf4
	jr	ge, 3
	.byte 0xc7, 0xe6, 0x99
	ld	xiy, 15579692
	ld	xix, 38624
	lds	bc, 6
	.byte 0x95, 0x11
	ld	b, (xde+10)
	.byte 0xc7, 0xe6, 0x8b
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xfe
	xor	b, c
	lda	xix, (xde+6)
	ldada	xwa, 38630
	ld	(xsp+8), xwa
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 11
	ld	c, (xix)
	and	c, b
	ld	xwa, (xsp+8)
	ld	(xwa), c
	jr	57
	lda	xiy, (xde+5)
	ld	a, (xiy)
	extz	wa
	.byte 0xf3, 0x07, 0xec, 0xe0, 0x36
	ld	w, (xiz)
	.byte 0xc7, 0xe7, 0x98
	ld	c, (xix)
	.byte 0xc7, 0xe6, 0x9b, 0xc7, 0xe6, 0x89
	and	a, b
	.byte 0xc7, 0xe6, 0x99
	cpl	c
	and	w, c
	ld	(xiz), w
	ld	a, (xiy)
	extz	wa
	.byte 0xf3, 0x07, 0xec, 0xe0, 0x33
	ld	c, (xhl)
	.byte 0xc7, 0xe6, 0xe3
	ld	(xhl), c
	ld	xwa, (xsp+8)
	ld	(xwa), c
	ldada	xhl, 38624
	.byte 0xc7, 0xe7, 0x89, 0x8b, 0x06, 0xf1
	jr	nz, 7
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 27
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xhl+4), a
	ld	a, (xde+5)
	ld	(xhl+5), a
	ld	a, (xix)
	ld	(xhl+7), a
	jr	6
	stdi16	38624, 65535
	ld	xhl, 38624
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterEntryAlt_Data:
	dec	8, xsp
	pushw	iz
	ld	hl, de
	ld	xde, xwa
	ld	a, c
	.byte 0xc7, 0xe6, 0x99
	lda	xwa, (xde+4)
	ld	(xsp+6), xwa
	ld	a, (xwa)
	extz	wa
	.byte 0xd8, 0xec, 0x02
	lda_24	xix, 15602016
	.byte 0xe3, 0x07, 0xf0, 0xe0, 0x20
	ld	(xsp+2), xwa
	or	xwa, xwa
	jrl	z, 156
	ld	a, (xde+7)
	.byte 0xc7, 0xf0, 0x99
	extz	ix
	.byte 0xd9, 0xf4
	jr	le, 3
	.byte 0xc7, 0xe6, 0x99
	ld	a, (xde+8)
	.byte 0xc7, 0xf0, 0x99
	extz	ix
	.byte 0xd9, 0xf4
	jr	ge, 3
	.byte 0xc7, 0xe6, 0x99
	ld	xiy, 15579692
	ld	xix, 38636
	lds	bc, 6
	.byte 0x95, 0x11
	ld	b, (xde+10)
	.byte 0xc7, 0xe6, 0x8b
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xfe
	xor	b, c
	lda	xix, (xde+6)
	ldada	xiy, 38642
	cps	hl, 4
	jr	nz, 8
	ld	a, (xix)
	and	a, b
	ld	(xiy), a
	jr	50
	ld	c, (xix)
	.byte 0xc7, 0xe6, 0x9b, 0xc7, 0xe6, 0x89
	and	a, b
	.byte 0xc7, 0xe6, 0x99
	lda	xhl, (xde+5)
	ld	a, (xhl)
	extz	wa
	ld	iz, wa
	cpl	c
	ld	xwa, (xsp+2)
	.byte 0xc3, 0x07, 0xe0, 0xf8, 0xcb
	ld	c, (xhl)
	extz	bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x33
	ld	a, (xhl)
	.byte 0xc7, 0xe6, 0xe1
	ld	(xhl), a
	ld	(xiy), a
	ldada	xbc, 38636
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	6
	stdi16	38636, 65535
	ld	xhl, 38636
	popw	iz
	inc	8, xsp
	ret
SndParam_UpdateEntry_Data:
	ld	de, bc
	ld	xiy, 15579692
	ld	xix, 38648
	lds	bc, 6
	.byte 0x95, 0x11
	ldada	xhl, 38648
	lda	xiy, (xwa+4)
	ld	c, (xiy)
	ld	(xhl+4), c
	ld	c, (xwa+5)
	ld	(xhl+5), c
	ld	c, e
	.byte 0xc7, 0xea, 0x9b
	lda	xbc, (xhl+6)
	lda	xix, (xhl+7)
	.byte 0x85, 0x3f, 0xb1
	jr	nz, 15
	.byte 0xc7, 0xea, 0x89
	res	7, a
	ld	(xbc), a
	.byte 0xda, 0xed, 0x07
	ld	(xix), e
	jr	16
	lda	xiy, (xwa+6)
	ld	e, (xiy)
	.byte 0xc7, 0xea, 0x89
	and	a, e
	ld	(xbc), a
	ld	a, (xiy)
	ld	(xix), a
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, 177
	ld	xiy, 15579692
	ld	xix, 38660
	lds	bc, 6
	.byte 0x95, 0x11
	ld	a, (xde+11)
	.byte 0xc9, 0xec, 0x02
	lda_24	xbc, 15597976
	.byte 0xe3, 0x03, 0xe4, 0xe0, 0x21
	lds32	xwa, 1
	.byte 0x81, 0xf7
	jr	c, 2
	lds32	xwa, 2
	add	xbc, xwa
	ld	l, (xbc)
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf, 0xfe
	xor	c, l
	ld	h, c
	lda	xix, (xde+6)
	ldada	xbc, 38666
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 8
	ld	a, (xix)
	and	a, h
	ld	(xbc), a
	jr	56
	lda	xiy, (xde+5)
	ld	a, (xiy)
	.byte 0xc7, 0xf8, 0x99
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	.byte 0xc7, 0xee, 0x98
	ld	a, (xix)
	ld	l, a
	and	l, h
	cpl	a
	and	w, a
	ld	(xiz), w
	ld	a, (xiy)
	.byte 0xc7, 0xf4, 0x99
	extz	iy
	ld	xwa, (xsp+4)
	exts	xiy
	add	xiy, xwa
	ld	a, (xiy)
	or	a, l
	ld	(xiy), a
	ld	(xbc), a
	ldada	xbc, 38660
	.byte 0xc7, 0xee, 0x89, 0x89, 0x06, 0xf1
	jr	nz, 7
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 27
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	6
	stdi16	38660, 65535
	ld	xhl, 38660
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
	.byte 0xd9, 0xec, 0x02
	lda_24	xix, 15602016
	.byte 0xe3, 0x07, 0xf0, 0xe4, 0x26
	or	xiz, xiz
	jrl	z, 143
	ld	xiy, 15579692
	ld	xix, 38672
	lds	bc, 6
	.byte 0x95, 0x11
	ldada	xix, 38672
	.byte 0xbc, 0x02, 0x02, 0x01, 0x00
	ld	c, (xwa+7)
	extz	bc
	cp	bc, de
	jr	le, 2
	ld	de, bc
	ld	c, (xwa+8)
	extz	bc
	cp	bc, de
	jr	ge, 2
	ld	de, bc
	ld	c, (xwa+11)
	.byte 0xcb, 0xec, 0x02
	lda_24	xiy, 15597980
	.byte 0xe3, 0x03, 0xf4, 0xe4, 0x25
	exts	xde
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
	jr	z, 63
	.byte 0x9f, 0x04, 0x3f, 0x04, 0x00
	jr	z, 2
	ld	(xbc), de
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
	.byte 0xda, 0xef, 0x08
	ld	(xix+10), e
	ld	a, (xbc)
	ld	(xix+11), a
	jr	6
	stdi16	38672, 65535
	ld	xhl, 38672
	pop	xiz
	inc	2, xsp
	ret
SndParam_RegisterLinked_Data:
	lda	xsp, (xsp-18)
	ld	(xsp+16), de
	ld	de, bc
	ld	xhl, xwa
	ld	a, e
	.byte 0xc7, 0xe6, 0x99
	lda	xwa, (xhl+4)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	.byte 0xd8, 0xec, 0x02
	lda_24	xix, 15602016
	.byte 0xe3, 0x07, 0xf0, 0xe0, 0x20
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, 237
	ld	a, (xhl+7)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	le, 3
	.byte 0xc7, 0xe6, 0x99
	ld	a, (xhl+8)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	ge, 3
	.byte 0xc7, 0xe6, 0x99
	ld	xiy, 15579692
	ld	xix, 38684
	lds	bc, 6
	.byte 0x95, 0x11
	ldada	xwa, 38684
	ld	(xsp+8), xwa
	lda	xix, (xwa+5)
	ld	a, (xhl+5)
	ld	(xix), a
	cps	de, 3
	jr	nz, 9
	inc	1, a
	ld	(xix), a
	.byte 0xc7, 0xe6, 0xa9
	jr	26
	.byte 0xc7, 0xe6, 0xd8
	jr	z, 21
	ld	c, (xhl+6)
	ld	a, (xhl+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xff, 0xc7, 0xe6, 0x89
	xor	a, c
	.byte 0xc7, 0xe6, 0x99
	ld	e, (xhl+10)
	.byte 0xc7, 0xe6, 0x8b
	ld	a, (xhl+9)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xfe
	ld	xwa, (xsp+8)
	inc	6, xwa
	ld	(xsp+12), xwa
	xor	e, c
	ld	d, e
	lda	xbc, (xhl+6)
	.byte 0x9f, 0x10, 0x3f, 0x04, 0x00
	jr	nz, 11
	ld	c, (xbc)
	and	c, d
	ld	xwa, (xsp+12)
	ld	(xwa), c
	jr	59
	ld	a, (xix)
	.byte 0xc7, 0xf4, 0x99
	extz	iy
	ld	xwa, (xsp)
	exts	xiy
	add	xiy, xwa
	ld	w, (xiy)
	ld	e, w
	ld	c, (xbc)
	.byte 0xc7, 0xe6, 0x9b, 0xc7, 0xe6, 0x89
	and	a, d
	.byte 0xc7, 0xe6, 0x99
	cpl	c
	and	w, c
	ld	(xiy), w
	ld	c, (xix)
	extz	bc
	ld	xwa, (xsp)
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x34
	ld	c, (xix)
	.byte 0xc7, 0xe6, 0xe3
	ld	(xix), c
	ld	xwa, (xsp+12)
	ld	(xwa), c
	ld	xbc, (xsp+12)
	.byte 0x81, 0xf5
	jr	nz, 7
	.byte 0x9f, 0x10, 0x3f, 0x04, 0x00
	jr	nz, 25
	ld	xwa, (xsp+4)
	ld	xde, (xsp+8)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	c, (xhl+6)
	ld	(xde+7), c
	jr	6
	stdi16	38684, 65535
	ld	xhl, 38684
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, 269
	ld	a, (xde+7)
	cp	a, l
	jr	ule, 2
	ld	l, a
	ld	a, (xde+8)
	cp	a, l
	jr	nc, 2
	ld	l, a
	lda_24	xbc, 15597908
	ld	a, (xde+11)
	cp	a, 255
	jr	z, 10
	.byte 0xc9, 0xec, 0x02, 0xe3, 0x03, 0xe4, 0xe0, 0x25
	jr	2
	ld	xiy, (xbc)
	extz	hl
	ld	xix, xiy
	lds	bc, 0
	.byte 0x9d, 0x04, 0x3f, 0x00, 0x00
	jr	le, 20
	ld	xwa, (xix)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0xf7
	jr	nz, 4
	ld	wa, bc
	jr	10
	inc	1, bc
	.byte 0x9c, 0x04, 0xf1
	jr	lt, -20
	ld	wa, (xix+7)
	ld	xhl, xiy
	ld	bc, wa
	cps	wa, 0
	jr	ge, 6
	ld	xwa, (xhl)
	ld	l, (xwa)
	jr	27
	ld	wa, (xhl+4)
	cp	bc, wa
	jr	ge, 9
	ld	xwa, (xhl)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x27
	jr	11
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xhl)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x27
	ld	xiy, 15579692
	ld	xix, 38696
	lds	bc, 6
	.byte 0x95, 0x11
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf, 0xfe
	xor	c, l
	ld	h, c
	lda	xbc, (xde+6)
	ldada	xix, 38702
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 8
	ld	a, (xbc)
	and	a, h
	ld	(xix), a
	jr	56
	lda	xiy, (xde+5)
	ld	a, (xiy)
	.byte 0xc7, 0xf8, 0x99
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	.byte 0xc7, 0xee, 0x98
	ld	a, (xbc)
	ld	l, a
	and	l, h
	cpl	a
	and	w, a
	ld	(xiz), w
	ld	a, (xiy)
	.byte 0xc7, 0xf4, 0x99
	extz	iy
	ld	xwa, (xsp+4)
	exts	xiy
	add	xiy, xwa
	ld	a, (xiy)
	or	a, l
	ld	(xiy), a
	ld	(xix), a
	ldada	xix, 38696
	.byte 0xc7, 0xee, 0x89, 0x8c, 0x06, 0xf1
	jr	nz, 7
	.byte 0x9f, 0x0c, 0x3f, 0x04, 0x00
	jr	nz, 27
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xix+4), a
	ld	a, (xde+5)
	ld	(xix+5), a
	ld	a, (xbc)
	ld	(xix+7), a
	jr	6
	stdi16	38696, 65535
	ld	xhl, 38696
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x26
	or	xiz, xiz
	jr	z, 114
	ld	xiy, 15579692
	ld	xix, 38708
	lds	bc, 6
	.byte 0x95, 0x11
	cp	de, 40
	jr	ge, 5
	ldw	de, 40
	jr	9
	cp	de, 300
	jr	le, 3
	ldw	de, 300
	ld	a, e
	.byte 0xc7, 0xea, 0x99
	ldada	xwa, 38708
	lda	xbc, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	lda	xiy, (xwa+7)
	.byte 0x9f, 0x08, 0x3f, 0x04, 0x00
	jr	nz, 22
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	.byte 0xc7, 0xea, 0x89
	ld	(xix), a
	.byte 0xda, 0xed, 0x08
	ld	(xiy), e
	jr	36
	inc	8, xiz
	ld	wa, de
	.byte 0x96, 0xf0
	jr	z, 28
	ld	(xiz), de
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	.byte 0xc7, 0xea, 0x89
	ld	(xix), a
	ld	(xiy), 255
	jr	6
	stdi16	38708, 65535
	ld	xhl, 38708
	pop	xiz
	inc	6, xsp
	ret
SndParam_DeregisterEntry_Data:
	ld	xiy, 15579692
	ld	xix, 38720
	lds	bc, 6
	.byte 0x95, 0x11
	ldada	xhl, 38720
	.byte 0xb3, 0x02, 0xff, 0xff
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x26
	or	xiz, xiz
	jrl	z, 222
	ld	xiy, 15579692
	ld	xix, 38732
	lds	bc, 6
	.byte 0x95, 0x11
	lda	xwa, (xhl+5)
	ld	(xsp+10), xwa
	ld	a, (xwa)
	extz	wa
	.byte 0xf3, 0x07, 0xf8, 0xe0, 0x34
	ld	a, (xix)
	.byte 0xc7, 0xea, 0x99
	extz	wa
	ld	(xsp+4), wa
	ld	bc, wa
	lda	xiy, (xhl+9)
	lda	xwa, (xhl+6)
	ld	(xsp+6), xwa
	ld	a, (xwa)
	.byte 0xc7, 0xe6, 0x99
	extz	wa
	.byte 0xd7, 0xe2, 0x98
	and	wa, bc
	.byte 0xd7, 0xe2, 0x98
	ld	a, (xiy)
	ld	bc, qwa
	and	a, 15
	jr	z, 2
	.byte 0xd9, 0xfd
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
	.byte 0xc7, 0xe6, 0x8d
	cpl	e
	ldada	xbc, 38738
	.byte 0x9f, 0x12, 0x3f, 0x04, 0x00
	jr	nz, 24
	.byte 0xc7, 0xea, 0xc5
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xfe
	or	l, e
	ld	(xbc), l
	jr	41
	.byte 0xc7, 0xea, 0x89
	and	a, e
	.byte 0xc7, 0xea, 0x99
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xfe
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	extz	wa
	.byte 0xf3, 0x07, 0xf8, 0xe0, 0x33
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
	ldada	xbc, 38732
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
	jr	6
	stdi16	38732, 65535
	ld	xhl, 38732
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x26
	or	xiz, xiz
	jrl	z, 212
	ld	xiy, 15579692
	ld	xix, 38744
	lds	bc, 6
	.byte 0x95, 0x11
	lda	xwa, (xde+5)
	ld	(xsp+8), xwa
	ld	a, (xwa)
	extz	wa
	.byte 0xf3, 0x07, 0xf8, 0xe0, 0x34
	ld	a, (xix)
	.byte 0xc7, 0xee, 0x99, 0xc7, 0xee, 0x8b
	extz	bc
	lda	xiy, (xde+9)
	lda	xwa, (xde+6)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	.byte 0xc7, 0xe6, 0x99
	extz	wa
	.byte 0xd7, 0xe2, 0x98
	and	wa, bc
	.byte 0xd7, 0xe2, 0x98
	ld	a, (xiy)
	ld	bc, qwa
	and	a, 15
	jr	z, 2
	.byte 0xd9, 0xfd
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
	.byte 0xc7, 0xe6, 0x8d
	cpl	e
	ldada	xbc, 38750
	.byte 0x9f, 0x10, 0x3f, 0x04, 0x00
	jr	nz, 24
	.byte 0xc7, 0xee, 0xc5
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xfe
	or	l, e
	ld	(xbc), l
	jr	41
	.byte 0xc7, 0xee, 0x89
	and	a, e
	.byte 0xc7, 0xee, 0x99
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xfe
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	extz	wa
	.byte 0xf3, 0x07, 0xf8, 0xe0, 0x33
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
	ldada	xbc, 38744
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	6
	stdi16	38744, 65535
	ld	xhl, 38744
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, 251
	ld	xiy, 15579692
	ld	xix, 38756
	lds	bc, 6
	.byte 0x95, 0x11
	ld	xwa, (xsp+12)
	calr	-2696
	ld	xwa, (xsp+12)
	ld	a, (xwa+11)
	.byte 0xc9, 0xec, 0x02
	lda_24	xbc, 15597976
	.byte 0xe3, 0x03, 0xe4, 0xe0, 0x21, 0x9f, 0x0a, 0x3f, 0x00, 0x00
	jr	lt, 9
	ld	a, (xbc)
	extz	wa
	ld	(xsp+10), wa
	jr	7
	ld	a, (xbc)
	extz	wa
	sub	(xsp+10), wa
	.byte 0x9f, 0x0a, 0x83
	ld	xwa, (xsp+12)
	ld	a, (xwa+7)
	extz	wa
	cp	wa, hl
	jr	le, 2
	ld	hl, wa
	ld	xwa, (xsp+12)
	ld	a, (xwa+8)
	extz	wa
	cp	wa, hl
	jr	ge, 2
	ld	hl, wa
	ld	e, (xbc)
	extz	de
	lds32	xwa, 1
	cp	hl, de
	jr	lt, 2
	lds32	xwa, 2
	ld	xde, xbc
	add	xde, xwa
	ld	d, (xde)
	ld	xiy, (xsp+12)
	lda	xwa, (xiy+5)
	ld	(xsp+4), xwa
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	.byte 0xc3, 0x07, 0xe0, 0xec, 0x21, 0xc7, 0xea, 0x99
	ldada	xix, 38756
	lda	xhl, (xix+6)
	.byte 0xc7, 0xea, 0x8d
	ld	a, e
	ld	(xhl), a
	ld	a, (xiy+9)
	and	a, 15
	jr	z, 2
	.byte 0xcc, 0xfe
	ld	a, (xiy+10)
	xor	a, d
	.byte 0xc7, 0xeb, 0x99
	inc	6, xiy
	ld	w, (xiy)
	ld	d, w
	.byte 0xc7, 0xeb, 0xc4
	cpl	w
	and	e, w
	ld	a, e
	ld	(xhl), a
	or	e, d
	ld	(xhl), e
	.byte 0xc7, 0xea, 0x89
	cp	a, e
	jr	z, 63
	.byte 0x9f, 0x08, 0x3f, 0x04, 0x00
	jr	z, 16
	ld	xwa, (xsp+4)
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp)
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x45
	jr	10
	.byte 0x89, 0x06, 0x3f, 0x01
	jr	nz, 4
	ld	a, (xiy)
	ld	(xhl), a
	ld	xwa, (xsp+12)
	ld	a, (xwa+4)
	ld	(xix+4), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xix+5), a
	ld	a, (xiy)
	ld	(xix+7), a
	jr	6
	stdi16	38756, 65535
	ld	xhl, 38756
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	or	xwa, xwa
	jr	z, 44
	ld	xwa, xiz
	calr	-2881
	ld	bc, hl
	.byte 0x9f, 0x06, 0x81
	ld	a, (xiz+7)
	extz	wa
	cp	wa, bc
	jr	le, 2
	ld	bc, wa
	ld	a, (xiz+8)
	extz	wa
	cp	wa, bc
	jr	ge, 2
	ld	bc, wa
	ld	xwa, xiz
	ld	de, (xsp+4)
	calr	-1924
	stda32	38768, xhl
	ldda32	xhl, 38768
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, 275
	ld	xiy, 15579692
	ld	xix, 38772
	lds	bc, 6
	.byte 0x95, 0x11
	lda	xwa, (xde+5)
	ld	(xsp+8), xwa
	ld	c, (xwa)
	extz	bc
	lda	xwa, (xde+6)
	ld	(xsp+4), xwa
	ld	l, (xwa)
	ld	h, l
	ld	xwa, (xsp)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x21, 0xc7, 0xee, 0x99, 0xc7, 0xee, 0xc6
	ld	c, h
	ld	h, (xde+9)
	ld	a, h
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xff
	ld	w, c
	lda_24	xbc, 15597908
	ld	a, (xde+11)
	cp	a, 255
	jr	z, 10
	.byte 0xc9, 0xec, 0x02, 0xe3, 0x03, 0xe4, 0xe0, 0x25
	jr	2
	ld	xiy, (xbc)
	ld	a, w
	extz	wa
	ld	xix, xiy
	ld	w, a
	lds	de, 0
	.byte 0x9d, 0x04, 0x3f, 0x00, 0x00
	jr	le, 20
	ld	xbc, (xix)
	.byte 0xc3, 0x07, 0xe4, 0xe8, 0xf0
	jr	nz, 4
	ld	wa, de
	jr	10
	inc	1, de
	.byte 0x9c, 0x04, 0xf2
	jr	lt, -20
	ld	wa, (xix+7)
	.byte 0x9f, 0x12, 0x80
	ld	xde, xiy
	ld	bc, wa
	cps	wa, 0
	jr	ge, 6
	ld	xwa, (xde)
	ld	e, (xwa)
	jr	27
	ld	wa, (xde+4)
	cp	bc, wa
	jr	ge, 9
	ld	xwa, (xde)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x25
	jr	11
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xde)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x25, 0xc7, 0xee, 0x8a, 0xc7, 0xee, 0x89, 0xc7, 0xe6, 0x99
	cpl	l
	.byte 0xc7, 0xe6, 0x89
	and	a, l
	.byte 0xc7, 0xe6, 0x99
	ld	a, h
	and	a, 15
	jr	z, 2
	.byte 0xcd, 0xfe, 0xc7, 0xe6, 0x89
	or	a, e
	.byte 0xc7, 0xe6, 0x99
	ldada	xde, 38772
	.byte 0xc7, 0xe6, 0x89
	ld	(xde+6), a
	.byte 0x9f, 0x10, 0x3f, 0x04, 0x00
	jr	z, 17
	ld	xwa, (xsp+8)
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	.byte 0xc7, 0xe6, 0x8b, 0xf3, 0x07, 0xe0, 0xec, 0x43, 0xc7, 0xe6, 0x89
	cp	a, b
	jr	z, 32
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xde+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xde+7), a
	jr	6
	stdi16	38772, 65535
	ld	xhl, 38772
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	or	xwa, xwa
	jrl	z, 141
	ld	xiy, 15579692
	ld	xix, 38784
	lds	bc, 6
	.byte 0x95, 0x11
	lda	xiy, (xwa+8)
	ld	iz, (xiy)
	ld	bc, iz
	and	bc, 511
	.byte 0x9f, 0x0a, 0x81
	cp	bc, 40
	jr	ge, 5
	ldw	bc, 40
	jr	9
	cp	bc, 300
	jr	le, 3
	ldw	bc, 300
	ld	a, c
	ld	(xsp+2), a
	ld	a, (xde)
	.byte 0xc7, 0xe6, 0x99
	ldada	xwa, 38784
	lda	xde, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	inc	7, xwa
	ld	(xsp+4), xwa
	.byte 0x9f, 0x08, 0x3f, 0x04, 0x00
	jr	nz, 31
	cp	iz, bc
	jr	z, 60
	.byte 0xc7, 0xe6, 0x89
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	.byte 0xd9, 0xed, 0x08
	and	bc, 1
	ld	xwa, (xsp+4)
	ld	(xwa), c
	jr	33
	ld	(xiy), bc
	cp	iz, bc
	jr	z, 27
	.byte 0xc7, 0xe6, 0x89
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	ld	xwa, (xsp+4)
	ld	(xwa), 255
	jr	6
	stdi16	38784, 65535
	ld	xhl, 38784
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
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15602016
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, 238
	ld	xiy, 15579692
	ld	xix, 38796
	lds	bc, 6
	.byte 0x95, 0x11
	lda	xwa, (xde+5)
	ld	(xsp+14), xwa
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp+4)
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x34
	ld	l, (xix)
	ld	c, l
	extz	bc
	ld	(xsp+8), bc
	lda	xiy, (xde+9)
	lda	xwa, (xde+6)
	ld	(xsp+10), xwa
	ld	a, (xwa)
	.byte 0xc7, 0xe6, 0x99
	extz	wa
	ld	iz, wa
	and	iz, bc
	ld	a, (xiy)
	ld	bc, iz
	and	a, 15
	jr	z, 2
	.byte 0xd9, 0xfd, 0x9f, 0x18, 0x81
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
	ld	xwa, (xsp+18)
	ld	h, (xwa)
	ldada	xiz, 38796
	lda	xde, (xiz+6)
	.byte 0x9f, 0x16, 0x3f, 0x04, 0x00
	jr	nz, 54
	ld	xbc, xiz
	ld	(xiz+4), h
	ld	xwa, (xsp+14)
	ld	a, (xwa)
	ld	(xiz+5), a
	lda	xwa, (xiz+7)
	.byte 0x9f, 0x18, 0x3f, 0x00, 0x00
	jr	le, 8
	ld	(xwa), 2
	ld	(xde), 2
	jr	19
	.byte 0x9f, 0x18, 0x3f, 0x00, 0x00
	jr	ge, 8
	ld	(xwa), 1
	ld	(xde), 1
	jr	4
	.byte 0xb1, 0x02, 0xff, 0xff
	ld	xhl, xbc
	jr	79
	.byte 0xc7, 0xe6, 0x88
	cpl	w
	and	l, w
	ld	(xix), l
	ld	a, (xiy)
	and	a, 15
	jr	z, 2
	.byte 0xcb, 0xfe
	ld	l, c
	ld	xiy, (xsp+14)
	ld	c, (xiy)
	extz	bc
	ld	xwa, (xsp+4)
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x34
	ld	c, (xix)
	or	c, l
	ld	(xix), c
	ld	(xde), c
	ld	wa, (xsp+8)
	cp	a, c
	jr	z, 24
	ld	(xiz+4), h
	ld	a, (xiy)
	ld	(xiz+5), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xiz+7), a
	jr	6
	stdi16	38796, 65535
	ld	xhl, 38796
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
	.byte 0xcf, 0xfe
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
	.byte 0xc9, 0xec, 0x02
	lda_24	xde, 15597976
	.byte 0xe3, 0x03, 0xe8, 0xe0, 0x22
	lds32	xwa, 1
	.byte 0x82, 0xf7
	jr	c, 2
	lds32	xwa, 2
	add	xde, xwa
	ld	l, (xde)
	ld	a, (xbc+9)
	and	a, 15
	jr	z, 2
	.byte 0xcf, 0xfe
	ld	a, (xbc+10)
	xor	a, l
	ld	l, (xbc+6)
	and	l, a
	extz	hl
	ret
SndParam_ClampReverbTime:
	ld32_24	xwa, 15602304
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, 5
	ldw	hl, 40
	jr	9
	cp	hl, 300
	ret	ule
	ldw	hl, 300
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
	.byte 0xcf, 0xff
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
	.byte 0xcf, 0xff
	ld	a, (xde+11)
	.byte 0xc9, 0xec, 0x02
	lda_24	xbc, 15597976
	.byte 0xe3, 0x03, 0xe4, 0xe0, 0x21, 0x89, 0x01, 0xf7
	jr	nz, 4
	lds32	xwa, 3
	jr	9
	lds32	xwa, 5
	.byte 0x89, 0x02, 0xf7
	jr	nz, 2
	lds32	xwa, 4
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret
SndParam_ClampDelayTime:
	ld32_24	xwa, 15602304
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, 5
	ldw	hl, 40
	jr	9
	cp	hl, 300
	ret	ule
	ldw	hl, 300
	ret
SndParam_ReturnInvalid:
	ldw	hl, 65535
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
	.byte 0xdb, 0xfc
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
	calr	442
	lds	hl, 0
	inc	4, xsp
	ret
SndParam_WriteFieldSub_Data:
	dec	4, xsp
	ld	hl, bc
	ld	xde, xwa
	ld	a, (xde+11)
	.byte 0xc9, 0xec, 0x02
	lda_24	xbc, 15597976
	.byte 0xe3, 0x03, 0xe4, 0xe0, 0x21
	lds32	xwa, 1
	.byte 0x81, 0xf7
	jr	c, 2
	lds32	xwa, 2
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
	.byte 0xcf, 0xfe
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
	lds	hl, 0
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
	calr	310
	lds	hl, 0
	inc	4, xsp
	ret
SndParam_WriteViaHash_Data:
	ld	a, (xwa+4)
	extz	wa
	add	wa, wa
	ldada	xde, 38808
	.byte 0xf3, 0x07, 0xe8, 0xe0, 0x51
	lds	hl, 0
	ret
SndParam_BatchUpdate_Data:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), bc
	ld	(xsp+22), xwa
	.byte 0xc7, 0xfa, 0xa8, 0xc7, 0xf9, 0xa8, 0xc7, 0xfb, 0xa8
	ld	xwa, 8705
	calr	-5923
	ld	wa, (xsp+20)
	ld	d, a
	ldada	xix, 38808
	ld	xwa, (xsp+22)
	lda	xbc, (xwa+4)
	cps	hl, 3
	jr	z, 122
	cps	hl, 1
	jr	z, 77
	cps	hl, 0
	jrl	nz, 166
	lda	xwa, (xsp+10)
	ld	e, (xbc)
	ld	(xwa+2), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	.byte 0xd3, 0x07, 0xf0, 0xe4, 0x21
	and	bc, 127
	ld	(xwa+4), c
	call	16705514
	lda	xbc, (xsp+10)
	ld	a, (xbc+1)
	.byte 0xc7, 0xfa, 0x99, 0xc7, 0xfa, 0x30, 0x07, 0xc9, 0xef, 0x07, 0xc7, 0xf9, 0x99
	ld	a, (xbc)
	.byte 0xc7, 0xfb, 0x99, 0xc7, 0xfb, 0x33, 0x07
	jr	z, 103
	.byte 0xc7, 0xfb, 0x30, 0x07, 0xc7, 0xfa, 0x61
	jr	94
	ld	a, (xbc)
	extz	wa
	add	wa, wa
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20
	and	wa, 7
	.byte 0xc9, 0xee, 0x04, 0xc7, 0xfa, 0x99, 0xc7, 0xf9, 0xa8, 0xc7, 0xfb, 0x9c
	bit	7, d
	jr	z, 62
	.byte 0xc7, 0xfb, 0x30, 0x07, 0xc7, 0xf9, 0xa9
	jr	53
	lda	xwa, (xsp+4)
	ld	e, (xbc)
	ld	(xwa+5), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	.byte 0xd3, 0x07, 0xf0, 0xe4, 0x21
	and	bc, 127
	ld	(xwa+4), c
	call	16705747
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	.byte 0xc7, 0xfa, 0x99
	ld	a, (xbc+1)
	.byte 0xc7, 0xf9, 0x99
	ld	a, (xbc+2)
	.byte 0xc7, 0xfb, 0x99
	lda	xwa, (xsp+16)
	ld	(xwa), 129
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa+1), c
	.byte 0xc7, 0xfa, 0x8b
	ld	(xwa+2), c
	.byte 0xc7, 0xf9, 0x8b
	ld	(xwa+3), c
	calr	35
	lda	xwa, (xsp+16)
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa), c
	ld	(xwa+1), 0
	.byte 0xc7, 0xfb, 0x8b
	ld	(xwa+2), c
	ld	(xwa+3), 255
	calr	7
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	ld	c, (xwa)
	ld	b, (xwa+1)
	ld	e, (xwa+2)
	ld	d, (xwa+3)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16581982
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
	cps wa, 4
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
	ldfr_berp A, 0xF0
	extz ix
	ld e, (xiz + 6)
	extz de
	ld c, (xiz + 5)
	extz bc
	ld a, (xiz + 4)
	extz wa
	cps hl, 4
	jr z, SndParam_WidgetCallType4
	cps hl, 3
	jr z, SndParam_WidgetCallType3
	cps hl, 2
	jr z, SndParam_WidgetAppendType2
	cps hl, 1
	jr nz, SndParam_WidgetDispatchDone
	cpdi16 37086, 508
	call_24 nc, 0xEF14D8
	ldada xbc, 48444
	ldda16 xde, 37086
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 5)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 6)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 7)
	lda_dpi XBC, 0xE8
	jr SndParam_WidgetAppendTail

SndParam_WidgetAppendType2:
	cpdi16 37086, 508
	call_24 nc, 0xEF14F3
	ldada xbc, 48444
	ldda16 xde, 37086
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 5)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 6)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 7)
	lda_dpi XBC, 0xE8

SndParam_WidgetAppendTail:
	ld (xde), 0xFF
	incdi16 4, 37086
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
	cps e, 0
	jrl z, SndParam_Widget1_Done
	lda xiy, (xiz + 6)
	ldfr_berp E, 0xF0
	extz ix
	ld c, (xiz + 5)
	extz bc
	ld l, (xiz + 4)
	extz hl
	cps wa, 4
	jrl z, SndParam_Widget1_CallType4
	cps wa, 3
	jrl z, SndParam_Widget1_CallType3
	cps wa, 2
	jr z, SndParam_Widget1_AppendType2
	cps wa, 1
	jrl nz, SndParam_Widget1_Done
	cpdi16 37086, 504
	call_24 nc, 0xEF14D8
	ldada xbc, 48444
	ldda16 xde, 37086
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 5)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 6)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 7)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 8)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 9)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 10)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 11)
	lda_dpi XBC, 0xE8
	jr SndParam_Widget1_AppendTail

SndParam_Widget1_AppendType2:
	cpdi16 37086, 504
	call_24 nc, 0xEF14F3
	ldada xbc, 48444
	ldda16 xde, 37086
	extz xde
	add xde, xbc
	ld a, (xiz + 4)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 5)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 6)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 7)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 8)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 9)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 10)
	lda_dpi XBC, 0xE8
	ld a, (xiz + 11)
	lda_dpi XBC, 0xE8

SndParam_Widget1_AppendTail:
	ld (xde), 0xFF
	incdi16 8, 37086
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
	lds	iy, 0
	ld	ix, de
	sub	ix, 1
	jr	c, 40
	ld	hl, iy
	add	hl, ix
	srl	hl, 1
	ld	de, hl
	extz	xde
	add	xde, xbc
	ld	e, (xde)
	cp	a, e
	jr	nz, 3
	lds	hl, 0
	ret
	cp	a, e
	jr	ule, 6
	ld	iy, hl
	inc	1, iy
	jr	4
	ld	ix, hl
	dec	1, ix
	cp	iy, ix
	jr	ule, -40
	ldw	hl, 65535
	ret

SndParam_EncodeAddress:
	ld xhl, 0x8000
	and wa, 0x3F
	sll wa, 10
	extz xwa
	add xhl, xwa
	ld wa, bc
	and wa, 0x3FF
	extz xwa
	or xhl, xwa
	cp bc, 0x400
	ret c
	add xhl, 0x10000
	ret

SndParam_InitHashTable:
	lda_24 xbc, 0x034100
	ld xwa, xbc
	st_dri3b B, 0xE5, 0xF8, 0x3F

SndParam_InitHashFillLoop:
	ld xiy, 0xEDBA3C
	ld xix, xwa
	lds bc, 4
	ldirw
	inc 8, xwa
	cp xwa, xde
	jr c, SndParam_InitHashFillLoop
	ret

SndParam_RegisterAllWidgets:
	push xiz
	lds32 xiz, 0

SndParam_RegisterLoop:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0xEE01A0
	add xwa, xbc
	ld xbc, (xwa)
	ld xwa, (xbc)
	calr SndParam_InsertEntry
	inc 1, xiz
	cp xiz, 0x3CC
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
	and xhl, 0xFF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xFF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1F
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32

SndParam_InsertProbe:
	ld wa, hl
	extz xwa
	sll xwa, 3
	ld xbc, 0x34100
	add xbc, xwa
	ld xde, (xbc)
	cp xde, 0xFFFFFF
	jr nz, SndParam_InsertCheckKey
	ld (xbc), xiz
	ld xwa, (xsp + 6)
	ld (xbc + 4), xwa
	lds hl, 0
	jr SndParam_InsertReturn

SndParam_InsertCheckKey:
	lds wa, 0
	cp xiz, xde
	jr z, SndParam_InsertKeyMatch
	ldw wa, 0xFFFF

SndParam_InsertIncSlot:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x7FF
	jr ule, SndParam_InsertNextSlot
	jr SndParam_InsertFail

SndParam_InsertKeyMatch:
	cp wa, 0xFFFF
	jr z, SndParam_InsertIncSlot
	jr SndParam_InsertFail

SndParam_InsertNextSlot:
	inc 3, hl
	extz xhl
	div hl, 0x7FF
	ldto_werp WA, 0xEE
	ld hl, wa
	cp wa, 0x7FF
	jr c, SndParam_InsertProbe

SndParam_InsertFail:
	ldw hl, 0xFFFF

SndParam_InsertReturn:
	pop xiz
	inc 6, xsp
	ret

SndParam_ClearHashTable:
	ldada xwa, 38872
	ld xbc, xwa
	st_dri3b B, 0xE1, 0xFC, 0x1F

SndParam_ClearLoop:
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	cp xbc, xde
	jr c, SndParam_ClearLoop
	lda_24 xde, 0x0380f8
	lda xbc, (xde + 2)
	ld xwa, xbc
	st_dri3b A, 0xE5, 0x00, 0x40

SndParam_ClearHeap:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SndParam_ClearHeap
	ldw (xde), 0x0
	ret

SndParam_ReregisterAll:
	push xiz
	lds32 xiz, 0

SndParam_ReregisterLoop:
	ld xbc, xiz
	sll xbc, 2
	ld xwa, 0xEE01A0
	add xwa, xbc
	ld xhl, (xwa)
	ld a, (xhl + 4)
	ld c, (xhl + 5)
	ld e, (xhl + 6)
	push xhl
	calr SndParam_AllocAndInsert
	inc 1, xiz
	cp xiz, 0x3CC
	jr c, SndParam_ReregisterLoop
	pop xiz
	ret

SndParam_AllocAndInsert:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), e
	ld (xsp + 18), c
	ld (xsp + 20), a
	ldw wa, 0xC
	calr SndParam_HeapAlloc
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	or xwa, xwa
	jr nz, SndParam_AllocBuildKey
	ld xwa, 0xEE1560
	call Debug_PrintString
	pushw 0x1
	call Boot_HaltInstruction
	inc 2, xsp

SndParam_AllocBuildKey:
	lds32 xde, 0
	ld e, (xsp + 18)
	sll xde, 8
	lds32 xwa, 0
	ld a, (xsp + 20)
	sll xwa, 0
	ld xbc, xwa
	or xbc, xde
	lds32 xwa, 0
	ld a, (xsp + 16)
	ld (xsp + 12), xwa
	or (xsp + 12), xbc
	ld xde, (xsp + 12)
	srl xde, 8
	ld xhl, xde
	and xhl, 0xF
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 4
	and xhl, 0xF
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xde
	srl xhl, 8
	and xhl, 0xF
	add xhl, xwa
	ld xbc, xhl
	sll xbc, 9
	add xbc, xhl
	srl xde, 12
	ld xhl, xde
	and xhl, 0xF
	add xhl, xbc
	ld xwa, xhl
	ld xbc, 0x7FF
	call DivMod32
	ld bc, hl
	sll hl, 2
	ldada xde, 38872
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
	lds hl, 0
	pop xiz
	lda xsp, (xsp + 18)
	retd 0x4

SndParam_HeapAlloc:
	cps wa, 0
	jr z, SndParam_HeapAllocFail
	lda_24 xbc, 0x0380f8
	ld de, (xbc)
	add de, wa
	cp de, 0x4000
	jr c, SndParam_HeapAllocOK

SndParam_HeapAllocFail:
	lds32 xhl, 0
	ret

SndParam_HeapAllocOK:
	ld de, (xbc)
	extz xde
	inc 2, xde
	ld xhl, xbc
	add xhl, xde
	add (xbc), wa
	ret

