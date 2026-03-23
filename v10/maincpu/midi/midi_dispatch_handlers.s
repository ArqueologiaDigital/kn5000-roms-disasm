; =============================================================================
; MIDI Dispatch Handlers (11K lines)
; =============================================================================
;
; MIDI Control Change handlers (22 types), serial input parsing,
; file data validation, sound mode handlers, and arpeggiator queue.
; The main MIDI message routing and processing layer.
; =============================================================================



MidiSerial_RetStub:
	ret

MidiSerial_ProcessInput:
	bitda 4, 64848
	jr nz, MidiSerial_Return
	call SeqMain_SaveWritePos
	stdi16 37086, 0

MidiSerial_PumpLoop:
	ld xix, 0x1f37b
	ld wa, (xix - 10)
	cp wa, (xix - 6)
	jr z, MidiSerial_PumpDone
	anddi8 1064, 254
	call MidiSerial_WaitForData
	ldda8 a, 38452
	stda8 38484, a
	and a, 0x70
	srl a, 2
	ld xiz, 0xfcfa05
	ld_sril3 XIZ, 0x03, 0xf8, 0xe0
	call (xiz)
	jr MidiSerial_PumpLoop

MidiSerial_PumpDone:
	call MidiStream_LoadAllPresets
	ld xix, 0xbd3c
	ldda16 xhl, 37086
	stib_dri 0x07, 0xf0, 0xec, 0xff

MidiSerial_Return:
	ret

MidiSerial_StatusTable:
	.byte 0xff, 0xd5, 0xfa, 0xfc, 0x00, 0xd5, 0xfa, 0xfc
	.byte 0x00, 0xd5, 0xfa, 0xfc, 0x00, 0xd5, 0xfa, 0xfc
	.byte 0x00, 0xd5, 0xfa, 0xfc, 0x00, 0xd5, 0xfa, 0xfc
	.byte 0x00, 0xd5, 0xfa, 0xfc, 0x00, 0x4d, 0xfa, 0xfc
	nop

MidiSerial_WaitForData:
	ld xiz, 0x1f37b
	ld xiy, 0x9634
	ld (xiy + 3), 0x0

MidiSerial_WaitLoop:
	call SeqMain_ReadData
	lda_dpi XSP, 0xf4
	ld hl, (xiz - 10)
	cp hl, (xiz - 6)
	jr z, MidiSerial_WaitDone
	ld_srib3 A, 0x07, 0xf8, 0xec
	bit 7, a
	jr z, MidiSerial_WaitLoop

MidiSerial_WaitDone:
	ret

MidiSerial_ParseStatus_Data:
	ldda8	l, 38452
	and	l, 15
	sla	l, 2
	extz	hl
	ld	xiz, 16579175
	.byte 0xe3
	reti
	swi	0
	.byte 0xec
	ldb	h, 182
	.byte 0xe8
	ret
	swi	7


MidiSerial_CmdJumpTable:
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleSysReset_Data
	.long MidiSerial_HandleSysCommon_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
MidiSerial_HandleSysReset_Data:
	ldda16	wa, 38453
	stda8	1069, a
	.byte 0xf1, 0x52
	swi	5
	inc	6, b
	pop_sr
	set	7, w
	stda8	1070, w
	ret
MidiSerial_HandleSysCommon_Data:
	ldda8	a, 38453
	.byte 0xf1, 0x51
	swi	5
	inc	6, c
	pop_sr
	set	7, a
	stda8	1068, a
	ret
MidiSerial_HandleDefault_Data:
	.byte 0xc1
	pushw	wa
	.byte 0x04
	push	xiz
	.byte 0x01
	ret
	ldda8	a, 38452
	and	a, 15
	ld	xhl, 38132
	.byte 0xc3
	pop_sr
	or	xwa, xix
	ldb	a, 201
	.byte 0xcf
	swi	7
	jr	z, 80
	stda8	38504, a
	ld	xhl, 38164
	.byte 0xc3
	pop_sr
	or	xwa, xix
	ldb	a, 201
	inc	6, wa
	push	xiz
	stda8	38505, a
	stda8	38507, a
	incdi8	1, 38504
	xor	h, h
	ldda8	l, 38504
	ld	xix, 38164
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 241
	jr	gt, -106
	ld	xbc, 885118670
	.byte 0x96
	ldb	l, 207
	scc8	f, d
	srl	hl, 2
	ld	xix, 16579389
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	and	xbc, xwa
	jr	ugt, -106
	jr	ge, 110
	.byte 0xca
	ret
	swi	7


MidiCC_LowRange_Table:
	.long MidiCC_Handler_SimpleParamStore
	.long MidiCC_Handler_SimpleParamStore
	.long MidiCC_Handler_SimpleParamStore
	.long MidiCC_Handler_CC3_TableLookup
	.long MidiCC_Handler_CC4_VoiceParam
	.long MidiCC_Handler_CC5_VoiceParam
	.long MidiCC_Handler_CC6_VoiceParam
	.long MidiCC_Handler_SimpleParamStore
MidiCC_Handler_SimpleParamStore:
	.byte 0xc1
	pushw	wa
	.byte 0x04
	push	xiz
	.byte 0x01
	ret
MidiCC_Handler_CC3_TableLookup:
	ld	xix, 16584295
	ldda8	l, 38453
	.byte 0xc3
	pop_sr
	.byte 0xf0, 0xec
	ldb	a, 241
	.byte 0x57, 0x96
	ld	xbc, 1728040905
	push	xwa
	extz	wa
	sll	a, 1
	ld	xix, 16584423
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 14
	ld	xix, 64855
	.byte 0xc3
	pop_sr
	.byte 0xf0, 0xe1
	ldb	c, 201
	.byte 0xc3
	jr	z, 21
	extz	wa
	ldda8	a, 38487
	sla	wa, 2
	ld	xix, 16579507
	.byte 0xe3
	reti
	.byte 0xf0, 0xe0
	ldb	d, 180
	.byte 0xe8
	ret


MidiCC_ExtendedRange_Table:
	.long MidiCC_VoiceParam_0
	.long MidiCC_VoiceParam_3
	.long MidiCC_VoiceParam_4
	.long MidiCC_VoiceParam_5
	.long MidiCC_VoiceParam_6
	.long MidiCC_VoiceParam_7
	.long MidiCC_VoiceParam_8
	.long MidiCC_VoiceParam_9
	.long MidiCC_VoiceParam_1
	.long MidiCC_VoiceParam_2
	.long MidiCC_StubHandler_A
	.long MidiCC_StubHandler_B
	.long MidiCC_VoiceParam_10
	.long MidiCC_VoiceParam_11
	.long MidiCC_VoiceParam_12
	.long MidiCC_VoiceParam_13
	.long MidiCC_Handler_RangeCheck
	.long MidiCC_Handler_ChannelMapping
	.long MidiCC_Handler_BitManipulation
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_PairedParamB
	.long MidiCC_Handler_PairedParamA
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_BankModeSelect
	.long MidiCC_Handler_ExpressionParam
	.long MidiCC_Handler_DirectStoreA
	.long MidiCC_Handler_DirectStoreB
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_ParamDispatch
	.long MidiCC_Handler_TableDispatch
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
MidiCC_NullHandlerBlock:
	ret
MidiCC_Handler_BitManipulation:
	.byte 0xf1, 0x51
	swi	5
	inc	6, b
	push	xiy
	ldda8	a, 38506
	cp	a, 25
	jr	nz, 52
	.byte 0xc1, 0x57, 0x96
	push	xsp
	ccf
	jr	nz, 45
	xor	e, e
	ldda8	a, 38454
	cps	a, 2
	jr	ugt, 10
	ld	xix, 16579769
	.byte 0xc3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	e, 49
	ld	ix, (xwa+11)
	.byte 0xc0
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565575
	ret
	swi	7
	nop
	.byte 0x80, 0x40
MidiCC_Handler_PairedParamA:
	extz	hl
	ldda8	l, 38506
	cp	l, 31
	jr	ugt, 50
	.byte 0xf1, 0x57
	swi	5
	inc	6, d
	pushw	ix
	sll	hl, 1
	ld	xix, 16586407
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 26
	ldda8	e, 38454
	ldb	d, 255
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16567732
	ret
MidiCC_Handler_PairedParamB:
	extz	hl
	ldda8	l, 38506
	cp	l, 31
	jr	ugt, 50
	.byte 0xf1, 0x57
	swi	5
	inc	6, d
	pushw	ix
	sll	hl, 1
	ld	xix, 16586407
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 26
	ldda8	d, 38454
	ldb	e, 255
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16567732
	ret
MidiCC_Handler_RangeCheck:
	ldda8	a, 38506
	cp	a, 16
	jr	nz, 52
	.byte 0xc1, 0x57, 0x96
	push	xsp
	rcf
	jr	nz, 45
	xor	e, e
	ldda8	a, 38454
	cps	a, 3
	jr	ugt, 10
	ld	xix, 16579959
	.byte 0xc3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	e, 49
	popw	wa
	pop_sr
	ldb	d, 7
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	MidiStream_ApplyPendingParams
	ret
	swi	7
	nop
	push_sr
	.byte 0x01
	pop_sr
MidiCC_Handler_ChannelMapping:
	ldda8	a, 38506
	cp	a, 20
	jr	nz, 86
	.byte 0xc1, 0x57, 0x96
	push	xsp
	scf
	jr	nz, 79
	ldb	b, 5
	ldw	de, 64512
	ldda8	a, 38454
	cp	a, 11
	jr	ugt, 22
	extz	wa
	sll	wa, 2
	ld	xix, 16580059
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	a, 216
	jr	le, -45
	reti
	.byte 0xf0, 0xe0
	ldb	b, 41
	pushw	de
	stda8	13449, b
	stda8	13436, e
	stda8	13437, d
	call	AccWrap_ReplaySavedExpr
	popw	de
	popw	bc
	cps	e, 0
	jr	nz, 19
	inc	1, b
	stda8	13449, b
	stda8	13436, e
	stdi8	13437, 4
	call	AccWrap_ReplaySavedExpr
	ret
	popw	wa
	halt
	nop
	swi	4
	popw	wa
	halt
	ld	xwa, 268781632
	rcf
	popw	wa
	halt
	.byte 0x04, 0x04
	popw	wa
	halt
	nop
	swi	4
	popw	wa
	halt
	.byte 0x80, 0x80
	popw	wa
	halt
	ldb	w, 32
	popw	wa
	halt
	ldio	8, 72
	halt
	nop
	swi	4
	popw	wa
	halt
	nop
	swi	4
	popw	wa
	halt
	nop
	swi	4
	popw	wa
	ei	4
	.byte 0x04
MidiCC_VoiceParam_0:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 54
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584519
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 30
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	calr	1313
	ret
MidiCC_VoiceParam_1:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584615
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565861
	ret
MidiCC_VoiceParam_2:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584711
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565861
	ret
MidiCC_VoiceParam_3:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584807
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565812
	ret
MidiCC_VoiceParam_4:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584903
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565705
	ret
MidiCC_VoiceParam_5:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16584999
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, -34
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565749
	ret
MidiCC_VoiceParam_6:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585095
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, -99
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16566084
	ret
MidiCC_VoiceParam_7:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585191
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16566084
	ret
MidiCC_VoiceParam_8:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 54
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585287
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 30
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	calr	794
	ret
MidiCC_VoiceParam_9:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 65
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585383
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 41
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	cp	c, 96
	jr	z, 6
	call	16566084
	jr	3
	calr	719
	ret
MidiCC_StubHandler_A:
	ret
MidiCC_StubHandler_B:
	ret
MidiCC_VoiceParam_10:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585671
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565891
	ret
MidiCC_VoiceParam_11:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
MidiCC_VoiceParam_11_MidEntry:
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585767
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565891
	ret
MidiCC_VoiceParam_12:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585863
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565891
	ret
MidiCC_VoiceParam_13:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 55
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, 16585959
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 31
	inc	2, xix
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	d, 193
	ldw	iz, 9622
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565891
	ret
MidiCC_Handler_BankModeSelect:
	ldda8	l, 38506
	cp	l, 31
	jrl	ugt, 134
	extz	hl
	ld	xix, 16586375
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	c, 203
	.byte 0xcf
	swi	7
	jr	z, 117
	sll	hl, 1
	ld	xix, 38516
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	w, 216
	add	w, l
	incm8	6, (xwa)
	ret
	cp	wa, 32897
	jr	z, 29
	cp	wa, 32898
	jr	z, 42
	jr	84
	.byte 0xf1, 0x57
	swi	5
	inc	6, w
	popw	iz
	ldb	b, 11
	ldda8	e, 38454
	cp	e, 12
	jr	ugt, 67
	ldb	d, 127
	jr	43
	.byte 0xf1, 0x57
	swi	5
	inc	6, a
	push	xbc
	ldb	b, 10
	ldda8	e, 38454
	sll	e, 1
	ldb	d, 255
	jr	24
	.byte 0xf1, 0x57
	swi	5
	inc	6, a
	ldb	h, 34
	push	193
	ldw	iz, 9622
	cp	e, 76
	jr	ugt, 27
	cp	e, 52
	jr	c, 22
	ldb	d, 127
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565835
	ret
MidiCC_Handler_ExpressionParam:
	ldda8	l, 38506
	cp	l, 31
	jr	ugt, 97
	extz	hl
	ld	xix, 16586375
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	c, 203
	.byte 0xcf
	swi	7
	jr	z, 80
	sll	hl, 1
	ld	xix, 38516
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	push	xsp
	.byte 0x81
	decm8	6, (xwa)
	push	xsp
	.byte 0xf1, 0x57
	swi	5
	inc	6, a
	push	xbc
	ldb	b, 10
	ldda32	xix, 37106
	extz	hl
	ldda8	l, 38506
	sll	hl, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 140
	ldwio	33, 12489
	nop
	ldda8	e, 38454
	srl	e, 6
	or	e, a
	ldb	d, 255
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565835
	ret
MidiCC_Handler_DirectStoreA:
	ldda8	a, 38454
	set	7, a
	extz	hl
	ldda8	l, 38506
	sll	hl, 1
	ld	xix, 38517
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	ld	xbc, 130247148
	.byte 0xf0, 0xec
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	nz, 7
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	push_sr
	jrl	nc, 3711
MidiCC_Handler_DirectStoreB:
	ldda8	a, 38454
	set	7, a
	extz	hl
	ldda8	l, 38506
	sll	hl, 1
	ld	xix, 38516
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	ld	xbc, 130245100
	.byte 0xf0, 0xec
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	nz, 9
	dec	1, xix
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	push_sr
	jrl	nc, 3711
MidiCC_Handler_ParamDispatch:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 44
	sll	a, 1
	ld	xix, 16586055
	.byte 0xd3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 26
	ldda8	e, 38454
	ldb	d, 127
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565921
	ret
MidiCC_Handler_TableDispatch:
	; --- Subroutine 1: table-indexed dispatch via XIX+A (54 bytes) ---
	ldda8	a, 38506
	cp a, 0x1f
	jr ugt, MidiCC_Handler_TableDispatch_Ret
	sll	a, 1
	ld xix, 0x00fd1587
	ld_rr8w	bc, xix, w
	cp c, 0xff
	jr z, MidiCC_Handler_TableDispatch_Ret
	ldda8	e, 38454
	ldb d, 0x7f
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call 0xfcc726
MidiCC_Handler_TableDispatch_Ret:
	ret
MidiCC_Helper_ConditionalESetup:
	; --- Subroutine 2: conditional E setup from D (26 bytes) ---
	ldda8	a, 38454
	ldda16	de, 38470
	xor e, e
	cp a, 0x40
	jr c, MidiCC_Helper_ConditionalESetup_Store
	ld e, d
MidiCC_Helper_ConditionalESetup_Store:
	stda16	38470, de
	call 0xfcc5b7
	ret
MidiCC_Helper_EntryWithEqA:
	; --- Subroutine 3: entry variant with E=A (23 bytes) ---
	ld e, a
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call 0xfcc744
	ret


MidiCC_Handler_CC4_VoiceParam:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 50
	.byte 0xf1, 0x57
	swi	5
	inc	6, d
	pushw	ix
	sll	a, 1
	ld	xix, 16586183
	.byte 0xd3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 26
	ldda8	e, 38453
	ldb	d, 255
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16567069
	ret
MidiCC_Handler_CC6_VoiceParam:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 52
	.byte 0xf1, 0x57
	swi	5
	inc	6, h
	pushw	iz
	sll	a, 1
	ld	xix, 16586247
	.byte 0xd3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 28
	ldda8	e, 38453
	ldda8	d, 38454
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565786
	ret
MidiCC_Handler_CC5_VoiceParam:
	ldda8	a, 38506
	cp	a, 31
	jr	ugt, 50
	.byte 0xf1, 0x57
	swi	5
	inc	6, e
	pushw	ix
	sll	a, 1
	ld	xix, 16586311
	.byte 0xd3
	pop_sr
	.byte 0xf0, 0xe0
	ldb	a, 203
	.byte 0xcf
	swi	7
	jr	z, 26
	ldda8	e, 38453
	ldb	d, 127
	ldda8	a, 38455
	stda8	38472, a
	stda16	38468, bc
	stda16	38470, de
	call	16565891
	ret
; ============================================================================
; UIState_ProcessDisplayUpdate - Process a display update event in UI state
; ============================================================================
; Input:  Display update event data
; Output: None
; Handles display refresh events within the UI state machine, updating
; screen elements that need to be redrawn.
; ============================================================================
UIState_ProcessDisplayUpdate:
	.byte 0xc1
	jrl	pl, 16320
	decf
	jr	nz, 13
	ldda8	a, 49279
	and	a, 255
	jr	z, 4
	.byte 0xf1
	jr	nov, -106
	.byte 0xb8
	ret
UIState_DisplayUpdate_BitmapHandler:
	.byte 0xf1
	jr	nov, -106
	inc	6, w
	push_f
	.byte 0xf1
	jr	nov, -106
	ret	lt
	jr	pl, -106
	nop
	.byte 0x80
	calr	13
	stdi8	38509, 64
	calr	5
	call	VoiceChannels_InitPanFromPreset
	ret
	ld	xix, 38132
	.byte 0xc1
	jr	pl, -106
	push	xsp
	incm8	6, (xwa)
	halt
	ld	xix, 38292
	ldw	wa, 65535
	ldw	bc, 16
	.byte 0xf5, 0xf1, 0x50
	djnz16	bc, -6
	ld	xix, 38164
	.byte 0xc1
	jr	pl, -106
	push	xsp
	incm8	6, (xwa)
	halt
	ld	xix, 38324
	xor	wa, wa
	ldw	bc, 64
	.byte 0xf5, 0xf1, 0x50
	djnz16	bc, -6
	ld	xix, 38132
	ld	xiy, 38164
	.byte 0xc1
	jr	pl, -106
	push	xsp
	incm8	6, (xwa)
	ldwio	68, 38292
	nop
	nop
	ld	xiy, 38324
	stda32	38500, xiy
	stdi8	38510, 0
	ldb	w, 0
	lds32	xhl, 1
	stdi8	38511, 0
	stdi8	38512, 0
	ldda32	xiz, 37106
	xor	d, d
	ldda8	e, 38512
	sll	de, 2
	.byte 0xe3
	reti
	swi	0
	.byte 0xe8
	ldb	h, 238
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 33
	ld	a, (xiz+13)
	pushw	wa
	andda8	a, 38509
	popw	wa
	jr	nz, 22
	and	a, 31
	cp	a, w
	jr	nz, 15
	ldda8	d, 38512
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ld	xix, 1874944491
	incm	1, (xiz)
	incdi8	1, 38512
	.byte 0xc1
	jrl	f, 16278
	ldb	w, 110
	.byte 0xba, 0xc1
	jr	nc, -106
	push	xsp
	nop
	jr	z, 16
	ldda8	e, 38511
	ld	(xiy), e
	ld	xde, xiy
	subda32	xde, 38500
	ld	(xix), e
	add	xiy, xhl
	inc	1, xix
	inc	1, w
	incdi8	1, 38510
	.byte 0xc1
	jr	nz, -106
	push	xsp
	ldb	w, 110
	.byte 0x88
	ret
MIDI_DispatchCC:
	bitda 0, 47079
	jr nz, MidiCC_DispatchCleanupRet
	bitda 4, 64848
	jr nz, MidiCC_DispatchCleanupRet
	stda16 38476, xbc
	stda16 38478, xde
	cp c, 0xbf
	jr ugt, MidiCC_DispatchCleanupRet
	ld l, c
	extz hl
	sll hl, 2
	ld xix, 0xfd175e
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	call (xix)

MidiCC_DispatchCleanupRet:
	resda 7, 37093
	ret

MidiCC_DispatchStubRet:
	ret

PanelEvt_CheckFlag7_Dispatch_A:
	bitda 7, 37093
	jr nz, PanelEvt_CheckFlag7_DoDispatch_A
	bitda 6, 63939
	jr nz, PanelEvt_CheckFlag7_Ret_A

PanelEvt_CheckFlag7_DoDispatch_A:
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_A:
	ret

PanelEvt_CheckFlag7_Dispatch_B:
	bitda 7, 37093
	jr nz, PanelEvt_CheckFlag7_DoDispatch_B
	bitda 6, 63965
	jr nz, PanelEvt_CheckFlag7_Ret_B

PanelEvt_CheckFlag7_DoDispatch_B:
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_B:
	ret

PanelEvt_CheckFlag7_Dispatch_C:
	bitda 7, 37093
	jr nz, PanelEvt_CheckFlag7_DoDispatch_C
	bitda 6, 63991
	jr nz, PanelEvt_CheckFlag7_Ret_C

PanelEvt_CheckFlag7_DoDispatch_C:
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_C:
	ret

PanelEvt_UnconditionalDispatch:
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_CheckFlag6_Dispatch:
	bitda 6, 64851
	jr z, PanelEvt_CheckFlag6_Ret
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag6_Ret:
	ret

PanelEvt_CheckChanZero_Dispatch:
	cpdi8 38477, 0
	jr PanelEvt_CheckChanZero_DoDispatch
	bitda 6, 64848
	jr z, PanelEvt_CheckChanZero_Ret

PanelEvt_CheckChanZero_DoDispatch:
	ld xiy, PanelEvt_DispatchTable
	ldb a, 0xf
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckChanZero_Ret:
	ret


PanelEvt_DispatchTable:
	.long PanelEvt_Handler_0_NoteOnParam
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_Handler_3_ValueCheck
	.long PanelEvt_Handler_4_DualValueCheck
	.long PanelEvt_Handler_5_ValueCheck
	.long PanelEvt_Handler_6_NullStub
	.long PanelEvt_Handler_7_ValueCheck
	.long PanelEvt_Handler_8_ValueCheck
	.long PanelEvt_Handler_9_SingleByteParam
	.long PanelEvt_Handler_10_TwoByteParam
	.long PanelEvt_Handler_11_SingleByteParam
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_Handler_15_ConditionalSet
PanelEvt_Handler_0_NoteOnParam:
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 70
	ld	xix, 16587406
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 47
	.byte 0xf1, 0x57
	swi	5
	inc	6, d
	pushw	bc
	ldda8	a, 37093
	.byte 0xf1, 0xe5, 0x90
	dec	6, l
	reti
	ld	a, (xix)
	bit	6, a
	jr	nz, 24
	ldw	de, 512
	stda16	38463, de
	and	a, 15
	or	a, 192
	ldda8	w, 38478
	stda16	38460, wa
	calr	1878
	ret
PanelEvt_Handler_3_ValueCheck:
	ldda8	a, 38479
	and	a, 127
	jr	z, 47
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16587534
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, b
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 2
	calr	1602
	ret
PanelEvt_Handler_5_ValueCheck:
	ldda8	a, 38479
	and	a, 127
	jr	z, 47
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16587662
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, e
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 5
	calr	1545
	ret
PanelEvt_Handler_6_NullStub:
	ret
PanelEvt_Handler_7_ValueCheck:
	ldda8	a, 38479
	and	a, 127
	jr	z, 47
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16587918
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, e
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 7
	calr	1487
	ret
PanelEvt_Handler_8_ValueCheck:
	ldda8	a, 38479
	and	a, 127
	jr	z, 47
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16588047
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, d
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 4
	calr	1430
	ret
PanelEvt_Handler_9_SingleByteParam:
	ldda8	a, 38479
	and	a, 127
	jr	z, 49
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 40
	ld	xix, 16588175
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 17
	.byte 0xf1, 0x57
	swi	5
	inc	6, a
	pushw	43737
	ldda8	d, 38478
	xor	e, e
	calr	1437
	ret
PanelEvt_Handler_10_TwoByteParam:
	ldda8	a, 38479
	and	a, 255
	jr	z, 55
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 46
	ld	xix, 16588303
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 23
	.byte 0xf1, 0x57
	swi	5
	inc	6, a
	scf
	lds	bc, 1
	ldda8	d, 38478
	xor	e, e
	srl	de, 1
	srl	e, 1
	calr	1372
	ret
PanelEvt_Handler_11_SingleByteParam:
	ldda8	a, 38479
	and	a, 127
	jr	z, 49
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 40
	ld	xix, 16588431
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 17
	.byte 0xf1, 0x57
	swi	5
	inc	6, w
	pushw	43225
	ldda8	d, 38478
	xor	e, e
	calr	1313
	ret
PanelEvt_Handler_15_ConditionalSet:
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 44
	ld	xix, 16587406
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 21
	extz	de
	ldda8	e, 38478
	bit	7, e
	jr	z, 6
	set	0, d
	res	7, e
	call	MidiCC_ChannelDispatch_DualSend
	ret

PanelEvt_Dispatch6Entry:
	ld xiy, 0xfd0877
	ldb a, 0x6
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_Dispatch6_TableAndHandlers:
	swi	7
	popw	bc
	ei	253
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	.byte 0x93
	ldio	253, 0
	jrl	ule, -772
	nop
	.byte 0xc7
	ldio	253, 0
	.byte 0xc7
	ldio	253, 0
	ldda8	a, 38479
	and	a, 7
	.ascii "f!Dc"
	swi	3
	nop
	nop
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, e
	ex_ff
	ldda8	e, 38478
	and	e, 7
	ld	xiy, 16582847
	.byte 0xc3
	pop_sr
	.byte 0xf4, 0xe8
	ldb	e, 32
	rcf
	calr	1110
	ret
	swi	7
	nop
	push_sr
	.byte 0x01
	pop_sr
	nop
	nop
	nop
	nop
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, h
	.byte 0x54
	ld	h, e
	cpl	h
	and	h, d
	and	e, d
	ldb	l, 252
	.byte 0xc1
	popw	iy
	.byte 0x96
	push	xsp
	halt
	jr	z, 2
	ldb	l, 4
	and	h, l
	jr	z, 16
	ld	xix, 64459
	ldb	w, 17
	xor	e, e
	pushw	hl
	pushw	de
	calr	1057
	popw	de
	popw	hl
	and	e, l
	jr	z, 41
	ld	xix, 64459
	ldb	w, 17
	ld	xiy, 16582946
	.byte 0xc1
	popw	iy
	.byte 0x96
	push	xsp
	halt
	jr	z, 5
	ld	xiy, 16582955
	xor	a, a
	inc	1, a
	srl	e, 1
	jr	nc, -7
	.byte 0xc3
	pop_sr
	.byte 0xf4, 0xe0
	ldb	e, 30
	sti8_24	3587, 0
	pop_sr
	reti
	push_sr
	ei	1
	halt
	nop
	nop
	nop
	pushw	0
	nop
	nop
	nop

PanelEvt_Dispatch3Entry_A:
	ld xiy, PanelEvt_Dispatch3_TableAndHandlers_A
	ldb a, 0x3
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_Dispatch3_TableAndHandlers_A:
	jrl	ule, -772
	nop
	popw	sp
	push	253
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	.byte 0xf1
	popw	sp
	.byte 0x96
	inc	6, l
	pushw	iz
	ldb	l, 25
	ld	xix, 16587918
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 21
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, e
	retd	37
	.byte 0xf1
	popw	iz
	.byte 0x96
	inc	6, l
	push_sr
	ldb	e, 127
	ldb	w, 7
	calr	912
	ret

PanelEvt_Dispatch3Entry_B:
	ld xiy, PanelEvt_Dispatch3_Table_B
	ldb a, 0x3
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_Dispatch3_Table_B:
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop

PanelEvt_Dispatch11Entry:
	ld xiy, 0xfd09ab
	ldb a, 0xb
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_Dispatch11_TableAndHandlers:
	swi	7
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	jrl	ule, -772
	nop
	muls	hl, 253
	ldda8	a, 38479
	and	a, 192
	jr	z, 36
	ld	xix, 64537
	.byte 0xf1, 0x51
	swi	5
	inc	6, b
	pop_f
	ldda8	e, 38478
	and	e, 192
	srl	e, 6
	ld	xiy, 16583177
	.byte 0xc3
	pop_sr
	.byte 0xf4, 0xe8
	ldb	e, 32
	ccf
	calr	779
	ret
	nop
	push_sr
	.byte 0x01
	nop

PanelEvent_DispatchByIndex:
	ldda8 l, 38477
	cp l, a
	jr ugt, PanelEvt_DispatchByIndex_Ret
	extz hl
	sll hl, 2
	ld_sril3 XHL, 0x07, 0xf4, 0xec
	call (xhl)

PanelEvt_DispatchByIndex_Ret:
	ret

MidiCC_ChannelDispatch_TableA:
	ld xix, 0xfd1a8e
	ldda8 l, 38477
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, MidiCC_ChannelDispatch_TableA_Ret
	ldda16 xde, 38478
	call MidiCC_ChannelDispatch_DualSend

MidiCC_ChannelDispatch_TableA_Ret:
	ret

MidiCC_ChannelDispatch_Ctrl40:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, BitMask_Ctrl40_ConfigExit
	ld xix, 0xfd1f0f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl40_ConfigExit
	bitda 0, 64857
	jr z, BitMask_Ctrl40_ConfigExit
	xor e, e
	ldb w, 0x28
	calr MidiChannel_ConfigureController

BitMask_Ctrl40_ConfigExit:
	ret

MidiCC_ChannelDispatch_Ctrl41:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, MidiCC_ChannelDispatch_Ctrl41_Ret
	ld xix, 0xfd1f8f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, MidiCC_ChannelDispatch_Ctrl41_Ret
	xor e, e
	ldb w, 0x29
	calr MidiChannel_ConfigureController

MidiCC_ChannelDispatch_Ctrl41_Ret:
	ret

MidiCC_ChannelDispatch_SpecialCh1:
	ldda8 l, 38477
	cps l, 1
	jr nz, MidiCC_ChannelDispatch_SpecialCh1_Ret
	ld xix, 0xfc19
	bitda 3, 64856
	jr z, MidiCC_ChannelDispatch_SpecialCh1_Ret
	ldda8 e, 38478
	ldb w, 0x3
	calr MidiChannel_ConfigureController

MidiCC_ChannelDispatch_SpecialCh1_Ret:
	ret

MidiCC_ChannelDispatch_CtrlFlags:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, PanelEvent_NullRet
	ld xix, 0xfd200f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, PanelEvent_NullRet
	bitda 6, 64855
	jr z, PanelEvent_NullRet
	ldda8 a, 37093
	bitda 7, 37093
	jr nz, MidiCC_ChannelDispatch_BuildPacket
	ld a, (xix)
	bit 6, a
	jr nz, PanelEvent_NullRet

MidiCC_ChannelDispatch_BuildPacket:
	ldw de, 0x300
	stda16 38463, xde
	and a, 0xf
	or a, 0xe0
	ldda8 w, 38478
	stda16 38460, xwa
	ldda8 a, 38479
	stda8 38462, a
	calr FileData_ValidateAndDispatch

PanelEvent_NullRet:
	ret

MidiCC_ChannelDispatch_Ctrl1:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, BitMask_Ctrl1_ConfigExit
	ld xix, 0xfd208f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl1_ConfigExit
	bitda 1, 64856
	jr z, BitMask_Ctrl1_ConfigExit
	ldda8 e, 38478
	ldb w, 0x1
	calr MidiChannel_ConfigureController

BitMask_Ctrl1_ConfigExit:
	ret

MidiCC_ChannelDispatch_Ctrl3:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, BitMask_Ctrl3_ConfigExit
	ld xix, 0xfd210f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl3_ConfigExit
	bitda 3, 64856
	jr z, BitMask_Ctrl3_ConfigExit
	ldda8 e, 38478
	ldb w, 0x3
	calr MidiChannel_ConfigureController

BitMask_Ctrl3_ConfigExit:
	ret

MidiCC_ChannelDispatch_CtrlFlags2:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, PanelEvent_NullRet2
	ld xix, 0xfd218f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, PanelEvent_NullRet2
	bitda 5, 64855
	jr z, PanelEvent_NullRet2
	ldda8 a, 37093
	bitda 7, 37093
	jr nz, MidiCC_ChannelDispatch_BuildPacket2
	ld a, (xix)
	bit 6, a
	jr nz, PanelEvent_NullRet2

MidiCC_ChannelDispatch_BuildPacket2:
	ldw de, 0x200
	stda16 38463, xde
	and a, 0xf
	or a, 0xd0
	ldda8 w, 38478
	stda16 38460, xwa
	calr FileData_ValidateAndDispatch

PanelEvent_NullRet2:
	ret

MidiCC_ChannelDispatch_Ctrl0:
	ldda8 l, 38477
	cp l, 0x1f
	jr ugt, BitMask_Ctrl0_ConfigExit
	ld xix, 0xfd220f
	extz hl
	sll l, 2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl0_ConfigExit
	bitda 0, 64856
	jr z, BitMask_Ctrl0_ConfigExit
	ldda8 e, 38478
	ldb w, 0x0
	calr MidiChannel_ConfigureController

BitMask_Ctrl0_ConfigExit:
	ret

MidiCC_ChannelDispatch_MultiHandler:
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16589455
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, a
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 9
	calr	243
	ret
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16589583
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, b
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 8
	calr	195
	ret
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16589711
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, c
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 12
	calr	147
	ret
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16589839
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, c
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 13
	calr	99
	ret
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16589967
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, d
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 14
	calr	51
	ret
	ldda8	l, 38477
	cp	l, 31
	jr	ugt, 38
	ld	xix, 16590095
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 15
	.byte 0xf1
	pop	xbc
	swi	5
	inc	6, d
	push	193
	popw	iz
	ld	iy, (xiz)
	ldb	w, 15
	calr	3
	ret
	ret
	ret

MidiChannel_ConfigureController:
	pushw bc
	ldda8 a, 37093
	bitda 7, 37093
	jr nz, MidiChanCfg_SetupParams
	ld a, (xix)
	bit 6, a
	jr nz, MidiChannel_ConfigureExit

MidiChanCfg_SetupParams:
	ld xiy, 0x963c
	ldw bc, 0x300
	ld (xiy + 3), bc
	and a, 0xf
	or a, 0xb0
	cp w, 0x2f
	jr ugt, MidiChannel_ConfigureExit
	ld xiz, 0xfd1a5e
	ld_srib3 W, 0x03, 0xf8, 0xe1
	cp w, 0xff
	jr z, MidiChannel_ConfigureExit
	ld (xiy + 256), wa
	ld (xiy + 2), e
	calr FileData_ValidateAndDispatch

MidiChannel_ConfigureExit:
	popw bc
	ret

FileData_ProcessWithLookup:
	ldda8	a, 37093
	.byte 0xf1, 0xe5, 0x90
	dec	6, l
	reti
	ld	a, (xix)
	bit	6, a
	jr	nz, 60
	ld	xiy, 38460
	pushw	bc
	ldw	bc, 768
	ld	(xiy+3), bc
	popw	bc
	and	a, 15
	or	a, 176
	ldb	w, 100
	.byte 0xbd
	nop
	.byte 0x50
	ld	(xiy+2), c
	calr	106
	ldb	a, 101
	ld	w, b
	ld	(xiy+1), wa
	calr	96
	ldb	a, 6
	ld	w, d
	ld	(xiy+1), wa
	calr	86
	ldb	a, 38
	ld	w, e
	ld	(xiy+1), wa
	calr	76
	ret

MidiCC_ChannelDispatch_DualSend:
	bitda 4, 64855
	jr z, FileData_DispatchExit
	bitda 7, 64856
	jr z, FileData_DispatchExit
	ldda8 a, 37093
	bitda 7, 37093
	jr nz, MidiCC_DualSend_SetupParams
	ld a, (xix)
	bit 6, a
	jr nz, FileData_DispatchExit

MidiCC_DualSend_SetupParams:
	ld xiy, 0x963c
	ldw bc, 0x300
	ld (xiy + 3), bc
	and a, 0xf
	or a, 0xb0
	ldb w, 0x0
	ld (xiy + 256), wa
	res 7, d
	ld (xiy + 2), d
	calr FileData_ValidateAndDispatch
	ldb w, 0x20
	ld (xiy + 1), w
	res 7, e
	ld (xiy + 2), e
	calr FileData_ValidateAndDispatch

FileData_DispatchExit:
	ret

FileData_ValidateAndDispatch:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xix, 0x963c
	ld c, (xix + 4)
	ld w, (xix + 256)
	ld xiy, SeqOut_WriteTimedBytes
	ld xiz, 0x424
	pushw wa
	ld a, w
	extz wa
	calr FileData_ValidateFormat
	popw wa
	cp hl, 0xffff
	jr z, FileData_DispatchHandler
	inc 1, xix
	dec 1, c

; File data dispatch handler
FileData_DispatchHandler:
	push xix
	ld wa, bc
	extz wa
	pushw wa
	ei 6
	call (xiy)
	ei 0
	inc 6, xsp
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

Periodic_TimestampHelper_Data:
	stda8	1060, a
	extz	wa
	pushw	wa
	ei	0x06
	call	SeqBuf_MidiOut_WriteByte
	ei	0x00
	.byte 0xef
	jr	le, 0x0e

Periodic_TimestampCheck:
	calr Periodic_TimestampCompare
	ret

Periodic_TimestampCompare:
	pushw wa
	pushw de
	ldda16 xwa, 1033
	ld de, wa
	subda16 xwa, 47075
	cp wa, 0x96
	jr c, Periodic_TimestampCompare_Done
	stda16 47075, xde
	stdi8 1060, 0

Periodic_TimestampCompare_Done:
	popw de
	popw wa
	ret

MidiCC_ChannelMappingData:
	push_f
	.byte 0x01
	swi	7
	swi	7
	swi	7
	swi	7
	ldb	w, 2
	swi	7
	swi	7
	.byte 0x04
	pop_sr
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	pop_f
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	ldb	a, 255
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	rcf
	swi	7
	scf
	ccf
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	reti
	swi	7
	halt
	.byte 0x06
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	ldb	c, 34
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	pushw	bc
	pushw	wa
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x01, 0x01
	push_sr
	.byte 0x01, 0x04, 0x01
	ldio	1, 16
	.byte 0x01
	ldb	w, 1
	ldb	w, 1
	ldb	w, 1
	.byte 0x04
	push_sr
	push_sr
	push_sr
	ld	xwa, 134381569
	push_sr
	ldio	2, 16
	push_sr
	rcf
	push_sr
	ldb	w, 2
	ld	xwa, 4294967042
	swi	7
	.fill 8, 1, 0xff
	.byte 0x80, 0x01, 0x80, 0x01
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0x01
	push_sr
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	nop
	.byte 0x04
	ldio	1, 4
	ldio	2, 4
	ldio	3, 4
	ldio	4, 4
	ldio	5, 4
	ldio	6, 4
	ldio	7, 4
	ldio	8, 4
	ldio	9, 4
	ldio	10, 4
	ldio	11, 4
	ldio	12, 4
	ldio	13, 4
	ldio	14, 4
	ldio	255, 255
	swi	7
	rcf
	.byte 0x04
	ldio	17, 4
	ldio	18, 4
	ldio	19, 4
	ldio	255, 255
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x17, 0x04, 0x08
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xsp), 127
	.byte 0xb7, 0x01
	jrl	nc, 695
	jrl	nc, 951
	jrl	nc, 1207
	jrl	nc, 1463
	jrl	nc, 1719
	jrl	nc, 1975
	jrl	nc, 2231
	jrl	nc, 2487
	jrl	nc, 2743
	jrl	nc, 2999
	jrl	nc, 3255
	jrl	nc, 3511
	jrl	nc, 3767
	jrl	nc, -1
	swi	7
	.byte 0xb7
	rcf
	jrl	nc, 4535
	jrl	nc, 4791
	jrl	nc, 5047
	jrl	nc, -1
	swi	7
	.byte 0xb7
	pop_a
	jrl	nc, -1
	swi	7
	.byte 0xb7, 0x17
	jrl	nc, 6327
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xiz), 127
	.byte 0xb6, 0x01
	jrl	nc, 694
	jrl	nc, 950
	jrl	nc, 1206
	jrl	nc, 1462
	jrl	nc, 1718
	jrl	nc, 1974
	jrl	nc, 2230
	jrl	nc, 2486
	jrl	nc, 2742
	jrl	nc, 2998
	jrl	nc, 3254
	jrl	nc, 3510
	jrl	nc, 3766
	jrl	nc, -1
	swi	7
	.byte 0xb6
	rcf
	jrl	nc, 4534
	jrl	nc, 4790
	jrl	nc, 5046
	jrl	nc, -1
	swi	7
	.byte 0xb6
	pop_a
	jrl	nc, -1
	swi	7
	.byte 0xb6, 0x17
	jrl	nc, 6326
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xde), 127
	.byte 0xb2, 0x01
	jrl	nc, 690
	jrl	nc, 946
	jrl	nc, 1202
	jrl	nc, 1458
	jrl	nc, 1714
	jrl	nc, 1970
	jrl	nc, 2226
	jrl	nc, 2482
	jrl	nc, 2738
	jrl	nc, 2994
	jrl	nc, 3250
	jrl	nc, 3506
	jrl	nc, 3762
	jrl	nc, -1
	swi	7
	.byte 0xb2
	rcf
	jrl	nc, 4530
	jrl	nc, 4786
	jrl	nc, 5042
	jrl	nc, -1
	swi	7
	.byte 0xb2
	pop_a
	jrl	nc, -1
	swi	7
	.byte 0xb2, 0x17, 0x7f
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	pop_sr
	jrl	nc, 769
	jrl	nc, 770
	jrl	nc, 771
	jrl	nc, 772
	jrl	nc, 773
	jrl	nc, 774
	jrl	nc, 775
	jrl	nc, 776
	jrl	nc, 777
	jrl	nc, 778
	jrl	nc, 779
	jrl	nc, 780
	jrl	nc, 781
	jrl	nc, 782
	jrl	nc, 783
	jrl	nc, 784
	jrl	nc, 785
	jrl	nc, 786
	jrl	nc, 787
	jrl	nc, 788
	jrl	nc, 789
	jrl	nc, -1
	swi	7
	.byte 0x17
	pop_sr
	.byte 0x7f
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xhl), 127
	.byte 0xb3, 0x01
	jrl	nc, 691
	jrl	nc, 947
	jrl	nc, 1203
	jrl	nc, 1459
	jrl	nc, 1715
	jrl	nc, 1971
	jrl	nc, 2227
	jrl	nc, 2483
	jrl	nc, 2739
	jrl	nc, 2995
	jrl	nc, 3251
	jrl	nc, 3507
	jrl	nc, 3763
	jrl	nc, 4019
	jrl	nc, 4275
	jrl	nc, 4531
	jrl	nc, 4787
	jrl	nc, 5043
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xb3, 0x17
	jrl	nc, -1
	swi	7
	.byte 0xb0, 0x01
	jrl	nc, -1
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	ldio	127, 1
	ldio	127, 2
	ldio	127, 3
	ldio	127, 4
	ldio	127, 5
	ldio	127, 6
	ldio	127, 7
	ldio	127, 8
	ldio	127, 9
	ldio	127, 10
	ldio	127, 11
	ldio	127, 12
	ldio	127, 13
	ldio	127, 14
	ldio	127, 255
	swi	7
	swi	7
	rcf
	ldio	127, 17
	ldio	127, 18
	ldio	127, 19
	ldio	127, 255
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x17, 0x08, 0x7f
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	halt
	jrl	nc, 1281
	jrl	nc, 1282
	jrl	nc, 1283
	jrl	nc, 1284
	jrl	nc, 1285
	jrl	nc, 1286
	jrl	nc, 1287
	jrl	nc, 1288
	jrl	nc, 1289
	jrl	nc, 1290
	jrl	nc, 1291
	jrl	nc, 1292
	jrl	nc, 1293
	jrl	nc, 1294
	jrl	nc, 1295
	.byte 0x7f
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	.byte 0x04
	ld	xwa, 37749761
	.byte 0x04
	ld	xwa, 71304195
	.byte 0x04
	ld	xwa, 104858629
	.byte 0x04
	ld	xwa, 138413063
	.byte 0x04
	ld	xwa, 171967497
	.byte 0x04
	ld	xwa, 205521931
	.byte 0x04
	ld	xwa, 239076365
	.byte 0x04
	ld	xwa, 285212671
	.byte 0x04
	ld	xwa, 306185233
	.byte 0x04
	ld	xwa, 4282385427
	swi	7
	swi	7
	pop_a
	.byte 0x04
	ld	xwa, 402653183
	.byte 0x04, 0x40
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	reti
	jrl	nc, 1793
	jrl	nc, 1794
	jrl	nc, 1795
	jrl	nc, 1796
	jrl	nc, 1797
	jrl	nc, 1798
	jrl	nc, 1799
	jrl	nc, 1800
	jrl	nc, 1801
	jrl	nc, 1802
	jrl	nc, 1803
	jrl	nc, 1804
	jrl	nc, 1805
	jrl	nc, 1806
	jrl	nc, 1807
	jrl	nc, 1808
	jrl	nc, 1809
	jrl	nc, 1810
	jrl	nc, 1811
	jrl	nc, 1812
	jrl	nc, 1813
	jrl	nc, -1
	swi	7
	.byte 0x17
	reti
	jrl	nc, -1
	swi	7
	jr	f, 1
	cp	(xwa), l
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xbc
	nop
	jrl	nc, 444
	jrl	nc, 700
	jrl	nc, 956
	jrl	nc, 1212
	jrl	nc, 1468
	jrl	nc, 1724
	jrl	nc, 1980
	jrl	nc, 2236
	jrl	nc, 2492
	jrl	nc, 2748
	jrl	nc, 3004
	jrl	nc, 3260
	jrl	nc, 3516
	jrl	nc, 3772
	jrl	nc, 4028
	jrl	nc, 4284
	jrl	nc, 4540
	jrl	nc, 4796
	jrl	nc, 5052
	jrl	nc, 5308
	jrl	nc, 5564
	jrl	nc, -1
	swi	7
	.byte 0xbc, 0x17
	jrl	nc, 6332
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xbd
	nop
	jrl	nc, 445
	jrl	nc, 701
	jrl	nc, 957
	jrl	nc, 1213
	jrl	nc, 1469
	jrl	nc, 1725
	jrl	nc, 1981
	jrl	nc, 2237
	jrl	nc, 2493
	jrl	nc, 2749
	jrl	nc, 3005
	jrl	nc, 3261
	jrl	nc, 3517
	jrl	nc, 3773
	jrl	nc, 4029
	jrl	nc, 4285
	jrl	nc, 4541
	jrl	nc, 4797
	jrl	nc, 5053
	jrl	nc, 5309
	jrl	nc, 5565
	jrl	nc, -1
	swi	7
	.byte 0xbd, 0x17
	jrl	nc, 6333
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xb8
	nop
	jrl	nc, 440
	jrl	nc, 696
	jrl	nc, 952
	jrl	nc, 1208
	jrl	nc, 1464
	jrl	nc, 1720
	jrl	nc, 1976
	jrl	nc, 2232
	jrl	nc, 2488
	jrl	nc, 2744
	jrl	nc, 3000
	jrl	nc, 3256
	jrl	nc, 3512
	jrl	nc, 3768
	jrl	nc, 4024
	jrl	nc, 4280
	jrl	nc, 4536
	jrl	nc, 4792
	jrl	nc, 5048
	jrl	nc, 5304
	jrl	nc, 5560
	jrl	nc, -1
	swi	7
	.byte 0xb8, 0x17
	jrl	nc, 6328
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xb9
	nop
	jrl	nc, 441
	jrl	nc, 697
	jrl	nc, 953
	jrl	nc, 1209
	jrl	nc, 1465
	jrl	nc, 1721
	jrl	nc, 1977
	jrl	nc, 2233
	jrl	nc, 2489
	jrl	nc, 2745
	jrl	nc, 3001
	jrl	nc, 3257
	jrl	nc, 3513
	jrl	nc, 3769
	jrl	nc, 4025
	jrl	nc, 4281
	jrl	nc, 4537
	jrl	nc, 4793
	jrl	nc, 5049
	jrl	nc, 5305
	jrl	nc, 5561
	jrl	nc, -1
	swi	7
	.byte 0xb9, 0x17
	jrl	nc, 6329
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xba
	nop
	jrl	nc, 442
	jrl	nc, 698
	jrl	nc, 954
	jrl	nc, 1210
	jrl	nc, 1466
	jrl	nc, 1722
	jrl	nc, 1978
	jrl	nc, 2234
	jrl	nc, 2490
	jrl	nc, 2746
	jrl	nc, 3002
	jrl	nc, 3258
	jrl	nc, 3514
	jrl	nc, 3770
	jrl	nc, 4026
	jrl	nc, 4282
	jrl	nc, 4538
	jrl	nc, 4794
	jrl	nc, 5050
	jrl	nc, 5306
	jrl	nc, 5562
	jrl	nc, -1
	swi	7
	.byte 0xba, 0x17
	jrl	nc, 6330
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xbb
	nop
	jrl	nc, 443
	jrl	nc, 699
	jrl	nc, 955
	jrl	nc, 1211
	jrl	nc, 1467
	jrl	nc, 1723
	jrl	nc, 1979
	jrl	nc, 2235
	jrl	nc, 2491
	jrl	nc, 2747
	jrl	nc, 3003
	jrl	nc, 3259
	jrl	nc, 3515
	jrl	nc, 3771
	jrl	nc, 4027
	jrl	nc, 4283
	jrl	nc, 4539
	jrl	nc, 4795
	jrl	nc, 5051
	jrl	nc, 5307
	jrl	nc, 5563
	jrl	nc, -1
	swi	7
	.byte 0xbb, 0x17
	jrl	nc, 6331
	jrl	nc, -1
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xad
	nop
	sub	(xiy+1), xiy
	push_sr
	sub	(xiy+3), xiy
	.byte 0x04
	sub	(xiy+5), xiy
	.byte 0x06
	sub	(xiy+7), xiy
	ldio	173, 9
	sub	(xiy+10), xiy
	pushw	3245
	sub	(xiy+13), xiy
	ret
	sub	(xiy+15), xiy
	rcf
	sub	(xiy+17), xiy
	ccf
	sub	(xiy+19), xiy
	push_a
	cp	(xiy+21), xsp
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xae
	nop
	sub	(xiz+1), xiz
	push_sr
	sub	(xiz+3), xiz
	.byte 0x04
	sub	(xiz+5), xiz
	.byte 0x06
	sub	(xiz+7), xiz
	ldio	174, 9
	sub	(xiz+10), xiz
	pushw	3246
	sub	(xiz+13), xiz
	ret
	sub	(xiz+15), xiz
	rcf
	sub	(xiz+17), xiz
	ccf
	sub	(xiz+19), xiz
	push_a
	cp	(xiz+21), xsp
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	nop
	.byte 0x01
	nop
	push_sr
	nop
	pop_sr
	nop
	.byte 0x04
	nop
	halt
	nop
	di
	reti
	nop
	ldio	0, 9
	nop
	ldwio	0, 11
	incf
	nop
	decf
	nop
	ret
	nop
	retd	4096
	nop
	scf
	nop
	ccf
	nop
	zcf
	nop
	push_a
	nop
	pop_a
	nop
	swi	7
	swi	7
	.byte 0x17
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xbc), 177
	.byte 0x01, 0xb1
	push_sr
	.byte 0xb1
	pop_sr
	.byte 0xb1, 0x04, 0xb1
	halt
	.byte 0xb1, 0x06, 0xb1
	reti
	.byte 0xb1
	ldio	177, 9
	.byte 0xb1
	ldwio	177, 45323
	incf
	.byte 0xb1
	decf
	.byte 0xb1
	ret
	swi	7
	swi	7
	.byte 0xb1
	rcf
	.byte 0xb1
	scf
	.byte 0xb1
	ccf
	.byte 0xb1
	zcf
	swi	7
	swi	7
	.byte 0xb1
	pop_a
	swi	7
	swi	7
	.byte 0xb1, 0x17
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	ld	(xix), 180
	.byte 0x01, 0xb4
	push_sr
	.byte 0xb4
	pop_sr
	.byte 0xb4, 0x04, 0xb4
	halt
	.byte 0xb4, 0x06, 0xb4
	reti
	.byte 0xb4
	ldio	180, 9
	.byte 0xb4
	ldwio	180, 46091
	incf
	.byte 0xb4
	decf
	.byte 0xb4
	ret
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	nop
	nop
	.byte 0x01
	nop
	push_sr
	nop
	pop_sr
	nop
	.byte 0x04
	nop
	halt
	nop
	di
	reti
	nop
	ldio	0, 9
	nop
	ldwio	0, 11
	incf
	nop
	decf
	nop
	ret
	nop
	retd	4096
	nop
	scf
	nop
	ccf
	nop
	zcf
	nop
	push_a
	nop
	pop_a
	nop
	swi	7
	nop
	.byte 0x17
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
PanelEvt_Handler_4_DualValueCheck:
	.byte 0xf1
	popw	sp
	and	(xiz), hl
	jr	z, 53
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 44
	ld	xix, 16587790
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 21
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, w
	retd	37
	.byte 0xf1
	popw	iz
	and	(xiz), hl
	jr	z, 2
	ldb	e, 127
	ldb	w, 0
	calr	62961
	.byte 0xf1
	popw	sp
	and	(xiz), iz
	jr	z, 53
	ldda8	l, 38476
	cp	l, 31
	jr	ugt, 44
	ld	xix, 16587790
	extz	hl
	sll	l, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 21
	.byte 0xf1
	pop	xwa
	swi	5
	inc	6, e
	retd	37
	.byte 0xf1
	popw	iz
	and	(xiz), iz
	jr	z, 2
	ldb	e, 127
	ldb	w, 6
	calr	62902
	ret
	.byte 0x90
	halt
	swi	5
	nop
	.byte 0xa7
	halt
	swi	5
	nop
	.byte 0xbe
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xd5
	halt
	swi	5
	nop
	.byte 0xe0
	halt
	swi	5
	nop
	.byte 0xe0
	halt
	swi	5
	nop
	.byte 0xe0
	halt
	swi	5
	nop
	.byte 0xe0
	halt
	swi	5
	nop
	stdi8	64773, 224
	halt
	swi	5
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	jr	ugt, 8
	swi	5
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	ldw	ix, 64777
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	.byte 0x84
	push	253
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	ldb	b, 10
	swi	5
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+9), iy
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	ld	xiz, 1946221834
	ldwio	253, 36608
	halt
	swi	5
	nop
	cp	(xix+10), iy
	nop
	.byte 0xb9
	ldwio	253, 4352
	pushw	253
	ld	xbc, 1895890187
	pushw	253
	.byte 0xc1
	pushw	253
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	cp	(xsp+5), e
	nop
	ld	xwa, 168494849
	pop	xiy
	pop	xiz
	pop	xhl
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x50, 0x52, 0x53
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	nop
	ldb	w, 255
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x06
	ldb	h, 101
	jr	ov, -1
	swi	7
	swi	7
	swi	7
	jrl	ge, -136
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	.byte 0xcb
	swi	3
	nop
	nop
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	.byte 0xcb
	swi	3
	nop
	nop
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	.byte 0xcb
	swi	3
	nop
	nop
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	pop_f
	swi	4
	nop
	nop
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	popw	bc
	swi	3
	nop
	nop
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	pop_f
	swi	4
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xc3
	swi	1
	nop
	nop
	.byte 0xdd
	swi	1
	nop
	nop
	ldx
	swi	1
	nop
	nop
	scf
	swi	2
	nop
	nop
	pushw	hl
	swi	2
	nop
	nop
	ld	xiy, 1593835770
	swi	2
	nop
	nop
	jrl	ge, 250
	nop
	cp	(xhl), de
	nop
	nop
	.byte 0xad
	swi	2
	nop
	nop
	.byte 0xc7
	swi	2
	nop
	nop
	.byte 0xe1
	swi	2
	nop
	nop
	swi	3
	swi	2
	nop
	nop
	pop_a
	swi	3
	nop
	nop
	pushw	sp
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	ule, -5
	nop
	nop
	jrl	pl, 251
	nop
	cp	(xsp), hl
	nop
	nop
	.byte 0xb1
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0xe5
	swi	3
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	jr	nc, -3
	nop
	nop
	.byte 0x89
	swi	5
	nop
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff

FileData_ValidateFormat:
	pushw wa
	dec 2, xsp
	ld (xsp), a
	call SeqState_GetFlags
	and hl, 0xf
	jr z, FileData_ValidateFormat_CheckMatch
	ldw hl, 0xffff
	jr FileData_ValidateFormat_Return

FileData_ValidateFormat_CheckMatch:
	ldda8 a, 1060
	cp a, (xsp)
	jr z, FileData_ValidateFormat_Match
	mrib4 0x87, 0x19, 0x24, 0x04
	ldw hl, 0xffff
	jr FileData_ValidateFormat_Return

FileData_ValidateFormat_Match:
	ld l, (xsp)
	extz hl

FileData_ValidateFormat_Return:
	inc 2, xsp
	popw wa
	ret

; --- FileData_LoadAndParse: Allocate buffer, load file, dispatch by format ---
; Allocates 32-byte buffer via malloc (0xff3e80). On failure returns 0xff38.
; Reads data into buffer via (0xf89a74), then dispatches based on format type:
;   type 1: calls local handler (+108 bytes)
;   type 2: calls local handler (+557 bytes), chains to secondary (+7610)
;   type 3: calls local handler (+7252 bytes), chains to secondary (+7610)
; On any sub-handler failure (negative result), returns error.
; Frees buffer via (0xff3af2) before returning status in HL.
FileData_AllocLoadAndParse:
	dec	4, xsp
	pushw	iz
	pushw	32
	call	Malloc
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, (xsp+2)
	or	xwa, xwa
	jr	nz, 5
	ldw	hl, 65336
	jr	87
	ld	xwa, (xsp+2)
	ld	xbc, 32
	call	FileIO_ReadBlock
	ld	iz, hl
	cps	iz, 0
	jr	lt, 57
	ld	xwa, (xsp+2)
	calr	11187
	stda16	47082, hl
	cps	hl, 3
	jr	z, 24
	cps	hl, 2
	jr	z, 4
	cps	hl, 1
	jr	nz, 32
	calr	108
	ld	iz, hl
	cps	iz, 0
	jr	lt, 26
	calr	557
	ld	iz, hl
	jr	19
	calr	7252
	ld	iz, hl
	cps	iz, 0
	jr	lt, 10
	calr	7610
	ld	iz, hl
	jr	3
	ldw	iz, 65434
	ld	xwa, (xsp+2)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	popw	iz
	inc	4, xsp
	ret

FileData_LoadFromSlot:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	sla bc, 11
	lda_24 xwa, 0x0ab000
	st_dri3b W, 0x07, 0xe0, 0xe4
	calr DataBuf_CheckSubFormat
	stda16 47082, xhl
	ld a, (xsp)
	extz wa
	cps hl, 3
	jr z, FileData_LoadFromSlot_Type3
	cps hl, 2
	jr z, FileData_LoadFromSlot_Type1or2
	cps hl, 1
	jr nz, FileData_LoadFromSlot_UnknownFormat

FileData_LoadFromSlot_Type1or2:
	calr DataBuf_AllocAndLoadFormatted
	jr FileData_LoadFromSlot_Return

FileData_LoadFromSlot_Type3:
	calr FileData_LoadAndParseType3
	jr FileData_LoadFromSlot_Return

FileData_LoadFromSlot_UnknownFormat:
	ldw hl, 0xff9a

FileData_LoadFromSlot_Return:
	inc 2, xsp
	ret

FileData_RawDataBlock:
	lda	xsp, (xsp-10)
	push	xiz
	call	PreLswLoad
	calr	11147
	ldada	xwa, 63872
	ld	(xsp+6), xwa
	pushw	1664
	call	Malloc
	inc	2, xsp
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	or	xwa, xwa
	jr	nz, 6
	ldw	hl, 65336
	jrl	410
	ld	xwa, (xsp+10)
	add	xwa, 32
	ld	xbc, 1632
	call	FileIO_ReadBlock
	ld	iz, hl
	cps	iz, 0
	jr	ge, 15
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	371
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 32
	ld	xiz, xbc
	.byte 0xaf
	ldwio	134, 6721
	nop
	nop
	nop
	call	Math_MultiplyAccumulate
	add	xhl, 52
	.byte 0xaf, 0x06
	or	(xhl), h
	add	(xwa-21), a
	calr	1351
	incm	1, (xsp+4)
	.byte 0x9f, 0x04
	push	xsp
	push_f
	nop
	jr	c, -56
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld	xwa, xbc
	add	xwa, 800
	.byte 0xaf
	ldwio	128, 51433
	.byte 0xa4
	push_sr
	nop
	nop
	.byte 0xaf, 0x06, 0x81
	calr	1869
	incm	1, (xsp+4)
	.byte 0x9f, 0x04
	push	xsp
	pop_sr
	nop
	jr	c, -47
	ld	xwa, (xsp+10)
	.byte 0xf3, 0xe1
	ld	xix, 112144387
	ldb	a, 243
	.byte 0xe5, 0xd8
	push_sr
	ldw	bc, 4382
	ldio	175, 10
	.byte 0x20
	lda	xwa, (xwa+852)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+740)
	calr	2409
	ld	xwa, (xsp+10)
	.byte 0xf3, 0xe1
	pop	xix
	pop_sr
	ldw	wa, 1711
	ldb	a, 243
	.byte 0xe5, 0xec
	push_sr
	ldw	bc, 59678
	push	191
	.byte 0x04
	push_sr
	nop
	nop
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 874
	ld	xiz, xbc
	.byte 0xaf
	ldwio	134, 6721
	nop
	nop
	nop
	call	Math_MultiplyAccumulate
	add	xhl, 754
	.byte 0xaf, 0x06
	or	(xhl), h
	add	(xwa-21), a
	calr	2499
	incm	1, (xsp+4)
	.byte 0x9f, 0x04
	push	xsp
	push_sr
	nop
	jr	c, -56
	ld	xwa, (xsp+10)
	.byte 0xf3, 0xe1, 0xaa
	pop_sr
	ldw	wa, 1711
	ldb	a, 243
	.byte 0xe5, 0x80
	pop_sr
	ldw	bc, 8478
	incf
	ld	xwa, (xsp+10)
	.byte 0xf3, 0xe1
	lda	xwa, (xwa+3)
	ld	xbc, (xsp+6)
	.byte 0xf3, 0xe5, 0x8a
	pop_sr
	ldw	bc, 32798
	incf
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+968)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+922)
	calr	3356
	ld	xwa, (xsp+10)
	.byte 0xf3, 0xe1
	ld	wa, 44848
	.byte 0x06
	ldb	a, 243
	.byte 0xe5, 0xaa
	pop_sr
	ldw	bc, 31006
	decf
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+990)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+974)
	calr	3443
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	4078
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	4071
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	5219
	lds	wa, 0
	call	PostLswLoad
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-14)
	push	xiz
	ldda16	wa, 47082
	cps	wa, 1
	jr	z, 119
	cps	wa, 2
	jr	nz, 122
	.byte 0xbf
	incf
	push_sr
	ldwio	0, 36893
	.byte 0xb4
	swi	5
	ld	wa, (xsp+12)
	calr	10765
	.byte 0xbf
	ldio	2, 0
	nop
	ld	wa, (xsp+12)
	srl	wa, 3
	cps	wa, 0
	jr	ule, 20
	ld	wa, (xsp+8)
	calr	10986
	incm	1, (xsp+8)
	ld	wa, (xsp+12)
	srl	wa, 3
	cp	(xsp+8), wa
	jr	c, -20
	pushw	768
	call	Malloc
	inc	2, xsp
	ld	(xsp+14), xhl
	ld	xwa, (xsp+14)
	or	xwa, xwa
	jr	z, 53
	.byte 0xbf
	ldwio	2, 0
	.byte 0x9f
	incf
	push	xsp
	nop
	nop
	jrl	ule, 427
	ld	xwa, (xsp+14)
	ld	xbc, 768
	call	FileIO_ReadBlock
	ld	iz, hl
	cps	iz, 0
	jr	ge, 28
	ld	xwa, (xsp+14)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	412
	.byte 0xbf
	incf
	push_sr
	push_f
	nop
	jr	-117
	ldw	hl, 65336
	jrl	399
	ld	wa, (xsp+10)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	ld	(xsp+4), xwa
	.byte 0xbf
	ldio	2, 0
	nop
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 3
	ld	xiz, xbc
	.byte 0xaf
	ret
	.byte 0x86
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	.byte 0xaf, 0x04
	or	(xhl), h
	add	(xwa-21), a
	calr	808
	incm	1, (xsp+8)
	.byte 0x9f
	ldio	63, 24
	nop
	jr	c, -54
	.byte 0xbf
	ldio	2, 0
	nop
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld	xwa, xbc
	add	xwa, 576
	.byte 0xaf
	ret
	or	(xwa), a
	add	d, w
	push_sr
	nop
	nop
	.byte 0xaf, 0x04, 0x81
	calr	1326
	incm	1, (xsp+8)
	.byte 0x9f
	ldio	63, 3
	nop
	jr	c, -47
	ld	xwa, (xsp+14)
	.byte 0xf3, 0xe1
	jr	ov, 2
	ldw	wa, 1199
	ldb	a, 243
	.byte 0xe5
	lda	xbc, (xwa+2)
	calr	1522
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+624)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+708)
	calr	1866
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+631)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+716)
	calr	1994
	.byte 0xbf
	ldio	2, 0
	nop
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 645
	ld	xiz, xbc
	.byte 0xaf
	ret
	.byte 0x86
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 722
	.byte 0xaf, 0x04
	or	(xhl), h
	add	(xwa-21), a
	calr	1956
	incm	1, (xsp+8)
	.byte 0x9f
	ldio	63, 2
	nop
	jr	c, -56
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+709)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+864)
	calr	2562
	ld	xwa, (xsp+14)
	.byte 0xf3, 0xe1, 0xcc
	push_sr
	ldw	wa, 1199
	ldb	a, 243
	.byte 0xe5
	jr	gt, 3
	ldw	bc, 24862
	ldwio	175, 8206
	lda	xwa, (xwa+732)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+890)
	calr	2813
	ld	xwa, (xsp+14)
	.byte 0xf3, 0xe1, 0xec
	push_sr
	ldw	wa, 1199
	ldb	a, 243
	.byte 0xe5, 0x8a
	pop_sr
	ldw	bc, 23070
	pushw	3759
	ldb	w, 243
	.byte 0xe1, 0xf2
	push_sr
	ldw	wa, 1199
	ldb	a, 243
	.byte 0xe5, 0xae
	pop_sr
	ldw	bc, 21534
	pushw	3759
	ldb	w, 175
	.byte 0x04
	ldb	a, 30
	.byte 0xd0
	decf
	ld	xwa, 63872
	ld	xbc, (xsp+4)
	calr	3907
	incm	1, (xsp+10)
	ld	wa, (xsp+10)
	.byte 0x9f
	incf
	.byte 0xf0
	jrl	c, -427
	lds	wa, 0
	call	PostPmLoad
	ld	xwa, (xsp+14)
	push	xwa
	call	Free
	inc	4, xsp
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+14)
	ret

DataBuf_AllocAndLoadFormatted:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	pushw 0x800
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, DataBuf_AllocAndLoadFormatted_AllocOk
	ldw hl, 0xff38
	jrl DataBuf_AllocAndLoadFormatted_Return

DataBuf_AllocAndLoadFormatted_AllocOk:
	pushw 0x800
	ld c, (xsp + 20)
	extz bc
	sla bc, 11
	lda_24 xwa, 0x0ab000
	st_dri3b W, 0x07, 0xe0, 0xe4
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	st_dri3b W, 0xe1, 0xe0, 0x02
	ld (xsp + 10), xwa
	ld a, (xsp + 18)
	extz wa
	inc 1, wa
	calr DataBuf_InitSlotFromPreset
	ld c, (xsp + 18)
	extz bc
	sla bc, 11
	lda_24 xwa, 0x0ab000
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld (xsp + 14), xwa
	ld xwa, 0x2e0
	add (xsp + 14), xwa
	ldw (xsp + 4), 0x0

DataBuf_TransferVoiceParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 5
	add xbc, 0x20
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x34
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr DataBuf_CopyVoiceBlock24
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x18
	jr c, DataBuf_TransferVoiceParams_Loop
	ldw (xsp + 4), 0x0

DataBuf_TransferEffectParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xwa, xbc
	add xwa, 0x320
	add xwa, (xsp + 10)
	add xbc, 0x2a4
	add xbc, (xsp + 14)
	calr DataBuf_CopyEffectBlock12
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x3
	jr c, DataBuf_TransferEffectParams_Loop
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x44, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xd8, 0x02
	calr DataBuf_CopyFilterBlock12
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x54, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xe4, 0x02
	calr DataBuf_CopyReverbBlock6
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x5c, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xec, 0x02
	calr DataBuf_CopySimpleBlock4
	ldw (xsp + 4), 0x0

DataBuf_TransferAuxParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 5
	add xbc, 0x36a
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x2f2
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr DataBuf_LoadAndDispatchFormat2
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x2
	jr c, DataBuf_TransferAuxParams_Loop
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0xaa, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0x80, 0x03
	calr DataBuf_CopyEQBlock7
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0xb8, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0x8a, 0x03
	calr DataBuf_CopyChorusBlock16
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0xc8, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0x9a, 0x03
	calr DataBuf_CopyCompressorBlock16
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0xd8, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xaa, 0x03
	calr DataBuf_CopyDelayBit2
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0xde, 0x03
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xce, 0x03
	calr DataBuf_CopyMixerBlock12
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	calr DataBuf_CopyBulkBitfields_Nop
	ld xwa, 0xf980
	ld xbc, (xsp + 14)
	calr DataBuf_CopyBulkBitfields_F980
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0

DataBuf_AllocAndLoadFormatted_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

DataBuf_CopyVoiceBlock24:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	and a, 0x7f
	andmi8 (xbc + 4), 0x80
	or (xbc + 4), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	ld a, (xde + 7)
	and a, 0x7f
	andmi8 (xbc + 7), 0x80
	or (xbc + 7), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 9)
	and a, 0x7f
	andmi8 (xbc + 9), 0x80
	or (xbc + 9), a
	ld a, (xde + 10)
	and a, 0x7f
	andmi8 (xbc + 10), 0x80
	or (xbc + 10), a
	ld a, (xde + 11)
	and a, 0x7f
	andmi8 (xbc + 11), 0x80
	or (xbc + 11), a
	ld a, (xde + 12)
	ld (xbc + 12), a
	ld a, (xde + 13)
	and a, 0x7f
	andmi8 (xbc + 13), 0x80
	or (xbc + 13), a
	lda xix, (xbc + 14)
	lda xhl, (xde + 14)
	ld a, (xhl)
	srl a, 6
	and a, 0x3
	sla a, 6
	andmi8 (xix), 0x3f
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 15)
	lda xhl, (xde + 15)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 16)
	lda xhl, (xde + 16)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 17)
	ld (xbc + 17), a
	ld a, (xde + 18)
	ld (xbc + 18), a
	lda xix, (xbc + 19)
	lda xhl, (xde + 19)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 20)
	lda xhl, (xde + 20)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 21)
	lda xhl, (xde + 21)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 22)
	lda xhl, (xde + 22)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 23)
	ld (xbc + 23), a
	ret

DataBuf_CopyEffectBlock12:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	lda xix, (xbc + 3)
	lda xhl, (xde + 3)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xbc, (xbc + 9)
	lda xwa, (xde + 9)
	ldcfm 5, (xwa)
	stcfm 5, (xbc)
	ldcfm 4, (xwa)
	stcfm 4, (xbc)
	ld a, (xwa)
	and a, 0xf
	andmi8 (xbc), 0xf0
	or (xbc), a
	ret

DataBuf_CopyFilterBlock12:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	res 7, a
	ld (xbc + 4), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	stcfm 2, (xix)
	ld a, (xde + 9)
	and a, 0x30
	andmi8 (xbc + 9), 0xcf
	or (xbc + 9), a
	ld a, (xde + 10)
	ld (xbc + 10), a
	ldcfm 0, (xde + 11)
	stcfm 0, (xbc + 11)
	ret

DataBuf_CopyReverbBlock6:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	ldcfm 1, (xde + 3)
	stcfm 1, (xbc + 3)
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	inc 5, xbc
	lda xwa, (xde + 5)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopySimpleBlock4:
	ld e, (xwa + 2)
	ld (xbc + 2), e
	ldcfm 7, (xwa + 3)
	stcfm 7, (xbc + 3)
	ret

DataBuf_LoadAndDispatchFormat2:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xbc
	ldda16 xhl, 47082
	lda xbc, (xwa + 2)
	ld xwa, (xsp + 6)
	lda xde, (xwa + 2)
	ld a, (xwa + 1)
	extz wa
	cps hl, 2
	jrl z, DataBuf_Format2_FormatType2
	cps hl, 1
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	pushw wa
	push xbc
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	inc 2, xwa
	call DSPCfg_ApplyParamStruct
	cps hl, 0
	jrl ge, DataBuf_LoadAndDispatchFormat2_Return
	ld xwa, (xsp + 6)
	ld c, (xwa)
	lda xde, (xwa + 2)
	cp c, 0x63
	jrl z, DataBuf_Format2_Type63
	cp c, 0x61
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	ld xwa, 0x4900
	lds bc, 1
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64628
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DataBuf_Format2_Type61_RestoreSlotId
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DataBuf_Format2_Type61_RestoreSlotId

DataBuf_Format2_Type61_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DataBuf_Format2_Type61_UpdateLoop

DataBuf_Format2_Type61_RestoreSlotId:
	ld a, (xsp + 4)
	jrl DataBuf_StoreSlotId_Return

DataBuf_Format2_Type63:
	ld xwa, 0x4b00
	ldw bc, 0x14
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64654
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DataBuf_Format2_Type63_RestoreSlotId
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DataBuf_Format2_Type63_RestoreSlotId

DataBuf_Format2_Type63_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DataBuf_Format2_Type63_UpdateLoop

DataBuf_Format2_Type63_RestoreSlotId:
	ld a, (xsp + 4)
	jrl DataBuf_StoreSlotId63_Return

DataBuf_Format2_FormatType2:
	pushw wa
	push xbc
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	inc 2, xwa
	call DSPCfg_ApplyParamStructFull
	cps hl, 0
	jrl ge, DataBuf_LoadAndDispatchFormat2_Return
	ld xbc, (xsp + 6)
	ld a, (xbc)
	cp a, 0x63
	jrl z, DataBuf_FormatType2_Type63
	cp a, 0x61
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	lda xde, (xbc + 2)
	ld xwa, 0x4900
	lds bc, 1
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64628
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DataBuf_FormatType2_RestoreSlotId
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DataBuf_FormatType2_RestoreSlotId

DataBuf_FormatType2_Type61_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DataBuf_FormatType2_Type61_UpdateLoop

DataBuf_FormatType2_RestoreSlotId:
	ld a, (xsp + 4)

DataBuf_StoreSlotId_Return:
	stda8 64628, a
	jrl DataBuf_LoadAndDispatchFormat2_Return

DataBuf_FormatType2_Type63:
	ld xwa, (xsp + 6)
	lda xde, (xwa + 2)
	ld xwa, 0x4b00
	ldw bc, 0x14
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64654
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DataBuf_FormatType2_Type63_RestoreSlotId
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DataBuf_FormatType2_Type63_RestoreSlotId

DataBuf_FormatType2_Type63_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DataBuf_FormatType2_Type63_UpdateLoop

DataBuf_FormatType2_Type63_RestoreSlotId:
	ld a, (xsp + 4)

DataBuf_StoreSlotId63_Return:
	stda8 64654, a

DataBuf_LoadAndDispatchFormat2_Return:
	pop xiz
	inc 6, xsp
	ret

DataBuf_CopyEQBlock7:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ld a, (xhl)
	and a, 0x30
	srl a, 4
	and a, 0x3
	sla a, 4
	andmi8 (xix), 0xcf
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ld a, (xhl)
	and a, 0x3
	andmi8 (xix), 0xfc
	or (xix), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	ld (xbc + 4), a
	ld a, (xde + 6)
	and a, 0xf
	andmi8 (xbc + 6), 0xf0
	or (xbc + 6), a
	cpdi16 47082, 2
	ret nz
	ld a, (xde + 5)
	ld (xbc + 5), a
	ret

DataBuf_CopyChorusBlock16:
	ld e, (xwa + 2)
	ld (xbc + 2), e
	ld e, (xwa + 3)
	and e, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), e
	ld e, (xwa + 4)
	res 7, e
	ld (xbc + 4), e
	ld e, (xwa + 5)
	and e, 0x7f
	andmi8 (xbc + 5), 0x80
	or (xbc + 5), e
	ldcfm 6, (xwa + 6)
	stcfm 6, (xbc + 6)
	ld e, (xwa + 7)
	and e, 0x7f
	andmi8 (xbc + 7), 0x80
	or (xbc + 7), e
	ld e, (xwa + 8)
	ld (xbc + 8), e
	ld e, (xwa + 9)
	and e, 0x7f
	andmi8 (xbc + 9), 0x80
	or (xbc + 9), e
	lda xde, (xbc + 10)
	ldcfm 7, (xwa + 11)
	stcfm 7, (xde)
	ld l, (xwa + 11)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 11)
	ldcfm 7, (xwa + 12)
	stcfm 7, (xde)
	ld l, (xwa + 12)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 12)
	ldcfm 7, (xwa + 13)
	stcfm 7, (xde)
	ld l, (xwa + 13)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 13)
	ldcfm 7, (xwa + 14)
	stcfm 7, (xde)
	ld l, (xwa + 14)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xbc, (xbc + 14)
	ldcfm 7, (xwa + 15)
	stcfm 7, (xbc)
	ld a, (xwa + 15)
	and a, 0x7f
	andmi8 (xbc), 0x80
	or (xbc), a
	ret

DataBuf_CopyCompressorBlock16:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xix, (xde + 3)
	lda xhl, (xwa + 3)
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xix), 0x7f
	or (xix), c
	ld c, (xhl)
	and c, 0xf
	andmi8 (xix), 0xf0
	or (xix), c
	ld c, (xwa + 4)
	ld (xde + 4), c
	ld c, (xwa + 5)
	ld (xde + 5), c
	ld c, (xwa + 6)
	ld (xde + 6), c
	ld c, (xwa + 7)
	ld (xde + 7), c
	ld c, (xwa + 8)
	ld (xde + 8), c
	ld c, (xwa + 9)
	ld (xde + 9), c
	ld c, (xwa + 10)
	ld (xde + 10), c
	ld c, (xwa + 11)
	ld (xde + 11), c
	ld c, (xwa + 12)
	ld (xde + 12), c
	ld c, (xwa + 13)
	ld (xde + 13), c
	ld c, (xwa + 14)
	ld (xde + 14), c
	ld a, (xwa + 15)
	ld (xde + 15), a
	ret

DataBuf_CopyDelayBit2:
	inc 2, xbc
	inc 2, xwa
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopyMixerBlock12:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ld a, (xhl)
	and a, 0x3
	andmi8 (xix), 0xfc
	or (xix), a
	ldcfm 3, (xde + 3)
	stcfm 3, (xbc + 3)
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ld a, (xhl)
	and a, 0x18
	srl a, 3
	and a, 0x3
	sla a, 3
	andmi8 (xix), 0xe7
	or (xix), a
	ldcfm 2, (xhl)
	stcfm 2, (xix)
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ld a, (xhl)
	and a, 0x1f
	andmi8 (xix), 0xe0
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 9)
	lda xhl, (xde + 9)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 10)
	lda xhl, (xde + 10)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xbc, (xbc + 11)
	lda xwa, (xde + 11)
	ldcfm 7, (xwa)
	stcfm 7, (xbc)
	ldcfm 6, (xwa)
	stcfm 6, (xbc)
	ldcfm 5, (xwa)
	stcfm 5, (xbc)
	ldcfm 4, (xwa)
	stcfm 4, (xbc)
	ldcfm 3, (xwa)
	stcfm 3, (xbc)
	ldcfm 2, (xwa)
	stcfm 2, (xbc)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopyBulkBitfields_Nop:
	ret

DataBuf_CopyBulkBitfields_Stub:
	; --- Stub (1 byte) ---
	ret
DataBuf_CopyBulkBitfields_944:
	; --- Bit-field + byte copy subroutine 1 (FD38FF-FD3A7B) ---
	ld xde, xwa
	lda xhl, (xbc + 944)
	lda xix, (xde + 1090)
	ldcfm 7, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 7
	andmi8 (xhl), 0x7f
	or (xhl), a
	ldcfm 6, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 6
	andmi8 (xhl), 0xbf
	or (xhl), a
	ldcfm 5, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 5
	andmi8 (xhl), 0xdf
	or (xhl), a
	ldcfm 4, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 4
	andmi8 (xhl), 0xef
	or (xhl), a
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	lda xhl, (xbc + 945)
	lda xix, (xde + 1091)
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	ld	a, (xde+1093)
	ld (xbc + 947), a
	ld	a, (xde+1094)
	ld (xbc + 948), a
	ld	a, (xde+1095)
	ld (xbc + 949), a
	ld	a, (xde+1100)
	ld (xbc + 954), a
	ld	a, (xde+1101)
	ld (xbc + 955), a
	ld	a, (xde+1102)
	ld (xbc + 956), a
	ld	a, (xde+1103)
	ld (xbc + 957), a
	ld	a, (xde+1104)
	ld (xbc + 958), a
	ld	a, (xde+1105)
	ld (xbc + 959), a
	ld	a, (xde+1106)
	ld (xbc + 960), a
	ld	a, (xde+1107)
	ld (xbc + 961), a
	ld	a, (xde+1108)
	ld (xbc + 962), a
	ld	a, (xde+1109)
	ld (xbc + 963), a
	ld	a, (xde+1110)
	ld (xbc + 964), a
	ld	a, (xde+1111)
	ld (xbc + 965), a
	ld	a, (xde+1112)
	ld (xbc + 966), a
	ld	a, (xde+1113)
	ld (xbc + 967), a
	ld	a, (xde+1114)
	ld (xbc + 968), a
	ld	a, (xde+1115)
	ld (xbc + 969), a
	ld	a, (xde+1116)
	ld (xbc + 970), a
	ret
DataBuf_CopyBulkBitfields_960:
	; --- Bit-field + byte copy subroutine 2 (FD3A7C-FD3BF8) ---
	ld xde, xwa
	lda xhl, (xbc + 912)
	lda xix, (xde + 944)
	ldcfm 7, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 7
	andmi8 (xhl), 0x7f
	or (xhl), a
	ldcfm 6, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 6
	andmi8 (xhl), 0xbf
	or (xhl), a
	ldcfm 5, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 5
	andmi8 (xhl), 0xdf
	or (xhl), a
	ldcfm 4, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 4
	andmi8 (xhl), 0xef
	or (xhl), a
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	lda xhl, (xbc + 913)
	lda xix, (xde + 945)
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	ld	a, (xde+947)
	ld (xbc + 915), a
	ld	a, (xde+948)
	ld (xbc + 916), a
	ld	a, (xde+949)
	ld (xbc + 917), a
	ld	a, (xde+954)
	ld (xbc + 922), a
	ld	a, (xde+955)
	ld (xbc + 923), a
	ld	a, (xde+956)
	ld (xbc + 924), a
	ld	a, (xde+957)
	ld (xbc + 925), a
	ld	a, (xde+958)
	ld (xbc + 926), a
	ld	a, (xde+959)
	ld (xbc + 927), a
	ld	a, (xde+960)
	ld (xbc + 928), a
	ld	a, (xde+961)
	ld (xbc + 929), a
	ld	a, (xde+962)
	ld (xbc + 930), a
	ld	a, (xde+963)
	ld (xbc + 931), a
	ld	a, (xde+964)
	ld (xbc + 932), a
	ld	a, (xde+965)
	ld (xbc + 933), a
	ld	a, (xde+966)
	ld (xbc + 934), a
	ld	a, (xde+967)
	ld (xbc + 935), a
	ld	a, (xde+968)
	ld (xbc + 936), a
	ld	a, (xde+969)
	ld (xbc + 937), a
	ld	a, (xde+970)
	ld (xbc + 938), a
	ret


DataBuf_CopyBulkBitfields_F980:
	ld xde, xbc
	st_dri3b D, 0xe9, 0xb0, 0x03
	st_dri3b C, 0xe1, 0xb0, 0x03
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xix), 0x7f
	or (xix), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xix), 0xbf
	or (xix), c
	ldcfm 5, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 5
	andmi8 (xix), 0xdf
	or (xix), c
	ldcfm 4, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 4
	andmi8 (xix), 0xef
	or (xix), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcfm 2, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 1, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 1
	andmi8 (xix), 0xfd
	or (xix), c
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	st_dri3b D, 0xe9, 0xb1, 0x03
	st_dri3b C, 0xe1, 0xb1, 0x03
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcf_dri 2, 0xe1, 0xb1, 0x03
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 1, (xhl)
	stcfm 1, (xix)
	ldcf_dri 0, 0xe1, 0xb1, 0x03
	stcfm 0, (xix)
	ld_srib C, (xwa + 0x03b3)
	lda_dri3 XHL, 0xe9, 0xb3, 0x03
	ld_srib C, (xwa + 0x03b4)
	lda_dri3 XHL, 0xe9, 0xb4, 0x03
	ld_srib C, (xwa + 0x03b5)
	lda_dri3 XHL, 0xe9, 0xb5, 0x03
	ld_srib C, (xwa + 0x03ba)
	lda_dri3 XHL, 0xe9, 0xba, 0x03
	ld_srib C, (xwa + 0x03bb)
	lda_dri3 XHL, 0xe9, 0xbb, 0x03
	ld_srib C, (xwa + 0x03bc)
	lda_dri3 XHL, 0xe9, 0xbc, 0x03
	ld_srib C, (xwa + 0x03bd)
	lda_dri3 XHL, 0xe9, 0xbd, 0x03
	ld_srib C, (xwa + 0x03be)
	lda_dri3 XHL, 0xe9, 0xbe, 0x03
	ld_srib C, (xwa + 0x03bf)
	lda_dri3 XHL, 0xe9, 0xbf, 0x03
	ld_srib C, (xwa + 0x03c0)
	lda_dri3 XHL, 0xe9, 0xc0, 0x03
	ld_srib C, (xwa + 0x03c1)
	lda_dri3 XHL, 0xe9, 0xc1, 0x03
	ld_srib C, (xwa + 0x03c2)
	lda_dri3 XHL, 0xe9, 0xc2, 0x03
	ld_srib C, (xwa + 0x03c3)
	lda_dri3 XHL, 0xe9, 0xc3, 0x03
	ld_srib C, (xwa + 0x03c4)
	lda_dri3 XHL, 0xe9, 0xc4, 0x03
	ld_srib C, (xwa + 0x03c5)
	lda_dri3 XHL, 0xe9, 0xc5, 0x03
	ld_srib C, (xwa + 0x03c6)
	lda_dri3 XHL, 0xe9, 0xc6, 0x03
	ld_srib C, (xwa + 0x03c7)
	lda_dri3 XHL, 0xe9, 0xc7, 0x03
	ld_srib C, (xwa + 0x03c8)
	lda_dri3 XHL, 0xe9, 0xc8, 0x03
	ld_srib C, (xwa + 0x03c9)
	lda_dri3 XHL, 0xe9, 0xc9, 0x03
	ld_srib C, (xwa + 0x03ca)
	lda_dri3 XHL, 0xe9, 0xca, 0x03
	ld_srib A, (xwa + 0x0417)
	and a, 0x7f
	and_srib_im 0xe9, 0x17, 0x04, 0x80
	or_srib_mr A, 0xe9, 0x17, 0x04
	ret

DataBuf_CopyBulkBitfields_Large:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+6), xbc
	ld	(xsp+10), xwa
	ldw	(xsp+4), 0
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 1008
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 992
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	-4231
	incm	1, (xsp+4)
	cpw	(xsp+4), 2
	jr	c, -56
	ld	xiy, (xsp+6)
	lda	xbc, (xiy+1046)
	ld	xix, (xsp+10)
	ld	a, (xix+1074)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xde, (xiy+1047)
	lda	xwa, (xix+1075)
	ldcfm	7, (xwa)
	stcfm	7, (xde)
	ldcfm	6, (xwa)
	stcfm	6, (xbc)
	ld	a, (xwa)
	and	a, 63
	andmi8	(xde), 128
	or	(xde), a
	ldcfm	7, (xix+1076)
	scc8	c, c
	and	c, 1
	sla	c, 7
	andmi8	(xiy+1048), 127
	or	(xiy+1048), c
	ld	xhl, xiy
	lda	xbc, (xhl+1049)
	lda	xwa, (xix+1077)
	ld	e, (xwa)
	and	e, 112
	andmi8	(xbc), 143
	or	(xbc), e
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	ld	c, (xix+1078)
	res	7, c
	res	7, c
	andmi8	(xhl+1050), 128
	or	(xhl+1050), c
	ld	c, (xix+1079)
	srl	c, 4
	and	c, 15
	sla	c, 4
	andmi8	(xhl+1051), 15
	or	(xhl+1051), c
	ldcfm	0, (xix+1080)
	scc8	c, c
	and	c, 1
	andmi8	(xhl+1052), 254
	or	(xhl+1052), c
	lda	xbc, (xhl+1053)
	lda	xwa, (xix+1081)
	ldcfm	7, (xwa)
	stcfm	7, (xbc)
	ldcfm	6, (xwa)
	stcfm	6, (xbc)
	ldcfm	5, (xwa)
	stcfm	5, (xbc)
	ldcfm	4, (xwa)
	stcfm	4, (xbc)
	ldcfm	3, (xwa)
	stcfm	3, (xbc)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	lda	xbc, (xhl+1054)
	lda	xwa, (xix+1082)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	ld	c, (xix+1083)
	ld	(xhl+1056), c
	ld	c, (xix+1122)
	ld	(xhl+1066), c
	ld	c, (xix+1123)
	ld	(xhl+1067), c
	ld	c, (xix+1124)
	ld	(xhl+1068), c
	lda	xbc, (xhl+1069)
	lda	xwa, (xix+1125)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	lda	xbc, (xhl+1078)
	lda	xwa, (xix+1138)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1079)
	lda	xwa, (xix+1139)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	ld	c, (xix+1140)
	res	7, c
	res	7, c
	andmi8	(xhl+1080), 128
	or	(xhl+1080), c
	ld	c, (xix+1141)
	res	7, c
	res	7, c
	andmi8	(xhl+1081), 128
	or	(xhl+1081), c
	ld	c, (xix+1142)
	and	c, 15
	and	c, 15
	andmi8	(xhl+1082), 240
	or	(xhl+1082), c
	ld	c, (xix+1143)
	ld	(xhl+1083), c
	ld	c, (xix+1144)
	res	7, c
	res	7, c
	andmi8	(xhl+1084), 128
	or	(xhl+1084), c
	ld	c, (xix+1145)
	ld	(xhl+1085), c
	ld	c, (xix+1146)
	res	7, c
	res	7, c
	andmi8	(xhl+1086), 128
	or	(xhl+1086), c
	lda	xbc, (xhl+1087)
	lda	xwa, (xix+1147)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1088)
	lda	xwa, (xix+1148)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1089)
	lda	xwa, (xix+1149)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1090)
	lda	xwa, (xix+1150)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1091)
	lda	xwa, (xix+1151)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1092)
	lda	xwa, (xix+1152)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1093)
	lda	xwa, (xix+1153)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1094)
	lda	xwa, (xix+1154)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1095)
	lda	xwa, (xix+1155)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1096)
	lda	xwa, (xix+1156)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1097)
	lda	xwa, (xix+1157)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1098)
	lda	xwa, (xix+1158)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1099)
	lda	xwa, (xix+1159)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1100)
	lda	xwa, (xix+1160)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1101)
	lda	xwa, (xix+1161)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1102)
	lda	xwa, (xix+1162)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1103)
	lda	xwa, (xix+1163)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1104)
	lda	xwa, (xix+1164)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1105)
	lda	xwa, (xix+1165)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1106)
	lda	xwa, (xix+1166)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1107)
	lda	xwa, (xix+1167)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1108)
	lda	xwa, (xix+1168)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	ld	c, (xix+1638)
	ld	(xhl+1576), c
	ld	xwa, xix
	ld	c, (xwa+1639)
	ld	xde, xhl
	ld	(xde+1577), c
	ld	c, (xwa+1640)
	ld	(xde+1578), c
	ld	c, (xwa+1641)
	ld	(xde+1579), c
	ld	c, (xwa+1642)
	ld	(xde+1580), c
	ld	c, (xwa+1643)
	ld	(xde+1581), c
	ld	c, (xwa+1644)
	ld	(xde+1582), c
	ld	c, (xwa+1645)
	ld	(xde+1583), c
	ld	c, (xwa+1646)
	ld	(xde+1584), c
	ld	c, (xwa+1647)
	ld	(xde+1585), c
	ld	c, (xwa+1648)
	ld	(xde+1586), c
	ld	c, (xwa+1649)
	ld	(xde+1587), c
	ld	c, (xwa+1650)
	ld	(xde+1588), c
	ld	c, (xwa+1651)
	ld	(xde+1589), c
	ld	c, (xwa+1652)
	ld	(xde+1590), c
	ld	c, (xwa+1653)
	ld	(xde+1591), c
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	push	xiz
	call	PreLswLoad
	calr	3987
	ldada	xwa, 63872
	ld	(xsp+6), xwa
	pushw 1088
	call	Malloc
	inc	2, xsp
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	or	xwa, xwa
	jr	nz, 6
	ldw	hl, 65336
	jrl	319
	ld	xwa, (xsp+10)
	add	xwa, 32
	ld	xbc, 1056
	call	FileIO_ReadBlock
	ld	iz, hl
	cps	iz, 0
	jr	ge, 15
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	280
	ldw	(xsp+4), 0
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	add	xbc, 32
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 52
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	885
	incm	1, (xsp+4)
	cpw	(xsp+4), 23
	jr	c, -60
	ldw	(xsp+4), 0
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, 15603076
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 414
	ld	xwa, (xsp+10)
	lda_rr	xiz, xwa, de
	ld	xwa, xbc
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 52
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	1411
	incm	1, (xsp+4)
	cpw	(xsp+4), 24
	jr	c, -70
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+308)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+728)
	calr	973
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+326)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+740)
	calr	1195
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+334)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+896)
	calr	1220
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+352)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+938)
	calr	1247
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+358)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+906)
	calr	1241
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	1888
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	2317
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	2479
	lds	wa, 0
	call	PostLswLoad
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-14)
	pushw	iz
	call	PrePmLoad
	ldw	wa, 24
	calr	3713
	lds	iz, 0
	ld	wa, iz
	calr	3948
	inc	1, iz
	cps	iz, 3
	jr	c, -11
	pushw 336
	call	Malloc
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, 6
	ldw	hl, 65336
	jrl	279
	ldw	(xsp+6), 0
	ld	xwa, (xsp+8)
	ld	xbc, 336
	call	FileIO_ReadBlock
	ld	iz, hl
	cps	iz, 0
	jr	ge, 15
	ld	xwa, (xsp+8)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	241
	ld	wa, (xsp+6)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	ld	(xsp+2), xwa
	lds	iz, 0
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	add	xwa, xwa
	add	xwa, xbc
	sll	xwa, 2
	ld	(xsp+12), xwa
	ld	xwa, (xsp+8)
	add	(xsp+12), xwa
	ld	xwa, xbc
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	add	xhl, (xsp+2)
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	calr	488
	inc	1, iz
	cp	iz, 23
	jr	c, -58
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+276)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+696)
	calr	653
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+294)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+708)
	calr	875
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+302)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+864)
	calr	900
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+320)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+906)
	calr	927
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+326)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+874)
	calr	921
	ld	xwa, (xsp+8)
	sub	xwa, 32
	ld	xbc, (xsp+2)
	sub	xbc, 32
	calr	1556
	ld	xwa, 63872
	ld	xbc, (xsp+2)
	calr	3029
	incm	1, (xsp+6)
	cpw	(xsp+6), 24
	jrl	c, -256
	lds	wa, 0
	call	PostPmLoad
	ld	xwa, (xsp+8)
	push	xwa
	call	Free
	inc	4, xsp
	lds	hl, 0
	popw	iz
	lda	xsp, (xsp+14)
	ret

FileData_LoadAndParseType3:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	pushw 0x800
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, FileData_LoadAndParseType3_Continue
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xff38
	jrl DataBuf_TransferSlot_Epilogue

FileData_LoadAndParseType3_Continue:
	pushw 0x800
	ld c, (xsp + 20)
	extz bc
	sla bc, 11
	lda_24 xwa, 0x0ab000
	st_dri3b W, 0x07, 0xe0, 0xe4
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	st_dri3b W, 0xe1, 0x00, 0x01
	ld (xsp + 10), xwa
	ld a, (xsp + 18)
	extz wa
	inc 1, wa
	calr DataBuf_InitSlotFromPreset
	ld c, (xsp + 18)
	extz bc
	sla bc, 11
	lda_24 xwa, 0x0ab000
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld (xsp + 14), xwa
	ld xwa, 0x2e0
	add (xsp + 14), xwa
	ldw (xsp + 4), 0x0

FileData_LoadAndParseType3_Error:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, 0x20
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x34
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr VoiceParam_CopyBitfields_TypeA
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x18
	jr c, FileData_LoadAndParseType3_Error
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x34, 0x01
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xd8, 0x02
	calr VoiceParam_CopyBitfields_TypeB
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x46, 0x01
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xe4, 0x02
	calr VoiceParam_CopyBitfields_TypeC
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x4e, 0x01
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0x80, 0x03
	calr VoiceParam_CopyFields_TypeD
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x60, 0x01
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0xaa, 0x03
	calr VoiceParam_CopyBits_TwoFlags
	ld xwa, (xsp + 10)
	st_dri3b W, 0xe1, 0x66, 0x01
	ld xbc, (xsp + 14)
	st_dri3b A, 0xe5, 0x8a, 0x03
	calr VoiceParam_CopyFields_TypeE
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	calr DSPCfg_ConfigureVoiceSlotA
	ld xwa, 0xf980
	ld xbc, (xsp + 14)
	calr DataBuf_TransferSlotBitfields
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0

DataBuf_TransferSlot_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

VoiceParam_CopyBitfields_TypeA:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xix, (xwa + 6)
	ld c, (xix)
	and c, 0xf
	andmi8 (xde + 3), 0x80
	or (xde + 3), c
	ld c, (xwa + 3)
	and c, 0x7f
	andmi8 (xde + 5), 0x80
	or (xde + 5), c
	lda xiy, (xde + 6)
	lda xhl, (xwa + 4)
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xiy), 0x7f
	or (xiy), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xiy), 0xbf
	or (xiy), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xiy), 0xf7
	or (xiy), c
	ld c, (xhl)
	and c, 0x7
	and c, 0x7
	andmi8 (xiy), 0xf8
	or (xiy), c
	lda xbc, (xde + 7)
	bitm 5, (xhl)
	jr z, VoiceParam_CopyBitfields_TypeA_NoBit5
	ld l, (xbc)
	and l, 0x80
	or l, 0x50
	ld (xbc), l
	jr VoiceParam_CopyBitfields_TypeA_Cont

VoiceParam_CopyBitfields_TypeA_NoBit5:
	andmi8 (xbc), 0x80

VoiceParam_CopyBitfields_TypeA_Cont:
	lda xhl, (xde + 9)
	bitm 7, (xwa + 5)
	jr z, VoiceParam_CopyBitfields_TypeA_NoHigh
	ld c, (xhl)
	and c, 0x80
	or c, 0x5a
	ld (xhl), c
	jr VoiceParam_CopyBitfields_TypeA_Final

VoiceParam_CopyBitfields_TypeA_NoHigh:
	andmi8 (xhl), 0x80

VoiceParam_CopyBitfields_TypeA_Final:
	ldcfm 5, (xwa + 9)
	stcfm 5, (xde + 14)
	lda xiy, (xde + 16)
	lda xhl, (xwa + 8)
	ld c, (xhl)
	res 7, c
	res 7, c
	andmi8 (xiy), 0x80
	or (xiy), c
	ldcfm 7, (xhl)
	stcfm 7, (xiy)
	ld a, (xwa + 11)
	ld (xde + 17), a
	lda xwa, (xde + 15)
	ldcfm 6, (xix)
	stcfm 6, (xwa)
	ldcfm 5, (xix)
	stcfm 5, (xwa)
	ret

VoiceParam_CopyBitfields_TypeB:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xiy, (xwa + 12)
	ld c, (xiy)
	and c, 0xf
	andmi8 (xde + 3), 0x80
	or (xde + 3), c
	lda xix, (xde + 5)
	lda xhl, (xwa + 4)
	ld c, (xhl)
	and c, 0x3
	and c, 0x7
	andmi8 (xix), 0xf8
	or (xix), c
	ldcfm 2, (xhl)
	stcfm 3, (xix)
	lda xix, (xde + 6)
	lda xhl, (xwa + 6)
	ld c, (xhl)
	and c, 0x3
	and c, 0x7
	andmi8 (xix), 0xf8
	or (xix), c
	ldcfm 6, (xhl)
	stcfm 6, (xix)
	lda xix, (xde + 7)
	lda xhl, (xwa + 7)
	ldcfm 0, (xhl)
	scc8 c, c
	and c, 0x1
	andmi8 (xix), 0xfe
	or (xix), c
	ldcfm 1, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 1
	andmi8 (xix), 0xfd
	or (xix), c
	ldcfm 2, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcfm 4, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 4
	andmi8 (xix), 0xef
	or (xix), c
	ldcfm 5, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 5
	andmi8 (xix), 0xdf
	or (xix), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xix), 0xbf
	or (xix), c
	ldcfm 7, (xhl)
	stcfm 7, (xix)
	lda xbc, (xde + 9)
	bitm 4, (xiy)
	jr z, VoiceParam_CopyBitfields_TypeB_NoBit4
	ld l, (xbc)
	and l, 0xcf
	set 5, l
	ld (xbc), l
	jr VoiceParam_CopyBitfields_TypeB_Cont

VoiceParam_CopyBitfields_TypeB_NoBit4:
	andmi8 (xbc), 0xcf

VoiceParam_CopyBitfields_TypeB_Cont:
	ldcfm 0, (xwa + 15)
	scc8 c, h
	lda xbc, (xwa + 14)
	ld l, (xbc)
	ld a, l
	add a, l
	add a, h
	ld (xde + 10), a
	ld a, (xbc)
	srl a, 7
	and a, 0x1
	and a, 0x1
	andmi8 (xde + 11), 0xfe
	or (xde + 11), a
	ret

VoiceParam_CopyBitfields_TypeC:
	ld xde, xbc
	lda xix, (xde + 2)
	lda xhl, (xwa + 2)
	ldcfm 0, (xhl)
	scc8 c, c
	and c, 0x1
	andmi8 (xix), 0xfe
	or (xix), c
	ldcfm 1, (xhl)
	stcfm 1, (xix)
	ldcfm 1, (xwa + 3)
	stcfm 1, (xde + 3)
	lda xbc, (xde + 5)
	inc 7, xwa
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ret

VoiceParam_CopyFields_TypeD:
	ld e, (xwa + 2)
	and e, 0x3
	andmi8 (xbc + 2), 0xfc
	or (xbc + 2), e
	ld e, (xwa + 3)
	ld (xbc + 4), e
	ld e, (xwa + 5)
	and e, 0xf
	andmi8 (xbc + 6), 0xf0
	or (xbc + 6), e
	ld a, (xwa + 17)
	res 7, a
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ret

VoiceParam_CopyBits_TwoFlags:
	inc 2, xbc
	inc 2, xwa
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

VoiceParam_CopyFields_TypeE:
	ld e, (xwa + 2)
	and e, 0x7f
	andmi8 (xbc + 10), 0x80
	or (xbc + 10), e
	ld e, (xwa + 3)
	and e, 0x7f
	andmi8 (xbc + 11), 0x80
	or (xbc + 11), e
	ld e, (xwa + 4)
	and e, 0x7f
	andmi8 (xbc + 12), 0x80
	or (xbc + 12), e
	ld e, (xwa + 5)
	ld (xbc + 2), e
	ld e, (xwa + 6)
	and e, 0x7f
	andmi8 (xbc + 5), 0x80
	or (xbc + 5), e
	ldcfm 6, (xwa + 7)
	stcfm 6, (xbc + 6)
	ret

VoiceParam_CopyBitfields_LargeBlock:
	lda	xde, (xbc+15)
	ld	l, (xwa)
	and	l, 15
	.byte 0x82
	push	xix
	.byte 0xf0
	or	(xde), l
	.byte 0xb0, 0x9d, 0xb2, 0xa5, 0xb0, 0x9e, 0xb2, 0xa6
	.byte 0xb0, 0x9e, 0xb2
	add	(xsp), xwa
	.byte 0x01
	ldb	a, 201
	neg	d
	.byte 0x89
	ret
	push	xix
	swi	0
	or	(xbc+14), a
	ret
	ld	xde, xwa
	lda	xix, (xbc+2)
	lda	xhl, (xde+2)
	ld	a, (xhl)
	and	a, 3
	and	a, 3
	.byte 0x84
	push	xix
	swi	4
	or	(xix), a
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	.byte 0xb3, 0x9b
	scc8	c, a
	and	a, 1
	sla	a, 3
	.byte 0x84
	push	xix
	ldx
	or	(xix), a
	.byte 0xb3, 0x9c
	scc8	c, a
	and	a, 1
	sla	a, 4
	.byte 0x84
	push	xix
	add	xix, xsp
	sbc	xhl, xbc
	.byte 0x9d
	scc8	c, a
	and	a, 1
	sla	a, 5
	.byte 0x84
	push	xix
	.byte 0xdf
	or	(xix), a
	.byte 0xb3, 0x9e, 0xb4, 0xa6, 0xba
	pop_sr
	.byte 0x9b, 0xb9
	pop_sr
	.byte 0xa3
	lda	xix, (xbc+4)
	lda	xhl, (xde+4)
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	ld	a, (xhl)
	and	a, 24
	.byte 0x84
	push	xix
	.byte 0xe7
	or	(xix), a
	lda	xix, (xbc+5)
	lda	xhl, (xde+5)
	.byte 0xb3, 0x98
	scc8	c, a
	and	a, 1
	.byte 0x84
	push	xix
	swi	6
	or	(xix), a
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	.byte 0xb3, 0x9e
	scc8	c, a
	and	a, 1
	sla	a, 6
	.byte 0x84
	push	xix
	.byte 0xbf
	or	(xix), a
	.byte 0xb3, 0x9f, 0xb4, 0xa7
	lda	xix, (xbc+7)
	lda	xhl, (xde+7)
	ld	a, (xhl)
	and	a, 15
	and	a, 15
	.byte 0x84
	push	xix
	.byte 0xf0
	or	(xix), a
	.byte 0xb3, 0x9c
	scc8	c, a
	and	a, 1
	sla	a, 4
	.byte 0x84
	push	xix
	add	xix, xsp
	sbc	xhl, xbc
	.byte 0x9d, 0xb4, 0xa5
	lda	xix, (xbc+8)
	lda	xhl, (xde+8)
	.byte 0xb3, 0x98
	scc8	c, a
	and	a, 1
	.byte 0x84
	push	xix
	swi	6
	or	(xix), a
	.byte 0xb3, 0x99
	scc8	c, a
	and	a, 1
	sla	a, 1
	.byte 0x84
	push	xix
	swi	5
	or	(xix), a
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	.byte 0xb3, 0x9b
	scc8	c, a
	and	a, 1
	sla	a, 3
	.byte 0x84
	push	xix
	ldx
	or	(xix), a
	.byte 0xb3, 0x9c
	scc8	c, a
	and	a, 1
	sla	a, 4
	.byte 0x84
	push	xix
	add	xix, xsp
	sbc	xhl, xbc
	.byte 0x9d
	scc8	c, a
	and	a, 1
	sla	a, 5
	.byte 0x84
	push	xix
	.byte 0xdf
	or	(xix), a
	.byte 0xb3, 0x9e
	scc8	c, a
	and	a, 1
	sla	a, 6
	.byte 0x84
	push	xix
	.byte 0xbf
	or	(xix), a
	.byte 0xb3, 0x9f, 0xb4, 0xa7
	lda	xix, (xbc+9)
	lda	xhl, (xde+9)
	.byte 0xb3, 0x98
	scc8	c, a
	and	a, 1
	.byte 0x84
	push	xix
	swi	6
	or	(xix), a
	.byte 0xb3, 0x99
	scc8	c, a
	and	a, 1
	sla	a, 1
	.byte 0x84
	push	xix
	swi	5
	or	(xix), a
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	.byte 0xb3, 0x9b
	scc8	c, a
	and	a, 1
	sla	a, 3
	.byte 0x84
	push	xix
	ldx
	or	(xix), a
	.byte 0xb3, 0x9c
	scc8	c, a
	and	a, 1
	sla	a, 4
	.byte 0x84
	push	xix
	add	xix, xsp
	sbc	xhl, xbc
	.byte 0x9d
	scc8	c, a
	and	a, 1
	sla	a, 5
	.byte 0x84
	push	xix
	.byte 0xdf
	or	(xix), a
	.byte 0xb3, 0x9e
	scc8	c, a
	and	a, 1
	sla	a, 6
	.byte 0x84
	push	xix
	.byte 0xbf
	or	(xix), a
	.byte 0xb3, 0x9f, 0xb4, 0xa7
	lda	xix, (xbc+10)
	lda	xhl, (xde+10)
	.byte 0xb3, 0x98
	scc8	c, a
	and	a, 1
	.byte 0x84
	push	xix
	swi	6
	or	(xix), a
	.byte 0xb3, 0x99
	scc8	c, a
	and	a, 1
	sla	a, 1
	.byte 0x84
	push	xix
	swi	5
	or	(xix), a
	.byte 0xb3, 0x9a
	scc8	c, a
	and	a, 1
	sla	a, 2
	.byte 0x84
	push	xix
	swi	3
	or	(xix), a
	.byte 0xb3, 0x9b
	scc8	c, a
	and	a, 1
	sla	a, 3
	.byte 0x84
	push	xix
	ldx
	or	(xix), a
	.byte 0xb3, 0x9c
	scc8	c, a
	and	a, 1
	sla	a, 4
	.byte 0x84
	push	xix
	add	xix, xsp
	sbc	xhl, xbc
	.byte 0x9d
	scc8	c, a
	and	a, 1
	sla	a, 5
	.byte 0x84
	push	xix
	.byte 0xdf
	or	(xix), a
	.byte 0xb3, 0x9f, 0xb4, 0xa7
	lda	xbc, (xbc+11)
	lda	xwa, (xde+11)
	.byte 0xb0, 0x98, 0xb1, 0xa0, 0xb0, 0x9d, 0xb1, 0xa5
	.byte 0xb0, 0x9e, 0xb1, 0xa6
	ret

DSPCfg_ConfigureVoiceSlotA:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ldcf_dri 7, 0xe1, 0x53, 0x01
	scc8 c, c
	ld xde, (xsp + 6)
	and c, 0x1
	sla c, 7
	and_srib_im 0xe9, 0xef, 0x02, 0x7f
	or_srib_mr C, 0xe9, 0xef, 0x02
	ld_srib A, (xwa + 0x0155)
	and a, 0xf
	extz wa
	lda_24 xbc, 0xee159c
	ld_srib3 C, 0x07, 0xe4, 0xe0
	extz bc
	st_dri3b B, 0xe9, 0xf4, 0x02
	ld xwa, 0x4900
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jr lt, DSPCfg_ConfigureVoiceSlotB
	ld xbc, (xsp + 6)
	ld_srib A, (xbc + 0x02f3)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	st_dri3b W, 0xe5, 0xf5, 0x02
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64628
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld_srib A, (xwa + 0x02f4)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DSPCfg_VoiceSlotA_RestoreContext
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DSPCfg_VoiceSlotA_RestoreContext

DSPCfg_VoiceSlotA_ParamLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	st_dri3b B, 0xe9, 0xf4, 0x02
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DSPCfg_VoiceSlotA_ParamLoop

DSPCfg_VoiceSlotA_RestoreContext:
	ld a, (xsp + 4)
	stda8 64628, a

DSPCfg_ConfigureVoiceSlotB:
	ld xwa, (xsp + 10)
	ld_srib A, (xwa + 0x0152)
	srl a, 4
	extz wa
	lda_24 xbc, 0xee15ac
	ld_srib3 C, 0x07, 0xe4, 0xe0
	extz bc
	ld xwa, (xsp + 6)
	st_dri3b B, 0xe1, 0x0e, 0x03
	ld xwa, 0x4b00
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jrl lt, DSPCfg_VoiceSlotB_Epilog
	ld xbc, (xsp + 6)
	ld_srib A, (xbc + 0x030d)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	st_dri3b W, 0xe5, 0x0f, 0x03
	push xwa
	call Memset
	inc 8, xsp
	ldada xbc, 64654
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld_srib A, (xwa + 0x030e)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DSPCfg_VoiceSlotB_RestorePort
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DSPCfg_VoiceSlotB_RestorePort

DSPCfg_VoiceSlotB_ParamLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ResolveAndExtract
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	cps hl, 1
	jr z, DSPCfg_VoiceSlotB_MapAndWrite
	cps hl, 2
	jr nz, DSPCfg_VoiceSlotB_ReadAndWrite

DSPCfg_VoiceSlotB_MapAndWrite:
	ld xbc, (xsp + 10)
	ld_srib C, (xbc + 0x0152)
	and c, 0xf
	srl c, 1
	extz bc
	lda_24 xde, 0xee15bc
	ld_srib3 C, 0x07, 0xe8, 0xe4
	extz bc
	ld xde, (xsp + 6)
	st_dri3b B, 0xe9, 0x0e, 0x03
	jr DSPCfg_VoiceSlotB_WriteAndLoop

DSPCfg_VoiceSlotB_ReadAndWrite:
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	st_dri3b B, 0xe9, 0x0e, 0x03

DSPCfg_VoiceSlotB_WriteAndLoop:
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, DSPCfg_VoiceSlotB_ParamLoop

DSPCfg_VoiceSlotB_RestorePort:
	ld a, (xsp + 4)
	stda8 64654, a

DSPCfg_VoiceSlotB_Epilog:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DSPCfg_VoiceSlotB_ExtractData:
	ld	xde, xwa
	lda	xhl, (xde+373)
	ld	a, (xhl)
	and	a, 7
	jr	z, 19
	ld	a, (xhl)
	sll	a, 4
	and	a, 48
	andmi8	(xbc+737), 207
	or	(xbc+737), a
	lda	xwa, (xde+1006)
	ld	xhl, xwa
	lda	xix, (xbc+64)
	lda	xiy, (xwa+16)
	ld	a, (xhl-36)
	res	7, a
	.byte 0x8c
	swi	6
	push	xix
	.byte 0x80
	or	(xix-2), a
	ld	a, (xhl-18)
	res	7, a
	andmi8	(xix+1), 128
	or	(xix+1), a
	ld	a, (xhl+18)
	res	7, a
	.byte 0x8c
	swi	7
	push	xix
	.byte 0x80
	or	(xix-1), a
	ld_spib	a, 236
	ld	(xix), a
	lda	xix, (xix+26)
	cp	xhl, xiy
	jr	c, -51
	ld	a, (xde+389)
	extz	wa
	lda_24	xhl, 15603148
	ld_rrb	a, xhl, wa
	ld	(xbc+948), a
	ld	a, (xde+390)
	extz	wa
	ld_rrb	a, xhl, wa
	ld	(xbc+949), a
	ld	a, (xde+394)
	extz	wa
	ld_rrb	a, xhl, wa
	ld	(xbc+970), a
	ld	a, (xde+395)
	extz	wa
	ld_rrb	a, xhl, wa
	ld	(xbc+969), a
	ret
	ld	xde, xwa
	lda	xwa, (xde+371)
	ld	l, (xwa)
	and	l, 31
	andmi8	(xbc+1047), 128
	or	(xbc+1047), l
	ldcfm	6, (xwa)
	stcfm	6, (xbc+1046)
	lda	xix, (xbc+1049)
	lda	xhl, (xde+373)
	ld	a, (xhl)
	and	a, 112
	srl	a, 4
	and	a, 7
	sla	a, 4
	andmi8	(xix), 143
	or	(xix), a
	ld	a, (xhl)
	and	a, 7
	jr	z, 2
	setm	0, (xix)
	ld	a, (xde+374)
	and	a, 127
	andmi8	(xbc+1050), 128
	or	(xbc+1050), a
	ld	a, (xde+512)
	ld	(xbc+1066), a
	ld	a, (xde+513)
	ld	(xbc+1068), a
	ld	a, (xde+526)
	and	a, 15
	andmi8	(xbc+1078), 240
	or	(xbc+1078), a
	ld	a, (xde+528)
	and	a, 15
	andmi8	(xbc+1082), 240
	or	(xbc+1082), a
	ld	a, (xde+516)
	and	a, 15
	andmi8	(xbc+1087), 240
	or	(xbc+1087), a
	lda	xix, (xbc+1088)
	lda	xhl, (xde+517)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1089)
	lda	xhl, (xde+518)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1090)
	lda	xhl, (xde+519)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1091)
	lda	xhl, (xde+520)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1092)
	lda	xhl, (xde+521)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1093)
	lda	xhl, (xde+522)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1094)
	lda	xhl, (xde+523)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1095)
	lda	xhl, (xde+524)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1096)
	lda	xhl, (xde+525)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1097)
	lda	xhl, (xde+529)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1098)
	lda	xhl, (xde+530)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1099)
	lda	xhl, (xde+531)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1100)
	lda	xhl, (xde+532)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1101)
	lda	xhl, (xde+533)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1102)
	lda	xhl, (xde+534)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	ldcfm	7, (xde+407)
	stcfm	2, (xbc+1069)
	ld	a, (xde+1056)
	ld	(xbc+1576), a
	ld	a, (xde+1057)
	ld	(xbc+1577), a
	ld	a, (xde+1058)
	ld	(xbc+1578), a
	ld	a, (xde+1059)
	ld	(xbc+1579), a
	ld	a, (xde+1060)
	ld	(xbc+1580), a
	ld	a, (xde+1061)
	ld	(xbc+1581), a
	ld	a, (xde+1062)
	ld	(xbc+1582), a
	ld	a, (xde+1063)
	ld	(xbc+1583), a
	ld	a, (xde+1064)
	ld	(xbc+1584), a
	ld	a, (xde+1065)
	ld	(xbc+1585), a
	ld	a, (xde+1066)
	ld	(xbc+1586), a
	ld	a, (xde+1067)
	ld	(xbc+1587), a
	ld	a, (xde+1068)
	ld	(xbc+1588), a
	ld	a, (xde+1069)
	ld	(xbc+1589), a
	ld	a, (xde+1070)
	ld	(xbc+1590), a
	ld	a, (xde+1071)
	ld	(xbc+1591), a
	ret
	ld	e, (xwa+737)
	and	e, 48
	andmi8	(xbc+705), 207
	or	(xbc+705), e
	lda	xde, (xwa+64)
	ld	xwa, xde
	lda	xbc, (xbc+32)
	lda	xde, (xde+416)
	ld	l, (xwa-2)
	and	l, 127
	.byte 0x89
	swi	6
	push	xix
	.byte 0x80
	or	(xbc-2), l
	ld	l, (xwa+1)
	and	l, 127
	andmi8	(xbc+1), 128
	or	(xbc+1), l
	ld	l, (xwa-1)
	and	l, 127
	.byte 0x89
	swi	7
	push	xix
	.byte 0x80
	or	(xbc-1), l
	ld	l, (xwa)
	ld	(xbc), l
	lda	xbc, (xbc+26)
	lda	xwa, (xwa+26)
	cp	xwa, xde
	jr	c, -53
	ret

DataBuf_TransferSlotBitfields:
	ld xde, xbc
	ld_srib C, (xwa + 0x02e1)
	and c, 0x30
	and_srib_im 0xe9, 0xe1, 0x02, 0xcf
	or_srib_mr C, 0xe9, 0xe1, 0x02
	lda xbc, (xwa + 64)
	ld xhl, xbc
	lda xix, (xde + 64)
	st_dri3b E, 0xe5, 0xa0, 0x01

DataBuf_TransferSlotBitfields_Loop:
	ld c, (xhl - 2)
	res 7, c
	res 7, c
	andmi8 (xix - 2), 0x80
	or (xix - 2), c
	ld c, (xhl + 1)
	res 7, c
	res 7, c
	andmi8 (xix + 1), 0x80
	or (xix + 1), c
	ld c, (xhl - 1)
	res 7, c
	res 7, c
	andmi8 (xix - 1), 0x80
	or (xix - 1), c
	ld c, (xhl)
	ld (xix), c
	lda xix, (xix + 26)
	lda xhl, (xhl + 26)
	cp xhl, xiy
	jr c, DataBuf_TransferSlotBitfields_Loop
	ld_srib A, (xwa + 0x0417)
	and a, 0x7f
	and_srib_im 0xe9, 0x17, 0x04, 0x80
	or_srib_mr A, 0xe9, 0x17, 0x04
	ret

DataBuf_CheckFormatPair:
	; --- Multi-branch lookup: C=(XWA+4), check pairs, return HL=1/2/3/0xffff (52 bytes) ---
	ld c, (xwa+4)
	inc 5, xwa
	cp c, 0x4d
	jr nz, DataBuf_CheckFormatPair_NotM34
	ld e, (xwa)
	cp e, 0x34
	jr nz, DataBuf_CheckFormatPair_NotM34
	lds	hl, 1
	ret
DataBuf_CheckFormatPair_NotM34:
	ld a, (xwa)
	cp c, 0x4d
	jr nz, DataBuf_CheckFormatPair_NotM36
	cp a, 0x36
	jr nz, DataBuf_CheckFormatPair_NotM36
	lds	hl, 2
	ret
DataBuf_CheckFormatPair_NotM36:
	cp c, 0x4e
	jr nz, DataBuf_CheckFormatPair_NotN4E
	cp a, 0x4e
	jr nz, DataBuf_CheckFormatPair_NotN4E
	lds	hl, 3
	ret
DataBuf_CheckFormatPair_NotN4E:
	ldw hl, 0xffff
	ret


DataBuf_CheckSubFormat:
	lda xbc, (xwa + 6)
	ld a, (xwa + 5)
	cps a, 1
	jr nz, DataBuf_CheckSubFormat_Not6
	cp (xbc), 0x6
	jr nz, DataBuf_CheckSubFormat_Not6
	lds hl, 1
	ret

DataBuf_CheckSubFormat_Not6:
	cps a, 1
	jr nz, DataBuf_CheckSubFormat_Not7
	cp (xbc), 0x7
	jr nz, DataBuf_CheckSubFormat_Not7
	lds hl, 2
	ret

DataBuf_CheckSubFormat_Not7:
	cps a, 1
	jr nz, DataBuf_CheckSubFormat_Not3
	cp (xbc), 0x3
	jr nz, DataBuf_CheckSubFormat_Not3
	lds hl, 3
	ret

DataBuf_CheckSubFormat_Not3:
	ldw hl, 0xffff
	ret

DataBuf_Data_FormatDispatch:
	lda	xsp, (xsp-28)
	pushw	4
	pushw	0
	pushw	64596
	lda	xwa, (xsp+30)
	push	xwa
	call	Mem_Copy
	pushw	24
	pushw	0
	pushw	64732
	lda	xwa, (xsp+16)
	push	xwa
	call	Mem_Copy
	ldada	xwa, 63904
	pushw	1568
	pushw	237
	pushw	46076
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+30)
	pushw	4
	lda	xwa, (xsp+26)
	push	xwa
	pushw	0
	pushw	64596
	call	Mem_Copy
	pushw	24
	lda	xwa, (xsp+12)
	push	xwa
	pushw	0
	pushw	64732
	call	Mem_Copy
	lda	xsp, (xsp+48)
	ret
	dec	6, xsp
	pushw	iz
	ld	(xsp+6), wa
	lda_24	xwa, 15578108
	ld	(xsp+2), xwa
	lds	iz, 0
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	ule, 43
	ld	wa, iz
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xde, 2020352
	add	xde, xbc
	pushw	960
	ld	xwa, (xsp+4)
	push	xwa
	push	xde
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc	1, iz
	.byte 0x9f, 0x06, 0xf6
	jr	c, -43
	popw	iz
	inc	6, xsp
	ret

DataBuf_InitSlotFromPreset:
	pushw iz
	ld iz, wa
	lda_24 xwa, 0xedb3dc
	cps iz, 0
	jr nz, DataBuf_InitSlotFromPreset_Alt
	lda_24 xbc, 0x00f180
	add xbc, 0x2e0
	pushw 0x20
	push xwa
	push xbc
	call Mem_Copy
	lda_24 xbc, 0x00f180
	add xbc, 0x300
	ldada xwa, 64930
	sub xwa, 0xf9a0
	pushw wa
	pushw 0xed
	pushw 0xb3fc
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)
	jr SndParam_PopIzRet

DataBuf_InitSlotFromPreset_Alt:
	ld bc, iz
	dec 1, bc
	extz xbc
	sll xbc, 11
	ld xde, 0xab000
	add xde, xbc
	add xde, 0x2e0
	pushw 0x20
	push xwa
	push xde
	call Mem_Copy
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 11
	ld xbc, 0xab000
	add xbc, xwa
	add xbc, 0x300
	ldada xwa, 64930
	sub xwa, 0xf9a0
	pushw wa
	pushw 0xed
	pushw 0xb3fc
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)

SndParam_PopIzRet:
	popw iz
	ret

SndParam_SaturationClamp:
	; --- Routine 1: saturation clamp C = max(0, C-0x7f+A), return L (22 bytes) ---
	cps	a, 0
	jr z, SndParam_SaturationClamp_Zero
	cps	c, 0
	jr z, SndParam_SaturationClamp_Zero
	sub c, 0x7f
	add	c, a
	ld l, c
	cps	l, 0
	ret ge
SndParam_SaturationClamp_Zero:
	ldb l, 0x00
	ret
SndParam_TableDispatch_Memset:
	; --- Routine 2: table dispatch via 0x1ed360 + WA*16 (32 bytes) ---
	cp wa, 0x0009
	ret ugt
	lda_24	xbc, 2020192
	sll	wa, 4
	extz xwa
	add xbc, xwa
	pushw	16
	pushw	32
	push xbc
	call Memset
	inc 8, xsp
	ret


SndParam_ApplyAndSync:
	push_werp 0xfa
	ldda8 a, 47084
	bit 7, a
	jr z, SndParam_CheckBit6
	stdi8 47088, 1
	jr SndParam_ReadAndApply

SndParam_CheckBit6:
	bit 6, a
	jr z, SndParam_SetMode2
	stdi8 47088, 0
	jr SndParam_ReadAndApply

SndParam_SetMode2:
	stdi8 47088, 2

SndParam_ReadAndApply:
	ldda8 a, 47084
	and a, 0x3f
	ldfr_berp A, 0xfb
	stda8 47084, a
	cpdi8 47088, 0
	jr nz, SndParam_CheckRangeForDisplay
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldto_berp A, 0xfb
	stda8 47084, a
	stda8 47088, a

SndParam_CheckRangeForDisplay:
	ldda8 a, 47084
	cp a, 0x19
	jr c, SndParam_CallDisplaySync
	cp a, 0x1b
	jr c, SoundParam_UpdateCleanupRet
	cp a, 0x1d
	jr ugt, SoundParam_UpdateCleanupRet

SndParam_CallDisplaySync:
	cps a, 0
	jr z, SndParam_ApplyAllBlocks
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde

SndParam_ApplyAllBlocks:
	ldda8 a, 47084
	extz wa
	calr SndParam_ApplyBaseBlock
	ldda8 a, 47084
	extz wa
	calr SndParam_ApplyMaskBlock
	ldda8 a, 47084
	extz wa
	calr SndParam_ApplyModeSpecific
	bitda 0, 47086
	jr nz, SoundParam_UpdateCleanupRet
	lds wa, 3
	call BitMapOut_GetRenderMode_CheckBit3
	push xde
	push xhl
	push xix
	push xiz
	call SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitBothBanks
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

SoundParam_UpdateCleanupRet:
	pop_werp 0xfa
	ret

SndParam_ApplyMaskBlock:
	extz wa
	calr SndParam_GetBlockPointer
	or xhl, xhl
	ret z
	st_dri3b W, 0xed, 0x8a, 0x00
	ld xbc, xwa
	lda xde, (xwa + 96)

SndParam_ApplyMaskBlock_Loop:
	ld xhl, xbc
	ld xix, (xbc)
	or xix, xix
	jr z, SndParam_ApplyMaskBlock_Next
	ld a, (xhl + 4)
	cpl a
	and a, (xix)
	ld w, a
	ld a, (xhl + 5)
	or a, w
	ld (xix), a

SndParam_ApplyMaskBlock_Next:
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_ApplyMaskBlock_Loop
	ret

SndParam_ApplyBaseBlock:
	extz wa
	calr SndParam_GetBlockPointer
	or xhl, xhl
	ret z
	ld xbc, xhl
	st_dri3b B, 0xed, 0x8a, 0x00

SndParam_ApplyBaseBlock_Loop:
	ld xhl, xbc
	ld xix, (xbc)
	or xix, xix
	jr z, SndParam_ApplyBaseBlock_Next
	ld a, (xix)
	and a, 0xf8
	or a, (xhl + 4)
	lda_dpi XBC, 0xf0
	ld a, (xhl + 5)
	ld (xix), a

SndParam_ApplyBaseBlock_Next:
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_ApplyBaseBlock_Loop
	ret

SndParam_ApplyModeSpecific:
	ldda8 c, 47088
	cps c, 2
	ret z
	ldada xwa, 64941
	cps c, 0
	jr z, SndParam_ClearBits
	cps c, 1
	ret nz
	ld c, (xwa)
	and c, 0xf8
	ld (xwa), c
	set 2, c
	ld (xwa), c
	ret

SndParam_ClearBits:
	andmi8 (xwa), 0xf8
	ret

SndParam_AllocAndCopyPreset:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	pushw 0xea
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jrl z, SoundData_FreeSoundPtr
	cp (xsp + 4), 0x3
	jrl nc, SoundData_FreeSoundPtr
	pushw 0xea
	pushw 0xee
	pushw 0x15fe
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xwa, (xiz + 5)
	ld xbc, xwa
	st_dri3b B, 0xe1, 0x8a, 0x00

SndParam_CopyPreset_FillLoop:
	ld xhl, (xbc - 5)
	ld_spib A, 0xec
	and a, 0x7
	ld (xbc - 1), a
	ld a, (xhl)
	ld (xbc), a
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_CopyPreset_FillLoop
	st_dri3b W, 0xf9, 0x8f, 0x00
	ld xbc, xwa
	lda xde, (xwa + 96)

SndParam_CopyPreset_MaskLoop:
	ld xhl, (xbc - 5)
	ld a, (xbc - 1)
	and a, (xhl)
	ld (xbc), a
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_CopyPreset_MaskLoop
	call MainMpst_ReadPresetIndex
	cps l, 0
	jr nz, SndParam_CopyPreset_SelectBank
	lds32 xwa, 0
	st_dri3l XWA, 0xf9, 0xd8, 0x00

SndParam_CopyPreset_SelectBank:
	cp (xsp + 4), 0x2
	jr z, SndParam_CopyPreset_Bank2
	cp (xsp + 4), 0x1
	jr z, SndParam_CopyPreset_Bank1
	cp (xsp + 4), 0x0
	jr nz, SoundData_FreeSoundPtr
	ld xwa, 0x3d3010
	push xwa
	lds wa, 1
	ld xbc, xiz
	ldw de, 0xea
	jr SndParam_CopyPreset_CallFlash

SndParam_CopyPreset_Bank1:
	ld xwa, 0x3d3110
	push xwa
	lds wa, 1
	ld xbc, xiz
	ldw de, 0xea
	jr SndParam_CopyPreset_CallFlash

SndParam_CopyPreset_Bank2:
	ld xwa, 0x3d3210
	push xwa
	lds wa, 1
	ld xbc, xiz
	ldw de, 0xea

SndParam_CopyPreset_CallFlash:
	call FlashWrite

SoundData_FreeSoundPtr:
	push xiz
	call Free
	inc 4, xsp
	pop xiz
	inc 2, xsp
	ret

SndParam_GetBlockPointer:
	cp a, 0x19
	jr nc, SndParam_GetBlockPointer_Extended
	extz wa
	muls wa, 0xea
	lda_24 xbc, 0xee15fe
	st_dri3b C, 0x07, 0xe4, 0xe0
	ret

SndParam_GetBlockPointer_Extended:
	cp a, 0x1d
	jr z, SndParam_GetBlockPointer_Bank3
	cp a, 0x1c
	jr z, SndParam_GetBlockPointer_Bank2
	cp a, 0x1b
	jr z, SndParam_GetBlockPointer_Bank1
	lds32 xhl, 0
	ret

SndParam_GetBlockPointer_Bank1:
	ld xhl, 0x3d3010
	ret

SndParam_GetBlockPointer_Bank2:
	ld xhl, 0x3d3110
	ret

SndParam_GetBlockPointer_Bank3:
	ld xhl, 0x3d3210
	ret

SndParam_RelocateAndApply:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	extz bc
	ld wa, bc
	calr SndParam_GetBlockPointer
	or xhl, xhl
	jr z, SndParam_RelocateApply_Epilog
	st_dri3b A, 0xed, 0x8a, 0x00
	ld xde, xbc
	lda xiy, (xbc + 96)

SndParam_RelocateApply_MaskLoop:
	ld xiz, xde
	ld xix, (xde)
	or xix, xix
	jr z, SndParam_RelocateApply_NextMask
	sub xix, 0xf980
	add xix, (xsp + 4)
	ld a, (xiz + 4)
	cpl a
	and a, (xix)
	ld w, a
	ld a, (xiz + 5)
	or a, w
	ld (xix), a

SndParam_RelocateApply_NextMask:
	inc 6, xde
	cp xde, xiy
	jr c, SndParam_RelocateApply_MaskLoop

SndParam_RelocateApply_BaseLoop:
	ld xde, xhl
	ld xix, (xhl)
	or xix, xix
	jr z, SndParam_RelocateApply_NextBase
	sub xix, 0xf980
	add xix, (xsp + 4)
	ld a, (xix)
	and a, 0xf8
	or a, (xde + 4)
	lda_dpi XBC, 0xf0
	ld a, (xde + 5)
	ld (xix), a

SndParam_RelocateApply_NextBase:
	inc 6, xhl
	cp xhl, xbc
	jr c, SndParam_RelocateApply_BaseLoop

SndParam_RelocateApply_Epilog:
	pop xiz
	inc 4, xsp
	ret

SndParam_UpdateChannels:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), c
	cp a, 0xa
	jr nc, SndParam_UpdateAll_Loop
	extz wa
	ld c, (xsp + 2)
	extz bc
	calr SndParam_UpdateSingleChannel
	jr SndParam_UpdateChannels_Done

SndParam_UpdateAll_Loop:
	cp a, 0xa
	jr nz, SndParam_UpdateChannels_Done
	lds iz, 0

SndParam_UpdateAll_Body:
	ldto_berp A, 0xf8
	extz wa
	ld c, (xsp + 2)
	extz bc
	calr SndParam_UpdateSingleChannel
	inc 1, iz
	cp iz, 0xa
	jr c, SndParam_UpdateAll_Body

SndParam_UpdateChannels_Done:
	popw iz
	inc 2, xsp
	ret

SndParam_UpdateSingleChannel:
	dec 8, xsp
	ld (xsp + 4), c
	ld (xsp + 6), a
	setda 0, 47086
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	cp (xsp + 4), 0x3
	jr z, SndParam_UpdateChan_Mode3
	cp (xsp + 4), 0x2
	jr z, SndParam_UpdateChan_Mode2
	ld (xsp + 4), 0x16
	jr SndParam_UpdateChan_CallRender

SndParam_UpdateChan_Mode2:
	ld (xsp + 4), 0x17

SndParam_UpdateChan_CallRender:
	call SoundMode_RenderWithNotify
	jr SndParam_UpdateChan_CopyMemory

SndParam_UpdateChan_Mode3:
	ld (xsp + 4), 0x0
	call SoundMode_FullRenderUpdate

SndParam_UpdateChan_CopyMemory:
	lds32 xbc, 0
	ld c, (xsp + 6)
	sll xbc, 11
	lda_24 xwa, 0x0ab000
	add xwa, xbc
	ld (xsp), xwa
	ld xwa, 0x2e0
	add (xsp), xwa
	ldada xbc, 63872
	ldada xwa, 64930
	sub xwa, xbc
	pushw wa
	push xbc
	ld xwa, (xsp + 6)
	push xwa
	call Mem_Copy
	ldada xbc, 63904
	ldada xwa, 65472
	sub xwa, xbc
	pushw wa
	pushw 0x3
	pushw 0xc8e4
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)
	resda 0, 47086
	ld c, (xsp + 4)
	extz bc
	ld xwa, (xsp)
	calr SndParam_RelocateAndApply
	inc 8, xsp
	ret

MidiSysEx_SendAllParams:
	dec 2, xsp
	push xiz
	ld xwa, 0x2203
	call SndParam_LookupReadOnly
	cps hl, 0
	jrl nz, MidiSysEx_PopIzAndReturn
	pushw 0xe
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jrl z, MidiSysEx_PopIzAndReturn
	call GET_COMPUTER_INTERFACE_SELECTION
	ld (xsp + 4), l
	ld xwa, 0x2d03
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendReverbParam
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x20
	ld (xiz + 12), 0x3
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendParamViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbParam

MidiSysEx_SendParamViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbParam:
	ld xwa, 0x2d01
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendProgramChange
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldmi16 (xiz + 4), 0xb7f2
	ld (xiz + 9), 0x11
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendReverbViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbParam2

MidiSysEx_SendReverbViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbParam2:
	ld (xiz + 9), 0x12
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendReverb2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbFixup

MidiSysEx_SendReverb2ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbFixup:
	mrdb5 0x8e, 0x0c, 0x19, 0xf2, 0xb7

MidiSysEx_SendProgramChange:
	ld xwa, 0x2d03
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendControlChange1
	pushw 0x2
	pushw 0xee
	pushw 0x2cea
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendPCRegValue
	or (xiz), l

MidiSysEx_SendPCRegValue:
	ld xwa, 0x2d02
	call SndParam_LookupReadOnly
	ld (xiz + 1), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendPCViaCOMM
	push xiz
	pushw 0x2
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendControlChange1

MidiSysEx_SendPCViaCOMM:
	lds wa, 4
	lds bc, 2
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendControlChange1:
	ld xwa, 0x2d05
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendControlChange2
	pushw 0x3
	pushw 0xee
	pushw 0x2ce6
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendCC1RegValue
	or (xiz), l

MidiSysEx_SendCC1RegValue:
	ld xwa, 0x2d04
	call SndParam_LookupReadOnly
	ld (xiz + 2), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendCC1ViaCOMM
	push xiz
	pushw 0x3
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendControlChange2

MidiSysEx_SendCC1ViaCOMM:
	lds wa, 4
	lds bc, 3
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendControlChange2:
	ld xwa, 0x2d07
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_CheckDelayAndSend
	pushw 0x3
	pushw 0xee
	pushw 0x2ce6
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendCC2RegValue
	or (xiz), l

MidiSysEx_SendCC2RegValue:
	ld xwa, 0x2d06
	call SndParam_LookupReadOnly
	add hl, 0x3c
	ld (xiz + 2), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendCC2ViaCOMM
	push xiz
	pushw 0x3
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_CheckDelayAndSend

MidiSysEx_SendCC2ViaCOMM:
	lds wa, 4
	lds bc, 3
	ld xde, xiz
	call sendCOMM

MidiSysEx_CheckDelayAndSend:
	call AccPlay_GetCurrentPart
	cps l, 1
	jr nz, MidiSysEx_SendAfterDelay
	ldw wa, 0x32
	call TaskSched_DelayTicks

MidiSysEx_SendAfterDelay:
	ld xwa, 0x2d09
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendBankData1
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x20
	ld xwa, 0x2d08
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendAfterDelayViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData1

MidiSysEx_SendAfterDelayViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData1:
	ld xwa, 0x2d0b
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendBankData2
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x16
	ld (xiz + 12), 0x0
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank1ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank1Param2

MidiSysEx_SendBank1ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank1Param2:
	ld (xiz + 9), 0x17
	ld xwa, 0x2d0a
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank1P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData2

MidiSysEx_SendBank1P2ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData2:
	ld xwa, 0x2d0f
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_SendBankData3
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x28
	ld xwa, 0x2d0e
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank2Param2

MidiSysEx_SendBank2ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank2Param2:
	ld (xiz + 9), 0x29
	ld xwa, 0x2d0d
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank2P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData3

MidiSysEx_SendBank2P2ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData3:
	ld xwa, 0x2d13
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, MidiSysEx_FreeAndReturn
	pushw 0xe
	pushw 0xee
	pushw 0x2cd8
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x1b
	ld xwa, 0x2d12
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank3ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank3Param2

MidiSysEx_SendBank3ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank3Param2:
	ld (xiz + 9), 0x1c
	ld xwa, 0x2d11
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank3P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_FreeAndReturn

MidiSysEx_SendBank3P2ViaCOMM:
	lds wa, 4
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_FreeAndReturn:
	push xiz
	call Free
	inc 4, xsp

MidiSysEx_PopIzAndReturn:
	pop xiz
	inc 2, xsp
	ret

MidiSysEx_SendAllPartChannels:
	; --- Routine 1: stack-frame loop, XIZ alloc + 16 iterations (93 bytes) ---
	dec 2, xsp
	push xiz
	pushw	14
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, MidiSysEx_SendPartChan_Done
	ldw	(xsp+4), 0
MidiSysEx_SendPartChanLoop:
	pushw	14
	pushw	238
	pushw	11500
	push xiz
	call Mem_Copy
	lda	xsp, (xsp+10)
	ld	wa, (xsp+4)
	ld (xiz+4), a
	ld (xiz+9), 0x12
	ld xwa, 0x00002d00
	call SndParam_LookupReadOnly
	ld (xiz+0x0c), l
	push xiz
	pushw	14
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	incm	1, (xsp+4)
	cpw (xsp+4), 0x0010
	jr c, MidiSysEx_SendPartChanLoop
	push xiz
	call Free
	inc 4, xsp
MidiSysEx_SendPartChan_Done:
	pop xiz
	inc 2, xsp
	ret
MidiSysEx_CopyParamToBuffer:
	; --- Routine 2: sla+lda helper, push args + call FF0D99 (32 bytes) ---
	extz wa
	sla	wa, 3
	lda_24 xbc, 0xee2cfa
	exts xwa
	add xwa, xbc
	pushw	8
	push xwa
	pushw	0
	pushw	64586
	call Mem_Copy
	lda	xsp, (xsp+10)
	ret


MidiPkt_SendControlPair:
	ld xbc, 0xbd26
	ld (xbc), a
	ld (xbc + 1), w
	ld xwa, xbc
	call MidiPkt_EnqueueControl_335E
	ret

MidiStream_RefreshDisplay:
	push xde
	push xhl
	push xix
	push xiz
	ldda8 l, 48422
	ldda8 h, 48423
	call AccompSeq_ManualMidiEntry1
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_ApplyPendingCC:
	push xde
	push xhl
	push xix
	push xiz
	ldb c, 0x48
	ldb b, 0x3
	ldda8 e, 48422
	ldb d, 0x7
	call MidiStream_ApplyPendingParams
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_ReplaySavedExpr:
	push xde
	push xhl
	push xix
	push xiz
	call AccWrap_ReplaySavedExpr
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_JumpStubData:
	push	xiz
	call	Audio_ProcessAllMidiStreams
	pop	xiz
	ret

MidiStream_RetStub2:
	ret

AccWrap_ReturnZero:
	lds hl, 0
	ret

MidiStream_RetStub3:
	ret

MidiStream_PrevBankCheck:
	.byte 0xd7
	swi	2
	.byte 0x04, 0xf1
	push_f
	ld	(xiy-49), xiz
	push	xwa
	.byte 0xc7
	swi	3
	.byte 0xa8
	calr	60
	ldda32	xwa, 48300
	.byte 0x80
	push	xsp
	.byte 0x01
	jr	z, 47
	.byte 0x80
	push	xsp
	.byte 0x06
	jr	nz, 6
	ld	(xwa+4), 32
	jr	36
	ldda32	xwa, 48224
	calr	3797
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	inc	7, hl
	.byte 0xda, 0xc7
	swi	3
	inc	7, hl
	rcf
	ldda32	xwa, 48300
	ld	(xwa+4), 24
	jr	6
	calr	24
	calr	5117
	.byte 0xd7
	swi	2
	halt
	ret

SeqAlt_ProcessAndFinalize:
	call MidiSeq_SwapActiveBuffers
	calr SeqBuf_WaitForEmpty
	calr MidiChan_ParseVoiceData
	calr SeqData_InitPlaybackFromField
	jp SeqAlt_CheckInitBuffer

SeqBuf_WaitForEmpty:
	pushw iz
	ldw iz, 0xfffe

SeqBuf_WaitLoop:
	call SeqBuf_MidiOut_CheckEmpty
	cps hl, 0
	jr z, SeqBuf_WaitDone
	ld wa, iz
	dec 1, iz
	cps wa, 0
	jr nz, SeqBuf_WaitLoop

SeqBuf_WaitDone:
	popw iz
	ret

MidiChan_ParseVoiceData:
	push xiz
	ldi_berp 0xfb, 0
	resda 5, 48408
	ldda16 xiz, 1033
	jrl MidiChan_CheckSysExFlag

MidiChan_ReadNextByte:
	ldda32 xwa, 48300
	lds bc, 4
	calr SeqData_ReadFieldByIndex
	cps l, 0
	jrl nz, MidiChan_ParseVoiceDone
	call SeqBuf2_ReadByte
	cp hl, 0xffff
	jr z, MIDI_ProcessChannelPair
	ldda16 xiz, 1033
	ld c, l
	extz bc
	ldda32 xwa, 48300
	cpi_berp 0xfb, 1
	jr z, MidiChan_CheckSysExData
	cpi_berp 0xfb, 0
	jr nz, MidiChan_CheckHighBit
	cp l, 0xf0
	jr nz, MidiChan_SendFieldParam4
	ldi_berp 0xfb, 1
	ld wa, bc
	jr MidiChan_AppendAndContinue

MidiChan_SendFieldParam4:
	lds bc, 4
	lds de, 1
	jr MidiChan_WriteAndSetFlag

MidiChan_CheckSysExData:
	cp l, 0x50
	jr nz, MidiChan_SendFieldParam4_2
	ldi_berp 0xfb, 2
	ld wa, bc
	jr MidiChan_AppendAndContinue

MidiChan_SendFieldParam4_2:
	lds bc, 4
	lds de, 2
	jr MidiChan_WriteAndSetFlag

MidiChan_CheckHighBit:
	bit 7, l
	jr nz, MidiChan_CheckSysExEnd
	ldda32 xde, 48212
	cpw (xde), 0xff
	jr nc, MidiChan_SendFieldParam6
	ld wa, bc

MidiChan_AppendAndContinue:
	calr VoiceQueue_Append
	jr MIDI_ProcessChannelPair

MidiChan_SendFieldParam6:
	lds bc, 4
	lds de, 6
	calr MIDI_ReadChannelParam
	jr MIDI_ProcessChannelPair

MidiChan_CheckSysExEnd:
	cp l, 0xf7
	jr nz, MidiChan_SendFieldParam3
	ldi_berp 0xfb, 0
	ld wa, bc
	calr VoiceQueue_Append
	setda 5, 48408
	jr MIDI_ProcessChannelPair

MidiChan_SendFieldParam3:
	lds bc, 4
	lds de, 3

MidiChan_WriteAndSetFlag:
	calr MIDI_ReadChannelParam
	setda 5, 1074

MIDI_ProcessChannelPair:
	calr MidiChan_CheckFlags
	ld wa, iz
	calr MidiChan_CheckTimeout

MidiChan_CheckSysExFlag:
	bitda 5, 48408
	jrl z, MidiChan_ReadNextByte

MidiChan_ParseVoiceDone:
	pop xiz
	ret

VoiceQueue_Append:
	ldda32 xbc, 48212
	lda xde, (xbc + 10)
	ld xbc, (xde)
	st_dpib C, 0xe4
	ld (xde), xbc
	ld (xhl), a
	ldda32 xbc, 48212
	ld xbc, (xbc + 10)
	ld (xbc), 0xff
	ldda32 xbc, 48212
	cp a, 0xf0
	jr nz, VoiceQueue_IncrementCount
	ldw (xbc), 0x1
	ret

VoiceQueue_IncrementCount:
	incm 1, (xbc)
	ret

MidiChan_DequeueVoiceEntry:
	ldb l, 0xff
	lda xbc, (xwa + 2)
	ld xwa, (xbc)
	cp (xwa), 0xff
	ret z
	st_dpib B, 0xe0
	ld (xbc), xwa
	ld l, (xde)
	ret

MidiChan_NibbleLookup_Data:
	ld	hl, de
	ld	xde, xwa
	ld	wa, hl
	dec	1, hl
	cps	wa, 0
	jr	z, 23
	lda	xix, (xde+10)
	ld	xwa, (xix)
	.byte 0xf5, 0xe0
	ldw	iy, 24756
	.byte 0xc5, 0xe4
	ldb	a, 181
	ld	xbc, 1775995099
	cps	wa, 0
	jr	nz, -20
	ld	xwa, (xde+10)
	ld	(xwa), 255
	ret

MIDI_ReadChannelParam:
	extz bc
	cps bc, 0
	ret mi
	cp bc, 0xf
	ret gt
	add bc, bc
	lda_24 xix, 0xee2d2a
	ld_sriw3 BC, 0x07, 0xf0, 0xe4
	lda_24 xix, MidiChan_ParamDispatch
	jp_dri 8, 0x07, 0xf0, 0xe4
; MIDI channel parameter read dispatch
MidiChan_ParamDispatch:
	ld	(xwa), e
	ret
	lds32	xbc, 1
	jr	78
	lds32	xbc, 2
	jr	74
	lds32	xbc, 3
	jr	70
	lds32	xbc, 4
	jr	66
	lds32	xbc, 5
	jr	62
	lds32	xbc, 6
	jr	58
	lds32	xbc, 7
	jr	54
	ld	xbc, 8
	jr	47
	ld	xbc, 9
	jr	40
	ld	xbc, 10
	jr	33
	ld	xbc, 11
	jr	26
	ld	xbc, 12
	jr	19
	ld	xbc, 13
	jr	12
	ld	xbc, 14
	jr	5
	ld	xbc, 15
	add	xwa, xbc
	ld	(xwa), e
	ret

; ============================================================================
; SeqData_ReadFieldByIndex - Read a field from sequencer data by index
; ============================================================================
; Input:  Index parameter identifying which field to read
; Output: Field value
; Indexed accessor for sequencer data structures. Reads a specific field
; from the current sequencer data block based on the given index.
; ============================================================================
SeqData_ReadFieldByIndex:
	extz bc
	cps bc, 0
	jr mi, SeqData_ReturnZeroField
	cp bc, 0xf
	jr gt, SeqData_ReturnZeroField
	add bc, bc
	lda_24 xix, 0xee2d4a
	ld_sriw3 BC, 0x07, 0xf0, 0xe4
	lda_24 xix, SeqData_FieldDispatch
	jp_dri 8, 0x07, 0xf0, 0xe4
; Sequence data field read dispatch
SeqData_FieldDispatch:
	ld	l, (xwa)
	jr	90
	lds32	xbc, 1
	jr	78
	lds32	xbc, 2
	jr	74
	lds32	xbc, 3
	jr	70
	lds32	xbc, 4
	jr	66
	lds32	xbc, 5
	jr	62
	lds32	xbc, 6
	jr	58
	lds32	xbc, 7
	jr	54
	ld	xbc, 8
	jr	47
	ld	xbc, 9
	jr	40
	ld	xbc, 10
	jr	33
	ld	xbc, 11
	jr	26
	ld	xbc, 12
	jr	19
	ld	xbc, 13
	jr	12
	ld	xbc, 14
	jr	5
	ld	xbc, 15
	add	xwa, xbc
	ld	l, (xwa)
	jr	2

SeqData_ReturnZeroField:
	ldb l, 0x0
	ret

SeqData_InitPlaybackFromField:
	ldda32 xwa, 48300
	lds bc, 4
	calr SeqData_ReadFieldByIndex
	cps l, 0
	ret nz
	calr MidiSeq_AssignVoiceSlots
	calr MidiStream_RetStub3
	calr MidiSeq_NopRet
	calr MidiSeq_ValidateVoiceRange
	calr MidiSeq_CheckQueuePosition
	calr MidiSeq_ParseVoiceConfig
	ret

MidiSeq_AssignVoiceSlots:
	dec 4, xsp
	push_werp 0xfa
	ldda32 xbc, 48212
	lds32 xwa, 2
	add (xbc + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0
	lda_24 xbc, 0xee493e

MidiSeq_ScanSlot0_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	exts xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot0_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	lds de, 7
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot0_CheckMatch:
	cp (xwa), l
	jr z, MidiSeq_Slot0_WriteParams
	cp (xwa), 0xfe
	jr nz, MidiSeq_Slot0_NextEntry

MidiSeq_Slot0_WriteParams:
	extz hl
	ldda32 xwa, 48300
	lds bc, 5
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	lda_24 xbc, 0xee493e
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot0_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	lda_24 xwa, 0xee4940
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	lda_24 xwa, 0xee4940
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot0_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	jr MidiSeq_PrepSlot1

MidiSeq_Slot0_NextEntry:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x10
	jrl c, MidiSeq_ScanSlot0_Loop

MidiSeq_PrepSlot1:
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot1_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot1_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0x8
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot1_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot1_NextEntry

MidiSeq_Slot1_WriteParams:
	extz hl
	ldda32 xwa, 48300
	lds bc, 6
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot1_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot2_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot2_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0x9
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot1_Loop

MidiSeq_Slot2_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot2_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot2_NextEntry

MidiSeq_Slot2_WriteParams:
	extz hl
	ldda32 xwa, 48300
	lds bc, 7
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot2_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot2_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot3_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot3_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xa
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot2_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot2_Loop

MidiSeq_Slot3_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot3_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot3_NextEntry

MidiSeq_Slot3_WriteParams:
	extz hl
	ldda32 xwa, 48300
	ldw bc, 0x8
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot3_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot3_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot4_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot4_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xb
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot3_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot3_Loop

MidiSeq_Slot4_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot4_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot4_NextEntry

MidiSeq_Slot4_WriteParams:
	extz hl
	ldda32 xwa, 48300
	ldw bc, 0x9
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot4_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot4_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot5_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot5_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xc
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot4_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot4_Loop

MidiSeq_Slot5_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot5_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot5_NextEntry

MidiSeq_Slot5_WriteParams:
	extz hl
	ldda32 xwa, 48300
	ldw bc, 0xa
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot5_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot5_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot6_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot6_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xd
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot5_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot5_Loop

MidiSeq_Slot6_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot6_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot6_NextEntry

MidiSeq_Slot6_WriteParams:
	extz hl
	ldda32 xwa, 48300
	ldw bc, 0xb
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot6_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot6_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot7_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot7_CheckMatch
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xe
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot6_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot6_Loop

MidiSeq_Slot7_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot7_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot7_NextEntry

MidiSeq_Slot7_WriteParams:
	extz hl
	ldda32 xwa, 48300
	ldw bc, 0xc
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot7_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot7_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0

MidiSeq_ScanSlot8_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	exts xbc
	add xbc, xwa
	ldda32 xwa, 48300
	cp (xbc), 0xff
	jr nz, MidiSeq_Slot8_CheckMatch
	lds bc, 4
	ldw de, 0xf
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot7_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot7_Loop

MidiSeq_Slot8_CheckMatch:
	cp l, (xbc)
	jr z, MidiSeq_Slot8_WriteParams
	cp (xbc), 0xfe
	jrl nz, MidiSeq_Slot8_NextEntry

MidiSeq_Slot8_WriteParams:
	extz hl
	ldw bc, 0xd
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_Slot8_StorePtr
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot8_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldi_berp 0xfb, 0
	ldda32 xwa, 48300

MidiSeq_ScanSlot9_Loop:
	ldto_berp C, 0xfb
	extz bc
	muls bc, 0x6
	ld de, bc
	ld xbc, (xsp + 2)
	st_dri3b A, 0x07, 0xe4, 0xe8
	cp (xbc), 0xff
	jr nz, MidiSeq_Slot9_CheckMatch
	lds bc, 4
	ldw de, 0x10
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot8_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot8_Loop

MidiSeq_Slot9_CheckMatch:
	cp l, (xbc)
	jr z, MidiSeq_Slot9_WriteParams
	cp (xbc), 0xfe
	jrl nz, MidiSeq_Slot9_NextEntry

MidiSeq_Slot9_WriteParams:
	extz hl
	ldw bc, 0xe
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld e, (xwa + 1)
	cps e, 0
	jr z, MidiSeq_RestoreAndReturn
	ldda32 xwa, 48300
	lds bc, 0
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ldda32 xwa, 48300
	lds bc, 1
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ldda32 xwa, 48300
	lds bc, 2

MidiSeq_ChannelWriteEpilog:
	calr MIDI_ReadChannelParam

MidiSeq_RestoreAndReturn:
	pop_werp 0xfa
	inc 4, xsp
	ret

MidiSeq_Slot9_NextEntry:
	inc1_berp 0xfb
	jrl MidiSeq_ScanSlot9_Loop

MidiSeq_NopRet:
	ret

MidiSeq_ValidateVoiceRange:
	push xiz
	ldda32 xwa, 48300
	lds bc, 4
	calr SeqData_ReadFieldByIndex
	cps l, 0
	jrl nz, MidiSeq_PopIzRet
	ldda32 xwa, 48300
	lds bc, 0
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x11
	jr z, MidiSeq_Dequeue3Voices
	cp_erpb 0xfb, 0x14
	jr z, MidiSeq_Dequeue3Voices
	cp_erpb 0xfb, 0x19
	jrl nz, MidiSeq_CheckBitfieldType

MidiSeq_Dequeue3Voices:
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf8
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf9
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xfa
	lds32 xde, 0
	ldto_berp E, 0xfa
	lds32 xwa, 0
	ldto_berp A, 0xf9
	sll xwa, 7
	or xde, xwa
	lds32 xwa, 0
	ldto_berp A, 0xf8
	sll xwa, 14
	or xde, xwa
	cp_erpb 0xfb, 0x14
	jr z, MidiSeq_SetRange4D800
	cp_erpb 0xfb, 0x19
	jr z, MidiSeq_SetRange3900
	cp_erpb 0xfb, 0x11
	jr nz, MidiSeq_SetRange4D800
	ld xbc, 0x15440
	jr MidiSeq_CompareRange

MidiSeq_SetRange3900:
	ld xbc, 0x3900
	jr MidiSeq_CompareRange

MidiSeq_SetRange4D800:
	ld xbc, 0x4d800

MidiSeq_CompareRange:
	ldda32 xwa, 48300
	cp xde, xbc
	jr ugt, MidiSeq_RangeOverflow
	ldto_berp E, 0xf8
	extz de
	ldw bc, 0xc
	calr MIDI_ReadChannelParam
	ldto_berp E, 0xf9
	extz de
	ldda32 xwa, 48300
	ldw bc, 0xd
	calr MIDI_ReadChannelParam
	ldto_berp E, 0xfa
	extz de
	ldda32 xwa, 48300
	ldw bc, 0xe
	jr MidiSeq_WriteParamAndReturn

MidiSeq_RangeOverflow:
	lds bc, 4
	ldw de, 0x16
	jr MidiSeq_WriteParamAndReturn

MidiSeq_CheckBitfieldType:
	cp_erpb 0xfb, 0x1b
	jr z, MidiSeq_ReadBitfield
	cp_erpb 0xfb, 0x1d
	jr nz, MidiSeq_PopIzRet

MidiSeq_ReadBitfield:
	ldda32 xwa, 48300
	ldw bc, 0xc
	calr SeqData_ReadFieldByIndex
	cp l, 0xff
	jr nz, MidiSeq_PopIzRet
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf8
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldto_berp A, 0xf8
	or a, l
	ldfr_berp A, 0xf8
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldto_berp A, 0xf8
	or a, l
	ldfr_berp A, 0xf8
	cpi_berp 0xf8, 1
	jr z, MidiSeq_PopIzRet
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0xe

MidiSeq_WriteParamAndReturn:
	calr MIDI_ReadChannelParam

MidiSeq_PopIzRet:
	pop xiz
	ret

MidiSeq_CheckQueuePosition:
	push_werp 0xfa
	ldda32 xwa, 48300
	lds bc, 4
	calr SeqData_ReadFieldByIndex
	cps l, 0
	jrl nz, MidiSeq_PopRetFA
	ldda32 xwa, 48300
	ldw bc, 0xc
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	ldda32 xwa, 48300
	ldw bc, 0xd
	calr SeqData_ReadFieldByIndex
	ldto_berp A, 0xfb
	or a, l
	ldfr_berp A, 0xfb
	ldda32 xwa, 48300
	ldw bc, 0xe
	calr SeqData_ReadFieldByIndex
	ldto_berp A, 0xfb
	or a, l
	ldfr_berp A, 0xfb
	and a, 0xff
	jr z, MidiSeq_PopRetFA
	ldda32 xwa, 48300
	lds bc, 5
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x7e
	jr z, MidiSeq_TrimQueue
	cp_erpb 0xfb, 0x2d
	jr z, MidiSeq_TrimQueue
	cp_erpb 0xfb, 0x2c
	jr nz, MidiSeq_PopRetFA

MidiSeq_TrimQueue:
	ldda32 xbc, 48212
	ld xde, (xbc + 10)
	dec 3, xde
	ld xwa, (xbc + 2)
	ld (xbc + 6), xwa
	ldda32 xbc, 48212
	inc 2, xbc
	cp (xbc), xde
	jr nc, MidiSeq_TrimCheckDone
	ld xhl, xbc

MidiSeq_TrimLoop:
	lds32 xwa, 2
	add (xhl), xwa
	cp (xbc), xde
	jr c, MidiSeq_TrimLoop

MidiSeq_TrimCheckDone:
	ldda32 xwa, 48212
	cp (xwa + 2), xde
	jr z, MidiSeq_PopRetFA
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0x11
	calr MIDI_ReadChannelParam

MidiSeq_PopRetFA:
	pop_werp 0xfa
	ret

MidiSeq_ParseVoiceConfig:
	push_werp 0xfa
	ldi_berp 0xfb, 0
	ldda32 xwa, 48300
	lds bc, 4
	calr SeqData_ReadFieldByIndex
	cps l, 0
	jr nz, MidiChan_DequeueExit
	ldda32 xwa, 48300
	lds bc, 5
	calr SeqData_ReadFieldByIndex
	cp l, 0x7e
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2d
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2c
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2b
	jr nz, MidiChan_DequeueExit

SeqData_ParseFieldAndDequeue:
	ldda32 xwa, 48212
	calr MidiChan_DequeueVoiceEntry
	ldda32 xwa, 48300
	cps l, 0
	jr z, MidiSeq_DequeueWriteField15
	cps l, 1
	jr nz, MidiSeq_WriteField4_12

MidiSeq_DequeueWriteField15:
	extz hl
	ldw bc, 0xf
	ld de, hl
	calr MIDI_ReadChannelParam
	ldda32 xwa, 48212
	lda xbc, (xwa + 15)
	ld xhl, xbc
	ld xde, (xwa + 2)
	cp xbc, xde
	jr z, MidiSeq_NegateAndCheck

MidiSeq_CountEntriesLoop:
	ldto_berp C, 0xfb
	add_spib C, 0xec
	ldfr_berp C, 0xfb
	cp xhl, xde
	jr nz, MidiSeq_CountEntriesLoop

MidiSeq_NegateAndCheck:
	ldto_berp C, 0xfb
	neg c
	ldfr_berp C, 0xfb
	res_erpb 0xfb, 0x07
	calr MidiChan_DequeueVoiceEntry
	cp_berp L, 0xfb
	jr z, MidiChan_DequeueExit
	ldda32 xwa, 48300
	lds bc, 4
	ldw de, 0x14
	jr MidiSeq_WriteParamAndExit

MidiSeq_WriteField4_12:
	lds bc, 4
	ldw de, 0x12

MidiSeq_WriteParamAndExit:
	calr MIDI_ReadChannelParam

MidiChan_DequeueExit:
	pop_werp 0xfa
	ret

SeqBuf_FlushNoteOffs:
	ld de, bc
	dec 1, bc
	cps de, 0
	jr z, SeqBuf_FlushTerminate
	ldda32 xhl, 48220
	lda xix, (xhl + 10)

SeqBuf_FlushLoop:
	ld xde, (xix)
	st_dpib E, 0xe8
	ld (xix), xde
	ld_spib E, 0xe0
	ld (xiy), e
	incm 1, (xhl)
	ld de, bc
	dec 1, bc
	cps de, 0
	jr nz, SeqBuf_FlushLoop

SeqBuf_FlushTerminate:
	ldda32 xwa, 48220
	ld xwa, (xwa + 10)
	ld (xwa), 0xff
	ldda32 xwa, 48220
	ld xbc, (xwa + 10)
	cp (xbc - 1), 0xf7
	ret nz

	calr SeqOut_FlushWithChunking
	call MidiSeq_UpdateAllParams
	call ArpQueue_SwapBuffers
	ret

ArpQueue_Pack21BitValue:
	dec	4, xsp
	lda	xwa, (xsp)
	ldada	xde, 48340
	ld	xbc, (xde)
	srl	xbc, 14
	res	7, c
	ld	(xwa), c
	ld	xbc, (xde)
	srl	xbc, 7
	res	7, c
	ld	(xwa+1), c
	ld	xbc, (xde)
	res	7, c
	ld	(xwa+2), c
	lds	bc, 3
	calr	3
	inc	4, xsp
	ret

ArpQueue_Enqueue:
	ld de, bc
	dec 1, bc
	cps de, 0
	jr z, ArpQueue_EnqueueDone
	ldda32 xhl, 48220
	lda xix, (xhl + 10)

ArpQueue_EnqueueLoop:
	ld xde, (xix)
	st_dpib E, 0xe8
	ld (xix), xde
	ld_spib E, 0xe0
	ld (xiy), e
	incm 1, (xhl)
	ld de, bc
	dec 1, bc
	cps de, 0
	jr nz, ArpQueue_EnqueueLoop

ArpQueue_EnqueueDone:
	ldda32 xwa, 48220
	ld xwa, (xwa + 10)
	ld (xwa), 0xff
	ret

ArpQueue_ProcessAndSort_Data:
	ldda32	xwa, 48300
	.byte 0x88, 0x04
	push	xsp
	nop
	ret	nz
	ldda32	xwa, 48300
	.byte 0x88, 0x04
	push	xsp
	nop
	ret	nz
	call	MidiSeq_PartConfigure_Data
	calr	36
	calr	54
	calr	129
	calr	195
	ldda32	xwa, 48220
	calr	241
	call	MidiSeq_UpdateAllParams
	call	ArpQueue_SwapBuffers
	calr	61927
	ldda32	xwa, 48340
	or	xwa, xwa
	jr	nz, -52
	ret
	ldda32	xwa, 48312
	.byte 0x88
	retd	319
	ret	nz
	ld	xwa, 15611320
	lds	bc, 3
	calr	65288
	ret
	dec	2, xsp
	ldda32	xwa, 48340
	or	xwa, xwa
	jr	z, 65
	lda	xwa, (xsp)
	lda	xde, (xwa+1)
	ldada	xhl, 48332
	ld	xbc, (xhl)
	.byte 0xf5, 0xe4
	ldw	ix, 25011
	ld	c, (xix)
	ld	(xde), c
	ld	(xwa), c
	srl	c, 4
	ld	(xwa), c
	.byte 0x82
	push	xix
	retd	43737
	calr	65359
	lds32	xwa, 1
	subdm32	48324, xwa
	ldada	xbc, 48340
	ld	xwa, (xbc)
	dec	1, xwa
	ld	(xbc), xwa
	or	xwa, xwa
	jr	z, 10
	ldda32	xwa, 48220
	.byte 0x90
	push	xsp
	swi	4
	nop
	jr	c, -65
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), 1
	ldda32	xwa, 48340
	or	xwa, xwa
	jr	nz, 3
	ld	(xsp), 0
	lda	xwa, (xsp)
	lds	bc, 1
	calr	65303
	ld	e, (xsp)
	extz	de
	ldda32	xwa, 48308
	ldw	bc, 15
	calr	62176
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), 1
	lda	xwa, (xsp)
	lds	bc, 1
	calr	65274
	ld	e, (xsp)
	extz	de
	ldda32	xwa, 48308
	ldw	bc, 15
	calr	62147
	inc	2, xsp
	ret

ArpQueue_ComputeAndEnqueue:
	dec 2, xsp
	ldb e, 0x0
	ld xiy, 0xee2d6a
	ld xix, xsp
	ldiw
	ldda32 xwa, 48220
	lda xbc, (xwa + 15)
	ld xhl, xbc
	ld xwa, (xwa + 10)
	cp xbc, xwa
	jr z, ArpQueue_ComputeSize

ArpQueue_CountLoop:
	add_spib E, 0xec
	cp xhl, xwa
	jr nz, ArpQueue_CountLoop

ArpQueue_ComputeSize:
	lda xwa, (xsp)
	neg e
	res 7, e
	ld (xwa), e
	lds bc, 2
	calr ArpQueue_Enqueue
	inc 2, xsp
	ret

SeqOut_FlushWithChunking:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld wa, (xiz)
	ld (xsp + 4), wa
	stdi8 1060, 240
	ld xwa, xiz
	calr MidiStream_RetStub2
	lda xiz, (xiz + 14)
	cpw (xsp + 4), 0x20
	jr ule, SeqOut_ChunkRemainder

SeqOut_ChunkLoop32:
	ei 6
	push xiz
	pushw 0x20
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	submi16 (xsp + 4), 0x20
	lda xiz, (xiz + 32)
	cpw (xsp + 4), 0x20
	jr ugt, SeqOut_ChunkLoop32

SeqOut_ChunkRemainder:
	ei 6
	push xiz
	pushm (xsp + 8)
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	pop xiz
	inc 2, xsp
	ret

SeqOut_FlushTimedBuffer:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld wa, (xiz)
	ld (xsp + 4), wa
	stdi8 1060, 240
	ld xwa, xiz
	calr MidiStream_RetStub2
	lda xiz, (xiz + 14)
	cpw (xsp + 4), 0x20
	jr ule, SeqOut_TimedChunkRemainder

SeqOut_TimedChunkLoop32:
	ei 6
	push xiz
	pushw 0x20
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	submi16 (xsp + 4), 0x20
	lda xiz, (xiz + 32)
	cpw (xsp + 4), 0x20
	jr ugt, SeqOut_TimedChunkLoop32

SeqOut_TimedChunkRemainder:
	ei 6
	push xiz
	pushm (xsp + 8)
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	pop xiz
	inc 2, xsp
	ret

SeqVoice_ReadEntryFields_Data:
	ld	xde, xwa
	ld	a, (xde)
	.byte 0xf5, 0xe4, 0x41
	ld	a, (xde+1)
	.byte 0xf5, 0xe4, 0x41
	ld	a, (xde+2)
	.byte 0xf5, 0xe4, 0x41
	ld	a, (xde+3)
	.byte 0xf5, 0xe4
	ld	xbc, 0x0eff00b1

SeqVoice_StoreEntry:
	dec 4, xsp
	lda xbc, (xsp)
	ld xde, (xsp + 8)
	ld_spib A, 0xe8
	ld (xbc), a
	cp a, 0xff
	jr z, SeqVoice_StoreEntryDone
	ld_spib A, 0xe8
	ld (xbc + 1), a
	ld_spib A, 0xe8
	ld (xbc + 2), a
	ld a, (xde)
	ld (xbc + 3), a

SeqVoice_StoreEntryDone:
	ld xhl, (xsp)
	inc 4, xsp
	ret

SeqVoice_DispatchProcess_Data:
	lda	xsp, (xsp-12)
	push	xiz
	ldda32	xiz, 48212
	cpw	(xiz), 0
	jr	z, 114
	lda	xbc, (xiz+6)
	ld	xix, xbc
	ld	xhl, xbc
	ldada	xiy, 48364
	ld	xde, xiy
	ldada	xwa, 48356
	ld	(xsp+4), xwa
	inc	8, xiy
	ld	(xsp+8), xbc
	lda	xwa, (xiz+10)
	ld	(xsp+12), xwa
	ld	xwa, (xix)
	.byte 0xf5, 0xe0
	ldw	bc, 24756
	ld	c, (xbc)
	sll	c, 4
	ld	xwa, (xhl)
	.byte 0xf5, 0xe0
	ldw	iz, 24755
	ld	w, (xiz)
	and	w, 15
	xor	c, w
	ld	xwa, (xde)
	.byte 0xf5, 0xe0
	ldw	iz, 24754
	ld	(xiz), c
	ld	xwa, (xsp+4)
	lds32	xbc, 1
	sub	(xwa), xbc
	ld	xbc, (xiy)
	dec	1, xbc
	ld	(xiy), xbc
	ld	xwa, (xsp+12)
	ld	xwa, (xwa)
	lda	xiz, (xwa-3)
	ld	xwa, (xsp+8)
	cp	(xwa), xiz
	jr	c, 4
	lds	hl, 0
	jr	19
	or	xbc, xbc
	jr	nz, -71
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 22
	calr	61741
	ldw	hl, 65535
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	push	xiz
	ldda32	xwa, 48300
	ldw	bc, 12
	calr	61846
	lds32	xiz, 0
	.byte 0xc7
	swi	0
	or	(xsp-18), iz
	ret
	ldda32	xwa, 48300
	ldw	bc, 13
	calr	61828
	ldb	h, 0
	extz	xhl
	sll	xhl, 7
	or	xiz, xhl
	ldda32	xwa, 48300
	ldw	bc, 14
	calr	61809
	ldb	h, 0
	extz	xhl
	or	xiz, xhl
	ldada	xwa, 48348
	ld	xbc, (xwa)
	add	xbc, xiz
	ld	(xwa+4), xbc
	ld	(xwa+8), xiz
	ldada	xwa, 48364
	ld	xbc, (xwa)
	add	xbc, xiz
	ld	(xwa+4), xbc
	ld	(xwa+8), xiz
	pop	xiz
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ldada	xwa, 63872
	ld	(xiz), xwa
	calr	763
	ld	(xsp+4), xhl
	calr	779
	ldada	xwa, 65470
	sub	xwa, 63872
	add	xwa, 76978
	add	xwa, xhl
	.byte 0xaf, 0x04
	or	(xwa), w
	.byte 0xc8
	nop
	pop	xwa
	nop
	nop
	add	(xiz+8), xwa
	lds	wa, 1
	calr	61196
	cp	hl, 65535
	jr	z, 8
	ld	xwa, 29354
	add	(xiz+8), xwa
	lds	wa, 3
	calr	61177
	cp	hl, 65535
	jr	z, 6
	calr	671
	add	(xiz+8), xhl
	ld	xwa, (xiz+8)
	.byte 0xa6, 0x80
	ld	(xiz+4), xwa
	pop	xiz
	inc	4, xsp
	ret
	ldada	xde, 63872
	ld	(xwa), xde
	ldada	xbc, 65470
	sub	xbc, xde
	ld	xde, xbc
	add	xde, 76978
	ld	xbc, (xwa)
	ld	xhl, xde
	add	xhl, xbc
	ld	(xwa+4), xhl
	ld	(xwa+8), xde
	ret
	ldada	xde, 63872
	ld	(xwa), xde
	ldada	xbc, 65470
	sub	xbc, xde
	inc	2, xbc
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
	lda_24	xbc, 2020176
	ld	(xwa), xbc
	add	xbc, 76976
	ld	(xwa+4), xbc
	ld	xbc, 76976
	ld	(xwa+8), xbc
	ret
	lda_24	xbc, 1966080
	ld	(xwa), xbc
	ld	xbc, 29354
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+29354)
	ld	(xwa+4), xbc
	ret
	lda_24	xbc, 1966080
	ld	(xwa), xbc
	ld	xbc, 16
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+16)
	ld	(xwa+4), xbc
	ret
	lda_24	xbc, 1966080
	add	xbc, 16
	ld	(xwa), xbc
	ld	xbc, 29338
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+29338)
	ld	(xwa+4), xbc
	ret
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, 608256
	ld	(xiz), xwa
	add	xwa, 92160
	ld	(xiz+4), xwa
	ld	xwa, 92160
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	decf
	calr	455
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
	pop	xiz
	ret
	lda_24	xde, 608256
	ld	(xwa), xde
	lda_24	xbc, 608352
	sub	xbc, xde
	add	xde, xbc
	ld	(xwa+4), xde
	ld	(xwa+8), xbc
	ret
	lda_24	xde, 608352
	ld	(xwa), xde
	lda_24	xbc, 613312
	sub	xbc, xde
	add	xde, xbc
	ld	(xwa+4), xde
	ld	(xwa+8), xbc
	ret
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, 613312
	ld	(xiz), xwa
	add	xwa, 87104
	ld	(xiz+4), xwa
	ld	xwa, 87104
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	ldb	h, 30
	jr	ge, 1
	lda_24	xde, 608352
	lda_24	xbc, 613312
	sub	xbc, xde
	lda_24	xix, 608256
	sub	xde, xix
	add	xde, xbc
	ld	xbc, (xiz)
	add	xbc, xhl
	sub	xbc, xde
	ld	(xiz+4), xbc
	sub	xhl, xde
	ld	(xiz+8), xhl
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ldada	xwa, 61824
	ld	(xiz), xwa
	add	xwa, 339968
	ld	(xiz+4), xwa
	ld	xwa, 339968
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	.byte 0x17
	calr	312
	.byte 0xf3, 0xed
	nop
	pop	xwa
	ldw	wa, 32934
	ld	(xiz+4), xwa
	ld	xwa, 22528
	add	xwa, xhl
	ld	(xiz+8), xwa
	pop	xiz
	ret
	ldada	xbc, 61824
	ld	(xwa), xbc
	.byte 0xf3, 0xe5
	nop
	ldio	49, 184
	.byte 0x04
	jr	lt, 65
	nop
	ldio	0, 0
	ld	(xwa+8), xbc
	ret
	lda_24	xbc, 700416
	ld	(xwa), xbc
	.byte 0xf3, 0xe5
	nop
	.byte 0x50
	ldw	bc, 1208
	jr	lt, 65
	nop
	.byte 0x50
	nop
	nop
	ld	(xwa+8), xbc
	ret
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, 720896
	ld	(xiz), xwa
	add	xwa, 317440
	ld	(xiz+4), xwa
	ld	xwa, 317440
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	decf
	calr	207
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
	pop	xiz
	ret
	ret
	ret
	ret
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, 2000896
	ld	(xiz), xwa
	.byte 0xf3, 0xe1
	nop
	push	xix
	ldw	wa, 1214
	jr	f, 64
	nop
	push	xix
	nop
	nop
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	decf
	calr	179
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
	pop	xiz
	ret
	lda_24	xde, 2000896
	ld	(xwa), xde
	lda_24	xbc, 2000928
	sub	xbc, xde
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
	lda_24	xde, 2000928
	ld	(xwa), xde
	lda_24	xbc, 2001664
	sub	xbc, xde
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
	push	xiz
	ld	xiz, xwa
	lda_24	xwa, 2001664
	ld	(xiz), xwa
	lda	xwa, (xwa+14592)
	ld	(xiz+4), xwa
	ld	xwa, 14592
	ld	(xiz+8), xwa
	.byte 0xf1
	push_f
	ld	(xiy-50), xiz
	ldb	h, 30
	.byte 0x52
	nop
	lda_24	xde, 2000928
	lda_24	xbc, 2001664
	sub	xbc, xde
	lda_24	xix, 2000896
	sub	xde, xix
	add	xde, xbc
	ld	xbc, (xiz)
	add	xbc, xhl
	sub	xbc, xde
	ld	(xiz+4), xbc
	sub	xhl, xde
	ld	(xiz+8), xhl
	pop	xiz
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16116079
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld16_24	hl, 608302
	extz	xhl
	sll	xhl, 4
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqStep_ByteBlockEA5F
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldda16	hl, 61902
	extz	xhl
	sll	xhl, 4
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16183459
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld16_24	hl, 2000924
	extz	xhl
	sll	xhl, 4
	ret

MidiChan_CheckFlags:
	ei 6
	ldda8 a, 1063
	and a, 0x2c
	jr z, MidiChan_EnableAndReturn
	call SeqBuf2_InitWithInterrupts
	ldda32 xwa, 48300
	lds bc, 4
	lds de, 4
	calr MIDI_ReadChannelParam
	anddi8 1063, 211

MidiChan_EnableAndReturn:
	ei 0
	ret

MidiChan_CheckTimeout:
	ldw de, 0x9c4
	bitda 2, 48408
	jr z, MidiChan_ApplyTimeout
	ldw de, 0x3e8

MidiChan_ApplyTimeout:
	ldda16 xbc, 1033
	sub bc, wa
	cp bc, de
	ret le
	ldda32 xwa, 48300
	lds bc, 4
	lds de, 5
	calr MIDI_ReadChannelParam
	ret

MidiChan_TimerDispatch_Data:	.ascii ":;<>"
	call	ToneGen_DSPCfg_Initialize
	call	SndParam_SyncDisplayBitmap
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	ldda16	de, 1033
	ld	wa, de
	ldda16	bc, 1033
	sub	bc, wa
	cp	bc, 25
	jr	lt, -14
	ret

Part_LookupByIndex:
	ldda32 xbc, 37106
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

MIDI_PackNibbleParam:
	lda xbc, (xwa + 6)
	ld xwa, (xbc)
	st_dpib B, 0xe0
	ld (xbc), xwa
	ld l, (xde)
	sll l, 4
	st_dpib B, 0xe0
	ld (xbc), xwa
	ld a, (xde)
	and a, 0xf
	or l, a
	ret

MidiTG_WriteRegByDescriptor:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld a, (xiz)
	extz wa
	calr Part_LookupByIndex
	cp xhl, 0xffffffff
	jr z, MidiTG_WriteReg_NoEntry
	lda xde, (xiz + 2)
	lda xix, (xiz + 3)
	ld a, (xix)
	and (xde), a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xix)
	cpl a
	and_srib_mr A, 0x07, 0xec, 0xf4
	ld c, (xbc)
	extz bc
	ld a, (xde)
	or_srib_mr A, 0x07, 0xec, 0xe4
	jr MidiTG_WriteReg_Return

MidiTG_WriteReg_NoEntry:
	ldw (xsp + 4), 0xffff

MidiTG_WriteReg_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

AssSwb_ApplyBitDescriptor:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld a, (xiz)
	extz wa
	calr Part_LookupByIndex
	cp xhl, 0xffffffff
	jr z, AssSwb_NoEntry
	lda xde, (xiz + 2)
	lda xix, (xiz + 3)
	ld a, (xix)
	and (xde), a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xix)
	cpl a
	and_srib_mr A, 0x07, 0xec, 0xf4
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xde)
	or_srib_mr A, 0x07, 0xec, 0xf4
	ld a, (xiz)
	extz wa
	ld c, (xbc)
	extz bc
	ld_srib3 E, 0x07, 0xec, 0xe4
	extz de
	ld l, (xix)
	extz hl
	pushw hl
	call AssswbWr
	jr AssSwb_Return

AssSwb_NoEntry:
	ldw (xsp + 4), 0xffff

AssSwb_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

AssSwb_ProcessLoop_Data:
	dec	6, xsp
	push	xiz
	ld	xiz, xwa
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ld	a, (xiz)
	extz	wa
	calr	65291
	ld	(xsp+6), xhl
	ld	xbc, (xsp+6)
	cp	xbc, 4294967295
	jrl	z, 150
	lda	xix, (xiz+2)
	lda	xhl, (xiz+4)
	ld	wa, (xhl)
	and	(xix), wa
	lda	xde, (xiz+1)
	ld	a, (xde)
	.byte 0xc7, 0xf4, 0x99
	extz	iy
	ld	wa, (xhl)
	cpl	a
	.byte 0xc3
	reti
	.byte 0xe4, 0xf4
	add	b, a
	ldb	a, 199
	.byte 0xf4, 0x99
	extz	iy
	ld	wa, (xix)
	.byte 0xc3
	reti
	.byte 0xe4, 0xf4
	add	xde, xbc
	ldb	a, 216
	ccf
	ld	iy, wa
	inc	1, iy
	ld	wa, (xhl)
	srl	wa, 8
	cpl	a
	.byte 0xc3
	reti
	.byte 0xe4, 0xf4
	add	b, a
	ldb	a, 216
	ccf
	ld	iy, wa
	inc	1, iy
	ld	wa, (xix)
	srl	wa, 8
	ld	xix, (xsp+6)
	.byte 0xc3
	reti
	.byte 0xf0, 0xf4
	add	xiz, xbc
	ldb	a, 216
	ccf
	ld	c, (xde)
	extz	bc
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	ldb	e, 218
	ccf
	ld	hl, (xhl)
	extz	hl
	pushw	hl
	call	AssswbWr
	ld	a, (xiz)
	extz	wa
	ld	l, (xiz+1)
	ld	c, l
	inc	1, c
	extz	bc
	extz	hl
	inc	1, hl
	ld	xde, (xsp+6)
	.byte 0xc3
	reti
	sla	xwa, 37
	extz	de
	ld	hl, (xiz+4)
	srl	hl, 8
	extz	hl
	pushw	hl
	call	AssswbWr
	jr	5
	.byte 0xbf, 0x04
	push_sr
	swi	7
	swi	7
	ld	hl, (xsp+4)
	pop	xiz
	.byte 0xef
	jr	z, 0x0e

Part_LookupTableEntry:
	ldda32 xde, 37106
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	cp xwa, 0xffffffff
	jr z, Part_LookupReturnZero
	extz bc
	ld_srib3 L, 0x07, 0xe0, 0xe4
	ret

Part_LookupReturnZero:
	ldb l, 0x0
	ret

Part_ProcessEntry_Data:
	ld	xhl, xwa
	ld	wa, bc
	dec	1, bc
	cps	wa, 0
	ret	z
	.byte 0xc5, 0xec
	ldb	a, 245
	.byte 0xe8
	ld	xbc, 1775864025
	cps	wa, 0
	jr	nz, -14
	ret
	inc	1, xwa
	ldb	l, 0
	dec	1, bc
	ld	de, bc
	dec	1, bc
	cps	de, 0
	jr	z, 11
	.byte 0xc5, 0xe0
	xor	(xsp), a
	decm8	1, (xde-39)
	cps	de, 0
	jr	nz, -11
	neg	l
	res	7, l
	ret
	calr	63322
	ldda32	xwa, 48220
	calr	63647
	jp	ArpQueue_SwapBuffers
	ret
	ret
	ret

MidiChan_ClearAllStates:
	stdi8 48384, 0
	stdi8 48386, 0
	stdi8 48388, 0
	stdi8 48390, 0
	stdi8 48392, 0
	stdi8 48394, 0
	stdi8 48396, 0
	stdi8 48398, 0
	stdi8 48400, 0
	stdi8 48402, 0
	stdi8 48404, 0
	stdi8 48406, 0
	stdi8 48438, 0
	stdi8 48440, 0
	calr MidiChan_SetStateMode
	calr MidiChan_SetVoiceBaseState
	jrl MidiSeq_ApplyPendingParams

MidiChan_SetStateMode:
	bitda 6, 48408
	jr z, MidiChan_SetStateMode2
	stdi8 48438, 1
	ldb a, 0x1
	jr MidiChan_CompareAndFlag

MidiChan_SetStateMode2:
	stdi8 48438, 2
	ldda8 a, 48438

MidiChan_CompareAndFlag:
	cpda8 a, 48440
	ret z
	setda 6, 48412
	ldmm8 48440, 48438
	ret

MidiChan_SetVoiceBaseState:
	bitda 6, 48408
	jr z, MidiChan_SetBaseState128
	stdi8 48384, 128
	ret

MidiChan_SetBaseState128:
	stdi8 48396, 128
	ret

MidiSeq_UpdateAllParams:
	ldda32 xwa, 48300
	lds bc, 4
	call SeqData_ReadFieldByIndex
	cps l, 0
	ret nz
	calr MidiSeq_SyncToneStates_Upper
	calr MidiSeq_UpdateToneParam
	calr MidiSeq_UpdateVolumeScale
	calr MidiSeq_ComputeExpression
	calr MidiSeq_CheckSyncDirty
	calr MidiSeq_ApplyPendingParams
	call MainTitle_PrepareAndDispatch
	ret

MidiSeq_SyncToneStates_Upper:
	bitda 6, 48408
	jr z, MidiSeq_SyncToneStates_Lower
	resda 7, 48384
	ldmm8 48386, 48384
	resda 7, 48388
	ldmm8 48390, 48388
	resda 7, 48392
	ldmm8 48394, 48392
	ret

MidiSeq_SyncToneStates_Lower:
	resda 7, 48396
	ldmm8 48398, 48396
	resda 7, 48400
	ldmm8 48402, 48400
	resda 7, 48404
	ldmm8 48406, 48404
	ret

MidiSeq_UpdateToneParam:
	bitda 6, 48408
	jr z, MidiSeq_UpdateToneParam_Lower
	ldda32 xwa, 48308
	lds bc, 3
	call SeqData_ReadFieldByIndex
	extz hl
	lda_24 xbc, 0xee499e
	ld_srib3 C, 0x07, 0xe4, 0xec
	ld a, c
	stda8 48384, c
	cpda8 c, 48386
	ret z
	set 7, a
	stda8 48384, a
	ret

MidiSeq_UpdateToneParam_Lower:
	ldda32 xwa, 48300
	lds bc, 3
	call SeqData_ReadFieldByIndex
	extz hl
	lda_24 xbc, 0xee499e
	ld_srib3 C, 0x07, 0xe4, 0xec
	ld a, c
	stda8 48396, c
	cpda8 c, 48398
	ret z
	set 7, a
	stda8 48396, a
	ret

MidiSeq_UpdateVolumeScale:
	ldada xwa, 48412
	bitm 7, (xwa)
	ret nz
	bitda 6, 48408
	jr z, MidiSeq_VolScale_Lower
	ldada xbc, 48316
	ld xde, (xbc + 8)
	srl xde, 5
	ld (xbc + 12), xde
	stdi8 48388, 160
	jr MidiSeq_VolScale_SetActive

MidiSeq_VolScale_Lower:
	ldada xbc, 48348
	ld xde, (xbc + 8)
	srl xde, 5
	ld (xbc + 12), xde
	stdi8 48400, 160

MidiSeq_VolScale_SetActive:
	or xde, xde
	ret z
	setm 7, (xwa)
	ret

MidiSeq_ComputeExpression:
	bitda 6, 48408
	jr z, MidiSeq_Expression_Lower
	ldada xwa, 48316
	ld xde, (xwa + 8)
	ld xbc, (xwa + 12)
	or xde, xde
	ret z
	or xbc, xbc
	ret z
	ld xwa, xde
	call Math_DivideU32
	sub xhl, 0x20
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld a, l
	stda8 48392, l
	cpda8 l, 48394
	ret z
	set 7, a
	stda8 48392, a
	ret

MidiSeq_Expression_Lower:
	ldada xwa, 48348
	ld xde, (xwa + 8)
	ld xbc, (xwa + 12)
	or xde, xde
	ret z
	or xbc, xbc
	ret z
	ld xwa, xde
	call Math_DivideU32
	sub xhl, 0x20
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld a, l
	stda8 48404, l
	cpda8 l, 48406
	ret z
	set 7, a
	stda8 48404, a
	ret

MidiSeq_CheckSyncDirty:
	ldada xbc, 48412
	bitda 6, 48408
	jr z, MidiSeq_CheckSyncDirty_Lower
	ldda8 a, 48384
	cpda8 a, 48386
	jr nz, DSP_Init_ErrorFlagSet
	ldda8 a, 48388
	cpda8 a, 48390
	jr nz, DSP_Init_ErrorFlagSet
	ldda8 a, 48392
	cpda8 a, 48394
	jr nz, DSP_Init_ErrorFlagSet
	ret

MidiSeq_CheckSyncDirty_Lower:
	ldda8 a, 48396
	cpda8 a, 48398
	jr nz, DSP_Init_ErrorFlagSet
	ldda8 a, 48400
	cpda8 a, 48402
	jr nz, DSP_Init_ErrorFlagSet
	ldda8 a, 48404
	cpda8 a, 48406
	ret z

DSP_Init_ErrorFlagSet:
	setm 6, (xbc)
	ret

MidiSeq_PartLookup_Data:
	lds	wa, 0
	call	ParaLoadOpt_PostDualEvent
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cp	l, 34
	jr	z, 9
	cps	l, 0
	jr	nz, 10
	calr	21
	jr	8
	calr	28
	jr	3
	calr	24
	.byte 0xf1
	push_f
	.byte 0xbd
	sbc	w, a
	.byte 0xf6
	call	SeqStep_PlaybackNop
	ret
	stdi8	32578, 35
	ldw	wa, 238
	jp	SoundCtrl_SendCommand
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	extz	hl
	lda_24	xbc, 15616436
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	pop_f
	ld	xde, 15609983
	jp	SoundCtrl_SendCommand

MidiSeq_ApplyPendingParams:
	bitda 6, 48412
	ret z
	bitda 6, 48408
	jr z, MidiSeq_ApplyParams_Lower
	ldda8 a, 48384
	res 7, a
	extz wa
	ldda8 c, 48388
	res 7, c
	extz bc
	ldda8 e, 48392
	res 7, e
	extz de
	call ParaLoadOpt_AudioFlagCheck
	jr MidiSeq_ClearSyncFlag

MidiSeq_ApplyParams_Lower:
	ldda8 a, 48396
	res 7, a
	extz wa
	ldda8 c, 48400
	res 7, c
	extz bc
	ldda8 e, 48404
	res 7, e
	extz de
	call ParaLoadOpt_AudioFlagCheck_B

MidiSeq_ClearSyncFlag:
	resda 6, 48412
	ret

MidiSeq_PartConfigure_Data:
	ret
	ldw	wa, 238
	jp	SoundCtrl_SendCommand
	.byte 0xf1
	push_f
	ld	(xiy-69), w
	ld	(xix-68), 0
	call	16608617
	calr	230
	.byte 0xf1
	push_f
	.byte 0xbd, 0xb3
	ret
	ld	xwa, 48316
	call	16608880
	jrl	467
	ld	xwa, 48316
	call	16609047
	jrl	642
	ld	xwa, 48316
	call	16608798
	jrl	317
	ld	xwa, 48316
	call	16608715
	jrl	192
	ret
	ld	xwa, 48316
	call	16609202
	jrl	796

MidiPkt_ArpMultiPass:
	push_werp 0xfa
	resda 7, 48408
	ldi_berp 0xfb, 0

MidiPkt_ArpPassLoop:
	ld xwa, 0xee35bc
	lds bc, 7
	call SeqBuf_FlushNoteOffs
	setda 2, 48408
	call SeqAlt_ProcessAndFinalize
	ldda32 xwa, 48300
	lds bc, 0
	call SeqData_ReadFieldByIndex
	cp l, 0x8
	jr z, MidiPkt_ArpPassDone
	inc1_berp 0xfb
	cpi_berp 0xfb, 3
	jr c, MidiPkt_ArpPassLoop

MidiPkt_ArpPassDone:
	ldda32 xwa, 48300
	cpi_berp 0xfb, 3
	jr nz, MidiPkt_ArpStoreFieldValues
	lds bc, 4
	lds de, 0
	call MIDI_ReadChannelParam
	jr MidiPkt_ArpPopReturn

MidiPkt_ArpStoreFieldValues:
	lds bc, 6
	call SeqData_ReadFieldByIndex
	stda8 48228, l
	ldda32 xwa, 48300
	lds bc, 7
	call SeqData_ReadFieldByIndex
	stda8 48229, l
	ldda32 xwa, 48300
	ldw bc, 0x8
	call SeqData_ReadFieldByIndex
	stda8 48230, l
	ldi_berp 0xfb, 0

MidiPkt_ArpSecondLoop:
	ld xwa, 0xee35c4
	lds bc, 7
	call SeqBuf_FlushNoteOffs
	setda 2, 48408
	call SeqAlt_ProcessAndFinalize
	ldda32 xwa, 48300
	lds bc, 0
	call SeqData_ReadFieldByIndex
	cps l, 1
	jr nz, MidiPkt_ArpSecondLoopNext
	setda 7, 48408
	jr MidiPkt_ArpPopReturn

MidiPkt_ArpSecondLoopNext:
	inc1_berp 0xfb
	cpi_berp 0xfb, 3
	jr c, MidiPkt_ArpSecondLoop

MidiPkt_ArpPopReturn:
	pop_werp 0xfa
	ret

MidiPkt_ArpConfigChain_Data:
	calr	12
	calr	122
	calr	623
	calr	242
	jrl	426
	calr	6
	calr	55
	jrl	783
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	lds	de, 1
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608748
	ld	xwa, 15611362
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	lds	de, 2
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608773
	ld	xwa, 15611374
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	lds	wa, 1
	call	AccWrap_ReturnZero
	cp	hl, 65535
	ret	z
	calr	7
	calr	56
	calr	658
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	lds	de, 4
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608824
	ld	xwa, 15611386
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	lds	de, 5
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608848
	ld	xwa, 15611398
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	lds	wa, 3
	call	AccWrap_ReturnZero
	cp	hl, 65535
	ret	z
	calr	10
	calr	59
	calr	109
	calr	529
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	lds	de, 7
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608928
	ld	xwa, 15611410
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608951
	ld	xwa, 15611422
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16608974
	ld	xwa, 15611434
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
	lds	wa, 4
	call	AccWrap_ReturnZero
	cp	hl, 65535
	ret	z
	calr	10
	calr	60
	calr	110
	calr	342
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 11
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609104
	ld	xwa, 15611444
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609127
	ld	xwa, 15611456
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 13
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609151
	ld	xwa, 15611468
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
	ret
	ret
	ret
	calr	9
	calr	59
	calr	109
	jrl	163
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 18
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609249
	ld	xwa, 15611478
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609274
	ld	xwa, 15611490
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	lds	bc, 3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	ld	xwa, 48332
	call	16609299
	ld	xwa, 15611502
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48308
	incm8	1, (xwa+3)
	ld	xwa, 15611296
	lds	bc, 5
	call	SeqBuf_FlushNoteOffs
	call	MidiStream_PrevBankCheck
	ret
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 39
	ld	xwa, 15611302
	lds	bc, 5
	call	SeqBuf_FlushNoteOffs
	call	MidiStream_PrevBankCheck
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cp	l, 24
	ret	nz
	ld	xwa, 15611308
	lds	bc, 5
	jr	22
	ldda32	xwa, 48300
	lds	bc, 4
	call	SeqData_ReadFieldByIndex
	cp	l, 24
	ret	nz
	ld	xwa, 15611308
	lds	bc, 5
	call	SeqBuf_FlushNoteOffs
	ret
MidiPkt_ArpChordHandler:
	; --- Main: guard check, loop with bit 4 flag, multiple calls (76 bytes) ---
	cpdi8	36150, 87
	jr nz, ArpChord_ClearBitAndReturn
	ldda32	xwa, 48300
	lds	bc, 0
	call SeqData_ReadFieldByIndex
	cps	l, 7
	jr c, ArpChord_ClearBitAndReturn
	setda	4, 48408
	call MidiChan_ClearAllStates
	jr t, ArpChord_DispatchAndLoop
ArpChord_CheckPlaybackDone:
	ldda32	xwa, 48300
	lds	bc, 4
	call SeqData_ReadFieldByIndex
	cps	l, 0
	jr z, ArpChord_ProcessAndDispatch
	resda	4, 48408
	jr t, ArpChord_FinalizePass
ArpChord_ProcessAndDispatch:
	call SeqAlt_ProcessAndFinalize
ArpChord_DispatchAndLoop:
	calr MidiTable_DispatchHelper
	bitda	4, 48408
	jr nz, ArpChord_CheckPlaybackDone
ArpChord_FinalizePass:
	calr	1913
	call MidiSeq_PartLookup_Data
ArpChord_ClearBitAndReturn:
	resda	4, 48408
	ret
; MIDI table dispatch helper
MidiTable_DispatchHelper:
	; --- Helper 1: table dispatch via (XBC+WA) with guard checks (58 bytes) ---
	ldda32	xwa, 48300
	lds	bc, 4
	call SeqData_ReadFieldByIndex
	cps	l, 0
	ret nz
	call MidiSeq_PartConfigure_Data
	ldda32	xwa, 48300
	cp (xwa), 0x27
	ret nc
	ld a, (xwa)
	extz wa
	sla	wa, 2
	lda_24 xbc, SeqChan_CommandDispatch_Table
	ld_rrl	xhl, xbc, wa
	call	(xhl)
	calr MidiTable_FlushArpNotes
	call MidiSeq_UpdateAllParams
	call 0xfd7316
	ret
MidiTable_FlushArpNotes:
	; --- Helper 2: conditional A-based 3-way pointer selection (56 bytes) ---
	bitda	7, 48408
	ret z
	call ArpQueue_SwapBuffers
	ldda32	xwa, 48300
	ld a, (xwa+4)
	cps	a, 0
	jr nz, MidiTable_CheckSpecialSlot
	ld xwa, 0x00ee3594
	lds	bc, 5
	jr t, MidiTable_CallFlush
MidiTable_CheckSpecialSlot:
	cp a, 0x16
	jr nz, MidiTable_UseDefaultBuf
	ld xwa, 0x00ee35b2
	lds	bc, 5
	jr t, MidiTable_CallFlush
MidiTable_UseDefaultBuf:
	ld xwa, 0x00ee359a
	lds	bc, 5
MidiTable_CallFlush:
	call SeqBuf_FlushNoteOffs
	ret


MidiPkt_InitSingleField_Data:
	.byte 0xc1
	ldb	w, 189
	push	xsp
	nop
	ret	nz
	stdi8	48416, 1
	ld	xwa, 15611332
	lds	bc, 7
	call	SeqBuf_FlushNoteOffs
	ret
MidiPkt_HandleCmdCode01:
	; --- Two-path: 3x field extraction or single store (73 bytes) ---
	cpdi8	48416, 1
	jr nz, MidiPkt_SetSlot18
	ldda32	xwa, 48300
	lds	bc, 6
	call SeqData_ReadFieldByIndex
	stda8	48232, l
	ldda32	xwa, 48300
	lds	bc, 7
	call SeqData_ReadFieldByIndex
	stda8	48233, l
	ldda32	xwa, 48300
	ldw bc, 0x0008
	call SeqData_ReadFieldByIndex
	stda8	48234, l
	setda	7, 48408
	stdi8	48416, 2
	ret
MidiPkt_SetSlot18:
	ldda32	xwa, 48300
	ld (xwa+4), 0x18
	resda	4, 48408
	ret


MidiPkt_ArpExtHandler_A:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 25
	call	MidiChan_TimerDispatch_Data
	ld	xwa, 48348
	call	16608715
	ld	xwa, 48364
	call	16608748
	jrl	591
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_B_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 2
	jr	nz, 12
	ld	xwa, 48364
	call	16608773
	jrl	596
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_C_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 21
	ld	xwa, 48348
	call	16608798
	ld	xwa, 48364
	call	16608824
	jrl	592
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 26
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_D_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 5
	jr	nz, 12
	ld	xwa, 48364
	call	16608848
	jrl	597
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_E_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 25
	call	16614114
	ld	xwa, 48348
	call	16608880
	ld	xwa, 48364
	call	16608928
	jrl	593
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_F_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 8
	jr	nz, 12
	ld	xwa, 48364
	call	16608951
	jrl	598
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_G:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 9
	jr	nz, 16
	ld	xwa, 48364
	call	16608974
	call	16608533
	jrl	600
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_H_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 25
	call	16614164
	ld	xwa, 48348
	call	16609202
	ld	xwa, 48364
	call	16609249
	jrl	594
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_I_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 19
	jr	nz, 12
	ld	xwa, 48364
	call	16609274
	jrl	600
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_J:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 20
	jr	nz, 16
	ld	xwa, 48364
	call	16609299
	call	16608533
	jrl	602
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_K:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	jr	nz, 21
	ld	xwa, 48348
	call	16609047
	ld	xwa, 48364
	call	16609104
	jrl	600
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_L:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 12
	jr	nz, 12
	ld	xwa, 48364
	call	16609127
	jrl	617
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_M_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 13
	jr	nz, 16
	ld	xwa, 48364
	call	16609151
	call	16608533
	jrl	630
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_RetStub_A:
	ret
MidiPkt_RetStub_B:
	ret
MidiPkt_ArpExtHandler_N_Data:
	ldda32	xwa, 48304
	lds	bc, 3
	call	SeqData_ReadFieldByIndex
	cp	l, 22
	ret	nc
	extz	hl
	sla	hl, 2
	lda_24	xbc, 15609352
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	c, 179
	.byte 0xe8
	ret
SeqChan_ProcessStepCmd:
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 19
	jp	MIDI_ReadChannelParam
SeqChan_StepCmd_Field1to2:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 1
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 2
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field2to3:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 2
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 3
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field4to5:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 4
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 5
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field5to6:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 5
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	call	16713580
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 6
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field6_Data:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 7
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field8to9:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field9to10:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 10
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field10_Data:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 18
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field13_Data:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field20to21:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ldda32	xwa, 48300
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 21
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field11_Data:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 11
	call	MIDI_ReadChannelParam
	lds	wa, 4
	call	AccWrap_ReturnZero
	cp	hl, 65535
	.byte 0xf2
	cp	(xiy+108), e
	or	xbc, xiz
	ld	xwa, (xix-68)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field12_Data:
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	lds	wa, 4
	call	AccWrap_ReturnZero
	cp	hl, 65535
	.byte 0xf2
	cp	(xiy+108), e
	or	xbc, xiz
	ld	xwa, (xix-68)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cps	l, 0
	ret	nz
	ldda32	xwa, 48300
	lds	bc, 3
	ldw	de, 13
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field13Write:
	; --- Section 1: load XWA, setup BC/DE, call, then compare HL ---
	ldda32	xwa, 48300
	lds	bc, 3
	ldw de, 0x000d
	call MIDI_ReadChannelParam
	lds	wa, 4
	call AccWrap_ReturnZero
	cp hl, 0xffff
	.byte 0xf2
	cp	(xiy+108), e
	.byte 0xee
	; --- Section 2: reload XWA, setup BC, call, check L ---
	ldda32	xwa, 48300
	ldw bc, 0x000f
	call SeqData_ReadFieldByIndex
	cps	l, 0
	ret nz
	; --- Section 3: reload XWA, setup BC/DE, call ---
	ldda32	xwa, 48300
	lds	bc, 3
	ldw de, 0x000e
	call MIDI_ReadChannelParam
	ret


SeqChan_RetStub_A:
	ret
SeqChan_RetStub_B:
	ret
SeqChan_DispatchByType_Data:
	ldda32	xwa, 48304
	ld	a, (xwa+3)
	cp	a, 22
	ret	nc
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15609440
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 179
	cp	xbc, xwa
	.byte 0x1c, 0xbd, 0xb7
	ret
SeqChan_DefaultHandler:
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 31
	jp	MIDI_ReadChannelParam
SeqChan_WriteField_Data_A:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	.byte 0xf1, 0x1a, 0xbd, 0xbf
	ret
SeqChan_WriteField_Data_B:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	.byte 0xf1, 0x1a, 0xbd, 0xbe
	ret
SeqChan_WriteField_Data_C:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	.byte 0xf1, 0x1a, 0xbd, 0xbd
	ret
SeqChan_WriteField_Data_D:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	.byte 0xf1, 0x1a, 0xbd, 0xbc
	ret
SeqChan_RetStub_C:
	ret
SeqChan_WriteField_Data_E:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	.byte 0xf1, 0x1a, 0xbd, 0xba
	ret
; MIDI SysEx processing block with dispatch
MidiSysEx_ProcessBlock:
	ldda32	xwa, 48300
	lds	bc, 3
	lds	de, 0
	call	MIDI_ReadChannelParam
	resda	4, 48408
	calr	111
	calr	161
	calr	187
	calr	211
	calr	243
	jrl	241
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_DSPCfg_Initialize
	call	ToneGen_Config_InitAndChannels
	call	ToneGen_InitAllChannelEntries_Skip
	call	ToneGen_DispatchByMode
	lds	wa, 3
	call	BitMapOut_GetRenderMode_CheckBit3
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SoundParam_NotifyMultipleChanges
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	call	SwbtWr_CallProcessAll
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	resda	0, 4330
	lds	wa, 3
	call	BitMapOut_GetRenderMode_Return
	setda	4, 37113
	call	SeqTimer_UpdateTempoReg
	resda	4, 37113
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	bitda	7, 48410
	ret	z
	calr	-105
	calr	17
	calr	-80
	calr	11
	calr	-73
	calr	5
	resda	7, 48410
	ret
	bitda	4, 48410
	ret	z
	setda	0, 4330
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MIDI_PitchBendData_Block
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	dec	6, xsp
	ld	xiy, 15609528
	ld	xix, xsp
	lds	bc, 3
	ldirw
	bitda	6, 48410
	jr	z, 7
	calr	-35
	resda	6, 48410
	inc	6, xsp
	ret
	bitda	5, 48410
	ret	z
	resda	0, 13043
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccPatch_MultiCallWrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	resda	5, 48410
	ret
	bitda	4, 48410
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16534756
	call	ToneGen_InitAllChannelEntries_Skip
	call	16050861
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	setda	1, 48408
	resda	4, 48410
	ret
	ret
	bitda	2, 48410
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Voice_InitBankDataSafe_Alt1
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	resda	2, 48410
	ret
	ret
	ret
	ret
	ret
	ldda32	xwa, 48300
	cp	(xwa+4), 0
	ret	z
	calr	11
	ret
	ldda32	xwa, 48300
	ld	(xwa+4), 23
	jr	0
	ldda32	xwa, 48304
	ld	a, (xwa+3)
	cp	a, 22
	ret	nc
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15609534
	ld_rrl	xhl, xbc, wa
	call	(xhl)
	ret
	ret
	jp	16614065
	jp	16614097
	jp	16614131
	jp	16614148
	ret
	jp	16614177
	setda	4, 37113
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld32_24	xhl, 15577836
	call	(xhl)
	call	MidiMsg_ParseChannelStream
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	resda	4, 37113
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SendPartDataBlock_DoGetError
	call	MIDI_PitchBendData_Block
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccDemo_InitWithFlag
	resda	0, 13043
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccDemo_InitDone
	resda	0, 13043
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld32_24	xhl, 14960190
	call	(xhl)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16183466
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Voice_InitBankDataSafe
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret

SeqAlt_CheckInitBuffer:
	cpdi8 36150, 87
	ret nz
	ei 6
	call SeqMain_InitBuffer
	ei 0
	ret

SeqBuf2_InitWithInterrupts:
	ei 6
	call SeqBuf2_Init
	ei 0
	ret

SeqBuf_Timing_Data:
	ei	6
	call	SeqBuf_MidiOut_Init
	di
	ret

MidiChan_ClearStorageFields:
	ldada xwa, 48232
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	ld (xwa + 2), 0xff
	ldada xwa, 48228
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	ld (xwa + 2), 0xff
	ret

MidiChan_InitAllBufferPtrs:
	ldada xwa, 47092
	stda32 48212, xwa
	ldada xbc, 48236
	stda32 48300, xbc
	ldada xde, 47372
	stda32 48216, xde
	ldada xde, 48252
	stda32 48304, xde
	ldada xde, 47652
	stda32 48220, xde
	ldada xde, 48268
	stda32 48308, xde
	ldada xde, 47932
	stda32 48224, xde
	ldada xde, 48284
	stda32 48312, xde
	calr ArpQueue_InitBuffer
	ldda32 xwa, 48216
	ldda32 xbc, 48304
	calr ArpQueue_InitBuffer
	ldda32 xwa, 48220
	ldda32 xbc, 48308
	calr ArpQueue_InitBuffer
	ldda32 xwa, 48224
	ldda32 xbc, 48312
	jr ArpQueue_InitBuffer

ArpQueue_InitBuffer:
	ld xde, xbc
	ldw (xwa), 0x0
	lda xbc, (xwa + 14)
	ld (xwa + 2), xbc
	ld (xwa + 6), xbc
	ld (xwa + 10), xbc
	ld (xbc), 0xff
	ld xiy, 0xee49d8
	ld xix, xde
	ldw bc, 0x8
	ldirw
	ret

MidiSeq_SwapActiveBuffers:
	ldda32 xbc, 48300
	cp (xbc + 4), 0x0
	jr nz, MidiSeq_SwapBuffersFallthru
	ldda32 xwa, 48212
	lda xde, (xwa + 14)
	cp xde, (xwa + 10)
	jr z, MidiSeq_SwapBuffersFallthru
	ldda32 xwa, 48304
	stda32 48304, xbc
	stda32 48300, xwa
	ldda32 xbc, 48216
	ldda32 xwa, 48212
	stda32 48216, xwa
	stda32 48212, xbc

MidiSeq_SwapBuffersFallthru:
	jr MidiSeq_ReinitCurrentBuffer

ArpQueue_SwapBuffers:
	ldda32 xbc, 48308
	cp (xbc + 4), 0x0
	jr nz, ArpQueue_SwapFallthru
	ldda32 xwa, 48220
	lda xde, (xwa + 14)
	cp xde, (xwa + 10)
	jr z, ArpQueue_SwapFallthru
	ldda32 xwa, 48312
	stda32 48312, xbc
	stda32 48308, xwa
	ldda32 xbc, 48224
	ldda32 xwa, 48220
	stda32 48224, xwa
	stda32 48220, xbc
	calr ArpQueue_ReinitCurrentBuffer
	ldda32 xbc, 48308
	ldda32 xwa, 48312
	ld a, (xwa + 3)
	ld (xbc + 3), a
	ret

ArpQueue_SwapFallthru:
	jr ArpQueue_ReinitCurrentBuffer

MidiSeq_ReinitCurrentBuffer:
	ldda32 xwa, 48212
	ldda32 xbc, 48300
	jrl ArpQueue_InitBuffer

ArpQueue_ReinitCurrentBuffer:
	ldda32 xwa, 48220
	ldda32 xbc, 48308
	jrl ArpQueue_InitBuffer

MidiChan_InitSoundRegisters:
	ld xiy, 0xee2f16
	ld xix, 0xbcbc
	ldw bc, 0x8
	ldirw
	ld xiy, 0xee2f16
	ld xix, 0xbccc
	ldw bc, 0x8
	ldirw
	ld xiy, 0xee2f16
	ld xix, 0xbcdc
	ldw bc, 0x8
	ldirw
	ld xiy, 0xee2f16
	ld xix, 0xbcec
	ldw bc, 0x8
	ldirw
	ret

SoundMode_ResetAllParams:
	calr MidiChan_InitAllBufferPtrs
	calr MidiChan_ClearStorageFields
	calr MidiChan_InitSoundRegisters
	stdi8 48408, 0
	stdi8 48410, 0
	stdi8 48412, 0
	stdi8 48414, 0
	stdi8 48416, 0
	stdi8 48380, 0
	stdi8 48384, 0
	ret

SoundMode_ResetJump:
	jr SoundMode_ResetAllParams

SoundMode_ResetJump2:
	jr SoundMode_ResetJump

SoundMode_RetStub_A:
	ret

SoundMode_RetStub_B:
	ret

SoundMode_RetStub_C:
	ret

SoundMode_RetStub_D:
	ret

SoundMode_ApplyVoiceParams:
	lds wa, 2
	ld xbc, 0xf980
	call SysEx_ApplyVoiceParam_49
	lds wa, 4
	ld xbc, 0xf980
	call SysEx_ApplyVoiceParam_4B
	ldada xbc, 37261
	ld xwa, xbc
	lda xbc, (xbc + 31)

SoundMode_VoiceIterLoop:
	stib_dpi 0xe0, 0x23
	cp xwa, xbc
	jr ule, SoundMode_VoiceIterLoop
	ret

SoundMode_RetStub_E:
	ret

SoundMode_RetStub_F:
	ret

SoundMode_RetStub_G:
	ret

SoundMode_RetStub_H:
	ret

SoundMode_SysExConfig_Data:
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	and	wa, 511
	ldada	xbc, 64602
	ld	l, a
	ld	(xbc+8), l
	lda	xde, (xbc+9)
	ld	c, (xde)
	res	0, c
	ld	(xde), c
	srl	wa, 8
	or	c, a
	ld	(xde), c
	stdi8	37159, 72
	stdi8	37160, 8
	stda8	37161, l
	stdi8	37162, 255
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_WriteParamBlock
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xf1
	swi	1
	.byte 0x90, 0xbc
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb4
	ret

SoundMode_DispatchRender:
	dec 2, xsp
	ld (xsp), a
	setda 0, 47086
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	cp (xsp), 0x2
	jr z, SoundMode_DispatchRender_2
	cp (xsp), 0x1
	jr z, SoundMode_DispatchRender_1
	calr SoundMode_RenderWithNotify
	jr SoundMode_PostRender

SoundMode_DispatchRender_1:
	calr SoundMode_FullRenderUpdate
	jr SoundMode_PostRender

SoundMode_DispatchRender_2:
	calr SoundMode_AlternateRender

SoundMode_PostRender:
	call BitMapOut_ComputeRegionDelta
	lda_24 xde, 0x03c8e4
	ldada xbc, 63904
	ld xhl, xbc
	ldada xwa, 65470
	sub xwa, xbc
	inc 2, xwa
	ld xbc, xwa
	srl xbc, 1
	ld xwa, xbc
	dec 1, xbc
	or xwa, xwa
	jr z, SoundMode_CopyBitmapDone

SoundMode_CopyBitmapLoop:
	ld_spiw WA, 0xe9
	st_dpiw WA, 0xed
	ld xwa, xbc
	dec 1, xbc
	or xwa, xwa
	jr nz, SoundMode_CopyBitmapLoop

SoundMode_CopyBitmapDone:
	resda 0, 47086
	inc 2, xsp
	ret

SoundMode_FullRenderUpdate:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_RetStub_D
	calr TGReg_WriteCC0_Volume
	calr SoundMode_RetStub_G
	calr TGReg_WriteCC3_Expression
	calr TGReg_WriteCC4_Pan
	calr TGReg_WriteCC5_Modulation
	calr TGReg_WriteCC4_Sustain
	calr TGReg_WriteCC6_RetStub
	calr TGReg_WriteCC7_Reverb
	calr TGReg_WriteCC8_Chorus
	calr TGReg_WriteCC9_Variation
	calr TGReg_WriteCC10_KeyShift
	calr TGReg_WriteCC11_PartMode
	calr SoundMode_SetReverbType
	calr VoiceData_ZeroFillAll
	calr SoundParam_ApplyBit15Toggle
	calr TGReg_WriteCC12_Assign
	calr SoundMode_ApplyVoiceParams
	jrl VoiceData_SyncAllToHardware

SoundMode_RenderWithNotify:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	ldda8 a, 36150
	cp a, 0x76
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x72
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x73
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x6f
	jr nz, SoundMode_RenderPopRegs

SoundMode_NotifyActiveVoices:
	ld xwa, 0x2201
	lds bc, 1
	lds de, 0
	call SoundParam_NotifyChange
	ld xwa, 0x2205
	lds bc, 1
	lds de, 0
	call SoundParam_NotifyChange

SoundMode_RenderPopRegs:
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_SetChorusType
	calr SoundMode_RetStub_H
	calr SoundParam_Bit15Jump
	jrl VoiceData_SyncAllToHardware

SoundMode_AlternateRender:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_RetStub_D
	calr TGReg_WriteCC0_AltMask
	calr SoundMode_RetStub_H
	calr TGReg_WriteCC3_Expression
	calr TGReg_WriteCC4_Pan
	calr TGReg_WriteCC5_Modulation
	calr TGReg_WriteCC4_Sustain
	calr TGReg_WriteCC6_RetStub
	calr TGReg_WriteCC7_Reverb
	calr TGReg_WriteCC8_Chorus
	calr TGReg_WriteCC9_Variation
	calr TGReg_WriteCC10_KeyShift
	calr TGReg_WriteCC11_PartMode
	calr VoiceData_ZeroFillAll
	calr SoundParam_ApplyBit15Toggle
	calr SoundMode_ApplyVoiceParams
	jrl VoiceData_SyncAllToHardware
MidiCtrl_ModeSwitchHandler:
	cpdi8 49277, 3
	ret nz
	ldda8 a, 49279
	bit 2, a
	jr z, MidiCtrl_CheckAltCommand
	ldda8 a, 47086
	bit 0, a
	ret nz
	set 0, a
	stda8 47086, a
	ldda16 xwa, 4597
	bit 15, wa
	jr nz, MidiCtrl_ApplyModeSwitch
	push xde
	push xhl
	push xix
	push xiz
	call AccWrap_PlayModeDispatch
	call AccompSeq_StopSequence
	pop xiz
	pop xix
	pop xhl
	pop xde

MidiCtrl_ApplyModeSwitch:
	ldda8 a, 49278
	extz wa
	calr MidiCtrl_Bit2ToChannel
	ldda8 a, 49278
	extz wa
	calr MidiCtrl_SendControlPacket
	calr MidiCtrl_FullReconfigure
	resda 0, 47086
	ret

MidiCtrl_CheckAltCommand:
	cpdi8 49278, 4
	ret nz
	cps a, 0
	ret nz
	calr SwbtWr_InitAndWriteAllBlocks
	ret

MidiCtrl_FullReconfigure:
	push_werp 0xfa
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_DSPCfg_Initialize
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldda8 a, 64607
	ldfr_berp A, 0xfb
	bitda 2, 49278
	jr z, MidiCtrl_RenderAndProcess
	calr SoundMode_RetStub_E
	calr SoundMode_FullRenderUpdate
	bitda 0, 4330
	jr nz, SoundMode_ProcessToneAndParams
	ldda8 a, 36150
	cp a, 0x76
	jr ugt, MidiCtrl_DeltaAndProcess
	cp a, 0x6c
	jr nc, SoundMode_ProcessToneAndParams

MidiCtrl_DeltaAndProcess:
	call BitMapOut_ComputeRegionDelta
	jr SoundMode_ProcessToneAndParams

MidiCtrl_RenderAndProcess:
	calr SoundMode_RenderWithNotify
	calr SoundMode_RetStub_F

SoundMode_ProcessToneAndParams:
	calr TGReg_ClearTerminator
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_DSPCfg_Initialize
	call ToneGen_Config_InitAllEntries
	call Voice_InitAllChannelEntries
	call ToneGen_DispatchByMode
	lds wa, 3
	call BitMapOut_GetRenderMode_CheckBit3
	call SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call SwbtWr_CallProcessAll
	lds wa, 3
	call BitMapOut_GetRenderMode_Return
	setda 4, 37113
	call SeqTimer_UpdateTempoReg
	resda 4, 37113
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SwbtWr_InitAndWrite_CC_B1
	calr SwbtWr_WriteLoop_CC_B1_Ret
	calr SwbtWr_InitAndWrite_CC_B2
	calr SwbtWr_InitAndWriteAllBlocks
	calr SwbtWr_StubRet_A
	calr SwbtWr_StubRet_B
	calr SwbtWr_StubRet_C
	calr SwbtWr_WriteBankSelect
	calr MidiBuf_CalcFillRange
	ldada xde, 64607
	ld c, (xde)
	res 0, c
	ld (xde), c
	ldto_berp A, 0xfb
	and a, 0x1
	or c, a
	ld (xde), c
	pop_werp 0xfa
	ret

TGReg_ClearTerminator:
	ldada xwa, 63926
	sub xwa, 0xf9b4
	lda_24 xbc, 0x03c8e4
	add xwa, xbc
	ld (xwa), 0xff
	ret

TGReg_WriteCC0_Volume:
	dec 4, xsp
	ld (xsp + 256), 0x0
	jr TGReg_WriteCC0_Check

TGReg_WriteCC0_Body:
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC0_Check:
	lda xwa, (xsp)
	lda xbc, (xwa + 1)
	lda xde, (xwa + 2)
	lda xhl, (xwa + 3)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC0_Body
	ld (xwa), 0xf
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa), 0xf
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x78
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	inc 4, xsp
	ret

TGReg_WriteCC0_AltMask:
	dec 4, xsp
	ld (xsp + 256), 0x0
	jr TGReg_WriteCC0_AltCheck

TGReg_WriteCC0_AltBody:
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC0_AltCheck:
	lda xwa, (xsp)
	lda xbc, (xwa + 1)
	lda xde, (xwa + 2)
	lda xhl, (xwa + 3)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC0_AltBody
	ld (xwa), 0xf
	ld (xbc), 0x0
	ld (xde), 0xf0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa), 0xf
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	inc 4, xsp
	ret

TGReg_WriteCC3_Expression:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x3
	ld (xwa + 2), 0x64
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC3_Check

TGReg_WriteCC3_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC3_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC3_Body
	inc 4, xsp
	ret

TGReg_WriteCC4_Pan:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x4
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x8
	ld (xwa), 0x0
	jr TGReg_WriteCC4_Check

TGReg_WriteCC4_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC4_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC4_Body
	inc 4, xsp
	ret

TGReg_WriteCC5_Modulation:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x5
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC5_Check

TGReg_WriteCC5_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC5_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC5_Body
	inc 4, xsp
	ret

TGReg_WriteCC4_Sustain:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x4
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x40
	ld (xwa), 0x0
	jr TGReg_WriteCC4_SustainCheck

TGReg_WriteCC4_SustainBody:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC4_SustainCheck:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC4_SustainBody
	inc 4, xsp
	ret

TGReg_WriteCC6_RetStub:
	ret

TGReg_WriteCC7_Reverb:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x7
	ld (xwa + 2), 0x28
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC7_Check

TGReg_WriteCC7_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC7_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC7_Body
	inc 4, xsp
	ret

TGReg_WriteCC8_Chorus:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x8
	ld (xwa + 2), 0x40
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC8_Check

TGReg_WriteCC8_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC8_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC8_Body
	inc 4, xsp
	ret

TGReg_WriteCC9_Variation:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x9
	ld (xwa + 2), 0x40
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC9_Check

TGReg_WriteCC9_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC9_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC9_Body
	inc 4, xsp
	ret

TGReg_WriteCC10_KeyShift:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0xa
	ld (xwa + 2), 0x80
	ld (xwa + 3), 0xff
	ld (xwa), 0x0
	jr TGReg_WriteCC10_Check

TGReg_WriteCC10_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC10_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC10_Body
	inc 4, xsp
	ret

TGReg_WriteCC11_PartMode:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0xb
	ld (xwa + 2), 0x2
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC11_Check

TGReg_WriteCC11_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC11_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC11_Body
	inc 4, xsp
	ret

SoundMode_SetReverbType:
	ld8_24 a, 0x0340f8
	cps a, 3
	jr z, SoundMode_ReverbType3
	cps a, 2
	jr z, SoundMode_ReverbType2
	cps a, 1
	jr z, SoundMode_ReverbType1
	stdi8 47084, 128
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType1:
	stdi8 47084, 155
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType2:
	stdi8 47084, 156
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType3:
	stdi8 47084, 157

SoundParam_SyncAndReturn:
	jp SndParam_ApplyAndSync

SoundMode_SetChorusType:
	ld8_24 a, 0x0340f9
	cps a, 3
	jr z, SoundMode_ChorusType3
	cps a, 2
	jr z, SoundMode_ChorusType2
	cps a, 1
	ret nz
	stdi8 47084, 91
	jr SoundMode_ChorusSyncAndRet

SoundMode_ChorusType2:
	stdi8 47084, 92
	jr SoundMode_ChorusSyncAndRet

SoundMode_ChorusType3:
	stdi8 47084, 93

SoundMode_ChorusSyncAndRet:
	jp SndParam_ApplyAndSync

VoiceData_ZeroFillAll:
	lda_24 xbc, 0xee2f36
	ld xwa, xbc
	lda xbc, (xbc + 64)

VoiceData_ZeroFillOuter:
	ld xhl, (xwa)
	ld d, (xhl - 1)
	ld e, d
	dec 1, d
	cps e, 0
	jr z, VoiceData_ZeroFillNext

VoiceData_ZeroFillInner:
	stib_dpi 0xec, 0x00
	ld e, d
	dec 1, d
	cps e, 0
	jr nz, VoiceData_ZeroFillInner

VoiceData_ZeroFillNext:
	inc 4, xwa
	cp xwa, xbc
	jr c, VoiceData_ZeroFillOuter
	ret

SoundParam_ApplyBit15Toggle:
	ldda16 xwa, 4597
	bit 15, wa
	ret z
	ldada xbc, 64602
	ld (xbc + 8), a
	lda xde, (xbc + 9)
	ld c, (xde)
	res 0, c
	ld (xde), c
	ldda16 xwa, 4597
	srl wa, 8
	and a, 0x1
	or c, a
	ld (xde), c
	ret

SoundParam_Bit15Jump:
	jr SoundParam_ApplyBit15Toggle

TGReg_WriteCC12_Assign:
	dec 4, xsp
	ld (xsp + 256), 0x0
	jr TGReg_WriteCC12_Check

TGReg_WriteCC12_Body:
	ld (xwa + 1), 0xc
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x10
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 256)

TGReg_WriteCC12_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC12_Body
	inc 4, xsp
	ret

SwbtWr_InitAndWrite_CC_B1:
	stdi8 37159, 177
	stdi8 37161, 0
	stdi8 37160, 0

SwbtWr_WriteLoop_CC_B1:
	stdi8 37162, 64
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldda8 a, 37160
	inc 1, a
	stda8 37160, a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B1
	ret

SwbtWr_WriteLoop_CC_B1_Ret:
	ret

SwbtWr_InitAndWrite_CC_B2:
	stdi8 37159, 178
	stdi8 37161, 0
	stdi8 37160, 0

SwbtWr_WriteLoop_CC_B2:
	stdi8 37162, 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldda8 a, 37160
	inc 1, a
	stda8 37160, a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B2
	ret

SwbtWr_InitAndWriteAllBlocks:
	stdi8 37159, 179
	stdi8 37161, 127
	stdi8 37160, 0

SwbtWr_WriteLoop_CC_B3:
	stdi8 37162, 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldda8 a, 37160
	inc 1, a
	stda8 37160, a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B3
	ret

SwbtWr_StubRet_A:
	ret

SwbtWr_StubRet_B:
	ret

SwbtWr_StubRet_C:
	ret

SwbtWr_WriteBankSelect:
	stdi8 37159, 176
	stdi8 37160, 0
	ldda8 a, 36582
	res 7, a
	stda8 37161, a
	stdi8 37162, 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	stdi8 37159, 176
	stdi8 37160, 1
	ldda8 a, 36580
	res 7, a
	stda8 37161, a
	stdi8 37162, 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiBuf_CalcFillRange:
	ldada xbc, 38516
	ld xde, xbc
	ldada xwa, 38579
	sub xwa, xbc
	inc 1, xwa
	ld c, a
	dec 1, c
	cps a, 0
	ret z

MidiBuf_FillLoop:
	stib_dpi 0xe8, 0x7f
	ld a, c
	dec 1, c
	cps a, 0
	jr nz, MidiBuf_FillLoop
	ret

MidiCtrl_ModeSwitch_Data:
	.byte 0xf1
	sbc	xsp, xiz
	sbc	w, w
	swi	6
	.byte 0xc1
	jrl	pl, 16320
	pop_sr
	ret	nz
	.byte 0xf1
	jrl	nc, -13632
	ret	z
	ldda8	a, 49278
	extz	wa
	calr	1
	ret

MidiCtrl_Bit2ToChannel:
	ldb c, 0x0
	bit 2, a
	jr z, MidiCtrl_Bit2ToChannel_Store
	ldb c, 0x1

MidiCtrl_Bit2ToChannel_Store:
	extz bc
	ld wa, bc
	jp COMM_WriteAndCheck

MidiCtrl_SendControlPacket:
	dec 4, xsp
	ld c, a
	ldda8 a, 37113
	bit 7, a
	jr nz, MidiCtrl_SendPacket_ClearFlag
	lda xwa, (xsp)
	ld (xwa), 0xb0
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	lda xde, (xwa + 1)
	ld (xde), 0x11
	bit 2, c
	jr nz, MidiCtrl_SendPacket_DispatchCall
	ld (xde), 0x10

MidiCtrl_SendPacket_DispatchCall:
	call MidiPkt_DispatchSpecialType
	jr MidiCtrl_SendPacket_Ret

MidiCtrl_SendPacket_ClearFlag:
	res 7, a
	stda8 37113, a

MidiCtrl_SendPacket_Ret:
	inc 4, xsp
	ret

VoiceData_SyncAllToHardware:
	pushw iz
	lds iz, 0

VoiceData_SyncLoop:
	ld wa, iz
	extz xwa
	ld xbc, 0xee2f76
	add xbc, xwa
	ld a, (xbc)
	call VoiceData_LookupPtrByIndex
	ld c, (xhl - 1)
	ld xwa, xhl
	sub xwa, 0xf9a0
	lda_24 xde, 0x03c8e4
	add xde, xwa
	extz bc
	pushw bc
	push xde
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, iz
	cps iz, 7
	jr c, VoiceData_SyncLoop
	ldada xbc, 64919
	ld a, (xbc)
	and a, 0x80
	ld (xbc), a
	ldda8 e, 36466
	res 7, e
	or a, e
	ld (xbc), a
	ldada xwa, 64623
	cpdi8 36468, 0
	jr z, VoiceSync_ClearBit5
	setm 5, (xwa)
	jr VoiceSync_PopReturn

VoiceSync_ClearBit5:
	resm 5, (xwa)

VoiceSync_PopReturn:
	popw iz
	ret

SwbtWr_ResetAllChannels:
	calr SwbtWr_InitAndWrite_CC_B1
	calr SwbtWr_WriteLoop_CC_B1_Ret
	calr SwbtWr_InitAndWrite_CC_B2
	calr SwbtWr_InitAndWriteAllBlocks
	calr SwbtWr_StubRet_A
	calr SwbtWr_StubRet_B
	calr SwbtWr_StubRet_C
	calr SwbtWr_WriteBankSelect
	jrl MidiBuf_CalcFillRange

SysEx_InitiateSend:
	set 7, a
	stda8 48380, a
	bit 7, a
	jr z, SysEx_ResetAndReturn
	setda 6, 48408
	call SeqAlt_CheckInitBuffer
	call MidiChan_ClearAllStates
	call MidiPkt_ArpMultiPass
	ldda8 a, 48380
	and a, 0x7
	extz wa
	cps wa, 0
	ret mi
	cps wa, 6
	ret gt
	add wa, wa
	lda_24 xix, 0xee2f7e
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, SysEx_SendDispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; SysEx send dispatch
SysEx_SendDispatch:
	call	16610839
	call	16611929
	call	MidiSeq_PartLookup_Data

SysEx_ResetAndReturn:
	stdi8 48408, 0
	jp SoundMode_ResetAllParams
SysEx_DispatchCalls_Data:
	call	16610860
	jr	-23
	call	16610872
	jr	-29
	call	16610884
	jr	-35
	call	16610896
	jr	-41
	call	16610908
	jr	-47
	call	16610909
	jr	-53
	ret

SysEx_ParseAndDispatch:
	push_werp 0xfa
	stdi8 48408, 0

SysEx_ParserLoop:
	call SeqBuf2_ReadByte
	cp hl, 0xffff
	jr z, SysEx_ParseAndDispatch_Ret
	ldfr_berp L, 0xfb
	call SeqAlt_CheckInitBuffer
	ldda8 c, 48414
	ldto_berp A, 0xfb
	extz wa
	cps c, 1
	jr z, SysEx_ParseState1_CheckManufID
	cps c, 0
	jr nz, SysEx_ParseState2_CheckBit7
	cp_erpb 0xfb, 0xf0
	jr nz, SysEx_ParserLoop
	stdi8 48414, 1
	jr SysEx_ParseState_AppendToQueue

SysEx_ParseState1_CheckManufID:
	cp_erpb 0xfb, 0x50
	jr z, SysEx_ParseState1_SetState2
	cp_erpb 0xfb, 0x7e
	jr z, SysEx_ParseState1_SetState2
	cp_erpb 0xfb, 0x41
	jr nz, SysEx_ParseState_Reset

SysEx_ParseState1_SetState2:
	stdi8 48414, 2
	jr SysEx_ParseState_AppendToQueue

SysEx_ParseState_Reset:
	stdi8 48414, 0

SysEx_ParseState_DispatchByte:
	call MidiSeq_ReinitCurrentBuffer
	jr SysEx_ParserLoop

SysEx_ParseState2_CheckBit7:
	bit_erpb 0xfb, 0x07
	jr nz, SysEx_ParseState2_EndOfSysEx
	ldda32 xbc, 48212
	cpw (xbc), 0xff
	jr nc, SysEx_ParseState_Reset

SysEx_ParseState_AppendToQueue:
	call VoiceQueue_Append
	jr SysEx_ParserLoop

SysEx_ParseState2_EndOfSysEx:
	stdi8 48414, 0
	cp_erpb 0xfb, 0xf7
	jr nz, SysEx_ParseState_DispatchByte
	call VoiceQueue_Append
	calr SeqData_DispatchHandler
	jr SysEx_ParserLoop

SysEx_ParseAndDispatch_Ret:
	pop_werp 0xfa
	ret

; Sequencer data dispatch handler
SeqData_DispatchHandler:
	call SeqData_InitPlaybackFromField
	ldda32 xwa, 48300
	lds bc, 4
	call SeqData_ReadFieldByIndex
	cps l, 0
	jr nz, SeqData_DispatchLoop
	ldda32 xwa, 48300
	lds bc, 0
	call SeqData_ReadFieldByIndex
	cp l, 0x27
	jr nc, SeqData_DispatchLoop
	ldda32 xwa, 48300
	lds bc, 0
	call SeqData_ReadFieldByIndex
	extz hl
	sla hl, 2
	lda_24 xbc, SeqData_SubDispatch_Table
	ld_sril3 XHL, 0x07, 0xe4, 0xec
	call (xhl)

SeqData_DispatchLoop:
	call MidiPkt_SendBankSelect
	jp SoundMode_ResetAllParams
SeqData_DispatchLoop_Body:
	ret
SeqData_DispatchLoop_Check:
	jp	SoundMode_ResetAllParams

SeqData_DispatchLoop_Done:
	dec 4, xsp
	ld xiy, 0xee3028
	ld xix, xsp
	ldi85
	ldiw
	lds wa, 0
	call AccWrap_ReturnZero
	cp hl, 0xffff
	jr z, ArpQueue_Flush_Return
	bitda 0, 47079
	jr nz, ArpQueue_Flush_Return
	cpdi8 36150, 87
	jr z, ArpQueue_Flush_Return
	ldda8 a, 64848
	and a, 0x14
	jr nz, ArpQueue_Flush_Return
	ld xwa, 0xee35cc
	lds bc, 3
	call SeqBuf_FlushNoteOffs
	ldda16 xwa, 48442
	cp wa, 0x28
	jr nc, SeqData_FormatOutput
	stdi16 48442, 40
	jr SeqData_FormatOutput_Loop

SeqData_FormatOutput:
	cp wa, 0x12c
	jr ule, SeqData_FormatOutput_Loop
	stdi16 48442, 300

SeqData_FormatOutput_Loop:
	lda xwa, (xsp)
	ldda16 xbc, 48442
	and c, 0xf
	ld (xwa), c
	ldda16 xbc, 48442
	srl bc, 4
	and c, 0x1f
	ld (xwa + 1), c
	lds bc, 3
	call ArpQueue_Enqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

ArpQueue_Flush_Return:
	inc 4, xsp
	ret

SeqData_FormatOutput_Dispatch:
	; --- Input validation and dispatch (106 bytes, 2 functions) ---
	lds	wa, 0
	call AccWrap_ReturnZero
	cp hl, 0xffff
	ret z
	cpdi8	36150, 87
	ret z
	ldda8	a, 64848
	and a, 0x14
	ret nz
	ldda32	xwa, 48212
	ld e, (xwa + 17)
	ld c, (xwa + 18)
	ld a, e
	and a, 0xf0
	jr z, SeqData_FormatOutput_CaseA
	ld a, c
	and a, 0xe0
	ret nz
SeqData_FormatOutput_CaseA:
	extz bc
	sll bc, 4
	extz de
	or de, bc
	cp de, 0x0028
	ret c
	cp de, 0x012c
	ret	ugt
	ld wa, de
	call SoundMode_SysExConfig_Data
	calr SeqData_FormatOutput_CaseB
	ret
SeqData_FormatOutput_CaseB:
	stdi16	37086, 0
	push xde
	push xhl
	push xix
	push xiz
	call MidiStream_JumpStubData
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret


SeqData_FormatOutput_CaseC:
	bitda	4, 64848
	ret	nz
	ldda32	xwa, 48212
	lda	xwa, (xwa+14)
	jp	16707558
SeqData_FormatOutput_Default:
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	ldda32	xwa, 48212
	lda	xwa, (xwa+14)
	call	16708023
	cps	hl, 0
	ret	z
	ld	xwa, 15611308
	lds	bc, 5
	call	ArpQueue_Enqueue
	ldda32	xwa, 48220
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	ret
SeqData_FormatOutput_Data:
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	calr	31
	.byte 0xd1
	adc	wa, iz
	push	xsp
	nop
	nop
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	.byte 0xd1
	adc	wa, iz
	pop_f
	.byte 0xe0, 0x90
	call	MidiStream_JumpStubData
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	ldda32	xwa, 48300
	lds	bc, 1
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cps	hl, 0
	ret	lt
	cps	hl, 6
	ret	gt
	add	hl, hl
	lda_24	xix, 15609900
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	jrl	nz, -625
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	jr	18
	jr	110
	jrl	200
	jrl	291
	jrl	289
	jrl	379
	calr	469
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	divs	l, 111
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617578
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	.byte 0xba, 0x17
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617578
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617666
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	pop	xiy
	.byte 0x17
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617666
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0xcf
	incf
	jr	nc, 68
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	sla	bc, 2
	lda_24	xwa, 15617674
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	swi	7
	ex_ff
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617674
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617770
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	.byte 0xa1
	ex_ff
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617770
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617778
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	ld	xix, 4291812118
	swi	7
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617778
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0xcf
	ret
	jr	nc, 68
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	sla	bc, 2
	lda_24	xwa, 15617786
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	.byte 0xe6
	pop_a
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617786
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617898
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret

SeqAlt_NibbleSearch_Ret:
	ret

SeqAlt_NibbleSearch:
	ld hl, de
	dec 1, de
	cps hl, 0
	jr z, SeqAlt_NibbleSearch_NotFound

SeqAlt_NibbleSearch_CompareLoop:
	cp_spib A, 0xe4
	jr nz, SeqAlt_NibbleSearch_DecLoop
	lds hl, 0
	ret

SeqAlt_NibbleSearch_DecLoop:
	ld hl, de
	dec 1, de
	cps hl, 0
	jr nz, SeqAlt_NibbleSearch_CompareLoop

SeqAlt_NibbleSearch_NotFound:
	ldw hl, 0xffff
	ret

SeqAlt_ApplyDescriptor_TypeA:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 4)
	lda xix, (xbc + 2)
	ld (xix), l
	cp (xiz + 9), l
	jrl ugt, SeqAlt_PopIzSkip4Ret
	cp l, (xiz + 10)
	jrl ugt, SeqAlt_PopIzSkip4Ret
	ld a, (xiz + 14)
	cp a, 0xff
	jr z, SeqAlt_ApplyDescA_DirectWrite
	cps a, 1
	jr nc, SeqAlt_PopIzSkip4Ret
	extz wa
	muls wa, 0x6
	lda_24 xbc, 0xee4e16
	exts xwa
	add xwa, xbc
	ld de, (xwa)
	ld xbc, (xwa + 2)
	extz hl
	ld wa, hl
	calr SeqAlt_NibbleSearch
	cp hl, 0xffff
	jr z, SeqAlt_PopIzSkip4Ret
	lda xbc, (xsp + 4)
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	lda xhl, (xbc + 2)
	ld e, (xhl)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescA_NoShift
	slla e

SeqAlt_ApplyDescA_NoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xhl), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	jr SeqAlt_ApplyDescA_FinalCall

SeqAlt_ApplyDescA_DirectWrite:
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld e, (xix)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescA_DirectNoShift
	slla e

SeqAlt_ApplyDescA_DirectNoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xix), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc

SeqAlt_ApplyDescA_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_ApplyDescriptor_TypeB:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	ld a, (xiz + 9)
	cp a, l
	jrl gt, SeqAlt_PopIzSkip4Ret2
	ld c, (xiz + 10)
	cp l, c
	jrl gt, SeqAlt_PopIzSkip4Ret2
	lda xbc, (xsp + 4)
	lda xix, (xbc + 2)
	ld (xix), l
	ld a, (xiz + 14)
	cp a, 0xff
	jr z, SeqAlt_ApplyDescB_DirectWrite
	cps a, 1
	jr nc, SeqAlt_PopIzSkip4Ret2
	extz wa
	muls wa, 0x6
	lda_24 xbc, 0xee4e16
	exts xwa
	add xwa, xbc
	ld de, (xwa)
	ld xbc, (xwa + 2)
	extz hl
	ld wa, hl
	calr SeqAlt_NibbleSearch
	cp hl, 0xffff
	jr z, SeqAlt_PopIzSkip4Ret2
	lda xbc, (xsp + 4)
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	lda xhl, (xbc + 2)
	ld e, (xhl)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescB_NoShift
	slla e

SeqAlt_ApplyDescB_NoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xhl), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	jr SeqAlt_ApplyDescB_FinalCall

SeqAlt_ApplyDescB_DirectWrite:
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld e, (xix)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescB_DirectNoShift
	slla e

SeqAlt_ApplyDescB_DirectNoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xix), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc

SeqAlt_ApplyDescB_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_PopIzSkip4Ret2:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_DescriptorBlock_Data:
	dec	6, xsp
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, 59
	.byte 0x8e
	ldwio	247, 13931
	extz	hl
	lda	xbc, (xsp+4)
	ld	a, (xiz+6)
	ld	(xbc), a
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xde, (xiz+11)
	ld	a, (xde)
	and	a, 15
	jr	z, 2
	.byte 0xdb
	swi	6
	ld	(xbc+2), hl
	ld	l, (xiz+8)
	extz	hl
	ld	a, (xde)
	and	a, 15
	jr	z, 2
	.byte 0xdb
	swi	6
	ld	(xbc+4), hl
	ld	xwa, xbc
	call	AssSwb_ProcessLoop_Data
	pop	xiz
	inc	6, xsp
	ret
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, 47
	.byte 0x8e
	ldwio	247, 10859
	ld	a, (xiz+14)
	cps	a, 1
	jr	nc, 35
	extz	wa
	muls	wa, 6
	lda_24	xbc, 15617560
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 142
	ldio	33, 201
	.byte 0x06
	and	(xbc), a
	ld	a, (xiz+11)
	and	a, 15
	jr	z, 2
	.byte 0xcf
	swi	6
	or	(xbc), l
	pop	xiz
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	lda	xbc, (xsp+4)
	ld	(xbc+2), l
	cp	(xiz+9), l
	jrl	ugt, 169
	.byte 0x8e
	ldwio	247, 41851
	nop
	ld	a, (xiz+14)
	cp	a, 255
	jr	z, 96
	cps	a, 1
	jrl	nc, 150
	extz	wa
	muls	wa, 6
	lda_24	xbc, 15617558
	exts	xwa
	add	xwa, xbc
	ld	de, (xwa)
	ld	xbc, (xwa+2)
	extz	hl
	ld	wa, hl
	calr	64947
	cp	hl, 65535
	jr	z, 117
	ld	a, (xiz+6)
	ld	(xsp+4), a
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
	jr	55
	ld	a, (xiz+6)
	ld	(xbc), a
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
	call	AssSwb_ApplyBitDescriptor
	pop	xiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+10), xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	ld	(xsp+4), l
	ld	xde, (xsp+10)
	ld	a, (xde+9)
	.byte 0x8f, 0x04
	stdi8	34171, 143
	.byte 0x04
	ldb	c, 138
	ldwio	243, 32107
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	.byte 0xc7
	swi	0
	.byte 0x9f
	extz	iz
	sll	iz, 8
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	extz	hl
	or	iz, hl
	cp	iz, 16383
	jr	ugt, 91
	srl	iz, 4
	and	iz, 63
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	xwa, (xsp+10)
	ld	a, (xwa+6)
	or	a, l
	.byte 0xc7
	swi	3
	.byte 0x99
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	ld	(xwa+1), 1
	.byte 0xc7
	swi	0
	.byte 0x8b
	ld	(xwa+2), c
	ld	(xwa+3), 127
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	ld	xde, (xsp+10)
	ld	c, (xde+7)
	ld	(xwa+1), c
	ld	c, (xsp+4)
	ld	(xwa+2), c
	ld	c, (xde+8)
	ld	(xwa+3), c
	call	AssSwb_ApplyBitDescriptor
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	ld	(xsp+8), l
	ld	a, (xiz+9)
	.byte 0x8f
	ldio	241, 123
	.byte 0xb8
	nop
	ld	a, (xsp+8)
	.byte 0x8e
	ldwio	241, 44923
	nop
	ld	a, (xiz+14)
	cps	a, 1
	jrl	nc, 167
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617568
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x04
	jr	f, -31
	ld	xwa, (xix-68)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	a, (xiz+6)
	or	a, l
	ld	(xsp+10), a
	lda	xiy, (xiz+7)
	inc	8, xiz
	lda	xwa, (xsp+12)
	lda	xde, (xwa+1)
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	.byte 0x8f
	ldio	63, 129
	jr	z, 51
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	c, (xiy)
	ld	(xde), c
	ld	c, (xsp+8)
	ld	(xhl), c
	ld	c, (xiz)
	ld	(xix), c
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+12)
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	xde, (xsp+4)
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	(xwa+2), 0
	ld	c, (xde+3)
	ld	(xwa+3), c
	jr	49
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	c, (xiy)
	ld	(xde), c
	ld	(xhl), 0
	ld	c, (xiz)
	ld	(xix), c
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+12)
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	xde, (xsp+4)
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	c, (xde+2)
	ld	(xwa+2), c
	ld	c, (xde+3)
	ld	(xwa+3), c
	call	AssSwb_ApplyBitDescriptor
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48212
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, 110
	.byte 0x8e
	ldwio	247, 26987
	ld	a, (xiz+14)
	cp	a, 255
	jr	z, 97
	cps	a, 1
	jr	nc, 93
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617574
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	ldw	bc, 55503
	jr	nz, 6
	ld	a, (xwa)
	ld	(xbc), a
	jr	5
	ld	a, (xwa+1)
	ld	(xbc), a
	ld	a, (xiz+6)
	ld	(xsp+4), a
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, 2
	.byte 0xcd
	swi	6
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
	call	AssSwb_ApplyBitDescriptor
	pop	xiz
	inc	4, xsp
	ret
	ret
	ldda32	xwa, 48212
	lda	xwa, (xwa+14)
	call	16707806
	cps	hl, 0
	ret	z
	ld	xwa, 15611308
	lds	bc, 5
	call	ArpQueue_Enqueue
	ldda32	xwa, 48220
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	ret

SeqAlt_ApplyDescriptor_TypeC:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 4)
	lda xde, (xbc + 2)
	ld (xde), l
	cp (xiz + 9), l
	jr ugt, SeqAlt_ApplyDescC_Cleanup
	cp l, (xiz + 10)
	jr ugt, SeqAlt_ApplyDescC_Cleanup
	lda xix, (xiz + 11)
	cp l, 0x40
	scc16 nc, hl
	ld a, (xix)
	and a, 0xf
	jr z, SeqAlt_ApplyDescC_NoShift
	slaa hl

SeqAlt_ApplyDescC_NoShift:
	ld (xde), l
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	call AssSwb_ApplyBitDescriptor

SeqAlt_ApplyDescC_Cleanup:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_ApplyDescriptor_TypeD:
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, SeqAlt_ApplyDescD_Cleanup
	cp l, (xiz + 10)
	jr ugt, SeqAlt_ApplyDescD_Cleanup
	ld e, (xiz + 6)
	ld c, (xiz + 7)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescD_NoShift
	slla l

SeqAlt_ApplyDescD_NoShift:
	extz hl
	ld a, (xiz + 8)
	extz wa
	pushw wa
	ld a, e
	ld de, hl
	call AssswbWr

SeqAlt_ApplyDescD_Cleanup:
	pop xiz
	ret

SeqAlt_StubRet_Pair:
	ret
	ret

SeqAlt_ApplyDescriptor_WithAssSwb:
	dec 8, xsp
	push_werp 0xfa
	ld (xsp + 6), xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	ldfr_berp L, 0xfb
	lda xbc, (xsp + 2)
	lda xde, (xbc + 1)
	lda xhl, (xbc + 2)
	lda xix, (xbc + 3)
	cpi_berp 0xfb, 0
	jr z, SeqAlt_AssSwb_ZeroPath
	dec1_berp 0xfb
	ld xiy, (xsp + 6)
	ld a, (xiy + 11)
	and a, 0xf
	jr z, SeqAlt_AssSwb_NoShift
	sll_a_berp 0xfb

SeqAlt_AssSwb_NoShift:
	ld a, (xiy + 9)
	cp_berp A, 0xfb
	jr ugt, SeqAlt_AssSwb_Cleanup
	ldto_berp A, 0xfb
	cp a, (xiy + 10)
	jr ugt, SeqAlt_AssSwb_Cleanup
	setda 3, 36178
	ld (xbc), 0x98
	ld (xde), 0x3
	ld (xhl), 0x1
	ld (xix), 0x1
	ld xwa, xbc
	call AssSwb_ApplyBitDescriptor
	lda xwa, (xsp + 2)
	ld (xwa), 0x48
	ld (xwa + 1), 0x7
	ldto_berp C, 0xfb
	ld (xwa + 2), c
	ld (xwa + 3), 0x30
	jr SeqAlt_AssSwb_FinalCall

SeqAlt_AssSwb_ZeroPath:
	ld (xbc), 0x98
	ld (xde), 0x3
	ld (xhl), 0x0
	ld (xix), 0x1
	ld xwa, xbc

SeqAlt_AssSwb_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_AssSwb_Cleanup:
	pop_werp 0xfa
	inc 8, xsp
	ret

SeqAlt_DualNibblePack:
	dec 4, xsp
	push xiz
	ldada xwa, 48422
	ld (xsp + 4), xwa
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	inc 1, xiz
	ld xwa, (xsp + 4)
	ld (xwa), l
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	ld (xiz), l
	bitm 7, (xiz)
	jr z, SeqAlt_DualNibblePack_Dispatch
	resm 7, (xiz)
	setm 7, (xiz - 1)

SeqAlt_DualNibblePack_Dispatch:
	call MidiStream_RefreshDisplay
	pop xiz
	inc 4, xsp
	ret

DSPParam_StoreWithLoop:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 10)
	ld (xbc), l
	cp (xiz + 9), l
	jrl ugt, DSP_ParamLoop_Cleanup
	cp l, (xiz + 10)
	jr ugt, DSP_ParamLoop_Cleanup
	ld a, (xiz + 11)
	and a, 0xf
	jr z, DSPParam_StoreWithLoop_NoShift
	slla l

DSPParam_StoreWithLoop_NoShift:
	ld (xbc), l
	ld a, (xiz + 6)
	sub a, 0x61
	ldb w, 0x0
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 8
	ld (xsp + 4), xwa
	add xwa, 0x4900
	extz hl
	ld bc, hl
	call DSPCfg_WriteParamFull
	cps hl, 0
	jr lt, DSP_ParamLoop_Cleanup
	ld xwa, (xsp + 4)
	add xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 0
	jr lt, DSP_ParamLoop_Cleanup
	lds iz, 0
	cpi_werp 0xfa, 0
	jr le, DSP_ParamLoop_Cleanup

VoiceParam_ApplyRangeCheck:
	ld bc, iz
	exts xbc
	ld xwa, (xsp + 4)
	add xwa, 0x4910
	add xwa, xbc
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld de, iz
	exts xde
	ld xwa, (xsp + 4)
	add xwa, 0x4910
	add xwa, xde
	call DSPCfg_WriteParamFull
	inc 1, iz
	cp_werp IZ, 0xfa
	jr lt, VoiceParam_ApplyRangeCheck

DSP_ParamLoop_Cleanup:
	pop xiz
	inc 8, xsp
	ret

VoiceParam_ApplyBoundsCheck:
	dec 8, xsp
	push_werp 0xfa
	ld (xsp + 6), xwa
	ldda8 a, 36148
	cp a, 0xe
	jr nz, VoiceParam_ApplyBoundsValidated
	cp a, 0x11
	jr z, VoiceParam_ApplyCleanupRet

VoiceParam_ApplyBoundsValidated:
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	ldfr_berp L, 0xfb
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	bit 7, l
	jr z, VoiceParam_ApplyNibbleLookup
	res 7, l
	set_erpb 0xfb, 0x07

VoiceParam_ApplyNibbleLookup:
	ld xde, (xsp + 6)
	ld a, (xde + 9)
	cp_berp A, 0xfb
	jr ugt, VoiceParam_ApplyCleanupRet
	ldto_berp C, 0xfb
	cp c, (xde + 10)
	jr ugt, VoiceParam_ApplyCleanupRet
	and l, 0x7
	bit_erpb 0xfb, 0x07
	jr z, VoiceParam_ApplyNibble_NoShiftBit
	ldb l, 0x0

VoiceParam_ApplyNibble_NoShiftBit:
	lda xwa, (xsp + 2)
	ld xbc, (xsp + 6)
	ld c, (xbc + 6)
	ld (xwa), c
	ld (xwa + 1), 0x1
	ld (xwa + 2), l
	ld (xwa + 3), 0x7f
	call AssSwb_ApplyBitDescriptor
	lda xwa, (xsp + 2)
	ld xde, (xsp + 6)
	ld c, (xde + 6)
	ld (xwa), c
	ld c, (xde + 7)
	ld (xwa + 1), c
	ldto_berp C, 0xfb
	ld (xwa + 2), c
	ld c, (xde + 8)
	ld (xwa + 3), c
	call AssSwb_ApplyBitDescriptor

VoiceParam_ApplyCleanupRet:
	pop_werp 0xfa
	inc 8, xsp
	ret

VoiceParam_StoreToBuffer:
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	ld a, (xiz + 11)
	and a, 0xf
	jr z, VoiceParam_StoreToBuffer_NoShift
	slla l

VoiceParam_StoreToBuffer_NoShift:
	stda8 48422, l
	cp (xiz + 9), l
	jr ugt, VoiceParam_StoreToBuffer_Ret
	cp l, (xiz + 10)
	call_24 ule, 0xfd5c80

VoiceParam_StoreToBuffer_Ret:
	pop xiz
	ret

VoiceParam_DirectHardwareWrite:
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, VoiceParam_DirectHW_Ret
	cp l, (xiz + 10)
	jr ugt, VoiceParam_DirectHW_Ret
	mrdb5 0x8e, 0x07, 0x19, 0x89, 0x34
	ld a, (xiz + 11)
	and a, 0xf
	jr z, VoiceParam_DirectHW_NoShift
	slla l

VoiceParam_DirectHW_NoShift:
	stda8 13436, l
	mrdb5 0x8e, 0x08, 0x19, 0x7d, 0x34
	call MidiStream_ReplaySavedExpr

VoiceParam_DirectHW_Ret:
	pop xiz
	ret

VoiceParam_MultiModeDispatch:
	push xiz
	ld xiz, xwa
	ldda32 xwa, 48212
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, VoiceParam_LoopExit
	cp l, (xiz + 10)
	jr ugt, VoiceParam_LoopExit
	lda xbc, (xiz + 8)
	lda xwa, (xiz + 11)
	cps l, 2
	jr z, VoiceParam_MultiMode_Case2
	cps l, 1
	jr z, VoiceParam_MultiMode_Case1
	cps l, 0
	jr nz, VoiceParam_LoopExit
	stdi8 13449, 5
	stdi8 13436, 0
	stdi8 13437, 4
	call MidiStream_ReplaySavedExpr
	stdi8 13449, 6
	stdi8 13436, 0
	stdi8 13437, 4
	jr VoiceParam_MultiMode_Dispatch

VoiceParam_MultiMode_Case1:
	stdi8 13449, 5
	ld a, (xwa)
	and a, 0xf
	jr z, VoiceParam_MultiMode_Case1_NoShift
	slla l

VoiceParam_MultiMode_Case1_NoShift:
	stda8 13436, l
	jr VoiceParam_MultiMode_SetupHW

VoiceParam_MultiMode_Case2:
	stdi8 13449, 6
	ld a, (xwa)
	dec 1, a
	and a, 0xf
	jr z, VoiceParam_MultiMode_Case2_NoShift
	slla l

VoiceParam_MultiMode_Case2_NoShift:
	stda8 13436, l

VoiceParam_MultiMode_SetupHW:
	mrib4 0x81, 0x19, 0x7d, 0x34

VoiceParam_MultiMode_Dispatch:
	call MidiStream_ReplaySavedExpr

VoiceParam_LoopExit:
	pop xiz
	ret

VoiceParam_MultiMode_StubRet:
	ret
VoiceParam_AssSwb_MultiBlock_Data:
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	ldda32	xwa, 48300
	lds	bc, 1
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cps	hl, 0
	ret	lt
	cps	hl, 6
	ret	gt
	add	hl, hl
	lda_24	xix, 15609914
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	push	xiz
	.byte 0x9a
	swi	5
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	jr	18
	jr	110
	jrl	200
	jrl	291
	jrl	289
	jrl	379
	calr	469
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	divs	l, 111
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617622
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	swi	2
	incf
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617622
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617670
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	xor	(xiy+12), hl
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617670
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0xcf
	incf
	jr	nc, 68
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	sla	bc, 2
	lda_24	xwa, 15617722
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	push	xsp
	incf
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617722
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617774
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	.byte 0xe1
	pushw	53211
	swi	7
	swi	7
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617774
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	dec	7, bc
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617782
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	.byte 0x84
	pushw	53211
	swi	7
	swi	7
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617782
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	lds	bc, 2
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	mul	l, 111
	ld	xix, 3649829831
	ccf
	sla	bc, 2
	lda_24	xwa, 15617842
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 30
	ldb	h, 11
	cp	hl, 65535
	jr	z, 41
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617842
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 233
	.byte 0x88
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda_24	xde, 15617946
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	.byte 0xd7
	swi	2
	halt
	ret

VoiceParam_MultiBlock_Ret:
	ret

VoiceParam_MultiBlock_Epilogue_Data:
	lda	xsp, (xsp-12)
	ld	c, (xwa+14)
	cps	c, 1
	jr	nc, 53
	extz	bc
	muls	bc, 6
	lda_24	xde, 15617560
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	c, 191
	ldio	50, 136
	.byte 0x06
	ldb	c, 178
	ld	xhl, 3122857864
	.byte 0x01
	ld	xhl, 45753219
	ld	xhl, 3122858120
	pop_sr
	ld	xhl, 1655779767
	ld	(xbc+4), xwa
	ld	xwa, xbc
	calr	1460
	lda	xsp, (xsp+12)
	ret

VoiceParam_LookupAndEnqueue:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 12)
	lda xde, (xiz + 6)
	ld a, (xde)
	ld (xbc), a
	lda xhl, (xiz + 7)
	ld a, (xhl)
	ld (xbc + 1), a
	ld a, (xde)
	ld c, (xhl)
	call Part_LookupTableEntry
	lda xbc, (xsp + 12)
	ld (xbc + 2), l
	ld a, (xiz + 8)
	ld (xbc + 3), a
	lda xwa, (xsp + 4)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr MidiPkt_EnqueueControl_3354
	pop xiz
	lda xsp, (xsp + 12)
	ret

	.include "midi/midipkt_routines.s"
