# WSA1 prom_a 0xFF7776..0xFF78B5: disk-directory helpers and C-callable LCD / memory wrappers.
s/\bsub_FF7776\b/Disk_FormatSelectedEntry_SaveRegs/g
s/\bsub_FF7783\b/Disk_FormatSelectedEntry/g
s/\bsub_FF77A7\b/Disk_DirEntryPtr/g
s/\bsub_FF77BC\b/Disk_SetStatusFromCheck/g
s/\bsub_FF77E3\b/Disk_CheckSelectedEntrySignature/g
s/\bsub_FF7826\b/Disk_CopyDirEntryToFileName/g
s/\bsub_FF7832\b/Disk_CopyEntry2724HeadToFileName_SaveRegs/g
s/\bsub_FF7846\b/LCD_DrawVar272ENumberTag_SaveRegs/g
s/\bsub_FF7895\b/LCD_SwiTextCall_SaveRegs/g
s/\bsub_FF78B5\b/MemCpy_C/g
