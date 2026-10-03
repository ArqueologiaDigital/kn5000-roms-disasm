# DisplayStr_BytecodeBlock_E + 1 copies the current style section's name (DisplayStr_StyleSectionNames[(0x3728)])
# into the display buffer at 0x0ED4; SeMenu_OrPartConfig_Data (+0) sets bit 3 of (0xE3E2) and +6 returns it.
s/\bDisplayStr_BytecodeBlock_E_0x1\b/DisplayStr_CopyStyleSectionName/g
s/\bSeMenu_OrPartConfig_Data_0x6\b/SeMenu_GetPartConfigBit3/g
s/\bSeMenu_OrPartConfig_Data\b/SeMenu_SetPartConfigBit3/g
