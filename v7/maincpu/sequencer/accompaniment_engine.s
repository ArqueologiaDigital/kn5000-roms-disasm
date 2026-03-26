; =============================================================================
; Accompaniment Engine (32K lines)
; =============================================================================
;
; Rhythm note dispatch, accompaniment voice selection, timing,
; patch management, drum configuration, and style conversion.
; One of the largest files in the ROM.
; =============================================================================

Rhythm_DispatchNote:
	ld l, a
	ld h, d
	call VoiceParam_ClampAndValidate
	ld a, l
	ld d, h
	cp a, 0x80
	jr c, Rhythm_DispatchNote_Lookup
	cp a, 0xf0
	jr c, Rhythm_DispatchNote_SetParam
	call AccTone_LookupByProgramWrapped
	jr Rhythm_DispatchNote_Return

Rhythm_DispatchNote_SetParam:
	and a, 0x7f
	call AccPatch_SetVoiceParam
	jr Rhythm_DispatchNote_Return

Rhythm_DispatchNote_Lookup:
	ld h, d
	call AccVoice_LookupWithOffset
	call AccStyle_ReadVoiceParam

Rhythm_DispatchNote_Return:
	ret

AccStyle_TempoLookupData:
	push	xiz
	calr	2
	pop	xiz
	ret
	call	AccTuning_DispatchDataBlock_A_0x4C
	ret

AccStyle_LookupTempoAndVelocity:
	.incbin "includes/generated/v7_transplant_AccStyle_LookupTempoAndVelocity.bin"
AccStyle_LookupTempo_ClampL:
	.incbin "includes/generated/v7_transplant_AccStyle_LookupTempo_ClampL.bin"
AccStyle_LookupTempo_AddAndStore:
	.incbin "includes/generated/v7_transplant_AccStyle_LookupTempo_AddAndStore.bin"
AccStyle_TempoMultiplierTable:
	.byte 0x00, 0x00, 0x14, 0x00, 0x28, 0x00, 0x3c, 0x00
	.byte 0x50, 0x00, 0x64, 0x00, 0x78, 0x00, 0x8c, 0x00
	.byte 0xa0, 0x00, 0xb4, 0x00, 0xc8, 0x00, 0xdc, 0x00
	.byte 0xf0, 0x00, 0x04, 0x01, 0x18, 0x01, 0x68, 0x01

AccStyle_LookupVelocityTable:
	.incbin "includes/generated/v7_transplant_AccStyle_LookupVelocityTable.bin"
AccStyle_Velocity_ExtendedRange:
	.incbin "includes/generated/v7_transplant_AccStyle_Velocity_ExtendedRange.bin"
AccStyle_Velocity_ExtClamp:
	.incbin "includes/generated/v7_transplant_AccStyle_Velocity_ExtClamp.bin"
AccStyle_Velocity_HighRange:
	.incbin "includes/generated/v7_transplant_AccStyle_Velocity_HighRange.bin"
AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x50FB
	ld wa, (xhl)

AccStyle_Velocity_StoreResult:
	.incbin "includes/generated/v7_transplant_AccStyle_Velocity_StoreResult.bin"
AccStyle_CheckRecordMode:
	.incbin "includes/generated/v7_transplant_AccStyle_CheckRecordMode.bin"
AccStyle_CheckRecordReturn:
	ret

AccStyle_DetectChanges:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges.bin"
AccStyle_DetectChanges_Init:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges_Init.bin"
AccStyle_DetectChanges_QueueDone:
	bitda 2, (0xfc60)
	jr z, AccStyle_DetectChanges_MarkDirty
	anddi8 (0xfc60), 251
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x6
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_MarkDirty:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges_MarkDirty.bin"
AccStyle_DetectChanges_CompareParams:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges_CompareParams.bin"
AccStyle_Compare_StyleNumber:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_StyleNumber.bin"
AccStyle_Compare_StyleNumDone:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_StyleNumDone.bin"
AccStyle_Compare_Variation:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_Variation.bin"
AccStyle_Compare_VariationDone:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_VariationDone.bin"
AccStyle_Compare_RegistrationFlag:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_RegistrationFlag.bin"
AccStyle_Compare_SplitA:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_SplitA.bin"
AccStyle_Compare_SplitADone:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_SplitADone.bin"
AccStyle_Compare_LayerA:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_LayerA.bin"
AccStyle_Compare_LayerADone:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_LayerADone.bin"
AccStyle_Compare_TuningState:
	.incbin "includes/generated/v7_transplant_AccStyle_Compare_TuningState.bin"
AccStyle_Compare_TuningDone:
	call AccTuning_Toggle

AccStyle_DetectChanges_Epilogue:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges_Epilogue.bin"
AccStyle_DetectChanges_ClearFlags:
	.incbin "includes/generated/v7_transplant_AccStyle_DetectChanges_ClearFlags.bin"
AccStyle_ApplyChanges:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyChanges.bin"
AccStyle_ApplyChanges_Extended:
	calr AccStyle_ApplyExtendedStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Finalize:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyChanges_Finalize.bin"
AccStyle_ResetAllVoiceState:
	.incbin "includes/generated/v7_transplant_AccStyle_ResetAllVoiceState.bin"
AccStyle_ApplyStandardStyle:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyStandardStyle.bin"
AccStyle_ApplyStd_LoadTuning:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyStd_LoadTuning.bin"
AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	.incbin "includes/generated/v7_transplant_AccStyle_SetupPartAddresses.bin"
AccStyle_ApplyExtendedStyle:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExtendedStyle.bin"
AccStyle_ApplyExt_ClampIndex:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_ClampIndex.bin"
AccStyle_ApplyExt_SkipClamp:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_SkipClamp.bin"
AccStyle_ApplyExt_CheckSplit:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_CheckSplit.bin"
AccStyle_ApplyExt_CheckBit0:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_CheckBit0.bin"
AccStyle_ApplyExt_CheckBit1:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_CheckBit1.bin"
AccStyle_ApplyExt_UseSecondary:
	calr AccStyle_UseSecondarySource
	jr AccStyle_ApplyExt_UpdateTuning


; -----------------------------------------------------------------------------
; Section: Sequence Processing & Voice Selection
; -----------------------------------------------------------------------------
; Sequence continuation and accompaniment voice
; part offset selection.
; -----------------------------------------------------------------------------

Seq_ProcessAndContinue:
	calr AccPart_ResetAndCopyTuning
	jr AccStyle_ApplyExt_UpdateTuning

AccStyle_ApplyExt_SelectPart:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_SelectPart.bin"
AccStyle_ApplyExt_UpdateTuning:
	.incbin "includes/generated/v7_transplant_AccStyle_ApplyExt_UpdateTuning.bin"
AccVoice_SelectPartOffset:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset.bin"
AccVoice_SelectPartOffset_Resolved:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset_Resolved.bin"
AccVoice_SelectPartOffset_Bound:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset_Bound.bin"
AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset_Apply63.bin"
AccVoice_SelectPartOffset_Bit1:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset_Bit1.bin"
AccVoice_SelectPartOffset_Mode3:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectPartOffset_Mode3.bin"
AccVoice_SelectPartOffset_Return:
	ret

AccStyle_SetupPartAddressesByHL:
	.incbin "includes/generated/v7_transplant_AccStyle_SetupPartAddressesByHL.bin"
AccStyle_UseSecondarySource:
	.incbin "includes/generated/v7_transplant_AccStyle_UseSecondarySource.bin"
AccStyle_UseSecondary_Resolve:
	.incbin "includes/generated/v7_transplant_AccStyle_UseSecondary_Resolve.bin"
AccStyle_UseSecondary_Mode3:
	.incbin "includes/generated/v7_transplant_AccStyle_UseSecondary_Mode3.bin"
AccStyle_UseSecondary_Return:
	ret


; -----------------------------------------------------------------------------
; Section: Accompaniment Part Management
; -----------------------------------------------------------------------------
; Part position initialization, buffer reset, tuning
; configuration, and style index lookup.
; -----------------------------------------------------------------------------

AccPart_InitPositionsAndBase:
	.incbin "includes/generated/v7_transplant_AccPart_InitPositionsAndBase.bin"
AccPart_ResetAndCopyTuning:
	.incbin "includes/generated/v7_transplant_AccPart_ResetAndCopyTuning.bin"
AccBuf_ResetAllPositions:
	.incbin "includes/generated/v7_transplant_AccBuf_ResetAllPositions.bin"
AccBuf_InitKbd1WithMarkers:
	.incbin "includes/generated/v7_transplant_AccBuf_InitKbd1WithMarkers.bin"
Rhythm_SendResetMsg:
	ldb a, 0xd8
	ldb w, 0x10
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	.incbin "includes/generated/v7_transplant_Rhythm_UpdateTuningConfig.bin"
Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, AccVoice_ParamIndexData_0x5B
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

Rhythm_LookupTuningRange:
	.incbin "includes/generated/v7_transplant_Rhythm_LookupTuningRange.bin"
Rhythm_LookupTuning_DefaultRange:
	ldb a, 0x39
	ldb w, 0x39

Rhythm_StoreTuningRange:
	.incbin "includes/generated/v7_transplant_Rhythm_StoreTuningRange.bin"
Rhythm_LookupStyleIndex:
	ld xhl, AccVoice_ParamIndexData_0x26
	cp w, 0x30
	jr c, Rhythm_LookupStyleIndex_Compute
	xor w, w

Rhythm_LookupStyleIndex_Compute:
	ldb_sri W, 0x03, 0xec, 0xe1
	and w, 0x3
	ld xhl, AccVoice_ParamIndexData_0x57
	ldb_sri L, 0x03, 0xec, 0xe1
	xor h, h
	ret

AccVoice_LookupParamIndex:
	push xhl
	ld xhl, AccVoice_ParamIndexData
	and wa, 0x3
	ldb_sri A, 0x07, 0xec, 0xe0
	pop xhl
	ret

AccVoice_ParamIndexData:
	nop
	pop	sr
	.byte 0x04
	reti
	add	hl, 994
	extz	wa
	.byte 0xd7
	ldw	wa, 0xd898
	.byte 0x83, 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	a, 201
	.byte 0xcf
	swi	7
	jr	nz, 12
	.byte 0xd7
	ldw	wa, 0xd888
	or	b, w
	pop	sr
	.byte 0xc3
	reti
	.byte 0xf4, 0xe0
	ldb	a, 14
	nop
	nop
	.byte 0x01, 0x01
	nop
	push	sr
	.byte 0x01, 0x01
	push	sr
	.byte 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	push	sr
	.byte 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x01, 0x01
	nop
	push	sr
	.zero 8
	ldio	4, 12
	nop
	halt
	ldwio	15, 6420
	calr	53795
	pop	sr
	.byte 0xd4
	pop	sr
	.byte 0xd6
	pop	sr
	ld	wa, 2002
	.byte 0xd4
	reti
	.byte 0xd6
	reti
	neg	wa

AccPart_GetVoiceParamOffsetTable:
	ld xhl, AccPart_VoiceParamDispatchTable
	ldb_erp W, 0x31
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xec, 0xe0
	stb_erp W, 0x31
	sla w, 1
	ldw_sri HL, 0x03, 0xec, 0xe1
	extz xhl
	ret

AccPart_VoiceParamDispatchTable:
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
AccPart_VoiceParamOffsets_BaseA:
	nop
	nop
	jr	le, 0
	.byte 0xc4
	nop
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_BaseB:
	ldw	bc, 0x9300
	nop
	.byte 0xf5
	nop
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordA:
	nop
	.byte 0x04
	jr	le, 4
	.byte 0xc4, 0x04
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordB:
	ldw	bc, 0x9304
	.byte 0x04, 0xf5, 0x04
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt

AccPart_LookupBoundVoiceParam:
	ld w, a
	calr AccStyle_ReadParamOffset
	ld xhl, AccStyle_ByteDataBlock_0xAC
	cp a, 0x14
	jr c, AccPart_LookupBound_ComputeIdx
	ld xhl, AccStyle_ByteDataBlock_0xBC

AccPart_LookupBound_ComputeIdx:
	sla w, 1
	ldw_sri HL, 0x03, 0xec, 0xe1
	ret

AccStyle_ReadParamOffset:
	.incbin "includes/generated/v7_transplant_AccStyle_ReadParamOffset.bin"
AccStyle_ReadParamOff_Part2:
	.incbin "includes/generated/v7_transplant_AccStyle_ReadParamOff_Part2.bin"
AccStyle_ReadParamOff_Part4:
	.incbin "includes/generated/v7_transplant_AccStyle_ReadParamOff_Part4.bin"
AccStyle_ReadParamOff_Part8:
	.incbin "includes/generated/v7_transplant_AccStyle_ReadParamOff_Part8.bin"
AccStyle_ReadParamOff_Part16:
	.incbin "includes/generated/v7_transplant_AccStyle_ReadParamOff_Part16.bin"
AccStyle_ReadParamOff_Part32:
	ldb_sri0 W, (xhl + 0x00a0)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	.incbin "includes/generated/v7_transplant_AccStyle_ByteDataBlock.bin"
AccVoice_ComputeParamAddr:
	.incbin "includes/generated/v7_transplant_AccVoice_ComputeParamAddr.bin"
AccVoice_ParamAddr_Range0F_14:
	.incbin "includes/generated/v7_transplant_AccVoice_ParamAddr_Range0F_14.bin"
AccVoice_ParamAddr_Range14_23:
	.incbin "includes/generated/v7_transplant_AccVoice_ParamAddr_Range14_23.bin"
AccVoice_ParamAddr_Range23Plus:
	.incbin "includes/generated/v7_transplant_AccVoice_ParamAddr_Range23Plus.bin"
AccVoice_ReturnExtHL:
	extz xhl
	ret

AccTuning_SetAllFromLookup:
	.incbin "includes/generated/v7_transplant_AccTuning_SetAllFromLookup.bin"
AccTuning_FetchValue:
	ld xhl, AccTuning_ValueTable
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

AccTuning_ValueTable:
	nop
	nop
	nop
	nop
	nop
	halt
	halt
	halt
	halt
	halt
	ldwio	10, 2570
	ldwio	15, 3855
	retd	0x140f
	push_a
	push_a
	push_a
	push_a
	pop_f
	pop_f
	pop_f
	pop_f
	pop_f
	.byte 0x1e, 0x1e
	calr	0x1e1e
	.ascii "#####"

AccVoice_ProcessAllSixParts:
	calr AccVoice_SavePartState1
	calr AccVoice_ProcessEventLoop
	calr AccVoice_RestorePartState1
	ret

AccVoice_SavePartState1:
	.incbin "includes/generated/v7_transplant_AccVoice_SavePartState1.bin"
AccVoice_RestorePartState1:
	.incbin "includes/generated/v7_transplant_AccVoice_RestorePartState1.bin"
AccVoice_ProcessEventLoop:
	.incbin "includes/generated/v7_transplant_AccVoice_ProcessEventLoop.bin"
AccVoice_EventLoop_Active:
	.incbin "includes/generated/v7_transplant_AccVoice_EventLoop_Active.bin"
AccVoice_EventLoop_Dispatch:
	.incbin "includes/generated/v7_transplant_AccVoice_EventLoop_Dispatch.bin"
AccVoice_EventLoop_Check81:
	cp a, 0x81
	jr nz, AccVoice_EventLoop_CheckNoteOn
	calr AccVoice_HandleBarEndEvent
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_CheckNoteOn:
	cp a, 0x90
	jr z, AccVoice_HandleEvent_D5
	cp a, 0x91
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd1
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd2
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd3
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd4
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd5
	jr nz, AccVoice_EventLoop_Unknown

AccVoice_HandleEvent_D5:
	calr AccVoice_HandleNoteOnEvent
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Unknown:
	calr AccVoice_AdvanceAndCheckEnd

AccVoice_EventProcessingReturn:
	jr AccVoice_ProcessEventLoop

AccVoice_EventLoop_Idle:
	ret

AccVoice_DispatchByChannel:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchByChannel.bin"
AccVoice_DispatchCh_Kbd2:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchCh_Kbd2.bin"
AccVoice_DispatchCh_Acc1:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchCh_Acc1.bin"
AccVoice_DispatchCh_Acc2:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchCh_Acc2.bin"
AccVoice_DispatchCh_Acc3:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchCh_Acc3.bin"
AccVoice_DispatchCh_Acc4:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchCh_Acc4.bin"
SoundPatch_NullRet:
	ret

AccVoice_AdvanceAndCheckEnd:
	.incbin "includes/generated/v7_transplant_AccVoice_AdvanceAndCheckEnd.bin"
AccVoice_AdvanceAndCheck_Return:
	ret

AccVoice_HandleNoteOnEvent:
	.incbin "includes/generated/v7_transplant_AccVoice_HandleNoteOnEvent.bin"
AccVoice_NoteOn_InRange:
	calr AccMidi_Dispatch

AccVoice_NoteOn_Return:
	ret

AccVoice_HandleBarEndEvent:
	.incbin "includes/generated/v7_transplant_AccVoice_HandleBarEndEvent.bin"
AccVoice_BarEnd_Process:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_Process.bin"
AccVoice_BarEnd_InRange:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_InRange.bin"
AccVoice_BarEnd_NextPage:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_NextPage.bin"
AccVoice_BarEnd_CheckChord94:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_CheckChord94.bin"
AccVoice_BarEnd_CheckChord65:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_CheckChord65.bin"
AccVoice_BarEnd_CheckChord95:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_CheckChord95.bin"
AccVoice_BarEnd_CheckSync69:
	.incbin "includes/generated/v7_transplant_AccVoice_BarEnd_CheckSync69.bin"
AccVoice_SetChordChangeFlags:
	.incbin "includes/generated/v7_transplant_AccVoice_SetChordChangeFlags.bin"
AccVoice_NullRet:
	ret

AccVoice_LookupTableAddress:
	ld xde, Display_FontPalette_Table_0x1D46
	and w, 0x7
	sla w, 1
	ldw_sri DE, 0x03, 0xe8, 0xe1
	xor w, w
	add de, wa
	ret

AccVoice_LookupExtParamAddr:
	ld xde, Display_FontPalette_Table_0x1D46
	and w, 0x7
	inc 1, w
	sla w, 1
	ldw_sri DE, 0x03, 0xe8, 0xe1
	ret

AccVoice_AdvanceWithSave:
	.incbin "includes/generated/v7_transplant_AccVoice_AdvanceWithSave.bin"
AccBuf_AdvanceNoPage:
	.incbin "includes/generated/v7_transplant_AccBuf_AdvanceNoPage.bin"
AccVoice_HandleMarker83:
	.incbin "includes/generated/v7_transplant_AccVoice_HandleMarker83.bin"
AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	.incbin "includes/generated/v7_transplant_AccVoice_Marker83_CheckDeact.bin"
AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	.incbin "includes/generated/v7_transplant_AccVoice_ActivatePart.bin"
AccVoice_ActivatePart_Return:
	ret

AccVoice_ActivateByteData:
	.incbin "includes/generated/v7_transplant_AccVoice_ActivateByteData.bin"
AccPart_SelectSourceOrParam:
	.incbin "includes/generated/v7_transplant_AccPart_SelectSourceOrParam.bin"
AccPart_SelectSource_Param:
	calr AccPart_LoadParamOffsetTable

AccPart_SelectSource_Done:
	.incbin "includes/generated/v7_transplant_AccPart_SelectSource_Done.bin"
AccPart_AdvanceAndResolve:
	.incbin "includes/generated/v7_transplant_AccPart_AdvanceAndResolve.bin"
AccPart_AdvanceResolve_Done:
	calr AccPart_ResolveStyleAddr
	ret

AccPart_ResolveStyleAddr:
	.incbin "includes/generated/v7_transplant_AccPart_ResolveStyleAddr.bin"
AccPart_ResolveStyle_Bound:
	.incbin "includes/generated/v7_transplant_AccPart_ResolveStyle_Bound.bin"
AccPart_ResolveStyle_Return:
	ret

AccPart_IncrementIndex:
	.incbin "includes/generated/v7_transplant_AccPart_IncrementIndex.bin"
AccPart_IncrementIndex_Return:
	ret

AccPart_ResolveWithPedal:
	.incbin "includes/generated/v7_transplant_AccPart_ResolveWithPedal.bin"
AccPart_ResolveWithPedal_DirB:
	.incbin "includes/generated/v7_transplant_AccPart_ResolveWithPedal_DirB.bin"
AccPart_ResolveWithPedal_Bound:
	.incbin "includes/generated/v7_transplant_AccPart_ResolveWithPedal_Bound.bin"
AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	.incbin "includes/generated/v7_transplant_AccPart_LoadParamOffsetTable.bin"
AccPart_LoadTuningByChannel:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuningByChannel.bin"
AccPart_LoadTuning_Kbd2:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuning_Kbd2.bin"
AccPart_LoadTuning_Acc1:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuning_Acc1.bin"
AccPart_LoadTuning_Acc2:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuning_Acc2.bin"
AccPart_LoadTuning_Acc3:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuning_Acc3.bin"
AccPart_LoadTuning_Acc4:
	.incbin "includes/generated/v7_transplant_AccPart_LoadTuning_Acc4.bin"
AccPart_NullRet:
	ret

AccPart_GetFreeVoiceAddr:
	.incbin "includes/generated/v7_transplant_AccPart_GetFreeVoiceAddr.bin"
AccPart_FreeAddr_Kbd2:
	.incbin "includes/generated/v7_transplant_AccPart_FreeAddr_Kbd2.bin"
AccPart_FreeAddr_Acc1:
	.incbin "includes/generated/v7_transplant_AccPart_FreeAddr_Acc1.bin"
AccPart_FreeAddr_Acc2:
	.incbin "includes/generated/v7_transplant_AccPart_FreeAddr_Acc2.bin"
AccPart_FreeAddr_Acc3:
	.incbin "includes/generated/v7_transplant_AccPart_FreeAddr_Acc3.bin"
AccPart_FreeAddr_Acc4:
	.incbin "includes/generated/v7_transplant_AccPart_FreeAddr_Acc4.bin"
AccPart_CheckEndOfDataMarker:
	.incbin "includes/generated/v7_transplant_AccPart_CheckEndOfDataMarker.bin"
AccPart_FreeAddr_Return:
	ret

; ============================================================================
; AccPart_GetParamAddr - Get parameter address for accompaniment part
; ============================================================================
; Input:  HL = base pointer, channel selector bitmask at 13268
; Output: WA = parameter address for the selected part
; Adds per-part offset (0x118-0x1d6) based on channel (kbd/acc1-5).
; ============================================================================
AccPart_GetParamAddr:
	.incbin "includes/generated/v7_transplant_AccPart_GetParamAddr.bin"
AccPart_ParamAddr_Kbd2:
	.incbin "includes/generated/v7_transplant_AccPart_ParamAddr_Kbd2.bin"
AccPart_ParamAddr_Acc1:
	.incbin "includes/generated/v7_transplant_AccPart_ParamAddr_Acc1.bin"
AccPart_ParamAddr_Acc2:
	.incbin "includes/generated/v7_transplant_AccPart_ParamAddr_Acc2.bin"
AccPart_ParamAddr_Acc3:
	.incbin "includes/generated/v7_transplant_AccPart_ParamAddr_Acc3.bin"
AccPart_ParamAddr_Acc4:
	.incbin "includes/generated/v7_transplant_AccPart_ParamAddr_Acc4.bin"
AccPart_SubtractBaseAddr:
	sub wa, 0x8000
	add wa, 0x6
	ret

AccPart_SelectSource:
	.incbin "includes/generated/v7_transplant_AccPart_SelectSource.bin"
AccPart_SelectKbd:
	.incbin "includes/generated/v7_transplant_AccPart_SelectKbd.bin"
AccPart_CheckAcc1:
	.incbin "includes/generated/v7_transplant_AccPart_CheckAcc1.bin"
AccPart_CheckAcc2:
	.incbin "includes/generated/v7_transplant_AccPart_CheckAcc2.bin"
AccPart_CheckAcc3:
	.incbin "includes/generated/v7_transplant_AccPart_CheckAcc3.bin"
AccPart_CheckAcc4:
	.incbin "includes/generated/v7_transplant_AccPart_CheckAcc4.bin"
AccPart_CopyData:
	.incbin "includes/generated/v7_transplant_AccPart_CopyData.bin"
AccPart_CheckAnyActive:
	.incbin "includes/generated/v7_transplant_AccPart_CheckAnyActive.bin"
AccPedal_DirectionA:
	.incbin "includes/generated/v7_transplant_AccPedal_DirectionA.bin"
AccPedal_DirA_CheckBit1:
	.incbin "includes/generated/v7_transplant_AccPedal_DirA_CheckBit1.bin"
AccPedal_DirA_SetForward:
	.incbin "includes/generated/v7_transplant_AccPedal_DirA_SetForward.bin"
AccPedal_DirA_SetReverse:
	.incbin "includes/generated/v7_transplant_AccPedal_DirA_SetReverse.bin"
AccPedal_DirA_Apply:
	.incbin "includes/generated/v7_transplant_AccPedal_DirA_Apply.bin"
AccPedal_DirectionB:
	.incbin "includes/generated/v7_transplant_AccPedal_DirectionB.bin"
AccPedal_DirB_CheckBit0:
	.incbin "includes/generated/v7_transplant_AccPedal_DirB_CheckBit0.bin"
AccPedal_DirB_InvertAndStore:
	.incbin "includes/generated/v7_transplant_AccPedal_DirB_InvertAndStore.bin"
AccPedal_DirB_Alternate:
	.incbin "includes/generated/v7_transplant_AccPedal_DirB_Alternate.bin"
AccPedal_DirB_DefaultStyle:
	.incbin "includes/generated/v7_transplant_AccPedal_DirB_DefaultStyle.bin"
AccPedal_DirB_Return:
	ret

AccMidi_Dispatch:
	calr AccMidi_NormalizeVelocity
	cp a, 0x90
	jr z, AccMidi_NoteEvent
	cp a, 0x91
	jr z, AccMidi_NoteEvent
	cp a, 0xd1
	jr z, AccMidi_ControlEvent
	cp a, 0xd2
	jr z, AccMidi_ControlEvent
	cp a, 0xd3
	jr z, AccMidi_ControlEvent
	cp a, 0xd4
	jr z, AccMidi_ControlEvent
	cp a, 0xd5
	jr z, AccMidi_ControlEvent

AccMidi_NoteEvent:
	calr AccMidi_ParseNoteOn
	calr AccMidi_SelectVelocitySource
	calr AccMidi_DispatchPerPart
	jr AccMidi_DispatchReturn

AccMidi_ControlEvent:
	call AccMidi_ParseDType
	calr AccMidi_SelectVelocitySource
	call AccMidi_DispatchDType

AccMidi_DispatchReturn:
	ret

AccMidi_NormalizeVelocity:
	cps a, 0
	jr nz, AccMidi_VelNonZero
	ldb a, 0x1

AccMidi_VelNonZero:
	.incbin "includes/generated/v7_transplant_AccMidi_VelNonZero.bin"
AccMidi_ParseNoteOn:
	.incbin "includes/generated/v7_transplant_AccMidi_ParseNoteOn.bin"
AccMidi_ParseNoteOn_StorePos:
	.incbin "includes/generated/v7_transplant_AccMidi_ParseNoteOn_StorePos.bin"
AccMidi_ParseCommon:
	.incbin "includes/generated/v7_transplant_AccMidi_ParseCommon.bin"
AccMidi_ParseCommon_ExtraFields:
	.incbin "includes/generated/v7_transplant_AccMidi_ParseCommon_ExtraFields.bin"
AccMidi_SelectVelocitySource:
	.incbin "includes/generated/v7_transplant_AccMidi_SelectVelocitySource.bin"
AccMidi_VelSource_Active:
	.incbin "includes/generated/v7_transplant_AccMidi_VelSource_Active.bin"
AccMidi_VelSource_Store:
	.incbin "includes/generated/v7_transplant_AccMidi_VelSource_Store.bin"
AccMidi_DispatchPerPart:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchPerPart.bin"
AccMidi_DispatchKbd2:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchKbd2.bin"
AccMidi_DispatchAcc1:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchAcc1.bin"
AccMidi_DispatchAcc2:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchAcc2.bin"
AccMidi_DispatchAcc3:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchAcc3.bin"
AccMidi_DispatchAcc4:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchAcc4.bin"
AccMidi_DispatchAcc4Return:
	ret

AccKbd1_RingBufEntry:
	.incbin "includes/generated/v7_transplant_AccKbd1_RingBufEntry.bin"
AccKbd1_RingBufReturn:
	ret

AccKbd1_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccKbd1_CheckEligible.bin"
AccKbd1_CheckRecording:
	.incbin "includes/generated/v7_transplant_AccKbd1_CheckRecording.bin"
AccKbd1_CheckReturn:
	ret

AccBuf_WriteNoteEvent:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteNoteEvent.bin"
AccBuf_WriteNote_VelNonZero:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteNote_VelNonZero.bin"
AccBuf_ComputeFillLevel:
	ld wa, (xhl + 6)
	cp wa, (xhl + 4)
	jr c, AccBuf_FillLevel_Wrapped
	jr ugt, AccBuf_FillLevel_Simple
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Wrapped:
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	sub wa, (xhl + 4)
	add wa, (xhl + 6)
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Simple:
	sub wa, (xhl + 4)

AccBuf_FillLevel_Store:
	.incbin "includes/generated/v7_transplant_AccBuf_FillLevel_Store.bin"
AccTempo_PositionCompare:
	.incbin "includes/generated/v7_transplant_AccTempo_PositionCompare.bin"
AccTempo_SameBar:
	sub de, bc
	ld a, e
	cps d, 0
	jr z, AccTempo_Return
	ldb a, 0x60
	jr AccTempo_Return

AccTempo_DiffBar:
	.incbin "includes/generated/v7_transplant_AccTempo_DiffBar.bin"
AccTempo_BarZero:
	.incbin "includes/generated/v7_transplant_AccTempo_BarZero.bin"
AccTempo_TooFar:
	ldb a, 0x0
	jr AccTempo_Return

AccTempo_ComputeDelta:
	xor xwa, xwa
	ldb_d8 a, (1112)
	sla a, 1
	add xwa, Display_FontPalette_Table_0x1D46
	add de, (xwa)
	sub de, bc
	ld a, e
	cps d, 0
	jr z, AccTempo_Return
	ldb a, 0x60

AccTempo_Return:
	ret

AccKbd1_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccKbd1_ProcessNotes.bin"
AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	.incbin "includes/generated/v7_transplant_AccKbd1_TimingCheck.bin"
AccKbd1_TimingOK:
	.incbin "includes/generated/v7_transplant_AccKbd1_TimingOK.bin"
AccKbd1_TimingReturn:
	ret

AccKbd1_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccKbd1_ScanSlots.bin"
AccKbd1_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccKbd1_ScanSlots_Loop.bin"
AccSlot_CheckAndUpdate:
	.incbin "includes/generated/v7_transplant_AccSlot_CheckAndUpdate.bin"
AccSlot_TimingZero:
	xor wa, wa

AccSlot_CompareAndUpdate:
	.incbin "includes/generated/v7_transplant_AccSlot_CompareAndUpdate.bin"
AccSlot_RestoreInterrupts:
	ei 0

AccSlot_Return:
	ret

AccKbd1_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccKbd1_DrainRingBuf.bin"
AccKbd1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd1_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccKbd1_DrainSkip
	calr AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	jr AccKbd1_DrainLoop

AccKbd1_DrainSkip:
	call RingBuf_AdvanceIndex
	jr AccKbd1_DrainLoop

AccKbd1_DrainDone:
	ret

AccBuf_ProcessNoteEvent:
	call RingBuf_AdvanceIndex
	ldb_sri W, 0x07, 0xec, 0xf4
	call Rhythm_AdvancePosition
	ldb_sri E, 0x07, 0xec, 0xf4
	pushw iy
	inc 1, iy
	cp iy, bc
	jr ule, AccBuf_NoteEvent_WrapPos
	ld iy, (xhl + 256)

AccBuf_NoteEvent_WrapPos:
	.incbin "includes/generated/v7_transplant_AccBuf_NoteEvent_WrapPos.bin"
AccBuf_NoteEvent_StoreTiming:
	xor w, w
	cp de, wa
	jr ule, AccBuf_NoteEvent_SkipTiming
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	lda_dri XWA, 0x07, 0xec, 0xf4
	jr AccBuf_NoteEvent_Return

AccBuf_NoteEvent_SkipTiming:
	call RingBuf_AdvanceIndex

AccBuf_NoteEvent_Return:
	ei 0
	ret

AccKbd2_CheckActive:
	.incbin "includes/generated/v7_transplant_AccKbd2_CheckActive.bin"
AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	.incbin "includes/generated/v7_transplant_AccKbd2_SaveState.bin"
AccKbd2_RestoreState:
	.incbin "includes/generated/v7_transplant_AccKbd2_RestoreState.bin"
AccKbd2_RingBufEntry:
	.incbin "includes/generated/v7_transplant_AccKbd2_RingBufEntry.bin"
AccKbd2_RingBufReturn:
	ret

AccKbd2_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccKbd2_CheckEligible.bin"
AccKbd2_CheckReturn:
	ret

AccKbd2_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccKbd2_ProcessNotes.bin"
AccKbd2_ProcessReturn:
	ret

AccKbd2_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccKbd2_ScanSlots.bin"
AccKbd2_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccKbd2_ScanSlots_Loop.bin"
AccKbd2_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccKbd2_DrainRingBuf.bin"
AccKbd2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd2_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccKbd2_DrainSkip
	calr AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	jr AccKbd2_DrainLoop

AccKbd2_DrainSkip:
	call RingBuf_AdvanceIndex
	jr AccKbd2_DrainLoop

AccKbd2_DrainDone:
	ret

AccSeq_ScanPattern:
	.incbin "includes/generated/v7_transplant_AccSeq_ScanPattern.bin"
AccSeq_ScanLoop:
	.incbin "includes/generated/v7_transplant_AccSeq_ScanLoop.bin"
AccSeq_CheckMarker81:
	cp a, 0x81
	jr z, AccSeq_EndOfBar
	cp a, 0x90
	jr z, AccSeq_NoteOn90
	calr AccSeq_AdvancePointer
	jr AccSeq_ScanLoop

AccSeq_NoteOn90:
	.incbin "includes/generated/v7_transplant_AccSeq_NoteOn90.bin"
AccSeq_NoteOn_TooFar:
	.incbin "includes/generated/v7_transplant_AccSeq_NoteOn_TooFar.bin"
AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	.incbin "includes/generated/v7_transplant_AccSeq_EndOfBar.bin"
AccSeq_EndOfBar_Process:
	.incbin "includes/generated/v7_transplant_AccSeq_EndOfBar_Process.bin"
AccSeq_NextBarPage:
	.incbin "includes/generated/v7_transplant_AccSeq_NextBarPage.bin"
AccSeq_EndOfBar_TooFar:
	.incbin "includes/generated/v7_transplant_AccSeq_EndOfBar_TooFar.bin"
AccSeq_ScanDone:
	ret

AccSeq_ReadNextByte:
	.incbin "includes/generated/v7_transplant_AccSeq_ReadNextByte.bin"
AccSeq_AdvancePointer:
	.incbin "includes/generated/v7_transplant_AccSeq_AdvancePointer.bin"
AccSeq_ResetToStart:
	.incbin "includes/generated/v7_transplant_AccSeq_ResetToStart.bin"
AccSeq_ParseNoteEvent:
	cps a, 0
	jr nz, AccSeq_ParseNote_VelNonZero
	ldb a, 0x1

AccSeq_ParseNote_VelNonZero:
	.incbin "includes/generated/v7_transplant_AccSeq_ParseNote_VelNonZero.bin"
AccSeq_ParseNote_CheckMode:
	.incbin "includes/generated/v7_transplant_AccSeq_ParseNote_CheckMode.bin"
AccSeq_ParseNote_CheckRec:
	.incbin "includes/generated/v7_transplant_AccSeq_ParseNote_CheckRec.bin"
AccSeq_ParseNote_WriteToKbd2:
	.incbin "includes/generated/v7_transplant_AccSeq_ParseNote_WriteToKbd2.bin"
AccSeq_ParseNote_Return:
	ret

AccCh1_ProcessEntry:
	calr AccCh1_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh1_RestoreState
	ret

AccCh1_SaveState:
	.incbin "includes/generated/v7_transplant_AccCh1_SaveState.bin"
AccCh1_RestoreState:
	.incbin "includes/generated/v7_transplant_AccCh1_RestoreState.bin"
AccVoice_AssignPerPart:
	.incbin "includes/generated/v7_transplant_AccVoice_AssignPerPart.bin"
AccVoice_AssignReturn:
	ret

AccVoice_ScanInstruments:
	.incbin "includes/generated/v7_transplant_AccVoice_ScanInstruments.bin"
AccVoice_ScanLoop:
	.incbin "includes/generated/v7_transplant_AccVoice_ScanLoop.bin"
AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	.incbin "includes/generated/v7_transplant_AccVoice_SendProgChange.bin"
AccVoice_SendD4:
	.incbin "includes/generated/v7_transplant_AccVoice_SendD4.bin"
AccVoice_SendD5:
	.incbin "includes/generated/v7_transplant_AccVoice_SendD5.bin"
AccVoice_SendD6:
	.incbin "includes/generated/v7_transplant_AccVoice_SendD6.bin"
AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	.incbin "includes/generated/v7_transplant_AccBuf_Write3ByteEvent.bin"
AccCh1_Padding:
	nop
	nop

AccCh1_NoteOnEntry:
	.incbin "includes/generated/v7_transplant_AccCh1_NoteOnEntry.bin"
AccCh1_NoteOnReturn:
	ret

AccCh1_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccCh1_CheckEligible.bin"
AccCh1_SetReady:
	.incbin "includes/generated/v7_transplant_AccCh1_SetReady.bin"
AccCh1_CheckReturn:
	ret

AccBuf_WriteExtendedEvent:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteExtendedEvent.bin"
AccBuf_ExtEvt_VelNonZero:
	.incbin "includes/generated/v7_transplant_AccBuf_ExtEvt_VelNonZero.bin"
AccBuf_ExtEvt_WriteExtra:
	.incbin "includes/generated/v7_transplant_AccBuf_ExtEvt_WriteExtra.bin"
AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	.incbin "includes/generated/v7_transplant_AccVoice_CheckStyle.bin"
AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	.incbin "includes/generated/v7_transplant_AccVoice_CorrectionData.bin"
AccVoice_CorrectNote:
	.incbin "includes/generated/v7_transplant_AccVoice_CorrectNote.bin"
AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	.incbin "includes/generated/v7_transplant_AccVoice_VelocityLookup.bin"
AccVoice_UseVoiceMap:
	call Rhythm_VoiceMapLookup

AccVoice_CorrectReturn:
	popw iy
	pop xhl
	ret

AccMidi_ParseDType:
	.incbin "includes/generated/v7_transplant_AccMidi_ParseDType.bin"
AccMidi_DispatchDType:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchDType.bin"
AccMidi_DType_CheckKbd2:
	.incbin "includes/generated/v7_transplant_AccMidi_DType_CheckKbd2.bin"
AccMidi_DType_CheckAcc1:
	.incbin "includes/generated/v7_transplant_AccMidi_DType_CheckAcc1.bin"
AccMidi_DType_CheckAcc2:
	.incbin "includes/generated/v7_transplant_AccMidi_DType_CheckAcc2.bin"
AccMidi_DType_CheckAcc3:
	.incbin "includes/generated/v7_transplant_AccMidi_DType_CheckAcc3.bin"
AccMidi_DType_CheckAcc4:
	.incbin "includes/generated/v7_transplant_AccMidi_DType_CheckAcc4.bin"
AccMidi_DType_Return:
	ret

AccCh1_DTypeEntry:
	.incbin "includes/generated/v7_transplant_AccCh1_DTypeEntry.bin"
AccCh1_DTypeReturn:
	ret

AccCh_CheckOverlap:
	.incbin "includes/generated/v7_transplant_AccCh_CheckOverlap.bin"
AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	.incbin "includes/generated/v7_transplant_AccBuf_InitWithDefaults.bin"
AccCh1_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccCh1_ProcessNotes.bin"
AccCh1_ProcessReturn:
	ret

AccCh1_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccCh1_ScanSlots.bin"
AccCh1_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccCh1_ScanSlots_Loop.bin"
AccCh1_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccCh1_DrainRingBuf.bin"
AccCh1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh1_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccCh1_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh1_DrainLoop

AccCh1_DrainType91:
	cp a, 0x91
	jr nz, AccCh1_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh1_DrainLoop

AccCh1_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh1_DrainLoop

AccCh1_DrainDone:
	ret

AccCh2_ProcessEntry:
	calr AccCh2_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh2_RestoreState
	ret

AccCh2_SaveState:
	.incbin "includes/generated/v7_transplant_AccCh2_SaveState.bin"
AccCh2_RestoreState:
	.incbin "includes/generated/v7_transplant_AccCh2_RestoreState.bin"
AccCh2_NoteOnEntry:
	.incbin "includes/generated/v7_transplant_AccCh2_NoteOnEntry.bin"
AccCh2_NoteOnReturn:
	ret

AccCh2_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccCh2_CheckEligible.bin"
AccCh2_SetReady:
	.incbin "includes/generated/v7_transplant_AccCh2_SetReady.bin"
AccCh2_CheckReturn:
	ret

AccCh2_DTypeEntry:
	.incbin "includes/generated/v7_transplant_AccCh2_DTypeEntry.bin"
AccCh2_DTypeReturn:
	ret

AccCh2_CheckOverlap:
	.incbin "includes/generated/v7_transplant_AccCh2_CheckOverlap.bin"
AccCh2_OverlapReturn:
	ret

AccCh2_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccCh2_ProcessNotes.bin"
AccCh2_ProcessReturn:
	ret

AccCh2_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccCh2_ScanSlots.bin"
AccCh2_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccCh2_ScanSlots_Loop.bin"
AccCh2_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccCh2_DrainRingBuf.bin"
AccCh2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh2_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccCh2_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh2_DrainLoop

AccCh2_DrainType91:
	cp a, 0x91
	jr nz, AccCh2_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh2_DrainLoop

AccCh2_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh2_DrainLoop

AccCh2_DrainDone:
	ret

AccCh3_ProcessEntry:
	calr AccCh3_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh3_RestoreState
	ret

AccCh3_SaveState:
	.incbin "includes/generated/v7_transplant_AccCh3_SaveState.bin"
AccCh3_RestoreState:
	.incbin "includes/generated/v7_transplant_AccCh3_RestoreState.bin"
AccCh3_NoteOnEntry:
	.incbin "includes/generated/v7_transplant_AccCh3_NoteOnEntry.bin"
AccCh3_NoteOnReturn:
	ret

AccCh3_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccCh3_CheckEligible.bin"
AccCh3_SetReady:
	.incbin "includes/generated/v7_transplant_AccCh3_SetReady.bin"
AccCh3_CheckReturn:
	ret

AccCh3_DTypeEntry:
	.incbin "includes/generated/v7_transplant_AccCh3_DTypeEntry.bin"
AccCh3_DTypeReturn:
	ret

AccCh3_CheckOverlap:
	.incbin "includes/generated/v7_transplant_AccCh3_CheckOverlap.bin"
AccCh3_OverlapReturn:
	ret

AccCh3_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccCh3_ProcessNotes.bin"
AccCh3_ProcessReturn:
	ret

AccCh3_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccCh3_ScanSlots.bin"
AccCh3_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccCh3_ScanSlots_Loop.bin"
AccCh3_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccCh3_DrainRingBuf.bin"
AccCh3_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh3_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccCh3_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh3_DrainLoop

AccCh3_DrainType91:
	cp a, 0x91
	jr nz, AccCh3_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh3_DrainLoop

AccCh3_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh3_DrainLoop

AccCh3_DrainDone:
	ret

AccCh4_ProcessEntry:
	calr AccCh4_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh4_RestoreState
	ret

AccCh4_SaveState:
	.incbin "includes/generated/v7_transplant_AccCh4_SaveState.bin"
AccCh4_RestoreState:
	.incbin "includes/generated/v7_transplant_AccCh4_RestoreState.bin"
AccCh4_NoteOnEntry:
	.incbin "includes/generated/v7_transplant_AccCh4_NoteOnEntry.bin"
AccCh4_NoteOnReturn:
	ret

AccCh4_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccCh4_CheckEligible.bin"
AccCh4_SetReady:
	.incbin "includes/generated/v7_transplant_AccCh4_SetReady.bin"
AccCh4_CheckReturn:
	ret

AccCh4_DTypeEntry:
	.incbin "includes/generated/v7_transplant_AccCh4_DTypeEntry.bin"
AccCh4_DTypeReturn:
	ret

AccCh4_CheckOverlap:
	.incbin "includes/generated/v7_transplant_AccCh4_CheckOverlap.bin"
AccCh4_OverlapReturn:
	ret

AccCh4_ProcessNotes:
	.incbin "includes/generated/v7_transplant_AccCh4_ProcessNotes.bin"
AccCh4_ProcessReturn:
	ret

AccCh4_ScanSlots:
	.incbin "includes/generated/v7_transplant_AccCh4_ScanSlots.bin"
AccCh4_ScanSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccCh4_ScanSlots_Loop.bin"
AccCh4_DrainRingBuf:
	.incbin "includes/generated/v7_transplant_AccCh4_DrainRingBuf.bin"
AccCh4_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh4_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, AccCh4_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh4_DrainLoop

AccCh4_DrainType91:
	cp a, 0x91
	jr nz, AccCh4_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh4_DrainLoop

AccCh4_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh4_DrainLoop

AccCh4_DrainDone:
	ret

AccCh1_InitProgChange:
	.incbin "includes/generated/v7_transplant_AccCh1_InitProgChange.bin"
AccCh2_InitProgChange:
	.incbin "includes/generated/v7_transplant_AccCh2_InitProgChange.bin"
AccCh3_InitProgChange:
	.incbin "includes/generated/v7_transplant_AccCh3_InitProgChange.bin"
AccCh4_InitProgChange:
	.incbin "includes/generated/v7_transplant_AccCh4_InitProgChange.bin"
AccBuf_WriteD0Defaults:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteD0Defaults.bin"
AccPart_Deactivate:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate.bin"
AccPart_Deactivate_WithPedal:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_WithPedal.bin"
AccPart_Deactivate_NoPedal:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_NoPedal.bin"
AccPart_Deactivate_WithSync:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_WithSync.bin"
AccPart_Deactivate_ActiveNote:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_ActiveNote.bin"
AccPart_Deactivate_SetDone:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_SetDone.bin"
AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	.incbin "includes/generated/v7_transplant_AccPart_Deactivate_ClearMasks.bin"
AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	.incbin "includes/generated/v7_transplant_AccPart_Reactivate.bin"
AccPart_Reactivate_Inactive:
	.incbin "includes/generated/v7_transplant_AccPart_Reactivate_Inactive.bin"
AccPart_ReactivateReturn:
	ret

AccTick_Main:
	.incbin "includes/generated/v7_transplant_AccTick_Main.bin"
AccTick_AfterSync:
	.incbin "includes/generated/v7_transplant_AccTick_AfterSync.bin"
AccTick_ProcessAccChannels:
	call AccCh1_ProcessEntry
	call AccCh2_ProcessEntry
	call AccCh3_ProcessEntry
	call AccCh4_ProcessEntry

AccTick_CheckNoteOn:
	.incbin "includes/generated/v7_transplant_AccTick_CheckNoteOn.bin"
AccTick_DispatchNoteOn:
	call AccFlags_Aggregate

AccTick_FlushAndRepeat:
	call AccNote_FlushAll
	jrl AccTick_AfterSync

AccTick_CheckCollect:
	.incbin "includes/generated/v7_transplant_AccTick_CheckCollect.bin"
AccTick_Return:
	ret

AccVelocity_CurveTable:
	.byte 0x0d, 0x1a, 0x33, 0x4d, 0x66, 0x80, 0x9a, 0xb3
	.byte 0xcc, 0xe6, 0xff

AccVoice_InitPerChannel:
	.incbin "includes/generated/v7_transplant_AccVoice_InitPerChannel.bin"
AccVoice_InitCh2:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh2.bin"
AccVoice_InitCh3:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh3.bin"
AccVoice_InitCh4:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh4.bin"
AccVoice_InitReturn:
	ret

AccVoice_InitCh1_D7:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh1_D7.bin"
AccBuf_WriteD0WithVoice:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteD0WithVoice.bin"
AccVoice_InitCh2_D4:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh2_D4.bin"
AccVoice_InitCh3_D5:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh3_D5.bin"
AccVoice_InitCh4_D6:
	.incbin "includes/generated/v7_transplant_AccVoice_InitCh4_D6.bin"
AccPedal_CheckCombined:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckCombined.bin"
AccPedal_CheckFlags:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckFlags.bin"
AccPedal_CheckDirection:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckDirection.bin"
AccPedal_CheckCounter:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckCounter.bin"
AccPedal_TriggerReInit:
	calr AccInit_FullReInit

AccPedal_CombinedReturn:
	ret

AccTick_ByteData:
	.incbin "includes/generated/v7_transplant_AccTick_ByteData.bin"
AccTempo_BarCompare:
	.incbin "includes/generated/v7_transplant_AccTempo_BarCompare.bin"
AccTempo_BarLess:
	.incbin "includes/generated/v7_transplant_AccTempo_BarLess.bin"
AccTempo_BarEqual:
	.incbin "includes/generated/v7_transplant_AccTempo_BarEqual.bin"
AccTempo_BarGreater:
	.incbin "includes/generated/v7_transplant_AccTempo_BarGreater.bin"
AccTempo_BarChanged:
	ldb a, 0x1
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	.incbin "includes/generated/v7_transplant_AccTempo_ComputeSubDelta.bin"
AccTempo_StoreDelta:
	.incbin "includes/generated/v7_transplant_AccTempo_StoreDelta.bin"
AccSeq_DualPartScan:
	.incbin "includes/generated/v7_transplant_AccSeq_DualPartScan.bin"
AccSeq_DualPartReturn:
	ret

AccSeq_PatternScanner:
	.incbin "includes/generated/v7_transplant_AccSeq_PatternScanner.bin"
AccSeq_ScannerLoop:
	.incbin "includes/generated/v7_transplant_AccSeq_ScannerLoop.bin"
AccSeq_Scanner_BarEnd:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_BarEnd.bin"
AccSeq_Scanner_StorePos:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_StorePos.bin"
AccSeq_Scanner_EventType:
	cp a, 0x90
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0x91
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd1
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd2
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd3
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd4
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd5
	jr z, AccSeq_Scanner_EventMatch
	jr nz, AccSeq_Scanner_Unknown

AccSeq_Scanner_EventMatch:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_EventMatch.bin"
AccSeq_Scanner_SkipFields:
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd3
	jr z, AccSeq_Scanner_D3Voice
	cp a, 0x90
	jr nz, AccSeq_Scanner_Skip91
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Skip91:
	cp a, 0x91
	jr nz, AccSeq_Scanner_SkipOther
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_SkipOther:
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_D3Voice:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_D3Voice.bin"
AccSeq_Scanner_Unknown:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_Unknown.bin"
AccSeq_Scanner_Skip1:
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Done:
	.incbin "includes/generated/v7_transplant_AccSeq_Scanner_Done.bin"
AccSeq_ScannerPadding:
	nop
	nop

AccBuf_AdvanceWithPageTurn:
	pushw iy
	inc 1, iy
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, AccBuf_AdvanceReturn
	push xhl
	pushw iz
	ld iz, (xhl + 3)
	calr AccWave_BankResolve
	ld a, (xhl + 6)
	popw iz
	pop xhl

AccBuf_AdvanceReturn:
	popw iy
	ret

AccBuf_Advance:
	inc 1, iy
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, AccBuf_AdvanceSimpleReturn
	ld hl, (xhl + 3)
	ld iz, hl
	calr AccWave_BankResolve
	lds iy, 6

AccBuf_AdvanceSimpleReturn:
	ret

AccSeq_FourChannelScan:
	.incbin "includes/generated/v7_transplant_AccSeq_FourChannelScan.bin"
AccSeq_FourChannelReturn:
	ret

AccStyle_Init:
	.incbin "includes/generated/v7_transplant_AccStyle_Init.bin"
AccStyle_ExtendedInit:
	.incbin "includes/generated/v7_transplant_AccStyle_ExtendedInit.bin"
AccStyle_LookupTable:
	.incbin "includes/generated/v7_transplant_AccStyle_LookupTable.bin"
AccStyle_LoadAndApply:
	.incbin "includes/generated/v7_transplant_AccStyle_LoadAndApply.bin"
AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr AccInit_ClearAllFlags

AccInit_ClearAllFlags:
	.incbin "includes/generated/v7_transplant_AccInit_ClearAllFlags.bin"
AccVoice_SetupAllParts:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAllParts.bin"
AccVoice_SetupAll_Extended:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAll_Extended.bin"
AccVoice_SetupAll_Dispatch:
	calr AccVoice_SetupKbd1
	calr AccVoice_SetupKbd2
	calr AccVoice_SetupAcc1
	calr AccVoice_SetupAcc2
	calr AccVoice_SetupAcc3
	calr AccVoice_SetupAcc4
	ret

AccVoice_SetupKbd1:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupKbd1.bin"
AccVoice_SetupKbd1_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupKbd1_Free.bin"
AccVoice_SetupKbd1_Return:
	ret

AccVoice_SetupKbd2:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupKbd2.bin"
AccVoice_SetupKbd2_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupKbd2_Free.bin"
AccVoice_SetupKbd2_Return:
	ret

AccVoice_SetupAcc1:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc1.bin"
AccVoice_SetupAcc1_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc1_Free.bin"
AccVoice_SetupAcc1_Return:
	ret

AccVoice_SetupAcc2:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc2.bin"
AccVoice_SetupAcc2_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc2_Free.bin"
AccVoice_SetupAcc2_Return:
	ret

AccVoice_SetupAcc3:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc3.bin"
AccVoice_SetupAcc3_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc3_Free.bin"
AccVoice_SetupAcc3_Return:
	ret

AccVoice_SetupAcc4:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc4.bin"
AccVoice_SetupAcc4_Free:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupAcc4_Free.bin"
AccVoice_SetupAcc4_Return:
	ret

AccVoice_ResetAll:
	.incbin "includes/generated/v7_transplant_AccVoice_ResetAll.bin"
AccVoice_Reset_UseSecondary:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_UseSecondary.bin"
AccVoice_Reset_UseStyle:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_UseStyle.bin"
AccVoice_Reset_SelectMode:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_SelectMode.bin"
AccVoice_Reset_LoadParams:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_LoadParams.bin"
AccVoice_Reset_Extended:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_Extended.bin"
AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_ApplyAll.bin"
AccVoice_Reset_SetMasks:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_SetMasks.bin"
AccVoice_Reset_Mode2:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_Mode2.bin"
AccVoice_Reset_Mode3:
	.incbin "includes/generated/v7_transplant_AccVoice_Reset_Mode3.bin"
AccVoice_Reset_Return:
	ret

AccVoice_Reassign:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign.bin"
AccVoice_Reassign_MatchA:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_MatchA.bin"
AccVoice_Reassign_Mode2:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_Mode2.bin"
AccVoice_Reassign_Mode3:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_Mode3.bin"
AccVoice_Reassign_MatchB:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_MatchB.bin"
AccVoice_Reassign_Apply:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_Apply.bin"
AccVoice_Reassign_Fallback:
	.incbin "includes/generated/v7_transplant_AccVoice_Reassign_Fallback.bin"
AccVoice_Reassign_Return:
	ret

AccVoice_SplitPointSetup:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitPointSetup.bin"
AccVoice_Split_UseSecondary:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_UseSecondary.bin"
AccVoice_Split_UseStyle:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_UseStyle.bin"
AccVoice_Split_LoadAndApply:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_LoadAndApply.bin"
AccVoice_Split_StyleMode:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_StyleMode.bin"
AccVoice_Split_Apply63:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_Apply63.bin"
AccVoice_Split_SetForward:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_SetForward.bin"
AccVoice_Split_SetReverse:
	.incbin "includes/generated/v7_transplant_AccVoice_Split_SetReverse.bin"
AccVoice_Split_Return:
	ret

AccVoice_SplitReassign:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitReassign.bin"
AccVoice_SplitReassign_MatchFwd:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitReassign_MatchFwd.bin"
AccVoice_SplitReassign_Reverse:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitReassign_Reverse.bin"
AccVoice_SplitReassign_MatchRev:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitReassign_MatchRev.bin"
AccVoice_SplitReassign_Apply:
	.incbin "includes/generated/v7_transplant_AccVoice_SplitReassign_Apply.bin"
AccVoice_LoadAllParts:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadAllParts.bin"
AccInit_AllPartPositions:
	.incbin "includes/generated/v7_transplant_AccInit_AllPartPositions.bin"
AccVoice_ThirdLayer:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer.bin"
AccVoice_ThirdLayer_Secondary:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_Secondary.bin"
AccVoice_ThirdLayer_Style:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_Style.bin"
AccVoice_ThirdLayer_SelectMode:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_SelectMode.bin"
AccVoice_ThirdLayer_LoadParams:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_LoadParams.bin"
AccVoice_ThirdLayer_StyleMode:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_StyleMode.bin"
AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_Apply.bin"
AccVoice_ThirdLayer_SetMasks:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_SetMasks.bin"
AccVoice_ThirdLayer_Reverse:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayer_Reverse.bin"
AccVoice_ThirdLayer_Return:
	ret

AccVoice_ThirdLayerReassign:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdLayerReassign.bin"
AccVoice_ThirdReassign_MatchFwd:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdReassign_MatchFwd.bin"
AccVoice_ThirdReassign_Reverse:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdReassign_Reverse.bin"
AccVoice_ThirdReassign_MatchRev:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdReassign_MatchRev.bin"
AccVoice_ThirdReassign_Apply:
	.incbin "includes/generated/v7_transplant_AccVoice_ThirdReassign_Apply.bin"
AccBuf_WriteAllNotesOff:
	.incbin "includes/generated/v7_transplant_AccBuf_WriteAllNotesOff.bin"
AccBuf_AllNotesOffPadding:
	nop
	nop

AccBuf_ResetAll4:
	.incbin "includes/generated/v7_transplant_AccBuf_ResetAll4.bin"
AccBuf_DrainAndReset:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccBuf_DrainReset_Loop:
	cp iy, (xhl + 4)
	jr z, AccBuf_DrainReset_Done
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd0
	jr z, AccBuf_DrainReset_D0Found
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_D0Found:
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	cps a, 2
	jr nz, AccBuf_DrainReset_Sub1
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x40
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub1:
	cps a, 1
	jr nz, AccBuf_DrainReset_Sub3
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub3:
	cps a, 3
	jr nz, AccBuf_DrainReset_Sub5
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub5:
	cps a, 5
	jr nz, AccBuf_DrainReset_Other
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x7f
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Other:
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Done:
	ret

AccTiming_CallHelper:
	.incbin "includes/generated/v7_transplant_AccTiming_CallHelper.bin"
AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectByMask.bin"
AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectByMask_Default.bin"
AccVoice_SelectReturn:
	ret

AccWave_BankResolve_Short:
	cp	iz, 0xfffe
	jr	nz, 7
	ld	xhl, 0x095bc0
	jr	13
	extz	xiz
	ld	xhl, xiz
	sla	xhl, 8
	add	xhl, 0x095c00
	ret

AccWave_BankResolve:
	push xwa
	push xix
	push xiz
	cp iz, 0xfffe
	jr nz, AccWave_BankResolve_Normal
	ld xhl, 0x95bc0
	jr AccWave_BankResolve_Epilogue

AccWave_BankResolve_Normal:
	ld wa, iz
	and iz, 0xfff
	extz xiz
	ld xhl, xiz
	sla xhl, 8
	srl wa, 10
	ld xix, AccWave_BankTable
	ld_sril3 XIX, 0x07, 0xf0, 0xe0
	add xhl, xix

AccWave_BankResolve_Epilogue:
	pop xiz
	pop xix
	pop xwa
	ret

AccWave_BankTable:
	.byte 0x00, 0x5c, 0x09, 0x00, 0x00, 0x14, 0x30, 0x00
	.byte 0x00, 0xac, 0x31, 0x00, 0x00, 0x14, 0x33, 0x00
	.byte 0x00, 0xac, 0x34, 0x00, 0x00, 0x14, 0x36, 0x00
	.byte 0x00, 0xac, 0x37, 0x00, 0x00, 0x14, 0x39, 0x00

AccVoice_TableLookup:
	call AccVoice_TableLookup_Inner
	add xhl, 0x8000
	ret

AccVoice_TableLookup_Inner:
	cp a, 0x3f
	jr ule, AccVoice_TableLookup_Compute
	xor a, a

AccVoice_TableLookup_Compute:
	.incbin "includes/generated/v7_transplant_AccVoice_TableLookup_Compute.bin"
AccVoice_OffsetTable:
	.byte 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x00, 0x42, 0x00, 0x00, 0x00, 0x43, 0x00
	.byte 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x45, 0x00
	.byte 0x00, 0x00, 0x46, 0x00, 0x00, 0x00, 0x47, 0x00
	.byte 0x00, 0x00, 0x48, 0x00, 0x00, 0x00, 0x49, 0x00
	.byte 0x00, 0x00, 0x4a, 0x00, 0x00, 0x00, 0x4b, 0x00
	.byte 0x00, 0x00, 0x4c, 0x00, 0x00, 0x00, 0x4d, 0x00
	.byte 0x00, 0x00, 0x4e, 0x00, 0x00, 0x00, 0x4f, 0x00
	.byte 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x51, 0x00
	.byte 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x53, 0x00
	.byte 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0x55, 0x00
	.byte 0x00, 0x00, 0x56, 0x00, 0x00, 0x00, 0x57, 0x00
	.byte 0x00, 0x00, 0x58, 0x00, 0x00, 0x00, 0x59, 0x00
	.byte 0x00, 0x00, 0x5a, 0x00, 0x00, 0x00, 0x5b, 0x00
	.byte 0x00, 0x00, 0x5c, 0x00, 0x00, 0x00, 0x5d, 0x00
	.byte 0x00, 0x00, 0x5e, 0x00, 0x00, 0x00, 0x5f, 0x00
	.byte 0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x61, 0x00
	.byte 0x00, 0x00, 0x62, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x65, 0x00
	.byte 0x00, 0x00, 0x66, 0x00, 0x00, 0x00, 0x67, 0x00
	.byte 0x00, 0x00, 0x68, 0x00, 0x00, 0x00, 0x69, 0x00
	.byte 0x00, 0x00, 0x6a, 0x00, 0x00, 0x00, 0x6b, 0x00
	.byte 0x00, 0x00, 0x6c, 0x00, 0x00, 0x00, 0x6d, 0x00
	.byte 0x00, 0x00, 0x6e, 0x00, 0x00, 0x00, 0x6f, 0x00
	.byte 0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0x71, 0x00
	.byte 0x00, 0x00, 0x72, 0x00, 0x00, 0x00, 0x73, 0x00
	.byte 0x00, 0x00, 0x74, 0x00, 0x00, 0x00, 0x75, 0x00
	.byte 0x00, 0x00, 0x76, 0x00, 0x00, 0x00, 0x77, 0x00
	.byte 0x00, 0x00, 0x78, 0x00, 0x00, 0x00, 0x79, 0x00
	.byte 0x00, 0x00, 0x7a, 0x00, 0x00, 0x00, 0x7b, 0x00
	.byte 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x7d, 0x00
	.byte 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x7f, 0x00

AccState_CollectAll:
	.incbin "includes/generated/v7_transplant_AccState_CollectAll.bin"
AccState_CollectKbd1_Loop:
	.incbin "includes/generated/v7_transplant_AccState_CollectKbd1_Loop.bin"
AccState_CollectKbd2_Loop:
	.incbin "includes/generated/v7_transplant_AccState_CollectKbd2_Loop.bin"
AccState_CollectAcc1_Loop:
	.incbin "includes/generated/v7_transplant_AccState_CollectAcc1_Loop.bin"
AccState_CollectAcc2_Loop:
	.incbin "includes/generated/v7_transplant_AccState_CollectAcc2_Loop.bin"
AccState_CollectAcc3_Loop:
	.incbin "includes/generated/v7_transplant_AccState_CollectAcc3_Loop.bin"
AccState_CollectAcc4_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc4_Loop
	bit 7, a
	jr nz, AccState_CollectReturn
	cpdi16 0x28b4, 0
	jr nz, AccState_CollectAcc4_Active
	cpdi16 0x28a8, 0
	jr nz, AccState_CollectAcc4_Active
	call AccWrap_PlayModeStopSync
	jr AccState_Apply

AccState_CollectAcc4_Active:
	call AccWrap_PlayModeStartPlay

AccState_Apply:
	.incbin "includes/generated/v7_transplant_AccState_Apply.bin"
AccState_CollectReturn:
	ret

AccState_ScanLookupTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02
	.byte 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00
	.byte 0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00
	.zero 10

AccVoice_ScanForD3:
	.incbin "includes/generated/v7_transplant_AccVoice_ScanForD3.bin"
AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupByteData.bin"
AccFlags_Aggregate:
	.incbin "includes/generated/v7_transplant_AccFlags_Aggregate.bin"
AccFlags_CheckDecay:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckDecay.bin"
AccFlags_BuildIndex:
	.incbin "includes/generated/v7_transplant_AccFlags_BuildIndex.bin"
AccFlags_CheckDir65:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckDir65.bin"
AccFlags_CheckDir67:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckDir67.bin"
AccFlags_CheckNoteOn:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckNoteOn.bin"
AccFlags_PedalBit7:
	.incbin "includes/generated/v7_transplant_AccFlags_PedalBit7.bin"
AccFlags_CheckSync69:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckSync69.bin"
AccFlags_CheckSync71:
	.incbin "includes/generated/v7_transplant_AccFlags_CheckSync71.bin"
AccFlags_Dispatch:
	and w, 0xf
	sla w, 2
	ld xhl, AccFlags_JumpTable
	ld_sril3 XWA, 0x03, 0xec, 0xe1
	jp (xwa)


AccFlags_JumpTable:
	.long AccFlags_Handler0
	.long AccFlags_Handler1
	.long AccFlags_Handler2
	.long AccFlags_Handler2
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler0
	.long AccFlags_Handler9
	.long AccFlags_Handler10
	.long AccFlags_Handler10
	.long AccFlags_Handler8
	.long AccFlags_Handler8
	.long AccFlags_Handler8
	.long AccFlags_Handler8
AccFlags_Handler0:
	.incbin "includes/generated/v7_transplant_AccFlags_Handler0.bin"
AccFlags_Handler4:
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	48
AccFlags_Handler8:
	call	AccStyle_Init
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	t, 0x1e
AccFlags_Handler2:
	call	AccVoice_SplitPointSetup
	jr	24
AccFlags_Handler10:
	call	AccStyle_Init
	call	AccVoice_SplitPointSetup
	jr	t, 0x0e
AccFlags_Handler1:
	call	AccVoice_ResetAll
	jr	8
AccFlags_Handler9:
	call	AccStyle_Init
	call	AccVoice_ResetAll
	call	Rhythm_Send_Ch90_7F_7E
	call	Rhythm_SendChanPressure
	calr	59
	ret

AccBuf_ResetAll4Positions:
	.incbin "includes/generated/v7_transplant_AccBuf_ResetAll4Positions.bin"
AccBuf_ResetOnePosition:
	ld (xhl + 256), 0xa
	ld (xhl + 2), 0xff
	ldw wa, 0xa
	ldw bc, 0xa
	ei 6
	ld (xhl + 4), wa
	ld (xhl + 6), bc
	ei 0
	ret

AccBuf_ResetByteData:
	.incbin "includes/generated/v7_transplant_AccBuf_ResetByteData.bin"
AccNote_FlushAll:
	.incbin "includes/generated/v7_transplant_AccNote_FlushAll.bin"
AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	.incbin "includes/generated/v7_transplant_AccTempo_CalcPosition.bin"
AccInit_FullReInit:
	.incbin "includes/generated/v7_transplant_AccInit_FullReInit.bin"
AccInit_ReInit_AdjustDecay:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_AdjustDecay.bin"
AccInit_ReInit_CheckNoteOn:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_CheckNoteOn.bin"
AccInit_ReInit_CheckModes:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_CheckModes.bin"
AccInit_ReInit_CheckSplit:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_CheckSplit.bin"
AccInit_ReInit_CheckPedalBit7:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_CheckPedalBit7.bin"
AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_CheckThird.bin"
AccInit_ReInit_ClearHighBits:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_ClearHighBits.bin"
AccInit_ReInit_SetDirty:
	.incbin "includes/generated/v7_transplant_AccInit_ReInit_SetDirty.bin"
AccInit_ResetSongCounter:
	.incbin "includes/generated/v7_transplant_AccInit_ResetSongCounter.bin"
AccInit_ResetSong_Store:
	.incbin "includes/generated/v7_transplant_AccInit_ResetSong_Store.bin"
AccInit_CallF435A9:
	call SeqVoice_SendNoteOffAndFlush
	ret

AccTuning_CheckChange:
	.incbin "includes/generated/v7_transplant_AccTuning_CheckChange.bin"
AccTuning_ChangeReturn:
	ret

AccTuning_LoadFromROM:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadFromROM.bin"
AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadMaster.bin"
AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadCoarse.bin"
AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadFine.bin"
AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadOctave.bin"
AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadTranspose.bin"
AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	.incbin "includes/generated/v7_transplant_AccTuning_ApplyChange.bin"
AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_ApplyChange_SelectMode:
	.incbin "includes/generated/v7_transplant_AccTuning_ApplyChange_SelectMode.bin"
AccTuning_Mode_078:
	ldb w, 0x3
	jr AccTuning_ApplyVoice

AccTuning_Mode_080:
	ldb w, 0x4
	jr AccTuning_ApplyVoice

AccTuning_Mode_076:
	ldb w, 0x5
	jr AccTuning_ApplyVoice

AccTuning_Mode_077:
	ldb w, 0x6
	jr AccTuning_ApplyVoice

AccTuning_Mode_074:
	ldb w, 0x2
	jr AccTuning_ApplyVoice

AccTuning_Mode_149:
	ldb w, 0x1
	jr AccTuning_ApplyVoice

AccTuning_Mode_None:
	ldb w, 0x0

AccTuning_ApplyVoice:
	.incbin "includes/generated/v7_transplant_AccTuning_ApplyVoice.bin"
AccTuning_ApplyReturn:
	.incbin "includes/generated/v7_transplant_AccTuning_ApplyReturn.bin"
AccTuning_Toggle:
	.incbin "includes/generated/v7_transplant_AccTuning_Toggle.bin"
AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_Toggle_SetFlag:
	.incbin "includes/generated/v7_transplant_AccTuning_Toggle_SetFlag.bin"
AccTuning_Toggle_CheckDirty:
	.incbin "includes/generated/v7_transplant_AccTuning_Toggle_CheckDirty.bin"
AccTuning_Toggle_NoStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_Toggle_NoStyle.bin"
AccTuning_Toggle_Return:
	ret

AccTuning_SaveState:
	.incbin "includes/generated/v7_transplant_AccTuning_SaveState.bin"
AccTuning_Init:
	.incbin "includes/generated/v7_transplant_AccTuning_Init.bin"
AccTuning_Init_NoTuning:
	.incbin "includes/generated/v7_transplant_AccTuning_Init_NoTuning.bin"
AccTuning_Init_Epilogue:
	pop xhl
	pop xwa
	ret

AccTuning_DisableIfNoStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_DisableIfNoStyle.bin"
AccTuning_DisableReturn:
	ret

AccTuning_LEDOn:
	.incbin "includes/generated/v7_transplant_AccTuning_LEDOn.bin"
AccTuning_LEDOff:
	.incbin "includes/generated/v7_transplant_AccTuning_LEDOff.bin"
AccWrap_JumpTable:
	jp	AccWrap_JumpTable_0x15
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	ret
	ret
AccWrap_ReplayStop:
	jp	AccPedal_EventDispatch
AccWrap_ReplayStopAlt:
	jp	AccPedal_RawHandler_0x2

AccWrap_AutoPlayCheck:
	push xiz
	call AccAutoPlay_NoteDispatch
	pop xiz
	ret

AccWrap_PlayModeByteData:
	jp	AccReplay_FullRestart
	jp	AccAutoPlay_ActionDispatch

AccWrap_DeferredAction:
	jp AccAutoPlay_DeferredAction

AccWrap_AutoPlayStateMachine:
	push xiz
	call AccAutoPlay_StateMachine
	pop xiz
	ret

AccWrap_PlayModeDispatch:
	push xiz
	call AccPlayMode_Dispatch
	pop xiz
	ret

AccWrap_PlayModeStart:
	push xiz
	call AccPlayMode_StartPlayFull
	pop xiz
	ret

AccWrap_PlayModeStopData:
	jp	AccPlayMode_StopExprC

AccWrap_PlayModeStartAccPlay:
	jp AccPlayMode_StartAccPlayFull

AccWrap_PlayModeStopSync:
	jp AccPlayMode_StopToSync2

AccWrap_PlayModeStopExpr:
	push xiz
	call AccPlayMode_StopExprD
	pop xiz
	ret

AccWrap_PlayModeStartPlay:
	push xiz
	call AccPlayMode_StartPlay2
	pop xiz
	ret

AccWrap_ReplaySavedPedal:
	push xiz
	call AccReplay_SavedPedal
	pop xiz
	ret

AccWrap_ReplaySavedExpr:
	jp AccReplay_SavedExpression

AccWrap_FullStop:
	push xiz
	call AccReplay_FullStop
	pop xiz
	ret

AccWrap_PositionClear:
	push xiz
	call AccPos_ClearOnStart
	pop xiz
	ret

AccWrap_PositionSaveData:
	push	xiz
	call	AccPos_ClearOnStart_Padding_0x2
	pop	xiz
	ret

AccWrap_FlagSync:
	jp AccFlags_SyncTo64607
AccWrap_PlayModeStopData2:
	jp	AccTempo_WriteMarker_Padding_0x2

AccWrap_AutoPlayZoneTrack:
	push xiz
	call AccAutoPlay_ZoneTrack
	pop xiz
	ret

AccWrap_AutoPlayByteData:
	jp	AccAutoPlay_PeriodicCheck
	push	xiz
	calr	5156
	pop	xiz
	ret
	push	xiz
	calr	5268
	pop	xiz
	ret

AccPedal_EventDispatch:
	.incbin "includes/generated/v7_transplant_AccPedal_EventDispatch.bin"
AccPedal_TypeSustainOrExpr:
	.incbin "includes/generated/v7_transplant_AccPedal_TypeSustainOrExpr.bin"
AccPedal_ParseValue:
	.incbin "includes/generated/v7_transplant_AccPedal_ParseValue.bin"
AccPedal_CheckType0:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckType0.bin"
AccPedal_SavePosition:
	calr AccPos_SaveOnStop

AccPedal_EventReturn:
	ret

AccPedal_RawHandler:
	.incbin "includes/generated/v7_transplant_AccPedal_RawHandler.bin"
AccPedal_SustainHandler:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainHandler.bin"
AccPedal_Sustain_CallReset:
	.incbin "includes/generated/v7_transplant_AccPedal_Sustain_CallReset.bin"
AccPedal_Sustain_CheckStyle:
	.incbin "includes/generated/v7_transplant_AccPedal_Sustain_CheckStyle.bin"
AccPedal_Sustain_SpecialStyle:
	ordi8 3381, 1
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckPlay:
	bitda 2, (0x28a7)
	jr z, AccPedal_Sustain_CheckMultiStyle
	calr AccPlayMode_Dispatch
	bitda 3, (3411)
	jr z, AccPedal_Sustain_PlayJump
	cpdi8 (3429), 0
	jr z, AccPedal_Sustain_PlayJump
	call AccPedal_ScanVoiceSlots
	ldb a, 0x86
	bitda 1, (3411)
	jr nz, AccPedal_Sustain_WriteTempo
	ldb a, 0x85

AccPedal_Sustain_WriteTempo:
	calr AccTempo_WriteStopMarker

AccPedal_Sustain_PlayJump:
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckMultiStyle:
	.incbin "includes/generated/v7_transplant_AccPedal_Sustain_CheckMultiStyle.bin"
AccPedal_Sustain_MultiMatch:
	ordi8 3381, 1
	jr AccPedal_SustainReturn

AccPedal_Sustain_Normal:
	bitda 2, (0x28b2)
	jr nz, AccPedal_SustainReturn
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccPedal_SustainReturn
	ei 6
	ldb_d8 a, (1056)
	bit 2, a
	jr nz, AccPedal_Sustain_CallPlayMode
	bit 0, a
	jr z, AccPedal_Sustain_CallPlayMode
	xor a, a
	stb_d8 (1056), a
	stb_d8 (1054), a
	stb_d8 (1057), a
	ei 0
	jr AccPedal_SustainReturn

AccPedal_Sustain_CallPlayMode:
	ei 0
	calr AccPlayMode_TransitionRouter

AccPedal_SustainReturn:
	ret

AccPedal_SustainPadding:
	nop
	nop

AccPedal_StyleCheck:
	.incbin "includes/generated/v7_transplant_AccPedal_StyleCheck.bin"
AccPedal_StyleCheck_Extended:
	.incbin "includes/generated/v7_transplant_AccPedal_StyleCheck_Extended.bin"
AccPedal_StyleCheck_Match120:
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Eligible:
	ldb a, 0x0
	jr AccPedal_StyleCheckReturn

AccPedal_StyleCheck_Ineligible:
	ldb a, 0x1

AccPedal_StyleCheckReturn:
	ret

AccPedal_ExprToggle:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprToggle.bin"
AccPedal_ExprReturn:
	ret

AccPedal_ExprPadding:
	nop
	nop

AccPedal_DistributeParams:
	.incbin "includes/generated/v7_transplant_AccPedal_DistributeParams.bin"
AccPedal_Distribute_JumpMain:
	jp AccPedal_DistributeReturn

AccPedal_Distribute_ClearAll:
	.incbin "includes/generated/v7_transplant_AccPedal_Distribute_ClearAll.bin"
AccPedal_Distribute_CheckRecord:
	.incbin "includes/generated/v7_transplant_AccPedal_Distribute_CheckRecord.bin"
AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	nop
	nop

AccPedal_SendEvents:
	.incbin "includes/generated/v7_transplant_AccPedal_SendEvents.bin"
AccPedal_SendEvents_Group2:
	.incbin "includes/generated/v7_transplant_AccPedal_SendEvents_Group2.bin"
AccPedal_SendEvents_OnSustain:
	.incbin "includes/generated/v7_transplant_AccPedal_SendEvents_OnSustain.bin"
AccPedal_SendEvents_OnExpr:
	.incbin "includes/generated/v7_transplant_AccPedal_SendEvents_OnExpr.bin"
AccPedal_SendEventsReturn:
	ret

AccPedal_ProcessAllBits:
	calr AccPedal_Bit2_Sustain
	calr AccPedal_Bit2_Expression
	calr AccPedal_Bit7_Portamento
	calr AccPedal_Bit6_Hold
	calr AccPedal_Bit4_Sostenuto
	calr AccPedal_Bit5_Soft
	calr AccPedal_Bit3_Damper
	ret

AccPedal_ProcessBitsPadding:
	nop
	nop

AccPedal_Bit2_Sustain:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit2_Sustain.bin"
AccPedal_Bit2_CheckPlay:
	bitda 2, (1054)
	jr nz, AccPedal_Bit2_Sostenuto
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_Sostenuto:
	calr AccPedal_SostenutoOn

AccPedal_Bit2_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit2_Off.bin"
AccPedal_Bit2_OffPlay:
	bitda 2, (1054)
	jr nz, AccPedal_Bit2_OffSostenuto
	calr AccPedal_SustainOff
	jr AccPedal_Bit2_Return

AccPedal_Bit2_OffSostenuto:
	calr AccPedal_SostenutoOff

AccPedal_Bit2_Return:
	ret

AccPedal_Bit2_Expression:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit2_Expression.bin"
AccPedal_Expr_CheckPlay:
	bitda 2, (1054)
	jr nz, AccPedal_Expr_Soft
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_Soft:
	calr AccPedal_SoftOn

AccPedal_Expr_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Expr_Off.bin"
AccPedal_Expr_OffPlay:
	bitda 2, (1054)
	jr nz, AccPedal_Expr_OffSoft
	calr AccPedal_ExprOff
	jr AccPedal_Expr_Return

AccPedal_Expr_OffSoft:
	calr AccPedal_SoftOff

AccPedal_Expr_Return:
	ret

AccPedal_Bit7_Portamento:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit7_Portamento.bin"
AccPedal_Bit7_Damper:
	calr AccPedal_DamperOn

AccPedal_Bit7_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit7_Off.bin"
AccPedal_Bit7_OffDamper:
	calr AccPedal_DamperOff

AccPedal_Bit7_Return:
	ret

AccPedal_Bit6_Hold:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit6_Hold.bin"
AccPedal_Bit6_HoldOff:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit6_HoldOff.bin"
AccPedal_Bit6_Return:
	ret

AccPedal_Bit4_Sostenuto:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit4_Sostenuto.bin"
AccPedal_Bit4_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit4_Off.bin"
AccPedal_Bit4_Return:
	ret

AccPedal_Bit5_Soft:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit5_Soft.bin"
AccPedal_Bit5_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit5_Off.bin"
AccPedal_Bit5_Return:
	ret

AccPedal_Bit3_Damper:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit3_Damper.bin"
AccPedal_Bit3_Off:
	.incbin "includes/generated/v7_transplant_AccPedal_Bit3_Off.bin"
AccPedal_Bit3_Return:
	ret

AccPedal_StateSync:
	.incbin "includes/generated/v7_transplant_AccPedal_StateSync.bin"
AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	.incbin "includes/generated/v7_transplant_AccPedal_Sync_DispatchAll.bin"
AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl1.bin"
AccPedal_SendCtrl1_CheckPort:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl1_CheckPort.bin"
AccPedal_SendCtrl1_UpdateMask:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl1_UpdateMask.bin"
AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl2.bin"
AccPedal_SendCtrl2_CheckPort:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl2_CheckPort.bin"
AccPedal_SendCtrl2_UpdateMask:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl2_UpdateMask.bin"
AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl3.bin"
AccPedal_SendCtrl3_CheckPort:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl3_CheckPort.bin"
AccPedal_SendCtrl3_UpdateMask:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl3_UpdateMask.bin"
AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl4.bin"
AccPedal_SendCtrl4_CheckPort:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl4_CheckPort.bin"
AccPedal_SendCtrl4_UpdateMask:
	.incbin "includes/generated/v7_transplant_AccPedal_SendCtrl4_UpdateMask.bin"
AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc.bin"
AccPedal_MapToAcc_Send:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_Send.bin"
AccPedal_MapToAcc_CheckDir:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_CheckDir.bin"
AccPedal_MapToAcc_UpdateMask:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_UpdateMask.bin"
AccPedal_MapToAcc_ClearMask:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_ClearMask.bin"
AccPedal_MapToAcc_SetMask:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_SetMask.bin"
AccPedal_MapToAcc_Apply:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_Apply.bin"
AccPedal_MapToAcc_Return:
	.incbin "includes/generated/v7_transplant_AccPedal_MapToAcc_Return.bin"
AccPedal_MapPadding:
	ret

AccPedal_MapPadding2:
	nop
	nop

AccPedal_SustainOn:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOn.bin"
AccPedal_SustainOn_SetMask:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOn_SetMask.bin"
AccPedal_SustainOn_Update64607:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOn_Update64607.bin"
AccPedal_SustainOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOn_Post.bin"
AccPedal_SustainOn_Finalize:
	bitda 6, (0xfc5f)
	jr z, AccPedal_SustainOn_CheckAlt
	anddi8 (0xfc5f), 191

AccPedal_SustainOn_CheckAlt:
	bitda 7, (0xfc5f)
	jr z, AccPedal_SustainOn_AltRoute
	anddi8 (0xfc5f), 127

AccPedal_SustainOn_AltRoute:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOn_AltRoute.bin"
AccPedal_SustainOn_Return:
	ret

AccPedal_SustainOff_Padding:
	nop
	nop

AccPedal_SustainOff:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOff.bin"
AccPedal_SustainOff_Clear:
	.incbin "includes/generated/v7_transplant_AccPedal_SustainOff_Clear.bin"
AccPedal_SustainOff_Return:
	ret

AccPedal_ExprOn_Padding:
	nop
	nop

AccPedal_ExprOn:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOn.bin"
AccPedal_ExprOn_SetMask:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOn_SetMask.bin"
AccPedal_ExprOn_Update64607:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOn_Update64607.bin"
AccPedal_ExprOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOn_Post.bin"
AccPedal_ExprOn_Finalize:
	bitda 6, (0xfc5f)
	jr z, AccPedal_ExprOn_CheckAlt
	anddi8 (0xfc5f), 191

AccPedal_ExprOn_CheckAlt:
	bitda 7, (0xfc5f)
	jr z, AccPedal_ExprOn_AltRoute
	anddi8 (0xfc5f), 127

AccPedal_ExprOn_AltRoute:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOn_AltRoute.bin"
AccPedal_ExprOn_Return:
	ret

AccPedal_ExprOff_Padding:
	nop
	nop

AccPedal_ExprOff:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOff.bin"
AccPedal_ExprOff_Clear:
	.incbin "includes/generated/v7_transplant_AccPedal_ExprOff_Clear.bin"
AccPedal_ExprOff_Return:
	ret

AccPedal_SostenutoOn_Padding:
	nop
	nop

AccPedal_SostenutoOn:
	.incbin "includes/generated/v7_transplant_AccPedal_SostenutoOn.bin"
AccPedal_SostenutoOn_SetMask:
	bitda 6, (0xfc5f)
	jr z, AccPedal_SostenutoOn_Update
	anddi8 (0xfc5f), 191

AccPedal_SostenutoOn_Update:
	bitda 7, (0xfc5f)
	jr z, AccPedal_SostenutoOn_Post
	anddi8 (0xfc5f), 127

AccPedal_SostenutoOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_SostenutoOn_Post.bin"
AccPedal_SostenutoOn_Finalize:
	.incbin "includes/generated/v7_transplant_AccPedal_SostenutoOn_Finalize.bin"
AccPedal_SostenutoOn_CheckAlt:
	.incbin "includes/generated/v7_transplant_AccPedal_SostenutoOn_CheckAlt.bin"
AccPedal_SostenutoOn_Return:
	ret

AccPedal_SostenutoOff_Padding:
	nop
	nop

AccPedal_SostenutoOff:
	.incbin "includes/generated/v7_transplant_AccPedal_SostenutoOff.bin"
AccPedal_SostenutoOff_Return:
	ret

AccPedal_SostenutoOff_Padding2:
	nop
	nop

AccPedal_SoftOn:
	.incbin "includes/generated/v7_transplant_AccPedal_SoftOn.bin"
AccPedal_SoftOn_SetMask:
	bitda 6, (0xfc5f)
	jr z, AccPedal_SoftOn_Update
	anddi8 (0xfc5f), 191

AccPedal_SoftOn_Update:
	bitda 7, (0xfc5f)
	jr z, AccPedal_SoftOn_Post
	anddi8 (0xfc5f), 127

AccPedal_SoftOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_SoftOn_Post.bin"
AccPedal_SoftOn_Finalize:
	.incbin "includes/generated/v7_transplant_AccPedal_SoftOn_Finalize.bin"
AccPedal_SoftOn_CheckAlt:
	.incbin "includes/generated/v7_transplant_AccPedal_SoftOn_CheckAlt.bin"
AccPedal_SoftOn_Return:
	ret

AccPedal_SoftOff_Padding:
	nop
	nop

AccPedal_SoftOff:
	.incbin "includes/generated/v7_transplant_AccPedal_SoftOff.bin"
AccPedal_SoftOff_Return:
	ret

AccPedal_HoldOn_Padding:
	nop
	nop

AccPedal_HoldOn:
	.incbin "includes/generated/v7_transplant_AccPedal_HoldOn.bin"
AccPedal_HoldOn_SetMask:
	bitda 5, (0xfc5f)
	jr z, AccPedal_HoldOn_Update
	anddi8 (0xfc5f), 223

AccPedal_HoldOn_Update:
	.incbin "includes/generated/v7_transplant_AccPedal_HoldOn_Update.bin"
AccPedal_HoldOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_HoldOn_Post.bin"
AccPedal_HoldOn_Finalize:
	.incbin "includes/generated/v7_transplant_AccPedal_HoldOn_Finalize.bin"
AccPedal_HoldOn_CheckAlt:
	bitda 7, (0xfc5f)
	jr z, AccPedal_HoldOn_Return
	anddi8 (0xfc5f), 127

AccPedal_HoldOn_Return:
	ret

AccPedal_HoldOff_Padding:
	nop
	nop

AccPedal_HoldOff:
	.incbin "includes/generated/v7_transplant_AccPedal_HoldOff.bin"
AccPedal_HoldOff_Return:
	ret

AccPedal_HoldOff_Padding2:
	nop
	nop

AccPedal_DamperOn:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOn.bin"
AccPedal_DamperOn_SetMask:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOn_SetMask.bin"
AccPedal_DamperOn_Update:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOn_Update.bin"
AccPedal_DamperOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOn_Post.bin"
AccPedal_DamperOn_Finalize:
	bitda 6, (0xfc5f)
	jr z, AccPedal_DamperOn_CheckAlt
	anddi8 (0xfc5f), 191

AccPedal_DamperOn_CheckAlt:
	bitda 7, (0xfc5f)
	jr z, AccPedal_DamperOn_AltRoute
	anddi8 (0xfc5f), 127

AccPedal_DamperOn_AltRoute:
	bitda 4, (0xfc5f)
	jr z, AccPedal_DamperOn_Apply
	anddi8 (0xfc5f), 239

AccPedal_DamperOn_Apply:
	bitda 5, (0xfc5f)
	jr z, AccPedal_DamperOn_FinalCheck
	anddi8 (0xfc5f), 223

AccPedal_DamperOn_FinalCheck:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOn_FinalCheck.bin"
AccPedal_DamperOn_Return:
	ret

AccPedal_DamperOff_Padding:
	nop
	nop

AccPedal_DamperOff:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOff.bin"
AccPedal_DamperOff_Clear:
	.incbin "includes/generated/v7_transplant_AccPedal_DamperOff_Clear.bin"
AccPedal_DamperOff_Return:
	ret

AccPedal_DamperOff_Padding2:
	nop
	nop

AccPedal_PortamentoOn:
	.incbin "includes/generated/v7_transplant_AccPedal_PortamentoOn.bin"
AccPedal_PortamentoOn_SetMask:
	bitda 5, (0xfc5f)
	jr z, AccPedal_PortamentoOn_Update
	anddi8 (0xfc5f), 223

AccPedal_PortamentoOn_Update:
	.incbin "includes/generated/v7_transplant_AccPedal_PortamentoOn_Update.bin"
AccPedal_PortamentoOn_Post:
	.incbin "includes/generated/v7_transplant_AccPedal_PortamentoOn_Post.bin"
AccPedal_PortamentoOn_Finalize:
	.incbin "includes/generated/v7_transplant_AccPedal_PortamentoOn_Finalize.bin"
AccPedal_PortamentoOn_CheckAlt:
	bitda 6, (0xfc5f)
	jr z, AccPedal_PortamentoOn_Return
	anddi8 (0xfc5f), 191

AccPedal_PortamentoOn_Return:
	ret

AccPedal_PortamentoOff_Padding:
	nop
	nop

AccPedal_PortamentoOff:
	.incbin "includes/generated/v7_transplant_AccPedal_PortamentoOff.bin"
AccPedal_PortamentoOff_Return:
	ret

AccPedal_PortamentoOff_Padding2:
	nop
	nop

AccAutoPlay_NoteDispatch:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_NoteDispatch.bin"
AccAutoPlay_NoteDispatch_Check:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_NoteDispatch_Check.bin"
AccAutoPlay_NoteDispatch_Process:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_NoteDispatch_Process.bin"
AccAutoPlay_NoteDispatch_Return:
	ret

AccAutoPlay_SplitDetect:
	ldb c, 0x0
	cpdi16 0x28a8, 0
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 3, (0x28b3)
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 0, (0x28b2)
	jr nz, AccAutoPlay_SplitDetect_Return
	bitda 2, (0x28b1)
	jr nz, AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Check:
	bit 7, w
	jr z, AccAutoPlay_SplitDetect_Process
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Upper
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Upper:
	ldb c, 0x0
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Process:
	bitda 0, (0xfd53)
	jr nz, AccAutoPlay_SplitDetect_NoSplit
	and w, 0xf
	ldb_d8 l, (0xf9c3)
	and l, 0xf
	cp l, w
	jr z, AccAutoPlay_SplitDetect_Lower
	ldb_d8 l, (0xfbe5)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Apply
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Apply
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Lower:
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Apply
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Apply:
	ldb c, 0x0
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_NoSplit:
	and w, 0xf
	ldb_d8 l, (0xf9f7)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Store
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Store
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Store:
	ldb_d8 l, (0xfbe5)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Return
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Return
	ldb c, 0x1

AccAutoPlay_SplitDetect_Return:
	ret

AccAutoPlay_ZoneTrack:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ZoneTrack.bin"
AccAutoPlay_ZoneTrack_Update:
	ret

AccAutoPlay_ZoneTrack_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ZoneTrack_Apply.bin"
AccAutoPlay_ZoneTrack_Check:
	cps wa, 1
	jr nz, AccAutoPlay_ZoneTrack_Upper
	ldb l, 0x0
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Upper:
	ldb l, 0xf0

AccAutoPlay_ZoneTrack_Store:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ZoneTrack_Store.bin"
AccAutoPlay_ZoneTrack_Clear:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ZoneTrack_Clear.bin"
AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ZoneTrack_Default.bin"
AccAutoPlay_ZoneTrack_SetFlag:
	ldb c, 0x0
	bit 7, w
	jr z, AccAutoPlay_ZoneTrack_Done
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Done:
	bitda 0, (0xfd53)
	jr nz, AccAutoPlay_ZoneTrack_Final
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Final:
	ldb l, 0x7f

AccAutoPlay_ZoneTrack_Return2:
	ret

AccAutoPlay_ZoneTrack_Return:
	ret

AccAutoPlay_StateMachine:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_StateMachine.bin"
AccAutoPlay_SM_CheckEligible:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SM_CheckEligible.bin"
AccAutoPlay_SM_Return:
	ret

AccAutoPlay_SM_Padding:
	nop
	nop

AccAutoPlay_TriggerCheck:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_TriggerCheck.bin"
AccAutoPlay_Trigger_Evaluate:
	calr AccAutoPlay_Configure

AccAutoPlay_Trigger_Process:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Trigger_Process.bin"
AccAutoPlay_Trigger_Activate:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Trigger_Activate.bin"
AccAutoPlay_Trigger_Configure:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Trigger_Configure.bin"
AccAutoPlay_Trigger_Finalize:
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Return:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Trigger_Return.bin"
AccAutoPlay_ModeAvail_Padding:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeAvail_Padding.bin"
AccAutoPlay_ModeAvail_Padding2:
	ret

AccAutoPlay_ModeAvail_Padding3:
	nop
	nop

AccAutoPlay_ModeAvail:
	ldb_d8 l, (0xfd02)
	and l, 0x3
	cps l, 0
	jr nz, AccAutoPlay_ModeAvail_Process
	ldb_d8 l, (0xfd03)
	and l, 0x7f
	dec 1, l
	cp l, 0xff
	jr nz, AccAutoPlay_ModeAvail_Check
	ldb l, 0x0

AccAutoPlay_ModeAvail_Check:
	jr AccAutoPlay_ModeAvail_SetMode

AccAutoPlay_ModeAvail_Process:
	push l
	lds32 xhl, 0
	pop l
	add xhl, AccAutoPlay_ModeAvail_Extended_0x2
	ld l, (xhl)

AccAutoPlay_ModeAvail_SetMode:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeAvail_SetMode.bin"
AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeAvail_Extended.bin"
AccAutoPlay_SetConfig:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SetConfig.bin"
AccAutoPlay_SetConfig_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SetConfig_Apply.bin"
AccAutoPlay_SetConfig_Return:
	ret

AccAutoPlay_Configure:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure.bin"
AccAutoPlay_Configure_Mode1:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Mode1.bin"
AccAutoPlay_Configure_Mode2:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Mode2.bin"
AccAutoPlay_Configure_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Apply.bin"
AccAutoPlay_Configure_Check:
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Store:
	bitda 2, (1056)
	jr nz, AccAutoPlay_Configure_Return
	calr AccAutoPlay_ModeDecode
	calr AccAutoPlay_SubModeB

AccAutoPlay_Configure_Return:
	ret

AccAutoPlay_Configure_Extended:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Extended.bin"
AccAutoPlay_Configure_Final:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Final.bin"
AccAutoPlay_Configure_Done:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Configure_Done.bin"
AccAutoPlay_Configure_Return2:
	ret
	nop
	nop


AccAutoPlay_PeriodicCheck:
	bitda 1, (0xfc5f)
	jr nz, AccAutoPlay_Periodic_Evaluate
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Evaluate:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Periodic_Evaluate.bin"
AccAutoPlay_Periodic_Padding:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Periodic_Padding.bin"
AccAutoPlay_Periodic_Process:
	cpdi16 0xf19e, 0
	jr nz, AccAutoPlay_Periodic_Toggle
	cpdi16 0x28a8, 0
	jr z, AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Toggle:
	calr AccAutoPlay_Disable

AccAutoPlay_Periodic_Return:
	ret

AccAutoPlay_Disable:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Disable.bin"
AccAutoPlay_Disable_Return:
	nop
	nop

AccAutoPlay_SubModeA:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeA.bin"
AccAutoPlay_SubModeA_Check:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeA_Check.bin"
AccAutoPlay_SubModeA_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeA_Apply.bin"
AccAutoPlay_SubModeA_Return:
	ret

AccAutoPlay_SubModeA_Padding:
	nop
	nop

AccAutoPlay_SubModeB:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeB.bin"
AccAutoPlay_SubModeB_Check:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeB_Check.bin"
AccAutoPlay_SubModeB_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SubModeB_Apply.bin"
AccAutoPlay_SubModeB_Return:
	ret

AccAutoPlay_SubModeB_Padding:
	nop
	nop

AccAutoPlay_SeqHandoff:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_SeqHandoff.bin"
AccAutoPlay_SeqHandoff_Process:
	bitda 2, (1057)
	jr z, AccAutoPlay_SeqHandoff_Return
	bitda 2, (1054)
	jr z, AccAutoPlay_SeqHandoff_Finalize
	ei 6
	calr AccPlayMode_StopExprFull
	ei 0
	jr AccAutoPlay_SeqHandoff_Return

AccAutoPlay_SeqHandoff_Finalize:
	ei 6
	calr AccPlayMode_StopExprC
	ei 0

AccAutoPlay_SeqHandoff_Return:
	ret

AccAutoPlay_SeqHandoff_Padding:
	nop
	nop

AccAutoPlay_ModeDecode:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeDecode.bin"
AccAutoPlay_ModeDecode_Process:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeDecode_Process.bin"
AccAutoPlay_ModeDecode_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ModeDecode_Apply.bin"
AccAutoPlay_ModeDecode_Return:
	ret

AccAutoPlay_ModeDecode_Padding:
	nop
	nop

AccAutoPlay_ActionDispatch:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_ActionDispatch.bin"
AccAutoPlay_Action_Check:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Action_Check.bin"
AccAutoPlay_Action_Process:
	bit 6, a
	jr z, AccAutoPlay_Action_Deactivate
	calr AccPlayMode_StopExprB
	jr AccAutoPlay_Action_Apply

AccAutoPlay_Action_Activate:
	calr AccPlayMode_StartPlayFull
	jr AccAutoPlay_Action_Apply

AccAutoPlay_Action_Deactivate:
	calr AccPlayMode_StartAccPlayFull

AccAutoPlay_Action_Apply:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Action_Apply.bin"
AccAutoPlay_Action_Finalize:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Action_Finalize.bin"
AccAutoPlay_Action_Return:
	ret

AccAutoPlay_Action_Padding:
	nop
	nop

AccAutoPlay_DeferredAction:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_DeferredAction.bin"
AccAutoPlay_Deferred_Process:
	.incbin "includes/generated/v7_transplant_AccAutoPlay_Deferred_Process.bin"
AccAutoPlay_Deferred_Return:
	ret

AccAutoPlay_Deferred_Padding:
	nop
	nop

AccPlayMode_Dispatch:
	xor xhl, xhl
	ei 6
	bitda 2, (1054)
	jr z, AccPlayMode_Dispatch_Check
	or l, 0x4

AccPlayMode_Dispatch_Check:
	bitda 2, (1057)
	jr z, AccPlayMode_Dispatch_Select
	or l, 0x8

AccPlayMode_Dispatch_Select:
	bitda 2, (1056)
	jr z, AccPlayMode_Dispatch_Execute
	or l, 0x10

AccPlayMode_Dispatch_Execute:
	ld xwa, AccPlayMode_Dispatch_Table_0x2
	add xhl, xwa
	ld xwa, (xhl)
	call (xwa)
	ei 0
	ret

AccPlayMode_Dispatch_Table:
	.incbin "includes/generated/v7_transplant_AccPlayMode_Dispatch_Table.bin"
AccPlayMode_TransitionRouter:
	cpdi16 0x28a8, 0
	jr z, AccPlayMode_Router_Process
	cpdi16 0xf19e, 0
	jr z, AccPlayMode_Router_Check
	calr AccPlayMode_Router_Alt
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Check:
	calr AccPlayMode_StartRecording
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Process:
	cpdi16 0xf19e, 0
	jr z, AccPlayMode_Router_Apply
	calr AccPlayMode_StartAcc
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Apply:
	calr AccPlayMode_StopToSync

AccPlayMode_Router_Return:
	ret

AccPlayMode_Router_Padding:
	nop
	nop

AccPlayMode_Router_Alt:
	bitda 2, (1056)
	jr nz, AccPlayMode_Router_AltPadding
	calr AccPlayMode_StartPlay
	jr AccPlayMode_Router_AltPadding

AccPlayMode_Router_AltPadding:
	ret

AccPlayMode_StartRecording_Padding:
	nop
	nop

AccPlayMode_StartRecording:
	bitda 2, (1056)
	jr nz, AccPlayMode_StartRec_Apply
	bitda 1, (0x28a7)
	jr z, AccPlayMode_StartRec_Process
	ei 6
	calr AccPlayMode_StopExprB
	ei 0
	jr AccPlayMode_StartRec_Return

AccPlayMode_StartRec_Process:
	calr AccPlayMode_Dispatch
	jr AccPlayMode_StartRec_Return

AccPlayMode_StartRec_Apply:
	calr AccPlayMode_StopExprA

AccPlayMode_StartRec_Return:
	ret

AccPlayMode_StartRec_Padding:
	nop
	nop

AccPlayMode_StartAcc:
	bitda 2, (1056)
	jr nz, AccPlayMode_StartAcc_Apply
	bitda 1, (0x28a7)
	jr z, AccPlayMode_StartAcc_Process
	ei 6
	calr AccPlayMode_StopExprB
	ei 0
	jr AccPlayMode_StartAcc_Return

AccPlayMode_StartAcc_Process:
	ei 6
	calr AccPlayMode_StartPlayFull
	ei 0
	jr AccPlayMode_StartAcc_Return

AccPlayMode_StartAcc_Apply:
	calr AccPlayMode_Dispatch

AccPlayMode_StartAcc_Return:
	ret

AccPlayMode_StartAcc_Padding:
	nop
	nop

AccPlayMode_StopToSync:
	bitda 2, (1056)
	jr nz, AccPlayMode_StopToSync_Process
	ei 6
	calr AccPlayMode_StartAccPlayFull
	ei 0
	jr AccPlayMode_StopToSync_Return

AccPlayMode_StopToSync_Process:
	ei 6
	calr AccPlayMode_StopToSync2
	ei 0

AccPlayMode_StopToSync_Return:
	ret

AccPlayMode_StopToSync_Padding:
	nop
	nop

AccPlayMode_StartPlay:
	bitda 2, (0x28a7)
	jr nz, AccPlayMode_StartPlay_Return
	bitda 1, (0x28a7)
	jr nz, AccPlayMode_StartPlay_Process
	ei 6
	calr AccPlayMode_StartPlayFull
	ei 0
	jr AccPlayMode_StartPlay_Return

AccPlayMode_StartPlay_Process:
	ei 6
	calr AccPlayMode_StopExprB
	ei 0

AccPlayMode_StartPlay_Return:
	ret

AccPlayMode_StartPlay_Padding:
	nop
	nop

AccPlayMode_StopExprA:
	bitda 2, (1054)
	jr nz, AccPlayMode_StopExprA_Process
	ei 6
	calr AccPlayMode_StartAccPlay
	ei 0
	jr AccPlayMode_StopExprA_Return

AccPlayMode_StopExprA_Process:
	ei 6
	calr AccPlayMode_StartPlay2
	ei 0

AccPlayMode_StopExprA_Return:
	ret

AccPlayMode_StopExprA_Padding:
	nop
	nop

AccPlayMode_StopExprB:
	bitda 0, (1056)
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, (1056)
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, (0x28b2)
	jr nz, AccPlayMode_StopExprB_Process
	bitda 1, (0x28b2)
	jr z, AccPlayMode_StopExprB_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 (1054), 128
	ordi8 0x28b2, 4
	jr AccPlayMode_StartAccPlay_Return

AccPlayMode_StopExprB_Process:
	stdi8 (1056), 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StopExprB_Return:
	stdi8 (1057), 1
	calr AccTempo_ClearSubPos

AccPlayMode_StartAccPlay:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StartAccPlay.bin"
AccPlayMode_StartAccPlay_Return:
	ret

AccPlayMode_StartAccPlay_Padding:
	nop
	nop

AccPlayMode_StopToSync2:
	bitda 3, (1056)
	jr nz, AccPlayMode_StartPlay2
	bitda 2, (1056)
	jr z, AccPlayMode_StartPlay2
	stdi8 (1056), 12

AccPlayMode_StartPlay2:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StartPlay2.bin"
AccPlayMode_StartPlay2_Padding:
	nop
	nop

AccPlayMode_StartPlayFull:
	bitda 2, (0x28b2)
	jr nz, AccPlayMode_StartPlayFull_Process
	bitda 1, (0x28b2)
	jr z, AccPlayMode_StartPlayFull_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 (1054), 128
	ordi8 0x28b2, 4
	jr AccPlayMode_StartPlayFull_Return

AccPlayMode_StartPlayFull_Process:
	stdi8 (1057), 1
	calr AccTempo_ClearSubPos
	bitda 0, (1056)
	jr nz, AccPlayMode_StartPlayFull_Return
	bitda 2, (1056)
	jr nz, AccPlayMode_StartPlayFull_Return
	stdi8 (1056), 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StartPlayFull_Return:
	ret

AccPlayMode_StartPlayFull_Padding:
	nop
	nop

AccPlayMode_StopExprFull:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StopExprFull.bin"
AccPlayMode_StopExprFull_Process:
	ldb a, 0x86
	calr AccTempo_WriteStartMarker

AccPlayMode_StopExprC:
	stdi8 (1057), 12
	bitda 3, (1056)
	jr nz, AccPlayMode_StopExprC_Process
	bitda 2, (1056)
	jr z, AccPlayMode_StopExprC_Process
	stdi8 (1056), 12

AccPlayMode_StopExprC_Process:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StopExprC_Process.bin"
AccPlayMode_StopExprC_Return:
	nop
	nop

AccPlayMode_StopExprD:
	stdi8 (1057), 12
	ret

AccPlayMode_StopExprD_Return:
	nop
	nop

AccPlayMode_StartAccPlayFull:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StartAccPlayFull.bin"
AccPlayMode_StartAccPlayFull_Return:
	ret

AccPlayMode_StartAccPlayFull_Padding:
	.incbin "includes/generated/v7_transplant_AccPlayMode_StartAccPlayFull_Padding.bin"
AccTempo_ClearCounters:
	xor wa, wa
	ei 6
	stb_d8 (1047), a
	stda16 (1048), xwa
	ei 0
	ret

AccTempo_ClearPositions:
	xor wa, wa
	ei 6
	bitda 0, (0x28a6)
	jr nz, AccTempo_ClearPositions_Loop
	stb_d8 (1045), a
	stb_d8 (1046), a

AccTempo_ClearPositions_Loop:
	stb_d8 (1076), a
	stb_d8 (1077), a
	ei 0
	anddi8 (0x28a6), 254
	ret

AccTempo_ClearSubPos:
	xor wa, wa
	ei 6
	bitda 3, (0x28a7)
	jr nz, AccTempo_ClearSubPos_Loop
	stda16 (1052), xwa
	stb_d8 (1051), a

AccTempo_ClearSubPos_Loop:
	ei 0
	ret

AccSync_MidiClock:
	bitda 2, (0xfd52)
	jr z, AccSync_MidiClock_Return
	ei 6
	bitda 3, (0x28a7)
	jr z, AccSync_MidiClock_Update
	ordi8 1065, 4
	jr AccSync_MidiClock_Apply

AccSync_MidiClock_Update:
	ordi8 1065, 2

AccSync_MidiClock_Apply:
	.incbin "includes/generated/v7_transplant_AccSync_MidiClock_Apply.bin"
AccSync_MidiClock_Return:
	ret

AccSync_MidiClock_Padding:
	nop
	nop

AccTempo_WriteStartMarker:
	cpdi16 0x28aa, 0
	jr z, AccTempo_WriteMarker_Return

AccTempo_WriteStopMarker:
	ei 6
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ldb_d8 a, (1051)
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ei 0

AccTempo_WriteMarker_Return:
	ret

AccTempo_WriteMarker_Padding:
	nop
	nop
	ret

AccReplay_FullRestart:
	.incbin "includes/generated/v7_transplant_AccReplay_FullRestart.bin"
AccReplay_Restart_WaitIdle:
	pushw bc
	call SeqTiming_Snapshot
	popw bc
	xor wa, wa
	pushw bc
	call RhythmBuf_CheckEmpty
	popw bc
	cps wa, 0
	jr nz, AccReplay_Restart_Snapshot
	inc 1, bc
	cp bc, 0x200
	jr c, AccReplay_Restart_WaitIdle
	jr AccReplay_Restart_ReInit

AccReplay_Restart_Snapshot:
	call RhythmBuf_DispatchWrap
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cps wa, 0
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	calr AccTiming_AlignTo8Tick
	calr AccTempo_CheckSource
	call SeqTiming_Snapshot

AccReplay_Restart_Drain:
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cps wa, 0
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	jr AccReplay_Restart_Drain

AccReplay_Restart_ReInit:
	.incbin "includes/generated/v7_transplant_AccReplay_Restart_ReInit.bin"
AccReplay_Restart_Return:
	nop
	nop

AccTiming_AlignTo8Tick:
	pushw hl
	ldw bc, 0x8
	ldw_d16 xwa, (1033)
	add wa, bc

AccTiming_Align_Compute:
	ld hl, wa
	subda16 xhl, 1033
	cps hl, 0
	jr le, AccTiming_Align_Return
	jr AccTiming_Align_Compute

AccTiming_Align_Return:
	popw hl
	ret

AccPlayMode_WaitIdle:
	xor bc, bc

AccPlayMode_WaitIdle_Check:
	bitda 0, (1054)
	jr z, AccPlayMode_WaitIdle_Loop
	inc 1, bc
	cp bc, 0x500
	jr nz, AccPlayMode_WaitIdle_Check

AccPlayMode_WaitIdle_Loop:
	ret

AccPlayMode_WaitIdle_Return:
	nop
	nop

AccTempo_CheckSource:
	.incbin "includes/generated/v7_transplant_AccTempo_CheckSource.bin"
AccTempo_CheckSource_Process:
	bitda 0, (1115)
	jr z, AccTempo_CheckSource_Clear
	bitda 2, (1054)
	jr nz, AccTempo_CheckSource_Return

AccTempo_CheckSource_Clear:
	call Seq_DispatcherEntry
	stdi8 (1124), 0

AccTempo_CheckSource_Return:
	ret

AccTempo_CheckSource_Padding:
	nop
	nop

AccReplay_SavedPedal:
	.incbin "includes/generated/v7_transplant_AccReplay_SavedPedal.bin"
AccReplay_SavedPedal_Return:
	nop
	nop

AccReplay_SendPedalType5:
	push xiz
	calr AccReplay_SendPedalType6
	pop xiz
	ret

AccReplay_SendPedalType6:
	.incbin "includes/generated/v7_transplant_AccReplay_SendPedalType6.bin"
AccReplay_SendPedal_Process:
	.incbin "includes/generated/v7_transplant_AccReplay_SendPedal_Process.bin"
AccReplay_SendPedal_Dispatch:
	.incbin "includes/generated/v7_transplant_AccReplay_SendPedal_Dispatch.bin"
AccReplay_SendPedal_Return:
	nop
	nop

AccReplay_SavedExpression:
	.incbin "includes/generated/v7_transplant_AccReplay_SavedExpression.bin"
AccReplay_SavedExpr_Return:
	nop
	nop
	ld	xwa, 0x094800
	add	xwa, 14
	ld	wa, (xwa)
	cps	wa, 0
	jr	z, 4
	call	AccDemo_InitDone
	ret
	nop
	nop

AccReplay_FullStop:
	.incbin "includes/generated/v7_transplant_AccReplay_FullStop.bin"
AccReplay_Stop_ClearPedals:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_ClearPedals.bin"
AccReplay_Stop_ResetPosition:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_ResetPosition.bin"
AccReplay_Stop_Rebuild:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_Rebuild.bin"
AccReplay_Stop_CheckMode:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_CheckMode.bin"
AccReplay_Stop_Process:
	stb_d8 (1045), c
	stb_d8 (1046), b
	pushw bc
	pushw de
	call Seq_DispatcherEntry
	popw de
	popw bc
	add c, 0x18
	cp c, 0x60
	jr nz, AccReplay_Stop_UpdateFlags
	inc 1, b
	xor c, c

AccReplay_Stop_UpdateFlags:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_UpdateFlags.bin"
AccReplay_Stop_Finalize:
	.incbin "includes/generated/v7_transplant_AccReplay_Stop_Finalize.bin"
AccReplay_Stop_Return:
	nop
	nop

AccPos_SaveOnStop:
	.incbin "includes/generated/v7_transplant_AccPos_SaveOnStop.bin"
AccPos_SaveOnStop_Return:
	ret

AccPos_SaveOnStop_Padding:
	nop
	nop

AccPos_ClearOnStart:
	.incbin "includes/generated/v7_transplant_AccPos_ClearOnStart.bin"
AccPos_ClearOnStart_Return:
	ret

AccPos_ClearOnStart_Padding:
	.incbin "includes/generated/v7_transplant_AccPos_ClearOnStart_Padding.bin"
AccFlags_SyncTo64607:
	ldb_d8 e, (1056)
	anddi8 (0xfc5f), 254
	bit 2, e
	jr z, AccFlags_Sync_Process
	ordi8 0xfc5f, 1

AccFlags_Sync_Process:
	.incbin "includes/generated/v7_transplant_AccFlags_Sync_Process.bin"
AccFlags_Sync_UpdateLED:
	.incbin "includes/generated/v7_transplant_AccFlags_Sync_UpdateLED.bin"
AccFlags_Sync_Return:
	ret

AccFlags_Sync_Padding:
	nop
	nop

AccTiming_InitAllParts:
	.incbin "includes/generated/v7_transplant_AccTiming_InitAllParts.bin"
AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	.incbin "includes/generated/v7_transplant_AccTiming_MasterTick.bin"
AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_ScanRingBuf.bin"
AccKbdTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccKbdTiming_ScanDone
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccKbdTiming_ClassifyEvent:
	ld w, a
	cp a, 0xdf
	jr z, AccKbdTiming_SpecialEvent
	cp a, 0x9f
	jr nz, AccKbdTiming_CheckNoteOn

AccKbdTiming_SpecialEvent:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_SpecialEvent.bin"
AccKbdTiming_CheckNoteOn:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_CheckNoteOn.bin"
AccKbdTiming_CheckProgramChg:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_CheckProgramChg.bin"
AccKbdTiming_CheckControl:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_CheckControl.bin"
AccKbdTiming_StoreEventData:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_StoreEventData.bin"
AccKbdTiming_CheckTimestamp:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_CheckTimestamp.bin"
AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_SlotLoop.bin"
AccKbdTiming_SlotOverflow:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_SlotOverflow.bin"
AccKbdTiming_SlotOverflow_Done:
	jr AccKbdTiming_WriteNoteEvent

AccKbdTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNoteEvent:
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, w
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb a, 0x0
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ReadTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ReadTiming:
	ldb_sri W, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ClampTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ClampTiming:
	cp wa, 0xa
	jr ugt, AccKbdTiming_WriteNote_AddBase
	ldw wa, 0xa

AccKbdTiming_WriteNote_AddBase:
	addda16 xwa, 1118
	cp a, 0x60
	jr c, AccKbdTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccKbdTiming_WriteNote_StoreTiming:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_WriteNote_StoreTiming.bin"
AccKbdTiming_WriteNote_UpdateReadPos:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNonNote_Prep:
	ld w, a
	or a, 0x8

AccKbdTiming_WriteNonNote:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte3:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_WriteNonNote_Byte3.bin"
AccKbdTiming_WriteNonNote_CheckType:
	cp w, 0x9f
	jr z, AccKbdTiming_WriteNonNote_Done
	cp w, 0xd0
	jr z, AccKbdTiming_WriteNonNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte4
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte4:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte6
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte

AccKbdTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_TimestampOverflow:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_TimestampOverflow.bin"
AccKbdTiming_Overflow_SubBase:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_Overflow_SubBase.bin"
AccKbdTiming_Overflow_CalcSkip:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_Overflow_CalcSkip.bin"
AccKbdTiming_Overflow_AdvancePos:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_Overflow_AdvancePos.bin"
AccKbdTiming_ScanDone:
	ret

AccKbdTiming_CatchupReplay:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld iy, ix
	ld ix, (xhl + 6)

AccKbdTiming_Catchup_Loop:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_Catchup_Loop.bin"
AccKbdTiming_Catchup_SkipNonC0:
	calr AccKbdTiming_AdvancePos
	jr AccKbdTiming_Catchup_Loop

AccKbdTiming_Catchup_Done:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

AccKbdTiming_AdvancePos:
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_AdvancePos_Ret
	ld ix, (xhl + 256)

AccKbdTiming_AdvancePos_Ret:
	ret

AccKbdTiming_TableScan:
	xor iz, iz

AccKbdTiming_TableScan_Loop:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_TableScan_Loop.bin"
AccKbdTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_TableScan_StoreTiming.bin"
AccKbdTiming_TableScan_NextSlot:
	.incbin "includes/generated/v7_transplant_AccKbdTiming_TableScan_NextSlot.bin"
AccKbdTiming_TableScan_Done:
	ret

AccSeq_WriteByte:
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	pushw wa
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	popw wa
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	ret

AccAccTiming_ScanRingBuf:
	.incbin "includes/generated/v7_transplant_AccAccTiming_ScanRingBuf.bin"
AccAccTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccAccTiming_ScanDone
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccAccTiming_ClassifyEvent:
	.incbin "includes/generated/v7_transplant_AccAccTiming_ClassifyEvent.bin"
AccAccTiming_Check0x91:
	.incbin "includes/generated/v7_transplant_AccAccTiming_Check0x91.bin"
AccAccTiming_Check0x92:
	.incbin "includes/generated/v7_transplant_AccAccTiming_Check0x92.bin"
AccAccTiming_CheckProgramChg:
	.incbin "includes/generated/v7_transplant_AccAccTiming_CheckProgramChg.bin"
AccAccTiming_CheckControl:
	.incbin "includes/generated/v7_transplant_AccAccTiming_CheckControl.bin"
AccAccTiming_StoreEventData:
	.incbin "includes/generated/v7_transplant_AccAccTiming_StoreEventData.bin"
AccAccTiming_CheckTimestamp:
	.incbin "includes/generated/v7_transplant_AccAccTiming_CheckTimestamp.bin"
AccAccTiming_NoteSlotScan:
	pushw wa
	ldb_sri W, 0x07, 0xec, 0xf0
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	.incbin "includes/generated/v7_transplant_AccAccTiming_NoteSlot_Loop.bin"
AccAccTiming_NoteSlot_NextSlot:
	.incbin "includes/generated/v7_transplant_AccAccTiming_NoteSlot_NextSlot.bin"
AccAccTiming_NoteSlot_SendNoteOff:
	.incbin "includes/generated/v7_transplant_AccAccTiming_NoteSlot_SendNoteOff.bin"
AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	.incbin "includes/generated/v7_transplant_AccAccTiming_NoteSlot_FreeLoop.bin"
AccAccTiming_SlotOverflow:
	.incbin "includes/generated/v7_transplant_AccAccTiming_SlotOverflow.bin"
AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	.incbin "includes/generated/v7_transplant_AccAccTiming_WriteNoteEvent.bin"
AccAccTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	pushw wa
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingLo
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_ReadTimingLo:
	ldb_sri W, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingHi
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_ReadTimingHi:
	addda16 xwa, 1118
	cp a, 0x60
	jr c, AccAccTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccAccTiming_WriteNote_StoreTiming:
	.incbin "includes/generated/v7_transplant_AccAccTiming_WriteNote_StoreTiming.bin"
AccAccTiming_WriteNote_ExtraBytes:
	popw wa
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra1
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra1:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x90
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra2:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x92
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra3:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz

AccAccTiming_WriteNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNonNote:
	.incbin "includes/generated/v7_transplant_AccAccTiming_WriteNonNote.bin"
AccAccTiming_WriteNonNote_Byte2:
	.incbin "includes/generated/v7_transplant_AccAccTiming_WriteNonNote_Byte2.bin"
AccAccTiming_WriteNonNote_Byte3:
	.incbin "includes/generated/v7_transplant_AccAccTiming_WriteNonNote_Byte3.bin"
AccAccTiming_WriteNonNote_ExtBytes:
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte6
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte7
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte7:
	calr AccSeq_WriteByte

AccAccTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_TimestampOverflow:
	.incbin "includes/generated/v7_transplant_AccAccTiming_TimestampOverflow.bin"
AccAccTiming_Overflow_SubBase:
	.incbin "includes/generated/v7_transplant_AccAccTiming_Overflow_SubBase.bin"
AccAccTiming_Overflow_CalcSkip:
	.incbin "includes/generated/v7_transplant_AccAccTiming_Overflow_CalcSkip.bin"
AccAccTiming_Overflow_AdvancePos:
	.incbin "includes/generated/v7_transplant_AccAccTiming_Overflow_AdvancePos.bin"
AccAccTiming_ScanDone:
	ret

AccAccTiming_TableScan:
	xor iz, iz

AccAccTiming_TableScan_Loop:
	.incbin "includes/generated/v7_transplant_AccAccTiming_TableScan_Loop.bin"
AccAccTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	.incbin "includes/generated/v7_transplant_AccAccTiming_TableScan_StoreTiming.bin"
AccAccTiming_TableScan_NextSlot:
	.incbin "includes/generated/v7_transplant_AccAccTiming_TableScan_NextSlot.bin"
AccAccTiming_TableScan_Done:
	ret

AccTiming_SlotOffsetTables:
	nop
	nop
	nop
	nop
	di
	nop
	nop
	incf
	nop
	nop
	nop
	ccf
	nop
	nop
	nop
	push_f
	nop
	nop
	nop
	calr	0
	nop
	ldb	d, 0
	nop
	nop
	pushw	de
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	0
	nop
	nop
	ccf
	nop
	nop
	nop
	jp	0
	ldb	d, 0
	nop
	nop
	pushw	iy
	nop
	nop
	nop
	ldw	iz, 0
	nop
	push	xsp
	nop
	nop
	nop

AccDir_Entry:
	jp AccDir_Main

AccDir_PeriodicEntry:
	jp AccDir_PeriodicCheck

AccDir_Main:
	.incbin "includes/generated/v7_transplant_AccDir_Main.bin"
AccDir_CheckLeftNote:
	.incbin "includes/generated/v7_transplant_AccDir_CheckLeftNote.bin"
AccDir_CheckRightHandState:
	.incbin "includes/generated/v7_transplant_AccDir_CheckRightHandState.bin"
AccDir_Finalize:
	calr AccDir_AdjustDirection
	calr AccDir_SavePrevState
	ret

AccDir_Padding1:
	nop
	nop

AccDir_ReadState:
	.incbin "includes/generated/v7_transplant_AccDir_ReadState.bin"
AccDir_ReadState_StoreFlags:
	.incbin "includes/generated/v7_transplant_AccDir_ReadState_StoreFlags.bin"
AccDir_ReadState_Ret:
	ret

AccDir_Padding2:
	nop
	nop

AccDir_SavePrevState:
	.incbin "includes/generated/v7_transplant_AccDir_SavePrevState.bin"
AccDir_SavePrevState_StoreFlags:
	.incbin "includes/generated/v7_transplant_AccDir_SavePrevState_StoreFlags.bin"
AccDir_Padding3:
	nop
	nop

AccDir_AdjustDirection:
	.incbin "includes/generated/v7_transplant_AccDir_AdjustDirection.bin"
AccDir_Adjust_RightDec:
	sll a, 4
	anddi8 (0xfc61), 207
	orddm8 0xfc61, a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	.incbin "includes/generated/v7_transplant_AccDir_Adjust_LeftHand.bin"
AccDir_Adjust_LeftInc:
	sll a, 4
	anddi8 (0xfc61), 207
	orddm8 0xfc61, a
	calr AccDir_DispatchEvent

AccDir_Adjust_SetChanged:
	.incbin "includes/generated/v7_transplant_AccDir_Adjust_SetChanged.bin"
AccDir_Adjust_Ret:
	ret

AccDir_Padding4:
	nop
	nop

AccDir_DispatchEvent:
	.incbin "includes/generated/v7_transplant_AccDir_DispatchEvent.bin"
AccDir_DispatchEvent_Ret:
	ret

AccDir_Padding5:
	nop
	nop

AccDir_PeriodicCheck:
	.incbin "includes/generated/v7_transplant_AccDir_PeriodicCheck.bin"
AccDir_Periodic_CheckCountdown:
	.incbin "includes/generated/v7_transplant_AccDir_Periodic_CheckCountdown.bin"
AccDir_Periodic_DisableAndReset:
	.incbin "includes/generated/v7_transplant_AccDir_Periodic_DisableAndReset.bin"
AccDir_Periodic_Ret:
	ret

AccDir_JumpTable:
	.incbin "includes/generated/v7_transplant_AccDir_JumpTable.bin"
AccProcess_Entry:
	call AccProcess_TimerCompare
	ret

AccProcess_InlinedCode:
	.incbin "includes/generated/v7_transplant_AccProcess_InlinedCode.bin"
AccProcess_TimerCompare:
	.incbin "includes/generated/v7_transplant_AccProcess_TimerCompare.bin"
AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	.incbin "includes/generated/v7_transplant_AccProcess_Timer_WrapCase.bin"
AccProcess_Timer_Ret:
	ret

AccVoice_DispatchEntry:
	jp AccVoice_Dispatch

AccVoice_DispatchWithChannel:
	push xiz
	ld l, a
	ld h, c
	call AccVoice_Dispatch
	ld xhl, xiy
	pop xiz
	ret

AccVoice_GetChannelCount_Wrap:
	push xiz
	ld l, a
	call AccVoice_GetChannelCount
	pop xiz
	ret

AccVoice_GetChannelCount_Direct:
	call AccVoice_GetChannelCount
	ret

AccVoice_CopyFromROM_Wrap:
	push xiz
	ld l, a
	call AccVoice_CopyFromROM
	ld xhl, xiy
	pop xiz
	ret

AccVoice_Dispatch:
	push xwa
	push xbc
	push xde
	push xhl
	push xiy
	cp l, 0x10
	jr c, AccVoice_Dispatch_ClampH
	xor l, l

AccVoice_Dispatch_ClampH:
	cp h, 0x50
	jr c, AccVoice_Dispatch_CheckType
	xor h, h

AccVoice_Dispatch_CheckType:
	cp l, 0xf
	jr nz, AccVoice_Dispatch_Type0E
	calr AccVoice_ROMLookup
	jr AccVoice_Dispatch_Epilogue

AccVoice_Dispatch_Type0E:
	cp l, 0xe
	jr nz, AccVoice_Dispatch_TypeDefault
	calr AccVoice_IndexedTableLookup
	jr AccVoice_Dispatch_Epilogue

AccVoice_Dispatch_TypeDefault:
	calr AccVoice_ComputedCopy

AccVoice_Dispatch_Epilogue:
	.incbin "includes/generated/v7_transplant_AccVoice_Dispatch_Epilogue.bin"
AccVoice_Dispatch_Padding:
	nop
	nop

AccVoice_ComputedCopy:
	.incbin "includes/generated/v7_transplant_AccVoice_ComputedCopy.bin"
AccVoice_ComputedCopy_Padding:
	nop
	nop

AccVoice_ROMLookup:
	.incbin "includes/generated/v7_transplant_AccVoice_ROMLookup.bin"
AccVoice_ROMLookup_OffsetTable:
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01


	naka_header NAKA_TYPE_0x00
	.byte 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0xa0, 0x00
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0xa0, 0x00
	.byte 0x00, 0x00

AccVoice_IndexedTableLookup:
	.incbin "includes/generated/v7_transplant_AccVoice_IndexedTableLookup.bin"
AccVoice_IndexedTableLookup_BaseOffsets:
	.incbin "includes/generated/v7_transplant_AccVoice_IndexedTableLookup_BaseOffsets.bin"
AccVoice_GetChannelCount:
	push xix
	cp l, 0x10
	jr c, AccVoice_GetChannelCount_Lookup
	xor l, l

AccVoice_GetChannelCount_Lookup:
	and hl, 0x1f
	ld xix, AccVoice_ChannelCountTable_0x2
	ldb_sri L, 0x07, 0xf0, 0xec
	pop xix
	ret

AccVoice_ChannelCountTable:
	.byte 0x00, 0x00, 0x0f, 0x0c, 0x10, 0x09, 0x12, 0x0d
	.byte 0x0c, 0x0e, 0x0c, 0x12, 0x0b, 0x0b, 0x0c, 0x0d
	.byte 0x13, 0x0b

AccVoice_CopyFromROM:
	push xwa
	push xbc
	push xhl
	push xiy
	cp l, 0x10
	jr c, AccVoice_CopyFromROM_Do
	xor l, l

AccVoice_CopyFromROM_Do:
	.incbin "includes/generated/v7_transplant_AccVoice_CopyFromROM_Do.bin"
AccVoice_CopyFromROM_DataBlock:
	nop
	nop
	pushw	hl
	calr	64464
	popw	hl
	lds32	xix, 0
	ldw	bc, 8
	ldirw
	ld	xiy, AccVoice_CopyFromROM_DataBlock_0x46
	jr	c, 5
	ld	xiy, AccVoice_CopyFromROM_DataBlock_0x6D
	ld	wa, (xiy)
	ld	c, (xiy+2)
	cp	wa, 0xffff
	jr	z, 28
	cp	wa, hl
	jr	z, 6
	add	iy, 3
	jr	-21
	cps	c, 0
	jr	nz, 8
	ldio	0, 0
	ldio	1, 1
	jr	6
	ldio	11, 0
	ldio	12, 1
	lds32	xiy, 0
	ret
	nop
	nop
	pop	sr
	push	sr
	nop
	.byte 0x04
	pop	sr
	nop
	.byte 0x04, 0x04
	nop
	halt
	push	sr
	nop
	ei	4
	nop
	ei	6
	.byte 0x01
	pushw	3
	pushw	4
	decf
	push	sr
	nop
	decf
	reti
	.byte 0x01
	ret
	.byte 0x01
	nop
	swi	7
	swi	7
	nop
	swi	7
	swi	7
	nop
	pop	sr
	push	sr
	nop
	.byte 0x04
	push	sr
	nop
	.byte 0x04
	di
	halt
	push	sr
	nop
	pushw	2
	pushw	261
	decf
	push	sr
	nop
	ret
	reti
	nop
	ret
	push	1
	ret
	ldwio	1, 0xffff
	nop
	swi	7
	swi	7
	nop

AccStyle_Entry:
	jp AccStyle_Process
AccStyle_JumpTable:
	jp	AccStyle_ToggleBit0
	jp	AccStyle_ModeEnter
	jp	AccStyle_ModeExit
	jp	AccStyle_InlinedBlock_0x6

AccStyle_InitVRAM_Wrap:
	push xiz
	call AccStyle_InitVRAM
	pop xiz
	ret

AccStyle_JumpTable2:
	jp	AccStyle_IndexedLookup
	jp	AccStyle_SC0ByteSelect
	jp	AccStyle_SC0ByteSelect_0x19
	jp	AccStyle_SC0ByteSelect_0x32
	jp	AccStyle_SC0ByteSelect_0x4B
	jp	AccStyle_SC0ByteSelect_0x64
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop

AccStyle_Process:
	.incbin "includes/generated/v7_transplant_AccStyle_Process.bin"
AccStyle_Process_DoChain:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1e7810
	calr AccVoiceDelta_Part1
	calr AccVoiceDelta_Part2
	calr AccVoiceDelta_Part3
	calr AccVoiceDelta_Part4
	calr AccVoiceDelta_Part5

AccStyle_Process_SaveState:
	.incbin "includes/generated/v7_transplant_AccStyle_Process_SaveState.bin"
AccStyle_ToggleBit0:
	.incbin "includes/generated/v7_transplant_AccStyle_ToggleBit0.bin"
AccStyle_ToggleBit0_CheckC07D:
	.incbin "includes/generated/v7_transplant_AccStyle_ToggleBit0_CheckC07D.bin"
AccStyle_ToggleBit0_CallOn:
	call AccTuning_LEDOn
AccStyle_ToggleBit0_Ret:
	ret
AccStyle_IndexedLookup:
	.incbin "includes/generated/v7_transplant_AccStyle_IndexedLookup.bin"
AccStyle_IndexedLookup_Ret:
	ret


AccStyle_ModeEnter_Wrap:
	push xiz
	calr AccStyle_ModeEnter
	pop xiz
	ret

AccStyle_ModeEnter:
	.incbin "includes/generated/v7_transplant_AccStyle_ModeEnter.bin"
AccStyle_ModeEnter_SetFlags:
	.incbin "includes/generated/v7_transplant_AccStyle_ModeEnter_SetFlags.bin"
AccStyle_ModeEnter_Ret:
	ret

AccStyle_ModeExit_Wrap:
	push xiz
	calr AccStyle_ModeExit
	pop xiz
	ret

AccStyle_ModeExit:
	.incbin "includes/generated/v7_transplant_AccStyle_ModeExit.bin"
AccStyle_ModeExit_ClearFlags:
	.incbin "includes/generated/v7_transplant_AccStyle_ModeExit_ClearFlags.bin"
AccStyle_ModeExit_Ret:
	ret

AccStyle_InlinedBlock:
	.incbin "includes/generated/v7_transplant_AccStyle_InlinedBlock.bin"
AccVoiceReg_WritePart3:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart3.bin"
AccVoiceReg_WritePart3_StoreBit4:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart3_StoreBit4.bin"
AccVoiceReg_WritePart3_Ret:
	ret

AccVoiceReg_WritePart4:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart4.bin"
AccVoiceReg_WritePart4_StoreBit4:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart4_StoreBit4.bin"
AccVoiceReg_WritePart4_Ret:
	ret

AccVoiceReg_WritePart5:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart5.bin"
AccVoiceReg_WritePart5_StoreBit4:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart5_StoreBit4.bin"
AccVoiceReg_WritePart5_Ret:
	ret

AccVoiceReg_WritePart2:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart2.bin"
AccVoiceReg_WritePart2_StoreBit4:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart2_StoreBit4.bin"
AccVoiceReg_WritePart2_Ret:
	ret

AccVoiceReg_WritePart1:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_WritePart1.bin"
AccVoiceReg_WritePart1_Ret:
	ret

AccVoiceState_Snapshot:
	.incbin "includes/generated/v7_transplant_AccVoiceState_Snapshot.bin"
AccVoiceState_DispatchChange:
	.incbin "includes/generated/v7_transplant_AccVoiceState_DispatchChange.bin"
AccVoiceState_PartLookupTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0xbe, 0xfb, 0x00, 0x00
	.byte 0xa4, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x56, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x70, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x8a, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 56
	.byte 0x00, 0x00, 0x00, 0x00, 0x6a, 0xff, 0x00, 0x00
	.byte 0x56, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x1a, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x2e, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x42, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 56

AccVoiceDelta_Part1:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part1.bin"
AccVoiceDelta_Part1_Store:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part1_Store.bin"
AccVoiceDelta_Part2:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part2.bin"
AccVoiceDelta_Part2_Store:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part2_Store.bin"
AccVoiceDelta_Part3:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part3.bin"
AccVoiceDelta_Part3_Store:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part3_Store.bin"
AccVoiceDelta_Part4:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part4.bin"
AccVoiceDelta_Part4_Store:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part4_Store.bin"
AccVoiceDelta_Part5:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part5.bin"
AccVoiceDelta_Part5_Store:
	.incbin "includes/generated/v7_transplant_AccVoiceDelta_Part5_Store.bin"
AccStyle_InitVRAM:
	xor a, a
	ld xiy, Display_FontPalette_Table_0x3127
	ld xix, 0x1e7800
	ldw bc, 0x7e0
	ldir85
	ret

AccStyle_SC0ByteSelect:
	.incbin "includes/generated/v7_transplant_AccStyle_SC0ByteSelect.bin"
AccHelper_ComputeVoiceOffset:
	.incbin "includes/generated/v7_transplant_AccHelper_ComputeVoiceOffset.bin"
AccHelper_VoiceOffset_Loop:
	cp h, l
	jr z, AccHelper_VoiceOffset_Done
	pushw hl
	push xwa
	call AccVoice_GetChannelCount_Direct
	pop xwa
	inc 1, l
	add a, l
	popw hl
	inc 1, l
	jr AccHelper_VoiceOffset_Loop

AccHelper_VoiceOffset_Done:
	ld xhl, xwa
	sla xwa, 3
	sla xhl, 1
	add xhl, xwa
	ret

AccDemo_Init_Wrap:
	calr AccDemo_Init
	ret

AccDemo_Init:
	.incbin "includes/generated/v7_transplant_AccDemo_Init.bin"
AccDemo_Init_ConfigTimers:
	.incbin "includes/generated/v7_transplant_AccDemo_Init_ConfigTimers.bin"
AccDemo_Init_DataBlock:
	nop
	nop
	ld	xix, 0x094800
	ld	(xix+2976), 0
	ld	(xix+2977), 1
	ld	(xix+2978), 2
	ld	(xix+2979), 3
	ret

AccDemo_LoadRhythm:
	ld xiy, Demo_StyleRhythmData
	ld xix, 0x94800
	add xix, 0x0
	ldw bc, 0x60
	ldir85
	ret

AccDemo_LoadVariation:
	ldb a, 0x0
	ld xix, 0x94800
	add xix, 0x60
	lds hl, 0

AccDemo_LoadVariation_EntryLoop:
	ld (xix), hl
	inc 2, xix
	ldw (xix), 0x0
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 1, hl
	inc 2, xix
	ld xiy, Demo_StyleRhythmData_0x240
	ldw bc, 0x34
	ldir85
	ld xiy, Demo_StyleRhythmData_0x60
	xor xde, xde
	ld e, a
	mul e, 0x10
	add xiy, xde
	ldw bc, 0x10
	ldir85
	ld xiy, Demo_StyleRhythmData_0x57C
	ldw bc, 0x10
	ldir85
	add a, 0x1
	cp a, 0x1e
	jr lt, AccDemo_LoadVariation_EntryLoop
	ret

AccDemo_LoadVariation_DataBlock:
	ld	xiy, Demo_StyleRhythmData_0x274
	ld	xix, 0x094800
	add	xix, 2976
	ldw	bc, 160
	.byte 0x85
	scf
	ret
	lds32	xwa, 0
	ld	xix, 0x094800
	add	xix, 3136
	lds32	xde, 0
	.byte 0xd7
	lds32	xde, 6
	ld	de, wa
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	add	wa, 1
	cp	wa, 60
	jr	lt, -79
	ret

AccDemo_LoadFillIn:
	ldw bc, 0x40
	ld xix, 0x94800
	add xix, 0x13c0
	ld xiy, Demo_StyleRhythmData_0x334
	ldir85
	ret

AccDemo_LoadVariationData:
	ld xix, 0x94800
	add xix, 0x1400
	ldb a, 0x1e

Demo_LoadVariationData:
	ld xiy, Demo_StyleRhythmData_0x374
	ldw bc, 0x100
	ldir85
	ldb l, 0x4

Demo_LoadVariationData_Inner:
	ld xiy, Demo_StyleRhythmData_0x474
	ldw bc, 0x100
	ldir85
	dec 1, l
	cps l, 0
	jr gt, Demo_LoadVariationData_Inner
	dec 1, a
	cps a, 0
	jr nz, Demo_LoadVariationData
	ret

Demo_LoadVariationC_Data:
	ld xix, 0x94800
	add xix, 0xaa00
	ldb a, 0xbe

Demo_LoadVariationC_Loop:
	ld xiy, Demo_StyleRhythmData_0x574
	ldw bc, 0x100
	ldir85
	dec 1, a
	cps a, 0
	jr nz, Demo_LoadVariationC_Loop
	ret

Demo_StyleRhythmData:
	popw	wa
	nop
	popw	hl
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop	xde
	pop	xde
	pop	xde
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01, 0x01, 0x01
	push	sr
	push	sr
	push	sr
	push	sr
	nop
	cpd
	jr	f, 0
	jr	f, 0
	calr	0
	.byte 0x01, 0x54, 0x01
	ld	xwa, 0x80000000
	ex_ff
	.zero 48
	.ascii "a-variation1    a-variation2    a-variation3    a-variation4    b-variation1    b-variation2    b-variation3    b-variation4    c-variation1    c-variation2    c-variation3    c-variation4     a-intro 1       a-intro 2       a-fill in 1     a-fill in 2     a-ending 1      a-ending 2      b-intro 1       b-intro 2       b-fill in 1     b-fill in 2     b-ending 1      b-ending 2      c-intro 1       c-intro 2       c-fill in 1     c-fill in 2     c-ending 1      c-ending 2     "
	reti
	pop	sr
	ldb	w, 0
	pop	xwa
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ld	xwa, 0x7f005000
	nop
	pushw	wa
	nop
	ld	xwa, 0x7f065000
	nop
	nop
	nop
	ld	xwa, 0x7f065000
	nop
	.byte 0x1c
	nop
	ld	xwa, 0x7f065000
	nop
	call	0x4000
	.byte 0x50, 0x06
	jrl	nc, 0
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 1     "
	.byte 0x01
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 2     "
	push	sr
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 3     "
	pop	sr
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 4     "
	.byte 0x04
	swi	7
	swi	7
	swi	7
	.zero 12
	.asciz "chord map 5     "
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81
	.byte 0x81, 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 40
	nop
	nop
	nop
	.byte 0x87
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 128
	nop
	nop
	nop
	.byte 0x87
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81
	.fill 8, 1, 0x81
	.byte 0x81, 0x81, 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 224
	nop
	nop
	nop
	.byte 0x87
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x87
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 240
	nop
	nop
	nop
	.byte 0x87

AccTone_LookupByProgram:
	sub a, 0xf0
	extz wa
	sla wa, 2
	lda_24 xbc, (Display_FontPalette_Table_0x515C)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld a, (xde)
	extz wa
	sla wa, 2
	lda_24 xbc, (RhythmTiming_OffsetTable)
	ld xde, 0x94860
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, (Display_FontPalette_Table_0x1D32)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

AccTone_ReadAndProcess:
	dec 4, xsp
	lda_d16 xbc, (0xfc5a)
	ld e, (xbc)
	and e, 0xff
	lda xwa, (xsp + 2)
	ld (xwa), e
	ld e, (xbc + 1)
	res 7, e
	ld (xwa + 1), e
	call AccTone_ValidateAndClamp
	lda xwa, (xsp)
	lda xbc, (xsp + 2)
	call AccTone_WriteProgramChange
	lda xwa, (xsp + 2)
	cp (xwa), 0x80
	jr nc, AccTone_Process_Under80
	lda xbc, (xsp)
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	calr AccTone_NoteLookup
	jr AccTone_Process_Cleanup

AccTone_Process_Under80:
	cp (xwa), 0xf0
	jr nc, AccTone_Process_UnderF0
	ld e, (xwa)
	res 7, e
	ld c, (xwa + 1)
	extz de
	extz bc
	ld wa, de
	jr AccTone_Process_CalcResult

AccTone_Process_UnderF0:
	ld a, (xwa)
	sub a, 0xf0
	extz wa
	sla wa, 2
	lda_24 xbc, (Display_FontPalette_Table_0x515C)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld e, (xwa)
	extz de
	ld wa, de
	lds bc, 0

AccTone_Process_CalcResult:
	calr AccTone_ExtendAndDispatch

AccTone_Process_Cleanup:
	inc 4, xsp
	ret

AccTone_NoteLookup:
	ldb_erp A, 0xf4
	extz iy
	ldw_d16 xde, (4360)
	ld ix, de
	and ix, 0x4
	lda_24 xhl, (Display_FontPalette_Table_0x1EBF)
	ld a, c
	add a, c
	mul iy, 0x28
	ld c, a
	extz bc
	ld wa, iy
	add wa, bc
	cps ix, 4
	jr z, AccTone_NoteLookup_ReadTable
	ld bc, de
	and bc, 0x400
	cp bc, 0x400
	jr nz, AccTone_NoteLookup_CheckBit3
	inc 1, wa

AccTone_NoteLookup_ReadTable:
	extz xwa
	add xhl, xwa
	ld l, (xhl)
	jr AccTone_NoteLookup_Ret

AccTone_NoteLookup_CheckBit3:
	and de, 0x8
	ldb l, 0x0
	cp de, 0x8
	ret nz
	ldb l, 0x1

AccTone_NoteLookup_Ret:
	ret

AccTone_ExtendAndDispatch:
	extz bc
	extz wa
	jr AccTone_ExtendAndDispatch_Body

AccTone_ExtendAndDispatch_Body:
	push xiz
	extz bc
	sla bc, 2
	lda_24 xde, (Display_FontPalette_Table_0x513C)
	ld_sril3 XIY, 0x07, 0xe8, 0xe4
	ld e, a
	extz de
	ld wa, de
	sla wa, 2
	lda_24 xix, (RhythmTiming_OffsetTable)
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld a, (xiz + 12)
	extz wa
	lda_24 xhl, (Display_FontPalette_Table_0x1D32)
	ldb_sri A, 0x07, 0xec, 0xe0
	ldb_erp A, 0xe2
	lda_24 xiz, (Display_FontPalette_Table_0x511C)
	ld_sril3 XBC, 0x07, 0xf8, 0xe4
	add de, 0x11
	ldb_sri C, 0x07, 0xe4, 0xe8
	ldw_d16 xwa, (4360)
	ld de, wa
	and de, 0x4
	extz bc
	cps de, 4
	jr nz, AccTone_CheckBit10Flag
	lda_24 xde, (Display_FontPalette_Table_0x51E4)
	ldb_sri A, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld c, (xiz + 12)
	extz bc
	stb_erp A, 0xe2
	cpb_sri_rm A, 0x07, 0xec, 0xe4
	jr z, AccTone_FoundMatch_IncRet

AccTone_SetupExit:
	ldb l, 0x0

AccTone_ExtendAndDispatch_PopRet:
	pop xiz
	ret

AccTone_CheckBit10Flag:
	ld de, wa
	and de, 0x400
	cp de, 0x400
	jr nz, AccTone_CheckBit3Flag
	lda_24 xde, (Display_FontPalette_Table_0x51E8)
	ldb_sri A, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld c, (xiz + 12)
	extz bc
	stb_erp A, 0xe2
	cpb_sri_rm A, 0x07, 0xec, 0xe4
	jr nz, AccTone_SetupExit

AccTone_FoundMatch_IncRet:
	ld l, (xiz + 13)
	inc 1, l
	jr AccTone_ExtendAndDispatch_PopRet

AccTone_CheckBit3Flag:
	and wa, 0x8
	cp wa, 0x8
	jr nz, AccTone_SetupExit
	stb_erp A, 0xe2
	extz wa
	lda_24 xbc, (Display_FontPalette_Table_0x1D58)
	bit_dri 0, 0x07, 0xe4, 0xe0
	jr nz, AccTone_SetupExit
	ldb l, 0x1
	jr AccTone_ExtendAndDispatch_PopRet
	dec 4, xsp
	ldw_d16 xde, (4360)
	and de, 0x40c
	jrl z, AccTone_LookupFailed
	extz bc
	sla bc, 2
	lda_24 xde, (Display_FontPalette_Table_0x513C)
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	lda_24 xbc, (RhythmTiming_OffsetTable)
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, (Display_FontPalette_Table_0x1D32)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_24 xbc, (Display_FontPalette_Table_0x1D58)
	bit_dri 0, 0x07, 0xe4, 0xe0
	jr nz, AccTone_LookupFailed
	lda xwa, (xsp)
	ld c, (xde + 16)
	ld (xwa), c
	ld e, (xde + 17)
	ld (xwa + 1), e
	ld l, (xwa)
	extz hl
	extz de
	sll de, 8
	ld bc, de
	or bc, hl
	cp bc, 0x208
	jr z, AccTone_CheckDirectAddr
	ld c, (xwa)
	extz bc
	or de, bc
	cp de, 0x318
	jr nz, AccTone_ValidateAndWrite

AccTone_CheckDirectAddr:
	.incbin "includes/generated/v7_transplant_AccTone_CheckDirectAddr.bin"
AccTone_DirectAddr_Mode1:
	ldb l, 0x2
	jr AccTone_LookupDone

AccTone_DirectAddr_Mode2:
	ldb l, 0x1
	jr AccTone_LookupDone

AccTone_ValidateAndWrite:
	call AccTone_ValidateAndClamp
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call AccTone_WriteProgramChange
	lda xbc, (xsp + 2)
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	calr AccTone_NoteLookup
	jr AccTone_LookupDone

AccTone_LookupFailed:
	ldb l, 0x0

AccTone_LookupDone:
	inc 4, xsp
	ret

AccTone_InlineBytecodeData:
	.incbin "includes/generated/v7_transplant_AccTone_InlineBytecodeData.bin"
AccVoice_ClearChannelStates:
	.incbin "includes/generated/v7_transplant_AccVoice_ClearChannelStates.bin"
AccVoice_IncrementBarCounter:
	.incbin "includes/generated/v7_transplant_AccVoice_IncrementBarCounter.bin"
AccVoice_BarCounterBytecodeData:
	.incbin "includes/generated/v7_transplant_AccVoice_BarCounterBytecodeData.bin"
AccTuning_ReadAndApplyOffset:
	.incbin "includes/generated/v7_transplant_AccTuning_ReadAndApplyOffset.bin"
AccTuning_ComplexBytecodeData:
	.incbin "includes/generated/v7_transplant_AccTuning_ComplexBytecodeData.bin"
AccTone_WriteProgramChange:
	.incbin "includes/generated/v7_transplant_AccTone_WriteProgramChange.bin"
AccTone_ValidateAndClamp:
	push xiz
	ld xbc, xwa
	ld l, (xbc)
	ld h, (xbc + 1)
	push xbc
	call VoiceParam_ClampAndValidate
	pop xbc
	ld (xbc), l
	ld (xbc + 1), h
	pop xiz
	ret

AccTone_LookupByProgram_Dispatch:
	.incbin "includes/generated/v7_transplant_AccTone_LookupByProgram_Dispatch.bin"
AccTone_CallWithSaveAll:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccVoice_ClearChannelStates
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccVoice_IncrementBarWithSave:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccVoice_IncrementBarCounter
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccTuning_DispatchDataBlock_A:	.ascii "<=>89:;"
	call	AccVoice_BarCounterBytecodeData
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	call	AccVoice_BarCounterBytecodeData_0x11A
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	call	AccVoice_BarCounterBytecodeData_0x215
	.ascii "[ZYX^]\\"
	ret
	.ascii "<=>89:;"
	call	AccVoice_BarCounterBytecodeData_0x30A
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	call	AccTone_ReadAndProcess
	ld	a, l
	pop	xhl
	pop	xde
	ld	e, a
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret

AccTuning_CallWithSaveRestore:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccTuning_ReadAndApplyOffset
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccTuning_DispatchDataBlock_B:	.ascii "<=>9;"
	call	AccTuning_ComplexBytecodeData
	pop	xhl
	pop	xbc
	pop	xiz
	pop	xiy
	pop	xix
	ret

AccTone_LookupByProgramWrapped:
	push xix
	push xiy
	push xiz
	push xbc
	push xhl
	and xwa, 0xff
	xor xbc, xbc
	ld c, d
	call AccTone_LookupByProgram
	ld a, l
	pop xhl
	pop xbc
	pop xiz
	pop xiy
	pop xix
	ret

AccTone_JumpTableData:
	.incbin "includes/generated/v7_transplant_AccTone_JumpTableData.bin"
AccTone_StubReturn_A:
	ret

AccTone_StubReturn_B:
	ret

AccPatch_CountSlots_Wrapper:
	calr AccPatch_CountAvailableSlots
	ret

AccPatch_CountSlotsAlt:
	calr AccPatch_CountSlotsAlt_Body
	ret

AccPatch_InitAndCountSlots:
	.incbin "includes/generated/v7_transplant_AccPatch_InitAndCountSlots.bin"
AccDemo_InitDone:
	push xiz
	call AccDemo_Init_Wrap
	calr AccPatch_CountAvailableSlots
	pop xiz
	ret

AccPatch_InitByteData:
	.incbin "includes/generated/v7_transplant_AccPatch_InitByteData.bin"
AccDemo_InitWithFlag:
	.incbin "includes/generated/v7_transplant_AccDemo_InitWithFlag.bin"
AccPatch_MultiCallWrapper:
	push	xiz
	calr	4559
	calr	18
	pop	xiz
	ret
	push	xiz
	calr	12
	call	AccPatch_InitSlotChain_WithAddr
	pop	xiz
	ret
	push	xiz
	calr	2
	pop	xiz
	ret

AccPatch_ClearModeFlag:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearModeFlag.bin"
Not_sure_maybe_SOFT_VERSION_related:
	.incbin "includes/generated/v7_transplant_Not_sure_maybe_SOFT_VERSION_related.bin"
AccPatch_CheckAndInitDemo:
	ld xiy, 0x94800
	add xiy, 0xe
	ld wa, (xiy)
	cps wa, 0
	jr z, AccPatch_CheckAndInitDemo_Ret
	call AccDemo_Init_Wrap

AccPatch_CheckAndInitDemo_Ret:
	ret

AccPatch_SlotConfigByteData:
	.incbin "includes/generated/v7_transplant_AccPatch_SlotConfigByteData.bin"
AccPatch_InitCurrentSlotPointer:
	.incbin "includes/generated/v7_transplant_AccPatch_InitCurrentSlotPointer.bin"
AccPatch_SlotScanByteData:
	.incbin "includes/generated/v7_transplant_AccPatch_SlotScanByteData.bin"
AccPatch_RefreshSlotOffset_Wrap:
	push xiz
	call AccPatch_RefreshSlotOffset
	pop xiz
	ret

AccPatch_RefreshSlotOffset:
	calr AccPatch_GetCurrentSlotAddr
	lds32 xhl, 0
	ld l, (xiy + 12)
	sll l, 1
	add xhl, AccPatch_VoiceStrideTable
	ld wa, (xhl)
	ld (xiy + 16), wa
	ret

Seq_RhythmProcessor:
	calr RhythmProc_CheckStyleChange
	calr RhythmProc_CheckPlayMode
	calr RhythmProc_CallDispatch
	calr RhythmProc_NullStub
	calr RhythmProc_CheckRhythmEdit
	calr RhythmProc_CheckStyleSwitch
	calr RhythmProc_CheckRepeatFlag
	calr AccPatch_ProcessPartChanges
	calr RhythmProc_SavePrevState
	ret

RhythmProc_CheckStyleChange:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckStyleChange.bin"
RhythmProc_StyleChange_Init:
	.incbin "includes/generated/v7_transplant_RhythmProc_StyleChange_Init.bin"
RhythmProc_StyleChange_Ret:
	ret

RhythmProc_CheckPlayMode:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckPlayMode.bin"
RhythmProc_PlayMode_Compare:
	.incbin "includes/generated/v7_transplant_RhythmProc_PlayMode_Compare.bin"
RhythmProc_PlayMode_SendTempo:
	.incbin "includes/generated/v7_transplant_RhythmProc_PlayMode_SendTempo.bin"
AccPatch_DetectModeChange:
	.incbin "includes/generated/v7_transplant_AccPatch_DetectModeChange.bin"
AccPatch_CopySlotsExit:
	ret

RhythmProc_CallDispatch:
	call AccPlayback_InitOrUpdate
	ret

RhythmProc_NullStub:
	ret

RhythmProc_CopySlotData_Wrap:
	push xiz
	call RhythmProc_CopySlotData
	pop xiz
	ret

RhythmProc_CopySlotData:
	.incbin "includes/generated/v7_transplant_RhythmProc_CopySlotData.bin"
RhythmProc_ChannelMapTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x04, 0x04
	.byte 0x08, 0x08, 0x08, 0x08, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	.fill 6, 1, 0x08

; ============================================================================
; AccPatch_GetCurrentSlotAddr - Get address of current accompaniment patch slot
; ============================================================================
; Input:  None (reads current slot index from 13526)
; Output: XIY = pointer to patch slot data (at 0x94800 + slot*96 + 96)
; Reads the current patch slot index (0-29, capped), multiplies by 96-byte
; stride, and returns a pointer into the accompaniment patch table at 0x94800.
; ============================================================================
AccPatch_GetCurrentSlotAddr:
	.incbin "includes/generated/v7_transplant_AccPatch_GetCurrentSlotAddr.bin"
AccPatch_GetSlotAddr_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ld xiy, 0x94800
	add xiy, xhl
	ret

AccPatch_GetSlotAddr_Preserve:
	.incbin "includes/generated/v7_transplant_AccPatch_GetSlotAddr_Preserve.bin"
AccPatch_GetEntryAddr:
	cp hl, 0xffff
	jr z, AccPatch_GetEntryAddr_Ret
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xix, 0x95c00
	add xix, xhl
	popw hl

AccPatch_GetEntryAddr_Ret:
	ret

AccPatch_InitCurrentSlot:
	.incbin "includes/generated/v7_transplant_AccPatch_InitCurrentSlot.bin"
AccPatch_InitFromSlotIndex:
	push xiz
	calr AccPatch_InitFromIndex
	pop xiz
	ret

AccPatch_InitFromIndex:
	.incbin "includes/generated/v7_transplant_AccPatch_InitFromIndex.bin"
AccPatch_InitFromIndex_Valid:
	.incbin "includes/generated/v7_transplant_AccPatch_InitFromIndex_Valid.bin"
AccPatch_InitByteStub:
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	.incbin "includes/generated/v7_transplant_AccPat_InitWorkAreaFromSlot.bin"
AccPatch_CopyDefaultsToSlot:
	push xiy
	push xwa
	push xbc
	ld a, (xiy + 12)
	pushw wa
	ld wa, (xiy + 16)
	pushw wa
	push xiy
	add xiy, 0xc
	ld xix, AccPatch_DefaultSlotData
	ld xbc, 0x54
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	pop xiy
	popw wa
	ld bc, wa
	popw wa
	cps a, 7
	jr nz, AccPatch_CopyDefaults_Done
	ld (xiy + 16), bc

AccPatch_CopyDefaults_Done:
	pop xbc
	pop xwa
	pop xiy
	calr AccPatch_ClearSlot13ByIndex
	ret

AccPatch_ClearSlot13ByIndex:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13ByIndex.bin"
AccPatch_ClearSlot13_Check0F:
	cp w, 0xf
	jr nz, AccPatch_ClearSlot13_Check14
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check14:
	cp w, 0x14
	jr nz, AccPatch_ClearSlot13_Check15
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check15:
	cp w, 0x15
	jr nz, AccPatch_ClearSlot13_Check1A
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check1A:
	cp w, 0x1a
	jr nz, AccPatch_ClearSlot13_Check1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check1B:
	cp w, 0x1b
	jr nz, AccPatch_ClearSlot13_Done
	ld (xiy + 13), a

AccPatch_ClearSlot13_Done:
	pop xwa
	ret

AccPatch_MiscByteData:
	.incbin "includes/generated/v7_transplant_AccPatch_MiscByteData.bin"
AccPatch_FreeAllChains:
	ld hl, (xiy + 256)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 4)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 6)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 8)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 10)
	calr AccPatch_FreeChainEntries
	ret

AccPatch_FreeChainEntries:
	push xiy
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Done

AccPatch_FreeChainLoop:
	.incbin "includes/generated/v7_transplant_AccPatch_FreeChainLoop.bin"
AccPatch_FreeChain_Done:
	pop xiy
	ret

AccPatch_FillAllVoiceData:
	ld hl, (xiy + 256)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 4)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 6)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 8)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 10)
	calr AccPatch_FillEntryWithVoiceData
	ret

AccPatch_FillEntryWithVoiceData:
	push xiy
	pushw hl
	ld l, (xiy + 12)
	xor h, h
	lds32 xwa, 0
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xe4, 0xec
	lds32 xbc, 0
	ld b, (xiy + 13)
	inc 1, b
	mul8rr a, b
	popw hl
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	ldb l, 0x81

AccPatch_FillVoice_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cps wa, 0
	jr nz, AccPatch_FillVoice_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_CopyDefaultsForInit:
	push xiy
	push xwa
	push xbc
	ld a, (xiy + 12)
	pushw wa
	ld wa, (xiy + 16)
	pushw wa
	push xiy
	add xiy, 0xc
	ld xix, AccPatch_DefaultSlotData
	ld xbc, 0x54
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	pop xiy
	popw wa
	ld bc, wa
	popw wa
	cps a, 7
	jr nz, AccPatch_CopyDefaults_InitDone
	ld (xiy + 16), bc

AccPatch_CopyDefaults_InitDone:
	pop xbc
	pop xwa
	pop xiy
	calr AccPatch_ClearSlot13BySlotIdx
	ret

AccPatch_DefaultSlotData:
	reti
	.byte 0x01
	ldb	w, 128
	pop	xwa
	push	sr
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	pushw	wa
	nop
	ld	xwa, 0x7f065000
	nop
	nop
	nop
	incf
	nop
	.byte 0x50, 0x06
	jrl	nc, 14336
	nop
	jrl	ov, 20480
	.byte 0x06
	jrl	nc, 16640
	nop
	ld	xwa, 0x7f065000
	nop
	.asciz "    clear       "
	.zero 15

AccPatch_ClearSlot13BySlotIdx:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13BySlotIdx.bin"
AccPatch_ClearSlot13_Idx0F:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13_Idx0F.bin"
AccPatch_ClearSlot13_Idx14:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13_Idx14.bin"
AccPatch_ClearSlot13_Idx15:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13_Idx15.bin"
AccPatch_ClearSlot13_Idx1A:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13_Idx1A.bin"
AccPatch_ClearSlot13_Idx1B:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearSlot13_Idx1B.bin"
AccPatch_ClearSlot13_IdxDone:
	ret

AccPatch_SetVoiceAndInit:
	.incbin "includes/generated/v7_transplant_AccPatch_SetVoiceAndInit.bin"
AccPatch_VoiceStrideTable:
	.byte 0x00, 0x00, 0x58, 0x02, 0x08, 0x02, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03

AccPatch_CheckConfigType:
	.incbin "includes/generated/v7_transplant_AccPatch_CheckConfigType.bin"
RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	.incbin "includes/generated/v7_transplant_AccPatch_InitAllSentinels.bin"
AccPatch_InitSlotSentinels:
	push xiy
	push c
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	pop c
	ld b, c

AccPatch_WriteSentinel_Loop:
	ld (xix), 0x81
	inc 1, xix
	dec 1, b
	cps b, 0
	jr nz, AccPatch_WriteSentinel_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_ReadVoiceStride:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadVoiceStride.bin"
RhythmProc_CheckRhythmEdit:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckRhythmEdit.bin"
RhythmProc_RhythmEdit_Ret:
	ret

RhythmProc_CheckVoiceChange:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckVoiceChange.bin"
RhythmProc_CheckVoiceUpdate:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckVoiceUpdate.bin"
RhythmProc_VoiceUpdate_Ret:
	ret

RhythmProc_UpdateVoiceSentinels:
	.incbin "includes/generated/v7_transplant_RhythmProc_UpdateVoiceSentinels.bin"
RhythmProc_CheckConfigBits:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckConfigBits.bin"
RhythmProc_ConfigBit1:
	.incbin "includes/generated/v7_transplant_RhythmProc_ConfigBit1.bin"
RhythmProc_ConfigBit2:
	.incbin "includes/generated/v7_transplant_RhythmProc_ConfigBit2.bin"
RhythmProc_ConfigBit2_SetBit6:
	.incbin "includes/generated/v7_transplant_RhythmProc_ConfigBit2_SetBit6.bin"
RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	.incbin "includes/generated/v7_transplant_AccPatch_RebuildChannelSlot.bin"
AccPatch_RebuildChannel_Done:
	ret

MapBitFlagsToChannelOffset:
	ldb w, 0x0
	bit 4, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x4
	bit 3, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x6
	bit 0, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x8
	bit 1, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0xa

MapBitFlags_NullRet:
	ret

AccPatch_ComputeSeqPosition:
	.incbin "includes/generated/v7_transplant_AccPatch_ComputeSeqPosition.bin"
AccPatch_SeqPosition_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqPosition_Store.bin"
AccPatch_SeqBaseAddrTable:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqBaseAddrTable.bin"
AccPatch_WriteRhythmInit:
	.incbin "includes/generated/v7_transplant_AccPatch_WriteRhythmInit.bin"
AccPatch_WriteRhythm_Done:
	ret

AccPatch_ChannelToParamTable:
	.incbin "includes/generated/v7_transplant_AccPatch_ChannelToParamTable.bin"
AccPatch_WriteRhythmParams:
	calr AccPatch_FetchVolumeForChannel
	push_a
	lds32 xwa, 0
	pop_a
	ldb c, 0x0

AccPatch_WriteRhythmParam_Loop:
	.incbin "includes/generated/v7_transplant_AccPatch_WriteRhythmParam_Loop.bin"
AccPatch_WriteRhythmParam_Push:
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop xwa
	pop c
	inc 1, c
	jr AccPatch_WriteRhythmParam_Loop

AccPatch_WriteRhythmParam_Done:
	ret

AccPatch_RhythmParamDefaults:
	.byte 0x01
	nop
	push	sr
	ld	xwa, 0x40040003
	halt
	jrl	nc, 6

AccPatch_FetchVolumeForChannel:
	push xwa
	push xhl
	push xix
	push xiy
	calr AccPatch_GetCurrentSlotAddr
	ld xix, 0x22
	cp a, 0xd7
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x2a
	cp a, 0xd4
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x32
	cp a, 0xd5
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x3a
	cp a, 0xd6
	jr z, ToneGen_FetchSelectRestore
	ldb a, 0x40
	jr AccPatch_FetchVolume_Default

ToneGen_FetchSelectRestore:
	add xix, xiy
	ld a, (xix)

AccPatch_FetchVolume_Default:
	.incbin "includes/generated/v7_transplant_AccPatch_FetchVolume_Default.bin"
RhythmProc_CheckStyleSwitch:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckStyleSwitch.bin"
RhythmProc_StyleSwitch_Call:
	call AccPat_DispatchNoteChange

RhythmProc_StyleSwitch_Ret:
	ret

RhythmProc_CheckRepeatFlag:
	.incbin "includes/generated/v7_transplant_RhythmProc_CheckRepeatFlag.bin"
RhythmProc_RepeatFlag_Store:
	ld (xiy), a

RhythmProc_RepeatFlag_Ret:
	ret

RhythmProc_SavePrevState:
	.incbin "includes/generated/v7_transplant_RhythmProc_SavePrevState.bin"
RhythmProc_SavePrevState_Done:
	ret

AccPatch_CountAvailableSlots:
	ldw wa, 0xbe
	ldw de, 0x153
	xor iy, iy

AccPatch_CountSlots_Loop:
	ld hl, de
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_CountSlots_Dec
	dec 1, wa

AccPatch_CountSlots_Dec:
	dec 1, de
	cp de, 0x95
	jr z, AccPatch_CountSlots_Store
	jr AccPatch_CountSlots_Loop

AccPatch_CountSlots_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_CountSlots_Store.bin"
AccPatch_CountSlotsAlt_Body:
	.incbin "includes/generated/v7_transplant_AccPatch_CountSlotsAlt_Body.bin"
AccPatch_CountSlotsAlt_Loop:
	ld hl, de
	calr AccPatch_ResolveSlotAddr
	bitm 7, (xix)
	jr z, AccPatch_CountSlotsAlt_Dec
	dec 1, wa

AccPatch_CountSlotsAlt_Dec:
	dec 1, de
	cp de, 0x95
	jr z, AccPatch_CountSlotsAlt_Store
	jr AccPatch_CountSlotsAlt_Loop

AccPatch_CountSlotsAlt_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_CountSlotsAlt_Store.bin"
AccPatch_MiscDataBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_MiscDataBlock.bin"
AccPatch_ProcessPartChanges:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessPartChanges.bin"
AccPatch_PartChanges_NoNew:
	jr AccPatch_PartChanges_CheckFlag

AccPatch_PartChanges_MapLookup:
	.incbin "includes/generated/v7_transplant_AccPatch_PartChanges_MapLookup.bin"
AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	.incbin "includes/generated/v7_transplant_AccPatch_PartChanges_CheckFlag.bin"
AccPatch_PartChanges_Done:
	ret

AccPatch_ReadRepeatBit:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadRepeatBit.bin"
AccPatch_SetRepeatBitOn:
	.incbin "includes/generated/v7_transplant_AccPatch_SetRepeatBitOn.bin"
AccPatch_SetRepeatBit_Done:
	ret

AccPatch_PartNumberTable:
	.byte 0x00, 0x10, 0x11, 0x00, 0x12, 0x00, 0x00, 0x00
	.byte 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8

AccPatch_UpdateAllChains:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_UpdateChain_Rhythm
	calr AccPatch_UpdateChain_Bass
	calr AccPatch_UpdateChain_Acc1
	calr AccPatch_UpdateChain_Acc2
	calr AccPatch_UpdateChain_Acc3
	ret

; Curious thing I've just observed:
; The routines below are almost identical to each other...

AccPatch_UpdateChain_Rhythm:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateChain_Rhythm.bin"
AccPatch_UpdateChain_Bass:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateChain_Bass.bin"
AccPatch_UpdateChain_Acc1:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateChain_Acc1.bin"
AccPatch_UpdateChain_Acc2:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateChain_Acc2.bin"
AccPatch_UpdateChain_Acc3:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateChain_Acc3.bin"
AccPatch_SyncAllVoiceParams:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_SyncVoice_Rhythm
	calr AccPatch_SyncVoice_Acc1
	calr AccPatch_SyncVoice_Acc2
	calr AccPatch_SyncVoice_Acc3
	calr AccPatch_SyncVoice_Bass
	ret

AccPatch_SyncVoice_Rhythm:
	push xiy
	add xiy, 0x20
	ld xix, 0xfba4
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncRhythm_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncRhythm_HasBank:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncRhythm_HasBank.bin"
AccPatch_SyncRhythm_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Bass:
	push xiy
	add xiy, 0x18
	ld xix, 0xfbbe
	ld w, (xix + 256)
	and w, 0xff
	and w, 0xf
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncBass_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncBass_HasBank:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncBass_HasBank.bin"
AccPatch_SyncBass_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc1:
	push xiy
	add xiy, 0x28
	ld xix, 0xfb56
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc1_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc1_HasBank:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncAcc1_HasBank.bin"
AccPatch_SyncAcc1_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc2:
	push xiy
	add xiy, 0x30
	ld xix, 0xfb70
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc2_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc2_HasBank:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncAcc2_HasBank.bin"
AccPatch_SyncAcc2_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc3:
	push xiy
	add xiy, 0x38
	ld xix, 0xfb8a
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc3_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc3_HasBank:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncAcc3_HasBank.bin"
AccPatch_SyncAcc3_Done:
	pop xiy
	ret

AccPatch_LoadVoiceParams:
	.incbin "includes/generated/v7_transplant_AccPatch_LoadVoiceParams.bin"
AccPatch_CallParamLookup:
	.incbin "includes/generated/v7_transplant_AccPatch_CallParamLookup.bin"
AccPatch_StoreVoiceParams:
	.incbin "includes/generated/v7_transplant_AccPatch_StoreVoiceParams.bin"
AccPatch_ComplexDataBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_ComplexDataBlock.bin"
AccPatch_FreeAllChains_Alt:
	ld hl, (xiy + 256)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 4)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 6)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 8)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 10)
	calr AccPatch_ClearLinkedListEntries
	ret

AccPatch_ClearLinkedListEntries:
	push xiy
	calr AccPatch_ResolveSlotAddr
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Alt_Done

AccPatch_FreeChainLoop_Alt:
	.incbin "includes/generated/v7_transplant_AccPatch_FreeChainLoop_Alt.bin"
AccPatch_FreeChain_Alt_Done:
	pop xiy
	ret

AccPatch_ResolveSlotAddr:
	.incbin "includes/generated/v7_transplant_AccPatch_ResolveSlotAddr.bin"
AccPatch_ResolveSlotAddr_Ret:
	ret

AccPatch_FillAllSlots_Alt:
	ld hl, (xiy + 256)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 4)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 6)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 8)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 10)
	calr AccPatch_FillSlotWithVoiceData
	ret

AccPatch_FillSlotWithVoiceData:
	push xiy
	pushw hl
	ld l, (xiy + 12)
	xor h, h
	lds32 xwa, 0
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xe4, 0xec
	lds32 xbc, 0
	ld b, (xiy + 13)
	inc 1, b
	mul8rr a, b
	popw hl
	calr AccPatch_ResolveSlotAddr
	add xix, 0x6
	ldb l, 0x81

AccPatch_FillSlot_Alt_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cps wa, 0
	jr nz, AccPatch_FillSlot_Alt_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_ScanSequenceToEnd:
	calr AccPatch_InitSlotPointer_Alt

AccPatch_ScanSeq_Loop:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanSeq_Loop.bin"
AccPatch_ScanSeq_StorePosAndRet:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanSeq_StorePosAndRet.bin"
AccPatch_SeqReadByte_Alt:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqReadByte_Alt.bin"
AccPatch_SeqAdvance_Alt:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvance_Alt.bin"
AccPatch_SeqAdvance_CheckLimit:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvance_CheckLimit.bin"
AccPatch_SeqAdvance_ResetBase:
	lds wa, 6
	jr AccPatch_SeqAdvance_Store

AccPatch_SeqAdvance_Inc:
	inc 1, wa

AccPatch_SeqAdvance_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvance_Store.bin"
AccPatch_InitSlotPointer_Alt:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlotPointer_Alt.bin"
AccPatch_InitSlotAlt_Valid:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlotAlt_Valid.bin"
AccPatch_SeqDispatch_Entry:
	jr AccPatch_SeqDispatch_Main
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	jrl AccPatch_SeqAdvanceStep

AccPatch_SeqReadByte:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqReadByte.bin"
AccPatch_SeqDispatch_Padding:
	nop
	nop

AccPatch_AdvanceSeqIndex:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvanceSeqIndex.bin"
AccPatch_AdvSeq_CheckLimit:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvSeq_CheckLimit.bin"
AccPatch_AdvSeq_ResetBase:
	lds wa, 6
	jr AccPatch_AdvSeq_Store

AccPatch_AdvSeq_Inc:
	inc 1, wa

AccPatch_AdvSeq_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvSeq_Store.bin"
AccPatch_AdvSeq_Padding:
	nop
	nop

AccPatch_SeqDispatch_Main:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_Main.bin"
AccPatch_SeqDispatch_CheckEmpty:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_CheckEmpty.bin"
AccPatch_SeqDispatch_CheckPlaying:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_CheckPlaying.bin"
AccPatch_SeqDispatch_CheckStarted:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_CheckStarted.bin"
AccPatch_SeqDispatch_ProcessFlags:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_ProcessFlags.bin"
AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_RunNotes:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_RunNotes.bin"
AccPatch_SeqDispatch_CheckQueued:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_CheckQueued.bin"
AccPatch_SyncStateAndReturn:
	.incbin "includes/generated/v7_transplant_AccPatch_SyncStateAndReturn.bin"
AccPatch_SeqDispatch_MiscData:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqDispatch_MiscData.bin"
AccPatch_ReadModeFlags:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadModeFlags.bin"
AccPatch_ReadModeFlags_Active:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadModeFlags_Active.bin"
AccPatch_ReadModeFlags_Check400:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadModeFlags_Check400.bin"
AccPatch_SetFlagExit:
	ret

AccPatch_ScanSeq_PaddingByte:
	ret

AccPatch_ScanToSequenceStart:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ScanSeq_ReadLoop:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanSeq_ReadLoop.bin"
AccPatch_ScanSeq_StorePosition:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanSeq_StorePosition.bin"
AccPatch_ScanSeq_PaddingWord:
	nop
	nop

AccPatch_InitAndLoadSequence:
	.incbin "includes/generated/v7_transplant_AccPatch_InitAndLoadSequence.bin"
AccPatch_InitSeq_ClearLoop:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSeq_ClearLoop.bin"
AccPatch_InitSeq_LoadTempo:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSeq_LoadTempo.bin"
AccPatch_InitSeq_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_InitSeq_AdvLoop

AccPatch_InitSeq_AdvDone:
	ret

AccPatch_InitSeq_Padding:
	nop
	nop

AccPatch_ResetSeqCounters:
	.incbin "includes/generated/v7_transplant_AccPatch_ResetSeqCounters.bin"
AccPatch_ResetSeqCounters_Loop:
	.incbin "includes/generated/v7_transplant_AccPatch_ResetSeqCounters_Loop.bin"
AccPatch_ResetSeqCounters_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_ResetSeqCounters_AdvLoop

AccPatch_ResetSeqCounters_Done:
	ret

__pad_F60077:
	nop
	nop

AccPatch_ScanToSequenceEnd:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanToSequenceEnd.bin"
AccPatch_ScanSeqEnd_HandleMarker:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanSeqEnd_HandleMarker.bin"
AccPatch_ScanDone:
	ret

__pad_F600A1:
	nop
	nop

AccPatch_MarkAllSlotsActive:
	.incbin "includes/generated/v7_transplant_AccPatch_MarkAllSlotsActive.bin"
AccPatch_MarkSlots_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_MarkSlots_Next
	ormi8 (xhl + 1), 0x80

AccPatch_MarkSlots_Next:
	.incbin "includes/generated/v7_transplant_AccPatch_MarkSlots_Next.bin"
AccPatch_UpdateSequenceState:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSequenceState.bin"
AccPatch_UpdateSeqState_CheckXor:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_CheckXor.bin"
AccPatch_UpdateSeqState_AndCheck:
	and w, c
	cps w, 0
	jr z, AccPatch_UpdateSeqState_ResumeSeq
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_ResumeSeq:
	calr AccPatch_ResumeSequencePlayback
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_CheckBit4:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_CheckBit4.bin"
AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_ClearBit7.bin"
AccPatch_UpdateSeqState_CompareBits:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_CompareBits.bin"
AccPatch_UpdateSeqState_CheckC7:
	bit 7, c
	jr z, AccPatch_LoadNextSequencePointers
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_BothSet:
	calr AccPatch_PrepareAndProcessEvents

AccPatch_LoadNextSequencePointers:
	.incbin "includes/generated/v7_transplant_AccPatch_LoadNextSequencePointers.bin"
AccPatch_UpdateSeqState_CheckBit3:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_CheckBit3.bin"
AccPatch_UpdateSeqState_StoreFlags:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSeqState_StoreFlags.bin"
AccPatch_UpdateSeqState_Return:
	ret

__pad_F601A3:
	nop
	nop

AccPatch_ClearAndScanForNote:
	.incbin "includes/generated/v7_transplant_AccPatch_ClearAndScanForNote.bin"
AccPatch_ScanForActiveNote:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanForActiveNote.bin"
AccPatch_ScanNote_Continue:
	jr AccPatch_ScanForActiveNote

AccPatch_ScanNote_Done:
	ret

TempoRingBuf_SkipBytes:
	cps bc, 0
	jr z, TempoRingBuf_SkipBytes_Done
	pushw bc
	call TempoRingBuf_ReadByteToA
	popw bc
	dec 1, bc
	jr TempoRingBuf_SkipBytes

TempoRingBuf_SkipBytes_Done:
	ret

AccPatch_ScanForNoteOff:
	.incbin "includes/generated/v7_transplant_AccPatch_ScanForNoteOff.bin"
AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	.incbin "includes/generated/v7_transplant_AccPatch_SeekToPosition.bin"
AccPatch_SeekForwardSteps:
	.incbin "includes/generated/v7_transplant_AccPatch_SeekForwardSteps.bin"
AccPatch_SeekFwd_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_SeekFwd_AdvLoop

AccPatch_SeekFwd_Done:
	ret

__pad_F60273:
	nop
	nop

AccPatch_ParseSequenceHeader:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseSequenceHeader.bin"
AccPatch_ParseHdr_AdvanceAndCompare:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseHdr_AdvanceAndCompare.bin"
AccPatch_ParseHdr_AdvanceAndRead:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseHdr_AdvanceAndRead.bin"
AccPatch_ParseHdr_CheckBit7:
	bit 7, a
	jr z, AccPatch_ParseHdr_AdvanceAndRead
	jr AccPatch_ParseSequenceHeader

AccPatch_ParseHdr_RestorePos:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseHdr_RestorePos.bin"
AccPatch_ParseHdr_Return:
	ret

__pad_F602CB:
	nop
	nop

AccPatch_ResumeSequencePlayback:
	.incbin "includes/generated/v7_transplant_AccPatch_ResumeSequencePlayback.bin"
AccPatch_ResumeSeq_ComparePos:
	.incbin "includes/generated/v7_transplant_AccPatch_ResumeSeq_ComparePos.bin"
AccPatch_ResumeSeq_ReadByte:
	calr AccPatch_SeqReadByte
	cp a, 0x90
	jr z, AccPatch_ResumeSeq_Skip6
	cp a, 0x91
	jr z, AccPatch_ResumeSeq_Skip8
	cp a, 0x92
	jr z, AccPatch_ResumeSeq_Skip6
	cp a, 0x81
	jr z, AccPatch_ResumeSeq_HandleMarker
	and a, 0xf0
	cp a, 0xd0
	jr z, AccPatch_ResumeSeq_Skip3
	calr AccPatch_ProcessSeqEvt_RetNop
	jr AccPatch_ResumeSeq_Return

AccPatch_ResumeSeq_Skip6:
	lds bc, 6
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip8:
	ldw bc, 0x8
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip3:
	lds bc, 3

AccPatch_ResumeSeq_AddAndAdvance:
	.incbin "includes/generated/v7_transplant_AccPatch_ResumeSeq_AddAndAdvance.bin"
AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	.incbin "includes/generated/v7_transplant_AccPatch_ResumeSeq_HandleMarker.bin"
AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	.incbin "includes/generated/v7_transplant_AccPatch_ResumeSeq_InitSlot.bin"
AccPatch_ResumeSeq_Return:
	ret

__pad_F60386:
	nop
	nop

AccPatch_PrepareSequencePlayback:
	.incbin "includes/generated/v7_transplant_AccPatch_PrepareSequencePlayback.bin"
AccPatch_CheckSequenceChanged:
	.incbin "includes/generated/v7_transplant_AccPatch_CheckSequenceChanged.bin"
AccPatch_CheckChanged_DoCopy:
	.incbin "includes/generated/v7_transplant_AccPatch_CheckChanged_DoCopy.bin"
AccPatch_CheckChanged_Return:
	ret

__pad_F603FC:
	nop
	nop

AccPatch_CopySequenceEntry:
	.incbin "includes/generated/v7_transplant_AccPatch_CopySequenceEntry.bin"
AccPatch_CopyEntry_Store:
	.incbin "includes/generated/v7_transplant_AccPatch_CopyEntry_Store.bin"
__pad_F60464:
	nop
	nop

AccPatch_UpdateEntryFromTable:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateEntryFromTable.bin"
AccPatch_UpdateEntry_CheckDE:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateEntry_CheckDE.bin"
AccPatch_UpdateEntry_AdjustOffset:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateEntry_AdjustOffset.bin"
AccPatch_UpdateEntry_StoreDirect:
	pushw de
	calr AccPatch_LoadTablePointers
	popw de
	ld (xix), de

AccPatch_NullRet:
	ret

__pad_F604BB:
	nop
	nop

AccPatch_LoadTablePointers:
	.incbin "includes/generated/v7_transplant_AccPatch_LoadTablePointers.bin"
AccPatch_AdjustTableEntryPos:
	.incbin "includes/generated/v7_transplant_AccPatch_AdjustTableEntryPos.bin"
AccPatch_AdjustEntry_Overflow:
	.incbin "includes/generated/v7_transplant_AccPatch_AdjustEntry_Overflow.bin"
AccPatch_AdjustEntry_Return:
	ret

AccPatch_PrepareAndProcessEvents:
	.incbin "includes/generated/v7_transplant_AccPatch_PrepareAndProcessEvents.bin"
AccPatch_ProcessSequenceEvents:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSequenceEvents.bin"
AccPatch_ProcessSeqEvt_SavePos:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSeqEvt_SavePos.bin"
AccPatch_SkipNoteOff:
	.incbin "includes/generated/v7_transplant_AccPatch_SkipNoteOff.bin"
AccPatch_ProcessSeqEvt_AdvLoop:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSeqEvt_AdvLoop.bin"
AccPatch_ProcessSeqEvt_LoopBack:
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_HandleEnd:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ProcessSeqEvt_InitSlot
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_SkipD:
	lds bc, 3

AccPatch_ProcessSeqEvt_SkipDLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ProcessSeqEvt_SkipDLoop
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_SetSize:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSeqEvt_SetSize.bin"
AccPatch_ProcessSeqEvt_StoreAndPrep:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSeqEvt_StoreAndPrep.bin"
AccPatch_ProcessSeqEvt_InitSlot:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ProcessSeqEvt_StorePos:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessSeqEvt_StorePos.bin"
AccPatch_ProcessSeqEvt_RetNop:
	ret

AccPatch_EventDispatch_Nop:
	nop

AccPatch_EventDispatchLoop:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr nz, AccPatch_EventDispatch_ReadCmd
	jrl AccPatch_EventDispatch_Done

AccPatch_EventDispatch_ReadCmd:
	call TempoRingBuf_PeekByte
	cp a, 0x81
	jr z, AccPatch_EventDispatch_EndMarker
	ldb w, 0xf0
	and w, a
	cp w, 0x90
	jr z, AccPatch_EventDispatch_NoteOn
	cp a, 0xd1
	jr nz, AccPatch_EventDispatch_CheckD2
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD2:
	cp a, 0xd2
	jr nz, AccPatch_EventDispatch_CheckD4
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD4:
	cp a, 0xd4
	jr nz, AccPatch_EventDispatch_CheckD3
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD3:
	cp a, 0xd3
	jr nz, AccPatch_EventDispatch_CheckD5
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD5:
	cp a, 0xd5
	jr z, AccPatch_ProcessMarkerCommand
	calr AccPatch_SkipToMarker
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_NoteOn:
	.incbin "includes/generated/v7_transplant_AccPatch_EventDispatch_NoteOn.bin"
AccPatch_EventDispatch_NoteResolve:
	calr AccPatch_ParseAndResolve
	calr AccPatch_CopyNoteStepsToSlots
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_EndMarker:
	.incbin "includes/generated/v7_transplant_AccPatch_EventDispatch_EndMarker.bin"
AccPatch_EventDispatch_AdvSlots:
	.incbin "includes/generated/v7_transplant_AccPatch_EventDispatch_AdvSlots.bin"
AccPatch_ProcessMarkerCommand:
	lds bc, 3
	calr AccPatch_ReadRingBufBytes
	calr AccPatch_ParseAndResolve
	calr AccPatch_ProcessMarkerEvent
	jr AccPatch_ContinueProcessing

AccPatch_ContinueProcessing:
	jrl AccPatch_EventDispatchLoop

AccPatch_EventDispatch_Done:
	ret

__pad_F60699:
	nop
	nop

AccPatch_UpdatePlayback:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdatePlayback.bin"
AccPatch_UpdatePlayback_CheckQueue:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdatePlayback_CheckQueue.bin"
AccPatch_UpdatePlayback_ClearStep:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdatePlayback_ClearStep.bin"
__pad_F606D3:
	nop
	nop

AccPatch_AdvanceSlotCounters:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvanceSlotCounters.bin"
AccPatch_AdvSlotCtr_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_AdvSlotCtr_Next
	ld a, (xhl + 1)
	cp a, 0xff
	jr z, AccPatch_AdvSlotCtr_Store
	inc 1, a

AccPatch_AdvSlotCtr_Store:
	ld (xhl + 1), a

AccPatch_AdvSlotCtr_Next:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvSlotCtr_Next.bin"
__pad_F606FA:
	nop
	nop

AccPatch_ReadRingBufBytes:
	lds32 xhl, 0

AccPatch_ReadBuf_Loop:
	cp hl, bc
	jr z, AccPatch_ReadBuf_Done
	pushw bc
	pushw hl
	call TempoRingBuf_ReadByteToA
	cp a, 0xff
	jr nz, AccPatch_ReadBuf_StoreAndNext
	nop

AccPatch_ReadBuf_StoreAndNext:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadBuf_StoreAndNext.bin"
AccPatch_ReadBuf_Done:
	ret

__pad_F6071F:
	nop
	nop

AccPatch_ParseAndResolve:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseAndResolve.bin"
AccPatch_ParseResolve_ParseHdr:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseResolve_ParseHdr.bin"
AccPatch_ParseResolve_IncStep:
	.incbin "includes/generated/v7_transplant_AccPatch_ParseResolve_IncStep.bin"
__pad_F60764:
	nop
	nop

AccPatch_LookupStepByDrumParam:
	.incbin "includes/generated/v7_transplant_AccPatch_LookupStepByDrumParam.bin"
AccPatch_LookupStep_StoreResult:
	.incbin "includes/generated/v7_transplant_AccPatch_LookupStep_StoreResult.bin"
AccPatch_SetStepDone:
	ret

__pad_F607AA:
	nop
	nop

AccPatch_CopyNoteStepsToSlots:
	.incbin "includes/generated/v7_transplant_AccPatch_CopyNoteStepsToSlots.bin"
AccPatch_CopySteps_FindFreeSlot:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	.incbin "includes/generated/v7_transplant_AccPatch_CopySteps_ProcessEntry.bin"
AccPatch_CopySteps_StartFetch:
	.incbin "includes/generated/v7_transplant_AccPatch_CopySteps_StartFetch.bin"
AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	.incbin "includes/generated/v7_transplant_AccPatch_CopySteps_Overflow.bin"
AccPatch_TransposeNote:
	.incbin "includes/generated/v7_transplant_AccPatch_TransposeNote.bin"
AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	.incbin "includes/generated/v7_transplant_AccPatch_Transpose_AddBack.bin"
AccPatch_Transpose_LookupTable:
	.incbin "includes/generated/v7_transplant_AccPatch_Transpose_LookupTable.bin"
AccPatch_Transpose_CheckBit6:
	.incbin "includes/generated/v7_transplant_AccPatch_Transpose_CheckBit6.bin"
AccPatch_Transpose_CheckBit5:
	.incbin "includes/generated/v7_transplant_AccPatch_Transpose_CheckBit5.bin"
AccPatch_Transpose_SetDrumSplit:
	.incbin "includes/generated/v7_transplant_AccPatch_Transpose_SetDrumSplit.bin"
AccPatch_StoreDrumParams:
	.incbin "includes/generated/v7_transplant_AccPatch_StoreDrumParams.bin"
AccPatch_StoreDrumParams_CheckSplit:
	.incbin "includes/generated/v7_transplant_AccPatch_StoreDrumParams_CheckSplit.bin"
AccPatch_StoreDrumParams_Return:
	ret

AccPatch_TransposeNoteTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x11, 0x01, 0x00, 0x11, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x11, 0x11

AccPatch_ReadTransposeAmount:
	.incbin "includes/generated/v7_transplant_AccPatch_ReadTransposeAmount.bin"
AccPatch_SelectTranspose:
	.incbin "includes/generated/v7_transplant_AccPatch_SelectTranspose.bin"
AccPatch_FetchStepEntry:
	.incbin "includes/generated/v7_transplant_AccPatch_FetchStepEntry.bin"
AccPatch_FetchStepData:
	.incbin "includes/generated/v7_transplant_AccPatch_FetchStepData.bin"
AccPatch_SeqAdvanceStep:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvanceStep.bin"
AccPatch_SeqAdvStep_Increment:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvStep_Increment.bin"
AccPatch_SeqAdvStep_Return:
	ret

AccPatch_SeqAdvStep_WrapToNext:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvStep_WrapToNext.bin"
AccPatch_SeqAdvStep_ScanFromStart:
	ldw hl, 0x95

AccPatch_SeqAdvStep_ScanLoop:
	inc 1, hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_SeqAdvStep_StorePos
	jr AccPatch_SeqAdvStep_ScanLoop

AccPatch_SeqAdvStep_StorePos:
	.incbin "includes/generated/v7_transplant_AccPatch_SeqAdvStep_StorePos.bin"
__pad_F609EE:
	nop
	nop

AccPatch_UpdateSlotVoiceData:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateSlotVoiceData.bin"
AccPatch_TransposeAndCopyNote:
	.incbin "includes/generated/v7_transplant_AccPatch_TransposeAndCopyNote.bin"
AccPatch_TransposeCopy_DoCopy:
	.incbin "includes/generated/v7_transplant_AccPatch_TransposeCopy_DoCopy.bin"
__pad_F60A51:
	nop
	nop

AccPatch_ProcessMarkerEvent:
	.incbin "includes/generated/v7_transplant_AccPatch_ProcessMarkerEvent.bin"
AccPatch_ProcessMarker_CheckD3:
	cp a, 0xd3
	jr nz, AccPatch_ProcessMarker_CheckD5
	ldb a, 0xd5
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD5:
	cp a, 0xd5
	jr nz, AccPatch_FetchSequence
	ldb a, 0xd4
	jr AccPatch_FetchSequence

AccPatch_FetchSequence:
	.incbin "includes/generated/v7_transplant_AccPatch_FetchSequence.bin"
AccPatch_ProcessMarker_Return:
	ret

__pad_F60A95:
	nop
	nop

AccPatch_SkipToMarker:
	call TempoRingBuf_ReadByteToA
	bit 7, a
	jr z, AccPatch_SkipToMarker
	ret

AccPatch_SlotCopyDataBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_SlotCopyDataBlock.bin"
AccPatch_InitSlotAndCopyData:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlotAndCopyData.bin"
AccPatch_InitSlot_SameBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlot_SameBlock.bin"
AccPatch_InitSlot_CrossBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlot_CrossBlock.bin"
AccPatch_InitSlot_StoreAddrs:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlot_StoreAddrs.bin"
AccPatch_InitSlot_SplitCopy:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlot_SplitCopy.bin"
AccPatch_InitSlot_Finalize:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlot_Finalize.bin"
__pad_F60BD0:
	nop
	nop

AccPatch_FindFreeEntrySlot:
	ldw hl, 0x95

AccPatch_FindFreeSlot_Loop:
	inc 1, hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_FindFreeSlot_Found
	jr AccPatch_FindFreeSlot_Loop

AccPatch_FindFreeSlot_Found:
	.incbin "includes/generated/v7_transplant_AccPatch_FindFreeSlot_Found.bin"
__pad_F60C04:
	nop
	nop

AccPatch_AdvancePlayPos:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvancePlayPos.bin"
AccPatch_AdvPlayPos_CheckDE:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvPlayPos_CheckDE.bin"
AccPatch_AdvPlayPos_AddAndCheck:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvPlayPos_AddAndCheck.bin"
AccPatch_AdvPlayPos_StoreDirect:
	pushw de
	calr AccPatch_LoadTablePointers
	popw de
	ld (xix), de

AccPatch_StoreEntryPtr:
	ret

AccPatch_AdvPlayPos_DataBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvPlayPos_DataBlock.bin"
AccPatch_AdvanceAllSteps:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvanceAllSteps.bin"
AccPatch_AdvAllSteps_Loop:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvAllSteps_Loop.bin"
AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz xbc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvAllSteps_Next.bin"
__pad_F60D0C:
	nop
	nop

AccPatch_AdvanceSingleStep:
	xor w, w
	ld a, (xix + 5)
	cp wa, 0xfe
	jr nz, AccPatch_AdvSingleStep_Inc
	ld hl, (xix + 3)
	push xix
	calr AccPatch_GetEntryAddr
	ld xiy, xix
	pop xix
	ld wa, (xiy + 3)
	ld (xix + 3), wa
	lds wa, 6
	jr AccPatch_AdvSingleStep_Store

AccPatch_AdvSingleStep_Inc:
	inc 1, wa

AccPatch_AdvSingleStep_Store:
	ld (xix + 5), a
	ret

__pad_F60D33:
	nop
	nop

AccPatch_DispatchQueuedNotes:
	.incbin "includes/generated/v7_transplant_AccPatch_DispatchQueuedNotes.bin"
AccPatch_DispatchQueued_Loop:
	.incbin "includes/generated/v7_transplant_AccPatch_DispatchQueued_Loop.bin"
__pad_F60D58:
	nop
	nop

AccPatch_DispatchNoteToVoice:
	.incbin "includes/generated/v7_transplant_AccPatch_DispatchNoteToVoice.bin"
AccPatch_DispatchNote_Loop:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, AccPatch_DispatchNote_NextSlot
	ldb_sri A, 0x07, 0xec, 0xf4
	and a, 0x7f
	cp a, (xix + 2)
	jr nz, AccPatch_DispatchNote_NextSlot
	and_srib_im 0x07, 0xec, 0xf4, 0x7f
	inc 1, iy
	and_srib_im 0x07, 0xec, 0xf4, 0x7f
	ldb_sri D, 0x07, 0xec, 0xf4
	inc 1, iy
	ldb_sri A, 0x07, 0xec, 0xf4
	ld c, (xix + 1)
	cp c, a
	jr nc, AccPatch_DispatchNote_CalcVelocity
	add c, 0x60
	cps d, 0
	jr z, AccPatch_DispatchNote_CalcVelocity
	dec 1, d

AccPatch_DispatchNote_CalcVelocity:
	sub c, a
	ld a, c
	calr AccPatch_WriteVelocityToSeq
	jr AccPatch_DispatchNote_Return

AccPatch_DispatchNote_NextSlot:
	sub iy, 0x6
	cps iy, 0
	jr lt, AccPatch_DispatchNote_Return
	jr AccPatch_DispatchNote_Loop

AccPatch_DispatchNote_Return:
	ret

__pad_F60DB4:
	nop
	nop

AccPatch_WriteVelocityToSeq:
	.incbin "includes/generated/v7_transplant_AccPatch_WriteVelocityToSeq.bin"
AccPatch_WriteVel_MatchFound:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_AdvanceSeqIndex
	popw wa
	calr AccPatch_WriteSeqByte
	calr AccPatch_AdvanceSeqIndex
	popw de
	ld a, d
	calr AccPatch_WriteSeqByte

AccPatch_WriteVel_RestorePos:
	.incbin "includes/generated/v7_transplant_AccPatch_WriteVel_RestorePos.bin"
__pad_F60E12:
	nop
	nop

AccPatch_WriteSeqByte:
	.incbin "includes/generated/v7_transplant_AccPatch_WriteSeqByte.bin"
__pad_F60E2A:
	nop
	nop

AccPatch_CalcBlockCopySetup:
	.incbin "includes/generated/v7_transplant_AccPatch_CalcBlockCopySetup.bin"
AccPatch_CalcBlockCopy_DiffEntry:
	.incbin "includes/generated/v7_transplant_AccPatch_CalcBlockCopy_DiffEntry.bin"
AccPatch_CalcBlockCopy_Clamp:
	calr __pad_F60E86
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_StoreIY:
	calr BlockCopy_SameEntry_Reverse
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_CheckIX:
	calr BlockCopy_IXFirst_Reverse

AccPatch_CalcBlockCopy_StoreIX:
	.incbin "includes/generated/v7_transplant_AccPatch_CalcBlockCopy_StoreIX.bin"
AccPatch_CalcBlockCopy_Done:
	ret

__pad_F60E86:
	.incbin "includes/generated/v7_transplant___pad_F60E86.bin"
BlockCopy_Rev_CheckSameEntry:
	.incbin "includes/generated/v7_transplant_BlockCopy_Rev_CheckSameEntry.bin"
BlockCopy_Rev_CopyDiffEntry:
	.incbin "includes/generated/v7_transplant_BlockCopy_Rev_CopyDiffEntry.bin"
BlockCopy_Rev_CopyRemainder:
	.incbin "includes/generated/v7_transplant_BlockCopy_Rev_CopyRemainder.bin"
BlockCopy_Rev_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_Rev_StoreBounds.bin"
DSP_SetupDone:
	ret

DSP_BlockCopyReverse:
	.incbin "includes/generated/v7_transplant_DSP_BlockCopyReverse.bin"
DSP_BlockCopyForward:
	.incbin "includes/generated/v7_transplant_DSP_BlockCopyForward.bin"
BlockCopy_SameEntry_Reverse:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_Reverse.bin"
BlockCopy_SameEntry_AdvIY:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_AdvIY.bin"
BlockCopy_SameEntry_CheckDE:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_CheckDE.bin"
BlockCopy_SameEntry_FullCopy:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_FullCopy.bin"
BlockCopy_SameEntry_AdvIYLoop:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_AdvIYLoop.bin"
BlockCopy_SameEntry_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_SameEntry_StoreBounds.bin"
DSP_NullRet:
	ret

BlockCopy_IXFirst_Reverse:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_Reverse.bin"
BlockCopy_IXFirst_CopyOffset:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_CopyOffset.bin"
BlockCopy_IXFirst_CheckDE:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_CheckDE.bin"
BlockCopy_IXFirst_CopyRemainder:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_CopyRemainder.bin"
BlockCopy_IXFirst_CopyOffset2:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_CopyOffset2.bin"
BlockCopy_IXFirst_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_IXFirst_StoreBounds.bin"
DSP_NullRet2:
	ret

AccPatch_CalcBlockCopyBounds:
	.incbin "includes/generated/v7_transplant_AccPatch_CalcBlockCopyBounds.bin"
BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	.incbin "includes/generated/v7_transplant_BlockCopyBounds_UseSmaller.bin"
BlockCopyBounds_CopyRemainder:
	.incbin "includes/generated/v7_transplant_BlockCopyBounds_CopyRemainder.bin"
BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvanceNextEntry_IY.bin"
AdvNextEntry_IY_StoreAndReset:
	.incbin "includes/generated/v7_transplant_AdvNextEntry_IY_StoreAndReset.bin"
AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvanceNextEntry_IX.bin"
AdvNextEntry_IX_StoreAndReset:
	.incbin "includes/generated/v7_transplant_AdvNextEntry_IX_StoreAndReset.bin"
AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	.incbin "includes/generated/v7_transplant_AccPatch_SetupBlockCopyDispatch.bin"
BlockCopyDisp_CompareOffsets:
	.incbin "includes/generated/v7_transplant_BlockCopyDisp_CompareOffsets.bin"
BlockCopyDisp_IXSmaller:
	calr BlockCopy_FwdIYSmaller
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_Equal:
	calr BlockCopy_FwdEqual
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_IXLarger:
	calr BlockCopy_FwdIXSmaller
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_CheckAndForward:
	.incbin "includes/generated/v7_transplant_BlockCopyDisp_CheckAndForward.bin"
BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIYSmaller.bin"
BlockCopy_FwdIYSmall_CheckDE:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIYSmall_CheckDE.bin"
BlockCopy_FwdIYSmall_CopyOffset:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIYSmall_CopyOffset.bin"
BlockCopy_FwdIYSmall_CopyRem:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIYSmall_CopyRem.bin"
BlockCopy_FwdIYSmall_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIYSmall_StoreBounds.bin"
DSP_CopyDone:
	ret

BlockCopy_FwdEqual:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual.bin"
BlockCopy_FwdEqual_AdvIX:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual_AdvIX.bin"
BlockCopy_FwdEqual_CheckDE:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual_CheckDE.bin"
BlockCopy_FwdEqual_FullCopy:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual_FullCopy.bin"
BlockCopy_FwdEqual_AdvIXLoop:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual_AdvIXLoop.bin"
BlockCopy_FwdEqual_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdEqual_StoreBounds.bin"
AccPatch_NullRet2:
	ret

BlockCopy_FwdIXSmaller:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmaller.bin"
BlockCopy_FwdIXSmall_CopyOff:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmall_CopyOff.bin"
BlockCopy_FwdIXSmall_CheckDE:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmall_CheckDE.bin"
BlockCopy_FwdIXSmall_CopyRem:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmall_CopyRem.bin"
BlockCopy_FwdIXSmall_CopyOff2:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmall_CopyOff2.bin"
BlockCopy_FwdIXSmall_StoreBounds:
	.incbin "includes/generated/v7_transplant_BlockCopy_FwdIXSmall_StoreBounds.bin"
AccPatch_NullRet3:
	ret

AccPatch_ForwardBlockCopy:
	.incbin "includes/generated/v7_transplant_AccPatch_ForwardBlockCopy.bin"
FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	.incbin "includes/generated/v7_transplant_FwdBlockCopy_UseSmaller.bin"
FwdBlockCopy_CopyRemainder:
	.incbin "includes/generated/v7_transplant_FwdBlockCopy_CopyRemainder.bin"
AccPatch_DoneBlockCopy:
	ret

AccPatch_AdvancePrevEntry_IX:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvancePrevEntry_IX.bin"
AdvPrevEntry_IX_StoreAndReset:
	.incbin "includes/generated/v7_transplant_AdvPrevEntry_IX_StoreAndReset.bin"
AdvPrevEntry_IX_Return:
	ret

AccPatch_AdvancePrevEntry_IY:
	.incbin "includes/generated/v7_transplant_AccPatch_AdvancePrevEntry_IY.bin"
AdvPrevEntry_IY_StoreAndReset:
	.incbin "includes/generated/v7_transplant_AdvPrevEntry_IY_StoreAndReset.bin"
AdvPrevEntry_IY_Return:
	pop xix
	ret

AccPatch_CheckEmpty:
	call TempoRingBuf_CheckEmpty
	ld wa, hl
	ret

TempoRingBuf_ReadByteToA:
	call TempoRingBuf_ReadByte
	ld a, l
	ret

TempoRingBuf_ReInitAndRet:
	call TempoRingBuf_Init
	ret

TempoRingBuf_PeekByte:
	call TempoRingBuf_SaveReadPos
	call TempoRingBuf_ReadAlternate
	ld a, l
	ret

AccPlayback_InitOrUpdate:
	.incbin "includes/generated/v7_transplant_AccPlayback_InitOrUpdate.bin"
AccPlayback_CheckStyleMatch:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckStyleMatch.bin"
AccPlayback_CheckActiveStyle:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckActiveStyle.bin"
AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride

AccPlayback_CheckBit4:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckBit4.bin"
AccPlayback_InitTimingVars:
	.incbin "includes/generated/v7_transplant_AccPlayback_InitTimingVars.bin"
AccPlayback_CheckStateFlags:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckStateFlags.bin"
AccPlayback_CheckSkipInit:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckSkipInit.bin"
AccPlayback_ApplyChanges:
	.incbin "includes/generated/v7_transplant_AccPlayback_ApplyChanges.bin"
AccPlayback_CheckBit0_3:
	.incbin "includes/generated/v7_transplant_AccPlayback_CheckBit0_3.bin"
AccPlayback_ProcessMiscFlags:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessMiscFlags.bin"
AccPlayback_RunPeriodicTasks:
	calr AccPlayback_ReadEventLoop
	calr AccPlayback_ProcessBit5Change
	calr AccPlayback_ProcessTempoAdvance

AccPlayback_Finalize:
	calr AccPlayback_UpdateRhythmSustain
	ret

__pad_F614A3:
	nop
	nop
	pushw	hl
	and	hl, 4095
	sla	hl, 4
	popw	hl
	ret
	nop
	nop

; ============================================================================
; ToneGen_CalcBufferAddr - Compute tone generator buffer address
; ============================================================================
; Input:  HL = buffer index
; Output: XHL = 0x95c00 + (HL & 0xffff) * 256
; Calculates address into tone generator hardware buffer memory.
; Called from MIDI voice processing code (handles status bytes 0x81-0x91).
; ============================================================================
ToneGen_CalcBufferAddr:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x95c00
	ret

__pad_F614C1:
	nop
	nop

AccPlayback_CalcTimingPosition:
	.incbin "includes/generated/v7_transplant_AccPlayback_CalcTimingPosition.bin"
AccTiming_StorePartA:
	.incbin "includes/generated/v7_transplant_AccTiming_StorePartA.bin"
AccTiming_ComputeOffset:
	.incbin "includes/generated/v7_transplant_AccTiming_ComputeOffset.bin"
AccTiming_UseFullBar:
	.incbin "includes/generated/v7_transplant_AccTiming_UseFullBar.bin"
AccTiming_StoreResult:
	.incbin "includes/generated/v7_transplant_AccTiming_StoreResult.bin"
AccTiming_CompareStyles:
	.incbin "includes/generated/v7_transplant_AccTiming_CompareStyles.bin"
AccTiming_Return:
	ret

__pad_F6152D:
	nop
	nop

AccPlayback_AdjustBeatPosition:
	.incbin "includes/generated/v7_transplant_AccPlayback_AdjustBeatPosition.bin"
AccBeatAdj_CheckBit6:
	.incbin "includes/generated/v7_transplant_AccBeatAdj_CheckBit6.bin"
AccBeatAdj_StoreAndClear:
	.incbin "includes/generated/v7_transplant_AccBeatAdj_StoreAndClear.bin"
__pad_F61565:
	nop
	nop

AccVoice_InitPatternBuffer:
	.incbin "includes/generated/v7_transplant_AccVoice_InitPatternBuffer.bin"
ToneGen_SkipToNoteEntry:
	pushw bc
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	lds32 xix, 6
	add xix, xhl
	popw bc

ToneGen_SkipLoop:
	cps c, 0
	jr z, ToneGen_ParseAllEvents
	ld a, (xix)
	cp a, 0x81
	jr nz, ToneGen_SkipLoop_ReadNext
	dec 1, c

ToneGen_SkipLoop_ReadNext:
	calr ToneGen_ReadBufferWithIndirection
	jr ToneGen_SkipLoop

ToneGen_ParseAllEvents:
	.incbin "includes/generated/v7_transplant_ToneGen_ParseAllEvents.bin"
ToneGen_SaveRegsAndCall:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccAudio_LockRelease
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

__pad_F61634:
	nop
	nop

ToneGen_ParseEventBuffer:
	.incbin "includes/generated/v7_transplant_ToneGen_ParseEventBuffer.bin"
EventBuffer_ParseLoop:
	cps c, 0
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	.incbin "includes/generated/v7_transplant_EventBuffer_ReadByte.bin"
EventBuffer_CheckNoteType:
	cp a, 0x90
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0x91
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd1
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd2
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd3
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd4
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd5
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd6
	jr z, ToneGen_MapNoteToOctaveBitmask
	calr ToneGen_ReadBufferWithIndirection
	jr EventBuffer_ParseLoop

ToneGen_MapNoteToOctaveBitmask:
	calr ToneGen_ReadBufferWithIndirection
	ld a, (xix)
	xor w, w
	ldb l, 0xc
	div8rr a, l
	pushw bc
	push xix
	and a, 0x7
	ld c, a
	xor b, b
	ld xix, ToneGen_MapNoteToOctaveBitmask_0x20
	ldb_sri C, 0x07, 0xf0, 0xe4
	jr ToneGen_MapNote_OrMask
	; Bit mask lookup table (powers of 2):
	normal
	push	sr
	max
	ldio	16, 32
	.byte 0x40, 0x80

ToneGen_MapNote_OrMask:
	.incbin "includes/generated/v7_transplant_ToneGen_MapNote_OrMask.bin"
ToneGen_ParseEvent_Done:
	ret

__pad_F616D5:
	nop
	nop

AccPlayback_ProcessStyleChanges:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessStyleChanges.bin"
AccStyleChange_CheckPartCount:
	nop
	nop

AccPlayback_ProcessPartChanges:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessPartChanges.bin"
AccPartChange_Bit1:
	.incbin "includes/generated/v7_transplant_AccPartChange_Bit1.bin"
AccPartChange_CheckBit2:
	.incbin "includes/generated/v7_transplant_AccPartChange_CheckBit2.bin"
AccPartChange_Done:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots

AccPartChange_ProcessBit2:
	calr ToneGen_CalcNoteWithWrap
	cp bc, wa
	jr ugt, AccPartChange_StoreResult
	jr __pad_F61760

AccPartChange_StoreResult:
	.incbin "includes/generated/v7_transplant_AccPartChange_StoreResult.bin"
ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

__pad_F61760:
	.incbin "includes/generated/v7_transplant___pad_F61760.bin"
ToneGen_ProcessVoiceEvent:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessVoiceEvent.bin"
ToneGen_PushAndReadType:
	.incbin "includes/generated/v7_transplant_ToneGen_PushAndReadType.bin"
ToneGen_UpdateAndInitPattern:
	.incbin "includes/generated/v7_transplant_ToneGen_UpdateAndInitPattern.bin"
ToneGen_VoiceSlotLookupTable:
	.byte 0x00, 0x00, 0x00, 0x94, 0x95, 0x00, 0x96, 0x00
	.byte 0x00, 0x00, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x98

ToneGen_ProcessWithRestore:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessWithRestore.bin"
ToneGen_ProcessRestore_Direct:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_Direct.bin"
ToneGen_ProcessRestore_CalcPos:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_CalcPos.bin"
ToneGen_ProcessRestore_CheckDelta:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_CheckDelta.bin"
ToneGen_ProcessRestore_ClearBit5:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_ClearBit5.bin"
ToneGen_ProcessRestore_CalcNote:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_CalcNote.bin"
ToneGen_ProcessRestore_AdjNote:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_AdjNote.bin"
ToneGen_ProcessRestore_UseSaved:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_UseSaved.bin"
ToneGen_ProcessRestore_UseActive:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_UseActive.bin"
ToneGen_ProcessRestore_SetBit5:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_SetBit5.bin"
ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_ReadType.bin"
ToneGen_ProcessRestore_WrapOctave:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessRestore_WrapOctave.bin"
ToneGen_ProcessRestore_Return:
	ret

__pad_F618FF:
	nop
	nop

ToneGen_RestoreFromSavedPos:
	.incbin "includes/generated/v7_transplant_ToneGen_RestoreFromSavedPos.bin"
ToneGen_EventDispatchLoop:
	.incbin "includes/generated/v7_transplant_ToneGen_EventDispatchLoop.bin"
ToneGen_EventDisp_EndOfBlock:
	.incbin "includes/generated/v7_transplant_ToneGen_EventDisp_EndOfBlock.bin"
ToneGen_CalcEventVelocity_WithFlags:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcEventVelocity_WithFlags.bin"
ToneGen_Velocity_Multiply:
	muls8rr a, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	.incbin "includes/generated/v7_transplant_ToneGen_Velocity_HandleEnd.bin"
ToneGen_Velocity_DefaultCalc:
	.incbin "includes/generated/v7_transplant_ToneGen_Velocity_DefaultCalc.bin"
VoiceVelocity_CalcDone:
	.incbin "includes/generated/v7_transplant_VoiceVelocity_CalcDone.bin"
ToneGen_Velocity_Store:
	.incbin "includes/generated/v7_transplant_ToneGen_Velocity_Store.bin"
__pad_F61A1C:
	nop
	nop

ToneGen_CalcNotePosition:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcNotePosition.bin"
ToneGen_CalcPos_SubOctave:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcPos_SubOctave.bin"
ToneGen_CalcPos_Return:
	ld w, d
	ret

__pad_F61A62:
	nop
	nop

ToneGen_AdjustNoteWrap:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjustNoteWrap.bin"
ToneGen_AdjWrap_AddOctave:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjWrap_AddOctave.bin"
ToneGen_AdjWrap_WrapBar:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjWrap_WrapBar.bin"
ToneGen_AdjWrap_WrapMeasure:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjWrap_WrapMeasure.bin"
SustainLevel_SetExit:
	ret

__pad_F61AAF:
	nop
	nop

ToneGen_ScanRestoredVoiceEvents:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanRestoredVoiceEvents.bin"
ToneGen_ScanRestored_Loop:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanRestored_Loop.bin"
ToneGen_ScanRestored_EndBlock:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanRestored_EndBlock.bin"
ToneGen_CalcEventVelocity_Restored:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcEventVelocity_Restored.bin"
ToneGen_ScanRestored_EndMarker:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanRestored_EndMarker.bin"
ToneGen_ScanRestored_Return:
	ret

__pad_F61B56:
	nop
	nop

ToneGen_GetSlotIndex:
	.incbin "includes/generated/v7_transplant_ToneGen_GetSlotIndex.bin"
ToneGen_GetSlot_Lookup:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ldw_sri HL, 0x07, 0xf4, 0xec
	ret

__pad_F61B78:
	nop
	nop

ToneGen_CalcNoteWithWrap:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcNoteWithWrap.bin"
ToneGen_CalcWrap_Store:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcWrap_Store.bin"
__pad_F61BAB:
	nop
	nop

ToneGen_RecalcAndRestart:
	.incbin "includes/generated/v7_transplant_ToneGen_RecalcAndRestart.bin"
__pad_F61BCE:
	nop
	nop

ToneGen_StoreNoteOrWrap:
	.incbin "includes/generated/v7_transplant_ToneGen_StoreNoteOrWrap.bin"
ToneGen_AdvancePeriodWrap:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvancePeriodWrap.bin"
ToneGen_PeriodWrap_NextBar:
	.incbin "includes/generated/v7_transplant_ToneGen_PeriodWrap_NextBar.bin"
ToneGen_PeriodWrap_ResetBar:
	.incbin "includes/generated/v7_transplant_ToneGen_PeriodWrap_ResetBar.bin"
PitchValidate_Exit:
	ret

__pad_F61C16:
	nop
	nop

ToneGen_ClassifyAndDispatch:
	cp a, 0xd1
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd2
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd3
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd4
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd5
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd6
	jr z, ToneGen_ClassifyStereoType
	calr ToneGen_ClassifyMonoEvent
	jr ToneGen_Classify_Return

ToneGen_ClassifyStereoType:
	calr ToneGen_ClassifyStereoEvent

ToneGen_Classify_Return:
	ret

__pad_F61C3F:
	nop
	nop

ToneGen_ClassifyStereoEvent:
	.incbin "includes/generated/v7_transplant_ToneGen_ClassifyStereoEvent.bin"
ToneGen_ClassifyStereoSlot_Common:
	.incbin "includes/generated/v7_transplant_ToneGen_ClassifyStereoSlot_Common.bin"
__pad_F61C98:
	nop
	nop

ToneGen_ClassifyMonoEvent:
	.incbin "includes/generated/v7_transplant_ToneGen_ClassifyMonoEvent.bin"
ToneGen_ClassifyMono_MapChannel:
	.incbin "includes/generated/v7_transplant_ToneGen_ClassifyMono_MapChannel.bin"
ToneGen_ClassifyMono_WriteNew:
	.incbin "includes/generated/v7_transplant_ToneGen_ClassifyMono_WriteNew.bin"
ToneGen_ClassifyMono_Return:
	ret

__pad_F61D76:
	nop
	nop

AccPlayback_ReadEventLoop:
	.incbin "includes/generated/v7_transplant_AccPlayback_ReadEventLoop.bin"
AccPlayback_ReadEvt_CheckEmpty:
	.incbin "includes/generated/v7_transplant_AccPlayback_ReadEvt_CheckEmpty.bin"
AccPlayback_ReadEvt_Continue:
	jr AccPlayback_ReadEvt_CheckEmpty

AccPlayback_ReadEvt_CheckBit7:
	.incbin "includes/generated/v7_transplant_AccPlayback_ReadEvt_CheckBit7.bin"
AccPlayback_ReadEvt_HasEntries:
	.incbin "includes/generated/v7_transplant_AccPlayback_ReadEvt_HasEntries.bin"
AccPlayback_ReadEvt_Overflow:
	calr AccPlayback_AdvPattern_Loop

AccPlayback_ReadEvt_OverflowOK:
	.incbin "includes/generated/v7_transplant_AccPlayback_ReadEvt_OverflowOK.bin"
ToneGenSetup_Done:
	ret

AccPlayback_ReadEvt_Return:
	nop
	nop

AccPlayback_ProcessNoteOnEvent:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessNoteOnEvent.bin"
AccPlayback_NoteOn_ReadParams:
	.incbin "includes/generated/v7_transplant_AccPlayback_NoteOn_ReadParams.bin"
AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	.incbin "includes/generated/v7_transplant_AccPlayback_NoteOn_WriteVoice.bin"
TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	nop
	nop

AccPlayback_NoteOn_Check91:
	.incbin "includes/generated/v7_transplant_AccPlayback_NoteOn_Check91.bin"
AccPlayback_NoteOn_WritePan:
	.incbin "includes/generated/v7_transplant_AccPlayback_NoteOn_WritePan.bin"
AccPlayback_NoteOn_Return:
	ret

__pad_F61EAF:
	nop
	nop

ToneGen_WriteVoiceEventEntry:
	.incbin "includes/generated/v7_transplant_ToneGen_WriteVoiceEventEntry.bin"
AccPlayback_AdvancePattern:
	nop
	nop

AccPlayback_AdvPattern_Loop:
	.incbin "includes/generated/v7_transplant_AccPlayback_AdvPattern_Loop.bin"
AccPlayback_AdvPattern_Check81:
	.incbin "includes/generated/v7_transplant_AccPlayback_AdvPattern_Check81.bin"
AccPlayback_AdvPattern_Check90:
	.incbin "includes/generated/v7_transplant_AccPlayback_AdvPattern_Check90.bin"
AccPlayback_AdvPattern_Done:
	dec 1, e
	jr AccPlayback_AdvPattern_Check81

AccPlayback_AdvPattern_Nop:
	ret

__pad_F61F3E:
	nop
	nop

AccPlayback_AdvanceRingBuffer:
	.incbin "includes/generated/v7_transplant_AccPlayback_AdvanceRingBuffer.bin"
AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

__pad_F61F65:
	ldb w, 0xc
	sub w, a
	add_srib_mr W, 0x07, 0xf0, 0xec

AccPlayback_TrackPosition:
	.incbin "includes/generated/v7_transplant_AccPlayback_TrackPosition.bin"
AccPlayback_TrackPos_Return:
	ld a, c

__pad_F61FAC:
	.incbin "includes/generated/v7_transplant___pad_F61FAC.bin"
AccPlayback_TrackPos_WrapCheck:
	.incbin "includes/generated/v7_transplant_AccPlayback_TrackPos_WrapCheck.bin"
AccPlayback_TrackPos_WrapDone:
	.incbin "includes/generated/v7_transplant_AccPlayback_TrackPos_WrapDone.bin"
ToneGen_LoadRhythmPatternParams:
	.incbin "includes/generated/v7_transplant_ToneGen_LoadRhythmPatternParams.bin"
AccPlayback_StyleRecalc_Return:
	ret

__pad_F62002:
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	scf
	.byte 0x01
	nop
	scf
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	scf
	scf

AccPlayback_ProcessOngoingEvents:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessOngoingEvents.bin"
ToneGen_NullRet:
	ret

AccPlayback_Ongoing_HandleType:
	nop
	nop

ToneGen_ProcessVoiceSlots:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessVoiceSlots.bin"
AccPlayback_Ongoing_NoteOff:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_NoteOff.bin"
AccPlayback_Ongoing_NoteOffDone:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_NoteOffDone.bin"
AccPlayback_Ongoing_D1Type:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_D1Type.bin"
AccPlayback_Ongoing_D1_Return:
	jr AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_D2Type:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_D2Type.bin"
AccPlayback_Ongoing_D2_Return:
	cp a, 0x91
	jr nz, AccPlayback_Ongoing_WriteChan
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_WriteChan:
	cp a, 0xd1
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd2
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd3
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd4
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd5
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd6
	jr z, ToneGen_StepToNextStereoVoicePair
	jr AccPlayback_Ongoing_StorePan

ToneGen_StepToNextStereoVoicePair:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_StorePan:
	calr ToneGen_StepToNextVoiceSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_StoreDone:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_StoreDone.bin"
ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

__pad_F62169:
	nop
	nop

AccPlayback_Ongoing_AdvSlot:
	.incbin "includes/generated/v7_transplant_AccPlayback_Ongoing_AdvSlot.bin"
AccPlayback_Ongoing_AdvDone:
	nop
	nop

__pad_F621A7:
	.incbin "includes/generated/v7_transplant___pad_F621A7.bin"
AccPlayback_UpdateVoiceState:
	nop
	nop

ToneGen_AdvanceSeqList:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvanceSeqList.bin"
AccPlayback_VoiceState_NoChange:
	.incbin "includes/generated/v7_transplant_AccPlayback_VoiceState_NoChange.bin"
AccPlayback_VoiceState_Changed:
	.incbin "includes/generated/v7_transplant_AccPlayback_VoiceState_Changed.bin"
AccPlayback_VoiceState_CalcOff:
	.incbin "includes/generated/v7_transplant_AccPlayback_VoiceState_CalcOff.bin"
AccPlayback_VoiceState_Return:
	ret

__pad_F62230:
	.incbin "includes/generated/v7_transplant___pad_F62230.bin"
ToneGen_SearchVoiceBuffer:
	.incbin "includes/generated/v7_transplant_ToneGen_SearchVoiceBuffer.bin"
ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ldw_sri WA, 0x07, 0xf4, 0xec

ToneGen_SearchBuf_CompareLoop:
	.incbin "includes/generated/v7_transplant_ToneGen_SearchBuf_CompareLoop.bin"
ToneGen_SearchBuf_CheckEnd:
	.incbin "includes/generated/v7_transplant_ToneGen_SearchBuf_CheckEnd.bin"
ToneGen_SearchBuf_FollowChain:
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 3)
	jr ToneGen_SearchBuf_CompareLoop

ToneGen_SearchBuf_Return:
	ret

__pad_F622FD:
	nop
	nop

AccPlayback_ProcessBit5Change:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessBit5Change.bin"
AccBit5_CheckBit5Active:
	.incbin "includes/generated/v7_transplant_AccBit5_CheckBit5Active.bin"
AccBit5_InitAndScan:
	.incbin "includes/generated/v7_transplant_AccBit5_InitAndScan.bin"
AccBit5_StepOnce:
	calr ToneGen_StepToNextStereoSlot

AccBit5_StepTwice:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot

AccVoice_InitPlaybackState:
	.incbin "includes/generated/v7_transplant_AccVoice_InitPlaybackState.bin"
FlagClear_Exit:
	.incbin "includes/generated/v7_transplant_FlagClear_Exit.bin"
AccBit5_Return:
	ret

__pad_F623D8:
	nop
	nop

ToneGen_ScanVoicePosition:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanVoicePosition.bin"
ToneGen_ScanPos_CompareLoop:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanPos_CompareLoop.bin"
ToneGen_ScanPos_CheckEnd:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanPos_CheckEnd.bin"
VoiceState_CheckExit:
	.incbin "includes/generated/v7_transplant_VoiceState_CheckExit.bin"
ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanPos_ProcessFlags.bin"
ToneGen_ScanPos_AdjustBit1:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanPos_AdjustBit1.bin"
ToneGen_ScanPos_WrapBlock:
	.incbin "includes/generated/v7_transplant_ToneGen_ScanPos_WrapBlock.bin"
PlaybackState_InitDone:
	ret

__pad_F62498:
	nop
	nop

ToneGen_InitPlaybackState:
	.incbin "includes/generated/v7_transplant_ToneGen_InitPlaybackState.bin"
ToneGen_InitPlay_SetupTables:
	.incbin "includes/generated/v7_transplant_ToneGen_InitPlay_SetupTables.bin"
__pad_F624E5:
	nop
	nop

ToneGen_AdvanceVoiceStep:
	inc 1, iy
	inc 1, c
	cp c, 0xff
	jr nz, ToneGen_AdvVoiceStep_Return
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ld de, hl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	ldb c, 0x6

ToneGen_AdvVoiceStep_Return:
	ret

__pad_F62502:
	nop
	nop

AccPlayback_ProcessTempoAdvance:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessTempoAdvance.bin"
AccPlayback_TempoAdv_Return:
	ret

__pad_F62534:
	nop
	nop

ToneGen_CalcTempo:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcTempo.bin"
ToneGen_CalcTempo_Lookup:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcTempo_Lookup.bin"
ToneGen_CalcTempo_Mode0:
	cps a, 0
	jr nz, ToneGen_CalcTempo_Mode2
	ld wa, de
	sla wa, 4
	add wa, de
	add wa, de
	add wa, de
	xor de, de
	ldw hl, 0x14
	ldw_erp DE, 0xe2
	div xwa, xhl
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode2:
	cps a, 2
	jr nz, ToneGen_CalcTempo_Mode3
	srl de, 1
	ld wa, de
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode3:
	srl de, 2
	ld wa, de

ToneGen_CalcTempoBeatsAndTicks:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcTempoBeatsAndTicks.bin"
ToneGen_CalcTempo_DataTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x0c, 0x00
	.byte 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00
	.byte 0x40, 0x00, 0x60, 0x00, 0xc0, 0x00, 0x80, 0x01
	.byte 0x00, 0x03, 0x80, 0x04, 0x00, 0x06

ToneGen_AdvanceByTempo:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvanceByTempo.bin"
ToneGen_AdvTempo_StoreNote:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvTempo_StoreNote.bin"
ToneGen_AdvTempo_WrapLoop:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvTempo_WrapLoop.bin"
ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	.incbin "includes/generated/v7_transplant_ToneGen_AdvTempo_StoreBeat.bin"
__pad_F62627:
	nop
	nop

AccPlayback_UpdateRhythmSustain:
	.incbin "includes/generated/v7_transplant_AccPlayback_UpdateRhythmSustain.bin"
AccPlayback_RhythmSust_Return:
	ret

__pad_F6265F:
	nop
	nop

AccPlayback_ProcessVoiceType5:
	.incbin "includes/generated/v7_transplant_AccPlayback_ProcessVoiceType5.bin"
AccVoiceType5_CheckBit01:
	.incbin "includes/generated/v7_transplant_AccVoiceType5_CheckBit01.bin"
AccVoice_DispatchType5Handler:
	.incbin "includes/generated/v7_transplant_AccVoice_DispatchType5Handler.bin"
TempoCheck_Exit:
	ret

__pad_F626A6:
	nop
	nop

ToneGen_AdjustVoiceVelocity:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjustVoiceVelocity.bin"
ToneGen_AdjVel_CheckBit2:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjVel_CheckBit2.bin"
ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_AdjVel_StoreAndParam
	ldb a, 0x0

ToneGen_AdjVel_StoreAndParam:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjVel_StoreAndParam.bin"
ToneGen_AdjVel_WriteToBuffer:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjVel_WriteToBuffer.bin"
ToneGen_AdjVel_Return:
	ret

__pad_F62776:
	nop
	nop

ToneGen_AdjustVolumePan:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjustVolumePan.bin"
ToneGen_AdjVol_ClampHigh:
	jr ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_Decrement:
	dec 1, a
	cps a, 0
	jr z, ToneGen_AdjVol_ClampLow
	cp a, 0xff
	jr nz, ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_ClampLow:
	ldb a, 0x1

ToneGen_AdjVol_WriteToBuffer:
	.incbin "includes/generated/v7_transplant_ToneGen_AdjVol_WriteToBuffer.bin"
ToneGen_AdjVol_Return:
	ret

__pad_F627F4:
	nop
	nop

ToneGen_ProcessStereoType:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessStereoType.bin"
ToneGen_Stereo_CheckInc:
	jr ToneGen_Stereo_Decrement

ToneGen_Stereo_Increment:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_Stereo_Decrement
	ldb a, 0x0

ToneGen_Stereo_Decrement:
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_ClampLow:
	.incbin "includes/generated/v7_transplant_ToneGen_Stereo_ClampLow.bin"
ToneGen_Stereo_Store:
	ldb a, 0x0

ToneGen_Stereo_WriteParam:
	.incbin "includes/generated/v7_transplant_ToneGen_Stereo_WriteParam.bin"
ToneGen_Stereo_Return:
	ret

__pad_F6288E:
	nop
	nop
	ret
	nop
	nop
	push	sr
	.byte 0x53, 0x54
	.ascii "UVWX_`aR"
	pop	sr
	.ascii "bcdefghPiQj'(*,.$%& "
	.byte 0x1f
	pushw	bc
	.byte 0x21
	.ascii "+\"-#/0123456789:=>"
	jp	0x1e1d1c
	.byte 0x41, 0x42
	.ascii "CDEkl"
	pop_f
	.byte 0x1a
	ld	xiz, 0x114b4c18
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	ldf	77
	popw	iz
	popw	sp
	incf
	decf
	ret
	retd	2576
	pushw	0x4709
	reti
	ldio	59, 60
	ld	xwa, 0x4906053f
	.byte 0x04
	.ascii "JHmnopqrstuvwxyz{|}~"
	jrl	nc, 14
	nop
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	jp	0x09121d
	ldwio	11, 3340
	ret
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	halt
	reti
	retd	4368
	push_a
	pop_a
	ex_ff
	ldf	24
	pop_f
	.byte 0x1a, 0x1c, 0x1e
	.ascii "FGmnopqrstuvwxyz{|}~"
	.byte 0x7f

ToneGen_WriteMultiChanParam:
	.incbin "includes/generated/v7_transplant_ToneGen_WriteMultiChanParam.bin"
ToneGen_MultiChan_Compare:
	.incbin "includes/generated/v7_transplant_ToneGen_MultiChan_Compare.bin"
ToneGen_MultiChan_AdjustVel:
	cps a, 7
	jr nz, AccVoice_ResolveNoteOnOffType
	ldb e, 0x91
	jr ToneGen_MultiChan_CheckBit4

AccVoice_ResolveNoteOnOffType:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, __pad_F62002_0xE
	add xix, xhl
	ld a, (xix)
	pop xix
	cps a, 0
	jr z, ToneGen_MultiChan_CheckBit4
	ldb e, 0x91

ToneGen_MultiChan_CheckBit4:
	cp d, 0x90
	jr nz, ToneGen_MultiChan_WriteNoteOff
	cp e, 0x90
	jr z, VoiceCompare_Done
	calr ToneGen_CompareVoiceBlocks
	jr VoiceCompare_Done

ToneGen_MultiChan_WriteNoteOff:
	cp e, 0x90
	jr nz, VoiceCompare_Done
	calr ToneGen_CompareVoiceBlocks

VoiceCompare_Done:
	ret

ToneGen_MultiChan_WriteFinalNote:
	nop
	nop

ToneGen_CompareVoiceBlocks:
	calr __pad_F62A0D
	calr __pad_F62AAC
	calr __pad_F62B29
	calr ToneGen_StepWithBoundsCheck
	ret

ToneGen_MultiChan_Return:
	nop
	nop

__pad_F62A0D:
	.incbin "includes/generated/v7_transplant___pad_F62A0D.bin"
ToneGen_VoiceParamDisp_Return:
	nop
	nop

__pad_F62AAC:
	.incbin "includes/generated/v7_transplant___pad_F62AAC.bin"
ToneGen_CalcBeatSubdivision:
	.incbin "includes/generated/v7_transplant_ToneGen_CalcBeatSubdivision.bin"
ToneGen_CalcBeat_Return:
	nop
	nop

__pad_F62B29:
	.incbin "includes/generated/v7_transplant___pad_F62B29.bin"
ToneGen_ReadBufferUtility:
	.incbin "includes/generated/v7_transplant_ToneGen_ReadBufferUtility.bin"
ToneGen_ReadBufUtil_Loop:
	cps a, 7
	jr nz, AccVoice_WriteNoteEventToBuffer
	ld (xiy), 0x91
	ld (xiy + 6), 0x3
	ld (xiy + 7), 0x0
	jr __pad_F62BC0

AccVoice_WriteNoteEventToBuffer:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, __pad_F62002_0xE
	add xix, xhl
	ld a, (xix)
	ld (xiy), 0x90
	cps a, 0
	jr z, ToneGen_ReadBufUtil_Return
	ld (xiy), 0x91
	ld a, (xix + 1)
	ld (xiy + 6), a
	ld a, (xix + 2)
	ld (xiy + 7), a

ToneGen_ReadBufUtil_Return:
	pop xix

__pad_F62BC0:
	ret

__pad_F62BC1_2:
	nop
	nop

ToneGen_StepWithBoundsCheck:
	.incbin "includes/generated/v7_transplant_ToneGen_StepWithBoundsCheck.bin"
ToneGen_StepBounds_Return:
	.incbin "includes/generated/v7_transplant_ToneGen_StepBounds_Return.bin"
ToneGen_SeqAdvanceMain:
	.incbin "includes/generated/v7_transplant_ToneGen_SeqAdvanceMain.bin"
ToneGen_SeqAdv_Return:
	ret

__pad_F62C3E:
	nop
	nop

AccVoice_ReadCurrentToneType:
	.incbin "includes/generated/v7_transplant_AccVoice_ReadCurrentToneType.bin"
ToneGen_InterpolateParam:
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Loop:
	nop
	nop

ToneGen_StepToNextVoiceSlot:
	.incbin "includes/generated/v7_transplant_ToneGen_StepToNextVoiceSlot.bin"
ToneGen_Interp_StoreResult:
	.incbin "includes/generated/v7_transplant_ToneGen_Interp_StoreResult.bin"
ToneGen_Interp_CheckExit:
	.incbin "includes/generated/v7_transplant_ToneGen_Interp_CheckExit.bin"
ToneGen_Interp_WrapPoint:
	.incbin "includes/generated/v7_transplant_ToneGen_Interp_WrapPoint.bin"
ToneGen_Interp_Done:
	nop
	nop

ToneGen_StepToNextStereoSlot:
	.incbin "includes/generated/v7_transplant_ToneGen_StepToNextStereoSlot.bin"
ToneGen_Interp_Return:
	.incbin "includes/generated/v7_transplant_ToneGen_Interp_Return.bin"
ToneGen_Interp_OverflowCheck:
	.incbin "includes/generated/v7_transplant_ToneGen_Interp_OverflowCheck.bin"
ToneGen_Interp_OverflowDone:
	nop
	nop

ToneGen_StepToNextBuffer:
	.incbin "includes/generated/v7_transplant_ToneGen_StepToNextBuffer.bin"
ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	.byte 0x9b
	nop
	ldb	e, 14
	nop
	nop

ToneGen_ReadBufferWithIndirection:
	push xhl
	inc 1, xix
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld a, (xix)
	cp a, 0x87
	jr nz, ToneGen_AdvBeat_Return
	ld hl, (xhl + 3)
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ld xix, xhl
	add xix, 0x6

ToneGen_AdvBeat_Return:
	pop xhl
	ret

__pad_F62D57:
	nop
	nop

ToneGen_StepVoiceForward:
	.incbin "includes/generated/v7_transplant_ToneGen_StepVoiceForward.bin"
ToneGen_StepFwd_CheckWrap:
	.incbin "includes/generated/v7_transplant_ToneGen_StepFwd_CheckWrap.bin"
ToneGen_StepFwd_WrapDone:
	.incbin "includes/generated/v7_transplant_ToneGen_StepFwd_WrapDone.bin"
ToneGen_StepFwd_Exit:
	nop
	nop

ToneGen_StepFwd_Alternate:
	.incbin "includes/generated/v7_transplant_ToneGen_StepFwd_Alternate.bin"
ToneGen_StepAlt_CheckBeat:
	calr __pad_F62E01
	calr ChordDetect_CheckDescending
	calr ChordDetect_CheckRoot1
	calr ChordDetect_CheckInversion1

ToneGen_StepAlt_Return:
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_Overflow:
	cps b, 1
	jr ugt, ToneGen_StepAlt_OverflowDone
	ldb c, 0x0
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_OverflowDone:
	calr ChordDetect_CheckAscending
	calr ChordDetect_CheckMirror
	calr ChordDetect_CheckRoot2
	calr ChordDetect_CheckInversion2

ToneGen_StepAlt_StoreResult:
	.incbin "includes/generated/v7_transplant_ToneGen_StepAlt_StoreResult.bin"
ToneGen_StepAlt_Done:
	nop
	nop

__pad_F62E01:
	ld a, c
	add a, 0x3
	cp b, a
	jr ule, RhythmParam_CheckExit6
	inc 1, a
	cp a, d
	jr nz, RhythmParam_CheckExit6
	ld a, d
	inc 1, a
	cp a, e
	jr nz, RhythmParam_CheckExit6
	inc 1, c

RhythmParam_CheckExit6:
	ret

__pad_F62E1B:
	nop
	nop

ChordDetect_CheckDescending:
	cps c, 0
	jr z, ToneGen_NullRet2
	ld a, c
	add a, 0x2
	cp b, a
	jr ule, ToneGen_NullRet2
	ld a, c
	inc 1, a
	cp a, d
	jr nz, ToneGen_NullRet2
	ld a, d
	dec 1, a
	cp a, e
	jr nz, ToneGen_NullRet2
	dec 1, c

ToneGen_NullRet2:
	ret

__pad_F62E3D:
	nop
	nop

ChordDetect_CheckRoot1:
	cps c, 0
	jr nz, RhythmParam_CheckExit5
	cps d, 1
	jr nz, RhythmParam_CheckExit5
	ld a, b
	inc 1, a
	cp e, a
	jr nz, RhythmParam_CheckExit5
	ld a, b
	sub a, 0x3
	ld c, a

RhythmParam_CheckExit5:
	ret

__pad_F62E57:
	nop
	nop

ChordDetect_CheckInversion1:
	ld a, b
	sub a, 0x3
	cp c, a
	jr nz, RhythmParam_CheckExit4
	ld a, b
	inc 1, a
	cp d, a
	jr nz, RhythmParam_CheckExit4
	cps e, 1
	jr nz, RhythmParam_CheckExit4
	ldb c, 0x0

RhythmParam_CheckExit4:
	ret

__pad_F62E71:
	nop
	nop

ChordDetect_CheckAscending:
	ld a, c
	add a, 0x1
	cp b, a
	jr ule, RhythmParam_CheckExit3
	inc 1, a
	cp a, d
	jr nz, RhythmParam_CheckExit3
	ld a, d
	inc 1, a
	cp a, e
	jr nz, RhythmParam_CheckExit3
	inc 1, c

RhythmParam_CheckExit3:
	ret

__pad_F62E8D:
	nop
	nop

ChordDetect_CheckMirror:
	cps c, 0
	jr z, Rhythm_NullRet
	ld a, c
	cp b, a
	jr ule, Rhythm_NullRet
	ld a, c
	inc 1, a
	cp a, d
	jr nz, Rhythm_NullRet
	ld a, d
	dec 1, a
	cp a, e
	jr nz, Rhythm_NullRet
	dec 1, c

Rhythm_NullRet:
	ret

__pad_F62EAC:
	nop
	nop

ChordDetect_CheckRoot2:
	cps c, 0
	jr nz, RhythmParam_CheckExit2
	cps d, 1
	jr nz, RhythmParam_CheckExit2
	ld a, b
	inc 1, a
	cp e, a
	jr nz, RhythmParam_CheckExit2
	ld a, b
	dec 1, a
	ld c, a

RhythmParam_CheckExit2:
	ret

__pad_F62EC5:
	nop
	nop

ChordDetect_CheckInversion2:
	ld a, b
	dec 1, a
	cp c, a
	jr nz, RhythmParam_ValidExit
	ld a, b
	inc 1, a
	cp d, a
	jr nz, RhythmParam_ValidExit
	cps e, 1
	jr nz, RhythmParam_ValidExit
	ldb c, 0x0

RhythmParam_ValidExit:
	ret

__pad_F62EDE:
	nop
	nop

AccPlayback_DetectMeasurePos:
	.incbin "includes/generated/v7_transplant_AccPlayback_DetectMeasurePos.bin"
AccPlayback_MeasPos_SetLower:
	.incbin "includes/generated/v7_transplant_AccPlayback_MeasPos_SetLower.bin"
AccPlayback_MeasPos_SetUpper:
	.incbin "includes/generated/v7_transplant_AccPlayback_MeasPos_SetUpper.bin"
AccPlayback_MeasPos_SmallBeat:
	cp e, a
	jr c, AccPlayback_MeasPos_SmallLower
	add a, 0x1
	cp e, a
	jr ugt, AccPlayback_MeasPos_SmallUpper
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallLower:
	.incbin "includes/generated/v7_transplant_AccPlayback_MeasPos_SmallLower.bin"
AccPlayback_MeasPos_SmallUpper:
	.incbin "includes/generated/v7_transplant_AccPlayback_MeasPos_SmallUpper.bin"
RhythmChannel_NullRet:
	ret

__pad_F62F32:
	nop
	nop

AccPlayback_InitPartAssignment:
	.incbin "includes/generated/v7_transplant_AccPlayback_InitPartAssignment.bin"
AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_Store.bin"
AccPlayback_PartAssign_Check4:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_Check4.bin"
AccPlayback_PartAssign_SmallPart:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_SmallPart.bin"
AccPlayback_PartAssign_Check2:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_Check2.bin"
AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_LargeMeasure.bin"
AccPlayback_PartAssign_FullSetup:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_FullSetup.bin"
AccPlayback_PartAssign_LargeBeat:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_LargeBeat.bin"
AccPlayback_PartAssign_LargeBeat2:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_LargeBeat2.bin"
RhythmFunc_NullRet:
	ret

AccPlayback_PartAssign_DataBlock:
	.incbin "includes/generated/v7_transplant_AccPlayback_PartAssign_DataBlock.bin"
AccPat_ShiftAndMask:
	pushw hl
	and hl, 0xfff
	sla hl, 4
	popw hl
	ret

__pad_F630DE:
	nop
	nop

AccPat_IndexToAddress:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x95c00
	ret

AccPat_InlineFunctions_DataBlock:
	nop
	nop
	and	xhl, 0xffff
	sla	xhl, 8
	add	xhl, 0x095c00
	ret
	push	xwa
	push	xix
	ld	wa, hl
	and	xhl, 4095
	sla	xhl, 8
	and	wa, 0xf000
	srl	wa, 10
	ld	xix, AccPat_InlineFunctions_DataBlock_0x35
	.byte 0xe3
	reti
	.byte 0xf0, 0xe0
	ldb	d, 236
	.byte 0x83
	pop	xix
	pop	xwa
	ret
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_DispatchNoteChange:
	.incbin "includes/generated/v7_transplant_AccPat_DispatchNoteChange.bin"
AccPat_Dispatch_AllocAndProcess:
	.incbin "includes/generated/v7_transplant_AccPat_Dispatch_AllocAndProcess.bin"
AccPat_Dispatch_CalcAccent:
	.incbin "includes/generated/v7_transplant_AccPat_Dispatch_CalcAccent.bin"
AccPat_Dispatch_LowRange:
	.incbin "includes/generated/v7_transplant_AccPat_Dispatch_LowRange.bin"
AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	.incbin "includes/generated/v7_transplant_AccPat_Dispatch_CheckBit0.bin"
AccPat_Dispatch_InitSlot:
	.incbin "includes/generated/v7_transplant_AccPat_Dispatch_InitSlot.bin"
AccPat_CleanupAndFree:
	.incbin "includes/generated/v7_transplant_AccPat_CleanupAndFree.bin"
AccPat_Dispatch_Return:
	ret

__pad_F6323D:
	nop
	nop

DualVoice_ParamLoadDone:
	push xiz
	calr AccPatch_LoadDualVoiceParams
	pop xiz
	ret

AccPatch_LoadDualVoiceParams:
	.incbin "includes/generated/v7_transplant_AccPatch_LoadDualVoiceParams.bin"
AccPat_DualVoice_ClampIndex:
	.incbin "includes/generated/v7_transplant_AccPat_DualVoice_ClampIndex.bin"
AccPat_DualVoice_ClampIndex2:
	.incbin "includes/generated/v7_transplant_AccPat_DualVoice_ClampIndex2.bin"
AccPat_DualVoice_DataBlock:
	.incbin "includes/generated/v7_transplant_AccPat_DualVoice_DataBlock.bin"
AccPat_DualVoice_ReadParamsA:
	.incbin "includes/generated/v7_transplant_AccPat_DualVoice_ReadParamsA.bin"
__pad_F6333A:
	nop
	nop

AccPatch_LoadDualVoiceParamsB:
	.incbin "includes/generated/v7_transplant_AccPatch_LoadDualVoiceParamsB.bin"
__pad_F63364:
	nop
	nop

AccPat_DualVoice_CopyAllBanks:
	.incbin "includes/generated/v7_transplant_AccPat_DualVoice_CopyAllBanks.bin"
__pad_F6339E:
	nop
	nop

ToneBank_CopyEntry:
	.incbin "includes/generated/v7_transplant_ToneBank_CopyEntry.bin"
__pad_F633E3:
	.incbin "includes/generated/v7_transplant___pad_F633E3.bin"
ToneBank_CopyComplete_Return:
	.incbin "includes/generated/v7_transplant_ToneBank_CopyComplete_Return.bin"
ToneBank_CopyChunk:
	nop

ToneBank_ComputeEntryAddress:
	and xhl, 0xfff
	sla xhl, 8
	add xhl, xwa
	add xhl, 0x1400
	ret

ToneBank_CopyChunk_Return:
	ldw de, 0x96

__pad_F63498:
	.incbin "includes/generated/v7_transplant___pad_F63498.bin"
ToneBank_ComputeAddr_CheckRange:
	.incbin "includes/generated/v7_transplant_ToneBank_ComputeAddr_CheckRange.bin"
ToneBank_ComputeAddr_Return:
	ret

__pad_F634B5:
	ldw de, 0x96

ToneBank_CopyChunkWithSwap:
	cp de, 0x154
	jr nc, ToneBank_SwapCopy_Return
	ld hl, de
	calr AccPat_IndexToAddress
	bitm 7, (xhl)
	jr z, ToneBank_SwapCopy_Pad
	inc 1, de
	jr ToneBank_CopyChunkWithSwap

ToneBank_SwapCopy_Return:
	.incbin "includes/generated/v7_transplant_ToneBank_SwapCopy_Return.bin"
ToneBank_SwapCopy_Pad:
	ret

__pad_F634D1:
	.incbin "includes/generated/v7_transplant___pad_F634D1.bin"
RhythmROM_PatternDispatcher:
	.incbin "includes/generated/v7_transplant_RhythmROM_PatternDispatcher.bin"
AccPat_CalcAccentVelocity_Body:
	.incbin "includes/generated/v7_transplant_AccPat_CalcAccentVelocity_Body.bin"
RhythmROM_LoadAndInit:
	calr DrumKit_DataTable_Entry0
	calr AccPatch_LoadDualVoiceParamsB
	calr AccSection_ProcessEntry

AccPat_CalcAccent_Return:
	ret

__pad_F6358B:
	nop
	nop

RhythmROM_LoadPattern:
	.incbin "includes/generated/v7_transplant_RhythmROM_LoadPattern.bin"
RhythmROM_PatternDisp_InitLoop:
	neg	wa
	.byte 0xd3
	pop	sr
	.byte 0xd3
	reti
	.byte 0xd3
	pop	sr
	.byte 0xd3
	reti
	.byte 0xd2
	pop	sr
	.byte 0xd2
	pop	sr
	ld	wa, 984
	xordm16_24	(0x07d207), wa
	reti
	neg	wa

RhythmROM_PatternDisp_ReadByte:
	.incbin "includes/generated/v7_transplant_RhythmROM_PatternDisp_ReadByte.bin"
RhythmROM_PatternDisp_CheckCmd:
	popw	wa
	push	sr
	jrl	ge, 18434
	.byte 0x06
	jrl	ge, 28166
	pop	sr
	jr	nz, 7
	.byte 0x9f
	pop	sr
	.byte 0x9f
	reti
	incf
	pop	sr
	incf
	pop	sr
	push	xiy
	pop	sr
	push	xiy
	pop	sr
	incf
	reti
	incf
	reti
	push	xiy
	reti
	push	xiy
	reti

RhythmROM_PatternDisp_Handle90:
	.incbin "includes/generated/v7_transplant_RhythmROM_PatternDisp_Handle90.bin"
RhythmROM_PatternDisp_Check91:
	.incbin "includes/generated/v7_transplant_RhythmROM_PatternDisp_Check91.bin"
RhythmROM_PatternDisp_Handle91:
	nop
	nop

RhythmROM_CalcPatternAddr:
	.incbin "includes/generated/v7_transplant_RhythmROM_CalcPatternAddr.bin"
RhythmROM_PatternDisp_Return:
	nop
	nop

__pad_F636FB:
	.incbin "includes/generated/v7_transplant___pad_F636FB.bin"
RhythmROM_InitPattern:
	.incbin "includes/generated/v7_transplant_RhythmROM_InitPattern.bin"
RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

__pad_F63748:
	.incbin "includes/generated/v7_transplant___pad_F63748.bin"
RhythmROM_ProcessPattern:
	.incbin "includes/generated/v7_transplant_RhythmROM_ProcessPattern.bin"
RhythmVoice_SetupChannels:
	cp a, 0x8
	jr z, RhythmROM_ReturnZero
	cp a, 0x9
	jr z, RhythmROM_ReturnZero
	cp a, 0xa
	jr z, RhythmROM_ReturnZero
	cp a, 0xb
	jr z, RhythmROM_ReturnZero
	cp a, 0xc
	jr z, RhythmROM_ReturnZero
	cp a, 0xd
	jr z, RhythmROM_ReturnZero
	cp a, 0xe
	jr z, RhythmROM_ReturnZero
	cp a, 0xf
	jr z, RhythmROM_ReturnZero
	jr RhythmROM_NullRet

RhythmROM_ReturnZero:
	xor a, a

RhythmROM_NullRet:
	ret

RhythmVoice_SetupChan_Finalize:
	nop
	nop

RhythmROM_CountEntries:
	.incbin "includes/generated/v7_transplant_RhythmROM_CountEntries.bin"
RhythmVoice_WriteToBuffer:
	cp a, 0x83
	jr z, RhythmVoice_WriteBuf_Done
	cp a, 0x81
	jr nz, RhythmVoice_WriteBuf_Clamp
	inc 1, e

RhythmVoice_WriteBuf_Clamp:
	ld a, (xhl)
	inc 1, xhl
	jr RhythmVoice_WriteToBuffer

RhythmVoice_WriteBuf_Done:
	ret

__pad_F63813:
	nop
	nop
	ldb	c, 16
	ld	a, (xiy)
	jr	nz, 3
	ld	(xiy), 32
	jr	nz, 3
	ld	(xiy), 32
	dec	1, bc
	inc	1, iy
	cps	bc, 0
	jr	nz, -20
	ret
	nop
	nop

DrumKit_DataTable_Entry0:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry0.bin"
DrumKit_DataTable_Entry1:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry1.bin"
DrumKit_DataTable_Entry2:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry2.bin"
DrumKit_DataTable_Entry3:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry3.bin"
DrumKit_DataTable_Entry4:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry4.bin"
DrumKit_DataTable_Entry5:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry5.bin"
DrumKit_DataTable_Entry6:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry6.bin"
DrumKit_DataTable_Entry7:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry7.bin"
DrumKit_DataTable_Entry8:
	.incbin "includes/generated/v7_transplant_DrumKit_DataTable_Entry8.bin"
RhythmROM_LoadKit_InitLDA:
	nop
	nop

ToneData_LookupEffectParam:
	.incbin "includes/generated/v7_transplant_ToneData_LookupEffectParam.bin"
RhythmROM_LoadKit_Return:
	nop
	nop

__pad_F63A6C:
	.incbin "includes/generated/v7_transplant___pad_F63A6C.bin"
RhythmROM_LoadKit_CopyLoop:
	.incbin "includes/generated/v7_transplant_RhythmROM_LoadKit_CopyLoop.bin"
RhythmROM_LoadKit_CopyReturn:
	nop
	nop

__pad_F63AE7:
	.incbin "includes/generated/v7_transplant___pad_F63AE7.bin"
VoiceSlot_ResolveIndex:
	.zero 8
	nop
	nop
	push	xwa
	.byte 0x01
	push	xwa
	halt
	push	xix
	.byte 0x01
	push	xix
	halt
	ldw	wa, 0x3201
	.byte 0x01
	ldw	ix, 0x3601
	.byte 0x01
	ldw	wa, 0x3205
	halt
	ldw	ix, 0x3605
	halt
	ret
	nop
	nop

VoiceSlot_Resolve_Loop:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_Loop.bin"
VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_StoreA.bin"
VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_StoreB.bin"
VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_StoreC.bin"
VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_StoreD.bin"
VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Resolve_Done.bin"
__pad_F63BDA:
	.incbin "includes/generated/v7_transplant___pad_F63BDA.bin"
AccSection_ProcessEntry:
	.incbin "includes/generated/v7_transplant_AccSection_ProcessEntry.bin"
AccSection_Process_Loop:
	.incbin "includes/generated/v7_transplant_AccSection_Process_Loop.bin"
AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63CFB:
	.incbin "includes/generated/v7_transplant___pad_F63CFB.bin"
AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D47:
	.incbin "includes/generated/v7_transplant___pad_F63D47.bin"
AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D93:
	.incbin "includes/generated/v7_transplant___pad_F63D93.bin"
AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63DDF:
	.incbin "includes/generated/v7_transplant___pad_F63DDF.bin"
AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63E2B:
	.incbin "includes/generated/v7_transplant___pad_F63E2B.bin"
AccSection_Finalize:
	nop
	nop

; ============================================================================
; RhythmBuf_LoadPattern - Load rhythm pattern from ROM to DRAM buffer
; ============================================================================
; Input:  XIY = source ROM pointer, XIZ = write offset, XDE = dest base
; Output: Pattern data at 0x95c00 + index*256
; Copies bytes until end marker (0x83) or buffer full (0xfe). Chains buffers.
; ============================================================================
RhythmBuf_LoadPattern:
	.incbin "includes/generated/v7_transplant_RhythmBuf_LoadPattern.bin"
AccFill_CheckPattern:
	.incbin "includes/generated/v7_transplant_AccFill_CheckPattern.bin"
AccFill_ProcessEntry:
	.incbin "includes/generated/v7_transplant_AccFill_ProcessEntry.bin"
AccFill_ProcessDone:
	.incbin "includes/generated/v7_transplant_AccFill_ProcessDone.bin"
__pad_F63E69:
	.incbin "includes/generated/v7_transplant___pad_F63E69.bin"
AccFill_AdvanceAndCheck:
	ld a, (xiy)
	ld hl, de
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a
	jr __pad_F63E69

AccFill_AdvCheck_Return:
	ldw wa, 0xffff
	ld hl, de
	calr AccPat_IndexToAddress
	lds32 xiy, 3

AccFill_AdvCheck_Done:
	ret

__pad_F63EC6:
	nop
	nop
	push	sr
	.byte 0x04, 0x06
	ldio	1, 2
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	1, 2
	pop	sr
	.byte 0x04
	halt
	ei	7
	.byte 0x08

RhythmBuf_FillEmptyPattern:
	.incbin "includes/generated/v7_transplant_RhythmBuf_FillEmptyPattern.bin"
StyleConvert_ReloadParams:
	ld (xhl), a
	inc 1, xhl
	dec 1, e
	cps e, 0
	jr nz, StyleConvert_ReloadParams
	ld (xhl), 0x83
	ret

StyleConvert_Reload_Loop:
	.incbin "includes/generated/v7_transplant_StyleConvert_Reload_Loop.bin"
AccPat_CalcAccentVelocity:
	.incbin "includes/generated/v7_transplant_AccPat_CalcAccentVelocity.bin"
StyleConvert_Reload_CheckEnd:
	.incbin "includes/generated/v7_transplant_StyleConvert_Reload_CheckEnd.bin"
StyleConvert_Reload_Return:
	.incbin "includes/generated/v7_transplant_StyleConvert_Reload_Return.bin"
StyleConvert_Reload_Fallback:
	.incbin "includes/generated/v7_transplant_StyleConvert_Reload_Fallback.bin"
StyleConvert_Reload_Done:
	ret

__pad_F63F8F:
	.incbin "includes/generated/v7_transplant___pad_F63F8F.bin"
AccWidget_DispatchTable:
	ld xiy, 0x9b4000
	ld xix, 0x94800
	ldw bc, 0x8000
	ldirw
	jp AccWidget_Dispatch_Return

AccWidget_Dispatch_Return:
	ret

__pad_F6414E:
	nop
	nop

AccWidget_ProcessSpecialCmd:
	.incbin "includes/generated/v7_transplant_AccWidget_ProcessSpecialCmd.bin"
__pad_F64174:
	.incbin "includes/generated/v7_transplant___pad_F64174.bin"
DrumKit_ErrorFallbackLoop:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_ErrorFallbackSlotIter:
	.incbin "includes/generated/v7_transplant_DrumKit_ErrorFallbackSlotIter.bin"
DrumKit_SetErrorCode20:
	.incbin "includes/generated/v7_transplant_DrumKit_SetErrorCode20.bin"
DrumKit_RestoreRegisters:
	.incbin "includes/generated/v7_transplant_DrumKit_RestoreRegisters.bin"
DrumKit_Return:
	ret

DrumKit_GroupAssignTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01
	.byte 0x02, 0x02, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x00, 0x04, 0x08, 0x0c
	.byte 0x12, 0x18, 0x0d, 0x13, 0x19, 0x0e, 0x14, 0x1a
	.byte 0x0f, 0x15, 0x1b, 0x10, 0x16, 0x1c, 0x11, 0x17
	.byte 0x1d

RhythmROM_LoadDrumKit:
	.incbin "includes/generated/v7_transplant_RhythmROM_LoadDrumKit.bin"
DrumKit_PatternLoadFailed:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_FallbackSlotLoop:
	.incbin "includes/generated/v7_transplant_DrumKit_FallbackSlotLoop.bin"
DrumKit_AllPatternsOK:
	.incbin "includes/generated/v7_transplant_DrumKit_AllPatternsOK.bin"
DrumKit_Epilogue:
	.incbin "includes/generated/v7_transplant_DrumKit_Epilogue.bin"
DrumKit_FallbackSlotTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x10, 0x11, 0x04, 0x05, 0x06, 0x07, 0x12, 0x13
	.byte 0x14, 0x15, 0x16, 0x17, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x18, 0x19, 0x1a, 0x1b, 0x1d, 0x1d

DrumParam_Wrapper:
	calr DrumParam_Lookup
	ret

DrumParam_Lookup:
	push xhl
	lds32 xhl, 0
	and w, 0x7
	sll w, 2
	ld l, w
	add xhl, DrumParam_PointerTableAndData_0x2
	ld xhl, (xhl)
	push_a
	lds32 xwa, 0
	pop_a
	add xhl, xwa
	ld a, (xhl)
	pop xhl
	ret

DrumParam_PointerTableAndData:
	.incbin "includes/generated/v7_transplant_DrumParam_PointerTableAndData.bin"
DrumKitInit_Wrapper:
	push xiz
	call DrumKitInit_Entry
	pop xiz
	ret

DrumKitInit_Entry:
	.incbin "includes/generated/v7_transplant_DrumKitInit_Entry.bin"
DrumKitInit_Setup:
	.incbin "includes/generated/v7_transplant_DrumKitInit_Setup.bin"
DrumKitInit_ClearAssignFlags:
	.incbin "includes/generated/v7_transplant_DrumKitInit_ClearAssignFlags.bin"
DrumKitInit_CheckExtAssign:
	.incbin "includes/generated/v7_transplant_DrumKitInit_CheckExtAssign.bin"
DrumKitInit_FinalSetup:
	.incbin "includes/generated/v7_transplant_DrumKitInit_FinalSetup.bin"
DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	.incbin "includes/generated/v7_transplant_DrumKit_SendProgramChange.bin"
DrumKit_SendPC_MaskAndSend:
	and l, 0x1f
	add l, 0x80
	ld xbc, 0xfc5a
	ldb a, 0x0
	lda_dri XSP, 0x03, 0xe4, 0xe0
	ldb a, 0x1
	ldb_sri H, 0x03, 0xe4, 0xe0
	and h, 0x80
	lda_dri XIZ, 0x03, 0xe4, 0xe0
	calr DrumKit_PostMidiEvents
	ret

DrumKitExit_Wrapper:
	push xiz
	call DrumKitExit_Entry
	pop xiz
	ret

DrumKitExit_Entry:
	.incbin "includes/generated/v7_transplant_DrumKitExit_Entry.bin"
DrumKitExit_CheckState1:
	.incbin "includes/generated/v7_transplant_DrumKitExit_CheckState1.bin"
DrumKitExit_ClearFlags:
	.incbin "includes/generated/v7_transplant_DrumKitExit_ClearFlags.bin"
DrumKitExit_PostRestore:
	call AccWrap_PlayModeDispatch
	calr DrumKit_ValidateBank
	call SeqAcc_RestorePlaybackState
	cpdi16 0x28a8, 0
	jr nz, DrumKitExit_ExtraInit
	cpdi16 0xf19e, 0
	jr nz, DrumKitExit_ExtraInit
	jr DrumKitExit_CheckAutoPlay

DrumKitExit_ExtraInit:
	call AccWrap_PlayModeDispatch

DrumKitExit_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_DrumKitExit_CheckAutoPlay.bin"
DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
	push	xiz
	call	DrumKit_ValidateBank
	pop	xiz
	ret

DrumKit_ValidateBank:
	ldb_d8 a, (0xfc5a)
	cp a, 0x80
	jr c, DrumKit_ValidateBank_Return
	cp a, 0x8b
	jr ule, DrumKit_ValidateBank_Return
	cp a, 0x91
	jr ugt, DrumKit_ValidateBank_Mid
	ldb l, 0x80
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_Mid:
	cp a, 0x97
	jr ugt, DrumKit_ValidateBank_High
	ldb l, 0x84
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_High:
	ldb l, 0x88

DrumKit_ValidateBank_Apply:
	.incbin "includes/generated/v7_transplant_DrumKit_ValidateBank_Apply.bin"
DrumKit_ValidateBank_Return:
	ret

DrumKit_StoreAndSendBank:
	stb_d8 (0xfc5a), l
	anddi8 (0xfc5b), 128
	ldb h, 0x0
	call PartCtrl_WriteProgramChange
	ld xix, 0xff92
	lda_dri XIZ, 0x03, 0xf0, 0xec
	call DrumKit_PostMidiEvents
	ret

DrumKit_PostMidiEvents:
	.incbin "includes/generated/v7_transplant_DrumKit_PostMidiEvents.bin"
DrumKit_UpdateStatusFlags:
	.incbin "includes/generated/v7_transplant_DrumKit_UpdateStatusFlags.bin"
DrumKit_StatusBit3:
	bit 3, a
	jr z, DrumKit_StatusBit0
	or w, 0x39

DrumKit_StatusBit0:
	bit 0, a
	jr z, DrumKit_StatusBit1
	or w, 0x35

DrumKit_StatusBit1:
	bit 1, a
	jr z, DrumKit_StatusBit2
	or w, 0x2d

DrumKit_StatusBit2:
	bit 2, a
	jr z, DrumKit_StoreStatus
	or w, 0x1d

DrumKit_StoreStatus:
	.incbin "includes/generated/v7_transplant_DrumKit_StoreStatus.bin"
DrumKit_InlineCode1:
	.incbin "includes/generated/v7_transplant_DrumKit_InlineCode1.bin"
DrumSlot_DispatchWrapper:
	push xiz
	call DrumSlot_Dispatch
	pop xiz
	ret

DrumSlot_Dispatch:
	cp hl, 0xa
	jr c, DrumSlot_ClampAndLookup
	lds hl, 0

DrumSlot_ClampAndLookup:
	ld xiy, DrumSlot_HandlerTable
	pushw hl
	sll hl, 2
	ld_sril3 XWA, 0x07, 0xf4, 0xec
	popw hl
	call (xwa)
	calr DrumKit_SendProgramChange
	ret

DrumSlot_HandlerTable:
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
DrumSlot_Handler_Type0:
	calr	5
	ret
DrumSlot_Handler_Type1:
	; --- Wrapper: calr to F64DC4, ret (4 bytes) ---
	calr DrumSlot_OffsetCalc_Extended
	ret
DrumSlot_OffsetCalc_Simple:
	.incbin "includes/generated/v7_transplant_DrumSlot_OffsetCalc_Simple.bin"
DrumSlot_OffsetCalc_Check20:
	cp e, 0x20
	jr nz, DrumSlot_OffsetCalc_AddHigh
	add l, 0x04
	jr t, DrumSlot_OffsetCalc_StoreAndRet
DrumSlot_OffsetCalc_AddHigh:
	add l, 0x08
DrumSlot_OffsetCalc_StoreAndRet:
	.incbin "includes/generated/v7_transplant_DrumSlot_OffsetCalc_StoreAndRet.bin"
DrumSlot_OffsetCalc_Extended:
	.incbin "includes/generated/v7_transplant_DrumSlot_OffsetCalc_Extended.bin"
DrumSlot_ExtOffset_Check20:
	cp e, 0x20
	jr nz, DrumSlot_ExtOffset_AddHigh
	add l, 0x0e
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_AddHigh:
	add l, 0x14
DrumSlot_ExtOffset_StoreAndRet:
	.incbin "includes/generated/v7_transplant_DrumSlot_ExtOffset_StoreAndRet.bin"
RhythmPatInit_Wrapper:
	; --- Push XIZ wrapper for inner routine (7 bytes) ---
	push xiz
	call RhythmPatInit_Entry
	pop xiz
	ret
RhythmPatInit_Entry:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_Entry.bin"
RhythmPatInit_Cleanup:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_Cleanup.bin"
RhythmPatInit_LoadParams:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_LoadParams.bin"
RhythmPatInit_FlagBit7:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_FlagBit7.bin"
RhythmPatInit_Tempo4:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_Tempo4.bin"
RhythmPatInit_Tempo5:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_Tempo5.bin"
RhythmPatInit_CopyChannels:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_CopyChannels.bin"
RhythmPatInit_KitIndexTable:
	.incbin "includes/generated/v7_transplant_RhythmPatInit_KitIndexTable.bin"
RhythmFillIn_Wrapper:
	push xiz
	call RhythmFillIn_Select
	pop xiz
	ret

RhythmFillIn_Select:
	.incbin "includes/generated/v7_transplant_RhythmFillIn_Select.bin"
RhythmFillIn_LookupAndApply:
	.incbin "includes/generated/v7_transplant_RhythmFillIn_LookupAndApply.bin"
RhythmFillIn_PatternTable:
	.incbin "includes/generated/v7_transplant_RhythmFillIn_PatternTable.bin"
RhythmMute_Wrapper:
	push xiz
	call RhythmMute_Toggle
	pop xiz
	ret

RhythmMute_Toggle:
	calr RhythmMute_StateMachine
	ret

RhythmMute_StateMachine:
	.incbin "includes/generated/v7_transplant_RhythmMute_StateMachine.bin"
RhythmMute_State1:
	.incbin "includes/generated/v7_transplant_RhythmMute_State1.bin"
RhythmMute_State8:
	.incbin "includes/generated/v7_transplant_RhythmMute_State8.bin"
RhythmMute_StateDone:
	ret

RhythmMute_InlineCode:
	.incbin "includes/generated/v7_transplant_RhythmMute_InlineCode.bin"
RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	.incbin "includes/generated/v7_transplant_RhythmSolo_Toggle.bin"
RhythmSolo_Disable:
	.incbin "includes/generated/v7_transplant_RhythmSolo_Disable.bin"
RhythmSolo_UpdateStatus:
	.incbin "includes/generated/v7_transplant_RhythmSolo_UpdateStatus.bin"
RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	.incbin "includes/generated/v7_transplant_RhythmVariation_Select.bin"
RhythmVariation_PostDispatch:
	.incbin "includes/generated/v7_transplant_RhythmVariation_PostDispatch.bin"
RhythmVariation_Return:
	ret

RhythmVariation_InlineCode:
	.incbin "includes/generated/v7_transplant_RhythmVariation_InlineCode.bin"
RhythmConfig_ReturnStub:
	ret

RhythmConfig_InlineCode2:
	.incbin "includes/generated/v7_transplant_RhythmConfig_InlineCode2.bin"
DrumTempo_Adjust:
	.incbin "includes/generated/v7_transplant_DrumTempo_Adjust.bin"
DrumTempo_CheckMax:
	cp a, l
	jr z, DrumTempo_Done
	inc 1, a
	jr DrumTempo_Store

DrumTempo_Decrement:
	cps a, 1
	jr z, DrumTempo_Done
	dec 1, a

DrumTempo_Store:
	.incbin "includes/generated/v7_transplant_DrumTempo_Store.bin"
DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	.incbin "includes/generated/v7_transplant_DrumVoice_Select.bin"
DrumVoice_ClampMin:
	dec 1, l
	calr DrumVoice_Dispatch
	pop xiz
	ret

DrumVoice_InlineStub:
	push	xiz
	call	DrumVoice_Dispatch
	pop	xiz
	ret

DrumVoice_Dispatch:
	.incbin "includes/generated/v7_transplant_DrumVoice_Dispatch.bin"
DrumVoice_DispatchTable:
	.long DrumVoice_Handler0
	.long DrumVoice_Handler1
	.long DrumVoice_Handler2
	.long DrumVoice_Handler3
	.long DrumVoice_Handler4
	.long DrumVoice_Handler5
	.long DrumVoice_Handler6
	.long DrumVoice_Handler7
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
DrumVoice_NullHandler:
	ret
DrumVoice_Handler0:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler0.bin"
DrumVoice_Handler1:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler1.bin"
DrumVoice_Handler2:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler2.bin"
DrumVoice_Handler3:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler3.bin"
DrumVoice_Handler5:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler5.bin"
DrumVoice_Handler4:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler4.bin"
DrumVoice_Handler6:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler6.bin"
DrumVoice_Handler7:
	.incbin "includes/generated/v7_transplant_DrumVoice_Handler7.bin"
DrumVoice_NotifyEE:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ldb a, 0xee
	call SoundCtrl_SendCommand
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

TimeSig_DisplayStrings:
	.incbin "includes/generated/v7_transplant_TimeSig_DisplayStrings.bin"
Tempo_AdjustStartMeasure:
	.incbin "includes/generated/v7_transplant_Tempo_AdjustStartMeasure.bin"
Tempo_StartMeasureDec:
	.incbin "includes/generated/v7_transplant_Tempo_StartMeasureDec.bin"
Tempo_StartMeasureSync:
	.incbin "includes/generated/v7_transplant_Tempo_StartMeasureSync.bin"
Tempo_StartMeasureSyncFar:
	.incbin "includes/generated/v7_transplant_Tempo_StartMeasureSyncFar.bin"
Tempo_StartMeasureSetDirty:
	.incbin "includes/generated/v7_transplant_Tempo_StartMeasureSetDirty.bin"
Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	.incbin "includes/generated/v7_transplant_Tempo_AdjustEndMeasure.bin"
Tempo_EndMeasureDec:
	.incbin "includes/generated/v7_transplant_Tempo_EndMeasureDec.bin"
Tempo_EndMeasureSyncStart:
	.incbin "includes/generated/v7_transplant_Tempo_EndMeasureSyncStart.bin"
Tempo_EndMeasureSyncFar:
	.incbin "includes/generated/v7_transplant_Tempo_EndMeasureSyncFar.bin"
Tempo_EndMeasureSetDirty:
	.incbin "includes/generated/v7_transplant_Tempo_EndMeasureSetDirty.bin"
Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	.incbin "includes/generated/v7_transplant_Tempo_AdjustQuantize.bin"
Tempo_QuantizeDec:
	.incbin "includes/generated/v7_transplant_Tempo_QuantizeDec.bin"
Tempo_QuantizeSetDirty:
	.incbin "includes/generated/v7_transplant_Tempo_QuantizeSetDirty.bin"
Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	.incbin "includes/generated/v7_transplant_Tempo_AdjustEffect.bin"
Tempo_EffectDec:
	cps a, 0
	jr z, Tempo_EffectReturn
	dec 1, a

Tempo_EffectStore:
	.incbin "includes/generated/v7_transplant_Tempo_EffectStore.bin"
Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	.incbin "includes/generated/v7_transplant_Tempo_IncrementTimeSigNum.bin"
Tempo_DecrementTimeSigNum:
	.incbin "includes/generated/v7_transplant_Tempo_DecrementTimeSigNum.bin"
Tempo_TimeSigCodeBlock:
	.incbin "includes/generated/v7_transplant_Tempo_TimeSigCodeBlock.bin"
Tempo_EditBPM:
	.incbin "includes/generated/v7_transplant_Tempo_EditBPM.bin"
Tempo_EditBPMDec:
	.incbin "includes/generated/v7_transplant_Tempo_EditBPMDec.bin"
Tempo_EditBPMClamp:
	.incbin "includes/generated/v7_transplant_Tempo_EditBPMClamp.bin"
Tempo_EditBPMApply:
	.incbin "includes/generated/v7_transplant_Tempo_EditBPMApply.bin"
Tempo_DisplayParamCommon:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayParamCommon.bin"
Tempo_DisplayParamSkipClear:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayParamSkipClear.bin"
Tempo_DisplayParamFormat:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayParamFormat.bin"
Tempo_DisplayParamReturn:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayParamReturn.bin"
Tempo_DisplayStartMeasure:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayStartMeasure.bin"
Tempo_DisplayEndMeasure:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayEndMeasure.bin"
Tempo_DisplayQuantize:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayQuantize.bin"
Tempo_DisplayTimeSigNum:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayTimeSigNum.bin"
Tempo_DisplayEffect:
	calr Tempo_DisplayEffectRender

Tempo_DisplayEffectLookup:
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

Tempo_DisplayEffectRender:
	lds wa, 0
	calr SeqRec_ValidateDone
	lds wa, 1
	calr SeqRec_ValidateDone
	lds wa, 2
	calr SeqRec_ValidateDone
	lds wa, 3
	calr SeqRec_ValidateDone
	lds wa, 4
	jrl SeqRec_ValidateDone

Tempo_FormatBPM:
	.incbin "includes/generated/v7_transplant_Tempo_FormatBPM.bin"
Tempo_FormatBPMDigit:
	.incbin "includes/generated/v7_transplant_Tempo_FormatBPMDigit.bin"
Tempo_FormatBPMDone:
	.incbin "includes/generated/v7_transplant_Tempo_FormatBPMDone.bin"
Tempo_FormatBPMOutput:
	.incbin "includes/generated/v7_transplant_Tempo_FormatBPMOutput.bin"
Tempo_FormatBPMPad:
	.incbin "includes/generated/v7_transplant_Tempo_FormatBPMPad.bin"
Tempo_DisplayBPMValue:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayBPMValue.bin"
Tempo_DisplayBPMFraction:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayBPMFraction.bin"
Tempo_DisplayBPMNoFrac:
	cp a, 0x83
	jr z, Tempo_DisplayBPMWithDec

Tempo_DisplayBPMDecimal:
	calr Voice_ScanTableByType
	cps l, 1
	jr nz, Tempo_DisplayBPMFraction
	jr Tempo_DisplayBPMExit

Tempo_DisplayBPMWithDec:
	cpib_erp 0xfa, 0
	jr z, Tempo_DisplayBPMClean
	ldib_erp 0xfb, 0

Tempo_DisplayBPMFinal:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayBPMFinal.bin"
Tempo_DisplayBPMClean:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayBPMClean.bin"
Tempo_DisplayBPMExit:
	popw_erp 0xfa
	ret

Tempo_DisplayBPMReturn:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayBPMReturn.bin"
Tempo_DisplayMeasureRange:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayMeasureRange.bin"
Tempo_DisplayMeasureStart:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayMeasureStart.bin"
Tempo_DisplayMeasureSep:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayMeasureSep.bin"
Tempo_DisplayMeasureEnd:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayMeasureEnd.bin"
Tempo_DisplayQuantizeVal:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayQuantizeVal.bin"
Tempo_DisplayTimeSig:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayTimeSig.bin"
Tempo_DisplayEffectVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

Tempo_DisplayEffectValLookup:
	.incbin "includes/generated/v7_transplant_Tempo_DisplayEffectValLookup.bin"
Tempo_RefreshDisplay1:
	.incbin "includes/generated/v7_transplant_Tempo_RefreshDisplay1.bin"
Tempo_RefreshDisplay2:
	.incbin "includes/generated/v7_transplant_Tempo_RefreshDisplay2.bin"
Tempo_RefreshDisplay3:
	.incbin "includes/generated/v7_transplant_Tempo_RefreshDisplay3.bin"
Tempo_RefreshDisplay4:
	.incbin "includes/generated/v7_transplant_Tempo_RefreshDisplay4.bin"
Tempo_RefreshDisplay5:
	.incbin "includes/generated/v7_transplant_Tempo_RefreshDisplay5.bin"
SeqRec_InitState:
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld c, (xix)
	extz bc
	calr SeqRec_OverflowCleanup

SeqRec_InitChannels:
	.incbin "includes/generated/v7_transplant_SeqRec_InitChannels.bin"
SeqRec_StartRecord:
	cpw_erp IZ, 0xfa
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	.incbin "includes/generated/v7_transplant_SeqRec_StartRecordImpl.bin"
SeqRec_StopRecord:
	cp c, 0x82
	jr z, SeqRec_UpdateFlags
	cp c, 0x84
	jr nz, SeqRec_StartRecord
	jr SeqRec_UpdateFlags

SeqRec_StopRecordImpl:
	ld e, (xsp + 8)
	extz de
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xe8
	and c, 0x1
	sll c, 7
	ld e, (xhl + 5)
	res 7, e
	ld l, (xhl + 4)
	res 7, l
	extz de
	or c, l
	extz bc
	cp (xsp + 10), 0x0
	jr nz, SeqRec_UpdateState
	calr SeqRec_CheckOverflow
	jr SeqRec_StartRecord

SeqRec_UpdateState:
	calr SeqRec_OverflowCleanup
	cpw_erp IZ, 0xfa
	jr c, SeqRec_StartRecordImpl

SeqRec_UpdateFlags:
	pop xiz
	inc 8, xsp
	ret

SeqRec_CheckOverflow:
	lda xhl, (xwa + 1)
	cp c, 0xf0
	jr c, SeqRec_HandleOverflow
	and c, 0xf
	ld (xwa), c
	ld (xhl), e
	ret

SeqRec_HandleOverflow:
	ld (xwa), 0x0
	ld (xhl), 0x0
	ret

SeqRec_OverflowCleanup:
	lda xhl, (xwa + 1)
	cp c, 0xf0
	jr nc, SeqRec_CommitData
	cp c, 0x80
	jr c, SeqRec_CommitData
	cps e, 7
	jr nz, SeqRec_CommitData
	ldb c, 0x58
	jr SeqRec_CommitFinalize

SeqRec_CommitData:
	cp c, 0xf0
	jr c, SeqRec_Validate
	ldb c, 0x0

SeqRec_CommitFinalize:
	ld (xwa), c
	ld (xhl), 0x0
	ret

SeqRec_Validate:
	ld (xwa), c
	res 7, e
	ld (xhl), e
	ret

SeqRec_ValidateDone:
	.incbin "includes/generated/v7_transplant_SeqRec_ValidateDone.bin"
SeqRec_Cleanup:
	.incbin "includes/generated/v7_transplant_SeqRec_Cleanup.bin"
Part_SetVoiceType1:
	.incbin "includes/generated/v7_transplant_Part_SetVoiceType1.bin"
Part_SetVoiceType2:
	.incbin "includes/generated/v7_transplant_Part_SetVoiceType2.bin"
Part_SetVoiceType4:
	.incbin "includes/generated/v7_transplant_Part_SetVoiceType4.bin"
Part_LoadAndIndexVoiceTable:
	.incbin "includes/generated/v7_transplant_Part_LoadAndIndexVoiceTable.bin"
Part_StoreVoiceTableIndex:
	.incbin "includes/generated/v7_transplant_Part_StoreVoiceTableIndex.bin"
SetWall_StoreAndResolve:
	stda16 (0x287f), xwa
	extz bc
	ld wa, bc
	jp Voice_ResolveSlotAddr

MIDIChan_ScanForFree:
	ld xbc, 0xf1a0
	ldb a, 0x1

MIDIChan_ScanLoop:
	cp (xbc), 0x10
	jr z, MIDIChan_Found
	inc 1, xbc
	inc 1, a
	cp a, 0x11
	jr ule, MIDIChan_ScanLoop

MIDIChan_Found:
	.incbin "includes/generated/v7_transplant_MIDIChan_Found.bin"
MIDIChan_StoreResult:
	.incbin "includes/generated/v7_transplant_MIDIChan_StoreResult.bin"
VoiceSlot_UpdateState:
	.incbin "includes/generated/v7_transplant_VoiceSlot_UpdateState.bin"
VoiceSlot_SetBit2:
	setda 2, 0x287b

VoiceSlot_ValidateAndResolve:
	.incbin "includes/generated/v7_transplant_VoiceSlot_ValidateAndResolve.bin"
VoiceSlot_CheckSlot2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckSlot2.bin"
VoiceSlot_CheckSlot3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckSlot3.bin"
VoiceSlot_CheckSlot4:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckSlot4.bin"
VoiceSlot_CheckSlot5:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckSlot5.bin"
VoiceSlot_ResolveAddr:
	call Voice_ResolveSlotAddr

VoiceSlot_StoreAndReturn:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreAndReturn.bin"
Part_IsPercussionType:
	dec 1, a
	extz wa
	extz xwa
	add xwa, 0xf1a0
	ld a, (xwa)
	cp a, 0xd
	jr z, EventCode_CheckExit
	cp a, 0xe
	jr z, EventCode_CheckExit
	cp a, 0xf
	jr z, EventCode_CheckExit
	cp a, 0x10
	jr nz, PartType_NotPercussion

EventCode_CheckExit:
	ldb l, 0x1
	jr PartType_Return

PartType_NotPercussion:
	ldb l, 0x0

PartType_Return:
	ret

Voice_ReadEventBytes:
	push xiz
	calr VoiceTable_ResolveReadAddr
	ld xwa, xhl
	ld c, (xwa)
	and c, 0xf0
	cp c, 0x80
	jr z, VoiceEvt_Size1
	cp c, 0xd0
	jr z, VoiceEvt_CheckD2
	cp c, 0xc0
	jr z, VoiceEvt_Size6
	cp c, 0xb0
	jr z, VoiceEvt_Size6
	cp c, 0x90
	jr nz, VoiceEvt_Size1

VoiceEvt_Size6:
	ldiw_erp 0xfa, 6
	jr VoiceBuffer_CopyLoop

VoiceEvt_CheckD2:
	cp (xwa), 0xd2
	jr nz, VoiceEvt_Size3
	ldiw_erp 0xfa, 4
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size3:
	ldiw_erp 0xfa, 3
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size1:
	ldiw_erp 0xfa, 1

VoiceBuffer_CopyLoop:
	lds iz, 0
	cpiw_erp 0xfa, 0
	jr ule, VoiceBuf_CopyDone

VoiceBuf_CopyLoop:
	.incbin "includes/generated/v7_transplant_VoiceBuf_CopyLoop.bin"
VoiceBuf_CopyDone:
	pop xiz
	ret

Voice_ScanTableByType:
	.incbin "includes/generated/v7_transplant_Voice_ScanTableByType.bin"
VoiceScan_Size8:
	ldi_erpw 0xfa, 0x08, 0x00
	jr Voice_ScanTableEntries

Voice_SetScanType3:
	ldiw_erp 0xfa, 3
	jr Voice_ScanTableEntries

VoiceScan_Size1:
	ldiw_erp 0xfa, 1
	jr Voice_ScanTableEntries

VoiceScan_Size0:
	ldiw_erp 0xfa, 0

Voice_ScanTableEntries:
	lds iz, 0
	cpiw_erp 0xfa, 0
	jr ule, VoiceScan_NotFound

VoiceScan_WriteLoop:
	.incbin "includes/generated/v7_transplant_VoiceScan_WriteLoop.bin"
VoiceScan_NextEntry:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, VoiceScan_WriteLoop

VoiceScan_NotFound:
	ldb l, 0x0

VoiceScan_Return:
	pop xiz
	ret

VoiceTable_AdvanceReadPos:
	.incbin "includes/generated/v7_transplant_VoiceTable_AdvanceReadPos.bin"
VoiceTable_AdvRead_Done:
	jr VoiceTable_ResolveReadAddr

VoiceTable_ResolveReadAddr:
	.incbin "includes/generated/v7_transplant_VoiceTable_ResolveReadAddr.bin"
VoiceTable_AdvanceWritePos:
	.incbin "includes/generated/v7_transplant_VoiceTable_AdvanceWritePos.bin"
VoiceTable_AdvWrite_AllocSlot:
	.incbin "includes/generated/v7_transplant_VoiceTable_AdvWrite_AllocSlot.bin"
VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	stb_dri B, 0xe9, 0x00, 0x01
	cp bc, 0x153
	jr ule, VoiceTable_AdvWrite_ScanLoop

VoiceTable_AdvWrite_LinkEntry:
	.incbin "includes/generated/v7_transplant_VoiceTable_AdvWrite_LinkEntry.bin"
RhythmParam_Setup:
	calr Voice_ResolveTableAddr

; Rhythm parameter entry
RhythmParam_Entry:
	ret

Voice_ResolveTableAddr:
	.incbin "includes/generated/v7_transplant_Voice_ResolveTableAddr.bin"
RhythmParam_TypeCheck:
	.incbin "includes/generated/v7_transplant_RhythmParam_TypeCheck.bin"
RhythmParam_Dispatch:
	extz bc
	sub bc, 0x80
	cps bc, 0
	jr lt, RhythmParam_CheckExit
	cps bc, 6
	jr gt, RhythmParam_CheckExit
	add bc, bc
	lda_24 xix, (Display_FontPalette_Table_0x52CE)
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda_24 xix, (RhythmParam_CheckExit)
	jp_ind 8, 0x07, 0xf0, 0xe4

RhythmParam_CheckExit:
	ld (xde), 0x0
	ret

RhythmParam_DispatchTableData:
	ld	(xde), 131
	ret

; Rhythm parameter processing
RhythmParam_Process:
	.incbin "includes/generated/v7_transplant_RhythmParam_Process.bin"
VoiceNote_SubtractOffset:
	cp e, 0x19
	jr nc, Voice_BoundaryCheck
	ld xix, xbc
	ldb a, 0x19
	sub a, e
	ld e, a
	ld a, (xbc)
	sub a, e
	ld (xbc), a
	cps a, 0
	jr ge, Voice_BoundaryCheck
	ld (xix), 0x0

Voice_BoundaryCheck:
	.incbin "includes/generated/v7_transplant_Voice_BoundaryCheck.bin"
VoiceBound_CalcOctave:
	ld a, (xhl + 2)
	extz wa
	div a, 0xc
	ld e, w
	lda xwa, (xhl + 6)
	lda xbc, (xhl + 7)
	cp e, 0xb
	jr z, VoiceParam_D0_CheckD4
	cps e, 7
	jr z, VoiceParam_D0_Skip
	cps e, 4
	jr z, VoiceParam_D0_Process
	cps e, 3
	jr nz, VoiceParam_D0_StoreD5

VoiceParam_D0_Process:
	ld (xhl), 0x91
	ld (xwa), 0x0
	jr VoiceParam_D0_CheckD5

VoiceParam_D0_Skip:
	ld (xhl), 0x91
	ld (xwa), 0x3
	ld (xbc), 0x0
	ret

VoiceParam_D0_CheckD4:
	ld (xhl), 0x91
	ld (xwa), 0x11

VoiceParam_D0_CheckD5:
	ld (xbc), 0x11
	ret

VoiceParam_D0_StoreD5:
	ld (xhl), 0x90
	ret

VoiceParam_B0_Handler:
	ld xde, xbc
	ld c, (xbc)
	res 7, c
	cp c, 0x16
	jr ule, VoiceParam_B0_CheckType
	cp c, 0x19
	jrl nz, Voice_ClearSlotAndRet

VoiceParam_B0_CheckType:
	ld a, (xwa)
	and a, 0x1f
	lda xbc, (xhl + 4)
	lda xix, (xhl + 5)
	cps a, 4
	jr nz, __pad_F66E4B
	bitm 3, (xix)
	jr z, __pad_F66E4B
	ld (xhl), 0xd3
	bitm 3, (xbc)
	jr nz, VoiceParam_B0_Process
	ld (xde), 0x0
	ret

VoiceParam_B0_Process:
	ld (xde), 0x7f
	ret

__pad_F66E4B:
	cp a, 0x8
	jr nz, Voice_ClearSlotAndRet
	ld a, (xix)
	res 7, a
	cps a, 0
	jr z, Voice_ClearSlotAndRet
	ld (xhl), 0xd4
	ld a, (xbc)
	res 7, a
	ld (xde), a
	ret

; Voice parameter D0 type (fine tuning)
VoiceParam_D0Handler:
	cp e, 0xd2
	jr nz, VoiceParam_D3Special
	ld e, (xwa)
	cp e, 0x40
	jr c, VoiceParam_DownscaleBelow40
	sub e, 0x40
	extz de
	div e, 0x6
	add e, 0x40
	ld (xbc), e
	ret

; Voice param downscale below 0x40
VoiceParam_DownscaleBelow40:
	ldb a, 0x40
	sub a, e
	extz wa
	div a, 0x6
	ld e, a
	ldb a, 0x40
	sub a, e
	ld (xbc), a
	ret

; Voice parameter D3 special case (transition to D5)
VoiceParam_D3Special:
	cp e, 0xd3
	ret nz
	ld (xhl), 0xd5
	ret

; Voice slot dispatch
VoiceSlot_Dispatch:
	extz de
	sub de, 0x80
	cps de, 0
	jr lt, Voice_ClearSlotAndRet
	cps de, 6
	jr gt, Voice_ClearSlotAndRet
	add de, de
	lda_24 xix, (Display_FontPalette_Table_0x52C0)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, (Voice_ClearSlotAndRet)
	jp_ind 8, 0x07, 0xf0, 0xe8

Voice_ClearSlotAndRet:
	ld (xhl), 0x0
	ret

VoiceSlot_DispatchByType:
	ld	(xhl), 131
	ret
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	pushw	wa
	pushw	hl
	call	TimeSig_DisplayStrings_0x935
	inc	4, xsp
	ret

Voice_ResolveSlotAddr:
	.incbin "includes/generated/v7_transplant_Voice_ResolveSlotAddr.bin"
VoiceSlot_Dispatch_Type81:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Dispatch_Type81.bin"
VoiceSlot_Dispatch_Type90:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Dispatch_Type90.bin"
VoiceSlot_Dispatch_D0Type:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Dispatch_D0Type.bin"
VoiceSlot_Dispatch_Return:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Dispatch_Return.bin"
DrumParam_ProcessChannel:
	push xiz
	calr DrumParam_LookupChannelBit
	call __pad_F67013
	pop xiz
	ret

DrumParam_LookupChannelBit:
	.incbin "includes/generated/v7_transplant_DrumParam_LookupChannelBit.bin"
PatIdx_Lookup_Return:
	.byte 0x01
	push	sr
	.byte 0x04
	ldio	16, 32
	.byte 0x40

__pad_F67013:
	.incbin "includes/generated/v7_transplant___pad_F67013.bin"
VoiceTable_InitEntry:
	ld (xiy), 0x9
	jr RhythmVoice_LoadParams

VoiceTable_InitEntry_Loop:
	cp (xiy), 0x0
	jr z, RhythmVoice_LoadParams
	decm8 1, (xiy)

RhythmVoice_LoadParams:
	pop l
	push l
	calr DrumParam_ReadMaxCount
	pop l
	cp l, w
	jr ule, VoiceTable_InitEntry_Done
	push w
	calr DrumParam_ReadVoiceCount
	pop w
	ld (xix), w

VoiceTable_InitEntry_Done:
	calr RhythmDrum_LoadVoiceParams
	calr __pad_F67459
	calr DrumParam_BuildActiveMask
	ret

DrumParam_BuildActiveMask:
	.incbin "includes/generated/v7_transplant_DrumParam_BuildActiveMask.bin"
VoiceTable_InitEntry_Store:
	.incbin "includes/generated/v7_transplant_VoiceTable_InitEntry_Store.bin"
VoiceTable_InitEntry_Return:
	.incbin "includes/generated/v7_transplant_VoiceTable_InitEntry_Return.bin"
MultiVoice_SetupChannel:
	.incbin "includes/generated/v7_transplant_MultiVoice_SetupChannel.bin"
MultiVoice_Setup_Loop:
	.incbin "includes/generated/v7_transplant_MultiVoice_Setup_Loop.bin"
MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	.incbin "includes/generated/v7_transplant_Rhythm_MapChannelToDrumIndex.bin"
MultiVoice_Setup_NextChan:
	push c
	lds32 xbc, 0
	pop c
	ret

MultiVoice_Setup_Done:
	nop
	.byte 0x01
	push	sr
	nop
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x06

DrumParam_ReadVoiceCount:
	.incbin "includes/generated/v7_transplant_DrumParam_ReadVoiceCount.bin"
RhythmDrum_LoadVoiceParams:
	.incbin "includes/generated/v7_transplant_RhythmDrum_LoadVoiceParams.bin"
VoiceAssign_ProcessRequest:
	cp hl, bc
	jr z, VoiceAssign_Process_Loop
	push xbc
	ldb_sri C, 0x07, 0xe0, 0xec
	and xbc, 0xff
	add xde, xbc
	pop xbc
	inc 1, hl
	jr VoiceAssign_ProcessRequest

VoiceAssign_Process_Loop:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Process_Loop.bin"
VoiceAssign_Process_Return:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Process_Return.bin"
VoiceAssign_StoreFinal:
	ret

__pad_F671E7:
	pushw hl
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	popw hl
	ld xwa, RegPreset_LoadVoiceData
	ldb_sri A, 0x07, 0xe0, 0xec
	and xwa, 0x7
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x4
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr RegPreset_Load_Loop
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x14
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr MIDIChan_DispatchDone
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x24
	ld de, (xbc)
	push xix
	calr VoiceResolve_CheckAndStore
	pop xix
	pop xwa
	push xix
	calr __pad_F6742B
	pop xix
	ret

RegPreset_LoadVoiceData:
	nop
	pop	sr
	.byte 0x04
	reti
	nop
	nop
	retd	3844
	.byte 0x04
	retd	0
	.byte 0x04
	retd	3844
	.byte 0x04
	retd	4
	nop
	ldw	bc, 0x3104
	.byte 0x04
	ldw	bc, 0
	.byte 0x04
	ldw	bc, 0x3104
	.byte 0x04
	ldw	bc, 4
	nop
	ei	4
	ei	4
	di
	nop
	.byte 0x04
	ei	4
	ei	4
	ei	4

RegPreset_Load_Loop:
	push xix
	push xde
	calr DrumChannel_MapToIndexA
	pop xde
	pop xix
	ld wa, bc
	sll wa, 1
	mul a, 0x14
	add wa, de
	push xwa
	call MIDIChan_DispatchTable
	pop xwa
	lds hl, 1
	cp wa, 0x400
	jr nc, RegPreset_Load_Return
	lds hl, 0

RegPreset_Load_Return:
	lds32 xbc, 0

__pad_F6729B:
	cps c, 4
	jr z, ChanAssign_StoreResult
	push xbc
	pushw wa
	push xbc
	calr __pad_F672B2
	pop xbc
	calr ChanAssign_Lookup_Found
	popw wa
	pop xbc
	inc 1, wa
	inc 1, c
	jr __pad_F6729B

ChanAssign_StoreResult:
	ret

__pad_F672B2:
	lds32 xde, 0
	ldb_sri E, 0x07, 0xf0, 0xe0
	sll e, 1
	push xix
	pushw de
	pushw hl
	calr DrumChannel_MapToIndexB
	popw hl
	popw de
	pop xix
	mul c, 0x26
	add bc, de
	cps hl, 0
	jr nz, ChanAssign_Lookup
	add bc, 0x118
	jr ChanAssign_Lookup_Loop

ChanAssign_Lookup:
	add bc, 0x518

ChanAssign_Lookup_Loop:
	lds32 xwa, 0
	ldw_sri WA, 0x07, 0xf0, 0xe4
	ld xde, xiy
	add xde, xwa
	ret

ChanAssign_Lookup_Found:
	.incbin "includes/generated/v7_transplant_ChanAssign_Lookup_Found.bin"
MIDIChan_DispatchTable:
	.incbin "includes/generated/v7_transplant_MIDIChan_DispatchTable.bin"
DrumChannel_MapToIndexA:
	.incbin "includes/generated/v7_transplant_DrumChannel_MapToIndexA.bin"
MIDIChan_Dispatch_Ch1:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch1.bin"
MIDIChan_Dispatch_Ch2:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch2.bin"
MIDIChan_Dispatch_Ch3:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch3.bin"
MIDIChan_Dispatch_Ch4:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch4.bin"
MIDIChan_Dispatch_Ch5:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch5.bin"
MIDIChan_Dispatch_Ch6:
	lds32 xbc, 4

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	.incbin "includes/generated/v7_transplant_DrumChannel_MapToIndexB.bin"
MIDIChan_Dispatch_Ch7:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch7.bin"
MIDIChan_Dispatch_Ch8:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch8.bin"
MIDIChan_Dispatch_Ch9:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch9.bin"
MIDIChan_Dispatch_Ch10:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch10.bin"
MIDIChan_Dispatch_Ch11:
	.incbin "includes/generated/v7_transplant_MIDIChan_Dispatch_Ch11.bin"
MIDIChan_Dispatch_Ch12:
	lds32 xbc, 5

DrumChannel_MapB_NullRet:
	ret

MIDIChan_DispatchDone:
	.incbin "includes/generated/v7_transplant_MIDIChan_DispatchDone.bin"
VoiceResolve_CheckAndStore:
	.incbin "includes/generated/v7_transplant_VoiceResolve_CheckAndStore.bin"
VoiceResolve_Return:
	ldb a, 0x1

__pad_F67412:
	jr VoiceResolve_InitSearch

Rhythm_ClearChannelDrumIndex:
	ldb a, 0x0

VoiceResolve_InitSearch:
	.incbin "includes/generated/v7_transplant_VoiceResolve_InitSearch.bin"
VoiceResolve_SearchDone:
	ldio	8, 8
	ldio	8, 16
	.byte 0x20

__pad_F6742B:
	.incbin "includes/generated/v7_transplant___pad_F6742B.bin"
VoiceResolve_FindSlot:
	push xbc
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xe4, 0xe0
	pop xbc
	ret

VoiceResolve_FindSlot_Return:
	add	a, 3
	ret

__pad_F67459:
	.incbin "includes/generated/v7_transplant___pad_F67459.bin"
DrumParam_ProcessChannelAlt:
	push xiz
	calr DrumParam_LookupChannelBit
	call PartVoice_UpdateParams
	pop xiz
	ret

PartVoice_UpdateParams:
	.incbin "includes/generated/v7_transplant_PartVoice_UpdateParams.bin"
PartVoice_Update_Loop:
	.incbin "includes/generated/v7_transplant_PartVoice_Update_Loop.bin"
DrumParam_ClampVoiceCount:
	cp c, w
	jr gt, PartVoice_Update_Return
	cps c, 0
	jr lt, PartVoice_Update_Done
	jr __pad_F674CB

PartVoice_Update_Return:
	ld c, w
	jr __pad_F674CB

PartVoice_Update_Done:
	ldb c, 0x0

__pad_F674CB:
	ld (xix), c
	calr RhythmDrum_LoadVoiceParams
	calr DrumParam_BuildActiveMask
	ret

DrumParam_ReadMaxCount:
	.incbin "includes/generated/v7_transplant_DrumParam_ReadMaxCount.bin"
ExtVoice_ProcessList:
	.incbin "includes/generated/v7_transplant_ExtVoice_ProcessList.bin"
AccVoice_SetupStyleSlots:
	calr __pad_F676E6
	calr DrumChannel_MapToIndexB
	sll xbc, 1
	add xix, xbc
	ld hl, (xix)
	pushw hl
	calr AccPatch_ResolveEntryAddr
	push xwa
	add xwa, 0x3
	ld hl, (xwa)
	ldw (xwa), 0xffff
	pop xwa
	pushw hl
	calr Voice_ClearSlotBuffer
	calr __pad_F676C1
	popw hl

AccVoice_SetupSlots_Loop:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupSlots_Loop.bin"
AccVoice_SetupSlots_InitEntry:
	popw hl
	ret

Voice_ClearSlotBuffer:
	add xwa, 0x6
	ld xix, xwa
	ld xbc, 0xf9

AccVoice_SetupSlots_StoreEntry:
	cps bc, 0
	jr z, AccVoice_SetupSlots_Return
	ldb a, 0x0
	ld (xix), a
	inc 1, xix
	dec 1, bc
	jr AccVoice_SetupSlots_StoreEntry

AccVoice_SetupSlots_Return:
	ret

__pad_F676C1:
	.incbin "includes/generated/v7_transplant___pad_F676C1.bin"
AccVoice_SetupSlots_CheckType:
	cps bc, 0
	jr z, AccVoice_SetupSlots_Done
	ldb e, 0x81
	ld (xwa), e
	inc 1, xwa
	dec 1, bc
	jr AccVoice_SetupSlots_CheckType

AccVoice_SetupSlots_Done:
	ldb c, 0x83
	ld (xwa), c
	ret

__pad_F676E6:
	.incbin "includes/generated/v7_transplant___pad_F676E6.bin"
AccVoice_SetupSlots_Write:
	mul l, 0x60
	add hl, 0x60
	ld xix, 0x94800
	add xix, xhl
	ret

AccVoice_SetupSlots_WriteDone:
	nop
	nop

AccPatch_ResolveEntryAddr:
	push xix
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xwa, 0x95c00
	add xwa, xhl
	popw hl
	pop xix
	ret

AccVoice_SetupSlots_DataBlock:
	.incbin "includes/generated/v7_transplant_AccVoice_SetupSlots_DataBlock.bin"
VoiceSlot_InitFromTable:
	push xiz
	call VoiceSlot_Init_CheckType
	pop xiz
	ret

VoiceSlot_Init_CheckType:
	calr VoiceSlot_Init_Process
	calr AccVoice_SetupStyleSlots
	ret

VoiceSlot_Init_Process:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Init_Process.bin"
CmpMode_NullRet:
	ret

__pad_F67D15:
	.incbin "includes/generated/v7_transplant___pad_F67D15.bin"
CmpMenuTtl_Setup:
CmpModeFunc:
	cp xbc, 0x1c00013
	jr nz, DrumKitExit_ReturnZero
	cp xde, 0x1
	jr z, CmpMenuTtl_InitTitle
	or xde, xde
	jr nz, DrumKitExit_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call DrumKitInit_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DrumKitExit_ReturnZero

; CmpMenuTtlFunc init title
CmpMenuTtl_InitTitle:
	push xde
	push xhl
	push xix
	push xiz
	call DrumKitExit_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde

DrumKitExit_ReturnZero:
	lds32 xhl, 0
	ret
; CmpMenuTtlFunc main handler
CmpMenuTtl_MainHandler:
CmpMenuTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpMenuTtl_SpecialKeys
	cp xbc, 0x1c00013
	jr nz, CmpMenuTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CmpMenuTtl_ReturnZero
	cp xde, 0x6
	jr ugt, CmpMenuTtl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x701A
	ld de, (xde)
	lda_24 xix, (CmpMenuTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpMenuTtlFunc title dispatch
CmpMenuTtl_Dispatch:
	setda	2, 0x28a7
	call	AccWrap_PlayModeDispatch
	jr	t, 0x46

; CmpMenuTtl special key handler (0x88-0x8a)
CmpMenuTtl_SpecialKeys:
	.incbin "includes/generated/v7_transplant_CmpMenuTtl_SpecialKeys.bin"
CmpMenuTtl_SetBit5:
	.incbin "includes/generated/v7_transplant_CmpMenuTtl_SetBit5.bin"
CmpMenuTtl_SetBit4:
	.incbin "includes/generated/v7_transplant_CmpMenuTtl_SetBit4.bin"
CmpMenuTtl_PostModeEvent:
	call UI_PostModeChangeEvent

CmpMenuTtl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpSetTtlFunc main handler
CmpSetTtl_MainHandler:
CmpSetTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpSetTtl_ModeSwitch
	cp xbc, 0x1c00013
	jrl nz, CmpReal_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpReal_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7040
	ld de, (xde)
	lda_24 xix, (CmpSetTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch
CmpSetTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_CmpSetTtl_Dispatch.bin"
CmpSetTtl_ModeSwitch:
	.incbin "includes/generated/v7_transplant_CmpSetTtl_ModeSwitch.bin"
VoiceSlot_ResolveFromMap:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x0
	call DrumTempo_Adjust
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

VoiceSlot_Resolve_StoreMap:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x80
	call DrumTempo_Adjust
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl drum voice select (w=0)
CmpSetTtl_DrumVoice0:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x0
	call DrumVoice_Select
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl drum voice select (w=0x80)
CmpSetTtl_DrumVoice1:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x80
	call DrumVoice_Select
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl secondary dispatch
CmpSetTtl_SecondaryDispatch:
	dec 1, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x5
	jr ule, CmpSetTtl_DynamicLookup
	sub xde, 0x7a
	cp xde, 0x6
	jr c, CmpReal_ReturnZero
	cp xde, 0xb
	jr ugt, CmpReal_ReturnZero

; CmpSetTtl dynamic table lookup
CmpSetTtl_DynamicLookup:
	add xde, xde
	add xde, Display_FontPalette_Table_0x7028
	ld de, (xde)
	lda_24 xix, (CmpSetTtl_Dispatch2)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch 2
CmpSetTtl_Dispatch2:
	.incbin "includes/generated/v7_transplant_CmpSetTtl_Dispatch2.bin"
CmpReal_ReturnZero:
	lds32 xhl, 0
	ret
; CmpRealTtlFunc entry
CmpRealTtl_Entry:
CmpRealTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpRealTtl_MajorDispatch
	cp xbc, 0x1c00013
	jrl nz, CmpBk_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBk_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBk_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7068
	ld de, (xde)
	lda_24 xix, (CmpRealTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpRealTtlFunc title dispatch
CmpRealTtl_Dispatch:
	.ascii ":;<>"
	call	RhythmFillIn_PatternTable_0x8
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	7235
	jrl	678
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmFillIn_PatternTable_0x8
	.ascii "^\\[Zx—"
	push	sr

; CmpRealTtl major dispatch (5-way)
CmpRealTtl_MajorDispatch:
	ld xwa, xde
	cp xde, 0x84
	jrl z, CmpRealTtl_RhythmVar4
	cp xde, 0x83
	jrl z, CmpRealTtl_RhythmVar3
	cp xde, 0x82
	jrl z, CmpRealTtl_RhythmVar2
	cp xde, 0x81
	jrl z, CmpRealTtl_RhythmVar1
	cp xde, 0x80
	jr z, CmpRealTtl_RhythmVar0
	cp xwa, 0xc
	jrl ugt, CmpBk_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x704E
	ld wa, (xwa)
	lda_24 xix, (CmpRealTtl_RhythmVar0)
	jp_ind 8, 0x07, 0xf0, 0xe0

; CmpRealTtl rhythm variation 0
CmpRealTtl_RhythmVar0:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 0
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 1
CmpRealTtl_RhythmVar1:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 1
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 2
CmpRealTtl_RhythmVar2:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 2
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 3
CmpRealTtl_RhythmVar3:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 4
CmpRealTtl_RhythmVar4:
	.incbin "includes/generated/v7_transplant_CmpRealTtl_RhythmVar4.bin"
CmpBk_DeliverEvent:
	call ApDeliveryEvent

CmpBk_ReturnZero:
	lds32 xhl, 0
	ret
; CmpOffsetFunc dispatch
CmpOffset_Dispatch:
CmpBkslTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpBkslTtl_Mode1
	cp xbc, 0x1c00013
	jrl nz, CmpBksl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBksl_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBksl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7076
	ld de, (xde)
	lda_24 xix, (CmpBkslTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpBkslTtlFunc title dispatch
CmpBkslTtl_Dispatch:
	.ascii ":;<>"
	call	DrumKit_InlineCode1_0x8
	.ascii "^\\[Zx."
	.byte 0x01
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumKit_InlineCode1_0x8
	pop	xiz
	.ascii "\\[Zx"
	.byte 0x1f, 0x01

; CmpBkslTtl mode 1
CmpBkslTtl_Mode1:
	cp xde, 0x8c
	jrl z, CmpBkslTtl_ModeDefault
	cp xde, 0xc
	jrl z, CmpBkslTtl_ModeSelect
	cp xde, 0x8b
	jrl z, DrumSlot_Dispatch_Slot6
	cp xde, 0xb
	jrl z, DrumSlot_Dispatch_Slot7
	cp xde, 0x8a
	jrl z, DrumSlot_Dispatch_Slot4
	cp xde, 0xa
	jr z, DrumSlot_Dispatch_Slot5
	cp xde, 0x89
	jr z, DrumSlot_Dispatch_Slot2
	cp xde, 0x9
	jr z, DrumSlot_Dispatch_Slot3_WithMode
	cp xde, 0x88
	jr z, DrumSlot_Dispatch_Slot0
	cp xde, 0x8
	jrl nz, CmpBksl_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 1
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jrl CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot0:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 0
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jrl CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot3_WithMode:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 3
	call DrumSlot_DispatchWrapper
	ldw wa, 0xb2
	call UI_PostModeChangeEvent
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpBksl_ReturnZero

DrumSlot_Dispatch_Slot2:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 2
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot5:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 5
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot4:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 4
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot7:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 7
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot6:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 6
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

; CmpBkslTtl mode select
CmpBkslTtl_ModeSelect:
	push xde
	push xhl
	push xix
	push xiz
	ldw hl, 0x9
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2
	jr CmpBksl_ApplyAndReturnZero

; CmpBkslTtl mode default
CmpBkslTtl_ModeDefault:
	push xde
	push xhl
	push xix
	push xiz
	ldw hl, 0x8
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb2

CmpBksl_ApplyAndReturnZero:
	call UI_PostModeChangeEvent

CmpBksl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpBksl_STtlFunc main handler
CmpBkslSTtl_MainHandler:
CmpBksl_STtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpBkslSTtl_DirectMode
	cp xbc, 0x1c00013
	jrl nz, DisplayFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xde, 0x6
	jrl ugt, DisplayFunc_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x709A
	ld de, (xde)
	lda_24 xix, (CmpBkslSTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpBksl_STtlFunc title dispatch
CmpBkslSTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_Dispatch.bin"
CmpBkslSTtl_DirectMode:
	ld xwa, xde
	cp xde, 0x4
	jrl z, CmpBkslSTtl_FillIn8
	cp xde, 0x3
	jrl z, CmpBkslSTtl_FillIn7
	cp xde, 0x2
	jr z, CmpBkslSTtl_FillIn6
	cp xde, 0x1
	jr z, CmpBkslSTtl_FillIn5
	or xde, xde
	jr z, CmpBkslSTtl_FillIn4
	sub xwa, 0x80
	cp xwa, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xwa, 0xa
	jrl ugt, DisplayFunc_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x7084
	ld wa, (xwa)
	lda_24 xix, (CmpBkslSTtl_FillIn4)
	jp_ind 8, 0x07, 0xf0, 0xe0

; CmpBkslSTtl fill-in level 4
CmpBkslSTtl_FillIn4:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_FillIn4.bin"
CmpBkslSTtl_FillIn5:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_FillIn5.bin"
CmpBkslSTtl_FillIn6:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_FillIn6.bin"
CmpBkslSTtl_FillIn7:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_FillIn7.bin"
CmpBkslSTtl_FillIn8:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_FillIn8.bin"
CmpBkslSTtl_EventPost:
	.incbin "includes/generated/v7_transplant_CmpBkslSTtl_EventPost.bin"
CmpBk_PostModeChange:
	call UI_PostModeChangeEvent

DisplayFunc_ReturnZero:
	lds32 xhl, 0
	ret
; CmpNcpTtlFunc main handler
CmpNcpTtl_MainHandler:
CmpNcpTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CmpNcpTtl_SpecialMode7
	cp xbc, 0x1c00013
	jrl nz, CmEsy_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmEsy_ReturnZero
	cp xde, 0x6
	jrl ugt, CmEsy_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x70D0
	ld de, (xde)
	lda_24 xix, (CmpNcpTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpNcpTtlFunc title dispatch
CmpNcpTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_CmpNcpTtl_Dispatch.bin"
CmpNcpTtl_SpecialMode7:
	cp xde, 0xb
	jr ule, CmpNcpTtl_TableDispatch
	sub xde, 0x74
	cp xde, 0xc
	jrl c, CmEsy_ReturnZero
	cp xde, 0x13
	jrl ugt, CmEsy_ReturnZero

; CmpNcpTtl table-driven dispatch
CmpNcpTtl_TableDispatch:
	add xde, xde
	add xde, Display_FontPalette_Table_0x70A8
	ld de, (xde)
	lda_24 xix, (CmpNcpTtl_Dispatch2)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpNcpTtlFunc title dispatch 2
CmpNcpTtl_Dispatch2:
	.incbin "includes/generated/v7_transplant_CmpNcpTtl_Dispatch2.bin"
CmEsy_ReturnZero:
	lds32 xhl, 0
	ret
; CmEsyTtlFunc main handler
CmpEsyTtl_MainHandler:
CmEsyTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CmpEsyTtl_Mode1
	cp xbc, 0x1c00013
	jrl nz, S2cTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, S2cTtl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x70FE
	ld de, (xde)
	lda_24 xix, (CmEsyTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmEsyTtlFunc title dispatch
CmEsyTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_CmEsyTtl_Dispatch.bin"
CmpEsyTtl_Mode1:
	cp xde, 0xb
	jr ule, CmpEsyTtl_Mode2
	sub xde, 0x74
	cp xde, 0xc
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x13
	jrl ugt, S2cTtl_ReturnZero

; CmpEsyTtl mode 2
CmpEsyTtl_Mode2:
	add xde, Display_FontPalette_Table_0x70DE
	ld de, (xde)
	extz de
	sll de, 1
	ld xix, Display_FontPalette_Table_0x70F2
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, (CmEsyTtl_Dispatch2)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmEsyTtlFunc title dispatch 2
CmEsyTtl_Dispatch2:
	; --- Multi-branch dispatch subroutine (195 bytes) ---
	lds	wa, 0
	jrl t, CmpEsyTtl_SubModeD_Cont
	push xde
	push xhl
	push xix
	push xiz
	call ExtVoice_ProcessList_0x1
	call TimeSig_DisplayStrings_0x7C6
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0x00b5
	call UI_PostModeChangeEvent
	jrl t, S2cTtl_ReturnZero
	lds	wa, 1
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x00
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00ba0009
	ld xbc, 0x01c0000b
	lds32	xde, 0
	jr t, CmpEsy_DeliverEventAndCheck
	lds	wa, 1
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x80
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00ba0009
	ld xbc, 0x01c0000b
	lds32	xde, 0
CmpEsy_DeliverEventAndCheck:
	.incbin "includes/generated/v7_transplant_CmpEsy_DeliverEventAndCheck.bin"
CmpEsyTtl_SubModeB:
	.incbin "includes/generated/v7_transplant_CmpEsyTtl_SubModeB.bin"
CmpEsyTtl_SubModeC:
	push xde
	push xhl
	push xix
	push xiz
	call ExtVoice_ProcessList_0x1
	pop xiz
	pop xix
	pop xhl
	pop xde
; CmpEsyTtl sub-mode D entry
CmpEsyTtl_SubModeD:
	lds	wa, 0
; CmpEsyTtl sub-mode D continuation
CmpEsyTtl_SubModeD_Cont:
	call UI_PostDialEnable


S2cTtl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpEsyTtl sub-mode E dispatch
CmpEsyTtl_SubModeE:
S2cTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CmpEsyTtl_E_Var1
	cp xbc, 0x1c00013
	jrl nz, CstmCp_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7124
	ld de, (xde)
	lda_24 xix, (S2cTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; S2cTtlFunc title dispatch
S2cTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_S2cTtl_Dispatch.bin"
CmpEsyTtl_E_Var1:
	ld xwa, xde
	cp xde, 0x86
	jrl z, CstmCp_ReturnZero
	cp xde, 0x84
	jrl z, CstmCp_ReturnZero
	cp xde, 0x82
	jrl z, S2cTtl_SecondaryHandler
	cp xde, 0x81
	jrl z, S2cTtl_MainHandler
	cp xde, 0x80
	jrl z, CmpEsyTtl_E_Var2
	cp xwa, 0xb
	jrl ugt, CstmCp_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x710C
	ld wa, (xwa)
	lda_24 xix, (CmpEsy_E_DispatchDataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe0

CmpEsy_E_DispatchDataBlock:
	.incbin "includes/generated/v7_transplant_CmpEsy_E_DispatchDataBlock.bin"
CmpEsyTtl_E_Var2:
	.incbin "includes/generated/v7_transplant_CmpEsyTtl_E_Var2.bin"
CmpEsy_E_Var2_StoreMeasure:
	.incbin "includes/generated/v7_transplant_CmpEsy_E_Var2_StoreMeasure.bin"
CmpEsy_E_EndMeasure_Store:
	.incbin "includes/generated/v7_transplant_CmpEsy_E_EndMeasure_Store.bin"
S2cTtl_MainHandler:
	.incbin "includes/generated/v7_transplant_S2cTtl_MainHandler.bin"
CmpEsy_Main_EndMeasure_Store:
	.incbin "includes/generated/v7_transplant_CmpEsy_Main_EndMeasure_Store.bin"
CmpEsy_Quantize_Store:
	.incbin "includes/generated/v7_transplant_CmpEsy_Quantize_Store.bin"
S2cTtl_SecondaryHandler:
	.incbin "includes/generated/v7_transplant_S2cTtl_SecondaryHandler.bin"
CmpEsy_SecQuantize_Store:
	.incbin "includes/generated/v7_transplant_CmpEsy_SecQuantize_Store.bin"
TtlFunc_SendEventAndReturn:
	call ApDeliveryEvent
	jr CstmCp_ReturnZero
	lds wa, 0
	call Tempo_EditBPM

CstmCp_ReturnZero:
	lds32 xhl, 0
	ret
; CstmCpTtl record dispatch
CstmCpTtl_RecDispatch:
CstmCpTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CstmCpTtl_RecMode1
	cp xbc, 0x1c00013
	jrl nz, CstmCp_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero2
	add xde, xde
	add xde, Display_FontPalette_Table_0x715A
	ld de, (xde)
	lda_24 xix, (CstmCpTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch
CstmCpTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_CstmCpTtl_Dispatch.bin"
CstmCpTtl_RecMode1:
	cp xde, 0xb
	jr ule, CstmCpTtl_RecMode2
	sub xde, 0x74
	cp xde, 0xc
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x13
	jrl ugt, CstmCp_ReturnZero2

; CstmCpTtl record mode 2
CstmCpTtl_RecMode2:
	add xde, xde
	add xde, Display_FontPalette_Table_0x7132
	ld de, (xde)
	lda_24 xix, (CstmCpTtl_Dispatch2)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch 2
CstmCpTtl_Dispatch2:
	.incbin "includes/generated/v7_transplant_CstmCpTtl_Dispatch2.bin"
CstmCp_ReturnZero2:
	lds32 xhl, 0
	ret

CstmCp_StyleDataBlock:
	.incbin "includes/generated/v7_transplant_CstmCp_StyleDataBlock.bin"
__pad_F695CA:

MainCstmNameFunc:
	.incbin "includes/generated/v7_transplant_MainCstmNameFunc.bin"
CstmName_HandleEvent2C:
	.incbin "includes/generated/v7_transplant_CstmName_HandleEvent2C.bin"
CstmName_PostEventAndReturn:
	call ApPostEvent

CstmName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 120)
	ret
__pad_F696AB:

MainS2cFunc:
	.incbin "includes/generated/v7_transplant_MainS2cFunc.bin"
S2cFunc_HandleEvent11:
	.incbin "includes/generated/v7_transplant_S2cFunc_HandleEvent11.bin"
S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69788:

MiddleNameFunc:
	.incbin "includes/generated/v7_transplant_MiddleNameFunc.bin"
MiddleName_HandleEvent01:
	.incbin "includes/generated/v7_transplant_MiddleName_HandleEvent01.bin"
MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8a40

MiddleName_CopyAndPost:
	.incbin "includes/generated/v7_transplant_MiddleName_CopyAndPost.bin"
MiddleName_PostModeChange:
	call UI_PostModeChangeEvent

MiddleName_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F697FE:

MiddleCmpClrFunc:
	.incbin "includes/generated/v7_transplant_MiddleCmpClrFunc.bin"
MiddleCmpClr_HandleEvent07:
	.incbin "includes/generated/v7_transplant_MiddleCmpClr_HandleEvent07.bin"
MiddleCmpClr_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6985D:

MainCmpCpFunc:
	.incbin "includes/generated/v7_transplant_MainCmpCpFunc.bin"
MainCmpCp_HandleEvent03:
	.incbin "includes/generated/v7_transplant_MainCmpCp_HandleEvent03.bin"
MainCmpCp_ClampRange4:
	cp a, 0x8
	jr nc, MainCmpCp_ClampRange8
	ldb a, 0x1
	jr MainCmpCp_StoreClampResult

MainCmpCp_ClampRange8:
	ldb a, 0x2

MainCmpCp_StoreClampResult:
	pushw 0xd
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	jr MainCmpCp_MemCopyAndFinalize

MemCopy_SetupParams:
	pushw 0xd
	push xhl

MainCmpCp_MemCopyAndFinalize:
	.incbin "includes/generated/v7_transplant_MainCmpCp_MemCopyAndFinalize.bin"
MainCmpSet_Init:
	cp a, 0xdc
	jr nz, MainCmpSet_Case2
	ld xwa, 0xdc0002
	ld xbc, 0x1e40005
	ld xde, xiz

; MainCmpSetFunc case 1
MainCmpSet_Case1:
	call ApDeliveryEvent

; MainCmpSetFunc case 2
MainCmpSet_Case2:
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz

; MainCmpSetFunc case 3
MainCmpSet_Case3:
	call ApPostEvent

; MainCmpSetFunc case 4
MainCmpSet_Case4:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret
; CmpSongTtlFunc main handler
CmpSong_MainHandler:
MainCmpSetFunc:
	.incbin "includes/generated/v7_transplant_MainCmpSetFunc.bin"
MainCmpSet_Dispatch:
	.incbin "includes/generated/v7_transplant_MainCmpSet_Dispatch.bin"
CmpSong_VariantA:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69B4C:

MainEsCmpFunc:
	.incbin "includes/generated/v7_transplant_MainEsCmpFunc.bin"
EsCmp_HandleEvent28:
	.incbin "includes/generated/v7_transplant_EsCmp_HandleEvent28.bin"
EsCmp_HandleEvent29:
	.incbin "includes/generated/v7_transplant_EsCmp_HandleEvent29.bin"
EsCmp_HandleEvent2A:
	.incbin "includes/generated/v7_transplant_EsCmp_HandleEvent2A.bin"
MspBksl_EventDeliver:
	call ApDeliveryEvent

EsCmp_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69C5B:

MspBkslTtlFunc:
	lds32 xhl, 0
	ret
__pad_F69C5E:

MainMspBnkNameFunc:
	lds32 xhl, 0
	ret

SoundCtrl_SendAccTempo:
	.incbin "includes/generated/v7_transplant_SoundCtrl_SendAccTempo.bin"
SoundCtrl_SendTempoScaled:
	.incbin "includes/generated/v7_transplant_SoundCtrl_SendTempoScaled.bin"
SoundCtrl_CalcScaledTempo:
	.incbin "includes/generated/v7_transplant_SoundCtrl_CalcScaledTempo.bin"
SoundCtrl_CalcTempo_Clamp:
	.incbin "includes/generated/v7_transplant_SoundCtrl_CalcTempo_Clamp.bin"
AccGuard_ProgramChangeCheck:
	.incbin "includes/generated/v7_transplant_AccGuard_ProgramChangeCheck.bin"
AccGuard_CheckMode09:
	.incbin "includes/generated/v7_transplant_AccGuard_CheckMode09.bin"
AccGuard_SendProgramChange:
	.incbin "includes/generated/v7_transplant_AccGuard_SendProgramChange.bin"
AccSeq_DeliverC9_0009:
	.incbin "includes/generated/v7_transplant_AccSeq_DeliverC9_0009.bin"
AccSeq_DeliverC9_000A:
	.incbin "includes/generated/v7_transplant_AccSeq_DeliverC9_000A.bin"
__pad_F69D47:

MainMspRgpSetFunc:
	.incbin "includes/generated/v7_transplant_MainMspRgpSetFunc.bin"
MspRgpSet_HandleEvent13:
	.incbin "includes/generated/v7_transplant_MspRgpSet_HandleEvent13.bin"
MspMenuTtl_Init:
	.incbin "includes/generated/v7_transplant_MspMenuTtl_Init.bin"
MspMenuTtl_Case1:
	.incbin "includes/generated/v7_transplant_MspMenuTtl_Case1.bin"
AccBass_EventDeliver:
	call ApDeliveryEvent

AccBass_ReturnZero:
	lds32 xhl, 0
	ret
; MspMenuTtlFunc case 2
MspMenuTtl_Case2:
MspMenuTtlFunc:
	cp xbc, 0x1c00013
	jr nz, MspNameTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspNameTtl_ReturnZero
	cp xde, 0x6
	jr ugt, MspNameTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x26
	ld de, (xde)
	lda_24 xix, (MspMenuTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspMenuTtlFunc title dispatch
MspMenuTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_MspMenuTtl_Dispatch.bin"
MspNameTtl_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 1
MspNameTtl_Mode1:
MspNameTtlFunc:
	cp xbc, 0x1c00013
	jr nz, MspRecMode_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspRecMode_ReturnZero
	cp xde, 0x6
	jr ugt, MspRecMode_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x34
	ld de, (xde)
	lda_24 xix, (MspNameTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspNameTtlFunc title dispatch
MspNameTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_MspNameTtl_Dispatch.bin"
MspRecMode_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 2
MspNameTtl_Mode2:
MspRecModeFunc:
	cp xbc, 0x1c00013
	jr nz, MspNameTtl_Mode4
	cp xde, 0x1
	jr z, MspNameTtl_Mode3
	or xde, xde
	jr nz, MspNameTtl_Mode4

; MspNameTtlFunc mode 3
MspNameTtl_Mode3:
	.incbin "includes/generated/v7_transplant_MspNameTtl_Mode3.bin"
MspNameTtl_Mode4:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 5
MspNameTtl_Mode5:
MspRecTtlFunc:
	cp xbc, 0x1e4001f
	jrl z, MspRecTtl_SubA
	cp xbc, 0x1c00013
	jrl nz, MspRecTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, MspRecTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, MspRecTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x42
	ld de, (xde)
	lda_24 xix, (MspRecTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspRecTtlFunc title dispatch
MspRecTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_MspRecTtl_Dispatch.bin"
MspRecTtl_SubA:
	.incbin "includes/generated/v7_transplant_MspRecTtl_SubA.bin"
MspRecTtl_SubA_CheckRange:
	.incbin "includes/generated/v7_transplant_MspRecTtl_SubA_CheckRange.bin"
MspRecTtl_ReturnZero:
	lds32 xhl, 0
	ret

AccSeq_PostEvent9E_Enable:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	jp ApPostEvent

AccSeq_PostEvent9E_Disable:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	jp ApPostEvent
AccSeq_DcModeDataBlock:
	.incbin "includes/generated/v7_transplant_AccSeq_DcModeDataBlock.bin"
SndArgTtl_SubA:
SndArgModeFunc:
	cp xbc, 0x1c00013
	jr nz, AccStyle_ExitReturn
	cp xde, 0x1
	jr z, SndArgTtl_SubB
	or xde, xde
	jr nz, AccStyle_ExitReturn
	push xde
	push xhl
	push xix
	push xiz
	call AccStyle_ModeEnter_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr AccStyle_ExitReturn

; SndArgTtlFunc sub-handler B
SndArgTtl_SubB:
	push xde
	push xhl
	push xix
	push xiz
	call AccStyle_ModeExit_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde

AccStyle_ExitReturn:
	lds32 xhl, 0
	ret
; SndArgTtlFunc sub-handler C
SndArgTtl_SubC:
SndArgTtlFunc:
	cp xbc, 0x1c00013
	jr nz, SndArgTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SndArgTtl_ReturnZero
	cp xde, 0x6
	jr ugt, SndArgTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x50
	ld de, (xde)
	lda_24 xix, (SndArgTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; SndArgTtlFunc title dispatch
SndArgTtl_Dispatch:
	.incbin "includes/generated/v7_transplant_SndArgTtl_Dispatch.bin"
SndArgTtl_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6A0BB:

SndArgNmGet:
	.incbin "includes/generated/v7_transplant_SndArgNmGet.bin"
SndArgNm_ChannelLoop:
	ld a, (xsp + 4)
	call AccVoice_GetChannelCount_Wrap
	ldb_erp L, 0xfb
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	extz wa
	add (xsp + 2), wa
	incm8 1, (xsp + 4)

SndArgNm_CheckChannelDone:
	lda xbc, (xsp + 6)
	ld xde, (xsp + 70)
	dec 2, xde
	ld xhl, (xsp + 70)
	add xhl, xhl
	ld a, (xsp + 4)
	cp a, (xbc)
	jr c, SndArgNm_ChannelLoop
	ld a, (xbc + 1)
	extz wa
	add (xsp + 2), wa
	ld wa, (xsp + 2)
	mul wa, 0xa
	extz xwa
	add xwa, 0x1e7810
	ld xix, xwa
	lda xwa, (xsp + 52)
	ld (xsp + 2), xwa
	dec 4, xhl
	ld xwa, (xsp + 74)
	cp xwa, 0x1e40024
	jrl z, SndArgNm_HandleEvent24
	add xhl, xix
	cp xwa, 0x1e40021
	jrl z, SndArgNm_HandleEvent21
	cp xwa, 0x1e40020
	jrl nz, SndArgNm_ReturnZero
	ld xix, xhl
	ld a, (xhl)
	ldb_erp A, 0xfb
	ld xiy, xde
	or xde, xde
	jr nz, SndArgNm_ProcessEntry
	or_erpb 0xfb, 0xf0

SndArgNm_ProcessEntry:
	.incbin "includes/generated/v7_transplant_SndArgNm_ProcessEntry.bin"
SndArgNm_HandleEvent21:
	.incbin "includes/generated/v7_transplant_SndArgNm_HandleEvent21.bin"
SndArgNm_HandleEvent21_Copy:
	.incbin "includes/generated/v7_transplant_SndArgNm_HandleEvent21_Copy.bin"
SndArgNm_DeliverEvent:
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xdc0005
	ld xbc, 0x1e40023

SndArgNm_DeliverAndReturn:
	call ApDeliveryEvent
	jr SndArgNm_ReturnZero

SndArgNm_HandleEvent24:
	.incbin "includes/generated/v7_transplant_SndArgNm_HandleEvent24.bin"
SndArgNm_ReturnZero:
	lds32 xhl, 0
	popw_erp 0xfa
	lda xsp, (xsp + 76)
	ret
__pad_F6A2E2:

CmpStepTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, NakaInst_OFF_Str_0x32
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

CmpStep_DataBlock:
	.incbin "includes/generated/v7_transplant_CmpStep_DataBlock.bin"
AccAudio_LockAcquire:
	ldw wa, 0x8
	jp Audio_Lock_Acquire

AccAudio_LockRelease:
	ldw wa, 0x8
	jp Audio_Lock_Release
AccAudio_DataBlock1:
	ld	xwa, xiy
	ld	xbc, xix
	call	GraphicsRender_ProcessEntries
	ret

AccGraphics_RenderStart:
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_Start
	pop xbc
	pop xwa
	ret

AccGraphics_DataBlock2:
	push	xwa
	ld	xwa, xiy
	call	ColorBlit_WithPaletteSave
	pop	xwa
	ret

AccDraw_Init:
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret

AccDraw_Secondary:
	push xwa
	ld xwa, xiy
	call DrawText_ExtendedLayout
	pop xwa
	ret

AccScreen_DataBlock:
	.incbin "includes/generated/v7_transplant_AccScreen_DataBlock.bin"
AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, AccScreen_UIDataBlock_0x360
	ld xix, AccScreen_UIDataBlock_0x37E
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	.incbin "includes/generated/v7_transplant_AccScreen_CalcTempoParams.bin"
AccScreen_UpdateBeatDisplay:
	.incbin "includes/generated/v7_transplant_AccScreen_UpdateBeatDisplay.bin"
AccScreen_BeatDisplay_Large:
	ld xiy, AccScreen_UIDataBlock_0x390

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	.incbin "includes/generated/v7_transplant_AccScreen_BeatDataBlock.bin"
AccScreen_DrawInit_StackWrap:
	ld xwa, AccScreen_DrawInit_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawInit_Body:
	stib_da (0x03efa8), 0x00
	calr AccScreen_DrawTempoDisplay
	ret

AccScreen_UpdateBeat_StackWrap:
	ld xwa, AccScreen_UpdateBeat_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_UpdateBeat_Body:
	stib_da (0x03efa8), 0x00
	calr AccScreen_UpdateBeatDisplay
	ret

AccScreen_DrawMeasure_StackWrap:
	ld xwa, AccScreen_DrawMeasure_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawMeasure_Body:
	stib_da (0x03efa8), 0x00
	calr AccScreen_DrawMeasureDetail
	ret

AccScreen_DrawMeasureDetail:
	.incbin "includes/generated/v7_transplant_AccScreen_DrawMeasureDetail.bin"
AccScreen_DrawMeas_Variant3:
	ld xiy, AccScreen_UIDataBlock_0x341
	calr AccDraw_Secondary
	jr AccScreen_DrawMeas_Return

AccScreen_DrawMeas_Other:
	ld xiy, AccScreen_UIDataBlock_0x356
	calr AccDraw_Init

AccScreen_DrawMeas_Return:
	ret

AccScreen_UIDataBlock:
	.incbin "includes/generated/v7_block_accscreen_uidatablock.bin"
AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlotChain_WithAddr.bin"
AccPatch_InitSlotChain:
	.incbin "includes/generated/v7_transplant_AccPatch_InitSlotChain.bin"
AccPatch_IterateSlotChain:
	.incbin "includes/generated/v7_transplant_AccPatch_IterateSlotChain.bin"
AccPatch_IterateSlot_Advance:
	.incbin "includes/generated/v7_transplant_AccPatch_IterateSlot_Advance.bin"
AccPatch_IterateSlot_NextBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_IterateSlot_NextBlock.bin"
AccPatch_SwapSlotBuffers:
	.incbin "includes/generated/v7_transplant_AccPatch_SwapSlotBuffers.bin"
AccPatch_UpdateLinkPointers:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateLinkPointers.bin"
AccPatch_UpdateLink_Back:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateLink_Back.bin"
AccPatch_UpdateLink_Fwd1:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateLink_Fwd1.bin"
AccPatch_UpdateLink_Fwd2:
	.incbin "includes/generated/v7_transplant_AccPatch_UpdateLink_Fwd2.bin"
AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	.incbin "includes/generated/v7_transplant_AccPatch_CalcSlotBufferAddr.bin"
AccPatch_VoiceAssignDataBlock:
	.incbin "includes/generated/v7_transplant_AccPatch_VoiceAssignDataBlock.bin"
cmp_ld_mae:
	push xiz
	calr CmpLoad_InitWithFlag
	pop xiz
	ret

CmpLoad_InitWithFlag:
	call AccDemo_InitWithFlag
	ret

cmp_ld_ato:
	push xiz
	calr CmpLoadAuto_CheckAndInit
	pop xiz
	ret

CmpLoadAuto_CheckAndInit:
	cps wa, 0
	jr lt, CmpLoadAuto_DemoInit
	call AccPatch_ClearModeFlag
	jr CmpLoadAuto_CountSlots

CmpLoadAuto_DemoInit:
	call AccDemo_Init_Wrap

CmpLoadAuto_CountSlots:
	call AccPatch_CountAvailableSlots
	ret

cmp_sv_mae:
	push xiz
	calr CmpSave_InitSlotAndCalcSize
	pop xiz
	ret

CmpSave_InitSlotAndCalcSize:
	call AccPatch_InitSlotChain_WithAddr
	ld hl, wa
	extz xhl
	sll xhl, 4
	ret

cmp_sv_ato:
	push xiz
	calr CmpSaveAuto_ClearFlag
	pop xiz
	ret

CmpSaveAuto_ClearFlag:
	.incbin "includes/generated/v7_transplant_CmpSaveAuto_ClearFlag.bin"
msp_ld_mae:
	push xiz
	calr MspLoad_InitVoice
	pop xiz
	ret

MspLoad_InitVoice:
	call AccompSeq_InitBankTables
	ret

msp_ld_ato:
	push xiz
	calr MspLoadAuto_CheckAndInit
	pop xiz
	ret

MspLoadAuto_CheckAndInit:
	cps wa, 0
	jr lt, MspLoadAuto_NegativeCase
	jr MspLoadAuto_Return

MspLoadAuto_NegativeCase:
	call Voice_InitBankDataSafe

MspLoadAuto_Return:
	ret

msp_sv_mae:
	push xiz
	calr MspSave_InitAndCalcSize
	pop xiz
	ret

MspSave_InitAndCalcSize:
	call Voice_RefreshBankData
	ld xhl, 0x1e881c
	ld hl, (xhl)
	extz xhl
	sll xhl, 4
	ret

msp_sv_ato:
	push xiz
	calr MspSaveAuto_Return
	pop xiz
	ret

MspSaveAuto_Return:
	ret

AccDisplay_FullInit:
	.incbin "includes/generated/v7_transplant_AccDisplay_FullInit.bin"
Display_RestoreEntry:
	resda 2, 0x28a7
	call Vga_RestoreMultiPlaneDisplay
	jr AccDisplay_CopyToFrontBuffer

AccDisplay_CopyToBackBuffer:
	.incbin "includes/generated/v7_transplant_AccDisplay_CopyToBackBuffer.bin"
AccDisplay_CopyToFrontBuffer:
	.incbin "includes/generated/v7_transplant_AccDisplay_CopyToFrontBuffer.bin"
AccBankData_InitAllSlots:
	.incbin "includes/generated/v7_transplant_AccBankData_InitAllSlots.bin"
AccBankData_InitSlot_OuterLoop:
	lds32 xde, 0

AccBankData_InitSlot_InnerLoop:
	.incbin "includes/generated/v7_transplant_AccBankData_InitSlot_InnerLoop.bin"
AccBankData_InitSlot_NonZero:
	inc 1, xde
	cp xde, 0x10
	jr c, AccBankData_InitSlot_InnerLoop

AccBankData_InitSlot_PadSpaces:
	cp xde, 0x10
	jr nc, AccBankData_PadSpaces_Done
	cp xde, 0x10
	jr nc, AccBankData_PadSpaces_Done

AccBankData_PadSpaces_Loop:
	.incbin "includes/generated/v7_transplant_AccBankData_PadSpaces_Loop.bin"
AccBankData_PadSpaces_Done:
	.incbin "includes/generated/v7_transplant_AccBankData_PadSpaces_Done.bin"
AccBankData_ProcessSlot:
	.incbin "includes/generated/v7_transplant_AccBankData_ProcessSlot.bin"
AccBankData_SlotFound:
	.incbin "includes/generated/v7_transplant_AccBankData_SlotFound.bin"
AccBankData_ReInitAllSlots:
	.incbin "includes/generated/v7_transplant_AccBankData_ReInitAllSlots.bin"
AccBankData_ReInit_Loop:
	.incbin "includes/generated/v7_transplant_AccBankData_ReInit_Loop.bin"
AccBankData_FinalizeCheck:
	.incbin "includes/generated/v7_transplant_AccBankData_FinalizeCheck.bin"
AccBankData_CompareLoop:
	stb_erp A, 0xfb
	extz wa
	ld hl, wa
	extz xhl
	add xhl, xde
	ldb_spi A, 0xf0
	cp a, (xhl)
	jr nz, AccBankData_Return
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AccBankData_CompareLoop
	ld xix, xbc
	lda_24 xbc, (0x1e0000)
	lds32 xde, 0

AccBankData_CopyToExtRAM:
	.incbin "includes/generated/v7_transplant_AccBankData_CopyToExtRAM.bin"
AccBankData_Return:
	popw_erp 0xfa
	ret

AccBankData_ProcessWithCopy:
	.incbin "includes/generated/v7_transplant_AccBankData_ProcessWithCopy.bin"
AccBankData_CopyLoop:
	.incbin "includes/generated/v7_transplant_AccBankData_CopyLoop.bin"
AccBankData_CopyLoop_NonZero:
	.incbin "includes/generated/v7_transplant_AccBankData_CopyLoop_NonZero.bin"
AccBankData_InitSlotScan:
	.incbin "includes/generated/v7_transplant_AccBankData_InitSlotScan.bin"
AccBankData_SlotScan_Loop:
	.incbin "includes/generated/v7_transplant_AccBankData_SlotScan_Loop.bin"
AccBankData_SlotScan_Next:
	.incbin "includes/generated/v7_transplant_AccBankData_SlotScan_Next.bin"
AccBankData_SlotScan_ReInit:
	.incbin "includes/generated/v7_transplant_AccBankData_SlotScan_ReInit.bin"
AccBankData_ReInit_ScanLoop:
	.incbin "includes/generated/v7_transplant_AccBankData_ReInit_ScanLoop.bin"
AccBankData_NotifyAndUpdateTempo:
	.incbin "includes/generated/v7_transplant_AccBankData_NotifyAndUpdateTempo.bin"
AccBankData_PostModeChange:
	ldw wa, 0x16
	call UI_PostModeChangeEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

AccBankData_CopyDataBlock:
	.incbin "includes/generated/v7_transplant_AccBankData_CopyDataBlock.bin"
StyleBuf_ClearAllEntries:
	.incbin "includes/generated/v7_transplant_StyleBuf_ClearAllEntries.bin"
StyleBuf_ClearEntry_Outer:
	ld xde, xwa
	lda xhl, (xwa + 32)

StyleBuf_ClearEntry_Inner:
	stib_dsp 0xe8, 0x00
	cp xde, xhl
	jr c, StyleBuf_ClearEntry_Inner
	lda xwa, (xwa + 32)
	cp xwa, xbc
	jr c, StyleBuf_ClearEntry_Outer
	ret

StyleConv_ClearWorkBuffer:
	.incbin "includes/generated/v7_transplant_StyleConv_ClearWorkBuffer.bin"
StyleConv_ClearWorkBuf_Loop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	.incbin "includes/generated/v7_transplant_StyleConv_ClearEntryTables.bin"
StyleConv_ClearEntry_Outer:
	ld xwa, xde
	lda xix, (xde + 32)

StyleConv_ClearEntry_Inner:
	stib_dsp 0xe0, 0x00
	cp xwa, xix
	jr c, StyleConv_ClearEntry_Inner
	lds32 xwa, 0
	stl_dpi XWA, 0xe6
	lda xde, (xde + 32)
	cp xbc, xhl
	jr c, StyleConv_ClearEntry_Outer
	ret

StyleConv_InitEntryTable:
	pushw iz
	lds ix, 0

StyleConvInit_OuterLoop:
	.incbin "includes/generated/v7_transplant_StyleConvInit_OuterLoop.bin"
StyleConvInit_InnerLoop:
	ldib_erp 0xe2, 0
	cp iz, 0xc
	jr nc, StyleConvInit_StoreChar
	ldi_erpb 0xe2, 0x20

StyleConvInit_StoreChar:
	ld wa, hl
	add wa, iz
	ld iy, wa
	extz xiy
	add xiy, xde
	stb_erp A, 0xe2
	ld (xiy + 1), a
	inc 1, iz
	cp iz, 0x20
	jr c, StyleConvInit_InnerLoop
	lds32 xwa, 0
	ld (xbc + 33), xwa
	inc 1, ix
	cp ix, 0x100
	jr c, StyleConvInit_OuterLoop
	popw iz
	ret

SoundMem_ClearRegion:
	ld xwa, 0xffc00

SoundMem_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, 0x100000
	jr c, SoundMem_ClearLoop
	ret

StyleFile_ClearAllTables:
	.incbin "includes/generated/v7_transplant_StyleFile_ClearAllTables.bin"
StyleFile_ClearTable_Outer:
	ld xwa, xde
	lda xix, (xde + 100)

StyleFile_ClearTable_Inner:
	stib_dsp 0xe0, 0x00
	cp xwa, xix
	jr c, StyleFile_ClearTable_Inner
	lds32 xwa, 0
	stl_dpi XWA, 0xe6
	lda xde, (xde + 100)
	cp xbc, xhl
	jr c, StyleFile_ClearTable_Outer
	ret

DialUI_PostInitEvents:
	lds wa, 1
	call UI_PostDialEnable
	ldw wa, 0x82
	call UI_PostDialValueEvent
	lds wa, 2
	jp UI_PostDialRangeEvent

DialUI_CalcProlog:
	dec 2, xsp
	push xiz
	ld iz, wa
	extz xde
	div xde, xiz
	mul xde, xiz
	ld (xsp + 4), de
	ldiw_erp 0xfa, 0
	cps iz, 0
	jr ule, DialCalc_Return

DialCalc_EventLoop:
	.incbin "includes/generated/v7_transplant_DialCalc_EventLoop.bin"
DialCalc_SetMode12:
	ld xbc, 0x120002
	jr PostEventSetup_Send

DialCalc_SetMode15:
	ld xbc, 0x150002

PostEventSetup_Send:
	.incbin "includes/generated/v7_transplant_PostEventSetup_Send.bin"
DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret
__pad_F6C160:

StylCnvWaitTtlFunc:
	.incbin "includes/generated/v7_transplant_StylCnvWaitTtlFunc.bin"
StylCnvWait_SetStatus:
	.incbin "includes/generated/v7_transplant_StylCnvWait_SetStatus.bin"
StylCnvWait_CheckPending:
	.incbin "includes/generated/v7_transplant_StylCnvWait_CheckPending.bin"
StylCnvWait_HandleClose:
	.incbin "includes/generated/v7_transplant_StylCnvWait_HandleClose.bin"
StylCnvWait_RestoreDisplay:
	calr Display_RestoreEntry

AccChord_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C1DE:

StylCnvTxtTtlFunc:
	cp xbc, 0x1c00007
	jr z, StylCnvTxt_ReturnZero
	cp xbc, 0x1c00013
	jr nz, StylCnvTxt_ReturnZero
	cp xde, 0x3
	jr z, StylCnvTxt_HandleClose
	cp xde, 0x8
	jr z, StylCnvTxt_ReturnZero
	cp xde, 0x2
	jr nz, StylCnvTxt_ReturnZero
	cpib_da (0x0ffc00), 0x05
	jr nz, StylCnvTxt_ReturnZero
	stib_da (0x0ffc00), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvTxt_ReturnZero

StylCnvTxt_HandleClose:
	.incbin "includes/generated/v7_transplant_StylCnvTxt_HandleClose.bin"
StylCnvTxt_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C229:

StylCnvModlTtlFunc:
	.incbin "includes/generated/v7_transplant_StylCnvModlTtlFunc.bin"
StylCnvModl_ScanMatchingModels:
	.incbin "includes/generated/v7_transplant_StylCnvModl_ScanMatchingModels.bin"
StylCnvModl_ScanDone:
	.incbin "includes/generated/v7_transplant_StylCnvModl_ScanDone.bin"
StylCnvModl_PadModelNames:
	.incbin "includes/generated/v7_transplant_StylCnvModl_PadModelNames.bin"
StylCnvModl_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvModl_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xc
	jr nc, StylCnvModl_PadStoreChar
	ldb a, 0x20

StylCnvModl_PadStoreChar:
	ld ix, de
	extz xix
	add xix, xhl
	ld (xix + 1), a
	inc 1, iy
	inc 1, de
	cp iy, 0x14
	jr c, StylCnvModl_PadInnerLoop
	inc 1, iz
	add bc, 0x25
	cp iz, 0x100
	jr c, StylCnvModl_PadOuterLoop

StylCnvModl_InitListDisplay:
	.incbin "includes/generated/v7_transplant_StylCnvModl_InitListDisplay.bin"
StylCnvModl_ClearDisplayBuf:
	.incbin "includes/generated/v7_transplant_StylCnvModl_ClearDisplayBuf.bin"
StylCnvModl_FormatFilename:
	.incbin "includes/generated/v7_transplant_StylCnvModl_FormatFilename.bin"
StylCnvModl_FormatLoop:
	ld bc, iy
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cps a, 0
	jr z, StylCnvModl_DrawListUI
	cp a, 0x5f
	jr nz, StylCnvModl_CheckPercent
	ld (xbc), 0x20
	jr StylCnvModl_FormatNext

StylCnvModl_CheckPercent:
	cp a, 0x25
	jr nz, StylCnvModl_FormatNext
	ld (xbc), 0x2e

StylCnvModl_FormatNext:
	inc 1, iy
	cp iy, 0x20
	jr c, StylCnvModl_FormatLoop
	jr StylCnvModl_DrawListUI

StylCnvModl_CopyDefaultName:
	.incbin "includes/generated/v7_transplant_StylCnvModl_CopyDefaultName.bin"
StylCnvModl_DrawListUI:
	ld xwa, 0x110007
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cps hl, 0
	jrl nz, StylCnvModl_Return

StylCnvModl_WaitForAck:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr z, StylCnvModl_WaitForAck
	jrl StylCnvModl_Return

StylCnvModl_HandleScroll:
	ld bc, wa
	cps wa, 0
	jrl z, StylCnvModl_Return
	ldw wa, 0x14
	jrl StylCnvModl_OK_CallRedraw

StylCnvModl_HandleRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvModl_HandleRedraw.bin"
StylCnvModl_RedrawDone:
	calr Display_RestoreEntry

StylCnvModl_RedrawReturnZero:
	lds wa, 0
	jr StylCnvModl_CallReturnAction

StylCnvModl_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvModl_Return

StylCnvModl_HandleOpenItem:
	lds wa, 0

StylCnvModl_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvModl_Return

StylCnvModl_HandleOK:
	cp xhl, 0xb
	jrl z, StylCnvModl_OK_SelectItem
	cp xhl, 0x84
	jrl z, StylCnvModl_OK_PageDown
	cp xhl, 0x4
	jrl z, StylCnvModl_OK_PageDown
	cp xhl, 0x83
	jrl z, StylCnvModl_OK_ScrollDown
	cp xhl, 0x82
	jrl z, StylCnvModl_OK_ScrollDown
	cp xhl, 0x3
	jrl z, StylCnvModl_OK_ScrollUp
	cp xhl, 0x2
	jrl z, StylCnvModl_OK_ScrollUp
	cp xhl, 0x81
	jr z, StylCnvModl_OK_PageUp
	cp xhl, 0x1
	jr nz, StylCnvModl_OK_LoadSelection

StylCnvModl_OK_PageUp:
	cp de, 0x14
	jr c, StylCnvModl_OK_LoadSelection
	sub de, 0x14

StylCnvModl_OK_StoreSelection:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_StoreSelection.bin"
StylCnvModl_OK_LoadSelection:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_LoadSelection.bin"
StylCnvModl_OK_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_UpdateDisplay.bin"
StylCnvModl_OK_ScrollUp:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_ScrollUp.bin"
StylCnvModl_OK_ScrollDown:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_ScrollDown.bin"
StylCnvModl_OK_PageDown:
	ld bc, de
	add bc, 0x14
	ld hl, wa
	cp bc, wa
	jr nc, StylCnvModl_OK_PageDown_Clamp
	add de, 0x14
	jrl StylCnvModl_OK_StoreSelection

StylCnvModl_OK_PageDown_Clamp:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_PageDown_Clamp.bin"
StylCnvModl_OK_SelectItem:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_SelectItem.bin"
StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	lds32 xwa, 0

StylCnvModl_OK_Select_FillLoop:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_Select_FillLoop.bin"
StylCnvModl_OK_Select_ShowError:
	call UI_PostModeChangeEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_Select_LoadOK:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_Select_LoadOK.bin"
StylCnvModl_OK_Select_AlignSize:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_Select_AlignSize.bin"
StylCnvModl_OK_Select_CompareNames:
	ld ix, iz
	extz xix
	add xix, xhl
	ld de, wa
	add de, iz
	extz xde
	add xde, xbc
	ld e, (xde + 1)
	cp e, (xix)
	jr nz, StylCnvModl_OK_Select_StoreResult
	inc 1, iz
	cp iz, 0x8
	jr c, StylCnvModl_OK_Select_CompareNames

StylCnvModl_OK_Select_StoreResult:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_Select_StoreResult.bin"
StylCnvModl_OK_PageRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvModl_OK_PageRedraw.bin"
StylCnvModl_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvModl_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 36)
	ret
StylCnvModl_End:

StylCnvCnvtTtlFunc:
	.incbin "includes/generated/v7_transplant_StylCnvCnvtTtlFunc.bin"
StylCnvCnvt_ScanMatchingStyles:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_ScanMatchingStyles.bin"
StylCnvCnvt_PadStyleNames:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_PadStyleNames.bin"
StylCnvCnvt_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvCnvt_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xc
	jr nc, StylCnvCnvt_PadStoreChar
	ldb a, 0x20

StylCnvCnvt_PadStoreChar:
	ld ix, de
	extz xix
	add xix, xhl
	ld (xix + 1), a
	inc 1, iy
	inc 1, de
	cp iy, 0x20
	jr c, StylCnvCnvt_PadInnerLoop
	inc 1, iz
	add bc, 0x25
	cp iz, 0x100
	jr c, StylCnvCnvt_PadOuterLoop

StylCnvCnvt_InitListDisplay:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_InitListDisplay.bin"
StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_HandleRedraw.bin"
StylCnvCnvt_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleOpenItem:
	lds wa, 0

StylCnvCnvt_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleOK:
	cp xde, 0xb
	jrl z, StylCnvCnvt_OK_SelectItem
	cp xde, 0x84
	jrl z, StylCnvCnvt_OK_PageDown
	cp xde, 0x4
	jrl z, StylCnvCnvt_OK_PageDown
	cp xde, 0x83
	jrl z, StylCnvCnvt_OK_ScrollDown
	cp xde, 0x82
	jrl z, StylCnvCnvt_OK_ScrollDown
	cp xde, 0x3
	jrl z, StylCnvCnvt_OK_ScrollUp
	cp xde, 0x2
	jrl z, StylCnvCnvt_OK_ScrollUp
	cp xde, 0x81
	jr z, StylCnvCnvt_OK_PageUp
	cp xde, 0x1
	jr nz, StylCnvCnvt_OK_LoadSelection

StylCnvCnvt_OK_PageUp:
	cp hl, 0x14
	jr c, StylCnvCnvt_OK_LoadSelection
	sub hl, 0x14

StylCnvCnvt_OK_StoreSelection:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_StoreSelection.bin"
StylCnvCnvt_OK_LoadSelection:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_LoadSelection.bin"
StylCnvCnvt_OK_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_UpdateDisplay.bin"
StylCnvCnvt_OK_ScrollUp:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_ScrollUp.bin"
StylCnvCnvt_OK_ScrollDown:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_ScrollDown.bin"
StylCnvCnvt_OK_PageDown:
	ld wa, hl
	add wa, 0x14
	ld de, ix
	cp wa, ix
	jr nc, StylCnvCnvt_OK_PageDown_Clamp
	add hl, 0x14
	jrl StylCnvCnvt_OK_StoreSelection

StylCnvCnvt_OK_PageDown_Clamp:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_PageDown_Clamp.bin"
StylCnvCnvt_OK_SelectItem:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_SelectItem.bin"
StylCnvCnvt_OK_Select_WriteStyle:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_Select_WriteStyle.bin"
StylCnvCnvt_OK_Select_Finalize:
	stib_da (0x0ffc00), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_PageRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvCnvt_OK_PageRedraw.bin"
StylCnvCnvt_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvCnvt_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvCnvt_End:

StylCnvSelTtlFunc:
	.incbin "includes/generated/v7_transplant_StylCnvSelTtlFunc.bin"
StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvSel_HandleRedraw.bin"
StylCnvSel_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvSel_Return

StylCnvSel_HandleOpenItem:
	lds wa, 0

StylCnvSel_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvSel_Return

StylCnvSel_HandleOK:
	cp xde, 0xb
	jrl z, StylCnvSel_OK_SelectItem
	cp xde, 0x84
	jrl z, StylCnvSel_OK_PageDown
	cp xde, 0x4
	jrl z, StylCnvSel_OK_PageDown
	cp xde, 0x83
	jrl z, StylCnvSel_OK_ScrollDown
	cp xde, 0x82
	jrl z, StylCnvSel_OK_ScrollDown
	cp xde, 0x3
	jrl z, StylCnvSel_OK_ScrollUp
	cp xde, 0x2
	jrl z, StylCnvSel_OK_ScrollUp
	cp xde, 0x81
	jr z, StylCnvSel_OK_PageUp
	cp xde, 0x1
	jr nz, StylCnvSel_OK_LoadSelection

StylCnvSel_OK_PageUp:
	cp ix, 0x14
	jr c, StylCnvSel_OK_LoadSelection
	sub ix, 0x14

StylCnvSel_OK_StoreSelection:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_StoreSelection.bin"
StylCnvSel_OK_LoadSelection:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_LoadSelection.bin"
StylCnvSel_OK_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_UpdateDisplay.bin"
StylCnvSel_OK_ScrollUp:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_ScrollUp.bin"
StylCnvSel_OK_ScrollDown:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_ScrollDown.bin"
StylCnvSel_OK_PageDown:
	ld wa, ix
	add wa, 0x14
	ld de, bc
	cp wa, bc
	jr nc, StylCnvSel_OK_PageDown_Clamp
	add ix, 0x14
	jrl StylCnvSel_OK_StoreSelection

StylCnvSel_OK_PageDown_Clamp:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_PageDown_Clamp.bin"
StylCnvSel_OK_SelectItem:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_SelectItem.bin"
StylCnvSel_OK_PageRedraw:
	.incbin "includes/generated/v7_transplant_StylCnvSel_OK_PageRedraw.bin"
StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	.incbin "includes/generated/v7_transplant_StylCnvContTtlFunc.bin"
StylCnvCont_CheckPending:
	.incbin "includes/generated/v7_transplant_StylCnvCont_CheckPending.bin"
StylCnvCont_HandleClose:
	.incbin "includes/generated/v7_transplant_StylCnvCont_HandleClose.bin"
StylCnvCont_HandleOK:
	.incbin "includes/generated/v7_transplant_StylCnvCont_HandleOK.bin"
StylCnvCont_NotifyPart:
	lds wa, 1
	call UI_PostPartChangeEvent

AccRhythm_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6CBDE:

StylCnvStorTtlFunc:
	cp xbc, 0x1c00013
	jr nz, StylCnvStor_ReturnZero
	cp xde, 0x3
	jr z, StylCnvStor_HandleClose
	lds32 xhl, 0
	ret

StylCnvStor_HandleClose:
	.incbin "includes/generated/v7_transplant_StylCnvStor_HandleClose.bin"
StylCnvStor_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6CBFE:

MainStylCnvFunc:
	extz de
	ld wa, de
	calr AccBankData_ProcessWithCopy
	lds32 xhl, 0
	ret

StylCnv_ReportErrorAndReturn:
	.incbin "includes/generated/v7_transplant_StylCnv_ReportErrorAndReturn.bin"
FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	.incbin "includes/generated/v7_transplant_StyleConv_DispatchSoundMemState.bin"
StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_CheckFE.bin"
StylCnvDisp_CheckType:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_CheckType.bin"
StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xffc01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_Type2_CheckSubtype.bin"
StylCnvDisp_Subtype10_Process:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_Subtype10_Process.bin"
StylCnvDisp_CopyAndFinalize:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_CopyAndFinalize.bin"
StylCnvDisp_Subtype80_Process:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_Subtype80_Process.bin"
StylCnvDisp_ScanFileLoop:
	.incbin "includes/generated/v7_transplant_StylCnvDisp_ScanFileLoop.bin"
StylCnv_ParseEntry_ScanChar:
	.incbin "includes/generated/v7_transplant_StylCnv_ParseEntry_ScanChar.bin"
StylCnv_ParseEntry_StoreChar:
	.incbin "includes/generated/v7_transplant_StylCnv_ParseEntry_StoreChar.bin"
StylCnv_ParseEntry_NextField:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x80
	jrl lt, StylCnvDisp_ScanFileLoop

StylCnv_ParseEntry_Done:
	.incbin "includes/generated/v7_transplant_StylCnv_ParseEntry_Done.bin"
StylCnv_CopyNameLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_CopyNameLoop.bin"
StylCnv_CopyName_Finalize:
	.incbin "includes/generated/v7_transplant_StylCnv_CopyName_Finalize.bin"
ControlState_Type3:
	.incbin "includes/generated/v7_transplant_ControlState_Type3.bin"
StylCnv_Type4_Init:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_Init.bin"
StylCnv_Type4_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Type4_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Type4_MainLoop:
	cpw (xsp + 4), 0x0
	jr nz, LoopIndex_Reset
	ldw (xsp + 6), 0x0
	cpw (xsp + 4), 0x28
	jr ge, LoopIndex_Reset

StylCnv_Type4_CopyChars:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld c, (xwa)
	cps c, 0
	jr z, LoopIndex_Reset
	ld wa, (xsp + 6)
	lda_dri XHL, 0x07, 0xe8, 0xe0
	incm 1, (xsp + 4)
	incm 1, (xsp + 6)
	cpw (xsp + 4), 0x28
	jr lt, StylCnv_Type4_CopyChars

LoopIndex_Reset:
	ldw (xsp + 6), 0x0

StylCnv_Type4_FindDot:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x2e
	jr z, StylCnv_Type4_CalcExtLen
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type4_FindDot

StylCnv_Type4_CalcExtLen:
	ldw (xsp + 16), 0x0

StylCnv_Type4_CountExt:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x00
	jr z, StylCnv_Type4_CalcCenter
	incm 1, (xsp + 16)
	incm 1, (xsp + 6)
	cpw (xsp + 16), 0x20
	jr lt, StylCnv_Type4_CountExt

StylCnv_Type4_CalcCenter:
	ld wa, (xsp + 16)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	ldiw_erp 0xfa, 1
	cps wa, 0
	jr nz, StylCnv_Type4_CheckNull
	ldiw_erp 0xfa, 2

StylCnv_Type4_CheckNull:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_CheckNull.bin"
StylCnv_Type4_Advance:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jrl lt, StylCnv_Type4_MainLoop

StylCnv_Type4_BuildOutput:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_BuildOutput.bin"
StylCnv_Type4_CopyNameLoop2:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_CopyNameLoop2.bin"
StylCnv_Type4_AppendExt:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_AppendExt.bin"
StylCnv_AppendAndClear:
	.incbin "includes/generated/v7_transplant_StylCnv_AppendAndClear.bin"
StylCnv_ClearAndFinalize:
	stib_da (0x0ffc00), 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	.incbin "includes/generated/v7_transplant_StylCnv_DispatchByType.bin"
StylCnv_Type2_CheckSoundMem:
	.incbin "includes/generated/v7_transplant_StylCnv_Type2_CheckSoundMem.bin"
StylCnv_Type3_ProcessFiles:
	.incbin "includes/generated/v7_transplant_StylCnv_Type3_ProcessFiles.bin"
StylCnv_Type3_SearchLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Type3_SearchLoop.bin"
StylCnv_Type3_SearchNext:
	.incbin "includes/generated/v7_transplant_StylCnv_Type3_SearchNext.bin"
StylCnv_Type3_CheckCount:
	cpw (xsp + 4), 0x0
	jrl z, StylCnv_AbortWithError
	ldw (xsp + 8), 0x0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_Type3_BuildFfcBuffer

StylCnv_Type3_LoadFileLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Type3_LoadFileLoop.bin"
StylCnv_Type3_EmptyName:
	ld (xwa), 0x0

StylCnv_Type3_CloseFile:
	call FileIO_CloseHandle
	incm 1, (xsp + 8)
	ld wa, (xsp + 8)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_LoadFileLoop

StylCnv_Type3_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	stib_da (0x0ffc00), 0xff
	stib_da (0x0ffc01), 0x00
	ldw (xsp + 16), 0x0
	ldiw_erp 0xfa, 0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Type3_CopyBlockLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Type3_CopyBlockLoop.bin"
StylCnv_Type3_CopyNameChars:
	ld wa, iz
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Type3_TerminateName
	stw_erp HL, 0xfa
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc1w_erp 0xfa
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type3_CopyNameChars

StylCnv_Type3_TerminateName:
	stw_erp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa
	ld wa, iz
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Type3_NextBlock
	stw_erp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa

StylCnv_Type3_NextBlock:
	incm 1, (xsp + 16)
	ld wa, (xsp + 16)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type4_OpenFile:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_OpenFile.bin"
FileIO_ErrorExit:
	call FileIO_CloseHandle

StylCnv_AbortWithError:
	calr StylCnv_ReportErrorAndReturn
	jrl StylCnv_Epilogue114

StylCnv_Type4_ClearAndBuild:
	.incbin "includes/generated/v7_transplant_StylCnv_Type4_ClearAndBuild.bin"
StylCnv_Type4_CopyFieldLoop:
	ld bc, (xsp + 4)
	inc 6, bc
	extz xbc
	add xbc, 0xffc00
	ld wa, (xsp + 4)
	inc 1, wa
	ldb_sri A, 0x07, 0xe8, 0xe0
	ld (xbc), a
	cps a, 0
	jrl z, StylCnv_FinalizeAndCheckStatus
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyFieldLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_Dispatch:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_Dispatch.bin"
StylCnv_Type6_ClearRegion:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_ClearRegion.bin"
StylCnv_Type6_MainLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_MainLoop.bin"
StylCnv_Type6_FindDot:
	cpib_sri 0x07, 0xe4, 0xf8, 0x2e
	jr z, StylCnv_Type6_ClearRemainder
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_FindDot

StylCnv_Type6_ClearRemainder:
	cp iz, 0x20
	jr ge, StylCnv_Type6_AppendName

StylCnv_Type6_ClearLoop:
	stib_ind 0x07, 0xe4, 0xf8, 0x00
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_ClearLoop

StylCnv_Type6_AppendName:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_AppendName.bin"
StylCnv_Type6_AdvanceEntry:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_AdvanceEntry.bin"
StylCnv_Type6_BuildFfcBuffer:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_BuildFfcBuffer.bin"
StylCnv_Type6_CopyBlockLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_CopyBlockLoop.bin"
StylCnv_Type6_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Type6_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type6_CopyNameChars

StylCnv_Type6_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Type6_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Type6_NextBlock:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_NextBlock.bin"
StylCnv_Type6_FileReadError:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_FileReadError.bin"
StylCnv_Type6_FileOpenError:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_FileOpenError.bin"
StylCnv_Type6_Case1_CopyName:
	.incbin "includes/generated/v7_transplant_StylCnv_Type6_Case1_CopyName.bin"
StylCnv_Single_FindDot:
	ld bc, (xsp + 4)
	cpib_sri 0x07, 0xe0, 0xe4, 0x2e
	jr z, StylCnv_Single_CopyExtension
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot

StylCnv_Single_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Single_RenameTM

StylCnv_Single_CopyExt_Loop:
	.incbin "includes/generated/v7_transplant_StylCnv_Single_CopyExt_Loop.bin"
StylCnv_Single_RenameTM:
	ldw (xsp + 4), 0x0

StylCnv_Single_FindDot2:
	ld bc, (xsp + 4)
	exts xbc
	add xbc, xwa
	incm 1, (xsp + 4)
	cp (xbc), 0x2e
	jr z, StylCnv_Single_WriteTMExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot2

StylCnv_Single_WriteTMExtension:
	.incbin "includes/generated/v7_transplant_StylCnv_Single_WriteTMExtension.bin"
StylCnv_LSW_FindDot:
	ld wa, (xsp + 4)
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
	jr z, StylCnv_LSW_CopyExtension
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot

StylCnv_LSW_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, DRI_ParseFieldsAndOpenFile

StylCnv_LSW_CopyExt_Loop:
	.incbin "includes/generated/v7_transplant_StylCnv_LSW_CopyExt_Loop.bin"
DRI_ParseFieldsAndOpenFile:
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 18)

StylCnv_LSW_FindDot2:
	ld bc, (xsp + 4)
	exts xbc
	add xbc, xwa
	incm 1, (xsp + 4)
	cp (xbc), 0x2e
	jr z, StylCnv_LSW_WriteExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot2

StylCnv_LSW_WriteExtension:
	.incbin "includes/generated/v7_transplant_StylCnv_LSW_WriteExtension.bin"
StylCnv_LSW_FindDot3:
	ld wa, (xsp + 4)
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
	jr z, StylCnv_LSW_CopyExt3
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot3

StylCnv_LSW_CopyExt3:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, FileLoad_ResetAndStartProcessing

StylCnv_LSW_CopyExt3_Loop:
	.incbin "includes/generated/v7_transplant_StylCnv_LSW_CopyExt3_Loop.bin"
FileLoad_ResetAndStartProcessing:
	calr SoundMem_ClearRegion
	stib_da (0x0ffc00), 0xff
	stib_da (0x0ffc01), 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
	ld wa, (xsp + 8)
	add wa, 0x1
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Final_CopyBlockLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Final_CopyBlockLoop.bin"
StylCnv_Final_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Final_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Final_CopyNameChars

StylCnv_Final_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Final_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Final_NextBlock:
	incm 1, (xsp + 4)
	ld wa, (xsp + 8)
	inc 1, wa
	cp (xsp + 4), wa
	jrl lt, StylCnv_Final_CopyBlockLoop

StylCnv_FinalizeAndCheckStatus:
	calr TableData_JumpToEntry
	jrl StyleConv_DispatchSoundMemState

StylCnv_Multi_InitAndClear:
	.incbin "includes/generated/v7_transplant_StylCnv_Multi_InitAndClear.bin"
StylCnv_Multi_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Multi_ParseLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Multi_ParseLoop.bin"
StylCnv_Multi_HandleSeparator:
	.incbin "includes/generated/v7_transplant_StylCnv_Multi_HandleSeparator.bin"
StylCnv_Multi_ClearSubLoop:
	.incbin "includes/generated/v7_transplant_StylCnv_Multi_ClearSubLoop.bin"
StylCnv_Multi_CopyChar:
	cps iz, 0
	jr le, LoopCounter_Increment
	ld wa, (xsp + 6)
	lda_dri XIY, 0x07, 0xe4, 0xe0
	ld (xhl), 0x0
	incm 1, (xsp + 6)

LoopCounter_Increment:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, 0x200
	jrl c, StylCnv_Multi_ParseLoop

StylCnv_Multi_Finalize:
	ldw wa, 0x15

StylCnv_PostModeChange:
	call UI_PostModeChangeEvent

StylCnv_Epilogue114:
	pop xiz
	lda xsp, (xsp + 114)
	ret

TableData_JumpToEntry:
	ld xhl, 0x80000
	jp (xhl)
AccStyle_TableDataEntry:
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	cpdi8	(0xc07d), 65
	ret	nz
	bitda	0, (0xc07f)
	ret	z
	ldb_d8	c, (0x8d36)
	bitda	0, (0xc07e)
	jr	z, 10
	cp	c, 17
	ret	nz
	ldw	wa, 16
	jr	98
	ldb_d8	a, (0x3d06)
	cp	c, 18
	jr	z, 61
	cp	c, 20
	jr	z, 18
	cp	c, 16
	ret	nz
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ldw	wa, 17
	jr	66
	cps	a, 2
	jr	z, 21
	cps	a, 5
	jr	z, 4
	cps	a, 1
	ret	nz
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	41
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	28
	cps	a, 2
	jr	z, 4
	cps	a, 1
	ret	nz
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ld	xwa, 0x3d08
	call	ControlState_ProcessCommand
	ldw	wa, 18
	call	UI_PostModeChangeEvent
	ret
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+34), c
	ld	(xsp+36), a
	ld	xiy, NakaInst_OFF_Str_0xB6
	lda	xix, (xsp+4)
	ldw	bc, 15
	ldirw
	lda_24	xde, (0x094800)
	lda_24	xbc, (0x0ab000)
	sub	xbc, xde
	ld	xwa, 0x069800
	call	FileIO_ReadBlock
	cp	xhl, 0
	jrl	lt, 731
	lda_24	xbc, (0x069800)
	stda32	0x7ae4, xbc
	lda_24	xwa, (0x094800)
	stda32	0x7ae8, xwa
	stdi8	(0x3950), 0
	ld	a, (xbc)
	ldb_erp	a, 249
	ld	a, (xbc+1)
	ldb_erp	a, 250
	ld	a, (xbc+2)
	ldb_erp	a, 251
	cp_erpb	249, 72
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 38
	cp_erpb	249, 71
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 21
	cp_erpb	249, 76
	jrl	nz, 336
	cp_erpb	250, 75
	jrl	nz, 329
	cp_erpb	251, 69
	jrl	nz, 322
	ldda32	xwa, (0x7ae4)
	ld	(xwa), 72
	ldda32	xwa, (0x7ae4)
	ld	(xwa+1), 0
	ldda32	xwa, (0x7ae4)
	ld	(xwa+2), 75
	ldda32	xbc, (0x7ae8)
	cp	(xsp+36), 29
	jrl	ule, 264
	cp	(xsp+34), 29
	jrl	ule, 257
	ldda32	xwa, (0x7ae4)
	ld	e, (xwa+14)
	cps	e, 0
	jr	nz, 6
	cp	(xwa+15), 0
	jr	z, 13
	ld	(xbc+14), e
	ldda32	xwa, (0x7ae4)
	ld	a, (xwa+15)
	ld	(xbc+15), a
	cp_erpb	249, 72
	jr	nz, 12
	cpib_erp	250, 0
	jr	nz, 7
	cp_erpb	251, 75
	jrl	z, 147
	ld	a, (xsp+36)
	sub	a, 30
	extz	wa
	extz	xwa
	add	xwa, NakaInst_OFF_Str_0x98
	ld	xbc, xwa
	ld	xde, xwa
	ld	xhl, xwa
	ld	xix, xwa
	lda	xiy, (xwa+30)
	ld	a, (xix)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, iz
	ld	(xwa+34), 64
	ld	a, (xhl)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, iz
	ld	(xwa+42), 12
	ld	a, (xde)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, iz
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, iz
	ld	(xwa+58), 64
	inc	3, xix
	inc	3, xhl
	inc	3, xde
	inc	3, xbc
	cp	xbc, xiy
	jr	c, -120
	ld	a, (xsp+36)
	extz	wa
	ld	c, (xsp+34)
	extz	bc
	calr	392
	ldb_d8	a, (0x3950)
	extz	wa
	bit	0, wa
	jrl	z, 357
	ldda32	xwa, (0x7ae8)
	stda32	0x39ae, xwa
	cp	(xsp+34), 30
	jrl	nc, 293
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	jrl	320
	cp	(xsp+36), 29
	jr	ule, 6
	cp	(xsp+34), 30
	jr	c, 12
	cp	(xsp+36), 30
	jr	nc, 14
	cp	(xsp+34), 29
	jr	ule, 8
	stdi8	(0x3950), 130
	jrl	304
	stda32	0x39ae, xbc
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	cp_erpb	249, 72
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 121
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	lda_rr	xbc, xbc, wa
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, de
	ld	(xwa+34), 64
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, de
	ld	(xwa+42), 12
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, de
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ldda32	xwa, (0x7ae4)
	lda_rr	xwa, xwa, bc
	ld	(xwa+58), 64
	ldda32	xwa, (0x7ae4)
	stda32	0x39ae, xwa
	ldda32	xwa, (0x7ae8)
	stda32	0x39b2, xwa
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	.byte 0xac
	push	xbc
	ld	a, (xsp+34)
	extz	wa
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	.byte 0xad
	push	xbc
	resda	0, 0x35b0
	call	DualVoice_ParamLoadDone
	ldb_d8	a, (0x35b0)
	extz	wa
	bit	0, wa
	jr	z, 8
	stdi8	(0x3950), 131
	jrl	-312
	stdi8	(0x3950), 0
	jrl	-320
	ldib_erp	251, 0
	ld	c, (xsp+34)
	sub	c, 30
	extz	bc
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, (NakaInst_OFF_Str_0x98)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -46
	cpdi8	(0x3950), 131
	jr	nz, 5
	ldw	hl, 0xff95
	jr	6
	call	AccPatch_MultiCallWrapper_0x13
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+34)
	ret
	dec	4, xsp
	push qiz
	ld	(xsp+2), c
	ld	(xsp+4), a
	ldda32	xwa, (0x7ae8)
	stda32	0x39ae, xwa
	ldib_erp	251, 0
	ld	c, (xsp+2)
	sub	c, 30
	extz	bc
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, (NakaInst_OFF_Str_0x98)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -46
	ldda32	xwa, (0x7ae4)
	stda32	0x39ae, xwa
	ldda32	xwa, (0x7ae8)
	stda32	0x39b2, xwa
	stdi8	(0x3950), 0
	resda	0, 0x35b0
	ldib_erp	251, 0
	ld	e, (xsp+4)
	sub	e, 30
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda_24	xde, (NakaInst_OFF_Str_0x98)
	.byte 0xc3
	reti
	or	xwa, xwa
	pop_f
	.byte 0xac
	push	xbc
	ld	a, (xsp+2)
	sub	a, 30
	extz	wa
	add	bc, wa
	.byte 0xc3
	reti
	or	xix, xwa
	pop_f
	.byte 0xad
	push	xbc
	call	DualVoice_ParamLoadDone
	ldb_d8	a, (0x35b0)
	extz	wa
	bit	0, wa
	jr	z, 7
	stdi8	(0x3950), 131
	jr	9
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -81
	pop qiz
	inc	4, xsp
	ret

	.include "sequencer/accompseq_routines.s"
