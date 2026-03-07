#!/usr/bin/env python3
"""Batch 12: Rename 4-ref unnamed labels to semantic names.

Labels analyzed by exploring code context. Covers first 100 of 563 labels
with 4 references each.
"""

import sys

RENAMES = {
    # P1 - Sound/Synth/Seq area (FExx range, selected with context prefixes)
    'LABEL_FF0E25': 'NumFormat_DivideAndConvert',
    'LABEL_FEEBA9': 'SndParam_LookupTableConverge',
    'LABEL_FEEB52': 'SndParam_LoadReturnByte',
    'LABEL_FEEB2C': 'SndParam_LoadTableConverge',
    'LABEL_FEEA84': 'SndParam_DispatchProcessParam',
    'LABEL_FEE8C9': 'SndParam_InitBufferConverge',
    'LABEL_FEE1A5': 'SndParam_PopStackReturn',
    'LABEL_FEE032': 'SndParam_StoreAndReturn',
    'LABEL_FEE007': 'SndParam_DirectReturn',
    'LABEL_FEDFB8': 'ToneGen_RestoreStackReturn',
    'LABEL_FEDC79': 'ToneGen_ValidateRange_Loop',
    'LABEL_FEDB5D': 'ToneGen_ProcessMidiConverge',
    'LABEL_FED9E4': 'ToneGen_PopIzReturn',
    'LABEL_FED98B': 'ToneGen_PopIzStackReturn',
    'LABEL_FED000': 'SeqVoice_InitZeroPath',
    'LABEL_FECB88': 'FileIO_SeekRecord_PopReturn',
    'LABEL_FEC494': 'SeqPlay_BusyWaitLoop',
    'LABEL_FEC0C3': 'SeqVoice_PopIzReturn',
    'LABEL_FEBC0D': 'SeqVoice_CheckAndRetry',
    'LABEL_FE9EF2': 'Voice_ZeroInitConverge',
    'LABEL_FE9BE1': 'Voice_ProcessSlotEntry',
    'LABEL_FE992E': 'Voice_PitchCalcStep',
    'LABEL_FE990F': 'Voice_DecrementCounter',

    # P2 - Voice, NoteMap, Synth, MIDI (25 labels)
    'LABEL_FE9571': 'Voice_UpdateVelocity_Entry',
    'LABEL_FE946A': 'Voice_ProcessControllers_Return',
    'LABEL_FE9453': 'Voice_CheckAndUpdateMode',
    'LABEL_FE8C8F': 'NoteMap_SearchVoiceEntry',
    'LABEL_FE8B6F': 'NoteMap_GetVoiceData_Entry',
    'LABEL_FE8B6E': 'NoteMap_GetVoiceData_Return',
    'LABEL_FE8B30': 'NoteMap_CheckVoiceReuse',
    'LABEL_FE8AFB': 'NoteMap_FindBestMatch_Return',
    'LABEL_FE78C1': 'NoteMap_ProcessNote_SetResult',
    'LABEL_FE672C': 'UI_CheckControlCode_TestResult',
    'LABEL_FE668A': 'Synth_SelectTone_Continue',
    'LABEL_FE6474': 'Synth_SetChannelTone_Continue',
    'LABEL_FE6383': 'Synth_InitChannelState_Loop',
    'LABEL_FE62CA': 'Synth_WriteChannelParam',
    'LABEL_FE61D9': 'Synth_WriteChannelGain_Loop',
    'LABEL_FE603B': 'Synth_WriteChannelDelay_Loop',
    'LABEL_FE5E16': 'Synth_WriteChannelMod_Loop',
    'LABEL_FE5BEE': 'Synth_WriteVoiceData_CheckSize',
    'LABEL_FE51CA': 'MIDI_SysExParse_CheckLength',
    'LABEL_FE50B4': 'MIDI_SendVoiceData_Increment',
    'LABEL_FE49E7': 'NoteMap_EmitNoteData_Process',
    'LABEL_FE3C75': 'NoteMap_ProcessNoteOff_Done',
    'LABEL_FE38C3': 'NoteMap_UpdateVoiceSlots_Return',
    'LABEL_FE383B': 'NoteMap_AllocVoiceEntry_Continue',
    'LABEL_FE37CB': 'NoteMap_AllocVoice_Done',

    # P3 - NoteMap allocation, MIDI, AudioInit (25 labels, shortened)
    'LABEL_FE35DC': 'NoteMap_FindAllocEmit',
    'LABEL_FE355C': 'NoteMap_CollectBestEmit',
    'LABEL_FE34A4': 'NoteMap_DirectLookupEmit',
    'LABEL_FE3416': 'NoteMap_FallbackAllocEmit',
    'LABEL_FE3233': 'NoteMap_IndirectCollectEmit',
    'LABEL_FE31B3': 'NoteMap_AllocVoiceEmit',
    'LABEL_FE30FB': 'NoteMap_LookupAllocEmit',
    'LABEL_FE306D': 'NoteMap_FallbackVoiceCheck',
    'LABEL_FE2E04': 'NoteMap_AltAllocEmit',
    'LABEL_FE2BA7': 'NoteMap_AllocCheckNoteOn',
    'LABEL_FE2A90': 'NoteMap_AllocCheckChannel',
    'LABEL_FE29F3': 'NoteMap_AltCheckEmit',
    'LABEL_FE2619': 'NoteMap_ProcessMergeAlloc',
    'LABEL_FE2470': 'Voice_BuildProgramNotify',
    'LABEL_FE1F26': 'MidiEvent_NoteSeqCount',
    'LABEL_FE1E79': 'MidiEvent_NoteLoopAdvance',
    'LABEL_FE1BA9': 'MidiEvent_ConfigChannel',
    'LABEL_FE1186': 'NoteMap_AddEntry_Return',
    'LABEL_FDEEC3': 'AudioInit_VoiceStereoCheck',
    'LABEL_FDED97': 'AudioInit_DrumRoutingCheck',
    'LABEL_FDED11': 'AudioInit_VoiceParamCtrl',
    'LABEL_FDECF4': 'AudioInit_DrumSaveReturn',
    'LABEL_FDECB6': 'AudioInit_LoadAndConfigure',
    'LABEL_FDEB33': 'AudioInit_StereoVoiceCfg',
    'LABEL_FDEAD7': 'AudioInit_VoiceRouteJump',

    # P4 - Tone, Voice, Sound, MIDI, FileData, Acc (25 labels)
    'LABEL_FDE1D7': 'Tone_WriteEndMarker',
    'LABEL_FD9A09': 'VoiceParam_LoopExit',
    'LABEL_FD992D': 'VoiceParam_ApplyCleanupRet',
    'LABEL_FD8A22': 'SoundParam_SyncAndReturn',
    'LABEL_FD8643': 'SoundMode_NotifyActiveVoices',
    'LABEL_FD832E': 'SeqAlt_CheckInitBuffer',
    'LABEL_FD69EA': 'MidiChan_DequeueExit',
    'LABEL_FD5CAC': 'AccWrap_ReturnZero',
    'LABEL_FD5C97': 'AccWrap_ReplaySavedExpr',
    'LABEL_FD5677': 'SoundData_FreeSoundPtr',
    'LABEL_FD5535': 'SoundParam_UpdateCleanupRet',
    'LABEL_FD0DED': 'FileData_DispatchExit',
    'LABEL_FD0D53': 'MidiChannel_ConfigureExit',
    'LABEL_FD0BF0': 'BitMask_Ctrl0_ConfigExit',
    'LABEL_FD0B70': 'BitMask_Ctrl3_ConfigExit',
    'LABEL_FD0B40': 'BitMask_Ctrl1_ConfigExit',
    'LABEL_FD0A73': 'BitMask_Ctrl40_ConfigExit',
    'LABEL_FD058A': 'MidiCC_DispatchCleanupRet',
    'LABEL_FCB6BA': 'MIDI_VoiceNote_CtrlExit',
    'LABEL_FCB229': 'MIDI_PartCC_DispatchExit',
    'LABEL_FCAB5F': 'TempoRingBuf_ProcessEntry',
    'LABEL_FCA450': 'MIDI_ParamValidate_CheckBit2',
    'LABEL_FCA2BA': 'MIDI_SetupChannelParams',
    'LABEL_FC9E82': 'ToneGen_IncrementAndExit',
    'LABEL_FC997E': 'ToneGen_DispatchStartVoice',
}


def main():
    filepath = '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # Pre-check for duplicate target names
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
