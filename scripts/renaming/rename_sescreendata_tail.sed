# flash_floppy_handlers.s opens with the TAIL of the sound editor's ScreenData block
# (0xF158A7-0xF165EA, base SeScreenData 0xF10C06), not with flash handlers.  Three of its
# labels kept flash names from an early guess; they are a list-boundary table and two
# ScreenData records, named like the block's other records.  Same offsets in v10/v9/v7.
s/\bFlashWrite_BlockHandler_Table\b/SeScreenData_ListBounds/g
s/\bFlashRead_BlockHandler_Table\b/SeScreenData_0x4D89/g
s/\bFlashWrite_BlockRef_Type6\b/SeScreenData_0x4E8B/g
