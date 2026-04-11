#!/usr/bin/env python3
"""
Rename all LABEL_XXXXXX labels in maincpu/audio/dsp_config_sysex.s to semantic names.
Uses binary I/O to preserve Latin-1 encoding in .s files.
"""

import os
import sys
import glob

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"

# Mapping of old label -> new label
# Grouped by functional area for clarity

RENAME_MAP = {
    # AddswbWr buffer full check
    "LABEL_FDB252": "AddswbWr_BufferFull",

    # PreLswLoad helper: save voice reverb/chorus params to buffer
    "LABEL_FDB4A4": "VoiceParam_SaveReverbChorus",
    "LABEL_FDB4B3": "VoiceParam_SaveReverbChorus_Loop",

    # PostLswLoad helper: restore voice reverb/chorus params from buffer
    "LABEL_FDB4F9": "VoiceParam_RestoreReverbChorus",
    "LABEL_FDB508": "VoiceParam_RestoreReverbChorus_Loop",

    # BitMapOut_RenderDisplay helpers: copy region to snapshot buffer
    "LABEL_FDB5F5": "BitMapOut_CopyRegion_Loop",
    "LABEL_FDB603": "BitMapOut_CopyRegion_Done",

    # BitMapOut_RenderDisplay: conditional restore check
    "LABEL_FDB637": "BitMapOut_SkipRestore",
    "LABEL_FDB63A": "BitMapOut_MergeOutputFields",

    # SeqOut_WriteTimedBytes: MIDI buffer full / error returns
    "LABEL_FDB79C": "SeqOut_WriteTimedBytes_BufferFull",
    # SeqOut_WriteTimedBytes: non-MIDI path (computer interface)
    "LABEL_FDB7A3": "SeqOut_WriteTimedBytes_CompIface",
    # SeqOut_WriteTimedBytes: MAC/PC1 serial write path
    "LABEL_FDB7B3": "SeqOut_WriteTimedBytes_SerialWrite",
    # SeqOut_WriteTimedBytes: PC2 timing check
    "LABEL_FDB7CE": "SeqOut_WriteTimedBytes_PC2Timing",

    # MIDI receive-and-forward single byte dispatcher
    "LABEL_FDB7DC": "MidiSeq_ReceiveAndForward",
    # MidiSeq_ReceiveAndForward: non-MIDI interface branch
    "LABEL_FDB7FC": "MidiSeq_ReceiveAndForward_CompIface",
    # MidiSeq_ReceiveAndForward: MAC/PC1 timing path
    "LABEL_FDB80C": "MidiSeq_ReceiveAndForward_SerialTiming",
    # MidiSeq_ReceiveAndForward: PC2 forward with buffer check
    "LABEL_FDB814": "MidiSeq_ReceiveAndForward_PC2Forward",
    # MidiSeq_ReceiveAndForward: common exit
    "LABEL_FDB832": "MidiSeq_ReceiveAndForward_Exit",

    # MIDI multi-byte send with timing
    "LABEL_FDB838": "MidiSeq_SendMultiByteWithTiming",
    # MidiSeq_SendMultiByteWithTiming: non-MIDI interface
    "LABEL_FDB84E": "MidiSeq_SendMultiByte_CompIface",
    # MidiSeq_SendMultiByte: PC2 mode - count loop init
    "LABEL_FDB861": "MidiSeq_SendMultiByte_PC2CountInit",
    # MidiSeq_SendMultiByte: PC2 byte send loop
    "LABEL_FDB869": "MidiSeq_SendMultiByte_PC2SendLoop",
    # MidiSeq_SendMultiByte: advance to next byte
    "LABEL_FDB896": "MidiSeq_SendMultiByte_PC2NextByte",
    # MidiSeq_SendMultiByte: MAC/PC1 count loop init
    "LABEL_FDB8A5": "MidiSeq_SendMultiByte_SerialCountInit",
    # MidiSeq_SendMultiByte: MAC/PC1 byte send loop
    "LABEL_FDB8AD": "MidiSeq_SendMultiByte_SerialSendLoop",
    # MidiSeq_SendMultiByte: MAC/PC1 advance to next byte
    "LABEL_FDB8CF": "MidiSeq_SendMultiByte_SerialNextByte",
    # MidiSeq_SendMultiByte: common exit with interrupt enable
    "LABEL_FDB8DC": "MidiSeq_SendMultiByte_Exit",

    # SeqBuf_DspSysEx_DataReadLoop inner loop
    "LABEL_FDB8E7": "SeqBuf_DspSysEx_ReadAndForward_Loop",
    # SeqBuf_DspSysEx_DataReadLoop: end of data
    "LABEL_FDB900": "SeqBuf_DspSysEx_ReadAndForward_Done",

    # Stub return (single ret instruction)
    "LABEL_FDB903": "SeqBuf3_EnableTx_Stub",

    # MIDI SysEx message builder / allocate and send
    "LABEL_FDB904": "MidiSysEx_BuildAndSend",
    # MidiSysEx_BuildAndSend: apply channel to header
    "LABEL_FDB96B": "MidiSysEx_ApplyChannel",
    # MidiSysEx_BuildAndSend: exit/free
    "LABEL_FDB996": "MidiSysEx_BuildAndSend_Exit",

    # MIDI_BroadcastControlChange: MIDI out loop per channel
    "LABEL_FDB9B1": "MIDI_BroadcastCC_MidiOutLoop",
    # MIDI_BroadcastControlChange: sendCOMM loop per channel
    "LABEL_FDB9DB": "MIDI_BroadcastCC_CommLoop",

    # Computer interface serial ActiveSensing / flush
    "LABEL_FDBA02": "CompIface_SendActiveSensing",
    # CompIface_SendActiveSensing: PC1/MAC path
    "LABEL_FDBA16": "CompIface_SendActiveSensing_PC1MAC",
    # CompIface_SendActiveSensing: PC2 path
    "LABEL_FDBA28": "CompIface_SendActiveSensing_PC2",

    # MidiOut realtime message data block
    "LABEL_FDBA3A": "MidiOut_RealtimeDispatch_Data",

    # MidiOut serializer: serialize realtime MIDI + SysEx to sendCOMM
    "LABEL_FDBA5D": "MidiOut_SerializeAndSend",
    # MidiOut serializer: check realtime flags - Start
    "LABEL_FDBA9D": "MidiOut_CheckStart",
    # MidiOut serializer: check realtime flags - Continue
    "LABEL_FDBABE": "MidiOut_CheckContinue",
    # MidiOut serializer: check realtime flags - Stop
    "LABEL_FDBADB": "MidiOut_CheckStop",
    # MidiOut serializer: read from SysEx buffer
    "LABEL_FDBAFA": "MidiOut_ReadSysExByte",
    # MidiOut serializer: send accumulated buffer via sendCOMM
    "LABEL_FDBB18": "MidiOut_FlushBuffer",
    # MidiOut serializer: exit (nothing to send)
    "LABEL_FDBB2B": "MidiOut_SerializeAndSend_Exit",

    # MIDI thru disable
    "LABEL_FDBB2D": "MidiThru_Disable",
    # MIDI thru enable
    "LABEL_FDBB32": "MidiThru_Enable",

    # DSPCfg_ApplyParamStructFull: range check fallthrough
    "LABEL_FDD27E": "DSPCfg_ApplyParamStructFull_RangeCheck",

    # DSPCfg_ApplyParamStructFull: type 0x36 clamp result
    "LABEL_FDD43A": "DSPCfg_EventType36_ClampResult",

    # DSPCfg_ApplyParamStructFull event type handlers
    "LABEL_FDD4E9": "DSPCfg_EventType30",
    "LABEL_FDD51A": "DSPCfg_EventType32",
    "LABEL_FDD54B": "DSPCfg_EventType34",
    "LABEL_FDD56C": "DSPCfg_EventType35",
    "LABEL_FDD5FC": "DSPCfg_EventType36",
    "LABEL_FDD61B": "DSPCfg_EventType36_StoreTail",
    "LABEL_FDD6C0": "DSPCfg_EventType40",
    "LABEL_FDD762": "DSPCfg_EventType42",
    "LABEL_FDD82F": "DSPCfg_EventType44",
    "LABEL_FDD8FF": "DSPCfg_EventType46",
    "LABEL_FDD97F": "DSPCfg_EventType10to1B",
    "LABEL_FDD9B8": "DSPCfg_EventType50",
    "LABEL_FDDA60": "DSPCfg_EventType51",

    # DSPCfg_ApplyParamStructFull: return value table
    "LABEL_FDDB19": "DSPCfg_ReturnValueTable",

    # AudioInit_ProcessModeChange: check bit 4 for mode
    "LABEL_FDDE15": "AudioModeChange_ClearVoiceFlags",

    # Audio_CheckSubsystemReady: check bit 4 for mode
    "LABEL_FDDE95": "AudioSubsystem_ClearVoiceFlags",

    # AudioInit select priority and dispatch
    "LABEL_FDDEEF": "AudioInit_SelectAndDispatch",
    # AudioInit check MIDI status and dispatch
    "LABEL_FDDEF7": "AudioInit_CheckMIDIAndDispatch",

    # Audio_InitDispatchReturn: sub-branches
    "LABEL_FDDF12": "AudioDispatch_ClearAccFlags",
    "LABEL_FDDF27": "AudioDispatch_SetAccMode",
    "LABEL_FDDF42": "AudioDispatch_SetTimerBase",
    "LABEL_FDDF47": "AudioDispatch_CheckStereoMode",
    "LABEL_FDDF5C": "AudioDispatch_ClearVoiceFlags",
    "LABEL_FDDF61": "AudioDispatch_SetBusyFlag",

    # AudioVoice_Callback: skip to dispatch
    "LABEL_FDDF8D": "AudioVoice_SkipToDispatch",

    # AudioMode_ResetVoiceState: check bit 4
    "LABEL_FDDFBC": "AudioVoiceReset_ClearFlags",

    # Audio external mode configure entry
    "LABEL_FDE01C": "AudioMode_ConfigureExternal",
    "LABEL_FDE02D": "AudioMode_ConfigExternal_Off",
    "LABEL_FDE03D": "AudioMode_ConfigExternal_CheckBit1",
    "LABEL_FDE047": "AudioMode_ConfigExternal_CheckStereo",
    "LABEL_FDE055": "AudioMode_ConfigExternal_NoStereo",
    "LABEL_FDE068": "AudioMode_ConfigExternal_MergeFlags",
    "LABEL_FDE07B": "AudioMode_ConfigExternal_Apply",

    # UIState_ProcessMidiEvent sub-handlers
    "LABEL_FDE0D0": "UIStateEvt_PartRouting",
    "LABEL_FDE11C": "UIStateEvt_VoiceAssign",
    "LABEL_FDE14B": "UIStateEvt_VoiceAssign_Reset",
    "LABEL_FDE166": "UIStateEvt_VoiceAssign_Notify",
    "LABEL_FDE172": "UIStateEvt_ToneChange",
    "LABEL_FDE1A3": "UIStateEvt_ToneChange_Set",
    "LABEL_FDE1E3": "UIStateEvt_DrumAssign",
    "LABEL_FDE20A": "UIStateEvt_DrumAssign_Set",
    "LABEL_FDE23D": "UIStateEvt_DrumAssign_Notify",
    "LABEL_FDE24A": "UIStateEvt_TransposeUpdate",
    "LABEL_FDE281": "UIStateEvt_TransposeUpdate_Clear",
    "LABEL_FDE2A1": "UIStateEvt_TransposeUpdate_Apply",

    # Widget dispatch bytecode entries (data blocks)
    "LABEL_FDE2A8": "UIStateEvt_ParamEdit_Data",
    "LABEL_FDE514": "UIStateEvt_VolumeMixer_Data",
    "LABEL_FDE67D": "UIStateEvt_EffectSelect_Data",
    "LABEL_FDE7B5": "UIStateEvt_PlayModeGuard_Data",
    "LABEL_FDE7C9": "UIStateEvt_PlayModeGuard_ClearBit",
    "LABEL_FDE7EB": "UIStateEvt_ChannelConfig_Data",
    "LABEL_FDE983": "UIStateEvt_MuteToggle_Data",
}

def main():
    # Verify no duplicate target names
    targets = list(RENAME_MAP.values())
    dupes = [t for t in targets if targets.count(t) > 1]
    if dupes:
        print(f"ERROR: Duplicate target names: {set(dupes)}")
        sys.exit(1)

    # Collect all .s files under maincpu/
    s_files = []
    for root, dirs, files in os.walk(os.path.join(REPO, "maincpu")):
        for f in files:
            if f.endswith(".s"):
                s_files.append(os.path.join(root, f))

    # Check that new names don't already exist in the codebase
    print("Checking for name collisions...")
    all_content = b""
    for fpath in s_files:
        with open(fpath, "rb") as f:
            all_content += f.read()

    for new_name in RENAME_MAP.values():
        if new_name.encode("ascii") in all_content:
            print(f"ERROR: New name '{new_name}' already exists in codebase!")
            sys.exit(1)

    print(f"No collisions found. Renaming {len(RENAME_MAP)} labels across {len(s_files)} files...")

    total_replacements = 0
    files_modified = 0

    for fpath in s_files:
        with open(fpath, "rb") as f:
            data = f.read()

        original = data
        file_count = 0
        for old_name, new_name in RENAME_MAP.items():
            old_bytes = old_name.encode("ascii")
            new_bytes = new_name.encode("ascii")
            count = data.count(old_bytes)
            if count > 0:
                data = data.replace(old_bytes, new_bytes)
                file_count += count

        if data != original:
            with open(fpath, "wb") as f:
                f.write(data)
            rel = os.path.relpath(fpath, REPO)
            print(f"  {rel}: {file_count} replacements")
            total_replacements += file_count
            files_modified += 1

    print(f"\nDone: {total_replacements} replacements across {files_modified} files.")

if __name__ == "__main__":
    main()
