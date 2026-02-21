# Rename rhythm ring buffer routines
s/LABEL_EF2563/RhythmBuf_WriteByte/g
s/LABEL_EF259B/RhythmBuf_CheckEmpty/g
s/LABEL_EF25B3/RhythmBuf_Init/g
s/LABEL_EF25C1/RhythmBuf_SaveWritePos/g
s/LABEL_EF150A/RhythmBuf_ProcessEvents/g
s/LABEL_EF1513/RhythmBuf_ProcessLoop/g
s/LABEL_EF1525/RhythmBuf_DispatchEvent/g
s/LABEL_EF3066/Seq_RingBuf_WriteByte_512/g

# Rename rhythm engine senders
s/LABEL_F5549B/Rhythm_SendByte/g
s/LABEL_F543D7/Rhythm_SendNoteOnMax/g
s/LABEL_F543E1/Rhythm_Send3ByteMsg/g
s/LABEL_F54406/Rhythm_SendChanPressure/g
s/LABEL_F54CCD/Rhythm_NoteOnAfterSetup_A/g
s/LABEL_F54CF2/Rhythm_NoteOnAfterSetup_B/g
s/LABEL_F54D3B/Rhythm_NoteOnAfterSetup_C/g

# Rename MIDI dispatcher for rhythm buffer events
s/LABEL_FE0B06/RhythmMidi_Dispatcher/g
s/LABEL_FE0BB5/RhythmMidi_HandleCC/g

# Note: PostEvent, GetEvent, MainPostEvent, MainGetEvent, ApPostEvent
# were already renamed in a previous session.
