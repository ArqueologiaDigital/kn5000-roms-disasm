#!/usr/bin/env python3
"""Batch 10: Rename high-reference-count unnamed labels to semantic names.

Labels analyzed by exploring code context, call patterns, and string references.
Covers labels with 5-6 references each (56 labels).
"""

import sys

RENAMES = {
    # Batch H - FileIO, NoteMap, Voice, ToneGen, CtrlPanel (5 refs each)
    'LABEL_FECB72': 'FileIO_SeekRecord_SendMidi',
    'LABEL_FECA81': 'FileIO_SeekRecord_LoopDone',
    'LABEL_FE7C10': 'NoteMap_LoopAdvance_Next',
    'LABEL_FE7DF3': 'NoteMap_LoopAdvance_Next2',
    'LABEL_FE7FA4': 'NoteMap_SetParam_Return',
    'LABEL_FE5F92': 'SndParam_StoreChannelResult',
    'LABEL_FE580C': 'Voice_LoopAdvance_Next',
    'LABEL_FE3BAE': 'Voice_SetParam_Return',
    'LABEL_FD8E7F': 'ArpQueue_Flush_Return',
    'LABEL_FCA7A6': 'Tempo_Expression_Bypass',
    'LABEL_FC99EC': 'ToneGen_Dispatch_Return',
    'LABEL_FC9718': 'Voice_Update_Return',
    'LABEL_FC7982': 'CtrlPanel_IndicatorDispatch',
    'LABEL_FC6B87': 'Voice_SetupFromData',
    'LABEL_FC55A9': 'CtrlPanel_IndicatorJumpTable',

    # Batch I - ToneGen, UI, Seq, TextRender (5 refs each)
    'LABEL_FC4CEB': 'ToneGen_InitAllChannelEntries_Skip',
    'LABEL_FC4CDE': 'ToneGen_DSPCfg_Initialize',
    'LABEL_FC4C4B': 'ToneGen_Config_InitAllEntries',
    'LABEL_FC2FAC': 'UI_EventHandler_InitReturnZero',
    'LABEL_FC2EB4': 'UI_AccChordBoxProc_Return',
    'LABEL_FBD5BA': 'UI_AcBkNoBoxProc_Return',
    'LABEL_FBD4E2': 'UI_AcPmBkNoBoxProc_Return',
    'LABEL_FBCF9B': 'UI_MainFuncCall_Execute',
    'LABEL_FBA3A7': 'Seq_ApplyFunctionAndReturn',
    'LABEL_FB77CD': 'EffectMode_UIPostModeChangeEvent',
    'LABEL_FB1403': 'TextRender_AdvancePointerAndUpdateLine',
    'LABEL_FB1352': 'TextRender_BitMask5_AdvancePointer',
    'LABEL_FB12A0': 'TextRender_BitMask5_ProcessCharacter',
    'LABEL_FADB3A': 'DrawPartGroup_TableJump_DefaultCase',
    'LABEL_FAA2E9': 'ApTimer_KillApTimer_CheckNextEntry',

    # Batch J - FileIO, UI, CtrlPanel, Accompaniment (5 refs each)
    'LABEL_F87841': 'FileIO_CloseHandle_Return',
    'LABEL_F87A95': 'FileIO_RecordLoop_Continue',
    'LABEL_F8ABB7': 'FileIO_ScanComplete_Return',
    'LABEL_F8B421': 'UI_PostEventCommon',
    'LABEL_F95BF9': 'AcParaStrBox_InheritedProcCall',
    'LABEL_F99768': 'CtrlPanel_Frame_AddLeftMargin',
    'LABEL_F99787': 'CtrlPanel_Frame_SubtractTopMargin',
    'LABEL_F9AA5D': 'UI_ChangeWallPalette_Jump',
    'LABEL_F9D057': 'Ac_SendUIEvent_Common',
    'LABEL_F9D240': 'AcRamBox_SendUIEvent_Common',
    'LABEL_FA149A': 'UI_VwBox_Return',
    'LABEL_FA256B': 'AcRhythm_SendPartEvent',
    'LABEL_FA317B': 'UI_NameCapture_ReturnSuccess',
    'LABEL_FA35EC': 'PsMenuBox_SendEvent',
    'LABEL_FAA12A': 'ApTimer_IncrementCounter',

    # Batch K - Drawbar, Percussion, Audio, Banner (5 refs each)
    'LABEL_F82F49': 'AcEditBox_DialApplyEvent',
    'LABEL_F83048': 'Lsw_PercDecay_DialScroll',
    'LABEL_F83157': 'Lsw_PercLevel_DialScroll',
    'LABEL_F83238': 'Lsw_DrawAttack_DialScroll',
    'LABEL_F83319': 'Lsw_DrawRelease_DialScroll',
    'LABEL_F83961': 'IvDrawbar_ForwardUnhandled',
    'LABEL_F83B27': 'IvDrawbarNorm_SendEvent',
    'LABEL_F844BB': 'AcAudio_SendEvent_Continue',
    'LABEL_F805AB': 'PsMixer_VolumeSelect_Continue',
    'LABEL_F7ED38': 'PsLabelBox_SendEvent_Continue',
    'LABEL_F86819': 'Banner_ReturnZero',
    'LABEL_F86E17': 'Banner_Loop_Check',
    'LABEL_F86E60': 'Banner_Loop_Exit',
}


def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

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
