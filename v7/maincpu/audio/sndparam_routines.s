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
; 2026-10-03: the labels of that framing sat 0x41A bytes away from the code
; they name (scripts/analysis/v7_label_drift.py), 66 of them as `.set Name, . + k`
; inside instructions.  Re-derived by notes/v7-port-sndser-2026-10-03/run.sh:
; v10's text and names at the addresses of v10's code, the pre-port lines kept
; where v7's bytes differ from v10's, other files' `Name + k` references re-aimed
; at the label now at that address.  Drift 0 in this file and in
; midi/midi_serial_routines.s (the same span).
; =============================================================================
; Ported from v10 by scripts/converters/port_v10_span_to_v7.py: every
; instruction below was re-assembled to the v7 bytes; `.byte` rows are v7
; bytes with no byte-identical v10 counterpart.  Comments carried over
; from v10 may cite v10 addresses.

; A free slot of SNDPARAM_HASH_TABLE has this key (extension_data.s
; SndParam_InitHashFillLoop_Data is the {key, pointer} pair stamped over the table).  It is the
; same number as NakaData_RomEnd, which is why the probes used to spell it that way.
	.equ SNDPARAM_HASH_EMPTY_KEY, 0x00FFFFFF

	.byte 0xe8
	ld	xwa, (xsp + 14)
	ld	(xwa), hl
	ld	c, (xiz + 6)
	cpl	c
	ld	xwa, (xsp + 22)
	and	(xwa + 3), c
	jr	SndParam_RW_Success
SndParam_ProbeMatchFound_Skip:
SndParam_RW_HandleB1Type:
	ld	xwa, (xsp + 10)
	ld	c, (xwa)
	res	7, c
	extz	bc
	ld	xwa, (xsp + 6)
	ld	a, (xwa)
	res	7, a
	extz	wa
	sla	wa, 7
	ld	de, wa
SndParam_ProbeMatchFound_Skip_Part:
	or	de, bc
	ld	xwa, (xsp + 14)
	ld	(xwa), de
SndParam_RW_Success:
	ld	hl, 0:i3
	jr	SndParam_RW_Epilogue
SndParam_ProbeMatchFound_Join_Skip:
SndParam_RW_Fail:
	ldw	hl, 0xffff
SndParam_RW_Epilogue:
	pop	xiz
	lda	xsp, (xsp + 22)
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
SndParam_ResolveWidget_Join_Part:
	inc	3, wa
	extz	xwa
	div	wa, 2047
	ld	ix, qwa
SndParam_ResolveWidget_Join2:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, SNDPARAM_HASH_TABLE
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, SNDPARAM_HASH_EMPTY_KEY
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
	lda	xhl, (SndParam_EncodeHandlers:24)
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
SndParam_ResolveOscEntry_Helper:
	lda	xsp, (xsp - 22)
	push	xiz
	ld	(xsp + 14), xde
	ld	(xsp + 18), xbc
	ld	(xsp + 22), xwa
	ldw	(xsp + 4), 0xffff
	ld	xwa, (xsp + 22)
	ld	xiz, (xwa)
	ld	(xsp + 6), xiz
	ld	xwa, 0:i3
	ld	(xsp + 10), xwa
	ld	xhl, xiz
	and	xhl, 0xff
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 8
	and	xhl, 0xff
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 16
	and	xhl, 0x1f
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 0x7ff
	call	DivMod32
	ld	ix, hl
	jr	SndParam_DMA_ProbeEntry
SndParam_DMA_ProbeCheck:
	ld	bc, 0:i3
	cp	(xsp + 6), xde
SndParam_DMA_ProbeCheck_Part:
	jr	z, SndParam_DMA_MatchFound
	ldw	bc, 0xffff
	jr	SndParam_DMA_ProbeAdvance
SndParam_DMA_MatchFound:
	cp	bc, 0xffff
	jr	z, SndParam_DMA_ProbeAdvance
SndParam_DMA_MatchFound_Part:
	ld	xwa, (xwa + 4)
	ld	(xsp + 10), xwa
SndParam_DMA_ProbeAdvance:
	inc	1, hl
SndParam_DMA_ProbeAdvance_Part:
	cp	hl, 0x7ff
	jr	ugt, SndParam_DMA_ExtractFields
	ld	wa, ix
	inc	3, wa
	extz	xwa
	div	wa, 0x7ff
	ldto_werp	IX, 0xe2
SndParam_DMA_ProbeEntry:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, SNDPARAM_HASH_TABLE
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, SNDPARAM_HASH_EMPTY_KEY
	jr	nz, SndParam_DMA_ProbeCheck
SndParam_DMA_ExtractFields:
	ld	xwa, (xsp + 10)
	or	xwa, xwa
	jrl	z, SndParam_DMA_Epilogue
	ld	xbc, (xsp + 22)
	ld	xwa, (xbc)
	cp	xwa, 0x8000
	jr	c, SndParam_DMA_Zone2Check
	ld	xwa, (xbc)
	cp	xwa, 0x17fff
	jr	ugt, SndParam_DMA_Zone2Check
	sub	xiz, 0x8000
	ld	xwa, xiz
	srl	xwa, 10
	and	xwa, 0x3f
	ld	bc, wa
	ld	xwa, (xsp + 18)
	ld	(xwa), bc
	ld	xbc, xiz
	and	xbc, 0x3ff
	ld	xwa, (xsp + 14)
	ld	(xwa), bc
	ldw	(xsp + 4), 0x0
SndParam_DMA_Zone2Check:
	ld	xbc, (xsp + 22)
	ld	xwa, (xbc)
	cp	xwa, 0x18000
	jr	c, SndParam_DMA_Epilogue
	ld	xwa, (xbc)
	cp	xwa, 0x27fff
	jr	ugt, SndParam_DMA_Epilogue
	sub	xiz, 0x8000
	ld	xwa, xiz
	srl	xwa, 10
	and	xwa, 0x3f
	ld	bc, wa
	ld	xwa, (xsp + 18)
	ld	(xwa), bc
	ld	xbc, xiz
	and	xbc, 0x3ff
	add	bc, 0x400
	ld	xwa, (xsp + 14)
	ld	(xwa), bc
	ldw	(xsp + 4), 0x0
SndParam_DMA_Epilogue:
	ld	hl, (xsp + 4)
	pop	xiz
	lda	xsp, (xsp + 22)
	ret
SndParam_ResolveWidgetVariant2_Data:
	dec	8, xsp
	push	xiz
	ld	xbc, 0:i3
	ld	(xsp+4), xbc
	ld	xiz, xwa
	ld	xwa, 0:i3
SndParam_ResolveWidgetVariant2_Data_Part:
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
	ld	ix, qwa
SndParam_DecodeMidiAddr_Join2:
	ld	bc, ix
	extz	xbc
	sll	xbc, 3
	ld	xwa, SNDPARAM_HASH_TABLE
	add	xwa, xbc
	ld	xde, (xwa)
	cp	xde, SNDPARAM_HASH_EMPTY_KEY
	jr	nz, SndParam_DecodeMidiAddr_Loop
SndParam_DecodeMidiAddr_Skip2:
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	z, SndParam_DecodeMidiAddr_Skip3
	ld	c, (xwa+4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	l, (xwa+5)
	extz	hl
	ld	xwa, (xde+bc)
	lda	xwa, (xwa+hl)
	ld	(xsp+4), xwa
SndParam_DecodeMidiAddr_Skip3:
	ld	xhl, (xsp+4)
	pop	xiz
	inc	8, xsp
	ret
SndParam_ReturnNotFound:
	ldw	hl, 0xffff
	ret
SndParam_ReadRegField:
	ldw	hl, 0xffff
	ld	c, (xwa + 4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+bc)
	or	xde, xde
	ret	z
	ld	c, (xwa + 5)
	extz	bc
	ld	l, (xde+bc)
	extz	hl
	ld	e, (xwa + 6)
	extz	de
	ld	c, (xwa + 10)
	extz	bc
	xor	hl, bc
	and	hl, de
	ld	a, (xwa + 9)
	and	a, 0xf
	ret	z
	sraa	hl
SndParam_ReadRegField_Part:
	ret
SndParam_ReadRegWithLUT:
	ld	e, (xwa + 11)
SndParam_ReadRegWithLUT_Part:
	ld	c, e
	sla	c, 2
	lda	xhl, (SndParam_RegRamPtrs:24)
	ld	xbc, (xhl+c)
	ld	c, (xbc)
	cp	e, 2:i3
	jr	nz, SndParam_ReadRegMasked
	ld	a, c
	sll	a, 6
	and	a, 0x40
	ld	l, a
	extz	hl
	srl	c, 1
	res	7, c
	sll	c, 7
	extz	bc
	add	hl, bc
	cp	hl, 0x3fc0
	ret	lt
	ldw	hl, 0x3fff
	jr	SndParam_ReadRegReturn
SndParam_ReadRegMasked:
	ld	l, (xwa + 6)
	and	l, c
	extz	hl
SndParam_ReadRegReturn:
	ret
SndParam_CompareRegField:
	ld	xbc, xwa
SndParam_CompareRegField_Part:
	ld	a, (xbc + 4)
	extz	wa
	sla	wa, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+wa)
SndParam_CompareRegField_Part_2:
	or	xde, xde
SndParam_CompareRegField_Part_3:
	jr	z, SndParam_CompareNotFound
	ld	a, (xbc + 5)
	extz	wa
	ld	l, (xde+wa)
	ld	e, (xbc + 6)
	ld	a, (xbc + 10)
	xor	l, a
	and	l, e
	ld	a, (xbc + 9)
	and	a, 0xf
	jr	z, SndParam_CompareShifted
	srla	l
SndParam_CompareShifted:
	ld	a, (xbc + 11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cp	l, (xbc + 1)
	jr	nz, SndParam_CompareStatus5
	ld	xwa, 3:i3
	jr	SndParam_CompareAddOffset
SndParam_CompareStatus5:
	ld	xwa, 5:i3
	cp	l, (xbc + 2)
	jr	nz, SndParam_CompareAddOffset
	ld	xwa, 4:i3
SndParam_CompareAddOffset:
	add	xbc, xwa
SndParam_CompareAddOffset_Part:
	ld	l, (xbc)
	extz	hl
	ret
SndParam_CompareNotFound:
	ldw	hl, 0xffff
	ret
SndParam_ReadRegWord:
	ldw	hl, 0xffff
	ld	c, (xwa + 4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xde, (xde+bc)
	or	xde, xde
SndParam_ReadRegWord_Part:
	ret	z
	ld	c, (xwa + 5)
	extz	bc
SndParam_ReadRegWord_Part_2:
	add	bc, bc
	ld	de, (xde+bc)
	ld	a, (xwa + 11)
	sla	a, 2
	lda	xbc, (SndParam_ReadRegWord_Data:24)
	ld	xwa, (xbc+a)
	ld	hl, 0:i3
SndParam_ReadRegScanLoop:
	cp	DE, (xwa+)
	ret	z
	inc	1, hl
	cp	hl, 5:i3
	jr	le, SndParam_ReadRegScanLoop
	ld	hl, 0:i3
	ret
SndParam_ReadRegBitfield:
	ld	l, 0x0:opc
	ld	c, (xwa + 4)
	extz	bc
	sla	bc, 2
	lda	xde, (SndParam_BlockRamPtrs:24)
	ld	xix, (xde+bc)
	or	xix, xix
	jr	z, SndParam_BitfieldReturn
	ld	c, (xwa + 5)
	extz	bc
	ld	de, bc
	inc	1, de
	bit	2, (xix+de)
	jr	nz, SndParam_BitfieldPendingWrite
	ld	l, (xix+bc)
	ld	c, (xwa + 6)
	ld	b, c
	ld	e, (xwa + 10)
	xor	l, e
	and	l, b
	ld	e, (xwa + 9)
	ld	a, e
	and	a, 0xf
	jr	z, SndParam_BitfieldZeroCheck
	srla	l
SndParam_BitfieldZeroCheck:
	jr	z, SndParam_BitfieldReturn
	ld	a, e
	and	a, 0xf
	jr	z, SndParam_BitfieldNoShift
	srla	c
SndParam_BitfieldNoShift:
	xor	l, c
	jr	SndParam_BitfieldReturn
SndParam_BitfieldPendingWrite:
	ld	l, 0x3:opc
SndParam_BitfieldReturn:
	extz	hl
	ret
SndParam_ReadRegAddress:
	ldw	hl, 0xffff
	ld	a, (xwa + 4)
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
	ret	z
	ld	wa, (xwa + 8)
	and	wa, 0x1ff
	ld	hl, wa
	ret
SndParam_ResetDefaultTable:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9638
	ld	bc, 6:i3
	ldirw
	lda	xhl, (0x9638:16)
	ldw	(xhl), 0xffff
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
	lda	xhl, (SndParam_BlockRamPtrs:24)
	ld	xhl, (xhl+wa)
	or	xhl, xhl
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
	jr	ge, SndParam_RegisterEntry_Data_Skip4
	ldfr_berp	a, 230
SndParam_RegisterEntry_Data_Skip4:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9644
	ld	bc, 6:i3
	ldirw
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RegisterEntry_Data_Skip5
	slla	c	; sll A,C
SndParam_RegisterEntry_Data_Skip5:
	xor	b, c
	lda	xix, (xde+6)
	lda	xwa, (0x964a:16)
	ld	(xsp+8), xwa
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterEntry_Data_Skip6
	ld	c, (xix)
	and	c, b
	ld	xwa, (xsp+8)
	ld	(xwa), c
	jr	SndParam_RegisterEntry_Data_Join2
SndParam_RegisterEntry_Data_Skip6:
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
SndParam_RegisterEntry_Data_Join2:
	lda	xhl, (0x9644:16)
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
	ldw	(0x9644:16), 0xffff
SndParam_RegisterEntry_Data_Join:
	ld	xhl, 0x9644
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
SndParam_RegisterEntryAlt_Data_Part:
	ld	(xsp+6), xwa
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xix+wa)
	ld	(xsp+2), xwa
	or	xwa, xwa
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
	jr	ge, SndParam_RegisterEntryAlt_Data_Skip3
	ldfr_berp	a, 230
SndParam_RegisterEntryAlt_Data_Skip3:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9650
	ld	bc, 6:i3
	ldirw
	ld	b, (xde+10)
	ldto_berp	c, 230
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RegisterEntryAlt_Data_Skip4
	slla	c	; sll A,C
SndParam_RegisterEntryAlt_Data_Skip4:
	xor	b, c
	lda	xix, (xde+6)
	lda	xiy, (0x9656:16)
	cp	hl, 4:i3
	jr	nz, SndParam_RegisterEntryAlt_Data_Skip5
	ld	a, (xix)
	and	a, b
	ld	(xiy), a
	jr	SndParam_RegisterEntryAlt_Data_Join2
SndParam_RegisterEntryAlt_Data_Skip5:
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
	and	(xwa+iz), c
	ld	c, (xhl)
	extz	bc
	lda	xhl, (xwa+bc)
SndParam_RegisterEntryAlt_Data_Skip5_Part:
	ld	a, (xhl)
	orb_erp	a, 230
	ld	(xhl), a
	ld	(xiy), a
SndParam_RegisterEntryAlt_Data_Join2:
	lda	xbc, (0x9650:16)
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+4), a
	ld	a, (xde+5)
	ld	(xbc+5), a
	ld	a, (xix)
	ld	(xbc+7), a
	jr	SndParam_RegisterEntryAlt_Data_Join
SndParam_RegisterEntryAlt_Data_Skip2:
	ldw	(0x9650:16), 0xffff
SndParam_RegisterEntryAlt_Data_Join:
	ld	xhl, 0x9650
	popw	iz
	inc	8, xsp
	ret
SndParam_UpdateEntry_Data:
	ld	de, bc
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x965c
	ld	bc, 6:i3
	ldirw
	lda	xhl, (0x965c:16)
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterMultiField_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9668
	ld	bc, 6:i3
	ldirw
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, SndParam_RegisterMultiField_Data_Skip3
	ld	xwa, 2:i3
SndParam_RegisterMultiField_Data_Skip3:
	add	xbc, xwa
	ld	l, (xbc)
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RegisterMultiField_Data_Skip4
	slla	l	; sll A,L
SndParam_RegisterMultiField_Data_Skip4:
	xor	c, l
	ld	h, c
	lda	xix, (xde+6)
	lda	xbc, (0x966e:16)
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterMultiField_Data_Skip5
	ld	a, (xix)
	and	a, h
	ld	(xbc), a
	jr	SndParam_RegisterMultiField_Data_Join2
SndParam_RegisterMultiField_Data_Skip5:
	lda	xiy, (xde+5)
SndParam_RegisterMultiField_Data_Skip5_Part:
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
SndParam_RegisterMultiField_Data_Join2:
	lda	xbc, (0x9668:16)
	ldto_berp	a, 238
SndParam_RegisterMultiField_Data_Join2_Part:
	cp	a, (xbc+6)
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
	ldw	(0x9668:16), 0xffff
SndParam_RegisterMultiField_Data_Join:
	ld	xhl, 0x9668
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
SndParam_RegisterBitfield_Data_Part:
	extz	bc
	sla	bc, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xix+bc)
	or	xiz, xiz
	jrl	z, SndParam_RegisterBitfield_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
SndParam_RegisterBitfield_Data_Part_2:
	ld	xix, 0x9674
	ld	bc, 6:i3
	ldirw
SndParam_RegisterBitfield_Data_Part_3:
	lda	xix, (0x9674:16)
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
SndParam_RegisterBitfield_Data_Skip2_Part:
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
	ldw	(0x9674:16), 0xffff
SndParam_RegisterBitfield_Data_Join:
	ld	xhl, 0x9674
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
SndParam_RegisterLinked_Data_Part:
	sla	wa, 2
	lda	xix, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xix+wa)
	ld	(xsp), xwa
	or	xwa, xwa
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
	ld	xix, 0x9680
SndParam_RegisterLinked_Data_Skip2_Part:
	ld	bc, 6:i3
	ldirw
	lda	xwa, (0x9680:16)
	ld	(xsp+8), xwa
	lda	xix, (xwa+5)
	ld	a, (xhl+5)
	ld	(xix), a
	cp	de, 3:i3
	jr	nz, SndParam_RegisterLinked_Data_Skip5
	inc	1, a
	ld	(xix), a
	ldib_erp	230, 1
	jr	SndParam_RegisterLinked_Data_Join3
SndParam_RegisterLinked_Data_Skip5:
	cpib_erp	230, 0
	jr	z, SndParam_RegisterLinked_Data_Join3
	ld	c, (xhl+6)
	ld	a, (xhl+9)
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip6
	srla	c	; srl A,C
SndParam_RegisterLinked_Data_Skip6:
	ldto_berp	a, 230
	xor	a, c
	ldfr_berp	a, 230
SndParam_RegisterLinked_Data_Join3:
	ld	e, (xhl+10)
	ldto_berp	c, 230
	ld	a, (xhl+9)
	and	a, 15
	jr	z, SndParam_RegisterLinked_Data_Skip7
	slla	c	; sll A,C
SndParam_RegisterLinked_Data_Skip7:
	ld	xwa, (xsp+8)
	inc	6, xwa
	ld	(xsp+12), xwa
	xor	e, c
	ld	d, e
	lda	xbc, (xhl+6)
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterLinked_Data_Skip8
	ld	c, (xbc)
	and	c, d
	ld	xwa, (xsp+12)
	ld	(xwa), c
	jr	SndParam_RegisterLinked_Data_Join
SndParam_RegisterLinked_Data_Skip8:
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
SndParam_RegisterLinked_Data_Join:
	ld	xbc, (xsp+12)
	cp	e, (xbc)
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
	ldw	(0x9680:16), 0xffff
SndParam_RegisterLinked_Data_Join2:
	ld	xhl, 0x9680
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
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
	lda	xbc, (SndParam_LinkTargetPtrs:24)
	ld	a, (xde+11)
	cp	a, 255
	jr	z, SndParam_RegisterLinked2_Data_Skip6
	sla	a, 2
	ld	xiy, (xbc+a)
	jr	SndParam_RegisterLinked2_Data_Join3
SndParam_RegisterLinked2_Data_Skip6:
	ld	xiy, (xbc)
SndParam_RegisterLinked2_Data_Join3:
	extz	hl
	ld	xix, xiy
	ld	bc, 0:i3
	cpw	(xiy+4), 0
	jr	le, SndParam_RegisterLinked2_Data_Skip8
SndParam_RegisterLinked2_Data_Loop:
	ld	xwa, (xix)
	cp	l, (xwa+bc)
	jr	nz, SndParam_RegisterLinked2_Data_Skip7
	ld	wa, bc
	jr	SndParam_RegisterLinked2_Data_Join4
SndParam_RegisterLinked2_Data_Skip7:
	inc	1, bc
	cp	bc, (xix+4)
	jr	lt, SndParam_RegisterLinked2_Data_Loop
SndParam_RegisterLinked2_Data_Skip8:
	ld	wa, (xix+7)
SndParam_RegisterLinked2_Data_Join4:
	ld	xhl, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, SndParam_RegisterLinked2_Data_Skip9
	ld	xwa, (xhl)
	ld	l, (xwa)
	jr	SndParam_RegisterLinked2_Data_Join2
SndParam_RegisterLinked2_Data_Skip9:
	ld	wa, (xhl+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterLinked2_Data_Skip4
	ld	xwa, (xhl)
	ld	l, (xwa+bc)
	jr	SndParam_RegisterLinked2_Data_Join2
SndParam_RegisterLinked2_Data_Skip4:
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xhl)
	ld	l, (xwa+bc)
SndParam_RegisterLinked2_Data_Join2:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x968c
	ld	bc, 6:i3
	ldirw
	ld	c, (xde+10)
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_RegisterLinked2_Data_Skip10
	slla	l	; sll A,L
SndParam_RegisterLinked2_Data_Skip10:
	xor	c, l
	ld	h, c
	lda	xbc, (xde+6)
	lda	xix, (0x9692:16)
	cpw	(xsp+12), 4
	jr	nz, SndParam_RegisterLinked2_Data_Skip11
	ld	a, (xbc)
	and	a, h
	ld	(xix), a
	jr	SndParam_RegisterLinked2_Data_Join5
SndParam_RegisterLinked2_Data_Skip11:
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
SndParam_RegisterLinked2_Data_Skip11_Part:
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
SndParam_RegisterLinked2_Data_Join5:
	lda	xix, (0x968c:16)
	ldto_berp	a, 238
	cp	a, (xix+6)
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
	ldw	(0x968c:16), 0xffff
SndParam_RegisterLinked2_Data_Join:
	ld	xhl, 0x968c
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jr	z, SndParam_RegisterSimple_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x9698
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
	lda	xwa, (0x9698:16)
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
	cp	wa, (xiz)
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
	ldw	(0x9698:16), 0xffff
SndParam_RegisterSimple_Data_Join2:
	ld	xhl, 0x9698
	pop	xiz
	inc	6, xsp
	ret
SndParam_DeregisterEntry_Data:
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96a4
	ld	bc, 6:i3
	ldirw
	lda	xhl, (0x96a4:16)
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jrl	z, SndParam_RegisterChained_Data_Skip
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96b0
SndParam_RegisterChained_Data_Part:
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
	jr	z, SndParam_RegisterChained_Data_Skip2
	sraa	bc	; sra A,BC
SndParam_RegisterChained_Data_Skip2:
	add	bc, de
	ld	a, (xhl+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterChained_Data_Skip3
	ld	bc, wa
SndParam_RegisterChained_Data_Skip3:
	ld	a, (xhl+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_RegisterChained_Data_Skip4
	ld	bc, wa
SndParam_RegisterChained_Data_Skip4:
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda	xbc, (0x96b6:16)
	cpw	(xsp+18), 4
	jr	nz, SndParam_RegisterChained_Data_Skip6
	andb_erp	e, 234
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterChained_Data_Skip5
	slla	e	; sll A,E
SndParam_RegisterChained_Data_Skip5:
	or	l, e
	ld	(xbc), l
	jr	SndParam_RegisterChained_Data_Join2
SndParam_RegisterChained_Data_Skip6:
	ldto_berp	a, 234
	and	a, e
	ldfr_berp	a, 234
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterChained_Data_Skip7
	slla	e	; sll A,E
SndParam_RegisterChained_Data_Skip7:
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	extz	wa
	lda	xhl, (xiz+wa)
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
SndParam_RegisterChained_Data_Join2:
	lda	xbc, (0x96b0:16)
	ld	wa, (xsp+4)
	cp	a, (xbc+6)
	jr	z, SndParam_RegisterChained_Data_Join
	ld	xwa, (xsp+14)
	ld	a, (xwa)
SndParam_RegisterChained_Data_Join2_Part:
	ld	(xbc+4), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xbc+5), a
	ld	xwa, (xsp+6)
	ld	a, (xwa)
	ld	(xbc+7), a
	jr	SndParam_RegisterChained_Data_Join
SndParam_RegisterChained_Data_Skip:
	ldw	(0x96b0:16), 0xffff
SndParam_RegisterChained_Data_Join:
	ld	xhl, 0x96b0
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xiz, (xbc+wa)
	or	xiz, xiz
	jrl	z, SndParam_RegisterChained2_Data_Skip
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96bc
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
	jr	z, SndParam_RegisterChained2_Data_Skip2
	sraa	bc	; sra A,BC
SndParam_RegisterChained2_Data_Skip2:
	add	bc, hl
	ld	a, (xde+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterChained2_Data_Skip3
	ld	bc, wa
SndParam_RegisterChained2_Data_Skip3:
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
	jr	ge, SndParam_RegisterChained2_Data_Skip4
	ld	bc, wa
SndParam_RegisterChained2_Data_Skip4:
	ld	w, c
	ldto_berp	e, 230
	cpl	e
	lda	xbc, (0x96c2:16)
	cpw	(xsp+16), 4
	jr	nz, SndParam_RegisterChained2_Data_Skip6
	andb_erp	e, 238
	ld	l, e
	ld	(xbc), l
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterChained2_Data_Skip5
	slla	e	; sll A,E
SndParam_RegisterChained2_Data_Skip5:
	or	l, e
	ld	(xbc), l
	jr	SndParam_RegisterChained2_Data_Join2
SndParam_RegisterChained2_Data_Skip6:
	ldto_berp	a, 238
	and	a, e
	ldfr_berp	a, 238
	ld	(xix), a
	ld	e, w
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterChained2_Data_Skip7
	slla	e	; sll A,E
SndParam_RegisterChained2_Data_Skip7:
	ld	xwa, (xsp+8)
	ld	a, (xwa)
	extz	wa
	lda	xhl, (xiz+wa)
	ld	a, (xhl)
	or	a, e
	ld	(xhl), a
	ld	(xbc), a
SndParam_RegisterChained2_Data_Join2:
	lda	xbc, (0x96bc:16)
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
	ldw	(0x96bc:16), 0xffff
SndParam_RegisterChained2_Data_Join:
	ld	xhl, 0x96bc
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterComplex_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96c8
	ld	bc, 6:i3
	ldirw
	ld	xwa, (xsp+12)
	calr	SndParam_CompareRegField
	ld	xwa, (xsp+12)
	ld	a, (xwa+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
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
	ld	a, (xwa+hl)
	ldfr_berp	a, 234
	lda	xix, (0x96c8:16)
	lda	xhl, (xix+6)
	ldto_berp	e, 234
	ld	a, e
	ld	(xhl), a
	ld	a, (xiy+9)
	and	a, 15
	jr	z, SndParam_RegisterComplex_Data_Skip7
	slla	d	; sll A,D
SndParam_RegisterComplex_Data_Skip7:
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
	jr	z, SndParam_RegisterComplex_Data_Join3
	cpw	(xsp+8), 4
	jr	z, SndParam_RegisterComplex_Data_Skip6
	ld	xwa, (xsp+4)
	ld	c, (xwa)
	extz	bc
	ld	xwa, (xsp)
	ld	(xwa+bc), e
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
	ldw	(0x96c8:16), 0xffff
SndParam_RegisterComplex_Data_Join3:
	ld	xhl, 0x96c8
	lda	xsp, (xsp+16)
	ret
SndParam_NotifyQuick_Data:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), de
	ld	(xsp+6), bc
	ld	xiz, xwa
	ld	a, (xiz+4)
SndParam_NotifyQuick_Data_Part:
	extz	wa
	sla	wa, 2
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
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
	ld	(0x96d4:16), xhl
SndParam_NotifyQuick_Data_Skip3:
	ld	xhl, (0x96d4:16)
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterDual_Data_Skip2
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96d8
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
	ld	h, (xde+9)
	ld	a, h
	and	a, 15
	jr	z, SndParam_RegisterDual_Data_Skip6
	srla	c	; srl A,C
SndParam_RegisterDual_Data_Skip6:
	ld	w, c
	lda	xbc, (SndParam_LinkTargetPtrs:24)
	ld	a, (xde+11)
	cp	a, 255
SndParam_RegisterDual_Data_Skip6_Part:
	jr	z, SndParam_RegisterDual_Data_Skip7
	sla	a, 2
	ld	xiy, (xbc+a)
	jr	SndParam_RegisterDual_Data_Join4
SndParam_RegisterDual_Data_Skip7:
	ld	xiy, (xbc)
SndParam_RegisterDual_Data_Join4:
	ld	a, w
	extz	wa
	ld	xix, xiy
	ld	w, a
	ld	de, 0:i3
	cpw	(xiy+4), 0
	jr	le, SndParam_RegisterDual_Data_Skip4
SndParam_RegisterDual_Data_Loop:
	ld	xbc, (xix)
	cp	w, (xbc+de)
	jr	nz, SndParam_RegisterDual_Data_Skip3
	ld	wa, de
	jr	SndParam_RegisterDual_Data_Join3
SndParam_RegisterDual_Data_Skip3:
	inc	1, de
	cp	de, (xix+4)
	jr	lt, SndParam_RegisterDual_Data_Loop
SndParam_RegisterDual_Data_Skip4:
	ld	wa, (xix+7)
SndParam_RegisterDual_Data_Join3:
	add	wa, (xsp+18)
	ld	xde, xiy
	ld	bc, wa
	cp	wa, 0:i3
	jr	ge, SndParam_RegisterDual_Data_Skip5
	ld	xwa, (xde)
	ld	e, (xwa)
	jr	SndParam_RegisterDual_Data_Join
SndParam_RegisterDual_Data_Skip5:
	ld	wa, (xde+4)
	cp	bc, wa
	jr	ge, SndParam_RegisterDual_Data_Skip
	ld	xwa, (xde)
	ld	e, (xwa+bc)
	jr	SndParam_RegisterDual_Data_Join
SndParam_RegisterDual_Data_Skip:
	ld	bc, wa
	dec	1, bc
	ld	xwa, (xde)
	ld	e, (xwa+bc)
SndParam_RegisterDual_Data_Join:
	ldto_berp	b, 238
	ldto_berp	a, 238
	ldfr_berp	a, 230
	cpl	l
	ldto_berp	a, 230
	and	a, l
	ldfr_berp	a, 230
	ld	a, h
	and	a, 15
	jr	z, SndParam_RegisterDual_Data_Skip8
	slla	e	; sll A,E
SndParam_RegisterDual_Data_Skip8:
	ldto_berp	a, 230
	or	a, e
	ldfr_berp	a, 230
	lda	xde, (0x96d8:16)
	ldto_berp	a, 230
	ld	(xde+6), a
	cpw	(xsp+16), 4
	jr	z, SndParam_RegisterDual_Data_Skip9
	ld	xwa, (xsp+8)
	ld	l, (xwa)
	extz	hl
	ld	xwa, (xsp)
	ldto_berp	c, 230
	ld	(xwa+hl), c
SndParam_RegisterDual_Data_Skip9:
	ldto_berp	a, 230
	cp	a, b
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
	ldw	(0x96d8:16), 0xffff
SndParam_RegisterDual_Data_Join2:
	ld	xhl, 0x96d8
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	or	xwa, xwa
	jrl	z, SndParam_RegisterOffset_Data_Skip3
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96e4
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
	lda	xwa, (0x96e4:16)
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
	ldw	(0x96e4:16), 0xffff
SndParam_RegisterOffset_Data_Join2:
	ld	xhl, 0x96e4
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
	lda	xbc, (SndParam_BlockRamPtrs:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	or	xwa, xwa
	jrl	z, SndParam_RegisterWide_Data_Skip4
	ld	xiy, SndParam_ResetDefaultTable_Data
	ld	xix, 0x96f0
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
	jr	z, SndParam_RegisterWide_Data_Skip5
	sraa	bc	; sra A,BC
SndParam_RegisterWide_Data_Skip5:
	add	bc, (xsp+24)
	ld	a, (xde+7)
	extz	wa
	cp	wa, bc
	jr	le, SndParam_RegisterWide_Data_Skip6
	ld	bc, wa
SndParam_RegisterWide_Data_Skip6:
	ld	a, (xde+8)
	extz	wa
	cp	wa, bc
SndParam_RegisterWide_Data_Skip6_Part:
	jr	ge, SndParam_RegisterWide_Data_Skip7
	ld	bc, wa
SndParam_RegisterWide_Data_Skip7:
	ld	xwa, (xsp+18)
	ld	h, (xwa)
	lda	xiz, (0x96f0:16)
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
	jr	SndParam_RegisterWide_Data_Join
SndParam_RegisterWide_Data_Skip2:
	ldw	(xbc), 0xffff
SndParam_RegisterWide_Data_Join:
	ld	xhl, xbc
	jr	SndParam_RegisterWide_Data_Epilogue
SndParam_RegisterWide_Data_Skip3:
	ldto_berp	w, 230
	cpl	w
	and	l, w
	ld	(xix), l
	ld	a, (xiy)
	and	a, 15
	jr	z, SndParam_RegisterWide_Data_Skip8
	slla	c	; sll A,C
SndParam_RegisterWide_Data_Skip8:
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
	jr	z, SndParam_RegisterWide_Data_Join2
	ld	(xiz+4), h
	ld	a, (xiy)
	ld	(xiz+5), a
	ld	xwa, (xsp+10)
	ld	a, (xwa)
	ld	(xiz+7), a
	jr	SndParam_RegisterWide_Data_Join2
SndParam_RegisterWide_Data_Skip4:
	ldw	(0x96f0:16), 0xffff
SndParam_RegisterWide_Data_Join2:
	ld	xhl, 0x96f0
SndParam_RegisterWide_Data_Epilogue:
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SndParam_EncodeFieldDirect_Data:
	ld	de, bc
	ld	xbc, xwa
	ld	l, e
	ld	a, (xbc+7)
	cp	a, l
	jr	ule, SndParam_EncodeFieldDirect_Data_Skip
	ld	l, a
SndParam_EncodeFieldDirect_Data_Skip:
	ld	a, (xbc+8)
	cp	a, l
	jr	nc, SndParam_EncodeFieldDirect_Data_Skip2
	ld	l, a
SndParam_EncodeFieldDirect_Data_Skip2:
	ld	a, (xbc+9)
	and	a, 15
	jr	z, SndParam_EncodeFieldDirect_Data_Skip3
	slla	l	; sll A,L
SndParam_EncodeFieldDirect_Data_Skip3:
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
	ld	xde, (xde+a)
	ld	xwa, 1:i3
	cp	l, (xde)
	jr	c, SndParam_EncodeFieldSub_Data_Skip
	ld	xwa, 2:i3
SndParam_EncodeFieldSub_Data_Skip:
	add	xde, xwa
	ld	l, (xde)
	ld	a, (xbc+9)
	and	a, 15
	jr	z, SndParam_EncodeFieldSub_Data_Skip2
	slla	l	; sll A,L
SndParam_EncodeFieldSub_Data_Skip2:
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
	jr	nc, SndParam_ClampReverbTime_Skip
	ldw	hl, 40
	jr	SndParam_ClampReverbTime_Return
SndParam_ClampReverbTime_Skip:
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
SndParam_DecodeField_Data_Part:
	xor	a, l
	and	a, c
	ld	l, a
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_DecodeField_Data_Skip
	srla	l	; srl A,L
SndParam_DecodeField_Data_Skip:
	ld	a, (xde+7)
	cp	a, l
	jr	ule, SndParam_DecodeField_Data_Skip2
	ld	l, a
SndParam_DecodeField_Data_Skip2:
	ld	a, (xde+8)
	cp	a, l
	jr	nc, SndParam_DecodeField_Data_Skip3
	ld	l, a
SndParam_DecodeField_Data_Skip3:
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
	jr	z, SndParam_DecodeFieldAlt_Data_Skip
	srla	l	; srl A,L
SndParam_DecodeFieldAlt_Data_Skip:
	ld	a, (xde+11)
	sla	a, 2
	lda	xbc, (Naka_SubDispatch_B_Table:24)
	ld	xbc, (xbc+a)
	cp	l, (xbc+1)
	jr	nz, SndParam_DecodeFieldAlt_Data_Skip2
	ld	xwa, 3:i3
	jr	SndParam_DecodeFieldAlt_Data_Join
SndParam_DecodeFieldAlt_Data_Skip2:
	ld	xwa, 5:i3
	cp	l, (xbc+2)
	jr	nz, SndParam_DecodeFieldAlt_Data_Join
	ld	xwa, 4:i3
SndParam_DecodeFieldAlt_Data_Join:
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
	jr	z, SndParam_WriteFieldDirect_Data_Skip
	slaa	hl	; sla A,HL
SndParam_WriteFieldDirect_Data_Skip:
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
	calr	SndParam_DispatchPackedEvent
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
	ld	xbc, (xbc+a)
	ld	xwa, 1:i3
	cp	l, (xbc)
	jr	c, SndParam_WriteFieldSub_Data_Skip
	ld	xwa, 2:i3
SndParam_WriteFieldSub_Data_Skip:
	add	xbc, xwa
	ld	l, (xbc)
	lda	xbc, (xsp)
	ld	a, (xde+4)
	ld	(xbc), a
	ld	a, (xde+5)
	ld	(xbc+1), a
	ld	a, (xde+9)
	and	a, 15
	jr	z, SndParam_WriteFieldSub_Data_Skip2
	slla	l	; sll A,L
SndParam_WriteFieldSub_Data_Skip2:
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
	calr	SndParam_DispatchPackedEvent
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
	calr	SndParam_DispatchPackedEvent
	ld	hl, 0:i3
	inc	4, xsp
	ret
SndParam_WriteViaHash_Data:
	ld	a, (xwa+4)
	extz	wa
	add	wa, wa
	lda	xde, (0x96fc:16)
	ld	(xde+wa), bc
	ld	hl, 0:i3
	ret
SndParam_BatchUpdate_Data:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), bc
	ld	(xsp+22), xwa
	ldib_erp	250, 0
	ldib_erp	249, 0
	ldib_erp	251, 0
	ld	xwa, 8705
	calr	SndParam_LookupReadOnly
	ld	wa, (xsp+20)
	ld	d, a
	lda	xix, (0x96fc:16)
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
SndParam_BatchUpdate_Data_Part:
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
	jr	z, SndParam_BatchUpdate_Data_Join
	res_erpb	251, 7
	inc1b_erp	250
	jr	SndParam_BatchUpdate_Data_Join
SndParam_BatchUpdate_Data_Skip:
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
	jr	z, SndParam_BatchUpdate_Data_Join
	res_erpb	251, 7
	ldib_erp	249, 1
	jr	SndParam_BatchUpdate_Data_Join
SndParam_BatchUpdate_Data_Skip2:
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
	calr	SndParam_DispatchPackedEvent
	lda	xwa, (xsp+16)
	ld	xbc, (xsp+22)
	ld	c, (xbc+4)
	ld	(xwa), c
	ld	(xwa+1), 0
	ldto_berp	c, 251
	ld	(xwa+2), c
	ld	(xwa+3), 255
	calr	SndParam_DispatchPackedEvent
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp+22)
	ret
SndParam_DispatchPackedEvent:
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
SndParam_WidgetNotifyType0:
	cp	(xbc + 4), 0x48
	jr	nz, SndParam_WidgetCheckDirty
	cp	(xbc + 5), 0x8
	jr	nz, SndParam_WidgetCheckDirty
	cp	wa, 4:i3
	jr	z, SndParam_WidgetCallHandler
SndParam_WidgetCheckDirty:
	cp	(xbc + 7), 0x0
	ret	z
SndParam_WidgetCallHandler:
	calr	SndParam_WidgetDispatch
	ret
SndParam_WidgetDispatch:
	push	xiz
	ld	xiz, xbc
	ld	hl, wa
	ld	a, (xiz + 7)
	ldfr_berp	A, 0xf0
	extz	ix
	ld	e, (xiz + 6)
	extz	de
	ld	c, (xiz + 5)
	extz	bc
	ld	a, (xiz + 4)
	extz	wa
	cp	hl, 4:i3
	jr	z, SndParam_WidgetCallType4
	cp	hl, 3:i3
	jr	z, SndParam_WidgetCallType3
	cp	hl, 2:i3
	jr	z, SndParam_WidgetAppendType2
	cp	hl, 1:i3
	jr	nz, SndParam_WidgetDispatchDone
	cpw	(0x9042:16), 508
	call	nc, (SwbtWr_ReinitBothBanks:24)
	lda	xbc, (SWBTWR_EVENT_QUEUE:16)
	ld	de, (0x9042:16)
	extz	xde
	add	xde, xbc
	ld	a, (xiz + 4)
	ld	(xde+), a
	ld	a, (xiz + 5)
	ld	(xde+), a
	ld	a, (xiz + 6)
	ld	(xde+), a
	ld	a, (xiz + 7)
	ld	(xde+), a
	jr	SndParam_WidgetAppendTail
SndParam_WidgetAppendType2:
	cpw	(0x9042:16), 508
	call	nc, (SwbtWr_ReinitOutputBank:24)
	lda	xbc, (SWBTWR_EVENT_QUEUE:16)
	ld	de, (0x9042:16)
	extz	xde
	add	xde, xbc
	ld	a, (xiz + 4)
	ld	(xde+), a
	ld	a, (xiz + 5)
	ld	(xde+), a
	ld	a, (xiz + 6)
	ld	(xde+), a
	ld	a, (xiz + 7)
	ld	(xde+), a
SndParam_WidgetAppendTail:
	ld	(xde), 0xff
	incw	4, (0x9042:16)
	jr	SndParam_WidgetDispatchDone
SndParam_WidgetCallType3:
	pushw	ix
	call	AddswbWr
	jr	SndParam_WidgetDispatchDone
SndParam_WidgetCallType4:
	pushw	ix
	call	SwbtWr
SndParam_WidgetDispatchDone:
	pop	xiz
	ret
Audio_ResetAfterPayloadError_Helper_Helper2:
SndParam_WidgetNotifyType1:
	push	xiz
	ld	xiz, xbc
	ld	e, (xiz + 7)
	cp	e, 0:i3
	jrl	z, SndParam_Widget1_Done
	lda	xiy, (xiz + 6)
	ldfr_berp	E, 0xf0
	extz	ix
	ld	c, (xiz + 5)
	extz	bc
	ld	l, (xiz + 4)
	extz	hl
	cp	wa, 4:i3
	jrl	z, SndParam_Widget1_CallType4
	cp	wa, 3:i3
	jrl	z, SndParam_Widget1_CallType3
	cp	wa, 2:i3
	jr	z, SndParam_Widget1_AppendType2
	cp	wa, 1:i3
	jrl	nz, SndParam_Widget1_Done
	cpw	(0x9042:16), 504
	call	nc, (SwbtWr_ReinitBothBanks:24)
	lda	xbc, (SWBTWR_EVENT_QUEUE:16)
	ld	de, (0x9042:16)
	extz	xde
	add	xde, xbc
	ld	a, (xiz + 4)
	ld	(xde+), a
	ld	a, (xiz + 5)
	ld	(xde+), a
	ld	a, (xiz + 6)
	ld	(xde+), a
	ld	a, (xiz + 7)
	ld	(xde+), a
	ld	a, (xiz + 8)
	ld	(xde+), a
	ld	a, (xiz + 9)
	ld	(xde+), a
	ld	a, (xiz + 10)
	ld	(xde+), a
	ld	a, (xiz + 11)
	ld	(xde+), a
	jr	SndParam_Widget1_AppendTail
SndParam_Widget1_AppendType2:
	cpw	(0x9042:16), 504
	call	nc, (SwbtWr_ReinitOutputBank:24)
	lda	xbc, (SWBTWR_EVENT_QUEUE:16)
	ld	de, (0x9042:16)
	extz	xde
	add	xde, xbc
	ld	a, (xiz + 4)
	ld	(xde+), a
	ld	a, (xiz + 5)
	ld	(xde+), a
	ld	a, (xiz + 6)
	ld	(xde+), a
	ld	a, (xiz + 7)
	ld	(xde+), a
	ld	a, (xiz + 8)
	ld	(xde+), a
	ld	a, (xiz + 9)
	ld	(xde+), a
	ld	a, (xiz + 10)
	ld	(xde+), a
	ld	a, (xiz + 11)
	ld	(xde+), a
SndParam_Widget1_AppendTail:
	ld	(xde), 0xff
	incw	8, (0x9042:16)
	jr	SndParam_Widget1_Done
SndParam_Widget1_CallType3:
	ld	e, (xiy)
	extz	de
	pushw	ix
	ld	wa, hl
	call	AddswbWr
	ld	a, (xiz + 8)
	extz	wa
	ld	c, (xiz + 9)
	extz	bc
	ld	e, (xiz + 10)
	extz	de
	ld	l, (xiz + 11)
	extz	hl
SndParam_Widget1_CallType3_Part:
	pushw	hl
	call	AddswbWr
	jr	SndParam_Widget1_Done
SndParam_Widget1_CallType4:
	and	e, (xiy)
	extz	de
	pushw	ix
	ld	wa, hl
	call	SwbtWr
	ld	a, (xiz + 8)
	extz	wa
	ld	c, (xiz + 9)
	extz	bc
	ld	l, (xiz + 11)
	ld	e, l
	and	e, (xiz + 10)
	extz	de
	extz	hl
	pushw	hl
	call	SwbtWr
SndParam_Widget1_Done:
	pop	xiz
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
SndParam_WidgetNotifyType1_Skip3_Part:
	ret
SndParam_EncodeAddress:
UIState_CheckAndRenderBitmap_Helper_Helper:
	ld	xhl, 0x8000
	and	wa, 0x3f
	sll	wa, 10
	extz	xwa
	add	xhl, xwa
	ld	wa, bc
	and	wa, 0x3ff
	extz	xwa
	or	xhl, xwa
	cp	bc, 0x400
	ret	c
	add	xhl, 0x10000
	ret
SndParam_InitHashTable:
	lda	xbc, (SNDPARAM_HASH_TABLE:24)
	ld	xwa, xbc
	lda	xde, (xbc+16376)
SndParam_InitHashFillLoop:
	ld	xiy, SndParam_InitHashFillLoop_Data
	ld	xix, xwa
	ld	bc, 4:i3
	ldirw
	inc	8, xwa
	cp	xwa, xde
	jr	c, SndParam_InitHashFillLoop
	ret
SndParam_RegisterAllWidgets:
	push	xiz
	ld	xiz, 0:i3
SndParam_RegisterLoop:
	ld	xbc, xiz
	sll	xbc, 2
	ld	xwa, SndParam_Registry
	add	xwa, xbc
	ld	xbc, (xwa)
	ld	xwa, (xbc)
	calr	SndParam_InsertEntry
	inc	1, xiz
	cp	xiz, 0x3cc
	jr	c, SndParam_RegisterLoop
	pop	xiz
	ret
SndParam_InsertEntry:
	dec	6, xsp
	push	xiz
	ld	(xsp + 6), xbc
	ld	xiz, xwa
	ldw	(xsp + 4), 0x0
	ld	xhl, xiz
	and	xhl, 0xff
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 8
	and	xhl, 0xff
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xiz
	srl	xhl, 16
	and	xhl, 0x1f
	add	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 0x7ff
	call	DivMod32
SndParam_InsertProbe:
	ld	wa, hl
	extz	xwa
	sll	xwa, 3
	ld	xbc, SNDPARAM_HASH_TABLE
	add	xbc, xwa
	ld	xde, (xbc)
	cp	xde, SNDPARAM_HASH_EMPTY_KEY
	jr	nz, SndParam_InsertCheckKey
SndParam_InsertProbe_Part:
	ld	(xbc), xiz
	ld	xwa, (xsp + 6)
	ld	(xbc + 4), xwa
	ld	hl, 0:i3
	jr	SndParam_InsertReturn
SndParam_InsertCheckKey:
	ld	wa, 0:i3
	cp	xiz, xde
	jr	z, SndParam_InsertKeyMatch
	ldw	wa, 0xffff
SndParam_InsertIncSlot:
	incw	1, (xsp + 4)
	cpw	(xsp + 4), 0x7ff
	jr	ule, SndParam_InsertNextSlot
	jr	SndParam_InsertFail
SndParam_InsertKeyMatch:
	cp	wa, 0xffff
	jr	z, SndParam_InsertIncSlot
	jr	SndParam_InsertFail
SndParam_InsertNextSlot:
	inc	3, hl
	extz	xhl
	div	hl, 0x7ff
	ldto_werp	WA, 0xee
	ld	hl, wa
	cp	wa, 0x7ff
	jr	c, SndParam_InsertProbe
SndParam_InsertFail:
	ldw	hl, 0xffff
SndParam_InsertReturn:
	pop	xiz
	inc	6, xsp
	ret
SndParam_ClearHashTable:
	lda	xwa, (0x973c:16)
	ld	xbc, xwa
	lda	xde, (xwa+8188)
SndParam_ClearLoop:
	ld	xwa, 0:i3
	ld	(xbc+), XWA
	cp	xbc, xde
	jr	c, SndParam_ClearLoop
	lda	xde, (0x0380f8:24)
	lda	xbc, (xde + 2)
	ld	xwa, xbc
	lda	xbc, (xbc+16384)
SndParam_ClearHeap:
	ld	(xwa+), 0x00
	cp	xwa, xbc
	jr	c, SndParam_ClearHeap
	ldw	(xde), 0x0
	ret
SndParam_ReregisterAll:
	push	xiz
	ld	xiz, 0:i3
SndParam_ReregisterLoop:
	ld	xbc, xiz
	sll	xbc, 2
	ld	xwa, SndParam_Registry
	add	xwa, xbc
	ld	xhl, (xwa)
	ld	a, (xhl + 4)
	ld	c, (xhl + 5)
	ld	e, (xhl + 6)
	push	xhl
	calr	SndParam_AllocAndInsert
	inc	1, xiz
	cp	xiz, 0x3cc
	jr	c, SndParam_ReregisterLoop
	pop	xiz
	ret
SndParam_AllocAndInsert:
	lda	xsp, (xsp - 18)
	push	xiz
	ld	(xsp + 16), e
	ld	(xsp + 18), c
	ld	(xsp + 20), a
	ldw	wa, 0xc
	calr	SndParam_HeapAlloc
	ld	(xsp + 8), xhl
	ld	xwa, (xsp + 8)
	ld	(xsp + 4), xwa
	or	xwa, xwa
	jr	nz, SndParam_AllocBuildKey
	ld	xwa, SndParam_OutOfMemoryMsg
	call	Debug_PrintString
	pushw	0x1
	call	Boot_HaltInstruction
	inc	2, xsp
SndParam_AllocBuildKey:
	ld	xde, 0:i3
	ld	e, (xsp + 18)
	sll	xde, 8
	ld	xwa, 0:i3
	ld	a, (xsp + 20)
	sll	xwa, 16
	ld	xbc, xwa
	or	xbc, xde
	ld	xwa, 0:i3
	ld	a, (xsp + 16)
	ld	(xsp + 12), xwa
	or	(xsp + 12), xbc
	ld	xde, (xsp + 12)
	srl	xde, 8
	ld	xhl, xde
	and	xhl, 0xf
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 4
	and	xhl, 0xf
	add	xhl, xwa
	ld	xwa, xhl
	sll	xwa, 9
	add	xwa, xhl
	ld	xhl, xde
	srl	xhl, 8
	and	xhl, 0xf
	add	xhl, xwa
	ld	xbc, xhl
	sll	xbc, 9
	add	xbc, xhl
	srl	xde, 12
	ld	xhl, xde
	and	xhl, 0xf
	add	xhl, xbc
	ld	xwa, xhl
	ld	xbc, 0x7ff
	call	DivMod32
	ld	bc, hl
	sll	hl, 2
	lda	xde, (0x973c:16)
	ld	iy, hl
	extz	xiy
	add	xiy, xde
	ld	xwa, (xsp + 8)
	lda	xhl, (xwa + 4)
	ld	xwa, (xsp + 4)
	lda	xix, (xwa + 8)
	ld	xiz, (xsp + 26)
	sll	bc, 2
	extz	xbc
	add	xbc, xde
	ld	xwa, (xiy)
	or	xwa, xwa
	jr	nz, SndParam_AllocChainExisting
	ld	xwa, (xsp + 8)
	ld	xde, (xsp + 12)
	ld	(xwa), xde
	ld	(xhl), xiz
	ld	xwa, (xbc)
	ld	(xix), xwa
	ld	xwa, (xsp + 4)
	ld	(xbc), xwa
	jr	SndParam_AllocSuccess
SndParam_AllocChainExisting:
	ld	xde, (xbc)
	ld	xwa, (xde + 8)
	or	xwa, xwa
	jr	z, SndParam_AllocAppendToChain
SndParam_AllocChainLoop:
	ld	xde, (xde + 8)
	ld	xwa, (xde + 8)
	or	xwa, xwa
	jr	nz, SndParam_AllocChainLoop
SndParam_AllocAppendToChain:
	ld	xiy, (xsp + 4)
	ld	xbc, (xsp + 12)
	ld	(xiy), xbc
	ld	(xhl), xiz
	lda	xbc, (xde + 8)
	ld	xwa, (xbc)
	ld	(xix), xwa
	ld	(xbc), xiy
SndParam_AllocSuccess:
	ld	hl, 0:i3
	pop	xiz
	lda	xsp, (xsp + 18)
	retd	0x4
SndParam_HeapAlloc:
	cp	wa, 0:i3
	jr	z, SndParam_HeapAllocFail
	lda	xbc, (0x0380f8:24)
	ld	de, (xbc)
	add	de, wa
	cp	de, 0x4000
	jr	c, SndParam_HeapAllocOK
SndParam_HeapAllocFail:
	ld	xhl, 0:i3
	ret
SndParam_HeapAllocOK:
	ld	de, (xbc)
	extz	xde
	inc	2, xde
	ld	xhl, xbc
	add	xhl, xde
	add	(xbc), wa
	ret
