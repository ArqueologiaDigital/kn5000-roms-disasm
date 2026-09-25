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

MIDI_INIT_SEQUENCES:
	calr SndParam_InitHashTable
	calr SndParam_RegisterAllWidgets
	calr SndParam_ClearHashTable
	calr SndParam_ReregisterAll
	lda xbc, (0x9798:16)
	ld xwa, xbc
	lda xbc, (xbc + 64)

MidiInit_FillLoop:
	stiw_dsp 0xe1, 0x00, 0x00
	cp xwa, xbc
	jr c, MidiInit_FillLoop
	ret

MidiInit_Stub1:
	ret

MidiInit_Stub2:
	ret

MidiInit_Stub3:
	ret

INTRX0_CLEAR_ERROR_STATE:
	pushw wa
	ld a, (208:16)
	ld (1059:16), 0
	and (1063:16), 189
	set 3, (1063:16)
	ld (1074:16), 0
	inc 1, (0xb7de:16)
	popw wa
	reti

INTTX0_HANDLER:
	pushw wa
	pushw hl
	ld a, (1065:16)
	bit 0, a
	jr nz, IntTx0_FlagBit0Branch
	bit 4, a
	jr nz, IntTx0_FlagBit4Branch
	bit 1, a
	jr nz, IntTx0_FlagBit1Branch
	bit 2, a
	jr nz, IntTx0_FlagBit2Branch
	bit 3, a
	jr z, IntTx0_DequeueAndSend
	res 3, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, IntTx0_SendHoldByte
	ld (208:16), 252
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit0Branch:
	res 0, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, IntTx0_SendHoldByte
	ld (208:16), 248
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit4Branch:
	res 4, (1065:16)

IntTx0_SendHoldByte:
	ld (208:16), 254
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit1Branch:
	res 1, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, IntTx0_SendHoldByte
	ld (208:16), 250
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit2Branch:
	res 2, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, IntTx0_SendHoldByte
	ld (208:16), 251
	jr IntTx0_CheckQueueEmpty

IntTx0_DequeueAndSend:
	call SeqBuf_MidiOut_ReadByte
	cp hl, 0xffff
	jr z, IntTx0_CheckQueueEmpty
	ld (208:16), l

IntTx0_CheckQueueEmpty:
	ld a, (1065:16)
	and a, 0x1f
	jr nz, IntTx0_Epilogue
	call SeqBuf_MidiOut_CheckEmpty
	and hl, hl
	jr nz, IntTx0_Epilogue
	ld (234:16), 253

IntTx0_Epilogue:
	popw hl
	popw wa
	reti

INTRX0_HANDLER:
	pushw wa
	ld a, (209:16)
	and a, 0x1c
	popw wa
	jrl nz, INTRX0_CLEAR_ERROR_STATE
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, (208:16)
	ld (1061:16), 0
	dec 2, xsp
	ld (xsp), a
	lda xwa, (xsp)
	push xwa
	ld wa, 1:i3
	pushw wa
	call MidiSeq_ReceiveAndForward
	inc 8, xsp
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	reti

MIDI_RX_BYTE_DISPATCHER:
	ld (0xb7df:16), a
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	calr MIDI_RX_CONTEXT_RESTORE
	ld a, (0xb7df:16)
	bit 7, a
	jr z, RxDisp_DataByteDispatch
	cp a, 0xf7
	jr ule, RxDisp_StatusByte
	calr MIDI_SYSTEM_MESSAGE_HANDLER
	jr RxDisp_SaveContextAndReturn

RxDisp_StatusByte:
	ld (1059:16), a
	and (1063:16), 189
	bit 0, (1074:16)
	jr z, RxDisp_SaveContextAndReturn
	bit 1, (1074:16)
	jr z, RxDisp_ClearSysExState
	cp a, 0xf7
	jr nz, RxDisp_SysExError
	bit 5, (1074:16)
	jr nz, RxDisp_ClearSysExState
	pushw wa
	call SeqBuf2_WriteByte
	inc 2, xsp
	ld (1074:16), 4

RxDisp_ClearSysExState:
	ld (1059:16), 0
	and (1074:16), 204
	jr RxDisp_SaveContextAndReturn

RxDisp_SysExError:
	ld (1074:16), 16
	ld (1059:16), 0
	jr RxDisp_SaveContextAndReturn

RxDisp_DataByteDispatch:
	calr MIDI_CHANNEL_MESSAGE_DISPATCHER

RxDisp_SaveContextAndReturn:
	calr MIDI_RX_CONTEXT_SAVE
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_SYSTEM_MESSAGE_HANDLER:
	cp a, 0xfe
	jr nz, SysMsg_NotActiveSense
	set 7, (1063:16)

SysMsg_Return:
	ret

SysMsg_NotActiveSense:
	bit 4, (0xfd50:16)
	jr nz, SysMsg_Return
	cp a, 0xfd
	jr nc, SysMsg_Return
	bit 6, (0xb7e2:16)
	jr nz, SysMsg_Return
	cp (0x7f0b:16), 0
	jr z, SysMsg_ClockTransportDispatch
	cp a, 0xfa
	jr nz, SysMsg_CheckStop
	call AccPlay_StopEntry
	ret

SysMsg_CheckStop:
	cp a, 0xfc
	jr nz, SysMsg_ClockTransportDispatch
	set 0, (0x7f35:16)

SysMsg_ClockTransportDispatch:
	ld d, a
	bit 2, (0xfd50:16)
	jrl z, AltClk_DisabledClockPath
	cp d, 0xf8
	jr nz, ClkTick_PerClockCounters
	bit 5, (0x28ac:16)
	jr z, ClkTick_TempoThresholdCheck
	inc 1, (1108:16)

ClkTick_TempoThresholdCheck:
	ld a, (1066:16)
	cp a, 0x70
	jr ugt, ClkTick_HighTempoLoad
	cp a, 4:i3
	jr ugt, ClkTick_MidRangeTempoMul
	ld wa, (0xb7d8:16)
	jr ClkTick_WriteTimingReg

ClkTick_MidRangeTempoMul:
	extz xwa
	xor w, w
	muls_sd16w 0, 0xda, 0xb7
	jr ClkTick_WriteTimingReg

ClkTick_HighTempoLoad:
	ld wa, (0xb7d6:16)

ClkTick_WriteTimingReg:
	ld (146:16), wa; LD (TREG5L), WA
	ld (1066:16), 0
	bit 0, (1055:16)
	jr z, ClkTick_BeatSubdivCheck
	ld (1055:16), 6

ClkTick_BeatSubdivCheck:
	bit 2, (1055:16)
	jr z, ClkTick_PerClockCounters
	and (1130:16), 252
	inc 4, (1130:16)
	cp (1130:16), 96
	jr nz, ClkTick_PerClockCounters
	ld (1130:16), 0
	incw 1, (1128:16)
	cp (0x7f0b:16), 0
	jr z, ClkTick_PerClockCounters
	calr MIDI_QUEUE_TRACK_EVENT

ClkTick_PerClockCounters:
	ld a, (1056:16)
	pushw wa
	and a, 0x5
	popw wa
	jrl z, Transport_NoClockSourcePath
	cp d, 0xf8
	jrl nz, Transport_StopHandler
	bit 0, a
	jr z, ClkTick_Src2ClickIncrement
	ld (1056:16), 6
	bit 0, (1054:16)
	jr z, ClkTick_Src1FineUpdate
	ld (1054:16), 6

ClkTick_Src1FineUpdate:
	bit 0, (1057:16)
	jr z, ClkTick_Src1CoarseUpdate
	ld (1057:16), 6

ClkTick_Src1CoarseUpdate:
	jrl Transport_StopHandler

ClkTick_Src2ClickIncrement:
	bit 2, a
	jr z, ClkTick_Src2FineBeatCheck
	and (1047:16), 252
	inc 4, (1047:16)
	cp (1047:16), 96
	jr nz, ClkTick_Src2FineBeatCheck
	ld (1047:16), 0
	incw 1, (1048:16)

ClkTick_Src2FineBeatCheck:
	bit 2, (1054:16)
	jr z, ClkTick_Src2ErrorDelta
	and (1045:16), 252
	inc 4, (1045:16)
	cp (1045:16), 96
	jr nz, ClkTick_Src2ErrorDelta
	ld (1045:16), 0
	inc 1, (1046:16)
	ld a, (0x379b:16)
	and a, 0x1f
	jr z, ClkTick_Src2CoarseOverflow
	calr MIDI_QUEUE_TRACK_EVENT

ClkTick_Src2CoarseOverflow:
	ld a, (1046:16)
	ld w, (1075:16)
	ex_sd16b W, 0x58, 0x04
	cp a, w
	jr c, ClkTick_Src2ErrorDelta
	ld (1046:16), 0
	inc 1, (1076:16)
	inc 1, (1077:16)
	ld a, (1077:16)
	cp a, (0x34d7:16)
	jr ule, ClkTick_Src2ErrorDelta
	ld (1077:16), 0

ClkTick_Src2ErrorDelta:
	ld a, (1045:16)
	ld w, a
	sub a, (1111:16)
	jr z, ClkTick_Src3ClickCheck
	jr ugt, ClkTick_Src2ErrorAccumulate
	add a, 0x60

ClkTick_Src2ErrorAccumulate:
	ld (1111:16), w
	add (1124:16), a
	add (1122:16), a
	xor w, w
	add wa, (1120:16)
	cp a, 0x60
	jr c, ClkTick_Src2ErrorWriteback
	sub a, 0x60
	inc 1, w

ClkTick_Src2ErrorWriteback:
	ld (1120:16), wa

ClkTick_Src3ClickCheck:
	bit 2, (1057:16)
	jr z, Transport_StopHandler
	and (1051:16), 252
	inc 4, (1051:16)
	ld a, (1051:16)
	bit 0, (1073:16)
	jr z, ClkTick_Src3LowerSyncCheck
	cp a, (1071:16)
	jr nz, ClkTick_Src3LowerSyncCheck
	res 0, (1073:16)
	ld (1054:16), 1
	cpw (0x28aa:16), 0
	jr z, ClkTick_Src3LowerSyncCheck
	ld a, 0x85:opc
	calr MIDI_QUEUE_EVENT_PAIR

ClkTick_Src3LowerSyncCheck:
	bit 3, (1073:16)
	jr z, ClkTick_Src3OverflowQueue
	cp a, (1072:16)
	jr nz, ClkTick_Src3OverflowQueue
	res 3, (1073:16)
	ld (1054:16), 8
	cpw (0x28aa:16), 0
	jr z, ClkTick_Src3OverflowQueue
	ld a, 0x86:opc
	calr MIDI_QUEUE_EVENT_PAIR

ClkTick_Src3OverflowQueue:
	cp (1051:16), 96
	jr nz, Transport_Return
	ld (1051:16), 0
	incw 1, (1052:16)
	cpw (0x28aa:16), 0
	jr z, Transport_StopHandler
	calr MIDI_QUEUE_TRACK_EVENT

Transport_StopHandler:
	bit 2, (0xfd52:16)
	jr z, Transport_Return
	cp d, 0xfc
	jr nz, Transport_Return
	ld (1056:16), 16
	bit 2, (1054:16)
	jr z, Transport_StopSrc3Snapshot
	bit 2, (1057:16)
	jr z, Transport_StopSrc1QueueEvent
	set 2, (0x347a:16)

Transport_StopSrc1QueueEvent:
	ld (1054:16), 16
	cpw (0x28aa:16), 0
	jr z, Transport_StopSrc3Snapshot
	ld a, 0x86:opc
	calr MIDI_QUEUE_EVENT_PAIR

Transport_StopSrc3Snapshot:
	bit 2, (1057:16)
	jr z, Transport_Return
	ld (1057:16), 16
	pushw wa
	ld a, (1045:16)
	ld (1078:16), a
	ld a, (1046:16)
	ld (1079:16), a
	popw wa

Transport_Return:
	ret

Transport_NoClockSourcePath:
	bit 2, (0xfd52:16)
	jr z, Transport_StopSrc3Snapshot
	bit 2, (0x28a7:16)
	jr nz, Transport_NoClockReturn
	cp d, 0xfa
	jr z, StartPlay_Body
	cp d, 0xfb
	jrl z, Continue_SetRunning

Transport_NoClockReturn:
	ret

MIDI_START_PLAYBACK_REQUEST:
	cpw (0xf19e:16), 0
	jr z, StartPlay_Return
	push	sr
	ei 6
	calr MIDI_RESET_PLAYBACK_STATE
	calr MIDI_APPLY_STARTUP_TIMING
	pop	sr

StartPlay_Return:
	ret

StartPlay_Body:
	set 5, (0x28ac:16)
	ld (1108:16), 0
	cpw (0xf19e:16), 0
	jr nz, ResetPlay_Return

MIDI_RESET_PLAYBACK_STATE:
	xor wa, wa
	ld (1047:16), a
	ld (1048:16), wa
	ld (1056:16), 1
	bit 1, (0x28a7:16)
	jr z, ResetPlay_Src3Check
	ld (1045:16), a
	ld (1046:16), a
	ld (1076:16), a
	ld (1077:16), a
	ld (1054:16), 1
	res 0, (0x28a6:16)
	cpw (0x28aa:16), 0
	jr z, ResetPlay_Src3Check
	ld a, 0x85:opc
	calr MIDI_QUEUE_EVENT_PAIR

ResetPlay_Src3Check:
	bit 0, (0x28a7:16)
	jr z, ResetPlay_Return
	xor wa, wa
	ld (1051:16), a
	ld (1052:16), wa
	ld (1057:16), 1

ResetPlay_Return:
	ret

MIDI_APPLY_STARTUP_TIMING:
	cp (1108:16), 0
	jr z, StartTiming_ClearAndReturn
	bit 0, (1056:16)
	jr z, StartTiming_ClearAndReturn
	ld (1056:16), 6
	ld a, (1108:16)
	dec 1, a
	sll a, 2
	add (1047:16), a
	bit 0, (1055:16)
	jr z, StartTiming_Src1Adjust
	ld (1055:16), 6
	add (1130:16), a

StartTiming_Src1Adjust:
	bit 0, (1054:16)
	jr z, StartTiming_Src2Adjust
	ld (1054:16), 6
	add (1045:16), a

StartTiming_Src2Adjust:
	bit 0, (1057:16)
	jr z, StartTiming_ClearAndReturn
	ld (1057:16), 6
	add (1051:16), a

StartTiming_ClearAndReturn:
	ld (1108:16), 0
	ret

Continue_SetRunning:
	ld (1056:16), 6
	bit 0, (0x28a7:16)
	jr z, Continue_Return
	ld (1057:16), 6
	bit 1, (0x28a7:16)
	jr z, Continue_Return
	bit 0, (0x28a6:16)
	jr nz, Continue_ClearPositionAndSetSrc1
	ld (1045:16), 0
	ld (1046:16), 0

Continue_ClearPositionAndSetSrc1:
	ld (1076:16), 0
	ld (1077:16), 0
	and (0x28a6:16), 254
	ld (1054:16), 6

Continue_Return:
	ret

AltClk_DisabledClockPath:
	ld (1066:16), 0
	pushw wa
	ld a, (1056:16)
	and a, 0x5
	popw wa
	jr z, AltClk_NoSrcFlagPath
	bit 2, (0xfd52:16)
	jr z, AltClk_Return
	cp d, 0xfc
	jr nz, AltClk_Return
	ld (1056:16), 12
	bit 2, (1054:16)
	jr z, AltClk_StopSrc3Snapshot
	bit 2, (1057:16)
	jr z, AltClk_StopSrc1Queue
	set 2, (0x347a:16)

AltClk_StopSrc1Queue:
	ld (1054:16), 12
	cpw (0x28aa:16), 0
	jr z, AltClk_StopSrc3Snapshot
	ld a, 0x86:opc
	calr MIDI_QUEUE_EVENT_PAIR

AltClk_StopSrc3Snapshot:
	bit 2, (1057:16)
	jr z, AltClk_Return
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
	jr z, AltClk_NoMatchReturn
	bit 2, (0x28a7:16)
	jr nz, AltClk_NoMatchReturn
	cp d, 0xfa
	jr z, AltClk_StartArmTx
	cp d, 0xfb
	jr z, AltClk_ContinueArmTx

AltClk_NoMatchReturn:
	ret

AltClk_StartArmTx:
	set 1, (1065:16)
	ld (234:16), 221
	jrl StartPlay_Body

AltClk_ContinueArmTx:
	bit 0, (0x28a7:16)
	jr z, AltClk_Src3DisabledReturn
	set 2, (1065:16)
	ld (234:16), 221
	jrl Continue_SetRunning

AltClk_Src3DisabledReturn:
	ret

MIDI_QUEUE_TRACK_EVENT:
	bit 0, (1113:16)
	jr nz, QueueTrack_LinearBufWrite
	pushw wa
	ld xix, 0x1e753
	ld wa, (xix - 2)
	and wa, wa
	jr z, QueueTrack_FifoWriteOrClear
	ld hl, (xix - 4)
	stib_ind 0x07, 0xf0, 0xec, 0x81
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
	stib_ind 0x07, 0xf0, 0xec, 0x81
	inc 1, hl
	ld (1141:16), hl
	ret

MIDI_QUEUE_EVENT_PAIR:
	bit 0, (1113:16)
	jr nz, QueuePair_LinearBufWrite
	cpw (0x01e751:24), 2
	jr c, QueuePair_FifoFullReturn
	push	sr
	ei 6
	ld xix, 0x1e753
	ld hl, (xix - 4)
	stb_dri A, 0x07, 0xf0, 0xec
	minc1_16 hl, 0x7ff
	ld a, (1051:16)
	stb_dri A, 0x07, 0xf0, 0xec
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
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, hl
	ld a, (1051:16)
	stb_dri A, 0x07, 0xf0, 0xec
	inc 1, hl
	ld (1141:16), hl
	ret

MIDI_CHANNEL_MESSAGE_DISPATCHER:
	ld e, a
	ld a, (1059:16)
	ld d, a
	bit 0, (1074:16)
	jrl nz, SysEx_InProgressByte
	bit 6, (1063:16)
	jr nz, ChanDisp_SecondDataByte
	cp a, 0:i3
	jr z, ChanDisp_NoStatusReturn
	and a, 0x70
	srl a, 2
	xor w, w
	ld xix, MIDI_CHANNEL_HANDLERS
	ld_sril3 XIX, 0x07, 0xf0, 0xe0
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
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
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
	jr c, QueueToSeq_OverflowFlag
	ld a, d
	pushw wa
	call SeqMain_WriteByte
	inc 2, xsp
	pushw de
	call SeqMain_WriteByte
	inc 2, xsp
	ret

QueueToSeq_OverflowFlag:
	set 2, (1063:16)
	inc 1, (0xb7dd:16)
	ret

ChanDisp_AwaitSecondDataByte:
	set 6, (1063:16)
	ld c, e
	ret

ChanDisp_SecondDataByte:
	bit 1, (1063:16)
	jr z, ChanDisp_ThreeByteRoute
	ld d, 0xf2:opc

ChanDisp_ThreeByteRoute:
	ld xix, 0x1f37b
	cpw (xix - 2), 0x40
	jr ugt, ChanDisp_EnqueueThreeBytes
	pushw de
	and d, 0xf0
	cp d, 0x90
	popw de
	jr nz, ChanDisp_EnqueueThreeBytes
	cp e, 0:i3
	jr nz, ChanDisp_NoteOnZeroReturn

ChanDisp_EnqueueThreeBytes:
	cpw (xix - 2), 0x4
	jr c, ChanDisp_QueueOverflowSet
	ld a, d
	pushw wa
	call SeqMain_WriteByte
	inc 2, xsp
	ld a, c
	pushw wa
	call SeqMain_WriteByte
	inc 2, xsp
	pushw de
	call SeqMain_WriteByte
	inc 2, xsp
	and (1063:16), 189

ChanDisp_NoteOnZeroReturn:
	ret

ChanDisp_QueueOverflowSet:
	set 2, (1063:16)
	inc 1, (0xb7dd:16)
	ret

MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	ld (1059:16), 0
	cp d, 0xf0
	jr z, SysEx_StartByte
	cp d, 0xf2
	jr z, SysEx_SongPositionSetup
	cp d, 0xf3
	jr z, SysEx_SongSelectQueue
	ret

SysEx_SongPositionSetup:
	or (1063:16), 66
	ld c, e
	ret

SysEx_SongSelectQueue:
	jrl MIDI_QUEUE_EVENT_TO_SEQUENCER

SysEx_StartByte:
	ld (1074:16), 1
	cp e, 0x50
	jr z, SysEx_CaptureManufacturerId
	cp e, 0x41
	jr z, SysEx_CaptureManufacturerId
	cp e, 0x7e
	jr nz, SysEx_Return

SysEx_CaptureManufacturerId:
	set 1, (1074:16)
	ld a, d
	pushw wa
	call SeqBuf2_WriteByte
	inc 2, xsp
	pushw de
	call SeqBuf2_WriteByte
	inc 2, xsp

SysEx_Return:
	ret

SysEx_InProgressByte:
	bit 1, (1074:16)
	jr z, SysEx_InProgressReturn
	bit 5, (1074:16)
	jr nz, SysEx_InProgressReturn
	pushw de
	call SeqBuf2_WriteByte
	inc 2, xsp

SysEx_InProgressReturn:
	ret

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
	res 0, (0xb7e7:16)
	ld (0xb7e1:16), 0
	calr SC0Init_ClearContextSlots
	calr SC0Init_StandardBaudTable
	calr READ_COM_SELECT_SWITCH
	call CompIface_SendActiveSensing
	calr SC0Init_EnableRegisters
	ret

SC0Init_StandardBaudTable:
	call Get_Region_Code
	cp l, 4:i3
	jr z, SC0Init_AlternateBaudTable
	ldw (0xb7d4:16), 0x7a12
	ldw (0xb7d6:16), 0x28b0
	ldw (0xb7d8:16), 4166
	ldw (0xb7da:16), 1000
	ld (0xb7dc:16), 8; BR0CR: clk=fc/4/8 = 500kHz (baudrate for MIDI ?!)
	jr SC0Init_BaudTableReturn

SC0Init_AlternateBaudTable:
	ldw (0xb7d4:16), 0x5b8d
	ldw (0xb7d6:16), 7812
	ldw (0xb7d8:16), 3125
	ldw (0xb7da:16), 750
	ld (0xb7dc:16), 6; BR0CR: clk=fc/4/6 = 666.6kHz (baudrate for MIDI ?!)

SC0Init_BaudTableReturn:
	ret

READ_COM_SELECT_SWITCH:
	ld a, (104:16)
	srl a, 4
	ld xix, MidiSerial_OffsetTable
	ldb_sri A, 0x03, 0xf0, 0xe0
	ld (0xb7e0:16), a
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
	ld (1100:16), 0
	ld (1104:16), 0
	ret

SC0Init_EnableRegisters:
	ei 6
	ld (210:16), 41
	ld (209:16), 0
	ld a, (0xb7dc:16)
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
	cp (0xb7e0:16), 0; 000h means MIDI
	jr nz, SC0TxDisp_NonMidiPath
	calr MIDI_SC0_ENABLE_TX
	jr SC0TxDisp_RestoreAndReturn

SC0TxDisp_NonMidiPath:
	call SeqBuf3_EnableTx_Stub

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
	jr z, SC0TxEnable_MidiActivePath
	ld (234:16), 221
	jr SC0TxEnable_Return

SC0TxEnable_MidiActivePath:
	call SeqBuf_MidiOut_Init
	ld (1065:16), 0

SC0TxEnable_Return:
	pop	sr
	ret

; End of MIDI Serial routines

