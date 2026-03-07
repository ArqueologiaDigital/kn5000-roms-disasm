# Rename VoiceSynth_Algorithm_Table targets (kn5000_v10_program.s)
# Table at 0xF24FA0, 16 entries dispatching voice synthesis algorithms
# Index 0: Simple store algorithm (25 bytes)
s/LABEL_F263F9\b/VoiceSynth_Algo_SimpleStore/g

# Index 1: Multi-path algorithm with loop processing (95 bytes)
s/LABEL_F26412\b/VoiceSynth_Algo_MultiPath/g

# Index 2-5,8-9,12-15: Null algorithm (just ret)
s/LABEL_F26471\b/VoiceSynth_Algo_Null/g

# Index 6: Channel configuration with table lookup (92 bytes)
s/LABEL_F26472\b/VoiceSynth_Algo_ChannelConfig/g

# Index 7: Conditional voice update, calls VoiceChannel_UpdateWithPitch (49 bytes)
s/LABEL_F264CE\b/VoiceSynth_Algo_ConditionalUpdate/g

# Internal label within ConditionalUpdate
s/LABEL_F264DD\b/VoiceSynth_ConditionalUpdate_SetParams/g
s/LABEL_F264F1\b/VoiceSynth_ConditionalUpdate_StoreAndCall/g
s/LABEL_F264FF\b/VoiceSynth_ConditionalUpdate_Helper/g

# Index 10: Multi-stage voice synthesis with multiple code paths (181 bytes)
s/LABEL_F26506\b/VoiceSynth_Algo_MultiStage/g

# Index 11: Pitch-modulated synthesis with conditional processing (108 bytes)
s/LABEL_F265BB\b/VoiceSynth_Algo_PitchModulated/g

# Additional routines near the algorithm table
s/LABEL_F26627\b/VoiceSynth_Algo_DirectStore/g
s/LABEL_F26640\b/VoiceSynth_Algo_PitchShift/g
