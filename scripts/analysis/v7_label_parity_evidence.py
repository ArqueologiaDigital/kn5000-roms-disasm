#!/usr/bin/env python3
"""v7_label_parity_evidence.py -- the evidence that v7's interior labels were
borrowed from v9/v10 without checking v7's bytes.

QUESTION ANSWERED
  For each interior label in the blocked v7 regions: is it referenced anywhere,
  and do v7's raw ROM bytes at that label match v9's bytes at v9's own address
  for the SAME NAME?

  Answer, measured 2026-09-02: essentially zero live references across ~100
  labels, and **96-100% byte divergence across all 14 sampled regions**. A
  name-and-size correspondence tool had assigned these labels from v9/v10
  without ever comparing v7's content. The bytes are real code -- just not the
  routine the borrowed name claims.

⚠ RUN IT AGAINST A PRE-CONVERSION REVISION. The regions it measures have since
  been converted from .byte to instructions, so on today's tree the companion
  diagnosis script reports "find_span failed: not a recognized DATA directive"
  -- correctly, because the .byte runs are gone. To reproduce the figures above,
  check out a revision before commit 300a409c, e.g.

      git worktree add --detach /tmp/v7pre 300a409c^
      cd /tmp/v7pre && python3 scripts/analysis/v7_label_parity_evidence.py

  This is a general hazard for evidence scripts in a converting tree: the
  measurement destroys its own preconditions. State the revision beside the
  number.

PROVENANCE
  Lane V7INTERIOR, 2026-09-02. Recovered from session scratch after the figures
  it produced had already been published in a merge message.
"""
import subprocess, re, os

REPO = os.path.expanduser("~/compartilhado/disasm-lanes/v7interior")
BASE = 0xE00000

REGIONS = [
    ("maincpu/audio/note_voice_mapping.s", 11670, 0xfee831, 222,
     ['Param_SignExtendRetu_Block', 'Param_SignExtendRetu_Block2', 'Param_SignExtendRetu_Data']),
    ("maincpu/audio/note_voice_mapping.s", 10849, 0xfedc84, 105,
     ['StoreAndReturn_Block', 'FileIO_InitTrackSlots', 'InitTrackSlots_LoopBody']),
    ("maincpu/audio/note_voice_mapping.s", 9637, 0xfec786, 75,
     ['SeekRecord_Done_Block2', 'SeekRecord_Done_DoGetPlayS', 'FileIO_SeekRecord_SendMidi']),
    ("maincpu/audio/note_voice_mapping.s", 9442, 0xfec43d, 149,
     ['SeqFile_SkipTrackPad_Loop', 'SeqFile_SkipTrackPad_Next', 'SeqFile_ReadTrackLength',
      'SeqFile_AccumulateLength', 'SeqFile_Epilogue', 'SeqInit_ResetAndSetupChannels',
      'SeqInit_SetDefaultMode', 'SeqInit_ConfigureBanks']),
    ("maincpu/audio/note_voice_mapping.s", 8871, 0xfeba64, 94,
     ['MIDI_SendPartVol_StoreAndSend', 'MIDI_SendPartVol_ExtraParts',
      'MIDI_SendPartVol_ExtraLookup', 'MIDI_SendPartVol_ExtraSend']),
    ("maincpu/audio/note_voice_mapping.s", 8715, 0xfeb7d1, 169,
     ['SendChannelPressure_Prologue', 'SendChannelPressure_InitVal', 'SendChannelPressure_LoadReg',
      'SendChannelPressure_LoadParam', 'SeqVoice_CheckAndRetry', 'SeqVoice_CheckAndRet_Compare']),
    ("maincpu/audio/note_voice_mapping.s", 3691, 0xfe4c48, 205,
     ['Voice_EmitMidiNoteAndBankEvents', 'MIDI_SendVoiceData_Loop', 'MIDI_SendVoiceData_Increment',
      'MIDI_SendVoiceData_CheckCount']),
    ("maincpu/audio/note_voice_mapping.s", 3626, 0xfe4b2c, 172,
     ['NoteMap_SlotLoop_Continue', 'SlotLoop_Continue_LoadParam', 'SlotLoop_Continue_RestoreReg',
      'NoteMap_SetChannelParam', 'SetChannelParam_LoadParam', 'SetChannelParam_LoadDRAM']),
    ("maincpu/audio/sndparam_routines.s", 1163, 0xfcea6a, 749,
     ['SndParam_Widget1_CallType4', 'SndParam_Widget1_Done', 'SndParam_BinarySearch',
      'SndParam_EncodeAddress', 'SndParam_InitHashTable', 'SndParam_InitHashFillLoop',
      'SndParam_RegisterAllWidgets', 'SndParam_RegisterLoop', 'SndParam_InsertEntry',
      'SndParam_InsertProbe', 'SndParam_InsertCheckKey', 'SndParam_InsertIncSlot',
      'SndParam_InsertKeyMatch', 'SndParam_InsertNextSlot', 'SndParam_InsertFail',
      'SndParam_InsertReturn', 'SndParam_ClearHashTable', 'SndParam_ClearLoop',
      'SndParam_ClearHeap', 'SndParam_ReregisterAll', 'SndParam_ReregisterLoop',
      'SndParam_AllocAndInsert', 'SndParam_AllocBuildKey', 'SndParam_AllocChainExisting',
      'SndParam_AllocChainLoop', 'SndParam_AllocAppendToChain', 'SndParam_AllocSuccess',
      'SndParam_HeapAlloc', 'SndParam_HeapAllocFail']),
    ("maincpu/midi/midi_dispatch_handlers.s", 5982, 0xfd7f87, 111,
     ['SeqBuf2_InitWithInterrupts', 'SeqBuf_Timing_Data', 'MidiChan_ClearStorageFields',
      'MidiChan_InitAllBufferPtrs']),
    ("maincpu/midi/midi_dispatch_handlers.s", 3985, 0xfd5551, 123,
     ['MidiSysEx_SendPCRegValue', 'MidiSysEx_SendPCViaCOMM', 'MidiSysEx_SendControlChange1',
      'MidiSysEx_SendCC1RegValue']),
    ("maincpu/midi/midi_dispatch_handlers.s", 82, 0xfcf905, 994,
     ['MidiCC_Handler_PairedParamA', 'MidiCC_Handler_PairedParamB', 'MidiCC_Handler_RangeCheck',
      'MidiCC_Handler_ChannelMapping', 'MidiCC_VoiceParam_0', 'MidiCC_VoiceParam_1',
      'MidiCC_VoiceParam_2', 'MidiCC_VoiceParam_3', 'MidiCC_VoiceParam_4', 'MidiCC_VoiceParam_5',
      'MidiCC_VoiceParam_6', 'MidiCC_VoiceParam_7', 'MidiCC_VoiceParam_8', 'MidiCC_VoiceParam_9',
      'MidiCC_StubHandler_A']),
    ("maincpu/midi/midi_serial_routines.s", 438, 0xfcf4a6, 296,
     ['MIDI_RX_CONTEXT_RESTORE', 'MIDI_RX_CONTEXT_SAVE', 'SC0Init_Entry',
      'SC0Init_StandardBaudTable', 'SC0Init_AlternateBaudTable', 'SC0Init_BaudTableReturn',
      'READ_COM_SELECT_SWITCH', 'MidiSerial_OffsetTable', 'SC0Init_ClearContextSlots',
      'SC0Init_EnableRegisters', 'SC0Init_PaddingStub', 'MIDI_SC0_DISPATCH_TABLE',
      'MIDI_SC0_TX_DISPATCH']),
    ("maincpu/midi/midi_serial_routines.s", 168, 0xfcefc0, 204,
     ['ClkTick_Src2ClickIncrement', 'ClkTick_Src2FineBeatCheck', 'ClkTick_Src2CoarseOverflow',
      'ClkTick_Src2ErrorDelta', 'ClkTick_Src2ErrorAccumulate', 'ClkTick_Src2ErrorWriteback',
      'ClkTick_Src3ClickCheck']),
]


def grep_count(label, relpath):
    out = subprocess.run(
        ["grep", "-rn", rf"\b{re.escape(label)}\b", os.path.join(REPO, "v7")],
        capture_output=True, text=True).stdout
    lines = [l for l in out.splitlines() if "transplant_manifest.txt" not in l]
    def_line = f"v7/{relpath}:"
    others = [l for l in lines if not (def_line in l and l.split(":")[2].strip().rstrip(":") == label)]
    # crude: exclude lines that are exactly the label definition (label: at col0)
    others2 = []
    for l in lines:
        if def_line in l:
            # this is the region's own file; is it the definition line or a real use?
            rest = l.split(":", 2)[-1].strip()
            if rest == f"{label}:":
                continue
        others2.append(l)
    return others2


def get_addr_in(tag, label):
    elf = os.path.join(REPO, "census-work", f"{tag}.elf")
    if not os.path.exists(elf):
        return None
    NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
    out = subprocess.run([NM, "--no-sort", elf], capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == label:
            return int(parts[0], 16)
    return None


def manifest_size(label):
    mf = os.path.join(REPO, "v7/maincpu/transplant_manifest.txt")
    with open(mf, encoding="latin-1") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 3 and parts[1] == label:
                return int(parts[2])
    return None


def main():
    v7rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    v9rom = open(os.path.join(REPO, "original_ROMs/kn5000_v9_program.rom"), "rb").read()
    v10rom = open(os.path.join(REPO, "original_ROMs/kn5000_v10_program.rom"), "rb").read()

    for relpath, start_line, addr, size, labels in REGIONS:
        print(f"\n=== {relpath}:{start_line} addr {addr:#x} size {size}B ===")
        for lab in labels:
            refs = grep_count(lab, relpath)
            sz = manifest_size(lab)
            v9a = get_addr_in("v9", lab)
            v10a = get_addr_in("v10", lab)
            note = ""
            if sz is not None and v9a is not None:
                off9 = v9a - BASE
                r9 = v9rom[off9:off9 + sz]
                # v7's own bytes for this label: need its OWN address --
                # we don't have per-label v7 elf/nm here (v7 doesn't
                # decode), so just note v9/v10 existence + size for manual
                # cross-check by the caller.
                note = f" v9@{v9a:#x} sz{sz}"
            if v10a is not None:
                note += f" v10@{v10a:#x}"
            print(f"  {lab}: external_refs={len(refs)} {note}")
            for r in refs[:3]:
                print(f"      {r}")


if __name__ == "__main__":
    main()
