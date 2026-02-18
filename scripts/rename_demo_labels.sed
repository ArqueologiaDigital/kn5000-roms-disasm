# Rename Feature Demo related labels to semantic names
# High priority - core demo flow
s/LABEL_F8696F/DemoMode_Main_Operation/g
s/LABEL_F869E3/DemoMode_Initialize/g
s/LABEL_F229F1/SeqInit_PostEventSequence/g
s/LABEL_F22A4D/SeqInit_FinalEvent/g
s/LABEL_F846BF/Seq_StartMainControl/g
s/LABEL_FDDE6F/Audio_CheckSubsystemReady/g
s/LABEL_FDF08A/Audio_CheckInitStatus/g
s/LABEL_FE0E75/Voice_InitializeAll/g

# Medium priority - demo handlers and utilities
s/LABEL_F99490/UI_PostModeChangeEvent/g
s/LABEL_F86A47/Demo_SelectionEntryHandler/g
s/LABEL_FDBD52/Audio_ConfigureDSP/g
s/LABEL_F86DA6/Voice_LoadVoiceTable/g
s/LABEL_F86D5E/Audio_WaitForReady/g
s/LABEL_F86E7B/Demo_PreSetup/g
s/LABEL_F5CFCC/Demo_StyleRhythmData/g
s/LABEL_F846CF/Seq_StartMainControlAlt/g

# Lower priority - demo data and helpers
s/LABEL_F86EF0/Voice_SavePreset/g
s/LABEL_F86F07/Voice_CopyPreset/g
s/LABEL_F86D8C/Timer7_DisableInterrupt/g
s/LABEL_F5CF8B/Demo_LoadVariationData/g
s/LABEL_F5CF97/Demo_LoadVariationData_Inner/g
s/LABEL_F5CFAE/Demo_LoadVariationC_Data/g
s/LABEL_F5CFBB/Demo_LoadVariationC_Loop/g

# Sequencer event check
s/LABEL_EF27A5/Seq_CheckSongEnd/g
s/LABEL_EF14CA/Seq_ProcessEventLoop/g
s/LABEL_EF13CD/Seq_ProcessMidiEvent/g
