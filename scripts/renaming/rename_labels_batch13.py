#!/usr/bin/env python3
"""Batch 13: Rename 4-ref unnamed labels to semantic names.

Covers labels 101-200 of the 4-reference-count tier (100 labels).
"""

import sys

RENAMES = {
    # Q1 - MIDI, CtrlPanel, Voice, UI, Seq (25 labels)
    'LABEL_FC9470': 'MidiLoadParams_ContinueLoop',
    'LABEL_FC817B': 'MidiChannelMsg_WriteOutput',
    'LABEL_FC7A86': 'MidiChannel_CleanupRet',
    'LABEL_FC7A0C': 'MidiChOutState_Return',
    'LABEL_FC78C2': 'CtrlPanel_BitOp_Cleanup',
    'LABEL_FC77ED': 'CtrlPanel_SetBit3',
    'LABEL_FC77BD': 'CtrlPanel_BitManip_Ret',
    'LABEL_FC74FF': 'CtrlPanel_SetResBit7_Ret',
    'LABEL_FC6B17': 'VoiceData_Setup_Ret',
    'LABEL_FC6A4C': 'MidiParseThreeByte_Done',
    'LABEL_FC6962': 'VoiceEntryLoop_Continue',
    'LABEL_FC2CE1': 'CntIniFunc_ReturnZero',
    'LABEL_FC2BB3': 'MainPmGet_PostEvent',
    'LABEL_FC27D5': 'MainVariSet_ReturnZero',
    'LABEL_FC2629': 'WallOthCheckLoop_RetZero',
    'LABEL_FC25AE': 'WallOthEditCheck_RetZero',
    'LABEL_FC226B': 'ToneGen_InitDone',
    'LABEL_FBF063': 'FileBrowser_DrawString',
    'LABEL_FBE1E2': 'VariScreen_CleanupRet',
    'LABEL_FBD2F4': 'MssNameFunc_CleanupRet',
    'LABEL_FBD22E': 'PmBankNamingCheck_Ret',
    'LABEL_FBD12A': 'PmNamingCheck_CleanupRet',
    'LABEL_FBBAFE': 'SeqLoad_PostEvent',
    'LABEL_FBB98D': 'SeqLoadFunc_ReturnZero',
    'LABEL_FBAD90': 'TchSensGrid_SendEvent',

    # Q2 - Display, Text, FileIO, UI (25 labels)
    'LABEL_FB8B04': 'EffectMode_SendEvent_Return',
    'LABEL_FB7E11': 'TableDispatch_Return',
    'LABEL_FB7DDD': 'TableDispatch_Return5',
    'LABEL_FB7DA9': 'TableDispatch_Return4',
    'LABEL_FB7D75': 'TableDispatch_Return3',
    'LABEL_FB733D': 'DramTest_Loop',
    'LABEL_FB319A': 'VGA_ScreenBlank',
    'LABEL_FB318A': 'VGA_ScreenUnblank',
    'LABEL_FB30D3': 'DisplayBuffer_Process',
    'LABEL_FB2044': 'DrawFunc_Init',
    'LABEL_FB15F6': 'GraphicsRender_Start',
    'LABEL_FB13FA': 'TextRender_BitMask6_Return',
    'LABEL_FB1349': 'TextRender_BitMask5_Return',
    'LABEL_FB1297': 'TextRender_BitMask4_Return',
    'LABEL_FAF1F0': 'FileIO_ClosePath',
    'LABEL_FAEA86': 'SplashScreen_Return',
    'LABEL_FAD8B9': 'ColorAttribute_SetupReturn',
    'LABEL_FAA48B': 'DrawFunc_Return',
    'LABEL_FA9D3A': 'ObjectSearch_ContinueLoop',
    'LABEL_FA9927': 'ObjectSearch_ContinueLoop2',
    'LABEL_FA964C': 'EventHandler_ContinueProc',
    'LABEL_FA82F6': 'ViewIDProc_Return',
    'LABEL_FA810F': 'MainFuncIDProc_Return',
    'LABEL_FA7F28': 'ApFuncIDProc_Return',
    'LABEL_FA7E08': 'BitmapIDProc_Return',

    # Q3 - UI procs, events, timer, view (25 labels)
    'LABEL_FA7CE8': 'CommonIDProc_Return',
    'LABEL_FA75A6': 'ViewFlagProc_Return',
    'LABEL_FA73E2': 'IDCursorProc_Return',
    'LABEL_FA71E4': 'POINTWProc_Return',
    'LABEL_FA3B57': 'PsTextBox_ZeroReturn',
    'LABEL_FA35F0': 'PsMenuBox_ZeroReturn',
    'LABEL_FA2D10': 'UIList_VwBoxCall',
    'LABEL_FA2CFF': 'UIList_SendEvent',
    'LABEL_FA2788': 'PsParaBox_EventReturn',
    'LABEL_FA266D': 'PsParaBox_ZeroReturn',
    'LABEL_FA220A': 'ReminderProc_Return',
    'LABEL_FA148C': 'UIVwBox_ZeroReturn',
    'LABEL_FA0F73': 'UIViewFrame_ZeroReturn',
    'LABEL_F9D324': 'PsRadioBox_EventReturn',
    'LABEL_F9D244': 'AcRamBox_EventReturn',
    'LABEL_F9CDB1': 'ViewableProc_Return',
    'LABEL_F9C869': 'FrameLoop_Cleanup',
    'LABEL_F9B3DE': 'AcNaming_Return',
    'LABEL_F9ADF0': 'PostTitle_Function',
    'LABEL_F9AD8E': 'TaskWake_ZeroReturn',
    'LABEL_F9AC05': 'StringDraw_JoinPoint',
    'LABEL_F9ABCD': 'StringCenter_Entry',
    'LABEL_F9A69A': 'ApTimer_SetupReturn',
    'LABEL_F9A5EF': 'EventParam_FetchPoint',
    'LABEL_F99C47': 'GroupBox_TitleCheck',

    # Q4 - Lsw drawbar/perc, FileIO, Audio, Demo (25 labels)
    'LABEL_F996F9': 'CtrlFrame_SubRightMargin',
    'LABEL_F996DA': 'CtrlFrame_AddLeftMargin',
    'LABEL_F992EF': 'MainTitle_SendEventDone',
    'LABEL_F95F4B': 'AcFileSfxBox_InheritedCall',
    'LABEL_F95DCD': 'AcFileSfxChild_InheritedCall',
    'LABEL_F8AD73': 'ControlState_ProcessNext',
    'LABEL_F8ABB3': 'FileIO_ScanDone',
    'LABEL_F8A8BF': 'FileIO_DirScanDone',
    'LABEL_F87107': 'Demo_RecordChainLoopExit',
    'LABEL_F87052': 'Demo_VoiceTypeDispatch',
    'LABEL_F8408A': 'AudioView_SendEventCall',
    'LABEL_F8334B': 'LswDrawRelease_Return',
    'LABEL_F83303': 'LswDrawRelease_ReturnOne',
    'LABEL_F8326A': 'LswDrawAttack_Return',
    'LABEL_F83222': 'LswDrawAttack_ReturnOne',
    'LABEL_F83189': 'LswPercLevel_Return',
    'LABEL_F83141': 'LswPercLevel_ReturnOne',
    'LABEL_F8307A': 'LswPercDecay_Return',
    'LABEL_F83032': 'LswPercDecay_ReturnOne',
    'LABEL_F82EE6': 'AcDrawComboBox_Return',
    'LABEL_F82B01': 'AcDrawComboBox_CheckDone',
    'LABEL_F803E8': 'AudioCtrl_MixerLoopNext',
    'LABEL_F7FB96': 'AudioCtrl_MainFuncCallPt',
    'LABEL_F7EE5C': 'StringOp_ReturnPoint',
    'LABEL_F7EE56': 'StringOp_ReturnOne',
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
