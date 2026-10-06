# TmFlash_WriteRoutine writes nothing: it locates a slot of the section-7 slot store (helper-naming batch g finding)
s/\bTmFlash_WriteRoutine_Entry_Code_Entry\b/Flash_GetSlotAddressAndSize_RamSmallBlock/g
s/\bTmFlash_WriteRoutine_Entry_Code_Join\b/Flash_GetSlotAddressAndSize_StoreSize/g
s/\bTmFlash_WriteRoutine_Entry\b/Flash_GetSlotAddressAndSize_FlashSmallSlot/g
s/\bTmFlash_WriteRoutine_Skip2\b/Flash_GetSlotAddressAndSize_RamBlock/g
s/\bTmFlash_WriteRoutine_Skip\b/Flash_GetSlotAddressAndSize_OutOfRange/g
s/\bTmFlash_WriteRoutine_Join\b/Flash_GetSlotAddressAndSize_Join/g
s/\bTmFlash_WriteRoutine\b/Flash_GetSlotAddressAndSize/g
