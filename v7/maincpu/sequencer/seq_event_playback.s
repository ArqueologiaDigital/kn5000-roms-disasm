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
	ld	(32097:16), 95
	ldw	(32102:16), 9
	ldw	(32104:16), 72
	ld	(32106:16), 16
	ld	(32107:16), 1
	ld	a, (32108:16)
	ld	(32110:16), a
	ld	xhl, 31312
	ld	xbc, 31952
	calr	51
	ld	a, (32110:16)
	ld	(32108:16), a
	ld	(32107:16), 2
	ld	a, (32109:16)
	ld	(32110:16), a
	ld	xhl, 31568
	ld	xbc, 32024
	calr	17
	ld	a, (32110:16)
	ld	(32109:16), a
	ld	a, (32097:16)
	ld	(32096:16), a
	ret
SeqEvt_ProcessReadLoop:
	ld	ix, (xhl+6)
	ld	(32115:16), ix
SeqEvt_ProcessLoop_Check:
	cp (xhl + 4), ix
	jr nz, SeqEvt_ClassifyEventType
	jp SeqEvt_ProcessLoopRet

SeqEvt_ClassifyEventType:
	ld_rrb	a, xhl, ix
	calr	901
	ld	w, a
	cp	a, 144
	jr	nz, 7
	ld	(32114:16), 5
	jr	49
SeqEvt_CheckType91:
	cp	a, 145
	jr	nz, 7
	ld	(32114:16), 7
	jr	37
SeqEvt_CheckTypeC0:
	and	a, 240
	cp	a, 192
	jr	nz, 7
	ld	(32114:16), 4
	jr	22
SeqEvt_CheckTypeD0:
	cp	a, 208
	jr	z, 12
	ld	ix, (xhl+4)
	ld	(xhl+6), ix
	ld	(32115:16), ix
	jr	-75
SeqEvt_TypeD0_SetCount:
	ld	(32114:16), 2
SeqEvt_ReadAndDispatchEntry:
	ld_rrb	a, xhl, ix
	ld	(32117:16), ix
	calr	826
	ld	(32115:16), ix
	cp	a, (1132:16)
	jr	ule, 4
	jp	16189567
SeqEvt_DispatchByChannel:
	ld a, w
	and a, 0xf0
	cp a, 0x90
	jr z, SeqEvt_ProcessNoteOn
	jr SeqEvt_ProcessNonNoteEvent

SeqEvt_ProcessNoteOn:
	pushw wa

	ldb_sri W, 0x07, 0xec, 0xf0

	ld (32119:16), xhl

	ld xhl, xbc

	ld xbc, (32119:16)

	xor ix, ix



SeqEvt_SlotScanLoop:
	.byte 0xd1, 0x68, 0x7d, 0xf4, 0x67, 0x02, 0x68, 0x1f
SeqEvt_CheckSlotActive:
	bit_dri 7, 0x07, 0xec, 0xf0
	jr z, SeqEvt_AdvanceSlotIndex
	ld xiy, xhl
	and xix, 0xffff
	add xiy, xix
	cp (xiy + 2), w
	jr z, SeqEvt_SlotMatchFound

SeqEvt_AdvanceSlotIndex:
	.byte 0xd1, 0x66, 0x7d, 0x84, 0x68, 0xdc
SeqEvt_SlotMatchFound:
	calr SeqEvt_WriteNoteOff

SeqEvt_AfterSlotScan:
	popw wa
	xor ix, ix

SeqEvt_FindFreeSlotLoop:
	.byte 0xd1, 0x68, 0x7d, 0xf4, 0x6f, 0x19, 0xf3, 0x07
	.byte 0xec, 0xf0, 0xcf, 0x6e, 0x0c, 0xf1, 0x77, 0x7d
	.byte 0x63, 0xe9, 0x8b, 0xe1, 0x77, 0x7d, 0x21, 0x68
	.byte 0x09
SeqEvt_AdvanceFreeSlotIdx:
	.byte 0xd1, 0x66, 0x7d, 0x84, 0x68, 0xe1
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
	ldb_sri A, 0x07, 0xec, 0xf0

	and_srib_im 0x07, 0xec, 0xf0, 0x7f

	and a, 0xf0

	orda8 xbc, (32107)

	calr 640

	ld a, w

	calr	635

	ldb a, 0x0

	calr	630

	ret



SeqEvt_WriteNoteOnRotating:
	push XWA
	xor XWA,XWA
	ld a, (0x7d6e:16)
	ld XIX,SeqEvt_RotationOffsetTable
	add XIX,XWA
	ld IX,(XIX)
	.byte 0xc3, 0x07, 0xec, 0xf0, 0x21, 0xc3, 0x07, 0xec
	.byte 0xf0, 0x3c, 0x7f, 0xdc, 0x8e, 0xdc, 0x62, 0xc3
	.byte 0x07, 0xec, 0xf0, 0x20, 0xf1, 0x77, 0x7d, 0x63
	.byte 0xe9, 0x8b, 0xe1, 0x77, 0x7d, 0x21, 0xc9, 0xcc
	.byte 0xf0, 0xc1, 0x6b, 0x7d, 0xe1, 0x1e, 0x3d, 0x02
	.byte 0xc8, 0x89, 0x1e, 0x38, 0x02, 0x21, 0x00, 0x1e
	.byte 0x33, 0x02, 0xde, 0x8c, 0x58, 0xc1, 0x6e, 0x7d
	.byte 0x38, 0x02, 0xc1, 0x6e, 0x7d, 0x21, 0xc1, 0x6a
	.byte 0x7d, 0xf1, 0x67, 0x05, 0xf1, 0x6e, 0x7d, 0x00
	.byte 0x00
SeqEvt_RotateIndexDone:
	ld a, w
	and a, 0xf0
	ret

SeqEvt_WriteVoiceParams:
	orda8 a, (0x7d6b)
	calr SeqEvtBuf_WriteBytePreserve
	ld (0x7d77:16), xhl
	ld XHL,XBC
	ld xbc, (0x7d77:16)
	ld A,W
	stb_dri a, 0x07, 0xec, 0xf0
	inc 1,IX
	ldb A, 0x00
	stb_dri a, 0x07, 0xec, 0xf0
	inc 1,IX
	ld (0x7d77:16), xhl
	ld XHL,XBC
	ld xbc, (0x7d77:16)
	.byte 0xdc, 0xbe, 0xd1, 0x73, 0x7d, 0x24, 0xc3, 0x07
	.byte 0xec, 0xf0, 0x21, 0x1e, 0xf2, 0x01, 0xdc, 0xbe
	.byte 0x1e, 0xd6, 0x01, 0xf1, 0x77, 0x7d, 0x63, 0xe9
	.byte 0x8b, 0xe1, 0x77, 0x7d, 0x21, 0xf3, 0x07, 0xec
	.byte 0xf0, 0x41, 0xdc, 0x61, 0xf1, 0x77, 0x7d, 0x63
	.byte 0xe9, 0x8b, 0xe1, 0x77, 0x7d, 0x21, 0xdc, 0xbe
	.byte 0xc3, 0x07, 0xec, 0xf0, 0x21, 0x1e, 0xc8, 0x01
	.byte 0xdc, 0xbe, 0x1e, 0xac, 0x01, 0xf1, 0x77, 0x7d
	.byte 0x63, 0xe9, 0x8b, 0xe1, 0x77, 0x7d, 0x21, 0xf3
	.byte 0x07, 0xec, 0xf0, 0x41, 0xdc, 0x61, 0xf1, 0x77
	.byte 0x7d, 0x63, 0xe9, 0x8b, 0xe1, 0x77, 0x7d, 0x21
	.byte 0x38, 0xdc, 0xbe, 0xc3, 0x07, 0xec, 0xf0, 0x21
	.byte 0x1e, 0x9d, 0x01, 0xc3, 0x07, 0xec, 0xf0, 0x20
	.byte 0x1e, 0x95, 0x01, 0xdc, 0xbe, 0xd1, 0x6e, 0x04
	.byte 0x80, 0xc9, 0xcf, 0x60, 0x67, 0x05, 0xc8, 0x61
	.byte 0xc9, 0xca, 0x60
SeqEvt_AdjustNoteOctave:
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	st_rrw	wa, xhl, ix
	inc	2, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	cp	wa, (32098:16)
	jr	nc, 4	; -> 0xF709D3
	ld	(32098:16), wa
SeqEvt_WriteRemainingParams:
	pop	xwa
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	341
	ld	(32115:16), ix
	ex16	iz, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	st_rrb	a, xhl, ix
	inc	1, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	cp	w, 144
	jr	z, 86	; -> 0xF70A5A
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	293
	ld	(32115:16), ix
	ex16	iz, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	st_rrb	a, xhl, ix
	inc	1, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	250
	ld	(32115:16), ix
	ex16	iz, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
	st_rrb	a, xhl, ix
	inc	1, ix
	ld	(32119:16), xhl
	ld	xhl, xbc
	ld	xbc, (32119:16)
SeqEvt_UpdateReadPosition:
	ld	ix, (32115:16)
	ld	(xhl+6), ix
	ret
SeqEvt_HandleControlEvent:
	ld W,A
	orda8 a, (0x7d6b)
	calr SeqEvtBuf_WriteBytePreserve
	ld ix, (0x7d73:16)
	cp W,0xd0
	jr nz, SeqEvt_HandleExtendedCtrl
	ldb_dri a, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	ldb_dri a, 0x07, 0xec, 0xf0
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	jr t, SeqEvt_SaveReadPosAndRet
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
	popw	bc
	calr	101
	ldb	a, 208
	orda8	a, 32107
	calr	92
	ldb	a, 7
	calr	87
	ld_rrb	w, xhl, ix
	calr	102
	ldb	a, 0
	bit	0, w
	jr	z, 2
	ldb	a, 127
SeqEvt_WriteSustainValue:
	calr SeqEvtBuf_WriteBytePreserve

SeqEvt_SaveReadPosAndRet:
	ld	(32115:16), ix
	ld	(xhl+6), ix
	ret
SeqEvt_CalcTempoOffset:
	subda8 a, (0x046c)
	cp a, (0x7d61:16)
	jr nc, .Lc_f70aef
	ld (0x7d61:16), a
SeqEvt_UpdateMinTempo:
.Lc_f70aef:
	ld iy, (0x7d75:16)
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xd8, 0xd0, 0xc1
	.byte 0x72, 0x7d, 0x21, 0xd1, 0x73, 0x7d, 0x80, 0xf1
	.byte 0x73, 0x7d, 0x50, 0xd8, 0x8c, 0x9b, 0x02, 0xf4
	.byte 0x6b, 0x02, 0x68, 0x0c
SeqEvt_HandleBufferWrap:
	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 256)

	.byte 0xf1, 0x73, 0x7d, 0x54	; stda16 (0x7e0f), xix (v7 patched)



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
	ldw	(32100:16), 65375
	ldw	(32102:16), 9
	ldw	(32104:16), 72
	ld	(32107:16), 1
	ld	xhl, 31952
	calr	24
	ld	(32107:16), 2
	ld	xhl, 32024
	calr	11
	ld	wa, (32100:16)
	ld	(32098:16), wa
	jr	0
SeqEvt_VoiceScanDone:
	ret

Voice_ScanSlotMetric:
	xor iy, iy

Voice_ScanLoop:
	.byte 0xd1, 0x68, 0x7d, 0xf5, 0x67, 0x04, 0x1b, 0x13
	.byte 0x0c, 0xf7
Voice_CheckSlotBit:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, Voice_ReadSlotParams
	jr Voice_ParamComplete

Voice_ReadSlotParams:
	.byte 0xdd, 0x8c, 0xc3, 0x07, 0xec, 0xf0, 0x21, 0xf1
	.byte 0x6f, 0x7d, 0x41, 0xdc, 0x62, 0xc3, 0x07, 0xec
	.byte 0xf0, 0x21, 0xf1, 0x70, 0x7d, 0x41, 0xdc, 0x61
	.byte 0xc3, 0x07, 0xec, 0xf0, 0x21, 0xf1, 0x71, 0x7d
	.byte 0x41, 0xdc, 0x61, 0xd3, 0x07, 0xec, 0xf0, 0x20
	.byte 0xd1, 0x6e, 0x04, 0xf0, 0x6a, 0x28, 0xde, 0xbd
	.byte 0x9b, 0x04, 0x25, 0x21, 0xf0, 0xc1, 0x6f, 0x7d
	.byte 0xc1, 0xc1, 0x6b, 0x7d, 0xe1, 0x1e, 0x42, 0xff
	.byte 0xc1, 0x70, 0x7d, 0x21, 0x1e, 0x3b, 0xff, 0x21
	.byte 0x00, 0x1e, 0x36, 0xff, 0xde, 0xbd, 0xc3, 0x07
	.byte 0xec, 0xf4, 0x3c, 0x7f, 0x68, 0x1b
Voice_SubtractBaseFreq:
	subda16 xwa, 1134
	bit 7, a
	jr z, Voice_StoreMetricValue
	add a, 0x60

Voice_StoreMetricValue:
	.byte 0xf3, 0x07, 0xec, 0xf0, 0x50, 0xd1, 0x64, 0x7d
	.byte 0xf0, 0x6f, 0x04, 0xf1, 0x64, 0x7d, 0x50
Voice_ParamComplete:
	.byte 0xd1, 0x66, 0x7d, 0x85, 0x1b, 0x87, 0x0b, 0xf7
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
	cp (0x7e6f:16), 0x00
	jr z, AccPlay_CheckPrevRunning
	cp (0x7e70:16), 0x00
	jr z, AccPlay_StartNewAccomp
	bit 0, (0x7e6f:16)
	jr z, AccPlay_RunningWithBit0
	calr AccPlay_DispatchSeqStart
	jr t, AccPlay_ContinueMainLoop
AccPlay_RunningWithBit0:
	calr AccPlay_HandleStopState
	jr AccPlay_ContinueMainLoop

AccPlay_StartNewAccomp:
	calr AccPlay_InitializeStart
	jr AccPlay_ContinueMainLoop

AccPlay_CheckPrevRunning:
	.byte 0xc1, 0x70, 0x7e, 0x3f, 0x00, 0x66, 0x05, 0x1e
	.byte 0x99, 0x00, 0x68, 0x03
AccPlay_StopSequencer:
	calr AccPlay_StopIfRunning

AccPlay_ContinueMainLoop:
	.byte 0x1e, 0x64, 0x07, 0xf1, 0x99, 0x7e, 0xc8, 0x66
	.byte 0x08, 0xc1, 0x99, 0x7e, 0x3c, 0xfe, 0x1e, 0xc5
	.byte 0x0c
AccPlay_UpdateStateFlags:
	.byte 0xc1, 0x6f, 0x7e, 0x21, 0xf1, 0x70, 0x7e, 0x41
	.byte 0xf1, 0x79, 0x7e, 0xca, 0x66, 0x15, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x01, 0x6e, 0x0e, 0xc1, 0x79, 0x7e
	.byte 0x3c, 0xfb, 0xf1, 0xa6, 0x7e, 0x00, 0x0f, 0x1d
	.byte 0xee, 0x54, 0xf6
AccPlay_DispatchRet:
	ret

AccPlay_InitializeStart:
	call AccWrap_PlayModeDispatch
	call CountAvailableVoiceSlots
	calr AccPlay_SetupSoundParams
	call 0xfdd726
	calr AccPlay_SaveMuteStates
	ldw (0x7e72:16), 0xfffe
	ld (0x7e98:16), 0x00
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	xor WA,WA
	ldb A, 0x10
	call UI_PostPartChangeEvent
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ld a, (0x0433:16)
	sla A, 0x01
	and A,0x1f
	or A,0x80
	ld (0x7e7a:16), a
	ld XHL,0x001e880a
	.byte 0x83, 0x3e, 0x01, 0x40, 0x22, 0x00, 0x00, 0x00
	.byte 0xe9, 0xa8, 0xea, 0xa8, 0x1d, 0xb7, 0x71, 0xfc
	.byte 0xf1, 0xb2, 0x8e, 0x00, 0x04, 0x0e
AccPlay_MainUpdateLoop:
	call AccWrap_PlayModeDispatch
	ld (0x041f:16), 0x0c
	calr AccPlay_ExtractVoiceSlot
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call PartSelect_UpdateDisplayState
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	call 0xfdd726
	calr AccPlay_RestoreMuteStates
	calr AccPlay_ClearSlotTable
	cp (0x8c98:16), 0x10
	jr nz, AccPlay_SetIndicatorAndRet
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	bit 2, (0x7e79:16)
	jr z, .Lc_f71b3c
	call AccSeq_PostEvent9E_Enable
AccPlay_PostEvent9E_Enable:
.Lc_f71b3c:
	xor WA,WA
	ldb A, 0x01
	call UI_PostPartChangeEvent
	bit 2, (0x7e79:16)
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
	.byte 0xc1, 0x79, 0x7e, 0x3e, 0x01	; ordi8 0x7f15, 1 (v7 patched)

	ld xhl, 0x1e880a

	andmi8 (xhl), 0xfe

	ld xwa, 0x22

	.byte 0x1d, 0xfc, 0x71, 0xfc	; call CtrlPanel_SetIndicatorLED (v7 addr)

	ret



AccPlay_DispatchSeqStart:
	bit 2, (0x0420:16)
	jr nz, AccPlay_DispatchSeqRet
	call Seq_DispatcherEntry
	or (0x334c:16), 0x01
	or (0x3431:16), 0x80
	call Seq_DispatcherEntry
	ld (0x7e6f:16), 0x02
AccPlay_DispatchSeqRet:
	ret

AccPlay_HandleStopState:
	bit 2, (0x7d83:16)
	jr nz, .Lc_f71b94
	jp AccPlay_PostLoopCleanup
AccPlay_CheckResumeState:
.Lc_f71b94:
	bit 2, (0x7d87:16)
	jr nz, TempoEvt_ProcessLoop
	calr AccPlay_ProcessVoiceBank
	call CountAvailableVoiceSlots
	calr AccPlay_AllocateVoiceSlot
	ld XWA,0x00000022
	call CtrlPanel_SetIndicatorLED
TempoEvt_ProcessLoop:
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	jr nz, TempoEvt_ReadAndClassify
	jp AccPlay_PostLoopCleanup

TempoEvt_ReadAndClassify:
	.byte 0x1d, 0xe9, 0x24, 0xef, 0x1d, 0x04, 0x25, 0xef
	.byte 0xcf, 0x89, 0xc9, 0x88, 0xc8, 0xcc, 0xf0, 0xf1
	.byte 0xb8, 0x7d, 0x41, 0xf1, 0xb9, 0x7d, 0x40, 0xf1
	.byte 0x7a, 0x7e, 0xcf, 0x66, 0x56, 0xc9, 0xcf, 0x81
	.byte 0x6e, 0x20, 0xc1, 0x7a, 0x7e, 0x21, 0xc9, 0x88
	.byte 0xc9, 0xcc, 0x1f, 0xc8, 0xcc, 0xe0, 0xc9, 0x69
	.byte 0xc9, 0xe0, 0xc9, 0xd8, 0x6e, 0x06, 0xc8, 0xcc
	.byte 0x7f, 0x1e, 0x28, 0x02
TempoEvt_StoreBankParam:
	ld	(32378:16), w
	jr	42
TempoEvt_CheckHighBit:
	.byte 0xc9, 0x33, 0x07, 0x66, 0x25, 0xc1, 0x7a, 0x7e
	.byte 0x21, 0xc9, 0xcc, 0x1f, 0xc9, 0xd9, 0x6e, 0x1a
	.byte 0x1d, 0x04, 0x25, 0xef, 0xcf, 0x89, 0xc9, 0xcf
	.byte 0x48, 0x67, 0x0f, 0xc1, 0x79, 0x7e, 0x3e, 0x10
	.byte 0xc1, 0xb8, 0x7d, 0x21, 0xc1, 0xb9, 0x7d, 0x20
	.byte 0x68, 0x07
TempoEvt_ContinueProcessing:
	calr TempoRingBuf_ReadLoop
	jp TempoEvt_ProcessLoop

TempoEvt_DispatchEvent:
	cpw	(32124:16), 0
	jr	nz, 5
	calr	2779
	jr	73
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
	.byte 0xf1, 0x79, 0x7e, 0xc8, 0x66, 0x1d, 0xf1, 0x20
	.byte 0x04, 0xca, 0x6e, 0x17, 0x1d, 0xdd, 0x2e, 0xf5
	.byte 0xc1, 0x4c, 0x33, 0x3c, 0xfe, 0xc1, 0x31, 0x34
	.byte 0x3e, 0x80, 0x1d, 0xdd, 0x2e, 0xf5, 0xc1, 0x79
	.byte 0x7e, 0x3c, 0xfe
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
	ld	a, (32376:16)
	cp	a, 12
	jr	c, 2
	ldb	a, 0
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
	.byte 0x1e, 0x14, 0x09, 0x9c, 0x03, 0x23, 0xbc, 0x01
	.byte 0x02, 0xff, 0xff, 0xbc, 0x03, 0x02, 0xff, 0xff
	.byte 0x84, 0x3c, 0x7f, 0xd1, 0x7c, 0x7d, 0x61, 0xdb
	.byte 0xcf, 0xff, 0xff, 0x66, 0x02, 0x68, 0xe1
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
	ldb A, 0x17
	ld (0x8c9e:16), a
	ldb E, 0x90
	ldb D, 0x10
	ldb A, 0x17
	ldb W, 0xff
	call SysEx_ApplyVoiceParam_49
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	cp WA,0x01ff
	jr nz, AccPlay_SetupJumpTarget
	lds wa, 0
	ld (0xfd62:16), a
	ld (0xfd63:16), w
	ldb E, 0x17
	ldb D, 0x01
	ldb A, 0x00
	ldb W, 0x7f
	call SysEx_ApplyVoiceParam_49
	ldb E, 0x17
	ldb D, 0x00
	ldb A, 0x00
	ldb W, 0xff
	call SysEx_ApplyVoiceParam_49
	ldb H, 0x00
	ldb L, 0x00
	ld (0x905b:16), 0x17
	call PartCtrl_WriteProgramChange
	ld XBC,0x0000ff7e
	st_rr8b	h, xbc, l
AccPlay_SetupJumpTarget:
	jp AccPlay_SyncParamsRet
AccPlay_SyncVoiceParams:
	ld	xiy, 63926
	ld	xix, 64866
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
	call	16624672
	pop	xbc
	pop	xix
	pop	xiy
	inc	1, iy
	inc	1, ix
	dec	1, c
	cps	c, 0
	jr	nz, -38
AccPlay_SyncParamsRet:
	ret

AccPlay_AllocateVoiceSlot:
	calr Voice_GetBankEntryPointer
	push XIY
	calr Voice_FindFreeSlot
	ld HL,WA
	calr Util_ExtractAndShiftBits
	.byte 0x84, 0x3e, 0x80, 0xd1, 0x7c, 0x7d, 0x69, 0x5d
	.byte 0xbd, 0x03, 0x50, 0x27, 0x01, 0x8d, 0x00, 0xef
	.byte 0xf1, 0x74, 0x7e, 0x50, 0xd8, 0xae, 0xf1, 0x76
	.byte 0x7e, 0x50, 0xc1, 0x62, 0xfd, 0x21, 0xc1, 0x63
	.byte 0xfd, 0x20, 0xbd, 0x09, 0x50, 0xc9, 0xd1, 0xc1
	.byte 0x66, 0xfd, 0x20, 0xc8, 0x33, 0x06, 0x66, 0x03
	.byte 0xc9, 0xce, 0x01
AccPlay_CheckReverbFlag:
	ld (xiy + 13), a
	xor a, a
	ld w, (0xfd66:16)
	bit 3, w
	jr z, AccPlay_CheckChorusFlag
	or a, 0x1

AccPlay_CheckChorusFlag:
	ld (xiy + 14), a
	ld a, (0xfd6a:16)
	and a, 0x7f
	ld (xiy + 12), a
	ret

AccPlay_UpdateBankParams:
	push xiy
	push xhl
	push xwa
	calr Voice_GetBankEntryPointer
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	ld (xiy + 9), wa
	xor a, a
	ld w, (0xfd66:16)
	bit 6, w
	jr z, AccPlay_UpdateReverbParam
	or a, 0x1

AccPlay_UpdateReverbParam:
	ld (xiy + 13), a
	xor a, a
	ld w, (0xfd66:16)
	bit 3, w
	jr z, AccPlay_UpdateChorusParam
	or a, 0x1

AccPlay_UpdateChorusParam:
	ld (xiy + 14), a
	ld a, (0xfd6a:16)
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
	ld hl, (32372:16)

	calr 1938

	ldb a, 0x83

	ld hl, (32374:16)

	stb_dri A, 0x07, 0xf0, 0xec

	ret



AccPlay_ProcessNoteEvent:
	lds	bc, 5
	calr	1983
	ld	a, (32413:16)
	cps	a, 0
	jr	z, 5
	calr	6
	jr	3
AccPlay_NoteNoSlotMatch:
	calr AccPlay_FindSlotByChannel

AccPlay_NoteEventRet:
	ret

AccPlay_NoteWithSlot:
	cpw (0x7d7c:16), 0x0000
	jr z, AccPlay_NoteNoSlotAvail
	calr AccPlay_FindActiveSlot
	cp XHL,0x0000ffff
	jr nz, AccPlay_NoteAllocAndWrite
AccPlay_NoteNoSlotAvail:
	jp AccPlay_NoteAllocRet

AccPlay_NoteAllocAndWrite:
	.byte 0x3b, 0x3c, 0xc1, 0x9c, 0x7e, 0x27, 0xce, 0xd6
	.byte 0x44, 0x42, 0x61, 0xe4, 0x00, 0xc3, 0x07, 0xf0
	.byte 0xec, 0x21, 0xc8, 0xd0, 0xd8, 0xec, 0x02, 0xd8
	.byte 0x8b, 0x44, 0x64, 0x1f, 0xf7, 0x00, 0xc3, 0x07
	.byte 0xf0, 0xec, 0x21, 0xf1, 0xb8, 0x7d, 0x41, 0xdb
	.byte 0x61, 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xf1, 0xb9
	.byte 0x7d, 0x41, 0xdb, 0x61, 0xc3, 0x07, 0xf0, 0xec
	.byte 0x21, 0xf1, 0xba, 0x7d, 0x41, 0x21, 0x90, 0xc1
	.byte 0xb8, 0x7d, 0x3f, 0x00, 0x66, 0x02, 0x21, 0x91
AccPlay_NoteSetType91:
	.byte 0x1e, 0x0b, 0x08, 0x1e, 0xa2, 0x07, 0xc1, 0x9b
	.byte 0x7e, 0x21, 0x1e, 0x01, 0x08, 0x1e, 0x98, 0x07
	.byte 0xc1, 0x9c, 0x7e, 0x21, 0x1e, 0xf7, 0x07, 0x5c
	.byte 0x5b, 0xc1, 0x9c, 0x7e, 0x21, 0xc9, 0xce, 0x80
	.byte 0xb3, 0x41, 0x21, 0x00, 0xbb, 0x01, 0x41, 0xc1
	.byte 0x9b, 0x7e, 0x21, 0xbb, 0x02, 0x41, 0xd1, 0x74
	.byte 0x7e, 0x20, 0xbb, 0x03, 0x50, 0xd1, 0x76, 0x7e
	.byte 0x20, 0xbb, 0x05, 0x41, 0x1e, 0x69, 0x07, 0xc1
	.byte 0x9d, 0x7e, 0x21, 0x1e, 0xc8, 0x07, 0x1e, 0x5f
	.byte 0x07, 0x21, 0x10, 0x1e, 0xc0, 0x07, 0x1e, 0x57
	.byte 0x07, 0x21, 0x00, 0x1e, 0xb8, 0x07, 0x1e, 0x4f
	.byte 0x07, 0xc1, 0xb8, 0x7d, 0x3f, 0x00, 0x66, 0x14
	.byte 0xc1, 0xb9, 0x7d, 0x21, 0x1e, 0xa7, 0x07, 0x1e
	.byte 0x3e, 0x07, 0xc1, 0xba, 0x7d, 0x21, 0x1e, 0x9d
	.byte 0x07, 0x1e, 0x34, 0x07
AccPlay_NoteAllocRet:
	ret

AccPlay_NoteParamTable:
	.zero 8
	nop
	nop
	nop
	nop
	normal
	nop
	scf
	nop
	normal
	nop
	scf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	normal
	pop sr
	nop
	nop
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x11, 0x11, 0x00

AccPlay_FindActiveSlot:
	ld	xhl, 32223
AccPlay_ScanActiveLoop:
	ld	a, (xhl)
	bit	7, a
	jr	z, 21
	add	xhl, 9
	cp	xhl, 32367
	jr	z, 2
	jr	-23
AccPlay_ScanActiveFail:
	ld xhl, 0xffff

AccPlay_ScanActiveRet:
	ret

AccPlay_FindSlotByChannel:
	ld	w, (32412:16)
	ld	xhl, 32223
AccPlay_ChannelScanLoop:
	ld	a, (xhl)
	and	a, 127
	cp	a, w
	jr	z, 16
	add	hl, 9
	cp	xhl, 32367
	jr	z, 2
	jr	-23
AccPlay_ChannelScanFail:
	jr AccPlay_NoteReleaseRet

AccPlay_ChannelSlotFound:
	ldb	a, 0
	ld	(xhl), a
	ld	d, (xhl+1)
	ld	a, (xhl+2)
	ld	c, (32411:16)
	cp	c, a
	jr	nc, 9
	add	c, 96
	cps	d, 0
	jr	z, 2
	dec	1, d
AccPlay_CalcNoteOffset:
	sub c, a
	ld e, c
	cps d, 0
	jr nz, AccPlay_WriteNoteRelease
	cps e, 2
	jr nc, AccPlay_WriteNoteRelease
	ldb e, 0x2

AccPlay_WriteNoteRelease:
	ld	wa, (32372:16)
	pushw	wa
	ld	wa, (32374:16)
	pushw	wa
	ld	wa, (xhl+3)
	ld	(32372:16), wa
	ld	a, (xhl+5)
	xor	w, w
	ld	(32374:16), wa
	pushw	de
	calr	1717
	calr	1714
	popw	de
	ld	a, e
	and	a, 127
	pushw	de
	calr	1745
	calr	1701
	popw	de
	ld	a, d
	and	a, 127
	calr	1733
	popw	wa
	ld	(32374:16), wa
	popw	wa
	ld	(32372:16), wa
AccPlay_NoteReleaseRet:
	ret

AccPlay_HandleEndMarkerEvt:
	lds	bc, 1
	calr	1526
	lds	de, 1
	calr	1560
	ld	xhl, 32223
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
	add	xhl, 9
	cp	xhl, 32367
	jr	nz, -34
	ret
MidiSeq_ProcessSustainEvent:
	lds	bc, 4
	calr	1476
	ld	xhl, 32410
	ld	a, (xhl)
	cp	a, 211
	jr	nz, 4
	ldb	a, 213
	ld	(xhl), a
MidiSeq_SustainFixup:
	lds de, 3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleD2Event:
	lds	bc, 5
	calr	1449
	ld	xhl, 32410
	ld	a, (xhl+3)
	ld	(xhl+2), a
	lds	de, 3
	calr	1472
	ret
MidiSeq_HandleProgChange:
	lds	bc, 7
	calr	1427
	ld	xhl, 32410
	ld	a, (xhl+4)
	ld	(xhl+2), a
	ld	a, (xhl+5)
	ld	(xhl+4), a
	ld	a, (xhl)
	and	a, 1
	ld	(xhl+3), a
	ld	a, (xhl)
	and	a, 240
	ld	(xhl), a
	xor	w, w
	ld	a, (64870:16)
	bit	6, a
	jr	z, 3
	or	w, 1
MidiSeq_ProgChangeSetReverb:
	ld (xhl + 5), w
	lds de, 6
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleCtrlChange:
	lds	bc, 7
	calr	1367
	ld	xhl, 32410
	ld	a, (xhl+2)
	ld	w, (xhl)
	bit	2, w
	jr	z, 3
	or	a, 128
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
	ld	a, (1076:16)
	ld	w, (32408:16)
	cp	a, w
	jr	z, 45
	ld	hl, (32370:16)
	inc	1, hl
	cps	hl, 0
	jr	nz, 2
	inc	1, hl
AccPlay_MeasureIncrement:
	ld	(32370:16), hl
	cp	(35996:16), 201
	jr	nz, 18
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16161043
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
AccPlay_MeasureNotifyDone:
	ld	(32408:16), a
AccPlay_MeasureTrackRet:
	ret

AccPlay_TrackVoiceCount:
	ld wa, (0x7d7c:16)
	ld hl, (0x7d7e:16)
	cp WA,HL
	jr z, AccPlay_VoiceCountRet
	cp (0x8c9c:16), 0xc9
	jr nz, AccPlay_VoiceCountNotify
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call AccSeq_DeliverC9_000A
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
AccPlay_VoiceCountNotify:
	ld	(32126:16), wa
AccPlay_VoiceCountRet:
	ret

AccPlay_MonitorParamState:
	cp	(32367:16), 0
	jr	z, 15
	cp	(32368:16), 0
	jr	z, 5
	calr	34
	jr	3
AccPlay_InitVoiceBankState:
	calr AccPlay_RestoreVoiceBank

AccPlay_SaveCurrentState:
	ld	a, (64866:16)
	ld	w, (64867:16)
	and	w, 127
	ld	(32380:16), wa
	ld	a, (64870:16)
	and	a, 72
	xor	w, w
	ld	(32382:16), wa
	ret
AccPlay_CompareAndSendProg:
	ld	hl, (32380:16)
	ld	a, (64866:16)
	ld	w, (64867:16)
	and	w, 127
	cp	wa, hl
	jr	z, 28
	ld	e, w
	ld	w, a
	ldb	a, 193
	ld	(32164:16), w
	and	e, 15
	bit	7, w
	jr	z, 6
	or	e, 16
	and	w, 127
AccPlay_SendProgChange:
	call AccompSeq_SendMidiEvent

AccPlay_CompareReverbState:
	ld	hl, (32382:16)
	ld	a, (64870:16)
	and	a, 64
	xor	w, w
	and	l, 64
	cp	wa, hl
	jr	z, 16
	ldb	e, 0
	cps	a, 0
	jr	z, 2
	ldb	e, 127
AccPlay_SetReverbValue:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_CompareChorusState:
	jr	36
	ld	hl, (32382:16)
	ld	a, (64870:16)
	and	a, 8
	xor	w, w
	and	l, 8
	cp	wa, hl
	jr	z, 16
	ldb	e, 0
	cps	a, 0
	jr	z, 2
	ldb	e, 127
AccPlay_SetChorusValue:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent

AccPlay_ParamMonitorRet:
	ret

AccPlay_RestoreVoiceBank:
	calr	64068
	ld	wa, (xiy+9)
	ld	e, w
	ld	w, a
	ldb	a, 193
	ld	(32164:16), w
	and	e, 15
	bit	7, w
	jr	z, 6
	or	e, 16
	and	w, 127
AccPlay_SendBankProgram:
	call	16179773
	ld	wa, (xiy+9)
	ld	(64866:16), a
	ld	(64867:16), w
	ldb	e, 23
	ldb	d, 1
	ld	a, w
	ldb	w, 127
	call	16624672
	ld	wa, (xiy+9)
	ldb	e, 23
	ldb	d, 0
	ldb	w, 255
	call	16624672
	ld	a, (xiy+12)
	ld	e, a
	ldb	w, 4
	ldb	a, 209
	call	16179773
	ld	a, (xiy+12)
	ld	(64874:16), a
	ldb	e, 23
	ldb	d, 8
	ldb	w, 127
	call	16624672
	ld	a, (xiy+13)
	ldb	e, 0
	bit	0, a
	jr	z, 2
	ldb	e, 127
AccPlay_RestoreReverbVal:
	ldb w, 0x7
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 13)
	ld w, (0xfd66:16)
	and w, 0xbf
	bit 0, a
	jr z, AccPlay_WriteReverbFlag
	or w, 0x40

AccPlay_WriteReverbFlag:
	ld	(64870:16), w
	ldb	e, 23
	ldb	d, 4
	ld	a, w
	ldb	w, 64
	call	16624672
	ld	a, (xiy+14)
	ldb	e, 0
	bit	0, a
	jr	z, 2
	ldb	e, 127
AccPlay_RestoreChorusVal:
	ldb w, 0x3
	ldb a, 0xd1
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 14)
	ld w, (0xfd66:16)
	and w, 0xf7
	bit 0, a
	jr z, AccPlay_WriteChorusFlag
	or w, 0x8

AccPlay_WriteChorusFlag:
	ld	(64870:16), w
	ldb	e, 23
	ldb	d, 4
	ld	a, w
	ldb	w, 8
	call	16624672
	ret
AccPlay_ClearSlotTable:
	ld	xhl, 32223
	ldb	a, 0
AccPlay_ClearSlotLoop:
	ld	(xhl), a
	add	xhl, 9
	cp	xhl, 32367
	jr	z, 2
	jr	-18
AccPlay_ClearSlotDone:
	ret

AccPlay_SaveMuteStates:
	ld	a, (63939:16)
	ld	w, (63965:16)
	ld	(32384:16), wa
	ld	a, (63991:16)
	ld	w, (64017:16)
	ld	(32386:16), wa
	ld	a, (64043:16)
	ld	w, (64069:16)
	ld	(32388:16), wa
	ld	a, (64095:16)
	ld	w, (64121:16)
	ld	(32390:16), wa
	ld	a, (64147:16)
	ld	w, (64173:16)
	ld	(32392:16), wa
	ld	a, (64199:16)
	ld	w, (64225:16)
	ld	(32394:16), wa
	ld	a, (64251:16)
	ld	w, (64277:16)
	ld	(32396:16), wa
	ld	a, (64303:16)
	ld	w, (64329:16)
	ld	(32398:16), wa
	ld	a, (64355:16)
	ld	w, (64381:16)
	ld	(32400:16), wa
	ld	a, (64407:16)
	ld	w, (64433:16)
	ld	(32402:16), wa
	ld	a, (64459:16)
	ld	w, (64485:16)
	ld	(32404:16), wa
	ld	a, (64511:16)
	ld	w, (64537:16)
	ld	(32406:16), wa
	ldb	a, 192
	orddm8	(63939), a
	orddm8	(63965), a
	orddm8	(63991), a
	orddm8	(64017), a
	orddm8	(64043), a
	orddm8	(64069), a
	orddm8	(64095), a
	orddm8	(64121), a
	orddm8	(64147), a
	orddm8	(64173), a
	orddm8	(64199), a
	orddm8	(64225), a
	orddm8	(64251), a
	orddm8	(64277), a
	orddm8	(64303), a
	orddm8	(64329), a
	orddm8	(64355), a
	orddm8	(64381), a
	orddm8	(64407), a
	orddm8	(64433), a
	orddm8	(64459), a
	orddm8	(64485), a
	orddm8	(64511), a
	orddm8	(64537), a
	ld	a, (64879:16)
	and	a, 63
	and	a, 240
	ld	(64879:16), a
	ldb	e, 23
	ldb	d, 13
	ldb	w, 207
	call	16624672
	calr	1
	ret
AccompSeq_QueueAllMutes:
	ldb e, 0x0
	ld a, (0xf9c3:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x1
	ld a, (0xf9dd:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x2
	ld a, (0xf9f7:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x3
	ld a, (0xfa11:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x4
	ld a, (0xfa2b:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x5
	ld a, (0xfa45:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x6
	ld a, (0xfa5f:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x7
	ld a, (0xfa79:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x8
	ld a, (0xfa93:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x9
	ld a, (0xfaad:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xa
	ld a, (0xfac7:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xb
	ld a, (0xfae1:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xc
	ld a, (0xfafb:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xd
	ld a, (0xfb15:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xe
	ld a, (0xfb2f:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0xf
	ld a, (0xfb49:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x10
	ld a, (0xfb63:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x11
	ld a, (0xfb7d:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x12
	ld a, (0xfb97:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x13
	ld a, (0xfbb1:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x14
	ld a, (0xfbcb:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x15
	ld a, (0xfbe5:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x16
	ld a, (0xfbff:16)
	calr AccompSeq_QueueMuteEvent
	ldb e, 0x19
	ld a, (0xfc19:16)
	calr AccompSeq_QueueMuteEvent
	ret

AccompSeq_QueueMuteEvent:
	ldb	d, 13
	ldb	w, 207
	call	16624672
	ret
AccPlay_RestoreMuteStates:
	ld	wa, (32384:16)
	ld	(63939:16), a
	ld	(63965:16), w
	ld	wa, (32386:16)
	ld	(63991:16), a
	ld	(64017:16), w
	ld	wa, (32388:16)
	ld	(64043:16), a
	ld	(64069:16), w
	ld	wa, (32390:16)
	ld	(64095:16), a
	ld	(64121:16), w
	ld	wa, (32392:16)
	ld	(64147:16), a
	ld	(64173:16), w
	ld	wa, (32394:16)
	ld	(64199:16), a
	ld	(64225:16), w
	ld	wa, (32396:16)
	ld	(64251:16), a
	ld	(64277:16), w
	ld	wa, (32398:16)
	ld	(64303:16), a
	ld	(64329:16), w
	ld	wa, (32400:16)
	ld	(64355:16), a
	ld	(64381:16), w
	ld	wa, (32402:16)
	ld	(64407:16), a
	ld	(64433:16), w
	ld	wa, (32404:16)
	ld	(64459:16), a
	ld	(64485:16), w
	ld	wa, (32406:16)
	ld	(64511:16), a
	ld	(64537:16), w
	ld	a, (64879:16)
	or	a, 192
	ld	(64879:16), a
	ldb	e, 23
	ldb	d, 13
	ldb	w, 79
	call	16624672
	calr	65142
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
	.byte 0x1e, 0xf4, 0xff, 0x43, 0x9a, 0x7e, 0x00, 0x00
	.byte 0xf3, 0x07, 0xec, 0xf0, 0x41, 0xdc, 0x61, 0xd9
	.byte 0x69, 0xd9, 0xd8, 0x6e, 0xeb, 0xf1, 0x79, 0x7e
	.byte 0xcc, 0x66, 0x09, 0xc1, 0x79, 0x7e, 0x3c, 0xef
	.byte 0xbb, 0x01, 0x00, 0x00
MidiSeqBuf_ScanDone:
	ret

MidiSeqBuf_ProcessEntries:
	cpw (0x7d7c:16), 0x0000
	jr z, MidiSeqBuf_ProcessDone
	xor IX,IX
MidiSeqBuf_ProcessLoop:
.Lc_f7266f:
	ld XHL,0x00007e9a
	.byte 0xc3, 0x07, 0xec, 0xf0, 0x21, 0x3c, 0x2a, 0xd1
	.byte 0x74, 0x7e, 0x23, 0x1e, 0x7e, 0xff, 0xd1, 0x76
	.byte 0x7e, 0x23, 0xf3, 0x07, 0xf0, 0xec, 0x41, 0x1e
	.byte 0x09, 0x00, 0x4a, 0x5c, 0xdc, 0x61, 0xda, 0xf4
	.byte 0x67, 0xd9
MidiSeqBuf_ProcessDone:
	ret

MidiSeqBuf_AdvancePosition:
	.byte 0xd1, 0x76, 0x7e, 0x20, 0xd8, 0x61, 0xd8, 0xcf
	.byte 0xff, 0x00, 0x6e, 0x2c, 0x3c, 0x3a, 0x3b, 0x1e
	.byte 0x6b, 0xff, 0xdc, 0xd4, 0xd1, 0x74, 0x7e, 0x23
	.byte 0xdb, 0x8a, 0x1e, 0x4c, 0xff, 0xbc, 0x03, 0x50
	.byte 0xf1, 0x74, 0x7e, 0x50, 0xd8, 0x8b, 0x1e, 0x40
	.byte 0xff, 0xbc, 0x01, 0x52, 0x84, 0x3e, 0x80, 0xd1
	.byte 0x7c, 0x7d, 0x69, 0xd8, 0xae, 0x5b, 0x5a, 0x5c
MidiSeqBuf_AdvanceDone:
	ld	(32374:16), wa
	ret
MidiSeqBuf_AdvanceWritePos:
	ld	wa, (32374:16)
	inc	1, wa
	cp	wa, 255
	jr	nz, 24
	push	xix
	push	xde
	push	xhl
	ld	hl, (32372:16)
	ld	de, hl
	calr	65300
	ld	wa, (xix+3)
	ld	(32372:16), wa
	lds	wa, 6
	pop	xhl
	pop	xde
	pop	xix
MidiSeqBuf_WriteAdvDone:
	ld	(32374:16), wa
	ret
MidiSeqBuf_WriteByte:
	push xix

	push xhl

	ld hl, (32372:16)

	calr 65274

	ld hl, (32374:16)

	stb_dri A, 0x07, 0xf0, 0xec

	pop xhl

	pop xix

	ret



AccPlay_InitAndStartLoop:
	ld (0x7e6f:16), 0x00
	call TempoRingBuf_ReInitAndRet
	or (0x7e79:16), 0x04

	ldb a, 0x8

	call 16692690

	calr 62419

	ret



AccPlay_ToggleCodeFragment:
	cp (0x7e6f:16), 0x00
	jr z, .Lc_f7273d
	ld (0x7e6f:16), 0x00
	call TempoRingBuf_ReInitAndRet
	calr AccPlay_MainUpdateLoop
.Lc_f7273d:
	ret
AccPlay_CheckAndToggle:
	bit 1, (0x7e6f:16)
	jr z, AccPlay_ToggleRet
	bit 2, (0x041f:16)
	jr nz, AccPlay_ToggleRestart
	call AccWrap_PlayModeStartAccPlay
	lds wa, 0
	ei 0x06
	ld (0x046a:16), a
	ld (0x0468:16), wa
	ld (0x041f:16), 0x01
	ei 0x00
	jr t, AccPlay_ToggleRet
AccPlay_ToggleRestart:
	ld	(32367:16), 0
	call	16125820
	calr	62349
AccPlay_ToggleRet:
	ret

AccPlay_StopAndReset:
	bit 2, (1056:16)
	jr nz, AccPlay_StopResetRet
	lds wa, 0
	ld (1047:16), a
	ld (1048:16), wa
	ld (1045:16), a
	ld (1046:16), a
	ld (1076:16), a
	ld (1077:16), a
	ld (1130:16), a
	ld (1128:16), wa
	ld (1056:16), 1
	ld (1054:16), 1
	ld (1055:16), 1

AccPlay_StopResetRet:
	ret

InitializeEast:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,0x01600004
	ld (XBC),XWA
	lda xwa, (ClassProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe55cd4:24)
	ld (XBC+0x08),WA
	lda xwa, (0xe559ea:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0163
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000c
	ld (XBC),XWA
	lda xwa, (ResEventProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe55cda:24)
	ld (XBC+0x08),WA
	lda xwa, (0xe55cd6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000d
	ld (XBC),XWA
	lda xwa, (ResMethodProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe55dac:24)
	ld (XBC+0x08),WA
	lda xwa, (0xe55cdc:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003c
	lda xwa, (0xe55210:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0123
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003c
	lda xwa, (0xe55304:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0423
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (0xe55dae:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0103
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (MidiMenu_NakaProcName_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0403
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5ad8c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0143
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5adac:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0443
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe59c5a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0009
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe5a122:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0309
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe59c6e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x000f
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe5a152:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x030f
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59c7e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0018
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a17a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0318
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59cb2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0019
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a1d4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0319
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59ce6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x001a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a23a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x031a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe59d1a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0050
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe5a2a8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0350
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe59d6e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0051
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5a350:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0351
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe59d8e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0052
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (NakaData_WidgetTables2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0352
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59db2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0053
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a3f2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0353
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (0xe59dce:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0054
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (NakaObj_MidiCommonSetting_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0354
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (0xe59de6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0055
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (NakaObj_MidiInOutSetting_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0355
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda xwa, (0xe59dfe:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0056
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda xwa, (NakaObj_MidiPresets_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0356
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda xwa, (0xe59f0e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0057
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda xwa, (0xe5a77c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0357
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xe59f82:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0058
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xe5a906:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0358
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59fda:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0059
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a9ae:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0359
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59ff6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (NakaObj_MidiComputerConn_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda xwa, (0xe5a012:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda xwa, (NakaObj_MidiPmemOutput_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5a05a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5aac6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe5a07e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe5ab12:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5a0e2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5ac06:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a106:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ec
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5ac5a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ec
	call RegisterObjectTable
	pushw 0x0003
	pushw 0x00e5
	pushw 0xac90
	.byte 0xe8, 0xad, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x50, 0x00, 0xa0, 0x01, 0x1d, 0x1e, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x98
	.byte 0xac, 0x40, 0x09, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x09, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0xa6, 0xac, 0x40, 0x0f, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x0f, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0xb0
	.byte 0xac, 0x40, 0x18, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x18, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0xbe, 0xac, 0x40, 0x19, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x19, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0xca
	.byte 0xac, 0x40, 0x1a, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x1a, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0xda, 0xac, 0x40, 0x50, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x50, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0xe4
	.byte 0xac, 0x40, 0x51, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x51, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0xee, 0xac, 0x40, 0x52, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x52, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0xf8
	.byte 0xac, 0x40, 0x53, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x53, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x02, 0xad, 0x40, 0x54, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x54, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x0c
	.byte 0xad, 0x40, 0x55, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x55, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x18, 0xad, 0x40, 0x56, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x56, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x24
	.byte 0xad, 0x40, 0x57, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x57, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x2e, 0xad, 0x40, 0x58, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x58, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x3a
	.byte 0xad, 0x40, 0x59, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x59, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x46, 0xad, 0x40, 0x5a, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x5a, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x50
	.byte 0xad, 0x40, 0x5b, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x5b, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x5c, 0xad, 0x40, 0x5c, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x5c, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x68
	.byte 0xad, 0x40, 0xd7, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0xd7, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x03, 0x00, 0x0b
	.byte 0xe5, 0x00, 0x0b, 0x74, 0xad, 0x40, 0xd8, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0xd8, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x03, 0x00, 0x0b, 0xe5, 0x00, 0x0b, 0x80
	.byte 0xad, 0x40, 0xec, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0xec, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0xbf, 0x0e, 0x37, 0x0e
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
	lda xhl, (Bitmap_Bmphk:24)
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
	lda xix, (AcVocalGrid_DialSetup:24)
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
	lda xbc, (MidiPart_PageStr_1of3_0x12:24)
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
	lda xbc, (MidiPart_PageStr_1of3_0x2A:24)
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
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	36
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	15
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
	lda xwa, (MidiPart_OctaveStr_m2_0x4:24)
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
	lda xix, (VocalistGrid_DispatchData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
VocalistGrid_DispatchData:
	call	16400579
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16421459
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	.byte 0x93, 0x3f, 0x01, 0x00
	jr	z, 7
	.byte 0x93, 0x3f, 0x02, 0x00
	jrl	nz, 1604
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda	xde, (15199840:24)
	ld_rrl	xwa, xde, ix
	cp	xwa, 4294967295
	jrl	z, 1571
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	lds	bc, 1
	lds	de, 2
	jr	102
	call	16400579
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	16421459
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	.byte 0x93, 0x3f, 0x01, 0x00
	jr	z, 7
	.byte 0x93, 0x3f, 0x02, 0x00
	jrl	nz, 1501
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda	xde, (15199840:24)
	ld_rrl	xwa, xde, ix
	cp	xwa, 4294967295
	jrl	z, 1468
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	ldw	bc, 65535
	lds	de, 2
	call	16381237
	jrl	1442
	ld	(xsp+4), xbc
	ld	xhl, xiy
	ldw	(xiy), 0
	ld	xix, (xsp+8)
	ld	xiz, xde
	ld	xiy, xde
	jr	50
	ld	qbc, bc
	.byte 0xd7, 0xe6, 0xec, 0x03
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0
	jr	nz, 4
	lds	bc, 1
	jr	19
	ld	wa, qbc
	inc	4, wa
	ld	qbc, wa
	ld	xwa, (xiy)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0
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
	sub	xwa, 11520
	cp	xwa, 0
	jrl	c, 1331
	cp	xwa, 19
	jrl	ugt, 1322
	add	xwa, xwa
	add	xwa, 15200368
	ld	wa, (xwa)
	lda	xix, (16201364:24)
	jp_rr 8, xix, wa
	ld	wa, (xbc)
	cp	wa, 16
	jr	z, 13
	cp	wa, 17
	jr	nz, 25
	ld	xwa, 15199968
	jr	5
	ld	xwa, 15199980
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	20
	inc	1, wa
	pushw	wa
	pushw 231
	pushw 61176
	ld	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	1222
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	.byte 0x0b, 0xe7, 0x00, 0x0b, 0x04, 0xef
	ld	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	1183
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw 231
	pushw 61200
	ld	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	1144
	ld	wa, (xbc)
	sla	wa, 2
	lda	xbc, (15199646:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw 231
	pushw 61212
	ld	xwa, (xsp+16)
	push	xwa
	call	16712341
	lda	xsp, (xsp+12)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	1094
	ld	wa, (xbc)
	cps	wa, 3
	jr	z, 33
	cps	wa, 2
	jr	z, 22
	cps	wa, 1
	jr	z, 11
	cps	wa, 0
	jr	nz, 37
	ld	xwa, 15200040
	jr	19
	ld	xwa, 15200052
	jr	12
	ld	xwa, 15200064
	jr	5
	ld	xwa, 15200076
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	1022
	ld	wa, (xbc)
	cp	wa, 120
	jr	z, 13
	cp	wa, 121
	jr	nz, 25
	ld	xwa, 15200088
	jr	5
	ld	xwa, 15200100
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	18
	pushw	wa
	pushw 231
	pushw 61296
	ld	xwa, (xsp+14)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	948
	ld	bc, (xbc)
	ld	de, bc
	and	de, 127
	ld	wa, de
	exts	xwa
	divs	wa, 12
	sla	wa, 2
	lda	xhl, (15199752:24)
	ld_rrl	xwa, xhl, wa
	push	xwa
	exts	xde
	divs	de, 12
	ld	wa, qde
	sla	wa, 2
	lda	xde, (15199646:24)
	ld_rrl	xwa, xde, wa
	push	xwa
	and	bc, 128
	sra	bc, 7
	sla	bc, 2
	lda	xwa, (15199626:24)
	ld_rrl	xwa, xwa, bc
	push	xwa
	pushw 231
	pushw 61308
	ld	xwa, (xsp+24)
	push	xwa
	call	16712341
	lda	xsp, (xsp+20)
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	840
	ld	xwa, 15200138
	.byte 0x91, 0x3f, 0x00, 0x00
	jr	z, 5
	ld	xwa, 15200132
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	16713584
	inc	8, xsp
	call	16400579
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	796
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
	lda xix, (VocalistGrid_CheckDispData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

VocalistGrid_CheckDispData:
	ld	xwa, 11520
	call	16567398
	cp	hl, 16
	jr	z, 13	; -> 0xF73901
	cp	hl, 17
	jr	nz, 25	; -> 0xF73913
	ld	xwa, 15200144
	jr	5	; -> 0xF73906
	ld	xwa, 15200156
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	29	; -> 0xF73930
	ld	xwa, 11520
	call	16567398
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61352
	lda	xwa, (xsp+26)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	613	; -> 0xF73BA6
	ld	xwa, 11522
	call	16567398
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61364
	lda	xwa, (xsp+26)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	567	; -> 0xF73BA6
	ld	xwa, 11524
	call	16567398
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61376
	lda	xwa, (xsp+26)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	521	; -> 0xF73BA6
	ld	xwa, 11526
	call	16567398
	sla	hl, 2
	lda	xwa, (15199646:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61388
	lda	xwa, (xsp+28)
	push	xwa
	call	16712341
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	464	; -> 0xF73BA6
	ld	xwa, 11528
	call	16567398
	cps	hl, 3
	jr	z, 33	; -> 0xF73A04
	cps	hl, 2
	jr	z, 22	; -> 0xF739FD
	cps	hl, 1
	jr	z, 11	; -> 0xF739F6
	cps	hl, 0
	jr	nz, 37	; -> 0xF73A14
	ld	xwa, 15200216
	jr	19	; -> 0xF73A09
	ld	xwa, 15200228
	jr	12	; -> 0xF73A09
	ld	xwa, 15200240
	jr	5	; -> 0xF73A09
	ld	xwa, 15200252
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	385	; -> 0xF73BA6
	ld	xwa, 11530
	call	16567398
	lda	xbc, (xsp+20)
	cp	hl, 120
	jr	z, 13	; -> 0xF73A44
	cp	hl, 121
	jr	nz, 22	; -> 0xF73A53
	ld	xwa, 15200264
	jr	5	; -> 0xF73A49
	ld	xwa, 15200276
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	27	; -> 0xF73A6E
	ld	xwa, 11530
	call	16567398
	pushw	hl
	pushw	231
	pushw	61472
	lda	xwa, (xsp+26)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	295	; -> 0xF73BA6
	ld	xwa, 11533
	call	16567398
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (15199752:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	ld	xwa, 11533
	call	16567398
	exts	xhl
	divs	hl, 12
	ld	wa, qhl
	sla	wa, 2
	lda	xbc, (15199646:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, 11534
	call	16567398
	sla	hl, 2
	lda	xwa, (15199626:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61484
	lda	xwa, (xsp+36)
	push	xwa
	call	16712341
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jrl	177	; -> 0xF73BA6
	ld	xwa, 11537
	call	16567398
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (15199752:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	ld	xwa, 11537
	call	16567398
	exts	xhl
	divs	hl, 12
	ld	wa, qhl
	sla	wa, 2
	lda	xbc, (15199646:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, 11538
	call	16567398
	sla	hl, 2
	lda	xwa, (15199626:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61492
	lda	xwa, (xsp+36)
	push	xwa
	call	16712341
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jr	60	; -> 0xF73BA6
	ld	xwa, (xsp+4)
	ld	wa, (xwa)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	call	16567398
	ld	xwa, 15200322
	cps	hl, 0
	jr	z, 5	; -> 0xF73B8D
	ld	xwa, 15200316
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
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
	add xhl, MidiPart_ColWidthData_0x36
	ld hl, (xhl)
	lda xix, (AcVocalist_ListDispatch:24)
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
	ld xde, (MidiPart_ColWidthData_0x42:24)
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
	ld xde, (MidiPart_ColWidthData_0x42:24)
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
	lda xix, (MidiPart_HarmLocalStr_0x24:24)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda xix, (VocalistPage1OK_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MainVocalistPage1OKFunc dispatch
VocalistPage1OK_Dispatch:
	call	16602217
	call	16602124
	ld	(46928:16), 11
	call	16600229
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 119808
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 119808
	lds	bc, 0
	lds	de, 2
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	16423243
	ld	(32420:16), 1
	call	16601121
	ld	(32420:16), 0
VocalistPage_Handler:
	lds32 xhl, 0
	inc 4, xsp
	ret

VocalistPage1_DispatchData:
	call	16602217
	call	16602124
	ld	(46928:16), 2
	call	16600229
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 98304
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 98304
	lds	bc, 0
	lds	de, 2
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	jr	-98
	ld	wa, bc
	call	16602217
	call	16602124
	ld	(46928:16), 24
	call	16600229
	ld	xwa, 16897
	lds	bc, 3
	lds	de, 2
	call	16566832
	ld	xwa, (xsp)
	srl	xwa, 0
	ld	qwa, 0
	cps	wa, 0
	jr	z, 11
	ld	xwa, 101376
	lds	bc, 1
	lds	de, 2
	jr	9
	ld	xwa, 101376
	lds	bc, 0
	lds	de, 2
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	jrl	-189
	ld	wa, bc
	call	16602217
	call	16602124
	ld	(46928:16), 1
	call	16600229
	lds	wa, 1
	call	16328715
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	jrl	-237
MainVocalistPage2OKFunc:
	cp	xbc, 31653896
	jr	nz, 28
	call	16601121
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	16423243
VocalistPage2_ReturnZero:
	lds32 xhl, 0
	ret

AccPlay_GetCurrentPart:
	ld	l, (32420:16)
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
	call	16421459
	ld	xwa, 16390
	call	16567398
	exts	xhl
	ld	xwa, 1638411
	ld	xbc, 31457339
	ld	xde, xhl
	jrl	132
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
	call	16421459
	ld	xwa, 16390
	call	16567398
	exts	xhl
	ld	xwa, 1703946
	ld	xbc, 31457339
	ld	xde, xhl
	jrl	132
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
	ld	xwa, (xsp+12)
	call	16408153
	ld	xiz, xhl
	ld	xwa, 192
	call	16567398
	ld	xwa, (xiz+50)
	ld	(xwa), hl
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	call	16400380
	lds32	xhl, 0
AcGMOnOff_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret

StsAttentionCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAttention_ReturnZero
	lda xhl, (GMMode_AttentionTable:24)
	ret

StsAttention_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOnCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOn_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x204:24)
	ret

StsGMOn_ReturnZero:
	lds32 xhl, 0
	ret

StsGMOffCheck:
	cp xbc, 0x1e0009f
	jr nz, StsGMOff_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x47C:24)
	ret

StsGMOff_ReturnZero:
	lds32 xhl, 0
	ret

StsAreYouSureCheck:
	cp xbc, 0x1e0009f
	jr nz, StsAreYouSure_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x494:24)
	ret

StsAreYouSure_ReturnZero:
	lds32 xhl, 0
	ret

GMOKFunc:
	ld l, (0x0340ea:24)
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
	ld	xwa, 5767169
	ld	xbc, 31457387
	lds32	xde, 0
	call	16421459
	ld	xwa, 192
	ld	bc, hl
	lds	de, 1
	call	16381053
	ld	xwa, 4294967295
	ld	xbc, 29360130
	lds32	xde, 0
	call	16421701
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	16421701
	lds32	xhl, 0
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
	lda xhl, (GMMode_Attention_English2_0x514:24)
	ret

StsSplit_ReturnZero:
	lds32 xhl, 0
	ret

SplitPointFunc:
	.byte 0xbf, 0xf4, 0x37, 0x3e, 0xbf, 0x08, 0x62, 0xe9
	.byte 0x8a, 0xbf, 0x0c, 0x60, 0x45, 0x16, 0xf8, 0xe7
	.byte 0x00, 0xbf, 0x04, 0x34, 0x95, 0x10, 0x95, 0x10
	.byte 0xea, 0xcf, 0x3f, 0x00, 0xe0, 0x01, 0x76, 0x4d
	.byte 0x01, 0xea, 0xcf, 0x3e, 0x00, 0xe0, 0x01, 0x76
	.byte 0x44, 0x01, 0xea, 0xcf, 0x41, 0x00, 0xe0, 0x01
	.byte 0x76, 0x3b, 0x01, 0xea, 0xcf, 0x40, 0x00, 0xe0
	.byte 0x01, 0x76, 0x2b, 0x01, 0xea, 0xcf, 0x42, 0x00
	.byte 0xe0, 0x01, 0x76, 0xd0, 0x00, 0xea, 0xcf, 0x02
	.byte 0x00, 0xe3, 0x01, 0x7e, 0xc3, 0x00, 0x40, 0x80
	.byte 0x41, 0x00, 0x00, 0xd9, 0xa8, 0xda, 0xa9, 0x1d
	.byte 0x30, 0xca, 0xfc, 0xaf, 0x08, 0x20, 0xc7, 0xfb
	.byte 0x99, 0xc7, 0xfb, 0xcf, 0x24, 0x67, 0x06, 0xc7
	.byte 0xfb, 0xcf, 0x60, 0x63, 0x04
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
	lda xde, (SplitPoint_NoteEntry_C_Code_0x4:24)
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
	ld	xde, (xsp+8)
	ld	bc, (xde+4)
	ld	wa, bc
	exts	xwa
	divs	wa, 12
	dec	2, wa
	pushw	wa
	exts	xbc
	divs	bc, 12
	ld	wa, qbc
	sla	wa, 2
	lda	xbc, (15202168:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw 231
	pushw 63514
	ld	xwa, (xde+8)
	push	xwa
	call	16712341
	lda	xsp, (xsp+14)
	ld	xwa, (xsp+8)
	ld	de, (xwa+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31653890
	call	16401834
	ld	xhl, (xsp+12)
	jr	9
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

	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xec	; cpdi8 (0x8d38), 236 (v7 patched)

	ret nz

	cp c, 0x15

	ret c

	cp c, 0x6c

	ret ugt

	extz bc

	ld xwa, 0x4181

	lds de, 1

	call	16566832

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
	push	xwa
	push	xbc
	call	16713584
	inc	8, xsp
	ld	xwa, 4294967295
	ld	xbc, 31457400
	lds32	xde, 0
	call	16421459
	ld	xhl, xiz
	jr	16
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
