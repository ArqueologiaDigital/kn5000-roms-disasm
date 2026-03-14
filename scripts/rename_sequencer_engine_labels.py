#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in sequencer_engine.s to semantic names.

Uses binary I/O (rb/wb) to preserve Latin-1 bytes safely.
Checks for collisions and cross-file references before renaming.

Usage:
    python3 scripts/rename_sequencer_engine_labels.py analyze
    python3 scripts/rename_sequencer_engine_labels.py apply
"""

import sys
import os
import re
import glob
import subprocess

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_FILE = os.path.join(REPO_DIR, 'maincpu', 'sequencer', 'sequencer_engine.s')

# Map of LABEL_XXXXXX -> new_name
# Organized by section/function group
RENAMES = {
    # === Section: NoteEditSy / preamble ===
    'LABEL_F3888B': 'NoteEditSy_UpdateAllWidgets',
    'LABEL_F388A8': 'NoteEditSy_ScanAndSortEntries',
    'LABEL_F388BB': 'NoteEditSy_ScanLoop',
    'LABEL_F388E0': 'NoteEditSy_CopyEntryLoop',
    'LABEL_F388F4': 'NoteEditSy_DirectCopy',
    'LABEL_F388FF': 'NoteEditSy_DirectCopyLoop',
    'LABEL_F38907': 'NoteEditSy_ScanReturn',
    'LABEL_F3890C': 'SeqAcc_UpdateAndDispatch',
    'LABEL_F38912': 'SeqAcc_InitAndDispatch',

    # === Section: Sequencer Playback Control ===
    'LABEL_F38948': 'SeqAcc_HandlePlaybackTick_ClearBit1',
    'LABEL_F3894C': 'SeqAcc_HandlePlaybackTick_ClearBit2',
    'LABEL_F38951': 'SeqAcc_HandlePlaybackTick_Data',  # .byte data block
    'LABEL_F38956': 'SeqAcc_StartPlaybackFromPosition',
    'LABEL_F38985': 'SeqAcc_AdjustEndAndStart',
    'LABEL_F389AD': 'SeqAcc_StopPlayback',
    'LABEL_F389BB': 'SeqAcc_StopPlayback_HandleTick',
    'LABEL_F38A32': 'SeqPlay_CheckAndActivateParts',
    'LABEL_F38A4B': 'SeqPlay_CheckAndActivateParts_RetFFFF',
    'LABEL_F38A50': 'SeqPlay_CheckAndActivateParts_Bit6',
    'LABEL_F38A75': 'SeqPlay_CheckAndActivateParts_Deactivate',
    'LABEL_F38A85': 'SeqPlay_CheckAndActivateParts_SetHL0',
    'LABEL_F38A87': 'SeqPlay_CheckAndActivateParts_Return',
    'LABEL_F38AB3': 'SeqPlay_ActivateParts_PartLoop',
    'LABEL_F38AC1': 'SeqPlay_ActivateParts_ShiftDone',
    'LABEL_F38AD0': 'SeqPlay_ActivateParts_LoopNext',
    'LABEL_F38AE5': 'SeqPlay_DeactivateAndSendOff',
    'LABEL_F38AF3': 'SeqPlay_DeactivateParts_PartLoop',
    'LABEL_F38B01': 'SeqPlay_DeactivateParts_ShiftDone',
    'LABEL_F38B10': 'SeqPlay_DeactivateParts_LoopNext',
    'LABEL_F38B45': 'SeqPlay_ResetPlaybackState',
    'LABEL_F38BB7': 'SeqPlay_InitAccAndSetMode_StoreState',
    'LABEL_F38BBE': 'SeqPlay_DataBlock_BBE',  # .byte data block

    # === Section: Part & Voice Processing ===
    'LABEL_F38DA4': 'SeqPlay_ProcessParts_PartLoop',
    'LABEL_F38DB2': 'SeqPlay_ProcessParts_ShiftDone',
    'LABEL_F38DE4': 'SeqPlay_ProcessParts_HandleResult',
    'LABEL_F38E25': 'SeqPlay_ProcessParts_LoopNext',
    'LABEL_F38E3E': 'SeqPlay_ProcessParts_Dispatch',
    'LABEL_F38E40': 'SeqPlay_ProcessParts_Return',

    # SeqAcc_ProcessTempoEvents internals
    'LABEL_F38E5F': 'SeqAcc_ProcessTempo_DispatchLoop',
    'LABEL_F38E71': 'SeqAcc_ProcessTempo_ReadComplete',
    'LABEL_F38EA2': 'SeqAcc_ProcessTempo_CopyLoop',
    'LABEL_F38EC7': 'SeqAcc_ProcessTempo_PartScanLoop',
    'LABEL_F38EDA': 'SeqAcc_ProcessTempo_ShiftDone',
    'LABEL_F38EEF': 'SeqAcc_ProcessTempo_ClearPartBit',
    'LABEL_F38EFC': 'SeqAcc_ProcessTempo_ClearShiftDone',
    'LABEL_F38F3F': 'SeqAcc_ProcessTempo_NextPart',
    'LABEL_F38F7E': 'SeqAcc_ProcessTempo_NoActiveParts',

    # SeqPlay_FinalizeAndReturn / Stop routines
    'LABEL_F38FB1': 'SeqPlay_SelectStopCommand',
    'LABEL_F38FBC': 'SeqPlay_SelectStopCommand_Check88',
    'LABEL_F38FC8': 'SeqPlay_SelectStopCommand_Default18',
    'LABEL_F38FF2': 'SeqPlay_FinalCleanupAndReset',
    'LABEL_F3900C': 'SeqPlay_FinalCleanup_ClearFlags',
    'LABEL_F3902B': 'SeqPlay_CopyVoicePositionsToParts',
    'LABEL_F39031': 'SeqPlay_CopyVoicePos_PartLoop',
    'LABEL_F39041': 'SeqPlay_CopyVoicePos_ShiftDone',
    'LABEL_F3905A': 'SeqPlay_CopyVoicePos_LoopNext',

    # SeqData navigation
    'LABEL_F39067': 'SeqPlay_ProcessCurrentPart',
    'LABEL_F39094': 'SeqPlay_ProcessCurrentPart_Done',
    'LABEL_F39099': 'SeqPlay_ProcessCurrentPart_Return',
    'LABEL_F390D8': 'SeqPlay_ProcessCurrentPart_Loop',
    'LABEL_F390F0': 'SeqPlay_ProcessCurrentPart_NextTick',
    'LABEL_F390F5': 'SeqData_SkipCommand_CheckType',

    # SeqData bar/end mark handling
    'LABEL_F39118': 'SeqData_HandleEndMark_NotBarEnd',
    'LABEL_F39123': 'SeqData_HandleEndMark_NotEndMark',
    'LABEL_F39154': 'SeqData_HandleEndMark_SetError1',
    'LABEL_F39159': 'SeqData_HandleEndMark_Return',
    'LABEL_F3915B': 'SeqData_ScanForBarPosition',
    'LABEL_F39171': 'SeqData_ScanForBar_CheckMarkers',
    'LABEL_F391C8': 'Seq_HandleBarMark_AdvanceBlock',
    'LABEL_F391DA': 'Seq_HandleBarMark_Return',

    # SeqPlay tempo/repeat management
    'LABEL_F391DC': 'SeqPlay_CheckAndReactivate',
    'LABEL_F39205': 'SeqPlay_CheckAndReactivate_CopyPos',
    'LABEL_F39229': 'SeqPlay_CheckAndReactivate_Activate',
    'LABEL_F3923A': 'SeqPlay_CheckAndReactivate_Return',
    'LABEL_F3923E': 'SeqPlay_CheckRepeatAndReactivate',
    'LABEL_F3926C': 'SeqPlay_CheckRepeat_AltPath',
    'LABEL_F39287': 'SeqPlay_CheckRepeat_ApplyMask',

    # SeqPlay position sync
    'LABEL_F39290': 'SeqPlay_SyncPlaybackPosition',
    'LABEL_F392FA': 'SeqPlay_SyncPosition_CheckPrev',
    'LABEL_F3930C': 'SeqPlay_SyncPosition_ApplyParts',
    'LABEL_F39327': 'SeqPlay_SyncPosition_AltMode',
    'LABEL_F39342': 'SeqPlay_SyncPosition_MatchCheck',
    'LABEL_F39346': 'SeqPlay_SyncPosition_StopAndReset',

    # SeqPlay_ReactivatePartsAndResume internals
    'LABEL_F393AA': 'SeqPlay_Reactivate_PartLoop',
    'LABEL_F393B8': 'SeqPlay_Reactivate_ShiftDone',
    'LABEL_F393C7': 'SeqPlay_Reactivate_LoopNext',

    # SeqAcc_InitPlaybackState internals
    'LABEL_F39434': 'SeqAcc_InitPlayback_HasActiveVoices',
    'LABEL_F39441': 'SeqAcc_InitPlayback_FindVoices',
    'LABEL_F39499': 'SeqAcc_InitPlayback_RestartPath',
    'LABEL_F3949C': 'SeqAcc_InitPlayback_CheckDrum',
    'LABEL_F394B0': 'SeqAcc_InitPlayback_SetState0',
    'LABEL_F394BC': 'SeqAcc_InitPlayback_DrumActive',
    'LABEL_F394D5': 'SeqAcc_InitPlayback_SetState4',
    'LABEL_F394DE': 'SeqAcc_InitPlayback_ReturnZero',
    'LABEL_F394E1': 'SeqAcc_InitPlayback_FreshStart',
    'LABEL_F39552': 'SeqAcc_InitPlayback_ScanParts',
    'LABEL_F39593': 'SeqAcc_InitPlayback_DrumShiftDone',

    # SeqPlay restart voice config
    'LABEL_F395AF': 'SeqPlay_RestartWithVoiceConfig',

    # SeqPlay_ConfigureVoiceChannels internals
    'LABEL_F39651': 'SeqPlay_ConfigVoice_CheckActive',

    # SeqPlay_AssignAccompVoices and related
    'LABEL_F396A8': 'SeqPlay_ProcessChannelsAndDrum',

    # Drum Parts & Channel Dispatch
    'LABEL_F3994F': 'SeqPlay_DrumPart_ShiftDone',
    'LABEL_F3995D': 'SeqPlay_DrumPart_SetActiveFlag',

    # SeqPlay_IterateAllChannels internals
    'LABEL_F39990': 'SeqPlay_IterateCh_PartLoop',
    'LABEL_F3999E': 'SeqPlay_IterateCh_ShiftDone',
    'LABEL_F399A8': 'SeqPlay_IterateCh_ProcessChannel',
    'LABEL_F399EA': 'SeqPlay_IterateCh_CopyDataLoop',
    'LABEL_F39A36': 'SeqPlay_IterateCh_ClearPartBit',
    'LABEL_F39A43': 'SeqPlay_IterateCh_CheckEventType',
    'LABEL_F39A6A': 'SeqPlay_IterateCh_CheckEvent86',
    'LABEL_F39A7E': 'SeqPlay_IterateCh_CheckControlChange',
    'LABEL_F39AC0': 'SeqPlay_IterateCh_CtrlChange5',
    'LABEL_F39AE5': 'SeqPlay_IterateCh_CtrlChangeBit3',

    # SeqPlay_IterateAllChannels - more
    'LABEL_F39B0C': 'SeqPlay_IterateCh_NotControlChange',
    'LABEL_F39B6B': 'SeqPlay_IterateCh_TempoFlag0',
    'LABEL_F39B76': 'SeqPlay_IterateCh_TempoFlag1',

    # Playback Initialization section
    'LABEL_F39CCC': 'SeqPlay_Init_AccMode87_88',
    'LABEL_F39CD5': 'SeqPlay_Init_CheckRepeatMode',
    'LABEL_F39CE3': 'SeqPlay_Init_RepeatMode',
    'LABEL_F39CF3': 'SeqPlay_InitFreshPlayback',
    'LABEL_F39D2C': 'SeqPlay_InitFresh_PartClearLoop',
    'LABEL_F39D37': 'SeqPlay_InitFresh_PartShiftDone',
    'LABEL_F39D4C': 'SeqPlay_InitFresh_ClearBit',
    'LABEL_F39D52': 'SeqPlay_InitFresh_PartLoopNext',
    'LABEL_F39D7B': 'SeqPlay_InitFresh_SetPosition',
    'LABEL_F39DB2': 'SeqPlay_InitFresh_NoVoices',
    'LABEL_F39DCA': 'SeqPlay_InitFresh_TempoInit',
    'LABEL_F39DE8': 'SeqPlay_InitFresh_StateB',
    'LABEL_F39DEC': 'SeqPlay_InitFresh_State8orC',
    'LABEL_F39DFC': 'SeqPlay_InitFresh_Return',
    'LABEL_F39DFF': 'SeqPlay_InitResumePlayback',
    'LABEL_F39E30': 'SeqPlay_InitResume_PartLoop',
    'LABEL_F39E3E': 'SeqPlay_InitResume_ShiftDone',
    'LABEL_F39E56': 'SeqPlay_InitResume_LoopNext',
    'LABEL_F39E82': 'SeqPlay_InitResume_SetFlags',
    'LABEL_F39EDC': 'SeqPlay_InitResume_State0F',
    'LABEL_F39EE0': 'SeqPlay_InitResume_State10or14',
    'LABEL_F39EEC': 'SeqPlay_InitResume_Return',
    'LABEL_F39EF0': 'SeqPlay_FindSpecialVoices',

    # SeqPlay prepare state
    'LABEL_F39F39': 'SeqPlay_SaveAndPrepareState',
    'LABEL_F39F4D': 'SeqPlay_SaveState_CheckActive',
    'LABEL_F39F79': 'SeqPlay_SaveState_NoActiveParts',

    # Voice Processing & Cleanup section
    'LABEL_F3A20C': 'SeqPlay_ProcessVoice_AccMode',
    'LABEL_F3A213': 'SeqPlay_ProcessVoice_CheckActive',
    'LABEL_F3A289': 'SeqPlay_ProcessVoice_ReadTempo',
    'LABEL_F3A29B': 'SeqPlay_ProcessVoice_TempoLoop',
    'LABEL_F3A2AB': 'SeqPlay_ProcessVoice_ValidateData',
    'LABEL_F3A2D6': 'SeqPlay_ProcessVoice_RepeatPath',
    'LABEL_F3A2DD': 'SeqPlay_ProcessVoice_Cleanup',
    'LABEL_F3A333': 'SeqPlay_ProcessVoice_PartChange',
    'LABEL_F3A337': 'SeqPlay_ProcessVoice_ClearBit',
    'LABEL_F3A33B': 'SeqPlay_ProcessVoice_Return',

    # SeqPlay_ReadTempoEvents / Note processing
    'LABEL_F3A342': 'SeqPlay_ProcessNoteAndTempo',
    'LABEL_F3A384': 'SeqPlay_ReadTempo_HasData',
    'LABEL_F3A3AC': 'SeqPlay_ReadTempo_Reconfigure',
    'LABEL_F3A3C0': 'SeqPlay_ReadTempo_CheckLoop',
    'LABEL_F3A3CC': 'SeqPlay_ReadTempo_Return',

    # TempoRingBuf_ReadEventBytes internals
    'LABEL_F3A3DC': 'TempoRingBuf_Read_ProcessByte',
    'LABEL_F3A3FA': 'TempoRingBuf_Read_NextByte',
    'LABEL_F3A404': 'TempoRingBuf_Read_CheckCount',
    'LABEL_F3A40C': 'TempoRingBuf_Read_ExtLoop',
    'LABEL_F3A41C': 'TempoRingBuf_Read_StoreByte',
    'LABEL_F3A437': 'TempoRingBuf_Read_Return',

    # Seq_DispatchVoiceConfigEvent internals
    'LABEL_F3A45F': 'SeqVoice_Dispatch_CheckTiming',
    'LABEL_F3A48C': 'SeqVoice_Dispatch_ProcessVoice',
    'LABEL_F3A498': 'SeqVoice_Dispatch_CallBBE1',
    'LABEL_F3A4A0': 'SeqVoice_Dispatch_CheckOtherTypes',

    # SeqNote_ProcessNoteOn internals
    'LABEL_F3A87C': 'SeqNote_NoteOn_HasParts',
    'LABEL_F3A89C': 'SeqNote_NoteOn_TickDone',
    'LABEL_F3A89E': 'SeqNote_NoteOn_CheckRepeat',
    'LABEL_F3A8AE': 'SeqNote_NoteOn_ReadPosition',
    'LABEL_F3A8D8': 'SeqNote_NoteOn_Reconfigure',
    'LABEL_F3A8F7': 'SeqNote_FindExtra_CheckPosition',
    'LABEL_F3A914': 'SeqNote_FindExtra_ProcessChannel',
    'LABEL_F3AAF3': 'SeqNote_ProcessCurrent_DrumCheck',
    'LABEL_F3AABC': 'SeqNote_ProcessCurrent_ComparePos',
    'LABEL_F3AAD4': 'SeqNote_ProcessCurrent_AdjustOfs',
    'LABEL_F3AAE6': 'SeqNote_ProcessCurrent_Dispatch',
    'LABEL_F3AAA5': 'SeqNote_AllocSub_SetBitAndFlags',
    'LABEL_F3AA2F': 'SeqNote_AllocBass_SetBitAndFlags',

    # SeqNote_UpdateScoreDisplay internals
    'LABEL_F3AB17': 'SeqNote_ScoreDisplay_Compare',
    'LABEL_F3AB30': 'SeqNote_ScoreDisplay_HasTarget',
    'LABEL_F3AD25': 'SeqNote_ProcessNoteOn_Return',
    'LABEL_F3AD2A': 'SeqNote_ProcessRepeatNote',

    # Voice dispatch / MIDI events
    'LABEL_F3B202': 'SeqNote_NoteOff_CheckActive',
    'LABEL_F3B21C': 'SeqNote_NoteOff_CheckActive2',
    'LABEL_F3B225': 'SeqNote_NoteOff_WritePart',
    'LABEL_F3B233': 'SeqNote_UpdatePositionA_Entry',
    'LABEL_F3B24C': 'SeqNote_UpdatePositionB_Entry',
    'LABEL_F3B265': 'SeqNote_ScanNextEvent_Entry',
    'LABEL_F3B27E': 'SeqNote_ScanNextEvent_ClearBit',
    'LABEL_F3B28E': 'SeqNote_ScanNextEvent_ShiftDone',
    'LABEL_F3B2A6': 'SeqNote_WriteEvent_RetStatus',
    'LABEL_F3B2A9': 'SeqNote_WriteEvent_Return',

    # VoiceType validation
    'LABEL_F3B2AE': 'VoiceType_CheckDrumOrControl',
    'LABEL_F3B2D2': 'VoiceType_CheckControlB0',
    'LABEL_F3B2E6': 'VoiceType_SetMatchFlag',
    'LABEL_F3B2F3': 'VoiceType_ReturnZero',
    'LABEL_F3B2F6': 'VoiceType_CheckMatchFlag',
    'LABEL_F3B2FB': 'VoiceType_ReturnFFFF',

    # SeqNote_ProcessForChannelAlt internals
    'LABEL_F3B31C': 'SeqNote_ProcessAlt_CopyDataLoop',
    'LABEL_F3B37F': 'SeqNote_ProcessAlt_WriteBuffer5',
    'LABEL_F3B384': 'SeqNote_ProcessAlt_ControlChange',
    'LABEL_F3B39F': 'SeqNote_ProcessAlt_RetStatus',
    'LABEL_F3B3A5': 'SeqNote_ProcessAlt_ProgramChange',
    'LABEL_F3B3B1': 'SeqNote_ProcessAlt_CheckSpecial',
    'LABEL_F3B3EF': 'SeqNote_ProcessAlt_82ShiftDone',
    'LABEL_F3B40C': 'SeqNote_ProcessAlt_82AllDone',
    'LABEL_F3B41B': 'SeqNote_ProcessAlt_80Tempo',
    'LABEL_F3B428': 'SeqNote_ProcessAlt_D2Store',
    'LABEL_F3B42E': 'SeqNote_ProcessAlt_85UpdateA',
    'LABEL_F3B436': 'SeqNote_ProcessAlt_86UpdateB',
    'LABEL_F3B43E': 'SeqNote_ProcessAlt_ErrorUnknown',
    'LABEL_F3B453': 'SeqNote_ProcessAlt_Return',

    # Chan_IsActive internals
    'LABEL_F3B46C': 'Chan_IsActive_ShiftDone',

    # AccPedalConfig internals
    'LABEL_F3B4A1': 'AccPedalConfig_ValidCtrl5_6_7',
    'LABEL_F3B4B5': 'AccPedalConfig_CheckBit1',
    'LABEL_F3B4BD': 'AccPedalConfig_CheckCtrl7',
    'LABEL_F3B513': 'AccPedalConfig_NotCtrl7',
    'LABEL_F3B54D': 'AccPedalConfig_StoreCtrl6Vals',
    'LABEL_F3B561': 'AccPedalConfig_StoreCtrl6ValsAlt',
    'LABEL_F3B575': 'AccPedalConfig_Ctrl5Path',
    'LABEL_F3B590': 'AccPedalConfig_Ctrl5Store',
    'LABEL_F3B5A7': 'AccPedalConfig_Ctrl5Bit5',
    'LABEL_F3B5BE': 'AccPedalConfig_Ctrl5Bit5Store',
    'LABEL_F3B5D5': 'AccPedalConfig_Ctrl5Bit2',
    'LABEL_F3B5F2': 'AccPedalConfig_Ctrl5Bit2Store',
    'LABEL_F3B606': 'AccPedalConfig_Ctrl5Bit3',

    # ToneVoice_AssignChannel internals
    'LABEL_F3C086': 'ToneVoice_Assign_ShiftDone',
    'LABEL_F3C0B0': 'ToneVoice_Assign_FromTable',
    'LABEL_F3C0C7': 'ToneVoice_Assign_CopyToVoice',
    'LABEL_F3C101': 'ToneVoice_Assign_WriteShiftDone',
    'LABEL_F3C127': 'ToneVoice_Assign_WriteFromTable',
    'LABEL_F3C13C': 'ToneVoice_Assign_Return',

    # SeqPart_ReadEventStream internals
    'LABEL_F3C169': 'SeqPart_ReadEvent_MainLoop',
    'LABEL_F3C18C': 'SeqPart_ReadEvent_SavePos',
    'LABEL_F3C1C7': 'SeqPart_ReadEvent_NotEndMark',

    # SeqPlay_AssignChordVoices internals
    'LABEL_F3C650': 'SeqPlay_BassCheck_ShiftDone',
    'LABEL_F3C65F': 'SeqPlay_BassCheck_TestBit',
    'LABEL_F3C69D': 'SeqPlay_Chord_ShiftDone',
    'LABEL_F3C6B9': 'SeqPlay_Chord_CompareLoop',
    'LABEL_F3C6D8': 'SeqPlay_Chord_CheckMatch',
    'LABEL_F3C6E0': 'SeqPlay_Chord_CopyDataLoop',
    'LABEL_F3C744': 'SeqPlay_Chord_NextPart',
    'LABEL_F3C751': 'SeqPlay_Chord_NextShiftDone',

    # SeqCh_ClearActivePartBit internals
    'LABEL_F3C76D': 'SeqCh_ClearActive_ShiftDone',
    'LABEL_F3C795': 'SeqCh_ClearActive_DrumShiftDone',

    # NotePool / linked-list management
    'LABEL_F3C7A7': 'NotePool_InsertEntry',
    'LABEL_F3C7BA': 'NotePool_Insert_CheckMax',
    'LABEL_F3C7E4': 'NotePool_Insert_ScanLoop',
    'LABEL_F3C810': 'NotePool_Insert_UpdateHead',
    'LABEL_F3C825': 'NotePool_Insert_CompareAndLink',
    'LABEL_F3C857': 'NotePool_Insert_AdvanceScan',
    'LABEL_F3C85E': 'NotePool_Insert_LinkBefore',
    'LABEL_F3C874': 'NotePool_Insert_SetHead',
    'LABEL_F3C87E': 'NotePool_Insert_RelinkPrev',
    'LABEL_F3C88C': 'NotePool_Insert_Return',
    'LABEL_F3C890': 'NotePool_DataBlock_890',  # .byte data block
    'LABEL_F3C8BA': 'NotePool_DataBlock_8BA',  # .byte data block

    # SeqPlay_CheckStartConditions internals
    'LABEL_F3C927': 'SeqPlay_CheckStart_TestSysFlag',
    'LABEL_F3C939': 'SeqPlay_CheckStart_TestBit5',

    # SeqData_ValidateProcess internals
    'LABEL_F3D58E': 'SeqData_Validate_SlotLoop',
    'LABEL_F3D5B8': 'SeqData_Validate_MatchFound',
    'LABEL_F3D5CA': 'SeqData_Validate_ComputeOffset',
    'LABEL_F3D5F3': 'SeqData_Validate_ErrorCode9',
    'LABEL_F3D5FA': 'SeqData_Validate_NextSlot',
    'LABEL_F3D618': 'SeqData_Validate_Return',

    # Part_FindAndAssignDrumVoice related
    'LABEL_F3D61F': 'SeqPlay_PrepareDrumVoice',
    'LABEL_F3D644': 'SeqPlay_PrepareDrum_ShiftDone',

    # SeqPlay event processing
    'LABEL_F3D3ED': 'SeqPlay_ReadAndProcessEvents',
    'LABEL_F3D417': 'SeqPlay_ReadEvents_TimingMatch',
    'LABEL_F3D41E': 'SeqPlay_ReadEvents_CopyDataLoop',
    'LABEL_F3D451': 'SeqPlay_ReadEvents_NotEndMark',
    'LABEL_F3D46C': 'SeqPlay_ReadEvents_ErrorBadParam',
    'LABEL_F3D473': 'SeqPlay_ReadEvents_ReloadCfg',
    'LABEL_F3D484': 'SeqPlay_PendingCh_CopyDataLoop',
    'LABEL_F3D502': 'SeqPlay_PendingCh_SetPart1',
    'LABEL_F3D506': 'SeqPlay_PendingCh_ActivateLoop',
    'LABEL_F3D514': 'SeqPlay_PendingCh_ActivateShift',
    'LABEL_F3D525': 'SeqPlay_PendingCh_ActivateNext',
    'LABEL_F3D52E': 'SeqPlay_PendingCh_ClearAndDealloc',
    'LABEL_F3D53E': 'SeqPlay_PendingCh_Return',
    'LABEL_F3D547': 'SeqPlay_PendingCh_AssignVoice',
    'LABEL_F3D562': 'SeqPlay_PendingCh_ErrorBadParam',
    'LABEL_F3D569': 'SeqPlay_PendingCh_ReadMore',

    # SeqBuffer / NoteMap management
    'LABEL_F3E61C': 'SeqBuffer_ClearLoop',
    'LABEL_F3E63C': 'SeqBuffer_InitSlotLoop',
    'LABEL_F3E649': 'SeqBuffer_InitSlot_CopyFields',
    'LABEL_F3E69F': 'SeqBuffer_FindMinPosition',
    'LABEL_F3E6AF': 'SeqBuffer_FindMin_ScanLoop',
    'LABEL_F3E6C2': 'SeqBuffer_FindMin_NextEntry',
    'LABEL_F3E6CA': 'SeqBuffer_FindMin_Store',
    'LABEL_F3E6CF': 'NoteMap_RemoveHeadEntry',
    'LABEL_F3E6F9': 'NoteMap_RemoveHead_ClearTail',
    'LABEL_F3E6FD': 'NoteMap_RemoveAndRelink',
    'LABEL_F3E756': 'NoteMap_Relink_HasPrev',
    'LABEL_F3E773': 'NoteMap_Relink_ConnectPrevNext',
    'LABEL_F3E778': 'NoteMap_Relink_SetPrev',
    'LABEL_F3E78F': 'NoteMap_UpdateTail_HasPrev',
    'LABEL_F3E79E': 'NoteMap_UpdateTail_LinkEntry',
    'LABEL_F3E7AC': 'SeqBuffer_RemoveLastEntry',
    'LABEL_F3E7DF': 'SeqBuffer_RemoveLast_Fixup',

    # SeqPlay_AllocBuffersAndInit internals
    'LABEL_F3E7F9': 'SeqPlay_AllocBuf_Mode85_86',
    'LABEL_F3E816': 'SeqPlay_AllocBuf_HasRepeat',
    'LABEL_F3E834': 'SeqPlay_AllocBuf_SetRepeatBit',
    'LABEL_F3E838': 'SeqPlay_AllocBuf_AllocSecond',
    'LABEL_F3E845': 'SeqPlay_AllocBuf_Mode87_88',
    'LABEL_F3E853': 'SeqPlay_AllocBuf_Mode87_88_Alloc',
    'LABEL_F3E85F': 'SeqPlay_AllocBuf_InitPlayback',

    # PartCtrl internals
    'LABEL_F3FB06': 'PartCtrl_AdvancePos_AtMax',
    'LABEL_F3FB1F': 'PartCtrl_AdvancePos_SaveNew',
    'LABEL_F3FB29': 'PartCtrl_AdvancePos_Return',
    'LABEL_F3FB3C': 'PartCtrl_NavBack_AtMin',
    'LABEL_F3FB5B': 'PartCtrl_NavBack_CheckZero',
    'LABEL_F3FB65': 'PartCtrl_NavBack_ErrorEnd',
    'LABEL_F3FB6C': 'PartCtrl_NavBack_SaveNew',
    'LABEL_F3FB8B': 'PartCtrl_AdvanceEntry_AtMax',
    'LABEL_F3FBB0': 'PartCtrl_AdvanceEntry_TestBit7',
    'LABEL_F3FBDB': 'PartCtrl_NavBackAlt_AtMin',
    'LABEL_F3FBFA': 'PartCtrl_NavBackAlt_CheckZero',
    'LABEL_F3FC04': 'PartCtrl_NavBackAlt_ErrorEnd',
    'LABEL_F3FC0B': 'PartCtrl_NavBackAlt_SaveNew',

    # SeqPart read/write byte
    'LABEL_F3FC26': 'SeqPart_ReadByte_Primary',
    'LABEL_F3FC35': 'SeqPart_WriteByte_Secondary',
    'LABEL_F3FC72': 'Part_ValidateVoice_ReadWord',
    'LABEL_F3FC8B': 'Part_ValidateVoice_CheckFFFF',
    'LABEL_F3FC98': 'Part_ValidateVoice_CheckOverflow',
    'LABEL_F3FCA8': 'Part_ValidateVoice_SetPosition',

    # Part_ValidateVoiceAndSetupSeq internals
    'LABEL_F3FD04': 'Part_ValidateSetup_StorePos',
    'LABEL_F3FD19': 'Part_ValidateSetup_ErrorEnd',
    'LABEL_F3FD20': 'Part_ValidateSetup_CheckBarMark',

    # AppEvent / VoiceTable
    'LABEL_F3FF2D': 'Part_ApplyVoiceTableB',
    'LABEL_F3FF3B': 'Part_ApplyVoiceTableC',
    'LABEL_F3FF76': 'Part_ValidateSetup_ErrorReturn',
    'LABEL_F3FF78': 'Part_ValidateSetup_ClearAndProcess',
    'LABEL_F3FFBB': 'Part_ValidateSetup_NoData',
    'LABEL_F3FFB2': 'Part_ValidateSetup_TestBit7',
    'LABEL_F3FFC2': 'Part_ValidateSetup_StoreAndRead',

    # SeqData_ScanAllTracks internals
    'LABEL_F3FFF5': 'SeqData_ScanTracks_OuterLoop',
    'LABEL_F40002': 'SeqData_ScanTracks_InnerLoop',
    'LABEL_F40018': 'SeqData_ScanTracks_SetFlag',
    'LABEL_F4002B': 'SeqData_ScanTracks_Check81',
    'LABEL_F40033': 'SeqData_ScanTracks_CheckCount',
    'LABEL_F4003E': 'SeqData_ScanTracks_NextTrack',

    # SeqData_AdvancePosition internals (from line 12948+)
    # These will be around F3FA range

    # Part_WriteByte/ReadByte internals
    'LABEL_F4152C': 'Part_WriteByte_ComputeAddr',
    'LABEL_F41540': 'Part_WriteByte_DoWrite',
    'LABEL_F41551': 'Part_WriteWord_ComputeAddr',
    'LABEL_F41565': 'Part_WriteWord_DoWrite',
    'LABEL_F41576': 'Part_ReadByteDirect_ComputeAddr',
    'LABEL_F4158A': 'Part_ReadByteDirect_DoRead',
    'LABEL_F4159B': 'Part_ReadWord_ComputeAddr',
    'LABEL_F415AF': 'Part_ReadWord_DoRead',

    # Part_SetAllVoicePos / Part_IncrementVoicePos
    'LABEL_F41606': 'Part_SetAllVoicePos_Loop',
    'LABEL_F4163F': 'Part_IncrVoicePos_ValidRange',

    # PartCtrl_SetClearBit7 internals
    'LABEL_F41CAE': 'PartCtrl_SetClearBit7_ClearPath',

    # PartCtrl_WriteBytePair internals
    'LABEL_F41DAE': 'PartCtrl_WritePair_NotFF',
    'LABEL_F41D9C': 'PartCtrl_WritePair_ReadNext',
    'LABEL_F41DB0': 'PartCtrl_WritePair_WriteSecond',
    'LABEL_F41DB7': 'PartCtrl_WritePair_Return',
    'LABEL_F41DB9': 'PartCtrl_DeallocAndWriteEnd',
    'LABEL_F41DE4': 'PartCtrl_DeallocAndWrite_WriteByte',

    # Part_DeallocVoices1And2 internals
    'LABEL_F41E0A': 'Part_DeallocVoices_Voice2',
    'LABEL_F41E2C': 'Part_DeallocVoices_Voice2Write',

    # Part_UnlinkVoiceFromChain internals
    'LABEL_F41E6F': 'Part_UnlinkVoice1_HasNext',
    'LABEL_F41E80': 'Part_UnlinkVoice1_LinkPrevNext',
    'LABEL_F41E8D': 'Part_UnlinkVoice1_WriteOff1',
    'LABEL_F41E90': 'Part_UnlinkVoice1_Clear',
    'LABEL_F41E9F': 'Part_UnlinkVoice_CheckVoice2',
    'LABEL_F41ED7': 'Part_UnlinkVoice2_HasNext',

    # Misc standalone functions
    'LABEL_F437EB': 'SeqAcc_ReInitWithGuard',
    'LABEL_F437FA': 'SeqPlay_DispatchAndResetAll',
    'LABEL_F4384C': 'SeqPlay_StopAndClearSequence',

    # Seq_ComputePercentClamped99 internals
    'LABEL_F439D3': 'Seq_ComputePercent_NormalizeLoop',
    'LABEL_F439DF': 'Seq_ComputePercent_Compute',

    # SeqStatus internals
    'LABEL_F439BF': 'SeqStatus_CheckMaskedBit',
    'LABEL_F439FC': 'SeqStatus_SetOrClear_ClearPath',
    'LABEL_F43A30': 'Part_IsVoiceActive_Return',

    # AccWrap_DispatchAndWaitSync internals
    'LABEL_F4399F': 'AccWrap_WaitSync_Loop',

    'LABEL_F41CE1': 'PartCtrl_DataBlock_CE1',  # .byte data block
}


def read_file(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def collect_all_labels(repo_dir):
    """Collect all label definitions across the repo."""
    labels = set()
    for pattern in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                    'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pattern), recursive=True):
            content = read_file(fpath).decode('latin-1')
            for m in re.finditer(r'^([A-Za-z_]\w+):', content, re.MULTILINE):
                labels.add(m.group(1))
    return labels


def find_all_files_with_label(repo_dir, label):
    """Find all .s files that reference a label."""
    result = subprocess.run(
        ['grep', '-rl', '--include=*.s', label, repo_dir],
        capture_output=True, text=True
    )
    return [f.strip() for f in result.stdout.splitlines() if f.strip()]


def analyze(repo_dir, renames):
    """Analyze renames for collisions and cross-file references."""
    print("Collecting all existing labels...")
    existing = collect_all_labels(repo_dir)

    # Remove the labels we're renaming FROM
    existing -= set(renames.keys())

    print(f"\nChecking {len(renames)} renames for collisions...")
    collisions = 0
    for old, new in sorted(renames.items()):
        if new in existing:
            print(f"  COLLISION: {old} -> {new} (already exists)")
            collisions += 1

    # Check for duplicate new names
    new_names = list(renames.values())
    seen = set()
    for name in new_names:
        if name in seen:
            print(f"  DUPLICATE NEW NAME: {name}")
            collisions += 1
        seen.add(name)

    print(f"\nChecking cross-file references...")
    cross_file_count = 0
    for old in sorted(renames.keys()):
        files = find_all_files_with_label(repo_dir, old)
        other_files = [f for f in files if 'sequencer_engine.s' not in f]
        if other_files:
            cross_file_count += 1
            print(f"  {old} -> {renames[old]}")
            for f in other_files:
                print(f"    referenced in: {f}")

    # Verify all old labels exist in the target file
    content = read_file(TARGET_FILE).decode('latin-1')
    missing = 0
    for old in sorted(renames.keys()):
        if old + ':' not in content and old not in content:
            print(f"  MISSING: {old} not found in target file")
            missing += 1

    print(f"\nSummary:")
    print(f"  Total renames: {len(renames)}")
    print(f"  Collisions: {collisions}")
    print(f"  Cross-file references: {cross_file_count}")
    print(f"  Missing labels: {missing}")

    if collisions > 0:
        print("\nFIX COLLISIONS BEFORE APPLYING!")
        return False
    if missing > 0:
        print("\nFIX MISSING LABELS BEFORE APPLYING!")
        return False
    return True


def apply_renames(repo_dir, renames):
    """Apply all renames using binary-safe I/O with efficient regex."""
    # Collect all files that need updating
    files_to_update = set()
    files_to_update.add(TARGET_FILE)

    for old in renames:
        files = find_all_files_with_label(repo_dir, old)
        files_to_update.update(files)

    # Exclude note_voice_mapping.s per instructions
    files_to_update = {f for f in files_to_update if 'note_voice_mapping.s' not in f}

    # Build a single regex pattern for all old labels (efficient!)
    # Sort by length descending to avoid partial matches
    sorted_labels = sorted(renames.keys(), key=len, reverse=True)
    pattern = re.compile(r'\b(' + '|'.join(re.escape(l) for l in sorted_labels) + r')\b')

    print(f"Updating {len(files_to_update)} files...")

    for fpath in sorted(files_to_update):
        raw = read_file(fpath)
        content = raw.decode('latin-1')
        original = content

        def replacer(m):
            return renames[m.group(1)]

        new_content = pattern.sub(replacer, content)

        if new_content != original:
            count = len(pattern.findall(original))
            write_file(fpath, new_content.encode('latin-1'))
            rel = os.path.relpath(fpath, repo_dir)
            print(f"  Updated {rel}: {count} replacements")
        else:
            rel = os.path.relpath(fpath, repo_dir)
            if fpath == TARGET_FILE:
                print(f"  WARNING: No changes in {rel}!")

    print(f"\nDone! Applied {len(renames)} label renames.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 rename_sequencer_engine_labels.py [analyze|apply]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == 'analyze':
        ok = analyze(REPO_DIR, RENAMES)
        sys.exit(0 if ok else 1)
    elif cmd == 'apply':
        ok = analyze(REPO_DIR, RENAMES)
        if not ok:
            print("\nAborting due to errors.")
            sys.exit(1)
        print("\nApplying renames...")
        apply_renames(REPO_DIR, RENAMES)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == '__main__':
    main()
