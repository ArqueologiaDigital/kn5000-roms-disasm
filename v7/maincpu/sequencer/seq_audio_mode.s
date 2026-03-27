; =============================================================================
; Sequencer Audio Mode & Accompaniment Processing (2K lines)
; =============================================================================
;
; Audio mode stereo flags, accompaniment pedal processing,
; sequencer timing setup, part activation, and audio flag
; dispatch between SMF event processing and rhythm routines.
; =============================================================================

	ei 0
	stb_d8 (0x31e3), a
	ret

AudioMode_CheckAndUpdateStereo:
	.incbin "includes/generated/v7_transplant_AudioMode_CheckAndUpdateStereo.bin"
AudioMode_ApplyStereoUpdate:
	.incbin "includes/generated/v7_transplant_AudioMode_ApplyStereoUpdate.bin"
AudioMode_CheckDone:
	ret

AudioMode_MergeOutputBits:
	.incbin "includes/generated/v7_transplant_AudioMode_MergeOutputBits.bin"
AudioMode_CopyChannelMode:
	.incbin "includes/generated/v7_transplant_AudioMode_CopyChannelMode.bin"
AudioMode_CopyAccentFlags:
	.incbin "includes/generated/v7_transplant_AudioMode_CopyAccentFlags.bin"
AccPedal_BytecodeBlock1:
	.incbin "includes/generated/v7_transplant_AccPedal_BytecodeBlock1.bin"
AccPedal_SetFlag13155:
	.incbin "includes/generated/v7_transplant_AccPedal_SetFlag13155.bin"
AccPedal_PartOffsetTable:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00

AccPedal_ProcessAllChanges:
	.incbin "includes/generated/v7_transplant_AccPedal_ProcessAllChanges.bin"
AccPedal_CheckBit1Left:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckBit1Left.bin"
AccPedal_CheckBit0Right:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckBit0Right.bin"
AccPedal_CheckBit1Right:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckBit1Right.bin"
AccPedal_CheckBit0Aux:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckBit0Aux.bin"
AccPedal_CheckBit1Aux:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckBit1Aux.bin"
AccPedal_ApplyChangeMask:
	cps a, 0
	jr z, AccPedal_CheckAuxBit2
	ld w, a
	xor w, 0xff
	anddm8 0xfc5f, w
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

AccPedal_CheckAuxBit2:
	.incbin "includes/generated/v7_transplant_AccPedal_CheckAuxBit2.bin"
AccPedal_ClearAllPedalFlags:
	.incbin "includes/generated/v7_transplant_AccPedal_ClearAllPedalFlags.bin"
AccPedal_ReadBankAndReturn:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	.incbin "includes/generated/v7_transplant_AccVoice_ReadBankAssign.bin"
AccVoice_StoreBankAssign:
	.incbin "includes/generated/v7_transplant_AccVoice_StoreBankAssign.bin"
AccChannel_CompareAndMarkDirty:
	.incbin "includes/generated/v7_transplant_AccChannel_CompareAndMarkDirty.bin"
AccChannel_MarkDirtyAndSync:
	.incbin "includes/generated/v7_transplant_AccChannel_MarkDirtyAndSync.bin"
AccChannel_StoreCurrentState:
	.incbin "includes/generated/v7_transplant_AccChannel_StoreCurrentState.bin"
AccChannel_BytecodeBlock2:
	.incbin "includes/generated/v7_transplant_AccChannel_BytecodeBlock2.bin"
AccChannel_SetDirtyIfActive:
	.incbin "includes/generated/v7_transplant_AccChannel_SetDirtyIfActive.bin"
AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	.incbin "includes/generated/v7_transplant_AccChannel_CheckActivitySetDirty.bin"
AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	.incbin "includes/generated/v7_transplant_AccChannel_CheckPartIndexDirty.bin"
AccChannel_PartIndexDone:
	ret

AccVoice_ProcessPedalChanges:
	.incbin "includes/generated/v7_transplant_AccVoice_ProcessPedalChanges.bin"
AccVoice_Pedal0_SetAndCheck:
	.incbin "includes/generated/v7_transplant_AccVoice_Pedal0_SetAndCheck.bin"
AccVoice_Pedal0_Done:
	.incbin "includes/generated/v7_transplant_AccVoice_Pedal0_Done.bin"
AccVoice_Pedal1_SetAndCheck:
	.incbin "includes/generated/v7_transplant_AccVoice_Pedal1_SetAndCheck.bin"
AccVoice_Pedal1_Done:
	.incbin "includes/generated/v7_transplant_AccVoice_Pedal1_Done.bin"
AccVoice_Pedal2_SetAndCheck:
	.incbin "includes/generated/v7_transplant_AccVoice_Pedal2_SetAndCheck.bin"
AccVoice_Pedal2_Done:
	ret

AccVoice_ProcessLeftPedalChanges:
	.incbin "includes/generated/v7_transplant_AccVoice_ProcessLeftPedalChanges.bin"
AccVoice_LeftPedal0_SetAndCheck:
	.incbin "includes/generated/v7_transplant_AccVoice_LeftPedal0_SetAndCheck.bin"
AccVoice_LeftPedal0_Done:
	.incbin "includes/generated/v7_transplant_AccVoice_LeftPedal0_Done.bin"
AccVoice_LeftPedal1_SetAndCheck:
	.incbin "includes/generated/v7_transplant_AccVoice_LeftPedal1_SetAndCheck.bin"
AccVoice_LeftPedal1_Done:
	ret

AccVoice_CheckChannelSetActive:
	.incbin "includes/generated/v7_transplant_AccVoice_CheckChannelSetActive.bin"
AccVoice_ChannelActiveDone:
	ret

AccVoice_CheckBitsAndSetFlags:
	.incbin "includes/generated/v7_transplant_AccVoice_CheckBitsAndSetFlags.bin"
AccVoice_BitsCheckDone:
	ret

AccPitch_CheckTransposeFlags:
	.incbin "includes/generated/v7_transplant_AccPitch_CheckTransposeFlags.bin"
AccPitch_UpdateCheck:
	.incbin "includes/generated/v7_transplant_AccPitch_UpdateCheck.bin"
AccPitch_FinalReturn:
	ret

AccChord_ProcessKeyChanges:
	.incbin "includes/generated/v7_transplant_AccChord_ProcessKeyChanges.bin"
AccChord_KeyChange0_Done:
	.incbin "includes/generated/v7_transplant_AccChord_KeyChange0_Done.bin"
AccChord_KeyChange1_Done:
	ret

AccChord_ResolveVoiceAndDispatch:
	.incbin "includes/generated/v7_transplant_AccChord_ResolveVoiceAndDispatch.bin"
AccChord_CheckRange:
	.incbin "includes/generated/v7_transplant_AccChord_CheckRange.bin"
AccChord_MaskAndContinue:
	and a, 0x7f

AccChord_DispatchVoiceChange:
	.incbin "includes/generated/v7_transplant_AccChord_DispatchVoiceChange.bin"
AccChord_CheckVoiceBit2:
	.incbin "includes/generated/v7_transplant_AccChord_CheckVoiceBit2.bin"
AccChord_CheckLeftPedal0:
	.incbin "includes/generated/v7_transplant_AccChord_CheckLeftPedal0.bin"
AccChord_CheckLeftPedal1:
	.incbin "includes/generated/v7_transplant_AccChord_CheckLeftPedal1.bin"
AccChord_CheckKeyChange0:
	.incbin "includes/generated/v7_transplant_AccChord_CheckKeyChange0.bin"
RhythmPart_ProcessBit0:
	.incbin "includes/generated/v7_transplant_RhythmPart_ProcessBit0.bin"
RhythmPart_ProcessBit1:
	cps a, 0
	jr z, AccChord_CheckExtraDirtyBit3
	ldb w, 0x0
	xor a, 0xff
	anddm8 0xfc5f, a
	ldb a, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckExtraDirtyBit3:
	.incbin "includes/generated/v7_transplant_AccChord_CheckExtraDirtyBit3.bin"
AccChord_CheckPitchDirty:
	.incbin "includes/generated/v7_transplant_AccChord_CheckPitchDirty.bin"
AccChord_CheckPitchLeftPedal1:
	.incbin "includes/generated/v7_transplant_AccChord_CheckPitchLeftPedal1.bin"
AccChord_NullRet:
	ret

AccChord_CompareAndSetDirty:
	.incbin "includes/generated/v7_transplant_AccChord_CompareAndSetDirty.bin"
AccChord_SetDirtyBit5:
	.incbin "includes/generated/v7_transplant_AccChord_SetDirtyBit5.bin"
AccChord_CheckZeroChord:
	.incbin "includes/generated/v7_transplant_AccChord_CheckZeroChord.bin"
AccChord_CompareDone:
	ret

AccentVoice_DetectAndMarkChange:
	.incbin "includes/generated/v7_transplant_AccentVoice_DetectAndMarkChange.bin"
AccentVoice_CheckModeChange:
	.incbin "includes/generated/v7_transplant_AccentVoice_CheckModeChange.bin"
AccentVoice_UpdateParamIndex:
	.incbin "includes/generated/v7_transplant_AccentVoice_UpdateParamIndex.bin"
AccVoice_ResolveParamAddr:
	push xwa
	push xix
	ld xiy, RhythmTiming_OffsetTable
	cp a, 0x1d
	jr ule, AccVoice_ComputeParamOffset
	xor a, a

AccVoice_ComputeParamOffset:
	.incbin "includes/generated/v7_transplant_AccVoice_ComputeParamOffset.bin"
AccVoice_PartOffsetTable2:
	.byte 0x00, 0x48, 0x09, 0x00, 0x00, 0x00, 0x30, 0x00
	.byte 0x00, 0x98, 0x31, 0x00, 0x00, 0x00, 0x33, 0x00
	.byte 0x00, 0x98, 0x34, 0x00, 0x00, 0x00, 0x36, 0x00
	.byte 0x00, 0x98, 0x37, 0x00, 0x00, 0x00, 0x39, 0x00

AccVoice_ComputeChannelIndex:
	and h, 0x7
	sla h, 1
	xor w, w
	sla wa, 2
	xor l, l
	add hl, wa
	ld xiy, Display_FontPalette_Table_0x2EA
	ldw_sri WA, 0x07, 0xf4, 0xec
	add hl, 0x2
	ldw_sri IY, 0x07, 0xf4, 0xec
	ret

AccVoice_LookupWithOffset:
	calr AccVoice_ComputeChannelIndex
	call AccVoice_TableLookup_Inner
	extz xiy
	add xhl, xiy
	ld xiy, xhl
	ret

AccVoice_SelectAndApplyPatch:
	.incbin "includes/generated/v7_transplant_AccVoice_SelectAndApplyPatch.bin"
AccVoice_PatchFromDirect:
	.incbin "includes/generated/v7_transplant_AccVoice_PatchFromDirect.bin"
AccVoice_StorePatchAndLookup:
	.incbin "includes/generated/v7_transplant_AccVoice_StorePatchAndLookup.bin"
AccStyle_ReadVoiceParam:
	ldb_sri0 W, (xiy + 0x03da)
	ldb_sri0 A, (xiy + 0x03d0)
	ld xhl, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

; ============================================================================
; AccPatch_SetVoiceParam - Set accompaniment voice parameter
; ============================================================================
; Clamps register A to <= 0x1d (29 voices), then indexes into table at
; 0xe46b8a to set a voice parameter. Called 148+ times, typically in
; rapid bursts during accompaniment patch configuration.
; ============================================================================
AccPatch_SetVoiceParam:
	cp a, 0x1d
	jr ule, AccPatch_ClampedSetParam
	xor a, a

AccPatch_ClampedSetParam:
	ld w, a
	calr AccVoice_ResolveParamAddr
	ld a, (xiy + 12)
	ld xhl, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

AccVoice_LoadTuningBlock:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadTuningBlock.bin"
AccTuning_CopyAllPartsFromStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_CopyAllPartsFromStyle.bin"
AccTuning_LoadAndApplyMaster:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadAndApplyMaster.bin"
AccTuning_LoadCoarseFromStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadCoarseFromStyle.bin"
AccTuning_LoadFineFromStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadFineFromStyle.bin"
AccTuning_LoadOctaveFromStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadOctaveFromStyle.bin"
AccTuning_LoadTransposeFromStyle:
	.incbin "includes/generated/v7_transplant_AccTuning_LoadTransposeFromStyle.bin"
Rhythm_ProcessAllPartsAndLoad:
	.incbin "includes/generated/v7_transplant_Rhythm_ProcessAllPartsAndLoad.bin"
Rhythm_ProcessAllDone:
	ret

RhythmPart_CopyData:
	.incbin "includes/generated/v7_transplant_RhythmPart_CopyData.bin"
RhythmPart1_ProcessAccentData:
	.incbin "includes/generated/v7_transplant_RhythmPart1_ProcessAccentData.bin"
RhythmPart1_CheckAccentData:
	.incbin "includes/generated/v7_transplant_RhythmPart1_CheckAccentData.bin"
RhythmPart1_ProcessRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmPart1_ProcessRingBuf.bin"
RhythmPart1_WriteDone:
	.incbin "includes/generated/v7_transplant_RhythmPart1_WriteDone.bin"
RhythmAccent_CopyAndUpdateRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmAccent_CopyAndUpdateRingBuf.bin"
RhythmAccent_UpdateRingBufPosition:
	.incbin "includes/generated/v7_transplant_RhythmAccent_UpdateRingBufPosition.bin"
RhythmAccent_StorePosition:
	.incbin "includes/generated/v7_transplant_RhythmAccent_StorePosition.bin"
RhythmAccent_AddAndCompare:
	.incbin "includes/generated/v7_transplant_RhythmAccent_AddAndCompare.bin"
RhythmAccent_UpdateDone:
	ei 0
	ret

; ============================================================================
; RingBuf_AdvanceIndex - Advance circular buffer index with wraparound
; ============================================================================
; Input:  IY = current index, BC = limit, XHL+256 = reset value
; Output: IY = incremented index (wrapped if >= limit)
; Called 110+ times, typically in bursts of 5-7 sequential calls while
; storing/loading data parameters through the ring buffer.
; ============================================================================
RingBuf_AdvanceIndex:
	add iy, 0x1
	cp iy, bc
	jr ule, RingBuf_IndexOK
	ld iy, (xhl + 256)

RingBuf_IndexOK:
	ret

RhythmPart2_ProcessAccentData:
	.incbin "includes/generated/v7_transplant_RhythmPart2_ProcessAccentData.bin"
RhythmPart2_LoadAndStore:
	.incbin "includes/generated/v7_transplant_RhythmPart2_LoadAndStore.bin"
RhythmPart2_ProcessRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmPart2_ProcessRingBuf.bin"
RhythmPart2_WriteDone:
	.incbin "includes/generated/v7_transplant_RhythmPart2_WriteDone.bin"
AccVoiceReg_StoreParamRecord:
	.incbin "includes/generated/v7_transplant_AccVoiceReg_StoreParamRecord.bin"
Rhythm_PackVelocityHighBit:
	bit 7, e
	jr z, Rhythm_VelocityPackDone
	or d, 0x10
	and e, 0x7f

Rhythm_VelocityPackDone:
	ret

AccVoice_LoadRhythmParams_Part3:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadRhythmParams_Part3.bin"
RhythmPart3_LoadAndStore:
	.incbin "includes/generated/v7_transplant_RhythmPart3_LoadAndStore.bin"
RhythmPart3_ProcessRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmPart3_ProcessRingBuf.bin"
RhythmPart3_WriteDone:
	.incbin "includes/generated/v7_transplant_RhythmPart3_WriteDone.bin"
AccVoice_LoadRhythmParams_Part4:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadRhythmParams_Part4.bin"
RhythmPart4_LoadAndStore:
	.incbin "includes/generated/v7_transplant_RhythmPart4_LoadAndStore.bin"
RhythmPart4_ProcessRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmPart4_ProcessRingBuf.bin"
RhythmPart4_WriteDone:
	.incbin "includes/generated/v7_transplant_RhythmPart4_WriteDone.bin"
AccVoice_LoadRhythmParams_Part5:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadRhythmParams_Part5.bin"
RhythmPart5_LoadAndStore:
	.incbin "includes/generated/v7_transplant_RhythmPart5_LoadAndStore.bin"
RhythmPart5_ProcessRingBuf:
	.incbin "includes/generated/v7_transplant_RhythmPart5_ProcessRingBuf.bin"
RhythmPart5_WriteDone:
	.incbin "includes/generated/v7_transplant_RhythmPart5_WriteDone.bin"
AccompVoice_BulkReadRegisters:
	.incbin "includes/generated/v7_transplant_AccompVoice_BulkReadRegisters.bin"
BulkRead_Loop1_6Byte:
	.incbin "includes/generated/v7_transplant_BulkRead_Loop1_6Byte.bin"
BulkRead_Loop2_6Byte:
	.incbin "includes/generated/v7_transplant_BulkRead_Loop2_6Byte.bin"
BulkRead_Loop3_9Byte:
	.incbin "includes/generated/v7_transplant_BulkRead_Loop3_9Byte.bin"
BulkRead_Loop4_9Byte:
	.incbin "includes/generated/v7_transplant_BulkRead_Loop4_9Byte.bin"
BulkRead_Loop5_9Byte:
	.incbin "includes/generated/v7_transplant_BulkRead_Loop5_9Byte.bin"
BulkRead_Loop6_9Byte:
	lda_dri XBC, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop6_9Byte
	ret

Rhythm_SendNoteOnMax:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x7f
	calr Rhythm_Send3ByteMsg
	ret

Rhythm_Send3ByteMsg:
	.incbin "includes/generated/v7_transplant_Rhythm_Send3ByteMsg.bin"
Rhythm_SendChanPressure:
	.incbin "includes/generated/v7_transplant_Rhythm_SendChanPressure.bin"
AccBuf_ResetAndReload:
	call AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	call AccStyle_InitVRAM_Wrap
	ret

AccVoice_LoadAllChannelParams:
	.incbin "includes/generated/v7_transplant_AccVoice_LoadAllChannelParams.bin"
VoiceParams_LoadFiveSequential:
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ret

AccVoice_BytecodeBlock3:
	.incbin "includes/generated/v7_transplant_AccVoice_BytecodeBlock3.bin"
RhythmROM_CheckValid:
	.incbin "includes/generated/v7_transplant_RhythmROM_CheckValid.bin"
RhythmROM_InvalidIncrement:
	.incbin "includes/generated/v7_transplant_RhythmROM_InvalidIncrement.bin"
RhythmROM_CheckDone:
	ret

RhythmROM_BytecodeBlock4:
	.incbin "includes/generated/v7_transplant_RhythmROM_BytecodeBlock4.bin"
AccentData_ComparePart1:
	.incbin "includes/generated/v7_transplant_AccentData_ComparePart1.bin"
AccentData_Part1_Done:
	ret

AccentData_ComparePart2:
	.incbin "includes/generated/v7_transplant_AccentData_ComparePart2.bin"
AccentData_Part2_Done:
	ret

AccentData_ComparePart3:
	.incbin "includes/generated/v7_transplant_AccentData_ComparePart3.bin"
AccentData_Part3_Done:
	ret

AccentData_ComparePart4:
	.incbin "includes/generated/v7_transplant_AccentData_ComparePart4.bin"
AccentData_Part4_Done:
	ret

AccentData_ComparePart5:
	.incbin "includes/generated/v7_transplant_AccentData_ComparePart5.bin"
AccentData_Part5_Done:
	ret

RhythmROM_ValidateHeader:
	.incbin "includes/generated/v7_transplant_RhythmROM_ValidateHeader.bin"
AccChord_CheckFailed:
	.incbin "includes/generated/v7_transplant_AccChord_CheckFailed.bin"
RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	.incbin "includes/generated/v7_transplant_AccPatch_SetByChordIndex.bin"
AccPatch_ChIdx0_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx0_Bank1.bin"
AccPatch_ChIdx0_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx0_Bank2.bin"
AccPatch_ChIdx1_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx1_Entry.bin"
AccPatch_ChIdx1_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx1_Bank1.bin"
AccPatch_ChIdx1_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx1_Bank2.bin"
AccPatch_ChIdx2_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx2_Entry.bin"
AccPatch_ChIdx2_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx2_Bank1.bin"
AccPatch_ChIdx2_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx2_Bank2.bin"
AccPatch_ChIdx3_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx3_Entry.bin"
AccPatch_ChIdx3_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx3_Bank1.bin"
AccPatch_ChIdx3_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx3_Bank2.bin"
AccPatch_ChIdx4_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx4_Entry.bin"
AccPatch_ChIdx4_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx4_Bank1.bin"
AccPatch_ChIdx4_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx4_Bank2.bin"
AccPatch_ChIdx5_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx5_Entry.bin"
AccPatch_ChIdx5_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx5_Bank1.bin"
AccPatch_ChIdx5_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx5_Bank2.bin"
AccPatch_ChIdx6_Entry:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx6_Entry.bin"
AccPatch_ChIdx6_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx6_Bank1.bin"
AccPatch_ChIdx6_Bank2:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdx6_Bank2.bin"
AccPatch_ChIdxDefault_Bank0:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdxDefault_Bank0.bin"
AccPatch_ChIdxDefault_Bank1:
	.incbin "includes/generated/v7_transplant_AccPatch_ChIdxDefault_Bank1.bin"
AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
