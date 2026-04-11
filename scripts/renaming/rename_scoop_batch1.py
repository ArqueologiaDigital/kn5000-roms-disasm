#!/usr/bin/env python3
"""Batch 1: Rename ~106 LABEL_XXXXXX to semantic names in scoop_display.s (and cross-file refs)."""
import os, sys, tempfile, glob

RENAMES = {
    # Graphics rendering conditional wrappers (lines 290-427)
    "LABEL_EF5CF0": "UIRender_SingleTable_Body",
    "LABEL_EF5D01": "UIRender_TwoTableGeneral_Body",
    "LABEL_EF5D12": "GraphicsRender_TwoTable_Body",
    "LABEL_EF5D1F": "GraphicsRender_TwoTable_Alt",
    "LABEL_EF5D27": "GraphicsRender_TwoTable_Alt_Body",
    "LABEL_EF5D3C": "UIRender_TwoTableEvtCheck_Body",
    "LABEL_EF5D45": "UIRender_ConditionalDrawInit",
    "LABEL_EF5D4D": "UIRender_ConditionalDrawInit_Body",
    "LABEL_EF5D5E": "Scoop_ConditionalCurveUpdate_Body",
    "LABEL_EF5D67": "Scoop_CurveUpdate_Direct",
    "LABEL_EF5D78": "Scoop_ConditionalGlideSetup_Body",
    "LABEL_EF5D81": "UIRender_ConditionalFBCall",
    "LABEL_EF5D89": "UIRender_ConditionalFBCall_Body",
    "LABEL_EF5D9A": "GraphicsRender_EventCheck_Body",

    # Data tables and rendering descriptors (lines 428-460)
    "LABEL_EF5DA3": "UIRender_LoadTwoDescriptors",
    "LABEL_EF5DB6": "UIRender_DescriptorTable1",
    "LABEL_EF5E37": "UIRender_DescriptorTable2",

    # Param digit extraction (lines 460-528)
    "LABEL_EF5E5C": "ParamDigit_ExtractAndFormat",
    "LABEL_EF5E75": "ParamDigit_ExtractDone",
    "LABEL_EF5E76": "ParamDigit_CalrData",
    "LABEL_EF5E84": "ParamDigit_DivideValue",
    "LABEL_EF5E9C": "ParamDigit_Div100Loop",
    "LABEL_EF5EB3": "ParamDigit_Div100Done",
    "LABEL_EF5EBD": "ParamDigit_Div10Loop",
    "LABEL_EF5ED4": "ParamDigit_Div10Done",

    # Undisassembled data block
    "LABEL_EF5EEE": "ScoopDisp_BytecodeBlock1",

    # Channel filter / indicator setup (lines 547-614)
    "LABEL_EF5F56": "ChannelFilter_InitAndApply",
    "LABEL_EF5F65": "ChannelFilter_SetMode",
    "LABEL_EF5F6B": "ChannelFilter_ApplyWrapper",
    "LABEL_EF5F6F": "ChannelFilter_ApplyMask",
    "LABEL_EF5F7E": "ChannelFilter_BitScanLoop",
    "LABEL_EF5FA0": "ChannelFilter_ClearBit",
    "LABEL_EF5FB2": "ChannelFilter_NextBit",

    # Display setup wrappers (lines 600-710)
    "LABEL_EF5FBE": "Display_LoadAndSetIndicator",
    "LABEL_EF5FCB": "Display_LoadChannelMask",
    "LABEL_EF5FD7": "Display_LoadChannelMask_Ret",
    "LABEL_EF5FD8": "Display_CopyToneTableToRAM",
    "LABEL_EF5FFC": "Display_InitScreenLayout",
    "LABEL_EF6019": "Display_InitParamLoader1",
    "LABEL_EF602A": "Display_InitParamLoader2",
    "LABEL_EF6033": "Display_CallMenuInit",
    "LABEL_EF6038": "Display_ConditionalCompare",
    "LABEL_EF6046": "Display_ConditionalCompare_Ret",
    "LABEL_EF6047": "Display_CallMenuConfig",
    "LABEL_EF604C": "Display_PollAudioAndUpdate",
    "LABEL_EF605C": "Display_PollAudioLoop",
    "LABEL_EF606E": "Display_PollAudioDone",
    "LABEL_EF6073": "Display_DeletePollEvent",
    "LABEL_EF607F": "Display_CallSetupRoutine",
    "LABEL_EF6084": "Display_NullHandler",
    "LABEL_EF6085": "MIDI_SendSysExFromW",

    # Bytecode handler data blocks (lines 743-792)
    "LABEL_EF6159": "ScoopDisp_HandlerData2",
    "LABEL_EF628F": "ScoopDisp_FlagSetAndDispatch",
    "LABEL_EF62A7": "ScoopDisp_DispatchTable_Small",

    # Jump tables for performance mode (lines 886-1002)
    "LABEL_EF6423": "PerfMode_JumpTable_Extended",
    "LABEL_EF648A": "PerfMode_EventTable_0",
    "LABEL_EF650A": "PerfMode_Evt03_FlagHandler_A",
    "LABEL_EF6528": "PerfMode_Evt03_FlagHandler_B",
    "LABEL_EF6546": "PerfMode_Evt03_ClampAndUpdate",
    "LABEL_EF6564": "PerfMode_ClampValue",
    "LABEL_EF6577": "PerfMode_ClampValue_Dec",
    "LABEL_EF65DD": "PerfMode_EventTable_1",
    "LABEL_EF667C": "PerfMode_EventTable_2",

    # More performance mode handler tables
    "LABEL_EF6713": "PerfMode_ParamHandler_3_Entry",
    "LABEL_EF6726": "PerfMode_EventTable_3",
    "LABEL_EF67C5": "PerfMode_EventTable_4",
    "LABEL_EF685C": "PerfMode_EventTable_5",
    "LABEL_EF690E": "PerfMode_EventTable_6",
    "LABEL_EF69A5": "PerfMode_EventTable_7",
    "LABEL_EF6AF2": "PerfMode_EventTable_9",
    "LABEL_EF6B72": "PerfMode_Evt04_VolumeHandler",
    "LABEL_EF6BE7": "PerfMode_VoiceAddressTable",
    "LABEL_EF6C6B": "PerfMode_EventTable_10",

    # Voice param dispatcher (lines 1414-1530)
    "LABEL_EF6CEB": "VoiceParam_MultiDispatch",
    "LABEL_EF6D2D": "VoiceParam_Case03",
    "LABEL_EF6D4E": "VoiceParam_Case08",
    "LABEL_EF6D6F": "VoiceParam_Case0A",
    "LABEL_EF6D90": "VoiceParam_Case0B",
    "LABEL_EF6DE2": "VoiceParam_SaveRestore_Ret",
    "LABEL_EF6DE3": "VoiceParam_BitManipHelper",
    "LABEL_EF6E28": "VoiceParam_BitManip_Ret",

    # UI state dispatch (lines 1529-1602)
    "LABEL_EF6E29": "UIState_PerfModeEntry",
    "LABEL_EF6E44": "UIState_EventTable",
    "LABEL_EF6EE1": "UIState_CallDecHandler",
    "LABEL_EF6EE5": "UIState_CheckValueChanged",
    "LABEL_EF6EFC": "UIState_UpdateAllRegions",
    "LABEL_EF6F00": "UIState_Dispatch_Ret",
    "LABEL_EF6F01": "UIState_UpdateMultiRegions",

    # Display redraw helpers (lines 1617-1810)
    "LABEL_EF6F42": "Display_RedrawParams_StoreAndLoad",
    "LABEL_EF6F82": "Display_RedrawParams_StoreDigits",
    "LABEL_EF6FA2": "Display_RedrawParams_Ret",
    "LABEL_EF6FBA": "Display_RedrawValues_Store",
    "LABEL_EF702A": "Display_RedrawValues_StoreDigits",
    "LABEL_EF704A": "Display_RedrawValues_Ret",
    "LABEL_EF7068": "Display_RedrawInd_Store",
    "LABEL_EF708C": "Display_RedrawInd_LoadDirect",
    "LABEL_EF70AF": "Display_RedrawInd_CalcSlotCount",
    "LABEL_EF70BC": "Display_RedrawInd_StoreDigits",
    "LABEL_EF70DC": "Display_RedrawInd_Ret",
    "LABEL_EF7128": "Display_RedrawFooter_Main",
    "LABEL_EF7158": "Display_RedrawTitleString",
    "LABEL_EF718B": "Display_TitleString_BuildFromMode",
    "LABEL_EF71C0": "Display_TitleString_Mode0",
    "LABEL_EF71CB": "Display_TitleString_Mode1",
    "LABEL_EF71D7": "Display_TitleString_Mode2",
    "LABEL_EF71E2": "Display_TitleString_Mode3",
    "LABEL_EF71ED": "Display_TitleString_Mode4",
    "LABEL_EF71F8": "Display_TitleString_Mode5",
}

def atomic_write(path, data):
    dirn = os.path.dirname(path)
    fd, tmp = tempfile.mkstemp(dir=dirn, suffix='.tmp')
    try:
        os.write(fd, data)
        os.fsync(fd)
        os.close(fd)
        os.rename(tmp, path)
    except:
        os.close(fd)
        os.unlink(tmp)
        raise

def rename_in_file(filepath, renames):
    with open(filepath, 'rb') as f:
        content = f.read()
    original = content
    for old, new in renames.items():
        content = content.replace(old.encode('latin-1'), new.encode('latin-1'))
    if content != original:
        atomic_write(filepath, content)
        return True
    return False

base = '/home/fsanches/compartilhado/kn5000-roms-disasm'
s_files = glob.glob(os.path.join(base, 'maincpu', '**', '*.s'), recursive=True)

changed = 0
for f in s_files:
    if rename_in_file(f, RENAMES):
        changed += 1
        print(f'  Updated: {os.path.relpath(f, base)}')

print(f'\nBatch 1: Renamed {len(RENAMES)} labels across {changed} files')
