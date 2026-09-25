# HD-AE5000 screen helpers in hd-ae5000_v2_06i.s / hdae5000_hd_driver.s /
# hdae5000_filesystem.s whose earlier names were guesses (HD_Seek,
# PPI_Read_Sector, FS_Read_FSB ...).  Each new name is argued in the
# routine's header from its own code and the ROM strings/templates it uses.
#   sed -i -f scripts/renaming/rename_hdae5000_screens.sed hdae5000/*.s
s/\bHDAE5000_Event_Handler\b/HDAE5000_HardTest_Print/g
s/\bHDAE5000_PPI_Transfer_Byte\b/HDAE5000_PPI_LoopbackByte/g
s/\bHDAE5000_PPI_Read_Register\b/HDAE5000_HardTest_PortTest/g
s/\bHDAE5000_PPI_Write_Sector\b/HDAE5000_HardTest_HddIdRead/g
s/\bHDAE5000_PPI_Read_Sector\b/HDAE5000_FdList_Clear/g
s/\bHDAE5000_PPI_Transfer_Block\b/HDAE5000_FdName_SongNumber/g
s/\bHDAE5000_HD_Setup_Drive\b/HDAE5000_FdList_Scan/g
s/\bHDAE5000_HD_Read_Identify\b/HDAE5000_TitleInfo_Build/g
s/\bHDAE5000_HD_Format_Params\b/HDAE5000_DirList_BuildPage/g
s/\bHDAE5000_HD_Seek\b/HDAE5000_PartList_Build/g
s/\bHDAE5000_HD_Read_Write\b/HDAE5000_SongScreen_Refresh/g
s/\bHDAE5000_HD_Error_Check\b/HDAE5000_PcLink_ShowStatus/g
s/\bHDAE5000_HD_Wait_Ready\b/HDAE5000_SeparateOutput_SendPartMsg/g
s/\bHDAE5000_HD_Status_Check\b/HDAE5000_SeparateOutput_Apply/g
s/\bHDAE5000_HD_Data_Copy\b/HDAE5000_TypeSel_Init/g
s/\bHDAE5000_HD_Buffer_Init\b/HDAE5000_TypeSel_BuildMask/g
s/\bHDAE5000_HD_Config_Manager\b/HDAE5000_TypeSel_ShowSaveFlags/g
s/\bHDAE5000_HD_Partition_Setup\b/HDAE5000_SetupPage_BuildDriveInfo/g
s/\bHDAE5000_HD_CHS_Calculate\b/HDAE5000_FormatDialog_CodeDigit/g
s/\bHDAE5000_HD_Sector_Read\b/HDAE5000_Lbn_StepDigit/g
s/\bHDAE5000_HD_Sector_Write\b/HDAE5000_Lbn_TypeDigit/g
s/\bHDAE5000_FS_Init\b/HDAE5000_Lbn_ShowEntry/g
s/\bHDAE5000_FS_Read_FSB\b/HDAE5000_FlsList_BuildPage/g
s/\bHDAE5000_FS_Write_FSB\b/HDAE5000_FlsScreen_Refresh/g
s/\bHDAE5000_FS_Buffer_Setup\b/HDAE5000_FdList_Redisplay/g
s/\bHDAE5000_FS_Scan_Directory\b/HDAE5000_CopyToHd_Execute/g
s/\bHDAE5000_FS_Entry_Lookup\b/HDAE5000_DelOpt_ShowFlags/g
s/\bHDAE5000_Display_Update_Offset\b/HDAE5000_DelOpt_InitFromSong/g
