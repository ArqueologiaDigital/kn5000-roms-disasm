#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in system_handlers.s - Batch 1 (~80 labels)"""

import os
import sys
import tempfile
import glob

# Mapping of old label -> new label (Batch 1: NMI, boot, VGA, timer, UI state machine, sequencer)
RENAMES = {
    # NMI handler
    "LABEL_EF08BE": "NMI_SetPowerOffCode_A5A5",
    "LABEL_EF08C5": "NMI_ClearGuardAndHalt",
    "LABEL_EF08D2": "NMI_HaltLoop",
    "LABEL_EF08D4": "NMI_StorePayloadChecksums_Entry",  # duplicate label on same line
    "LABEL_EF0914": "NMI_CopyPayloadToSRAM",

    # SubCPU payload verify (already named, but have dual labels)
    "LABEL_EF092B": "SubCPU_Payload_Verify_Entry",
    "LABEL_EF095E": "SubCPU_Payload_Verify_Fail_Entry",
    "LABEL_EF0979": "SubCPU_Payload_GetErrorFlag_Entry",
    "LABEL_EF0988": "Sys_CheckPowerStableFlag",

    # VGA routines
    "LABEL_EF0994": "Vga_WritePort_DelayLoop",
    "LABEL_EF0AFC": "Vga_BackupPlane3ToBuffer",
    "LABEL_EF0B21": "Vga_RestorePlane3FromBuffer",

    # Boot_InitWorkRAM internal labels
    "LABEL_EF0B6E": "Boot_InitWorkRAM_ZeroBlock1_Loop",
    "LABEL_EF0B7B": "Boot_InitWorkRAM_ZeroBlock1_Done",
    "LABEL_EF0BA3": "Boot_InitWorkRAM_ZeroBlock2_Loop",
    "LABEL_EF0BB0": "Boot_InitWorkRAM_ROMCopy1_Start",
    "LABEL_EF0BCD": "Boot_InitWorkRAM_ROMCopy1_Loop",
    "LABEL_EF0BD2": "Boot_InitWorkRAM_ROMCopy2_Start",
    "LABEL_EF0BEF": "Boot_InitWorkRAM_ROMCopy2_Loop",
    "LABEL_EF0BF4": "Boot_InitWorkRAM_Done",
    "LABEL_EF0BF8": "Boot_InitWorkRAM_Trailer",

    # INTT1 handler / UI state machine
    "LABEL_EF0C2C": "INTT1_NoOverflow",
    "LABEL_EF0C3E": "INTT1_StoreCounters",
    "LABEL_EF0C52": "INTT1_CheckScanFlag",
    "LABEL_EF0C76": "INTT1_CheckTickCount",
    "LABEL_EF0C83": "INTT1_CheckMidiSync",
    "LABEL_EF0CA5": "INTT1_CheckTickOverflow",
    "LABEL_EF0CC4": "INTT1_CheckAltSeqOverflow",
    "LABEL_EF0CD3": "INTT1_CheckMidiSyncGate",
    "LABEL_EF0CE7": "INTT1_SkipToDispatch",
    "LABEL_EF0CE9": "INTT1_UpdateAlternateTimers",
    "LABEL_EF0CF4": "INTT1_CheckAltSeqTimer",
    "LABEL_EF0D0F": "INTT1_CheckMetroTimer",
    "LABEL_EF0D35": "UIStateMachine_CheckPending",
    "LABEL_EF0D3D": "UIStateMachine_ClearBit3",

    # UI state machine process
    "LABEL_EF0D89": "UIState1_SkipToExit",
    "LABEL_EF0D8C": "UIState1_AlternateExit",

    # Seq_TickWrapper internals
    "LABEL_EF139B": "SeqTick_CheckActive",
    "LABEL_EF13A5": "SeqTick_Dispatch",
    "LABEL_EF13AE": "SeqTick_Return",

    # Seq_ProcessMidiEvent internals
    "LABEL_EF13DC": "MidiEvt_ScanLoop",
    "LABEL_EF13F0": "MidiEvt_FoundStatusByte",
    "LABEL_EF141B": "MidiEvt_SetNoteOnFlag",
    "LABEL_EF1455": "MidiEvt_SetDataFlag",
    "LABEL_EF145A": "MidiEvt_ClearDataFlag",
    "LABEL_EF145D": "MidiEvt_CheckProcessMode",
    "LABEL_EF1465": "MidiEvt_AdvancePointer",
    "LABEL_EF1474": "MidiEvt_ProcessNoteOn",
    "LABEL_EF148F": "MidiEvt_UpdateReadPosition",

    # Seq event processing
    "LABEL_EF14B0": "SeqEvtTick_ProcessTimers",
    "LABEL_EF14D7": "SeqEvtTick_Return",
    "LABEL_EF14F2": "SwbtWr_ReinitBothBanks_Return",
    "LABEL_EF1509": "SwbtWr_ReinitOutputBank_Return",
    "LABEL_EF1524": "RhythmBuf_ProcessLoop_Done",

    # AudioMix data block
    "LABEL_EF185A": "AudioMix_BytecodeData",

    # Checksum routine
    "LABEL_EF18ED": "Checksum_AccumulateLoop",

    # Data tables
    "LABEL_EF18F7": "TaskSched_ScreenGroupTable",
    "LABEL_EF1949": "TaskSched_ScreenGroupTable_End",
    "LABEL_EF194B": "INTT3_PriorityAdjust",
    "LABEL_EF1958": "INTT3_PriorityAdjust_Active",

    # Show_ScreenGroup entry
    "LABEL_EF1B9C": "Show_ScreenGroup_Entry",

    # TempoRingBuf_CheckEmpty
    "LABEL_EF24FE": "TempoRingBuf_CheckEmpty_Return",

    # SeqMain_WriteBytes loop
    "LABEL_EF2795": "SeqMain_WriteBytes_Loop",

    # Seq_CheckSongEnd
    "LABEL_EF27B6": "Seq_CheckSongEnd_Return",

    # SeqBuf helpers
    "LABEL_EF27E6": "SeqMain_ReadAlternate",
}

def do_renames(renames):
    base = "/home/fsanches/compartilhado/kn5000-roms-disasm"
    # Find all .s files in maincpu/
    s_files = []
    for root, dirs, files in os.walk(os.path.join(base, "maincpu")):
        for f in files:
            if f.endswith(".s"):
                s_files.append(os.path.join(root, f))
    s_files.sort()

    for fpath in s_files:
        with open(fpath, 'rb') as fh:
            data = fh.read()

        original = data
        for old, new in renames.items():
            data = data.replace(old.encode('ascii'), new.encode('ascii'))

        if data != original:
            # Atomic write
            dirname = os.path.dirname(fpath)
            fd, tmp = tempfile.mkstemp(dir=dirname, suffix='.tmp')
            try:
                os.write(fd, data)
                os.fsync(fd)
                os.close(fd)
                os.rename(tmp, fpath)
                print(f"  Updated: {fpath}")
            except:
                os.close(fd)
                os.unlink(tmp)
                raise

if __name__ == "__main__":
    print(f"Renaming {len(RENAMES)} labels (Batch 1)...")
    do_renames(RENAMES)
    print("Done.")
