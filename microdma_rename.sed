# MicroDMA-related symbol renaming script
# Apply with: sed -i -f microdma_rename.sed subcpu/kn5000_subprogram_v142.asm

# Core InterCPU DMA routines
s/LABEL_020DB3/InterCPU_E1_DMA_Transfer/g
s/LABEL_020CB0/InterCPU_DMA_Send_Chunk/g

# DAC output routine
s/LABEL_021023/DAC_Write_Sample/g

# Wait loops within DMA routines
s/LABEL_020CFA/InterCPU_Wait_MSTAT1_Clear/g
s/LABEL_020D05/InterCPU_Wait_MSTAT1_Set/g

# Local labels within InterCPU_E1_DMA_Transfer (convert to local names)
s/LABEL_020DBD/E1_Wait_DMA_Idle/g
s/LABEL_020DCF/E1_DMA_Ready/g
s/LABEL_020DD1/E1_Check_MSTAT1/g
s/LABEL_020DE7/E1_Start_Transfer/g
s/LABEL_020E19/E1_Wait_State1/g
s/LABEL_020E20/E1_Delay_Loop1/g
s/LABEL_020E28/E1_Delay1/g
s/LABEL_020E31/E1_Phase2_Setup/g
s/LABEL_020E4F/E1_Wait_Complete/g
s/LABEL_020E56/E1_Delay_Loop2/g
s/LABEL_020E5E/E1_Delay2/g
s/LABEL_020E67/E1_Done/g
s/LABEL_020E69/E1_Timeout_Retry/g
s/LABEL_020E76/E1_Busy_Wait/g
s/LABEL_020E84/E1_Exit/g

# Local labels within InterCPU_DMA_Send (already has semantic name)
s/LABEL_020C7C/DMA_Send_Loop/g
s/LABEL_020C9C/DMA_Send_Final/g
s/LABEL_020CB6/DMA_Chunk_Start/g
s/LABEL_020CD3/DMA_Chunk_Transfer/g
s/LABEL_020CF2/DMA_Chunk_Wait/g
