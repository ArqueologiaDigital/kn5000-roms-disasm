; =============================================================================
; Accompaniment Sequencer
; =============================================================================
;
; Accompaniment sequencer periodic processing. Handles real-time
; accompaniment playback, manual MIDI mode, and fade-out timing.
; =============================================================================

AccompSeq_PeriodicEntry:
	jp LABEL_F6DCB5

LABEL_F6DCAD:
	jp AccompSeq_ManualMidiMode2

LABEL_F6DCB1:
	jp AccompSeq_ManualMidiMode1

LABEL_F6DCB5:
	calr LABEL_F6DCD1
	anddi8 32339, 223
	calr LABEL_F6DD0F
	bitda 5, 32339
	jr nz, LABEL_F6DCD0
	calr AccompSeq_FadeOutTick
	call AccPlay_Entry
	calr LABEL_F6DCF6

LABEL_F6DCD0:
	ret

LABEL_F6DCD1:
	jr __jrt_nop_F6DCD3
__jrt_nop_F6DCD3:

LABEL_F6DCD3:
	xor a, a
	ei 6
	stda8 1131, a
	ldda16 xwa, 1128
	stda16 32284, xwa
	ldda8 a, 1130
	stda8 32286, a
	ldda8 a, 1055
	stda8 32287, a
	ei 0
	ret

LABEL_F6DCF6:
	ldda16 xwa, 32284
	stda16 32288, xwa
	ldda8 a, 32286
	stda8 32290, a
	ldda8 a, 32287
	stda8 32291, a
	ret

LABEL_F6DD0F:
	bitda 2, 32287
	jr nz, LABEL_F6DD19
	jp LABEL_F6DDEB

LABEL_F6DD19:
	bitda 0, 32292
	jr z, LABEL_F6DD82
	stdi8 32338, 0
	ld xwa, 0x7AEC
	stda32 32332, xwa
	ld xwa, 0x7E40
	stda32 32328, xwa
	ld xwa, 0x7E72
	stda32 32372, xwa
	ldda16 xwa, 32300
	stda16 32322, xwa
	ldda16 xwa, 32302
	stda16 32324, xwa
	ldda16 xwa, 32316
	stda16 32326, xwa
	ldda8 a, 32366
	stda8 32365, a
	calr AccompSeq_InitEventDispatch
	ldda8 a, 32365
	stda8 32366, a
	ldda16 xwa, 32326
	stda16 32316, xwa
	ldda16 xwa, 32324
	stda16 32302, xwa
	ldda16 xwa, 32322
	stda16 32300, xwa

LABEL_F6DD82:
	bitda 1, 32292
	jr z, LABEL_F6DDEB
	stdi8 32338, 1
	ld xwa, 0x7BEC
	stda32 32332, xwa
	ld xwa, 0x7E41
	stda32 32328, xwa
	ld xwa, 0x7E73
	stda32 32372, xwa
	ldda16 xwa, 32304
	stda16 32322, xwa
	ldda16 xwa, 32306
	stda16 32324, xwa
	ldda16 xwa, 32318
	stda16 32326, xwa
	ldda8 a, 32367
	stda8 32365, a
	calr AccompSeq_InitEventDispatch
	ldda8 a, 32365
	stda8 32367, a
	ldda16 xwa, 32326
	stda16 32318, xwa
	ldda16 xwa, 32324
	stda16 32306, xwa
	ldda16 xwa, 32322
	stda16 32304, xwa

LABEL_F6DDEB:
	ret

LABEL_F6DDEC:
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
	call	16190255
	call	16190259
	ret

AccompSeq_InitEventDispatch:
	ldb a, 0x9
	anddi8 32339, 252

AccompSeq_EventDispatchLoop:
	bitda 0, 32339
	jr z, LABEL_F6DE25
	jp LABEL_F6DEC4

LABEL_F6DE25:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x84
	jr nz, LABEL_F6DE34
	calr AccompSeq_UpdatePosition
	jr AccompSeq_EventDispatchLoop

LABEL_F6DE34:
	cp a, 0x83
	jr nz, LABEL_F6DE3E
	calr LABEL_F6DFDC
	jr AccompSeq_EventDispatchLoop

LABEL_F6DE3E:
	cp a, 0x81
	jr z, LABEL_F6DE8D
	cp a, 0x90
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0x91
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD2
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD1
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD3
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD4
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD5
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xD7
	jr z, AccompSeq_ProcessTimedEvent
	cp a, 0xC0
	jr z, AccompSeq_ProcessTimedEvent
	calr AccompSeq_AdvancePosition
	jr AccompSeq_EventDispatchLoop

AccompSeq_ProcessTimedEvent:
	calr AccompSeq_CheckPatternEnd
	call AccompSeq_CalcDeltaTime
	cp a, 0x18
	jr ugt, LABEL_F6DE86
	calr AccompSeq_ParseEvents
	jr AccompSeq_EventDispatchLoop

LABEL_F6DE86:
	ordi8 32339, 1
	jr AccompSeq_EventDispatchLoop

LABEL_F6DE8D:
	bitda 1, 32339
	jr z, LABEL_F6DE9A
	ordi8 32339, 1
	jr AccompSeq_EventDispatchLoop

LABEL_F6DE9A:
	ldb a, 0x60
	call AccompSeq_CalcDeltaTime
	cp a, 0x18
	jr ule, LABEL_F6DEAE
	ordi8 32339, 1
	jp AccompSeq_EventDispatchLoop

LABEL_F6DEAE:
	ordi8 32339, 2
	ldda16 xwa, 32326
	inc 1, wa
	stda16 32326, xwa
	calr AccompSeq_AdvancePosition
	jp AccompSeq_EventDispatchLoop

LABEL_F6DEC4:
	ret

AccompSeq_CheckPatternEnd:
	push xiy
	calr ResolveVRAMAddressForVoice
	ld a, (xiy + 1)
	cp a, 0x87
	jr nz, LABEL_F6DEDE
	calr AccompSeq_ReadBeatHeader
	ldfr_werp WA, 0xE2
	lds wa, 6
	calr AccompSeq_BuildVRAMAddr
	ld a, (xiy)

LABEL_F6DEDE:
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
	ldda16 xwa, 32324
	inc 1, wa
	stda16 32324, xwa
	cps wa, 0
	jr nz, LABEL_F6DEFA
	pushw wa
	ldda16 xwa, 32322
	inc 1, wa
	stda16 32322, xwa
	popw wa

LABEL_F6DEFA:
	calr ResolveVRAMAddressForVoice
	ld a, (xiy)
	cp a, 0x87
	jr nz, LABEL_F6DF19
	calr AccompSeq_ReadBeatHeader
	stda16 32322, xwa
	ldfr_werp WA, 0xE2
	lds wa, 6
	stda16 32324, xwa
	calr AccompSeq_BuildVRAMAddr
	ld a, (xiy)

LABEL_F6DF19:
	ret

LABEL_F6DF1A:
	.byte 0xc1, 0x25, 0x7e, 0x3f, 0x80, 0x67, 0x05, 0x1e
	.byte 0x09, 0x00, 0x68, 0x06, 0xd1, 0x42, 0x7e, 0x20
	.byte 0xd8, 0x8d, 0x0e, 0xd1, 0x42, 0x7e, 0x20, 0xe8
	.byte 0xcc, 0xff, 0x0f, 0x00, 0x00, 0xe8, 0xec, 0x08
	.byte 0xe8, 0xc8, 0x00, 0x8b, 0x1e, 0x00, 0xe8, 0x8d
	.byte 0x0e

ResolveVRAMAddressForVoice:
	cpdi8 32293, 128
	jr c, LABEL_F6DF73
	bitda 0, 32365
	jr nz, LABEL_F6DF73
	ldda16 xwa, 32322
	and xwa, 0xFFF
	sla xwa, 8
	ld xiy, xwa
	ldda16 xwa, 32324
	and xwa, 0xFF
	add xiy, xwa
	add xiy, 0x1E8B00
	jr LABEL_F6DF80

LABEL_F6DF73:
	ldda16 xwa, 32322
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32324
	ld xiy, xwa

LABEL_F6DF80:
	ret

AccompSeq_BuildVRAMAddr:
	push xhl
	ld xhl, xwa
	ldto_werp WA, 0xE2
	and xwa, 0xFFF
	sla xwa, 8
	ld xiy, xwa
	ld wa, hl
	and xwa, 0xFF
	add xiy, xwa
	add xiy, 0x1E8B00
	pop xhl
	ret

AccompSeq_ReadBeatHeader:
	ldda16 xwa, 32322
	and xwa, 0xFFF
	sla xwa, 8
	add xwa, 0x3
	add xwa, 0x1E8B00
	ld wa, (xwa)
	ret

LABEL_F6DFC0:
	ldda16	wa, 32322
	and	xwa, 4095
	sla	xwa, 8
	add	xwa, 1
	add	xwa, 2001664
	ld	wa, (xwa)
	ret

LABEL_F6DFDC:
	bitda 3, 32295
	jr z, AccompSeq_StopPart
	cpdi8 32338, 1
	jr z, LABEL_F6DFFB
	ldda16 xwa, 32308
	stda16 32322, xwa
	ldda16 xwa, 32310
	stda16 32324, xwa
	jr AccompSeq_PartTransitionDone

LABEL_F6DFFB:
	ldda16 xwa, 32312
	stda16 32322, xwa
	ldda16 xwa, 32314
	stda16 32324, xwa

AccompSeq_PartTransitionDone:
	jr AccompSeq_DispatchReturn

AccompSeq_StopPart:
	cpdi8 32338, 1
	jr z, AccompSeq_StopPartCh2
	anddi8 32292, 254
	jr AccompSeq_CheckRestart

AccompSeq_StopPartCh2:
	anddi8 32292, 253

AccompSeq_CheckRestart:
	ordi8 32339, 1
	ldda8 a, 32292
	and a, 0x3
	cps a, 0
	jr nz, AccompSeq_DispatchReturn
	ordi8 32292, 1
	call AccompSeq_StopSequence

AccompSeq_DispatchReturn:
	ret

AccompSeq_CalcDeltaTime:
	ld e, a
	ldda16 xwa, 32326
	cpda16 xwa, 32284
	jr nz, AccompSeq_DeltaCompare
	ldda8 a, 32286
	cp a, e
	jr ugt, AccompSeq_DeltaZero
	sub e, a
	ld a, e
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaZero:
	xor a, a
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaCompare:
	ldda16 xhl, 32284
	cp hl, wa
	jr ugt, AccompSeq_DeltaFarBehind
	sub wa, hl
	cps wa, 1
	jr z, AccompSeq_DeltaOneAhead
	ldb a, 0x60
	jr AccompSeq_DeltaReturn

AccompSeq_DeltaOneAhead:
	ldda8 a, 32286
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
	cp a, 0xC0
	jr z, AccompSeq_Parse_TypeC0
	jr AccompSeq_Parse_Fallthrough

AccompSeq_Parse_Type91:
	jp AccompSeq_Parse_Type91_Impl

AccompSeq_Parse_TypeC0:
	jp AccompSeq_Parse_TypeC0_Impl

AccompSeq_Parse_Type90:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpdi16 32336, 16
	jr ugt, AccompSeq_Parse_Type90_Large
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Done

AccompSeq_Parse_Type90_Large:
	ldda32 xhl, 32332
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn6

AccompSeq_Parse_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Type91_Impl:
	calr AccompSeq_ReadParams
	stda8 32346, a
	calr AccompSeq_AdvancePosition
	stda8 32347, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpdi16 32336, 16
	jr ugt, AccompSeq_Parse_Type91_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Type91_Done

AccompSeq_Parse_Type91_CalcSize:
	ldda32 xhl, 32332
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn8

AccompSeq_Parse_Type91_Done:
	jp AccompSeq_Ret

AccompSeq_Parse_Fallthrough:
	ld d, a
	and a, 0xF0
	stda8 32340, a
	calr AccompSeq_AdvancePosition
	stda8 32341, e
	calr AccompSeq_AdvancePosition
	ld a, d
	and a, 0xF
	stda8 32342, a
	ld a, (xiy)
	stda8 32343, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_CalcEventSize
	cpdi16 32336, 16
	jr ugt, AccompSeq_Parse_TypeC0_CalcSize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_TypeC0_Done

AccompSeq_Parse_TypeC0_CalcSize:
	ldda32 xhl, 32332
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNotePorta

AccompSeq_Parse_TypeC0_Done:
	jr AccompSeq_Ret

AccompSeq_Parse_TypeC0_Impl:
	calr AccompSeq_ReadParams
	calr AccompSeq_CalcEventSize
	cpdi16 32336, 16
	jr ugt, AccompSeq_Parse_TypeC0_Finalize
	calr AccompSeq_ResetCounters
	jr AccompSeq_Parse_Return

AccompSeq_Parse_TypeC0_Finalize:
	ldda32 xhl, 32332
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccompSeq_ProcessNoteOn5

AccompSeq_Parse_Return:
	jr __jrt_nop_F6E15C
__jrt_nop_F6E15C:

AccompSeq_Ret:
	ret

AccompSeq_ReadParams:
	stda8 32340, a
	calr AccompSeq_AdvancePosition
	stda8 32341, e
	calr AccompSeq_AdvancePosition
	stda8 32342, a
	calr AccompSeq_AdvancePosition
	stda8 32343, a
	calr AccompSeq_AdvancePosition
	stda8 32344, a
	calr AccompSeq_AdvancePosition
	stda8 32345, a
	calr AccompSeq_AdvancePosition
	ret

AccompSeq_CalcEventSize:
	ldda32 xhl, 32332
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
	stda16 32336, xwa
	ret

AccompSeq_ResetCounters:
	ldda32 xhl, 32332
	ldw (xhl + 256), 0xA
	ldw (xhl + 2), 0xFF
	ldw (xhl + 4), 0xA
	ldw (xhl + 6), 0xA
	ldw (xhl + 8), 0xF6
	ret

AccompSeq_InlineCodeBlock:
	.byte 0xed, 0x61, 0x85, 0x21, 0xc9, 0xcf, 0x87, 0x6e
	.byte 0x10, 0xeb, 0xd3, 0x9b, 0x03, 0x23, 0xf1, 0x42
	.byte 0x7e, 0x53, 0x3b, 0x1e, 0x2e, 0xfd, 0x5b, 0xdd
	.byte 0xae, 0x0e

AccompSeq_ProcessNoteOn6:
	ldda8 a, 32340
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 32342
	ld e, a
	call AccompSeq_CheckVelocityFlags
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32343
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32344
	cps a, 0
	jr nz, AccompSeq_NoteOn6_VelClamp
	ldb a, 0x1

AccompSeq_NoteOn6_VelClamp:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32345
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNoteOn8:
	ldda8 a, 32340
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 32342
	ld e, a
	calr AccompSeq_CheckVelFlagsExtended
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32343
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32344
	cps a, 0
	jr nz, AccompSeq_NoteOn8_VelClamp
	ldb a, 0x1

AccompSeq_NoteOn8_VelClamp:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32345
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32346
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32347
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ret

AccompSeq_ProcessNotePorta:
	ldda8 a, 32340
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 32342
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32343
	calr AccompSeq_PortaFadeOut
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ldda8 a, 32340
	cp a, 0xD0
	jr nz, AccompSeq_NotePorta_Done
	ldda8 a, 32341
	cps a, 5
	jr nz, AccompSeq_NotePorta_Done
	ldda8 a, 32343
	push xiy
	ldda32 xiy, 32372
	ld (xiy), a
	pop xiy

AccompSeq_NotePorta_Done:
	ret

AccompSeq_ProcessNoteOn5:
	ldda8 a, 32340
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	calr AccompSeq_ResolveChannel
	ldda8 a, 32342
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32343
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32344
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 a, 32345
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ld (xhl + 4), iy
	ldda8 a, 32340
	cp a, 0xC0
	jr nz, AccompSeq_NoteOn5_Return
	ldda8 a, 32342
	and a, 0x7F
	bitda 0, 32343
	jr z, AccompSeq_NoteOn5_StoreProgram
	or a, 0x80

AccompSeq_NoteOn5_StoreProgram:
	push xiy
	ldda32 xiy, 32328
	ld (xiy), a
	pop xiy

AccompSeq_NoteOn5_Return:
	ret

AccompSeq_ResolveChannel:
	ldda8 a, 32341
	ei 6
	subda8 a, 1131
	jr ugt, AccompSeq_ResolveCh_Store
	ldb a, 0x1
	stda8 32341, a
	cpdi8 1133, 0
	jr z, AccompSeq_ResolveCh_AddOffset
	xor a, a
	jr AccompSeq_ResolveCh_AddOffset

AccompSeq_ResolveCh_Store:
	stda8 32341, a

AccompSeq_ResolveCh_AddOffset:
	ldda8 w, 1133
	add a, w
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr AccompSeq_AdvanceBufferPtr
	ldda8 w, 32252
	cp a, w
	jr nc, AccompSeq_ResolveCh_Done
	stda8 32252, a

AccompSeq_ResolveCh_Done:
	ei 0
	ret

AccompSeq_CheckVelocityFlags:
	anddi8 13285, 253
	anddi8 13285, 251
	cp a, 0x78
	jr c, AccompSeq_VelFlags_CheckProgram
	ordi8 13285, 4

AccompSeq_VelFlags_CheckProgram:
	push xiy
	ldda32 xiy, 32328
	ld w, (xiy)
	cp w, 0xF0
	jr c, AccompSeq_VelFlags_CallDispatch
	ordi8 13285, 4

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
	ordi8 13285, 2
	pushw wa
	ldda8 a, 32346
	stda8 13286, a
	ldda8 a, 32347
	stda8 13287, a
	popw wa
	anddi8 13285, 251
	cp a, 0x78
	jr c, AccompSeq_ExtVelFlags_CheckProg
	ordi8 13285, 4

AccompSeq_ExtVelFlags_CheckProg:
	push xiy
	ldda32 xiy, 32328
	ld w, (xiy)
	cp w, 0xF0
	jr c, AccompSeq_ExtVelFlags_Dispatch
	ordi8 13285, 4

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
	bitda 2, 32287
	jr nz, AccompSeq_FadeOut_Active
	jr AccompSeq_FadeOut_Return

AccompSeq_FadeOut_Active:
	bitda 7, 32292
	jr z, AccompSeq_FadeOut_Return
	ldda16 xwa, 32368
	dec 1, wa
	stda16 32368, xwa
	cp wa, 0xFFFF
	jr nz, AccompSeq_FadeOut_Periodic
	anddi8 32292, 127
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
	bitda 0, 32292
	jr z, AccompSeq_FadeOut_Ch2Volume
	ldda8 l, 32370
	xor h, h
	ldda16 xwa, 32368
	mul xwa, xhl
	ldto_werp DE, 0xE2
	ldw hl, 0x800
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	ld e, a
	ldb w, 0x5
	ldb a, 0xD1
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_Ch2Volume:
	bitda 1, 32292
	jr z, AccompSeq_FadeOut_ChReturn
	ldda8 l, 32371
	xor h, h
	ldda16 xwa, 32368
	mul xwa, xhl
	ldto_werp DE, 0xE2
	ldw hl, 0x800
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	ld e, a
	ldb w, 0x5
	ldb a, 0xD2
	call AccompSeq_SendMidiEvent

AccompSeq_FadeOut_ChReturn:
	ret

AccompSeq_PortaFadeOut:
	bitda 7, 32292
	jr z, AccompSeq_PortaFade_Return
	ldda8 w, 32340
	cp w, 0xD0
	jr nz, AccompSeq_PortaFade_Return
	ldda8 w, 32341
	cps w, 5
	jr nz, AccompSeq_PortaFade_Return
	push xhl
	push xde
	ldda8 l, 32343
	xor h, h
	ldda16 xwa, 32368
	mul xwa, xhl
	ldto_werp DE, 0xE2
	ldw hl, 0x800
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	pop xde
	pop xhl

AccompSeq_PortaFade_Return:
	ret

AccompSeq_ManualMidiMode1:
	ordi8 32533, 2
	jr AccompSeq_ManualMidi_CheckAllNotes

AccompSeq_ManualMidiMode2:
	ordi8 32533, 8

AccompSeq_ManualMidi_CheckAllNotes:
	cp l, 0x7F
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	cps h, 3
	jr nz, AccompSeq_ManualMidi_SaveAndCall
	call AccompSeq_AllNotesOff
	jr AccompSeq_ManualMidi_ClearFlags

AccompSeq_ManualMidi_SaveAndCall:
	ldda8 a, 49278
	push xwa
	push xhl
	call Voice_DecodeNoteParam
	call Voice_DecodeNoteChannel
	stdi8 49278, 1
	cps h, 0
	jr z, AccompSeq_ManualMidi_SetChannel
	stdi8 49278, 2
	cps h, 1
	jr z, AccompSeq_ManualMidi_SetChannel
	stdi8 49278, 4

AccompSeq_ManualMidi_SetChannel:
	pop xhl
	call AccompSeq_ProcessAfterNote
	pop xwa
	stda8 49278, a

AccompSeq_ManualMidi_ClearFlags:
	anddi8 32533, 253
	anddi8 32533, 247
	ret

AccompSeq_LargeCodeBlock1:
	.byte 0xb3, 0x45, 0xbb, 0x01, 0x44, 0xc1, 0x56, 0x7e
	.byte 0x21, 0xbb, 0x02, 0x41, 0xc1, 0x57, 0x7e, 0x21
	.byte 0xbb, 0x03, 0x41, 0xc1, 0x58, 0x7e, 0x21, 0xbb
	.byte 0x04, 0x41, 0x1e, 0x01, 0x00, 0x0e, 0xcd, 0x33
	.byte 0x07, 0x66, 0x06, 0xcc, 0xce, 0x10, 0xcd, 0xcc
	.byte 0x7f, 0x0e, 0x21, 0x9f, 0x20, 0x7f, 0x25, 0x7f
	.byte 0x1e, 0x0b, 0x00, 0x0e, 0x21, 0xdf, 0x20, 0x7f
	.byte 0x25, 0x7f, 0x1e, 0x01, 0x00, 0x0e, 0x2d, 0x43
	.byte 0xec, 0x7a, 0x00, 0x00, 0x06, 0x06, 0x9b, 0x04
	.byte 0x25, 0x9b, 0x02, 0x21, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x45, 0x1e, 0x8c, 0xfe, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x44, 0x1e, 0x84, 0xfe, 0xf3, 0x07, 0xf4, 0xec
	.byte 0x41, 0x1e, 0x7c, 0xfe, 0xbb, 0x04, 0x55, 0x06
	.byte 0x00, 0x4d, 0x0e, 0xd8, 0xa8, 0xf1, 0x68, 0x04
	.byte 0x50, 0xf1, 0x6a, 0x04, 0x41, 0xf1, 0x1c, 0x7e
	.byte 0x50, 0xf1, 0x1e, 0x7e, 0x41, 0x0e, 0xc1, 0x62
	.byte 0x7e, 0x21, 0xc1, 0x34, 0x04, 0x20, 0xf1, 0x62
	.byte 0x7e, 0x40, 0xc8, 0xf1, 0x66, 0x42, 0xf1, 0x5f
	.byte 0x7e, 0xc8, 0x66, 0x3c, 0xc1, 0x5f, 0x7e, 0x3c
	.byte 0xfe, 0xc1, 0x60, 0x7e, 0x27, 0xc1, 0x61, 0x7e
	.byte 0x26, 0xc1, 0x24, 0x7e, 0x21, 0xc0, 0x03, 0xc1
	.byte 0xc9, 0xd8, 0x6e, 0x06, 0x1d, 0x0f, 0xe7, 0xf6
	.byte 0x68, 0x04, 0x1d, 0x76, 0xe9, 0xf6, 0x06, 0x06
	.byte 0xc1, 0x15, 0x04, 0x23, 0xf1, 0x6a, 0x04, 0x43
	.byte 0xf1, 0x72, 0x04, 0x43, 0xd8, 0xa8, 0xc1, 0x16
	.byte 0x04, 0x21, 0xf1, 0x68, 0x04, 0x50, 0x06, 0x00
	.byte 0x0e

AccompSeq_UpdatePosition:
	cpdi8 32338, 0
	jr nz, AccompSeq_UpdatePos_Part2
	ldda32 xwa, 32357
	anddi8 32365, 254
	jr AccompSeq_UpdatePos_Store

AccompSeq_UpdatePos_Part2:
	ldda32 xwa, 32361
	anddi8 32365, 254

AccompSeq_UpdatePos_Store:
	stda16 32324, xwa
	ldto_werp WA, 0xE2
	stda16 32322, xwa
	ret

AccompSeq_JumpTable:
	.byte 0x1b, 0x51, 0xe6, 0xf6, 0x1b, 0x61, 0xea, 0xf6
	.byte 0x1b, 0xec, 0xea, 0xf6

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
	.byte 0x1b, 0xdd, 0xea, 0xf6, 0xc1, 0x7d, 0xc0, 0x21
	.byte 0xc9, 0xcf, 0x09, 0x7e, 0xa0, 0x00, 0xc1, 0x7f
	.byte 0xc0, 0x21, 0xc9, 0x33, 0x07, 0x66, 0x16, 0x1e
	.byte 0xfa, 0x03, 0x27, 0x7f, 0x26, 0x03, 0xc1, 0x7e
	.byte 0xc0, 0x21, 0xc9, 0x33, 0x07, 0x66, 0x03, 0x1e
	.byte 0x83, 0x03, 0x78, 0x81, 0x00, 0xc9, 0xcc, 0x3f
	.byte 0xc9, 0xd8, 0x66, 0x7a, 0xc1, 0x7e, 0xc0, 0x21
	.byte 0xc1, 0x7f, 0xc0, 0xc1, 0xc9, 0xcc, 0x3f, 0xc9
	.byte 0xd8, 0x66, 0x6b, 0xc8, 0xd0, 0xd8, 0x8b, 0x44
	.byte 0x3a, 0xec, 0xf6, 0x00, 0xc3, 0x07, 0xf0, 0xec
	.byte 0x26, 0xc1, 0x12, 0xfd, 0x27, 0xcf, 0xcf, 0x11
	.byte 0x66, 0x54, 0xcf, 0xcf, 0x12, 0x66, 0x4f, 0xcf
	.byte 0xcf, 0x0f, 0x66, 0x05, 0xcf, 0xcf, 0x10, 0x6e
	.byte 0x24, 0x44, 0x00, 0x8a, 0x1e, 0x00, 0xcf, 0xcf
	.byte 0x10, 0x6e, 0x06, 0xec, 0xc8, 0x10, 0x00, 0x00
	.byte 0x00, 0xce, 0xee, 0x01, 0xc3, 0x03, 0xf0, 0xed
	.byte 0x27, 0xce, 0x61, 0xc3, 0x03, 0xf0, 0xed, 0x26
	.byte 0xcf, 0xcf, 0x0e, 0x6b, 0x21, 0x1d, 0x75, 0x14
	.byte 0xf7, 0xce, 0xd8, 0x66, 0x19, 0xc1, 0x0b, 0x7f
	.byte 0x3f, 0x00, 0x6e, 0x12, 0xf1, 0x7a, 0x7e, 0xc8
	.byte 0x66, 0x05, 0x1e, 0xac, 0x02, 0x68, 0x07, 0x1e
	.byte 0x03, 0x03, 0x1d, 0x7a, 0xec, 0xf6, 0x0e

AccompSeq_PostNoteProcess:
	cps h, 0
	jr z, AccompSeq_PostNote_Return
	cpdi8 32523, 0
	jr nz, AccompSeq_PostNote_Return
	calr AccompSeq_OutputEvent
	call AccompSeq_ProcessChordChange

AccompSeq_PostNote_Return:
	ret

AccompSeq_InitPartFull:
	calr AccompSeq_ResetMidiState
	stda8 32293, l
	stda8 32294, h
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
	and l, 0xF
	call Voice_DecodeBankIndex
	and xhl, 0xFFFF
	ld xwa, xhl
	add xwa, 0x1E8800
	stda16 32298, xwa
	ldto_werp WA, 0xE2
	stda16 32296, xwa
	jr AccompSeq_LookupStyle_Return

AccompSeq_LookupStyle_Internal:
	call Voice_DecodeNoteChannel2
	xor xwa, xwa
	ldw wa, 0x20
	mul xwa, xhl
	add xwa, 0xE4C1A6
	stda16 32298, xwa
	ldto_werp WA, 0xE2
	stda16 32296, xwa

AccompSeq_LookupStyle_Return:
	ret

AccompSeq_LoadParams:
	ldda16 xwa, 32296
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32298
	ld xiy, xwa
	cpdi8 32293, 128
	jr nc, AccompSeq_LoadParams_Alt
	ld a, (xiy + 256)
	and a, 0x1D
	stda8 32295, a
	ld xwa, (xiy + 1)
	add xwa, 0x6
	stda16 32302, xwa
	ldto_werp WA, 0xE2
	stda16 32300, xwa
	ld xwa, (xiy + 5)
	stda16 32310, xwa
	ldto_werp WA, 0xE2
	stda16 32308, xwa
	ld a, (xiy + 16)
	bit 0, a
	jr z, AccompSeq_LoadParams_Bit0Set
	ordi8 32295, 2

AccompSeq_LoadParams_Bit0Set:
	ld xwa, (xiy + 17)
	add xwa, 0x6
	stda16 32306, xwa
	ldto_werp WA, 0xE2
	stda16 32304, xwa
	ld xwa, (xiy + 21)
	stda16 32314, xwa
	ldto_werp WA, 0xE2
	stda16 32312, xwa
	jr AccompSeq_LoadParams_OverrideCheck

AccompSeq_LoadParams_Alt:
	ld a, (xiy + 256)
	and a, 0x1D
	stda8 32295, a
	ld wa, (xiy + 3)
	stda16 32300, xwa
	lds wa, 6
	stda16 32302, xwa

AccompSeq_LoadParams_OverrideCheck:
	bitda 0, 32351
	jr z, AccompSeq_LoadParams_Return
	ldda16 xwa, 32300
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32302
	stda32 32357, xwa
	ldda16 xwa, 32304
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32306
	stda32 32361, xwa
	lds wa, 0
	ldda8 a, 1075
	dec 1, a
	and a, 0x7
	sll wa, 2
	ld xiy, 0xF6EFEC
	ld_sril3 XWA, 0x07, 0xF4, 0xE0
	add xwa, 0x6
	stda16 32302, xwa
	stda16 32306, xwa
	ldto_werp WA, 0xE2
	stda16 32300, xwa
	stda16 32304, xwa

AccompSeq_LoadParams_Return:
	ret

AccompSeq_InitMidiEvents:
	ldb a, 0xD0
	ldb w, 0x3
	ldb e, 0x0
	calr AccompSeq_WriteMidiToBuffer
	stdi8 32370, 127
	stdi8 32371, 127
	ldda16 xwa, 32296
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32298
	ld xiy, xwa
	bitda 0, 32295
	jr z, AccompSeq_InitMidi_Ch2
	ld wa, (xiy + 9)
	ld e, w
	ld w, a
	ldb a, 0xC1
	stda8 32320, w
	and e, 0xF
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch1Flags
	or e, 0x10
	and w, 0x7F

AccompSeq_InitMidi_Ch1Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 12)
	ld e, a
	ldb w, 0x4
	ldb a, 0xD1
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 13)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Reverb
	ldb e, 0x7F

AccompSeq_InitMidi_Ch1Reverb:
	ldb w, 0x7
	ldb a, 0xD1
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 14)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch1Chorus
	ldb e, 0x7F

AccompSeq_InitMidi_Ch1Chorus:
	ldb w, 0x3
	ldb a, 0xD1
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Ch2:
	bitda 1, 32295
	jr z, AccompSeq_InitMidi_Return
	ld wa, (xiy + 25)
	ld e, w
	ld w, a
	ldb a, 0xC2
	stda8 32321, w
	and e, 0xF
	bit 7, w
	jr z, AccompSeq_InitMidi_Ch2Flags
	or e, 0x10
	and w, 0x7F

AccompSeq_InitMidi_Ch2Flags:
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 28)
	ld e, a
	ldb w, 0x4
	ldb a, 0xD2
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 29)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Reverb
	ldb e, 0x7F

AccompSeq_InitMidi_Ch2Reverb:
	ldb w, 0x7
	ldb a, 0xD2
	calr AccompSeq_WriteMidiToBuffer
	ld a, (xiy + 30)
	ldb e, 0x0
	bit 0, a
	jr z, AccompSeq_InitMidi_Ch2Chorus
	ldb e, 0x7F

AccompSeq_InitMidi_Ch2Chorus:
	ldb w, 0x3
	ldb a, 0xD2
	calr AccompSeq_WriteMidiToBuffer

AccompSeq_InitMidi_Return:
	ret

AccompSeq_InitPlayState:
	anddi8 32292, 127
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
	stda16 32316, xwa
	stda16 32318, xwa
	ldda8 a, 32292
	ldda8 w, 32295
	bit 0, w
	jr z, AccompSeq_InitPlay_Ch2Flag
	or a, 0x1

AccompSeq_InitPlay_Ch2Flag:
	bit 1, w
	jr z, AccompSeq_InitPlay_Store
	or a, 0x2

AccompSeq_InitPlay_Store:
	stda8 32292, a
	ldda8 w, 49278
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
	ldda8 a, 32292
	and a, 0xFC
	stda8 32292, a
	calr AccompSeq_SendAllOff
	popw hl
	calr AccompSeq_ResetMidiState
	stda8 32293, l
	stda8 32294, h
	calr AccompSeq_LookupStyleData
	calr AccompSeq_LoadParams
	calr AccompSeq_InitMidiEvents
	calr AccompSeq_InitPlayState
	ret

AccompSeq_HandleSpecialMode:
	ldda8	a, 32292
	and	a, 3
	jr	z, 16
	pushw	hl
	ldda8	a, 32292
	and	a, 252
	stda8	32292, a
	calr	417
	popw	hl
	ldda8	a, 64786
	cp	a, 13
	jr	z, 5
	cp	a, 14
	jr	nz, 37
	stdi8	32523, 1
	calr	64858
	and	l, 15
	stda8	32532, l
	ldda8	w, 49278
	ldb	a, 1
	bit	0, w
	jr	nz, 9
	ldb	a, 2
	bit	1, w
	jr	nz, 2
	ldb	a, 4
	jr	15
	stdi8	32578, 57
	call	16144626
	ldb	a, 8
	call	16694689
	ret

AccompSeq_OutputEvent:
	pushw hl
	pushw hl
	call Voice_DecodeNoteChannel
	ld bc, hl
	popw hl
	ld wa, hl
	ld hl, bc
	cpdi16 10410, 0
	jr nz, AccompSeq_Output_CheckFilter
	cpdi8 36150, 138
	jr nz, AccompSeq_Output_CheckManual
	cpdi8 3429, 2
	jr nz, AccompSeq_Output_CheckManual

AccompSeq_Output_CheckFilter:
	bitda 3, 32533
	jr nz, AccompSeq_Output_CheckManual
	pushw wa
	pushw hl
	call Tempo_ProcessExpressionChange
	popw hl
	popw wa

AccompSeq_Output_CheckManual:
	bitda 1, 32533
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
	.byte 0xdd, 0x61, 0xd9, 0xf5, 0x63, 0x03, 0x9b, 0x00
	.byte 0x25, 0x0e, 0xc1, 0x7e, 0xc0, 0x21, 0xc9, 0x33
	.byte 0x07, 0x6e, 0x07, 0xc1, 0x7a, 0x7e, 0x3c, 0xfe
	.byte 0x68, 0x3c, 0xc1, 0x7a, 0x7e, 0x3e, 0x01, 0xc1
	.byte 0x0b, 0x7f, 0x21, 0xc9, 0xd8, 0x66, 0x08, 0x21
	.byte 0x00, 0xf1, 0x0b, 0x7f, 0x41, 0x68, 0x27, 0xc1
	.byte 0x24, 0x7e, 0x21, 0xc9, 0xcc, 0x03, 0xc9, 0xd8
	.byte 0x66, 0x1c, 0xf1, 0x27, 0x7e, 0xca, 0x66, 0x13
	.byte 0xf1, 0x24, 0x7e, 0xcf, 0x6e, 0x0d, 0xf1, 0x70
	.byte 0x7e, 0x02, 0x00, 0x08, 0xc1, 0x24, 0x7e, 0x3e
	.byte 0x80, 0x68, 0x03, 0x1e, 0x7c, 0x00, 0x0e

AccompSeq_AllNotesOffImpl:
	ldda8 a, 32292
	and a, 0x3
	cps a, 0
	jr z, AccompSeq_AllNotesOff_Send
	bitda 2, 32295
	jr z, AccompSeq_AllNotesOff_Stop
	bitda 7, 32292
	jr nz, AccompSeq_AllNotesOff_Stop
	stdi16 32368, 2048
	ordi8 32292, 128
	jr AccompSeq_AllNotesOff_Send

AccompSeq_AllNotesOff_Stop:
	calr AccompSeq_CleanupSequence

AccompSeq_AllNotesOff_Send:
	ldb l, 0x7F
	ldb h, 0x3
	calr AccompSeq_OutputEvent
	ret

AccompSeq_ClearPendingFlag:
	; --- Routine 1: clear flag at (0x7F0B) if nonzero (15 bytes) ---
	ldda8	a, 32523
	cps	a, 0
	jr z, AccompSeq_ClearPending_Return
	ldb a, 0x00
	stda8	32523, a
AccompSeq_ClearPending_Return:
	ret
AccompSeq_GuardedNoteOff:
	; --- Routine 2: multi-guard, all-register push, call F99490 (61 bytes) ---
	ldda8	a, 49277
	cp a, 0x1c
	jr nz, AccompSeq_GuardedNote_Return
	ldda8	a, 49278
	andda8	a, 49279
	and a, 0x03
	cps	a, 0
	jr z, AccompSeq_GuardedNote_Return
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13		; cp (0x8D34), 0x13  [C1 prefix]
	jr z, AccompSeq_GuardedNote_Return
	.byte 0xc1, 0x38, 0x8d, 0x3f, 0xc8		; cp (0x8D38), 0xC8  [C1 prefix]
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
	ldda8 a, 32292
	and a, 0x3
	cps a, 0
	jr z, AccompSeq_Cleanup_ClearFlags
	anddi8 32292, 127
	ordi8 1055, 8
	ldda8 a, 32292
	and a, 0xFC
	stda8 32292, a
	calr AccompSeq_SendAllOff

AccompSeq_Cleanup_ClearFlags:
	anddi8 32366, 254
	anddi8 32367, 254
	ret

AccompSeq_SendAllOff:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x7F
	calr AccompSeq_WriteMidiToBuffer
	ldb a, 0xD0
	ldb w, 0x3
	ldb e, 0x0
	calr AccompSeq_WriteMidiToBuffer
	stdi8 32370, 127
	stdi8 32371, 127
	ld xhl, 0x7AEC
	ld wa, (xhl + 4)
	ld (xhl + 6), wa
	ldw wa, 0xF6
	ld (xhl + 8), wa
	ld xhl, 0x7BEC
	ld wa, (xhl + 4)
	ld (xhl + 6), wa
	ldw wa, 0xF6
	ld (xhl + 8), wa
	ldb a, 0x8
	xor w, w
	ld xhl, 0x7D6C

AccompSeq_SendAllOff_Loop1:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop1
	ldb a, 0x8
	xor w, w
	ld xhl, 0x7DB4

AccompSeq_SendAllOff_Loop2:
	ld (xhl), w
	add hl, 0x9
	dec 1, a
	cps a, 0
	jr nz, AccompSeq_SendAllOff_Loop2
	ret

AccompSeq_MidiFilterCodeBlock:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0x0e, 0x0e, 0xc1
	.byte 0x0b, 0x7f, 0x3f, 0x00, 0x66, 0x04, 0x1b, 0x39
	.byte 0xec, 0xf6, 0x25, 0x0c, 0xc1, 0x12, 0xfd, 0x21
	.byte 0xc8, 0x33, 0x07, 0x66, 0x0a, 0xc9, 0x61, 0xcd
	.byte 0xf1, 0x63, 0x02, 0xcd, 0x89, 0x68, 0x09, 0xc9
	.byte 0x69, 0xc9, 0xcf, 0xff, 0x6e, 0x02, 0x21, 0x00
	.byte 0xf1, 0x12, 0xfd, 0x41, 0xf1, 0x78, 0x7e, 0x00
	.byte 0x00, 0xc1, 0xe0, 0xe3, 0x3e, 0x10, 0x68, 0x39
	.byte 0xc1, 0x78, 0x7e, 0x3f, 0x00, 0x6e, 0x10, 0xf1
	.byte 0x79, 0x7e, 0x41, 0xf1, 0x78, 0x7e, 0x00, 0x01
	.byte 0xc1, 0xde, 0xe3, 0x3e, 0x10, 0x68, 0x22, 0xc1
	.ascii "y~! "
	.byte 0x0a, 0xc8, 0x81, 0xc9
	.byte 0xd8, 0x66, 0x02, 0xc9, 0x69, 0xcd, 0xf1, 0x63
	.byte 0x02, 0xcd, 0x89, 0xf1, 0x12, 0xfd, 0x41, 0xf1
	.byte 0x78, 0x7e, 0x00, 0x00, 0xc1, 0xde, 0xe3, 0x3e
	.byte 0x10, 0x0e, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x05, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02, 0x00
	.byte 0x01, 0x00

AccompSeq_ProcessChordChange:
	anddi8 32366, 254
	anddi8 32367, 254
	anddi8 32351, 252
	pushw hl
	calr AccompSeq_CompareChord
	popw hl
	ldda8 a, 32292
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
	bitda 1, 32351
	jr nz, AccompSeq_ChordChange_ApplyOverride
	bitda 0, 32351
	jr z, AccompSeq_ChordChange_Return
	ordi8 32366, 1
	ordi8 32367, 1

AccompSeq_ChordChange_ApplyOverride:
	anddi8 32351, 253
	call AccompSeq_SetupChannels

AccompSeq_ChordChange_Return:
	ret

AccompSeq_CompareChord:
	bitda 0, 12931
	jr z, AccompSeq_CompareChord_Return
	bitda 2, 10418
	jr nz, AccompSeq_CompareChord_Return
	stda8 32352, l
	stda8 32353, h
	ldda16 xwa, 32298
	pushw wa
	ldda16 xwa, 32296
	pushw wa
	calr AccompSeq_ResetMidiState
	calr AccompSeq_LookupStyleData
	ldda16 xwa, 32296
	ldfr_werp WA, 0xE2
	ldda16 xwa, 32298
	ld xiy, xwa
	ld a, (xiy + 256)
	bit 4, a
	jr z, AccompSeq_CompareChord_RestorePos
	ldda8 a, 1075
	ldda8 w, 1046
	inc 1, w
	cp a, w
	jr z, AccompSeq_CompareChord_Match
	ordi8 32351, 2
	jr AccompSeq_CompareChord_RestorePos

AccompSeq_CompareChord_Match:
	ordi8 32351, 1

AccompSeq_CompareChord_RestorePos:
	popw wa
	stda16 32296, xwa
	popw wa
	stda16 32298, xwa

AccompSeq_CompareChord_Return:
	ret

AccompSeq_SetupChannels:
	ei 6
	ldda8 c, 1045
	stda8 32355, c
	lds wa, 0
	ldda8 a, 1046
	stda8 32356, a
	stda8 1130, c
	stda8 1138, c
	stda16 1128, xwa
	ei 0
	bitda 0, 32292
	jr z, AccompSeq_SetupCh2
	stdi8 32338, 0
	ld xwa, 0x7E40
	stda32 32328, xwa
	ld xwa, 0x7E72
	stda32 32372, xwa
	ldda16 xwa, 32300
	stda16 32322, xwa
	ldda16 xwa, 32302
	stda16 32324, xwa
	ldda16 xwa, 32316
	stda16 32326, xwa
	ldda8 a, 32366
	stda8 32365, a
	calr AccompSeq_ParseSequenceData
	ldda8 a, 32365
	stda8 32366, a
	ldda16 xwa, 32326
	stda16 32316, xwa
	ldda16 xwa, 32324
	stda16 32302, xwa
	ldda16 xwa, 32322
	stda16 32300, xwa

AccompSeq_SetupCh2:
	bitda 1, 32292
	jr z, AccompSeq_SetupCh_Return
	stdi8 32338, 1
	ld xwa, 0x7E41
	stda32 32328, xwa
	ld xwa, 0x7E73
	stda32 32372, xwa
	ldda16 xwa, 32304
	stda16 32322, xwa
	ldda16 xwa, 32306
	stda16 32324, xwa
	ldda16 xwa, 32318
	stda16 32326, xwa
	ldda8 a, 32367
	stda8 32365, a
	calr AccompSeq_ParseSequenceData
	ldda8 a, 32365
	stda8 32367, a
	ldda16 xwa, 32326
	stda16 32318, xwa
	ldda16 xwa, 32324
	stda16 32306, xwa
	ldda16 xwa, 32322
	stda16 32304, xwa

AccompSeq_SetupCh_Return:
	ret

AccompSeq_ParseSequenceData:
	lds bc, 0
	ldda8 d, 32356
	ldda8 e, 32355
	anddi8 32339, 254

AccompSeq_SeqParse_Loop:
	bitda 0, 32339
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
	cp a, 0xD2
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xD1
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xD3
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xD4
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xD5
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xD7
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0xC0
	jr z, AccompSeq_SeqParse_MidiEvent
	cp a, 0x84
	jp_24 z, 0xF6EFCD
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_EndMark:
	calr AccompSeq_CleanupSequence
	ordi8 32339, 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeAdvance:
	ldda16 xbc, 32326
	inc 1, bc
	ld b, c
	xor c, c
	cp de, bc
	jr nc, AccompSeq_SeqParse_TimeStore
	ordi8 32339, 1
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TimeStore:
	incdi16 1, 32326
	calr AccompSeq_AdvancePosition
	jr AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_MidiEvent:
	calr AccompSeq_CheckPatternEnd
	ldda16 xbc, 32326
	ld c, a
	ldda8 b, 32326
	cp de, bc
	jr nc, AccompSeq_SeqParse_CheckNoteOn
	ordi8 32339, 1
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
	cp a, 0xC0
	jr nz, AccompSeq_SeqParse_CtrlChg
	ldb a, 0x1
	cpdi8 32338, 0
	jr z, AccompSeq_SeqParse_ProgChg_SetCh
	ldb a, 0x2

AccompSeq_SeqParse_ProgChg_SetCh:
	or a, 0xC0
	stda8 32340, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	stda8 32341, a
	calr AccompSeq_AdvancePosition
	ld a, (xiy)
	stda8 32342, a
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	and e, 0xF
	stda8 32343, e
	bitda 0, 32342
	jr z, AccompSeq_SeqParse_ProgChg_Flags
	or e, 0x10

AccompSeq_SeqParse_ProgChg_Flags:
	ldda8 a, 32340
	ldda8 w, 32341
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	push xiy
	ldda32 xiy, 32328
	ldda8 a, 32341
	and a, 0x7F
	bitda 0, 32342
	jr z, AccompSeq_SeqParse_ProgChg_Store
	or a, 0x80

AccompSeq_SeqParse_ProgChg_Store:
	ld (xiy), a
	pop xiy
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_CtrlChg:
	and a, 0xF
	stda8 32341, a
	ldb a, 0x1
	cpdi8 32338, 0
	jr z, AccompSeq_SeqParse_CtrlChg_SetCh
	ldb a, 0x2

AccompSeq_SeqParse_CtrlChg_SetCh:
	or a, 0xD0
	stda8 32340, a
	calr AccompSeq_AdvancePosition
	calr AccompSeq_AdvancePosition
	ld e, (xiy)
	stda8 32342, e
	ldda8 w, 32341
	ldda8 a, 32340
	calr AccompSeq_WriteMidiToBuffer
	calr AccompSeq_AdvancePosition
	ldda8 w, 32341
	ldda8 a, 32340
	and a, 0xF0
	cp a, 0xD0
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	cps w, 5
	jr nz, AccompSeq_SeqParse_CtrlChg_Loop
	ldda8 a, 32342
	push xiy
	ldda32 xiy, 32372
	ld (xiy), a
	pop xiy

AccompSeq_SeqParse_CtrlChg_Loop:
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_TempoReset:
	ldda32 xwa, 32357
	cpdi8 32338, 0
	jr z, AccompSeq_SeqParse_TempoStore
	ldda32 xwa, 32361

AccompSeq_SeqParse_TempoStore:
	stda16 32324, xwa
	ldto_werp WA, 0xE2
	stda16 32322, xwa
	jp AccompSeq_SeqParse_Loop

AccompSeq_SeqParse_Return:
	ret

AccompSeq_TempoScaleTable:
	.long LABEL_F6F060
	.long LABEL_F6F057
	.long LABEL_F6F04D
	.long LABEL_F6F042
	.long LABEL_F6F036
	.long LABEL_F6F029
	.long LABEL_F6F01B
	.long LABEL_F6F00C
LABEL_F6F00C:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
LABEL_F6F01B:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x81, 0x81, 0x81, 0x81, 0x81, 0x84
LABEL_F6F029:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x81, 0x81, 0x81, 0x81, 0x84
LABEL_F6F036:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x81, 0x81, 0x81, 0x84
LABEL_F6F042:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x81, 0x81, 0x84
LABEL_F6F04D:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	add	d, (xbc)
LABEL_F6F057:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81
	.byte 0x84
LABEL_F6F060:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x84
	.byte 0x79, 0xf0, 0xf6, 0x00, 0x78, 0xf0, 0xf6, 0x00
	.long LABEL_F6F07E
	.long LABEL_F6F078

LABEL_F6F078:
	ret

LABEL_F6F079:
	call LABEL_F6F352
	ret

LABEL_F6F07E:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xFFFF
	jr nz, LABEL_F6F08C
	call Voice_InitBankData

LABEL_F6F08C:
	ret

LABEL_F6F08D:
	.byte 0x1b, 0x52, 0xf3, 0xf6

LABEL_F6F091:
	jp Voice_InitBankTables

