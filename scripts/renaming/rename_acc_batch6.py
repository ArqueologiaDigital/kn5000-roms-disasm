#!/usr/bin/env python3
"""Batch 6: Rename LABEL_XXXXXX labels in accompaniment_engine.s (remaining labels in voice/part/rhythm sections)"""

import os

RENAMES = {
    # Leftover from batch 3 (tone gen voice processing)
    "LABEL_F617F5": "ToneGen_PushAndReadType",
    "LABEL_F61803": "ToneGen_UpdateAndInitPattern",

    # Part selection by type
    "LABEL_F66A06": "Part_SetVoiceType1",
    "LABEL_F66A0D": "Part_SetVoiceType2",
    "LABEL_F66A14": "Part_SetVoiceType4",

    # MIDI channel scan (LABEL_F66A8B)
    "LABEL_F66A8B": "MIDIChan_ScanForFree",
    "LABEL_F66A92": "MIDIChan_ScanLoop",
    "LABEL_F66AA0": "MIDIChan_Found",
    "LABEL_F66AAB": "MIDIChan_StoreResult",

    # Voice slot state update (LABEL_F66AB0)
    "LABEL_F66AB0": "VoiceSlot_UpdateState",
    "LABEL_F66AC5": "VoiceSlot_SetBit2",
    "LABEL_F66AC9": "VoiceSlot_ValidateAndResolve",
    "LABEL_F66ADF": "VoiceSlot_CheckSlot2",
    "LABEL_F66AEB": "VoiceSlot_CheckSlot3",
    "LABEL_F66AF7": "VoiceSlot_CheckSlot4",
    "LABEL_F66B03": "VoiceSlot_CheckSlot5",
    "LABEL_F66B0D": "VoiceSlot_ResolveAddr",
    "LABEL_F66B11": "VoiceSlot_StoreAndReturn",

    # Part type detection
    "LABEL_F66B3E": "PartType_NotPercussion",
    "LABEL_F66B40": "PartType_Return",

    # Voice event size classification
    "LABEL_F66B65": "VoiceEvt_Size6",
    "LABEL_F66B6A": "VoiceEvt_CheckD2",
    "LABEL_F66B74": "VoiceEvt_Size3",
    "LABEL_F66B79": "VoiceEvt_Size1",

    # Voice buffer copy loop
    "LABEL_F66B83": "VoiceBuf_CopyLoop",
    "LABEL_F66B9D": "VoiceBuf_CopyDone",

    # Voice scan table
    "LABEL_F66BDB": "VoiceScan_Size8",
    "LABEL_F66BE7": "VoiceScan_Size1",
    "LABEL_F66BEC": "VoiceScan_Size0",
    "LABEL_F66BF6": "VoiceScan_WriteLoop",
    "LABEL_F66C15": "VoiceScan_NextEntry",
    "LABEL_F66C1C": "VoiceScan_NotFound",
    "LABEL_F66C1E": "VoiceScan_Return",

    # Table address advance (LABEL_F66C20)
    "LABEL_F66C20": "VoiceTable_AdvanceReadPos",
    "LABEL_F66C5E": "VoiceTable_AdvRead_Done",

    # Table address resolve (LABEL_F66C60)
    "LABEL_F66C60": "VoiceTable_ResolveReadAddr",

    # Write position advance (LABEL_F66C7C)
    "LABEL_F66C7C": "VoiceTable_AdvanceWritePos",
    "LABEL_F66C9D": "VoiceTable_AdvWrite_AllocSlot",
    "LABEL_F66CAB": "VoiceTable_AdvWrite_ScanLoop",
    "LABEL_F66CBC": "VoiceTable_AdvWrite_LinkEntry",

    # Rhythm param dispatch table
    "LABEL_F66D5E": "RhythmParam_DispatchTableData",

    # Voice note offset (LABEL_F66DA7)
    "LABEL_F66DA7": "VoiceNote_SubtractOffset",

    # Voice boundary check
    "LABEL_F66DD6": "VoiceBound_CalcOctave",

    # D0/B0 handlers and slot dispatch
    "LABEL_F66DF7": "VoiceParam_D0_Process",
    "LABEL_F66DFF": "VoiceParam_D0_Skip",
    "LABEL_F66E09": "VoiceParam_D0_CheckD4",
    "LABEL_F66E0F": "VoiceParam_D0_CheckD5",
    "LABEL_F66E13": "VoiceParam_D0_StoreD5",
    "LABEL_F66E17": "VoiceParam_B0_Handler",
    "LABEL_F66E29": "VoiceParam_B0_CheckType",
    "LABEL_F66E47": "VoiceParam_B0_Process",
    "LABEL_F66E4B": "__pad_F66E4B",

    # Slot dispatch table (LABEL_F66EC1)
    "LABEL_F66EC1": "VoiceSlot_DispatchByType",
    "LABEL_F66EFD": "VoiceSlot_Dispatch_Type81",
    "LABEL_F66F0B": "VoiceSlot_Dispatch_Type90",
    "LABEL_F66F43": "VoiceSlot_Dispatch_D0Type",
    "LABEL_F66F7C": "VoiceSlot_Dispatch_Return",

    # Pattern index lookup
    "LABEL_F6700C": "PatIdx_Lookup_Return",
    "LABEL_F67013": "__pad_F67013",

    # Voice table management
    "LABEL_F67036": "VoiceTable_InitEntry",
    "LABEL_F6703B": "VoiceTable_InitEntry_Loop",
    "LABEL_F67058": "VoiceTable_InitEntry_Done",
    "LABEL_F67076": "VoiceTable_InitEntry_Store",
    "LABEL_F67082": "VoiceTable_InitEntry_Return",

    # Multi-voice setup
    "LABEL_F67099": "MultiVoice_SetupChannel",
    "LABEL_F670A5": "MultiVoice_Setup_Loop",
    "LABEL_F670BE": "MultiVoice_Setup_WriteParam",
    "LABEL_F670D6": "MultiVoice_Setup_NextChan",
    "LABEL_F670DD": "MultiVoice_Setup_Done",

    # Voice assignment (LABEL_F67128)
    "LABEL_F67128": "VoiceAssign_ProcessRequest",
    "LABEL_F6713F": "VoiceAssign_Process_Loop",
    "LABEL_F6718B": "VoiceAssign_Process_Return",
    "LABEL_F671E6": "VoiceAssign_StoreFinal",
    "LABEL_F671E7": "__pad_F671E7",

    # Registration / preset data
    "LABEL_F67244": "RegPreset_LoadVoiceData",
    "LABEL_F67278": "RegPreset_Load_Loop",
    "LABEL_F67299": "RegPreset_Load_Return",
    "LABEL_F6729B": "__pad_F6729B",

    # Channel assignment table
    "LABEL_F672B1": "ChanAssign_StoreResult",
    "LABEL_F672B2": "__pad_F672B2",
    "LABEL_F672D4": "ChanAssign_Lookup",
    "LABEL_F672D8": "ChanAssign_Lookup_Loop",
    "LABEL_F672E4": "ChanAssign_Lookup_Found",

    # MIDI channel dispatch table
    "LABEL_F67304": "MIDIChan_DispatchTable",
    "LABEL_F6732E": "MIDIChan_Dispatch_Ch1",
    "LABEL_F67339": "MIDIChan_Dispatch_Ch2",
    "LABEL_F67344": "MIDIChan_Dispatch_Ch3",
    "LABEL_F6734F": "MIDIChan_Dispatch_Ch4",
    "LABEL_F6735A": "MIDIChan_Dispatch_Ch5",
    "LABEL_F67365": "MIDIChan_Dispatch_Ch6",
    "LABEL_F67373": "MIDIChan_Dispatch_Ch7",
    "LABEL_F6737E": "MIDIChan_Dispatch_Ch8",
    "LABEL_F67389": "MIDIChan_Dispatch_Ch9",
    "LABEL_F67394": "MIDIChan_Dispatch_Ch10",
    "LABEL_F6739F": "MIDIChan_Dispatch_Ch11",
    "LABEL_F673AA": "MIDIChan_Dispatch_Ch12",
    "LABEL_F673AD": "MIDIChan_DispatchDone",

    # Voice resolve chain
    "LABEL_F673DA": "VoiceResolve_CheckAndStore",
    "LABEL_F67410": "VoiceResolve_Return",
    "LABEL_F67412": "__pad_F67412",
    "LABEL_F67416": "VoiceResolve_InitSearch",
    "LABEL_F67424": "VoiceResolve_SearchDone",
    "LABEL_F6742B": "__pad_F6742B",
    "LABEL_F67448": "VoiceResolve_FindSlot",
    "LABEL_F67455": "VoiceResolve_FindSlot_Return",
    "LABEL_F67459": "__pad_F67459",

    # Part voice parameter update
    "LABEL_F6748C": "PartVoice_UpdateParams",
    "LABEL_F674A9": "PartVoice_Update_Loop",
    "LABEL_F674C5": "PartVoice_Update_Return",
    "LABEL_F674C9": "PartVoice_Update_Done",
    "LABEL_F674CB": "__pad_F674CB",

    # Extended voice processing
    "LABEL_F674F4": "ExtVoice_ProcessList",

    # Style/accompaniment voice setup
    "LABEL_F67649": "AccVoice_SetupStyleSlots",
    "LABEL_F67670": "AccVoice_SetupSlots_Loop",
    "LABEL_F676A3": "AccVoice_SetupSlots_InitEntry",
    "LABEL_F676B2": "AccVoice_SetupSlots_StoreEntry",
    "LABEL_F676C0": "AccVoice_SetupSlots_Return",
    "LABEL_F676C1": "__pad_F676C1",
    "LABEL_F676D3": "AccVoice_SetupSlots_CheckType",
    "LABEL_F676E1": "AccVoice_SetupSlots_Done",
    "LABEL_F676E6": "__pad_F676E6",
    "LABEL_F676F3": "AccVoice_SetupSlots_Write",
    "LABEL_F67702": "AccVoice_SetupSlots_WriteDone",
    "LABEL_F67717": "AccVoice_SetupSlots_DataBlock",

    # Voice slot init/cleanup
    "LABEL_F67CD5": "VoiceSlot_InitFromTable",
    "LABEL_F67CDC": "VoiceSlot_Init_CheckType",
    "LABEL_F67CE3": "VoiceSlot_Init_Process",
    "LABEL_F67D15": "__pad_F67D15",

    # Voice slot resolution
    "LABEL_F67F0C": "VoiceSlot_ResolveFromMap",
    "LABEL_F67F1D": "VoiceSlot_Resolve_StoreMap",
}

def main():
    base = "/home/fsanches/compartilhado/kn5000-roms-disasm"
    target_file = os.path.join(base, "maincpu/sequencer/accompaniment_engine.s")

    with open(target_file, 'rb') as f:
        data = f.read()

    all_s_files = []
    skip_files = {'widget_dispatch.s', 'effects_sequencer_screens.s'}
    for root, dirs, files in os.walk(os.path.join(base, "maincpu")):
        for fn in files:
            if fn.endswith('.s'):
                all_s_files.append(os.path.join(root, fn))

    count = 0
    files_modified = set()

    for old_label, new_label in RENAMES.items():
        old_bytes = old_label.encode('ascii')
        new_bytes = new_label.encode('ascii')

        if old_bytes in data:
            data = data.replace(old_bytes, new_bytes)
            count += 1
            files_modified.add(target_file)

        for sf in all_s_files:
            if sf == target_file or os.path.basename(sf) in skip_files:
                continue
            with open(sf, 'rb') as f:
                sdata = f.read()
            if old_bytes in sdata:
                sdata = sdata.replace(old_bytes, new_bytes)
                with open(sf, 'wb') as f:
                    f.write(sdata)
                files_modified.add(sf)
                print(f"  Cross-ref: {old_label} -> {new_label} in {os.path.basename(sf)}")

    with open(target_file, 'wb') as f:
        f.write(data)

    print(f"\nRenamed {count} labels in {len(files_modified)} files")

if __name__ == "__main__":
    main()
