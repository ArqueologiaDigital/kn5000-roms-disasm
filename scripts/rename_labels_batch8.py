#!/usr/bin/env python3
"""Batch 8: Rename high-reference-count unnamed labels to semantic names.

Labels analyzed by exploring code context, call patterns, and string references.
"""

import re
import sys

RENAMES = {
    # Batch A (10-7 refs)
    'LABEL_EF6A25': 'PerfMode_ParamHandler_8',
    'LABEL_F42AB0': 'Rhythm_NoteAllocation_Finalize',
    'LABEL_F7823C': 'ComSetGridCheck_ParamDisplay',
    'LABEL_FADD24': 'DrawPartGroup_Loop',
    'LABEL_FE281B': 'NoteMap_EncodeCC_Recheck',
    'LABEL_FECB86': 'FileIO_SeekRecord_Return',
    'LABEL_F1DA18': 'PsParaListBoxProc_Return',
    'LABEL_F3A3CA': 'SeqPlay_ReadTempoEvents_ReturnZero',

    # Batch B (6 refs)
    'LABEL_F3EF7E': 'SeqCh_WriteVoiceDataToTable',
    'LABEL_F3FF49': 'Part_LoadAndApplyVoiceTable',
    'LABEL_F45057': 'SeqVoice_PostStatusEvent_Inactive',
    'LABEL_F48E63': 'SeqStep_CallHandleNoteOverflow',
    'LABEL_F53309': 'Rhythm_DispatchNote_Finalize',
    'LABEL_F5FF1B': 'AccPatch_SyncStateAndReturn',
    'LABEL_F6016B': 'AccPatch_LoadNextSequencePointers',
    'LABEL_F60688': 'AccPatch_ProcessMarkerCommand',
    'LABEL_F61C7C': 'ToneGen_ClassifyStereoSlot_Common',
    'LABEL_F66A19': 'Part_LoadAndIndexVoiceTable',

    # Batch C (6 refs)
    'LABEL_F674BB': 'DrumParam_ClampVoiceCount',
    'LABEL_F74ACB': 'R12Octave_StringCopyAndSendEvent',
    'LABEL_F8018A': 'AudioCtrl_ReturnToCallerExit',
    'LABEL_F80730': 'AudioCtrl_ProcessParamsAndReturn',
    'LABEL_F870F6': 'RecordChain_SkipToNext',
    'LABEL_F87101': 'RecordChain_ContinueLoop',
    'LABEL_F87AD4': 'FileIO_FinalizeRecordLookup',
    'LABEL_F99670': 'CtrlPanel_InvalidIndexHandler',
    'LABEL_FA23FA': 'IvShowHide_ProcessSpecialEvent',
    'LABEL_FAE901': 'FileIO_ControllerValidationFailed',

    # Batch D (6 refs)
    'LABEL_FBCCED': 'DispTimeSet_SendEventReturn',
    'LABEL_FC24EA': 'WallHomeEditCheck_ReturnFalse',
    'LABEL_FCA7BA': 'Tempo_ExpressionStore',
    'LABEL_FCA80B': 'Mod_ExpressionStore',
    'LABEL_FCA923': 'MIDI_ParamValidation_ReturnNoOp',
    'LABEL_FD755E': 'DSP_Init_ErrorFlagSet',
    'LABEL_FD989B': 'DSP_ParamLoop_Cleanup',
    'LABEL_FDB7D5': 'MIDI_SeqProcess_DisableIntReturn',
}


def main():
    filepath = '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    count = 0
    for old, new in RENAMES.items():
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
