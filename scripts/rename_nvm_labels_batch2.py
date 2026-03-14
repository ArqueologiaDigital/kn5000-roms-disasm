#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in note_voice_mapping.s - batch 2.

Uses binary I/O to preserve Latin-1 bytes.

Usage:
    python3 scripts/rename_nvm_labels_batch2.py analyze
    python3 scripts/rename_nvm_labels_batch2.py apply
"""

import sys
import os
import re
import glob

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_FILE = os.path.join(REPO, 'maincpu', 'audio', 'note_voice_mapping.s')


def read_file(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)


RENAMES = {
    # =========================================================================
    # AccNoteOn continued (FE08B5-FE0992)
    # =========================================================================
    'LABEL_FE08B5': 'AccNoteOn_MergeLayer3',
    'LABEL_FE08EE': 'AccNoteOn_CheckSpecialChannel',
    'LABEL_FE0923': 'AccNoteOn_SpecialMergeAndAdd',
    'LABEL_FE094D': 'AccNoteOn_SpecialDirectAdd',
    'LABEL_FE095E': 'AccNoteOn_CheckLayer3Only',
    'LABEL_FE0992': 'AccNoteOn_UpdateByChannelType',

    # =========================================================================
    # AccNoteOn channel dispatch / final loop (FE09C4-FE0A9E)
    # =========================================================================
    'LABEL_FE0A33': 'AccNoteOn_ChannelLoop_Body',
    'LABEL_FE0A43': 'AccNoteOn_ChannelLoop_Remap98',
    'LABEL_FE0A93': 'AccNoteOn_ChannelLoop_Next',
    'LABEL_FE0A9E': 'AccNoteOn_ChannelLoop_Check',

    # =========================================================================
    # Voice_InitTablePair internal (FE1285-FE12AE)
    # =========================================================================
    'LABEL_FE1285': 'VoiceTablePair_PartLoop',
    'LABEL_FE12AE': 'VoiceTablePair_Return',

    # =========================================================================
    # VoiceEvent handler table entries (FE12B8-FE1310)
    # =========================================================================
    'LABEL_FE12B8': 'VoiceEvent_AllocAllLayers',
    'LABEL_FE12E8': 'VoiceEvent_AllocTwoLayers',
    'LABEL_FE1310': 'VoiceEvent_TableSeparator',

    # =========================================================================
    # VoiceEvent_HandlerTable / dispatch (FE138C-FE143D)
    # =========================================================================
    'LABEL_FE138C': 'VoiceEvtHandler_Type1',
    'LABEL_FE139B': 'VoiceEvtHandler_Type2',
    'LABEL_FE13AA': 'VoiceEvtHandler_Type3',
    'LABEL_FE13B8': 'VoiceEvtHandler_Type4',
    'LABEL_FE13C6': 'VoiceEvtHandler_Type5',
    'LABEL_FE13D4': 'VoiceEvtHandler_Type6',
    'LABEL_FE13E2': 'VoiceEvtHandler_Type7',
    'LABEL_FE13F0': 'VoiceEvtHandler_Type8',
    'LABEL_FE13FE': 'VoiceEvtHandler_Type9',
    'LABEL_FE140C': 'VoiceEvtHandler_Type10',
    'LABEL_FE141A': 'VoiceEvtHandler_Type11',
    'LABEL_FE1428': 'VoiceEvtHandler_Type12',
    'LABEL_FE143D': 'VoiceEvtHandler_Done',

    # =========================================================================
    # Voice claim / MIDI config (FE14AD-FE18E1)
    # =========================================================================
    'LABEL_FE14AD': 'VoiceClaim_Slot0_MarkLoop',
    'LABEL_FE14C3': 'VoiceClaim_Slot0_MarkCheck',
    'LABEL_FE14F8': 'VoiceClaim_Slot0_Alt',
    'LABEL_FE1551': 'VoiceClaim_Slot0_Alt_MarkLoop',
    'LABEL_FE1567': 'VoiceClaim_Slot0_Alt_MarkCheck',

    # =========================================================================
    # VoiceClaim_Extended (FE1781-FE18E1) - repeated slot pattern
    # =========================================================================
    'LABEL_FE1781': 'VoiceClaimExt_Slot1_MarkLoop',
    'LABEL_FE1797': 'VoiceClaimExt_Slot1_MarkCheck',
    'LABEL_FE17E4': 'VoiceClaimExt_Slot2_MarkLoop',
    'LABEL_FE17FA': 'VoiceClaimExt_Slot2_MarkCheck',
    'LABEL_FE1817': 'VoiceClaimExt_Slot2_SetParam',
    'LABEL_FE1847': 'VoiceClaimExt_Slot3_MarkLoop',
    'LABEL_FE185D': 'VoiceClaimExt_Slot3_MarkCheck',
    'LABEL_FE187A': 'VoiceClaimExt_Slot3_SetParam',
    'LABEL_FE18AB': 'VoiceClaimExt_Slot6_MarkLoop',
    'LABEL_FE18C1': 'VoiceClaimExt_Slot6_MarkCheck',

    # =========================================================================
    # Extended voice claim (FE1934-FE1A11+) more slots
    # =========================================================================
    'LABEL_FE1934': 'VoiceClaimExt2_Slot1_MarkLoop',
    'LABEL_FE194A': 'VoiceClaimExt2_Slot1_MarkCheck',
    'LABEL_FE1997': 'VoiceClaimExt2_Slot2_MarkLoop',
    'LABEL_FE19AD': 'VoiceClaimExt2_Slot2_MarkCheck',
    'LABEL_FE19CA': 'VoiceClaimExt2_Slot2_SetParam',
    'LABEL_FE19FB': 'VoiceClaimExt2_Slot3_MarkLoop',
    'LABEL_FE1A11': 'VoiceClaimExt2_Slot3_MarkCheck',

    # =========================================================================
    # SndPart_SetParam dispatch targets (FEB179-FEB2B0)
    # =========================================================================
    'LABEL_FEB179': 'SndPart_SetProgramMSB',
    'LABEL_FEB18B': 'SndPart_SetModWheel',
    'LABEL_FEB19A': 'SndPart_SetVolume',
    'LABEL_FEB1B9': 'SndPart_SetPan',
    'LABEL_FEB1C9': 'SndPart_SetExpression',
    'LABEL_FEB1D9': 'SndPart_SetDamperPedal',
    'LABEL_FEB1F9': 'SndPart_SetPitchBendRange',
    'LABEL_FEB209': 'SndPart_SetReverbSend',
    'LABEL_FEB219': 'SndPart_SetChorusSend',
    'LABEL_FEB229': 'SndPart_SetDelaySend',
    'LABEL_FEB23B': 'SndPart_SetBankMSB',
    'LABEL_FEB24A': 'SndPart_SetBankLSB',
    'LABEL_FEB259': 'SndPart_SetBankSelect',
    'LABEL_FEB268': 'SndPart_SetRPN',
    'LABEL_FEB272': 'SndPart_SetFineTune',
    'LABEL_FEB28C': 'SndPart_SetCoarseTune',
    'LABEL_FEB2A6': 'SndPart_SetPitchBendSens',
    'LABEL_FEB2B0': 'SndPart_SetAllSoundOff',

    # =========================================================================
    # MIDI_BroadcastPitchReset internal (FEBE8B-FEBEE7)
    # =========================================================================
    'LABEL_FEBE8B': 'PitchReset_ShiftAndOr',
    'LABEL_FEBE9A': 'PitchReset_ChannelLoop',
    'LABEL_FEBEB6': 'PitchReset_CheckExtChannels',
    'LABEL_FEBECB': 'PitchReset_ExtChannelLoop',
    'LABEL_FEBEE7': 'PitchReset_Flush',

    # =========================================================================
    # MIDI_SendCmdPacket internal (FEBF4C-FEBF60)
    # =========================================================================
    'LABEL_FEBF4C': 'SendCmdPacket_Loop',
    # REMOVED: LABEL_BEBF60 was a typo (should be FEBF60, already mapped above)
    'LABEL_FEBF60': 'SendCmdPacket_CheckCount',

    # =========================================================================
    # MIDI_SendAllSoundOff internal (FEBF05-FEBF17)
    # =========================================================================
    'LABEL_FEBF05': 'SendAllSoundOff_Loop',
    'LABEL_FEBF17': 'SendAllSoundOff_Flush',

    # =========================================================================
    # MIDI send utility (FEBDFB-FEBE33)
    # =========================================================================
    'LABEL_FEBDFB': 'MIDI_SendPartVolumes_Loop',
    'LABEL_FEBE0E': 'MIDI_SendPartVol_LookupFallback',
    'LABEL_FEBE19': 'MIDI_SendPartVol_StoreAndSend',
    'LABEL_FEBE33': 'MIDI_SendPartVol_ExtraParts',
    'LABEL_FEBE46': 'MIDI_SendPartVol_ExtraLookup',
    'LABEL_FEBE52': 'MIDI_SendPartVol_ExtraSend',

    # =========================================================================
    # NoteDisplay internal (FE9DFA-FEA013)
    # =========================================================================
    'LABEL_FE9DFA': 'NoteDisplay_LookupEntry',
    'LABEL_FE9E2F': 'NoteDisplay_SetBounds',
    'LABEL_FE9E36': 'NoteDisplay_ScanLoop',
    'LABEL_FE9E63': 'NoteDisplay_FoundEntry',
    'LABEL_FE9E84': 'NoteDisplay_NotFound',
    'LABEL_FE9E8A': 'NoteDisplay_StoreBoundsReturn',
    'LABEL_FE9E91': 'NoteDisplay_AlternateLookup',
    'LABEL_FE9EF8': 'NoteDisplay_AltReturn',
    'LABEL_FE9F15': 'NoteDisplay_ClearReturn',
    'LABEL_FE9F6F': 'NoteDisplay_LookupFromCurrent',
    'LABEL_FE9F80': 'NoteDisplay_LookupFromTable',
    'LABEL_FE9FA6': 'NoteDisplay_StoreNoCurrent',
    'LABEL_FE9FB1': 'NoteDisplay_SetUpdateFlags',
    'LABEL_FE9FD1': 'NoteDisplay_SameNote',
    'LABEL_FE9FE7': 'NoteDisplay_ClearBoth',
    'LABEL_FE9FF3': 'NoteDisplay_SetOverlayFlags',

    # =========================================================================
    # Ring buffer operations (FEE1A9-FEE2C5)
    # =========================================================================
    'LABEL_FEE1A9': 'SysexRingBuf_Init',
    'LABEL_FEE1BF': 'SysexRingBuf_ClearLoop',
    'LABEL_FEE1CF': 'SysexRingBuf_ClearCheck',
    'LABEL_FEE1D8': 'SysexRingBuf_WriteByte',
    'LABEL_FEE1E5': 'SysexRingBuf_StoreAndAdvance',
    'LABEL_FEE207': 'SysexRingBuf_IncrementWrite',
    'LABEL_FEE20B': 'SysexRingBuf_WriteSuccess',
    'LABEL_FEE20D': 'SysexRingBuf_WriteReturn',
    'LABEL_FEE20E': 'SysexRingBuf_ReadByte',
    'LABEL_FEE21D': 'SysexRingBuf_ReadAndAdvance',
    'LABEL_FEE241': 'SysexRingBuf_IncrementRead',
    'LABEL_FEE245': 'SysexRingBuf_ReadReturn',
    'LABEL_FEE246': 'SysexRingBuf_GetFreeSpace',
    'LABEL_FEE24E': 'SysexRingBuf_ReadBytes',
    'LABEL_FEE260': 'SysexRingBuf_ReadBytesLoop',
    'LABEL_FEE26E': 'SysexRingBuf_ReadBytesStore',
    'LABEL_FEE27F': 'SysexRingBuf_ReadBytesOK',
    'LABEL_FEE281': 'SysexRingBuf_ReadBytesReturn',
    'LABEL_FEE295': 'SysexRingBuf_WriteNonZero',
    'LABEL_FEE2A9': 'SysexRingBuf_WriteBytesLoop',
    'LABEL_FEE2C3': 'SysexRingBuf_WriteBytesOK',
    'LABEL_FEE2C5': 'SysexRingBuf_WriteBytesReturn',

    # MIDI ring buffer (FEE2C9-FEE32D)
    'LABEL_FEE2C9': 'MidiRingBuf_Init',
    'LABEL_FEE2DF': 'MidiRingBuf_ClearLoop',
    'LABEL_FEE2EF': 'MidiRingBuf_ClearCheck',
    'LABEL_FEE2F8': 'MidiRingBuf_WriteByte',
    'LABEL_FEE305': 'MidiRingBuf_StoreAndAdvance',

    # =========================================================================
    # SeqFile parsing (FEC67E-FEC82D)
    # =========================================================================
    'LABEL_FEC67E': 'SeqFile_SkipHeaderBytes_Loop',
    'LABEL_FEC68C': 'SeqFile_SkipHeaderBytes_Next',
    'LABEL_FEC69A': 'SeqFile_ReadMagicInit',
    'LABEL_FEC6AA': 'SeqFile_ReadMagicByte_Loop',
    'LABEL_FEC6BA': 'SeqFile_CheckMagicByte',
    'LABEL_FEC6DA': 'SeqFile_ValidateMagicCount',
    'LABEL_FEC6E9': 'SeqFile_SkipPadding_Init',
    'LABEL_FEC6F9': 'SeqFile_SkipPadding_Loop',
    'LABEL_FEC707': 'SeqFile_SkipPadding_Next',
    'LABEL_FEC715': 'SeqFile_ReadFormatByte',
    'LABEL_FEC725': 'SeqFile_ValidateFormat',
    'LABEL_FEC72F': 'SeqFile_ReadTempoByte1',
    'LABEL_FEC73F': 'SeqFile_StoreTempoByte1',
    'LABEL_FEC75A': 'SeqFile_ReadTempoByte2',
    'LABEL_FEC772': 'SeqFile_ReadDivisionByte1',
    'LABEL_FEC78D': 'SeqFile_StoreDivisionByte1',
    'LABEL_FEC7A5': 'SeqFile_ReadTrackMagic_Loop',
    'LABEL_FEC7B4': 'SeqFile_CheckTrackMagic',
    'LABEL_FEC7D4': 'SeqFile_ValidateTrackMagic',
    'LABEL_FEC7E2': 'SeqFile_SkipTrackPad_Init',
    'LABEL_FEC7F2': 'SeqFile_SkipTrackPad_Loop',
    'LABEL_FEC7FF': 'SeqFile_SkipTrackPad_Next',
    'LABEL_FEC80D': 'SeqFile_ReadTrackLength',
    'LABEL_FEC82D': 'SeqFile_AccumulateLength',

    # =========================================================================
    # Seq play / tone gen file I/O (FED934-FEDA34)
    # =========================================================================
    'LABEL_FED934': 'ToneGen_CheckSpecialChannel',
    'LABEL_FED962': 'ToneGen_SendPacketDirect',
    'LABEL_FED969': 'ToneGen_CheckVelocityRepeat',
    'LABEL_FED975': 'ToneGen_CheckZeroVelocity',
    'LABEL_FED97B': 'ToneGen_ResendPacket',
    'LABEL_FED984': 'ToneGen_SendAndReturn',
    'LABEL_FED990': 'ToneGen_ReadFileRecord',
    'LABEL_FED9A5': 'ToneGen_CheckRecordType',
    'LABEL_FED9BA': 'ToneGen_ReadExtendedDelta',
    'LABEL_FED9CD': 'ToneGen_ShiftAndAccumulate',
    'LABEL_FED9DA': 'ToneGen_SignExtendDelta',
    'LABEL_FED9DE': 'ToneGen_AccumulateDelta',
    'LABEL_FED9E6': 'ToneGen_ResetAndInitBanks',
    'LABEL_FEDA34': 'MidiRealtime_ReadAndProcess',
    'LABEL_FEDA4B': 'MidiRealtime_DispatchStatus',
    'LABEL_FEDA61': 'MidiRealtime_SysExStart',
    'LABEL_FEDA6B': 'MidiRealtime_SysExReadLoop',
    'LABEL_FEDA7A': 'MidiRealtime_SysExCheckEnd',
    'LABEL_FEDA8C': 'MidiRealtime_SysExCheckF7',
    'LABEL_FEDAA4': 'MidiRealtime_SysExOverflow',
    'LABEL_FEDAEC': 'MidiRealtime_NonSysExHandler',
    'LABEL_FEDB4E': 'MidiRealtime_StopAndReturn',

    # =========================================================================
    # SndParam internal (FEE8D3-FEEA24)
    # =========================================================================
    'LABEL_FEE8D3': 'SndParam_ComputeVoiceIndex',
    'LABEL_FEE98C': 'SndParam_StoreNoteValue',
    'LABEL_FEE993': 'SndParam_SetDefaultKeyOff',
    'LABEL_FEE99D': 'SndParam_ApplyReturn',
    'LABEL_FEE99F': 'SndParam_CheckAndApplyMode',
    'LABEL_FEE9BD': 'SndParam_LookupFromPointerTable',
    'LABEL_FEE9EA': 'SndParam_LookupByPartAndNote',
    'LABEL_FEEA13': 'SndParam_CompactLookupStub',
    'LABEL_FEEA24': 'SndParam_LookupAndDispatch',
    'LABEL_FEEA63': 'SndParam_ApplyMaskAndCheck',
    'LABEL_FEEABB': 'SndParam_StoreResult',
    'LABEL_FEEABE': 'SndParam_ReturnResult',

    # =========================================================================
    # SndParam_TypeDispatch area (FEEB0E)
    # =========================================================================
    'LABEL_FEEB0E': 'SndParam_TypeDispatch_Entry1',

    # =========================================================================
    # SeqFile init / MIDI reset (FEC83A-FEC851)
    # =========================================================================
    'LABEL_FEC83A': 'SeqInit_ResetAndSetupChannels',
    'LABEL_FEC84C': 'SeqInit_SetDefaultMode',
    'LABEL_FEC851': 'SeqInit_ConfigureBanks',

    # =========================================================================
    # SndParam notify path (FEE184-FEE1A2)
    # =========================================================================
    'LABEL_FEE184': 'SndParam_NotifyLoop_Body',
    'LABEL_FEE19E': 'SndParam_NotifySuccess',
    'LABEL_FEE1A2': 'SndParam_NotifyError',

    # =========================================================================
    # Various utility labels
    # =========================================================================
    'LABEL_FEBF1D': 'MIDI_WriteChannelData_Block',
    'LABEL_FEBEED': 'MIDI_PitchBendData_Block',
    'LABEL_FEF315': 'SndParam_LookupPartIndex',

    # =========================================================================
    # NoteMap_LookupVoice continued (FE495C)
    # =========================================================================
    'LABEL_FE495C': 'NoteMap_LookupVoice_Return',
}


def collect_all_labels(repo_dir):
    existing = set()
    for pat in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pat), recursive=True):
            try:
                with open(fpath, 'rb') as f:
                    content = f.read().decode('latin-1')
                for m in re.finditer(r'^([A-Za-z_]\w*):', content, re.MULTILINE):
                    existing.add(m.group(1))
            except Exception:
                pass
    return existing


def find_all_files_with_label(repo_dir, label):
    files = []
    for pat in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s',
                'table_data/**/*.s', 'custom_data/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pat), recursive=True):
            try:
                with open(fpath, 'rb') as f:
                    content = f.read().decode('latin-1')
                if re.search(r'\b' + re.escape(label) + r'\b', content):
                    files.append(fpath)
            except Exception:
                pass
    return files


def apply_rename(content_bytes, old_label, new_label):
    old = old_label.encode('latin-1')
    new = new_label.encode('latin-1')
    pattern = re.compile(rb'\b' + re.escape(old) + rb'\b')
    return pattern.sub(new, content_bytes)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ('analyze', 'apply'):
        print("Usage: python3 scripts/rename_nvm_labels_batch2.py [analyze|apply]")
        sys.exit(1)

    mode = sys.argv[1]
    existing_labels = collect_all_labels(REPO)

    # Remove the invalid BEBF60 entry
    renames = {k: v for k, v in RENAMES.items() if k.startswith('LABEL_FE') or k.startswith('LABEL_FB') or k.startswith('LABEL_F')}

    errors = []
    for old, new in renames.items():
        if new in existing_labels and old in existing_labels:
            pass
        elif new in existing_labels:
            errors.append(f"COLLISION: {new} already exists (from {old})")
        content = read_file(TARGET_FILE).decode('latin-1')
        if old not in content:
            # Check other files
            found = False
            for pat in ['maincpu/**/*.s']:
                for fpath in glob.glob(os.path.join(REPO, pat), recursive=True):
                    with open(fpath, 'rb') as f:
                        if old.encode('latin-1') in f.read():
                            found = True
                            break
                if found:
                    break
            if not found:
                errors.append(f"NOT FOUND: {old} not in any source file")

    new_names = list(renames.values())
    seen = set()
    for n in new_names:
        if n in seen:
            errors.append(f"DUPLICATE new name: {n}")
        seen.add(n)

    if errors:
        print("ERRORS found:")
        for e in errors:
            print(f"  {e}")
        if mode == 'apply':
            sys.exit(1)

    if mode == 'analyze':
        print(f"Planned renames: {len(renames)}")
        return

    # Apply
    files_to_modify = {}
    for old, new in renames.items():
        refs = find_all_files_with_label(REPO, old)
        for f in refs:
            if f not in files_to_modify:
                files_to_modify[f] = []
            files_to_modify[f].append((old, new))

    print(f"Applying {len(renames)} renames across {len(files_to_modify)} files...")

    for fpath, rename_list in files_to_modify.items():
        content = read_file(fpath)
        for old, new in rename_list:
            content = apply_rename(content, old, new)
        write_file(fpath, content)
        rel = os.path.relpath(fpath, REPO)
        print(f"  Updated {rel} ({len(rename_list)} renames)")

    print("Done.")


if __name__ == '__main__':
    main()
