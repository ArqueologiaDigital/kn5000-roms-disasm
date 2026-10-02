; =============================================================================
; midi_serial_routines.asm - MIDI Serial Communication (SC0)
; =============================================================================
; This file contains the MIDI serial communication routines for the KN5000
; Main CPU. Serial Channel 0 (SC0) is used for MIDI communication.
;
; Key routines:
;   INTTX0_HANDLER        - MIDI TX interrupt handler
;   INTRX0_HANDLER        - MIDI RX interrupt handler
;   READ_COM_SELECT_SWITCH - Reads COM port selection switch (MIDI/MAC/PC1/PC2)
;   SC0Init_EnableRegisters          - SC0 serial port initialization
;
; Hardware:
;   Serial Channel 0 (SC0) registers:
;     SC0BUF (0xd0) - Serial buffer
;     SC0CR  (0xd1) - Control register
;     SC0MOD (0xd2) - Mode register
;     BR0CR  (0xd3) - Baud rate control
;
; COM_SELECT switch values:
;   0x00 = MIDI
;   0x01 = MAC
;   0x02 = PC1
;   0x03 = PC2
;
; =============================================================================

;
; v7 REGENERATED FROM v10's STRUCTURE (midi lane, 2026-09-25,
; scripts/tools/midi_lane_v7_from_v10.py): every line below was derived
; from the v10 line emitting the same bytes at v10 = v7 + 0x7D1, with v7's
; own bytes decoded and re-encoded.  Addresses quoted in carried-over
; headers are v10's.  Labels marked `v7 NAME DISPLACED` are the old v7
; names, kept because another v7 file references them; see that note.
;
; The first bytes of this file are the TAIL of an instruction whose head
; is the last bytes of the previous file: the v7 file boundary sits 0x41A
; bytes off the v10 one, so it cuts an instruction.
	.byte 0x16, 0x04, 0x41
	ld (1076:16), a
	ld (1077:16), a
	ld (1054:16), 1
	res 0, (0x28a6:16)
	cpw (0x28aa:16), 0
	jr	z, ResetPlay_Src3Check
	ld a, 0x85:opc
	calr	MIDI_QUEUE_EVENT_PAIR
ResetPlay_Src3Check:
	bit 0, (0x28a7:16)
	jr	z, ResetPlay_Return
	xor wa, wa
	ld (1051:16), a
	ld (1052:16), wa
	ld (1057:16), 1
ResetPlay_Return:
	ret
MIDI_APPLY_STARTUP_TIMING:
	cp (1108:16), 0
	jr	z, StartTiming_ClearAndReturn
	bit 0, (1056:16)
	jr	z, StartTiming_ClearAndReturn
	ld (1056:16), 6
	ld a, (1108:16)
	dec 1, a
	sll a, 2
	add (1047:16), a
	bit 0, (1055:16)
	jr	z, StartTiming_Src1Adjust
	ld (1055:16), 6
	add (1130:16), a
StartTiming_Src1Adjust:
	bit 0, (1054:16)
	jr	z, StartTiming_Src2Adjust
	ld (1054:16), 6
	add (1045:16), a
StartTiming_Src2Adjust:
	bit 0, (1057:16)
	jr	z, StartTiming_ClearAndReturn
	ld (1057:16), 6
	add (1051:16), a
StartTiming_ClearAndReturn:
	ld (1108:16), 0
	ret
Continue_SetRunning:
	ld (1056:16), 6
	bit 0, (0x28a7:16)
	jr	z, Continue_Return
	ld (1057:16), 6
	bit 1, (0x28a7:16)
	jr	z, Continue_Return
	bit 0, (0x28a6:16)
	jr	nz, Continue_ClearPositionAndSetSrc1
	ld (1045:16), 0
	ld (1046:16), 0
Continue_ClearPositionAndSetSrc1:
	ld (1076:16), 0
	ld (1077:16), 0
	and (0x28a6:16), 254
	ld (1054:16), 6
Continue_Return:
	ret
; v7 NAME DISPLACED: `IntTx0_DequeueAndSend_Code_Skip` sits where v10 has `AltClk_DisabledClockPath` (v10 0xFCF5F9).
; Kept because another v7 file references this address by this name.
IntTx0_DequeueAndSend_Code_Skip:
AltClk_DisabledClockPath:
	ld (1066:16), 0
	pushw wa
	ld a, (1056:16)
	and a, 0x5
	popw wa
	jr	z, AltClk_NoSrcFlagPath
	bit 2, (0xfd52:16)
	jr	z, AltClk_Return
	cp d, 0xfc
	jr	nz, AltClk_Return
	ld (1056:16), 12
	bit 2, (1054:16)
	jr	z, AltClk_StopSrc3Snapshot
	bit 2, (1057:16)
	jr	z, AltClk_StopSrc1Queue
	set	2, (0x33de:16)
AltClk_StopSrc1Queue:
	ld (1054:16), 12
	cpw (0x28aa:16), 0
	jr	z, AltClk_StopSrc3Snapshot
	ld a, 0x86:opc
	calr	MIDI_QUEUE_EVENT_PAIR
AltClk_StopSrc3Snapshot:
	bit 2, (1057:16)
	jr	z, AltClk_Return
	ld (1057:16), 12
	pushw wa
	ld a, (1045:16)
	ld (1078:16), a
	ld a, (1046:16)
	ld (1079:16), a
	popw wa
AltClk_Return:
	ret
AltClk_NoSrcFlagPath:
	bit 2, (0xfd52:16)
	jr	z, AltClk_NoMatchReturn
	bit 2, (0x28a7:16)
	jr	nz, AltClk_NoMatchReturn
	cp d, 0xfa
	jr	z, AltClk_StartArmTx
	cp d, 0xfb
	jr	z, AltClk_ContinueArmTx
AltClk_NoMatchReturn:
	ret
AltClk_StartArmTx:
	set 1, (1065:16)
	ld (234:16), 221
	jrl	SndParam_Widget1_AppendType2_Entry10
AltClk_ContinueArmTx:
	bit 0, (0x28a7:16)
	jr	z, AltClk_Src3DisabledReturn
	set 2, (1065:16)
	ld (234:16), 221
	jrl	Continue_SetRunning
AltClk_Src3DisabledReturn:
	ret
MIDI_QUEUE_TRACK_EVENT:
	bit 0, (1113:16)
	jr	nz, QueueTrack_LinearBufWrite
	pushw wa
	ld xix, 0x1e753
	ld wa, (xix - 2)
	and wa, wa
	jr	z, QueueTrack_FifoWriteOrClear
	ld hl, (xix - 4)
	ld	(xix+hl), 0x81
	minc1_16 hl, 0x7ff
	dec 1, wa
	ld (xix - 4), hl
	ld (xix - 2), wa
QueueTrack_FifoWriteOrClear:
	popw wa
	ldw (1141:16), 0
	ret
QueueTrack_LinearBufWrite:
	ld xix, 0x477
	ld hl, (1141:16)
	ld	(xix+hl), 0x81
	inc 1, hl
	ld (1141:16), hl
	ret
MIDI_QUEUE_EVENT_PAIR:
	bit 0, (1113:16)
	jr	nz, QueuePair_LinearBufWrite
	cpw (0x01e751:24), 2
	jr	c, QueuePair_FifoFullReturn
	push	sr
	ei 6
	ld xix, 0x1e753
	ld hl, (xix - 4)
	ld	(xix+hl), a
	minc1_16 hl, 0x7ff
	ld a, (1051:16)
	ld	(xix+hl), a
	minc1_16 hl, 0x7ff
	ld (xix - 4), hl
	decm 2, (xix - 2)
	pop	sr
QueuePair_FifoFullReturn:
	ldw (1141:16), 0
	ret
QueuePair_LinearBufWrite:
	ld xix, 0x477
	ld hl, (1141:16)
	ld	(xix+hl), a
	inc 1, hl
	ld a, (1051:16)
	ld	(xix+hl), a
	inc 1, hl
	ld (1141:16), hl
	ret
; v7 NAME DISPLACED: `ClkTick_BeatSubdivCheck` sits where v10 has `MIDI_CHANNEL_MESSAGE_DISPATCHER` (v10 0xFCF733).
; The v7 code v10 calls `ClkTick_BeatSubdivCheck` is 0x41A earlier, at v7 0xFCEB48.
; Kept because another v7 file references this address by this name.
ClkTick_BeatSubdivCheck:
MIDI_CHANNEL_MESSAGE_DISPATCHER:
	ld e, a
	ld a, (1059:16)
	ld d, a
	bit 0, (1074:16)
	jrl	nz, SysEx_InProgressByte
	bit 6, (1063:16)
	jr	nz, ChanDisp_SecondDataByte
	cp a, 0:i3
	jr	z, ChanDisp_NoStatusReturn
	and a, 0x70
	srl a, 2
	xor w, w
	ld	xix, MIDI_CHANNEL_HANDLERS
	ld	xix, (xix+wa)
	jp (xix)
; MIDI_CHANNEL_HANDLER_JUMP_TABLE -- one 0xFF pad byte, then 8 handler pointers
; (MIDI_CHANNEL_HANDLERS = this label + 1), one per status-byte high nibble.
; Reader MIDI_CHANNEL_MESSAGE_DISPATCHER (just above) for each received DATA
; byte: running status from (0x423), `and a, 0x70 / srl a, 2` (= 4 * nibble
; index 0..7), `ld xix, MIDI_CHANNEL_HANDLERS / ld xix, (xix+wa) / jp (xix)`.
; Slots: 8x 9x Bx Ex (two data bytes) -> ChanDisp_AwaitSecondDataByte (sets
; bit 6 of (0x427), which routes the NEXT data byte to ChanDisp_SecondDataByte);
; Cx Dx (one data byte) ->
; MIDI_QUEUE_EVENT_TO_SEQUENCER; Ax (polyphonic key pressure) ->
; ChanDisp_NoStatusReturn, a bare `ret`, i.e. ignored; Fx ->
; MIDI_SYSTEM_EXCLUSIVE_HANDLER.  Previously spelled as `.byte` rows.
	.byte 0xff
MIDI_CHANNEL_HANDLERS:
	.long ChanDisp_AwaitSecondDataByte
	.long ChanDisp_AwaitSecondDataByte
	.long ChanDisp_NoStatusReturn
	.long ChanDisp_AwaitSecondDataByte
	.long MIDI_QUEUE_EVENT_TO_SEQUENCER
	.long MIDI_QUEUE_EVENT_TO_SEQUENCER
	.long ChanDisp_AwaitSecondDataByte
	.long MIDI_SYSTEM_EXCLUSIVE_HANDLER
ChanDisp_NoStatusReturn:
	ret
MIDI_QUEUE_EVENT_TO_SEQUENCER:
	ld xix, 0x1f37b
	cpw (xix - 2), 0x3
	jr	c, QueueToSeq_OverflowFlag
	ld a, d
	pushw wa
	call	SeqMain_WriteByte
	inc 2, xsp
	pushw de
	call	SeqMain_WriteByte
	inc 2, xsp
	ret
QueueToSeq_OverflowFlag:
	set 2, (1063:16)
	inc	1, (0xb741:16)
	ret
ChanDisp_AwaitSecondDataByte:
	set 6, (1063:16)
	ld c, e
	ret
ChanDisp_SecondDataByte:
	bit 1, (1063:16)
	jr	z, ChanDisp_ThreeByteRoute
	ld d, 0xf2:opc
ChanDisp_ThreeByteRoute:
	ld xix, 0x1f37b
	cpw (xix - 2), 0x40
	jr	ugt, ChanDisp_EnqueueThreeBytes
	pushw de
	and d, 0xf0
	cp d, 0x90
	popw de
	jr	nz, ChanDisp_EnqueueThreeBytes
	cp e, 0:i3
	jr	nz, ChanDisp_NoteOnZeroReturn
ChanDisp_EnqueueThreeBytes:
	cpw (xix - 2), 0x4
	jr	c, ChanDisp_QueueOverflowSet
	ld a, d
	pushw wa
	call	SeqMain_WriteByte
	inc 2, xsp
	ld a, c
	pushw wa
	call	SeqMain_WriteByte
	inc 2, xsp
	pushw de
	call	SeqMain_WriteByte
	inc 2, xsp
	and (1063:16), 189
ChanDisp_NoteOnZeroReturn:
	ret
ChanDisp_QueueOverflowSet:
	set 2, (1063:16)
	inc	1, (0xb741:16)
	ret
MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	ld (1059:16), 0
	cp d, 0xf0
	jr	z, SysEx_StartByte
	cp d, 0xf2
	jr	z, SysEx_SongPositionSetup
	cp d, 0xf3
	jr	z, SysEx_SongSelectQueue
	ret
SysEx_SongPositionSetup:
	or (1063:16), 66
	ld c, e
	ret
SysEx_SongSelectQueue:
	jrl	MIDI_QUEUE_EVENT_TO_SEQUENCER
SysEx_StartByte:
	ld (1074:16), 1
	cp e, 0x50
	jr	z, SysEx_CaptureManufacturerId
	cp e, 0x41
	jr	z, SysEx_CaptureManufacturerId
	cp e, 0x7e
	jr	nz, SysEx_Return
SysEx_CaptureManufacturerId:
	set 1, (1074:16)
	ld a, d
	pushw wa
	call	SeqBuf2_WriteByte
	inc 2, xsp
	pushw de
	call	SeqBuf2_WriteByte
	inc 2, xsp
SysEx_Return:
	ret
SysEx_InProgressByte:
	bit 1, (1074:16)
	jr	z, SysEx_InProgressReturn
	bit 5, (1074:16)
	jr	nz, SysEx_InProgressReturn
	pushw de
	call	SeqBuf2_WriteByte
	inc 2, xsp
SysEx_InProgressReturn:
	ret
; v7 NAME DISPLACED: `SndParam_Widget1_AppendType2_Helper2` sits where v10 has `MIDI_RX_CONTEXT_RESTORE` (v10 0xFCF85D).
; Kept because another v7 file references this address by this name.
SndParam_Widget1_AppendType2_Helper2:
MIDI_RX_CONTEXT_RESTORE:
	ld xwa, (1080:16)
	ld xbc, (1084:16)
	ld xde, (1088:16)
	ld xhl, (1092:16)
	ld xix, (1096:16)
	ld xiy, (1100:16)
	ld xiz, (1104:16)
	ret
MIDI_RX_CONTEXT_SAVE:
	ld (1080:16), xwa
	ld (1084:16), xbc
	ld (1088:16), xde
	ld (1092:16), xhl
	ld (1096:16), xix
	ld (1100:16), xiy
	ld (1104:16), xiz
	ret
SC0Init_Entry:
	res	0, (0xb74b:16)
	ld	(0xb745:16), 0
	calr	SC0Init_ClearContextSlots
	calr	SC0Init_StandardBaudTable
	calr	READ_COM_SELECT_SWITCH
	call	CompIface_SendActiveSensing
	calr	SC0Init_EnableRegisters
	ret
SC0Init_StandardBaudTable:
	call	Get_Region_Code
	cp l, 4:i3
	jr	z, SC0Init_AlternateBaudTable
	ldw	(0xb738:16), 0x7a12
	ldw	(0xb73a:16), 0x28b0
	ldw	(0xb73c:16), 0x1046
	ldw	(0xb73e:16), 0x3e8
	ld	(0xb740:16), 8
	jr	SC0Init_BaudTableReturn
SC0Init_AlternateBaudTable:
	ldw	(0xb738:16), 0x5b8d
	ldw	(0xb73a:16), 0x1e84
	ldw	(0xb73c:16), 0xc35
	ldw	(0xb73e:16), 0x2ee
	ld	(0xb740:16), 6
SC0Init_BaudTableReturn:
	ret
READ_COM_SELECT_SWITCH:
	ld a, (104:16)
	srl a, 4
	ld	xix, MidiSerial_OffsetTable
	ld	a, (xix+a)
	ld	(0xb744:16), a
	ret
; Input: Active-low "COM_SELECT"
; bit 7: MIDI
; bit 6: MAC
; bit 5: PC1
; bit 4: PC2
;
; Output:
;   000h = MIDI
;   001h = MAC
;   002h = PC1
;   003h = PC2
;
; Note: Bad switch positioning data (more than a single low-bit)
;       is treated as MIDI selection.
;
MidiSerial_OffsetTable:
; 16 x u8, indexed by bits 7..4 of the port byte at 0x68: READ_COM_SELECT_SWITCH
; does `ld a, (0x68) / srl a, 4 / ld a, (xix+a)` and stores the result in
; (0xB7E0).  Checked against the table above: index 7 (bit 7 low) -> 0 MIDI,
; 11 (bit 6 low) -> 1 MAC, 13 (bit 5 low) -> 2 PC1, 14 (bit 4 low) -> 3 PC2,
; every other pattern -> 0.  Previously spelled as 11 x `nop` / `normal` /
; `nop` / `push sr` / `pop sr` / `nop`.
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x03, 0x00
SC0Init_ClearContextSlots:
	ld (1080:16), 0
	ld (1084:16), 0
	ld (1088:16), 0
	ld (1092:16), 0
	ld (1096:16), 0
; v7 NAME DISPLACED: `MIDI_RESET_PLAYBACK_STATE` sits where v10 has no label (v10 0xFCF935).
; The v7 code v10 calls `MIDI_RESET_PLAYBACK_STATE` is 0x41A earlier, at v7 0xFCED4A.
; Kept because another v7 file references this address by this name.
MIDI_RESET_PLAYBACK_STATE:
	ld (1100:16), 0
	ld (1104:16), 0
	ret
SC0Init_EnableRegisters:
	ei 6
	ld (210:16), 41
	ld (209:16), 0
	ld	a, (0xb740:16)
	ld (211:16), a
	ld (234:16), 93
	ld (208:16), 254
	ei 0
	ret
SC0Init_PaddingStub:
	ret
; MIDI_SC0_DISPATCH_TABLE -- 4 handler pointers: SC0Init_Entry, then
; SC0Init_PaddingStub (a bare `ret`) three times.  Nothing in this file reads
; it; its only reference is entry 3 of SystemConfig_PointerTable
; (ui_widgets/widget_dispatch.s), and the reader of THAT table was not traced
; by the midi lane, so the indexing is not pinned here beyond the 4 entries
; that fit before MIDI_SC0_TX_DISPATCH.
MIDI_SC0_DISPATCH_TABLE:
	.long SC0Init_Entry
	.long SC0Init_PaddingStub
	.long SC0Init_PaddingStub
	.long SC0Init_PaddingStub
MIDI_SC0_TX_DISPATCH:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	cp	(0xb744:16), 0
	jr	nz, SC0TxDisp_NonMidiPath
	calr	MIDI_SC0_ENABLE_TX
	jr	SC0TxDisp_RestoreAndReturn
SC0TxDisp_NonMidiPath:
	call	SeqBuf3_EnableTx_Stub
SC0TxDisp_RestoreAndReturn:
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret
MIDI_SC0_ENABLE_TX:
	push	sr
	ei 6
	cp (1140:16), 85
	jr	z, SC0TxEnable_MidiActivePath
	ld (234:16), 221
	jr	SC0TxEnable_Return
SC0TxEnable_MidiActivePath:
	call	SeqBuf_MidiOut_Init
	ld (1065:16), 0
SC0TxEnable_Return:
	pop	sr
	ret
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
	jr	nz, MidiSerial_Return
	call	SeqMain_SaveWritePos
	ldw	(0x9042:16), 0
MidiSerial_PumpLoop:
	ld xix, 0x1f37b
	ld wa, (xix - 10)
	cp wa, (xix - 6)
	jr	z, MidiSerial_PumpDone
	and (1064:16), 254
	call	MidiSerial_WaitForData
	ld	a, (0x9598:16)
	ld	(0x95b8:16), a
	and a, 0x70
	srl a, 2
	ld	xiz, MidiSerial_StatusHandlers
	ld	xiz, (xiz+a)
	call (xiz)
	jr	MidiSerial_PumpLoop
MidiSerial_PumpDone:
	call	MidiStream_LoadAllPresets
	ld	xix, 0xbca0
	ld	hl, (0x9042:16)
	ld	(xix+hl), 0xff
MidiSerial_Return:
	ret
; MidiSerial_StatusTable -- one 0xFF pad byte, then 8 handler pointers indexed by
; the status byte's high nibble.  Reader MidiSerial_PumpLoop (this file): `ld a,
; (0x9634) / and a, 0x70 / srl a, 2` (= 4 * ((status >> 4) & 7)), `ld xiz,
; MidiSerial_StatusTable_0x1 / ld xiz, (xiz+a) / call (xiz)`, so entry 0 is at +1
; (MidiSerial_StatusTable_0x1 = this label + 1, shared/positional_labels.s) and
; 8 entries reach MidiSerial_WaitForData.  Slots 0-6 (8x note off .. Ex pitch
; bend) -> MidiRx_ChannelMsgDispatch; slot 7 (Fx) -> MidiRx_SystemMsgDispatch,
; which dispatches system messages on the low nibble through
; MidiSerial_CmdJumpTable.  Previously spelled as `swi 7 / cpm_spiw ix, 250 /
; nop` x 7.
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
	ld	xiy, 0x9598
	ld (xiy + 3), 0x0
MidiSerial_WaitLoop:
	call	SeqMain_ReadData
	ld (xiy+), l
	ld hl, (xiz - 10)
	cp hl, (xiz - 6)
	jr	z, MidiSerial_WaitDone
	ld	a, (xiz+hl)
	bit 7, a
	jr	z, MidiSerial_WaitLoop
MidiSerial_WaitDone:
	ret
MidiRx_SystemMsgDispatch:
	ld	l, (0x9598:16)
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
	ld	wa, (0x9599:16)
	ld	(1069:16), a
	bit	2, (0xfd52:16)
	jr	z, 3
	set	7, w
	ld	(1070:16), w
	ret
MidiSerial_HandleSongSelect:
	ld	a, (0x9599:16)
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
	ld	a, (0x9598:16)
	and	a, 15
	ld	xhl, 0x9458
	ld	a, (xhl+a)
	cp a, 255
	jr	z, MidiRx_ChannelMsgDispatch_Return
	ld	(0x95cc:16), a
	ld	xhl, 0x9478
	ld	a, (xhl+a)
	cp a, 0:i3
	jr	z, MidiRx_ChannelMsgDispatch_Return
	ld	(0x95cd:16), a
	ld	(0x95cf:16), a
	inc	1, (0x95cc:16)
	xor	h, h
	ld	l, (0x95cc:16)
	ld	xix, 0x9478
	ld	a, (xix+hl)
	ld	(0x95ce:16), a
	xor h, h
	ld	l, (0x9598:16)
	and l, 112
	srl	hl, 2
	ld	xix, MidiCC_LowRange_Table
	ld	xix, (xix+hl)
	call (xix)
	dec	1, (0x95cf:16)
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
	ld	xix, 0xfd0696
	ld	l, (0x9599:16)
	ld	a, (xix+l)
	ld	(0x95bb:16), a
	cp a, 255
	jr z, 56
; v7 NAME DISPLACED: `MIDI_CHANNEL_HANDLER_JUMP_TABLE` sits where v10 has no label (v10 0xFCFB7A).
; The v7 code v10 calls `MIDI_CHANNEL_HANDLER_JUMP_TABLE` is 0x41A earlier, at v7 0xFCEF8F.
; Kept because another v7 file references this address by this name.
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
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
	ld	a, (0x95bb:16)
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
	.long 0x00fcf841
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
	.long 0x00fcf4a3
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
	bit	2, (0xfd51:16)
	jr	z, MidiCC_Handler_BitManipulation_Return
	ld	a, (0x95ce:16)
	cp	a, 25
	jr	nz, MidiCC_Handler_BitManipulation_Return
	cp	(0x95bb:16), 18
	jr	nz, MidiCC_Handler_BitManipulation_Return
	xor	e, e
	ld	a, (0x959a:16)
	cp	a, 2:i3
	jr	ugt, MidiCC_Handler_BitManipulation_Skip
	ld	xix, MidiCC_CC83_ValueMap
	ld	e, (xix+a)
MidiCC_Handler_BitManipulation_Skip:
	ldw bc, 2968
	ld d, 192:opc
	ld	a, (0x959b:16)
	ld	(0x95ac:16), a
	ld	(0x95a8:16), bc
	ld	(0x95aa:16), de
	call	VoiceMode_ParamConfigTables_0xB68
MidiCC_Handler_BitManipulation_Return:
	ret
; 0xFF filler after the `ret`; nothing reads it (the table below starts at +1).
	.byte 0xff
; MidiCC_CC83_ValueMap (0xFCF4E8, 3 x u8): controller value 0..2 -> E.  Reader
; MidiCC_Handler_BitManipulation (0xFCF8BD), CC function 18 <- CC83
; (MidiCC_ChannelMappingData): only for part 25, with `bit 2, (0xfd51)` set;
; `ld a, (0x9636) / cp a, 2 / jr ugt` (E stays 0 above 2) / `ld e, (xix+a)`,
; then BC = 0x0B98, D = 0xC0 -> VoiceMode_ParamConfigTables_0xB68.
; Previously spelled `.byte 0x80, 0x40` behind a `nop`.
MidiCC_CC83_ValueMap:
	.byte 0x00, 0x80, 0x40
MidiCC_Handler_PairedParamA:
	extz	hl
	ld	l, (0x95ce:16)
	cp	l, 31
	jr	ugt, MidiCC_Handler_PairedParamA_Return
	bit	4, (0xfd57:16)
	jr	z, MidiCC_Handler_PairedParamA_Return
	sll	hl, 1
	ld	xix, MidiCC_PartTargets_BankSelect
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_PairedParamA_Return
	ld	e, (0x959a:16)
	ld	d, 255:opc
	ld	a, (0x959b:16)
	ld	(0x95ac:16), a
	ld	(0x95a8:16), bc
	ld	(0x95aa:16), de
	call	MidiStream_ExtendedDispatch_0x298
MidiCC_Handler_PairedParamA_Return:
	ret
MidiCC_Handler_PairedParamB:
	extz	hl
	ld	l, (0x95ce:16)
	cp	l, 31
	jr	ugt, MidiCC_Handler_PairedParamB_Return
	bit	4, (0xfd57:16)
	jr	z, MidiCC_Handler_PairedParamB_Return
	sll	hl, 1
	ld	xix, MidiCC_PartTargets_BankSelect
	ld	bc, (xix+hl)
	cp c, 255
	jr	z, MidiCC_Handler_PairedParamB_Return
	ld	d, (0x959a:16)
	ld	e, 255:opc
	ld	a, (0x959b:16)
	ld	(0x95ac:16), a
	ld	(0x95a8:16), bc
	ld	(0x95aa:16), de
	call	MidiStream_ExtendedDispatch_0x298
MidiCC_Handler_PairedParamB_Return:
	ret
MidiCC_Handler_RangeCheck:
	ld	a, (0x95ce:16)
	cp	a, 16
	jr	nz, MidiCC_Handler_RangeCheck_Return
	cp	(0x95bb:16), 16
	jr	nz, MidiCC_Handler_RangeCheck_Return
	xor	e, e
	ld	a, (0x959a:16)
	cp	a, 3:i3
	jr	ugt, MidiCC_Handler_RangeCheck_Skip
	ld	xix, MidiCC_CC80_ValueMap
	ld	e, (xix+a)
MidiCC_Handler_RangeCheck_Skip:
	ldw bc, 840
	ld	d, 7:opc
	ld	a, (0x959b:16)
	ld	(0x95ac:16), a
	ld	(0x95a8:16), bc
	ld	(0x95aa:16), de
	call	MidiStream_ApplyPendingParams
MidiCC_Handler_RangeCheck_Return:
	ret
; 0xFF filler after the `ret`; nothing reads it (the table below starts at +1).
	.byte 0xff
; MidiCC_CC80_ValueMap (0xFCF5A6, 4 x u8): controller value 0..3 -> E.  Reader
; MidiCC_Handler_RangeCheck (0xFCF567), CC function 16 <- CC80: only for part 16;
; `ld a, (0x9636) / cp a, 3 / jr ugt` (E stays 0 above 3) / `ld e, (xix+a)`,
; then BC = 0x0348, D = 7 -> MidiStream_ApplyPendingParams.  Previously
; spelled `nop / push sr / normal / pop sr`.
MidiCC_CC80_ValueMap:
	.byte 0x00, 0x02, 0x01, 0x03
MidiCC_Handler_ChannelMapping:
	ld	a, (0x95ce:16)
	cp	a, 20
	jr	nz, MidiCC_Handler_ChannelMapping_Return
	cp	(0x95bb:16), 17
	jr	nz, MidiCC_Handler_ChannelMapping_Return
	ld	b, 5:opc
	ldw	de, 0xfc00
	ld	a, (0x959a:16)
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
	ld	(0x33ed:16), b
	ld	(0x33e0:16), e
	ld	(0x33e1:16), d
	call	AccWrap_ReplaySavedExpr
	popw	de
	popw	bc
	cp	e, 0:i3
	jr	nz, MidiCC_Handler_ChannelMapping_Return
; End of MIDI Serial routines
