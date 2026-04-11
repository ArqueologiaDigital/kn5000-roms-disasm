#!/usr/bin/env python3
"""Batch 15: Rename 4-ref unnamed labels to semantic names.

Covers labels in F3xx-F5xx range (sequencer, part control, voice, rhythm, FileIO).
"""

import sys

RENAMES = {
    # S1 - Seq, Voice, FileIO, AccPitch (30 labels)
    'LABEL_F53AE1': 'AccPitch_FinalReturn',
    'LABEL_F53AC4': 'AccPitch_UpdateCheck',
    'LABEL_F5346D': 'TableLoad_Return',
    'LABEL_F52C89': 'FileIO_Epilogue',
    'LABEL_F52BAC': 'FindNext_Epilogue',
    'LABEL_F52B90': 'FindNext_ReadFile',
    'LABEL_F52905': 'PathInfo_RetVal',
    'LABEL_F52878': 'GetDiskSpace_ReadLoop',
    'LABEL_F52716': 'GetMediaType_F9Check',
    'LABEL_F526CF': 'GetMediaType_Invalid',
    'LABEL_F526B0': 'GetMediaType_Type3Check',
    'LABEL_F49A66': 'SeqVoice_InitEntry',
    'LABEL_F49A5C': 'SeqScan_PartSearchEnd',
    'LABEL_F49A0A': 'SeqScan_PartLoopEnd',
    'LABEL_F498A4': 'SeqVoice_ReadByteLoop',
    'LABEL_F4951F': 'SeqEvent_Dispatch',
    'LABEL_F493EB': 'Portamento_CheckPos',
    'LABEL_F48F26': 'SeqStep_OverflowCheck',
    'LABEL_F48C91': 'Seq_TickReturn',
    'LABEL_F48A8B': 'SeqScan_StoreAndReturn',
    'LABEL_F4859F': 'SeqScan_CallCompare',
    'LABEL_F4834F': 'VoiceData_LoopEnd',
    'LABEL_F4833D': 'VoiceData_NextWord',
    'LABEL_F48264': 'VoiceData_ProcessLoop',
    'LABEL_F4820F': 'SeqLoad_SkipBitCheck',
    'LABEL_F46F37': 'SqDrmSel_HandleReturn',
    'LABEL_F46EFE': 'SqNoteSel_HandleReturn',
    'LABEL_F46EDF': 'SqPunchm_HandleReturn',
    'LABEL_F46EBA': 'SqPunch_HandleReturn',
    'LABEL_F46E76': 'SqRepeat_HandleReturn',

    # S2 - Seq events, part ctrl, DSP, sound (30 labels)
    'LABEL_F46E47': 'SqSngcp_ReturnZero',
    'LABEL_F46DAD': 'SqMcpy_ReturnZero',
    'LABEL_F46BEF': 'SqRealRec_ReturnZero',
    'LABEL_F46A90': 'SeqErecMode_ReturnZero',
    'LABEL_F46696': 'SoundCtrl_SendCmd_EE',
    'LABEL_F454E7': 'DSPCfg_WriteParam_Exit',
    'LABEL_F4546D': 'AppEvent_DeliveryNoRet',
    'LABEL_F453F3': 'AppEvent_DeliveryLoop',
    'LABEL_F45059': 'SeqVoice_PostStatus_Loop',
    'LABEL_F43D49': 'SeqData_ReturnZero',
    'LABEL_F43A2E': 'SeqStatus_Exit',
    'LABEL_F439B7': 'SeqStatus_CheckBit2',
    'LABEL_F43788': 'SeqPlay_InitBuffers',
    'LABEL_F436ED': 'SeqAcc_SetIndicator_PB',
    'LABEL_F4357B': 'Part_WriteSubBlock_Exit',
    'LABEL_F43410': 'Part_DeactivateChannel',
    'LABEL_F432C4': 'SeqPlay_ClearFlags_Exit',
    'LABEL_F42BD2': 'SeqEvent_ProcessRhythm3Ch',
    'LABEL_F42B61': 'SeqEvent_ProcessRhythm4Ch',
    'LABEL_F426BE': 'PartCtrl_ReadWordRoutine',
    'LABEL_F423FD': 'SeqData_ContinuePos',
    'LABEL_F4233F': 'SeqScan_CheckPartActive',
    'LABEL_F4225F': 'SeqScan_PartEntry',
    'LABEL_F420B3': 'MIDI_Status_3',
    'LABEL_F420AB': 'MIDI_Status_6',
    'LABEL_F41355': 'PartCtrl_ApplyChanges',
    'LABEL_F4109C': 'SeqPart_StoredExit',
    'LABEL_F40C86': 'SeqData_EOL_Cleanup',
    'LABEL_F40BA2': 'SeqTrack_ProcessLoop',
    'LABEL_F408EB': 'SeqVoice_AdvanceReadLoop',

    # S3 - SeqPart, PartCtrl, Voice, Bitmap, SeqCh (30 labels)
    'LABEL_F40852': 'SeqPart_PopReturn',
    'LABEL_F4084A': 'SeqData_ClearError',
    'LABEL_F405F6': 'SeqPart_SaveIndexReturn',
    'LABEL_F40376': 'SeqPart_RestoreReturn',
    'LABEL_F40365': 'SeqData_ClearAndLoop',
    'LABEL_F4022B': 'SeqData_SaveIndexReturn',
    'LABEL_F3FD25': 'SeqPart_DecisionReturn',
    'LABEL_F3FC15': 'SeqPart_RestoreReturn2',
    'LABEL_F3FBC8': 'PartCtrl_RestoreReturn',
    'LABEL_F3FB76': 'SeqPart_RestoreReturn3',
    'LABEL_F3FAEC': 'SeqPart_ErrorReturn',
    'LABEL_F3F738': 'SeqPart_SuccessReturn',
    'LABEL_F3F734': 'SeqPart_ErrorReturnFFFF',
    'LABEL_F3F2E9': 'PartCtrl_IncrAndLoop',
    'LABEL_F3F2D8': 'PartCtrl_ReadWordCheck',
    'LABEL_F3EEC4': 'Voice_WriteIndexedData',
    'LABEL_F3ED1B': 'Voice_LoadPresetReturn',
    'LABEL_F3E8D9': 'Display_ClearHWState',
    'LABEL_F3E5C4': 'Bitmap_RestoreReturn',
    'LABEL_F3E3C5': 'SeqEvent_ReturnError6',
    'LABEL_F3DF20': 'BitMapOut_WriteMultiIdx',
    'LABEL_F3DED5': 'BitMapOut_WriteAltIdx',
    'LABEL_F3D571': 'SeqData_ValidateProcess',
    'LABEL_F3D0C6': 'SeqCh_LoadProcessEvent',
    'LABEL_F3D071': 'SeqPlay_RestoreReturn',
    'LABEL_F3CA14': 'SeqAcc_InitPlayback',
    'LABEL_F3C73D': 'SeqPlay_LoadChannelRet',
    'LABEL_F3C648': 'SeqPlay_DispatchRhythm',
    'LABEL_F3C560': 'SeqPlay_RestoreReturn2',
    'LABEL_F3C4F2': 'SeqPlay_WriteVoiceData',

    # S4 - SeqNote, VoiceConfig, ToneVoice, SeqPlay (23 labels)
    'LABEL_F3BED6': 'SeqNote_VoiceConfigExit',
    'LABEL_F3BC95': 'ToneVoice_ChannelAssignRet',
    'LABEL_F3BC1F': 'ToneVoice_VoiceTypeCheck',
    'LABEL_F3BACF': 'VoiceConfig_CounterIncr',
    'LABEL_F3B88D': 'SeqNote_StackCleanupRet',
    'LABEL_F3B50E': 'Chan_IsActive_RetFalse',
    'LABEL_F3B477': 'Chan_IsActive_RetTrue',
    'LABEL_F3B413': 'SeqNote_WriteChannelEvt',
    'LABEL_F3B1CA': 'SeqNote_ConditionalWrite',
    'LABEL_F3AB95': 'VoiceConfig_EventTypeChk',
    'LABEL_F3AB3B': 'VoiceConfig_SlotCheck',
    'LABEL_F3A5FF': 'SeqVoice_ReadPartEvent',
    'LABEL_F3A3AF': 'SeqPlay_DispatchVoiceEvt',
    'LABEL_F3A1F7': 'SeqPlay_ClearFlagsRet',
    'LABEL_F39FA8': 'SeqPlay_ReassignVoicesAlt',
    'LABEL_F39EE8': 'SeqPlay_StoreCheckValue',
    'LABEL_F39DF8': 'SeqPlay_StoreChannelVal',
    'LABEL_F39933': 'SeqData_EventParseExit',
    'LABEL_F397A4': 'SeqData_BarMarkerWrite',
    'LABEL_F396A0': 'SeqPlay_MidiTimingSync',
    'LABEL_F39601': 'SeqPlay_VoiceChannelCfg',
    'LABEL_F395AB': 'SeqPlay_MidiTimingJP',
    'LABEL_F394DA': 'SeqPlay_StateSetExit',
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
