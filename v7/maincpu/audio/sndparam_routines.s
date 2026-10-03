; =============================================================================
; Sound Parameter Routines
; =============================================================================
;
; Sound parameter probe, match, and heap allocation. Provides
; lookup and comparison services for sound preset data.
; =============================================================================
; v7 FRAMING (lane seui, 2026-09-25): this file was carried as `.byte` rows
; with labels placed on them.  It is now decoded in lock-step -- MAME unidasm's
; instruction boundaries, every instruction spelled by the tree's backend at
; the same address and length (else kept as `.byte`) -- over 0xFCCE9F-0xFCED54,
; and checked against v10: 2,768 of the 2,776 instructions whose bytes are
; equal in v10 start an instruction line there
; (scripts/lanes/seui/se_reframe_code.py --span ... --witness v10).
; NOTE: a label written `.set Name, . + k` falls INSIDE an instruction of that
; framing (66 of them).  They are kept at their exact old addresses because
; other code uses several as bases (`.long SndParam_ResolveWidget + 164` in
; ui_widgets/widget_dispatch.s), but their names are NOT evidence of what
; starts there: they were attached to `.byte` rows, not to routines.
; =============================================================================

SndParam_ProbeCheckMatch:
	ld	xwa, 7:i3
	ret
	ld	w, 176:opc
	.byte	0x53
	ld	c, (xiz+6)
	cpl	c
SndParam_ProbeMatchFound:
	ld	xwa, (xsp+22)
	and	(xwa+3), c
	jr	SndParam_ProbeMatchFound_Join
SndParam_ProbeMatchFound_Skip:
	ld	xwa, (xsp+10)
	.set	SndParam_ProbeAdvance, . + 1
	ld	c, (xwa)
	res	7, c
	extz	bc
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	res	7, a
	extz	wa
	sla	wa, 7
	ld	de, wa
SndParam_ProbeEntry:
	or	de, bc
	ld	xwa, (xsp+14)
	ld	(xwa), de
SndParam_ProbeMatchFound_Join:
	ld	hl, 0:i3
	jr	SndParam_ProbeEntry_Epilogue
SndParam_ProbeMatchFound_Join_Skip:
	ldw	hl, 65535
SndParam_ProbeEntry_Epilogue:
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-14)
	push	xiz
	.set	SndParam_DispatchCallback, . + 1
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
	.set	SndParam_CallbackType1, . + 1
	and	xhl, 31
	add	xhl, xwa
	.set	SndParam_NotFound, . + 1
	ld	xwa, xhl
	.set	SndParam_Epilogue, . + 4
	ld	xbc, 2047
	call	DivMod32
	ld	ix, hl
	.set	SndParam_DispatchTypeDE5, . + 1
	jr	SndParam_ProbeEntry_Join2
SndParam_ProbeEntry_Loop:
	ld	bc, 0:i3
	cp	xiz, xde
	jr	z, SndParam_ProbeEntry_Skip
	ldw	bc, 65535
	jr	SndParam_ProbeEntry_Join
SndParam_ProbeEntry_Skip:
	cp	bc, 65535
	jr	z, SndParam_ProbeEntry_Join
	ld	xwa, (xwa+4)
	ld	(xsp+6), xwa
SndParam_ProbeEntry_Join:
	inc	1, hl
	cp	hl, 2047
	jr	ugt, SndParam_ProbeEntry_Skip2
	ld	wa, ix
SndParam_NotifyAndReturn:
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
SndParam_ProbeEntry_Join2:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	.set	SndParam_LookupByKey, . + 2
	ld	xwa, 0x34100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_ProbeEntry_Loop
SndParam_ProbeEntry_Skip2:
	ld	xwa, (xsp+6)
	or	xwa, xwa
	jr	z, SndParam_NotifyAndReturn_Skip2
	ld	xhl, (xsp+14)
	ld	c, (xwa+4)
	ld	(xhl), c
	ld	c, (xwa+5)
	ld	(xhl+1), c
	lda	xde, (xhl+3)
	ld	c, (xwa+6)
	ld	(xde), c
	cp	(xhl), 177
	jr	z, SndParam_NotifyAndReturn_Skip
	ld	xbc, (xsp+10)
	ld	bc, (xbc)
	ld	e, (xwa+15)
	extz	de
	sla	de, 2
	lda	xhl, (SndParam_EncodeHandlers:24)
	exts	xde
	add	xde, xhl
	ld	xix, (xde)
	call	(xix)
	ld	xwa, (xsp+14)
	ld	(xwa+2), l
	jr	SndParam_NotifyAndReturn_Join
	.set	SndParam_Lkp2_ProbeCheck, . + 2
SndParam_NotifyAndReturn_Skip:
	ld	xhl, (xsp+10)
	ld	bc, (xhl)
	and	bc, 127
	ld	xwa, (xsp+14)
	.set	SndParam_Lkp2_MatchFound, . + 1
	ld	(xwa+2), c
	ld	wa, (xhl)
	sra	wa, 7
	and	wa, 127
	.set	SndParam_Lkp2_ProbeAdvance, . + 1
	ld	(xde), a
	jr	SndParam_NotifyAndReturn_Join
SndParam_NotifyAndReturn_Skip2:
	ldw	(xsp+4), 65535
SndParam_NotifyAndReturn_Join:
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+14)
	ret
SndParam_ResolveOscEntry_Helper:
	lda	xsp, (xsp-22)
	push	xiz
	.set	SndParam_Lkp2_ProbeEntry, . + 1
	ld	(xsp+14), xde
	ld	(xsp+18), xbc
	ld	(xsp+22), xwa
	ldw	(xsp+4), 65535
	ld	xwa, (xsp+22)
	ld	xiz, (xwa)
	ld	(xsp+6), xiz
	ld	xwa, 0:i3
	.set	SndParam_Lkp2_Dispatch, . + 1
	ld	(xsp+10), xwa
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
	jr	SndParam_ResolveOscEntry_Helper_Join2
SndParam_ResolveOscEntry_Helper_Loop:
	ld	bc, 0:i3
	cp	(xsp+6), xde
SndParam_Lkp2_CallType1:
	jr	z, SndParam_ResolveOscEntry_Helper_Skip
	ldw	bc, 65535
	jr	SndParam_ResolveOscEntry_Helper_Join
	.set	SndParam_Lkp2_NotFound, . + 1
SndParam_ResolveOscEntry_Helper_Skip:
	cp	bc, 65535
	jr	z, SndParam_ResolveOscEntry_Helper_Join
SndParam_Lkp2_Epilogue:
	ld	xwa, (xwa+4)
	ld	(xsp+10), xwa
SndParam_ResolveOscEntry_Helper_Join:
	inc	1, hl
SndParam_WrapNotify2:
	cp	hl, 2047
	jr	ugt, SndParam_ResolveOscEntry_Helper_Skip2
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
	.set	SndParam_LookupReadOnly, . + 1
SndParam_ResolveOscEntry_Helper_Join2:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, 0x34100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_ResolveOscEntry_Helper_Loop
SndParam_ResolveOscEntry_Helper_Skip2:
	ld	xwa, (xsp+10)
	or	xwa, xwa
	jrl	z, SndParam_ResolveOscEntry_Helper_Skip4
	ld	xbc, (xsp+22)
	ld	xwa, (xbc)
	cp	xwa, 32768
	jr	c, SndParam_ResolveOscEntry_Helper_Skip3
	ld	xwa, (xbc)
	cp	xwa, 0x17fff
	jr	ugt, SndParam_ResolveOscEntry_Helper_Skip3
	sub	xiz, 32768
	ld	xwa, xiz
	srl	xwa, 10
	and	xwa, 63
	ld	bc, wa
	ld	xwa, (xsp+18)
	ld	(xwa), bc
SndParam_RO_ProbeCheck:
	ld	xbc, xiz
	and	xbc, 1023
	ld	xwa, (xsp+14)
SndParam_RO_MatchFound:
	ld	(xwa), bc
	ldw	(xsp+4), 0
SndParam_ResolveOscEntry_Helper_Skip3:
	ld	xbc, (xsp+22)
	ld	xwa, (xbc)
SndParam_RO_ProbeAdvance:
	cp	xwa, 0x18000
	jr	c, SndParam_ResolveOscEntry_Helper_Skip4
	ld	xwa, (xbc)
	cp	xwa, 0x27fff
	jr	ugt, SndParam_ResolveOscEntry_Helper_Skip4
	.set	SndParam_RO_ProbeEntry, . + 3
	sub	xiz, 32768
	ld	xwa, xiz
	srl	xwa, 10
	and	xwa, 63
	ld	bc, wa
	ld	xwa, (xsp+18)
	ld	(xwa), bc
	ld	xbc, xiz
	.set	SndParam_RO_Dispatch, . + 1
	and	xbc, 1023
	add	bc, 1024
	ld	xwa, (xsp+14)
	ld	(xwa), bc
	ldw	(xsp+4), 0
SndParam_ResolveOscEntry_Helper_Skip4:
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	dec	8, xsp
	push	xiz
	ld	xbc, 0:i3
	ld	(xsp+4), xbc
	ld	xiz, xwa
	ld	xwa, 0:i3
SndParam_RO_Epilogue:
	ld	(xsp+8), xwa
	ld	xhl, xiz
	.set	SndParam_LookupViaEncode, . + 2
	and	xhl, 255
	ld	xwa, xhl
	.set	SndParam_ResolveWidget, . + 2
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
	jr	SndParam_ResolveOscEntry_Helper_Join4
SndParam_ResolveOscEntry_Helper_Loop2:
	ld	bc, 0:i3
	cp	xiz, xde
	jr	z, SndParam_ResolveOscEntry_Helper_Skip5
	ldw	bc, 65535
	jr	SndParam_ResolveOscEntry_Helper_Join3
SndParam_ResolveOscEntry_Helper_Skip5:
	cp	bc, 65535
	jr	z, SndParam_ResolveOscEntry_Helper_Join3
	ld	xwa, (xwa+4)
	ld	(xsp+8), xwa
SndParam_ResolveOscEntry_Helper_Join3:
	inc	1, hl
	cp	hl, 2047
	jr	ugt, SndParam_ResolveOscEntry_Helper_Skip6
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
SndParam_ResolveOscEntry_Helper_Join4:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, 0x34100
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_ResolveOscEntry_Helper_Loop2
SndParam_ResolveOscEntry_Helper_Skip6:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	z, SndParam_ResolveOscEntry_Helper_Skip7
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	l, (xwa+5)
	extz	hl
	ld	xwa, (xde+bc)
	lda	xwa, (xwa+hl)
	ld	(xsp+4), xwa
SndParam_ResolveOscEntry_Helper_Skip7:
	ld	xhl, (xsp+4)
	pop	xiz
	inc	8, xsp
	ret
	ldw	hl, 65535
	ret
	ldw	hl, 65535
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+bc)
	or	xde, xde
	ret	z
	ld	c, (xwa+5)
	extz	bc
	ld	l, (xde+bc)
	extz	hl
	ld	e, (xwa+6)
	extz	de
	ld	c, (xwa+10)
	extz	bc
	xor	hl, bc
	and	hl, de
	ld	a, (xwa+9)
	and	a, 15
	ret	z
	.byte	0xdb,	0xfd
SndParam_RW_ExactMatch:
	ret
	ld	e, (xwa+11)
SndParam_RW_CheckFirstMatch:
	ld	c, e
	sla	c, 2
	lda	xhl, (SndParam_RegRamPtrs:24)
	.set	SndParam_RW_ChainNext, . + 3
	ld	xbc, (xhl+c)
	ld	c, (xbc)
	cp	e, 2:i3
	jr	nz, SndParam_RW_ExactMatch_Skip
	ld	a, c
	sll	a, 6
	and	a, 64
	ld	l, a
	extz	hl
	srl	c, 1
	res	7, c
	sll	c, 7
	extz	bc
	add	hl, bc
	cp	hl, 16320
	ret	lt
	ldw	hl, 16383
	jr	SndParam_RW_ExactMatch_Return
SndParam_RW_ExactMatch_Skip:
	ld	l, (xwa+6)
	and	l, c
	.set	SndParam_RW_ChainExactMatch, . + 1
	extz	hl
SndParam_RW_ExactMatch_Return:
	ret
SndParam_RegisterLinked_Data_Helper:
	ld	xbc, xwa
SndParam_RW_ChainCheckFirst:
	ld	a, (xbc+4)
	extz	wa
	.set	SndParam_RW_FoundCallback, . + 1
	sla	wa, 2
	.set	SndParam_RW_ChainContinue, . + 3
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+wa)
SndParam_RW_NoEntry:
	or	xde, xde
SndParam_RW_ProcessResult:
	jr	z, SndParam_RW_HandleB1Type_Skip
	ld	a, (xbc+5)
	extz	wa
	ld	l, (xde+wa)
	ld	e, (xbc+6)
	ld	a, (xbc+10)
	xor	l, a
	and	l, e
	ld	a, (xbc+9)
	and	a, 15
	jr	z, SndParam_RW_ExactMatch_Skip2
	.byte	0xcf,	0xff
SndParam_RW_ExactMatch_Skip2:
	ld	a, (xbc+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cp	l, (xbc+1)
	jr	nz, SndParam_RW_ExactMatch_Skip3
	ld	xwa, 3:i3
	jr	SndParam_RW_ExactMatch_Join
SndParam_RW_ExactMatch_Skip3:
	ld	xwa, 5:i3
	cp	l, (xbc+2)
	jr	nz, SndParam_RW_ExactMatch_Join
	ld	xwa, 4:i3
SndParam_RW_ExactMatch_Join:
	add	xbc, xwa
SndParam_RW_HandleB1Type:
	ld	l, (xbc)
	extz	hl
	ret
SndParam_RW_HandleB1Type_Skip:
	ldw	hl, 65535
	ret
SndParam_RegisterSimple_Data_Helper:
	ldw	hl, 65535
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+bc)
	or	xde, xde
SndParam_RW_Success:
	ret	z
	.set	SndParam_RW_Fail, . + 2
	ld	c, (xwa+5)
	extz	bc
SndParam_RW_Epilogue:
	add	bc, bc
	.set	SndParam_ResolveWidgetEx_Data, . + 3
	ld	de, (xde+bc)
	ld	a, (xwa+11)
	sla	a, 2
	lda	xbc, (SndParam_ReadRegWord_Data:24)
	ld	xwa, (xbc+a)
	ld	hl, 0:i3
SndParam_RW_HandleB1Type_Loop:
	cp	de, (xwa+)
	ret	z
	inc	1, hl
	cp	hl, 5:i3
	jr	le, SndParam_RW_HandleB1Type_Loop
	ld	hl, 0:i3
	ret
	ld	l, 0:opc
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xix, (xde+bc)
	or	xix, xix
	jr	z, SndParam_RW_HandleB1Type_Join
	ld	c, (xwa+5)
	extz	bc
	ld	de, bc
	inc	1, de
	.byte	0xf3,	0x07, 0xf0, 0xe8, 0xca
	jr	nz, SndParam_RW_HandleB1Type_Skip4
	ld	l, (xix+bc)
	ld	c, (xwa+6)
	ld	b, c
	ld	e, (xwa+10)
	xor	l, e
	and	l, b
	ld	e, (xwa+9)
	ld	a, e
	and	a, 15
	jr	z, SndParam_RW_HandleB1Type_Skip2
	.byte	0xcf,	0xff
SndParam_RW_HandleB1Type_Skip2:
	jr	z, SndParam_RW_HandleB1Type_Join
	ld	a, e
	and	a, 15
	jr	z, SndParam_RW_HandleB1Type_Skip3
	.byte	0xcb,	0xff
SndParam_RW_HandleB1Type_Skip3:
	xor	l, c
	jr	SndParam_RW_HandleB1Type_Join
SndParam_RW_HandleB1Type_Skip4:
	ld	l, 3:opc
SndParam_RW_HandleB1Type_Join:
	extz	hl
	ret
	ldw	hl, 65535
	ld	a, (xwa+4)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
	ret	z
	ld	wa, (xwa+8)
	and	wa, 511
	ld	hl, wa
	ret
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38456
	ld	bc, 6:i3
	ldirw
	lda_d16	xhl, (0x9638)
	ldw	(xhl), 65535
	ret
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
	lda	xhl, (SndParam_BlockRamPtrs:24)
	ld	xhl, (xhl+wa)
	or	xhl, xhl
	jrl	z, SndParam_RW_HandleB1Type_Skip10
	ld	a, (xde+7)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	le, SndParam_RW_HandleB1Type_Skip5
	ldfr_berp	a, 230
SndParam_RW_HandleB1Type_Skip5:
	ld	a, (xde+8)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	ge, SndParam_RW_HandleB1Type_Skip6
	ldfr_berp	a, 230
SndParam_RW_HandleB1Type_Skip6:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38468
	ld	bc, 6:i3
	ldirw
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	.set	SndParam_DecodeMidiAddr, . + 2
	and	a, 15
	jr	z, SndParam_RW_HandleB1Type_Skip7
	.byte	0xcb,	0xfe
SndParam_RW_HandleB1Type_Skip7:
	xor	b, c
	lda	xix, (xde+6)
	lda_d16	xwa, (0x964a)
	ld	(xsp+8), xwa
	cpw	(xsp+12), 4
	jr	nz, SndParam_RW_HandleB1Type_Skip8
	ld	c, (xix)
	and	c, b
	ld	xwa, (xsp+8)
	ld	(xwa), c
	jr	SndParam_RW_HandleB1Type_Join2
SndParam_RW_HandleB1Type_Skip8:
	lda	xiy, (xde+5)
	ld	a, (xiy)
	extz	wa
	lda	xiz, (xhl+wa)
	ld	w, (xiz)
	ldfr_berp	w, 231
	ld	c, (xix)
	ldfr_berp	c, 230
	ldto_berp	a, 230
	and	a, b
	ldfr_berp	a, 230
	cpl	c
	and	w, c
	ld	(xiz), w
	ld	a, (xiy)
	extz	wa
	lda	xhl, (xhl+wa)
	ld	c, (xhl)
	orb_erp	c, 230
	ld	(xhl), c
	ld	xwa, (xsp+8)
	ld	(xwa), c
	.set	SndParam_DMA_ProbeCheck, . + 2
SndParam_RW_HandleB1Type_Join2:
	lda_d16	xhl, (0x9644)
	ldto_berp	a, 231
	cp	a, (xhl+6)
	jr	nz, SndParam_RW_HandleB1Type_Skip9
	.set	SndParam_DMA_MatchFound, . + 2
	cpw	(xsp+12), 4
	jr	nz, SndParam_RW_HandleB1Type_Join3
SndParam_RW_HandleB1Type_Skip9:
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	.set	SndParam_DMA_ProbeAdvance, . + 2
	ld	(xhl+4), a
	ld	a, (xde+5)
	ld	(xhl+5), a
	ld	a, (xix)
	ld	(xhl+7), a
	jr	SndParam_RW_HandleB1Type_Join3
SndParam_RW_HandleB1Type_Skip10:
	ldw	(0x9644:16), 65535
	.set	SndParam_DMA_ProbeEntry, . + 1
SndParam_RW_HandleB1Type_Join3:
	ld	xhl, 38468
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	pushw	iz
	ld	hl, de
	ld	xde, xwa
	ld	a, c
	ldfr_berp	a, 230
	lda	xwa, (xde+4)
SndParam_DMA_ExtractFields:
	ld	(xsp+6), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xix+wa)
	ld	(xsp+2), xwa
	or	xwa, xwa
	jrl	z, SndParam_ResolveWidgetVariant2_Data_Skip
	ld	a, (xde+7)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	le, SndParam_RW_HandleB1Type_Skip11
	ldfr_berp	a, 230
SndParam_RW_HandleB1Type_Skip11:
	ld	a, (xde+8)
	ldfr_berp	a, 240
	extz	ix
	cp	ix, bc
	jr	ge, SndParam_RW_HandleB1Type_Skip12
	ldfr_berp	a, 230
SndParam_RW_HandleB1Type_Skip12:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38480
	ld	bc, 6:i3
	ldirw
	.set	SndParam_DMA_Zone2Check, . + 1
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RW_HandleB1Type_Skip13
	.byte	0xcb,	0xfe
SndParam_RW_HandleB1Type_Skip13:
	xor	b, c
	lda	xix, (xde+6)
	lda_d16	xiy, (0x9656)
	cp	hl, 4:i3
	jr	nz, SndParam_RW_HandleB1Type_Skip14
	ld	a, (xix)
	and	a, b
	ld	(xiy), a
	jr	SndParam_ResolveWidgetVariant2_Data_Join
SndParam_RW_HandleB1Type_Skip14:
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
	.byte	0xc3,	0x07, 0xe0, 0xf8, 0xcb
	.set	SndParam_DMA_Epilogue, . + 1
	ld	c, (xhl)
	extz	bc
	lda	xhl, (xwa+bc)
SndParam_ResolveWidgetVariant2_Data:
	ld	a, (xhl)
	orb_erp	a, 230
	ld	(xhl), a
	ld	(xiy), a
SndParam_ResolveWidgetVariant2_Data_Join:
	lda_d16	xbc, (0x9650)
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	SndParam_ResolveWidgetVariant2_Data_Join2
SndParam_ResolveWidgetVariant2_Data_Skip:
	ldw	(0x9650:16), 65535
SndParam_ResolveWidgetVariant2_Data_Join2:
	ld	xhl, 38480
	popw	iz
	inc	8, xsp
	ret
	ld	de, bc
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38492
	ld	bc, 6:i3
	ldirw
	lda_d16	xhl, (0x965c)
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
	jr	nz, SndParam_ResolveWidgetVariant2_Data_Skip2
	ldto_berp	a, 234
	res	7, a
	ld	(xbc), a
	sra	de, 7
	ld	(xix), e
	jr	SndParam_ResolveWidgetVariant2_Data_Return
SndParam_ResolveWidgetVariant2_Data_Skip2:
	lda	xiy, (xwa+6)
	ld	e, (xiy)
	ldto_berp	a, 234
	and	a, e
	ld	(xbc), a
	ld	a, (xiy)
	ld	(xix), a
SndParam_ResolveWidgetVariant2_Data_Return:
	ret
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_ResolveWidgetVariant2_Data_Skip7
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38504
	ld	bc, 6:i3
	ldirw
	ld	a, (xde+11)
	.set	SndParam_ReturnNotFound, . + 1
	sla	a, 2
	.set	SndParam_ReadRegField, . + 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, SndParam_ResolveWidgetVariant2_Data_Skip3
	ld	xwa, 2:i3
SndParam_ResolveWidgetVariant2_Data_Skip3:
	add	xbc, xwa
	ld	l, (xbc)
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_ResolveWidgetVariant2_Data_Skip4
	.byte	0xcf,	0xfe
SndParam_ResolveWidgetVariant2_Data_Skip4:
	xor	c, l
	ld	h, c
	lda	xix, (xde+6)
	lda_d16	xbc, (0x966e)
	cpw	(xsp+12), 4
	jr	nz, SndParam_ResolveWidgetVariant2_Data_Skip5
	ld	a, (xix)
	and	a, h
	ld	(xbc), a
	jr	SndParam_ResolveWidgetVariant2_Data_Join3
SndParam_ResolveWidgetVariant2_Data_Skip5:
	lda	xiy, (xde+5)
SndParam_ReadRegWithLUT:
	ld	a, (xiy)
	ldfr_berp	a, 248
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	ldfr_berp	w, 238
	ld	a, (xix)
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
SndParam_ResolveWidgetVariant2_Data_Join3:
	lda_d16	xbc, (0x9668)
	ldto_berp	a, 238
SndParam_ReadRegMasked:
	cp	a, (xbc+6)
	jr	nz, SndParam_ResolveWidgetVariant2_Data_Skip6
	.set	SndParam_ReadRegReturn, . + 2
	.set	SndParam_CompareRegField, . + 3
	cpw	(xsp+12), 4
	jr	nz, SndParam_ResolveWidgetVariant2_Data_Join4
SndParam_ResolveWidgetVariant2_Data_Skip6:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	SndParam_ResolveWidgetVariant2_Data_Join4
SndParam_ResolveWidgetVariant2_Data_Skip7:
	ldw	(0x9668:16), 65535
SndParam_ResolveWidgetVariant2_Data_Join4:
	ld	xhl, 38504
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterSimple_Data_Helper2:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), de
	ld	de, bc
	lda	xhl, (xwa+4)
	ld	c, (xhl)
SndParam_CompareShifted:
	extz	bc
	sla	bc, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xix+bc)
	or	xiz, xiz
	jrl	z, SndParam_ResolveWidgetVariant2_Data_Skip11
	ld	xiy, SndParam_ResetDefaultTable_Data
SndParam_CompareStatus5:
	ld	xix, 38516
	ld	bc, 6:i3
	ldirw
SndParam_CompareAddOffset:
	lda_d16	xix, (0x9674)
	.set	SndParam_CompareNotFound, . + 3
	ldw	(xix+2), 1
	.set	SndParam_ReadRegWord, . + 2
	ld	c, (xwa+7)
	extz	bc
	cp	bc, de
	jr	le, SndParam_ResolveWidgetVariant2_Data_Skip8
	ld	de, bc
SndParam_ResolveWidgetVariant2_Data_Skip8:
	ld	c, (xwa+8)
	extz	bc
	cp	bc, de
	jr	ge, SndParam_ResolveWidgetVariant2_Data_Skip9
	ld	de, bc
SndParam_ResolveWidgetVariant2_Data_Skip9:
	ld	c, (xwa+11)
	sla	c, 2
	lda	xiy, (SndParam_ReadRegWord_Data:24)
	ld	xiy, (xiy+c)
	exts	xde
	add	xde, xde
	add	xde, xiy
	ld	de, (xde)
	lda	xiy, (xwa+5)
	ld	c, (xiy)
	extz	bc
	add	bc, bc
	exts	xbc
SndParam_ReadRegScanLoop:
	add	xbc, xiz
	cp	(xbc), de
	jr	z, SndParam_ResolveWidgetVariant2_Data_Join5
	cpw	(xsp+4), 4
	jr	z, SndParam_ResolveWidgetVariant2_Data_Skip10
	.set	SndParam_ReadRegBitfield, . + 1
	ld	(xbc), de
SndParam_ResolveWidgetVariant2_Data_Skip10:
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
	jr	SndParam_ResolveWidgetVariant2_Data_Join5
SndParam_ResolveWidgetVariant2_Data_Skip11:
	ldw	(0x9674:16), 65535
SndParam_ResolveWidgetVariant2_Data_Join5:
	ld	xhl, 38516
	pop	xiz
	inc	2, xsp
	ret
	lda	xsp, (xsp-18)
	.set	SndParam_BitfieldZeroCheck, . + 2
	ld	(xsp+16), de
	ld	de, bc
	ld	xhl, xwa
	ld	a, e
	ldfr_berp	a, 230
	.set	SndParam_BitfieldNoShift, . + 1
	lda	xwa, (xhl+4)
	.set	SndParam_BitfieldPendingWrite, . + 2
	ld	(xsp+4), xwa
	.set	SndParam_BitfieldReturn, . + 1
	ld	a, (xwa)
	extz	wa
SndParam_ReadRegAddress:
	sla	wa, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xix+wa)
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterEntry_Data_Skip6
	ld	a, (xhl+7)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	le, SndParam_ResolveWidgetVariant2_Data_Skip12
	ldfr_berp	a, 230
	.set	SndParam_ResetDefaultTable, . + 1
SndParam_ResolveWidgetVariant2_Data_Skip12:
	ld	a, (xhl+8)
	ld	c, a
	extz	bc
	cp	bc, de
	jr	ge, SndParam_ResolveWidgetVariant2_Data_Skip13
	ldfr_berp	a, 230
SndParam_ResolveWidgetVariant2_Data_Skip13:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38528
SndParam_RegisterEntry_Data:
	ld	bc, 6:i3
	ldirw
	lda_d16	xwa, (0x9680)
	ld	(xsp+8), xwa
	lda	xix, (xwa+5)
	ld	a, (xhl+5)
	ld	(xix), a
	cp	de, 3:i3
	jr	nz, SndParam_RegisterEntry_Data_Skip
	inc	1, a
	ld	(xix), a
	ldib_erp	230, 1
	jr	SndParam_RegisterEntry_Data_Join
SndParam_RegisterEntry_Data_Skip:
	cpib_erp	230, 0
	jr	z, SndParam_RegisterEntry_Data_Join
	ld	c, (xhl+6)
	ld	a, (xhl+9)
	and	a, 15
	jr	z, SndParam_RegisterEntry_Data_Skip2
	.byte	0xcb,	0xff
SndParam_RegisterEntry_Data_Skip2:
	ldto_berp	a, 230
	xor	a, c
	ldfr_berp	a, 230
SndParam_RegisterEntry_Data_Join:
	ld	e, (xhl+10)
	ldto_berp	c, 230
	ld	a, (xhl+9)
	and	a, 15
	jr	z, SndParam_RegisterEntry_Data_Skip3
	.byte	0xcb,	0xfe
SndParam_RegisterEntry_Data_Skip3:
	ld	xwa, (xsp+8)
	inc	6, xwa
	ld	(xsp+12), xwa
	xor	e, c
	ld	d, e
	lda	xbc, (xhl+6)
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterEntry_Data_Skip4
	ld	c, (xbc)
	and	c, d
	ld	xwa, (xsp+12)
	ld	(xwa), c
	jr	SndParam_RegisterEntry_Data_Join2
SndParam_RegisterEntry_Data_Skip4:
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
	lda	xix, (xwa+bc)
	ld	c, (xix)
	orb_erp	c, 230
	ld	(xix), c
	ld	xwa, (xsp+12)
	ld	(xwa), c
SndParam_RegisterEntry_Data_Join2:
	ld	xbc, (xsp+12)
	cp	e, (xbc)
	jr	nz, SndParam_RegisterEntry_Data_Skip5
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterEntry_Data_Join3
SndParam_RegisterEntry_Data_Skip5:
	ld	xwa, (xsp+4)
	ld	xde, (xsp+8)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	c, (xhl+6)
	ld	(xde+7), c
	jr	SndParam_RegisterEntry_Data_Join3
SndParam_RegisterEntry_Data_Skip6:
	ldw	(0x9680:16), 65535
SndParam_RegisterEntry_Data_Join3:
	ld	xhl, 38528
	lda	xsp, (xsp+18)
	ret
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	.set	SndParam_RegisterEntryAlt_Data, . + 2
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterEntry_Data_Skip17
	ld	a, (xde+7)
	cp	a, l
	jr	ule, SndParam_RegisterEntry_Data_Skip7
	ld	l, a
SndParam_RegisterEntry_Data_Skip7:
	ld	a, (xde+8)
	cp	a, l
	jr	nc, SndParam_RegisterEntry_Data_Skip8
	ld	l, a
SndParam_RegisterEntry_Data_Skip8:
	lda	xbc, (SndParam_LinkTargetPtrs:24)
	ld	a, (xde+11)
	cp	a, 255
	jr	z, SndParam_RegisterEntry_Data_Skip9
	sla	a, 2
	ld	xiy, (xbc+a)
	jr	SndParam_RegisterEntry_Data_Join4
SndParam_RegisterEntry_Data_Skip9:
	ld	xiy, (xbc)
SndParam_RegisterEntry_Data_Join4:
	extz	hl
	ld	xix, xiy
	ld	bc, 0:i3
	cpw	(xiy+4), 0
	jr	le, SndParam_RegisterEntry_Data_Skip11
SndParam_RegisterEntry_Data_Loop:
	ld	xwa, (xix)
	.byte	0xc3,	0x07, 0xe0, 0xe4, 0xf7
	jr	nz, SndParam_RegisterEntry_Data_Skip10
	ld	wa, bc
	jr	SndParam_RegisterEntry_Data_Join5
SndParam_RegisterEntry_Data_Skip10:
	inc	1, bc
	cp	bc, (xix+4)
	jr	lt, SndParam_RegisterEntry_Data_Loop
SndParam_RegisterEntry_Data_Skip11:
	ld	wa, (xix+7)
SndParam_RegisterEntry_Data_Join5:
	ld	xhl, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, SndParam_RegisterEntry_Data_Skip12
	ld	xwa, (xhl)
	ld	l, (xwa)
	jr	SndParam_RegisterEntry_Data_Join6
SndParam_RegisterEntry_Data_Skip12:
	ld	wa, (xhl+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterEntry_Data_Skip13
	ld	xwa, (xhl)
	ld	l, (xwa+bc)
	jr	SndParam_RegisterEntry_Data_Join6
SndParam_RegisterEntry_Data_Skip13:
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xhl)
	ld	l, (xwa+bc)
SndParam_RegisterEntry_Data_Join6:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38540
	ld	bc, 6:i3
	ldirw
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RegisterEntry_Data_Skip14
	.byte	0xcf,	0xfe
SndParam_RegisterEntry_Data_Skip14:
	xor	c, l
	ld	h, c
	lda	xbc, (xde+6)
	lda_d16	xix, (0x9692)
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterEntry_Data_Skip15
	ld	a, (xbc)
	and	a, h
	ld	(xix), a
	jr	SndParam_RegisterEntry_Data_Join7
SndParam_RegisterEntry_Data_Skip15:
	lda	xiy, (xde+5)
	ld	a, (xiy)
	ldfr_berp	a, 248
	extz	iz
	ld	xwa, (xsp+4)
	exts	xiz
	add	xiz, xwa
	ld	w, (xiz)
	ldfr_berp	w, 238
	ld	a, (xbc)
	ld	l, a
	and	l, h
	cpl	a
SndParam_UpdateEntry_Data:
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
SndParam_RegisterEntry_Data_Join7:
	lda_d16	xix, (0x968c)
	ldto_berp	a, 238
	cp	a, (xix+6)
	jr	nz, SndParam_RegisterEntry_Data_Skip16
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterEntry_Data_Join8
SndParam_RegisterEntry_Data_Skip16:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xix+4), a
	ld	a, (xde+5)
	ld	(xix+5), a
	ld	a, (xbc)
	ld	(xix+7), a
	jr	SndParam_RegisterEntry_Data_Join8
SndParam_RegisterEntry_Data_Skip17:
	ldw	(0x968c:16), 65535
SndParam_RegisterEntry_Data_Join8:
	ld	xhl, 38540
	pop	xiz
	lda	xsp, (xsp+10)
	ret
SndParam_RegisterMultiField_Data:
	dec	6, xsp
	push	xiz
	ld	(xsp+8), de
	ld	de, bc
	inc	4, xwa
	ld	(xsp+4), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jr	z, SndParam_RegisterMultiField_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38552
	ld	bc, 6:i3
	ldirw
	cp	de, 40
	jr	ge, SndParam_RegisterMultiField_Data_Skip
	ldw	de, 40
	jr	SndParam_RegisterMultiField_Data_Join
SndParam_RegisterMultiField_Data_Skip:
	cp	de, 300
	jr	le, SndParam_RegisterMultiField_Data_Join
	ldw	de, 300
SndParam_RegisterMultiField_Data_Join:
	ld	a, e
	ldfr_berp	a, 234
	lda_d16	xwa, (0x9698)
	lda	xbc, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	lda	xiy, (xwa+7)
	cpw	(xsp+8), 4
	jr	nz, SndParam_RegisterMultiField_Data_Skip2
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	ldto_berp	a, 234
	ld	(xix), a
	sra	de, 8
	ld	(xiy), e
	jr	SndParam_RegisterMultiField_Data_Join2
SndParam_RegisterMultiField_Data_Skip2:
	inc	8, xiz
	ld	wa, de
	cp	wa, (xiz)
	jr	z, SndParam_RegisterMultiField_Data_Join2
	ld	(xiz), de
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xhl), 8
	ldto_berp	a, 234
	ld	(xix), a
	ld	(xiy), 255
	jr	SndParam_RegisterMultiField_Data_Join2
SndParam_RegisterMultiField_Data_Skip3:
	ldw	(0x9698:16), 65535
SndParam_RegisterMultiField_Data_Join2:
	ld	xhl, 38552
	pop	xiz
	inc	6, xsp
	ret
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38564
	ld	bc, 6:i3
	ldirw
	lda_d16	xhl, (0x96a4)
	ldw	(xhl), 65535
	ret
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jrl	z, SndParam_RegisterLinked_Data_Skip
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38576
SndParam_RegisterBitfield_Data:
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xhl+5)
	ld	(xsp+10), xwa
	ld	a, (xwa)
	extz	wa
	lda	xix, (xiz+wa)
	ld	a, (xix)
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
	ld	qwa, wa
	ld	a, (xiy)
	ld	bc, qwa
	and	a, 15
	jr	z, SndParam_RegisterMultiField_Data_Skip4
	.byte	0xd9,	0xfd
SndParam_RegisterMultiField_Data_Skip4:
	add	bc, de
	ld	a, (xhl+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterMultiField_Data_Skip5
	ld	bc, wa
SndParam_RegisterMultiField_Data_Skip5:
	ld	a, (xhl+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_RegisterMultiField_Data_Skip6
	ld	bc, wa
SndParam_RegisterMultiField_Data_Skip6:
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda_d16	xbc, (0x96b6)
	cpw	(xsp+18), 4
	jr	nz, SndParam_RegisterMultiField_Data_Skip8
	andb_erp	e, 234
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterMultiField_Data_Skip7
	.byte	0xcd,	0xfe
SndParam_RegisterMultiField_Data_Skip7:
	or	l, e
	ld	(xbc), l
	jr	SndParam_RegisterMultiField_Data_Join3
SndParam_RegisterMultiField_Data_Skip8:
	ldto_berp	a, 234
	and	a, e
	ldfr_berp	a, 234
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterMultiField_Data_Skip9
	.byte	0xcd,	0xfe
SndParam_RegisterMultiField_Data_Skip9:
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	extz	wa
	lda	xhl, (xiz+wa)
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
SndParam_RegisterMultiField_Data_Join3:
	lda_d16	xbc, (0x96b0)
	ld	wa, (xsp+4)
	cp	a, (xbc+6)
	jr	z, SndParam_RegisterLinked_Data_Join
	ld	xwa, (xsp+14)
	ld	a, (xwa)
SndParam_RegisterLinked_Data:
	ld	(xbc+4), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	SndParam_RegisterLinked_Data_Join
SndParam_RegisterLinked_Data_Skip:
	ldw	(0x96b0:16), 65535
SndParam_RegisterLinked_Data_Join:
	ld	xhl, 38576
	pop	xiz
	lda	xsp, (xsp+16)
	ret
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jrl	z, SndParam_RegisterLinked_Data_Skip8
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38588
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xde+5)
	ld	(xsp+8), xwa
	ld	a, (xwa)
	extz	wa
	lda	xix, (xiz+wa)
	ld	a, (xix)
	ldfr_berp	a, 238
	ldto_berp	c, 238
	extz	bc
	lda	xiy, (xde+9)
	lda	xwa, (xde+6)
	ld	(xsp+4), xwa
	ld	a, (xwa)
	ldfr_berp	a, 230
	extz	wa
	ld	qwa, wa
	and	wa, bc
	ld	qwa, wa
	ld	a, (xiy)
	ld	bc, qwa
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip2
	.byte	0xd9,	0xfd
SndParam_RegisterLinked_Data_Skip2:
	add	bc, hl
	ld	a, (xde+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterLinked_Data_Skip3
	ld	bc, wa
SndParam_RegisterLinked_Data_Skip3:
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_RegisterLinked_Data_Skip4
	ld	bc, wa
SndParam_RegisterLinked_Data_Skip4:
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda_d16	xbc, (0x96c2)
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterLinked_Data_Skip6
	andb_erp	e, 238
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip5
	.byte	0xcd,	0xfe
SndParam_RegisterLinked_Data_Skip5:
	or	l, e
	ld	(xbc), l
	jr	SndParam_RegisterLinked_Data_Join2
SndParam_RegisterLinked_Data_Skip6:
	ldto_berp	a, 238
	and	a, e
	ldfr_berp	a, 238
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip7
	.byte	0xcd,	0xfe
SndParam_RegisterLinked_Data_Skip7:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	extz	wa
	lda	xhl, (xiz+wa)
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
SndParam_RegisterLinked_Data_Join2:
	lda_d16	xbc, (0x96bc)
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	SndParam_RegisterLinked_Data_Join3
SndParam_RegisterLinked_Data_Skip8:
	ldw	(0x96bc:16), 65535
	.set	SndParam_RegisterLinked2_Data, . + 3
SndParam_RegisterLinked_Data_Join3:
	ld	xhl, 38588
	pop	xiz
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+8), de
	ld	(xsp+10), bc
	ld	(xsp+12), xwa
	ld	xwa, (xsp+12)
	ld	a, (xwa+4)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterLinked_Data_Skip15
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38600
	ld	bc, 6:i3
	ldirw
	ld	xwa, (xsp+12)
	calr	SndParam_RegisterLinked_Data_Helper
	ld	xwa, (xsp+12)
	ld	a, (xwa+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cpw	(xsp+10), 0
	jr	lt, SndParam_RegisterLinked_Data_Skip9
	ld	a, (xbc)
	extz	wa
	ld	(xsp+10), wa
	jr	SndParam_RegisterLinked_Data_Join4
SndParam_RegisterLinked_Data_Skip9:
	ld	a, (xbc)
	extz	wa
	sub	(xsp+10), wa
SndParam_RegisterLinked_Data_Join4:
	add	hl, (xsp+10)
	ld	xwa, (xsp+12)
	ld	a, (xwa+7)
	extz	wa
	cp	wa, hl
	jr	le, SndParam_RegisterLinked_Data_Skip10
	ld	hl, wa
SndParam_RegisterLinked_Data_Skip10:
	ld	xwa, (xsp+12)
	ld	a, (xwa+8)
	extz	wa
	cp	wa, hl
	jr	ge, SndParam_RegisterLinked_Data_Skip11
	ld	hl, wa
SndParam_RegisterLinked_Data_Skip11:
	ld	e, (xbc)
	extz	de
	ld	xwa, 1:i3
	cp	hl, de
	jr	lt, SndParam_RegisterLinked_Data_Skip12
	ld	xwa, 2:i3
SndParam_RegisterLinked_Data_Skip12:
	ld	xde, xbc
	add	xde, xwa
	ld	d, (xde)
	ld	xiy, (xsp+12)
	lda	xwa, (xiy+5)
	ld	(xsp+4), xwa
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	ld	a, (xwa+hl)
	ldfr_berp	a, 234
	lda_d16	xix, (0x96c8)
	lda	xhl, (xix+6)
	ldto_berp	e, 234
	ld	a, e
	ld	(xhl), a
	ld	a, (xiy+9)
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip13
	.byte	0xcc,	0xfe
SndParam_RegisterLinked_Data_Skip13:
	ld	a, (xiy+10)
	xor	a, d
	ldfr_berp	a, 235
	inc	6, xiy
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
	jr	z, SndParam_RegisterLinked_Data_Join6
	cpw	(xsp+8), 4
	jr	z, SndParam_RegisterLinked_Data_Skip14
	ld	xwa, (xsp+4)
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp)
	ld	(xwa+bc), e
	jr	SndParam_RegisterLinked_Data_Join5
SndParam_RegisterLinked_Data_Skip14:
	cp	(xbc+6), 1
	jr	nz, SndParam_RegisterLinked_Data_Join5
	ld	a, (xiy)
	ld	(xhl), a
SndParam_RegisterLinked_Data_Join5:
	ld	xwa, (xsp+12)
	ld	a, (xwa+4)
	ld	(xix+4), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xix+5), a
	ld	a, (xiy)
	ld	(xix+7), a
	jr	SndParam_RegisterLinked_Data_Join6
SndParam_RegisterLinked_Data_Skip15:
	ldw	(0x96c8:16), 65535
SndParam_RegisterLinked_Data_Join6:
	ld	xhl, 38600
	lda	xsp, (xsp+16)
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), bc
	ld	xiz, xwa
	ld	a, (xiz+4)
SndParam_RegisterSimple_Data:
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
	jr	z, SndParam_RegisterSimple_Data_Skip3
	ld	xwa, xiz
	calr	SndParam_RegisterSimple_Data_Helper
	ld	bc, hl
	add	bc, (xsp+6)
	ld	a, (xiz+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterSimple_Data_Skip
	ld	bc, wa
SndParam_RegisterSimple_Data_Skip:
	ld	a, (xiz+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_RegisterSimple_Data_Skip2
	ld	bc, wa
SndParam_RegisterSimple_Data_Skip2:
	ld	xwa, xiz
	ld	de, (xsp+4)
	calr	SndParam_RegisterSimple_Data_Helper2
	ld	(0x96d4:16), xhl
SndParam_RegisterSimple_Data_Skip3:
	ld	xhl, (0x96d4:16)
	pop	xiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+16), de
	ld	(xsp+18), bc
	ld	xde, xwa
	lda	xwa, (xde+4)
	ld	(xsp+12), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterChained_Data_Skip8
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38616
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
	ld	a, (xwa+bc)
	ldfr_berp	a, 238
	andb_erp	h, 238
	ld	c, h
	.set	SndParam_DeregisterEntry_Data, . + 2
	ld	h, (xde+9)
	ld	a, h
	and	a, 15
	jr	z, SndParam_RegisterSimple_Data_Skip4
	.byte	0xcb,	0xff
SndParam_RegisterSimple_Data_Skip4:
	ld	w, c
	lda	xbc, (SndParam_LinkTargetPtrs:24)
	ld	a, (xde+11)
	cp	a, 255
SndParam_RegisterChained_Data:
	jr	z, SndParam_RegisterChained_Data_Skip
	sla	a, 2
	ld	xiy, (xbc+a)
	jr	SndParam_RegisterChained_Data_Join
SndParam_RegisterChained_Data_Skip:
	ld	xiy, (xbc)
SndParam_RegisterChained_Data_Join:
	ld	a, w
	extz	wa
	ld	xix, xiy
	ld	w, a
	ld	de, 0:i3
	cpw	(xiy+4), 0
	jr	le, SndParam_RegisterChained_Data_Skip3
SndParam_RegisterChained_Data_Loop:
	ld	xbc, (xix)
	.byte	0xc3,	0x07, 0xe4, 0xe8, 0xf0
	jr	nz, SndParam_RegisterChained_Data_Skip2
	ld	wa, de
	jr	SndParam_RegisterChained_Data_Join2
SndParam_RegisterChained_Data_Skip2:
	inc	1, de
	cp	de, (xix+4)
	jr	lt, SndParam_RegisterChained_Data_Loop
SndParam_RegisterChained_Data_Skip3:
	ld	wa, (xix+7)
SndParam_RegisterChained_Data_Join2:
	add	wa, (xsp+18)
	ld	xde, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, SndParam_RegisterChained_Data_Skip4
	ld	xwa, (xde)
	ld	e, (xwa)
	jr	SndParam_RegisterChained_Data_Join3
SndParam_RegisterChained_Data_Skip4:
	ld	wa, (xde+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterChained_Data_Skip5
	ld	xwa, (xde)
	ld	e, (xwa+bc)
	jr	SndParam_RegisterChained_Data_Join3
SndParam_RegisterChained_Data_Skip5:
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xde)
	ld	e, (xwa+bc)
SndParam_RegisterChained_Data_Join3:
	ldto_berp	b, 238
	ldto_berp	a, 238
	ldfr_berp	a, 230
	cpl	l
	ldto_berp	a, 230
	and	a, l
	ldfr_berp	a, 230
	ld	a, h
	and	a, 15
	jr	z, SndParam_RegisterChained_Data_Skip6
	.byte	0xcd,	0xfe
SndParam_RegisterChained_Data_Skip6:
	ldto_berp	a, 230
	or	a, e
	ldfr_berp	a, 230
	lda_d16	xde, (0x96d8)
	ldto_berp	a, 230
	ld	(xde+6), a
	cpw	(xsp+16), 4
	jr	z, SndParam_RegisterChained_Data_Skip7
	ld	xwa, (xsp+8)
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	ldto_berp	c, 230
	ld	(xwa+hl), c
SndParam_RegisterChained_Data_Skip7:
	ldto_berp	a, 230
	cp	a, b
	jr	z, SndParam_RegisterChained_Data_Join4
	ld	xwa, (xsp+12)
	ld	a, (xwa)
	ld	(xde+4), a
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	ld	(xde+5), a
	ld	xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xde+7), a
	jr	SndParam_RegisterChained_Data_Join4
SndParam_RegisterChained_Data_Skip8:
	ldw	(0x96d8:16), 65535
SndParam_RegisterChained_Data_Join4:
	ld	xhl, 38616
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-10)
	pushw	iz
	ld	(xsp+8), de
	ld	(xsp+10), bc
	lda	xde, (xwa+4)
	ld	a, (xde)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
	jrl	z, SndParam_RegisterChained_Data_Skip11
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38628
	ld	bc, 6:i3
	ldirw
	lda	xiy, (xwa+8)
	ld	iz, (xiy)
	ld	bc, iz
	and	bc, 511
	.set	SndParam_RegisterChained2_Data, . + 1
	add	bc, (xsp+10)
	cp	bc, 40
	jr	ge, SndParam_RegisterChained_Data_Skip9
	ldw	bc, 40
	jr	SndParam_RegisterChained_Data_Join5
SndParam_RegisterChained_Data_Skip9:
	cp	bc, 300
	jr	le, SndParam_RegisterChained_Data_Join5
	ldw	bc, 300
SndParam_RegisterChained_Data_Join5:
	ld	a, c
	ld	(xsp+2), a
	ld	a, (xde)
	ldfr_berp	a, 230
	lda_d16	xwa, (0x96e4)
	lda	xde, (xwa+4)
	lda	xhl, (xwa+5)
	lda	xix, (xwa+6)
	inc	7, xwa
	ld	(xsp+4), xwa
	cpw	(xsp+8), 4
	jr	nz, SndParam_RegisterChained_Data_Skip10
	cp	iz, bc
	jr	z, SndParam_RegisterChained_Data_Join6
	ldto_berp	a, 230
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	sra	bc, 8
	and	bc, 1
	ld	xwa, (xsp+4)
	ld	(xwa), c
	jr	SndParam_RegisterChained_Data_Join6
SndParam_RegisterChained_Data_Skip10:
	ld	(xiy), bc
	cp	iz, bc
	jr	z, SndParam_RegisterChained_Data_Join6
	ldto_berp	a, 230
	ld	(xde), a
	ld	(xhl), 8
	ld	a, (xsp+2)
	ld	(xix), a
	ld	xwa, (xsp+4)
	ld	(xwa), 255
	jr	SndParam_RegisterChained_Data_Join6
SndParam_RegisterChained_Data_Skip11:
	ldw	(0x96e4:16), 65535
SndParam_RegisterChained_Data_Join6:
	ld	xhl, 38628
	popw	iz
	lda	xsp, (xsp+10)
	ret
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterComplex_Data_Skip6
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 38640
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xde+5)
	ld	(xsp+14), xwa
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp+4)
	lda	xix, (xwa+bc)
	ld	l, (xix)
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
	jr	z, SndParam_RegisterChained_Data_Skip12
	.byte	0xd9,	0xfd
SndParam_RegisterChained_Data_Skip12:
	add	bc, (xsp+24)
	ld	a, (xde+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterChained_Data_Skip13
	ld	bc, wa
SndParam_RegisterChained_Data_Skip13:
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
SndParam_RegisterComplex_Data:
	jr	ge, SndParam_RegisterComplex_Data_Skip
	ld	bc, wa
SndParam_RegisterComplex_Data_Skip:
	ld	xwa, (xsp+18)
	ld	h, (xwa)
	lda_d16	xiz, (0x96f0)
	lda	xde, (xiz+6)
	cpw	(xsp+22), 4
	jr	nz, SndParam_RegisterComplex_Data_Skip4
	ld	xbc, xiz
	ld	(xiz+4), h
	ld	xwa, (xsp+14)
	ld	a, (xwa)
	ld	(xiz+5), a
	lda	xwa, (xiz+7)
	cpw	(xsp+24), 0
	jr	le, SndParam_RegisterComplex_Data_Skip2
	ld	(xwa), 2
	ld	(xde), 2
	jr	SndParam_RegisterComplex_Data_Join
SndParam_RegisterComplex_Data_Skip2:
	cpw	(xsp+24), 0
	jr	ge, SndParam_RegisterComplex_Data_Skip3
	ld	(xwa), 1
	ld	(xde), 1
	jr	SndParam_RegisterComplex_Data_Join
SndParam_RegisterComplex_Data_Skip3:
	ldw	(xbc), 65535
SndParam_RegisterComplex_Data_Join:
	ld	xhl, xbc
	jr	SndParam_RegisterComplex_Data_Epilogue
SndParam_RegisterComplex_Data_Skip4:
	ldto_berp	w, 230
	cpl	w
	and	l, w
	ld	(xix), l
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterComplex_Data_Skip5
	.byte	0xcb,	0xfe
SndParam_RegisterComplex_Data_Skip5:
	ld	l, c
	ld	xiy, (xsp+14)
	ld	c, (xiy)
	extz	bc
	ld	xwa, (xsp+4)
	lda	xix, (xwa+bc)
	ld	c, (xix)
	or	c, l
	ld	(xix), c
	ld	(xde), c
	ld	wa, (xsp+8)
	cp	a, c
	jr	z, SndParam_RegisterComplex_Data_Join2
	ld	(xiz+4), h
	ld	a, (xiy)
	ld	(xiz+5), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xiz+7), a
	jr	SndParam_RegisterComplex_Data_Join2
SndParam_RegisterComplex_Data_Skip6:
	ldw	(0x96f0:16), 65535
SndParam_RegisterComplex_Data_Join2:
	ld	xhl, 38640
SndParam_RegisterComplex_Data_Epilogue:
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	ld	de, bc
	ld	xbc, xwa
	ld	l, e
	ld	a, (xbc+7)
	cp	a, l
	jr	ule, SndParam_RegisterComplex_Data_Skip7
	ld	l, a
SndParam_RegisterComplex_Data_Skip7:
	ld	a, (xbc+8)
	cp	a, l
	jr	nc, SndParam_RegisterComplex_Data_Skip8
	ld	l, a
SndParam_RegisterComplex_Data_Skip8:
	ld	a, (xbc+9)
	and	a, 15
	jr	z, SndParam_RegisterComplex_Data_Skip9
	.byte	0xcf,	0xfe
SndParam_RegisterComplex_Data_Skip9:
	ld	a, (xbc+10)
	xor	a, l
	ld	l, (xbc+6)
	and	l, a
	extz	hl
	ret
	ld	hl, bc
	ld	xbc, xwa
	ld	a, (xbc+11)
	sla	a, 2
	lda	xde, (Naka_SubDispatch_B_Table:24)
	ld	xde, (xde+a)
	ld	xwa, 1:i3
	cp	l, (xde)
	jr	c, SndParam_RegisterComplex_Data_Skip10
	ld	xwa, 2:i3
SndParam_RegisterComplex_Data_Skip10:
	add	xde, xwa
	ld	l, (xde)
	ld	a, (xbc+9)
	and	a, 15
	jr	z, SndParam_RegisterComplex_Data_Skip11
	.byte	0xcf,	0xfe
SndParam_RegisterComplex_Data_Skip11:
	ld	a, (xbc+10)
	xor	a, l
	ld	l, (xbc+6)
	and	l, a
	extz	hl
	ret
	ld	xwa, (SndParam_ClampReverbTime_Data:24)
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, SndParam_RegisterComplex_Data_Skip12
	ldw	hl, 40
	jr	SndParam_RegisterComplex_Data_Return
SndParam_RegisterComplex_Data_Skip12:
	cp	hl, 300
	ret	ule
	ldw	hl, 300
SndParam_RegisterComplex_Data_Return:
	ret
	ld	hl, bc
	ld	xde, xwa
	ld	c, (xde+6)
	ld	a, (xde+10)
SndParam_NotifyQuick_Data:
	xor	a, l
	and	a, c
	ld	l, a
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_NotifyQuick_Data_Skip
	.byte	0xcf,	0xff
SndParam_NotifyQuick_Data_Skip:
	ld	a, (xde+7)
	cp	a, l
	jr	ule, SndParam_NotifyQuick_Data_Skip2
	ld	l, a
SndParam_NotifyQuick_Data_Skip2:
	ld	a, (xde+8)
	cp	a, l
	jr	nc, SndParam_NotifyQuick_Data_Skip3
	ld	l, a
SndParam_NotifyQuick_Data_Skip3:
	extz	hl
	ret
	ld	hl, bc
	ld	xde, xwa
	ld	c, (xde+6)
	ld	a, (xde+10)
	xor	a, l
	and	a, c
	ld	l, a
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_NotifyQuick_Data_Skip4
	.byte	0xcf,	0xff
SndParam_NotifyQuick_Data_Skip4:
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cp	l, (xbc+1)
	jr	nz, SndParam_NotifyQuick_Data_Skip5
	.set	SndParam_RegisterDual_Data, . + 1
	ld	xwa, 3:i3
	jr	SndParam_NotifyQuick_Data_Join
SndParam_NotifyQuick_Data_Skip5:
	ld	xwa, 5:i3
	cp	l, (xbc+2)
	jr	nz, SndParam_NotifyQuick_Data_Join
	ld	xwa, 4:i3
SndParam_NotifyQuick_Data_Join:
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret
	ld	xwa, (SndParam_ClampReverbTime_Data:24)
	ld	hl, (xwa+8)
	and	hl, 511
	cp	hl, 40
	jr	nc, SndParam_NotifyQuick_Data_Skip6
	ldw	hl, 40
	jr	SndParam_NotifyQuick_Data_Return
SndParam_NotifyQuick_Data_Skip6:
	cp	hl, 300
	ret	ule
	ldw	hl, 300
SndParam_NotifyQuick_Data_Return:
	ret
	ldw	hl, 65535
	ret
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
	jr	z, SndParam_NotifyQuick_Data_Skip7
	.byte	0xdb,	0xfc
SndParam_NotifyQuick_Data_Skip7:
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
	calr	SndParam_NotifyQuick_Data_Helper
	ld	hl, 0:i3
	inc	4, xsp
	ret
	dec	4, xsp
	ld	hl, bc
	ld	xde, xwa
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, SndParam_NotifyQuick_Data_Skip8
	ld	xwa, 2:i3
SndParam_NotifyQuick_Data_Skip8:
	add	xbc, xwa
	ld	l, (xbc)
	lda	xbc, (xsp)
	ld	a, (xde+4)
	ld	(xbc), a
	ld	a, (xde+5)
	ld	(xbc+1), a
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_NotifyQuick_Data_Skip9
	.byte	0xcf,	0xfe
SndParam_NotifyQuick_Data_Skip9:
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
	calr	SndParam_NotifyQuick_Data_Helper
	ld	hl, 0:i3
	inc	4, xsp
	ret
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
	calr	SndParam_NotifyQuick_Data_Helper
	ld	hl, 0:i3
	inc	4, xsp
	ret
	ld	a, (xwa+4)
	extz	wa
	add	wa, wa
	lda_d16	xde, (0x96fc)
	ld	(xde+wa), bc
	ld	hl, 0:i3
	ret
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), bc
	ld	(xsp+22), xwa
	ldib_erp	250, 0
	ldib_erp	249, 0
	ldib_erp	251, 0
	ld	xwa, 8705
	calr	AcApcToggleProc_Helper
	ld	wa, (xsp+20)
	ld	d, a
	lda_d16	xix, (0x96fc)
	ld	xwa, (xsp+22)
	lda	xbc, (xwa+4)
	cp	hl, 3:i3
	jr	z, SndParam_NotifyQuick_Data_Skip11
	cp	hl, 1:i3
	jr	z, SndParam_NotifyQuick_Data_Skip10
	cp	hl, 0:i3
	jrl	nz, SndParam_NotifyQuick_Data_Join2
	lda	xwa, (xsp+10)
	ld	e, (xbc)
SndParam_RegisterOffset_Data:
	ld	(xwa+2), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	ld	bc, (xix+bc)
	and	bc, 127
	ld	(xwa+4), c
	call	SndParam_FetchOscTableEntry
	lda	xbc, (xsp+10)
	ld	a, (xbc+1)
	ldfr_berp	a, 250
	res_erpb	250, 7
	srl	a, 7
	ldfr_berp	a, 249
	ld	a, (xbc)
	ldfr_berp	a, 251
	bit_erpb	251, 7
	jr	z, SndParam_NotifyQuick_Data_Join2
	res_erpb	251, 7
	inc1b_erp	250
	jr	SndParam_NotifyQuick_Data_Join2
SndParam_NotifyQuick_Data_Skip10:
	ld	a, (xbc)
	extz	wa
	add	wa, wa
	ld	wa, (xix+wa)
	and	wa, 7
	sll	a, 4
	ldfr_berp	a, 250
	ldib_erp	249, 0
	ldfr_berp	d, 251
	bit	7, d
	jr	z, SndParam_NotifyQuick_Data_Join2
	res_erpb	251, 7
	ldib_erp	249, 1
	jr	SndParam_NotifyQuick_Data_Join2
SndParam_NotifyQuick_Data_Skip11:
	lda	xwa, (xsp+4)
	ld	e, (xbc)
	ld	(xwa+5), e
	ld	(xwa+3), d
	ld	c, (xbc)
	extz	bc
	add	bc, bc
	ld	bc, (xix+bc)
	and	bc, 127
	ld	(xwa+4), c
	call	SndParam_ComputeVoiceIndex
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	ldfr_berp	a, 250
	ld	a, (xbc+1)
	ldfr_berp	a, 249
	ld	a, (xbc+2)
	ldfr_berp	a, 251
SndParam_NotifyQuick_Data_Join2:
	lda	xwa, (xsp+16)
	ld	(xwa), 129
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa+1), c
	ldto_berp	c, 250
	ld	(xwa+2), c
	ldto_berp	c, 249
	ld	(xwa+3), c
	calr	SndParam_NotifyQuick_Data_Helper
	.set	SndParam_RegisterWide_Data, . + 1
	lda	xwa, (xsp+16)
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa), c
	ld	(xwa+1), 0
	ldto_berp	c, 251
	ld	(xwa+2), c
	ld	(xwa+3), 255
	calr	SndParam_NotifyQuick_Data_Helper
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SndParam_NotifyQuick_Data_Helper:
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
Audio_ResetAfterPayloadError_Helper_Helper:
	cp	(xbc+4), 72
	jr	nz, SndParam_NotifyQuick_Data_Skip12
	cp	(xbc+5), 8
	jr	nz, SndParam_NotifyQuick_Data_Skip12
	cp	wa, 4:i3
	jr	z, SndParam_NotifyQuick_Data_Skip13
SndParam_NotifyQuick_Data_Skip12:
	cp	(xbc+7), 0
	ret	z
SndParam_NotifyQuick_Data_Skip13:
	calr	SndParam_NotifyQuick_Data_Helper2
	ret
SndParam_NotifyQuick_Data_Helper2:
	push	xiz
	ld	xiz, xbc
	ld	hl, wa
	ld	a, (xiz+7)
	ldfr_berp	a, 240
	extz	ix
	ld	e, (xiz+6)
	extz	de
	ld	c, (xiz+5)
	extz	bc
	ld	a, (xiz+4)
	extz	wa
	cp	hl, 4:i3
	jr	z, SndParam_NotifyQuick_Data_Skip16
	cp	hl, 3:i3
	jr	z, SndParam_NotifyQuick_Data_Skip15
	cp	hl, 2:i3
	jr	z, SndParam_NotifyQuick_Data_Skip14
	cp	hl, 1:i3
	jr	nz, SndParam_NotifyQuick_Data_Epilogue
	cpw	(0x9042:16), 508
	call	nc, (SwbtWr_ReinitBothBanks:24)
	lda_d16	xbc, (SWBTWR_EVENT_QUEUE)
	ldw_d16	de, (0x9042)
	extz	xde
	add	xde, xbc
	ld	a, (xiz+4)
	ld	(xde+), a
	ld	a, (xiz+5)
	ld	(xde+), a
	ld	a, (xiz+6)
	ld	(xde+), a
	ld	a, (xiz+7)
	ld	(xde+), a
	jr	SndParam_NotifyQuick_Data_Join3
SndParam_NotifyQuick_Data_Skip14:
	cpw	(0x9042:16), 508
	call	nc, (SwbtWr_ReinitOutputBank:24)
	lda_d16	xbc, (SWBTWR_EVENT_QUEUE)
	ldw_d16	de, (0x9042)
	extz	xde
	add	xde, xbc
	ld	a, (xiz+4)
	ld	(xde+), a
	ld	a, (xiz+5)
	ld	(xde+), a
	ld	a, (xiz+6)
	ld	(xde+), a
	ld	a, (xiz+7)
	ld	(xde+), a
SndParam_NotifyQuick_Data_Join3:
	ld	(xde), 255
	incw	4, (0x9042:16)
	jr	SndParam_NotifyQuick_Data_Epilogue
SndParam_NotifyQuick_Data_Skip15:
	pushw	ix
	call	AddswbWr
	jr	SndParam_NotifyQuick_Data_Epilogue
SndParam_NotifyQuick_Data_Skip16:
	pushw	ix
	call	SwbtWr
SndParam_NotifyQuick_Data_Epilogue:
	pop	xiz
	ret
Audio_ResetAfterPayloadError_Helper_Helper2:
	push	xiz
	ld	xiz, xbc
	ld	e, (xiz+7)
	cp	e, 0:i3
	jrl	z, SndParam_NotifyQuick_Data_Epilogue2
	lda	xiy, (xiz+6)
	ldfr_berp	e, 240
	extz	ix
	ld	c, (xiz+5)
	extz	bc
	ld	l, (xiz+4)
	extz	hl
	cp	wa, 4:i3
	jrl	z, SndParam_NotifyQuick_Data_Skip19
	cp	wa, 3:i3
	jrl	z, SndParam_NotifyQuick_Data_Skip18
	cp	wa, 2:i3
	jr	z, SndParam_NotifyQuick_Data_Skip17
	cp	wa, 1:i3
	jrl	nz, SndParam_NotifyQuick_Data_Epilogue2
	.set	SndParam_EncodeFieldDirect_Data, . + 2
	cpw	(0x9042:16), 504
	call	nc, (SwbtWr_ReinitBothBanks:24)
	lda_d16	xbc, (SWBTWR_EVENT_QUEUE)
	ldw_d16	de, (0x9042)
	extz	xde
	add	xde, xbc
	ld	a, (xiz+4)
	ld	(xde+), a
	ld	a, (xiz+5)
	ld	(xde+), a
	ld	a, (xiz+6)
	ld	(xde+), a
	ld	a, (xiz+7)
	ld	(xde+), a
	.set	SndParam_EncodeFieldSub_Data, . + 2
	ld	a, (xiz+8)
	ld	(xde+), a
	ld	a, (xiz+9)
	ld	(xde+), a
	ld	a, (xiz+10)
	ld	(xde+), a
	ld	a, (xiz+11)
	ld	(xde+), a
	jr	SndParam_NotifyQuick_Data_Join4
SndParam_NotifyQuick_Data_Skip17:
	cpw	(0x9042:16), 504
	call	nc, (SwbtWr_ReinitOutputBank:24)
	lda_d16	xbc, (SWBTWR_EVENT_QUEUE)
	ldw_d16	de, (0x9042)
	extz	xde
	add	xde, xbc
	ld	a, (xiz+4)
	ld	(xde+), a
	.set	SndParam_ClampReverbTime, . + 2
	ld	a, (xiz+5)
	ld	(xde+), a
	ld	a, (xiz+6)
	ld	(xde+), a
	ld	a, (xiz+7)
	ld	(xde+), a
	ld	a, (xiz+8)
	ld	(xde+), a
	ld	a, (xiz+9)
	ld	(xde+), a
	ld	a, (xiz+10)
	.set	SndParam_DecodeField_Data, . + 2
	ld	(xde+), a
	ld	a, (xiz+11)
	ld	(xde+), a
SndParam_NotifyQuick_Data_Join4:
	ld	(xde), 255
	incw	8, (0x9042:16)
	jr	SndParam_NotifyQuick_Data_Epilogue2
SndParam_NotifyQuick_Data_Skip18:
	ld	e, (xiy)
	extz	de
	pushw	ix
	ld	wa, hl
	call	AddswbWr
	ld	a, (xiz+8)
	extz	wa
	ld	c, (xiz+9)
	extz	bc
	ld	e, (xiz+10)
	extz	de
	ld	l, (xiz+11)
	extz	hl
SndParam_DecodeFieldAlt_Data:
	pushw	hl
	call	AddswbWr
	jr	SndParam_NotifyQuick_Data_Epilogue2
SndParam_NotifyQuick_Data_Skip19:
	and	e, (xiy)
	extz	de
	pushw	ix
	ld	wa, hl
	call	SwbtWr
	ld	a, (xiz+8)
	extz	wa
	ld	c, (xiz+9)
	extz	bc
	ld	l, (xiz+11)
	ld	e, l
	and	e, (xiz+10)
	extz	de
	extz	hl
	pushw	hl
	call	SwbtWr
SndParam_NotifyQuick_Data_Epilogue2:
	pop	xiz
	ret
	ld	iy, 0:i3
	ld	ix, de
	sub	ix, 1
	jr	c, SndParam_NotifyQuick_Data_Skip22
SndParam_NotifyQuick_Data_Loop:
	ld	hl, iy
	add	hl, ix
	srl	hl, 1
	ld	de, hl
	.set	SndParam_ClampDelayTime, . + 1
	extz	xde
	add	xde, xbc
	ld	e, (xde)
	cp	a, e
	jr	nz, SndParam_NotifyQuick_Data_Skip20
	ld	hl, 0:i3
	ret
SndParam_NotifyQuick_Data_Skip20:
	cp	a, e
	jr	ule, SndParam_NotifyQuick_Data_Skip21
	ld	iy, hl
	inc	1, iy
	jr	SndParam_NotifyQuick_Data_Join5
SndParam_NotifyQuick_Data_Skip21:
	ld	ix, hl
	dec	1, ix
SndParam_NotifyQuick_Data_Join5:
	cp	iy, ix
	jr	ule, SndParam_NotifyQuick_Data_Loop
SndParam_NotifyQuick_Data_Skip22:
	ldw	hl, 65535
SndParam_ReturnInvalid:
	ret
	.set	SndParam_WriteFieldDirect_Data, . + 3
UIState_CheckAndRenderBitmap_Helper_Helper:
	ld	xhl, 32768
	and	wa, 63
	sll	wa, 10
	extz	xwa
	add	xhl, xwa
	ld	wa, bc
	and	wa, 1023
	extz	xwa
	or	xhl, xwa
	cp	bc, 1024
	ret	c
	add	xhl, 0x10000
	ret
SndParam_NotifyQuick_Data_Helper3:
	lda	xbc, (0x34100:24)
	ld	xwa, xbc
	lda	xde, (xbc+16376)
SndParam_NotifyQuick_Data_Loop2:
	ld	xiy, SndParam_InitHashFillLoop_Data
	ld	xix, xwa
	ld	bc, 4:i3
	ldirw
	inc	8, xwa
	cp	xwa, xde
	.set	SndParam_WriteFieldSub_Data, . + 1
	jr	c, SndParam_NotifyQuick_Data_Loop2
	ret
SndParam_NotifyQuick_Data_Helper4:
	push	xiz
	ld	xiz, 0:i3
SndParam_NotifyQuick_Data_Loop3:
	ld	xbc, xiz
	sll	xbc, 2
	ld	xwa, SndParam_Registry
	add	xwa, xbc
	ld	xbc, (xwa)
	ld	xwa, (xbc)
	calr	SndParam_NotifyQuick_Data_Helper5
	inc	1, xiz
	cp	xiz, 972
	jr	c, SndParam_NotifyQuick_Data_Loop3
	pop	xiz
	ret
SndParam_NotifyQuick_Data_Helper5:
	dec	6, xsp
	push	xiz
	ld	(xsp+6), xbc
	ld	xiz, xwa
	ldw	(xsp+4), 0
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
	.set	SndParam_PackAndWrite, . + 2
	srl	xhl, 16
	and	xhl, 31
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 2047
	call	DivMod32
SndParam_NotifyQuick_Data_Loop4:
	ld	wa, hl
	extz	xwa
	sll	xwa, 3
	ld	xbc, 0x34100
	add	xbc, xwa
	ld	xde, (xbc)
	cp	xde, NakaData_RomEnd
	jr	nz, SndParam_NotifyQuick_Data_Skip23
SndParam_WriteViaHash_Data:
	ld	(xbc), xiz
	ld	xwa, (xsp+6)
	ld	(xbc+4), xwa
	ld	hl, 0:i3
	jr	SndParam_NotifyQuick_Data_Epilogue3
SndParam_NotifyQuick_Data_Skip23:
	ld	wa, 0:i3
	cp	xiz, xde
	jr	z, SndParam_NotifyQuick_Data_Skip24
	.set	SndParam_BatchUpdate_Data, . + 1
	ldw	wa, 65535
SndParam_NotifyQuick_Data_Loop5:
	incm	1, (xsp+4)
	cpw	(xsp+4), 2047
	jr	ule, SndParam_NotifyQuick_Data_Skip25
	jr	SndParam_NotifyQuick_Data_Join6
SndParam_NotifyQuick_Data_Skip24:
	cp	wa, 65535
	jr	z, SndParam_NotifyQuick_Data_Loop5
	jr	SndParam_NotifyQuick_Data_Join6
SndParam_NotifyQuick_Data_Skip25:
	inc	3, hl
	extz	xhl
	div	hl, 2047
	ld	wa, qhl
	ld	hl, wa
	cp	wa, 2047
	jr	c, SndParam_NotifyQuick_Data_Loop4
SndParam_NotifyQuick_Data_Join6:
	ldw	hl, 65535
SndParam_NotifyQuick_Data_Epilogue3:
	pop	xiz
	inc	6, xsp
	ret
SndParam_NotifyQuick_Data_Helper6:
	lda_d16	xwa, (0x973c)
	ld	xbc, xwa
	lda	xde, (xwa+8188)
SndParam_NotifyQuick_Data_Loop6:
	ld	xwa, 0:i3
	ld	(xbc+), xwa
	cp	xbc, xde
	jr	c, SndParam_NotifyQuick_Data_Loop6
	lda	xde, (0x380f8:24)
	lda	xbc, (xde+2)
	ld	xwa, xbc
	lda	xbc, (xbc+16384)
SndParam_NotifyQuick_Data_Loop7:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, SndParam_NotifyQuick_Data_Loop7
	ldw	(xde), 0
	ret
SndParam_NotifyQuick_Data_Helper7:
	push	xiz
	ld	xiz, 0:i3
SndParam_NotifyQuick_Data_Loop8:
	ld	xbc, xiz
	sll	xbc, 2
	ld	xwa, SndParam_Registry
	add	xwa, xbc
	ld	xhl, (xwa)
	ld	a, (xhl+4)
	ld	c, (xhl+5)
	ld	e, (xhl+6)
	push	xhl
	calr	SndParam_NotifyQuick_Data_Helper8
	inc	1, xiz
	cp	xiz, 972
	jr	c, SndParam_NotifyQuick_Data_Loop8
	pop	xiz
	ret
SndParam_NotifyQuick_Data_Helper8:
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	ldw	wa, 12
	calr	SndParam_NotifyQuick_Data_Helper9
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jr	nz, SndParam_NotifyQuick_Data_Skip26
	ld	xwa, SndParam_OutOfMemoryMsg
	call	Debug_PrintString
	pushw	1
	call	Boot_HaltInstruction
	inc	2, xsp
SndParam_NotifyQuick_Data_Skip26:
	ld	xde, 0:i3
	ld	e, (xsp+18)
	sll	xde, 8
	ld	xwa, 0:i3
	ld	a, (xsp+20)
	sll	xwa, 16
	ld	xbc, xwa
	or	xbc, xde
	ld	xwa, 0:i3
	ld	a, (xsp+16)
	ld	(xsp+12), xwa
	or	(xsp+12), xbc
	ld	xde, (xsp+12)
	srl	xde, 8
	ld	xhl, xde
	and	xhl, 15
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 4
	and	xhl, 15
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 8
	and	xhl, 15
	add	xhl, xwa
	ld	xbc, xhl
	sll	xbc, 9
	add	xbc, xhl
	srl	xde, 12
	ld	xhl, xde
	and	xhl, 15
	add	xhl, xbc
	ld	xwa, xhl
	ld	xbc, 2047
	call	DivMod32
	ld	bc, hl
	sll	hl, 2
	.set	SndParam_WidgetNotifyType0, . + 1
	lda_d16	xde, (0x973c)
	ld	iy, hl
	extz	xiy
	add	xiy, xde
	ld	xwa, (xsp+8)
	lda	xhl, (xwa+4)
	.set	SndParam_WidgetCheckDirty, . + 1
	ld	xwa, (xsp+4)
	lda	xix, (xwa+8)
	.set	SndParam_WidgetCallHandler, . + 1
	ld	xiz, (xsp+26)
	.set	SndParam_WidgetDispatch, . + 2
	sll	bc, 2
	extz	xbc
	add	xbc, xde
	ld	xwa, (xiy)
	or	xwa, xwa
	jr	nz, SndParam_NotifyQuick_Data_Skip27
	ld	xwa, (xsp+8)
	ld	xde, (xsp+12)
	ld	(xwa), xde
	ld	(xhl), xiz
	ld	xwa, (xbc)
	ld	(xix), xwa
	ld	xwa, (xsp+4)
	ld	(xbc), xwa
	jr	SndParam_NotifyQuick_Data_Join7
SndParam_NotifyQuick_Data_Skip27:
	ld	xde, (xbc)
	ld	xwa, (xde+8)
	or	xwa, xwa
	jr	z, SndParam_NotifyQuick_Data_Skip28
SndParam_NotifyQuick_Data_Loop9:
	ld	xde, (xde+8)
	ld	xwa, (xde+8)
	or	xwa, xwa
	jr	nz, SndParam_NotifyQuick_Data_Loop9
SndParam_NotifyQuick_Data_Skip28:
	ld	xiy, (xsp+4)
	ld	xbc, (xsp+12)
	ld	(xiy), xbc
	ld	(xhl), xiz
	lda	xbc, (xde+8)
	ld	xwa, (xbc)
	ld	(xix), xwa
	ld	(xbc), xiy
SndParam_NotifyQuick_Data_Join7:
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp+18)
	retd	4
SndParam_NotifyQuick_Data_Helper9:
	cp	wa, 0:i3
	jr	z, SndParam_NotifyQuick_Data_Skip29
	lda	xbc, (0x380f8:24)
	ld	de, (xbc)
	add	de, wa
	.set	SndParam_WidgetAppendType2, . + 1
	cp	de, 16384
	jr	c, SndParam_NotifyQuick_Data_Skip30
SndParam_NotifyQuick_Data_Skip29:
	ld	xhl, 0:i3
	ret
SndParam_NotifyQuick_Data_Skip30:
	ld	de, (xbc)
	extz	xde
	inc	2, xde
	ld	xhl, xbc
	add	xhl, xde
	add	(xbc), wa
	ret
	calr	SndParam_NotifyQuick_Data_Helper3
	calr	SndParam_NotifyQuick_Data_Helper4
	calr	SndParam_NotifyQuick_Data_Helper6
	calr	SndParam_NotifyQuick_Data_Helper7
	lda_d16	xbc, (0x96fc)
	ld	xwa, xbc
	lda	xbc, (xbc+64)
SndParam_NotifyQuick_Data_Loop10:
	ldw	(xwa+), 0x0000
SndParam_WidgetAppendTail:
	cp	xwa, xbc
	jr	c, SndParam_NotifyQuick_Data_Loop10
	ret
	ret
	ret
	ret
SndParam_WidgetAppendType2_Code_Loop:
	pushw	wa
SndParam_WidgetCallType3:
	ldb_d8	a, (0xd0)
	.set	SndParam_WidgetCallType4, . + 3
	ld	(0x423:16), 0
	.set	SndParam_WidgetDispatchDone, . + 3
	and	(0x427:16), 189
SndParam_WidgetNotifyType1:
	set	3, (0x427:16)
	ld	(0x432:16), 0
	inc	1, (0xb742:16)
	popw	wa
	reti
	pushw	wa
	pushw	hl
	ldb_d8	a, (0x429)
	bit	0, a
	jr	nz, SndParam_WidgetNotifyType1_Skip
	bit	4, a
	jr	nz, SndParam_WidgetNotifyType1_Skip2
	bit	1, a
	jr	nz, SndParam_WidgetNotifyType1_Skip3
	bit	2, a
	jr	nz, SndParam_WidgetNotifyType1_Skip4
	bit	3, a
	jr	z, SndParam_WidgetNotifyType1_Skip5
	res	3, (0x429:16)
	bit	4, (0xfd50:16)
	jr	nz, SndParam_WidgetNotifyType1_Loop
	ld	(0xd0:16), 252
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip:
	res	0, (0x429:16)
	bit	4, (0xfd50:16)
	jr	nz, SndParam_WidgetNotifyType1_Loop
	ld	(0xd0:16), 248
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip2:
	res	4, (0x429:16)
SndParam_WidgetNotifyType1_Loop:
	ld	(0xd0:16), 254
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip3:
	res	1, (0x429:16)
	bit	4, (0xfd50:16)
	jr	nz, SndParam_WidgetNotifyType1_Loop
	ld	(0xd0:16), 250
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip4:
	res	2, (0x429:16)
	bit	4, (0xfd50:16)
	jr	nz, SndParam_WidgetNotifyType1_Loop
	.set	SndParam_Widget1_AppendType2, . + 3
	ld	(0xd0:16), 251
	jr	SndParam_WidgetNotifyType1_Join
SndParam_WidgetNotifyType1_Skip5:
	call	SeqBuf_MidiOut_ReadByte
	cp	hl, 65535
	jr	z, SndParam_WidgetNotifyType1_Join
	stb_d8	(0xd0), l
SndParam_WidgetNotifyType1_Join:
	ldb_d8	a, (0x429)
	and	a, 31
	jr	nz, SndParam_WidgetNotifyType1_Epilogue
	call	SeqBuf_MidiOut_CheckEmpty
	and	hl, hl
	jr	nz, SndParam_WidgetNotifyType1_Epilogue
	ld	(0xea:16), 253
SndParam_WidgetNotifyType1_Epilogue:
	popw	hl
	popw	wa
	reti
	pushw	wa
	ldb_d8	a, (0xd1)
	and	a, 28
	popw	wa
	jrl	nz, SndParam_WidgetAppendType2_Code_Loop
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	ldb_d8	a, (0xd0)
	ld	(0x425:16), 0
SndParam_Widget1_AppendTail:
	dec	2, xsp
	ld	(xsp), a
	lda	xwa, (xsp)
	push	xwa
	ld	wa, 1:i3
SndParam_Widget1_CallType3:
	pushw	wa
	call	MidiSeq_ReceiveAndForward
	inc	8, xsp
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	reti
MidiSeq_ReceiveAndForward_Helper:
	stb_d8	(0xb743), a
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	calr	MIDI_RX_CONTEXT_RESTORE
	ldb_d8	a, (0xb743)
	bit	7, a
	jr	z, SndParam_Widget1_AppendType2_Skip4
	cp	a, 247
	jr	ule, SndParam_Widget1_AppendType2_Skip
	calr	SndParam_Widget1_AppendType2_Helper
	jr	SndParam_Widget1_AppendType2_Join
SndParam_Widget1_AppendType2_Skip:
	stb_d8	(0x423), a
	and	(0x427:16), 189
	bit	0, (0x432:16)
	jr	z, SndParam_Widget1_AppendType2_Join
	.byte 0xf1, 0x32, 0x04, 0xc9
	jr	z, SndParam_Widget1_AppendType2_Skip2
	cp	a, 247
	jr	nz, SndParam_Widget1_AppendType2_Skip3
	.byte 0xf1, 0x32, 0x04, 0xcd
	jr	nz, SndParam_Widget1_AppendType2_Skip2
	pushw	wa
	call	SeqBuf2_WriteByte
	inc	2, xsp
	ld	(1074:16), 4
SndParam_Widget1_AppendType2_Skip2:
	ld	(1059:16), 0
	.byte 0xc1, 0x32, 0x04, 0x3c, 0xcc
	jr	SndParam_Widget1_AppendType2_Join
SndParam_Widget1_AppendType2_Skip3:
	ld	(1074:16), 16
	ld	(1059:16), 0
	jr	SndParam_Widget1_AppendType2_Join
SndParam_Widget1_AppendType2_Skip4:
	calr	ClkTick_BeatSubdivCheck
SndParam_Widget1_AppendType2_Join:
	calr	MIDI_RX_CONTEXT_SAVE
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
SndParam_Widget1_AppendType2_Helper:
	cp	a, 254
	jr	nz, SndParam_Widget1_AppendType2_Entry
	.byte 0xf1, 0x27, 0x04, 0xbf
SndParam_Widget1_AppendType2_Return:
	ret
SndParam_Widget1_AppendType2_Entry:
	.byte 0xf1, 0x50, 0xfd, 0xcc
	jr	nz, SndParam_Widget1_AppendType2_Return
	cp	a, 253
	jr	nc, SndParam_Widget1_AppendType2_Return
	.byte 0xf1, 0x46, 0xb7, 0xce
	jr	nz, SndParam_Widget1_AppendType2_Return
	cp	(32367:16), 0
	jr	z, SndParam_Widget1_AppendType2_Skip6
	cp	a, 250
	jr	nz, SndParam_Widget1_AppendType2_Skip5
	call	AccPlay_StopEntry
	ret
SndParam_Widget1_AppendType2_Skip5:
	cp	a, 252
	jr	nz, SndParam_Widget1_AppendType2_Skip6
	.byte 0xf1, 0x99, 0x7e, 0xb8
SndParam_Widget1_AppendType2_Skip6:
	ld	d, a
	.byte 0xf1, 0x50, 0xfd, 0xca
	jrl	z, AltClk_DisabledClockPath
	cp	d, 248
	jr	nz, SndParam_Widget1_AppendType2_Skip10
	.byte 0xf1, 0xac, 0x28, 0xcd
	jr	z, SndParam_Widget1_AppendType2_Skip7
	inc	1, (1108:16)
SndParam_Widget1_AppendType2_Skip7:
	ld	a, (1066:16)
	cp	a, 112
	jr	ugt, SndParam_Widget1_AppendType2_Skip9
	cp	a, 4:i3
	jr	ugt, SndParam_Widget1_AppendType2_Skip8
	ld	wa, (46908:16)
	jr	SndParam_Widget1_AppendType2_Join2
SndParam_Widget1_AppendType2_Skip8:
	extz	xwa
	xor	w, w
	.byte 0xd1, 0x3e, 0xb7, 0x48
	jr	SndParam_Widget1_AppendType2_Join2
SndParam_Widget1_AppendType2_Skip9:
	ld	wa, (46906:16)
SndParam_Widget1_AppendType2_Join2:
	ld	(146:16), wa
	ld	(1066:16), 0
	.byte 0xf1, 0x1f, 0x04, 0xc8
	jr	z, SndParam_Widget1_AppendType2_Entry2
	ld	(1055:16), 6
SndParam_Widget1_AppendType2_Entry2:
	.byte 0xf1, 0x1f, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Skip10
	.byte 0xc1, 0x6a, 0x04, 0x3c, 0xfc
	inc	4, (1130:16)
	cp	(1130:16), 96
	jr	nz, SndParam_Widget1_AppendType2_Skip10
	ld	(1130:16), 0
	incw	1, (1128:16)
	cp	(32367:16), 0
	jr	z, SndParam_Widget1_AppendType2_Skip10
	calr	MIDI_QUEUE_TRACK_EVENT
SndParam_Widget1_AppendType2_Skip10:
	ld	a, (1056:16)
	pushw	wa
	and	a, 5
	popw	wa
	jrl	z, SndParam_Widget1_AppendType2_Entry9
	cp	d, 248
	jrl	nz, SndParam_Widget1_AppendType2_Entry7
	bit	0, a
	jr	z, SndParam_Widget1_AppendType2_Skip12
	ld	(1056:16), 6
	.byte 0xf1, 0x1e, 0x04, 0xc8
	jr	z, SndParam_Widget1_AppendType2_Entry3
	ld	(1054:16), 6
SndParam_Widget1_AppendType2_Entry3:
	.byte 0xf1, 0x21, 0x04, 0xc8
	jr	z, SndParam_Widget1_AppendType2_Skip11
	ld	(SEQ_TRANSPORT_STATE:16), 6
SndParam_Widget1_AppendType2_Skip11:
	jrl	SndParam_Widget1_AppendType2_Entry7
SndParam_Widget1_AppendType2_Skip12:
	bit	2, a
	jr	z, SndParam_Widget1_AppendType2_Entry4
	.byte 0xc1, 0x17, 0x04, 0x3c, 0xfc
	inc	4, (1047:16)
	cp	(1047:16), 96
	jr	nz, SndParam_Widget1_AppendType2_Entry4
	ld	(1047:16), 0
	incw	1, (1048:16)
SndParam_Widget1_AppendType2_Entry4:
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Skip14
	.byte 0xc1, 0x15, 0x04, 0x3c, 0xfc
	inc	4, (1045:16)
	cp	(1045:16), 96
	jr	nz, SndParam_Widget1_AppendType2_Skip14
	ld	(1045:16), 0
	inc	1, (1046:16)
	ld	a, (14079:16)
	and	a, 31
	jr	z, SndParam_Widget1_AppendType2_Skip13
	calr	MIDI_QUEUE_TRACK_EVENT
SndParam_Widget1_AppendType2_Skip13:
	ld	a, (1046:16)
	ld	w, (1075:16)
	.byte 0xc1, 0x58, 0x04, 0x30
	cp	a, w
	jr	c, SndParam_Widget1_AppendType2_Skip14
	ld	(1046:16), 0
	inc	1, (1076:16)
	inc	1, (1077:16)
	ld	a, (1077:16)
	cp	a, (13371:16)
	jr	ule, SndParam_Widget1_AppendType2_Skip14
	ld	(1077:16), 0
SndParam_Widget1_AppendType2_Skip14:
	ld	a, (1045:16)
	ld	w, a
	sub	a, (1111:16)
	jr	z, SndParam_Widget1_AppendType2_Entry5
	jr	ugt, SndParam_Widget1_AppendType2_Skip15
	add	a, 96
SndParam_Widget1_AppendType2_Skip15:
	ld	(1111:16), w
	add	(1124:16), a
	add	(1122:16), a
	xor	w, w
	.byte 0xd1, 0x60, 0x04, 0x80
	cp	a, 96
	jr	c, SndParam_Widget1_AppendType2_Skip16
	sub	a, 96
	inc	1, w
SndParam_Widget1_AppendType2_Skip16:
	ld	(1120:16), wa
SndParam_Widget1_AppendType2_Entry5:
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Entry7
	.byte 0xc1, 0x1b, 0x04, 0x3c, 0xfc
	inc	4, (SEQ_BEAT_TICK:16)
	ld	a, (SEQ_BEAT_TICK:16)
	.byte 0xf1, 0x31, 0x04, 0xc8
	jr	z, SndParam_Widget1_AppendType2_Entry6
	cp	a, (1071:16)
	jr	nz, SndParam_Widget1_AppendType2_Entry6
	.byte 0xf1, 0x31, 0x04, 0xb0
	ld	(1054:16), 1
	cpw	(10410:16), 0
	jr	z, SndParam_Widget1_AppendType2_Entry6
	ld	a, 133:opc
	calr	MIDI_QUEUE_EVENT_PAIR
SndParam_Widget1_AppendType2_Entry6:
	.byte 0xf1, 0x31, 0x04, 0xcb
	jr	z, SndParam_Widget1_AppendType2_Skip17
	cp	a, (1072:16)
	jr	nz, SndParam_Widget1_AppendType2_Skip17
	.byte 0xf1, 0x31, 0x04, 0xb3
	ld	(1054:16), 8
	cpw	(10410:16), 0
	jr	z, SndParam_Widget1_AppendType2_Skip17
	ld	a, 134:opc
	calr	MIDI_QUEUE_EVENT_PAIR
SndParam_Widget1_AppendType2_Skip17:
	cp	(SEQ_BEAT_TICK:16), 96
	jr	nz, SndParam_Widget1_AppendType2_Return2
	ld	(SEQ_BEAT_TICK:16), 0
	incw	1, (SEQ_BEAT_COUNT:16)
	cpw	(10410:16), 0
	jr	z, SndParam_Widget1_AppendType2_Entry7
	calr	MIDI_QUEUE_TRACK_EVENT
SndParam_Widget1_AppendType2_Entry7:
	.byte 0xf1, 0x52, 0xfd, 0xca
	jr	z, SndParam_Widget1_AppendType2_Return2
	cp	d, 252
	jr	nz, SndParam_Widget1_AppendType2_Return2
	ld	(1056:16), 16
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Entry8
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Skip18
	.byte 0xf1, 0xde, 0x33, 0xba
SndParam_Widget1_AppendType2_Skip18:
	ld	(1054:16), 16
	cpw	(10410:16), 0
	jr	z, SndParam_Widget1_AppendType2_Entry8
	ld	a, 134:opc
	calr	MIDI_QUEUE_EVENT_PAIR
SndParam_Widget1_AppendType2_Entry8:
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	z, SndParam_Widget1_AppendType2_Return2
	ld	(SEQ_TRANSPORT_STATE:16), 16
	pushw	wa
	ld	a, (1045:16)
	ld	(1078:16), a
	ld	a, (1046:16)
	ld	(1079:16), a
	popw	wa
SndParam_Widget1_AppendType2_Return2:
	ret
SndParam_Widget1_AppendType2_Entry9:
	.byte 0xf1, 0x52, 0xfd, 0xca
	jr	z, SndParam_Widget1_AppendType2_Entry8
	.byte 0xf1, 0xa7, 0x28, 0xca
	jr	nz, SndParam_Widget1_AppendType2_Return3
	cp	d, 250
	jr	z, SndParam_Widget1_AppendType2_Entry10
	cp	d, 251
	jrl	z, Continue_SetRunning
SndParam_Widget1_AppendType2_Return3:
	ret
SeqEvt_ProcessTimedEvents_Helper:
	cpw	(61854:16), 0
	jr	z, SndParam_Widget1_AppendType2_Return4
	push	sr
	ei	0x06
	calr	SndParam_Widget1_AppendType2_Sub
	calr	MIDI_APPLY_STARTUP_TIMING
	pop	sr
SndParam_Widget1_AppendType2_Return4:
	ret
SndParam_Widget1_AppendType2_Entry10:
	.byte 0xf1, 0xac, 0x28, 0xbd
	ld	(1108:16), 0
	cpw	(61854:16), 0
	jr	nz, ResetPlay_Return
SndParam_Widget1_AppendType2_Sub:
	xor	wa, wa
	ld	(1047:16), a
	ld	(1048:16), wa
	.byte 0xf1, 0x20, 0x04
SndParam_HeapAllocOK:
	.incbin "includes/romslices/v7_fix_sndparam_heapallocok.bin"
