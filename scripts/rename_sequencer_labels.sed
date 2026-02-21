# Rename sequencer/rhythm ROM routines discovered during demo mode investigation
# Main application loop
s/LABEL_EF1245/MainLoop/g
s/LABEL_EF1369/MainLoop_SequencerPhase/g

# Sequencer dispatcher and tick routines
s/LABEL_F532E1/Seq_DispatcherEntry/g
s/LABEL_F53318/Seq_DispatcherTick/g
s/LABEL_F53328/Seq_DispatcherTick_Process/g
s/LABEL_EF1388/Seq_TickWrapper/g
s/LABEL_EF14A3/Seq_EventProcessingTick/g

# Sequencer state machine transitions (8D36h variable)
s/LABEL_F9936D/SeqState_TransitionMode/g
s/LABEL_F993AD/SeqState_DemoModeHandler/g

# Rhythm ROM routines
s/LABEL_F54651/RhythmROM_ValidateHeader/g
s/LABEL_F5452F/RhythmROM_CheckValid/g
s/LABEL_F5EC75/Seq_RhythmProcessor/g
s/LABEL_F634F3/RhythmROM_PatternDispatcher/g
s/LABEL_F6358D/RhythmROM_LoadPattern/g
s/LABEL_F636E4/RhythmROM_CalcPatternAddr/g
s/LABEL_F64550/RhythmROM_LoadDrumKit/g
