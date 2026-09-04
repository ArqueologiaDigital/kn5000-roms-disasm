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
	and (0x7db7:16), 0xdf
	calr AccompSeq_CheckChannelActive
	bit 5, (0x7db7:16)
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
	ld	(1131:16), a
	ld	wa, (1128:16)
	ld	(32128:16), wa
	ld	a, (1130:16)
	ld	(32130:16), a
	ld	a, (1055:16)
	ld	(32131:16), a
	di
	ret
AccompSeq_SaveTimerSnapshot:
	ld	wa, (32128:16)
	ld	(32132:16), wa
	ld	a, (32130:16)
	ld	(32134:16), a
	ld	a, (32131:16)
	ld	(32135:16), a
	ret
AccompSeq_CheckChannelActive:
	bit 2, (0x7d83:16)
	jr nz, .Lc_f6d915
	jp AccompSeq_ChannelSetupDone
AccompSeq_SetupChannel1:
.Lc_f6d915:
	bit 0, (0x7d88:16)
	jr z, .Lc_f6d97e
	ld (0x7db6:16), 0x00
	ld XWA,0x00007a50
	ld (0x7db0:16), xwa
	ld XWA,0x00007da4
	ld (0x7dac:16), xwa
	ld XWA,0x00007dd6
	ld (0x7dd8:16), xwa
	ld wa, (0x7d90:16)
	ld (0x7da6:16), wa
	ld wa, (0x7d92:16)
	ld (0x7da8:16), wa
	ld wa, (0x7da0:16)
	ld (0x7daa:16), wa
	ld a, (0x7dd2:16)
	ld (0x7dd1:16), a
	calr AccompSeq_InitEventDispatch
	ld a, (0x7dd1:16)
	ld (0x7dd2:16), a
	ld wa, (0x7daa:16)
	ld (0x7da0:16), wa
	ld wa, (0x7da8:16)
	ld (0x7d92:16), wa
	ld wa, (0x7da6:16)
	ld (0x7d90:16), wa
AccompSeq_SetupChannel2:
.Lc_f6d97e:
	bit 1, (0x7d88:16)
	jr z, AccompSeq_ChannelSetupDone
	ld (0x7db6:16), 0x01
	ld XWA,0x00007b50
	ld (0x7db0:16), xwa
	ld XWA,0x00007da5
	ld (0x7dac:16), xwa
	ld XWA,0x00007dd7
	ld (0x7dd8:16), xwa
	ld wa, (0x7d94:16)
	ld (0x7da6:16), wa
	ld wa, (0x7d96:16)
	ld (0x7da8:16), wa
	ld wa, (0x7da2:16)
	ld (0x7daa:16), wa
	ld a, (0x7dd3:16)
	ld (0x7dd1:16), a
	calr AccompSeq_InitEventDispatch
	ld a, (0x7dd1:16)
	ld (0x7dd3:16), a
	ld wa, (0x7daa:16)
	ld (0x7da2:16), wa
	ld wa, (0x7da8:16)
	ld (0x7d96:16), wa
	ld wa, (0x7da6:16)
	ld (0x7d94:16), wa
AccompSeq_ChannelSetupDone:
	ret

AccompSeq_IncrementTickCounter:
	ld	hl, (1128:16)
	ld	a, (1130:16)
	inc	1, a
	cp	a, 96
	jr	nz, 4
	xor	a, a
	inc	1, hl
	ld	(1128:16), hl
	ld	(1130:16), a
	inc	1, (1132:16)
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
	ld	wa, (32168:16)
	inc	1, wa
	ld	(32168:16), wa
	cps	wa, 0
	jr	nz, 12
	pushw	wa
	ld	wa, (32166:16)
	inc	1, wa
	ld	(32166:16), wa
	popw	wa
AccompSeq_AdvanceCheckPattern:
	calr	70
	ld	a, (xiy)
	cp	a, 135
	jr	nz, 21
	calr	157
	ld	(32166:16), wa
	ld	qwa, wa
	lds	wa, 6
	ld	(32168:16), wa
	calr	106
	ld	a, (xiy)
AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	.byte 0xc1, 0x89
AccompSeq_VRAMHelperData_Code:
	jrl	pl, -32705
	jr	c, 5
	calr	9
	jr	6
	ld	wa, (32166:16)
	ld	iy, wa
	ret	
	ld wa, (0x7da6:16)
	and XWA,0x00000fff
	sla xwa, 8
	add XWA,0x001e8b00
	ld XIY,XWA
	ret
ResolveVRAMAddressForVoice:
	cp (0x7d89:16), 0x80
	jr c, AccompSeq_ResolveVRAMFallback
	bit 0, (0x7dd1:16)
	jr nz, AccompSeq_ResolveVRAMFallback
	ld wa, (0x7da6:16)
	and XWA,0x00000fff
	sla XWA, 0x08
	ld XIY,XWA
	ld wa, (0x7da8:16)
	and XWA,0x000000ff
	add XIY,XWA
	add XIY,0x001e8b00
	jr t, AccompSeq_ResolveVRAMDone
AccompSeq_ResolveVRAMFallback:
	ld	wa, (32166:16)
	ld	qwa, wa
	ld	wa, (32168:16)
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
	ld	wa, (32166:16)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 3
	add	xwa, 2001664
	ld	wa, (xwa)
	ret
AccompSeq_ReadPatternTimeSig:
	ld	wa, (32166:16)
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 1
	add	xwa, 2001664
	ld	wa, (xwa)
	ret
AccompSeq_HandlePartTransition:
	bit 3, (0x7d8b:16)
	jr z, AccompSeq_StopPart
	cp (0x7db6:16), 0x01
	jr z, AccompSeq_TransitionChannel2
	ld wa, (0x7d98:16)
	ld (0x7da6:16), wa
	ld wa, (0x7d9a:16)
	ld (0x7da8:16), wa
	jr t, AccompSeq_PartTransitionDone
AccompSeq_TransitionChannel2:
	ld	wa, (32156:16)
	ld	(32166:16), wa
	ld	wa, (32158:16)
	ld	(32168:16), wa
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
	ld wa, (0x7daa:16)
	cp wa, (0x7d80:16)
	jr nz, AccompSeq_DeltaCompare
	ld a, (0x7d82:16)
	cp A,E
	jr ugt, AccompSeq_DeltaZero
	sub E,A
	ld A,E
	jr t, AccompSeq_DeltaReturn
AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	ld	hl, (32128:16)
	cp	hl, wa
	jr	ugt, 23
	sub	wa, hl
	cps	wa, 1
	jr	z, 4
	ldb	a, 96
	jr	15
AccompSeq_DeltaOneAhead:
	ld	a, (32130:16)
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
	calr	186
	calr	226
	cpw	(32180:16), 16
	jr	ugt, 5
	calr	263
	jr	13
AccompSeq_Parse_Type90_Large:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	304
AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	calr AccompSeq_ReadParams
	ld (0x7dbe:16), a
	calr AccompSeq_AdvancePosition
	ld (0x7dbf:16), a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpw (0x7db4:16), 0x0010
	jr ugt, AccompSeq_Parse_Type91_CalcSize
	calr AccompSeq_ResetCounters
	jr t, AccompSeq_Parse_Type91_Done
AccompSeq_Parse_Type91_CalcSize:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	341
AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	ld	d, a
	and	a, 240
	ld	(32184:16), a
	calr	-546
	ld	(32185:16), e
	calr	-553
	ld	a, d
	and	a, 15
	ld	(32186:16), a
	ld	a, (xiy)
	ld	(32187:16), a
	calr	-571
	calr	106
	cpw	(32180:16), 16
	jr	ugt, 5
	calr	143
	jr	13
AccompSeq_Parse_TypeC0_CalcSize:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	381
AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpw (0x7db4:16), 0x0010
	jr ugt, AccompSeq_Parse_TypeC0_Finalize
	calr AccompSeq_ResetCounters
	jr t, AccompSeq_Parse_Return
AccompSeq_Parse_TypeC0_Finalize:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	422
AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	ld	(32184:16), a
	calr	64892
	ld	(32185:16), e
	calr	64885
	ld	(32186:16), a
	calr	64878
	ld	(32187:16), a
	calr	64871
	ld	(32188:16), a
	calr	64864
	ld	(32189:16), a
	calr	64857
	ret
AccompSeq_CalcEventSize:
	ld xhl, (0x7db0:16)
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
	ld	(32180:16), wa
	ret
AccompSeq_ResetCounters:
	ld xhl, (32176:16)

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
	ld	(32166:16), hl
	push	xhl
	calr	64814
	pop	xhl
	lds	iy, 6
	ret
AccompSeq_ProcessNoteOn6:
	ld a, (0x7db8:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld E,A
	call AccompSeq_CheckVelocityFlags
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	cps a, 0
	jr nz, AccompSeq_NoteOn6_VelClamp
	ldb A, 0x01
AccompSeq_NoteOn6_VelClamp:
	stb_dri A, 0x07, 0xec, 0xf4

	.byte 0x1e, 0xe7, 0x01	; calr AccompSeq_AdvanceBufferPtr (v7 displacement)

	.byte 0xc1, 0xbd, 0x7d, 0x21	; ldb_d8 a, (0x7e59) (v7 patched)

	stb_dri A, 0x07, 0xec, 0xf4

	calr	475

	stb_dri E, 0x07, 0xec, 0xf4

	calr	467

	ld (xhl + 4), iy

	ret



AccompSeq_ProcessNoteOn8:
	ld a, (0x7db8:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld E,A
	calr AccompSeq_CheckVelFlagsExtended
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	cps a, 0
	jr nz, .Lc_f6de79
	ldb A, 0x01
AccompSeq_NoteOn8_VelClamp:
.Lc_f6de79:
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbd:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbe:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbf:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	stb_dri e, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ret
AccompSeq_ProcessNotePorta:
	ld a, (0x7db8:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	calr AccompSeq_PortaFadeOut
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ld a, (0x7db8:16)
	cp A,0xd0
	jr nz, AccompSeq_NotePorta_Done
	ld a, (0x7db9:16)
	cps a, 5
	jr nz, AccompSeq_NotePorta_Done
	ld a, (0x7dbb:16)
	push XIY
	ld xiy, (0x7dd8:16)
	ld (XIY),A
	pop XIY
AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	ld a, (0x7db8:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbd:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ld a, (0x7db8:16)
	cp A,0xc0
	jr nz, AccompSeq_NoteOn5_Return
	ld a, (0x7dba:16)
	and A,0x7f
	bit 0, (0x7dbb:16)
	jr z, AccompSeq_NoteOn5_StoreProgram
	or A,0x80
AccompSeq_NoteOn5_StoreProgram:
	push	xiy
	ld	xiy, (32172:16)
	ld	(xiy), a
	pop	xiy
AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	ld a, (0x7db9:16)
	ei 0x06
	subda8 a, (0x046b)
	jr ugt, AccompSeq_ResolveCh_Store
	ldb A, 0x01
	ld (0x7db9:16), a
	cp (0x046d:16), 0x00
	jr z, AccompSeq_ResolveCh_AddOffset
	xor A,A
	jr t, AccompSeq_ResolveCh_AddOffset
AccompSeq_ResolveCh_Store:
	ld	(32185:16), a
AccompSeq_ResolveCh_AddOffset:
	ld	w, (1133:16)
	add	a, w
	st_rrb	a, xhl, iy
	calr	131
	ld	w, (32096:16)
	cp	a, w
	jr	nc, 4	; -> 0xF6DF9B
	ld	(32096:16), a
AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	and (0x3349:16), 0xfd
	and (0x3349:16), 0xfb
	cp A,0x78
	jr c, .Lc_f6dfb2
	or (0x3349:16), 0x04
AccompSeq_VelFlags_CheckProgram:
.Lc_f6dfb2:
	push XIY
	ld xiy, (0x7dac:16)
	ld W,(XIY)
	cp W,0xf0
	jr c, AccompSeq_VelFlags_CallDispatch
	or (0x3349:16), 0x04
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
	or (0x3349:16), 0x02
	pushw wa
	ld a, (0x7dbe:16)
	ld (0x334a:16), a
	ld a, (0x7dbf:16)
	ld (0x334b:16), a
	popw wa
	and (0x3349:16), 0xfb
	cp A,0x78
	jr c, .Lc_f6dff5
	or (0x3349:16), 0x04
AccompSeq_ExtVelFlags_CheckProg:
.Lc_f6dff5:
	push XIY
	ld xiy, (0x7dac:16)
	ld W,(XIY)
	cp W,0xf0
	jr c, AccompSeq_ExtVelFlags_Dispatch
	or (0x3349:16), 0x04
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
	bit 2, (0x7d83:16)
	jr nz, .Lc_f6e024
	jr t, AccompSeq_FadeOut_Return
AccompSeq_FadeOut_Active:
.Lc_f6e024:
	bit 7, (0x7d88:16)
	jr z, AccompSeq_FadeOut_Return
	ld wa, (0x7dd4:16)
	dec 1,WA
	ld (0x7dd4:16), wa
	cp WA,0xffff
	jr nz, AccompSeq_FadeOut_Periodic
	and (0x7d88:16), 0x7f
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
	bit 0, (0x7d88:16)
	jr z, .Lc_f6e07c
	ld l, (0x7dd6:16)
	xor H,H
	ld wa, (0x7dd4:16)
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
	bit 1, (0x7d88:16)
	jr z, AccompSeq_FadeOut_ChReturn
	ld l, (0x7dd7:16)
	xor H,H
	ld wa, (0x7dd4:16)
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
	bit 7, (0x7d88:16)
	jr z, AccompSeq_PortaFade_Return
	ld w, (0x7db8:16)
	cp W,0xd0
	jr nz, AccompSeq_PortaFade_Return
	ld w, (0x7db9:16)
	cps w, 5
	jr nz, AccompSeq_PortaFade_Return
	push XHL
	push XDE
	ld l, (0x7dbb:16)
	xor H,H
	ld wa, (0x7dd4:16)
	mul	xwa, xhl
	ld	de, qwa
	ldw	hl, 2048
	ld	qwa, de
	div	xwa, xhl
	ld	de, qwa
	pop	xde
	pop	xhl
AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	or (0x7e79:16), 0x02
	jr t, AccompSeq_ManualMidi_CheckAllNotes
AccompSeq_ManualMidiMode2:
	or (0x7e79:16), 0x08



AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7f
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cps h, 3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ld	a, (49122:16)
	push	xwa
	push	xhl
	call	16193008
	call	16190484
	ld	(49122:16), 1
	cps	h, 0
	jr	z, 14
	ld	(49122:16), 2
	cps	h, 1
	jr	z, 5
	ld	(49122:16), 4
AccompSeq_ManualMidi_SetChannel:
	pop	xhl
	call	16179781
	pop	xwa
	ld	(49122:16), a
AccompSeq_ManualMidi_ClearFlags:
	.byte 0xc1, 0x79, 0x7e, 0x3c, 0xfd	; anddi8 (0x7f15), 253 (v7 patched)

	.byte 0xc1, 0x79, 0x7e, 0x3c, 0xf7	; anddi8 (0x7f15), 247 (v7 patched)

	ret
AccompSeq_LargeCodeBlock1:
	ld	(xhl), e
	ld	(xhl+1), d
	ld	a, (32186:16)
	ld	(xhl+2), a
	ld	a, (32187:16)
	ld	(xhl+3), a
	ld	a, (32188:16)
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
	ld	xhl, 31312
	ei	0x06
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	st_rrb	e, xiy, hl
	calr	-372
	st_rrb	d, xiy, hl
	calr	-380
	st_rrb	a, xiy, hl
	calr	-388
	ld	(xhl+4), iy
	ei	0x00
	popw	iy
	ret
	lds	wa, 0
	ld	(1128:16), wa
	ld	(1130:16), a
	ld	(32128:16), wa
	ld	(32130:16), a
	ret
	ld	a, (32198:16)
	ld	w, (1076:16)
	ld	(32198:16), w
	cp	a, w
	jr	z, 66
	.byte 0xf1, 0xc3, 0x7d, 0xc8
	jr	z, 60
	.byte 0xc1, 0xc3, 0x7d, 0x3c, 0xfe
	ld	l, (32196:16)
	ld	h, (32197:16)
	ld	a, (32136:16)
	.byte 0xc0, 0x03, 0xc1
	cps	a, 0
	jr	nz, 6
	call	16179979
	jr	4
	call	16180594
	ei	0x06
	ld	c, (1045:16)
	ld	(1130:16), c
	ld	(1138:16), c
	lds	wa, 0
	ld	a, (1046:16)
	ld	(1128:16), wa
	ei	0x00
	ret
AccompSeq_UpdatePosition:
	cp (0x7db6:16), 0x00
	jr nz, .Lc_f6e215
	ld xwa, (0x7dc9:16)
	and (0x7dd1:16), 0xfe
	jr t, AccompSeq_UpdatePos_Store
AccompSeq_UpdatePos_Part2:
.Lc_f6e215:
	ld xwa, (0x7dcd:16)
	and (0x7dd1:16), 0xfe



AccompSeq_UpdatePos_Store:
	ld	(32168:16), wa
	ld	wa, qwa
	ld	(32166:16), wa
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
	jp	16180953
	ld	a, (49121:16)
	cp	a, 9
	jrl	nz, 160
	ld	a, (49123:16)
	bit	7, a
	jr	z, 22
	calr	1018
	ldb	l, 127
	ldb	h, 3
	ld	a, (49122:16)
	bit	7, a
	jr	z, 3
	calr	899
	jrl	129
	and	a, 63
	cps	a, 0
	jr	z, 122
	ld	a, (49122:16)
	andda8	a, 49123
	and	a, 63
	cps	a, 0
	jr	z, 107
	xor	w, w
	ld	hl, wa
	ld	xix, 16181302
	ld_rrb	h, xix, hl
	ld	l, (64786:16)
	cp	l, 17
	jr	z, 84
	cp	l, 18
	jr	z, 79
	cp	l, 15
	jr	z, 5
	cp	l, 16
	jr	nz, 36
	ld	xix, 2001408
	cp	l, 16
	jr	nz, 6
	add	xix, 16
	sll	h, 1
	ld_rr8b	l, xix, h
	inc	1, h
	ld_rr8b	h, xix, h
	cp	l, 14
	jr	ugt, 33
	call	16191601
	cps	h, 0
	jr	z, 25
	cp	(32367:16), 0
	jr	nz, 18
	.byte 0xf1, 0xde, 0x7d, 0xc8
	jr	z, 5
	calr	684
	jr	7
	calr	771
	call	16181366
	ret
AccompSeq_PostNoteProcess:
	cps h, 0
	jr z, AccompSeq_PostNote_Return
	cp (0x7e6f:16), 0x00
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange
AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr	21
	ld	(32137:16), l
	ld	(32138:16), h
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
	ld	(32142:16), wa
	ld	wa, qwa
	ld	(32140:16), wa
	jr	28
AccompSeq_LookupStyle_Internal:
	call	16191886
	xor	xwa, xwa
	ldw	wa, 32
	mul	xwa, xhl
	add	xwa, 14991782
	ld	(32142:16), wa
	ld	wa, qwa
	ld	(32140:16), wa
AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	ld wa, (0x7d8c:16)
	ld QWA,WA
	ld wa, (0x7d8e:16)
	ld XIY,XWA
	cp (0x7d89:16), 0x80
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
	ld	(32150:16), wa
	ld	wa, qwa
	ld	(32148:16), wa
	ld	xwa, (xiy+21)
	ld	(32158:16), wa
	ld	wa, qwa
	ld	(32156:16), wa
	jr	23
AccompSeq_LoadParams_Alt:
	ld	a, (xiy+256)
	and	a, 29
	ld	(32139:16), a
	ld	wa, (xiy+3)
	ld	(32144:16), wa
	lds	wa, 6
	ld	(32146:16), wa
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
	ld (0x7dd6:16), 0x7f
	ld (0x7dd7:16), 0x7f
	ld wa, (0x7d8c:16)
	ld QWA,WA
	ld wa, (0x7d8e:16)
	ld XIY,XWA
	bit 0, (0x7d8b:16)
	jr z, AccompSeq_InitMidi_Ch2
	ld WA,(XIY+0x09)
	ld E,W
	ld W,A
	ldb A, 0xc1
	ld (0x7da4:16), w
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
	and (0x7d88:16), 0x7f
	xor WA,WA
	ei 0x06
	ld (0x0468:16), wa
	ld (0x046a:16), a
	ld (0x0472:16), a
	bit 2, (0x041f:16)
	jr nz, AccompSeq_InitPlay_SetCounters
	or (0x041f:16), 0x01
AccompSeq_InitPlay_SetCounters:
	di
	ld	(32160:16), wa
	ld	(32162:16), wa
	ld	a, (32136:16)
	ld	w, (32139:16)
	bit	0, w
	jr	z, 3
	or	a, 1
AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	ld	(32136:16), a
	ld	w, (49122:16)
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
	ld	a, (32136:16)
	and	a, 252
	ld	(32136:16), a
	calr	466
	popw	hl
	calr	64926
	ld	(32137:16), l
	ld	(32138:16), h
	calr	64920
	calr	64985
	calr	65204
	calr	65406
	ret
AccompSeq_HandleSpecialMode:
	ld	a, (32136:16)
	and	a, 3
	jr	z, 16
	pushw	hl
	ld	a, (32136:16)
	and	a, 252
	ld	(32136:16), a
	calr	417
	popw	hl
	ld	a, (64786:16)
	cp	a, 13
	jr	z, 5
	cp	a, 14
	jr	nz, 37
	ld	(32367:16), 1
	calr	64858
	and	l, 15
	ld	(32376:16), l
	ld	w, (49122:16)
	ldb	a, 1
	bit	0, w
	jr	nz, 9
	ldb	a, 2
	bit	1, w
	jr	nz, 2
	ldb	a, 4
	jr	15
	ld	(32422:16), 57
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
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	ld	iy, (xhl+256)
	ret
	ld a, (0xbfe2:16)
	bit 0x07,A
	jr nz, .Lc_f6e66d
	and (0x7dde:16), 0xfe
	jr t, .Lc_f6e6a9
.Lc_f6e66d:
	or (0x7dde:16), 0x01
	ld a, (0x7e6f:16)
	cps a, 0
	jr z, .Lc_f6e682
	ldb A, 0x00
	ld (0x7e6f:16), a
	jr t, .Lc_f6e6a9
.Lc_f6e682:
	ld a, (0x7d88:16)
	and A,0x03
	cps a, 0
	jr z, .Lc_f6e6a9
	bit 2, (0x7d8b:16)
	jr z, .Lc_f6e6a6
	bit 7, (0x7d88:16)
	jr nz, .Lc_f6e6a6
	ldw (0x7dd4:16), 0x0800
	or (0x7d88:16), 0x80
	jr t, .Lc_f6e6a9
.Lc_f6e6a6:
	calr AccompSeq_CleanupSequence
.Lc_f6e6a9:
	ret
AccompSeq_AllNotesOffImpl:
	ld a, (0x7d88:16)
	and A,0x03
	cps a, 0
	jr z, AccompSeq_AllNotesOff_Send
	bit 2, (0x7d8b:16)
	jr z, AccompSeq_AllNotesOff_Stop
	bit 7, (0x7d88:16)
	jr nz, AccompSeq_AllNotesOff_Stop
	ldw (0x7dd4:16), 0x0800
	or (0x7d88:16), 0x80
	jr t, AccompSeq_AllNotesOff_Send
AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ldb l, 0x7f
	ldb h, 0x3
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	ld	a, (32367:16)
	cps	a, 0
	jr	z, 6
	ldb	a, 0
	ld	(32367:16), a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	ld a, (0xbfe1:16)
	cp A,0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ld a, (0xbfe2:16)
	andda8 a, (0xbfe3)
	and A,0x03
	cps a, 0
	jr z, AccompSeq_GuardedNote_Return
	cp (0x8c98:16), 0x13
	jr z, AccompSeq_GuardedNote_Return
	cp (0x8c9c:16), 0xc8
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
	ld a, (0x7d88:16)
	and A,0x03
	cps a, 0
	jr z, .Lc_f6e748
	and (0x7d88:16), 0x7f
	or (0x041f:16), 0x08
	ld a, (0x7d88:16)
	and A,0xfc
	ld (0x7d88:16), a
	calr AccompSeq_SendAllOff
AccompSeq_Cleanup_ClearFlags:
.Lc_f6e748:
	and (0x7dd2:16), 0xfe
	and (0x7dd3:16), 0xfe

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
	ld	(32214:16), 127
	ld	(32215:16), 127
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
	and (0x7dd2:16), 0xfe
	and (0x7dd3:16), 0xfe
	and (0x7dc3:16), 0xfc
	pushw hl
	calr AccompSeq_CompareChord
	popw hl
	ld a, (0x7d88:16)
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
	bit 0, (0x31e7:16)
	jr z, AccompSeq_CompareChord_Return
	bit 2, (0x28b2:16)
	jr nz, AccompSeq_CompareChord_Return
	ld (0x7dc4:16), l
	ld (0x7dc5:16), h
	ld wa, (0x7d8e:16)
	pushw wa
	ld wa, (0x7d8c:16)
	pushw wa
	calr AccompSeq_ResetMidiState
	calr AccompSeq_LookupStyleData
	ld wa, (0x7d8c:16)
	ld QWA,WA
	ld wa, (0x7d8e:16)
	ld XIY,XWA
	.byte 0x8d, 0x00, 0x21, 0xc9, 0x33, 0x04, 0x66, 0x1a
	.byte 0xc1, 0x33, 0x04, 0x21, 0xc1, 0x16, 0x04, 0x20
	.byte 0xc8, 0x61, 0xc8, 0xf1, 0x66, 0x07, 0xc1, 0xc3
	.byte 0x7d, 0x3e, 0x02, 0x68, 0x05
AccompSeq_CompareChord_Match:
	.byte 0xc1, 0xc3, 0x7d, 0x3e, 0x01	; ordi8 0x7e5f, 1 (v7 patched)



AccompSeq_CompareChord_RestorePos:
	popw	wa
	ld	(32140:16), wa
	popw	wa
	ld	(32142:16), wa
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
	bit 0, (0x7db7:16)
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
	incw	1, (32170:16)
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
	and	a, 15
	ld	(32185:16), a
	ldb	a, 1
	cp	(32182:16), 0
	jr	z, 2
	ldb	a, 2
AccompSeq_SeqParse_CtrlChg_SetCh:
	or	a, 208
	ld	(32184:16), a
	calr	61262
	calr	61259
	ld	e, (xiy)
	ld	(32186:16), e
	ld	w, (32185:16)
	ld	a, (32184:16)
	calr	64145
	calr	61239
	ld	w, (32185:16)
	ld	a, (32184:16)
	and	a, 240
	cp	a, 208
	jr	nz, 16
	cps	w, 5
	jr	nz, 12
	ld	a, (32186:16)
	push	xiy
	ld	xiy, (32216:16)
	ld	(xiy), a
	pop	xiy
AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	ld xwa, (0x7dc9:16)
	cp (0x7db6:16), 0x00
	jr z, AccompSeq_SeqParse_TempoStore
	ld xwa, (0x7dcd:16)
AccompSeq_SeqParse_TempoStore:
	ld	(32168:16), wa
	ld	wa, qwa
	ld	(32166:16), wa
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

