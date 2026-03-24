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
	stdi8 0x7dfd, 95
	stdi16 0x7e02, 9
	stdi16 0x7e04, 72
	stdi8 0x7e06, 16
	stdi8 0x7e07, 1
	ldda8 a, 0x7e08
	stda8 0x7e0a, a
	ld xhl, 0x7aec
	ld xbc, 0x7d6c
	calr SeqEvt_ProcessReadLoop
	ldda8 a, 0x7e0a
	stda8 0x7e08, a
	stdi8 0x7e07, 2
	ldda8 a, 0x7e09
	stda8 0x7e0a, a
	ld xhl, 0x7bec
	ld xbc, 0x7db4
	calr SeqEvt_ProcessReadLoop
	ldda8 a, 0x7e0a
	stda8 0x7e09, a
	ldda8 a, 0x7dfd
	stda8 0x7dfc, a
	ret

SeqEvt_ProcessReadLoop:
	ld ix, (xhl + 6)
	stda16 0x7e0f, xix

SeqEvt_ProcessLoop_Check:
	cp (xhl + 4), ix
	jr nz, SeqEvt_ClassifyEventType
	jp SeqEvt_ProcessLoopRet

SeqEvt_ClassifyEventType:
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ld w, a
	cp a, 0x90
	jr nz, SeqEvt_CheckType91
	stdi8 0x7e0e, 5
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckType91:
	cp a, 0x91
	jr nz, SeqEvt_CheckTypeC0
	stdi8 0x7e0e, 7
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckTypeC0:
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqEvt_CheckTypeD0
	stdi8 0x7e0e, 4
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckTypeD0:
	cp a, 0xd0
	jr z, SeqEvt_TypeD0_SetCount
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	stda16 0x7e0f, xix
	jr SeqEvt_ProcessLoop_Check

SeqEvt_TypeD0_SetCount:
	stdi8 0x7e0e, 2

SeqEvt_ReadAndDispatchEntry:
	ld_srib3 A, 0x07, 0xec, 0xf0
	stda16 0x7e11, xix
	calr SeqEvtBuf_AdvanceReadPos
	stda16 0x7e0f, xix
	cpda8 a, 1132
	jr ule, SeqEvt_DispatchByChannel
	jp SeqEvt_ProcessTempoEvent

SeqEvt_DispatchByChannel:
	ld a, w
	and a, 0xf0
	cp a, 0x90
	jr z, SeqEvt_ProcessNoteOn
	jr SeqEvt_ProcessNonNoteEvent

SeqEvt_ProcessNoteOn:
	pushw wa
	ld_srib3 W, 0x07, 0xec, 0xf0
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	xor ix, ix

SeqEvt_SlotScanLoop:
	cpda16 xix, 0x7e04
	jr c, SeqEvt_CheckSlotActive
	jr SeqEvt_AfterSlotScan

SeqEvt_CheckSlotActive:
	bit_dri 7, 0x07, 0xec, 0xf0
	jr z, SeqEvt_AdvanceSlotIndex
	ld xiy, xhl
	and xix, 0xffff
	add xiy, xix
	cp (xiy + 2), w
	jr z, SeqEvt_SlotMatchFound

SeqEvt_AdvanceSlotIndex:
	addda16 xix, 0x7e02
	jr SeqEvt_SlotScanLoop

SeqEvt_SlotMatchFound:
	calr SeqEvt_WriteNoteOff

SeqEvt_AfterSlotScan:
	popw wa
	xor ix, ix

SeqEvt_FindFreeSlotLoop:
	cpda16 xix, 0x7e04
	jr nc, SeqEvt_AllocateNewSlot
	bit_dri 7, 0x07, 0xec, 0xf0
	jr nz, SeqEvt_AdvanceFreeSlotIdx
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	jr SeqEvt_WriteEventAndContinue

SeqEvt_AdvanceFreeSlotIdx:
	addda16 xix, 0x7e02
	jr SeqEvt_FindFreeSlotLoop

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
	ld_srib3 A, 0x07, 0xec, 0xf0
	and_srib_im 0x07, 0xec, 0xf0, 0x7f
	and a, 0xf0
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	ld a, w
	calr SeqEvtBuf_WriteBytePreserve
	ldb a, 0x0
	calr SeqEvtBuf_WriteBytePreserve
	ret

SeqEvt_WriteNoteOnRotating:
	push xwa
	xor xwa, xwa
	ldda8 a, 0x7e0a
	ld xix, SeqEvt_RotationOffsetTable
	add xix, xwa
	ld ix, (xix)
	ld_srib3 A, 0x07, 0xec, 0xf0
	and_srib_im 0x07, 0xec, 0xf0, 0x7f
	ld iz, ix
	inc 2, ix
	ld_srib3 W, 0x07, 0xec, 0xf0
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	and a, 0xf0
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	ld a, w
	calr SeqEvtBuf_WriteBytePreserve
	ldb a, 0x0
	calr SeqEvtBuf_WriteBytePreserve
	ld ix, iz
	pop xwa
	adddi8 0x7e0a, 2
	ldda8 a, 0x7e0a
	cpda8 a, 0x7e06
	jr c, SeqEvt_RotateIndexDone
	stdi8 0x7e0a, 0

SeqEvt_RotateIndexDone:
	ld a, w
	and a, 0xf0
	ret

SeqEvt_WriteVoiceParams:
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	ld a, w
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	ldb a, 0x0
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	ex16 iz, ix
	ldda16 xix, 0x7e0f
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	calr SeqEvtBuf_WriteBytePreserve
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	ex16 iz, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	calr SeqEvtBuf_WriteBytePreserve
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	push xwa
	ex16 iz, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ld_srib3 W, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	addda16 xwa, 1134
	cp a, 0x60
	jr c, SeqEvt_AdjustNoteOctave
	inc 1, w
	sub a, 0x60

SeqEvt_AdjustNoteOctave:
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	st_dri3w WA, 0x07, 0xec, 0xf0
	inc 2, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	cpda16 xwa, 0x7dfe
	jr nc, SeqEvt_WriteRemainingParams
	stda16 0x7dfe, xwa

SeqEvt_WriteRemainingParams:
	pop xwa
	ex16 iz, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	stda16 0x7e0f, xix
	ex16 iz, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	cp w, 0x90
	jr z, SeqEvt_UpdateReadPosition
	ex16 iz, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	stda16 0x7e0f, xix
	ex16 iz, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	ex16 iz, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	stda16 0x7e0f, xix
	ex16 iz, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	stda32 0x7e13, xhl
	ld xhl, xbc
	ldda32 xbc, 0x7e13

SeqEvt_UpdateReadPosition:
	ldda16 xix, 0x7e0f
	ld (xhl + 6), ix
	ret

SeqEvt_HandleControlEvent:
	ld w, a
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	ldda16 xix, 0x7e0f
	cp w, 0xd0
	jr nz, SeqEvt_HandleExtendedCtrl
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	jr SeqEvt_SaveReadPosAndRet

SeqEvt_HandleExtendedCtrl:
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	pushw bc
	ld_srib3 C, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ld_srib3 A, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	and a, 0xf
	bit 0, c
	jr z, SeqEvt_SetExtendedFlag
	or a, 0x10

SeqEvt_SetExtendedFlag:
	popw bc
	calr SeqEvtBuf_WriteBytePreserve
	ldb a, 0xd0
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	ldb a, 0x7
	calr SeqEvtBuf_WriteBytePreserve
	ld_srib3 W, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	ldb a, 0x0
	bit 0, w
	jr z, SeqEvt_WriteSustainValue
	ldb a, 0x7f

SeqEvt_WriteSustainValue:
	calr SeqEvtBuf_WriteBytePreserve

SeqEvt_SaveReadPosAndRet:
	stda16 0x7e0f, xix
	ld (xhl + 6), ix
	ret

SeqEvt_CalcTempoOffset:
	subda8 a, 1132
	cpda8 a, 0x7dfd
	jr nc, SeqEvt_UpdateMinTempo
	stda8 0x7dfd, a

SeqEvt_UpdateMinTempo:
	ldda16 xiy, 0x7e11
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	xor wa, wa
	ldda8 a, 0x7e0e
	addda16 xwa, 0x7e0f
	stda16 0x7e0f, xwa
	ld ix, wa
	cp ix, (xhl + 2)
	jr ugt, SeqEvt_HandleBufferWrap
	jr SeqEvt_CalcTempoRet

SeqEvt_HandleBufferWrap:
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 256)
	stda16 0x7e0f, xix

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
	stdi16 0x7e00, 0xff5f
	stdi16 0x7e02, 9
	stdi16 0x7e04, 72
	stdi8 0x7e07, 1
	ld xhl, 0x7d6c
	calr Voice_ScanSlotMetric
	stdi8 0x7e07, 2
	ld xhl, 0x7db4
	calr Voice_ScanSlotMetric
	ldda16 xwa, 0x7e00
	stda16 0x7dfe, xwa
	jr SeqEvt_VoiceScanDone

SeqEvt_VoiceScanDone:
	ret

Voice_ScanSlotMetric:
	xor iy, iy

Voice_ScanLoop:
	cpda16 xiy, 0x7e04
	jr c, Voice_CheckSlotBit
	jp Voice_ScanLoopDone

Voice_CheckSlotBit:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, Voice_ReadSlotParams
	jr Voice_ParamComplete

Voice_ReadSlotParams:
	ld ix, iy
	ld_srib3 A, 0x07, 0xec, 0xf0
	stda8 0x7e0b, a
	inc 2, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	stda8 0x7e0c, a
	inc 1, ix
	ld_srib3 A, 0x07, 0xec, 0xf0
	stda8 0x7e0d, a
	inc 1, ix
	ld_sriw3 WA, 0x07, 0xec, 0xf0
	cpda16 xwa, 1134
	jr gt, Voice_SubtractBaseFreq
	ex16 iy, iz
	ld iy, (xhl + 4)
	ldb a, 0xf0
	andda8 a, 0x7e0b
	orda8 a, 0x7e07
	calr SeqEvtBuf_WriteBytePreserve
	ldda8 a, 0x7e0c
	calr SeqEvtBuf_WriteBytePreserve
	ldb a, 0x0
	calr SeqEvtBuf_WriteBytePreserve
	ex16 iy, iz
	and_srib_im 0x07, 0xec, 0xf4, 0x7f
	jr Voice_ParamComplete

Voice_SubtractBaseFreq:
	subda16 xwa, 1134
	bit 7, a
	jr z, Voice_StoreMetricValue
	add a, 0x60

Voice_StoreMetricValue:
	st_dri3w WA, 0x07, 0xec, 0xf0
	cpda16 xwa, 0x7e00
	jr nc, Voice_ParamComplete
	stda16 0x7e00, xwa

Voice_ParamComplete:
	addda16 xiy, 0x7e02
	jp Voice_ScanLoop

Voice_ScanLoopDone:
	ret

Voice_DecodeNoteChannel:
	cp l, 0x80
	jr c, Voice_DecodeNonPercussion
	xor h, h
	and l, 0xf
	sla hl, 1
	push xix
	ld xix, Voice_NoteChannelTable1_0x402_
	ld_sriw3 HL, 0x07, 0xf0, 0xec
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
	ld xix, Voice_NoteChannelTable1_0x02_
	ld_sriw3 HL, 0x07, 0xf0, 0xec
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
	push_sr
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
	pop_sr
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
	push_sr
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	pop_sr
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
	pop_sr
	nop
	nop
	nop
	nop
	.byte 0x04
	halt
	incf
	push_sr
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
	pop_sr
	.byte 0x04, 0x04
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	push_sr
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	push_sr
	halt
	.zero 32
	nop
	nop
	nop
	nop
	nop
	nop
	push_sr
	.byte 0x04
	nop
	nop
	nop
	nop
	push_sr
	.byte 0x01
	nop
	nop
	pop_sr
	nop
	nop
	nop
	push_sr
	push_sr
	nop
	nop
	pop_sr
	.byte 0x01
	nop
	nop
	push_sr
	pop_sr
	nop
	nop
	pop_sr
	push_sr
	nop
	nop
	nop
	nop
	nop
	nop
	pop_sr
	pop_sr
	nop
	nop
	nop
	nop
	nop
	nop
	pop_sr
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	pop_sr
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	.byte 0x04
	push_sr
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
	push_sr
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
	pop_sr
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
	pop_sr
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
	push_sr
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
	push_sr
	decf
	pop_sr
	decf
	.byte 0x04
	decf
	halt
	ret
	nop
	ret
	.byte 0x01
	ret
	push_sr
	ret
	pop_sr
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
	ld	xix, Voice_NoteChannelTable1_0x43F_
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
	push_sr
	pop	xbc
	.byte 0x01
	pop	xde
	.byte 0x01
	pop	xhl
	.byte 0x01
	pop	xwa
	push_sr
	.byte 0x53
	push_sr
	nop
	nop
	nop
	nop
	pop	xbc
	pop_sr
	pop	xde
	pop_sr
	pop	xhl
	pop_sr
	pop	xix
	pop_sr
	pop	xiy
	pop_sr
	pop	xiz
	pop_sr
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
	push_sr
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
	pop_sr
	.byte 0x01
	pop_sr
	push_sr
	.byte 0x04
	push_sr
	ldwio	1, 260
	incf
	push_sr
	nop
	nop
	nop
	nop
	ldio	1, 3
	pop_sr
	ldio	2, 13
	push_sr
	reti
	.byte 0x01
	pushw	2
	nop
	nop
	nop
	.byte 0x1a, 0x01, 0x1a
	push_sr
	pop_f
	push_sr
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
	push_sr
	pop_a
	push_sr
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
	push_sr
	nop
	nop
	nop
	nop
	ld	xiy, 0x46016301
	push_sr
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
	ld xix, Voice_NoteChannelTable2_0x02_
	ld_sriw3 HL, 0x07, 0xf0, 0xec
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
	push_sr
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
	pop_sr
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
	ld xix, Voice_BankIndexTable_0x02_
	ld_sriw3 HL, 0x07, 0xf0, 0xec
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
	ld xix, Voice_NoteParamTable_0x02_
	ld_sriw3 HL, 0x07, 0xf0, 0xec
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
	cpdi8 0x7f0b, 0
	jr z, AccPlay_CheckPrevRunning
	cpdi8 0x7f0c, 0
	jr z, AccPlay_StartNewAccomp
	bitda 0, 0x7f0b
	jr z, AccPlay_RunningWithBit0
	calr AccPlay_DispatchSeqStart
	jr AccPlay_ContinueMainLoop

AccPlay_RunningWithBit0:
	calr AccPlay_HandleStopState
	jr AccPlay_ContinueMainLoop

AccPlay_StartNewAccomp:
	calr AccPlay_InitializeStart
	jr AccPlay_ContinueMainLoop

AccPlay_CheckPrevRunning:
	cpdi8 0x7f0c, 0
	jr z, AccPlay_StopSequencer
	calr AccPlay_MainUpdateLoop
	jr AccPlay_ContinueMainLoop

AccPlay_StopSequencer:
	calr AccPlay_StopIfRunning

AccPlay_ContinueMainLoop:
	calr AccPlay_MonitorParamState
	bitda 0, 0x7f35
	jr z, AccPlay_UpdateStateFlags
	anddi8 0x7f35, 254
	calr AccPlay_CheckAndToggle

AccPlay_UpdateStateFlags:
	ldda8 a, 0x7f0b
	stda8 0x7f0c, a
	bitda 2, 0x7f15
	jr z, AccPlay_DispatchRet
	cpdi8 0x8d36, 1
	jr nz, AccPlay_DispatchRet
	anddi8 0x7f15, 251
	stdi8 0x7f42, 15
	call DrumVoice_NotifyEE

AccPlay_DispatchRet:
	ret

AccPlay_InitializeStart:
	call AccWrap_PlayModeDispatch
	call CountAvailableVoiceSlots
	calr AccPlay_SetupSoundParams
	call AudioInit_CheckMIDIAndDispatch
	calr AccPlay_SaveMuteStates
	stdi16 0x7f0e, 0xfffe
	stdi8 0x7f34, 0
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ldb a, 0x10
	call UI_PostPartChangeEvent
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ldda8 a, 1075
	sla a, 1
	and a, 0x1f
	or a, 0x80
	stda8 0x7f16, a
	ld xhl, 0x1e880a
	ormi8 (xhl), 0x1
	ld xwa, 0x22
	lds32 xbc, 0
	lds32 xde, 0
	call CtrlPanel_IndicatorDispatch
	stdi8 0x8f4e, 4
	ret

AccPlay_MainUpdateLoop:
	call AccWrap_PlayModeDispatch
	stdi8 1055, 12
	calr AccPlay_ExtractVoiceSlot
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call PartSelect_UpdateDisplayState
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	call AudioInit_CheckMIDIAndDispatch
	calr AccPlay_RestoreMuteStates
	calr AccPlay_ClearSlotTable
	cpdi8 0x8d34, 16
	jr nz, AccPlay_SetIndicatorAndRet
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	bitda 2, 0x7f15
	jr z, AccPlay_PostEvent9E_Enable
	call AccSeq_PostEvent9E_Enable

AccPlay_PostEvent9E_Enable:
	xor wa, wa
	ldb a, 0x1
	call UI_PostPartChangeEvent
	bitda 2, 0x7f15
	jr z, AccPlay_PostEvent9E_Disable
	call AccSeq_PostEvent9E_Disable

AccPlay_PostEvent9E_Disable:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPlay_SetIndicatorAndRet:
	ordi8 0x7f15, 1
	ld xhl, 0x1e880a
	andmi8 (xhl), 0xfe
	ld xwa, 0x22
	call CtrlPanel_SetIndicatorLED
	ret

AccPlay_DispatchSeqStart:
	bitda 2, 1056
	jr nz, AccPlay_DispatchSeqRet
	call Seq_DispatcherEntry
	ordi8 0x33e8, 1
	ordi8 0x34cd, 128
	call Seq_DispatcherEntry
	stdi8 0x7f0b, 2

AccPlay_DispatchSeqRet:
	ret

AccPlay_HandleStopState:
	bitda 2, 0x7e1f
	jr nz, AccPlay_CheckResumeState
	jp AccPlay_PostLoopCleanup

AccPlay_CheckResumeState:
	bitda 2, 0x7e23
	jr nz, TempoEvt_ProcessLoop
	calr AccPlay_ProcessVoiceBank
	call CountAvailableVoiceSlots
	calr AccPlay_AllocateVoiceSlot
	ld xwa, 0x22
	call CtrlPanel_SetIndicatorLED

TempoEvt_ProcessLoop:
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	jr nz, TempoEvt_ReadAndClassify
	jp AccPlay_PostLoopCleanup

TempoEvt_ReadAndClassify:
	call TempoRingBuf_SaveReadPos
	call TempoRingBuf_ReadAlternate
	ld a, l
	ld w, a
	and w, 0xf0
	stda8 0x7e54, a
	stda8 0x7e55, w
	bitda 7, 0x7f16
	jr z, TempoEvt_DispatchEvent
	cp a, 0x81
	jr nz, TempoEvt_CheckHighBit
	ldda8 a, 0x7f16
	ld w, a
	and a, 0x1f
	and w, 0xe0
	dec 1, a
	or w, a
	cps a, 0
	jr nz, TempoEvt_StoreBankParam
	and w, 0x7f
	calr AccPlay_UpdateBankParams

TempoEvt_StoreBankParam:
	stda8 0x7f16, w
	jr TempoEvt_ContinueProcessing

TempoEvt_CheckHighBit:
	bit 7, a
	jr z, TempoEvt_ContinueProcessing
	ldda8 a, 0x7f16
	and a, 0x1f
	cps a, 1
	jr nz, TempoEvt_ContinueProcessing
	call TempoRingBuf_ReadAlternate
	ld a, l
	cp a, 0x48
	jr c, TempoEvt_ContinueProcessing
	ordi8 0x7f15, 16
	ldda8 a, 0x7e54
	ldda8 w, 0x7e55
	jr TempoEvt_DispatchEvent

TempoEvt_ContinueProcessing:
	calr TempoRingBuf_ReadLoop
	jp TempoEvt_ProcessLoop

TempoEvt_DispatchEvent:
	cpdi16 0x7e18, 0
	jr nz, TempoEvt_HandleEndMarker
	calr AccPlay_InitAndStartLoop
	jr TempoEvent_ContinueLoop

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
	bitda 0, 0x7f15
	jr z, AccPlay_StopRet
	bitda 2, 1056
	jr nz, AccPlay_StopRet
	call Seq_DispatcherEntry
	anddi8 0x33e8, 254
	ordi8 0x34cd, 128
	call Seq_DispatcherEntry
	anddi8 0x7f15, 254

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
	ldda8 a, 0x7f14
	cp a, 0xc
	jr c, Voice_CalcBankOffset
	ldb a, 0x0

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
	calr Util_ExtractAndShiftBits
	ld hl, (xix + 3)
	ldw (xix + 1), 0xffff
	ldw (xix + 3), 0xffff
	andmi8 (xix), 0x7f
	incdi16 1, 0x7e18
	cp hl, 0xffff
	jr z, Voice_ReleaseChainDone
	jr Voice_ReleaseChainLoop

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
	ldb a, 0x17
	stda8 0x8d3a, a
	ldb e, 0x90
	ldb d, 0x10
	ldb a, 0x17
	ldb w, 0xff
	call SwbtWr_QueuePostEvent
	ldda8 a, 0xfd62
	ldda8 w, 0xfd63
	cp wa, 0x1ff
	jr nz, AccPlay_SetupJumpTarget
	lds wa, 0
	stda8 0xfd62, a
	stda8 0xfd63, w
	ldb e, 0x17
	ldb d, 0x1
	ldb a, 0x0
	ldb w, 0x7f
	call SwbtWr_QueuePostEvent
	ldb e, 0x17
	ldb d, 0x0
	ldb a, 0x0
	ldb w, 0xff
	call SwbtWr_QueuePostEvent
	ldb h, 0x0
	ldb l, 0x0
	stdi8 0x90f7, 23
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff7e
	lda_dri3 XIZ, 0x03, 0xe4, 0xec

AccPlay_SetupJumpTarget:
	jp AccPlay_SyncParamsRet
AccPlay_SyncVoiceParams:
	ld	xiy, 0xf9b6
	ld	xix, 0xfd62
	ldb	c, 30
	ld	a, (xiy)
	ld	w, (xix)
	ld	(xix), a
	cp	a, w
	jr	z, 18
	push	xiy
	push	xix
	push	xbc
	ldb	e, 23
	ldb	d, 30
	sub	d, c
	ldb	w, 255
	call	SwbtWr_QueuePostEvent
	pop	xbc
	pop	xix
	pop	xiy
	inc	1, iy
	inc	1, ix
	dec	1, c
	cps	c, 0
	jr	nz, 0xda

AccPlay_SyncParamsRet:
	ret

AccPlay_AllocateVoiceSlot:
	calr Voice_GetBankEntryPointer
	push xiy
	calr Voice_FindFreeSlot
	ld hl, wa
	calr Util_ExtractAndShiftBits
	ormi8 (xix), 0x80
	decdi16 1, 0x7e18
	pop xiy
	ld (xiy + 3), wa
	ldb l, 0x1
	or (xiy + 256), l
	stda16 0x7f10, xwa
	lds wa, 6
	stda16 0x7f12, xwa
	ldda8 a, 0xfd62
	ldda8 w, 0xfd63
	ld (xiy + 9), wa
	xor a, a
	ldda8 w, 0xfd66
	bit 6, w
	jr z, AccPlay_CheckReverbFlag
	or a, 0x1

AccPlay_CheckReverbFlag:
	ld (xiy + 13), a
	xor a, a
	ldda8 w, 0xfd66
	bit 3, w
	jr z, AccPlay_CheckChorusFlag
	or a, 0x1

AccPlay_CheckChorusFlag:
	ld (xiy + 14), a
	ldda8 a, 0xfd6a
	and a, 0x7f
	ld (xiy + 12), a
	ret

AccPlay_UpdateBankParams:
	push xiy
	push xhl
	push xwa
	calr Voice_GetBankEntryPointer
	ldda8 a, 0xfd62
	ldda8 w, 0xfd63
	ld (xiy + 9), wa
	xor a, a
	ldda8 w, 0xfd66
	bit 6, w
	jr z, AccPlay_UpdateReverbParam
	or a, 0x1

AccPlay_UpdateReverbParam:
	ld (xiy + 13), a
	xor a, a
	ldda8 w, 0xfd66
	bit 3, w
	jr z, AccPlay_UpdateChorusParam
	or a, 0x1

AccPlay_UpdateChorusParam:
	ld (xiy + 14), a
	ldda8 a, 0xfd6a
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
	ldda16 xhl, 0x7f10
	calr Util_ExtractAndShiftBits
	ldb a, 0x83
	ldda16 xhl, 0x7f12
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	ret

AccPlay_ProcessNoteEvent:
	lds bc, 5
	calr MidiSeqBuf_ScanAllEntries
	ldda8 a, 0x7f39
	cps a, 0
	jr z, AccPlay_NoteNoSlotMatch
	calr AccPlay_NoteWithSlot
	jr AccPlay_NoteEventRet

AccPlay_NoteNoSlotMatch:
	calr AccPlay_FindSlotByChannel

AccPlay_NoteEventRet:
	ret

AccPlay_NoteWithSlot:
	cpdi16 0x7e18, 0
	jr z, AccPlay_NoteNoSlotAvail
	calr AccPlay_FindActiveSlot
	cp xhl, 0xffff
	jr nz, AccPlay_NoteAllocAndWrite

AccPlay_NoteNoSlotAvail:
	jp AccPlay_NoteAllocRet

AccPlay_NoteAllocAndWrite:
	push xhl
	push xix
	ldda8 l, 0x7f38
	xor h, h
	ld xix, Display_FontPalette_Table_0x12EA_
	ld_srib3 A, 0x07, 0xf0, 0xec
	xor w, w
	sla wa, 2
	ld hl, wa
	ld xix, AccPlay_NoteParamTable
	ld_srib3 A, 0x07, 0xf0, 0xec
	stda8 0x7e54, a
	inc 1, hl
	ld_srib3 A, 0x07, 0xf0, 0xec
	stda8 0x7e55, a
	inc 1, hl
	ld_srib3 A, 0x07, 0xf0, 0xec
	stda8 0x7e56, a
	ldb a, 0x90
	cpdi8 0x7e54, 0
	jr z, AccPlay_NoteSetType91
	ldb a, 0x91

AccPlay_NoteSetType91:
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ldda8 a, 0x7f37
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ldda8 a, 0x7f38
	calr MidiSeqBuf_WriteByte
	pop xix
	pop xhl
	ldda8 a, 0x7f38
	or a, 0x80
	ld (xhl), a
	ldb a, 0x0
	ld (xhl + 1), a
	ldda8 a, 0x7f37
	ld (xhl + 2), a
	ldda16 xwa, 0x7f10
	ld (xhl + 3), wa
	ldda16 xwa, 0x7f12
	ld (xhl + 5), a
	calr MidiSeqBuf_AdvancePosition
	ldda8 a, 0x7f39
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ldb a, 0x10
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ldb a, 0x0
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	cpdi8 0x7e54, 0
	jr z, AccPlay_NoteAllocRet
	ldda8 a, 0x7e55
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ldda8 a, 0x7e56
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition

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
	ld xhl, 0x7e7b

AccPlay_ScanActiveLoop:
	ld a, (xhl)
	bit 7, a
	jr z, AccPlay_ScanActiveRet
	add xhl, 0x9
	cp xhl, 0x7f0b
	jr z, AccPlay_ScanActiveFail
	jr AccPlay_ScanActiveLoop

AccPlay_ScanActiveFail:
	ld xhl, 0xffff

AccPlay_ScanActiveRet:
	ret

AccPlay_FindSlotByChannel:
	ldda8 w, 0x7f38
	ld xhl, 0x7e7b

AccPlay_ChannelScanLoop:
	ld a, (xhl)
	and a, 0x7f
	cp a, w
	jr z, AccPlay_ChannelSlotFound
	add hl, 0x9
	cp xhl, 0x7f0b
	jr z, AccPlay_ChannelScanFail
	jr AccPlay_ChannelScanLoop

AccPlay_ChannelScanFail:
	jr AccPlay_NoteReleaseRet

AccPlay_ChannelSlotFound:
	ldb a, 0x0
	ld (xhl), a
	ld d, (xhl + 1)
	ld a, (xhl + 2)
	ldda8 c, 0x7f37
	cp c, a
	jr nc, AccPlay_CalcNoteOffset
	add c, 0x60
	cps d, 0
	jr z, AccPlay_CalcNoteOffset
	dec 1, d

AccPlay_CalcNoteOffset:
	sub c, a
	ld e, c
	cps d, 0
	jr nz, AccPlay_WriteNoteRelease
	cps e, 2
	jr nc, AccPlay_WriteNoteRelease
	ldb e, 0x2

AccPlay_WriteNoteRelease:
	ldda16 xwa, 0x7f10
	pushw wa
	ldda16 xwa, 0x7f12
	pushw wa
	ld wa, (xhl + 3)
	stda16 0x7f10, xwa
	ld a, (xhl + 5)
	xor w, w
	stda16 0x7f12, xwa
	pushw de
	calr MidiSeqBuf_AdvanceWritePos
	calr MidiSeqBuf_AdvanceWritePos
	popw de
	ld a, e
	and a, 0x7f
	pushw de
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvanceWritePos
	popw de
	ld a, d
	and a, 0x7f
	calr MidiSeqBuf_WriteByte
	popw wa
	stda16 0x7f12, xwa
	popw wa
	stda16 0x7f10, xwa

AccPlay_NoteReleaseRet:
	ret

AccPlay_HandleEndMarkerEvt:
	lds bc, 1
	calr MidiSeqBuf_ScanAllEntries
	lds de, 1
	calr MidiSeqBuf_ProcessEntries
	ld xhl, 0x7e7b

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
	add xhl, 0x9
	cp xhl, 0x7f0b
	jr nz, AccPlay_IncrementHoldLoop
	ret

MidiSeq_ProcessSustainEvent:
	lds bc, 4
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl)
	cp a, 0xd3
	jr nz, MidiSeq_SustainFixup
	ldb a, 0xd5
	ld (xhl), a

MidiSeq_SustainFixup:
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleD2Event:
	lds bc, 5
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl + 3)
	ld (xhl + 2), a
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleProgChange:
	lds bc, 7
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl + 4)
	ld (xhl + 2), a
	ld a, (xhl + 5)
	ld (xhl + 4), a
	ld a, (xhl)
	and a, 0x1
	ld (xhl + 3), a
	ld a, (xhl)
	and a, 0xf0
	ld (xhl), a
	xor w, w
	ldda8 a, 0xfd66
	bit 6, a
	jr z, MidiSeq_ProgChangeSetReverb
	or w, 0x1

MidiSeq_ProgChangeSetReverb:
	ld (xhl + 5), w
	lds de, 6
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleCtrlChange:
	lds bc, 7
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl + 2)
	ld w, (xhl)
	bit 2, w
	jr z, MidiSeq_CtrlCheckType
	or a, 0x80

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
	ldda8 a, 1076
	ldda8 w, 0x7f34
	cp a, w
	jr z, AccPlay_MeasureTrackRet
	ldda16 xhl, 0x7f0e
	inc 1, hl
	cps hl, 0
	jr nz, AccPlay_MeasureIncrement
	inc 1, hl

AccPlay_MeasureIncrement:
	stda16 0x7f0e, xhl
	cpdi8 0x8d38, 201
	jr nz, AccPlay_MeasureNotifyDone
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccSeq_DeliverC9_0009
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPlay_MeasureNotifyDone:
	stda8 0x7f34, a

AccPlay_MeasureTrackRet:
	ret

AccPlay_TrackVoiceCount:
	ldda16 xwa, 0x7e18
	ldda16 xhl, 0x7e1a
	cp wa, hl
	jr z, AccPlay_VoiceCountRet
	cpdi8 0x8d38, 201
	jr nz, AccPlay_VoiceCountNotify
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccSeq_DeliverC9_000A
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPlay_VoiceCountNotify:
	stda16 0x7e1a, xwa

AccPlay_VoiceCountRet:
	ret

AccPlay_MonitorParamState:
	cpdi8 0x7f0b, 0
	jr z, AccPlay_SaveCurrentState
	cpdi8 0x7f0c, 0
	jr z, AccPlay_InitVoiceBankState
	calr AccPlay_CompareAndSendProg
	jr AccPlay_SaveCurrentState

AccPlay_InitVoiceBankState:
	calr AccPlay_RestoreVoiceBank

AccPlay_SaveCurrentState:
	ldda8 a, 0xfd62
	ldda8 w, 0xfd63
	and w, 0x7f
	stda16 0x7f18, xwa
	ldda8 a, 0xfd66
	and a, 0x48
	xor w, w
	stda16 0x7f1a, xwa
	ret

AccPlay_CompareAndSendProg:
	ldda16 xhl, 0x7f18
	ldda8 a, 0xfd62
	ldda8 w, 0xfd63
	and w, 0x7f
	cp wa, hl
	jr z, AccPlay_CompareReverbState
	ld e, w
	ld w, a
	ldb a, 0xc1
	stda8 0x7e40, w
	and e, 0xf
	bit 7, w
	jr z, AccPlay_SendProgChange
	or e, 0x10
	and w, 0x7f

AccPlay_SendProgChange:
	call AccompSeq_SendMidiEvent

AccPlay_CompareReverbState:
	ldda16 xhl, 0x7f1a
	ldda8 a, 0xfd66
	and a, 0x40
	xor w, w
	and l, 0x40
	cp wa, hl
	jr z, AccPlay_CompareChorusState
	ldb e, 0x0
	cps a, 0
	jr z, AccPlay_SetReverbValue
	ldb e, 0x7f

AccPlay_SetReverbValue:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_CompareChorusState:
	jr AccPlay_ParamMonitorRet
	ldda16 xhl, 0x7f1a
	ldda8 a, 0xfd66
	and a, 0x8
	xor w, w
	and l, 0x8
	cp wa, hl
	jr z, AccPlay_ParamMonitorRet
	ldb e, 0x0
	cps a, 0
	jr z, AccPlay_SetChorusValue
	ldb e, 0x7f

AccPlay_SetChorusValue:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_ParamMonitorRet:
	ret

AccPlay_RestoreVoiceBank:
	calr Voice_GetBankEntryPointer
	ld wa, (xiy + 9)
	ld e, w
	ld w, a
	ldb a, 0xc1
	stda8 0x7e40, w
	and e, 0xf
	bit 7, w
	jr z, AccPlay_SendBankProgram
	or e, 0x10
	and w, 0x7f

AccPlay_SendBankProgram:
	call AccompSeq_SendMidiEvent
	ld wa, (xiy + 9)
	stda8 0xfd62, a
	stda8 0xfd63, w
	ldb e, 0x17
	ldb d, 0x1
	ld a, w
	ldb w, 0x7f
	call SwbtWr_QueuePostEvent
	ld wa, (xiy + 9)
	ldb e, 0x17
	ldb d, 0x0
	ldb w, 0xff
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 12)
	ld e, a
	ldb w, 0x4
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 12)
	stda8 0xfd6a, a
	ldb e, 0x17
	ldb d, 0x8
	ldb w, 0x7f
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 13)
	ldb e, 0x0
	bit 0, a
	jr z, AccPlay_RestoreReverbVal
	ldb e, 0x7f

AccPlay_RestoreReverbVal:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 13)
	ldda8 w, 0xfd66
	and w, 0xbf
	bit 0, a
	jr z, AccPlay_WriteReverbFlag
	or w, 0x40

AccPlay_WriteReverbFlag:
	stda8 0xfd66, w
	ldb e, 0x17
	ldb d, 0x4
	ld a, w
	ldb w, 0x40
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 14)
	ldb e, 0x0
	bit 0, a
	jr z, AccPlay_RestoreChorusVal
	ldb e, 0x7f

AccPlay_RestoreChorusVal:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 14)
	ldda8 w, 0xfd66
	and w, 0xf7
	bit 0, a
	jr z, AccPlay_WriteChorusFlag
	or w, 0x8

AccPlay_WriteChorusFlag:
	stda8 0xfd66, w
	ldb e, 0x17
	ldb d, 0x4
	ld a, w
	ldb w, 0x8
	call SwbtWr_QueuePostEvent
	ret

AccPlay_ClearSlotTable:
	ld xhl, 0x7e7b
	ldb a, 0x0

AccPlay_ClearSlotLoop:
	ld (xhl), a
	add xhl, 0x9
	cp xhl, 0x7f0b
	jr z, AccPlay_ClearSlotDone
	jr AccPlay_ClearSlotLoop

AccPlay_ClearSlotDone:
	ret

AccPlay_SaveMuteStates:
	ldda8 a, 0xf9c3
	ldda8 w, 0xf9dd
	stda16 0x7f1c, xwa
	ldda8 a, 0xf9f7
	ldda8 w, 0xfa11
	stda16 0x7f1e, xwa
	ldda8 a, 0xfa2b
	ldda8 w, 0xfa45
	stda16 0x7f20, xwa
	ldda8 a, 0xfa5f
	ldda8 w, 0xfa79
	stda16 0x7f22, xwa
	ldda8 a, 0xfa93
	ldda8 w, 0xfaad
	stda16 0x7f24, xwa
	ldda8 a, 0xfac7
	ldda8 w, 0xfae1
	stda16 0x7f26, xwa
	ldda8 a, 0xfafb
	ldda8 w, 0xfb15
	stda16 0x7f28, xwa
	ldda8 a, 0xfb2f
	ldda8 w, 0xfb49
	stda16 0x7f2a, xwa
	ldda8 a, 0xfb63
	ldda8 w, 0xfb7d
	stda16 0x7f2c, xwa
	ldda8 a, 0xfb97
	ldda8 w, 0xfbb1
	stda16 0x7f2e, xwa
	ldda8 a, 0xfbcb
	ldda8 w, 0xfbe5
	stda16 0x7f30, xwa
	ldda8 a, 0xfbff
	ldda8 w, 0xfc19
	stda16 0x7f32, xwa
	ldb a, 0xc0
	orddm8 0xf9c3, a
	orddm8 0xf9dd, a
	orddm8 0xf9f7, a
	orddm8 0xfa11, a
	orddm8 0xfa2b, a
	orddm8 0xfa45, a
	orddm8 0xfa5f, a
	orddm8 0xfa79, a
	orddm8 0xfa93, a
	orddm8 0xfaad, a
	orddm8 0xfac7, a
	orddm8 0xfae1, a
	orddm8 0xfafb, a
	orddm8 0xfb15, a
	orddm8 0xfb2f, a
	orddm8 0xfb49, a
	orddm8 0xfb63, a
	orddm8 0xfb7d, a
	orddm8 0xfb97, a
	orddm8 0xfbb1, a
	orddm8 0xfbcb, a
	orddm8 0xfbe5, a
	orddm8 0xfbff, a
	orddm8 0xfc19, a
	ldda8 a, 0xfd6f
	and a, 0x3f
	and a, 0xf0
	stda8 0xfd6f, a
	ldb e, 0x17
	ldb d, 0xd
	ldb w, 0xcf
	call SwbtWr_QueuePostEvent
	calr AccompSeq_QueueAllMutes
	ret

AccompSeq_QueueAllMutes:
	ldb e, 0x0
	ldda8 a, 0xf9c3
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x1
	ldda8 a, 0xf9dd
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x2
	ldda8 a, 0xf9f7
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x3
	ldda8 a, 0xfa11
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x4
	ldda8 a, 0xfa2b
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x5
	ldda8 a, 0xfa45
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x6
	ldda8 a, 0xfa5f
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x7
	ldda8 a, 0xfa79
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x8
	ldda8 a, 0xfa93
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x9
	ldda8 a, 0xfaad
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xa
	ldda8 a, 0xfac7
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xb
	ldda8 a, 0xfae1
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xc
	ldda8 a, 0xfafb
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xd
	ldda8 a, 0xfb15
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xe
	ldda8 a, 0xfb2f
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xf
	ldda8 a, 0xfb49
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x10
	ldda8 a, 0xfb63
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x11
	ldda8 a, 0xfb7d
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x12
	ldda8 a, 0xfb97
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x13
	ldda8 a, 0xfbb1
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x14
	ldda8 a, 0xfbcb
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x15
	ldda8 a, 0xfbe5
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x16
	ldda8 a, 0xfbff
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x19
	ldda8 a, 0xfc19
	calr AccompSeq_QueueMuteEvent
	ret

AccompSeq_QueueMuteEvent:
	ldb d, 0xd
	ldb w, 0xcf
	call SwbtWr_QueuePostEvent
	ret

AccPlay_RestoreMuteStates:
	ldda16 xwa, 0x7f1c
	stda8 0xf9c3, a
	stda8 0xf9dd, w
	ldda16 xwa, 0x7f1e
	stda8 0xf9f7, a
	stda8 0xfa11, w
	ldda16 xwa, 0x7f20
	stda8 0xfa2b, a
	stda8 0xfa45, w
	ldda16 xwa, 0x7f22
	stda8 0xfa5f, a
	stda8 0xfa79, w
	ldda16 xwa, 0x7f24
	stda8 0xfa93, a
	stda8 0xfaad, w
	ldda16 xwa, 0x7f26
	stda8 0xfac7, a
	stda8 0xfae1, w
	ldda16 xwa, 0x7f28
	stda8 0xfafb, a
	stda8 0xfb15, w
	ldda16 xwa, 0x7f2a
	stda8 0xfb2f, a
	stda8 0xfb49, w
	ldda16 xwa, 0x7f2c
	stda8 0xfb63, a
	stda8 0xfb7d, w
	ldda16 xwa, 0x7f2e
	stda8 0xfb97, a
	stda8 0xfbb1, w
	ldda16 xwa, 0x7f30
	stda8 0xfbcb, a
	stda8 0xfbe5, w
	ldda16 xwa, 0x7f32
	stda8 0xfbff, a
	stda8 0xfc19, w
	ldda8 a, 0xfd6f
	or a, 0xc0
	stda8 0xfd6f, a
	ldb e, 0x17
	ldb d, 0xd
	ldb w, 0x4f
	call SwbtWr_QueuePostEvent
	calr AccompSeq_QueueAllMutes
	ret

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
	calr TempoRingBuf_ReadLoop
	ld xhl, 0x7f36
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	dec 1, bc
	cps bc, 0
	jr nz, MidiSeqBuf_ScanLoop
	bitda 4, 0x7f15
	jr z, MidiSeqBuf_ScanDone
	anddi8 0x7f15, 239
	ld (xhl + 1), 0x0

MidiSeqBuf_ScanDone:
	ret

MidiSeqBuf_ProcessEntries:
	cpdi16 0x7e18, 0
	jr z, MidiSeqBuf_ProcessDone
	xor ix, ix

MidiSeqBuf_ProcessLoop:
	ld xhl, 0x7f36
	ld_srib3 A, 0x07, 0xec, 0xf0
	push xix
	pushw de
	ldda16 xhl, 0x7f10
	calr Util_ExtractAndShiftBits
	ldda16 xhl, 0x7f12
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	calr MidiSeqBuf_AdvancePosition
	popw de
	pop xix
	inc 1, ix
	cp ix, de
	jr c, MidiSeqBuf_ProcessLoop

MidiSeqBuf_ProcessDone:
	ret

MidiSeqBuf_AdvancePosition:
	ldda16 xwa, 0x7f12
	inc 1, wa
	cp wa, 0xff
	jr nz, MidiSeqBuf_AdvanceDone
	push xix
	push xde
	push xhl
	calr Voice_FindFreeSlot
	xor ix, ix
	ldda16 xhl, 0x7f10
	ld de, hl
	calr Util_ExtractAndShiftBits
	ld (xix + 3), wa
	stda16 0x7f10, xwa
	ld hl, wa
	calr Util_ExtractAndShiftBits
	ld (xix + 1), de
	ormi8 (xix), 0x80
	decdi16 1, 0x7e18
	lds wa, 6
	pop xhl
	pop xde
	pop xix

MidiSeqBuf_AdvanceDone:
	stda16 0x7f12, xwa
	ret

MidiSeqBuf_AdvanceWritePos:
	ldda16 xwa, 0x7f12
	inc 1, wa
	cp wa, 0xff
	jr nz, MidiSeqBuf_WriteAdvDone
	push xix
	push xde
	push xhl
	ldda16 xhl, 0x7f10
	ld de, hl
	calr Util_ExtractAndShiftBits
	ld wa, (xix + 3)
	stda16 0x7f10, xwa
	lds wa, 6
	pop xhl
	pop xde
	pop xix

MidiSeqBuf_WriteAdvDone:
	stda16 0x7f12, xwa
	ret

MidiSeqBuf_WriteByte:
	push xix
	push xhl
	ldda16 xhl, 0x7f10
	calr Util_ExtractAndShiftBits
	ldda16 xhl, 0x7f12
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	pop xhl
	pop xix
	ret

AccPlay_InitAndStartLoop:
	stdi8 0x7f0b, 0
	call TempoRingBuf_ReInitAndRet
	ordi8 0x7f15, 4
	ldb a, 0x8
	call MIDI_SendSysExCmd
	calr AccPlay_MainUpdateLoop
	ret

AccPlay_ToggleCodeFragment:
	.byte 0xc1
	pushw	0x3f7f
	nop
	jr	z, 12
	stdi8	0x7f0b, 0
	call	TempoRingBuf_ReInitAndRet
	calr	62399
	ret

AccPlay_CheckAndToggle:
	bitda 1, 0x7f0b
	jr z, AccPlay_ToggleRet
	bitda 2, 1055
	jr nz, AccPlay_ToggleRestart
	call AccWrap_PlayModeStartAccPlay
	lds wa, 0
	ei 6
	stda8 1130, a
	stda16 1128, xwa
	stdi8 1055, 1
	ei 0
	jr AccPlay_ToggleRet

AccPlay_ToggleRestart:
	stdi8 0x7f0b, 0
	call TempoRingBuf_ReInitAndRet
	calr AccPlay_MainUpdateLoop

AccPlay_ToggleRet:
	ret

AccPlay_StopAndReset:
	bitda 2, 1056
	jr nz, AccPlay_StopResetRet
	lds wa, 0
	stda8 1047, a
	stda16 1048, xwa
	stda8 1045, a
	stda8 1046, a
	stda8 1076, a
	stda8 1077, a
	stda8 1130, a
	stda16 1128, xwa
	stdi8 1056, 1
	stdi8 1054, 1
	stdi8 1055, 1

AccPlay_StopResetRet:
	ret

InitializeEast:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xe55cd4, 0xe559ea, 0x163
	RegObjTable 0x160000c, 0xfa58fb, 0xe55cda, 0xe55cd6, 0x1c3
	RegObjTable 0x160000d, 0xfa5948, 0xe55dac, 0xe55cdc, 0x1e3
	RegObjTabl 0x1600002, ApFunctionProc, 0x3c, 0xe55210, 0x123
	RegObjTabl 0x1600002, ApFunctionProc, 0x3c, 0xe55304, 0x423
	RegObjTabl 0x1600001, FunctionProc, 0x10, 0xe55dae, 0x103
	RegObjTabl 0x1600001, FunctionProc, 0x10, MidiMenu_NakaProcName_Table, 0x403
	RegObjTabl 0x1600003, MainFunctionProc, 0x7, 0xe5ad8c, 0x143
	RegObjTabl 0x1600003, MainFunctionProc, 0x7, 0xe5adac, 0x443
	RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe59c5a, 0x9
	RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe5a122, 0x309
	RegObjTabl 0x1600010, ViewableProc, 0x3, 0xe59c6e, 0xf
	RegObjTabl 0x160000f, ResNameProc, 0x3, 0xe5a152, 0x30f
	RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59c7e, 0x18
	RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a17a, 0x318
	RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59cb2, 0x19
	RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a1d4, 0x319
	RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe59ce6, 0x1a
	RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe5a23a, 0x31a
	RegObjTabl 0x1600010, ViewableProc, 0x14, 0xe59d1a, 0x50
	RegObjTabl 0x160000f, ResNameProc, 0x14, 0xe5a2a8, 0x350
	RegObjTabl 0x1600010, ViewableProc, 0x7, 0xe59d6e, 0x51
	RegObjTabl 0x160000f, ResNameProc, 0x7, 0xe5a350, 0x351
	RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe59d8e, 0x52
	RegObjTabl 0x160000f, ResNameProc, 0x8, NakaData_WidgetTables2, 0x352
	RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59db2, 0x53
	RegObjTabl 0x160000f, ResNameProc, 0x6, 0xe5a3f2, 0x353
	RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe59dce, 0x54
	RegObjTabl 0x160000f, ResNameProc, 0x5, NakaObj_MidiCommonSetting_Table, 0x354
	RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe59de6, 0x55
	RegObjTabl 0x160000f, ResNameProc, 0x5, NakaObj_MidiInOutSetting_Table, 0x355
	RegObjTabl 0x1600010, ViewableProc, 0x43, 0xe59dfe, 0x56
	RegObjTabl 0x160000f, ResNameProc, 0x43, NakaObj_MidiPresets_Table, 0x356
	RegObjTabl 0x1600010, ViewableProc, 0x1c, 0xe59f0e, 0x57
	RegObjTabl 0x160000f, ResNameProc, 0x1c, 0xe5a77c, 0x357
	RegObjTabl 0x1600010, ViewableProc, 0x15, 0xe59f82, 0x58
	RegObjTabl 0x160000f, ResNameProc, 0x15, 0xe5a906, 0x358
	RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59fda, 0x59
	RegObjTabl 0x160000f, ResNameProc, 0x6, 0xe5a9ae, 0x359
	RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe59ff6, 0x5a
	RegObjTabl 0x160000f, ResNameProc, 0x6, NakaObj_MidiComputerConn_Table, 0x35a
	RegObjTabl 0x1600010, ViewableProc, 0x11, 0xe5a012, 0x5b
	RegObjTabl 0x160000f, ResNameProc, 0x11, NakaObj_MidiPmemOutput_Table, 0x35b
	RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe5a05a, 0x5c
	RegObjTabl 0x160000f, ResNameProc, 0x8, 0xe5aac6, 0x35c
	RegObjTabl 0x1600010, ViewableProc, 0x18, 0xe5a07e, 0xd7
	RegObjTabl 0x160000f, ResNameProc, 0x18, 0xe5ab12, 0x3d7
	RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe5a0e2, 0xd8
	RegObjTabl 0x160000f, ResNameProc, 0x8, 0xe5ac06, 0x3d8
	RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe5a106, 0xec
	RegObjTabl 0x160000f, ResNameProc, 0x6, 0xe5ac5a, 0x3ec

	RegMode 0x3, 0xe5, 0xac90, 0x5, 0x1200000, 0x1a00050

	RegTitle 0x3, 0xe5, 0xac98, 0x9, 0x1200000, 0x90000
	RegTitle 0x3, 0xe5, 0xaca6, 0xf, 0x1200000, 0xf0000
	RegTitle 0x3, 0xe5, 0xacb0, 0x18, 0x1200000, 0x180000
	RegTitle 0x3, 0xe5, 0xacbe, 0x19, 0x1200000, 0x190000
	RegTitle 0x3, 0xe5, 0xacca, 0x1a, 0x1200000, 0x1a0000
	RegTitle 0x3, 0xe5, 0xacda, 0x50, 0x1200000, 0x500000
	RegTitle 0x3, 0xe5, 0xace4, 0x51, 0x1200000, 0x510000
	RegTitle 0x3, 0xe5, 0xacee, 0x52, 0x1200000, 0x520000
	RegTitle 0x3, 0xe5, 0xacf8, 0x53, 0x1200000, 0x530000
	RegTitle 0x3, 0xe5, 0xad02, 0x54, 0x1200000, 0x540000
	RegTitle 0x3, 0xe5, 0xad0c, 0x55, 0x1200000, 0x550000
	RegTitle 0x3, 0xe5, 0xad18, 0x56, 0x1200000, 0x560000
	RegTitle 0x3, 0xe5, 0xad24, 0x57, 0x1200000, 0x570000
	RegTitle 0x3, 0xe5, 0xad2e, 0x58, 0x1200000, 0x580000
	RegTitle 0x3, 0xe5, 0xad3a, 0x59, 0x1200000, 0x590000
	RegTitle 0x3, 0xe5, 0xad46, 0x5a, 0x1200000, 0x5a0000
	RegTitle 0x3, 0xe5, 0xad50, 0x5b, 0x1200000, 0x5b0000
	RegTitle 0x3, 0xe5, 0xad5c, 0x5c, 0x1200000, 0x5c0000
	RegTitle 0x3, 0xe5, 0xad68, 0xd7, 0x1200000, 0xd70000
	RegTitle 0x3, 0xe5, 0xad74, 0xd8, 0x1200000, 0xd80000
	RegTitle 0x3, 0xe5, 0xad80, 0xec, 0x1200000, 0xec0000

	lda xsp, (xsp + 14)
	ret


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
	lda_24 xhl, Bitmap_Bmphk
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
	add xbc, MidiPart_PageStr_1of3_0x42_
	ld bc, (xbc)
	lda_24 xix, AcVocalGrid_DialSetup
	jp_dri 8, 0x07, 0xf0, 0xe4

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
	ldi_werp 0xe2, 0
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
	ldi_werp 0xe2, 0
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
	lda_24 xbc, MidiPart_PageStr_1of3_0x12_
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, MidiPart_PageStr_1of3_0x2A_
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
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
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr Vocalist_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr AcVocalGrid_FuncCallB

; AcVocalGridBoxProc function callback A
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
	ld xiy, MidiPart_OctaveStr_m2_0x64_
	lda xix, (xsp + 20)
	ldw bc, 0x10
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0x0A_
	lda xix, (xsp + 12)
	lds bc, 4
	ldirw
	ld xix, xhl
	lda xbc, (xsp + 12)
	lda_24 xwa, MidiPart_OctaveStr_m2_0x04_
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
	add xwa, MidiPart_ColWidthData_0x28_
	ld wa, (xwa)
	lda_24 xix, VocalistGrid_DispatchData
	jp_dri 8, 0x07, 0xf0, 0xe0

VocalistGrid_DispatchData:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 0
	.byte 0xd7, 0xe2, 0xa8
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	cpw	(xhl), 1
	jr	z, 7
	cpw	(xhl), 2
	jrl	nz, 1604
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda_24	xde, MidiPart_OctaveStr_m2_0x04_
	.byte 0xe3
	reti
	cp	xwa, xwa
	ldb	w, 232
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jrl	z, 1571
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	w, 217
	sub	(xbc-38), xde
	jr	102
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 0
	.byte 0xd7, 0xe2, 0xa8
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	.byte 0x93
	push	xsp
	.byte 0x01
	nop
	jr	z, 7
	.byte 0x93
	push	xsp
	push_sr
	nop
	jrl	nz, 1501
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda_24	xde, MidiPart_OctaveStr_m2_0x04_
	.byte 0xe3
	reti
	cp	xwa, xwa
	ldb	w, 232
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jrl	z, 1468
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	w, 49
	swi	7
	swi	7
	lds	de, 2
	call	MainLswAdd
	jrl	1442
	ld	(xsp+4), xbc
	ld	xhl, xiy
	.byte 0xb5
	push_sr
	nop
	nop
	ld	xix, (xsp+8)
	ld	xiz, xde
	ld	xiy, xde
	jr	50
	.byte 0xd7, 0xe6, 0x99, 0xd7, 0xe6, 0xec
	pop_sr
	ld	xwa, (xiz)
	.byte 0xe3
	reti
	.byte 0xf0, 0xe6, 0xf0
	jr	nz, 4
	lds	bc, 1
	jr	19
	.byte 0xd7, 0xe6
	incm8	4, (xwa-40)
	.byte 0xd7, 0xe6
	ld	wa, (xwa-91)
	.byte 0xe3
	reti
	.byte 0xf0, 0xe6, 0xf0
	jr	nz, 9
	lds	bc, 2
	ld	xwa, (xsp+4)
	ld	(xwa), bc
	jr	12
	inc	1, bc
	ld	(xhl), bc
	ld	bc, (xhl)
	cp	bc, 12
	jr	lt, -58
	lda	xwa, (xsp+20)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xsp+8)
	ld	(xwa+4), xbc
	ld	xwa, (xde)
	lda	xbc, (xde+4)
	sub	xwa, 0x2d00
	cp	xwa, 0
	jrl	c, 1331
	cp	xwa, 19
	jrl	ugt, 1322
	add	xwa, xwa
	.byte 0xe8, 0xc8
	.long MidiPart_ColWidthData
	ld	wa, (xwa)
	lda_24	xix, VocalistGrid_DispatchData_0x160_
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	adc	bc, wa
	ldb	w, 216
	.byte 0xcf
	rcf
	nop
	jr	z, 13
	cp	wa, 17
	jr	nz, 25
	ld	xwa, MidiPart_OctaveStr_m2_0x84_
	jr	5
	ld	xwa, MidiPart_OctaveStr_m2_0x90_
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	20
	inc	1, wa
	pushw	wa
	pushw	231
	pushw	0xeef8
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	1222
	ld	wa, (xbc)
	inc	1, wa
	.long Bitmap_MIDIConnections_Header
	pushw	0xef04
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	1183
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw	231
	pushw	0xef10
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	1144
	ld	wa, (xbc)
	sla	wa, 2
	lda_24	xbc, MidiPart_NoteNameTable
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	pushw	231
	pushw	0xef1c
	ld	xwa, (xsp+16)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	1094
	ld	wa, (xbc)
	cps	wa, 3
	jr	z, 33
	cps	wa, 2
	jr	z, 22
	cps	wa, 1
	jr	z, 11
	cps	wa, 0
	.ascii "n%@("
	or	xsp, xsp
	nop
	jr	19
	ld	xwa, MidiPart_OctaveStr_m2_0xD8_
	jr	12
	ld	xwa, MidiPart_OctaveStr_m2_0xE4_
	jr	5
	ld	xwa, MidiPart_OctaveStr_m2_0xF0_
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	1022
	ld	wa, (xbc)
	cp	wa, 120
	jr	z, 13
	cp	wa, 121
	jr	nz, 25
	ld	xwa, MidiPart_OctaveStr_m2_0xFC_
	jr	5
	ld	xwa, MidiPart_OctaveStr_m2_0x108_
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	18
	pushw	wa
	pushw	231
	pushw	0xef70
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	948
	ld	bc, (xbc)
	ld	de, bc
	and	de, 127
	ld	wa, de
	exts	xwa
	divs	wa, 12
	sla	wa, 2
	lda_24	xhl, MidiPart_OctaveTable
	.byte 0xe3
	reti
	or	xwa, xix
	ldb	w, 56
	exts	xde
	divs	de, 12
	.byte 0xd7
	ld	xwa, xde
	sla	wa, 2
	lda_24	xde, MidiPart_NoteNameTable
	.byte 0xe3
	reti
	or	xwa, xwa
	ldb	w, 56
	and	bc, 128
	sra	bc, 7
	sla	bc, 2
	lda_24	xwa, MidiPart_PageStr_1of3_0x50_
	.byte 0xe3
	reti
	.byte 0xe0, 0xe4
	ldb	w, 56
	pushw	231
	pushw	0xef7c
	ld	xwa, (xsp+24)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	840
	ld	xwa, MidiPart_OctaveStr_m2_0x12E_
	.byte 0x91
	push	xsp
	nop
	nop
	jr	z, 5
	ld	xwa, MidiPart_OctaveStr_m2_0x128_
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	796

; VocalistGridCheck dispatch handler
VocalistGrid_CheckHandler:
	ld (xsp + 4), xbc
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xe2, 0
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
	add xwa, MidiPart_AfterStr_0x34_
	ld wa, (xwa)
	lda_24 xix, VocalistGrid_CheckDispData
	jp_dri 8, 0x07, 0xf0, 0xe0

VocalistGrid_CheckDispData:
	ld	xwa, 0x2d00
	call	SndParam_LookupReadOnly
	cp	hl, 16
	jr	z, 13
	cp	hl, 17
	jr	nz, 25
	ld	xwa, MidiPart_OctaveStr_m2_0x134_
	jr	5
	ld	xwa, MidiPart_OctaveStr_m2_0x140_
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	29
	ld	xwa, 0x2d00
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	0xefa8
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	613
	ld	xwa, 0x2d02
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	0xefb4
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	567
	ld	xwa, 0x2d04
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	0xefc0
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	521
	ld	xwa, 0x2d06
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda_24	xwa, MidiPart_NoteNameTable
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	pushw	231
	pushw	0xefcc
	lda	xwa, (xsp+28)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	464
	ld	xwa, 0x2d08
	call	SndParam_LookupReadOnly
	cps	hl, 3
	jr	z, 33
	cps	hl, 2
	jr	z, 22
	cps	hl, 1
	jr	z, 11
	cps	hl, 0
	jr	nz, 37
	ld	xwa, MidiPart_OctaveStr_m2_0x17C_
	jr	19
	ld	xwa, MidiPart_OctaveStr_m2_0x188_
	jr	12
	ld	xwa, MidiPart_OctaveStr_m2_0x194_
	jr	5
	.byte 0x40
	.long MidiPart_RecvTransStr
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	385
	ld	xwa, 0x2d0a
	call	SndParam_LookupReadOnly
	lda	xbc, (xsp+20)
	cp	hl, 120
	jr	z, 13
	cp	hl, 121
	jr	nz, 22
	ld	xwa, MidiPart_RecvTransStr_0x0C_
	jr	5
	.byte 0x40
	.long MidiPart_AfterStr
	push	xwa
	push	xbc
	call	Strcpy
	inc	8, xsp
	jr	27
	ld	xwa, 0x2d0a
	call	SndParam_LookupReadOnly
	pushw	hl
	pushw	231
	pushw	0xf020
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	295
	ld	xwa, 0x2d0d
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda_24	xbc, MidiPart_OctaveTable
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	ld	xwa, 0x2d0d
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	.byte 0xd7
	ld	xwa, xiz
	sla	wa, 2
	lda_24	xbc, MidiPart_NoteNameTable
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	ld	xwa, 0x2d0e
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda_24	xwa, MidiPart_PageStr_1of3_0x50_
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	pushw	231
	pushw	0xf02c
	lda	xwa, (xsp+36)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jrl	177
	ld	xwa, 0x2d11
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda_24	xbc, MidiPart_OctaveTable
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	ld	xwa, 0x2d11
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	.byte 0xd7
	ld	xwa, xiz
	sla	wa, 2
	lda_24	xbc, MidiPart_NoteNameTable
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	ld	xwa, 0x2d12
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda_24	xwa, MidiPart_PageStr_1of3_0x50_
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	pushw	231
	pushw	0xf034
	lda	xwa, (xsp+36)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	jr	60
	ld	xwa, (xsp+4)
	ld	wa, (xwa)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	w, 29
	.byte 0x37, 0xd4
	swi	4
	ld	xwa, MidiPart_AfterStr_0x2E_
	cps	hl, 0
	jr	z, 5
	ld	xwa, MidiPart_AfterStr_0x28_
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 0x01e0008c
	call	SendEvent

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
	add xhl, MidiPart_ColWidthData_0x36_
	ld hl, (xhl)
	lda_24 xix, AcVocalist_ListDispatch
	jp_dri 8, 0x07, 0xf0, 0xec
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
	ld xiy, MidiPart_HarmLocalStr_0x18_
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, MidiPart_HarmLocalStr_0x1C_
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
	ld32_24 xde, MidiPart_ColWidthData_0x42_
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
	ld32_24 xde, MidiPart_ColWidthData_0x42_
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
	lda_24 xix, MidiPart_HarmLocalStr_0x24_
	ld_sriw3 DE, 0x07, 0xf0, 0xe8
	lda_24 xix, VocalistPage1OK_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; MainVocalistPage1OKFunc dispatch
VocalistPage1OK_Dispatch:
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	stdi8	0xb7ec, 11
	call	SndParam_ApplyAndSync
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 0x01d400
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 0x01d400
	lds	bc, 0
	lds	de, 2
	call	SoundParam_NotifyChange
	stdi8	0x7f42, 35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000ee
	call	ApPostEvent
	stdi8	0x7f40, 1
	call	MidiSysEx_SendAllParams
	.byte 0xf1, 0x40
	jrl	nc, 0x0000

; Vocalist page handler
VocalistPage_Handler:
	lds32 xhl, 0
	inc 4, xsp
	ret

VocalistPage1_DispatchData:
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	stdi8	0xb7ec, 2
	call	SndParam_ApplyAndSync
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 0x018000
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 0x018000
	lds	bc, 0
	lds	de, 2
	call	SoundParam_NotifyChange
	stdi8	0x7f42, 35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000ee
	jr	-98
	ld	wa, bc
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	stdi8	0xb7ec, 24
	call	SndParam_ApplyAndSync
	ld	xwa, 0x4201
	lds	bc, 3
	lds	de, 2
	call	SoundParam_NotifyChange
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 0x018c00
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 0x018c00
	lds	bc, 0
	lds	de, 2
	call	SoundParam_NotifyChange
	stdi8	0x7f42, 35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000ee
	jrl	-189
	ld	wa, bc
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	stdi8	0xb7ec, 1
	call	SndParam_ApplyAndSync
	lds	wa, 1
	call	SmfMedley_RawData
	stdi8	0x7f42, 35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000ee
	jrl	-237

MainVocalistPage2OKFunc:
	cp xbc, 0x1e30008
	jr nz, VocalistPage2_ReturnZero
	call MidiSysEx_SendAllParams
	stdi8 0x7f42, 35
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent

VocalistPage2_ReturnZero:
	lds32 xhl, 0
	ret

AccPlay_GetCurrentPart:
	ldda8 l, 0x7f40
	ret

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
	ld xde, MidiPart_HarmLocalStr_0x30_

RevSel_SendAndRet:
	call SendEvent
	jr RevSel_ReturnZero

RevSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
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
	call SendEvent
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	exts xhl
	ld xwa, 0x19000b
	ld xbc, 0x1e0003b
	ld xde, xhl
	jrl EqSel_SendEvent

EqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, MidiPart_HarmLocalStr_0x36_
	jr EqSel_SendEvent

EqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
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
	call SendEvent
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	exts xhl
	ld xwa, 0x1a000a
	ld xbc, 0x1e0003b
	ld xde, xhl
	jrl RevEqSel_SendEvent

RevEqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, MidiPart_HarmLocalStr_0x3C_
	jr RevEqSel_SendEvent

RevEqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
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
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	ld xwa, (xiz + 50)
	ld (xwa), hl
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	lds32 xhl, 0

AcGMOnOff_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret

StsAttentionCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAttention_ReturnZero
	lda_24 xhl, GMMode_AttentionTable
	ret

StsAttention_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOnCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOn_ReturnZero
	lda_24 xhl, GMMode_Attention_English2_0x204_
	ret

StsGMOn_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOffCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOff_ReturnZero
	lda_24 xhl, GMMode_Attention_English2_0x47C_
	ret

StsGMOff_ReturnZero:
	lds32 xhl, 0
	ret

StsAreYouSureCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAreYouSure_ReturnZero
	lda_24 xhl, GMMode_Attention_English2_0x494_
	ret

StsAreYouSure_ReturnZero:
	lds32 xhl, 0
	ret

GMOKFunc:
	ld8_24 l, 0x0340ea
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
	ld xwa, 0x580001
	ld xbc, 0x1e0006b
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xc0
	ld bc, hl
	lds de, 1
	call MainLswPut
	ld xwa, 0xffffffff
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	stdi8 0x7f42, 35
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	lds32 xhl, 0
	ret

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
	lda_24 xhl, GMMode_Attention_English2_0x514_
	ret

StsSplit_ReturnZero:
	lds32 xhl, 0
	ret

SplitPointFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, SplitPoint_NoteEntry_C_Code_0x38_
	lda xix, (xsp + 4)
	ldiw
	ldiw
	cp xde, 0x1e0003f
	jrl z, ParamFunc_ReturnOne
	cp xde, 0x1e0003e
	jrl z, ParamFunc_ReturnOne
	cp xde, 0x1e00041
	jrl z, ParamFunc_ReturnOne
	cp xde, 0x1e00040
	jrl z, SplitPoint_ReturnParamId
	cp xde, 0x1e00042
	jrl z, SplitPoint_HandleNoteEvt
	cp xde, 0x1e30002
	jrl nz, SplitPoint_ReturnZero
	ld xwa, 0x4180
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	ld xwa, (xsp + 8)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0x24
	jr c, SplitPoint_ClampToMiddle
	cp_erpb 0xfb, 0x60
	jr ule, SplitPoint_StartDraw

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
	addmi16 (xsp + 4), 0x38
	inc 1, iz

Draw_keybed_maybe_for_indicating_split_point:
	ldto_berp A, 0xfb
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
	ldto_berp C, 0xfb
	extz bc
	div c, 0xc
	ld c, b
	extz bc
	sla bc, 2
	lda_24 xde, SplitPoint_NoteEntry_C_Code_0x04_
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	pushw 0x34
	ldw de, 0x39
	call DrawBitmapSPFast
	addmi16 (xsp + 4), 0x38
	inc 1, iz
	cps iz, 5
	jr nc, SplitPoint_UpdateScreen

SplitPoint_FillRemainingLoop:
	lda xwa, (xsp + 4)
	pushw 0x34
	ld xbc, Bitmap_SplitPoint_no_split
	ldw de, 0x39
	call DrawBitmapSPFast
	addmi16 (xsp + 4), 0x38
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
	ld xde, (xsp + 8)
	ld bc, (xde + 4)
	ld wa, bc
	exts xwa
	divs wa, 0xc
	dec 2, wa
	pushw wa
	exts xbc
	divs bc, 0xc
	ldto_werp WA, 0xe6
	sla wa, 2
	lda_24 xbc, SplitPoint_NoteNameTable
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xe7
	pushw 0xf81a
	ld xwa, (xde + 8)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	ld xwa, (xsp + 8)
	ld de, (xwa + 4)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1e30002
	call ApFuncCall
	ld xhl, (xsp + 12)
	jr ParamFunc_CommonExit

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
	ld c, a
	cpdi8 0x8d38, 236
	ret nz
	cp c, 0x15
	ret c
	cp c, 0x6c
	ret ugt
	extz bc
	ld xwa, 0x4181
	lds de, 1
	call SoundParam_NotifyChange
	ret

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
	ld xwa, SplitPoint_NoteEntry_C_Code_0x42_
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave2:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x48_
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave3:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x4E_
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave4:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x54_
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave5:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x5A_
	jr R12Octave_StringCopyAndSendEvent

R12Octave_OctaveDefault:
	ld xwa, SplitPoint_NoteEntry_C_Code_0x60_

R12Octave_StringCopyAndSendEvent:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, 0xffffffff
	ld xbc, 0x1e00078
	lds32 xde, 0
	call SendEvent
	ld xhl, xiz
	jr R12Octave_PopIzRet

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
