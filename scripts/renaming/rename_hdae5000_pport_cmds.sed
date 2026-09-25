# HD-AE5000 PC-link (parallel port) command layer.  The link's command byte
# n = 1..20 (packet 0x239168 byte 0) selects entry n-1 of the 20-pointer
# table at 0x2953CE (`lda xix,(0x2953ce)` + 4*(n-1) in the command loop), and
# every handler first shows its own "NN>..." status record from
# HDAE5000_PPORT_Strings (24-byte stride, PC-link service 26).  The old
# CmdNN_* labels were numbered from the second table label, 5 too low.
#   sed -i -f scripts/renaming/rename_hdae5000_pport_cmds.sed hdae5000/*.s
s/\bHDAE5000_Code_2_PartB\b/HDAE5000_PPORT_Cmd01_SendInfosAboutHd/g
s/\.Lc2b_cmd_format\b/HDAE5000_PPORT_Cmd02_ExitPport/g
s/\.Lc2b_cmd_read_status\b/HDAE5000_PPORT_Cmd03_ReadFsbFromHd/g
s/\.Lc2b_cmd_read_hd\b/HDAE5000_PPORT_Cmd04_SendFsbToPc/g
s/\.Lc2b_cmd_write_hd\b/HDAE5000_PPORT_Cmd05_RcvFsbFromPc/g
s/\bHDAE5000_Cmd01_SendInfo\b/HDAE5000_PPORT_Cmd06_WriteFsbToHd/g
s/\bHDAE5000_Cmd02_Exit\b/HDAE5000_PPORT_Cmd07_LoadHdToMemory/g
s/\bHDAE5000_Cmd03_ReadFSB\b/HDAE5000_PPORT_Cmd08_SendDataToPc/g
s/\bHDAE5000_Cmd04_SendFSB\b/HDAE5000_PPORT_Cmd09_SendFilesToPc/g
s/\bHDAE5000_Cmd05_RcvFSB\b/HDAE5000_PPORT_Cmd10_RcvDataFromPc/g
s/\bHDAE5000_Cmd06_WriteFSB\b/HDAE5000_PPORT_Cmd11_SaveMemoryToHd/g
s/\bHDAE5000_PPORT_Cmd_LoadHDtoMemory\b/HDAE5000_PPORT_Cmd12_Nothing/g
s/\bHDAE5000_PPORT_Cmd_SendDataBlock\b/HDAE5000_PPORT_Cmd13_RcvDataFromPc/g
s/\bHDAE5000_PPORT_Cmd_SendFileList\b/HDAE5000_PPORT_Cmd14_SendInfosToPc/g
s/\bHDAE5000_PPORT_Cmd_ReceiveDataBlock\b/HDAE5000_PPORT_Cmd15_Nothing/g
s/\bHDAE5000_PPORT_Cmd_WriteMemoryToHD\b/HDAE5000_PPORT_Cmd16_DeleteFiles/g
s/\bHDAE5000_PPORT_Cmd_Reserved\b/HDAE5000_PPORT_Cmd17_FormatHd/g
s/\bPPORT_Utility_1\b/HDAE5000_PPORT_Cmd18_SwitchHdMotorOff/g
s/\bPPORT_Utility_2\b/HDAE5000_PPORT_Cmd19_Nothing/g
s/\bPPORT_Utility_3\b/HDAE5000_PPORT_Cmd20_SendXapFileFlash/g
s/\bHDAE5000_PPORT_Cmd_Done\b/HDAE5000_PPORT_CommandDone/g
s/\.Lppe_jump_table\b/HDAE5000_PPORT_CommandTable/g
s/\.Lppe_read_exec\b/HDAE5000_PPORT_CommandLoop/g
s/\.Lppe_poll\b/HDAE5000_PPORT_CommandLoop_Poll/g
s/\.Lppe_write_setup\b/HDAE5000_PPORT_InitPort/g
s/\bHDAE5000_PPORT_Ready_Check\b/HDAE5000_PPORT_ClearPacket/g
s/\bHDAE5000_PPORT_Cleanup\b/HDAE5000_PPORT_FlagPacketError/g
s/\bHDAE5000_PPORT_Sum_Buffer\b/HDAE5000_PPORT_SendPacket/g
s/\bHDAE5000_Render_Display_Region2\b/HDAE5000_PPORT_RequestSongInfo/g
s/\bHDAE5000_Render_Display_Region\b/HDAE5000_PPORT_LatchPacketArgs/g
s/\.Lrdr2_register\b/HDAE5000_PPORT_GetInfoBlock/g
s/\.Lrdr2_main\b/HDAE5000_PPORT_RecvPacket/g
s/\.Lpsb_read_byte\b/HDAE5000_PPORT_RecvByte/g
s/\.Lpsb_write_byte\b/HDAE5000_PPORT_SendByte/g
s/\.Lpsb_finish\b/HDAE5000_PPORT_EndBlock/g
s/\.Lppc_utility\b/HDAE5000_PPORT_CopyInfoToPacket/g
s/\.Lppc_send_bytes\b/HDAE5000_PPORT_SendBlock/g
s/\.Lppc_recv_write_bytes\b/HDAE5000_PPORT_RecvBlock/g
s/\.Lppc_recv_sector_data\b/HDAE5000_PPORT_RecvSector/g
s/\.Lppc_send_regions\b/HDAE5000_PPORT_SendTwoRegions/g
s/\.Lppc_recv_custom_data\b/HDAE5000_PPORT_RecvCustomData/g
s/\.Lppc_init_region_descriptors\b/HDAE5000_PPORT_InitRegionDescriptors/g
s/\.Lppc_compute_sector\b/HDAE5000_PPORT_InitRegionDescriptors_Lookup/g
s/\.Lppc_send_region_to_pc\b/HDAE5000_PPORT_SendRegionToPc/g
