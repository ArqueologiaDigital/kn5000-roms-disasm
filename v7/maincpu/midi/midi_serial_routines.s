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
	.incbin "includes/generated/v7_transplant_MIDI_INIT_SEQUENCES.bin"
MidiInit_FillLoop:
	.incbin "includes/generated/v7_transplant_MidiInit_FillLoop.bin"
MidiInit_Stub1:
	.incbin "includes/generated/v7_transplant_MidiInit_Stub1.bin"
MidiInit_Stub2:
	.incbin "includes/generated/v7_transplant_MidiInit_Stub2.bin"
MidiInit_Stub3:
	.incbin "includes/generated/v7_transplant_MidiInit_Stub3.bin"
INTRX0_CLEAR_ERROR_STATE:
	.incbin "includes/generated/v7_transplant_INTRX0_CLEAR_ERROR_STATE.bin"
INTTX0_HANDLER:
	.incbin "includes/generated/v7_transplant_INTTX0_HANDLER.bin"
IntTx0_FlagBit0Branch:
	.incbin "includes/generated/v7_transplant_IntTx0_FlagBit0Branch.bin"
IntTx0_FlagBit4Branch:
	.incbin "includes/generated/v7_transplant_IntTx0_FlagBit4Branch.bin"
IntTx0_SendHoldByte:
	.incbin "includes/generated/v7_transplant_IntTx0_SendHoldByte.bin"
IntTx0_FlagBit1Branch:
	.incbin "includes/generated/v7_transplant_IntTx0_FlagBit1Branch.bin"
IntTx0_FlagBit2Branch:
	.incbin "includes/generated/v7_transplant_IntTx0_FlagBit2Branch.bin"
IntTx0_DequeueAndSend:
	.incbin "includes/generated/v7_transplant_IntTx0_DequeueAndSend.bin"
IntTx0_CheckQueueEmpty:
	.incbin "includes/generated/v7_transplant_IntTx0_CheckQueueEmpty.bin"
IntTx0_Epilogue:
	.incbin "includes/generated/v7_transplant_IntTx0_Epilogue.bin"
INTRX0_HANDLER:
	.incbin "includes/generated/v7_transplant_INTRX0_HANDLER.bin"
MIDI_RX_BYTE_DISPATCHER:
	.incbin "includes/generated/v7_transplant_MIDI_RX_BYTE_DISPATCHER.bin"
RxDisp_StatusByte:
	.incbin "includes/generated/v7_transplant_RxDisp_StatusByte.bin"
RxDisp_ClearSysExState:
	.incbin "includes/generated/v7_transplant_RxDisp_ClearSysExState.bin"
RxDisp_SysExError:
	.incbin "includes/generated/v7_transplant_RxDisp_SysExError.bin"
RxDisp_DataByteDispatch:
	.incbin "includes/generated/v7_transplant_RxDisp_DataByteDispatch.bin"
RxDisp_SaveContextAndReturn:
	.incbin "includes/generated/v7_transplant_RxDisp_SaveContextAndReturn.bin"
MIDI_SYSTEM_MESSAGE_HANDLER:
	.incbin "includes/generated/v7_transplant_MIDI_SYSTEM_MESSAGE_HANDLER.bin"
SysMsg_Return:
	.incbin "includes/generated/v7_transplant_SysMsg_Return.bin"
SysMsg_NotActiveSense:
	.incbin "includes/generated/v7_transplant_SysMsg_NotActiveSense.bin"
SysMsg_CheckStop:
	.incbin "includes/generated/v7_transplant_SysMsg_CheckStop.bin"
SysMsg_ClockTransportDispatch:
	.incbin "includes/generated/v7_transplant_SysMsg_ClockTransportDispatch.bin"
ClkTick_TempoThresholdCheck:
	.incbin "includes/generated/v7_transplant_ClkTick_TempoThresholdCheck.bin"
ClkTick_MidRangeTempoMul:
	.incbin "includes/generated/v7_transplant_ClkTick_MidRangeTempoMul.bin"
ClkTick_HighTempoLoad:
	.incbin "includes/generated/v7_transplant_ClkTick_HighTempoLoad.bin"
ClkTick_WriteTimingReg:
	.incbin "includes/generated/v7_transplant_ClkTick_WriteTimingReg.bin"
ClkTick_BeatSubdivCheck:
	.incbin "includes/generated/v7_transplant_ClkTick_BeatSubdivCheck.bin"
ClkTick_PerClockCounters:
	.incbin "includes/generated/v7_transplant_ClkTick_PerClockCounters.bin"
ClkTick_Src1FineUpdate:
	.incbin "includes/generated/v7_transplant_ClkTick_Src1FineUpdate.bin"
ClkTick_Src1CoarseUpdate:
	.incbin "includes/generated/v7_transplant_ClkTick_Src1CoarseUpdate.bin"
ClkTick_Src2ClickIncrement:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2ClickIncrement.bin"
ClkTick_Src2FineBeatCheck:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2FineBeatCheck.bin"
ClkTick_Src2CoarseOverflow:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2CoarseOverflow.bin"
ClkTick_Src2ErrorDelta:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2ErrorDelta.bin"
ClkTick_Src2ErrorAccumulate:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2ErrorAccumulate.bin"
ClkTick_Src2ErrorWriteback:
	.incbin "includes/generated/v7_transplant_ClkTick_Src2ErrorWriteback.bin"
ClkTick_Src3ClickCheck:
	.incbin "includes/generated/v7_transplant_ClkTick_Src3ClickCheck.bin"
ClkTick_Src3LowerSyncCheck:
	.incbin "includes/generated/v7_transplant_ClkTick_Src3LowerSyncCheck.bin"
ClkTick_Src3OverflowQueue:
	.incbin "includes/generated/v7_transplant_ClkTick_Src3OverflowQueue.bin"
Transport_StopHandler:
	.incbin "includes/generated/v7_transplant_Transport_StopHandler.bin"
Transport_StopSrc1QueueEvent:
	.incbin "includes/generated/v7_transplant_Transport_StopSrc1QueueEvent.bin"
Transport_StopSrc3Snapshot:
	.incbin "includes/generated/v7_transplant_Transport_StopSrc3Snapshot.bin"
Transport_Return:
	.incbin "includes/generated/v7_transplant_Transport_Return.bin"
Transport_NoClockSourcePath:
	.incbin "includes/generated/v7_transplant_Transport_NoClockSourcePath.bin"
Transport_NoClockReturn:
	.incbin "includes/generated/v7_transplant_Transport_NoClockReturn.bin"
MIDI_START_PLAYBACK_REQUEST:
	.incbin "includes/generated/v7_transplant_MIDI_START_PLAYBACK_REQUEST.bin"
StartPlay_Return:
	.incbin "includes/generated/v7_transplant_StartPlay_Return.bin"
StartPlay_Body:
	.incbin "includes/generated/v7_transplant_StartPlay_Body.bin"
MIDI_RESET_PLAYBACK_STATE:
	.incbin "includes/generated/v7_transplant_MIDI_RESET_PLAYBACK_STATE.bin"
ResetPlay_Src3Check:
	.incbin "includes/generated/v7_transplant_ResetPlay_Src3Check.bin"
ResetPlay_Return:
	.incbin "includes/generated/v7_transplant_ResetPlay_Return.bin"
MIDI_APPLY_STARTUP_TIMING:
	.incbin "includes/generated/v7_transplant_MIDI_APPLY_STARTUP_TIMING.bin"
StartTiming_Src1Adjust:
	.incbin "includes/generated/v7_transplant_StartTiming_Src1Adjust.bin"
StartTiming_Src2Adjust:
	.incbin "includes/generated/v7_transplant_StartTiming_Src2Adjust.bin"
StartTiming_ClearAndReturn:
	.incbin "includes/generated/v7_transplant_StartTiming_ClearAndReturn.bin"
Continue_SetRunning:
	.incbin "includes/generated/v7_transplant_Continue_SetRunning.bin"
Continue_ClearPositionAndSetSrc1:
	.incbin "includes/generated/v7_transplant_Continue_ClearPositionAndSetSrc1.bin"
Continue_Return:
	.incbin "includes/generated/v7_transplant_Continue_Return.bin"
AltClk_DisabledClockPath:
	.incbin "includes/generated/v7_transplant_AltClk_DisabledClockPath.bin"
AltClk_StopSrc1Queue:
	.incbin "includes/generated/v7_transplant_AltClk_StopSrc1Queue.bin"
AltClk_StopSrc3Snapshot:
	.incbin "includes/generated/v7_transplant_AltClk_StopSrc3Snapshot.bin"
AltClk_Return:
	.incbin "includes/generated/v7_transplant_AltClk_Return.bin"
AltClk_NoSrcFlagPath:
	.incbin "includes/generated/v7_transplant_AltClk_NoSrcFlagPath.bin"
AltClk_NoMatchReturn:
	.incbin "includes/generated/v7_transplant_AltClk_NoMatchReturn.bin"
AltClk_StartArmTx:
	.incbin "includes/generated/v7_transplant_AltClk_StartArmTx.bin"
AltClk_ContinueArmTx:
	.incbin "includes/generated/v7_transplant_AltClk_ContinueArmTx.bin"
AltClk_Src3DisabledReturn:
	.incbin "includes/generated/v7_transplant_AltClk_Src3DisabledReturn.bin"
MIDI_QUEUE_TRACK_EVENT:
	.incbin "includes/generated/v7_transplant_MIDI_QUEUE_TRACK_EVENT.bin"
QueueTrack_FifoWriteOrClear:
	.incbin "includes/generated/v7_transplant_QueueTrack_FifoWriteOrClear.bin"
QueueTrack_LinearBufWrite:
	.incbin "includes/generated/v7_transplant_QueueTrack_LinearBufWrite.bin"
MIDI_QUEUE_EVENT_PAIR:
	.incbin "includes/generated/v7_transplant_MIDI_QUEUE_EVENT_PAIR.bin"
QueuePair_FifoFullReturn:
	.incbin "includes/generated/v7_transplant_QueuePair_FifoFullReturn.bin"
QueuePair_LinearBufWrite:
	.incbin "includes/generated/v7_transplant_QueuePair_LinearBufWrite.bin"
MIDI_CHANNEL_MESSAGE_DISPATCHER:
	.incbin "includes/generated/v7_transplant_MIDI_CHANNEL_MESSAGE_DISPATCHER.bin"
MIDI_CHANNEL_HANDLER_JUMP_TABLE:
	.incbin "includes/generated/v7_transplant_MIDI_CHANNEL_HANDLER_JUMP_TABLE.bin"
ChanDisp_NoStatusReturn:
	.incbin "includes/generated/v7_transplant_ChanDisp_NoStatusReturn.bin"
MIDI_QUEUE_EVENT_TO_SEQUENCER:
	.incbin "includes/generated/v7_transplant_MIDI_QUEUE_EVENT_TO_SEQUENCER.bin"
QueueToSeq_OverflowFlag:
	.incbin "includes/generated/v7_transplant_QueueToSeq_OverflowFlag.bin"
ChanDisp_QueueOverflow:
	.incbin "includes/generated/v7_transplant_ChanDisp_QueueOverflow.bin"
ChanDisp_SysExInProgress:
	.incbin "includes/generated/v7_transplant_ChanDisp_SysExInProgress.bin"
ChanDisp_ThreeByteRoute:
	.incbin "includes/generated/v7_transplant_ChanDisp_ThreeByteRoute.bin"
ChanDisp_EnqueueThreeBytes:
	.incbin "includes/generated/v7_transplant_ChanDisp_EnqueueThreeBytes.bin"
ChanDisp_NoteOnZeroReturn:
	.byte 0xf4

ChanDisp_QueueOverflowSet:
	.incbin "includes/generated/v7_transplant_ChanDisp_QueueOverflowSet.bin"
MIDI_SYSTEM_EXCLUSIVE_HANDLER:
	.incbin "includes/generated/v7_transplant_MIDI_SYSTEM_EXCLUSIVE_HANDLER.bin"
SysEx_SongPositionSetup:
	.incbin "includes/generated/v7_transplant_SysEx_SongPositionSetup.bin"
SysEx_SongSelectQueue:
	.incbin "includes/generated/v7_transplant_SysEx_SongSelectQueue.bin"
SysEx_StartByte:
	.incbin "includes/generated/v7_transplant_SysEx_StartByte.bin"
SysEx_CaptureManufacturerId:
	.incbin "includes/generated/v7_transplant_SysEx_CaptureManufacturerId.bin"
SysEx_Return:
	.incbin "includes/generated/v7_transplant_SysEx_Return.bin"
SysEx_InProgressByte:
	.incbin "includes/generated/v7_transplant_SysEx_InProgressByte.bin"
SysEx_InProgressReturn:
	.incbin "includes/generated/v7_transplant_SysEx_InProgressReturn.bin"
MIDI_RX_CONTEXT_RESTORE:
	.incbin "includes/generated/v7_transplant_MIDI_RX_CONTEXT_RESTORE.bin"
MIDI_RX_CONTEXT_SAVE:
	.incbin "includes/generated/v7_transplant_MIDI_RX_CONTEXT_SAVE.bin"
SC0Init_Entry:
	.incbin "includes/generated/v7_transplant_SC0Init_Entry.bin"
SC0Init_StandardBaudTable:
	.incbin "includes/generated/v7_transplant_SC0Init_StandardBaudTable.bin"
SC0Init_AlternateBaudTable:
	.incbin "includes/generated/v7_transplant_SC0Init_AlternateBaudTable.bin"
SC0Init_BaudTableReturn:
	.incbin "includes/generated/v7_transplant_SC0Init_BaudTableReturn.bin"
READ_COM_SELECT_SWITCH:
	.incbin "includes/generated/v7_transplant_READ_COM_SELECT_SWITCH.bin"
MidiSerial_OffsetTable:
	.incbin "includes/generated/v7_transplant_MidiSerial_OffsetTable.bin"
SC0Init_ClearContextSlots:
	.incbin "includes/generated/v7_transplant_SC0Init_ClearContextSlots.bin"
SC0Init_EnableRegisters:
	.incbin "includes/generated/v7_transplant_SC0Init_EnableRegisters.bin"
SC0Init_PaddingStub:
	.incbin "includes/generated/v7_transplant_SC0Init_PaddingStub.bin"
MIDI_SC0_DISPATCH_TABLE:
	.incbin "includes/generated/v7_transplant_MIDI_SC0_DISPATCH_TABLE.bin"
MIDI_SC0_TX_DISPATCH:
	.incbin "includes/generated/v7_transplant_MIDI_SC0_TX_DISPATCH.bin"
SC0TxDisp_NonMidiPath:
	.incbin "includes/generated/v7_transplant_SC0TxDisp_NonMidiPath.bin"
SC0TxDisp_RestoreAndReturn:
	.incbin "includes/generated/v7_transplant_SC0TxDisp_RestoreAndReturn.bin"
MIDI_SC0_ENABLE_TX:
	.incbin "includes/generated/v7_transplant_MIDI_SC0_ENABLE_TX.bin"
SC0TxEnable_MidiActivePath:
	.incbin "includes/generated/v7_transplant_SC0TxEnable_MidiActivePath.bin"
SC0TxEnable_Return:
	.byte 0x6e, 0x13

; End of MIDI Serial routines

