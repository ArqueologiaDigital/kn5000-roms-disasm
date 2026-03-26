; =============================================================================
; Sequencer Event Playback & Accompaniment (4K lines)
; =============================================================================
;
; Sequencer event buffer processing, voice slot scanning, note/channel
; decoding, accompaniment playback loop, tempo event dispatch, MIDI
; sustain handling, accompaniment mute queuing, and ring buffer management.
; =============================================================================


SeqEvt_EntryPoint1:
	jp SeqEvt_InitAndProcess

SeqEvt_EntryPoint2:
	jp SeqEvt_InitVoiceScan

SeqEvt_InitAndProcess:
	.incbin "includes/generated/v7_transplant_SeqEvt_InitAndProcess.bin"
SeqEvt_ProcessReadLoop:
	.incbin "includes/generated/v7_transplant_SeqEvt_ProcessReadLoop.bin"
SeqEvt_ProcessLoop_Check:
	cp (xhl + 4), ix
	jr nz, SeqEvt_ClassifyEventType
	jp SeqEvt_ProcessLoopRet

SeqEvt_ClassifyEventType:
	.incbin "includes/generated/v7_transplant_SeqEvt_ClassifyEventType.bin"
SeqEvt_CheckType91:
	.incbin "includes/generated/v7_transplant_SeqEvt_CheckType91.bin"
SeqEvt_CheckTypeC0:
	.incbin "includes/generated/v7_transplant_SeqEvt_CheckTypeC0.bin"
SeqEvt_CheckTypeD0:
	.incbin "includes/generated/v7_transplant_SeqEvt_CheckTypeD0.bin"
SeqEvt_TypeD0_SetCount:
	.incbin "includes/generated/v7_transplant_SeqEvt_TypeD0_SetCount.bin"
SeqEvt_ReadAndDispatchEntry:
	.incbin "includes/generated/v7_transplant_SeqEvt_ReadAndDispatchEntry.bin"
SeqEvt_DispatchByChannel:
	ld a, w
	and a, 0xf0
	cp a, 0x90
	jr z, SeqEvt_ProcessNoteOn
	jr SeqEvt_ProcessNonNoteEvent

SeqEvt_ProcessNoteOn:
	.incbin "includes/generated/v7_transplant_SeqEvt_ProcessNoteOn.bin"
SeqEvt_SlotScanLoop:
	.incbin "includes/generated/v7_transplant_SeqEvt_SlotScanLoop.bin"
SeqEvt_CheckSlotActive:
	bit_dri 7, 0x07, 0xec, 0xf0
	jr z, SeqEvt_AdvanceSlotIndex
	ld xiy, xhl
	and xix, 0xffff
	add xiy, xix
	cp (xiy + 2), w
	jr z, SeqEvt_SlotMatchFound

SeqEvt_AdvanceSlotIndex:
	.incbin "includes/generated/v7_transplant_SeqEvt_AdvanceSlotIndex.bin"
SeqEvt_SlotMatchFound:
	calr SeqEvt_WriteNoteOff

SeqEvt_AfterSlotScan:
	popw wa
	xor ix, ix

SeqEvt_FindFreeSlotLoop:
	.incbin "includes/generated/v7_transplant_SeqEvt_FindFreeSlotLoop.bin"
SeqEvt_AdvanceFreeSlotIdx:
	.incbin "includes/generated/v7_transplant_SeqEvt_AdvanceFreeSlotIdx.bin"
SeqEvt_AllocateNewSlot:
	calr SeqEvt_WriteNoteOnRotating

SeqEvt_WriteEventAndContinue:
	calr SeqEvt_WriteVoiceParams
	jp SeqEvt_ProcessLoop_Check

SeqEvt_ProcessNonNoteEvent:
	calr SeqEvt_HandleControlEvent
	jp SeqEvt_ProcessLoop_Check

SeqEvt_ProcessTempoEvent:
	calr SeqEvt_CalcTempoOffset
	jp SeqEvt_ProcessLoop_Check

SeqEvt_ProcessLoopRet:
	ret

SeqEvt_WriteNoteOff:
	.incbin "includes/generated/v7_transplant_SeqEvt_WriteNoteOff.bin"
SeqEvt_WriteNoteOnRotating:
	.incbin "includes/generated/v7_transplant_SeqEvt_WriteNoteOnRotating.bin"
SeqEvt_RotateIndexDone:
	ld a, w
	and a, 0xf0
	ret

SeqEvt_WriteVoiceParams:
	.incbin "includes/generated/v7_transplant_SeqEvt_WriteVoiceParams.bin"
SeqEvt_AdjustNoteOctave:
	.incbin "includes/generated/v7_transplant_SeqEvt_AdjustNoteOctave.bin"
SeqEvt_WriteRemainingParams:
	.incbin "includes/generated/v7_transplant_SeqEvt_WriteRemainingParams.bin"
SeqEvt_UpdateReadPosition:
	.incbin "includes/generated/v7_transplant_SeqEvt_UpdateReadPosition.bin"
SeqEvt_HandleControlEvent:
	.incbin "includes/generated/v7_transplant_SeqEvt_HandleControlEvent.bin"
SeqEvt_HandleExtendedCtrl:
	ldb_sri A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	pushw bc
	ldb_sri C, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ldb_sri A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	and a, 0xf
	bit 0, c
	jr z, SeqEvt_SetExtendedFlag
	or a, 0x10

SeqEvt_SetExtendedFlag:
	.incbin "includes/generated/v7_transplant_SeqEvt_SetExtendedFlag.bin"
SeqEvt_WriteSustainValue:
	calr SeqEvtBuf_WriteBytePreserve

SeqEvt_SaveReadPosAndRet:
	.incbin "includes/generated/v7_transplant_SeqEvt_SaveReadPosAndRet.bin"
SeqEvt_CalcTempoOffset:
	.incbin "includes/generated/v7_transplant_SeqEvt_CalcTempoOffset.bin"
SeqEvt_UpdateMinTempo:
	.incbin "includes/generated/v7_transplant_SeqEvt_UpdateMinTempo.bin"
SeqEvt_HandleBufferWrap:
	.incbin "includes/generated/v7_transplant_SeqEvt_HandleBufferWrap.bin"
SeqEvt_CalcTempoRet:
	ret

SeqEvtBuf_WriteBytePreserve:
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	pushw wa
	pushw wa
	call SeqEvtBuf_WriteByte
	inc 2, xsp
	popw wa
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	ret

SeqEvtBuf_SizeConstant:
	ret

SeqEvtBuf_AdvanceReadPos:
	inc 1, ix
	cp ix, (xhl + 2)
	jr le, SeqEvtBuf_AdvanceRet
	ld ix, (xhl + 256)

SeqEvtBuf_AdvanceRet:
	ret

SeqEvt_RotationOffsetTable:
	.byte 0x00, 0x00, 0x09, 0x00, 0x12, 0x00, 0x1b, 0x00
	.byte 0x24, 0x00, 0x2d, 0x00, 0x36, 0x00, 0x3f, 0x00

SeqEvt_InitVoiceScan:
	.incbin "includes/generated/v7_transplant_SeqEvt_InitVoiceScan.bin"
SeqEvt_VoiceScanDone:
	ret

Voice_ScanSlotMetric:
	xor iy, iy

Voice_ScanLoop:
	.incbin "includes/generated/v7_transplant_Voice_ScanLoop.bin"
Voice_CheckSlotBit:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, Voice_ReadSlotParams
	jr Voice_ParamComplete

Voice_ReadSlotParams:
	.incbin "includes/generated/v7_transplant_Voice_ReadSlotParams.bin"
Voice_SubtractBaseFreq:
	subda16 xwa, 1134
	bit 7, a
	jr z, Voice_StoreMetricValue
	add a, 0x60

Voice_StoreMetricValue:
	.incbin "includes/generated/v7_transplant_Voice_StoreMetricValue.bin"
Voice_ParamComplete:
	.incbin "includes/generated/v7_transplant_Voice_ParamComplete.bin"
Voice_ScanLoopDone:
	ret

Voice_DecodeNoteChannel:
	cp l, 0x80
	jr c, Voice_DecodeNonPercussion
	xor h, h
	and l, 0xf
	sla hl, 1
	push xix
	ld xix, Voice_NoteChannelTable1_0x402
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	jr Voice_DecodeRet

Voice_DecodeNonPercussion:
	ld wa, hl
	and wa, 0x7f
	sla wa, 3
	and h, 0x3
	sla h, 1
	or a, h
	ld hl, wa
	push xix
	ld xix, Voice_NoteChannelTable1_0x2
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix

Voice_DecodeRet:
	ret

Voice_NoteChannelTable1:
	.zero 24
	nop
	nop
	nop
	nop
	di
	ei	1
	reti
	.byte 0x01
	nop
	nop
	ei	4
	ei	2
	.zero 16
	nop
	nop
	nop
	nop
	reti
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	reti
	nop
	reti
	push	sr
	.zero 8
	nop
	nop
	nop
	nop
	ei	3
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	reti
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	ei	5
	nop
	nop
	nop
	nop
	nop
	nop
	reti
	pop	sr
	.zero 24
	nop
	nop
	nop
	nop
	push	3
	nop
	nop
	nop
	nop
	nop
	nop
	push	1
	nop
	nop
	nop
	nop
	nop
	nop
	push	2
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	4
	nop
	nop
	nop
	nop
	nop
	nop
	push	5
	nop
	nop
	nop
	nop
	push	0
	nop
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	ldio	2, 0
	nop
	nop
	nop
	ldio	0, 8
	.byte 0x01
	nop
	nop
	nop
	nop
	ldio	3, 8
	.byte 0x04
	ldio	5, 0
	nop
	nop
	nop
	nop
	nop
	.zero 32
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x0a
	nop
	.zero 8
	nop
	nop
	nop
	nop
	ldwio	2, 0
	ldwio	4, 0
	ldwio	1, 0
	nop
	nop
	nop
	nop
	ldwio	3, 0
	nop
	nop
	nop
	nop
	ldwio	5, 0
	.zero 72
	nop
	nop
	nop
	nop
	pushw	3
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x0b
	halt
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	2
	nop
	nop
	nop
	pushw	1
	nop
	nop
	nop
	nop
	nop
	pushw	0
	nop
	pushw	4
	nop
	nop
	nop
	nop
	nop
	.zero 64
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	pop	sr
	halt
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	nop
	.zero 8
	nop
	nop
	nop
	nop
	incf
	nop
	incf
	pop	sr
	nop
	nop
	nop
	nop
	.byte 0x04
	halt
	incf
	push	sr
	nop
	nop
	nop
	nop
	incf
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	incf
	halt
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	halt
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	halt
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	.byte 0x04
	pop	sr
	.byte 0x04, 0x04
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	push	sr
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	push	sr
	halt
	.zero 32
	nop
	nop
	nop
	nop
	nop
	nop
	push	sr
	.byte 0x04
	nop
	nop
	nop
	nop
	push	sr
	.byte 0x01
	nop
	nop
	pop	sr
	nop
	nop
	nop
	push	sr
	push	sr
	nop
	nop
	pop	sr
	.byte 0x01
	nop
	nop
	push	sr
	pop	sr
	nop
	nop
	pop	sr
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	pop	sr
	pop	sr
	nop
	nop
	nop
	nop
	nop
	nop
	pop	sr
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	pop	sr
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	.byte 0x04
	push	sr
	nop
	nop
	incf
	.byte 0x01
	nop
	nop
	.zero 8
	nop
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
	.byte 0x04, 0x01
	nop
	nop
	.zero 80
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	sr
	nop
	nop
	.zero 8
	nop
	nop
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
	.zero 16
	nop
	nop
	nop
	nop
	.byte 0x01
	pop	sr
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop	sr
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x04
	nop
	nop
	.zero 16
	nop
	nop
	decf
	nop
	decf
	.byte 0x01
	decf
	push	sr
	decf
	pop	sr
	decf
	.byte 0x04
	decf
	halt
	ret
	nop
	ret
	.byte 0x01
	ret
	push	sr
	ret
	pop	sr
	ret
	.byte 0x04
	ret
	halt
	incf
	nop
	incf
	nop
	incf
	nop
	incf
	nop
	and	l, 15
	and	h, 7
	sla	l, 4
	sla	h, 1
	or	l, h
	xor	h, h
	push	xix
	ld	xix, Voice_NoteChannelTable1_0x43F
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	ret
	jrl	f, 28929
	.byte 0x01
	jrl	le, 31233
	.byte 0x01
	jrl	ov, 29953
	.byte 0x01
	nop
	nop
	nop
	nop
	ld	xwa, 0x7c017901
	.byte 0x01
	jrl	32001
	.byte 0x01
	jrl	ugt, 1
	nop
	nop
	nop
	.byte 0x50
	push	sr
	pop	xbc
	.byte 0x01
	pop	xde
	.byte 0x01
	pop	xhl
	.byte 0x01
	pop	xwa
	push	sr
	.byte 0x53
	push	sr
	nop
	nop
	nop
	nop
	pop	xbc
	pop	sr
	pop	xde
	pop	sr
	pop	xhl
	pop	sr
	pop	xix
	pop	sr
	pop	xiy
	pop	sr
	pop	xiz
	pop	sr
	nop
	nop
	nop
	nop
	jr	mi, 1
	jr	z, 1
	jr	le, 3
	popw	iy
	.byte 0x01
	popw	iy
	push	sr
	ld	xiz, 1
	nop
	ld	xhl, 0x41014a02
	.byte 0x01
	ld	xde, 0x4b024201
	.byte 0x01
	nop
	nop
	nop
	nop
	pop	sr
	.byte 0x01
	pop	sr
	push	sr
	.byte 0x04
	push	sr
	ldwio	1, 260
	incf
	push	sr
	nop
	nop
	nop
	nop
	ldio	1, 3
	pop	sr
	ldio	2, 13
	push	sr
	reti
	.byte 0x01
	pushw	2
	nop
	nop
	nop
	.byte 0x1a, 0x01, 0x1a
	push	sr
	pop_f
	push	sr
	jp	0x021b01
	jp	3
	nop
	nop
	ex_ff
	.byte 0x01
	ccf
	.byte 0x01
	zcf
	.byte 0x01
	scf
	.byte 0x01
	push_a
	push	sr
	pop_a
	push	sr
	nop
	nop
	nop
	nop
	ldb	a, 2
	ldb	d, 1
	ldb	c, 1
	ldb	e, 1
	ldb	c, 3
	ldb	h, 1
	nop
	nop
	nop
	nop
	ldw	iz, 0x3501
	.byte 0x01
	ldw	ix, 0x3002
	.byte 0x01
	ldw	iz, 0x3103
	push	sr
	nop
	nop
	nop
	nop
	ld	xiy, 0x46016301
	push	sr
	ld	xiy, 0x48014702
	.byte 0x01
	nop
	nop
	nop
	nop
	.byte 0x80, 0x01, 0x81, 0x01, 0x82, 0x01, 0x83, 0x01
	.byte 0x84, 0x01, 0x85, 0x01
	nop
	nop
	nop
	nop
	.byte 0x86, 0x01, 0x87, 0x01
	add	(xwa+1), a
	.byte 0x01
	add	(xde+1), c
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	.zero 15

Voice_DecodeNoteChannel2:
	ld wa, hl
	and wa, 0x7f
	sla wa, 3
	and h, 0x3
	sla h, 1
	or a, h
	ld hl, wa
	push xix
	ld xix, Voice_NoteChannelTable2_0x2
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	ret

Voice_NoteChannelTable2:
	.zero 24
	nop
	nop
	nop
	nop
	ldb	d, 0
	ldb	e, 0
	pushw	hl
	nop
	nop
	nop
	pushw	wa
	nop
	ldb	h, 0
	.zero 16
	nop
	nop
	nop
	nop
	pushw	iz
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	de
	nop
	pushw	ix
	nop
	.zero 8
	nop
	nop
	nop
	nop
	ldb	l, 0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	sp
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	bc
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	iy
	nop
	.zero 24
	nop
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x37
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	xwa
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	xde
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	xhl
	nop
	nop
	nop
	nop
	nop
	ldw	iz, 0
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	ldw	de, 0
	nop
	nop
	nop
	ldw	wa, 0x3100
	nop
	nop
	nop
	nop
	nop
	ldw	hl, 0x3400
	nop
	ldw	iy, 0
	nop
	nop
	nop
	nop
	nop
	.zero 32
	nop
	nop
	nop
	nop
	nop
	nop
	push	xix
	nop
	.zero 8
	nop
	nop
	nop
	nop
	push	xiz
	nop
	nop
	nop
	ld	xwa, 0x3d000000
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	xsp
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x41
	nop
	nop
	nop
	.zero 72
	nop
	nop
	nop
	nop
	ld	xiy, 0
	nop
	nop
	nop
	nop
	nop
	.byte 0x47
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	ld	xix, 0
	nop
	ld	xhl, 0
	nop
	nop
	nop
	ld	xde, 0x46000000
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 64
	nop
	nop
	nop
	nop
	di
	nop
	nop
	nop
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	nop
	nop
	nop
	nop
	ldb	a, 0
	ldb	b, 0
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x1e
	nop
	.zero 8
	nop
	nop
	nop
	nop
	popw	wa
	nop
	popw	hl
	nop
	nop
	nop
	nop
	nop
	call	0x4a00
	nop
	nop
	nop
	nop
	popw	ix
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	popw	iy
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	.byte 0x1f
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ldb	c, 0
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	jp	7168
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	incf
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	scf
	nop
	.zero 32
	nop
	nop
	nop
	nop
	nop
	nop
	rcf
	nop
	nop
	nop
	nop
	nop
	decf
	nop
	nop
	nop
	ccf
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	zcf
	nop
	nop
	nop
	retd	0
	nop
	push_a
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop_a
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ex_ff
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x17
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	.byte 0x1a
	nop
	nop
	nop
	popw	bc
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	push_f
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop_f
	nop
	nop
	nop
	.zero 80
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.zero 8
	nop
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
	.zero 16
	nop
	nop
	nop
	nop
	push	0
	nop
	nop
	nop
	nop
	nop
	nop
	reti
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop	sr
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	0
	nop
	nop
	nop
	nop
	nop
	ldio	0, 0
	nop
	nop
	nop
	nop
	nop
	ldwio	0, 0
	.zero 18

Voice_DecodeBankIndex:
	and l, 0x7f
	cp l, 0xc
	jr c, Voice_ClampBankIndex
	xor l, l

Voice_ClampBankIndex:
	xor h, h
	sla hl, 1
	push xix
	ld xix, Voice_BankIndexTable_0x2
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	ret

Voice_BankIndexTable:
	.byte 0x00, 0x00, 0x20, 0x00, 0x30, 0x00, 0x40, 0x00
	.byte 0x50, 0x00, 0x60, 0x00, 0x70, 0x00, 0x80, 0x00
	.byte 0x90, 0x00, 0xa0, 0x00, 0xb0, 0x00, 0xc0, 0x00
	.byte 0xd0, 0x00, 0x20, 0x00, 0x20, 0x00, 0x20, 0x00
	.byte 0x20, 0x00, 0x20, 0x00

Voice_DecodeNoteParam:
	cp l, 0x80
	jr c, Voice_DecodeStandard
	ldb h, 0x1
	cp l, 0x8c
	jr c, Voice_DecodePercussion
	ldb l, 0x80

Voice_DecodePercussion:
	jr Voice_DecodeParamRet

Voice_DecodeStandard:
	ld wa, hl
	and wa, 0x7f
	sla wa, 3
	and h, 0x3
	sla h, 1
	or a, h
	ld hl, wa
	push xix
	ld xix, Voice_NoteParamTable_0x2
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix

Voice_DecodeParamRet:
	ret

Voice_NoteParamTable:
	.byte 0x00, 0x00, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x04, 0x01, 0x04, 0x02
	.byte 0x04, 0x02, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x03, 0x01, 0x03, 0x02
	.byte 0x03, 0x03, 0x00, 0x01, 0x07, 0x01, 0x07, 0x01
	.byte 0x07, 0x01, 0x00, 0x01, 0x08, 0x01, 0x08, 0x02
	.byte 0x08, 0x02, 0x00, 0x01, 0x08, 0x01, 0x08, 0x02
	.byte 0x08, 0x02, 0x00, 0x01, 0x0a, 0x01, 0x0a, 0x01
	.byte 0x0a, 0x01, 0x00, 0x01, 0x0b, 0x02, 0x0b, 0x02
	.byte 0x0b, 0x02, 0x00, 0x01, 0x0c, 0x02, 0x0c, 0x02
	.byte 0x0c, 0x02, 0x00, 0x01, 0x0d, 0x02, 0x0d, 0x02
	.byte 0x0d, 0x02, 0x00, 0x01, 0x0d, 0x02, 0x0d, 0x02
	.byte 0x0d, 0x02, 0x00, 0x01, 0x0d, 0x02, 0x0d, 0x02
	.byte 0x0d, 0x02, 0x00, 0x01, 0x11, 0x01, 0x11, 0x01
	.byte 0x11, 0x01, 0x00, 0x01, 0x11, 0x01, 0x11, 0x01
	.byte 0x11, 0x01, 0x00, 0x01, 0x12, 0x01, 0x12, 0x01
	.byte 0x12, 0x01, 0x00, 0x01, 0x13, 0x01, 0x13, 0x01
	.byte 0x13, 0x01, 0x00, 0x01, 0x14, 0x02, 0x14, 0x02
	.byte 0x14, 0x02, 0x00, 0x01, 0x15, 0x02, 0x15, 0x02
	.byte 0x15, 0x02, 0x00, 0x01, 0x16, 0x01, 0x16, 0x01
	.byte 0x16, 0x01, 0x00, 0x01, 0x16, 0x01, 0x16, 0x01
	.byte 0x16, 0x01, 0x00, 0x01, 0x16, 0x01, 0x16, 0x01
	.byte 0x16, 0x01, 0x00, 0x01, 0x19, 0x02, 0x19, 0x02
	.byte 0x19, 0x02, 0x00, 0x01, 0x1a, 0x01, 0x1a, 0x02
	.byte 0x1a, 0x02, 0x00, 0x01, 0x1b, 0x01, 0x1b, 0x02
	.byte 0x1b, 0x03, 0x00, 0x01, 0x1b, 0x01, 0x1b, 0x02
	.byte 0x1b, 0x03, 0x00, 0x01, 0x1b, 0x01, 0x1b, 0x02
	.byte 0x1b, 0x03, 0x00, 0x01, 0x1b, 0x01, 0x1b, 0x02
	.byte 0x1b, 0x03, 0x00, 0x01, 0x1b, 0x01, 0x1b, 0x02
	.byte 0x1b, 0x03, 0x00, 0x01, 0x21, 0x02, 0x21, 0x02
	.byte 0x21, 0x02, 0x00, 0x01, 0x21, 0x02, 0x21, 0x02
	.byte 0x21, 0x02, 0x00, 0x01, 0x21, 0x02, 0x21, 0x02
	.byte 0x21, 0x02, 0x00, 0x01, 0x23, 0x01, 0x23, 0x01
	.byte 0x23, 0x03, 0x00, 0x01, 0x24, 0x01, 0x24, 0x01
	.byte 0x24, 0x01, 0x00, 0x01, 0x25, 0x01, 0x25, 0x01
	.byte 0x25, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x26, 0x01, 0x26, 0x01
	.byte 0x26, 0x01, 0x00, 0x01, 0x30, 0x01, 0x30, 0x01
	.byte 0x30, 0x01, 0x00, 0x01, 0x31, 0x02, 0x31, 0x02
	.byte 0x31, 0x02, 0x00, 0x01, 0x31, 0x02, 0x31, 0x02
	.byte 0x31, 0x02, 0x00, 0x01, 0x31, 0x02, 0x31, 0x02
	.byte 0x31, 0x02, 0x00, 0x01, 0x34, 0x02, 0x34, 0x02
	.byte 0x34, 0x02, 0x00, 0x01, 0x35, 0x01, 0x35, 0x01
	.byte 0x35, 0x01, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x36, 0x01, 0x36, 0x01
	.byte 0x36, 0x03, 0x00, 0x01, 0x40, 0x01, 0x40, 0x01
	.byte 0x40, 0x01, 0x00, 0x01, 0x41, 0x01, 0x41, 0x01
	.byte 0x41, 0x01, 0x00, 0x01, 0x42, 0x01, 0x42, 0x02
	.byte 0x42, 0x02, 0x00, 0x01, 0x43, 0x02, 0x43, 0x02
	.byte 0x43, 0x02, 0x00, 0x01, 0x45, 0x01, 0x45, 0x02
	.byte 0x45, 0x02, 0x00, 0x01, 0x45, 0x01, 0x45, 0x02
	.byte 0x45, 0x02, 0x00, 0x01, 0x46, 0x01, 0x46, 0x02
	.byte 0x46, 0x02, 0x00, 0x01, 0x47, 0x01, 0x47, 0x01
	.byte 0x47, 0x01, 0x00, 0x01, 0x48, 0x01, 0x48, 0x01
	.byte 0x48, 0x01, 0x00, 0x01, 0x48, 0x01, 0x48, 0x01
	.byte 0x48, 0x01, 0x00, 0x01, 0x4a, 0x01, 0x4a, 0x01
	.byte 0x4a, 0x01, 0x00, 0x01, 0x4b, 0x01, 0x4b, 0x01
	.byte 0x4b, 0x01, 0x00, 0x01, 0x4b, 0x01, 0x4b, 0x01
	.byte 0x4b, 0x01, 0x00, 0x01, 0x4d, 0x01, 0x4d, 0x02
	.byte 0x4d, 0x02, 0x00, 0x01, 0x4d, 0x01, 0x4d, 0x02
	.byte 0x4d, 0x02, 0x00, 0x01, 0x4d, 0x01, 0x4d, 0x02
	.byte 0x4d, 0x02, 0x00, 0x01, 0x50, 0x02, 0x50, 0x02
	.byte 0x50, 0x02, 0x00, 0x01, 0x50, 0x02, 0x50, 0x02
	.byte 0x50, 0x02, 0x00, 0x01, 0x50, 0x02, 0x50, 0x02
	.byte 0x50, 0x02, 0x00, 0x01, 0x53, 0x02, 0x53, 0x02
	.byte 0x53, 0x02, 0x00, 0x01, 0x53, 0x02, 0x53, 0x02
	.byte 0x53, 0x02, 0x00, 0x01, 0x53, 0x02, 0x53, 0x02
	.byte 0x53, 0x02, 0x00, 0x01, 0x53, 0x02, 0x53, 0x02
	.byte 0x53, 0x02, 0x00, 0x01, 0x53, 0x02, 0x53, 0x02
	.byte 0x53, 0x02, 0x00, 0x01, 0x58, 0x02, 0x58, 0x02
	.byte 0x58, 0x02, 0x00, 0x01, 0x59, 0x01, 0x59, 0x01
	.byte 0x59, 0x03, 0x00, 0x01, 0x5a, 0x01, 0x5a, 0x01
	.byte 0x5a, 0x03, 0x00, 0x01, 0x5b, 0x01, 0x5b, 0x01
	.byte 0x5b, 0x03, 0x00, 0x01, 0x5c, 0x03, 0x5c, 0x03
	.byte 0x5c, 0x03, 0x00, 0x01, 0x5d, 0x03, 0x5d, 0x03
	.byte 0x5d, 0x03, 0x00, 0x01, 0x5e, 0x03, 0x5e, 0x03
	.byte 0x5e, 0x03, 0x00, 0x01, 0x5e, 0x03, 0x5e, 0x03
	.byte 0x5e, 0x03, 0x00, 0x01, 0x62, 0x03, 0x62, 0x03
	.byte 0x62, 0x03, 0x00, 0x01, 0x62, 0x03, 0x62, 0x03
	.byte 0x62, 0x03, 0x00, 0x01, 0x62, 0x03, 0x62, 0x03
	.byte 0x62, 0x03, 0x00, 0x01, 0x63, 0x01, 0x63, 0x01
	.byte 0x63, 0x01, 0x00, 0x01, 0x63, 0x01, 0x63, 0x01
	.byte 0x63, 0x01, 0x00, 0x01, 0x65, 0x01, 0x65, 0x01
	.byte 0x65, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x66, 0x01, 0x66, 0x01
	.byte 0x66, 0x01, 0x00, 0x01, 0x70, 0x01, 0x70, 0x01
	.byte 0x70, 0x01, 0x00, 0x01, 0x71, 0x01, 0x71, 0x01
	.byte 0x71, 0x01, 0x00, 0x01, 0x72, 0x01, 0x72, 0x01
	.byte 0x72, 0x01, 0x00, 0x01, 0x72, 0x01, 0x72, 0x01
	.byte 0x72, 0x01, 0x00, 0x01, 0x74, 0x01, 0x74, 0x01
	.byte 0x74, 0x01, 0x00, 0x01, 0x75, 0x01, 0x75, 0x01
	.byte 0x75, 0x01, 0x00, 0x01, 0x75, 0x01, 0x75, 0x01
	.byte 0x75, 0x01, 0x00, 0x01, 0x75, 0x01, 0x75, 0x01
	.byte 0x75, 0x01, 0x00, 0x01, 0x78, 0x01, 0x78, 0x01
	.byte 0x78, 0x01, 0x00, 0x01, 0x79, 0x01, 0x79, 0x01
	.byte 0x79, 0x01, 0x00, 0x01, 0x7a, 0x01, 0x7a, 0x01
	.byte 0x7a, 0x01, 0x00, 0x01, 0x7b, 0x01, 0x7b, 0x01
	.byte 0x7b, 0x01, 0x00, 0x01, 0x7c, 0x01, 0x7c, 0x01
	.byte 0x7c, 0x01, 0x00, 0x01, 0x7d, 0x01, 0x7d, 0x01
	.byte 0x7d, 0x01, 0x00, 0x01, 0x7d, 0x01, 0x7d, 0x01
	.byte 0x7d, 0x01, 0x00, 0x01, 0x7d, 0x01, 0x7d, 0x01
	.byte 0x7d, 0x01

AccPlay_Entry:
	jp AccPlay_MainDispatch
AccPlay_JumpTable:
	jp	AccPlay_ProcessVoiceBank
	jp	AccPlay_ToggleCodeFragment

AccPlay_ToggleEntry:
	jp AccPlay_CheckAndToggle

AccPlay_StopEntry:
	jp AccPlay_StopAndReset

AccPlay_MainDispatch:
	.incbin "includes/generated/v7_transplant_AccPlay_MainDispatch.bin"
AccPlay_RunningWithBit0:
	calr AccPlay_HandleStopState
	jr AccPlay_ContinueMainLoop

AccPlay_StartNewAccomp:
	calr AccPlay_InitializeStart
	jr AccPlay_ContinueMainLoop

AccPlay_CheckPrevRunning:
	.incbin "includes/generated/v7_transplant_AccPlay_CheckPrevRunning.bin"
AccPlay_StopSequencer:
	calr AccPlay_StopIfRunning

AccPlay_ContinueMainLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_ContinueMainLoop.bin"
AccPlay_UpdateStateFlags:
	.incbin "includes/generated/v7_transplant_AccPlay_UpdateStateFlags.bin"
AccPlay_DispatchRet:
	ret

AccPlay_InitializeStart:
	.incbin "includes/generated/v7_transplant_AccPlay_InitializeStart.bin"
AccPlay_MainUpdateLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_MainUpdateLoop.bin"
AccPlay_PostEvent9E_Enable:
	.incbin "includes/generated/v7_transplant_AccPlay_PostEvent9E_Enable.bin"
AccPlay_PostEvent9E_Disable:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPlay_SetIndicatorAndRet:
	.incbin "includes/generated/v7_transplant_AccPlay_SetIndicatorAndRet.bin"
AccPlay_DispatchSeqStart:
	.incbin "includes/generated/v7_transplant_AccPlay_DispatchSeqStart.bin"
AccPlay_DispatchSeqRet:
	ret

AccPlay_HandleStopState:
	.incbin "includes/generated/v7_transplant_AccPlay_HandleStopState.bin"
AccPlay_CheckResumeState:
	.incbin "includes/generated/v7_transplant_AccPlay_CheckResumeState.bin"
TempoEvt_ProcessLoop:
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	jr nz, TempoEvt_ReadAndClassify
	jp AccPlay_PostLoopCleanup

TempoEvt_ReadAndClassify:
	.incbin "includes/generated/v7_transplant_TempoEvt_ReadAndClassify.bin"
TempoEvt_StoreBankParam:
	.incbin "includes/generated/v7_transplant_TempoEvt_StoreBankParam.bin"
TempoEvt_CheckHighBit:
	.incbin "includes/generated/v7_transplant_TempoEvt_CheckHighBit.bin"
TempoEvt_ContinueProcessing:
	calr TempoRingBuf_ReadLoop
	jp TempoEvt_ProcessLoop

TempoEvt_DispatchEvent:
	.incbin "includes/generated/v7_transplant_TempoEvt_DispatchEvent.bin"
TempoEvt_HandleEndMarker:
	cp a, 0x81
	jr nz, TempoEvt_HandleNoteEvent
	calr AccPlay_HandleEndMarkerEvt
	jr TempoEvent_ContinueLoop

TempoEvt_HandleNoteEvent:
	cp w, 0x90
	jr nz, TempoEvt_HandleD2Event
	calr AccPlay_ProcessNoteEvent
	jr TempoEvent_ContinueLoop

TempoEvt_HandleD2Event:
	cp a, 0xd2
	jr nz, TempoEvt_HandleD1Sustain
	calr MidiSeq_HandleD2Event
	jr TempoEvent_ContinueLoop

TempoEvt_HandleD1Sustain:
	cp a, 0xd1
	jr nz, TempoEvt_HandleD3Sustain
	calr MidiSeq_ProcessSustainEvent
	jr TempoEvent_ContinueLoop

TempoEvt_HandleD3Sustain:
	cp a, 0xd3
	jr nz, TempoEvt_HandleProgChange
	calr MidiSeq_ProcessSustainEvent
	jr TempoEvent_ContinueLoop

TempoEvt_HandleProgChange:
	cp w, 0xc0
	jr nz, TempoEvt_HandleCtrlChange
	calr MidiSeq_HandleProgChange
	jr TempoEvent_ContinueLoop

TempoEvt_HandleCtrlChange:
	cp w, 0xb0
	jr nz, TempoEvt_HandleUnknown
	calr MidiSeq_HandleCtrlChange
	jr TempoEvent_ContinueLoop

TempoEvt_HandleUnknown:
	calr TempoRingBuf_ReadLoop

TempoEvent_ContinueLoop:
	jp TempoEvt_ProcessLoop

AccPlay_PostLoopCleanup:
	calr AccPlay_TrackMeasureChange
	calr AccPlay_TrackVoiceCount
	ret

AccPlay_StopIfRunning:
	.incbin "includes/generated/v7_transplant_AccPlay_StopIfRunning.bin"
AccPlay_StopRet:
	ret

AccPlay_ProcessVoiceBank:
	calr Voice_GetBankEntryPointer
	ld a, (xiy + 256)
	bit 0, a
	jr z, AccPlay_VoiceBankRet
	calr Voice_ReleaseChain
	calr Voice_InitSlotTemplate

AccPlay_VoiceBankRet:
	ret

Voice_GetBankEntryPointer:
	.incbin "includes/generated/v7_transplant_Voice_GetBankEntryPointer.bin"
Voice_CalcBankOffset:
	ld xiy, 0x1e8820
	ldb w, 0x10
	mul8rr a, w
	and xwa, 0xffff
	add xiy, xwa
	ret

Voice_ReleaseChain:
	ld hl, (xiy + 3)
	cp hl, 0xffff
	jr z, Voice_ReleaseChainDone

Voice_ReleaseChainLoop:
	.incbin "includes/generated/v7_transplant_Voice_ReleaseChainLoop.bin"
Voice_ReleaseChainDone:
	ret

Voice_InitSlotTemplate:
	ld a, (xiy)
	push xiy
	ld xix, xiy
	ld xiy, Voice_SlotTemplateData
	ldw bc, 0x8
	ldirw
	pop xiy
	and a, 0xf0
	ld (xiy), a
	ret

Voice_SlotTemplateData:
	nop
	nop
	nop
	swi	7
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	jrl	nc, 64
	nop
	nop

AccPlay_SetupSoundParams:
	.incbin "includes/generated/v7_transplant_AccPlay_SetupSoundParams.bin"
AccPlay_SetupJumpTarget:
	jp AccPlay_SyncParamsRet
AccPlay_SyncVoiceParams:
	.incbin "includes/generated/v7_transplant_AccPlay_SyncVoiceParams.bin"
AccPlay_SyncParamsRet:
	ret

AccPlay_AllocateVoiceSlot:
	.incbin "includes/generated/v7_transplant_AccPlay_AllocateVoiceSlot.bin"
AccPlay_CheckReverbFlag:
	ld (xiy + 13), a
	xor a, a
	ldb_d8 w, (0xfd66)
	bit 3, w
	jr z, AccPlay_CheckChorusFlag
	or a, 0x1

AccPlay_CheckChorusFlag:
	ld (xiy + 14), a
	ldb_d8 a, (0xfd6a)
	and a, 0x7f
	ld (xiy + 12), a
	ret

AccPlay_UpdateBankParams:
	push xiy
	push xhl
	push xwa
	calr Voice_GetBankEntryPointer
	ldb_d8 a, (0xfd62)
	ldb_d8 w, (0xfd63)
	ld (xiy + 9), wa
	xor a, a
	ldb_d8 w, (0xfd66)
	bit 6, w
	jr z, AccPlay_UpdateReverbParam
	or a, 0x1

AccPlay_UpdateReverbParam:
	ld (xiy + 13), a
	xor a, a
	ldb_d8 w, (0xfd66)
	bit 3, w
	jr z, AccPlay_UpdateChorusParam
	or a, 0x1

AccPlay_UpdateChorusParam:
	ld (xiy + 14), a
	ldb_d8 a, (0xfd6a)
	and a, 0x7f
	ld (xiy + 12), a
	pop xwa
	pop xhl
	pop xiy
	ret

AccPlay_UnusedCodeFragment:
	calr	2006
	bit	7, a
	jr	z, -8
	ret

AccPlay_ExtractVoiceSlot:
	.incbin "includes/generated/v7_transplant_AccPlay_ExtractVoiceSlot.bin"
AccPlay_ProcessNoteEvent:
	.incbin "includes/generated/v7_transplant_AccPlay_ProcessNoteEvent.bin"
AccPlay_NoteNoSlotMatch:
	calr AccPlay_FindSlotByChannel

AccPlay_NoteEventRet:
	ret

AccPlay_NoteWithSlot:
	.incbin "includes/generated/v7_transplant_AccPlay_NoteWithSlot.bin"
AccPlay_NoteNoSlotAvail:
	jp AccPlay_NoteAllocRet

AccPlay_NoteAllocAndWrite:
	.incbin "includes/generated/v7_transplant_AccPlay_NoteAllocAndWrite.bin"
AccPlay_NoteSetType91:
	.incbin "includes/generated/v7_transplant_AccPlay_NoteSetType91.bin"
AccPlay_NoteAllocRet:
	ret

AccPlay_NoteParamTable:
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x11, 0x00
	.byte 0x01, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x11, 0x11, 0x00

AccPlay_FindActiveSlot:
	.incbin "includes/generated/v7_transplant_AccPlay_FindActiveSlot.bin"
AccPlay_ScanActiveLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_ScanActiveLoop.bin"
AccPlay_ScanActiveFail:
	ld xhl, 0xffff

AccPlay_ScanActiveRet:
	ret

AccPlay_FindSlotByChannel:
	.incbin "includes/generated/v7_transplant_AccPlay_FindSlotByChannel.bin"
AccPlay_ChannelScanLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_ChannelScanLoop.bin"
AccPlay_ChannelScanFail:
	jr AccPlay_NoteReleaseRet

AccPlay_ChannelSlotFound:
	.incbin "includes/generated/v7_transplant_AccPlay_ChannelSlotFound.bin"
AccPlay_CalcNoteOffset:
	sub c, a
	ld e, c
	cps d, 0
	jr nz, AccPlay_WriteNoteRelease
	cps e, 2
	jr nc, AccPlay_WriteNoteRelease
	ldb e, 0x2

AccPlay_WriteNoteRelease:
	.incbin "includes/generated/v7_transplant_AccPlay_WriteNoteRelease.bin"
AccPlay_NoteReleaseRet:
	ret

AccPlay_HandleEndMarkerEvt:
	.incbin "includes/generated/v7_transplant_AccPlay_HandleEndMarkerEvt.bin"
AccPlay_IncrementHoldLoop:
	ld a, (xhl)
	bit 7, a
	jr z, AccPlay_HoldLoopAdvance
	ld a, (xhl + 1)
	cp a, 0x7f
	jr nc, AccPlay_HoldLoopAdvance
	inc 1, a
	ld (xhl + 1), a

AccPlay_HoldLoopAdvance:
	.incbin "includes/generated/v7_transplant_AccPlay_HoldLoopAdvance.bin"
MidiSeq_ProcessSustainEvent:
	.incbin "includes/generated/v7_transplant_MidiSeq_ProcessSustainEvent.bin"
MidiSeq_SustainFixup:
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleD2Event:
	.incbin "includes/generated/v7_transplant_MidiSeq_HandleD2Event.bin"
MidiSeq_HandleProgChange:
	.incbin "includes/generated/v7_transplant_MidiSeq_HandleProgChange.bin"
MidiSeq_ProgChangeSetReverb:
	ld (xhl + 5), w
	lds de, 6
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleCtrlChange:
	.incbin "includes/generated/v7_transplant_MidiSeq_HandleCtrlChange.bin"
MidiSeq_CtrlCheckType:
	ld w, (xhl + 3)
	and w, 0x1f
	ld e, (xhl + 4)
	ld d, (xhl + 5)
	cp a, 0x17
	jr nz, MidiSeq_CheckSostenuto
	cp w, 0x8
	jr nz, MidiSeq_CheckSostenuto
	ldb a, 0xd4
	ld (xhl), a
	and e, 0x7f
	ld (xhl + 2), e
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_CheckSostenuto:
	cp a, 0x17
	jr nz, MidiSeq_SustainHandler
	cps w, 4
	jr nz, MidiSeq_SustainHandler
	bit 6, d
	jr z, MidiSeq_SustainHandler
	ldb a, 0xd7
	ld (xhl), a
	ldb a, 0x0
	bit 6, e
	jr z, MidiSeq_SostenutoValue
	ldb a, 0x7f

MidiSeq_SostenutoValue:
	ld (xhl + 2), a
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_SustainHandler:
	cp a, 0x17
	jr nz, MidiSeq_SustainRet
	cps w, 4
	jr nz, MidiSeq_SustainRet
	bit 3, d
	jr z, MidiSeq_SustainRet
	ldb a, 0xd3
	ld (xhl), a
	ldb a, 0x0
	bit 3, e
	jr z, MidiSeq_SoftPedalValue
	ldb a, 0x7f

MidiSeq_SoftPedalValue:
	ld (xhl + 2), a
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_SustainRet:
	ret

AccPlay_TrackMeasureChange:
	.incbin "includes/generated/v7_transplant_AccPlay_TrackMeasureChange.bin"
AccPlay_MeasureIncrement:
	.incbin "includes/generated/v7_transplant_AccPlay_MeasureIncrement.bin"
AccPlay_MeasureNotifyDone:
	.incbin "includes/generated/v7_transplant_AccPlay_MeasureNotifyDone.bin"
AccPlay_MeasureTrackRet:
	ret

AccPlay_TrackVoiceCount:
	.incbin "includes/generated/v7_transplant_AccPlay_TrackVoiceCount.bin"
AccPlay_VoiceCountNotify:
	.incbin "includes/generated/v7_transplant_AccPlay_VoiceCountNotify.bin"
AccPlay_VoiceCountRet:
	ret

AccPlay_MonitorParamState:
	.incbin "includes/generated/v7_transplant_AccPlay_MonitorParamState.bin"
AccPlay_InitVoiceBankState:
	calr AccPlay_RestoreVoiceBank

AccPlay_SaveCurrentState:
	.incbin "includes/generated/v7_transplant_AccPlay_SaveCurrentState.bin"
AccPlay_CompareAndSendProg:
	.incbin "includes/generated/v7_transplant_AccPlay_CompareAndSendProg.bin"
AccPlay_SendProgChange:
	call AccompSeq_SendMidiEvent

AccPlay_CompareReverbState:
	.incbin "includes/generated/v7_transplant_AccPlay_CompareReverbState.bin"
AccPlay_SetReverbValue:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_CompareChorusState:
	.incbin "includes/generated/v7_transplant_AccPlay_CompareChorusState.bin"
AccPlay_SetChorusValue:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_ParamMonitorRet:
	ret

AccPlay_RestoreVoiceBank:
	.incbin "includes/generated/v7_transplant_AccPlay_RestoreVoiceBank.bin"
AccPlay_SendBankProgram:
	.incbin "includes/generated/v7_transplant_AccPlay_SendBankProgram.bin"
AccPlay_RestoreReverbVal:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 13)
	ldb_d8 w, (0xfd66)
	and w, 0xbf
	bit 0, a
	jr z, AccPlay_WriteReverbFlag
	or w, 0x40

AccPlay_WriteReverbFlag:
	.incbin "includes/generated/v7_transplant_AccPlay_WriteReverbFlag.bin"
AccPlay_RestoreChorusVal:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 14)
	ldb_d8 w, (0xfd66)
	and w, 0xf7
	bit 0, a
	jr z, AccPlay_WriteChorusFlag
	or w, 0x8

AccPlay_WriteChorusFlag:
	.incbin "includes/generated/v7_transplant_AccPlay_WriteChorusFlag.bin"
AccPlay_ClearSlotTable:
	.incbin "includes/generated/v7_transplant_AccPlay_ClearSlotTable.bin"
AccPlay_ClearSlotLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_ClearSlotLoop.bin"
AccPlay_ClearSlotDone:
	ret

AccPlay_SaveMuteStates:
	.incbin "includes/generated/v7_transplant_AccPlay_SaveMuteStates.bin"
AccompSeq_QueueAllMutes:
	ldb e, 0x0
	ldb_d8 a, (0xf9c3)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x1
	ldb_d8 a, (0xf9dd)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x2
	ldb_d8 a, (0xf9f7)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x3
	ldb_d8 a, (0xfa11)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x4
	ldb_d8 a, (0xfa2b)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x5
	ldb_d8 a, (0xfa45)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x6
	ldb_d8 a, (0xfa5f)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x7
	ldb_d8 a, (0xfa79)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x8
	ldb_d8 a, (0xfa93)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x9
	ldb_d8 a, (0xfaad)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xa
	ldb_d8 a, (0xfac7)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xb
	ldb_d8 a, (0xfae1)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xc
	ldb_d8 a, (0xfafb)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xd
	ldb_d8 a, (0xfb15)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xe
	ldb_d8 a, (0xfb2f)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xf
	ldb_d8 a, (0xfb49)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x10
	ldb_d8 a, (0xfb63)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x11
	ldb_d8 a, (0xfb7d)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x12
	ldb_d8 a, (0xfb97)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x13
	ldb_d8 a, (0xfbb1)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x14
	ldb_d8 a, (0xfbcb)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x15
	ldb_d8 a, (0xfbe5)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x16
	ldb_d8 a, (0xfbff)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x19
	ldb_d8 a, (0xfc19)
	calr AccompSeq_QueueMuteEvent
	ret

AccompSeq_QueueMuteEvent:
	.incbin "includes/generated/v7_transplant_AccompSeq_QueueMuteEvent.bin"
AccPlay_RestoreMuteStates:
	.incbin "includes/generated/v7_transplant_AccPlay_RestoreMuteStates.bin"
Util_ExtractAndShiftBits:
	push xhl
	and xhl, 0xfff
	sla xhl, 8
	add xhl, 0x1e8b00
	ld xix, xhl
	pop xhl
	ret

Voice_FindFreeSlot:
	xor xix, xix
	lds bc, 0

Voice_FindLoop:
	ld hl, bc
	calr Util_ExtractAndShiftBits
	ld a, (xix)
	bit 7, a
	jr z, Voice_FindDone
	inc 1, bc
	cp bc, 0x39
	jr c, Voice_FindLoop
	ldw bc, 0xffff
	pushw bc
	calr AccPlay_InitAndStartLoop
	popw bc

Voice_FindDone:
	ld wa, bc
	ret

TempoRingBuf_ReadLoop:
	call TempoRingBuf_ReadByte
	ld a, l
	ret

MidiSeqBuf_ScanAllEntries:
	xor ix, ix

MidiSeqBuf_ScanLoop:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_ScanLoop.bin"
MidiSeqBuf_ScanDone:
	ret

MidiSeqBuf_ProcessEntries:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_ProcessEntries.bin"
MidiSeqBuf_ProcessLoop:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_ProcessLoop.bin"
MidiSeqBuf_ProcessDone:
	ret

MidiSeqBuf_AdvancePosition:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_AdvancePosition.bin"
MidiSeqBuf_AdvanceDone:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_AdvanceDone.bin"
MidiSeqBuf_AdvanceWritePos:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_AdvanceWritePos.bin"
MidiSeqBuf_WriteAdvDone:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_WriteAdvDone.bin"
MidiSeqBuf_WriteByte:
	.incbin "includes/generated/v7_transplant_MidiSeqBuf_WriteByte.bin"
AccPlay_InitAndStartLoop:
	.incbin "includes/generated/v7_transplant_AccPlay_InitAndStartLoop.bin"
AccPlay_ToggleCodeFragment:
	.incbin "includes/generated/v7_transplant_AccPlay_ToggleCodeFragment.bin"
AccPlay_CheckAndToggle:
	.incbin "includes/generated/v7_transplant_AccPlay_CheckAndToggle.bin"
AccPlay_ToggleRestart:
	.incbin "includes/generated/v7_transplant_AccPlay_ToggleRestart.bin"
AccPlay_ToggleRet:
	ret

AccPlay_StopAndReset:
	bitda 2, (1056)
	jr nz, AccPlay_StopResetRet
	lds wa, 0
	stb_d8 (1047), a
	stda16 (1048), xwa
	stb_d8 (1045), a
	stb_d8 (1046), a
	stb_d8 (1076), a
	stb_d8 (1077), a
	stb_d8 (1130), a
	stda16 (1128), xwa
	stdi8 (1056), 1
	stdi8 (1054), 1
	stdi8 (1055), 1

AccPlay_StopResetRet:
	ret

InitializeEast:
	.incbin "includes/generated/v7_transplant_InitializeEast.bin"
BitmapBmphk:
	cp xbc, 0x1e000a3
	jr z, BitmapBmphk_ReturnA3
	cp xbc, 0x1e000a2
	jr z, BitmapBmphk_ReturnA2
	cp xbc, 0x1e000a1
	jr z, BitmapBmphk_ReturnA1
	lds32 xhl, 0
	ret

BitmapBmphk_ReturnA1:
	lda_24 xhl, (Bitmap_Bmphk)
	ret

BitmapBmphk_ReturnA2:
	ld xhl, 0x64
	ret

BitmapBmphk_ReturnA3:
	ld xhl, 0x78
	ret

TtMdmenu:
	push xiz
	cp xbc, 0x1c0000c
	jr z, TtMdmenu_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdmenu_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdmenu_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdmenu_ReturnZero
	or xde, xde
	jr nz, TtMdmenu_ReturnZero
	call GetModeOld
	ld xiz, xhl
	call GetModeNow
	cp xhl, xiz
	jr z, TtMdmenu_ReturnZero
	ld xwa, 0x500001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent

TtMdmenu_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

TtVocalistWorkstation:
	cp xbc, 0x1c0000c
	jr z, TtVocalist_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtVocalist_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtVocalist_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtVocalist_ReturnZero
	or xde, xde
	jr nz, TtVocalist_ReturnZero
	ld xwa, 0xd70003
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xd7000e
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtVocalist_ReturnZero:
	lds32 xhl, 0
	ret

AcVocalGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, AcVocalGrid_FuncCallA
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, AcVocalGrid_ViewAccess
	cp xwa, 0x1e0008a
	jrl z, AcVocalGrid_StringCopy
	cp xwa, 0x1c00001
	jr z, AcVocalGrid_DialSetup
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, AcVocalGrid_FuncCallC
	cp xbc, 0x6
	jrl gt, AcVocalGrid_FuncCallC
	add xbc, xbc
	add xbc, MidiPart_PageStr_1of3_0x42
	ld bc, (xbc)
	lda_24 xix, (AcVocalGrid_DialSetup)
	jp_ind 8, 0x07, 0xf0, 0xe4

; AcVocalGridBoxProc dial setup handler
AcVocalGrid_DialSetup:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl AcVocalGrid_SetDialAndRet
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcVocalGrid_CheckEvent91
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, (MidiPart_PageStr_1of3_0x12)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Vocalist_ReturnZeroJmp

AcVocalGrid_CheckEvent91:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, Vocalist_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl AcVocalGrid_SetDialAndRet
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcVocalGrid_CheckEvent91B
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, (MidiPart_PageStr_1of3_0x2A)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Vocalist_ReturnZeroJmp

AcVocalGrid_CheckEvent91B:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, Vocalist_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

AcVocalGrid_SetDialAndRet:
	call SetDialEnable
	jr Vocalist_ReturnZeroJmp

; AcVocalGridBoxProc string copy handler
AcVocalGrid_StringCopy:
	ld xwa, xiz
	ld xiz, 0x3e
	jr AcVocalGrid_CopyViewString

; AcVocalGridBoxProc view access handler
AcVocalGrid_ViewAccess:
	ld xwa, xiz
	ld xiz, 0x42

AcVocalGrid_CopyViewString:
	.incbin "includes/generated/v7_transplant_AcVocalGrid_CopyViewString.bin"
AcVocalGrid_FuncCallA:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

; AcVocalGridBoxProc function callback B
AcVocalGrid_FuncCallB:
	call ApFuncCall

Vocalist_ReturnZeroJmp:
	lds32 xhl, 0
	jr AcVocalGrid_FuncCallD

; AcVocalGridBoxProc function callback C
AcVocalGrid_FuncCallC:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; AcVocalGridBoxProc function callback D
AcVocalGrid_FuncCallD:
	pop xiz
	lda xsp, (xsp + 16)
	ret

VocalistGridCheck:
	lda xsp, (xsp - 48)
	push xiz
	ld xhl, xbc
	ld xiy, MidiPart_OctaveStr_m2_0x64
	lda xix, (xsp + 20)
	ldw bc, 0x10
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 12)
	lds bc, 4
	ldirw
	ld xix, xhl
	lda xbc, (xsp + 12)
	lda_24 xwa, (MidiPart_OctaveStr_m2_0x4)
	ld (xsp + 8), xwa
	lda xiy, (xbc + 2)
	cp xhl, 0x1e0008d
	jrl z, VocalistGrid_CheckHandler
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, AcVocalist_ReturnZero
	cp xwa, 0x6
	jrl gt, AcVocalist_ReturnZero
	add xwa, xwa
	add xwa, MidiPart_ColWidthData_0x28
	ld wa, (xwa)
	lda_24 xix, (VocalistGrid_DispatchData)
	jp_ind 8, 0x07, 0xf0, 0xe0

VocalistGrid_DispatchData:
	.incbin "includes/generated/v7_transplant_VocalistGrid_DispatchData.bin"
VocalistGrid_CheckHandler:
	ld (xsp + 4), xbc
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	ld (xiy), de
	lda xwa, (xsp + 20)
	ld (xbc + 4), xwa
	ld wa, (xbc)
	sla wa, 2
	dec 4, wa
	ld bc, (xiy)
	sla bc, 3
	ld hl, bc
	add hl, wa
	ld xde, (xsp + 8)
	ld xwa, xde
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	sub xwa, 0x2d00
	cp xwa, 0x0
	jrl c, AcVocalist_ReturnZero
	cp xwa, 0x13
	jrl ugt, AcVocalist_ReturnZero
	add xwa, xwa
	add xwa, MidiPart_AfterStr_0x34
	ld wa, (xwa)
	lda_24 xix, (VocalistGrid_CheckDispData)
	jp_ind 8, 0x07, 0xf0, 0xe0

VocalistGrid_CheckDispData:
	.incbin "includes/generated/v7_transplant_VocalistGrid_CheckDispData.bin"
AcVocalist_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 48)
	ret

AcVocalistListBoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000e
	jr z, AcVocalist_ListSetup
	ld xwa, xiz
	call InheritedProc
	jr AcVocalist_ListCase2

; AcVocalist list setup
AcVocalist_ListSetup:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x5
	jr ugt, AcVocalist_ListCase1
	add xhl, xhl
	add xhl, MidiPart_ColWidthData_0x36
	ld hl, (xhl)
	lda_24 xix, (AcVocalist_ListDispatch)
	jp_ind 8, 0x07, 0xf0, 0xec
; AcVocalistListBoxProc dispatch
AcVocalist_ListDispatch:
	ld	xwa, 0xd7000c
	ld	xbc, 0x01c0000f
	lds32	xde, 0
	jr	12
	ld	xwa, 0xd7000c
	ld	xbc, 0x01c0000f
	lds32	xde, 1
	call	SendEvent

; AcVocalist list case 1
AcVocalist_ListCase1:
	lds32 xhl, 0

; AcVocalist list case 2
AcVocalist_ListCase2:
	pop xiz
	ret

PsHarmOnOffBoxProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xbc
	ld (xsp + 24), xwa
	ld xiy, MidiPart_HarmLocalStr_0x18
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, MidiPart_HarmLocalStr_0x1C
	lda xix, (xsp + 8)
	lds bc, 4
	ldirw
	cp xiz, 0x1c0000f
	jr z, PsHarm_DrawHandler
	cp xiz, 0x1c00007
	jr z, PsHarm_CheckMode
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	jrl PsHarm_CleanupAndRet

PsHarm_CheckMode:
	ld xwa, 0xd7000a
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x5
	jrl z, PsHarm_ReturnZero
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	jrl PsHarm_ReturnZero

PsHarm_DrawHandler:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 34)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp xbc, (xsp + 20)
	jr z, PsHarm_GetClientAndDraw
	ld xbc, (xwa)
	ld xwa, (xsp + 20)
	ld (xbc), wa

PsHarm_GetClientAndDraw:
	lda xbc, (xsp + 8)
	ld xwa, (xsp + 24)
	call GetClientBox
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 16)
	call GetBoxCenter
	ld xbc, (xsp + 4)
	ld xde, (xbc + 34)
	lda xwa, (xbc + 14)
	lda xbc, (xbc + 38)
	cpw (xde), 0x0
	jr z, PsHarm_InactiveCheck
	cpw (xbc), 0x7
	jr ugt, PsHarm_ActiveColorA
	ldw bc, 0xca
	ldw de, 0xa
	jr PsHarm_DrawActiveBox

PsHarm_ActiveColorA:
	ldw bc, 0xc3
	ldw de, 0xa

PsHarm_DrawActiveBox:
	call DrawDesignBox
	ld xwa, 0xd7000a
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	lda xbc, (xsp + 16)
	lda xwa, (xsp + 8)
	ld xde, (xsp + 4)
	lda xix, (xde + 22)
	cp xhl, 0x5
	jr nz, PsHarm_DrawActiveLabel
	ldl_da xde, (MidiPart_ColWidthData_0x42)
	ld xhl, (xix)
	push xhl
	pushw 0xff
	pushw 0xf7
	jr DrawCenterString_Exit

PsHarm_DrawActiveLabel:
	ld xde, (xix)
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, (xsp + 12)
	ld xde, (xde + 26)
	jr DrawCenterString_Exit

PsHarm_InactiveCheck:
	cpw (xbc), 0x7
	jr ugt, PsHarm_InactiveColorA
	ldw bc, 0xc9
	lds de, 7
	jr PsHarm_DrawInactiveBox

PsHarm_InactiveColorA:
	ldw bc, 0xc1
	lds de, 7

PsHarm_DrawInactiveBox:
	call DrawDesignBox
	ld xwa, 0xd7000a
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	lda xbc, (xsp + 16)
	lda xwa, (xsp + 8)
	ld xde, (xsp + 4)
	lda xix, (xde + 22)
	cp xhl, 0x5
	jr nz, PsHarm_DrawInactiveLabel
	ldl_da xde, (MidiPart_ColWidthData_0x42)
	ld xhl, (xix)
	push xhl
	pushw 0xff
	pushw 0xf7
	jr DrawCenterString_Exit

PsHarm_DrawInactiveLabel:
	ld xde, (xix)
	push xde
	pushw 0x0
	pushw 0xf7
	ld xde, (xsp + 12)
	ld xde, (xde + 30)

DrawCenterString_Exit:
	call DrawStringCentered

PsHarm_ReturnZero:
	lds32 xhl, 0

PsHarm_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 24)
	ret

HarmOnOffFunc:
	lds32 xhl, 0
	ret

VocalistPage1OKFunc:
	push xiz
	ld xhl, xde
	cp xbc, 0x1c00007
	jr nz, VocalistP1OK_Case0
	ld xwa, 0xd7000a
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	ld iz, hl
	extz xiz
	ld xwa, 0xd7000c
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	extz xhl
	sll xhl, 0
	add xhl, xiz
	ld xwa, 0x1430004
	ld xbc, 0x1e30007
	ld xde, xhl
	call MainFuncCall

; VocalistPage1OK case 0
VocalistP1OK_Case0:
	lds32 xhl, 0
	pop xiz
	ret

VocalistPage2OKFunc:
	cp xbc, 0x1c00007
	jr nz, VocalistP1OK_Case1
	ld xwa, 0x1430005
	ld xbc, 0x1e30008
	lds32 xde, 0
	call MainFuncCall

; VocalistPage1OK case 1
VocalistP1OK_Case1:
	lds32 xhl, 0
	ret

MainVocalistPage1OKFunc:
	dec 4, xsp
	ld (xsp), xde
	cp xbc, 0x1e30007
	jr nz, VocalistPage_Handler
	ld xwa, (xsp)
	ld de, wa
	extz wa
	ld bc, wa
	cps de, 5
	jr ugt, VocalistPage_Handler
	add de, de
	lda_24 xix, (MidiPart_HarmLocalStr_0x24)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, (VocalistPage1OK_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MainVocalistPage1OKFunc dispatch
VocalistPage1OK_Dispatch:
	.incbin "includes/generated/v7_transplant_VocalistPage1OK_Dispatch.bin"
VocalistPage_Handler:
	lds32 xhl, 0
	inc 4, xsp
	ret

VocalistPage1_DispatchData:
	.incbin "includes/generated/v7_transplant_VocalistPage1_DispatchData.bin"
MainVocalistPage2OKFunc:
	.incbin "includes/generated/v7_transplant_MainVocalistPage2OKFunc.bin"
VocalistPage2_ReturnZero:
	lds32 xhl, 0
	ret

AccPlay_GetCurrentPart:
	.incbin "includes/generated/v7_transplant_AccPlay_GetCurrentPart.bin"
RevSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c00029
	jr z, RevSel_HandleDial
	cp xbc, 0x1c0000d
	jr z, RevSel_HandleConfirm
	cp xbc, 0x1c00001
	jr z, RevSel_HandleInit
	cp xbc, 0x1e00085
	jr z, RevSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl RevSel_CleanupAndRet

RevSel_ReturnOne:
	lds32 xhl, 1
	jrl RevSel_CleanupAndRet

RevSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	lds wa, 0
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, RevSel_NoPresetMatch
	extz xhl
	add xhl, 0x10000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002a
	ld xde, xhl
	jr RevSel_SendAndRet

RevSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 1
	jr RevSel_SendAndRet

RevSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, MidiPart_HarmLocalStr_0x30

RevSel_SendAndRet:
	call SendEvent
	jr RevSel_ReturnZero

RevSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	cps wa, 1
	jr nz, RevSel_ReturnZero
	ld xwa, (xsp + 4)
	ld de, wa
	extz xde
	ld xwa, 0x1430006
	ld xbc, 0x1e30009
	call MainFuncCall

RevSel_ReturnZero:
	lds32 xhl, 0

RevSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

EqSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c0001c
	jrl z, EqSel_HandleParamChange
	cp xbc, 0x1c00029
	jrl z, EqSel_HandleDial
	cp xbc, 0x1c0000d
	jr z, EqSel_HandleConfirm
	cp xbc, 0x1c00001
	jr z, EqSel_HandleInit
	cp xbc, 0x1e00085
	jr z, EqSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl EqSel_CleanupAndRet

EqSel_ReturnOne:
	lds32 xhl, 1
	jrl EqSel_CleanupAndRet

EqSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	lds wa, 1
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, EqSel_NoPresetMatch
	extz xhl
	add xhl, 0x20000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002a
	ld xde, xhl
	jr EqSel_SendPresetEvent

EqSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 2

EqSel_SendPresetEvent:
	.incbin "includes/generated/v7_transplant_EqSel_SendPresetEvent.bin"
EqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, MidiPart_HarmLocalStr_0x36
	jr EqSel_SendEvent

EqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	cps wa, 2
	jr nz, RevEqFunc_ReturnZero
	ld xwa, 0x19000b
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	extz xhl
	sll xhl, 0
	ld xwa, (xsp + 4)
	extz xwa
	add xwa, xhl
	ld (xsp + 4), xwa
	ld xwa, 0x1430006
	ld xbc, 0x1e3000a
	ld xde, (xsp + 4)
	call MainFuncCall
	jr RevEqFunc_ReturnZero

EqSel_HandleParamChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	cp xwa, 0x4006
	jr nz, RevEqFunc_ReturnZero
	ld de, (xbc + 4)
	exts xde
	ld xwa, 0x19000b
	ld xbc, 0x1e0003b

EqSel_SendEvent:
	call SendEvent

RevEqFunc_ReturnZero:
	lds32 xhl, 0

EqSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

RevEqSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c0001c
	jrl z, RevEqSel_HandleParamChange
	cp xbc, 0x1c00029
	jrl z, RevEqSel_HandleDial
	cp xbc, 0x1c0000d
	jr z, RevEqSel_HandleConfirm
	cp xbc, 0x1c00001
	jr z, RevEqSel_HandleInit
	cp xbc, 0x1e00085
	jr z, RevEqSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl RevEqSel_CleanupAndRet

RevEqSel_ReturnOne:
	lds32 xhl, 1
	jrl RevEqSel_CleanupAndRet

RevEqSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	lds wa, 2
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, RevEqSel_NoPresetMatch
	extz xhl
	add xhl, 0x30000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002a
	ld xde, xhl
	jr RevEqSel_SendPresetEvent

RevEqSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 3

RevEqSel_SendPresetEvent:
	.incbin "includes/generated/v7_transplant_RevEqSel_SendPresetEvent.bin"
RevEqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, MidiPart_HarmLocalStr_0x3C
	jr RevEqSel_SendEvent

RevEqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	cps wa, 3
	jr nz, EqFunc_ReturnZero
	ld xwa, 0x1a000a
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	extz xhl
	sll xhl, 0
	ld xwa, (xsp + 4)
	extz xwa
	add xwa, xhl
	ld (xsp + 4), xwa
	ld xwa, 0x1430006
	ld xbc, 0x1e3000b
	ld xde, (xsp + 4)
	call MainFuncCall
	jr EqFunc_ReturnZero

RevEqSel_HandleParamChange:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	cp xwa, 0x4006
	jr nz, EqFunc_ReturnZero
	ld de, (xbc + 4)
	exts xde
	ld xwa, 0x1a000a
	ld xbc, 0x1e0003b

RevEqSel_SendEvent:
	call SendEvent

EqFunc_ReturnZero:
	lds32 xhl, 0

RevEqSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

EqOnOffFunc:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	ld xwa, 0x4006
	ld bc, hl
	lds de, 1
	call MainLswPut
	lds32 xhl, 0
	ret

RevEqOnOffFunc:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	ld xwa, 0x4006
	ld bc, hl
	lds de, 1
	call MainLswPut
	lds32 xhl, 0
	ret

MainRevEqPresetLoad:
	ld xhl, xbc
	extz de
	cp xhl, 0x1e3000b
	jr z, RevEqPreset_TypeRevEq
	cp xhl, 0x1e3000a
	jr z, RevEqPreset_TypeEq
	cp xhl, 0x1e30009
	jr nz, RevEqPreset_ReturnZero
	lds wa, 0
	ld bc, de
	jr MainRevEqPresetLoad_DoLoad

RevEqPreset_TypeEq:
	lds wa, 1
	ld bc, de
	jr MainRevEqPresetLoad_DoLoad

RevEqPreset_TypeRevEq:
	lds wa, 2
	ld bc, de

MainRevEqPresetLoad_DoLoad:
	call SoundPreset_Dispatch

RevEqPreset_ReturnZero:
	lds32 xhl, 0
	ret

AcGMOnOffBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00001
	jr z, AcGMOnOff_InitHandler
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr AcGMOnOff_CleanupAndRet

AcGMOnOff_InitHandler:
	.incbin "includes/generated/v7_transplant_AcGMOnOff_InitHandler.bin"
AcGMOnOff_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret

StsAttentionCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAttention_ReturnZero
	lda_24 xhl, (GMMode_AttentionTable)
	ret

StsAttention_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOnCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOn_ReturnZero
	lda_24 xhl, (GMMode_Attention_English2_0x204)
	ret

StsGMOn_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOffCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOff_ReturnZero
	lda_24 xhl, (GMMode_Attention_English2_0x47C)
	ret

StsGMOff_ReturnZero:
	lds32 xhl, 0
	ret

StsAreYouSureCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAreYouSure_ReturnZero
	lda_24 xhl, (GMMode_Attention_English2_0x494)
	ret

StsAreYouSure_ReturnZero:
	lds32 xhl, 0
	ret

GMOKFunc:
	ldb_da l, (0x0340ea)
	cps l, 2
	jr z, GMOK_ConfirmDialog
	cps l, 1
	jr z, GMOK_ConfirmDialog
	cps l, 0
	jr nz, GMOK_ReturnZero
	calr GMYesFunc
	jr GMOK_ReturnZero

GMOK_ConfirmDialog:
	ld xwa, 0x580001
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, GMOK_PostNoDialog
	ld xwa, 0x580005
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr GMOK_PostEvent

GMOK_PostNoDialog:
	ld xwa, 0x58000d
	ld xbc, 0x1c00001
	lds32 xde, 0

GMOK_PostEvent:
	call PostEvent

GMOK_ReturnZero:
	lds32 xhl, 0
	ret

GMNoFunc:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	lds32 xhl, 0
	ret

GMYesFunc:
	.incbin "includes/generated/v7_transplant_GMYesFunc.bin"
TtMdGm:
	cp xbc, 0x1c00001
	jr nz, TtMdGm_ReturnZero
	call GetTitleOld
	cp xhl, 0x1a000ee
	jr nz, TtMdGm_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent

TtMdGm_ReturnZero:
	lds32 xhl, 0
	ret

StsSplitCheck:
	cp xbc, 0x1e0009f
	jr nz, StsSplit_ReturnZero
	lda_24 xhl, (GMMode_Attention_English2_0x514)
	ret

StsSplit_ReturnZero:
	lds32 xhl, 0
	ret

SplitPointFunc:
	.incbin "includes/generated/v7_transplant_SplitPointFunc.bin"
SplitPoint_ClampToMiddle:
	ldi_erpb 0xfb, 0x3c

SplitPoint_StartDraw:
	lds iz, 0
	jr Draw_keybed_maybe_for_indicating_split_point

SplitPoint_DrawOctaveLoop:
	pushw 0x34
	ld xbc, Bitmap_SplitPoint_B
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
	inc 1, iz

Draw_keybed_maybe_for_indicating_split_point:
	stb_erp A, 0xfb
	extz wa
	div a, 0xc
	dec 3, a
	ld c, a
	extz bc
	lda xwa, (xsp + 4)
	cp iz, bc
	jr c, SplitPoint_DrawOctaveLoop
	cp_erpb 0xfb, 0x60
	jr nc, SplitPoint_UpdateScreen
	stb_erp C, 0xfb
	extz bc
	div c, 0xc
	ld c, b
	extz bc
	sla bc, 2
	lda_24 xde, (SplitPoint_NoteEntry_C_Code_0x4)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	pushw 0x34
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
	inc 1, iz
	cps iz, 5
	jr nc, SplitPoint_UpdateScreen

SplitPoint_FillRemainingLoop:
	lda xwa, (xsp + 4)
	pushw 0x34
	ld xbc, Bitmap_SplitPoint_no_split
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
	inc 1, iz
	cps iz, 5
	jr c, SplitPoint_FillRemainingLoop

SplitPoint_UpdateScreen:
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	call SetNeedUpdate
	ld xwa, 0xffffffff
	ld xbc, 0x1e00078
	lds32 xde, 0
	call SendEvent

SplitPoint_ReturnZero:
	lds32 xhl, 0
	jr ParamFunc_CommonExit

SplitPoint_HandleNoteEvt:
	.incbin "includes/generated/v7_transplant_SplitPoint_HandleNoteEvt.bin"
SplitPoint_ReturnParamId:
	ld xhl, 0x4181
	jr ParamFunc_CommonExit

ParamFunc_ReturnOne:
	lds32 xhl, 1

ParamFunc_CommonExit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AccWrap_SetMinVelocity:
	.incbin "includes/generated/v7_transplant_AccWrap_SetMinVelocity.bin"
R12OctaveFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003f
	jrl z, R12Octave_ReturnStepSize
	cp xbc, 0x1e0003e
	jrl z, R12Octave_ReturnStepSize
	cp xbc, 0x1e00041
	jrl z, R12Octave_ReturnOne
	cp xbc, 0x1e00040
	jr z, R12Octave_ReturnParamId
	cp xbc, 0x1e00042
	jr z, R12Octave_HandleNoteEvt
	lds32 xhl, 0
	jr R12Octave_PopIzRet

R12Octave_HandleNoteEvt:
	ld wa, (xde + 4)
	ld xbc, (xde + 8)
	cp wa, 0x58
	jr z, R12Octave_Octave5
	cp wa, 0x4c
	jr z, R12Octave_Octave4
	cp wa, 0x40
	jr z, R12Octave_Octave3
	cp wa, 0x34
	jr z, R12Octave_Octave2
	cp wa, 0x28
	jr nz, R12Octave_OctaveDefault
	ld xwa, SplitPoint_NoteEntry_C_Code_0x42
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave2:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x48
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave3:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x4E
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave4:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x54
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave5:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x5A
	jr R12Octave_StringCopyAndSendEvent

R12Octave_OctaveDefault:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x60

R12Octave_StringCopyAndSendEvent:
	.incbin "includes/generated/v7_transplant_R12Octave_StringCopyAndSendEvent.bin"
R12Octave_ReturnParamId:
	ld xhl, 0x40e0
	jr R12Octave_PopIzRet

R12Octave_ReturnOne:
	lds32 xhl, 1
	jr R12Octave_PopIzRet

R12Octave_ReturnStepSize:
	ld xhl, 0xc

R12Octave_PopIzRet:
	pop xiz
	ret


; Computer Interface routines (Connection config and PCG Output)

; --- Computer Interface & SysEx ---
