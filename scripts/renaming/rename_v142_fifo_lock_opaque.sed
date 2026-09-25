# Sub-CPU v1.42, 2026-09-25 (lane subcpu).  Each new name restates the routine's own header.
#  - RingBuf_Control_Opaque: header "incw 1,(0x10D2) -- take the scheduler lock"; its twin
#    right below is already TaskSched_Unlock.
#  - RingBuf_ReadWrite_Opaque_A / _B / AudioBuf_PtrUtils: headers "read index -> mark cursor" of
#    the 1 KB / 256 B / 512 B FIFOs whose Get_Marked / Get_From_Mark routines follow.
#  - *_Opaque_*_Code_Loop: symboliser sub-labels left behind when their parents were renamed
#    (RingBuf_Access_Opaque_A -> TaskSched_TerminateTask, InterCPU_LatchProtocol_Opaque ->
#    InterCPU_Send_E3_Command, rename_v142_converted_blocks.sed); named after where they sit now.
s/\bRingBuf_Control_Opaque\b/TaskSched_Lock/g
s/\bRingBuf_ReadWrite_Opaque_A\b/FIFO1K_SetMark/g
s/\bRingBuf_ReadWrite_Opaque_B\b/FIFO256_SetMark/g
s/\bAudioBuf_PtrUtils\b/FIFO512_SetMark/g
s/\bRingBuf_Access_Opaque_A_Code_Loop\b/Timer_Delay_Ticks_Loop/g
s/\bInterCPU_LatchProtocol_Opaque_Code_Loop2\b/InterCPU_E2_Gate2/g
s/\bInterCPU_LatchProtocol_Opaque_Code_Loop\b/InterCPU_E3_RaiseSSTAT0/g
