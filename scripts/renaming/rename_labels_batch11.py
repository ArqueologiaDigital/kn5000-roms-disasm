#!/usr/bin/env python3
"""Batch 11: Rename high-reference-count unnamed labels to semantic names.

Labels analyzed by exploring code context, call patterns, and string references.
Covers remaining labels with 5 references each (69 labels).
"""

import sys

RENAMES = {
    # Batch L - Sound, String, Voice, Rhythm, ToneGen, AccPatch
    'LABEL_FEF6F5': 'Note_CheckValidityReturn',
    'LABEL_FEEBDC': 'Param_SignExtendReturn',
    'LABEL_FEE55A': 'SndParam_StoreDRAMInit',
    'LABEL_FEE119': 'Seq_CalcAddrOffset',
    'LABEL_F7EE5A': 'StringOp_ReturnZero',
    'LABEL_F7EE3C': 'StringOp_CopyCall',
    'LABEL_F7E861': 'Voice_InheritedProcCall',
    'LABEL_F7CC76': 'LswSound_ReturnZero',
    'LABEL_F751D6': 'AudioMix_SendEvent',
    'LABEL_F74F83': 'AudioMix_SendEventAlt',
    'LABEL_F72029': 'TempoEvt_ContinueProcessing',
    'LABEL_F71E6C': 'AccPlay_ContinueMainLoop',
    'LABEL_F70BA1': 'SeqEvt_ProcessLoop_Check',
    'LABEL_F66DC1': 'Voice_BoundaryCheck',
    'LABEL_F66B0D': 'Voice_ResolveSlot',
    'LABEL_F63782': 'RhythmROM_ProcessPattern',
    'LABEL_F63722': 'RhythmROM_InitPattern',
    'LABEL_F63581': 'RhythmROM_LoadAndInit',
    'LABEL_F62165': 'ToneGen_StepVoiceReturn',
    'LABEL_F60695': 'AccPatch_ContinueProcessing',

    # Batch M - ToneGen, Rhythm, Seq, Part, Voice
    'LABEL_F5F3CD': 'ToneGen_FetchSelectRestore',
    'LABEL_F5F0AE': 'RhythmConfig_CheckAndSkip',
    'LABEL_F56834': 'AccVoice_EventProcessingReturn',
    'LABEL_F56173': 'Seq_ProcessAndContinue',
    'LABEL_F48683': 'PartCtrl_AdjustAndReturn',
    'LABEL_F47E5A': 'SeqLoad_FetchPartLength',
    'LABEL_F46BC5': 'SeqAcc_ProcessedReturn',
    'LABEL_F454B5': 'Voice_OffsetAndDispatch',
    'LABEL_F4325C': 'SeqPlay_PostInitReturn',
    'LABEL_F42CF6': 'Rhythm_ClearAndReturn',
    'LABEL_F3FFDC': 'SeqData_TrackProcessComplete',
    'LABEL_F3FEEB': 'SeqData_UpdatePositionAndReturn',
    'LABEL_F3FCB7': 'PartCtrl_ConfigureAndReturn',
    'LABEL_F3F88A': 'Seq_ValidationFailReturn',
    'LABEL_F3F6AD': 'Seq_TempoValidationFailReturn',
    'LABEL_F3EC43': 'SeqBuf_MidiEventReturnPath',
    'LABEL_F3EB3B': 'SeqPart_ReturnStatusFour',
    'LABEL_F3E3CD': 'SeqEvent_ReturnStatusThree',
    'LABEL_F3DF75': 'BitMapOut_CompletionJoin',
    'LABEL_F3AE09': 'SeqNote_StreamAdvanceJoin',

    # Batch N - Seq, SMF, BmDrEdit, Voice, String
    'LABEL_F2041B': 'SeqPlay_RestoreVoiceState_Return',
    'LABEL_F228FD': 'SongBank_EventHandler_Return',
    'LABEL_F236AA': 'SeqPlay_ReadyStateTransition',
    'LABEL_F25D71': 'VoiceChannel_StorePosition_Continue',
    'LABEL_F268A2': 'ToneGen_SaveVoiceState_Continue',
    'LABEL_F2810B': 'SMF_ProcessTimedEvent_Continue',
    'LABEL_F28152': 'SMF_EventLoop_Return',
    'LABEL_F2E640': 'EventHandler_FinalizeAndReturn',
    'LABEL_F2FF02': 'StringDraw_CleanupAndReturn',
    'LABEL_F375D4': 'NoteEditSy_CallFarRoutine',
    'LABEL_F3763C': 'BmDrEdit_WalkTrackLoop',
    'LABEL_F379D4': 'BmDrEdit_ScanSequenceEnd',
    'LABEL_F37A32': 'BmDrEdit_CheckVelocityMatch',
    'LABEL_F380E6': 'NoteEditSy_ScrollComplete_Return',
    'LABEL_F39883': 'SeqVoice_EventAdvanceLoop',
    'LABEL_F39895': 'SeqVoice_ChannelValidation_Check',
    'LABEL_F39916': 'SeqVoice_DataReadError_Return',
    'LABEL_F3A11E': 'KeyScan_DisableComplete_Return',
    'LABEL_F3AC2F': 'SeqNote_CheckActiveChannels',
    'LABEL_F3AD22': 'SeqNote_LoadNoteParam_Return',

    # Batch O - FileIO, UI, Voice, Port
    'LABEL_F1ED20': 'FileIO_SendCommand_Return',
    'LABEL_F1BEA0': 'CmpFunc_Return',
    'LABEL_F1B632': 'DesignFrame_Return',
    'LABEL_F1ABAF': 'EventHandler_Return',
    'LABEL_F1ABAB': 'SendEvent_Continue',
    'LABEL_F1A458': 'GridBoxProc_Return',
    'LABEL_EF4889': 'PortWrite_BusyWait',
    'LABEL_EF68F7': 'PerfMode_ParamHandler_Data',
    'LABEL_EF6DAD': 'VoiceParam_CommonTail',
}


def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # Pre-check for duplicate target names
    skip = set()
    for old, new in RENAMES.items():
        if new in text:
            print(f"WARNING: Target name '{new}' already exists in file! Skipping {old}.")
            skip.add(old)

    count = 0
    for old, new in RENAMES.items():
        if old in skip:
            continue
        if old not in text:
            print(f"WARNING: {old} not found in file!")
            continue
        occurrences = text.count(old)
        text = text.replace(old, new)
        print(f"  {old} -> {new} ({occurrences} occurrences)")
        count += 1

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))

    print(f"\nRenamed {count} labels ({sum(text.count(new) for new in RENAMES.values())} total occurrences)")


if __name__ == '__main__':
    main()
