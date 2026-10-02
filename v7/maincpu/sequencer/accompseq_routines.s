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
	ei	0
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

	; anddi8 (0x7e53), 252 (v7 patched)
	and	(0x7db7:16), 252
AccompSeq_EventDispatchLoop:
	bit	0, (0x7db7:16)
	jr	z, AccompSeq_DispatchByOpcode
	jp	AccompSeq_EventDispatchDone
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
	or	(0x7db7:16), 1
	jr	AccompSeq_EventDispatchLoop
AccompSeq_HandleEndMarker:
	bit	1, (0x7db7:16)
	jr	z, AccompSeq_EndMarkerCalcTime
	or	(0x7db7:16), 1
	jr	AccompSeq_EventDispatchLoop
AccompSeq_EndMarkerCalcTime:
	ld	a, 96:opc
	call	AccompSeq_CalcDeltaTime
	cp	a, 24
	jr	ule, AccompSeq_EndMarkerAdvance
	or	(0x7db7:16), 1
	jp	AccompSeq_EventDispatchLoop
AccompSeq_EndMarkerAdvance:
	or	(0x7db7:16), 2
	ld	wa, (0x7daa:16)
	inc	1, wa
	ld	(0x7daa:16), wa
	calr	AccompSeq_AdvancePosition
	jp	AccompSeq_EventDispatchLoop
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
	ld	wa, (32168:16)
	inc	1, wa
	ld	(32168:16), wa
	cp	wa, 0:i3
	jr	nz, AccompSeq_AdvanceCheckPattern
	pushw	wa
	ld	wa, (32166:16)
	inc	1, wa
	ld	(32166:16), wa
	popw	wa
AccompSeq_AdvanceCheckPattern:
	calr	ResolveVRAMAddressForVoice
	ld	a, (xiy)
	cp	a, 135
	jr	nz, AccompSeq_AdvanceDone
	calr	AccompSeq_ReadBeatHeader
	ld	(32166:16), wa
	ld	qwa, wa
	ld	wa, 6:i3
	ld	(32168:16), wa
	calr	AccompSeq_BuildVRAMAddr
	ld	a, (xiy)
AccompSeq_AdvanceDone:
	ret

AccompSeq_VRAMHelperData:
	cp	(0x7d89:16), 128
	jr	c, AccompSeq_VRAMHelperData_Skip
	calr	AccompSeq_VRAMHelperData_Helper
	jr	AccompSeq_VRAMHelperData_Return
AccompSeq_VRAMHelperData_Skip:
	ld	wa, (32166:16)
	ld	iy, wa
AccompSeq_VRAMHelperData_Return:
	ret	
AccompSeq_VRAMHelperData_Helper:
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
	cp	(0x7db6:16), 1
	jr	z, AccompSeq_StopPartCh2
	and	(0x7d88:16), 254
	jr	AccompSeq_CheckRestart
AccompSeq_StopPartCh2:
	; anddi8 (0x7e24), 253 (v7 patched)
	and	(0x7d88:16), 253
AccompSeq_CheckRestart:
	or	(0x7db7:16), 1
	ld	a, (0x7d88:16)
	and	a, 3
	cp	a, 0:i3
	jr	nz, AccompSeq_DispatchReturn
	or	(0x7d88:16), 1
	call	AccompSeq_StopSequence
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
	jr	ugt, AccompSeq_DeltaFarBehind
	sub	wa, hl
	cp	wa, 1:i3
	jr	z, AccompSeq_DeltaOneAhead
	ld	a, 96:opc
	jr	AccompSeq_DeltaReturn
AccompSeq_DeltaOneAhead:
	ld	a, (32130:16)
	add	e, 96
	sub	e, a
	ld	a, e
	jr	AccompSeq_DeltaReturn
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
	calr	AccompSeq_ReadParams
	calr	AccompSeq_CalcEventSize
	cpw	(32180:16), 16
	jr	ugt, AccompSeq_Parse_Type90_Large
	calr	AccompSeq_ResetCounters
	jr	AccompSeq_Parse_Done
AccompSeq_Parse_Type90_Large:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	AccompSeq_ProcessNoteOn6
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
	calr	AccompSeq_ProcessNoteOn8
AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	ld	d, a
	and	a, 240
	ld	(32184:16), a
	calr	AccompSeq_AdvancePosition
	ld	(32185:16), e
	calr	AccompSeq_AdvancePosition
	ld	a, d
	and	a, 15
	ld	(32186:16), a
	ld	a, (xiy)
	ld	(32187:16), a
	calr	AccompSeq_AdvancePosition
	calr	AccompSeq_CalcEventSize
	cpw	(32180:16), 16
	jr	ugt, AccompSeq_Parse_TypeC0_CalcSize
	calr	AccompSeq_ResetCounters
	jr	AccompSeq_Parse_TypeC0_Done
AccompSeq_Parse_TypeC0_CalcSize:
	ld	xhl, (32176:16)
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	AccompSeq_ProcessNotePorta
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
	calr	AccompSeq_ProcessNoteOn5
AccompSeq_Parse_Return:
	jr AccompSeq_Ret

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	ld	(32184:16), a
	calr	AccompSeq_AdvancePosition
	ld	(32185:16), e
	calr	AccompSeq_AdvancePosition
	ld	(32186:16), a
	calr	AccompSeq_AdvancePosition
	ld	(32187:16), a
	calr	AccompSeq_AdvancePosition
	ld	(32188:16), a
	calr	AccompSeq_AdvancePosition
	ld	(32189:16), a
	calr	AccompSeq_AdvancePosition
	ret
AccompSeq_CalcEventSize:
	ld xhl, (0x7db0:16)
	ld WA,(XHL+0x06)
	cp WA,(XHL+0x04)
	jr c, AccompSeq_CalcSize_Negative
	jr ugt, AccompSeq_CalcSize_Positive
	ld WA,(XHL+0x02)
	sub	wa, (xhl+0:8)
	inc	1, wa
	jr	AccompSeq_CalcSize_Store
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
	ld	(32180:16), wa
	ret
AccompSeq_ResetCounters:
	ld xhl, (32176:16)

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
	ld	(32166:16), hl
	push	xhl
	calr	AccompSeq_VRAMHelperData
	pop	xhl
	ld	iy, 6:i3
AccompSeq_ResetCounters_Return:
	ret
AccompSeq_ProcessNoteOn6:
	ld a, (0x7db8:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld E,A
	call AccompSeq_CheckVelocityFlags
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	cp a, 0:i3
	jr nz, AccompSeq_NoteOn6_VelClamp
	ld A, 0x01:opc
AccompSeq_NoteOn6_VelClamp:
	ld	(xhl+iy), a

	; calr AccompSeq_AdvanceBufferPtr (v7 displacement)
	calr	AccompSeq_AdvanceBufferPtr
	; ldb_d8 a, (0x7e59) (v7 patched)
	ld	a, (0x7dbd:16)
	ld	(xhl+iy), a

	calr	AccompSeq_AdvanceBufferPtr

	ld	(xhl+iy), e

	calr	AccompSeq_AdvanceBufferPtr

	ld (xhl + 4), iy

	ret



AccompSeq_ProcessNoteOn8:
	ld a, (0x7db8:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld E,A
	calr AccompSeq_CheckVelFlagsExtended
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	cp a, 0:i3
	jr nz, .Lc_f6de79
	ld A, 0x01:opc
AccompSeq_NoteOn8_VelClamp:
.Lc_f6de79:
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbd:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbe:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbf:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld	(xhl+iy), e
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ret
AccompSeq_ProcessNotePorta:
	ld a, (0x7db8:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	calr AccompSeq_PortaFadeOut
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld (XHL+0x04),IY
	ld a, (0x7db8:16)
	cp A,0xd0
	jr nz, AccompSeq_NotePorta_Done
	ld a, (0x7db9:16)
	cp a, 5:i3
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
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ld a, (0x7dba:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbb:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbc:16)
	ld	(xhl+iy), a
	calr AccompSeq_AdvanceBufferPtr
	ld a, (0x7dbd:16)
	ld	(xhl+iy), a
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
	sub a, (0x046b:16)
	jr ugt, AccompSeq_ResolveCh_Store
	ld A, 0x01:opc
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
	calr	AccompSeq_AdvanceBufferPtr
	ld	w, (32096:16)
	cp	a, w
	jr	nc, AccompSeq_ResolveCh_Done	; -> 0xF6DF9B
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
	ld iy, (xhl + 0:8)

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
	cp wa, 0:i3
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
	mul xwa, hl
	ld DE,QWA
	ldw HL, 0x0800
	ld QWA,DE
	div xwa, hl
	ld DE,QWA
	ld E,A
	ld W, 0x05:opc
	ld A, 0xd1:opc
	call AccompSeq_SendMidiEvent
AccompSeq_FadeOut_Ch2Volume:
.Lc_f6e07c:
	bit 1, (0x7d88:16)
	jr z, AccompSeq_FadeOut_ChReturn
	ld l, (0x7dd7:16)
	xor H,H
	ld wa, (0x7dd4:16)
	mul xwa, hl
	ld DE,QWA
	ldw HL, 0x0800
	ld QWA,DE
	div xwa, hl
	ld DE,QWA
	ld E,A
	ld W, 0x05:opc
	ld A, 0xd2:opc
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
	cp w, 5:i3
	jr nz, AccompSeq_PortaFade_Return
	push XHL
	push XDE
	ld l, (0x7dbb:16)
	xor H,H
	ld wa, (0x7dd4:16)
	mul	xwa, hl
	ld	de, qwa
	ldw	hl, 2048
	ld	qwa, de
	div	xwa, hl
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
	cp h, 3:i3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ld	a, (49122:16)
	push	xwa
	push	xhl
	call	Voice_DecodeNoteParam
	call	Voice_DecodeNoteChannel
	ld	(49122:16), 1
	cp	h, 0:i3
	jr	z, AccompSeq_ManualMidi_SetChannel
	ld	(49122:16), 2
	cp	h, 1:i3
	jr	z, AccompSeq_ManualMidi_SetChannel
	ld	(49122:16), 4
AccompSeq_ManualMidi_SetChannel:
	pop	xhl
	call	AccompSeq_ProcessAfterNote
	pop	xwa
	ld	(49122:16), a
AccompSeq_ManualMidi_ClearFlags:
	; anddi8 (0x7f15), 253 (v7 patched)
	and	(0x7e79:16), 253
	; anddi8 (0x7f15), 247 (v7 patched)
	and	(0x7e79:16), 247
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
	calr	AccompSeq_ManualMidi_ClearFlags_Code_Helper
	ret
AccompSeq_ManualMidi_ClearFlags_Code_Helper:
	bit	7, e
	jr	z, AccompSeq_ManualMidi_ClearFlags_Code_Return
	or	d, 16
	and	e, 127
AccompSeq_ManualMidi_ClearFlags_Code_Return:
	ret
	ld	a, 159:opc
	ld	w, 127:opc
	ld	e, 127:opc
	calr	AccompSeq_ManualMidi_ClearFlags_Code_Helper2
	ret
	ld	a, 223:opc
	ld	w, 127:opc
	ld	e, 127:opc
	calr	AccompSeq_ManualMidi_ClearFlags_Code_Helper2
	ret
AccompSeq_ManualMidi_ClearFlags_Code_Helper2:
	pushw	iy
	ld	xhl, 31312
	ei	0x06
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	st_rrb	e, xiy, hl
	calr	AccompSeq_AdvanceBufferPtr
	st_rrb	d, xiy, hl
	calr	AccompSeq_AdvanceBufferPtr
	st_rrb	a, xiy, hl
	calr	AccompSeq_AdvanceBufferPtr
	ld	(xhl+4), iy
	ei	0x00
	popw	iy
	ret
	ld	wa, 0:i3
	ld	(1128:16), wa
	ld	(1130:16), a
	ld	(32128:16), wa
	ld	(32130:16), a
	ret
	ld	a, (32198:16)
	ld	w, (1076:16)
	ld	(32198:16), w
	cp	a, w
	jr	z, AccompSeq_ManualMidi_ClearFlags_Code_Return2
	bit	0, (0x7dc3:16)
	jr	z, AccompSeq_ManualMidi_ClearFlags_Code_Return2
	and	(0x7dc3:16), 254
	ld	l, (32196:16)
	ld	h, (32197:16)
	ld	a, (32136:16)
	and	a, (0x03:8)
	cp	a, 0:i3
	jr	nz, AccompSeq_ManualMidi_ClearFlags_Code_Skip
	call	AccompSeq_InitPartFull
	jr	AccompSeq_ManualMidi_ClearFlags_Code_Join
AccompSeq_ManualMidi_ClearFlags_Code_Skip:
	call	AccompSeq_ReinitPart
AccompSeq_ManualMidi_ClearFlags_Code_Join:
	ei	0x06
	ld	c, (1045:16)
	ld	(1130:16), c
	ld	(1138:16), c
	ld	wa, 0:i3
	ld	a, (1046:16)
	ld	(1128:16), wa
	ei	0x00
AccompSeq_ManualMidi_ClearFlags_Code_Return2:
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
	jp	AccompSeq_ClearPendingFlag
	ld	a, (49121:16)
	cp	a, 9
	jrl	nz, AccompSeq_ProcessAfterNote_Return
	ld	a, (49123:16)
	bit	7, a
	jr	z, AccompSeq_ProcessAfterNote_Skip2
	calr	AccompSeq_ProcessAfterNote_Helper
	ld	l, 127:opc
	ld	h, 3:opc
	ld	a, (49122:16)
	bit	7, a
	jr	z, AccompSeq_ProcessAfterNote_Skip
	calr	AccompSeq_OutputEvent
AccompSeq_ProcessAfterNote_Skip:
	jrl	AccompSeq_ProcessAfterNote_Return
AccompSeq_ProcessAfterNote_Skip2:
	and	a, 63
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	ld	a, (49122:16)
	and	a, (49123:16)
	and	a, 63
	cp	a, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	xor	w, w
	ld	hl, wa
	ld	xix, AccompSeq_MidiFilterCodeBlock_0x7A
	ld_rrb	h, xix, hl
	ld	l, (64786:16)
	cp	l, 17
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	l, 18
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	l, 15
	jr	z, AccompSeq_ProcessAfterNote_Skip3
	cp	l, 16
	jr	nz, AccompSeq_ProcessAfterNote_Skip5
AccompSeq_ProcessAfterNote_Skip3:
	ld	xix, 2001408
	cp	l, 16
	jr	nz, AccompSeq_ProcessAfterNote_Skip4
	add	xix, 16
AccompSeq_ProcessAfterNote_Skip4:
	sll	h, 1
	ld_rr8b	l, xix, h
	inc	1, h
	ld_rr8b	h, xix, h
	cp	l, 14
	jr	ugt, AccompSeq_ProcessAfterNote_Return
AccompSeq_ProcessAfterNote_Skip5:
	call	Voice_NoteChannelTable1_Code_Sub
	cp	h, 0:i3
	jr	z, AccompSeq_ProcessAfterNote_Return
	cp	(32367:16), 0
	jr	nz, AccompSeq_ProcessAfterNote_Return
	bit	0, (0x7dde:16)
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
	cp (0x7e6f:16), 0x00
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange
AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr	AccompSeq_ResetMidiState
	ld	(32137:16), l
	ld	(32138:16), h
	calr	AccompSeq_LookupStyleData
	calr	AccompSeq_LoadParams
	calr	AccompSeq_InitMidiEvents
	calr	AccompSeq_InitPlayState
	ret
AccompSeq_ResetMidiState:
	call Voice_DecodeNoteParam
	ret

AccompSeq_LookupStyleData:
	cp	l, 128
	jr	c, AccompSeq_LookupStyle_Internal
	and	l, 15
	call	Voice_DecodeBankIndex
	and	xhl, 65535
	ld	xwa, xhl
	add	xwa, 2000896
	ld	(32142:16), wa
	ld	wa, qwa
	ld	(32140:16), wa
	jr	AccompSeq_LookupStyle_Return
AccompSeq_LookupStyle_Internal:
	call	Voice_DecodeNoteChannel2
	xor	xwa, xwa
	ldw	wa, 32
	mul	xwa, hl
	add	xwa, AccompSeq_StyleDataTable
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
	ld	a, (xiy+0:8)
	and	a, 29
	ld	(0x7d8b:16), a
	ld	xwa, (xiy+1)
	add	xwa, 6
	ld	(0x7d92:16), wa
	ld	wa, qwa
	ld	(0x7d90:16), wa
	ld	xwa, (xiy+5)
	ld	(0x7d9a:16), wa
	ld	wa, qwa
	ld	(0x7d98:16), wa
	ld	a, (xiy+16)
	bit	0, a
	jr	z, AccompSeq_LoadParams_Bit0Set
	or	(0x7d8b:16), 2
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
	jr	AccompSeq_LoadParams_OverrideCheck
AccompSeq_LoadParams_Alt:
	ld	a, (xiy+0:8)
	and	a, 29
	ld	(32139:16), a
	ld	wa, (xiy+3)
	ld	(32144:16), wa
	ld	wa, 6:i3
	ld	(32146:16), wa
AccompSeq_LoadParams_OverrideCheck:
	bit	0, (0x7dc3:16)
	jr	z, AccompSeq_LoadParams_Return
	ld	wa, (0x7d90:16)
	ld	qwa, wa
	ld	wa, (0x7d92:16)
	ld	(0x7dc9:16), xwa
	ld	wa, (0x7d94:16)
	ld	qwa, wa
	ld	wa, (0x7d96:16)
	ld	(0x7dcd:16), xwa
	ld	wa, 0:i3
	ld	a, (0x433:16)
	dec	1, a
	and	a, 7
	sll	wa, 2
	ld	xiy, AccompSeq_TempoScaleTable
	ld_rrl	xwa, xiy, wa
	add	xwa, 6
	ld	(0x7d92:16), wa
	ld	(0x7d96:16), wa
	ld	wa, qwa
	ld	(0x7d90:16), wa
	ld	(0x7d94:16), wa
AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	ld A, 0xd0:opc
	ld W, 0x03:opc
	ld E, 0x00:opc
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
	ld A, 0xc1:opc
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
	bit	1, (0x7d8b:16)
	jr	z, AccompSeq_InitMidi_Return
	ld	wa, (xiy+25)
	ld	e, w
	ld	w, a
	ld	a, 194:opc
	ld	(0x7da5:16), w
	and	e, 15
	bit	7, w
	jr	z, AccompSeq_InitMidi_Ch2Flags
	or	e, 16
	and	w, 127
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
	ei	0
	ld	(32160:16), wa
	ld	(32162:16), wa
	ld	a, (32136:16)
	ld	w, (32139:16)
	bit	0, w
	jr	z, AccompSeq_InitPlay_Ch2Flag
	or	a, 1
AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	ld	(32136:16), a
	ld	w, (49122:16)
	ld	a, 1:opc
	bit	0, w
	jr	nz, AccompSeq_InitPlay_Return
	ld	a, 2:opc
	bit	1, w
	jr	nz, AccompSeq_InitPlay_Return
	ld	a, 4:opc
AccompSeq_InitPlay_Return:
	ret

AccompSeq_ReinitPart:
	pushw	hl
	ld	a, (32136:16)
	and	a, 252
	ld	(32136:16), a
	calr	AccompSeq_SendAllOff
	popw	hl
	calr	AccompSeq_ResetMidiState
	ld	(32137:16), l
	ld	(32138:16), h
	calr	AccompSeq_LookupStyleData
	calr	AccompSeq_LoadParams
	calr	AccompSeq_InitMidiEvents
	calr	AccompSeq_InitPlayState
	ret
AccompSeq_HandleSpecialMode:
	ld	a, (32136:16)
	and	a, 3
	jr	z, AccompSeq_HandleSpecialMode_Skip
	pushw	hl
	ld	a, (32136:16)
	and	a, 252
	ld	(32136:16), a
	calr	AccompSeq_SendAllOff
	popw	hl
AccompSeq_HandleSpecialMode_Skip:
	ld	a, (64786:16)
	cp	a, 13
	jr	z, AccompSeq_HandleSpecialMode_Skip2
	cp	a, 14
	jr	nz, AccompSeq_HandleSpecialMode_Skip4
AccompSeq_HandleSpecialMode_Skip2:
	ld	(32367:16), 1
	calr	AccompSeq_ResetMidiState
	and	l, 15
	ld	(32376:16), l
	ld	w, (49122:16)
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
	ld	(32422:16), 57
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
AccompSeq_HandleSpecialMode_Return:
	ret
AccompSeq_OutputEvent:
	pushw HL
	pushw HL
	call Voice_DecodeNoteChannel
	ld BC,HL
	popw	hl
	ld	wa, hl
	ld	hl, bc
	cpw	(0x28aa:16), 0
	jr	nz, AccompSeq_Output_CheckFilter
	cp	(0x8c9a:16), 138
	jr	nz, AccompSeq_Output_CheckManual
	cp	(0xd65:16), 2
	jr	nz, AccompSeq_Output_CheckManual
AccompSeq_Output_CheckFilter:
	bit	3, (0x7e79:16)
	jr	nz, AccompSeq_Output_CheckManual
	pushw	wa
	pushw	hl
	call	Tempo_ProcessExpressionChange
	popw	hl
	popw	wa
AccompSeq_Output_CheckManual:
	bit	1, (0x7e79:16)
	jr	nz, AccompSeq_Output_Return
	call	MidiPkt_SendControlPair
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
	ld	iy, (xhl+0:8)
AccompSeq_WriteMidiToBuffer_Return:
	ret
AccompSeq_ProcessAfterNote_Helper:
	ld a, (0xbfe2:16)
	bit 0x07,A
	jr nz, .Lc_f6e66d
	and (0x7dde:16), 0xfe
	jr t, .Lc_f6e6a9
.Lc_f6e66d:
	or (0x7dde:16), 0x01
	ld a, (0x7e6f:16)
	cp a, 0:i3
	jr z, .Lc_f6e682
	ld A, 0x00:opc
	ld (0x7e6f:16), a
	jr t, .Lc_f6e6a9
.Lc_f6e682:
	ld a, (0x7d88:16)
	and A,0x03
	cp a, 0:i3
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
	cp a, 0:i3
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
	ld l, 0x7f:opc
	ld h, 0x3:opc
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	ld	a, (32367:16)
	cp	a, 0:i3
	jr	z, AccompSeq_ClearPending_Return
	ld	a, 0:opc
	ld	(32367:16), a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	ld a, (0xbfe1:16)
	cp A,0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ld a, (0xbfe2:16)
	and a, (0xbfe3:16)
	and A,0x03
	cp a, 0:i3
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
	ld A, 0xc8:opc
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
	cp a, 0:i3
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
	ld	a, 144:opc
	ld	w, 127:opc
	ld	e, 127:opc
	calr	AccompSeq_WriteMidiToBuffer
	ld	a, 208:opc
	ld	w, 3:opc
	ld	e, 0:opc
	calr	AccompSeq_WriteMidiToBuffer
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
	ld	a, 8:opc
	xor	w, w
	ld	xhl, 31952
AccompSeq_SendAllOff_Loop1:
	ld	(xhl), w
	add	hl, 9
	dec	1, a
	cp	a, 0:i3
	jr	nz, AccompSeq_SendAllOff_Loop1
	ld	a, 8:opc
	xor	w, w
	ld	xhl, 32024
AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cp a, 0:i3
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
	cp a, 0:i3
	jr nz, AccompSeq_ChordChange_Reinit
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call AccPedal_SustainHandler_Helper
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
	call	AccPedal_SustainHandler_Helper
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	calr	AccompSeq_ReinitPart
AccompSeq_ChordChange_CheckOverride:
	bit	1, (0x7dc3:16)
	jr	nz, AccompSeq_ChordChange_ApplyOverride
	bit	0, (0x7dc3:16)
	jr	z, AccompSeq_ChordChange_Return
	or	(0x7dd2:16), 1
	or	(0x7dd3:16), 1
AccompSeq_ChordChange_ApplyOverride:
	; anddi8 (0x7e5f), 253 (v7 patched)
	and	(0x7dc3:16), 253
	; call AccompSeq_SetupChannels (v7 addr)
	call	AccompSeq_SetupChannels
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
	ld	a, (xiy+0:8)
	bit	4, a
	jr	z, AccompSeq_CompareChord_RestorePos
	ld	a, (0x433:16)
	ld	w, (0x416:16)
	inc	1, w
	cp	a, w
	jr	z, AccompSeq_CompareChord_Match
	or	(0x7dc3:16), 2
	jr	AccompSeq_CompareChord_RestorePos
AccompSeq_CompareChord_Match:
	; ordi8 0x7e5f, 1 (v7 patched)
	or	(0x7dc3:16), 1
AccompSeq_CompareChord_RestorePos:
	popw	wa
	ld	(32140:16), wa
	popw	wa
	ld	(32142:16), wa
AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	ei	6
	ld	c, (0x415:16)
	ld	(0x7dc7:16), c
	ld	wa, 0:i3
	ld	a, (0x416:16)
	ld	(0x7dc8:16), a
	ld	(0x46a:16), c
	ld	(0x472:16), c
	ld	(0x468:16), wa
	ei	0
	bit	0, (0x7d88:16)
	jr	z, AccompSeq_SetupCh2
	ld	(0x7db6:16), 0
	ld	xwa, 32164
	ld	(0x7dac:16), xwa
	ld	xwa, 32214
	ld	(0x7dd8:16), xwa
	ld	wa, (0x7d90:16)
	ld	(0x7da6:16), wa
	ld	wa, (0x7d92:16)
	ld	(0x7da8:16), wa
	ld	wa, (0x7da0:16)
	ld	(0x7daa:16), wa
	ld	a, (0x7dd2:16)
	ld	(0x7dd1:16), a
	calr	AccompSeq_ParseSequenceData
	ld	a, (0x7dd1:16)
	ld	(0x7dd2:16), a
	ld	wa, (0x7daa:16)
	ld	(0x7da0:16), wa
	ld	wa, (0x7da8:16)
	ld	(0x7d92:16), wa
	ld	wa, (0x7da6:16)
	ld	(0x7d90:16), wa
AccompSeq_SetupCh2:
	bit	1, (0x7d88:16)
	jr	z, AccompSeq_SetupCh_Return
	ld	(0x7db6:16), 1
	ld	xwa, 32165
	ld	(0x7dac:16), xwa
	ld	xwa, 32215
	ld	(0x7dd8:16), xwa
	ld	wa, (0x7d94:16)
	ld	(0x7da6:16), wa
	ld	wa, (0x7d96:16)
	ld	(0x7da8:16), wa
	ld	wa, (0x7da2:16)
	ld	(0x7daa:16), wa
	ld	a, (0x7dd3:16)
	ld	(0x7dd1:16), a
	calr	AccompSeq_ParseSequenceData
	ld	a, (0x7dd1:16)
	ld	(0x7dd3:16), a
	ld	wa, (0x7daa:16)
	ld	(0x7da2:16), wa
	ld	wa, (0x7da8:16)
	ld	(0x7d96:16), wa
	ld	wa, (0x7da6:16)
	ld	(0x7d94:16), wa
AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	ld bc, 0:i3

	; ldb_d8 d, (0x7e64) (v7 patched)
	ld	d, (0x7dc8:16)
	; ldb_d8 e, (0x7e63) (v7 patched)
	ld	e, (0x7dc7:16)
	; anddi8 (0x7e53), 254 (v7 patched)
	and	(0x7db7:16), 254
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
	jp z, (AccompSeq_SeqParse_TempoReset:24)
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_EndMark:
	calr	AccompSeq_CleanupSequence
	or	(0x7db7:16), 1
	jr	AccompSeq_SeqParse_Loop
AccompSeq_SeqParse_TimeAdvance:
	ld	bc, (0x7daa:16)
	inc	1, bc
	ld	b, c
	xor	c, c
	cp	de, bc
	jr	nc, AccompSeq_SeqParse_TimeStore
	or	(0x7db7:16), 1
	jr	AccompSeq_SeqParse_Loop
AccompSeq_SeqParse_TimeStore:
	incw	1, (32170:16)
	calr	AccompSeq_AdvancePosition
	jr	AccompSeq_SeqParse_Loop
AccompSeq_SeqParse_MidiEvent:
	calr	AccompSeq_CheckPatternEnd
	ld	bc, (0x7daa:16)
	ld	c, a
	ld	b, (0x7daa:16)
	cp	de, bc
	jr	nc, AccompSeq_SeqParse_CheckNoteOn
	or	(0x7db7:16), 1
	jp	AccompSeq_SeqParse_Loop
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
	cp	a, 192
	jr	nz, AccompSeq_SeqParse_CtrlChg
	ld	a, 1:opc
	cp	(0x7db6:16), 0
	jr	z, AccompSeq_SeqParse_ProgChg_SetCh
	ld	a, 2:opc
AccompSeq_SeqParse_ProgChg_SetCh:
	or	a, 192
	ld	(0x7db8:16), a
	calr	AccompSeq_AdvancePosition
	calr	AccompSeq_AdvancePosition
	ld	a, (xiy)
	ld	(0x7db9:16), a
	calr	AccompSeq_AdvancePosition
	ld	a, (xiy)
	ld	(0x7dba:16), a
	calr	AccompSeq_AdvancePosition
	ld	e, (xiy)
	and	e, 15
	ld	(0x7dbb:16), e
	bit	0, (0x7dba:16)
	jr	z, AccompSeq_SeqParse_ProgChg_Flags
	or	e, 16
AccompSeq_SeqParse_ProgChg_Flags:
	ld	a, (0x7db8:16)
	ld	w, (0x7db9:16)
	calr	AccompSeq_WriteMidiToBuffer
	calr	AccompSeq_AdvancePosition
	calr	AccompSeq_AdvancePosition
	push	xiy
	ld	xiy, (0x7dac:16)
	ld	a, (0x7db9:16)
	and	a, 127
	bit	0, (0x7dba:16)
	jr	z, AccompSeq_SeqParse_ProgChg_Store
	or	a, 128
AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	and	a, 15
	ld	(32185:16), a
	ld	a, 1:opc
	cp	(32182:16), 0
	jr	z, AccompSeq_SeqParse_CtrlChg_SetCh
	ld	a, 2:opc
AccompSeq_SeqParse_CtrlChg_SetCh:
	or	a, 208
	ld	(32184:16), a
	calr	AccompSeq_AdvancePosition
	calr	AccompSeq_AdvancePosition
	ld	e, (xiy)
	ld	(32186:16), e
	ld	w, (32185:16)
	ld	a, (32184:16)
	calr	AccompSeq_WriteMidiToBuffer
	calr	AccompSeq_AdvancePosition
	ld	w, (32185:16)
	ld	a, (32184:16)
	and	a, 240
	cp	a, 208
	jr	nz, AccompSeq_SeqParse_CtrlChg_Loop
	cp	w, 5:i3
	jr	nz, AccompSeq_SeqParse_CtrlChg_Loop
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

