# Audio Subsystem Symbol Renaming Script
# Usage:
#   sed -f audio_subsystem_rename.sed -i maincpu/kn5000_v10_program.asm
#   sed -f audio_subsystem_rename.sed -i subcpu/kn5000_subprogram_v142.asm
#
# Or to preview changes:
#   sed -f audio_subsystem_rename.sed maincpu/kn5000_v10_program.asm > /tmp/preview.asm

# =============================================================================
# MAIN CPU: Audio/DMA Routines (8 symbols)
# =============================================================================
s/LABEL_EF1F0F/Audio_Lock_Release/g
s/LABEL_EF1FEE/Audio_Lock_Acquire/g
s/LABEL_EF341B/Audio_DMA_Transfer/g
s/LABEL_EF3D0E/HDAE5000_Detect/g
s/LABEL_EF3DBB/HDAE5000_Flash_Verify/g
s/LABEL_EF3F29/HDAE5000_Status_Check/g
s/LABEL_EF48AE/TableData_ROM_Verify/g
s/LABEL_EF48CF/HDAE5000_ROM_Transfer/g

# =============================================================================
# SUB CPU: Command Dispatch Handlers (6 symbols)
# =============================================================================
s/LABEL_034D5F/Audio_CmdHandler_00_1F/g
s/LABEL_01FC7C/Audio_CmdHandler_20_3F/g
s/LABEL_01FC7F/Audio_CmdHandler_40_5F/g
s/LABEL_035893/Audio_CmdHandler_60_7F/g
s/LABEL_03CFEE/Audio_CmdHandler_A0_BF/g
s/LABEL_020C12/Audio_CmdHandler_C0_FF/g

# Sub-labels within Audio_CmdHandler_00_1F
s/LABEL_034D66/Audio_CmdHandler_00_1F_Loop/g
s/LABEL_034D90/Audio_CmdHandler_00_1F_Done/g
s/LABEL_034D47/Audio_CmdHandler_ConstData/g

# =============================================================================
# SUB CPU: MIDI Message Dispatcher (16+ symbols)
# =============================================================================
s/LABEL_034D93/MIDI_Dispatch/g
s/LABEL_034DA2/MIDI_Dispatch_ParseStatus/g

# MIDI Status Handlers
s/LABEL_034E65/MIDI_Status_NoteOn/g
s/LABEL_034E9F/MIDI_Status_NoteOn_Poly/g
s/LABEL_034EAA/MIDI_Status_NoteOn_Skip/g
s/LABEL_034E21/MIDI_Status_NoteOn_Extended/g
s/LABEL_034E5D/MIDI_Status_Incomplete/g

s/LABEL_034EB2/MIDI_Status_CtrlChange/g
s/LABEL_034EE3/MIDI_Status_CtrlChange_Skip/g

s/LABEL_034EEB/MIDI_Status_ProgChange/g
s/LABEL_034F25/MIDI_Status_ProgChange_Skip/g

s/LABEL_034F2D/MIDI_Status_ChanPressure/g
s/LABEL_034F5E/MIDI_Status_ChanPressure_Skip/g

s/LABEL_034F65/MIDI_Status_PitchBend/g
s/LABEL_034F95/MIDI_Status_PitchBend_Skip/g

s/LABEL_034F9C/MIDI_Status_System/g
s/LABEL_034FCC/MIDI_Status_System_Skip/g

s/LABEL_034FD3/MIDI_Status_Unknown/g
s/LABEL_034FD8/MIDI_Dispatch_NextByte/g
s/LABEL_034FE4/MIDI_Dispatch_Exit/g

# =============================================================================
# SUB CPU: Voice Parameter Handlers (12+ symbols)
# =============================================================================
s/LABEL_02CF97/Voice_NoteOn/g
s/LABEL_02A282/Voice_CtrlChange/g
s/LABEL_034A4A/Voice_ProgChange/g
s/LABEL_02A4EA/Voice_ChanPressure/g
s/LABEL_02A5E6/Voice_PitchBend/g
s/LABEL_0356C9/Voice_Poly_NoteOn/g
s/LABEL_02A7AF/Voice_SystemMsg/g
s/LABEL_031A72/Voice_ParamFinalize/g

# Control Change Sub-handlers
s/LABEL_02A306/Voice_CC_ModWheel/g
s/LABEL_02A31C/Voice_CC_Volume/g
s/LABEL_02A340/Voice_CC_Pan/g
s/LABEL_02A35F/Voice_CC_Expression/g
s/LABEL_02A383/Voice_CC_Sustain/g
s/LABEL_02A3A9/Voice_CC_Sostenuto/g
s/LABEL_02A3BF/Voice_CC_Soft/g
s/LABEL_02A3D5/Voice_CC_Portamento/g
s/LABEL_02A46C/Voice_CC_91/g
s/LABEL_02A481/Voice_CC_95/g
s/LABEL_02A496/Voice_CC_97/g
s/LABEL_02A4AB/Voice_CC_9B/g
s/LABEL_02A4C0/Voice_CC_9C/g
s/LABEL_02A4D5/Voice_CC_9D/g
s/LABEL_02A4E8/Voice_CC_Exit/g

# =============================================================================
# SUB CPU: Ring Buffer Operations (4 symbols)
# =============================================================================
s/LABEL_034CFC/RingBuf_ReadByte/g
s/LABEL_034D2B/RingBuf_SkipToEnd/g
s/LABEL_021031/RingBuf_SetOffsetHi/g
s/LABEL_021036/RingBuf_SetOffsetLo/g

# =============================================================================
# SUB CPU: DSP Control Routines (6 symbols)
# =============================================================================
s/LABEL_03581D/DSP2_Init/g
s/LABEL_035830/DSP_RingBuf_Read/g
s/LABEL_03585F/DSP_RingBuf_Skip/g
s/LABEL_0360A7/DSP_Reset/g
s/LABEL_02DFA8/DSP_Config_Init/g

# =============================================================================
# SUB CPU: Audio Processing Loop (5 symbols)
# =============================================================================
s/LABEL_035AC8/Audio_Process_DSP/g
s/LABEL_01F8D5/Audio_Process_Final/g
s/LABEL_034CDB/Audio_Process_Init/g
s/LABEL_020C15/InterCPU_Latch_Setup/g
s/LABEL_020C6B/InterCPU_DMA_Send/g

# =============================================================================
# SUB CPU: Additional Voice/Note Helpers (6 symbols)
# =============================================================================
s/LABEL_02C6CD/Voice_SetPitch/g
s/LABEL_02C7D7/Voice_NoteOff/g
s/LABEL_02C8E4/Voice_SetVelocity/g
s/LABEL_02CCAD/Voice_Allocate/g
s/LABEL_02CF07/Voice_ParamInit/g
s/LABEL_029F73/Voice_ModWheel_Apply/g
