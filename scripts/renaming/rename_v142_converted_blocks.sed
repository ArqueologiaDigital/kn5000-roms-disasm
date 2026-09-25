# v142 sub-CPU, 2026-09-25: routines converted from .byte by convert_v142_byte_block.py get
# names that say what their (already written) headers say they do.  Evidence per rule:
#  - RingBuf_Access_Opaque_A: its header says "Terminate task A"; WSA1 prom_c's Kernel_KillTask
#    matches this address at 0.909 (wsa1/notes/FINDINGS-kernel-in-the-kn5000.md, section 3).
#  - RingBuf_WrappedRead_Opaque_A/B/C: engine GET of the 256/512/1K FIFOs -- pop at the read
#    index (XDE-8) until it meets the write index (XDE-4), then bump the free count (XDE-2);
#    siblings FIFO_Engine*_Get_Marked / _Get_From_Mark / _Put were already named that way.
#  - VoiceState_OpaqueData1: header "Builds the packed 16-bit part handle".
#  - VoiceDispatch_OpaqueData: header "DECODE A 2-BIT FIELD OUT OF THE 0x47-BYTE PER-VOICE
#    PARAMETER RECORD" (bits 6..7 of the record's first word -> 0..3).
#  - EGEnv_OpaqueData: header "BYTE-IDENTICAL DUPLICATE of EGEnv_Compute_A_Simple".
#  - DSP_State_Dispatcher_Data: header "not data, it is a complete 18-byte routine ...
#    A config-block SNAPSHOT/SAVE"; its inverse is EFF_ConfigSnapshot_Restore.
#  - DSP_Translator_JumpTable: header "These 26 bytes are the OPCODE 0x61 ARM, not a jump
#    table"; opcode 0x61 is the linear-eval translator op (DSP zone header).
#  - InterCPU_LatchProtocol_Opaque: header "Sends the single command byte 0xE3 to the main CPU".
#  - InterCPU_DMA_Send_Chunk_Loop / DSP_AlgoType_Dispatch3_Skip2 / *_Skip: structural names the
#    branch symboliser gave targets inside the newly converted code.
s/\bRingBuf_Access_Opaque_A\b/TaskSched_TerminateTask/g
s/\bRingBuf_WrappedRead_Opaque_A_Skip\b/FIFO_Engine256_Get_NotEmpty/g
s/\bRingBuf_WrappedRead_Opaque_A\b/FIFO_Engine256_Get/g
s/\bRingBuf_WrappedRead_Opaque_B_Skip\b/FIFO_Engine512_Get_NotEmpty/g
s/\bRingBuf_WrappedRead_Opaque_B\b/FIFO_Engine512_Get/g
s/\bRingBuf_WrappedRead_Opaque_C_Skip\b/FIFO_Engine1K_Get_NotEmpty/g
s/\bRingBuf_WrappedRead_Opaque_C\b/FIFO_Engine1K_Get/g
s/\bFIFO_Engine\(256\|512\|1K\)_Get_Marked_Skip\b/FIFO_Engine\1_Get_Marked_NotEmpty/g
s/\bFIFO_Engine\(256\|512\|1K\)_Get_From_Mark_Skip\b/FIFO_Engine\1_Get_From_Mark_NotEmpty/g
s/\bFIFO_Engine\(256\|512\|1K\)_Put_Skip\b/FIFO_Engine\1_Put_HasRoom/g
s/\bVoiceState_OpaqueData1_Skip\b/Voice_MakePartHandle_NoRefresh/g
s/\bVoiceState_OpaqueData1_Epilogue\b/Voice_MakePartHandle_Epilogue/g
s/\bVoiceState_OpaqueData1\b/Voice_MakePartHandle/g
s/\bVoiceDispatch_Field_Is3\b/VoiceRec_Decode2BitField_Is3/g
s/\bVoiceDispatch_OpaqueData_Return\b/VoiceRec_Decode2BitField_Return/g
s/\bVoiceDispatch_OpaqueData\b/VoiceRec_Decode2BitField/g
s/\bEGEnv_OpaqueData\b/EGEnv_Compute_A_Simple_Dup/g
s/\bDSP_State_Dispatcher_Data\b/EFF_ConfigSnapshot_Save/g
s/\bDSP_Translator_JumpTable\b/DSP_Op_0x61_LinearEval/g
s/\bInterCPU_LatchProtocol_Opaque\b/InterCPU_Send_E3_Command/g
s/\bInterCPU_DMA_Send_Chunk_Loop\b/InterCPU_E2_Wait_DMA_Done_Spin/g
s/\bDSP_AlgoType_Dispatch3_Skip2\b/DSP_AlgoType_D3_Arm_TypeAB_Bit3Clear/g
