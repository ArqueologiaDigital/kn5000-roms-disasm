#!/usr/bin/env python3
"""Batch 14: Rename 4-ref unnamed labels to semantic names.

Covers labels in F5xx-F7xx range (UI, audio, rhythm, accompaniment).
"""

import sys

RENAMES = {
    # R1 - LSW/AudioCtrl zero-return handlers (25 labels)
    'LABEL_F7E6D0': 'StringCopyReturn',
    'LABEL_F7E0D2': 'LanguageCheckReturn',
    'LABEL_F7E00B': 'LanguageSelectEventReturn',
    'LABEL_F7DF9C': 'LanguageStringcpyReturn',
    'LABEL_F7DE3C': 'IvMessageStrcpyReturn',
    'LABEL_F7DD1D': 'LswLocalZeroReturn',
    'LABEL_F7DBEF': 'LswLocalControlZeroReturn',
    'LABEL_F7DB37': 'LswPartExpZeroReturn',
    'LABEL_F7DA58': 'LswAfterTouchZeroReturn',
    'LABEL_F7D97B': 'LswKeyScaleZeroReturn',
    'LABEL_F7D89E': 'LswSustainZeroReturn',
    'LABEL_F7D7C1': 'LswGlideZeroReturn',
    'LABEL_F7D6E4': 'LswBendRangeZeroReturn',
    'LABEL_F7D603': 'AudioCtrlReverbZeroReturn',
    'LABEL_F7D4FF': 'AudioCtrlChorusZeroReturn',
    'LABEL_F7D406': 'LswSustainLenZeroReturn',
    'LABEL_F7D32C': 'LswSustainZeroReturn2',
    'LABEL_F7D253': 'LswDigitalEffZeroReturn',
    'LABEL_F7D17A': 'LswDSPEffZeroReturn',
    'LABEL_F7D0A4': 'AudioCtrlVibratoZeroReturn',
    'LABEL_F7CF96': 'AudioCtrlTremoloZeroReturn',
    'LABEL_F7CE8D': 'AudioCtrlMutePitchReturn',
    'LABEL_F7CD84': 'AudioCtrlMuteZeroReturn',
    'LABEL_F7A78B': 'MidiPartAutoIncReturn',
    'LABEL_F77327': 'ParaLoadOptSendEvtReturn',

    # R2 - MIDI, param, EQ, tempo, voice, display (25 labels)
    'LABEL_F76BFD': 'MidiFunc_SendEventReturn',
    'LABEL_F76A4F': 'MidiFunc_SendEvtReturnAlt',
    'LABEL_F7641E': 'MdPreset_ReturnSuccess',
    'LABEL_F7639F': 'MdPresetWith_ReturnSuccess',
    'LABEL_F74A27': 'ParamFunc_CommonExit',
    'LABEL_F74A25': 'ParamFunc_ReturnOne',
    'LABEL_F74695': 'EqFunc_ReturnZero',
    'LABEL_F7456F': 'RevEqFunc_ReturnZero',
    'LABEL_F7418E': 'DrawCenterString_Exit',
    'LABEL_F72A3B': 'TempoRingBuf_ReadLoop',
    'LABEL_F72549': 'MidiSeq_SustainHandler',
    'LABEL_F7100F': 'Voice_ParamComplete',
    'LABEL_F6D82D': 'LoopCounter_Increment',
    'LABEL_F6D1E4': 'FileIO_ErrorExit',
    'LABEL_F6CE44': 'LoopIndex_Reset',
    'LABEL_F6CDDB': 'ControlState_Type3',
    'LABEL_F6C133': 'PostEventSetup_Send',
    'LABEL_F6C0F3': 'DialUI_CalcProlog',
    'LABEL_F6BCD6': 'Display_RestoreEntry',
    'LABEL_F6A0B8': 'SndArgTtl_ReturnZero',
    'LABEL_F6A061': 'AccStyle_ExitReturn',
    'LABEL_F69F0C': 'MspRecMode_ReturnZero',
    'LABEL_F69EA6': 'MspNameTtl_ReturnZero',
    'LABEL_F69E1B': 'AccBass_EventDeliver',
    'LABEL_F69C52': 'MspBksl_EventDeliver',

    # R3 - Rhythm params, voice, tone gen, events (25 labels)
    'LABEL_F69969': 'MemCopy_SetupParams',
    'LABEL_F69783': 'EventDelivery_ReturnZero',
    'LABEL_F67DCD': 'DrumKitExit_ReturnZero',
    'LABEL_F67042': 'RhythmVoice_LoadParams',
    'LABEL_F66D5A': 'RhythmParam_CheckExit',
    'LABEL_F66B7C': 'VoiceBuffer_CopyLoop',
    'LABEL_F66B3A': 'EventCode_CheckExit',
    'LABEL_F6323F': 'DualVoice_ParamLoadDone',
    'LABEL_F62EDD': 'RhythmParam_ValidExit',
    'LABEL_F62EC4': 'RhythmParam_CheckExit2',
    'LABEL_F62E8C': 'RhythmParam_CheckExit3',
    'LABEL_F62E70': 'RhythmParam_CheckExit4',
    'LABEL_F62E56': 'RhythmParam_CheckExit5',
    'LABEL_F62E1A': 'RhythmParam_CheckExit6',
    'LABEL_F629FB': 'VoiceCompare_Done',
    'LABEL_F626A5': 'TempoCheck_Exit',
    'LABEL_F62497': 'PlaybackState_InitDone',
    'LABEL_F62416': 'VoiceState_CheckExit',
    'LABEL_F623D2': 'FlagClear_Exit',
    'LABEL_F61E7B': 'TimeoutCounter_CheckExit',
    'LABEL_F61E06': 'ToneGenSetup_Done',
    'LABEL_F61C15': 'PitchValidate_Exit',
    'LABEL_F61AAE': 'SustainLevel_SetExit',
    'LABEL_F61A06': 'VoiceVelocity_CalcDone',
    'LABEL_F6163B': 'EventBuffer_ParseLoop',

    # R4 - AccPatch, DSP, Rhythm (25 labels)
    'LABEL_F615C5': 'ToneGen_SkipToNoteEntry',
    'LABEL_F6132B': 'AccPatch_DoneBlockCopy',
    'LABEL_F611E7': 'DSP_CopyDone',
    'LABEL_F60F05': 'DSP_SetupDone',
    'LABEL_F60C59': 'AccPatch_StoreEntryPtr',
    'LABEL_F60A7A': 'AccPatch_FetchSequence',
    'LABEL_F6096B': 'AccPatch_SelectTranspose',
    'LABEL_F608D8': 'AccPatch_StoreDrumParams',
    'LABEL_F60838': 'AccPatch_CopyStepsDone',
    'LABEL_F607A9': 'AccPatch_SetStepDone',
    'LABEL_F6069B': 'AccPatch_UpdatePlayback',
    'LABEL_F60575': 'AccPatch_SkipNoteOff',
    'LABEL_F6022D': 'AccPatch_ErrorExit',
    'LABEL_F600A0': 'AccPatch_ScanDone',
    'LABEL_F5FFBF': 'AccPatch_SetFlagExit',
    'LABEL_F5ED43': 'AccPatch_CopySlotsExit',
    'LABEL_F5E931': 'AccDemo_InitDone',
    'LABEL_F5D8C2': 'AccTone_LookupDone',
    'LABEL_F5D7BF': 'AccTone_SetupExit',
    'LABEL_F56A10': 'AccBuf_AdvanceNoPage',
    'LABEL_F5671E': 'AccTuning_FetchValue',
    'LABEL_F5467E': 'AccChord_CheckFailed',
    'LABEL_F53F76': 'RhythmPart_CopyData',
    'LABEL_F53C2F': 'RhythmPart_ProcessBit1',
    'LABEL_F53C0B': 'RhythmPart_ProcessBit0',
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
