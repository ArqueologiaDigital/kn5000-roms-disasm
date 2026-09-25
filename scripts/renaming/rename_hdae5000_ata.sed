# rename_hdae5000_ata.sed -- HD-AE5000 IDE/ATA driver and filesystem-table I/O
#
# 0x2971B7-0x297E15 was named "RAM_Test" + Helper/Join numbers after its
# first 60 bytes (an SRAM pattern test).  It is the HD bring-up and the ATA
# register-level driver: status polling at 0x13001E, commands 0x20/0x30/0x94/
# 0xEC, device control 0x130020, error flag 0x200222.  Evidence per routine
# is in its header.
#
# Apply:  LC_ALL=C sed -i -f scripts/renaming/rename_hdae5000_ata.sed hdae5000/*.s
#
# --- HD bring-up (was RAM_Test) ---
s/\bHDAE5000_RAM_Test_Join8\b/HDAE5000_HD_Init_Fail/g
s/\bHDAE5000_RAM_Test_Join7\b/HDAE5000_HD_Init_Exit/g
s/\bHDAE5000_RAM_Test_Join6\b/HDAE5000_HD_Init_ClearLoop2/g
s/\bHDAE5000_RAM_Test_Join5\b/HDAE5000_HD_Init_ClearLoop1/g
s/\bHDAE5000_RAM_Test_Join4\b/HDAE5000_HD_Init_SpaceFillLoop/g
s/\bHDAE5000_RAM_Test_Join3\b/HDAE5000_HD_Init_SramClearLoop/g
s/\bHDAE5000_RAM_Test_Join2\b/HDAE5000_HD_Init_SramVerifyLoop/g
s/\bHDAE5000_RAM_Test_Join\b/HDAE5000_HD_Init_SramFillLoop/g
s/\bHDAE5000_RAM_Test\b/HDAE5000_HD_Init/g
# --- ATA primitives ---
s/\bHDAE5000_RAM_Test_Join9\b/HDAE5000_ATA_WaitReady_Poll/g
s/\bHDAE5000_RAM_Test_Helper\b/HDAE5000_ATA_WaitReady/g
s/\bHDAE5000_Table_Lookup_Helper\b/HDAE5000_ATA_SoftReset_Status/g
s/\bHDAE5000_RAM_Test_Return\b/HDAE5000_ATA_SoftReset_Return/g
s/\bHDAE5000_RAM_Test_Helper2\b/HDAE5000_ATA_SoftReset/g
s/\bHDAE5000_Display_Callback_Helper\b/HDAE5000_ATA_Standby_Status/g
s/\bHDAE5000_RAM_Test_Helper3\b/HDAE5000_ATA_Standby/g
s/\bHDAE5000_RAM_Test_Join13\b/HDAE5000_ATA_WriteSector_WaitReady/g
s/\bHDAE5000_RAM_Test_Join14\b/HDAE5000_ATA_WriteSector_WaitDrq/g
s/\bHDAE5000_RAM_Test_Join15\b/HDAE5000_ATA_WriteSector_DataLoop/g
s/\bHDAE5000_RAM_Test_Join16\b/HDAE5000_ATA_WriteSector_WaitDone/g
s/\bHDAE5000_HD_Config_Init_Values_Helper\b/HDAE5000_ATA_WriteSector/g
s/\bHDAE5000_RAM_Test_Join17\b/HDAE5000_ATA_ReadSector_WaitReady/g
s/\bHDAE5000_RAM_Test_Join18\b/HDAE5000_ATA_ReadSector_WaitDrq/g
s/\bHDAE5000_RAM_Test_Join19\b/HDAE5000_ATA_ReadSector_DataLoop/g
s/\bHDAE5000_RAM_Test_Join20\b/HDAE5000_ATA_ReadSector_WaitDone/g
s/\bHDAE5000_RAM_Test_Helper6\b/HDAE5000_ATA_ReadSector/g
s/\bHDAE5000_RAM_Test_Join21\b/HDAE5000_ATA_Identify_WaitReady/g
s/\bHDAE5000_RAM_Test_Join22\b/HDAE5000_ATA_Identify_WaitDrq/g
s/\bHDAE5000_RAM_Test_Join23\b/HDAE5000_ATA_Identify_DataLoop/g
s/\bHDAE5000_RAM_Test_Join24\b/HDAE5000_ATA_Identify_WaitDone/g
s/\bHDAE5000_RAM_Test_Helper7\b/HDAE5000_ATA_IdentifyDevice/g
# --- drive geometry and signature sector ---
s/\bHDAE5000_RAM_Test_Join10\b/HDAE5000_HD_CheckSignature_Done/g
s/\bHDAE5000_RAM_Test_Helper4\b/HDAE5000_HD_CheckSignature/g
s/\bHDAE5000_PPI_Write_Sector_Helper2\b/HDAE5000_HD_GetGeometry/g
s/\bHDAE5000_RAM_Test_Join11\b/HDAE5000_HD_ParseIdentify_ClusterSet/g
s/\bHDAE5000_RAM_Test_Join12\b/HDAE5000_HD_ParseIdentify_ModelLoop/g
s/\bHDAE5000_RAM_Test_Helper5\b/HDAE5000_HD_ParseIdentify/g
# --- CHS arithmetic ---
s/\bHDAE5000_HD_Init_Variables\b/HDAE5000_HD_Mul32/g
s/\bHDAE5000_HD_Config_Init_Values\b/HDAE5000_HD_UDiv32/g
# --- filesystem tables (323 sectors at RAM 0x201632) and FAT scan ---
s/\.Lhciv_mem_init\b/HDAE5000_HD_InitTables/g
s/\.Lhciv_hd_check\b/HDAE5000_HD_WriteTables_Status/g
s/\.Lhciv_hd_config_init\b/HDAE5000_HD_WriteTables/g
s/\bHDAE5000_HD_Detect_Drive\b/HDAE5000_HD_WriteTables_Next/g
s/\.Lhdd_wrapper2\b/HDAE5000_HD_ReadTables_Status/g
s/\.Lhdd_config_init2\b/HDAE5000_HD_ReadTables/g
s/\.Lhdd_wrapper3\b/HDAE5000_HD_CountFreeClusters_Status/g
s/\.Lhdd_count_sectors\b/HDAE5000_HD_CountFreeClusters/g
