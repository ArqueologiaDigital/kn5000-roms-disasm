
; Multilingual Disk Operation Warning Strings (30 widgets, 16430 bytes)
; Source: maincpu/ui_widgets/naka_disk_warning.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_disk_warning
; How these pieces were identified
; (scripts/analysis/nakarest_objtab_map.py): every RegObjTabl
; registration in the v10, v9 and v7 sources (the macro, and v7's
; written-out form) was parsed, each registered table was read out of
; the original ROM dump, and every address those tables point at is an
; object START: a Viewable table points at NAKA widget records, a
; ResName table (slot = Viewable slot + 0x300) at the name string of
; each element, an ApFunction / Function / MainFunction table (slot
; 0x1xx) at procedures and its slot + 0x300 twin at their names. Each
; piece below starts at one such run of objects or at a label that
; already existed. A widget record begins with the Viewable fields (the
; firmware's own names): +0 class (class id), +4 super, +6 sub, +8 next,
; +10 prev (element indices of the same table, 0xffff = none -- parent,
; first child, next and previous sibling, checked against each other for
; every table: the Links result per table), +12 flag, +14 rect (x1, y1,
; x2, y2). Name strings are NUL-terminated and 0xff-padded to even
; length. Strings a record's `X` field (str, title, caption, name)
; points at are indexed too, so the bytes after a record are accounted
; for (in v10, 4 of the 3,340 records are followed by bytes nothing
; indexed starts at). The first word of a widget record is its CLASS ID
; 0x016S_KKKK: ClassProc (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff
; as a registry slot -- the Class table that RegObjTable 0x1600004 put
; there -- and 0x18 * (id & 0xffff) into it. Each class definition gives
; the instance size (+8 allsize), and all 3,340 in-ROM widget records of
; v10 resolve to a class and are at least that far apart (THE CLASS
; SYSTEM, scripts/analysis/nakarest_objtab_map.py).
;
; Tables with objects in this file:
;
; ApFunction slot 0x120: RegObjTabl 0x1600002, ApFunctionProc, 0xc,
; 0xeab2b4, 0x120 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x120.
;
; Class slot 0x160: RegObjTable 0x1600004, ClassProc, 0xeada92,
; 0xeac9ee, 0x160 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 109, is the word at 0xeada92; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x160.
;
; ApFunction slot 0x420: RegObjTabl 0x1600002, ApFunctionProc, 0xc,
; 0xeab2e8, 0x420 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x420.
; -----------------------------------------------------------------------------

; [nakarest] DiskWarning_ConfirmStrings  +0x0..+0x30 (0xea8cac, 48 B)
; [nakarest] Text (48 B at 0xea8cac), first string "Etes vous s\xFBr?"; no registered NAKA table
; [nakarest] points into it; reached through 3 data words in DiskSure_PtrTable (at
; [nakarest] 0xea8c64, 0xea8c60, 0xea8c5c), which is read by DiskSure (file_io/medley.s: `lda
; [nakarest] xhl, (DiskSure_PtrTable:24)`).
DiskWarning_ConfirmStrings:
	.incbin "includes/generated/naka_disk_warning.bin", 0x0, 0x10
DiskWarning_GermanConfirm:	.incbin "includes/generated/naka_disk_warning.bin", 0x10, 0x20
; [nakarest] naka_disk_warning+0x30  +0x30..+0x1c4 (0xea8cdc, 404 B)
; [nakarest] A table of 6 pointers into this piece (404 B at 0xea8cdc), then text; entry 0
; [nakarest] points at "Using DISK FORMAT will erase any current data on"; no registered NAKA
; [nakarest] table points into it; reached through source references FormatText
; [nakarest] (file_io/medley.s: `lda xhl, (FormatText_PtrTable:24)`).
FormatText_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x30, 0x194	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1c4  +0x1c4..+0x47e (0xea8e70, 698 B)
; [nakarest] A table of 6 pointers into this piece (698 B at 0xea8e70), then text; entry 0
; [nakarest] points at "Using FILE DELETE will erase the selected file c"; no registered NAKA
; [nakarest] table points into it; reached through source references DeleteText
; [nakarest] (file_io/medley.s: `lda xhl, (DeleteText_PtrTable:24)`).
DeleteText_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4, 0x2BA	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0x47e  +0x47e..+0x790 (0xea912a, 786 B)
; [nakarest] A table of 6 pointers into this piece (786 B at 0xea912a), then text; entry 0
; [nakarest] points at "A file already exists at the chosen location. If"; no registered NAKA
; [nakarest] table points into it; reached through source references SaveText (file_io/medley.s:
; [nakarest] `lda xhl, (SaveText_PtrTable:24)`).
SaveText_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x47E, 0x312	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0x790  +0x790..+0x8ac (0xea943c, 284 B)
; [nakarest] A table of 6 pointers into this piece (284 B at 0xea943c), then text; entry 0
; [nakarest] points at "When a disk is inserted open this page."; no registered NAKA table
; [nakarest] points into it; reached through source references InsertOptionText
; [nakarest] (file_io/medley.s: `lda xhl, (InsertOptionText_PtrTable:24)`).
InsertOptionText_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x790, 0x11C	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0x8ac  +0x8ac..+0x9de (0xea9558, 306 B)
; [nakarest] A table of 6 pointers into this piece (306 B at 0xea9558), then text; entry 0
; [nakarest] points at "When a disk contains Technics & SMF files."; no registered NAKA table
; [nakarest] points into it; reached through source references TypePriorityText
; [nakarest] (file_io/medley.s: `lda xhl, (TypePriorityText_PtrTable:24)`).
TypePriorityText_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x8AC, 0x132	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0x9de  +0x9de..+0xa38 (0xea968a, 90 B)
; [nakarest] purpose not established: layout of 90 B at 0xea968a not derived; readers below
; [nakarest] Readers: source references JumpInsert_DispatchBody (file_io/misc_ui.s: `ld xbc,
; [nakarest] JumpInsert_DispatchBody_PtrTable`).
JumpInsert_DispatchBody_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x9DE, 0x5A	; 5 x 32-bit pointer
; [nakarest] naka_disk_warning+0xa38  +0xa38..+0xa4c (0xea96e4, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xea96e4 not derived; readers below
; [nakarest] Readers: source references JumpInsertFunc (file_io/misc_ui.s: `add xbc,
; [nakarest] JumpInsertFunc_Data`).
JumpInsertFunc_Data:
	.short	JumpInsertFunc_OnGetLargeStep - JumpInsert_DispatchBody
	.short	JumpInsertFunc_OnGetLargeStep - JumpInsert_DispatchBody
	.short	JumpInsert_Error - JumpInsert_DispatchBody
	.short	JumpInsert_Error - JumpInsert_DispatchBody
	.short	JumpInsert_Error - JumpInsert_DispatchBody
	.short	JumpInsertFunc_OnGetMax - JumpInsert_DispatchBody
	.short	JumpInsert_Error - JumpInsert_DispatchBody
	.short	JumpInsertFunc_OnGetRamAddress - JumpInsert_DispatchBody
	.short	JumpInsertFunc_OnGetLargeStep - JumpInsert_DispatchBody
	.short	JumpInsert_DispatchBody - JumpInsert_DispatchBody
; [nakarest] naka_disk_warning+0xa4c  +0xa4c..+0xa6c (0xea96f8, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xea96f8 not derived; readers below
; [nakarest] Readers: source references FilePriorityFunc (file_io/misc_ui.s: `lda xbc,
; [nakarest] (FilePriorityFunc_PtrTable:24)`).
FilePriorityFunc_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xA4C, 0x20	; 2 x 32-bit pointer
; [nakarest] naka_disk_warning+0xa6c  +0xa6c..+0xb46 (0xea9718, 218 B)
; [nakarest] A table of 6 pointers into this piece (218 B at 0xea9718), then text; entry 0
; [nakarest] points at "PLEASE WAIT!............"; no registered NAKA table points into it;
; [nakarest] reached through source references WaitingFunc_DrawMessage (file_io/misc_ui.s: `lda
; [nakarest] xbc, (WaitingFunc_DrawMessage_PtrTable:24)`).
WaitingFunc_DrawMessage_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xA6C, 0xDA	; 6 x 32-bit pointer
; [nakarest] naka_disk_warning+0xb46  +0xb46..+0xbfa (0xea97f2, 180 B)
; [nakarest] purpose not established: layout of 180 B at 0xea97f2 not derived; readers below
; [nakarest] Readers: source references AcFileSfx_DrawLoop (ui/ui_control_panel.s: `lda xhl,
; [nakarest] (AcFileSfx_DrawLoop_PtrTable:24)`).
AcFileSfx_DrawLoop_PtrTable:		.incbin "includes/generated/naka_disk_warning.bin", 0xB46, 0xA2	; 9 x 32-bit pointer
IvTimer_HandleEvent3A_Str_N1shot:	.incbin "includes/generated/naka_disk_warning.bin", 0xBE8, 0x6	; "1shot"
IvIndexSwCtrlProc_Str_ISC:		.incbin "includes/generated/naka_disk_warning.bin", 0xBEE, 0x4	; "ISC"
IvIndexSwDelayProc_Str_ISD:		.incbin "includes/generated/naka_disk_warning.bin", 0xBF2, 0x4	; "ISD"
IvWaitWinCtlProc_Str_WWC:		.incbin "includes/generated/naka_disk_warning.bin", 0xBF6, 0x4	; "WWC"
; [nakarest] naka_disk_warning+0xbfa  +0xbfa..+0xc06 (0xea98a6, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea98a6 not derived; readers below
; [nakarest] Readers: source references FDC_WaitReady_Skip10 (storage/fdc_routines.s: `lda xix,
; [nakarest] (FDC_WaitReady_Data:24)`).
FDC_WaitReady_Data:
	.short	FDC_CONFIG_VERIFY_Code - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case1 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case2 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case3 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case4 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case5 - FDC_CONFIG_VERIFY_Code
; [nakarest] naka_disk_warning+0xc06  +0xc06..+0xc1e (0xea98b2, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xea98b2 not derived; readers below
; [nakarest] Readers: source references FDC_COMMAND_DISPATCHER (storage/fdc_routines.s: `lda
; [nakarest] xix, (FDC_COMMAND_DISPATCHER_Data:24)`).
FDC_COMMAND_DISPATCHER_Data:
	.short	FDC_CMD_HANDLER_BASE - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
	.short	FDC_ReturnZero - FDC_CMD_HANDLER_BASE
	.short	FDC_ReturnZero - FDC_CMD_HANDLER_BASE
	.short	FDC_ReturnZero - FDC_CMD_HANDLER_BASE
	.short	FDC_ErrorInvalidDrive - FDC_CMD_HANDLER_BASE
	.short	FDC_ReturnZero - FDC_CMD_HANDLER_BASE
	.short	FDC_CheckDriveCount - FDC_CMD_HANDLER_BASE
; [nakarest] naka_disk_warning+0xc1e  +0xc1e..+0xc36 (0xea98ca, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xea98ca not derived; readers below
; [nakarest] Readers: source references FDC_CommandEntry_CopyParams (storage/fdc_routines.s:
; [nakarest] `lda xix, (FDC_CommandEntry_CopyParams_Data:24)`).
FDC_CommandEntry_CopyParams_Data:
	.short	FDC_HANDLER_DISPATCH_BASE - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_01 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_02 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_03 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_04 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_05 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_06 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_07 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_08 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_09 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_10 - FDC_HANDLER_DISPATCH_BASE
	.short	FDC_HANDLER_11 - FDC_HANDLER_DISPATCH_BASE
; [nakarest] naka_disk_warning+0xc36  +0xc36..+0xcba (0xea98e2, 132 B)
; [nakarest] purpose not established: layout of 132 B at 0xea98e2 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_HandleSerialPort
; [nakarest] (boot/main_title_ctrl_panel.s: `lda xbc, (CtrlPanel_HandleSerialPort_Data:24)`).
CtrlPanel_HandleSerialPort_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0xC36, 0x84
; [nakarest] naka_disk_warning+0xcba  +0xcba..+0xd4c (0xea9966, 146 B)
; [nakarest] purpose not established: layout of 146 B at 0xea9966 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_CheckButtonRelease
; [nakarest] (boot/main_title_ctrl_panel.s: `ld xbc, SndParam_SendDiskMenuEvents_Data`),
; [nakarest] CtrlPanel_CheckDiskMenuRelease (boot/main_title_ctrl_panel.s: `ld xbc,
; [nakarest] SndParam_SendDiskMenuEvents_Data`), CtrlPanel_ProcessButtonPress
; [nakarest] (boot/main_title_ctrl_panel.s: `ld xbc, SndParam_SendDiskMenuEvents_Data`),
; [nakarest] SndParam_SendDiskMenuEvents (boot/main_title_ctrl_panel.s: `ld xbc,
; [nakarest] SndParam_SendDiskMenuEvents_Data`).
SndParam_SendDiskMenuEvents_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0xCBA, 0x80
GetSoundName_DefaultString_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0xD3A, 0x12
; [nakarest] naka_disk_warning+0xd4c  +0xd4c..+0xd58 (0xea99f8, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea99f8 not derived; readers below
; [nakarest] Readers: source references MainPmanControl (ui/ui_control_panel.s: `add xwa,
; [nakarest] MainPmanControl_Data`).
MainPmanControl_Data:
	.short	MainPmanCtrl_Case0 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case1 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case2 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case3 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case4 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case5 - MainPmanCtrl_DispatchTable
; [nakarest] naka_disk_warning+0xd58  +0xd58..+0xdae (0xea9a04, 86 B)
; [nakarest] purpose not established: layout of 86 B at 0xea9a04 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_DispatchByIndex (ui/ui_control_panel.s: `lda
; [nakarest] xix, (CtrlPanel_DispatchByIndex_Data:24)`).
CtrlPanel_DispatchByIndex_Data:
	.short	CtrlPanel_FrameReturn - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case26 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case27 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case28 - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case26 - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_FrameDispatchTable - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case35 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case36 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case37 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case38 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case39 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case40 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case41 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case42 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case43 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case44 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case45 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case46 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case47 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case48 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case49 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case50 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case51 - CtrlPanel_FrameDispatchTable
	.short	GetClientBox2_Case52 - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterTopMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
	.short	CtrlPanel_AfterLeftMargin - CtrlPanel_FrameDispatchTable
; [nakarest] naka_disk_warning+0xdae  +0xdae..+0xe2e (0xea9a5a, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xea9a5a not derived; readers below
; [nakarest] Readers: source references GroupBox_HandleStateCompare (ui/ui_control_panel.s: `lda
; [nakarest] xwa, (GroupBox_HandleStateCompare_Data:24)`).
GroupBox_HandleStateCompare_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0xDAE, 0x80
; [nakarest] naka_disk_warning+0xe2e  +0xe2e..+0xe56 (0xea9ada, 40 B)
; [nakarest] purpose not established: layout of 40 B at 0xea9ada not derived; readers below
; [nakarest] Readers: source references CtrlPanel_FuncDispatch (ui/ui_control_panel.s: `add xwa,
; [nakarest] CtrlPanel_FuncDispatch_Data`).
CtrlPanel_FuncDispatch_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0xE2E, 0x28
; [nakarest] naka_disk_warning+0xe56  +0xe56..+0xe70 (0xea9b02, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xea9b02 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_FuncDispatch (ui/ui_control_panel.s: `ld xix,
; [nakarest] CtrlPanel_FuncDispatch_Data_2`).
CtrlPanel_FuncDispatch_Data_2:
	.short	GroupBox_NavUpDown - GroupBox_HandlePartChange
	.short	GroupBox_ForwardToBoxProc - GroupBox_HandlePartChange
	.short	GroupBox_ReturnZero - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case3 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case4 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case5 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case6 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case7 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case8 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case9 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case10 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case11 - GroupBox_HandlePartChange
	.short	GroupBoxProc_Case12 - GroupBox_HandlePartChange
; [nakarest] naka_disk_warning+0xe70  +0xe70..+0xe8a (0xea9b1c, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xea9b1c not derived; readers below
; [nakarest] Readers: source references GetEditSwPoint (audio/presentation_sound_nav.s: `lda
; [nakarest] xix, (GetEditSwPoint_Data:24)`).
GetEditSwPoint_Data:
	.short	EditSwParam_TempoTable - EditSwParam_Mode0
	.short	GetEditSwPoint_Case1 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case2 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case3 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case4 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case5 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case6 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case7 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case8 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case9 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case10 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case11 - EditSwParam_Mode0
	.short	GetEditSwPoint_Case12 - EditSwParam_Mode0
; [nakarest] naka_disk_warning+0xe8a  +0xe8a..+0xe96 (0xea9b36, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9b36 not derived; readers below
; [nakarest] Readers: source references SetWallPaper (audio/presentation_sound_nav.s: `lda xix,
; [nakarest] (SetWallPaper_Data:24)`).
SetWallPaper_Data:
	.short	SetWallPaper_DispatchData - SetWallPaper_DispatchData
	.short	SetWallPaper_CaseData - SetWallPaper_DispatchData
	.short	SetWallPaper_Case2 - SetWallPaper_DispatchData
	.short	SetWallPaper_Default - SetWallPaper_DispatchData
	.short	SetWallPaper_Loop - SetWallPaper_DispatchData
	.short	SetWallPaper_Loop - SetWallPaper_DispatchData
; [nakarest] naka_disk_warning+0xe96  +0xe96..+0xeb4 (0xea9b42, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xea9b42 not derived; readers below
; [nakarest] Readers: source references IvDirmdScreenProc (audio/presentation_sound_nav.s: `add
; [nakarest] xbc, IvDirmdScreenProc_Str_K`).
IvDirmdScreenProc_Str_K:
	.short	IvDirmdScreenProc_OnShow - DirmdEmu_CaseB
	.short	IvDirmdScreenProc_OnHide - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	IvDirmdScreenProc_OnSwIn - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	IvDirmdScreenProc_OnAllPaint - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	DirmdEmu_CaseE - DirmdEmu_CaseB
	.short	TaskWake_ZeroReturn - DirmdEmu_CaseB
	.short	TaskWake_ZeroReturn - DirmdEmu_CaseB
	.short	IvDirmdScreenProc_OnParaDraw - DirmdEmu_CaseB
; [nakarest] naka_disk_warning+0xeb4  +0xeb4..+0xec4 (0xea9b60, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xea9b60 not derived; readers below
; [nakarest] Readers: source references DirmdTitleFunc (audio/presentation_sound_nav.s: `ld xiy,
; [nakarest] DirmdTitleFunc_PtrTable`).
DirmdTitleFunc_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xEB4, 0x10	; 4 x 32-bit pointer
; [nakarest] naka_disk_warning+0xec4  +0xec4..+0xed6 (0xea9b70, 18 B)
; [nakarest] Text (18 B at 0xea9b70), first string "DirmdTitleNew();"; no registered NAKA table
; [nakarest] points into it; reached through source references PostTitle_Function_Skip
; [nakarest] (audio/presentation_sound_nav.s: `ld xwa, DirmdTitleFunc_Str_DirmdTitleNew`).
DirmdTitleFunc_Str_DirmdTitleNew:	.incbin "includes/generated/naka_disk_warning.bin", 0xEC4, 0x12	; "DirmdTitleNew();"
; [nakarest] naka_disk_warning+0xed6  +0xed6..+0xf00 (0xea9b82, 42 B)
; [nakarest] Text (42 B at 0xea9b82), first string "DirmdTitleOld();"; no registered NAKA table
; [nakarest] points into it; reached through source references PostTitle_Function_Skip
; [nakarest] (audio/presentation_sound_nav.s: `ld xwa, DirmdTitleFunc_Str_DirmdTitleOld`).
DirmdTitleFunc_Str_DirmdTitleOld:		.incbin "includes/generated/naka_disk_warning.bin", 0xED6, 0x12	; "DirmdTitleOld();"
DirmdTitleFunc_Str_DirmdTitleESw_Fmtd_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0xEE8, 0x18	; "DirmdTitleESw(%d, %d);"
; [nakarest] naka_disk_warning+0xf00  +0xf00..+0xf12 (0xea9bac, 18 B)
; [nakarest] Text (18 B at 0xea9bac), first string "DirmdTitleCur();"; no registered NAKA table
; [nakarest] points into it; reached through source references PostTitle_Function_Skip
; [nakarest] (audio/presentation_sound_nav.s: `ld xwa, DirmdTitleFunc_Str_DirmdTitleCur`).
DirmdTitleFunc_Str_DirmdTitleCur:	.incbin "includes/generated/naka_disk_warning.bin", 0xF00, 0x12	; "DirmdTitleCur();"
; DirmdEmulator's case table: one 16-bit offset from DirmdEmulator_Dispatch per event EVT_NONE .. EVT_NONE+15
; (DirmdEmulator subtracts EVT_NONE, rejects anything outside 0..15, then `jp t, (xix+bc)`).  Four events
; have cases; the rest go straight to DirmdEmu_DefaultCase.  Was a 32-byte slice of naka_disk_warning.bin.
DirmdEmulator_Data:
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_NONE
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_SHOW
	.short DirmdEmulator_Dispatch - DirmdEmulator_Dispatch	; EVT_HIDE
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_NONE+3
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_NONE+4
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_NONE+5
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_ACTION
	.short DirmdEmu_OnSwitchIn - DirmdEmulator_Dispatch	; EVT_SW_IN
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_SW_ON
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_SW_OFF
	.short DirmdEmu_OnAllPaint - DirmdEmulator_Dispatch	; EVT_ALL_PAINT
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_PAINT
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_REPAINT
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_DRAW
	.short DirmdEmu_DefaultCase - DirmdEmulator_Dispatch	; EVT_SELE_DRAW
	.short DirmdEmu_OnParaDraw - DirmdEmulator_Dispatch	; EVT_PARA_DRAW
; [nakarest] naka_disk_warning+0xf32  +0xf32..+0xf46 (0xea9bde, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xea9bde not derived; readers below
; [nakarest] Readers: source references WindowProc (audio/presentation_sound_nav.s: `add xbc,
; [nakarest] WindowProc_Data`).
WindowProc_Data:
	.short	WindowProc_EventDispatch - WindowProc_EventDispatch
	.short	WindowProc_OnHide - WindowProc_EventDispatch
	.short	WindowProc_DefaultHandler - WindowProc_EventDispatch
	.short	WindowProc_DefaultHandler - WindowProc_EventDispatch
	.short	WindowProc_DefaultHandler - WindowProc_EventDispatch
	.short	WindowProc_DefaultHandler - WindowProc_EventDispatch
	.short	WindowProc_OnSwIn - WindowProc_EventDispatch
	.short	WindowProc_OnSwIn - WindowProc_EventDispatch
	.short	WindowProc_OnSwIn - WindowProc_EventDispatch
	.short	WindowProc_OnAllPaint - WindowProc_EventDispatch
; [nakarest] naka_disk_warning+0xf46  +0xf46..+0x1154 (0xea9bf2, 526 B)
; [nakarest] purpose not established: layout of 526 B at 0xea9bf2 not derived; readers below
; [nakarest] Readers: source references WndScroll_SendSelectionEvents (ui/ui_window_procs.s: `ld
; [nakarest] xbc, WndScroll_SendSelectionEvents_PtrTable`); 2 data words in
; [nakarest] Data_SoundEditorCharsLayout (at 0xea9ed2, 0xea9ed6), which is read by
; [nakarest] WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), 4 more.
WndScroll_SendSelectionEvents_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xF46, 0x20E	; 3 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1154  +0x1154..+0x1226 (0xea9e00, 210 B)
; [nakarest] purpose not established: layout of 210 B at 0xea9e00 not derived; readers below
; [nakarest] Readers: source references WndScroll_SearchCharTable (ui/ui_window_procs.s: `lda
; [nakarest] xwa, (WndScroll_SearchCharTable_PtrTable:24)`); 1 data word in
; [nakarest] Data_SoundEditorCharsLayout (at 0xea9eda), which is read by
; [nakarest] WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), 4 more.
WndScroll_SearchCharTable_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1154, 0xD2	; 33 x 32-bit pointer
; [nakarest] Data_SoundEditorCharsLayout  +0x1226..+0x1232 (0xea9ed2, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9ed2 not derived; readers below
; [nakarest] Readers: source references WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Skip4
; [nakarest] (ui/ui_window_procs.s: `.long Data_SoundEditorCharsLayout`),
; [nakarest] WndScroll_ClampPageCount (ui/ui_window_procs.s: `ld xbc,
; [nakarest] Data_SoundEditorCharsLayout`), 2 more.
Data_SoundEditorCharsLayout:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1226, 0xC
; [nakarest] naka_disk_warning+0x1232  +0x1232..+0x123e (0xea9ede, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9ede not derived; readers below
; [nakarest] Readers: source references WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s: `ld
; [nakarest] xbc, WndScroll_ItemCountCheck_Str_Chr25`), WndEvt_EventCodeDispatch_Skip2
; [nakarest] (ui/ui_window_procs.s: `lda xde, (WndScroll_ItemCountCheck_Str_Chr25:24)`),
; [nakarest] WndScroll_CheckTableEnd (ui/ui_window_procs.s: `ld xbc,
; [nakarest] WndScroll_ItemCountCheck_Str_Chr25`), WndScroll_HandleDialPage (ui/ui_window_procs.s:
; [nakarest] `ld xwa, WndScroll_ItemCountCheck_Str_Chr25`), 1 more.
WndScroll_ItemCountCheck_Str_Chr25:	.incbin "includes/generated/naka_disk_warning.bin", 0x1232, 0x2	; "%"
	.incbin "includes/generated/naka_disk_warning.bin", 0x1234, 0xA	; 10 bytes after WndScroll_ItemCountCheck_Str_Chr25's string; unnamed (they sat under its label until 2026-10-03)
; [nakarest] naka_disk_warning+0x123e  +0x123e..+0x124a (0xea9eea, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9eea not derived; readers below
; [nakarest] Readers: source references AcNaming_QueryCharSet (audio/presentation_sound_nav.s:
; [nakarest] `ld xbc, AcNaming_QueryCharSet_PtrTable`).
AcNaming_QueryCharSet_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x123E, 0xC	; 2 x 32-bit pointer
; [nakarest] naka_disk_warning+0x124a  +0x124a..+0x1274 (0xea9ef6, 42 B)
; [nakarest] purpose not established: layout of 42 B at 0xea9ef6 not derived; readers below
; [nakarest] Readers: source references WndEvt_DispatchByEventCode (ui/ui_window_procs.s: `add
; [nakarest] xwa, WndEvt_DispatchByEventCode_Data`).
WndEvt_DispatchByEventCode_Data:
	.short	WndEvt_EventCodeDispatch - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case1 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case2 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case3 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case4 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case5 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case6 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case7 - WndEvt_EventCodeDispatch
	.short	WndEvt_DispatchByEventCode_Case8 - WndEvt_EventCodeDispatch
ModeEdit_HandlePaint_Data:			.incbin "includes/generated/naka_disk_warning.bin", 0x125C, 0xC
TitleEdit_HandlePaint_Str_N0x_Fmt2X_Fmts:	.incbin "includes/generated/naka_disk_warning.bin", 0x1268, 0xC	; "0x%02X : %s"
; [nakarest] naka_disk_warning+0x1274  +0x1274..+0x14ba (0xea9f20, 582 B)
; [nakarest] purpose not established: layout of 582 B at 0xea9f20 not derived; readers below
; [nakarest] Readers: source references UserBitmapCheck_ReturnTablePtr (ui/ui_window_procs.s:
; [nakarest] `lda xhl, (UserBitmapCheck_ReturnTablePtr_Data:24)`).
UserBitmapCheck_ReturnTablePtr_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1274, 0x240
VwUserBitmapByName_HandlePaint_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x14B4, 0x6
; [nakarest] naka_disk_warning+0x14ba  +0x14ba..+0x14be (0xeaa166, 4 B)
; [nakarest] Text (4 B at 0xeaa166), first string "~7f"; no registered NAKA table points into
; [nakarest] it; reached through source references EditSw_ByteData (ui/ui_window_procs.s: `ld
; [nakarest] xwa, EditSw_ByteData_Str_N7f`).
EditSw_ByteData_Str_N7f:	.incbin "includes/generated/naka_disk_warning.bin", 0x14BA, 0x4	; "~7f"
; [nakarest] naka_disk_warning+0x14be  +0x14be..+0x14c2 (0xeaa16a, 4 B)
; [nakarest] Text (4 B at 0xeaa16a), first string "~80"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawDesignFrame_Skip (ui/ui_window_procs.s:
; [nakarest] `ld xwa, EditSw_ByteData_Str_N80`).
EditSw_ByteData_Str_N80:	.incbin "includes/generated/naka_disk_warning.bin", 0x14BE, 0x4	; "~80"
; [nakarest] naka_disk_warning+0x14c2  +0x14c2..+0x14c6 (0xeaa16e, 4 B)
; [nakarest] Text (4 B at 0xeaa16e), first string "~81"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawDesignFrame_Skip2 (ui/ui_window_procs.s:
; [nakarest] `ld xwa, EditSw_ByteData_Str_N81`).
EditSw_ByteData_Str_N81:	.incbin "includes/generated/naka_disk_warning.bin", 0x14C2, 0x4	; "~81"
; [nakarest] naka_disk_warning+0x14c6  +0x14c6..+0x14ca (0xeaa172, 4 B)
; [nakarest] Text (4 B at 0xeaa172), first string "~7f"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw (ui/ui_window_procs.s: `ld xwa,
; [nakarest] DrawEditSw_Str_N7f`).
DrawEditSw_Str_N7f:	.incbin "includes/generated/naka_disk_warning.bin", 0x14C6, 0x4	; "~7f"
; [nakarest] naka_disk_warning+0x14ca  +0x14ca..+0x14ce (0xeaa176, 4 B)
; [nakarest] Text (4 B at 0xeaa176), first string "~80"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw_SelectVariantA
; [nakarest] (ui/ui_window_procs.s: `ld xwa, DrawEditSw_SelectVariantA_Str_N80`).
DrawEditSw_SelectVariantA_Str_N80:	.incbin "includes/generated/naka_disk_warning.bin", 0x14CA, 0x4	; "~80"
; [nakarest] naka_disk_warning+0x14ce  +0x14ce..+0x1546 (0xeaa17a, 120 B)
; [nakarest] Text (120 B at 0xeaa17a), first string "~81"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw_SelectVariantC
; [nakarest] (ui/ui_window_procs.s: `ld xwa, DrawEditSw_SelectVariantC_Str_N81`).
DrawEditSw_SelectVariantC_Str_N81:			.incbin "includes/generated/naka_disk_warning.bin", 0x14CE, 0x4	; "~81"
TextBox_DrawLineLoop_Data:				.incbin "includes/generated/naka_disk_warning.bin", 0x14D2, 0x2
AcTempoBox_MatchTempoID_Str_aa_Fmt3d:			.incbin "includes/generated/naka_disk_warning.bin", 0x14D4, 0x8	; "~aa=%3d"
AcTempoBox_CopyTempoString_Str_aa:			.incbin "includes/generated/naka_disk_warning.bin", 0x14DC, 0x8	; "~aa=---"
PsListBox_GetText_Str_No_My_Car_Day_Memory_AyaSam:	.incbin "includes/generated/naka_disk_warning.bin", 0x14E4, 0x5C	; "No My Car Day|Memory|AyaSam|Sweet Home Town|I am Rocker|Sunday Song|Two Day Drunk?|Samba 2"
PsGridBox_Scroll_Render_Str_Fmtd_Fmtd:			.incbin "includes/generated/naka_disk_warning.bin", 0x1540, 0x6	; "%d-%d"
; [nakarest] naka_disk_warning+0x1546  +0x1546..+0x1566 (0xeaa1f2, 32 B)
; [nakarest] Text (32 B at 0xeaa1f2), first string " PART |CHANNEL|OCTAVE | LOCAL "; no
; [nakarest] registered NAKA table points into it; reached through source references
; [nakarest] PsGridBox_Scroll_Render (ui/psgridbox_routines.s: `ld xwa,
; [nakarest] PsGridBox_Scroll_Render_Str_PART_CHANNEL_OCTAVE_LOCAL`).
PsGridBox_Scroll_Render_Str_PART_CHANNEL_OCTAVE_LOCAL:	.incbin "includes/generated/naka_disk_warning.bin", 0x1546, 0x20	; " PART  |CHANNEL|OCTAVE | LOCAL "
; [nakarest] naka_disk_warning+0x1566  +0x1566..+0x159c (0xeaa212, 54 B)
; [nakarest] Text (54 B at 0xeaa212), first string
; [nakarest] "|-|RIGHT1|RIGHT2|LEFT|PART4|PART5|PART6|PART7|PA"; no registered NAKA table points
; [nakarest] into it; reached through source references PsGridBox_Scroll_Render
; [nakarest] (ui/psgridbox_routines.s: `ld xwa, PsGridBox_Scroll_Render_Str_RIGHT1_RIGHT2_LEFT_PART4_PART5`).
PsGridBox_Scroll_Render_Str_RIGHT1_RIGHT2_LEFT_PART4_PART5:	.incbin "includes/generated/naka_disk_warning.bin", 0x1566, 0x36	; "|-|RIGHT1|RIGHT2|LEFT|PART4|PART5|PART6|PART7|PART8|"
; [nakarest] naka_disk_warning+0x159c  +0x159c..+0x15ac (0xeaa248, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa248 not derived; readers below
; [nakarest] Readers: source references PsGridBoxProc (ui/ui_window_procs.s: `add xbc,
; [nakarest] PsGridBoxProc_Data`).
PsGridBoxProc_Data:
	.short	PsGridBoxProc_OnGetFixedColStr - PsGridBox_Init
	.short	PsGridBoxProc_OnGetFixedRowStr - PsGridBox_Init
	.short	PsGridBoxProc_OnGridDraw - PsGridBox_Init
	.short	PsGridBoxProc_OnRequestGridDraw - PsGridBox_Init
	.short	PsGridBoxProc_OnSetSelectedCel - PsGridBox_Init
	.short	PsGridBoxProc_OnGetSelectedCel - PsGridBox_Init
	.short	PsGridBox_Default - PsGridBox_Init
	.short	PsGridBoxProc_OnCheckGridIndex - PsGridBox_Init
; [nakarest] naka_disk_warning+0x15ac  +0x15ac..+0x15c0 (0xeaa258, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeaa258 not derived; readers below
; [nakarest] Readers: source references AcGridBoxProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] AcGridBoxProc_Data`).
AcGridBoxProc_Data:
	.short	AcGridBoxProc_OnIndexswUp - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswDown - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswUp - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswDown - AcGridBox_Init
	.short	AcGridBox_Default - AcGridBox_Init
	.short	AcGridBox_CellSelect - AcGridBox_Init
	.short	AcGridBox_CellSelect - AcGridBox_Init
GridCheck_CellSelect_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x15BA, 0x6
; [nakarest] naka_disk_warning+0x15c0  +0x15c0..+0x15d6 (0xeaa26c, 22 B)
; [nakarest] purpose not established: layout of 22 B at 0xeaa26c not derived; readers below
; [nakarest] Readers: source references GridCheck (ui/ui_widget_defs.s: `add xwa,
; [nakarest] GridCheck_Data`).
GridCheck_Data:
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_Return - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
PsNumEditBox_Confirm_Str_Chr25:	.incbin "includes/generated/naka_disk_warning.bin", 0x15CE, 0x2	; "%"
PsNumEditBox_Confirm_Str_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x15D0, 0x4	; "%d"
PsNumEditBox_Confirm_Str_d:	.incbin "includes/generated/naka_disk_warning.bin", 0x15D4, 0x2	; "d"
; [nakarest] naka_disk_warning+0x15d6  +0x15d6..+0x15ee (0xeaa282, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xeaa282 not derived; readers below
; [nakarest] Readers: source references PasTableCheck (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] PasTableCheck_PtrTable`).
PasTableCheck_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x15D6, 0x18	; 2 x 32-bit pointer
; [nakarest] naka_disk_warning+0x15ee  +0x15ee..+0x160e (0xeaa29a, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaa29a not derived; readers below
; [nakarest] Readers: source references AcOnOff_GetText (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] AcOnOff_GetText_PtrTable`).
AcOnOff_GetText_PtrTable:		.incbin "includes/generated/naka_disk_warning.bin", 0x15EE, 0x10	; 2 x 32-bit pointer
AcNumEdit_GetText_Str_Chr25:		.incbin "includes/generated/naka_disk_warning.bin", 0x15FE, 0x2	; "%"
AcNumEdit_GetText_Str_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1600, 0x4	; "%d"
AcNumEdit_GetText_Str_d:		.incbin "includes/generated/naka_disk_warning.bin", 0x1604, 0x2	; "d"
LswEditCheck_Str_Fmt3d:			.incbin "includes/generated/naka_disk_warning.bin", 0x1606, 0x4	; "%3d"
RamEditCheck_JumpStart_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x160A, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x160e  +0x160e..+0x1622 (0xeaa2ba, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeaa2ba not derived; readers below
; [nakarest] Readers: source references RamEditCheck (ui/ui_widget_defs.s: `add xwa,
; [nakarest] RamEditCheck_Data`).
RamEditCheck_Data:
	.short	RamEditCheck_OnGetLargeStep - RamEditCheck_JumpStart
	.short	RamEditCheck_OnGetSmallStep - RamEditCheck_JumpStart
	.short	RamEditCheck_NotHandled - RamEditCheck_JumpStart
	.short	RamEditCheck_NotHandled - RamEditCheck_JumpStart
	.short	RamEditCheck_NotHandled - RamEditCheck_JumpStart
	.short	RamEditCheck_OnGetMax - RamEditCheck_JumpStart
	.short	RamEditCheck_OnGetMin - RamEditCheck_JumpStart
	.short	RamEditCheck_OnGetRamAddress - RamEditCheck_JumpStart
	.short	RamEditCheck_OnGetLargeStep - RamEditCheck_JumpStart
	.short	RamEditCheck_JumpStart - RamEditCheck_JumpStart
; [nakarest] naka_disk_warning+0x1622  +0x1622..+0x1636 (0xeaa2ce, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeaa2ce not derived; readers below
; [nakarest] Readers: source references BitEditCheck (ui/ui_widget_defs.s: `lda xbc,
; [nakarest] (BitEditCheck_PtrTable:24)`).
BitEditCheck_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1622, 0x14	; 2 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1636  +0x1636..+0x163a (0xeaa2e2, 4 B)
; [nakarest] Text (4 B at 0xeaa2e2), first string "ON"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_Paint_Default (ui/ui_widget_defs.s:
; [nakarest] `ld xde, ButtonState_Paint_EventConfirm_Str_ON`).
ButtonState_Paint_EventConfirm_Str_ON:	.incbin "includes/generated/naka_disk_warning.bin", 0x1636, 0x4	; "ON"
; [nakarest] naka_disk_warning+0x163a  +0x163a..+0x163e (0xeaa2e6, 4 B)
; [nakarest] Text (4 B at 0xeaa2e6), first string "OFF"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_Paint_Default
; [nakarest] (ui/ui_widget_defs.s: `ld xde, ButtonState_Paint_EventConfirm_Str_OFF`).
ButtonState_Paint_EventConfirm_Str_OFF:	.incbin "includes/generated/naka_disk_warning.bin", 0x163A, 0x4	; "OFF"
; [nakarest] naka_disk_warning+0x163e  +0x163e..+0x1642 (0xeaa2ea, 4 B)
; [nakarest] Text (4 B at 0xeaa2ea), first string "~9b"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N9b`).
ButtonState_DispatchDSP_InlineData_Str_N9b:	.incbin "includes/generated/naka_disk_warning.bin", 0x163E, 0x4	; "~9b"
; [nakarest] naka_disk_warning+0x1642  +0x1642..+0x1646 (0xeaa2ee, 4 B)
; [nakarest] Text (4 B at 0xeaa2ee), first string "~98"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N98`).
ButtonState_DispatchDSP_InlineData_Str_N98:	.incbin "includes/generated/naka_disk_warning.bin", 0x1642, 0x4	; "~98"
; [nakarest] naka_disk_warning+0x1646  +0x1646..+0x164a (0xeaa2f2, 4 B)
; [nakarest] Text (4 B at 0xeaa2f2), first string "~85"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N85`).
ButtonState_DispatchDSP_InlineData_Str_N85:	.incbin "includes/generated/naka_disk_warning.bin", 0x1646, 0x4	; "~85"
; [nakarest] naka_disk_warning+0x164a  +0x164a..+0x164e (0xeaa2f6, 4 B)
; [nakarest] Text (4 B at 0xeaa2f6), first string "~81"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N81`).
ButtonState_DispatchDSP_InlineData_Str_N81:	.incbin "includes/generated/naka_disk_warning.bin", 0x164A, 0x4	; "~81"
; [nakarest] NakaInst_OK  +0x164e..+0x1652 (0xeaa2fa, 4 B)
; [nakarest] Text (4 B at 0xeaa2fa), first string "ON"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `.long NakaInst_OK`).
NakaInst_OK:
	.incbin "includes/generated/naka_disk_warning.bin", 0x164E, 0x4
; [nakarest] naka_disk_warning+0x1652  +0x1652..+0x1656 (0xeaa2fe, 4 B)
; [nakarest] Text (4 B at 0xeaa2fe), first string "OFF"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_OFF`).
ButtonState_DispatchDSP_InlineData_Str_OFF:	.incbin "includes/generated/naka_disk_warning.bin", 0x1652, 0x4	; "OFF"
; [nakarest] naka_disk_warning+0x1656  +0x1656..+0x165a (0xeaa302, 4 B)
; [nakarest] Text (4 B at 0xeaa302), first string "OK"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_OK`).
ButtonState_DispatchDSP_InlineData_Str_OK:	.incbin "includes/generated/naka_disk_warning.bin", 0x1656, 0x4	; "OK"
; [nakarest] naka_disk_warning+0x165a  +0x165a..+0x165c (0xeaa306, 2 B)
; [nakarest] Text (2 B at 0xeaa306), first string "<"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_Lt`).
ButtonState_DispatchDSP_InlineData_Str_Lt:	.incbin "includes/generated/naka_disk_warning.bin", 0x165A, 0x2	; "<"
; [nakarest] naka_disk_warning+0x165c  +0x165c..+0x165e (0xeaa308, 2 B)
; [nakarest] Text (2 B at 0xeaa308), first string ">"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_Gt`).
ButtonState_DispatchDSP_InlineData_Str_Gt:	.incbin "includes/generated/naka_disk_warning.bin", 0x165C, 0x2	; ">"
; [nakarest] naka_disk_warning+0x165e  +0x165e..+0x1662 (0xeaa30a, 4 B)
; [nakarest] Text (4 B at 0xeaa30a), first string "~7f"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N7f`).
ButtonState_DispatchDSP_InlineData_Str_N7f:	.incbin "includes/generated/naka_disk_warning.bin", 0x165E, 0x4	; "~7f"
; [nakarest] naka_disk_warning+0x1662  +0x1662..+0x1666 (0xeaa30e, 4 B)
; [nakarest] Text (4 B at 0xeaa30e), first string "~80"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_N80`).
ButtonState_DispatchDSP_InlineData_Str_N80:	.incbin "includes/generated/naka_disk_warning.bin", 0x1662, 0x4	; "~80"
; [nakarest] naka_disk_warning+0x1666  +0x1666..+0x166a (0xeaa312, 4 B)
; [nakarest] Text (4 B at 0xeaa312), first string "YES"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ButtonState_DispatchDSP_InlineData_Str_YES`).
ButtonState_DispatchDSP_InlineData_Str_YES:	.incbin "includes/generated/naka_disk_warning.bin", 0x1666, 0x4	; "YES"
; [nakarest] Str_No  +0x166a..+0x166e (0xeaa316, 4 B)
; [nakarest] Text (4 B at 0xeaa316), first string "NO"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `.long Str_No`).
Str_No:
	.incbin "includes/generated/naka_disk_warning.bin", 0x166A, 0x4
; [nakarest] naka_disk_warning+0x166e  +0x166e..+0x1690 (0xeaa31a, 34 B)
; [nakarest] purpose not established: layout of 34 B at 0xeaa31a not derived; readers below
; [nakarest] Readers: source references ButtonState_DispatchDSP (ui/ui_widget_defs.s: `lda xix,
; [nakarest] (ButtonState_DispatchDSP_Data:24)`).
ButtonState_DispatchDSP_Data:
	.short	ButtonState_DispatchDSP_InlineData - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case1 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case2 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_Paint_DrawAligned - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case4 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case5 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case6 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case7 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case8 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case9 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case10 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_Paint_DrawAligned - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case12 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case13 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_Paint_DrawAligned - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case15 - ButtonState_DispatchDSP_InlineData
	.short	ButtonState_DispatchDSP_Case16 - ButtonState_DispatchDSP_InlineData
; [nakarest] naka_disk_warning+0x1690  +0x1690..+0x16a2 (0xeaa33c, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xeaa33c not derived; readers below
; [nakarest] Readers: source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `lda xix,
; [nakarest] (AcIndexEdit_DispatchDSP_Data:24)`).
AcIndexEdit_DispatchDSP_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1690, 0x12
; [nakarest] naka_disk_warning+0x16a2  +0x16a2..+0x16d8 (0xeaa34e, 54 B)
; [nakarest] Text (54 B at 0xeaa34e), first string ""; no registered NAKA table points into it;
; [nakarest] reached through source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `ld
; [nakarest] xix, AcIndexEdit_DispatchDSP_Data_2`).
AcIndexEdit_DispatchDSP_Data_2:
	.short	AcIndexEdit_DispatchDSP_InlineData - AcIndexEdit_DispatchDSP_InlineData
	.short	AcIndexEdit_OK_AltView_Case1 - AcIndexEdit_DispatchDSP_InlineData
	.short	AcIndexEdit_OK_AltView_Case2 - AcIndexEdit_DispatchDSP_InlineData
PsPageBox_Confirm_DrawValue_Str_PAGE_Fmtd_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x16A8, 0xC	; "PAGE %d/%d"
IvPageControl_GetText_Str_PAGE:			.incbin "includes/generated/naka_disk_warning.bin", 0x16B4, 0x6	; "PAGE"
IvMainEditSw_GetText_Str_MnSw:			.incbin "includes/generated/naka_disk_warning.bin", 0x16BA, 0x6	; "MnSw"
IvExit_GetText_Str_EXIT:			.incbin "includes/generated/naka_disk_warning.bin", 0x16C0, 0x6	; "EXIT"
IvExitMode_GetText_Str_ExMD:			.incbin "includes/generated/naka_disk_warning.bin", 0x16C6, 0x6	; "ExMD"
IvExitScreen_GetText_Str_ExSC:			.incbin "includes/generated/naka_disk_warning.bin", 0x16CC, 0x6	; "ExSC"
IvExitWindow_GetText_Str_ExWn:			.incbin "includes/generated/naka_disk_warning.bin", 0x16D2, 0x6	; "ExWn"
; [nakarest] naka_disk_warning+0x16d8  +0x16d8..+0x16de (0xeaa384, 6 B)
; [nakarest] Text (6 B at 0xeaa384), first string "FWin"; no registered NAKA table points into
; [nakarest] it; reached through source references IvFixWin_Paint (ui/ui_widget_defs.s: `ld xde,
; [nakarest] IvFixWin_Paint_Str_FWin`).
IvFixWin_Paint_Str_FWin:	.incbin "includes/generated/naka_disk_warning.bin", 0x16D8, 0x6	; "FWin"
; [nakarest] naka_disk_warning+0x16de  +0x16de..+0x16e4 (0xeaa38a, 6 B)
; [nakarest] Text (6 B at 0xeaa38a), first string "Name"; no registered NAKA table points into
; [nakarest] it; reached through source references IvNaming_Paint (ui/ui_widget_defs.s: `ld xde,
; [nakarest] IvNaming_Paint_Str_Name`).
IvNaming_Paint_Str_Name:	.incbin "includes/generated/naka_disk_warning.bin", 0x16DE, 0x6	; "Name"
; [nakarest] naka_disk_warning+0x16e4  +0x16e4..+0x16ea (0xeaa390, 6 B)
; [nakarest] Text (6 B at 0xeaa390), first string "TrSw"; no registered NAKA table points into
; [nakarest] it; reached through source references IvTrackSwitch_Paint (ui/ui_widget_defs.s: `ld
; [nakarest] xde, IvTrackSwitch_Paint_Str_TrSw`).
IvTrackSwitch_Paint_Str_TrSw:	.incbin "includes/generated/naka_disk_warning.bin", 0x16E4, 0x6	; "TrSw"
; [nakarest] naka_disk_warning+0x16ea  +0x16ea..+0x171a (0xeaa396, 48 B)
; [nakarest] Text (48 B at 0xeaa396), first string "CcEv"; no registered NAKA table points into
; [nakarest] it; reached through source references DefaultClass_Paint (ui/ui_widget_defs.s: `ld
; [nakarest] xde, DefaultClass_Paint_Str_CcEv`).
DefaultClass_Paint_Str_CcEv:	.incbin "includes/generated/naka_disk_warning.bin", 0x16EA, 0x6	; "CcEv"
IvInterrupt_GetText_Str_IntT:	.incbin "includes/generated/naka_disk_warning.bin", 0x16F0, 0x6	; "IntT"
IvIntReminderProc_Str_iRem:	.incbin "includes/generated/naka_disk_warning.bin", 0x16F6, 0x6	; "iRem"
IvIntCompleteProc_Str_iCmp:	.incbin "includes/generated/naka_disk_warning.bin", 0x16FC, 0x6	; "iCmp"
IvIntErrorProc_Str_iErr:	.incbin "includes/generated/naka_disk_warning.bin", 0x1702, 0x6	; "iErr"
IvIntVari_GetText_Str_iVar:	.incbin "includes/generated/naka_disk_warning.bin", 0x1708, 0x6	; "iVar"
IvIntEasySetProc_Str_iEsy:	.incbin "includes/generated/naka_disk_warning.bin", 0x170E, 0x6	; "iEsy"
IvIntWelcome_GetText_Str_iVar:	.incbin "includes/generated/naka_disk_warning.bin", 0x1714, 0x6	; "iVar"
; [nakarest] naka_disk_warning+0x171a  +0x171a..+0x175e (0xeaa3c6, 68 B)
; [nakarest] Text (68 B at 0xeaa3c6), first string "Show"; no registered NAKA table points into
; [nakarest] it; reached through source references IvShowHideProc (ui/ui_widget_defs.s: `ld xde,
; [nakarest] IvShowHideProc_Str_Show`).
IvShowHideProc_Str_Show:				.incbin "includes/generated/naka_disk_warning.bin", 0x171A, 0x6	; "Show"
AcPmemName_Confirm_Str_PMEM_Fmt2d_Fmtd_Fmt16s:		.incbin "includes/generated/naka_disk_warning.bin", 0x1720, 0x12	; "PMEM:%2d-%d %16s"
AcPmemName_Confirm_ZeroIndex_Str_PMEM_Fmt2d_Fmt16s:	.incbin "includes/generated/naka_disk_warning.bin", 0x1732, 0x10	; "PMEM:%2d-  %16s"
AcPmemName_Confirm_EmptySlot_Str_PMEM_Fmt2d:		.incbin "includes/generated/naka_disk_warning.bin", 0x1742, 0x1C	; "PMEM:%2d-                  "
; [nakarest] naka_disk_warning+0x175e  +0x175e..+0x1860 (0xeaa40a, 258 B)
; [nakarest] purpose not established: layout of 258 B at 0xeaa40a not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Paint (ui/ui_widget_defs.s: `ld xhl,
; [nakarest] AcMixerVol_Paint_PtrTable`).
AcMixerVol_Paint_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x175E, 0x102	; 28 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1860  +0x1860..+0x1864 (0xeaa50c, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaa50c not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Confirm (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] AcMixerVol_Confirm_Data`), AcMixerVol_FastScroll (ui/ui_widget_defs.s: `ld xde,
; [nakarest] AcMixerVol_Confirm_Data`), AcMixerVol_FastScroll_Increment (ui/ui_widget_defs.s: `ld xde,
; [nakarest] AcMixerVol_Confirm_Data`), AcMixerVol_OK (ui/ui_widget_defs.s: `ld xbc, AcMixerVol_Confirm_Data`), 3
; [nakarest] more.
AcMixerVol_Confirm_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1860, 0x4
; [nakarest] naka_disk_warning+0x1864  +0x1864..+0x1978 (0xeaa510, 276 B)
; [nakarest] purpose not established: layout of 276 B at 0xeaa510 not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Confirm (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (AcMixerVol_Confirm_Data_2:24)`), AcMixerVol_OK (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (AcMixerVol_Confirm_Data_2:24)`).
AcMixerVol_Confirm_Data_2:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1864, 0x114
; [nakarest] naka_disk_warning+0x1978  +0x1978..+0x1a08 (0xeaa624, 144 B)
; [nakarest] purpose not established: layout of 144 B at 0xeaa624 not derived; readers below
; [nakarest] Readers: source references AcMixerVol_PartSelect_DrawIcon (ui/ui_widget_defs.s:
; [nakarest] `lda xde, (AcMixerVol_PartSelect_DrawIcon_Data:24)`).
AcMixerVol_PartSelect_DrawIcon_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1978, 0x8C
AcMixerVol_Confirm_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A04, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x1a08  +0x1a08..+0x1a0e (0xeaa6b4, 6 B)
; [nakarest] Text (6 B at 0xeaa6b4), first string "MUTE"; no registered NAKA table points into
; [nakarest] it; reached through source references AcMixerVol_Confirm (ui/ui_widget_defs.s: `ld
; [nakarest] xde, AcMixerVol_Confirm_Str_MUTE`).
AcMixerVol_Confirm_Str_MUTE:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A08, 0x6	; "MUTE"
; [nakarest] naka_disk_warning+0x1a0e  +0x1a0e..+0x1a4e (0xeaa6ba, 64 B)
; [nakarest] Text (64 B at 0xeaa6ba), first string "Debug Time!"; no registered NAKA table
; [nakarest] points into it; reached through source references DbMemo_Paint
; [nakarest] (ui/ui_widget_defs.s: `ld xde, DbMemo_Paint_Str_Debug_Time`).
DbMemo_Paint_Str_Debug_Time:					.incbin "includes/generated/naka_disk_warning.bin", 0x1A0E, 0xC	; "Debug Time!"
DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt4X:			.incbin "includes/generated/naka_disk_warning.bin", 0x1A1A, 0xC	; "%02X%04X  "
DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt2X_Fmt2X_Fmt2X_Fmt2X:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A26, 0x28	; "%02X %02X %02X %02X %02X %02X %02X %02X"
; [nakarest] naka_disk_warning+0x1a4e  +0x1a4e..+0x1a66 (0xeaa6fa, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xeaa6fa not derived; readers below
; [nakarest] Readers: source references DbMemDump_OK (ui/ui_widget_defs.s: `add xwa,
; [nakarest] DbMemDump_StepTable`).
DbMemDump_StepTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A4E, 0x18
; [nakarest] naka_disk_warning+0x1a66  +0x1a66..+0x1a98 (0xeaa712, 50 B)
; [nakarest] purpose not established: layout of 50 B at 0xeaa712 not derived; readers below
; [nakarest] Readers: source references DbDebugMenu_Confirm (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (DbDebugMenu_Confirm_PtrTable:24)`), DbDebugMenu_OK_Advance (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (DbDebugMenu_Confirm_PtrTable:24)`).
DbDebugMenu_Confirm_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A66, 0x32	; 4 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1a98  +0x1a98..+0x1aa4 (0xeaa744, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa744 not derived; readers below
; [nakarest] Readers: source references DbDebugMenu_Close (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (DbDebugMenu_Init_Str_N1:24)`), DbDebugMenu_Init (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (DbDebugMenu_Init_Str_N1:24)`), DbDebugMenu_OK (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (DbDebugMenu_Init_Str_N1:24)`), DbDebugMenu_OK_CheckValid (ui/ui_widget_defs.s: `lda xbc,
; [nakarest] (DbDebugMenu_Init_Str_N1:24)`).
DbDebugMenu_Init_Str_N1:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A98, 0x2	; "1"
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A9A, 0xA	; 10 bytes after DbDebugMenu_Init_Str_N1's string; unnamed (they sat under its label until 2026-10-03)
; [nakarest] naka_disk_warning+0x1aa4  +0x1aa4..+0x1b44 (0xeaa750, 160 B)
; [nakarest] purpose not established: layout of 160 B at 0xeaa750 not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] PsTrackSwitchProc_PtrTable`).
PsTrackSwitchProc_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1AA4, 0xA0	; 20 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1b44  +0x1b44..+0x1b6e (0xeaa7f0, 42 B)
; [nakarest] purpose not established: layout of 42 B at 0xeaa7f0 not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] PsTrackSwitchProc_PtrTable_2`).
PsTrackSwitchProc_PtrTable_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B44, 0x2A	; 5 x 32-bit pointer
; [nakarest] naka_disk_warning+0x1b6e  +0x1b6e..+0x1b7e (0xeaa81a, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa81a not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] PsTrackSwitchProc_Data`).
PsTrackSwitchProc_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B6E, 0xA
PsTrkSw_Confirm_DrawGeometry_Str_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B78, 0x4	; "%d"
AcTrkSw_Select_Data:			.incbin "includes/generated/naka_disk_warning.bin", 0x1B7C, 0x2
; [nakarest] naka_disk_warning+0x1b7e  +0x1b7e..+0x1b88 (0xeaa82a, 10 B)
; [nakarest] Text (10 B at 0xeaa82a), first string "PsTextBox"; no registered NAKA table points
; [nakarest] into it; reached through source references AcTrkSw_Select_HighTrack
; [nakarest] (ui/ui_widget_defs.s: `lda xhl, (AcTrkSw_Select_HighTrack_Str_PsTextBox:24)`).
AcTrkSw_Select_HighTrack_Str_PsTextBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B7E, 0xA	; "PsTextBox"
; [nakarest] naka_disk_warning+0x1b88  +0x1b88..+0x1b98 (0xeaa834, 16 B)
; [nakarest] Text (16 B at 0xeaa834), first string "AcLanguageText"; no registered NAKA table
; [nakarest] points into it; reached through source references AcTrkSw_ShowHide_CheckDirty
; [nakarest] (ui/ui_widget_defs.s: `lda xhl, (AcTrkSw_ShowHide_CheckDirty_Str_AcLanguageText:24)`).
AcTrkSw_ShowHide_CheckDirty_Str_AcLanguageText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B88, 0x10	; "AcLanguageText"
; [nakarest] naka_disk_warning+0x1b98  +0x1b98..+0x1bf8 (0xeaa844, 96 B)
; [nakarest] purpose not established: layout of 96 B at 0xeaa844 not derived; readers below
; [nakarest] Readers: source references LanguageCheck (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (LanguageCheck_PtrTable:24)`).
LanguageCheck_PtrTable:			.incbin "includes/generated/naka_disk_warning.bin", 0x1B98, 0x4C	; 6 x 32-bit pointer
ObjectProc_OnGetPropString_Str_YZ:		.incbin "includes/generated/naka_disk_warning.bin", 0x1BE4, 0x4	; "YZ"
ObjectProc_OnGetPropName_Str_name:		.incbin "includes/generated/naka_disk_warning.bin", 0x1BE8, 0x6	; "name"
ObjectProc_OnGetPropName_Str_romram:	.incbin "includes/generated/naka_disk_warning.bin", 0x1BEE, 0x8	; "romram"
ObjectProc_OnGetPropName_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1BF6, 0x2	; ""
; [nakarest] naka_disk_warning+0x1bf8  +0x1bf8..+0x1c20 (0xeaa8a4, 40 B)
; [nakarest] purpose not established: layout of 40 B at 0xeaa8a4 not derived; readers below
; [nakarest] Readers: source references ObjectProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] ObjectProc_Data`).
ObjectProc_Data:
	.short	AcTrkSw_Return - AcTrkSw_Return
	.short	ObjectProc_OnGetParentClass - AcTrkSw_Return
	.short	ObjectProc_OnGetClassName - AcTrkSw_Return
	.short	ObjectProc_OnGetProcedure - AcTrkSw_Return
	.short	ObjectProc_OnCheckClass - AcTrkSw_Return
	.short	ExitWindow_Init - AcTrkSw_Return
	.short	ExitWindow_Init - AcTrkSw_Return
	.short	ObjectProc_OnGetPropCount - AcTrkSw_Return
	.short	ObjectProc_OnGetPropName - AcTrkSw_Return
	.short	ObjectProc_OnGetPropString - AcTrkSw_Return
	.short	ObjectProc_OnCopyProperty - AcTrkSw_Return
	.short	ObjectProc_OnDumpProperty - AcTrkSw_Return
	.short	ObjectProc_OnDumpPointer - AcTrkSw_Return
	.short	ObjectProc_OnGetProperty - AcTrkSw_Return
	.short	ObjectProc_OnSetProperty - AcTrkSw_Return
	.short	ObjectProc_OnGetPropData - AcTrkSw_Return
	.short	ObjectProc_OnGetPropDataCount - AcTrkSw_Return
	.short	ObjectProc_OnGetInstanceSize - AcTrkSw_Return
	.short	ObjectProc_OnGetPropChar - AcTrkSw_Return
	.short	ObjectProc_OnAutoFree - AcTrkSw_Return
; [nakarest] naka_disk_warning+0x1c20  +0x1c20..+0x1c30 (0xeaa8cc, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa8cc not derived; readers below
; [nakarest] Readers: source references ExitWindow_Confirm (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] ExitWindow_Confirm_Data`).
ExitWindow_Confirm_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C20, 0x10
; [nakarest] naka_disk_warning+0x1c30  +0x1c30..+0x1c48 (0xeaa8dc, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xeaa8dc not derived; readers below
; [nakarest] Readers: source references ExitWindow_OK (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] ExitWindow_OK_Data`).
ExitWindow_OK_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C30, 0x18
; [nakarest] naka_disk_warning+0x1c48  +0x1c48..+0x1c4a (0xeaa8f4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa8f4 not derived; readers below
; [nakarest] Readers: source references InputDialog_Confirm (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (InputDialog_Confirm_Data:24)`).
InputDialog_Confirm_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C48, 0x2
; [nakarest] naka_disk_warning+0x1c4a  +0x1c4a..+0x1c4c (0xeaa8f6, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa8f6 not derived; readers below
; [nakarest] Readers: source references UnRegisterObject (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (UnRegisterObject_Data:24)`).
UnRegisterObject_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4A, 0x2
; [nakarest] naka_disk_warning+0x1c4c  +0x1c4c..+0x1c5c (0xeaa8f8, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa8f8 not derived; readers below
; [nakarest] Readers: source references ClassProc (ui/ui_widget_defs.s: `add xbc,
; [nakarest] ClassProc_Data`).
ClassProc_Data:
	.short	ClassProc_Event_LoadFromWA - ClassProc_Event_LoadFromWA
	.short	ClassProc_Event_LoadFromHL - ClassProc_Event_LoadFromWA
	.short	ClassProc_Event_LoadFromIZ - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetInstanceSizeSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnCheckClassSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropStringEx - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropCountSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropNameSp - ClassProc_Event_LoadFromWA
; [nakarest] naka_disk_warning+0x1c5c  +0x1c5c..+0x1c68 (0xeaa908, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa908 not derived; readers below
; [nakarest] Readers: source references ModeProc (ui/ui_widget_defs.s: `add xbc, ModeProc_Data`).
ModeProc_Data:
	.short	ModeProc_OnGetModeProc - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeProcId - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetStartTitle - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeNow - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeOld - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetUserId - NakaWidget_ReturnConst_0x1600006
; [nakarest] naka_disk_warning+0x1c68  +0x1c68..+0x1c6a (0xeaa914, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa914 not derived; readers below
; [nakarest] Readers: source references UnregisteredMode (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (UnregisteredMode_Data:24)`).
UnregisteredMode_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C68, 0x2
; [nakarest] naka_disk_warning+0x1c6a  +0x1c6a..+0x1c6c (0xeaa916, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa916 not derived; readers below
; [nakarest] Readers: source references UnregisteredTitle (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (UnregisteredTitle_Data:24)`).
UnregisteredTitle_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C6A, 0x2
; [nakarest] naka_disk_warning+0x1c6c  +0x1c6c..+0x1c70 (0xeaa918, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaa918 not derived; readers below
; [nakarest] Readers: source references EnumList_HitTest_Loop (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] TitleProc_Data`), EnumList_OK_ScrollUp_Done (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] TitleProc_Data`), TitleProc (ui/ui_widget_defs.s: `ld xbc, TitleProc_Data`).
TitleProc_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C6C, 0x4
; [nakarest] naka_disk_warning+0x1c70  +0x1c70..+0x1d14 (0xeaa91c, 164 B)
; [nakarest] purpose not established: layout of 164 B at 0xeaa91c not derived; readers below
; [nakarest] Readers: source references EnumList_HitTest (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (EnumList_HitTest_Data:24)`).
EnumList_HitTest_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C70, 0xA4
; [nakarest] naka_disk_warning+0x1d14  +0x1d14..+0x1d20 (0xeaa9c0, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa9c0 not derived; readers below
; [nakarest] Readers: source references TitleProc (ui/ui_widget_defs.s: `add xde,
; [nakarest] TitleProc_Str_j`).
TitleProc_Str_j:
	.short	TitleProc_OnGetUserId - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleProc - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleProcId - TitleProc_EventDispatch
	.short	TitleProc_OnGetStartScreen - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleNow - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleOld - TitleProc_EventDispatch
; [nakarest] naka_disk_warning+0x1d20  +0x1d20..+0x1d3a (0xeaa9cc, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xeaa9cc not derived; readers below
; [nakarest] Readers: source references EnumList_Reset (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] EnumList_Reset_Data`).
EnumList_Reset_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D20, 0x1A
; [nakarest] naka_disk_warning+0x1d3a  +0x1d3a..+0x1d48 (0xeaa9e6, 14 B)
; [nakarest] purpose not established: layout of 14 B at 0xeaa9e6 not derived; readers below
; [nakarest] Readers: source references ViewableProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] ViewableProc_Data`).
ViewableProc_Data:
	.short	ViewableProc_OnPaint - Viewable_GetClassProc
	.short	ViewableProc_OnRepaint - Viewable_GetClassProc
	.short	Viewable_ReturnZero - Viewable_GetClassProc
	.short	Viewable_ReturnZero - Viewable_GetClassProc
	.short	Viewable_ReturnZero - Viewable_GetClassProc
	.short	Viewable_DefaultDispatch - Viewable_GetClassProc
	.short	Viewable_ReturnZero - Viewable_GetClassProc
; [nakarest] naka_disk_warning+0x1d48  +0x1d48..+0x1d52 (0xeaa9f4, 10 B)
; [nakarest] Text (10 B at 0xeaa9f4), first string "bool %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle7_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle7_Setup_Data`).
BoxStyle7_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D48, 0xA
; [nakarest] naka_disk_warning+0x1d52  +0x1d52..+0x1d58 (0xeaa9fe, 6 B)
; [nakarest] Text (6 B at 0xeaa9fe), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle7_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle7_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle7_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D52, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d58  +0x1d58..+0x1d64 (0xeaaa04, 12 B)
; [nakarest] Text (12 B at 0xeaaa04), first string "sword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle8_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle8_Setup_Data`).
BoxStyle8_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D58, 0xC
; [nakarest] naka_disk_warning+0x1d64  +0x1d64..+0x1d6a (0xeaaa10, 6 B)
; [nakarest] Text (6 B at 0xeaaa10), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle8_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle8_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle8_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D64, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d6a  +0x1d6a..+0x1d76 (0xeaaa16, 12 B)
; [nakarest] Text (12 B at 0xeaaa16), first string "uword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle9_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle9_Setup_Data`).
BoxStyle9_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D6A, 0xC
; [nakarest] naka_disk_warning+0x1d76  +0x1d76..+0x1d7c (0xeaaa22, 6 B)
; [nakarest] Text (6 B at 0xeaaa22), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle9_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle9_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle9_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D76, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d7c  +0x1d7c..+0x1d88 (0xeaaa28, 12 B)
; [nakarest] Text (12 B at 0xeaaa28), first string "schar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle10_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle10_Setup_Data`).
BoxStyle10_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D7C, 0xC
; [nakarest] naka_disk_warning+0x1d88  +0x1d88..+0x1d8e (0xeaaa34, 6 B)
; [nakarest] Text (6 B at 0xeaaa34), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle10_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle10_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle10_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D88, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d8e  +0x1d8e..+0x1d9a (0xeaaa3a, 12 B)
; [nakarest] Text (12 B at 0xeaaa3a), first string "uchar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle11_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle11_Setup_Data`).
BoxStyle11_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D8E, 0xC
; [nakarest] naka_disk_warning+0x1d9a  +0x1d9a..+0x1da0 (0xeaaa46, 6 B)
; [nakarest] Text (6 B at 0xeaaa46), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle11_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle11_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle11_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D9A, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1da0  +0x1da0..+0x1dac (0xeaaa4c, 12 B)
; [nakarest] Text (12 B at 0xeaaa4c), first string "slong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle12_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle12_Setup_Data`).
BoxStyle12_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DA0, 0xC
; [nakarest] naka_disk_warning+0x1dac  +0x1dac..+0x1db2 (0xeaaa58, 6 B)
; [nakarest] Text (6 B at 0xeaaa58), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle12_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle12_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle12_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1DAC, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1db2  +0x1db2..+0x1dbe (0xeaaa5e, 12 B)
; [nakarest] Text (12 B at 0xeaaa5e), first string "ulong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle13_Setup_Data`).
BoxStyle13_Setup_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DB2, 0xC
; [nakarest] naka_disk_warning+0x1dbe  +0x1dbe..+0x1ed0 (0xeaaa6a, 274 B)
; [nakarest] Text (274 B at 0xeaaa6a), first string "&%s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_CalcWidth
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, BoxStyle13_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle13_CalcWidth_Str_Fmts_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DBE, 0x6	; "&%s%d"
EdgeDraw_TopRight_Inner_Str_left:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DC4, 0x6	; ".left"
EdgeDraw_TopRight_Inner_Str_LBrace:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DCA, 0x2	; "{"
EdgeDraw_BottomRight_Str_top:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DCC, 0x6	; ".top"
TabDraw_TopEdge_Str_width:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DD2, 0x8	; ".width"
EdgeVariant_A_Setup_Str_height:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DDA, 0x8	; ".height"
EdgeVariant_A_CalcWidth_Str_RBrace:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DE2, 0x2	; "}"
EdgeVariant_C_CalcWidth_Str_x:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DE4, 0x4	; ".x"
EdgeVariant_C_CalcHeight_Str_LBrace:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DE8, 0x2	; "{"
ShadowBox_A_Setup_Str_y:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DEA, 0x4	; ".y"
ShadowBox_A_CalcWidth_Str_RBrace:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DEE, 0x2	; "}"
ShadowBox_B_Prologue_Str_idc:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF0, 0x4	; "idc"
ScrollBar_CalcRange_Str_DQuote:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF4, 0x2	; """
ScrollBar_CalcRange_Str_DQuote_2:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DF6, 0x2	; """
SliderH_Prologue_Str_id:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF8, 0x4	; "id"
SliderV_Prologue_Str_idICON:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DFC, 0x8	; "idICON_"
DrawHelper_A_Prologue_Str_id:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E04, 0x4	; "id"
DrawHelper_B_FinishAlt_Str_idf:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E08, 0x4	; "idf"
DrawHelper_D_FinishAlt_Str_idf:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E0C, 0x4	; "idf"
ViewID_EventSwitch_Str_idNONE:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E10, 0x8	; "idNONE"
ViewID_Select_Lookup_Str_idi_Fmts:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E18, 0x6	; "idi%s"
ViewID_Select_NoName_Str_idi_Fmts_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E1E, 0x8	; "idi%s%d"
ViewID_GetInfoStr_Str_sword:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E26, 0x8	; "(sword)"
ViewID_GetCurrent_Str_idi_Fmts:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E2E, 0x6	; "idi%s"
ViewID_GetCurrent_NoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E34, 0x8	; "idi%s%d"
ViewID_GetCurrent_None_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E3C, 0x8	; "idNONE"
ScreenID_EventSwitch_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E44, 0x8	; "idNONE"
ScreenID_Select_Lookup_Str_idi_Fmts:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E4C, 0x6	; "idi%s"
ScreenID_Select_NoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E52, 0x8	; "idi%s%d"
ScreenID_GetCurrent_Str_idi_Fmts:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E5A, 0x6	; "idi%s"
ScreenID_GetCurrent_NoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E60, 0x8	; "idi%s%d"
ScreenID_GetCurrent_None_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E68, 0x8	; "idNONE"
ScreenID_EnumOpen_ScanLoop_Str_idi_Fmts:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E70, 0x6	; "idi%s"
ScreenID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E76, 0x8	; "idi%s%d"
ScreenID_EnumOpen_NotFound_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E7E, 0x8	; "idNONE"
WindowID_EventSwitch_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E86, 0x8	; "idNONE"
WindowID_Select_Lookup_Str_idi_Fmts:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E8E, 0x6	; "idi%s"
WindowID_Select_NoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1E94, 0x8	; "idi%s%d"
WindowID_GetCurrent_Str_idi_Fmts:		.incbin "includes/generated/naka_disk_warning.bin", 0x1E9C, 0x6	; "idi%s"
WindowID_GetCurrent_NoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1EA2, 0x8	; "idi%s%d"
WindowID_GetCurrent_None_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1EAA, 0x8	; "idNONE"
WindowID_EnumOpen_ScanLoop_Str_idi_Fmts:	.incbin "includes/generated/naka_disk_warning.bin", 0x1EB2, 0x6	; "idi%s"
WindowID_EnumOpen_ScanNoName_Str_idi_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1EB8, 0x8	; "idi%s%d"
WindowID_EnumOpen_NotFound_Str_idNONE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1EC0, 0x8	; "idNONE"
ModeID_EnumFill_Str_Mode_Fmtd:			.incbin "includes/generated/naka_disk_warning.bin", 0x1EC8, 0x8	; "Mode%d"
; [nakarest] naka_disk_warning+0x1ed0  +0x1ed0..+0x1ed4 (0xeaab7c, 4 B)
; [nakarest] Text (4 B at 0xeaab7c), first string "%d"; no registered NAKA table points into it;
; [nakarest] reached through source references ModeID_GetCurrent (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] ModeID_GetCurrent_Str_Fmtd`).
ModeID_GetCurrent_Str_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1ED0, 0x4	; "%d"
; [nakarest] naka_disk_warning+0x1ed4  +0x1ed4..+0x1efc (0xeaab80, 40 B)
; [nakarest] Text (40 B at 0xeaab80), first string "MAKEMODEID(%s)"; no registered NAKA table
; [nakarest] points into it; reached through source references ModeID_GetCurrent_HasName
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, ModeID_GetCurrent_HasName_Str_MAKEMODEID_Fmts`).
ModeID_GetCurrent_HasName_Str_MAKEMODEID_Fmts:	.incbin "includes/generated/naka_disk_warning.bin", 0x1ED4, 0x10	; "MAKEMODEID(%s)"
ModeID_GetNext_Str_Mode_Fmtd:			.incbin "includes/generated/naka_disk_warning.bin", 0x1EE4, 0x8	; "Mode%d"
ModeID_EnumOpen_SearchLoop_Str_Mode_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1EEC, 0x8	; "Mode%d"
TitleID_EnumFill_Str_Title_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1EF4, 0x8	; "Title%d"
; [nakarest] naka_disk_warning+0x1efc  +0x1efc..+0x1f00 (0xeaaba8, 4 B)
; [nakarest] Text (4 B at 0xeaaba8), first string "%d"; no registered NAKA table points into it;
; [nakarest] reached through source references TitleID_GetCurrent (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] TitleID_GetCurrent_Str_Fmtd`).
TitleID_GetCurrent_Str_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1EFC, 0x4	; "%d"
; [nakarest] naka_disk_warning+0x1f00  +0x1f00..+0x1f20 (0xeaabac, 32 B)
; [nakarest] Text (32 B at 0xeaabac), first string "MAKETITLEID(%s)"; no registered NAKA table
; [nakarest] points into it; reached through source references TitleID_GetCurrent_HasName
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, TitleID_GetCurrent_HasName_Str_MAKETITLEID_Fmts`).
TitleID_GetCurrent_HasName_Str_MAKETITLEID_Fmts:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F00, 0x10	; "MAKETITLEID(%s)"
TitleID_GetNext_Str_Title_Fmtd:				.incbin "includes/generated/naka_disk_warning.bin", 0x1F10, 0x8	; "Title%d"
TitleID_EnumOpen_SearchLoop_Str_Title_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1F18, 0x8	; "Title%d"
; [nakarest] naka_disk_warning+0x1f20  +0x1f20..+0x1f26 (0xeaabcc, 6 B)
; [nakarest] Text (6 B at 0xeaabcc), first string "name"; no registered NAKA table points into
; [nakarest] it; reached through source references NameProc_Init (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] NameProc_Init_Str_name`).
NameProc_Init_Str_name:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F20, 0x6	; "name"
; [nakarest] naka_disk_warning+0x1f26  +0x1f26..+0x1f2a (0xeaabd2, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaabd2 not derived; readers below
; [nakarest] Readers: source references NameProc_Init_SetPtr (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] NameProc_Init_SetPtr_Data`).
NameProc_Init_SetPtr_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F26, 0x2
NameProc_GetText_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F28, 0x2	; ""
; [nakarest] naka_disk_warning+0x1f2a  +0x1f2a..+0x1f32 (0xeaabd6, 8 B)
; [nakarest] Text (8 B at 0xeaabd6), first string "romram"; no registered NAKA table points into
; [nakarest] it; reached through source references ConstFlagProc_GetValue (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, ConstFlagProc_GetValue_Str_romram`).
ConstFlagProc_GetValue_Str_romram:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F2A, 0x8	; "romram"
; [nakarest] naka_disk_warning+0x1f32  +0x1f32..+0x1f38 (0xeaabde, 6 B)
; [nakarest] purpose not established: layout of 6 B at 0xeaabde not derived; readers below
; [nakarest] Readers: source references ConstFlagProc_GetValue_Set (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, ConstFlagProc_GetValue_Set_Data`).
ConstFlagProc_GetValue_Set_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F32, 0x2
ConstFlagProc_SetValue_Check_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F34, 0x2	; ""
CommonIDProc_OnDumpPointerEx_Data:		.incbin "includes/generated/naka_disk_warning.bin", 0x1F36, 0x2
; [nakarest] naka_disk_warning+0x1f38  +0x1f38..+0x1f46 (0xeaabe4, 14 B)
; [nakarest] purpose not established: layout of 14 B at 0xeaabe4 not derived; readers below
; [nakarest] Readers: source references CommonIDProc (ui/ui_widget_defs.s: `add xde,
; [nakarest] CommonIDProc_Data`).
CommonIDProc_Data:
	.short	CommonIDProc_ReturnZero - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPointerEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnSetPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnGetPropDataSp - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnGetPropDataCountSp - CommonIDProc_OnGetPropDataSp
; [nakarest] naka_disk_warning+0x1f46  +0x1f46..+0x214a (0xeaabf2, 516 B)
; [nakarest] purpose not established: layout of 516 B at 0xeaabf2 not derived; readers below
; [nakarest] Readers: source references DrawIcons_Impl_ColLoop (ui/drawing_primitives.s: `lda
; [nakarest] xbc, (DrawIcons_Impl_ColLoop_Data:24)`).
DrawIcons_Impl_ColLoop_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F46, 0x200
DrawBitmapFile_Impl_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x2146, 0x4
; [nakarest] naka_disk_warning+0x214a  +0x214a..+0x216a (0xeaadf6, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaadf6 not derived; readers below
; [nakarest] Readers: source references DrawPartGroup_DispatchByType (ui/ui_window_procs.s: `lda
; [nakarest] xix, (DrawPartGroup_DispatchByType_Data:24)`).
DrawPartGroup_DispatchByType_Data:
	.short	DrawDesignBox_PartGroupStyle_Case24 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case25 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case26 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case27 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case28 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case29 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case30 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case31 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case32 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case33 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case34 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case35 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case36 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case37 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case38 - DrawPartGroup_TableJump_DefaultCase
	.short	DrawDesignBox_PartGroupStyle_Case39 - DrawPartGroup_TableJump_DefaultCase
; [nakarest] naka_disk_warning+0x216a  +0x216a..+0x21b2 (0xeaae16, 72 B)
; [nakarest] purpose not established: layout of 72 B at 0xeaae16 not derived; readers below
; [nakarest] Readers: source references Draw_DispatchByPartType (ui/ui_window_procs.s: `lda xix,
; [nakarest] (Draw_DispatchByPartType_Data:24)`).
Draw_DispatchByPartType_Data:
	.short	Draw_StyledBoxWithFrame - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case181 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case181 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case181 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case184 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case185 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_IconStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_PartGroupStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_PartGroupStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_PartGroupStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_PartGroupStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_PartGroupStyle - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case192 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case193 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case192 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case193 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case196 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case197 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case196 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case197 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case200 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case201 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case201 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case203 - Draw_StyledBoxWithFrame
	.short	DrawDesignBox_Impl_Case204 - Draw_StyledBoxWithFrame
Gfx_LoadSplashBMP_Data:		.incbin "includes/generated/naka_disk_warning.bin", 0x219C, 0x4
CaptureLcd_Str_BM:		.incbin "includes/generated/naka_disk_warning.bin", 0x21A0, 0x4	; "BM"
CaptureLcd_Str_HKLCD_Fmt3d_BMP:	.incbin "includes/generated/naka_disk_warning.bin", 0x21A4, 0xE	; "HKLCD%03d.BMP"
; [nakarest] naka_disk_warning+0x21b2  +0x21b2..+0x21b6 (0xeaae5e, 4 B)
; [nakarest] Text (4 B at 0xeaae5e), first string "wb"; no registered NAKA table points into it;
; [nakarest] reached through source references CaptureLcd (ui/ui_window_procs.s: `ld xbc,
; [nakarest] CaptureLcd_Str_wb`).
CaptureLcd_Str_wb:	.incbin "includes/generated/naka_disk_warning.bin", 0x21B2, 0x4	; "wb"
; [nakarest] naka_disk_warning+0x21b6  +0x21b6..+0x21ba (0xeaae62, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaae62 not derived; readers below
; [nakarest] Readers: source references ChangeWall_Impl (ui/ui_window_procs.s: `ld xwa,
; [nakarest] ChangeWall_Impl_Data`).
ChangeWall_Impl_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x21B6, 0x4
; [nakarest] naka_disk_warning+0x21ba  +0x21ba..+0x21e8 (0xeaae66, 46 B)
; [nakarest] purpose not established: layout of 46 B at 0xeaae66 not derived; readers below
; [nakarest] Readers: source references ChangePalette_Impl (ui/ui_window_procs.s: `lda xwa,
; [nakarest] (ChangePalette_Impl_Data:24)`).
ChangePalette_Impl_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x21BA, 0x2E
; [nakarest] naka_disk_warning+0x21e8  +0x21e8..+0x2228 (0xeaae94, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xeaae94 not derived; readers below
; [nakarest] Readers: source references ClipBlit_Replace_ScanlineLoop (ui/ui_window_procs.s:
; [nakarest] `lda xwa, (ClipBlit_Replace_ScanlineLoop_Data:24)`).
ClipBlit_Replace_ScanlineLoop_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x21E8, 0x40
; [nakarest] naka_disk_warning+0x2228  +0x2228..+0x2248 (0xeaaed4, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaaed4 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_ByteData_Loop2
; [nakarest] (display/graphics_text_vga.s: `ld xbc, GraphicsRender_ByteData_Data`).
GraphicsRender_ByteData_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2228, 0x20
; [nakarest] naka_disk_warning+0x2248  +0x2248..+0x2268 (0xeaaef4, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaaef4 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_ByteData_Loop3
; [nakarest] (display/graphics_text_vga.s: `.long Pad_AfterStr_No`).
Pad_AfterStr_No:	.incbin "includes/generated/naka_disk_warning.bin", 0x2248, 0x20
; GraphicsRender_ProcessEntries_PtrTable -- 36 x u32, the handler of each static display-list record op
; ({u8 op, u8 len, payload}; the sd_* macros of audio/sound_editor_ui.s).  GraphicsRender_ProcessEntries
; calls [op] with the record.  Lines 00-02, dotted lines 11/12/15, dotted box 13, box 09, shadowed boxes
; 22 / 0A, highlight fill 05, bitmap 03, text at a cell 06/07/08/20 (fonts 0/1/2/6) or a pixel 17/1C (fonts
; 3/4), design box 23; GraphicsRender_RetStub = no such op (scripts/tools/label_segfx_ops.py).
GraphicsRender_ProcessEntries_PtrTable:
	.long	SeGfx_StaticOp00_Line
	.long	SeGfx_StaticOp01_Line
	.long	SeGfx_StaticOp02_Line
	.long	SeGfx_StaticOp03_Bitmap
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp05_FillBoxMode1
	.long	SeGfx_StaticOp06_CellTextFont0
	.long	SeGfx_StaticOp07_CellTextFont1
	.long	SeGfx_StaticOp08_CellTextFont2
	.long	SeGfx_StaticOp09_Box
	.long	SeGfx_StaticOp0A_ShadowBox2
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	ColorBlit_ComputeRectAndBlit
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp11_DottedLine
	.long	SeGfx_StaticOp12_DottedLine
	.long	SeGfx_StaticOp13_DottedBox
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp15_DottedLine
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp17_PixelTextFont3
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	ColorBlit_ByteData
	.long	SeGfx_StaticOp1C_PixelTextFont4
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp20_CellTextFont6
	.long	GraphicsRender_RetStub
	.long	SeGfx_StaticOp22_ShadowBox1
	.long	SeGfx_StaticOp23_DesignBox
; GraphicsRender_Start_PtrTable -- 12 x u32, the handler of each bound display record op (a value read from
; RAM: the sdb_* macros of audio/sound_editor_ui.s); GraphicsRender_Start calls [op].  Ops 08-0B are not
; named: their record layouts are not derived yet.
GraphicsRender_Start_PtrTable:
	.long	DrawFunc_Init
	.long	GraphicsRender_RetStub
	.long	DrawText_ExtendedLayout
	.long	ColorBlit_WithPaletteSave
	.long	ColorBlit_Variant_ByteData
	.long	DrawFunc_Init_Variant1
	.long	SeGfx_BoundOp06_Helper
	.long	DrawText_ExtLayout_Variant1
	.long	0x00fb25a3
	.long	0x00fb22a3
	.long	0x00fb2438
	.long	0x00fb2346
; [nakarest] naka_disk_warning+0x2328  +0x2328..+0x2330 (0xeaafd4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafd4 not derived; readers below
; [nakarest] Readers: source references SeGfx_StaticOp06_CellTextFont0 (display/graphics_text_vga.s:
; [nakarest] `ld xiy, DrawText_LayoutAndRender_Data`).
DrawText_LayoutAndRender_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2328, 0x8
; [nakarest] naka_disk_warning+0x2330  +0x2330..+0x2338 (0xeaafdc, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafdc not derived; readers below
; [nakarest] Readers: source references SeGfx_StaticOp07_CellTextFont1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_LayoutAndRender_Variant1_Data`).
DrawText_LayoutAndRender_Variant1_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2330, 0x8
; [nakarest] naka_disk_warning+0x2338  +0x2338..+0x2340 (0xeaafe4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafe4 not derived; readers below
; [nakarest] Readers: source references SeGfx_StaticOp07_CellTextFont1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_LayoutAndRender_Variant1_Data_2`).
DrawText_LayoutAndRender_Variant1_Data_2:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2338, 0x8
; [nakarest] naka_disk_warning+0x2340  +0x2340..+0x2348 (0xeaafec, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafec not derived; readers below
; [nakarest] Readers: source references SeGfx_StaticOp07_CellTextFont1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_LayoutAndRender_Variant1_Data_3`).
DrawText_LayoutAndRender_Variant1_Data_3:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2340, 0x8
; [nakarest] naka_disk_warning+0x2348  +0x2348..+0x2350 (0xeaaff4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaaff4 not derived; readers below
; [nakarest] Readers: source references SeGfx_StaticOp07_CellTextFont1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_LayoutAndRender_Variant1_Data_4`).
DrawText_LayoutAndRender_Variant1_Data_4:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2348, 0x8
; [nakarest] naka_disk_warning+0x2350  +0x2350..+0x2358 (0xeaaffc, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaaffc not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1_Loop
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_LayoutAndRender_Variant1_Data_5`).
DrawText_LayoutAndRender_Variant1_Data_5:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2350, 0x8
; [nakarest] naka_disk_warning+0x2358  +0x2358..+0x2458 (0xeab004, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xeab004 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join2 (display/graphics_text_vga.s: `lda
; [nakarest] xbc, (Scoop_EnvelopeCalc_Data_2:24)`), DrawFunc_Init_Join3 (display/graphics_text_vga.s: `lda
; [nakarest] xbc, (Scoop_EnvelopeCalc_Data_2:24)`), DrawFunc_Init_PushFontAndDraw
; [nakarest] (display/graphics_text_vga.s: `lda xbc, (Scoop_EnvelopeCalc_Data_2:24)`),
; [nakarest] DrawText_ExtLayout_NullAndDraw (display/graphics_text_vga.s: `lda xbc,
; [nakarest] (Scoop_EnvelopeCalc_Data_2:24)`), 5 more.
Scoop_EnvelopeCalc_Data_2:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2358, 0x100
; [nakarest] naka_disk_warning+0x2458  +0x2458..+0x2468 (0xeab104, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeab104 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join4 (display/graphics_text_vga.s: `lda
; [nakarest] xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)`), DrawFunc_Init_Join6 (display/graphics_text_vga.s: `lda
; [nakarest] xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)`), DrawFunc_Init_Join7 (display/graphics_text_vga.s: `lda
; [nakarest] xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)`), DrawText_ExtendedLayout_Skip
; [nakarest] (display/graphics_text_vga.s: `lda xbc, (Scoop_EventLoop_36Entry_Branch3_Data_3:24)`), 3 more.
Scoop_EventLoop_36Entry_Branch3_Data_3:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2458, 0x10
; [nakarest] naka_disk_warning+0x2468  +0x2468..+0x2470 (0xeab114, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab114 not derived; readers below
; [nakarest] Readers: source references DrawText_ExtendedLayout (display/graphics_text_vga.s:
; [nakarest] `ld xiy, DrawText_ExtendedLayout_Data`).
DrawText_ExtendedLayout_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2468, 0x8
; [nakarest] naka_disk_warning+0x2470  +0x2470..+0x2478 (0xeab11c, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab11c not derived; readers below
; [nakarest] Readers: source references DrawText_ExtLayout_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, DrawText_ExtLayout_Variant1_Data`).
DrawText_ExtLayout_Variant1_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2470, 0x8
; [nakarest] naka_disk_warning+0x2478  +0x2478..+0x2480 (0xeab124, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab124 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init (display/graphics_text_vga.s: `ld xiy,
; [nakarest] DrawFunc_Init_Data`).
DrawFunc_Init_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2478, 0x8
; [nakarest] naka_disk_warning+0x2480  +0x2480..+0x2484 (0xeab12c, 4 B)
; [nakarest] Text (4 B at 0xeab12c), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_SkipShift
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_SkipShift_Str_Fmt1d`).
DrawFunc_Init_SkipShift_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2480, 0x4	; "%1d"
; [nakarest] naka_disk_warning+0x2484  +0x2484..+0x2488 (0xeab130, 4 B)
; [nakarest] Text (4 B at 0xeab130), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_FontTable2
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_FontTable2_Str_Fmt2d`).
DrawFunc_Init_FontTable2_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2484, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x2488  +0x2488..+0x248c (0xeab134, 4 B)
; [nakarest] Text (4 B at 0xeab134), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_FontTable0
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_FontTable0_Str_Fmt3d`).
DrawFunc_Init_FontTable0_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2488, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x248c  +0x248c..+0x2494 (0xeab138, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab138 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Variant1 (display/graphics_text_vga.s: `ld
; [nakarest] xiy, DrawFunc_Init_Variant1_Data`).
DrawFunc_Init_Variant1_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x248C, 0x8
; [nakarest] naka_disk_warning+0x2494  +0x2494..+0x24a0 (0xeab140, 12 B)
; [nakarest] Text (12 B at 0xeab140), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Variant1_Str_Fmt1d`).
DrawFunc_Init_Variant1_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2494, 0x4	; "%1d"
DrawFunc_Init_Variant1_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2498, 0x4	; "%2d"
DrawFunc_Init_Variant1_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x249C, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24a0  +0x24a0..+0x24a4 (0xeab14c, 4 B)
; [nakarest] Text (4 B at 0xeab14c), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip4
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry_Str_Fmt2d`).
DrawFunc_Init_Entry_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24A0, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x24a4  +0x24a4..+0x24a8 (0xeab150, 4 B)
; [nakarest] Text (4 B at 0xeab150), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip5
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry_Str_Fmt3d`).
DrawFunc_Init_Entry_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24A4, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24a8  +0x24a8..+0x24ac (0xeab154, 4 B)
; [nakarest] Text (4 B at 0xeab154), first string "%4d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip6
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry_Str_Fmt4d`).
DrawFunc_Init_Entry_Str_Fmt4d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24A8, 0x4	; "%4d"
; [nakarest] naka_disk_warning+0x24ac  +0x24ac..+0x24b4 (0xeab158, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab158 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join2 (display/graphics_text_vga.s: `ld
; [nakarest] xiy, DrawFunc_Init_Entry_Data`).
DrawFunc_Init_Entry_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24AC, 0x8
; [nakarest] naka_disk_warning+0x24b4  +0x24b4..+0x24b8 (0xeab160, 4 B)
; [nakarest] Text (4 B at 0xeab160), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join2
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry_Str_Fmt1d`).
DrawFunc_Init_Entry_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24B4, 0x4	; "%1d"
; [nakarest] naka_disk_warning+0x24b8  +0x24b8..+0x24bc (0xeab164, 4 B)
; [nakarest] Text (4 B at 0xeab164), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Entry2
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry2_Str_Fmt2d`).
DrawFunc_Init_Entry2_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24B8, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x24bc  +0x24bc..+0x24c0 (0xeab168, 4 B)
; [nakarest] Text (4 B at 0xeab168), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Entry3
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry3_Str_Fmt3d`).
DrawFunc_Init_Entry3_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24BC, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24c0  +0x24c0..+0x24c8 (0xeab16c, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab16c not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join3 (display/graphics_text_vga.s: `ld
; [nakarest] xiy, DrawFunc_Init_Entry3_Data`).
DrawFunc_Init_Entry3_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24C0, 0x8
; [nakarest] naka_disk_warning+0x24c8  +0x24c8..+0x24cc (0xeab174, 4 B)
; [nakarest] Text (4 B at 0xeab174), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join3
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry3_Str_Fmt1d`).
DrawFunc_Init_Entry3_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24C8, 0x4	; "%1d"
; [nakarest] naka_disk_warning+0x24cc  +0x24cc..+0x24d0 (0xeab178, 4 B)
; [nakarest] Text (4 B at 0xeab178), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join3
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry3_Str_Fmt2d`).
DrawFunc_Init_Entry3_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24CC, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x24d0  +0x24d0..+0x24d4 (0xeab17c, 4 B)
; [nakarest] Text (4 B at 0xeab17c), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join3
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry3_Str_Fmt3d_2`).
DrawFunc_Init_Entry3_Str_Fmt3d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x24D0, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24d4  +0x24d4..+0x24dc (0xeab180, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab180 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join4 (display/graphics_text_vga.s: `ld
; [nakarest] xiy, DrawFunc_Init_Entry3_Data_2`).
DrawFunc_Init_Entry3_Data_2:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24D4, 0x8
; [nakarest] naka_disk_warning+0x24dc  +0x24dc..+0x24e0 (0xeab188, 4 B)
; [nakarest] Text (4 B at 0xeab188), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join5
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry3_Str_Fmt1d_2`).
DrawFunc_Init_Entry3_Str_Fmt1d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x24DC, 0x4	; "%1d"
; [nakarest] naka_disk_warning+0x24e0  +0x24e0..+0x24e4 (0xeab18c, 4 B)
; [nakarest] Text (4 B at 0xeab18c), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Entry4
; [nakarest] (display/graphics_text_vga.s: `.long FmtStr_pct2d`).
FmtStr_pct2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24E0, 0x4
; [nakarest] naka_disk_warning+0x24e4  +0x24e4..+0x24e8 (0xeab190, 4 B)
; [nakarest] Text (4 B at 0xeab190), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip9
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry4_Str_Fmt3d`).
DrawFunc_Init_Entry4_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24E4, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24e8  +0x24e8..+0x24ec (0xeab194, 4 B)
; [nakarest] Text (4 B at 0xeab194), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Entry5
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry5_Str_Fmt2d`).
DrawFunc_Init_Entry5_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24E8, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x24ec  +0x24ec..+0x24f0 (0xeab198, 4 B)
; [nakarest] Text (4 B at 0xeab198), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip10
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry5_Str_Fmt3d`).
DrawFunc_Init_Entry5_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24EC, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x24f0  +0x24f0..+0x24f4 (0xeab19c, 4 B)
; [nakarest] Text (4 B at 0xeab19c), first string "%4d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Skip11
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry5_Str_Fmt4d`).
DrawFunc_Init_Entry5_Str_Fmt4d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24F0, 0x4	; "%4d"
; [nakarest] Data_CharMapFormatBlock  +0x24f4..+0x24fc (0xeab1a0, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab1a0 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join6 (display/graphics_text_vga.s: `.long
; [nakarest] Data_CharMapFormatBlock`).
Data_CharMapFormatBlock:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24F4, 0x8
; [nakarest] naka_disk_warning+0x24fc  +0x24fc..+0x2504 (0xeab1a8, 8 B)
; [nakarest] Text (8 B at 0xeab1a8), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join6
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry5_Str_Fmt1d`).
DrawFunc_Init_Entry5_Str_Fmt1d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24FC, 0x4	; "%1d"
DrawFunc_Init_Entry5_Str_Fmt2d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x2500, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x2504  +0x2504..+0x2508 (0xeab1b0, 4 B)
; [nakarest] Text (4 B at 0xeab1b0), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_Join6
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_Entry5_Str_Fmt3d_2`).
DrawFunc_Init_Entry5_Str_Fmt3d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x2504, 0x4	; "%3d"
; [nakarest] naka_disk_warning+0x2508  +0x2508..+0x2608 (0xeab1b4, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xeab1b4 not derived; readers below
; [nakarest] Readers: source references FontGlyph_ByteData (display/graphics_text_vga.s: `lda
; [nakarest] xde, (TextRender_CharEncodeAndDraw_Data:24)`), TextRender_CharEncodeAndDraw
; [nakarest] (kn5000_v9_program.s: `lda xde, (0xeab1b4:24)`).
TextRender_CharEncodeAndDraw_Data:
	.incbin "includes/generated/naka_disk_warning.bin", 0x2508, 0x100
; [nakarest] naka_disk_warning+0x2608  +0x2608..+0x263c (0xeab2b4, 52 B)
; [nakarest] the table itself: ApFunction slot 0x120 (table 0xeab2b4, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
Root_ApFunctionTable_120:	.incbin "includes/generated/naka_disk_warning.bin", 0x2608, 0x34
; [nakarest] naka_disk_warning+0x263c  +0x263c..+0x2672 (0xeab2e8, 54 B)
; [nakarest] the table itself: ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
Root_ApFunctionTable_420:	.incbin "includes/generated/naka_disk_warning.bin", 0x263C, 0x36
; [nakarest] naka_disk_warning+0x2672  +0x2672..+0x271e (0xeab31e, 172 B)
; [nakarest] name strings, entries 0-11 of ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot) (names for ApFunction slot 0x120): "ApTaskControl",
; [nakarest] "CaptureLcdCheck", "UserBitmapCheck", "LanguageCheck", "GridCheck",
; [nakarest] "DefaultClassProc", ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x2672, 0xAC
; [nakarest] naka_disk_warning+0x271e  +0x271e..+0x2720 (0xeab3ca, 2 B)
; [nakarest] Text (2 B at 0xeab3ca), first string """; no registered NAKA table points into it;
; [nakarest] reached through source references DrawHelper_A_Setup (ui/ui_widget_defs.s: `ld hl,
; [nakarest] (DrawHelper_A_Setup_Str_DQuote:24)`).
DrawHelper_A_Setup_Str_DQuote:	.incbin "includes/generated/naka_disk_warning.bin", 0x271E, 0x2	; """
; [nakarest] naka_disk_warning+0x2720  +0x2720..+0x31e8 (0xeab3cc, 2760 B)
; [nakarest] purpose not established: layout of 2760 B at 0xeab3cc not derived; readers below
; [nakarest] Readers: source references BitmapIDProc (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] BitmapIDProc_PtrTable`), DrawHelper_A_CalcRange (ui/ui_widget_defs.s: `ld
; [nakarest] xbc, BitmapIDProc_PtrTable`), DrawHelper_A_ReturnAlt (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BitmapIDProc_PtrTable`).
BitmapIDProc_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x2720, 0xAC8	; 35 x 32-bit pointer
; [nakarest] naka_disk_warning+0x31e8  +0x31e8..+0x3d42 (0xeabe94, 2906 B)
; [nakarest] propname blocks (the +20 field-name table) of classes 0-108 of Class slot 0x160
; [nakarest] (table 0xeac9ee, 109 entries, InitializeRoot): Object {}; Function {func};
; [nakarest] ApFunction {}; ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x31E8, 0x326
WidgetPropStr_Max:		.incbin "includes/generated/naka_disk_warning.bin", 0x350E, 0x4
WidgetPropStr_RangeFigures:	.incbin "includes/generated/naka_disk_warning.bin", 0x3512, 0x830
; [nakarest] naka_disk_warning+0x3d42  +0x3d42..+0x402e (0xeac9ee, 748 B)
; [nakarest] the table itself: Class slot 0x160 (table 0xeac9ee, 109 entries, InitializeRoot),
; [nakarest] 109 class definitions x 24 bytes. class definition entries 0-31 of Class slot 0x160
; [nakarest] (table 0xeac9ee, 109 entries, InitializeRoot) (24 bytes each: proc, parent,
; [nakarest] allsize, selfsize, name, propdata, propname): Object, Function, ApFunction,
; [nakarest] MainFunction, Class, SupportClass, Mode, Title, ResBitmap, ResFrame, ....
Root_ClassTable_160:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D42, 0x2EC
; External label offsets within the binary blob above.
