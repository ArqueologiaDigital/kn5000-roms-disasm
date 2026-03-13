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
;     SC0BUF (0xD0) - Serial buffer
;     SC0CR  (0xD1) - Control register
;     SC0MOD (0xD2) - Mode register
;     BR0CR  (0xD3) - Baud rate control
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
	ldada xbc, 38808
	ld xwa, xbc
	lda xbc, (xbc + 64)

MidiInit_FillLoop:
	stiw_dpi 0xE1, 0x00, 0x00
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
	ldda8 a, 208
	stdi8 1059, 0
	anddi8 1063, 189
	setda 3, 1063
	stdi8 1074, 0
	incdi8 1, 47070
	popw wa
	reti

INTTX0_HANDLER:
	pushw wa
	pushw hl
	ldda8 a, 1065
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
	resda 3, 1065
	bitda 4, 64848
	jr nz, IntTx0_SendHoldByte
	stdi8 208, 252
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit0Branch:
	resda 0, 1065
	bitda 4, 64848
	jr nz, IntTx0_SendHoldByte
	stdi8 208, 248
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit4Branch:
	resda 4, 1065

IntTx0_SendHoldByte:
	stdi8 208, 254
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit1Branch:
	resda 1, 1065
	bitda 4, 64848
	jr nz, IntTx0_SendHoldByte
	stdi8 208, 250
	jr IntTx0_CheckQueueEmpty

IntTx0_FlagBit2Branch:
	resda 2, 1065
	bitda 4, 64848
	jr nz, IntTx0_SendHoldByte
	stdi8 208, 251
	jr IntTx0_CheckQueueEmpty

IntTx0_DequeueAndSend:
	call SeqBuf_MidiOut_ReadByte
	cp hl, 0xFFFF
	jr z, IntTx0_CheckQueueEmpty
	stda8 208, l

IntTx0_CheckQueueEmpty:
	ldda8 a, 1065
	and a, 0x1F
	jr nz, IntTx0_Epilogue
	call SeqBuf_MidiOut_CheckEmpty
	and hl, hl
	jr nz, IntTx0_Epilogue
	stdi8 234, 253

IntTx0_Epilogue:
	popw hl
	popw wa
	reti

INTRX0_HANDLER:
	pushw wa
	ldda8 a, 209
	and a, 0x1C
	popw wa
	jrl nz, INTRX0_CLEAR_ERROR_STATE
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ldda8 a, 208
	stdi8 1061, 0
	dec 2, xsp
	ld (xsp), a
	lda xwa, (xsp)
	push xwa
	lds wa, 1
	pushw wa
	call LABEL_FDB7DC
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
	stda8 47071, a
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	calr MIDI_RX_CONTEXT_RESTORE
	ldda8 a, 47071
	bit 7, a
	jr z, RxDisp_DataByteDispatch
	cp a, 0xF7
	jr ule, RxDisp_StatusByte
	calr MIDI_SYSTEM_MESSAGE_HANDLER
	jr RxDisp_SaveContextAndReturn

RxDisp_StatusByte:
	stda8 1059, a
	anddi8 1063, 189
	bitda 0, 1074
	jr z, RxDisp_SaveContextAndReturn
	bitda 1, 1074
	jr z, RxDisp_ClearSysExState
	cp a, 0xF7
	jr nz, RxDisp_SysExError
	bitda 5, 1074
	jr nz, RxDisp_ClearSysExState
	pushw wa
	call SeqBuf2_WriteByte
	inc 2, xsp
	stdi8 1074, 4

RxDisp_ClearSysExState:
	stdi8 1059, 0
	anddi8 1074, 204
	jr RxDisp_SaveContextAndReturn

RxDisp_SysExError:
	stdi8 1074, 16
	stdi8 1059, 0
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
	cp a, 0xFE
	jr nz, SysMsg_NotActiveSense
	setda 7, 1063

SysMsg_Return:
	ret

SysMsg_NotActiveSense:
	bitda 4, 64848
	jr nz, SysMsg_Return
	cp a, 0xFD
	jr nc, SysMsg_Return
	bitda 6, 47074
	jr nz, SysMsg_Return
	cpdi8 32523, 0
	jr z, SysMsg_ClockTransportDispatch
	cp a, 0xFA
	jr nz, SysMsg_CheckStop
	call LABEL_F71E36
	ret

SysMsg_CheckStop:
	cp a, 0xFC
	jr nz, SysMsg_ClockTransportDispatch
	setda 0, 32565

SysMsg_ClockTransportDispatch:
	ld d, a
	bitda 2, 64848
	jrl z, AltClk_DisabledClockPath
	cp d, 0xF8
	jr nz, ClkTick_PerClockCounters
	bitda 5, 10412
	jr z, ClkTick_TempoThresholdCheck
	incdi8 1, 1108

ClkTick_TempoThresholdCheck:
	ldda8 a, 1066
	cp a, 0x70
	jr ugt, ClkTick_HighTempoLoad
	cps a, 4
	jr ugt, ClkTick_MidRangeTempoMul
	ldda16 xwa, 47064
	jr ClkTick_WriteTimingReg

ClkTick_MidRangeTempoMul:
	extz xwa
	xor w, w
	muls_sd16w 0, 0xDA, 0xB7
	jr ClkTick_WriteTimingReg

ClkTick_HighTempoLoad:
	ldda16 xwa, 47062

ClkTick_WriteTimingReg:
	stda16 146, xwa	; LD (TREG5L), WA
	stdi8 1066, 0
	bitda 0, 1055
	jr z, ClkTick_BeatSubdivCheck
	stdi8 1055, 6

ClkTick_BeatSubdivCheck:
	bitda 2, 1055
	jr z, ClkTick_PerClockCounters
	anddi8 1130, 252
	incdi8 4, 1130
	cpdi8 1130, 96
	jr nz, ClkTick_PerClockCounters
	stdi8 1130, 0
	incdi16 1, 1128
	cpdi8 32523, 0
	jr z, ClkTick_PerClockCounters
	calr MIDI_QUEUE_TRACK_EVENT

ClkTick_PerClockCounters:
	ldda8 a, 1056
	pushw wa
	and a, 0x5
	popw wa
	jrl z, Transport_NoClockSourcePath
	cp d, 0xF8
	jrl nz, Transport_StopHandler
	bit 0, a
	jr z, ClkTick_Src2ClickIncrement
	stdi8 1056, 6
	bitda 0, 1054
	jr z, ClkTick_Src1FineUpdate
	stdi8 1054, 6

ClkTick_Src1FineUpdate:
	bitda 0, 1057
	jr z, ClkTick_Src1CoarseUpdate
	stdi8 1057, 6

ClkTick_Src1CoarseUpdate:
	jrl Transport_StopHandler

ClkTick_Src2ClickIncrement:
	bit 2, a
	jr z, ClkTick_Src2FineBeatCheck
	anddi8 1047, 252
	incdi8 4, 1047
	cpdi8 1047, 96
	jr nz, ClkTick_Src2FineBeatCheck
	stdi8 1047, 0
	incdi16 1, 1048

ClkTick_Src2FineBeatCheck:
	bitda 2, 1054
	jr z, ClkTick_Src2ErrorDelta
	anddi8 1045, 252
	incdi8 4, 1045
	cpdi8 1045, 96
	jr nz, ClkTick_Src2ErrorDelta
	stdi8 1045, 0
	incdi8 1, 1046
	ldda8 a, 14235
	and a, 0x1F
	jr z, ClkTick_Src2CoarseOverflow
	calr MIDI_QUEUE_TRACK_EVENT

ClkTick_Src2CoarseOverflow:
	ldda8 a, 1046
	ldda8 w, 1075
	ex_sd16b W, 0x58, 0x04
	cp a, w
	jr c, ClkTick_Src2ErrorDelta
	stdi8 1046, 0
	incdi8 1, 1076
	incdi8 1, 1077
	ldda8 a, 1077
	cpda8 a, 13527
	jr ule, ClkTick_Src2ErrorDelta
	stdi8 1077, 0

ClkTick_Src2ErrorDelta:
	ldda8 a, 1045
	ld w, a
	subda8 a, 1111
	jr z, ClkTick_Src3ClickCheck
	jr ugt, ClkTick_Src2ErrorAccumulate
	add a, 0x60

ClkTick_Src2ErrorAccumulate:
	stda8 1111, w
	adddm8 1124, a
	adddm8 1122, a
	xor w, w
	addda16 xwa, 1120
	cp a, 0x60
	jr c, ClkTick_Src2ErrorWriteback
	sub a, 0x60
	inc 1, w

ClkTick_Src2ErrorWriteback:
	stda16 1120, xwa

ClkTick_Src3ClickCheck:
	bitda 2, 1057
	jr z, Transport_StopHandler
	anddi8 1051, 252
	incdi8 4, 1051
	ldda8 a, 1051
	bitda 0, 1073
	jr z, ClkTick_Src3LowerSyncCheck
	cpda8 a, 1071
	jr nz, ClkTick_Src3LowerSyncCheck
	resda 0, 1073
	stdi8 1054, 1
	cpdi16 10410, 0
	jr z, ClkTick_Src3LowerSyncCheck
	ldb a, 0x85
	calr MIDI_QUEUE_EVENT_PAIR

ClkTick_Src3LowerSyncCheck:
	bitda 3, 1073
	jr z, ClkTick_Src3OverflowQueue
	cpda8 a, 1072
	jr nz, ClkTick_Src3OverflowQueue
	resda 3, 1073
	stdi8 1054, 8
	cpdi16 10410, 0
	jr z, ClkTick_Src3OverflowQueue
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

ClkTick_Src3OverflowQueue:
	cpdi8 1051, 96
	jr nz, Transport_Return
	stdi8 1051, 0
	incdi16 1, 1052
	cpdi16 10410, 0
	jr z, Transport_StopHandler
	calr MIDI_QUEUE_TRACK_EVENT

Transport_StopHandler:
	bitda 2, 64850
	jr z, Transport_Return
	cp d, 0xFC
	jr nz, Transport_Return
	stdi8 1056, 16
	bitda 2, 1054
	jr z, Transport_StopSrc3Snapshot
	bitda 2, 1057
	jr z, Transport_StopSrc1QueueEvent
	setda 2, 13434

Transport_StopSrc1QueueEvent:
	stdi8 1054, 16
	cpdi16 10410, 0
	jr z, Transport_StopSrc3Snapshot
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

Transport_StopSrc3Snapshot:
	bitda 2, 1057
	jr z, Transport_Return
	stdi8 1057, 16
	pushw wa
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a
	popw wa

Transport_Return:
	ret

Transport_NoClockSourcePath:
	bitda 2, 64850
	jr z, Transport_StopSrc3Snapshot
	bitda 2, 10407
	jr nz, Transport_NoClockReturn
	cp d, 0xFA
	jr z, StartPlay_Body
	cp d, 0xFB
	jrl z, Continue_SetRunning

Transport_NoClockReturn:
	ret

MIDI_START_PLAYBACK_REQUEST:
	cpdi16 61854, 0
	jr z, StartPlay_Return
	push_sr
	ei 6
	calr MIDI_RESET_PLAYBACK_STATE
	calr MIDI_APPLY_STARTUP_TIMING
	pop_sr

StartPlay_Return:
	ret

StartPlay_Body:
	setda 5, 10412
	stdi8 1108, 0
	cpdi16 61854, 0
	jr nz, ResetPlay_Return

MIDI_RESET_PLAYBACK_STATE:
	xor wa, wa
	stda8 1047, a
	stda16 1048, xwa
	stdi8 1056, 1
	bitda 1, 10407
	jr z, ResetPlay_Src3Check
	stda8 1045, a
	stda8 1046, a
	stda8 1076, a
	stda8 1077, a
	stdi8 1054, 1
	resda 0, 10406
	cpdi16 10410, 0
	jr z, ResetPlay_Src3Check
	ldb a, 0x85
	calr MIDI_QUEUE_EVENT_PAIR

ResetPlay_Src3Check:
	bitda 0, 10407
	jr z, ResetPlay_Return
	xor wa, wa
	stda8 1051, a
	stda16 1052, xwa
	stdi8 1057, 1

ResetPlay_Return:
	ret

MIDI_APPLY_STARTUP_TIMING:
	cpdi8 1108, 0
	jr z, StartTiming_ClearAndReturn
	bitda 0, 1056
	jr z, StartTiming_ClearAndReturn
	stdi8 1056, 6
	ldda8 a, 1108
	dec 1, a
	sll a, 2
	adddm8 1047, a
	bitda 0, 1055
	jr z, StartTiming_Src1Adjust
	stdi8 1055, 6
	adddm8 1130, a

StartTiming_Src1Adjust:
	bitda 0, 1054
	jr z, StartTiming_Src2Adjust
	stdi8 1054, 6
	adddm8 1045, a

StartTiming_Src2Adjust:
	bitda 0, 1057
	jr z, StartTiming_ClearAndReturn
	stdi8 1057, 6
	adddm8 1051, a

StartTiming_ClearAndReturn:
	stdi8 1108, 0
	ret

Continue_SetRunning:
	stdi8 1056, 6
	bitda 0, 10407
	jr z, Continue_Return
	stdi8 1057, 6
	bitda 1, 10407
	jr z, Continue_Return
	bitda 0, 10406
	jr nz, Continue_ClearPositionAndSetSrc1
	stdi8 1045, 0
	stdi8 1046, 0

Continue_ClearPositionAndSetSrc1:
	stdi8 1076, 0
	stdi8 1077, 0
	anddi8 10406, 254
	stdi8 1054, 6

Continue_Return:
	ret

AltClk_DisabledClockPath:
	stdi8 1066, 0
	pushw wa
	ldda8 a, 1056
	and a, 0x5
	popw wa
	jr z, AltClk_NoSrcFlagPath
	bitda 2, 64850
	jr z, AltClk_Return
	cp d, 0xFC
	jr nz, AltClk_Return
	stdi8 1056, 12
	bitda 2, 1054
	jr z, AltClk_StopSrc3Snapshot
	bitda 2, 1057
	jr z, AltClk_StopSrc1Queue
	setda 2, 13434

AltClk_StopSrc1Queue:
	stdi8 1054, 12
	cpdi16 10410, 0
	jr z, AltClk_StopSrc3Snapshot
	ldb a, 0x86
	calr MIDI_QUEUE_EVENT_PAIR

AltClk_StopSrc3Snapshot:
	bitda 2, 1057
	jr z, AltClk_Return
	stdi8 1057, 12
	pushw wa
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a
	popw wa

AltClk_Return:
	ret

AltClk_NoSrcFlagPath:
	bitda 2, 64850
	jr z, AltClk_NoMatchReturn
	bitda 2, 10407
	jr nz, AltClk_NoMatchReturn
	cp d, 0xFA
	jr z, AltClk_StartArmTx
	cp d, 0xFB
	jr z, AltClk_ContinueArmTx

AltClk_NoMatchReturn:
	ret

AltClk_StartArmTx:
	setda 1, 1065
	stdi8 234, 221
	jrl StartPlay_Body

AltClk_ContinueArmTx:
	bitda 0, 10407
	jr z, AltClk_Src3DisabledReturn
	setda 2, 1065
	stdi8 234, 221
	jrl Continue_SetRunning

AltClk_Src3DisabledReturn:
	ret

MIDI_QUEUE_TRACK_EVENT:
	bitda 0, 1113
	jr nz, QueueTrack_LinearBufWrite
	pushw wa
	ld xix, 0x1E753
	ld wa, (xix - 2)
	and wa, wa
	jr z, QueueTrack_FifoWriteOrClear
	ld hl, (xix - 4)
	stib_dri 0x07, 0xF0, 0xEC, 0x81
	minc1_16 hl, 0x7FF
	dec 1, wa
	ld (xix - 4), hl
	ld (xix - 2), wa

QueueTrack_FifoWriteOrClear:
	popw wa
	stdi16 1141, 0
	ret

QueueTrack_LinearBufWrite:
	ld xix, 0x477
	ldda16 xhl, 1141
	stib_dri 0x07, 0xF0, 0xEC, 0x81
	inc 1, hl
	stda16 1141, xhl
	ret

MIDI_QUEUE_EVENT_PAIR:
	bitda 0, 1113
	jr nz, QueuePair_LinearBufWrite
	cpdi16_24 124753, 2
	jr c, QueuePair_FifoFullReturn
	push_sr
	ei 6
	ld xix, 0x1E753
	ld hl, (xix - 4)
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	minc1_16 hl, 0x7FF
	ldda8 a, 1051
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	minc1_16 hl, 0x7FF
	ld (xix - 4), hl
	decm 2, (xix - 2)
	pop_sr

QueuePair_FifoFullReturn:
	stdi16 1141, 0
	ret

QueuePair_LinearBufWrite:
	ld xix, 0x477
	ldda16 xhl, 1141
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	inc 1, hl
	ldda8 a, 1051
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	inc 1, hl
	stda16 1141, xhl
	ret

MIDI_CHANNEL_MESSAGE_DISPATCHER:
	ld e, a
	ldda8 a, 1059
	ld d, a
	bitda 0, 1074
	jrl nz, SysEx_InProgressByte
	bitda 6, 1063
	jr nz, ChanDisp_SysExInProgress
	cps a, 0
	jr z, ChanDisp_NoStatusReturn
	and a, 0x70
	srl a, 2
	xor w, w
	ld xix, 0xFCF761
	ld_sril3 XIX, 0x07, 0xF0, 0xE0
	jp (xix)
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
	.byte 0xff, 0xa8, 0xf7, 0xfc, 0x00, 0xa8, 0xf7, 0xfc
	.byte 0x00, 0x81, 0xf7, 0xfc, 0x00, 0xa8, 0xf7, 0xfc
	.byte 0x00, 0x82, 0xf7, 0xfc, 0x00, 0x82, 0xf7, 0xfc
	.byte 0x00, 0xa8, 0xf7, 0xfc, 0x00, 0x00, 0xf8, 0xfc
	.byte 0x00

ChanDisp_NoStatusReturn:
	ret

MIDI_QUEUE_EVENT_TO_SEQUENCER:
	ld xix, 0x1F37B
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
	setda 2, 1063
	incdi8 1, 47069
	ret

ChanDisp_QueueOverflow:
	setda 6, 1063
	ld c, e
	ret

ChanDisp_SysExInProgress:
	bitda 1, 1063
	jr z, ChanDisp_ThreeByteRoute
	ldb d, 0xF2

ChanDisp_ThreeByteRoute:
	ld xix, 0x1F37B
	cpw (xix - 2), 0x40
	jr ugt, ChanDisp_EnqueueThreeBytes
	pushw de
	and d, 0xF0
	cp d, 0x90
	popw de
	jr nz, ChanDisp_EnqueueThreeBytes
	cps e, 0
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
	anddi8 1063, 189

ChanDisp_NoteOnZeroReturn:
	ret

ChanDisp_QueueOverflowSet:
	setda 2, 1063
	incdi8 1, 47069
	ret

MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	stdi8 1059, 0
	cp d, 0xF0
	jr z, SysEx_StartByte
	cp d, 0xF2
	jr z, SysEx_SongPositionSetup
	cp d, 0xF3
	jr z, SysEx_SongSelectQueue
	ret

SysEx_SongPositionSetup:
	ordi8 1063, 66
	ld c, e
	ret

SysEx_SongSelectQueue:
	jrl MIDI_QUEUE_EVENT_TO_SEQUENCER

SysEx_StartByte:
	stdi8 1074, 1
	cp e, 0x50
	jr z, SysEx_CaptureManufacturerId
	cp e, 0x41
	jr z, SysEx_CaptureManufacturerId
	cp e, 0x7E
	jr nz, SysEx_Return

SysEx_CaptureManufacturerId:
	setda 1, 1074
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
	bitda 1, 1074
	jr z, SysEx_InProgressReturn
	bitda 5, 1074
	jr nz, SysEx_InProgressReturn
	pushw de
	call SeqBuf2_WriteByte
	inc 2, xsp

SysEx_InProgressReturn:
	ret

MIDI_RX_CONTEXT_RESTORE:
	ldda32 xwa, 1080
	ldda32 xbc, 1084
	ldda32 xde, 1088
	ldda32 xhl, 1092
	ldda32 xix, 1096
	ldda32 xiy, 1100
	ldda32 xiz, 1104
	ret

MIDI_RX_CONTEXT_SAVE:
	stda32 1080, xwa
	stda32 1084, xbc
	stda32 1088, xde
	stda32 1092, xhl
	stda32 1096, xix
	stda32 1100, xiy
	stda32 1104, xiz
	ret

SC0Init_Entry:
	resda 0, 47079
	stdi8 47073, 0
	calr SC0Init_ClearContextSlots
	calr SC0Init_StandardBaudTable
	calr READ_COM_SELECT_SWITCH
	call LABEL_FDBA02
	calr SC0Init_EnableRegisters
	ret

SC0Init_StandardBaudTable:
	call Get_Region_Code
	cps l, 4
	jr z, SC0Init_AlternateBaudTable
	stdi16 47060, 31250
	stdi16 47062, 10416
	stdi16 47064, 4166
	stdi16 47066, 1000
	stdi8 47068, 8	; BR0CR: clk=fc/4/8 = 500kHz (baudrate for MIDI ?!)
	jr SC0Init_BaudTableReturn

SC0Init_AlternateBaudTable:
	stdi16 47060, 23437
	stdi16 47062, 7812
	stdi16 47064, 3125
	stdi16 47066, 750
	stdi8 47068, 6	; BR0CR: clk=fc/4/6 = 666.6kHz (baudrate for MIDI ?!)

SC0Init_BaudTableReturn:
	ret

READ_COM_SELECT_SWITCH:
	ldda8 a, 104
	srl a, 4
	ld xix, 0xFCF90C
	ld_srib3 A, 0x03, 0xF0, 0xE0
	stda8 47072, a
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
OFFSETS_FCF90C:
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x00	; MIDI
	.byte 0x00
	.byte 0x00
	.byte 0x00
	.byte 0x01	; MAC
	.byte 0x00
	.byte 0x02	; PC1
	.byte 0x03	; PC2
	.byte 0x00

SC0Init_ClearContextSlots:
	stdi8 1080, 0
	stdi8 1084, 0
	stdi8 1088, 0
	stdi8 1092, 0
	stdi8 1096, 0
	stdi8 1100, 0
	stdi8 1104, 0
	ret

SC0Init_EnableRegisters:
	ei 6
	stdi8 210, 41
	stdi8 209, 0
	ldda8 a, 47068
	stda8 211, a
	stdi8 234, 93
	stdi8 208, 254
	ei 0
	ret

SC0Init_PaddingStub:
	ret

MIDI_SC0_DISPATCH_TABLE:
	.byte 0x97, 0xf8, 0xfc, 0x00, 0x61, 0xf9, 0xfc, 0x00
	.byte 0x61, 0xf9, 0xfc, 0x00, 0x61, 0xf9, 0xfc, 0x00

MIDI_SC0_TX_DISPATCH:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	cpdi8 47072, 0	; 000h means MIDI
	jr nz, SC0TxDisp_NonMidiPath
	calr MIDI_SC0_ENABLE_TX
	jr SC0TxDisp_RestoreAndReturn

SC0TxDisp_NonMidiPath:
	call LABEL_FDB903

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
	push_sr
	ei 6
	cpdi8 1140, 85
	jr z, SC0TxEnable_MidiActivePath
	stdi8 234, 221
	jr SC0TxEnable_Return

SC0TxEnable_MidiActivePath:
	call SeqBuf_MidiOut_Init
	stdi8 1065, 0

SC0TxEnable_Return:
	pop_sr
	ret

; End of MIDI Serial routines

