; =============================================================================
; MIDI Packet Routines
; =============================================================================
;
; MIDI packet extraction, packing, and queue management.
; Handles the low-level MIDI message framing between the
; serial I/O layer and the dispatch handlers.
; =============================================================================

MidiPkt_ExtractAndPack:
	; --- Stack-frame: XIZ struct field extraction + packed lookup (96 bytes) ---
	lda	xsp, (xsp-16)
	push xiz
	ld xiz, xwa
	ld a, (xiz+6)
	ld c, (xiz+7)
	call Part_LookupTableEntry
	extz hl
	ld (xsp+4), hl
	ld a, (xiz+6)
	ld c, (xiz+7)
	inc 1, c
	call Part_LookupTableEntry
	extz hl
	sll	hl, 8
	or (xsp+4), hl
	lda	xbc, (xsp+14)
	ld a, (xiz+6)
	ld (xbc), a
	ld a, (xiz+7)
	ld (xbc+1), a
	ld wa, (xsp+4)
	ld (xbc+2), wa
	ld e, (xiz+8)
	extz de
	ld a, (xiz+0x0b)
	and a, 0x0f
	jr z, MidiPkt_ExtractAndPack_StoreShifted
	.byte 0xda
	swi	6
MidiPkt_ExtractAndPack_StoreShifted:
	ld (xbc+4), de
	lda	xwa, (xsp+6)
	ld (xwa), xbc
	ld (xwa+4), xiz
	calr MidiPkt_EnqueueExtended_Data
	pop xiz
	lda	xsp, (xsp+16)
	ret
MidiPkt_ExtractAndPack_Ret:
	ret


MidiPkt_BuildDirect:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 12)
	lda xde, (xiz + 6)
	ld a, (xde)
	ld (xbc), a
	lda xhl, (xiz + 7)
	ld a, (xhl)
	ld (xbc + 1), a
	ld a, (xde)
	ld c, (xhl)
	call Part_LookupTableEntry
	lda xbc, (xsp + 12)
	ld (xbc + 2), l
	ld a, (xiz + 8)
	ld (xbc + 3), a
	lda xwa, (xsp + 4)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr MidiPkt_EnqueueControl_335C
	pop xiz
	lda xsp, (xsp + 12)
	ret

; --- MIDI_BuildControlPacket: Construct a 4-byte MIDI control packet ---
; Two entry points building MIDI packets from a parameter structure (XIZ):
; 1) Full packet: reads MIDI map value from table at 0xbccc (via 0xfd6eb6),
;    adjusts by subtracting 0x20, ORs with (xiz+6) for status byte,
;    copies controller number from *(xiz+7), computes data byte via
;    lookup (0xfd822d), copies channel from (xiz+8).
; 2) Simple packet: same status byte construction but data byte 2 = 0.
; Output: 4-byte packet pointer + source struct pointer stored to (XWA).
MidiPkt_BuildControl:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	c, l
	ld	l, (xiz+6)
	or	l, c
	lda	xbc, (xsp+12)
	ld	(xbc), l
	lda	xde, (xiz+7)
	ld	a, (xde)
	ld	(xbc+1), a
	extz	hl
	ld	c, (xde)
	ld	wa, hl
	call	Part_LookupTableEntry
	lda	xbc, (xsp+12)
	ld	(xbc+2), l
	ld	a, (xiz+8)
	ld	(xbc+3), a
	lda	xwa, (xsp+4)
	ld	(xwa), xbc
	ld	(xwa+4), xiz
	calr	2277
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	a, (xiz+6)
	or	a, l
	lda	xbc, (xsp+12)
	ld	(xbc), a
	ld	a, (xiz+7)
	ld	(xbc+1), a
	ld	(xbc+2), 0
	ld	a, (xiz+8)
	ld	(xbc+3), a
	lda	xwa, (xsp+4)
	ld	(xwa), xbc
	ld	(xwa+4), xiz
	calr	1512
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), xwa
	ld	xiy, 15609928
	lda	xix, (xsp+6)
	ldi85
	ldiw
	ld	xwa, (xsp+16)
	cp	(xwa+14), 1
	jrl	nc, 181
	ld	xwa, (xsp+16)
	calr	2344
	cp	hl, 65535
	jrl	z, 168
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	xbc, (xsp+16)
	ld	a, (xbc+6)
	or	a, l
	ld	(xsp+4), a
	extz	wa
	ld	c, (xbc+7)
	call	Part_LookupTableEntry
	ld	(xsp+6), l
	ld	xwa, (xsp+16)
	ld	a, (xwa+14)
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617568
	ld_rrl	xiz, xbc, wa
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xiz+1)
	call	Part_LookupTableEntry
	ld	a, (xiz+3)
	and	a, l
	jr	z, 4
	ld	(xsp+6), 129
	ld	xwa, 15611356
	lds	bc, 6
	call	ArpQueue_Enqueue
	pushw 6
	lda	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+10)
	ld	c, (xsp+4)
	add	c, 32
	ld	(xwa+1), c
	lds	bc, 6
	call	ArpQueue_Enqueue
	lda	xwa, (xsp+6)
	ld	c, (xwa)
	and	c, 15
	ld	(xwa+1), c
	ld	c, (xwa)
	srl	c, 4
	ld	(xwa), c
	lds	bc, 3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, 48220
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	ret
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+18), xwa
	ld	xwa, (xsp+18)
	cp	(xwa+14), 255
	jr	z, 108
	ldda32	xwa, 48300
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	xde, (xsp+18)
	ld	a, (xde+6)
	or	a, l
	ld	(xsp+4), a
	ld	a, (xde+14)
	cps	a, 1
	jr	nc, 76
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15617574
	ld_rrl	xiz, xbc, wa
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xde+7)
	call	Part_LookupTableEntry
	lda	xbc, (xsp+14)
	lda	xwa, (xbc+2)
	cp	l, (xiz)
	jr	ugt, 5
	ld	(xwa), 0
	jr	3
	ld	(xwa), 1
	ld	a, (xsp+4)
	ld	(xbc), a
	ld	xde, (xsp+18)
	ld	a, (xde+7)
	ld	(xbc+1), a
	ld	a, (xde+8)
	ld	(xbc+3), a
	lda	xwa, (xsp+6)
	ld	(xwa), xbc
	ld	(xwa+4), xde
	calr	1870
	pop	xiz
	lda	xsp, (xsp+18)
	ret

MidiPkt_BuildStatusDirect:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	lda xbc, (xsp + 12)
	lda xde, (xiz + 6)
	ld a, (xde)
	ld (xbc), a
	lda xhl, (xiz + 7)
	ld a, (xhl)
	ld (xbc + 1), a
	ld a, (xde)
	ld c, (xhl)
	call Part_LookupTableEntry
	lda xbc, (xsp + 12)
	ld (xbc + 2), l
	ld a, (xiz + 8)
	ld (xbc + 3), a
	lda xwa, (xsp + 4)
	ld (xwa), xbc
	ld (xwa + 4), xiz
	calr MidiPkt_EnqueueControl_3364
	pop xiz
	lda xsp, (xsp + 12)
	ret

MidiPkt_BuildFromConstant:
	lda xsp, (xsp - 12)
	lda xde, (xsp + 8)
	ld c, (xwa + 6)
	ld (xde), c
	ld c, (xwa + 7)
	ld (xde + 1), c
	ldda8 c, 36580
	ld (xde + 2), c
	ld c, (xwa + 8)
	ld (xde + 3), c
	lda xbc, (xsp)
	ld (xbc), xde
	ld (xbc + 4), xwa
	ld xwa, xbc
	calr MidiPkt_EnqueueControl_3354
	lda xsp, (xsp + 12)
	ret

MidiPkt_BuildZeroData:
	lda xsp, (xsp - 12)
	ld xbc, xwa
	lda xde, (xsp + 8)
	ld a, (xbc + 6)
	ld (xde), a
	ld a, (xbc + 7)
	ld (xde + 1), a
	ld (xde + 2), 0x0
	ld a, (xbc + 8)
	ld (xde + 3), a
	lda xwa, (xsp)
	ld (xwa), xde
	ld (xwa + 4), xbc
	calr MidiPkt_EnqueueControl_3358
	lda xsp, (xsp + 12)
	ret

MidiPkt_ProcessEventQueue:
	push xiz
	bitda 4, 64848
	jr nz, MidiPkt_ProcessEventQueue_Done
	bitda 3, 64854
	jr z, MidiPkt_ProcessEventQueue_Done
	bitda 0, 47079
	jr nz, MidiPkt_ProcessEventQueue_Done
	ldada xbc, 48444
	ldda16 xwa, 37088
	ld iz, wa
	extz xiz
	add xiz, xbc

MidiPkt_ProcessEventQueue_Loop:
	push xiz
	call SeqVoice_StoreEntry
	inc 4, xsp
	stda32 48418, xhl
	ldada xwa, 48418
	cp (xwa), 0xff
	jr z, MidiPkt_ProcessEventQueue_Done
	cp (xwa), 0xc0
	jr nc, MidiPkt_ProcessEventQueue_Next
	ld c, (xwa)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee304c
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)

MidiPkt_ProcessEventQueue_Next:
	inc 4, xiz
	jr MidiPkt_ProcessEventQueue_Loop

MidiPkt_ProcessEventQueue_Done:
	pop xiz
	ret

MidiPkt_Nop:
	ret

MidiPkt_DispatchViaTable_4D6A:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0xee4d6a
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret

MidiPkt_DispatchViaTable_4D82:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0xee4d82
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret

MidiPkt_DispatchViaTable_4D8E:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0xee4d8e
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret

MidiPkt_DispatchViaTable_4D9A:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0xee4d9a
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
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
	ld xbc, 0xee4da6
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
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
	ld xbc, 0xee4dae
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	cp (xiz + 1), 0xb
	jr nz, MidiPkt_DispatchViaTable_4DAE_Done
	lda xde, (xiz + 3)
	ld xwa, (xsp + 8)
	ld c, (xwa + 8)
	cpl c
	ld a, (xde)
	and a, c
	ld (xde), a
	cps a, 0
	jr z, MidiPkt_DispatchViaTable_4DAE_Done
	ld xwa, xiz
	ld xbc, 0xee4dae
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
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
	jr nz, MidiPkt_DispatchSpecialType_Type10
	ld xwa, 0xee35d0
	lds bc, 6
	call ArpQueue_Enqueue
	ldda32 xwa, 48220
	jr MidiPkt_DispatchSpecialType_SendAndUpdate

MidiPkt_DispatchSpecialType_Type10:
	cp a, 0x10
	jr nz, MidiPkt_DispatchSpecialType_Default
	ld xwa, 0xee35d6
	lds bc, 6
	call ArpQueue_Enqueue
	ldda32 xwa, 48220

MidiPkt_DispatchSpecialType_SendAndUpdate:
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers
	jr MidiPkt_DispatchSpecialType_Return

MidiPkt_DispatchSpecialType_Default:
	ld xwa, xiz
	ld xbc, 0xee4dc6
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
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
	lda_24 xix, 0xee49e8

MidiPkt_MatchParamInTable_Loop:
	ld_spil XHL, 0xea
	cp xix, xhl
	ret z
	ld c, (xhl + 7)
	cp c, (xwa + 1)
	jr nz, MidiPkt_MatchParamInTable_Loop
	ld c, (xhl + 8)
	and c, (xwa + 3)
	jr z, MidiPkt_MatchParamInTable_Loop
	ret

MidiPkt_EnqueueControlNop:
	ret

MidiPkt_EnqueueControl_3354:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xiy, 0xee334c
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_3354_Return
	lda_24 xbc, 0xee49e8
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr z, MidiPkt_EnqueueControl_3354_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr z, MidiPkt_EnqueueControl_3354_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	lds bc, 6
	call ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr z, MidiPkt_EnqueueControl_3354_ShiftBits
	srla c

MidiPkt_EnqueueControl_3354_ShiftBits:
	lda xwa, (xsp + 4)
	ld (xwa), c
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	lds bc, 3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_3354_Return:
	pop xiz
	inc 4, xsp
	ret

MidiPkt_EnqueueExtended_Data:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15610704
	lda	xix, (xsp+4)
	.byte 0x85
	rcf
	ldiw
	ld	xwa, (xiz+4)
	calr	1118
	cp	hl, 65535
	jr	z, 102
	lda_24	xwa, 15616488
	.byte 0xae, 0x04, 0xf0
	jr	z, 92
	ld	xwa, (xiz)
	.byte 0x98, 0x04
	push	xsp
	nop
	nop
	jr	z, 83
	ld	xwa, 15611356
	lds	bc, 6
	call	ArpQueue_Enqueue
	ld	xwa, (xiz+4)
	lds	bc, 6
	call	ArpQueue_Enqueue
	ld	xwa, (xiz)
	ld	xbc, xwa
	ld	bc, (xbc+4)
	.byte 0x98
	push_sr
	ldda8	w, 1198
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
	lds	bc, 3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, 48220
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	pop	xiz
	inc	4, xsp
	ret

MidiPkt_EnqueueControl_335C:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xiy, 0xee3354
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_335C_Return
	lda_24 xbc, 0xee49e8
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr z, MidiPkt_EnqueueControl_335C_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr z, MidiPkt_EnqueueControl_335C_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	lds bc, 6
	call ArpQueue_Enqueue
	lda xwa, (xsp + 4)
	ld (xwa), 0x0
	ld xde, (xiz)
	ld xbc, (xiz + 4)
	ld c, (xbc + 8)
	and c, (xde + 2)
	jr z, MidiPkt_EnqueueControl_335C_ZeroData
	ld (xwa), 0x7f

MidiPkt_EnqueueControl_335C_ZeroData:
	ld c, (xwa)
	and c, 0xf
	ld (xwa + 1), c
	ld c, (xwa)
	srl c, 4
	ld (xwa), c
	lds bc, 3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_335C_Return:
	pop xiz
	inc 4, xsp
	ret

MidiPkt_EnqueueControl_3358:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld xiy, 0xee3358
	lda xix, (xsp + 4)
	lds bc, 2
	ldirw
	ldi85
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jrl z, MidiPkt_EnqueueControl_3358_Return
	lda_24 xbc, 0xee49e8
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jrl z, MidiPkt_EnqueueControl_3358_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jrl z, MidiPkt_EnqueueControl_3358_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	lds bc, 6
	call ArpQueue_Enqueue
	ldda32 xhl, 37106
	ld xwa, (xiz)
	ld a, (xwa)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	cp xwa, 0xffffffff
	jr z, MidiPkt_EnqueueControl_3358_Return
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
	jr z, MidiPkt_EnqueueControl_3358_SplitNibbles
	res 7, c
	ld (xwa), c
	ld c, (xde)
	set 7, c
	ld (xde), c

MidiPkt_EnqueueControl_3358_SplitNibbles:
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
	lds bc, 5
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_3358_Return:
	pop xiz
	inc 6, xsp
	ret

MidiPkt_EnqueueControl_335E:
	lda xsp, (xsp - 14)
	push xiz
	ld xiz, xwa
	ld xiy, 0xee335e
	lda xix, (xsp + 4)
	lds bc, 2
	ldirw
	ldi85
	lda xbc, (xsp + 10)
	ld (xbc), xiz
	lda_24 xwa, 0xee4aea
	ld (xbc + 4), xwa
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_335E_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ld xwa, (xsp + 14)
	lds bc, 6
	call ArpQueue_Enqueue
	lda xwa, (xsp + 4)
	ld c, (xiz)
	ld (xwa), c
	lda xde, (xwa + 2)
	ld c, (xiz + 1)
	ld (xde), c
	ld c, (xwa)
	bit 7, c
	jr z, MidiPkt_EnqueueControl_335E_SplitNibbles
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
	lds bc, 5
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_335E_Return:
	pop xiz
	lda xsp, (xsp + 14)
	ret

MidiPkt_EnqueueControl_3364:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xiy, 0xee3364
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_3364_Return
	ld xbc, (xiz)
	ld xwa, (xiz + 4)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr z, MidiPkt_EnqueueControl_3364_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	lds bc, 6
	call ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	cps a, 1
	jr nz, MidiPkt_EnqueueControl_3364_FormatData
	ldda8 c, 64609
	and c, 0x30
	ld a, (xde + 11)
	and a, 0xf
	jr z, MidiPkt_EnqueueControl_3364_NoShift
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
	lds bc, 3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_3364_Return:
	pop xiz
	inc 4, xsp
	ret

MidiPkt_EnqueueControl_3368:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xiy, 0xee3368
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jrl z, MidiPkt_EnqueueControl_3368_Return
	ld xbc, (xiz)
	ld xwa, (xiz + 4)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jrl z, MidiPkt_EnqueueControl_3368_Return
	ld xwa, 0xee35dc
	lds bc, 6
	call ArpQueue_Enqueue
	ldda8 a, 64921
	and a, 0x1
	cps a, 1
	jr nz, MidiPkt_EnqueueControl_3368_NoPedal
	ld xwa, 0xee4ac2
	lds bc, 6
	call ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr z, MidiPkt_EnqueueControl_3368_PedalNoShift
	srla c

MidiPkt_EnqueueControl_3368_PedalNoShift:
	inc 1, c
	jr MidiPkt_EnqueueControl_3368_FormatData

MidiPkt_EnqueueControl_3368_NoPedal:
	ld xwa, (xiz + 4)
	lds bc, 6
	call ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	ld c, a
	ld a, (xde + 11)
	and a, 0xf
	jr z, MidiPkt_EnqueueControl_3368_FormatData
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
	lds bc, 3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

MidiPkt_EnqueueControl_3368_Return:
	pop xiz
	inc 4, xsp
	ret

MidiPkt_EnqueueExtended2_Data:
	ret
	lda	xsp, (xsp-10)
	push	xiz
	ld	xiz, xwa
	ld	xiy, 15610732
	lda	xix, (xsp+4)
	.byte 0x85
	rcf
	ldiw
	ld	xwa, (xiz+4)
	calr	145
	cp	hl, 65535
	jrl	z, 133
	lda_24	xbc, 15616488
	ld	xwa, (xiz+4)
	cp	xbc, xwa
	jr	z, 121
	ld	xbc, (xiz)
	ld	a, (xwa+8)
	and	a, (xbc+3)
	jr	z, 111
	ld	xwa, 15611356
	lds	bc, 6
	call	ArpQueue_Enqueue
	pushw	6
	lda	xwa, (xsp+10)
	push	xwa
	ld	xwa, (xiz+4)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+8)
	ld	xbc, (xiz)
	ld	c, (xbc)
	set	5, c
	ld	(xwa+1), c
	lds	bc, 6
	call	ArpQueue_Enqueue
	ld	xbc, (xiz)
	ld	xde, (xiz+4)
	ld	a, (xde+8)
	.byte 0x89
	push_sr
	adddm8	35785, b
	pushw	51489
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
	lds	bc, 3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ldda32	xwa, 48220
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	pop	xiz
	lda	xsp, (xsp+10)
	ret

MidiPkt_CheckGateCondition:
	ld c, (xwa + 12)
	cps c, 0
	jr z, MidiPkt_CheckGateCondition_Second
	extz bc
	muls bc, 0x6
	lda_24 xde, 0xee4df2
	st_dri3b B, 0x07, 0xe8, 0xe4
	ld xhl, (xde)
	ld c, (xde + 4)
	and c, (xhl)
	cp (xde + 5), c
	jr nz, MidiPkt_CheckGateCondition_Blocked

MidiPkt_CheckGateCondition_Second:
	ld a, (xwa + 13)
	cps a, 0
	jr z, MidiPkt_CheckGateCondition_Pass
	extz wa
	muls wa, 0x6
	lda_24 xbc, 0xee4e04
	st_dri3b A, 0x07, 0xe4, 0xe0
	ld xde, (xbc)
	ld a, (xbc + 4)
	and a, (xde)
	cp (xbc + 5), a
	jr z, MidiPkt_CheckGateCondition_Pass

MidiPkt_CheckGateCondition_Blocked:
	ldw hl, 0xffff
	ret

MidiPkt_CheckGateCondition_Pass:
	lds hl, 0
	ret

MidiPkt_DispatchViaTable_4DCE:
	dec 8, xsp
	push xiz
	ld xiz, (xsp + 16)
	ld xwa, xiz
	ld xbc, 0xee4dce
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda_24 xde, 0xee4f52
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret

MidiPkt_DispatchData_Chan4:
	stdi8	48380, 4
	jr	57
MidiPkt_DispatchData_Chan3:
	stdi8	48380, 3
	jr	50
MidiPkt_DispatchData_Chan1:
	stdi8	48380, 1
	jr	43
MidiPkt_DispatchData_Chan2:
	stdi8	48380, 2
	jr	36
MidiPkt_DispatchData_Chan5:
	stdi8	48380, 5
	jr	29
MidiPkt_DispatchData_Chan6:
	stdi8	48380, 6
	jr	t, 0x16
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccWrap_PlayModeDispatch
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldda8	a, 48380
	extz	wa
	jp	SysEx_InitiateSend
	ldda8	a, 36150
	cp	a, 87
	jr	z, 11
	cpdi8	36148, 1
	jr	nz, 6
	cps	a, 1
	jr	nz, 2
	jr	-44
	ldda32	xwa, 48300
	lds	bc, 4
	ldw	de, 17
	jp	MIDI_ReadChannelParam

MidiPkt_SendBankSelect:
	ldda32 xwa, 48300
	lds bc, 4
	call SeqData_ReadFieldByIndex
	cps l, 0
	ret z
	ldda32 xwa, 48300
	lds bc, 5
	call SeqData_ReadFieldByIndex
	cp l, 0x2b
	jr z, MidiPkt_SendBankSelect_Send
	cp l, 0x2c
	ret nz

MidiPkt_SendBankSelect_Send:
	ld xwa, 0xee35ac
	lds bc, 5
	call ArpQueue_Enqueue
	ldda32 xwa, 48220
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers
	ret

MidiPkt_SysExValidator_Data:
	ldda8	a, 36150
	cp	a, 108
	jr	c, 5
	cp	a, 118
	jr	ule, 6
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	cp	a, 153
	jr	ugt, 5
	cp	a, 148
	ret	nc
	.byte 0xf1
	swi	1
	.byte 0x90, 0xbf
	ldada	xbc, 64941
	ld	e, (xbc)
	set	2, e
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	lds	bc, 3
	call	AssswbWr
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExProcessor_Data:
	ldda8	a, 36150
	cp	a, 108
	jr	c, 5
	cp	a, 118
	jr	ule, 6
	.byte 0xf1, 0x50
	swi	5
	sbc	w, d
	swi	6
	cp	a, 153
	jr	ugt, 5
	cp	a, 148
	ret	nc
	ldada	xbc, 64941
	ld	a, (xbc)
	bit	2, a
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xbf
	ld	e, (xbc)
	res	2, e
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	lds	bc, 3
	call	AssswbWr
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExBulkTransfer_Data:
	ldda32	xwa, 48300
	lds	bc, 1
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cps	hl, 0
	ret	lt
	cps	hl, 5
	ret	gt
	add	hl, hl
	lda_24	xix, 15610736
	.byte 0xd3
	reti
	.byte 0xf0, 0xec
	ldb	c, 242
	popw	iy
	.byte 0xa9
	swi	5
	ldw	ix, 2035
	.byte 0xf0
	cps	xix, 0
	jr	98
	jrl	377
	jrl	377
	jrl	512
	jrl	641
	calr	776
	ret
	ldada	xde, 38468
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	.byte 0xba
	pop_sr
	ld	xbc, 0x3e3c3b3a
	call	16567732
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	ldada	xde, 38468
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	.byte 0xba
	pop_sr
	ld	xbc, 0x3e3c3b3a
	call	16567069
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	lda	xsp, (xsp-12)
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda32	xwa, 48300
	ldw	bc, 9
	call	SeqData_ReadFieldByIndex
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	.byte 0xca
	rcf
	.byte 0xc7
	swi	3
	.byte 0xcf
	rcf
	jrl	nc, 244
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda_24	xbc, 15610748
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 199
	swi	3
	sub	(xbc-31), ix
	lda	xbc, (xix+32)
	pushw	7424
	.byte 0xb6
	pop	xiz
	swi	5
	cps	l, 2
	jrl	ugt, 210
	.byte 0xc7
	swi	3
	.byte 0xcf
	retd	52086
	nop
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	cps	l, 0
	jr	z, 97
	pushw	0
	lds	bc, 0
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	0
	ldw	bc, 32
	ldw	de, 120
	call	SndParam_NotifyAndReturn
	ld	xiy, 15610764
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65321
	ld	xiy, 15610768
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65298
	ld	xiy, 15610772
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	jr	94
	pushw	0
	lds	bc, 0
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	pushw	0
	ldw	bc, 32
	lds	de, 0
	call	SndParam_NotifyAndReturn
	ld	xiy, 15610776
	lda	xix, (xsp+10)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+10)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65225
	ld	xiy, 15610780
	lda	xix, (xsp+6)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+6)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65202
	ld	xiy, 15610784
	lda	xix, (xsp+2)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+2)
	.byte 0xc7
	swi	3
	.byte 0x8b
	ld	(xwa), c
	calr	65218
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+12)
	ret
	jrl	-568
	dec	2, xsp
	push	xiz
	ldda32	xwa, 48300
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	93
	extz	hl
	ld	xwa, 19200
	ld	bc, hl
	call	DSPCfg_WriteParamFull
	cps	hl, 0
	jr	lt, 72
	ld	xwa, 19204
	call	DSPCfg_ReadParam_Map0
	.byte 0xd7
	swi	2
	cp	(xhl-41), de
	inc	1, wa
	.byte 0x37
	lds	iz, 0
	.byte 0xd7
	swi	2
	inc	2, wa
	pushw	de
	ld	a, (xsp+4)
	extz	wa
	.byte 0xc7
	swi	0
	.byte 0x8b
	extz	bc
	calr	596
	ld	bc, hl
	cp	bc, 55536
	jr	z, 14
	ld	wa, iz
	exts	xwa
	add	xwa, 19216
	call	DSPCfg_WriteParamFull
	inc	1, iz
	.byte 0xd7
	swi	2
	.byte 0xf6
	jr	lt, -42
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xiz
	inc	2, xsp
	ret

