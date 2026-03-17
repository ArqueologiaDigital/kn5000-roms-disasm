#!/usr/bin/env python3
"""Rename MIDI parameter processing labels to semantic names."""

import re
import sys

RENAMES = {
    'LABEL_FC6ED1': 'MidiParam_ProcessDeltas',
    'LABEL_FC6EE0': 'MidiParam_ProcessChannel0',
    'LABEL_FC6F33': 'MidiParam_ProcessChannel1',
    'LABEL_FC6F2D': 'MidiParam_Ch0_Done',
    'LABEL_FC6F80': 'MidiParam_Ch1_Done',
    'LABEL_FC6FF4': 'MidiParam_DeltaTooSmall',
    'LABEL_FC6FFD': 'MidiParam_DeltaDone',
    'LABEL_FC6FDD': 'MidiParam_DeltaMedium',
    'LABEL_FC6FE3': 'MidiParam_DeltaConfirmed',
    'LABEL_FC6FEE': 'MidiParam_DeltaStartDebounce',
    'LABEL_FC6FF9': 'MidiParam_DeltaClearActive',
    'LABEL_FC6E42': 'MidiParam_ForceResync',
    'LABEL_FC6EBD': 'MidiChannel_GetParam1',
    'LABEL_FC6EC3': 'MidiChannel_GetParam2',
    'LABEL_FC6EC9': 'MidiChannel_GetParam3',
    'LABEL_FC6ECD': 'MidiChannel_GetParamReturn',
}

def main():
    files = [
        '/mnt/shared/kn5000-roms-disasm/maincpu/kn5000_v10_program.s',
        '/mnt/shared/kn5000-roms-disasm/symbols/maincpu_symbols_reference.txt',
    ]

    for filepath in files:
        with open(filepath, 'rb') as f:
            data = f.read()

        text = data.decode('latin-1')
        count = 0
        for old, new in RENAMES.items():
            pattern = r'\b' + re.escape(old) + r'\b'
            matches = len(re.findall(pattern, text))
            if matches > 0:
                text = re.sub(pattern, new, text)
                count += matches
                print(f"  {old} -> {new}: {matches} replacements")

        with open(filepath, 'wb') as f:
            f.write(text.encode('latin-1'))

        print(f"{filepath}: {count} total replacements")

if __name__ == '__main__':
    main()
