# HD-AE5000 UI helpers whose names were guesses.
#   sed -i -f scripts/renaming/rename_hdae5000_uimisc.sed hdae5000/*.s
s/\bHDAE5000_UI_Main_Handler\b/HDAE5000_UiObj_SetCaption/g
s/\bHDAE5000_Register_Frame\b/HDAE5000_UiState_Reset/g
s/\bHDAE5000_Dir_Format_Setup\b/HDAE5000_PPORT_Svc28_FlashXapFile/g
s/\bHDAE5000_Dir_Flush\b/HDAE5000_PPORT_Svc29_MainHook0538/g
s/\bHDAE5000_Dir_Close\b/HDAE5000_PPORT_Svc30_MainHook053C/g
