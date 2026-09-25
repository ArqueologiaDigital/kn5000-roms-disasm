# v142 sub-CPU DSP_AlgoType_Dispatch3 arms (2026-09-25).  Evidence: the dispatcher's
# `lda xix,(0x033e44:24) / jp (xix+iy)` makes 0x033E44 the jump BASE (first arm), and the
# arm's own header already says "NOT DATA -- arm block for algorithm types 0..5 and 7".
# The two _Skip targets are the "HL = 0x0040" exits of the E == 0 half: descriptor[0x5D]
# bit 6 clear, and sub-record bit 3 clear.
s/\bDSP_AlgoType_Dispatch3_TableData\b/DSP_AlgoType_D3_Arm_Types0to5_7/g
s/\bDSP_AlgoType_Dispatch3_Skip2\b/DSP_AlgoType_D3_E0_Bit3Clear/g
s/\bDSP_AlgoType_Dispatch3_Skip\b/DSP_AlgoType_D3_E0_DescBit6Clear/g
