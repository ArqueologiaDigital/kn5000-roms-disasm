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
	ld (0x7dfd:16), 95
	ldw (0x7e02:16), 9
	ldw (0x7e04:16), 72
	ld (0x7e06:16), 16
	ld (0x7e07:16), 1
	ld a, (0x7e08:16)
	ld (0x7e0a:16), a
	ld xhl, 0x7aec
	ld xbc, 0x7d6c
	calr SeqEvt_ProcessReadLoop
	ld a, (0x7e0a:16)
	ld (0x7e08:16), a
	ld (0x7e07:16), 2
	ld a, (0x7e09:16)
	ld (0x7e0a:16), a
	ld xhl, 0x7bec
	ld xbc, 0x7db4
	calr SeqEvt_ProcessReadLoop
	ld a, (0x7e0a:16)
	ld (0x7e09:16), a
	ld a, (0x7dfd:16)
	ld (0x7dfc:16), a
	ret

SeqEvt_ProcessReadLoop:
	ld ix, (xhl + 6)
	ld (0x7e0f:16), ix

SeqEvt_ProcessLoop_Check:
	cp (xhl + 4), ix
	jr nz, SeqEvt_ClassifyEventType
	jp SeqEvt_ProcessLoopRet

SeqEvt_ClassifyEventType:
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld w, a
	cp a, 0x90
	jr nz, SeqEvt_CheckType91
	ld (0x7e0e:16), 5
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckType91:
	cp a, 0x91
	jr nz, SeqEvt_CheckTypeC0
	ld (0x7e0e:16), 7
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckTypeC0:
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqEvt_CheckTypeD0
	ld (0x7e0e:16), 4
	jr SeqEvt_ReadAndDispatchEntry

SeqEvt_CheckTypeD0:
	cp a, 0xd0
	jr z, SeqEvt_TypeD0_SetCount
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	ld (0x7e0f:16), ix
	jr SeqEvt_ProcessLoop_Check

SeqEvt_TypeD0_SetCount:
	ld (0x7e0e:16), 2

SeqEvt_ReadAndDispatchEntry:
	ld	a, (xhl+ix)
	ld (0x7e11:16), ix
	calr SeqEvtBuf_AdvanceReadPos
	ld (0x7e0f:16), ix
	cp a, (1132:16)
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
	ld	w, (xhl+ix)
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	xor ix, ix

SeqEvt_SlotScanLoop:
	cp ix, (0x7e04:16)
	jr c, SeqEvt_CheckSlotActive
	jr SeqEvt_AfterSlotScan

SeqEvt_CheckSlotActive:
	bit	7, (xhl+ix)
	jr z, SeqEvt_AdvanceSlotIndex
	ld xiy, xhl
	and xix, 0xffff
	add xiy, xix
	cp (xiy + 2), w
	jr z, SeqEvt_SlotMatchFound

SeqEvt_AdvanceSlotIndex:
	add ix, (0x7e02:16)
	jr SeqEvt_SlotScanLoop

SeqEvt_SlotMatchFound:
	calr SeqEvt_WriteNoteOff

SeqEvt_AfterSlotScan:
	popw wa
	xor ix, ix

SeqEvt_FindFreeSlotLoop:
	cp ix, (0x7e04:16)
	jr nc, SeqEvt_AllocateNewSlot
	bit	7, (xhl+ix)
	jr nz, SeqEvt_AdvanceFreeSlotIdx
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	jr SeqEvt_WriteEventAndContinue

SeqEvt_AdvanceFreeSlotIdx:
	add ix, (0x7e02:16)
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
	ld	a, (xhl+ix)
	and	(xhl+ix), 0x7f
	and a, 0xf0
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld a, w
	calr SeqEvtBuf_WriteBytePreserve
	ld a, 0x0:opc
	calr SeqEvtBuf_WriteBytePreserve
	ret

SeqEvt_WriteNoteOnRotating:
	push xwa
	xor xwa, xwa
	ld a, (0x7e0a:16)
	ld xix, SeqEvt_RotationOffsetTable
	add xix, xwa
	ld ix, (xix)
	ld	a, (xhl+ix)
	and	(xhl+ix), 0x7f
	ld iz, ix
	inc 2, ix
	ld	w, (xhl+ix)
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	and a, 0xf0
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld a, w
	calr SeqEvtBuf_WriteBytePreserve
	ld a, 0x0:opc
	calr SeqEvtBuf_WriteBytePreserve
	ld ix, iz
	pop xwa
	add (0x7e0a:16), 2
	ld a, (0x7e0a:16)
	cp a, (0x7e06:16)
	jr c, SeqEvt_RotateIndexDone
	ld (0x7e0a:16), 0

SeqEvt_RotateIndexDone:
	ld a, w
	and a, 0xf0
	ret

SeqEvt_WriteVoiceParams:
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld a, w
	ld	(xhl+ix), a
	inc 1, ix
	ld a, 0x0:opc
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ex16 iz, ix
	ld ix, (0x7e0f:16)
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	calr SeqEvtBuf_WriteBytePreserve
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ex16 iz, ix
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	calr SeqEvtBuf_WriteBytePreserve
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	push xwa
	ex16 iz, ix
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld	w, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ex16 iz, ix
	add wa, (1134:16)
	cp a, 0x60
	jr c, SeqEvt_AdjustNoteOctave
	inc 1, w
	sub a, 0x60

SeqEvt_AdjustNoteOctave:
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), wa
	inc 2, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	cp wa, (0x7dfe:16)
	jr nc, SeqEvt_WriteRemainingParams
	ld (0x7dfe:16), wa

SeqEvt_WriteRemainingParams:
	pop xwa
	ex16 iz, ix
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld (0x7e0f:16), ix
	ex16 iz, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	cp w, 0x90
	jr z, SeqEvt_UpdateReadPosition
	ex16 iz, ix
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld (0x7e0f:16), ix
	ex16 iz, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ex16 iz, ix
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld (0x7e0f:16), ix
	ex16 iz, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)
	ld	(xhl+ix), a
	inc 1, ix
	ld (0x7e13:16), xhl
	ld xhl, xbc
	ld xbc, (0x7e13:16)

SeqEvt_UpdateReadPosition:
	ld ix, (0x7e0f:16)
	ld (xhl + 6), ix
	ret

SeqEvt_HandleControlEvent:
	ld w, a
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld ix, (0x7e0f:16)
	cp w, 0xd0
	jr nz, SeqEvt_HandleExtendedCtrl
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	jr SeqEvt_SaveReadPosAndRet

SeqEvt_HandleExtendedCtrl:
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	calr SeqEvtBuf_WriteBytePreserve
	pushw bc
	ld	c, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld	a, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	and a, 0xf
	bit 0, c
	jr z, SeqEvt_SetExtendedFlag
	or a, 0x10

SeqEvt_SetExtendedFlag:
	popw bc
	calr SeqEvtBuf_WriteBytePreserve
	ld a, 0xd0:opc
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld a, 0x7:opc
	calr SeqEvtBuf_WriteBytePreserve
	ld	w, (xhl+ix)
	calr SeqEvtBuf_AdvanceReadPos
	ld a, 0x0:opc
	bit 0, w
	jr z, SeqEvt_WriteSustainValue
	ld a, 0x7f:opc

SeqEvt_WriteSustainValue:
	calr SeqEvtBuf_WriteBytePreserve

SeqEvt_SaveReadPosAndRet:
	ld (0x7e0f:16), ix
	ld (xhl + 6), ix
	ret

SeqEvt_CalcTempoOffset:
	sub a, (1132:16)
	cp a, (0x7dfd:16)
	jr nc, SeqEvt_UpdateMinTempo
	ld (0x7dfd:16), a

SeqEvt_UpdateMinTempo:
	ld iy, (0x7e11:16)
	ld	(xhl+iy), a
	xor wa, wa
	ld a, (0x7e0e:16)
	add wa, (0x7e0f:16)
	ld (0x7e0f:16), wa
	ld ix, wa
	cp ix, (xhl + 2)
	jr ugt, SeqEvt_HandleBufferWrap
	jr SeqEvt_CalcTempoRet

SeqEvt_HandleBufferWrap:
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 0:8)
	ld (0x7e0f:16), ix

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
; Read by SeqEvt_WriteNoteOnRotating (0xF70CAB): A = byte
; at 0x7E0A (a rotating index advanced by 2 per call and wrapped at the
; byte at 0x7E06), IX = word [this + A]; the slot's bytes +0 and +2 are
; then read at (XHL+IX).  Stride 2, 8 entries (16 B up to
; SeqEvt_InitVoiceScan).  TYPED 2026-09-25 (lane seqeng).
	.short 0x0000, 0x0009, 0x0012, 0x001b, 0x0024, 0x002d, 0x0036, 0x003f

SeqEvt_InitVoiceScan:
	ldw (0x7e00:16), 0xff5f
	ldw (0x7e02:16), 9
	ldw (0x7e04:16), 72
	ld (0x7e07:16), 1
	ld xhl, 0x7d6c
	calr Voice_ScanSlotMetric
	ld (0x7e07:16), 2
	ld xhl, 0x7db4
	calr Voice_ScanSlotMetric
	ld wa, (0x7e00:16)
	ld (0x7dfe:16), wa
	jr SeqEvt_VoiceScanDone

SeqEvt_VoiceScanDone:
	ret

Voice_ScanSlotMetric:
	xor iy, iy

Voice_ScanLoop:
	cp iy, (0x7e04:16)
	jr c, Voice_CheckSlotBit
	jp Voice_ScanLoopDone

Voice_CheckSlotBit:
	bit	7, (xhl+iy)
	jr nz, Voice_ReadSlotParams
	jr Voice_ParamComplete

Voice_ReadSlotParams:
	ld ix, iy
	ld	a, (xhl+ix)
	ld (0x7e0b:16), a
	inc 2, ix
	ld	a, (xhl+ix)
	ld (0x7e0c:16), a
	inc 1, ix
	ld	a, (xhl+ix)
	ld (0x7e0d:16), a
	inc 1, ix
	ld	wa, (xhl+ix)
	cp wa, (1134:16)
	jr gt, Voice_SubtractBaseFreq
	ex16 iy, iz
	ld iy, (xhl + 4)
	ld a, 0xf0:opc
	and a, (0x7e0b:16)
	or a, (0x7e07:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld a, (0x7e0c:16)
	calr SeqEvtBuf_WriteBytePreserve
	ld a, 0x0:opc
	calr SeqEvtBuf_WriteBytePreserve
	ex16 iy, iz
	and	(xhl+iy), 0x7f
	jr Voice_ParamComplete

Voice_SubtractBaseFreq:
	sub wa, (1134:16)
	bit 7, a
	jr z, Voice_StoreMetricValue
	add a, 0x60

Voice_StoreMetricValue:
	ld	(xhl+ix), wa
	cp wa, (0x7e00:16)
	jr nc, Voice_ParamComplete
	ld (0x7e00:16), wa

Voice_ParamComplete:
	add iy, (0x7e02:16)
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
	ld xix, Voice_DecodeNoteChannel_Data
	ld	hl, (xix+hl)
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
	ld xix, Voice_DecodeNonPercussion_Data
	ld	hl, (xix+hl)
	pop xix

Voice_DecodeRet:
	ret

Voice_NoteChannelTable1:
; PORTED 2026-09-25 (lane seqeng) from v10: Voice_NoteChannelTable1 ..
; Voice_NoteParamTable was spelled here as ~1,350 lines of nop/ei/reti/halt
; and .byte; the ROM bytes are identical to v10's apart from the absolute
; operands of the decode routines, which are symbolic.  v9 holds these bytes at the SAME addresses as v10, so the addresses
; quoted below hold for v9 too.
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
Voice_DecodeNonPercussion_Data:
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
Voice_DecodeNoteChannel_Data:
	.short 0x000d, 0x010d, 0x020d, 0x030d, 0x040d, 0x050d, 0x000e, 0x010e
	.short 0x020e, 0x030e, 0x040e, 0x050e, 0x000c, 0x000c, 0x000c, 0x000c
; Voice_NoteChannelGrid_Lookup (= Voice_NoteChannelTable1 +0x422, the
; address shared/positional_labels.s still calls Voice_NoteChannelGrid_Lookup;
; its one caller is AccompSeq_ProcessAfterNote in accompseq_routines.s).
; In: L = row (low 4 bits used), H = column (low 3 bits used).
; Out: HL = word [(L & 15) * 8 + (H & 7)] of the 16 x 8 grid at +0x43F below.
; Clobbers nothing else (XIX saved).  RE-FRAMED 2026-09-25 (lane seqeng): the
; five bytes d3 07 f0 ec 23 were written as `.byte 0xd3 / reti / .byte 0xf0,
; 0xec / ld c, 92` -- a lone prefix plus its operands read as instructions;
; unidasm and llvm-mc both read them as ONE instruction, ld HL,(XIX+HL).
Voice_NoteChannelGrid_Lookup:
	and	l, 15
	and	h, 7
	sla	l, 4
	sla	h, 1
	or	l, h
	xor	h, h
	push	xix
	ld	xix, Voice_NoteChannelGrid_Lookup_Data
	ld	hl, (xix+hl)
	pop	xix
	ret
; Voice_NoteChannelTable1 +0x43F (16 rows x 8 x LE16).
; RE-FRAMED 2026-09-02 (lane v10seq). Was ~160 lines of mnemonics with 12
; undecodable bytes wedged between them as .byte. Its reader is the routine
; just above (Voice_NoteChannelTable1 +0x422): and l,15 / and h,7 / sla l,4 /
; sla h,1 / or l,h / xor h,h then ldw_sri -- index (l&15)*16 + (h&7)*2, so a
; 16-row grid of 8 LE16 words, which is exactly the 256 B to the next label.
; The grid shape shows in the values: columns 6 and 7 are zero in every row.
Voice_NoteChannelGrid_Lookup_Data:
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
	ld xix, Voice_DecodeNoteChannel2_Data
	ld	hl, (xix+hl)
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
; reference is `ld xix, Voice_DecodeNoteChannel2_Data`; nothing calls or
; jumps into the block, and 1026 B is exactly 2 + 128*8, ending where
; Voice_DecodeBankIndex begins.
; +0x00 (2 B) head; the grid below is based at +0x02
; +0x00 (2 B) head; the grid below is based at +0x02
	.byte 0x00, 0x00	; |..|
; +0x02 (128 records x 4 LE16). The reader is ldw_sri, a WORD load, so each record is four 16-bit fields and the index (note<<3) + ((h and 3)<<1) selects one of them. One record per line, MIDI note 0..127.
Voice_DecodeNoteChannel2_Data:
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
	ld xix, Voice_ClampBankIndex_Data
	ld	hl, (xix+hl)
	pop xix
	ret

Voice_BankIndexTable:
; Voice_BankIndexTable (18 x LE16), 2026-09-02 (lane v10seq).
; Voice_DecodeBankIndex: and l,0x7f / cp l,0xc else xor l,l / xor h,h /
; sla hl,1 then ldw_sri off xix = +0x02, so entry k is the word at index
; k+1 below. The values are the ramp 0x20,0x30,...,0xD0 then 0x20 repeated.
	.short	0x0000
Voice_ClampBankIndex_Data:	.short	0x0020, 0x0030, 0x0040, 0x0050, 0x0060, 0x0070, 0x0080
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
	ld xix, Voice_DecodeStandard_Data
	ld	hl, (xix+hl)
	pop xix

Voice_DecodeParamRet:
	ret

Voice_NoteParamTable:
; REGRIDDED 2026-09-02 (lane v10seq). The bytes were already correct;
; they were laid out 8 to a line but starting at +0x00, which put every
; record across two lines. The only reference to this block is
; `ld xix, Voice_DecodeStandard_Data`, and 1026 B is exactly 2 + 128*8.
; +0x00 (2 B) head; the grid below is based at +0x02
; +0x00 (2 B) head; the grid below is based at +0x02
	.byte 0x00, 0x00	; |..|  (was `nop / nop`: never executed, nothing jumps here)
; +0x02 (128 records x 4 LE16). The reader is ldw_sri, a WORD load, so each record is four 16-bit fields and the index (note<<3) + ((h and 3)<<1) selects one of them. One record per line, MIDI note 0..127.
Voice_DecodeStandard_Data:
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
	cp (0x7f0b:16), 0
	jr z, AccPlay_CheckPrevRunning
	cp (0x7f0c:16), 0
	jr z, AccPlay_StartNewAccomp
	bit 0, (0x7f0b:16)
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
	cp (0x7f0c:16), 0
	jr z, AccPlay_StopSequencer
	calr AccPlay_MainUpdateLoop
	jr AccPlay_ContinueMainLoop

AccPlay_StopSequencer:
	calr AccPlay_StopIfRunning

AccPlay_ContinueMainLoop:
	calr AccPlay_MonitorParamState
	bit 0, (0x7f35:16)
	jr z, AccPlay_UpdateStateFlags
	and (0x7f35:16), 254
	calr AccPlay_CheckAndToggle

AccPlay_UpdateStateFlags:
	ld a, (0x7f0b:16)
	ld (0x7f0c:16), a
	bit 2, (0x7f15:16)
	jr z, AccPlay_DispatchRet
	cp (CURRENT_TITLE:16), 1
	jr nz, AccPlay_DispatchRet
	and (0x7f15:16), 251
	ld (GLOBAL_ERROR_CODE:16), 15
	call DrumVoice_NotifyEE

AccPlay_DispatchRet:
	ret

AccPlay_InitializeStart:
	call AccWrap_PlayModeDispatch
	call CountAvailableVoiceSlots
	calr AccPlay_SetupSoundParams
	call AudioInit_CheckMIDIAndDispatch
	calr AccPlay_SaveMuteStates
	ldw (0x7f0e:16), 0xfffe
	ld (0x7f34:16), 0
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ld a, 0x10:opc
	call UI_PostPartChangeEvent
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ld a, (1075:16)
	sla a, 1
	and a, 0x1f
	or a, 0x80
	ld (0x7f16:16), a
	ld xhl, 0x1e880a
	ormi8 (xhl), 0x1
	ld xwa, 0x22
	ld xbc, 0:i3
	ld xde, 0:i3
	call CtrlPanel_IndicatorDispatch
	ld (0x8f4e:16), 4
	ret

AccPlay_MainUpdateLoop:
	call AccWrap_PlayModeDispatch
	ld (1055:16), 12
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
	cp (CURRENT_MODE:16), 16
	jr nz, AccPlay_SetIndicatorAndRet
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	bit 2, (0x7f15:16)
	jr z, AccPlay_PostEvent9E_Enable
	call AccSeq_PostEvent9E_Enable

AccPlay_PostEvent9E_Enable:
	xor wa, wa
	ld a, 0x1:opc
	call UI_PostPartChangeEvent
	bit 2, (0x7f15:16)
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
	or (0x7f15:16), 1
	ld xhl, 0x1e880a
	andmi8 (xhl), 0xfe
	ld xwa, 0x22
	call CtrlPanel_SetIndicatorLED
	ret

AccPlay_DispatchSeqStart:
	bit 2, (1056:16)
	jr nz, AccPlay_DispatchSeqRet
	call Seq_DispatcherEntry
	or (0x33e8:16), 1
	or (0x34cd:16), 128
	call Seq_DispatcherEntry
	ld (0x7f0b:16), 2

AccPlay_DispatchSeqRet:
	ret

AccPlay_HandleStopState:
	bit 2, (0x7e1f:16)
	jr nz, AccPlay_CheckResumeState
	jp AccPlay_PostLoopCleanup

AccPlay_CheckResumeState:
	bit 2, (0x7e23:16)
	jr nz, TempoEvt_ProcessLoop
	calr AccPlay_ProcessVoiceBank
	call CountAvailableVoiceSlots
	calr AccPlay_AllocateVoiceSlot
	ld xwa, 0x22
	call CtrlPanel_SetIndicatorLED

TempoEvt_ProcessLoop:
	call TempoRingBuf_CheckEmpty
	cp hl, 0:i3
	jr nz, TempoEvt_ReadAndClassify
	jp AccPlay_PostLoopCleanup

TempoEvt_ReadAndClassify:
	call TempoRingBuf_SaveReadPos
	call TempoRingBuf_ReadAlternate
	ld a, l
	ld w, a
	and w, 0xf0
	ld (0x7e54:16), a
	ld (0x7e55:16), w
	bit 7, (0x7f16:16)
	jr z, TempoEvt_DispatchEvent
	cp a, 0x81
	jr nz, TempoEvt_CheckHighBit
	ld a, (0x7f16:16)
	ld w, a
	and a, 0x1f
	and w, 0xe0
	dec 1, a
	or w, a
	cp a, 0:i3
	jr nz, TempoEvt_StoreBankParam
	and w, 0x7f
	calr AccPlay_UpdateBankParams

TempoEvt_StoreBankParam:
	ld (0x7f16:16), w
	jr TempoEvt_ContinueProcessing

TempoEvt_CheckHighBit:
	bit 7, a
	jr z, TempoEvt_ContinueProcessing
	ld a, (0x7f16:16)
	and a, 0x1f
	cp a, 1:i3
	jr nz, TempoEvt_ContinueProcessing
	call TempoRingBuf_ReadAlternate
	ld a, l
	cp a, 0x48
	jr c, TempoEvt_ContinueProcessing
	or (0x7f15:16), 16
	ld a, (0x7e54:16)
	ld w, (0x7e55:16)
	jr TempoEvt_DispatchEvent

TempoEvt_ContinueProcessing:
	calr TempoRingBuf_ReadLoop
	jp TempoEvt_ProcessLoop

TempoEvt_DispatchEvent:
	cpw (0x7e18:16), 0
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
	bit 0, (0x7f15:16)
	jr z, AccPlay_StopRet
	bit 2, (1056:16)
	jr nz, AccPlay_StopRet
	call Seq_DispatcherEntry
	and (0x33e8:16), 254
	or (0x34cd:16), 128
	call Seq_DispatcherEntry
	and (0x7f15:16), 254

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
	ld a, (0x7f14:16)
	cp a, 0xc
	jr c, Voice_CalcBankOffset
	ld a, 0x0:opc

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
	calr Util_ExtractAndShiftBits
	ld hl, (xix + 3)
	ldw (xix + 1), 0xffff
	ldw (xix + 3), 0xffff
	andmi8 (xix), 0x7f
	incw 1, (0x7e18:16)
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
; 16-byte template of one voice slot, copied as 8 LE16 words.  Read by
; Voice_InitSlotTemplate (0xF7210D): XIX = the slot (XIY on
; entry), XIY = this, BC = 8, ldirw; then byte +0 is overwritten with its
; own old value AND 0xF0 (old high nibble kept, low nibble cleared), so the
; template's byte +0 is discarded.  TYPED 2026-09-25 (lane seqeng); was spelled
; nop / swi 7 / jrl nc,64 (0xFF bytes read as swi 7).
	.short 0x0000, 0xff00, 0x00ff, 0x0000, 0x0000, 0x7f00, 0x0040, 0x0000

AccPlay_SetupSoundParams:
	ld a, 0x17:opc
	ld (PART_SELECT:16), a
	ld e, 0x90:opc
	ld d, 0x10:opc
	ld a, 0x17:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	cp wa, 0x1ff
	jr nz, AccPlay_SetupJumpTarget
	ld wa, 0:i3
	ld (0xfd62:16), a
	ld (0xfd63:16), w
	ld e, 0x17:opc
	ld d, 0x1:opc
	ld a, 0x0:opc
	ld w, 0x7f:opc
	call SwbtWr_QueuePostEvent
	ld e, 0x17:opc
	ld d, 0x0:opc
	ld a, 0x0:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent
	ld h, 0x0:opc
	ld l, 0x0:opc
	ld (0x90f7:16), 23
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff7e
	ld	(xbc+l), h

AccPlay_SetupJumpTarget:
	jp AccPlay_SyncParamsRet
AccPlay_SyncVoiceParams:
	ld	xiy, 0xf9b6
	ld	xix, 0xfd62
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
	call	SwbtWr_QueuePostEvent
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
	push xiy
	calr Voice_FindFreeSlot
	ld hl, wa
	calr Util_ExtractAndShiftBits
	ormi8 (xix), 0x80
	decw 1, (0x7e18:16)
	pop xiy
	ld (xiy + 3), wa
	ld l, 0x1:opc
	or (xiy + 0:8), l
	ld (0x7f10:16), wa
	ld wa, 6:i3
	ld (0x7f12:16), wa
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	ld (xiy + 9), wa
	xor a, a
	ld w, (0xfd66:16)
	bit 6, w
	jr z, AccPlay_CheckReverbFlag
	or a, 0x1

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
	ld hl, (0x7f10:16)
	calr Util_ExtractAndShiftBits
	ld a, 0x83:opc
	ld hl, (0x7f12:16)
	ld	(xix+hl), a
	ret

AccPlay_ProcessNoteEvent:
	ld bc, 5:i3
	calr MidiSeqBuf_ScanAllEntries
	ld a, (0x7f39:16)
	cp a, 0:i3
	jr z, AccPlay_NoteNoSlotMatch
	calr AccPlay_NoteWithSlot
	jr AccPlay_NoteEventRet

AccPlay_NoteNoSlotMatch:
	calr AccPlay_FindSlotByChannel

AccPlay_NoteEventRet:
	ret

AccPlay_NoteWithSlot:
	cpw (0x7e18:16), 0
	jr z, AccPlay_NoteNoSlotAvail
	calr AccPlay_FindActiveSlot
	cp xhl, 0xffff
	jr nz, AccPlay_NoteAllocAndWrite

AccPlay_NoteNoSlotAvail:
	jp AccPlay_NoteAllocRet

AccPlay_NoteAllocAndWrite:
	push xhl
	push xix
	ld l, (0x7f38:16)
	xor h, h
	ld xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+hl)
	xor w, w
	sla wa, 2
	ld hl, wa
	ld xix, AccPlay_NoteParamTable
	ld	a, (xix+hl)
	ld (0x7e54:16), a
	inc 1, hl
	ld	a, (xix+hl)
	ld (0x7e55:16), a
	inc 1, hl
	ld	a, (xix+hl)
	ld (0x7e56:16), a
	ld a, 0x90:opc
	cp (0x7e54:16), 0
	jr z, AccPlay_NoteWriteStatusByte
	ld a, 0x91:opc

; AccPlay_NoteWriteStatusByte (was AccPlay_NoteSetType91): A = 0x90, or 0x91
; when AccPlay_NoteParamTable's flag byte for this note is nonzero; the branch
; here is taken with A still 0x90.  Writes A, then the bytes at 0x7F37 and
; 0x7F38, to the MIDI sequence buffer (MidiSeqBuf_WriteByte).
AccPlay_NoteWriteStatusByte:
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ld a, (0x7f37:16)
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ld a, (0x7f38:16)
	calr MidiSeqBuf_WriteByte
	pop xix
	pop xhl
	ld a, (0x7f38:16)
	or a, 0x80
	ld (xhl), a
	ld a, 0x0:opc
	ld (xhl + 1), a
	ld a, (0x7f37:16)
	ld (xhl + 2), a
	ld wa, (0x7f10:16)
	ld (xhl + 3), wa
	ld wa, (0x7f12:16)
	ld (xhl + 5), a
	calr MidiSeqBuf_AdvancePosition
	ld a, (0x7f39:16)
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ld a, 0x10:opc
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ld a, 0x0:opc
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	cp (0x7e54:16), 0
	jr z, AccPlay_NoteAllocRet
	ld a, (0x7e55:16)
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition
	ld a, (0x7e56:16)
	calr MidiSeqBuf_WriteByte
	calr MidiSeqBuf_AdvancePosition

AccPlay_NoteAllocRet:
	ret

AccPlay_NoteParamTable:
; 12 records x 4 bytes: +0 flag, +1 and +2 two extra event bytes, +3 unused
; (0 in every record).  Read by AccPlay_NoteAllocAndWrite
; (0xF722AB): L = byte at 0x7F38, A = byte
; [AccPatch_Transpose_LookupTable_Data + L], HL = 4*A (12 records), then
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
	ld w, (0x7f38:16)
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
	ld a, 0x0:opc
	ld (xhl), a
	ld d, (xhl + 1)
	ld a, (xhl + 2)
	ld c, (0x7f37:16)
	cp c, a
	jr nc, AccPlay_CalcNoteOffset
	add c, 0x60
	cp d, 0:i3
	jr z, AccPlay_CalcNoteOffset
	dec 1, d

AccPlay_CalcNoteOffset:
	sub c, a
	ld e, c
	cp d, 0:i3
	jr nz, AccPlay_WriteNoteRelease
	cp e, 2:i3
	jr nc, AccPlay_WriteNoteRelease
	ld e, 0x2:opc

AccPlay_WriteNoteRelease:
	ld wa, (0x7f10:16)
	pushw wa
	ld wa, (0x7f12:16)
	pushw wa
	ld wa, (xhl + 3)
	ld (0x7f10:16), wa
	ld a, (xhl + 5)
	xor w, w
	ld (0x7f12:16), wa
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
	ld (0x7f12:16), wa
	popw wa
	ld (0x7f10:16), wa

AccPlay_NoteReleaseRet:
	ret

AccPlay_HandleEndMarkerEvt:
	ld bc, 1:i3
	calr MidiSeqBuf_ScanAllEntries
	ld de, 1:i3
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
	ld bc, 4:i3
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl)
	cp a, 0xd3
	jr nz, MidiSeq_SustainFixup
	ld a, 0xd5:opc
	ld (xhl), a

MidiSeq_SustainFixup:
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleD2Event:
	ld bc, 5:i3
	calr MidiSeqBuf_ScanAllEntries
	ld xhl, 0x7f36
	ld a, (xhl + 3)
	ld (xhl + 2), a
	ld de, 3:i3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleProgChange:
	ld bc, 7:i3
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
	ld a, (0xfd66:16)
	bit 6, a
	jr z, MidiSeq_ProgChangeSetReverb
	or w, 0x1

MidiSeq_ProgChangeSetReverb:
	ld (xhl + 5), w
	ld de, 6:i3
	calr MidiSeqBuf_ProcessEntries
	ret

MidiSeq_HandleCtrlChange:
	ld bc, 7:i3
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
	ld a, (1076:16)
	ld w, (0x7f34:16)
	cp a, w
	jr z, AccPlay_MeasureTrackRet
	ld hl, (0x7f0e:16)
	inc 1, hl
	cp hl, 0:i3
	jr nz, AccPlay_MeasureIncrement
	inc 1, hl

AccPlay_MeasureIncrement:
	ld (0x7f0e:16), hl
	cp (ACTIVE_TITLE:16), 201
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
	ld (0x7f34:16), a

AccPlay_MeasureTrackRet:
	ret

AccPlay_TrackVoiceCount:
	ld wa, (0x7e18:16)
	ld hl, (0x7e1a:16)
	cp wa, hl
	jr z, AccPlay_VoiceCountRet
	cp (ACTIVE_TITLE:16), 201
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
	ld (0x7e1a:16), wa

AccPlay_VoiceCountRet:
	ret

AccPlay_MonitorParamState:
	cp (0x7f0b:16), 0
	jr z, AccPlay_SaveCurrentState
	cp (0x7f0c:16), 0
	jr z, AccPlay_InitVoiceBankState
	calr AccPlay_CompareAndSendProg
	jr AccPlay_SaveCurrentState

AccPlay_InitVoiceBankState:
	calr AccPlay_RestoreVoiceBank

AccPlay_SaveCurrentState:
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	and w, 0x7f
	ld (0x7f18:16), wa
	ld a, (0xfd66:16)
	and a, 0x48
	xor w, w
	ld (0x7f1a:16), wa
	ret

AccPlay_CompareAndSendProg:
	ld hl, (0x7f18:16)
	ld a, (0xfd62:16)
	ld w, (0xfd63:16)
	and w, 0x7f
	cp wa, hl
	jr z, AccPlay_CompareReverbState
	ld e, w
	ld w, a
	ld a, 0xc1:opc
	ld (0x7e40:16), w
	and e, 0xf
	bit 7, w
	jr z, AccPlay_SendProgChange
	or e, 0x10
	and w, 0x7f

AccPlay_SendProgChange:
	call AccompSeq_SendMidiEvent

AccPlay_CompareReverbState:
	ld hl, (0x7f1a:16)
	ld a, (0xfd66:16)
	and a, 0x40
	xor w, w
	and l, 0x40
	cp wa, hl
	jr z, AccPlay_CompareChorusState
	ld e, 0x0:opc
	cp a, 0:i3
	jr z, AccPlay_SetReverbValue
	ld e, 0x7f:opc

AccPlay_SetReverbValue:
	ld w, 0x7:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent

AccPlay_CompareChorusState:
	jr AccPlay_ParamMonitorRet
	ld hl, (0x7f1a:16)
	ld a, (0xfd66:16)
	and a, 0x8
	xor w, w
	and l, 0x8
	cp wa, hl
	jr z, AccPlay_ParamMonitorRet
	ld e, 0x0:opc
	cp a, 0:i3
	jr z, AccPlay_SetChorusValue
	ld e, 0x7f:opc

AccPlay_SetChorusValue:
	ld w, 0x3:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent

AccPlay_ParamMonitorRet:
	ret

AccPlay_RestoreVoiceBank:
	calr Voice_GetBankEntryPointer
	ld wa, (xiy + 9)
	ld e, w
	ld w, a
	ld a, 0xc1:opc
	ld (0x7e40:16), w
	and e, 0xf
	bit 7, w
	jr z, AccPlay_SendBankProgram
	or e, 0x10
	and w, 0x7f

AccPlay_SendBankProgram:
	call AccompSeq_SendMidiEvent
	ld wa, (xiy + 9)
	ld (0xfd62:16), a
	ld (0xfd63:16), w
	ld e, 0x17:opc
	ld d, 0x1:opc
	ld a, w
	ld w, 0x7f:opc
	call SwbtWr_QueuePostEvent
	ld wa, (xiy + 9)
	ld e, 0x17:opc
	ld d, 0x0:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 12)
	ld e, a
	ld w, 0x4:opc
	ld a, 0xd1:opc
	call AccompSeq_SendMidiEvent
	ld a, (xiy + 12)
	ld (0xfd6a:16), a
	ld e, 0x17:opc
	ld d, 0x8:opc
	ld w, 0x7f:opc
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 13)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccPlay_RestoreReverbVal
	ld e, 0x7f:opc

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
	ld (0xfd66:16), w
	ld e, 0x17:opc
	ld d, 0x4:opc
	ld a, w
	ld w, 0x40:opc
	call SwbtWr_QueuePostEvent
	ld a, (xiy + 14)
	ld e, 0x0:opc
	bit 0, a
	jr z, AccPlay_RestoreChorusVal
	ld e, 0x7f:opc

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
	ld (0xfd66:16), w
	ld e, 0x17:opc
	ld d, 0x4:opc
	ld a, w
	ld w, 0x8:opc
	call SwbtWr_QueuePostEvent
	ret

AccPlay_ClearSlotTable:
	ld xhl, 0x7e7b
	ld a, 0x0:opc

AccPlay_ClearSlotLoop:
	ld (xhl), a
	add xhl, 0x9
	cp xhl, 0x7f0b
	jr z, AccPlay_ClearSlotDone
	jr AccPlay_ClearSlotLoop

AccPlay_ClearSlotDone:
	ret

AccPlay_SaveMuteStates:
	ld a, (0xf9c3:16)
	ld w, (0xf9dd:16)
	ld (0x7f1c:16), wa
	ld a, (0xf9f7:16)
	ld w, (0xfa11:16)
	ld (0x7f1e:16), wa
	ld a, (0xfa2b:16)
	ld w, (0xfa45:16)
	ld (0x7f20:16), wa
	ld a, (0xfa5f:16)
	ld w, (0xfa79:16)
	ld (0x7f22:16), wa
	ld a, (0xfa93:16)
	ld w, (0xfaad:16)
	ld (0x7f24:16), wa
	ld a, (0xfac7:16)
	ld w, (0xfae1:16)
	ld (0x7f26:16), wa
	ld a, (0xfafb:16)
	ld w, (0xfb15:16)
	ld (0x7f28:16), wa
	ld a, (0xfb2f:16)
	ld w, (0xfb49:16)
	ld (0x7f2a:16), wa
	ld a, (0xfb63:16)
	ld w, (0xfb7d:16)
	ld (0x7f2c:16), wa
	ld a, (0xfb97:16)
	ld w, (0xfbb1:16)
	ld (0x7f2e:16), wa
	ld a, (0xfbcb:16)
	ld w, (0xfbe5:16)
	ld (0x7f30:16), wa
	ld a, (0xfbff:16)
	ld w, (0xfc19:16)
	ld (0x7f32:16), wa
	ld a, 0xc0:opc
	or (0xf9c3:16), a
	or (0xf9dd:16), a
	or (0xf9f7:16), a
	or (0xfa11:16), a
	or (0xfa2b:16), a
	or (0xfa45:16), a
	or (0xfa5f:16), a
	or (0xfa79:16), a
	or (0xfa93:16), a
	or (0xfaad:16), a
	or (0xfac7:16), a
	or (0xfae1:16), a
	or (0xfafb:16), a
	or (0xfb15:16), a
	or (0xfb2f:16), a
	or (0xfb49:16), a
	or (0xfb63:16), a
	or (0xfb7d:16), a
	or (0xfb97:16), a
	or (0xfbb1:16), a
	or (0xfbcb:16), a
	or (0xfbe5:16), a
	or (0xfbff:16), a
	or (0xfc19:16), a
	ld a, (0xfd6f:16)
	and a, 0x3f
	and a, 0xf0
	ld (0xfd6f:16), a
	ld e, 0x17:opc
	ld d, 0xd:opc
	ld w, 0xcf:opc
	call SwbtWr_QueuePostEvent
	calr AccompSeq_QueueAllMutes
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
	ld d, 0xd:opc
	ld w, 0xcf:opc
	call SwbtWr_QueuePostEvent
	ret

AccPlay_RestoreMuteStates:
	ld wa, (0x7f1c:16)
	ld (0xf9c3:16), a
	ld (0xf9dd:16), w
	ld wa, (0x7f1e:16)
	ld (0xf9f7:16), a
	ld (0xfa11:16), w
	ld wa, (0x7f20:16)
	ld (0xfa2b:16), a
	ld (0xfa45:16), w
	ld wa, (0x7f22:16)
	ld (0xfa5f:16), a
	ld (0xfa79:16), w
	ld wa, (0x7f24:16)
	ld (0xfa93:16), a
	ld (0xfaad:16), w
	ld wa, (0x7f26:16)
	ld (0xfac7:16), a
	ld (0xfae1:16), w
	ld wa, (0x7f28:16)
	ld (0xfafb:16), a
	ld (0xfb15:16), w
	ld wa, (0x7f2a:16)
	ld (0xfb2f:16), a
	ld (0xfb49:16), w
	ld wa, (0x7f2c:16)
	ld (0xfb63:16), a
	ld (0xfb7d:16), w
	ld wa, (0x7f2e:16)
	ld (0xfb97:16), a
	ld (0xfbb1:16), w
	ld wa, (0x7f30:16)
	ld (0xfbcb:16), a
	ld (0xfbe5:16), w
	ld wa, (0x7f32:16)
	ld (0xfbff:16), a
	ld (0xfc19:16), w
	ld a, (0xfd6f:16)
	or a, 0xc0
	ld (0xfd6f:16), a
	ld e, 0x17:opc
	ld d, 0xd:opc
	ld w, 0x4f:opc
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
	calr TempoRingBuf_ReadLoop
	ld xhl, 0x7f36
	ld	(xhl+ix), a
	inc 1, ix
	dec 1, bc
	cp bc, 0:i3
	jr nz, MidiSeqBuf_ScanLoop
	bit 4, (0x7f15:16)
	jr z, MidiSeqBuf_ScanDone
	and (0x7f15:16), 239
	ld (xhl + 1), 0x0

MidiSeqBuf_ScanDone:
	ret

MidiSeqBuf_ProcessEntries:
	cpw (0x7e18:16), 0
	jr z, MidiSeqBuf_ProcessDone
	xor ix, ix

MidiSeqBuf_ProcessLoop:
	ld xhl, 0x7f36
	ld	a, (xhl+ix)
	push xix
	pushw de
	ld hl, (0x7f10:16)
	calr Util_ExtractAndShiftBits
	ld hl, (0x7f12:16)
	ld	(xix+hl), a
	calr MidiSeqBuf_AdvancePosition
	popw de
	pop xix
	inc 1, ix
	cp ix, de
	jr c, MidiSeqBuf_ProcessLoop

MidiSeqBuf_ProcessDone:
	ret

MidiSeqBuf_AdvancePosition:
	ld wa, (0x7f12:16)
	inc 1, wa
	cp wa, 0xff
	jr nz, MidiSeqBuf_AdvanceDone
	push xix
	push xde
	push xhl
	calr Voice_FindFreeSlot
	xor ix, ix
	ld hl, (0x7f10:16)
	ld de, hl
	calr Util_ExtractAndShiftBits
	ld (xix + 3), wa
	ld (0x7f10:16), wa
	ld hl, wa
	calr Util_ExtractAndShiftBits
	ld (xix + 1), de
	ormi8 (xix), 0x80
	decw 1, (0x7e18:16)
	ld wa, 6:i3
	pop xhl
	pop xde
	pop xix

MidiSeqBuf_AdvanceDone:
	ld (0x7f12:16), wa
	ret

MidiSeqBuf_AdvanceWritePos:
	ld wa, (0x7f12:16)
	inc 1, wa
	cp wa, 0xff
	jr nz, MidiSeqBuf_WriteAdvDone
	push xix
	push xde
	push xhl
	ld hl, (0x7f10:16)
	ld de, hl
	calr Util_ExtractAndShiftBits
	ld wa, (xix + 3)
	ld (0x7f10:16), wa
	ld wa, 6:i3
	pop xhl
	pop xde
	pop xix

MidiSeqBuf_WriteAdvDone:
	ld (0x7f12:16), wa
	ret

MidiSeqBuf_WriteByte:
	push xix
	push xhl
	ld hl, (0x7f10:16)
	calr Util_ExtractAndShiftBits
	ld hl, (0x7f12:16)
	ld	(xix+hl), a
	pop xhl
	pop xix
	ret

AccPlay_InitAndStartLoop:
	ld (0x7f0b:16), 0
	call TempoRingBuf_ReInitAndRet
	or (0x7f15:16), 4
	ld a, 0x8:opc
	call MIDI_SendSysExCmd
	calr AccPlay_MainUpdateLoop
	ret

AccPlay_ToggleCodeFragment:
	cp	(32523:16), 0
	jr	z, AccPlay_ToggleCodeFragment_Code_Return
	ld	(0x7f0b:16), 0
	call	TempoRingBuf_ReInitAndRet
	calr	AccPlay_MainUpdateLoop
AccPlay_ToggleCodeFragment_Code_Return:
	ret

AccPlay_CheckAndToggle:
	bit 1, (0x7f0b:16)
	jr z, AccPlay_ToggleRet
	bit 2, (1055:16)
	jr nz, AccPlay_ToggleRestart
	call AccWrap_PlayModeStartAccPlay
	ld wa, 0:i3
	ei 6
	ld (1130:16), a
	ld (1128:16), wa
	ld (1055:16), 1
	ei 0
	jr AccPlay_ToggleRet

AccPlay_ToggleRestart:
	ld (0x7f0b:16), 0
	call TempoRingBuf_ReInitAndRet
	calr AccPlay_MainUpdateLoop

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
	lda xsp, (xsp - 14)

	RegObjTable NAKA_CLASS_Class, ClassProc, MidiMenu_WidgetCount, East_ClassTable_163, 0x163
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, MidiMenu_ResEventCount, MidiMenu_ResEventTable, 0x1c3
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, MidiMenu_MsgTypeCount, MidiMenu_MsgType_Table, 0x1e3
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x3c, MidiMenu_ApFunctionTable, 0x123
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x3c, MidiMenu_ApFunctionNameTable, 0x423
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x10, MidiMenu_ProcTable, 0x103
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x10, MidiMenu_NakaProcName_Table, 0x403
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x7, East_MainFuncTable_143, 0x143
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x7, East_MainFuncNameTable_443, 0x443
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, East_ViewableTable_009, 0x9
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, East_ResNameTable_309, 0x309
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x3, East_ViewableTable_00F, 0xf
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x3, East_ResNameTable_30F, 0x30f
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, East_ViewableTable_018, 0x18
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, East_ResNameTable_318, 0x318
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, East_ViewableTable_019, 0x19
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, East_ResNameTable_319, 0x319
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, East_ViewableTable_01A, 0x1a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, East_ResNameTable_31A, 0x31a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x14, East_ViewableTable_050, 0x50
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x14, East_ResNameTable_350, 0x350
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x7, East_ViewableTable_051, 0x51
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x7, East_ResNameTable_351, 0x351
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, East_ViewableTable_052, 0x52
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, NakaData_WidgetTables2, 0x352
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, East_ViewableTable_053, 0x53
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, East_ResNameTable_353, 0x353
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x5, East_ViewableTable_054, 0x54
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x5, NakaObj_MidiCommonSetting_Table, 0x354
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x5, East_ViewableTable_055, 0x55
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x5, NakaObj_MidiInOutSetting_Table, 0x355
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x43, East_ViewableTable_056, 0x56
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x43, NakaObj_MidiPresets_Table, 0x356
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1c, East_ViewableTable_057, 0x57
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1c, East_ResNameTable_357, 0x357
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x15, East_ViewableTable_058, 0x58
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x15, East_ResNameTable_358, 0x358
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, East_ViewableTable_059, 0x59
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, East_ResNameTable_359, 0x359
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, East_ViewableTable_05A, 0x5a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, NakaObj_MidiComputerConn_Table, 0x35a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x11, East_ViewableTable_05B, 0x5b
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x11, NakaObj_MidiPmemOutput_Table, 0x35b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, East_ViewableTable_05C, 0x5c
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, East_ResNameTable_35C, 0x35c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x18, East_ViewableTable_0D7, 0xd7
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x18, East_ResNameTable_3D7, 0x3d7
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, East_ViewableTable_0D8, 0xd8
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, East_ResNameTable_3D8, 0x3d8
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, East_ViewableTable_0EC, 0xec
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, East_ResNameTable_3EC, 0x3ec

	RegMode 0x3, East_ResNames_3EC_Strings, 0x5, NAKA_APFUNC_DefaultFunction, TITLE_MDMENU

	RegTitle 0x3, InitializeEast_Str_TT_REVEQMENU, 0x9, NAKA_APFUNC_DefaultFunction, 0x90000
	RegTitle 0x3, InitializeEast_Str_TT_SDOCT, 0xf, NAKA_APFUNC_DefaultFunction, 0xf0000
	RegTitle 0x3, InitializeEast_Str_TT_REVPRESET, 0x18, NAKA_APFUNC_DefaultFunction, 0x180000
	RegTitle 0x3, InitializeEast_Str_TT_EQPRESET, 0x19, NAKA_APFUNC_DefaultFunction, 0x190000
	RegTitle 0x3, InitializeEast_Str_TT_REVEQPRESET, 0x1a, NAKA_APFUNC_DefaultFunction, 0x1a0000
	RegTitle 0x3, InitializeEast_Str_TT_MDMENU, 0x50, NAKA_APFUNC_DefaultFunction, 0x500000
	RegTitle 0x3, InitializeEast_Str_TT_MDPART, 0x51, NAKA_APFUNC_DefaultFunction, 0x510000
	RegTitle 0x3, InitializeEast_Str_TT_MDCTRL, 0x52, NAKA_APFUNC_DefaultFunction, 0x520000
	RegTitle 0x3, InitializeEast_Str_TT_MDREAL, 0x53, NAKA_APFUNC_DefaultFunction, 0x530000
	RegTitle 0x3, InitializeEast_Str_TT_MDCOM, 0x54, NAKA_APFUNC_DefaultFunction, 0x540000
	RegTitle 0x3, InitializeEast_Str_TT_MDINOUT, 0x55, NAKA_APFUNC_DefaultFunction, 0x550000
	RegTitle 0x3, InitializeEast_Str_TT_MDPRESET, 0x56, NAKA_APFUNC_DefaultFunction, 0x560000
	RegTitle 0x3, InitializeEast_Str_TT_MDEXC, 0x57, NAKA_APFUNC_DefaultFunction, 0x570000
	RegTitle 0x3, InitializeEast_Str_TT_MDGMMODE, 0x58, NAKA_APFUNC_DefaultFunction, 0x580000
	RegTitle 0x3, InitializeEast_Str_TT_MDTXPCG, 0x59, NAKA_APFUNC_DefaultFunction, 0x590000
	RegTitle 0x3, InitializeEast_Str_TT_MDCOMP, 0x5a, NAKA_APFUNC_DefaultFunction, 0x5a0000
	RegTitle 0x3, InitializeEast_Str_TT_MDPMLCTL, 0x5b, NAKA_APFUNC_DefaultFunction, 0x5b0000
	RegTitle 0x3, InitializeEast_Str_TT_MDSETUP, 0x5c, NAKA_APFUNC_DefaultFunction, 0x5c0000
	RegTitle 0x3, InitializeEast_Str_TT_ETVOCAL, 0xd7, NAKA_APFUNC_DefaultFunction, 0xd70000
	RegTitle 0x3, InitializeEast_Str_TT_ETFADEIN, 0xd8, NAKA_APFUNC_DefaultFunction, 0xd80000
	RegTitle 0x3, InitializeEast_Str_TT_SPLITSEL, 0xec, NAKA_APFUNC_DefaultFunction, NAKA_VIEW_SplitSetting

	lda xsp, (xsp + 14)
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
	add xbc, AcVocalGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (AcVocalGrid_DialSetup:24)
	jp	t, (xix+bc)

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
AcVocalGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
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
	lda xbc, (AcVocalGrid_DialSetup_Table:24)
	ld	wa, (xbc+wa)
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
AcVocalGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
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
	lda xbc, (AcVocalGrid_DialSetup_Table_2:24)
	ld	wa, (xbc+wa)
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
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr Vocalist_ReturnZeroJmp
AcVocalGridBoxProc_OnLswData:	; cases 29360156, 29360157
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
	ld xiy, VocalistGridCheck_LocalInit
	lda xix, (xsp + 20)
	ldw bc, 0x10
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 12)
	ld bc, 4:i3
	ldirw
	ld xix, xhl
	lda xbc, (xsp + 12)
	lda xwa, (VocalistGridCheck_Table:24)
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
	add xwa, VocalistGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (VocalistGrid_DispatchData:24)
	jp	t, (xix+wa)

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
	lda	xde, (VocalistGridCheck_Table:24)
	ld	xwa, (xde+ix)
	cp xwa, 4294967295
	jrl	z, AcVocalist_ReturnZero
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld	xwa, (xde+bc)
	ld bc, 1:i3
	ld de, 2:i3
	jr	VocalistGridCheck_Join
VocalistGridCheck_OnIndexswDown:	; cases 29360152, 29360154
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
	jr	z, VocalistGridCheck_Skip15
	cpw	(xhl), 2
	jrl	nz, AcVocalist_ReturnZero
VocalistGridCheck_Skip15:
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	sla	bc, 3
	ld	ix, bc
	add	ix, wa
	lda	xde, (VocalistGridCheck_Table:24)
	ld	xwa, (xde+ix)
	cp xwa, 4294967295
	jrl	z, AcVocalist_ReturnZero
	ld	wa, (xhl)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld	xwa, (xde+bc)
	ldw bc, 65535
	ld	de, 2:i3
VocalistGridCheck_Join:
	call	MainLswAdd
	jrl	AcVocalist_ReturnZero
VocalistGridCheck_OnLswData:
	ld	(xsp+4), xbc
	ld	xhl, xiy
	ldw (xiy), 0
	ld	xix, (xsp+8)
	ld	xiz, xde
	ld	xiy, xde
	jr	VocalistGridCheck_Join15
VocalistGridCheck_Loop:
	ld	qbc, bc
	.byte 0xd7, 0xe6, 0xec, 0x03	; sla 0x03,qbc
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0	; cp xwa,(xix+qbc)
	jr	nz, VocalistGridCheck_Skip16
	ld	bc, 1:i3
	jr	VocalistGridCheck_Join14
VocalistGridCheck_Skip16:
	ld wa, qbc
	inc 4, wa
	ld qbc, wa
	ld xwa, (xiy)
	.byte 0xe3, 0x07, 0xf0, 0xe6, 0xf0	; cp xwa,(xix+qbc)
	jr	nz, VocalistGridCheck_Skip17
	ld	bc, 2:i3
VocalistGridCheck_Join14:
	ld	xwa, (xsp+4)
	ld	(xwa), bc
	jr	VocalistGridCheck_Join16
VocalistGridCheck_Skip17:
	inc	1, bc
	ld	(xhl), bc
VocalistGridCheck_Join15:
	ld	bc, (xhl)
	cp	bc, 12
	jr	lt, VocalistGridCheck_Loop
VocalistGridCheck_Join16:
	lda	xwa, (xsp+20)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xsp+8)
	ld	(xwa+4), xbc
	ld	xwa, (xde)
	lda	xbc, (xde+4)
	sub	xwa, 0x2d00
	cp	xwa, 0
	jrl	c, AcVocalist_ReturnZero
	cp	xwa, 19
	jrl	ugt, AcVocalist_ReturnZero
	add	xwa, xwa
	add	xwa, MidiPart_ColWidthData
	ld	wa, (xwa)
	lda	xix, (VocalistGrid_DispatchData_Code:24)
	jp	t, (xix+wa)
VocalistGrid_DispatchData_Code:
	ld wa, (xbc)
	cp wa, 16
	jr	z, VocalistGridCheck_Skip2
	cp	wa, 17
	jr	nz, VocalistGridCheck_Skip3
	ld	xwa, VocalistGrid_DispatchData_Str
	jr	VocalistGridCheck_Join2
VocalistGridCheck_Skip2:
	ld	xwa, VocalistGrid_DispatchData_Str_2
VocalistGridCheck_Join2:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	VocalistGridCheck_Join3
VocalistGridCheck_Skip3:
	inc	1, wa
	pushw	wa
	pushw	VocalistGrid_DispatchData_Str_Fmt2d@hi16
	pushw	VocalistGrid_DispatchData_Str_Fmt2d@lo16
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
VocalistGridCheck_Join3:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawProgram:
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw	VocalistGrid_DispatchData_Str_Fmt3d@hi16
	pushw	VocalistGrid_DispatchData_Str_Fmt3d@lo16
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawHarmony:
	ld	wa, (xbc)
	inc	1, wa
	pushw	wa
	pushw	VocalistGrid_DispatchData_Str_Fmtd@hi16
	pushw	VocalistGrid_DispatchData_Str_Fmtd@lo16
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawKey:
	ld	wa, (xbc)
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	pushw	VocalistGrid_DispatchData_Str_Fmts@hi16
	pushw	VocalistGrid_DispatchData_Str_Fmts@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawProgramChangeOption:
	ld	wa, (xbc)
	cp	wa, 3:i3
	jr	z, VocalistGridCheck_Skip6
	cp	wa, 2:i3
	jr	z, VocalistGridCheck_Skip5
	cp	wa, 1:i3
	jr	z, VocalistGridCheck_Skip4
	cp	wa, 0:i3
	jr	nz, VocalistGridCheck_Skip18
	ld	xwa, MidiPart_OctaveStr_m2 + 0xcc
	jr	VocalistGridCheck_Join4
VocalistGridCheck_Skip4:
	ld	xwa, VocalistGrid_DispatchData_Str_3
	jr	VocalistGridCheck_Join4
VocalistGridCheck_Skip5:
	ld	xwa, VocalistGrid_DispatchData_Str_4
	jr	VocalistGridCheck_Join4
VocalistGridCheck_Skip6:
	ld	xwa, VocalistGrid_DispatchData_Str_5
VocalistGridCheck_Join4:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
VocalistGridCheck_Skip18:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawControlVolume:
	ld	wa, (xbc)
	cp	wa, 120
	jr	z, VocalistGridCheck_Skip7
	cp	wa, 121
	jr	nz, VocalistGridCheck_Skip8
	ld	xwa, VocalistGrid_DispatchData_Str_6
	jr	VocalistGridCheck_Join5
VocalistGridCheck_Skip7:
	ld	xwa, VocalistGrid_DispatchData_Str_7
VocalistGridCheck_Join5:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	VocalistGridCheck_Join6
VocalistGridCheck_Skip8:
	pushw	wa
	pushw	VocalistGrid_DispatchData_Str_CC_Fmt3d@hi16
	pushw	VocalistGrid_DispatchData_Str_CC_Fmt3d@lo16
	ld	xwa, (xsp+14)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
VocalistGridCheck_Join6:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawKeySplitPoint:	; cases 11532, 11536
	ld	bc, (xbc)
	ld	de, bc
	and	de, 127
	ld	wa, de
	exts	xwa
	divs	wa, 12
	sla	wa, 2
	lda	xhl, (MidiPart_OctaveTable:24)
	ld	xwa, (xhl+wa)
	push xwa
	exts	xde
	divs	de, 12
	ld wa, qde
	sla	wa, 2
	lda	xde, (MidiPart_NoteNameTable:24)
	ld	xwa, (xde+wa)
	push xwa
	and	bc, 128
	sra	bc, 7
	sla	bc, 2
	lda	xwa, (VocalistGrid_DispatchData_PtrTable:24)
	ld	xwa, (xwa+bc)
	push xwa
	pushw	VocalistGrid_DispatchData_Str_Fmts_Fmts_Fmts@hi16
	pushw	VocalistGrid_DispatchData_Str_Fmts_Fmts_Fmts@lo16
	ld	xwa, (xsp+24)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGridCheck_LswDrawOnOffColumn:	; cases 11521, 11523, 11525, 11527, 11529, 11531, 11535, 11539
	ld	xwa, VocalistGrid_DispatchData_Str_9
	cpw	(xbc), 0
	jr	z, VocalistGridCheck_Skip19
	ld	xwa, VocalistGrid_DispatchData_Str_8
VocalistGridCheck_Skip19:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12

; VocalistGridCheck dispatch handler
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
	ld	xwa, (xwa+hl)
	sub xwa, 0x2d00
	cp xwa, 0x0
	jrl c, AcVocalist_ReturnZero
	cp xwa, 0x13
	jrl ugt, AcVocalist_ReturnZero
	add xwa, xwa
	add xwa, VocalistGrid_DispatchData_CaseTable
	ld wa, (xwa)
	lda xix, (VocalistGrid_CheckDispData:24)
	jp	t, (xix+wa)

VocalistGrid_CheckDispData:
	ld	xwa, 0x2d00
	call	SndParam_LookupReadOnly
	cp	hl, 16
	jr	z, VocalistGridCheck_Skip9
	cp	hl, 17
	jr	nz, VocalistGridCheck_Skip10
	ld	xwa, VocalistGrid_DispatchData_Str_10
	jr	VocalistGridCheck_Join7
VocalistGridCheck_Skip9:
	ld	xwa, VocalistGrid_DispatchData_Str_11
VocalistGridCheck_Join7:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	VocalistGridCheck_Join8
VocalistGridCheck_Skip10:
	ld	xwa, 0x2d00
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	VocalistGrid_CheckDispData_Str_Fmt2d@hi16
	pushw	VocalistGrid_CheckDispData_Str_Fmt2d@lo16
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
VocalistGridCheck_Join8:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawProgram:
	ld	xwa, 0x2d02
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	VocalistGrid_CheckDispData_Str_Fmt3d@hi16
	pushw	VocalistGrid_CheckDispData_Str_Fmt3d@lo16
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawHarmony:
	ld	xwa, 0x2d04
	call	SndParam_LookupReadOnly
	inc	1, hl
	pushw	hl
	pushw	VocalistGrid_CheckDispData_Str_Fmtd@hi16
	pushw	VocalistGrid_CheckDispData_Str_Fmtd@lo16
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawKey:
	ld	xwa, 0x2d06
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (MidiPart_NoteNameTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	pushw	VocalistGrid_CheckDispData_Str_Fmts@hi16
	pushw	VocalistGrid_CheckDispData_Str_Fmts@lo16
	lda	xwa, (xsp+28)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawPcngOption:
	ld	xwa, 0x2d08
	call	SndParam_LookupReadOnly
	cp	hl, 3:i3
	jr	z, VocalistGridCheck_Entry
	cp	hl, 2:i3
	jr	z, VocalistGridCheck_Skip12
	cp	hl, 1:i3
	jr	z, VocalistGridCheck_Skip11
	cp	hl, 0:i3
	jr	nz, VocalistGridCheck_Skip13
	ld	xwa, VocalistGrid_DispatchData_Str_12
	jr	VocalistGridCheck_Join9
VocalistGridCheck_Skip11:
	ld	xwa, VocalistGrid_DispatchData_Str_13
	jr	VocalistGridCheck_Join9
VocalistGridCheck_Skip12:
	ld	xwa, VocalistGrid_DispatchData_Str_14
	jr	VocalistGridCheck_Join9
VocalistGridCheck_Entry:
	ld	xwa, MidiPart_RecvTransStr
VocalistGridCheck_Join9:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
VocalistGridCheck_Skip13:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawControlVol:
	ld	xwa, 0x2d0a
	call	SndParam_LookupReadOnly
	lda	xbc, (xsp+20)
	cp	hl, 120
	jr	z, VocalistGridCheck_Entry2
	cp	hl, 121
	jr	nz, VocalistGridCheck_Skip14
	ld	xwa, VocalistGrid_DispatchData_Str_15
	jr	VocalistGridCheck_Join10
VocalistGridCheck_Entry2:
	ld	xwa, MidiPart_AfterStr
VocalistGridCheck_Join10:
	push	xwa
	push	xbc
	call	Strcpy
	inc	8, xsp
	jr	VocalistGridCheck_Join11
VocalistGridCheck_Skip14:
	ld	xwa, 0x2d0a
	call	SndParam_LookupReadOnly
	pushw	hl
	pushw	VocalistGridCheck_Entry2_Str_CC_Fmt3d@hi16
	pushw	VocalistGridCheck_Entry2_Str_CC_Fmt3d@lo16
	lda	xwa, (xsp+26)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
VocalistGridCheck_Join11:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawVocoderKeySplit:
	ld	xwa, 0x2d0d
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (MidiPart_OctaveTable:24)
	ld	xwa, (xbc+hl)
	push xwa
	ld	xwa, 0x2d0d
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	ld wa, qhl
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	ld	xwa, 0x2d0e
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (VocalistGrid_DispatchData_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	pushw	VocalistGridCheck_Entry2_Str_Fmts_Fmts_Fmts@hi16
	pushw	VocalistGridCheck_Entry2_Str_Fmts_Fmts_Fmts@lo16
	lda	xwa, (xsp+36)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jrl	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawChordalKeySplit:
	ld	xwa, 0x2d11
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	sla	hl, 2
	lda	xbc, (MidiPart_OctaveTable:24)
	ld	xwa, (xbc+hl)
	push xwa
	ld	xwa, 0x2d11
	call	SndParam_LookupReadOnly
	exts	xhl
	divs	hl, 12
	ld wa, qhl
	sla	wa, 2
	lda	xbc, (MidiPart_NoteNameTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	ld	xwa, 0x2d12
	call	SndParam_LookupReadOnly
	sla	hl, 2
	lda	xwa, (VocalistGrid_DispatchData_PtrTable:24)
	ld	xwa, (xwa+hl)
	push xwa
	pushw	VocalistGridCheck_Entry2_Str_Fmts_Fmts_Fmts_2@hi16
	pushw	VocalistGridCheck_Entry2_Str_Fmts_Fmts_Fmts_2@lo16
	lda	xwa, (xsp+36)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+20)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jr	VocalistGridCheck_Join12
VocalistGrid_DispatchData_DrawOnOffCell:	; cases 11521, 11523, 11525, 11527, 11529, 11531, 11535, 11539
	ld	xwa, (xsp+4)
	ld	wa, (xwa)
	sla	wa, 2
	dec	4, wa
	add	bc, wa
	ld	xwa, (xde+bc)
	call	SndParam_LookupReadOnly
	ld	xwa, VocalistGrid_DispatchData_Str_17
	cp	hl, 0:i3
	jr	z, VocalistGridCheck_Entry2_Code_Skip
	ld	xwa, VocalistGrid_DispatchData_Str_16
VocalistGridCheck_Entry2_Code_Skip:
	push	xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
VocalistGridCheck_Join12:
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
	add xhl, AcVocalist_ListSetup_CaseTable
	ld hl, (xhl)
	lda xix, (AcVocalist_ListDispatch:24)
	jp	t, (xix+hl)
; AcVocalistListBoxProc dispatch
AcVocalist_ListDispatch:
	ld	xwa, 0xd7000c
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jr	VocalistGridCheck_Join13
AcVocalist_ListSetup_Case1:	; cases 1, 3, 5
	ld	xwa, 0xd7000c
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 1:i3
VocalistGridCheck_Join13:
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
	ld xiy, PsHarmOnOffBoxProc_LocalInit
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, PsHarmOnOffBoxProc_LocalInit_2
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
	ld xde, (PsHarm_DrawActiveBox_PtrTable:24)
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
	ld xde, (PsHarm_DrawActiveBox_PtrTable:24)
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
	lda xix, (MainVocalistPage1OKFunc_CaseTable:24)
	ld	de, (xix+de)
	lda xix, (VocalistPage1OK_Dispatch:24)
	jp	t, (xix+de)
; MainVocalistPage1OKFunc dispatch
VocalistPage1OK_Dispatch:
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	ld	(0xb7ec:16), 11
	call	SndParam_ApplyAndSync
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip
	ld	xwa, 0x01d400
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join4
VocalistPage2OKFunc_Skip:
	ld	xwa, 0x01d400
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join4:
	call	SoundParam_NotifyChange
	ld	(GLOBAL_ERROR_CODE:16), 35
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
VocalistPage2OKFunc_Join:
	call	ApPostEvent
	ld	(0x7f40:16), 1
	call	MidiSysEx_SendAllParams
	ld	(32576:16), 0

; Vocalist page handler
VocalistPage_Handler:
	ld xhl, 0:i3
	inc 4, xsp
	ret

VocalistPage1_DispatchData:
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	ld	(0xb7ec:16), 2
	call	SndParam_ApplyAndSync
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip3
	ld	xwa, 0x018000
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join2
VocalistPage2OKFunc_Skip3:
	ld	xwa, 0x018000
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join2:
	call	SoundParam_NotifyChange
	ld	(GLOBAL_ERROR_CODE:16), 35
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jr	VocalistPage2OKFunc_Join
MainVocalistPage1OKFunc_Case4:
	ld	wa, bc
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	ld	(0xb7ec:16), 24
	call	SndParam_ApplyAndSync
	ld	xwa, 0x4201
	ld	bc, 3:i3
	ld	de, 2:i3
	call	SoundParam_NotifyChange
	ld	xwa, (xsp)
	srl	xwa, 16
	ld	qwa, 0
	cp	wa, 0:i3
	jr	z, VocalistPage2OKFunc_Skip2
	ld	xwa, 0x018c00
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	VocalistPage2OKFunc_Join3
VocalistPage2OKFunc_Skip2:
	ld	xwa, 0x018c00
	ld	bc, 0:i3
	ld	de, 2:i3
VocalistPage2OKFunc_Join3:
	call	SoundParam_NotifyChange
	ld	(GLOBAL_ERROR_CODE:16), 35
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jrl	VocalistPage2OKFunc_Join
MainVocalistPage1OKFunc_Case5:
	ld	wa, bc
	call	MidiSysEx_CopyParamToBuffer
	call	MidiSysEx_SendAllPartChannels
	ld	(0xb7ec:16), 1
	call	SndParam_ApplyAndSync
	ld	wa, 1:i3
	call	SmfMedley_RawData
	ld	(GLOBAL_ERROR_CODE:16), 35
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	jrl	VocalistPage2OKFunc_Join

MainVocalistPage2OKFunc:
	cp xbc, EVT_VST_SEND_OK
	jr nz, VocalistPage2_ReturnZero
	call MidiSysEx_SendAllParams
	ld (GLOBAL_ERROR_CODE:16), 35
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call ApPostEvent

VocalistPage2_ReturnZero:
	ld xhl, 0:i3
	ret

AccPlay_GetCurrentPart:
	ld l, (0x7f40:16)
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
	ld xde, RevSel_HandleConfirm_Str

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
	call SendEvent
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	exts xhl
	ld xwa, 0x19000b
	ld xbc, EVT_SET_PARAM
	ld xde, xhl
	jrl EqSel_SendEvent

EqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, EqSel_HandleConfirm_Str
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
	call SendEvent
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	exts xhl
	ld xwa, 0x1a000a
	ld xbc, EVT_SET_PARAM
	ld xde, xhl
	jrl RevEqSel_SendEvent

RevEqSel_HandleConfirm:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, RevEqSel_HandleConfirm_Str
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
	ld xhl, 0:i3

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
	lda xhl, (StsGMOnCheck_PtrTable:24)
	ret

StsGMOn_ReturnZero:
	ld xhl, 0:i3
	ret

StsGMOffCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsGMOff_ReturnZero
	lda xhl, (StsGMOffCheck_PtrTable:24)
	ret

StsGMOff_ReturnZero:
	ld xhl, 0:i3
	ret

StsAreYouSureCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsAreYouSure_ReturnZero
	lda xhl, (StsAreYouSureCheck_PtrTable:24)
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
	ld xwa, 0x580001
	ld xbc, EVT_GET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xc0
	ld bc, hl
	ld de, 1:i3
	call MainLswPut
	ld xwa, 0xffffffff
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call PostEvent
	ld (GLOBAL_ERROR_CODE:16), 35
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_MESAGE
	call PostEvent
	ld xhl, 0:i3
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
	lda xhl, (StsSplitCheck_PtrTable:24)
	ret

StsSplit_ReturnZero:
	ld xhl, 0:i3
	ret

SplitPointFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, SplitPointFunc_LocalInit
	lda xix, (xsp + 4)
	ldiw
	ldiw
	cp xde, EVT_GET_SMALL_STEP
	jrl z, ParamFunc_ReturnOne
	cp xde, EVT_GET_LARGE_STEP
	jrl z, ParamFunc_ReturnOne
	cp xde, EVT_GET_LSW_OUTPUT
	jrl z, ParamFunc_ReturnOne
	cp xde, EVT_GET_LSW_ADDRESS
	jrl z, SplitPoint_ReturnParamId
	cp xde, EVT_GET_LSW_STRING
	jrl z, SplitPoint_HandleNoteEvt
	cp xde, EVT_DRAW_KEY
	jrl nz, SplitPoint_ReturnZero
	ld xwa, 0x4180
	ld bc, 0:i3
	ld de, 1:i3
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
	lda xde, (SplitPoint_BitmapTable:24)
	ld	xbc, (xde+bc)
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
	lda xbc, (SplitPoint_NoteNameTable:24)
	ld	xwa, (xbc+wa)
	push xwa
	pushw SplitPointFunc_LocalInit_Strings@hi16
	pushw SplitPointFunc_LocalInit_Strings@lo16
	ld xwa, (xde + 8)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 14)
	ld xwa, (xsp + 8)
	ld de, (xwa + 4)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, EVT_DRAW_KEY
	call ApFuncCall
	ld xhl, (xsp + 12)
	jr ParamFunc_CommonExit

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
	cp (ACTIVE_TITLE:16), 236
	ret nz
	cp c, 0x15
	ret c
	cp c, 0x6c
	ret ugt
	extz bc
	ld xwa, 0x4181
	ld de, 1:i3
	call SoundParam_NotifyChange
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
	ld xwa, R12Octave_HandleNoteEvt_Str
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave2:
	ld xwa, R12Octave_Octave2_Str
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave3:
	ld xwa, R12Octave_Octave3_Str
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave4:
	ld xwa, R12Octave_Octave4_Str
	jr R12Octave_StringCopyAndSendEvent

R12Octave_Octave5:
	ld xwa, R12Octave_Octave5_Str
	jr R12Octave_StringCopyAndSendEvent

R12Octave_OctaveDefault:
	ld xwa, R12Octave_OctaveDefault_Str

R12Octave_StringCopyAndSendEvent:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, 0xffffffff
	ld xbc, EVT_RESET_INTERRUPT_TIME
	ld xde, 0:i3
	call SendEvent
	ld xhl, xiz
	jr R12Octave_PopIzRet

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
