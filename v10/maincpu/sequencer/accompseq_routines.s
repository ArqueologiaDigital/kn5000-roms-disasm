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
	calr AccompSeq_CaptureTimerState
	and (0x7e53:16), 223
	calr AccompSeq_CheckChannelActive
	bit 5, (0x7e53:16)
	jr nz, AccompSeq_PeriodicReturn
	calr AccompSeq_FadeOutTick
	call AccPlay_Entry
	calr AccompSeq_SaveTimerSnapshot

AccompSeq_PeriodicReturn:
	ret

AccompSeq_CaptureTimerState:
	jr AccompSeq_ReadTimerRegisters

AccompSeq_ReadTimerRegisters:
	xor a, a
	ei 6
	ld (1131:16), a
	ld wa, (1128:16)
	ld (0x7e1c:16), wa
	ld a, (1130:16)
	ld (0x7e1e:16), a
	ld a, (1055:16)
	ld (0x7e1f:16), a
	ei 0
	ret

AccompSeq_SaveTimerSnapshot:
	ld wa, (0x7e1c:16)
	ld (0x7e20:16), wa
	ld a, (0x7e1e:16)
	ld (0x7e22:16), a
	ld a, (0x7e1f:16)
	ld (0x7e23:16), a
	ret

AccompSeq_CheckChannelActive:
	bit 2, (0x7e1f:16)
	jr nz, AccompSeq_SetupChannel1
	jp AccompSeq_ChannelSetupDone

AccompSeq_SetupChannel1:
	bit 0, (0x7e24:16)
	jr z, AccompSeq_SetupChannel2
	ld (0x7e52:16), 0
	ld xwa, 0x7aec
	ld (0x7e4c:16), xwa
	ld xwa, 0x7e40
	ld (0x7e48:16), xwa
	ld xwa, 0x7e72
	ld (0x7e74:16), xwa
	ld wa, (0x7e2c:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e2e:16)
	ld (0x7e44:16), wa
	ld wa, (0x7e3c:16)
	ld (0x7e46:16), wa
	ld a, (0x7e6e:16)
	ld (0x7e6d:16), a
	calr AccompSeq_InitEventDispatch
	ld a, (0x7e6d:16)
	ld (0x7e6e:16), a
	ld wa, (0x7e46:16)
	ld (0x7e3c:16), wa
	ld wa, (0x7e44:16)
	ld (0x7e2e:16), wa
	ld wa, (0x7e42:16)
	ld (0x7e2c:16), wa

AccompSeq_SetupChannel2:
	bit 1, (0x7e24:16)
	jr z, AccompSeq_ChannelSetupDone
	ld (0x7e52:16), 1
	ld xwa, 0x7bec
	ld (0x7e4c:16), xwa
	ld xwa, 0x7e41
	ld (0x7e48:16), xwa
	ld xwa, 0x7e73
	ld (0x7e74:16), xwa
	ld wa, (0x7e30:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e32:16)
	ld (0x7e44:16), wa
	ld wa, (0x7e3e:16)
	ld (0x7e46:16), wa
	ld a, (0x7e6f:16)
	ld (0x7e6d:16), a
	calr AccompSeq_InitEventDispatch
	ld a, (0x7e6d:16)
	ld (0x7e6f:16), a
	ld wa, (0x7e46:16)
	ld (0x7e3e:16), wa
	ld wa, (0x7e44:16)
	ld (0x7e32:16), wa
	ld wa, (0x7e42:16)
	ld (0x7e30:16), wa

AccompSeq_ChannelSetupDone:
	ret

AccompSeq_IncrementTickCounter:
	ld	hl, (1128:16)
	ld	a, (1130:16)
	inc	1, a
	cp	a, 96
	jr	nz, AccompSeq_CheckChannelActive_Skip
	xor	a, a
	inc	1, hl
AccompSeq_CheckChannelActive_Skip:
	ld	(1128:16), hl
	ld	(1130:16), a
	inc	1, (1132:16)
	call	SeqEvt_EntryPoint1
	call	SeqEvt_EntryPoint2
	ret

AccompSeq_InitEventDispatch:
	ld a, 0x9:opc
	and (0x7e53:16), 252

AccompSeq_EventDispatchLoop:
	bit 0, (0x7e53:16)
	jr z, AccompSeq_DispatchByOpcode
	jp AccompSeq_EventDispatchDone

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
	or (0x7e53:16), 1
	jr AccompSeq_EventDispatchLoop

AccompSeq_HandleEndMarker:
	bit 1, (0x7e53:16)
	jr z, AccompSeq_EndMarkerCalcTime
	or (0x7e53:16), 1
	jr AccompSeq_EventDispatchLoop

AccompSeq_EndMarkerCalcTime:
	ld a, 0x60:opc
	call AccompSeq_CalcDeltaTime
	cp a, 0x18
	jr ule, AccompSeq_EndMarkerAdvance
	or (0x7e53:16), 1
	jp AccompSeq_EventDispatchLoop

AccompSeq_EndMarkerAdvance:
	or (0x7e53:16), 2
	ld wa, (0x7e46:16)
	inc 1, wa
	ld (0x7e46:16), wa
	calr AccompSeq_AdvancePosition
	jp AccompSeq_EventDispatchLoop

AccompSeq_EventDispatchDone:
	ret

AccompSeq_CheckPatternEnd:
	push xiy
	calr ResolveVRAMAddressForVoice
	ld a, (xiy + 1)
	cp a, 0x87
	jr nz, AccompSeq_PatternEndReturn
	calr AccompSeq_ReadBeatHeader
	ldfr_werp WA, 0xe2
	ld wa, 6:i3
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
	ld wa, (0x7e44:16)
	inc 1, wa
	ld (0x7e44:16), wa
	cp wa, 0:i3
	jr nz, AccompSeq_AdvanceCheckPattern
	pushw wa
	ld wa, (0x7e42:16)
	inc 1, wa
	ld (0x7e42:16), wa
	popw wa

AccompSeq_AdvanceCheckPattern:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x87
	jr nz, AccompSeq_AdvanceDone
	calr AccompSeq_ReadBeatHeader
	ld (0x7e42:16), wa
	ldfr_werp WA, 0xe2
	ld wa, 6:i3
	ld (0x7e44:16), wa
	calr AccompSeq_BuildVRAMAddr
	ld a, (xiy)

AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	cp	(0x7e25:16), 128
	jr	c, AccompSeq_VRAMHelperData_Skip
	calr	AccompSeq_VRAMHelperData_Helper
	jr	AccompSeq_VRAMHelperData_Return
AccompSeq_VRAMHelperData_Skip:
	ld	wa, (0x7e42:16)
	ld	iy, wa
AccompSeq_VRAMHelperData_Return:
	ret
AccompSeq_VRAMHelperData_Helper:
	ld	wa, (0x7e42:16)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 0x1e8b00
	ld	xiy, xwa
	ret

ResolveVRAMAddressForVoice:
	cp (0x7e25:16), 128
	jr c, AccompSeq_ResolveVRAMFallback
	bit 0, (0x7e6d:16)
	jr nz, AccompSeq_ResolveVRAMFallback
	ld wa, (0x7e42:16)
	and xwa, 0xfff
	sla xwa, 8
	ld xiy, xwa
	ld wa, (0x7e44:16)
	and xwa, 0xff
	add xiy, xwa
	add xiy, 0x1e8b00
	jr AccompSeq_ResolveVRAMDone

AccompSeq_ResolveVRAMFallback:
	ld wa, (0x7e42:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e44:16)
	ld xiy, xwa

AccompSeq_ResolveVRAMDone:
	ret

AccompSeq_BuildVRAMAddr:
	push xhl
	ld xhl, xwa
	ldto_werp WA, 0xe2
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
	ld wa, (0x7e42:16)
	and xwa, 0xfff
	sla xwa, 8
	add xwa, 0x3
	add xwa, 0x1e8b00
	ld wa, (xwa)
	ret

AccompSeq_ReadPatternTimeSig:
	ld	wa, (0x7e42:16)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 1
	add	xwa, 0x1e8b00
	ld	wa, (xwa)
	ret

AccompSeq_HandlePartTransition:
	bit 3, (0x7e27:16)
	jr z, AccompSeq_StopPart
	cp (0x7e52:16), 1
	jr z, AccompSeq_TransitionChannel2
	ld wa, (0x7e34:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e36:16)
	ld (0x7e44:16), wa
	jr AccompSeq_PartTransitionDone

AccompSeq_TransitionChannel2:
	ld wa, (0x7e38:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e3a:16)
	ld (0x7e44:16), wa

AccompSeq_PartTransitionDone:
	jr AccompSeq_DispatchReturn

AccompSeq_StopPart:
	cp (0x7e52:16), 1
	jr z, AccompSeq_StopPartCh2
	and (0x7e24:16), 254
	jr AccompSeq_CheckRestart

AccompSeq_StopPartCh2:
	and (0x7e24:16), 253

AccompSeq_CheckRestart:
	or (0x7e53:16), 1
	ld a, (0x7e24:16)
	and a, 0x3
	cp a, 0:i3
	jr nz, AccompSeq_DispatchReturn
	or (0x7e24:16), 1
	call AccompSeq_StopSequence

AccompSeq_DispatchReturn:
	ret

AccompSeq_CalcDeltaTime:
	ld e, a
	ld wa, (0x7e46:16)
	cp wa, (0x7e1c:16)
	jr nz, AccompSeq_DeltaCompare
	ld a, (0x7e1e:16)
	cp a, e
	jr ugt, AccompSeq_DeltaZero
	sub e, a
	ld a, e
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	ld hl, (0x7e1c:16)
	cp hl, wa
	jr ugt, AccompSeq_DeltaFarBehind
	sub wa, hl
	cp wa, 1:i3
	jr z, AccompSeq_DeltaOneAhead
	ld a, 0x60:opc
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaOneAhead:
	ld a, (0x7e1e:16)
	add e, 0x60
	sub e, a
	ld a, e
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaFarBehind:
	xor a, a

AccompSeq_DeltaReturn:
	ret

AccompSeq_ParseEvents:
	cp a, 0:i3
	jr nz, AccompSeq_ParseLoop
	ld a, 0x1:opc

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
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpw (0x7e50:16), 16
	jr ugt, AccompSeq_Parse_Type90_Large
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Done

AccompSeq_Parse_Type90_Large:
	ld xhl, (0x7e4c:16)
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn6

AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	calr AccompSeq_ReadParams
	ld (0x7e5a:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e5b:16), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpw (0x7e50:16), 16
	jr ugt, AccompSeq_Parse_Type91_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Type91_Done

AccompSeq_Parse_Type91_CalcSize:
	ld xhl, (0x7e4c:16)
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn8

AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	ld d, a
	and a, 0xf0
	ld (0x7e54:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e55:16), e
	calr AccompSeq_AdvancePosition
	ld a, d
	and a, 0xf
	ld (0x7e56:16), a
	ld a, (xiy)
	ld (0x7e57:16), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpw (0x7e50:16), 16
	jr ugt, AccompSeq_Parse_TypeC0_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_TypeC0_Done

AccompSeq_Parse_TypeC0_CalcSize:
	ld xhl, (0x7e4c:16)
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNotePorta

AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpw (0x7e50:16), 16
	jr ugt, AccompSeq_Parse_TypeC0_Finalize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Return

AccompSeq_Parse_TypeC0_Finalize:
	ld xhl, (0x7e4c:16)
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn5

AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	ld (0x7e54:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e55:16), e
	calr AccompSeq_AdvancePosition
	ld (0x7e56:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e57:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e58:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7e59:16), a
	calr AccompSeq_AdvancePosition
	ret

AccompSeq_CalcEventSize:
	ld xhl, (0x7e4c:16)
	ld wa, (xhl + 6)
	cp wa, (xhl + 4)
	jr c, AccompSeq_CalcSize_Negative
	jr ugt, AccompSeq_CalcSize_Positive
	ld wa, (xhl + 2)
	sub wa, (xhl + 0:8)
	inc 1, wa
	jr AccompSeq_CalcSize_Store

AccompSeq_CalcSize_Negative:
	ld wa, (xhl + 2)
	sub wa, (xhl + 0:8)
	inc 1, wa
	sub wa, (xhl + 4)
	add wa, (xhl + 6)
	jr AccompSeq_CalcSize_Store

AccompSeq_CalcSize_Positive:
	sub wa, (xhl + 4)

AccompSeq_CalcSize_Store:
	ld (0x7e50:16), wa
	ret

AccompSeq_ResetCounters:
	ld xhl, (0x7e4c:16)
	ldw (xhl + 0:8), 0xa
	ldw (xhl + 2), 0xff
	ldw (xhl + 4), 0xa
	ldw (xhl + 6), 0xa
	ldw (xhl + 8), 0xf6
	ret

AccompSeq_InlineCodeBlock:
	inc	1, xiy
	ld	a, (xiy)
	cp	a, 135
	jr	nz, AccompSeq_ResetCounters_Return
	xor	xhl, xhl
	ld	hl, (xhl+3)
	ld	(0x7e42:16), hl
	push	xhl
	calr	AccompSeq_VRAMHelperData
	pop	xhl
	ld	iy, 6:i3
AccompSeq_ResetCounters_Return:
	ret

AccompSeq_ProcessNoteOn6:
	ld a, (0x7e54:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7e56:16)
	ld e, a
	call AccompSeq_CheckVelocityFlags
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e57:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e58:16)
	cp a, 0:i3
	jr nz, AccompSeq_NoteOn6_VelClamp
	ld a, 0x1:opc

AccompSeq_NoteOn6_VelClamp:
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e59:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld	(xhl+iy), e
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNoteOn8:
	ld a, (0x7e54:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7e56:16)
	ld e, a
	calr AccompSeq_CheckVelFlagsExtended
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e57:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e58:16)
	cp a, 0:i3
	jr nz, AccompSeq_NoteOn8_VelClamp
	ld a, 0x1:opc

AccompSeq_NoteOn8_VelClamp:
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e59:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e5a:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e5b:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld	(xhl+iy), e
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNotePorta:
	ld a, (0x7e54:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7e56:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e57:16)
	calr AccompSeq_PortaFadeOut
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ld a, (0x7e54:16)
	cp a, 0xd0
	jr nz, AccompSeq_NotePorta_Done
	ld a, (0x7e55:16)
	cp a, 5:i3
	jr nz, AccompSeq_NotePorta_Done
	ld a, (0x7e57:16)
	push xiy
	ld xiy, (0x7e74:16)
	ld (xiy), a
	pop xiy

AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	ld a, (0x7e54:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7e56:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e57:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e58:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7e59:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ld a, (0x7e54:16)
	cp a, 0xc0
	jr nz, AccompSeq_NoteOn5_Return
	ld a, (0x7e56:16)
	and a, 0x7f
	bit 0, (0x7e57:16)
	jr z, AccompSeq_NoteOn5_StoreProgram
	or a, 0x80

AccompSeq_NoteOn5_StoreProgram:
	push xiy
	ld xiy, (0x7e48:16)
	ld (xiy), a
	pop xiy

AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	ld a, (0x7e55:16)
	ei 6
	sub a, (1131:16)
	jr ugt, AccompSeq_ResolveCh_Store
	ld a, 0x1:opc
	ld (0x7e55:16), a
	cp (1133:16), 0
	jr z, AccompSeq_ResolveCh_AddOffset
	xor a, a
	jr AccompSeq_ResolveCh_AddOffset

AccompSeq_ResolveCh_Store:
	ld (0x7e55:16), a

AccompSeq_ResolveCh_AddOffset:
	ld w, (1133:16)
	add a, w
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld w, (0x7dfc:16)
	cp a, w
	jr nc, AccompSeq_ResolveCh_Done
	ld (0x7dfc:16), a

AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	and (0x33e5:16), 253
	and (0x33e5:16), 251
	cp a, 0x78
	jr c, AccompSeq_VelFlags_CheckProgram
	or (0x33e5:16), 4

AccompSeq_VelFlags_CheckProgram:
	push xiy
	ld xiy, (0x7e48:16)
	ld w, (xiy)
	cp w, 0xf0
	jr c, AccompSeq_VelFlags_CallDispatch
	or (0x33e5:16), 4

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
	or (0x33e5:16), 2
	pushw wa
	ld a, (0x7e5a:16)
	ld (0x33e6:16), a
	ld a, (0x7e5b:16)
	ld (0x33e7:16), a
	popw wa
	and (0x33e5:16), 251
	cp a, 0x78
	jr c, AccompSeq_ExtVelFlags_CheckProg
	or (0x33e5:16), 4

AccompSeq_ExtVelFlags_CheckProg:
	push xiy
	ld xiy, (0x7e48:16)
	ld w, (xiy)
	cp w, 0xf0
	jr c, AccompSeq_ExtVelFlags_Dispatch
	or (0x33e5:16), 4

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
	ld iy, (xhl + 0:8)

AccompSeq_AdvanceBuf_Return:
	ret

AccompSeq_FadeOutTick:
	bit 2, (0x7e1f:16)
	jr nz, AccompSeq_FadeOut_Active
	jr AccompSeq_FadeOut_Return

AccompSeq_FadeOut_Active:
	bit 7, (0x7e24:16)
	jr z, AccompSeq_FadeOut_Return
	ld wa, (0x7e70:16)
	dec 1, wa
	ld (0x7e70:16), wa
	cp wa, 0xffff
	jr nz, AccompSeq_FadeOut_Periodic
	and (0x7e24:16), 127
	call AccompSeq_StopSequence
	jr AccompSeq_FadeOut_Return

AccompSeq_FadeOut_Periodic:
	and wa, 0x7
	cp wa, 0:i3
	jr nz, AccompSeq_FadeOut_Return
	call AccompSeq_FadeOutApplyVol

AccompSeq_FadeOut_Return:
	ret

AccompSeq_FadeOutApplyVol:
	bit 0, (0x7e24:16)
	jr z, AccompSeq_FadeOut_Ch2Volume
	ld l, (0x7e72:16)
	xor h, h
	ld wa, (0x7e70:16)
	mul xwa, hl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	ld e, a
	ld w, 0x5:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_Ch2Volume:
	bit 1, (0x7e24:16)
	jr z, AccompSeq_FadeOut_ChReturn
	ld l, (0x7e73:16)
	xor h, h
	ld wa, (0x7e70:16)
	mul xwa, hl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	ld e, a
	ld w, 0x5:opc
	ld a, 0xd2:opc
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_ChReturn:
	ret

AccompSeq_PortaFadeOut:
	bit 7, (0x7e24:16)
	jr z, AccompSeq_PortaFade_Return
	ld w, (0x7e54:16)
	cp w, 0xd0
	jr nz, AccompSeq_PortaFade_Return
	ld w, (0x7e55:16)
	cp w, 5:i3
	jr nz, AccompSeq_PortaFade_Return
	push xhl
	push xde
	ld l, (0x7e57:16)
	xor h, h
	ld wa, (0x7e70:16)
	mul xwa, hl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	pop xde
	pop xhl

AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	or (0x7f15:16), 2
	jr AccompSeq_ManualMidi_CheckAllNotes

AccompSeq_ManualMidiMode2:
	or (0x7f15:16), 8

AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7f
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cp h, 3:i3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ld a, (SWBTWR_PAYLOAD_2:16)
	push xwa
	push xhl
	call Voice_DecodeNoteParam
	call Voice_DecodeNoteChannel
	ld (SWBTWR_PAYLOAD_2:16), 1
	cp h, 0:i3
	jr z, AccompSeq_ManualMidi_SetChannel
	ld (SWBTWR_PAYLOAD_2:16), 2
	cp h, 1:i3
	jr z, AccompSeq_ManualMidi_SetChannel
	ld (SWBTWR_PAYLOAD_2:16), 4

AccompSeq_ManualMidi_SetChannel:
	pop xhl
	call AccompSeq_ProcessAfterNote
	pop xwa
	ld (SWBTWR_PAYLOAD_2:16), a

AccompSeq_ManualMidi_ClearFlags:
	and (0x7f15:16), 253
	and (0x7f15:16), 247
	ret

AccompSeq_LargeCodeBlock1:
	ld	(xhl), e
	ld	(xhl+1), d
	ld	a, (0x7e56:16)
	ld	(xhl+2), a
	ld	a, (0x7e57:16)
	ld	(xhl+3), a
	ld	a, (0x7e58:16)
	ld	(xhl+4), a
	calr	AccompSeq_PortaFadeOut_Helper
	ret
AccompSeq_PortaFadeOut_Helper:
	bit	7, e
	jr	z, AccompSeq_PortaFadeOut_Return
	or	d, 16
	and	e, 127
AccompSeq_PortaFadeOut_Return:
	ret
	ld	a, 159:opc
	ld	w, 127:opc
	ld	e, 127:opc
	calr	AccompSeq_PortaFadeOut_Helper_Helper
	ret
	ld	a, 223:opc
	ld	w, 127:opc
	ld	e, 127:opc
	calr	AccompSeq_PortaFadeOut_Helper_Helper
	ret
AccompSeq_PortaFadeOut_Helper_Helper:
	pushw	iy
	ld	xhl, 0x7aec
	ei	6
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	ld	(xiy+hl), e
	calr	AccompSeq_AdvanceBufferPtr
	ld	(xiy+hl), d
	calr	AccompSeq_AdvanceBufferPtr
	ld	(xiy+hl), a
	calr	AccompSeq_AdvanceBufferPtr
	ld	(xhl+4), iy
	ei	0
	popw	iy
	ret
	ld	wa, 0:i3
	ld	(1128:16), wa
	ld	(1130:16), a
	ld	(0x7e1c:16), wa
	ld	(0x7e1e:16), a
	ret
	ld	a, (0x7e62:16)
	ld	w, (1076:16)
	ld	(0x7e62:16), w
	cp	a, w
	jr	z, AccompSeq_PortaFadeOut_Return2
	bit	0, (0x7e5f:16)
	jr	z, AccompSeq_PortaFadeOut_Return2
	and	(0x7e5f:16), 254
	ld	l, (0x7e60:16)
	ld	h, (0x7e61:16)
	ld	a, (0x7e24:16)
	and	a, (P0FC:8)
	cp	a, 0:i3
	jr	nz, AccompSeq_PortaFadeOut_Helper_Skip
	call	AccompSeq_InitPartFull
	jr	AccompSeq_PortaFadeOut_Join
AccompSeq_PortaFadeOut_Helper_Skip:
	call	AccompSeq_ReinitPart
AccompSeq_PortaFadeOut_Join:
	ei	6
	ld	c, (1045:16)
	ld	(1130:16), c
	ld	(1138:16), c
	ld	wa, 0:i3
	ld	a, (1046:16)
	ld	(1128:16), wa
	ei	0
AccompSeq_PortaFadeOut_Return2:
	ret

AccompSeq_UpdatePosition:
	cp (0x7e52:16), 0
	jr nz, AccompSeq_UpdatePos_Part2
	ld xwa, (0x7e65:16)
	and (0x7e6d:16), 254
	jr AccompSeq_UpdatePos_Store

AccompSeq_UpdatePos_Part2:
	ld xwa, (0x7e69:16)
	and (0x7e6d:16), 254

AccompSeq_UpdatePos_Store:
	ld (0x7e44:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e42:16), wa
	ret

AccompSeq_JumpTable:
	jp	AccompSeq_LargeCodeBlock2_Join
	jp	AccompSeq_ProcessAfterNote_Helper
SwbtB3_CodeA9_Listener1:
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
	jp	AccompSeq_ClearPendingFlag
AccompSeq_LargeCodeBlock2_Join:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 9
	jrl	nz, AccompSeq_ProcessAfterNote_Return
	ld	a, (SWBTWR_PAYLOAD_3:16)
	bit	7, a
	jr	z, AccompSeq_ProcessAfterNote_Skip2
	calr	AccompSeq_ProcessAfterNote_Helper
	ld	l, 127:opc
	ld	h, 3:opc
	ld	a, (SWBTWR_PAYLOAD_2:16)
	bit	7, a
	jr	z, AccompSeq_ProcessAfterNote_Skip
	calr	AccompSeq_OutputEvent
AccompSeq_ProcessAfterNote_Skip:
	jrl	AccompSeq_ProcessAfterNote_Return
AccompSeq_ProcessAfterNote_Skip2:
	and	a, 63
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 63
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	xor	w, w
	ld	hl, wa
	ld	xix, AccompSeq_LowestBitIndex
	ld	h, (xix+hl)
	ld l, (64786:16)
	cp l, 17
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	l, 18
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	l, 15
	jr	z, AccompSeq_ProcessAfterNote_Skip3
	cp	l, 16
	jr	nz, AccompSeq_ProcessAfterNote_Skip5
AccompSeq_ProcessAfterNote_Skip3:
	ld	xix, 0x1e8a00
	cp	l, 16
	jr	nz, AccompSeq_ProcessAfterNote_Skip4
	add	xix, 16
AccompSeq_ProcessAfterNote_Skip4:
	sll	h, 1
	ld	l, (xix+h)
	inc 1, h
	ld	h, (xix+h)
	cp l, 14
	jr	ugt, AccompSeq_ProcessAfterNote_Return
AccompSeq_ProcessAfterNote_Skip5:
	call	Voice_NoteChannelGrid_Lookup
	cp	h, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	(0x7f0b:16), 0
	jr	nz, AccompSeq_ProcessAfterNote_Return
	bit	0, (0x7e7a:16)
	jr	z, AccompSeq_ProcessAfterNote_Skip6
	calr	AccompSeq_HandleSpecialMode
	jr	AccompSeq_ProcessAfterNote_Return
AccompSeq_ProcessAfterNote_Skip6:
	calr	AccompSeq_OutputEvent
	call	AccompSeq_ProcessChordChange
AccompSeq_ProcessAfterNote_Return:
	ret

AccompSeq_PostNoteProcess:
	cp h, 0:i3
	jr z, AccompSeq_PostNote_Return
	cp (0x7f0b:16), 0
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange

AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr AccompSeq_ResetMidiState
	ld (0x7e25:16), l
	ld (0x7e26:16), h
	calr AccompSeq_LookupStyleData
	calr AccompSeq_LoadParams
	calr AccompSeq_InitMidiEvents
	calr AccompSeq_InitPlayState
	ret

AccompSeq_ResetMidiState:
	call Voice_DecodeNoteParam
	ret

AccompSeq_LookupStyleData:
	cp l, 0x80
	jr c, AccompSeq_LookupStyle_Internal
	and l, 0xf
	call Voice_DecodeBankIndex
	and xhl, 0xffff
	ld xwa, xhl
	add xwa, 0x1e8800
	ld (0x7e2a:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e28:16), wa
	jr AccompSeq_LookupStyle_Return

AccompSeq_LookupStyle_Internal:
	call Voice_DecodeNoteChannel2
	xor xwa, xwa
	ldw wa, 0x20
	mul xwa, hl
	add xwa, AccompSeq_StyleDataTable
	ld (0x7e2a:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e28:16), wa

AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	ld wa, (0x7e28:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e2a:16)
	ld xiy, xwa
	cp (0x7e25:16), 128
	jr nc, AccompSeq_LoadParams_Alt
	ld a, (xiy + 0:8)
	and a, 0x1d
	ld (0x7e27:16), a
	ld xwa, (xiy + 1)
	add xwa, 0x6
	ld (0x7e2e:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e2c:16), wa
	ld xwa, (xiy + 5)
	ld (0x7e36:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e34:16), wa
	ld a, (xiy + 16)
	bit 0, a
	jr z, AccompSeq_LoadParams_Bit0Set
	or (0x7e27:16), 2

AccompSeq_LoadParams_Bit0Set:
	ld xwa, (xiy + 17)
	add xwa, 0x6
	ld (0x7e32:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e30:16), wa
	ld xwa, (xiy + 21)
	ld (0x7e3a:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e38:16), wa
	jr AccompSeq_LoadParams_OverrideCheck

AccompSeq_LoadParams_Alt:
	ld a, (xiy + 0:8)
	and a, 0x1d
	ld (0x7e27:16), a
	ld wa, (xiy + 3)
	ld (0x7e2c:16), wa
	ld wa, 6:i3
	ld (0x7e2e:16), wa

AccompSeq_LoadParams_OverrideCheck:
	bit 0, (0x7e5f:16)
	jr z, AccompSeq_LoadParams_Return
	ld wa, (0x7e2c:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e2e:16)
	ld (0x7e65:16), xwa
	ld wa, (0x7e30:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e32:16)
	ld (0x7e69:16), xwa
	ld wa, 0:i3
	ld a, (1075:16)
	dec 1, a
	and a, 0x7
	sll wa, 2
	ld xiy, AccompSeq_TempoScaleTable
	ld	xwa, (xiy+wa)
	add xwa, 0x6
	ld (0x7e2e:16), wa
	ld (0x7e32:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e2c:16), wa
	ld (0x7e30:16), wa

AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	ld a, 0xd0:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	calr AccompSeq_WriteMidiToBuffer
	ld (0x7e72:16), 127
	ld (0x7e73:16), 127
	ld wa, (0x7e28:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e2a:16)
	ld xiy, xwa
	bit 0, (0x7e27:16)
	jr z, AccompSeq_InitMidi_Ch2
	ld wa, (xiy + 9)
	ld e, w
	ld w, a
	ld a, 0xc1:opc
	ld (0x7e40:16), w
	and e, 0xf
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch1Flags
	or e, 0x10
	and w, 0x7f

AccompSeq_InitMidi_Ch1Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 12)
	ld e, a
	ld w, 0x4:opc
	ld a, 0xd1:opc
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 13)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Reverb
	ld e, 0x7f:opc

AccompSeq_InitMidi_Ch1Reverb:
	ld w, 0x7:opc
	ld a, 0xd1:opc
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 14)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Chorus
	ld e, 0x7f:opc

AccompSeq_InitMidi_Ch1Chorus:
	ld w, 0x3:opc
	ld a, 0xd1:opc
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Ch2:
	bit 1, (0x7e27:16)
	jr z, AccompSeq_InitMidi_Return
	ld wa, (xiy + 25)
	ld e, w
	ld w, a
	ld a, 0xc2:opc
	ld (0x7e41:16), w
	and e, 0xf
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch2Flags
	or e, 0x10
	and w, 0x7f

AccompSeq_InitMidi_Ch2Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 28)
	ld e, a
	ld w, 0x4:opc
	ld a, 0xd2:opc
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 29)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Reverb
	ld e, 0x7f:opc

AccompSeq_InitMidi_Ch2Reverb:
	ld w, 0x7:opc
	ld a, 0xd2:opc
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 30)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Chorus
	ld e, 0x7f:opc

AccompSeq_InitMidi_Ch2Chorus:
	ld w, 0x3:opc
	ld a, 0xd2:opc
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Return:
	ret

AccompSeq_InitPlayState:
	and (0x7e24:16), 127
	xor wa, wa
	ei 6
	ld (1128:16), wa
	ld (1130:16), a
	ld (1138:16), a
	bit 2, (1055:16)
	jr nz, AccompSeq_InitPlay_SetCounters
	or (1055:16), 1

AccompSeq_InitPlay_SetCounters:
	ei 0
	ld (0x7e3c:16), wa
	ld (0x7e3e:16), wa
	ld a, (0x7e24:16)
	ld w, (0x7e27:16)
	bit 0, w
	jr z, AccompSeq_InitPlay_Ch2Flag
	or a, 0x1

AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	ld (0x7e24:16), a
	ld w, (SWBTWR_PAYLOAD_2:16)
	ld a, 0x1:opc
	bit 0, w
	jr nz, AccompSeq_InitPlay_Return
	ld a, 0x2:opc
	bit 1, w
	jr nz, AccompSeq_InitPlay_Return
	ld a, 0x4:opc

AccompSeq_InitPlay_Return:
	ret

AccompSeq_ReinitPart:
	pushw hl
	ld a, (0x7e24:16)
	and a, 0xfc
	ld (0x7e24:16), a
	calr AccompSeq_SendAllOff
	popw hl
	calr AccompSeq_ResetMidiState
	ld (0x7e25:16), l
	ld (0x7e26:16), h
	calr AccompSeq_LookupStyleData
	calr AccompSeq_LoadParams
	calr AccompSeq_InitMidiEvents
	calr AccompSeq_InitPlayState
	ret

AccompSeq_HandleSpecialMode:
	ld	a, (0x7e24:16)
	and	a, 3
	jr	z, AccompSeq_HandleSpecialMode_Skip
	pushw	hl
	ld	a, (0x7e24:16)
	and	a, 252
	ld	(0x7e24:16), a
	calr	AccompSeq_SendAllOff
	popw	hl
AccompSeq_HandleSpecialMode_Skip:
	ld	a, (0xfd12:16)
	cp	a, 13
	jr	z, AccompSeq_HandleSpecialMode_Skip2
	cp	a, 14
	jr	nz, AccompSeq_HandleSpecialMode_Skip4
AccompSeq_HandleSpecialMode_Skip2:
	ld	(0x7f0b:16), 1
	calr	AccompSeq_ResetMidiState
	and	l, 15
	ld	(0x7f14:16), l
	ld	w, (SWBTWR_PAYLOAD_2:16)
	ld	a, 1:opc
	bit	0, w
	jr	nz, AccompSeq_HandleSpecialMode_Skip3
	ld	a, 2:opc
	bit	1, w
	jr	nz, AccompSeq_HandleSpecialMode_Skip3
	ld	a, 4:opc
AccompSeq_HandleSpecialMode_Skip3:
	jr	AccompSeq_HandleSpecialMode_Return
AccompSeq_HandleSpecialMode_Skip4:
	ld	(GLOBAL_ERROR_CODE:16), 57
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
AccompSeq_HandleSpecialMode_Return:
	ret

AccompSeq_OutputEvent:
	pushw hl
	pushw hl
	call Voice_DecodeNoteChannel
	ld bc, hl
	popw hl
	ld wa, hl
	ld hl, bc
	cpw (0x28aa:16), 0
	jr nz, AccompSeq_Output_CheckFilter
	cp (CURRENT_TITLE:16), 138
	jr nz, AccompSeq_Output_CheckManual
	cp (3429:16), 2
	jr nz, AccompSeq_Output_CheckManual

AccompSeq_Output_CheckFilter:
	bit 3, (0x7f15:16)
	jr nz, AccompSeq_Output_CheckManual
	pushw wa
	pushw hl
	call Tempo_ProcessExpressionChange
	popw hl
	popw wa

AccompSeq_Output_CheckManual:
	bit 1, (0x7f15:16)
	jr nz, AccompSeq_Output_Return
	call MidiPkt_SendControlPair

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
	inc	1, iy
	cp	iy, bc
	jr	ule, AccompSeq_WriteMidiToBuffer_Return
	ld iy, (xhl+0:8)
AccompSeq_WriteMidiToBuffer_Return:
	ret
AccompSeq_ProcessAfterNote_Helper:
	ld	a, (SWBTWR_PAYLOAD_2:16)
	bit	7, a
	jr	nz, AccompSeq_ProcessAfterNote_Helper_Skip2
	and	(0x7e7a:16), 254
	jr	AccompSeq_ProcessAfterNote_Helper_Return
AccompSeq_ProcessAfterNote_Helper_Skip2:
	or	(0x7e7a:16), 1
	ld	a, (0x7f0b:16)
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Helper_Skip3
	ld	a, 0:opc
	ld	(0x7f0b:16), a
	jr	AccompSeq_ProcessAfterNote_Helper_Return
AccompSeq_ProcessAfterNote_Helper_Skip3:
	ld	a, (0x7e24:16)
	and	a, 3
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Helper_Return
	bit	2, (0x7e27:16)
	jr	z, AccompSeq_ProcessAfterNote_Helper_Skip
	bit	7, (0x7e24:16)
	jr	nz, AccompSeq_ProcessAfterNote_Helper_Skip
	ldw	(0x7e70:16), 2048
	or	(0x7e24:16), 128
	jr	AccompSeq_ProcessAfterNote_Helper_Return
AccompSeq_ProcessAfterNote_Helper_Skip:
	calr	AccompSeq_CleanupSequence
AccompSeq_ProcessAfterNote_Helper_Return:
	ret

AccompSeq_AllNotesOffImpl:
	ld a, (0x7e24:16)
	and a, 0x3
	cp a, 0:i3
	jr z, AccompSeq_AllNotesOff_Send
	bit 2, (0x7e27:16)
	jr z, AccompSeq_AllNotesOff_Stop
	bit 7, (0x7e24:16)
	jr nz, AccompSeq_AllNotesOff_Stop
	ldw (0x7e70:16), 2048
	or (0x7e24:16), 128
	jr AccompSeq_AllNotesOff_Send

AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ld l, 0x7f:opc
	ld h, 0x3:opc
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	; --- Routine 1: clear flag at (0x7f0b) if nonzero (15 bytes) ---
	ld	a, (0x7f0b:16)
	cp	a, 0:i3
	jr z, AccompSeq_ClearPending_Return
	ld a, 0x00:opc
	ld	(0x7f0b:16), a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	; --- Routine 2: multi-guard, all-register push, call F99490 (61 bytes) ---
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp a, 0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	and a, 0x03
	cp	a, 0:i3
	jr z, AccompSeq_GuardedNote_Return
	cp	(CURRENT_MODE:16), 19
	jr z, AccompSeq_GuardedNote_Return
	cp	(ACTIVE_TITLE:16), 200
	jr z, AccompSeq_GuardedNote_Return
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ld a, 0xc8:opc
	call UI_PostModeChangeEvent
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
AccompSeq_GuardedNote_Return:
	ret


AccompSeq_CleanupSequence:
	ld a, (0x7e24:16)
	and a, 0x3
	cp a, 0:i3
	jr z, AccompSeq_Cleanup_ClearFlags
	and (0x7e24:16), 127
	or (1055:16), 8
	ld a, (0x7e24:16)
	and a, 0xfc
	ld (0x7e24:16), a
	calr AccompSeq_SendAllOff

AccompSeq_Cleanup_ClearFlags:
	and (0x7e6e:16), 254
	and (0x7e6f:16), 254
	ret

AccompSeq_SendAllOff:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x7f:opc
	calr AccompSeq_WriteMidiToBuffer
	ld a, 0xd0:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	calr AccompSeq_WriteMidiToBuffer
	ld (0x7e72:16), 127
	ld (0x7e73:16), 127
	ld xhl, 0x7aec
	ld wa, (xhl + 4)
	ld (xhl + 6), wa
	ldw wa, 0xf6
	ld (xhl + 8), wa
	ld xhl, 0x7bec
	ld wa, (xhl + 4)
	ld (xhl + 6), wa
	ldw wa, 0xf6
	ld (xhl + 8), wa
	ld a, 0x8:opc
	xor w, w
	ld xhl, 0x7d6c

AccompSeq_SendAllOff_Loop1:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cp a, 0:i3
	jr nz, AccompSeq_SendAllOff_Loop1
	ld a, 0x8:opc
	xor w, w
	ld xhl, 0x7db4

AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cp a, 0:i3
	jr nz, AccompSeq_SendAllOff_Loop2
	ret

AccompSeq_MidiFilterCodeBlock:
	or	(0xe3e2:16), 8
	ret
	ret
	; No reference found.  Unless (0x7F0B) is set, steps (0xFD12) within 0..12 (bit 7 of W = down).
AccompSeq_MidiFilterCodeBlock_Step:
	cp	(0x7f0b:16), 0
	jr	z, AccompSeq_MidiFilterCodeBlock_Code_Skip
	jp	AccompSeq_MidiFilterCodeBlock_Code_Return
AccompSeq_MidiFilterCodeBlock_Code_Skip:
	ld	e, 12:opc
	ld	a, (0xfd12:16)
	bit	7, w
	jr	z, AccompSeq_MidiFilterCodeBlock_Code_Skip3
	inc	1, a
	cp	a, e
	jr	ule, AccompSeq_MidiFilterCodeBlock_Code_Skip2
	ld	a, e
AccompSeq_MidiFilterCodeBlock_Code_Skip2:
	jr	AccompSeq_MidiFilterCodeBlock_Code_Join
AccompSeq_MidiFilterCodeBlock_Code_Skip3:
	dec	1, a
	cp	a, 255
	jr	nz, AccompSeq_MidiFilterCodeBlock_Code_Join
	ld	a, 0:opc
AccompSeq_MidiFilterCodeBlock_Code_Join:
	ld	(0xfd12:16), a
	ld	(0x7e78:16), 0
	or	(0xe3e0:16), 16
	jr	AccompSeq_MidiFilterCodeBlock_Code_Return
	; No reference found.  Was `.byte 0xc1 / jrl 16254 / nop`: `cp (0x7e78:16), 0`.
AccompSeq_MidiFilterCodeBlock_Step2:
	cp	(0x7e78:16), 0
	jr	nz, AccompSeq_MidiFilterCodeBlock_Code_Entry
	ld	(0x7e79:16), a
	ld	(0x7e78:16), 1
	or	(0xe3de:16), 16
	jr	AccompSeq_MidiFilterCodeBlock_Code_Return
AccompSeq_MidiFilterCodeBlock_Code_Entry:
	ld	a, (0x7e79:16)
	ld	w, 10:opc
	add	a, w
	cp	a, 0:i3
	jr	z, AccompSeq_MidiFilterCodeBlock_Step2_Compare
	dec	1, a
AccompSeq_MidiFilterCodeBlock_Step2_Compare:
	cp	a, e
	jr	ule, AccompSeq_MidiFilterCodeBlock_Step2_Store
	ld	a, e
AccompSeq_MidiFilterCodeBlock_Step2_Store:
	ld	(0xfd12:16), a
	ld	(0x7e78:16), 0
	or	(0xe3de:16), 16
AccompSeq_MidiFilterCodeBlock_Code_Return:
	ret
AccompSeq_LowestBitIndex:
	; Byte a (0..63) = the index of the lowest set bit of a, 0 for a = 0.  AccompSeq_ProcessAfterNote
	; reads it with `ld h, (xix+hl)` after `and a, 63`.  Was decoded as `nop / .byte 0x01 / push sr` ...
	.byte	0, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
	.byte	4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
	.byte	5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
	.byte	4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0

AccompSeq_ProcessChordChange:
	and (0x7e6e:16), 254
	and (0x7e6f:16), 254
	and (0x7e5f:16), 252
	pushw hl
	calr AccompSeq_CompareChord
	popw hl
	ld a, (0x7e24:16)
	and a, 0x3
	cp a, 0:i3
	jr nz, AccompSeq_ChordChange_Reinit
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call CompIface_ResetPedal
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	calr AccompSeq_InitPartFull
	jr AccompSeq_ChordChange_CheckOverride

AccompSeq_ChordChange_Reinit:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call CompIface_ResetPedal
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	calr AccompSeq_ReinitPart

AccompSeq_ChordChange_CheckOverride:
	bit 1, (0x7e5f:16)
	jr nz, AccompSeq_ChordChange_ApplyOverride
	bit 0, (0x7e5f:16)
	jr z, AccompSeq_ChordChange_Return
	or (0x7e6e:16), 1
	or (0x7e6f:16), 1

AccompSeq_ChordChange_ApplyOverride:
	and (0x7e5f:16), 253
	call AccompSeq_SetupChannels

AccompSeq_ChordChange_Return:
	ret

AccompSeq_CompareChord:
	bit 0, (0x3283:16)
	jr z, AccompSeq_CompareChord_Return
	bit 2, (0x28b2:16)
	jr nz, AccompSeq_CompareChord_Return
	ld (0x7e60:16), l
	ld (0x7e61:16), h
	ld wa, (0x7e2a:16)
	pushw wa
	ld wa, (0x7e28:16)
	pushw wa
	calr AccompSeq_ResetMidiState
	calr AccompSeq_LookupStyleData
	ld wa, (0x7e28:16)
	ldfr_werp WA, 0xe2
	ld wa, (0x7e2a:16)
	ld xiy, xwa
	ld a, (xiy + 0:8)
	bit 4, a
	jr z, AccompSeq_CompareChord_RestorePos
	ld a, (1075:16)
	ld w, (1046:16)
	inc 1, w
	cp a, w
	jr z, AccompSeq_CompareChord_Match
	or (0x7e5f:16), 2
	jr AccompSeq_CompareChord_RestorePos

AccompSeq_CompareChord_Match:
	or (0x7e5f:16), 1

AccompSeq_CompareChord_RestorePos:
	popw wa
	ld (0x7e28:16), wa
	popw wa
	ld (0x7e2a:16), wa

AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	ei 6
	ld c, (1045:16)
	ld (0x7e63:16), c
	ld wa, 0:i3
	ld a, (1046:16)
	ld (0x7e64:16), a
	ld (1130:16), c
	ld (1138:16), c
	ld (1128:16), wa
	ei 0
	bit 0, (0x7e24:16)
	jr z, AccompSeq_SetupCh2
	ld (0x7e52:16), 0
	ld xwa, 0x7e40
	ld (0x7e48:16), xwa
	ld xwa, 0x7e72
	ld (0x7e74:16), xwa
	ld wa, (0x7e2c:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e2e:16)
	ld (0x7e44:16), wa
	ld wa, (0x7e3c:16)
	ld (0x7e46:16), wa
	ld a, (0x7e6e:16)
	ld (0x7e6d:16), a
	calr AccompSeq_ParseSequenceData
	ld a, (0x7e6d:16)
	ld (0x7e6e:16), a
	ld wa, (0x7e46:16)
	ld (0x7e3c:16), wa
	ld wa, (0x7e44:16)
	ld (0x7e2e:16), wa
	ld wa, (0x7e42:16)
	ld (0x7e2c:16), wa

AccompSeq_SetupCh2:
	bit 1, (0x7e24:16)
	jr z, AccompSeq_SetupCh_Return
	ld (0x7e52:16), 1
	ld xwa, 0x7e41
	ld (0x7e48:16), xwa
	ld xwa, 0x7e73
	ld (0x7e74:16), xwa
	ld wa, (0x7e30:16)
	ld (0x7e42:16), wa
	ld wa, (0x7e32:16)
	ld (0x7e44:16), wa
	ld wa, (0x7e3e:16)
	ld (0x7e46:16), wa
	ld a, (0x7e6f:16)
	ld (0x7e6d:16), a
	calr AccompSeq_ParseSequenceData
	ld a, (0x7e6d:16)
	ld (0x7e6f:16), a
	ld wa, (0x7e46:16)
	ld (0x7e3e:16), wa
	ld wa, (0x7e44:16)
	ld (0x7e32:16), wa
	ld wa, (0x7e42:16)
	ld (0x7e30:16), wa

AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	ld bc, 0:i3
	ld d, (0x7e64:16)
	ld e, (0x7e63:16)
	and (0x7e53:16), 254

AccompSeq_SeqParse_Loop:
	bit 0, (0x7e53:16)
	jr z, AccompSeq_SeqParse_Dispatch
	jp AccompSeq_SeqParse_Return

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
	jp z, (AccompSeq_SeqParse_TempoReset:24)
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_EndMark:
	calr AccompSeq_CleanupSequence
	or (0x7e53:16), 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeAdvance:
	ld bc, (0x7e46:16)
	inc 1, bc
	ld b, c
	xor c, c
	cp de, bc
	jr nc, AccompSeq_SeqParse_TimeStore
	or (0x7e53:16), 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeStore:
	incw 1, (0x7e46:16)
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_MidiEvent:
	calr AccompSeq_CheckPatternEnd
	ld bc, (0x7e46:16)
	ld c, a
	ld b, (0x7e46:16)
	cp de, bc
	jr nc, AccompSeq_SeqParse_CheckNoteOn
	or (0x7e53:16), 1
	jp AccompSeq_SeqParse_Loop

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
	cp a, 0xc0
	jr nz, AccompSeq_SeqParse_CtrlChg
	ld a, 0x1:opc
	cp (0x7e52:16), 0
	jr z, AccompSeq_SeqParse_ProgChg_SetCh
	ld a, 0x2:opc

AccompSeq_SeqParse_ProgChg_SetCh:
	or a, 0xc0
	ld (0x7e54:16), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	ld (0x7e55:16), a
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	ld (0x7e56:16), a
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	and e, 0xf
	ld (0x7e57:16), e
	bit 0, (0x7e56:16)
	jr z, AccompSeq_SeqParse_ProgChg_Flags
	or e, 0x10

AccompSeq_SeqParse_ProgChg_Flags:
	ld a, (0x7e54:16)
	ld w, (0x7e55:16)
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	push xiy
	ld xiy, (0x7e48:16)
	ld a, (0x7e55:16)
	and a, 0x7f
	bit 0, (0x7e56:16)
	jr z, AccompSeq_SeqParse_ProgChg_Store
	or a, 0x80

AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	and a, 0xf
	ld (0x7e55:16), a
	ld a, 0x1:opc
	cp (0x7e52:16), 0
	jr z, AccompSeq_SeqParse_CtrlChg_SetCh
	ld a, 0x2:opc

AccompSeq_SeqParse_CtrlChg_SetCh:
	or a, 0xd0
	ld (0x7e54:16), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	ld (0x7e56:16), e
	ld w, (0x7e55:16)
	ld a, (0x7e54:16)
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	ld w, (0x7e55:16)
	ld a, (0x7e54:16)
	and a, 0xf0
	cp a, 0xd0
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	cp w, 5:i3
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	ld a, (0x7e56:16)
	push xiy
	ld xiy, (0x7e74:16)
	ld (xiy), a
	pop xiy

AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	ld xwa, (0x7e65:16)
	cp (0x7e52:16), 0
	jr z, AccompSeq_SeqParse_TempoStore
	ld xwa, (0x7e69:16)

AccompSeq_SeqParse_TempoStore:
	ld (0x7e44:16), wa
	ldto_werp WA, 0xe2
	ld (0x7e42:16), wa
	jp AccompSeq_SeqParse_Loop

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
	; data, not code: TempoScale_8Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
TempoScale_7Beats:
	; data, not code: TempoScale_7Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
TempoScale_6Beats:
	; data, not code: TempoScale_6Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
TempoScale_5Beats:
	; data, not code: TempoScale_5Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
TempoScale_4Beats:
	; data, not code: TempoScale_4Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x84
TempoScale_3Beats:
	; data, not code: TempoScale_3Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x84
TempoScale_2Beats:
	; data, not code: TempoScale_2Beats is reached only as data (1 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x84
TempoScale_1Beat:
	; data, not code: TempoScale_1Beat is reached only as data (2 data), and its instruction decode held swi (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x84
	.long	AccompSeq_ResetToFactoryBanks
	.long	AccompSeq_VoiceResetStub
	.long	AccompSeq_InitBankIfNoError
	.long	AccompSeq_VoiceResetStub

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

