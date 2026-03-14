#!/usr/bin/env python3
"""
Rename LABEL_XXXXXX to semantic names in accompaniment_engine.s and all referencing files.

Uses binary I/O to preserve Latin-1 bytes safely.
"""

import os
import sys
import glob

# Directory containing the disassembly
DISASM_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mapping from LABEL_XXXXXX to semantic names
# Only includes labels where the purpose is confidently determined
RENAMES = {
    # ===== Rhythm_DispatchNote subroutine branch targets =====
    "LABEL_F55BCF": "Rhythm_DispatchNote_SetParam",      # and + call AccPatch_SetVoiceParam
    "LABEL_F55BD8": "Rhythm_DispatchNote_Lookup",         # call AccVoice_LookupWithOffset + AccStyle_ReadVoiceParam
    "LABEL_F55BE2": "Rhythm_DispatchNote_Return",         # ret

    # ===== Tempo/velocity lookup data tables =====
    "LABEL_F55BE3": "AccStyle_TempoLookupData",           # inline byte data (0x3e, 0x1e, ...)
    "LABEL_F55BEE": "AccStyle_LookupTempoAndVelocity",    # push xhl; push xwa; lookup into table at E49B5F
    "LABEL_F55BFD": "AccStyle_LookupTempo_ClampL",        # after clamp of l <= 0xF
    "LABEL_F55C17": "AccStyle_LookupTempo_AddAndStore",   # add xhl + store to 37102/37103
    "LABEL_F55C2F": "AccStyle_TempoMultiplierTable",      # 16 x 2-byte table (0x00,0x14,0x28,...)
    "LABEL_F55C4F": "AccStyle_LookupVelocityTable",       # push xhl; xor xhl; lookup into E4935F/E49E53
    "LABEL_F55C79": "AccStyle_Velocity_ExtendedRange",    # cpdi8 37098, 240; second range
    "LABEL_F55C90": "AccStyle_Velocity_ExtClamp",         # after and l, 0x7F; cp l, 0xB
    "LABEL_F55CAB": "AccStyle_Velocity_HighRange",        # third range (F0+)
    "LABEL_F55CBA": "AccStyle_Velocity_HighClamp",        # after and l, 0xF; cps l, 4
    "LABEL_F55CC5": "AccStyle_Velocity_StoreResult",      # stda8 37102/37103

    # ===== Style change detection routine =====
    "LABEL_F55CD0": "AccStyle_CheckRecordMode",           # cp 13041 with 0xE, compare 36148
    "LABEL_F55CE7": "AccStyle_CheckRecordReturn",         # ret
    "LABEL_F55CE8": "AccStyle_DetectChanges",             # main change detection entry, checks 12931 bits

    # ===== AccStyle_DetectChanges branch targets =====
    "LABEL_F55D05": "AccStyle_DetectChanges_Init",        # stdi8 13026,0; call Rhythm_SendNoteOnMax etc
    "LABEL_F55D97": "AccStyle_DetectChanges_QueueDone",   # after queueing part change events
    "LABEL_F55DAE": "AccStyle_DetectChanges_MarkDirty",   # ordi8 13115, 1
    "LABEL_F55DB3": "AccStyle_DetectChanges_CompareParams",  # check 13043 bit 0
    "LABEL_F55DC5": "AccStyle_Compare_StyleNumber",       # check 13045 vs 13046
    "LABEL_F55DD4": "AccStyle_Compare_StyleNumDone",      # check 13047 vs 13048
    "LABEL_F55DE3": "AccStyle_Compare_Variation",         # check 13049 & 0x7 vs 13050
    "LABEL_F55DF5": "AccStyle_Compare_VariationDone",     # check 13517 bit 7
    "LABEL_F55E05": "AccStyle_Compare_RegistrationFlag",  # check 13109 xor 13042 bit 1
    "LABEL_F55E1B": "AccStyle_Compare_SplitA",            # check 13055 vs 13056
    "LABEL_F55E2A": "AccStyle_Compare_SplitADone",        # check 13057 vs 13058
    "LABEL_F55E39": "AccStyle_Compare_LayerA",            # check 13061 vs 13062
    "LABEL_F55E48": "AccStyle_Compare_LayerADone",        # check 13063 vs 13064
    "LABEL_F55E57": "AccStyle_Compare_TuningState",       # check 13288 xor 13289 bit 0
    "LABEL_F55E69": "AccStyle_Compare_TuningDone",        # call AccTuning_Toggle
    "LABEL_F55E6D": "AccStyle_DetectChanges_Epilogue",    # check 13115 bit 0, call F55E90 if set
    "LABEL_F55E76": "AccStyle_DetectChanges_ClearFlags",  # stdi8 13140/13141/13151, etc
    "LABEL_F55E90": "AccStyle_ApplyChanges",              # calr F55EF0; anddi8 12931,251 etc
    "LABEL_F55ED6": "AccStyle_ApplyChanges_Extended",     # calr LABEL_F5607E
    "LABEL_F55EDB": "AccStyle_ApplyChanges_Finalize",     # calr F56331; store 1075->1112; Rhythm_ProcessAll
    "LABEL_F55EF0": "AccStyle_ResetAllVoiceState",        # reset many DRAM locations to 0
    "LABEL_F55F87": "AccStyle_ApplyStandardStyle",        # read 13061, AccVoice_LookupWithOffset
    "LABEL_F55FC8": "AccStyle_ApplyStd_LoadTuning",       # calr F55FDE; load tuning block
    "LABEL_F55FDD": "AccStyle_ApplyStd_Return",           # ret
    "LABEL_F55FDE": "AccStyle_SetupPartAddresses",        # read xiy+0x3d1 -> 12933; setup all 6 parts

    # ===== Extended style setup =====
    "LABEL_F5607E": "AccStyle_ApplyExtendedStyle",        # ld xiy,E46BF9; look up extended style
    "LABEL_F56091": "AccStyle_ApplyExt_ClampIndex",       # after cp a, 0x1D
    "LABEL_F560C5": "AccStyle_ApplyExt_SkipClamp",        # ld a,l; AccVoice_LookupWithOffset
    "LABEL_F560E5": "AccStyle_ApplyExt_CheckSplit",       # check 13055 bits
    "LABEL_F56124": "AccStyle_ApplyExt_CheckBit0",        # bitda 0, 13055
    "LABEL_F5614C": "AccStyle_ApplyExt_CheckBit1",        # check 13158 vs 1075
    "LABEL_F5616E": "AccStyle_ApplyExt_UseSecondary",     # calr LABEL_F56281
    "LABEL_F56178": "AccStyle_ApplyExt_SelectPart",       # ldda32 xiy, 13011; calr AccVoice_SelectPartOffset
    "LABEL_F5617F": "AccStyle_ApplyExt_UpdateTuning",     # ldda32 xiy, 13011; calr Rhythm_UpdateTuningConfig

    # ===== AccVoice_SelectPartOffset internal =====
    "LABEL_F5619C": "AccVoice_SelectPartOffset_Resolved", # calr LABEL_F56208
    "LABEL_F561B0": "AccVoice_SelectPartOffset_Bound",    # ldda8 a, 12963; load tuning via style
    "LABEL_F561BE": "AccVoice_SelectPartOffset_SetModeW", # calr AccPart_GetVoiceParamOffsetTable
    "LABEL_F561C5": "AccVoice_SelectPartOffset_Apply63",  # ordi8 13100, 63
    "LABEL_F561E1": "AccVoice_SelectPartOffset_Bit1",     # bitda 1, 13055; check mode 2
    "LABEL_F561F8": "AccVoice_SelectPartOffset_Mode3",    # default mode: anddi8 + ordi8 13080
    "LABEL_F56207": "AccVoice_SelectPartOffset_Return",   # ret

    # ===== AccStyle part setup (6 parts) =====
    "LABEL_F56208": "AccStyle_SetupPartAddressesByHL",    # read xiy+0x3d1; iterate HL->parts via ldto_werp
    "LABEL_F56281": "AccStyle_UseSecondarySource",        # read 13157 or 13159
    "LABEL_F5628F": "AccStyle_UseSecondary_Resolve",      # call AccVoice_ResolveParamAddr etc
    "LABEL_F562B6": "AccStyle_UseSecondary_Mode3",        # anddi8 13078/13079; ordi8 13080
    "LABEL_F562C5": "AccStyle_UseSecondary_Return",       # ret

    # ===== Accompaniment part management =====
    "LABEL_F562DA": "AccPart_ResetAndCopyTuning",         # ldda32 xiy, 13006; InitPositionsAndBase+CopyAllParts

    # ===== Ring buffer operations =====
    "LABEL_F56331": "AccBuf_InitKbd1WithMarkers",         # ld xhl,0x2A94; write 0xD0, 0x01, 0x10, 0x01
    "LABEL_F56368": "Rhythm_SendResetMsg",                # send 0xD8/0x10/0x00 via Rhythm_Send3ByteMsg

    # ===== Rhythm_UpdateTuningConfig internals =====
    "LABEL_F563A2": "Rhythm_LookupTuningByStyle",         # Rhythm_LookupStyleIndex + AccVoice_LookupParamIndex
    "LABEL_F563B3": "Rhythm_LookupTuningRange",           # check 13029 < 128; compute range via table
    "LABEL_F563D4": "Rhythm_LookupTuning_DefaultRange",   # ldb a,0x39; ldb w,0x39
    "LABEL_F563D8": "Rhythm_StoreTuningRange",            # stda8 13119/13120

    # ===== Rhythm_LookupStyleIndex internals =====
    "LABEL_F563ED": "Rhythm_LookupStyleIndex_Compute",    # after clamp w < 0x30

    # ===== Data tables =====
    "LABEL_F56413": "AccVoice_ParamIndexData",            # mixed data/code block
    "LABEL_F564A6": "AccPart_VoiceParamDispatchTable",    # .long AccPart_VoiceParamOffsets_BaseA etc

    # ===== AccStyle_ReadParamOffset switch =====
    "LABEL_F565B8": "AccStyle_ReadParamOff_Part2",        # cpdi8 13268, 2
    "LABEL_F565C4": "AccStyle_ReadParamOff_Part4",        # cpdi8 13268, 4
    "LABEL_F565D0": "AccStyle_ReadParamOff_Part8",        # cpdi8 13268, 8
    "LABEL_F565DC": "AccStyle_ReadParamOff_Part16",       # cpdi8 13268, 16
    "LABEL_F565E8": "AccStyle_ReadParamOff_Part32",       # cpdi8 13268, 32

    # ===== Data block =====
    "LABEL_F565EE": "AccStyle_ByteDataBlock",             # .byte block after AccStyle_ReadParamRet
    "LABEL_F56592": "AccPart_LookupBound_ComputeIdx",     # sla w, 1; lookup

    # ===== AccVoice_ComputeParamAddr switch cases =====
    "LABEL_F566CD": "AccVoice_ParamAddr_Range0F_14",      # cp a, 0x14
    "LABEL_F566E0": "AccVoice_ParamAddr_Range14_23",      # cp a, 0x23
    "LABEL_F566F3": "AccVoice_ParamAddr_Range23Plus",     # ldw hl, 0x41C

    # ===== Tuning data =====
    "LABEL_F56729": "AccTuning_ValueTable",               # .byte 0x00..0x23 tuning lookup data

    # ===== Process all 6 voices =====
    "LABEL_F56751": "AccVoice_ProcessAllSixParts",        # calr F5675B; calr AccVoice_ProcessEventLoop; calr F5679C
    "LABEL_F5675B": "AccVoice_SavePartState1",            # save 13268=1, copy part1 state to temp
    "LABEL_F5679C": "AccVoice_RestorePartState1",         # restore part1 state from temp

    # ===== Voice event processing dispatch =====
    "LABEL_F567D5": "AccVoice_EventLoop_Active",          # check 13044 bit 0 -> active processing
    "LABEL_F567E0": "AccVoice_EventLoop_Dispatch",        # select by mask, read event type
    "LABEL_F567FF": "AccVoice_EventLoop_Check81",         # cp a, 0x81
    "LABEL_F56809": "AccVoice_EventLoop_CheckNoteOn",     # cp a, 0x90 through 0xD5
    "LABEL_F56831": "AccVoice_EventLoop_Unknown",         # calr LABEL_F568A8
    "LABEL_F56836": "AccVoice_EventLoop_Idle",            # ret (when bit 0 of 13044 already set)

    # ===== Event type dispatch by channel =====
    "LABEL_F56837": "AccVoice_DispatchByChannel",         # switch 13268 -> AccKbd1/Kbd2/Ch1..Ch4 ProcessNotes
    "LABEL_F56849": "AccVoice_DispatchCh_Kbd2",           # cpdi8 13268, 2
    "LABEL_F5685B": "AccVoice_DispatchCh_Acc1",           # cpdi8 13268, 4
    "LABEL_F5686E": "AccVoice_DispatchCh_Acc2",           # cpdi8 13268, 8
    "LABEL_F56881": "AccVoice_DispatchCh_Acc3",           # cpdi8 13268, 16
    "LABEL_F56894": "AccVoice_DispatchCh_Acc4",           # cpdi8 13268, 32

    # ===== Event processing helpers =====
    "LABEL_F568A8": "AccVoice_AdvanceAndCheckEnd",        # AccBuf_AdvanceNoPage; inc 13037; check 32
    "LABEL_F568C8": "AccVoice_AdvanceAndCheck_Return",    # ret
    "LABEL_F568C9": "AccVoice_HandleNoteOnEvent",         # calr F56A03; lookup table; tempo compare; dispatch
    "LABEL_F568EA": "AccVoice_NoteOn_InRange",            # calr AccMidi_Dispatch
    "LABEL_F568ED": "AccVoice_NoteOn_Return",             # ret
    "LABEL_F568EE": "AccVoice_HandleBarEndEvent",         # check 13044 bit 1; lookup ext param; compare tempo
    "LABEL_F568FC": "AccVoice_BarEnd_Process",            # main processing path
    "LABEL_F5691B": "AccVoice_BarEnd_InRange",            # ordi8 13044, 2; increment bar counter
    "LABEL_F5693B": "AccVoice_BarEnd_NextPage",           # increment page, advance pointer
    "LABEL_F56967": "AccVoice_BarEnd_CheckChord94",       # check 13068 bit 0
    "LABEL_F56971": "AccVoice_BarEnd_CheckChord65",       # check 13065 & 0x3
    "LABEL_F56983": "AccVoice_BarEnd_CheckChord95",       # check 13095 AND 13268
    "LABEL_F5698D": "AccVoice_BarEnd_CheckSync69",        # bitda 0, 13069

    # ===== Buffer advance and style check =====
    "LABEL_F56A03": "AccVoice_AdvanceWithSave",           # load 13272/13270 -> AccBuf_AdvanceWithPageTurn
    "LABEL_F56A25": "AccVoice_HandleMarker83",            # marker 0x83 handler - check channel masks
    "LABEL_F56A3F": "AccVoice_Marker83_Activate",         # calr F56A56
    "LABEL_F56A44": "AccVoice_Marker83_CheckDeact",       # AccPart_CheckAnyActive
    "LABEL_F56A52": "AccVoice_Marker83_NextPart",         # calr F56B23
    "LABEL_F56A55": "AccVoice_Marker83_Return",           # ret
    "LABEL_F56A56": "AccVoice_ActivatePart",              # orddm8 13098/13096; ordi8 13044,1
    "LABEL_F56A7D": "AccVoice_ActivatePart_Return",       # ret
    "LABEL_F56A7E": "AccVoice_ActivateByteData",          # .byte block

    # ===== Part loading/resolution =====
    "LABEL_F56B0F": "AccPart_SelectSourceOrParam",        # check 13029 < 128 -> SelectSource or LoadParamOffsetTable
    "LABEL_F56B1B": "AccPart_SelectSource_Param",         # calr AccPart_LoadParamOffsetTable
    "LABEL_F56B1E": "AccPart_SelectSource_Done",          # ldda8 w, 13268; ret
    "LABEL_F56B23": "AccPart_AdvanceAndResolve",          # advance part index, check limits, resolve style
    "LABEL_F56B46": "AccPart_AdvanceResolve_Done",        # calr AccPart_ResolveStyleAddr; ret
    "LABEL_F56B6B": "AccPart_ResolveStyle_Bound",         # for bound (non-extended) mode
    "LABEL_F56B7E": "AccPart_ResolveStyle_Return",        # ret
    "LABEL_F56B7F": "AccPart_IncrementIndex",             # increment 13269; check for 0x83 wrap
    "LABEL_F56BA9": "AccPart_IncrementIndex_Return",      # ret
    "LABEL_F56BAA": "AccPart_ResolveWithPedal",           # check 13029 < 128 and 13155 bit 0
    "LABEL_F56BC7": "AccPart_ResolveWithPedal_DirB",      # pedal direction B path
    "LABEL_F56BE1": "AccPart_ResolveWithPedal_Bound",     # bound (non-extended) path
    "LABEL_F56BEF": "AccPart_ResolveWithPedal_Return",    # ret

    # ===== Part tuning loading dispatch =====
    "LABEL_F56C02": "AccPart_LoadTuningByChannel",        # switch on 13268 -> AccTuning_LoadAndApplyMaster / F53E*
    "LABEL_F56C14": "AccPart_LoadTuning_Kbd2",            # channel 2
    "LABEL_F56C26": "AccPart_LoadTuning_Acc1",            # channel 4 (acc1)
    "LABEL_F56C38": "AccPart_LoadTuning_Acc2",            # channel 8 (acc2)
    "LABEL_F56C4A": "AccPart_LoadTuning_Acc3",            # channel 16 (acc3)
    "LABEL_F56C5C": "AccPart_LoadTuning_Acc4",            # channel 32 (acc4)

    # ===== AccPart_GetFreeVoiceAddr switch cases =====
    "LABEL_F56C84": "AccPart_FreeAddr_Kbd2",              # cpdi8 13268, 2
    "LABEL_F56C90": "AccPart_FreeAddr_Acc1",              # cpdi8 13268, 4
    "LABEL_F56C9C": "AccPart_FreeAddr_Acc2",              # cpdi8 13268, 8
    "LABEL_F56CA8": "AccPart_FreeAddr_Acc3",              # cpdi8 13268, 16
    "LABEL_F56CB4": "AccPart_FreeAddr_Acc4",              # cpdi8 13268, 32
    "LABEL_F56CCF": "AccPart_FreeAddr_Return",            # ret

    # ===== AccPart_GetParamAddr switch cases =====
    "LABEL_F56CED": "AccPart_ParamAddr_Kbd2",             # add hl, 0x13E
    "LABEL_F56CFF": "AccPart_ParamAddr_Acc1",             # add hl, 0x164
    "LABEL_F56D11": "AccPart_ParamAddr_Acc2",             # add hl, 0x18A
    "LABEL_F56D23": "AccPart_ParamAddr_Acc3",             # add hl, 0x1B0
    "LABEL_F56D35": "AccPart_ParamAddr_Acc4",             # add hl, 0x1D6
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
    # Read all files into memory for collision checking
    all_content = b''
    for f in s_files:
        with open(f, 'rb') as fh:
            all_content += fh.read()

    collisions = []
    for old_name, new_name in renames.items():
        new_bytes = new_name.encode('ascii')
        # Check if the new name already exists (as a label definition)
        if (new_bytes + b':') in all_content:
            collisions.append(f"  {new_name}: already defined in codebase!")
        # Also check if used as a reference (but not the old name)
        # This is less strict - we just want to avoid label definition collisions

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
