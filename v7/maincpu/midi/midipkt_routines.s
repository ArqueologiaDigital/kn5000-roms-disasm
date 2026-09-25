; =============================================================================
; MIDI Packet Routines
; =============================================================================
;
; MIDI packet extraction, packing, and queue management.
; Handles the low-level MIDI message framing between the
; serial I/O layer and the dispatch handlers.
; =============================================================================

;
; v7 REGENERATED FROM v10's STRUCTURE (midi lane, 2026-09-25,
; scripts/tools/midi_lane_v7_from_v10.py): every line below was derived
; from the v10 line emitting the same bytes at v10 = v7 + 0x7D1, with v7's
; own bytes decoded and re-encoded.  Addresses quoted in carried-over
; headers are v10's.  Labels marked `v7 NAME DISPLACED` are the old v7
; names, kept because another v7 file references them; see that note.
;
; v7 NAME DISPLACED: `MidiPkt_ExtractAndPack` sits where v10 has no label (v10 0xFDA11E).
; The v7 code v10 calls `MidiPkt_ExtractAndPack` is 0x41A earlier, at v7 0xFD9533.
; Kept because another v7 file references this address by this name.
MidiPkt_ExtractAndPack:
; The first bytes of this file are the TAIL of an instruction whose head
; is the last bytes of the previous file: the v7 file boundary sits 0x41A
; bytes off the v10 one, so it cuts an instruction.
	.byte 0x04, 0x31
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret
MidiPkt_DispatchViaTable_4DA6:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld	xbc, ToneKit_FrequencyTable_0x396
	calr	MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
; v7 NAME DISPLACED: `MidiPkt_ExtractAndPack_StoreShifted` (0xFD9999) falls inside the line above in the
; correct framing (v10 0xFDA16A).  Kept as an alias because another v7
; file references this address by this name.
	.set MidiPkt_ExtractAndPack_StoreShifted, MidiPkt_DispatchViaTable_4DA6 + 43
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret
MidiPkt_DispatchViaTable_4DAE:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld	xbc, ToneKit_FrequencyTable_0x39E
	calr	MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	cp (xiz + 1), 0xb
	jr	nz, MidiPkt_DispatchViaTable_4DAE_Done
	lda xde, (xiz + 3)
	ld xwa, (xsp + 8)
	ld c, (xwa + 8)
	cpl c
	ld a, (xde)
	and a, c
	ld (xde), a
; v7 NAME DISPLACED: `MidiPkt_BuildControl` sits where v10 has no label (v10 0xFDA1BA).
; The v7 code v10 calls `MidiPkt_BuildControl` is 0x41A earlier, at v7 0xFD95CF.
; Kept because another v7 file references this address by this name.
MidiPkt_BuildControl:
	cp a, 0:i3
	jr	z, MidiPkt_DispatchViaTable_4DAE_Done
	ld xwa, xiz
	ld	xbc, ToneKit_FrequencyTable_0x39E
	calr	MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
MidiPkt_DispatchViaTable_4DAE_Done:
	pop xiz
	inc 8, xsp
	ret
MidiPkt_DispatchSpecialType:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld a, (xiz + 1)
	cp a, 0x11
	jr	nz, MidiPkt_DispatchSpecialType_Type10
	ld	xwa, MidiPkt_EventType_Table_0x584
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ldda32	xwa, (0xbbc0)
	jr	MidiPkt_DispatchSpecialType_SendAndUpdate
MidiPkt_DispatchSpecialType_Type10:
	cp a, 0x10
	jr	nz, MidiPkt_DispatchSpecialType_Default
	ld	xwa, MidiPkt_EventType_Table_0x58A
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ldda32	xwa, (0xbbc0)
MidiPkt_DispatchSpecialType_SendAndUpdate:
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	jr	MidiPkt_DispatchSpecialType_Return
MidiPkt_DispatchSpecialType_Default:
	ld xwa, xiz
	ld	xbc, ToneKit_FrequencyTable_0x3B6
	calr	MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
MidiPkt_DispatchSpecialType_Return:
	pop xiz
	inc 8, xsp
	ret
MidiPkt_MatchParamInTable:
	ld xde, xbc
	lda	xix, (0xee49e8:24)
MidiPkt_MatchParamInTable_Loop:
	ld_spil XHL, 0xea
	cp xix, xhl
	ret z
	ld c, (xhl + 7)
	cp c, (xwa + 1)
	jr	nz, MidiPkt_MatchParamInTable_Loop
	ld c, (xhl + 8)
	and c, (xwa + 3)
	jr	z, MidiPkt_MatchParamInTable_Loop
	ret
MidiPkt_EnqueueControlNop:
	ret
MidiPkt_EnqueueControl_3354:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x300
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr	z, MidiPkt_EnqueueControl_3354_Return
	lda	xbc, (0xee49e8:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr	z, MidiPkt_EnqueueControl_3354_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr	z, MidiPkt_EnqueueControl_3354_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr	z, MidiPkt_EnqueueControl_3354_ShiftBits
	srla c
MidiPkt_EnqueueControl_3354_ShiftBits:
	lda xwa, (xsp + 4)
	ld (xwa), c
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3354_Return:
	pop xiz
	inc 4, xsp
	ret
MidiPkt_EnqueueExtended_Data:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x304
	lda	xix, (xsp+4)
	.byte 0x85
	rcf
	ldiw
	ld	xwa, (xiz+4)
	calr	1118
	cp	hl, 0xffff
	jr	z, 102
	lda	xwa, (0xee49e8:24)
	.byte 0xae, 0x04, 0xf0
	jr	z, 92
	ld	xwa, (xiz)
	.byte 0x98, 0x04
	push	xsp
	nop
	nop
	jr	z, 83
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	ld	xwa, (xiz+4)
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	ld	xwa, (xiz)
	ld	xbc, xwa
	ld	bc, (xbc+4)
	.byte 0x98
	push	sr
	ld	w, (1198:16)
	ld	a, (xwa+11)
	and	a, 15
	jr	z, 2
	.byte 0xd9
	swi	7
	lda	xwa, (xsp+4)
	ld	(xwa), c
	and	c, 15
	ld	(xwa+1), c
	ld	c, (xwa)
	srl	c, 4
	ld	(xwa), c
	ld	bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	pop	xiz
	inc	4, xsp
	ret
SeqAlt_DescriptorBlock_Data_Helper:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x308
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr	z, MidiPkt_EnqueueControl_335C_Return
	lda	xbc, (0xee49e8:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr	z, MidiPkt_EnqueueControl_335C_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr	z, MidiPkt_EnqueueControl_335C_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	lda xwa, (xsp + 4)
	ld (xwa), 0x0
	ld xde, (xiz)
	ld xbc, (xiz + 4)
	ld c, (xbc + 8)
	and c, (xde + 2)
	jr	z, MidiPkt_EnqueueExtended_Data_Skip
	ld (xwa), 0x7f
MidiPkt_EnqueueExtended_Data_Skip:
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_335C_Return:
	pop xiz
	inc 4, xsp
	ret
SeqAlt_DescriptorBlock_Data_Helper2:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x30C
	lda xix, (xsp + 4)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xwa, (xiz + 4)
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jrl	z, MidiPkt_EnqueueControl_3358_Return
	lda	xbc, (0xee49e8:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jrl	z, MidiPkt_EnqueueControl_3358_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jrl	z, MidiPkt_EnqueueControl_3358_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ldda32	xhl, (0x9056)
	ld xwa, (xiz)
	ld a, (xwa)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	cp xwa, 0xffffffff
	jr	z, MidiPkt_EnqueueControl_3358_Return
	lda xwa, (xsp + 4)
	ld xbc, (xiz)
	ld c, (xbc)
	extz bc
	sla bc, 2
	ld_sril3 XBC, 0x07, 0xec, 0xe4
	ld c, (xbc)
	ld (xwa), c
	lda xde, (xwa + 2)
	ld xbc, (xiz)
	ld c, (xbc)
	extz bc
	sla bc, 2
	ld_sril3 XBC, 0x07, 0xec, 0xe4
	ld c, (xbc + 1)
	and c, 0x7
	ld (xde), c
	ld c, (xwa)
	bit 7, c
	jr	z, MidiPkt_EnqueueExtended_Data_Skip2
	res 7, c
	ld (xwa), c
	ld c, (xde)
	set 7, c
	ld (xde), c
MidiPkt_EnqueueExtended_Data_Skip2:
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld c, (xde)
	and c, 0xf
	ld (xwa + 3), c
	ld c, (xde)
	srl c, 4
	ld (xde), c
	ld bc, 5:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3358_Return:
	pop xiz
	inc 6, xsp
	ret
VocalistPage2OKFunc_Helper2_Helper:
	lda xsp, (xsp - 14)
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x312
	lda xix, (xsp + 4)
	ld bc, 2:i3
	ldirw
	ldi85
	lda xbc, (xsp + 10)
	ld (xbc), xiz
	lda	xwa, (0xee4aea:24)
	ld (xbc + 4), xwa
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr	z, MidiPkt_EnqueueControl_335E_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xwa, (xsp + 14)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	lda xwa, (xsp + 4)
	ld c, (xiz)
	ld (xwa), c
	lda xde, (xwa + 2)
	ld c, (xiz + 1)
	ld (xde), c
	ld c, (xwa)
	bit 7, c
	jr	z, MidiPkt_EnqueueControl_335E_SplitNibbles
	res 7, c
	ld (xwa), c
	ld c, (xde)
	set 7, c
	ld (xde), c
MidiPkt_EnqueueControl_335E_SplitNibbles:
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld c, (xde)
	and c, 0xf
	ld (xwa + 3), c
	ld c, (xde)
	srl c, 4
	ld (xde), c
	ld bc, 5:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_335E_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret
MidiPkt_EnqueueControl_3364:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x318
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr	z, MidiPkt_EnqueueControl_3364_Return
	ld xbc, (xiz)
	ld xwa, (xiz + 4)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr	z, MidiPkt_EnqueueControl_3364_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	cp a, 1:i3
	jr	nz, MidiPkt_EnqueueControl_3364_FormatData
	ld c, (0xfc61:16)
	and c, 0x30
	ld a, (xde + 11)
	and a, 0xf
	jr	z, MidiPkt_EnqueueControl_3364_NoShift
	srla c
MidiPkt_EnqueueControl_3364_NoShift:
	inc 1, c
	ld (xsp + 4), c
MidiPkt_EnqueueControl_3364_FormatData:
	lda xwa, (xsp + 4)
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3364_Return:
	pop xiz
	inc 4, xsp
	ret
MidiPkt_EnqueueControl_3368:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x31C
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr	MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jrl	z, MidiPkt_EnqueueControl_3368_Return
	ld xbc, (xiz)
	ld xwa, (xiz + 4)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jrl	z, MidiPkt_EnqueueControl_3368_Return
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld a, (0xfd99:16)
	and a, 0x1
	cp a, 1:i3
	jr	nz, MidiPkt_EnqueueControl_3368_NoPedal
	ld	xwa, ToneKit_FrequencyTable_0xB2
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr	z, MidiPkt_EnqueueControl_3368_PedalNoShift
	srla c
MidiPkt_EnqueueControl_3368_PedalNoShift:
	inc 1, c
	jr	MidiPkt_EnqueueControl_3368_FormatData
MidiPkt_EnqueueControl_3368_NoPedal:
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call	ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr	z, MidiPkt_EnqueueControl_3368_FormatData
	srla c
MidiPkt_EnqueueControl_3368_FormatData:
	ld (xsp + 4), c
	lda xwa, (xsp + 4)
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	ld bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3368_Return:
	pop xiz
	inc 4, xsp
	ret
MidiPkt_EnqueueExtended2_Data:
	ret
MidiPkt_BuildControl_Helper:
	lda	xsp, (xsp-10)
	push	xiz
	ld	xiz, xwa
	ld	xiy, MidiPkt_EventType_Table_0x320
	lda	xix, (xsp+4)
	.byte 0x85
	rcf
	ldiw
	ld	xwa, (xiz+4)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jrl	z, MidiPkt_EnqueueControl_3364_Epilogue
	lda	xbc, (0xee49e8:24)
	ld	xwa, (xiz+4)
	cp	xbc, xwa
	jr	z, MidiPkt_EnqueueControl_3364_Epilogue
	ld	xbc, (xiz)
	ld	a, (xwa+8)
	and	a, (xbc+3)
	jr	z, MidiPkt_EnqueueControl_3364_Epilogue
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	pushw	6
	lda	xwa, (xsp+10)
	push	xwa
	ld	xwa, (xiz+4)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+8)
	ld	xbc, (xiz)
	ld	c, (xbc)
	set	5, c
	ld	(xwa+1), c
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	ld	xbc, (xiz)
	ld	xde, (xiz+4)
	ld	a, (xde+8)
	.byte 0x89
	push	sr
	add	(0x8bc9:16), b
	pushw	0xc921
	.byte 0xcc
	retd	614
	.byte 0xcb
	swi	7
	lda	xwa, (xsp+4)
	ld	(xwa), c
	and	c, 15
	ld	(xwa+1), c
	ld	c, (xwa)
	srl	c, 4
	ld	(xwa), c
	ld	bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3364_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret
MidiPkt_CheckGateCondition:
	ld c, (xwa + 12)
	cp c, 0:i3
	jr	z, MidiPkt_CheckGateCondition_Second
	extz bc
	muls bc, 0x6
	lda	xde, (0xee4df2:24)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	ld xhl, (xde)
	ld c, (xde + 4)
	and c, (xhl)
	cp (xde + 5), c
	jr	nz, MidiPkt_CheckGateCondition_Blocked
MidiPkt_CheckGateCondition_Second:
	ld a, (xwa + 13)
	cp a, 0:i3
	jr	z, MidiPkt_CheckGateCondition_Pass
	extz wa
; v7 NAME DISPLACED: `MidiPkt_EnqueueControl_335C` sits where v10 has no label (v10 0xFDA7A3).
; The v7 code v10 calls `MidiPkt_EnqueueControl_335C` is 0x41A earlier, at v7 0xFD9BB8.
; Kept because another v7 file references this address by this name.
MidiPkt_EnqueueControl_335C:
	muls wa, 0x6
	lda	xbc, (0xee4e04:24)
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld xde, (xbc)
	ld a, (xbc + 4)
	and a, (xde)
	cp (xbc + 5), a
	jr	z, MidiPkt_CheckGateCondition_Pass
MidiPkt_CheckGateCondition_Blocked:
	ldw hl, 0xffff
	ret
MidiPkt_CheckGateCondition_Pass:
	ld hl, 0:i3
	ret
MidiPkt_DispatchViaTable_4DCE:
	dec 8, xsp
	push xiz
	ld xiz, (xsp + 16)
	ld xwa, xiz
	ld	xbc, ToneKit_FrequencyTable_0x3BE
	calr	MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda	xde, (0xee4f52:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret
MidiPkt_DispatchData_Chan4:
	ld	(0xbc60:16), 4
	jr	MidiPkt_DispatchData_Chan6_Join2
; v7 NAME DISPLACED: `MidiPkt_EnqueueControl_335C_ZeroData` sits where v10 has `MidiPkt_DispatchData_Chan3` (v10 0xFDA800).
; The v7 code v10 calls `MidiPkt_EnqueueControl_335C_ZeroData` is 0x41A earlier, at v7 0xFD9C15.
; Kept because another v7 file references this address by this name.
MidiPkt_EnqueueControl_335C_ZeroData:
MidiPkt_DispatchData_Chan3:
	ld	(0xbc60:16), 3
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan1:
	ld	(0xbc60:16), 1
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan2:
	ld	(0xbc60:16), 2
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan5:
	ld	(0xbc60:16), 5
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan6:
	ld	(0xbc60:16), 6
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan6_Join:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccWrap_PlayModeDispatch
; v7 NAME DISPLACED: `MidiPkt_EnqueueControl_3358` (0xFDA058) falls inside the line above in the
; correct framing (v10 0xFDA829).  Kept as an alias because another v7
; file references this address by this name.
	.set MidiPkt_EnqueueControl_3358, MidiPkt_DispatchData_Chan6_Join + 6
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (0xbc60:16)
	extz	wa
	jp	SysEx_InitiateSend
MidiPkt_DispatchData_Chan6_Join2:
	ld	a, (0x8c9a:16)
	cp	a, 87
	jr	z, MidiPkt_DispatchData_Chan6_Skip
	cp	(0x8c98:16), 1
	jr	nz, MidiPkt_DispatchData_Chan6_Skip2
	cp	a, 1:i3
	jr	nz, MidiPkt_DispatchData_Chan6_Skip2
MidiPkt_DispatchData_Chan6_Skip:
	jr	MidiPkt_DispatchData_Chan6_Join
MidiPkt_DispatchData_Chan6_Skip2:
	ldda32	xwa, (0xbc10)
	ld	bc, 4:i3
	ldw	de, 17
	jp	MIDI_ReadChannelParam
MidiPkt_SendBankSelect:
	ldda32	xwa, (0xbc10)
	ld bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp l, 0:i3
	ret z
	ldda32	xwa, (0xbc10)
	ld bc, 5:i3
	call	SeqData_ReadFieldByIndex
	cp l, 0x2b
	jr	z, MidiPkt_SendBankSelect_Send
	cp l, 0x2c
	ret nz
MidiPkt_SendBankSelect_Send:
	ld	xwa, MidiPkt_EventType_Table_0x560
	ld bc, 5:i3
	call	ArpQueue_Enqueue
	ldda32	xwa, (0xbbc0)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	ret
MidiPkt_SysExValidator_Data:
	ld	a, (0x8c9a:16)
	cp	a, 108
	jr	c, MidiPkt_SysExValidator_Data_Skip
	cp	a, 118
	jr	ule, MidiPkt_SysExValidator_Data_Skip2
MidiPkt_SysExValidator_Data_Skip:
	bit	4, (0xfd50:16)
	ret	nz
MidiPkt_SysExValidator_Data_Skip2:
	cp	a, 153
	jr	ugt, MidiPkt_SysExValidator_Data_Skip3
	cp	a, 148
	ret	nc
MidiPkt_SysExValidator_Data_Skip3:
	set	7, (0x905d:16)
	lda	xbc, (0xfdad:16)
	ld	e, (xbc)
	set	2, e
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	ld	bc, 3:i3
	call	16624162
; v7 NAME DISPLACED: `MidiPkt_EnqueueControl_3358_SplitNibbles` (0xFDA0FF) falls inside the line above in the
; correct framing (v10 0xFDA8D0).  Kept as an alias because another v7
; file references this address by this name.
	.set MidiPkt_EnqueueControl_3358_SplitNibbles, MidiPkt_SysExValidator_Data_Skip3 + 28
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExProcessor_Data:
	ld	a, (0x8c9a:16)
	cp	a, 108
	jr	c, MidiPkt_SysExProcessor_Data_Skip
	cp	a, 118
	jr	ule, MidiPkt_SysExProcessor_Data_Skip2
MidiPkt_SysExProcessor_Data_Skip:
	bit	4, (0xfd50:16)
	ret	nz
MidiPkt_SysExProcessor_Data_Skip2:
	cp	a, 153
	jr	ugt, MidiPkt_SysExProcessor_Data_Skip3
	cp	a, 148
	ret	nc
MidiPkt_SysExProcessor_Data_Skip3:
	lda	xbc, (0xfdad:16)
	ld	a, (xbc)
	bit	2, a
	ret	z
	set	7, (0x905d:16)
	ld	e, (xbc)
	res	2, e
; v7 NAME DISPLACED: `MidiPkt_EnqueueControl_335E` (0xFDA137) falls inside the line above in the
; correct framing (v10 0xFDA908).  Kept as an alias because another v7
; file references this address by this name.
	.set MidiPkt_EnqueueControl_335E, MidiPkt_SysExProcessor_Data_Skip3 + 18
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	ld	bc, 3:i3
	call	16624162
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExBulkTransfer_Data:
	ldda32	xwa, (0xbc10)
	ld	bc, 1:i3
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	ret	lt
	cp	hl, 5:i3
	ret	gt
	add	hl, hl
	lda	xix, (0xee3370:24)
	ld	hl, (xix+hl)
	lda	xix, (0xfda17c:24)
	jp_rr 8, xix, hl
	jr	MidiPkt_SysExBulkTransfer_Data_Join
	jrl	MidiPkt_SysExBulkTransfer_Data_Join3
	jrl	MidiPkt_SysExBulkTransfer_Data_Join4
	jrl	MidiPkt_SysExBulkTransfer_Data_Helper2_Join
	jrl	MidiPkt_SysExBulkTransfer_Data_Helper2_Join2
	calr	MidiPkt_SendBankSelect_Helper
	ret
MidiPkt_SysExBulkTransfer_Data_Helper:
	lda	xde, (0x95a8:16)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	ld (xde+3), a
	push xde
	push xhl
	push xix
	push xiz
	call	MidiStream_ExtendedDispatch_0x298
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2:
	lda	xde, (0x95a8:16)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	ld (xde+3), a
	push xde
	push xhl
	push xix
	push xiz
	call	MidiStream_ExtendedDispatch_0x1
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_SysExBulkTransfer_Data_Join:
	lda	xsp, (xsp-12)
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, (0xbc10)
	ldw	bc, 9
	call	SeqData_ReadFieldByIndex
	ldb_erp l, 251
	sub_erpb 251, 16
	cp_erpb 251, 16
	jrl	nc, 244
	stb_erp a, 251
	extz	wa
	lda	xbc, (0xee337c:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ld	a, 199:opc
	swi	3
	.byte 0x99, 0xe1, 0x10	; v7 bytes do not decode as v10's `sub	(xbc-31), ix`
	lda	xbc, (xix+32)
	pushw	7424
	.byte 0xe5	; v7 bytes; v10 has: .byte 0xb6
	.byte 0x56	; v7 bytes do not decode as v10's `pop	xiz`
	swi	5
	cp	l, 2:i3
	jrl	ugt, 210
	cp_erpb 251, 15
	jrl z, 203
	stb_erp a, 251
	extz	wa
	cp	l, 0:i3
	jr	z, 97
	pushw	0
	ld	bc, 0:i3
	ld	de, 0:i3
	call	16567114
	stb_erp a, 251
	extz	wa
	pushw	0
	ldw	bc, 32
	ldw	de, 120
	call	16567114
	ld	xiy, MidiPkt_EventType_Table_0x340
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	stb_erp c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x344
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	stb_erp c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x348
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	stb_erp c, 251
	ld	(xwa), c
	jr	MidiPkt_SysExBulkTransfer_Data_Join2
	pushw	0
	ld	bc, 0:i3
	ld	de, 0:i3
	call	16567114
	stb_erp a, 251
	extz	wa
	pushw	0
	ldw	bc, 32
	ld	de, 0:i3
	call	16567114
	ld	xiy, MidiPkt_EventType_Table_0x34C
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	stb_erp c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x350
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	stb_erp c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x354
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	stb_erp c, 251
	ld	(xwa), c
MidiPkt_SysExBulkTransfer_Data_Join2:
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2
	pop qiz
	lda	xsp, (xsp+12)
	ret
MidiPkt_SysExBulkTransfer_Data_Join3:
	jrl	MidiPkt_SysExValidator_Data
MidiPkt_SysExBulkTransfer_Data_Join4:
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbc10)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	93
	extz	hl
	ld	xwa, 0x4b00
	ld	bc, hl
	call	16630064
	cp	hl, 0:i3
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Epilogue
	ld	xwa, 0x4b04
	call	16629800
	ld qiz, hl
	cp qiz, 0
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr	le, MidiPkt_SysExBulkTransfer_Data_Skip2
MidiPkt_SysExBulkTransfer_Data_Loop:
	ld	a, (xsp+4)
	extz	wa
	stb_erp c, 248
	extz	bc
	calr	SysEx_DispatchByChannel_Entry_Code_Sub
	ld	bc, hl
	cp	bc, 0xd8f0
	jr	z, MidiPkt_SysExBulkTransfer_Data_Skip
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4b10
	call	AppEvent_HandleChannelEvent_Helper
MidiPkt_SysExBulkTransfer_Data_Skip:
	inc	1, iz
	cp iz, qiz
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Loop
MidiPkt_SysExBulkTransfer_Data_Skip2:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
MidiPkt_SysExBulkTransfer_Data_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
; =============================================================================
; DSP Configuration & SysEx Processing
; =============================================================================
;
; DSP effect parameter handlers (reverb, chorus, EQ, compressor)
; and System Exclusive (SysEx) command processing. Manages effect
; presets and real-time parameter editing.
; =============================================================================

SysEx_DispatchByChannel_49_Entry_Code_Helper:
	cp a, 0x8
	jr	c, MidiPkt_SysExBulkTransfer_Data_Helper2_Skip
	ld a, 0x0:opc
MidiPkt_SysExBulkTransfer_Data_Helper2_Skip:
	extz wa
	lda	xbc, (0xee33a4:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Join:
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbc10)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2_Helper
	ld	(xsp+4), l
	ld	xwa, 0x4b04
	call	16629800
	ld qiz, hl
	cp qiz, 0
	jr	lt, SysEx_ClampVoiceIndex8_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr	le, SysEx_ClampVoiceIndex8_Join
SysEx_ClampVoiceIndex8_Loop:
	ld wa, iz
	exts	xwa
	add	xwa, 0x4b10
	call	16629526
	cp	hl, 1:i3
	jr	z, SysEx_ClampVoiceIndex8_Skip
	cp	hl, 2:i3
	jr	nz, SysEx_ClampVoiceIndex8_Skip2
SysEx_ClampVoiceIndex8_Skip:
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4b10
	ld	c, (xsp+4)
	extz	bc
	call	AppEvent_HandleChannelEvent_Helper
	jr	SysEx_ClampVoiceIndex8_Join
SysEx_ClampVoiceIndex8_Skip2:
	inc	1, iz
	cp	iz, qiz
	jr	lt, SysEx_ClampVoiceIndex8_Loop
SysEx_ClampVoiceIndex8_Join:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ClampVoiceIndex8_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Helper:
	cp a, 0x80
	jr	c, MidiPkt_SysExBulkTransfer_Data_Helper2_Skip2
	ld a, 0x0:opc
MidiPkt_SysExBulkTransfer_Data_Helper2_Skip2:
	extz wa
	lda	xbc, (0xee33ac:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Join2:
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbc10)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2_Helper2
	extz	hl
	ld	xwa, 0x4900
	ld	bc, hl
	call	AppEvent_HandleChannelEvent_Helper
	cp	hl, 0:i3
	jr	lt, SysEx_ClampVoiceIndex128_Epilogue
	ld	xwa, 0x4904
	call	16629800
	ld qiz, hl
	cp qiz, 0
	jr	lt, SysEx_ClampVoiceIndex128_Epilogue
	ld iz, 0:i3
	cp qiz, 0
	jr	le, SysEx_ClampVoiceIndex128_Skip2
SysEx_ClampVoiceIndex128_Loop:
	ld	a, (xsp+4)
	extz	wa
	stb_erp	c, 248
	extz	bc
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2_Helper4
	ld	bc, hl
	cp	bc, 0xd8f0
	jr	z, SysEx_ClampVoiceIndex128_Skip
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4910
	call	AppEvent_HandleChannelEvent_Helper
SysEx_ClampVoiceIndex128_Skip:
	inc	1, iz
	cp	iz, qiz
	jr	lt, SysEx_ClampVoiceIndex128_Loop
SysEx_ClampVoiceIndex128_Skip2:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ClampVoiceIndex128_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Helper2:
	cp a, 0x8
	jr	c, MidiPkt_SysExBulkTransfer_Data_Helper2_Skip3
	ld a, 0x0:opc
MidiPkt_SysExBulkTransfer_Data_Helper2_Skip3:
	extz wa
	lda	xbc, (0xee342c:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret
MidiPkt_SendBankSelect_Helper:
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbc10)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2_Helper3
	ld	(xsp+4), l
	ld	xwa, 0x4904
	call	16629800
	ld qiz, hl
	cp qiz, 0
	jr	lt, SysEx_ApplyToSlot49_Format_Data_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr	le, SysEx_ApplyToSlot49_Format_Data_Join
SysEx_ApplyToSlot49_Format_Data_Loop:
	ld wa, iz
	exts	xwa
	add	xwa, 0x4910
	call	16629526
	cp	hl, 1:i3
	jr	z, SysEx_ApplyToSlot49_Format_Data_Skip
	cp	hl, 2:i3
	jr	nz, SysEx_ApplyToSlot49_Format_Data_Skip2
SysEx_ApplyToSlot49_Format_Data_Skip:
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4910
	ld	c, (xsp+4)
	extz	bc
	call	AppEvent_HandleChannelEvent_Helper
	jr	SysEx_ApplyToSlot49_Format_Data_Join
SysEx_ApplyToSlot49_Format_Data_Skip2:
	inc	1, iz
	cp	iz, qiz
	jr	lt, SysEx_ApplyToSlot49_Format_Data_Loop
SysEx_ApplyToSlot49_Format_Data_Join:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ApplyToSlot49_Format_Data_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Helper3:
	cp a, 0x80
	jr	c, MidiPkt_SysExBulkTransfer_Data_Helper2_Skip4
	ld a, 0x0:opc
MidiPkt_SysExBulkTransfer_Data_Helper2_Skip4:
	extz wa
	lda	xbc, (0xee3434:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2_Helper4:
	ldw hl, 0xd8f0
	ld e, c
	extz de
	add de, de
	extz wa
	cp wa, 0:i3
	ret mi
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda	xix, (0xee3520:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda	xix, (0xfda542:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x468
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x472
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x480
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x48A
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 8
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x498
	jr	32
	cp	c, 8
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4A8
	jr	20
	cp	c, 7:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4B8
	jr	9
	cp	c, 7:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4C6
SysEx_DispatchByChannel_Entry:
	.byte 0xd3
	reti
	.byte 0xe0, 0xe8
	ld	c, 14:opc
SysEx_DispatchByChannel_Entry_Code_Sub:
	ldw hl, 0xd8f0
	ld e, c
	extz de
	add de, de
	extz wa
	cp wa, 0:i3
	ret mi
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda	xix, (0xee3584:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda	xix, (0xfda5c9:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4E4
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4EE
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x4F8
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x502
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x50C
	jr	31
	cp	c, 5:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x516
	jr	20
	cp	c, 6:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x520
	jr	9
	cp	c, 6:i3
	ret	nc
	ld	xwa, MidiPkt_EventType_Table_0x52C
SysEx_DispatchByChannel_49_Entry:
	.byte 0xd3
	reti
	.byte 0xe0, 0xe8
	ld	c, 14:opc
	cp c, 0xa
	ret ugt
	cp_spib_im 0xe0, 0xf0
	ret nz
	inc 1, xwa
	cp_spib_im 0xe0, 0x41
	ret nz
	inc 1, xwa
	cp_spib_im 0xe0, 0x42
	ret nz
	cp_spib_im 0xe0, 0x12
	ret nz
	cp_spib_im 0xe0, 0x40
	ret nz
	cp_spib_im 0xe0, 0x01
	ret nz
	cp c, 0:i3
	jr	nz, SysEx_DispatchByChannel_49_Entry_Code_Skip
	lda xbc, (0x00f180:24)
	add xbc, 0x2e0
	jr	SysEx_DispatchByChannel_49_Entry_Code_Join
SysEx_DispatchByChannel_49_Entry_Code_Skip:
	dec 1, c
	extz bc
	sla bc, 11
	ld de, bc
	exts xde
	lda xbc, (0x0ab000:24)
	add xbc, xde
	add xbc, 0x2e0
SysEx_DispatchByChannel_49_Entry_Code_Join:
	ldb_spi E, 0xe0
	cp e, 0x3a
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip4
	cp e, 0x38
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip3
	cp e, 0x33
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip2
	cp e, 0x30
	ret nz
	ld a, (xwa)
	extz wa
	jr	SysEx_DispatchByChannel_49_Entry_Code_Join2
SysEx_DispatchByChannel_49_Entry_Code_Skip2:
	ld a, (xwa)
	extz wa
	jrl	SysEx_DispatchByChannel_49_Entry_Code_Join3
SysEx_DispatchByChannel_49_Entry_Code_Skip3:
	ld a, (xwa)
	extz wa
	jrl	352
SysEx_DispatchByChannel_49_Entry_Code_Skip4:
	ld a, (xwa)
	extz wa
	calr	524
	ret
SysEx_DispatchByChannel_49_Entry_Code_Join2:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	lda xwa, (0xfc8e:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr	SysEx_DispatchByChannel_49_Entry_Code_Helper
	extz hl
	ld xwa, 0x4b00
	ld bc, hl
	ld xde, (xsp + 6)
	call	DataBuf_CopyVoiceBlock24_Code_Helper
	cp hl, 0:i3
	jr	lt, SysEx_DispatchByChannel_49_Entry_Code_Epilogue
	lda xwa, (0xfc8e:16)
	cp xwa, (xsp + 6)
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip5
	ld a, (xwa)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	extz wa
	calr	SysEx_DispatchByChannel_49_Entry_Code_Helper
	ld (0xfc8e:16), l
SysEx_DispatchByChannel_49_Entry_Code_Skip5:
	ld xwa, 0x4b04
	call	16629800
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr	ge, SysEx_DispatchByChannel_49_Entry_Code_Skip7
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip6
	ld a, (xsp + 4)
	ld (xbc), a
SysEx_DispatchByChannel_49_Entry_Code_Skip6:
	jr	SysEx_DispatchByChannel_49_Entry_Code_Epilogue
SysEx_DispatchByChannel_49_Entry_Code_Skip7:
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr	le, SysEx_DispatchByChannel_49_Entry_Code_Skip9
SysEx_DispatchByChannel_49_Entry_Code_Loop:
	ld a, (xsp + 10)
	extz wa
	stb_erp C, 0xf8
	extz bc
	calr	SysEx_DispatchByChannel_Entry_Code_Sub
	ld bc, hl
	cp bc, 0xd8f0
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Skip8
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	call	DataBuf_CopyVoiceBlock24_Code_Helper
SysEx_DispatchByChannel_49_Entry_Code_Skip8:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr	lt, SysEx_DispatchByChannel_49_Entry_Code_Loop
SysEx_DispatchByChannel_49_Entry_Code_Skip9:
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr	z, SysEx_DispatchByChannel_49_Entry_Code_Epilogue
	ld a, (xsp + 4)
	ld (xbc), a
SysEx_DispatchByChannel_49_Entry_Code_Epilogue:
	pop xiz
	inc 8, xsp
	ret
SysEx_DispatchByChannel_49_Entry_Code_Join3:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	lda xwa, (0xfc8e:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2_Helper
	ld (xsp + 10), l
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr	z, 12
	ld a, (xbc)
