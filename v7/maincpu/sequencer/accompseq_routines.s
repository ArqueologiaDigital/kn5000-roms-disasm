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
	anddi8 (0x7db7), 0xdf
	calr AccompSeq_CheckChannelActive
	bitda 5, (0x7db7)
	jr nz, AccompSeq_PeriodicReturn
	calr AccompSeq_FadeOutTick
	call AccPlay_Entry
	calr AccompSeq_SaveTimerSnapshot
AccompSeq_PeriodicReturn:
	ret

AccompSeq_CaptureTimerState:
	jr AccompSeq_ReadTimerRegisters

AccompSeq_ReadTimerRegisters:
	xor	a, a
	ei	6
	stb_d8	(1131), a
	ldw_d16	wa, (1128)
	stda16	(32128), wa
	ldb_d8	a, (1130)
	stb_d8	(32130), a
	ldb_d8	a, (1055)
	stb_d8	(32131), a
	di
	ret
AccompSeq_SaveTimerSnapshot:
	ldw_d16	wa, (32128)
	stda16	(32132), wa
	ldb_d8	a, (32130)
	stb_d8	(32134), a
	ldb_d8	a, (32131)
	stb_d8	(32135), a
	ret
AccompSeq_CheckChannelActive:
	bitda 2, (0x7d83)
	jr nz, .Lc_f6d915
	jp AccompSeq_ChannelSetupDone
AccompSeq_SetupChannel1:
.Lc_f6d915:
	bitda 0, (0x7d88)
	jr z, .Lc_f6d97e
	stdi8 (0x7db6), 0x00
	ld XWA,0x00007a50
	stda32 (0x7db0), xwa
	ld XWA,0x00007da4
	stda32 (0x7dac), xwa
	ld XWA,0x00007dd6
	stda32 (0x7dd8), xwa
	ldw_d16 wa, (0x7d90)
	stda16 (0x7da6), wa
	ldw_d16 wa, (0x7d92)
	stda16 (0x7da8), wa
	ldw_d16 wa, (0x7da0)
	stda16 (0x7daa), wa
	ldb_d8 a, (0x7dd2)
	stb_d8 (0x7dd1), a
	calr AccompSeq_InitEventDispatch
	ldb_d8 a, (0x7dd1)
	stb_d8 (0x7dd2), a
	ldw_d16 wa, (0x7daa)
	stda16 (0x7da0), wa
	ldw_d16 wa, (0x7da8)
	stda16 (0x7d92), wa
	ldw_d16 wa, (0x7da6)
	stda16 (0x7d90), wa
AccompSeq_SetupChannel2:
.Lc_f6d97e:
	bitda 1, (0x7d88)
	jr z, AccompSeq_ChannelSetupDone
	stdi8 (0x7db6), 0x01
	ld XWA,0x00007b50
	stda32 (0x7db0), xwa
	ld XWA,0x00007da5
	stda32 (0x7dac), xwa
	ld XWA,0x00007dd7
	stda32 (0x7dd8), xwa
	ldw_d16 wa, (0x7d94)
	stda16 (0x7da6), wa
	ldw_d16 wa, (0x7d96)
	stda16 (0x7da8), wa
	ldw_d16 wa, (0x7da2)
	stda16 (0x7daa), wa
	ldb_d8 a, (0x7dd3)
	stb_d8 (0x7dd1), a
	calr AccompSeq_InitEventDispatch
	ldb_d8 a, (0x7dd1)
	stb_d8 (0x7dd3), a
	ldw_d16 wa, (0x7daa)
	stda16 (0x7da2), wa
	ldw_d16 wa, (0x7da8)
	stda16 (0x7d96), wa
	ldw_d16 wa, (0x7da6)
	stda16 (0x7d94), wa
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
	ldb a, 0x9

	.byte 0xc1, 0xb7, 0x7d, 0x3c, 0xfc	; anddi8 (0x7e53), 252 (v7 patched)



AccompSeq_EventDispatchLoop:
	.byte 0xf1, 0xb7, 0x7d, 0xc8, 0x66, 0x04, 0x1b, 0xc0
	.byte 0xda, 0xf6
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
	.byte 0xc1, 0xb7, 0x7d, 0x3e, 0x01, 0x68, 0x8e
AccompSeq_HandleEndMarker:
	.byte 0xf1, 0xb7, 0x7d, 0xc9, 0x66, 0x07, 0xc1, 0xb7
	.byte 0x7d, 0x3e, 0x01, 0x68, 0x81
AccompSeq_EndMarkerCalcTime:
	.byte 0x21, 0x60, 0x1d, 0x36, 0xdc, 0xf6, 0xc9, 0xcf
	.byte 0x18, 0x63, 0x09, 0xc1, 0xb7, 0x7d, 0x3e, 0x01
	.byte 0x1b, 0x17, 0xda, 0xf6
AccompSeq_EndMarkerAdvance:
	.byte 0xc1, 0xb7, 0x7d, 0x3e, 0x02, 0xd1, 0xaa, 0x7d
	.byte 0x20, 0xd8, 0x61, 0xf1, 0xaa, 0x7d, 0x50, 0x1e
	.byte 0x20, 0x00, 0x1b, 0x17, 0xda, 0xf6
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
	ldw_d16	wa, (32168)
	inc	1, wa
	stda16	(32168), wa
	cps	wa, 0
	jr	nz, 12
	pushw	wa
	ldw_d16	wa, (32166)
	inc	1, wa
	stda16	(32166), wa
	popw	wa
AccompSeq_AdvanceCheckPattern:
	calr	70
	ld	a, (xiy)
	cp	a, 135
	jr	nz, 21
	calr	157
	stda16	(32166), wa
	ld	qwa, wa
	lds	wa, 6
	stda16	(32168), wa
	calr	106
	ld	a, (xiy)
AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	.incbin "includes/romslices/v7_transplant_AccompSeq_VRAMHelperData_head.bin"
	ldw_d16 wa, (0x7da6)
	and XWA,0x00000fff
	sla xwa, 8
	add XWA,0x001e8b00
	ld XIY,XWA
	ret
ResolveVRAMAddressForVoice:
	cpdi8 (0x7d89), 0x80
	jr c, AccompSeq_ResolveVRAMFallback
	bitda 0, (0x7dd1)
	jr nz, AccompSeq_ResolveVRAMFallback
	ldw_d16 wa, (0x7da6)
	and XWA,0x00000fff
	sla XWA, 0x08
	ld XIY,XWA
	ldw_d16 wa, (0x7da8)
	and XWA,0x000000ff
	add XIY,XWA
	add XIY,0x001e8b00
	jr t, AccompSeq_ResolveVRAMDone
AccompSeq_ResolveVRAMFallback:
	ldw_d16	wa, (32166)
	ld	qwa, wa
	ldw_d16	wa, (32168)
	ld	xiy, xwa
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
	ldw_d16	wa, (32166)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 3
	add	xwa, 2001664
	ld	wa, (xwa)
	ret
AccompSeq_ReadPatternTimeSig:
	ldw_d16	wa, (32166)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 1
	add	xwa, 2001664
	ld	wa, (xwa)
	ret
AccompSeq_HandlePartTransition:
	bitda 3, (0x7d8b)
	jr z, AccompSeq_StopPart
	cpdi8 (0x7db6), 0x01
	jr z, AccompSeq_TransitionChannel2
	ldw_d16 wa, (0x7d98)
	stda16 (0x7da6), wa
	ldw_d16 wa, (0x7d9a)
	stda16 (0x7da8), wa
	jr t, AccompSeq_PartTransitionDone
AccompSeq_TransitionChannel2:
	ldw_d16	wa, (32156)
	stda16	(32166), wa
	ldw_d16	wa, (32158)
	stda16	(32168), wa
AccompSeq_PartTransitionDone:
	jr AccompSeq_DispatchReturn

AccompSeq_StopPart:
	.byte 0xc1, 0xb6, 0x7d, 0x3f, 0x01, 0x66, 0x07, 0xc1
	.byte 0x88, 0x7d, 0x3c, 0xfe, 0x68, 0x05
AccompSeq_StopPartCh2:
	.byte 0xc1, 0x88, 0x7d, 0x3c, 0xfd	; anddi8 (0x7e24), 253 (v7 patched)



AccompSeq_CheckRestart:
	.byte 0xc1, 0xb7, 0x7d, 0x3e, 0x01, 0xc1, 0x88, 0x7d
	.byte 0x21, 0xc9, 0xcc, 0x03, 0xc9, 0xd8, 0x6e, 0x09
	.byte 0xc1, 0x88, 0x7d, 0x3e, 0x01, 0x1d, 0x36, 0xe2
	.byte 0xf6
AccompSeq_DispatchReturn:
	ret

AccompSeq_CalcDeltaTime:
	ld E,A
	ldw_d16 wa, (0x7daa)
	cpda16 xwa, 0x7d80
	jr nz, AccompSeq_DeltaCompare
	ldb_d8 a, (0x7d82)
	cp A,E
	jr ugt, AccompSeq_DeltaZero
	sub E,A
	ld A,E
	jr t, AccompSeq_DeltaReturn
AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	ldw_d16	hl, (32128)
	cp	hl, wa
	jr	ugt, 23
	sub	wa, hl
	cps	wa, 1
	jr	z, 4
	ldb	a, 96
	jr	15
AccompSeq_DeltaOneAhead:
	ldb_d8	a, (32130)
	add	e, 96
	sub	e, a
	ld	a, e
	jr	2
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
	.byte 0x1e, 0xba, 0x00, 0x1e, 0xe2, 0x00, 0xd1, 0xb4
	.byte 0x7d, 0x3f, 0x10, 0x00, 0x6b, 0x05, 0x1e, 0x07
	.byte 0x01, 0x68, 0x0d
AccompSeq_Parse_Type90_Large:
	ldda32	xhl, (32176)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	304
AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	calr AccompSeq_ReadParams
	stb_d8 (0x7dbe), a
	calr AccompSeq_AdvancePosition
	stb_d8 (0x7dbf), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpdi16 (0x7db4), 0x0010
	jr ugt, AccompSeq_Parse_Type91_CalcSize
	calr AccompSeq_ResetCounters
	jr t, AccompSeq_Parse_Type91_Done
AccompSeq_Parse_Type91_CalcSize:
	ldda32	xhl, (32176)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	341
AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	.byte 0xc9, 0x8c, 0xc9, 0xcc, 0xf0, 0xf1, 0xb8, 0x7d
	.byte 0x41, 0x1e, 0xde, 0xfd, 0xf1, 0xb9, 0x7d, 0x45
	.byte 0x1e, 0xd7, 0xfd, 0xcc, 0x89, 0xc9, 0xcc, 0x0f
	.byte 0xf1, 0xba, 0x7d, 0x41, 0x85, 0x21, 0xf1, 0xbb
	.byte 0x7d, 0x41, 0x1e, 0xc5, 0xfd, 0x1e, 0x6a, 0x00
	.byte 0xd1, 0xb4, 0x7d, 0x3f, 0x10, 0x00, 0x6b, 0x05
	.byte 0x1e, 0x8f, 0x00, 0x68, 0x0d
AccompSeq_Parse_TypeC0_CalcSize:
	ldda32	xhl, (32176)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	381
AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpdi16 (0x7db4), 0x0010
	jr ugt, AccompSeq_Parse_TypeC0_Finalize
	calr AccompSeq_ResetCounters
	jr t, AccompSeq_Parse_Return
AccompSeq_Parse_TypeC0_Finalize:
	ldda32	xhl, (32176)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	422
AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	stb_d8	(32184), a
	calr	64892
	stb_d8	(32185), e
	calr	64885
	stb_d8	(32186), a
	calr	64878
	stb_d8	(32187), a
	calr	64871
	stb_d8	(32188), a
	calr	64864
	stb_d8	(32189), a
	calr	64857
	ret
AccompSeq_CalcEventSize:
	ldda32 xhl, (0x7db0)
	ld WA,(XHL+0x06)
	cp WA,(XHL+0x04)
	jr c, AccompSeq_CalcSize_Negative
	jr ugt, AccompSeq_CalcSize_Positive
	ld WA,(XHL+0x02)
	.byte 0x9b, 0x00, 0xa0, 0xd8, 0x61, 0x68, 0x13
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
	stda16	(32180), wa
	ret
AccompSeq_ResetCounters:
	.byte 0xe1, 0xb0, 0x7d, 0x23	; ldda32 xhl, (0x7e4c) (v7 patched)

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
	stda16	(32166), hl
	push	xhl
	calr	64814
	pop	xhl
	lds	iy, 6
	ret
AccompSeq_ProcessNoteOn6:
	ldb_d8 a, (0x7db8)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldb_d8 a, (0x7dba)
	ld E,A
	call AccompSeq_CheckVelocityFlags
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbb)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbc)
	cps a, 0
	jr nz, AccompSeq_NoteOn6_VelClamp
	ldb A, 0x01
AccompSeq_NoteOn6_VelClamp:
	stb_dri A, 0x07, 0xec, 0xf4

	.byte 0x1e, 0xe7, 0x01	; calr AccompSeq_AdvanceBufferPtr (v7 displacement)

	.byte 0xc1, 0xbd, 0x7d, 0x21	; ldb_d8 a, (0x7e59) (v7 patched)

	stb_dri A, 0x07, 0xec, 0xf4

	.byte 0x1e, 0xdb, 0x01	; calr AccompSeq_AdvanceBufferPtr (v7 displacement)

	stb_dri E, 0x07, 0xec, 0xf4

	.byte 0x1e, 0xd3, 0x01	; calr AccompSeq_AdvanceBufferPtr (v7 displacement)

	ld (xhl + 4), iy

	ret



AccompSeq_ProcessNoteOn8:
	ldb_d8 a, (0x7db8)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldb_d8 a, (0x7dba)
	ld E,A
	calr AccompSeq_CheckVelFlagsExtended
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbb)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbc)
	cps a, 0
	jr nz, .Lc_f6de79
	ldb A, 0x01
AccompSeq_NoteOn8_VelClamp:
.Lc_f6de79:
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbd)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbe)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbf)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	stb_dri e, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ret
AccompSeq_ProcessNotePorta:
	ldb_d8 a, (0x7db8)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldb_d8 a, (0x7dba)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbb)
	calr AccompSeq_PortaFadeOut
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ldb_d8 a, (0x7db8)
	cp A,0xd0
	jr nz, AccompSeq_NotePorta_Done
	ldb_d8 a, (0x7db9)
	cps a, 5
	jr nz, AccompSeq_NotePorta_Done
	ldb_d8 a, (0x7dbb)
	push XIY
	ldda32 xiy, (0x7dd8)
	ld (XIY),A
	pop XIY
AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	ldb_d8 a, (0x7db8)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldb_d8 a, (0x7dba)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbb)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbc)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ldb_d8 a, (0x7dbd)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ldb_d8 a, (0x7db8)
	cp A,0xc0
	jr nz, AccompSeq_NoteOn5_Return
	ldb_d8 a, (0x7dba)
	and A,0x7f
	bitda 0, (0x7dbb)
	jr z, AccompSeq_NoteOn5_StoreProgram
	or A,0x80
AccompSeq_NoteOn5_StoreProgram:
	push	xiy
	ldda32	xiy, (32172)
	ld	(xiy), a
	pop	xiy
AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	ldb_d8 a, (0x7db9)
	ei 0x06
	subda8 a, (0x046b)
	jr ugt, AccompSeq_ResolveCh_Store
	ldb A, 0x01
	stb_d8 (0x7db9), a
	cpdi8 (0x046d), 0x00
	jr z, AccompSeq_ResolveCh_AddOffset
	xor A,A
	jr t, AccompSeq_ResolveCh_AddOffset
AccompSeq_ResolveCh_Store:
	stb_d8	(32185), a
AccompSeq_ResolveCh_AddOffset:
	.byte 0xc1, 0x6d, 0x04, 0x20, 0xc8, 0x81, 0xf3, 0x07
	.byte 0xec, 0xf4, 0x41, 0x1e, 0x83, 0x00, 0xc1, 0x60
	.byte 0x7d, 0x20, 0xc8, 0xf1, 0x6f, 0x04, 0xf1, 0x60
	.byte 0x7d, 0x41
AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	anddi8 (0x3349), 0xfd
	anddi8 (0x3349), 0xfb
	cp A,0x78
	jr c, .Lc_f6dfb2
	ordi8 (0x3349), 0x04
AccompSeq_VelFlags_CheckProgram:
.Lc_f6dfb2:
	push XIY
	ldda32 xiy, (0x7dac)
	ld W,(XIY)
	cp W,0xf0
	jr c, AccompSeq_VelFlags_CallDispatch
	ordi8 (0x3349), 0x04
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
	ordi8 (0x3349), 0x02
	pushw wa
	ldb_d8 a, (0x7dbe)
	stb_d8 (0x334a), a
	ldb_d8 a, (0x7dbf)
	stb_d8 (0x334b), a
	popw wa
	anddi8 (0x3349), 0xfb
	cp A,0x78
	jr c, .Lc_f6dff5
	ordi8 (0x3349), 0x04
AccompSeq_ExtVelFlags_CheckProg:
.Lc_f6dff5:
	push XIY
	ldda32 xiy, (0x7dac)
	ld W,(XIY)
	cp W,0xf0
	jr c, AccompSeq_ExtVelFlags_Dispatch
	ordi8 (0x3349), 0x04
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
	bitda 2, (0x7d83)
	jr nz, .Lc_f6e024
	jr t, AccompSeq_FadeOut_Return
AccompSeq_FadeOut_Active:
.Lc_f6e024:
	bitda 7, (0x7d88)
	jr z, AccompSeq_FadeOut_Return
	ldw_d16 wa, (0x7dd4)
	dec 1,WA
	stda16 (0x7dd4), wa
	cp WA,0xffff
	jr nz, AccompSeq_FadeOut_Periodic
	anddi8 (0x7d88), 0x7f
	call AccompSeq_StopSequence
	jr t, AccompSeq_FadeOut_Return
AccompSeq_FadeOut_Periodic:
	and wa, 0x7
	cps wa, 0
	jr nz, AccompSeq_FadeOut_Return
	call AccompSeq_FadeOutApplyVol

AccompSeq_FadeOut_Return:
	ret

AccompSeq_FadeOutApplyVol:
	bitda 0, (0x7d88)
	jr z, .Lc_f6e07c
	ldb_d8 l, (0x7dd6)
	xor H,H
	ldw_d16 wa, (0x7dd4)
	mul xwa, xhl
	ld DE,QWA
	ldw HL, 0x0800
	ld QWA,DE
	div xwa, xhl
	ld DE,QWA
	ld E,A
	ldb W, 0x05
	ldb A, 0xd1
	call AccompSeq_SendMidiEvent
AccompSeq_FadeOut_Ch2Volume:
.Lc_f6e07c:
	bitda 1, (0x7d88)
	jr z, AccompSeq_FadeOut_ChReturn
	ldb_d8 l, (0x7dd7)
	xor H,H
	ldw_d16 wa, (0x7dd4)
	mul xwa, xhl
	ld DE,QWA
	ldw HL, 0x0800
	ld QWA,DE
	div xwa, xhl
	ld DE,QWA
	ld E,A
	ldb W, 0x05
	ldb A, 0xd2
	call AccompSeq_SendMidiEvent
AccompSeq_FadeOut_ChReturn:
	ret

AccompSeq_PortaFadeOut:
	bitda 7, (0x7d88)
	jr z, AccompSeq_PortaFade_Return
	ldb_d8 w, (0x7db8)
	cp W,0xd0
	jr nz, AccompSeq_PortaFade_Return
	ldb_d8 w, (0x7db9)
	cps w, 5
	jr nz, AccompSeq_PortaFade_Return
	push XHL
	push XDE
	ldb_d8 l, (0x7dbb)
	xor H,H
	ldw_d16 wa, (0x7dd4)
	.byte 0xdb, 0x40, 0xd7, 0xe2, 0x8a, 0x33, 0x00, 0x08
	.byte 0xd7, 0xe2, 0x9a, 0xdb, 0x50, 0xd7, 0xe2, 0x8a
	.byte 0x5a, 0x5b
AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	ordi8 (0x7e79), 0x02
	jr t, AccompSeq_ManualMidi_CheckAllNotes
AccompSeq_ManualMidiMode2:
	ordi8 (0x7e79), 0x08



AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7f
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cps h, 3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ldb_d8	a, (49122)
	push	xwa
	push	xhl
	call	16193008
	call	16190484
	stdi8	(49122), 1
	cps	h, 0
	jr	z, 14
	stdi8	(49122), 2
	cps	h, 1
	jr	z, 5
	stdi8	(49122), 4
AccompSeq_ManualMidi_SetChannel:
	pop	xhl
	call	16179781
	pop	xwa
	stb_d8	(49122), a
AccompSeq_ManualMidi_ClearFlags:
	.byte 0xc1, 0x79, 0x7e, 0x3c, 0xfd	; anddi8 (0x7f15), 253 (v7 patched)

	.byte 0xc1, 0x79, 0x7e, 0x3c, 0xf7	; anddi8 (0x7f15), 247 (v7 patched)

	ret



AccompSeq_LargeCodeBlock1:
	.byte 0xb3, 0x45, 0xbb, 0x01, 0x44, 0xc1, 0xba, 0x7d
	.byte 0x21, 0xbb, 0x02, 0x41, 0xc1, 0xbb, 0x7d, 0x21
	.byte 0xbb, 0x03, 0x41, 0xc1, 0xbc, 0x7d, 0x21, 0xbb
	.byte 0x04, 0x41, 0x1e, 0x01, 0x00, 0x0e, 0xcd, 0x33
	.byte 0x07, 0x66, 0x06, 0xcc, 0xce, 0x10, 0xcd, 0xcc
	.byte 0x7f, 0x0e, 0x21, 0x9f, 0x20, 0x7f, 0x25, 0x7f
	.byte 0x1e, 0x0b, 0x00, 0x0e, 0x21, 0xdf, 0x20, 0x7f
	.byte 0x25, 0x7f, 0x1e, 0x01, 0x00, 0x0e, 0x2d, 0x43
	.byte 0x50, 0x7a, 0x00, 0x00, 0x06, 0x06, 0x9b, 0x04
	.byte 0x25, 0x9b, 0x02, 0x21, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x45, 0x1e, 0x8c, 0xfe, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x44, 0x1e, 0x84, 0xfe, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x41, 0x1e, 0x7c, 0xfe, 0xbb, 0x04, 0x55, 0x06
	.byte 0x00, 0x4d, 0x0e, 0xd8, 0xa8, 0xf1, 0x68, 0x04
	.byte 0x50, 0xf1, 0x6a, 0x04, 0x41, 0xf1, 0x80, 0x7d
	.byte 0x50, 0xf1, 0x82, 0x7d, 0x41, 0x0e, 0xc1, 0xc6
	.byte 0x7d, 0x21, 0xc1, 0x34, 0x04, 0x20, 0xf1, 0xc6
	.byte 0x7d, 0x40, 0xc8, 0xf1, 0x66, 0x42, 0xf1, 0xc3
	.byte 0x7d, 0xc8, 0x66, 0x3c, 0xc1, 0xc3, 0x7d, 0x3c
	.byte 0xfe, 0xc1, 0xc4, 0x7d, 0x27, 0xc1, 0xc5, 0x7d
	.byte 0x26, 0xc1, 0x88, 0x7d, 0x21, 0xc0, 0x03, 0xc1
	.byte 0xc9, 0xd8, 0x6e, 0x06, 0x1d, 0x0b, 0xe3, 0xf6
	.byte 0x68, 0x04, 0x1d, 0x72, 0xe5, 0xf6, 0x06, 0x06
	.byte 0xc1, 0x15, 0x04, 0x23, 0xf1, 0x6a, 0x04, 0x43
	.byte 0xf1, 0x72, 0x04, 0x43, 0xd8, 0xa8, 0xc1, 0x16
	.byte 0x04, 0x21, 0xf1, 0x68, 0x04, 0x50, 0x06, 0x00
	.byte 0x0e
AccompSeq_UpdatePosition:
	cpdi8 (0x7db6), 0x00
	jr nz, .Lc_f6e215
	ldda32 xwa, (0x7dc9)
	anddi8 (0x7dd1), 0xfe
	jr t, AccompSeq_UpdatePos_Store
AccompSeq_UpdatePos_Part2:
.Lc_f6e215:
	ldda32 xwa, (0x7dcd)
	anddi8 (0x7dd1), 0xfe



AccompSeq_UpdatePos_Store:
	stda16	(32168), wa
	ld	wa, qwa
	stda16	(32166), wa
	ret
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
	.byte 0x1b, 0xd9, 0xe6, 0xf6, 0xc1, 0xe1, 0xbf, 0x21
	.byte 0xc9, 0xcf, 0x09, 0x7e, 0xa0, 0x00, 0xc1, 0xe3
	.byte 0xbf, 0x21, 0xc9, 0x33, 0x07, 0x66, 0x16, 0x1e
	.byte 0xfa, 0x03, 0x27, 0x7f, 0x26, 0x03, 0xc1, 0xe2
	.byte 0xbf, 0x21, 0xc9, 0x33, 0x07, 0x66, 0x03, 0x1e
	.byte 0x83, 0x03, 0x78, 0x81, 0x00, 0xc9, 0xcc, 0x3f
	.byte 0xc9, 0xd8, 0x66, 0x7a, 0xc1, 0xe2, 0xbf, 0x21
	.byte 0xc1, 0xe3, 0xbf, 0xc1, 0xc9, 0xcc, 0x3f, 0xc9
	.byte 0xd8, 0x66, 0x6b, 0xc8, 0xd0, 0xd8, 0x8b, 0x44
	.byte 0x36, 0xe8, 0xf6, 0x00, 0xc3, 0x07, 0xf0, 0xec
	.byte 0x26, 0xc1, 0x12, 0xfd, 0x27, 0xcf, 0xcf, 0x11
	.byte 0x66, 0x54, 0xcf, 0xcf, 0x12, 0x66, 0x4f, 0xcf
	.byte 0xcf, 0x0f, 0x66, 0x05, 0xcf, 0xcf, 0x10, 0x6e
	.byte 0x24, 0x44, 0x00, 0x8a, 0x1e, 0x00, 0xcf, 0xcf
	.byte 0x10, 0x6e, 0x06, 0xec, 0xc8, 0x10, 0x00, 0x00
	.byte 0x00, 0xce, 0xee, 0x01, 0xc3, 0x03, 0xf0, 0xed
	.byte 0x27, 0xce, 0x61, 0xc3, 0x03, 0xf0, 0xed, 0x26
	.byte 0xcf, 0xcf, 0x0e, 0x6b, 0x21, 0x1d, 0x71, 0x10
	.byte 0xf7, 0xce, 0xd8, 0x66, 0x19, 0xc1, 0x6f, 0x7e
	.byte 0x3f, 0x00, 0x6e, 0x12, 0xf1, 0xde, 0x7d, 0xc8
	.byte 0x66, 0x05, 0x1e, 0xac, 0x02, 0x68, 0x07, 0x1e
	.byte 0x03, 0x03, 0x1d, 0x76, 0xe8, 0xf6, 0x0e
AccompSeq_PostNoteProcess:
	cps h, 0
	jr z, AccompSeq_PostNote_Return
	cpdi8 (0x7e6f), 0x00
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange
AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr	21
	stb_d8	(32137), l
	stb_d8	(32138), h
	calr	15
	calr	80
	calr	299
	calr	501
	ret
AccompSeq_ResetMidiState:
	call Voice_DecodeNoteParam
	ret

AccompSeq_LookupStyleData:
	cp	l, 128
	jr	c, 34
	and	l, 15
	call	16192944
	and	xhl, 65535
	ld	xwa, xhl
	add	xwa, 2000896
	stda16	(32142), wa
	ld	wa, qwa
	stda16	(32140), wa
	jr	28
AccompSeq_LookupStyle_Internal:
	call	16191886
	xor	xwa, xwa
	ldw	wa, 32
	mul	xwa, xhl
	add	xwa, 14991782
	stda16	(32142), wa
	ld	wa, qwa
	stda16	(32140), wa
AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	ldw_d16 wa, (0x7d8c)
	ld QWA,WA
	ldw_d16 wa, (0x7d8e)
	ld XIY,XWA
	cpdi8 (0x7d89), 0x80
	jr nc, AccompSeq_LoadParams_Alt
	.byte 0x8d, 0x00, 0x21, 0xc9, 0xcc, 0x1d, 0xf1, 0x8b
	.byte 0x7d, 0x41, 0xad, 0x01, 0x20, 0xe8, 0xc8, 0x06
	.byte 0x00, 0x00, 0x00, 0xf1, 0x92, 0x7d, 0x50, 0xd7
	.byte 0xe2, 0x88, 0xf1, 0x90, 0x7d, 0x50, 0xad, 0x05
	.byte 0x20, 0xf1, 0x9a, 0x7d, 0x50, 0xd7, 0xe2, 0x88
	.byte 0xf1, 0x98, 0x7d, 0x50, 0x8d, 0x10, 0x21, 0xc9
	.byte 0x33, 0x00, 0x66, 0x05, 0xc1, 0x8b, 0x7d, 0x3e
	.byte 0x02
AccompSeq_LoadParams_Bit0Set:
	ld	xwa, (xiy+17)
	add	xwa, 6
	stda16	(32150), wa
	ld	wa, qwa
	stda16	(32148), wa
	ld	xwa, (xiy+21)
	stda16	(32158), wa
	ld	wa, qwa
	stda16	(32156), wa
	jr	23
AccompSeq_LoadParams_Alt:
	.byte 0x8d, 0x00, 0x21, 0xc9, 0xcc, 0x1d, 0xf1, 0x8b
	.byte 0x7d, 0x41, 0x9d, 0x03, 0x20, 0xf1, 0x90, 0x7d
	.byte 0x50, 0xd8, 0xae, 0xf1, 0x92, 0x7d, 0x50
AccompSeq_LoadParams_OverrideCheck:
	.byte 0xf1, 0xc3, 0x7d, 0xc8, 0x66, 0x4f, 0xd1, 0x90
	.byte 0x7d, 0x20, 0xd7, 0xe2, 0x98, 0xd1, 0x92, 0x7d
	.byte 0x20, 0xf1, 0xc9, 0x7d, 0x60, 0xd1, 0x94, 0x7d
	.byte 0x20, 0xd7, 0xe2, 0x98, 0xd1, 0x96, 0x7d, 0x20
	.byte 0xf1, 0xcd, 0x7d, 0x60, 0xd8, 0xa8, 0xc1, 0x33
	.byte 0x04, 0x21, 0xc9, 0x69, 0xc9, 0xcc, 0x07, 0xd8
	.byte 0xee, 0x02, 0x45, 0xe8, 0xeb, 0xf6, 0x00, 0xe3
	.byte 0x07, 0xf4, 0xe0, 0x20, 0xe8, 0xc8, 0x06, 0x00
	.byte 0x00, 0x00, 0xf1, 0x92, 0x7d, 0x50, 0xf1, 0x96
	.byte 0x7d, 0x50, 0xd7, 0xe2, 0x88, 0xf1, 0x90, 0x7d
	.byte 0x50, 0xf1, 0x94, 0x7d, 0x50
AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	ldb A, 0xd0
	ldb W, 0x03
	ldb E, 0x00
	calr AccompSeq_WriteMidiToBuffer
	stdi8 (0x7dd6), 0x7f
	stdi8 (0x7dd7), 0x7f
	ldw_d16 wa, (0x7d8c)
	ld QWA,WA
	ldw_d16 wa, (0x7d8e)
	ld XIY,XWA
	bitda 0, (0x7d8b)
	jr z, AccompSeq_InitMidi_Ch2
	ld WA,(XIY+0x09)
	ld E,W
	ld W,A
	ldb A, 0xc1
	stb_d8 (0x7da4), w
	and E,0x0f
	bit 0x07,W
	jr z, AccompSeq_InitMidi_Ch1Flags
	or E,0x10
	and W,0x7f
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
	.byte 0xf1, 0x8b, 0x7d, 0xc9, 0x66, 0x50, 0x9d, 0x19
	.byte 0x20, 0xc8, 0x8d, 0xc9, 0x88, 0x21, 0xc2, 0xf1
	.byte 0xa5, 0x7d, 0x40, 0xcd, 0xcc, 0x0f, 0xc8, 0x33
	.byte 0x07, 0x66, 0x06, 0xcd, 0xce, 0x10, 0xc8, 0xcc
	.byte 0x7f
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
	anddi8 (0x7d88), 0x7f
	xor WA,WA
	ei 0x06
	stda16 (0x0468), wa
	stb_d8 (0x046a), a
	stb_d8 (0x0472), a
	bitda 2, (0x041f)
	jr nz, AccompSeq_InitPlay_SetCounters
	ordi8 (0x041f), 0x01
AccompSeq_InitPlay_SetCounters:
	di
	stda16	(32160), wa
	stda16	(32162), wa
	ldb_d8	a, (32136)
	ldb_d8	w, (32139)
	bit	0, w
	jr	z, 3
	or	a, 1
AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	stb_d8	(32136), a
	ldb_d8	w, (49122)
	ldb	a, 1
	bit	0, w
	jr	nz, 9
	ldb	a, 2
	bit	1, w
	jr	nz, 2
	ldb	a, 4
AccompSeq_InitPlay_Return:
	ret

AccompSeq_ReinitPart:
	pushw	hl
	ldb_d8	a, (32136)
	and	a, 252
	stb_d8	(32136), a
	calr	466
	popw	hl
	calr	64926
	stb_d8	(32137), l
	stb_d8	(32138), h
	calr	64920
	calr	64985
	calr	65204
	calr	65406
	ret
AccompSeq_HandleSpecialMode:
	ldb_d8	a, (32136)
	and	a, 3
	jr	z, 16
	pushw	hl
	ldb_d8	a, (32136)
	and	a, 252
	stb_d8	(32136), a
	calr	417
	popw	hl
	ldb_d8	a, (64786)
	cp	a, 13
	jr	z, 5
	cp	a, 14
	jr	nz, 37
	stdi8	(32367), 1
	calr	64858
	and	l, 15
	stb_d8	(32376), l
	ldb_d8	w, (49122)
	ldb	a, 1
	bit	0, w
	jr	nz, 9
	ldb	a, 2
	bit	1, w
	jr	nz, 2
	ldb	a, 4
	jr	15
	stdi8	(32422), 57
	call	16143598
	ldb	a, 8
	call	16692690
	ret
AccompSeq_OutputEvent:
	pushw HL
	pushw HL
	call Voice_DecodeNoteChannel
	ld BC,HL
	.byte 0x4b, 0xdb, 0x88, 0xd9, 0x8b, 0xd1, 0xaa, 0x28
	.byte 0x3f, 0x00, 0x00, 0x6e, 0x0e, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x8a, 0x6e, 0x15, 0xc1, 0x65, 0x0d, 0x3f
	.byte 0x02, 0x6e, 0x0e
AccompSeq_Output_CheckFilter:
	.byte 0xf1, 0x79, 0x7e, 0xcb, 0x6e, 0x08, 0x28, 0x2b
	.byte 0x1d, 0x10, 0x9f, 0xfc, 0x4b, 0x48
AccompSeq_Output_CheckManual:
	.byte 0xf1, 0x79, 0x7e, 0xc9, 0x6e, 0x04, 0x1d, 0x89
	.byte 0x54, 0xfd
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
	.byte 0xdd, 0x61, 0xd9, 0xf5, 0x63, 0x03, 0x9b, 0x00
	.byte 0x25, 0x0e
	ldb_d8 a, (0xbfe2)
	bit 0x07,A
	jr nz, .Lc_f6e66d
	anddi8 (0x7dde), 0xfe
	jr t, .Lc_f6e6a9
.Lc_f6e66d:
	ordi8 (0x7dde), 0x01
	ldb_d8 a, (0x7e6f)
	cps a, 0
	jr z, .Lc_f6e682
	ldb A, 0x00
	stb_d8 (0x7e6f), a
	jr t, .Lc_f6e6a9
.Lc_f6e682:
	ldb_d8 a, (0x7d88)
	and A,0x03
	cps a, 0
	jr z, .Lc_f6e6a9
	bitda 2, (0x7d8b)
	jr z, .Lc_f6e6a6
	bitda 7, (0x7d88)
	jr nz, .Lc_f6e6a6
	stdi16 (0x7dd4), 0x0800
	ordi8 (0x7d88), 0x80
	jr t, .Lc_f6e6a9
.Lc_f6e6a6:
	calr AccompSeq_CleanupSequence
.Lc_f6e6a9:
	ret
AccompSeq_AllNotesOffImpl:
	ldb_d8 a, (0x7d88)
	and A,0x03
	cps a, 0
	jr z, AccompSeq_AllNotesOff_Send
	bitda 2, (0x7d8b)
	jr z, AccompSeq_AllNotesOff_Stop
	bitda 7, (0x7d88)
	jr nz, AccompSeq_AllNotesOff_Stop
	stdi16 (0x7dd4), 0x0800
	ordi8 (0x7d88), 0x80
	jr t, AccompSeq_AllNotesOff_Send
AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ldb l, 0x7f
	ldb h, 0x3
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	ldb_d8	a, (32367)
	cps	a, 0
	jr	z, 6
	ldb	a, 0
	stb_d8	(32367), a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	ldb_d8 a, (0xbfe1)
	cp A,0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ldb_d8 a, (0xbfe2)
	andda8 a, (0xbfe3)
	and A,0x03
	cps a, 0
	jr z, AccompSeq_GuardedNote_Return
	cpdi8 (0x8c98), 0x13
	jr z, AccompSeq_GuardedNote_Return
	cpdi8 (0x8c9c), 0xc8
	jr z, AccompSeq_GuardedNote_Return
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	xor WA,WA
	ldb A, 0xc8
	call UI_PostModeChangeEvent
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
AccompSeq_GuardedNote_Return:
	ret


AccompSeq_CleanupSequence:
	ldb_d8 a, (0x7d88)
	and A,0x03
	cps a, 0
	jr z, .Lc_f6e748
	anddi8 (0x7d88), 0x7f
	ordi8 (0x041f), 0x08
	ldb_d8 a, (0x7d88)
	and A,0xfc
	stb_d8 (0x7d88), a
	calr AccompSeq_SendAllOff
AccompSeq_Cleanup_ClearFlags:
.Lc_f6e748:
	anddi8 (0x7dd2), 0xfe
	anddi8 (0x7dd3), 0xfe

	ret



AccompSeq_SendAllOff:
	ldb	a, 144
	ldb	w, 127
	ldb	e, 127
	calr	65239
	ldb	a, 208
	ldb	w, 3
	ldb	e, 0
	calr	65230
	stdi8	(32214), 127
	stdi8	(32215), 127
	ld	xhl, 31312
	ld	wa, (xhl+4)
	ld	(xhl+6), wa
	ldw	wa, 246
	ld	(xhl+8), wa
	ld	xhl, 31568
	ld	wa, (xhl+4)
	ld	(xhl+6), wa
	ldw	wa, 246
	ld	(xhl+8), wa
	ldb	a, 8
	xor	w, w
	ld	xhl, 31952
AccompSeq_SendAllOff_Loop1:
	ld	(xhl), w
	add	hl, 9
	dec	1, a
	cps	a, 0
	jr	nz, -12
	ldb	a, 8
	xor	w, w
	ld	xhl, 32024
AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop2
	ret

AccompSeq_MidiFilterCodeBlock:
	.incbin "includes/romslices/v7_transplant_AccompSeq_MidiFilterCodeBlock.bin"
AccompSeq_ProcessChordChange:
	anddi8 (0x7dd2), 0xfe
	anddi8 (0x7dd3), 0xfe
	anddi8 (0x7dc3), 0xfc
	pushw hl
	calr AccompSeq_CompareChord
	popw hl
	ldb_d8 a, (0x7d88)
	and A,0x03
	cps a, 0
	jr nz, AccompSeq_ChordChange_Reinit
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call 0xfdb4ea
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	calr AccompSeq_InitPartFull
	jr t, AccompSeq_ChordChange_CheckOverride
AccompSeq_ChordChange_Reinit:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16626922
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	calr	64689
AccompSeq_ChordChange_CheckOverride:
	.byte 0xf1, 0xc3, 0x7d, 0xc9, 0x6e, 0x10, 0xf1, 0xc3
	.byte 0x7d, 0xc8, 0x66, 0x13, 0xc1, 0xd2, 0x7d, 0x3e
	.byte 0x01, 0xc1, 0xd3, 0x7d, 0x3e, 0x01
AccompSeq_ChordChange_ApplyOverride:
	.byte 0xc1, 0xc3, 0x7d, 0x3c, 0xfd	; anddi8 (0x7e5f), 253 (v7 patched)

	.byte 0x1d, 0x3f, 0xe9, 0xf6	; call AccompSeq_SetupChannels (v7 addr)



AccompSeq_ChordChange_Return:
	ret

AccompSeq_CompareChord:
	bitda 0, (0x31e7)
	jr z, AccompSeq_CompareChord_Return
	bitda 2, (0x28b2)
	jr nz, AccompSeq_CompareChord_Return
	stb_d8 (0x7dc4), l
	stb_d8 (0x7dc5), h
	ldw_d16 wa, (0x7d8e)
	pushw wa
	ldw_d16 wa, (0x7d8c)
	pushw wa
	calr AccompSeq_ResetMidiState
	calr AccompSeq_LookupStyleData
	ldw_d16 wa, (0x7d8c)
	ld QWA,WA
	ldw_d16 wa, (0x7d8e)
	ld XIY,XWA
	.byte 0x8d, 0x00, 0x21, 0xc9, 0x33, 0x04, 0x66, 0x1a
	.byte 0xc1, 0x33, 0x04, 0x21, 0xc1, 0x16, 0x04, 0x20
	.byte 0xc8, 0x61, 0xc8, 0xf1, 0x66, 0x07, 0xc1, 0xc3
	.byte 0x7d, 0x3e, 0x02, 0x68, 0x05
AccompSeq_CompareChord_Match:
	.byte 0xc1, 0xc3, 0x7d, 0x3e, 0x01	; ordi8 0x7e5f, 1 (v7 patched)



AccompSeq_CompareChord_RestorePos:
	popw	wa
	stda16	(32140), wa
	popw	wa
	stda16	(32142), wa
AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	.byte 0x06, 0x06, 0xc1, 0x15, 0x04, 0x23, 0xf1, 0xc7
	.byte 0x7d, 0x43, 0xd8, 0xa8, 0xc1, 0x16, 0x04, 0x21
	.byte 0xf1, 0xc8, 0x7d, 0x41, 0xf1, 0x6a, 0x04, 0x43
	.byte 0xf1, 0x72, 0x04, 0x43, 0xf1, 0x68, 0x04, 0x50
	.byte 0x06, 0x00, 0xf1, 0x88, 0x7d, 0xc8, 0x66, 0x5a
	.byte 0xf1, 0xb6, 0x7d, 0x00, 0x00, 0x40, 0xa4, 0x7d
	.byte 0x00, 0x00, 0xf1, 0xac, 0x7d, 0x60, 0x40, 0xd6
	.byte 0x7d, 0x00, 0x00, 0xf1, 0xd8, 0x7d, 0x60, 0xd1
	.byte 0x90, 0x7d, 0x20, 0xf1, 0xa6, 0x7d, 0x50, 0xd1
	.byte 0x92, 0x7d, 0x20, 0xf1, 0xa8, 0x7d, 0x50, 0xd1
	.byte 0xa0, 0x7d, 0x20, 0xf1, 0xaa, 0x7d, 0x50, 0xc1
	.byte 0xd2, 0x7d, 0x21, 0xf1, 0xd1, 0x7d, 0x41, 0x1e
	.byte 0x81, 0x00, 0xc1, 0xd1, 0x7d, 0x21, 0xf1, 0xd2
	.byte 0x7d, 0x41, 0xd1, 0xaa, 0x7d, 0x20, 0xf1, 0xa0
	.byte 0x7d, 0x50, 0xd1, 0xa8, 0x7d, 0x20, 0xf1, 0x92
	.byte 0x7d, 0x50, 0xd1, 0xa6, 0x7d, 0x20, 0xf1, 0x90
	.byte 0x7d, 0x50
AccompSeq_SetupCh2:
	.byte 0xf1, 0x88, 0x7d, 0xc9, 0x66, 0x5a, 0xf1, 0xb6
	.byte 0x7d, 0x00, 0x01, 0x40, 0xa5, 0x7d, 0x00, 0x00
	.byte 0xf1, 0xac, 0x7d, 0x60, 0x40, 0xd7, 0x7d, 0x00
	.byte 0x00, 0xf1, 0xd8, 0x7d, 0x60, 0xd1, 0x94, 0x7d
	.byte 0x20, 0xf1, 0xa6, 0x7d, 0x50, 0xd1, 0x96, 0x7d
	.byte 0x20, 0xf1, 0xa8, 0x7d, 0x50, 0xd1, 0xa2, 0x7d
	.byte 0x20, 0xf1, 0xaa, 0x7d, 0x50, 0xc1, 0xd3, 0x7d
	.byte 0x21, 0xf1, 0xd1, 0x7d, 0x41, 0x1e, 0x21, 0x00
	.byte 0xc1, 0xd1, 0x7d, 0x21, 0xf1, 0xd3, 0x7d, 0x41
	.byte 0xd1, 0xaa, 0x7d, 0x20, 0xf1, 0xa2, 0x7d, 0x50
	.byte 0xd1, 0xa8, 0x7d, 0x20, 0xf1, 0x96, 0x7d, 0x50
	.byte 0xd1, 0xa6, 0x7d, 0x20, 0xf1, 0x94, 0x7d, 0x50
AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	lds bc, 0

	.byte 0xc1, 0xc8, 0x7d, 0x24	; ldb_d8 d, (0x7e64) (v7 patched)

	.byte 0xc1, 0xc7, 0x7d, 0x25	; ldb_d8 e, (0x7e63) (v7 patched)

	.byte 0xc1, 0xb7, 0x7d, 0x3c, 0xfe	; anddi8 (0x7e53), 254 (v7 patched)



AccompSeq_SeqParse_Loop:
	bitda 0, (0x7db7)
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
	.byte 0x1e, 0x9e, 0xfc, 0xc1, 0xb7, 0x7d, 0x3e, 0x01
	.byte 0x68, 0xa3
AccompSeq_SeqParse_TimeAdvance:
	.byte 0xd1, 0xaa, 0x7d, 0x21, 0xd9, 0x61, 0xcb, 0x8a
	.byte 0xcb, 0xd3, 0xd9, 0xf2, 0x6f, 0x07, 0xc1, 0xb7
	.byte 0x7d, 0x3e, 0x01, 0x68, 0x8e
AccompSeq_SeqParse_TimeStore:
	incdi16	1, (32170)
	calr	61490
	jr	-123
AccompSeq_SeqParse_MidiEvent:
	.byte 0x1e, 0x12, 0xf0, 0xd1, 0xaa, 0x7d, 0x21, 0xc9
	.byte 0x8b, 0xc1, 0xaa, 0x7d, 0x22, 0xd9, 0xf2, 0x6f
	.byte 0x09, 0xc1, 0xb7, 0x7d, 0x3e, 0x01, 0x1b, 0x31
	.byte 0xea, 0xf6
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
	.byte 0xc9, 0xcf, 0xc0, 0x6e, 0x69, 0x21, 0x01, 0xc1
	.byte 0xb6, 0x7d, 0x3f, 0x00, 0x66, 0x02, 0x21, 0x02
AccompSeq_SeqParse_ProgChg_SetCh:
	.byte 0xc9, 0xce, 0xc0, 0xf1, 0xb8, 0x7d, 0x41, 0x1e
	.byte 0xbe, 0xef, 0x1e, 0xbb, 0xef, 0x85, 0x21, 0xf1
	.byte 0xb9, 0x7d, 0x41, 0x1e, 0xb2, 0xef, 0x85, 0x21
	.byte 0xf1, 0xba, 0x7d, 0x41, 0x1e, 0xa9, 0xef, 0x85
	.byte 0x25, 0xcd, 0xcc, 0x0f, 0xf1, 0xbb, 0x7d, 0x45
	.byte 0xf1, 0xba, 0x7d, 0xc8, 0x66, 0x03, 0xcd, 0xce
	.byte 0x10
AccompSeq_SeqParse_ProgChg_Flags:
	.byte 0xc1, 0xb8, 0x7d, 0x21, 0xc1, 0xb9, 0x7d, 0x20
	.byte 0x1e, 0xe3, 0xfa, 0x1e, 0x89, 0xef, 0x1e, 0x86
	.byte 0xef, 0x3d, 0xe1, 0xac, 0x7d, 0x25, 0xc1, 0xb9
	.byte 0x7d, 0x21, 0xc9, 0xcc, 0x7f, 0xf1, 0xba, 0x7d
	.byte 0xc8, 0x66, 0x03, 0xc9, 0xce, 0x80
AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	.byte 0xc9, 0xcc, 0x0f, 0xf1, 0xb9, 0x7d, 0x41, 0x21
	.byte 0x01, 0xc1, 0xb6, 0x7d, 0x3f, 0x00, 0x66, 0x02
	.byte 0x21, 0x02
AccompSeq_SeqParse_CtrlChg_SetCh:
	or	a, 208
	stb_d8	(32184), a
	calr	61262
	calr	61259
	ld	e, (xiy)
	stb_d8	(32186), e
	ldb_d8	w, (32185)
	ldb_d8	a, (32184)
	calr	64145
	calr	61239
	ldb_d8	w, (32185)
	ldb_d8	a, (32184)
	and	a, 240
	cp	a, 208
	jr	nz, 16
	cps	w, 5
	jr	nz, 12
	ldb_d8	a, (32186)
	push	xiy
	ldda32	xiy, (32216)
	ld	(xiy), a
	pop	xiy
AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	ldda32 xwa, (0x7dc9)
	cpdi8 (0x7db6), 0x00
	jr z, AccompSeq_SeqParse_TempoStore
	ldda32 xwa, (0x7dcd)
AccompSeq_SeqParse_TempoStore:
	stda16	(32168), wa
	ld	wa, qwa
	stda16	(32166), wa
	jp	16181809
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
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x84
	.byte 0x75, 0xec, 0xf6, 0x00, 0x74, 0xec, 0xf6, 0x00
	.byte 0x7a, 0xec, 0xf6, 0x00, 0x74, 0xec, 0xf6, 0x00
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

