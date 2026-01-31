# Table data ROM label renames
s/LABEL_800000/TableData_BootRegionReserved/g
s/LABEL_88000C/HKstSSF_Padding/g
s/LABEL_9FA000/FileIdentifierStringsTable/g
s/LABEL_9FA150/BootscreenSlideMarker/g
# Note: Don't rename hkst_55 as it's used as both a label and a filename
# s/hkst_55/FeatureDemo_FileMetadata/g
s/Compressed_data/SubCPU_Payload_Compressed_LZSS/g
s/ClearMemoryBlockWith0/MemBlock_FillWithZeros/g
s/Boot_Stub_Return0_1/BootStub_ReturnSuccessSlot1/g
s/Boot_Stub_Return0_2/BootStub_ReturnSuccessSlot2/g
s/Boot_Stub_Return0_3/BootStub_ReturnSuccessSlot3/g
s/Boot_Stub_Return0_4/BootStub_ReturnSuccessSlot4/g
s/Boot_Stub_ReturnFFFF/BootStub_ReturnError/g
s/Draw_Bitmap/DrawBitmap_UpdateDisplay/g
s/Init_Display_Progress/InitProgressDisplay_FillRegion/g
s/VGA_Init_Epilogue/VGA_FinalizeInitialization/g
s/Handler_INTTC3/BootTimer_InterruptHandler/g
s/Boot_ProgramHDAE_Part1/Flash_ProgramHDAE_Initialization/g
s/Boot_ProgramHDAE_Part2/Flash_ProgramHDAE_Payload/g
s/Boot_InitHDAE_PPI/HDAE5000_InitializeParallelPort/g
s/Boot_FindValidBlock/Flash_SearchFirstNonEmptyBlock/g
