#!/usr/bin/env python3
"""
Batch rename LABEL_XXXXXX to semantic names in midi_dispatch_handlers.s
and any cross-file references.

Uses binary I/O to preserve Latin-1 bytes in other files.
"""

import os
import re
import sys
import glob

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Map of old label -> new semantic name
# Only rename where purpose is CONFIDENT from code analysis
RENAMES = {
    # === UIState / Display Update area (lines 537+) ===
    # LABEL_FD0467: continuation of UIState_ProcessDisplayUpdate, handles bitmap rendering
    # Referenced from widget_dispatch.s
    "LABEL_FD0467": "UIState_DisplayUpdate_BitmapHandler",

    # === MIDI CC Dispatch area (lines 589-668) ===
    # These are panel event handlers that check bit flags and dispatch via table
    "LABEL_FD058F": "MidiCC_DispatchStubRet",
    "LABEL_FD0590": "PanelEvt_CheckFlag7_Dispatch_A",
    "LABEL_FD059C": "PanelEvt_CheckFlag7_DoDispatch_A",
    "LABEL_FD05A6": "PanelEvt_CheckFlag7_Ret_A",
    "LABEL_FD05A7": "PanelEvt_CheckFlag7_Dispatch_B",
    "LABEL_FD05B3": "PanelEvt_CheckFlag7_DoDispatch_B",
    "LABEL_FD05BD": "PanelEvt_CheckFlag7_Ret_B",
    "LABEL_FD05BE": "PanelEvt_CheckFlag7_Dispatch_C",
    "LABEL_FD05CA": "PanelEvt_CheckFlag7_DoDispatch_C",
    "LABEL_FD05D4": "PanelEvt_CheckFlag7_Ret_C",
    "LABEL_FD05D5": "PanelEvt_UnconditionalDispatch",
    "LABEL_FD05E0": "PanelEvt_CheckFlag6_Dispatch",
    "LABEL_FD05F0": "PanelEvt_CheckFlag6_Ret",
    "LABEL_FD05F1": "PanelEvt_CheckChanZero_Dispatch",
    "LABEL_FD05FE": "PanelEvt_CheckChanZero_DoDispatch",
    "LABEL_FD0608": "PanelEvt_CheckChanZero_Ret",

    # Panel event dispatch table (lines 665-681)
    "LABEL_FD0609": "PanelEvt_DispatchTable",

    # Panel event handlers in the dispatch table
    "LABEL_FD0649": "PanelEvt_Handler_0_NoteOnParam",
    "LABEL_FD0699": "PanelEvt_Handler_3_ValueCheck",
    "LABEL_FD06D2": "PanelEvt_Handler_5_ValueCheck",
    "LABEL_FD070B": "PanelEvt_Handler_6_NullStub",
    "LABEL_FD070C": "PanelEvt_Handler_7_ValueCheck",
    "LABEL_FD0745": "PanelEvt_Handler_8_ValueCheck",
    "LABEL_FD077E": "PanelEvt_Handler_9_SingleByteParam",
    "LABEL_FD07B9": "PanelEvt_Handler_10_TwoByteParam",
    "LABEL_FD07FA": "PanelEvt_Handler_11_SingleByteParam",
    "LABEL_FD0835": "PanelEvt_Handler_15_ConditionalSet",
    "LABEL_FD16E7": "PanelEvt_Handler_4_DualValueCheck",

    # === Second dispatch group (lines 768+) ===
    "LABEL_FD086B": "PanelEvt_Dispatch6Entry",
    # LABEL_FD0876 is data table following FD086B
    "LABEL_FD0876": "PanelEvt_Dispatch6_TableAndHandlers",
    "LABEL_FD0934": "PanelEvt_Dispatch3Entry_A",
    "LABEL_FD093F": "PanelEvt_Dispatch3_TableAndHandlers_A",
    "LABEL_FD0984": "PanelEvt_Dispatch3Entry_B",
    "LABEL_FD098F": "PanelEvt_Dispatch3_Table_B",
    "LABEL_FD099F": "PanelEvt_Dispatch11Entry",
    "LABEL_FD09AA": "PanelEvt_Dispatch11_TableAndHandlers",

    # === PanelEvent_DispatchByIndex return (line 858) ===
    "LABEL_FD0A21": "PanelEvt_DispatchByIndex_Ret",

    # === MIDI CC channel-indexed dispatch handlers ===
    "LABEL_FD0A22": "MidiCC_ChannelDispatch_TableA",
    "LABEL_FD0A45": "MidiCC_ChannelDispatch_TableA_Ret",
    "LABEL_FD0A46": "MidiCC_ChannelDispatch_Ctrl40",
    "LABEL_FD0A74": "MidiCC_ChannelDispatch_Ctrl41",
    "LABEL_FD0A9B": "MidiCC_ChannelDispatch_Ctrl41_Ret",
    "LABEL_FD0A9C": "MidiCC_ChannelDispatch_SpecialCh1",
    "LABEL_FD0AB8": "MidiCC_ChannelDispatch_SpecialCh1_Ret",
    "LABEL_FD0AB9": "MidiCC_ChannelDispatch_CtrlFlags",
    "LABEL_FD0AF0": "MidiCC_ChannelDispatch_BuildPacket",
    "LABEL_FD0B11": "MidiCC_ChannelDispatch_Ctrl1",
    "LABEL_FD0B41": "MidiCC_ChannelDispatch_Ctrl3",
    "LABEL_FD0B71": "MidiCC_ChannelDispatch_CtrlFlags2",
    "LABEL_FD0BA8": "MidiCC_ChannelDispatch_BuildPacket2",
    "LABEL_FD0BC1": "MidiCC_ChannelDispatch_Ctrl0",
    "LABEL_FD0BF1": "MidiCC_ChannelDispatch_MultiHandler",

    # === MidiChannel_ConfigureController internals ===
    "LABEL_FD0D25": "MidiChanCfg_SetupParams",

    # === File data / validation helpers ===
    "LABEL_FD0D55": "FileData_ProcessWithLookup",
    "LABEL_FD0DA3": "MidiCC_ChannelDispatch_DualSend",
    "LABEL_FD0DC0": "MidiCC_DualSend_SetupParams",

    # === Timestamp check internals ===
    "LABEL_FD0E33": "Periodic_TimestampHelper_Data",
    "LABEL_FD0E49": "Periodic_TimestampCompare",
    "LABEL_FD0E64": "Periodic_TimestampCompare_Done",

    # === CC Mapping data table ===
    "LABEL_FD0E67": "MidiCC_ChannelMappingData",

    # === DataBuf / slot transfer return ===
    "LABEL_FD475F": "DataBuf_TransferSlot_Epilogue",

    # === Voice parameter copy routines ===
    "LABEL_FD4764": "VoiceParam_CopyBitfields_TypeA",
    "LABEL_FD47DB": "VoiceParam_CopyBitfields_TypeA_NoBit5",
    "LABEL_FD47DE": "VoiceParam_CopyBitfields_TypeA_Cont",
    "LABEL_FD47F2": "VoiceParam_CopyBitfields_TypeA_NoHigh",
    "LABEL_FD47F5": "VoiceParam_CopyBitfields_TypeA_Final",
    "LABEL_FD4824": "VoiceParam_CopyBitfields_TypeB",
    "LABEL_FD48EC": "VoiceParam_CopyBitfields_TypeB_NoBit4",
    "LABEL_FD48EF": "VoiceParam_CopyBitfields_TypeB_Cont",
    "LABEL_FD4915": "VoiceParam_CopyBitfields_TypeC",
    "LABEL_FD4941": "VoiceParam_CopyFields_TypeD",
    "LABEL_FD496F": "VoiceParam_CopyBits_TwoFlags",
    "LABEL_FD497C": "VoiceParam_CopyFields_TypeE",
    "LABEL_FD49BD": "VoiceParam_CopyBitfields_LargeBlock",

    # === DSP config loop routines ===
    "LABEL_FD4C0C": "DSPCfg_ConfigureVoiceSlotA",
    "LABEL_FD4CA3": "DSPCfg_VoiceSlotA_ParamLoop",
    "LABEL_FD4CD0": "DSPCfg_VoiceSlotA_RestoreContext",
    "LABEL_FD4CD7": "DSPCfg_ConfigureVoiceSlotB",
    "LABEL_FD4D4D": "DSPCfg_VoiceSlotB_ParamLoop",

    # === SwbtWr (Switchboard Write) parameter block routines ===
    "LABEL_FD8AC8": "SwbtWr_InitAndWrite_CC_B1",
    "LABEL_FD8AD7": "SwbtWr_WriteLoop_CC_B1",
    "LABEL_FD8AF8": "SwbtWr_WriteLoop_CC_B1_Ret",
    "LABEL_FD8AF9": "SwbtWr_InitAndWrite_CC_B2",
    "LABEL_FD8B08": "SwbtWr_WriteLoop_CC_B2",
    "LABEL_FD8B38": "SwbtWr_WriteLoop_CC_B3",
    "LABEL_FD8B59": "SwbtWr_StubRet_A",
    "LABEL_FD8B5A": "SwbtWr_StubRet_B",
    "LABEL_FD8B5B": "SwbtWr_StubRet_C",
    "LABEL_FD8B5C": "SwbtWr_WriteBankSelect",

    # === Memory fill / buffer routines ===
    "LABEL_FD8BA9": "MidiBuf_CalcFillRange",
    "LABEL_FD8BBF": "MidiBuf_FillLoop",

    # === MIDI control dispatch helpers (referenced from widget_dispatch.s) ===
    "LABEL_FD8BCC": "MidiCtrl_ModeSwitch_Data",

    # === Bit test + channel config ===
    "LABEL_FD8BE9": "MidiCtrl_Bit2ToChannel",
    "LABEL_FD8BF2": "MidiCtrl_Bit2ToChannel_Store",
    "LABEL_FD8BFA": "MidiCtrl_SendControlPacket",
    "LABEL_FD8C22": "MidiCtrl_SendPacket_DispatchCall",
    "LABEL_FD8C28": "MidiCtrl_SendPacket_ClearFlag",
    "LABEL_FD8C2F": "MidiCtrl_SendPacket_Ret",

    # === VoiceData sync internals ===
    "LABEL_FD8C35": "VoiceData_SyncLoop",

    # === Sequencer alternative / nibble param handlers ===
    "LABEL_FD91C4": "SeqAlt_NibbleSearch_Ret",
    "LABEL_FD91C5": "SeqAlt_NibbleSearch",
    "LABEL_FD91CD": "SeqAlt_NibbleSearch_CompareLoop",
    "LABEL_FD91D5": "SeqAlt_NibbleSearch_DecLoop",
    "LABEL_FD91DD": "SeqAlt_NibbleSearch_NotFound",

    # === SeqAlt apply descriptor handlers ===
    "LABEL_FD91E1": "SeqAlt_ApplyDescriptor_TypeA",
    "LABEL_FD924C": "SeqAlt_ApplyDescA_NoShift",
    "LABEL_FD925D": "SeqAlt_ApplyDescA_DirectWrite",
    "LABEL_FD9274": "SeqAlt_ApplyDescA_DirectNoShift",
    "LABEL_FD9283": "SeqAlt_ApplyDescA_FinalCall",
    "LABEL_FD928B": "SeqAlt_ApplyDescriptor_TypeB",
    "LABEL_FD92FA": "SeqAlt_ApplyDescB_NoShift",
    "LABEL_FD930B": "SeqAlt_ApplyDescB_DirectWrite",
    "LABEL_FD9322": "SeqAlt_ApplyDescB_DirectNoShift",
    "LABEL_FD9331": "SeqAlt_ApplyDescB_FinalCall",

    # === LABEL_FD9339: large data block ===
    "LABEL_FD9339": "SeqAlt_DescriptorBlock_Data",

    # === MIDI nibble param dispatch (lines 11208+) ===
    "LABEL_FD96BD": "SeqAlt_ApplyDescriptor_TypeC",
    "LABEL_FD96ED": "SeqAlt_ApplyDescC_NoShift",
    "LABEL_FD9706": "SeqAlt_ApplyDescC_Cleanup",
    "LABEL_FD970A": "SeqAlt_ApplyDescriptor_TypeD",
    "LABEL_FD972F": "SeqAlt_ApplyDescD_NoShift",
    "LABEL_FD973F": "SeqAlt_ApplyDescD_Cleanup",
    "LABEL_FD9741": "SeqAlt_StubRet_Pair",
    "LABEL_FD9743": "SeqAlt_ApplyDescriptor_WithAssSwb",
    "LABEL_FD9778": "SeqAlt_AssSwb_NoShift",
    "LABEL_FD97B4": "SeqAlt_AssSwb_ZeroPath",
    "LABEL_FD97C2": "SeqAlt_AssSwb_FinalCall",
    "LABEL_FD97C6": "SeqAlt_AssSwb_Cleanup",
    "LABEL_FD97CC": "SeqAlt_DualNibblePack",
    "LABEL_FD97FA": "SeqAlt_DualNibblePack_Dispatch",

    # === DSP param store with loop (lines 11359+) ===
    "LABEL_FD9802": "DSPParam_StoreWithLoop",
    "LABEL_FD9829": "DSPParam_StoreWithLoop_NoShift",

    # === More voice param handlers ===
    "LABEL_FD9933": "VoiceParam_StoreToBuffer",
    "LABEL_FD9948": "VoiceParam_StoreToBuffer_NoShift",
    "LABEL_FD9959": "VoiceParam_StoreToBuffer_Ret",
    "LABEL_FD995B": "VoiceParam_DirectHardwareWrite",
    "LABEL_FD997F": "VoiceParam_DirectHW_NoShift",
    "LABEL_FD998C": "VoiceParam_DirectHW_Ret",
    "LABEL_FD998E": "VoiceParam_MultiModeDispatch",
    "LABEL_FD99D9": "VoiceParam_MultiMode_Case1",
    "LABEL_FD99E7": "VoiceParam_MultiMode_Case1_NoShift",
    "LABEL_FD99ED": "VoiceParam_MultiMode_Case2",
    "LABEL_FD99FD": "VoiceParam_MultiMode_Case2_NoShift",
    "LABEL_FD9A01": "VoiceParam_MultiMode_SetupHW",
    "LABEL_FD9A05": "VoiceParam_MultiMode_Dispatch",
    "LABEL_FD9A0B": "VoiceParam_MultiMode_StubRet",
    # LABEL_FD9A0C: referenced from widget_dispatch.s
    "LABEL_FD9A0C": "VoiceParam_AssSwb_MultiBlock_Data",

    # === Final section ===
    "LABEL_FD9C84": "VoiceParam_MultiBlock_Ret",
    "LABEL_FD9C85": "VoiceParam_MultiBlock_Epilogue_Data",
    "LABEL_FD9CC8": "VoiceParam_LookupAndEnqueue",

    # === Additional labels from mid-file (lines 10451-10519) ===
    "LABEL_FD8D2B": "SysEx_ParseAndDispatch",  # called from system_handlers.s
    "LABEL_FD8C93": "SwbtWr_ResetAllChannels",  # called from ui_playback_modes.s

    # === SysEx parser internals (lines 10599-10677) ===
    "LABEL_FD8CFD": "SysEx_ResetAndReturn",
    "LABEL_FD8D06": "SysEx_DispatchCalls_Data",
    "LABEL_FD8D62": "SysEx_ParseState1_CheckManufID",
    "LABEL_FD8D74": "SysEx_ParseState1_SetState2",
    "LABEL_FD8D7B": "SysEx_ParseState_Reset",
    "LABEL_FD8D80": "SysEx_ParseState_DispatchByte",
    "LABEL_FD8D86": "SysEx_ParseState2_CheckBit7",
    "LABEL_FD8D96": "SysEx_ParseState_AppendToQueue",
    "LABEL_FD8D9C": "SysEx_ParseState2_EndOfSysEx",
    "LABEL_FD8DB0": "SysEx_ParseAndDispatch_Ret",
    "LABEL_FD8DF0": "SeqData_DispatchLoop",
    "LABEL_FD8DF8": "SeqData_DispatchLoop_Body",
    "LABEL_FD8DF9": "SeqData_DispatchLoop_Check",
    "LABEL_FD8DFD": "SeqData_DispatchLoop_Done",
    "LABEL_FD8E49": "SeqData_FormatOutput",
    "LABEL_FD8E55": "SeqData_FormatOutput_Loop",
    "LABEL_FD8E82": "SeqData_FormatOutput_Dispatch",
    "LABEL_FD8EB6": "SeqData_FormatOutput_CaseA",
    "LABEL_FD8ED5": "SeqData_FormatOutput_CaseB",
    "LABEL_FD8EEC": "SeqData_FormatOutput_CaseC",
    "LABEL_FD8EFD": "SeqData_FormatOutput_Default",
    "LABEL_FD8F2A": "SeqData_FormatOutput_Data",

    # Voice parameter apply (line 11401+)
    "LABEL_FD986C": "VoiceParam_ApplyRangeCheck",
    "LABEL_FD989F": "VoiceParam_ApplyBoundsCheck",
    "LABEL_FD98B5": "VoiceParam_ApplyBoundsValidated",
    "LABEL_FD98D4": "VoiceParam_ApplyNibbleLookup",
    "LABEL_FD98F2": "VoiceParam_ApplyNibble_NoShiftBit",

    # Additional DSP-related from line 4893+
    "LABEL_FD4D4D": "DSPCfg_VoiceSlotB_ParamLoop",
}

def find_all_s_files(repo_root):
    """Find all .s files in maincpu/ directory."""
    result = []
    for dirpath, dirnames, filenames in os.walk(os.path.join(repo_root, "maincpu")):
        for fn in filenames:
            if fn.endswith(".s"):
                result.append(os.path.join(dirpath, fn))
    return sorted(result)

def check_collision(new_name, all_files):
    """Check if new_name already exists as a label definition in any file."""
    target = (new_name + ":").encode("ascii")
    for fpath in all_files:
        data = open(fpath, "rb").read()
        if target in data:
            return fpath
    return None

def main():
    all_files = find_all_s_files(REPO_ROOT)

    # Also check files outside maincpu that reference these labels
    for extra_dir in ["hdae5000", "subcpu", "table_data"]:
        extra_path = os.path.join(REPO_ROOT, extra_dir)
        if os.path.isdir(extra_path):
            for dirpath, dirnames, filenames in os.walk(extra_path):
                for fn in filenames:
                    if fn.endswith(".s"):
                        all_files.append(os.path.join(dirpath, fn))

    # Collision check
    print("Checking for name collisions...")
    collisions = []
    for old_name, new_name in RENAMES.items():
        collision_file = check_collision(new_name, all_files)
        if collision_file:
            collisions.append((new_name, collision_file))

    if collisions:
        print("COLLISIONS FOUND:")
        for name, fpath in collisions:
            print(f"  {name} already exists in {fpath}")
        sys.exit(1)

    print(f"No collisions. Performing {len(RENAMES)} renames...")

    # Build a single combined regex for efficiency
    # Sort by length (longest first) to avoid partial matches
    sorted_names = sorted(RENAMES.keys(), key=lambda x: -len(x))
    combined_pattern = re.compile(
        r'\b(' + '|'.join(re.escape(n) for n in sorted_names) + r')\b'
    )

    def replacer(m):
        return RENAMES[m.group(0)]

    # Count changes per file
    file_changes = {}

    for fpath in all_files:
        data = open(fpath, "rb").read()
        text = data.decode("latin-1")  # preserves all bytes

        new_text, count = combined_pattern.subn(replacer, text)

        if count > 0:
            open(fpath, "wb").write(new_text.encode("latin-1"))
            file_changes[fpath] = count
            print(f"  Updated {os.path.relpath(fpath, REPO_ROOT)} ({count} replacements)")

    print(f"\nDone! {len(RENAMES)} labels renamed across {len(file_changes)} files.")

if __name__ == "__main__":
    main()
