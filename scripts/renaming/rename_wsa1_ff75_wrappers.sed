# WSA1 prom_a 0xFF75D3..0xFF7743 (prom_b imports by .set): C-callable display wrappers and two disk-directory drawers.
s/\bsub_FF75D3\b/DisplayList_RunOnLayer_SaveRegs/g
s/\bsub_FF75EF\b/DisplayListB_Run_SaveRegs/g
s/\bsub_FF7604\b/LCD_BlankAndSetPanel3Layer_SaveRegs/g
s/\bsub_FF7623\b/DLB_Array8_2_OnLayer1_SaveRegs/g
s/\bsub_FF763F\b/DLB_Array8_SaveRegs/g
s/\bsub_FF767F\b/Disk_DrawDirectory20/g
s/\bsub_FF76B5\b/Disk_DrawDirEntry/g
s/\bsub_FF770F\b/LCD_DrawDiskFileName6_SaveRegs/g
s/\bsub_FF7729\b/LCD_DrawDiskFileName8_SaveRegs/g
s/\bsub_FF7743\b/UI_ScreenItem_StepByDial/g
