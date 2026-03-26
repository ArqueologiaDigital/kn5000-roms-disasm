; =============================================================================
; DSP Configuration & SysEx Processing
; =============================================================================
;
; DSP effect parameter handlers (reverb, chorus, EQ, compressor)
; and System Exclusive (SysEx) command processing. Manages effect
; presets and real-time parameter editing.
; =============================================================================

SysEx_ClampVoiceIndex8:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex8.bin"
SysEx_ClampVoiceIndex8_DoLookup:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex8_DoLookup.bin"
SysEx_ApplyToSlot4B_Data:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyToSlot4B_Data.bin"
SysEx_ClampVoiceIndex128:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex128.bin"
SysEx_ClampVoiceIndex128_DoLookup:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex128_DoLookup.bin"
SysEx_ApplyToSlot49_Data:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyToSlot49_Data.bin"
SysEx_ClampVoiceIndex8_49:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex8_49.bin"
SysEx_ClampVoiceIndex8_49_DoLookup:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex8_49_DoLookup.bin"
SysEx_ApplyToSlot49_Format_Data:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyToSlot49_Format_Data.bin"
SysEx_ClampVoiceIndex128_49:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex128_49.bin"
SysEx_ClampVoiceIndex128_49_DoLookup:
	.incbin "includes/generated/v7_transplant_SysEx_ClampVoiceIndex128_49_DoLookup.bin"
SysEx_DispatchByChannel:
	.incbin "includes/generated/v7_transplant_SysEx_DispatchByChannel.bin"
SysEx_ChannelHandler_4B_Data:
	.incbin "includes/generated/v7_transplant_SysEx_ChannelHandler_4B_Data.bin"
SysEx_DispatchByChannel_49:
	.incbin "includes/generated/v7_transplant_SysEx_DispatchByChannel_49.bin"
SysEx_ChannelHandler_49_Data:
	.incbin "includes/generated/v7_transplant_SysEx_ChannelHandler_49_Data.bin"
SysEx_ValidateRolandHeader:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader.bin"
SysEx_ValidateRolandHeader_NonZeroChan:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader_NonZeroChan.bin"
SysEx_ValidateRolandHeader_Dispatch:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader_Dispatch.bin"
SysEx_ValidateRolandHeader_Cmd33:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader_Cmd33.bin"
SysEx_ValidateRolandHeader_Cmd38:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader_Cmd38.bin"
SysEx_ValidateRolandHeader_Cmd3A:
	.incbin "includes/generated/v7_transplant_SysEx_ValidateRolandHeader_Cmd3A.bin"
SysEx_ApplyVoiceParam_4B:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B.bin"
SysEx_ApplyVoiceParam_4B_ReadSubParams:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_ReadSubParams.bin"
SysEx_ApplyVoiceParam_4B_SkipRestore:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_SkipRestore.bin"
SysEx_ApplyVoiceParam_4B_IterateSlots:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_IterateSlots.bin"
SysEx_ApplyVoiceParam_4B_SlotLoop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_SlotLoop.bin"
SysEx_ApplyVoiceParam_4B_SlotNext:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_SlotNext.bin"
SysEx_ApplyVoiceParam_4B_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_RestoreSlotId.bin"
SysEx_ApplyVoiceParam_4B_Return:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_Return.bin"
SysEx_ApplyVoiceParam_4B_128:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128.bin"
SysEx_ApplyVoiceParam_4B_128_ReadSub:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_ReadSub.bin"
SysEx_ApplyVoiceParam_4B_128_SkipRestore:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_SkipRestore.bin"
SysEx_ApplyVoiceParam_4B_128_IterateSlots:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_IterateSlots.bin"
SysEx_ApplyVoiceParam_4B_128_SlotLoop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_SlotLoop.bin"
SysEx_ApplyVoiceParam_4B_128_WriteSlot:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_WriteSlot.bin"
SysEx_ApplyVoiceParam_4B_128_SlotNext:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_SlotNext.bin"
SysEx_ApplyVoiceParam_4B_128_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_RestoreSlotId.bin"
SysEx_ApplyVoiceParam_4B_128_Return:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_4B_128_Return.bin"
SysEx_ApplyVoiceParam_49:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49.bin"
SysEx_ApplyVoiceParam_49_ReadSubParams:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_ReadSubParams.bin"
SysEx_ApplyVoiceParam_49_SkipRestore:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_SkipRestore.bin"
SysEx_ApplyVoiceParam_49_IterateSlots:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_IterateSlots.bin"
SysEx_ApplyVoiceParam_49_SlotLoop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_SlotLoop.bin"
SysEx_ApplyVoiceParam_49_SlotNext:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_SlotNext.bin"
SysEx_ApplyVoiceParam_49_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_RestoreSlotId.bin"
SysEx_ApplyVoiceParam_49_Return:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_Return.bin"
SysEx_ApplyVoiceParam_49_128:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128.bin"
SysEx_ApplyVoiceParam_49_128_ReadSub:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_ReadSub.bin"
SysEx_ApplyVoiceParam_49_128_SkipRestore:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_SkipRestore.bin"
SysEx_ApplyVoiceParam_49_128_IterateSlots:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_IterateSlots.bin"
SysEx_ApplyVoiceParam_49_128_SlotLoop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_SlotLoop.bin"
SysEx_ApplyVoiceParam_49_128_WriteSlot:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_WriteSlot.bin"
SysEx_ApplyVoiceParam_49_128_SlotNext:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_SlotNext.bin"
SysEx_ApplyVoiceParam_49_128_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_RestoreSlotId.bin"
SysEx_ApplyVoiceParam_49_128_Return:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyVoiceParam_49_128_Return.bin"
SysEx_ApplyAndReloadPreset:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyAndReloadPreset.bin"
SysEx_ApplyAndReloadPreset_Type61:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyAndReloadPreset_Type61.bin"
SysEx_ApplyAndReloadPreset_Type61_Loop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyAndReloadPreset_Type61_Loop.bin"
SysEx_ApplyAndReloadPreset_Type63:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyAndReloadPreset_Type63.bin"
SysEx_ApplyAndReloadPreset_Type63_Loop:
	.incbin "includes/generated/v7_transplant_SysEx_ApplyAndReloadPreset_Type63_Loop.bin"
AssswbWr_ReturnFail:
	.incbin "includes/generated/v7_transplant_AssswbWr_ReturnFail.bin"
AssswbWr_Return:
	.incbin "includes/generated/v7_transplant_AssswbWr_Return.bin"
AssswbWr:
	.incbin "includes/generated/v7_transplant_AssswbWr.bin"
AssswbWr_BufferFull:
	.incbin "includes/generated/v7_transplant_AssswbWr_BufferFull.bin"
AddswbWr:
	.incbin "includes/generated/v7_transplant_AddswbWr.bin"
AddswbWr_BufferFull:
	.incbin "includes/generated/v7_transplant_AddswbWr_BufferFull.bin"
SwbtWr:
	.incbin "includes/generated/v7_transplant_SwbtWr.bin"
SwbtWr_ScanEnd:
	.incbin "includes/generated/v7_transplant_SwbtWr_ScanEnd.bin"
SwbtWr_CheckSpace:
	.incbin "includes/generated/v7_transplant_SwbtWr_CheckSpace.bin"
SwbtWr_Done:
	.incbin "includes/generated/v7_transplant_SwbtWr_Done.bin"
SwbtWr_CallProcessAll:
	.incbin "includes/generated/v7_transplant_SwbtWr_CallProcessAll.bin"
SwbtWr_SoundBankParamTable:
	.incbin "includes/generated/v7_transplant_SwbtWr_SoundBankParamTable.bin"
SwbtWr_ProcessAll:
	.incbin "includes/generated/v7_transplant_SwbtWr_ProcessAll.bin"
SwbtWr_ProcessAll_CompactDone:
	.incbin "includes/generated/v7_transplant_SwbtWr_ProcessAll_CompactDone.bin"
SwbtWr_InitBank1:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitBank1.bin"
SwbtWr_InitBank2:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitBank2.bin"
SwbtWr_InitBank3:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitBank3.bin"
SwbtWr_DispatchLoop_Init:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop_Init.bin"
SwbtWr_DispatchLoop:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop.bin"
SwbtWr_DispatchLoop_ScanCallbacks:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop_ScanCallbacks.bin"
SwbtWr_DispatchLoop_ExecuteCallback:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop_ExecuteCallback.bin"
SwbtWr_DispatchLoop_NextEvent:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop_NextEvent.bin"
SwbtWr_DispatchLoop_PostCallbacks:
	.incbin "includes/generated/v7_transplant_SwbtWr_DispatchLoop_PostCallbacks.bin"
SwbtWr_PostCallback_Loop:
	.incbin "includes/generated/v7_transplant_SwbtWr_PostCallback_Loop.bin"
SwbtWr_PostCallback_Done:
	.incbin "includes/generated/v7_transplant_SwbtWr_PostCallback_Done.bin"
SwbtWr_QueueMainEvent:
	.incbin "includes/generated/v7_transplant_SwbtWr_QueueMainEvent.bin"
SwbtWr_QueueMainEvent_Done:
	.incbin "includes/generated/v7_transplant_SwbtWr_QueueMainEvent_Done.bin"
SwbtWr_QueuePostEvent:
	.incbin "includes/generated/v7_transplant_SwbtWr_QueuePostEvent.bin"
SwbtWr_QueuePostEvent_Done:
	.incbin "includes/generated/v7_transplant_SwbtWr_QueuePostEvent_Done.bin"
SwbtWr_TrailingBytecode:
	.incbin "includes/generated/v7_transplant_SwbtWr_TrailingBytecode.bin"
PreLswLoad:
	.incbin "includes/generated/v7_transplant_PreLswLoad.bin"
PostLswLoad:
	.incbin "includes/generated/v7_transplant_PostLswLoad.bin"
PreLswSave:
	.incbin "includes/generated/v7_transplant_PreLswSave.bin"
PostLswSave:
	.incbin "includes/generated/v7_transplant_PostLswSave.bin"
PrePmLoad:
	.incbin "includes/generated/v7_transplant_PrePmLoad.bin"
PostPmLoad:
	.incbin "includes/generated/v7_transplant_PostPmLoad.bin"
PrePmSave:
	.incbin "includes/generated/v7_transplant_PrePmSave.bin"
PostPmSave:
	.incbin "includes/generated/v7_transplant_PostPmSave.bin"
PreMidiLoad:
	.incbin "includes/generated/v7_transplant_PreMidiLoad.bin"
PostMidiLoad:
	.incbin "includes/generated/v7_transplant_PostMidiLoad.bin"
PreMidiSave:
	.incbin "includes/generated/v7_transplant_PreMidiSave.bin"
PostMidiSave:
	.incbin "includes/generated/v7_transplant_PostMidiSave.bin"
VoiceParam_SaveReverbChorus:
	.incbin "includes/generated/v7_transplant_VoiceParam_SaveReverbChorus.bin"
VoiceParam_SaveReverbChorus_Loop:
	.incbin "includes/generated/v7_transplant_VoiceParam_SaveReverbChorus_Loop.bin"
VoiceParam_RestoreReverbChorus:
	.incbin "includes/generated/v7_transplant_VoiceParam_RestoreReverbChorus.bin"
VoiceParam_RestoreReverbChorus_Loop:
	.incbin "includes/generated/v7_transplant_VoiceParam_RestoreReverbChorus_Loop.bin"
BitMapOut_ComputeRegionDelta:
	.incbin "includes/generated/v7_transplant_BitMapOut_ComputeRegionDelta.bin"
BitMapOut_PrepareAndRender:
	.incbin "includes/generated/v7_transplant_BitMapOut_PrepareAndRender.bin"
BitMapOut_RenderDisplay:
	.incbin "includes/generated/v7_transplant_BitMapOut_RenderDisplay.bin"
BitMapOut_CopyRegion_Loop:
	.incbin "includes/generated/v7_transplant_BitMapOut_CopyRegion_Loop.bin"
BitMapOut_CopyRegion_Done:
	.incbin "includes/generated/v7_transplant_BitMapOut_CopyRegion_Done.bin"
BitMapOut_SkipRestore:
	.incbin "includes/generated/v7_transplant_BitMapOut_SkipRestore.bin"
BitMapOut_MergeOutputFields:
	.incbin "includes/generated/v7_transplant_BitMapOut_MergeOutputFields.bin"
SeqOut_WriteTimedBytes:
	.incbin "includes/generated/v7_transplant_SeqOut_WriteTimedBytes.bin"
SeqOut_WriteTimedBytes_BufferFull:
	.incbin "includes/generated/v7_transplant_SeqOut_WriteTimedBytes_BufferFull.bin"
SeqOut_WriteTimedBytes_CompIface:
	.incbin "includes/generated/v7_transplant_SeqOut_WriteTimedBytes_CompIface.bin"
SeqOut_WriteTimedBytes_SerialWrite:
	.incbin "includes/generated/v7_transplant_SeqOut_WriteTimedBytes_SerialWrite.bin"
SeqOut_WriteTimedBytes_PC2Timing:
	.incbin "includes/generated/v7_transplant_SeqOut_WriteTimedBytes_PC2Timing.bin"
MIDI_SeqProcess_DisableIntReturn:
	.incbin "includes/generated/v7_transplant_MIDI_SeqProcess_DisableIntReturn.bin"
MidiSeq_ReceiveAndForward:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReceiveAndForward.bin"
MidiSeq_ReceiveAndForward_CompIface:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReceiveAndForward_CompIface.bin"
MidiSeq_ReceiveAndForward_SerialTiming:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReceiveAndForward_SerialTiming.bin"
MidiSeq_ReceiveAndForward_PC2Forward:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReceiveAndForward_PC2Forward.bin"
MidiSeq_ReceiveAndForward_Exit:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReceiveAndForward_Exit.bin"
MidiSeq_SendMultiByteWithTiming:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByteWithTiming.bin"
MidiSeq_SendMultiByte_CompIface:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_CompIface.bin"
MidiSeq_SendMultiByte_PC2CountInit:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_PC2CountInit.bin"
MidiSeq_SendMultiByte_PC2SendLoop:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_PC2SendLoop.bin"
MidiSeq_SendMultiByte_PC2NextByte:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_PC2NextByte.bin"
MidiSeq_SendMultiByte_SerialCountInit:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_SerialCountInit.bin"
MidiSeq_SendMultiByte_SerialSendLoop:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_SerialSendLoop.bin"
MidiSeq_SendMultiByte_SerialNextByte:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_SerialNextByte.bin"
MidiSeq_SendMultiByte_Exit:
	.incbin "includes/generated/v7_transplant_MidiSeq_SendMultiByte_Exit.bin"
SeqBuf_DspSysEx_DataReadLoop:
	.incbin "includes/generated/v7_transplant_SeqBuf_DspSysEx_DataReadLoop.bin"
SeqBuf_DspSysEx_ReadAndForward_Loop:
	.incbin "includes/generated/v7_transplant_SeqBuf_DspSysEx_ReadAndForward_Loop.bin"
SeqBuf_DspSysEx_ReadAndForward_Done:
	.incbin "includes/generated/v7_transplant_SeqBuf_DspSysEx_ReadAndForward_Done.bin"
SeqBuf3_EnableTx_Stub:
	.incbin "includes/generated/v7_transplant_SeqBuf3_EnableTx_Stub.bin"
MidiSysEx_BuildAndSend:
	.incbin "includes/generated/v7_transplant_MidiSysEx_BuildAndSend.bin"
MidiSysEx_ApplyChannel:
	.incbin "includes/generated/v7_transplant_MidiSysEx_ApplyChannel.bin"
MidiSysEx_BuildAndSend_Exit:
	.incbin "includes/generated/v7_transplant_MidiSysEx_BuildAndSend_Exit.bin"
MIDI_BroadcastControlChange:
	.incbin "includes/generated/v7_transplant_MIDI_BroadcastControlChange.bin"
MIDI_BroadcastCC_MidiOutLoop:
	.incbin "includes/generated/v7_transplant_MIDI_BroadcastCC_MidiOutLoop.bin"
MIDI_BroadcastCC_CommLoop:
	.incbin "includes/generated/v7_transplant_MIDI_BroadcastCC_CommLoop.bin"
CompIface_SendActiveSensing:
	.incbin "includes/generated/v7_transplant_CompIface_SendActiveSensing.bin"
CompIface_SendActiveSensing_PC1MAC:
	.incbin "includes/generated/v7_transplant_CompIface_SendActiveSensing_PC1MAC.bin"
CompIface_SendActiveSensing_PC2:
	.incbin "includes/generated/v7_transplant_CompIface_SendActiveSensing_PC2.bin"
MidiOut_RealtimeDispatch_Data:
	.incbin "includes/generated/v7_transplant_MidiOut_RealtimeDispatch_Data.bin"
MidiOut_SerializeAndSend:
	.incbin "includes/generated/v7_transplant_MidiOut_SerializeAndSend.bin"
MidiOut_SerializeRealtimeLoop:
	.incbin "includes/generated/v7_transplant_MidiOut_SerializeRealtimeLoop.bin"
MidiOut_CheckStart:
	.incbin "includes/generated/v7_transplant_MidiOut_CheckStart.bin"
MidiOut_CheckContinue:
	.incbin "includes/generated/v7_transplant_MidiOut_CheckContinue.bin"
MidiOut_CheckStop:
	.incbin "includes/generated/v7_transplant_MidiOut_CheckStop.bin"
MidiOut_ReadSysExByte:
	.incbin "includes/generated/v7_transplant_MidiOut_ReadSysExByte.bin"
MidiOut_FlushBuffer:
	.incbin "includes/generated/v7_transplant_MidiOut_FlushBuffer.bin"
MidiOut_SerializeAndSend_Exit:
	.incbin "includes/generated/v7_transplant_MidiOut_SerializeAndSend_Exit.bin"
MidiThru_Disable:
	.incbin "includes/generated/v7_transplant_MidiThru_Disable.bin"
MidiThru_Enable:
	.incbin "includes/generated/v7_transplant_MidiThru_Enable.bin"
GET_COMPUTER_INTERFACE_SELECTION:
	.incbin "includes/generated/v7_transplant_GET_COMPUTER_INTERFACE_SELECTION.bin"
CompIface_ProcessInput:
	.incbin "includes/generated/v7_transplant_CompIface_ProcessInput.bin"
CompIface_CheckUpDown:
	.incbin "includes/generated/v7_transplant_CompIface_CheckUpDown.bin"
CompIface_RampDown:
	.incbin "includes/generated/v7_transplant_CompIface_RampDown.bin"
CompIface_RampDown_Start:
	.incbin "includes/generated/v7_transplant_CompIface_RampDown_Start.bin"
CompIface_FilterBySource:
	.incbin "includes/generated/v7_transplant_CompIface_FilterBySource.bin"
CompIface_FromSource2:
	.incbin "includes/generated/v7_transplant_CompIface_FromSource2.bin"
CompIface_Source2_ZeroCheck:
	.incbin "includes/generated/v7_transplant_CompIface_Source2_ZeroCheck.bin"
CompIface_SetPedalBit:
	.incbin "includes/generated/v7_transplant_CompIface_SetPedalBit.bin"
CompIface_CallFilterA:
	.incbin "includes/generated/v7_transplant_CompIface_CallFilterA.bin"
CompIface_CallSync:
	.incbin "includes/generated/v7_transplant_CompIface_CallSync.bin"
CompIface_PostProcess:
	.incbin "includes/generated/v7_transplant_CompIface_PostProcess.bin"
CompIface_RampControl:
	.incbin "includes/generated/v7_transplant_CompIface_RampControl.bin"
CompIface_RampUp_Clamp:
	.incbin "includes/generated/v7_transplant_CompIface_RampUp_Clamp.bin"
CompIface_RampDown_Apply:
	.incbin "includes/generated/v7_transplant_CompIface_RampDown_Apply.bin"
CompIface_RampDown_Clamp:
	.incbin "includes/generated/v7_transplant_CompIface_RampDown_Clamp.bin"
CompIface_ResetPedal:
	.incbin "includes/generated/v7_transplant_CompIface_ResetPedal.bin"
CompIface_SetMax:
	.incbin "includes/generated/v7_transplant_CompIface_SetMax.bin"
CompIface_ScaleValue:
	.incbin "includes/generated/v7_transplant_CompIface_ScaleValue.bin"
CompIface_ScaleAndNormalize:
	.incbin "includes/generated/v7_transplant_CompIface_ScaleAndNormalize.bin"
CompIface_WriteVolume:
	.incbin "includes/generated/v7_transplant_CompIface_WriteVolume.bin"
Audio_ConfigureDSP:
	.incbin "includes/generated/v7_transplant_Audio_ConfigureDSP.bin"
DSPCfg_ProcessInput:
	.incbin "includes/generated/v7_transplant_DSPCfg_ProcessInput.bin"
DSPCfg_Reverb_CheckSustain:
	.incbin "includes/generated/v7_transplant_DSPCfg_Reverb_CheckSustain.bin"
DSPCfg_Chorus_Active:
	.incbin "includes/generated/v7_transplant_DSPCfg_Chorus_Active.bin"
DSPCfg_Chorus_CheckSustain:
	.incbin "includes/generated/v7_transplant_DSPCfg_Chorus_CheckSustain.bin"
DSPCfg_FadeOut_Active:
	.incbin "includes/generated/v7_transplant_DSPCfg_FadeOut_Active.bin"
DSPCfg_FadeOut_CheckSustain:
	.incbin "includes/generated/v7_transplant_DSPCfg_FadeOut_CheckSustain.bin"
DSPCfg_EQ_Active:
	.incbin "includes/generated/v7_transplant_DSPCfg_EQ_Active.bin"
DSPCfg_EQ_CheckSustain:
	.incbin "includes/generated/v7_transplant_DSPCfg_EQ_CheckSustain.bin"
DSPCfg_Idle_EnableChorus:
	.incbin "includes/generated/v7_transplant_DSPCfg_Idle_EnableChorus.bin"
DSPCfg_Idle_CheckSustain:
	.incbin "includes/generated/v7_transplant_DSPCfg_Idle_CheckSustain.bin"
DSPCfg_SetFadeBit:
	.incbin "includes/generated/v7_transplant_DSPCfg_SetFadeBit.bin"
DSPCfg_UpdateOutputVolume:
	.incbin "includes/generated/v7_transplant_DSPCfg_UpdateOutputVolume.bin"
DSPCfg_CheckChorusMuted:
	.incbin "includes/generated/v7_transplant_DSPCfg_CheckChorusMuted.bin"
DSPCfg_CompressorDispatch:
	.incbin "includes/generated/v7_transplant_DSPCfg_CompressorDispatch.bin"
DSPCfg_CompParam_SubType6:
	.incbin "includes/generated/v7_transplant_DSPCfg_CompParam_SubType6.bin"
DSPCfg_CompParam_SubType7:
	.incbin "includes/generated/v7_transplant_DSPCfg_CompParam_SubType7.bin"
DSPCfg_CompParam_Bit1:
	.incbin "includes/generated/v7_transplant_DSPCfg_CompParam_Bit1.bin"
DSPCfg_CompParam_Bit2:
	.incbin "includes/generated/v7_transplant_DSPCfg_CompParam_Bit2.bin"
DSPCfg_ScaleFactor_Dispatch:
	.incbin "includes/generated/v7_transplant_DSPCfg_ScaleFactor_Dispatch.bin"
DSPCfg_ScaleFactor_Update:
	.incbin "includes/generated/v7_transplant_DSPCfg_ScaleFactor_Update.bin"
DSPCfg_ScaleFactor_StoreResult:
	.incbin "includes/generated/v7_transplant_DSPCfg_ScaleFactor_StoreResult.bin"
DSPCfg_LookupMidiMap:
	.incbin "includes/generated/v7_transplant_DSPCfg_LookupMidiMap.bin"
DSPCfg_ExtractFieldPair:
	.incbin "includes/generated/v7_transplant_DSPCfg_ExtractFieldPair.bin"
DSPCfg_ExtractAdjustType2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ExtractAdjustType2.bin"
DSPCfg_ExtractFieldSingle:
	.incbin "includes/generated/v7_transplant_DSPCfg_ExtractFieldSingle.bin"
DSPCfg_WriteParam:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam.bin"
DSPCfg_WriteParam_SetMask:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_SetMask.bin"
DSPCfg_WriteParam_Exit:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Exit.bin"
DSPCfg_WriteParam_Type64_67:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type64_67.bin"
DSPCfg_WriteParam_Type70:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type70.bin"
DSPCfg_WriteParam_Type70_Sub10:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type70_Sub10.bin"
DSPCfg_WriteParam_Type70_Sub20:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type70_Sub20.bin"
DSPCfg_WriteParam_Type76:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type76.bin"
DSPCfg_WriteParam_SetMask7:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_SetMask7.bin"
DSPCfg_WriteParam_Type76_Sub10:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type76_Sub10.bin"
DSPCfg_WriteParam_Type76_NotType2:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_Type76_NotType2.bin"
DSPCfg_WriteParam_IncCounter:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_IncCounter.bin"
DSPCfg_WriteParam_SetMask3F:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParam_SetMask3F.bin"
DSPCfg_PackAddress:
	.incbin "includes/generated/v7_transplant_DSPCfg_PackAddress.bin"
DSPCfg_PackAddress_ReturnInput:
	.incbin "includes/generated/v7_transplant_DSPCfg_PackAddress_ReturnInput.bin"
DSPCfg_ReadField:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField.bin"
DSPCfg_ReadField_SetWidth1:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_SetWidth1.bin"
DSPCfg_ReadField_StoreAndReturn:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_StoreAndReturn.bin"
DSPCfg_ReadField_GoWidth2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_GoWidth2.bin"
DSPCfg_ReadField_Type68_Unsigned:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type68_Unsigned.bin"
DSPCfg_ReadField_Type70:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type70.bin"
DSPCfg_ReadField_Type70_Width16:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type70_Width16.bin"
DSPCfg_ReadField_Type70_Width32:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type70_Width32.bin"
DSPCfg_ReadField_SetWidth2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_SetWidth2.bin"
DSPCfg_ReadField_Type76:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type76.bin"
DSPCfg_ReadField_Type76_ShiftAndMask:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type76_ShiftAndMask.bin"
DSPCfg_ReadField_Type76_Mask5Bits:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type76_Mask5Bits.bin"
DSPCfg_ReadField_Type76_Width16:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadField_Type76_Width16.bin"
DSPCfg_WriteMultiField:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteMultiField.bin"
DSPCfg_WriteMultiField_Loop:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteMultiField_Loop.bin"
DSPCfg_WriteMultiField_AccumXWA:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteMultiField_AccumXWA.bin"
DSPCfg_WriteMultiField_AdvanceAddr:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteMultiField_AdvanceAddr.bin"
DSPCfg_WriteMultiField_Final:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteMultiField_Final.bin"
DSPCfg_ReadMultiField:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadMultiField.bin"
DSPCfg_ReadMultiField_Loop:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadMultiField_Loop.bin"
DSPCfg_ReadMultiField_AdvancePtr:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadMultiField_AdvancePtr.bin"
DSPCfg_ReadMultiField_PackAndNext:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadMultiField_PackAndNext.bin"
DSPCfg_ReadMultiField_Final:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadMultiField_Final.bin"
DSPCfg_GetParamCount:
	.incbin "includes/generated/v7_transplant_DSPCfg_GetParamCount.bin"
DSPCfg_ReadViaTableLookup:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadViaTableLookup.bin"
DSPCfg_StoreByte_ReturnZero:
	.incbin "includes/generated/v7_transplant_DSPCfg_StoreByte_ReturnZero.bin"
DSPCfg_WriteViaTableLookup:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteViaTableLookup.bin"
DSPCfg_ExtractPairFromStruct:
	.incbin "includes/generated/v7_transplant_DSPCfg_ExtractPairFromStruct.bin"
DSPCfg_LookupAndExtract:
	.incbin "includes/generated/v7_transplant_DSPCfg_LookupAndExtract.bin"
DSPCfg_Data_001:
	.incbin "includes/generated/v7_transplant_DSPCfg_Data_001.bin"
DSPCfg_GetSlotCount:
	.incbin "includes/generated/v7_transplant_DSPCfg_GetSlotCount.bin"
DSPCfg_Data_002:
	.incbin "includes/generated/v7_transplant_DSPCfg_Data_002.bin"
DSPCfg_FindSlot63:
	.incbin "includes/generated/v7_transplant_DSPCfg_FindSlot63.bin"
DSPCfg_FindSlot63_Loop:
	.incbin "includes/generated/v7_transplant_DSPCfg_FindSlot63_Loop.bin"
DSPCfg_FindSlot63_Next:
	.incbin "includes/generated/v7_transplant_DSPCfg_FindSlot63_Next.bin"
DSPCfg_FindSlot63_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_FindSlot63_Return.bin"
DSPCfg_Data_003:
	.incbin "includes/generated/v7_transplant_DSPCfg_Data_003.bin"
DSPCfg_DecodeParamIdRange:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange.bin"
DSPCfg_DecodeParamIdRange_4910:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange_4910.bin"
DSPCfg_DecodeParamIdRange_4940:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange_4940.bin"
DSPCfg_DecodeParamIdRange_CalcOffset:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange_CalcOffset.bin"
DSPCfg_DecodeParamIdRange_Invalid:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange_Invalid.bin"
DSPCfg_DecodeParamIdRange_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_DecodeParamIdRange_Return.bin"
DSPCfg_ResolveParamToSlot:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot.bin"
DSPCfg_ResolveParamToSlot_OutOfRange:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_OutOfRange.bin"
DSPCfg_ResolveParamToSlot_Range49:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range49.bin"
DSPCfg_ResolveParamToSlot_Range4A:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range4A.bin"
DSPCfg_ResolveParamToSlot_Range4B:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range4B.bin"
DSPCfg_ResolveParamToSlot_Range4C:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range4C.bin"
DSPCfg_ResolveParamToSlot_Range4D:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range4D.bin"
DSPCfg_ResolveParamToSlot_Range4E:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_Range4E.bin"
DSPCfg_ResolveParamToSlot_CallDecode:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_CallDecode.bin"
DSPCfg_ResolveParamToSlot_StoreResult:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveParamToSlot_StoreResult.bin"
DSPCfg_ResolveAndExtract:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveAndExtract.bin"
DSPCfg_ResolveAndExtract_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveAndExtract_Return.bin"
DSPCfg_ResolveWithFallback:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback.bin"
DSPCfg_ResolveWithFallback_CheckType:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_CheckType.bin"
DSPCfg_ResolveWithFallback_Type1:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_Type1.bin"
DSPCfg_ResolveWithFallback_SndParam4003:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_SndParam4003.bin"
DSPCfg_ResolveWithFallback_Type8:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_Type8.bin"
DSPCfg_ResolveWithFallback_Type9:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_Type9.bin"
DSPCfg_ResolveWithFallback_UnknownType:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_UnknownType.bin"
DSPCfg_ResolveWithFallback_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_ResolveWithFallback_Return.bin"
DSPCfg_ReadParam_Map0:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadParam_Map0.bin"
DSPCfg_ReadParam_Map1:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadParam_Map1.bin"
DSPCfg_ClampAndExtract:
	.incbin "includes/generated/v7_transplant_DSPCfg_ClampAndExtract.bin"
DSPCfg_ClampAndExtract_CheckMax:
	.incbin "includes/generated/v7_transplant_DSPCfg_ClampAndExtract_CheckMax.bin"
DSPCfg_ClampAndExtract_InRange:
	.incbin "includes/generated/v7_transplant_DSPCfg_ClampAndExtract_InRange.bin"
DSPCfg_ClampAndExtract_NoSlot:
	.incbin "includes/generated/v7_transplant_DSPCfg_ClampAndExtract_NoSlot.bin"
DSPCfg_ClampAndExtract_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_ClampAndExtract_Return.bin"
DSPCfg_ValidateSlotForWrite:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite.bin"
DSPCfg_ValidateSlotForWrite_Invalid:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Invalid.bin"
DSPCfg_ValidateSlotForWrite_Ret:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Ret.bin"
DSPCfg_ValidateSlotForWrite_Slot1:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Slot1.bin"
DSPCfg_ValidateSlotForWrite_Slot2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Slot2.bin"
DSPCfg_ValidateSlotForWrite_Slot3:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Slot3.bin"
DSPCfg_ValidateSlotForWrite_Slot4:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Slot4.bin"
DSPCfg_ValidateSlotForWrite_Valid:
	.incbin "includes/generated/v7_transplant_DSPCfg_ValidateSlotForWrite_Valid.bin"
DSPCfg_WriteParamFull:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull.bin"
DSPCfg_WriteParamFull_Type1:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Type1.bin"
DSPCfg_WriteParamFull_Type1_Clamped:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Type1_Clamped.bin"
DSPCfg_WriteParamFull_Type1_Notify:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Type1_Notify.bin"
DSPCfg_WriteParamFull_Check491D:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Check491D.bin"
DSPCfg_WriteParamFull_Notify4003:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Notify4003.bin"
DSPCfg_WriteParamFull_UnknownType:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_UnknownType.bin"
DSPCfg_WriteParamFull_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamFull_Return.bin"
DSPCfg_WriteParamSimple:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple.bin"
DSPCfg_WriteParamSimple_Type1:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_Type1.bin"
DSPCfg_WriteParamSimple_Type1_Clamped:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_Type1_Clamped.bin"
DSPCfg_WriteParamSimple_Check491D:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_Check491D.bin"
DSPCfg_WriteParamSimple_Notify4003:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_Notify4003.bin"
DSPCfg_WriteParamSimple_UnknownType:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_UnknownType.bin"
DSPCfg_WriteParamSimple_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamSimple_Return.bin"
DSPCfg_WriteParamDelta:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamDelta.bin"
DSPCfg_WriteParamDelta_Type1:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamDelta_Type1.bin"
DSPCfg_WriteParamDelta_CallWrite:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamDelta_CallWrite.bin"
DSPCfg_WriteParamDelta_BadType:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamDelta_BadType.bin"
DSPCfg_WriteParamDelta_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteParamDelta_Return.bin"
DSPCfg_WriteAllSlots_Direct:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Direct.bin"
DSPCfg_WriteAllSlots_Direct_Loop:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Direct_Loop.bin"
DSPCfg_WriteAllSlots_Direct_CheckCount:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Direct_CheckCount.bin"
DSPCfg_WriteAllSlots_Direct_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Direct_Return.bin"
DSPCfg_WriteAllSlots_Clamped:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Clamped.bin"
DSPCfg_WriteAllSlots_Clamped_Loop:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Clamped_Loop.bin"
DSPCfg_WriteAllSlots_Clamped_Next:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Clamped_Next.bin"
DSPCfg_WriteAllSlots_Clamped_CheckCount:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Clamped_CheckCount.bin"
DSPCfg_WriteAllSlots_Combined:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Combined.bin"
DSPCfg_WriteAllSlots_Combined_Done:
	.incbin "includes/generated/v7_transplant_DSPCfg_WriteAllSlots_Combined_Done.bin"
DSPCfg_Data_ParamDispatch:
	.incbin "includes/generated/v7_transplant_DSPCfg_Data_ParamDispatch.bin"
DSPCfg_CheckParamTableEntry:
	.incbin "includes/generated/v7_transplant_DSPCfg_CheckParamTableEntry.bin"
DSPCfg_CheckParamTableEntry_NotFound:
	.incbin "includes/generated/v7_transplant_DSPCfg_CheckParamTableEntry_NotFound.bin"
DSPCfg_ReadFieldSimple:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadFieldSimple.bin"
DSPCfg_ReadFieldSimple_StoreReturn:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadFieldSimple_StoreReturn.bin"
DSPCfg_ReadFieldSimple_Type64_67:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadFieldSimple_Type64_67.bin"
DSPCfg_ReadFieldSimple_Type70:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadFieldSimple_Type70.bin"
DSPCfg_ReadFieldSimple_SetWidth2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ReadFieldSimple_SetWidth2.bin"
DSPCfg_ApplyParamStruct:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct.bin"
DSPCfg_ApplyParamStruct_Normal:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_Normal.bin"
DSPCfg_ApplyParamStruct_ReadLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_ReadLoop.bin"
DSPCfg_ApplyParamStruct_AdvancePtr:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_AdvancePtr.bin"
DSPCfg_ApplyParamStruct_PackNext:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_PackNext.bin"
DSPCfg_ApplyParamStruct_CheckSpecial:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_CheckSpecial.bin"
DSPCfg_ApplyParamStruct_Offset2:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_Offset2.bin"
DSPCfg_ApplyParamStruct_Offset1:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_Offset1.bin"
DSPCfg_ApplyParamStruct_WriteLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_WriteLoop.bin"
DSPCfg_ApplyParamStruct_WriteReadLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_WriteReadLoop.bin"
DSPCfg_ApplyParamStruct_WriteSkip2Byte:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_WriteSkip2Byte.bin"
DSPCfg_ApplyParamStruct_WriteAdvancePtr:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_WriteAdvancePtr.bin"
DSPCfg_ApplyParamStruct_WritePackNext:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_WritePackNext.bin"
DSPCfg_ApplyParamStruct_Return:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStruct_Return.bin"
DSPCfg_ApplyParamStructFull:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStructFull.bin"
DSPCfg_ApplyParamStructFull_RangeCheck:
	.incbin "includes/generated/v7_transplant_DSPCfg_ApplyParamStructFull_RangeCheck.bin"
DspConfig_EventDispatch:
	.incbin "includes/generated/v7_transplant_DspConfig_EventDispatch.bin"
AssSwb_SwapEntriesAndDispatch:
	.incbin "includes/generated/v7_transplant_AssSwb_SwapEntriesAndDispatch.bin"
DSPCfg_EventType36_ClampResult:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType36_ClampResult.bin"
DSPCfg_EventType30:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType30.bin"
DSPCfg_EventType32:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType32.bin"
DSPCfg_EventType34:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType34.bin"
DSPCfg_EventType35:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType35.bin"
DSPCfg_EventType36:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType36.bin"
DSPCfg_EventType36_StoreTail:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType36_StoreTail.bin"
DSPCfg_EventType40:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType40.bin"
DSPCfg_EventType42:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType42.bin"
DSPCfg_EventType44:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType44.bin"
DSPCfg_EventType46:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType46.bin"
DSPCfg_EventType10to1B:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType10to1B.bin"
DSPCfg_EventType50:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType50.bin"
DSPCfg_EventType51:
	.incbin "includes/generated/v7_transplant_DSPCfg_EventType51.bin"
DSPCfg_Epilogue:
	.incbin "includes/generated/v7_transplant_DSPCfg_Epilogue.bin"
DSPCfg_ReturnValueTable:
	.incbin "includes/generated/v7_fix_dspcfg_returnvaluetable.bin"
	.include "boot/screen_group_dispatch.s"

AudioInit_ProcessModeChange:
	.incbin "includes/generated/v7_transplant_AudioInit_ProcessModeChange.bin"
AudioModeChange_ClearVoiceFlags:
	.incbin "includes/generated/v7_transplant_AudioModeChange_ClearVoiceFlags.bin"
AudioModeChange_Handler:
	.incbin "includes/generated/v7_transplant_AudioModeChange_Handler.bin"
Audio_CheckSubsystemReady:
	.incbin "includes/generated/v7_transplant_Audio_CheckSubsystemReady.bin"
AudioSubsystem_ClearVoiceFlags:
	.incbin "includes/generated/v7_transplant_AudioSubsystem_ClearVoiceFlags.bin"
AudioSubsystem_Callback:
	.incbin "includes/generated/v7_transplant_AudioSubsystem_Callback.bin"
AudioInit_SelectAndDispatch:
	.incbin "includes/generated/v7_transplant_AudioInit_SelectAndDispatch.bin"
AudioInit_CheckMIDIAndDispatch:
	.incbin "includes/generated/v7_transplant_AudioInit_CheckMIDIAndDispatch.bin"
Audio_InitDispatchReturn:
	.incbin "includes/generated/v7_transplant_Audio_InitDispatchReturn.bin"
AudioDispatch_ClearAccFlags:
	.incbin "includes/generated/v7_transplant_AudioDispatch_ClearAccFlags.bin"
AudioDispatch_SetAccMode:
	.incbin "includes/generated/v7_transplant_AudioDispatch_SetAccMode.bin"
AudioDispatch_SetTimerBase:
	.incbin "includes/generated/v7_transplant_AudioDispatch_SetTimerBase.bin"
AudioDispatch_CheckStereoMode:
	.incbin "includes/generated/v7_transplant_AudioDispatch_CheckStereoMode.bin"
AudioDispatch_ClearVoiceFlags:
	.incbin "includes/generated/v7_transplant_AudioDispatch_ClearVoiceFlags.bin"
AudioDispatch_SetBusyFlag:
	.incbin "includes/generated/v7_transplant_AudioDispatch_SetBusyFlag.bin"
AudioVoice_Callback:
	.incbin "includes/generated/v7_transplant_AudioVoice_Callback.bin"
AudioVoice_SkipToDispatch:
	.incbin "includes/generated/v7_transplant_AudioVoice_SkipToDispatch.bin"
AudioMode_SetStereoFlags:
	.incbin "includes/generated/v7_transplant_AudioMode_SetStereoFlags.bin"
AudioMode_ResetVoiceState:
	.incbin "includes/generated/v7_transplant_AudioMode_ResetVoiceState.bin"
AudioVoiceReset_ClearFlags:
	.incbin "includes/generated/v7_transplant_AudioVoiceReset_ClearFlags.bin"
AudioVoiceReset_Handler:
	.incbin "includes/generated/v7_transplant_AudioVoiceReset_Handler.bin"
AudioMode_ConfigureExternal:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigureExternal.bin"
AudioMode_ConfigExternal_Off:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_Off.bin"
AudioMode_ConfigExternal_CheckBit1:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_CheckBit1.bin"
AudioMode_ConfigExternal_CheckStereo:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_CheckStereo.bin"
AudioMode_ConfigExternal_NoStereo:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_NoStereo.bin"
AudioMode_ConfigExternal_MergeFlags:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_MergeFlags.bin"
AudioMode_ConfigExternal_Apply:
	.incbin "includes/generated/v7_transplant_AudioMode_ConfigExternal_Apply.bin"
UIState_ProcessMidiEvent:
	.incbin "includes/generated/v7_transplant_UIState_ProcessMidiEvent.bin"
UIStateEvt_PartRouting:
	.incbin "includes/generated/v7_transplant_UIStateEvt_PartRouting.bin"
UIStateEvt_VoiceAssign:
	.incbin "includes/generated/v7_transplant_UIStateEvt_VoiceAssign.bin"
UIStateEvt_VoiceAssign_Reset:
	.incbin "includes/generated/v7_transplant_UIStateEvt_VoiceAssign_Reset.bin"
UIStateEvt_VoiceAssign_Notify:
	.incbin "includes/generated/v7_transplant_UIStateEvt_VoiceAssign_Notify.bin"
UIStateEvt_ToneChange:
	.incbin "includes/generated/v7_transplant_UIStateEvt_ToneChange.bin"
UIStateEvt_ToneChange_Set:
	.incbin "includes/generated/v7_transplant_UIStateEvt_ToneChange_Set.bin"
Tone_WriteEndMarker:
	.incbin "includes/generated/v7_transplant_Tone_WriteEndMarker.bin"
UIStateEvt_DrumAssign:
	.incbin "includes/generated/v7_transplant_UIStateEvt_DrumAssign.bin"
UIStateEvt_DrumAssign_Set:
	.incbin "includes/generated/v7_transplant_UIStateEvt_DrumAssign_Set.bin"
UIStateEvt_DrumAssign_Notify:
	.incbin "includes/generated/v7_transplant_UIStateEvt_DrumAssign_Notify.bin"
UIStateEvt_TransposeUpdate:
	.incbin "includes/generated/v7_block_uistateevt_transposeupdate.bin"
; === end v7 block ===
	.include "audio/audioinit_routines.s"
