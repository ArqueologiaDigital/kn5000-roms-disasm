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
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+6)
	ld	c, (xiz+7)
	call	Part_LookupTableEntry
	extz	hl
	ld	(xsp+4), hl
	ld	a, (xiz+6)
	ld	c, (xiz+7)
	inc	1, c
	call	Part_LookupTableEntry
	extz	hl
	sll	hl, 8
	or	(xsp+4), hl
	lda	xbc, (xsp+14)
	ld	a, (xiz+6)
	ld	(xbc), a
	ld	a, (xiz+7)
	ld	(xbc+1), a
	ld	wa, (xsp+4)
	ld	(xbc+2), wa
	ld	e, (xiz+8)
	extz	de
	ld	a, (xiz+11)
	and	a, 15
	jr	z, MidiPkt_ExtractAndPack_StoreShifted
	.byte 0xda, 0xfe	; sll a,de -- the backend cannot spell this form
MidiPkt_ExtractAndPack_StoreShifted:
	ld	(xbc+4), de
	lda	xwa, (xsp+6)
	ld	(xwa), xbc
	ld	(xwa+4), xiz
	calr	MidiPkt_EnqueueExtended_Data
	pop	xiz
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
	ld	xwa, (0xbcac:16)
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
	calr	MidiPkt_BuildControl_Helper
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ld	xwa, (0xbcac:16)
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
	calr	MidiPkt_EnqueueControl_3358
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), xwa
	ld	xiy, SeqData_SubDispatch_Table_0xBC
	lda	xix, (xsp+6)
	ldi85
	ldiw
	ld	xwa, (xsp+16)
	cp	(xwa+14), 1
	jrl	nc, MidiPkt_BuildControl_Epilogue
	ld	xwa, (xsp+16)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jrl	z, MidiPkt_BuildControl_Epilogue
	ld	xwa, (0xbcac:16)
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
	lda	xbc, (WidgetParam_SelfRef_Table_0x4:24)
	ld	xiz, (xbc+wa)
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xiz+1)
	call	Part_LookupTableEntry
	ld	a, (xiz+3)
	and	a, l
	jr	z, MidiPkt_BuildControl_Skip
	ld	(xsp+6), 129
MidiPkt_BuildControl_Skip:
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld	bc, 6:i3
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
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	lda	xwa, (xsp+6)
	ld	c, (xwa)
	and	c, 15
	ld	(xwa+1), c
	ld	c, (xwa)
	srl	c, 4
	ld	(xwa), c
	ld	bc, 3:i3
	call	ArpQueue_Enqueue
	call	ArpQueue_ComputeAndEnqueue
	ld	xwa, (0xbc5c:16)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_BuildControl_Epilogue:
	pop	xiz
	lda	xsp, (xsp+16)
	ret
	ret
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+18), xwa
	ld	xwa, (xsp+18)
	cp	(xwa+14), 255
	jr	z, MidiPkt_BuildControl_Epilogue2
	ld	xwa, (0xbcac:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	xde, (xsp+18)
	ld	a, (xde+6)
	or	a, l
	ld	(xsp+4), a
	ld	a, (xde+14)
	cp	a, 1:i3
	jr	nc, MidiPkt_BuildControl_Epilogue2
	extz	wa
	sla	wa, 2
	lda	xbc, (WidgetParam_SelfRef_Table_0xA:24)
	ld	xiz, (xbc+wa)
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xde+7)
	call	Part_LookupTableEntry
	lda	xbc, (xsp+14)
	lda	xwa, (xbc+2)
	cp	l, (xiz)
	jr	ugt, MidiPkt_BuildControl_Skip2
	ld	(xwa), 0
	jr	MidiPkt_BuildControl_Join
MidiPkt_BuildControl_Skip2:
	ld	(xwa), 1
MidiPkt_BuildControl_Join:
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
	calr	MidiPkt_BuildControl_Helper
MidiPkt_BuildControl_Epilogue2:
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
	ld c, (0x8ee4:16)
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
	bit 4, (0xfd50:16)
	jr nz, MidiPkt_ProcessEventQueue_Done
	bit 3, (0xfd56:16)
	jr z, MidiPkt_ProcessEventQueue_Done
	bit 0, (0xb7e7:16)
	jr nz, MidiPkt_ProcessEventQueue_Done
	lda xbc, (0xbd3c:16)
	ld wa, (0x90e0:16)
	ld iz, wa
	extz xiz
	add xiz, xbc

MidiPkt_ProcessEventQueue_Loop:
	push xiz
	call SeqVoice_StoreEntry
	inc 4, xsp
	ld (0xbd22:16), xhl
	lda xwa, (0xbd22:16)
	cp (xwa), 0xff
	jr z, MidiPkt_ProcessEventQueue_Done
	cp (xwa), 0xc0
	jr nc, MidiPkt_ProcessEventQueue_Next
	ld c, (xwa)
	extz bc
	sla bc, 2
	lda xde, (MidiPkt_EventType_Table:24)
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
	ld xbc, ToneKit_FrequencyTable_0x35A
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xbc, ToneKit_FrequencyTable_0x372
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xbc, ToneKit_FrequencyTable_0x37E
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xbc, ToneKit_FrequencyTable_0x38A
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xbc, ToneKit_FrequencyTable_0x396
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xbc, ToneKit_FrequencyTable_0x39E
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	cp a, 0:i3
	jr z, MidiPkt_DispatchViaTable_4DAE_Done
	ld xwa, xiz
	ld xbc, ToneKit_FrequencyTable_0x39E
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	ld xwa, MidiPkt_EventType_Table_0x584
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (0xbc5c:16)
	jr MidiPkt_DispatchSpecialType_SendAndUpdate

MidiPkt_DispatchSpecialType_Type10:
	cp a, 0x10
	jr nz, MidiPkt_DispatchSpecialType_Default
	ld xwa, MidiPkt_EventType_Table_0x58A
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (0xbc5c:16)

MidiPkt_DispatchSpecialType_SendAndUpdate:
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers
	jr MidiPkt_DispatchSpecialType_Return

MidiPkt_DispatchSpecialType_Default:
	ld xwa, xiz
	ld xbc, ToneKit_FrequencyTable_0x3B6
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
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
	lda xix, (WidgetParam_Entry_018_0xCE:24)

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
	ld xiy, MidiPkt_EventType_Table_0x300
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_3354_Return
	lda xbc, (WidgetParam_Entry_018_0xCE:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr z, MidiPkt_EnqueueControl_3354_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr z, MidiPkt_EnqueueControl_3354_Return
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
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
	ld bc, 3:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
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
	ld	xiy, MidiPkt_EventType_Table_0x304
	lda	xix, (xsp+4)
	ldi85
	ldiw
	ld	xwa, (xiz+4)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, MidiPkt_EnqueueExtended_Data_Epilogue
	lda	xwa, (0xee49e8:24)
	cp	xwa, (xiz+4)
	jr	z, MidiPkt_EnqueueExtended_Data_Epilogue
	ld	xwa, (xiz)
	cpw	(xwa+4), 0
	jr	z, MidiPkt_EnqueueExtended_Data_Epilogue
	ld	xwa, MidiPkt_EventType_Table_0x590
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	ld	xwa, (xiz+4)
	ld	bc, 6:i3
	call	ArpQueue_Enqueue
	ld	xwa, (xiz)
	ld	xbc, xwa
	ld	bc, (xbc+4)
	and	bc, (xwa+2)
	ld	xwa, (xiz+4)
	ld	a, (xwa+11)
	and	a, 15
	jr	z, MidiPkt_EnqueueExtended_Data_Skip
	.byte 0xd9, 0xff	; srl a,bc -- the backend cannot spell this form
MidiPkt_EnqueueExtended_Data_Skip:
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
	ldda32	xwa, (0xbc5c)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueExtended_Data_Epilogue:
	pop	xiz
	inc	4, xsp
	ret

MidiPkt_EnqueueControl_335C:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xiy, MidiPkt_EventType_Table_0x308
	lda xix, (xsp + 4)
	ldi85
	ldiw
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_335C_Return
	lda xbc, (WidgetParam_Entry_018_0xCE:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jr z, MidiPkt_EnqueueControl_335C_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jr z, MidiPkt_EnqueueControl_335C_Return
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
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
	ld bc, 3:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
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
	ld xiy, MidiPkt_EventType_Table_0x30C
	lda xix, (xsp + 4)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xwa, (xiz + 4)
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jrl z, MidiPkt_EnqueueControl_3358_Return
	lda xbc, (WidgetParam_Entry_018_0xCE:24)
	ld xwa, (xiz + 4)
	cp xbc, xwa
	jrl z, MidiPkt_EnqueueControl_3358_Return
	ld xbc, (xiz)
	ld a, (xwa + 8)
	and a, (xbc + 3)
	jrl z, MidiPkt_EnqueueControl_3358_Return
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xhl, (0x90f2:16)
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
	ld bc, 5:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
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
	ld xiy, MidiPkt_EventType_Table_0x312
	lda xix, (xsp + 4)
	ld bc, 2:i3
	ldirw
	ldi85
	lda xbc, (xsp + 10)
	ld (xbc), xiz
	lda xwa, (ToneKit_FrequencyTable_0xDA:24)
	ld (xbc + 4), xwa
	calr MidiPkt_CheckGateCondition
	cp hl, 0xffff
	jr z, MidiPkt_EnqueueControl_335E_Return
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (xsp + 14)
	ld bc, 6:i3
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
	ld bc, 5:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
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
	ld xiy, MidiPkt_EventType_Table_0x318
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
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xwa, (xiz + 4)
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld xbc, (xiz)
	ld xde, (xiz + 4)
	ld a, (xde + 8)
	and a, (xbc + 2)
	cp a, 1:i3
	jr nz, MidiPkt_EnqueueControl_3364_FormatData
	ld c, (0xfc61:16)
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
	ld bc, 3:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
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
	ld xiy, MidiPkt_EventType_Table_0x31C
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
	ld xwa, MidiPkt_EventType_Table_0x590
	ld bc, 6:i3
	call ArpQueue_Enqueue
	ld a, (0xfd99:16)
	and a, 0x1
	cp a, 1:i3
	jr nz, MidiPkt_EnqueueControl_3368_NoPedal
	ld xwa, ToneKit_FrequencyTable_0xB2
	ld bc, 6:i3
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
	ld bc, 6:i3
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
	ld bc, 3:i3
	call ArpQueue_Enqueue
	call ArpQueue_ComputeAndEnqueue
	ld xwa, (0xbc5c:16)
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

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
	ldi85
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
	call	Mem_Copy
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
	and	a, (xbc+2)
	ld	c, a
	ld	a, (xde+11)
	and	a, 15
	jr	z, MidiPkt_BuildControl_Helper_Skip
	.byte 0xcb, 0xff	; srl a,c -- the backend cannot spell this form
MidiPkt_BuildControl_Helper_Skip:
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
	ldda32	xwa, (0xbc5c)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
MidiPkt_EnqueueControl_3364_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret

MidiPkt_CheckGateCondition:
	ld c, (xwa + 12)
	cp c, 0:i3
	jr z, MidiPkt_CheckGateCondition_Second
	extz bc
	muls bc, 0x6
	lda xde, (ToneKit_FrequencyTable_0x3E2:24)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	ld xhl, (xde)
	ld c, (xde + 4)
	and c, (xhl)
	cp (xde + 5), c
	jr nz, MidiPkt_CheckGateCondition_Blocked

MidiPkt_CheckGateCondition_Second:
	ld a, (xwa + 13)
	cp a, 0:i3
	jr z, MidiPkt_CheckGateCondition_Pass
	extz wa
	muls wa, 0x6
	lda xbc, (ToneKit_FrequencyTable_0x3F4:24)
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld xde, (xbc)
	ld a, (xbc + 4)
	and a, (xde)
	cp (xbc + 5), a
	jr z, MidiPkt_CheckGateCondition_Pass

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
	ld xbc, ToneKit_FrequencyTable_0x3BE
	calr MidiPkt_MatchParamInTable
	lda xwa, (xsp + 4)
	lda xbc, (xwa + 4)
	ld (xbc), xhl
	ld (xwa), xiz
	ld xbc, (xbc)
	ld c, (xbc + 16)
	extz bc
	sla bc, 2
	lda xde, (WidgetParam_SelfRef_Table_0x136:24)
	exts xbc
	add xbc, xde
	ld xhl, (xbc)
	call (xhl)
	pop xiz
	inc 8, xsp
	ret

MidiPkt_DispatchData_Chan4:
	ld	(0xbcfc:16), 4
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan3:
	ld	(0xbcfc:16), 3
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan1:
	ld	(0xbcfc:16), 1
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan2:
	ld	(0xbcfc:16), 2
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan5:
	ld	(0xbcfc:16), 5
	jr	MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan6:
	ld	(0xbcfc:16), 6
	jr	t, MidiPkt_DispatchData_Chan6_Join2
MidiPkt_DispatchData_Chan6_Join:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccWrap_PlayModeDispatch
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (0xbcfc:16)
	extz	wa
	jp	SysEx_InitiateSend
MidiPkt_DispatchData_Chan6_Join2:
	ld	a, (0x8d36:16)
	cp	a, 87
	jr	z, MidiPkt_DispatchData_Chan6_Skip
	cp	(0x8d34:16), 1
	jr	nz, MidiPkt_DispatchData_Chan6_Skip2
	cp	a, 1:i3
	jr	nz, MidiPkt_DispatchData_Chan6_Skip2
MidiPkt_DispatchData_Chan6_Skip:
	jr	MidiPkt_DispatchData_Chan6_Join
MidiPkt_DispatchData_Chan6_Skip2:
	ld	xwa, (0xbcac:16)
	ld	bc, 4:i3
	ldw	de, 17
	jp	MIDI_ReadChannelParam

MidiPkt_SendBankSelect:
	ld xwa, (0xbcac:16)
	ld bc, 4:i3
	call SeqData_ReadFieldByIndex
	cp l, 0:i3
	ret z
	ld xwa, (0xbcac:16)
	ld bc, 5:i3
	call SeqData_ReadFieldByIndex
	cp l, 0x2b
	jr z, MidiPkt_SendBankSelect_Send
	cp l, 0x2c
	ret nz

MidiPkt_SendBankSelect_Send:
	ld xwa, MidiPkt_EventType_Table_0x560
	ld bc, 5:i3
	call ArpQueue_Enqueue
	ld xwa, (0xbc5c:16)
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers
	ret

MidiPkt_SysExValidator_Data:
	ld	a, (0x8d36:16)
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
	set	7, (0x90f9:16)
	lda	xbc, (0xfdad:16)
	ld	e, (xbc)
	set	2, e
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	ld	bc, 3:i3
	call	AssswbWr
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExProcessor_Data:
	ld	a, (0x8d36:16)
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
	set	7, (0x90f9:16)
	ld	e, (xbc)
	res	2, e
	ld	(xbc), e
	extz	de
	pushw	4
	ldw	wa, 145
	ld	bc, 3:i3
	call	AssswbWr
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	ret
MidiPkt_SysExBulkTransfer_Data:
	ld	xwa, (0xbcac:16)
	ld	bc, 1:i3
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	ret	lt
	cp	hl, 5:i3
	ret	gt
	add	hl, hl
	lda	xix, (MidiPkt_EventType_Table_0x324:24)
	ld	hl, (xix+hl)
	lda xix, (16623949:24)
	jp_rr 8, xix, hl
	jr	MidiPkt_SysExBulkTransfer_Data_Join
	jrl	MidiPkt_SysExBulkTransfer_Data_Join3
	jrl	MidiPkt_SysExBulkTransfer_Data_Join4
	jrl	SysEx_ApplyToSlot4B_Data
	jrl	SysEx_ApplyToSlot49_Data
	calr	SysEx_ApplyToSlot49_Format_Data
	ret
MidiPkt_SysExBulkTransfer_Data_Helper:
	lda	xde, (0x9644:16)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	ld	(xde+3), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MidiStream_ExtendedDispatch_0x298
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_SysExBulkTransfer_Data_Helper2:
	lda	xde, (0x9644:16)
	ld	c, (xwa)
	ld	(xde), c
	ld	c, (xwa+1)
	ld	(xde+1), c
	ld	c, (xwa+2)
	ld	(xde+2), c
	ld	a, (xwa+3)
	ld	(xde+3), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MidiStream_ExtendedDispatch_0x1
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_SysExBulkTransfer_Data_Join:
	lda	xsp, (xsp-12)
	push	qiz
	ldda32	xwa, (0xbcac)
	ldw	bc, 9
	call	SeqData_ReadFieldByIndex
	ldb_erp	l, 251
	sub_erpb	251, 16
	cp_erpb	251, 16
	jrl	nc, MidiPkt_SysExBulkTransfer_Data_Helper2_Epilogue
	stb_erp	a, 251
	extz	wa
	lda	xbc, (0xee337c:24)
	ld	a, (xbc+wa)
	ldb_erp	a, 251
	ldda32	xwa, (0xbcac)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	cp	l, 2:i3
	jrl	ugt, MidiPkt_SysExBulkTransfer_Data_Helper2_Epilogue
	cp_erpb	251, 15
	jrl	z, MidiPkt_SysExBulkTransfer_Data_Helper2_Epilogue
	stb_erp	a, 251
	extz	wa
	cp	l, 0:i3
	jr	z, MidiPkt_SysExBulkTransfer_Data_Helper2_Skip
	pushw	0
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SndParam_NotifyAndReturn
	stb_erp	a, 251
	extz	wa
	pushw	0
	ldw	bc, 32
	ldw	de, 120
	call	SndParam_NotifyAndReturn
	ld	xiy, MidiPkt_EventType_Table_0x340
	lda	xix, (xsp+10)
	ldiw
	ldiw
	lda	xwa, (xsp+10)
	stb_erp	c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x344
	lda	xix, (xsp+6)
	ldiw
	ldiw
	lda	xwa, (xsp+6)
	stb_erp	c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x348
	lda	xix, (xsp+2)
	ldiw
	ldiw
	lda	xwa, (xsp+2)
	stb_erp	c, 251
	ld	(xwa), c
	jr	MidiPkt_SysExBulkTransfer_Data_Join2
MidiPkt_SysExBulkTransfer_Data_Helper2_Skip:
	pushw	0
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SndParam_NotifyAndReturn
	stb_erp	a, 251
	extz	wa
	pushw	0
	ldw	bc, 32
	ld	de, 0:i3
	call	SndParam_NotifyAndReturn
	ld	xiy, MidiPkt_EventType_Table_0x34C
	lda	xix, (xsp+10)
	ldiw
	ldiw
	lda	xwa, (xsp+10)
	stb_erp	c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x350
	lda	xix, (xsp+6)
	ldiw
	ldiw
	lda	xwa, (xsp+6)
	stb_erp	c, 251
	ld	(xwa), c
	calr	MidiPkt_SysExBulkTransfer_Data_Helper
	ld	xiy, MidiPkt_EventType_Table_0x354
	lda	xix, (xsp+2)
	ldiw
	ldiw
	lda	xwa, (xsp+2)
	stb_erp	c, 251
	ld	(xwa), c
MidiPkt_SysExBulkTransfer_Data_Join2:
	calr	MidiPkt_SysExBulkTransfer_Data_Helper2
MidiPkt_SysExBulkTransfer_Data_Helper2_Epilogue:
	pop	qiz
	lda	xsp, (xsp+12)
	ret
MidiPkt_SysExBulkTransfer_Data_Join3:
	jrl	MidiPkt_SysExValidator_Data
MidiPkt_SysExBulkTransfer_Data_Join4:
	dec	2, xsp
	push	xiz
	ldda32	xwa, (0xbcac)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	SysEx_ClampVoiceIndex8
	extz	hl
	ld	xwa, 0x4b00
	ld	bc, hl
	call	DSPCfg_WriteParamFull
	cp	hl, 0:i3
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Epilogue
	ld	xwa, 0x4b04
	call	DSPCfg_ReadParam_Map0
	ld	qiz, hl
	cp	qiz, 0
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Epilogue
	ld	iz, 0:i3
	cp	qiz, 0
	jr	le, MidiPkt_SysExBulkTransfer_Data_Skip2
MidiPkt_SysExBulkTransfer_Data_Loop:
	ld	a, (xsp+4)
	extz	wa
	stb_erp	c, 248
	extz	bc
	calr	SysEx_DispatchByChannel_49
	ld	bc, hl
	cp	bc, 0xd8f0
	jr	z, MidiPkt_SysExBulkTransfer_Data_Skip
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4b10
	call	DSPCfg_WriteParamFull
MidiPkt_SysExBulkTransfer_Data_Skip:
	inc	1, iz
	cp	iz, qiz
	jr	lt, MidiPkt_SysExBulkTransfer_Data_Loop
MidiPkt_SysExBulkTransfer_Data_Skip2:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
MidiPkt_SysExBulkTransfer_Data_Epilogue:
	pop	xiz
	inc	2, xsp
	ret

