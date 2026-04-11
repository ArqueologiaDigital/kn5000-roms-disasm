#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in sequencer_ui.s (batch 2, lines 2010-5500)"""
import os

RENAMES = {
    # IvNamingExit_ScreenData byte block (line 2010)
    # LABEL_F2BBF9 already renamed in batch 1

    # VoiceConfig dispatch (lines ~3028-3113)
    "LABEL_F2C9B8": "VoiceConfig_HandleInit",
    "LABEL_F2C9D7": "VoiceConfig_ReturnZero",
    "LABEL_F2C9D9": "VoiceConfig_Epilogue",
    "LABEL_F2C9DD": "VoiceConfig_ScreenTypeDispatch",
    "LABEL_F2CA36": "VoiceConfig_SetType1",
    "LABEL_F2CA3A": "VoiceConfig_SetType2",
    "LABEL_F2CA3E": "VoiceConfig_SetType3",
    "LABEL_F2CA42": "VoiceConfig_SetType4",
    "LABEL_F2CA46": "VoiceConfig_SetType5",
    "LABEL_F2CA4A": "VoiceConfig_LoadTableA",
    "LABEL_F2CA51": "VoiceConfig_LoadTableB",
    "LABEL_F2CA58": "VoiceConfig_ReturnZeroShort",
    "LABEL_F2CA5A": "VoiceConfig_PopIzRet",
    "LABEL_F2CA5C": "VoiceConfig_End",

    # AcDemoSongBoxProc (lines 3116-3186)
    "LABEL_F2CA89": "AcDemoSong_HandleInit",
    "LABEL_F2CAA0": "AcDemoSong_HandleResize",
    "LABEL_F2CACF": "AcDemoSong_SetupDisplay",
    "LABEL_F2CAE8": "AcDemoSong_DefaultHandler",
    "LABEL_F2CAF0": "AcDemoSong_CallInherited",
    "LABEL_F2CAF6": "AcDemoSong_Epilogue",
    "LABEL_F2CAFB": "AcDemoSong_End",

    # AcCurrentSongBoxProc (lines 3189-3240)
    "LABEL_F2CB2B": "AcCurSong_HandleEvent2",
    "LABEL_F2CB2F": "AcCurSong_HandleEvent1",
    "LABEL_F2CB31": "AcCurSong_CallInherited",
    "LABEL_F2CB66": "AcCurSong_ReturnZero",
    "LABEL_F2CB68": "AcCurSong_Epilogue",
    "LABEL_F2CB6F": "AcCurSong_End",

    # AcCurSongNameBoxProc (lines 3243-3384)
    "LABEL_F2CBA7": "AcCurSongName_HandleEvent2",
    "LABEL_F2CBAB": "AcCurSongName_HandleEvent1",
    "LABEL_F2CBAD": "AcCurSongName_CallInherited",
    "LABEL_F2CBB3": "AcCurSongName_HandleFocusGained",
    "LABEL_F2CBCB": "AcCurSongName_HandleEventF",
    "LABEL_F2CCE6": "MuteChSel_Epilogue",

    # SqAftSetFunc boundary (line 3490)
    "LABEL_F2CDDA": "SqAftSetFunc_End",

    # AcMuteToggleBoxProc (lines 3492-3528)
    "LABEL_F2CDFE": "AcMuteToggle_HandleInit",
    "LABEL_F2CE32": "AcMuteToggle_Epilogue",

    # SMFMuteOnOffFunc (lines 3530-3559)
    "LABEL_F2CE46": "SMFMuteOnOff_Enable",
    "LABEL_F2CE6C": "SMFMuteOnOff_Disable",
    "LABEL_F2CE85": "SMFMuteOnOff_PostCall",

    # SMF Mute status query functions (lines 3561-3583)
    "LABEL_F2CE8C": "SMFMute_GetBit0Status",
    "LABEL_F2CE98": "SMFMute_GetBit1Status",
    "LABEL_F2CEA4": "SMFMute_GetUpperBits",
    "LABEL_F2CEB0": "SMFMute_ClearBit0",

    # Rt1MuteFunc (lines ~3585-3605)
    "LABEL_F2CEE0": "Rt1Mute_ClearAndPost",
    "LABEL_F2CEF3": "Rt1Mute_PostCall",

    # Rt2MuteFunc (lines ~3607-3627)
    "LABEL_F2CF1F": "Rt2Mute_ClearAndPost",
    "LABEL_F2CF32": "Rt2Mute_PostCall",

    # DocOrchMuteFunc (lines ~3629-3649)
    "LABEL_F2CF5F": "DocOrchMute_ClearAndPost",
    "LABEL_F2CF72": "DocOrchMute_PostCall",

    # PdOrchMuteFunc (lines ~3651-3671)
    "LABEL_F2CF9F": "PdOrchMute_ClearAndPost",
    "LABEL_F2CFB2": "PdOrchMute_PostCall",

    # SeqNameOKFunc (lines 3673-3723)
    "LABEL_F2D02F": "SeqNameOK_ReturnZero",
    "LABEL_F2D033": "SeqNameOK_Return10",
    "LABEL_F2D038": "SeqNameOK_Epilogue",
    "LABEL_F2D03C": "SeqNameOK_End",

    # AcDemoMedleyDispBoxProc (lines 3726-3915)
    "LABEL_F2D06C": "DemoMedDsp_HandleDefault",
    "LABEL_F2D21A": "DemoMedDsp_End",

    # IvExitModeTrSelProc (lines 3918-3981)
    "LABEL_F2D242": "IvExitTrSel_CopyString",
    "LABEL_F2D256": "IvExitTrSel_CheckSendEvent",
    "LABEL_F2D2B4": "IvExitTrSel_PrepareInherited",
    "LABEL_F2D2BC": "IvExitTrSel_CallInherited",
    "LABEL_F2D2C0": "IvExitTrSel_Epilogue",

    # IvRealRecExitProc (similar pattern, lines ~4136-4200)
    "LABEL_F2E48D": "IvRealRecCheck_ReturnZero",
    "LABEL_F2E4B5": "IvRealRecExit_CopyString",
    "LABEL_F2E4C9": "IvRealRecExit_CheckSendEvent",
    "LABEL_F2E522": "IvRealRecExit_PrepareInherited",
    "LABEL_F2E52A": "IvRealRecExit_CallInherited",
    "LABEL_F2E52E": "IvRealRecExit_Epilogue",

    # AcPanicEditSwProc (lines 4202-4323)
    "LABEL_F2E564": "AcPanicEditSw_HandleInit",
    "LABEL_F2E58A": "AcPanicEditSw_HandleFocus",
    "LABEL_F2E5C0": "AcPanicEditSw_SetMode1",
    "LABEL_F2E5C7": "AcPanicEditSw_SetMode2",
    "LABEL_F2E5CE": "AcPanicEditSw_SetMode3",
    "LABEL_F2E5F0": "AcPanicEditSw_ReturnZero",
    "LABEL_F2E5F4": "AcPanicEditSw_HandleFocusLost",
    "LABEL_F2E5FE": "AcPanicEditSw_HandleLostInherited",
    "LABEL_F2E62D": "AcPanicEditSw_ClearMode1",
    "LABEL_F2E634": "AcPanicEditSw_ClearMode2",
    "LABEL_F2E63B": "AcPanicEditSw_ClearMode3",
    "LABEL_F2E648": "AcPanicEditSw_CallInherited",
    "LABEL_F2E64C": "AcPanicEditSw_Epilogue",

    # PanicFunc (line 4332)
    "LABEL_F2E666": "PanicFunc_ReturnZero",

    # Help status check return-zero labels
    "LABEL_F2E68E": "HelpStsCheck_ReturnZero",
    "LABEL_F2E6BB": "HelpStsP2Check_ReturnZero",
    "LABEL_F2E6E8": "HelpStsP3Check_ReturnZero",
    "LABEL_F2E715": "HelpStsP4Check_ReturnZero",
    "LABEL_F2E726": "HelpMenuCheck_ReturnZero",

    # HelpLangChkFunc (lines 4421-4464)
    "LABEL_F2E749": "HelpLangChk_CheckIzZero",

    # EdMenuPageFunc / HelpFunc (lines 4466-4548)
    "LABEL_F2E825": "HelpFunc_CheckIzZero",
    "LABEL_F2E8A1": "HelpFunc_ReturnZero2",

    # HelpTtlProc (lines 4550-4601)
    "LABEL_F2E929": "HelpTtl_Epilogue",

    # HelpTtlFunc (lines 4603-4643)
    "LABEL_F2E945": "HelpTtlFunc_LoadPageCount",
    "LABEL_F2E94D": "HelpTtlFunc_DecrementPage",
    "LABEL_F2E95F": "HelpTtlFunc_ClampMin",
    "LABEL_F2E962": "HelpTtlFunc_LookupSlide",
    "LABEL_F2E97C": "HelpTtlFunc_Epilogue",

    # IvSdrevProc (lines 4645-4710)
    "LABEL_F2E9AF": "IvSdrev_CheckParam",
    "LABEL_F2E9EB": "IvSdrev_HandleFocus",
    "LABEL_F2EA07": "IvSdrev_CopyString",
    "LABEL_F2EA17": "IvSdrev_ReturnZero",
    "LABEL_F2EA19": "IvSdrev_Epilogue",

    # IvSddspProc (lines 4712-4787)
    "LABEL_F2EA55": "IvSddsp_CheckParam",
    "LABEL_F2EAA4": "IvSddsp_HandleFocus",
    "LABEL_F2EAC1": "IvSddsp_CopyString",
    "LABEL_F2EAD1": "IvSddsp_ReturnZero",
    "LABEL_F2EAD3": "IvSddsp_Epilogue",

    # IvSdaccProc (lines 4789-4854)
    "LABEL_F2EB09": "IvSdacc_CheckParam",
    "LABEL_F2EB44": "IvSdacc_HandleFocus",
    "LABEL_F2EB60": "IvSdacc_CopyString",
    "LABEL_F2EB70": "IvSdacc_ReturnZero",
    "LABEL_F2EB72": "IvSdacc_Epilogue",

    # IvPlayExitProc (lines 4856-4914)
    "LABEL_F2EB9F": "IvPlayExit_CopyString",
    "LABEL_F2EBB3": "IvPlayExit_CheckSendEvent",
    "LABEL_F2EBE9": "IvPlayExit_ClearFlag",
    "LABEL_F2EBEE": "IvPlayExit_PrepareInherited",
    "LABEL_F2EBF6": "IvPlayExit_CallInherited",
    "LABEL_F2EBFA": "IvPlayExit_Epilogue",

    # IvPunchExitProc (lines 4916-4966)
    "LABEL_F2EC24": "IvPunchExit_CopyString",
    "LABEL_F2EC38": "IvPunchExit_CheckSendEvent",
    "LABEL_F2EC64": "IvPunchExit_PrepareInherited",
    "LABEL_F2EC6C": "IvPunchExit_CallInherited",
    "LABEL_F2EC70": "IvPunchExit_Epilogue",

    # IvAutoPunchExitProc (lines 4968-5022)
    "LABEL_F2EC99": "IvAutoPunchExit_CopyString",
    "LABEL_F2ECAD": "IvAutoPunchExit_CheckSendEvent",
    "LABEL_F2ECCE": "IvAutoPunchExit_PostSceneEvent",
    "LABEL_F2ECE1": "IvAutoPunchExit_PrepareInherited",
    "LABEL_F2ECE9": "IvAutoPunchExit_CallInherited",
    "LABEL_F2ECED": "IvAutoPunchExit_Epilogue",

    # AcIndexWideToggleProc (lines 5024-5210)
    "LABEL_F2ED33": "AcIndexToggle_HandleInit",
    "LABEL_F2ED71": "AcIndexToggle_HandleSelectEvent",
    "LABEL_F2EDCE": "AcIndexToggle_SendVisibility",
    "LABEL_F2EDFF": "AcIndexToggle_PrepareInherited",
    "LABEL_F2EE07": "AcIndexToggle_CallInherited",
    "LABEL_F2EE0E": "AcIndexToggle_HandleFocusLost",
    "LABEL_F2EE43": "AcIndexToggle_CheckNoteRange",
    "LABEL_F2EE61": "AcIndexToggle_SetFromDE",
    "LABEL_F2EE66": "AcIndexToggle_SendNoteEvent",
    "LABEL_F2EE84": "AcIndexToggle_HandleDefault",
    "LABEL_F2EEDB": "AcIndexToggle_Epilogue",

    # AcIndexWideToggleFunc (lines 5212-5237)
    "LABEL_F2EF02": "AcIndexToggleFunc_StoreAndPost",
    "LABEL_F2EF10": "AcIndexToggleFunc_ReturnZero",
    "LABEL_F2EF13": "AcIndexToggleFunc_CheckMatch",

    # Status check functions return-zero blocks
    "LABEL_F2EF2B": "AttModePreCheck_ReturnZero",
    "LABEL_F2EF3C": "AttAttentionCheck_ReturnZero",
    "LABEL_F2EF4D": "StsSeqMenu1Check_ReturnZero",
    "LABEL_F2EF5E": "StsSeqMenu2Check_ReturnZero",
    "LABEL_F2EF6F": "StsEasyRec1Check_ReturnZero",
    "LABEL_F2EF80": "StsEasyRec2Check_ReturnZero",
    "LABEL_F2EF91": "StsPnlWrtCheck_ReturnZero",
    "LABEL_F2EFA2": "StsTrkClr1Check_ReturnZero",
    "LABEL_F2EFB3": "StsTrkClr2Check_ReturnZero",
    "LABEL_F2EFC4": "StsNtDrEditCheck_ReturnZero",
    "LABEL_F2EFD5": "AttTrkClrCheck_ReturnZero",
    "LABEL_F2EFE6": "AttSongClrCheck_ReturnZero",
    "LABEL_F2EFF7": "StsAtPunchCheck_ReturnZero",

    # MsgToTtlProc (lines 5369-5407)
    "LABEL_F2F057": "MsgToTtl_CheckTitleAndPost",
    "LABEL_F2F06D": "MsgToTtl_PostEvent",
    "LABEL_F2F071": "MsgToTtl_ReturnZero",

    # NoteEditBoxProc (lines 5409-5452)
    "LABEL_F2F0BA": "NoteEditBox_HandleFocusGained",
    "LABEL_F2F0F9": "NoteEditBox_HandleFocusLost",

    # NoteEditGrid coordinate setup (lines ~5826-5846)
    "LABEL_F2F94D": "NoteEditGrid_SetCoord3",
    "LABEL_F2F953": "NoteEditGrid_CheckTitle95",
    "LABEL_F2F965": "NoteEditGrid_SetCoord5",
    "LABEL_F2F96B": "NoteEditGrid_CheckTitle95Alt",
}

def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/sequencer/sequencer_ui.s'
    with open(filepath, 'rb') as f:
        data = f.read()

    original = data
    for old, new in RENAMES.items():
        data = data.replace(old.encode('ascii'), new.encode('ascii'))

    if data != original:
        with open(filepath, 'wb') as f:
            f.write(data)
        count = sum(1 for old in RENAMES if old.encode('ascii') in original)
        print(f"Updated sequencer_ui.s: {count} label(s) renamed")

    print(f"Total renames: {len(RENAMES)}")

if __name__ == '__main__':
    main()
