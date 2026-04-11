#!/usr/bin/env python3
"""Batch 16: Rename remaining 4-ref unnamed labels to semantic names.

Final push to cross the 50% named labels milestone.
"""

import sys

RENAMES = {
    # T1 - BmDrEdit, Seq, Audio, Effects (37 labels)
    'LABEL_F383CB': 'ReadSeqData_StoreParams',
    'LABEL_F38544': 'BmDrEdit_SyncSeekCheck',
    'LABEL_F38604': 'BmDrEdit_PopIzRet',
    'LABEL_F386DB': 'BmDrEdit_SyncStorePos',
    'LABEL_F386E0': 'BmDrEdit_StoreStreamPos',
    'LABEL_F38718': 'BmDrEdit_CalcStorePos',
    'LABEL_F387ED': 'BmDrEdit_RestoreReturn',
    'LABEL_F3815B': 'BmDrEdit_RestoreEditRet',
    'LABEL_F380E9': 'BmDrEdit_CountMeasuresInit',
    'LABEL_F37FFF': 'BmDrEdit_BuildVoiceList',
    'LABEL_F37DD1': 'BmDrEdit_TrackValidateRet',
    'LABEL_F379A5': 'BmDrEdit_NavigateReturn',
    'LABEL_F3785C': 'BmDrEdit_SetFlagReturn',
    'LABEL_F376C6': 'BmDrEdit_WalkReturn',
    'LABEL_F37678': 'BmDrEdit_AdjustViewReturn',
    'LABEL_F37670': 'BmDrEdit_AdjustViewPath',
    'LABEL_F3726B': 'BmDrEdit_CleanupReturn',
    'LABEL_F35C8A': 'SendAudioCommand',
    'LABEL_F35C7E': 'PrepareAudioParam',
    'LABEL_F35BA6': 'FormatParamString',
    'LABEL_F3599D': 'FormatEqParamValue',
    'LABEL_F357DF': 'EffectEdit_ReturnZero',
    'LABEL_F3551F': 'SqedtFunc_ReturnPath',
    'LABEL_F34FE7': 'StringCopyEpilog',
    'LABEL_F3464D': 'SqEdit_SendEventEpilog',
    'LABEL_F33EB1': 'EffectBox_SetAutoInc',
    'LABEL_F3030D': 'CallApFuncPath',
    'LABEL_F30014': 'PlaySong_ReturnZero',
    'LABEL_F2FF90': 'ReturnTitleOrZero',
    'LABEL_F2EED5': 'SendNoteDeleteEvent',
    'LABEL_F2EB36': 'OscillatorParam_Return',
    'LABEL_F2EA95': 'FilterParam_Return',
    'LABEL_F2E9DD': 'MasterParam_Return',
    'LABEL_F2E7D7': 'HelpFuncCheck_Return',
    'LABEL_F2D216': 'DPPause_DspReturn',
    'LABEL_F2D19E': 'DPPlay_DspReturn',
    'LABEL_F2D126': 'DPLoad_DspReturn',

    # T2 - SongBank, ToneGen, SMF, SeqTrack, VoiceChannel (40 labels)
    'LABEL_F2CDD6': 'MuteChSetFunc_Exit',
    'LABEL_F2CD37': 'SqAftSet_LookupExit',
    'LABEL_F2CAF4': 'AcCurrentSongBox_RetZero',
    'LABEL_F2B58E': 'DrawStringCentered_RetZero',
    'LABEL_F2B49F': 'DrawStringCenter_RetZero2',
    'LABEL_F2AE87': 'SongEdit_CheckBounds',
    'LABEL_F2AA02': 'Audio_SendEventPostCmd',
    'LABEL_F28155': 'SMF_IncrementPosition',
    'LABEL_F277FA': 'SMF_ResetEventTimers',
    'LABEL_F26F7C': 'Seq_ReturnToDispatcher',
    'LABEL_F26F78': 'Seq_AdvanceBlock',
    'LABEL_F26ECC': 'VoiceChannel_StoreVoiceIdx',
    'LABEL_F26BDF': 'ToneGen_StoreBadValue',
    'LABEL_F26AE6': 'SoundGen_ClampUpdateVoice',
    'LABEL_F25C9F': 'ToneGen_AdvanceVoiceLoop',
    'LABEL_F25C1F': 'VoiceChannel_FindNextLoop',
    'LABEL_F25BD6': 'ToneGen_ValidateVoiceCh2',
    'LABEL_F25B8D': 'VoiceChannel_UpdateParamSet',
    'LABEL_F25B5B': 'VoiceChannel_CopyParamBlock',
    'LABEL_F255E4': 'ToneGen_LoopAdvanceCheck',
    'LABEL_F253D1': 'ToneGen_SetSustain_Exit',
    'LABEL_F24EC9': 'ToneGen_LoopAdvanceChkAlt',
    'LABEL_F24CBE': 'ToneGen_SetSustainExitAlt',
    'LABEL_F2466E': 'ToneGen_LoadBlockValidate',
    'LABEL_F240E0': 'SMF_EventFailureExit',
    'LABEL_F23F12': 'SMF_VoiceSetup_Exit',
    'LABEL_F23B55': 'SeqTrack_UpdateVolumesExit',
    'LABEL_F23996': 'SeqTrack_DispatchPartEvt',
    'LABEL_F23958': 'SeqTrack_ErrorMark',
    'LABEL_F238C3': 'SeqPlay_CheckLoadStatus',
    'LABEL_F23671': 'SeqPlay_FloppyReady',
    'LABEL_F23221': 'SoundBank_StoreChParam',
    'LABEL_F23182': 'SoundBank_CopyChData',
    'LABEL_F22CD3': 'DispatchHandler_ResolveSlot',
    'LABEL_F22BFB': 'DispatchHandler_JumpSub',
    'LABEL_F2295B': 'CDlikeSwTtl_SendStartEvt',
    'LABEL_F228B4': 'SongBank_EventCompare',
    'LABEL_F227A5': 'SongBank_LookupTableEntry',
    'LABEL_F2273D': 'SongBank_StoreCurrentSong',
    'LABEL_F22628': 'SongBank_ComputeTableOfs',

    # T3 - UI, Song, Flash, Part, SubCPU (30 labels)
    'LABEL_F2225F': 'SqTrSelTtl_ReturnZero',
    'LABEL_F22214': 'SeqStepMode_ReturnZero',
    'LABEL_F210FC': 'Snd_ParamLookupSetupWerp',
    'LABEL_F20F52': 'SetWall_ReturnZero',
    'LABEL_F20E83': 'SqTrAsPs_ReturnZero',
    'LABEL_F20D06': 'SqSngName_ReturnZero',
    'LABEL_F20993': 'PlayMode_StopAbortRetZero',
    'LABEL_F208AE': 'PartFormat_PostMode6E',
    'LABEL_F208A4': 'PartFormat_PostMode6D',
    'LABEL_F20868': 'PartFormat_PartTypeDisp',
    'LABEL_F207F4': 'SongMode_VoiceStateDisp',
    'LABEL_F20711': 'SongMode_PostEvtRetZero',
    'LABEL_F1D837': 'ParamList_ReturnZero',
    'LABEL_F1CE6A': 'AudioEvt_GetFocusRetZero',
    'LABEL_F1CCEB': 'MspBnk_ReturnZero',
    'LABEL_F1CCE7': 'MspBnk_SendEventJoin',
    'LABEL_F1CC5A': 'MspBnk_MainFuncDispatch',
    'LABEL_F1CB83': 'MspBnk_JoinLoadParams',
    'LABEL_F1C4AE': 'MspNaming_CleanupExit',
    'LABEL_F1A888': 'Widget_PostEvtReturnZero',
    'LABEL_F19491': 'DualVoice_LoadDoneRetVal',
    'LABEL_F18BF5': 'Floppy_SetHLFF9A_RetZero',
    'LABEL_F171D5': 'Flash_SectorWriteExecute',
    'LABEL_F16EFC': 'PartGrid_ByteOffsetLoop',
    'LABEL_F16E57': 'PartGrid_CopyHLtoBC',
    'LABEL_F16A57': 'Flash_InitExtMemAddrs',
    'LABEL_F160B8': 'Data_Dispatch_Entry',
    'LABEL_F102FC': 'Data_UnknownBlock',
    'LABEL_EFF518': 'SNS_Init_Startup',
    'LABEL_EFDBF7': 'SubCPU_CallRoutine',

    # T4 - VoiceSlot, Display, Flash, MIDI, RingBuf, CharMap (37 labels)
    'LABEL_EFC2DA': 'VoiceSlot_DecCountLoop',
    'LABEL_EFC1E3': 'VoiceSlot_ReadParamsErrExit',
    'LABEL_EFB24C': 'SndDispatch_TableEntryBegin',
    'LABEL_EFAADA': 'SubCPU_CmdCountdownRet',
    'LABEL_EFA497': 'Display_RegionUpdateFromHW',
    'LABEL_EF9656': 'VoiceSlot_ProcessedWordRet',
    'LABEL_EF902E': 'VoiceSlot_TableSetup',
    'LABEL_EF738B': 'Display_FillMemoryLoop',
    'LABEL_EF7175': 'VoiceBank_CheckCommand',
    'LABEL_EF70E7': 'VoiceBank_StatusDoubleRCF',
    'LABEL_EF70DD': 'VoiceBank_BitsAndLoad',
    'LABEL_EF6580': 'CompareClamp_ValueReturn',
    'LABEL_EF5EE0': 'ParamUpdate_AddAndStore',
    'LABEL_EF5D92': 'GraphicsRender_EventCheck',
    'LABEL_EF5D34': 'UIRender_TwoTableEvtCheck',
    'LABEL_EF5D0A': 'GraphicsRender_TwoTable',
    'LABEL_EF5CE8': 'UIRender_SingleTable',
    'LABEL_EF4FE4': 'Flash_CheckAndValidate',
    'LABEL_EF4827': 'UpdateFile_StackCleanup',
    'LABEL_EF3853': 'Flash_WriteWordSeq',
    'LABEL_EF3803': 'Flash_BufferAddressStore',
    'LABEL_EF3681': 'E1DMA_ISR_Epilogue',
    'LABEL_EF3523': 'FlashBufferIO_Exit',
    'LABEL_EF3030': 'RingBuf_CheckFull_256',
    'LABEL_EF3012': 'RingBuf_CheckFull_512',
    'LABEL_EF2EB2': 'Seq_RingBuf_ReadSmall',
    'LABEL_EF2B81': 'Seq_TimerEventLoop',
    'LABEL_EF2AC6': 'Seq_DataHandler',
    'LABEL_EF149F': 'RhythmBuf_DispatchWrap',
    'LABEL_EF146F': 'MidiSerial_BufferWrap',
    'LABEL_EF141D': 'MidiSerial_DataReceive',
    'LABEL_EF0CA3': 'UIState_DispatchBranch',
    'LABEL_EF0BA8': 'MemCopy_SetupAndDMA',
    'LABEL_EF0B73': 'MemCopy_DataValidation',
    'LABEL_EF0981': 'SubCPU_PayloadErrorStore',
    'LABEL_EEC698': 'CharMap_Mode6Reverse',
    'LABEL_EEC398': 'CharMap_Mode1Forward',
}


def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    skip = set()
    for old, new in RENAMES.items():
        if new in text:
            print(f"WARNING: Target name '{new}' already exists in file! Skipping {old}.")
            skip.add(old)

    count = 0
    for old, new in RENAMES.items():
        if old in skip:
            continue
        if old not in text:
            print(f"WARNING: {old} not found in file!")
            continue
        occurrences = text.count(old)
        text = text.replace(old, new)
        print(f"  {old} -> {new} ({occurrences} occurrences)")
        count += 1

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))

    print(f"\nRenamed {count} labels ({sum(text.count(new) for new in RENAMES.values())} total occurrences)")


if __name__ == '__main__':
    main()
