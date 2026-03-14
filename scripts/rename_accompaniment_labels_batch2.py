#!/usr/bin/env python3
"""
Rename LABEL_XXXXXX to semantic names in accompaniment_engine.s (batch 2).
Covers AccTone / AccPatch / Seq_RhythmProcessor area.

Uses binary I/O to preserve Latin-1 bytes safely.
"""

import os
import sys

# Directory containing the disassembly
DISASM_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mapping from LABEL_XXXXXX to semantic names
# Only includes labels where the purpose is confidently determined
RENAMES = {
    # ===== AccTone_ExtendAndDispatch sub-labels =====
    "LABEL_F5D740": "AccTone_ExtendAndDispatch_Body",
    "LABEL_F5D7C1": "AccTone_ExtendAndDispatch_PopRet",
    "LABEL_F5D7C3": "AccTone_CheckBit10Flag",
    "LABEL_F5D7F4": "AccTone_FoundMatch_IncRet",
    "LABEL_F5D7FB": "AccTone_CheckBit3Flag",
    "LABEL_F5D88E": "AccTone_CheckDirectAddr",
    "LABEL_F5D89A": "AccTone_DirectAddr_Mode1",
    "LABEL_F5D89E": "AccTone_DirectAddr_Mode2",
    "LABEL_F5D8A2": "AccTone_ValidateAndWrite",
    "LABEL_F5D8C0": "AccTone_LookupFailed",
    "LABEL_F5D8C5": "AccTone_InlineBytecodeData",

    # ===== Voice state reset =====
    "LABEL_F5DEC4": "AccVoice_ClearChannelStates",
    "LABEL_F5DEE3": "AccVoice_IncrementBarCounter",
    "LABEL_F5DEFC": "AccVoice_BarCounterBytecodeData",

    # ===== Chord/tuning lookup =====
    "LABEL_F5E393": "AccTuning_ReadAndApplyOffset",
    "LABEL_F5E3A6": "AccTuning_ComplexBytecodeData",

    # ===== AccTone wrapper functions =====
    "LABEL_F5E700": "AccTone_LookupByProgram_Dispatch",
    "LABEL_F5E834": "AccVoice_IncrementBarWithSave",
    "LABEL_F5E847": "AccTuning_DispatchDataBlock_A",
    "LABEL_F5E8BD": "AccTuning_DispatchDataBlock_B",
    "LABEL_F5E8CC": "AccTone_LookupByProgramWrapped",
    "LABEL_F5E8E7": "AccTone_JumpTableData",
    "LABEL_F5E917": "AccTone_StubReturn_A",
    "LABEL_F5E918": "AccTone_StubReturn_B",
    "LABEL_F5E919": "AccPatch_CountSlots_Wrapper",
    "LABEL_F5E921": "AccPatch_InitAndCountSlots",
    "LABEL_F5E93B": "AccPatch_InitByteData",
    "LABEL_F5E95A": "AccDemo_InitWithFlag",
    "LABEL_F5E966": "AccPatch_MultiCallWrapper",
    "LABEL_F5E97F": "AccPatch_ClearModeFlag",

    # ===== AccPatch slot management =====
    "LABEL_F5EAEE": "AccPatch_CheckAndInitDemo",
    "LABEL_F5EB03": "AccPatch_CheckAndInitDemo_Ret",
    "LABEL_F5EB04": "AccPatch_SlotConfigByteData",
    "LABEL_F5EB9C": "AccPatch_SlotScanByteData",

    # ===== AccPatch sequence read =====
    "LABEL_F5EC57": "AccPatch_RefreshSlotOffset_Wrap",
    "LABEL_F5EC5E": "AccPatch_RefreshSlotOffset",

    # ===== Seq_RhythmProcessor sub-calls =====
    "LABEL_F5EC91": "RhythmProc_CheckStyleChange",
    "LABEL_F5EC9A": "RhythmProc_StyleChange_Init",
    "LABEL_F5ECAF": "RhythmProc_StyleChange_Ret",
    "LABEL_F5ECB0": "RhythmProc_CheckPlayMode",
    "LABEL_F5ECC4": "RhythmProc_PlayMode_Compare",
    "LABEL_F5ECDB": "RhythmProc_PlayMode_SendTempo",

    # ===== Rhythm tempo/dispatch =====
    "LABEL_F5ED44": "RhythmProc_CallDispatch",
    "LABEL_F5ED49": "RhythmProc_NullStub",
    "LABEL_F5ED4A": "RhythmProc_CopySlotData_Wrap",
    "LABEL_F5ED51": "RhythmProc_CopySlotData",
    "LABEL_F5ED6C": "RhythmProc_ChannelMapTable",

    # ===== AccPatch_GetCurrentSlotAddr internals =====
    "LABEL_F5ED97": "AccPatch_GetSlotAddr_Valid",
    "LABEL_F5EDA9": "AccPatch_GetSlotAddr_Preserve",

    # ===== AccPatch_InitCurrentSlot internals =====
    "LABEL_F5EDE2": "AccPatch_GetEntryAddr_Ret",
    "LABEL_F5EE0B": "AccPatch_InitFromIndex_Valid",
    "LABEL_F5EE2D": "AccPatch_InitByteStub",
    "LABEL_F5EE4A": "AccPatch_CopyDefaultsToSlot",
    "LABEL_F5EE78": "AccPatch_CopyDefaults_Done",
    "LABEL_F5EE7F": "AccPatch_ClearSlot13ByIndex",
    "LABEL_F5EE8E": "AccPatch_ClearSlot13_Check0F",
    "LABEL_F5EE96": "AccPatch_ClearSlot13_Check14",
    "LABEL_F5EE9E": "AccPatch_ClearSlot13_Check15",
    "LABEL_F5EEA6": "AccPatch_ClearSlot13_Check1A",
    "LABEL_F5EEAE": "AccPatch_ClearSlot13_Check1B",
    "LABEL_F5EEB6": "AccPatch_ClearSlot13_Done",
    "LABEL_F5EEB8": "AccPatch_MiscByteData",

    # ===== Chain free/init =====
    "LABEL_F5EECD": "AccPatch_FreeAllChains",
    "LABEL_F5EEF9": "AccPatch_FreeChainLoop",
    "LABEL_F5EF1A": "AccPatch_FreeChain_Done",
    "LABEL_F5EF1C": "AccPatch_FillAllVoiceData",
    "LABEL_F5EF63": "AccPatch_FillVoice_Loop",
    "LABEL_F5EF72": "AccPatch_CopyDefaultsForInit",
    "LABEL_F5EFA0": "AccPatch_CopyDefaults_InitDone",
    "LABEL_F5EFA7": "AccPatch_DefaultSlotData",

    # ===== Slot index range-check =====
    "LABEL_F5EFFB": "AccPatch_ClearSlot13BySlotIdx",
    "LABEL_F5F007": "AccPatch_ClearSlot13_Idx0F",
    "LABEL_F5F011": "AccPatch_ClearSlot13_Idx14",
    "LABEL_F5F01B": "AccPatch_ClearSlot13_Idx15",
    "LABEL_F5F025": "AccPatch_ClearSlot13_Idx1A",
    "LABEL_F5F02F": "AccPatch_ClearSlot13_Idx1B",
    "LABEL_F5F039": "AccPatch_ClearSlot13_IdxDone",
    "LABEL_F5F03A": "AccPatch_SetVoiceAndInit",

    # ===== Voice stride table =====
    "LABEL_F5F068": "AccPatch_VoiceStrideTable",
    "LABEL_F5F090": "AccPatch_CheckConfigType",

    # ===== Rhythm config flag processing =====
    "LABEL_F5F0B2": "AccPatch_CheckConfig_Done",
    "LABEL_F5F0F8": "AccPatch_WriteSentinel_Loop",
    "LABEL_F5F11C": "RhythmProc_CheckRhythmEdit",
    "LABEL_F5F129": "RhythmProc_RhythmEdit_Ret",
    "LABEL_F5F12A": "RhythmProc_CheckVoiceChange",
    "LABEL_F5F138": "RhythmProc_CheckVoiceUpdate",
    "LABEL_F5F146": "RhythmProc_VoiceUpdate_Ret",
    "LABEL_F5F147": "RhythmProc_UpdateVoiceSentinels",

    # ===== Config bit flags =====
    "LABEL_F5F158": "RhythmProc_CheckConfigBits",
    "LABEL_F5F174": "RhythmProc_ConfigBit1",
    "LABEL_F5F190": "RhythmProc_ConfigBit2",
    "LABEL_F5F1AC": "RhythmProc_ConfigBit2_SetBit6",
    "LABEL_F5F1B6": "RhythmProc_ConfigBits_Done",

    # ===== Channel-based slot operations =====
    "LABEL_F5F1B7": "AccPatch_RebuildChannelSlot",
    "LABEL_F5F21C": "AccPatch_RebuildChannel_Done",
    "LABEL_F5F23C": "AccPatch_ComputeSeqPosition",
    "LABEL_F5F270": "AccPatch_SeqPosition_Store",
    "LABEL_F5F2A7": "AccPatch_SeqBaseAddrTable",
    "LABEL_F5F2D7": "AccPatch_WriteRhythmInit",
    "LABEL_F5F30F": "AccPatch_WriteRhythm_Done",
    "LABEL_F5F310": "AccPatch_ChannelToParamTable",
    "LABEL_F5F338": "AccPatch_WriteRhythmParams",
    "LABEL_F5F341": "AccPatch_WriteRhythmParam_Loop",
    "LABEL_F5F37F": "AccPatch_WriteRhythmParam_Push",
    "LABEL_F5F38D": "AccPatch_WriteRhythmParam_Done",
    "LABEL_F5F38E": "AccPatch_RhythmParamDefaults",
    "LABEL_F5F39A": "AccPatch_FetchVolumeForChannel",
    "LABEL_F5F3D1": "AccPatch_FetchVolume_Default",

    # ===== Rhythm pattern update =====
    "LABEL_F5F3DA": "RhythmProc_CheckStyleSwitch",
    "LABEL_F5F3E3": "RhythmProc_StyleSwitch_Call",
    "LABEL_F5F3E7": "RhythmProc_StyleSwitch_Ret",
    "LABEL_F5F3E8": "RhythmProc_CheckRepeatFlag",
    "LABEL_F5F419": "RhythmProc_RepeatFlag_Store",
    "LABEL_F5F41B": "RhythmProc_RepeatFlag_Ret",
    "LABEL_F5F41C": "RhythmProc_SavePrevState",
    "LABEL_F5F443": "RhythmProc_SavePrevState_Done",

    # ===== Patch slot counting =====
    "LABEL_F5F44C": "AccPatch_CountSlots_Loop",
    "LABEL_F5F457": "AccPatch_CountSlots_Dec",
    "LABEL_F5F461": "AccPatch_CountSlots_Store",
    "LABEL_F5F466": "AccPatch_CountSlotsAlt_Body",
    "LABEL_F5F47C": "AccPatch_CountSlotsAlt_Loop",
    "LABEL_F5F487": "AccPatch_CountSlotsAlt_Dec",
    "LABEL_F5F491": "AccPatch_CountSlotsAlt_Store",
    "LABEL_F5F49B": "AccPatch_MiscDataBlock",

    # ===== Voice param change detect =====
    "LABEL_F5F4B5": "AccPatch_ProcessPartChanges",
    "LABEL_F5F4DD": "AccPatch_PartChanges_NoNew",
    "LABEL_F5F4DF": "AccPatch_PartChanges_MapLookup",
    "LABEL_F5F516": "AccPatch_PartChanges_Update",
    "LABEL_F5F519": "AccPatch_PartChanges_CheckFlag",
    "LABEL_F5F532": "AccPatch_PartChanges_Done",
    "LABEL_F5F533": "AccPatch_ReadRepeatBit",
    "LABEL_F5F552": "AccPatch_SetRepeatBitOn",
    "LABEL_F5F557": "AccPatch_SetRepeatBit_Done",
    "LABEL_F5F558": "AccPatch_PartNumberTable",

    # ===== UpdateAllChains (5 voice channels) =====
    "LABEL_F5F58B": "AccPatch_UpdateChain_Rhythm",
    "LABEL_F5F624": "AccPatch_UpdateChain_Bass",
    "LABEL_F5F6C0": "AccPatch_UpdateChain_Acc1",
    "LABEL_F5F759": "AccPatch_UpdateChain_Acc2",
    "LABEL_F5F7F2": "AccPatch_UpdateChain_Acc3",

    # ===== SyncVoiceParams (5 voice channels) =====
    "LABEL_F5F891": "AccPatch_SyncAllVoiceParams",
    "LABEL_F5F8A4": "AccPatch_SyncVoice_Rhythm",
    "LABEL_F5F8C8": "AccPatch_SyncRhythm_HasBank",
    "LABEL_F5F8FA": "AccPatch_SyncRhythm_Done",
    "LABEL_F5F8FC": "AccPatch_SyncVoice_Bass",
    "LABEL_F5F923": "AccPatch_SyncBass_HasBank",
    "LABEL_F5F955": "AccPatch_SyncBass_Done",
    "LABEL_F5F957": "AccPatch_SyncVoice_Acc1",
    "LABEL_F5F97B": "AccPatch_SyncAcc1_HasBank",
    "LABEL_F5F9AD": "AccPatch_SyncAcc1_Done",
    "LABEL_F5F9AF": "AccPatch_SyncVoice_Acc2",
    "LABEL_F5F9D3": "AccPatch_SyncAcc2_HasBank",
    "LABEL_F5FA05": "AccPatch_SyncAcc2_Done",
    "LABEL_F5FA07": "AccPatch_SyncVoice_Acc3",
    "LABEL_F5FA2B": "AccPatch_SyncAcc3_HasBank",
    "LABEL_F5FA5D": "AccPatch_SyncAcc3_Done",

    # ===== Voice param loading =====
    "LABEL_F5FA7E": "AccPatch_CallParamLookup",
    "LABEL_F5FAA9": "AccPatch_StoreVoiceParams",
    "LABEL_F5FAC8": "AccPatch_ComplexDataBlock",

    # ===== Linked list operations (alt base) =====
    "LABEL_F5FC9F": "AccPatch_FreeAllChains_Alt",
    "LABEL_F5FCCB": "AccPatch_FreeChainLoop_Alt",
    "LABEL_F5FCEC": "AccPatch_FreeChain_Alt_Done",
    "LABEL_F5FD09": "AccPatch_ResolveSlotAddr_Ret",
    "LABEL_F5FD0A": "AccPatch_FillAllSlots_Alt",
    "LABEL_F5FD51": "AccPatch_FillSlot_Alt_Loop",

    # ===== Sequence scanning =====
    "LABEL_F5FD60": "AccPatch_ScanSequenceToEnd",
    "LABEL_F5FD63": "AccPatch_ScanSeq_Loop",
    "LABEL_F5FD76": "AccPatch_ScanSeq_StorePosAndRet",
    "LABEL_F5FD87": "AccPatch_SeqReadByte_Alt",
    "LABEL_F5FD9A": "AccPatch_SeqAdvance_Alt",
    "LABEL_F5FDBD": "AccPatch_SeqAdvance_CheckLimit",
    "LABEL_F5FDC8": "AccPatch_SeqAdvance_ResetBase",
    "LABEL_F5FDCC": "AccPatch_SeqAdvance_Inc",
    "LABEL_F5FDCE": "AccPatch_SeqAdvance_Store",
    "LABEL_F5FDD3": "AccPatch_InitSlotPointer_Alt",

    # ===== Sequence dispatch main loop =====
    "LABEL_F5FDE0": "AccPatch_InitSlotAlt_Valid",
    "LABEL_F5FE07": "AccPatch_SeqDispatch_Entry",
    "LABEL_F5FE2B": "AccPatch_SeqDispatch_Padding",
    "LABEL_F5FE50": "AccPatch_AdvSeq_CheckLimit",
    "LABEL_F5FE5B": "AccPatch_AdvSeq_ResetBase",
    "LABEL_F5FE5F": "AccPatch_AdvSeq_Inc",
    "LABEL_F5FE61": "AccPatch_AdvSeq_Store",
    "LABEL_F5FE66": "AccPatch_AdvSeq_Padding",
    "LABEL_F5FE68": "AccPatch_SeqDispatch_Main",
    "LABEL_F5FE78": "AccPatch_SeqDispatch_CheckEmpty",
    "LABEL_F5FE86": "AccPatch_SeqDispatch_CheckPlaying",
    "LABEL_F5FE93": "AccPatch_SeqDispatch_CheckStarted",

    # ===== Seq dispatch continued =====
    "LABEL_F5FEAF": "AccPatch_SeqDispatch_ProcessFlags",
    "LABEL_F5FEC8": "AccPatch_SeqDispatch_ModeChange",
    "LABEL_F5FECD": "AccPatch_SeqDispatch_RunNotes",
    "LABEL_F5FF10": "AccPatch_SeqDispatch_CheckQueued",
    "LABEL_F5FF24": "AccPatch_SeqDispatch_MiscData",
    "LABEL_F5FF36": "AccPatch_ReadModeFlags",
    "LABEL_F5FF4A": "AccPatch_ReadModeFlags_Active",
    "LABEL_F5FF90": "AccPatch_ReadModeFlags_Check400",
    "LABEL_F5FFC0": "AccPatch_ScanSeq_PaddingByte",
    "LABEL_F5FFC4": "AccPatch_ScanSeq_ReadLoop",
    "LABEL_F5FFD7": "AccPatch_ScanSeq_StorePosition",
    "LABEL_F5FFE8": "AccPatch_ScanSeq_PaddingWord",
    "LABEL_F5FFF2": "AccPatch_InitSeq_ClearLoop",

    # ===== F600xx range =====
    "LABEL_F60009": "AccPatch_InitSeq_LoadTempo",
    "LABEL_F6002B": "AccPatch_InitSeq_AdvLoop",
    "LABEL_F60033": "AccPatch_InitSeq_AdvDone",
    "LABEL_F60034": "AccPatch_InitSeq_Padding",
    "LABEL_F60036": "AccPatch_ResetSeqCounters",
}


def find_all_s_files(root):
    """Find all .s files in the disassembly tree."""
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith('.s'):
                files.append(os.path.join(dirpath, fn))
    return sorted(files)


def rename_in_file(filepath, renames):
    """Perform all renames in a single file using binary I/O. Returns number of replacements."""
    with open(filepath, 'rb') as f:
        data = f.read()

    original = data
    total = 0
    for old_name, new_name in renames.items():
        old_bytes = old_name.encode('ascii')
        new_bytes = new_name.encode('ascii')
        count = data.count(old_bytes)
        if count > 0:
            data = data.replace(old_bytes, new_bytes)
            total += count

    if data != original:
        with open(filepath, 'wb') as f:
            f.write(data)

    return total


def check_collisions(renames, s_files):
    """Verify no new name already exists in the codebase."""
    all_content = b''
    for f in s_files:
        with open(f, 'rb') as fh:
            all_content += fh.read()

    collisions = []
    for old_name, new_name in renames.items():
        new_bytes = new_name.encode('ascii')
        if (new_bytes + b':') in all_content:
            collisions.append(f"  {new_name}: already defined in codebase!")

    return collisions


def main():
    s_files = find_all_s_files(DISASM_ROOT)

    # Exclude note_voice_mapping.s and sequencer_engine.s (other agents working on them)
    s_files = [f for f in s_files if not f.endswith('note_voice_mapping.s')
               and not f.endswith('sequencer_engine.s')]

    print(f"Found {len(s_files)} .s files to process")
    print(f"Renaming {len(RENAMES)} labels")

    # Check for collisions first
    all_s_files = find_all_s_files(DISASM_ROOT)
    collisions = check_collisions(RENAMES, all_s_files)
    if collisions:
        print("\nCOLLISION ERRORS:")
        for c in collisions:
            print(c)
        sys.exit(1)

    # Perform renames
    total_replacements = 0
    files_modified = 0
    for filepath in s_files:
        count = rename_in_file(filepath, RENAMES)
        if count > 0:
            relpath = os.path.relpath(filepath, DISASM_ROOT)
            print(f"  {relpath}: {count} replacements")
            files_modified += 1
            total_replacements += count

    print(f"\nTotal: {total_replacements} replacements across {files_modified} files")
    print(f"Labels renamed: {len(RENAMES)}")


if __name__ == '__main__':
    main()
