# The 441-byte chord table's parts (v10/v9 note_voice_mapping.s header): symbolizer names -> what they hold
s/\bInitPartAllocState_TestBit242_Data_2\b/ChordTables_TypeIntervals/g
s/\bInitPartAllocState_TestBit242_Data\b/ChordTables_TypeNoteCount/g
s/\bVoiceSlot_StoreParams_LoadReg_Data\b/ChordTables_NoteToPitchClass/g
s/\bVoiceSlot_CheckAndApply_Data\b/Chord_Tables/g
