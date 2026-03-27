; =============================================================================
; MIDI Dispatch Handlers (11K lines)
; =============================================================================
;
; MIDI Control Change handlers (22 types), serial input parsing,
; file data validation, sound mode handlers, and arpeggiator queue.
; The main MIDI message routing and processing layer.
; =============================================================================



MidiSerial_RetStub:
	.incbin "includes/generated/v7_transplant_MidiSerial_RetStub.bin"
MidiSerial_ProcessInput:
	.incbin "includes/generated/v7_transplant_MidiSerial_ProcessInput.bin"
MidiSerial_PumpLoop:
	.incbin "includes/generated/v7_transplant_MidiSerial_PumpLoop.bin"
MidiSerial_PumpDone:
	.incbin "includes/generated/v7_transplant_MidiSerial_PumpDone.bin"
MidiSerial_Return:
	.incbin "includes/generated/v7_transplant_MidiSerial_Return.bin"
MidiSerial_StatusTable:
	.incbin "includes/generated/v7_transplant_MidiSerial_StatusTable.bin"
MidiSerial_WaitForData:
	.incbin "includes/generated/v7_transplant_MidiSerial_WaitForData.bin"
MidiSerial_WaitLoop:
	.incbin "includes/generated/v7_transplant_MidiSerial_WaitLoop.bin"
MidiSerial_WaitDone:
	.incbin "includes/generated/v7_transplant_MidiSerial_WaitDone.bin"
MidiSerial_ParseStatus_Data:
	.incbin "includes/generated/v7_transplant_MidiSerial_ParseStatus_Data.bin"
MidiSerial_CmdJumpTable:
	.incbin "includes/generated/v7_transplant_MidiSerial_CmdJumpTable.bin"
MidiSerial_HandleSysReset_Data:
	.incbin "includes/generated/v7_transplant_MidiSerial_HandleSysReset_Data.bin"
MidiSerial_HandleSysCommon_Data:
	.incbin "includes/generated/v7_transplant_MidiSerial_HandleSysCommon_Data.bin"
MidiSerial_HandleDefault_Data:
	.incbin "includes/generated/v7_transplant_MidiSerial_HandleDefault_Data.bin"
MidiCC_LowRange_Table:
	.incbin "includes/generated/v7_transplant_MidiCC_LowRange_Table.bin"
MidiCC_Handler_SimpleParamStore:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_SimpleParamStore.bin"
MidiCC_Handler_CC3_TableLookup:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_CC3_TableLookup.bin"
MidiCC_ExtendedRange_Table:
	.incbin "includes/generated/v7_transplant_MidiCC_ExtendedRange_Table.bin"
MidiCC_NullHandlerBlock:
	.incbin "includes/generated/v7_transplant_MidiCC_NullHandlerBlock.bin"
MidiCC_Handler_BitManipulation:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_BitManipulation.bin"
MidiCC_Handler_PairedParamA:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_PairedParamA.bin"
MidiCC_Handler_PairedParamB:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_PairedParamB.bin"
MidiCC_Handler_RangeCheck:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_RangeCheck.bin"
MidiCC_Handler_ChannelMapping:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_ChannelMapping.bin"
MidiCC_VoiceParam_0:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_0.bin"
MidiCC_VoiceParam_1:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_1.bin"
MidiCC_VoiceParam_2:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_2.bin"
MidiCC_VoiceParam_3:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_3.bin"
MidiCC_VoiceParam_4:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_4.bin"
MidiCC_VoiceParam_5:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_5.bin"
MidiCC_VoiceParam_6:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_6.bin"
MidiCC_VoiceParam_7:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_7.bin"
MidiCC_VoiceParam_8:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_8.bin"
MidiCC_VoiceParam_9:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_9.bin"
MidiCC_StubHandler_A:
	.incbin "includes/generated/v7_transplant_MidiCC_StubHandler_A.bin"
MidiCC_StubHandler_B:
	.incbin "includes/generated/v7_transplant_MidiCC_StubHandler_B.bin"
MidiCC_VoiceParam_10:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_10.bin"
MidiCC_VoiceParam_11:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_11.bin"
MidiCC_VoiceParam_11_MidEntry:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_11_MidEntry.bin"
MidiCC_VoiceParam_12:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_12.bin"
MidiCC_VoiceParam_13:
	.incbin "includes/generated/v7_transplant_MidiCC_VoiceParam_13.bin"
MidiCC_Handler_BankModeSelect:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_BankModeSelect.bin"
MidiCC_Handler_ExpressionParam:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_ExpressionParam.bin"
MidiCC_Handler_DirectStoreA:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_DirectStoreA.bin"
MidiCC_Handler_DirectStoreB:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_DirectStoreB.bin"
MidiCC_Handler_ParamDispatch:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_ParamDispatch.bin"
MidiCC_Handler_TableDispatch:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_TableDispatch.bin"
MidiCC_Handler_TableDispatch_Ret:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_TableDispatch_Ret.bin"
MidiCC_Helper_ConditionalESetup:
	.incbin "includes/generated/v7_transplant_MidiCC_Helper_ConditionalESetup.bin"
MidiCC_Helper_ConditionalESetup_Store:
	.incbin "includes/generated/v7_transplant_MidiCC_Helper_ConditionalESetup_Store.bin"
MidiCC_Helper_EntryWithEqA:
	.incbin "includes/generated/v7_transplant_MidiCC_Helper_EntryWithEqA.bin"
MidiCC_Handler_CC4_VoiceParam:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_CC4_VoiceParam.bin"
MidiCC_Handler_CC6_VoiceParam:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_CC6_VoiceParam.bin"
MidiCC_Handler_CC5_VoiceParam:
	.incbin "includes/generated/v7_transplant_MidiCC_Handler_CC5_VoiceParam.bin"
UIState_ProcessDisplayUpdate:
	.incbin "includes/generated/v7_transplant_UIState_ProcessDisplayUpdate.bin"
UIState_DisplayUpdate_BitmapHandler:
	.incbin "includes/generated/v7_transplant_UIState_DisplayUpdate_BitmapHandler.bin"
MIDI_DispatchCC:
	.incbin "includes/generated/v7_transplant_MIDI_DispatchCC.bin"
MidiCC_DispatchCleanupRet:
	.incbin "includes/generated/v7_transplant_MidiCC_DispatchCleanupRet.bin"
MidiCC_DispatchStubRet:
	.incbin "includes/generated/v7_transplant_MidiCC_DispatchStubRet.bin"
PanelEvt_CheckFlag7_Dispatch_A:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Dispatch_A.bin"
PanelEvt_CheckFlag7_DoDispatch_A:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_DoDispatch_A.bin"
PanelEvt_CheckFlag7_Ret_A:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Ret_A.bin"
PanelEvt_CheckFlag7_Dispatch_B:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Dispatch_B.bin"
PanelEvt_CheckFlag7_DoDispatch_B:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_DoDispatch_B.bin"
PanelEvt_CheckFlag7_Ret_B:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Ret_B.bin"
PanelEvt_CheckFlag7_Dispatch_C:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Dispatch_C.bin"
PanelEvt_CheckFlag7_DoDispatch_C:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_DoDispatch_C.bin"
PanelEvt_CheckFlag7_Ret_C:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag7_Ret_C.bin"
PanelEvt_UnconditionalDispatch:
	.incbin "includes/generated/v7_transplant_PanelEvt_UnconditionalDispatch.bin"
PanelEvt_CheckFlag6_Dispatch:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag6_Dispatch.bin"
PanelEvt_CheckFlag6_Ret:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckFlag6_Ret.bin"
PanelEvt_CheckChanZero_Dispatch:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckChanZero_Dispatch.bin"
PanelEvt_CheckChanZero_DoDispatch:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckChanZero_DoDispatch.bin"
PanelEvt_CheckChanZero_Ret:
	.incbin "includes/generated/v7_transplant_PanelEvt_CheckChanZero_Ret.bin"
PanelEvt_DispatchTable:
	.incbin "includes/generated/v7_transplant_PanelEvt_DispatchTable.bin"
PanelEvt_Handler_0_NoteOnParam:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_0_NoteOnParam.bin"
PanelEvt_Handler_3_ValueCheck:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_3_ValueCheck.bin"
PanelEvt_Handler_5_ValueCheck:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_5_ValueCheck.bin"
PanelEvt_Handler_6_NullStub:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_6_NullStub.bin"
PanelEvt_Handler_7_ValueCheck:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_7_ValueCheck.bin"
PanelEvt_Handler_8_ValueCheck:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_8_ValueCheck.bin"
PanelEvt_Handler_9_SingleByteParam:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_9_SingleByteParam.bin"
PanelEvt_Handler_10_TwoByteParam:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_10_TwoByteParam.bin"
PanelEvt_Handler_11_SingleByteParam:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_11_SingleByteParam.bin"
PanelEvt_Handler_15_ConditionalSet:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_15_ConditionalSet.bin"
PanelEvt_Dispatch6Entry:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch6Entry.bin"
PanelEvt_Dispatch6_TableAndHandlers:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch6_TableAndHandlers.bin"
PanelEvt_Dispatch3Entry_A:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch3Entry_A.bin"
PanelEvt_Dispatch3_TableAndHandlers_A:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch3_TableAndHandlers_A.bin"
PanelEvt_Dispatch3Entry_B:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch3Entry_B.bin"
PanelEvt_Dispatch3_Table_B:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch3_Table_B.bin"
PanelEvt_Dispatch11Entry:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch11Entry.bin"
PanelEvt_Dispatch11_TableAndHandlers:
	.incbin "includes/generated/v7_transplant_PanelEvt_Dispatch11_TableAndHandlers.bin"
PanelEvent_DispatchByIndex:
	.incbin "includes/generated/v7_transplant_PanelEvent_DispatchByIndex.bin"
PanelEvt_DispatchByIndex_Ret:
	.incbin "includes/generated/v7_transplant_PanelEvt_DispatchByIndex_Ret.bin"
MidiCC_ChannelDispatch_TableA:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_TableA.bin"
MidiCC_ChannelDispatch_TableA_Ret:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_TableA_Ret.bin"
MidiCC_ChannelDispatch_Ctrl40:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl40.bin"
BitMask_Ctrl40_ConfigExit:
	.byte 0x21

MidiCC_ChannelDispatch_Ctrl41:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl41.bin"
MidiCC_ChannelDispatch_Ctrl41_Ret:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl41_Ret.bin"
MidiCC_ChannelDispatch_SpecialCh1:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_SpecialCh1.bin"
MidiCC_ChannelDispatch_SpecialCh1_Ret:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_SpecialCh1_Ret.bin"
MidiCC_ChannelDispatch_CtrlFlags:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_CtrlFlags.bin"
MidiCC_ChannelDispatch_BuildPacket:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_BuildPacket.bin"
PanelEvent_NullRet:
	.incbin "includes/generated/v7_transplant_PanelEvent_NullRet.bin"
MidiCC_ChannelDispatch_Ctrl1:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl1.bin"
BitMask_Ctrl1_ConfigExit:
	.incbin "includes/generated/v7_transplant_BitMask_Ctrl1_ConfigExit.bin"
MidiCC_ChannelDispatch_Ctrl3:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl3.bin"
BitMask_Ctrl3_ConfigExit:
	.incbin "includes/generated/v7_transplant_BitMask_Ctrl3_ConfigExit.bin"
MidiCC_ChannelDispatch_CtrlFlags2:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_CtrlFlags2.bin"
MidiCC_ChannelDispatch_BuildPacket2:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_BuildPacket2.bin"
PanelEvent_NullRet2:
	.incbin "includes/generated/v7_transplant_PanelEvent_NullRet2.bin"
MidiCC_ChannelDispatch_Ctrl0:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_Ctrl0.bin"
BitMask_Ctrl0_ConfigExit:
	.incbin "includes/generated/v7_transplant_BitMask_Ctrl0_ConfigExit.bin"
MidiCC_ChannelDispatch_MultiHandler:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_MultiHandler.bin"
MidiChannel_ConfigureController:
	.incbin "includes/generated/v7_transplant_MidiChannel_ConfigureController.bin"
MidiChanCfg_SetupParams:
	.incbin "includes/generated/v7_transplant_MidiChanCfg_SetupParams.bin"
MidiChannel_ConfigureExit:
	.incbin "includes/generated/v7_transplant_MidiChannel_ConfigureExit.bin"
FileData_ProcessWithLookup:
	.incbin "includes/generated/v7_transplant_FileData_ProcessWithLookup.bin"
MidiCC_ChannelDispatch_DualSend:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelDispatch_DualSend.bin"
MidiCC_DualSend_SetupParams:
	.incbin "includes/generated/v7_transplant_MidiCC_DualSend_SetupParams.bin"
FileData_DispatchExit:
	.incbin "includes/generated/v7_transplant_FileData_DispatchExit.bin"
FileData_ValidateAndDispatch:
	.incbin "includes/generated/v7_transplant_FileData_ValidateAndDispatch.bin"
FileData_DispatchHandler:
	.incbin "includes/generated/v7_transplant_FileData_DispatchHandler.bin"
Periodic_TimestampHelper_Data:
	.incbin "includes/generated/v7_transplant_Periodic_TimestampHelper_Data.bin"
Periodic_TimestampCheck:
	.incbin "includes/generated/v7_transplant_Periodic_TimestampCheck.bin"
Periodic_TimestampCompare:
	.incbin "includes/generated/v7_transplant_Periodic_TimestampCompare.bin"
Periodic_TimestampCompare_Done:
	.incbin "includes/generated/v7_transplant_Periodic_TimestampCompare_Done.bin"
MidiCC_ChannelMappingData:
	.incbin "includes/generated/v7_transplant_MidiCC_ChannelMappingData.bin"
PanelEvt_Handler_4_DualValueCheck:
	.incbin "includes/generated/v7_transplant_PanelEvt_Handler_4_DualValueCheck.bin"
FileData_ValidateFormat:
	.incbin "includes/generated/v7_transplant_FileData_ValidateFormat.bin"
FileData_ValidateFormat_CheckMatch:
	.incbin "includes/generated/v7_transplant_FileData_ValidateFormat_CheckMatch.bin"
FileData_ValidateFormat_Match:
	.incbin "includes/generated/v7_transplant_FileData_ValidateFormat_Match.bin"
FileData_ValidateFormat_Return:
	.incbin "includes/generated/v7_transplant_FileData_ValidateFormat_Return.bin"
FileData_AllocLoadAndParse:
	.incbin "includes/generated/v7_transplant_FileData_AllocLoadAndParse.bin"
FileData_LoadFromSlot:
	.incbin "includes/generated/v7_transplant_FileData_LoadFromSlot.bin"
FileData_LoadFromSlot_Type1or2:
	.incbin "includes/generated/v7_transplant_FileData_LoadFromSlot_Type1or2.bin"
FileData_LoadFromSlot_Type3:
	.incbin "includes/generated/v7_transplant_FileData_LoadFromSlot_Type3.bin"
FileData_LoadFromSlot_UnknownFormat:
	.incbin "includes/generated/v7_transplant_FileData_LoadFromSlot_UnknownFormat.bin"
FileData_LoadFromSlot_Return:
	.incbin "includes/generated/v7_transplant_FileData_LoadFromSlot_Return.bin"
FileData_RawDataBlock:
	.incbin "includes/generated/v7_transplant_FileData_RawDataBlock.bin"
DataBuf_AllocAndLoadFormatted:
	.incbin "includes/generated/v7_transplant_DataBuf_AllocAndLoadFormatted.bin"
DataBuf_AllocAndLoadFormatted_AllocOk:
	.incbin "includes/generated/v7_transplant_DataBuf_AllocAndLoadFormatted_AllocOk.bin"
DataBuf_TransferVoiceParams_Loop:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferVoiceParams_Loop.bin"
DataBuf_TransferEffectParams_Loop:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferEffectParams_Loop.bin"
DataBuf_TransferAuxParams_Loop:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferAuxParams_Loop.bin"
DataBuf_AllocAndLoadFormatted_Return:
	.incbin "includes/generated/v7_transplant_DataBuf_AllocAndLoadFormatted_Return.bin"
DataBuf_CopyVoiceBlock24:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyVoiceBlock24.bin"
DataBuf_CopyEffectBlock12:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyEffectBlock12.bin"
DataBuf_CopyFilterBlock12:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyFilterBlock12.bin"
DataBuf_CopyReverbBlock6:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyReverbBlock6.bin"
DataBuf_CopySimpleBlock4:
	.incbin "includes/generated/v7_transplant_DataBuf_CopySimpleBlock4.bin"
DataBuf_LoadAndDispatchFormat2:
	.incbin "includes/generated/v7_transplant_DataBuf_LoadAndDispatchFormat2.bin"
DataBuf_Format2_Type61_UpdateLoop:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_Type61_UpdateLoop.bin"
DataBuf_Format2_Type61_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_Type61_RestoreSlotId.bin"
DataBuf_Format2_Type63:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_Type63.bin"
DataBuf_Format2_Type63_UpdateLoop:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_Type63_UpdateLoop.bin"
DataBuf_Format2_Type63_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_Type63_RestoreSlotId.bin"
DataBuf_Format2_FormatType2:
	.incbin "includes/generated/v7_transplant_DataBuf_Format2_FormatType2.bin"
DataBuf_FormatType2_Type61_UpdateLoop:
	.incbin "includes/generated/v7_transplant_DataBuf_FormatType2_Type61_UpdateLoop.bin"
DataBuf_FormatType2_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_DataBuf_FormatType2_RestoreSlotId.bin"
DataBuf_StoreSlotId_Return:
	.incbin "includes/generated/v7_transplant_DataBuf_StoreSlotId_Return.bin"
DataBuf_FormatType2_Type63:
	.incbin "includes/generated/v7_transplant_DataBuf_FormatType2_Type63.bin"
DataBuf_FormatType2_Type63_UpdateLoop:
	.incbin "includes/generated/v7_transplant_DataBuf_FormatType2_Type63_UpdateLoop.bin"
DataBuf_FormatType2_Type63_RestoreSlotId:
	.incbin "includes/generated/v7_transplant_DataBuf_FormatType2_Type63_RestoreSlotId.bin"
DataBuf_StoreSlotId63_Return:
	.incbin "includes/generated/v7_transplant_DataBuf_StoreSlotId63_Return.bin"
DataBuf_LoadAndDispatchFormat2_Return:
	.incbin "includes/generated/v7_transplant_DataBuf_LoadAndDispatchFormat2_Return.bin"
DataBuf_CopyEQBlock7:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyEQBlock7.bin"
DataBuf_CopyChorusBlock16:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyChorusBlock16.bin"
DataBuf_CopyCompressorBlock16:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyCompressorBlock16.bin"
DataBuf_CopyDelayBit2:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyDelayBit2.bin"
DataBuf_CopyMixerBlock12:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyMixerBlock12.bin"
DataBuf_CopyBulkBitfields_Nop:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_Nop.bin"
DataBuf_CopyBulkBitfields_Stub:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_Stub.bin"
DataBuf_CopyBulkBitfields_944:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_944.bin"
DataBuf_CopyBulkBitfields_960:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_960.bin"
DataBuf_CopyBulkBitfields_F980:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_F980.bin"
DataBuf_CopyBulkBitfields_Large:
	.incbin "includes/generated/v7_transplant_DataBuf_CopyBulkBitfields_Large.bin"
FileData_LoadAndParseType3:
	.incbin "includes/generated/v7_transplant_FileData_LoadAndParseType3.bin"
FileData_LoadAndParseType3_Continue:
	.incbin "includes/generated/v7_transplant_FileData_LoadAndParseType3_Continue.bin"
FileData_LoadAndParseType3_Error:
	.incbin "includes/generated/v7_transplant_FileData_LoadAndParseType3_Error.bin"
DataBuf_TransferSlot_Epilogue:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferSlot_Epilogue.bin"
VoiceParam_CopyBitfields_TypeA:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeA.bin"
VoiceParam_CopyBitfields_TypeA_NoBit5:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeA_NoBit5.bin"
VoiceParam_CopyBitfields_TypeA_Cont:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeA_Cont.bin"
VoiceParam_CopyBitfields_TypeA_NoHigh:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeA_NoHigh.bin"
VoiceParam_CopyBitfields_TypeA_Final:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeA_Final.bin"
VoiceParam_CopyBitfields_TypeB:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeB.bin"
VoiceParam_CopyBitfields_TypeB_NoBit4:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeB_NoBit4.bin"
VoiceParam_CopyBitfields_TypeB_Cont:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeB_Cont.bin"
VoiceParam_CopyBitfields_TypeC:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_TypeC.bin"
VoiceParam_CopyFields_TypeD:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyFields_TypeD.bin"
VoiceParam_CopyBits_TwoFlags:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBits_TwoFlags.bin"
VoiceParam_CopyFields_TypeE:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyFields_TypeE.bin"
VoiceParam_CopyBitfields_LargeBlock:
	.incbin "includes/generated/v7_transplant_VoiceParam_CopyBitfields_LargeBlock.bin"
DSPCfg_ConfigureVoiceSlotA:
	.incbin "includes/generated/v7_transplant_DSPCfg_ConfigureVoiceSlotA.bin"
DSPCfg_VoiceSlotA_ParamLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotA_ParamLoop.bin"
DSPCfg_VoiceSlotA_RestoreContext:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotA_RestoreContext.bin"
DSPCfg_ConfigureVoiceSlotB:
	.incbin "includes/generated/v7_transplant_DSPCfg_ConfigureVoiceSlotB.bin"
DSPCfg_VoiceSlotB_ParamLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_ParamLoop.bin"
DSPCfg_VoiceSlotB_MapAndWrite:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_MapAndWrite.bin"
DSPCfg_VoiceSlotB_ReadAndWrite:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_ReadAndWrite.bin"
DSPCfg_VoiceSlotB_WriteAndLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_WriteAndLoop.bin"
DSPCfg_VoiceSlotB_RestorePort:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_RestorePort.bin"
DSPCfg_VoiceSlotB_Epilog:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_Epilog.bin"
DSPCfg_VoiceSlotB_ExtractData:
	.incbin "includes/generated/v7_transplant_DSPCfg_VoiceSlotB_ExtractData.bin"
DataBuf_TransferSlotBitfields:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferSlotBitfields.bin"
DataBuf_TransferSlotBitfields_Loop:
	.incbin "includes/generated/v7_transplant_DataBuf_TransferSlotBitfields_Loop.bin"
DataBuf_CheckFormatPair:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckFormatPair.bin"
DataBuf_CheckFormatPair_NotM34:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckFormatPair_NotM34.bin"
DataBuf_CheckFormatPair_NotM36:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckFormatPair_NotM36.bin"
DataBuf_CheckFormatPair_NotN4E:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckFormatPair_NotN4E.bin"
DataBuf_CheckSubFormat:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckSubFormat.bin"
DataBuf_CheckSubFormat_Not6:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckSubFormat_Not6.bin"
DataBuf_CheckSubFormat_Not7:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckSubFormat_Not7.bin"
DataBuf_CheckSubFormat_Not3:
	.incbin "includes/generated/v7_transplant_DataBuf_CheckSubFormat_Not3.bin"
DataBuf_Data_FormatDispatch:
	.incbin "includes/generated/v7_transplant_DataBuf_Data_FormatDispatch.bin"
DataBuf_InitSlotFromPreset:
	.incbin "includes/generated/v7_transplant_DataBuf_InitSlotFromPreset.bin"
DataBuf_InitSlotFromPreset_Alt:
	.incbin "includes/generated/v7_transplant_DataBuf_InitSlotFromPreset_Alt.bin"
SndParam_PopIzRet:
	.incbin "includes/generated/v7_transplant_SndParam_PopIzRet.bin"
SndParam_SaturationClamp:
	.incbin "includes/generated/v7_transplant_SndParam_SaturationClamp.bin"
SndParam_SaturationClamp_Zero:
	.incbin "includes/generated/v7_transplant_SndParam_SaturationClamp_Zero.bin"
SndParam_TableDispatch_Memset:
	.incbin "includes/generated/v7_transplant_SndParam_TableDispatch_Memset.bin"
SndParam_ApplyAndSync:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyAndSync.bin"
SndParam_CheckBit6:
	.incbin "includes/generated/v7_transplant_SndParam_CheckBit6.bin"
SndParam_SetMode2:
	.incbin "includes/generated/v7_transplant_SndParam_SetMode2.bin"
SndParam_ReadAndApply:
	.incbin "includes/generated/v7_transplant_SndParam_ReadAndApply.bin"
SndParam_CheckRangeForDisplay:
	.incbin "includes/generated/v7_transplant_SndParam_CheckRangeForDisplay.bin"
SndParam_CallDisplaySync:
	.incbin "includes/generated/v7_transplant_SndParam_CallDisplaySync.bin"
SndParam_ApplyAllBlocks:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyAllBlocks.bin"
SoundParam_UpdateCleanupRet:
	.incbin "includes/generated/v7_transplant_SoundParam_UpdateCleanupRet.bin"
SndParam_ApplyMaskBlock:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyMaskBlock.bin"
SndParam_ApplyMaskBlock_Loop:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyMaskBlock_Loop.bin"
SndParam_ApplyMaskBlock_Next:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyMaskBlock_Next.bin"
SndParam_ApplyBaseBlock:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyBaseBlock.bin"
SndParam_ApplyBaseBlock_Loop:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyBaseBlock_Loop.bin"
SndParam_ApplyBaseBlock_Next:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyBaseBlock_Next.bin"
SndParam_ApplyModeSpecific:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyModeSpecific.bin"
SndParam_ClearBits:
	.incbin "includes/generated/v7_transplant_SndParam_ClearBits.bin"
SndParam_AllocAndCopyPreset:
	.incbin "includes/generated/v7_transplant_SndParam_AllocAndCopyPreset.bin"
SndParam_CopyPreset_FillLoop:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_FillLoop.bin"
SndParam_CopyPreset_MaskLoop:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_MaskLoop.bin"
SndParam_CopyPreset_SelectBank:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_SelectBank.bin"
SndParam_CopyPreset_Bank1:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_Bank1.bin"
SndParam_CopyPreset_Bank2:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_Bank2.bin"
SndParam_CopyPreset_CallFlash:
	.incbin "includes/generated/v7_transplant_SndParam_CopyPreset_CallFlash.bin"
SoundData_FreeSoundPtr:
	.incbin "includes/generated/v7_transplant_SoundData_FreeSoundPtr.bin"
SndParam_GetBlockPointer:
	.incbin "includes/generated/v7_transplant_SndParam_GetBlockPointer.bin"
SndParam_GetBlockPointer_Extended:
	.incbin "includes/generated/v7_transplant_SndParam_GetBlockPointer_Extended.bin"
SndParam_GetBlockPointer_Bank1:
	.incbin "includes/generated/v7_transplant_SndParam_GetBlockPointer_Bank1.bin"
SndParam_GetBlockPointer_Bank2:
	.incbin "includes/generated/v7_transplant_SndParam_GetBlockPointer_Bank2.bin"
SndParam_GetBlockPointer_Bank3:
	.incbin "includes/generated/v7_transplant_SndParam_GetBlockPointer_Bank3.bin"
SndParam_RelocateAndApply:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateAndApply.bin"
SndParam_RelocateApply_MaskLoop:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateApply_MaskLoop.bin"
SndParam_RelocateApply_NextMask:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateApply_NextMask.bin"
SndParam_RelocateApply_BaseLoop:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateApply_BaseLoop.bin"
SndParam_RelocateApply_NextBase:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateApply_NextBase.bin"
SndParam_RelocateApply_Epilog:
	.incbin "includes/generated/v7_transplant_SndParam_RelocateApply_Epilog.bin"
SndParam_UpdateChannels:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChannels.bin"
SndParam_UpdateAll_Loop:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateAll_Loop.bin"
SndParam_UpdateAll_Body:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateAll_Body.bin"
SndParam_UpdateChannels_Done:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChannels_Done.bin"
SndParam_UpdateSingleChannel:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateSingleChannel.bin"
SndParam_UpdateChan_Mode2:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChan_Mode2.bin"
SndParam_UpdateChan_CallRender:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChan_CallRender.bin"
SndParam_UpdateChan_Mode3:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChan_Mode3.bin"
SndParam_UpdateChan_CopyMemory:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChan_CopyMemory.bin"
MidiSysEx_SendAllParams:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendAllParams.bin"
MidiSysEx_SendParamViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendParamViaCOMM.bin"
MidiSysEx_SendReverbParam:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendReverbParam.bin"
MidiSysEx_SendReverbViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendReverbViaCOMM.bin"
MidiSysEx_SendReverbParam2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendReverbParam2.bin"
MidiSysEx_SendReverb2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendReverb2ViaCOMM.bin"
MidiSysEx_SendReverbFixup:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendReverbFixup.bin"
MidiSysEx_SendProgramChange:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendProgramChange.bin"
MidiSysEx_SendPCRegValue:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendPCRegValue.bin"
MidiSysEx_SendPCViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendPCViaCOMM.bin"
MidiSysEx_SendControlChange1:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendControlChange1.bin"
MidiSysEx_SendCC1RegValue:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendCC1RegValue.bin"
MidiSysEx_SendCC1ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendCC1ViaCOMM.bin"
MidiSysEx_SendControlChange2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendControlChange2.bin"
MidiSysEx_SendCC2RegValue:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendCC2RegValue.bin"
MidiSysEx_SendCC2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendCC2ViaCOMM.bin"
MidiSysEx_CheckDelayAndSend:
	.incbin "includes/generated/v7_transplant_MidiSysEx_CheckDelayAndSend.bin"
MidiSysEx_SendAfterDelay:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendAfterDelay.bin"
MidiSysEx_SendAfterDelayViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendAfterDelayViaCOMM.bin"
MidiSysEx_SendBankData1:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBankData1.bin"
MidiSysEx_SendBank1ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank1ViaCOMM.bin"
MidiSysEx_SendBank1Param2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank1Param2.bin"
MidiSysEx_SendBank1P2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank1P2ViaCOMM.bin"
MidiSysEx_SendBankData2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBankData2.bin"
MidiSysEx_SendBank2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank2ViaCOMM.bin"
MidiSysEx_SendBank2Param2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank2Param2.bin"
MidiSysEx_SendBank2P2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank2P2ViaCOMM.bin"
MidiSysEx_SendBankData3:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBankData3.bin"
MidiSysEx_SendBank3ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank3ViaCOMM.bin"
MidiSysEx_SendBank3Param2:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank3Param2.bin"
MidiSysEx_SendBank3P2ViaCOMM:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendBank3P2ViaCOMM.bin"
MidiSysEx_FreeAndReturn:
	.incbin "includes/generated/v7_transplant_MidiSysEx_FreeAndReturn.bin"
MidiSysEx_PopIzAndReturn:
	.incbin "includes/generated/v7_transplant_MidiSysEx_PopIzAndReturn.bin"
MidiSysEx_SendAllPartChannels:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendAllPartChannels.bin"
MidiSysEx_SendPartChanLoop:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendPartChanLoop.bin"
MidiSysEx_SendPartChan_Done:
	.incbin "includes/generated/v7_transplant_MidiSysEx_SendPartChan_Done.bin"
MidiSysEx_CopyParamToBuffer:
	.incbin "includes/generated/v7_transplant_MidiSysEx_CopyParamToBuffer.bin"
MidiPkt_SendControlPair:
	.incbin "includes/generated/v7_transplant_MidiPkt_SendControlPair.bin"
MidiStream_RefreshDisplay:
	.incbin "includes/generated/v7_transplant_MidiStream_RefreshDisplay.bin"
MidiStream_ApplyPendingCC:
	.incbin "includes/generated/v7_transplant_MidiStream_ApplyPendingCC.bin"
MidiStream_ReplaySavedExpr:
	.incbin "includes/generated/v7_transplant_MidiStream_ReplaySavedExpr.bin"
MidiStream_JumpStubData:
	.incbin "includes/generated/v7_transplant_MidiStream_JumpStubData.bin"
MidiStream_RetStub2:
	.incbin "includes/generated/v7_transplant_MidiStream_RetStub2.bin"
AccWrap_ReturnZero:
	.incbin "includes/generated/v7_transplant_AccWrap_ReturnZero.bin"
MidiStream_RetStub3:
	.incbin "includes/generated/v7_transplant_MidiStream_RetStub3.bin"
MidiStream_PrevBankCheck:
	.incbin "includes/generated/v7_transplant_MidiStream_PrevBankCheck.bin"
SeqAlt_ProcessAndFinalize:
	.incbin "includes/generated/v7_transplant_SeqAlt_ProcessAndFinalize.bin"
SeqBuf_WaitForEmpty:
	.incbin "includes/generated/v7_transplant_SeqBuf_WaitForEmpty.bin"
SeqBuf_WaitLoop:
	.incbin "includes/generated/v7_transplant_SeqBuf_WaitLoop.bin"
SeqBuf_WaitDone:
	.incbin "includes/generated/v7_transplant_SeqBuf_WaitDone.bin"
MidiChan_ParseVoiceData:
	.incbin "includes/generated/v7_transplant_MidiChan_ParseVoiceData.bin"
MidiChan_ReadNextByte:
	.incbin "includes/generated/v7_transplant_MidiChan_ReadNextByte.bin"
MidiChan_SendFieldParam4:
	.incbin "includes/generated/v7_transplant_MidiChan_SendFieldParam4.bin"
MidiChan_CheckSysExData:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckSysExData.bin"
MidiChan_SendFieldParam4_2:
	.incbin "includes/generated/v7_transplant_MidiChan_SendFieldParam4_2.bin"
MidiChan_CheckHighBit:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckHighBit.bin"
MidiChan_AppendAndContinue:
	.incbin "includes/generated/v7_transplant_MidiChan_AppendAndContinue.bin"
MidiChan_SendFieldParam6:
	.incbin "includes/generated/v7_transplant_MidiChan_SendFieldParam6.bin"
MidiChan_CheckSysExEnd:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckSysExEnd.bin"
MidiChan_SendFieldParam3:
	.incbin "includes/generated/v7_transplant_MidiChan_SendFieldParam3.bin"
MidiChan_WriteAndSetFlag:
	.incbin "includes/generated/v7_transplant_MidiChan_WriteAndSetFlag.bin"
MIDI_ProcessChannelPair:
	.incbin "includes/generated/v7_transplant_MIDI_ProcessChannelPair.bin"
MidiChan_CheckSysExFlag:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckSysExFlag.bin"
MidiChan_ParseVoiceDone:
	.incbin "includes/generated/v7_transplant_MidiChan_ParseVoiceDone.bin"
VoiceQueue_Append:
	.incbin "includes/generated/v7_transplant_VoiceQueue_Append.bin"
VoiceQueue_IncrementCount:
	.incbin "includes/generated/v7_transplant_VoiceQueue_IncrementCount.bin"
MidiChan_DequeueVoiceEntry:
	.incbin "includes/generated/v7_transplant_MidiChan_DequeueVoiceEntry.bin"
MidiChan_NibbleLookup_Data:
	.incbin "includes/generated/v7_transplant_MidiChan_NibbleLookup_Data.bin"
MIDI_ReadChannelParam:
	.incbin "includes/generated/v7_transplant_MIDI_ReadChannelParam.bin"
MidiChan_ParamDispatch:
	.incbin "includes/generated/v7_transplant_MidiChan_ParamDispatch.bin"
SeqData_ReadFieldByIndex:
	.incbin "includes/generated/v7_transplant_SeqData_ReadFieldByIndex.bin"
SeqData_FieldDispatch:
	.incbin "includes/generated/v7_transplant_SeqData_FieldDispatch.bin"
SeqData_ReturnZeroField:
	.incbin "includes/generated/v7_transplant_SeqData_ReturnZeroField.bin"
SeqData_InitPlaybackFromField:
	.incbin "includes/generated/v7_transplant_SeqData_InitPlaybackFromField.bin"
MidiSeq_AssignVoiceSlots:
	.incbin "includes/generated/v7_transplant_MidiSeq_AssignVoiceSlots.bin"
MidiSeq_ScanSlot0_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot0_Loop.bin"
MidiSeq_Slot0_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot0_CheckMatch.bin"
MidiSeq_Slot0_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot0_WriteParams.bin"
MidiSeq_Slot0_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot0_StorePtr.bin"
MidiSeq_Slot0_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot0_NextEntry.bin"
MidiSeq_PrepSlot1:
	.incbin "includes/generated/v7_transplant_MidiSeq_PrepSlot1.bin"
MidiSeq_ScanSlot1_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot1_Loop.bin"
MidiSeq_Slot1_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot1_CheckMatch.bin"
MidiSeq_Slot1_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot1_WriteParams.bin"
MidiSeq_Slot1_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot1_StorePtr.bin"
MidiSeq_ScanSlot2_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot2_Loop.bin"
MidiSeq_Slot1_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot1_NextEntry.bin"
MidiSeq_Slot2_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot2_CheckMatch.bin"
MidiSeq_Slot2_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot2_WriteParams.bin"
MidiSeq_Slot2_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot2_StorePtr.bin"
MidiSeq_ScanSlot3_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot3_Loop.bin"
MidiSeq_Slot2_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot2_NextEntry.bin"
MidiSeq_Slot3_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot3_CheckMatch.bin"
MidiSeq_Slot3_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot3_WriteParams.bin"
MidiSeq_Slot3_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot3_StorePtr.bin"
MidiSeq_ScanSlot4_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot4_Loop.bin"
MidiSeq_Slot3_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot3_NextEntry.bin"
MidiSeq_Slot4_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot4_CheckMatch.bin"
MidiSeq_Slot4_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot4_WriteParams.bin"
MidiSeq_Slot4_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot4_StorePtr.bin"
MidiSeq_ScanSlot5_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot5_Loop.bin"
MidiSeq_Slot4_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot4_NextEntry.bin"
MidiSeq_Slot5_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot5_CheckMatch.bin"
MidiSeq_Slot5_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot5_WriteParams.bin"
MidiSeq_Slot5_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot5_StorePtr.bin"
MidiSeq_ScanSlot6_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot6_Loop.bin"
MidiSeq_Slot5_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot5_NextEntry.bin"
MidiSeq_Slot6_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot6_CheckMatch.bin"
MidiSeq_Slot6_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot6_WriteParams.bin"
MidiSeq_Slot6_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot6_StorePtr.bin"
MidiSeq_ScanSlot7_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot7_Loop.bin"
MidiSeq_Slot6_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot6_NextEntry.bin"
MidiSeq_Slot7_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot7_CheckMatch.bin"
MidiSeq_Slot7_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot7_WriteParams.bin"
MidiSeq_Slot7_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot7_StorePtr.bin"
MidiSeq_ScanSlot8_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot8_Loop.bin"
MidiSeq_Slot7_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot7_NextEntry.bin"
MidiSeq_Slot8_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot8_CheckMatch.bin"
MidiSeq_Slot8_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot8_WriteParams.bin"
MidiSeq_Slot8_StorePtr:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot8_StorePtr.bin"
MidiSeq_ScanSlot9_Loop:
	.incbin "includes/generated/v7_transplant_MidiSeq_ScanSlot9_Loop.bin"
MidiSeq_Slot8_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot8_NextEntry.bin"
MidiSeq_Slot9_CheckMatch:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot9_CheckMatch.bin"
MidiSeq_Slot9_WriteParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot9_WriteParams.bin"
MidiSeq_ChannelWriteEpilog:
	.incbin "includes/generated/v7_transplant_MidiSeq_ChannelWriteEpilog.bin"
MidiSeq_RestoreAndReturn:
	.incbin "includes/generated/v7_transplant_MidiSeq_RestoreAndReturn.bin"
MidiSeq_Slot9_NextEntry:
	.incbin "includes/generated/v7_transplant_MidiSeq_Slot9_NextEntry.bin"
MidiSeq_NopRet:
	.incbin "includes/generated/v7_transplant_MidiSeq_NopRet.bin"
MidiSeq_ValidateVoiceRange:
	.incbin "includes/generated/v7_transplant_MidiSeq_ValidateVoiceRange.bin"
MidiSeq_Dequeue3Voices:
	.incbin "includes/generated/v7_transplant_MidiSeq_Dequeue3Voices.bin"
MidiSeq_SetRange3900:
	.incbin "includes/generated/v7_transplant_MidiSeq_SetRange3900.bin"
MidiSeq_SetRange4D800:
	.incbin "includes/generated/v7_transplant_MidiSeq_SetRange4D800.bin"
MidiSeq_CompareRange:
	.incbin "includes/generated/v7_transplant_MidiSeq_CompareRange.bin"
MidiSeq_RangeOverflow:
	.incbin "includes/generated/v7_transplant_MidiSeq_RangeOverflow.bin"
MidiSeq_CheckBitfieldType:
	.incbin "includes/generated/v7_transplant_MidiSeq_CheckBitfieldType.bin"
MidiSeq_ReadBitfield:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReadBitfield.bin"
MidiSeq_WriteParamAndReturn:
	.incbin "includes/generated/v7_transplant_MidiSeq_WriteParamAndReturn.bin"
MidiSeq_PopIzRet:
	.incbin "includes/generated/v7_transplant_MidiSeq_PopIzRet.bin"
MidiSeq_CheckQueuePosition:
	.incbin "includes/generated/v7_transplant_MidiSeq_CheckQueuePosition.bin"
MidiSeq_TrimQueue:
	.incbin "includes/generated/v7_transplant_MidiSeq_TrimQueue.bin"
MidiSeq_TrimLoop:
	.incbin "includes/generated/v7_transplant_MidiSeq_TrimLoop.bin"
MidiSeq_TrimCheckDone:
	.incbin "includes/generated/v7_transplant_MidiSeq_TrimCheckDone.bin"
MidiSeq_PopRetFA:
	.incbin "includes/generated/v7_transplant_MidiSeq_PopRetFA.bin"
MidiSeq_ParseVoiceConfig:
	.incbin "includes/generated/v7_transplant_MidiSeq_ParseVoiceConfig.bin"
SeqData_ParseFieldAndDequeue:
	.incbin "includes/generated/v7_transplant_SeqData_ParseFieldAndDequeue.bin"
MidiSeq_DequeueWriteField15:
	.incbin "includes/generated/v7_transplant_MidiSeq_DequeueWriteField15.bin"
MidiSeq_CountEntriesLoop:
	.incbin "includes/generated/v7_transplant_MidiSeq_CountEntriesLoop.bin"
MidiSeq_NegateAndCheck:
	.incbin "includes/generated/v7_transplant_MidiSeq_NegateAndCheck.bin"
MidiSeq_WriteField4_12:
	.incbin "includes/generated/v7_transplant_MidiSeq_WriteField4_12.bin"
MidiSeq_WriteParamAndExit:
	.incbin "includes/generated/v7_transplant_MidiSeq_WriteParamAndExit.bin"
MidiChan_DequeueExit:
	.incbin "includes/generated/v7_transplant_MidiChan_DequeueExit.bin"
SeqBuf_FlushNoteOffs:
	.incbin "includes/generated/v7_transplant_SeqBuf_FlushNoteOffs.bin"
SeqBuf_FlushLoop:
	.incbin "includes/generated/v7_transplant_SeqBuf_FlushLoop.bin"
SeqBuf_FlushTerminate:
	.incbin "includes/generated/v7_transplant_SeqBuf_FlushTerminate.bin"
ArpQueue_Pack21BitValue:
	.incbin "includes/generated/v7_transplant_ArpQueue_Pack21BitValue.bin"
ArpQueue_Enqueue:
	.incbin "includes/generated/v7_transplant_ArpQueue_Enqueue.bin"
ArpQueue_EnqueueLoop:
	.incbin "includes/generated/v7_transplant_ArpQueue_EnqueueLoop.bin"
ArpQueue_EnqueueDone:
	.incbin "includes/generated/v7_transplant_ArpQueue_EnqueueDone.bin"
ArpQueue_ProcessAndSort_Data:
	.incbin "includes/generated/v7_transplant_ArpQueue_ProcessAndSort_Data.bin"
ArpQueue_ComputeAndEnqueue:
	.incbin "includes/generated/v7_transplant_ArpQueue_ComputeAndEnqueue.bin"
ArpQueue_CountLoop:
	.incbin "includes/generated/v7_transplant_ArpQueue_CountLoop.bin"
ArpQueue_ComputeSize:
	.incbin "includes/generated/v7_transplant_ArpQueue_ComputeSize.bin"
SeqOut_FlushWithChunking:
	.incbin "includes/generated/v7_transplant_SeqOut_FlushWithChunking.bin"
SeqOut_ChunkLoop32:
	.incbin "includes/generated/v7_transplant_SeqOut_ChunkLoop32.bin"
SeqOut_ChunkRemainder:
	.incbin "includes/generated/v7_transplant_SeqOut_ChunkRemainder.bin"
SeqOut_FlushTimedBuffer:
	.incbin "includes/generated/v7_transplant_SeqOut_FlushTimedBuffer.bin"
SeqOut_TimedChunkLoop32:
	.incbin "includes/generated/v7_transplant_SeqOut_TimedChunkLoop32.bin"
SeqOut_TimedChunkRemainder:
	.incbin "includes/generated/v7_transplant_SeqOut_TimedChunkRemainder.bin"
SeqVoice_ReadEntryFields_Data:
	.incbin "includes/generated/v7_transplant_SeqVoice_ReadEntryFields_Data.bin"
SeqVoice_StoreEntry:
	.incbin "includes/generated/v7_transplant_SeqVoice_StoreEntry.bin"
SeqVoice_StoreEntryDone:
	.incbin "includes/generated/v7_transplant_SeqVoice_StoreEntryDone.bin"
SeqVoice_DispatchProcess_Data:
	.incbin "includes/generated/v7_transplant_SeqVoice_DispatchProcess_Data.bin"
MidiChan_CheckFlags:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckFlags.bin"
MidiChan_EnableAndReturn:
	.incbin "includes/generated/v7_transplant_MidiChan_EnableAndReturn.bin"
MidiChan_CheckTimeout:
	.incbin "includes/generated/v7_transplant_MidiChan_CheckTimeout.bin"
MidiChan_ApplyTimeout:
	.incbin "includes/generated/v7_transplant_MidiChan_ApplyTimeout.bin"
MidiChan_TimerDispatch_Data:
	.incbin "includes/generated/v7_transplant_MidiChan_TimerDispatch_Data.bin"
Part_LookupByIndex:
	.incbin "includes/generated/v7_transplant_Part_LookupByIndex.bin"
MIDI_PackNibbleParam:
	.incbin "includes/generated/v7_transplant_MIDI_PackNibbleParam.bin"
MidiTG_WriteRegByDescriptor:
	.incbin "includes/generated/v7_transplant_MidiTG_WriteRegByDescriptor.bin"
MidiTG_WriteReg_NoEntry:
	.incbin "includes/generated/v7_transplant_MidiTG_WriteReg_NoEntry.bin"
MidiTG_WriteReg_Return:
	.incbin "includes/generated/v7_transplant_MidiTG_WriteReg_Return.bin"
AssSwb_ApplyBitDescriptor:
	.incbin "includes/generated/v7_transplant_AssSwb_ApplyBitDescriptor.bin"
AssSwb_NoEntry:
	.incbin "includes/generated/v7_transplant_AssSwb_NoEntry.bin"
AssSwb_Return:
	.incbin "includes/generated/v7_transplant_AssSwb_Return.bin"
AssSwb_ProcessLoop_Data:
	.incbin "includes/generated/v7_transplant_AssSwb_ProcessLoop_Data.bin"
Part_LookupTableEntry:
	.incbin "includes/generated/v7_transplant_Part_LookupTableEntry.bin"
Part_LookupReturnZero:
	.incbin "includes/generated/v7_transplant_Part_LookupReturnZero.bin"
Part_ProcessEntry_Data:
	.incbin "includes/generated/v7_transplant_Part_ProcessEntry_Data.bin"
MidiChan_ClearAllStates:
	.incbin "includes/generated/v7_transplant_MidiChan_ClearAllStates.bin"
MidiChan_SetStateMode:
	.incbin "includes/generated/v7_transplant_MidiChan_SetStateMode.bin"
MidiChan_SetStateMode2:
	.incbin "includes/generated/v7_transplant_MidiChan_SetStateMode2.bin"
MidiChan_CompareAndFlag:
	.incbin "includes/generated/v7_transplant_MidiChan_CompareAndFlag.bin"
MidiChan_SetVoiceBaseState:
	.incbin "includes/generated/v7_transplant_MidiChan_SetVoiceBaseState.bin"
MidiChan_SetBaseState128:
	.incbin "includes/generated/v7_transplant_MidiChan_SetBaseState128.bin"
MidiSeq_UpdateAllParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_UpdateAllParams.bin"
MidiSeq_SyncToneStates_Upper:
	.incbin "includes/generated/v7_transplant_MidiSeq_SyncToneStates_Upper.bin"
MidiSeq_SyncToneStates_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_SyncToneStates_Lower.bin"
MidiSeq_UpdateToneParam:
	.incbin "includes/generated/v7_transplant_MidiSeq_UpdateToneParam.bin"
MidiSeq_UpdateToneParam_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_UpdateToneParam_Lower.bin"
MidiSeq_UpdateVolumeScale:
	.incbin "includes/generated/v7_transplant_MidiSeq_UpdateVolumeScale.bin"
MidiSeq_VolScale_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_VolScale_Lower.bin"
MidiSeq_VolScale_SetActive:
	.incbin "includes/generated/v7_transplant_MidiSeq_VolScale_SetActive.bin"
MidiSeq_ComputeExpression:
	.incbin "includes/generated/v7_transplant_MidiSeq_ComputeExpression.bin"
MidiSeq_Expression_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_Expression_Lower.bin"
MidiSeq_CheckSyncDirty:
	.incbin "includes/generated/v7_transplant_MidiSeq_CheckSyncDirty.bin"
MidiSeq_CheckSyncDirty_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_CheckSyncDirty_Lower.bin"
DSP_Init_ErrorFlagSet:
	.incbin "includes/generated/v7_transplant_DSP_Init_ErrorFlagSet.bin"
MidiSeq_PartLookup_Data:
	.incbin "includes/generated/v7_transplant_MidiSeq_PartLookup_Data.bin"
MidiSeq_ApplyPendingParams:
	.incbin "includes/generated/v7_transplant_MidiSeq_ApplyPendingParams.bin"
MidiSeq_ApplyParams_Lower:
	.incbin "includes/generated/v7_transplant_MidiSeq_ApplyParams_Lower.bin"
MidiSeq_ClearSyncFlag:
	.incbin "includes/generated/v7_transplant_MidiSeq_ClearSyncFlag.bin"
MidiSeq_PartConfigure_Data:
	.incbin "includes/generated/v7_transplant_MidiSeq_PartConfigure_Data.bin"
MidiPkt_ArpMultiPass:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpMultiPass.bin"
MidiPkt_ArpPassLoop:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpPassLoop.bin"
MidiPkt_ArpPassDone:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpPassDone.bin"
MidiPkt_ArpStoreFieldValues:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpStoreFieldValues.bin"
MidiPkt_ArpSecondLoop:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpSecondLoop.bin"
MidiPkt_ArpSecondLoopNext:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpSecondLoopNext.bin"
MidiPkt_ArpPopReturn:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpPopReturn.bin"
MidiPkt_ArpConfigChain_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpConfigChain_Data.bin"
MidiPkt_ArpChordHandler:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpChordHandler.bin"
ArpChord_CheckPlaybackDone:
	.incbin "includes/generated/v7_transplant_ArpChord_CheckPlaybackDone.bin"
ArpChord_ProcessAndDispatch:
	.incbin "includes/generated/v7_transplant_ArpChord_ProcessAndDispatch.bin"
ArpChord_DispatchAndLoop:
	.incbin "includes/generated/v7_transplant_ArpChord_DispatchAndLoop.bin"
ArpChord_FinalizePass:
	.incbin "includes/generated/v7_transplant_ArpChord_FinalizePass.bin"
ArpChord_ClearBitAndReturn:
	.incbin "includes/generated/v7_transplant_ArpChord_ClearBitAndReturn.bin"
MidiTable_DispatchHelper:
	.incbin "includes/generated/v7_transplant_MidiTable_DispatchHelper.bin"
MidiTable_FlushArpNotes:
	.incbin "includes/generated/v7_transplant_MidiTable_FlushArpNotes.bin"
MidiTable_CheckSpecialSlot:
	.incbin "includes/generated/v7_transplant_MidiTable_CheckSpecialSlot.bin"
MidiTable_UseDefaultBuf:
	.incbin "includes/generated/v7_transplant_MidiTable_UseDefaultBuf.bin"
MidiTable_CallFlush:
	.incbin "includes/generated/v7_transplant_MidiTable_CallFlush.bin"
MidiPkt_InitSingleField_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_InitSingleField_Data.bin"
MidiPkt_HandleCmdCode01:
	.incbin "includes/generated/v7_transplant_MidiPkt_HandleCmdCode01.bin"
MidiPkt_SetSlot18:
	.incbin "includes/generated/v7_transplant_MidiPkt_SetSlot18.bin"
MidiPkt_ArpExtHandler_A:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_A.bin"
MidiPkt_ArpExtHandler_B_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_B_Data.bin"
MidiPkt_ArpExtHandler_C_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_C_Data.bin"
MidiPkt_ArpExtHandler_D_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_D_Data.bin"
MidiPkt_ArpExtHandler_E_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_E_Data.bin"
MidiPkt_ArpExtHandler_F_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_F_Data.bin"
MidiPkt_ArpExtHandler_G:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_G.bin"
MidiPkt_ArpExtHandler_H_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_H_Data.bin"
MidiPkt_ArpExtHandler_I_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_I_Data.bin"
MidiPkt_ArpExtHandler_J:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_J.bin"
MidiPkt_ArpExtHandler_K:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_K.bin"
MidiPkt_ArpExtHandler_L:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_L.bin"
MidiPkt_ArpExtHandler_M_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_M_Data.bin"
MidiPkt_RetStub_A:
	.incbin "includes/generated/v7_transplant_MidiPkt_RetStub_A.bin"
MidiPkt_RetStub_B:
	.incbin "includes/generated/v7_transplant_MidiPkt_RetStub_B.bin"
MidiPkt_ArpExtHandler_N_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_ArpExtHandler_N_Data.bin"
SeqChan_ProcessStepCmd:
	.incbin "includes/generated/v7_transplant_SeqChan_ProcessStepCmd.bin"
SeqChan_StepCmd_Field1to2:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field1to2.bin"
SeqChan_StepCmd_Field2to3:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field2to3.bin"
SeqChan_StepCmd_Field4to5:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field4to5.bin"
SeqChan_StepCmd_Field5to6:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field5to6.bin"
SeqChan_StepCmd_Field6_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field6_Data.bin"
SeqChan_StepCmd_Field8to9:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field8to9.bin"
SeqChan_StepCmd_Field9to10:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field9to10.bin"
SeqChan_StepCmd_Field10_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field10_Data.bin"
SeqChan_StepCmd_Field13_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field13_Data.bin"
SeqChan_StepCmd_Field20to21:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field20to21.bin"
SeqChan_StepCmd_Field11_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field11_Data.bin"
SeqChan_StepCmd_Field12_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field12_Data.bin"
SeqChan_StepCmd_Field13Write:
	.incbin "includes/generated/v7_transplant_SeqChan_StepCmd_Field13Write.bin"
SeqChan_RetStub_A:
	.incbin "includes/generated/v7_transplant_SeqChan_RetStub_A.bin"
SeqChan_RetStub_B:
	.incbin "includes/generated/v7_transplant_SeqChan_RetStub_B.bin"
SeqChan_DispatchByType_Data:
	.incbin "includes/generated/v7_transplant_SeqChan_DispatchByType_Data.bin"
SeqChan_DefaultHandler:
	.incbin "includes/generated/v7_transplant_SeqChan_DefaultHandler.bin"
SeqChan_WriteField_Data_A:
	.incbin "includes/generated/v7_transplant_SeqChan_WriteField_Data_A.bin"
SeqChan_WriteField_Data_B:
	.incbin "includes/generated/v7_transplant_SeqChan_WriteField_Data_B.bin"
SeqChan_WriteField_Data_C:
	.incbin "includes/generated/v7_transplant_SeqChan_WriteField_Data_C.bin"
SeqChan_WriteField_Data_D:
	.incbin "includes/generated/v7_transplant_SeqChan_WriteField_Data_D.bin"
SeqChan_RetStub_C:
	.incbin "includes/generated/v7_transplant_SeqChan_RetStub_C.bin"
SeqChan_WriteField_Data_E:
	.incbin "includes/generated/v7_transplant_SeqChan_WriteField_Data_E.bin"
MidiSysEx_ProcessBlock:
	.incbin "includes/generated/v7_transplant_MidiSysEx_ProcessBlock.bin"
SeqAlt_CheckInitBuffer:
	.incbin "includes/generated/v7_transplant_SeqAlt_CheckInitBuffer.bin"
SeqBuf2_InitWithInterrupts:
	.incbin "includes/generated/v7_transplant_SeqBuf2_InitWithInterrupts.bin"
SeqBuf_Timing_Data:
	.incbin "includes/generated/v7_transplant_SeqBuf_Timing_Data.bin"
MidiChan_ClearStorageFields:
	.incbin "includes/generated/v7_transplant_MidiChan_ClearStorageFields.bin"
MidiChan_InitAllBufferPtrs:
	.incbin "includes/generated/v7_transplant_MidiChan_InitAllBufferPtrs.bin"
ArpQueue_InitBuffer:
	.incbin "includes/generated/v7_transplant_ArpQueue_InitBuffer.bin"
MidiSeq_SwapActiveBuffers:
	.incbin "includes/generated/v7_transplant_MidiSeq_SwapActiveBuffers.bin"
MidiSeq_SwapBuffersFallthru:
	.incbin "includes/generated/v7_transplant_MidiSeq_SwapBuffersFallthru.bin"
ArpQueue_SwapBuffers:
	.incbin "includes/generated/v7_transplant_ArpQueue_SwapBuffers.bin"
ArpQueue_SwapFallthru:
	.incbin "includes/generated/v7_transplant_ArpQueue_SwapFallthru.bin"
MidiSeq_ReinitCurrentBuffer:
	.incbin "includes/generated/v7_transplant_MidiSeq_ReinitCurrentBuffer.bin"
ArpQueue_ReinitCurrentBuffer:
	.incbin "includes/generated/v7_transplant_ArpQueue_ReinitCurrentBuffer.bin"
MidiChan_InitSoundRegisters:
	.incbin "includes/generated/v7_transplant_MidiChan_InitSoundRegisters.bin"
SoundMode_ResetAllParams:
	.incbin "includes/generated/v7_transplant_SoundMode_ResetAllParams.bin"
SoundMode_ResetJump:
	.incbin "includes/generated/v7_transplant_SoundMode_ResetJump.bin"
SoundMode_ResetJump2:
	.incbin "includes/generated/v7_transplant_SoundMode_ResetJump2.bin"
SoundMode_RetStub_A:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_A.bin"
SoundMode_RetStub_B:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_B.bin"
SoundMode_RetStub_C:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_C.bin"
SoundMode_RetStub_D:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_D.bin"
SoundMode_ApplyVoiceParams:
	.incbin "includes/generated/v7_transplant_SoundMode_ApplyVoiceParams.bin"
SoundMode_VoiceIterLoop:
	.incbin "includes/generated/v7_transplant_SoundMode_VoiceIterLoop.bin"
SoundMode_RetStub_E:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_E.bin"
SoundMode_RetStub_F:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_F.bin"
SoundMode_RetStub_G:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_G.bin"
SoundMode_RetStub_H:
	.incbin "includes/generated/v7_transplant_SoundMode_RetStub_H.bin"
SoundMode_SysExConfig_Data:
	.incbin "includes/generated/v7_transplant_SoundMode_SysExConfig_Data.bin"
SoundMode_DispatchRender:
	.incbin "includes/generated/v7_transplant_SoundMode_DispatchRender.bin"
SoundMode_DispatchRender_1:
	.incbin "includes/generated/v7_transplant_SoundMode_DispatchRender_1.bin"
SoundMode_DispatchRender_2:
	.incbin "includes/generated/v7_transplant_SoundMode_DispatchRender_2.bin"
SoundMode_PostRender:
	.incbin "includes/generated/v7_transplant_SoundMode_PostRender.bin"
SoundMode_CopyBitmapLoop:
	.incbin "includes/generated/v7_transplant_SoundMode_CopyBitmapLoop.bin"
SoundMode_CopyBitmapDone:
	.incbin "includes/generated/v7_transplant_SoundMode_CopyBitmapDone.bin"
SoundMode_FullRenderUpdate:
	.incbin "includes/generated/v7_transplant_SoundMode_FullRenderUpdate.bin"
SoundMode_RenderWithNotify:
	.incbin "includes/generated/v7_transplant_SoundMode_RenderWithNotify.bin"
SoundMode_NotifyActiveVoices:
	.incbin "includes/generated/v7_transplant_SoundMode_NotifyActiveVoices.bin"
SoundMode_RenderPopRegs:
	.incbin "includes/generated/v7_transplant_SoundMode_RenderPopRegs.bin"
SoundMode_AlternateRender:
	.incbin "includes/generated/v7_transplant_SoundMode_AlternateRender.bin"
MidiCtrl_ModeSwitchHandler:
	.incbin "includes/generated/v7_transplant_MidiCtrl_ModeSwitchHandler.bin"
MidiCtrl_ApplyModeSwitch:
	.incbin "includes/generated/v7_transplant_MidiCtrl_ApplyModeSwitch.bin"
MidiCtrl_CheckAltCommand:
	.incbin "includes/generated/v7_transplant_MidiCtrl_CheckAltCommand.bin"
MidiCtrl_FullReconfigure:
	.incbin "includes/generated/v7_transplant_MidiCtrl_FullReconfigure.bin"
MidiCtrl_DeltaAndProcess:
	.incbin "includes/generated/v7_transplant_MidiCtrl_DeltaAndProcess.bin"
MidiCtrl_RenderAndProcess:
	.incbin "includes/generated/v7_transplant_MidiCtrl_RenderAndProcess.bin"
SoundMode_ProcessToneAndParams:
	.incbin "includes/generated/v7_transplant_SoundMode_ProcessToneAndParams.bin"
TGReg_ClearTerminator:
	.incbin "includes/generated/v7_transplant_TGReg_ClearTerminator.bin"
TGReg_WriteCC0_Volume:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_Volume.bin"
TGReg_WriteCC0_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_Body.bin"
TGReg_WriteCC0_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_Check.bin"
TGReg_WriteCC0_AltMask:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_AltMask.bin"
TGReg_WriteCC0_AltBody:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_AltBody.bin"
TGReg_WriteCC0_AltCheck:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC0_AltCheck.bin"
TGReg_WriteCC3_Expression:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC3_Expression.bin"
TGReg_WriteCC3_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC3_Body.bin"
TGReg_WriteCC3_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC3_Check.bin"
TGReg_WriteCC4_Pan:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_Pan.bin"
TGReg_WriteCC4_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_Body.bin"
TGReg_WriteCC4_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_Check.bin"
TGReg_WriteCC5_Modulation:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC5_Modulation.bin"
TGReg_WriteCC5_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC5_Body.bin"
TGReg_WriteCC5_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC5_Check.bin"
TGReg_WriteCC4_Sustain:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_Sustain.bin"
TGReg_WriteCC4_SustainBody:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_SustainBody.bin"
TGReg_WriteCC4_SustainCheck:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC4_SustainCheck.bin"
TGReg_WriteCC6_RetStub:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC6_RetStub.bin"
TGReg_WriteCC7_Reverb:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC7_Reverb.bin"
TGReg_WriteCC7_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC7_Body.bin"
TGReg_WriteCC7_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC7_Check.bin"
TGReg_WriteCC8_Chorus:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC8_Chorus.bin"
TGReg_WriteCC8_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC8_Body.bin"
TGReg_WriteCC8_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC8_Check.bin"
TGReg_WriteCC9_Variation:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC9_Variation.bin"
TGReg_WriteCC9_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC9_Body.bin"
TGReg_WriteCC9_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC9_Check.bin"
TGReg_WriteCC10_KeyShift:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC10_KeyShift.bin"
TGReg_WriteCC10_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC10_Body.bin"
TGReg_WriteCC10_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC10_Check.bin"
TGReg_WriteCC11_PartMode:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC11_PartMode.bin"
TGReg_WriteCC11_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC11_Body.bin"
TGReg_WriteCC11_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC11_Check.bin"
SoundMode_SetReverbType:
	.incbin "includes/generated/v7_transplant_SoundMode_SetReverbType.bin"
SoundMode_ReverbType1:
	.incbin "includes/generated/v7_transplant_SoundMode_ReverbType1.bin"
SoundMode_ReverbType2:
	.incbin "includes/generated/v7_transplant_SoundMode_ReverbType2.bin"
SoundMode_ReverbType3:
	.incbin "includes/generated/v7_transplant_SoundMode_ReverbType3.bin"
SoundParam_SyncAndReturn:
	.incbin "includes/generated/v7_transplant_SoundParam_SyncAndReturn.bin"
SoundMode_SetChorusType:
	.incbin "includes/generated/v7_transplant_SoundMode_SetChorusType.bin"
SoundMode_ChorusType2:
	.incbin "includes/generated/v7_transplant_SoundMode_ChorusType2.bin"
SoundMode_ChorusType3:
	.incbin "includes/generated/v7_transplant_SoundMode_ChorusType3.bin"
SoundMode_ChorusSyncAndRet:
	.incbin "includes/generated/v7_transplant_SoundMode_ChorusSyncAndRet.bin"
VoiceData_ZeroFillAll:
	.incbin "includes/generated/v7_transplant_VoiceData_ZeroFillAll.bin"
VoiceData_ZeroFillOuter:
	.incbin "includes/generated/v7_transplant_VoiceData_ZeroFillOuter.bin"
VoiceData_ZeroFillInner:
	.incbin "includes/generated/v7_transplant_VoiceData_ZeroFillInner.bin"
VoiceData_ZeroFillNext:
	.incbin "includes/generated/v7_transplant_VoiceData_ZeroFillNext.bin"
SoundParam_ApplyBit15Toggle:
	.incbin "includes/generated/v7_transplant_SoundParam_ApplyBit15Toggle.bin"
SoundParam_Bit15Jump:
	.incbin "includes/generated/v7_transplant_SoundParam_Bit15Jump.bin"
TGReg_WriteCC12_Assign:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC12_Assign.bin"
TGReg_WriteCC12_Body:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC12_Body.bin"
TGReg_WriteCC12_Check:
	.incbin "includes/generated/v7_transplant_TGReg_WriteCC12_Check.bin"
SwbtWr_InitAndWrite_CC_B1:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitAndWrite_CC_B1.bin"
SwbtWr_WriteLoop_CC_B1:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteLoop_CC_B1.bin"
SwbtWr_WriteLoop_CC_B1_Ret:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteLoop_CC_B1_Ret.bin"
SwbtWr_InitAndWrite_CC_B2:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitAndWrite_CC_B2.bin"
SwbtWr_WriteLoop_CC_B2:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteLoop_CC_B2.bin"
SwbtWr_InitAndWriteAllBlocks:
	.incbin "includes/generated/v7_transplant_SwbtWr_InitAndWriteAllBlocks.bin"
SwbtWr_WriteLoop_CC_B3:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteLoop_CC_B3.bin"
SwbtWr_StubRet_A:
	.incbin "includes/generated/v7_transplant_SwbtWr_StubRet_A.bin"
SwbtWr_StubRet_B:
	.incbin "includes/generated/v7_transplant_SwbtWr_StubRet_B.bin"
SwbtWr_StubRet_C:
	.incbin "includes/generated/v7_transplant_SwbtWr_StubRet_C.bin"
SwbtWr_WriteBankSelect:
	.incbin "includes/generated/v7_transplant_SwbtWr_WriteBankSelect.bin"
MidiBuf_CalcFillRange:
	.incbin "includes/generated/v7_transplant_MidiBuf_CalcFillRange.bin"
MidiBuf_FillLoop:
	.incbin "includes/generated/v7_transplant_MidiBuf_FillLoop.bin"
MidiCtrl_ModeSwitch_Data:
	.incbin "includes/generated/v7_transplant_MidiCtrl_ModeSwitch_Data.bin"
MidiCtrl_Bit2ToChannel:
	.incbin "includes/generated/v7_transplant_MidiCtrl_Bit2ToChannel.bin"
MidiCtrl_Bit2ToChannel_Store:
	.incbin "includes/generated/v7_transplant_MidiCtrl_Bit2ToChannel_Store.bin"
MidiCtrl_SendControlPacket:
	.incbin "includes/generated/v7_transplant_MidiCtrl_SendControlPacket.bin"
MidiCtrl_SendPacket_DispatchCall:
	.incbin "includes/generated/v7_transplant_MidiCtrl_SendPacket_DispatchCall.bin"
MidiCtrl_SendPacket_ClearFlag:
	.incbin "includes/generated/v7_transplant_MidiCtrl_SendPacket_ClearFlag.bin"
MidiCtrl_SendPacket_Ret:
	.incbin "includes/generated/v7_transplant_MidiCtrl_SendPacket_Ret.bin"
VoiceData_SyncAllToHardware:
	.incbin "includes/generated/v7_transplant_VoiceData_SyncAllToHardware.bin"
VoiceData_SyncLoop:
	.incbin "includes/generated/v7_transplant_VoiceData_SyncLoop.bin"
VoiceSync_ClearBit5:
	.incbin "includes/generated/v7_transplant_VoiceSync_ClearBit5.bin"
VoiceSync_PopReturn:
	.incbin "includes/generated/v7_transplant_VoiceSync_PopReturn.bin"
SwbtWr_ResetAllChannels:
	.incbin "includes/generated/v7_transplant_SwbtWr_ResetAllChannels.bin"
SysEx_InitiateSend:
	.incbin "includes/generated/v7_transplant_SysEx_InitiateSend.bin"
SysEx_SendDispatch:
	.incbin "includes/generated/v7_transplant_SysEx_SendDispatch.bin"
SysEx_ResetAndReturn:
	.incbin "includes/generated/v7_transplant_SysEx_ResetAndReturn.bin"
SysEx_DispatchCalls_Data:
	.incbin "includes/generated/v7_transplant_SysEx_DispatchCalls_Data.bin"
SysEx_ParseAndDispatch:
	.incbin "includes/generated/v7_transplant_SysEx_ParseAndDispatch.bin"
SysEx_ParserLoop:
	.incbin "includes/generated/v7_transplant_SysEx_ParserLoop.bin"
SysEx_ParseState1_CheckManufID:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState1_CheckManufID.bin"
SysEx_ParseState1_SetState2:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState1_SetState2.bin"
SysEx_ParseState_Reset:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState_Reset.bin"
SysEx_ParseState_DispatchByte:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState_DispatchByte.bin"
SysEx_ParseState2_CheckBit7:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState2_CheckBit7.bin"
SysEx_ParseState_AppendToQueue:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState_AppendToQueue.bin"
SysEx_ParseState2_EndOfSysEx:
	.incbin "includes/generated/v7_transplant_SysEx_ParseState2_EndOfSysEx.bin"
SysEx_ParseAndDispatch_Ret:
	.incbin "includes/generated/v7_transplant_SysEx_ParseAndDispatch_Ret.bin"
SeqData_DispatchHandler:
	.incbin "includes/generated/v7_transplant_SeqData_DispatchHandler.bin"
SeqData_DispatchLoop:
	.incbin "includes/generated/v7_transplant_SeqData_DispatchLoop.bin"
SeqData_DispatchLoop_Body:
	.incbin "includes/generated/v7_transplant_SeqData_DispatchLoop_Body.bin"
SeqData_DispatchLoop_Check:
	.incbin "includes/generated/v7_transplant_SeqData_DispatchLoop_Check.bin"
SeqData_DispatchLoop_Done:
	.incbin "includes/generated/v7_transplant_SeqData_DispatchLoop_Done.bin"
SeqData_FormatOutput:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput.bin"
SeqData_FormatOutput_Loop:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_Loop.bin"
ArpQueue_Flush_Return:
	.incbin "includes/generated/v7_transplant_ArpQueue_Flush_Return.bin"
SeqData_FormatOutput_Dispatch:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_Dispatch.bin"
SeqData_FormatOutput_CaseA:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_CaseA.bin"
SeqData_FormatOutput_CaseB:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_CaseB.bin"
SeqData_FormatOutput_CaseC:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_CaseC.bin"
SeqData_FormatOutput_Default:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_Default.bin"
SeqData_FormatOutput_Data:
	.incbin "includes/generated/v7_transplant_SeqData_FormatOutput_Data.bin"
SeqAlt_NibbleSearch_Ret:
	.incbin "includes/generated/v7_transplant_SeqAlt_NibbleSearch_Ret.bin"
SeqAlt_NibbleSearch:
	.incbin "includes/generated/v7_transplant_SeqAlt_NibbleSearch.bin"
SeqAlt_NibbleSearch_CompareLoop:
	.incbin "includes/generated/v7_transplant_SeqAlt_NibbleSearch_CompareLoop.bin"
SeqAlt_NibbleSearch_DecLoop:
	.incbin "includes/generated/v7_transplant_SeqAlt_NibbleSearch_DecLoop.bin"
SeqAlt_NibbleSearch_NotFound:
	.incbin "includes/generated/v7_transplant_SeqAlt_NibbleSearch_NotFound.bin"
SeqAlt_ApplyDescriptor_TypeA:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescriptor_TypeA.bin"
SeqAlt_ApplyDescA_NoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescA_NoShift.bin"
SeqAlt_ApplyDescA_DirectWrite:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescA_DirectWrite.bin"
SeqAlt_ApplyDescA_DirectNoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescA_DirectNoShift.bin"
SeqAlt_ApplyDescA_FinalCall:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescA_FinalCall.bin"
SeqAlt_PopIzSkip4Ret:
	.incbin "includes/generated/v7_transplant_SeqAlt_PopIzSkip4Ret.bin"
SeqAlt_ApplyDescriptor_TypeB:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescriptor_TypeB.bin"
SeqAlt_ApplyDescB_NoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescB_NoShift.bin"
SeqAlt_ApplyDescB_DirectWrite:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescB_DirectWrite.bin"
SeqAlt_ApplyDescB_DirectNoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescB_DirectNoShift.bin"
SeqAlt_ApplyDescB_FinalCall:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescB_FinalCall.bin"
SeqAlt_PopIzSkip4Ret2:
	.incbin "includes/generated/v7_transplant_SeqAlt_PopIzSkip4Ret2.bin"
SeqAlt_DescriptorBlock_Data:
	.incbin "includes/generated/v7_transplant_SeqAlt_DescriptorBlock_Data.bin"
SeqAlt_ApplyDescriptor_TypeC:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescriptor_TypeC.bin"
SeqAlt_ApplyDescC_NoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescC_NoShift.bin"
SeqAlt_ApplyDescC_Cleanup:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescC_Cleanup.bin"
SeqAlt_ApplyDescriptor_TypeD:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescriptor_TypeD.bin"
SeqAlt_ApplyDescD_NoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescD_NoShift.bin"
SeqAlt_ApplyDescD_Cleanup:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescD_Cleanup.bin"
SeqAlt_StubRet_Pair:
	.incbin "includes/generated/v7_transplant_SeqAlt_StubRet_Pair.bin"
SeqAlt_ApplyDescriptor_WithAssSwb:
	.incbin "includes/generated/v7_transplant_SeqAlt_ApplyDescriptor_WithAssSwb.bin"
SeqAlt_AssSwb_NoShift:
	.incbin "includes/generated/v7_transplant_SeqAlt_AssSwb_NoShift.bin"
SeqAlt_AssSwb_ZeroPath:
	.incbin "includes/generated/v7_transplant_SeqAlt_AssSwb_ZeroPath.bin"
SeqAlt_AssSwb_FinalCall:
	.incbin "includes/generated/v7_transplant_SeqAlt_AssSwb_FinalCall.bin"
SeqAlt_AssSwb_Cleanup:
	.incbin "includes/generated/v7_transplant_SeqAlt_AssSwb_Cleanup.bin"
SeqAlt_DualNibblePack:
	.incbin "includes/generated/v7_transplant_SeqAlt_DualNibblePack.bin"
SeqAlt_DualNibblePack_Dispatch:
	.incbin "includes/generated/v7_transplant_SeqAlt_DualNibblePack_Dispatch.bin"
DSPParam_StoreWithLoop:
	.incbin "includes/generated/v7_transplant_DSPParam_StoreWithLoop.bin"
DSPParam_StoreWithLoop_NoShift:
	.incbin "includes/generated/v7_transplant_DSPParam_StoreWithLoop_NoShift.bin"
VoiceParam_ApplyRangeCheck:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyRangeCheck.bin"
DSP_ParamLoop_Cleanup:
	.incbin "includes/generated/v7_transplant_DSP_ParamLoop_Cleanup.bin"
VoiceParam_ApplyBoundsCheck:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyBoundsCheck.bin"
VoiceParam_ApplyBoundsValidated:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyBoundsValidated.bin"
VoiceParam_ApplyNibbleLookup:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyNibbleLookup.bin"
VoiceParam_ApplyNibble_NoShiftBit:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyNibble_NoShiftBit.bin"
VoiceParam_ApplyCleanupRet:
	.incbin "includes/generated/v7_transplant_VoiceParam_ApplyCleanupRet.bin"
VoiceParam_StoreToBuffer:
	.incbin "includes/generated/v7_transplant_VoiceParam_StoreToBuffer.bin"
VoiceParam_StoreToBuffer_NoShift:
	.incbin "includes/generated/v7_transplant_VoiceParam_StoreToBuffer_NoShift.bin"
VoiceParam_StoreToBuffer_Ret:
	.incbin "includes/generated/v7_transplant_VoiceParam_StoreToBuffer_Ret.bin"
VoiceParam_DirectHardwareWrite:
	.incbin "includes/generated/v7_transplant_VoiceParam_DirectHardwareWrite.bin"
VoiceParam_DirectHW_NoShift:
	.incbin "includes/generated/v7_transplant_VoiceParam_DirectHW_NoShift.bin"
VoiceParam_DirectHW_Ret:
	.incbin "includes/generated/v7_transplant_VoiceParam_DirectHW_Ret.bin"
VoiceParam_MultiModeDispatch:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiModeDispatch.bin"
VoiceParam_MultiMode_Case1:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_Case1.bin"
VoiceParam_MultiMode_Case1_NoShift:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_Case1_NoShift.bin"
VoiceParam_MultiMode_Case2:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_Case2.bin"
VoiceParam_MultiMode_Case2_NoShift:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_Case2_NoShift.bin"
VoiceParam_MultiMode_SetupHW:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_SetupHW.bin"
VoiceParam_MultiMode_Dispatch:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_Dispatch.bin"
VoiceParam_LoopExit:
	.incbin "includes/generated/v7_transplant_VoiceParam_LoopExit.bin"
VoiceParam_MultiMode_StubRet:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiMode_StubRet.bin"
VoiceParam_AssSwb_MultiBlock_Data:
	.incbin "includes/generated/v7_transplant_VoiceParam_AssSwb_MultiBlock_Data.bin"
VoiceParam_MultiBlock_Ret:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiBlock_Ret.bin"
VoiceParam_MultiBlock_Epilogue_Data:
	.incbin "includes/generated/v7_transplant_VoiceParam_MultiBlock_Epilogue_Data.bin"
VoiceParam_LookupAndEnqueue:
	.incbin "includes/generated/v7_fix_voiceparam_lookupandenqueue.bin"
	.include "midi/midipkt_routines.s"
