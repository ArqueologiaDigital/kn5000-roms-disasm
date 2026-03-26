; =============================================================================
; MIDI Packet Routines
; =============================================================================
;
; MIDI packet extraction, packing, and queue management.
; Handles the low-level MIDI message framing between the
; serial I/O layer and the dispatch handlers.
; =============================================================================

MidiPkt_ExtractAndPack:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack.bin"
MidiPkt_ExtractAndPack_StoreShifted:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack_StoreShifted.bin"
MidiPkt_ExtractAndPack_Ret:
	.incbin "includes/generated/v7_transplant_MidiPkt_ExtractAndPack_Ret.bin"
MidiPkt_BuildDirect:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildDirect.bin"
MidiPkt_BuildControl:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildControl.bin"
MidiPkt_BuildStatusDirect:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildStatusDirect.bin"
MidiPkt_BuildFromConstant:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildFromConstant.bin"
MidiPkt_BuildZeroData:
	.incbin "includes/generated/v7_transplant_MidiPkt_BuildZeroData.bin"
MidiPkt_ProcessEventQueue:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue.bin"
MidiPkt_ProcessEventQueue_Loop:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Loop.bin"
MidiPkt_ProcessEventQueue_Next:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Next.bin"
MidiPkt_ProcessEventQueue_Done:
	.incbin "includes/generated/v7_transplant_MidiPkt_ProcessEventQueue_Done.bin"
MidiPkt_Nop:
	.incbin "includes/generated/v7_transplant_MidiPkt_Nop.bin"
MidiPkt_DispatchViaTable_4D6A:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D6A.bin"
MidiPkt_DispatchViaTable_4D82:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D82.bin"
MidiPkt_DispatchViaTable_4D8E:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D8E.bin"
MidiPkt_DispatchViaTable_4D9A:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4D9A.bin"
MidiPkt_DispatchViaTable_4DA6:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DA6.bin"
MidiPkt_DispatchViaTable_4DAE:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DAE.bin"
MidiPkt_DispatchViaTable_4DAE_Done:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DAE_Done.bin"
MidiPkt_DispatchSpecialType:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType.bin"
MidiPkt_DispatchSpecialType_Type10:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Type10.bin"
MidiPkt_DispatchSpecialType_SendAndUpdate:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_SendAndUpdate.bin"
MidiPkt_DispatchSpecialType_Default:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Default.bin"
MidiPkt_DispatchSpecialType_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchSpecialType_Return.bin"
MidiPkt_MatchParamInTable:
	.incbin "includes/generated/v7_transplant_MidiPkt_MatchParamInTable.bin"
MidiPkt_MatchParamInTable_Loop:
	.incbin "includes/generated/v7_transplant_MidiPkt_MatchParamInTable_Loop.bin"
MidiPkt_EnqueueControlNop:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControlNop.bin"
MidiPkt_EnqueueControl_3354:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354.bin"
MidiPkt_EnqueueControl_3354_ShiftBits:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354_ShiftBits.bin"
MidiPkt_EnqueueControl_3354_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3354_Return.bin"
MidiPkt_EnqueueExtended_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueExtended_Data.bin"
MidiPkt_EnqueueControl_335C:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C.bin"
MidiPkt_EnqueueControl_335C_ZeroData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C_ZeroData.bin"
MidiPkt_EnqueueControl_335C_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335C_Return.bin"
MidiPkt_EnqueueControl_3358:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358.bin"
MidiPkt_EnqueueControl_3358_SplitNibbles:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358_SplitNibbles.bin"
MidiPkt_EnqueueControl_3358_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3358_Return.bin"
MidiPkt_EnqueueControl_335E:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E.bin"
MidiPkt_EnqueueControl_335E_SplitNibbles:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E_SplitNibbles.bin"
MidiPkt_EnqueueControl_335E_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_335E_Return.bin"
MidiPkt_EnqueueControl_3364:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364.bin"
MidiPkt_EnqueueControl_3364_NoShift:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_NoShift.bin"
MidiPkt_EnqueueControl_3364_FormatData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_FormatData.bin"
MidiPkt_EnqueueControl_3364_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3364_Return.bin"
MidiPkt_EnqueueControl_3368:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368.bin"
MidiPkt_EnqueueControl_3368_PedalNoShift:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_PedalNoShift.bin"
MidiPkt_EnqueueControl_3368_NoPedal:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_NoPedal.bin"
MidiPkt_EnqueueControl_3368_FormatData:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_FormatData.bin"
MidiPkt_EnqueueControl_3368_Return:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueControl_3368_Return.bin"
MidiPkt_EnqueueExtended2_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_EnqueueExtended2_Data.bin"
MidiPkt_CheckGateCondition:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition.bin"
MidiPkt_CheckGateCondition_Second:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Second.bin"
MidiPkt_CheckGateCondition_Blocked:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Blocked.bin"
MidiPkt_CheckGateCondition_Pass:
	.incbin "includes/generated/v7_transplant_MidiPkt_CheckGateCondition_Pass.bin"
MidiPkt_DispatchViaTable_4DCE:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchViaTable_4DCE.bin"
MidiPkt_DispatchData_Chan4:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan4.bin"
MidiPkt_DispatchData_Chan3:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan3.bin"
MidiPkt_DispatchData_Chan1:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan1.bin"
MidiPkt_DispatchData_Chan2:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan2.bin"
MidiPkt_DispatchData_Chan5:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan5.bin"
MidiPkt_DispatchData_Chan6:
	.incbin "includes/generated/v7_transplant_MidiPkt_DispatchData_Chan6.bin"
MidiPkt_SendBankSelect:
	.incbin "includes/generated/v7_transplant_MidiPkt_SendBankSelect.bin"
MidiPkt_SendBankSelect_Send:
	.incbin "includes/generated/v7_transplant_MidiPkt_SendBankSelect_Send.bin"
MidiPkt_SysExValidator_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_SysExValidator_Data.bin"
MidiPkt_SysExProcessor_Data:
	.incbin "includes/generated/v7_transplant_MidiPkt_SysExProcessor_Data.bin"
MidiPkt_SysExBulkTransfer_Data:
	.incbin "includes/generated/v7_block_midipkt_sysexbulktransfer_data.bin"
