#!/usr/bin/env python3
"""Batch 9: Rename high-reference-count unnamed labels to semantic names.

Labels analyzed by exploring code context, call patterns, and string references.
Covers labels with 6-7 references each.
"""

import re
import sys

RENAMES = {
    # 7 refs
    'LABEL_F4294B': 'SeqPart_NoteProcessing_Loop',

    # 6 refs - COMM/sound parameters
    'LABEL_FEF671': 'CommParam_SetComplete_Return',
    'LABEL_FEF3AE': 'CommPacket_WriteMeasureCount',
    'LABEL_FEE551': 'SndParam_StoreResult_Return',
    'LABEL_FEDF68': 'ToneGen_NotifyChangeComplete_Return',
    'LABEL_FEDC96': 'ToneGen_VoiceReset_Return',

    # 6 refs - sequencer/playback
    'LABEL_FECF8B': 'SeqPlay_ReadRecord_Entry',
    'LABEL_FEBFF5': 'AccSong_ProcessRecord_Loop',

    # 6 refs - voice/sound FX
    'LABEL_FE9570': 'Voice_AdjustTiming_Return',
    'LABEL_FE8E34': 'SoundFX_SetVolumeOffset_Return',
    'LABEL_FE83CD': 'SeqPart_EmitPercussionNote_Return',
    'LABEL_FE829F': 'SeqPart_EmitMelodicNote_Return',

    # 6 refs - note mapping
    'LABEL_FE4947': 'NoteMap_StoreResultAndReturn',
    'LABEL_FE470B': 'NoteMap_StoreEntryAndReturn',
    'LABEL_FE4EE1': 'NoteMap_SlotLoop_Continue',

    # 6 refs - MIDI
    'LABEL_FE2024': 'MidiEvent_ProcessCC_Continue',
}


def main():
    filepath = '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s'

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
