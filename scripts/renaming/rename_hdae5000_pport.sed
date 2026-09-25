# rename_hdae5000_pport.sed -- HD-AE5000 PC-link (PPORT) coroutine and its services
#
# The PC link runs as a second execution context on its own stack (RAM 0x23FFFC
# down), switched to and from with two SP swaps.  It asks the main context to run
# HD services by NUMBER (1..30) through a mailbox; the main context polls the
# mailbox once per frame.  25 of the services print their developer's name through
# a compiled-out debug-trace stub (a lone `ret`), which names them.  Evidence is
# in each routine's header.
#
# Apply:  LC_ALL=C sed -i -f scripts/renaming/rename_hdae5000_pport.sed hdae5000/*.s
#
s/\bHDAE5000_Display_Sub_294414\b/HDAE5000_DebugTrace/g
s/\bHDAE5000_Display_String\b/HDAE5000_PPORT_CallService/g
s/\bHDAE5000_PPORT_Init_Main\b/HDAE5000_PPORT_StartLink/g
s/\bHDAE5000_PPORT_Init\b/HDAE5000_PPORT_YieldToMain/g
s/\bHDAE5000_PPORT_Status\b/HDAE5000_PPORT_SwitchToLink/g
s/\bHDAE5000_PPORT_Handler\b/HDAE5000_PPORT_ServicePending/g
s/\bHDAE5000_PPORT_Dispatch\b/HDAE5000_PPORT_ReturnToLink/g
s/\bHDAE5000_PPORT_Setup\b/HDAE5000_PPORT_ServiceDispatch/g
s/\bHDAE5000_PPORT_Menu\b/HDAE5000_PPORT_LinkMain/g
s/\.Lpps_jump_table\b/HDAE5000_PPORT_ServiceTable/g
s/\bHDAE5000_PPORT_Setup_Helper\b/HDAE5000_PPORT_Svc26_ShowStatus/g
s/\bHDAE5000_PPORT_Util\b/HDAE5000_PPORT_Svc27/g
s/\bHDAE5000_PPORT_Setup_Helper26\b/HDAE5000_PPORT_Svc25_ReadFileHD/g
s/\bHDAE5000_PPORT_Setup_Helper25\b/HDAE5000_PPORT_Svc24_ReadOpenHD/g
s/\bHDAE5000_PPORT_Setup_Helper24\b/HDAE5000_PPORT_Svc23_WriteFileHD/g
s/\bHDAE5000_PPORT_Setup_Helper23\b/HDAE5000_PPORT_Svc22_WriteCloseHD/g
s/\bHDAE5000_PPORT_Setup_Helper22\b/HDAE5000_PPORT_Svc21_WriteOpenHD/g
s/\bHDAE5000_PPORT_Setup_Helper21\b/HDAE5000_PPORT_Svc20_PreWholeSongInMemory/g
s/\bHDAE5000_PPORT_Setup_Helper20\b/HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace/g
s/\bHDAE5000_PPORT_Setup_Helper19\b/HDAE5000_PPORT_Svc18/g
s/\bHDAE5000_PPORT_Setup_Helper18\b/HDAE5000_PPORT_Svc17_FormatHd/g
s/\bHDAE5000_PPORT_Setup_Helper17\b/HDAE5000_PPORT_Svc16_InitWholeSongInMemory/g
s/\bHDAE5000_PPORT_Setup_Helper16\b/HDAE5000_PPORT_Svc15_SaveSongInMemoryToHd/g
s/\bHDAE5000_PPORT_Setup_Helper15\b/HDAE5000_PPORT_Svc14_LoadSongFromHdToMemory/g
s/\bHDAE5000_PPORT_Setup_Helper14\b/HDAE5000_PPORT_Svc13_SendInfosAboutSong/g
s/\bHDAE5000_PPORT_Setup_Helper13\b/HDAE5000_PPORT_Svc12_WriteFlsBlockToHd/g
s/\bHDAE5000_PPORT_Setup_Helper12\b/HDAE5000_PPORT_Svc11_WriteFileSystemBlockToHd/g
s/\bHDAE5000_PPORT_Setup_Helper11\b/HDAE5000_PPORT_Svc10_WriteDirBlockToHd/g
s/\bHDAE5000_PPORT_Setup_Helper10\b/HDAE5000_PPORT_Svc09_ReadFlsBlockFromHd/g
s/\bHDAE5000_PPORT_Setup_Helper9\b/HDAE5000_PPORT_Svc08_ReadFileBlockFromHd/g
s/\bHDAE5000_PPORT_Setup_Helper8\b/HDAE5000_PPORT_Svc07_ReadDirBlockFromHd/g
s/\bHDAE5000_PPORT_Setup_Helper7\b/HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock/g
s/\bHDAE5000_PPORT_Setup_Helper6\b/HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock/g
s/\bHDAE5000_PPORT_Setup_Helper5\b/HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock/g
s/\bHDAE5000_PPORT_Setup_Helper4\b/HDAE5000_PPORT_Svc03_SendInfosAboutHd/g
s/\bHDAE5000_PPORT_Setup_Helper3\b/HDAE5000_PPORT_Svc02_TurnHdMotorOff/g
s/\bHDAE5000_PPORT_Setup_Helper2\b/HDAE5000_PPORT_Svc01_GetInfoBlockPointer/g
