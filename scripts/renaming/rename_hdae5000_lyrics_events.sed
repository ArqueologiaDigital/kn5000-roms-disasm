# hdae5000: the lyrics player and the main-CPU event helpers, renamed from
# what their code does (lane hdae, 2026-09-25).  Evidence in each routine's
# header; the main-CPU function names come from
# scripts/converters/hdae5000_symbolize_fn_tables.py.
s/\bHDAE5000_File_Operation\b/HDAE5000_Lyrics_PlayToPosition/g
s/\bHDAE5000_File_Save\b/HDAE5000_Lyrics_ResetState/g
s/\bHDAE5000_File_Load\b/HDAE5000_Lyrics_ReadSongInfo/g
s/\bHDAE5000_File_Delete\b/HDAE5000_Lyrics_FillLines/g
s/\bHDAE5000_File_Rename\b/HDAE5000_Lyrics_FindEvent/g
s/\bHDAE5000_File_Format\b/HDAE5000_Lyrics_ParseEvent/g
s/\bHDAE5000_Calc_Disk_Space\b/HDAE5000_Lyrics_ReadVarLen/g
s/\bHDAE5000_Display_Notify\b/HDAE5000_Lyrics_CheckHeaderChunk/g
s/\bHDAE5000_Display_Progress\b/HDAE5000_Lyrics_CheckTrackChunk/g
s/\.LDisplay_Progress__ok\b/.LLyrics_CheckTrackChunk__ok/g
s/\bHDAE5000_Display_Error\b/HDAE5000_Lyrics_ClearBuffer/g
s/\bHDAE5000_String_To_Upper\b/HDAE5000_SwapBytes32/g
s/\.LString_To_Upper__loop\b/.LSwapBytes32__loop/g
s/\bHDAE5000_String_Compare\b/HDAE5000_SwapBytes16/g
s/\bHDAE5000_Menu_Register_A\b/HDAE5000_RequestMode/g
s/\bHDAE5000_Menu_Register_B\b/HDAE5000_RequestTitle15/g
s/\bHDAE5000_HD_Shutdown\b/HDAE5000_ShowErrorMessageTitle/g
s/\bHDAE5000_Menu_Handler\b/HDAE5000_DirName_StoreWithUi/g
s/\bHDAE5000_Menu_Callback\b/HDAE5000_FlsName_StoreWithUi/g
s/\bHDAE5000_Wait_Callback_Loop\b/HDAE5000_YieldUntilSem1Zero/g
s/\.LWait_Callback__invoke\b/.LYieldUntilSem1Zero__yield/g
s/\.LWait_Callback__poll\b/.LYieldUntilSem1Zero__poll/g
s/\bHDAE5000_Get_Table_Entry\b/HDAE5000_NameHistory_Push/g
s/\bHDAE5000_Validate_String\b/HDAE5000_NameHistory_Recall/g
s/\.LValidate_String__/.LNameHistory_Recall__/g
s/\bHDAE5000_Dir_EntrySlots\b/HDAE5000_LyricLines_Init/g
s/\bHDAE5000_Workspace_Ptr_Init\b/HDAE5000_LyricBoxObj_Init/g
