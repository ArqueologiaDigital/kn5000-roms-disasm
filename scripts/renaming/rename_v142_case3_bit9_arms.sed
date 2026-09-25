# The bit-9 test in the TVF_Emit_Registers / Voice_PanReg_WriteDispatchB landing pads is CASE 3
# (TVF_Emit_Registers_CaseOffsets / Voice_PanReg_WriteDispatchB_CaseOffsets entry 3 = +0x1B),
# not case 2: entries 1 and 2 share the TVF_Emit_Offset_Reg100 body at +0x13.
s/\bVoice_PanReg_Dispatch_Mode2_CheckBit9\b/TVF_Emit_Registers_Case3_Bit9Clear/g
s/\bVoice_PanReg_DispatchB_Mode2_CheckBit9\b/Voice_PanReg_WriteDispatchB_Case3_Bit9Clear/g
