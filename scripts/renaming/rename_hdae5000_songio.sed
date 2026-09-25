# HD-AE5000 song/directory/FLS record layer (0x28F97E-0x2941AB), named from
# what the code does (see each routine's header).  The in-RAM tables are
# described by HDAE5000_HD_GetBlockInfo: directory names 0x201632 (16 B x
# 120), song records 0x201DB2 (76 B x 1920 = 120 dirs x 16 songs: name[26],
# part byte[9] at +26, first-cluster long[9] at +36), FLS rows 0x2257B2
# (144 B x 120: name[16], then 32-item arrays dir+1 / song+1 / +80 / +112).
# Part k (bit k of the masks, slot +36+4k, byte +26+k, flag 0x22AA4E+k,
# UI object RAM_EDIT_<type>) is LSW PMT SQT CMP TM MSP RCM MD TLX for k=0..8.
#   sed -i -f scripts/renaming/rename_hdae5000_songio.sed hdae5000/*.s
s/\bHDAE5000_Calc_Offset_16\b/HDAE5000_DirName_Address/g
s/\bHDAE5000_Copy_To_Table\b/HDAE5000_DirName_SetAndStore/g
s/\bHDAE5000_Get_Display_Dimensions_A1_2F\b/HDAE5000_Dir_IsBlankName/g
s/\bHDAE5000_Count_Invalid_Cells\b/HDAE5000_Dir_CountEmptySongs/g
s/\bHDAE5000_Calculate_Row_Address\b/HDAE5000_SongRecord_Address/g
s/\bHDAE5000_Copy_Display_Cell_90\b/HDAE5000_FlsName_SetAndStore/g
s/\bHDAE5000_Copy_Display_Cell\b/HDAE5000_SongName_SetAndStore/g
s/\bHDAE5000_Calculate_Tile_Address\b/HDAE5000_FlsRecord_Address/g
s/\bHDAE5000_Validate_Cell_Coords\b/HDAE5000_Fls_IsBlankName/g
s/\bHDAE5000_Resolve_Cell_Address\b/HDAE5000_FlsItem_SongRecord/g
s/\bHDAE5000_Cell_In_Bounds\b/HDAE5000_FlsItem_IsSet/g
s/\bHDAE5000_FS_Write_FSB_Helper\b/HDAE5000_FlsItem_Get/g
s/\bHDAE5000_FlsDel1SwCatch_Helper\b/HDAE5000_FlsItem_Clear/g
s/\bHDAE5000_FlsDel2SwCatch_Helper\b/HDAE5000_FlsItem_Remove/g
s/\bHDAE5000_FlsEditScreen_Helper3\b/HDAE5000_FlsItem_SetByte112/g
s/\bHDAE5000_FlsEditScreen_Helper2\b/HDAE5000_FlsItem_SetByte80/g
s/\bHDAE5000_FlsEditScreen_Helper\b/HDAE5000_FlsItem_Insert/g
s/\bHDAE5000_FlsFileSelScreen_Helper2\b/HDAE5000_FlsItem_SetSong/g
s/\bHDAE5000_FlsFileSelScreen_Helper\b/HDAE5000_FlsItem_SetDir/g
s/\bHDAE5000_Table_Calc_Offset\b/HDAE5000_Song_IsUsed/g
s/\bHDAE5000_Table_Lookup\b/HDAE5000_Song_PartMask/g
s/\bHDAE5000_Display_Manager_Helper\b/HDAE5000_LoadSong/g
s/\bHDAE5000_Display_Manager\b/HDAE5000_LoadSongWithUi/g
s/\bHDAE5000_Table_Sub_290753\b/HDAE5000_LoadSong_Lsw/g
s/\bHDAE5000_Table_Sub_2908B1\b/HDAE5000_LoadSong_Pmt/g
s/\bHDAE5000_Table_Sub_290A00\b/HDAE5000_LoadSong_Sqt/g
s/\bHDAE5000_Table_Sub_290B86\b/HDAE5000_LoadSong_Cmp/g
s/\bHDAE5000_Table_Sub_290CB5\b/HDAE5000_LoadSong_Tm/g
s/\bHDAE5000_Table_Sub_290D91\b/HDAE5000_LoadSong_Msp/g
s/\bHDAE5000_Table_Sub_290EC0\b/HDAE5000_LoadSong_Rcm/g
s/\bHDAE5000_Table_Sub_290F45\b/HDAE5000_LoadSong_Md/g
s/\bHDAE5000_Table_Sub_29103D\b/HDAE5000_LoadSong_Tlx/g
s/\bHDAE5000_Display_Scroll_Helper\b/HDAE5000_SaveSong/g
s/\bHDAE5000_Display_Scroll\b/HDAE5000_SaveSongWithUi/g
s/\bHDAE5000_Table_Init_Entry\b/HDAE5000_SaveSong_Lsw/g
s/\bHDAE5000_Table_Sub_2915A3\b/HDAE5000_SaveSong_Pmt/g
s/\bHDAE5000_Table_Sub_29167C\b/HDAE5000_SaveSong_Sqt/g
s/\bHDAE5000_Table_Sub_29175E\b/HDAE5000_SaveSong_Cmp/g
s/\bHDAE5000_Table_Sub_291831\b/HDAE5000_SaveSong_Tm/g
s/\bHDAE5000_Table_Sub_291909\b/HDAE5000_SaveSong_Msp/g
s/\bHDAE5000_Table_Sub_2919DC\b/HDAE5000_SaveSong_Rcm/g
s/\bHDAE5000_Table_Sub_291A62\b/HDAE5000_SaveSong_Md/g
s/\bHDAE5000_Table_Sub_291B33\b/HDAE5000_SaveSong_Tlx/g
s/\bHDAE5000_Table_Sub_291BDE\b/HDAE5000_TlxPart_Describe/g
s/\bHDAE5000_Table_Complex_Init\b/HDAE5000_CheckFileSignature/g
s/\bHDAE5000_FS_Scan_Directory_Helper2\b/HDAE5000_CopyFdSongToHd/g
s/\bHDAE5000_FS_Scan_Directory_Helper\b/HDAE5000_FdSong_CheckFiles/g
s/\bHDAE5000_Table_Sub_292488\b/HDAE5000_CopyFdSongToHd_Lsw/g
s/\bHDAE5000_Table_Sub_2925EF\b/HDAE5000_CopyFdSongToHd_Pmt/g
s/\bHDAE5000_Table_Sub_292798\b/HDAE5000_CopyFdSongToHd_Sqt/g
s/\bHDAE5000_Table_Sub_29293B\b/HDAE5000_CopyFdSongToHd_Cmp/g
s/\bHDAE5000_Table_Sub_292ADE\b/HDAE5000_CopyFdSongToHd_Tm/g
s/\bHDAE5000_Table_Sub_292BFE\b/HDAE5000_CopyFdSongToHd_Msp/g
s/\bHDAE5000_Table_Sub_292D16\b/HDAE5000_CopyFdSongToHd_Rcm/g
s/\bHDAE5000_Table_Sub_292EB9\b/HDAE5000_CopyFdSongToHd_Md/g
s/\bHDAE5000_Table_Sub_292FD2\b/HDAE5000_CopyFdSongToHd_Tlx/g
s/\bHDAE5000_Workspace_Handler\b/HDAE5000_Fls_ForgetSong/g
s/\bHDAE5000_AttenDelDirSwCatch_Helper\b/HDAE5000_DeleteDirectory/g
s/\bHDAE5000_Workspace_Sub_29336B\b/HDAE5000_DeleteSongParts/g
s/\bHDAE5000_Cell_Render_Type0\b/HDAE5000_DeleteSongPart_Lsw/g
s/\bHDAE5000_Cell_Render_Type1\b/HDAE5000_DeleteSongPart_Pmt/g
s/\bHDAE5000_Cell_Render_Type2\b/HDAE5000_DeleteSongPart_Sqt/g
s/\bHDAE5000_Cell_Render_Type3\b/HDAE5000_DeleteSongPart_Cmp/g
s/\bHDAE5000_Cell_Render_Type4\b/HDAE5000_DeleteSongPart_Tm/g
s/\bHDAE5000_Cell_Render_Type5\b/HDAE5000_DeleteSongPart_Msp/g
s/\bHDAE5000_Cell_Render_Type6\b/HDAE5000_DeleteSongPart_Rcm/g
s/\bHDAE5000_Cell_Render_Type7\b/HDAE5000_DeleteSongPart_Md/g
s/\bHDAE5000_Cell_Render_Type8\b/HDAE5000_DeleteSongPart_Tlx/g
s/\bHDAE5000_Cell_Validate\b/HDAE5000_Song_CheckFreeSpace/g
s/\bHDAE5000_Cell_Get_Params\b/HDAE5000_RoundUpToSector/g
s/\bHDAE5000_Display_Callback\b/HDAE5000_HD_StoreTables/g
s/\bHDAE5000_PPI_Write_Sector_Helper\b/HDAE5000_HD_LoadTables/g
s/\bHDAE5000_SetupP2SwCatch_Helper\b/HDAE5000_HD_StoreSettings/g
