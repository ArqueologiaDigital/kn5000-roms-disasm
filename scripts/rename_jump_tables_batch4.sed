# Batch 4: Rename remaining tables in kn5000_v10_program.s

# F1xxxx - Parameter editing, drum config, flash memory
s/LABEL_F12CAF\b/DrumKit_VariantSelect_Table/g
s/LABEL_F13447\b/TuningSystem_Handler_Table/g
s/LABEL_F14427\b/RhythmTransport_Control_Table/g
s/LABEL_F1446F\b/DrumSound_ParamEdit_Table/g
s/LABEL_F158A7\b/FlashWrite_BlockHandler_Table/g
s/LABEL_F1598F\b/FlashRead_BlockHandler_Table/g
s/LABEL_F1612F\b/DrumDetailEdit_Menu_Table/g
s/LABEL_F1652F\b/EffectParam_Edit_Table/g

# F2xxxx - Voice synthesis
s/LABEL_F24FA0\b/VoiceSynth_Algorithm_Table/g
s/LABEL_F256B9\b/VoiceParam_ReadUpdate_Table/g

# FCxxxx - MIDI CC handlers
s/LABEL_FCA3BB\b/RegisterBit_Manipulate_Table/g
s/LABEL_FCA4F9\b/MidiStream_Processor_Table/g
s/LABEL_FCADA3\b/VoiceMode_ParamDispatch_Table/g
s/LABEL_FCB80D\b/MidiNote_VelocityHandler_Table/g
s/LABEL_FCFB3D\b/MidiCC_LowRange_Table/g
s/LABEL_FCFBB3\b/MidiCC_ExtendedRange_Table/g

# E06BB0 - Brass sound pointers
s/LABEL_E06BB0\b/BrassSound_SamplePtr_Table/g

# E55308 - String reference lookup
s/LABEL_E55308\b/Naka_UIStringRef_Table/g

# EEDD36 - Music scale data
s/LABEL_EEDD36\b/ScaleNote_Display_Table/g

# EF63BD - Performance mode params
s/LABEL_EF63BD\b/PerfMode_ParamHandler_Table/g

# EE6xxx - Tone kit and voice tables
s/LABEL_EE6048\b/ToneKit_VoiceDispatch_Table/g
s/LABEL_EE75FA\b/PerfMode_SetupDispatch_Table/g
s/LABEL_EE7632\b/VoiceEdit_ParamDispatch_Table/g
s/LABEL_EE7676\b/AccompStyle_ConfigDispatch_Table/g
s/LABEL_EE76D6\b/RhythmKit_SelectDispatch_Table/g
s/LABEL_EE76F6\b/ChordMode_ConfigDispatch_Table/g
s/LABEL_EE770E\b/RecordMode_SetupDispatch_Table/g
s/LABEL_EE7756\b/ControlPanel_ButtonDispatch_Table/g

# EE8xxx - UI state machine
s/LABEL_EE8558\b/UIState_SeqInit_Table/g
s/LABEL_EE8590\b/UIState_EventHandler_Table/g

# EEAE08 - Sound effects
s/LABEL_EEAE08\b/SoundEffect_Dispatch_Table/g

# EEC288 - Character mapping
s/LABEL_EEC288\b/CharMap_Preamble_Table/g

# E16xxx - Grid property tables
s/LABEL_E16A98\b/GridProperty_Config_Table/g
s/LABEL_E16ACA\b/GridProperty_AltConfig_Table/g

# E3xxxx - External device
s/LABEL_E344D8\b/ExtDevice_ModeDispatch_Table/g

# E44xxx - Font/palette
s/LABEL_E44E58\b/Display_FontPalette_Table/g

# E7Fxxx - Display mode string tables
s/LABEL_E7F900\b/DisplayMode_OnOff_Table/g
s/LABEL_E7FCBA\b/ControlMode_Option_Table/g
s/LABEL_E7FD9E\b/FileTransfer_Status_Table/g
s/LABEL_E7FECA\b/UserMemory_Config_Table/g

# E80xxx - Sound/UI property tables
s/LABEL_E80660\b/Transpose_ValueDisplay_Table/g
s/LABEL_E80B28\b/AudioStream_Property_Table/g
s/LABEL_E80B42\b/UIElement_Property_Table/g
s/LABEL_E80BFE\b/TextInput_Property_Table/g
s/LABEL_E80C72\b/Widget_DataProperty_Table/g

# E85F76 - Techni-Chord style
s/LABEL_E85F76\b/TechniChord_StyleDispatch_Table/g

# EAA7F0/EAA848 - Sequencer play
s/LABEL_EAA7F0\b/Naka_SeqPlay_Screens/g
s/LABEL_EAA848\b/Naka_SeqPlayMode_Screens/g

# EFxxxx - System routines tables
s/LABEL_EF7809\b/Timer_ModeSelect_Table/g
s/LABEL_EF8F92\b/DMA_ChannelSelect_Table/g
s/LABEL_EF9DDF\b/SerialPort_ModeSelect_Table/g
s/LABEL_EFA361\b/Interrupt_VectorSelect_Table/g
s/LABEL_EFA508\b/PortConfig_Select_Table/g
s/LABEL_EFA7A8\b/ClockConfig_Select_Table/g
s/LABEL_EFABE4\b/MemoryConfig_Handler_Table/g
s/LABEL_EFB7DB\b/SystemInit_Handler_Table/g
