; =============================================================================
; Accompaniment Sequencer
; =============================================================================
;
; Accompaniment sequencer periodic processing. Handles real-time
; accompaniment playback, manual MIDI mode, and fade-out timing.
; =============================================================================

AccompSeq_PeriodicEntry:
	jp AccompSeq_PeriodicMain

AccompSeq_ManualMidiEntry2:
	jp AccompSeq_ManualMidiMode2

AccompSeq_ManualMidiEntry1:
	jp AccompSeq_ManualMidiMode1

AccompSeq_PeriodicMain:
	.incbin "includes/generated/v7_transplant_AccompSeq_PeriodicMain.bin"
AccompSeq_PeriodicReturn:
	ret

AccompSeq_CaptureTimerState:
	jr AccompSeq_ReadTimerRegisters

AccompSeq_ReadTimerRegisters:
	.incbin "includes/generated/v7_transplant_AccompSeq_ReadTimerRegisters.bin"
AccompSeq_SaveTimerSnapshot:
	.incbin "includes/generated/v7_transplant_AccompSeq_SaveTimerSnapshot.bin"
AccompSeq_CheckChannelActive:
	.incbin "includes/generated/v7_transplant_AccompSeq_CheckChannelActive.bin"
AccompSeq_SetupChannel1:
	.incbin "includes/generated/v7_transplant_AccompSeq_SetupChannel1.bin"
AccompSeq_SetupChannel2:
	.incbin "includes/generated/v7_transplant_AccompSeq_SetupChannel2.bin"
AccompSeq_ChannelSetupDone:
	ret

AccompSeq_IncrementTickCounter:
	ldw_d16	hl, (1128)
	ldb_d8	a, (1130)
	inc	1, a
	cp	a, 96
	jr	nz, 4
	xor	a, a
	inc	1, hl
	stda16	(1128), hl
	stb_d8	(1130), a
	incdi8	1, (1132)
	call	SeqEvt_EntryPoint1
	call	SeqEvt_EntryPoint2
	ret

AccompSeq_InitEventDispatch:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitEventDispatch.bin"
AccompSeq_EventDispatchLoop:
	.incbin "includes/generated/v7_transplant_AccompSeq_EventDispatchLoop.bin"
AccompSeq_DispatchByOpcode:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x84
	jr nz, AccompSeq_CheckLoopMarker
	calr AccompSeq_UpdatePosition
	jr AccompSeq_EventDispatchLoop

AccompSeq_CheckLoopMarker:
	cp a, 0x83
	jr nz, AccompSeq_CheckTimedOpcodes
	calr AccompSeq_HandlePartTransition
	jr AccompSeq_EventDispatchLoop

AccompSeq_CheckTimedOpcodes:
	cp a, 0x81
	jr z, AccompSeq_HandleEndMarker
	cp a, 0x90
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0x91
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd2
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd1
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd3
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd4
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd5
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xd7
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xc0
	jr z, AccompSeq_ProcessTimedEvent
	calr AccompSeq_AdvancePosition
	jr AccompSeq_EventDispatchLoop

AccompSeq_ProcessTimedEvent:
	calr AccompSeq_CheckPatternEnd
	call AccompSeq_CalcDeltaTime
	cp a, 0x18
	jr ugt, AccompSeq_SetTimePending
	calr AccompSeq_ParseEvents
	jr AccompSeq_EventDispatchLoop

AccompSeq_SetTimePending:
	.incbin "includes/generated/v7_transplant_AccompSeq_SetTimePending.bin"
AccompSeq_HandleEndMarker:
	.incbin "includes/generated/v7_transplant_AccompSeq_HandleEndMarker.bin"
AccompSeq_EndMarkerCalcTime:
	.incbin "includes/generated/v7_transplant_AccompSeq_EndMarkerCalcTime.bin"
AccompSeq_EndMarkerAdvance:
	.incbin "includes/generated/v7_transplant_AccompSeq_EndMarkerAdvance.bin"
AccompSeq_EventDispatchDone:
	ret

AccompSeq_CheckPatternEnd:
	push xiy
	calr ResolveVRAMAddressForVoice
	ld a, (xiy + 1)
	cp a, 0x87
	jr nz, AccompSeq_PatternEndReturn
	calr AccompSeq_ReadBeatHeader
	ldw_erp WA, 0xe2
	lds wa, 6
	calr AccompSeq_BuildVRAMAddr
	ld a, (xiy)

AccompSeq_PatternEndReturn:
	pop xiy
	ret

; ============================================================================
; AccompSeq_AdvancePosition - Advance the accompaniment sequencer position
; ============================================================================
; Input:  None (reads from sequencer state at 32322-32324)
; Output: None (updates position counters)
; Increments the tick counter (32324). On tick overflow (wrap to 0),
; increments the beat counter (32322). Checks for pattern end marker
; (0x87) and handles looping by resetting position via sub-calls.
; ============================================================================
AccompSeq_AdvancePosition:
	.incbin "includes/generated/v7_transplant_AccompSeq_AdvancePosition.bin"
AccompSeq_AdvanceCheckPattern:
	.incbin "includes/generated/v7_transplant_AccompSeq_AdvanceCheckPattern.bin"
AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	.incbin "includes/generated/v7_transplant_AccompSeq_VRAMHelperData.bin"
ResolveVRAMAddressForVoice:
	.incbin "includes/generated/v7_transplant_ResolveVRAMAddressForVoice.bin"
AccompSeq_ResolveVRAMFallback:
	.incbin "includes/generated/v7_transplant_AccompSeq_ResolveVRAMFallback.bin"
AccompSeq_ResolveVRAMDone:
	ret

AccompSeq_BuildVRAMAddr:
	push xhl
	ld xhl, xwa
	stw_erp WA, 0xe2
	and xwa, 0xfff
	sla xwa, 8
	ld xiy, xwa
	ld wa, hl
	and xwa, 0xff
	add xiy, xwa
	add xiy, 0x1e8b00
	pop xhl
	ret

AccompSeq_ReadBeatHeader:
	.incbin "includes/generated/v7_transplant_AccompSeq_ReadBeatHeader.bin"
AccompSeq_ReadPatternTimeSig:
	.incbin "includes/generated/v7_transplant_AccompSeq_ReadPatternTimeSig.bin"
AccompSeq_HandlePartTransition:
	.incbin "includes/generated/v7_transplant_AccompSeq_HandlePartTransition.bin"
AccompSeq_TransitionChannel2:
	.incbin "includes/generated/v7_transplant_AccompSeq_TransitionChannel2.bin"
AccompSeq_PartTransitionDone:
	jr AccompSeq_DispatchReturn

AccompSeq_StopPart:
	.incbin "includes/generated/v7_transplant_AccompSeq_StopPart.bin"
AccompSeq_StopPartCh2:
	.incbin "includes/generated/v7_transplant_AccompSeq_StopPartCh2.bin"
AccompSeq_CheckRestart:
	.incbin "includes/generated/v7_transplant_AccompSeq_CheckRestart.bin"
AccompSeq_DispatchReturn:
	ret

AccompSeq_CalcDeltaTime:
	.incbin "includes/generated/v7_transplant_AccompSeq_CalcDeltaTime.bin"
AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	.incbin "includes/generated/v7_transplant_AccompSeq_DeltaCompare.bin"
AccompSeq_DeltaOneAhead:
	.incbin "includes/generated/v7_transplant_AccompSeq_DeltaOneAhead.bin"
AccompSeq_DeltaFarBehind:
	xor a, a

AccompSeq_DeltaReturn:
	ret

AccompSeq_ParseEvents:
	cps a, 0
	jr nz, AccompSeq_ParseLoop
	ldb a, 0x1

AccompSeq_ParseLoop:
	ld e, a
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x90
	jr z, AccompSeq_Parse_Type90
	cp a, 0x91
	jr z, AccompSeq_Parse_Type91
	cp a, 0xc0
	jr z, AccompSeq_Parse_TypeC0
	jr AccompSeq_Parse_Fallthrough

AccompSeq_Parse_Type91:
	jp AccompSeq_Parse_Type91_Impl

AccompSeq_Parse_TypeC0:
	jp AccompSeq_Parse_TypeC0_Impl

AccompSeq_Parse_Type90:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_Type90.bin"
AccompSeq_Parse_Type90_Large:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_Type90_Large.bin"
AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_Type91_Impl.bin"
AccompSeq_Parse_Type91_CalcSize:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_Type91_CalcSize.bin"
AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_Fallthrough.bin"
AccompSeq_Parse_TypeC0_CalcSize:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_TypeC0_CalcSize.bin"
AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_TypeC0_Impl.bin"
AccompSeq_Parse_TypeC0_Finalize:
	.incbin "includes/generated/v7_transplant_AccompSeq_Parse_TypeC0_Finalize.bin"
AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	.incbin "includes/generated/v7_transplant_AccompSeq_ReadParams.bin"
AccompSeq_CalcEventSize:
	.incbin "includes/generated/v7_transplant_AccompSeq_CalcEventSize.bin"
AccompSeq_CalcSize_Negative:
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	sub wa, (xhl + 4)
	add wa, (xhl + 6)
	jr AccompSeq_CalcSize_Store

AccompSeq_CalcSize_Positive:
	sub wa, (xhl + 4)

AccompSeq_CalcSize_Store:
	.incbin "includes/generated/v7_transplant_AccompSeq_CalcSize_Store.bin"
AccompSeq_ResetCounters:
	.incbin "includes/generated/v7_transplant_AccompSeq_ResetCounters.bin"
AccompSeq_InlineCodeBlock:
	.incbin "includes/generated/v7_transplant_AccompSeq_InlineCodeBlock.bin"
AccompSeq_ProcessNoteOn6:
	.incbin "includes/generated/v7_transplant_AccompSeq_ProcessNoteOn6.bin"
AccompSeq_NoteOn6_VelClamp:
	.incbin "includes/generated/v7_transplant_AccompSeq_NoteOn6_VelClamp.bin"
AccompSeq_ProcessNoteOn8:
	.incbin "includes/generated/v7_transplant_AccompSeq_ProcessNoteOn8.bin"
AccompSeq_NoteOn8_VelClamp:
	.incbin "includes/generated/v7_transplant_AccompSeq_NoteOn8_VelClamp.bin"
AccompSeq_ProcessNotePorta:
	.incbin "includes/generated/v7_transplant_AccompSeq_ProcessNotePorta.bin"
AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	.incbin "includes/generated/v7_transplant_AccompSeq_ProcessNoteOn5.bin"
AccompSeq_NoteOn5_StoreProgram:
	.incbin "includes/generated/v7_transplant_AccompSeq_NoteOn5_StoreProgram.bin"
AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	.incbin "includes/generated/v7_transplant_AccompSeq_ResolveChannel.bin"
AccompSeq_ResolveCh_Store:
	.incbin "includes/generated/v7_transplant_AccompSeq_ResolveCh_Store.bin"
AccompSeq_ResolveCh_AddOffset:
	.incbin "includes/generated/v7_transplant_AccompSeq_ResolveCh_AddOffset.bin"
AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	.incbin "includes/generated/v7_transplant_AccompSeq_CheckVelocityFlags.bin"
AccompSeq_VelFlags_CheckProgram:
	.incbin "includes/generated/v7_transplant_AccompSeq_VelFlags_CheckProgram.bin"
AccompSeq_VelFlags_CallDispatch:
	pop xiy
	push xde
	push xhl
	push xiy
	call Rhythm_TransposeWithMod_Tramp
	pop xiy
	pop xhl
	pop xde
	ret

AccompSeq_CheckVelFlagsExtended:
	.incbin "includes/generated/v7_transplant_AccompSeq_CheckVelFlagsExtended.bin"
AccompSeq_ExtVelFlags_CheckProg:
	.incbin "includes/generated/v7_transplant_AccompSeq_ExtVelFlags_CheckProg.bin"
AccompSeq_ExtVelFlags_Dispatch:
	pop xiy
	push xde
	push xhl
	push xiy
	call Rhythm_TransposeWithMod_Tramp
	pop xiy
	pop xhl
	pop xde
	ret

AccompSeq_AdvanceBufferPtr:
	inc 1, iy
	cp iy, bc
	jr ule, AccompSeq_AdvanceBuf_Return
	ld iy, (xhl + 256)

AccompSeq_AdvanceBuf_Return:
	ret

AccompSeq_FadeOutTick:
	.incbin "includes/generated/v7_transplant_AccompSeq_FadeOutTick.bin"
AccompSeq_FadeOut_Active:
	.incbin "includes/generated/v7_transplant_AccompSeq_FadeOut_Active.bin"
AccompSeq_FadeOut_Periodic:
	and wa, 0x7
	cps wa, 0
	jr nz, AccompSeq_FadeOut_Return
	call AccompSeq_FadeOutApplyVol

AccompSeq_FadeOut_Return:
	ret

AccompSeq_FadeOutApplyVol:
	.incbin "includes/generated/v7_transplant_AccompSeq_FadeOutApplyVol.bin"
AccompSeq_FadeOut_Ch2Volume:
	.incbin "includes/generated/v7_transplant_AccompSeq_FadeOut_Ch2Volume.bin"
AccompSeq_FadeOut_ChReturn:
	ret

AccompSeq_PortaFadeOut:
	.incbin "includes/generated/v7_transplant_AccompSeq_PortaFadeOut.bin"
AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	.incbin "includes/generated/v7_transplant_AccompSeq_ManualMidiMode1.bin"
AccompSeq_ManualMidiMode2:
	.incbin "includes/generated/v7_transplant_AccompSeq_ManualMidiMode2.bin"
AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7f
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cps h, 3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	.incbin "includes/generated/v7_transplant_AccompSeq_ManualMidi_SaveAndCall.bin"
AccompSeq_ManualMidi_SetChannel:
	.incbin "includes/generated/v7_transplant_AccompSeq_ManualMidi_SetChannel.bin"
AccompSeq_ManualMidi_ClearFlags:
	.incbin "includes/generated/v7_transplant_AccompSeq_ManualMidi_ClearFlags.bin"
AccompSeq_LargeCodeBlock1:
	.incbin "includes/generated/v7_transplant_AccompSeq_LargeCodeBlock1.bin"
AccompSeq_UpdatePosition:
	.incbin "includes/generated/v7_transplant_AccompSeq_UpdatePosition.bin"
AccompSeq_UpdatePos_Part2:
	.incbin "includes/generated/v7_transplant_AccompSeq_UpdatePos_Part2.bin"
AccompSeq_UpdatePos_Store:
	.incbin "includes/generated/v7_transplant_AccompSeq_UpdatePos_Store.bin"
AccompSeq_JumpTable:
	jp	AccompSeq_LargeCodeBlock2_0x4
	jp	AccompSeq_WriteMidi_CodeBlock_0xA
	jp	AccompSeq_GuardedNoteOff

AccompSeq_StopSequence:
	push xiz
	call AccompSeq_CleanupSequence
	pop xiz
	ret

AccompSeq_SendMidiEvent:
	jp AccompSeq_WriteMidiToBuffer

AccompSeq_AllNotesOff:
	jp AccompSeq_AllNotesOffImpl

AccompSeq_ProcessAfterNote:
	jp AccompSeq_PostNoteProcess
AccompSeq_LargeCodeBlock2:
	.incbin "includes/generated/v7_transplant_AccompSeq_LargeCodeBlock2.bin"
AccompSeq_PostNoteProcess:
	.incbin "includes/generated/v7_transplant_AccompSeq_PostNoteProcess.bin"
AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitPartFull.bin"
AccompSeq_ResetMidiState:
	call Voice_DecodeNoteParam
	ret

AccompSeq_LookupStyleData:
	.incbin "includes/generated/v7_transplant_AccompSeq_LookupStyleData.bin"
AccompSeq_LookupStyle_Internal:
	.incbin "includes/generated/v7_transplant_AccompSeq_LookupStyle_Internal.bin"
AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	.incbin "includes/generated/v7_transplant_AccompSeq_LoadParams.bin"
AccompSeq_LoadParams_Bit0Set:
	.incbin "includes/generated/v7_transplant_AccompSeq_LoadParams_Bit0Set.bin"
AccompSeq_LoadParams_Alt:
	.incbin "includes/generated/v7_transplant_AccompSeq_LoadParams_Alt.bin"
AccompSeq_LoadParams_OverrideCheck:
	.incbin "includes/generated/v7_transplant_AccompSeq_LoadParams_OverrideCheck.bin"
AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitMidiEvents.bin"
AccompSeq_InitMidi_Ch1Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 12)
	ld e, a
	ldb w, 0x4
	ldb a, 0xd1
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 13)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Reverb
	ldb e, 0x7f

AccompSeq_InitMidi_Ch1Reverb:
	ldb w, 0x7
	ldb a, 0xd1
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 14)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Chorus
	ldb e, 0x7f

AccompSeq_InitMidi_Ch1Chorus:
	ldb w, 0x3
	ldb a, 0xd1
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Ch2:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitMidi_Ch2.bin"
AccompSeq_InitMidi_Ch2Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 28)
	ld e, a
	ldb w, 0x4
	ldb a, 0xd2
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 29)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Reverb
	ldb e, 0x7f

AccompSeq_InitMidi_Ch2Reverb:
	ldb w, 0x7
	ldb a, 0xd2
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 30)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Chorus
	ldb e, 0x7f

AccompSeq_InitMidi_Ch2Chorus:
	ldb w, 0x3
	ldb a, 0xd2
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Return:
	ret

AccompSeq_InitPlayState:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitPlayState.bin"
AccompSeq_InitPlay_SetCounters:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitPlay_SetCounters.bin"
AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	.incbin "includes/generated/v7_transplant_AccompSeq_InitPlay_Store.bin"
AccompSeq_InitPlay_Return:
	ret

AccompSeq_ReinitPart:
	.incbin "includes/generated/v7_transplant_AccompSeq_ReinitPart.bin"
AccompSeq_HandleSpecialMode:
	.incbin "includes/generated/v7_transplant_AccompSeq_HandleSpecialMode.bin"
AccompSeq_OutputEvent:
	.incbin "includes/generated/v7_transplant_AccompSeq_OutputEvent.bin"
AccompSeq_Output_CheckFilter:
	.incbin "includes/generated/v7_transplant_AccompSeq_Output_CheckFilter.bin"
AccompSeq_Output_CheckManual:
	.incbin "includes/generated/v7_transplant_AccompSeq_Output_CheckManual.bin"
AccompSeq_Output_Return:
	popw hl
	ret

AccompSeq_WriteMidiToBuffer:
	pushw wa
	push xiy
	pushw wa
	pushw wa
	call SeqEvtBuf_WriteByte
	inc 2, xsp
	popw wa
	ld a, w
	pushw wa
	call SeqEvtBuf_WriteByte
	inc 2, xsp
	ld a, e
	pushw wa
	call SeqEvtBuf_WriteByte
	inc 2, xsp
	pop xiy
	popw wa
	ret

AccompSeq_WriteMidi_CodeBlock:
	.incbin "includes/generated/v7_transplant_AccompSeq_WriteMidi_CodeBlock.bin"
AccompSeq_AllNotesOffImpl:
	.incbin "includes/generated/v7_transplant_AccompSeq_AllNotesOffImpl.bin"
AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ldb l, 0x7f
	ldb h, 0x3
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	.incbin "includes/generated/v7_transplant_AccompSeq_ClearPendingFlag.bin"
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	.incbin "includes/generated/v7_transplant_AccompSeq_GuardedNoteOff.bin"
AccompSeq_GuardedNote_Return:
	ret


AccompSeq_CleanupSequence:
	.incbin "includes/generated/v7_transplant_AccompSeq_CleanupSequence.bin"
AccompSeq_Cleanup_ClearFlags:
	.incbin "includes/generated/v7_transplant_AccompSeq_Cleanup_ClearFlags.bin"
AccompSeq_SendAllOff:
	.incbin "includes/generated/v7_transplant_AccompSeq_SendAllOff.bin"
AccompSeq_SendAllOff_Loop1:
	.incbin "includes/generated/v7_transplant_AccompSeq_SendAllOff_Loop1.bin"
AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop2
	ret

AccompSeq_MidiFilterCodeBlock:
	.incbin "includes/generated/v7_transplant_AccompSeq_MidiFilterCodeBlock.bin"
AccompSeq_ProcessChordChange:
	.incbin "includes/generated/v7_transplant_AccompSeq_ProcessChordChange.bin"
AccompSeq_ChordChange_Reinit:
	.incbin "includes/generated/v7_transplant_AccompSeq_ChordChange_Reinit.bin"
AccompSeq_ChordChange_CheckOverride:
	.incbin "includes/generated/v7_transplant_AccompSeq_ChordChange_CheckOverride.bin"
AccompSeq_ChordChange_ApplyOverride:
	.incbin "includes/generated/v7_transplant_AccompSeq_ChordChange_ApplyOverride.bin"
AccompSeq_ChordChange_Return:
	ret

AccompSeq_CompareChord:
	.incbin "includes/generated/v7_transplant_AccompSeq_CompareChord.bin"
AccompSeq_CompareChord_Match:
	.incbin "includes/generated/v7_transplant_AccompSeq_CompareChord_Match.bin"
AccompSeq_CompareChord_RestorePos:
	.incbin "includes/generated/v7_transplant_AccompSeq_CompareChord_RestorePos.bin"
AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	.incbin "includes/generated/v7_transplant_AccompSeq_SetupChannels.bin"
AccompSeq_SetupCh2:
	.incbin "includes/generated/v7_transplant_AccompSeq_SetupCh2.bin"
AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	.incbin "includes/generated/v7_transplant_AccompSeq_ParseSequenceData.bin"
AccompSeq_SeqParse_Loop:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_Loop.bin"
AccompSeq_SeqParse_Dispatch:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x83
	jr z, AccompSeq_SeqParse_EndMark
	cp a, 0x81
	jr z, AccompSeq_SeqParse_TimeAdvance
	cp a, 0x90
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0x91
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd2
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd1
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd3
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd4
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd5
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xd7
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xc0
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0x84
	jp_24 z, AccompSeq_SeqParse_TempoReset
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_EndMark:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_EndMark.bin"
AccompSeq_SeqParse_TimeAdvance:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_TimeAdvance.bin"
AccompSeq_SeqParse_TimeStore:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_TimeStore.bin"
AccompSeq_SeqParse_MidiEvent:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_MidiEvent.bin"
AccompSeq_SeqParse_CheckNoteOn:
	ld a, (xiy)
	cp a, 0x90
	jr nz, AccompSeq_SeqParse_CheckNoteOn8
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CheckNoteOn8:
	cp a, 0x91
	jr nz, AccompSeq_SeqParse_CheckProgChg
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CheckProgChg:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_CheckProgChg.bin"
AccompSeq_SeqParse_ProgChg_SetCh:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_ProgChg_SetCh.bin"
AccompSeq_SeqParse_ProgChg_Flags:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_ProgChg_Flags.bin"
AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_CtrlChg.bin"
AccompSeq_SeqParse_CtrlChg_SetCh:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_CtrlChg_SetCh.bin"
AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_TempoReset.bin"
AccompSeq_SeqParse_TempoStore:
	.incbin "includes/generated/v7_transplant_AccompSeq_SeqParse_TempoStore.bin"
AccompSeq_SeqParse_Return:
	ret

AccompSeq_TempoScaleTable:
	.long TempoScale_1Beat
	.long TempoScale_2Beats
	.long TempoScale_3Beats
	.long TempoScale_4Beats
	.long TempoScale_5Beats
	.long TempoScale_6Beats
	.long TempoScale_7Beats
	.long TempoScale_8Beats
TempoScale_8Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	a, (xbc)
	add	a, (xbc)
	add	d, (xbc)
TempoScale_7Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	a, (xbc)
	add	a, (xbc)
	.byte 0x84
TempoScale_6Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	a, (xbc)
	add	d, (xbc)
TempoScale_5Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	a, (xbc)
	.byte 0x84
TempoScale_4Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	d, (xbc)
TempoScale_3Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	.byte 0x81
	add	d, (xbc)
TempoScale_2Beats:
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	d, (xbc)
TempoScale_1Beat:
	.incbin "includes/generated/v7_transplant_TempoScale_1Beat.bin"
AccompSeq_VoiceResetStub:
	ret

AccompSeq_ResetToFactoryBanks:
	call Voice_ResetToFactoryBanks
	ret

AccompSeq_InitBankIfNoError:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xffff
	jr nz, AccompSeq_InitBankDone
	call Voice_InitBankData

AccompSeq_InitBankDone:
	ret

AccompSeq_BankTablePtr:
	jp	Voice_ResetToFactoryBanks

AccompSeq_InitBankTables:
	jp Voice_InitBankTables

