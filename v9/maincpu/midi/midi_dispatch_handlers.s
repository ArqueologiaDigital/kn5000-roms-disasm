; =============================================================================
; MIDI Dispatch Handlers (11K lines)
; =============================================================================
;
; MIDI Control Change handlers (22 types), serial input parsing,
; file data validation, sound mode handlers, and arpeggiator queue.
; The main MIDI message routing and processing layer.
; =============================================================================



MidiSerial_RetStub:
	ret

MidiSerial_ProcessInput:
	bit 4, (0xfd50:16)
	jr nz, MidiSerial_Return
	call SeqMain_SaveWritePos
	ldw (0x90de:16), 0

MidiSerial_PumpLoop:
	ld xix, 0x1f37b
	ld wa, (xix - 10)
	cp wa, (xix - 6)
	jr z, MidiSerial_PumpDone
	and (1064:16), 254
	call MidiSerial_WaitForData
	ld a, (0x9634:16)
	ld (0x9654:16), a
	and a, 0x70
	srl a, 2
	ld xiz, MidiSerial_StatusHandlers
	ld	xiz, (xiz+a)
	call (xiz)
	jr MidiSerial_PumpLoop

MidiSerial_PumpDone:
	call MidiStream_LoadAllPresets
	ld xix, SWBTWR_EVENT_QUEUE
	ld hl, (0x90de:16)
	ld	(xix+hl), 0xff

MidiSerial_Return:
	ret

; MidiSerial_StatusTable -- one 0xFF pad byte, then 8 handler pointers indexed by
; the status byte's high nibble.  Reader MidiSerial_PumpLoop (this file): `ld a,
; (0x9634) / and a, 0x70 / srl a, 2` (= 4 * ((status >> 4) & 7)), `ld xiz,
; MidiSerial_StatusHandlers / ld xiz, (xiz+a) / call (xiz)`, so entry 0 is at +1
; (MidiSerial_StatusHandlers = this label + 1, shared/positional_labels.s) and
; 8 entries reach MidiSerial_WaitForData.  Slots 0-6 (8x note off .. Ex pitch
; bend) -> MidiRx_ChannelMsgDispatch; slot 7 (Fx) -> MidiRx_SystemMsgDispatch,
; which dispatches system messages on the low nibble through
; MidiSerial_CmdJumpTable.  Previously spelled as `swi 7 / cpm_spiw ix, 250 /
; nop` x 7.
MidiSerial_StatusTable:
	.byte 0xff
MidiSerial_StatusHandlers:
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_ChannelMsgDispatch
	.long MidiRx_SystemMsgDispatch

MidiSerial_WaitForData:
	ld xiz, 0x1f37b
	ld xiy, 0x9634
	ld (xiy + 3), 0x0

MidiSerial_WaitLoop:
	call SeqMain_ReadData
	ld (xiy+), l
	ld hl, (xiz - 10)
	cp hl, (xiz - 6)
	jr z, MidiSerial_WaitDone
	ld	a, (xiz+hl)
	bit 7, a
	jr z, MidiSerial_WaitLoop

MidiSerial_WaitDone:
	ret

MidiRx_SystemMsgDispatch:
	ld	l, (0x9634:16)
	and	l, 15
	sla	l, 2
	extz	hl
	ld	xiz, MidiSerial_CmdJumpTable
	ld	xiz, (xiz+hl)
	call (xiz)
	ret
	swi	7


; MidiSerial_CmdJumpTable -- 16 handler pointers for SYSTEM messages F0..FF,
; indexed by the status byte's low nibble.  Reader MidiRx_SystemMsgDispatch
; (MidiSerial_StatusTable slot 7): `ld l, (0x9634) / and l, 15 / sla l, 2 /
; ld xiz, MidiSerial_CmdJumpTable / ld xiz, (xiz+hl) / call (xiz)`.  F2 (song
; position pointer) -> MidiSerial_HandleSongPosition, F3 (song select) ->
; MidiSerial_HandleSongSelect, every other slot -> MidiSerial_HandleDefault_Data
; (`or (0x428:16), 1 / ret`).
MidiSerial_CmdJumpTable:
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleSongPosition
	.long MidiSerial_HandleSongSelect
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
	.long MidiSerial_HandleDefault_Data
MidiSerial_HandleSongPosition:
	ld	wa, (0x9635:16)
	ld	(1069:16), a
	bit	2, (0xfd52:16)
	jr	z, 3
	set	7, w
	ld	(1070:16), w
	ret
MidiSerial_HandleSongSelect:
	ld	a, (0x9635:16)
	bit	3, (0xfd51:16)
	jr	z, 3
	set	7, a
	ld	(1068:16), a
	ret
MidiSerial_HandleDefault_Data:
	or	(0x428:16), 1
	ret
; MidiRx_ChannelMsgDispatch -- entry for channel-voice messages (status 8x..Ex):
; MidiSerial_StatusTable slots 0-6 point here (that table's header gives the
; indexing).  Maps the status byte's channel, (0x9634) & 0x0F, through the
; 16-byte RAM table 0x94F4 to a list in 0x9514 (count, then part numbers), and
; for each part stores it in (0x966A) and calls
; MidiCC_LowRange_Table[((0x9634) & 0x70) >> 4]; (0x966B) counts the parts down.
; It follows MidiSerial_HandleDefault_Data's `ret` and had no label: the old
; sweep read that routine's first byte as `.byte 0xc1` and the rest as
; `pushw wa / max / push xiz / normal`.
MidiRx_ChannelMsgDispatch:
	ld	a, (0x9634:16)
	and	a, 15
	ld	xhl, 0x94f4
	ld	a, (xhl+a)
	cp a, 255
	jr	z, MidiRx_ChannelMsgDispatch_Return
	ld	(0x9668:16), a
	ld	xhl, 0x9514
	ld	a, (xhl+a)
	cp a, 0:i3
	jr z, MidiRx_ChannelMsgDispatch_Return
	ld	(0x9669:16), a
	ld	(0x966b:16), a
	inc	1, (0x9668:16)
	xor	h, h
	ld	l, (0x9668:16)
	ld	xix, 0x9514
	ld	a, (xix+hl)
	ld (38506:16), a
	xor h, h
	ld l, (38452:16)
	and l, 112
	srl	hl, 2
	ld	xix, MidiCC_LowRange_Table
	ld	xix, (xix+hl)
	call (xix)
	dec 1, (38507:16)
	jr nz, -54
MidiRx_ChannelMsgDispatch_Return:
	ret
	swi	7


; MidiCC_LowRange_Table -- 8 handler pointers, one per status-byte high nibble.
; Reader MidiRx_ChannelMsgDispatch: `ld l, (0x9634) / and l, 0x70 / srl hl, 2 /
; ld xix, MidiCC_LowRange_Table / ld xix, (xix+hl) / call (xix)`, slot =
; (status >> 4) & 7, called once per part in the channel's part list.  Slots:
; 8x note off, 9x note on, Ax key pressure -> MidiCC_Handler_SimpleParamStore
; (`or (0x428:16), 1 / ret`); Bx control change -> MidiRx_ControlChange;
; Cx program change -> MidiRx_ProgramChange; Dx channel pressure ->
; MidiRx_ChannelPressure; Ex pitch bend -> MidiRx_PitchBend;
; Fx -> SimpleParamStore (MidiSerial_StatusTable never sends Fx here).
MidiCC_LowRange_Table:
	.long MidiCC_Handler_SimpleParamStore
	.long MidiCC_Handler_SimpleParamStore
	.long MidiCC_Handler_SimpleParamStore
	.long MidiRx_ControlChange
	.long MidiRx_ProgramChange
	.long MidiRx_ChannelPressure
	.long MidiRx_PitchBend
	.long MidiCC_Handler_SimpleParamStore
MidiCC_Handler_SimpleParamStore:
	or	(0x428:16), 1
	ret
MidiRx_ControlChange:
	ld	xix, MidiCC_ChannelMappingData
	ld	l, (0x9635:16)
	ld	a, (xix+l)
	ld (38487:16), a
	cp a, 255
	jr z, 56
	extz	wa
	sll	a, 1
	ld	xix, MidiCC_FunctionRxFilter
	ld	wa, (xix+wa)
	cp wa, 65535
	jr	z, MidiRx_ControlChange_Skip
	ld	xix, 0xfd57
	ld	c, (xix+w)
	and c, a
	jr	z, MidiRx_ControlChange_Return
MidiRx_ControlChange_Skip:
	extz	wa
	ld	a, (0x9657:16)
	sla	wa, 2
	ld	xix, MidiCC_ExtendedRange_Table
	ld	xix, (xix+wa)
	call (xix)
MidiRx_ControlChange_Return:
	ret


; MidiCC_ExtendedRange_Table -- 48 handler pointers, one per CC FUNCTION index
; (the index MidiCC_ChannelMappingData gives a controller number).  Reader
; MidiRx_ControlChange: `ld a, (0x9657) / sla wa, 2 / ld xix,
; MidiCC_ExtendedRange_Table / ld xix, (xix+wa) / call (xix)`.  48 entries = the
; function range of MidiCC_FunctionRxFilter and MidiCC_FunctionToCCNumber (both
; 48); the per-part target table each slot's handler reads is listed in the
; header of MidiCC_ChannelMappingData.
MidiCC_ExtendedRange_Table:
	.long MidiCC_RxCC64_Sustain
	.long MidiCC_RxCC1_Modulation
	.long MidiCC_RxCC7_Volume
	.long MidiCC_RxCC11_Expression
	.long MidiCC_RxCC10_Pan
	.long MidiCC_RxCC93_Chorus
	.long MidiCC_RxCC94_Celeste
	.long MidiCC_RxCC91_Reverb
	.long MidiCC_RxFunc08
	.long MidiCC_RxFunc09
	.long MidiCC_StubHandler_A
	.long MidiCC_StubHandler_B
	.long MidiCC_RxFunc12
	.long MidiCC_RxFunc13
	.long MidiCC_RxFunc14
	.long MidiCC_RxFunc15
	.long MidiCC_Handler_RangeCheck
	.long MidiCC_Handler_ChannelMapping
	.long MidiCC_Handler_BitManipulation
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_PairedParamB
	.long MidiCC_Handler_PairedParamA
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_BankModeSelect
	.long MidiCC_Handler_ExpressionParam
	.long MidiCC_Handler_DirectStoreA
	.long MidiCC_Handler_DirectStoreB
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_Handler_ParamDispatch
	.long MidiCC_Handler_TableDispatch
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
MidiCC_NullHandlerBlock:
	ret
MidiCC_Handler_BitManipulation:
	bit	2, (0xfd51:16)
	jr	z, MidiCC_Handler_BitManipulation_Return
	ld	a, (0x966a:16)
	cp	a, 25
	jr	nz, MidiCC_Handler_BitManipulation_Return
	cp	(0x9657:16), 18
	jr	nz, MidiCC_Handler_BitManipulation_Return
	xor	e, e
	ld	a, (0x9636:16)
	cp	a, 2:i3
	jr	ugt, MidiCC_Handler_BitManipulation_Skip
	ld	xix, MidiCC_CC83_ValueMap
	ld	e, (xix+a)
MidiCC_Handler_BitManipulation_Skip:
	ldw bc, 2968
	ld d, 192:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_Handler_BitManipulation_Helper
MidiCC_Handler_BitManipulation_Return:
	ret
; 0xFF filler after the `ret`; nothing reads it (the table below starts at +1).
	.byte 0xff
; MidiCC_CC83_ValueMap (0xFCFCB9, 3 x u8): controller value 0..2 -> E.  Reader
; MidiCC_Handler_BitManipulation (0xFCFC74), CC function 18 <- CC83
; (MidiCC_ChannelMappingData): only for part 25, with `bit 2, (0xfd51)` set;
; `ld a, (0x9636) / cp a, 2 / jr ugt` (E stays 0 above 2) / `ld e, (xix+a)`,
; then BC = 0x0B98, D = 0xC0 -> MidiCC_Handler_BitManipulation_Helper.
; Previously spelled `.byte 0x80, 0x40` behind a `nop`.
MidiCC_CC83_ValueMap:
	.byte 0x00, 0x80, 0x40
MidiCC_Handler_PairedParamA:
	extz	hl
	ld	l, (0x966a:16)
	cp	l, 31
	jr	ugt, MidiCC_Handler_PairedParamA_Return
	bit	4, (0xfd57:16)
	jr	z, MidiCC_Handler_PairedParamA_Return
	sll	hl, 1
	ld	xix, MidiCC_PartTargets_BankSelect
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_PairedParamA_Return
	ld	e, (0x9636:16)
	ld	d, 255:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_Handler_PairedParamA_Helper
MidiCC_Handler_PairedParamA_Return:
	ret
MidiCC_Handler_PairedParamB:
	extz	hl
	ld	l, (0x966a:16)
	cp	l, 31
	jr	ugt, MidiCC_Handler_PairedParamB_Return
	bit	4, (0xfd57:16)
	jr	z, MidiCC_Handler_PairedParamB_Return
	sll	hl, 1
	ld	xix, MidiCC_PartTargets_BankSelect
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_PairedParamB_Return
	ld	d, (0x9636:16)
	ld	e, 255:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_Handler_PairedParamA_Helper
MidiCC_Handler_PairedParamB_Return:
	ret
MidiCC_Handler_RangeCheck:
	ld	a, (0x966a:16)
	cp	a, 16
	jr	nz, MidiCC_Handler_RangeCheck_Return
	cp	(0x9657:16), 16
	jr	nz, MidiCC_Handler_RangeCheck_Return
	xor	e, e
	ld	a, (0x9636:16)
	cp	a, 3:i3
	jr	ugt, MidiCC_Handler_RangeCheck_Skip
	ld	xix, MidiCC_CC80_ValueMap
	ld	e, (xix+a)
MidiCC_Handler_RangeCheck_Skip:
	ldw bc, 840
	ld	d, 7:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiStream_ApplyPendingParams
MidiCC_Handler_RangeCheck_Return:
	ret
; 0xFF filler after the `ret`; nothing reads it (the table below starts at +1).
	.byte 0xff
; MidiCC_CC80_ValueMap (0xFCFD77, 4 x u8): controller value 0..3 -> E.  Reader
; MidiCC_Handler_RangeCheck (0xFCFD38), CC function 16 <- CC80: only for part 16;
; `ld a, (0x9636) / cp a, 3 / jr ugt` (E stays 0 above 3) / `ld e, (xix+a)`,
; then BC = 0x0348, D = 7 -> MidiStream_ApplyPendingParams.  Previously
; spelled `nop / push sr / normal / pop sr`.
MidiCC_CC80_ValueMap:
	.byte 0x00, 0x02, 0x01, 0x03
MidiCC_Handler_ChannelMapping:
	ld	a, (0x966a:16)
	cp	a, 20
	jr	nz, MidiCC_Handler_ChannelMapping_Return
	cp	(0x9657:16), 17
	jr	nz, MidiCC_Handler_ChannelMapping_Return
	ld	b, 5:opc
	ldw	de, 0xfc00
	ld	a, (0x9636:16)
	cp	a, 11
	jr	ugt, MidiCC_Handler_ChannelMapping_Skip
	extz	wa
	sll	wa, 2
	ld	xix, MidiCC_CC82_Records
	ld	bc, (xix+wa)
	inc 2, wa
	ld	de, (xix+wa)
MidiCC_Handler_ChannelMapping_Skip:
	pushw bc
	pushw	de
	ld	(0x3489:16), b
	ld	(0x347c:16), e
	ld	(0x347d:16), d
	call	AccWrap_ReplaySavedExpr
	popw	de
	popw	bc
	cp	e, 0:i3
	jr	nz, MidiCC_Handler_ChannelMapping_Return
	inc	1, b
	ld	(0x3489:16), b
	ld	(0x347c:16), e
	ld	(0x347d:16), 4
	call	AccWrap_ReplaySavedExpr
MidiCC_Handler_ChannelMapping_Return:
	ret
; MidiCC_CC82_Records (0xFCFDDB, 12 records x 4 bytes, one per line = controller
; value 0..11).  Reader MidiCC_Handler_ChannelMapping (0xFCFD7B), CC function
; 17 <- CC82: only for part 20; `ld a, (0x9636) / cp a, 11 / jr ugt` (above 11
; it keeps B = 5, DE = 0xFC00) / `sll wa, 2 / ld bc, (xix+wa) / inc 2, wa /
; ld de, (xix+wa)`.  Fields as used: +1 B -> (0x3489), +2 E -> (0x347C),
; +3 D -> (0x347D), then `call AccWrap_ReplaySavedExpr`; when E == 0 it calls
; again with B+1 and D = 4.  +0 (C, always 0x48 here) is loaded but not used
; by this reader.  12 entries = the `cp a, 11` bound; the table ends where
; MidiCC_RxCC64_Sustain begins.
MidiCC_CC82_Records:
	.byte 0x48, 0x05, 0x00, 0xfc
	.byte 0x48, 0x05, 0x40, 0x40
	.byte 0x48, 0x05, 0x10, 0x10
	.byte 0x48, 0x05, 0x04, 0x04
	.byte 0x48, 0x05, 0x00, 0xfc
	.byte 0x48, 0x05, 0x80, 0x80
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFCFDF3-0xFCFE0A (23 B), unreached CODE-territory, was disassembled as 19 plausible-but-dead instruction lines; per=68% dist=8 near MidiCC_CC82_Records+24
	.byte 0x48, 0x05, 0x20, 0x20
	.byte 0x48, 0x05, 0x08, 0x08
	.byte 0x48, 0x05, 0x00, 0xfc
	.byte 0x48, 0x05, 0x00, 0xfc
	.byte 0x48, 0x05, 0x00, 0xfc
	.byte 0x48, 0x06, 0x04, 0x04
MidiCC_RxCC64_Sustain:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC64_Sustain_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC64_Sustain
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC64_Sustain_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	calr	MidiCC_Helper_ConditionalESetup
MidiCC_RxCC64_Sustain_Return:
	ret
MidiCC_RxFunc08:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc08_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func08
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc08_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc08_Helper
MidiCC_RxFunc08_Return:
	ret
MidiCC_RxFunc09:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc09_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func09
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc09_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc08_Helper
MidiCC_RxFunc09_Return:
	ret
MidiCC_RxCC1_Modulation:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC1_Modulation_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC1_Modulation
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC1_Modulation_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxCC1_Modulation_Helper
MidiCC_RxCC1_Modulation_Return:
	ret
MidiCC_RxCC7_Volume:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC7_Volume_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC7_Volume
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC7_Volume_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	PerfMode_Evt04_VolumeHandler_Helper2
MidiCC_RxCC7_Volume_Return:
	ret
MidiCC_RxCC11_Expression:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC11_Expression_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC11_Expression
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC7_Volume_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxCC11_Expression_Helper
MidiCC_RxCC11_Expression_Return:
	ret
MidiCC_RxCC10_Pan:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC10_Pan_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC10_Pan
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC7_Volume_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxCC10_Pan_Helper
MidiCC_RxCC10_Pan_Return:
	ret
MidiCC_RxCC93_Chorus:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC93_Chorus_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC93_Chorus
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC93_Chorus_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxCC10_Pan_Helper
MidiCC_RxCC93_Chorus_Return:
	ret
MidiCC_RxCC94_Celeste:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC94_Celeste_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC94_Celeste
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC94_Celeste_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	calr	MidiCC_Helper_ConditionalESetup
MidiCC_RxCC94_Celeste_Return:
	ret
MidiCC_RxCC91_Reverb:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxCC91_Reverb_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_CC91_Reverb
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxCC91_Reverb_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	cp	c, 96
	jr	z, MidiCC_RxCC91_Reverb_Skip
	call	MidiCC_RxCC10_Pan_Helper
	jr	MidiCC_RxCC91_Reverb_Return
MidiCC_RxCC91_Reverb_Skip:
	calr	MidiCC_Helper_ConditionalESetup
MidiCC_RxCC91_Reverb_Return:
	ret
MidiCC_StubHandler_A:
	ret
MidiCC_StubHandler_B:
	ret
MidiCC_RxFunc12:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc12_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func12
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc12_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc12_Helper
MidiCC_RxFunc12_Return:
	ret
MidiCC_RxFunc13:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc13_Return
	xor	w, w
MidiCC_RxFunc13_MidEntry:
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func13
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc13_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc12_Helper
MidiCC_RxFunc13_Return:
	ret
MidiCC_RxFunc14:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc14_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func14
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc14_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc12_Helper
MidiCC_RxFunc14_Return:
	ret
MidiCC_RxFunc15:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_RxFunc15_Return
	xor	w, w
	ld	hl, wa
	sll	wa, 1
	add	hl, wa
	ld	xix, MidiCC_PartTargets_Func15
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_RxFunc15_Return
	inc	2, xix
	ld	d, (xix+hl)
	ld e, (38454:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc12_Helper
MidiCC_RxFunc15_Return:
	ret
MidiCC_Handler_BankModeSelect:
	ld	l, (0x966a:16)
	cp	l, 31
	jrl	ugt, MidiCC_Handler_BankModeSelect_Return
	extz	hl
	ld	xix, MidiCC_PartSelector_DataEntry
	ld	c, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_BankModeSelect_Return
	sll	hl, 1
	ld	xix, 0x9674
	ld	wa, (xix+hl)
	cp wa, 32896
	jr z, MidiCC_Handler_BankModeSelect_Skip
	cp	wa, 0x8081
	jr	z, MidiCC_Handler_BankModeSelect_Skip2
	cp	wa, 0x8082
	jr	z, MidiCC_Handler_BankModeSelect_Skip3
	jr	MidiCC_Handler_BankModeSelect_Return
MidiCC_Handler_BankModeSelect_Skip:
	bit	0, (0xfd57:16)
	jr	z, MidiCC_Handler_BankModeSelect_Return
	ld	b, 11:opc
	ld	e, (0x9636:16)
	cp	e, 12
	jr	ugt, MidiCC_Handler_BankModeSelect_Return
	ld	d, 127:opc
	jr	MidiCC_Handler_BankModeSelect_Join
MidiCC_Handler_BankModeSelect_Skip2:
	bit	1, (0xfd57:16)
	jr	z, MidiCC_Handler_BankModeSelect_Return
	ld	b, 10:opc
	ld	e, (0x9636:16)
	sll	e, 1
	ld	d, 255:opc
	jr	MidiCC_Handler_BankModeSelect_Join
MidiCC_Handler_BankModeSelect_Skip3:
	bit	1, (0xfd57:16)
	jr	z, MidiCC_Handler_BankModeSelect_Return
	ld	b, 9:opc
	ld	e, (0x9636:16)
	cp	e, 76
	jr	ugt, MidiCC_Handler_BankModeSelect_Return
	cp	e, 52
	jr	c, MidiCC_Handler_BankModeSelect_Return
	ld	d, 127:opc
MidiCC_Handler_BankModeSelect_Join:
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_Handler_BankModeSelect_Helper
MidiCC_Handler_BankModeSelect_Return:
	ret
MidiCC_Handler_ExpressionParam:
	ld	l, (0x966a:16)
	cp	l, 31
	jr	ugt, MidiCC_Handler_ExpressionParam_Return
	extz	hl
	ld	xix, MidiCC_PartSelector_DataEntry
	ld	c, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_ExpressionParam_Return
	sll	hl, 1
	ld	xix, 0x9674
	; cp (xix+hl),0x8081 -- the backend cannot spell this form
	cpw	(xix+hl), 0x8081	; the backend cannot spell this form
	jr	nz, MidiCC_Handler_ExpressionParam_Return
	bit	1, (0xfd57:16)
	jr	z, MidiCC_Handler_ExpressionParam_Return
	ld	b, 10:opc
	ld	xix, (0x90f2:16)
	extz	hl
	ld	l, (0x966a:16)
	sll	hl, 2
	ld	xix, (xix+hl)
	ld a, (xix+10)
	res 0, a
	ld	e, (0x9636:16)
	srl	e, 6
	or	e, a
	ld	d, 255:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_Handler_BankModeSelect_Helper
MidiCC_Handler_ExpressionParam_Return:
	ret
MidiCC_Handler_DirectStoreA:
	ld	a, (0x9636:16)
	set	7, a
	extz	hl
	ld	l, (0x966a:16)
	sll	hl, 1
	ld	xix, 0x9675
	ld	(xix+hl), a
	dec 1, xix
	ld	w, (xix+hl)
	cp wa, 65535
	jr	nz, MidiCC_Handler_DirectStoreA_Return
	; ld (xix+hl),0x7f7f -- the backend cannot spell this form
	ldw	(xix+hl), 0x7f7f	; the backend cannot spell this form
MidiCC_Handler_DirectStoreA_Return:
	ret
MidiCC_Handler_DirectStoreB:
	ld	a, (0x9636:16)
	set	7, a
	extz	hl
	ld	l, (0x966a:16)
	sll	hl, 1
	ld	xix, 0x9674
	ld	(xix+hl), a
	inc 1, xix
	ld	w, (xix+hl)
	cp wa, 65535
	jr	nz, MidiCC_Handler_DirectStoreB_Return
	dec	1, xix
	; ld (xix+hl),0x7f7f -- the backend cannot spell this form
	ldw	(xix+hl), 0x7f7f	; the backend cannot spell this form
MidiCC_Handler_DirectStoreB_Return:
	ret
MidiCC_Handler_ParamDispatch:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiCC_Handler_ParamDispatch_Return
	sll	a, 1
	ld	xix, MidiCC_PartTargets_CC121_ResetAll
	ld	bc, (xix+a)
	cp c, 255
	jr	z, MidiCC_Handler_ParamDispatch_Return
	ld	e, (0x9636:16)
	ld	d, 127:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	VoiceMode3_EvType3_Helper
MidiCC_Handler_ParamDispatch_Return:
	ret
MidiCC_Handler_TableDispatch:
	; --- Subroutine 1: table-indexed dispatch via XIX+A (54 bytes) ---
	ld	a, (0x966a:16)
	cp a, 0x1f
	jr ugt, MidiCC_Handler_TableDispatch_Ret
	sll	a, 1
	ld xix, MidiCC_PartTargets_CC120_AllSoundOff
	ld	bc, (xix+a)
	cp c, 0xff
	jr z, MidiCC_Handler_TableDispatch_Ret
	ld	e, (0x9636:16)
	ld d, 0x7f:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call MidiCC_Handler_TableDispatch_Helper
MidiCC_Handler_TableDispatch_Ret:
	ret
MidiCC_Helper_ConditionalESetup:
	; --- Subroutine 2: conditional E setup from D (26 bytes) ---
	ld	a, (0x9636:16)
	ld	de, (0x9646:16)
	xor e, e
	cp a, 0x40
	jr c, MidiCC_Helper_ConditionalESetup_Store
	ld e, d
MidiCC_Helper_ConditionalESetup_Store:
	ld	(0x9646:16), de
	call MidiCC_Helper_ConditionalESetup_Store_Helper
	ret
MidiCC_Helper_EntryWithEqA:
	; --- Subroutine 3: entry variant with E=A (23 bytes) ---
	ld e, a
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call MidiCC_RxCC10_Pan_Helper
	ret


MidiRx_ProgramChange:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiRx_ProgramChange_Return
	bit	4, (0xfd57:16)
	jr	z, MidiRx_ProgramChange_Return
	sll	a, 1
	ld	xix, MidiPC_PartTargets
	ld	bc, (xix+a)
	cp c, 255
	jr	z, MidiRx_ProgramChange_Return
	ld	e, (0x9635:16)
	ld	d, 255:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiRx_ProgramChange_Helper
MidiRx_ProgramChange_Return:
	ret
MidiRx_PitchBend:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiRx_PitchBend_Return
	bit	6, (0xfd57:16)
	jr	z, MidiRx_PitchBend_Return
	sll	a, 1
	ld	xix, MidiPB_PartTargets
	ld	bc, (xix+a)
	cp c, 255
	jr	z, MidiRx_PitchBend_Return
	ld	e, (0x9635:16)
	ld	d, (0x9636:16)
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiRx_PitchBend_Helper
MidiRx_PitchBend_Return:
	ret
MidiRx_ChannelPressure:
	ld	a, (0x966a:16)
	cp	a, 31
	jr	ugt, MidiRx_ChannelPressure_Return
	bit	5, (0xfd57:16)
	jr	z, MidiRx_ChannelPressure_Return
	sll	a, 1
	ld	xix, MidiCP_PartTargets
	ld	bc, (xix+a)
	cp c, 255
	jr	z, MidiRx_ChannelPressure_Return
	ld	e, (0x9635:16)
	ld	d, 127:opc
	ld	a, (0x9637:16)
	ld	(0x9648:16), a
	ld	(0x9644:16), bc
	ld	(0x9646:16), de
	call	MidiCC_RxFunc12_Helper
MidiRx_ChannelPressure_Return:
	ret
; ============================================================================
; UIState_ProcessDisplayUpdate - Process a display update event in UI state
; ============================================================================
; Input:  Display update event data
; Output: None
; Handles display refresh events within the UI state machine, updating
; screen elements that need to be redrawn.
; ============================================================================
UIState_ProcessDisplayUpdate:
	cp	(SWBTWR_PAYLOAD_1:16), 13
	jr	nz, UIState_ProcessDisplayUpdate_Return
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 255
	jr	z, UIState_ProcessDisplayUpdate_Return
	set	0, (0x966c:16)
UIState_ProcessDisplayUpdate_Return:
	ret
UIState_DisplayUpdate_BitmapHandler:
	bit	0, (0x966c:16)
	jr	z, UIState_DisplayUpdate_BitmapHandler_Return
	res	0, (0x966c:16)
	ld	(0x966d:16), 128
	calr	UIState_DisplayUpdate_BitmapHandler_Helper
	ld	(0x966d:16), 64
	calr	UIState_DisplayUpdate_BitmapHandler_Helper
	call	VoiceChannels_InitPanFromPreset
UIState_DisplayUpdate_BitmapHandler_Return:
	ret
UIState_DisplayUpdate_BitmapHandler_Helper:
	ld	xix, 0x94f4
	cp	(0x966d:16), 128
	jr	z, UIState_DisplayUpdate_BitmapHandler_Skip
	ld	xix, 0x9594
UIState_DisplayUpdate_BitmapHandler_Skip:
	ldw	wa, 0xffff
	ldw	bc, 16
	ld	(xix+), wa
	djnz16	bc, -6
	ld	xix, 0x9514
	cp	(0x966d:16), 128
	jr	z, UIState_DisplayUpdate_BitmapHandler_Skip2
	ld	xix, 0x95b4
UIState_DisplayUpdate_BitmapHandler_Skip2:
	xor	wa, wa
	ldw	bc, 64
	ld	(xix+), wa
	djnz16	bc, -6
	ld	xix, 0x94f4
	ld	xiy, 0x9514
	cp	(0x966d:16), 128
	jr	z, UIState_DisplayUpdate_BitmapHandler_Skip3
	ld	xix, 0x9594
	ld	xiy, 0x95b4
UIState_DisplayUpdate_BitmapHandler_Skip3:
	ld	(0x9664:16), xiy
	ld	(0x966e:16), 0
	ld	w, 0:opc
UIState_DisplayUpdate_BitmapHandler_Loop:
	ld	xhl, 1:i3
	ld	(0x966f:16), 0
	ld	(0x9670:16), 0
UIState_DisplayUpdate_BitmapHandler_Loop2:
	ld	xiz, (0x90f2:16)
	xor	d, d
	ld	e, (0x9670:16)
	sll	de, 2
	ld	xiz, (xiz+de)
	cp xiz, 4294967295
	jr	z, UIState_DisplayUpdate_BitmapHandler_Code_Skip
	ld	a, (xiz+13)
	pushw	wa
	and	a, (0x966d:16)
	popw	wa
	jr	nz, UIState_DisplayUpdate_BitmapHandler_Code_Skip
	and	a, 31
	cp	a, w
	jr	nz, UIState_DisplayUpdate_BitmapHandler_Code_Skip
	ld	d, (0x9670:16)
	ld	(xiy+hl), d
	inc 1, xhl
	inc 1, (38511:16)
UIState_DisplayUpdate_BitmapHandler_Code_Skip:
	inc	1, (0x9670:16)
	cp	(0x9670:16), 32
	jr	nz, UIState_DisplayUpdate_BitmapHandler_Loop2
	cp	(0x966f:16), 0
	jr	z, UIState_DisplayUpdate_BitmapHandler_Skip4
	ld	e, (0x966f:16)
	ld	(xiy), e
	ld	xde, xiy
	sub	xde, (0x9664:16)
	ld	(xix), e
	add	xiy, xhl
UIState_DisplayUpdate_BitmapHandler_Skip4:
	inc	1, xix
	inc	1, w
	inc	1, (0x966e:16)
	cp	(0x966e:16), 32
	jr	nz, UIState_DisplayUpdate_BitmapHandler_Loop
	ret
MIDI_DispatchCC:
	bit 0, (0xb7e7:16)
	jr nz, MidiCC_DispatchCleanupRet
	bit 4, (0xfd50:16)
	jr nz, MidiCC_DispatchCleanupRet
	ld (0x964c:16), bc
	ld (0x964e:16), de
	cp c, 0xbf
	jr ugt, MidiCC_DispatchCleanupRet
	ld l, c
	extz hl
	sll hl, 2
	ld xix, MidiDispatchCC_HandlerTable
	ld	xix, (xix+hl)
	call (xix)

MidiCC_DispatchCleanupRet:
	res 7, (0x90e5:16)
	ret

MidiCC_DispatchStubRet:
	ret

PanelEvt_CheckFlag7_Dispatch_A:
	bit 7, (0x90e5:16)
	jr nz, PanelEvt_CheckFlag7_DoDispatch_A
	bit 6, (0xf9c3:16)
	jr nz, PanelEvt_CheckFlag7_Ret_A

PanelEvt_CheckFlag7_DoDispatch_A:
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_A:
	ret

PanelEvt_CheckFlag7_Dispatch_B:
	bit 7, (0x90e5:16)
	jr nz, PanelEvt_CheckFlag7_DoDispatch_B
	bit 6, (0xf9dd:16)
	jr nz, PanelEvt_CheckFlag7_Ret_B

PanelEvt_CheckFlag7_DoDispatch_B:
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_B:
	ret

PanelEvt_CheckFlag7_Dispatch_C:
	bit 7, (0x90e5:16)
	jr nz, PanelEvt_CheckFlag7_DoDispatch_C
	bit 6, (0xf9f7:16)
	jr nz, PanelEvt_CheckFlag7_Ret_C

PanelEvt_CheckFlag7_DoDispatch_C:
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag7_Ret_C:
	ret

PanelEvt_UnconditionalDispatch:
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_CheckFlag6_Dispatch:
	bit 6, (0xfd53:16)
	jr z, PanelEvt_CheckFlag6_Ret
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckFlag6_Ret:
	ret

PanelEvt_CheckChanZero_Dispatch:
	cp (0x964d:16), 0
	jr PanelEvt_CheckChanZero_DoDispatch
	bit 6, (0xfd50:16)
	jr z, PanelEvt_CheckChanZero_Ret

PanelEvt_CheckChanZero_DoDispatch:
	ld xiy, PanelEvt_DispatchTable
	ld a, 0xf:opc
	calr PanelEvent_DispatchByIndex

PanelEvt_CheckChanZero_Ret:
	ret


; PanelEvt_DispatchTable -- 16 handler pointers, second-level index = (0x964D).
; Reader PanelEvent_DispatchByIndex (0xFD0A0D): `ld l, (0x964d) / cp l, a /
; jr ugt <ret> / sll hl, 2 / ld xhl, (xiy+hl) / call (xhl)`; the loaders
; PanelEvt_CheckFlag7_Dispatch_A/B/C and friends pass xiy = this table and
; a = 0x0F, which pins 16 entries.  (0x964C)/(0x964D) and (0x964E)/(0x964F) are
; the BC and DE that MIDI_DispatchCC stores before its own 192-entry dispatch.
PanelEvt_DispatchTable:
	.long PanelEvt_Handler_0_NoteOnParam
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_Handler_3_ValueCheck
	.long PanelEvt_Handler_4_DualValueCheck
	.long PanelEvt_Handler_5_ValueCheck
	.long PanelEvt_Handler_6_NullStub
	.long PanelEvt_Handler_7_ValueCheck
	.long PanelEvt_Handler_8_ValueCheck
	.long PanelEvt_Handler_9_SingleByteParam
	.long PanelEvt_Handler_10_TwoByteParam
	.long PanelEvt_Handler_11_SingleByteParam
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_Handler_15_ConditionalSet
PanelEvt_Handler_0_NoteOnParam:
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_0_NoteOnParam_Return
	ld	xix, PanelEvt_Handler_0_NoteOnParam_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_0_NoteOnParam_Return
	bit	4, (0xfd57:16)
	jr	z, PanelEvt_Handler_0_NoteOnParam_Return
	ld	a, (0x90e5:16)
	bit	7, (0x90e5:16)
	jr	nz, PanelEvt_Handler_0_NoteOnParam_Skip
	ld	a, (xix)
	bit	6, a
	jr	nz, PanelEvt_Handler_0_NoteOnParam_Return
PanelEvt_Handler_0_NoteOnParam_Skip:
	ldw	de, 512
	ld	(0x963f:16), de
	and	a, 15
	or	a, 192
	ld	w, (0x964e:16)
	ld	(0x963c:16), wa
	calr	FileData_ValidateAndDispatch
PanelEvt_Handler_0_NoteOnParam_Return:
	ret
PanelEvt_Handler_3_ValueCheck:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_3_ValueCheck_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_3_ValueCheck_Return
	ld	xix, PanelEvt_Handler_3_ValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_3_ValueCheck_Return
	bit	2, (0xfd58:16)
	jr	z, PanelEvt_Handler_3_ValueCheck_Return
	ld	e, (0x964e:16)
	ld	w, 2:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_3_ValueCheck_Return:
	ret
PanelEvt_Handler_5_ValueCheck:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_5_ValueCheck_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_5_ValueCheck_Return
	ld	xix, PanelEvt_Handler_5_ValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_5_ValueCheck_Return
	bit	5, (0xfd58:16)
	jr	z, PanelEvt_Handler_5_ValueCheck_Return
	ld	e, (0x964e:16)
	ld	w, 5:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_5_ValueCheck_Return:
	ret
PanelEvt_Handler_6_NullStub:
	ret
PanelEvt_Handler_7_ValueCheck:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_7_ValueCheck_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_7_ValueCheck_Return
	ld	xix, PanelEvt_Handler_7_ValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_7_ValueCheck_Return
	bit	5, (0xfd58:16)
	jr	z, PanelEvt_Handler_7_ValueCheck_Return
	ld	e, (0x964e:16)
	ld	w, 7:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_7_ValueCheck_Return:
	ret
PanelEvt_Handler_8_ValueCheck:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_8_ValueCheck_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_8_ValueCheck_Return
	ld	xix, PanelEvt_Handler_8_ValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_8_ValueCheck_Return
	bit	4, (0xfd58:16)
	jr	z, PanelEvt_Handler_8_ValueCheck_Return
	ld	e, (0x964e:16)
	ld	w, 4:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_8_ValueCheck_Return:
	ret
PanelEvt_Handler_9_SingleByteParam:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_9_SingleByteParam_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_9_SingleByteParam_Return
	ld	xix, PanelEvt_Handler_9_SingleByteParam_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_9_SingleByteParam_Return
	bit	1, (0xfd57:16)
	jr	z, PanelEvt_Handler_9_SingleByteParam_Return
	ld	bc, 2:i3
	ld	d, (0x964e:16)
	xor	e, e
	calr	FileData_ProcessWithLookup
PanelEvt_Handler_9_SingleByteParam_Return:
	ret
PanelEvt_Handler_10_TwoByteParam:
	ld	a, (0x964f:16)
	and	a, 255
	jr	z, PanelEvt_Handler_10_TwoByteParam_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_10_TwoByteParam_Return
	ld	xix, PanelEvt_Handler_10_TwoByteParam_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_10_TwoByteParam_Return
	bit	1, (0xfd57:16)
	jr	z, PanelEvt_Handler_10_TwoByteParam_Return
	ld	bc, 1:i3
	ld	d, (0x964e:16)
	xor	e, e
	srl	de, 1
	srl	e, 1
	calr	FileData_ProcessWithLookup
PanelEvt_Handler_10_TwoByteParam_Return:
	ret
PanelEvt_Handler_11_SingleByteParam:
	ld	a, (0x964f:16)
	and	a, 127
	jr	z, PanelEvt_Handler_11_SingleByteParam_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_11_SingleByteParam_Return
	ld	xix, PanelEvt_Handler_11_SingleByteParam_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_11_SingleByteParam_Return
	bit	0, (0xfd57:16)
	jr	z, PanelEvt_Handler_11_SingleByteParam_Return
	ld	bc, 0:i3
	ld	d, (0x964e:16)
	xor	e, e
	calr	FileData_ProcessWithLookup
PanelEvt_Handler_11_SingleByteParam_Return:
	ret
PanelEvt_Handler_15_ConditionalSet:
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_15_ConditionalSet_Return
	ld	xix, PanelEvt_Handler_0_NoteOnParam_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp xix, 4294967295
	jr	z, PanelEvt_Handler_15_ConditionalSet_Return
	extz	de
	ld	e, (0x964e:16)
	bit	7, e
	jr	z, PanelEvt_Handler_15_ConditionalSet_Skip
	set	0, d
	res	7, e
PanelEvt_Handler_15_ConditionalSet_Skip:
	call	MidiCC_ChannelDispatch_DualSend
PanelEvt_Handler_15_ConditionalSet_Return:
	ret

PanelEvt_Dispatch6Entry:
	ld xiy, PanelEvt_Dispatch6_Handlers
	ld a, 0x6:opc
	calr PanelEvent_DispatchByIndex
	ret

; PanelEvt_Dispatch6_TableAndHandlers -- one 0xFF pad byte, then 7 handler
; pointers (PanelEvt_Dispatch6_Handlers = this label + 1): PanelEvt_Dispatch6Entry
; loads `ld xiy, PanelEvt_Dispatch6_Handlers / ld a, 6 / calr
; PanelEvent_DispatchByIndex`, so index (0x964D) 0..6.  The two slots that are
; not MidiCC_NullHandlerBlock / PanelEvt_Handler_0_NoteOnParam follow the table,
; each with the value map it reads.  Previously spelled as `swi 7 / popw bc /
; ei 253 / jrl ule, -772 ...` with the handlers misframed behind it.
PanelEvt_Dispatch6_TableAndHandlers:
	.byte 0xff
PanelEvt_Dispatch6_Handlers:
	.long PanelEvt_Handler_0_NoteOnParam
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_D6Slot3_SendCC80
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_D6Slot5_SendCC82
	.long PanelEvt_D6Slot5_SendCC82
; PanelEvt_D6Slot3_SendCC80 -- slot 3 of PanelEvt_Dispatch6_Handlers.  If
; (0x964F) & 7 is non-zero and bit 5 of (0xFD59) is set, E = PanelEvt_D6Slot3_ValueMap
; [(0x964E) & 7] and it calls MidiChannel_ConfigureController (0xFD0D13) with
; W = 0x10: CC function 16, which MidiCC_FunctionToCCNumber sends as CC80.
PanelEvt_D6Slot3_SendCC80:
	ld	a, (0x964f:16)
	and	a, 7
	jr	z, PanelEvt_D6Slot3_SendCC80_Return
	ld	xix, 0xfb63
	bit	5, (0xfd59:16)
	jr	z, PanelEvt_D6Slot3_SendCC80_Return
	ld	e, (0x964e:16)
	and	e, 7
	ld	xiy, PanelEvt_D6Slot3_ValueMap
	ld	e, (xiy+e)
	ld	w, 16:opc
	calr	MidiChannel_ConfigureController
PanelEvt_D6Slot3_SendCC80_Return:
	ret
	.byte 0xff
; PanelEvt_D6Slot3_ValueMap (8 x u8): (0x964E) & 7 -> the CC80 value; read by
; PanelEvt_D6Slot3_SendCC80 with `and e, 7 / ld e, (xiy+e)`, which pins 8 entries.
PanelEvt_D6Slot3_ValueMap:
	.byte 0x00, 0x02, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00
; PanelEvt_D6Slot5_SendCC82 -- slot 5 (and 6) of PanelEvt_Dispatch6_Handlers.
; Gated by bit 6 of (0xFD59); from the bits of (0x964E) that changed it may send
; an all-off first (E = 0), then E = <map>[1-based index of the lowest set bit],
; the map being PanelEvt_D6Slot5_BitMapA when (0x964D) == 5 and ..._BitMapB
; otherwise; both through MidiChannel_ConfigureController with W = 0x11: CC
; function 17, sent as CC82.
PanelEvt_D6Slot5_SendCC82:
	bit	6, (0xfd59:16)
	jr	z, PanelEvt_D6Slot5_SendCC82_Return
	ld	h, e
	cpl	h
	and	h, d
	and	e, d
	ld	l, 252:opc
	cp	(0x964d:16), 5
	jr	z, PanelEvt_D6Slot5_SendCC82_Skip
	ld	l, 4:opc
PanelEvt_D6Slot5_SendCC82_Skip:
	and	h, l
	jr	z, PanelEvt_D6Slot5_SendCC82_Skip2
	ld	xix, 0xfbcb
	ld	w, 17:opc
	xor	e, e
	pushw	hl
	pushw	de
	calr	MidiChannel_ConfigureController
	popw	de
	popw	hl
PanelEvt_D6Slot5_SendCC82_Skip2:
	and	e, l
	jr	z, PanelEvt_D6Slot5_SendCC82_Return
	ld	xix, 0xfbcb
	ld	w, 17:opc
	ld	xiy, PanelEvt_D6Slot5_BitMapA
	cp	(0x964d:16), 5
	jr	z, PanelEvt_D6Slot5_SendCC82_Skip3
	ld	xiy, PanelEvt_D6Slot5_BitMapB
PanelEvt_D6Slot5_SendCC82_Skip3:
	xor	a, a
PanelEvt_D6Slot5_SendCC82_Loop:
	inc	1, a
	srl	e, 1
	jr	nc, PanelEvt_D6Slot5_SendCC82_Loop
	ld	e, (xiy+a)
	calr	MidiChannel_ConfigureController
PanelEvt_D6Slot5_SendCC82_Return:
	ret
; PanelEvt_D6Slot5_BitMapA / _BitMapB (9 x u8 each): bit position 1..8 -> the
; CC82 value (entry 0 unused: the `inc 1, a / srl e, 1 / jr nc` loop starts
; at 1).  Read by PanelEvt_D6Slot5_SendCC82 via `ld e, (xiy+a)`.
PanelEvt_D6Slot5_BitMapA:
	.byte 0x00, 0x00, 0x00, 0x03, 0x07, 0x02, 0x06, 0x01, 0x05
PanelEvt_D6Slot5_BitMapB:
	.byte 0x00, 0x00, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x00

PanelEvt_Dispatch3Entry_A:
	ld xiy, PanelEvt_Dispatch3_TableAndHandlers_A
	ld a, 0x3:opc
	calr PanelEvent_DispatchByIndex
	ret

; PanelEvt_Dispatch3_TableAndHandlers_A -- 4 handler pointers (no pad):
; PanelEvt_Dispatch3Entry_A loads `ld xiy, <this> / ld a, 3 / calr
; PanelEvent_DispatchByIndex`, so index (0x964D) 0..3.  Slot 1 follows.
PanelEvt_Dispatch3_TableAndHandlers_A:
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_D3ASlot1_SendCC91
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
; PanelEvt_D3ASlot1_SendCC91 -- slot 1 of PanelEvt_Dispatch3_TableAndHandlers_A.
; If bit 7 of (0x964F) is set, takes part 25's entry of the per-part pointer
; table at PanelEvt_Handler_7_ValueCheck_Data (0xFFFFFFFF = none), and
; with bit 5 of (0xFD58) set sends E = 0x7F or 0 (bit 7 of (0x964E)) through
; MidiChannel_ConfigureController with W = 7: CC function 7, sent as CC91.
PanelEvt_D3ASlot1_SendCC91:
	bit	7, (0x964f:16)
	jr	z, PanelEvt_Dispatch3Entry_A_Return
	ld	l, 25:opc
	ld	xix, PanelEvt_Handler_7_ValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, PanelEvt_Dispatch3Entry_A_Return
	bit	5, (0xfd58:16)
	jr	z, PanelEvt_Dispatch3Entry_A_Return
	ld	e, 0:opc
	bit	7, (0x964e:16)
	jr	z, PanelEvt_Dispatch3Entry_A_Skip
	ld	e, 127:opc
PanelEvt_Dispatch3Entry_A_Skip:
	ld	w, 7:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Dispatch3Entry_A_Return:
	ret

PanelEvt_Dispatch3Entry_B:
	ld xiy, PanelEvt_Dispatch3_Table_B
	ld a, 0x3:opc
	calr PanelEvent_DispatchByIndex
	ret

; PanelEvt_Dispatch3_Table_B -- 4 handler pointers, all MidiCC_NullHandlerBlock:
; PanelEvt_Dispatch3Entry_B loads `ld xiy, <this> / ld a, 3 / calr
; PanelEvent_DispatchByIndex`.  Previously spelled `jrl ule, -772 / nop` x 4.
PanelEvt_Dispatch3_Table_B:
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock

PanelEvt_Dispatch11Entry:
	ld xiy, PanelEvt_Dispatch11_Handlers
	ld a, 0xb:opc
	calr PanelEvent_DispatchByIndex
	ret

PanelEvt_Dispatch11_TableAndHandlers:
	; PanelEvt_Dispatch11_TableAndHandlers -- one 0xFF pad byte, then 12 handler
	; pointers. The pad is not a guess: PanelEvt_Dispatch11_Handlers
	; is defined as this label + 1 in shared/positional_labels.s and is what
	; PanelEvt_Dispatch11Entry loads (`ld xiy, ..._0x1 / ldb a, 0xb / calr
	; PanelEvent_DispatchByIndex`), so entry 0 is at +1, not at +0.
	; 12 entries reach 0xFD09DB, which is also the value of the last entry --
	; the table is followed immediately by the code it points at.
	; one pad byte; entry 0 of the table is at +1
	.byte 0xff
PanelEvt_Dispatch11_Handlers:
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long MidiCC_NullHandlerBlock
	.long PanelEvt_D11Slot11_SendCC83
; PanelEvt_D11Slot11_SendCC83 -- slot 11 of PanelEvt_Dispatch11_Handlers.  If
; (0x964F) & 0xC0 is non-zero and bit 2 of (0xFD51) is set, E =
; PanelEvt_D11Slot11_ValueMap[((0x964E) & 0xC0) >> 6] through
; MidiChannel_ConfigureController with W = 0x12: CC function 18, sent as CC83.
PanelEvt_D11Slot11_SendCC83:
	ld	a, (0x964f:16)
	and	a, 192
	jr	z, PanelEvt_D11Slot11_SendCC83_Return
	ld	xix, 0xfc19
	bit	2, (0xfd51:16)
	jr	z, PanelEvt_D11Slot11_SendCC83_Return
	ld	e, (0x964e:16)
	and	e, 192
	srl	e, 6
	ld	xiy, PanelEvt_D11Slot11_ValueMap
	ld	e, (xiy+e)
	ld	w, 18:opc
	calr	MidiChannel_ConfigureController
PanelEvt_D11Slot11_SendCC83_Return:
	ret
; PanelEvt_D11Slot11_ValueMap (4 x u8): bits 7-6 of (0x964E) -> the CC83 value;
; `and e, 0xc0 / srl e, 6 / ld e, (xiy+e)` pins 4 entries.
PanelEvt_D11Slot11_ValueMap:
	.byte 0x00, 0x02, 0x01, 0x00

PanelEvent_DispatchByIndex:
	ld l, (0x964d:16)
	cp l, a
	jr ugt, PanelEvt_DispatchByIndex_Ret
	extz hl
	sll hl, 2
	ld	xhl, (xiy+hl)
	call (xhl)

PanelEvt_DispatchByIndex_Ret:
	ret

MidiCC_ChannelDispatch_TableA:
	ld xix, PanelEvt_Handler_0_NoteOnParam_Data
	ld l, (0x964d:16)
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, MidiCC_ChannelDispatch_TableA_Ret
	ld de, (0x964e:16)
	call MidiCC_ChannelDispatch_DualSend

MidiCC_ChannelDispatch_TableA_Ret:
	ret

MidiCC_ChannelDispatch_Ctrl40:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, BitMask_Ctrl40_ConfigExit
	ld xix, MidiCC_ChannelDispatch_Ctrl40_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl40_ConfigExit
	bit 0, (0xfd59:16)
	jr z, BitMask_Ctrl40_ConfigExit
	xor e, e
	ld w, 0x28:opc
	calr MidiChannel_ConfigureController

BitMask_Ctrl40_ConfigExit:
	ret

MidiCC_ChannelDispatch_Ctrl41:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, MidiCC_ChannelDispatch_Ctrl41_Ret
	ld xix, MidiCC_ChannelDispatch_Ctrl41_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, MidiCC_ChannelDispatch_Ctrl41_Ret
	xor e, e
	ld w, 0x29:opc
	calr MidiChannel_ConfigureController

MidiCC_ChannelDispatch_Ctrl41_Ret:
	ret

MidiCC_ChannelDispatch_SpecialCh1:
	ld l, (0x964d:16)
	cp l, 1:i3
	jr nz, MidiCC_ChannelDispatch_SpecialCh1_Ret
	ld xix, 0xfc19
	bit 3, (0xfd58:16)
	jr z, MidiCC_ChannelDispatch_SpecialCh1_Ret
	ld e, (0x964e:16)
	ld w, 0x3:opc
	calr MidiChannel_ConfigureController

MidiCC_ChannelDispatch_SpecialCh1_Ret:
	ret

MidiCC_ChannelDispatch_CtrlFlags:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, PanelEvent_NullRet
	ld xix, MidiCC_ChannelDispatch_CtrlFlags_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, PanelEvent_NullRet
	bit 6, (0xfd57:16)
	jr z, PanelEvent_NullRet
	ld a, (0x90e5:16)
	bit 7, (0x90e5:16)
	jr nz, MidiCC_ChannelDispatch_BuildPacket
	ld a, (xix)
	bit 6, a
	jr nz, PanelEvent_NullRet

MidiCC_ChannelDispatch_BuildPacket:
	ldw de, 0x300
	ld (0x963f:16), de
	and a, 0xf
	or a, 0xe0
	ld w, (0x964e:16)
	ld (0x963c:16), wa
	ld a, (0x964f:16)
	ld (0x963e:16), a
	calr FileData_ValidateAndDispatch

PanelEvent_NullRet:
	ret

MidiCC_ChannelDispatch_Ctrl1:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, BitMask_Ctrl1_ConfigExit
	ld xix, MidiCC_ChannelDispatch_Ctrl1_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl1_ConfigExit
	bit 1, (0xfd58:16)
	jr z, BitMask_Ctrl1_ConfigExit
	ld e, (0x964e:16)
	ld w, 0x1:opc
	calr MidiChannel_ConfigureController

BitMask_Ctrl1_ConfigExit:
	ret

MidiCC_ChannelDispatch_Ctrl3:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, BitMask_Ctrl3_ConfigExit
	ld xix, MidiCC_ChannelDispatch_Ctrl3_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl3_ConfigExit
	bit 3, (0xfd58:16)
	jr z, BitMask_Ctrl3_ConfigExit
	ld e, (0x964e:16)
	ld w, 0x3:opc
	calr MidiChannel_ConfigureController

BitMask_Ctrl3_ConfigExit:
	ret

MidiCC_ChannelDispatch_CtrlFlags2:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, PanelEvent_NullRet2
	ld xix, MidiCC_ChannelDispatch_CtrlFlags2_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, PanelEvent_NullRet2
	bit 5, (0xfd57:16)
	jr z, PanelEvent_NullRet2
	ld a, (0x90e5:16)
	bit 7, (0x90e5:16)
	jr nz, MidiCC_ChannelDispatch_BuildPacket2
	ld a, (xix)
	bit 6, a
	jr nz, PanelEvent_NullRet2

MidiCC_ChannelDispatch_BuildPacket2:
	ldw de, 0x200
	ld (0x963f:16), de
	and a, 0xf
	or a, 0xd0
	ld w, (0x964e:16)
	ld (0x963c:16), wa
	calr FileData_ValidateAndDispatch

PanelEvent_NullRet2:
	ret

MidiCC_ChannelDispatch_Ctrl0:
	ld l, (0x964d:16)
	cp l, 0x1f
	jr ugt, BitMask_Ctrl0_ConfigExit
	ld xix, MidiCC_ChannelDispatch_Ctrl0_Data
	extz hl
	sll l, 2
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jr z, BitMask_Ctrl0_ConfigExit
	bit 0, (0xfd58:16)
	jr z, BitMask_Ctrl0_ConfigExit
	ld e, (0x964e:16)
	ld w, 0x0:opc
	calr MidiChannel_ConfigureController

BitMask_Ctrl0_ConfigExit:
	ret

; MidiCC_ChannelDispatch_Func09 / _Func08 / _Func12 / _Func13 / _Func14 / _Func15
; (0xFD0BF1 + 0x30*k): six more routines of the exact shape of
; MidiCC_ChannelDispatch_Ctrl1/_Ctrl3/_Ctrl0 just above (same 7-byte prologue
; `ld l, (0x964d) / cp l, 31`, each loading the next 0x80-stride record of the
; per-part pointer tables, 0xFD228F..0xFD250F, then `ld w, N / calr
; MidiChannel_ConfigureController`), for CC functions 9, 8, 12, 13, 14, 15.
; NO REFERENCE FOUND: searched their 32-bit and 24-bit addresses anywhere in the
; 2 MB dump and every `calr` byte pattern within +-32 KB -- none; the four
; siblings are in MidiDispatchCC_HandlerTable, these are not.  Those six
; functions are also exactly the ones with no controller number in
; MidiCC_FunctionToCCNumber (0xFF), where MidiChannel_ConfigureController gives
; up -- consistent with handlers left in for unassigned functions.  Decoded as
; code on that shape evidence (clean decode from each start, calr to a known
; routine, the same bytes misframed one byte later as `pop xbc / swi 5`).
MidiCC_ChannelDispatch_Func09:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return
	ld	xix, MidiCC_ChannelDispatch_Func09_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return
	bit	1, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return
	ld	e, (0x964e:16)
	ld	w, 9:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return:
	ret
MidiCC_ChannelDispatch_Func08:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return2
	ld	xix, MidiCC_ChannelDispatch_Func08_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return2
	bit	2, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return2
	ld	e, (0x964e:16)
	ld	w, 8:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return2:
	ret
MidiCC_ChannelDispatch_Func12:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return3
	ld	xix, MidiCC_ChannelDispatch_Func12_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return3
	bit	3, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return3
	ld	e, (0x964e:16)
	ld	w, 12:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return3:
	ret
MidiCC_ChannelDispatch_Func13:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return4
	ld	xix, MidiCC_ChannelDispatch_Func13_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return4
	bit	3, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return4
	ld	e, (0x964e:16)
	ld	w, 13:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return4:
	ret
MidiCC_ChannelDispatch_Func14:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return5
	ld	xix, MidiCC_ChannelDispatch_Func14_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return5
	bit	4, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return5
	ld	e, (0x964e:16)
	ld	w, 14:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return5:
	ret
MidiCC_ChannelDispatch_Func15:
	ld	l, (0x964d:16)
	cp	l, 31
	jr	ugt, MidiCC_ChannelDispatch_Ctrl0_Return6
	ld	xix, MidiCC_ChannelDispatch_Func15_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return6
	bit	4, (0xfd59:16)
	jr	z, MidiCC_ChannelDispatch_Ctrl0_Return6
	ld	e, (0x964e:16)
	ld	w, 15:opc
	calr	MidiChannel_ConfigureController
MidiCC_ChannelDispatch_Ctrl0_Return6:
	ret
	ret
	ret

MidiChannel_ConfigureController:
	pushw bc
	ld a, (0x90e5:16)
	bit 7, (0x90e5:16)
	jr nz, MidiChanCfg_SetupParams
	ld a, (xix)
	bit 6, a
	jr nz, MidiChannel_ConfigureExit

MidiChanCfg_SetupParams:
	ld xiy, 0x963c
	ldw bc, 0x300
	ld (xiy + 3), bc
	and a, 0xf
	or a, 0xb0
	cp w, 0x2f
	jr ugt, MidiChannel_ConfigureExit
	ld xiz, MidiCC_FunctionToCCNumber
	ld	w, (xiz+w)
	cp w, 0xff
	jr z, MidiChannel_ConfigureExit
	ld (xiy + 0:8), wa
	ld (xiy + 2), e
	calr FileData_ValidateAndDispatch

MidiChannel_ConfigureExit:
	popw bc
	ret

FileData_ProcessWithLookup:
	ld	a, (0x90e5:16)
	bit	7, (0x90e5:16)
	jr	nz, FileData_ProcessWithLookup_Skip
	ld	a, (xix)
	bit	6, a
	jr	nz, FileData_ProcessWithLookup_Return
FileData_ProcessWithLookup_Skip:
	ld	xiy, 0x963c
	pushw	bc
	ldw	bc, 768
	ld	(xiy+3), bc
	popw	bc
	and	a, 15
	or	a, 176
	ld	w, 100:opc
	ld (xiy+0:8), wa
	ld	(xiy+2), c
	calr	FileData_ValidateAndDispatch
	ld	a, 101:opc
	ld	w, b
	ld	(xiy+1), wa
	calr	FileData_ValidateAndDispatch
	ld	a, 6:opc
	ld	w, d
	ld	(xiy+1), wa
	calr	FileData_ValidateAndDispatch
	ld	a, 38:opc
	ld	w, e
	ld	(xiy+1), wa
	calr	FileData_ValidateAndDispatch
FileData_ProcessWithLookup_Return:
	ret

MidiCC_ChannelDispatch_DualSend:
	bit 4, (0xfd57:16)
	jr z, FileData_DispatchExit
	bit 7, (0xfd58:16)
	jr z, FileData_DispatchExit
	ld a, (0x90e5:16)
	bit 7, (0x90e5:16)
	jr nz, MidiCC_DualSend_SetupParams
	ld a, (xix)
	bit 6, a
	jr nz, FileData_DispatchExit

MidiCC_DualSend_SetupParams:
	ld xiy, 0x963c
	ldw bc, 0x300
	ld (xiy + 3), bc
	and a, 0xf
	or a, 0xb0
	ld w, 0x0:opc
	ld (xiy + 0:8), wa
	res 7, d
	ld (xiy + 2), d
	calr FileData_ValidateAndDispatch
	ld w, 0x20:opc
	ld (xiy + 1), w
	res 7, e
	ld (xiy + 2), e
	calr FileData_ValidateAndDispatch

FileData_DispatchExit:
	ret

FileData_ValidateAndDispatch:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xix, 0x963c
	ld c, (xix + 4)
	ld w, (xix + 0:8)
	ld xiy, SeqOut_WriteTimedBytes
	ld xiz, 0x424
	pushw wa
	ld a, w
	extz wa
	calr FileData_ValidateFormat
	popw wa
	cp hl, 0xffff
	jr z, FileData_DispatchHandler
	inc 1, xix
	dec 1, c

; File data dispatch handler
FileData_DispatchHandler:
	push xix
	ld wa, bc
	extz wa
	pushw wa
	ei 6
	call (xiy)
	ei 0
	inc 6, xsp
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

Periodic_TimestampHelper_Data:
	ld	(0x424:16), a
	extz	wa
	pushw	wa
	ei	6
	call	SeqBuf_MidiOut_WriteByte
	ei	0
	inc	2, xsp
	ret

Periodic_TimestampCheck:
	calr Periodic_TimestampCompare
	ret

Periodic_TimestampCompare:
	pushw wa
	pushw de
	ld wa, (SYSTEM_TIMESTAMP:16)
	ld de, wa
	sub wa, (0xb7e3:16)
	cp wa, 0x96
	jr c, Periodic_TimestampCompare_Done
	ld (0xb7e3:16), de
	ld (1060:16), 0

Periodic_TimestampCompare_Done:
	popw de
	popw wa
	ret

; =====================================================================
; MIDI receive mapping tables (0xFD0E67-0xFD16E6, 2,176 B, 24 sub-tables).
; Previously spelled as ~850 instruction lines (push_f / normal / swi 7 /
; jrl nc, 1793 ...) that nothing executes: scripts/analysis/midi_lane_reach.py
; reaches none of it.  Every sub-table except the two marked Unread has one
; or two readers, each found both as a symbolic `ld xix, <table>` in this
; file and as the table's 24-bit address in the ROM image (searched: the
; 3-byte LE address anywhere in the 2 MB dump; the only hits are those
; `ld xix` operands).
;
; How a received message gets here (all in this file):
;   MidiRx_ChannelMsgDispatch (0xFCFAD5) takes the running status byte
;   from (0x9634), maps channel = status & 0x0F through the 16-byte RAM table
;   0x94F4 and the part list 0x9514, stores each target PART number (0..31)
;   in (0x966A) and calls MidiCC_LowRange_Table[(status & 0x70) >> 4]:
;   8x/9x/Ax/Fx -> MidiCC_Handler_SimpleParamStore, Bx -> ..._CC3_TableLookup,
;   Cx -> ..._CC4_VoiceParam, Dx -> ..._CC5_VoiceParam, Ex -> ..._CC6_VoiceParam.
;   The two data bytes are at (0x9635) and (0x9636).
; Every per-part table below is indexed by that part number, range-checked by
; its reader with `cp <part>, 31 / jr ugt` -- which is what pins 32 entries.
; The readers pass the entry to the dispatcher named per table below through
; (0x9644) = BC, (0x9646) = DE (E = the message's data byte), (0x9648) = (0x9637);
; the selector encoding is that dispatcher's business and was not traced here.
; =====================================================================
;
; MidiCC_ChannelMappingData (+0x000, 128 x u8): CONTROLLER NUMBER -> CC FUNCTION
; INDEX (0..47), 0xFF = controller ignored.  Reader MidiRx_ControlChange
; (0xFCFB63): `ld xix, MidiCC_ChannelMappingData / ld l, (0x9635) /
; ld a, (xix+l)`, result kept in (0x9657) and used as the index into the
; 48-entry MidiCC_ExtendedRange_Table.  Mapped here: CC0->24 CC1->1 CC6->32
; CC7->2 CC10->4 CC11->3 CC32->25 CC38->33 CC64->0 CC80->16 CC82->17
; CC83->18 CC91->7 CC93->5 CC94->6 CC100->35 CC101->34 CC120->41 CC121->40.
; No controller maps to functions 8-15 in this table.
MidiCC_ChannelMappingData:
	.byte 0x18, 0x01, 0xff, 0xff, 0xff, 0xff, 0x20, 0x02, 0xff, 0xff, 0x04, 0x03, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0x19, 0xff, 0xff, 0xff, 0xff, 0xff, 0x21, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0x10, 0xff, 0x11, 0x12, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x07, 0xff, 0x05, 0x06, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x23, 0x22, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x29, 0x28, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
;
; MidiCC_FunctionRxFilter (+0x080, 48 x {u8 bit mask, u8 byte offset}), one per
; CC function index (48 = the size of MidiCC_ExtendedRange_Table).  Reader
; MidiRx_ControlChange: `sll a, 1 / ld wa, (<this>+2*func)`; 0xFFFF
; = always dispatched, else `ld c, (0xfd57 + W) / and c, A / jr z` skips the
; function when that bit of the RAM byte array at 0xFD57 is clear (bytes
; 0xFD58/0xFD59 are used here; the handlers themselves test 0xFD57 bits
; with `bit n, (0xfd57:16)`).  Entry order = function index 0..47.
MidiCC_FunctionRxFilter:
	.byte 0x01, 0x01
	.byte 0x02, 0x01
	.byte 0x04, 0x01
	.byte 0x08, 0x01
	.byte 0x10, 0x01
	.byte 0x20, 0x01
	.byte 0x20, 0x01
	.byte 0x20, 0x01
	.byte 0x04, 0x02
	.byte 0x02, 0x02
	.byte 0x40, 0x01
	.byte 0x80, 0x02
	.byte 0x08, 0x02
	.byte 0x08, 0x02
	.byte 0x10, 0x02
	.byte 0x10, 0x02
	.byte 0x20, 0x02
	.byte 0x40, 0x02
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0x80, 0x01
	.byte 0x80, 0x01
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0x01, 0x02
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
	.byte 0xff, 0xff
;
; Per-part target records, 32 records x 3 bytes (4 per line, record n = part n):
;   +0 u16 selector -> BC -> (0x9644); low byte 0xFF = part not affected, skip
;   +2 u8           -> D  -> (0x9647); E = the controller value (0x9636)
; Sixteen such tables follow (fourteen with a reader, two marked Unread); the
; reader of each is the handler at its CC function's slot of
; MidiCC_ExtendedRange_Table, all of the
; shape `ld a, (0x966a) / cp a, 31 / jr ugt / hl = 3*a / ld xix, <table> /
; ld bc, (xix+hl) / cp c, 255 / jr z / inc 2, xix / ld d, (xix+hl)`.
;
; MidiCC_PartTargets_CC64_Sustain (+0x0E0): function 0 <- CC64; reader
; MidiCC_RxCC64_Sustain (0xFCFE0B), whose tail MidiCC_Helper_ConditionalESetup
; (0xFD036B) replaces E with D when the value is >= 0x40 and with 0 below it:
; here D = 0x08.
MidiCC_PartTargets_CC64_Sustain:
	.byte 0x00, 0x04, 0x08, 0x01, 0x04, 0x08, 0x02, 0x04, 0x08, 0x03, 0x04, 0x08
	.byte 0x04, 0x04, 0x08, 0x05, 0x04, 0x08, 0x06, 0x04, 0x08, 0x07, 0x04, 0x08
	.byte 0x08, 0x04, 0x08, 0x09, 0x04, 0x08, 0x0a, 0x04, 0x08, 0x0b, 0x04, 0x08
	.byte 0x0c, 0x04, 0x08, 0x0d, 0x04, 0x08, 0x0e, 0x04, 0x08, 0xff, 0xff, 0xff
	.byte 0x10, 0x04, 0x08, 0x11, 0x04, 0x08, 0x12, 0x04, 0x08, 0x13, 0x04, 0x08
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFD0F79-0xFD0F8C (19 B), unreached CODE-territory, was disassembled as 11 plausible-but-dead instruction lines; per=69% dist=6 near MidiCC_PartTargets_CC64_Sustain+50
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x17, 0x04, 0x08
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func08 (+0x140): function 8, reader MidiCC_RxFunc08
; (0xFCFE4B) -> MidiCC_RxFunc08_Helper.  No controller maps to function 8
; in MidiCC_ChannelMappingData, so this table is reachable only if (0x9657) is
; set some other way (not searched).
MidiCC_PartTargets_Func08:
	.byte 0xb7, 0x00, 0x7f, 0xb7, 0x01, 0x7f, 0xb7, 0x02, 0x7f, 0xb7, 0x03, 0x7f
	.byte 0xb7, 0x04, 0x7f, 0xb7, 0x05, 0x7f, 0xb7, 0x06, 0x7f, 0xb7, 0x07, 0x7f
	.byte 0xb7, 0x08, 0x7f, 0xb7, 0x09, 0x7f, 0xb7, 0x0a, 0x7f, 0xb7, 0x0b, 0x7f
	.byte 0xb7, 0x0c, 0x7f, 0xb7, 0x0d, 0x7f, 0xb7, 0x0e, 0x7f, 0xff, 0xff, 0xff
	.byte 0xb7, 0x10, 0x7f, 0xb7, 0x11, 0x7f, 0xb7, 0x12, 0x7f, 0xb7, 0x13, 0x7f
	.byte 0xff, 0xff, 0xff, 0xb7, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xb7, 0x17, 0x7f
	.byte 0xb7, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func09 (+0x1A0): function 9, reader MidiCC_RxFunc09
; (0xFCFE8C) -> MidiCC_RxFunc08_Helper.  Unmapped, as function 8.
MidiCC_PartTargets_Func09:
	.byte 0xb6, 0x00, 0x7f, 0xb6, 0x01, 0x7f, 0xb6, 0x02, 0x7f, 0xb6, 0x03, 0x7f
	.byte 0xb6, 0x04, 0x7f, 0xb6, 0x05, 0x7f, 0xb6, 0x06, 0x7f, 0xb6, 0x07, 0x7f
	.byte 0xb6, 0x08, 0x7f, 0xb6, 0x09, 0x7f, 0xb6, 0x0a, 0x7f, 0xb6, 0x0b, 0x7f
	.byte 0xb6, 0x0c, 0x7f, 0xb6, 0x0d, 0x7f, 0xb6, 0x0e, 0x7f, 0xff, 0xff, 0xff
	.byte 0xb6, 0x10, 0x7f, 0xb6, 0x11, 0x7f, 0xb6, 0x12, 0x7f, 0xb6, 0x13, 0x7f
	.byte 0xff, 0xff, 0xff, 0xb6, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xb6, 0x17, 0x7f
	.byte 0xb6, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC1_Modulation (+0x200): function 1 <- CC1, reader
; MidiCC_RxCC1_Modulation (0xFCFECD) -> MidiCC_RxCC1_Modulation_Helper.
MidiCC_PartTargets_CC1_Modulation:
	.byte 0xb2, 0x00, 0x7f, 0xb2, 0x01, 0x7f, 0xb2, 0x02, 0x7f, 0xb2, 0x03, 0x7f
	.byte 0xb2, 0x04, 0x7f, 0xb2, 0x05, 0x7f, 0xb2, 0x06, 0x7f, 0xb2, 0x07, 0x7f
	.byte 0xb2, 0x08, 0x7f, 0xb2, 0x09, 0x7f, 0xb2, 0x0a, 0x7f, 0xb2, 0x0b, 0x7f
	.byte 0xb2, 0x0c, 0x7f, 0xb2, 0x0d, 0x7f, 0xb2, 0x0e, 0x7f, 0xff, 0xff, 0xff
	.byte 0xb2, 0x10, 0x7f, 0xb2, 0x11, 0x7f, 0xb2, 0x12, 0x7f, 0xb2, 0x13, 0x7f
	.byte 0xff, 0xff, 0xff, 0xb2, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xb2, 0x17, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC7_Volume (+0x260): function 2 <- CC7, reader
; MidiCC_RxCC7_Volume (0xFCFF0E) -> PerfMode_Evt04_VolumeHandler_Helper2.
MidiCC_PartTargets_CC7_Volume:
	.byte 0x00, 0x03, 0x7f, 0x01, 0x03, 0x7f, 0x02, 0x03, 0x7f, 0x03, 0x03, 0x7f
	.byte 0x04, 0x03, 0x7f, 0x05, 0x03, 0x7f, 0x06, 0x03, 0x7f, 0x07, 0x03, 0x7f
	.byte 0x08, 0x03, 0x7f, 0x09, 0x03, 0x7f, 0x0a, 0x03, 0x7f, 0x0b, 0x03, 0x7f
	.byte 0x0c, 0x03, 0x7f, 0x0d, 0x03, 0x7f, 0x0e, 0x03, 0x7f, 0x0f, 0x03, 0x7f
	.byte 0x10, 0x03, 0x7f, 0x11, 0x03, 0x7f, 0x12, 0x03, 0x7f, 0x13, 0x03, 0x7f
	.byte 0x14, 0x03, 0x7f, 0x15, 0x03, 0x7f, 0xff, 0xff, 0xff, 0x17, 0x03, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC11_Expression (+0x2C0): function 3 <- CC11, reader
; MidiCC_RxCC11_Expression (0xFCFF4F) -> MidiCC_RxCC11_Expression_Helper.
MidiCC_PartTargets_CC11_Expression:
	.byte 0xb3, 0x00, 0x7f, 0xb3, 0x01, 0x7f, 0xb3, 0x02, 0x7f, 0xb3, 0x03, 0x7f
	.byte 0xb3, 0x04, 0x7f, 0xb3, 0x05, 0x7f, 0xb3, 0x06, 0x7f, 0xb3, 0x07, 0x7f
	.byte 0xb3, 0x08, 0x7f, 0xb3, 0x09, 0x7f, 0xb3, 0x0a, 0x7f, 0xb3, 0x0b, 0x7f
	.byte 0xb3, 0x0c, 0x7f, 0xb3, 0x0d, 0x7f, 0xb3, 0x0e, 0x7f, 0xb3, 0x0f, 0x7f
	.byte 0xb3, 0x10, 0x7f, 0xb3, 0x11, 0x7f, 0xb3, 0x12, 0x7f, 0xb3, 0x13, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xb3, 0x17, 0x7f
	.byte 0xff, 0xff, 0xff, 0xb0, 0x01, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC10_Pan (+0x320): function 4 <- CC10, reader
; MidiCC_RxCC10_Pan (0xFCFF90) -> MidiCC_RxCC10_Pan_Helper.
MidiCC_PartTargets_CC10_Pan:
	.byte 0x00, 0x08, 0x7f, 0x01, 0x08, 0x7f, 0x02, 0x08, 0x7f, 0x03, 0x08, 0x7f
	.byte 0x04, 0x08, 0x7f, 0x05, 0x08, 0x7f, 0x06, 0x08, 0x7f, 0x07, 0x08, 0x7f
	.byte 0x08, 0x08, 0x7f, 0x09, 0x08, 0x7f, 0x0a, 0x08, 0x7f, 0x0b, 0x08, 0x7f
	.byte 0x0c, 0x08, 0x7f, 0x0d, 0x08, 0x7f, 0x0e, 0x08, 0x7f, 0xff, 0xff, 0xff
	.byte 0x10, 0x08, 0x7f, 0x11, 0x08, 0x7f, 0x12, 0x08, 0x7f, 0x13, 0x08, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x17, 0x08, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC93_Chorus (+0x380): function 5 <- CC93, reader
; MidiCC_RxCC93_Chorus (0xFCFFD1) -> MidiCC_RxCC10_Pan_Helper.
MidiCC_PartTargets_CC93_Chorus:
	.byte 0x00, 0x05, 0x7f, 0x01, 0x05, 0x7f, 0x02, 0x05, 0x7f, 0x03, 0x05, 0x7f
	.byte 0x04, 0x05, 0x7f, 0x05, 0x05, 0x7f, 0x06, 0x05, 0x7f, 0x07, 0x05, 0x7f
	.byte 0x08, 0x05, 0x7f, 0x09, 0x05, 0x7f, 0x0a, 0x05, 0x7f, 0x0b, 0x05, 0x7f
	.byte 0x0c, 0x05, 0x7f, 0x0d, 0x05, 0x7f, 0x0e, 0x05, 0x7f, 0x0f, 0x05, 0x7f
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC94_Celeste (+0x3E0): function 6 <- CC94 (MIDI 1.0
; "effect 4 depth", formerly celeste), reader MidiCC_RxCC94_Celeste (0xFD0012);
; Records {u8 part, u8 0x04, u8 0x40}, the selector form of CC64; the reader
; ends in MidiCC_Helper_ConditionalESetup, so E = 0x40 when the controller
; value is >= 0x40, else 0 -- an on/off flag (cf. CC64's 0x08), not a level.
MidiCC_PartTargets_CC94_Celeste:
	.byte 0x00, 0x04, 0x40, 0x01, 0x04, 0x40, 0x02, 0x04, 0x40, 0x03, 0x04, 0x40
	.byte 0x04, 0x04, 0x40, 0x05, 0x04, 0x40, 0x06, 0x04, 0x40, 0x07, 0x04, 0x40
	.byte 0x08, 0x04, 0x40, 0x09, 0x04, 0x40, 0x0a, 0x04, 0x40, 0x0b, 0x04, 0x40
	.byte 0x0c, 0x04, 0x40, 0x0d, 0x04, 0x40, 0x0e, 0x04, 0x40, 0xff, 0xff, 0xff
	.byte 0x10, 0x04, 0x40, 0x11, 0x04, 0x40, 0x12, 0x04, 0x40, 0x13, 0x04, 0x40
	.byte 0xff, 0xff, 0xff, 0x15, 0x04, 0x40, 0xff, 0xff, 0xff, 0x17, 0x04, 0x40
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_CC91_Reverb (+0x440): function 7 <- CC91, reader
; MidiCC_RxCC91_Reverb (0xFD0052) -> MidiCC_RxCC10_Pan_Helper.
MidiCC_PartTargets_CC91_Reverb:
	.byte 0x00, 0x07, 0x7f, 0x01, 0x07, 0x7f, 0x02, 0x07, 0x7f, 0x03, 0x07, 0x7f
	.byte 0x04, 0x07, 0x7f, 0x05, 0x07, 0x7f, 0x06, 0x07, 0x7f, 0x07, 0x07, 0x7f
	.byte 0x08, 0x07, 0x7f, 0x09, 0x07, 0x7f, 0x0a, 0x07, 0x7f, 0x0b, 0x07, 0x7f
	.byte 0x0c, 0x07, 0x7f, 0x0d, 0x07, 0x7f, 0x0e, 0x07, 0x7f, 0x0f, 0x07, 0x7f
	.byte 0x10, 0x07, 0x7f, 0x11, 0x07, 0x7f, 0x12, 0x07, 0x7f, 0x13, 0x07, 0x7f
	.byte 0x14, 0x07, 0x7f, 0x15, 0x07, 0x7f, 0xff, 0xff, 0xff, 0x17, 0x07, 0x7f
	.byte 0xff, 0xff, 0xff, 0x60, 0x01, 0x80, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Unread_A (+0x4A0) and _Unread_B (+0x500): same record
; shape (selector low byte 0xBC / 0xBD), but NO READER FOUND.  Searched: the
; 24-bit address (0xFD1307 / 0xFD1367) anywhere in the ROM, and every
; `ld xix, MidiCC_ChannelMappingData*` in the tree.  They sit between the
; function-7 and function-12 tables, i.e. where functions 10 and 11 would
; keep theirs, and MidiCC_ExtendedRange_Table slots 10 and 11 hold
; MidiCC_StubHandler_A/B, which are a bare `ret` -- consistent with two
; functions compiled out, not proof of it.
MidiCC_PartTargets_Unread_A:
	.byte 0xbc, 0x00, 0x7f, 0xbc, 0x01, 0x7f, 0xbc, 0x02, 0x7f, 0xbc, 0x03, 0x7f
	.byte 0xbc, 0x04, 0x7f, 0xbc, 0x05, 0x7f, 0xbc, 0x06, 0x7f, 0xbc, 0x07, 0x7f
	.byte 0xbc, 0x08, 0x7f, 0xbc, 0x09, 0x7f, 0xbc, 0x0a, 0x7f, 0xbc, 0x0b, 0x7f
	.byte 0xbc, 0x0c, 0x7f, 0xbc, 0x0d, 0x7f, 0xbc, 0x0e, 0x7f, 0xbc, 0x0f, 0x7f
	.byte 0xbc, 0x10, 0x7f, 0xbc, 0x11, 0x7f, 0xbc, 0x12, 0x7f, 0xbc, 0x13, 0x7f
	.byte 0xbc, 0x14, 0x7f, 0xbc, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xbc, 0x17, 0x7f
	.byte 0xbc, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Unread_B (+0x500): same record layout; no reader found --
; see the searches listed above MidiCC_PartTargets_Unread_A.
MidiCC_PartTargets_Unread_B:
	.byte 0xbd, 0x00, 0x7f, 0xbd, 0x01, 0x7f, 0xbd, 0x02, 0x7f, 0xbd, 0x03, 0x7f
	.byte 0xbd, 0x04, 0x7f, 0xbd, 0x05, 0x7f, 0xbd, 0x06, 0x7f, 0xbd, 0x07, 0x7f
	.byte 0xbd, 0x08, 0x7f, 0xbd, 0x09, 0x7f, 0xbd, 0x0a, 0x7f, 0xbd, 0x0b, 0x7f
	.byte 0xbd, 0x0c, 0x7f, 0xbd, 0x0d, 0x7f, 0xbd, 0x0e, 0x7f, 0xbd, 0x0f, 0x7f
	.byte 0xbd, 0x10, 0x7f, 0xbd, 0x11, 0x7f, 0xbd, 0x12, 0x7f, 0xbd, 0x13, 0x7f
	.byte 0xbd, 0x14, 0x7f, 0xbd, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xbd, 0x17, 0x7f
	.byte 0xbd, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func12..15 (+0x560, +0x5C0, +0x620, +0x680): functions
; 12-15, readers MidiCC_RxFunc12 (0xFD009F), MidiCC_RxFunc13 (0xFD00E0),
; MidiCC_RxFunc14 (0xFD0121), MidiCC_RxFunc15 (0xFD0162), all -> MidiCC_RxFunc12_Helper.  No
; controller maps to these functions in MidiCC_ChannelMappingData.
MidiCC_PartTargets_Func12:
	.byte 0xb8, 0x00, 0x7f, 0xb8, 0x01, 0x7f, 0xb8, 0x02, 0x7f, 0xb8, 0x03, 0x7f
	.byte 0xb8, 0x04, 0x7f, 0xb8, 0x05, 0x7f, 0xb8, 0x06, 0x7f, 0xb8, 0x07, 0x7f
	.byte 0xb8, 0x08, 0x7f, 0xb8, 0x09, 0x7f, 0xb8, 0x0a, 0x7f, 0xb8, 0x0b, 0x7f
	.byte 0xb8, 0x0c, 0x7f, 0xb8, 0x0d, 0x7f, 0xb8, 0x0e, 0x7f, 0xb8, 0x0f, 0x7f
	.byte 0xb8, 0x10, 0x7f, 0xb8, 0x11, 0x7f, 0xb8, 0x12, 0x7f, 0xb8, 0x13, 0x7f
	.byte 0xb8, 0x14, 0x7f, 0xb8, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xb8, 0x17, 0x7f
	.byte 0xb8, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func13 (+0x5C0): same 32 x 3-byte record layout as the tables
; above; function 13, reader MidiCC_RxFunc13 (0xFD00E0) -> MidiCC_RxFunc12_Helper.
MidiCC_PartTargets_Func13:
	.byte 0xb9, 0x00, 0x7f, 0xb9, 0x01, 0x7f, 0xb9, 0x02, 0x7f, 0xb9, 0x03, 0x7f
	.byte 0xb9, 0x04, 0x7f, 0xb9, 0x05, 0x7f, 0xb9, 0x06, 0x7f, 0xb9, 0x07, 0x7f
	.byte 0xb9, 0x08, 0x7f, 0xb9, 0x09, 0x7f, 0xb9, 0x0a, 0x7f, 0xb9, 0x0b, 0x7f
	.byte 0xb9, 0x0c, 0x7f, 0xb9, 0x0d, 0x7f, 0xb9, 0x0e, 0x7f, 0xb9, 0x0f, 0x7f
	.byte 0xb9, 0x10, 0x7f, 0xb9, 0x11, 0x7f, 0xb9, 0x12, 0x7f, 0xb9, 0x13, 0x7f
	.byte 0xb9, 0x14, 0x7f, 0xb9, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xb9, 0x17, 0x7f
	.byte 0xb9, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func14 (+0x620): same 32 x 3-byte record layout as the tables
; above; function 14, reader MidiCC_RxFunc14 (0xFD0121) -> MidiCC_RxFunc12_Helper.
MidiCC_PartTargets_Func14:
	.byte 0xba, 0x00, 0x7f, 0xba, 0x01, 0x7f, 0xba, 0x02, 0x7f, 0xba, 0x03, 0x7f
	.byte 0xba, 0x04, 0x7f, 0xba, 0x05, 0x7f, 0xba, 0x06, 0x7f, 0xba, 0x07, 0x7f
	.byte 0xba, 0x08, 0x7f, 0xba, 0x09, 0x7f, 0xba, 0x0a, 0x7f, 0xba, 0x0b, 0x7f
	.byte 0xba, 0x0c, 0x7f, 0xba, 0x0d, 0x7f, 0xba, 0x0e, 0x7f, 0xba, 0x0f, 0x7f
	.byte 0xba, 0x10, 0x7f, 0xba, 0x11, 0x7f, 0xba, 0x12, 0x7f, 0xba, 0x13, 0x7f
	.byte 0xba, 0x14, 0x7f, 0xba, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xba, 0x17, 0x7f
	.byte 0xba, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_Func15 (+0x680): same 32 x 3-byte record layout as the tables
; above; function 15, reader MidiCC_RxFunc15 (0xFD0162) -> MidiCC_RxFunc12_Helper.
MidiCC_PartTargets_Func15:
	.byte 0xbb, 0x00, 0x7f, 0xbb, 0x01, 0x7f, 0xbb, 0x02, 0x7f, 0xbb, 0x03, 0x7f
	.byte 0xbb, 0x04, 0x7f, 0xbb, 0x05, 0x7f, 0xbb, 0x06, 0x7f, 0xbb, 0x07, 0x7f
	.byte 0xbb, 0x08, 0x7f, 0xbb, 0x09, 0x7f, 0xbb, 0x0a, 0x7f, 0xbb, 0x0b, 0x7f
	.byte 0xbb, 0x0c, 0x7f, 0xbb, 0x0d, 0x7f, 0xbb, 0x0e, 0x7f, 0xbb, 0x0f, 0x7f
	.byte 0xbb, 0x10, 0x7f, 0xbb, 0x11, 0x7f, 0xbb, 0x12, 0x7f, 0xbb, 0x13, 0x7f
	.byte 0xbb, 0x14, 0x7f, 0xbb, 0x15, 0x7f, 0xff, 0xff, 0xff, 0xbb, 0x17, 0x7f
	.byte 0xbb, 0x18, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
;
; Per-part 16-bit selectors, 32 x u16 (8 per line, entry n = part n), read
; as `sll a, 1 / ld bc, (xix+a)`; low byte 0xFF = part not affected.
;
; MidiCC_PartTargets_CC121_ResetAll (+0x6E0): function 40 <- CC121 (reset all
; controllers), reader MidiCC_Handler_ParamDispatch (0xFD02FF), D = 0x7F,
; -> VoiceMode3_EvType3_Helper.
MidiCC_PartTargets_CC121_ResetAll:
	.short 0x00ad, 0x01ad, 0x02ad, 0x03ad, 0x04ad, 0x05ad, 0x06ad, 0x07ad
	.short 0x08ad, 0x09ad, 0x0aad, 0x0bad, 0x0cad, 0x0dad, 0x0ead, 0x0fad
	.short 0x10ad, 0x11ad, 0x12ad, 0x13ad, 0x14ad, 0x15ad, 0xffff, 0xffff
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
; MidiCC_PartTargets_CC120_AllSoundOff (+0x720): function 41 <- CC120, reader
; MidiCC_Handler_TableDispatch (0xFD0335, which loads this address as the
; literal 0x00fd1587), D = 0x7F, -> MidiCC_Handler_TableDispatch_Helper.
MidiCC_PartTargets_CC120_AllSoundOff:
	.short 0x00ae, 0x01ae, 0x02ae, 0x03ae, 0x04ae, 0x05ae, 0x06ae, 0x07ae
	.short 0x08ae, 0x09ae, 0x0aae, 0x0bae, 0x0cae, 0x0dae, 0x0eae, 0x0fae
	.short 0x10ae, 0x11ae, 0x12ae, 0x13ae, 0x14ae, 0x15ae, 0xffff, 0xffff
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
; MidiPC_PartTargets (+0x760): PROGRAM CHANGE (status Cx).  Reader
; MidiRx_ProgramChange (0xFD039C, MidiCC_LowRange_Table slot 4):
; E = program number (0x9635), D = 0xFF, gated by bit 4 of (0xFD57),
; -> MidiRx_ProgramChange_Helper.
MidiPC_PartTargets:
	.short 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007
	.short 0x0008, 0x0009, 0x000a, 0x000b, 0x000c, 0x000d, 0x000e, 0x000f
	.short 0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0xffff, 0x0017
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
; MidiPB_PartTargets (+0x7A0): PITCH BEND (status Ex).  Reader
; MidiRx_PitchBend (0xFD03D8, slot 6): E = LSB (0x9635),
; D = MSB (0x9636), gated by bit 6 of (0xFD57), -> MidiRx_PitchBend_Helper.
MidiPB_PartTargets:
	.short 0x00b1, 0x01b1, 0x02b1, 0x03b1, 0x04b1, 0x05b1, 0x06b1, 0x07b1
	.short 0x08b1, 0x09b1, 0x0ab1, 0x0bb1, 0x0cb1, 0x0db1, 0x0eb1, 0xffff
	.short 0x10b1, 0x11b1, 0x12b1, 0x13b1, 0xffff, 0x15b1, 0xffff, 0x17b1
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
; MidiCP_PartTargets (+0x7E0): CHANNEL PRESSURE (status Dx).  Reader
; MidiRx_ChannelPressure (0xFD0416, slot 5): E = pressure (0x9635),
; D = 0x7F, gated by bit 5 of (0xFD57), -> MidiCC_RxFunc12_Helper.
MidiCP_PartTargets:
	.short 0x00b4, 0x01b4, 0x02b4, 0x03b4, 0x04b4, 0x05b4, 0x06b4, 0x07b4
	.short 0x08b4, 0x09b4, 0x0ab4, 0x0bb4, 0x0cb4, 0x0db4, 0x0eb4, 0xffff
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
; MidiCC_PartSelector_DataEntry (+0x820, 32 x u8): functions 32 and 33 <- CC6
; and CC38 (data entry MSB/LSB).  Readers MidiCC_Handler_BankModeSelect
; (0xFD01A3) and MidiCC_Handler_ExpressionParam (0xFD0234): `ld c, (xix+hl)`,
; 0xFF = part not affected; C becomes the selector's low byte and B is chosen
; by comparing the part's RPN word at 0x9674+2*part with 0x8080/0x8081/0x8082
; (the RPN MSB/LSB stored with bit 7 set by MidiCC_Handler_DirectStoreA/B,
; functions 34/35 <- CC101/CC100).
MidiCC_PartSelector_DataEntry:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
; MidiCC_PartTargets_BankSelect (+0x840, 32 x u16): functions 24 and 25 <- CC0
; and CC32 (bank select MSB/LSB).  Readers MidiCC_Handler_PairedParamB
; (0xFCFCFA, CC0: D = value, E = 0xFF) and MidiCC_Handler_PairedParamA
; (0xFCFCBC, CC32: E = value, D = 0xFF), both gated by bit 4 of (0xFD57), ->
; MidiCC_Handler_PairedParamA_Helper.
MidiCC_PartTargets_BankSelect:
	.short 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007
	.short 0x0008, 0x0009, 0x000a, 0x000b, 0x000c, 0x000d, 0x000e, 0x000f
	.short 0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x00ff, 0x0017
	.short 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff
PanelEvt_Handler_4_DualValueCheck:
	bit	3, (0x964f:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Skip2
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_4_DualValueCheck_Skip2
	ld	xix, PanelEvt_Handler_4_DualValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, PanelEvt_Handler_4_DualValueCheck_Skip2
	bit	0, (0xfd58:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Skip2
	ld	e, 0:opc
	bit	3, (0x964e:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Skip
	ld	e, 127:opc
PanelEvt_Handler_4_DualValueCheck_Skip:
	ld	w, 0:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_4_DualValueCheck_Skip2:
	bit	6, (0x964f:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Return
	ld	l, (0x964c:16)
	cp	l, 31
	jr	ugt, PanelEvt_Handler_4_DualValueCheck_Return
	ld	xix, PanelEvt_Handler_4_DualValueCheck_Data
	extz	hl
	sll	l, 2
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, PanelEvt_Handler_4_DualValueCheck_Return
	bit	5, (0xfd58:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Return
	ld	e, 0:opc
	bit	6, (0x964e:16)
	jr	z, PanelEvt_Handler_4_DualValueCheck_Skip3
	ld	e, 127:opc
PanelEvt_Handler_4_DualValueCheck_Skip3:
	ld	w, 6:opc
	calr	MidiChannel_ConfigureController
PanelEvt_Handler_4_DualValueCheck_Return:
	ret
	; MidiDispatchCC_HandlerTable (0xFD175E) -- MIDI CC handler table.
	; INDEXING RULE, from the only site that loads it (MidiCC_Dispatch, this file):
	;     cp c, 0xbf / jr ugt, <ret>      ; index = C, valid 0..0xBF
	;     ld l, c / extz hl / sll hl, 2   ; scaled by 4
	;     ld xix, ..._0x77 / ld_sril3 XIX, 0x07, 0xf0, 0xec   ; xix += hl
	;     call (xix)                      ; entry is a CODE address
	; => 192 entries of 4 bytes, index 0 at 0xFD175E, stride 4. Every entry
	; resolves to a label in this file, which is what settles CODE-pointer over
	; data-pointer. It was previously spelled as 1-byte .byte runs interleaved
	; with resync garbage; the byte gate could not see the difference.

	; Supersedes 3 v10_data_as_code_census.py notes inside this span (the first
	; reads: 0xFD17AB-0xFD191E (371 B), unreached CODE-territory, was disassembled
	; as 188 plausible-but-dead instruction lines). The census was RIGHT that this
	; is data and WRONG about where it starts: it carved from 0xFD17AB, one byte
	; past the entry boundary, so every record shown was a rotation of the real
	; one. The array starts at 0xFD175E, immediately after the `ret` at 0xFD175D.
MidiDispatchCC_HandlerTable:
	.long PanelEvt_CheckFlag7_Dispatch_A
	.long PanelEvt_CheckFlag7_Dispatch_B
	.long PanelEvt_CheckFlag7_Dispatch_C
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_UnconditionalDispatch
	.long PanelEvt_CheckFlag6_Dispatch
	.long PanelEvt_CheckFlag6_Dispatch
	.long PanelEvt_CheckFlag6_Dispatch
	.long PanelEvt_CheckFlag6_Dispatch
	.long PanelEvt_CheckChanZero_Dispatch
	.long PanelEvt_CheckFlag6_Dispatch
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long PanelEvt_Dispatch6Entry
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long PanelEvt_Dispatch3Entry_A
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long PanelEvt_Dispatch3Entry_B
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_ChannelDispatch_TableA
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long PanelEvt_Dispatch11Entry
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_ChannelDispatch_Ctrl40
	.long MidiCC_ChannelDispatch_Ctrl41
	.long MidiCC_DispatchStubRet
	.long MidiCC_ChannelDispatch_SpecialCh1
	.long MidiCC_ChannelDispatch_CtrlFlags
	.long MidiCC_ChannelDispatch_Ctrl1
	.long MidiCC_ChannelDispatch_Ctrl3
	.long MidiCC_ChannelDispatch_CtrlFlags2
	.long MidiCC_ChannelDispatch_Ctrl0
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	.long MidiCC_DispatchStubRet
	; MidiCC_FunctionToCCNumber (0xFD1A5E) -- 48-entry byte table.
	; INDEXING RULE, from MidiChanCfg_SetupParams (this file):
	;     cp w, 0x2f / jr ugt, <exit>     ; index = W, valid 0..0x2F
	;     ld xiz, ..._0x377 / ldb_sri W, 0x03, 0xf8, 0xe1   ; W = (xiz + W)
	;     cp w, 0xff / jr z, <exit>       ; 0xFF means 'no entry'
	; => 48 bytes, stride 1, 0xFF = absent. A genuine byte table: it is printed
	; 8 per line only to show the six 8-entry groups, not because 8 is a record.
; MidiCC_FunctionToCCNumber: the TRANSMIT direction of MidiCC_ChannelMappingData.
; Entry f is the controller number sent for CC function f; it is exactly the
; inverse of that receive map (function 0 -> 0x40 = CC64, 1 -> CC1, 2 -> CC7,
; ... 40 -> CC121, 41 -> CC120), and MidiChannel_ConfigureController builds
; the message as status 0xB0 | channel, this byte, value E.
MidiCC_FunctionToCCNumber:
	.byte 0x40, 0x01, 0x07, 0x0b, 0x0a, 0x5d, 0x5e, 0x5b

	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff

	.byte 0x50, 0x52, 0x53, 0xff, 0xff, 0xff, 0xff, 0xff

	.byte 0x00, 0x20, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff

	.byte 0x06, 0x26, 0x65, 0x64, 0xff, 0xff, 0xff, 0xff

	.byte 0x79, 0x78, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	; 0xFD1A8E..0xFD268F -- 24 records of 32 x u32, stride 0x80.
	; INDEXING RULE, from the 26 sites in this file that load a record base
	; (PanelEvt_Handler_0_NoteOnParam_Data .. _0xE28 in shared/positional_labels.s):
	;     ldb_d8 l, (0x964c) / cp l, 31 / jr ugt, <skip>   ; index = L, valid 0..31
	;     ld xix, <record base> / extz hl / sll l, 2
	;     ld_rrl xix, xix, hl             ; xix = record[index]
	;     cp xix, 0xffffffff / jr z, <skip>   ; 0xFFFFFFFF means 'no entry'
	; => 32 entries of 4 bytes per record; present entries are work-RAM addresses
	; 0x0000F9C3 + 26*k (26-byte parameter blocks, k = 0..23); absent entries are
	; 0xFFFFFFFF.  Except: entries 23 and 24 of the six records 0xFD238F..0xFD260F
	; point at 0xFD6F / 0xFD89, a second pair of 26-byte blocks (checked against
	; the ROM: those 12 are the only present entries off the 0xF9C3 + 26*k grid).
	; Record bases run 0xFD1A8E + 0x80*k for k=0..4, then 0xFD1D0F + 0x80*k for
	; k=0..18 -- there is a ONE-BYTE 0xFF pad at 0xFD1D0E, which is why the
	; second block is offset by one and why this span is emitted in three
	; segments. The positional labels are the evidence for that offset, not a
	; guess: _0x5A7 = base+1447 and _0x628 = base+1576, a gap of 129.

	; Previously this span was carved by v10_data_as_code_census.py at a start
	; offset one byte past the true array start, so each record appeared as
	; '.byte <tail>' plus fake instructions ('swi 1 / nop / nop') for its head.
	; Those census notes are removed here because the offset they record is the
	; wrong one; the census's finding -- that this is data, not code -- stands.

	; Supersedes 44 v10_data_as_code_census.py notes inside this span, all carved
	; one byte late for the same reason (e.g. 0xFD1A93-0xFD1AB2 (31 B) is the tail
	; of the record that really starts at 0xFD1A8E).
PanelEvt_Handler_0_NoteOnParam_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0x0000fbcb, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_3_ValueCheck_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0x0000fbcb, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_5_ValueCheck_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_4_DualValueCheck_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_7_ValueCheck_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0x0000fbcb, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0x0000fc19, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	; one-byte 0xFF pad; the record grid restarts at 0xFD1D0F
	.byte 0xff
PanelEvt_Handler_8_ValueCheck_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_9_SingleByteParam_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_10_TwoByteParam_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

PanelEvt_Handler_11_SingleByteParam_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Ctrl40_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Ctrl41_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_CtrlFlags_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Ctrl1_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Ctrl3_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0x0000fb49
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0x0000fc19, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_CtrlFlags2_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Ctrl0_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func09_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func08_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func12_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func13_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func14_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

MidiCC_ChannelDispatch_Func15_Data:
	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff

	.long 0x0000f9c3, 0x0000f9dd, 0x0000f9f7, 0x0000fa11
	.long 0x0000fa2b, 0x0000fa45, 0x0000fa5f, 0x0000fa79
	.long 0x0000fa93, 0x0000faad, 0x0000fac7, 0x0000fae1
	.long 0x0000fafb, 0x0000fb15, 0x0000fb2f, 0xffffffff
	.long 0x0000fb63, 0x0000fb7d, 0x0000fb97, 0x0000fbb1
	.long 0xffffffff, 0x0000fbe5, 0xffffffff, 0x0000fd6f
	.long 0x0000fd89, 0xffffffff, 0xffffffff, 0xffffffff
	.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
FileData_ValidateFormat:
	pushw wa
	dec 2, xsp
	ld (xsp), a
	call SeqState_GetFlags
	and hl, 0xf
	jr z, FileData_ValidateFormat_CheckMatch
	ldw hl, 0xffff
	jr FileData_ValidateFormat_Return

FileData_ValidateFormat_CheckMatch:
	ld a, (1060:16)
	cp a, (xsp)
	jr z, FileData_ValidateFormat_Match
	mrib4 0x87, 0x19, 0x24, 0x04
	ldw hl, 0xffff
	jr FileData_ValidateFormat_Return

FileData_ValidateFormat_Match:
	ld l, (xsp)
	extz hl

FileData_ValidateFormat_Return:
	inc 2, xsp
	popw wa
	ret

; --- FileData_LoadAndParse: Allocate buffer, load file, dispatch by format ---
; Allocates 32-byte buffer via malloc (0xff3e80). On failure returns 0xff38.
; Reads data into buffer via (0xf89a74), then dispatches based on format type:
;   type 1: calls local handler (+108 bytes)
;   type 2: calls local handler (+557 bytes), chains to secondary (+7610)
;   type 3: calls local handler (+7252 bytes), chains to secondary (+7610)
; On any sub-handler failure (negative result), returns error.
; Frees buffer via (0xff3af2) before returning status in HL.
FileData_AllocLoadAndParse:
	dec	4, xsp
	pushw	iz
	pushw	32
	call	Malloc
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, (xsp+2)
	or	xwa, xwa
	jr	nz, FileData_AllocLoadAndParse_Skip
	ldw	hl, 0xff38
	jr	FileData_AllocLoadAndParse_Epilogue
FileData_AllocLoadAndParse_Skip:
	ld	xwa, (xsp+2)
	ld	xbc, 32
	call	FileIO_ReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileData_AllocLoadAndParse_Join
	ld	xwa, (xsp+2)
	calr	DataBuf_CheckFormatPair
	ld	(0xb7ea:16), hl
	cp	hl, 3:i3
	jr	z, FileData_AllocLoadAndParse_Skip3
	cp	hl, 2:i3
	jr	z, FileData_AllocLoadAndParse_Skip2
	cp	hl, 1:i3
	jr	nz, FileData_AllocLoadAndParse_Skip4
FileData_AllocLoadAndParse_Skip2:
	calr	FileData_RawDataBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileData_AllocLoadAndParse_Join
	calr	FileData_AllocLoadAndParse_Helper
	ld	iz, hl
	jr	FileData_AllocLoadAndParse_Join
FileData_AllocLoadAndParse_Skip3:
	calr	FileData_AllocLoadAndParse_Helper2
	ld	iz, hl
	cp	iz, 0:i3
	jr	lt, FileData_AllocLoadAndParse_Join
	calr	FileData_AllocLoadAndParse_Helper3
	ld	iz, hl
	jr	FileData_AllocLoadAndParse_Join
FileData_AllocLoadAndParse_Skip4:
	ldw	iz, 0xff9a
FileData_AllocLoadAndParse_Join:
	ld	xwa, (xsp+2)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
FileData_AllocLoadAndParse_Epilogue:
	popw	iz
	inc	4, xsp
	ret

FileData_LoadFromSlot:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	sla bc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	lda	xwa, (xwa+bc)
	calr DataBuf_CheckSubFormat
	ld (0xb7ea:16), hl
	ld a, (xsp)
	extz wa
	cp hl, 3:i3
	jr z, FileData_LoadFromSlot_Type3
	cp hl, 2:i3
	jr z, FileData_LoadFromSlot_Type1or2
	cp hl, 1:i3
	jr nz, FileData_LoadFromSlot_UnknownFormat

FileData_LoadFromSlot_Type1or2:
	calr DataBuf_AllocAndLoadFormatted
	jr FileData_LoadFromSlot_Return

FileData_LoadFromSlot_Type3:
	calr FileData_LoadAndParseType3
	jr FileData_LoadFromSlot_Return

FileData_LoadFromSlot_UnknownFormat:
	ldw hl, 0xff9a

FileData_LoadFromSlot_Return:
	inc 2, xsp
	ret

FileData_RawDataBlock:
	lda	xsp, (xsp-10)
	push	xiz
	call	PreLswLoad
	calr	DataBuf_Data_FormatDispatch
	lda	xwa, (0xf980:16)
	ld	(xsp+6), xwa
	pushw	1664
	call	Malloc
	inc	2, xsp
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	or	xwa, xwa
	jr	nz, FileData_RawDataBlock_Skip
	ldw	hl, 0xff38
	jrl	FileData_RawDataBlock_Epilogue
FileData_RawDataBlock_Skip:
	ld	xwa, (xsp+10)
	add	xwa, 32
	ld	xbc, 1632
	call	FileIO_ReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	ge, FileData_RawDataBlock_Skip2
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	FileData_RawDataBlock_Epilogue
FileData_RawDataBlock_Skip2:
	ldw	(xsp+4), 0
FileData_RawDataBlock_Loop2:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 32
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 52
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	DataBuf_CopyVoiceBlock24
	incw	1, (xsp+4)
	cpw	(xsp+4), 24
	jr	c, FileData_RawDataBlock_Loop2
	ldw	(xsp+4), 0
FileData_RawDataBlock_Loop3:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld	xwa, xbc
	add	xwa, 0x320
	add	xwa, (xsp+10)
	add	xbc, 0x2a4
	add	xbc, (xsp+6)
	calr	DataBuf_CopyEffectBlock12
	incw	1, (xsp+4)
	cpw	(xsp+4), 3
	jr	c, FileData_RawDataBlock_Loop3
	ld	xwa, (xsp+10)
	lda xwa, (xwa+836)
	ld xbc, (xsp+6)
	lda xbc, (xbc+728)
	calr DataBuf_CopyFilterBlock12
	ld xwa, (xsp+10)
	lda	xwa, (xwa+852)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+740)
	calr	DataBuf_CopyReverbBlock6
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+860)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+748)
	calr	DataBuf_CopySimpleBlock4
	ldw	(xsp+4), 0
FileData_RawDataBlock_Loop4:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 874
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 754
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	DataBuf_LoadAndDispatchFormat2
	incw	1, (xsp+4)
	cpw	(xsp+4), 2
	jr	c, FileData_RawDataBlock_Loop4
	ld	xwa, (xsp+10)
	lda xwa, (xwa+938)
	ld xbc, (xsp+6)
	lda xbc, (xbc+896)
	calr DataBuf_CopyEQBlock7
	ld	xwa, (xsp+10)
	lda xwa, (xwa+952)
	ld	xbc, (xsp+6)
	lda xbc, (xbc+906)
	calr DataBuf_CopyChorusBlock16
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+968)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+922)
	calr	DataBuf_CopyCompressorBlock16
	ld	xwa, (xsp+10)
	lda xwa, (xwa+984)
	ld xbc, (xsp+6)
	lda xbc, (xbc+938)
	calr DataBuf_CopyDelayBit2
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+990)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+974)
	calr	DataBuf_CopyMixerBlock12
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DataBuf_CopyBulkBitfields_Nop
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DataBuf_CopyBulkBitfields_944
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DataBuf_CopyBulkBitfields_Large
	ld	wa, 0:i3
	call	PostLswLoad
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, 0:i3
FileData_RawDataBlock_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret
FileData_AllocLoadAndParse_Helper:
	lda	xsp, (xsp-14)
	push	xiz
	ld	wa, (0xb7ea:16)
	cp	wa, 1:i3
	jr	z, FileData_AllocLoadAndParse_Helper_Skip2
	cp	wa, 2:i3
	jr	nz, FileData_AllocLoadAndParse_Helper_Skip3
	ldw	(xsp+12), 10
FileData_AllocLoadAndParse_Helper_Join:
	call	PrePmLoad
	ld	wa, (xsp+12)
	calr	DataBuf_CopyBulkBitfields_Large_Helper3
	ldw (xsp+8), 0
	ld	wa, (xsp+12)
	srl	wa, 3
	cp	wa, 0:i3
	jr	ule, FileData_AllocLoadAndParse_Helper_Skip
FileData_AllocLoadAndParse_Helper_Loop:
	ld	wa, (xsp+8)
	calr	SndParam_TableDispatch_Memset
	incw	1, (xsp+8)
	ld	wa, (xsp+12)
	srl	wa, 3
	cp	(xsp+8), wa
	jr	c, FileData_AllocLoadAndParse_Helper_Loop
FileData_AllocLoadAndParse_Helper_Skip:
	pushw	768
	call	Malloc
	inc	2, xsp
	ld	(xsp+14), xhl
	ld	xwa, (xsp+14)
	or	xwa, xwa
	jr	z, FileData_AllocLoadAndParse_Helper_Skip3
	ldw (xsp+10), 0
	cpw	(xsp+12), 0
	jrl	ule, FileData_AllocLoadAndParse_Helper_Skip5
FileData_AllocLoadAndParse_Helper_Loop2:
	ld	xwa, (xsp+14)
	ld	xbc, 768
	call	FileIO_ReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	ge, FileData_AllocLoadAndParse_Helper_Skip4
	ld	xwa, (xsp+14)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	FileData_RawDataBlock_Epilogue2
FileData_AllocLoadAndParse_Helper_Skip2:
	ldw (xsp+12), 24
	jr	FileData_AllocLoadAndParse_Helper_Join
FileData_AllocLoadAndParse_Helper_Skip3:
	ldw	hl, 0xff38
	jrl	FileData_RawDataBlock_Epilogue2
FileData_AllocLoadAndParse_Helper_Skip4:
	ld	wa, (xsp+10)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	ld	(xsp+4), xwa
	ldw (xsp+8), 0
FileData_AllocLoadAndParse_Helper_Loop3:
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 3
	ld	xiz, xbc
	add	xiz, (xsp+14)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	add	xhl, (xsp+4)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	DataBuf_CopyVoiceBlock24
	incw	1, (xsp+8)
	cpw	(xsp+8), 24
	jr	c, FileData_AllocLoadAndParse_Helper_Loop3
	ldw	(xsp+8), 0
FileData_AllocLoadAndParse_Helper_Loop4:
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld	xwa, xbc
	add	xwa, 0x240
	add	xwa, (xsp+14)
	add	xbc, 0x284
	add	xbc, (xsp+4)
	calr	DataBuf_CopyEffectBlock12
	incw	1, (xsp+8)
	cpw	(xsp+8), 3
	jr	c, FileData_AllocLoadAndParse_Helper_Loop4
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+612)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+696)
	calr	DataBuf_CopyFilterBlock12
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+624)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+708)
	calr	DataBuf_CopyReverbBlock6
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+631)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+716)
	calr	DataBuf_CopySimpleBlock4
	ldw (xsp+8), 0
FileData_RawDataBlock_Loop:
	ld	wa, (xsp+8)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 645
	ld	xiz, xbc
	add	xiz, (xsp+14)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 722
	add	xhl, (xsp+4)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	DataBuf_LoadAndDispatchFormat2
	incw	1, (xsp+8)
	cpw	(xsp+8), 2
	jr	c, FileData_RawDataBlock_Loop
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+709)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+864)
	calr	DataBuf_CopyEQBlock7
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+716)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+874)
	calr	DataBuf_CopyChorusBlock16
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+732)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+890)
	calr	DataBuf_CopyCompressorBlock16
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+748)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+906)
	calr	DataBuf_CopyDelayBit2
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+754)
	ld	xbc, (xsp+4)
	lda	xbc, (xbc+942)
	calr	DataBuf_CopyMixerBlock12
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+4)
	calr	DataBuf_CopyBulkBitfields_Stub
	ld	xwa, 0xf980
	ld	xbc, (xsp+4)
	calr	DataBuf_CopyBulkBitfields_960
	incw	1, (xsp+10)
	ld	wa, (xsp+10)
	cp	wa, (xsp+12)
	jrl	c, FileData_AllocLoadAndParse_Helper_Loop2
FileData_AllocLoadAndParse_Helper_Skip5:
	ld	wa, 0:i3
	call	PostPmLoad
	ld	xwa, (xsp+14)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, 0:i3
FileData_RawDataBlock_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+14)
	ret

DataBuf_AllocAndLoadFormatted:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	pushw 0x800
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, DataBuf_AllocAndLoadFormatted_AllocOk
	ldw hl, 0xff38
	jrl DataBuf_AllocAndLoadFormatted_Return

DataBuf_AllocAndLoadFormatted_AllocOk:
	pushw 0x800
	ld c, (xsp + 20)
	extz bc
	sla bc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	lda	xwa, (xwa+bc)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	lda xwa, (xwa+736)
	ld (xsp + 10), xwa
	ld a, (xsp + 18)
	extz wa
	inc 1, wa
	calr DataBuf_InitSlotFromPreset
	ld c, (xsp + 18)
	extz bc
	sla bc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	lda	xwa, (xwa+bc)
	ld (xsp + 14), xwa
	ld xwa, 0x2e0
	add (xsp + 14), xwa
	ldw (xsp + 4), 0x0

DataBuf_TransferVoiceParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 5
	add xbc, 0x20
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x34
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr DataBuf_CopyVoiceBlock24
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x18
	jr c, DataBuf_TransferVoiceParams_Loop
	ldw (xsp + 4), 0x0

DataBuf_TransferEffectParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	ld xwa, xbc
	add xwa, 0x320
	add xwa, (xsp + 10)
	add xbc, 0x2a4
	add xbc, (xsp + 14)
	calr DataBuf_CopyEffectBlock12
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x3
	jr c, DataBuf_TransferEffectParams_Loop
	ld xwa, (xsp + 10)
	lda xwa, (xwa+836)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+728)
	calr DataBuf_CopyFilterBlock12
	ld xwa, (xsp + 10)
	lda xwa, (xwa+852)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+740)
	calr DataBuf_CopyReverbBlock6
	ld xwa, (xsp + 10)
	lda xwa, (xwa+860)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+748)
	calr DataBuf_CopySimpleBlock4
	ldw (xsp + 4), 0x0

DataBuf_TransferAuxParams_Loop:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 5
	add xbc, 0x36a
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x2f2
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr DataBuf_LoadAndDispatchFormat2
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x2
	jr c, DataBuf_TransferAuxParams_Loop
	ld xwa, (xsp + 10)
	lda xwa, (xwa+938)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+896)
	calr DataBuf_CopyEQBlock7
	ld xwa, (xsp + 10)
	lda xwa, (xwa+952)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+906)
	calr DataBuf_CopyChorusBlock16
	ld xwa, (xsp + 10)
	lda xwa, (xwa+968)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+922)
	calr DataBuf_CopyCompressorBlock16
	ld xwa, (xsp + 10)
	lda xwa, (xwa+984)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+938)
	calr DataBuf_CopyDelayBit2
	ld xwa, (xsp + 10)
	lda xwa, (xwa+990)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+974)
	calr DataBuf_CopyMixerBlock12
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	calr DataBuf_CopyBulkBitfields_Nop
	ld xwa, 0xf980
	ld xbc, (xsp + 14)
	calr DataBuf_CopyBulkBitfields_F980
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 4, xsp
	ld hl, 0:i3

DataBuf_AllocAndLoadFormatted_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

DataBuf_CopyVoiceBlock24:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	and a, 0x7f
	andmi8 (xbc + 4), 0x80
	or (xbc + 4), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	ld a, (xde + 7)
	and a, 0x7f
	andmi8 (xbc + 7), 0x80
	or (xbc + 7), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 9)
	and a, 0x7f
	andmi8 (xbc + 9), 0x80
	or (xbc + 9), a
	ld a, (xde + 10)
	and a, 0x7f
	andmi8 (xbc + 10), 0x80
	or (xbc + 10), a
	ld a, (xde + 11)
	and a, 0x7f
	andmi8 (xbc + 11), 0x80
	or (xbc + 11), a
	ld a, (xde + 12)
	ld (xbc + 12), a
	ld a, (xde + 13)
	and a, 0x7f
	andmi8 (xbc + 13), 0x80
	or (xbc + 13), a
	lda xix, (xbc + 14)
	lda xhl, (xde + 14)
	ld a, (xhl)
	srl a, 6
	and a, 0x3
	sla a, 6
	andmi8 (xix), 0x3f
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 15)
	lda xhl, (xde + 15)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 16)
	lda xhl, (xde + 16)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 17)
	ld (xbc + 17), a
	ld a, (xde + 18)
	ld (xbc + 18), a
	lda xix, (xbc + 19)
	lda xhl, (xde + 19)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 20)
	lda xhl, (xde + 20)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 21)
	lda xhl, (xde + 21)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	lda xix, (xbc + 22)
	lda xhl, (xde + 22)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ld a, (xhl)
	and a, 0x7f
	andmi8 (xix), 0x80
	or (xix), a
	ld a, (xde + 23)
	ld (xbc + 23), a
	ret

DataBuf_CopyEffectBlock12:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	lda xix, (xbc + 3)
	lda xhl, (xde + 3)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ld a, (xhl)
	srl a, 4
	and a, 0xf
	sla a, 4
	andmi8 (xix), 0xf
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xbc, (xbc + 9)
	lda xwa, (xde + 9)
	ldcfm 5, (xwa)
	stcfm 5, (xbc)
	ldcfm 4, (xwa)
	stcfm 4, (xbc)
	ld a, (xwa)
	and a, 0xf
	andmi8 (xbc), 0xf0
	or (xbc), a
	ret

DataBuf_CopyFilterBlock12:
	ld xde, xwa
	ld a, (xde + 2)
	ld (xbc + 2), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	res 7, a
	ld (xbc + 4), a
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0x7
	andmi8 (xix), 0xf8
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	stcfm 2, (xix)
	ld a, (xde + 9)
	and a, 0x30
	andmi8 (xbc + 9), 0xcf
	or (xbc + 9), a
	ld a, (xde + 10)
	ld (xbc + 10), a
	ldcfm 0, (xde + 11)
	stcfm 0, (xbc + 11)
	ret

DataBuf_CopyReverbBlock6:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	ldcfm 1, (xde + 3)
	stcfm 1, (xbc + 3)
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	inc 5, xbc
	lda xwa, (xde + 5)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopySimpleBlock4:
	ld e, (xwa + 2)
	ld (xbc + 2), e
	ldcfm 7, (xwa + 3)
	stcfm 7, (xbc + 3)
	ret

DataBuf_LoadAndDispatchFormat2:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xbc
	ld hl, (0xb7ea:16)
	lda xbc, (xwa + 2)
	ld xwa, (xsp + 6)
	lda xde, (xwa + 2)
	ld a, (xwa + 1)
	extz wa
	cp hl, 2:i3
	jrl z, DataBuf_Format2_FormatType2
	cp hl, 1:i3
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	pushw wa
	push xbc
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	inc 2, xwa
	call DSPCfg_ApplyParamStruct
	cp hl, 0:i3
	jrl ge, DataBuf_LoadAndDispatchFormat2_Return
	ld xwa, (xsp + 6)
	ld c, (xwa)
	lda xde, (xwa + 2)
	cp c, 0x63
	jrl z, DataBuf_Format2_Type63
	cp c, 0x61
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	ld xwa, 0x4900
	ld bc, 1:i3
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc74:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DataBuf_Format2_Type61_RestoreSlotId
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DataBuf_Format2_Type61_RestoreSlotId

DataBuf_Format2_Type61_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DataBuf_Format2_Type61_UpdateLoop

DataBuf_Format2_Type61_RestoreSlotId:
	ld a, (xsp + 4)
	jrl DataBuf_StoreSlotId_Return

DataBuf_Format2_Type63:
	ld xwa, 0x4b00
	ldw bc, 0x14
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc8e:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DataBuf_Format2_Type63_RestoreSlotId
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DataBuf_Format2_Type63_RestoreSlotId

DataBuf_Format2_Type63_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DataBuf_Format2_Type63_UpdateLoop

DataBuf_Format2_Type63_RestoreSlotId:
	ld a, (xsp + 4)
	jrl DataBuf_StoreSlotId63_Return

DataBuf_Format2_FormatType2:
	pushw wa
	push xbc
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	inc 2, xwa
	call DSPCfg_ApplyParamStructFull
	cp hl, 0:i3
	jrl ge, DataBuf_LoadAndDispatchFormat2_Return
	ld xbc, (xsp + 6)
	ld a, (xbc)
	cp a, 0x63
	jrl z, DataBuf_FormatType2_Type63
	cp a, 0x61
	jrl nz, DataBuf_LoadAndDispatchFormat2_Return
	lda xde, (xbc + 2)
	ld xwa, 0x4900
	ld bc, 1:i3
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc74:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DataBuf_FormatType2_RestoreSlotId
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DataBuf_FormatType2_RestoreSlotId

DataBuf_FormatType2_Type61_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DataBuf_FormatType2_Type61_UpdateLoop

DataBuf_FormatType2_RestoreSlotId:
	ld a, (xsp + 4)

DataBuf_StoreSlotId_Return:
	ld (0xfc74:16), a
	jrl DataBuf_LoadAndDispatchFormat2_Return

DataBuf_FormatType2_Type63:
	ld xwa, (xsp + 6)
	lda xde, (xwa + 2)
	ld xwa, 0x4b00
	ldw bc, 0x14
	call DSPCfg_WriteParamSimple
	ld xbc, (xsp + 6)
	ld a, (xbc + 1)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc + 3)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc8e:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa + 2)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DataBuf_FormatType2_Type63_RestoreSlotId
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DataBuf_FormatType2_Type63_RestoreSlotId

DataBuf_FormatType2_Type63_UpdateLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	inc 2, xde
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DataBuf_FormatType2_Type63_UpdateLoop

DataBuf_FormatType2_Type63_RestoreSlotId:
	ld a, (xsp + 4)

DataBuf_StoreSlotId63_Return:
	ld (0xfc8e:16), a

DataBuf_LoadAndDispatchFormat2_Return:
	pop xiz
	inc 6, xsp
	ret

DataBuf_CopyEQBlock7:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ld a, (xhl)
	and a, 0x30
	srl a, 4
	and a, 0x3
	sla a, 4
	andmi8 (xix), 0xcf
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ld a, (xhl)
	and a, 0x3
	andmi8 (xix), 0xfc
	or (xix), a
	ld a, (xde + 3)
	and a, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ld a, (xde + 4)
	ld (xbc + 4), a
	ld a, (xde + 6)
	and a, 0xf
	andmi8 (xbc + 6), 0xf0
	or (xbc + 6), a
	cpw (0xb7ea:16), 2
	ret nz
	ld a, (xde + 5)
	ld (xbc + 5), a
	ret

DataBuf_CopyChorusBlock16:
	ld e, (xwa + 2)
	ld (xbc + 2), e
	ld e, (xwa + 3)
	and e, 0x7f
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), e
	ld e, (xwa + 4)
	res 7, e
	ld (xbc + 4), e
	ld e, (xwa + 5)
	and e, 0x7f
	andmi8 (xbc + 5), 0x80
	or (xbc + 5), e
	ldcfm 6, (xwa + 6)
	stcfm 6, (xbc + 6)
	ld e, (xwa + 7)
	and e, 0x7f
	andmi8 (xbc + 7), 0x80
	or (xbc + 7), e
	ld e, (xwa + 8)
	ld (xbc + 8), e
	ld e, (xwa + 9)
	and e, 0x7f
	andmi8 (xbc + 9), 0x80
	or (xbc + 9), e
	lda xde, (xbc + 10)
	ldcfm 7, (xwa + 11)
	stcfm 7, (xde)
	ld l, (xwa + 11)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 11)
	ldcfm 7, (xwa + 12)
	stcfm 7, (xde)
	ld l, (xwa + 12)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 12)
	ldcfm 7, (xwa + 13)
	stcfm 7, (xde)
	ld l, (xwa + 13)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xde, (xbc + 13)
	ldcfm 7, (xwa + 14)
	stcfm 7, (xde)
	ld l, (xwa + 14)
	and l, 0x7f
	andmi8 (xde), 0x80
	or (xde), l
	lda xbc, (xbc + 14)
	ldcfm 7, (xwa + 15)
	stcfm 7, (xbc)
	ld a, (xwa + 15)
	and a, 0x7f
	andmi8 (xbc), 0x80
	or (xbc), a
	ret

DataBuf_CopyCompressorBlock16:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xix, (xde + 3)
	lda xhl, (xwa + 3)
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xix), 0x7f
	or (xix), c
	ld c, (xhl)
	and c, 0xf
	andmi8 (xix), 0xf0
	or (xix), c
	ld c, (xwa + 4)
	ld (xde + 4), c
	ld c, (xwa + 5)
	ld (xde + 5), c
	ld c, (xwa + 6)
	ld (xde + 6), c
	ld c, (xwa + 7)
	ld (xde + 7), c
	ld c, (xwa + 8)
	ld (xde + 8), c
	ld c, (xwa + 9)
	ld (xde + 9), c
	ld c, (xwa + 10)
	ld (xde + 10), c
	ld c, (xwa + 11)
	ld (xde + 11), c
	ld c, (xwa + 12)
	ld (xde + 12), c
	ld c, (xwa + 13)
	ld (xde + 13), c
	ld c, (xwa + 14)
	ld (xde + 14), c
	ld a, (xwa + 15)
	ld (xde + 15), a
	ret

DataBuf_CopyDelayBit2:
	inc 2, xbc
	inc 2, xwa
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopyMixerBlock12:
	ld xde, xwa
	lda xix, (xbc + 2)
	lda xhl, (xde + 2)
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ld a, (xhl)
	and a, 0x3
	andmi8 (xix), 0xfc
	or (xix), a
	ldcfm 3, (xde + 3)
	stcfm 3, (xbc + 3)
	lda xix, (xbc + 4)
	lda xhl, (xde + 4)
	ld a, (xhl)
	and a, 0x18
	srl a, 3
	and a, 0x3
	sla a, 3
	andmi8 (xix), 0xe7
	or (xix), a
	ldcfm 2, (xhl)
	stcfm 2, (xix)
	lda xix, (xbc + 5)
	lda xhl, (xde + 5)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 6)
	lda xhl, (xde + 6)
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ld a, (xhl)
	and a, 0x1f
	andmi8 (xix), 0xe0
	or (xix), a
	lda xix, (xbc + 7)
	lda xhl, (xde + 7)
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ld a, (xhl)
	and a, 0xf
	andmi8 (xix), 0xf0
	or (xix), a
	lda xix, (xbc + 8)
	lda xhl, (xde + 8)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 9)
	lda xhl, (xde + 9)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xbc + 10)
	lda xhl, (xde + 10)
	ldcfm 7, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 7
	andmi8 (xix), 0x7f
	or (xix), a
	ldcfm 6, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 6
	andmi8 (xix), 0xbf
	or (xix), a
	ldcfm 5, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 5
	andmi8 (xix), 0xdf
	or (xix), a
	ldcfm 4, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 4
	andmi8 (xix), 0xef
	or (xix), a
	ldcfm 3, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 3
	andmi8 (xix), 0xf7
	or (xix), a
	ldcfm 2, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 2
	andmi8 (xix), 0xfb
	or (xix), a
	ldcfm 1, (xhl)
	scc8 c, a
	and a, 0x1
	sla a, 1
	andmi8 (xix), 0xfd
	or (xix), a
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xbc, (xbc + 11)
	lda xwa, (xde + 11)
	ldcfm 7, (xwa)
	stcfm 7, (xbc)
	ldcfm 6, (xwa)
	stcfm 6, (xbc)
	ldcfm 5, (xwa)
	stcfm 5, (xbc)
	ldcfm 4, (xwa)
	stcfm 4, (xbc)
	ldcfm 3, (xwa)
	stcfm 3, (xbc)
	ldcfm 2, (xwa)
	stcfm 2, (xbc)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

DataBuf_CopyBulkBitfields_Nop:
	ret

DataBuf_CopyBulkBitfields_Stub:
	; --- Stub (1 byte) ---
	ret
DataBuf_CopyBulkBitfields_944:
	; --- Bit-field + byte copy subroutine 1 (FD38FF-FD3A7B) ---
	ld xde, xwa
	lda xhl, (xbc + 944)
	lda xix, (xde + 1090)
	ldcfm 7, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 7
	andmi8 (xhl), 0x7f
	or (xhl), a
	ldcfm 6, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 6
	andmi8 (xhl), 0xbf
	or (xhl), a
	ldcfm 5, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 5
	andmi8 (xhl), 0xdf
	or (xhl), a
	ldcfm 4, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 4
	andmi8 (xhl), 0xef
	or (xhl), a
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	lda xhl, (xbc + 945)
	lda xix, (xde + 1091)
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	ld	a, (xde+1093)
	ld (xbc + 947), a
	ld	a, (xde+1094)
	ld (xbc + 948), a
	ld	a, (xde+1095)
	ld (xbc + 949), a
	ld	a, (xde+1100)
	ld (xbc + 954), a
	ld	a, (xde+1101)
	ld (xbc + 955), a
	ld	a, (xde+1102)
	ld (xbc + 956), a
	ld	a, (xde+1103)
	ld (xbc + 957), a
	ld	a, (xde+1104)
	ld (xbc + 958), a
	ld	a, (xde+1105)
	ld (xbc + 959), a
	ld	a, (xde+1106)
	ld (xbc + 960), a
	ld	a, (xde+1107)
	ld (xbc + 961), a
	ld	a, (xde+1108)
	ld (xbc + 962), a
	ld	a, (xde+1109)
	ld (xbc + 963), a
	ld	a, (xde+1110)
	ld (xbc + 964), a
	ld	a, (xde+1111)
	ld (xbc + 965), a
	ld	a, (xde+1112)
	ld (xbc + 966), a
	ld	a, (xde+1113)
	ld (xbc + 967), a
	ld	a, (xde+1114)
	ld (xbc + 968), a
	ld	a, (xde+1115)
	ld (xbc + 969), a
	ld	a, (xde+1116)
	ld (xbc + 970), a
	ret
DataBuf_CopyBulkBitfields_960:
	; --- Bit-field + byte copy subroutine 2 (FD3A7C-FD3BF8) ---
	ld xde, xwa
	lda xhl, (xbc + 912)
	lda xix, (xde + 944)
	ldcfm 7, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 7
	andmi8 (xhl), 0x7f
	or (xhl), a
	ldcfm 6, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 6
	andmi8 (xhl), 0xbf
	or (xhl), a
	ldcfm 5, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 5
	andmi8 (xhl), 0xdf
	or (xhl), a
	ldcfm 4, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 4
	andmi8 (xhl), 0xef
	or (xhl), a
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	lda xhl, (xbc + 913)
	lda xix, (xde + 945)
	ldcfm 3, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 3
	andmi8 (xhl), 0xf7
	or (xhl), a
	ldcfm 2, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 2
	andmi8 (xhl), 0xfb
	or (xhl), a
	ldcfm 1, (xix)
	scc8 c, a
	and a, 0x01
	sla a, 1
	andmi8 (xhl), 0xfd
	or (xhl), a
	ldcfm 0, (xix)
	stcfm 0, (xhl)
	ld	a, (xde+947)
	ld (xbc + 915), a
	ld	a, (xde+948)
	ld (xbc + 916), a
	ld	a, (xde+949)
	ld (xbc + 917), a
	ld	a, (xde+954)
	ld (xbc + 922), a
	ld	a, (xde+955)
	ld (xbc + 923), a
	ld	a, (xde+956)
	ld (xbc + 924), a
	ld	a, (xde+957)
	ld (xbc + 925), a
	ld	a, (xde+958)
	ld (xbc + 926), a
	ld	a, (xde+959)
	ld (xbc + 927), a
	ld	a, (xde+960)
	ld (xbc + 928), a
	ld	a, (xde+961)
	ld (xbc + 929), a
	ld	a, (xde+962)
	ld (xbc + 930), a
	ld	a, (xde+963)
	ld (xbc + 931), a
	ld	a, (xde+964)
	ld (xbc + 932), a
	ld	a, (xde+965)
	ld (xbc + 933), a
	ld	a, (xde+966)
	ld (xbc + 934), a
	ld	a, (xde+967)
	ld (xbc + 935), a
	ld	a, (xde+968)
	ld (xbc + 936), a
	ld	a, (xde+969)
	ld (xbc + 937), a
	ld	a, (xde+970)
	ld (xbc + 938), a
	ret


DataBuf_CopyBulkBitfields_F980:
	ld xde, xbc
	lda xix, (xde+944)
	lda xhl, (xwa+944)
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xix), 0x7f
	or (xix), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xix), 0xbf
	or (xix), c
	ldcfm 5, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 5
	andmi8 (xix), 0xdf
	or (xix), c
	ldcfm 4, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 4
	andmi8 (xix), 0xef
	or (xix), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcfm 2, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 1, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 1
	andmi8 (xix), 0xfd
	or (xix), c
	ldcfm 0, (xhl)
	stcfm 0, (xix)
	lda xix, (xde+945)
	lda xhl, (xwa+945)
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcf	2, (xwa+945)
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 1, (xhl)
	stcfm 1, (xix)
	ldcf	0, (xwa+945)
	stcfm 0, (xix)
	ld	c, (xwa+947)
	ld	(xde+947), c
	ld	c, (xwa+948)
	ld	(xde+948), c
	ld	c, (xwa+949)
	ld	(xde+949), c
	ld	c, (xwa+954)
	ld	(xde+954), c
	ld	c, (xwa+955)
	ld	(xde+955), c
	ld	c, (xwa+956)
	ld	(xde+956), c
	ld	c, (xwa+957)
	ld	(xde+957), c
	ld	c, (xwa+958)
	ld	(xde+958), c
	ld	c, (xwa+959)
	ld	(xde+959), c
	ld	c, (xwa+960)
	ld	(xde+960), c
	ld	c, (xwa+961)
	ld	(xde+961), c
	ld	c, (xwa+962)
	ld	(xde+962), c
	ld	c, (xwa+963)
	ld	(xde+963), c
	ld	c, (xwa+964)
	ld	(xde+964), c
	ld	c, (xwa+965)
	ld	(xde+965), c
	ld	c, (xwa+966)
	ld	(xde+966), c
	ld	c, (xwa+967)
	ld	(xde+967), c
	ld	c, (xwa+968)
	ld	(xde+968), c
	ld	c, (xwa+969)
	ld	(xde+969), c
	ld	c, (xwa+970)
	ld	(xde+970), c
	ld	a, (xwa+1047)
	and a, 0x7f
	and	(xde+1047), 0x80
	or	(xde+1047), a
	ret

DataBuf_CopyBulkBitfields_Large:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+6), xbc
	ld	(xsp+10), xwa
	ldw	(xsp+4), 0
DataBuf_CopyBulkBitfields_Large_Loop:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 5
	add	xbc, 1008
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 992
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	DataBuf_CopyVoiceBlock24
	incw	1, (xsp+4)
	cpw	(xsp+4), 2
	jr	c, DataBuf_CopyBulkBitfields_Large_Loop
	ld	xiy, (xsp+6)
	lda	xbc, (xiy+1046)
	ld	xix, (xsp+10)
	ld	a, (xix+1074)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xde, (xiy+1047)
	lda	xwa, (xix+1075)
	ldcfm	7, (xwa)
	stcfm	7, (xde)
	ldcfm	6, (xwa)
	stcfm	6, (xbc)
	ld	a, (xwa)
	and	a, 63
	andmi8	(xde), 128
	or	(xde), a
	ldcfm	7, (xix+1076)
	scc8	c, c
	and	c, 1
	sla	c, 7
	andmi8	(xiy+1048), 127
	or	(xiy+1048), c
	ld	xhl, xiy
	lda	xbc, (xhl+1049)
	lda	xwa, (xix+1077)
	ld	e, (xwa)
	and	e, 112
	andmi8	(xbc), 143
	or	(xbc), e
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	ld	c, (xix+1078)
	res	7, c
	res	7, c
	andmi8	(xhl+1050), 128
	or	(xhl+1050), c
	ld	c, (xix+1079)
	srl	c, 4
	and	c, 15
	sla	c, 4
	andmi8	(xhl+1051), 15
	or	(xhl+1051), c
	ldcfm	0, (xix+1080)
	scc8	c, c
	and	c, 1
	andmi8	(xhl+1052), 254
	or	(xhl+1052), c
	lda	xbc, (xhl+1053)
	lda	xwa, (xix+1081)
	ldcfm	7, (xwa)
	stcfm	7, (xbc)
	ldcfm	6, (xwa)
	stcfm	6, (xbc)
	ldcfm	5, (xwa)
	stcfm	5, (xbc)
	ldcfm	4, (xwa)
	stcfm	4, (xbc)
	ldcfm	3, (xwa)
	stcfm	3, (xbc)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	lda	xbc, (xhl+1054)
	lda	xwa, (xix+1082)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	ld	c, (xix+1083)
	ld	(xhl+1056), c
	ld	c, (xix+1122)
	ld	(xhl+1066), c
	ld	c, (xix+1123)
	ld	(xhl+1067), c
	ld	c, (xix+1124)
	ld	(xhl+1068), c
	lda	xbc, (xhl+1069)
	lda	xwa, (xix+1125)
	ldcfm	2, (xwa)
	stcfm	2, (xbc)
	ldcfm	1, (xwa)
	stcfm	1, (xbc)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	lda	xbc, (xhl+1078)
	lda	xwa, (xix+1138)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1079)
	lda	xwa, (xix+1139)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	ld	c, (xix+1140)
	res	7, c
	res	7, c
	andmi8	(xhl+1080), 128
	or	(xhl+1080), c
	ld	c, (xix+1141)
	res	7, c
	res	7, c
	andmi8	(xhl+1081), 128
	or	(xhl+1081), c
	ld	c, (xix+1142)
	and	c, 15
	and	c, 15
	andmi8	(xhl+1082), 240
	or	(xhl+1082), c
	ld	c, (xix+1143)
	ld	(xhl+1083), c
	ld	c, (xix+1144)
	res	7, c
	res	7, c
	andmi8	(xhl+1084), 128
	or	(xhl+1084), c
	ld	c, (xix+1145)
	ld	(xhl+1085), c
	ld	c, (xix+1146)
	res	7, c
	res	7, c
	andmi8	(xhl+1086), 128
	or	(xhl+1086), c
	lda	xbc, (xhl+1087)
	lda	xwa, (xix+1147)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1088)
	lda	xwa, (xix+1148)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1089)
	lda	xwa, (xix+1149)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1090)
	lda	xwa, (xix+1150)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1091)
	lda	xwa, (xix+1151)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1092)
	lda	xwa, (xix+1152)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1093)
	lda	xwa, (xix+1153)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1094)
	lda	xwa, (xix+1154)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1095)
	lda	xwa, (xix+1155)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1096)
	lda	xwa, (xix+1156)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1097)
	lda	xwa, (xix+1157)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1098)
	lda	xwa, (xix+1158)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1099)
	lda	xwa, (xix+1159)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1100)
	lda	xwa, (xix+1160)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1101)
	lda	xwa, (xix+1161)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1102)
	lda	xwa, (xix+1162)
	ld	e, (xwa)
	and	e, 240
	andmi8	(xbc), 15
	or	(xbc), e
	ld	a, (xwa)
	and	a, 15
	andmi8	(xbc), 240
	or	(xbc), a
	lda	xbc, (xhl+1103)
	lda	xwa, (xix+1163)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1104)
	lda	xwa, (xix+1164)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1105)
	lda	xwa, (xix+1165)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1106)
	lda	xwa, (xix+1166)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1107)
	lda	xwa, (xix+1167)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	lda	xbc, (xhl+1108)
	lda	xwa, (xix+1168)
	ld	e, (xwa)
	and	e, 192
	andmi8	(xbc), 63
	or	(xbc), e
	ld	e, (xwa)
	and	e, 48
	andmi8	(xbc), 207
	or	(xbc), e
	ld	e, (xwa)
	and	e, 12
	andmi8	(xbc), 243
	or	(xbc), e
	ld	a, (xwa)
	and	a, 3
	andmi8	(xbc), 252
	or	(xbc), a
	ld	c, (xix+1638)
	ld	(xhl+1576), c
	ld	xwa, xix
	ld	c, (xwa+1639)
	ld	xde, xhl
	ld	(xde+1577), c
	ld	c, (xwa+1640)
	ld	(xde+1578), c
	ld	c, (xwa+1641)
	ld	(xde+1579), c
	ld	c, (xwa+1642)
	ld	(xde+1580), c
	ld	c, (xwa+1643)
	ld	(xde+1581), c
	ld	c, (xwa+1644)
	ld	(xde+1582), c
	ld	c, (xwa+1645)
	ld	(xde+1583), c
	ld	c, (xwa+1646)
	ld	(xde+1584), c
	ld	c, (xwa+1647)
	ld	(xde+1585), c
	ld	c, (xwa+1648)
	ld	(xde+1586), c
	ld	c, (xwa+1649)
	ld	(xde+1587), c
	ld	c, (xwa+1650)
	ld	(xde+1588), c
	ld	c, (xwa+1651)
	ld	(xde+1589), c
	ld	c, (xwa+1652)
	ld	(xde+1590), c
	ld	c, (xwa+1653)
	ld	(xde+1591), c
	pop	xiz
	lda	xsp, (xsp+10)
	ret
FileData_AllocLoadAndParse_Helper2:
	lda	xsp, (xsp-10)
	push	xiz
	call	PreLswLoad
	calr	DataBuf_Data_FormatDispatch
	lda	xwa, (0xf980:16)
	ld	(xsp+6), xwa
	pushw 1088
	call	Malloc
	inc	2, xsp
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	or	xwa, xwa
	jr	nz, DataBuf_CopyBulkBitfields_Large_Skip
	ldw	hl, 0xff38
	jrl	DataBuf_CopyBulkBitfields_Large_Epilogue
DataBuf_CopyBulkBitfields_Large_Skip:
	ld	xwa, (xsp+10)
	add	xwa, 32
	ld	xbc, 1056
	call	FileIO_ReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	ge, DataBuf_CopyBulkBitfields_Large_Skip2
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	DataBuf_CopyBulkBitfields_Large_Epilogue
DataBuf_CopyBulkBitfields_Large_Skip2:
	ldw	(xsp+4), 0
DataBuf_CopyBulkBitfields_Large_Loop2:
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	add	xbc, 32
	ld	xiz, xbc
	add	xiz, (xsp+10)
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 52
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	VoiceParam_CopyBitfields_TypeA
	incw	1, (xsp+4)
	cpw	(xsp+4), 23
	jr	c, DataBuf_CopyBulkBitfields_Large_Loop2
	ldw	(xsp+4), 0
DataBuf_CopyBulkBitfields_Large_Loop3:
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, DataBuf_CopyBulkBitfields_Large_Data
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 414
	ld	xwa, (xsp+10)
	lda	xiz, (xwa+de)
	ld	xwa, xbc
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 52
	add	xhl, (xsp+6)
	ld	xwa, xiz
	ld	xbc, xhl
	calr	VoiceParam_CopyBitfields_LargeBlock
	incw	1, (xsp+4)
	cpw	(xsp+4), 24
	jr	c, DataBuf_CopyBulkBitfields_Large_Loop3
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+308)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+728)
	calr	VoiceParam_CopyBitfields_TypeB
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+326)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+740)
	calr	VoiceParam_CopyBitfields_TypeC
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+334)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+896)
	calr	VoiceParam_CopyFields_TypeD
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+352)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+938)
	calr	VoiceParam_CopyBits_TwoFlags
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+358)
	ld	xbc, (xsp+6)
	lda	xbc, (xbc+906)
	calr	VoiceParam_CopyFields_TypeE
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DSPCfg_ConfigureVoiceSlotA
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DSPCfg_VoiceSlotB_ExtractData
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+6)
	calr	DataBuf_CopyBulkBitfields_Large_Helper
	ld	wa, 0:i3
	call	PostLswLoad
	ld	xwa, (xsp+10)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, 0:i3
DataBuf_CopyBulkBitfields_Large_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret
FileData_AllocLoadAndParse_Helper3:
	lda	xsp, (xsp-14)
	pushw	iz
	call	PrePmLoad
	ldw	wa, 24
	calr	DataBuf_CopyBulkBitfields_Large_Helper3
	ld	iz, 0:i3
DataBuf_CopyBulkBitfields_Large_Loop4:
	ld	wa, iz
	calr	SndParam_TableDispatch_Memset
	inc	1, iz
	cp	iz, 3:i3
	jr	c, DataBuf_CopyBulkBitfields_Large_Loop4
	pushw 336
	call	Malloc
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	or	xwa, xwa
	jr	nz, DataBuf_CopyBulkBitfields_Large_Skip3
	ldw	hl, 0xff38
	jrl	DataBuf_CopyBulkBitfields_Large_Epilogue2
DataBuf_CopyBulkBitfields_Large_Skip3:
	ldw	(xsp+6), 0
DataBuf_CopyBulkBitfields_Large_Loop5:
	ld	xwa, (xsp+8)
	ld	xbc, 336
	call	FileIO_ReadBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	ge, DataBuf_CopyBulkBitfields_Large_Skip4
	ld	xwa, (xsp+8)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, iz
	jrl	DataBuf_CopyBulkBitfields_Large_Epilogue2
DataBuf_CopyBulkBitfields_Large_Skip4:
	ld	wa, (xsp+6)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	ld	(xsp+2), xwa
	ld	iz, 0:i3
DataBuf_CopyBulkBitfields_Large_Loop6:
	ld	bc, iz
	extz	xbc
	ld	xwa, xbc
	add	xwa, xwa
	add	xwa, xbc
	sll	xwa, 2
	ld	(xsp+12), xwa
	ld	xwa, (xsp+8)
	add	(xsp+12), xwa
	ld	xwa, xbc
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	add	xhl, (xsp+2)
	ld	xwa, (xsp+12)
	ld	xbc, xhl
	calr	VoiceParam_CopyBitfields_TypeA
	inc	1, iz
	cp	iz, 23
	jr	c, DataBuf_CopyBulkBitfields_Large_Loop6
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+276)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+696)
	calr	VoiceParam_CopyBitfields_TypeB
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+294)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+708)
	calr	VoiceParam_CopyBitfields_TypeC
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+302)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+864)
	calr	VoiceParam_CopyFields_TypeD
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+320)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+906)
	calr	VoiceParam_CopyBits_TwoFlags
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+326)
	ld	xbc, (xsp+2)
	lda	xbc, (xbc+874)
	calr	VoiceParam_CopyFields_TypeE
	ld	xwa, (xsp+8)
	sub	xwa, 32
	ld	xbc, (xsp+2)
	sub	xbc, 32
	calr	DSPCfg_ConfigureVoiceSlotA
	ld	xwa, 0xf980
	ld	xbc, (xsp+2)
	calr	DataBuf_CopyBulkBitfields_Large_Helper2
	incw	1, (xsp+6)
	cpw	(xsp+6), 24
	jrl	c, DataBuf_CopyBulkBitfields_Large_Loop5
	ld	wa, 0:i3
	call	PostPmLoad
	ld	xwa, (xsp+8)
	push	xwa
	call	Free
	inc	4, xsp
	ld	hl, 0:i3
DataBuf_CopyBulkBitfields_Large_Epilogue2:
	popw	iz
	lda	xsp, (xsp+14)
	ret

FileData_LoadAndParseType3:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	pushw 0x800
	call Malloc
	inc 2, xsp
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, FileData_LoadAndParseType3_Continue
	push xwa
	call Free
	inc 4, xsp
	ldw hl, 0xff38
	jrl DataBuf_TransferSlot_Epilogue

FileData_LoadAndParseType3_Continue:
	pushw 0x800
	ld c, (xsp + 20)
	extz bc
	sla bc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	lda	xwa, (xwa+bc)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 6)
	lda xwa, (xwa+256)
	ld (xsp + 10), xwa
	ld a, (xsp + 18)
	extz wa
	inc 1, wa
	calr DataBuf_InitSlotFromPreset
	ld c, (xsp + 18)
	extz bc
	sla bc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	lda	xwa, (xwa+bc)
	ld (xsp + 14), xwa
	ld xwa, 0x2e0
	add (xsp + 14), xwa
	ldw (xsp + 4), 0x0

FileData_LoadAndParseType3_Error:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, 0x20
	ld xiz, xbc
	add xiz, (xsp + 10)
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	add xhl, 0x34
	add xhl, (xsp + 14)
	ld xwa, xiz
	ld xbc, xhl
	calr VoiceParam_CopyBitfields_TypeA
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x18
	jr c, FileData_LoadAndParseType3_Error
	ld xwa, (xsp + 10)
	lda xwa, (xwa+308)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+728)
	calr VoiceParam_CopyBitfields_TypeB
	ld xwa, (xsp + 10)
	lda xwa, (xwa+326)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+740)
	calr VoiceParam_CopyBitfields_TypeC
	ld xwa, (xsp + 10)
	lda xwa, (xwa+334)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+896)
	calr VoiceParam_CopyFields_TypeD
	ld xwa, (xsp + 10)
	lda xwa, (xwa+352)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+938)
	calr VoiceParam_CopyBits_TwoFlags
	ld xwa, (xsp + 10)
	lda xwa, (xwa+358)
	ld xbc, (xsp + 14)
	lda xbc, (xbc+906)
	calr VoiceParam_CopyFields_TypeE
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	calr DSPCfg_ConfigureVoiceSlotA
	ld xwa, 0xf980
	ld xbc, (xsp + 14)
	calr DataBuf_TransferSlotBitfields
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 4, xsp
	ld hl, 0:i3

DataBuf_TransferSlot_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

VoiceParam_CopyBitfields_TypeA:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xix, (xwa + 6)
	ld c, (xix)
	and c, 0xf
	andmi8 (xde + 3), 0x80
	or (xde + 3), c
	ld c, (xwa + 3)
	and c, 0x7f
	andmi8 (xde + 5), 0x80
	or (xde + 5), c
	lda xiy, (xde + 6)
	lda xhl, (xwa + 4)
	ldcfm 7, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 7
	andmi8 (xiy), 0x7f
	or (xiy), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xiy), 0xbf
	or (xiy), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xiy), 0xf7
	or (xiy), c
	ld c, (xhl)
	and c, 0x7
	and c, 0x7
	andmi8 (xiy), 0xf8
	or (xiy), c
	lda xbc, (xde + 7)
	bitm 5, (xhl)
	jr z, VoiceParam_CopyBitfields_TypeA_NoBit5
	ld l, (xbc)
	and l, 0x80
	or l, 0x50
	ld (xbc), l
	jr VoiceParam_CopyBitfields_TypeA_Cont

VoiceParam_CopyBitfields_TypeA_NoBit5:
	andmi8 (xbc), 0x80

VoiceParam_CopyBitfields_TypeA_Cont:
	lda xhl, (xde + 9)
	bitm 7, (xwa + 5)
	jr z, VoiceParam_CopyBitfields_TypeA_NoHigh
	ld c, (xhl)
	and c, 0x80
	or c, 0x5a
	ld (xhl), c
	jr VoiceParam_CopyBitfields_TypeA_Final

VoiceParam_CopyBitfields_TypeA_NoHigh:
	andmi8 (xhl), 0x80

VoiceParam_CopyBitfields_TypeA_Final:
	ldcfm 5, (xwa + 9)
	stcfm 5, (xde + 14)
	lda xiy, (xde + 16)
	lda xhl, (xwa + 8)
	ld c, (xhl)
	res 7, c
	res 7, c
	andmi8 (xiy), 0x80
	or (xiy), c
	ldcfm 7, (xhl)
	stcfm 7, (xiy)
	ld a, (xwa + 11)
	ld (xde + 17), a
	lda xwa, (xde + 15)
	ldcfm 6, (xix)
	stcfm 6, (xwa)
	ldcfm 5, (xix)
	stcfm 5, (xwa)
	ret

VoiceParam_CopyBitfields_TypeB:
	ld xde, xbc
	ld c, (xwa + 2)
	ld (xde + 2), c
	lda xiy, (xwa + 12)
	ld c, (xiy)
	and c, 0xf
	andmi8 (xde + 3), 0x80
	or (xde + 3), c
	lda xix, (xde + 5)
	lda xhl, (xwa + 4)
	ld c, (xhl)
	and c, 0x3
	and c, 0x7
	andmi8 (xix), 0xf8
	or (xix), c
	ldcfm 2, (xhl)
	stcfm 3, (xix)
	lda xix, (xde + 6)
	lda xhl, (xwa + 6)
	ld c, (xhl)
	and c, 0x3
	and c, 0x7
	andmi8 (xix), 0xf8
	or (xix), c
	ldcfm 6, (xhl)
	stcfm 6, (xix)
	lda xix, (xde + 7)
	lda xhl, (xwa + 7)
	ldcfm 0, (xhl)
	scc8 c, c
	and c, 0x1
	andmi8 (xix), 0xfe
	or (xix), c
	ldcfm 1, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 1
	andmi8 (xix), 0xfd
	or (xix), c
	ldcfm 2, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 2
	andmi8 (xix), 0xfb
	or (xix), c
	ldcfm 3, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 3
	andmi8 (xix), 0xf7
	or (xix), c
	ldcfm 4, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 4
	andmi8 (xix), 0xef
	or (xix), c
	ldcfm 5, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 5
	andmi8 (xix), 0xdf
	or (xix), c
	ldcfm 6, (xhl)
	scc8 c, c
	and c, 0x1
	sla c, 6
	andmi8 (xix), 0xbf
	or (xix), c
	ldcfm 7, (xhl)
	stcfm 7, (xix)
	lda xbc, (xde + 9)
	bitm 4, (xiy)
	jr z, VoiceParam_CopyBitfields_TypeB_NoBit4
	ld l, (xbc)
	and l, 0xcf
	set 5, l
	ld (xbc), l
	jr VoiceParam_CopyBitfields_TypeB_Cont

VoiceParam_CopyBitfields_TypeB_NoBit4:
	andmi8 (xbc), 0xcf

VoiceParam_CopyBitfields_TypeB_Cont:
	ldcfm 0, (xwa + 15)
	scc8 c, h
	lda xbc, (xwa + 14)
	ld l, (xbc)
	ld a, l
	add a, l
	add a, h
	ld (xde + 10), a
	ld a, (xbc)
	srl a, 7
	and a, 0x1
	and a, 0x1
	andmi8 (xde + 11), 0xfe
	or (xde + 11), a
	ret

VoiceParam_CopyBitfields_TypeC:
	ld xde, xbc
	lda xix, (xde + 2)
	lda xhl, (xwa + 2)
	ldcfm 0, (xhl)
	scc8 c, c
	and c, 0x1
	andmi8 (xix), 0xfe
	or (xix), c
	ldcfm 1, (xhl)
	stcfm 1, (xix)
	ldcfm 1, (xwa + 3)
	stcfm 1, (xde + 3)
	lda xbc, (xde + 5)
	inc 7, xwa
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ret

VoiceParam_CopyFields_TypeD:
	ld e, (xwa + 2)
	and e, 0x3
	andmi8 (xbc + 2), 0xfc
	or (xbc + 2), e
	ld e, (xwa + 3)
	ld (xbc + 4), e
	ld e, (xwa + 5)
	and e, 0xf
	andmi8 (xbc + 6), 0xf0
	or (xbc + 6), e
	ld a, (xwa + 17)
	res 7, a
	andmi8 (xbc + 3), 0x80
	or (xbc + 3), a
	ret

VoiceParam_CopyBits_TwoFlags:
	inc 2, xbc
	inc 2, xwa
	ldcfm 1, (xwa)
	stcfm 1, (xbc)
	ldcfm 0, (xwa)
	stcfm 0, (xbc)
	ret

VoiceParam_CopyFields_TypeE:
	ld e, (xwa + 2)
	and e, 0x7f
	andmi8 (xbc + 10), 0x80
	or (xbc + 10), e
	ld e, (xwa + 3)
	and e, 0x7f
	andmi8 (xbc + 11), 0x80
	or (xbc + 11), e
	ld e, (xwa + 4)
	and e, 0x7f
	andmi8 (xbc + 12), 0x80
	or (xbc + 12), e
	ld e, (xwa + 5)
	ld (xbc + 2), e
	ld e, (xwa + 6)
	and e, 0x7f
	andmi8 (xbc + 5), 0x80
	or (xbc + 5), e
	ldcfm 6, (xwa + 7)
	stcfm 6, (xbc + 6)
	ret

VoiceParam_CopyBitfields_LargeBlock:
	lda	xde, (xbc+15)
	ld	l, (xwa)
	and	l, 15
	andmi8	(xde), 240
	or	(xde), l
	ldcfm	5, (xwa)
	stcfm	5, (xde)
	ldcfm	6, (xwa)
	stcfm	6, (xde)
	ldcfm	6, (xwa)
	stcfm	7, (xde)
	ld	a, (xwa+1)
	and	a, 7
	andmi8	(xbc+14), 248
	or	(xbc+14), a
	ret
	ld	xde, xwa
	lda	xix, (xbc+2)
	lda	xhl, (xde+2)
	ld	a, (xhl)
	and	a, 3
	and	a, 3
	andmi8	(xix), 252
	or	(xix), a
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ldcfm	3, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 3
	andmi8	(xix), 247
	or	(xix), a
	ldcfm	4, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 4
	andmi8	(xix), 239
	or	(xix), a
	ldcfm	5, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 5
	andmi8	(xix), 223
	or	(xix), a
	ldcfm	6, (xhl)
	stcfm	6, (xix)
	ldcfm	3, (xde+3)
	stcfm	3, (xbc+3)
	lda	xix, (xbc+4)
	lda	xhl, (xde+4)
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ld	a, (xhl)
	and	a, 24
	andmi8	(xix), 231
	or	(xix), a
	lda	xix, (xbc+5)
	lda	xhl, (xde+5)
	ldcfm	0, (xhl)
	scc	c, a
	and	a, 1
	andmi8	(xix), 254
	or	(xix), a
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ldcfm	6, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 6
	andmi8	(xix), 191
	or	(xix), a
	ldcfm	7, (xhl)
	stcfm	7, (xix)
	lda	xix, (xbc+7)
	lda	xhl, (xde+7)
	ld	a, (xhl)
	and	a, 15
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	ldcfm	4, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 4
	andmi8	(xix), 239
	or	(xix), a
	ldcfm	5, (xhl)
	stcfm	5, (xix)
	lda	xix, (xbc+8)
	lda	xhl, (xde+8)
	ldcfm	0, (xhl)
	scc	c, a
	and	a, 1
	andmi8	(xix), 254
	or	(xix), a
	ldcfm	1, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 1
	andmi8	(xix), 253
	or	(xix), a
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ldcfm	3, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 3
	andmi8	(xix), 247
	or	(xix), a
	ldcfm	4, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 4
	andmi8	(xix), 239
	or	(xix), a
	ldcfm	5, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 5
	andmi8	(xix), 223
	or	(xix), a
	ldcfm	6, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 6
	andmi8	(xix), 191
	or	(xix), a
	ldcfm	7, (xhl)
	stcfm	7, (xix)
	lda	xix, (xbc+9)
	lda	xhl, (xde+9)
	ldcfm	0, (xhl)
	scc	c, a
	and	a, 1
	andmi8	(xix), 254
	or	(xix), a
	ldcfm	1, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 1
	andmi8	(xix), 253
	or	(xix), a
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ldcfm	3, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 3
	andmi8	(xix), 247
	or	(xix), a
	ldcfm	4, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 4
	andmi8	(xix), 239
	or	(xix), a
	ldcfm	5, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 5
	andmi8	(xix), 223
	or	(xix), a
	ldcfm	6, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 6
	andmi8	(xix), 191
	or	(xix), a
	ldcfm	7, (xhl)
	stcfm	7, (xix)
	lda	xix, (xbc+10)
	lda	xhl, (xde+10)
	ldcfm	0, (xhl)
	scc	c, a
	and	a, 1
	andmi8	(xix), 254
	or	(xix), a
	ldcfm	1, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 1
	andmi8	(xix), 253
	or	(xix), a
	ldcfm	2, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 2
	andmi8	(xix), 251
	or	(xix), a
	ldcfm	3, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 3
	andmi8	(xix), 247
	or	(xix), a
	ldcfm	4, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 4
	andmi8	(xix), 239
	or	(xix), a
	ldcfm	5, (xhl)
	scc	c, a
	and	a, 1
	sla	a, 5
	andmi8	(xix), 223
	or	(xix), a
	ldcfm	7, (xhl)
	stcfm	7, (xix)
	lda	xbc, (xbc+11)
	lda	xwa, (xde+11)
	ldcfm	0, (xwa)
	stcfm	0, (xbc)
	ldcfm	5, (xwa)
	stcfm	5, (xbc)
	ldcfm	6, (xwa)
	stcfm	6, (xbc)
	ret

DSPCfg_ConfigureVoiceSlotA:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ldcf	7, (xwa+339)
	scc8 c, c
	ld xde, (xsp + 6)
	and c, 0x1
	sla c, 7
	and	(xde+751), 0x7f
	or	(xde+751), c
	ld	a, (xwa+341)
	and a, 0xf
	extz wa
	lda xbc, (DSPCfg_ConfigureVoiceSlotA_Data:24)
	ld	c, (xbc+wa)
	extz bc
	lda xde, (xde+756)
	ld xwa, 0x4900
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jr lt, DSPCfg_ConfigureVoiceSlotB
	ld xbc, (xsp + 6)
	ld	a, (xbc+755)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc+757)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc74:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld	a, (xwa+756)
	ld (xbc), a
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DSPCfg_VoiceSlotA_RestoreContext
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DSPCfg_VoiceSlotA_RestoreContext

DSPCfg_VoiceSlotA_ParamLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	lda xde, (xde+756)
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DSPCfg_VoiceSlotA_ParamLoop

DSPCfg_VoiceSlotA_RestoreContext:
	ld a, (xsp + 4)
	ld (0xfc74:16), a

DSPCfg_ConfigureVoiceSlotB:
	ld xwa, (xsp + 10)
	ld	a, (xwa+338)
	srl a, 4
	extz wa
	lda xbc, (DSPCfg_ConfigureVoiceSlotB_Data:24)
	ld	c, (xbc+wa)
	extz bc
	ld xwa, (xsp + 6)
	lda xde, (xwa+782)
	ld xwa, 0x4b00
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jrl lt, DSPCfg_VoiceSlotB_Epilog
	ld xbc, (xsp + 6)
	ld	a, (xbc+781)
	dec 1, a
	extz wa
	pushw wa
	pushw 0x0
	lda xwa, (xbc+783)
	push xwa
	call Memset
	inc 8, xsp
	lda xbc, (0xfc8e:16)
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld	a, (xwa+782)
	ld (xbc), a
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DSPCfg_VoiceSlotB_RestorePort
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DSPCfg_VoiceSlotB_RestorePort

DSPCfg_VoiceSlotB_ParamLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ResolveAndExtract
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	cp hl, 1:i3
	jr z, DSPCfg_VoiceSlotB_MapAndWrite
	cp hl, 2:i3
	jr nz, DSPCfg_VoiceSlotB_ReadAndWrite

DSPCfg_VoiceSlotB_MapAndWrite:
	ld xbc, (xsp + 10)
	ld	c, (xbc+338)
	and c, 0xf
	srl c, 1
	extz bc
	lda xde, (DSPCfg_VoiceSlotB_MapAndWrite_Data:24)
	ld	c, (xde+bc)
	extz bc
	ld xde, (xsp + 6)
	lda xde, (xde+782)
	jr DSPCfg_VoiceSlotB_WriteAndLoop

DSPCfg_VoiceSlotB_ReadAndWrite:
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	lda xde, (xde+782)

DSPCfg_VoiceSlotB_WriteAndLoop:
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DSPCfg_VoiceSlotB_ParamLoop

DSPCfg_VoiceSlotB_RestorePort:
	ld a, (xsp + 4)
	ld (0xfc8e:16), a

DSPCfg_VoiceSlotB_Epilog:
	pop xiz
	lda xsp, (xsp + 10)
	ret

DSPCfg_VoiceSlotB_ExtractData:
	ld	xde, xwa
	lda	xhl, (xde+373)
	ld	a, (xhl)
	and	a, 7
	jr	z, DSPCfg_VoiceSlotB_ExtractData_Skip2
	ld	a, (xhl)
	sll	a, 4
	and	a, 48
	andmi8	(xbc+737), 207
	or	(xbc+737), a
DSPCfg_VoiceSlotB_ExtractData_Skip2:
	lda	xwa, (xde+1006)
	ld	xhl, xwa
	lda	xix, (xbc+64)
	lda	xiy, (xwa+16)
DSPCfg_VoiceSlotB_ExtractData_Loop:
	ld	a, (xhl-36)
	res	7, a
	andmi8	(xix-2), 128
	or	(xix-2), a
	ld	a, (xhl-18)
	res	7, a
	andmi8	(xix+1), 128
	or	(xix+1), a
	ld	a, (xhl+18)
	res	7, a
	andmi8	(xix-1), 128
	or	(xix-1), a
	ld	a, (xhl+)
	ld	(xix), a
	lda	xix, (xix+26)
	cp	xhl, xiy
	jr	c, DSPCfg_VoiceSlotB_ExtractData_Loop
	ld	a, (xde+389)
	extz	wa
	lda	xhl, (DSPCfg_VoiceSlotB_ExtractData_Data:24)
	ld	a, (xhl+wa)
	ld	(xbc+948), a
	ld	a, (xde+390)
	extz	wa
	ld	a, (xhl+wa)
	ld	(xbc+949), a
	ld	a, (xde+394)
	extz	wa
	ld	a, (xhl+wa)
	ld	(xbc+970), a
	ld	a, (xde+395)
	extz	wa
	ld	a, (xhl+wa)
	ld	(xbc+969), a
	ret
DataBuf_CopyBulkBitfields_Large_Helper:
	ld	xde, xwa
	lda	xwa, (xde+371)
	ld	l, (xwa)
	and	l, 31
	andmi8	(xbc+1047), 128
	or	(xbc+1047), l
	ldcfm	6, (xwa)
	stcfm	6, (xbc+1046)
	lda	xix, (xbc+1049)
	lda	xhl, (xde+373)
	ld	a, (xhl)
	and	a, 112
	srl	a, 4
	and	a, 7
	sla	a, 4
	andmi8	(xix), 143
	or	(xix), a
	ld	a, (xhl)
	and	a, 7
	jr	z, DSPCfg_VoiceSlotB_ExtractData_Skip
	setm	0, (xix)
DSPCfg_VoiceSlotB_ExtractData_Skip:
	ld	a, (xde+374)
	and	a, 127
	andmi8	(xbc+1050), 128
	or	(xbc+1050), a
	ld	a, (xde+512)
	ld	(xbc+1066), a
	ld	a, (xde+513)
	ld	(xbc+1068), a
	ld	a, (xde+526)
	and	a, 15
	andmi8	(xbc+1078), 240
	or	(xbc+1078), a
	ld	a, (xde+528)
	and	a, 15
	andmi8	(xbc+1082), 240
	or	(xbc+1082), a
	ld	a, (xde+516)
	and	a, 15
	andmi8	(xbc+1087), 240
	or	(xbc+1087), a
	lda	xix, (xbc+1088)
	lda	xhl, (xde+517)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1089)
	lda	xhl, (xde+518)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1090)
	lda	xhl, (xde+519)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1091)
	lda	xhl, (xde+520)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1092)
	lda	xhl, (xde+521)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1093)
	lda	xhl, (xde+522)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1094)
	lda	xhl, (xde+523)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1095)
	lda	xhl, (xde+524)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1096)
	lda	xhl, (xde+525)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1097)
	lda	xhl, (xde+529)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1098)
	lda	xhl, (xde+530)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1099)
	lda	xhl, (xde+531)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1100)
	lda	xhl, (xde+532)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1101)
	lda	xhl, (xde+533)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	lda	xix, (xbc+1102)
	lda	xhl, (xde+534)
	ld	a, (xhl)
	srl	a, 4
	and	a, 15
	sla	a, 4
	andmi8	(xix), 15
	or	(xix), a
	ld	a, (xhl)
	and	a, 15
	andmi8	(xix), 240
	or	(xix), a
	ldcfm	7, (xde+407)
	stcfm	2, (xbc+1069)
	ld	a, (xde+1056)
	ld	(xbc+1576), a
	ld	a, (xde+1057)
	ld	(xbc+1577), a
	ld	a, (xde+1058)
	ld	(xbc+1578), a
	ld	a, (xde+1059)
	ld	(xbc+1579), a
	ld	a, (xde+1060)
	ld	(xbc+1580), a
	ld	a, (xde+1061)
	ld	(xbc+1581), a
	ld	a, (xde+1062)
	ld	(xbc+1582), a
	ld	a, (xde+1063)
	ld	(xbc+1583), a
	ld	a, (xde+1064)
	ld	(xbc+1584), a
	ld	a, (xde+1065)
	ld	(xbc+1585), a
	ld	a, (xde+1066)
	ld	(xbc+1586), a
	ld	a, (xde+1067)
	ld	(xbc+1587), a
	ld	a, (xde+1068)
	ld	(xbc+1588), a
	ld	a, (xde+1069)
	ld	(xbc+1589), a
	ld	a, (xde+1070)
	ld	(xbc+1590), a
	ld	a, (xde+1071)
	ld	(xbc+1591), a
	ret
DataBuf_CopyBulkBitfields_Large_Helper2:
	ld	e, (xwa+737)
	and	e, 48
	andmi8	(xbc+705), 207
	or	(xbc+705), e
	lda	xde, (xwa+64)
	ld	xwa, xde
	lda	xbc, (xbc+32)
	lda	xde, (xde+416)
DataBuf_CopyBulkBitfields_Large_Helper2_Loop:
	ld	l, (xwa-2)
	and	l, 127
	andmi8	(xbc-2), 128
	or	(xbc-2), l
	ld	l, (xwa+1)
	and	l, 127
	andmi8	(xbc+1), 128
	or	(xbc+1), l
	ld	l, (xwa-1)
	and	l, 127
	andmi8	(xbc-1), 128
	or	(xbc-1), l
	ld	l, (xwa)
	ld	(xbc), l
	lda	xbc, (xbc+26)
	lda	xwa, (xwa+26)
	cp	xwa, xde
	jr	c, DataBuf_CopyBulkBitfields_Large_Helper2_Loop
	ret

DataBuf_TransferSlotBitfields:
	ld xde, xbc
	ld	c, (xwa+737)
	and c, 0x30
	and	(xde+737), 0xcf
	or	(xde+737), c
	lda xbc, (xwa + 64)
	ld xhl, xbc
	lda xix, (xde + 64)
	lda xiy, (xbc+416)

DataBuf_TransferSlotBitfields_Loop:
	ld c, (xhl - 2)
	res 7, c
	res 7, c
	andmi8 (xix - 2), 0x80
	or (xix - 2), c
	ld c, (xhl + 1)
	res 7, c
	res 7, c
	andmi8 (xix + 1), 0x80
	or (xix + 1), c
	ld c, (xhl - 1)
	res 7, c
	res 7, c
	andmi8 (xix - 1), 0x80
	or (xix - 1), c
	ld c, (xhl)
	ld (xix), c
	lda xix, (xix + 26)
	lda xhl, (xhl + 26)
	cp xhl, xiy
	jr c, DataBuf_TransferSlotBitfields_Loop
	ld	a, (xwa+1047)
	and a, 0x7f
	and	(xde+1047), 0x80
	or	(xde+1047), a
	ret

DataBuf_CheckFormatPair:
	; --- Multi-branch lookup: C=(XWA+4), check pairs, return HL=1/2/3/0xffff (52 bytes) ---
	ld c, (xwa+4)
	inc 5, xwa
	cp c, 0x4d
	jr nz, DataBuf_CheckFormatPair_NotM34
	ld e, (xwa)
	cp e, 0x34
	jr nz, DataBuf_CheckFormatPair_NotM34
	ld	hl, 1:i3
	ret
DataBuf_CheckFormatPair_NotM34:
	ld a, (xwa)
	cp c, 0x4d
	jr nz, DataBuf_CheckFormatPair_NotM36
	cp a, 0x36
	jr nz, DataBuf_CheckFormatPair_NotM36
	ld	hl, 2:i3
	ret
DataBuf_CheckFormatPair_NotM36:
	cp c, 0x4e
	jr nz, DataBuf_CheckFormatPair_NotN4E
	cp a, 0x4e
	jr nz, DataBuf_CheckFormatPair_NotN4E
	ld	hl, 3:i3
	ret
DataBuf_CheckFormatPair_NotN4E:
	ldw hl, 0xffff
	ret


DataBuf_CheckSubFormat:
	lda xbc, (xwa + 6)
	ld a, (xwa + 5)
	cp a, 1:i3
	jr nz, DataBuf_CheckSubFormat_Not6
	cp (xbc), 0x6
	jr nz, DataBuf_CheckSubFormat_Not6
	ld hl, 1:i3
	ret

DataBuf_CheckSubFormat_Not6:
	cp a, 1:i3
	jr nz, DataBuf_CheckSubFormat_Not7
	cp (xbc), 0x7
	jr nz, DataBuf_CheckSubFormat_Not7
	ld hl, 2:i3
	ret

DataBuf_CheckSubFormat_Not7:
	cp a, 1:i3
	jr nz, DataBuf_CheckSubFormat_Not3
	cp (xbc), 0x3
	jr nz, DataBuf_CheckSubFormat_Not3
	ld hl, 3:i3
	ret

DataBuf_CheckSubFormat_Not3:
	ldw hl, 0xffff
	ret

DataBuf_Data_FormatDispatch:
	lda	xsp, (xsp-28)
	pushw	4
	pushw	0
	pushw	0xfc54
	lda	xwa, (xsp+30)
	push	xwa
	call	Mem_Copy
	pushw	24
	pushw	0
	pushw	0xfcdc
	lda	xwa, (xsp+16)
	push	xwa
	call	Mem_Copy
	lda	xwa, (0xf9a0:16)
	pushw	1568
	pushw	SndParamRam_DefaultImage@hi16
	pushw	SndParamRam_DefaultImage@lo16
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+30)
	pushw	4
	lda	xwa, (xsp+26)
	push	xwa
	pushw	0
	pushw	0xfc54
	call	Mem_Copy
	pushw	24
	lda	xwa, (xsp+12)
	push	xwa
	pushw	0
	pushw	0xfcdc
	call	Mem_Copy
	lda	xsp, (xsp+48)
	ret
DataBuf_CopyBulkBitfields_Large_Helper3:
	dec	6, xsp
	pushw	iz
	ld	(xsp+6), wa
	lda	xwa, (SndParamRam_DefaultImage:24)
	ld	(xsp+2), xwa
	ld	iz, 0:i3
	cpw	(xsp+6), 0
	jr	ule, DataBuf_CopyBulkBitfields_Large_Helper3_Epilogue
DataBuf_Data_FormatDispatch_Loop:
	ld	wa, iz
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xde, 0x1ed400
	add	xde, xbc
	pushw	960
	ld	xwa, (xsp+4)
	push	xwa
	push	xde
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc	1, iz
	cp	iz, (xsp+6)
	jr	c, DataBuf_Data_FormatDispatch_Loop
DataBuf_CopyBulkBitfields_Large_Helper3_Epilogue:
	popw	iz
	inc	6, xsp
	ret

DataBuf_InitSlotFromPreset:
	pushw iz
	ld iz, wa
	lda xwa, (DataSlot_HeaderTemplate:24)
	cp iz, 0:i3
	jr nz, DataBuf_InitSlotFromPreset_Alt
	lda xbc, (0x00f180:24)
	add xbc, 0x2e0
	pushw 0x20
	push xwa
	push xbc
	call Mem_Copy
	lda xbc, (0x00f180:24)
	add xbc, 0x300
	lda xwa, (0xfda2:16)
	sub xwa, 0xf9a0
	pushw wa
	pushw SndParamRam_DefaultImage@hi16
	pushw SndParamRam_DefaultImage@lo16
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)
	jr SndParam_PopIzRet

DataBuf_InitSlotFromPreset_Alt:
	ld bc, iz
	dec 1, bc
	extz xbc
	sll xbc, 11
	ld xde, SEQ_SONG_SLOTS
	add xde, xbc
	add xde, 0x2e0
	pushw 0x20
	push xwa
	push xde
	call Mem_Copy
	ld wa, iz
	dec 1, wa
	extz xwa
	sll xwa, 11
	ld xbc, SEQ_SONG_SLOTS
	add xbc, xwa
	add xbc, 0x300
	lda xwa, (0xfda2:16)
	sub xwa, 0xf9a0
	pushw wa
	pushw SndParamRam_DefaultImage@hi16
	pushw SndParamRam_DefaultImage@lo16
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)

SndParam_PopIzRet:
	popw iz
	ret

SndParam_SaturationClamp:
	; --- Routine 1: saturation clamp C = max(0, C-0x7f+A), return L (22 bytes) ---
	cp	a, 0:i3
	jr z, SndParam_SaturationClamp_Zero
	cp	c, 0:i3
	jr z, SndParam_SaturationClamp_Zero
	sub c, 0x7f
	add	c, a
	ld l, c
	cp	l, 0:i3
	ret ge
SndParam_SaturationClamp_Zero:
	ld l, 0x00:opc
	ret
SndParam_TableDispatch_Memset:
	; --- Routine 2: table dispatch via 0x1ed360 + WA*16 (32 bytes) ---
	cp wa, 0x0009
	ret ugt
	lda	xbc, (0x1ed360:24)
	sll	wa, 4
	extz xwa
	add xbc, xwa
	pushw	16
	pushw	32
	push xbc
	call Memset
	inc 8, xsp
	ret


SndParam_ApplyAndSync:
	pushw_erp 0xfa
	ld a, (0xb7ec:16)
	bit 7, a
	jr z, SndParam_CheckBit6
	ld (0xb7f0:16), 1
	jr SndParam_ReadAndApply

SndParam_CheckBit6:
	bit 6, a
	jr z, SndParam_SetMode2
	ld (0xb7f0:16), 0
	jr SndParam_ReadAndApply

SndParam_SetMode2:
	ld (0xb7f0:16), 2

SndParam_ReadAndApply:
	ld a, (0xb7ec:16)
	and a, 0x3f
	ldfr_berp A, 0xfb
	ld (0xb7ec:16), a
	cp (0xb7f0:16), 0
	jr nz, SndParam_CheckRangeForDisplay
	ld xwa, 0xc0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldto_berp A, 0xfb
	ld (0xb7ec:16), a
	ld (0xb7f0:16), a

SndParam_CheckRangeForDisplay:
	ld a, (0xb7ec:16)
	cp a, 0x19
	jr c, SndParam_CallDisplaySync
	cp a, 0x1b
	jr c, SoundParam_UpdateCleanupRet
	cp a, 0x1d
	jr ugt, SoundParam_UpdateCleanupRet

SndParam_CallDisplaySync:
	cp a, 0:i3
	jr z, SndParam_ApplyAllBlocks
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde

SndParam_ApplyAllBlocks:
	ld a, (0xb7ec:16)
	extz wa
	calr SndParam_ApplyBaseBlock
	ld a, (0xb7ec:16)
	extz wa
	calr SndParam_ApplyMaskBlock
	ld a, (0xb7ec:16)
	extz wa
	calr SndParam_ApplyModeSpecific
	bit 0, (0xb7ee:16)
	jr nz, SoundParam_UpdateCleanupRet
	ld wa, 3:i3
	call BitMapOut_GetRenderMode_CheckBit3
	push xde
	push xhl
	push xix
	push xiz
	call SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitBothBanks
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

SoundParam_UpdateCleanupRet:
	popw_erp 0xfa
	ret

SndParam_ApplyMaskBlock:
	extz wa
	calr SndParam_GetBlockPointer
	or xhl, xhl
	ret z
	lda xwa, (xhl+138:16)
	ld xbc, xwa
	lda xde, (xwa + 96)

SndParam_ApplyMaskBlock_Loop:
	ld xhl, xbc
	ld xix, (xbc)
	or xix, xix
	jr z, SndParam_ApplyMaskBlock_Next
	ld a, (xhl + 4)
	cpl a
	and a, (xix)
	ld w, a
	ld a, (xhl + 5)
	or a, w
	ld (xix), a

SndParam_ApplyMaskBlock_Next:
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_ApplyMaskBlock_Loop
	ret

SndParam_ApplyBaseBlock:
	extz wa
	calr SndParam_GetBlockPointer
	or xhl, xhl
	ret z
	ld xbc, xhl
	lda xde, (xhl+138:16)

SndParam_ApplyBaseBlock_Loop:
	ld xhl, xbc
	ld xix, (xbc)
	or xix, xix
	jr z, SndParam_ApplyBaseBlock_Next
	ld a, (xix)
	and a, 0xf8
	or a, (xhl + 4)
	ld (xix+), a
	ld a, (xhl + 5)
	ld (xix), a

SndParam_ApplyBaseBlock_Next:
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_ApplyBaseBlock_Loop
	ret

SndParam_ApplyModeSpecific:
	ld c, (0xb7f0:16)
	cp c, 2:i3
	ret z
	lda xwa, (0xfdad:16)
	cp c, 0:i3
	jr z, SndParam_ClearBits
	cp c, 1:i3
	ret nz
	ld c, (xwa)
	and c, 0xf8
	ld (xwa), c
	set 2, c
	ld (xwa), c
	ret

SndParam_ClearBits:
	andmi8 (xwa), 0xf8
	ret

SndParam_AllocAndCopyPreset:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	pushw 0xea
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jrl z, SoundData_FreeSoundPtr
	cp (xsp + 4), 0x3
	jrl nc, SoundData_FreeSoundPtr
	pushw 0xea
	pushw SndParam_AllocAndCopyPreset_Data@hi16
	pushw SndParam_AllocAndCopyPreset_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xwa, (xiz + 5)
	ld xbc, xwa
	lda xde, (xwa+138:16)

SndParam_CopyPreset_FillLoop:
	ld xhl, (xbc - 5)
	ld A, (xhl+)
	and a, 0x7
	ld (xbc - 1), a
	ld a, (xhl)
	ld (xbc), a
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_CopyPreset_FillLoop
	lda xwa, (xiz+143:16)
	ld xbc, xwa
	lda xde, (xwa + 96)

SndParam_CopyPreset_MaskLoop:
	ld xhl, (xbc - 5)
	ld a, (xbc - 1)
	and a, (xhl)
	ld (xbc), a
	inc 6, xbc
	cp xbc, xde
	jr c, SndParam_CopyPreset_MaskLoop
	call MainMpst_ReadPresetIndex
	cp l, 0:i3
	jr nz, SndParam_CopyPreset_SelectBank
	ld xwa, 0:i3
	ld	(xiz+216), xwa

SndParam_CopyPreset_SelectBank:
	cp (xsp + 4), 0x2
	jr z, SndParam_CopyPreset_Bank2
	cp (xsp + 4), 0x1
	jr z, SndParam_CopyPreset_Bank1
	cp (xsp + 4), 0x0
	jr nz, SoundData_FreeSoundPtr
	ld xwa, 0x3d3010
	push xwa
	ld wa, 1:i3
	ld xbc, xiz
	ldw de, 0xea
	jr SndParam_CopyPreset_CallFlash

SndParam_CopyPreset_Bank1:
	ld xwa, 0x3d3110
	push xwa
	ld wa, 1:i3
	ld xbc, xiz
	ldw de, 0xea
	jr SndParam_CopyPreset_CallFlash

SndParam_CopyPreset_Bank2:
	ld xwa, 0x3d3210
	push xwa
	ld wa, 1:i3
	ld xbc, xiz
	ldw de, 0xea

SndParam_CopyPreset_CallFlash:
	call FlashWrite

SoundData_FreeSoundPtr:
	push xiz
	call Free
	inc 4, xsp
	pop xiz
	inc 2, xsp
	ret

SndParam_GetBlockPointer:
	cp a, 0x19
	jr nc, SndParam_GetBlockPointer_Extended
	extz wa
	muls wa, 0xea
	lda xbc, (SndParam_AllocAndCopyPreset_Data:24)
	lda	xhl, (xbc+wa)
	ret

SndParam_GetBlockPointer_Extended:
	cp a, 0x1d
	jr z, SndParam_GetBlockPointer_Bank3
	cp a, 0x1c
	jr z, SndParam_GetBlockPointer_Bank2
	cp a, 0x1b
	jr z, SndParam_GetBlockPointer_Bank1
	ld xhl, 0:i3
	ret

SndParam_GetBlockPointer_Bank1:
	ld xhl, 0x3d3010
	ret

SndParam_GetBlockPointer_Bank2:
	ld xhl, 0x3d3110
	ret

SndParam_GetBlockPointer_Bank3:
	ld xhl, 0x3d3210
	ret

SndParam_RelocateAndApply:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	extz bc
	ld wa, bc
	calr SndParam_GetBlockPointer
	or xhl, xhl
	jr z, SndParam_RelocateApply_Epilog
	lda xbc, (xhl+138:16)
	ld xde, xbc
	lda xiy, (xbc + 96)

SndParam_RelocateApply_MaskLoop:
	ld xiz, xde
	ld xix, (xde)
	or xix, xix
	jr z, SndParam_RelocateApply_NextMask
	sub xix, 0xf980
	add xix, (xsp + 4)
	ld a, (xiz + 4)
	cpl a
	and a, (xix)
	ld w, a
	ld a, (xiz + 5)
	or a, w
	ld (xix), a

SndParam_RelocateApply_NextMask:
	inc 6, xde
	cp xde, xiy
	jr c, SndParam_RelocateApply_MaskLoop

SndParam_RelocateApply_BaseLoop:
	ld xde, xhl
	ld xix, (xhl)
	or xix, xix
	jr z, SndParam_RelocateApply_NextBase
	sub xix, 0xf980
	add xix, (xsp + 4)
	ld a, (xix)
	and a, 0xf8
	or a, (xde + 4)
	ld (xix+), a
	ld a, (xde + 5)
	ld (xix), a

SndParam_RelocateApply_NextBase:
	inc 6, xhl
	cp xhl, xbc
	jr c, SndParam_RelocateApply_BaseLoop

SndParam_RelocateApply_Epilog:
	pop xiz
	inc 4, xsp
	ret

SndParam_UpdateChannels:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), c
	cp a, 0xa
	jr nc, SndParam_UpdateAll_Loop
	extz wa
	ld c, (xsp + 2)
	extz bc
	calr SndParam_UpdateSingleChannel
	jr SndParam_UpdateChannels_Done

SndParam_UpdateAll_Loop:
	cp a, 0xa
	jr nz, SndParam_UpdateChannels_Done
	ld iz, 0:i3

SndParam_UpdateAll_Body:
	ldto_berp A, 0xf8
	extz wa
	ld c, (xsp + 2)
	extz bc
	calr SndParam_UpdateSingleChannel
	inc 1, iz
	cp iz, 0xa
	jr c, SndParam_UpdateAll_Body

SndParam_UpdateChannels_Done:
	popw iz
	inc 2, xsp
	ret

SndParam_UpdateSingleChannel:
	dec 8, xsp
	ld (xsp + 4), c
	ld (xsp + 6), a
	set 0, (0xb7ee:16)
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	cp (xsp + 4), 0x3
	jr z, SndParam_UpdateChan_Mode3
	cp (xsp + 4), 0x2
	jr z, SndParam_UpdateChan_Mode2
	ld (xsp + 4), 0x16
	jr SndParam_UpdateChan_CallRender

SndParam_UpdateChan_Mode2:
	ld (xsp + 4), 0x17

SndParam_UpdateChan_CallRender:
	call SoundMode_RenderWithNotify
	jr SndParam_UpdateChan_CopyMemory

SndParam_UpdateChan_Mode3:
	ld (xsp + 4), 0x0
	call SoundMode_FullRenderUpdate

SndParam_UpdateChan_CopyMemory:
	ld xbc, 0:i3
	ld c, (xsp + 6)
	sll xbc, 11
	lda xwa, (SEQ_SONG_SLOTS:24)
	add xwa, xbc
	ld (xsp), xwa
	ld xwa, 0x2e0
	add (xsp), xwa
	lda xbc, (0xf980:16)
	lda xwa, (0xfda2:16)
	sub xwa, xbc
	pushw wa
	push xbc
	ld xwa, (xsp + 6)
	push xwa
	call Mem_Copy
	lda xbc, (0xf9a0:16)
	lda xwa, (0xffc0:16)
	sub xwa, xbc
	pushw wa
	pushw 0x3
	pushw 0xc8e4
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 20)
	res 0, (0xb7ee:16)
	ld c, (xsp + 4)
	extz bc
	ld xwa, (xsp)
	calr SndParam_RelocateAndApply
	inc 8, xsp
	ret

MidiSysEx_SendAllParams:
	dec 2, xsp
	push xiz
	ld xwa, 0x2203
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jrl nz, MidiSysEx_PopIzAndReturn
	pushw 0xe
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jrl z, MidiSysEx_PopIzAndReturn
	call GET_COMPUTER_INTERFACE_SELECTION
	ld (xsp + 4), l
	ld xwa, 0x2d03
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendReverbParam
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x20
	ld (xiz + 12), 0x3
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendParamViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbParam

MidiSysEx_SendParamViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbParam:
	ld xwa, 0x2d01
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendProgramChange
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldmi16 (xiz + 4), 0xb7f2
	ld (xiz + 9), 0x11
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendReverbViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbParam2

MidiSysEx_SendReverbViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbParam2:
	ld (xiz + 9), 0x12
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendReverb2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendReverbFixup

MidiSysEx_SendReverb2ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendReverbFixup:
	mrdb5 0x8e, 0x0c, 0x19, 0xf2, 0xb7

MidiSysEx_SendProgramChange:
	ld xwa, 0x2d03
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendControlChange1
	pushw 0x2
	pushw MidiSysEx_SendProgramChange_Data@hi16
	pushw MidiSysEx_SendProgramChange_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendPCRegValue
	or (xiz), l

MidiSysEx_SendPCRegValue:
	ld xwa, 0x2d02
	call SndParam_LookupReadOnly
	ld (xiz + 1), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendPCViaCOMM
	push xiz
	pushw 0x2
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendControlChange1

MidiSysEx_SendPCViaCOMM:
	ld wa, 4:i3
	ld bc, 2:i3
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendControlChange1:
	ld xwa, 0x2d05
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendControlChange2
	pushw 0x3
	pushw MidiSysEx_SendControlChange1_Data@hi16
	pushw MidiSysEx_SendControlChange1_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendCC1RegValue
	or (xiz), l

MidiSysEx_SendCC1RegValue:
	ld xwa, 0x2d04
	call SndParam_LookupReadOnly
	ld (xiz + 2), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendCC1ViaCOMM
	push xiz
	pushw 0x3
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendControlChange2

MidiSysEx_SendCC1ViaCOMM:
	ld wa, 4:i3
	ld bc, 3:i3
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendControlChange2:
	ld xwa, 0x2d07
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_CheckDelayAndSend
	pushw 0x3
	pushw MidiSysEx_SendControlChange1_Data@hi16
	pushw MidiSysEx_SendControlChange1_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	cp hl, 0xf
	jr gt, MidiSysEx_SendCC2RegValue
	or (xiz), l

MidiSysEx_SendCC2RegValue:
	ld xwa, 0x2d06
	call SndParam_LookupReadOnly
	add hl, 0x3c
	ld (xiz + 2), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendCC2ViaCOMM
	push xiz
	pushw 0x3
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_CheckDelayAndSend

MidiSysEx_SendCC2ViaCOMM:
	ld wa, 4:i3
	ld bc, 3:i3
	ld xde, xiz
	call sendCOMM

MidiSysEx_CheckDelayAndSend:
	call AccPlay_GetCurrentPart
	cp l, 1:i3
	jr nz, MidiSysEx_SendAfterDelay
	ldw wa, 0x32
	call TaskSched_DelayTicks

MidiSysEx_SendAfterDelay:
	ld xwa, 0x2d09
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendBankData1
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x20
	ld xwa, 0x2d08
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendAfterDelayViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData1

MidiSysEx_SendAfterDelayViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData1:
	ld xwa, 0x2d0b
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendBankData2
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x16
	ld (xiz + 12), 0x0
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank1ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank1Param2

MidiSysEx_SendBank1ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank1Param2:
	ld (xiz + 9), 0x17
	ld xwa, 0x2d0a
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank1P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData2

MidiSysEx_SendBank1P2ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData2:
	ld xwa, 0x2d0f
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_SendBankData3
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x28
	ld xwa, 0x2d0e
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank2Param2

MidiSysEx_SendBank2ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank2Param2:
	ld (xiz + 9), 0x29
	ld xwa, 0x2d0d
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank2P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBankData3

MidiSysEx_SendBank2P2ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBankData3:
	ld xwa, 0x2d13
	call SndParam_LookupReadOnly
	cp hl, 0:i3
	jr z, MidiSysEx_FreeAndReturn
	pushw 0xe
	pushw MidiSysEx_SendAllParams_Data@hi16
	pushw MidiSysEx_SendAllParams_Data@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, 0x2d00
	call SndParam_LookupReadOnly
	ld (xiz + 4), l
	ld (xiz + 9), 0x1b
	ld xwa, 0x2d12
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank3ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_SendBank3Param2

MidiSysEx_SendBank3ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_SendBank3Param2:
	ld (xiz + 9), 0x1c
	ld xwa, 0x2d11
	call SndParam_LookupReadOnly
	ld (xiz + 12), l
	cp (xsp + 4), 0x0
	jr nz, MidiSysEx_SendBank3P2ViaCOMM
	push xiz
	pushw 0xe
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	jr MidiSysEx_FreeAndReturn

MidiSysEx_SendBank3P2ViaCOMM:
	ld wa, 4:i3
	ldw bc, 0xe
	ld xde, xiz
	call sendCOMM

MidiSysEx_FreeAndReturn:
	push xiz
	call Free
	inc 4, xsp

MidiSysEx_PopIzAndReturn:
	pop xiz
	inc 2, xsp
	ret

MidiSysEx_SendAllPartChannels:
	; --- Routine 1: stack-frame loop, XIZ alloc + 16 iterations (93 bytes) ---
	dec 2, xsp
	push xiz
	pushw	14
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, MidiSysEx_SendPartChan_Done
	ldw	(xsp+4), 0
MidiSysEx_SendPartChanLoop:
	pushw	14
	pushw	MidiSysEx_SendPartChanLoop_Data@hi16
	pushw	MidiSysEx_SendPartChanLoop_Data@lo16
	push xiz
	call Mem_Copy
	lda	xsp, (xsp+10)
	ld	wa, (xsp+4)
	ld (xiz+4), a
	ld (xiz+9), 0x12
	ld xwa, 0x00002d00
	call SndParam_LookupReadOnly
	ld (xiz+0x0c), l
	push xiz
	pushw	14
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	incw	1, (xsp+4)
	cpw (xsp+4), 0x0010
	jr c, MidiSysEx_SendPartChanLoop
	push xiz
	call Free
	inc 4, xsp
MidiSysEx_SendPartChan_Done:
	pop xiz
	inc 2, xsp
	ret
MidiSysEx_CopyParamToBuffer:
	; --- Routine 2: sla+lda helper, push args + call FF0D99 (32 bytes) ---
	extz wa
	sla	wa, 3
	lda xbc, (MidiSysEx_CopyParamToBuffer_Data:24)
	exts xwa
	add xwa, xbc
	pushw	8
	push xwa
	pushw	0
	pushw	0xfc4a
	call Mem_Copy
	lda	xsp, (xsp+10)
	ret


MidiPkt_SendControlPair:
	ld xbc, 0xbd26
	ld (xbc), a
	ld (xbc + 1), w
	ld xwa, xbc
	call MidiPkt_EnqueueControl_335E
	ret

MidiStream_RefreshDisplay:
	push xde
	push xhl
	push xix
	push xiz
	ld l, (0xbd26:16)
	ld h, (0xbd27:16)
	call AccompSeq_ManualMidiEntry1
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_ApplyPendingCC:
	push xde
	push xhl
	push xix
	push xiz
	ld c, 0x48:opc
	ld b, 0x3:opc
	ld e, (0xbd26:16)
	ld d, 0x7:opc
	call MidiStream_ApplyPendingParams
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_ReplaySavedExpr:
	push xde
	push xhl
	push xix
	push xiz
	call AccWrap_ReplaySavedExpr
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiStream_JumpStubData:
	push	xiz
	call	Audio_ProcessAllMidiStreams
	pop	xiz
	ret

MidiStream_RetStub2:
	ret

AccWrap_ReturnZero:
	ld hl, 0:i3
	ret

MidiStream_RetStub3:
	ret

MidiStream_PrevBankCheck:
	push	qiz
	bit	7, (0xbd18:16)
	jr	z, MidiStream_PrevBankCheck_Skip2
	ldib_erp 251, 0
MidiStream_PrevBankCheck_Loop:
	calr	SeqAlt_ProcessAndFinalize
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp	(xwa), 1
	jr	z, MidiStream_PrevBankCheck_Epilogue
	cp	(xwa), 6
	jr	nz, MidiStream_PrevBankCheck_Skip
	ld	(xwa+4), 32
	jr	MidiStream_PrevBankCheck_Epilogue
MidiStream_PrevBankCheck_Skip:
	ld	xwa, (0xbc60:16)
	calr	SeqOut_FlushWithChunking
	inc1b_erp	251
	cpib_erp	251, 3
	jr	c, MidiStream_PrevBankCheck_Loop
	cpib_erp	251, 3
	jr	c, MidiStream_PrevBankCheck_Epilogue
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	(xwa+4), 24
	jr	MidiStream_PrevBankCheck_Epilogue
MidiStream_PrevBankCheck_Skip2:
	calr	SeqBuf_WaitForEmpty
	calr	MidiStream_PrevBankCheck_Helper
MidiStream_PrevBankCheck_Epilogue:
	pop qiz
	ret

SeqAlt_ProcessAndFinalize:
	call MidiSeq_SwapActiveBuffers
	calr SeqBuf_WaitForEmpty
	calr MidiChan_ParseVoiceData
	calr SeqData_InitPlaybackFromField
	jp SeqAlt_CheckInitBuffer

SeqBuf_WaitForEmpty:
	pushw iz
	ldw iz, 0xfffe

SeqBuf_WaitLoop:
	call SeqBuf_MidiOut_CheckEmpty
	cp hl, 0:i3
	jr z, SeqBuf_WaitDone
	ld wa, iz
	dec 1, iz
	cp wa, 0:i3
	jr nz, SeqBuf_WaitLoop

SeqBuf_WaitDone:
	popw iz
	ret

MidiChan_ParseVoiceData:
	push xiz
	ldib_erp 0xfb, 0
	res 5, (0xbd18:16)
	ld iz, (SYSTEM_TIMESTAMP:16)
	jrl MidiChan_CheckSysExFlag

MidiChan_ReadNextByte:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0:i3
	jrl nz, MidiChan_ParseVoiceDone
	call SeqBuf2_ReadByte
	cp hl, 0xffff
	jr z, MIDI_ProcessChannelPair
	ld iz, (SYSTEM_TIMESTAMP:16)
	ld c, l
	extz bc
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cpib_erp 0xfb, 1
	jr z, MidiChan_CheckSysExData
	cpib_erp 0xfb, 0
	jr nz, MidiChan_CheckHighBit
	cp l, 0xf0
	jr nz, MidiChan_SendFieldParam4
	ldib_erp 0xfb, 1
	ld wa, bc
	jr MidiChan_AppendAndContinue

MidiChan_SendFieldParam4:
	ld bc, 4:i3
	ld de, 1:i3
	jr MidiChan_WriteAndSetFlag

MidiChan_CheckSysExData:
	cp l, 0x50
	jr nz, MidiChan_SendFieldParam4_2
	ldib_erp 0xfb, 2
	ld wa, bc
	jr MidiChan_AppendAndContinue

MidiChan_SendFieldParam4_2:
	ld bc, 4:i3
	ld de, 2:i3
	jr MidiChan_WriteAndSetFlag

MidiChan_CheckHighBit:
	bit 7, l
	jr nz, MidiChan_CheckSysExEnd
	ld xde, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	cpw (xde), 0xff
	jr nc, MidiChan_SendFieldParam6
	ld wa, bc

MidiChan_AppendAndContinue:
	calr VoiceQueue_Append
	jr MIDI_ProcessChannelPair

MidiChan_SendFieldParam6:
	ld bc, 4:i3
	ld de, 6:i3
	calr MIDI_ReadChannelParam
	jr MIDI_ProcessChannelPair

MidiChan_CheckSysExEnd:
	cp l, 0xf7
	jr nz, MidiChan_SendFieldParam3
	ldib_erp 0xfb, 0
	ld wa, bc
	calr VoiceQueue_Append
	set 5, (0xbd18:16)
	jr MIDI_ProcessChannelPair

MidiChan_SendFieldParam3:
	ld bc, 4:i3
	ld de, 3:i3

MidiChan_WriteAndSetFlag:
	calr MIDI_ReadChannelParam
	set 5, (1074:16)

MIDI_ProcessChannelPair:
	calr MidiChan_CheckFlags
	ld wa, iz
	calr MidiChan_CheckTimeout

MidiChan_CheckSysExFlag:
	bit 5, (0xbd18:16)
	jrl z, MidiChan_ReadNextByte

MidiChan_ParseVoiceDone:
	pop xiz
	ret

VoiceQueue_Append:
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda xde, (xbc + 10)
	ld xbc, (xde)
	lda xhl, (xbc+:1)
	ld (xde), xbc
	ld (xhl), a
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld xbc, (xbc + 10)
	ld (xbc), 0xff
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	cp a, 0xf0
	jr nz, VoiceQueue_IncrementCount
	ldw (xbc), 0x1
	ret

VoiceQueue_IncrementCount:
	incw 1, (xbc)
	ret

MidiChan_DequeueVoiceEntry:
	ld l, 0xff:opc
	lda xbc, (xwa + 2)
	ld xwa, (xbc)
	cp (xwa), 0xff
	ret z
	lda xde, (xwa+:1)
	ld (xbc), xwa
	ld l, (xde)
	ret

MidiChan_NibbleLookup_Data:
	ld	hl, de
	ld	xde, xwa
	ld	wa, hl
	dec	1, hl
	cp	wa, 0:i3
	jr	z, MidiChan_DequeueVoiceEntry_Skip
	lda	xix, (xde+10)
MidiChan_DequeueVoiceEntry_Loop:
	ld	xwa, (xix)
	lda xiy, (xwa+:1)
	ld (xix), xwa
	ld a, (xbc+)
	ld (xiy), a
	ld wa, hl
	dec 1, hl
	cp	wa, 0:i3
	jr	nz, MidiChan_DequeueVoiceEntry_Loop
MidiChan_DequeueVoiceEntry_Skip:
	ld	xwa, (xde+10)
	ld	(xwa), 255
	ret

MIDI_ReadChannelParam:
	extz bc
	cp bc, 0:i3
	ret mi
	cp bc, 0xf
	ret gt
	add bc, bc
	lda xix, (MIDI_ReadChannelParam_Data:24)
	ld	bc, (xix+bc)
	lda xix, (MidiChan_ParamDispatch:24)
	jp	t, (xix+bc)
; MIDI channel parameter read dispatch
MidiChan_ParamDispatch:
	ld	(xwa), e
	ret
	ld	xbc, 1:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 2:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 3:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 4:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 5:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 6:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 7:i3
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 8
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 9
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 10
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 11
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 12
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 13
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 14
	jr	MIDI_ReadChannelParam_Join
	ld	xbc, 15
MIDI_ReadChannelParam_Join:
	add	xwa, xbc
	ld	(xwa), e
	ret

; ============================================================================
; SeqData_ReadFieldByIndex - Read a field from sequencer data by index
; ============================================================================
; Input:  Index parameter identifying which field to read
; Output: Field value
; Indexed accessor for sequencer data structures. Reads a specific field
; from the current sequencer data block based on the given index.
; ============================================================================
SeqData_ReadFieldByIndex:
	extz bc
	cp bc, 0:i3
	jr mi, SeqData_ReturnZeroField
	cp bc, 0xf
	jr gt, SeqData_ReturnZeroField
	add bc, bc
	lda xix, (SeqData_ReadFieldByIndex_Data:24)
	ld	bc, (xix+bc)
	lda xix, (SeqData_FieldDispatch:24)
	jp	t, (xix+bc)
; Sequence data field read dispatch
SeqData_FieldDispatch:
	ld	l, (xwa)
	jr	SeqData_ReadFieldByIndex_Return
	ld	xbc, 1:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 2:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 3:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 4:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 5:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 6:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 7:i3
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 8
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 9
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 10
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 11
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 12
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 13
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 14
	jr	SeqData_ReadFieldByIndex_Join
	ld	xbc, 15
SeqData_ReadFieldByIndex_Join:
	add	xwa, xbc
	ld	l, (xwa)
	jr	SeqData_ReadFieldByIndex_Return

SeqData_ReturnZeroField:
	ld l, 0x0:opc
SeqData_ReadFieldByIndex_Return:
	ret

SeqData_InitPlaybackFromField:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0:i3
	ret nz
	calr MidiSeq_AssignVoiceSlots
	calr MidiStream_RetStub3
	calr MidiSeq_NopRet
	calr MidiSeq_ValidateVoiceRange
	calr MidiSeq_CheckQueuePosition
	calr MidiSeq_ParseVoiceConfig
	ret

MidiSeq_AssignVoiceSlots:
	dec 4, xsp
	pushw_erp 0xfa
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld xwa, 2:i3
	add (xbc + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0
	lda xbc, (SysExRx_TrieRoot:24)

MidiSeq_ScanSlot0_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	exts xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot0_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ld de, 7:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot0_CheckMatch:
	cp (xwa), l
	jr z, MidiSeq_Slot0_WriteParams
	cp (xwa), 0xfe
	jr nz, MidiSeq_Slot0_NextEntry

MidiSeq_Slot0_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 5:i3
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	lda xbc, (SysExRx_TrieRoot:24)
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot0_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	lda xwa, (WidgetParam_Entry_018_0x26:24)
	ld	xwa, (xwa+bc)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	lda xwa, (WidgetParam_Entry_018_0x26:24)
	ld	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot0_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	jr MidiSeq_PrepSlot1

MidiSeq_Slot0_NextEntry:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jrl c, MidiSeq_ScanSlot0_Loop

MidiSeq_PrepSlot1:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot1_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot1_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0x8
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot1_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot1_NextEntry

MidiSeq_Slot1_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 6:i3
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot1_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot2_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot2_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0x9
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot1_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot1_Loop

MidiSeq_Slot2_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot2_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot2_NextEntry

MidiSeq_Slot2_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 7:i3
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot2_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot2_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot3_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot3_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xa
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot2_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot2_Loop

MidiSeq_Slot3_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot3_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot3_NextEntry

MidiSeq_Slot3_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0x8
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot3_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot3_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot4_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot4_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xb
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot3_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot3_Loop

MidiSeq_Slot4_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot4_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot4_NextEntry

MidiSeq_Slot4_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0x9
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot4_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot4_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot5_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot5_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xc
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot4_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot4_Loop

MidiSeq_Slot5_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot5_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot5_NextEntry

MidiSeq_Slot5_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xa
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot5_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot5_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot6_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot6_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xd
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot5_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot5_Loop

MidiSeq_Slot6_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot6_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot6_NextEntry

MidiSeq_Slot6_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xb
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot6_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot6_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot7_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	cp (xwa), 0xff
	jr nz, MidiSeq_Slot7_CheckMatch
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xe
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot6_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot6_Loop

MidiSeq_Slot7_CheckMatch:
	cp l, (xwa)
	jr z, MidiSeq_Slot7_WriteParams
	cp (xwa), 0xfe
	jrl nz, MidiSeq_Slot7_NextEntry

MidiSeq_Slot7_WriteParams:
	extz hl
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xc
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot7_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot7_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0

MidiSeq_ScanSlot8_Loop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	exts xbc
	add xbc, xwa
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp (xbc), 0xff
	jr nz, MidiSeq_Slot8_CheckMatch
	ld bc, 4:i3
	ldw de, 0xf
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot7_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot7_Loop

MidiSeq_Slot8_CheckMatch:
	cp l, (xbc)
	jr z, MidiSeq_Slot8_WriteParams
	cp (xbc), 0xfe
	jrl nz, MidiSeq_Slot8_NextEntry

MidiSeq_Slot8_WriteParams:
	extz hl
	ldw bc, 0xd
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_Slot8_StorePtr
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot8_StorePtr:
	ld xwa, (xwa + 2)
	ld (xsp + 2), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldib_erp 0xfb, 0
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)

MidiSeq_ScanSlot9_Loop:
	ldto_berp C, 0xfb
	extz bc
	muls bc, 0x6
	ld de, bc
	ld xbc, (xsp + 2)
	lda	xbc, (xbc+de)
	cp (xbc), 0xff
	jr nz, MidiSeq_Slot9_CheckMatch
	ld bc, 4:i3
	ldw de, 0x10
	jrl MidiSeq_ChannelWriteEpilog

MidiSeq_Slot8_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot8_Loop

MidiSeq_Slot9_CheckMatch:
	cp l, (xbc)
	jr z, MidiSeq_Slot9_WriteParams
	cp (xbc), 0xfe
	jrl nz, MidiSeq_Slot9_NextEntry

MidiSeq_Slot9_WriteParams:
	extz hl
	ldw bc, 0xe
	ld de, hl
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld e, (xwa + 1)
	cp e, 0:i3
	jr z, MidiSeq_RestoreAndReturn
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 1:i3
	calr MIDI_ReadChannelParam
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 2)
	lda	xwa, (xwa+bc)
	ld xwa, (xwa + 2)
	ld e, (xwa + 1)
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 2:i3

MidiSeq_ChannelWriteEpilog:
	calr MIDI_ReadChannelParam

MidiSeq_RestoreAndReturn:
	popw_erp 0xfa
	inc 4, xsp
	ret

MidiSeq_Slot9_NextEntry:
	inc1b_erp 0xfb
	jrl MidiSeq_ScanSlot9_Loop

MidiSeq_NopRet:
	ret

MidiSeq_ValidateVoiceRange:
	push xiz
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0:i3
	jrl nz, MidiSeq_PopIzRet
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x11
	jr z, MidiSeq_Dequeue3Voices
	cp_erpb 0xfb, 0x14
	jr z, MidiSeq_Dequeue3Voices
	cp_erpb 0xfb, 0x19
	jrl nz, MidiSeq_CheckBitfieldType

MidiSeq_Dequeue3Voices:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf8
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf9
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xfa
	ld xde, 0:i3
	ldto_berp E, 0xfa
	ld xwa, 0:i3
	ldto_berp A, 0xf9
	sll xwa, 7
	or xde, xwa
	ld xwa, 0:i3
	ldto_berp A, 0xf8
	sll xwa, 14
	or xde, xwa
	cp_erpb 0xfb, 0x14
	jr z, MidiSeq_SetRange4D800
	cp_erpb 0xfb, 0x19
	jr z, MidiSeq_SetRange3900
	cp_erpb 0xfb, 0x11
	jr nz, MidiSeq_SetRange4D800
	ld xbc, 0x15440
	jr MidiSeq_CompareRange

MidiSeq_SetRange3900:
	ld xbc, 0x3900
	jr MidiSeq_CompareRange

MidiSeq_SetRange4D800:
	ld xbc, 0x4d800

MidiSeq_CompareRange:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp xde, xbc
	jr ugt, MidiSeq_RangeOverflow
	ldto_berp E, 0xf8
	extz de
	ldw bc, 0xc
	calr MIDI_ReadChannelParam
	ldto_berp E, 0xf9
	extz de
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xd
	calr MIDI_ReadChannelParam
	ldto_berp E, 0xfa
	extz de
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xe
	jr MidiSeq_WriteParamAndReturn

MidiSeq_RangeOverflow:
	ld bc, 4:i3
	ldw de, 0x16
	jr MidiSeq_WriteParamAndReturn

MidiSeq_CheckBitfieldType:
	cp_erpb 0xfb, 0x1b
	jr z, MidiSeq_ReadBitfield
	cp_erpb 0xfb, 0x1d
	jr nz, MidiSeq_PopIzRet

MidiSeq_ReadBitfield:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xc
	calr SeqData_ReadFieldByIndex
	cp l, 0xff
	jr nz, MidiSeq_PopIzRet
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldfr_berp L, 0xf8
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldto_berp A, 0xf8
	or a, l
	ldfr_berp A, 0xf8
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ldto_berp A, 0xf8
	or a, l
	ldfr_berp A, 0xf8
	cpib_erp 0xf8, 1
	jr z, MidiSeq_PopIzRet
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0xe

MidiSeq_WriteParamAndReturn:
	calr MIDI_ReadChannelParam

MidiSeq_PopIzRet:
	pop xiz
	ret

MidiSeq_CheckQueuePosition:
	pushw_erp 0xfa
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0:i3
	jrl nz, MidiSeq_PopRetFA
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xc
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xd
	calr SeqData_ReadFieldByIndex
	ldto_berp A, 0xfb
	or a, l
	ldfr_berp A, 0xfb
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0xe
	calr SeqData_ReadFieldByIndex
	ldto_berp A, 0xfb
	or a, l
	ldfr_berp A, 0xfb
	and a, 0xff
	jr z, MidiSeq_PopRetFA
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 5:i3
	calr SeqData_ReadFieldByIndex
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x7e
	jr z, MidiSeq_TrimQueue
	cp_erpb 0xfb, 0x2d
	jr z, MidiSeq_TrimQueue
	cp_erpb 0xfb, 0x2c
	jr nz, MidiSeq_PopRetFA

MidiSeq_TrimQueue:
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld xde, (xbc + 10)
	dec 3, xde
	ld xwa, (xbc + 2)
	ld (xbc + 6), xwa
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	inc 2, xbc
	cp (xbc), xde
	jr nc, MidiSeq_TrimCheckDone
	ld xhl, xbc

MidiSeq_TrimLoop:
	ld xwa, 2:i3
	add (xhl), xwa
	cp (xbc), xde
	jr c, MidiSeq_TrimLoop

MidiSeq_TrimCheckDone:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	cp (xwa + 2), xde
	jr z, MidiSeq_PopRetFA
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0x11
	calr MIDI_ReadChannelParam

MidiSeq_PopRetFA:
	popw_erp 0xfa
	ret

MidiSeq_ParseVoiceConfig:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0:i3
	jr nz, MidiChan_DequeueExit
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 5:i3
	calr SeqData_ReadFieldByIndex
	cp l, 0x7e
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2d
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2c
	jr z, SeqData_ParseFieldAndDequeue
	cp l, 0x2b
	jr nz, MidiChan_DequeueExit

SeqData_ParseFieldAndDequeue:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	calr MidiChan_DequeueVoiceEntry
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp l, 0:i3
	jr z, MidiSeq_DequeueWriteField15
	cp l, 1:i3
	jr nz, MidiSeq_WriteField4_12

MidiSeq_DequeueWriteField15:
	extz hl
	ldw bc, 0xf
	ld de, hl
	calr MIDI_ReadChannelParam
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda xbc, (xwa + 15)
	ld xhl, xbc
	ld xde, (xwa + 2)
	cp xbc, xde
	jr z, MidiSeq_NegateAndCheck

MidiSeq_CountEntriesLoop:
	ldto_berp C, 0xfb
	add C, (xhl+)
	ldfr_berp C, 0xfb
	cp xhl, xde
	jr nz, MidiSeq_CountEntriesLoop

MidiSeq_NegateAndCheck:
	ldto_berp C, 0xfb
	neg c
	ldfr_berp C, 0xfb
	res_erpb 0xfb, 0x07
	calr MidiChan_DequeueVoiceEntry
	cpb_erp L, 0xfb
	jr z, MidiChan_DequeueExit
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ldw de, 0x14
	jr MidiSeq_WriteParamAndExit

MidiSeq_WriteField4_12:
	ld bc, 4:i3
	ldw de, 0x12

MidiSeq_WriteParamAndExit:
	calr MIDI_ReadChannelParam

MidiChan_DequeueExit:
	popw_erp 0xfa
	ret

SeqBuf_FlushNoteOffs:
	ld de, bc
	dec 1, bc
	cp de, 0:i3
	jr z, SeqBuf_FlushTerminate
	ld xhl, (0xbc5c:16)
	lda xix, (xhl + 10)

SeqBuf_FlushLoop:
	ld xde, (xix)
	lda xiy, (xde+:1)
	ld (xix), xde
	ld E, (xwa+)
	ld (xiy), e
	incw 1, (xhl)
	ld de, bc
	dec 1, bc
	cp de, 0:i3
	jr nz, SeqBuf_FlushLoop

SeqBuf_FlushTerminate:
	ld xwa, (0xbc5c:16)
	ld xwa, (xwa + 10)
	ld (xwa), 0xff
	ld xwa, (0xbc5c:16)
	ld xbc, (xwa + 10)
	cp (xbc - 1), 0xf7
	ret nz

	calr SeqOut_FlushWithChunking
	call MidiSeq_UpdateAllParams
	call ArpQueue_SwapBuffers
	ret

ArpQueue_Pack21BitValue:
	dec	4, xsp
	lda	xwa, (xsp)
	lda	xde, (0xbcd4:16)
	ld	xbc, (xde)
	srl	xbc, 14
	res	7, c
	ld	(xwa), c
	ld	xbc, (xde)
	srl	xbc, 7
	res	7, c
	ld	(xwa+1), c
	ld	xbc, (xde)
	res	7, c
	ld	(xwa+2), c
	ld	bc, 3:i3
	calr	ArpQueue_Enqueue
	inc	4, xsp
	ret

ArpQueue_Enqueue:
	ld de, bc
	dec 1, bc
	cp de, 0:i3
	jr z, ArpQueue_EnqueueDone
	ld xhl, (0xbc5c:16)
	lda xix, (xhl + 10)

ArpQueue_EnqueueLoop:
	ld xde, (xix)
	lda xiy, (xde+:1)
	ld (xix), xde
	ld E, (xwa+)
	ld (xiy), e
	incw 1, (xhl)
	ld de, bc
	dec 1, bc
	cp de, 0:i3
	jr nz, ArpQueue_EnqueueLoop

ArpQueue_EnqueueDone:
	ld xwa, (0xbc5c:16)
	ld xwa, (xwa + 10)
	ld (xwa), 0xff
	ret

ArpQueue_ProcessAndSort_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp	(xwa+4), 0
	ret	nz
ArpQueue_ProcessAndSort_Data_Loop:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp	(xwa+4), 0
	ret	nz
	call	MidiSeq_PartConfigure_Data
	calr	ArpQueue_ProcessAndSort_Data_Helper
	calr	ArpQueue_ProcessAndSort_Data_Helper2
	calr	ArpQueue_ProcessAndSort_Data_Helper3
	calr	ArpQueue_ComputeAndEnqueue
	ld	xwa, (0xbc5c:16)
	calr	SeqOut_FlushWithChunking
	call	MidiSeq_UpdateAllParams
	call	ArpQueue_SwapBuffers
	calr	MidiStream_PrevBankCheck
	ld	xwa, (0xbcd4:16)
	or	xwa, xwa
	jr	nz, ArpQueue_ProcessAndSort_Data_Loop
	ret
ArpQueue_ProcessAndSort_Data_Helper:
	ld	xwa, (0xbcb8:16)
	cp	(xwa+15), 1
	ret	nz
	ld	xwa, SysEx_Msg_35B8
	ld	bc, 3:i3
	calr	SeqBuf_FlushNoteOffs
	ret
ArpQueue_ProcessAndSort_Data_Helper2:
	dec	2, xsp
	ld	xwa, (0xbcd4:16)
	or	xwa, xwa
	jr	z, ArpQueue_ProcessAndSort_Data_Epilogue
ArpQueue_ProcessAndSort_Data_Helper2_Loop:
	lda	xwa, (xsp)
	lda	xde, (xwa+1)
	lda	xhl, (0xbccc:16)
	ld	xbc, (xhl)
	lda xix, (xbc+:1)
	ld (xhl), xbc
	ld	c, (xix)
	ld	(xde), c
	ld	(xwa), c
	srl	c, 4
	ld	(xwa), c
	andmi8	(xde), 15
	ld	bc, 2:i3
	calr	ArpQueue_Enqueue
	ld	xwa, 1:i3
	sub	(0xbcc4:16), xwa
	lda	xbc, (0xbcd4:16)
	ld	xwa, (xbc)
	dec	1, xwa
	ld	(xbc), xwa
	or	xwa, xwa
	jr	z, ArpQueue_ProcessAndSort_Data_Epilogue
	ld	xwa, (0xbc5c:16)
	cpw	(xwa), 252
	jr	c, ArpQueue_ProcessAndSort_Data_Helper2_Loop
ArpQueue_ProcessAndSort_Data_Epilogue:
	inc	2, xsp
	ret
ArpQueue_ProcessAndSort_Data_Helper3:
	dec	2, xsp
	ld	(xsp), 1
	ld	xwa, (0xbcd4:16)
	or	xwa, xwa
	jr	nz, ArpQueue_ProcessAndSort_Data_Helper3_Skip
	ld	(xsp), 0
ArpQueue_ProcessAndSort_Data_Helper3_Skip:
	lda	xwa, (xsp)
	ld	bc, 1:i3
	calr	ArpQueue_Enqueue
	ld	e, (xsp)
	extz	de
	ld	xwa, (0xbcb4:16)
	ldw	bc, 15
	calr	MIDI_ReadChannelParam
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), 1
	lda	xwa, (xsp)
	ld	bc, 1:i3
	calr	ArpQueue_Enqueue
	ld	e, (xsp)
	extz	de
	ld	xwa, (0xbcb4:16)
	ldw	bc, 15
	calr	MIDI_ReadChannelParam
	inc	2, xsp
	ret

ArpQueue_ComputeAndEnqueue:
	dec 2, xsp
	ld e, 0x0:opc
	ld xiy, ArpQueue_ComputeAndEnqueue_Data
	ld xix, xsp
	ldiw
	ld xwa, (0xbc5c:16)
	lda xbc, (xwa + 15)
	ld xhl, xbc
	ld xwa, (xwa + 10)
	cp xbc, xwa
	jr z, ArpQueue_ComputeSize

ArpQueue_CountLoop:
	add E, (xhl+)
	cp xhl, xwa
	jr nz, ArpQueue_CountLoop

ArpQueue_ComputeSize:
	lda xwa, (xsp)
	neg e
	res 7, e
	ld (xwa), e
	ld bc, 2:i3
	calr ArpQueue_Enqueue
	inc 2, xsp
	ret

SeqOut_FlushWithChunking:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld wa, (xiz)
	ld (xsp + 4), wa
	ld (1060:16), 240
	ld xwa, xiz
	calr MidiStream_RetStub2
	lda xiz, (xiz + 14)
	cpw (xsp + 4), 0x20
	jr ule, SeqOut_ChunkRemainder

SeqOut_ChunkLoop32:
	ei 6
	push xiz
	pushw 0x20
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	submi16 (xsp + 4), 0x20
	lda xiz, (xiz + 32)
	cpw (xsp + 4), 0x20
	jr ugt, SeqOut_ChunkLoop32

SeqOut_ChunkRemainder:
	ei 6
	push xiz
	pushm (xsp + 8)
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	pop xiz
	inc 2, xsp
	ret

SeqOut_FlushTimedBuffer:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld wa, (xiz)
	ld (xsp + 4), wa
	ld (1060:16), 240
	ld xwa, xiz
	calr MidiStream_RetStub2
	lda xiz, (xiz + 14)
	cpw (xsp + 4), 0x20
	jr ule, SeqOut_TimedChunkRemainder

SeqOut_TimedChunkLoop32:
	ei 6
	push xiz
	pushw 0x20
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	submi16 (xsp + 4), 0x20
	lda xiz, (xiz + 32)
	cpw (xsp + 4), 0x20
	jr ugt, SeqOut_TimedChunkLoop32

SeqOut_TimedChunkRemainder:
	ei 6
	push xiz
	pushm (xsp + 8)
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0
	pop xiz
	inc 2, xsp
	ret

SeqVoice_ReadEntryFields_Data:
	ld	xde, xwa
	ld	a, (xde)
	ld	(xbc+), a
	ld	a, (xde+1)
	ld	(xbc+), a
	ld	a, (xde+2)
	ld	(xbc+), a
	ld	a, (xde+3)
	ld	(xbc+), a
	ld	(xbc), 255
	ret

SeqVoice_StoreEntry:
	dec 4, xsp
	lda xbc, (xsp)
	ld xde, (xsp + 8)
	ld A, (xde+)
	ld (xbc), a
	cp a, 0xff
	jr z, SeqVoice_StoreEntryDone
	ld A, (xde+)
	ld (xbc + 1), a
	ld A, (xde+)
	ld (xbc + 2), a
	ld a, (xde)
	ld (xbc + 3), a

SeqVoice_StoreEntryDone:
	ld xhl, (xsp)
	inc 4, xsp
	ret

SeqVoice_DispatchProcess_Data:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	cpw	(xiz), 0
	jr	z, SeqVoice_DispatchProcess_Data_Skip2
	lda	xbc, (xiz+6)
	ld	xix, xbc
	ld	xhl, xbc
	lda	xiy, (0xbcec:16)
	ld	xde, xiy
	lda	xwa, (0xbce4:16)
	ld	(xsp+4), xwa
	inc	8, xiy
	ld	(xsp+8), xbc
	lda	xwa, (xiz+10)
	ld	(xsp+12), xwa
SeqVoice_DispatchProcess_Data_Loop:
	ld	xwa, (xix)
	lda xbc, (xwa+:1)
	ld (xix), xwa
	ld	c, (xbc)
	sll	c, 4
	ld	xwa, (xhl)
	lda xiz, (xwa+:1)
	ld (xhl), xwa
	ld	w, (xiz)
	and	w, 15
	xor	c, w
	ld	xwa, (xde)
	lda xiz, (xwa+:1)
	ld (xde), xwa
	ld	(xiz), c
	ld	xwa, (xsp+4)
	ld	xbc, 1:i3
	sub	(xwa), xbc
	ld	xbc, (xiy)
	dec	1, xbc
	ld	(xiy), xbc
	ld	xwa, (xsp+12)
	ld	xwa, (xwa)
	lda	xiz, (xwa-3)
	ld	xwa, (xsp+8)
	cp	(xwa), xiz
	jr	c, SeqVoice_DispatchProcess_Data_Skip
	ld	hl, 0:i3
	jr	SeqVoice_DispatchProcess_Data_Epilogue
SeqVoice_DispatchProcess_Data_Skip:
	or	xbc, xbc
	jr	nz, SeqVoice_DispatchProcess_Data_Loop
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 22
	calr	MIDI_ReadChannelParam
SeqVoice_DispatchProcess_Data_Skip2:
	ldw	hl, 0xffff
SeqVoice_DispatchProcess_Data_Epilogue:
	pop	xiz
	lda	xsp, (xsp+12)
	ret
MidiPkt_ArpExtHandler_G_Helper:
	push	xiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 12
	calr	SeqData_ReadFieldByIndex
	ld	xiz, 0:i3
	ldfr_berp l, 248
	sll xiz, 14
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 13
	calr	SeqData_ReadFieldByIndex
	ld	h, 0:opc
	extz	xhl
	sll	xhl, 7
	or	xiz, xhl
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 14
	calr	SeqData_ReadFieldByIndex
	ld	h, 0:opc
	extz	xhl
	or	xiz, xhl
	lda	xwa, (0xbcdc:16)
	ld	xbc, (xwa)
	add	xbc, xiz
	ld	(xwa+4), xbc
	ld	(xwa+8), xiz
	lda	xwa, (0xbcec:16)
	ld	xbc, (xwa)
	add	xbc, xiz
	ld	(xwa+4), xbc
	ld	(xwa+8), xiz
	pop	xiz
	ret
MidiSeq_ClearSyncFlag_Helper:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0xf980:16)
	ld	(xiz), xwa
	calr	SeqVoice_DispatchProcess_Data_Helper2
	ld	(xsp+4), xhl
	calr	SeqVoice_DispatchProcess_Data_Helper3
	lda	xwa, (0xffbe:16)
	sub	xwa, 0xf980
	add	xwa, 0x12cb2
	add	xwa, xhl
	add	xwa, (xsp+4)
	add	xwa, 0x5800
	add	(xiz+8), xwa
	ld	wa, 1:i3
	calr	AccWrap_ReturnZero
	cp	hl, 0xffff
	jr	z, SeqVoice_DispatchProcess_Data_Skip3
	ld	xwa, 0x72aa
	add	(xiz+8), xwa
SeqVoice_DispatchProcess_Data_Skip3:
	ld	wa, 3:i3
	calr	AccWrap_ReturnZero
	cp	hl, 0xffff
	jr	z, SeqVoice_DispatchProcess_Data_Skip4
	calr	SeqVoice_DispatchProcess_Data_Helper
	add	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Skip4:
	ld	xwa, (xiz+8)
	add	xwa, (xiz)
	ld	(xiz+4), xwa
	pop	xiz
	inc	4, xsp
	ret
MidiSeq_ClearSyncFlag_Helper2:
	lda	xde, (0xf980:16)
	ld	(xwa), xde
	lda	xbc, (0xffbe:16)
	sub	xbc, xde
	ld	xde, xbc
	add	xde, 0x12cb2
	ld	xbc, (xwa)
	ld	xhl, xde
	add	xhl, xbc
	ld	(xwa+4), xhl
	ld	(xwa+8), xde
	ret
MidiPkt_ArpPopReturn_Helper:
	lda	xde, (0xf980:16)
	ld	(xwa), xde
	lda	xbc, (0xffbe:16)
	sub	xbc, xde
	inc	2, xbc
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper2:
	lda	xbc, (0x1ed350:24)
	ld	(xwa), xbc
	add	xbc, 0x12cb0
	ld	(xwa+4), xbc
	ld	xbc, 0x12cb0
	ld	(xwa+8), xbc
	ret
MidiSeq_ClearSyncFlag_Helper3:
	lda	xbc, (0x1e0000:24)
	ld	(xwa), xbc
	ld	xbc, 0x72aa
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+0x72aa)
	ld	(xwa+4), xbc
	ret
MidiPkt_ArpPopReturn_Helper3:
	lda	xbc, (0x1e0000:24)
	ld	(xwa), xbc
	ld	xbc, 16
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+16)
	ld	(xwa+4), xbc
	ret
MidiPkt_ArpPopReturn_Helper4:
	lda	xbc, (0x1e0000:24)
	add	xbc, 16
	ld	(xwa), xbc
	ld	xbc, 0x729a
	ld	(xwa+8), xbc
	ld	xbc, (xwa)
	lda	xbc, (xbc+0x729a)
	ld	(xwa+4), xbc
	ret
MidiSeq_ClearSyncFlag_Helper4:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld	(xiz), xwa
	add	xwa, 0x16800
	ld	(xiz+4), xwa
	ld	xwa, 0x16800
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue2
	calr	SeqVoice_DispatchProcess_Data_Helper
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Epilogue2:
	pop	xiz
	ret
MidiPkt_ArpPopReturn_Helper5:
	lda	xde, (RHYTHM_PATTERN_BUF_A:24)
	ld	(xwa), xde
	lda	xbc, (0x94860:24)
	sub	xbc, xde
	add	xde, xbc
	ld	(xwa+4), xde
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper6:
	lda	xde, (0x94860:24)
	ld	(xwa), xde
	lda	xbc, (0x95bc0:24)
	sub	xbc, xde
	add	xde, xbc
	ld	(xwa+4), xde
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper7:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0x95bc0:24)
	ld	(xiz), xwa
	add	xwa, 0x15440
	ld	(xiz+4), xwa
	ld	xwa, 0x15440
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue3
	calr	SeqVoice_DispatchProcess_Data_Helper
	lda	xde, (0x94860:24)
	lda	xbc, (0x95bc0:24)
	sub	xbc, xde
	lda	xix, (RHYTHM_PATTERN_BUF_A:24)
	sub	xde, xix
	add	xde, xbc
	ld	xbc, (xiz)
	add	xbc, xhl
	sub	xbc, xde
	ld	(xiz+4), xbc
	sub	xhl, xde
	ld	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Epilogue3:
	pop	xiz
	ret
MidiSeq_ClearSyncFlag_Helper5:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0xf180:16)
	ld	(xiz), xwa
	add	xwa, 0x53000
	ld	(xiz+4), xwa
	ld	xwa, 0x53000
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue4
	calr	SeqVoice_DispatchProcess_Data_Helper2
	lda	xwa, (xhl+22528)
	add	xwa, (xiz)
	ld	(xiz+4), xwa
	ld	xwa, 0x5800
	add	xwa, xhl
	ld	(xiz+8), xwa
SeqVoice_DispatchProcess_Data_Epilogue4:
	pop	xiz
	ret
MidiPkt_ArpPopReturn_Helper8:
	lda	xbc, (0xf180:16)
	ld	(xwa), xbc
	lda	xbc, (xbc+2048)
	ld	(xwa+4), xbc
	ld	xbc, 0x800
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper9:
	lda	xbc, (SEQ_SONG_SLOTS:24)
	ld	(xwa), xbc
	lda	xbc, (xbc+20480)
	ld	(xwa+4), xbc
	ld	xbc, 0x5000
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper10:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0xb0000:24)
	ld	(xiz), xwa
	add	xwa, 0x4d800
	ld	(xiz+4), xwa
	ld	xwa, 0x4d800
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue5
	calr	SeqVoice_DispatchProcess_Data_Helper2
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Epilogue5:
	pop	xiz
	ret
	ret
	ret
	ret
MidiSeq_ClearSyncFlag_Helper6:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0x1e8800:24)
	ld	(xiz), xwa
	lda	xwa, (xwa+15360)
	ld	(xiz+4), xwa
	ld	xwa, 0x3c00
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue6
	calr	SeqVoice_DispatchProcess_Data_Helper3
	ld	xwa, (xiz)
	add	xwa, xhl
	ld	(xiz+4), xwa
	ld	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Epilogue6:
	pop	xiz
	ret
MidiPkt_ArpPopReturn_Helper11:
	lda	xde, (0x1e8800:24)
	ld	(xwa), xde
	lda	xbc, (0x1e8820:24)
	sub	xbc, xde
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper12:
	lda	xde, (0x1e8820:24)
	ld	(xwa), xde
	lda	xbc, (0x1e8b00:24)
	sub	xbc, xde
	ld	xhl, xbc
	add	xhl, xde
	ld	(xwa+4), xhl
	ld	(xwa+8), xbc
	ret
MidiPkt_ArpPopReturn_Helper13:
	push	xiz
	ld	xiz, xwa
	lda	xwa, (0x1e8b00:24)
	ld	(xiz), xwa
	lda	xwa, (xwa+0x3900)
	ld	(xiz+4), xwa
	ld	xwa, 0x3900
	ld	(xiz+8), xwa
	bit	6, (0xbd18:16)
	jr	z, SeqVoice_DispatchProcess_Data_Epilogue7
	calr	SeqVoice_DispatchProcess_Data_Helper3
	lda	xde, (0x1e8820:24)
	lda	xbc, (0x1e8b00:24)
	sub	xbc, xde
	lda	xix, (0x1e8800:24)
	sub	xde, xix
	add	xde, xbc
	ld	xbc, (xiz)
	add	xbc, xhl
	sub	xbc, xde
	ld	(xiz+4), xbc
	sub	xhl, xde
	ld	(xiz+8), xhl
SeqVoice_DispatchProcess_Data_Epilogue7:
	pop	xiz
	ret
SeqVoice_DispatchProcess_Data_Helper:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqVoice_StoreEntryDone_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	hl, (0x9482e:24)
	extz	xhl
	sll	xhl, 4
	ret
SeqVoice_DispatchProcess_Data_Helper2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqStep_ByteBlockEA5F
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	hl, (0xf1ce:16)
	extz	xhl
	sll	xhl, 4
	ret
SeqVoice_DispatchProcess_Data_Helper3:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqVoice_StoreEntryDone_Helper2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	hl, (0x1e881c:24)
	extz	xhl
	sll	xhl, 4
	ret

MidiChan_CheckFlags:
	ei 6
	ld a, (1063:16)
	and a, 0x2c
	jr z, MidiChan_EnableAndReturn
	call SeqBuf2_InitWithInterrupts
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ld de, 4:i3
	calr MIDI_ReadChannelParam
	and (1063:16), 211

MidiChan_EnableAndReturn:
	ei 0
	ret

MidiChan_CheckTimeout:
	ldw de, 0x9c4
	bit 2, (0xbd18:16)
	jr z, MidiChan_ApplyTimeout
	ldw de, 0x3e8

MidiChan_ApplyTimeout:
	ld bc, (SYSTEM_TIMESTAMP:16)
	sub bc, wa
	cp bc, de
	ret le
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	ld de, 5:i3
	calr MIDI_ReadChannelParam
	ret

MidiChan_TimerDispatch_Data:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_DSPCfg_Initialize
	call	SndParam_SyncDisplayBitmap
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiStream_PrevBankCheck_Helper:
	ld	de, (SYSTEM_TIMESTAMP:16)
MidiChan_TimerDispatch_Data_Code_Loop:
	ld	wa, de
	ld	bc, (SYSTEM_TIMESTAMP:16)
	sub	bc, wa
	cp	bc, 25
	jr	lt, MidiChan_TimerDispatch_Data_Code_Loop
	ret

Part_LookupByIndex:
	ld xbc, (0x90f2:16)
	extz wa
	sla wa, 2
	ld	xhl, (xbc+wa)
	ret

MIDI_PackNibbleParam:
	lda xbc, (xwa + 6)
	ld xwa, (xbc)
	lda xde, (xwa+:1)
	ld (xbc), xwa
	ld l, (xde)
	sll l, 4
	lda xde, (xwa+:1)
	ld (xbc), xwa
	ld a, (xde)
	and a, 0xf
	or l, a
	ret

MidiTG_WriteRegByDescriptor:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld a, (xiz)
	extz wa
	calr Part_LookupByIndex
	cp xhl, 0xffffffff
	jr z, MidiTG_WriteReg_NoEntry
	lda xde, (xiz + 2)
	lda xix, (xiz + 3)
	ld a, (xix)
	and (xde), a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xix)
	cpl a
	and	(xhl+iy), a
	ld c, (xbc)
	extz bc
	ld a, (xde)
	or	(xhl+bc), a
	jr MidiTG_WriteReg_Return

MidiTG_WriteReg_NoEntry:
	ldw (xsp + 4), 0xffff

MidiTG_WriteReg_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

AssSwb_ApplyBitDescriptor:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld a, (xiz)
	extz wa
	calr Part_LookupByIndex
	cp xhl, 0xffffffff
	jr z, AssSwb_NoEntry
	lda xde, (xiz + 2)
	lda xix, (xiz + 3)
	ld a, (xix)
	and (xde), a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xix)
	cpl a
	and	(xhl+iy), a
	ld a, (xbc)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xde)
	or	(xhl+iy), a
	ld a, (xiz)
	extz wa
	ld c, (xbc)
	extz bc
	ld	e, (xhl+bc)
	extz de
	ld l, (xix)
	extz hl
	pushw hl
	call AssswbWr
	jr AssSwb_Return

AssSwb_NoEntry:
	ldw (xsp + 4), 0xffff

AssSwb_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

AssSwb_ProcessLoop_Data:
	dec	6, xsp
	push	xiz
	ld	xiz, xwa
	ldw	(xsp+4), 0
	ld	a, (xiz)
	extz	wa
	calr	Part_LookupByIndex
	ld	(xsp+6), xhl
	ld	xbc, (xsp+6)
	cp	xbc, 0xffffffff
	jrl	z, AssSwb_ProcessLoop_Data_Skip
	lda	xix, (xiz+2)
	lda	xhl, (xiz+4)
	ld	wa, (xhl)
	and	(xix), wa
	lda	xde, (xiz+1)
	ld	a, (xde)
	ldfr_berp	a, 244
	extz	iy
	ld	wa, (xhl)
	cpl	a
	and	(xbc+iy), a	; the backend cannot spell this form
	ld	a, (xde)
	ldfr_berp	a, 244
	extz	iy
	ld	wa, (xix)
	or	(xbc+iy), a	; the backend cannot spell this form
	ld	a, (xde)
	extz	wa
	ld	iy, wa
	inc	1, iy
	ld	wa, (xhl)
	srl	wa, 8
	cpl	a
	and	(xbc+iy), a	; the backend cannot spell this form
	ld	a, (xde)
	extz	wa
	ld	iy, wa
	inc	1, iy
	ld	wa, (xix)
	srl	wa, 8
	ld	xix, (xsp+6)
	or	(xix+iy), a	; the backend cannot spell this form
	ld	a, (xiz)
	extz	wa
	ld	c, (xde)
	extz	bc
	ld	e, (xix+bc)
	extz de
	ld	hl, (xhl)
	extz	hl
	pushw	hl
	call	AssswbWr
	ld	a, (xiz)
	extz	wa
	ld	l, (xiz+1)
	ld	c, l
	inc	1, c
	extz	bc
	extz	hl
	inc	1, hl
	ld	xde, (xsp+6)
	ld	e, (xde+hl)
	extz	de
	ld	hl, (xiz+4)
	srl	hl, 8
	extz	hl
	pushw	hl
	call	AssswbWr
	jr	AssSwb_ProcessLoop_Data_Join
AssSwb_ProcessLoop_Data_Skip:
	ldw	(xsp+4), 0xffff
AssSwb_ProcessLoop_Data_Join:
	ld	hl, (xsp+4)
	pop	xiz
	inc	6, xsp
	ret

Part_LookupTableEntry:
	ld xde, (0x90f2:16)
	extz wa
	sla wa, 2
	ld	xwa, (xde+wa)
	cp xwa, 0xffffffff
	jr z, Part_LookupReturnZero
	extz bc
	ld	l, (xwa+bc)
	ret

Part_LookupReturnZero:
	ld l, 0x0:opc
	ret

Part_ProcessEntry_Data:
	ld	xhl, xwa
	ld	wa, bc
	dec	1, bc
	cp	wa, 0:i3
	ret	z
Part_LookupTableEntry_Loop:
	ld a, (xhl+)
	ld (xde+), a
	ld wa, bc
	dec 1, bc
	cp	wa, 0:i3
	jr	nz, Part_LookupTableEntry_Loop
	ret
Param_SignExtendReturn_Helper3_Helper:
	inc	1, xwa
	ld	l, 0:opc
	dec	1, bc
	ld	de, bc
	dec	1, bc
	cp	de, 0:i3
	jr	z, Part_LookupTableEntry_Skip
Part_LookupTableEntry_Loop2:
	add l, (xwa+)
	ld de, bc
	dec 1, bc
	cp	de, 0:i3
	jr	nz, Part_LookupTableEntry_Loop2
Part_LookupTableEntry_Skip:
	neg	l
	res	7, l
	ret
Param_SignExtendReturn_Helper3_Helper2:
	calr	ArpQueue_Enqueue
	ld	xwa, (0xbc5c:16)
	calr	SeqOut_FlushWithChunking
	jp	ArpQueue_SwapBuffers
	ret
	ret
MidiTable_DispatchHelper_Helper:
	ret

MidiChan_ClearAllStates:
	ld (0xbd00:16), 0
	ld (0xbd02:16), 0
	ld (0xbd04:16), 0
	ld (0xbd06:16), 0
	ld (0xbd08:16), 0
	ld (0xbd0a:16), 0
	ld (0xbd0c:16), 0
	ld (0xbd0e:16), 0
	ld (0xbd10:16), 0
	ld (0xbd12:16), 0
	ld (0xbd14:16), 0
	ld (0xbd16:16), 0
	ld (0xbd36:16), 0
	ld (0xbd38:16), 0
	calr MidiChan_SetStateMode
	calr MidiChan_SetVoiceBaseState
	jrl MidiSeq_ApplyPendingParams

MidiChan_SetStateMode:
	bit 6, (0xbd18:16)
	jr z, MidiChan_SetStateMode2
	ld (0xbd36:16), 1
	ld a, 0x1:opc
	jr MidiChan_CompareAndFlag

MidiChan_SetStateMode2:
	ld (0xbd36:16), 2
	ld a, (0xbd36:16)

MidiChan_CompareAndFlag:
	cp a, (0xbd38:16)
	ret z
	set 6, (0xbd1c:16)
	ldmm8 0xbd38, 0xbd36
	ret

MidiChan_SetVoiceBaseState:
	bit 6, (0xbd18:16)
	jr z, MidiChan_SetBaseState128
	ld (0xbd00:16), 128
	ret

MidiChan_SetBaseState128:
	ld (0xbd0c:16), 128
	ret

MidiSeq_UpdateAllParams:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	call SeqData_ReadFieldByIndex
	cp l, 0:i3
	ret nz
	calr MidiSeq_SyncToneStates_Upper
	calr MidiSeq_UpdateToneParam
	calr MidiSeq_UpdateVolumeScale
	calr MidiSeq_ComputeExpression
	calr MidiSeq_CheckSyncDirty
	calr MidiSeq_ApplyPendingParams
	call MainTitle_PrepareAndDispatch
	ret

MidiSeq_SyncToneStates_Upper:
	bit 6, (0xbd18:16)
	jr z, MidiSeq_SyncToneStates_Lower
	res 7, (0xbd00:16)
	ldmm8 0xbd02, 0xbd00
	res 7, (0xbd04:16)
	ldmm8 0xbd06, 0xbd04
	res 7, (0xbd08:16)
	ldmm8 0xbd0a, 0xbd08
	ret

MidiSeq_SyncToneStates_Lower:
	res 7, (0xbd0c:16)
	ldmm8 0xbd0e, 0xbd0c
	res 7, (0xbd10:16)
	ldmm8 0xbd12, 0xbd10
	res 7, (0xbd14:16)
	ldmm8 0xbd16, 0xbd14
	ret

MidiSeq_UpdateToneParam:
	bit 6, (0xbd18:16)
	jr z, MidiSeq_UpdateToneParam_Lower
	ld xwa, (0xbcb4:16)
	ld bc, 3:i3
	call SeqData_ReadFieldByIndex
	extz hl
	lda xbc, (MidiRx_ToneParam_ByteMap:24)
	ld	c, (xbc+hl)
	ld a, c
	ld (0xbd00:16), c
	cp c, (0xbd02:16)
	ret z
	set 7, a
	ld (0xbd00:16), a
	ret

MidiSeq_UpdateToneParam_Lower:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 3:i3
	call SeqData_ReadFieldByIndex
	extz hl
	lda xbc, (MidiRx_ToneParam_ByteMap:24)
	ld	c, (xbc+hl)
	ld a, c
	ld (0xbd0c:16), c
	cp c, (0xbd0e:16)
	ret z
	set 7, a
	ld (0xbd0c:16), a
	ret

MidiSeq_UpdateVolumeScale:
	lda xwa, (0xbd1c:16)
	bitm 7, (xwa)
	ret nz
	bit 6, (0xbd18:16)
	jr z, MidiSeq_VolScale_Lower
	lda xbc, (0xbcbc:16)
	ld xde, (xbc + 8)
	srl xde, 5
	ld (xbc + 12), xde
	ld (0xbd04:16), 160
	jr MidiSeq_VolScale_SetActive

MidiSeq_VolScale_Lower:
	lda xbc, (0xbcdc:16)
	ld xde, (xbc + 8)
	srl xde, 5
	ld (xbc + 12), xde
	ld (0xbd10:16), 160

MidiSeq_VolScale_SetActive:
	or xde, xde
	ret z
	setm 7, (xwa)
	ret

MidiSeq_ComputeExpression:
	bit 6, (0xbd18:16)
	jr z, MidiSeq_Expression_Lower
	lda xwa, (0xbcbc:16)
	ld xde, (xwa + 8)
	ld xbc, (xwa + 12)
	or xde, xde
	ret z
	or xbc, xbc
	ret z
	ld xwa, xde
	call Math_DivideU32
	sub xhl, 0x20
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld a, l
	ld (0xbd08:16), l
	cp l, (0xbd0a:16)
	ret z
	set 7, a
	ld (0xbd08:16), a
	ret

MidiSeq_Expression_Lower:
	lda xwa, (0xbcdc:16)
	ld xde, (xwa + 8)
	ld xbc, (xwa + 12)
	or xde, xde
	ret z
	or xbc, xbc
	ret z
	ld xwa, xde
	call Math_DivideU32
	sub xhl, 0x20
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld a, l
	ld (0xbd14:16), l
	cp l, (0xbd16:16)
	ret z
	set 7, a
	ld (0xbd14:16), a
	ret

MidiSeq_CheckSyncDirty:
	lda xbc, (0xbd1c:16)
	bit 6, (0xbd18:16)
	jr z, MidiSeq_CheckSyncDirty_Lower
	ld a, (0xbd00:16)
	cp a, (0xbd02:16)
	jr nz, DSP_Init_ErrorFlagSet
	ld a, (0xbd04:16)
	cp a, (0xbd06:16)
	jr nz, DSP_Init_ErrorFlagSet
	ld a, (0xbd08:16)
	cp a, (0xbd0a:16)
	jr nz, DSP_Init_ErrorFlagSet
	ret

MidiSeq_CheckSyncDirty_Lower:
	ld a, (0xbd0c:16)
	cp a, (0xbd0e:16)
	jr nz, DSP_Init_ErrorFlagSet
	ld a, (0xbd10:16)
	cp a, (0xbd12:16)
	jr nz, DSP_Init_ErrorFlagSet
	ld a, (0xbd14:16)
	cp a, (0xbd16:16)
	ret z

DSP_Init_ErrorFlagSet:
	setm 6, (xbc)
	ret

MidiSeq_PartLookup_Data:
	ld	wa, 0:i3
	call	ParaLoadOpt_PostDualEvent
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 34
	jr	z, MidiSeq_PartLookup_Data_Skip
	cp	l, 0:i3
	jr	nz, MidiSeq_PartLookup_Data_Skip2
	calr	MidiSeq_PartLookup_Data_Helper
	jr	MidiSeq_PartLookup_Data_Entry
MidiSeq_PartLookup_Data_Skip:
	calr	MidiSeq_PartLookup_Data_Helper2
	jr	MidiSeq_PartLookup_Data_Entry
MidiSeq_PartLookup_Data_Skip2:
	calr	MidiSeq_PartLookup_Data_Helper3
MidiSeq_PartLookup_Data_Entry:
	bit	1, (0xbd18:16)
	ret	z
	call	SeqStep_PlaybackNop
	ret
MidiSeq_PartLookup_Data_Helper:
	ld	(GLOBAL_ERROR_CODE:16), 35
	ldw	wa, 238
	jp	SoundCtrl_SendCommand
MidiSeq_PartLookup_Data_Helper2:
	ret
MidiSeq_PartLookup_Data_Helper3:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	extz	hl
	lda	xbc, (MidiRx_PartLookup_ByteMap:24)
	ld	(GLOBAL_ERROR_CODE), (xbc+hl)
	ldw	wa, 238
	jp	SoundCtrl_SendCommand

MidiSeq_ApplyPendingParams:
	bit 6, (0xbd1c:16)
	ret z
	bit 6, (0xbd18:16)
	jr z, MidiSeq_ApplyParams_Lower
	ld a, (0xbd00:16)
	res 7, a
	extz wa
	ld c, (0xbd04:16)
	res 7, c
	extz bc
	ld e, (0xbd08:16)
	res 7, e
	extz de
	call ParaLoadOpt_AudioFlagCheck
	jr MidiSeq_ClearSyncFlag

MidiSeq_ApplyParams_Lower:
	ld a, (0xbd0c:16)
	res 7, a
	extz wa
	ld c, (0xbd10:16)
	res 7, c
	extz bc
	ld e, (0xbd14:16)
	res 7, e
	extz de
	call ParaLoadOpt_AudioFlagCheck_B

MidiSeq_ClearSyncFlag:
	res 6, (0xbd1c:16)
	ret

MidiSeq_PartConfigure_Data:
	ret
	ldw	wa, 238
	jp	SoundCtrl_SendCommand
SysEx_SendDispatch_Helper:
	set	3, (0xbd18:16)
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper
	calr	MidiPkt_ArpConfigChain_Data
	res	3, (0xbd18:16)
	ret
SysEx_ResetAndReturn_Helper:
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper4
	jrl	MidiPkt_ArpConfigChain_Data_Helper7
SysEx_ResetAndReturn_Helper2:
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper5
	jrl	MidiPkt_ArpConfigChain_Data_Join
SysEx_ResetAndReturn_Helper3:
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper3
	jrl	MidiPkt_ArpConfigChain_Data_Helper4
SysEx_ResetAndReturn_Helper4:
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper2
	jrl	MidiPkt_ArpConfigChain_Data_Helper
SysEx_ResetAndReturn_Helper5:
	ret
SysEx_ResetAndReturn_Helper6:
	ld	xwa, 0xbcbc
	call	MidiSeq_ClearSyncFlag_Helper6
	jrl	MidiPkt_ArpConfigChain_Data_Helper14

MidiPkt_ArpMultiPass:
	pushw_erp 0xfa
	res 7, (0xbd18:16)
	ldib_erp 0xfb, 0

MidiPkt_ArpPassLoop:
	ld xwa, SysEx_Msg_35BC
	ld bc, 7:i3
	call SeqBuf_FlushNoteOffs
	set 2, (0xbd18:16)
	call SeqAlt_ProcessAndFinalize
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	call SeqData_ReadFieldByIndex
	cp l, 0x8
	jr z, MidiPkt_ArpPassDone
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, MidiPkt_ArpPassLoop

MidiPkt_ArpPassDone:
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cpib_erp 0xfb, 3
	jr nz, MidiPkt_ArpStoreFieldValues
	ld bc, 4:i3
	ld de, 0:i3
	call MIDI_ReadChannelParam
	jr MidiPkt_ArpPopReturn

MidiPkt_ArpStoreFieldValues:
	ld bc, 6:i3
	call SeqData_ReadFieldByIndex
	ld (0xbc64:16), l
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 7:i3
	call SeqData_ReadFieldByIndex
	ld (0xbc65:16), l
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0x8
	call SeqData_ReadFieldByIndex
	ld (0xbc66:16), l
	ldib_erp 0xfb, 0

MidiPkt_ArpSecondLoop:
	ld xwa, SysEx_Msg_35C4
	ld bc, 7:i3
	call SeqBuf_FlushNoteOffs
	set 2, (0xbd18:16)
	call SeqAlt_ProcessAndFinalize
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	call SeqData_ReadFieldByIndex
	cp l, 1:i3
	jr nz, MidiPkt_ArpSecondLoopNext
	set 7, (0xbd18:16)
	jr MidiPkt_ArpPopReturn

MidiPkt_ArpSecondLoopNext:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, MidiPkt_ArpSecondLoop

MidiPkt_ArpPopReturn:
	popw_erp 0xfa
	ret

MidiPkt_ArpConfigChain_Data:
	calr	MidiPkt_ArpConfigChain_Data_Helper
	calr	MidiPkt_ArpConfigChain_Data_Helper4
	calr	MidiPkt_ArpConfigChain_Data_Helper14
	calr	MidiPkt_ArpConfigChain_Data_Helper7
	jrl	MidiPkt_ArpConfigChain_Data_Join
MidiPkt_ArpConfigChain_Data_Helper:
	calr	MidiPkt_ArpConfigChain_Data_Helper2
	calr	MidiPkt_ArpConfigChain_Data_Helper3
	jrl	MidiPkt_ArpConfigChain_Data_Helper18
MidiPkt_ArpConfigChain_Data_Helper2:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ld	de, 1:i3
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper
	ld	xwa, SysEx_TechMsg_35E2
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper3:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ld	de, 2:i3
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper2
	ld	xwa, SysEx_TechMsg_35EE
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper4:
	ld	wa, 1:i3
	call	AccWrap_ReturnZero
	cp	hl, 0xffff
	ret	z
	calr	MidiPkt_ArpConfigChain_Data_Helper5
	calr	MidiPkt_ArpConfigChain_Data_Helper6
	calr	MidiPkt_ArpConfigChain_Data_Helper18
	ret
MidiPkt_ArpConfigChain_Data_Helper5:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ld	de, 4:i3
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper3
	ld	xwa, SysEx_TechMsg_35FA
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper6:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ld	de, 5:i3
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper4
	ld	xwa, SysEx_TechMsg_3606
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper7:
	ld	wa, 3:i3
	call	AccWrap_ReturnZero
	cp	hl, 0xffff
	ret	z
	calr	MidiPkt_ArpConfigChain_Data_Helper8
	calr	MidiPkt_ArpConfigChain_Data_Helper9
	calr	MidiPkt_ArpConfigChain_Data_Helper10
	calr	MidiPkt_ArpConfigChain_Data_Helper18
	ret
MidiPkt_ArpConfigChain_Data_Helper8:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ld	de, 7:i3
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper5
	ld	xwa, SysEx_TechMsg_3612
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper9:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper6
	ld	xwa, SysEx_TechMsg_361E
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper10:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper7
	ld	xwa, SysEx_TechMsg_362A
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Join:
	ld	wa, 4:i3
	call	AccWrap_ReturnZero
	cp	hl, 0xffff
	ret	z
	calr	MidiPkt_ArpConfigChain_Data_Helper11
	calr	MidiPkt_ArpConfigChain_Data_Helper12
	calr	MidiPkt_ArpConfigChain_Data_Helper13
	calr	MidiPkt_ArpConfigChain_Data_Helper18
	ret
MidiPkt_ArpConfigChain_Data_Helper11:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 11
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper8
	ld	xwa, SysEx_TechMsg_3634
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper12:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper9
	ld	xwa, SysEx_TechMsg_3640
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper13:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 13
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper10
	ld	xwa, SysEx_TechMsg_364C
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
	ret
	ret
	ret
MidiPkt_ArpConfigChain_Data_Helper14:
	calr	MidiPkt_ArpConfigChain_Data_Helper15
	calr	MidiPkt_ArpConfigChain_Data_Helper16
	calr	MidiPkt_ArpConfigChain_Data_Helper17
	jrl	MidiPkt_ArpConfigChain_Data_Helper18
MidiPkt_ArpConfigChain_Data_Helper15:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 18
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper11
	ld	xwa, SysEx_TechMsg_3656
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper16:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper12
	ld	xwa, SysEx_TechMsg_3662
	ldw	bc, 12
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper17:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	ld	bc, 3:i3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	ld	xwa, 0xbccc
	call	MidiPkt_ArpPopReturn_Helper13
	ld	xwa, SysEx_TechMsg_366E
	ldw	bc, 9
	call	SeqBuf_FlushNoteOffs
	call	ArpQueue_Pack21BitValue
	call	ArpQueue_ProcessAndSort_Data
	ret
MidiPkt_ArpConfigChain_Data_Helper18:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (0xbcb4:16)
	incm8	1, (xwa+3)
	ld	xwa, SysEx_Msg_35A0
	ld	bc, 5:i3
	call	SeqBuf_FlushNoteOffs
	call	MidiStream_PrevBankCheck
	ret
SysEx_SendDispatch_Helper2:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpConfigChain_Data_Skip
	ld	xwa, SysEx_Msg_35A6
	ld	bc, 5:i3
	call	SeqBuf_FlushNoteOffs
	call	MidiStream_PrevBankCheck
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 24
	ret	nz
	ld	xwa, SysEx_Msg_35AC
	ld	bc, 5:i3
	jr	MidiPkt_ArpConfigChain_Data_Join2
MidiPkt_ArpConfigChain_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 24
	ret	nz
	ld	xwa, SysEx_Msg_35AC
	ld	bc, 5:i3
MidiPkt_ArpConfigChain_Data_Join2:
	call	SeqBuf_FlushNoteOffs
	ret
MidiPkt_ArpChordHandler:
	; --- Main: guard check, loop with bit 4 flag, multiple calls (76 bytes) ---
	cp	(CURRENT_TITLE:16), 87
	jr nz, ArpChord_ClearBitAndReturn
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 0:i3
	call SeqData_ReadFieldByIndex
	cp	l, 7:i3
	jr c, ArpChord_ClearBitAndReturn
	set	4, (0xbd18:16)
	call MidiChan_ClearAllStates
	jr t, ArpChord_DispatchAndLoop
ArpChord_CheckPlaybackDone:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr z, ArpChord_ProcessAndDispatch
	res	4, (0xbd18:16)
	jr t, ArpChord_FinalizePass
ArpChord_ProcessAndDispatch:
	call SeqAlt_ProcessAndFinalize
ArpChord_DispatchAndLoop:
	calr MidiTable_DispatchHelper
	bit	4, (0xbd18:16)
	jr nz, ArpChord_CheckPlaybackDone
ArpChord_FinalizePass:
	calr	MidiPkt_ArpChordHandler_Helper
	call MidiSeq_PartLookup_Data
ArpChord_ClearBitAndReturn:
	res	4, (0xbd18:16)
	ret
; MIDI table dispatch helper
MidiTable_DispatchHelper:
	; --- Helper 1: table dispatch via (XBC+WA) with guard checks (58 bytes) ---
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	call SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret nz
	call MidiSeq_PartConfigure_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp (xwa), 0x27
	ret nc
	ld a, (xwa)
	extz wa
	sla	wa, 2
	lda xbc, (SeqChan_CommandDispatch_Table:24)
	ld	xhl, (xbc+wa)
	call	(xhl)
	calr MidiTable_FlushArpNotes
	call MidiSeq_UpdateAllParams
	call MidiTable_DispatchHelper_Helper
	ret
MidiTable_FlushArpNotes:
	; --- Helper 2: conditional A-based 3-way pointer selection (56 bytes) ---
	bit	7, (0xbd18:16)
	ret z
	call ArpQueue_SwapBuffers
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld a, (xwa+4)
	cp	a, 0:i3
	jr nz, MidiTable_CheckSpecialSlot
	ld xwa, SysEx_Msg_3594
	ld	bc, 5:i3
	jr t, MidiTable_CallFlush
MidiTable_CheckSpecialSlot:
	cp a, 0x16
	jr nz, MidiTable_UseDefaultBuf
	ld xwa, SysEx_Msg_35B2
	ld	bc, 5:i3
	jr t, MidiTable_CallFlush
MidiTable_UseDefaultBuf:
	ld xwa, SysEx_Msg_359A
	ld	bc, 5:i3
MidiTable_CallFlush:
	call SeqBuf_FlushNoteOffs
	ret


MidiPkt_InitSingleField_Data:
	cp	(0xbd20:16), 0
	ret	nz
	ld	(0xbd20:16), 1
	ld	xwa, SysEx_Msg_35C4
	ld	bc, 7:i3
	call	SeqBuf_FlushNoteOffs
	ret
MidiPkt_HandleCmdCode01:
	; --- Two-path: 3x field extraction or single store (73 bytes) ---
	cp	(0xbd20:16), 1
	jr nz, MidiPkt_SetSlot18
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 6:i3
	call SeqData_ReadFieldByIndex
	ld	(0xbc68:16), l
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 7:i3
	call SeqData_ReadFieldByIndex
	ld	(0xbc69:16), l
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw bc, 0x0008
	call SeqData_ReadFieldByIndex
	ld	(0xbc6a:16), l
	set	7, (0xbd18:16)
	ld	(0xbd20:16), 2
	ret
MidiPkt_SetSlot18:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld (xwa+4), 0x18
	res	4, (0xbd18:16)
	ret


MidiPkt_ArpExtHandler_A:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpExtHandler_A_Skip
	call	MidiChan_TimerDispatch_Data
	ld	xwa, 0xbcdc
	call	MidiSeq_ClearSyncFlag_Helper2
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper
	jrl	SeqChan_StepCmd_Field1to2
MidiPkt_ArpExtHandler_A_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_B_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 2:i3
	jr	nz, MidiPkt_ArpExtHandler_B_Data_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper2
	jrl	SeqChan_StepCmd_Field2to3
MidiPkt_ArpExtHandler_B_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_C_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpExtHandler_C_Data_Skip
	ld	xwa, 0xbcdc
	call	MidiSeq_ClearSyncFlag_Helper3
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper3
	jrl	SeqChan_StepCmd_Field4to5
MidiPkt_ArpExtHandler_C_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 26
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_D_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 5:i3
	jr	nz, MidiPkt_ArpExtHandler_D_Data_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper4
	jrl	SeqChan_StepCmd_Field5to6
MidiPkt_ArpExtHandler_D_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 25
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_E_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpExtHandler_E_Data_Skip
	call	MidiPkt_ArpExtHandler_A_Helper
	ld	xwa, 0xbcdc
	call	MidiSeq_ClearSyncFlag_Helper4
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper5
	jrl	SeqChan_StepCmd_Field6_Data
MidiPkt_ArpExtHandler_E_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_F_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 8
	jr	nz, MidiPkt_ArpExtHandler_F_Data_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper6
	jrl	SeqChan_StepCmd_Field8to9
MidiPkt_ArpExtHandler_F_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_G:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 9
	jr	nz, MidiPkt_ArpExtHandler_G_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper7
	call	MidiPkt_ArpExtHandler_G_Helper
	jrl	SeqChan_StepCmd_Field9to10
MidiPkt_ArpExtHandler_G_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 27
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_H_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpExtHandler_H_Data_Skip
	call	MidiPkt_ArpExtHandler_G_Helper2
	ld	xwa, 0xbcdc
	call	MidiSeq_ClearSyncFlag_Helper6
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper11
	jrl	SeqChan_StepCmd_Field10_Data
MidiPkt_ArpExtHandler_H_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_I_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 19
	jr	nz, MidiPkt_ArpExtHandler_I_Data_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper12
	jrl	SeqChan_StepCmd_Field13_Data
MidiPkt_ArpExtHandler_I_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_J:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 20
	jr	nz, MidiPkt_ArpExtHandler_J_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper13
	call	MidiPkt_ArpExtHandler_G_Helper
	jrl	SeqChan_StepCmd_Field20to21
MidiPkt_ArpExtHandler_J_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 30
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_K:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	jr	nz, MidiPkt_ArpExtHandler_K_Skip
	ld	xwa, 0xbcdc
	call	MidiSeq_ClearSyncFlag_Helper5
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper8
	jrl	SeqChan_StepCmd_Field11_Data
MidiPkt_ArpExtHandler_K_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_L:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 12
	jr	nz, MidiPkt_ArpExtHandler_L_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper9
	jrl	SeqChan_StepCmd_Field12_Data
MidiPkt_ArpExtHandler_L_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_ArpExtHandler_M_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 13
	jr	nz, MidiPkt_ArpExtHandler_M_Data_Skip
	ld	xwa, 0xbcec
	call	MidiPkt_ArpPopReturn_Helper10
	call	MidiPkt_ArpExtHandler_G_Helper
	jrl	SeqChan_StepCmd_Field13Write
MidiPkt_ArpExtHandler_M_Data_Skip:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 28
	jp	MIDI_ReadChannelParam
MidiPkt_RetStub_A:
	ret
MidiPkt_RetStub_B:
	ret
MidiPkt_ArpExtHandler_N_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	bc, 3:i3
	call	SeqData_ReadFieldByIndex
	cp	l, 22
	ret	nc
	extz	hl
	sla	hl, 2
	lda	xbc, (SeqChan_StepCmdHandlers:24)
	ld	xhl, (xbc+hl)
	call (xhl)
	ret
SeqChan_ProcessStepCmd:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 19
	jp	MIDI_ReadChannelParam
SeqChan_StepCmd_Field1to2:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 1:i3
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 2:i3
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field2to3:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 2:i3
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 3:i3
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field4to5:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 4:i3
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 5:i3
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field5to6:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 5:i3
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	call	TmFlash_BulkTransferToSubCPU
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 6:i3
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field6_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 7:i3
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field8to9:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 8
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field9to10:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 9
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 10
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field10_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 18
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field13_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 19
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field20to21:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 20
	call	MIDI_ReadChannelParam
	call	SeqVoice_DispatchProcess_Data
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 21
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field11_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 11
	call	MIDI_ReadChannelParam
	ld	wa, 4:i3
	call	AccWrap_ReturnZero
	cp	hl, 0xffff
	call	nz, (0xfd6c8d:24)
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field12_Data:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 12
	call	MIDI_ReadChannelParam
	ld	wa, 4:i3
	call	AccWrap_ReturnZero
	cp	hl, 0xffff
	call	nz, (0xfd6c8d:24)
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 15
	call	SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw	de, 13
	call	MIDI_ReadChannelParam
	ret
SeqChan_StepCmd_Field13Write:
	; --- Section 1: load XWA, setup BC/DE, call, then compare HL ---
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw de, 0x000d
	call MIDI_ReadChannelParam
	ld	wa, 4:i3
	call AccWrap_ReturnZero
	cp hl, 0xffff
	call	nz, (0xfd6c8d:24)
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	; --- Section 2: reload XWA, setup BC, call, check L ---
	ldw bc, 0x000f
	call SeqData_ReadFieldByIndex
	cp	l, 0:i3
	ret nz
	; --- Section 3: reload XWA, setup BC/DE, call ---
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ldw de, 0x000e
	call MIDI_ReadChannelParam
	ret


SeqChan_RetStub_A:
	ret
SeqChan_RetStub_B:
	ret
SeqChan_DispatchByType_Data:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	a, (xwa+3)
	cp	a, 22
	ret	nc
	extz	wa
	sla	wa, 2
	lda	xbc, (SeqChan_WriteFieldHandlers:24)
	ld	xhl, (xbc+wa)
	call	(xhl)
	res	7, (0xbd1c:16)
	ret
SeqChan_DefaultHandler:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 4:i3
	ldw	de, 31
	jp	MIDI_ReadChannelParam
SeqChan_WriteField_Data_A:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	set	7, (0xbd1a:16)
	ret
SeqChan_WriteField_Data_B:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	set	6, (0xbd1a:16)
	ret
SeqChan_WriteField_Data_C:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	set	5, (0xbd1a:16)
	ret
SeqChan_WriteField_Data_D:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	set	4, (0xbd1a:16)
	ret
SeqChan_RetStub_C:
	ret
SeqChan_WriteField_Data_E:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	set	2, (0xbd1a:16)
	ret
; MIDI SysEx processing block with dispatch
MidiSysEx_ProcessBlock:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 3:i3
	ld	de, 0:i3
	call	MIDI_ReadChannelParam
	res	4, (0xbd18:16)
	calr	MidiSysEx_ProcessBlock_Helper4
	calr	MidiSysEx_ProcessBlock_Helper7
	calr	MidiSysEx_ProcessBlock_Helper8
	calr	MidiSysEx_ProcessBlock_Helper9
	calr	MidiSysEx_ProcessBlock_Helper10
	jrl	MidiSysEx_ProcessBlock_Join
MidiSysEx_ProcessBlock_Helper:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_DSPCfg_Initialize
	call	ToneGen_Config_InitAndChannels
	call	ToneGen_InitAllChannelEntries_Skip
	call	ToneGen_DispatchByMode
	ld	wa, 3:i3
	call	BitMapOut_GetRenderMode_CheckBit3
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiSysEx_ProcessBlock_Helper2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SoundParam_NotifyMultipleChanges
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiSysEx_ProcessBlock_Helper3:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	call	SwbtWr_CallProcessAll
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	res	0, (4330:16)
	ld	wa, 3:i3
	call	BitMapOut_GetRenderMode_Return
	set	4, (0x90f9:16)
	call	SeqTimer_UpdateTempoReg
	res	4, (0x90f9:16)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiSysEx_ProcessBlock_Helper4:
	bit	7, (0xbd1a:16)
	ret	z
	calr	MidiSysEx_ProcessBlock_Helper
	calr	MidiSysEx_ProcessBlock_Helper5
	calr	MidiSysEx_ProcessBlock_Helper2
	calr	MidiSysEx_ProcessBlock_Helper5
	calr	MidiSysEx_ProcessBlock_Helper3
	calr	MidiSysEx_ProcessBlock_Helper5
	res	7, (0xbd1a:16)
	ret
MidiSysEx_ProcessBlock_Helper5:
	bit	4, (0xbd1a:16)
	ret	z
	set	0, (4330:16)
	ret
MidiSysEx_ProcessBlock_Helper6:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MIDI_PitchBendData_Block
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiSysEx_ProcessBlock_Helper7:
	dec	6, xsp
	ld	xiy, MidiSysEx_BlockTemplate
	ld	xix, xsp
	ld	bc, 3:i3
	ldirw
	bit	6, (0xbd1a:16)
	jr	z, MidiSysEx_ProcessBlock_Epilogue
	calr	MidiSysEx_ProcessBlock_Helper6
	res	6, (0xbd1a:16)
MidiSysEx_ProcessBlock_Epilogue:
	inc	6, xsp
	ret
MidiSysEx_ProcessBlock_Helper8:
	bit	5, (0xbd1a:16)
	ret	z
	res	0, (0x32f3:16)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccPatch_MultiCallWrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	res	5, (0xbd1a:16)
	ret
MidiSysEx_ProcessBlock_Helper9:
	bit	4, (0xbd1a:16)
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	MidiSysEx_ProcessBlock_Helper13
	call	ToneGen_InitAllChannelEntries_Skip
	call	MidiSysEx_ProcessBlock_Helper12
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	set	1, (0xbd18:16)
	res	4, (0xbd1a:16)
	ret
MidiSysEx_ProcessBlock_Helper10:
	ret
MidiSysEx_ProcessBlock_Join:
	bit	2, (0xbd1a:16)
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Voice_InitBankDataSafe_Alt1
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	res	2, (0xbd1a:16)
	ret
SeqChan_UnhandledCmd:
	ret
SeqChan_UnhandledCmd_0x01:
	ret
SeqChan_UnhandledCmd_0x02:
	ret
SeqChan_UnhandledCmd_0x03:
	ret
MidiPkt_ArpChordHandler_Helper:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp	(xwa+4), 0
	ret	z
	calr	MidiSysEx_ProcessBlock_Helper11
	ret
SeqChan_UnhandledCmd_0x12:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	(xwa+4), 23
	jr	MidiSysEx_ProcessBlock_Helper11
MidiSysEx_ProcessBlock_Helper11:
	ld	xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld	a, (xwa+3)
	cp	a, 22
	ret	nc
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiSysEx_BlockHandlers:24)
	ld	xhl, (xbc+wa)
	call	(xhl)
	ret
	ret
	jp	SeqChan_UnhandledCmd_Join
	jp	SeqChan_UnhandledCmd_Join2
	jp	SeqChan_UnhandledCmd_Join3
	jp	SeqChan_UnhandledCmd_Join4
	ret
	jp	SeqChan_UnhandledCmd_Join5
SeqChan_UnhandledCmd_Join:
	set	4, (0x90f9:16)
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xhl, (MidiSysEx_ProcessBlock_Data:24)
	call	(xhl)
	call	MidiMsg_ParseChannelStream
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	res	4, (0x90f9:16)
	ret
SeqChan_UnhandledCmd_Join2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SendPartDataBlock_DoGetError
	call	MIDI_PitchBendData_Block
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_ArpExtHandler_A_Helper:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccDemo_InitWithFlag
	res	0, (0x32f3:16)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
SeqChan_UnhandledCmd_Join3:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccDemo_InitDone
	res	0, (0x32f3:16)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
SeqChan_UnhandledCmd_Join4:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	xhl, (MidiSysEx_ProcessBlock_PtrTable:24)
	call	(xhl)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
MidiPkt_ArpExtHandler_G_Helper2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqChan_UnhandledCmd_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
SeqChan_UnhandledCmd_Join5:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Voice_InitBankDataSafe
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret

SeqAlt_CheckInitBuffer:
	cp (CURRENT_TITLE:16), 87
	ret nz
	ei 6
	call SeqMain_InitBuffer
	ei 0
	ret

SeqBuf2_InitWithInterrupts:
	ei 6
	call SeqBuf2_Init
	ei 0
	ret

SeqBuf_Timing_Data:
	ei	6
	call	SeqBuf_MidiOut_Init
	ei	0
	ret

MidiChan_ClearStorageFields:
	lda xwa, (0xbc68:16)
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	ld (xwa + 2), 0xff
	lda xwa, (0xbc64:16)
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	ld (xwa + 2), 0xff
	ret

MidiChan_InitAllBufferPtrs:
	lda xwa, (0xb7f4:16)
	ld (MIDISEQ_ACTIVE_BLOCK_PTR:16), xwa
	lda xbc, (0xbc6c:16)
	ld (MIDISEQ_ACTIVE_BUF_PTR:16), xbc
	lda xde, (0xb90c:16)
	ld (MIDISEQ_SPARE_BLOCK_PTR:16), xde
	lda xde, (0xbc7c:16)
	ld (MIDISEQ_SPARE_BUF_PTR:16), xde
	lda xde, (0xba24:16)
	ld (0xbc5c:16), xde
	lda xde, (0xbc8c:16)
	ld (0xbcb4:16), xde
	lda xde, (0xbb3c:16)
	ld (0xbc60:16), xde
	lda xde, (0xbc9c:16)
	ld (0xbcb8:16), xde
	calr ArpQueue_InitBuffer
	ld xwa, (MIDISEQ_SPARE_BLOCK_PTR:16)
	ld xbc, (MIDISEQ_SPARE_BUF_PTR:16)
	calr ArpQueue_InitBuffer
	ld xwa, (0xbc5c:16)
	ld xbc, (0xbcb4:16)
	calr ArpQueue_InitBuffer
	ld xwa, (0xbc60:16)
	ld xbc, (0xbcb8:16)
	jr ArpQueue_InitBuffer

ArpQueue_InitBuffer:
	ld xde, xbc
	ldw (xwa), 0x0
	lda xbc, (xwa + 14)
	ld (xwa + 2), xbc
	ld (xwa + 6), xbc
	ld (xwa + 10), xbc
	ld (xbc), 0xff
	ld xiy, ArpQueue_InitTemplate
	ld xix, xde
	ldw bc, 0x8
	ldirw
	ret

MidiSeq_SwapActiveBuffers:
	ld xbc, (MIDISEQ_ACTIVE_BUF_PTR:16)
	cp (xbc + 4), 0x0
	jr nz, MidiSeq_SwapBuffersFallthru
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda xde, (xwa + 14)
	cp xde, (xwa + 10)
	jr z, MidiSeq_SwapBuffersFallthru
	ld xwa, (MIDISEQ_SPARE_BUF_PTR:16)
	ld (MIDISEQ_SPARE_BUF_PTR:16), xbc
	ld (MIDISEQ_ACTIVE_BUF_PTR:16), xwa
	ld xbc, (MIDISEQ_SPARE_BLOCK_PTR:16)
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld (MIDISEQ_SPARE_BLOCK_PTR:16), xwa
	ld (MIDISEQ_ACTIVE_BLOCK_PTR:16), xbc

MidiSeq_SwapBuffersFallthru:
	jr MidiSeq_ReinitCurrentBuffer

ArpQueue_SwapBuffers:
	ld xbc, (0xbcb4:16)
	cp (xbc + 4), 0x0
	jr nz, ArpQueue_SwapFallthru
	ld xwa, (0xbc5c:16)
	lda xde, (xwa + 14)
	cp xde, (xwa + 10)
	jr z, ArpQueue_SwapFallthru
	ld xwa, (0xbcb8:16)
	ld (0xbcb8:16), xbc
	ld (0xbcb4:16), xwa
	ld xbc, (0xbc60:16)
	ld xwa, (0xbc5c:16)
	ld (0xbc60:16), xwa
	ld (0xbc5c:16), xbc
	calr ArpQueue_ReinitCurrentBuffer
	ld xbc, (0xbcb4:16)
	ld xwa, (0xbcb8:16)
	ld a, (xwa + 3)
	ld (xbc + 3), a
	ret

ArpQueue_SwapFallthru:
	jr ArpQueue_ReinitCurrentBuffer

MidiSeq_ReinitCurrentBuffer:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld xbc, (MIDISEQ_ACTIVE_BUF_PTR:16)
	jrl ArpQueue_InitBuffer

ArpQueue_ReinitCurrentBuffer:
	ld xwa, (0xbc5c:16)
	ld xbc, (0xbcb4:16)
	jrl ArpQueue_InitBuffer

MidiChan_InitSoundRegisters:
	ld xiy, MidiChan_ZeroRegTemplate
	ld xix, 0xbcbc
	ldw bc, 0x8
	ldirw
	ld xiy, MidiChan_ZeroRegTemplate
	ld xix, 0xbccc
	ldw bc, 0x8
	ldirw
	ld xiy, MidiChan_ZeroRegTemplate
	ld xix, 0xbcdc
	ldw bc, 0x8
	ldirw
	ld xiy, MidiChan_ZeroRegTemplate
	ld xix, 0xbcec
	ldw bc, 0x8
	ldirw
	ret

SoundMode_ResetAllParams:
	calr MidiChan_InitAllBufferPtrs
	calr MidiChan_ClearStorageFields
	calr MidiChan_InitSoundRegisters
	ld (0xbd18:16), 0
	ld (0xbd1a:16), 0
	ld (0xbd1c:16), 0
	ld (0xbd1e:16), 0
	ld (0xbd20:16), 0
	ld (0xbcfc:16), 0
	ld (0xbd00:16), 0
	ret

SoundMode_ResetJump:
	jr SoundMode_ResetAllParams

SoundMode_ResetJump2:
	jr SoundMode_ResetJump

SoundMode_RetStub_A:
	ret

SoundMode_RetStub_B:
	ret

SoundMode_RetStub_C:
	ret

SoundMode_RetStub_D:
	ret

SoundMode_ApplyVoiceParams:
	ld wa, 2:i3
	ld xbc, 0xf980
	call SysEx_ApplyVoiceParam_49
	ld wa, 4:i3
	ld xbc, 0xf980
	call SysEx_ApplyVoiceParam_4B
	lda xbc, (0x918d:16)
	ld xwa, xbc
	lda xbc, (xbc + 31)

SoundMode_VoiceIterLoop:
	ld (xwa+), 0x23
	cp xwa, xbc
	jr ule, SoundMode_VoiceIterLoop
	ret

SoundMode_RetStub_E:
	ret

SoundMode_RetStub_F:
	ret

SoundMode_RetStub_G:
	ret

SoundMode_RetStub_H:
	ret

SoundMode_SysExConfig_Data:
	bit	4, (0xfd50:16)
	ret	nz
	and	wa, 511
	lda	xbc, (0xfc5a:16)
	ld	l, a
	ld	(xbc+8), l
	lda	xde, (xbc+9)
	ld	c, (xde)
	res	0, c
	ld	(xde), c
	srl	wa, 8
	or	c, a
	ld	(xde), c
	ld	(MIDI_MSG_STATUS:16), 72
	ld	(MIDI_MSG_DATA1:16), 8
	ld	(MIDI_MSG_DATA2:16), l
	ld	(MIDI_MSG_DATA3:16), 255
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_WriteParamBlock
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	set	4, (0x90f9:16)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	res	4, (0x90f9:16)
	ret

SoundMode_DispatchRender:
	dec 2, xsp
	ld (xsp), a
	set 0, (0xb7ee:16)
	push xde
	push xhl
	push xix
	push xiz
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	cp (xsp), 0x2
	jr z, SoundMode_DispatchRender_2
	cp (xsp), 0x1
	jr z, SoundMode_DispatchRender_1
	calr SoundMode_RenderWithNotify
	jr SoundMode_PostRender

SoundMode_DispatchRender_1:
	calr SoundMode_FullRenderUpdate
	jr SoundMode_PostRender

SoundMode_DispatchRender_2:
	calr SoundMode_AlternateRender

SoundMode_PostRender:
	call BitMapOut_ComputeRegionDelta
	lda xde, (0x03c8e4:24)
	lda xbc, (0xf9a0:16)
	ld xhl, xbc
	lda xwa, (0xffbe:16)
	sub xwa, xbc
	inc 2, xwa
	ld xbc, xwa
	srl xbc, 1
	ld xwa, xbc
	dec 1, xbc
	or xwa, xwa
	jr z, SoundMode_CopyBitmapDone

SoundMode_CopyBitmapLoop:
	ld WA, (xde+)
	ld (xhl+), WA
	ld xwa, xbc
	dec 1, xbc
	or xwa, xwa
	jr nz, SoundMode_CopyBitmapLoop

SoundMode_CopyBitmapDone:
	res 0, (0xb7ee:16)
	inc 2, xsp
	ret

SoundMode_FullRenderUpdate:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_RetStub_D
	calr TGReg_WriteCC0_Volume
	calr SoundMode_RetStub_G
	calr TGReg_WriteCC3_Expression
	calr TGReg_WriteCC4_Pan
	calr TGReg_WriteCC5_Modulation
	calr TGReg_WriteCC4_Sustain
	calr TGReg_WriteCC6_RetStub
	calr TGReg_WriteCC7_Reverb
	calr TGReg_WriteCC8_Chorus
	calr TGReg_WriteCC9_Variation
	calr TGReg_WriteCC10_KeyShift
	calr TGReg_WriteCC11_PartMode
	calr SoundMode_SetReverbType
	calr VoiceData_ZeroFillAll
	calr SoundParam_ApplyBit15Toggle
	calr TGReg_WriteCC12_Assign
	calr SoundMode_ApplyVoiceParams
	jrl VoiceData_SyncAllToHardware

SoundMode_RenderWithNotify:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	ld a, (CURRENT_TITLE:16)
	cp a, 0x76
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x72
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x73
	jr z, SoundMode_NotifyActiveVoices
	cp a, 0x6f
	jr nz, SoundMode_RenderPopRegs

SoundMode_NotifyActiveVoices:
	ld xwa, 0x2201
	ld bc, 1:i3
	ld de, 0:i3
	call SoundParam_NotifyChange
	ld xwa, 0x2205
	ld bc, 1:i3
	ld de, 0:i3
	call SoundParam_NotifyChange

SoundMode_RenderPopRegs:
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_SetChorusType
	calr SoundMode_RetStub_H
	calr SoundParam_Bit15Jump
	jrl VoiceData_SyncAllToHardware

SoundMode_AlternateRender:
	push xde
	push xhl
	push xix
	push xiz
	call Display_SetupAndPrepareRender
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SoundMode_RetStub_D
	calr TGReg_WriteCC0_AltMask
	calr SoundMode_RetStub_H
	calr TGReg_WriteCC3_Expression
	calr TGReg_WriteCC4_Pan
	calr TGReg_WriteCC5_Modulation
	calr TGReg_WriteCC4_Sustain
	calr TGReg_WriteCC6_RetStub
	calr TGReg_WriteCC7_Reverb
	calr TGReg_WriteCC8_Chorus
	calr TGReg_WriteCC9_Variation
	calr TGReg_WriteCC10_KeyShift
	calr TGReg_WriteCC11_PartMode
	calr VoiceData_ZeroFillAll
	calr SoundParam_ApplyBit15Toggle
	calr SoundMode_ApplyVoiceParams
	jrl VoiceData_SyncAllToHardware
MidiCtrl_ModeSwitchHandler:
	cp (SWBTWR_PAYLOAD_1:16), 3
	ret nz
	ld a, (SWBTWR_PAYLOAD_3:16)
	bit 2, a
	jr z, MidiCtrl_CheckAltCommand
	ld a, (0xb7ee:16)
	bit 0, a
	ret nz
	set 0, a
	ld (0xb7ee:16), a
	ld wa, (4597:16)
	bit 15, wa
	jr nz, MidiCtrl_ApplyModeSwitch
	push xde
	push xhl
	push xix
	push xiz
	call AccWrap_PlayModeDispatch
	call AccompSeq_StopSequence
	pop xiz
	pop xix
	pop xhl
	pop xde

MidiCtrl_ApplyModeSwitch:
	ld a, (SWBTWR_PAYLOAD_2:16)
	extz wa
	calr MidiCtrl_Bit2ToChannel
	ld a, (SWBTWR_PAYLOAD_2:16)
	extz wa
	calr MidiCtrl_SendControlPacket
	calr MidiCtrl_FullReconfigure
	res 0, (0xb7ee:16)
	ret

MidiCtrl_CheckAltCommand:
	cp (SWBTWR_PAYLOAD_2:16), 4
	ret nz
	cp a, 0:i3
	ret nz
	calr SwbtWr_InitAndWriteAllBlocks
	ret

MidiCtrl_FullReconfigure:
	pushw_erp 0xfa
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_DSPCfg_Initialize
	call SndParam_SyncDisplayBitmap
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld a, (0xfc5f:16)
	ldfr_berp A, 0xfb
	bit 2, (SWBTWR_PAYLOAD_2:16)
	jr z, MidiCtrl_RenderAndProcess
	calr SoundMode_RetStub_E
	calr SoundMode_FullRenderUpdate
	bit 0, (4330:16)
	jr nz, SoundMode_ProcessToneAndParams
	ld a, (CURRENT_TITLE:16)
	cp a, 0x76
	jr ugt, MidiCtrl_DeltaAndProcess
	cp a, 0x6c
	jr nc, SoundMode_ProcessToneAndParams

MidiCtrl_DeltaAndProcess:
	call BitMapOut_ComputeRegionDelta
	jr SoundMode_ProcessToneAndParams

MidiCtrl_RenderAndProcess:
	calr SoundMode_RenderWithNotify
	calr SoundMode_RetStub_F

SoundMode_ProcessToneAndParams:
	calr TGReg_ClearTerminator
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_DSPCfg_Initialize
	call ToneGen_Config_InitAllEntries
	call Voice_InitAllChannelEntries
	call ToneGen_DispatchByMode
	ld wa, 3:i3
	call BitMapOut_GetRenderMode_CheckBit3
	call SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call SwbtWr_CallProcessAll
	ld wa, 3:i3
	call BitMapOut_GetRenderMode_Return
	set 4, (0x90f9:16)
	call SeqTimer_UpdateTempoReg
	res 4, (0x90f9:16)
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr SwbtWr_InitAndWrite_CC_B1
	calr SwbtWr_WriteLoop_CC_B1_Ret
	calr SwbtWr_InitAndWrite_CC_B2
	calr SwbtWr_InitAndWriteAllBlocks
	calr SwbtWr_StubRet_A
	calr SwbtWr_StubRet_B
	calr SwbtWr_StubRet_C
	calr SwbtWr_WriteBankSelect
	calr MidiBuf_CalcFillRange
	lda xde, (0xfc5f:16)
	ld c, (xde)
	res 0, c
	ld (xde), c
	ldto_berp A, 0xfb
	and a, 0x1
	or c, a
	ld (xde), c
	popw_erp 0xfa
	ret

TGReg_ClearTerminator:
	lda xwa, (0xf9b6:16)
	sub xwa, 0xf9b4
	lda xbc, (0x03c8e4:24)
	add xwa, xbc
	ld (xwa), 0xff
	ret

TGReg_WriteCC0_Volume:
	dec 4, xsp
	ld (xsp + 0:8), 0x0
	jr TGReg_WriteCC0_Check

TGReg_WriteCC0_Body:
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC0_Check:
	lda xwa, (xsp)
	lda xbc, (xwa + 1)
	lda xde, (xwa + 2)
	lda xhl, (xwa + 3)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC0_Body
	ld (xwa), 0xf
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa), 0xf
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x78
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	inc 4, xsp
	ret

TGReg_WriteCC0_AltMask:
	dec 4, xsp
	ld (xsp + 0:8), 0x0
	jr TGReg_WriteCC0_AltCheck

TGReg_WriteCC0_AltBody:
	ld (xbc), 0x0
	ld (xde), 0x0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC0_AltCheck:
	lda xwa, (xsp)
	lda xbc, (xwa + 1)
	lda xde, (xwa + 2)
	lda xhl, (xwa + 3)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC0_AltBody
	ld (xwa), 0xf
	ld (xbc), 0x0
	ld (xde), 0xf0
	ld (xhl), 0xff
	call MidiTG_WriteRegByDescriptor
	lda xwa, (xsp)
	ld (xwa), 0xf
	ld (xwa + 1), 0x1
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	call MidiTG_WriteRegByDescriptor
	inc 4, xsp
	ret

TGReg_WriteCC3_Expression:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x3
	ld (xwa + 2), 0x64
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC3_Check

TGReg_WriteCC3_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC3_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC3_Body
	inc 4, xsp
	ret

TGReg_WriteCC4_Pan:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x4
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x8
	ld (xwa), 0x0
	jr TGReg_WriteCC4_Check

TGReg_WriteCC4_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC4_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC4_Body
	inc 4, xsp
	ret

TGReg_WriteCC5_Modulation:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x5
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC5_Check

TGReg_WriteCC5_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC5_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC5_Body
	inc 4, xsp
	ret

TGReg_WriteCC4_Sustain:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x4
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x40
	ld (xwa), 0x0
	jr TGReg_WriteCC4_SustainCheck

TGReg_WriteCC4_SustainBody:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC4_SustainCheck:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC4_SustainBody
	inc 4, xsp
	ret

TGReg_WriteCC6_RetStub:
	ret

TGReg_WriteCC7_Reverb:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x7
	ld (xwa + 2), 0x28
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC7_Check

TGReg_WriteCC7_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC7_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC7_Body
	inc 4, xsp
	ret

TGReg_WriteCC8_Chorus:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x8
	ld (xwa + 2), 0x40
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC8_Check

TGReg_WriteCC8_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC8_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC8_Body
	inc 4, xsp
	ret

TGReg_WriteCC9_Variation:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0x9
	ld (xwa + 2), 0x40
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC9_Check

TGReg_WriteCC9_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC9_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC9_Body
	inc 4, xsp
	ret

TGReg_WriteCC10_KeyShift:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0xa
	ld (xwa + 2), 0x80
	ld (xwa + 3), 0xff
	ld (xwa), 0x0
	jr TGReg_WriteCC10_Check

TGReg_WriteCC10_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC10_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC10_Body
	inc 4, xsp
	ret

TGReg_WriteCC11_PartMode:
	dec 4, xsp
	lda xwa, (xsp)
	ld (xwa + 1), 0xb
	ld (xwa + 2), 0x2
	ld (xwa + 3), 0x7f
	ld (xwa), 0x0
	jr TGReg_WriteCC11_Check

TGReg_WriteCC11_Body:
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC11_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC11_Body
	inc 4, xsp
	ret

SoundMode_SetReverbType:
	ld a, (0x0340f8:24)
	cp a, 3:i3
	jr z, SoundMode_ReverbType3
	cp a, 2:i3
	jr z, SoundMode_ReverbType2
	cp a, 1:i3
	jr z, SoundMode_ReverbType1
	ld (0xb7ec:16), 128
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType1:
	ld (0xb7ec:16), 155
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType2:
	ld (0xb7ec:16), 156
	jr SoundParam_SyncAndReturn

SoundMode_ReverbType3:
	ld (0xb7ec:16), 157

SoundParam_SyncAndReturn:
	jp SndParam_ApplyAndSync

SoundMode_SetChorusType:
	ld a, (0x0340f9:24)
	cp a, 3:i3
	jr z, SoundMode_ChorusType3
	cp a, 2:i3
	jr z, SoundMode_ChorusType2
	cp a, 1:i3
	ret nz
	ld (0xb7ec:16), 91
	jr SoundMode_ChorusSyncAndRet

SoundMode_ChorusType2:
	ld (0xb7ec:16), 92
	jr SoundMode_ChorusSyncAndRet

SoundMode_ChorusType3:
	ld (0xb7ec:16), 93

SoundMode_ChorusSyncAndRet:
	jp SndParam_ApplyAndSync

VoiceData_ZeroFillAll:
	lda xbc, (VoiceData_RamBlockPtrs:24)
	ld xwa, xbc
	lda xbc, (xbc + 64)

VoiceData_ZeroFillOuter:
	ld xhl, (xwa)
	ld d, (xhl - 1)
	ld e, d
	dec 1, d
	cp e, 0:i3
	jr z, VoiceData_ZeroFillNext

VoiceData_ZeroFillInner:
	ld (xhl+), 0x00
	ld e, d
	dec 1, d
	cp e, 0:i3
	jr nz, VoiceData_ZeroFillInner

VoiceData_ZeroFillNext:
	inc 4, xwa
	cp xwa, xbc
	jr c, VoiceData_ZeroFillOuter
	ret

SoundParam_ApplyBit15Toggle:
	ld wa, (4597:16)
	bit 15, wa
	ret z
	lda xbc, (0xfc5a:16)
	ld (xbc + 8), a
	lda xde, (xbc + 9)
	ld c, (xde)
	res 0, c
	ld (xde), c
	ld wa, (4597:16)
	srl wa, 8
	and a, 0x1
	or c, a
	ld (xde), c
	ret

SoundParam_Bit15Jump:
	jr SoundParam_ApplyBit15Toggle

TGReg_WriteCC12_Assign:
	dec 4, xsp
	ld (xsp + 0:8), 0x0
	jr TGReg_WriteCC12_Check

TGReg_WriteCC12_Body:
	ld (xwa + 1), 0xc
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x10
	call MidiTG_WriteRegByDescriptor
	incm8 1, (xsp + 0:8)

TGReg_WriteCC12_Check:
	lda xwa, (xsp)
	cp (xwa), 0xf
	jr ule, TGReg_WriteCC12_Body
	inc 4, xsp
	ret

SwbtWr_InitAndWrite_CC_B1:
	ld (MIDI_MSG_STATUS:16), 177
	ld (MIDI_MSG_DATA2:16), 0
	ld (MIDI_MSG_DATA1:16), 0

SwbtWr_WriteLoop_CC_B1:
	ld (MIDI_MSG_DATA3:16), 64
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld a, (MIDI_MSG_DATA1:16)
	inc 1, a
	ld (MIDI_MSG_DATA1:16), a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B1
	ret

SwbtWr_WriteLoop_CC_B1_Ret:
	ret

SwbtWr_InitAndWrite_CC_B2:
	ld (MIDI_MSG_STATUS:16), 178
	ld (MIDI_MSG_DATA2:16), 0
	ld (MIDI_MSG_DATA1:16), 0

SwbtWr_WriteLoop_CC_B2:
	ld (MIDI_MSG_DATA3:16), 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld a, (MIDI_MSG_DATA1:16)
	inc 1, a
	ld (MIDI_MSG_DATA1:16), a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B2
	ret

SwbtWr_InitAndWriteAllBlocks:
	ld (MIDI_MSG_STATUS:16), 179
	ld (MIDI_MSG_DATA2:16), 127
	ld (MIDI_MSG_DATA1:16), 0

SwbtWr_WriteLoop_CC_B3:
	ld (MIDI_MSG_DATA3:16), 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld a, (MIDI_MSG_DATA1:16)
	inc 1, a
	ld (MIDI_MSG_DATA1:16), a
	cp a, 0xf
	jr ule, SwbtWr_WriteLoop_CC_B3
	ret

SwbtWr_StubRet_A:
	ret

SwbtWr_StubRet_B:
	ret

SwbtWr_StubRet_C:
	ret

SwbtWr_WriteBankSelect:
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 0
	ld a, (MIDI_CC_EXPRESSION_VALUE:16)
	res 7, a
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 1
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	res 7, a
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

MidiBuf_CalcFillRange:
	lda xbc, (0x9674:16)
	ld xde, xbc
	lda xwa, (0x96b3:16)
	sub xwa, xbc
	inc 1, xwa
	ld c, a
	dec 1, c
	cp a, 0:i3
	ret z

MidiBuf_FillLoop:
	ld (xde+), 0x7f
	ld a, c
	dec 1, c
	cp a, 0:i3
	jr nz, MidiBuf_FillLoop
	ret

MidiCtrl_ModeSwitch_Data:
	bit	0, (0xb7ee:16)
	ret	nz
	cp	(SWBTWR_PAYLOAD_1:16), 3
	ret	nz
	bit	2, (SWBTWR_PAYLOAD_3:16)
	ret	z
	ld	a, (SWBTWR_PAYLOAD_2:16)
	extz	wa
	calr	MidiCtrl_Bit2ToChannel
	ret

MidiCtrl_Bit2ToChannel:
	ld c, 0x0:opc
	bit 2, a
	jr z, MidiCtrl_Bit2ToChannel_Store
	ld c, 0x1:opc

MidiCtrl_Bit2ToChannel_Store:
	extz bc
	ld wa, bc
	jp COMM_WriteAndCheck

MidiCtrl_SendControlPacket:
	dec 4, xsp
	ld c, a
	ld a, (0x90f9:16)
	bit 7, a
	jr nz, MidiCtrl_SendPacket_ClearFlag
	lda xwa, (xsp)
	ld (xwa), 0xb0
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x7f
	lda xde, (xwa + 1)
	ld (xde), 0x11
	bit 2, c
	jr nz, MidiCtrl_SendPacket_DispatchCall
	ld (xde), 0x10

MidiCtrl_SendPacket_DispatchCall:
	call MidiPkt_DispatchSpecialType
	jr MidiCtrl_SendPacket_Ret

MidiCtrl_SendPacket_ClearFlag:
	res 7, a
	ld (0x90f9:16), a

MidiCtrl_SendPacket_Ret:
	inc 4, xsp
	ret

VoiceData_SyncAllToHardware:
	pushw iz
	ld iz, 0:i3

VoiceData_SyncLoop:
	ld wa, iz
	extz xwa
	ld xbc, VoiceData_SyncCodeList
	add xbc, xwa
	ld a, (xbc)
	call VoiceData_LookupPtrByIndex
	ld c, (xhl - 1)
	ld xwa, xhl
	sub xwa, 0xf9a0
	lda xde, (0x03c8e4:24)
	add xde, xwa
	extz bc
	pushw bc
	push xde
	push xhl
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, iz
	cp iz, 7:i3
	jr c, VoiceData_SyncLoop
	lda xbc, (0xfd97:16)
	ld a, (xbc)
	and a, 0x80
	ld (xbc), a
	ld e, (0x8e72:16)
	res 7, e
	or a, e
	ld (xbc), a
	lda xwa, (0xfc6f:16)
	cp (0x8e74:16), 0
	jr z, VoiceSync_ClearBit5
	setm 5, (xwa)
	jr VoiceSync_PopReturn

VoiceSync_ClearBit5:
	resm 5, (xwa)

VoiceSync_PopReturn:
	popw iz
	ret

SwbtWr_ResetAllChannels:
	calr SwbtWr_InitAndWrite_CC_B1
	calr SwbtWr_WriteLoop_CC_B1_Ret
	calr SwbtWr_InitAndWrite_CC_B2
	calr SwbtWr_InitAndWriteAllBlocks
	calr SwbtWr_StubRet_A
	calr SwbtWr_StubRet_B
	calr SwbtWr_StubRet_C
	calr SwbtWr_WriteBankSelect
	jrl MidiBuf_CalcFillRange

SysEx_InitiateSend:
	set 7, a
	ld (0xbcfc:16), a
	bit 7, a
	jr z, SysEx_ResetAndReturn
	set 6, (0xbd18:16)
	call SeqAlt_CheckInitBuffer
	call MidiChan_ClearAllStates
	call MidiPkt_ArpMultiPass
	ld a, (0xbcfc:16)
	and a, 0x7
	extz wa
	cp wa, 0:i3
	ret mi
	cp wa, 6:i3
	ret gt
	add wa, wa
	lda xix, (SysExSend_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda xix, (SysEx_SendDispatch:24)
	jp	t, (xix+wa)

; SysEx send dispatch
SysEx_SendDispatch:
	call	SysEx_SendDispatch_Helper
SysEx_InitiateSend_Join:
	call	SysEx_SendDispatch_Helper2
	call	MidiSeq_PartLookup_Data

SysEx_ResetAndReturn:
	ld (0xbd18:16), 0
	jp SoundMode_ResetAllParams
SysEx_DispatchCalls_Data:
	call	SysEx_ResetAndReturn_Helper
	jr	SysEx_InitiateSend_Join
	call	SysEx_ResetAndReturn_Helper2
	jr	SysEx_InitiateSend_Join
	call	SysEx_ResetAndReturn_Helper3
	jr	SysEx_InitiateSend_Join
	call	SysEx_ResetAndReturn_Helper4
	jr	SysEx_InitiateSend_Join
	call	SysEx_ResetAndReturn_Helper5
	jr	SysEx_InitiateSend_Join
	call	SysEx_ResetAndReturn_Helper6
	jr	SysEx_InitiateSend_Join
	ret

SysEx_ParseAndDispatch:
	pushw_erp 0xfa
	ld (0xbd18:16), 0

SysEx_ParserLoop:
	call SeqBuf2_ReadByte
	cp hl, 0xffff
	jr z, SysEx_ParseAndDispatch_Ret
	ldfr_berp L, 0xfb
	call SeqAlt_CheckInitBuffer
	ld c, (0xbd1e:16)
	ldto_berp A, 0xfb
	extz wa
	cp c, 1:i3
	jr z, SysEx_ParseState1_CheckManufID
	cp c, 0:i3
	jr nz, SysEx_ParseState2_CheckBit7
	cp_erpb 0xfb, 0xf0
	jr nz, SysEx_ParserLoop
	ld (0xbd1e:16), 1
	jr SysEx_ParseState_AppendToQueue

SysEx_ParseState1_CheckManufID:
	cp_erpb 0xfb, 0x50
	jr z, SysEx_ParseState1_SetState2
	cp_erpb 0xfb, 0x7e
	jr z, SysEx_ParseState1_SetState2
	cp_erpb 0xfb, 0x41
	jr nz, SysEx_ParseState_Reset

SysEx_ParseState1_SetState2:
	ld (0xbd1e:16), 2
	jr SysEx_ParseState_AppendToQueue

SysEx_ParseState_Reset:
	ld (0xbd1e:16), 0

SysEx_ParseState_DispatchByte:
	call MidiSeq_ReinitCurrentBuffer
	jr SysEx_ParserLoop

SysEx_ParseState2_CheckBit7:
	bit_erpb 0xfb, 0x07
	jr nz, SysEx_ParseState2_EndOfSysEx
	ld xbc, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	cpw (xbc), 0xff
	jr nc, SysEx_ParseState_Reset

SysEx_ParseState_AppendToQueue:
	call VoiceQueue_Append
	jr SysEx_ParserLoop

SysEx_ParseState2_EndOfSysEx:
	ld (0xbd1e:16), 0
	cp_erpb 0xfb, 0xf7
	jr nz, SysEx_ParseState_DispatchByte
	call VoiceQueue_Append
	calr SeqData_DispatchHandler
	jr SysEx_ParserLoop

SysEx_ParseAndDispatch_Ret:
	popw_erp 0xfa
	ret

; Sequencer data dispatch handler
SeqData_DispatchHandler:
	call SeqData_InitPlaybackFromField
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 4:i3
	call SeqData_ReadFieldByIndex
	cp l, 0:i3
	jr nz, SeqData_DispatchLoop
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	call SeqData_ReadFieldByIndex
	cp l, 0x27
	jr nc, SeqData_DispatchLoop
	ld xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld bc, 0:i3
	call SeqData_ReadFieldByIndex
	extz hl
	sla hl, 2
	lda xbc, (SeqData_SubDispatch_Table:24)
	ld	xhl, (xbc+hl)
	call (xhl)

SeqData_DispatchLoop:
	call MidiPkt_SendBankSelect
	jp SoundMode_ResetAllParams
SeqData_DispatchLoop_Body:
	ret
SeqData_DispatchLoop_Check:
	jp	SoundMode_ResetAllParams

SeqData_DispatchLoop_Done:
	dec 4, xsp
	ld xiy, SeqData_OutTemplate
	ld xix, xsp
	ldi85
	ldiw
	ld wa, 0:i3
	call AccWrap_ReturnZero
	cp hl, 0xffff
	jr z, ArpQueue_Flush_Return
	bit 0, (0xb7e7:16)
	jr nz, ArpQueue_Flush_Return
	cp (CURRENT_TITLE:16), 87
	jr z, ArpQueue_Flush_Return
	ld a, (0xfd50:16)
	and a, 0x14
	jr nz, ArpQueue_Flush_Return
	ld xwa, SysEx_Msg_35CC
	ld bc, 3:i3
	call SeqBuf_FlushNoteOffs
	ld wa, (0xbd3a:16)
	cp wa, 0x28
	jr nc, SeqData_FormatOutput
	ldw (0xbd3a:16), 40
	jr SeqData_FormatOutput_Loop

SeqData_FormatOutput:
	cp wa, 0x12c
	jr ule, SeqData_FormatOutput_Loop
	ldw (0xbd3a:16), 300

SeqData_FormatOutput_Loop:
	lda xwa, (xsp)
	ld bc, (0xbd3a:16)
	and c, 0xf
	ld (xwa), c
	ld bc, (0xbd3a:16)
	srl bc, 4
	and c, 0x1f
	ld (xwa + 1), c
	ld bc, 3:i3
	call ArpQueue_Enqueue
	ld xwa, (0xbc5c:16)
	call SeqOut_FlushTimedBuffer
	call ArpQueue_SwapBuffers

ArpQueue_Flush_Return:
	inc 4, xsp
	ret

SeqData_FormatOutput_Dispatch:
	; --- Input validation and dispatch (106 bytes, 2 functions) ---
	ld	wa, 0:i3
	call AccWrap_ReturnZero
	cp hl, 0xffff
	ret z
	cp	(CURRENT_TITLE:16), 87
	ret z
	ld	a, (0xfd50:16)
	and a, 0x14
	ret nz
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	ld e, (xwa + 17)
	ld c, (xwa + 18)
	ld a, e
	and a, 0xf0
	jr z, SeqData_FormatOutput_CaseA
	ld a, c
	and a, 0xe0
	ret nz
SeqData_FormatOutput_CaseA:
	extz bc
	sll bc, 4
	extz de
	or de, bc
	cp de, 0x0028
	ret c
	cp de, 0x012c
	ret	ugt
	ld wa, de
	call SoundMode_SysExConfig_Data
	calr SeqData_FormatOutput_CaseB
	ret
SeqData_FormatOutput_CaseB:
	ldw	(0x90de:16), 0
	push xde
	push xhl
	push xix
	push xiz
	call MidiStream_JumpStubData
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret


SeqData_FormatOutput_CaseC:
	bit	4, (0xfd50:16)
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda	xwa, (xwa+14)
	jp	Param_SignExtendReturn_Join7
SeqData_FormatOutput_Default:
	bit	4, (0xfd50:16)
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda	xwa, (xwa+14)
	call	SeqData_FormatOutput_Default_Helper
	cp	hl, 0:i3
	ret	z
	ld	xwa, SysEx_Msg_35AC
	ld	bc, 5:i3
	call	ArpQueue_Enqueue
	ld	xwa, (0xbc5c:16)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	ret
SeqData_FormatOutput_Data:
	bit	4, (0xfd50:16)
	ret	nz
	calr	SeqData_FormatOutput_Data_Helper
	cpw	(0x90de:16), 0
	ret	z
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldmm16	0x90e0, 0x90de
	call	MidiStream_JumpStubData
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
SeqData_FormatOutput_Data_Helper:
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 1:i3
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	ret	lt
	cp	hl, 6:i3
	ret	gt
	add	hl, hl
	lda	xix, (SeqDataFmt_SwitchOffsets:24)
	ld	hl, (xix+hl)
	lda xix, (SeqData_FormatOutput_Default_Code:24)
	jp	t, (xix+hl)
SeqData_FormatOutput_Default_Code:
	jr	SeqData_FormatOutput_Data_Helper_Join
	jr	SeqData_FormatOutput_Data_Helper_Join2
	jrl	SeqData_FormatOutput_Data_Helper_Join3
	jrl	SeqData_FormatOutput_Data_Helper_Return
	jrl	SeqData_FormatOutput_Data_Helper_Join4
	jrl	SeqData_FormatOutput_Data_Helper_Join5
	calr	SeqData_FormatOutput_Data_Helper_Helper
	ret
SeqData_FormatOutput_Data_Helper_Join:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 11
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable0:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable0:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue:
	pop	qiz
	ret
SeqData_FormatOutput_Data_Helper_Join2:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue2
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable2:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue2
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable2:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue2:
	pop	qiz
	ret
SeqData_FormatOutput_Data_Helper_Join3:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 12
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue3
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable4:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue3
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable4:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue3:
	pop	qiz
	ret
SeqData_FormatOutput_Data_Helper_Return:
	ret
SeqData_FormatOutput_Data_Helper_Join4:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue4
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable6:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue4
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable6:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue4:
	pop	qiz
	ret
SeqData_FormatOutput_Data_Helper_Join5:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue5
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable8:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue5
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable8:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue5:
	pop	qiz
	ret
SeqData_FormatOutput_Data_Helper_Helper:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 14
	jr	nc, SeqData_FormatOutput_Data_Code_Epilogue6
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable10:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, SeqData_FormatOutput_Data_Code_Epilogue6
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable10:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+17)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_FormatHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeqData_FormatOutput_Data_Code_Epilogue6:
	pop	qiz
	ret

SeqAlt_NibbleSearch_Ret:
	ret

SeqAlt_NibbleSearch:
	ld hl, de
	dec 1, de
	cp hl, 0:i3
	jr z, SeqAlt_NibbleSearch_NotFound

SeqAlt_NibbleSearch_CompareLoop:
	cp A, (xbc+)
	jr nz, SeqAlt_NibbleSearch_DecLoop
	ld hl, 0:i3
	ret

SeqAlt_NibbleSearch_DecLoop:
	ld hl, de
	dec 1, de
	cp hl, 0:i3
	jr nz, SeqAlt_NibbleSearch_CompareLoop

SeqAlt_NibbleSearch_NotFound:
	ldw hl, 0xffff
	ret

SeqAlt_ApplyDescriptor_TypeA:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 4)
	lda xix, (xbc + 2)
	ld (xix), l
	cp (xiz + 9), l
	jrl ugt, SeqAlt_PopIzSkip4Ret
	cp l, (xiz + 10)
	jrl ugt, SeqAlt_PopIzSkip4Ret
	ld a, (xiz + 14)
	cp a, 0xff
	jr z, SeqAlt_ApplyDescA_DirectWrite
	cp a, 1:i3
	jr nc, SeqAlt_PopIzSkip4Ret
	extz wa
	muls wa, 0x6
	lda xbc, (MidiCtl_SubTableDesc:24)
	exts xwa
	add xwa, xbc
	ld de, (xwa)
	ld xbc, (xwa + 2)
	extz hl
	ld wa, hl
	calr SeqAlt_NibbleSearch
	cp hl, 0xffff
	jr z, SeqAlt_PopIzSkip4Ret
	lda xbc, (xsp + 4)
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	lda xhl, (xbc + 2)
	ld e, (xhl)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescA_NoShift
	slla e

SeqAlt_ApplyDescA_NoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xhl), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	jr SeqAlt_ApplyDescA_FinalCall

SeqAlt_ApplyDescA_DirectWrite:
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld e, (xix)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescA_DirectNoShift
	slla e

SeqAlt_ApplyDescA_DirectNoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xix), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc

SeqAlt_ApplyDescA_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_ApplyDescriptor_TypeB:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	ld a, (xiz + 9)
	cp a, l
	jrl gt, SeqAlt_PopIzSkip4Ret2
	ld c, (xiz + 10)
	cp l, c
	jrl gt, SeqAlt_PopIzSkip4Ret2
	lda xbc, (xsp + 4)
	lda xix, (xbc + 2)
	ld (xix), l
	ld a, (xiz + 14)
	cp a, 0xff
	jr z, SeqAlt_ApplyDescB_DirectWrite
	cp a, 1:i3
	jr nc, SeqAlt_PopIzSkip4Ret2
	extz wa
	muls wa, 0x6
	lda xbc, (MidiCtl_SubTableDesc:24)
	exts xwa
	add xwa, xbc
	ld de, (xwa)
	ld xbc, (xwa + 2)
	extz hl
	ld wa, hl
	calr SeqAlt_NibbleSearch
	cp hl, 0xffff
	jr z, SeqAlt_PopIzSkip4Ret2
	lda xbc, (xsp + 4)
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	lda xhl, (xbc + 2)
	ld e, (xhl)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescB_NoShift
	slla e

SeqAlt_ApplyDescB_NoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xhl), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	jr SeqAlt_ApplyDescB_FinalCall

SeqAlt_ApplyDescB_DirectWrite:
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld e, (xix)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescB_DirectNoShift
	slla e

SeqAlt_ApplyDescB_DirectNoShift:
	ld a, (xiz + 15)
	xor a, e
	ld (xix), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc

SeqAlt_ApplyDescB_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_PopIzSkip4Ret2:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_DescriptorBlock_Data:
	dec	6, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, SeqAlt_NibbleSearch_Epilogue4
	cp	l, (xiz+10)
	jr	ugt, SeqAlt_NibbleSearch_Epilogue4
	extz	hl
	lda	xbc, (xsp+4)
	ld	a, (xiz+6)
	ld	(xbc), a
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xde, (xiz+11)
	ld	a, (xde)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip4
	.byte 0xdb, 0xfe	; sll a,hl -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip4:
	ld	(xbc+2), hl
	ld	l, (xiz+8)
	extz	hl
	ld	a, (xde)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip5
	.byte 0xdb, 0xfe	; sll a,hl -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip5:
	ld	(xbc+4), hl
	ld	xwa, xbc
	call	AssSwb_ProcessLoop_Data
SeqAlt_NibbleSearch_Epilogue4:
	pop	xiz
	inc	6, xsp
	ret
	push	xiz
	ld	xiz, xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, SeqAlt_NibbleSearch_Epilogue5
	cp	l, (xiz+10)
	jr	ugt, SeqAlt_NibbleSearch_Epilogue5
	ld	a, (xiz+14)
	cp	a, 1:i3
	jr	nc, SeqAlt_NibbleSearch_Epilogue5
	extz	wa
	muls	wa, 6
	lda	xbc, (SeqAlt_PopIzSkip4Ret2_Data:24)
	ld	xbc, (xbc+wa)
	ld	a, (xiz+8)
	cpl	a
	and	(xbc), a
	ld	a, (xiz+11)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip6
	.byte 0xcf, 0xfe	; sll a,l -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip6:
	or	(xbc), l
SeqAlt_NibbleSearch_Epilogue5:
	pop	xiz
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	lda	xbc, (xsp+4)
	ld	(xbc+2), l
	cp	(xiz+9), l
	jrl	ugt, SeqAlt_NibbleSearch_Epilogue
	cp	l, (xiz+10)
	jrl	ugt, SeqAlt_NibbleSearch_Epilogue
	ld	a, (xiz+14)
	cp	a, 255
	jr	z, SeqAlt_NibbleSearch_Skip
	cp	a, 1:i3
	jrl	nc, SeqAlt_NibbleSearch_Epilogue
	extz	wa
	muls	wa, 6
	lda	xbc, (MidiCtl_SubTableDesc:24)
	exts	xwa
	add	xwa, xbc
	ld	de, (xwa)
	ld	xbc, (xwa+2)
	extz	hl
	ld	wa, hl
	calr	SeqAlt_NibbleSearch
	cp	hl, 0xffff
	jr	z, SeqAlt_NibbleSearch_Epilogue
	ld	a, (xiz+6)
	ld	(xsp+4), a
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip7
	.byte 0xcd, 0xfe	; sll a,e -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip7:
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
	jr	SeqAlt_NibbleSearch_Join3
SeqAlt_NibbleSearch_Skip:
	ld	a, (xiz+6)
	ld	(xbc), a
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip8
	.byte 0xcd, 0xfe	; sll a,e -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip8:
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
SeqAlt_NibbleSearch_Join3:
	call	AssSwb_ApplyBitDescriptor
SeqAlt_NibbleSearch_Epilogue:
	pop	xiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+10), xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	ld	(xsp+4), l
	ld	xde, (xsp+10)
	ld	a, (xde+9)
	cp	a, (xsp+4)
	jrl	ugt, SeqAlt_NibbleSearch_Epilogue2
	ld	c, (xsp+4)
	cp	c, (xde+10)
	jr	ugt, SeqAlt_NibbleSearch_Epilogue2
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	ldfr_berp	l, 248
	extz	iz
	sll	iz, 8
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	extz	hl
	or	iz, hl
	cp	iz, 0x3fff
	jr	ugt, SeqAlt_NibbleSearch_Epilogue2
	srl	iz, 4
	and	iz, 63
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	xwa, (xsp+10)
	ld	a, (xwa+6)
	or	a, l
	ldfr_berp	a, 251
	lda	xwa, (xsp+6)
	ldto_berp	c, 251
	ld	(xwa), c
	ld	(xwa+1), 1
	ldto_berp	c, 248
	ld	(xwa+2), c
	ld	(xwa+3), 127
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+6)
	ldto_berp	c, 251
	ld	(xwa), c
	ld	xde, (xsp+10)
	ld	c, (xde+7)
	ld	(xwa+1), c
	ld	c, (xsp+4)
	ld	(xwa+2), c
	ld	c, (xde+8)
	ld	(xwa+3), c
	call	AssSwb_ApplyBitDescriptor
SeqAlt_NibbleSearch_Epilogue2:
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	ld	(xsp+8), l
	ld	a, (xiz+9)
	cp	a, (xsp+8)
	jrl	ugt, SeqAlt_NibbleSearch_Epilogue6
	ld	a, (xsp+8)
	cp	a, (xiz+10)
	jrl	ugt, SeqAlt_NibbleSearch_Epilogue6
	ld	a, (xiz+14)
	cp	a, 1:i3
	jrl	nc, SeqAlt_NibbleSearch_Epilogue6
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SubTableBPtr:24)
	ld	xwa, (xbc+wa)
	ld	(xsp+4), xwa
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	ld	a, (xiz+6)
	or	a, l
	ld	(xsp+10), a
	lda	xiy, (xiz+7)
	inc	8, xiz
	lda	xwa, (xsp+12)
	lda	xde, (xwa+1)
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	cp	(xsp+8), 129
	jr	z, SeqAlt_NibbleSearch_Skip2
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	c, (xiy)
	ld	(xde), c
	ld	c, (xsp+8)
	ld	(xhl), c
	ld	c, (xiz)
	ld	(xix), c
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+12)
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	xde, (xsp+4)
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	(xwa+2), 0
	ld	c, (xde+3)
	ld	(xwa+3), c
	jr	SeqAlt_NibbleSearch_Join
SeqAlt_NibbleSearch_Skip2:
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	c, (xiy)
	ld	(xde), c
	ld	(xhl), 0
	ld	c, (xiz)
	ld	(xix), c
	call	AssSwb_ApplyBitDescriptor
	lda	xwa, (xsp+12)
	ld	c, (xsp+10)
	ld	(xwa), c
	ld	xde, (xsp+4)
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	c, (xde+2)
	ld	(xwa+2), c
	ld	c, (xde+3)
	ld	(xwa+3), c
SeqAlt_NibbleSearch_Join:
	call	AssSwb_ApplyBitDescriptor
SeqAlt_NibbleSearch_Epilogue6:
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call	MIDI_PackNibbleParam
	cp	(xiz+9), l
	jr	ugt, SeqAlt_NibbleSearch_Epilogue3
	cp	l, (xiz+10)
	jr	ugt, SeqAlt_NibbleSearch_Epilogue3
	ld	a, (xiz+14)
	cp	a, 255
	jr	z, SeqAlt_NibbleSearch_Epilogue3
	cp	a, 1:i3
	jr	nc, SeqAlt_NibbleSearch_Epilogue3
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SubTableCPtr:24)
	ld	xwa, (xbc+wa)
	lda	xbc, (xsp+6)
	cp	l, 0:i3
	jr	nz, SeqAlt_NibbleSearch_Skip3
	ld	a, (xwa)
	ld	(xbc), a
	jr	SeqAlt_NibbleSearch_Join2
SeqAlt_NibbleSearch_Skip3:
	ld	a, (xwa+1)
	ld	(xbc), a
SeqAlt_NibbleSearch_Join2:
	ld	a, (xiz+6)
	ld	(xsp+4), a
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ldw	bc, 10
	call	SeqData_ReadFieldByIndex
	sub	l, 32
	lda	xbc, (xsp+4)
	or	(xbc), l
	ld	a, (xiz+7)
	ld	(xbc+1), a
	lda	xhl, (xbc+2)
	ld	e, (xhl)
	ld	a, (xiz+11)
	and	a, 15
	jr	z, SeqAlt_NibbleSearch_Skip9
	.byte 0xcd, 0xfe	; sll a,e -- the backend cannot spell this form
SeqAlt_NibbleSearch_Skip9:
	ld	(xhl), e
	ld	a, (xiz+8)
	ld	(xbc+3), a
	ld	xwa, xbc
	call	AssSwb_ApplyBitDescriptor
SeqAlt_NibbleSearch_Epilogue3:
	pop	xiz
	inc	4, xsp
	ret
	ret
	ld	xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	lda	xwa, (xwa+14)
	call	SeqAlt_PopIzSkip4Ret2_Helper
	cp	hl, 0:i3
	ret	z
	ld	xwa, SysEx_Msg_35AC
	ld	bc, 5:i3
	call	ArpQueue_Enqueue
	ld	xwa, (0xbc5c:16)
	call	SeqOut_FlushTimedBuffer
	call	ArpQueue_SwapBuffers
	ret

SeqAlt_ApplyDescriptor_TypeC:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 4)
	lda xde, (xbc + 2)
	ld (xde), l
	cp (xiz + 9), l
	jr ugt, SeqAlt_ApplyDescC_Cleanup
	cp l, (xiz + 10)
	jr ugt, SeqAlt_ApplyDescC_Cleanup
	lda xix, (xiz + 11)
	cp l, 0x40
	scc16 nc, hl
	ld a, (xix)
	and a, 0xf
	jr z, SeqAlt_ApplyDescC_NoShift
	slaa hl

SeqAlt_ApplyDescC_NoShift:
	ld (xde), l
	ld a, (xiz + 6)
	ld (xbc), a
	ld a, (xiz + 7)
	ld (xbc + 1), a
	ld a, (xiz + 8)
	ld (xbc + 3), a
	ld xwa, xbc
	call AssSwb_ApplyBitDescriptor

SeqAlt_ApplyDescC_Cleanup:
	pop xiz
	inc 4, xsp
	ret

SeqAlt_ApplyDescriptor_TypeD:
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, SeqAlt_ApplyDescD_Cleanup
	cp l, (xiz + 10)
	jr ugt, SeqAlt_ApplyDescD_Cleanup
	ld e, (xiz + 6)
	ld c, (xiz + 7)
	ld a, (xiz + 11)
	and a, 0xf
	jr z, SeqAlt_ApplyDescD_NoShift
	slla l

SeqAlt_ApplyDescD_NoShift:
	extz hl
	ld a, (xiz + 8)
	extz wa
	pushw wa
	ld a, e
	ld de, hl
	call AssswbWr

SeqAlt_ApplyDescD_Cleanup:
	pop xiz
	ret

SeqAlt_StubRet_Pair:
	ret
	ret

SeqAlt_ApplyDescriptor_WithAssSwb:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 6), xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	ldfr_berp L, 0xfb
	lda xbc, (xsp + 2)
	lda xde, (xbc + 1)
	lda xhl, (xbc + 2)
	lda xix, (xbc + 3)
	cpib_erp 0xfb, 0
	jr z, SeqAlt_AssSwb_ZeroPath
	dec1b_erp 0xfb
	ld xiy, (xsp + 6)
	ld a, (xiy + 11)
	and a, 0xf
	jr z, SeqAlt_AssSwb_NoShift
	sllb_erp 0xfb

SeqAlt_AssSwb_NoShift:
	ld a, (xiy + 9)
	cpb_erp A, 0xfb
	jr ugt, SeqAlt_AssSwb_Cleanup
	ldto_berp A, 0xfb
	cp a, (xiy + 10)
	jr ugt, SeqAlt_AssSwb_Cleanup
	set 3, (0x8d52:16)
	ld (xbc), 0x98
	ld (xde), 0x3
	ld (xhl), 0x1
	ld (xix), 0x1
	ld xwa, xbc
	call AssSwb_ApplyBitDescriptor
	lda xwa, (xsp + 2)
	ld (xwa), 0x48
	ld (xwa + 1), 0x7
	ldto_berp C, 0xfb
	ld (xwa + 2), c
	ld (xwa + 3), 0x30
	jr SeqAlt_AssSwb_FinalCall

SeqAlt_AssSwb_ZeroPath:
	ld (xbc), 0x98
	ld (xde), 0x3
	ld (xhl), 0x0
	ld (xix), 0x1
	ld xwa, xbc

SeqAlt_AssSwb_FinalCall:
	call AssSwb_ApplyBitDescriptor

SeqAlt_AssSwb_Cleanup:
	popw_erp 0xfa
	inc 8, xsp
	ret

SeqAlt_DualNibblePack:
	dec 4, xsp
	push xiz
	lda xwa, (0xbd26:16)
	ld (xsp + 4), xwa
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	inc 1, xiz
	ld xwa, (xsp + 4)
	ld (xwa), l
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	ld (xiz), l
	bitm 7, (xiz)
	jr z, SeqAlt_DualNibblePack_Dispatch
	resm 7, (xiz)
	setm 7, (xiz - 1)

SeqAlt_DualNibblePack_Dispatch:
	call MidiStream_RefreshDisplay
	pop xiz
	inc 4, xsp
	ret

DSPParam_StoreWithLoop:
	dec 8, xsp
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	lda xbc, (xsp + 10)
	ld (xbc), l
	cp (xiz + 9), l
	jrl ugt, DSP_ParamLoop_Cleanup
	cp l, (xiz + 10)
	jr ugt, DSP_ParamLoop_Cleanup
	ld a, (xiz + 11)
	and a, 0xf
	jr z, DSPParam_StoreWithLoop_NoShift
	slla l

DSPParam_StoreWithLoop_NoShift:
	ld (xbc), l
	ld a, (xiz + 6)
	sub a, 0x61
	ld w, 0x0:opc
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 8
	ld (xsp + 4), xwa
	add xwa, 0x4900
	extz hl
	ld bc, hl
	call DSPCfg_WriteParamFull
	cp hl, 0:i3
	jr lt, DSP_ParamLoop_Cleanup
	ld xwa, (xsp + 4)
	add xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, DSP_ParamLoop_Cleanup
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DSP_ParamLoop_Cleanup

VoiceParam_ApplyRangeCheck:
	ld bc, iz
	exts xbc
	ld xwa, (xsp + 4)
	add xwa, 0x4910
	add xwa, xbc
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld de, iz
	exts xde
	ld xwa, (xsp + 4)
	add xwa, 0x4910
	add xwa, xde
	call DSPCfg_WriteParamFull
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, VoiceParam_ApplyRangeCheck

DSP_ParamLoop_Cleanup:
	pop xiz
	inc 8, xsp
	ret

VoiceParam_ApplyBoundsCheck:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 6), xwa
	ld a, (CURRENT_MODE:16)
	cp a, 0xe
	jr nz, VoiceParam_ApplyBoundsValidated
	cp a, 0x11
	jr z, VoiceParam_ApplyCleanupRet

VoiceParam_ApplyBoundsValidated:
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	ldfr_berp L, 0xfb
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	bit 7, l
	jr z, VoiceParam_ApplyNibbleLookup
	res 7, l
	set_erpb 0xfb, 0x07

VoiceParam_ApplyNibbleLookup:
	ld xde, (xsp + 6)
	ld a, (xde + 9)
	cpb_erp A, 0xfb
	jr ugt, VoiceParam_ApplyCleanupRet
	ldto_berp C, 0xfb
	cp c, (xde + 10)
	jr ugt, VoiceParam_ApplyCleanupRet
	and l, 0x7
	bit_erpb 0xfb, 0x07
	jr z, VoiceParam_ApplyNibble_NoShiftBit
	ld l, 0x0:opc

VoiceParam_ApplyNibble_NoShiftBit:
	lda xwa, (xsp + 2)
	ld xbc, (xsp + 6)
	ld c, (xbc + 6)
	ld (xwa), c
	ld (xwa + 1), 0x1
	ld (xwa + 2), l
	ld (xwa + 3), 0x7f
	call AssSwb_ApplyBitDescriptor
	lda xwa, (xsp + 2)
	ld xde, (xsp + 6)
	ld c, (xde + 6)
	ld (xwa), c
	ld c, (xde + 7)
	ld (xwa + 1), c
	ldto_berp C, 0xfb
	ld (xwa + 2), c
	ld c, (xde + 8)
	ld (xwa + 3), c
	call AssSwb_ApplyBitDescriptor

VoiceParam_ApplyCleanupRet:
	popw_erp 0xfa
	inc 8, xsp
	ret

VoiceParam_StoreToBuffer:
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	ld a, (xiz + 11)
	and a, 0xf
	jr z, VoiceParam_StoreToBuffer_NoShift
	slla l

VoiceParam_StoreToBuffer_NoShift:
	ld (0xbd26:16), l
	cp (xiz + 9), l
	jr ugt, VoiceParam_StoreToBuffer_Ret
	cp l, (xiz + 10)
	call ule, (MidiStream_ApplyPendingCC:24)

VoiceParam_StoreToBuffer_Ret:
	pop xiz
	ret

VoiceParam_DirectHardwareWrite:
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, VoiceParam_DirectHW_Ret
	cp l, (xiz + 10)
	jr ugt, VoiceParam_DirectHW_Ret
	mrdb5 0x8e, 0x07, 0x19, 0x89, 0x34
	ld a, (xiz + 11)
	and a, 0xf
	jr z, VoiceParam_DirectHW_NoShift
	slla l

VoiceParam_DirectHW_NoShift:
	ld (0x347c:16), l
	mrdb5 0x8e, 0x08, 0x19, 0x7d, 0x34
	call MidiStream_ReplaySavedExpr

VoiceParam_DirectHW_Ret:
	pop xiz
	ret

VoiceParam_MultiModeDispatch:
	push xiz
	ld xiz, xwa
	ld xwa, (MIDISEQ_ACTIVE_BLOCK_PTR:16)
	call MIDI_PackNibbleParam
	cp (xiz + 9), l
	jr ugt, VoiceParam_LoopExit
	cp l, (xiz + 10)
	jr ugt, VoiceParam_LoopExit
	lda xbc, (xiz + 8)
	lda xwa, (xiz + 11)
	cp l, 2:i3
	jr z, VoiceParam_MultiMode_Case2
	cp l, 1:i3
	jr z, VoiceParam_MultiMode_Case1
	cp l, 0:i3
	jr nz, VoiceParam_LoopExit
	ld (0x3489:16), 5
	ld (0x347c:16), 0
	ld (0x347d:16), 4
	call MidiStream_ReplaySavedExpr
	ld (0x3489:16), 6
	ld (0x347c:16), 0
	ld (0x347d:16), 4
	jr VoiceParam_MultiMode_Dispatch

VoiceParam_MultiMode_Case1:
	ld (0x3489:16), 5
	ld a, (xwa)
	and a, 0xf
	jr z, VoiceParam_MultiMode_Case1_NoShift
	slla l

VoiceParam_MultiMode_Case1_NoShift:
	ld (0x347c:16), l
	jr VoiceParam_MultiMode_SetupHW

VoiceParam_MultiMode_Case2:
	ld (0x3489:16), 6
	ld a, (xwa)
	dec 1, a
	and a, 0xf
	jr z, VoiceParam_MultiMode_Case2_NoShift
	slla l

VoiceParam_MultiMode_Case2_NoShift:
	ld (0x347c:16), l

VoiceParam_MultiMode_SetupHW:
	mrib4 0x81, 0x19, 0x7d, 0x34

VoiceParam_MultiMode_Dispatch:
	call MidiStream_ReplaySavedExpr

VoiceParam_LoopExit:
	pop xiz
	ret

VoiceParam_MultiMode_StubRet:
	ret
VoiceParam_AssSwb_MultiBlock_Data:
	bit	4, (0xfd50:16)
	ret	nz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 1:i3
	call	SeqData_ReadFieldByIndex
	extz	hl
	dec	1, hl
	cp	hl, 0:i3
	ret	lt
	cp	hl, 6:i3
	ret	gt
	add	hl, hl
	lda	xix, (AssSwbMulti_SwitchOffsets:24)
	ld	hl, (xix+hl)
	lda xix, (VoiceParam_MultiMode_StubRet_Code:24)
	jp	t, (xix+hl)
VoiceParam_MultiMode_StubRet_Code:
	jr	VoiceParam_AssSwb_MultiBlock_Data_Join
	jr	VoiceParam_AssSwb_MultiBlock_Data_Join2
	jrl	VoiceParam_AssSwb_MultiBlock_Data_Join3
	jrl	VoiceParam_AssSwb_MultiBlock_Data_Return
	jrl	VoiceParam_AssSwb_MultiBlock_Data_Join4
	jrl	VoiceParam_AssSwb_MultiBlock_Data_Join5
	calr	VoiceParam_AssSwb_MultiBlock_Data_Helper
	ret
VoiceParam_AssSwb_MultiBlock_Data_Join:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 11
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable1:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable1:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue:
	pop	qiz
	ret
VoiceParam_AssSwb_MultiBlock_Data_Join2:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue2
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable3:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue2
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable3:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue2:
	pop	qiz
	ret
VoiceParam_AssSwb_MultiBlock_Data_Join3:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 12
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue3
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable5:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue3
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable5:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue3:
	pop	qiz
	ret
VoiceParam_AssSwb_MultiBlock_Data_Return:
	ret
VoiceParam_AssSwb_MultiBlock_Data_Join4:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue4
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable7:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue4
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable7:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue4:
	pop	qiz
	ret
VoiceParam_AssSwb_MultiBlock_Data_Join5:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cpib_erp	251, 1
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue5
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable9:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue5
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable9:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue5:
	pop	qiz
	ret
VoiceParam_AssSwb_MultiBlock_Data_Helper:
	push	qiz
	ld	xwa, (MIDISEQ_ACTIVE_BUF_PTR:16)
	ld	bc, 2:i3
	call	SeqData_ReadFieldByIndex
	ldfr_berp	l, 251
	cp_erpb	251, 8
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue6
	ldto_berp	c, 251
	extz	bc
	sla	bc, 2
	lda	xwa, (MidiCtl_SelectTable11:24)
	ld	xwa, (xwa+bc)
	calr	MidiPkt_CheckGateCondition
	cp	hl, 0xffff
	jr	z, VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue6
	ldto_berp	a, 251
	extz	wa
	sla	wa, 2
	lda	xbc, (MidiCtl_SelectTable11:24)
	ld	xbc, (xbc+wa)
	ld	xwa, xbc
	ld	c, (xbc+18)
	extz	bc
	sla	bc, 2
	lda	xde, (MidiCtl_AssSwbHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
VoiceParam_AssSwb_MultiBlock_Data_Code_Epilogue6:
	pop	qiz
	ret

VoiceParam_MultiBlock_Ret:
	ret

VoiceParam_MultiBlock_Epilogue_Data:
	lda	xsp, (xsp-12)
	ld	c, (xwa+14)
	cp	c, 1:i3
	jr	nc, VoiceParam_AssSwb_MultiBlock_Data_Epilogue
	extz	bc
	muls	bc, 6
	lda	xde, (SeqAlt_PopIzSkip4Ret2_Data:24)
	ld	xhl, (xde+bc)
	lda	xde, (xsp+8)
	ld	c, (xwa+6)
	ld	(xde), c
	ld	c, (xwa+7)
	ld	(xde+1), c
	ld	c, (xhl)
	ld	(xde+2), c
	ld	c, (xwa+8)
	ld	(xde+3), c
	lda	xbc, (xsp)
	ld	(xbc), xde
	ld	(xbc+4), xwa
	ld	xwa, xbc
	calr	MidiPkt_EnqueueControl_3354
VoiceParam_AssSwb_MultiBlock_Data_Epilogue:
	lda	xsp, (xsp+12)
	ret

VoiceParam_LookupAndEnqueue:
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
	calr MidiPkt_EnqueueControl_3354
	pop xiz
	lda xsp, (xsp + 12)
	ret

	.include "midi/midipkt_routines.s"
