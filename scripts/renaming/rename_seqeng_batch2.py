#!/usr/bin/env python3
"""Batch 2: Rename more LABEL_XXXXXX in sequencer_engine.s to semantic names.

Uses binary I/O (rb/wb) to preserve Latin-1 bytes safely.
"""

import sys
import os
import re
import glob
import subprocess

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_FILE = os.path.join(REPO_DIR, 'maincpu', 'sequencer', 'sequencer_engine.s')

RENAMES = {
    # === SeqPlay_ConfigVoice / MidiTimingSync area ===
    'LABEL_F3966D': 'SeqPlay_ConfigVoice_FindDrum',
    'LABEL_F39688': 'SeqPlay_ConfigVoice_DrumShiftDone',

    # === SeqPlay_ProcessChannelsAndDrum internals ===
    'LABEL_F396C5': 'SeqPlay_ProcessCh_FindDrumVoice',
    'LABEL_F396EA': 'SeqPlay_ProcessCh_FoundDrum',
    'LABEL_F396F8': 'SeqPlay_ProcessCh_DrumShiftDone',
    'LABEL_F3970D': 'SeqPlay_ProcessCh_ValidateChannel',
    'LABEL_F3975F': 'SeqPlay_ProcessCh_SkipToReturn',
    'LABEL_F39761': 'SeqPlay_ProcessCh_ReadData',
    'LABEL_F397B1': 'Seq_ScanForBar_AdvanceAndCheck',

    # === SeqPlay_ProcessTempoVoiceEvent internals ===
    'LABEL_F3981C': 'SeqPlay_TempoVoice_ReadLoop',
    'LABEL_F39860': 'SeqPlay_TempoVoice_CheckB0',
    'LABEL_F398A0': 'SeqPlay_TempoVoice_CheckNoteCount',
    'LABEL_F398B4': 'SeqPlay_TempoVoice_Return',
    'LABEL_F398B8': 'SeqPlay_TempoVoice_ParseCtrl48',
    'LABEL_F3991B': 'SeqPlay_TempoVoice_ParseCtrl48_Got3',
    'LABEL_F39935': 'SeqPlay_TempoVoice_ParseCtrl48_Return',

    # === SeqPlay_CheckChannelContinue / IncrLoopCounter ===
    'LABEL_F39B88': 'SeqPlay_CheckChCont_ShiftDone',

    # === SeqPlay init from demo record (F39BA0 area) ===
    'LABEL_F39BA0': 'SeqPlay_InitFromDemoRecord',
    'LABEL_F39BF8': 'SeqPlay_InitDemo_ClearRepeatBit',
    'LABEL_F39BFC': 'SeqPlay_InitDemo_SyncAndProcess',
    'LABEL_F39C09': 'SeqPlay_InitDemo_LoadVoiceData',
    'LABEL_F39C2E': 'SeqPlay_InitDemo_PartLoop',
    'LABEL_F39C3E': 'SeqPlay_InitDemo_PartShiftDone',
    'LABEL_F39C92': 'SeqPlay_InitDemo_PartLoopNext',

    # === SeqPlay_PreparePlaybackState internals ===
    'LABEL_F3A0D5': 'SeqPlay_Prepare_CheckRepeat',
    'LABEL_F3A0E8': 'SeqPlay_Prepare_LoadVoiceConfig',
    'LABEL_F3A107': 'SeqPlay_Prepare_SetState6',
    'LABEL_F3A10C': 'SeqPlay_Prepare_CheckMode87',

    # === SeqPlay voice processing (F3A125 area) ===
    'LABEL_F3A125': 'SeqPlay_HandlePlaybackEvent',
    'LABEL_F3A133': 'SeqPlay_HandleEvent_AccMode',
    'LABEL_F3A13A': 'SeqPlay_HandleEvent_CheckBit1',
    'LABEL_F3A14D': 'SeqPlay_HandleEvent_StopAndClean',
    'LABEL_F3A19E': 'SeqPlay_HandleEvent_SyncTiming',
    'LABEL_F3A1D0': 'SeqPlay_HandleEvent_ClearAccFlag',
    'LABEL_F3A1D6': 'SeqPlay_HandleEvent_SetAccFlag',
    'LABEL_F3A1F3': 'SeqPlay_HandleEvent_ClearBit2',

    # === SeqPlay_SaveState / ReassignVoices ===
    'LABEL_F39F97': 'SeqPlay_SaveState_CheckBit1',
    'LABEL_F39FAE': 'SeqPlay_SaveState_NoActive',
    'LABEL_F39FB7': 'SeqPlay_SaveState_SetPlayFlags',
    'LABEL_F39FEF': 'SeqPlay_SaveState_CheckVoices',
    'LABEL_F3A005': 'SeqPlay_SaveState_CheckChordVoice',
    'LABEL_F3A022': 'SeqPlay_SaveState_ChordShiftDone',
    'LABEL_F3A03D': 'SeqPlay_SaveState_ChordAssignDirect',
    'LABEL_F3A066': 'SeqPlay_SaveState_BassShiftDone',
    'LABEL_F3A081': 'SeqPlay_SaveState_BassAssignDirect',
    'LABEL_F3A096': 'SeqPlay_ReturnFalse_Return',

    # === Seq_DispatchVoiceConfigEvent internals (continued) ===
    'LABEL_F3A4B6': 'SeqVoice_Dispatch_Check80',
    'LABEL_F3A4C5': 'SeqVoice_Dispatch_Check83',
    'LABEL_F3A4D4': 'SeqVoice_Dispatch_Check84',
    'LABEL_F3A4E8': 'SeqVoice_Dispatch_Check82',
    'LABEL_F3A4F3': 'SeqVoice_Dispatch_CheckD2',
    'LABEL_F3A4F9': 'SeqVoice_Dispatch_CheckD3',
    'LABEL_F3A514': 'SeqVoice_Dispatch_CheckD1',
    'LABEL_F3A51A': 'SeqVoice_Dispatch_CheckD0',
    'LABEL_F3A530': 'SeqVoice_Dispatch_CheckB0',
    'LABEL_F3A536': 'SeqVoice_Dispatch_CheckC0',
    'LABEL_F3A557': 'SeqVoice_Dispatch_Check90',
    'LABEL_F3A562': 'SeqVoice_Dispatch_ErrorUnknown',
    'LABEL_F3A567': 'SeqVoice_Dispatch_ScanNext',

    # === SeqNote score / channel comparison area ===
    'LABEL_F3A56B': 'SeqNote_ReconfigureAfterRepeat',
    'LABEL_F3A570': 'SeqNote_Reconfig_CheckChannels',
    'LABEL_F3A585': 'SeqNote_Reconfig_ProcessChannel',
    'LABEL_F3A5A5': 'SeqNote_Reconfig_DispatchLoop',
    'LABEL_F3A5CD': 'SeqNote_Reconfig_Done',
    'LABEL_F3A5DE': 'SeqNote_Reconfig_MidiSync',
    'LABEL_F3A5E1': 'SeqNote_Reconfig_Return',
    'LABEL_F3A5E6': 'SeqNote_Reconfig_Complete',
    'LABEL_F3A5F9': 'SeqNote_Reconfig_BassSetup',
    'LABEL_F3A607': 'SeqNote_Reconfig_BassDone',
    'LABEL_F3A619': 'SeqNote_Reconfig_ChordSetup',
    'LABEL_F3A627': 'SeqNote_Reconfig_ChordDone',
    'LABEL_F3A635': 'SeqNote_Reconfig_SubSetup',
    'LABEL_F3A63D': 'SeqNote_Reconfig_SubDone',

    # === SeqNote channel tracking (F3A677 area) ===
    'LABEL_F3A677': 'SeqNote_TrackChannelPositions',
    'LABEL_F3A688': 'SeqNote_TrackPos_Done',
    'LABEL_F3A68B': 'SeqNote_TrackPos_Return',
    'LABEL_F3A693': 'SeqNote_TrackPos_CheckBass',
    'LABEL_F3A6A0': 'SeqNote_TrackPos_BassSetup',
    'LABEL_F3A6A5': 'SeqNote_TrackPos_BassDone',
    'LABEL_F3A6B6': 'SeqNote_TrackPos_ChordSetup',
    'LABEL_F3A6BB': 'SeqNote_TrackPos_ChordDone',
    'LABEL_F3A6CE': 'SeqNote_LoadVoicePositions',

    # === SeqNote score display comparison per-channel ===
    'LABEL_F3A6ED': 'SeqNote_LoadPos_Channel1',
    'LABEL_F3A706': 'SeqNote_LoadPos_Channel2',
    'LABEL_F3A71F': 'SeqNote_LoadPos_Channel3',
    'LABEL_F3A738': 'SeqNote_LoadPos_Channel4',
    'LABEL_F3A751': 'SeqNote_LoadPos_Channel5',
    'LABEL_F3A76A': 'SeqNote_LoadPos_Channel6',
    'LABEL_F3A783': 'SeqNote_LoadPos_Channel7',
    'LABEL_F3A79C': 'SeqNote_LoadPos_Channel8',
    'LABEL_F3A7B5': 'SeqNote_LoadPos_Channel9',
    'LABEL_F3A7CE': 'SeqNote_LoadPos_Channel10',
    'LABEL_F3A7E7': 'SeqNote_LoadPos_Channel11',
    'LABEL_F3A800': 'SeqNote_LoadPos_Channel12',
    'LABEL_F3A819': 'SeqNote_LoadPos_Channel13',
    'LABEL_F3A832': 'SeqNote_LoadPos_Channel14',
    'LABEL_F3A84B': 'SeqNote_LoadPos_Channel15',

    # === Part_ReadAndProcessVoiceData internals ===
    'LABEL_F3CB82': 'Part_ReadVoice_HasData',
    'LABEL_F3CB9E': 'Part_ReadVoice_ProcessLoop',
    'LABEL_F3CBC0': 'Part_ReadVoice_CheckCount',
    'LABEL_F3CBC7': 'Part_ReadVoice_StoreResult',
    'LABEL_F3CBC9': 'Part_ReadVoice_Return',
    'LABEL_F3CBCD': 'Part_ReadVoice_CheckEndMarks',
    'LABEL_F3CBD7': 'Part_ReadVoice_RestorePos',

    # === SeqPlay_ReconfigureVoices internals ===
    'LABEL_F3CC19': 'SeqPlay_Reconfig_CheckActive',
    'LABEL_F3CC29': 'SeqPlay_Reconfig_CopyPartBits',
    'LABEL_F3CCFB': 'SeqPlay_Reconfig_ScanParts',
    'LABEL_F3CCFF': 'SeqPlay_Reconfig_PartLoop',
    'LABEL_F3CD0F': 'SeqPlay_Reconfig_PartShiftDone',
    'LABEL_F3CD6F': 'SeqPlay_Reconfig_PartLoopNext',

    # === Seq_ResetAndRestartAccompaniment internals ===
    'LABEL_F3CAB5': 'Seq_ResetRestart_NormalPath',
    'LABEL_F3CABD': 'Seq_ResetRestart_CheckSubsystem',

    # === SeqPlay_StopAndResetAll internals ===
    'LABEL_F3CAD5': 'SeqPlay_StopReset_NotPlaying',
    'LABEL_F3CAF4': 'SeqPlay_StopReset_DispatchAccomp',
    'LABEL_F3CAF8': 'SeqPlay_StopReset_CleanupAll',

    # === SeqPlay start conditions ===
    'LABEL_F3CA4E': 'SeqPlay_EmergencyStopAll',

    # === Voice allocation internals ===
    'LABEL_F3DCC8': 'VoiceAlloc_InitAndFind',
    'LABEL_F3DCD0': 'VoiceAlloc_WriteIndexAndApply',
    'LABEL_F3DCEA': 'VoiceAlloc_Return',
    'LABEL_F3DD1E': 'VoiceAlloc_ComputeAddress',
    'LABEL_F3DD3E': 'VoiceAlloc_CheckNoteType',
    'LABEL_F3DDAF': 'VoiceAlloc_ComputePosition',
    'LABEL_F3DDD6': 'VoiceAlloc_AdjustSubtick',
    'LABEL_F3DE42': 'VoiceAlloc_ValidateCount_Done',
    'LABEL_F3DE54': 'VoiceAlloc_SortLoop_Outer',
    'LABEL_F3DE69': 'VoiceAlloc_SortLoop_Inner',
    'LABEL_F3DE7E': 'VoiceAlloc_SortLoop_InnerNext',
    'LABEL_F3DE82': 'VoiceAlloc_SortLoop_InnerCheck',
    'LABEL_F3DE92': 'VoiceAlloc_SortLoop_OuterCheck',
    'LABEL_F3DEFB': 'VoiceAlloc_CompareLocalIdx',
    'LABEL_F3DF35': 'VoiceAlloc_CopyNoteData_Loop',
    'LABEL_F3DF4F': 'VoiceAlloc_CopyNoteData_Check',
    'LABEL_F3DF77': 'VoiceAlloc_ReturnFF',
    'LABEL_F3DCA6': 'VoiceAlloc_CopyFieldLoop',

    # === Voice / SeqVoice match and assign ===
    'LABEL_F3B8AA': 'SeqVoice_HandleEndMark',
    'LABEL_F3B92B': 'SeqVoice_MatchAssign_ReadSlot',
    'LABEL_F3B969': 'SeqVoice_MatchAssign_ShiftDone',
    'LABEL_F3B9BA': 'SeqVoice_ApplyToChannels_Loop',
    'LABEL_F3BA4E': 'SeqVoice_ApplyChannels_CheckMode',
    'LABEL_F3BA7B': 'SeqVoice_ApplyChannels_ShiftDone',
    'LABEL_F3BA9E': 'SeqVoice_ApplyChannels_FromTable',
    'LABEL_F3BAAF': 'SeqVoice_ApplyChannels_UpdateSlot',
    'LABEL_F3BAC2': 'SeqVoice_ApplyChannels_NextSlot',
    'LABEL_F3BAFA': 'VoiceConfig_CounterIncr_Check',

    # === SeqCh/Voice channel data ===
    'LABEL_F3EE56': 'SeqCh_LoadData_CheckCh14',
    'LABEL_F3EE60': 'SeqCh_LoadData_CheckBass',
    'LABEL_F3EE81': 'SeqCh_LoadData_CheckDrum',
    'LABEL_F3EEA0': 'SeqCh_LoadData_DrumDefault',
    'LABEL_F3EEB0': 'SeqCh_LoadData_ReadVoiceWord',
    'LABEL_F3EEE8': 'SeqCh_LoadData_CheckEndMark',
    'LABEL_F3EF02': 'SeqCh_LoadData_EndMarkWord',
    'LABEL_F3EF06': 'SeqCh_LoadData_CopyToTable',
    'LABEL_F3EF3A': 'SeqCh_LoadData_CopyLoop',
    'LABEL_F3EF49': 'SeqCh_LoadData_NotEndMark',
    'LABEL_F3EF64': 'SeqCh_LoadData_DecrementPos',
    'LABEL_F3EFB5': 'SeqCh_WriteData_CopyLoop',
    'LABEL_F3EFC1': 'SeqCh_WriteData_Return',

    # === Voice init for repeat mode ===
    'LABEL_F3EFC5': 'SeqVoice_InitForRepeatMode',
    'LABEL_F3F041': 'SeqVoice_InitRepeat_CopyLoop',
    'LABEL_F3F05A': 'SeqVoice_InitRepeat_FinalCopy',

    # === Voice part scan ===
    'LABEL_F3F08A': 'SeqVoice_ScanAndAssignParts',
    'LABEL_F3F099': 'SeqVoice_ScanParts_PartLoop',
    'LABEL_F3F0A7': 'SeqVoice_ScanParts_ShiftDone',
    'LABEL_F3F0B4': 'SeqVoice_ScanParts_CheckType',
    'LABEL_F3F0F2': 'SeqVoice_ScanParts_ReadGPIO',
    'LABEL_F3F116': 'SeqVoice_ScanParts_LoopNext',
    'LABEL_F3F125': 'SeqVoice_ScanParts_Continue',
    'LABEL_F3F172': 'SeqVoice_ScanParts_Epilogue',
    'LABEL_F3F175': 'SeqVoice_ScanParts_Return',

    # === Part read/validate internals ===
    'LABEL_F3F180': 'SeqVoice_FindChannelSetup',

    # === BBE1 voice processing ===
    'LABEL_F3BBE1': 'SeqVoice_ProcessAndAssign',

    # === Misc data blocks ===
    'LABEL_F3DF77': 'VoiceAlloc_ReturnFF',  # duplicate removed below
}

# Remove duplicate
if 'LABEL_F3DF77' in RENAMES:
    pass  # already there, just keeping one

def read_file(path):
    with open(path, 'rb') as f:
        return f.read()

def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)

def collect_all_labels(repo_dir):
    labels = set()
    for pattern in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                    'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pattern), recursive=True):
            content = read_file(fpath).decode('latin-1')
            for m in re.finditer(r'^([A-Za-z_]\w+):', content, re.MULTILINE):
                labels.add(m.group(1))
    return labels

def find_all_files_with_label(repo_dir, label):
    result = subprocess.run(
        ['grep', '-rl', '--include=*.s', label, repo_dir],
        capture_output=True, text=True
    )
    return [f.strip() for f in result.stdout.splitlines() if f.strip()]

def analyze(repo_dir, renames):
    print("Collecting all existing labels...")
    existing = collect_all_labels(repo_dir)
    existing -= set(renames.keys())

    print(f"\nChecking {len(renames)} renames for collisions...")
    collisions = 0
    for old, new in sorted(renames.items()):
        if new in existing:
            print(f"  COLLISION: {old} -> {new} (already exists)")
            collisions += 1

    new_names = list(renames.values())
    seen = set()
    for name in new_names:
        if name in seen:
            print(f"  DUPLICATE NEW NAME: {name}")
            collisions += 1
        seen.add(name)

    print(f"\nChecking cross-file references...")
    cross_file_count = 0
    for old in sorted(renames.keys()):
        files = find_all_files_with_label(repo_dir, old)
        other_files = [f for f in files if 'sequencer_engine.s' not in f]
        if other_files:
            cross_file_count += 1
            print(f"  {old} -> {renames[old]}")
            for f in other_files:
                print(f"    referenced in: {f}")

    content = read_file(TARGET_FILE).decode('latin-1')
    missing = 0
    for old in sorted(renames.keys()):
        if old + ':' not in content and old not in content:
            print(f"  MISSING: {old} not found in target file")
            missing += 1

    print(f"\nSummary:")
    print(f"  Total renames: {len(renames)}")
    print(f"  Collisions: {collisions}")
    print(f"  Cross-file references: {cross_file_count}")
    print(f"  Missing labels: {missing}")

    if collisions > 0 or missing > 0:
        print("\nFIX ISSUES BEFORE APPLYING!")
        return False
    return True

def apply_renames(repo_dir, renames):
    files_to_update = set()
    files_to_update.add(TARGET_FILE)
    for old in renames:
        files = find_all_files_with_label(repo_dir, old)
        files_to_update.update(files)
    files_to_update = {f for f in files_to_update if 'note_voice_mapping.s' not in f}

    sorted_labels = sorted(renames.keys(), key=len, reverse=True)
    pattern = re.compile(r'\b(' + '|'.join(re.escape(l) for l in sorted_labels) + r')\b')

    print(f"Updating {len(files_to_update)} files...")
    for fpath in sorted(files_to_update):
        raw = read_file(fpath)
        content = raw.decode('latin-1')
        original = content
        def replacer(m):
            return renames[m.group(1)]
        new_content = pattern.sub(replacer, content)
        if new_content != original:
            count = len(pattern.findall(original))
            write_file(fpath, new_content.encode('latin-1'))
            rel = os.path.relpath(fpath, repo_dir)
            print(f"  Updated {rel}: {count} replacements")

    print(f"\nDone! Applied {len(renames)} label renames.")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 rename_seqeng_batch2.py [analyze|apply]")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == 'analyze':
        ok = analyze(REPO_DIR, RENAMES)
        sys.exit(0 if ok else 1)
    elif cmd == 'apply':
        ok = analyze(REPO_DIR, RENAMES)
        if not ok:
            sys.exit(1)
        print("\nApplying renames...")
        apply_renames(REPO_DIR, RENAMES)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == '__main__':
    main()
