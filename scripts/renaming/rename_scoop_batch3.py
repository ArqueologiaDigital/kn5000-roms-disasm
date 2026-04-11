#!/usr/bin/env python3
"""Batch 3: Rename remaining ~118 LABEL_XXXXXX to semantic names in scoop_display.s (and cross-file refs)."""
import os, sys, subprocess, glob

RENAMES = {
    # SysEx dispatch / controller mode (lines 4322-4425)
    "LABEL_EFAA2E": "SysEx_CountdownCheck",
    "LABEL_EFAA34": "SysEx_DecrementAndCheck",
    "LABEL_EFAA40": "SysEx_ControllerBitCheck",
    "LABEL_EFAA84": "SysEx_ModeChangeCheck",
    "LABEL_EFAAB9": "SysEx_FlagClearAndCompare",
    "LABEL_EFAACE": "SysEx_DecrementCounter",
    "LABEL_EFAADB": "SysEx_BytecodeDispatcher",

    # Memory config voice slot (lines 4478-4507)
    "LABEL_EFAD4E": "MemConfig_VoiceSlotLookup",
    "LABEL_EFAD77": "MemConfig_VoiceSlotCompare",
    "LABEL_EFAD8B": "MemConfig_VoiceSlotSkip",
    "LABEL_EFAD93": "MemConfig_VoiceSlotRet",

    # Sound dispatch tables (lines 4646-4735)
    "LABEL_EFB1A6": "SndDispatch_JumpTable_Main",
    "LABEL_EFB1D2": "SndDispatch_Handler_1",
    "LABEL_EFB1F7": "SndDispatch_SubTable_1",
    "LABEL_EFB20F": "SndDispatch_Handler_2",
    "LABEL_EFB234": "SndDispatch_SubTable_2",
    "LABEL_EFB271": "SndDispatch_BytecodeString",
    "LABEL_EFB275": "SndDispatch_SubTable_3",
    "LABEL_EFB289": "SndDispatch_ShortHandler",
    "LABEL_EFB28E": "SndDispatch_Handler_3",
    "LABEL_EFB2B3": "SndDispatch_SubTable_4",
    "LABEL_EFB2CB": "SndDispatch_Handler_4",
    "LABEL_EFB2F4": "SndDispatch_SubTable_5",
    "LABEL_EFB308": "SndDispatch_CallAndInit",
    "LABEL_EFB31F": "SndDispatch_SetFlag30",

    # System init handlers (lines 4892-4962)
    "LABEL_EFB7C9": "SysInit_SendAllNotesAndReset",
    "LABEL_EFB94A": "SysInit_BytecodeBlock",

    # Voice slot routines (lines 5185-5553)
    "LABEL_EFBFDC": "VoiceSlot_InitAndProcess",
    "LABEL_EFBFE5": "VoiceSlot_InitLoop",
    "LABEL_EFC040": "VoiceSlot_ProcessEntry",
    "LABEL_EFC0C4": "VoiceSlot_CheckDone",
    "LABEL_EFC0C5": "VoiceSlot_RetNZ",
    "LABEL_EFC0C6": "VoiceSlot_RetZ",
    "LABEL_EFC1BF": "VoiceSlot_LoadAndDispatch",
    "LABEL_EFC1E5": "VoiceSlot_DispatchDone",
    "LABEL_EFC1E6": "VoiceSlot_DispatchRet",
    "LABEL_EFC1F3": "VoiceSlot_CompareAndBranch",
    "LABEL_EFC207": "VoiceSlot_CompareRet",
    "LABEL_EFC241": "VoiceSlot_StoreAndAdvance",
    "LABEL_EFC261": "VoiceSlot_CopyBlock",
    "LABEL_EFC28A": "VoiceSlot_CopyBlockDone",
    "LABEL_EFC2A4": "VoiceSlot_LoadFromTable",
    "LABEL_EFC2AE": "VoiceSlot_LoadFromTableBody",
    "LABEL_EFC2F8": "VoiceSlot_CallSubroutine",
    "LABEL_EFC321": "VoiceSlot_SubroutineTable",
    "LABEL_EFC329": "VoiceSlot_SubroutineBody",
    "LABEL_EFC354": "VoiceSlot_SubrDone",
    "LABEL_EFC357": "VoiceSlot_SubrRetNZ",
    "LABEL_EFC358": "VoiceSlot_SubrRetZ",
    "LABEL_EFC367": "VoiceSlot_AdvancePointer",
    "LABEL_EFC39F": "VoiceSlot_FlagCheck",
    "LABEL_EFC3AA": "VoiceSlot_FlagCheckBody",
    "LABEL_EFC3B5": "VoiceSlot_FlagCheckDone",
    "LABEL_EFC3F9": "VoiceSlot_FinalCheck",
    "LABEL_EFC416": "VoiceSlot_FinalDone",
    "LABEL_EFC418": "VoiceSlot_FinalRetNZ",
    "LABEL_EFC419": "VoiceSlot_FinalRetZ",

    # Voice slot index compute (lines 5658-5721)
    "LABEL_EFC6C6": "VoiceSlot_ComputeIndex",
    "LABEL_EFC6DC": "VoiceSlot_IndexDone",
    "LABEL_EFC780": "VoiceSlot_StatusCheck",
    "LABEL_EFC798": "VoiceSlot_StatusActive",
    "LABEL_EFC7B1": "VoiceSlot_StatusDone",
    "LABEL_EFC7B2": "VoiceSlot_StatusRet",

    # Voice slot save/restore (lines 6007-6101)
    "LABEL_EFD08E": "VoiceState_SaveAndRestore",
    "LABEL_EFD11C": "VoiceState_DataBlock1",
    "LABEL_EFD134": "VoiceState_RestoreEntry",
    "LABEL_EFD16B": "VoiceState_RestoreDone",
    "LABEL_EFD17A": "VoiceState_DataBlock2",

    # SubCPU call / tone param display (lines 6373-6509)
    "LABEL_EFD9BC": "SubCPU_ToneParamDisplay",
    "LABEL_EFDB40": "SubCPU_ToneDispatch",
    "LABEL_EFDBC2": "SubCPU_ToneHandler_A",
    "LABEL_EFDBDF": "SubCPU_ToneHandler_B",
    "LABEL_EFDBED": "SubCPU_ToneLoadAndStore",
    "LABEL_EFDC08": "SubCPU_ToneStoreDigits",
    "LABEL_EFDC20": "SubCPU_ToneFormatValue",
    "LABEL_EFDC2A": "SubCPU_ToneFormatDone",
    "LABEL_EFDC43": "SubCPU_ToneClearRegion",
    "LABEL_EFDCC1": "SubCPU_ToneParamRet",

    # Oscilloscope / waveform handler tables (lines 6871-6970)
    "LABEL_EFE765": "OscScope_HandlerTable",
    "LABEL_EFE7A6": "OscScope_Handler_2",
    "LABEL_EFE7AB": "OscScope_Handler_3",
    "LABEL_EFE7B0": "OscScope_Handler_4",
    "LABEL_EFE7B5": "OscScope_Handler_6",
    "LABEL_EFE7BA": "OscScope_Handler_7",
    "LABEL_EFE808": "OscScope_DrawWaveform",
    "LABEL_EFE820": "OscScope_UpdateDisplay",
    "LABEL_EFE888": "OscScope_RefreshLoop",
    "LABEL_EFE921": "OscScope_RenderBlock",
    "LABEL_EFE989": "OscScope_FinalizeRender",

    # Voice bank processing (lines 6999-7074)
    "LABEL_EFEA73": "VoiceBank_CallAndReturn",
    "LABEL_EFEA7B": "VoiceBank_CallAndLoop",
    "LABEL_EFEA90": "VoiceBank_Ret",
    "LABEL_EFEA91": "VoiceBank_LoadLerpState",
    "LABEL_EFEAC1": "VoiceBank_UpdateLerpState",
    "LABEL_EFEAF2": "VoiceBank_IncrementIndex",
    "LABEL_EFEAF4": "VoiceBank_StoreIndex",

    # Display bytecode / string data (lines 7076-7228)
    "LABEL_EFEB06": "DisplayStr_BytecodeBlock_A",
    "LABEL_EFED00": "DisplayStr_ComputeTableAddr",
    "LABEL_EFED12": "DisplayStr_BytecodeBlock_B",
    "LABEL_EFEDC1": "DisplayStr_RhythmLabel",
    "LABEL_EFEE71": "DisplayStr_BytecodeBlock_C",
    "LABEL_EFEF3A": "DisplayStr_TempoString",

    # Display helpers and string formatting (lines 7254-7343)
    "LABEL_EFEFDA": "DisplayStr_FillDashes",
    "LABEL_EFEFEA": "DisplayStr_BytecodeBlock_D",
    "LABEL_EFF028": "DisplayStr_ClearRegion",
    "LABEL_EFF035": "DisplayStr_ClearLoop",
    "LABEL_EFF03F": "DisplayStr_StyleSectionInit",
    "LABEL_EFF06C": "DisplayStr_StyleClearLoop",
    "LABEL_EFF077": "DisplayStr_BytecodeBlock_E",
    "LABEL_EFF0A2": "DisplayStr_StyleSectionNames",

    # Display redraw menu (lines 7322-7377)
    "LABEL_EFF123": "Display_RedrawMenu_Extract",
    "LABEL_EFF13F": "Display_RedrawMenu_Update",
    "LABEL_EFF144": "Display_BytecodeBlock_F",

    # SNS init / startup data (lines 7459-7582)
    "LABEL_EFF526": "SNS_LoadKeyAndChord",
    "LABEL_EFF56D": "SNS_LoadDurationData",
    "LABEL_EFF599": "StringData_KeyNames",
    "LABEL_EFF939": "StringData_PartNames",

    # Effect / DSP string data (lines 7678-7749)
    "LABEL_EFFC89": "StringData_EffectLabel",
    "LABEL_EFFEA1": "StringData_APCModeNames",
}

base = '/home/fsanches/compartilhado/kn5000-roms-disasm'
s_files = glob.glob(os.path.join(base, 'maincpu', '**', '*.s'), recursive=True)

changed = 0
for f in s_files:
    with open(f, 'rb') as fh:
        content = fh.read()
    original = content
    for old, new in RENAMES.items():
        content = content.replace(old.encode('latin-1'), new.encode('latin-1'))
    if content != original:
        tmp = '/tmp/_nfs_' + os.path.basename(f)
        with open(tmp, 'wb') as fh:
            fh.write(content)
            fh.flush()
            os.fsync(fh.fileno())
        subprocess.run(['cp', '-f', tmp, f], check=True)
        os.unlink(tmp)
        changed += 1
        print(f'  Updated: {os.path.relpath(f, base)}')

print(f'\nBatch 3: Renamed {len(RENAMES)} labels across {changed} files')
