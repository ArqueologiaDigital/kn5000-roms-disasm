# Rename subcpu DSP labels from LABEL_XXXXXX placeholders to semantic names
# Generated from diff between sound subsystem and roms-disasm subcpu assembly

# Audio main loop
s/LABEL_01FAE6/Audio_Main_Loop/g

# ToneGen functions
s/LABEL_02D101/ToneGen_WriteVoiceParams/g
s/LABEL_02D41B/ToneGen_WriteSingleReg/g
s/LABEL_02D7C7/ToneGen_WriteGlobalConfig/g
s/LABEL_02DA16/ToneGen_WriteExtParams_56/g
s/LABEL_02DB33/ToneGen_WriteExtParams_56b/g
s/LABEL_02DC50/ToneGen_WriteExtParams_15/g
s/LABEL_02DFCF/ToneGen_Config_Init/g

# DSP ring buffer and command parsing
s/LABEL_035910/DSP_RingBuf_Enqueue/g
s/LABEL_035936/Extract_14Bit_PayloadSize/g
s/LABEL_03597D/Extract_14Bit_VoiceParam/g
s/LABEL_035997/DSP_Cmd_DequeueHeader/g
s/LABEL_0359DB/DSP_Cmd_LoadEffectPreset/g
s/LABEL_035A7E/DSP_RingBuf_ReadAndCompare/g

# DSP apply, reconfig, config/slot buffers
s/LABEL_03616A/DSP_ApplyConfig/g
s/LABEL_0361C5/DSP_ReconfigAndStatus/g
s/LABEL_0361D4/DSP_GetConfigBuffer/g
s/LABEL_0361D9/EFF_GetSlotBuffer/g

# DSP delay
s/LABEL_036305/DSP_WaitForDelay/g

# DSP2 send command/data
s/LABEL_03666B/DSP2_Send_Command/g
s/LABEL_0368BA/DSP2_Send_Data/g

# DSP dispatch command/data
s/LABEL_036A2E/DSP_DispatchCommand/g
s/LABEL_036A4F/DSP_DispatchData/g

# EFF state load
s/LABEL_03774E/EFF_StateLoad_Prepare/g

# EFF/DSP loops and handlers (DSP_State_Dispatcher sub-routines)
s/LABEL_037760/EFF_MuteLoop/g
s/LABEL_0377D8/DSP_ResetLoop/g
s/LABEL_0377ED/DSP_MuteLoop/g
s/LABEL_037814/DSP_UnmuteLoop/g
s/LABEL_03783B/DSP_AlgorithmChangeCheck/g
s/LABEL_037848/Unsigned_Max_Select/g
s/LABEL_037851/EFF_ParamIterator_Process/g
s/LABEL_03798B/EFF_VolumeChange_Check/g
s/LABEL_0379A7/EFF_Change_Handler/g
s/LABEL_037A67/EFF_HeaderChangeDataLoop/g
s/LABEL_037AE6/EFF_LinkLoop/g
s/LABEL_037B3D/EFF_SecondaryLinkPath/g
s/LABEL_037C25/EFF_VolumeLoop/g
s/LABEL_037D40/EFF_DisconnectLoop/g

# Master DSP state dispatcher
s/LABEL_037D6E/DSP_State_Dispatcher/g
s/LABEL_037E30/DSP_State_LookupAlgoIndex/g
s/LABEL_037E3E/DSP_State_Dispatcher_Data/g

# Debug print routines
s/LABEL_037E62/DSP_Reset_WithDebug/g
s/LABEL_037E93/DSP_AntiReset_WithDebug/g
s/LABEL_037EB4/EFF_Mute_WithDebug/g
s/LABEL_037EE9/DSP_Mute_WithDebug/g
s/LABEL_037F1C/DSP_Unmute_WithDebug/g
s/LABEL_037F4F/EFF_Disconnect/g
s/LABEL_037FAE/EFF_Link/g
s/LABEL_03800D/DSP_AlgorithmChange/g
s/LABEL_0380AB/EFF_WriteHeader/g
s/LABEL_0380EC/EFF_Change_WithDebug/g
s/LABEL_0381BC/EFF_DataChange_WithDebug/g
s/LABEL_038200/EFF_ParamEdit_WithDebug/g
s/LABEL_03826E/EFF_VolumeUpdate_WithDebug/g

# DSP schedule delay
s/LABEL_038392/DSP_ScheduleDelay/g

# DSP write functions (bytecode-driven)
s/LABEL_03C161/DSP_WriteEFFConfig/g
s/LABEL_03C181/DSP_WriteGlobalConfig/g
s/LABEL_03C190/DSP_WriteParameter/g

# DSP bytecode interpreter
s/LABEL_03C253/DSP_Bytecode_NotifyStateChange/g
s/LABEL_03C259/DSP_BytecodeInterpreter_Init/g
s/LABEL_03C2CB/DSP_BytecodeInterpreter_Loop/g
s/LABEL_03C32E/DSP_Bytecode_Programs/g
s/LABEL_03C97B/DSP_Bytecode_Op0D_StateChange/g
s/LABEL_03C984/DSP_Bytecode_Op0E_SendCommand/g
s/LABEL_03C9AA/DSP_Bytecode_Op0E_DataLoop/g
s/LABEL_03C9CE/DSP_BytecodeInterpreter_CheckEnd/g

# DSP parameter write engine
s/LABEL_03C9E6/DSP_ParameterWriteEngine/g
s/LABEL_03CAAE/DSP_PerParameterTranslator/g

# DMA macro name corrections (swap DMAM↔DMAC where both names exist in inc)
# Note: LDC_DMAC2_XWA→LDC_DMAM2_A, LDC_DMAC0_A→LDC_DMAM0_A, and
# LDC_WA_DMAM0→LDC_WA_DMAC0 require updating tmp94c241.inc first (separate task).
s/LDC_DMAM2_BC/LDC_DMAC2_BC/g
s/LDC_DMAM2_WA/LDC_DMAC2_WA/g
s/LDC_DMAM0_WA/LDC_DMAC0_WA/g
