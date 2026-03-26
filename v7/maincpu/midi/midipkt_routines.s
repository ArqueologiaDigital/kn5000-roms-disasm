; =============================================================================
; MIDI Packet Routines
; =============================================================================
;
; MIDI packet extraction, packing, and queue management.
; Handles the low-level MIDI message framing between the
; serial I/O layer and the dispatch handlers.
; =============================================================================

MidiPkt_ExtractAndPack:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack.bin"
MidiPkt_ExtractAndPack_StoreShifted:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack_StoreShifted.bin"
MidiPkt_ExtractAndPack_Ret:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack_Ret.bin"
MidiPkt_BuildDirect:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildDirect.bin"
MidiPkt_BuildControl:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildControl.bin"
MidiPkt_BuildStatusDirect:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildStatusDirect.bin"
MidiPkt_BuildFromConstant:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildFromConstant.bin"
MidiPkt_BuildZeroData:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildZeroData.bin"
MidiPkt_ProcessEventQueue:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue.bin"
MidiPkt_ProcessEventQueue_Loop:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Loop.bin"
MidiPkt_ProcessEventQueue_Next:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Next.bin"
MidiPkt_ProcessEventQueue_Done:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Done.bin"
MidiPkt_Nop:
	.incbin "includes/generated/v7_transplant_MidiPkt_Nop.bin"
MidiPkt_DispatchViaTable_4D6A:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D6A.bin"
MidiPkt_DispatchViaTable_4D82:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D82.bin"
MidiPkt_DispatchViaTable_4D8E:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D8E.bin"
MidiPkt_DispatchViaTable_4D9A:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D9A.bin"
MidiPkt_DispatchViaTable_4DA6:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DA6.bin"
MidiPkt_DispatchViaTable_4DAE:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DAE.bin"
MidiPkt_DispatchViaTable_4DAE_Done:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DAE_Done.bin"
MidiPkt_DispatchSpecialType:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType.bin"
MidiPkt_DispatchSpecialType_Type10:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Type10.bin"
MidiPkt_DispatchSpecialType_SendAndUpdate:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_SendAndUpdate.bin"
MidiPkt_DispatchSpecialType_Default:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Default.bin"
MidiPkt_DispatchSpecialType_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Return.bin"
MidiPkt_MatchParamInTable:
	.incbin "includes/generated/v7_transplant_MidiPkt_MatchParamInTable.bin"
MidiPkt_MatchParamInTable_Loop:
	.incbin "includes/generated/v7_transplant_MidiPkt_MatchParamInTable_Loop.bin"
MidiPkt_EnqueueControlNop:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControlNop.bin"
MidiPkt_EnqueueControl_3354:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354.bin"
MidiPkt_EnqueueControl_3354_ShiftBits:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354_ShiftBits.bin"
MidiPkt_EnqueueControl_3354_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354_Return.bin"
MidiPkt_EnqueueExtended_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueExtended_Data.bin"
MidiPkt_EnqueueControl_335C:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C.bin"
MidiPkt_EnqueueControl_335C_ZeroData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C_ZeroData.bin"
MidiPkt_EnqueueControl_335C_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C_Return.bin"
MidiPkt_EnqueueControl_3358:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358.bin"
MidiPkt_EnqueueControl_3358_SplitNibbles:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358_SplitNibbles.bin"
MidiPkt_EnqueueControl_3358_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358_Return.bin"
MidiPkt_EnqueueControl_335E:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E.bin"
MidiPkt_EnqueueControl_335E_SplitNibbles:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E_SplitNibbles.bin"
MidiPkt_EnqueueControl_335E_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E_Return.bin"
MidiPkt_EnqueueControl_3364:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364.bin"
MidiPkt_EnqueueControl_3364_NoShift:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_NoShift.bin"
MidiPkt_EnqueueControl_3364_FormatData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_FormatData.bin"
MidiPkt_EnqueueControl_3364_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_Return.bin"
MidiPkt_EnqueueControl_3368:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368.bin"
MidiPkt_EnqueueControl_3368_PedalNoShift:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_PedalNoShift.bin"
MidiPkt_EnqueueControl_3368_NoPedal:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_NoPedal.bin"
MidiPkt_EnqueueControl_3368_FormatData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_FormatData.bin"
MidiPkt_EnqueueControl_3368_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_Return.bin"
MidiPkt_EnqueueExtended2_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueExtended2_Data.bin"
MidiPkt_CheckGateCondition:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition.bin"
MidiPkt_CheckGateCondition_Second:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Second.bin"
MidiPkt_CheckGateCondition_Blocked:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Blocked.bin"
MidiPkt_CheckGateCondition_Pass:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Pass.bin"
MidiPkt_DispatchViaTable_4DCE:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DCE.bin"
MidiPkt_DispatchData_Chan4:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan4.bin"
MidiPkt_DispatchData_Chan3:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan3.bin"
MidiPkt_DispatchData_Chan1:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan1.bin"
MidiPkt_DispatchData_Chan2:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan2.bin"
MidiPkt_DispatchData_Chan5:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan5.bin"
MidiPkt_DispatchData_Chan6:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan6.bin"
MidiPkt_SendBankSelect:
	.incbin "includes/generated/v7_transplant_MidiPkt_SendBankSelect.bin"
MidiPkt_SendBankSelect_Send:
	.incbin "includes/generated/v7_transplant_MidiPkt_SendBankSelect_Send.bin"
MidiPkt_SysExValidator_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_SysExValidator_Data.bin"
MidiPkt_SysExProcessor_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_SysExProcessor_Data.bin"
MidiPkt_SysExBulkTransfer_Data:
	ldda32	xwa, (0xbcac)
	lds	bc, 1
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cps	hl, 0
	ret	lt
	cps	hl, 5
	ret	gt
	add	hl, hl
	lda_24	xix, (MidiPkt_EventType_Table_0x324)
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	popw	iy
	.byte 0xa9
	swi	5
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	jr	98
	jrl	377
	jrl	377
	jrl	512
	jrl	641
	calr	776
	ret
	lda_d16	xde, (0x9644)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	.byte 0xba
	pop	sr
	ld	xbc, 0x3e3c3b3a
	call	MidiStream_ExtendedDispatch_0x298
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	lda_d16	xde, (0x9644)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	.byte 0xba
	pop	sr
	ld	xbc, 0x3e3c3b3a
	call	MidiStream_ExtendedDispatch_0x1
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	lda	xsp, (xsp-12)
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, (0xbcac)
	ldw	bc, 9
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0xca
	rcf
	.byte 0xc7
	swi	3
	.byte 0xcf
	rcf
	jrl	nc, 244
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda_24	xbc, (MidiPkt_EventType_Table_0x330)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 199
	swi	3
	sub	(xbc-31), ix
	lda	xbc, (xix+32)
	pushw	7424
	.byte 0xb6
	pop	xiz
	swi	5
	cps	l, 2
	jrl	ugt, 210
	.byte 0xc7
	swi	3
	.byte 0xcf
	retd	0xcb76
	nop
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	cps	l, 0
	jr	z, 97
	pushw	0
	lds	bc, 0
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	0
	ldw	bc, 32
	ldw	de, 120
	call	SndParam_NotifyAndReturn
	ld	xiy, MidiPkt_EventType_Table_0x340
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65321
	ld	xiy, MidiPkt_EventType_Table_0x344
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65298
	ld	xiy, MidiPkt_EventType_Table_0x348
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	jr	94
	pushw	0
	lds	bc, 0
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	0
	ldw	bc, 32
	lds	de, 0
	call	SndParam_NotifyAndReturn
	ld	xiy, MidiPkt_EventType_Table_0x34C
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65225
	ld	xiy, MidiPkt_EventType_Table_0x350
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65202
	ld	xiy, MidiPkt_EventType_Table_0x354
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65218
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+12)
	ret
	jrl	-568
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbcac)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	93
	extz	hl
	ld	xwa, 0x4b00
	ld	bc, hl
	call	DSPCfg_WriteParamFull
	cps	hl, 0
	jr	lt, 72
	ld	xwa, 0x4b04
	call	DSPCfg_ReadParam_Map0
	.byte 0xd7
	swi	2
	cp	(xhl-41), de
	inc	1, wa
	.byte 0x37
	lds	iz, 0
	.byte 0xd7
	swi	2
	inc	2, wa
	pushw	de
	ld	a, (xsp+4)
	extz	wa
	.byte 0xc7
	swi	0
	.byte 0x8b
	extz	bc
	calr	596
	ld	bc, hl
	cp	bc, 0xd8f0
	jr	z, 14
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4b10
	call	DSPCfg_WriteParamFull
	inc	1, iz
	.byte 0xd7
	swi	2
	.byte 0xf6
	jr	lt, -42
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xiz
	inc	2, xsp
	ret

