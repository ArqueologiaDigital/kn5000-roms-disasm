# v142 sub-CPU, 2026-09-25, after convert_v142_byte_block.py turned two more .byte runs into code:
#  - Voice_ParamFinalize_Skip3: symboliser's name for the join after case 1's offset-0x5D special
#    case inside VoiceParam_Query_Case1_PatchRec.
#  - DSP_RingBuf_Read_Data: `lda xwa,(0x3b60:16) / jr DSP_RingBuf_Read` -- a read wrapper for the
#    ring whose control block is at 0x3B60 (see the CORRECTED note at the label).
s/\bVoice_ParamFinalize_Skip3\b/VoiceParam_Query_Case1_PatchRec_Done/g
s/\bDSP_RingBuf_Read_Data\b/DSP_RingBuf3B60_Read/g
