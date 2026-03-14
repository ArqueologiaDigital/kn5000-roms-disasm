#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in note_voice_mapping.s to semantic names.

Uses binary I/O to preserve Latin-1 bytes.

Usage:
    python3 scripts/rename_nvm_labels.py analyze   # Show planned renames
    python3 scripts/rename_nvm_labels.py apply      # Apply renames
"""

import sys
import os
import re
import glob

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_FILE = os.path.join(REPO, 'maincpu', 'audio', 'note_voice_mapping.s')


def read_file(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)


# Map: old_label -> new_label
# Each rename is based on careful analysis of the code context.
RENAMES = {
    # =========================================================================
    # Top-level entry / note-on processing (FE0245-FE06E0)
    # =========================================================================
    'LABEL_FE0245': 'NoteOn_EntryPoint',
    'LABEL_FE0275': 'NoteOn_DispatchByStatus',
    'LABEL_FE0293': 'NoteOn_ChannelScanLoop_NoteOn',
    'LABEL_FE02DB': 'NoteOn_AutoPlayVoiceLoop',
    'LABEL_FE0317': 'NoteOn_AutoPlayNext',
    'LABEL_FE0319': 'NoteOn_AutoPlayCheckCount',
    'LABEL_FE0354': 'NoteOn_VoiceLookupAndAssign',
    'LABEL_FE03B5': 'NoteOn_MergeLayer1',
    'LABEL_FE03E8': 'NoteOn_MergeLayer2',
    'LABEL_FE041B': 'NoteOn_MergeLayer3',
    'LABEL_FE0453': 'NoteOn_CheckSpecialChannel',
    'LABEL_FE046F': 'NoteOn_SpecialChannelUpdate',
    'LABEL_FE0480': 'NoteOn_CheckLayer3Only',
    'LABEL_FE04B4': 'NoteOn_UpdateByChannelType',
    'LABEL_FE04CE': 'NoteOn_PostAutoPlay',
    'LABEL_FE04D2': 'NoteOn_AdvanceChannel',
    'LABEL_FE04E0': 'NoteOn_ChannelScanLoop_CC',
    'LABEL_FE04ED': 'NoteOn_ChannelScanCC_Body',
    'LABEL_FE0544': 'NoteOn_CC_VoiceLookupAndAssign',
    'LABEL_FE05A4': 'NoteOn_CC_MergeLayer1',
    'LABEL_FE05D7': 'NoteOn_CC_MergeLayer2',
    'LABEL_FE060A': 'NoteOn_CC_MergeLayer3',
    'LABEL_FE0642': 'NoteOn_CC_CheckSpecialChannel',
    'LABEL_FE065D': 'NoteOn_CC_SpecialUpdate',
    'LABEL_FE066E': 'NoteOn_CC_CheckLayer3Only',
    'LABEL_FE06A2': 'NoteOn_CC_UpdateByChannelType',
    'LABEL_FE06E0': 'NoteOn_Epilogue',

    # =========================================================================
    # AccNoteOn processing (FE0721-FE09BB)
    # =========================================================================
    'LABEL_FE0721': 'AccNoteOn_AssignVoices',
    'LABEL_FE0730': 'AccNoteOn_AutoPlayLoop',
    'LABEL_FE0762': 'AccNoteOn_AutoPlayNext',
    'LABEL_FE0764': 'AccNoteOn_AutoPlayCheck',
    'LABEL_FE077F': 'AccNoteOn_FindMinVelocity_Loop',
    'LABEL_FE07AA': 'AccNoteOn_UseEntryVelocity',
    'LABEL_FE07BA': 'AccNoteOn_StoreMinVelocity',
    'LABEL_FE07BC': 'AccNoteOn_MinVelocity_Next',
    'LABEL_FE07BE': 'AccNoteOn_MinVelocity_Check',
    'LABEL_FE07D0': 'AccNoteOn_EmitVoiceLoop_Init',
    'LABEL_FE07D6': 'AccNoteOn_EmitVoiceLoop_Body',
    'LABEL_FE0808': 'AccNoteOn_EmitVoiceLoop_Check',
    'LABEL_FE084F': 'AccNoteOn_MergeLayer1',
    'LABEL_FE0882': 'AccNoteOn_MergeLayer2',
    'LABEL_FE09BB': 'AccNoteOn_Return',

    # =========================================================================
    # AccMidi / Rhythm MIDI processing
    # =========================================================================
    'LABEL_FE0AFD': 'AccMidi_Return',
    'LABEL_FE09F0': 'AccMidi_DispatchLoop',
    'LABEL_FE0B40': 'RhythmMidi_DispatchByStatus',
    'LABEL_FE0B88': 'RhythmMidi_NoteOn_Remap98',

    # =========================================================================
    # Voice_InitializeAll internal labels (FE0E96-FE1063)
    # =========================================================================
    'LABEL_FE0E96': 'VoiceInit_PartLoop',
    'LABEL_FE0EA9': 'VoiceInit_ChannelLoop',
    'LABEL_FE0F00': 'VoiceInit_LookupTableAndAssign',
    'LABEL_FE0F5C': 'VoiceInit_MergeLayer1',
    'LABEL_FE0F88': 'VoiceInit_MergeLayer2',
    'LABEL_FE0FB4': 'VoiceInit_MergeLayer3',
    'LABEL_FE0FE4': 'VoiceInit_CheckSpecialChannel',
    'LABEL_FE0FFC': 'VoiceInit_SpecialChannelUpdate',
    'LABEL_FE100C': 'VoiceInit_CheckLayer3Only',
    'LABEL_FE1039': 'VoiceInit_UpdateByChannelType',
    'LABEL_FE1059': 'VoiceInit_ChannelNext',
    'LABEL_FE1063': 'VoiceInit_Epilogue',

    # =========================================================================
    # NoteMap_ProcessAndMerge internal labels (FE10CC-FE1170)
    # =========================================================================
    'LABEL_FE10CC': 'NoteMap_ProcessMerge_Layer1',
    'LABEL_FE10F4': 'NoteMap_ProcessMerge_Layer2',
    'LABEL_FE111C': 'NoteMap_ProcessMerge_Layer3',
    'LABEL_FE1147': 'NoteMap_ProcessMerge_SpecialPath',
    'LABEL_FE1170': 'NoteMap_ProcessMerge_UpdateChannel',

    # =========================================================================
    # NoteMap_SendAllNotesOff internal (FE11A5-FE120C)
    # =========================================================================
    'LABEL_FE11A5': 'NoteOff_PartLoop_Body',
    'LABEL_FE11D6': 'NoteOff_PartLoop_Layer3',
    'LABEL_FE1203': 'NoteOff_PartLoop_Next',
    'LABEL_FE120C': 'NoteOff_Return',

    # =========================================================================
    # Voice_InitTableGroup internal (FE1234-FE125D)
    # =========================================================================
    'LABEL_FE1234': 'VoiceTableGroup_PartLoop',
    'LABEL_FE125D': 'VoiceTableGroup_Return',

    # =========================================================================
    # VoiceEvent dispatch (FE12B7-FE1445)
    # =========================================================================
    'LABEL_FE12B7': 'VoiceEvent_ResetAndInit',
    'LABEL_FE12FC': 'VoiceEvent_DispatchTable',
    'LABEL_FE1311': 'VoiceEvent_HandlerTable',
    'LABEL_FE1445': 'VoiceEvent_FlushAndReturn',

    # =========================================================================
    # Voice slot claim sequences (FE1528-FE1728)
    # =========================================================================
    'LABEL_FE1598': 'VoiceClaim_Slot1_Init',
    'LABEL_FE15C8': 'VoiceClaim_Slot1_MarkLoop',
    'LABEL_FE15DE': 'VoiceClaim_Slot1_MarkCheck',
    'LABEL_FE15FB': 'VoiceClaim_Slot2_Init',
    'LABEL_FE162B': 'VoiceClaim_Slot2_MarkLoop',
    'LABEL_FE1641': 'VoiceClaim_Slot2_MarkCheck',
    'LABEL_FE165E': 'VoiceClaim_Slot3_Init',
    'LABEL_FE168E': 'VoiceClaim_Slot3_MarkLoop',
    'LABEL_FE16A4': 'VoiceClaim_Slot3_MarkCheck',
    'LABEL_FE16C1': 'VoiceClaim_Slot6_Init',
    'LABEL_FE16F2': 'VoiceClaim_Slot6_MarkLoop',
    'LABEL_FE1708': 'VoiceClaim_Slot6_MarkCheck',
    'LABEL_FE1728': 'VoiceClaim_Extended_Init',

    # =========================================================================
    # MidiEvent_ConfigChannel internal (FE1C37-FE1CB3)
    # =========================================================================
    'LABEL_FE1C37': 'MidiConfig_Slot6Path',
    'LABEL_FE1CB3': 'MidiConfig_Return',

    # =========================================================================
    # Voice_InitSlotData internal (FE1CE3-FE1D13)
    # =========================================================================
    'LABEL_FE1CE3': 'VoiceSlotInit_Loop',
    'LABEL_FE1D13': 'VoiceSlotInit_Check',

    # =========================================================================
    # NoteMap_AssignAllVoiceLinks internal (FE1D5C-FE1E7B)
    # =========================================================================
    'LABEL_FE1D5C': 'VoiceLinks_SlotLoop',
    'LABEL_FE1DFC': 'VoiceLinks_SkipEmpty',
    'LABEL_FE1E7B': 'VoiceLinks_CheckCount',

    # =========================================================================
    # MidiEvent_ParseNoteSequence / NoteSeqCount internal
    # =========================================================================
    'LABEL_FE21DB': 'MidiEvent_ReadAndParseLoop',
    'LABEL_FE24B1': 'RhythmBuf_ParseEventLoop',
    'LABEL_FE250E': 'RhythmParse_ReadFromBuffer',
    'LABEL_FE2517': 'RhythmParse_ReadNote',
    'LABEL_FE252D': 'RhythmParse_ReadVelocity',
    'LABEL_FE2545': 'RhythmParse_ReadDuration',
    'LABEL_FE2559': 'RhythmParse_CheckNoteOnType',
    'LABEL_FE25BC': 'RhythmParse_StoreCCAndNote',
    'LABEL_FE25E1': 'RhythmParse_CheckAccType',
    'LABEL_FE2698': 'RhythmParse_AppendNoteEntry',
    'LABEL_FE2728': 'RhythmParse_TruncateCount',
    'LABEL_FE2735': 'RhythmParse_StoreCountAndReturn',
    'LABEL_FE249F': 'VoiceNotify_SendAllNotesOff',
    'LABEL_FE24AC': 'VoiceNotify_Epilogue',

    # =========================================================================
    # NoteMap_EncodeControlChange (FE2781-FE27D6)
    # =========================================================================
    'LABEL_FE273A': 'SeqEvtBuf_ParseEventLoop',

    # =========================================================================
    # NoteMap_CollectAndFindBestVoice internal (FE2E18-FE2E4B)
    # =========================================================================
    'LABEL_FE2E18': 'CollectBestVoice_EmitLoop',
    'LABEL_FE2E3F': 'CollectBestVoice_EmitNext',
    'LABEL_FE2E4B': 'CollectBestVoice_NonSpecialPath',

    # =========================================================================
    # NoteMap_CollectAndAllocVoice internal (FE2F32-FE2FB9)
    # =========================================================================
    'LABEL_FE2F32': 'CollectAllocVoice_CheckDuplicate',
    'LABEL_FE2F73': 'CollectAllocVoice_EmitCheck',
    'LABEL_FE2F85': 'CollectAllocVoice_EmitLoop',

    # =========================================================================
    # NoteMap_UpdateEntry internal (FE3428-FE34FE)
    # =========================================================================
    'LABEL_FE3428': 'UpdateEntry_EmitLoop',
    'LABEL_FE344B': 'UpdateEntry_EmitNext',
    'LABEL_FE3454': 'UpdateEntry_CheckLayerCount',
    'LABEL_FE346A': 'UpdateEntry_NonSpecialPath',
    'LABEL_FE34D2': 'UpdateEntry_DirectEmitLoop',
    'LABEL_FE34F5': 'UpdateEntry_DirectEmitNext',
    'LABEL_FE34FE': 'UpdateEntry_CheckSeqPartEmit',
    'LABEL_FE3524': 'UpdateEntry_CheckMidiEmit',
    'LABEL_FE354A': 'UpdateEntry_CheckLayerResult',

    # =========================================================================
    # NoteMap_FindAndAllocBestVoice internal (FE3627+)
    # =========================================================================
    'LABEL_FE3627': 'FindAllocBest_NonSpecialPath',

    # =========================================================================
    # NoteMap_LookupVoice internal (FE4735-FE495C)
    # =========================================================================
    'LABEL_FE4735': 'LookupVoice_RejectOutOfRange',
    'LABEL_FE473E': 'LookupVoice_StartLookup',
    'LABEL_FE47A4': 'LookupVoice_ScanEntries',
    'LABEL_FE4849': 'LookupVoice_AdvanceAndCheck',
    'LABEL_FE4861': 'LookupVoice_WithInstrument',
    'LABEL_FE4878': 'LookupVoice_InstrScanEntries',

    # =========================================================================
    # NoteMap_MergeEntries internal (FE5C4C-FE5CAB)
    # =========================================================================
    'LABEL_FE5C4C': 'MergeEntries_FilterLoop',
    'LABEL_FE5CA9': 'MergeEntries_NextEntry',
    'LABEL_FE5CAB': 'MergeEntries_CheckCount',

    # =========================================================================
    # NoteMap_ResetEntryTimers internal (FE5CD7-FE5D2D)
    # =========================================================================
    'LABEL_FE5CD7': 'ResetTimers_Loop',
    'LABEL_FE5D2D': 'ResetTimers_Return',
    'LABEL_FE5D1D': 'ResetTimers_CheckCount',

    # =========================================================================
    # Voice_ScanAndEmitMidiEvents internal (FE50E0-FE51F5)
    # =========================================================================
    'LABEL_FE50E0': 'ScanEmitMidi_VoiceLoop',
    'LABEL_FE5180': 'ScanEmitMidi_ValidFormat',
    'LABEL_FE51F2': 'ScanEmitMidi_NextVoice',
    'LABEL_FE51F5': 'ScanEmitMidi_CheckVoiceCount',

    # =========================================================================
    # Voice_BuildAndEmitNoteOnEvents internal (FE5228-FE5322)
    # =========================================================================
    'LABEL_FE5228': 'BuildNoteOn_VoiceLoop',
    'LABEL_FE52F5': 'BuildNoteOn_NextVoice',
    'LABEL_FE5322': 'BuildNoteOn_CheckVoiceCount',

    # =========================================================================
    # Synth voice data writing (FE5B45-FE5C28)
    # =========================================================================
    'LABEL_FE5B45': 'SynthVoice_WriteLoop',
    'LABEL_FE5C04': 'SynthVoice_FlushBuffer',
    'LABEL_FE5C19': 'SynthVoice_NextVoice',
    'LABEL_FE5C1B': 'SynthVoice_CheckVoiceCount',
    'LABEL_FE5C28': 'SynthVoice_Return',

    # =========================================================================
    # MIDI voice data sending (FE5002-FE50CA)
    # =========================================================================
    'LABEL_FE5002': 'MIDI_SendVoiceData_Loop',
    'LABEL_FE50B6': 'MIDI_SendVoiceData_CheckCount',
    'LABEL_FE50CA': 'MIDI_SendVoiceData_Return',

    # =========================================================================
    # NoteMap_ComputePitchOffset internal (FE6375-FE648E)
    # =========================================================================
    'LABEL_FE6375': 'PitchOffset_NegativeDir',
    'LABEL_FE637D': 'PitchOffset_BothDirs',
    'LABEL_FE638B': 'Synth_InitChannelState_Body',
    'LABEL_FE641E': 'Synth_OctaveDown_Loop',
    'LABEL_FE642C': 'Synth_CheckNegative',
    'LABEL_FE643E': 'Synth_StoreTransposedNote',
    'LABEL_FE644A': 'Synth_SkipTranspose',
    'LABEL_FE648E': 'Synth_InitChannelState_Check',
    'LABEL_FE648B': 'Synth_InitChannelState_Next',

    # =========================================================================
    # Note transpose range check (FE6274-FE6294)
    # =========================================================================
    'LABEL_FE6274': 'TransposeRange_OctaveDown',
    'LABEL_FE6282': 'TransposeRange_CheckLow',
    'LABEL_FE6289': 'TransposeRange_OctaveUp',
    'LABEL_FE6294': 'TransposeRange_Clamp',
    'LABEL_FE62A0': 'TransposeRange_LookupParam',
    'LABEL_FE62E1': 'Synth_WriteParam_Next',
    'LABEL_FE62E4': 'Synth_WriteParam_Check',
    'LABEL_FE61E1': 'Synth_WriteParam_Loop',

    # =========================================================================
    # NoteMap_AssignVoiceParams internal (FE3F43-FE3F55)
    # =========================================================================
    'LABEL_FE3F43': 'AssignVoiceParams_SetChannel',
    'LABEL_FE3F55': 'AssignVoiceParams_CheckDualLayer',

    # =========================================================================
    # NoteMap_InitVoiceSlots-adjacent labels
    # =========================================================================
    'LABEL_FE3D8D': 'InitVoiceSlots_CopyLoop',
    'LABEL_FE3DED': 'InitVoiceSlots_AllocAndCheck',
    'LABEL_FE3E30': 'InitVoiceSlots_SetChannel',
    'LABEL_FE3E42': 'InitVoiceSlots_CheckDualLayer',
    'LABEL_FE3E8F': 'InitVoiceSlots_EmitMidi',

    # =========================================================================
    # Voice state / play mode (FE94xx-FE96xx)
    # =========================================================================
    'LABEL_FE949E': 'PlayMode_ClearBit6',
    'LABEL_FE94A6': 'PlayMode_UpdateAndReturn',
    'LABEL_FE94C8': 'PlayMode_SetZeroResult',
    'LABEL_FE94CC': 'PlayMode_StoreResult',
    'LABEL_FE94E7': 'PlayMode_CheckModes23',
    'LABEL_FE94F9': 'PlayMode_ClearBit6_Alt',
    'LABEL_FE9501': 'PlayMode_CheckSlotAndReturn',
    'LABEL_FE9520': 'PlayMode_SetZero_Alt',
    'LABEL_FE9524': 'PlayMode_Epilogue',
    'LABEL_FE9528': 'Voice_DispatchByTimingState',
    'LABEL_FE953A': 'VoiceTiming_ResetSlot',
    'LABEL_FE953F': 'VoiceTiming_CheckBit6',
    'LABEL_FE954B': 'VoiceTiming_CheckBit7',
    'LABEL_FE9557': 'VoiceTiming_CompareThreshold',
    'LABEL_FE9562': 'VoiceTiming_EqualThreshold',
    'LABEL_FE956D': 'VoiceTiming_BelowThreshold',
    'LABEL_FE9591': 'VelocityUpdate_CheckBit4',
    'LABEL_FE959A': 'VelocityUpdate_CheckNoThreshold',
    'LABEL_FE95B3': 'VelocityUpdate_SetTimerValue',
    'LABEL_FE95C4': 'VelocityUpdate_Return',
    'LABEL_FE95C5': 'Voice_SetDecayTimer',
    'LABEL_FE95D3': 'DecayTimer_SetShort',
    'LABEL_FE95DA': 'DecayTimer_SetLong',
    'LABEL_FE95DF': 'DecayTimer_Return',
    'LABEL_FE95E0': 'Voice_MatchVoicePairs',
    'LABEL_FE95ED': 'VoicePair_OuterLoop',
    'LABEL_FE95F3': 'VoicePair_InnerScan',
    'LABEL_FE9603': 'VoicePair_AdvanceOuter',
    'LABEL_FE9608': 'VoicePair_Return',

    # =========================================================================
    # UIParam_ScanAndCollect internal
    # =========================================================================
    'LABEL_FE8C18': 'UIParam_SetDefaultCount',
    'LABEL_FE8C74': 'UIParam_CompareResult',
    'LABEL_FE8C79': 'UIParam_StoreAndReturn',

    # =========================================================================
    # NoteMap_SearchVoiceEntry internal (FE8C9E-FE8DAE)
    # =========================================================================
    'LABEL_FE8C9E': 'SearchVoice_EntryLoop',
    'LABEL_FE8CD2': 'SearchVoice_OctaveDown',
    'LABEL_FE8CD6': 'SearchVoice_CheckHighBound',
    'LABEL_FE8CE3': 'SearchVoice_OctaveUp',
    'LABEL_FE8CE7': 'SearchVoice_CheckLowBound',
    'LABEL_FE8CF7': 'SearchVoice_CheckDistance',
    'LABEL_FE8D16': 'SearchVoice_NextEntry',
    'LABEL_FE8D18': 'SearchVoice_CheckCount',
    'LABEL_FE8D1E': 'SearchVoice_StoreResult',
    'LABEL_FE8D26': 'SearchVoice_SetZero',
    'LABEL_FE8D2A': 'SearchVoice_SortCheck',
    'LABEL_FE8D38': 'SearchVoice_BubbleSortOuter',
    'LABEL_FE8D3E': 'SearchVoice_BubbleSortInner',
    'LABEL_FE8DA2': 'SearchVoice_BubbleAdvance',
    'LABEL_FE8DA8': 'SearchVoice_BubbleOuterNext',
    'LABEL_FE8DAE': 'SearchVoice_Done',

    # =========================================================================
    # Various small returns / epilogues
    # =========================================================================
    'LABEL_FE18E1': 'VoiceClaim_Extended_Return',
    'LABEL_FE8171': 'SeqPart_LookupReturn',
    'LABEL_FE8BEE': 'Voice_ResetSearchState',
    'LABEL_FE8BE9': 'Voice_ReadSearchResult',

    # =========================================================================
    # Seq playback (FECFxx-FED0xx)
    # =========================================================================
    'LABEL_FECF08': 'SeqPlay_CheckBit7Path',
    'LABEL_FECF14': 'SeqPlay_CopyRecordData',
    'LABEL_FECF3B': 'SeqPlay_CheckStatusByte',
    'LABEL_FECF4C': 'SeqPlay_TwoByteMsg',
    'LABEL_FECF53': 'SeqPlay_ThreeByteMsg',
    'LABEL_FECF58': 'SeqPlay_ReadRemainingBytes',
    'LABEL_FECF62': 'SeqPlay_ReadByte_Loop',
    'LABEL_FECF72': 'SeqPlay_StoreByte',
    'LABEL_FECFC9': 'SeqPlay_AccumulateDelta',
    'LABEL_FECFD0': 'SeqPlay_CheckSysExMarker',
    'LABEL_FED006': 'SeqPlay_CopyToMidiBuffer',
    'LABEL_FED06F': 'SeqPlay_SendEvent',
    'LABEL_FED079': 'SeqPlay_CheckMidiBuffer',
    'LABEL_FED099': 'SeqPlay_ClearMidiCount',
    'LABEL_FED09F': 'SeqPlay_SetSuccess',
    'LABEL_FED0A8': 'SeqPlay_ReadFileRecord',
    'LABEL_FED0CE': 'SeqPlay_RecordReadOK',

    # =========================================================================
    # NoteMap_VoiceAssign_Finalize area (FE6Bxx-FE6Dxx)
    # =========================================================================
    'LABEL_FE6BDB': 'VoiceAssign_CheckBothParts',
    'LABEL_FE6BFF': 'VoiceAssign_LookupAndLoop_Part1',
    'LABEL_FE6C1A': 'VoiceAssign_FindRetry_Part1',
    'LABEL_FE6C49': 'VoiceAssign_MergeAndCollect_Part1',
    'LABEL_FE6CD7': 'VoiceAssign_CheckSinglePart',
    'LABEL_FE6CF9': 'VoiceAssign_LookupAndLoop_Part2',
    'LABEL_FE6D15': 'VoiceAssign_FindRetry_Part2',
    'LABEL_FE6D47': 'VoiceAssign_CheckOtherPart',

    # =========================================================================
    # Voice realloc path (FE770A-FE780A)
    # =========================================================================
    'LABEL_FE770A': 'VoiceRealloc_CheckSingleLayer',
    'LABEL_FE772C': 'VoiceRealloc_LookupVoice',
    'LABEL_FE777D': 'VoiceRealloc_CheckAltLayer',

    # =========================================================================
    # SeqPart emit / note output (FE8177-FE83D3)
    # =========================================================================
    'LABEL_FE8177': 'SeqPart_EmitMelodicNote',
    'LABEL_FE81D3': 'SeqPart_MelodicNote_Layer1Done',
    'LABEL_FE8215': 'SeqPart_MelodicNote_SingleLayer',
    'LABEL_FE8261': 'SeqPart_MelodicNote_Layer1Done_Alt',
    'LABEL_FE82A5': 'SeqPart_EmitPercussionNote',
    'LABEL_FE8301': 'SeqPart_PercNote_Layer1Done',
    'LABEL_FE8343': 'SeqPart_PercNote_SingleLayer',
    'LABEL_FE838F': 'SeqPart_PercNote_Layer1Done_Alt',
    'LABEL_FE83D3': 'SeqPart_EmitNoteOn_Full',

    # =========================================================================
    # SndParam dispatch and lookup (FEA7EB+)
    # =========================================================================
    'LABEL_FEA7EB': 'SndParam_Init',
    'LABEL_FEA87F': 'SndParam_ProcessEntry',
    'LABEL_FE8A80': 'SndParam_DispatchReturn',

    # =========================================================================
    # Voice event handlers (FE942C area)
    # =========================================================================
    'LABEL_FE942C': 'Voice_UpdateNoteState',

    # =========================================================================
    # HdaeRom data (FEAAxx-FEB0xx dispatch tables)
    # =========================================================================
    'LABEL_FEAA18': 'HdaeRom_Entry',
    'LABEL_FEAA80': 'HdaeRom_ProcessBlock',
    'LABEL_FEAAC4': 'HdaeRom_ReadParam',
    'LABEL_FEAB09': 'HdaeRom_WriteParam',
    'LABEL_FEAB4D': 'HdaeRom_CheckResult',
    'LABEL_FEAB91': 'HdaeRom_FinishBlock',
    'LABEL_FEABD5': 'HdaeRom_TableEntry0',
    'LABEL_FEABD7': 'HdaeRom_TableEntry1',
    'LABEL_FEABD9': 'HdaeRom_TableEntry2',
    'LABEL_FEAC82': 'HdaeRom_AltEntry',
    'LABEL_FEAD01': 'HdaeRom_AltProcessBlock',
    'LABEL_FEAD62': 'HdaeRom_AltReadParam',
    'LABEL_FEADC7': 'HdaeRom_AltCheckResult',
    'LABEL_FEAE9E': 'HdaeRom_AltTableEntry0',
    'LABEL_FEAECA': 'HdaeRom_AltTableEntry1',
    'LABEL_FEAF26': 'HdaeRom_AltTableEntry2',
    'LABEL_FEAF52': 'HdaeRom_AltTableEntry3',
    'LABEL_FEAF7E': 'HdaeRom_AltTableEntry4',
    'LABEL_FEAFB6': 'HdaeRom_AltTableEntry5',
    'LABEL_FEAFE2': 'HdaeRom_AltTableEntry6',
    'LABEL_FEB00E': 'HdaeRom_AltTableEntry7',
    'LABEL_FEB00F': 'HdaeRom_AltTableEntry8',
    'LABEL_FEB010': 'HdaeRom_AltTableEntry9',

    # =========================================================================
    # NoteMap result storage helpers
    # =========================================================================
    'LABEL_FE4720': 'NoteMap_LookupReturn',

    # =========================================================================
    # Comm / MIDI utility
    # =========================================================================
    'LABEL_FEBA91': 'COMM_SendDataReturn',
    'LABEL_FEBDD2': 'COMM_WriteAndCheck',
    'LABEL_FEBF7F': 'MIDI_OutputFlush',
    'LABEL_FEC12A': 'FileIO_ReadChunk',

    # =========================================================================
    # Seq play file I/O
    # =========================================================================
    'LABEL_FECC0C': 'SeqFile_ParseHeader',
    'LABEL_FECC6B': 'SeqFile_ReadTrackData',
    'LABEL_FECCA5': 'SeqFile_ValidateAndStore',

    # =========================================================================
    # Additional internal branch targets in identifiable routines
    # =========================================================================
    'LABEL_FE4289': 'NoteMap_LookupAndMergeVoice',
    'LABEL_FE6525': 'Voice_SetTransposeAndAlloc',
    'LABEL_FEA066': 'Voice_InitPartAllocState',
    'LABEL_FE301A': 'NoteMap_CollectAndAllocVoice_NoTimerCheck',
    'LABEL_FE3A52': 'NoteMap_ProcessRhythmNoteOn',
    'LABEL_FE3BB4': 'NoteMap_ProcessRhythmRemap',
    'LABEL_FE66D7': 'Rhythm_DispatchCCCommand',
    'LABEL_FEF4CD': 'TmFlash_Return',
    'LABEL_F74A2C': 'AccWrap_SetMinVelocity',
    'LABEL_FB7BDF': 'Voice_EmitNoteWithVelocity',
    'LABEL_FDDEFF': 'Audio_InitDispatchReturn',
    'LABEL_FE09C4': 'AccNoteOn_ChannelDispatch',
    'LABEL_FE780A': 'NoteMap_ProcessDualLayerNoteOff',
    'LABEL_FE78C7': 'NoteMap_ProcessLayeredNoteOn',
    'LABEL_FE786E': 'NoteMap_DualLayerNoteOff_SinglePath',

    # External references that are defined here but called from other files
    'LABEL_F2AA12': 'Audio_ExternalCallback',
    'LABEL_F52FB1': 'SndTable_LookupA',
    'LABEL_F530B0': 'SndTable_LookupB',
    'LABEL_F530B3': 'SndTable_LookupC',
    'LABEL_F530F9': 'SndTable_LookupD',
}


def collect_all_labels(repo_dir):
    """Collect all label definitions in the repo."""
    existing = set()
    for pat in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pat), recursive=True):
            try:
                with open(fpath, 'rb') as f:
                    content = f.read().decode('latin-1')
                for m in re.finditer(r'^([A-Za-z_]\w*):', content, re.MULTILINE):
                    existing.add(m.group(1))
            except Exception:
                pass
    return existing


def find_all_files_with_label(repo_dir, label):
    """Find all .s files referencing a label."""
    files = []
    for pat in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pat), recursive=True):
            try:
                with open(fpath, 'rb') as f:
                    content = f.read().decode('latin-1')
                if re.search(r'\b' + re.escape(label) + r'\b', content):
                    files.append(fpath)
            except Exception:
                pass
    return files


def apply_rename(content_bytes, old_label, new_label):
    """Replace all occurrences of old_label with new_label in content bytes."""
    old = old_label.encode('latin-1')
    new = new_label.encode('latin-1')
    # Use word boundary matching via regex on bytes
    pattern = re.compile(rb'\b' + re.escape(old) + rb'\b')
    return pattern.sub(new, content_bytes)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ('analyze', 'apply'):
        print("Usage: python3 scripts/rename_nvm_labels.py [analyze|apply]")
        sys.exit(1)

    mode = sys.argv[1]
    existing_labels = collect_all_labels(REPO)

    # Validate renames
    errors = []
    for old, new in RENAMES.items():
        # Check new name doesn't collide
        if new in existing_labels and old in existing_labels:
            # Allow if it's the same label being renamed
            pass
        elif new in existing_labels:
            errors.append(f"COLLISION: {new} already exists (from {old})")
        # Check old label exists
        if old not in existing_labels:
            # Check if it's referenced but not defined (external ref)
            content = read_file(TARGET_FILE).decode('latin-1')
            if old not in content:
                errors.append(f"NOT FOUND: {old} not in target file")

    # Check for duplicate new names
    new_names = list(RENAMES.values())
    seen = set()
    for n in new_names:
        if n in seen:
            errors.append(f"DUPLICATE new name: {n}")
        seen.add(n)

    if errors:
        print("ERRORS found:")
        for e in errors:
            print(f"  {e}")
        if mode == 'apply':
            sys.exit(1)

    if mode == 'analyze':
        print(f"Planned renames: {len(RENAMES)}")
        for old, new in sorted(RENAMES.items()):
            refs = find_all_files_with_label(REPO, old)
            ref_files = [os.path.relpath(f, REPO) for f in refs]
            print(f"  {old} -> {new}  (in {len(ref_files)} files: {', '.join(ref_files[:5])})")
        return

    # Apply mode
    # Collect all files that need modification
    files_to_modify = {}
    for old, new in RENAMES.items():
        refs = find_all_files_with_label(REPO, old)
        for f in refs:
            if f not in files_to_modify:
                files_to_modify[f] = []
            files_to_modify[f].append((old, new))

    print(f"Applying {len(RENAMES)} renames across {len(files_to_modify)} files...")

    for fpath, rename_list in files_to_modify.items():
        content = read_file(fpath)
        for old, new in rename_list:
            content = apply_rename(content, old, new)
        write_file(fpath, content)
        rel = os.path.relpath(fpath, REPO)
        print(f"  Updated {rel} ({len(rename_list)} renames)")

    print("Done. Run 'make clean && make all && python scripts/compare_roms.py' to verify.")


if __name__ == '__main__':
    main()
