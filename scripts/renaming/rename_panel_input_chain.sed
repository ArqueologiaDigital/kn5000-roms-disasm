# The panel-input chain (technics-docs control-panel-protocol.md, "From a button change to an action"; cpu-subsystem.md,
# port G): every periodic tick drains the control-panel RX queue into 3-byte change records, scans the pedal ports
# (PG.2-3 foot switches FS1/FS2 = event 28, PG.4-7 foot controllers FC1-FC4 = event 29, PD.6 = event 30) and the two
# wheel encoders (ENCODER_0 = modulation wheel = event 26, ENCODER_1 = volume = event 27), queueing a record for each
# change; PanelButton_ProcessChanges later dispatches the queue through the action lists.  The routines were named
# Audio_/MIDI_/MidiCC_/Voice_/Encoder_/Seq_ by guess.
s/\bAudio_PeriodicUpdate\b/PanelInput_Poll/g
s/\bAudio_ProcessVoiceQueue\b/PanelInput_DrainRxQueue/g
s/\bVoiceQueue_ParseNextEntry\b/PanelInput_DrainRxQueue_Loop/g
s/\bVoiceQueue_Done\b/PanelInput_DrainRxQueue_Return/g
s/\bMIDI_ParseThreeByteParams\b/PanelInput_ReadRxRecord/g
s/\bMidiParseThreeByte_Done\b/PanelInput_ReadRxRecord_Return/g
s/\bMIDI_ProcessVoiceAssignment\b/PanelInput_ScanPedalPorts/g
s/\bMIDI_ValidateParam\b/PanelInput_ScanPedalPorts_Debounce/g
s/\bMIDI_WriteSecondByte\b/PanelInput_ScanPedalPorts_PD6/g
s/\bMIDI_WriteParamByte\b/PanelInput_UpdatePedalRecord/g
s/\bMIDI_ChannelSetup_Skip\b/PanelInput_UpdatePedalRecord_Store/g
s/\bMIDI_ChannelSetup_Store\b/PanelInput_UpdatePedalRecord_Compare/g
s/\bMIDI_ChannelSetup_Init\b/PanelInput_UpdatePedalRecord_Queue/g
s/\bVoiceData_Setup_Ret\b/PanelInput_UpdatePedalRecord_Return/g
s/\bMIDI_ProcessControlChange\b/PanelInput_QueueWheelChanges/g
s/\bMidiCC_ProcessParam\b/PanelInput_QueueWheelChanges_Volume/g
s/\bMidiCC_SkipEntry\b/PanelInput_QueueWheelChanges_Return/g
s/\bMidiCC_LookupHandler_Data\b/PanelInput_EventIndexByHeader/g
s/\bMidiCC_LookupHandler\b/PanelInput_EventIndexOfHeader/g
s/\bVoice_SetupFromData\b/PanelInput_QueueChange/g
s/\bMidiCC_SyncForceResync\b/PanelInput_ChangeQueue/g
s/\bMidiCC_ResetState\b/PanelInput_ClearChangeQueue/g
s/\bAudio_CopyStateFromROM_Data\b/PanelInput_PedalRecordDefaults/g
s/\bAudio_CopyStateFromROM\b/PanelInput_InitPedalRecords/g
s/\bAudioCopy_TransferLoop\b/PanelInput_InitPedalRecords_Loop/g
s/\bEncoder_ValueScanAndSync\b/PanelButton_ProcessChanges/g
s/\bEncoder_ScanAndSync\b/PanelButton_ProcessChanges_Next/g
s/\bEncoder_SyncLoop\b/PanelButton_ProcessChanges_Loop/g
s/\bEncoder_ReadNextEntry\b/PanelButton_FetchChange/g
s/\bSeq_DataHandler\b/CPanel_RxEventQueue_Pop/g
s/\bSeqBuf_TimerEvent_BytecodeBlock\b/CPanel_RxEventQueue_Push/g
s/\bPanelAction_Event28Bit0\b/PanelAction_FootSwitch1/g
s/\bPanelAction_Event28Bit1\b/PanelAction_FootSwitch2/g
s/\bPanelAction_Event29Bit0\b/PanelAction_FootController1/g
s/\bPanelAction_Event29Bit1\b/PanelAction_FootController2/g
s/\bPanelAction_Event29Bit2\b/PanelAction_FootController3/g
s/\bPanelAction_Event29Bit3\b/PanelAction_FootController4/g
s/\bPanelAction_Event26\b/PanelAction_ModWheel/g
s/\bPanelAction_Event27\b/PanelAction_Volume/g
s/\bMidiCC_ValidateRange\b/PanelInput_QueueChange_Index19/g
s/\bMidiCC_StoreAndDispatch\b/PanelInput_QueueChange_Segment/g
s/\bMidiCC_CheckOverflow\b/PanelInput_QueueChange_Leds/g
s/\bMidiCC_Finalize\b/PanelInput_QueueChange_Append/g
s/\bMidiCC_ReturnClean\b/PanelInput_QueueChange_AppendAndNotify/g
s/\bMidiCC_Return\b/PanelInput_QueueChange_Return/g
s/\bMIDI_PopIzRet\b/PanelInput_QueueChange_Done/g
