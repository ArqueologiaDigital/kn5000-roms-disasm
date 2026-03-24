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
	anddi8 0x7E53, 223
	calr AccompSeq_CheckChannelActive
	bitda 5, 0x7E53
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
	stda8 1131, a
	ldda16 xwa, 1128
	stda16 0x7E1C, xwa
	ldda8 a, 1130
	stda8 0x7E1E, a
	ldda8 a, 1055
	stda8 0x7E1F, a
	ei 0
	ret

AccompSeq_SaveTimerSnapshot:
	ldda16 xwa, 0x7E1C
	stda16 0x7E20, xwa
	ldda8 a, 0x7E1E
	stda8 0x7E22, a
	ldda8 a, 0x7E1F
	stda8 0x7E23, a
	ret

AccompSeq_CheckChannelActive:
	bitda 2, 0x7E1F
	jr nz, AccompSeq_SetupChannel1
	jp AccompSeq_ChannelSetupDone

AccompSeq_SetupChannel1:
	bitda 0, 0x7E24
	jr z, AccompSeq_SetupChannel2
	stdi8 0x7E52, 0
	ld xwa, 0x7aec
	stda32 0x7E4C, xwa
	ld xwa, 0x7e40
	stda32 0x7E48, xwa
	ld xwa, 0x7e72
	stda32 0x7E74, xwa
	ldda16 xwa, 0x7E2C
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E2E
	stda16 0x7E44, xwa
	ldda16 xwa, 0x7E3C
	stda16 0x7E46, xwa
	ldda8 a, 0x7E6E
	stda8 0x7E6D, a
	calr AccompSeq_InitEventDispatch
	ldda8 a, 0x7E6D
	stda8 0x7E6E, a
	ldda16 xwa, 0x7E46
	stda16 0x7E3C, xwa
	ldda16 xwa, 0x7E44
	stda16 0x7E2E, xwa
	ldda16 xwa, 0x7E42
	stda16 0x7E2C, xwa

AccompSeq_SetupChannel2:
	bitda 1, 0x7E24
	jr z, AccompSeq_ChannelSetupDone
	stdi8 0x7E52, 1
	ld xwa, 0x7bec
	stda32 0x7E4C, xwa
	ld xwa, 0x7e41
	stda32 0x7E48, xwa
	ld xwa, 0x7e73
	stda32 0x7E74, xwa
	ldda16 xwa, 0x7E30
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E32
	stda16 0x7E44, xwa
	ldda16 xwa, 0x7E3E
	stda16 0x7E46, xwa
	ldda8 a, 0x7E6F
	stda8 0x7E6D, a
	calr AccompSeq_InitEventDispatch
	ldda8 a, 0x7E6D
	stda8 0x7E6F, a
	ldda16 xwa, 0x7E46
	stda16 0x7E3E, xwa
	ldda16 xwa, 0x7E44
	stda16 0x7E32, xwa
	ldda16 xwa, 0x7E42
	stda16 0x7E30, xwa

AccompSeq_ChannelSetupDone:
	ret

AccompSeq_IncrementTickCounter:
	ldda16	hl, 1128
	ldda8	a, 1130
	inc	1, a
	cp	a, 96
	jr	nz, 4
	xor	a, a
	inc	1, hl
	stda16	1128, hl
	stda8	1130, a
	incdi8	1, 1132
	call	SeqEvt_EntryPoint1
	call	SeqEvt_EntryPoint2
	ret

AccompSeq_InitEventDispatch:
	ldb a, 0x9
	anddi8 0x7E53, 252

AccompSeq_EventDispatchLoop:
	bitda 0, 0x7E53
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
	ordi8 0x7E53, 1
	jr AccompSeq_EventDispatchLoop

AccompSeq_HandleEndMarker:
	bitda 1, 0x7E53
	jr z, AccompSeq_EndMarkerCalcTime
	ordi8 0x7E53, 1
	jr AccompSeq_EventDispatchLoop

AccompSeq_EndMarkerCalcTime:
	ldb a, 0x60
	call AccompSeq_CalcDeltaTime
	cp a, 0x18
	jr ule, AccompSeq_EndMarkerAdvance
	ordi8 0x7E53, 1
	jp AccompSeq_EventDispatchLoop

AccompSeq_EndMarkerAdvance:
	ordi8 0x7E53, 2
	ldda16 xwa, 0x7E46
	inc 1, wa
	stda16 0x7E46, xwa
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
	ldda16 xwa, 0x7E44
	inc 1, wa
	stda16 0x7E44, xwa
	cps wa, 0
	jr nz, AccompSeq_AdvanceCheckPattern
	pushw wa
	ldda16 xwa, 0x7E42
	inc 1, wa
	stda16 0x7E42, xwa
	popw wa

AccompSeq_AdvanceCheckPattern:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x87
	jr nz, AccompSeq_AdvanceDone
	calr AccompSeq_ReadBeatHeader
	stda16 0x7E42, xwa
	ldfr_werp WA, 0xe2
	lds wa, 6
	stda16 0x7E44, xwa
	calr AccompSeq_BuildVRAMAddr
	ld a, (xiy)

AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	.byte 0xc1
	ldb	e, 126
	push	xsp
	incm8	7, (xwa)
	halt
	calr	9
	jr	6
	ldda16	wa, 0x7E42
	ld	iy, wa
	ret
	ldda16	wa, 0x7E42
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 0x1E8B00
	ld	xiy, xwa
	ret

ResolveVRAMAddressForVoice:
	cpdi8 0x7E25, 128
	jr c, AccompSeq_ResolveVRAMFallback
	bitda 0, 0x7E6D
	jr nz, AccompSeq_ResolveVRAMFallback
	ldda16 xwa, 0x7E42
	and xwa, 0xfff
	sla xwa, 8
	ld xiy, xwa
	ldda16 xwa, 0x7E44
	and xwa, 0xff
	add xiy, xwa
	add xiy, 0x1e8b00
	jr AccompSeq_ResolveVRAMDone

AccompSeq_ResolveVRAMFallback:
	ldda16 xwa, 0x7E42
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E44
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
	ldda16 xwa, 0x7E42
	and xwa, 0xfff
	sla xwa, 8
	add xwa, 0x3
	add xwa, 0x1e8b00
	ld wa, (xwa)
	ret

AccompSeq_ReadPatternTimeSig:
	ldda16	wa, 0x7E42
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 1
	add	xwa, 0x1E8B00
	ld	wa, (xwa)
	ret

AccompSeq_HandlePartTransition:
	bitda 3, 0x7E27
	jr z, AccompSeq_StopPart
	cpdi8 0x7E52, 1
	jr z, AccompSeq_TransitionChannel2
	ldda16 xwa, 0x7E34
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E36
	stda16 0x7E44, xwa
	jr AccompSeq_PartTransitionDone

AccompSeq_TransitionChannel2:
	ldda16 xwa, 0x7E38
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E3A
	stda16 0x7E44, xwa

AccompSeq_PartTransitionDone:
	jr AccompSeq_DispatchReturn

AccompSeq_StopPart:
	cpdi8 0x7E52, 1
	jr z, AccompSeq_StopPartCh2
	anddi8 0x7E24, 254
	jr AccompSeq_CheckRestart

AccompSeq_StopPartCh2:
	anddi8 0x7E24, 253

AccompSeq_CheckRestart:
	ordi8 0x7E53, 1
	ldda8 a, 0x7E24
	and a, 0x3
	cps a, 0
	jr nz, AccompSeq_DispatchReturn
	ordi8 0x7E24, 1
	call AccompSeq_StopSequence

AccompSeq_DispatchReturn:
	ret

AccompSeq_CalcDeltaTime:
	ld e, a
	ldda16 xwa, 0x7E46
	cpda16 xwa, 0x7E1C
	jr nz, AccompSeq_DeltaCompare
	ldda8 a, 0x7E1E
	cp a, e
	jr ugt, AccompSeq_DeltaZero
	sub e, a
	ld a, e
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	ldda16 xhl, 0x7E1C
	cp hl, wa
	jr ugt, AccompSeq_DeltaFarBehind
	sub wa, hl
	cps wa, 1
	jr z, AccompSeq_DeltaOneAhead
	ldb a, 0x60
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaOneAhead:
	ldda8 a, 0x7E1E
	add e, 0x60
	sub e, a
	ld a, e
	jr AccompSeq_DeltaReturn

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
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpdi16 0x7E50, 16
	jr ugt, AccompSeq_Parse_Type90_Large
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Done

AccompSeq_Parse_Type90_Large:
	ldda32 xhl, 0x7E4C
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn6

AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	calr AccompSeq_ReadParams
	stda8 0x7E5A, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E5B, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpdi16 0x7E50, 16
	jr ugt, AccompSeq_Parse_Type91_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Type91_Done

AccompSeq_Parse_Type91_CalcSize:
	ldda32 xhl, 0x7E4C
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn8

AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	ld d, a
	and a, 0xf0
	stda8 0x7E54, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E55, e
	calr AccompSeq_AdvancePosition
	ld a, d
	and a, 0xf
	stda8 0x7E56, a
	ld a, (xiy)
	stda8 0x7E57, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpdi16 0x7E50, 16
	jr ugt, AccompSeq_Parse_TypeC0_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_TypeC0_Done

AccompSeq_Parse_TypeC0_CalcSize:
	ldda32 xhl, 0x7E4C
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNotePorta

AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpdi16 0x7E50, 16
	jr ugt, AccompSeq_Parse_TypeC0_Finalize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Return

AccompSeq_Parse_TypeC0_Finalize:
	ldda32 xhl, 0x7E4C
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn5

AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	stda8 0x7E54, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E55, e
	calr AccompSeq_AdvancePosition
	stda8 0x7E56, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E57, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E58, a
	calr AccompSeq_AdvancePosition
	stda8 0x7E59, a
	calr AccompSeq_AdvancePosition
	ret

AccompSeq_CalcEventSize:
	ldda32 xhl, 0x7E4C
	ld wa, (xhl + 6)
	cp wa, (xhl + 4)
	jr c, AccompSeq_CalcSize_Negative
	jr ugt, AccompSeq_CalcSize_Positive
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	jr AccompSeq_CalcSize_Store

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
	stda16 0x7E50, xwa
	ret

AccompSeq_ResetCounters:
	ldda32 xhl, 0x7E4C
	ldw (xhl + 256), 0xa
	ldw (xhl + 2), 0xff
	ldw (xhl + 4), 0xa
	ldw (xhl + 6), 0xa
	ldw (xhl + 8), 0xf6
	ret

AccompSeq_InlineCodeBlock:
	inc	1, xiy
	ld	a, (xiy)
	cp	a, 135
	jr	nz, 16
	xor	xhl, xhl
	ld	hl, (xhl+3)
	stda16	0x7E42, hl
	push	xhl
	calr	64814
	pop	xhl
	lds	iy, 6
	ret

AccompSeq_ProcessNoteOn6:
	ldda8 a, 0x7E54
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 0x7E56
	ld e, a
	call AccompSeq_CheckVelocityFlags
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E57
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E58
	cps a, 0
	jr nz, AccompSeq_NoteOn6_VelClamp
	ldb a, 0x1

AccompSeq_NoteOn6_VelClamp:
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E59
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	lda_dri3 XIY, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNoteOn8:
	ldda8 a, 0x7E54
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 0x7E56
	ld e, a
	calr AccompSeq_CheckVelFlagsExtended
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E57
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E58
	cps a, 0
	jr nz, AccompSeq_NoteOn8_VelClamp
	ldb a, 0x1

AccompSeq_NoteOn8_VelClamp:
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E59
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E5A
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E5B
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	lda_dri3 XIY, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNotePorta:
	ldda8 a, 0x7E54
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 0x7E56
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E57
	calr AccompSeq_PortaFadeOut
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ldda8 a, 0x7E54
	cp a, 0xd0
	jr nz, AccompSeq_NotePorta_Done
	ldda8 a, 0x7E55
	cps a, 5
	jr nz, AccompSeq_NotePorta_Done
	ldda8 a, 0x7E57
	push xiy
	ldda32 xiy, 0x7E74
	ld (xiy), a
	pop xiy

AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	ldda8 a, 0x7E54
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 0x7E56
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E57
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E58
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 0x7E59
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ldda8 a, 0x7E54
	cp a, 0xc0
	jr nz, AccompSeq_NoteOn5_Return
	ldda8 a, 0x7E56
	and a, 0x7f
	bitda 0, 0x7E57
	jr z, AccompSeq_NoteOn5_StoreProgram
	or a, 0x80

AccompSeq_NoteOn5_StoreProgram:
	push xiy
	ldda32 xiy, 0x7E48
	ld (xiy), a
	pop xiy

AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	ldda8 a, 0x7E55
	ei 6
	subda8 a, 1131
	jr ugt, AccompSeq_ResolveCh_Store
	ldb a, 0x1
	stda8 0x7E55, a
	cpdi8 1133, 0
	jr z, AccompSeq_ResolveCh_AddOffset
	xor a, a
	jr AccompSeq_ResolveCh_AddOffset

AccompSeq_ResolveCh_Store:
	stda8 0x7E55, a

AccompSeq_ResolveCh_AddOffset:
	ldda8 w, 1133
	add a, w
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 w, 0x7DFC
	cp a, w
	jr nc, AccompSeq_ResolveCh_Done
	stda8 0x7DFC, a

AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	anddi8 0x33E5, 253
	anddi8 0x33E5, 251
	cp a, 0x78
	jr c, AccompSeq_VelFlags_CheckProgram
	ordi8 0x33E5, 4

AccompSeq_VelFlags_CheckProgram:
	push xiy
	ldda32 xiy, 0x7E48
	ld w, (xiy)
	cp w, 0xf0
	jr c, AccompSeq_VelFlags_CallDispatch
	ordi8 0x33E5, 4

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
	ordi8 0x33E5, 2
	pushw wa
	ldda8 a, 0x7E5A
	stda8 0x33E6, a
	ldda8 a, 0x7E5B
	stda8 0x33E7, a
	popw wa
	anddi8 0x33E5, 251
	cp a, 0x78
	jr c, AccompSeq_ExtVelFlags_CheckProg
	ordi8 0x33E5, 4

AccompSeq_ExtVelFlags_CheckProg:
	push xiy
	ldda32 xiy, 0x7E48
	ld w, (xiy)
	cp w, 0xf0
	jr c, AccompSeq_ExtVelFlags_Dispatch
	ordi8 0x33E5, 4

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
	bitda 2, 0x7E1F
	jr nz, AccompSeq_FadeOut_Active
	jr AccompSeq_FadeOut_Return

AccompSeq_FadeOut_Active:
	bitda 7, 0x7E24
	jr z, AccompSeq_FadeOut_Return
	ldda16 xwa, 0x7E70
	dec 1, wa
	stda16 0x7E70, xwa
	cp wa, 0xffff
	jr nz, AccompSeq_FadeOut_Periodic
	anddi8 0x7E24, 127
	call AccompSeq_StopSequence
	jr AccompSeq_FadeOut_Return

AccompSeq_FadeOut_Periodic:
	and wa, 0x7
	cps wa, 0
	jr nz, AccompSeq_FadeOut_Return
	call AccompSeq_FadeOutApplyVol

AccompSeq_FadeOut_Return:
	ret

AccompSeq_FadeOutApplyVol:
	bitda 0, 0x7E24
	jr z, AccompSeq_FadeOut_Ch2Volume
	ldda8 l, 0x7E72
	xor h, h
	ldda16 xwa, 0x7E70
	mul xwa, xhl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	ld e, a
	ldb w, 0x5
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_Ch2Volume:
	bitda 1, 0x7E24
	jr z, AccompSeq_FadeOut_ChReturn
	ldda8 l, 0x7E73
	xor h, h
	ldda16 xwa, 0x7E70
	mul xwa, xhl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	ld e, a
	ldb w, 0x5
	ldb a, 0xd2
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_ChReturn:
	ret

AccompSeq_PortaFadeOut:
	bitda 7, 0x7E24
	jr z, AccompSeq_PortaFade_Return
	ldda8 w, 0x7E54
	cp w, 0xd0
	jr nz, AccompSeq_PortaFade_Return
	ldda8 w, 0x7E55
	cps w, 5
	jr nz, AccompSeq_PortaFade_Return
	push xhl
	push xde
	ldda8 l, 0x7E57
	xor h, h
	ldda16 xwa, 0x7E70
	mul xwa, xhl
	ldto_werp DE, 0xe2
	ldw hl, 0x800
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	pop xde
	pop xhl

AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	ordi8 0x7F15, 2
	jr AccompSeq_ManualMidi_CheckAllNotes

AccompSeq_ManualMidiMode2:
	ordi8 0x7F15, 8

AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7f
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cps h, 3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ldda8 a, 0xC07E
	push xwa
	push xhl
	call Voice_DecodeNoteParam
	call Voice_DecodeNoteChannel
	stdi8 0xC07E, 1
	cps h, 0
	jr z, AccompSeq_ManualMidi_SetChannel
	stdi8 0xC07E, 2
	cps h, 1
	jr z, AccompSeq_ManualMidi_SetChannel
	stdi8 0xC07E, 4

AccompSeq_ManualMidi_SetChannel:
	pop xhl
	call AccompSeq_ProcessAfterNote
	pop xwa
	stda8 0xC07E, a

AccompSeq_ManualMidi_ClearFlags:
	anddi8 0x7F15, 253
	anddi8 0x7F15, 247
	ret

AccompSeq_LargeCodeBlock1:
	ld	(xhl), e
	ld	(xhl+1), d
	ldda8	a, 0x7E56
	ld	(xhl+2), a
	ldda8	a, 0x7E57
	ld	(xhl+3), a
	ldda8	a, 0x7E58
	ld	(xhl+4), a
	calr	1
	ret
	bit	7, e
	jr	z, 6
	or	d, 16
	and	e, 127
	ret
	ldb	a, 159
	ldb	w, 127
	ldb	e, 127
	calr	11
	ret
	ldb	a, 223
	ldb	w, 127
	ldb	e, 127
	calr	1
	ret
	pushw	iy
	ld	xhl, 0x7AEC
	ei	6
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ld	xiy, 0xF3FE8C1E
	reti
	.byte 0xf4, 0xec
	ld	xix, 0xF3FE841E
	reti
	.byte 0xf4, 0xec
	ld	xbc, 0xBBFE7C1E
	.byte 0x04, 0x55
	di
	popw	iy
	ret
	lds	wa, 0
	stda16	1128, wa
	stda8	1130, a
	stda16	0x7E1C, wa
	stda8	0x7E1E, a
	ret
	ldda8	a, 0x7E62
	ldda8	w, 1076
	stda8	0x7E62, w
	cp	a, w
	jr	z, 66
	.byte 0xf1
	pop	xsp
	jrl	nz, 26312
	push	xix
	.byte 0xc1
	pop	xsp
	jrl	nz, -452
	ldda8	l, 0x7E60
	ldda8	h, 0x7E61
	ldda8	a, 0x7E24
	.byte 0xc0
	pop_sr
	decdi8	6, 0xD8C9
	.byte 0x06
	call	AccompSeq_InitPartFull
	jr	4
	call	AccompSeq_ReinitPart
	ei	6
	ldda8	c, 1045
	stda8	1130, c
	stda8	1138, c
	lds	wa, 0
	ldda8	a, 1046
	stda16	1128, wa
	di
	ret

AccompSeq_UpdatePosition:
	cpdi8 0x7E52, 0
	jr nz, AccompSeq_UpdatePos_Part2
	ldda32 xwa, 0x7E65
	anddi8 0x7E6D, 254
	jr AccompSeq_UpdatePos_Store

AccompSeq_UpdatePos_Part2:
	ldda32 xwa, 0x7E69
	anddi8 0x7E6D, 254

AccompSeq_UpdatePos_Store:
	stda16 0x7E44, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E42, xwa
	ret

AccompSeq_JumpTable:
	jp	0xF6E651
	jp	0xF6EA61
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
	ldda8	a, 0xC07D
	cp	a, 9
	jrl	nz, 160
	ldda8	a, 0xC07F
	bit	7, a
	jr	z, 22
	calr	1018
	ldb	l, 127
	ldb	h, 3
	ldda8	a, 0xC07E
	bit	7, a
	jr	z, 3
	calr	899
	jrl	129
	and	a, 63
	cps	a, 0
	jr	z, 122
	ldda8	a, 0xC07E
	andda8	a, 0xC07F
	and	a, 63
	cps	a, 0
	jr	z, 107
	xor	w, w
	ld	hl, wa
	ld	xix, 0xF6EC3A
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	h, 193
	ccf
	swi	5
	ldb	l, 207
	.byte 0xcf
	scf
	jr	z, 84
	cp	l, 18
	jr	z, 79
	cp	l, 15
	jr	z, 5
	cp	l, 16
	jr	nz, 36
	ld	xix, 0x1E8A00
	cp	l, 16
	jr	nz, 6
	add	xix, 16
	sll	h, 1
	.byte 0xc3
	pop_sr
	.byte 0xf0, 0xed
	ldb	l, 206
	jr	lt, -61
	pop_sr
	.byte 0xf0, 0xed
	ldb	h, 207
	.byte 0xcf
	ret
	jr	ugt, 33
	call	0xF71475
	cps	h, 0
	jr	z, 25
	.byte 0xc1
	pushw	0x3F7F
	nop
	jr	nz, 18
	.byte 0xf1
	jrl	gt, -14210
	jr	z, 5
	calr	684
	jr	7
	calr	771
	call	AccompSeq_ProcessChordChange
	ret

AccompSeq_PostNoteProcess:
	cps h, 0
	jr z, AccompSeq_PostNote_Return
	cpdi8 0x7F0B, 0
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange

AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr AccompSeq_ResetMidiState
	stda8 0x7E25, l
	stda8 0x7E26, h
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
	stda16 0x7E2A, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E28, xwa
	jr AccompSeq_LookupStyle_Return

AccompSeq_LookupStyle_Internal:
	call Voice_DecodeNoteChannel2
	xor xwa, xwa
	ldw wa, 0x20
	mul xwa, xhl
	add xwa, 0xe4c1a6
	stda16 0x7E2A, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E28, xwa

AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	ldda16 xwa, 0x7E28
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E2A
	ld xiy, xwa
	cpdi8 0x7E25, 128
	jr nc, AccompSeq_LoadParams_Alt
	ld a, (xiy + 256)
	and a, 0x1d
	stda8 0x7E27, a
	ld xwa, (xiy + 1)
	add xwa, 0x6
	stda16 0x7E2E, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E2C, xwa
	ld xwa, (xiy + 5)
	stda16 0x7E36, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E34, xwa
	ld a, (xiy + 16)
	bit 0, a
	jr z, AccompSeq_LoadParams_Bit0Set
	ordi8 0x7E27, 2

AccompSeq_LoadParams_Bit0Set:
	ld xwa, (xiy + 17)
	add xwa, 0x6
	stda16 0x7E32, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E30, xwa
	ld xwa, (xiy + 21)
	stda16 0x7E3A, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E38, xwa
	jr AccompSeq_LoadParams_OverrideCheck

AccompSeq_LoadParams_Alt:
	ld a, (xiy + 256)
	and a, 0x1d
	stda8 0x7E27, a
	ld wa, (xiy + 3)
	stda16 0x7E2C, xwa
	lds wa, 6
	stda16 0x7E2E, xwa

AccompSeq_LoadParams_OverrideCheck:
	bitda 0, 0x7E5F
	jr z, AccompSeq_LoadParams_Return
	ldda16 xwa, 0x7E2C
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E2E
	stda32 0x7E65, xwa
	ldda16 xwa, 0x7E30
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E32
	stda32 0x7E69, xwa
	lds wa, 0
	ldda8 a, 1075
	dec 1, a
	and a, 0x7
	sll wa, 2
	ld xiy, AccompSeq_TempoScaleTable
	ld_sril3 XWA, 0x07, 0xf4, 0xe0
	add xwa, 0x6
	stda16 0x7E2E, xwa
	stda16 0x7E32, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E2C, xwa
	stda16 0x7E30, xwa

AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	ldb a, 0xd0
	ldb w, 0x3
	ldb e, 0x0
	calr AccompSeq_WriteMidiToBuffer
	stdi8 0x7E72, 127
	stdi8 0x7E73, 127
	ldda16 xwa, 0x7E28
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E2A
	ld xiy, xwa
	bitda 0, 0x7E27
	jr z, AccompSeq_InitMidi_Ch2
	ld wa, (xiy + 9)
	ld e, w
	ld w, a
	ldb a, 0xc1
	stda8 0x7E40, w
	and e, 0xf
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch1Flags
	or e, 0x10
	and w, 0x7f

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
	bitda 1, 0x7E27
	jr z, AccompSeq_InitMidi_Return
	ld wa, (xiy + 25)
	ld e, w
	ld w, a
	ldb a, 0xc2
	stda8 0x7E41, w
	and e, 0xf
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch2Flags
	or e, 0x10
	and w, 0x7f

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
	anddi8 0x7E24, 127
	xor wa, wa
	ei 6
	stda16 1128, xwa
	stda8 1130, a
	stda8 1138, a
	bitda 2, 1055
	jr nz, AccompSeq_InitPlay_SetCounters
	ordi8 1055, 1

AccompSeq_InitPlay_SetCounters:
	ei 0
	stda16 0x7E3C, xwa
	stda16 0x7E3E, xwa
	ldda8 a, 0x7E24
	ldda8 w, 0x7E27
	bit 0, w
	jr z, AccompSeq_InitPlay_Ch2Flag
	or a, 0x1

AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	stda8 0x7E24, a
	ldda8 w, 0xC07E
	ldb a, 0x1
	bit 0, w
	jr nz, AccompSeq_InitPlay_Return
	ldb a, 0x2
	bit 1, w
	jr nz, AccompSeq_InitPlay_Return
	ldb a, 0x4

AccompSeq_InitPlay_Return:
	ret

AccompSeq_ReinitPart:
	pushw hl
	ldda8 a, 0x7E24
	and a, 0xfc
	stda8 0x7E24, a
	calr AccompSeq_SendAllOff
	popw hl
	calr AccompSeq_ResetMidiState
	stda8 0x7E25, l
	stda8 0x7E26, h
	calr AccompSeq_LookupStyleData
	calr AccompSeq_LoadParams
	calr AccompSeq_InitMidiEvents
	calr AccompSeq_InitPlayState
	ret

AccompSeq_HandleSpecialMode:
	ldda8	a, 0x7E24
	and	a, 3
	jr	z, 16
	pushw	hl
	ldda8	a, 0x7E24
	and	a, 252
	stda8	0x7E24, a
	calr	417
	popw	hl
	ldda8	a, 0xFD12
	cp	a, 13
	jr	z, 5
	cp	a, 14
	jr	nz, 37
	stdi8	0x7F0B, 1
	calr	64858
	and	l, 15
	stda8	0x7F14, l
	ldda8	w, 0xC07E
	ldb	a, 1
	bit	0, w
	jr	nz, 9
	ldb	a, 2
	bit	1, w
	jr	nz, 2
	ldb	a, 4
	jr	15
	stdi8	0x7F42, 57
	call	DrumVoice_NotifyEE
	ldb	a, 8
	call	MIDI_SendSysExCmd
	ret

AccompSeq_OutputEvent:
	pushw hl
	pushw hl
	call Voice_DecodeNoteChannel
	ld bc, hl
	popw hl
	ld wa, hl
	ld hl, bc
	cpdi16 0x28AA, 0
	jr nz, AccompSeq_Output_CheckFilter
	cpdi8 0x8D36, 138
	jr nz, AccompSeq_Output_CheckManual
	cpdi8 3429, 2
	jr nz, AccompSeq_Output_CheckManual

AccompSeq_Output_CheckFilter:
	bitda 3, 0x7F15
	jr nz, AccompSeq_Output_CheckManual
	pushw wa
	pushw hl
	call Tempo_ProcessExpressionChange
	popw hl
	popw wa

AccompSeq_Output_CheckManual:
	bitda 1, 0x7F15
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
	jr	ule, 3
	.byte 0x9b
	nop
	ldb	e, 14
	ldda8	a, 0xC07E
	bit	7, a
	jr	nz, 7
	.byte 0xc1
	jrl	gt, 15486
	swi	6
	jr	60
	.byte 0xc1
	jrl	gt, 15998
	.byte 0x01
	ldda8	a, 0x7F0B
	cps	a, 0
	jr	z, 8
	ldb	a, 0
	stda8	0x7F0B, a
	jr	39
	ldda8	a, 0x7E24
	and	a, 3
	cps	a, 0
	jr	z, 28
	.byte 0xf1
	ldb	l, 126
	inc	6, b
	zcf
	.byte 0xf1
	ldb	d, 126
	dec	6, l
	decf
	stdi16	0x7E70, 2048
	.byte 0xc1
	ldb	d, 126
	push	xiz
	decm8	8, (xwa)
	pop_sr
	calr	124
	ret

AccompSeq_AllNotesOffImpl:
	ldda8 a, 0x7E24
	and a, 0x3
	cps a, 0
	jr z, AccompSeq_AllNotesOff_Send
	bitda 2, 0x7E27
	jr z, AccompSeq_AllNotesOff_Stop
	bitda 7, 0x7E24
	jr nz, AccompSeq_AllNotesOff_Stop
	stdi16 0x7E70, 2048
	ordi8 0x7E24, 128
	jr AccompSeq_AllNotesOff_Send

AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ldb l, 0x7f
	ldb h, 0x3
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	; --- Routine 1: clear flag at (0x7f0b) if nonzero (15 bytes) ---
	ldda8	a, 0x7F0B
	cps	a, 0
	jr z, AccompSeq_ClearPending_Return
	ldb a, 0x00
	stda8	0x7F0B, a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	; --- Routine 2: multi-guard, all-register push, call F99490 (61 bytes) ---
	ldda8	a, 0xC07D
	cp a, 0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ldda8	a, 0xC07E
	andda8	a, 0xC07F
	and a, 0x03
	cps	a, 0
	jr z, AccompSeq_GuardedNote_Return
	cpdi8	0x8D34, 19
	jr z, AccompSeq_GuardedNote_Return
	cpdi8	0x8D38, 200
	jr z, AccompSeq_GuardedNote_Return
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ldb a, 0xc8
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
	ldda8 a, 0x7E24
	and a, 0x3
	cps a, 0
	jr z, AccompSeq_Cleanup_ClearFlags
	anddi8 0x7E24, 127
	ordi8 1055, 8
	ldda8 a, 0x7E24
	and a, 0xfc
	stda8 0x7E24, a
	calr AccompSeq_SendAllOff

AccompSeq_Cleanup_ClearFlags:
	anddi8 0x7E6E, 254
	anddi8 0x7E6F, 254
	ret

AccompSeq_SendAllOff:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x7f
	calr AccompSeq_WriteMidiToBuffer
	ldb a, 0xd0
	ldb w, 0x3
	ldb e, 0x0
	calr AccompSeq_WriteMidiToBuffer
	stdi8 0x7E72, 127
	stdi8 0x7E73, 127
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
	ldb a, 0x8
	xor w, w
	ld xhl, 0x7d6c

AccompSeq_SendAllOff_Loop1:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop1
	ldb a, 0x8
	xor w, w
	ld xhl, 0x7db4

AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop2
	ret

AccompSeq_MidiFilterCodeBlock:
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	14, 14
	.byte 0xc1
	pushw	0x3F7F
	nop
	jr	z, 4
	jp	0xF6EC39
	ldb	e, 12
	ldda8	a, 0xFD12
	bit	7, w
	jr	z, 10
	inc	1, a
	cp	a, e
	jr	ule, 2
	ld	a, e
	jr	9
	dec	1, a
	cp	a, 255
	jr	nz, 2
	ldb	a, 0
	stda8	0xFD12, a
	stdi8	0x7E78, 0
	.byte 0xc1, 0xe0, 0xe3
	push	xiz
	rcf
	jr	57
	.byte 0xc1
	jrl	16254
	nop
	jr	nz, 16
	stda8	0x7E79, a
	stdi8	0x7E78, 1
	.byte 0xc1
	or	hl, iz
	push	xiz
	rcf
	jr	34
	.byte 0xc1
	.ascii "y~! "
	ldwio	200, 0xC981
	inc	6, wa
	push_sr
	dec	1, a
	cp	a, e
	jr	ule, 2
	ld	a, e
	stda8	0xFD12, a
	stdi8	0x7E78, 0
	.byte 0xc1
	or	hl, iz
	push	xiz
	rcf
	ret
	nop
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	pop_sr
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	.byte 0x04
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	pop_sr
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	halt
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	pop_sr
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	.byte 0x04
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop
	pop_sr
	nop
	.byte 0x01
	nop
	push_sr
	nop
	.byte 0x01
	nop

AccompSeq_ProcessChordChange:
	anddi8 0x7E6E, 254
	anddi8 0x7E6F, 254
	anddi8 0x7E5F, 252
	pushw hl
	calr AccompSeq_CompareChord
	popw hl
	ldda8 a, 0x7E24
	and a, 0x3
	cps a, 0
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
	bitda 1, 0x7E5F
	jr nz, AccompSeq_ChordChange_ApplyOverride
	bitda 0, 0x7E5F
	jr z, AccompSeq_ChordChange_Return
	ordi8 0x7E6E, 1
	ordi8 0x7E6F, 1

AccompSeq_ChordChange_ApplyOverride:
	anddi8 0x7E5F, 253
	call AccompSeq_SetupChannels

AccompSeq_ChordChange_Return:
	ret

AccompSeq_CompareChord:
	bitda 0, 0x3283
	jr z, AccompSeq_CompareChord_Return
	bitda 2, 0x28B2
	jr nz, AccompSeq_CompareChord_Return
	stda8 0x7E60, l
	stda8 0x7E61, h
	ldda16 xwa, 0x7E2A
	pushw wa
	ldda16 xwa, 0x7E28
	pushw wa
	calr AccompSeq_ResetMidiState
	calr AccompSeq_LookupStyleData
	ldda16 xwa, 0x7E28
	ldfr_werp WA, 0xe2
	ldda16 xwa, 0x7E2A
	ld xiy, xwa
	ld a, (xiy + 256)
	bit 4, a
	jr z, AccompSeq_CompareChord_RestorePos
	ldda8 a, 1075
	ldda8 w, 1046
	inc 1, w
	cp a, w
	jr z, AccompSeq_CompareChord_Match
	ordi8 0x7E5F, 2
	jr AccompSeq_CompareChord_RestorePos

AccompSeq_CompareChord_Match:
	ordi8 0x7E5F, 1

AccompSeq_CompareChord_RestorePos:
	popw wa
	stda16 0x7E28, xwa
	popw wa
	stda16 0x7E2A, xwa

AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	ei 6
	ldda8 c, 1045
	stda8 0x7E63, c
	lds wa, 0
	ldda8 a, 1046
	stda8 0x7E64, a
	stda8 1130, c
	stda8 1138, c
	stda16 1128, xwa
	ei 0
	bitda 0, 0x7E24
	jr z, AccompSeq_SetupCh2
	stdi8 0x7E52, 0
	ld xwa, 0x7e40
	stda32 0x7E48, xwa
	ld xwa, 0x7e72
	stda32 0x7E74, xwa
	ldda16 xwa, 0x7E2C
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E2E
	stda16 0x7E44, xwa
	ldda16 xwa, 0x7E3C
	stda16 0x7E46, xwa
	ldda8 a, 0x7E6E
	stda8 0x7E6D, a
	calr AccompSeq_ParseSequenceData
	ldda8 a, 0x7E6D
	stda8 0x7E6E, a
	ldda16 xwa, 0x7E46
	stda16 0x7E3C, xwa
	ldda16 xwa, 0x7E44
	stda16 0x7E2E, xwa
	ldda16 xwa, 0x7E42
	stda16 0x7E2C, xwa

AccompSeq_SetupCh2:
	bitda 1, 0x7E24
	jr z, AccompSeq_SetupCh_Return
	stdi8 0x7E52, 1
	ld xwa, 0x7e41
	stda32 0x7E48, xwa
	ld xwa, 0x7e73
	stda32 0x7E74, xwa
	ldda16 xwa, 0x7E30
	stda16 0x7E42, xwa
	ldda16 xwa, 0x7E32
	stda16 0x7E44, xwa
	ldda16 xwa, 0x7E3E
	stda16 0x7E46, xwa
	ldda8 a, 0x7E6F
	stda8 0x7E6D, a
	calr AccompSeq_ParseSequenceData
	ldda8 a, 0x7E6D
	stda8 0x7E6F, a
	ldda16 xwa, 0x7E46
	stda16 0x7E3E, xwa
	ldda16 xwa, 0x7E44
	stda16 0x7E32, xwa
	ldda16 xwa, 0x7E42
	stda16 0x7E30, xwa

AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	lds bc, 0
	ldda8 d, 0x7E64
	ldda8 e, 0x7E63
	anddi8 0x7E53, 254

AccompSeq_SeqParse_Loop:
	bitda 0, 0x7E53
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
	jp_24 z, AccompSeq_SeqParse_TempoReset
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_EndMark:
	calr AccompSeq_CleanupSequence
	ordi8 0x7E53, 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeAdvance:
	ldda16 xbc, 0x7E46
	inc 1, bc
	ld b, c
	xor c, c
	cp de, bc
	jr nc, AccompSeq_SeqParse_TimeStore
	ordi8 0x7E53, 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeStore:
	incdi16 1, 0x7E46
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_MidiEvent:
	calr AccompSeq_CheckPatternEnd
	ldda16 xbc, 0x7E46
	ld c, a
	ldda8 b, 0x7E46
	cp de, bc
	jr nc, AccompSeq_SeqParse_CheckNoteOn
	ordi8 0x7E53, 1
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
	ldb a, 0x1
	cpdi8 0x7E52, 0
	jr z, AccompSeq_SeqParse_ProgChg_SetCh
	ldb a, 0x2

AccompSeq_SeqParse_ProgChg_SetCh:
	or a, 0xc0
	stda8 0x7E54, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	stda8 0x7E55, a
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	stda8 0x7E56, a
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	and e, 0xf
	stda8 0x7E57, e
	bitda 0, 0x7E56
	jr z, AccompSeq_SeqParse_ProgChg_Flags
	or e, 0x10

AccompSeq_SeqParse_ProgChg_Flags:
	ldda8 a, 0x7E54
	ldda8 w, 0x7E55
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	push xiy
	ldda32 xiy, 0x7E48
	ldda8 a, 0x7E55
	and a, 0x7f
	bitda 0, 0x7E56
	jr z, AccompSeq_SeqParse_ProgChg_Store
	or a, 0x80

AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	and a, 0xf
	stda8 0x7E55, a
	ldb a, 0x1
	cpdi8 0x7E52, 0
	jr z, AccompSeq_SeqParse_CtrlChg_SetCh
	ldb a, 0x2

AccompSeq_SeqParse_CtrlChg_SetCh:
	or a, 0xd0
	stda8 0x7E54, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	stda8 0x7E56, e
	ldda8 w, 0x7E55
	ldda8 a, 0x7E54
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	ldda8 w, 0x7E55
	ldda8 a, 0x7E54
	and a, 0xf0
	cp a, 0xd0
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	cps w, 5
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	ldda8 a, 0x7E56
	push xiy
	ldda32 xiy, 0x7E74
	ld (xiy), a
	pop xiy

AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	ldda32 xwa, 0x7E65
	cpdi8 0x7E52, 0
	jr z, AccompSeq_SeqParse_TempoStore
	ldda32 xwa, 0x7E69

AccompSeq_SeqParse_TempoStore:
	stda16 0x7E44, xwa
	ldto_werp WA, 0xe2
	stda16 0x7E42, xwa
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
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	.byte 0x84
	jrl	ge, -2320
	nop
	jrl	-2320
	nop
	.long AccompSeq_InitBankIfNoError
	.long AccompSeq_VoiceResetStub

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

