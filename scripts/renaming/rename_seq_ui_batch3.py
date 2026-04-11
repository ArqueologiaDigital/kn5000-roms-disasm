#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in sequencer_ui.s (batch 3, lines 5850-14419)"""
import os

RENAMES = {
    # SngSel2Proc (lines ~6238-6276)
    "LABEL_F2FD71": "SngSel2_HandleTimerResetEvent",
    "LABEL_F2FDA7": "SngSel2_Epilogue",

    # SngSelProc (lines ~6278-6405)
    "LABEL_F2FDE8": "SngSel_HandleEventB",
    "LABEL_F2FE05": "SngSel_HandleEventF",
    "LABEL_F2FED2": "SngSel_HandleScrollEvent",
    "LABEL_F2FF04": "SngSel_Epilogue",

    # SngSelFunc (lines ~6407-6466)
    "LABEL_F2FF2B": "SngSelFunc_HandleEvent47",
    "LABEL_F2FF7F": "SngSelFunc_LoadTitleCount",
    "LABEL_F2FF88": "SngSelFunc_GetTitleIndex",

    # PlySngSelFunc (lines ~6468-6517)
    "LABEL_F2FFCE": "PlySngSel_HandleTimerEvent",
    "LABEL_F2FFEA": "PlySngSel_ClearFlagAndReturn",
    "LABEL_F2FFF1": "PlySngSel_HandleSelectEvent",
    "LABEL_F30000": "PlySngSel_ResetTimerCommon",

    # AcEntertainerGridBoxProc (lines ~6538-6805)
    "LABEL_F300EC": "EntGrid_PostMainEvent",
    "LABEL_F3019E": "EntGrid_CheckOverflow1",
    "LABEL_F30250": "EntGrid_CheckOverflow2",
    "LABEL_F302A0": "EntGrid_SetDialEnable",
    "LABEL_F302B6": "EntGrid_GetViewAndCopy",
    "LABEL_F30321": "EntGrid_Epilogue",

    # EntertainerGridCheck (lines ~6807-7258)
    "LABEL_F30678": "EntGridCheck_Handle4140",
    "LABEL_F3068A": "EntGridCheck_CopyStringResult",
    "LABEL_F306A6": "EntGridCheck_Handle4E00",
    "LABEL_F306DA": "EntGridCheck_Handle4E10",
    "LABEL_F30725": "EntGridCheck_Handle4E11",
    "LABEL_F3076F": "EntGridCheck_Handle4E12",
    "LABEL_F307BD": "EntGridCheck_Handle4E13",
    "LABEL_F308A3": "EntGridCheck_DefaultCase1",
    "LABEL_F308D4": "EntGridCheck_DefaultCase2",
    "LABEL_F30909": "EntGridCheck_NullTerminate",
    "LABEL_F3090F": "EntGridCheck_SendAudioCommand",

    # IvSongCopyExitProc (lines ~7260-7322)
    "LABEL_F30964": "IvSongCopyExit_CopyString",
    "LABEL_F30978": "IvSongCopyExit_HandleSelectEvent",
    "LABEL_F309A8": "IvSongCopyExit_CheckTitleA8",
    "LABEL_F309C3": "IvSongCopyExit_PostEvent",
    "LABEL_F309C7": "IvSongCopyExit_PrepareInherited",
    "LABEL_F309CF": "IvSongCopyExit_CallInherited",
    "LABEL_F309D3": "IvSongCopyExit_Epilogue",

    # IvPnlWrExitProc (lines ~7324-7386)
    "LABEL_F309FC": "IvPnlWrExit_CopyString",
    "LABEL_F30A10": "IvPnlWrExit_HandleSelectEvent",
    "LABEL_F30A40": "IvPnlWrExit_CheckTitleAA",
    "LABEL_F30A5B": "IvPnlWrExit_PostEvent",
    "LABEL_F30A5F": "IvPnlWrExit_PrepareInherited",
    "LABEL_F30A67": "IvPnlWrExit_CallInherited",
    "LABEL_F30A6B": "IvPnlWrExit_Epilogue",

    # SqedtFixProc (lines ~8318-9106)
    "LABEL_F315F8": "SqedtFix_HandleInitEvent",
    "LABEL_F3195D": "SqedtFix_SetupLayoutA",
    "LABEL_F31C2C": "SqedtFix_SetupLayoutB",
    "LABEL_F31E8A": "SqedtFix_DrawString",
    "LABEL_F31E8E": "SqedtFix_ReturnZero",
    "LABEL_F31E90": "SqedtFix_Epilogue",

    # SqedtVal3Proc (lines ~9108-9442)
    "LABEL_F31ED4": "SqedtVal3_HandleInitEvent",
    "LABEL_F31F13": "SqedtVal3_HandleScrollEvent",
    "LABEL_F31FB4": "SqedtVal3_FillBufferLoop1",
    "LABEL_F3205D": "SqedtVal3_FillBufferLoop2",
    "LABEL_F32106": "SqedtVal3_FillBufferLoop3",
    "LABEL_F321AF": "SqedtVal3_FillBufferLoop4",
    "LABEL_F321E4": "SqedtVal3_HandleSelectEvent1",
    "LABEL_F32218": "SqedtVal3_HandleSelectEvent2",
    "LABEL_F3224A": "SqedtVal3_CallSetAutoInc",
    "LABEL_F32250": "SqedtVal3_Epilogue",

    # SqedtVal2Proc (lines ~9444-10557)
    "LABEL_F322A1": "SqedtVal2_HandleInitEvent",
    "LABEL_F32314": "SqedtVal2_SendA2A4Events",
    "LABEL_F32333": "SqedtVal2_SendCommonEvents",
    "LABEL_F32380": "SqedtVal2_HandleScrollEvent",
    "LABEL_F32634": "SqedtVal2_HandleUpScrollEvent",
    "LABEL_F32688": "SqedtVal2_UpScrollModeA2",
    "LABEL_F326AE": "SqedtVal2_UpScrollDefault",
    "LABEL_F326D2": "SqedtVal2_UpScrollCalcOffset",
    "LABEL_F326DB": "SqedtVal2_HandleDownScrollEvent",
    "LABEL_F326EF": "SqedtVal2_DownScrollModeA2",
    "LABEL_F32716": "SqedtVal2_DownScrollDefault",
    "LABEL_F3273B": "SqedtVal2_DownScrollCalcOffset",
    "LABEL_F32743": "SqedtVal2_DrawScrollFrame",
    "LABEL_F3275F": "SqedtVal2_DrawWithViewColors",
    "LABEL_F3276C": "SqedtVal2_CallDrawDesignFrame",
    "LABEL_F32773": "SqedtVal2_HandleSelectEvent",
    "LABEL_F327FD": "SqedtVal2_CheckModeA2",
    "LABEL_F32868": "SqedtVal2_CheckModeA4",
    "LABEL_F328D2": "SqedtVal2_DefaultScrollSend",
    "LABEL_F32912": "SqedtVal2_SendScrollAndDial",
    "LABEL_F32931": "SqedtVal2_HandleSelectCase3",
    "LABEL_F3299D": "SqedtVal2_SelectCase3_ModeA2",
    "LABEL_F32A08": "SqedtVal2_SelectCase3_ModeA4",
    "LABEL_F32A72": "SqedtVal2_SelectCase3_Default",
    "LABEL_F32AB2": "SqedtVal2_SelectCase3_SendDial",
    "LABEL_F32AD1": "SqedtVal2_HandleSelectCase2",
    "LABEL_F32B0F": "SqedtVal2_SelectCase2_ModeA4",
    "LABEL_F32B2B": "SqedtVal2_SelectCase2_Default",
    "LABEL_F32B3F": "SqedtVal2_SelectCase2_PostEvent",
    "LABEL_F32B6D": "SqedtVal2_HandleSelectCase4",
    "LABEL_F32BAB": "SqedtVal2_SelectCase4_ModeA4",
    "LABEL_F32BC7": "SqedtVal2_SelectCase4_Default",
    "LABEL_F32BDB": "SqedtVal2_SelectCase4_PostEvent",
    "LABEL_F32C09": "SqedtVal2_HandleUpScrollInner",
    "LABEL_F32C5F": "SqedtVal2_UpInner_CheckA8",
    "LABEL_F32C87": "SqedtVal2_UpInner_SendExtra",
    "LABEL_F32CE1": "SqedtVal2_UpInner_CheckA4",
    "LABEL_F32D20": "SqedtVal2_UpInner_SendFields",
    "LABEL_F32D8A": "SqedtVal2_UpInner_ModeA4Scroll",
    "LABEL_F32DEC": "SqedtVal2_UpInner_SendDial",
    "LABEL_F32E0B": "SqedtVal2_HandleDownScrollInner",
    "LABEL_F32E4B": "SqedtVal2_DownInner_CheckA8",
    "LABEL_F32E8A": "SqedtVal2_DownInner_SendFields",
    "LABEL_F32ECD": "SqedtVal2_DownInner_CheckA4",
    "LABEL_F32F0C": "SqedtVal2_DownInner_SendExtra",
    "LABEL_F32F76": "SqedtVal2_DownInner_ModeA4Scroll",
    "LABEL_F32FD8": "SqedtVal2_DownInner_SendDial",
    "LABEL_F32FF7": "SqedtVal2_HandleDownCase2",
    "LABEL_F33035": "SqedtVal2_DownCase2_ModeA4",
    "LABEL_F33051": "SqedtVal2_DownCase2_Default",
    "LABEL_F33065": "SqedtVal2_DownCase2_PostEvent",
    "LABEL_F33093": "SqedtVal2_HandleDownCase4",
    "LABEL_F330D1": "SqedtVal2_DownCase4_ModeA4",
    "LABEL_F330ED": "SqedtVal2_DownCase4_Default",
    "LABEL_F33101": "SqedtVal2_DownCase4_PostEvent",
    "LABEL_F33132": "SqedtVal2_Epilogue",

    # EffectBoxProc (lines ~10923-11807)
    "LABEL_F3354A": "EffectBox_HandleInitEvent",
    "LABEL_F335CB": "EffectBox_DrawWithViewFrame",
    "LABEL_F335D2": "EffectBox_CallDrawDesignFrame",
    "LABEL_F335D9": "EffectBox_HandleEvent0",
    "LABEL_F335E7": "EffectBox_HandleEvent1",
    "LABEL_F33620": "EffectBox_SendEventCommon",
    "LABEL_F33627": "EffectBox_HandleScrollEvent",
    "LABEL_F336A1": "EffectBox_FillBufferLoop1",
    "LABEL_F33739": "EffectBox_FillBufferLoop2",
    "LABEL_F33752": "EffectBox_PostFillSetup",
    "LABEL_F337EE": "EffectBox_FillBufferLoop3",
    "LABEL_F337F8": "EffectBox_PostFill3Setup",
    "LABEL_F338E2": "EffectBox_SetEmptyString1",
    "LABEL_F338EC": "EffectBox_DrawField1",
    "LABEL_F3397C": "EffectBox_SetEmptyString2",
    "LABEL_F33983": "EffectBox_DrawField2",
    "LABEL_F339A2": "EffectBox_DrawAndSendLoop",
    "LABEL_F339BF": "EffectBox_HandleSelectEvent",
    "LABEL_F33B3B": "EffectBox_DrawWithFBColor",
    "LABEL_F33B4A": "EffectBox_DrawStringAndSetDial",
    "LABEL_F33B70": "EffectBox_SetDialDownAndEnable",
    "LABEL_F33B77": "EffectBox_HandleDefaultEvent",
    "LABEL_F33C23": "EffectBox_RedrawAfterChange",
    "LABEL_F33C65": "EffectBox_SendLoopValue",
    "LABEL_F33C91": "EffectBox_HandleCase2",
    "LABEL_F33CF2": "EffectBox_HandleCaseOther",
    "LABEL_F33D60": "EffectBox_HandleCase0_Post",
    "LABEL_F33E2A": "EffectBox_RedrawFullLoop",
    "LABEL_F33E97": "EffectBox_SendMultipleValues",
    "LABEL_F33EB1": "EffectBox_SetAutoIncAfterLoop",
    "LABEL_F33EC3": "EffectBox_HandleAppFunc",
    "LABEL_F33F21": "EffectBox_HandleCase0_Direct",
    "LABEL_F33F96": "EffectBox_HandleInherited",
    "LABEL_F33FA9": "EffectBox_Epilogue",

    # EqualizerBoxProc (lines ~11842-12355)
    "LABEL_F34016": "Equalizer_SendPanelEvent",
    "LABEL_F34026": "Equalizer_SendChannelLoop",
    "LABEL_F34041": "Equalizer_SendAndLoopDone",
    "LABEL_F34061": "Equalizer_HandleSelectEvent",
    "LABEL_F341A0": "Equalizer_DrawStringDone",
    "LABEL_F341FC": "Equalizer_HandleEvent1",
    "LABEL_F34256": "Equalizer_CallSetAutoInc",
    "LABEL_F3425D": "Equalizer_HandleScrollUpEvent",
    "LABEL_F34368": "Equalizer_SetFixedWidth1",
    "LABEL_F34371": "Equalizer_StoreWidthAndDraw1",
    "LABEL_F343A1": "Equalizer_SetFixedWidth2",
    "LABEL_F343A6": "Equalizer_StoreWidthAndDraw2",
    "LABEL_F34424": "Equalizer_SetFixedWidth3",
    "LABEL_F34429": "Equalizer_StoreWidthAndDraw3",
    "LABEL_F344A7": "Equalizer_SetFixedWidth4",
    "LABEL_F344AC": "Equalizer_StoreWidthAndDraw4",
    "LABEL_F3454A": "Equalizer_SetFixedWidthFF",
    "LABEL_F34553": "Equalizer_StoreWidthAndDrawFF",
    "LABEL_F345D3": "Equalizer_HandleInherited",
    "LABEL_F345DF": "Equalizer_Epilogue",

    # EqOnOffFuncToggleProc (lines ~12371-12400)
    "LABEL_F345FF": "EqOnOff_HandleToggleOn",
    "LABEL_F3461D": "EqOnOff_HandleToggleOff",
    "LABEL_F34628": "EqOnOff_CheckValue",
    "LABEL_F34644": "EqOnOff_ToggleResult",

    # SqedtFunc dispatch area (lines ~12976-13011)
    "LABEL_F34F68": "SqedtFunc_Case2_CopyParam",
    "LABEL_F34F9F": "SqedtFunc_CheckMode_CopyParam",
    "LABEL_F34FB3": "SqedtFunc_CheckMode_SendAudio",

    # SqedtFunc field loaders - SeqFormat_DispatchB (lines ~13214-13481)
    "LABEL_F35299": "SeqFmt_Field_LoadA",
    "LABEL_F352A0": "SeqFmt_Field_LoadB",
    "LABEL_F352A7": "SeqFmt_Field_LoadC",
    "LABEL_F352D5": "SeqFmt_Field_LoadD",
    "LABEL_F352DC": "SeqFmt_Field_LoadE",
    "LABEL_F352E3": "SeqFmt_Field_LoadF",
    "LABEL_F352EA": "SeqFmt_Field_LoadG",
    "LABEL_F35310": "SeqFmt_Field_LoadH",
    "LABEL_F35317": "SeqFmt_Field_LoadI",
    "LABEL_F3531E": "SeqFmt_Field_LoadJ",
    "LABEL_F3533C": "SeqFmt_Field_LoadK",
    "LABEL_F35343": "SeqFmt_Field_LoadL",
    "LABEL_F35369": "SeqFmt_Field_LoadM",
    "LABEL_F35370": "SeqFmt_Field_LoadN",
    "LABEL_F35377": "SeqFmt_Field_LoadO",
    "LABEL_F353AD": "SeqFmt_Field_LoadP",
    "LABEL_F353B4": "SeqFmt_Field_LoadQ",
    "LABEL_F353BB": "SeqFmt_Field_LoadR",
    "LABEL_F353C2": "SeqFmt_Field_LoadS",
    "LABEL_F353C9": "SeqFmt_Field_LoadT",
    "LABEL_F353EF": "SeqFmt_Field_LoadU",
    "LABEL_F353F6": "SeqFmt_Field_LoadV",
    "LABEL_F353FD": "SeqFmt_Field_LoadW",
    "LABEL_F3541B": "SeqFmt_Field_LoadX",
    "LABEL_F35422": "SeqFmt_Field_LoadY",
    "LABEL_F35458": "SeqFmt_Field_LoadZ",
    "LABEL_F3545F": "SeqFmt_Field_LoadAA",
    "LABEL_F35466": "SeqFmt_Field_LoadAB",
    "LABEL_F3546D": "SeqFmt_Field_LoadAC",
    "LABEL_F35474": "SeqFmt_Field_LoadAD",
    "LABEL_F354A9": "SeqFmt_Field_LoadAE",
    "LABEL_F354AF": "SeqFmt_Field_LoadAF",
    "LABEL_F354B5": "SeqFmt_Field_LoadAG",
    "LABEL_F354BB": "SeqFmt_Field_LoadAH",
    "LABEL_F354C1": "SeqFmt_Field_LoadAI",

    # DspItem0_CngFunc (lines ~13447-13455)
    "LABEL_F354E5": "DspItem0Cng_LoadFieldA",
    "LABEL_F354EB": "DspItem0Cng_LoadFieldB",
    "LABEL_F354F1": "DspItem0Cng_LoadFieldC",

    # SqedtFunc_GetFieldAddr_BySelector (lines ~13469-13481)
    "LABEL_F35515": "SqedtFunc_FieldSel_LoadA",
    "LABEL_F3551B": "SqedtFunc_FieldSel_LoadB",
    "LABEL_F35521": "SqedtFunc_FieldSel_LoadC",

    # DspItem0_TypeDispatch (line ~13744)
    "LABEL_F357C8": "DspItem0_HandleType2",

    # FormatEqParamValue (line ~13950)
    "LABEL_F359AE": "FormatEqParam_CopyAndReturn",

    # Equalizer_FormatDispatch (line ~14125)
    "LABEL_F35B85": "EqFormat_DispatchTable",

    # Equalizer_FormatDefault (lines ~14178-14185)
    "LABEL_F35C2D": "EqFormat_NegativeValue",
    "LABEL_F35C39": "EqFormat_PositiveValue",

    # CycleOnOffFunc (line ~14239)
    "LABEL_F35CAF": "CycleOnOff_PostAndReturn",

    # MetroOnOffFunc (lines ~14253-14261)
    "LABEL_F35CCC": "MetroOnOff_SendDisable",
    "LABEL_F35CD8": "MetroOnOff_PostEvent",
    "LABEL_F35CDC": "MetroOnOff_ReturnZero",

    # PunchInOutFunc (lines ~14275-14283)
    "LABEL_F35CF9": "PunchInOut_SendDisable",
    "LABEL_F35D05": "PunchInOut_PostEvent",
    "LABEL_F35D09": "PunchInOut_ReturnZero",

    # EqInOutFunc (lines ~14297-14305)
    "LABEL_F35D23": "EqInOut_SendEnable",
    "LABEL_F35D2C": "EqInOut_CallLswPut",
    "LABEL_F35D30": "EqInOut_ReturnZero",

    # MimeOnOffFunc (line ~14316)
    "LABEL_F35D49": "MimeOnOff_PostAndReturn",

    # BitmapNtedt0k (lines ~14339-14347)
    "LABEL_F35D7D": "BitmapNtedt0k_GetAddress",
    "LABEL_F35D83": "BitmapNtedt0k_GetWidth",
    "LABEL_F35D89": "BitmapNtedt0k_GetHeight",

    # BitmapNtedt0d (lines ~14362-14370)
    "LABEL_F35DAA": "BitmapNtedt0d_GetAddress",
    "LABEL_F35DB0": "BitmapNtedt0d_GetWidth",
    "LABEL_F35DB6": "BitmapNtedt0d_GetHeight",

    # BitmapDredt0k (lines ~14385-14393)
    "LABEL_F35DD7": "BitmapDredt0k_GetAddress",
    "LABEL_F35DDD": "BitmapDredt0k_GetWidth",
    "LABEL_F35DE3": "BitmapDredt0k_GetHeight",
}

def main():
    files_to_update = [
        'maincpu/sequencer/sequencer_ui.s',
        'maincpu/ui_widgets/style_bitmaps.s',  # LABEL_F300EC external reference
    ]

    for filepath in files_to_update:
        full_path = os.path.join('/home/fsanches/compartilhado/kn5000-roms-disasm', filepath)
        if not os.path.exists(full_path):
            continue
        with open(full_path, 'rb') as f:
            data = f.read()

        original = data
        for old, new in RENAMES.items():
            data = data.replace(old.encode('ascii'), new.encode('ascii'))

        if data != original:
            with open(full_path, 'wb') as f:
                f.write(data)
            count = sum(1 for old in RENAMES if old.encode('ascii') in original)
            print(f"  Updated {filepath}: {count} label(s) renamed")

    print(f"\nTotal renames: {len(RENAMES)}")

if __name__ == '__main__':
    main()
