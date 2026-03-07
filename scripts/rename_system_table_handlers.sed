# Rename system-level table handler targets (kn5000_v10_program.s)
# These are all executable code handlers dispatched from system peripheral
# and MIDI processing tables in the EF/FC address range.

# === Timer_ModeSelect_Table (4 entries, 3 unique) ===
# TMP94C241F timer mode configuration handlers
s/LABEL_EF788C\b/Timer_ModeHandler_0/g
s/LABEL_EF7819\b/Timer_ModeHandler_1/g
s/LABEL_EF7850\b/Timer_ModeHandler_3/g

# === DMA_ChannelSelect_Table (4 entries, 4 unique) ===
# DMA channel setup handlers for TMP94C241F DMA controller
s/LABEL_EF8FDB\b/DMA_ChannelHandler_0/g
s/LABEL_EF8FA2\b/DMA_ChannelHandler_1/g
s/LABEL_EF8FC1\b/DMA_ChannelHandler_2/g
s/LABEL_EF8FE5\b/DMA_ChannelHandler_3/g

# === SerialPort_ModeSelect_Table (4 entries, 3 unique) ===
# Serial port mode configuration handlers
s/LABEL_EF9E03\b/SerialPort_ModeHandler_0/g
s/LABEL_EF9DEF\b/SerialPort_ModeHandler_1/g
s/LABEL_EF9DF9\b/SerialPort_ModeHandler_3/g

# === Interrupt_VectorSelect_Table (5 entries, 5 unique) ===
# Interrupt vector setup handlers
s/LABEL_EFA375\b/Interrupt_VectorHandler_0/g
s/LABEL_EFA38A\b/Interrupt_VectorHandler_1/g
s/LABEL_EFA394\b/Interrupt_VectorHandler_2/g
s/LABEL_EFA3A1\b/Interrupt_VectorHandler_3/g
s/LABEL_EFA3B6\b/Interrupt_VectorHandler_4/g

# === PortConfig_Select_Table (4 entries, 3 unique) ===
# I/O port configuration handlers
s/LABEL_EFA565\b/PortConfig_Handler_0/g
s/LABEL_EFA518\b/PortConfig_Handler_1/g
s/LABEL_EFA532\b/PortConfig_Handler_3/g

# === ClockConfig_Select_Table (4 entries, 2 unique) ===
# System clock configuration handlers
s/LABEL_EFA7BE\b/ClockConfig_Handler_0/g
s/LABEL_EFA7B8\b/ClockConfig_Handler_1/g

# === MemoryConfig_Handler_Table (6 entries, 6 unique) ===
# Memory controller configuration handlers
s/LABEL_EFAD94\b/MemConfig_Handler_0/g
s/LABEL_EFADF8\b/MemConfig_Handler_1/g
s/LABEL_EFACF7\b/MemConfig_Handler_2/g
s/LABEL_EFB0D3\b/MemConfig_Handler_3/g
s/LABEL_EFB60E\b/MemConfig_Handler_4/g
s/LABEL_EF7DB5\b/MemConfig_Handler_5/g

# === SystemInit_Handler_Table (6 entries, 5 unique) ===
# System initialization sequence handlers
s/LABEL_EFB875\b/SystemInit_StepHandler_0/g
s/LABEL_EFB869\b/SystemInit_StepHandler_2/g
s/LABEL_EFB861\b/SystemInit_StepHandler_3/g
s/LABEL_EFB859\b/SystemInit_StepHandler_4/g
s/LABEL_EFB839\b/SystemInit_StepHandler_5/g

# === RegisterBit_Manipulate_Table (8 entries, 4 unique) ===
# Register bit set/clear/toggle handlers
s/LABEL_FCA3E4\b/RegBitManip_Handler_0/g
s/LABEL_FCA3DB\b/RegBitManip_Handler_1/g
s/LABEL_FCA3E1\b/RegBitManip_Handler_3/g
s/LABEL_FCA3EE\b/RegBitManip_Handler_4/g

# === MidiStream_Processor_Table (8 entries, 6 unique) ===
# MIDI byte stream processing handlers (status/data byte routing)
s/LABEL_FCA554\b/MidiStream_ProcessHandler_0/g
s/LABEL_FCA573\b/MidiStream_ProcessHandler_1/g
s/LABEL_FCA592\b/MidiStream_ProcessHandler_2/g
s/LABEL_FCA5B1\b/MidiStream_ProcessHandler_3/g
s/LABEL_FCA5D6\b/MidiStream_ProcessHandler_4/g
s/LABEL_FCA519\b/MidiStream_ProcessHandler_5/g

# === VoiceMode_ParamDispatch_Table (8 entries, 5 unique) ===
# Voice mode parameter processing handlers
s/LABEL_FCB40B\b/VoiceMode_ParamHandler_0/g
s/LABEL_FCADC3\b/VoiceMode_ParamHandler_1/g
s/LABEL_FCB001\b/VoiceMode_ParamHandler_3/g
s/LABEL_FCADD4\b/VoiceMode_ParamHandler_4/g

# === MidiNote_VelocityHandler_Table (4 entries, 3 unique) ===
# MIDI note-on velocity processing handlers
s/LABEL_FCB81D\b/MidiNoteVel_Handler_0/g
s/LABEL_FCB857\b/MidiNoteVel_Handler_1/g
s/LABEL_FCB896\b/MidiNoteVel_Handler_2/g

# === VoiceParam_ReadUpdate_Table (additional targets, 4 remaining LABEL_*) ===
# Voice parameter read/update routines (shared with VoiceSynth_Algorithm_Table)
s/LABEL_F266AC\b/VoiceParam_ReadUpdate_6/g
s/LABEL_F26708\b/VoiceParam_ReadUpdate_7/g
s/LABEL_F26739\b/VoiceParam_ReadUpdate_10/g
s/LABEL_F267D4\b/VoiceParam_ReadUpdate_11/g
