; =============================================================================
; Note & Voice Mapping (26K lines)
; =============================================================================
;
; Note-on processing, polyphonic voice allocation and stealing,
; NoteMap dispatch (91 functions), sequence playback support, MIDI
; output formatting, sound parameter management, and utility routines.
; One of the largest files in the ROM.
; =============================================================================

NoteOn_EntryPoint:
	.incbin "includes/generated/v7_transplant_NoteOn_EntryPoint.bin"
NoteOn_DispatchByStatus:
	.incbin "includes/generated/v7_transplant_NoteOn_DispatchByStatus.bin"
NoteOn_ChannelScanLoop_NoteOn:
	.incbin "includes/generated/v7_transplant_NoteOn_ChannelScanLoop_NoteOn.bin"
NoteOn_AutoPlayVoiceLoop:
	.incbin "includes/generated/v7_transplant_NoteOn_AutoPlayVoiceLoop.bin"
NoteOn_AutoPlayNext:
	.incbin "includes/generated/v7_transplant_NoteOn_AutoPlayNext.bin"
NoteOn_AutoPlayCheckCount:
	.incbin "includes/generated/v7_transplant_NoteOn_AutoPlayCheckCount.bin"
NoteOn_VoiceLookupAndAssign:
	.incbin "includes/generated/v7_transplant_NoteOn_VoiceLookupAndAssign.bin"
NoteOn_MergeLayer1:
	.incbin "includes/generated/v7_transplant_NoteOn_MergeLayer1.bin"
NoteOn_MergeLayer2:
	.incbin "includes/generated/v7_transplant_NoteOn_MergeLayer2.bin"
NoteOn_MergeLayer3:
	.incbin "includes/generated/v7_transplant_NoteOn_MergeLayer3.bin"
NoteOn_CheckSpecialChannel:
	.incbin "includes/generated/v7_transplant_NoteOn_CheckSpecialChannel.bin"
NoteOn_SpecialChannelUpdate:
	.incbin "includes/generated/v7_transplant_NoteOn_SpecialChannelUpdate.bin"
NoteOn_CheckLayer3Only:
	.incbin "includes/generated/v7_transplant_NoteOn_CheckLayer3Only.bin"
NoteOn_UpdateByChannelType:
	.incbin "includes/generated/v7_transplant_NoteOn_UpdateByChannelType.bin"
NoteOn_PostAutoPlay:
	.incbin "includes/generated/v7_transplant_NoteOn_PostAutoPlay.bin"
NoteOn_AdvanceChannel:
	.incbin "includes/generated/v7_transplant_NoteOn_AdvanceChannel.bin"
NoteOn_ChannelScanLoop_CC:
	.incbin "includes/generated/v7_transplant_NoteOn_ChannelScanLoop_CC.bin"
NoteOn_ChannelScanCC_Body:
	.incbin "includes/generated/v7_transplant_NoteOn_ChannelScanCC_Body.bin"
NoteOn_CC_VoiceLookupAndAssign:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_VoiceLookupAndAssign.bin"
NoteOn_CC_MergeLayer1:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_MergeLayer1.bin"
NoteOn_CC_MergeLayer2:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_MergeLayer2.bin"
NoteOn_CC_MergeLayer3:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_MergeLayer3.bin"
NoteOn_CC_CheckSpecialChannel:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_CheckSpecialChannel.bin"
NoteOn_CC_SpecialUpdate:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_SpecialUpdate.bin"
NoteOn_CC_CheckLayer3Only:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_CheckLayer3Only.bin"
NoteOn_CC_UpdateByChannelType:
	.incbin "includes/generated/v7_transplant_NoteOn_CC_UpdateByChannelType.bin"
NoteOnProcess_NextChannel:
	.incbin "includes/generated/v7_transplant_NoteOnProcess_NextChannel.bin"
NoteOnProcess_StoreAndAllocate:
	.incbin "includes/generated/v7_transplant_NoteOnProcess_StoreAndAllocate.bin"
NoteOn_Epilogue:
	.incbin "includes/generated/v7_transplant_NoteOn_Epilogue.bin"
AccNoteOn_ProcessVoiceSetup:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ProcessVoiceSetup.bin"
AccNoteOn_AssignVoices:
	.incbin "includes/generated/v7_transplant_AccNoteOn_AssignVoices.bin"
AccNoteOn_AutoPlayLoop:
	.incbin "includes/generated/v7_transplant_AccNoteOn_AutoPlayLoop.bin"
AccNoteOn_AutoPlayNext:
	.incbin "includes/generated/v7_transplant_AccNoteOn_AutoPlayNext.bin"
AccNoteOn_AutoPlayCheck:
	.incbin "includes/generated/v7_transplant_AccNoteOn_AutoPlayCheck.bin"
AccNoteOn_FindMinVelocity_Loop:
	.incbin "includes/generated/v7_transplant_AccNoteOn_FindMinVelocity_Loop.bin"
AccNoteOn_UseEntryVelocity:
	.incbin "includes/generated/v7_transplant_AccNoteOn_UseEntryVelocity.bin"
AccNoteOn_StoreMinVelocity:
	.incbin "includes/generated/v7_transplant_AccNoteOn_StoreMinVelocity.bin"
AccNoteOn_MinVelocity_Next:
	.incbin "includes/generated/v7_transplant_AccNoteOn_MinVelocity_Next.bin"
AccNoteOn_MinVelocity_Check:
	.incbin "includes/generated/v7_transplant_AccNoteOn_MinVelocity_Check.bin"
AccNoteOn_EmitVoiceLoop_Init:
	.incbin "includes/generated/v7_transplant_AccNoteOn_EmitVoiceLoop_Init.bin"
AccNoteOn_EmitVoiceLoop_Body:
	.incbin "includes/generated/v7_transplant_AccNoteOn_EmitVoiceLoop_Body.bin"
AccNoteOn_EmitVoiceLoop_Check:
	.incbin "includes/generated/v7_transplant_AccNoteOn_EmitVoiceLoop_Check.bin"
AccNoteOn_MergeLayer1:
	.incbin "includes/generated/v7_transplant_AccNoteOn_MergeLayer1.bin"
AccNoteOn_MergeLayer2:
	.incbin "includes/generated/v7_transplant_AccNoteOn_MergeLayer2.bin"
AccNoteOn_MergeLayer3:
	.incbin "includes/generated/v7_transplant_AccNoteOn_MergeLayer3.bin"
AccNoteOn_CheckSpecialChannel:
	.incbin "includes/generated/v7_transplant_AccNoteOn_CheckSpecialChannel.bin"
AccNoteOn_SpecialMergeAndAdd:
	.incbin "includes/generated/v7_transplant_AccNoteOn_SpecialMergeAndAdd.bin"
AccNoteOn_SpecialDirectAdd:
	.incbin "includes/generated/v7_transplant_AccNoteOn_SpecialDirectAdd.bin"
AccNoteOn_CheckLayer3Only:
	.incbin "includes/generated/v7_transplant_AccNoteOn_CheckLayer3Only.bin"
AccNoteOn_UpdateByChannelType:
	.incbin "includes/generated/v7_transplant_AccNoteOn_UpdateByChannelType.bin"
AccNoteOn_FinalizeAndAutoPlay:
	.incbin "includes/generated/v7_transplant_AccNoteOn_FinalizeAndAutoPlay.bin"
AccNoteOn_Return:
	.incbin "includes/generated/v7_transplant_AccNoteOn_Return.bin"
AccNoteOn_ChannelDispatch:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ChannelDispatch.bin"
AccMidi_DispatchLoop:
	.incbin "includes/generated/v7_transplant_AccMidi_DispatchLoop.bin"
AccNoteOn_ChannelLoop_Body:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ChannelLoop_Body.bin"
AccNoteOn_ChannelLoop_Remap98:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ChannelLoop_Remap98.bin"
AccNoteOn_ChannelLoop_Next:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ChannelLoop_Next.bin"
AccNoteOn_ChannelLoop_Check:
	.incbin "includes/generated/v7_transplant_AccNoteOn_ChannelLoop_Check.bin"
AccMidi_ReadNextEvent:
	.incbin "includes/generated/v7_transplant_AccMidi_ReadNextEvent.bin"
AccMidi_Return:
	.incbin "includes/generated/v7_transplant_AccMidi_Return.bin"
RhythmMidi_Dispatcher:
	.incbin "includes/generated/v7_transplant_RhythmMidi_Dispatcher.bin"
RhythmMidi_DispatchByStatus:
	.incbin "includes/generated/v7_transplant_RhythmMidi_DispatchByStatus.bin"
RhythmMidi_NoteOn_Remap98:
	.incbin "includes/generated/v7_transplant_RhythmMidi_NoteOn_Remap98.bin"
RhythmMidi_HandleCC:
	.incbin "includes/generated/v7_transplant_RhythmMidi_HandleCC.bin"
RhythmMidi_CC7F_PartLoop:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC7F_PartLoop.bin"
RhythmMidi_CC7E:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC7E.bin"
RhythmMidi_CC7D:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC7D.bin"
RhythmMidi_CC7D_PartLoop:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC7D_PartLoop.bin"
RhythmMidi_CC7D_PartNext:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC7D_PartNext.bin"
RhythmMidi_CC_Default:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_Default.bin"
RhythmMidi_CC_Standard:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_Standard.bin"
RhythmMidi_CC_UpdateOutput:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_UpdateOutput.bin"
RhythmMidi_CC_PostProcess:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_PostProcess.bin"
RhythmMidi_CC_PostLoop:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_PostLoop.bin"
RhythmMidi_CC_PostNext:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_PostNext.bin"
RhythmMidi_CC_Return:
	.incbin "includes/generated/v7_transplant_RhythmMidi_CC_Return.bin"
RhythmMidi_SeqEvt:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt.bin"
RhythmMidi_SeqEvt_Dispatch:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_Dispatch.bin"
RhythmMidi_SeqEvt_CC:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC.bin"
RhythmMidi_SeqEvt_CC7F_Loop:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC7F_Loop.bin"
RhythmMidi_SeqEvt_CC7F_Next:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC7F_Next.bin"
RhythmMidi_SeqEvt_CC7E:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC7E.bin"
RhythmMidi_SeqEvt_CC7E_Loop:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC7E_Loop.bin"
RhythmMidi_SeqEvt_CC7E_Next:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC7E_Next.bin"
RhythmMidi_SeqEvt_CC_Default:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_CC_Default.bin"
RhythmMidi_SeqEvt_ReadNext:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_ReadNext.bin"
RhythmMidi_SeqEvt_Return:
	.incbin "includes/generated/v7_transplant_RhythmMidi_SeqEvt_Return.bin"
Voice_InitializeAll:
	.incbin "includes/generated/v7_transplant_Voice_InitializeAll.bin"
VoiceInit_PartLoop:
	.incbin "includes/generated/v7_transplant_VoiceInit_PartLoop.bin"
VoiceInit_ChannelLoop:
	.incbin "includes/generated/v7_transplant_VoiceInit_ChannelLoop.bin"
VoiceInit_LookupTableAndAssign:
	.incbin "includes/generated/v7_transplant_VoiceInit_LookupTableAndAssign.bin"
VoiceInit_MergeLayer1:
	.incbin "includes/generated/v7_transplant_VoiceInit_MergeLayer1.bin"
VoiceInit_MergeLayer2:
	.incbin "includes/generated/v7_transplant_VoiceInit_MergeLayer2.bin"
VoiceInit_MergeLayer3:
	.incbin "includes/generated/v7_transplant_VoiceInit_MergeLayer3.bin"
VoiceInit_CheckSpecialChannel:
	.incbin "includes/generated/v7_transplant_VoiceInit_CheckSpecialChannel.bin"
VoiceInit_SpecialChannelUpdate:
	.incbin "includes/generated/v7_transplant_VoiceInit_SpecialChannelUpdate.bin"
VoiceInit_CheckLayer3Only:
	.incbin "includes/generated/v7_transplant_VoiceInit_CheckLayer3Only.bin"
VoiceInit_UpdateByChannelType:
	.incbin "includes/generated/v7_transplant_VoiceInit_UpdateByChannelType.bin"
VoiceProcess_NextChannel:
	.incbin "includes/generated/v7_transplant_VoiceProcess_NextChannel.bin"
VoiceInit_ChannelNext:
	.incbin "includes/generated/v7_transplant_VoiceInit_ChannelNext.bin"
VoiceInit_Epilogue:
	.incbin "includes/generated/v7_transplant_VoiceInit_Epilogue.bin"
NoteMap_ProcessAndMerge:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessAndMerge.bin"
NoteMap_ProcessMerge_Layer1:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMerge_Layer1.bin"
NoteMap_ProcessMerge_Layer2:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMerge_Layer2.bin"
NoteMap_ProcessMerge_Layer3:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMerge_Layer3.bin"
NoteMap_ProcessMerge_SpecialPath:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMerge_SpecialPath.bin"
NoteMap_ProcessMerge_UpdateChannel:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMerge_UpdateChannel.bin"
NoteMap_AddEntry_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_AddEntry_Return.bin"
NoteMap_SendAllNotesOff:
	.incbin "includes/generated/v7_transplant_NoteMap_SendAllNotesOff.bin"
NoteOff_PartLoop_Body:
	.incbin "includes/generated/v7_transplant_NoteOff_PartLoop_Body.bin"
NoteOff_PartLoop_Layer3:
	.incbin "includes/generated/v7_transplant_NoteOff_PartLoop_Layer3.bin"
NoteOff_PartLoop_Next:
	.incbin "includes/generated/v7_transplant_NoteOff_PartLoop_Next.bin"
NoteOff_Return:
	.incbin "includes/generated/v7_transplant_NoteOff_Return.bin"
Voice_InitTableGroup:
	.incbin "includes/generated/v7_transplant_Voice_InitTableGroup.bin"
VoiceTableGroup_PartLoop:
	.incbin "includes/generated/v7_transplant_VoiceTableGroup_PartLoop.bin"
VoiceTableGroup_Return:
	.incbin "includes/generated/v7_transplant_VoiceTableGroup_Return.bin"
Voice_InitTablePair:
	.incbin "includes/generated/v7_transplant_Voice_InitTablePair.bin"
VoiceTablePair_PartLoop:
	.incbin "includes/generated/v7_transplant_VoiceTablePair_PartLoop.bin"
VoiceTablePair_Return:
	.incbin "includes/generated/v7_transplant_VoiceTablePair_Return.bin"
VoiceEvent_ResetAndInit:
	.incbin "includes/generated/v7_transplant_VoiceEvent_ResetAndInit.bin"
VoiceEvent_AllocAllLayers:
	.incbin "includes/generated/v7_transplant_VoiceEvent_AllocAllLayers.bin"
VoiceEvent_AllocTwoLayers:
	.incbin "includes/generated/v7_transplant_VoiceEvent_AllocTwoLayers.bin"
VoiceEvent_DispatchTable:
	.incbin "includes/generated/v7_transplant_VoiceEvent_DispatchTable.bin"
VoiceEvent_TableSeparator:
	.incbin "includes/generated/v7_transplant_VoiceEvent_TableSeparator.bin"
VoiceEvent_HandlerTable:
	.incbin "includes/generated/v7_transplant_VoiceEvent_HandlerTable.bin"
VoiceEvent_TypeDispatch:
	.incbin "includes/generated/v7_transplant_VoiceEvent_TypeDispatch.bin"
VoiceEvent_Dispatch:
	.incbin "includes/generated/v7_transplant_VoiceEvent_Dispatch.bin"
VoiceEvtHandler_Type1:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type1.bin"
VoiceEvtHandler_Type2:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type2.bin"
VoiceEvtHandler_Type3:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type3.bin"
VoiceEvtHandler_Type4:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type4.bin"
VoiceEvtHandler_Type5:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type5.bin"
VoiceEvtHandler_Type6:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type6.bin"
VoiceEvtHandler_Type7:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type7.bin"
VoiceEvtHandler_Type8:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type8.bin"
VoiceEvtHandler_Type9:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type9.bin"
VoiceEvtHandler_Type10:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type10.bin"
VoiceEvtHandler_Type11:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type11.bin"
VoiceEvtHandler_Type12:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Type12.bin"
AudioInit_FlushQueue_LoopNext:
	.incbin "includes/generated/v7_transplant_AudioInit_FlushQueue_LoopNext.bin"
VoiceEvtHandler_Done:
	.incbin "includes/generated/v7_transplant_VoiceEvtHandler_Done.bin"
VoiceEvent_FlushAndReturn:
	.incbin "includes/generated/v7_transplant_VoiceEvent_FlushAndReturn.bin"
VoiceClaim_Slot0_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot0_MarkLoop.bin"
VoiceClaim_Slot0_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot0_MarkCheck.bin"
VoiceClaim_Slot0_Alt:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot0_Alt.bin"
VoiceClaim_Slot0_Alt_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot0_Alt_MarkLoop.bin"
VoiceClaim_Slot0_Alt_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot0_Alt_MarkCheck.bin"
VoiceClaim_Slot1_Init:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot1_Init.bin"
VoiceClaim_Slot1_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot1_MarkLoop.bin"
VoiceClaim_Slot1_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot1_MarkCheck.bin"
VoiceClaim_Slot2_Init:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot2_Init.bin"
VoiceClaim_Slot2_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot2_MarkLoop.bin"
VoiceClaim_Slot2_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot2_MarkCheck.bin"
VoiceClaim_Slot3_Init:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot3_Init.bin"
VoiceClaim_Slot3_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot3_MarkLoop.bin"
VoiceClaim_Slot3_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot3_MarkCheck.bin"
VoiceClaim_Slot6_Init:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot6_Init.bin"
VoiceClaim_Slot6_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot6_MarkLoop.bin"
VoiceClaim_Slot6_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Slot6_MarkCheck.bin"
VoiceClaim_Extended_Init:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Extended_Init.bin"
VoiceClaimExt_Slot1_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot1_MarkLoop.bin"
VoiceClaimExt_Slot1_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot1_MarkCheck.bin"
VoiceClaimExt_Slot2_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot2_MarkLoop.bin"
VoiceClaimExt_Slot2_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot2_MarkCheck.bin"
VoiceClaimExt_Slot2_SetParam:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot2_SetParam.bin"
VoiceClaimExt_Slot3_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot3_MarkLoop.bin"
VoiceClaimExt_Slot3_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot3_MarkCheck.bin"
VoiceClaimExt_Slot3_SetParam:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot3_SetParam.bin"
VoiceClaimExt_Slot6_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot6_MarkLoop.bin"
VoiceClaimExt_Slot6_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt_Slot6_MarkCheck.bin"
VoiceClaim_Extended_Return:
	.incbin "includes/generated/v7_transplant_VoiceClaim_Extended_Return.bin"
VoiceClaimExt2_Slot1_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot1_MarkLoop.bin"
VoiceClaimExt2_Slot1_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot1_MarkCheck.bin"
VoiceClaimExt2_Slot2_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot2_MarkLoop.bin"
VoiceClaimExt2_Slot2_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot2_MarkCheck.bin"
VoiceClaimExt2_Slot2_SetParam:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot2_SetParam.bin"
VoiceClaimExt2_Slot3_MarkLoop:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_MarkLoop.bin"
VoiceClaimExt2_Slot3_MarkCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_MarkCheck.bin"
VoiceClaimExt2_Slot3_WriteReg:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_WriteReg.bin"
VoiceClaimExt2_Slot3_LoopBody:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopBody.bin"
VoiceClaimExt2_Slot3_LoopCheck:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopCheck.bin"
VoiceClaimExt2_Slot3_LoopBody2:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopBody2.bin"
VoiceClaimExt2_Slot3_LoopCheck2:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopCheck2.bin"
VoiceClaimExt2_Slot3_WriteReg2:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_WriteReg2.bin"
VoiceClaimExt2_Slot3_LoopBody3:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopBody3.bin"
VoiceClaimExt2_Slot3_LoopCheck3:
	.incbin "includes/generated/v7_transplant_VoiceClaimExt2_Slot3_LoopCheck3.bin"
Audio_StoreParamAndReturn:
	.incbin "includes/generated/v7_transplant_Audio_StoreParamAndReturn.bin"
MidiEvent_ConfigChannel:
	.incbin "includes/generated/v7_transplant_MidiEvent_ConfigChannel.bin"
MidiConfig_Slot6Path:
	.incbin "includes/generated/v7_transplant_MidiConfig_Slot6Path.bin"
MidiConfig_Return:
	.incbin "includes/generated/v7_transplant_MidiConfig_Return.bin"
Voice_FindAndAllocBestMatch:
	.incbin "includes/generated/v7_transplant_Voice_FindAndAllocBestMatch.bin"
Voice_InitSlotData:
	.incbin "includes/generated/v7_transplant_Voice_InitSlotData.bin"
VoiceSlotInit_Loop:
	.incbin "includes/generated/v7_transplant_VoiceSlotInit_Loop.bin"
VoiceSlotInit_Check:
	.incbin "includes/generated/v7_transplant_VoiceSlotInit_Check.bin"
NoteMap_AssignAllVoiceLinks:
	.incbin "includes/generated/v7_transplant_NoteMap_AssignAllVoiceLinks.bin"
VoiceLinks_SlotLoop:
	.incbin "includes/generated/v7_transplant_VoiceLinks_SlotLoop.bin"
VoiceLinks_SkipEmpty:
	.incbin "includes/generated/v7_transplant_VoiceLinks_SkipEmpty.bin"
VoiceLinks_SkipEmpty_LoadIter:
	.incbin "includes/generated/v7_transplant_VoiceLinks_SkipEmpty_LoadIter.bin"
MidiEvent_NoteLoopAdvance:
	.incbin "includes/generated/v7_transplant_MidiEvent_NoteLoopAdvance.bin"
VoiceLinks_CheckCount:
	.incbin "includes/generated/v7_transplant_VoiceLinks_CheckCount.bin"
MidiEvent_ParseNoteSequence:
	.incbin "includes/generated/v7_transplant_MidiEvent_ParseNoteSequence.bin"
ParseNoteSequence_ReadBuf:
	.incbin "includes/generated/v7_transplant_ParseNoteSequence_ReadBuf.bin"
ParseNoteSequence_ReadBuf2:
	.incbin "includes/generated/v7_transplant_ParseNoteSequence_ReadBuf2.bin"
ParseNoteSequence_Compare:
	.incbin "includes/generated/v7_transplant_ParseNoteSequence_Compare.bin"
ParseNoteSequence_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_ParseNoteSequence_AdvanceSlot.bin"
MidiEvent_NoteSeqCount:
	.incbin "includes/generated/v7_transplant_MidiEvent_NoteSeqCount.bin"
NoteSeqCount_ProcMerge:
	.incbin "includes/generated/v7_transplant_NoteSeqCount_ProcMerge.bin"
NoteSeqCount_Epilogue:
	.incbin "includes/generated/v7_transplant_NoteSeqCount_Epilogue.bin"
MidiEvent_ProcessNoteEntry:
	.incbin "includes/generated/v7_transplant_MidiEvent_ProcessNoteEntry.bin"
ProcessNoteEntry_CheckEnd:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_CheckEnd.bin"
ProcessNoteEntry_ReadBuf:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_ReadBuf.bin"
ProcessNoteEntry_ReadBuf2:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_ReadBuf2.bin"
ProcessNoteEntry_ReadBuf3:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_ReadBuf3.bin"
ProcessNoteEntry_Compare:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_Compare.bin"
ProcessNoteEntry_CheckDRAM:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_CheckDRAM.bin"
ProcessNoteEntry_LoadDRAM:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_LoadDRAM.bin"
ProcessNoteEntry_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_LoadDRAM2.bin"
ProcessNoteEntry_LoadDRAM3:
	.incbin "includes/generated/v7_transplant_ProcessNoteEntry_LoadDRAM3.bin"
MidiEvent_ProcessCC_Continue:
	.incbin "includes/generated/v7_transplant_MidiEvent_ProcessCC_Continue.bin"
ProcessCC_Continue_CheckEnd:
	.incbin "includes/generated/v7_transplant_ProcessCC_Continue_CheckEnd.bin"
MidiEvent_ClampAndStoreParam:
	.incbin "includes/generated/v7_transplant_MidiEvent_ClampAndStoreParam.bin"
ClampAndStoreParam_LoadReg:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadReg.bin"
ClampAndStoreParam_CheckZero:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_CheckZero.bin"
ClampAndStoreParam_LoadParam:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadParam.bin"
ClampAndStoreParam_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_AdvanceSlot.bin"
ClampAndStoreParam_LoadParam2:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadParam2.bin"
ClampAndStoreParam_LoadParam3:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadParam3.bin"
ClampAndStoreParam_AdvanceSlot2:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_AdvanceSlot2.bin"
ClampAndStoreParam_LoadReg2:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadReg2.bin"
ClampAndStoreParam_LoadReg3:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_LoadReg3.bin"
ClampAndStoreParam_DoInit:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_DoInit.bin"
ClampAndStoreParam_Epilogue:
	.incbin "includes/generated/v7_transplant_ClampAndStoreParam_Epilogue.bin"
MidiEvent_ReadAndParseLoop:
	.incbin "includes/generated/v7_transplant_MidiEvent_ReadAndParseLoop.bin"
ReadAndParseLoop_LoadParam:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam.bin"
ReadAndParseLoop_LoadParam2:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam2.bin"
ReadAndParseLoop_LoadParam3:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam3.bin"
ReadAndParseLoop_ReadAlt:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_ReadAlt.bin"
ReadAndParseLoop_ReadAlt2:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_ReadAlt2.bin"
ReadAndParseLoop_ReadAlt3:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_ReadAlt3.bin"
ReadAndParseLoop_ReadAlt4:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_ReadAlt4.bin"
ReadAndParseLoop_ReadAlt5:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_ReadAlt5.bin"
ReadAndParseLoop_LoadParam4:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam4.bin"
ReadAndParseLoop_LoadParam5:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam5.bin"
ReadAndParseLoop_LoadParam6:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam6.bin"
ReadAndParseLoop_LoadParam7:
	.incbin "includes/generated/v7_transplant_ReadAndParseLoop_LoadParam7.bin"
NoteMap_FinalizeCount:
	.incbin "includes/generated/v7_transplant_NoteMap_FinalizeCount.bin"
FinalizeCount_LoadIdx:
	.incbin "includes/generated/v7_transplant_FinalizeCount_LoadIdx.bin"
FinalizeCount_CheckZero:
	.incbin "includes/generated/v7_transplant_FinalizeCount_CheckZero.bin"
FinalizeCount_LoadParam:
	.incbin "includes/generated/v7_transplant_FinalizeCount_LoadParam.bin"
FinalizeCount_LoadParam2:
	.incbin "includes/generated/v7_transplant_FinalizeCount_LoadParam2.bin"
FinalizeCount_LoadReg:
	.incbin "includes/generated/v7_transplant_FinalizeCount_LoadReg.bin"
FinalizeCount_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_FinalizeCount_AdvanceSlot.bin"
Voice_BuildProgramNotify:
	.incbin "includes/generated/v7_transplant_Voice_BuildProgramNotify.bin"
VoiceNotify_SendAllNotesOff:
	.incbin "includes/generated/v7_transplant_VoiceNotify_SendAllNotesOff.bin"
VoiceNotify_Epilogue:
	.incbin "includes/generated/v7_transplant_VoiceNotify_Epilogue.bin"
RhythmBuf_ParseEventLoop:
	.incbin "includes/generated/v7_transplant_RhythmBuf_ParseEventLoop.bin"
RhythmParse_ReadFromBuffer:
	.incbin "includes/generated/v7_transplant_RhythmParse_ReadFromBuffer.bin"
RhythmParse_ReadNote:
	.incbin "includes/generated/v7_transplant_RhythmParse_ReadNote.bin"
RhythmParse_ReadVelocity:
	.incbin "includes/generated/v7_transplant_RhythmParse_ReadVelocity.bin"
RhythmParse_ReadDuration:
	.incbin "includes/generated/v7_transplant_RhythmParse_ReadDuration.bin"
RhythmParse_CheckNoteOnType:
	.incbin "includes/generated/v7_transplant_RhythmParse_CheckNoteOnType.bin"
NoteMap_CheckEndMarker:
	.incbin "includes/generated/v7_transplant_NoteMap_CheckEndMarker.bin"
NoteMap_EncodeExtControlChange:
	.incbin "includes/generated/v7_transplant_NoteMap_EncodeExtControlChange.bin"
RhythmParse_StoreCCAndNote:
	.incbin "includes/generated/v7_transplant_RhythmParse_StoreCCAndNote.bin"
RhythmParse_CheckAccType:
	.incbin "includes/generated/v7_transplant_RhythmParse_CheckAccType.bin"
NoteMap_ProcessMergeAlloc:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessMergeAlloc.bin"
RhythmParse_AppendNoteEntry:
	.incbin "includes/generated/v7_transplant_RhythmParse_AppendNoteEntry.bin"
AppendNoteEntry_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_AppendNoteEntry_AdvanceSlot.bin"
AppendNoteEntry_LoadParam:
	.incbin "includes/generated/v7_transplant_AppendNoteEntry_LoadParam.bin"
RhythmParse_TruncateCount:
	.incbin "includes/generated/v7_transplant_RhythmParse_TruncateCount.bin"
RhythmParse_StoreCountAndReturn:
	.incbin "includes/generated/v7_transplant_RhythmParse_StoreCountAndReturn.bin"
SeqEvtBuf_ParseEventLoop:
	.incbin "includes/generated/v7_transplant_SeqEvtBuf_ParseEventLoop.bin"
ParseEventLoop_LoadParam:
	.incbin "includes/generated/v7_transplant_ParseEventLoop_LoadParam.bin"
ParseEventLoop_ReadAlt:
	.incbin "includes/generated/v7_transplant_ParseEventLoop_ReadAlt.bin"
ParseEventLoop_ReadAlt2:
	.incbin "includes/generated/v7_transplant_ParseEventLoop_ReadAlt2.bin"
ParseEventLoop_ReadAlt3:
	.incbin "includes/generated/v7_transplant_ParseEventLoop_ReadAlt3.bin"
ParseEventLoop_CheckIdx:
	.incbin "includes/generated/v7_transplant_ParseEventLoop_CheckIdx.bin"
NoteMap_EncodeCC_Recheck:
	.incbin "includes/generated/v7_transplant_NoteMap_EncodeCC_Recheck.bin"
NoteMap_EncodeControlChange:
	.incbin "includes/generated/v7_transplant_NoteMap_EncodeControlChange.bin"
EncodeControlChange_LoadParam:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_LoadParam.bin"
EncodeControlChange_CheckIdx:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_CheckIdx.bin"
EncodeControlChange_LoadIdx:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_LoadIdx.bin"
EncodeControlChange_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_AdvanceSlot.bin"
EncodeControlChange_LoadParam2:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_LoadParam2.bin"
EncodeControlChange_DoInit:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_DoInit.bin"
EncodeControlChange_RestoreReg:
	.incbin "includes/generated/v7_transplant_EncodeControlChange_RestoreReg.bin"
NoteMap_AddEntry:
	.incbin "includes/generated/v7_transplant_NoteMap_AddEntry.bin"
NoteMap_AltCheckEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_AltCheckEmit.bin"
AltCheckEmit_LoopBody:
	.incbin "includes/generated/v7_transplant_AltCheckEmit_LoopBody.bin"
AltCheckEmit_LoopCheck:
	.incbin "includes/generated/v7_transplant_AltCheckEmit_LoopCheck.bin"
AltCheckEmit_LoadParam:
	.incbin "includes/generated/v7_transplant_AltCheckEmit_LoadParam.bin"
AltCheckEmit_LoadParam2:
	.incbin "includes/generated/v7_transplant_AltCheckEmit_LoadParam2.bin"
NoteMap_AllocCheckChannel:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocCheckChannel.bin"
AllocCheckChannel_LoadParam:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoadParam.bin"
AllocCheckChannel_LoadDRAM:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoadDRAM.bin"
AllocCheckChannel_LoopBody:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoopBody.bin"
AllocCheckChannel_LoopCheck:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoopCheck.bin"
AllocCheckChannel_LoadParam2:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoadParam2.bin"
AllocCheckChannel_LoadParam3:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoadParam3.bin"
AllocCheckChannel_LoadParam4:
	.incbin "includes/generated/v7_transplant_AllocCheckChannel_LoadParam4.bin"
NoteMap_AllocCheckNoteOn:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocCheckNoteOn.bin"
AllocCheckNoteOn_Data:
	.incbin "includes/generated/v7_transplant_AllocCheckNoteOn_Data.bin"
NoteMap_CollectAndFindBestVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectAndFindBestVoice.bin"
NoteMap_AltAllocEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_AltAllocEmit.bin"
CollectBestVoice_EmitLoop:
	.incbin "includes/generated/v7_transplant_CollectBestVoice_EmitLoop.bin"
CollectBestVoice_EmitNext:
	.incbin "includes/generated/v7_transplant_CollectBestVoice_EmitNext.bin"
CollectBestVoice_NonSpecialPath:
	.incbin "includes/generated/v7_transplant_CollectBestVoice_NonSpecialPath.bin"
NoteMap_CollectAndAllocVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectAndAllocVoice.bin"
CollectAllocVoice_CheckDuplicate:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_CheckDuplicate.bin"
CollectAllocVoice_EmitCheck:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_EmitCheck.bin"
CollectAllocVoice_EmitLoop:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_EmitLoop.bin"
CollectAllocVoice_Em_Block:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_Em_Block.bin"
CollectAllocVoice_Em_LoadFromStack:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_Em_LoadFromStack.bin"
CollectAllocVoice_Em_LoadFromStack2:
	.incbin "includes/generated/v7_transplant_CollectAllocVoice_Em_LoadFromStack2.bin"
NoteMap_PopRetFA_StoreAE:
	.incbin "includes/generated/v7_transplant_NoteMap_PopRetFA_StoreAE.bin"
NoteMap_CollectAndAllocVoice_NoTimerCheck:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectAndAllocVoice_NoTimerCheck.bin"
NoteMap_FallbackVoiceCheck:
	.incbin "includes/generated/v7_transplant_NoteMap_FallbackVoiceCheck.bin"
FallbackVoiceCheck_LoopBody:
	.incbin "includes/generated/v7_transplant_FallbackVoiceCheck_LoopBody.bin"
FallbackVoiceCheck_LoopCheck:
	.incbin "includes/generated/v7_transplant_FallbackVoiceCheck_LoopCheck.bin"
FallbackVoiceCheck_LoadParam:
	.incbin "includes/generated/v7_transplant_FallbackVoiceCheck_LoadParam.bin"
FallbackVoiceCheck_LoadParam2:
	.incbin "includes/generated/v7_transplant_FallbackVoiceCheck_LoadParam2.bin"
NoteMap_LookupAllocEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAllocEmit.bin"
LookupAllocEmit_LoopBody:
	.incbin "includes/generated/v7_transplant_LookupAllocEmit_LoopBody.bin"
LookupAllocEmit_LoopCheck:
	.incbin "includes/generated/v7_transplant_LookupAllocEmit_LoopCheck.bin"
LookupAllocEmit_LoadParam:
	.incbin "includes/generated/v7_transplant_LookupAllocEmit_LoadParam.bin"
LookupAllocEmit_LoadParam2:
	.incbin "includes/generated/v7_transplant_LookupAllocEmit_LoadParam2.bin"
LookupAllocEmit_LoadParam3:
	.incbin "includes/generated/v7_transplant_LookupAllocEmit_LoadParam3.bin"
NoteMap_AllocVoiceEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocVoiceEmit.bin"
NoteMap_CollectAndAllocVoice_Indirect:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectAndAllocVoice_Indirect.bin"
NoteMap_IndirectCollectEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_IndirectCollectEmit.bin"
IndirectCollectEmit_LoopBody:
	.incbin "includes/generated/v7_transplant_IndirectCollectEmit_LoopBody.bin"
IndirectCollectEmit_LoopCheck:
	.incbin "includes/generated/v7_transplant_IndirectCollectEmit_LoopCheck.bin"
IndirectCollectEmit_LoadFromStack:
	.incbin "includes/generated/v7_transplant_IndirectCollectEmit_LoadFromStack.bin"
NoteMap_LookupAllocAndSetChannel:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAllocAndSetChannel.bin"
LookupAllocAndSetCha_LoopBody:
	.incbin "includes/generated/v7_transplant_LookupAllocAndSetCha_LoopBody.bin"
LookupAllocAndSetCha_LoopCheck:
	.incbin "includes/generated/v7_transplant_LookupAllocAndSetCha_LoopCheck.bin"
LookupAllocAndSetCha_LoadFromStack:
	.incbin "includes/generated/v7_transplant_LookupAllocAndSetCha_LoadFromStack.bin"
LookupAllocAndSetCha_LoadFromStack2:
	.incbin "includes/generated/v7_transplant_LookupAllocAndSetCha_LoadFromStack2.bin"
NoteMap_PopRetFA_StoreAE2:
	.incbin "includes/generated/v7_transplant_NoteMap_PopRetFA_StoreAE2.bin"
NoteMap_UpdateEntry:
	.incbin "includes/generated/v7_transplant_NoteMap_UpdateEntry.bin"
NoteMap_FallbackAllocEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_FallbackAllocEmit.bin"
UpdateEntry_EmitLoop:
	.incbin "includes/generated/v7_transplant_UpdateEntry_EmitLoop.bin"
UpdateEntry_EmitNext:
	.incbin "includes/generated/v7_transplant_UpdateEntry_EmitNext.bin"
UpdateEntry_CheckLayerCount:
	.incbin "includes/generated/v7_transplant_UpdateEntry_CheckLayerCount.bin"
UpdateEntry_NonSpecialPath:
	.incbin "includes/generated/v7_transplant_UpdateEntry_NonSpecialPath.bin"
NoteMap_DirectLookupEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_DirectLookupEmit.bin"
UpdateEntry_DirectEmitLoop:
	.incbin "includes/generated/v7_transplant_UpdateEntry_DirectEmitLoop.bin"
UpdateEntry_DirectEmitNext:
	.incbin "includes/generated/v7_transplant_UpdateEntry_DirectEmitNext.bin"
UpdateEntry_CheckSeqPartEmit:
	.incbin "includes/generated/v7_transplant_UpdateEntry_CheckSeqPartEmit.bin"
UpdateEntry_CheckMidiEmit:
	.incbin "includes/generated/v7_transplant_UpdateEntry_CheckMidiEmit.bin"
UpdateEntry_CheckLayerResult:
	.incbin "includes/generated/v7_transplant_UpdateEntry_CheckLayerResult.bin"
NoteMap_CollectBestEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectBestEmit.bin"
NoteMap_FindAndAllocBestVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_FindAndAllocBestVoice.bin"
NoteMap_FindAllocEmit:
	.incbin "includes/generated/v7_transplant_NoteMap_FindAllocEmit.bin"
FindAllocEmit_LoopBody:
	.incbin "includes/generated/v7_transplant_FindAllocEmit_LoopBody.bin"
FindAllocEmit_LoopCheck:
	.incbin "includes/generated/v7_transplant_FindAllocEmit_LoopCheck.bin"
FindAllocBest_NonSpecialPath:
	.incbin "includes/generated/v7_transplant_FindAllocBest_NonSpecialPath.bin"
NoteMap_CollectAndAllocVoice_NoTimerReset:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectAndAllocVoice_NoTimerReset.bin"
CollectAndAllocVoice_LoopBody:
	.incbin "includes/generated/v7_transplant_CollectAndAllocVoice_LoopBody.bin"
CollectAndAllocVoice_LoopCheck:
	.incbin "includes/generated/v7_transplant_CollectAndAllocVoice_LoopCheck.bin"
CollectAndAllocVoice_LoadFromStack:
	.incbin "includes/generated/v7_transplant_CollectAndAllocVoice_LoadFromStack.bin"
CollectAndAllocVoice_LoadFromStack2:
	.incbin "includes/generated/v7_transplant_CollectAndAllocVoice_LoadFromStack2.bin"
NoteMap_PopRetFA_StoreAE3:
	.incbin "includes/generated/v7_transplant_NoteMap_PopRetFA_StoreAE3.bin"
PopRetFA_StoreAE3_Prologue:
	.incbin "includes/generated/v7_transplant_PopRetFA_StoreAE3_Prologue.bin"
PopRetFA_StoreAE3_LoadIter:
	.incbin "includes/generated/v7_transplant_PopRetFA_StoreAE3_LoadIter.bin"
NoteMap_AllocVoice_Done:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocVoice_Done.bin"
AllocVoice_Done_LoadParam:
	.incbin "includes/generated/v7_transplant_AllocVoice_Done_LoadParam.bin"
AllocVoice_Done_TryAlloc:
	.incbin "includes/generated/v7_transplant_AllocVoice_Done_TryAlloc.bin"
AllocVoice_Done_LoadIter:
	.incbin "includes/generated/v7_transplant_AllocVoice_Done_LoadIter.bin"
NoteMap_AllocVoiceEntry_Continue:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocVoiceEntry_Continue.bin"
AllocVoiceEntry_Cont_LoadParam:
	.incbin "includes/generated/v7_transplant_AllocVoiceEntry_Cont_LoadParam.bin"
AllocVoiceEntry_Cont_LoadParam2:
	.incbin "includes/generated/v7_transplant_AllocVoiceEntry_Cont_LoadParam2.bin"
NoteMap_UpdateVoiceSlots_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_UpdateVoiceSlots_Return.bin"
NoteMap_ProcessNoteEvent:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessNoteEvent.bin"
ProcessNoteEvent_LoadFromStack:
	.incbin "includes/generated/v7_transplant_ProcessNoteEvent_LoadFromStack.bin"
ProcessNoteEvent_LoadFromStack2:
	.incbin "includes/generated/v7_transplant_ProcessNoteEvent_LoadFromStack2.bin"
ProcessNoteEvent_TryAlloc:
	.incbin "includes/generated/v7_transplant_ProcessNoteEvent_TryAlloc.bin"
ProcessNoteEvent_LoadFromStack3:
	.incbin "includes/generated/v7_transplant_ProcessNoteEvent_LoadFromStack3.bin"
NoteMap_LookupAllocAndStore:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAllocAndStore.bin"
LookupAllocAndStore_LoadParam:
	.incbin "includes/generated/v7_transplant_LookupAllocAndStore_LoadParam.bin"
NoteMap_StoreAllocResult:
	.incbin "includes/generated/v7_transplant_NoteMap_StoreAllocResult.bin"
NoteMap_ProcessRhythmNoteOn:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessRhythmNoteOn.bin"
ProcessRhythmNoteOn_LoadParam:
	.incbin "includes/generated/v7_transplant_ProcessRhythmNoteOn_LoadParam.bin"
ProcessRhythmNoteOn_Epilogue:
	.incbin "includes/generated/v7_transplant_ProcessRhythmNoteOn_Epilogue.bin"
NoteMap_LookupAndAllocVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAndAllocVoice.bin"
LookupAndAllocVoice_LoadFromStack:
	.incbin "includes/generated/v7_transplant_LookupAndAllocVoice_LoadFromStack.bin"
LookupAndAllocVoice_LoadFromStack2:
	.incbin "includes/generated/v7_transplant_LookupAndAllocVoice_LoadFromStack2.bin"
Voice_SetParam_Return:
	.incbin "includes/generated/v7_transplant_Voice_SetParam_Return.bin"
NoteMap_ProcessRhythmRemap:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessRhythmRemap.bin"
ProcessRhythmRemap_LoadFromStack:
	.incbin "includes/generated/v7_transplant_ProcessRhythmRemap_LoadFromStack.bin"
NoteMap_ProcessNoteOff_Done:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessNoteOff_Done.bin"
ProcessNoteOff_Done_Prologue:
	.incbin "includes/generated/v7_transplant_ProcessNoteOff_Done_Prologue.bin"
ProcessNoteOff_Done_Epilogue:
	.incbin "includes/generated/v7_transplant_ProcessNoteOff_Done_Epilogue.bin"
NoteMap_LookupAllocAndStoreResult:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAllocAndStoreResult.bin"
LookupAllocAndStoreR_WriteReg:
	.incbin "includes/generated/v7_transplant_LookupAllocAndStoreR_WriteReg.bin"
NoteMap_InitVoiceSlots:
	.incbin "includes/generated/v7_transplant_NoteMap_InitVoiceSlots.bin"
InitVoiceSlots_CopyLoop:
	.incbin "includes/generated/v7_transplant_InitVoiceSlots_CopyLoop.bin"
InitVoiceSlots_AllocAndCheck:
	.incbin "includes/generated/v7_transplant_InitVoiceSlots_AllocAndCheck.bin"
InitVoiceSlots_SetChannel:
	.incbin "includes/generated/v7_transplant_InitVoiceSlots_SetChannel.bin"
InitVoiceSlots_CheckDualLayer:
	.incbin "includes/generated/v7_transplant_InitVoiceSlots_CheckDualLayer.bin"
InitVoiceSlots_EmitMidi:
	.incbin "includes/generated/v7_transplant_InitVoiceSlots_EmitMidi.bin"
NoteMap_PopIz_StoreAC:
	.incbin "includes/generated/v7_transplant_NoteMap_PopIz_StoreAC.bin"
NoteMap_AssignVoiceParams:
	.incbin "includes/generated/v7_transplant_NoteMap_AssignVoiceParams.bin"
AssignVoiceParams_SetChannel:
	.incbin "includes/generated/v7_transplant_AssignVoiceParams_SetChannel.bin"
AssignVoiceParams_CheckDualLayer:
	.incbin "includes/generated/v7_transplant_AssignVoiceParams_CheckDualLayer.bin"
AssignVoiceParams_Ch_LoadAddr:
	.incbin "includes/generated/v7_transplant_AssignVoiceParams_Ch_LoadAddr.bin"
NoteMap_PopRetFA_StoreAE4:
	.incbin "includes/generated/v7_transplant_NoteMap_PopRetFA_StoreAE4.bin"
NoteMap_AllocateVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocateVoice.bin"
AllocateVoice_LoadReg:
	.incbin "includes/generated/v7_transplant_AllocateVoice_LoadReg.bin"
AllocateVoice_LoadAddr:
	.incbin "includes/generated/v7_transplant_AllocateVoice_LoadAddr.bin"
AllocateVoice_LoadAddr2:
	.incbin "includes/generated/v7_transplant_AllocateVoice_LoadAddr2.bin"
AllocateVoice_Compare:
	.incbin "includes/generated/v7_transplant_AllocateVoice_Compare.bin"
AllocateVoice_LoadAddr3:
	.incbin "includes/generated/v7_transplant_AllocateVoice_LoadAddr3.bin"
NoteMap_PopIz_StoreAC2:
	.incbin "includes/generated/v7_transplant_NoteMap_PopIz_StoreAC2.bin"
NoteMap_SwapVoiceLinks:
	.incbin "includes/generated/v7_transplant_NoteMap_SwapVoiceLinks.bin"
NoteMap_LinkVoiceSlots:
	.incbin "includes/generated/v7_transplant_NoteMap_LinkVoiceSlots.bin"
LinkVoiceSlots_LoadReg:
	.incbin "includes/generated/v7_transplant_LinkVoiceSlots_LoadReg.bin"
LinkVoiceSlots_InitVal:
	.incbin "includes/generated/v7_transplant_LinkVoiceSlots_InitVal.bin"
LinkVoiceSlots_Block:
	.incbin "includes/generated/v7_transplant_LinkVoiceSlots_Block.bin"
LinkVoiceSlots_LoadReg2:
	.incbin "includes/generated/v7_transplant_LinkVoiceSlots_LoadReg2.bin"
NoteMap_LookupAndMergeVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupAndMergeVoice.bin"
LookupAndMergeVoice_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupAndMergeVoice_LoadReg.bin"
LookupAndMergeVoice_LoadReg2:
	.incbin "includes/generated/v7_transplant_LookupAndMergeVoice_LoadReg2.bin"
LookupAndMergeVoice_Deref:
	.incbin "includes/generated/v7_transplant_LookupAndMergeVoice_Deref.bin"
Voice_LookupTableEntries:
	.incbin "includes/generated/v7_transplant_Voice_LookupTableEntries.bin"
LookupTableEntries_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_LoadReg.bin"
LookupTableEntries_LoadReg2:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_LoadReg2.bin"
LookupTableEntries_Deref:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_Deref.bin"
LookupTableEntries_Prologue:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_Prologue.bin"
LookupTableEntries_LoadReg3:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_LoadReg3.bin"
LookupTableEntries_LoadReg4:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_LoadReg4.bin"
LookupTableEntries_Epilogue:
	.incbin "includes/generated/v7_transplant_LookupTableEntries_Epilogue.bin"
NoteMap_ClaimVoiceSlot:
	.incbin "includes/generated/v7_transplant_NoteMap_ClaimVoiceSlot.bin"
ClaimVoiceSlot_Deref:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_Deref.bin"
ClaimVoiceSlot_LoadReg:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_LoadReg.bin"
ClaimVoiceSlot_LoadIdx:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_LoadIdx.bin"
ClaimVoiceSlot_LoadIdx2:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_LoadIdx2.bin"
ClaimVoiceSlot_InitVal:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_InitVal.bin"
ClaimVoiceSlot_LoadIdx3:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_LoadIdx3.bin"
ClaimVoiceSlot_LoadIdx4:
	.incbin "includes/generated/v7_transplant_ClaimVoiceSlot_LoadIdx4.bin"
NoteMap_StoreEntryAndReturn:
	.incbin "includes/generated/v7_transplant_NoteMap_StoreEntryAndReturn.bin"
NoteMap_LookupReturn:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupReturn.bin"
NoteMap_LookupVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupVoice.bin"
LookupVoice_RejectOutOfRange:
	.incbin "includes/generated/v7_transplant_LookupVoice_RejectOutOfRange.bin"
LookupVoice_StartLookup:
	.incbin "includes/generated/v7_transplant_LookupVoice_StartLookup.bin"
LookupVoice_ScanEntries:
	.incbin "includes/generated/v7_transplant_LookupVoice_ScanEntries.bin"
LookupVoice_AdvanceAndCheck:
	.incbin "includes/generated/v7_transplant_LookupVoice_AdvanceAndCheck.bin"
LookupVoice_WithInstrument:
	.incbin "includes/generated/v7_transplant_LookupVoice_WithInstrument.bin"
LookupVoice_InstrScanEntries:
	.incbin "includes/generated/v7_transplant_LookupVoice_InstrScanEntries.bin"
LookupVoice_InstrSca_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupVoice_InstrSca_LoadReg.bin"
NoteMap_StoreResultAndReturn:
	.incbin "includes/generated/v7_transplant_NoteMap_StoreResultAndReturn.bin"
NoteMap_LookupVoice_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_LookupVoice_Return.bin"
NoteMap_CollectMatchingEntries:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectMatchingEntries.bin"
CollectMatchingEntri_LoadFromStack:
	.incbin "includes/generated/v7_transplant_CollectMatchingEntri_LoadFromStack.bin"
CollectMatchingEntri_LoadReg:
	.incbin "includes/generated/v7_transplant_CollectMatchingEntri_LoadReg.bin"
CollectMatchingEntri_LoadParam:
	.incbin "includes/generated/v7_transplant_CollectMatchingEntri_LoadParam.bin"
NoteMap_EmitNoteData_Process:
	.incbin "includes/generated/v7_transplant_NoteMap_EmitNoteData_Process.bin"
EmitNoteData_Process_LoadReg:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoadReg.bin"
EmitNoteData_Process_NextIter:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_NextIter.bin"
EmitNoteData_Process_LoadFromStack:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoadFromStack.bin"
EmitNoteData_Process_LoadReg2:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoadReg2.bin"
EmitNoteData_Process_LoadReg3:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoadReg3.bin"
EmitNoteData_Process_LoadReg4:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoadReg4.bin"
EmitNoteData_Process_InitVal:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_InitVal.bin"
EmitNoteData_Process_LoopBody:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoopBody.bin"
EmitNoteData_Process_LoopCheck:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_LoopCheck.bin"
EmitNoteData_Process_RestoreReg:
	.incbin "includes/generated/v7_transplant_EmitNoteData_Process_RestoreReg.bin"
NoteMap_AllocNewVoiceEntry:
	.incbin "includes/generated/v7_transplant_NoteMap_AllocNewVoiceEntry.bin"
AllocNewVoiceEntry_LoadParam:
	.incbin "includes/generated/v7_transplant_AllocNewVoiceEntry_LoadParam.bin"
AllocNewVoiceEntry_LoadParam2:
	.incbin "includes/generated/v7_transplant_AllocNewVoiceEntry_LoadParam2.bin"
AllocNewVoiceEntry_LoadParam3:
	.incbin "includes/generated/v7_transplant_AllocNewVoiceEntry_LoadParam3.bin"
AllocNewVoiceEntry_LoadParam4:
	.incbin "includes/generated/v7_transplant_AllocNewVoiceEntry_LoadParam4.bin"
NoteMap_SlotLoop_Continue:
	.incbin "includes/generated/v7_transplant_NoteMap_SlotLoop_Continue.bin"
SlotLoop_Continue_LoadParam:
	.incbin "includes/generated/v7_transplant_SlotLoop_Continue_LoadParam.bin"
SlotLoop_Continue_RestoreReg:
	.incbin "includes/generated/v7_transplant_SlotLoop_Continue_RestoreReg.bin"
NoteMap_SetChannelParam:
	.incbin "includes/generated/v7_transplant_NoteMap_SetChannelParam.bin"
SetChannelParam_LoadParam:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadParam.bin"
SetChannelParam_LoadDRAM:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadDRAM.bin"
SetChannelParam_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadDRAM2.bin"
SetChannelParam_LoadParam2:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadParam2.bin"
SetChannelParam_LoadParam3:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadParam3.bin"
SetChannelParam_LoadParam4:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadParam4.bin"
SetChannelParam_LoadParam5:
	.incbin "includes/generated/v7_transplant_SetChannelParam_LoadParam5.bin"
Voice_EmitMidiNoteAndBankEvents:
	.incbin "includes/generated/v7_transplant_Voice_EmitMidiNoteAndBankEvents.bin"
MIDI_SendVoiceData_Loop:
	.incbin "includes/generated/v7_transplant_MIDI_SendVoiceData_Loop.bin"
MIDI_SendVoiceData_Increment:
	.incbin "includes/generated/v7_transplant_MIDI_SendVoiceData_Increment.bin"
MIDI_SendVoiceData_CheckCount:
	.incbin "includes/generated/v7_transplant_MIDI_SendVoiceData_CheckCount.bin"
MIDI_SendVoiceData_Return:
	.incbin "includes/generated/v7_transplant_MIDI_SendVoiceData_Return.bin"
Voice_ScanAndEmitMidiEvents:
	.incbin "includes/generated/v7_transplant_Voice_ScanAndEmitMidiEvents.bin"
ScanEmitMidi_VoiceLoop:
	.incbin "includes/generated/v7_transplant_ScanEmitMidi_VoiceLoop.bin"
ScanEmitMidi_ValidFormat:
	.incbin "includes/generated/v7_transplant_ScanEmitMidi_ValidFormat.bin"
MIDI_SysExParse_CheckLength:
	.incbin "includes/generated/v7_transplant_MIDI_SysExParse_CheckLength.bin"
SysExParse_CheckLeng_LoadReg:
	.incbin "includes/generated/v7_transplant_SysExParse_CheckLeng_LoadReg.bin"
ScanEmitMidi_NextVoice:
	.incbin "includes/generated/v7_transplant_ScanEmitMidi_NextVoice.bin"
ScanEmitMidi_CheckVoiceCount:
	.incbin "includes/generated/v7_transplant_ScanEmitMidi_CheckVoiceCount.bin"
Voice_BuildAndEmitNoteOnEvents:
	.incbin "includes/generated/v7_transplant_Voice_BuildAndEmitNoteOnEvents.bin"
BuildNoteOn_VoiceLoop:
	.incbin "includes/generated/v7_transplant_BuildNoteOn_VoiceLoop.bin"
BuildNoteOn_NextVoice:
	.incbin "includes/generated/v7_transplant_BuildNoteOn_NextVoice.bin"
BuildNoteOn_NextVoic_LoadReg:
	.incbin "includes/generated/v7_transplant_BuildNoteOn_NextVoic_LoadReg.bin"
BuildNoteOn_NextVoic_NextIter:
	.incbin "includes/generated/v7_transplant_BuildNoteOn_NextVoic_NextIter.bin"
BuildNoteOn_CheckVoiceCount:
	.incbin "includes/generated/v7_transplant_BuildNoteOn_CheckVoiceCount.bin"
SeqPart_EmitNoteOnMessages:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitNoteOnMessages.bin"
EmitNoteOnMessages_LoadIter:
	.incbin "includes/generated/v7_transplant_EmitNoteOnMessages_LoadIter.bin"
EmitNoteOnMessages_Compare:
	.incbin "includes/generated/v7_transplant_EmitNoteOnMessages_Compare.bin"
EmitNoteOnMessages_LoadReg:
	.incbin "includes/generated/v7_transplant_EmitNoteOnMessages_LoadReg.bin"
EmitNoteOnMessages_NextIter:
	.incbin "includes/generated/v7_transplant_EmitNoteOnMessages_NextIter.bin"
EmitNoteOnMessages_LoadParam:
	.incbin "includes/generated/v7_transplant_EmitNoteOnMessages_LoadParam.bin"
Voice_EmitMidiNoteOnEvents:
	.incbin "includes/generated/v7_transplant_Voice_EmitMidiNoteOnEvents.bin"
EmitMidiNoteOnEvents_LoadIter:
	.incbin "includes/generated/v7_transplant_EmitMidiNoteOnEvents_LoadIter.bin"
EmitMidiNoteOnEvents_Compare:
	.incbin "includes/generated/v7_transplant_EmitMidiNoteOnEvents_Compare.bin"
EmitMidiNoteOnEvents_LoadReg:
	.incbin "includes/generated/v7_transplant_EmitMidiNoteOnEvents_LoadReg.bin"
EmitMidiNoteOnEvents_NextIter:
	.incbin "includes/generated/v7_transplant_EmitMidiNoteOnEvents_NextIter.bin"
EmitMidiNoteOnEvents_LoadParam:
	.incbin "includes/generated/v7_transplant_EmitMidiNoteOnEvents_LoadParam.bin"
NoteMap_FindEntry:
	.incbin "includes/generated/v7_transplant_NoteMap_FindEntry.bin"
FindEntry_LoadParam:
	.incbin "includes/generated/v7_transplant_FindEntry_LoadParam.bin"
FindEntry_LoadParam2:
	.incbin "includes/generated/v7_transplant_FindEntry_LoadParam2.bin"
FindEntry_LoadParam3:
	.incbin "includes/generated/v7_transplant_FindEntry_LoadParam3.bin"
FindEntry_LoadParam4:
	.incbin "includes/generated/v7_transplant_FindEntry_LoadParam4.bin"
Voice_LoopAdvance_Next:
	.incbin "includes/generated/v7_transplant_Voice_LoopAdvance_Next.bin"
LoopAdvance_Next_LoadParam:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_LoadParam.bin"
NoteMap_FindBestVoiceSlot:
	.incbin "includes/generated/v7_transplant_NoteMap_FindBestVoiceSlot.bin"
FindBestVoiceSlot_LoadReg:
	.incbin "includes/generated/v7_transplant_FindBestVoiceSlot_LoadReg.bin"
FindBestVoiceSlot_Compare:
	.incbin "includes/generated/v7_transplant_FindBestVoiceSlot_Compare.bin"
FindBestVoiceSlot_Compare2:
	.incbin "includes/generated/v7_transplant_FindBestVoiceSlot_Compare2.bin"
FindBestVoiceSlot_Compare3:
	.incbin "includes/generated/v7_transplant_FindBestVoiceSlot_Compare3.bin"
FindBestVoiceSlot_ClearByte:
	.incbin "includes/generated/v7_transplant_FindBestVoiceSlot_ClearByte.bin"
NoteMap_FindEntry_AdvanceSlotD:
	.incbin "includes/generated/v7_transplant_NoteMap_FindEntry_AdvanceSlotD.bin"
FindEntry_AdvanceSlo_LoadReg:
	.incbin "includes/generated/v7_transplant_FindEntry_AdvanceSlo_LoadReg.bin"
FindEntry_AdvanceSlo_LoadReg2:
	.incbin "includes/generated/v7_transplant_FindEntry_AdvanceSlo_LoadReg2.bin"
FindEntry_AdvanceSlo_Deref:
	.incbin "includes/generated/v7_transplant_FindEntry_AdvanceSlo_Deref.bin"
FindEntry_AdvanceSlo_StoreDRAM:
	.incbin "includes/generated/v7_transplant_FindEntry_AdvanceSlo_StoreDRAM.bin"
NoteMap_MarkEntriesAboveThreshold:
	.incbin "includes/generated/v7_transplant_NoteMap_MarkEntriesAboveThreshold.bin"
MarkEntriesAboveThre_LoadParam:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_LoadParam.bin"
MarkEntriesAboveThre_InitIdx:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_InitIdx.bin"
MarkEntriesAboveThre_LoadIdx:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_LoadIdx.bin"
MarkEntriesAboveThre_Block:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_Block.bin"
MarkEntriesAboveThre_LoadIdx2:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_LoadIdx2.bin"
MarkEntriesAboveThre_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_AdvanceSlot.bin"
MarkEntriesAboveThre_LoadParam2:
	.incbin "includes/generated/v7_transplant_MarkEntriesAboveThre_LoadParam2.bin"
NoteMap_FindBestFreeVoice:
	.incbin "includes/generated/v7_transplant_NoteMap_FindBestFreeVoice.bin"
FindBestFreeVoice_LoadReg:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_LoadReg.bin"
FindBestFreeVoice_Compare:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Compare.bin"
FindBestFreeVoice_Compare2:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Compare2.bin"
FindBestFreeVoice_Compare3:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Compare3.bin"
NoteMap_FindBestFreeVoice_AdvanceSlotH:
	.incbin "includes/generated/v7_transplant_NoteMap_FindBestFreeVoice_AdvanceSlotH.bin"
FindBestFreeVoice_Ad_LoadReg:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Ad_LoadReg.bin"
FindBestFreeVoice_Ad_LoadReg2:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Ad_LoadReg2.bin"
FindBestFreeVoice_Ad_Deref:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Ad_Deref.bin"
FindBestFreeVoice_Ad_StoreDRAM:
	.incbin "includes/generated/v7_transplant_FindBestFreeVoice_Ad_StoreDRAM.bin"
NoteMap_EmitNoteOnEvents:
	.incbin "includes/generated/v7_transplant_NoteMap_EmitNoteOnEvents.bin"
SynthVoice_WriteLoop:
	.incbin "includes/generated/v7_transplant_SynthVoice_WriteLoop.bin"
Synth_WriteVoiceData_CheckSize:
	.incbin "includes/generated/v7_transplant_Synth_WriteVoiceData_CheckSize.bin"
SynthVoice_FlushBuffer:
	.incbin "includes/generated/v7_transplant_SynthVoice_FlushBuffer.bin"
SynthVoice_NextVoice:
	.incbin "includes/generated/v7_transplant_SynthVoice_NextVoice.bin"
SynthVoice_CheckVoiceCount:
	.incbin "includes/generated/v7_transplant_SynthVoice_CheckVoiceCount.bin"
SynthVoice_Return:
	.incbin "includes/generated/v7_transplant_SynthVoice_Return.bin"
NoteMap_MergeEntries:
	.incbin "includes/generated/v7_transplant_NoteMap_MergeEntries.bin"
MergeEntries_FilterLoop:
	.incbin "includes/generated/v7_transplant_MergeEntries_FilterLoop.bin"
MergeEntries_NextEntry:
	.incbin "includes/generated/v7_transplant_MergeEntries_NextEntry.bin"
MergeEntries_CheckCount:
	.incbin "includes/generated/v7_transplant_MergeEntries_CheckCount.bin"
NoteMap_ResetEntryTimers:
	.incbin "includes/generated/v7_transplant_NoteMap_ResetEntryTimers.bin"
ResetTimers_Loop:
	.incbin "includes/generated/v7_transplant_ResetTimers_Loop.bin"
ResetTimers_Loop_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_ResetTimers_Loop_AdvanceSlot.bin"
ResetTimers_CheckCount:
	.incbin "includes/generated/v7_transplant_ResetTimers_CheckCount.bin"
ResetTimers_Return:
	.incbin "includes/generated/v7_transplant_ResetTimers_Return.bin"
ResetTimers_Return_LoadParam:
	.incbin "includes/generated/v7_transplant_ResetTimers_Return_LoadParam.bin"
ResetTimers_Return_LoadParam2:
	.incbin "includes/generated/v7_transplant_ResetTimers_Return_LoadParam2.bin"
ResetTimers_Return_LoadParam3:
	.incbin "includes/generated/v7_transplant_ResetTimers_Return_LoadParam3.bin"
ResetTimers_Return_LoadParam4:
	.incbin "includes/generated/v7_transplant_ResetTimers_Return_LoadParam4.bin"
Synth_WriteChannelMod_Loop:
	.incbin "includes/generated/v7_transplant_Synth_WriteChannelMod_Loop.bin"
WriteChannelMod_Loop_LoadParam:
	.incbin "includes/generated/v7_transplant_WriteChannelMod_Loop_LoadParam.bin"
WriteChannelMod_Loop_AdjustIdx:
	.incbin "includes/generated/v7_transplant_WriteChannelMod_Loop_AdjustIdx.bin"
WriteChannelMod_Loop_LoadIdx:
	.incbin "includes/generated/v7_transplant_WriteChannelMod_Loop_LoadIdx.bin"
WriteChannelMod_Loop_AdjustIdx2:
	.incbin "includes/generated/v7_transplant_WriteChannelMod_Loop_AdjustIdx2.bin"
WriteChannelMod_Loop_CheckEnd:
	.incbin "includes/generated/v7_transplant_WriteChannelMod_Loop_CheckEnd.bin"
SndParam_ApplyChannelEntry:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyChannelEntry.bin"
ApplyChannelEntry_AdjustIdx:
	.incbin "includes/generated/v7_transplant_ApplyChannelEntry_AdjustIdx.bin"
ApplyChannelEntry_LoadIdx:
	.incbin "includes/generated/v7_transplant_ApplyChannelEntry_LoadIdx.bin"
ApplyChannelEntry_AdjustIdx2:
	.incbin "includes/generated/v7_transplant_ApplyChannelEntry_AdjustIdx2.bin"
ApplyChannelEntry_CheckIdx:
	.incbin "includes/generated/v7_transplant_ApplyChannelEntry_CheckIdx.bin"
ApplyChannelEntry_CheckEnd:
	.incbin "includes/generated/v7_transplant_ApplyChannelEntry_CheckEnd.bin"
SndParam_StoreChannelResult:
	.incbin "includes/generated/v7_transplant_SndParam_StoreChannelResult.bin"
StoreChannelResult_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_StoreChannelResult_AdvanceSlot.bin"
StoreChannelResult_LoadParam:
	.incbin "includes/generated/v7_transplant_StoreChannelResult_LoadParam.bin"
StoreChannelResult_RestoreReg:
	.incbin "includes/generated/v7_transplant_StoreChannelResult_RestoreReg.bin"
Voice_ApplyTransposeWithEncode:
	.incbin "includes/generated/v7_transplant_Voice_ApplyTransposeWithEncode.bin"
ApplyTransposeWithEn_LoadParam:
	.incbin "includes/generated/v7_transplant_ApplyTransposeWithEn_LoadParam.bin"
ApplyTransposeWithEn_LoadParam2:
	.incbin "includes/generated/v7_transplant_ApplyTransposeWithEn_LoadParam2.bin"
Synth_WriteChannelDelay_Loop:
	.incbin "includes/generated/v7_transplant_Synth_WriteChannelDelay_Loop.bin"
WriteChannelDelay_Lo_LoadParam:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_LoadParam.bin"
WriteChannelDelay_Lo_AdjustIdx:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_AdjustIdx.bin"
WriteChannelDelay_Lo_LoadIdx:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_LoadIdx.bin"
WriteChannelDelay_Lo_AdjustIdx2:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_AdjustIdx2.bin"
WriteChannelDelay_Lo_LoadParam2:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_LoadParam2.bin"
WriteChannelDelay_Lo_LoadParam3:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_LoadParam3.bin"
WriteChannelDelay_Lo_AdvanceSlot:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_AdvanceSlot.bin"
WriteChannelDelay_Lo_LoadParam4:
	.incbin "includes/generated/v7_transplant_WriteChannelDelay_Lo_LoadParam4.bin"
SndParam_ComputeVoiceTuning:
	.incbin "includes/generated/v7_transplant_SndParam_ComputeVoiceTuning.bin"
ComputeVoiceTuning_LoadParam:
	.incbin "includes/generated/v7_transplant_ComputeVoiceTuning_LoadParam.bin"
ComputeVoiceTuning_LoadParam2:
	.incbin "includes/generated/v7_transplant_ComputeVoiceTuning_LoadParam2.bin"
Synth_WriteChannelGain_Loop:
	.incbin "includes/generated/v7_transplant_Synth_WriteChannelGain_Loop.bin"
Synth_WriteParam_Loop:
	.incbin "includes/generated/v7_transplant_Synth_WriteParam_Loop.bin"
TransposeRange_OctaveDown:
	.incbin "includes/generated/v7_transplant_TransposeRange_OctaveDown.bin"
TransposeRange_CheckLow:
	.incbin "includes/generated/v7_transplant_TransposeRange_CheckLow.bin"
TransposeRange_OctaveUp:
	.incbin "includes/generated/v7_transplant_TransposeRange_OctaveUp.bin"
TransposeRange_Clamp:
	.incbin "includes/generated/v7_transplant_TransposeRange_Clamp.bin"
TransposeRange_LookupParam:
	.incbin "includes/generated/v7_transplant_TransposeRange_LookupParam.bin"
Synth_WriteChannelParam:
	.incbin "includes/generated/v7_transplant_Synth_WriteChannelParam.bin"
Synth_WriteParam_Next:
	.incbin "includes/generated/v7_transplant_Synth_WriteParam_Next.bin"
Synth_WriteParam_Check:
	.incbin "includes/generated/v7_transplant_Synth_WriteParam_Check.bin"
NoteMap_ComputePitchOffset:
	.incbin "includes/generated/v7_transplant_NoteMap_ComputePitchOffset.bin"
PitchOffset_NegativeDir:
	.incbin "includes/generated/v7_transplant_PitchOffset_NegativeDir.bin"
PitchOffset_BothDirs:
	.incbin "includes/generated/v7_transplant_PitchOffset_BothDirs.bin"
Synth_InitChannelState_Loop:
	.incbin "includes/generated/v7_transplant_Synth_InitChannelState_Loop.bin"
Synth_InitChannelState_Body:
	.incbin "includes/generated/v7_transplant_Synth_InitChannelState_Body.bin"
Synth_OctaveDown_Loop:
	.incbin "includes/generated/v7_transplant_Synth_OctaveDown_Loop.bin"
Synth_CheckNegative:
	.incbin "includes/generated/v7_transplant_Synth_CheckNegative.bin"
CheckNegative_AdjustIdx:
	.incbin "includes/generated/v7_transplant_CheckNegative_AdjustIdx.bin"
Synth_StoreTransposedNote:
	.incbin "includes/generated/v7_transplant_Synth_StoreTransposedNote.bin"
Synth_SkipTranspose:
	.incbin "includes/generated/v7_transplant_Synth_SkipTranspose.bin"
Synth_SetChannelTone_Continue:
	.incbin "includes/generated/v7_transplant_Synth_SetChannelTone_Continue.bin"
Synth_InitChannelState_Next:
	.incbin "includes/generated/v7_transplant_Synth_InitChannelState_Next.bin"
Synth_InitChannelState_Check:
	.incbin "includes/generated/v7_transplant_Synth_InitChannelState_Check.bin"
InitChannelState_Che_InitVal:
	.incbin "includes/generated/v7_transplant_InitChannelState_Che_InitVal.bin"
InitChannelState_Che_LoopBody:
	.incbin "includes/generated/v7_transplant_InitChannelState_Che_LoopBody.bin"
InitChannelState_Che_NextIter:
	.incbin "includes/generated/v7_transplant_InitChannelState_Che_NextIter.bin"
InitChannelState_Che_LoopCheck:
	.incbin "includes/generated/v7_transplant_InitChannelState_Che_LoopCheck.bin"
Voice_SetTransposeAndAlloc:
	.incbin "includes/generated/v7_transplant_Voice_SetTransposeAndAlloc.bin"
SetTransposeAndAlloc_LoadReg:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_LoadReg.bin"
SetTransposeAndAlloc_Compute:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_Compute.bin"
SetTransposeAndAlloc_LoadReg2:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_LoadReg2.bin"
SetTransposeAndAlloc_Compute2:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_Compute2.bin"
SetTransposeAndAlloc_Compare:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_Compare.bin"
SetTransposeAndAlloc_LoadReg3:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_LoadReg3.bin"
SetTransposeAndAlloc_NextIter:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_NextIter.bin"
SetTransposeAndAlloc_Deref:
	.incbin "includes/generated/v7_transplant_SetTransposeAndAlloc_Deref.bin"
SndParam_UpdateChannelTuning:
	.incbin "includes/generated/v7_transplant_SndParam_UpdateChannelTuning.bin"
UpdateChannelTuning_LoadDRAM:
	.incbin "includes/generated/v7_transplant_UpdateChannelTuning_LoadDRAM.bin"
UpdateChannelTuning_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_UpdateChannelTuning_LoadDRAM2.bin"
UpdateChannelTuning_LoadDRAM3:
	.incbin "includes/generated/v7_transplant_UpdateChannelTuning_LoadDRAM3.bin"
UpdateChannelTuning_SetByteFF:
	.incbin "includes/generated/v7_transplant_UpdateChannelTuning_SetByteFF.bin"
Synth_SelectTone_Continue:
	.incbin "includes/generated/v7_transplant_Synth_SelectTone_Continue.bin"
SelectTone_Continue_SetByteFF:
	.incbin "includes/generated/v7_transplant_SelectTone_Continue_SetByteFF.bin"
SelectTone_Continue_Return:
	.incbin "includes/generated/v7_transplant_SelectTone_Continue_Return.bin"
SelectTone_Continue_Prologue:
	.incbin "includes/generated/v7_transplant_SelectTone_Continue_Prologue.bin"
SelectTone_Continue_LoadReg:
	.incbin "includes/generated/v7_transplant_SelectTone_Continue_LoadReg.bin"
Rhythm_DispatchCCCommand:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCCCommand.bin"
Note_CheckTransposeRange:
	.incbin "includes/generated/v7_transplant_Note_CheckTransposeRange.bin"
CheckTransposeRange_ClearByte:
	.incbin "includes/generated/v7_transplant_CheckTransposeRange_ClearByte.bin"
CheckTransposeRange_LoadParam:
	.incbin "includes/generated/v7_transplant_CheckTransposeRange_LoadParam.bin"
CheckTransposeRange_ClearByte2:
	.incbin "includes/generated/v7_transplant_CheckTransposeRange_ClearByte2.bin"
UI_CheckControlCode_TestResult:
	.incbin "includes/generated/v7_transplant_UI_CheckControlCode_TestResult.bin"
CheckControlCode_Tes_WriteReg:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_WriteReg.bin"
CheckControlCode_Tes_LoopBody:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_LoopBody.bin"
CheckControlCode_Tes_LoopCheck:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_LoopCheck.bin"
CheckControlCode_Tes_TestBit0:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_TestBit0.bin"
CheckControlCode_Tes_TestBit02:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_TestBit02.bin"
CheckControlCode_Tes_TestBit03:
	.incbin "includes/generated/v7_transplant_CheckControlCode_Tes_TestBit03.bin"
NoteMap_AddChangedVoices:
	.incbin "includes/generated/v7_transplant_NoteMap_AddChangedVoices.bin"
AddChangedVoices_TestBit0:
	.incbin "includes/generated/v7_transplant_AddChangedVoices_TestBit0.bin"
AddChangedVoices_TestBit02:
	.incbin "includes/generated/v7_transplant_AddChangedVoices_TestBit02.bin"
AddChangedVoices_TestBit03:
	.incbin "includes/generated/v7_transplant_AddChangedVoices_TestBit03.bin"
NoteMap_CollectEnabledVoices:
	.incbin "includes/generated/v7_transplant_NoteMap_CollectEnabledVoices.bin"
CollectEnabledVoices_TestBit0:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit0.bin"
CollectEnabledVoices_TestBit02:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit02.bin"
CollectEnabledVoices_TestBit03:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit03.bin"
CollectEnabledVoices_CheckMem:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_CheckMem.bin"
CollectEnabledVoices_CheckMem2:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_CheckMem2.bin"
CollectEnabledVoices_TestBit1:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit1.bin"
CollectEnabledVoices_TestBit2:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit2.bin"
CollectEnabledVoices_CheckMem3:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_CheckMem3.bin"
CollectEnabledVoices_TestBit12:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit12.bin"
CollectEnabledVoices_TestBit22:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_TestBit22.bin"
CollectEnabledVoices_WriteReg:
	.incbin "includes/generated/v7_transplant_CollectEnabledVoices_WriteReg.bin"
VoiceAssign_CheckBothParts:
	.incbin "includes/generated/v7_transplant_VoiceAssign_CheckBothParts.bin"
VoiceAssign_LookupAndLoop_Part1:
	.incbin "includes/generated/v7_transplant_VoiceAssign_LookupAndLoop_Part1.bin"
VoiceAssign_FindRetry_Part1:
	.incbin "includes/generated/v7_transplant_VoiceAssign_FindRetry_Part1.bin"
VoiceAssign_MergeAndCollect_Part1:
	.incbin "includes/generated/v7_transplant_VoiceAssign_MergeAndCollect_Part1.bin"
VoiceAssign_CheckSinglePart:
	.incbin "includes/generated/v7_transplant_VoiceAssign_CheckSinglePart.bin"
VoiceAssign_LookupAndLoop_Part2:
	.incbin "includes/generated/v7_transplant_VoiceAssign_LookupAndLoop_Part2.bin"
VoiceAssign_FindRetry_Part2:
	.incbin "includes/generated/v7_transplant_VoiceAssign_FindRetry_Part2.bin"
VoiceAssign_CheckOtherPart:
	.incbin "includes/generated/v7_transplant_VoiceAssign_CheckOtherPart.bin"
NoteMap_VoiceAssign_Finalize:
	.incbin "includes/generated/v7_transplant_NoteMap_VoiceAssign_Finalize.bin"
VoiceAssign_Finalize_LoopBody:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Finalize_LoopBody.bin"
VoiceAssign_Finalize_LoopCheck:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Finalize_LoopCheck.bin"
VoiceAssign_Finalize_TestBit0:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Finalize_TestBit0.bin"
VoiceAssign_Finalize_TestBit02:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Finalize_TestBit02.bin"
VoiceAssign_Finalize_TestBit03:
	.incbin "includes/generated/v7_transplant_VoiceAssign_Finalize_TestBit03.bin"
NoteMap_UpdateChangedVoices:
	.incbin "includes/generated/v7_transplant_NoteMap_UpdateChangedVoices.bin"
UpdateChangedVoices_TestBit0:
	.incbin "includes/generated/v7_transplant_UpdateChangedVoices_TestBit0.bin"
UpdateChangedVoices_TestBit02:
	.incbin "includes/generated/v7_transplant_UpdateChangedVoices_TestBit02.bin"
UpdateChangedVoices_TestBit03:
	.incbin "includes/generated/v7_transplant_UpdateChangedVoices_TestBit03.bin"
NoteMap_ReallocEnabledVoices:
	.incbin "includes/generated/v7_transplant_NoteMap_ReallocEnabledVoices.bin"
ReallocEnabledVoices_TestBit0:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit0.bin"
ReallocEnabledVoices_TestBit02:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit02.bin"
ReallocEnabledVoices_TestBit03:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit03.bin"
ReallocEnabledVoices_CheckMem:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem.bin"
ReallocEnabledVoices_CheckMem2:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem2.bin"
ReallocEnabledVoices_TestBit1:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit1.bin"
ReallocEnabledVoices_TestBit2:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit2.bin"
ReallocEnabledVoices_CheckMem3:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem3.bin"
ReallocEnabledVoices_TestBit12:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit12.bin"
ReallocEnabledVoices_TestBit22:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_TestBit22.bin"
ReallocEnabledVoices_WriteReg:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_WriteReg.bin"
ReallocEnabledVoices_Block:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_Block.bin"
ReallocEnabledVoices_CheckMem4:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem4.bin"
ReallocEnabledVoices_LoadAddr:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_LoadAddr.bin"
ReallocEnabledVoices_DoFindEntr:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_DoFindEntr.bin"
ReallocEnabledVoices_LoadAddr2:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_LoadAddr2.bin"
ReallocEnabledVoices_WriteReg2:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_WriteReg2.bin"
ReallocEnabledVoices_CheckMem5:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem5.bin"
ReallocEnabledVoices_LoadAddr3:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_LoadAddr3.bin"
ReallocEnabledVoices_DoFindEntr2:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_DoFindEntr2.bin"
ReallocEnabledVoices_CheckMem6:
	.incbin "includes/generated/v7_transplant_ReallocEnabledVoices_CheckMem6.bin"
NoteMap_ReallocVoices_Exit:
	.incbin "includes/generated/v7_transplant_NoteMap_ReallocVoices_Exit.bin"
ReallocVoices_Exit_WriteReg:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_WriteReg.bin"
ReallocVoices_Exit_CheckEnd:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_CheckEnd.bin"
ReallocVoices_Exit_Compare:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_Compare.bin"
ReallocVoices_Exit_TestBit1:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_TestBit1.bin"
ReallocVoices_Exit_TestBit2:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_TestBit2.bin"
ReallocVoices_Exit_TestBit3:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_TestBit3.bin"
ReallocVoices_Exit_CheckDRAM:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_CheckDRAM.bin"
ReallocVoices_Exit_WriteReg2:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_WriteReg2.bin"
ReallocVoices_Exit_TestBit32:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_TestBit32.bin"
ReallocVoices_Exit_WriteReg3:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_WriteReg3.bin"
ReallocVoices_Exit_Block:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_Block.bin"
ReallocVoices_Exit_WriteReg4:
	.incbin "includes/generated/v7_transplant_ReallocVoices_Exit_WriteReg4.bin"
NoteMap_StoreAndRet:
	.incbin "includes/generated/v7_transplant_NoteMap_StoreAndRet.bin"
StoreAndRet_WriteReg:
	.incbin "includes/generated/v7_transplant_StoreAndRet_WriteReg.bin"
StoreAndRet_WriteReg2:
	.incbin "includes/generated/v7_transplant_StoreAndRet_WriteReg2.bin"
StoreAndRet_WriteReg3:
	.incbin "includes/generated/v7_transplant_StoreAndRet_WriteReg3.bin"
VoiceRealloc_CheckSingleLayer:
	.incbin "includes/generated/v7_transplant_VoiceRealloc_CheckSingleLayer.bin"
VoiceRealloc_LookupVoice:
	.incbin "includes/generated/v7_transplant_VoiceRealloc_LookupVoice.bin"
VoiceRealloc_CheckAltLayer:
	.incbin "includes/generated/v7_transplant_VoiceRealloc_CheckAltLayer.bin"
NoteMap_StoreVoiceResultAndReturn:
	.incbin "includes/generated/v7_transplant_NoteMap_StoreVoiceResultAndReturn.bin"
NoteMap_ProcessDualLayerNoteOff:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessDualLayerNoteOff.bin"
NoteMap_DualLayerNoteOff_SinglePath:
	.incbin "includes/generated/v7_transplant_NoteMap_DualLayerNoteOff_SinglePath.bin"
NoteMap_ProcessNote_SetResult:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessNote_SetResult.bin"
NoteMap_ProcessLayeredNoteOn:
	.incbin "includes/generated/v7_transplant_NoteMap_ProcessLayeredNoteOn.bin"
ProcessLayeredNoteOn_WriteReg:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_WriteReg.bin"
ProcessLayeredNoteOn_CheckEnd:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_CheckEnd.bin"
ProcessLayeredNoteOn_WriteReg2:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_WriteReg2.bin"
ProcessLayeredNoteOn_WriteReg3:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_WriteReg3.bin"
ProcessLayeredNoteOn_WriteReg4:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_WriteReg4.bin"
ProcessLayeredNoteOn_InitVal:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_InitVal.bin"
ProcessLayeredNoteOn_LoadIter:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_LoadIter.bin"
ProcessLayeredNoteOn_WriteReg5:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_WriteReg5.bin"
ProcessLayeredNoteOn_NextIter:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_NextIter.bin"
ProcessLayeredNoteOn_InitVal2:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_InitVal2.bin"
ProcessLayeredNoteOn_LoadIter2:
	.incbin "includes/generated/v7_transplant_ProcessLayeredNoteOn_LoadIter2.bin"
NoteMap_ClaimAndInitVoiceSlot_A:
	.incbin "includes/generated/v7_transplant_NoteMap_ClaimAndInitVoiceSlot_A.bin"
NoteMap_LoopAdvance_Next:
	.incbin "includes/generated/v7_transplant_NoteMap_LoopAdvance_Next.bin"
LoopAdvance_Next_CheckMem:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_CheckMem.bin"
LoopAdvance_Next_InitVal:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_InitVal.bin"
LoopAdvance_Next_LoadIter:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_LoadIter.bin"
LoopAdvance_Next_WriteReg:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_WriteReg.bin"
LoopAdvance_Next_Increment:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_Increment.bin"
LoopAdvance_Next_CheckMem2:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_CheckMem2.bin"
LoopAdvance_Next_LoadIter2:
	.incbin "includes/generated/v7_transplant_LoopAdvance_Next_LoadIter2.bin"
NoteMap_ClaimAndInitVoiceSlot_B:
	.incbin "includes/generated/v7_transplant_NoteMap_ClaimAndInitVoiceSlot_B.bin"
NoteMap_LoopAdvance_Next2:
	.incbin "includes/generated/v7_transplant_NoteMap_LoopAdvance_Next2.bin"
NoteMap_PopIzStoreRet:
	.incbin "includes/generated/v7_transplant_NoteMap_PopIzStoreRet.bin"
PopIzStoreRet_Prologue:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_Prologue.bin"
PopIzStoreRet_CheckEnd:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_CheckEnd.bin"
PopIzStoreRet_Block:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_Block.bin"
PopIzStoreRet_Increment:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_Increment.bin"
PopIzStoreRet_WriteReg:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_WriteReg.bin"
PopIzStoreRet_WriteReg2:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_WriteReg2.bin"
PopIzStoreRet_WriteReg3:
	.incbin "includes/generated/v7_transplant_PopIzStoreRet_WriteReg3.bin"
NoteMap_CrossChannelReassign:
	.incbin "includes/generated/v7_transplant_NoteMap_CrossChannelReassign.bin"
CrossChannelReassign_WriteReg:
	.incbin "includes/generated/v7_transplant_CrossChannelReassign_WriteReg.bin"
NoteMap_SetParam_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_SetParam_Return.bin"
SetParam_Return_WriteReg:
	.incbin "includes/generated/v7_transplant_SetParam_Return_WriteReg.bin"
SetParam_Return_WriteReg2:
	.incbin "includes/generated/v7_transplant_SetParam_Return_WriteReg2.bin"
SetParam_Return_WriteReg3:
	.incbin "includes/generated/v7_transplant_SetParam_Return_WriteReg3.bin"
SetParam_Return_LoadAddr:
	.incbin "includes/generated/v7_transplant_SetParam_Return_LoadAddr.bin"
SetParam_Return_CheckEnd:
	.incbin "includes/generated/v7_transplant_SetParam_Return_CheckEnd.bin"
SetParam_Return_WriteReg4:
	.incbin "includes/generated/v7_transplant_SetParam_Return_WriteReg4.bin"
SetParam_Return_WriteReg5:
	.incbin "includes/generated/v7_transplant_SetParam_Return_WriteReg5.bin"
SetParam_Return_LoadAddr2:
	.incbin "includes/generated/v7_transplant_SetParam_Return_LoadAddr2.bin"
SeqPart_LookupReturn:
	.incbin "includes/generated/v7_transplant_SeqPart_LookupReturn.bin"
SeqPart_EmitMelodicNote:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitMelodicNote.bin"
SeqPart_MelodicNote_Layer1Done:
	.incbin "includes/generated/v7_transplant_SeqPart_MelodicNote_Layer1Done.bin"
SeqPart_MelodicNote_SingleLayer:
	.incbin "includes/generated/v7_transplant_SeqPart_MelodicNote_SingleLayer.bin"
SeqPart_MelodicNote_Layer1Done_Alt:
	.incbin "includes/generated/v7_transplant_SeqPart_MelodicNote_Layer1Done_Alt.bin"
SeqPart_EmitMelodicNote_Return:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitMelodicNote_Return.bin"
SeqPart_EmitPercussionNote:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitPercussionNote.bin"
SeqPart_PercNote_Layer1Done:
	.incbin "includes/generated/v7_transplant_SeqPart_PercNote_Layer1Done.bin"
SeqPart_PercNote_SingleLayer:
	.incbin "includes/generated/v7_transplant_SeqPart_PercNote_SingleLayer.bin"
SeqPart_PercNote_Layer1Done_Alt:
	.incbin "includes/generated/v7_transplant_SeqPart_PercNote_Layer1Done_Alt.bin"
SeqPart_EmitPercussionNote_Return:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitPercussionNote_Return.bin"
SeqPart_EmitNoteOn_Full:
	.incbin "includes/generated/v7_transplant_SeqPart_EmitNoteOn_Full.bin"
RhythmBuf_EventDispatchLoop:
	.incbin "includes/generated/v7_transplant_RhythmBuf_EventDispatchLoop.bin"
Rhythm_ProcessEventDispatch:
	.incbin "includes/generated/v7_transplant_Rhythm_ProcessEventDispatch.bin"
ProcessEventDispatch_Compare:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_Compare.bin"
ProcessEventDispatch_LoadParam:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam.bin"
ProcessEventDispatch_InitVal:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_InitVal.bin"
ProcessEventDispatch_LoadParam2:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam2.bin"
ProcessEventDispatch_LoadParam3:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam3.bin"
ProcessEventDispatch_LoadParam4:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam4.bin"
ProcessEventDispatch_LoadIter:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadIter.bin"
ProcessEventDispatch_InitVal2:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_InitVal2.bin"
ProcessEventDispatch_LoadReg:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadReg.bin"
ProcessEventDispatch_LoadParam5:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam5.bin"
ProcessEventDispatch_LoadParam6:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam6.bin"
ProcessEventDispatch_LoadParam7:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_LoadParam7.bin"
ProcessEventDispatch_DoInit:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_DoInit.bin"
ProcessEventDispatch_Block:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_Block.bin"
ProcessEventDispatch_Send:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_Send.bin"
ProcessEventDispatch_Prologue:
	.incbin "includes/generated/v7_transplant_ProcessEventDispatch_Prologue.bin"
SeqEvtBuf_NonNoteDispatchLoop:
	.incbin "includes/generated/v7_transplant_SeqEvtBuf_NonNoteDispatchLoop.bin"
NonNoteDispatchLoop_ReadAlt:
	.incbin "includes/generated/v7_transplant_NonNoteDispatchLoop_ReadAlt.bin"
NonNoteDispatchLoop_LoadParam:
	.incbin "includes/generated/v7_transplant_NonNoteDispatchLoop_LoadParam.bin"
NonNoteDispatchLoop_ReadAlt2:
	.incbin "includes/generated/v7_transplant_NonNoteDispatchLoop_ReadAlt2.bin"
NonNoteDispatchLoop_LoadParam2:
	.incbin "includes/generated/v7_transplant_NonNoteDispatchLoop_LoadParam2.bin"
SeqEvtBuf_NoteDispatch:
	.incbin "includes/generated/v7_transplant_SeqEvtBuf_NoteDispatch.bin"
SeqPerformance_EventDispatch:
	.incbin "includes/generated/v7_transplant_SeqPerformance_EventDispatch.bin"
SeqPerformance_Event_Block:
	.incbin "includes/generated/v7_transplant_SeqPerformance_Event_Block.bin"
SeqPerformance_Event_Send:
	.incbin "includes/generated/v7_transplant_SeqPerformance_Event_Send.bin"
SndParam_DispatchReturn:
	.incbin "includes/generated/v7_transplant_SndParam_DispatchReturn.bin"
VoiceMap_AllocateSlot:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlot.bin"
VoiceMap_AllocateSlo_SetByteFF:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlo_SetByteFF.bin"
VoiceMap_AllocateSlo_Block:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlo_Block.bin"
VoiceMap_AllocateSlo_Block2:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlo_Block2.bin"
VoiceMap_AllocateSlo_Block3:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlo_Block3.bin"
VoiceMap_AllocateSlo_SetByteFF2:
	.incbin "includes/generated/v7_transplant_VoiceMap_AllocateSlo_SetByteFF2.bin"
NoteMap_FindBestMatch_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_FindBestMatch_Return.bin"
NoteMap_FindBestMatch:
	.incbin "includes/generated/v7_transplant_NoteMap_FindBestMatch.bin"
NoteMap_CheckVoiceReuse:
	.incbin "includes/generated/v7_transplant_NoteMap_CheckVoiceReuse.bin"
CheckVoiceReuse_SetByteFF:
	.incbin "includes/generated/v7_transplant_CheckVoiceReuse_SetByteFF.bin"
CheckVoiceReuse_SetByteFF2:
	.incbin "includes/generated/v7_transplant_CheckVoiceReuse_SetByteFF2.bin"
CheckVoiceReuse_Block:
	.incbin "includes/generated/v7_transplant_CheckVoiceReuse_Block.bin"
NoteMap_GetVoiceData_Return:
	.incbin "includes/generated/v7_transplant_NoteMap_GetVoiceData_Return.bin"
NoteMap_GetVoiceData_Entry:
	.incbin "includes/generated/v7_transplant_NoteMap_GetVoiceData_Entry.bin"
GetVoiceData_Entry_LoopBody:
	.incbin "includes/generated/v7_transplant_GetVoiceData_Entry_LoopBody.bin"
GetVoiceData_Entry_LoopCheck:
	.incbin "includes/generated/v7_transplant_GetVoiceData_Entry_LoopCheck.bin"
GetVoiceData_Entry_Compare:
	.incbin "includes/generated/v7_transplant_GetVoiceData_Entry_Compare.bin"
GetVoiceData_Entry_Block:
	.incbin "includes/generated/v7_transplant_GetVoiceData_Entry_Block.bin"
GetVoiceData_Entry_Block2:
	.incbin "includes/generated/v7_transplant_GetVoiceData_Entry_Block2.bin"
Voice_ReadSearchResult:
	.incbin "includes/generated/v7_transplant_Voice_ReadSearchResult.bin"
Voice_ResetSearchState:
	.incbin "includes/generated/v7_transplant_Voice_ResetSearchState.bin"
UIParam_ScanAndCollect:
	.incbin "includes/generated/v7_transplant_UIParam_ScanAndCollect.bin"
UIParam_SetDefaultCount:
	.incbin "includes/generated/v7_transplant_UIParam_SetDefaultCount.bin"
UIParam_CallbackDispatch:
	.incbin "includes/generated/v7_transplant_UIParam_CallbackDispatch.bin"
UIParam_CallbackReturn:
	.incbin "includes/generated/v7_transplant_UIParam_CallbackReturn.bin"
UIParam_CompareResult:
	.incbin "includes/generated/v7_transplant_UIParam_CompareResult.bin"
UIParam_StoreAndReturn:
	.incbin "includes/generated/v7_transplant_UIParam_StoreAndReturn.bin"
NoteMap_SearchVoiceEntry:
	.incbin "includes/generated/v7_transplant_NoteMap_SearchVoiceEntry.bin"
SearchVoice_EntryLoop:
	.incbin "includes/generated/v7_transplant_SearchVoice_EntryLoop.bin"
SearchVoice_OctaveDown:
	.incbin "includes/generated/v7_transplant_SearchVoice_OctaveDown.bin"
SearchVoice_CheckHighBound:
	.incbin "includes/generated/v7_transplant_SearchVoice_CheckHighBound.bin"
SearchVoice_OctaveUp:
	.incbin "includes/generated/v7_transplant_SearchVoice_OctaveUp.bin"
SearchVoice_CheckLowBound:
	.incbin "includes/generated/v7_transplant_SearchVoice_CheckLowBound.bin"
SearchVoice_CheckDistance:
	.incbin "includes/generated/v7_transplant_SearchVoice_CheckDistance.bin"
SearchVoice_NextEntry:
	.incbin "includes/generated/v7_transplant_SearchVoice_NextEntry.bin"
SearchVoice_CheckCount:
	.incbin "includes/generated/v7_transplant_SearchVoice_CheckCount.bin"
SearchVoice_StoreResult:
	.incbin "includes/generated/v7_transplant_SearchVoice_StoreResult.bin"
SearchVoice_SetZero:
	.incbin "includes/generated/v7_transplant_SearchVoice_SetZero.bin"
SearchVoice_SortCheck:
	.incbin "includes/generated/v7_transplant_SearchVoice_SortCheck.bin"
SearchVoice_BubbleSortOuter:
	.incbin "includes/generated/v7_transplant_SearchVoice_BubbleSortOuter.bin"
SearchVoice_BubbleSortInner:
	.incbin "includes/generated/v7_transplant_SearchVoice_BubbleSortInner.bin"
SearchVoice_BubbleAdvance:
	.incbin "includes/generated/v7_transplant_SearchVoice_BubbleAdvance.bin"
SearchVoice_BubbleOuterNext:
	.incbin "includes/generated/v7_transplant_SearchVoice_BubbleOuterNext.bin"
SearchVoice_Done:
	.incbin "includes/generated/v7_transplant_SearchVoice_Done.bin"
SoundFX_Handler_12:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_12.bin"
SoundFX_Handler_12_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_12_LoadReg.bin"
SoundFX_Handler_0:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_0.bin"
SoundFX_Handler_0_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_0_LoadReg.bin"
SoundFX_Handler_1:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_1.bin"
SoundFX_Handler_1_Block:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_1_Block.bin"
SoundFX_Handler_1_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_1_LoadReg.bin"
SoundFX_Handler_1_Block2:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_1_Block2.bin"
SoundFX_SetVolumeOffset_Return:
	.incbin "includes/generated/v7_transplant_SoundFX_SetVolumeOffset_Return.bin"
SoundFX_Handler_2:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_2.bin"
SoundFX_Handler_2_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_2_ClearWord.bin"
SoundFX_Handler_2_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_2_LoadReg.bin"
SoundFX_Handler_3:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_3.bin"
SoundFX_Handler_3_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_3_ClearWord.bin"
SoundFX_Handler_3_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_3_LoadReg.bin"
SoundFX_Handler_4:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_4.bin"
SoundFX_Handler_4_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_4_ClearWord.bin"
SoundFX_Handler_4_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_4_LoadReg.bin"
SoundFX_Handler_5:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_5.bin"
SoundFX_Handler_5_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_5_ClearWord.bin"
SoundFX_Handler_5_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_5_LoadReg.bin"
SoundFX_Handler_6:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_6.bin"
SoundFX_Handler_6_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_6_ClearWord.bin"
SoundFX_Handler_6_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_6_LoadReg.bin"
SoundFX_Handler_7:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_7.bin"
SoundFX_Handler_7_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_7_ClearWord.bin"
SoundFX_Handler_7_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_7_LoadReg.bin"
SoundFX_Handler_8:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_8.bin"
SoundFX_Handler_8_ClearWord:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_8_ClearWord.bin"
SoundFX_Handler_8_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_8_LoadReg.bin"
SoundFX_Handler_9:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_9.bin"
SoundFX_Handler_10:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_10.bin"
SoundFX_Handler_11:
	.incbin "includes/generated/v7_transplant_SoundFX_Handler_11.bin"
VoiceBank_MapNoteToOffset:
	.incbin "includes/generated/v7_transplant_VoiceBank_MapNoteToOffset.bin"
MapNoteToOffset_Compare:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare.bin"
MapNoteToOffset_ClearByte:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_ClearByte.bin"
MapNoteToOffset_Compare2:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare2.bin"
MapNoteToOffset_SetByte:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_SetByte.bin"
MapNoteToOffset_Compare3:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare3.bin"
MapNoteToOffset_SetByte2:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_SetByte2.bin"
MapNoteToOffset_Compare4:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare4.bin"
MapNoteToOffset_ClearByte2:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_ClearByte2.bin"
MapNoteToOffset_Compare5:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare5.bin"
MapNoteToOffset_SetByte3:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_SetByte3.bin"
MapNoteToOffset_Compare6:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare6.bin"
MapNoteToOffset_SetByte4:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_SetByte4.bin"
MapNoteToOffset_Compare7:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_Compare7.bin"
MapNoteToOffset_SetByte5:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_SetByte5.bin"
MapNoteToOffset_ClearByte3:
	.incbin "includes/generated/v7_transplant_MapNoteToOffset_ClearByte3.bin"
Audio_NullRet1:
	.incbin "includes/generated/v7_transplant_Audio_NullRet1.bin"
Audio_NullRet1_Data:
	.incbin "includes/generated/v7_transplant_Audio_NullRet1_Data.bin"
Voice_UpdateNoteState:
	.incbin "includes/generated/v7_transplant_Voice_UpdateNoteState.bin"
UpdateNoteState_CheckDRAM:
	.incbin "includes/generated/v7_transplant_UpdateNoteState_CheckDRAM.bin"
UpdateNoteState_CheckDRAM2:
	.incbin "includes/generated/v7_transplant_UpdateNoteState_CheckDRAM2.bin"
Voice_CheckAndUpdateMode:
	.incbin "includes/generated/v7_transplant_Voice_CheckAndUpdateMode.bin"
Voice_ProcessControllers_Return:
	.incbin "includes/generated/v7_transplant_Voice_ProcessControllers_Return.bin"
ProcessControllers_R_Prologue:
	.incbin "includes/generated/v7_transplant_ProcessControllers_R_Prologue.bin"
ProcessControllers_R_LoadDRAM:
	.incbin "includes/generated/v7_transplant_ProcessControllers_R_LoadDRAM.bin"
PlayMode_ClearBit6:
	.incbin "includes/generated/v7_transplant_PlayMode_ClearBit6.bin"
PlayMode_UpdateAndReturn:
	.incbin "includes/generated/v7_transplant_PlayMode_UpdateAndReturn.bin"
PlayMode_SetZeroResult:
	.incbin "includes/generated/v7_transplant_PlayMode_SetZeroResult.bin"
PlayMode_StoreResult:
	.incbin "includes/generated/v7_transplant_PlayMode_StoreResult.bin"
Voice_UpdatePlayModeState:
	.incbin "includes/generated/v7_transplant_Voice_UpdatePlayModeState.bin"
PlayMode_CheckModes23:
	.incbin "includes/generated/v7_transplant_PlayMode_CheckModes23.bin"
PlayMode_ClearBit6_Alt:
	.incbin "includes/generated/v7_transplant_PlayMode_ClearBit6_Alt.bin"
PlayMode_CheckSlotAndReturn:
	.incbin "includes/generated/v7_transplant_PlayMode_CheckSlotAndReturn.bin"
PlayMode_SetZero_Alt:
	.incbin "includes/generated/v7_transplant_PlayMode_SetZero_Alt.bin"
PlayMode_Epilogue:
	.incbin "includes/generated/v7_transplant_PlayMode_Epilogue.bin"
Voice_DispatchByTimingState:
	.incbin "includes/generated/v7_transplant_Voice_DispatchByTimingState.bin"
VoiceTiming_ResetSlot:
	.incbin "includes/generated/v7_transplant_VoiceTiming_ResetSlot.bin"
VoiceTiming_CheckBit6:
	.incbin "includes/generated/v7_transplant_VoiceTiming_CheckBit6.bin"
VoiceTiming_CheckBit7:
	.incbin "includes/generated/v7_transplant_VoiceTiming_CheckBit7.bin"
VoiceTiming_CompareThreshold:
	.incbin "includes/generated/v7_transplant_VoiceTiming_CompareThreshold.bin"
VoiceTiming_EqualThreshold:
	.incbin "includes/generated/v7_transplant_VoiceTiming_EqualThreshold.bin"
VoiceTiming_BelowThreshold:
	.incbin "includes/generated/v7_transplant_VoiceTiming_BelowThreshold.bin"
Voice_AdjustTiming_Return:
	.incbin "includes/generated/v7_transplant_Voice_AdjustTiming_Return.bin"
Voice_UpdateVelocity_Entry:
	.incbin "includes/generated/v7_transplant_Voice_UpdateVelocity_Entry.bin"
VelocityUpdate_CheckBit4:
	.incbin "includes/generated/v7_transplant_VelocityUpdate_CheckBit4.bin"
VelocityUpdate_CheckNoThreshold:
	.incbin "includes/generated/v7_transplant_VelocityUpdate_CheckNoThreshold.bin"
VelocityUpdate_SetTimerValue:
	.incbin "includes/generated/v7_transplant_VelocityUpdate_SetTimerValue.bin"
Voice_CheckAndUpdateSlot:
	.incbin "includes/generated/v7_transplant_Voice_CheckAndUpdateSlot.bin"
VelocityUpdate_Return:
	.incbin "includes/generated/v7_transplant_VelocityUpdate_Return.bin"
Voice_SetDecayTimer:
	.incbin "includes/generated/v7_transplant_Voice_SetDecayTimer.bin"
DecayTimer_SetShort:
	.incbin "includes/generated/v7_transplant_DecayTimer_SetShort.bin"
DecayTimer_SetLong:
	.incbin "includes/generated/v7_transplant_DecayTimer_SetLong.bin"
DecayTimer_Return:
	.incbin "includes/generated/v7_transplant_DecayTimer_Return.bin"
Voice_MatchVoicePairs:
	.incbin "includes/generated/v7_transplant_Voice_MatchVoicePairs.bin"
VoicePair_OuterLoop:
	.incbin "includes/generated/v7_transplant_VoicePair_OuterLoop.bin"
VoicePair_InnerScan:
	.incbin "includes/generated/v7_transplant_VoicePair_InnerScan.bin"
VoicePair_AdvanceOuter:
	.incbin "includes/generated/v7_transplant_VoicePair_AdvanceOuter.bin"
VoicePair_Return:
	.incbin "includes/generated/v7_transplant_VoicePair_Return.bin"
Voice_CheckAndResetSlotState:
	.incbin "includes/generated/v7_transplant_Voice_CheckAndResetSlotState.bin"
CheckAndResetSlotSta_Block:
	.incbin "includes/generated/v7_transplant_CheckAndResetSlotSta_Block.bin"
CheckAndResetSlotSta_LoadDRAM:
	.incbin "includes/generated/v7_transplant_CheckAndResetSlotSta_LoadDRAM.bin"
CheckAndResetSlotSta_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_CheckAndResetSlotSta_LoadDRAM2.bin"
CheckAndResetSlotSta_Block2:
	.incbin "includes/generated/v7_transplant_CheckAndResetSlotSta_Block2.bin"
Voice_NullRet2:
	.incbin "includes/generated/v7_transplant_Voice_NullRet2.bin"
NullRet2_Block:
	.incbin "includes/generated/v7_transplant_NullRet2_Block.bin"
NullRet2_Data:
	.incbin "includes/generated/v7_transplant_NullRet2_Data.bin"
NullRet2_TestBit24:
	.incbin "includes/generated/v7_transplant_NullRet2_TestBit24.bin"
NullRet2_Block2:
	.incbin "includes/generated/v7_transplant_NullRet2_Block2.bin"
EffectState_Dispatch:
	.incbin "includes/generated/v7_transplant_EffectState_Dispatch.bin"
EffectState_Dispatch_Block:
	.incbin "includes/generated/v7_transplant_EffectState_Dispatch_Block.bin"
EffectState_Dispatch_Block2:
	.incbin "includes/generated/v7_transplant_EffectState_Dispatch_Block2.bin"
EffectState_Dispatch_Block3:
	.incbin "includes/generated/v7_transplant_EffectState_Dispatch_Block3.bin"
VoiceSlot_StoreParams:

VoiceSlot_StoreParams_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Block.bin"
VoiceSlot_StoreParams_Block2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Block2.bin"
VoiceSlot_StoreParams_OrBits:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_OrBits.bin"
VoiceSlot_StoreParams_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_LoadReg.bin"
VoiceSlot_StoreParams_Decrement:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Decrement.bin"
VoiceSlot_StoreParams_Block3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Block3.bin"
VoiceSlot_StoreParams_LoadReg2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_LoadReg2.bin"
VoiceSlot_StoreParams_Return:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Return.bin"
VoiceSlot_StoreParams_LoadReg3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_LoadReg3.bin"
VoiceSlot_StoreParams_LoadReg4:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_LoadReg4.bin"
VoiceSlot_StoreParams_Increment:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Increment.bin"
VoiceSlot_StoreParams_LoadReg5:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_LoadReg5.bin"
VoiceSlot_StoreParams_Data:
	.incbin "includes/generated/v7_transplant_VoiceSlot_StoreParams_Data.bin"
Voice_ComputeNoteBitPosition:
	.incbin "includes/generated/v7_transplant_Voice_ComputeNoteBitPosition.bin"
ComputeNoteBitPositi_Prologue:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_Prologue.bin"
ComputeNoteBitPositi_Data:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_Data.bin"
ComputeNoteBitPositi_StoreDRAM:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_StoreDRAM.bin"
ComputeNoteBitPositi_Block:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_Block.bin"
ComputeNoteBitPositi_TestBit9:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_TestBit9.bin"
ComputeNoteBitPositi_Compare:
	.incbin "includes/generated/v7_transplant_ComputeNoteBitPositi_Compare.bin"
Voice_DecrementCounter:
	.incbin "includes/generated/v7_transplant_Voice_DecrementCounter.bin"
PitchCalc_FindBitPosition:

PitchCalc_FindBitPosition_Increment:
	.incbin "includes/generated/v7_transplant_PitchCalc_FindBitPosition_Increment.bin"
PitchCalc_FindBitPosition_TestBit11:
	.incbin "includes/generated/v7_transplant_PitchCalc_FindBitPosition_TestBit11.bin"
PitchCalc_FindBitPosition_OrBits:
	.incbin "includes/generated/v7_transplant_PitchCalc_FindBitPosition_OrBits.bin"
Voice_PitchCalcStep:
	.incbin "includes/generated/v7_transplant_Voice_PitchCalcStep.bin"
PitchCalcStep_ClearByte:
	.incbin "includes/generated/v7_transplant_PitchCalcStep_ClearByte.bin"
PitchCalc_Return:

PitchCalc_Return_Return:
	.incbin "includes/generated/v7_transplant_PitchCalc_Return_Return.bin"
PitchCalc_Return_Block:
	.incbin "includes/generated/v7_transplant_PitchCalc_Return_Block.bin"
PitchCalc_Return_Block2:
	.incbin "includes/generated/v7_transplant_PitchCalc_Return_Block2.bin"
PitchCalc_Return_Block3:
	.incbin "includes/generated/v7_transplant_PitchCalc_Return_Block3.bin"
VoiceSlot_CompareAndUpdate:

VoiceSlot_CompareAndUpdate_Compare:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Compare.bin"
VoiceSlot_CompareAndUpdate_TestBit24:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_TestBit24.bin"
VoiceSlot_CompareAndUpdate_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Block.bin"
VoiceSlot_CompareAndUpdate_Block2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Block2.bin"
VoiceSlot_CompareAndUpdate_Block3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Block3.bin"
VoiceSlot_CompareAndUpdate_Block4:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Block4.bin"
VoiceSlot_CompareAndUpdate_Return:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CompareAndUpdate_Return.bin"
Voice_UpdateNoteBitmap:
	.incbin "includes/generated/v7_transplant_Voice_UpdateNoteBitmap.bin"
UpdateNoteBitmap_ClearByte:
	.incbin "includes/generated/v7_transplant_UpdateNoteBitmap_ClearByte.bin"
VoiceSlot_LoadResult:

VoiceSlot_LoadResult_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_LoadReg.bin"
VoiceSlot_LoadResult_Data:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Data.bin"
VoiceSlot_LoadResult_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block.bin"
VoiceSlot_LoadResult_SetByte:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_SetByte.bin"
VoiceSlot_LoadResult_Block2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block2.bin"
VoiceSlot_LoadResult_Data2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Data2.bin"
VoiceSlot_LoadResult_Block3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block3.bin"
VoiceSlot_LoadResult_TestBit24:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_TestBit24.bin"
VoiceSlot_LoadResult_Block4:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block4.bin"
VoiceSlot_LoadResult_Compare:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Compare.bin"
VoiceSlot_LoadResult_Block5:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block5.bin"
VoiceSlot_LoadResult_Block6:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block6.bin"
VoiceSlot_LoadResult_Block7:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block7.bin"
VoiceSlot_LoadResult_Block8:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block8.bin"
VoiceSlot_LoadResult_Block9:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block9.bin"
VoiceSlot_LoadResult_Block10:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block10.bin"
VoiceSlot_LoadResult_Block11:
	.incbin "includes/generated/v7_transplant_VoiceSlot_LoadResult_Block11.bin"
Audio_NullRet2:
	.incbin "includes/generated/v7_transplant_Audio_NullRet2.bin"
Audio_NullRet2_Prologue:
	.incbin "includes/generated/v7_transplant_Audio_NullRet2_Prologue.bin"
Audio_NullRet2_LoopBody:
	.incbin "includes/generated/v7_transplant_Audio_NullRet2_LoopBody.bin"
Audio_NullRet2_LoopCheck:
	.incbin "includes/generated/v7_transplant_Audio_NullRet2_LoopCheck.bin"
Voice_ProcessSlotEntry:
	.incbin "includes/generated/v7_transplant_Voice_ProcessSlotEntry.bin"
ProcessSlotEntry_Block:
	.incbin "includes/generated/v7_transplant_ProcessSlotEntry_Block.bin"
ProcessSlotEntry_Block2:
	.incbin "includes/generated/v7_transplant_ProcessSlotEntry_Block2.bin"
Audio_PopIzRet:
	.incbin "includes/generated/v7_transplant_Audio_PopIzRet.bin"
VoiceSlot_CheckPitchIntervals:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitchIntervals.bin"
VoiceSlot_CheckPitch_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_LoadReg.bin"
VoiceSlot_CheckPitch_LoadReg2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_LoadReg2.bin"
VoiceSlot_CheckPitch_Compare:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_Compare.bin"
VoiceSlot_CheckPitch_Compare2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_Compare2.bin"
VoiceSlot_CheckPitch_Compare3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_Compare3.bin"
VoiceSlot_CheckPitch_OrBits:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_OrBits.bin"
VoiceSlot_CheckPitch_OrBits2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckPitch_OrBits2.bin"
NoteBuffer_CompactEntries:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEntries.bin"
NoteBuffer_CompactEn_LoadReg:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_LoadReg.bin"
NoteBuffer_CompactEn_Block:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Block.bin"
NoteBuffer_CompactEn_LoadReg2:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_LoadReg2.bin"
NoteBuffer_CompactEn_Epilogue:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Epilogue.bin"
NoteBuffer_CompactEn_Data:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Data.bin"
NoteBuffer_CompactEn_Block2:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Block2.bin"
NoteBuffer_CompactEn_Compare:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Compare.bin"
NoteBuffer_CompactEn_Increment:
	.incbin "includes/generated/v7_transplant_NoteBuffer_CompactEn_Increment.bin"
NoteBuffer_NullRet:
	.incbin "includes/generated/v7_transplant_NoteBuffer_NullRet.bin"
Voice_LookupNoteAndComputePitch:
	.incbin "includes/generated/v7_transplant_Voice_LookupNoteAndComputePitch.bin"
LookupNoteAndCompute_Block:
	.incbin "includes/generated/v7_transplant_LookupNoteAndCompute_Block.bin"
LookupNoteAndCompute_Prologue:
	.incbin "includes/generated/v7_transplant_LookupNoteAndCompute_Prologue.bin"
NoteDisplay_LookupEntry:
	.incbin "includes/generated/v7_transplant_NoteDisplay_LookupEntry.bin"
NoteDisplay_SetBounds:
	.incbin "includes/generated/v7_transplant_NoteDisplay_SetBounds.bin"
NoteDisplay_ScanLoop:
	.incbin "includes/generated/v7_transplant_NoteDisplay_ScanLoop.bin"
NoteDisplay_FoundEntry:
	.incbin "includes/generated/v7_transplant_NoteDisplay_FoundEntry.bin"
NoteDisplay_NotFound:
	.incbin "includes/generated/v7_transplant_NoteDisplay_NotFound.bin"
NoteDisplay_StoreBoundsReturn:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreBoundsReturn.bin"
NoteDisplay_AlternateLookup:
	.incbin "includes/generated/v7_transplant_NoteDisplay_AlternateLookup.bin"
Voice_ZeroInitConverge:
	.incbin "includes/generated/v7_transplant_Voice_ZeroInitConverge.bin"
NoteDisplay_AltReturn:
	.incbin "includes/generated/v7_transplant_NoteDisplay_AltReturn.bin"
NoteDisplay_ClearAndSetUpdate:
	.incbin "includes/generated/v7_transplant_NoteDisplay_ClearAndSetUpdate.bin"
NoteDisplay_ClearReturn:
	.incbin "includes/generated/v7_transplant_NoteDisplay_ClearReturn.bin"
NoteDisplay_InitState:
	.incbin "includes/generated/v7_transplant_NoteDisplay_InitState.bin"
NoteDisplay_LookupBitmap:
	.incbin "includes/generated/v7_transplant_NoteDisplay_LookupBitmap.bin"
NoteDisplay_LookupFromCurrent:
	.incbin "includes/generated/v7_transplant_NoteDisplay_LookupFromCurrent.bin"
NoteDisplay_LookupFromTable:
	.incbin "includes/generated/v7_transplant_NoteDisplay_LookupFromTable.bin"
NoteDisplay_StoreNoCurrent:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreNoCurrent.bin"
NoteDisplay_SetUpdateFlags:
	.incbin "includes/generated/v7_transplant_NoteDisplay_SetUpdateFlags.bin"
NoteDisplay_SameNote:
	.incbin "includes/generated/v7_transplant_NoteDisplay_SameNote.bin"
NoteDisplay_ClearBoth:
	.incbin "includes/generated/v7_transplant_NoteDisplay_ClearBoth.bin"
NoteDisplay_SetOverlayFlags:
	.incbin "includes/generated/v7_transplant_NoteDisplay_SetOverlayFlags.bin"
VoiceSlot_Epilogue:

VoiceSlot_Epilogue_Epilogue:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Epilogue_Epilogue.bin"
VoiceSlot_Epilogue_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Epilogue_Block.bin"
VoiceSlot_Epilogue_Block2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_Epilogue_Block2.bin"
Voice_InitPartAllocState:
	.incbin "includes/generated/v7_transplant_Voice_InitPartAllocState.bin"
InitPartAllocState_Block:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Block.bin"
InitPartAllocState_Block2:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Block2.bin"
InitPartAllocState_TestBit24:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_TestBit24.bin"
InitPartAllocState_Block3:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Block3.bin"
InitPartAllocState_Epilogue:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Epilogue.bin"
InitPartAllocState_Block4:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Block4.bin"
InitPartAllocState_TestBit242:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_TestBit242.bin"
InitPartAllocState_Increment:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Increment.bin"
InitPartAllocState_Return:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Return.bin"
InitPartAllocState_OrBits:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_OrBits.bin"
InitPartAllocState_Block5:
	.incbin "includes/generated/v7_transplant_InitPartAllocState_Block5.bin"
VoiceSlot_SetPitchParams:

VoiceSlot_SetPitchParams_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_SetPitchParams_LoadReg.bin"
VoiceSlot_SetPitchParams_TestBit24:
	.incbin "includes/generated/v7_transplant_VoiceSlot_SetPitchParams_TestBit24.bin"
VoiceSlot_SetPitchParams_LoadFromStack:
	.incbin "includes/generated/v7_transplant_VoiceSlot_SetPitchParams_LoadFromStack.bin"
VoiceSlot_SetPitchParams_Compare:
	.incbin "includes/generated/v7_transplant_VoiceSlot_SetPitchParams_Compare.bin"
VoiceSlot_SetPitchParams_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_SetPitchParams_Block.bin"
VoiceSlot_IterateAlloc:

VoiceSlot_IterateAlloc_NextIter:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_NextIter.bin"
VoiceSlot_IterateAlloc_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block.bin"
VoiceSlot_IterateAlloc_LoadFromStack:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_LoadFromStack.bin"
VoiceSlot_IterateAlloc_Return:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Return.bin"
VoiceSlot_IterateAlloc_Block2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block2.bin"
VoiceSlot_IterateAlloc_Block3:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block3.bin"
VoiceSlot_IterateAlloc_Block4:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block4.bin"
VoiceSlot_IterateAlloc_SetByte:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_SetByte.bin"
VoiceSlot_IterateAlloc_Return2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Return2.bin"
VoiceSlot_IterateAlloc_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_LoadReg.bin"
VoiceSlot_IterateAlloc_LoadReg2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_LoadReg2.bin"
VoiceSlot_IterateAlloc_TestBit24:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_TestBit24.bin"
VoiceSlot_IterateAlloc_StoreDRAM:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_StoreDRAM.bin"
VoiceSlot_IterateAlloc_StoreDRAM2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_StoreDRAM2.bin"
VoiceSlot_IterateAlloc_Block5:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block5.bin"
VoiceSlot_IterateAlloc_Block6:
	.incbin "includes/generated/v7_transplant_VoiceSlot_IterateAlloc_Block6.bin"
VoiceSlot_CheckAndApply:

VoiceSlot_CheckAndApply_DoCheckDis:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_DoCheckDis.bin"
VoiceSlot_CheckAndApply_Return:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Return.bin"
VoiceSlot_CheckAndApply_Data:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Data.bin"
VoiceSlot_CheckAndApply_LoadReg:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_LoadReg.bin"
VoiceSlot_CheckAndApply_Data2:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Data2.bin"
VoiceSlot_CheckAndApply_Prologue:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Prologue.bin"
VoiceSlot_CheckAndApply_Compare:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Compare.bin"
VoiceSlot_CheckAndApply_Increment:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Increment.bin"
VoiceSlot_CheckAndApply_Block:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Block.bin"
VoiceSlot_CheckAndApply_Epilogue:
	.incbin "includes/generated/v7_transplant_VoiceSlot_CheckAndApply_Epilogue.bin"
NoteDisplay_StoreAndDispatch:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAndDispatch.bin"
NoteDisplay_StoreAnd_LoadReg:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_LoadReg.bin"
NoteDisplay_StoreAnd_LoadReg2:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_LoadReg2.bin"
NoteDisplay_StoreAnd_LoadDRAM:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_LoadDRAM.bin"
NoteDisplay_StoreAnd_DoLookupBi:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_DoLookupBi.bin"
NoteDisplay_StoreAnd_DoUpdateNo:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_DoUpdateNo.bin"
NoteDisplay_StoreAnd_Block:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_Block.bin"
NoteDisplay_StoreAnd_LoadReg3:
	.incbin "includes/generated/v7_transplant_NoteDisplay_StoreAnd_LoadReg3.bin"
MIDI_FinalizeParamBlock:
	.incbin "includes/generated/v7_transplant_MIDI_FinalizeParamBlock.bin"
SndParam_Init:
	.incbin "includes/generated/v7_transplant_SndParam_Init.bin"
UIState_ProcessKeyEvent:
	.incbin "includes/generated/v7_transplant_UIState_ProcessKeyEvent.bin"
SndParam_ProcessEntry:
	.incbin "includes/generated/v7_transplant_SndParam_ProcessEntry.bin"
HdaeRom_Entry:
	.incbin "includes/generated/v7_transplant_HdaeRom_Entry.bin"
HdaeRom_ProcessBlock:
	.incbin "includes/generated/v7_transplant_HdaeRom_ProcessBlock.bin"
HdaeRom_ReadParam:
	.incbin "includes/generated/v7_transplant_HdaeRom_ReadParam.bin"
HdaeRom_WriteParam:
	.incbin "includes/generated/v7_transplant_HdaeRom_WriteParam.bin"
HdaeRom_CheckResult:
	.incbin "includes/generated/v7_transplant_HdaeRom_CheckResult.bin"
HdaeRom_FinishBlock:
	.incbin "includes/generated/v7_transplant_HdaeRom_FinishBlock.bin"
HdaeRom_TableEntry0:
	.incbin "includes/generated/v7_transplant_HdaeRom_TableEntry0.bin"
HdaeRom_TableEntry1:
	.incbin "includes/generated/v7_transplant_HdaeRom_TableEntry1.bin"
HdaeRom_TableEntry2:
	.incbin "includes/generated/v7_transplant_HdaeRom_TableEntry2.bin"
HdaeRom_AltEntry:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltEntry.bin"
UIStateEvt_ProcessHandler:
	.incbin "includes/generated/v7_transplant_UIStateEvt_ProcessHandler.bin"
HdaeRom_AltProcessBlock:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltProcessBlock.bin"
HdaeRom_AltReadParam:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltReadParam.bin"
HdaeRom_AltCheckResult:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltCheckResult.bin"
HdaeRom_AltTableEntry0:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry0.bin"
HdaeRom_AltTableEntry1:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry1.bin"
HdaeRom_AltTableEntry2:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry2.bin"
HdaeRom_AltTableEntry3:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry3.bin"
HdaeRom_AltTableEntry4:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry4.bin"
HdaeRom_AltTableEntry5:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry5.bin"
HdaeRom_AltTableEntry6:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry6.bin"
HdaeRom_AltTableEntry7:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry7.bin"
HdaeRom_AltTableEntry8:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry8.bin"
HdaeRom_AltTableEntry9:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltTableEntry9.bin"
SndPart_SetParam:
	.incbin "includes/generated/v7_transplant_SndPart_SetParam.bin"
SndPart_SetProgramMSB:
	.incbin "includes/generated/v7_transplant_SndPart_SetProgramMSB.bin"
SndPart_SetModWheel:
	.incbin "includes/generated/v7_transplant_SndPart_SetModWheel.bin"
SndPart_SetVolume:
	.incbin "includes/generated/v7_transplant_SndPart_SetVolume.bin"
SndPart_SetVolume_LoadReg:
	.incbin "includes/generated/v7_transplant_SndPart_SetVolume_LoadReg.bin"
SndPart_SetPan:
	.incbin "includes/generated/v7_transplant_SndPart_SetPan.bin"
SndPart_SetExpression:
	.incbin "includes/generated/v7_transplant_SndPart_SetExpression.bin"
SndPart_SetDamperPedal:
	.incbin "includes/generated/v7_transplant_SndPart_SetDamperPedal.bin"
SndPart_SetDamperPed_LoadReg:
	.incbin "includes/generated/v7_transplant_SndPart_SetDamperPed_LoadReg.bin"
SndPart_SetPitchBendRange:
	.incbin "includes/generated/v7_transplant_SndPart_SetPitchBendRange.bin"
SndPart_SetReverbSend:
	.incbin "includes/generated/v7_transplant_SndPart_SetReverbSend.bin"
SndPart_SetChorusSend:
	.incbin "includes/generated/v7_transplant_SndPart_SetChorusSend.bin"
SndPart_SetDelaySend:
	.incbin "includes/generated/v7_transplant_SndPart_SetDelaySend.bin"
SndPart_SetBankMSB:
	.incbin "includes/generated/v7_transplant_SndPart_SetBankMSB.bin"
SndPart_SetBankLSB:
	.incbin "includes/generated/v7_transplant_SndPart_SetBankLSB.bin"
SndPart_SetBankSelect:
	.incbin "includes/generated/v7_transplant_SndPart_SetBankSelect.bin"
SndPart_SetRPN:
	.incbin "includes/generated/v7_transplant_SndPart_SetRPN.bin"
SndPart_SetFineTune:
	.incbin "includes/generated/v7_transplant_SndPart_SetFineTune.bin"
SndPart_SetFineTune_LoadReg:
	.incbin "includes/generated/v7_transplant_SndPart_SetFineTune_LoadReg.bin"
SndPart_SetCoarseTune:
	.incbin "includes/generated/v7_transplant_SndPart_SetCoarseTune.bin"
SndPart_SetCoarseTun_LoadReg:
	.incbin "includes/generated/v7_transplant_SndPart_SetCoarseTun_LoadReg.bin"
SndPart_SetPitchBendSens:
	.incbin "includes/generated/v7_transplant_SndPart_SetPitchBendSens.bin"
SndPart_SetAllSoundOff:
	.incbin "includes/generated/v7_transplant_SndPart_SetAllSoundOff.bin"
MIDI_SendEpilogue:
	.incbin "includes/generated/v7_transplant_MIDI_SendEpilogue.bin"
SendEpilogue_Data:
	.incbin "includes/generated/v7_transplant_SendEpilogue_Data.bin"
Song_SendPartDataBlocks:
	.incbin "includes/generated/v7_transplant_Song_SendPartDataBlocks.bin"
SendPartDataBlocks_LoadDRAM:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadDRAM.bin"
SendPartDataBlocks_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadDRAM2.bin"
SendPartDataBlocks_LoadDRAM3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadDRAM3.bin"
SendPartDataBlocks_LoadDRAM4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadDRAM4.bin"
SendPartDataBlocks_Block:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_Block.bin"
SendPartDataBlocks_Block2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_Block2.bin"
SendPartDataBlocks_Block3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_Block3.bin"
SendPartDataBlocks_Block4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_Block4.bin"
SendPartDataBlocks_InitVal:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_InitVal.bin"
SendPartDataBlocks_LoadIter:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadIter.bin"
SendPartDataBlocks_LoadIter2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadIter2.bin"
SendPartDataBlocks_LoadReg:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadReg.bin"
SendPartDataBlocks_LoadIter3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_LoadIter3.bin"
SendPartDataBlocks_NextIter:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_NextIter.bin"
SendPartDataBlocks_Send:
	.incbin "includes/generated/v7_transplant_SendPartDataBlocks_Send.bin"
COMM_SendDataReturn:
	.incbin "includes/generated/v7_transplant_COMM_SendDataReturn.bin"
SendDataReturn_LoadReg:
	.incbin "includes/generated/v7_transplant_SendDataReturn_LoadReg.bin"
MIDI_SendControlChange:
	.incbin "includes/generated/v7_transplant_MIDI_SendControlChange.bin"
MIDI_SendPitchBend:
	.incbin "includes/generated/v7_transplant_MIDI_SendPitchBend.bin"
MIDI_SendChannelPressure:
	.incbin "includes/generated/v7_transplant_MIDI_SendChannelPressure.bin"
SendChannelPressure_Prologue:
	.incbin "includes/generated/v7_transplant_SendChannelPressure_Prologue.bin"
SendChannelPressure_InitVal:
	.incbin "includes/generated/v7_transplant_SendChannelPressure_InitVal.bin"
SendChannelPressure_LoadReg:
	.incbin "includes/generated/v7_transplant_SendChannelPressure_LoadReg.bin"
SendChannelPressure_LoadParam:
	.incbin "includes/generated/v7_transplant_SendChannelPressure_LoadParam.bin"
SeqVoice_CheckAndRetry:
	.incbin "includes/generated/v7_transplant_SeqVoice_CheckAndRetry.bin"
SeqVoice_CheckAndRet_Compare:
	.incbin "includes/generated/v7_transplant_SeqVoice_CheckAndRet_Compare.bin"
SeqVoice_CheckAndRet_RestoreReg:
	.incbin "includes/generated/v7_transplant_SeqVoice_CheckAndRet_RestoreReg.bin"
SeqVoice_CheckAndRet_Prologue:
	.incbin "includes/generated/v7_transplant_SeqVoice_CheckAndRet_Prologue.bin"
SeqVoice_CheckAndRet_Data:
	.incbin "includes/generated/v7_transplant_SeqVoice_CheckAndRet_Data.bin"
MIDI_SendSysExCmd:
	.incbin "includes/generated/v7_transplant_MIDI_SendSysExCmd.bin"
SendSysExCmd_Data:
	.incbin "includes/generated/v7_transplant_SendSysExCmd_Data.bin"
COMM_WriteAndCheck:
	.incbin "includes/generated/v7_transplant_COMM_WriteAndCheck.bin"
WriteAndCheck_LoadParam:
	.incbin "includes/generated/v7_transplant_WriteAndCheck_LoadParam.bin"
MIDI_SendPartVolumes_Loop:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVolumes_Loop.bin"
MIDI_SendPartVol_LookupFallback:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVol_LookupFallback.bin"
MIDI_SendPartVol_StoreAndSend:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVol_StoreAndSend.bin"
MIDI_SendPartVol_ExtraParts:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVol_ExtraParts.bin"
MIDI_SendPartVol_ExtraLookup:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVol_ExtraLookup.bin"
MIDI_SendPartVol_ExtraSend:
	.incbin "includes/generated/v7_transplant_MIDI_SendPartVol_ExtraSend.bin"
MIDI_BroadcastPitchReset:
	.incbin "includes/generated/v7_transplant_MIDI_BroadcastPitchReset.bin"
PitchReset_ShiftAndOr:
	.incbin "includes/generated/v7_transplant_PitchReset_ShiftAndOr.bin"
PitchReset_ChannelLoop:
	.incbin "includes/generated/v7_transplant_PitchReset_ChannelLoop.bin"
PitchReset_CheckExtChannels:
	.incbin "includes/generated/v7_transplant_PitchReset_CheckExtChannels.bin"
PitchReset_ExtChannelLoop:
	.incbin "includes/generated/v7_transplant_PitchReset_ExtChannelLoop.bin"
PitchReset_Flush:
	.incbin "includes/generated/v7_transplant_PitchReset_Flush.bin"
MIDI_PitchBendData_Block:
	.incbin "includes/generated/v7_transplant_MIDI_PitchBendData_Block.bin"
MIDI_SendAllSoundOff:
	.incbin "includes/generated/v7_transplant_MIDI_SendAllSoundOff.bin"
SendAllSoundOff_Loop:
	.incbin "includes/generated/v7_transplant_SendAllSoundOff_Loop.bin"
SendAllSoundOff_Flush:
	.incbin "includes/generated/v7_transplant_SendAllSoundOff_Flush.bin"
MIDI_WriteChannelData_Block:
	.incbin "includes/generated/v7_transplant_MIDI_WriteChannelData_Block.bin"
MIDI_SendCmdPacket:
	.incbin "includes/generated/v7_transplant_MIDI_SendCmdPacket.bin"
SendCmdPacket_Loop:
	.incbin "includes/generated/v7_transplant_SendCmdPacket_Loop.bin"
SendCmdPacket_CheckCount:
	.incbin "includes/generated/v7_transplant_SendCmdPacket_CheckCount.bin"
MIDI_PostSendStub:
	.incbin "includes/generated/v7_transplant_MIDI_PostSendStub.bin"
SeqState_GetFlags:
	.incbin "includes/generated/v7_transplant_SeqState_GetFlags.bin"
MIDI_OutputFlush:
	.incbin "includes/generated/v7_transplant_MIDI_OutputFlush.bin"
OutputFlush_DoVoiceSta:
	.incbin "includes/generated/v7_transplant_OutputFlush_DoVoiceSta.bin"
OutputFlush_RestoreReg:
	.incbin "includes/generated/v7_transplant_OutputFlush_RestoreReg.bin"
OutputFlush_Prologue:
	.incbin "includes/generated/v7_transplant_OutputFlush_Prologue.bin"
OutputFlush_LoadDRAM:
	.incbin "includes/generated/v7_transplant_OutputFlush_LoadDRAM.bin"
OutputFlush_InitVal:
	.incbin "includes/generated/v7_transplant_OutputFlush_InitVal.bin"
AccSong_ProcessRecord_Loop:
	.incbin "includes/generated/v7_transplant_AccSong_ProcessRecord_Loop.bin"
AccSong_ProcessRecord_LoadDRAM:
	.incbin "includes/generated/v7_transplant_AccSong_ProcessRecord_LoadDRAM.bin"
AccSong_ProcessRecord_LoadReg:
	.incbin "includes/generated/v7_transplant_AccSong_ProcessRecord_LoadReg.bin"
AccSong_ProcessRecord_LoadReg2:
	.incbin "includes/generated/v7_transplant_AccSong_ProcessRecord_LoadReg2.bin"
AccSong_ProcessRecord_InitVal:
	.incbin "includes/generated/v7_transplant_AccSong_ProcessRecord_InitVal.bin"
Acc_PopIzRet:
	.incbin "includes/generated/v7_transplant_Acc_PopIzRet.bin"
Acc_LoadAndStartPlayback:
	.incbin "includes/generated/v7_transplant_Acc_LoadAndStartPlayback.bin"
LoadAndStartPlayback_LoadParam:
	.incbin "includes/generated/v7_transplant_LoadAndStartPlayback_LoadParam.bin"
LoadAndStartPlayback_LoadParam2:
	.incbin "includes/generated/v7_transplant_LoadAndStartPlayback_LoadParam2.bin"
LoadAndStartPlayback_LoadParam3:
	.incbin "includes/generated/v7_transplant_LoadAndStartPlayback_LoadParam3.bin"
SeqVoice_PopIzReturn:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn.bin"
SeqVoice_PopIzReturn_Compare:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Compare.bin"
SeqVoice_PopIzReturn_Block:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Block.bin"
SeqVoice_PopIzReturn_Block2:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Block2.bin"
SeqVoice_PopIzReturn_Return:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Return.bin"
SeqVoice_PopIzReturn_Prologue:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Prologue.bin"
SeqVoice_PopIzReturn_Block3:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Block3.bin"
SeqVoice_PopIzReturn_Block4:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Block4.bin"
SeqVoice_PopIzReturn_Block5:
	.incbin "includes/generated/v7_transplant_SeqVoice_PopIzReturn_Block5.bin"
SwbtWr_ReinitOutputBank_Wrapper:
	.incbin "includes/generated/v7_transplant_SwbtWr_ReinitOutputBank_Wrapper.bin"
Song_AbortPlayback:
	.incbin "includes/generated/v7_transplant_Song_AbortPlayback.bin"
FileIO_ReadChunk:
	.incbin "includes/generated/v7_transplant_FileIO_ReadChunk.bin"
ReadChunk_LoadParam:
	.incbin "includes/generated/v7_transplant_ReadChunk_LoadParam.bin"
ReadChunk_LoadParam2:
	.incbin "includes/generated/v7_transplant_ReadChunk_LoadParam2.bin"
ReadChunk_RestoreReg:
	.incbin "includes/generated/v7_transplant_ReadChunk_RestoreReg.bin"
Acc_TransitionPlayMode:
	.incbin "includes/generated/v7_transplant_Acc_TransitionPlayMode.bin"
TransitionPlayMode_Block:
	.incbin "includes/generated/v7_transplant_TransitionPlayMode_Block.bin"
Acc_StopPlayMode:
	.incbin "includes/generated/v7_transplant_Acc_StopPlayMode.bin"
Acc_StartFillIn:
	.incbin "includes/generated/v7_transplant_Acc_StartFillIn.bin"
StartFillIn_Data:
	.incbin "includes/generated/v7_transplant_StartFillIn_Data.bin"
FileIO_ReadMultiByteRecord:
	.incbin "includes/generated/v7_transplant_FileIO_ReadMultiByteRecord.bin"
ReadMultiByteRecord_TestBit7:
	.incbin "includes/generated/v7_transplant_ReadMultiByteRecord_TestBit7.bin"
ReadMultiByteRecord_Block:
	.incbin "includes/generated/v7_transplant_ReadMultiByteRecord_Block.bin"
ReadMultiByteRecord_LoadReg:
	.incbin "includes/generated/v7_transplant_ReadMultiByteRecord_LoadReg.bin"
ReadMultiByteRecord_LoadReg2:
	.incbin "includes/generated/v7_transplant_ReadMultiByteRecord_LoadReg2.bin"
ReadMultiByteRecord_Epilogue:
	.incbin "includes/generated/v7_transplant_ReadMultiByteRecord_Epilogue.bin"
FileIO_ReadVariableLengthData:
	.incbin "includes/generated/v7_transplant_FileIO_ReadVariableLengthData.bin"
ReadVariableLengthDa_LoadParam:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_LoadParam.bin"
ReadVariableLengthDa_DoReadNext:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_DoReadNext.bin"
ReadVariableLengthDa_LoadParam2:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_LoadParam2.bin"
ReadVariableLengthDa_LoadParam3:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_LoadParam3.bin"
ReadVariableLengthDa_Epilogue:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_Epilogue.bin"
ReadVariableLengthDa_Prologue:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_Prologue.bin"
ReadVariableLengthDa_LoopBody:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_LoopBody.bin"
ReadVariableLengthDa_LoopCheck:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_LoopCheck.bin"
ReadVariableLengthDa_InitVal:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_InitVal.bin"
ReadVariableLengthDa_RestoreReg:
	.incbin "includes/generated/v7_transplant_ReadVariableLengthDa_RestoreReg.bin"
AccWrap_PlayModeStateMachine:
	.incbin "includes/generated/v7_transplant_AccWrap_PlayModeStateMachine.bin"
PlayModeStateMachine_Block:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Block.bin"
PlayModeStateMachine_Block2:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Block2.bin"
PlayModeStateMachine_DoPlayMode:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_DoPlayMode.bin"
PlayModeStateMachine_TestBit2:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_TestBit2.bin"
PlayModeStateMachine_Block3:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Block3.bin"
PlayModeStateMachine_DoPlayMode2:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_DoPlayMode2.bin"
PlayModeStateMachine_Block4:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Block4.bin"
PlayModeStateMachine_TestBit22:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_TestBit22.bin"
PlayModeStateMachine_Block5:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Block5.bin"
PlayModeStateMachine_Prologue:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_Prologue.bin"
PlayModeStateMachine_LoadParam:
	.incbin "includes/generated/v7_transplant_PlayModeStateMachine_LoadParam.bin"
SeqPlay_BusyWaitLoop:
	.incbin "includes/generated/v7_transplant_SeqPlay_BusyWaitLoop.bin"
MIDI_ResetAllChannels:
	.incbin "includes/generated/v7_transplant_MIDI_ResetAllChannels.bin"
ResetAllChannels_LoadIdx:
	.incbin "includes/generated/v7_transplant_ResetAllChannels_LoadIdx.bin"
ResetAllChannels_RestoreReg:
	.incbin "includes/generated/v7_transplant_ResetAllChannels_RestoreReg.bin"
MIDI_SendSinglePacket:
	.incbin "includes/generated/v7_transplant_MIDI_SendSinglePacket.bin"
SendSinglePacket_LoadReg:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_LoadReg.bin"
SendSinglePacket_DoGetPlayS:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_DoGetPlayS.bin"
SendSinglePacket_Epilogue:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Epilogue.bin"
SendSinglePacket_Data:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Data.bin"
SendSinglePacket_WriteReg:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_WriteReg.bin"
SendSinglePacket_DoReadNext:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_DoReadNext.bin"
SendSinglePacket_Block:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Block.bin"
SendSinglePacket_Block2:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Block2.bin"
SendSinglePacket_DoReadNext2:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_DoReadNext2.bin"
SendSinglePacket_Increment:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Increment.bin"
SendSinglePacket_Block3:
	.incbin "includes/generated/v7_transplant_SendSinglePacket_Block3.bin"
SeqFile_SkipHeaderBytes_Loop:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipHeaderBytes_Loop.bin"
SeqFile_SkipHeaderBytes_Next:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipHeaderBytes_Next.bin"
SeqFile_ReadMagicInit:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadMagicInit.bin"
SeqFile_ReadMagicByte_Loop:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadMagicByte_Loop.bin"
SeqFile_CheckMagicByte:
	.incbin "includes/generated/v7_transplant_SeqFile_CheckMagicByte.bin"
SeqFile_ValidateMagicCount:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateMagicCount.bin"
SeqFile_SkipPadding_Init:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipPadding_Init.bin"
SeqFile_SkipPadding_Loop:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipPadding_Loop.bin"
SeqFile_SkipPadding_Next:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipPadding_Next.bin"
SeqFile_ReadFormatByte:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadFormatByte.bin"
SeqFile_ValidateFormat:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateFormat.bin"
SeqFile_ReadTempoByte1:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTempoByte1.bin"
SeqFile_StoreTempoByte1:
	.incbin "includes/generated/v7_transplant_SeqFile_StoreTempoByte1.bin"
SeqFile_ReadTempoByte2:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTempoByte2.bin"
SeqFile_ReadDivisionByte1:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadDivisionByte1.bin"
SeqFile_StoreDivisionByte1:
	.incbin "includes/generated/v7_transplant_SeqFile_StoreDivisionByte1.bin"
SeqFile_ReadTrackMagic_Loop:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackMagic_Loop.bin"
SeqFile_CheckTrackMagic:
	.incbin "includes/generated/v7_transplant_SeqFile_CheckTrackMagic.bin"
SeqFile_ValidateTrackMagic:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateTrackMagic.bin"
SeqFile_SkipTrackPad_Init:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipTrackPad_Init.bin"
SeqFile_SkipTrackPad_Loop:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipTrackPad_Loop.bin"
SeqFile_SkipTrackPad_Next:
	.incbin "includes/generated/v7_transplant_SeqFile_SkipTrackPad_Next.bin"
SeqFile_ReadTrackLength:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackLength.bin"
SeqFile_AccumulateLength:
	.incbin "includes/generated/v7_transplant_SeqFile_AccumulateLength.bin"
SeqFile_Epilogue:
	.incbin "includes/generated/v7_transplant_SeqFile_Epilogue.bin"
SeqInit_ResetAndSetupChannels:
	.incbin "includes/generated/v7_transplant_SeqInit_ResetAndSetupChannels.bin"
SeqInit_SetDefaultMode:
	.incbin "includes/generated/v7_transplant_SeqInit_SetDefaultMode.bin"
SeqInit_ConfigureBanks:
	.incbin "includes/generated/v7_transplant_SeqInit_ConfigureBanks.bin"
ConfigureBanks_Send:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Send.bin"
ConfigureBanks_LoadReg:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadReg.bin"
ConfigureBanks_Block:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block.bin"
ConfigureBanks_Block2:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block2.bin"
ConfigureBanks_Block3:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block3.bin"
ConfigureBanks_Extend:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Extend.bin"
ConfigureBanks_InitVal:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_InitVal.bin"
ConfigureBanks_WriteReg:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_WriteReg.bin"
ConfigureBanks_LoadReg2:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadReg2.bin"
ConfigureBanks_Block4:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block4.bin"
ConfigureBanks_Block5:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block5.bin"
ConfigureBanks_LoadAddr:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadAddr.bin"
ConfigureBanks_LoadAddr2:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadAddr2.bin"
ConfigureBanks_Block6:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block6.bin"
ConfigureBanks_SetWord:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_SetWord.bin"
ConfigureBanks_Block7:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block7.bin"
ConfigureBanks_Block8:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block8.bin"
ConfigureBanks_Block9:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block9.bin"
ConfigureBanks_LoadAddr3:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadAddr3.bin"
ConfigureBanks_LoadParam:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadParam.bin"
ConfigureBanks_LoadReg3:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadReg3.bin"
ConfigureBanks_LoadReg4:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_LoadReg4.bin"
ConfigureBanks_Block10:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block10.bin"
ConfigureBanks_Block11:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block11.bin"
ConfigureBanks_Block12:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_Block12.bin"
ConfigureBanks_NextIter:
	.incbin "includes/generated/v7_transplant_ConfigureBanks_NextIter.bin"
FileIO_SeekRecord_LoopDone:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRecord_LoopDone.bin"
FileIO_SeekRecord_Done:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRecord_Done.bin"
SeekRecord_Done_Prologue:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_Prologue.bin"
SeekRecord_Done_Block:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_Block.bin"
SeekRecord_Done_LoopBody:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_LoopBody.bin"
SeekRecord_Done_LoopCheck:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_LoopCheck.bin"
SeekRecord_Done_LoadParam:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_LoadParam.bin"
SeekRecord_Done_LoopBody2:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_LoopBody2.bin"
SeekRecord_Done_LoopCheck2:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_LoopCheck2.bin"
SeekRecord_Done_Compare:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_Compare.bin"
SeekRecord_Done_DoLookupRe:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_DoLookupRe.bin"
SeekRecord_Done_Block2:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_Block2.bin"
SeekRecord_Done_DoGetPlayS:
	.incbin "includes/generated/v7_transplant_SeekRecord_Done_DoGetPlayS.bin"
FileIO_SeekRecord_SendMidi:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRecord_SendMidi.bin"
FileIO_SeekRecord_Return:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRecord_Return.bin"
FileIO_SeekRecord_PopReturn:
	.incbin "includes/generated/v7_transplant_FileIO_SeekRecord_PopReturn.bin"
SeekRecord_PopReturn_Prologue:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Prologue.bin"
SeekRecord_PopReturn_Block:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Block.bin"
SeekRecord_PopReturn_LoadDRAM:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_LoadDRAM.bin"
SeekRecord_PopReturn_Block2:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Block2.bin"
SeekRecord_PopReturn_Block3:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Block3.bin"
SeekRecord_PopReturn_Block4:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Block4.bin"
SeekRecord_PopReturn_LoopBody:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_LoopBody.bin"
SeekRecord_PopReturn_LoopCheck:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_LoopCheck.bin"
SeekRecord_PopReturn_LoadAddr:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_LoadAddr.bin"
SeekRecord_PopReturn_Epilogue:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Epilogue.bin"
SeekRecord_PopReturn_Data:
	.incbin "includes/generated/v7_transplant_SeekRecord_PopReturn_Data.bin"
SeqFile_ParseHeader:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader.bin"
SeqFile_ParseHeader_Block:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_Block.bin"
SeqFile_ParseHeader_Block2:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_Block2.bin"
SeqFile_ParseHeader_Block3:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_Block3.bin"
SeqFile_ParseHeader_DoVoiceSta:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_DoVoiceSta.bin"
SeqFile_ParseHeader_LoadReg:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_LoadReg.bin"
SeqFile_ParseHeader_RestoreReg:
	.incbin "includes/generated/v7_transplant_SeqFile_ParseHeader_RestoreReg.bin"
SeqFile_ReadTrackData:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackData.bin"
SeqFile_ReadTrackDat_LoadIter:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackDat_LoadIter.bin"
SeqFile_ReadTrackDat_LoadParam:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackDat_LoadParam.bin"
SeqFile_ReadTrackDat_RestoreReg:
	.incbin "includes/generated/v7_transplant_SeqFile_ReadTrackDat_RestoreReg.bin"
SeqFile_ValidateAndStore:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateAndStore.bin"
SeqFile_ValidateAndS_LoadIter:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateAndS_LoadIter.bin"
SeqFile_ValidateAndS_LoadParam:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateAndS_LoadParam.bin"
SeqFile_ValidateAndS_RestoreReg:
	.incbin "includes/generated/v7_transplant_SeqFile_ValidateAndS_RestoreReg.bin"
SongFile_DecodeMidiEvent:
	.incbin "includes/generated/v7_transplant_SongFile_DecodeMidiEvent.bin"
DecodeMidiEvent_Block:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_Block.bin"
DecodeMidiEvent_Block2:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_Block2.bin"
DecodeMidiEvent_Send:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_Send.bin"
DecodeMidiEvent_LoadDRAM:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadDRAM.bin"
DecodeMidiEvent_DoReadNext:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_DoReadNext.bin"
DecodeMidiEvent_LoadParam:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam.bin"
DecodeMidiEvent_LoadParam2:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam2.bin"
DecodeMidiEvent_LoadParam3:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam3.bin"
DecodeMidiEvent_LoadAddr:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadAddr.bin"
DecodeMidiEvent_LoadParam4:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam4.bin"
DecodeMidiEvent_DoReadNext2:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_DoReadNext2.bin"
DecodeMidiEvent_Increment:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_Increment.bin"
DecodeMidiEvent_LoadParam5:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam5.bin"
DecodeMidiEvent_LoadParam6:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam6.bin"
DecodeMidiEvent_LoadParam7:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam7.bin"
DecodeMidiEvent_DoReadNext3:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_DoReadNext3.bin"
DecodeMidiEvent_LoadParam8:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam8.bin"
DecodeMidiEvent_LoadParam9:
	.incbin "includes/generated/v7_transplant_DecodeMidiEvent_LoadParam9.bin"
SeqPlay_CheckBit7Path:
	.incbin "includes/generated/v7_transplant_SeqPlay_CheckBit7Path.bin"
SeqPlay_CopyRecordData:
	.incbin "includes/generated/v7_transplant_SeqPlay_CopyRecordData.bin"
SeqPlay_CheckStatusByte:
	.incbin "includes/generated/v7_transplant_SeqPlay_CheckStatusByte.bin"
SeqPlay_TwoByteMsg:
	.incbin "includes/generated/v7_transplant_SeqPlay_TwoByteMsg.bin"
SeqPlay_ThreeByteMsg:
	.incbin "includes/generated/v7_transplant_SeqPlay_ThreeByteMsg.bin"
SeqPlay_ReadRemainingBytes:
	.incbin "includes/generated/v7_transplant_SeqPlay_ReadRemainingBytes.bin"
SeqPlay_ReadByte_Loop:
	.incbin "includes/generated/v7_transplant_SeqPlay_ReadByte_Loop.bin"
SeqPlay_StoreByte:
	.incbin "includes/generated/v7_transplant_SeqPlay_StoreByte.bin"
SeqPlay_ReadRecord_Entry:
	.incbin "includes/generated/v7_transplant_SeqPlay_ReadRecord_Entry.bin"
SeqPlay_AccumulateDelta:
	.incbin "includes/generated/v7_transplant_SeqPlay_AccumulateDelta.bin"
SeqPlay_CheckSysExMarker:
	.incbin "includes/generated/v7_transplant_SeqPlay_CheckSysExMarker.bin"
SeqVoice_InitZeroPath:
	.incbin "includes/generated/v7_transplant_SeqVoice_InitZeroPath.bin"
SeqPlay_CopyToMidiBuffer:
	.incbin "includes/generated/v7_transplant_SeqPlay_CopyToMidiBuffer.bin"
SeqPlay_SendEvent:
	.incbin "includes/generated/v7_transplant_SeqPlay_SendEvent.bin"
SeqPlay_CheckMidiBuffer:
	.incbin "includes/generated/v7_transplant_SeqPlay_CheckMidiBuffer.bin"
SeqPlay_ClearMidiCount:
	.incbin "includes/generated/v7_transplant_SeqPlay_ClearMidiCount.bin"
SeqPlay_SetSuccess:
	.incbin "includes/generated/v7_transplant_SeqPlay_SetSuccess.bin"
SeqPlay_Epilogue:
	.incbin "includes/generated/v7_transplant_SeqPlay_Epilogue.bin"
SeqPlay_ReadFileRecord:
	.incbin "includes/generated/v7_transplant_SeqPlay_ReadFileRecord.bin"
SeqPlay_RecordReadOK:
	.incbin "includes/generated/v7_transplant_SeqPlay_RecordReadOK.bin"
RecordReadOK_Block:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block.bin"
RecordReadOK_LoopBody:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody.bin"
RecordReadOK_LoopCheck:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck.bin"
RecordReadOK_InitVal:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal.bin"
RecordReadOK_LoopBody2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody2.bin"
RecordReadOK_LoadIter:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadIter.bin"
RecordReadOK_LoopCheck2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck2.bin"
RecordReadOK_InitVal2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal2.bin"
RecordReadOK_LoopBody3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody3.bin"
RecordReadOK_LoopCheck3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck3.bin"
RecordReadOK_Block2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block2.bin"
RecordReadOK_LoadReg:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg.bin"
RecordReadOK_InitVal3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal3.bin"
RecordReadOK_LoopBody4:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody4.bin"
RecordReadOK_Block3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block3.bin"
RecordReadOK_SetWord:
	.incbin "includes/generated/v7_transplant_RecordReadOK_SetWord.bin"
RecordReadOK_LoopCheck4:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck4.bin"
RecordReadOK_InitVal4:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal4.bin"
RecordReadOK_Block4:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block4.bin"
RecordReadOK_LoadIter2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadIter2.bin"
RecordReadOK_Block5:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block5.bin"
RecordReadOK_InitVal5:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal5.bin"
RecordReadOK_Block6:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block6.bin"
RecordReadOK_NextIter:
	.incbin "includes/generated/v7_transplant_RecordReadOK_NextIter.bin"
RecordReadOK_Block7:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block7.bin"
RecordReadOK_LoadReg2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg2.bin"
RecordReadOK_LoadReg3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg3.bin"
RecordReadOK_Block8:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block8.bin"
RecordReadOK_NextIter2:
	.incbin "includes/generated/v7_transplant_RecordReadOK_NextIter2.bin"
RecordReadOK_CheckDRAM:
	.incbin "includes/generated/v7_transplant_RecordReadOK_CheckDRAM.bin"
RecordReadOK_LoopBody5:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody5.bin"
RecordReadOK_LoopCheck5:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck5.bin"
RecordReadOK_Block9:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block9.bin"
RecordReadOK_LoadReg4:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg4.bin"
RecordReadOK_LoopBody6:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody6.bin"
RecordReadOK_NextIter3:
	.incbin "includes/generated/v7_transplant_RecordReadOK_NextIter3.bin"
RecordReadOK_LoopCheck6:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck6.bin"
RecordReadOK_InitVal6:
	.incbin "includes/generated/v7_transplant_RecordReadOK_InitVal6.bin"
RecordReadOK_LoopBody7:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopBody7.bin"
RecordReadOK_LoopCheck7:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoopCheck7.bin"
RecordReadOK_Block10:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block10.bin"
RecordReadOK_Compare:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Compare.bin"
RecordReadOK_Block11:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block11.bin"
RecordReadOK_Block12:
	.incbin "includes/generated/v7_transplant_RecordReadOK_Block12.bin"
RecordReadOK_LoadReg5:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg5.bin"
RecordReadOK_LoadReg6:
	.incbin "includes/generated/v7_transplant_RecordReadOK_LoadReg6.bin"
FileIO_Epilogue:
	.incbin "includes/generated/v7_transplant_FileIO_Epilogue.bin"
Epilogue_Prologue:
	.incbin "includes/generated/v7_transplant_Epilogue_Prologue.bin"
Epilogue_LoadReg:
	.incbin "includes/generated/v7_transplant_Epilogue_LoadReg.bin"
Epilogue_InitVal:
	.incbin "includes/generated/v7_transplant_Epilogue_InitVal.bin"
Epilogue_LoadIter:
	.incbin "includes/generated/v7_transplant_Epilogue_LoadIter.bin"
Epilogue_Block:
	.incbin "includes/generated/v7_transplant_Epilogue_Block.bin"
Epilogue_Prologue2:
	.incbin "includes/generated/v7_transplant_Epilogue_Prologue2.bin"
Epilogue_LoadReg2:
	.incbin "includes/generated/v7_transplant_Epilogue_LoadReg2.bin"
Epilogue_InitVal2:
	.incbin "includes/generated/v7_transplant_Epilogue_InitVal2.bin"
Epilogue_LoadIter2:
	.incbin "includes/generated/v7_transplant_Epilogue_LoadIter2.bin"
Epilogue_InitVal3:
	.incbin "includes/generated/v7_transplant_Epilogue_InitVal3.bin"
MidiSysMsg_Handler:
	.incbin "includes/generated/v7_transplant_MidiSysMsg_Handler.bin"
MidiSysMsg_Dispatch:
	.incbin "includes/generated/v7_transplant_MidiSysMsg_Dispatch.bin"
Dispatch_LoadParam:
	.incbin "includes/generated/v7_transplant_Dispatch_LoadParam.bin"
Dispatch_Block:
	.incbin "includes/generated/v7_transplant_Dispatch_Block.bin"
Dispatch_Block2:
	.incbin "includes/generated/v7_transplant_Dispatch_Block2.bin"
Dispatch_InitVal:
	.incbin "includes/generated/v7_transplant_Dispatch_InitVal.bin"
Dispatch_Block3:
	.incbin "includes/generated/v7_transplant_Dispatch_Block3.bin"
Dispatch_LoadAddr:
	.incbin "includes/generated/v7_transplant_Dispatch_LoadAddr.bin"
Dispatch_LoadAddr2:
	.incbin "includes/generated/v7_transplant_Dispatch_LoadAddr2.bin"
Dispatch_InitVal2:
	.incbin "includes/generated/v7_transplant_Dispatch_InitVal2.bin"
Dispatch_Epilogue:
	.incbin "includes/generated/v7_transplant_Dispatch_Epilogue.bin"
Dispatch_Data:
	.incbin "includes/generated/v7_transplant_Dispatch_Data.bin"
Dispatch_Prologue:
	.incbin "includes/generated/v7_transplant_Dispatch_Prologue.bin"
ToneGen_CheckSpecialChannel:
	.incbin "includes/generated/v7_transplant_ToneGen_CheckSpecialChannel.bin"
ToneGen_SendPacketDirect:
	.incbin "includes/generated/v7_transplant_ToneGen_SendPacketDirect.bin"
ToneGen_CheckVelocityRepeat:
	.incbin "includes/generated/v7_transplant_ToneGen_CheckVelocityRepeat.bin"
ToneGen_CheckZeroVelocity:
	.incbin "includes/generated/v7_transplant_ToneGen_CheckZeroVelocity.bin"
ToneGen_ResendPacket:
	.incbin "includes/generated/v7_transplant_ToneGen_ResendPacket.bin"
ToneGen_SendAndReturn:
	.incbin "includes/generated/v7_transplant_ToneGen_SendAndReturn.bin"
ToneGen_PopIzStackReturn:
	.incbin "includes/generated/v7_transplant_ToneGen_PopIzStackReturn.bin"
ToneGen_ReadFileRecord:
	.incbin "includes/generated/v7_transplant_ToneGen_ReadFileRecord.bin"
ToneGen_CheckRecordType:
	.incbin "includes/generated/v7_transplant_ToneGen_CheckRecordType.bin"
ToneGen_ReadExtendedDelta:
	.incbin "includes/generated/v7_transplant_ToneGen_ReadExtendedDelta.bin"
ToneGen_ShiftAndAccumulate:
	.incbin "includes/generated/v7_transplant_ToneGen_ShiftAndAccumulate.bin"
ToneGen_SignExtendDelta:
	.incbin "includes/generated/v7_transplant_ToneGen_SignExtendDelta.bin"
ToneGen_AccumulateDelta:
	.incbin "includes/generated/v7_transplant_ToneGen_AccumulateDelta.bin"
ToneGen_PopIzReturn:
	.incbin "includes/generated/v7_transplant_ToneGen_PopIzReturn.bin"
ToneGen_ResetAndInitBanks:
	.incbin "includes/generated/v7_transplant_ToneGen_ResetAndInitBanks.bin"
MidiRealtime_ReadAndProcess:
	.incbin "includes/generated/v7_transplant_MidiRealtime_ReadAndProcess.bin"
MidiRealtime_DispatchStatus:
	.incbin "includes/generated/v7_transplant_MidiRealtime_DispatchStatus.bin"
MidiRealtime_SysExStart:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExStart.bin"
MidiRealtime_SysExReadLoop:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExReadLoop.bin"
MidiRealtime_SysExCheckEnd:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExCheckEnd.bin"
MidiRealtime_SysExCheckF7:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExCheckF7.bin"
MidiRealtime_SysExOverflow:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOverflow.bin"
MidiRealtime_SysExOv_LoadReg:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOv_LoadReg.bin"
MidiRealtime_SysExOv_LoadReg2:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOv_LoadReg2.bin"
MidiRealtime_SysExOv_Block:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOv_Block.bin"
MidiRealtime_SysExOv_LoadReg3:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOv_LoadReg3.bin"
MidiRealtime_SysExOv_LoadIter:
	.incbin "includes/generated/v7_transplant_MidiRealtime_SysExOv_LoadIter.bin"
MidiRealtime_NonSysExHandler:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysExHandler.bin"
MidiRealtime_NonSysE_CheckEnd:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_CheckEnd.bin"
MidiRealtime_NonSysE_LoadReg:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_LoadReg.bin"
MidiRealtime_NonSysE_LoadReg2:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_LoadReg2.bin"
MidiRealtime_NonSysE_Block:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_Block.bin"
MidiRealtime_NonSysE_LoadReg3:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_LoadReg3.bin"
MidiRealtime_NonSysE_LoadIter:
	.incbin "includes/generated/v7_transplant_MidiRealtime_NonSysE_LoadIter.bin"
MidiRealtime_StopAndReturn:
	.incbin "includes/generated/v7_transplant_MidiRealtime_StopAndReturn.bin"
MidiRealtime_ProcessByte:
	.incbin "includes/generated/v7_transplant_MidiRealtime_ProcessByte.bin"
MidiRealtime_Process_Prologue:
	.incbin "includes/generated/v7_transplant_MidiRealtime_Process_Prologue.bin"
ToneGen_ProcessMidiConverge:
	.incbin "includes/generated/v7_transplant_ToneGen_ProcessMidiConverge.bin"
ProcessMidiConverge_Block:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_Block.bin"
ProcessMidiConverge_Block2:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_Block2.bin"
ProcessMidiConverge_Block3:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_Block3.bin"
ProcessMidiConverge_InitVal:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_InitVal.bin"
ProcessMidiConverge_LoopBody:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_LoopBody.bin"
ProcessMidiConverge_LoopCheck:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_LoopCheck.bin"
ProcessMidiConverge_LoadDRAM:
	.incbin "includes/generated/v7_transplant_ProcessMidiConverge_LoadDRAM.bin"
ToneGen_ValidateRange_Loop:
	.incbin "includes/generated/v7_transplant_ToneGen_ValidateRange_Loop.bin"
ToneGen_VoiceReset_Return:
	.incbin "includes/generated/v7_transplant_ToneGen_VoiceReset_Return.bin"
VoiceReset_Return_RestoreReg:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_RestoreReg.bin"
VoiceReset_Return_Prologue:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Prologue.bin"
VoiceReset_Return_Block:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Block.bin"
VoiceReset_Return_LoadDRAM:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadDRAM.bin"
VoiceReset_Return_Block2:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Block2.bin"
VoiceReset_Return_Block3:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Block3.bin"
VoiceReset_Return_Block4:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Block4.bin"
VoiceReset_Return_LoopBody:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoopBody.bin"
VoiceReset_Return_LoopCheck:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoopCheck.bin"
VoiceReset_Return_LoadParam:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadParam.bin"
VoiceReset_Return_LoadIter:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadIter.bin"
VoiceReset_Return_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadDRAM2.bin"
VoiceReset_Return_LoadIter2:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadIter2.bin"
VoiceReset_Return_LoadAddr:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_LoadAddr.bin"
VoiceReset_Return_InitVal:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_InitVal.bin"
VoiceReset_Return_Epilogue:
	.incbin "includes/generated/v7_transplant_VoiceReset_Return_Epilogue.bin"
SoundParam_InitDefaultBanks:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefaultBanks.bin"
SoundParam_InitDefau_LoadReg:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_LoadReg.bin"
SoundParam_InitDefau_Block:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_Block.bin"
SoundParam_InitDefau_LoadReg2:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_LoadReg2.bin"
SoundParam_InitDefau_Block2:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_Block2.bin"
SoundParam_InitDefau_LoadReg3:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_LoadReg3.bin"
SoundParam_InitDefau_LoadReg4:
	.incbin "includes/generated/v7_transplant_SoundParam_InitDefau_LoadReg4.bin"
ToneGen_NotifyChangeComplete_Return:
	.incbin "includes/generated/v7_transplant_ToneGen_NotifyChangeComplete_Return.bin"
NotifyChangeComplete_Prologue:
	.incbin "includes/generated/v7_transplant_NotifyChangeComplete_Prologue.bin"
NotifyChangeComplete_Prologue2:
	.incbin "includes/generated/v7_transplant_NotifyChangeComplete_Prologue2.bin"
NotifyChangeComplete_DoGetCurre:
	.incbin "includes/generated/v7_transplant_NotifyChangeComplete_DoGetCurre.bin"
NotifyChangeComplete_SetWord:
	.incbin "includes/generated/v7_transplant_NotifyChangeComplete_SetWord.bin"
ToneGen_RestoreStackReturn:
	.incbin "includes/generated/v7_transplant_ToneGen_RestoreStackReturn.bin"
FileIO_ReadNextRecord:
	.incbin "includes/generated/v7_transplant_FileIO_ReadNextRecord.bin"
ReadNextRecord_Block:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_Block.bin"
ReadNextRecord_Block2:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_Block2.bin"
ReadNextRecord_Block3:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_Block3.bin"
ReadNextRecord_DoReadNext:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_DoReadNext.bin"
ReadNextRecord_DoLookupB:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_DoLookupB.bin"
ReadNextRecord_SetWord:
	.incbin "includes/generated/v7_transplant_ReadNextRecord_SetWord.bin"
SndParam_DirectReturn:
	.incbin "includes/generated/v7_transplant_SndParam_DirectReturn.bin"
DirectReturn_LoadDRAM:
	.incbin "includes/generated/v7_transplant_DirectReturn_LoadDRAM.bin"
DirectReturn_DoDrainQue:
	.incbin "includes/generated/v7_transplant_DirectReturn_DoDrainQue.bin"
DirectReturn_DoLookupC:
	.incbin "includes/generated/v7_transplant_DirectReturn_DoLookupC.bin"
SndParam_StoreAndReturn:
	.incbin "includes/generated/v7_transplant_SndParam_StoreAndReturn.bin"
StoreAndReturn_Block:
	.incbin "includes/generated/v7_transplant_StoreAndReturn_Block.bin"
FileIO_InitTrackSlots:
	.incbin "includes/generated/v7_transplant_FileIO_InitTrackSlots.bin"
InitTrackSlots_LoopBody:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_LoopBody.bin"
InitTrackSlots_LoopCheck:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_LoopCheck.bin"
InitTrackSlots_Block:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_Block.bin"
InitTrackSlots_LoadDRAM:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_LoadDRAM.bin"
InitTrackSlots_IncDRAM:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_IncDRAM.bin"
InitTrackSlots_InitVal:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_InitVal.bin"
InitTrackSlots_Return:
	.incbin "includes/generated/v7_transplant_InitTrackSlots_Return.bin"
RingBuffer_ReadByte:
	.incbin "includes/generated/v7_transplant_RingBuffer_ReadByte.bin"
RingBuffer_ReadByte_LoadDRAM:
	.incbin "includes/generated/v7_transplant_RingBuffer_ReadByte_LoadDRAM.bin"
RingBuffer_ReadByte_IncDRAM:
	.incbin "includes/generated/v7_transplant_RingBuffer_ReadByte_IncDRAM.bin"
RingBuffer_ReadByte_Return:
	.incbin "includes/generated/v7_transplant_RingBuffer_ReadByte_Return.bin"
Seq_CalcAddrOffset:
	.incbin "includes/generated/v7_transplant_Seq_CalcAddrOffset.bin"
CalcAddrOffset_Data:
	.incbin "includes/generated/v7_transplant_CalcAddrOffset_Data.bin"
MidiRingBuf_WriteBytes:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_WriteBytes.bin"
WriteBytes_Block:
	.incbin "includes/generated/v7_transplant_WriteBytes_Block.bin"
WriteBytes_Block2:
	.incbin "includes/generated/v7_transplant_WriteBytes_Block2.bin"
SndParam_NotifyLoop_Body:
	.incbin "includes/generated/v7_transplant_SndParam_NotifyLoop_Body.bin"
SndParam_NotifySuccess:
	.incbin "includes/generated/v7_transplant_SndParam_NotifySuccess.bin"
SndParam_NotifyError:
	.incbin "includes/generated/v7_transplant_SndParam_NotifyError.bin"
SndParam_PopStackReturn:
	.incbin "includes/generated/v7_transplant_SndParam_PopStackReturn.bin"
SysexRingBuf_Init:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_Init.bin"
SysexRingBuf_ClearLoop:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ClearLoop.bin"
SysexRingBuf_ClearCheck:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ClearCheck.bin"
SysexRingBuf_WriteByte:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteByte.bin"
SysexRingBuf_StoreAndAdvance:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_StoreAndAdvance.bin"
SysexRingBuf_IncrementWrite:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_IncrementWrite.bin"
SysexRingBuf_WriteSuccess:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteSuccess.bin"
SysexRingBuf_WriteReturn:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteReturn.bin"
SysexRingBuf_ReadByte:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadByte.bin"
SysexRingBuf_ReadAndAdvance:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadAndAdvance.bin"
SysexRingBuf_IncrementRead:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_IncrementRead.bin"
SysexRingBuf_ReadReturn:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadReturn.bin"
SysexRingBuf_GetFreeSpace:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_GetFreeSpace.bin"
SysexRingBuf_ReadBytes:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadBytes.bin"
SysexRingBuf_ReadBytesLoop:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadBytesLoop.bin"
SysexRingBuf_ReadBytesStore:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadBytesStore.bin"
SysexRingBuf_ReadBytesOK:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadBytesOK.bin"
SysexRingBuf_ReadBytesReturn:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_ReadBytesReturn.bin"
SysexRingBuf_WriteBytes:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteBytes.bin"
SysexRingBuf_WriteNonZero:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteNonZero.bin"
SysexRingBuf_WriteBytesLoop:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteBytesLoop.bin"
SysexRingBuf_WriteBytesOK:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteBytesOK.bin"
SysexRingBuf_WriteBytesReturn:
	.incbin "includes/generated/v7_transplant_SysexRingBuf_WriteBytesReturn.bin"
MidiRingBuf_Init:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_Init.bin"
MidiRingBuf_ClearLoop:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_ClearLoop.bin"
MidiRingBuf_ClearCheck:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_ClearCheck.bin"
MidiRingBuf_WriteByte:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_WriteByte.bin"
MidiRingBuf_StoreAndAdvance:
	.incbin "includes/generated/v7_transplant_MidiRingBuf_StoreAndAdvance.bin"
StoreAndAdvance_IncDRAM:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_IncDRAM.bin"
StoreAndAdvance_InitVal:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_InitVal.bin"
StoreAndAdvance_Return:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Return.bin"
StoreAndAdvance_LoadDRAM:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_LoadDRAM.bin"
StoreAndAdvance_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_LoadDRAM2.bin"
StoreAndAdvance_IncDRAM2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_IncDRAM2.bin"
StoreAndAdvance_Return2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Return2.bin"
StoreAndAdvance_Prologue:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Prologue.bin"
StoreAndAdvance_LoopBody:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_LoopBody.bin"
StoreAndAdvance_LoopCheck:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_LoopCheck.bin"
StoreAndAdvance_InitVal2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_InitVal2.bin"
StoreAndAdvance_RestoreReg:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_RestoreReg.bin"
StoreAndAdvance_Prologue2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Prologue2.bin"
StoreAndAdvance_Block:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Block.bin"
StoreAndAdvance_LoadParam:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_LoadParam.bin"
StoreAndAdvance_InitVal3:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_InitVal3.bin"
StoreAndAdvance_RestoreReg2:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_RestoreReg2.bin"
StoreAndAdvance_Prologue3:
	.incbin "includes/generated/v7_transplant_StoreAndAdvance_Prologue3.bin"
CharMap_NullPreamble_0:
	.incbin "includes/generated/v7_transplant_CharMap_NullPreamble_0.bin"
CharMap_NullPreamble_1:
	.incbin "includes/generated/v7_transplant_CharMap_NullPreamble_1.bin"
CharMap_NullPreamble_2:
	.incbin "includes/generated/v7_transplant_CharMap_NullPreamble_2.bin"
CharMap_ActivePreamble:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamble.bin"
CharMap_ActivePreamb_LoadDRAM:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_LoadDRAM.bin"
CharMap_ActivePreamb_Prologue:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_Prologue.bin"
CharMap_ActivePreamb_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_LoadDRAM2.bin"
CharMap_ActivePreamb_Extend:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_Extend.bin"
CharMap_ActivePreamb_Compare:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_Compare.bin"
CharMap_ActivePreamb_LoadDRAM3:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_LoadDRAM3.bin"
CharMap_ActivePreamb_LoadDRAM4:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_LoadDRAM4.bin"
CharMap_ActivePreamb_Increment:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_Increment.bin"
CharMap_ActivePreamb_Prologue2:
	.incbin "includes/generated/v7_transplant_CharMap_ActivePreamb_Prologue2.bin"
SndParam_ApplyMaskClamp:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyMaskClamp.bin"
ApplyMaskClamp_LoadParam:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadParam.bin"
ApplyMaskClamp_Compare:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_Compare.bin"
ApplyMaskClamp_LoadParam2:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadParam2.bin"
ApplyMaskClamp_LoadParam3:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadParam3.bin"
ApplyMaskClamp_LoadParam4:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadParam4.bin"
ApplyMaskClamp_LoadParam5:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadParam5.bin"
ApplyMaskClamp_LoadReg:
	.incbin "includes/generated/v7_transplant_ApplyMaskClamp_LoadReg.bin"
SndParam_StoreResult_Return:
	.incbin "includes/generated/v7_transplant_SndParam_StoreResult_Return.bin"
SndParam_PopIzSkip4Ret:
	.incbin "includes/generated/v7_transplant_SndParam_PopIzSkip4Ret.bin"
SndParam_StoreDRAMInit:
	.incbin "includes/generated/v7_transplant_SndParam_StoreDRAMInit.bin"
StoreDRAMInit_ReadBuf:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_ReadBuf.bin"
StoreDRAMInit_ReadBuf2:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_ReadBuf2.bin"
StoreDRAMInit_ReadBuf3:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_ReadBuf3.bin"
StoreDRAMInit_LoadParam:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_LoadParam.bin"
StoreDRAMInit_Block:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_Block.bin"
StoreDRAMInit_Block2:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_Block2.bin"
StoreDRAMInit_LoadParam2:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_LoadParam2.bin"
StoreDRAMInit_LoadDRAM:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_LoadDRAM.bin"
StoreDRAMInit_Block3:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_Block3.bin"
StoreDRAMInit_Block4:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_Block4.bin"
StoreDRAMInit_Block5:
	.incbin "includes/generated/v7_transplant_StoreDRAMInit_Block5.bin"
SndParam_ApplyProgramChangeAsync:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyProgramChangeAsync.bin"
ApplyProgramChangeAs_Block:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_Block.bin"
ApplyProgramChangeAs_RestoreReg:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_RestoreReg.bin"
ApplyProgramChangeAs_Prologue:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_Prologue.bin"
ApplyProgramChangeAs_ClearByte:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_ClearByte.bin"
ApplyProgramChangeAs_LoadParam:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadParam.bin"
ApplyProgramChangeAs_LoadParam2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadParam2.bin"
ApplyProgramChangeAs_Prologue2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_Prologue2.bin"
ApplyProgramChangeAs_Block2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_Block2.bin"
ApplyProgramChangeAs_RestoreReg2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_RestoreReg2.bin"
ApplyProgramChangeAs_DoLookupRe:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_DoLookupRe.bin"
ApplyProgramChangeAs_SetByte:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_SetByte.bin"
ApplyProgramChangeAs_LoadDRAM:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadDRAM.bin"
ApplyProgramChangeAs_Return:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_Return.bin"
ApplyProgramChangeAs_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadDRAM2.bin"
ApplyProgramChangeAs_LoadReg:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadReg.bin"
ApplyProgramChangeAs_LoadReg2:
	.incbin "includes/generated/v7_transplant_ApplyProgramChangeAs_LoadReg2.bin"
SndParam_FetchOscTableEntry:
	.incbin "includes/generated/v7_transplant_SndParam_FetchOscTableEntry.bin"
FetchOscTableEntry_LoadIter:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_LoadIter.bin"
FetchOscTableEntry_Epilogue:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_Epilogue.bin"
FetchOscTableEntry_Prologue:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_Prologue.bin"
FetchOscTableEntry_ClearByte:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_ClearByte.bin"
FetchOscTableEntry_ClearByte2:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_ClearByte2.bin"
FetchOscTableEntry_Compute:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_Compute.bin"
FetchOscTableEntry_LoadReg:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_LoadReg.bin"
FetchOscTableEntry_LoadReg2:
	.incbin "includes/generated/v7_transplant_FetchOscTableEntry_LoadReg2.bin"
SndParam_ApplyProgramChange:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyProgramChange.bin"
ApplyProgramChange_LoadIter:
	.incbin "includes/generated/v7_transplant_ApplyProgramChange_LoadIter.bin"
ApplyProgramChange_Epilogue:
	.incbin "includes/generated/v7_transplant_ApplyProgramChange_Epilogue.bin"
ApplyProgramChange_LoadDRAM:
	.incbin "includes/generated/v7_transplant_ApplyProgramChange_LoadDRAM.bin"
ApplyProgramChange_LoadReg:
	.incbin "includes/generated/v7_transplant_ApplyProgramChange_LoadReg.bin"
SndParam_InitBufferConverge:
	.incbin "includes/generated/v7_transplant_SndParam_InitBufferConverge.bin"
SndParam_ComputeVoiceIndex:
	.incbin "includes/generated/v7_transplant_SndParam_ComputeVoiceIndex.bin"
ComputeVoiceIndex_LoadIter:
	.incbin "includes/generated/v7_transplant_ComputeVoiceIndex_LoadIter.bin"
ComputeVoiceIndex_Epilogue:
	.incbin "includes/generated/v7_transplant_ComputeVoiceIndex_Epilogue.bin"
SndParam_LookupOscEnvelope:
	.incbin "includes/generated/v7_transplant_SndParam_LookupOscEnvelope.bin"
LookupOscEnvelope_LoadDRAM:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_LoadDRAM.bin"
LookupOscEnvelope_Increment:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_Increment.bin"
LookupOscEnvelope_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_LoadReg.bin"
LookupOscEnvelope_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_LoadDRAM2.bin"
LookupOscEnvelope_LoadReg2:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_LoadReg2.bin"
LookupOscEnvelope_LoadReg3:
	.incbin "includes/generated/v7_transplant_LookupOscEnvelope_LoadReg3.bin"
SndParam_ApplyVoiceValue:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyVoiceValue.bin"
SndParam_StoreNoteValue:
	.incbin "includes/generated/v7_transplant_SndParam_StoreNoteValue.bin"
SndParam_SetDefaultKeyOff:
	.incbin "includes/generated/v7_transplant_SndParam_SetDefaultKeyOff.bin"
SndParam_ApplyReturn:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyReturn.bin"
SndParam_CheckAndApplyMode:
	.incbin "includes/generated/v7_transplant_SndParam_CheckAndApplyMode.bin"
SndParam_LookupFromPointerTable:
	.incbin "includes/generated/v7_transplant_SndParam_LookupFromPointerTable.bin"
SndParam_LookupByPartAndNote:
	.incbin "includes/generated/v7_transplant_SndParam_LookupByPartAndNote.bin"
SndParam_CompactLookupStub:
	.incbin "includes/generated/v7_transplant_SndParam_CompactLookupStub.bin"
SndParam_LookupAndDispatch:
	.incbin "includes/generated/v7_transplant_SndParam_LookupAndDispatch.bin"
SndParam_ApplyMaskAndCheck:
	.incbin "includes/generated/v7_transplant_SndParam_ApplyMaskAndCheck.bin"
SndParam_DispatchProcessParam:
	.incbin "includes/generated/v7_transplant_SndParam_DispatchProcessParam.bin"
SndParam_StoreResult:
	.incbin "includes/generated/v7_transplant_SndParam_StoreResult.bin"
SndParam_ReturnResult:
	.incbin "includes/generated/v7_transplant_SndParam_ReturnResult.bin"
SndParam_LookupByChannel:
	.incbin "includes/generated/v7_transplant_SndParam_LookupByChannel.bin"
SndParam_TypeDispatch:
	.incbin "includes/generated/v7_transplant_SndParam_TypeDispatch.bin"
SndParam_TypeDispatch_Entry1:
	.incbin "includes/generated/v7_transplant_SndParam_TypeDispatch_Entry1.bin"
TypeDispatch_Entry1_Extend:
	.incbin "includes/generated/v7_transplant_TypeDispatch_Entry1_Extend.bin"
TypeDispatch_Entry1_Extend2:
	.incbin "includes/generated/v7_transplant_TypeDispatch_Entry1_Extend2.bin"
SndParam_LoadTableConverge:
	.incbin "includes/generated/v7_transplant_SndParam_LoadTableConverge.bin"
LoadTableConverge_LoadReg:
	.incbin "includes/generated/v7_transplant_LoadTableConverge_LoadReg.bin"
LoadTableConverge_LoadReg2:
	.incbin "includes/generated/v7_transplant_LoadTableConverge_LoadReg2.bin"
LoadTableConverge_LoadFromStack:
	.incbin "includes/generated/v7_transplant_LoadTableConverge_LoadFromStack.bin"
SndParam_LoadReturnByte:
	.incbin "includes/generated/v7_transplant_SndParam_LoadReturnByte.bin"
LoadReturnByte_Increment:
	.incbin "includes/generated/v7_transplant_LoadReturnByte_Increment.bin"
SndParam_OffsetHandler:
	.incbin "includes/generated/v7_transplant_SndParam_OffsetHandler.bin"
SndParam_OffsetDispatch:
	.incbin "includes/generated/v7_transplant_SndParam_OffsetDispatch.bin"
OffsetDispatch_SetWord:
	.incbin "includes/generated/v7_transplant_OffsetDispatch_SetWord.bin"
OffsetDispatch_SetWord2:
	.incbin "includes/generated/v7_transplant_OffsetDispatch_SetWord2.bin"
OffsetDispatch_SetWord3:
	.incbin "includes/generated/v7_transplant_OffsetDispatch_SetWord3.bin"
SndParam_LookupTableConverge:
	.incbin "includes/generated/v7_transplant_SndParam_LookupTableConverge.bin"
LookupTableConverge_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupTableConverge_LoadReg.bin"
LookupTableConverge_LoadReg2:
	.incbin "includes/generated/v7_transplant_LookupTableConverge_LoadReg2.bin"
LookupTableConverge_LoadFromStack:
	.incbin "includes/generated/v7_transplant_LookupTableConverge_LoadFromStack.bin"
LookupTableConverge_LoadParam:
	.incbin "includes/generated/v7_transplant_LookupTableConverge_LoadParam.bin"
LookupTableConverge_Increment:
	.incbin "includes/generated/v7_transplant_LookupTableConverge_Increment.bin"
Param_SignExtendReturn:
	.incbin "includes/generated/v7_transplant_Param_SignExtendReturn.bin"
Param_SignExtendRetu_Return:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Return.bin"
Param_SignExtendRetu_Block:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Block.bin"
Param_SignExtendRetu_Block2:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Block2.bin"
Param_SignExtendRetu_Data:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Data.bin"
Param_SignExtendRetu_Block3:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Block3.bin"
Param_SignExtendRetu_Block4:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Block4.bin"
Param_SignExtendRetu_Block5:
	.incbin "includes/generated/v7_transplant_Param_SignExtendRetu_Block5.bin"
SndParam_LookupPartIndex:
	.incbin "includes/generated/v7_transplant_SndParam_LookupPartIndex.bin"
LookupPartIndex_Compare:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_Compare.bin"
LookupPartIndex_LoadReg:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_LoadReg.bin"
LookupPartIndex_LoadReg2:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_LoadReg2.bin"
LookupPartIndex_LoadReg3:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_LoadReg3.bin"
LookupPartIndex_LoadReg4:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_LoadReg4.bin"
LookupPartIndex_LoadReg5:
	.incbin "includes/generated/v7_transplant_LookupPartIndex_LoadReg5.bin"
CommPacket_WriteMeasureCount:
	.incbin "includes/generated/v7_transplant_CommPacket_WriteMeasureCount.bin"
CommPacket_WriteMeas_Block:
	.incbin "includes/generated/v7_transplant_CommPacket_WriteMeas_Block.bin"
SendCOMM_VariableLengthPacket:
	.incbin "includes/generated/v7_transplant_SendCOMM_VariableLengthPacket.bin"
SendCOMM_VariableLen_LoadReg:
	.incbin "includes/generated/v7_transplant_SendCOMM_VariableLen_LoadReg.bin"
SendCOMM_VariableLen_Increment:
	.incbin "includes/generated/v7_transplant_SendCOMM_VariableLen_Increment.bin"
COMM_BuildAndSendPacket:
	.incbin "includes/generated/v7_transplant_COMM_BuildAndSendPacket.bin"
BuildAndSendPacket_Block:
	.incbin "includes/generated/v7_transplant_BuildAndSendPacket_Block.bin"
TmFlash_Return:
	.incbin "includes/generated/v7_transplant_TmFlash_Return.bin"
TmFlash_Return_Prologue:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_Prologue.bin"
TmFlash_Return_LoadReg:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadReg.bin"
TmFlash_Return_CheckZero:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_CheckZero.bin"
TmFlash_Return_LoadParam:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadParam.bin"
TmFlash_Return_LoadParam2:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadParam2.bin"
TmFlash_Return_LoadDRAM:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadDRAM.bin"
TmFlash_Return_LoadDRAM2:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadDRAM2.bin"
TmFlash_Return_LoadDRAM3:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadDRAM3.bin"
TmFlash_Return_LoadDRAM4:
	.incbin "includes/generated/v7_transplant_TmFlash_Return_LoadDRAM4.bin"
CommParam_SetComplete_Return:
	.incbin "includes/generated/v7_transplant_CommParam_SetComplete_Return.bin"
CommParam_SetComplete_Block:
	.incbin "includes/generated/v7_transplant_CommParam_SetComplete_Block.bin"
CommParam_SetComplete_Block2:
	.incbin "includes/generated/v7_transplant_CommParam_SetComplete_Block2.bin"
CommParam_SetComplete_Return2:
	.incbin "includes/generated/v7_transplant_CommParam_SetComplete_Return2.bin"
CommParam_SetComplete_Return3:
	.incbin "includes/generated/v7_transplant_CommParam_SetComplete_Return3.bin"
CommPort_StatusCheckAndSend:
	.incbin "includes/generated/v7_transplant_CommPort_StatusCheckAndSend.bin"
CommPort_StatusCheck_Compare:
	.incbin "includes/generated/v7_transplant_CommPort_StatusCheck_Compare.bin"
Note_CheckValidityReturn:
	.incbin "includes/generated/v7_transplant_Note_CheckValidityReturn.bin"
CheckValidityReturn_SetByteFF:
	.incbin "includes/generated/v7_transplant_CheckValidityReturn_SetByteFF.bin"
CheckValidityReturn_Return:
	.incbin "includes/generated/v7_transplant_CheckValidityReturn_Return.bin"
COMM_SendPartDataBlock:
	.incbin "includes/generated/v7_transplant_COMM_SendPartDataBlock.bin"
SendPartDataBlock_LoadParam:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadParam.bin"
SendPartDataBlock_RestoreReg:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_RestoreReg.bin"
SendPartDataBlock_Block:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block.bin"
SendPartDataBlock_Block2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block2.bin"
SendPartDataBlock_Block3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block3.bin"
SendPartDataBlock_Block4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block4.bin"
SendPartDataBlock_ClearByte:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_ClearByte.bin"
SendPartDataBlock_Block5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block5.bin"
SendPartDataBlock_ClearByte2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_ClearByte2.bin"
SendPartDataBlock_Block6:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block6.bin"
SendPartDataBlock_Block7:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block7.bin"
SendPartDataBlock_StoreDRAM:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_StoreDRAM.bin"
SendPartDataBlock_ClearByte3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_ClearByte3.bin"
SendPartDataBlock_Block8:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block8.bin"
SendPartDataBlock_Block9:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block9.bin"
SendPartDataBlock_InitVal:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal.bin"
SendPartDataBlock_SetWord:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord.bin"
SendPartDataBlock_Return:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Return.bin"
SendPartDataBlock_Prologue:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Prologue.bin"
SendPartDataBlock_SetWord2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord2.bin"
SendPartDataBlock_Epilogue:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Epilogue.bin"
SendPartDataBlock_InitVal2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal2.bin"
SendPartDataBlock_SetWord3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord3.bin"
SendPartDataBlock_Return2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Return2.bin"
SendPartDataBlock_InitVal3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal3.bin"
SendPartDataBlock_SetWord4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord4.bin"
SendPartDataBlock_Return3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Return3.bin"
SendPartDataBlock_SetWord5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord5.bin"
SendPartDataBlock_Block10:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block10.bin"
SendPartDataBlock_ClearByte4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_ClearByte4.bin"
SendPartDataBlock_LoadReg:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg.bin"
SendPartDataBlock_Compare:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare.bin"
SendPartDataBlock_SetWord6:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord6.bin"
SendPartDataBlock_Return4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Return4.bin"
SendPartDataBlock_DoGetError:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_DoGetError.bin"
SendPartDataBlock_Return5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Return5.bin"
SendPartDataBlock_Data:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Data.bin"
SendPartDataBlock_Data2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Data2.bin"
SendPartDataBlock_Data3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Data3.bin"
SendPartDataBlock_Data4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Data4.bin"
SendPartDataBlock_Data5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Data5.bin"
SendPartDataBlock_InitVal4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal4.bin"
SendPartDataBlock_LoadReg2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg2.bin"
SendPartDataBlock_Compare2:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare2.bin"
SendPartDataBlock_InitVal5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal5.bin"
SendPartDataBlock_LoadReg3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg3.bin"
SendPartDataBlock_Compare3:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare3.bin"
SendPartDataBlock_InitVal6:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal6.bin"
SendPartDataBlock_LoadReg4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg4.bin"
SendPartDataBlock_Compare4:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare4.bin"
SendPartDataBlock_InitVal7:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal7.bin"
SendPartDataBlock_LoadReg5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg5.bin"
SendPartDataBlock_Compare5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare5.bin"
SendPartDataBlock_InitVal8:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal8.bin"
SendPartDataBlock_LoadReg6:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg6.bin"
SendPartDataBlock_Compare6:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare6.bin"
SendPartDataBlock_InitVal9:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_InitVal9.bin"
SendPartDataBlock_LoadReg7:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_LoadReg7.bin"
SendPartDataBlock_Compare7:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Compare7.bin"
SendPartDataBlock_ClearByte5:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_ClearByte5.bin"
SendPartDataBlock_SetWord7:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_SetWord7.bin"
SendPartDataBlock_Block11:
	.incbin "includes/generated/v7_transplant_SendPartDataBlock_Block11.bin"
HdaeRom_DataHandler:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataHandler.bin"
HdaeRom_DataDispatch:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataDispatch.bin"
HdaeRom_DataDispatch_SetWord:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataDispatch_SetWord.bin"
HdaeRom_DataDispatch_Block:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataDispatch_Block.bin"
HdaeRom_DataDispatch_Block2:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataDispatch_Block2.bin"
HdaeRom_DataDispatch_Block3:
	.incbin "includes/generated/v7_transplant_HdaeRom_DataDispatch_Block3.bin"
HdaeRom_AltHandler:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltHandler.bin"
HdaeRom_AltDispatch:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltDispatch.bin"
HdaeRom_AltDispatch_SetWord:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltDispatch_SetWord.bin"
HdaeRom_AltDispatch_Block:
	.incbin "includes/generated/v7_transplant_HdaeRom_AltDispatch_Block.bin"
PreTmLoad:
	ret

PostTmLoad:
	.incbin "includes/generated/v7_transplant_PostTmLoad.bin"
PostTmLoad_Send:
	.incbin "includes/generated/v7_transplant_PostTmLoad_Send.bin"
PostTmLoad_Block:
	.incbin "includes/generated/v7_transplant_PostTmLoad_Block.bin"
PreTmSave:
	.incbin "includes/generated/v7_transplant_PreTmSave.bin"
PostTmSave:
	.incbin "includes/generated/v7_transplant_PostTmSave.bin"
PostTmSave_ByteBlock:
	.incbin "includes/generated/v7_transplant_PostTmSave_ByteBlock.bin"
PostTmSave_Success:
	.incbin "includes/generated/v7_transplant_PostTmSave_Success.bin"
PostTmSave_Failure:
	.incbin "includes/generated/v7_transplant_PostTmSave_Failure.bin"
PostTmSave_JumpToRestore:
	.incbin "includes/generated/v7_transplant_PostTmSave_JumpToRestore.bin"
TmFlashWrite_Block1:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_Block1.bin"
TmFlashWrite_Block1_Entry:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_Block1_Entry.bin"
TmFlashWrite_Block1_Return:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_Block1_Return.bin"
TmFlashWrite_ValidateParams:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_ValidateParams.bin"
TmFlashWrite_Block2:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_Block2.bin"
TmFlashWrite_Block3:
	.incbin "includes/generated/v7_transplant_TmFlashWrite_Block3.bin"
TmFlash_CopyToExtMem:
	.incbin "includes/generated/v7_transplant_TmFlash_CopyToExtMem.bin"
TmFlash_WriteRoutine:
	.incbin "includes/generated/v7_transplant_TmFlash_WriteRoutine.bin"
TmFlash_BulkTransferToSubCPU:
	.incbin "includes/generated/v7_transplant_TmFlash_BulkTransferToSubCPU.bin"
VoiceParam_DispatchTable1:
	.incbin "includes/generated/v7_transplant_VoiceParam_DispatchTable1.bin"
TmFlash_CompareStrings:
	.incbin "includes/generated/v7_transplant_TmFlash_CompareStrings.bin"
StrSearch_Init:
	.incbin "includes/generated/v7_transplant_StrSearch_Init.bin"
StrSearch_LoadNeedle:
	.incbin "includes/generated/v7_transplant_StrSearch_LoadNeedle.bin"
StrSearch_CompareChar:
	.incbin "includes/generated/v7_transplant_StrSearch_CompareChar.bin"
StrSearch_CheckNeedleEnd:
	.incbin "includes/generated/v7_transplant_StrSearch_CheckNeedleEnd.bin"
StrSearch_CheckHaystackEnd:
	.incbin "includes/generated/v7_transplant_StrSearch_CheckHaystackEnd.bin"
ParseInt16:
	.incbin "includes/generated/v7_transplant_ParseInt16.bin"
ParseInt16_SkipWhitespace:
	.incbin "includes/generated/v7_transplant_ParseInt16_SkipWhitespace.bin"
ParseInt16_CheckWhitespace:
	.incbin "includes/generated/v7_transplant_ParseInt16_CheckWhitespace.bin"
ParseInt16_CheckMinus:
	.incbin "includes/generated/v7_transplant_ParseInt16_CheckMinus.bin"
ParseInt16_SkipSign:
	.incbin "includes/generated/v7_transplant_ParseInt16_SkipSign.bin"
ParseInt16_DigitLoop:
	.incbin "includes/generated/v7_transplant_ParseInt16_DigitLoop.bin"
ParseInt16_ApplySign:
	.incbin "includes/generated/v7_transplant_ParseInt16_ApplySign.bin"
ParseInt16_Positive:
	.incbin "includes/generated/v7_transplant_ParseInt16_Positive.bin"
ParseInt16_Return:
	.incbin "includes/generated/v7_transplant_ParseInt16_Return.bin"
ParseInt32:
	.incbin "includes/generated/v7_transplant_ParseInt32.bin"
ParseInt32_SkipWhitespace:
	.incbin "includes/generated/v7_transplant_ParseInt32_SkipWhitespace.bin"
ParseInt32_CheckWhitespace:
	.incbin "includes/generated/v7_transplant_ParseInt32_CheckWhitespace.bin"
ParseInt32_CheckMinus:
	.incbin "includes/generated/v7_transplant_ParseInt32_CheckMinus.bin"
ParseInt32_SkipSign:
	.incbin "includes/generated/v7_transplant_ParseInt32_SkipSign.bin"
ParseInt32_DigitLoop:
	.incbin "includes/generated/v7_transplant_ParseInt32_DigitLoop.bin"
ParseInt32_ApplySign:
	.incbin "includes/generated/v7_transplant_ParseInt32_ApplySign.bin"
ParseInt32_Positive:
	.incbin "includes/generated/v7_transplant_ParseInt32_Positive.bin"
ParseInt32_Return:
	.incbin "includes/generated/v7_transplant_ParseInt32_Return.bin"
Math_MultiplyAccumulate:
	.incbin "includes/generated/v7_transplant_Math_MultiplyAccumulate.bin"
Sprintf_Locked:
	.incbin "includes/generated/v7_transplant_Sprintf_Locked.bin"
Sprintf_Unlocked:
	.incbin "includes/generated/v7_transplant_Sprintf_Unlocked.bin"
Sprintf_OutputCallback:
	.incbin "includes/generated/v7_transplant_Sprintf_OutputCallback.bin"
Free:
	.incbin "includes/generated/v7_transplant_Free.bin"
Free_Block:
	.incbin "includes/generated/v7_transplant_Free_Block.bin"
Free_Compare:
	.incbin "includes/generated/v7_transplant_Free_Compare.bin"
Free_Compare2:
	.incbin "includes/generated/v7_transplant_Free_Compare2.bin"
Free_LoadReg:
	.incbin "includes/generated/v7_transplant_Free_LoadReg.bin"
Free_Block2:
	.incbin "includes/generated/v7_transplant_Free_Block2.bin"
Free_Block3:
	.incbin "includes/generated/v7_transplant_Free_Block3.bin"
Free_OrBits:
	.incbin "includes/generated/v7_transplant_Free_OrBits.bin"
Free_LoadReg2:
	.incbin "includes/generated/v7_transplant_Free_LoadReg2.bin"
Free_LoadReg3:
	.incbin "includes/generated/v7_transplant_Free_LoadReg3.bin"
Free_LoadReg4:
	.incbin "includes/generated/v7_transplant_Free_LoadReg4.bin"
Free_InitVal:
	.incbin "includes/generated/v7_transplant_Free_InitVal.bin"
Free_ClearByte:
	.incbin "includes/generated/v7_transplant_Free_ClearByte.bin"
Free_Block4:
	.incbin "includes/generated/v7_transplant_Free_Block4.bin"
Free_Prologue:
	.incbin "includes/generated/v7_transplant_Free_Prologue.bin"
Free_Compare3:
	.incbin "includes/generated/v7_transplant_Free_Compare3.bin"
Free_OrBits2:
	.incbin "includes/generated/v7_transplant_Free_OrBits2.bin"
Free_ClearByte2:
	.incbin "includes/generated/v7_transplant_Free_ClearByte2.bin"
Math_DivideSigned32:
	.incbin "includes/generated/v7_transplant_Math_DivideSigned32.bin"
DivMod32:
	.incbin "includes/generated/v7_transplant_DivMod32.bin"
Math_DivideU32:
	.incbin "includes/generated/v7_transplant_Math_DivideU32.bin"
Math_DivideU32_Block:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Block.bin"
Math_DivideU32_LoadReg:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_LoadReg.bin"
Math_DivideU32_Block2:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Block2.bin"
Math_DivideU32_Block3:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Block3.bin"
Math_DivideU32_ClearByte:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_ClearByte.bin"
Math_DivideU32_Compare:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Compare.bin"
Math_DivideU32_Shift:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Shift.bin"
Math_DivideU32_Block4:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Block4.bin"
Math_DivideU32_Compute:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Compute.bin"
Math_DivideU32_Shift2:
	.incbin "includes/generated/v7_transplant_Math_DivideU32_Shift2.bin"
Strncat:
	.incbin "includes/generated/v7_transplant_Strncat.bin"
Strncat_NextIter:
	.incbin "includes/generated/v7_transplant_Strncat_NextIter.bin"
Strncat_CheckZero:
	.incbin "includes/generated/v7_transplant_Strncat_CheckZero.bin"
Strncat_LoadReg:
	.incbin "includes/generated/v7_transplant_Strncat_LoadReg.bin"
Strncat_LoadReg2:
	.incbin "includes/generated/v7_transplant_Strncat_LoadReg2.bin"
String_Compare:
	.incbin "includes/generated/v7_transplant_String_Compare.bin"
String_Compare_CheckZero:
	.incbin "includes/generated/v7_transplant_String_Compare_CheckZero.bin"
String_Compare_NextIter:
	.incbin "includes/generated/v7_transplant_String_Compare_NextIter.bin"
String_Compare_Compare:
	.incbin "includes/generated/v7_transplant_String_Compare_Compare.bin"
String_Compare_ClearByte:
	.incbin "includes/generated/v7_transplant_String_Compare_ClearByte.bin"
String_Compare_Extend:
	.incbin "includes/generated/v7_transplant_String_Compare_Extend.bin"
Strncpy:
	.incbin "includes/generated/v7_transplant_Strncpy.bin"
Strncpy_Block:
	.incbin "includes/generated/v7_transplant_Strncpy_Block.bin"
Strncpy_Compare:
	.incbin "includes/generated/v7_transplant_Strncpy_Compare.bin"
Strncpy_Block2:
	.incbin "includes/generated/v7_transplant_Strncpy_Block2.bin"
Strncpy_Block3:
	.incbin "includes/generated/v7_transplant_Strncpy_Block3.bin"
Strncpy_Compare2:
	.incbin "includes/generated/v7_transplant_Strncpy_Compare2.bin"
Mem_Compare:
	.incbin "includes/generated/v7_transplant_Mem_Compare.bin"
Mem_Compare_Block:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Block.bin"
Mem_Compare_LoadReg:
	.incbin "includes/generated/v7_transplant_Mem_Compare_LoadReg.bin"
Mem_Compare_Block2:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Block2.bin"
Mem_Compare_Compare:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Compare.bin"
Mem_Compare_Extend:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Extend.bin"
Mem_Compare_Block3:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Block3.bin"
Mem_Compare_MaskBits:
	.incbin "includes/generated/v7_transplant_Mem_Compare_MaskBits.bin"
Mem_Compare_Block4:
	.incbin "includes/generated/v7_transplant_Mem_Compare_Block4.bin"
Mem_Copy:
	.incbin "includes/generated/v7_transplant_Mem_Copy.bin"
Mem_Copy_Shift:
	.incbin "includes/generated/v7_transplant_Mem_Copy_Shift.bin"
Mem_Copy_Block:
	.incbin "includes/generated/v7_transplant_Mem_Copy_Block.bin"
Strcat:
	.incbin "includes/generated/v7_transplant_Strcat.bin"
Strcat_NextIter:
	.incbin "includes/generated/v7_transplant_Strcat_NextIter.bin"
Strcat_CheckZero:
	.incbin "includes/generated/v7_transplant_Strcat_CheckZero.bin"
Strcat_Block:
	.incbin "includes/generated/v7_transplant_Strcat_Block.bin"
Strcat_CheckZero2:
	.incbin "includes/generated/v7_transplant_Strcat_CheckZero2.bin"
Itoa_Safe:
	.incbin "includes/generated/v7_transplant_Itoa_Safe.bin"
Itoa_Safe_LoadReg:
	.incbin "includes/generated/v7_transplant_Itoa_Safe_LoadReg.bin"
Itoa:
	.incbin "includes/generated/v7_transplant_Itoa.bin"
NumFormat_DivideAndConvert:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndConvert.bin"
NumFormat_DivideAndC_Block:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndC_Block.bin"
NumFormat_DivideAndC_Compare:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndC_Compare.bin"
NumFormat_DivideAndC_LoadAddr:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndC_LoadAddr.bin"
NumFormat_DivideAndC_Epilogue:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndC_Epilogue.bin"
NumFormat_DivideAndC_Data:
	.incbin "includes/generated/v7_transplant_NumFormat_DivideAndC_Data.bin"
Malloc:
	.incbin "includes/generated/v7_transplant_Malloc.bin"
Malloc_LoadReg:
	.incbin "includes/generated/v7_transplant_Malloc_LoadReg.bin"
Malloc_OrBits:
	.incbin "includes/generated/v7_transplant_Malloc_OrBits.bin"
Malloc_Block:
	.incbin "includes/generated/v7_transplant_Malloc_Block.bin"
Malloc_LoadParam:
	.incbin "includes/generated/v7_transplant_Malloc_LoadParam.bin"
Malloc_LoadParam2:
	.incbin "includes/generated/v7_transplant_Malloc_LoadParam2.bin"
Malloc_Block2:
	.incbin "includes/generated/v7_transplant_Malloc_Block2.bin"
Malloc_DoSignalEv:
	.incbin "includes/generated/v7_transplant_Malloc_DoSignalEv.bin"
Malloc_Epilogue:
	.incbin "includes/generated/v7_transplant_Malloc_Epilogue.bin"
Strcmp:
	.incbin "includes/generated/v7_transplant_Strcmp.bin"
Strcpy:
	.incbin "includes/generated/v7_transplant_Strcpy.bin"
Strcpy_LoadReg:
	.incbin "includes/generated/v7_transplant_Strcpy_LoadReg.bin"
Heap_Alloc:
	.incbin "includes/generated/v7_transplant_Heap_Alloc.bin"
Heap_Alloc_Block:
	.incbin "includes/generated/v7_transplant_Heap_Alloc_Block.bin"
Heap_Grow:
	.incbin "includes/generated/v7_transplant_Heap_Grow.bin"
Strlen:
	.incbin "includes/generated/v7_transplant_Strlen.bin"
Strlen_Compute:
	.incbin "includes/generated/v7_transplant_Strlen_Compute.bin"
Strlen_Epilogue:
	.incbin "includes/generated/v7_transplant_Strlen_Epilogue.bin"
Strlen_LoadParam:
	.incbin "includes/generated/v7_transplant_Strlen_LoadParam.bin"
Itoa_WithBase:
	.incbin "includes/generated/v7_transplant_Itoa_WithBase.bin"
Memset:
	.incbin "includes/generated/v7_transplant_Memset.bin"
Memset_Block:
	.incbin "includes/generated/v7_transplant_Memset_Block.bin"
Memset_LoadReg:
	.incbin "includes/generated/v7_transplant_Memset_LoadReg.bin"
Memset_Block2:
	.incbin "includes/generated/v7_transplant_Memset_Block2.bin"
Memset_MaskBits:
	.incbin "includes/generated/v7_transplant_Memset_MaskBits.bin"
Memset_Block3:
	.incbin "includes/generated/v7_transplant_Memset_Block3.bin"
Math_AbsInt16:
	ld hl, (xsp + 4)
	cps hl, 0
	ret ge
	neg hl
	ret

	.include "audio/sprintf_core.s"
