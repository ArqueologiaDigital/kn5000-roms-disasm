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
	calr	SeqEvt_ProcessReadLoop
	ld	a, (32110:16)
	ld	(32108:16), a
	ld	(32107:16), 2
	ld	a, (32109:16)
	ld	(32110:16), a
	ld	xhl, 31568
	ld	xbc, 32024
	calr	SeqEvt_ProcessReadLoop
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
	calr	SeqEvtBuf_AdvanceReadPos
	ld	w, a
	cp	a, 144
	jr	nz, SeqEvt_CheckType91
	ld	(32114:16), 5
	jr	SeqEvt_ReadAndDispatchEntry
SeqEvt_CheckType91:
	cp	a, 145
	jr	nz, SeqEvt_CheckTypeC0
	ld	(32114:16), 7
	jr	SeqEvt_ReadAndDispatchEntry
SeqEvt_CheckTypeC0:
	and	a, 240
	cp	a, 192
	jr	nz, SeqEvt_CheckTypeD0
	ld	(32114:16), 4
	jr	SeqEvt_ReadAndDispatchEntry
SeqEvt_CheckTypeD0:
	cp	a, 208
	jr	z, SeqEvt_TypeD0_SetCount
	ld	ix, (xhl+4)
	ld	(xhl+6), ix
	ld	(32115:16), ix
	jr	SeqEvt_ProcessLoop_Check
SeqEvt_TypeD0_SetCount:
	ld	(32114:16), 2
SeqEvt_ReadAndDispatchEntry:
	ld_rrb	a, xhl, ix
	ld	(32117:16), ix
	calr	SeqEvtBuf_AdvanceReadPos
	ld	(32115:16), ix
	cp	a, (1132:16)
	jr	ule, SeqEvt_DispatchByChannel
	jp	SeqEvt_ProcessTempoEvent
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
	cp	ix, (0x7d68:16)
	jr	c, SeqEvt_CheckSlotActive
	jr	SeqEvt_AfterSlotScan
SeqEvt_CheckSlotActive:
	bit_dri 7, 0x07, 0xec, 0xf0
	jr z, SeqEvt_AdvanceSlotIndex
	ld xiy, xhl
	and xix, 0xffff
	add xiy, xix
	cp (xiy + 2), w
	jr z, SeqEvt_SlotMatchFound

SeqEvt_AdvanceSlotIndex:
	add	ix, (0x7d66:16)
	jr	SeqEvt_SlotScanLoop
SeqEvt_SlotMatchFound:
	calr SeqEvt_WriteNoteOff

SeqEvt_AfterSlotScan:
	popw wa
	xor ix, ix

SeqEvt_FindFreeSlotLoop:
	cp	ix, (0x7d68:16)
	jr	nc, SeqEvt_AllocateNewSlot
	.byte 0xf3, 0x07, 0xec, 0xf0, 0xcf	; bit 7,(xhl+ix)
	jr	nz, SeqEvt_AdvanceFreeSlotIdx
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	jr	SeqEvt_WriteEventAndContinue
SeqEvt_AdvanceFreeSlotIdx:
	add	ix, (0x7d66:16)
	jr	SeqEvt_FindFreeSlotLoop
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

	or a, (32107:16)

	calr SeqEvtBuf_WriteBytePreserve

	ld a, w

	calr	SeqEvtBuf_WriteBytePreserve

	ld a, 0x0:opc

	calr	SeqEvtBuf_WriteBytePreserve

	ret



SeqEvt_WriteNoteOnRotating:
	push XWA
	xor XWA,XWA
	ld a, (0x7d6e:16)
	ld XIX,SeqEvt_RotationOffsetTable
	add XIX,XWA
	ld IX,(XIX)
	ld_rrb	a, xhl, ix
	.byte 0xc3, 0x07, 0xec, 0xf0, 0x3c, 0x7f	; and (xhl+ix),0x7f
	ld	iz, ix
	inc	2, ix
	ld_rrb	w, xhl, ix
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	and	a, 240
	or	a, (0x7d6b:16)
	calr	SeqEvtBuf_WriteBytePreserve
	ld	a, w
	calr	SeqEvtBuf_WriteBytePreserve
	ld	a, 0:opc
	calr	SeqEvtBuf_WriteBytePreserve
	ld	ix, iz
	pop	xwa
	adddi8	(32110), 2
	ldb_d8	a, (32110)
	cp	a, (0x7d6a:16)
	jr	c, SeqEvt_RotateIndexDone
	stdi8	(32110), 0
SeqEvt_RotateIndexDone:
	ld a, w
	and a, 0xf0
	ret

SeqEvt_WriteVoiceParams:
	or a, (0x7d6b:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld (0x7d77:16), xhl
	ld XHL,XBC
	ld xbc, (0x7d77:16)
	ld A,W
	stb_dri a, 0x07, 0xec, 0xf0
	inc 1,IX
	ld A, 0x00:opc
	stb_dri a, 0x07, 0xec, 0xf0
	inc 1,IX
	ld (0x7d77:16), xhl
	ld XHL,XBC
	ld xbc, (0x7d77:16)
	ex16	iz, ix
	ldw_d16	ix, (32115)
	ld_rrb	a, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
	ex16	iz, ix
	calr	SeqEvtBuf_WriteBytePreserve
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	st_rrb	a, xhl, ix
	inc	1, ix
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
	ex16	iz, ix
	calr	SeqEvtBuf_WriteBytePreserve
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	st_rrb	a, xhl, ix
	inc	1, ix
	stda32	(32119), xhl
	ld	xhl, xbc
	ldda32	xbc, (32119)
	push	xwa
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
	ld_rrb	w, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
	ex16	iz, ix
	add	wa, (0x46e:16)
	cp	a, 96
	jr	c, SeqEvt_AdjustNoteOctave
	inc	1, w
	sub	a, 96
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
	jr	nc, SeqEvt_WriteRemainingParams	; -> 0xF709D3
	ld	(32098:16), wa
SeqEvt_WriteRemainingParams:
	pop	xwa
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
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
	jr	z, SeqEvt_UpdateReadPosition	; -> 0xF70A5A
	ex16	iz, ix
	ld_rrb	a, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
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
	calr	SeqEvtBuf_AdvanceReadPos
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
	or a, (0x7d6b:16)
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
	calr	SeqEvtBuf_WriteBytePreserve
	ld	a, 208:opc
	or	a, (32107:16)
	calr	SeqEvtBuf_WriteBytePreserve
	ld	a, 7:opc
	calr	SeqEvtBuf_WriteBytePreserve
	ld_rrb	w, xhl, ix
	calr	SeqEvtBuf_AdvanceReadPos
	ld	a, 0:opc
	bit	0, w
	jr	z, SeqEvt_WriteSustainValue
	ld	a, 127:opc
SeqEvt_WriteSustainValue:
	calr SeqEvtBuf_WriteBytePreserve

SeqEvt_SaveReadPosAndRet:
	ld	(32115:16), ix
	ld	(xhl+6), ix
	ret
SeqEvt_CalcTempoOffset:
	sub a, (0x046c:16)
	cp a, (0x7d61:16)
	jr nc, .Lc_f70aef
	ld (0x7d61:16), a
SeqEvt_UpdateMinTempo:
.Lc_f70aef:
	ld iy, (0x7d75:16)
	st_rrb	a, xhl, iy
	xor	wa, wa
	ldb_d8	a, (32114)
	add	wa, (0x7d73:16)
	stda16	(32115), wa
	ld	ix, wa
	cp	ix, (xhl+2)
	jr	ugt, SeqEvt_HandleBufferWrap
	jr	SeqEvt_CalcTempoRet
SeqEvt_HandleBufferWrap:
	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 0:8)

	; stda16 (0x7e0f), xix (v7 patched)
	stda16	(32115), ix



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
	ld ix, (xhl + 0:8)

SeqEvtBuf_AdvanceRet:
	ret

SeqEvt_RotationOffsetTable:
; 8 LE16 byte offsets 0, 9, 18, ... 63: the starts of eight 9-byte slots.
; Read by SeqEvt_WriteNoteOnRotating (0xF708A7): A = byte
; at 0x7E0A (a rotating index advanced by 2 per call and wrapped at the
; byte at 0x7E06), IX = word [this + A]; the slot's bytes +0 and +2 are
; then read at (XHL+IX).  Stride 2, 8 entries (16 B up to
; SeqEvt_InitVoiceScan).  TYPED 2026-09-25 (lane seqeng).
	.short 0x0000, 0x0009, 0x0012, 0x001b, 0x0024, 0x002d, 0x0036, 0x003f

SeqEvt_InitVoiceScan:
	ldw	(32100:16), 65375
	ldw	(32102:16), 9
	ldw	(32104:16), 72
	ld	(32107:16), 1
	ld	xhl, 31952
	calr	Voice_ScanSlotMetric
	ld	(32107:16), 2
	ld	xhl, 32024
	calr	Voice_ScanSlotMetric
	ld	wa, (32100:16)
	ld	(32098:16), wa
	jr	SeqEvt_VoiceScanDone
SeqEvt_VoiceScanDone:
	ret

Voice_ScanSlotMetric:
	xor iy, iy

Voice_ScanLoop:
	cp	iy, (0x7d68:16)
	jr	c, Voice_CheckSlotBit
	jp	Voice_ScanLoopDone
Voice_CheckSlotBit:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr nz, Voice_ReadSlotParams
	jr Voice_ParamComplete

Voice_ReadSlotParams:
	ld	ix, iy
	ld_rrb	a, xhl, ix
	stb_d8	(32111), a
	inc	2, ix
	ld_rrb	a, xhl, ix
	stb_d8	(32112), a
	inc	1, ix
	ld_rrb	a, xhl, ix
	stb_d8	(32113), a
	inc	1, ix
	ld_rrw	wa, xhl, ix
	cp	wa, (0x46e:16)
	jr	gt, Voice_SubtractBaseFreq
	ex16	iy, iz
	ld	iy, (xhl+4)
	ld	a, 240:opc
	and	a, (0x7d6f:16)
	or	a, (0x7d6b:16)
	calr	SeqEvtBuf_WriteBytePreserve
	ldb_d8	a, (32112)
	calr	SeqEvtBuf_WriteBytePreserve
	ld	a, 0:opc
	calr	SeqEvtBuf_WriteBytePreserve
	ex16	iy, iz
	.byte 0xc3, 0x07, 0xec, 0xf4, 0x3c, 0x7f	; and (xhl+iy),0x7f
	jr	Voice_ParamComplete
Voice_SubtractBaseFreq:
	sub wa, (1134:16)
	bit 7, a
	jr z, Voice_StoreMetricValue
	add a, 0x60

Voice_StoreMetricValue:
	st_rrw	wa, xhl, ix
	cp	wa, (0x7d64:16)
	jr	nc, Voice_ParamComplete
	stda16	(32100), wa
Voice_ParamComplete:
	add	iy, (0x7d66:16)
	jp	Voice_ScanLoop
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
; PORTED 2026-09-25 (lane seqeng) from v10: Voice_NoteChannelTable1 ..
; Voice_NoteParamTable was spelled here as ~1,350 lines of nop/ei/reti/halt
; and .byte; the ROM bytes are identical to v10's apart from the absolute
; operands of the decode routines, which are symbolic.  v7 holds these bytes 0x404 LOWER than v10 (Voice_NoteParamTable at
; 0xF71620 here, 0xF71A24 in v10); the addresses quoted in the notes below are
; v10's -- subtract 0x404 for v7.
; RE-FRAMED 2026-09-02 (lane v10seq), replacing six per-span
; data-as-code annotations left by lane V10DAC inside this block --
; 0xF710A3-0xF710C3, 0xF710DB-0xF7110B, 0xF7116B-0xF7118B,
; 0xF711F3-0xF71213, 0xF71258-0xF7126A and 0xF7132D-0xF71344 -- with one
; typing of the whole table. The rest of the block was still spelled as
; nop/di/ei/reti/decf/incf/ldio mnemonics. Both references to this block
; are `ld xix, <label>`; nothing calls or jumps into +0x02..+0x401.
; +0x00 (2 B) head; the record grid below is based at +0x02
; +0x00 (2 B) head; the grid below is based at +0x02
	.byte 0x00, 0x00	; |..|
; +0x02 (128 records x 4 LE16). The reader is ldw_sri, a WORD load, so each record is four 16-bit fields and the index (note<<3) + ((h and 3)<<1) selects one of them. One record per line, MIDI note 0..127.
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0006, 0x0106, 0x0107
	.short 0x0000, 0x0406, 0x0206, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0407, 0x0000, 0x0000
	.short 0x0000, 0x0007, 0x0207, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0306, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0507, 0x0000
	.short 0x0000, 0x0000, 0x0506, 0x0000
	.short 0x0000, 0x0000, 0x0307, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0309, 0x0000, 0x0000
	.short 0x0000, 0x0109, 0x0000, 0x0000
	.short 0x0000, 0x0209, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0409, 0x0000
	.short 0x0000, 0x0000, 0x0509, 0x0000
	.short 0x0000, 0x0009, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0208, 0x0000
	.short 0x0000, 0x0008, 0x0108, 0x0000
	.short 0x0000, 0x0308, 0x0408, 0x0508
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x000a, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x020a, 0x0000, 0x040a
	.short 0x0000, 0x010a, 0x0000, 0x0000
	.short 0x0000, 0x030a, 0x0000, 0x0000
	.short 0x0000, 0x050a, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x030b, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x050b, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x020b, 0x0000
	.short 0x0000, 0x010b, 0x0000, 0x0000
	.short 0x0000, 0x000b, 0x0000, 0x040b
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0001, 0x0000, 0x0000
	.short 0x0000, 0x0205, 0x0000, 0x0000
	.short 0x0000, 0x0305, 0x0405, 0x0000
	.short 0x0000, 0x0000, 0x0005, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x000c, 0x030c, 0x0000
	.short 0x0000, 0x0504, 0x020c, 0x0000
	.short 0x0000, 0x040c, 0x0000, 0x0000
	.short 0x0000, 0x050c, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0105, 0x0000, 0x0000
	.short 0x0000, 0x0505, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0304, 0x0404, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0002, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0502, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0402, 0x0000
	.short 0x0000, 0x0102, 0x0000, 0x0003
	.short 0x0000, 0x0202, 0x0000, 0x0103
	.short 0x0000, 0x0302, 0x0000, 0x0203
	.short 0x0000, 0x0000, 0x0000, 0x0303
	.short 0x0000, 0x0000, 0x0000, 0x0403
	.short 0x0000, 0x0000, 0x0000, 0x0503
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0204
	.short 0x0000, 0x010c, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0004, 0x0000, 0x0000
	.short 0x0000, 0x0104, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0100, 0x0000, 0x0000
	.short 0x0000, 0x0200, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0400, 0x0000, 0x0000
	.short 0x0000, 0x0500, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0301, 0x0000, 0x0000
	.short 0x0000, 0x0101, 0x0000, 0x0000
	.short 0x0000, 0x0300, 0x0000, 0x0000
	.short 0x0000, 0x0501, 0x0000, 0x0000
	.short 0x0000, 0x0201, 0x0000, 0x0000
	.short 0x0000, 0x0401, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
; Voice_NoteChannelTable1 +0x402 (16 x LE16).
; RE-FRAMED 2026-09-02 (lane v10seq). Was 32 lines of mnemonics. Reader:
; Voice_DecodeNoteChannel percussion path -- xor h,h / and l,0xf / sla hl,1
; then ldw_sri off xix = this label, i.e. word[l & 15]. 32 B = 16 entries,
; ending exactly where the +0x422 subroutine begins.
	.short 0x000d, 0x010d, 0x020d, 0x030d, 0x040d, 0x050d, 0x000e, 0x010e
	.short 0x020e, 0x030e, 0x040e, 0x050e, 0x000c, 0x000c, 0x000c, 0x000c
; Voice_NoteChannelGrid_Lookup (= Voice_NoteChannelTable1 +0x422, the
; address shared/positional_labels.s still calls Voice_NoteChannelTable1_0x422;
; its one caller is AccompSeq_ProcessAfterNote in accompseq_routines.s).
; In: L = row (low 4 bits used), H = column (low 3 bits used).
; Out: HL = word [(L & 15) * 8 + (H & 7)] of the 16 x 8 grid at +0x43F below.
; Clobbers nothing else (XIX saved).  RE-FRAMED 2026-09-25 (lane seqeng): the
; five bytes d3 07 f0 ec 23 were written as `.byte 0xd3 / reti / .byte 0xf0,
; 0xec / ld c, 92` -- a lone prefix plus its operands read as instructions;
; unidasm and llvm-mc both read them as ONE instruction, ld HL,(XIX+HL).
Voice_NoteChannelGrid_Lookup:
; v7 only: accompseq_routines.s (not owned by lane seqeng) still calls this
; routine by its old structural name; keep that name as an alias until the
; call site is renamed, then drop it.
Voice_NoteChannelTable1_Code_Sub:
	and	l, 15
	and	h, 7
	sla	l, 4
	sla	h, 1
	or	l, h
	xor	h, h
	push	xix
	ld	xix, Voice_NoteChannelTable1_0x43F
	ldw_sri HL, 0x07, 0xf0, 0xec	; ld HL,(XIX+HL)
	pop	xix
	ret
; Voice_NoteChannelTable1 +0x43F (16 rows x 8 x LE16).
; RE-FRAMED 2026-09-02 (lane v10seq). Was ~160 lines of mnemonics with 12
; undecodable bytes wedged between them as .byte. Its reader is the routine
; just above (Voice_NoteChannelTable1 +0x422): and l,15 / and h,7 / sla l,4 /
; sla h,1 / or l,h / xor h,h then ldw_sri -- index (l&15)*16 + (h&7)*2, so a
; 16-row grid of 8 LE16 words, which is exactly the 256 B to the next label.
; The grid shape shows in the values: columns 6 and 7 are zero in every row.
	.short 0x0170, 0x0171, 0x0172, 0x017a, 0x0174, 0x0175, 0x0000, 0x0000
	.short 0x0140, 0x0179, 0x017c, 0x0178, 0x017d, 0x017b, 0x0000, 0x0000
	.short 0x0250, 0x0159, 0x015a, 0x015b, 0x0258, 0x0253, 0x0000, 0x0000
	.short 0x0359, 0x035a, 0x035b, 0x035c, 0x035d, 0x035e, 0x0000, 0x0000
	.short 0x0165, 0x0166, 0x0362, 0x014d, 0x024d, 0x0146, 0x0000, 0x0000
	.short 0x0243, 0x014a, 0x0141, 0x0142, 0x0242, 0x014b, 0x0000, 0x0000
	.short 0x0103, 0x0203, 0x0204, 0x010a, 0x0104, 0x020c, 0x0000, 0x0000
	.short 0x0108, 0x0303, 0x0208, 0x020d, 0x0107, 0x020b, 0x0000, 0x0000
	.short 0x011a, 0x021a, 0x0219, 0x011b, 0x021b, 0x031b, 0x0000, 0x0000
	.short 0x0116, 0x0112, 0x0113, 0x0111, 0x0214, 0x0215, 0x0000, 0x0000
	.short 0x0221, 0x0124, 0x0123, 0x0125, 0x0323, 0x0126, 0x0000, 0x0000
	.short 0x0136, 0x0135, 0x0234, 0x0130, 0x0336, 0x0231, 0x0000, 0x0000
	.short 0x0145, 0x0163, 0x0246, 0x0245, 0x0147, 0x0148, 0x0000, 0x0000
	.short 0x0180, 0x0181, 0x0182, 0x0183, 0x0184, 0x0185, 0x0000, 0x0000
	.short 0x0186, 0x0187, 0x0188, 0x0189, 0x018a, 0x018b, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
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
; RE-FRAMED 2026-09-02 (lane v10seq), replacing eleven per-span
; data-as-code annotations left by lane V10DAC inside this block with one
; typing of the whole table: 0xF715CA-0xF715DA, 0xF715EA-0xF715FA,
; 0xF71602-0xF71622, 0xF71647-0xF7166A, 0xF7167A-0xF7169A,
; 0xF716CA-0xF716E6, 0xF71752-0xF71772, 0xF717B2-0xF717D0,
; 0xF717DA-0xF717FA, 0xF71872-0xF718AA, 0xF718DA-0xF718EA and
; 0xF71972-0xF719A2. The rest was still spelled as mnemonics. The only
; reference is `ld xix, Voice_NoteChannelTable2_0x2`; nothing calls or
; jumps into the block, and 1026 B is exactly 2 + 128*8, ending where
; Voice_DecodeBankIndex begins.
; +0x00 (2 B) head; the grid below is based at +0x02
; +0x00 (2 B) head; the grid below is based at +0x02
	.byte 0x00, 0x00	; |..|
; +0x02 (128 records x 4 LE16). The reader is ldw_sri, a WORD load, so each record is four 16-bit fields and the index (note<<3) + ((h and 3)<<1) selects one of them. One record per line, MIDI note 0..127.
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0024, 0x0025, 0x002b
	.short 0x0000, 0x0028, 0x0026, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x002e, 0x0000, 0x0000
	.short 0x0000, 0x002a, 0x002c, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0027, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x002f, 0x0000
	.short 0x0000, 0x0000, 0x0029, 0x0000
	.short 0x0000, 0x0000, 0x002d, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0039, 0x0000, 0x0000
	.short 0x0000, 0x0037, 0x0000, 0x0000
	.short 0x0000, 0x0038, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x003a, 0x0000
	.short 0x0000, 0x0000, 0x003b, 0x0000
	.short 0x0000, 0x0036, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0032, 0x0000
	.short 0x0000, 0x0030, 0x0031, 0x0000
	.short 0x0000, 0x0033, 0x0034, 0x0035
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x003c, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x003e, 0x0000, 0x0040
	.short 0x0000, 0x003d, 0x0000, 0x0000
	.short 0x0000, 0x003f, 0x0000, 0x0000
	.short 0x0000, 0x0041, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0045, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0047, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0044, 0x0000
	.short 0x0000, 0x0043, 0x0000, 0x0000
	.short 0x0000, 0x0042, 0x0000, 0x0046
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0006, 0x0000, 0x0000
	.short 0x0000, 0x0020, 0x0000, 0x0000
	.short 0x0000, 0x0021, 0x0022, 0x0000
	.short 0x0000, 0x0000, 0x001e, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0048, 0x004b, 0x0000
	.short 0x0000, 0x001d, 0x004a, 0x0000
	.short 0x0000, 0x004c, 0x0000, 0x0000
	.short 0x0000, 0x004d, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x001f, 0x0000, 0x0000
	.short 0x0000, 0x0023, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x001b, 0x001c, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x000c, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0011, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0010, 0x0000
	.short 0x0000, 0x000d, 0x0000, 0x0012
	.short 0x0000, 0x000e, 0x0000, 0x0013
	.short 0x0000, 0x000f, 0x0000, 0x0014
	.short 0x0000, 0x0000, 0x0000, 0x0015
	.short 0x0000, 0x0000, 0x0000, 0x0016
	.short 0x0000, 0x0000, 0x0000, 0x0017
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x001a
	.short 0x0000, 0x0049, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0018, 0x0000, 0x0000
	.short 0x0000, 0x0019, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0001, 0x0000, 0x0000
	.short 0x0000, 0x0002, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0004, 0x0000, 0x0000
	.short 0x0000, 0x0005, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0009, 0x0000, 0x0000
	.short 0x0000, 0x0007, 0x0000, 0x0000
	.short 0x0000, 0x0003, 0x0000, 0x0000
	.short 0x0000, 0x000b, 0x0000, 0x0000
	.short 0x0000, 0x0008, 0x0000, 0x0000
	.short 0x0000, 0x000a, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
	.short 0x0000, 0x0000, 0x0000, 0x0000
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
; Voice_BankIndexTable (18 x LE16), 2026-09-02 (lane v10seq).
; Voice_DecodeBankIndex: and l,0x7f / cp l,0xc else xor l,l / xor h,h /
; sla hl,1 then ldw_sri off xix = +0x02, so entry k is the word at index
; k+1 below. The values are the ramp 0x20,0x30,...,0xD0 then 0x20 repeated.
	.short 0x0000, 0x0020, 0x0030, 0x0040, 0x0050, 0x0060, 0x0070, 0x0080
	.short 0x0090, 0x00a0, 0x00b0, 0x00c0, 0x00d0, 0x0020, 0x0020, 0x0020
	.short 0x0020, 0x0020

Voice_DecodeNoteParam:
	cp l, 0x80
	jr c, Voice_DecodeStandard
	ld h, 0x1:opc
	cp l, 0x8c
	jr c, Voice_DecodePercussion
	ld l, 0x80:opc

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
; REGRIDDED 2026-09-02 (lane v10seq). The bytes were already correct;
; they were laid out 8 to a line but starting at +0x00, which put every
; record across two lines. The only reference to this block is
; `ld xix, Voice_NoteParamTable_0x2`, and 1026 B is exactly 2 + 128*8.
; +0x00 (2 B) head; the grid below is based at +0x02
; +0x00 (2 B) head; the grid below is based at +0x02
	.byte 0x00, 0x00	; |..|  (was `nop / nop`: never executed, nothing jumps here)
; +0x02 (128 records x 4 LE16). The reader is ldw_sri, a WORD load, so each record is four 16-bit fields and the index (note<<3) + ((h and 3)<<1) selects one of them. One record per line, MIDI note 0..127.
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0104, 0x0204, 0x0204
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0103, 0x0203, 0x0303
	.short 0x0100, 0x0107, 0x0107, 0x0107
	.short 0x0100, 0x0108, 0x0208, 0x0208
	.short 0x0100, 0x0108, 0x0208, 0x0208
	.short 0x0100, 0x010a, 0x010a, 0x010a
	.short 0x0100, 0x020b, 0x020b, 0x020b
	.short 0x0100, 0x020c, 0x020c, 0x020c
	.short 0x0100, 0x020d, 0x020d, 0x020d
	.short 0x0100, 0x020d, 0x020d, 0x020d
	.short 0x0100, 0x020d, 0x020d, 0x020d
	.short 0x0100, 0x0111, 0x0111, 0x0111
	.short 0x0100, 0x0111, 0x0111, 0x0111
	.short 0x0100, 0x0112, 0x0112, 0x0112
	.short 0x0100, 0x0113, 0x0113, 0x0113
	.short 0x0100, 0x0214, 0x0214, 0x0214
	.short 0x0100, 0x0215, 0x0215, 0x0215
	.short 0x0100, 0x0116, 0x0116, 0x0116
	.short 0x0100, 0x0116, 0x0116, 0x0116
	.short 0x0100, 0x0116, 0x0116, 0x0116
	.short 0x0100, 0x0219, 0x0219, 0x0219
	.short 0x0100, 0x011a, 0x021a, 0x021a
	.short 0x0100, 0x011b, 0x021b, 0x031b
	.short 0x0100, 0x011b, 0x021b, 0x031b
	.short 0x0100, 0x011b, 0x021b, 0x031b
	.short 0x0100, 0x011b, 0x021b, 0x031b
	.short 0x0100, 0x011b, 0x021b, 0x031b
	.short 0x0100, 0x0221, 0x0221, 0x0221
	.short 0x0100, 0x0221, 0x0221, 0x0221
	.short 0x0100, 0x0221, 0x0221, 0x0221
	.short 0x0100, 0x0123, 0x0123, 0x0323
	.short 0x0100, 0x0124, 0x0124, 0x0124
	.short 0x0100, 0x0125, 0x0125, 0x0125
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0126, 0x0126, 0x0126
	.short 0x0100, 0x0130, 0x0130, 0x0130
	.short 0x0100, 0x0231, 0x0231, 0x0231
	.short 0x0100, 0x0231, 0x0231, 0x0231
	.short 0x0100, 0x0231, 0x0231, 0x0231
	.short 0x0100, 0x0234, 0x0234, 0x0234
	.short 0x0100, 0x0135, 0x0135, 0x0135
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0136, 0x0136, 0x0336
	.short 0x0100, 0x0140, 0x0140, 0x0140
	.short 0x0100, 0x0141, 0x0141, 0x0141
	.short 0x0100, 0x0142, 0x0242, 0x0242
	.short 0x0100, 0x0243, 0x0243, 0x0243
	.short 0x0100, 0x0145, 0x0245, 0x0245
	.short 0x0100, 0x0145, 0x0245, 0x0245
	.short 0x0100, 0x0146, 0x0246, 0x0246
	.short 0x0100, 0x0147, 0x0147, 0x0147
	.short 0x0100, 0x0148, 0x0148, 0x0148
	.short 0x0100, 0x0148, 0x0148, 0x0148
	.short 0x0100, 0x014a, 0x014a, 0x014a
	.short 0x0100, 0x014b, 0x014b, 0x014b
	.short 0x0100, 0x014b, 0x014b, 0x014b
	.short 0x0100, 0x014d, 0x024d, 0x024d
	.short 0x0100, 0x014d, 0x024d, 0x024d
	.short 0x0100, 0x014d, 0x024d, 0x024d
	.short 0x0100, 0x0250, 0x0250, 0x0250
	.short 0x0100, 0x0250, 0x0250, 0x0250
	.short 0x0100, 0x0250, 0x0250, 0x0250
	.short 0x0100, 0x0253, 0x0253, 0x0253
	.short 0x0100, 0x0253, 0x0253, 0x0253
	.short 0x0100, 0x0253, 0x0253, 0x0253
	.short 0x0100, 0x0253, 0x0253, 0x0253
	.short 0x0100, 0x0253, 0x0253, 0x0253
	.short 0x0100, 0x0258, 0x0258, 0x0258
	.short 0x0100, 0x0159, 0x0159, 0x0359
	.short 0x0100, 0x015a, 0x015a, 0x035a
	.short 0x0100, 0x015b, 0x015b, 0x035b
	.short 0x0100, 0x035c, 0x035c, 0x035c
	.short 0x0100, 0x035d, 0x035d, 0x035d
	.short 0x0100, 0x035e, 0x035e, 0x035e
	.short 0x0100, 0x035e, 0x035e, 0x035e
	.short 0x0100, 0x0362, 0x0362, 0x0362
	.short 0x0100, 0x0362, 0x0362, 0x0362
	.short 0x0100, 0x0362, 0x0362, 0x0362
	.short 0x0100, 0x0163, 0x0163, 0x0163
	.short 0x0100, 0x0163, 0x0163, 0x0163
	.short 0x0100, 0x0165, 0x0165, 0x0165
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0166, 0x0166, 0x0166
	.short 0x0100, 0x0170, 0x0170, 0x0170
	.short 0x0100, 0x0171, 0x0171, 0x0171
	.short 0x0100, 0x0172, 0x0172, 0x0172
	.short 0x0100, 0x0172, 0x0172, 0x0172
	.short 0x0100, 0x0174, 0x0174, 0x0174
	.short 0x0100, 0x0175, 0x0175, 0x0175
	.short 0x0100, 0x0175, 0x0175, 0x0175
	.short 0x0100, 0x0175, 0x0175, 0x0175
	.short 0x0100, 0x0178, 0x0178, 0x0178
	.short 0x0100, 0x0179, 0x0179, 0x0179
	.short 0x0100, 0x017a, 0x017a, 0x017a
	.short 0x0100, 0x017b, 0x017b, 0x017b
	.short 0x0100, 0x017c, 0x017c, 0x017c
	.short 0x0100, 0x017d, 0x017d, 0x017d
	.short 0x0100, 0x017d, 0x017d, 0x017d
	.short 0x0100, 0x017d, 0x017d, 0x017d
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
	cpdi8	(32368), 0
	jr	z, AccPlay_StopSequencer
	calr	AccPlay_MainUpdateLoop
	jr	AccPlay_ContinueMainLoop
AccPlay_StopSequencer:
	calr AccPlay_StopIfRunning

AccPlay_ContinueMainLoop:
	calr	AccPlay_MonitorParamState
	bitda	0, (32409)
	jr	z, AccPlay_UpdateStateFlags
	anddi8	(32409), 254
	calr	AccPlay_CheckAndToggle
AccPlay_UpdateStateFlags:
	ldb_d8	a, (32367)
	stb_d8	(32368), a
	bitda	2, (32377)
	jr	z, AccPlay_DispatchRet
	cpdi8	(35994), 1
	jr	nz, AccPlay_DispatchRet
	anddi8	(32377), 251
	stdi8	(32422), 15
	call	DrumVoice_NotifyEE
AccPlay_DispatchRet:
	ret

AccPlay_InitializeStart:
	call AccWrap_PlayModeDispatch
	call CountAvailableVoiceSlots
	calr AccPlay_SetupSoundParams
	call AccPlay_InitializeStart_Helper
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
	ld A, 0x10:opc
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
	ormi8	(xhl), 1
	ld	xwa, 34
	ld	xbc, 0:i3
	ld	xde, 0:i3
	call	CtrlPanel_IndicatorDispatch
	stdi8	(36530), 4
	ret
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
	call AccPlay_InitializeStart_Helper
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
	ld A, 0x01:opc
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
	; ordi8 0x7f15, 1 (v7 patched)
	ordi8	(32377), 1

	ld xhl, 0x1e880a

	andmi8 (xhl), 0xfe

	ld xwa, 0x22

	; call CtrlPanel_SetIndicatorLED (v7 addr)
	call	CtrlPanel_SetIndicatorLED

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
	cp hl, 0:i3
	jr nz, TempoEvt_ReadAndClassify
	jp AccPlay_PostLoopCleanup

TempoEvt_ReadAndClassify:
	call	TempoRingBuf_SaveReadPos
	call	TempoRingBuf_ReadAlternate
	ld	a, l
	ld	w, a
	and	w, 240
	stb_d8	(32184), a
	stb_d8	(32185), w
	bitda	7, (32378)
	jr	z, TempoEvt_DispatchEvent
	cp	a, 129
	jr	nz, TempoEvt_CheckHighBit
	ldb_d8	a, (32378)
	ld	w, a
	and	a, 31
	and	w, 224
	dec	1, a
	or	w, a
	cp	a, 0:i3
	jr	nz, TempoEvt_StoreBankParam
	and	w, 127
	calr	AccPlay_UpdateBankParams
TempoEvt_StoreBankParam:
	ld	(32378:16), w
	jr	TempoEvt_ContinueProcessing
TempoEvt_CheckHighBit:
	bit	7, a
	jr	z, TempoEvt_ContinueProcessing
	ldb_d8	a, (32378)
	and	a, 31
	cp	a, 1:i3
	jr	nz, TempoEvt_ContinueProcessing
	call	TempoRingBuf_ReadAlternate
	ld	a, l
	cp	a, 72
	jr	c, TempoEvt_ContinueProcessing
	ordi8	(32377), 16
	ldb_d8	a, (32184)
	ldb_d8	w, (32185)
	jr	TempoEvt_DispatchEvent
TempoEvt_ContinueProcessing:
	calr TempoRingBuf_ReadLoop
	jp TempoEvt_ProcessLoop

TempoEvt_DispatchEvent:
	cpw	(32124:16), 0
	jr	nz, TempoEvt_HandleEndMarker
	calr	AccPlay_InitAndStartLoop
	jr	TempoEvent_ContinueLoop
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
	bitda	0, (32377)
	jr	z, AccPlay_StopRet
	bitda	2, (1056)
	jr	nz, AccPlay_StopRet
	call	Seq_DispatcherEntry
	anddi8	(13132), 254
	ordi8	(13361), 128
	call	Seq_DispatcherEntry
	anddi8	(32377), 254
AccPlay_StopRet:
	ret

AccPlay_ProcessVoiceBank:
	calr Voice_GetBankEntryPointer
	ld a, (xiy + 0:8)
	bit 0, a
	jr z, AccPlay_VoiceBankRet
	calr Voice_ReleaseChain
	calr Voice_InitSlotTemplate

AccPlay_VoiceBankRet:
	ret

Voice_GetBankEntryPointer:
	ld	a, (32376:16)
	cp	a, 12
	jr	c, Voice_CalcBankOffset
	ld	a, 0:opc
Voice_CalcBankOffset:
	ld xiy, 0x1e8820
	ld w, 0x10:opc
	mul wa, w
	and xwa, 0xffff
	add xiy, xwa
	ret

Voice_ReleaseChain:
	ld hl, (xiy + 3)
	cp hl, 0xffff
	jr z, Voice_ReleaseChainDone

Voice_ReleaseChainLoop:
	calr	Util_ExtractAndShiftBits
	ld	hl, (xix+3)
	ldw	(xix+1), 65535
	ldw	(xix+3), 65535
	andmi8	(xix), 127
	incdi16	1, (32124)
	cp	hl, 65535
	jr	z, Voice_ReleaseChainDone
	jr	Voice_ReleaseChainLoop
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
; 16-byte template of one voice slot, copied as 8 LE16 words.  Read by
; Voice_InitSlotTemplate (0xF71D09): XIX = the slot (XIY on
; entry), XIY = this, BC = 8, ldirw; the slot's byte +0 then gets back its
; own old high nibble (and 0xF0), so only the template's low nibble of
; byte +0 survives.  TYPED 2026-09-25 (lane seqeng); was spelled
; nop / swi 7 / jrl nc,64 (0xFF bytes read as swi 7).
	.short 0x0000, 0xff00, 0x00ff, 0x0000, 0x0000, 0x7f00, 0x0040, 0x0000

AccPlay_SetupSoundParams:
	ld A, 0x17:opc
	ld (0x8c9e:16), a
	ld E, 0x90:opc
	ld D, 0x10:opc
	ld A, 0x17:opc
	ld W, 0xff:opc
	call SysEx_ApplyVoiceParam_49
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	cp WA,0x01ff
	jr nz, AccPlay_SetupJumpTarget
	ld wa, 0:i3
	ld (0xfd62:16), a
	ld (0xfd63:16), w
	ld E, 0x17:opc
	ld D, 0x01:opc
	ld A, 0x00:opc
	ld W, 0x7f:opc
	call SysEx_ApplyVoiceParam_49
	ld E, 0x17:opc
	ld D, 0x00:opc
	ld A, 0x00:opc
	ld W, 0xff:opc
	call SysEx_ApplyVoiceParam_49
	ld H, 0x00:opc
	ld L, 0x00:opc
	ld (0x905b:16), 0x17
	call PartCtrl_WriteProgramChange
	ld XBC,0x0000ff7e
	st_rr8b	h, xbc, l
AccPlay_SetupJumpTarget:
	jp AccPlay_SyncParamsRet
AccPlay_SyncVoiceParams:
	ld	xiy, 63926
	ld	xix, 64866
	ld	c, 30:opc
AccPlay_SetupSoundParams_Loop:
	ld	a, (xiy)
	ld	w, (xix)
	ld	(xix), a
	cp	a, w
	jr	z, AccPlay_SetupSoundParams_Skip
	push	xiy
	push	xix
	push	xbc
	ld	e, 23:opc
	ld	d, 30:opc
	sub	d, c
	ld	w, 255:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xbc
	pop	xix
	pop	xiy
AccPlay_SetupSoundParams_Skip:
	inc	1, iy
	inc	1, ix
	dec	1, c
	cp	c, 0:i3
	jr	nz, AccPlay_SetupSoundParams_Loop
AccPlay_SyncParamsRet:
	ret

AccPlay_AllocateVoiceSlot:
	calr Voice_GetBankEntryPointer
	push XIY
	calr Voice_FindFreeSlot
	ld HL,WA
	calr Util_ExtractAndShiftBits
	ormi8	(xix), 128
	decdi16	1, (32124)
	pop	xiy
	ld	(xiy+3), wa
	ld	l, 1:opc
	or	(xiy+0:8), l
	stda16	(32372), wa
	ld	wa, 6:i3
	stda16	(32374), wa
	ldb_d8	a, (64866)
	ldb_d8	w, (64867)
	ld	(xiy+9), wa
	xor	a, a
	ldb_d8	w, (64870)
	bit	6, w
	jr	z, AccPlay_CheckReverbFlag
	or	a, 1
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
	calr	TempoRingBuf_ReadLoop
	bit	7, a
	jr	z, AccPlay_UnusedCodeFragment
	ret

AccPlay_ExtractVoiceSlot:
	ld hl, (32372:16)

	calr Util_ExtractAndShiftBits

	ld a, 0x83:opc

	ld hl, (32374:16)

	stb_dri A, 0x07, 0xf0, 0xec

	ret



AccPlay_ProcessNoteEvent:
	ld	bc, 5:i3
	calr	MidiSeqBuf_ScanAllEntries
	ld	a, (32413:16)
	cp	a, 0:i3
	jr	z, AccPlay_NoteNoSlotMatch
	calr	AccPlay_NoteWithSlot
	jr	AccPlay_NoteEventRet
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
	push	xhl
	push	xix
	ldb_d8	l, (32412)
	xor	h, h
	ld	xix, Display_FontPalette_Table_0x12EA
	ld_rrb	a, xix, hl
	xor	w, w
	sla	wa, 2
	ld	hl, wa
	ld	xix, AccPlay_NoteParamTable
	ld_rrb	a, xix, hl
	stb_d8	(32184), a
	inc	1, hl
	ld_rrb	a, xix, hl
	stb_d8	(32185), a
	inc	1, hl
	ld_rrb	a, xix, hl
	stb_d8	(32186), a
	ld	a, 144:opc
	cpdi8	(32184), 0
	jr	z, AccPlay_NoteWriteStatusByte
	ld	a, 145:opc
; AccPlay_NoteWriteStatusByte (was AccPlay_NoteSetType91): A = 0x90, or 0x91
; when AccPlay_NoteParamTable's flag byte for this note is nonzero; the branch
; here is taken with A still 0x90.  Writes A, then the bytes at 0x7F37 and
; 0x7F38, to the MIDI sequence buffer (MidiSeqBuf_WriteByte).
AccPlay_NoteWriteStatusByte:
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	ldb_d8	a, (32411)
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	ldb_d8	a, (32412)
	calr	MidiSeqBuf_WriteByte
	pop	xix
	pop	xhl
	ldb_d8	a, (32412)
	or	a, 128
	ld	(xhl), a
	ld	a, 0:opc
	ld	(xhl+1), a
	ldb_d8	a, (32411)
	ld	(xhl+2), a
	ldw_d16	wa, (32372)
	ld	(xhl+3), wa
	ldw_d16	wa, (32374)
	ld	(xhl+5), a
	calr	MidiSeqBuf_AdvancePosition
	ldb_d8	a, (32413)
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	ld	a, 16:opc
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	ld	a, 0:opc
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	cpdi8	(32184), 0
	jr	z, AccPlay_NoteAllocRet
	ldb_d8	a, (32185)
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
	ldb_d8	a, (32186)
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvancePosition
AccPlay_NoteAllocRet:
	ret

AccPlay_NoteParamTable:
; 12 records x 4 bytes: +0 flag, +1 and +2 two extra event bytes, +3 unused
; (0 in every record).  Read by AccPlay_NoteAllocAndWrite
; (0xF71EA7): L = byte at 0x7F38, A = byte
; [Display_FontPalette_Table_0x12EA + L], HL = 4*A (12 records), then
; +0/+1/+2 go to 0x7E54/0x7E55/0x7E56.  A nonzero +0 makes the event
; status 0x91 instead of 0x90 and appends bytes +1 and +2 to the event.
; Non-zero records: 3 and 4 = (1, 0x00, 0x11), 7 = (1, 0x03, 0x00),
; 11 = (1, 0x11, 0x11).  TYPED 2026-09-25 (lane seqeng); it was spelled
; as .zero / nop / normal / scf / pop sr.
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x11, 0x00
	.byte 0x01, 0x00, 0x11, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x01, 0x03, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x01, 0x11, 0x11, 0x00

AccPlay_FindActiveSlot:
	ld	xhl, 32223
AccPlay_ScanActiveLoop:
	ld	a, (xhl)
	bit	7, a
	jr	z, AccPlay_ScanActiveRet
	add	xhl, 9
	cp	xhl, 32367
	jr	z, AccPlay_ScanActiveFail
	jr	AccPlay_ScanActiveLoop
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
	jr	z, AccPlay_ChannelSlotFound
	add	hl, 9
	cp	xhl, 32367
	jr	z, AccPlay_ChannelScanFail
	jr	AccPlay_ChannelScanLoop
AccPlay_ChannelScanFail:
	jr AccPlay_NoteReleaseRet

AccPlay_ChannelSlotFound:
	ld	a, 0:opc
	ld	(xhl), a
	ld	d, (xhl+1)
	ld	a, (xhl+2)
	ld	c, (32411:16)
	cp	c, a
	jr	nc, AccPlay_CalcNoteOffset
	add	c, 96
	cp	d, 0:i3
	jr	z, AccPlay_CalcNoteOffset
	dec	1, d
AccPlay_CalcNoteOffset:
	sub c, a
	ld e, c
	cp d, 0:i3
	jr nz, AccPlay_WriteNoteRelease
	cp e, 2:i3
	jr nc, AccPlay_WriteNoteRelease
	ld e, 0x2:opc

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
	calr	MidiSeqBuf_AdvanceWritePos
	calr	MidiSeqBuf_AdvanceWritePos
	popw	de
	ld	a, e
	and	a, 127
	pushw	de
	calr	MidiSeqBuf_WriteByte
	calr	MidiSeqBuf_AdvanceWritePos
	popw	de
	ld	a, d
	and	a, 127
	calr	MidiSeqBuf_WriteByte
	popw	wa
	ld	(32374:16), wa
	popw	wa
	ld	(32372:16), wa
AccPlay_NoteReleaseRet:
	ret

AccPlay_HandleEndMarkerEvt:
	ld	bc, 1:i3
	calr	MidiSeqBuf_ScanAllEntries
	ld	de, 1:i3
	calr	MidiSeqBuf_ProcessEntries
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
	jr	nz, AccPlay_IncrementHoldLoop
	ret
MidiSeq_ProcessSustainEvent:
	ld	bc, 4:i3
	calr	MidiSeqBuf_ScanAllEntries
	ld	xhl, 32410
	ld	a, (xhl)
	cp	a, 211
	jr	nz, MidiSeq_SustainFixup
	ld	a, 213:opc
	ld	(xhl), a
MidiSeq_SustainFixup:
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleD2Event:
	ld	bc, 5:i3
	calr	MidiSeqBuf_ScanAllEntries
	ld	xhl, 32410
	ld	a, (xhl+3)
	ld	(xhl+2), a
	ld	de, 3:i3
	calr	MidiSeqBuf_ProcessEntries
	ret
MidiSeq_HandleProgChange:
	ld	bc, 7:i3
	calr	MidiSeqBuf_ScanAllEntries
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
	jr	z, MidiSeq_ProgChangeSetReverb
	or	w, 1
MidiSeq_ProgChangeSetReverb:
	ld (xhl + 5), w
	ld de, 6:i3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleCtrlChange:
	ld	bc, 7:i3
	calr	MidiSeqBuf_ScanAllEntries
	ld	xhl, 32410
	ld	a, (xhl+2)
	ld	w, (xhl)
	bit	2, w
	jr	z, MidiSeq_CtrlCheckType
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
	ld a, 0xd4:opc
	ld (xhl), a
	and e, 0x7f
	ld (xhl + 2), e
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_CheckSostenuto:
	cp a, 0x17
	jr nz, MidiSeq_SustainHandler
	cp w, 4:i3
	jr nz, MidiSeq_SustainHandler
	bit 6, d
	jr z, MidiSeq_SustainHandler
	ld a, 0xd7:opc
	ld (xhl), a
	ld a, 0x0:opc
	bit 6, e
	jr z, MidiSeq_SostenutoValue
	ld a, 0x7f:opc

MidiSeq_SostenutoValue:
	ld (xhl + 2), a
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_SustainHandler:
	cp a, 0x17
	jr nz, MidiSeq_SustainRet
	cp w, 4:i3
	jr nz, MidiSeq_SustainRet
	bit 3, d
	jr z, MidiSeq_SustainRet
	ld a, 0xd3:opc
	ld (xhl), a
	ld a, 0x0:opc
	bit 3, e
	jr z, MidiSeq_SoftPedalValue
	ld a, 0x7f:opc

MidiSeq_SoftPedalValue:
	ld (xhl + 2), a
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	jr MidiSeq_SustainRet

MidiSeq_SustainRet:
	ret

AccPlay_TrackMeasureChange:
	ld	a, (1076:16)
	ld	w, (32408:16)
	cp	a, w
	jr	z, AccPlay_MeasureTrackRet
	ld	hl, (32370:16)
	inc	1, hl
	cp	hl, 0:i3
	jr	nz, AccPlay_MeasureIncrement
	inc	1, hl
AccPlay_MeasureIncrement:
	ld	(32370:16), hl
	cp	(35996:16), 201
	jr	nz, AccPlay_MeasureNotifyDone
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	AccSeq_DeliverC9_0009
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
	jr	z, AccPlay_SaveCurrentState
	cp	(32368:16), 0
	jr	z, AccPlay_InitVoiceBankState
	calr	AccPlay_CompareAndSendProg
	jr	AccPlay_SaveCurrentState
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
	jr	z, AccPlay_CompareReverbState
	ld	e, w
	ld	w, a
	ld	a, 193:opc
	ld	(32164:16), w
	and	e, 15
	bit	7, w
	jr	z, AccPlay_SendProgChange
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
	jr	z, AccPlay_CompareChorusState
	ld	e, 0:opc
	cp	a, 0:i3
	jr	z, AccPlay_SetReverbValue
	ld	e, 127:opc
AccPlay_SetReverbValue:
	ld w, 0x7:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent

AccPlay_CompareChorusState:
	jr	AccPlay_ParamMonitorRet
	ld	hl, (32382:16)
	ld	a, (64870:16)
	and	a, 8
	xor	w, w
	and	l, 8
	cp	wa, hl
	jr	z, AccPlay_ParamMonitorRet
	ld	e, 0:opc
	cp	a, 0:i3
	jr	z, AccPlay_SetChorusValue
	ld	e, 127:opc
AccPlay_SetChorusValue:
	ld w, 0x3:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent

AccPlay_ParamMonitorRet:
	ret

AccPlay_RestoreVoiceBank:
	calr	Voice_GetBankEntryPointer
	ld	wa, (xiy+9)
	ld	e, w
	ld	w, a
	ld	a, 193:opc
	ld	(32164:16), w
	and	e, 15
	bit	7, w
	jr	z, AccPlay_SendBankProgram
	or	e, 16
	and	w, 127
AccPlay_SendBankProgram:
	call	AccompSeq_SendMidiEvent
	ld	wa, (xiy+9)
	ld	(64866:16), a
	ld	(64867:16), w
	ld	e, 23:opc
	ld	d, 1:opc
	ld	a, w
	ld	w, 127:opc
	call	SysEx_ApplyVoiceParam_49
	ld	wa, (xiy+9)
	ld	e, 23:opc
	ld	d, 0:opc
	ld	w, 255:opc
	call	SysEx_ApplyVoiceParam_49
	ld	a, (xiy+12)
	ld	e, a
	ld	w, 4:opc
	ld	a, 209:opc
	call	AccompSeq_SendMidiEvent
	ld	a, (xiy+12)
	ld	(64874:16), a
	ld	e, 23:opc
	ld	d, 8:opc
	ld	w, 127:opc
	call	SysEx_ApplyVoiceParam_49
	ld	a, (xiy+13)
	ld	e, 0:opc
	bit	0, a
	jr	z, AccPlay_RestoreReverbVal
	ld	e, 127:opc
AccPlay_RestoreReverbVal:
	ld w, 0x7:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 13)
	ld w, (0xfd66:16)
	and w, 0xbf
	bit 0, a
	jr z, AccPlay_WriteReverbFlag
	or w, 0x40

AccPlay_WriteReverbFlag:
	ld	(64870:16), w
	ld	e, 23:opc
	ld	d, 4:opc
	ld	a, w
	ld	w, 64:opc
	call	SysEx_ApplyVoiceParam_49
	ld	a, (xiy+14)
	ld	e, 0:opc
	bit	0, a
	jr	z, AccPlay_RestoreChorusVal
	ld	e, 127:opc
AccPlay_RestoreChorusVal:
	ld w, 0x3:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 14)
	ld w, (0xfd66:16)
	and w, 0xf7
	bit 0, a
	jr z, AccPlay_WriteChorusFlag
	or w, 0x8

AccPlay_WriteChorusFlag:
	ld	(64870:16), w
	ld	e, 23:opc
	ld	d, 4:opc
	ld	a, w
	ld	w, 8:opc
	call	SysEx_ApplyVoiceParam_49
	ret
AccPlay_ClearSlotTable:
	ld	xhl, 32223
	ld	a, 0:opc
AccPlay_ClearSlotLoop:
	ld	(xhl), a
	add	xhl, 9
	cp	xhl, 32367
	jr	z, AccPlay_ClearSlotDone
	jr	AccPlay_ClearSlotLoop
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
	ld	a, 192:opc
	or	(63939:16), a
	or	(63965:16), a
	or	(63991:16), a
	or	(64017:16), a
	or	(64043:16), a
	or	(64069:16), a
	or	(64095:16), a
	or	(64121:16), a
	or	(64147:16), a
	or	(64173:16), a
	or	(64199:16), a
	or	(64225:16), a
	or	(64251:16), a
	or	(64277:16), a
	or	(64303:16), a
	or	(64329:16), a
	or	(64355:16), a
	or	(64381:16), a
	or	(64407:16), a
	or	(64433:16), a
	or	(64459:16), a
	or	(64485:16), a
	or	(64511:16), a
	or	(64537:16), a
	ld	a, (64879:16)
	and	a, 63
	and	a, 240
	ld	(64879:16), a
	ld	e, 23:opc
	ld	d, 13:opc
	ld	w, 207:opc
	call	SysEx_ApplyVoiceParam_49
	calr	AccompSeq_QueueAllMutes
	ret
AccompSeq_QueueAllMutes:
	ld e, 0x0:opc
	ld a, (0xf9c3:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x1:opc
	ld a, (0xf9dd:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x2:opc
	ld a, (0xf9f7:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x3:opc
	ld a, (0xfa11:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x4:opc
	ld a, (0xfa2b:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x5:opc
	ld a, (0xfa45:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x6:opc
	ld a, (0xfa5f:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x7:opc
	ld a, (0xfa79:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x8:opc
	ld a, (0xfa93:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x9:opc
	ld a, (0xfaad:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xa:opc
	ld a, (0xfac7:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xb:opc
	ld a, (0xfae1:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xc:opc
	ld a, (0xfafb:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xd:opc
	ld a, (0xfb15:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xe:opc
	ld a, (0xfb2f:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0xf:opc
	ld a, (0xfb49:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x10:opc
	ld a, (0xfb63:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x11:opc
	ld a, (0xfb7d:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x12:opc
	ld a, (0xfb97:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x13:opc
	ld a, (0xfbb1:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x14:opc
	ld a, (0xfbcb:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x15:opc
	ld a, (0xfbe5:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x16:opc
	ld a, (0xfbff:16)
	calr AccompSeq_QueueMuteEvent
	ld e, 0x19:opc
	ld a, (0xfc19:16)
	calr AccompSeq_QueueMuteEvent
	ret

AccompSeq_QueueMuteEvent:
	ld	d, 13:opc
	ld	w, 207:opc
	call	SysEx_ApplyVoiceParam_49
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
	ld	e, 23:opc
	ld	d, 13:opc
	ld	w, 79:opc
	call	SysEx_ApplyVoiceParam_49
	calr	AccompSeq_QueueAllMutes
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
	ld bc, 0:i3

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
	calr	TempoRingBuf_ReadLoop
	ld	xhl, 32410
	st_rrb	a, xhl, ix
	inc	1, ix
	dec	1, bc
	cp	bc, 0:i3
	jr	nz, MidiSeqBuf_ScanLoop
	bitda	4, (32377)
	jr	z, MidiSeqBuf_ScanDone
	anddi8	(32377), 239
	ld	(xhl+1), 0
MidiSeqBuf_ScanDone:
	ret

MidiSeqBuf_ProcessEntries:
	cpw (0x7d7c:16), 0x0000
	jr z, MidiSeqBuf_ProcessDone
	xor IX,IX
MidiSeqBuf_ProcessLoop:
.Lc_f7266f:
	ld XHL,0x00007e9a
	ld_rrb	a, xhl, ix
	push	xix
	pushw	de
	ldw_d16	hl, (32372)
	calr	Util_ExtractAndShiftBits
	ldw_d16	hl, (32374)
	st_rrb	a, xix, hl
	calr	MidiSeqBuf_AdvancePosition
	popw	de
	pop	xix
	inc	1, ix
	cp	ix, de
	jr	c, MidiSeqBuf_ProcessLoop
MidiSeqBuf_ProcessDone:
	ret

MidiSeqBuf_AdvancePosition:
	ldw_d16	wa, (32374)
	inc	1, wa
	cp	wa, 255
	jr	nz, MidiSeqBuf_AdvanceDone
	push	xix
	push	xde
	push	xhl
	calr	Voice_FindFreeSlot
	xor	ix, ix
	ldw_d16	hl, (32372)
	ld	de, hl
	calr	Util_ExtractAndShiftBits
	ld	(xix+3), wa
	stda16	(32372), wa
	ld	hl, wa
	calr	Util_ExtractAndShiftBits
	ld	(xix+1), de
	ormi8	(xix), 128
	decdi16	1, (32124)
	ld	wa, 6:i3
	pop	xhl
	pop	xde
	pop	xix
MidiSeqBuf_AdvanceDone:
	ld	(32374:16), wa
	ret
MidiSeqBuf_AdvanceWritePos:
	ld	wa, (32374:16)
	inc	1, wa
	cp	wa, 255
	jr	nz, MidiSeqBuf_WriteAdvDone
	push	xix
	push	xde
	push	xhl
	ld	hl, (32372:16)
	ld	de, hl
	calr	Util_ExtractAndShiftBits
	ld	wa, (xix+3)
	ld	(32372:16), wa
	ld	wa, 6:i3
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

	calr Util_ExtractAndShiftBits

	ld hl, (32374:16)

	stb_dri A, 0x07, 0xf0, 0xec

	pop xhl

	pop xix

	ret



AccPlay_InitAndStartLoop:
	ld (0x7e6f:16), 0x00
	call TempoRingBuf_ReInitAndRet
	or (0x7e79:16), 0x04

	ld a, 0x8:opc

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
	ld wa, 0:i3
	ei 0x06
	ld (0x046a:16), a
	ld (0x0468:16), wa
	ld (0x041f:16), 0x01
	ei 0x00
	jr t, AccPlay_ToggleRet
AccPlay_ToggleRestart:
	ld	(32367:16), 0
	call	TempoRingBuf_ReInitAndRet
	calr	AccPlay_MainUpdateLoop
AccPlay_ToggleRet:
	ret

AccPlay_StopAndReset:
	bit 2, (1056:16)
	jr nz, AccPlay_StopResetRet
	ld wa, 0:i3
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
	ld XWA,NAKA_CLASS_Class
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
	ld XWA,NAKA_CLASS_ResEvent
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
	ld XWA,NAKA_CLASS_ResMethod
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
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003c
	lda xwa, (0xe55210:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0123
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003c
	lda xwa, (0xe55304:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0423
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (0xe55dae:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0103
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0010
	lda xwa, (MidiMenu_NakaProcName_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0403
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5ad8c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0143
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5adac:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0443
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe59c5a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0009
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe5a122:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0309
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe59c6e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x000f
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe5a152:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x030f
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59c7e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0018
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a17a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0318
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59cb2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0019
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a1d4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0319
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe59ce6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x001a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000c
	lda xwa, (0xe5a23a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x031a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe59d1a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0050
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe5a2a8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0350
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe59d6e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0051
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda xwa, (0xe5a350:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0351
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe59d8e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0052
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (NakaData_WidgetTables2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0352
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59db2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0053
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a3f2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0353
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (0xe59dce:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0054
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (NakaObj_MidiCommonSetting_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0354
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (0xe59de6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0055
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0005
	lda xwa, (NakaObj_MidiInOutSetting_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0355
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda xwa, (0xe59dfe:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0056
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda xwa, (NakaObj_MidiPresets_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0356
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda xwa, (0xe59f0e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0057
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda xwa, (0xe5a77c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0357
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xe59f82:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0058
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xe5a906:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0358
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59fda:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0059
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a9ae:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0359
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe59ff6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (NakaObj_MidiComputerConn_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda xwa, (0xe5a012:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda xwa, (NakaObj_MidiPmemOutput_Table:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5a05a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x005c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5aac6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x035c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe5a07e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe5ab12:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5a0e2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xe5ac06:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe5a106:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ec
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
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
	ld	xwa, 5:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 27263056
	call	RegisterMode
	pushw	3
	pushw	229
	pushw	44184
	ld	xwa, 9
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 589824
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44198
	ld	xwa, 15
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 983040
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44208
	ld	xwa, 24
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 1572864
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44222
	ld	xwa, 25
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 1638400
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44234
	ld	xwa, 26
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 1703936
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44250
	ld	xwa, 80
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5242880
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44260
	ld	xwa, 81
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5308416
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44270
	ld	xwa, 82
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5373952
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44280
	ld	xwa, 83
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5439488
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44290
	ld	xwa, 84
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5505024
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44300
	ld	xwa, 85
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5570560
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44312
	ld	xwa, 86
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5636096
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44324
	ld	xwa, 87
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5701632
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44334
	ld	xwa, 88
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5767168
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44346
	ld	xwa, 89
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5832704
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44358
	ld	xwa, 90
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5898240
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44368
	ld	xwa, 91
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 5963776
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44380
	ld	xwa, 92
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 6029312
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44392
	ld	xwa, 215
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 14090240
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44404
	ld	xwa, 216
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 14155776
	call	RegisterTitle
	pushw	3
	pushw	229
	pushw	44416
	ld	xwa, 236
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 15466496
	call	RegisterTitle
	lda	xsp, (xsp+14)
	ret
BitmapBmphk:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapBmphk_ReturnA3
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapBmphk_ReturnA2
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapBmphk_ReturnA1
	ld xhl, 0:i3
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
	cp xbc, EVT_REPAINT
	jr z, TtMdmenu_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdmenu_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdmenu_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtMdmenu_ReturnZero
	or xde, xde
	jr nz, TtMdmenu_ReturnZero
	call GetModeOld
	ld xiz, xhl
	call GetModeNow
	cp xhl, xiz
	jr z, TtMdmenu_ReturnZero
	ld xwa, 0x500001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent

TtMdmenu_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

TtVocalistWorkstation:
	cp xbc, EVT_REPAINT
	jr z, TtVocalist_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtVocalist_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtVocalist_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtVocalist_ReturnZero
	or xde, xde
	jr nz, TtVocalist_ReturnZero
	ld xwa, 0xd70003
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xd7000e
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtVocalist_ReturnZero:
	ld xhl, 0:i3
	ret

AcVocalGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, AcVocalGrid_FuncCallA
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcVocalGrid_ViewAccess
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, AcVocalGrid_StringCopy
	cp xwa, EVT_SHOW
	jr z, AcVocalGrid_DialSetup
	sub xbc, EVT_INDEXSW_UP
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
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl AcVocalGrid_SetDialAndRet
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcVocalGrid_CheckEvent91
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (MidiPart_PageStr_1of3_0x12:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Vocalist_ReturnZeroJmp

AcVocalGrid_CheckEvent91:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl AcVocalGrid_SetDialAndRet
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, AcVocalGrid_CheckEvent91B
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
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
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Vocalist_ReturnZeroJmp

AcVocalGrid_CheckEvent91B:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	Vocalist_ReturnZeroJmp
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	AcVocalGrid_FuncCallB
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
	ld xhl, 0:i3
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
	ld bc, 4:i3
	ldirw
	ld xix, xhl
	lda xbc, (xsp + 12)
	lda xwa, (MidiPart_OctaveStr_m2_0x4:24)
	ld (xsp + 8), xwa
	lda xiy, (xbc + 2)
	cp xhl, EVT_REQUEST_GRID_DRAW
	jrl z, VocalistGrid_CheckHandler
	ld xwa, xix
	sub xwa, EVT_INDEXSW_UP
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
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 16
	ld	qwa, 0
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	cpw	(xhl), 1
	jr	z, VocalistGridCheck_Skip
	cpw	(xhl), 2
	jrl	nz, AcVocalist_ReturnZero
VocalistGridCheck_Skip:
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda	xde, (MidiPart_OctaveStr_m2_0x4:24)
	ld_rrl	xwa, xde, ix
	cp	xwa, 4294967295
	jrl	z, AcVocalist_ReturnZero
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistGridCheck_Join
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xhl, (xsp+12)
	ld	xwa, xde
	srl	xwa, 16
	ld	qwa, 0
	ld	(xhl), wa
	ld	bc, de
	ld	(xhl+2), bc
	cpw	(xhl), 1
	jr	z, VocalistGridCheck_Skip2
	cpw	(xhl), 2
	jrl	nz, AcVocalist_ReturnZero
VocalistGridCheck_Skip2:
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda	xde, (MidiPart_OctaveStr_m2_0x4:24)
	ld_rrl	xwa, xde, ix
	cp	xwa, 4294967295
	jrl	z, AcVocalist_ReturnZero
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	ldw	bc, 65535
	ld	de, 2:i3
VocalistGridCheck_Join:
	call	MainLswAdd
	jrl	AcVocalist_ReturnZero
	ld	(xsp+4), xbc
	ld	xhl, xiy
	ldw	(xiy), 0
	ld	xix, (xsp+8)
	ld	xiz, xde
	ld	xiy, xde
	jr	VocalistGridCheck_Join3
VocalistGridCheck_Loop:
	ld	qbc, bc
	.byte 0xd7, 0xe6, 0xec, 0x03
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0
	jr	nz, VocalistGridCheck_Skip3
	ld	bc, 1:i3
	jr	VocalistGridCheck_Join2
VocalistGridCheck_Skip3:
	ld	wa, qbc
	inc	4, wa
	ld	qbc, wa
	ld	xwa, (xiy)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0
	jr	nz, VocalistGridCheck_Skip4
	ld	bc, 2:i3
VocalistGridCheck_Join2:
	ld	xwa, (xsp+4)
	ld	(xwa), bc
	jr	VocalistGridCheck_Join4
VocalistGridCheck_Skip4:
	inc	1, bc
	ld	(xhl), bc
VocalistGridCheck_Join3:
	ld	bc, (xhl)
	cp	bc, 12
	jr	lt, VocalistGridCheck_Loop
VocalistGridCheck_Join4:
	lda	xwa, (xsp+20)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xsp+8)
	ld	(xwa+4), xbc
	ld	xwa, (xde)
	lda	xbc, (xde+4)
	sub	xwa, 11520
	cp	xwa, 0
	jrl	c, AcVocalist_ReturnZero
	cp	xwa, 19
	jrl	ugt, AcVocalist_ReturnZero
	add	xwa, xwa
	add	xwa, MidiPart_ColWidthData
	ld	wa, (xwa)
	lda	xix, (VocalistGrid_DispatchData_0x160:24)
	jp_rr 8, xix, wa
	ld	wa, (xbc)
	cp	wa, 16
	jr	z, VocalistGridCheck_Skip5
	cp	wa, 17
	jr	nz, VocalistGridCheck_Skip6
	ld	xwa, MidiPart_OctaveStr_m2_0x84
	jr	VocalistGridCheck_Join5
VocalistGridCheck_Skip5:
	ld	xwa, MidiPart_OctaveStr_m2_0x90
VocalistGridCheck_Join5:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	VocalistGridCheck_Join6
VocalistGridCheck_Skip6:
	inc	1, wa
	pushw	wa
	pushw 231
	pushw 61176
	ld	xwa, (xsp+14)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
VocalistGridCheck_Join6:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw	231
	pushw	61188
	ld	xwa, (xsp+14)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw 231
	pushw 61200
	ld	xwa, (xsp+14)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	wa, (xbc)
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw 231
	pushw 61212
	ld	xwa, (xsp+16)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	wa, (xbc)
	cp	wa, 3:i3
	jr	z, VocalistGridCheck_Skip9
	cp	wa, 2:i3
	jr	z, VocalistGridCheck_Skip8
	cp	wa, 1:i3
	jr	z, VocalistGridCheck_Skip7
	cp	wa, 0:i3
	jr	nz, VocalistGridCheck_Skip10
	ld	xwa, 15200040
	jr	VocalistGridCheck_Join7
VocalistGridCheck_Skip7:
	ld	xwa, MidiPart_OctaveStr_m2_0xD8
	jr	VocalistGridCheck_Join7
VocalistGridCheck_Skip8:
	ld	xwa, MidiPart_OctaveStr_m2_0xE4
	jr	VocalistGridCheck_Join7
VocalistGridCheck_Skip9:
	ld	xwa, MidiPart_OctaveStr_m2_0xF0
VocalistGridCheck_Join7:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
VocalistGridCheck_Skip10:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	wa, (xbc)
	cp	wa, 120
	jr	z, VocalistGridCheck_Skip11
	cp	wa, 121
	jr	nz, VocalistGridCheck_Skip12
	ld	xwa, MidiPart_OctaveStr_m2_0xFC
	jr	VocalistGridCheck_Join8
VocalistGridCheck_Skip11:
	ld	xwa, MidiPart_OctaveStr_m2_0x108
VocalistGridCheck_Join8:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	VocalistGridCheck_Join9
VocalistGridCheck_Skip12:
	pushw	wa
	pushw 231
	pushw 61296
	ld	xwa, (xsp+14)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
VocalistGridCheck_Join9:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	bc, (xbc)
	ld	de, bc
	and	de, 127
	ld	wa, de
	exts	xwa
	divs	wa, 12
	sla	wa, 2
	lda	xhl, (MidiPart_OctaveTable:24)
	ld_rrl	xwa, xhl, wa
	push	xwa
	exts	xde
	divs	de, 12
	ld	wa, qde
	sla	wa, 2
	lda	xde, (MidiPart_NoteNameTable:24)
	ld_rrl	xwa, xde, wa
	push	xwa
	and	bc, 128
	sra	bc, 7
	sla	bc, 2
	lda	xwa, (MidiPart_PageStr_1of3_0x50:24)
	ld_rrl	xwa, xwa, bc
	push	xwa
	pushw 231
	pushw 61308
	ld	xwa, (xsp+24)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
	ld	xwa, MidiPart_OctaveStr_m2_0x12E
	cpw	(xbc), 0
	jr	z, VocalistGridCheck_Skip13
	ld	xwa, MidiPart_OctaveStr_m2_0x128
VocalistGridCheck_Skip13:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15
VocalistGrid_CheckHandler:
	ld (xsp + 4), xbc
	ld xwa, xde
	srl xwa, 16
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
	call	AcApcToggleProc_Helper
	cp	hl, 16
	jr	z, VocalistGridCheck_Skip14	; -> 0xF73901
	cp	hl, 17
	jr	nz, VocalistGridCheck_Skip15	; -> 0xF73913
	ld	xwa, MidiPart_OctaveStr_m2_0x134
	jr	VocalistGridCheck_Join10	; -> 0xF73906
VocalistGridCheck_Skip14:
	ld	xwa, MidiPart_OctaveStr_m2_0x140
VocalistGridCheck_Join10:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	VocalistGridCheck_Join11	; -> 0xF73930
VocalistGridCheck_Skip15:
	ld	xwa, 11520
	call	AcApcToggleProc_Helper
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61352
	lda	xwa, (xsp+26)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
VocalistGridCheck_Join11:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11522
	call	AcApcToggleProc_Helper
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61364
	lda	xwa, (xsp+26)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11524
	call	AcApcToggleProc_Helper
	inc	1, hl
	pushw	hl
	pushw	231
	pushw	61376
	lda	xwa, (xsp+26)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11526
	call	AcApcToggleProc_Helper
	sla	hl, 2
	lda	xwa, (MidiPart_NoteNameTable:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61388
	lda	xwa, (xsp+28)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11528
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, VocalistGridCheck_Skip18	; -> 0xF73A04
	cp	hl, 2:i3
	jr	z, VocalistGridCheck_Skip17	; -> 0xF739FD
	cp	hl, 1:i3
	jr	z, VocalistGridCheck_Skip16	; -> 0xF739F6
	cp	hl, 0:i3
	jr	nz, VocalistGridCheck_Skip19	; -> 0xF73A14
	ld	xwa, MidiPart_OctaveStr_m2_0x17C
	jr	VocalistGridCheck_Join12	; -> 0xF73A09
VocalistGridCheck_Skip16:
	ld	xwa, MidiPart_OctaveStr_m2_0x188
	jr	VocalistGridCheck_Join12	; -> 0xF73A09
VocalistGridCheck_Skip17:
	ld	xwa, MidiPart_OctaveStr_m2_0x194
	jr	VocalistGridCheck_Join12	; -> 0xF73A09
VocalistGridCheck_Skip18:
	ld	xwa, MidiPart_RecvTransStr
VocalistGridCheck_Join12:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
VocalistGridCheck_Skip19:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11530
	call	AcApcToggleProc_Helper
	lda	xbc, (xsp+20)
	cp	hl, 120
	jr	z, VocalistGridCheck_Skip20	; -> 0xF73A44
	cp	hl, 121
	jr	nz, VocalistGridCheck_Skip21	; -> 0xF73A53
	ld	xwa, MidiPart_RecvTransStr_0xC
	jr	VocalistGridCheck_Join13	; -> 0xF73A49
VocalistGridCheck_Skip20:
	ld	xwa, MidiPart_AfterStr
VocalistGridCheck_Join13:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	VocalistGridCheck_Join14	; -> 0xF73A6E
VocalistGridCheck_Skip21:
	ld	xwa, 11530
	call	AcApcToggleProc_Helper
	pushw	hl
	pushw	231
	pushw	61472
	lda	xwa, (xsp+26)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
VocalistGridCheck_Join14:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11533
	call	AcApcToggleProc_Helper
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (MidiPart_OctaveTable:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	ld	xwa, 11533
	call	AcApcToggleProc_Helper
	exts	xhl
	divs	hl, 12
	ld	wa, qhl
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, 11534
	call	AcApcToggleProc_Helper
	sla	hl, 2
	lda	xwa, (MidiPart_PageStr_1of3_0x50:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61484
	lda	xwa, (xsp+36)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, 11537
	call	AcApcToggleProc_Helper
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (MidiPart_OctaveTable:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	ld	xwa, 11537
	call	AcApcToggleProc_Helper
	exts	xhl
	divs	hl, 12
	ld	wa, qhl
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, 11538
	call	AcApcToggleProc_Helper
	sla	hl, 2
	lda	xwa, (MidiPart_PageStr_1of3_0x50:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	pushw	231
	pushw	61492
	lda	xwa, (xsp+36)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jr	VocalistGridCheck_Join15	; -> 0xF73BA6
	ld	xwa, (xsp+4)
	ld	wa, (xwa)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld_rrl	xwa, xde, bc
	call	AcApcToggleProc_Helper
	ld	xwa, MidiPart_AfterStr_0x2E
	cp	hl, 0:i3
	jr	z, VocalistGridCheck_Skip22	; -> 0xF73B8D
	ld	xwa, MidiPart_AfterStr_0x28
VocalistGridCheck_Skip22:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
VocalistGridCheck_Join15:
	call	SendEvent
AcVocalist_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 48)
	ret

AcVocalistListBoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_SELE_DRAW
	jr z, AcVocalist_ListSetup
	ld xwa, xiz
	call InheritedProc
	jr AcVocalist_ListCase2

; AcVocalist list setup
AcVocalist_ListSetup:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
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
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jr	VocalistGridCheck_Join16
	ld	xwa, 0xd7000c
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 1:i3
VocalistGridCheck_Join16:
	call	SendEvent

; AcVocalist list case 1
AcVocalist_ListCase1:
	ld xhl, 0:i3

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
	ld bc, 4:i3
	ldirw
	cp xiz, EVT_PARA_DRAW
	jr z, PsHarm_DrawHandler
	cp xiz, EVT_SW_IN
	jr z, PsHarm_CheckMode
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	jrl PsHarm_CleanupAndRet

PsHarm_CheckMode:
	ld xwa, 0xd7000a
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
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
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
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
	ld de, 7:i3
	jr PsHarm_DrawInactiveBox

PsHarm_InactiveColorA:
	ldw bc, 0xc1
	ld de, 7:i3

PsHarm_DrawInactiveBox:
	call DrawDesignBox
	ld xwa, 0xd7000a
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
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
	ld xhl, 0:i3

PsHarm_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 24)
	ret

HarmOnOffFunc:
	ld xhl, 0:i3
	ret

VocalistPage1OKFunc:
	push xiz
	ld xhl, xde
	cp xbc, EVT_SW_IN
	jr nz, VocalistP1OK_Case0
	ld xwa, 0xd7000a
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	ld iz, hl
	extz xiz
	ld xwa, 0xd7000c
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	extz xhl
	sll xhl, 16
	add xhl, xiz
	ld xwa, NAKA_MAINFUNC_MainVocalistPage1OKFunc
	ld xbc, EVT_VST_PST_OK
	ld xde, xhl
	call MainFuncCall

; VocalistPage1OK case 0
VocalistP1OK_Case0:
	ld xhl, 0:i3
	pop xiz
	ret

VocalistPage2OKFunc:
	cp xbc, EVT_SW_IN
	jr nz, VocalistP1OK_Case1
	ld xwa, NAKA_MAINFUNC_MainVocalistPage2OKFunc
	ld xbc, EVT_VST_SEND_OK
	ld xde, 0:i3
	call MainFuncCall

; VocalistPage1OK case 1
VocalistP1OK_Case1:
	ld xhl, 0:i3
	ret

MainVocalistPage1OKFunc:
	dec 4, xsp
	ld (xsp), xde
	cp xbc, EVT_VST_PST_OK
	jr nz, VocalistPage_Handler
	ld xwa, (xsp)
	ld de, wa
	extz wa
	ld bc, wa
	cp de, 5:i3
	jr ugt, VocalistPage_Handler
	add de, de
	lda xix, (MidiPart_HarmLocalStr_0x24:24)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda xix, (VocalistPage1OK_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MainVocalistPage1OKFunc dispatch
VocalistPage1OK_Dispatch:
	call	VocalistPage2OKFunc_Helper2
	call	16602124
	ld	(46928:16), 11
	call	VocalistPage2OKFunc_Helper
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip
	ld	xwa, 119808
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join
VocalistPage2OKFunc_Skip:
	ld	xwa, 119808
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join:
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
VocalistPage2OKFunc_Join2:
	call	ApPostEvent
	ld	(32420:16), 1
	call	16601121
	ld	(32420:16), 0
VocalistPage_Handler:
	ld xhl, 0:i3
	inc 4, xsp
	ret

VocalistPage1_DispatchData:
	call	VocalistPage2OKFunc_Helper2
	call	16602124
	ld	(46928:16), 2
	call	VocalistPage2OKFunc_Helper
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip2
	ld	xwa, 98304
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join3
VocalistPage2OKFunc_Skip2:
	ld	xwa, 98304
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join3:
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jr	VocalistPage2OKFunc_Join2
	ld	wa, bc
	call	VocalistPage2OKFunc_Helper2
	call	16602124
	ld	(46928:16), 24
	call	VocalistPage2OKFunc_Helper
	ld	xwa, 16897
	ld	bc, 3:i3
	ld	de, 2:i3
	call	16566832
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip3
	ld	xwa, 101376
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join4
VocalistPage2OKFunc_Skip3:
	ld	xwa, 101376
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join4:
	call	16566832
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jrl	VocalistPage2OKFunc_Join2
	ld	wa, bc
	call	VocalistPage2OKFunc_Helper2
	call	16602124
	ld	(46928:16), 1
	call	VocalistPage2OKFunc_Helper
	ld	wa, 1:i3
	call	SmfMedley_RawData
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jrl	VocalistPage2OKFunc_Join2
MainVocalistPage2OKFunc:
	cp	xbc, EVT_VST_SEND_OK
	jr	nz, 28
	call	16601121
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	call	ApPostEvent
VocalistPage2_ReturnZero:
	ld xhl, 0:i3
	ret

AccPlay_GetCurrentPart:
	ld	l, (32420:16)
	ret
RevSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_I_AM_SELECTED
	jr z, RevSel_HandleDial
	cp xbc, EVT_DRAW
	jr z, RevSel_HandleConfirm
	cp xbc, EVT_SHOW
	jr z, RevSel_HandleInit
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr z, RevSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl RevSel_CleanupAndRet

RevSel_ReturnOne:
	ld xhl, 1:i3
	jrl RevSel_CleanupAndRet

RevSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, 0:i3
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, RevSel_NoPresetMatch
	extz xhl
	add xhl, 0x10000
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	ld xde, xhl
	jr RevSel_SendAndRet

RevSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 1:i3
	jr RevSel_SendAndRet

RevSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, MidiPart_HarmLocalStr_0x30

RevSel_SendAndRet:
	call SendEvent
	jr RevSel_ReturnZero

RevSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 1:i3
	jr nz, RevSel_ReturnZero
	ld xwa, (xsp + 4)
	ld de, wa
	extz xde
	ld xwa, NAKA_MAINFUNC_MainRevEqPresetLoad
	ld xbc, EVT_REV_LOAD
	call MainFuncCall

RevSel_ReturnZero:
	ld xhl, 0:i3

RevSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

EqSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_LSW_DATA
	jrl z, EqSel_HandleParamChange
	cp xbc, EVT_I_AM_SELECTED
	jrl z, EqSel_HandleDial
	cp xbc, EVT_DRAW
	jr z, EqSel_HandleConfirm
	cp xbc, EVT_SHOW
	jr z, EqSel_HandleInit
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr z, EqSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl EqSel_CleanupAndRet

EqSel_ReturnOne:
	ld xhl, 1:i3
	jrl EqSel_CleanupAndRet

EqSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, 1:i3
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, EqSel_NoPresetMatch
	extz xhl
	add xhl, 0x20000
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	ld xde, xhl
	jr EqSel_SendPresetEvent

EqSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 2:i3

EqSel_SendPresetEvent:
	call	SendEvent
	ld	xwa, 16390
	call	AcApcToggleProc_Helper
	exts	xhl
	ld	xwa, 1638411
	ld	xbc, EVT_SET_PARAM
	ld	xde, xhl
	jrl	EqSel_SendEvent
EqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, MidiPart_HarmLocalStr_0x36
	jr EqSel_SendEvent

EqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 2:i3
	jr nz, RevEqFunc_ReturnZero
	ld xwa, 0x19000b
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	extz xhl
	sll xhl, 16
	ld xwa, (xsp + 4)
	extz xwa
	add xwa, xhl
	ld (xsp + 4), xwa
	ld xwa, NAKA_MAINFUNC_MainRevEqPresetLoad
	ld xbc, EVT_EQ_LOAD
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
	ld xbc, EVT_SET_PARAM

EqSel_SendEvent:
	call SendEvent

RevEqFunc_ReturnZero:
	ld xhl, 0:i3

EqSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

RevEqSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_LSW_DATA
	jrl z, RevEqSel_HandleParamChange
	cp xbc, EVT_I_AM_SELECTED
	jrl z, RevEqSel_HandleDial
	cp xbc, EVT_DRAW
	jr z, RevEqSel_HandleConfirm
	cp xbc, EVT_SHOW
	jr z, RevEqSel_HandleInit
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr z, RevEqSel_ReturnOne
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl RevEqSel_CleanupAndRet

RevEqSel_ReturnOne:
	ld xhl, 1:i3
	jrl RevEqSel_CleanupAndRet

RevEqSel_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, 2:i3
	call SoundPreset_FindMatch
	cp hl, 0xffff
	jr z, RevEqSel_NoPresetMatch
	extz xhl
	add xhl, 0x30000
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	ld xde, xhl
	jr RevEqSel_SendPresetEvent

RevEqSel_NoPresetMatch:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 3:i3

RevEqSel_SendPresetEvent:
	call	SendEvent
	ld	xwa, 16390
	call	AcApcToggleProc_Helper
	exts	xhl
	ld	xwa, 1703946
	ld	xbc, EVT_SET_PARAM
	ld	xde, xhl
	jrl	RevEqSel_SendEvent
RevEqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, MidiPart_HarmLocalStr_0x3C
	jr RevEqSel_SendEvent

RevEqSel_HandleDial:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 3:i3
	jr nz, EqFunc_ReturnZero
	ld xwa, 0x1a000a
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	extz xhl
	sll xhl, 16
	ld xwa, (xsp + 4)
	extz xwa
	add xwa, xhl
	ld (xsp + 4), xwa
	ld xwa, NAKA_MAINFUNC_MainRevEqPresetLoad
	ld xbc, EVT_REV_EQ_LOAD
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
	ld xbc, EVT_SET_PARAM

RevEqSel_SendEvent:
	call SendEvent

EqFunc_ReturnZero:
	ld xhl, 0:i3

RevEqSel_CleanupAndRet:
	pop xiz
	inc 4, xsp
	ret

EqOnOffFunc:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0x4006
	ld bc, hl
	ld de, 1:i3
	call MainLswPut
	ld xhl, 0:i3
	ret

RevEqOnOffFunc:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0x4006
	ld bc, hl
	ld de, 1:i3
	call MainLswPut
	ld xhl, 0:i3
	ret

MainRevEqPresetLoad:
	ld xhl, xbc
	extz de
	cp xhl, EVT_REV_EQ_LOAD
	jr z, RevEqPreset_TypeRevEq
	cp xhl, EVT_EQ_LOAD
	jr z, RevEqPreset_TypeEq
	cp xhl, EVT_REV_LOAD
	jr nz, RevEqPreset_ReturnZero
	ld wa, 0:i3
	ld bc, de
	jr MainRevEqPresetLoad_DoLoad

RevEqPreset_TypeEq:
	ld wa, 1:i3
	ld bc, de
	jr MainRevEqPresetLoad_DoLoad

RevEqPreset_TypeRevEq:
	ld wa, 2:i3
	ld bc, de

MainRevEqPresetLoad_DoLoad:
	call SoundPreset_Dispatch

RevEqPreset_ReturnZero:
	ld xhl, 0:i3
	ret

AcGMOnOffBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SHOW
	jr z, AcGMOnOff_InitHandler
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr AcGMOnOff_CleanupAndRet

AcGMOnOff_InitHandler:
	ld	xwa, (xsp+12)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	ld	xwa, (xiz+50)
	ld	(xwa), hl
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	call	InheritedProc
	ld	xhl, 0:i3
AcGMOnOff_CleanupAndRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret

StsAttentionCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsAttention_ReturnZero
	lda xhl, (GMMode_AttentionTable:24)
	ret

StsAttention_ReturnZero:
	ld xhl, 0:i3
	ret

StsGMOnCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsGMOn_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x204:24)
	ret

StsGMOn_ReturnZero:
	ld xhl, 0:i3
	ret

StsGMOffCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsGMOff_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x47C:24)
	ret

StsGMOff_ReturnZero:
	ld xhl, 0:i3
	ret

StsAreYouSureCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsAreYouSure_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x494:24)
	ret

StsAreYouSure_ReturnZero:
	ld xhl, 0:i3
	ret

GMOKFunc:
	ld l, (0x0340ea:24)
	cp l, 2:i3
	jr z, GMOK_ConfirmDialog
	cp l, 1:i3
	jr z, GMOK_ConfirmDialog
	cp l, 0:i3
	jr nz, GMOK_ReturnZero
	calr GMYesFunc
	jr GMOK_ReturnZero

GMOK_ConfirmDialog:
	ld xwa, 0x580001
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, GMOK_PostNoDialog
	ld xwa, 0x580005
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr GMOK_PostEvent

GMOK_PostNoDialog:
	ld xwa, 0x58000d
	ld xbc, EVT_SHOW
	ld xde, 0:i3

GMOK_PostEvent:
	call PostEvent

GMOK_ReturnZero:
	ld xhl, 0:i3
	ret

GMNoFunc:
	ld xwa, 0xffffffff
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld xhl, 0:i3
	ret

GMYesFunc:
	ld	xwa, 5767169
	ld	xbc, EVT_GET_PARAM
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, 192
	ld	bc, hl
	ld	de, 1:i3
	call	MainLswPut
	ld	xwa, 4294967295
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	PostEvent
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	call	PostEvent
	ld	xhl, 0:i3
	ret
TtMdGm:
	cp xbc, EVT_SHOW
	jr nz, TtMdGm_ReturnZero
	call GetTitleOld
	cp xhl, TITLE_MESAGE
	jr nz, TtMdGm_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_NORMAL
	call PostEvent

TtMdGm_ReturnZero:
	ld xhl, 0:i3
	ret

StsSplitCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsSplit_ReturnZero
	lda xhl, (GMMode_Attention_English2_0x514:24)
	ret

StsSplit_ReturnZero:
	ld xhl, 0:i3
	ret

SplitPointFunc:
	lda	xsp, (xsp-12)
	push	xiz
	ld	(xsp+8), xde
	ld	xde, xbc
	ld	(xsp+12), xwa
	ld	xiy, SplitPoint_NoteEntry_C_Code_0x38
	lda	xix, (xsp+4)
	ldiw
	ldiw
	cp	xde, EVT_GET_SMALL_STEP
	jrl	z, ParamFunc_ReturnOne
	cp	xde, EVT_GET_LARGE_STEP
	jrl	z, ParamFunc_ReturnOne
	cp	xde, EVT_GET_LSW_OUTPUT
	jrl	z, ParamFunc_ReturnOne
	cp	xde, EVT_GET_LSW_ADDRESS
	jrl	z, SplitPoint_ReturnParamId
	cp	xde, EVT_GET_LSW_STRING
	jrl	z, SplitPoint_HandleNoteEvt
	cp	xde, EVT_DRAW_KEY
	jrl	nz, SplitPoint_ReturnZero
	ld	xwa, 16768
	ld	bc, 0:i3
	ld	de, 1:i3
	call	16566832
	ld	xwa, (xsp+8)
	ldfr_berp	a, 251	; ld qizh,a
	cp_erpb	251, 36	; cp qizh,0x24
	jr	c, SplitPoint_ClampToMiddle
	cp_erpb	251, 96	; cp qizh,0x60
	jr	ule, SplitPoint_StartDraw
SplitPoint_ClampToMiddle:
	ldi_erpb 0xfb, 0x3c

SplitPoint_StartDraw:
	ld iz, 0:i3
	jr Draw_keybed_maybe_for_indicating_split_point

SplitPoint_DrawOctaveLoop:
	pushw 0x34
	ld xbc, Bitmap_SplitPoint_B
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
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
	lda xde, (SplitPoint_NoteEntry_C_Code_0x4:24)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	pushw 0x34
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
	inc 1, iz
	cp iz, 5:i3
	jr nc, SplitPoint_UpdateScreen

SplitPoint_FillRemainingLoop:
	lda xwa, (xsp + 4)
	pushw 0x34
	ld xbc, Bitmap_SplitPoint_no_split
	ldw de, 0x39
	call DrawBitmapSPFast
	addiw_da (xsp + 4), 0x38
	inc 1, iz
	cp iz, 5:i3
	jr c, SplitPoint_FillRemainingLoop

SplitPoint_UpdateScreen:
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
	call SetNeedUpdate
	ld xwa, 0xffffffff
	ld xbc, EVT_RESET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent

SplitPoint_ReturnZero:
	ld xhl, 0:i3
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
	lda	xbc, (SplitPoint_NoteNameTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw 231
	pushw 63514
	ld	xwa, (xde+8)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+14)
	ld	xwa, (xsp+8)
	ld	de, (xwa+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_DRAW_KEY
	call	ApFuncCall
	ld	xhl, (xsp+12)
	jr	ParamFunc_CommonExit
SplitPoint_ReturnParamId:
	ld xhl, 0x4181
	jr ParamFunc_CommonExit

ParamFunc_ReturnOne:
	ld xhl, 1:i3

ParamFunc_CommonExit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AccWrap_SetMinVelocity:
	ld c, a

	; cpdi8 (0x8d38), 236 (v7 patched)
	cpdi8	(35996), 236

	ret nz

	cp c, 0x15

	ret c

	cp c, 0x6c

	ret ugt

	extz bc

	ld xwa, 0x4181

	ld de, 1:i3

	call	16566832

	ret



R12OctaveFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, R12Octave_ReturnStepSize
	cp xbc, EVT_GET_LARGE_STEP
	jrl z, R12Octave_ReturnStepSize
	cp xbc, EVT_GET_LSW_OUTPUT
	jrl z, R12Octave_ReturnOne
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, R12Octave_ReturnParamId
	cp xbc, EVT_GET_LSW_STRING
	jr z, R12Octave_HandleNoteEvt
	ld xhl, 0:i3
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
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, 4294967295
	ld	xbc, EVT_RESET_INTERRUPT_TIME
	ld	xde, 0:i3
	call	SendEvent
	ld	xhl, xiz
	jr	R12Octave_PopIzRet
R12Octave_ReturnParamId:
	ld xhl, 0x40e0
	jr R12Octave_PopIzRet

R12Octave_ReturnOne:
	ld xhl, 1:i3
	jr R12Octave_PopIzRet

R12Octave_ReturnStepSize:
	ld xhl, 0xc

R12Octave_PopIzRet:
	pop xiz
	ret


; Computer Interface routines (Connection config and PCG Output)

; --- Computer Interface & SysEx ---
