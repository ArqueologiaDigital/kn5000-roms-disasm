# hdae5000: the floppy lyric-file list (LOAD LYRICS FROM FD) and the version
# string copier, renamed from their code (lane hdae, 2026-09-25).
s/\bHDAE5000_Path_Builder\b/HDAE5000_FdLyricList_Scan/g
s/\bHDAE5000_Directory_Handler\b/HDAE5000_FdLyricList_AddTlx/g
s/\bHDAE5000_Display_Clear__loop\b/HDAE5000_CopyVersionString__loop/g
s/\bHDAE5000_Display_Clear__push\b/HDAE5000_CopyVersionString__len/g
s/\bHDAE5000_Display_Clear\b/HDAE5000_CopyVersionString/g
s/\bHDAE5000_Str_Rb_Path_Builder_2\b/HDAE5000_Str_Rb_FdLyricMid/g
s/\bHDAE5000_Str_Rb_Path_Builder\b/HDAE5000_Str_Rb_FdLyricTtx/g
s/\bread by Path_Builder\b/read by FdLyricList_Scan/g
s/\bread by Directory_Handler\b/read by FdLyricList_AddTlx/g
s/\bread by Display_Clear\b/read by CopyVersionString/g
