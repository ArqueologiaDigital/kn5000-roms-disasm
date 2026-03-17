#!/usr/bin/env python3
"""
Rename SeqAlt ring buffer symbols to meaningful names based on their consumers.

Buffer mapping (determined by base address and reader analysis):
  SeqAlt1 (0x01F785, 128-entry) -> SeqBuf_MidiOut    (read by midi_serial_routines)
  SeqAlt2 (0x01FCA3, 1024-entry) -> SeqBuf_DspSysEx  (read by dsp_config_sysex)
  SeqAlt3 (0x0201C1, 128-entry) -> SeqBuf_VoiceMap   (read by note_voice_mapping)
  SeqAlt4 (0x0202C7/0x0203D5)   -> SeqBuf_NoteEvent  (read by note_voice_mapping, sound_editor_ui)
  SeqAlt5 (via LABEL_EF2E39)    -> SeqBuf_SoundEdit  (read by sound_editor_ui)

Also renames the DMA ISR dispatch table entries:
  Seq_MultiWrite_Alt4 -> SeqDMA_MultiWrite_NoteEvent
  Seq_MultiWrite_Alt5 -> SeqDMA_MultiWrite_SoundEdit
  Seq_MultiWrite_Alt3 -> SeqDMA_MultiWrite_VoiceMap
  Seq_MultiWrite_Alt1 -> SeqDMA_MultiWrite_DspSysEx  (it calls SeqAlt2/DspSysEx!)
  Seq_WriteMidi90     -> SeqDMA_WriteMidi_NoteOn
  Seq_RingBuf_Nop     -> SeqDMA_Nop

Binary I/O for Latin-1 safety.
"""

import os
import glob

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')

# All renames: old -> new
RENAMES = {
    # Buffer 1: MIDI output
    b'SeqAlt1_ReadByte': b'SeqBuf_MidiOut_ReadByte',
    b'SeqAlt1_WriteByte': b'SeqBuf_MidiOut_WriteByte',
    b'SeqAlt1_WriteBytes': b'SeqBuf_MidiOut_WriteBytes',
    b'SeqAlt1_WriteBytes_Loop': b'SeqBuf_MidiOut_WriteBytes_Loop',
    b'SeqAlt1_CheckEmpty': b'SeqBuf_MidiOut_CheckEmpty',
    b'SeqAlt1_CheckEmpty_Return': b'SeqBuf_MidiOut_CheckEmpty_Return',
    b'SeqAlt1_GetTimingValue': b'SeqBuf_MidiOut_GetTimingValue',
    b'SeqAlt1_Init': b'SeqBuf_MidiOut_Init',
    b'SeqAlt1_SaveReadPos': b'SeqBuf_MidiOut_SaveReadPos',
    b'SeqAlt1_ReadAlternate': b'SeqBuf_MidiOut_ReadAlternate',
    b'SeqAlt1_ReadAlternate2': b'SeqBuf_MidiOut_ReadAlternate2',
    b'SeqAlt1_SaveReadPos2': b'SeqBuf_MidiOut_SaveReadPos2',
    b'SeqAlt1_SaveReadPos3': b'SeqBuf_MidiOut_SaveReadPos3',

    # Buffer 2: DSP / SysEx
    b'SeqAlt2_ReadByte_1024': b'SeqBuf_DspSysEx_ReadByte',
    b'SeqAlt2_WriteByte': b'SeqBuf_DspSysEx_WriteByte',
    b'SeqAlt2_WriteBytes': b'SeqBuf_DspSysEx_WriteBytes',
    b'SeqAlt2_CheckSongEnd': b'SeqBuf_DspSysEx_CheckSongEnd',
    b'SeqAlt2_InitBuffer': b'SeqBuf_DspSysEx_InitBuffer',
    b'SeqAlt2_DataReadLoop': b'SeqBuf_DspSysEx_DataReadLoop',

    # Buffer 3: Voice/note mapping
    b'SeqAlt3_ReadByte': b'SeqBuf_VoiceMap_ReadByte',
    b'SeqAlt3_WriteByte': b'SeqBuf_VoiceMap_WriteByte',
    b'SeqAlt3_WriteBlock': b'SeqBuf_VoiceMap_WriteBlock',
    b'SeqAlt3_WriteBlock_Loop': b'SeqBuf_VoiceMap_WriteBlock_Loop',
    b'SeqAlt3_CheckEmpty': b'SeqBuf_VoiceMap_CheckEmpty',
    b'SeqAlt3_CheckEmpty_Done': b'SeqBuf_VoiceMap_CheckEmpty_Done',
    b'SeqAlt3_GetWritePos': b'SeqBuf_VoiceMap_GetWritePos',
    b'SeqAlt3_Flush': b'SeqBuf_VoiceMap_Flush',
    b'SeqAlt3_SaveWritePtr': b'SeqBuf_VoiceMap_SaveWritePtr',
    b'SeqAlt3_CommitWrite': b'SeqBuf_VoiceMap_CommitWrite',
    b'SeqAlt3_RollbackWrite': b'SeqBuf_VoiceMap_RollbackWrite',
    b'SeqAlt3_SaveReadPtr': b'SeqBuf_VoiceMap_SaveReadPtr',
    b'SeqAlt3_AdvanceCheckpoint': b'SeqBuf_VoiceMap_AdvanceCheckpoint',

    # Buffer 4: Note events
    b'SeqAlt4_ReadByte': b'SeqBuf_NoteEvent_ReadByte',
    b'SeqAlt4_WriteByte_Data': b'SeqBuf_NoteEvent_WriteByte_Data',
    b'SeqAlt4_WriteByte_Block': b'SeqBuf_NoteEvent_WriteByte_Block',
    b'SeqAlt4_Flush': b'SeqBuf_NoteEvent_Flush',
    b'SeqAlt4_SaveWritePtr': b'SeqBuf_NoteEvent_SaveWritePtr',
    b'SeqAlt4_CheckSongEnd': b'SeqBuf_NoteEvent_CheckSongEnd',

    # Buffer 5: Sound editor
    b'SeqAlt5_Flush': b'SeqBuf_SoundEdit_Flush',
    b'SeqAlt5_SaveWritePtr': b'SeqBuf_SoundEdit_SaveWritePtr',
    b'SeqAlt5_CommitWrite': b'SeqBuf_SoundEdit_CommitWrite',
    b'SeqAlt5_RollbackWrite': b'SeqBuf_SoundEdit_RollbackWrite',
    b'SeqAlt5_SaveReadPtr': b'SeqBuf_SoundEdit_SaveReadPtr',
    b'SeqAlt5_AdvanceCheckpoint': b'SeqBuf_SoundEdit_AdvanceCheckpoint',
    b'SeqAlt5_ReadByte': b'SeqBuf_SoundEdit_ReadByte',

    # DMA ISR dispatch handlers (named by target buffer)
    b'Seq_MultiWrite_Alt4': b'SeqDMA_MultiWrite_NoteEvent',
    b'Seq_MultiWrite_Alt4_Loop': b'SeqDMA_MultiWrite_NoteEvent_Loop',
    b'Seq_MultiWrite_Alt4_Done': b'SeqDMA_MultiWrite_NoteEvent_Done',
    b'Seq_MultiWrite_Alt5': b'SeqDMA_MultiWrite_SoundEdit',
    b'Seq_MultiWrite_Alt5_Loop': b'SeqDMA_MultiWrite_SoundEdit_Loop',
    b'Seq_MultiWrite_Alt5_Done': b'SeqDMA_MultiWrite_SoundEdit_Done',
    b'Seq_MultiWrite_Alt3': b'SeqDMA_MultiWrite_VoiceMap',
    b'Seq_MultiWrite_Alt3_Loop': b'SeqDMA_MultiWrite_VoiceMap_Loop',
    b'Seq_MultiWrite_Alt3_Done': b'SeqDMA_MultiWrite_VoiceMap_Done',
    # NOTE: MultiWrite_Alt1 calls SeqAlt2 (DspSysEx), not SeqAlt1!
    b'Seq_MultiWrite_Alt1': b'SeqDMA_MultiWrite_DspSysEx',
    b'Seq_MultiWrite_Alt1_Loop': b'SeqDMA_MultiWrite_DspSysEx_Loop',
    b'Seq_MultiWrite_Alt1_Done': b'SeqDMA_MultiWrite_DspSysEx_Done',
    b'Seq_WriteMidi90': b'SeqDMA_WriteMidi_NoteOn',
    b'Seq_WriteMidi90_Done': b'SeqDMA_WriteMidi_NoteOn_Done',

    # Main loop labels
    b'MainLoop_AfterSeqAlt2': b'MainLoop_AfterSeqBuf_DspSysEx',
    b'MainLoop_AfterSeqAlt4': b'MainLoop_AfterSeqBuf_NoteEvent',
}


def rename_file(path, renames):
    """Apply all renames to a single file. Returns count of replacements."""
    with open(path, 'rb') as f:
        content = f.read()

    original = content
    count = 0

    # Sort by length descending to avoid partial matches
    # (e.g., "SeqAlt1_WriteBytes_Loop" before "SeqAlt1_WriteBytes")
    for old, new in sorted(renames.items(), key=lambda x: -len(x[0])):
        n = content.count(old)
        if n > 0:
            content = content.replace(old, new)
            count += n

    if content != original:
        with open(path, 'wb') as f:
            f.write(content)

    return count


def main():
    # Find all .s files under maincpu/
    files = []
    for root, dirs, filenames in os.walk(MAINCPU_DIR):
        for fn in filenames:
            if fn.endswith('.s'):
                files.append(os.path.join(root, fn))

    total = 0
    for path in sorted(files):
        count = rename_file(path, RENAMES)
        if count > 0:
            rel = os.path.relpath(path, MAINCPU_DIR)
            print(f'  {rel}: {count} replacements')
            total += count

    print(f'\nDone: {total} total replacements across {len(files)} files')


if __name__ == '__main__':
    main()
