
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
; [nakarest] points into it; reached through 3 data words in DiskSure_LanguageTable (at
; [nakarest] 0xea8c64, 0xea8c60, 0xea8c5c), which is read by DiskSure (file_io/medley.s: `lda
; [nakarest] xhl, (DiskSure_LanguageTable:24)`).
DiskWarning_ConfirmStrings:	.incbin "includes/generated/naka_disk_warning.bin", 0x0, 0x10
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
; [nakarest] naka_disk_warning+0x8ac  +0x8ac..+0xa38 (0xea9558, 396 B)
; [nakarest] A table of 6 pointers into this piece (396 B at 0xea9558), then text; entry 0
; [nakarest] points at "When a disk contains Technics & SMF files."; no registered NAKA table
; [nakarest] points into it; reached through source references TypePriorityText
; [nakarest] (file_io/medley.s: `lda xhl, (TypePriorityText_PtrTable:24)`).
TypePriorityText_PtrTable:		.incbin "includes/generated/naka_disk_warning.bin", 0x8AC, 0x132	; 6 x 32-bit pointer
; JumpInsert_ValueNames -- 5 x uint32_t + 5 x char[14]: display text of the Jump-Insert setting values 0-4
; {"OFF", "DISK MENU", "LOAD", "DIRECT PLAY", "SONG MEDLEY"} (centred in 13 columns), strings stored in reverse.
; JumpInsertFunc (file_io/misc_ui.s), EVT_GET_RAM_STRING: copies entry [value] into the caller's buffer; the value
; byte is RAM 0x340f2 (EVT_GET_RAM_ADDRESS), range 0..4 (EVT_GET_MAX = 4). 0 = do nothing when a disk is inserted.
JumpInsert_ValueNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x9DE, 0x5A
; [nakarest] naka_disk_warning+0xa38  +0xa38..+0xb46 (0xea96e4, 270 B)
; [nakarest] Text (270 B at 0xea96e4), first string " "; no registered NAKA table points into
; [nakarest] it; reached through source references JumpInsertFunc (file_io/misc_ui.s: `add xbc,
; [nakarest] JumpInsertFunc_CaseTable`).
JumpInsertFunc_CaseTable:
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
; FilePriority_SettingNames -- 2 x pointer + 2 x char[12]: text of the file-priority bit: [0] " TECHNICS ", [1] "   SMF    "
; FilePriorityFunc (file_io/misc_ui.s) answers EVT_GET_BIT_STRING with entry [bit & 1], Strcpy'd to the caller's buffer;
; the bit is bit 0 of RAM 0x340F4 (its EVT_GET_BIT_ADDRESS), which FileIO_DiskEventDispatch tests for floppy/HD media.
FilePriority_SettingNames:	.incbin "includes/generated/naka_disk_warning.bin", 0xA4C, 0x20
WaitingFunc_DrawMessage_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xA6C, 0xDA	; 6 x 32-bit pointer
; AcFileSfx_BitLabelPtrs -- 9 x u32: text of each row of the file-suffix box; [k] = label of mask bit k-1, [0] = blank
; AcFileSfxBoxProc (ui/ui_control_panel.s) on EVT_SET_FILE_SFX draws 8 rows, k = 1..8: bit 0 of the mask
; parameter set -> entry [k], clear -> entry [0] (13 spaces); the mask is shifted right once per row.
; Bits 0..7: CURRENT PANEL, PANEL MEMORY, SEQUENCER, COMPOSER, SOUND MEMORY, MSP, RHYTHM CUSTOM, USER MIDI.
AcFileSfx_BitLabelPtrs:	.incbin "includes/generated/naka_disk_warning.bin", 0xB46, 0x24
; AcFileSfx_BitLabels -- 9 x char[14]: the row texts AcFileSfx_BitLabelPtrs points at, 13 characters + NUL each
; in reverse order: [0] bit 7 "  USER MIDI  " .. [7] bit 0 "CURRENT PANEL", [8] 13 spaces (bit clear);
; drawn with DrawString by AcFileSfx_DrawLoop (ui/ui_control_panel.s).
AcFileSfx_BitLabels:	.incbin "includes/generated/naka_disk_warning.bin", 0xB6A, 0x7E
IvTimer_HandleEvent3A_Str_N1shot:	.incbin "includes/generated/naka_disk_warning.bin", 0xBE8, 0x6	; "1shot"
IvIndexSwCtrlProc_Str_ISC:		.incbin "includes/generated/naka_disk_warning.bin", 0xBEE, 0x4	; "ISC"
IvIndexSwDelayProc_Str_ISD:		.incbin "includes/generated/naka_disk_warning.bin", 0xBF2, 0x4	; "ISD"
IvWaitWinCtlProc_Str_WWC:		.incbin "includes/generated/naka_disk_warning.bin", 0xBF6, 0x4	; "WWC"
FDC_WaitReady_CaseTable:
	.short	FDC_CONFIG_VERIFY_Code - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case1 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case2 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case3 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case4 - FDC_CONFIG_VERIFY_Code
	.short	FDC_CONFIG_VERIFY_Case5 - FDC_CONFIG_VERIFY_Code
FDC_COMMAND_DISPATCHER_CaseTable:
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
FDC_CommandEntry_CopyParams_CaseTable:
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
; CtrlPanel_DialStepByDelta -- 33 x int32_t: EVT_DIAL step for dial delta -16..+16 (index = delta + 16)
; CtrlPanel_HandleSerialPort (boot/main_title_ctrl_panel.s), panel packet with payload1 == 33: payload2 + 16,
; sign-extended, x4, loads the 32-bit step and posts it as the EVT_DIAL parameter.
; The table is odd-symmetric (+d -> -step(d)), so the panel delta sign is inverted, and |step| saturates at 7.
CtrlPanel_DialStepByDelta:	.incbin "includes/generated/naka_disk_warning.bin", 0xC36, 0x84
; CtrlPanel_SwitchRowBit -- 32 x uint32_t: entry i = 1 << i, the bit for panel switch row i
; SwbtB3_OnPanelEvent's 0xA9 path (boot/main_title_ctrl_panel.s) indexes it by the row in
; SWBTWR_PAYLOAD_1 (`sll xwa, 2`): it ORs the bit into TRANSITION_PROGRESS (payload bit 1) or
; TRANSITION_TIMER (bit 0) on press and ANDs it out on release; the AND of both masks picks combos
; (0x1100, 0xA1, 0x91, 0x89 in CtrlPanel_DispatchCombinedState). Rows 0..16 are reachable (cp e, 0x10)
CtrlPanel_SwitchRowBit:	.incbin "includes/generated/naka_disk_warning.bin", 0xCBA, 0x80
GetSoundName_DefaultString_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0xD3A, 0x12
; MainPmanControl_CaseTable -- 6 x int16: the case offsets of MainPmanControl's compiled switch, relative to MainPmanCtrl_DispatchTable
MainPmanControl_CaseTable:
	.short	MainPmanCtrl_Case0 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case1 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case2 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case3 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case4 - MainPmanCtrl_DispatchTable
	.short	MainPmanCtrl_Case5 - MainPmanCtrl_DispatchTable
; CtrlPanel_DispatchByIndex_CaseTable -- 43 x int16: the case offsets of CtrlPanel_DispatchByIndex's compiled switch, relative to CtrlPanel_FrameDispatchTable
CtrlPanel_DispatchByIndex_CaseTable:
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
; GroupBox_ModeSwitchGroup -- 32 x u32: mode-switch group key per Mode-table slot (index = mode id & 0xFFFF)
; GroupBox_HandleStateCompare (EVT_SW_IN_MODE, param = requested mode) compares key[current] with key[requested]:
; equal -> EVT_CHANGE_MODE MD_NORMAL, else -> EVT_CHANGE_MODE requested.  E.g. MD_SOUND and MD_SOUNDEDIT share
; 0x101; MD_SEQ, MD_SEQ_REAL/EDIT/STEP share 0x106.  Slots 21-31 and MD_PS/MD_NORMAL are 0xFF.  The keys are only compared.
GroupBox_ModeSwitchGroup:	.incbin "includes/generated/naka_disk_warning.bin", 0xDAE, 0x80
; GroupBox_EventCaseMap -- 39 x uint8_t: case number (0-12) for each event GroupBoxProc switches on
; Slots 0-9 = EVT_SHOW..EVT_ALL_PAINT (0x1C00001+i), 10-19 = 0x1E0008B+i, 20-38 = 0x1E00091+i.
; CtrlPanel_FuncDispatch (ui/ui_control_panel.s) reads the byte, doubles it and jumps through
; CtrlPanel_FuncDispatch_CaseTable: 0 GroupBox_NavUpDown (send to GetTitleNow), 1 BoxProc, 2 return 0, 3-12 own handlers.
GroupBox_EventCaseMap:	.incbin "includes/generated/naka_disk_warning.bin", 0xE2E, 0x27
; GroupBox_EventCaseMap_Pad -- 1 x uint8_t: 0xFF fill so CtrlPanel_FuncDispatch_CaseTable (.short) starts even
GroupBox_EventCaseMap_Pad:	.incbin "includes/generated/naka_disk_warning.bin", 0xE55, 0x1
; CtrlPanel_FuncDispatch_CaseTable -- 13 x int16: the case offsets of CtrlPanel_FuncDispatch's compiled switch, relative to GroupBox_HandlePartChange
CtrlPanel_FuncDispatch_CaseTable:
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
; GetEditSwPoint_CaseTable -- 13 x int16: the case offsets of GetEditSwPoint's compiled switch, relative to EditSwParam_Mode0
GetEditSwPoint_CaseTable:
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
; SetWallPaper_CaseTable -- 6 x int16: the case offsets of SetWallPaper's compiled switch, relative to SetWallPaper_DispatchData
SetWallPaper_CaseTable:
	.short	SetWallPaper_DispatchData - SetWallPaper_DispatchData
	.short	SetWallPaper_CaseData - SetWallPaper_DispatchData
	.short	SetWallPaper_Case2 - SetWallPaper_DispatchData
	.short	SetWallPaper_Default - SetWallPaper_DispatchData
	.short	SetWallPaper_Loop - SetWallPaper_DispatchData
	.short	SetWallPaper_Loop - SetWallPaper_DispatchData
; IvDirmdScreenProc_Str_K -- 15 x int16: the case offsets of IvDirmdScreenProc's compiled switch, relative to DirmdEmu_CaseB
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
; [nakarest] naka_disk_warning+0xeb4  +0xeb4..+0xf12 (0xea9b60, 94 B)
; [nakarest] A table of 4 pointers (94 B at 0xea9b60), then text; entry 0 points at
; [nakarest] "\xC1\x9C\x8C!\xC1\x9D\x8C\xF1f0\xFF"; no registered NAKA table points into it;
; [nakarest] reached through source references DirmdTitleFunc (audio/presentation_sound_nav.s:
; [nakarest] `ld xiy, DirmdTitleFunc_PtrTable`).
DirmdTitleFunc_PtrTable:			.incbin "includes/generated/naka_disk_warning.bin", 0xEB4, 0x10	; 4 x 32-bit pointer
DirmdTitleFunc_Str_DirmdTitleNew:		.incbin "includes/generated/naka_disk_warning.bin", 0xEC4, 0x12	; "DirmdTitleNew();"
DirmdTitleFunc_Str_DirmdTitleOld:		.incbin "includes/generated/naka_disk_warning.bin", 0xED6, 0x12	; "DirmdTitleOld();"
DirmdTitleFunc_Str_DirmdTitleESw_Fmtd_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0xEE8, 0x18	; "DirmdTitleESw(%d, %d);"
DirmdTitleFunc_Str_DirmdTitleCur:		.incbin "includes/generated/naka_disk_warning.bin", 0xF00, 0x12	; "DirmdTitleCur();"
; DirmdEmulator's case table: one 16-bit offset from DirmdEmulator_Dispatch per event EVT_NONE .. EVT_NONE+15
; (DirmdEmulator subtracts EVT_NONE, rejects anything outside 0..15, then `jp t, (xix+bc)`).  Four events
; have cases; the rest go straight to DirmdEmu_DefaultCase.  Was a 32-byte slice of naka_disk_warning.bin.
DirmdEmulator_CaseTable:
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
; WindowProc_CaseTable -- 10 x int16: the case offsets of WindowProc's compiled switch, relative to WindowProc_EventDispatch
WindowProc_CaseTable:
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
; WndScroll_CharSetCaptions -- 3 x u32: the caption of each character set of the naming window, indexed by the set
; number in RAM 0x274DA (0 upper case, 1 lower case, 2 symbols, the order of AcNaming_PageCharLists).
; WndScroll_SendSelectionEvents (ui/ui_window_procs.s) scales the set by 4 and sends the string to view 0x1D
; with EVT_PARA_DRAW.
WndScroll_CharSetCaptions:	.incbin "includes/generated/naka_disk_warning.bin", 0xF46, 0xC
; WndScroll_CharSetCaptionText -- 42 x char: " !#$%&?.... ", "abc...123...", "ABC...123..." (NUL + 0xFF each),
; the strings WndScroll_CharSetCaptions points at.
WndScroll_CharSetCaptionText:	.incbin "includes/generated/naka_disk_warning.bin", 0xF52, 0x2A
; WndScroll_UpperCharTable -- 39 x u32: character set 0 of the naming window, one string per selectable item:
; "A".."Z", "_", "0".."9", "SPC" (inserts the fill character), then "". AcNaming_PageCharLists[0] points here;
; the WndScroll/WndEvt routines (ui/ui_window_procs.s) index it by the item number * 4 and draw or convert the string;
; the last item number per set comes from WndScroll_NamingPageLastIndex.
WndScroll_UpperCharTable:	.incbin "includes/generated/naka_disk_warning.bin", 0xF7C, 0x9C
; WndScroll_UpperCharText -- 80 x char: "" (+0xFF), "SPC", then "9".."0", "_", "Z".."A" as 2-byte strings,
; the items WndScroll_UpperCharTable points at.
WndScroll_UpperCharText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1018, 0x50
; WndScroll_LowerCharTable -- 39 x u32: character set 1 of the naming window: "a".."z", "_", "0".."9", "SPC", "".
; AcNaming_PageCharLists[1] points here; read like WndScroll_UpperCharTable (ui/ui_window_procs.s).
WndScroll_LowerCharTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1068, 0x9C
; WndScroll_LowerCharText -- 80 x char: "" (+0xFF), "SPC", then "9".."0", "_", "z".."a" as 2-byte strings,
; the items WndScroll_LowerCharTable points at.
WndScroll_LowerCharText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1104, 0x50
; WndScroll_SymbolPageChars -- 33 x u32: page 2 (symbols) of the name-entry character pages; [i] = symbol i as text,
; "~XX" meaning character code 0xXX (ConvertStrings).  Entry 2 of AcNaming_PageCharLists (one table per page,
; RAM 0x274DA = page).  WndScroll_SearchCharTable (ui/ui_window_procs.s) converts entries 0..31 and compares each
; with the character under the cursor to find its page/index; [32] = "" is past the search bound (31).
WndScroll_SymbolPageChars:	.incbin "includes/generated/naka_disk_warning.bin", 0x1154, 0x84
; WndScroll_Sym_End -- 2 x char: "" + 0xFF fill, entry 32 of WndScroll_SymbolPageChars (not reached by the search)
; WndScroll_SymbolPageChars[32] points here.
WndScroll_Sym_End:	.incbin "includes/generated/naka_disk_warning.bin", 0x11D8, 0x2
; WndScroll_Sym_RBrace -- 2 x char: "}", symbol 31 of page 2
; WndScroll_SymbolPageChars[31] points here.
WndScroll_Sym_RBrace:	.incbin "includes/generated/naka_disk_warning.bin", 0x11DA, 0x2
; WndScroll_Sym_LBrace -- 2 x char: "{", symbol 30 of page 2
; WndScroll_SymbolPageChars[30] points here.
WndScroll_Sym_LBrace:	.incbin "includes/generated/naka_disk_warning.bin", 0x11DC, 0x2
; WndScroll_Sym_RBracket -- 2 x char: "]", symbol 29 of page 2
; WndScroll_SymbolPageChars[29] points here.
WndScroll_Sym_RBracket:	.incbin "includes/generated/naka_disk_warning.bin", 0x11DE, 0x2
; WndScroll_Sym_LBracket -- 2 x char: "[", symbol 28 of page 2
; WndScroll_SymbolPageChars[28] points here.
WndScroll_Sym_LBracket:	.incbin "includes/generated/naka_disk_warning.bin", 0x11E0, 0x2
; WndScroll_Sym_Greater -- 2 x char: ">", symbol 27 of page 2
; WndScroll_SymbolPageChars[27] points here.
WndScroll_Sym_Greater:	.incbin "includes/generated/naka_disk_warning.bin", 0x11E2, 0x2
; WndScroll_Sym_Less -- 2 x char: "<", symbol 26 of page 2
; WndScroll_SymbolPageChars[26] points here.
WndScroll_Sym_Less:	.incbin "includes/generated/naka_disk_warning.bin", 0x11E4, 0x2
; WndScroll_Sym_RParen -- 2 x char: ")", symbol 25 of page 2
; WndScroll_SymbolPageChars[25] points here.
WndScroll_Sym_RParen:	.incbin "includes/generated/naka_disk_warning.bin", 0x11E6, 0x2
; WndScroll_Sym_LParen -- 2 x char: "(", symbol 24 of page 2
; WndScroll_SymbolPageChars[24] points here.
WndScroll_Sym_LParen:	.incbin "includes/generated/naka_disk_warning.bin", 0x11E8, 0x2
; WndScroll_Sym_Code8D -- 4 x char: "~8d", symbol 23 of page 2, character code 0x8D
; WndScroll_SymbolPageChars[23] points here.
WndScroll_Sym_Code8D:	.incbin "includes/generated/naka_disk_warning.bin", 0x11EA, 0x4
; WndScroll_Sym_Code8B -- 4 x char: "~8b", symbol 22 of page 2, character code 0x8B
; WndScroll_SymbolPageChars[22] points here.
WndScroll_Sym_Code8B:	.incbin "includes/generated/naka_disk_warning.bin", 0x11EE, 0x4
; WndScroll_Sym_Equals -- 2 x char: "=", symbol 21 of page 2
; WndScroll_SymbolPageChars[21] points here.
WndScroll_Sym_Equals:	.incbin "includes/generated/naka_disk_warning.bin", 0x11F2, 0x2
; WndScroll_Sym_Slash -- 2 x char: "/", symbol 20 of page 2
; WndScroll_SymbolPageChars[20] points here.
WndScroll_Sym_Slash:	.incbin "includes/generated/naka_disk_warning.bin", 0x11F4, 0x2
; WndScroll_Sym_Asterisk -- 2 x char: "*", symbol 19 of page 2
; WndScroll_SymbolPageChars[19] points here.
WndScroll_Sym_Asterisk:	.incbin "includes/generated/naka_disk_warning.bin", 0x11F6, 0x2
; WndScroll_Sym_Minus -- 2 x char: "-", symbol 18 of page 2
; WndScroll_SymbolPageChars[18] points here.
WndScroll_Sym_Minus:	.incbin "includes/generated/naka_disk_warning.bin", 0x11F8, 0x2
; WndScroll_Sym_Plus -- 2 x char: "+", symbol 17 of page 2
; WndScroll_SymbolPageChars[17] points here.
WndScroll_Sym_Plus:	.incbin "includes/generated/naka_disk_warning.bin", 0x11FA, 0x2
; WndScroll_Sym_Semicolon -- 2 x char: ";", symbol 16 of page 2
; WndScroll_SymbolPageChars[16] points here.
WndScroll_Sym_Semicolon:	.incbin "includes/generated/naka_disk_warning.bin", 0x11FC, 0x2
; WndScroll_Sym_Colon -- 2 x char: ":", symbol 15 of page 2
; WndScroll_SymbolPageChars[15] points here.
WndScroll_Sym_Colon:	.incbin "includes/generated/naka_disk_warning.bin", 0x11FE, 0x2
; WndScroll_Sym_Period -- 2 x char: ".", symbol 14 of page 2
; WndScroll_SymbolPageChars[14] points here.
WndScroll_Sym_Period:	.incbin "includes/generated/naka_disk_warning.bin", 0x1200, 0x2
; WndScroll_Sym_Comma -- 2 x char: ",", symbol 13 of page 2
; WndScroll_SymbolPageChars[13] points here.
WndScroll_Sym_Comma:	.incbin "includes/generated/naka_disk_warning.bin", 0x1202, 0x2
; WndScroll_Sym_Backquote -- 2 x char: "`", symbol 12 of page 2
; WndScroll_SymbolPageChars[12] points here.
WndScroll_Sym_Backquote:	.incbin "includes/generated/naka_disk_warning.bin", 0x1204, 0x2
; WndScroll_Sym_SQuote -- 4 x char: "~27", symbol 11 of page 2, character code 0x27
; WndScroll_SymbolPageChars[11] points here.
WndScroll_Sym_SQuote:	.incbin "includes/generated/naka_disk_warning.bin", 0x1206, 0x4
; WndScroll_Sym_DQuote -- 4 x char: "~22", symbol 10 of page 2, character code 0x22
; WndScroll_SymbolPageChars[10] points here.
WndScroll_Sym_DQuote:	.incbin "includes/generated/naka_disk_warning.bin", 0x120A, 0x4
; WndScroll_Sym_Bar -- 2 x char: "|", symbol 9 of page 2
; WndScroll_SymbolPageChars[9] points here.
WndScroll_Sym_Bar:	.incbin "includes/generated/naka_disk_warning.bin", 0x120E, 0x2
; WndScroll_Sym_Caret -- 2 x char: "^", symbol 8 of page 2
; WndScroll_SymbolPageChars[8] points here.
WndScroll_Sym_Caret:	.incbin "includes/generated/naka_disk_warning.bin", 0x1210, 0x2
; WndScroll_Sym_Code5C -- 4 x char: "~5c", symbol 7 of page 2, character code 0x5C
; WndScroll_SymbolPageChars[7] points here.
WndScroll_Sym_Code5C:	.incbin "includes/generated/naka_disk_warning.bin", 0x1212, 0x4
; WndScroll_Sym_At -- 4 x char: "~40", symbol 6 of page 2, character code 0x40
; WndScroll_SymbolPageChars[6] points here.
WndScroll_Sym_At:	.incbin "includes/generated/naka_disk_warning.bin", 0x1216, 0x4
; WndScroll_Sym_Question -- 2 x char: "?", symbol 5 of page 2
; WndScroll_SymbolPageChars[5] points here.
WndScroll_Sym_Question:	.incbin "includes/generated/naka_disk_warning.bin", 0x121A, 0x2
; WndScroll_Sym_Ampersand -- 2 x char: "&", symbol 4 of page 2
; WndScroll_SymbolPageChars[4] points here.
WndScroll_Sym_Ampersand:	.incbin "includes/generated/naka_disk_warning.bin", 0x121C, 0x2
; WndScroll_Sym_Percent -- 2 x char: "%", symbol 3 of page 2
; WndScroll_SymbolPageChars[3] points here.
WndScroll_Sym_Percent:	.incbin "includes/generated/naka_disk_warning.bin", 0x121E, 0x2
; WndScroll_Sym_Dollar -- 2 x char: "$", symbol 2 of page 2
; WndScroll_SymbolPageChars[2] points here.
WndScroll_Sym_Dollar:	.incbin "includes/generated/naka_disk_warning.bin", 0x1220, 0x2
; WndScroll_Sym_Hash -- 2 x char: "#", symbol 1 of page 2
; WndScroll_SymbolPageChars[1] points here.
WndScroll_Sym_Hash:	.incbin "includes/generated/naka_disk_warning.bin", 0x1222, 0x2
; WndScroll_Sym_Exclam -- 2 x char: "!", symbol 0 of page 2
; WndScroll_SymbolPageChars[0] points here.
WndScroll_Sym_Exclam:	.incbin "includes/generated/naka_disk_warning.bin", 0x1224, 0x2
; AcNaming_PageCharLists -- 3 x pointer: the key-label list of each character page of the naming window (AcNamingWindowProc)
; [0] A-Z _ 0-9 SPC, [1] a-z _ 0-9 SPC (39 labels, then ""), [2] the 32 symbols of WndScroll_SymbolPageChars (then "").
; The window code takes entry [page] (RAM 0x274DA, x4), then label [item] (x4) and ConvertStrings it; the label "SPC" enters a space.
AcNaming_PageCharLists:	.incbin "includes/generated/naka_disk_warning.bin", 0x1226, 0xC
; WndScroll_NamingPageLastIndex -- 2 x 3 uint16_t = {{37,37,31},{36,36,31}}: last selectable entry of each naming
; character page (0 = A-Z _ 0-9 SPC, 1 = a-z _ 0-9 SPC, 2 = symbols) per naming mode (EVT_GET_NAMING_MODE, RAM 0x274e2);
; mode 1 stops at '9', leaving out SPC. Read in ui/ui_window_procs.s at [(0x274e2)*3 + page (0x274da)] to bound the
; drawn/scrolled character index. This slice is element [0][0]; the other 5 words are the unnamed 10 bytes after it.
WndScroll_NamingPageLastIndex:	.incbin "includes/generated/naka_disk_warning.bin", 0x1232, 0x2
	.incbin "includes/generated/naka_disk_warning.bin", 0x1234, 0xA	; 10 bytes after WndScroll_NamingPageLastIndex's string; unnamed (they sat under its label until 2026-10-03)
; AcNaming_FillCharByMode -- 2 x u32: the blank/fill character of the naming window per naming mode, 0 -> " ", 1 -> "_"
; AcNaming_QueryCharSet (audio/presentation_sound_nav.s) gets the mode with EVT_GET_NAMING_MODE, stores it at RAM
; 0x274E2 and stores entry[mode] at RAM 0x274E4; ui/ui_window_procs.s fills and erases the name buffer with its
; first byte and inserts it for the SPC item.
AcNaming_FillCharByMode:	.incbin "includes/generated/naka_disk_warning.bin", 0x123E, 0x8
; AcNaming_FillCharUnderscore -- 2 x char: "_", AcNaming_FillCharByMode[1] (naming mode 1)
AcNaming_FillCharUnderscore:	.incbin "includes/generated/naka_disk_warning.bin", 0x1246, 0x2
; AcNaming_FillCharSpace -- 2 x char: " ", AcNaming_FillCharByMode[0] (naming mode 0)
AcNaming_FillCharSpace:	.incbin "includes/generated/naka_disk_warning.bin", 0x1248, 0x2
; WndEvt_DispatchByEventCode_CaseTable -- 9 x int16: the case offsets of WndEvt_DispatchByEventCode's compiled switch, relative to WndEvt_EventCodeDispatch
WndEvt_DispatchByEventCode_CaseTable:
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
; UserBitmapCheck_Bitmap24x24 -- a 24 x 24 bitmap, one byte per pixel.  UserBitmapCheck answers
; EVT_GET_BITMAP_WIDTH / _HEIGHT with 0x18 and EVT_GET_BITMAP_DATA with this address; VwUserBitmap_HandlePaint
; draws it with DrawBitmapSPFast.  Typed in ui_widgets/naka_disk_warning.c (scripts/converters/bitmap_id_tables_retype.py).
UserBitmapCheck_Bitmap24x24:	.incbin "includes/generated/naka_disk_warning.bin", 0x1274, 0x240
VwUserBitmapByName_HandlePaint_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x14B4, 0x6
EditSw_ByteData_Str_N7f:		.incbin "includes/generated/naka_disk_warning.bin", 0x14BA, 0x4	; "~7f"
EditSw_ByteData_Str_N80:		.incbin "includes/generated/naka_disk_warning.bin", 0x14BE, 0x4	; "~80"
EditSw_ByteData_Str_N81:		.incbin "includes/generated/naka_disk_warning.bin", 0x14C2, 0x4	; "~81"
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
; [nakarest] naka_disk_warning+0x14ce  +0x14ce..+0x159c (0xeaa17a, 206 B)
; [nakarest] Text (206 B at 0xeaa17a), first string "~81"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw_SelectVariantC
; [nakarest] (ui/ui_window_procs.s: `ld xwa, DrawEditSw_SelectVariantC_Str_N81`).
DrawEditSw_SelectVariantC_Str_N81:				.incbin "includes/generated/naka_disk_warning.bin", 0x14CE, 0x4	; "~81"
TextBox_DrawLineLoop_Data:					.incbin "includes/generated/naka_disk_warning.bin", 0x14D2, 0x2
AcTempoBox_MatchTempoID_Str_aa_Fmt3d:				.incbin "includes/generated/naka_disk_warning.bin", 0x14D4, 0x8	; "~aa=%3d"
AcTempoBox_CopyTempoString_Str_aa:				.incbin "includes/generated/naka_disk_warning.bin", 0x14DC, 0x8	; "~aa=---"
PsListBox_GetText_Str_No_My_Car_Day_Memory_AyaSam:		.incbin "includes/generated/naka_disk_warning.bin", 0x14E4, 0x5C	; "No My Car Day|Memory|AyaSam|Sweet Home Town|I am Rocker|Sunday Song|Two Day Drunk?|Samba 2"
PsGridBox_Scroll_Render_Str_Fmtd_Fmtd:				.incbin "includes/generated/naka_disk_warning.bin", 0x1540, 0x6	; "%d-%d"
PsGridBox_Scroll_Render_Str_PART_CHANNEL_OCTAVE_LOCAL:		.incbin "includes/generated/naka_disk_warning.bin", 0x1546, 0x20	; " PART  |CHANNEL|OCTAVE | LOCAL "
PsGridBox_Scroll_Render_Str_RIGHT1_RIGHT2_LEFT_PART4_PART5:	.incbin "includes/generated/naka_disk_warning.bin", 0x1566, 0x36	; "|-|RIGHT1|RIGHT2|LEFT|PART4|PART5|PART6|PART7|PART8|"
; PsGridBoxProc_CaseTable -- 8 x int16: the case offsets of PsGridBoxProc's compiled switch, relative to PsGridBox_Init
PsGridBoxProc_CaseTable:
	.short	PsGridBoxProc_OnGetFixedColStr - PsGridBox_Init
	.short	PsGridBoxProc_OnGetFixedRowStr - PsGridBox_Init
	.short	PsGridBoxProc_OnGridDraw - PsGridBox_Init
	.short	PsGridBoxProc_OnRequestGridDraw - PsGridBox_Init
	.short	PsGridBoxProc_OnSetSelectedCel - PsGridBox_Init
	.short	PsGridBoxProc_OnGetSelectedCel - PsGridBox_Init
	.short	PsGridBox_Default - PsGridBox_Init
	.short	PsGridBoxProc_OnCheckGridIndex - PsGridBox_Init
; AcGridBoxProc_CaseTable -- 7 x int16: the case offsets of AcGridBoxProc's compiled switch, relative to AcGridBox_Init
AcGridBoxProc_CaseTable:
	.short	AcGridBoxProc_OnIndexswUp - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswDown - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswUp - AcGridBox_Init
	.short	AcGridBoxProc_OnIndexswDown - AcGridBox_Init
	.short	AcGridBox_Default - AcGridBox_Init
	.short	AcGridBox_CellSelect - AcGridBox_Init
	.short	AcGridBox_CellSelect - AcGridBox_Init
	.incbin "includes/generated/naka_disk_warning.bin", 0x15ba, 0x6
; GridCheck_CaseTable -- 7 x int16: the case offsets of GridCheck's compiled switch, relative to GridCheck_JumpEnd
GridCheck_CaseTable:
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_Return - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
	.short	GridCheck_JumpEnd - GridCheck_JumpEnd
PsNumEditBox_Confirm_Str_Chr25:		.incbin "includes/generated/naka_disk_warning.bin", 0x15CE, 0x2	; "%"
PsNumEditBox_Confirm_Str_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x15D0, 0x4	; "%d"
PsNumEditBox_Confirm_Str_d:		.incbin "includes/generated/naka_disk_warning.bin", 0x15D4, 0x2	; "d"
; PasTableCheck_StateNames -- 2 x pointer + 2 x char[8]: [0] "PASSIVE", [1] "ACTIVE "
; PasTableCheck (ui/ui_widget_defs.s, NAKA_APFUNC_PasTableCheck) answers EVT_GET_TABLE_STRING with entry [the u32 at the
; event buffer] (x4), Strcpy'd back over that buffer.
PasTableCheck_StateNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x15D6, 0x18
; AcOnOff_ValueTexts -- 2 x u32: text of an on/off box's value, [0] "OFF", [1] "ON "
; AcOnOff_GetText (ui/ui_widget_defs.s), EVT_GET_STRING: the 16-bit value at the instance's +50 pointer, x4,
; selects the entry, which is Strcpy'd into the caller's buffer.
AcOnOff_ValueTexts:	.incbin "includes/generated/naka_disk_warning.bin", 0x15EE, 0x8
; AcOnOff_OnText -- 4 x char: "ON ", text of value 1
; AcOnOff_ValueTexts[1] points here.
AcOnOff_OnText:	.incbin "includes/generated/naka_disk_warning.bin", 0x15F6, 0x4
; AcOnOff_OffText -- 4 x char: "OFF", text of value 0
; AcOnOff_ValueTexts[0] points here.
AcOnOff_OffText:	.incbin "includes/generated/naka_disk_warning.bin", 0x15FA, 0x4
AcNumEdit_GetText_Str_Chr25:		.incbin "includes/generated/naka_disk_warning.bin", 0x15FE, 0x2	; "%"
AcNumEdit_GetText_Str_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1600, 0x4	; "%d"
AcNumEdit_GetText_Str_d:		.incbin "includes/generated/naka_disk_warning.bin", 0x1604, 0x2	; "d"
LswEditCheck_Str_Fmt3d:			.incbin "includes/generated/naka_disk_warning.bin", 0x1606, 0x4	; "%3d"
RamEditCheck_JumpStart_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x160A, 0x4	; "%3d"
; RamEditCheck_CaseTable -- 10 x int16: the case offsets of RamEditCheck's compiled switch, relative to RamEditCheck_JumpStart
RamEditCheck_CaseTable:
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
; BitEditCheck_FalseTrueNames -- 2 x uint32_t + 2 x char[6]: {"FALSE", "TRUE "}, indexed by the bit's value (0/1)
; BitEditCheck (ui/ui_widget_defs.s), EVT_GET_BIT_STRING: (value & 1) * 4 selects the entry and Strcpy copies it
; to the caller's buffer; the bit is mask 0x8000 (EVT_GET_BIT) of RAM 0x276ce (EVT_GET_BIT_ADDRESS).
BitEditCheck_FalseTrueNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x1622, 0x14
; [nakarest] naka_disk_warning+0x1636  +0x1636..+0x163a (0xeaa2e2, 4 B)
; [nakarest] Text (4 B at 0xeaa2e2), first string "ON"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_Paint_Default (ui/ui_widget_defs.s:
; [nakarest] `ld xde, ButtonState_Paint_EventConfirm_Str_ON`).
ButtonState_Paint_EventConfirm_Str_ON:	.incbin "includes/generated/naka_disk_warning.bin", 0x1636, 0x4	; "ON"
; [nakarest] naka_disk_warning+0x163a  +0x163a..+0x164e (0xeaa2e6, 20 B)
; [nakarest] Text (20 B at 0xeaa2e6), first string "OFF"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_Paint_Default
; [nakarest] (ui/ui_widget_defs.s: `ld xde, ButtonState_Paint_EventConfirm_Str_OFF`).
ButtonState_Paint_EventConfirm_Str_OFF:		.incbin "includes/generated/naka_disk_warning.bin", 0x163A, 0x4	; "OFF"
ButtonState_DispatchDSP_InlineData_Str_N9b:	.incbin "includes/generated/naka_disk_warning.bin", 0x163E, 0x4	; "~9b"
ButtonState_DispatchDSP_InlineData_Str_N98:	.incbin "includes/generated/naka_disk_warning.bin", 0x1642, 0x4	; "~98"
ButtonState_DispatchDSP_InlineData_Str_N85:	.incbin "includes/generated/naka_disk_warning.bin", 0x1646, 0x4	; "~85"
ButtonState_DispatchDSP_InlineData_Str_N81:	.incbin "includes/generated/naka_disk_warning.bin", 0x164A, 0x4	; "~81"
; [nakarest] NakaInst_OK  +0x164e..+0x166a (0xeaa2fa, 28 B)
; [nakarest] 28 B at 0xeaa2fa: split since into the labelled pieces below; code or data uses NakaInst_OK, ButtonState_DispatchDSP_InlineData_Str_OFF, ButtonState_DispatchDSP_InlineData_Str_OK, ButtonState_DispatchDSP_InlineData_Str_Lt and 4 more.
NakaInst_OK:					.incbin "includes/generated/naka_disk_warning.bin", 0x164E, 0x4
ButtonState_DispatchDSP_InlineData_Str_OFF:	.incbin "includes/generated/naka_disk_warning.bin", 0x1652, 0x4	; "OFF"
ButtonState_DispatchDSP_InlineData_Str_OK:	.incbin "includes/generated/naka_disk_warning.bin", 0x1656, 0x4	; "OK"
ButtonState_DispatchDSP_InlineData_Str_Lt:	.incbin "includes/generated/naka_disk_warning.bin", 0x165A, 0x2	; "<"
ButtonState_DispatchDSP_InlineData_Str_Gt:	.incbin "includes/generated/naka_disk_warning.bin", 0x165C, 0x2	; ">"
ButtonState_DispatchDSP_InlineData_Str_N7f:	.incbin "includes/generated/naka_disk_warning.bin", 0x165E, 0x4	; "~7f"
ButtonState_DispatchDSP_InlineData_Str_N80:	.incbin "includes/generated/naka_disk_warning.bin", 0x1662, 0x4	; "~80"
ButtonState_DispatchDSP_InlineData_Str_YES:	.incbin "includes/generated/naka_disk_warning.bin", 0x1666, 0x4	; "YES"
; [nakarest] Str_No  +0x166a..+0x166e (0xeaa316, 4 B)
; [nakarest] 4 B at 0xeaa316: split since into the labelled pieces below; code or data uses Str_No.
Str_No:	.incbin "includes/generated/naka_disk_warning.bin", 0x166A, 0x4
; ButtonState_DispatchDSP_CaseTable -- 17 x int16: the case offsets of ButtonState_DispatchDSP's compiled switch, relative to ButtonState_DispatchDSP_InlineData
ButtonState_DispatchDSP_CaseTable:
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
; AcIndexEdit_SwitchDirCaseMap -- 17 x uint8_t: case 0-2 for the widget's instance byte (0..16)
; AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s) reads instance +40 (PsWideESBox) or +38, bounds it 0..16,
; and jumps through AcIndexEdit_DispatchDSP_CaseTable: 0 = EVT_INDEXSW_DOWN if parameter bit 7 set
; else EVT_INDEXSW_UP, 1 = EVT_INDEXSW_UP, 2 = EVT_INDEXSW_DOWN.
AcIndexEdit_SwitchDirCaseMap:	.incbin "includes/generated/naka_disk_warning.bin", 0x1690, 0x11
; AcIndexEdit_SwitchDirCaseMap_Pad -- 1 x uint8_t: 0xFF fill so AcIndexEdit_DispatchDSP_CaseTable starts even
AcIndexEdit_SwitchDirCaseMap_Pad:	.incbin "includes/generated/naka_disk_warning.bin", 0x16A1, 0x1
; [nakarest] naka_disk_warning+0x16a2  +0x16a2..+0x16d8 (0xeaa34e, 54 B)
; [nakarest] Text (54 B at 0xeaa34e), first string ""; no registered NAKA table points into it;
; [nakarest] reached through source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `ld
; [nakarest] xix, AcIndexEdit_DispatchDSP_CaseTable`).
AcIndexEdit_DispatchDSP_CaseTable:
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
; AcMixerVol_ChannelNamePtrs -- 28 pointers to the mixer channel names (RT1 RT2 LEFT PT4..PT16 ACP1..3 BASS
; DRUM CHRD RTBS MSP MSP CTRL METR MIC), parallel to AcMixerVol_Channels; read by AcMixerVol_Paint.  The
; strings follow the table.
AcMixerVol_ChannelNamePtrs:	.incbin "includes/generated/naka_disk_warning.bin", 0x175E, 0x102	; 28 x 32-bit pointer
; AcMixerVol_Channels -- 28 mixer channels x {u32 volume_key, u32 mute_key, u16 lsw_word}, indexed by the
; AcMixerVol widget's +28 word (10 * index).  AcMixerVol_DrawChannel (EVT_PARA_DRAW) prints the volume and draws
; "MUTE" when SndParam_LookupReadOnly(mute_key) is 1; the switch arms pass (key, lsw_word) to MainLswPut /
; MainLswAdd.  Channels 0-22 are part tags 0-22 (keys 0x8000 + 0x400*T + 0x07 / + 0x08), so part field k = 0x08
; is the MUTE flag.  Channel names: AcMixerVol_ChannelNamePtrs.  Typed in ui_widgets/naka_disk_warning.c
; (scripts/converters/mixer_channel_table_retype.py).
AcMixerVol_Channels:	.incbin "includes/generated/naka_disk_warning.bin", 0x1860, 0x118
	.set AcMixerVol_Channels_MuteKey, AcMixerVol_Channels + 4	; the mute_key column
; AcMixerVol_GroupIconBitmap -- 35 x u32: sound-group number -> BitmapDescriptorTable index (table_data/ui_bitmaps.s) of the channel icon.
; AcMixerVol_PartSelect (ui/ui_widget_defs.s, on EVT_SOUND_SW_NO) takes the index from bits 24-28 of the event parameter,
; or forces 18 for mixer channel 26 (METR) and 19 for channel 27 (MIC), and draws entry [index] with DrawBitmapFast.
; Entries 0-19 are icon bitmaps 12-28 and 31-33 (18 = Bitmap_SoundIcon_Metronome, 19 = Bitmap_SoundIcon_Microphone); 20-34 are 0.
AcMixerVol_GroupIconBitmap:	.incbin "includes/generated/naka_disk_warning.bin", 0x1978, 0x8C
AcMixerVol_DrawChannel_Str_Fmt3d:		.incbin "includes/generated/naka_disk_warning.bin", 0x1A04, 0x4	; "%3d"
AcMixerVol_DrawChannel_Str_MUTE:		.incbin "includes/generated/naka_disk_warning.bin", 0x1A08, 0x6	; "MUTE"
; [nakarest] naka_disk_warning+0x1a0e  +0x1a0e..+0x1a4e (0xeaa6ba, 64 B)
; [nakarest] Text (64 B at 0xeaa6ba), first string "Debug Time!"; no registered NAKA table
; [nakarest] points into it; reached through source references DbMemo_Paint
; [nakarest] (ui/ui_widget_defs.s: `ld xde, DbMemo_Paint_Str_Debug_Time`).
DbMemo_Paint_Str_Debug_Time:					.incbin "includes/generated/naka_disk_warning.bin", 0x1A0E, 0xC	; "Debug Time!"
DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt4X:			.incbin "includes/generated/naka_disk_warning.bin", 0x1A1A, 0xC	; "%02X%04X  "
DbMemDump_Confirm_RowLoop_Str_Fmt2X_Fmt2X_Fmt2X_Fmt2X_Fmt2X:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A26, 0x28	; "%02X %02X %02X %02X %02X %02X %02X %02X"
; DbMemDump_StepTable -- 6 x u32: address step for each hex digit of the memory-dump debugger's address
; DbMemDump_OK: index = edit switch - 2 (0..5); the step is added (or subtracted, bit 7 of the param)
; to the dump address, which is then masked with NakaData_RomEnd.  Switch 0x10 steps 0x80 instead.
DbMemDump_StepTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A4E, 0x18
; DbDebugMenu_PageTitles -- 4 x u32: debug-menu page titles by page index (word at *(instance+42)): 0 "-MEMORY DUMP-",
; 1 "-MEMO-", 2 "-DEBUG3-", 3 "" = end. DbDebugMenu_Confirm (ui/ui_widget_defs.s) draws title[page] centred;
; DbDebugMenu_OK_Advance increments the page and sets it back to 0 when the title's first byte is 0.
DbDebugMenu_PageTitles:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A66, 0x10
; DbDebugMenu_PageTitleText -- 34 x char: "", "-DEBUG3-", "-MEMO-", "-MEMORY DUMP-" (NUL-terminated, 0xFF-padded),
; the strings DbDebugMenu_PageTitles points at.
DbDebugMenu_PageTitleText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A76, 0x22
; DbDebugMenu_PageWindowIds -- 3 x uint32_t (this 2-byte slice + the 10 unnamed bytes after it): NAKA view id opened by each page
; of the debug menu: [0] 0x31 MemDumpWindow ("-MEMORY DUMP-"), [1] 0x1E MemoWindow ("-MEMO-"), [2] 0xFFFFFFFF none ("-DEBUG3-").
; DbDebugMenuProc takes entry [page] (u16 at *(instance +42), x4) and sends EVT_SHOW / EVT_HIDE to it unless it is 0xFFFFFFFF;
; the page titles are DbDebugMenu_PageTitles, whose empty 4th title wraps the page back to 0.
DbDebugMenu_PageWindowIds:	.incbin "includes/generated/naka_disk_warning.bin", 0x1A98, 0x2
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A9A, 0xA	; 10 bytes after DbDebugMenu_PageWindowIds's string; unnamed (they sat under its label until 2026-10-03)
; PsTrkSw_AssignNamePtrs -- 20 x u32: 3-character name drawn for a track switch's assignment value 0..19
; PsTrackSwitchProc (ui/ui_widget_defs.s) copies the 20 pointers (0x28 words) to its frame; on EVT_PARA_DRAW
; it draws entry [value at the instance's +28 pointer] (the parameter's low 16 bits) with DrawStringCentered.
; 0 RT1, 1 LFT, 2 RT2, 3 P 8, 4 P 9, 5 P10, 6 P11, 7 P12, 8 P 5, 9 P 6, 10 P 7, 11 P 4, 12 DRM, 13 CHD, 14 APC,
; 15 CTL, 16 RHY, 17 P13, 18 P14, 19 P15 (the names are stored after it in reverse order).
PsTrkSw_AssignNamePtrs:	.incbin "includes/generated/naka_disk_warning.bin", 0x1AA4, 0x50
; PsTrkSw_AssignNames -- 20 x char[4]: the names PsTrkSw_AssignNamePtrs points at, element k = value 19-k
; ("P15" first, "RT1" last); drawn by PsTrkSw_Confirm_DrawSecondary (ui/ui_widget_defs.s).
PsTrkSw_AssignNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x1AF4, 0x50
; PsTrkSw_SelectStateLabels -- 5 x u32: track-switch label per select state 0-4: "", "REC", "PLAY", "MUTE", "CLR"
; PsTrackSwitchProc (ui/ui_widget_defs.s) copies it (10 words) to a local; on EVT_SELE_DRAW it indexes the copy by the
; state word *(instance+32) * 4 and draws the string centred, in the box coloured from PsTrkSw_SelectStateColor.
PsTrkSw_SelectStateLabels:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B44, 0x14
; PsTrkSw_SelectStateLabelText -- 22 x char: "CLR", "MUTE", "PLAY", "REC", "" (NUL-terminated, 0xFF-padded),
; the strings PsTrkSw_SelectStateLabels points at.
PsTrkSw_SelectStateLabelText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B58, 0x16
; PsTrkSw_SelectStateColor -- 5 x uint16_t: DrawBox colour per select state 0-4
; PsTrackSwitchProc (ui/ui_widget_defs.s) copies it to a local (5 words); on EVT_SELE_DRAW it indexes it
; by the state word *(instance+32) (`sla bc, 1`) and passes the word to DrawBox as the colour;
; the same state indexes the 5 strings copied from PsTrkSw_SelectStateLabels
PsTrkSw_SelectStateColor:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B6E, 0xA
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
; LanguageCheck_LanguageNames -- 6 x uint32_t + strings: name of each help language, index = language
; {"English", "German", "French", "Spanish", "Italian", "Indonesian"} (strings stored in reverse order).
; LanguageCheck (ui/ui_widget_defs.s) returns the table for EVT_GET_LANGUAGE_PTR; AcLanguageTextProc draws
; entry [help language byte 0x340e4] with EVT_PARA_DRAW.
LanguageCheck_LanguageNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x1B98, 0x4C
ObjectProc_OnGetPropString_Str_YZ:		.incbin "includes/generated/naka_disk_warning.bin", 0x1BE4, 0x4	; "YZ"
ObjectProc_OnGetPropName_Str_name:		.incbin "includes/generated/naka_disk_warning.bin", 0x1BE8, 0x6	; "name"
ObjectProc_OnGetPropName_Str_romram:	.incbin "includes/generated/naka_disk_warning.bin", 0x1BEE, 0x8	; "romram"
ObjectProc_OnGetPropName_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1BF6, 0x2	; ""
; ObjectProc_CaseTable -- 20 x int16: the case offsets of ObjectProc's compiled switch, relative to AcTrkSw_Return
ObjectProc_CaseTable:
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
; NakaMode_InitRecord -- 1 x 14-byte struct {u32 mode_proc, s32 start_title, s16 user_id, u32 name}: blank Mode object
; InitializeObjectTable (ui/ui_widget_defs.s, loop ExitWindow_Confirm) copies it (7 words) into all 32 records at
; RAM 0x328FC, then registers them as class Mode.  ModeProc reads +0 (GET_MODE_PROC/_ID), +4 (GET_START_TITLE),
; +8 (GET_USER_ID, sign-extended), +10 (GET_NAME).  Values: NAKA_APFUNC_DefaultFunction, -1, -1, "".
NakaMode_InitRecord:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C20, 0xE
; NakaMode_InitName -- 2 x char: "" + 0xFF fill, name of a blank Mode object
; NakaMode_InitRecord.name points here.
NakaMode_InitName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C2E, 0x2
; Title_RecordTemplate -- 1 x 22-byte title record: the default copied into each of the 256 Title records at RAM 0x32ABC
; {u32 title proc id 0x01200000, u32 start screen 0xFFFFFFFF (none), s16 user id -1 (iduNone), u32 name -> "",
; u32 return screen, s16 interrupt prev, s16 interrupt next (title numbers relative to TITLE_PS)}.
; InitializeObjectTable (ui/ui_widget_defs.s, loop at ExitWindow_OK) copies it 11 words at a time, then registers
; the table as class Title (TitleProc, 0x100 records, slot 0x1A0); TitleProc reads the fields.
Title_RecordTemplate:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C30, 0x16
; Title_RecordTemplateName -- 2 x char: "" + 0xFF fill, the name (+10) of Title_RecordTemplate
Title_RecordTemplateName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C46, 0x2
; RegisterObject_Str_EmptyName -- 1 x char[2]: "" + 0xFF alignment pad
; RegisterObject (ui/ui_widget_defs.s) stores its address in the name table (registry slot + 0x300) entry
; of the element it allocates, so a dynamically registered object starts with an empty name
RegisterObject_Str_EmptyName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C48, 0x2
; UnRegisterObject_EmptyName -- 2 x char: "" + 0xFF fill, stored as the name of an unregistered object
; UnRegisterObject clears the instance pointer and points the object's entry in the class + 0x300 name table here;
; that table is what EVT_SET_NAME / EVT_GET_NAME (Viewable_SetName, Strlen) read and write.
UnRegisterObject_EmptyName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4A, 0x2
; ClassProc_CaseTable -- 8 x int16: the case offsets of ClassProc's compiled switch, relative to ClassProc_Event_LoadFromWA
ClassProc_CaseTable:
	.short	ClassProc_Event_LoadFromWA - ClassProc_Event_LoadFromWA
	.short	ClassProc_Event_LoadFromHL - ClassProc_Event_LoadFromWA
	.short	ClassProc_Event_LoadFromIZ - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetInstanceSizeSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnCheckClassSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropStringEx - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropCountSp - ClassProc_Event_LoadFromWA
	.short	ClassProc_OnGetPropNameSp - ClassProc_Event_LoadFromWA
; ModeProc_CaseTable -- 6 x int16: the case offsets of ModeProc's compiled switch, relative to NakaWidget_ReturnConst_0x1600006
ModeProc_CaseTable:
	.short	ModeProc_OnGetModeProc - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeProcId - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetStartTitle - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeNow - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetModeOld - NakaWidget_ReturnConst_0x1600006
	.short	ModeProc_OnGetUserId - NakaWidget_ReturnConst_0x1600006
; Mode_UnregisteredName -- 2 x char: "" plus a 0xFF alignment pad, the name UnregisteredMode (ui/ui_widget_defs.s)
; stores at +10 of a 14-byte mode record (RAM 0x328FC + 14*mode), where RegisterMode stores the mode's name ("MD_NORMAL" ...).
Mode_UnregisteredName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C68, 0x2
; UnregisteredTitle_EmptyName -- 2 x char: "" + 0xFF fill, title name of an unregistered title slot
; UnregisteredTitle (ui/ui_widget_defs.s) stores its address at +10 of the 22-byte title record
; (RAM 0x32ABC + 22*n), the field RegisterTitle fills from its name argument.
UnregisteredTitle_EmptyName:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C6A, 0x2
; TitleProc_EasySetTable -- 1 x uint32_t: TITLE_SDTECD, the title of entry 0 of the press-and-hold (easy set) table
; the table is 12 x {u32 title, u32 event, u32 hold period, u16 0}; its other 164 bytes sit under TitleProc_EasySetHold0Tail
; TitleProc (ui/ui_widget_defs.s) indexes it by the EVT_EASY_SET_* parameter (*14): EASY_SET_ON arms
; SetApTimer with +8, EASY_SET_GO sends event +4 with param = title +0, EASY_SET_OFF kills the timer
TitleProc_EasySetTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C6C, 0x4
; TitleProc_EasySetHold0Tail -- 1 x 10 bytes: fields +4..+13 of record 0 of TitleProc's easy-set hold table
; The table is 12 x {u32 title id, u32 EVT_CHANGE_TITLE/EVT_INTERRUPT_TITLE, u32 hold ticks, u16 unread},
; starting at TitleProc_EasySetTable (record 0's title id); EnumList_HitTest reads this label + 14*button as the event column.
; Better: one label for all 168 bytes at TitleProc_EasySetTable, read here as that label + 4.
TitleProc_EasySetHold0Tail:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C70, 0xA
; TitleProc_EasySetHold1to11 -- 11 x 14-byte struct: records 1..11 of TitleProc's easy-set hold table
; Indexed by the EVT_EASY_SET_* parameter (the button, 0..11; stride 14 = x*8-x, doubled).  EVT_EASY_SET_ON arms
; SetApTimer(hold_ticks); on EVT_EASY_SET_GO EnumList_HitTest sends title_event(title_id), skipping
; EVT_CHANGE_TITLE in MD_NORMAL.  The u16 at +12 is not read (0 in every record).
TitleProc_EasySetHold1to11:	.incbin "includes/generated/naka_disk_warning.bin", 0x1C7A, 0x9A
; TitleProc_Str_j -- 6 x int16: the case offsets of TitleProc's compiled switch, relative to TitleProc_EventDispatch
TitleProc_Str_j:
	.short	TitleProc_OnGetUserId - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleProc - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleProcId - TitleProc_EventDispatch
	.short	TitleProc_OnGetStartScreen - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleNow - TitleProc_EventDispatch
	.short	TitleProc_OnGetTitleOld - TitleProc_EventDispatch
; Title_InterruptTimeTicks -- 13 x s16: IntTimeID -> timeout of an interrupt screen, in ApTimer ticks (IT_1Sec..IT_10Sec = 42..417).
; SetInterruptTime (ui/ui_widget_defs.s) stores entry [id] at RAM 0x2BC32; TitleProc uses it as the interval of the
; EVT_RETURN_TITLE timer (ResetApTimer).  Ids are the IntTimeID enum: 0 IT_Off (0), 1 IT_Default, 2 IT_Hold (167 each).
Title_InterruptTimeTicks:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D20, 0x1A
; ViewableProc_CaseTable -- 7 x int16: the case offsets of ViewableProc's compiled switch, relative to Viewable_GetClassProc
ViewableProc_CaseTable:
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
BoxStyle7_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D48, 0xA
; [nakarest] naka_disk_warning+0x1d52  +0x1d52..+0x1d58 (0xeaa9fe, 6 B)
; [nakarest] Text (6 B at 0xeaa9fe), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle7_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle7_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle7_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D52, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d58  +0x1d58..+0x1d64 (0xeaaa04, 12 B)
; [nakarest] Text (12 B at 0xeaaa04), first string "sword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle8_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle8_Setup_Data`).
BoxStyle8_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D58, 0xC
; [nakarest] naka_disk_warning+0x1d64  +0x1d64..+0x1d6a (0xeaaa10, 6 B)
; [nakarest] Text (6 B at 0xeaaa10), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle8_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle8_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle8_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D64, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d6a  +0x1d6a..+0x1d76 (0xeaaa16, 12 B)
; [nakarest] Text (12 B at 0xeaaa16), first string "uword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle9_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle9_Setup_Data`).
BoxStyle9_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D6A, 0xC
; [nakarest] naka_disk_warning+0x1d76  +0x1d76..+0x1d7c (0xeaaa22, 6 B)
; [nakarest] Text (6 B at 0xeaaa22), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle9_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, BoxStyle9_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle9_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D76, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d7c  +0x1d7c..+0x1d88 (0xeaaa28, 12 B)
; [nakarest] Text (12 B at 0xeaaa28), first string "schar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle10_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle10_Setup_Data`).
BoxStyle10_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D7C, 0xC
; [nakarest] naka_disk_warning+0x1d88  +0x1d88..+0x1d8e (0xeaaa34, 6 B)
; [nakarest] Text (6 B at 0xeaaa34), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle10_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle10_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle10_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D88, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1d8e  +0x1d8e..+0x1d9a (0xeaaa3a, 12 B)
; [nakarest] Text (12 B at 0xeaaa3a), first string "uchar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle11_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle11_Setup_Data`).
BoxStyle11_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D8E, 0xC
; [nakarest] naka_disk_warning+0x1d9a  +0x1d9a..+0x1da0 (0xeaaa46, 6 B)
; [nakarest] Text (6 B at 0xeaaa46), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle11_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle11_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle11_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1D9A, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1da0  +0x1da0..+0x1dac (0xeaaa4c, 12 B)
; [nakarest] Text (12 B at 0xeaaa4c), first string "slong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle12_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle12_Setup_Data`).
BoxStyle12_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1DA0, 0xC
; [nakarest] naka_disk_warning+0x1dac  +0x1dac..+0x1db2 (0xeaaa58, 6 B)
; [nakarest] Text (6 B at 0xeaaa58), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle12_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle12_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle12_CalcWidth_Str_Fmts_Fmtd:	.incbin "includes/generated/naka_disk_warning.bin", 0x1DAC, 0x6	; "&%s%d"
; [nakarest] naka_disk_warning+0x1db2  +0x1db2..+0x1dbe (0xeaaa5e, 12 B)
; [nakarest] Text (12 B at 0xeaaa5e), first string "ulong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, BoxStyle13_Setup_Data`).
BoxStyle13_Setup_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1DB2, 0xC
; [nakarest] naka_disk_warning+0x1dbe  +0x1dbe..+0x1ed0 (0xeaaa6a, 274 B)
; [nakarest] Text (274 B at 0xeaaa6a), first string "&%s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_CalcWidth
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, BoxStyle13_CalcWidth_Str_Fmts_Fmtd`).
BoxStyle13_CalcWidth_Str_Fmts_Fmtd:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DBE, 0x6	; "&%s%d"
EdgeDraw_TopRight_Inner_Str_left:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DC4, 0x6	; ".left"
EdgeDraw_TopRight_Inner_Str_LBrace:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DCA, 0x2	; "{"
EdgeDraw_BottomRight_Str_top:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DCC, 0x6	; ".top"
TabDraw_TopEdge_Str_width:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DD2, 0x8	; ".width"
RectY2Proc_MemberName:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DDA, 0x8	; ".height"
RectY2Proc_DumpClose:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DE2, 0x2	; "}"
PointXProc_MemberName:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DE4, 0x4	; ".x"
PointXProc_DumpOpen:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DE8, 0x2	; "{"
PointYProc_MemberName:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DEA, 0x4	; ".y"
PointYProc_DumpClose:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DEE, 0x2	; "}"
ClassIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF0, 0x4	; "idc"
ScrollBar_CalcRange_Str_DQuote:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF4, 0x2	; """
ScrollBar_CalcRange_Str_DQuote_2:		.incbin "includes/generated/naka_disk_warning.bin", 0x1DF6, 0x2	; """
FontIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DF8, 0x4	; "id"
IconIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1DFC, 0x8	; "idICON_"
BitmapIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E04, 0x4	; "id"
ApFuncIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E08, 0x4	; "idf"
MainFuncIDProc_DumpPrefix:			.incbin "includes/generated/naka_disk_warning.bin", 0x1E0C, 0x4	; "idf"
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
; NameProc_MakeDump_Str_Empty -- 1 x char[2]: "" + 0xFF alignment pad
; NameProc (ui/ui_widget_defs.s) Strcpy's it into the caller's buffer for EVT_MAKE_DUMP
; (EVT_GET_PROP_MEMBER gives "name", EVT_DUMP_PROPERTY_EX NameProc_GetText_Str_Empty)
NameProc_MakeDump_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F26, 0x2
NameProc_GetText_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F28, 0x2	; ""
; [nakarest] naka_disk_warning+0x1f2a  +0x1f2a..+0x1f32 (0xeaabd6, 8 B)
; [nakarest] Text (8 B at 0xeaabd6), first string "romram"; no registered NAKA table points into
; [nakarest] it; reached through source references ConstFlagProc_GetValue (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, ConstFlagProc_GetValue_Str_romram`).
ConstFlagProc_GetValue_Str_romram:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F2A, 0x8	; "romram"
; ConstFlagProc_DumpText -- 2 x char: "" + 0xFF fill, Strcpy'd into the caller's buffer on EVT_MAKE_DUMP
; (EVT_GET_PROP_MEMBER copies "romram" instead, ConstFlagProc_GetValue_Str_romram).
ConstFlagProc_DumpText:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F32, 0x2
ConstFlagProc_SetValue_Check_Str_Empty:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F34, 0x2	; ""
CommonIDProc_OnDumpPointerEx_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F36, 0x2
; CommonIDProc_CaseTable -- 7 x int16: the case offsets of CommonIDProc's compiled switch, relative to CommonIDProc_OnGetPropDataSp
CommonIDProc_CaseTable:
	.short	CommonIDProc_ReturnZero - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPointerEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnDumpPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnSetPropertyEx - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnGetPropDataSp - CommonIDProc_OnGetPropDataSp
	.short	CommonIDProc_OnGetPropDataCountSp - CommonIDProc_OnGetPropDataSp
; DrawIcons_PixelPairTable -- 256 x {u8 left, u8 right}: the two colour indices of the two 4-bpp pixels in one
; icon byte (high nibble = left pixel), nibble n -> n for n < 8, else 0xF0 + n.  DrawIcons_Impl writes
; entry [byte] as one word per icon byte, 12 bytes x 24 rows: a 24 x 24 icon.  Typed in
; ui_widgets/naka_disk_warning.c (scripts/converters/icon_pixel_pair_table_retype.py).
DrawIcons_PixelPairTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x1F46, 0x200
DrawBitmapFile_Impl_Data:	.incbin "includes/generated/naka_disk_warning.bin", 0x2146, 0x4
; DrawPartGroup_DispatchByType_CaseTable -- 16 x int16: the case offsets of DrawPartGroup_DispatchByType's compiled switch, relative to DrawPartGroup_TableJump_DefaultCase
DrawPartGroup_DispatchByType_CaseTable:
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
; Draw_DispatchByPartType_CaseTable -- 25 x int16: the case offsets of Draw_DispatchByPartType's compiled switch, relative to Draw_StyledBoxWithFrame
Draw_DispatchByPartType_CaseTable:
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
CaptureLcd_Str_wb:		.incbin "includes/generated/naka_disk_warning.bin", 0x21B2, 0x4	; "wb"
; ChangeWall_WallpaperTable -- 1 x u32: bitmap address of wallpaper 0, the first field of the wallpaper table
; The table is 5 x {u32 bitmap (320 bytes per row), u32 palette, u16 0}; ChangeWall_Impl reads +0 into RAM 0x30452
; (drawing code reads it as base + y*0x140 + x); ChangePalette_Impl reads ChangePalette_WallpaperPalettes (= this + 4),
; same stride, as the palette.  Better: one 50-byte label here.
ChangeWall_WallpaperTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x21B6, 0x4
; ChangePalette_WallpaperPalettes -- 1 x {u32 palette, u16 reserved}: tail of wallpaper record 0
; ChangePalette_Impl (ui/ui_window_procs.s) indexes from here with stride 10 (x*5*2) and loads the
; 32-bit palette pointer, then SetPaletteRGB for DAC entries 0x20..0xDF from it
; record 0 starts 4 bytes earlier at ChangeWall_WallpaperTable (its bitmap pointer)
ChangePalette_WallpaperPalettes:	.incbin "includes/generated/naka_disk_warning.bin", 0x21BA, 0x6
; ChangeWall_WallpaperRecords -- 4 x {u32 bitmap, u32 palette, u16 0}: wallpaper records 1-4
; ChangeWall_Impl reads +0 (bitmap -> 0x3EF98 / 0x30452), ChangePalette_Impl +4 (palette), stride 10
; bitmaps: 0x900000 (table data), 0x3C0000 (custom-data flash, twice), 0x56800 (RAM)
; each palette = bitmap + 76800 (320 x 240 bytes)
ChangeWall_WallpaperRecords:	.incbin "includes/generated/naka_disk_warning.bin", 0x21C0, 0x28
; ClipBlit_DiscHalfWidth -- 32 x u16: half-width of a radius-30 disc at |dy| = 0..30 from its centre (round(sqrt(900 - dy^2))); entry 31 is 0.
; ClipBlit_Replace_Impl (ui/ui_window_procs.s) takes Math_AbsInt16(y - centre y) as the index, copies 2*w pixels per scanline
; starting 30 - w pixels into the box, i.e. a filled disc of radius 30 from OFFSCREEN_BUFFER_2 into OFFSCREEN_BUFFER_1.
ClipBlit_DiscHalfWidth:	.incbin "includes/generated/naka_disk_warning.bin", 0x21E8, 0x40
; GraphicsRender_LowBandColorIndex -- 32 x uint8_t: palette colour for DAC entries 32..63
; GraphicsRender_ByteData_Join (display/graphics_text_vga.s): for DAC i = 32..63, byte [i-32] ->
; Table_LookupDword (4-byte RGB at 0x324FC + 4*index) -> SetPaletteRGB(i); GraphicsRender_PaletteSrc192 does
; the same for DAC 192..223
GraphicsRender_LowBandColorIndex:	.incbin "includes/generated/naka_disk_warning.bin", 0x2228, 0x20
; GraphicsRender_PaletteSrc192 -- 32 x uint8_t: source palette index for palette slots 192..223
; GraphicsRender_ByteData_Loop3 (display/graphics_text_vga.s): for slot = 192..223,
; SetPaletteRGB(slot, Table_LookupDword(table[slot - 192])) -- both work on the 256 x u32 palette at RAM 0x324FC.
; GraphicsRender_LowBandColorIndex does the same for slots 32..63.
GraphicsRender_PaletteSrc192:	.incbin "includes/generated/naka_disk_warning.bin", 0x2248, 0x20
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
; RAM: the sdb_* macros of audio/sound_editor_ui.s); GraphicsRender_Start calls [op].  Op 08 blits a bitmap, ops 09-0B print a
; number (Sprintf %Nd); their record layouts are not derived yet (scripts/tools/label_bound_ops_08_0b.py).
GraphicsRender_Start_PtrTable:
	.long	DrawFunc_Init
	.long	GraphicsRender_RetStub
	.long	DrawText_ExtendedLayout
	.long	ColorBlit_WithPaletteSave
	.long	ColorBlit_Variant_ByteData
	.long	DrawFunc_Init_Variant1
	.long	AccDraw_Secondary_Helper20
	.long	DrawText_ExtLayout_Variant1
	.long	SeGfx_BoundOp08_ColorBlit
	.long	SeGfx_BoundOp09_FormatNumber
	.long	SeGfx_BoundOp0A_FormatNumber
	.long	SeGfx_BoundOp0B_FormatNumber
; SeGfx_StaticOp06_ClipBox -- 4 x uint16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: text clip box of static display op 06 (the whole 320 x 240 screen)
; SeGfx_StaticOp06_CellTextFont0 copies it with `ldirw` (4 words) into its frame and passes that copy as the box argument (XWA) of
; DrawText_QueueOrDirect, whose TextRender_BeginDraw clamps x2 to 319 and y2 to 239. Entry 0 of SeGfx_TextClipBoxes[6][4] in C.
SeGfx_StaticOp06_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2328, 0x8
; SeGfx_StaticOp07_ClipBox -- 4 x int16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: the whole 320 x 240 screen, text clip box
; SeGfx_StaticOp07_CellTextFont1 (display/graphics_text_vga.s), static display-record op 07 (cell text, font 1): copies the 8 bytes to its frame with ldirw and
; passes that copy as the clip rectangle (XWA) to DrawText_QueueOrDirect -> TextRender_BeginDraw, which
; clamps x1/y1 to >= 0, x2 to <= 319 and y2 to <= 239.
SeGfx_StaticOp07_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2330, 0x8
; SeGfx_StaticOp08_ClipBox -- 4 x uint16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: text clip box of static display op 08 (the whole 320 x 240 screen)
; SeGfx_StaticOp08_CellTextFont2 copies it with `ldirw` (4 words) into its frame and passes that copy as the box argument (XWA) of
; DrawText_QueueOrDirect, whose TextRender_BeginDraw clamps x2 to 319 and y2 to 239. Entry 2 of SeGfx_TextClipBoxes[6][4] in C.
; The note's reader (SeGfx_StaticOp07_CellTextFont1) is wrong: op 07 reads the box before this one.
SeGfx_StaticOp08_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2338, 0x8
; SeGfx_StaticOp17_ClipBox -- 4 x int16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: the whole 320 x 240 screen, text clip box
; SeGfx_StaticOp17_PixelTextFont3 (display/graphics_text_vga.s), static display-record op 17 (pixel-positioned text): copies the 8 bytes to its frame with ldirw and
; passes that copy as the clip rectangle (XWA) to DrawText_QueueOrDirect -> TextRender_BeginDraw, which
; clamps x1/y1 to >= 0, x2 to <= 319 and y2 to <= 239.
SeGfx_StaticOp17_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2340, 0x8
; SeGfx_StaticOp1C_ClipBox -- 4 x uint16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: text clip box of static display op 1C (the whole 320 x 240 screen)
; SeGfx_StaticOp1C_PixelTextFont4 copies it with `ldirw` (4 words) into its frame and passes that copy as the box argument (XWA) of
; DrawText_QueueOrDirect, whose TextRender_BeginDraw clamps x2 to 319 and y2 to 239. Entry 4 of SeGfx_TextClipBoxes[6][4] in C.
; The note's reader (SeGfx_StaticOp07_CellTextFont1) is wrong.
SeGfx_StaticOp1C_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2348, 0x8
; SeGfx_StaticOp20_ClipBox -- 4 x int16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: the whole 320 x 240 screen, text clip box
; SeGfx_StaticOp20_CellTextFont6 (display/graphics_text_vga.s), static display-record op 20 (cell text, font 6): copies the 8 bytes to its frame with ldirw and
; passes that copy as the clip rectangle (XWA) to DrawText_QueueOrDirect -> TextRender_BeginDraw, which
; clamps x1/y1 to >= 0, x2 to <= 319 and y2 to <= 239.
SeGfx_StaticOp20_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2350, 0x8
; TextStyle_FontTable -- 64 x u32, text style (record byte & 0x3f) -> font index (table_data/fonts.s);
; the readers in display/graphics_text_vga.s pass the entry to DrawText_QueueOrDirect as the font.
; Typed in ui_widgets/naka_disk_warning.c (scripts/converters/text_tables_retype.py).
TextStyle_FontTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x2358, 0x100
; TextStyle_NibbleFontTable -- 16 x u8: style nibble (byte +6 & 15 of a draw record) -> font number (table_data/fonts.s).
; DrawText_ExtendedLayout and the DrawFunc_Init number fields (display/graphics_text_vga.s) read entry [nibble] as a byte
; and pass it to DrawText_QueueOrDirect as the font, the 4-bit companion of TextStyle_FontTable (byte +6 & 0x3f).
; CONFLICT: four readers in display/scoop_display.s index the same address with `sla wa, 2` / `ld xix, (xbc+wa)` (32-bit stride),
; which would fetch 0x03030303-style values; that Scoop path cannot be using a valid font from this table.
TextStyle_NibbleFontTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x2458, 0x10
; DrawText_ExtendedLayout_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; DrawText_ExtendedLayout (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
DrawText_ExtendedLayout_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x2468, 0x8
; SeGfx_BoundOp07_ClipBox -- 4 x uint16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: text clip box of bound display op 07 (the whole 320 x 240 screen)
; DrawText_ExtLayout_Variant1 copies it with `ldirw` (4 words) into its frame and passes that copy as the box argument (XWA) of
; DrawText_QueueOrDirect, whose TextRender_BeginDraw clamps x2 to 319 and y2 to 239.
SeGfx_BoundOp07_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2470, 0x8
; SeGfx_BoundOp00_ClipBox -- 4 x int16_t {x1, y1, x2, y2} = {0, 0, 319, 239}: the whole 320 x 240 screen, text clip box
; DrawFunc_Init (display/graphics_text_vga.s), bound display-record op 00 (GraphicsRender_Start_PtrTable[0]: a RAM byte field printed with %1d/%2d/%3d): copies the 8 bytes to its frame with ldirw and
; passes that copy as the clip rectangle (XWA) to DrawText_QueueOrDirect -> TextRender_BeginDraw, which
; clamps x1/y1 to >= 0, x2 to <= 319 and y2 to <= 239.
SeGfx_BoundOp00_ClipBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x2478, 0x8
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
; [nakarest] naka_disk_warning+0x2488  +0x2488..+0x24ac (0xeab134, 36 B)
; [nakarest] Text (36 B at 0xeab134), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_FontTable0
; [nakarest] (display/graphics_text_vga.s: `ld xwa, DrawFunc_Init_FontTable0_Str_Fmt3d`).
DrawFunc_Init_FontTable0_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2488, 0x4	; "%3d"
; DrawFunc_Init_Variant1_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; DrawFunc_Init_Variant1 (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
DrawFunc_Init_Variant1_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x248C, 0x8
DrawFunc_Init_Variant1_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2494, 0x4	; "%1d"
DrawFunc_Init_Variant1_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x2498, 0x4	; "%2d"
DrawFunc_Init_Variant1_Str_Fmt3d:	.incbin "includes/generated/naka_disk_warning.bin", 0x249C, 0x4	; "%3d"
DrawFunc_Init_Entry_Str_Fmt2d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24A0, 0x4	; "%2d"
DrawFunc_Init_Entry_Str_Fmt3d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24A4, 0x4	; "%3d"
DrawFunc_Init_Entry_Str_Fmt4d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24A8, 0x4	; "%4d"
; SeGfx_BoundOp06_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; SeGfx_BoundOp06_Helper (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
SeGfx_BoundOp06_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x24AC, 0x8
; [nakarest] naka_disk_warning+0x24b4  +0x24b4..+0x24b8 (0xeab160, 4 B)
; [nakarest] Text (4 B at 0xeab160), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,DrawFunc_Init_Entry_Str_Fmt1d`).
DrawFunc_Init_Entry_Str_Fmt1d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24B4, 0x4	; "%1d"
; [nakarest] naka_disk_warning+0x24b8  +0x24b8..+0x24bc (0xeab164, 4 B)
; [nakarest] Text (4 B at 0xeab164), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,DrawFunc_Init_Entry2_Str_Fmt2d`).
DrawFunc_Init_Entry2_Str_Fmt2d:	.incbin "includes/generated/naka_disk_warning.bin", 0x24B8, 0x4	; "%2d"
; [nakarest] naka_disk_warning+0x24bc  +0x24bc..+0x24f4 (0xeab168, 56 B)
; [nakarest] Text (56 B at 0xeab168), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,DrawFunc_Init_Entry3_Str_Fmt3d`).
DrawFunc_Init_Entry3_Str_Fmt3d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24BC, 0x4	; "%3d"
; SeGfx_BoundOp09_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; SeGfx_BoundOp09_FormatNumber (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
SeGfx_BoundOp09_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x24C0, 0x8
DrawFunc_Init_Entry3_Str_Fmt1d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24C8, 0x4	; "%1d"
DrawFunc_Init_Entry3_Str_Fmt2d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24CC, 0x4	; "%2d"
DrawFunc_Init_Entry3_Str_Fmt3d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x24D0, 0x4	; "%3d"
; SeGfx_BoundOp0B_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; SeGfx_BoundOp0B_FormatNumber (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
SeGfx_BoundOp0B_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x24D4, 0x8
DrawFunc_Init_Entry3_Str_Fmt1d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x24DC, 0x4	; "%1d"
FmtStr_pct2d:				.incbin "includes/generated/naka_disk_warning.bin", 0x24E0, 0x4
DrawFunc_Init_Entry4_Str_Fmt3d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24E4, 0x4	; "%3d"
DrawFunc_Init_Entry5_Str_Fmt2d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24E8, 0x4	; "%2d"
DrawFunc_Init_Entry5_Str_Fmt3d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24EC, 0x4	; "%3d"
DrawFunc_Init_Entry5_Str_Fmt4d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24F0, 0x4	; "%4d"
; SeGfx_BoundOp0A_ClipRect -- 4 x int16_t: clip rectangle {x1 0, y1 0, x2 319, y2 239}, the whole 320 x 240 screen
; SeGfx_BoundOp0A_FormatNumber (display/graphics_text_vga.s) copies it to its frame (`ldirw`, 4 words) and passes the copy to
; DrawText_QueueOrDirect as the clip rectangle.  The old C read its last 4 bytes (3F 01 EF 00) as a pointer.
SeGfx_BoundOp0A_ClipRect:	.incbin "includes/generated/naka_disk_warning.bin", 0x24F4, 0x8
DrawFunc_Init_Entry5_Str_Fmt1d:		.incbin "includes/generated/naka_disk_warning.bin", 0x24FC, 0x4	; "%1d"
DrawFunc_Init_Entry5_Str_Fmt2d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x2500, 0x4	; "%2d"
DrawFunc_Init_Entry5_Str_Fmt3d_2:	.incbin "includes/generated/naka_disk_warning.bin", 0x2504, 0x4	; "%3d"
; Text_CharGlyphMap -- 256 x u8, character code -> font glyph code: ASCII to itself except '\' -> 0xA5,
; 0x10-0x1F to UI-symbol glyphs, 0x80-0xAB to the Latin-1 letters of the fonts' accent page.
; FontGlyph_ByteData maps through it; the routine after it searches it for the reverse.
; Typed in ui_widgets/naka_disk_warning.c (scripts/converters/text_tables_retype.py).
Text_CharGlyphMap:	.incbin "includes/generated/naka_disk_warning.bin", 0x2508, 0x100
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
; [nakarest] reached through source references BitmapIDProc_OnGetPropDataCountSp (ui/ui_widget_defs.s: `ld hl,
; [nakarest] (BitmapIDProc_EntryCount:24)`).
BitmapIDProc_EntryCount:	.incbin "includes/generated/naka_disk_warning.bin", 0x271E, 0x2	; """
; BitmapIDProc_PtrTable -- 256 x u32: bitmap id -> resource name.  BitmapIDProc reads table[id] for
; GET/DUMP_PROPERTY_EX and searches it by name for SET_PROPERTY_EX.  35 entries are non-zero, while
; BitmapIDProc_EntryCount (the GET_PROP_DATA_COUNT_SP answer) is 34.
BitmapIDProc_PtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x2720, 0x400
; BitmapID_Names -- the resource names BitmapIDProc_PtrTable points at ("TrashIcon", "GoldTechnics" ...).
BitmapID_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x2B20, 0x138
; BitmapID_FileNamePtrTable -- 256 x u32: bitmap id -> its .bmp file name, parallel to BitmapIDProc_PtrTable
; (like IconBitmapNamePtrTable for icons).  No reader in the ROM: a development-time table.
BitmapID_FileNamePtrTable:	.incbin "includes/generated/naka_disk_warning.bin", 0x2C58, 0x400
; BitmapID_FileNames -- the .bmp file names BitmapID_FileNamePtrTable points at ("19mic.bmp" ...).
BitmapID_FileNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3058, 0x190
; ClassProps_Object -- 1 x uint32_t: the propname block of NAKA class Object (Class table slot 0x160, entry 0, its +20)
; One pointer per letter of its propdata "" (no own fields), then one to ""; the names follow in
; ClassProps_Object_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Object:	.incbin "includes/generated/naka_disk_warning.bin", 0x31E8, 0x4
; ClassProps_Object_Names -- 2 x char: the field names of class Object, in reverse field order: ""
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Object points at each one.
ClassProps_Object_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x31EC, 0x2
; ClassProps_Function -- 2 x uint32_t: the propname block of NAKA class Function (Class table slot 0x160, entry 1, its +20)
; One pointer per letter of its propdata "I" -- "func", then one to ""; the names follow in
; ClassProps_Function_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Function:	.incbin "includes/generated/naka_disk_warning.bin", 0x31EE, 0x8
; ClassProps_Function_Names -- 8 x char: the field names of class Function, in reverse field order: "", "func"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Function points at each one.
ClassProps_Function_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x31F6, 0x8
; ClassProps_ApFunction -- 1 x uint32_t: the propname block of NAKA class ApFunction (Class table slot 0x160, entry 2, its +20)
; One pointer per letter of its propdata "" (no own fields), then one to ""; the names follow in
; ClassProps_ApFunction_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ApFunction:	.incbin "includes/generated/naka_disk_warning.bin", 0x31FE, 0x4
; ClassProps_ApFunction_Names -- 2 x char: the field names of class ApFunction, in reverse field order: ""
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ApFunction points at each one.
ClassProps_ApFunction_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3202, 0x2
; ClassProps_MainFunction -- 1 x uint32_t: the propname block of NAKA class MainFunction (Class table slot 0x160, entry 3, its +20)
; One pointer per letter of its propdata "" (no own fields), then one to ""; the names follow in
; ClassProps_MainFunction_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_MainFunction:	.incbin "includes/generated/naka_disk_warning.bin", 0x3204, 0x4
; ClassProps_MainFunction_Names -- 2 x char: the field names of class MainFunction, in reverse field order: ""
; NUL-terminated, 0xFF pads each to an even length; ClassProps_MainFunction points at each one.
ClassProps_MainFunction_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3208, 0x2
; ClassProps_Class -- 8 x uint32_t: the propname block of NAKA class Class (Class table slot 0x160, entry 4, its +20)
; One pointer per letter of its propdata "JMBBXXL" -- "proc", "parent", "allsize", "selfsize", "name", "propdata", "propname", then one to ""; the names follow in
; ClassProps_Class_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Class:	.incbin "includes/generated/naka_disk_warning.bin", 0x320A, 0x20
; ClassProps_Class_Names -- 60 x char: the field names of class Class, in reverse field order: "", "propname", "propdata", "name", "selfsize", "allsize", "parent", "proc"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Class points at each one.
ClassProps_Class_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x322A, 0x3C
; ClassProps_SupportClass -- 5 x uint32_t: the propname block of NAKA class SupportClass (Class table slot 0x160, entry 5, its +20)
; One pointer per letter of its propdata "JBBK" -- "proc", "count", "size", "prop", then one to ""; the names follow in
; ClassProps_SupportClass_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_SupportClass:	.incbin "includes/generated/naka_disk_warning.bin", 0x3266, 0x14
; ClassProps_SupportClass_Names -- 26 x char: the field names of class SupportClass, in reverse field order: "", "prop", "size", "count", "proc"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_SupportClass points at each one.
ClassProps_SupportClass_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x327A, 0x1A
; ClassProps_Mode -- 5 x uint32_t: the propname block of NAKA class Mode (Class table slot 0x160, entry 6, its +20)
; One pointer per letter of its propdata "kalX" -- "proc", "title", "user", "name", then one to ""; the names follow in
; ClassProps_Mode_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Mode:	.incbin "includes/generated/naka_disk_warning.bin", 0x3294, 0x14
; ClassProps_Mode_Names -- 26 x char: the field names of class Mode, in reverse field order: "", "name", "user", "title", "proc"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Mode points at each one.
ClassProps_Mode_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x32A8, 0x1A
; ClassProps_Title -- 8 x uint32_t: the propname block of NAKA class Title (Class table slot 0x160, entry 7, its +20)
; One pointer per letter of its propdata "kNlXNAA" -- "proc", "top", "user", "name", "now", "prev", "next", then one to ""; the names follow in
; ClassProps_Title_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Title:	.incbin "includes/generated/naka_disk_warning.bin", 0x32C2, 0x20
; ClassProps_Title_Names -- 40 x char: the field names of class Title, in reverse field order: "", "next", "prev", "now", "name", "user", "top", "proc"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Title points at each one.
ClassProps_Title_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x32E2, 0x28
; ClassProps_ResBitmap -- 2 x uint32_t: the propname block of NAKA class ResBitmap (Class table slot 0x160, entry 8, its +20)
; One pointer per letter of its propdata "B" -- "data", then one to ""; the names follow in
; ClassProps_ResBitmap_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResBitmap:	.incbin "includes/generated/naka_disk_warning.bin", 0x330A, 0x8
; ClassProps_ResBitmap_Names -- 8 x char: the field names of class ResBitmap, in reverse field order: "", "data"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResBitmap points at each one.
ClassProps_ResBitmap_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3312, 0x8
; ClassProps_ResFrame -- 2 x uint32_t: the propname block of NAKA class ResFrame (Class table slot 0x160, entry 9, its +20)
; One pointer per letter of its propdata "B" -- "data", then one to ""; the names follow in
; ClassProps_ResFrame_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResFrame:	.incbin "includes/generated/naka_disk_warning.bin", 0x331A, 0x8
; ClassProps_ResFrame_Names -- 8 x char: the field names of class ResFrame, in reverse field order: "", "data"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResFrame points at each one.
ClassProps_ResFrame_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3322, 0x8
; ClassProps_ResIcon -- 2 x uint32_t: the propname block of NAKA class ResIcon (Class table slot 0x160, entry 10, its +20)
; One pointer per letter of its propdata "B" -- "data", then one to ""; the names follow in
; ClassProps_ResIcon_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResIcon:	.incbin "includes/generated/naka_disk_warning.bin", 0x332A, 0x8
; ClassProps_ResIcon_Names -- 8 x char: the field names of class ResIcon, in reverse field order: "", "data"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResIcon points at each one.
ClassProps_ResIcon_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3332, 0x8
; ClassProps_ResFont -- 2 x uint32_t: the propname block of NAKA class ResFont (Class table slot 0x160, entry 11, its +20)
; One pointer per letter of its propdata "B" -- "data", then one to ""; the names follow in
; ClassProps_ResFont_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResFont:	.incbin "includes/generated/naka_disk_warning.bin", 0x333A, 0x8
; ClassProps_ResFont_Names -- 8 x char: the field names of class ResFont, in reverse field order: "", "data"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResFont points at each one.
ClassProps_ResFont_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3342, 0x8
; ClassProps_ResEvent -- 2 x uint32_t: the propname block of NAKA class ResEvent (Class table slot 0x160, entry 12, its +20)
; One pointer per letter of its propdata "X" -- "name", then one to ""; the names follow in
; ClassProps_ResEvent_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResEvent:	.incbin "includes/generated/naka_disk_warning.bin", 0x334A, 0x8
; ClassProps_ResEvent_Names -- 8 x char: the field names of class ResEvent, in reverse field order: "", "name"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResEvent points at each one.
ClassProps_ResEvent_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3352, 0x8
; ClassProps_ResMethod -- 2 x uint32_t: the propname block of NAKA class ResMethod (Class table slot 0x160, entry 13, its +20)
; One pointer per letter of its propdata "X" -- "name", then one to ""; the names follow in
; ClassProps_ResMethod_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResMethod:	.incbin "includes/generated/naka_disk_warning.bin", 0x335A, 0x8
; ClassProps_ResMethod_Names -- 8 x char: the field names of class ResMethod, in reverse field order: "", "name"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResMethod points at each one.
ClassProps_ResMethod_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3362, 0x8
; ClassProps_ResString -- 2 x uint32_t: the propname block of NAKA class ResString (Class table slot 0x160, entry 14, its +20)
; One pointer per letter of its propdata "B" -- "data", then one to ""; the names follow in
; ClassProps_ResString_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResString:	.incbin "includes/generated/naka_disk_warning.bin", 0x336A, 0x8
; ClassProps_ResString_Names -- 8 x char: the field names of class ResString, in reverse field order: "", "data"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResString points at each one.
ClassProps_ResString_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3372, 0x8
; ClassProps_ResName -- 2 x uint32_t: the propname block of NAKA class ResName (Class table slot 0x160, entry 15, its +20)
; One pointer per letter of its propdata "X" -- "name", then one to ""; the names follow in
; ClassProps_ResName_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_ResName:	.incbin "includes/generated/naka_disk_warning.bin", 0x337A, 0x8
; ClassProps_ResName_Names -- 8 x char: the field names of class ResName, in reverse field order: "", "name"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_ResName points at each one.
ClassProps_ResName_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3382, 0x8
; ClassProps_Viewable -- 8 x uint32_t: the propname block of NAKA class Viewable (Class table slot 0x160, entry 16, its +20)
; One pointer per letter of its propdata "M[[[[]P" -- "class", "super", "sub", "next", "prev", "flag", "rect", then one to ""; the names follow in
; ClassProps_Viewable_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_Viewable:	.incbin "includes/generated/naka_disk_warning.bin", 0x338A, 0x20
; ClassProps_Viewable_Names -- 42 x char: the field names of class Viewable, in reverse field order: "", "rect", "flag", "prev", "next", "sub", "super", "class"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_Viewable points at each one.
ClassProps_Viewable_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x33AA, 0x2A
; ClassProps_VwBox -- 4 x uint32_t: the propname block of NAKA class VwBox (Class table slot 0x160, entry 17, its +20)
; One pointer per letter of its propdata "^_A" -- "color", "border", "index", then one to ""; the names follow in
; ClassProps_VwBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_VwBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x33D4, 0x10
; ClassProps_VwBox_Names -- 22 x char: the field names of class VwBox, in reverse field order: "", "index", "border", "color"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_VwBox points at each one.
ClassProps_VwBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x33E4, 0x16
; ClassProps_PsParaBox -- 4 x uint32_t: the propname block of NAKA class PsParaBox (Class table slot 0x160, entry 18, its +20)
; One pointer per letter of its propdata "c^d" -- "font", "fontcolor", "align", then one to ""; the names follow in
; ClassProps_PsParaBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_PsParaBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x33FA, 0x10
; ClassProps_PsParaBox_Names -- 24 x char: the field names of class PsParaBox, in reverse field order: "", "align", "fontcolor", "font"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_PsParaBox points at each one.
ClassProps_PsParaBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x340A, 0x18
; ClassProps_AcLswBox -- 3 x uint32_t: the propname block of NAKA class AcLswBox (Class table slot 0x160, entry 19, its +20)
; One pointer per letter of its propdata "jn" -- "func", "data", then one to ""; the names follow in
; ClassProps_AcLswBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_AcLswBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x3422, 0xC
; ClassProps_AcLswBox_Names -- 14 x char: the field names of class AcLswBox, in reverse field order: "", "data", "func"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_AcLswBox points at each one.
ClassProps_AcLswBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x342E, 0xE
; ClassProps_AcTempoBox -- 1 x uint32_t: the propname block of NAKA class AcTempoBox (Class table slot 0x160, entry 20, its +20)
; One pointer per letter of its propdata "" (no own fields), then one to ""; the names follow in
; ClassProps_AcTempoBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_AcTempoBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x343C, 0x4
; ClassProps_AcTempoBox_Names -- 2 x char: the field names of class AcTempoBox, in reverse field order: ""
; NUL-terminated, 0xFF pads each to an even length; ClassProps_AcTempoBox points at each one.
ClassProps_AcTempoBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3440, 0x2
; ClassProps_PsEditBox -- 9 x uint32_t: the propname block of NAKA class PsEditBox (Class table slot 0x160, entry 21, its +20)
; One pointer per letter of its propdata "Xc^dBeGm" -- "caption", "font", "fontcolor", "align", "length", "editsw", "dial", "selected", then one to ""; the names follow in
; ClassProps_PsEditBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_PsEditBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x3442, 0x24
; ClassProps_PsEditBox_Names -- 64 x char: the field names of class PsEditBox, in reverse field order: "", "selected", "dial", "editsw", "length", "align", "fontcolor", "font", "caption"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_PsEditBox points at each one.
ClassProps_PsEditBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x3466, 0x40
; ClassProps_PsNumEditBox -- 2 x uint32_t: the propname block of NAKA class PsNumEditBox (Class table slot 0x160, entry 22, its +20)
; One pointer per letter of its propdata "A" -- "figures", then one to ""; the names follow in
; ClassProps_PsNumEditBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_PsNumEditBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x34A6, 0x8
; ClassProps_PsNumEditBox_Names -- 10 x char: the field names of class PsNumEditBox, in reverse field order: "", "figures"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_PsNumEditBox points at each one.
ClassProps_PsNumEditBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x34AE, 0xA
; ClassProps_PsTblEditBox -- 2 x uint32_t: the propname block of NAKA class PsTblEditBox (Class table slot 0x160, entry 23, its +20)
; One pointer per letter of its propdata "j" -- "func", then one to ""; the names follow in
; ClassProps_PsTblEditBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_PsTblEditBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x34B8, 0x8
; ClassProps_PsTblEditBox_Names -- 8 x char: the field names of class PsTblEditBox, in reverse field order: "", "func"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_PsTblEditBox points at each one.
ClassProps_PsTblEditBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x34C0, 0x8
; ClassProps_AcOnOffBox -- 2 x uint32_t: the propname block of NAKA class AcOnOffBox (Class table slot 0x160, entry 24, its +20)
; One pointer per letter of its propdata "m" -- "onoff", then one to ""; the names follow in
; ClassProps_AcOnOffBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_AcOnOffBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x34C8, 0x8
; ClassProps_AcOnOffBox_Names -- 8 x char: the field names of class AcOnOffBox, in reverse field order: "", "onoff"
; NUL-terminated, 0xFF pads each to an even length; ClassProps_AcOnOffBox points at each one.
ClassProps_AcOnOffBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x34D0, 0x8
; ClassProps_AcNumEditBox -- 7 x uint32_t: the propname block of NAKA class AcNumEditBox (Class table slot 0x160, entry 25, its +20)
; One pointer per letter of its propdata "nAAAAA" -- "num", "figures", "max", "min", "largestep", "smallstep", then one to ""; the names follow in
; ClassProps_AcNumEditBox_Names. ClassProc copies entry [i] (`add xwa, (xbc + 20)`) when it lists a class's fields.
ClassProps_AcNumEditBox:	.incbin "includes/generated/naka_disk_warning.bin", 0x34D8, 0x1C
; ClassProps_AcNumEditBox_Names -- 26 x char: the first 4 of the 7 names of class AcNumEditBox, in reverse field order: "", "smallstep", "largestep", "min"
; NUL-terminated, 0xFF pads to even length. The rest ("max", "figures", "num") continue at WidgetPropStr_Max
; and NakaClass_AcNumEditBox_PropNameTextEnd; ClassProps_AcNumEditBox points at all of them.
ClassProps_AcNumEditBox_Names:	.incbin "includes/generated/naka_disk_warning.bin", 0x34F4, 0x1A
WidgetPropStr_Max:		.incbin "includes/generated/naka_disk_warning.bin", 0x350E, 0x4
; NakaClass_AcNumEditBox_PropNameTextEnd -- 12 x char: "figures", "num", the last two property names of class AcNumEditBox
; (0x1600019); entries 1 and 0 of its name list (Class descriptor +20, just before this slice) point here.
NakaClass_AcNumEditBox_PropNameTextEnd:	.incbin "includes/generated/naka_disk_warning.bin", 0x3512, 0xC
; NakaClass_AcLswEditBox_PropNames -- 3 x u32: name pointers of class AcLswEditBox (0x160001a)'s own properties, one per letter of its propdata "jn":
; "func", "data", ended by "". +20 (propname) of entry 26 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcLswEditBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x351E, 0xC
; NakaClass_AcLswEditBox_PropNameText -- 14 x char: the property-name strings NakaClass_AcLswEditBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcLswEditBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x352A, 0xE
; NakaClass_AcRamEditBox_PropNames -- 3 x u32: name pointers of class AcRamEditBox (0x160001b)'s own properties, one per letter of its propdata "jr":
; "func", "data", ended by "". +20 (propname) of entry 27 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcRamEditBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3538, 0xC
; NakaClass_AcRamEditBox_PropNameText -- 14 x char: the property-name strings NakaClass_AcRamEditBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcRamEditBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3544, 0xE
; NakaClass_PsMenuBox_PropNames -- 6 x u32: name pointers of class PsMenuBox (0x160001c)'s own properties, one per letter of its propdata "c^dem":
; "font", "fontcolor", "align", "editsw", "selected", ended by "". +20 (propname) of entry 28 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsMenuBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3552, 0x18
; NakaClass_PsMenuBox_PropNameText -- 42 x char: the property-name strings NakaClass_PsMenuBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsMenuBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x356A, 0x2A
; NakaClass_AcTitleMenu_PropNames -- 4 x u32: name pointers of class AcTitleMenu (0x160001d)'s own properties, one per letter of its propdata "Xab":
; "str", "title", "icon", ended by "". +20 (propname) of entry 29 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcTitleMenu_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3594, 0x10
; NakaClass_AcTitleMenu_PropNameText -- 18 x char: the property-name strings NakaClass_AcTitleMenu_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcTitleMenu_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x35A4, 0x12
; NakaClass_PsEditSwBox_PropNames -- 5 x u32: name pointers of class PsEditSwBox (0x160001e)'s own properties, one per letter of its propdata "c^de":
; "font", "fontcolor", "align", "editsw", ended by "". +20 (propname) of entry 30 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsEditSwBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x35B6, 0x14
; NakaClass_PsEditSwBox_PropNameText -- 32 x char: the property-name strings NakaClass_PsEditSwBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsEditSwBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x35CA, 0x20
; NakaClass_AcIndexEditSw_PropNames -- 2 x u32: name pointers of class AcIndexEditSw (0x160001f)'s own properties, one per letter of its propdata "f":
; "style", ended by "". +20 (propname) of entry 31 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcIndexEditSw_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x35EA, 0x8
; NakaClass_AcIndexEditSw_PropNameText -- 8 x char: the property-name strings NakaClass_AcIndexEditSw_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcIndexEditSw_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x35F2, 0x8
; NakaClass_AcFuncEditSw_PropNames -- 3 x u32: name pointers of class AcFuncEditSw (0x1600020)'s own properties, one per letter of its propdata "fj":
; "style", "func", ended by "". +20 (propname) of entry 32 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcFuncEditSw_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x35FA, 0xC
; NakaClass_AcFuncEditSw_PropNameText -- 14 x char: the property-name strings NakaClass_AcFuncEditSw_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcFuncEditSw_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3606, 0xE
; NakaClass_PsWideESBox_PropNames -- 2 x u32: name pointers of class PsWideESBox (0x1600021)'s own properties, one per letter of its propdata "e":
; "editsw2", ended by "". +20 (propname) of entry 33 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsWideESBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3614, 0x8
; NakaClass_PsWideESBox_PropNameText -- 10 x char: the property-name strings NakaClass_PsWideESBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsWideESBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x361C, 0xA
; NakaClass_AcIndexWideES_PropNames -- 2 x u32: name pointers of class AcIndexWideES (0x1600022)'s own properties, one per letter of its propdata "f":
; "style", ended by "". +20 (propname) of entry 34 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcIndexWideES_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3626, 0x8
; NakaClass_AcIndexWideES_PropNameText -- 8 x char: the property-name strings NakaClass_AcIndexWideES_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcIndexWideES_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x362E, 0x8
; NakaClass_AcFuncWideES_PropNames -- 3 x u32: name pointers of class AcFuncWideES (0x1600023)'s own properties, one per letter of its propdata "fj":
; "style", "func", ended by "". +20 (propname) of entry 35 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcFuncWideES_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3636, 0xC
; NakaClass_AcFuncWideES_PropNameText -- 14 x char: the property-name strings NakaClass_AcFuncWideES_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcFuncWideES_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3642, 0xE
; NakaClass_PsPageBox_PropNames -- 2 x u32: name pointers of class PsPageBox (0x1600024)'s own properties, one per letter of its propdata "n":
; "page", ended by "". +20 (propname) of entry 36 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsPageBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3650, 0x8
; NakaClass_PsPageBox_PropNameText -- 8 x char: the property-name strings NakaClass_PsPageBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsPageBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3658, 0x8
; NakaClass_AcWindowPage_PropNames -- 3 x u32: name pointers of class AcWindowPage (0x1600025)'s own properties, one per letter of its propdata "AA":
; "pagemin", "pagemax", ended by "". +20 (propname) of entry 37 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcWindowPage_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3660, 0xC
; NakaClass_AcWindowPage_PropNameText -- 18 x char: the property-name strings NakaClass_AcWindowPage_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcWindowPage_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x366C, 0x12
; NakaClass_PsToggleBox_PropNames -- 6 x u32: name pointers of class PsToggleBox (0x1600026)'s own properties, one per letter of its propdata "cXXme":
; "font", "stron", "stroff", "onoff", "editsw", ended by "". +20 (propname) of entry 38 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsToggleBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x367E, 0x18
; NakaClass_PsToggleBox_PropNameText -- 36 x char: the property-name strings NakaClass_PsToggleBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsToggleBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3696, 0x24
; NakaClass_PsInvisibleBox_PropNames -- 1 x u32: name pointers of class PsInvisibleBox (0x1600027)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 39 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsInvisibleBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x36BA, 0x4
; NakaClass_PsInvisibleBox_PropNameText -- 2 x char: the property-name strings NakaClass_PsInvisibleBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsInvisibleBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x36BE, 0x2
; NakaClass_IvPageControl_PropNames -- 3 x u32: name pointers of class IvPageControl (0x1600028)'s own properties, one per letter of its propdata "At":
; "page", "window", ended by "". +20 (propname) of entry 40 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvPageControl_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x36C0, 0xC
; NakaClass_IvPageControl_PropNameText -- 16 x char: the property-name strings NakaClass_IvPageControl_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvPageControl_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x36CC, 0x10
; NakaClass_IvMainEditSw_PropNames -- 2 x u32: name pointers of class IvMainEditSw (0x1600029)'s own properties, one per letter of its propdata "k":
; "func", ended by "". +20 (propname) of entry 41 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvMainEditSw_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x36DC, 0x8
; NakaClass_IvMainEditSw_PropNameText -- 8 x char: the property-name strings NakaClass_IvMainEditSw_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvMainEditSw_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x36E4, 0x8
; NakaClass_AcSoundName_PropNames -- 2 x u32: name pointers of class AcSoundName (0x160002a)'s own properties, one per letter of its propdata "u":
; "part", ended by "". +20 (propname) of entry 42 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcSoundName_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x36EC, 0x8
; NakaClass_AcSoundName_PropNameText -- 8 x char: the property-name strings NakaClass_AcSoundName_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcSoundName_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x36F4, 0x8
; NakaClass_Label_PropNames -- 4 x u32: name pointers of class Label (0x160002b)'s own properties, one per letter of its propdata "Xc^":
; "str", "font", "fontcolor", ended by "". +20 (propname) of entry 43 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Label_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x36FC, 0x10
; NakaClass_Label_PropNameText -- 22 x char: the property-name strings NakaClass_Label_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Label_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x370C, 0x16
; NakaClass_Bitmap_PropNames -- 2 x u32: name pointers of class Bitmap (0x160002c)'s own properties, one per letter of its propdata "i":
; "bmp", ended by "". +20 (propname) of entry 44 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Bitmap_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3722, 0x8
; NakaClass_Bitmap_PropNameText -- 6 x char: the property-name strings NakaClass_Bitmap_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Bitmap_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x372A, 0x6
; NakaClass_Icon_PropNames -- 2 x u32: name pointers of class Icon (0x160002d)'s own properties, one per letter of its propdata "b":
; "icon", ended by "". +20 (propname) of entry 45 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Icon_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3730, 0x8
; NakaClass_Icon_PropNameText -- 8 x char: the property-name strings NakaClass_Icon_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Icon_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3738, 0x8
; NakaClass_Line_PropNames -- 3 x u32: name pointers of class Line (0x160002e)'s own properties, one per letter of its propdata "^g":
; "color", "linemode", ended by "". +20 (propname) of entry 46 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Line_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3740, 0xC
; NakaClass_Line_PropNameText -- 18 x char: the property-name strings NakaClass_Line_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Line_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x374C, 0x12
; NakaClass_Frame_PropNames -- 4 x u32: name pointers of class Frame (0x160002f)'s own properties, one per letter of its propdata "hA^":
; "frame", "width", "color", ended by "". +20 (propname) of entry 47 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Frame_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x375E, 0x10
; NakaClass_Frame_PropNameText -- 20 x char: the property-name strings NakaClass_Frame_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Frame_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x376E, 0x14
; NakaClass_EditSw_PropNames -- 4 x u32: name pointers of class EditSw (0x1600030)'s own properties, one per letter of its propdata "ejA":
; "editsw", "func", "index", ended by "". +20 (propname) of entry 48 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_EditSw_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3782, 0x10
; NakaClass_EditSw_PropNameText -- 22 x char: the property-name strings NakaClass_EditSw_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_EditSw_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3792, 0x16
; NakaClass_Box_PropNames -- 3 x u32: name pointers of class Box (0x1600031)'s own properties, one per letter of its propdata "^_":
; "color", "border", ended by "". +20 (propname) of entry 49 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Box_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x37A8, 0xC
; NakaClass_Box_PropNameText -- 16 x char: the property-name strings NakaClass_Box_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Box_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x37B4, 0x10
; NakaClass_GroupBox_PropNames -- 1 x u32: name pointers of class GroupBox (0x1600032)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 50 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_GroupBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x37C4, 0x4
; NakaClass_GroupBox_PropNameText -- 2 x char: the property-name strings NakaClass_GroupBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_GroupBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x37C8, 0x2
; NakaClass_Screen_PropNames -- 3 x u32: name pointers of class Screen (0x1600033)'s own properties, one per letter of its propdata "ar":
; "exit", "window", ended by "". +20 (propname) of entry 51 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Screen_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x37CA, 0xC
; NakaClass_Screen_PropNameText -- 16 x char: the property-name strings NakaClass_Screen_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Screen_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x37D6, 0x10
; NakaClass_TtlScreen_PropNames -- 3 x u32: name pointers of class TtlScreen (0x1600034)'s own properties, one per letter of its propdata "Xb":
; "title", "icon", ended by "". +20 (propname) of entry 52 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_TtlScreen_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x37E6, 0xC
; NakaClass_TtlScreen_PropNameText -- 14 x char: the property-name strings NakaClass_TtlScreen_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_TtlScreen_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x37F2, 0xE
; NakaClass_Window_PropNames -- 4 x u32: name pointers of class Window (0x1600035)'s own properties, one per letter of its propdata "Grr":
; "modal", "parent", "child", ended by "". +20 (propname) of entry 53 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_Window_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3800, 0x10
; NakaClass_Window_PropNameText -- 22 x char: the property-name strings NakaClass_Window_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_Window_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3810, 0x16
; NakaClass_TextBox_PropNames -- 6 x u32: name pointers of class TextBox (0x1600036)'s own properties, one per letter of its propdata "Xc^dB":
; "text", "font", "fontcolor", "alignment", "lines", ended by "". +20 (propname) of entry 54 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_TextBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3826, 0x18
; NakaClass_TextBox_PropNameText -- 40 x char: the property-name strings NakaClass_TextBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_TextBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x383E, 0x28
; NakaClass_StringBox_PropNames -- 5 x u32: name pointers of class StringBox (0x1600037)'s own properties, one per letter of its propdata "Xc^d":
; "str", "font", "fontcolor", "alignment", ended by "". +20 (propname) of entry 55 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_StringBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3866, 0x14
; NakaClass_StringBox_PropNameText -- 32 x char: the property-name strings NakaClass_StringBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_StringBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x387A, 0x20
; NakaClass_ModeEdit_PropNames -- 6 x u32: name pointers of class ModeEdit (0x1600038)'s own properties, one per letter of its propdata "`kalX":
; "mode", "proc", "title", "user", "name", ended by "". +20 (propname) of entry 56 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_ModeEdit_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x389A, 0x18
; NakaClass_ModeEdit_PropNameText -- 32 x char: the property-name strings NakaClass_ModeEdit_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_ModeEdit_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x38B2, 0x20
; NakaClass_TitleEdit_PropNames -- 6 x u32: name pointers of class TitleEdit (0x1600039)'s own properties, one per letter of its propdata "akNlX":
; "title", "proc", "top", "user", "name", ended by "". +20 (propname) of entry 57 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_TitleEdit_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x38D2, 0x18
; NakaClass_TitleEdit_PropNameText -- 30 x char: the property-name strings NakaClass_TitleEdit_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_TitleEdit_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x38EA, 0x1E
; NakaClass_AcRhythmName_PropNames -- 1 x u32: name pointers of class AcRhythmName (0x160003a)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 58 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcRhythmName_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3908, 0x4
; NakaClass_AcRhythmName_PropNameText -- 2 x char: the property-name strings NakaClass_AcRhythmName_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcRhythmName_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x390C, 0x2
; NakaClass_AcPmemName_PropNames -- 1 x u32: name pointers of class AcPmemName (0x160003b)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 59 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcPmemName_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x390E, 0x4
; NakaClass_AcPmemName_PropNameText -- 2 x char: the property-name strings NakaClass_AcPmemName_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcPmemName_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3912, 0x2
; NakaClass_AcMixerVol_PropNames -- 3 x u32: name pointers of class AcMixerVol (0x160003c)'s own properties, one per letter of its propdata "ue":
; "part", "editsw", ended by "". +20 (propname) of entry 60 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcMixerVol_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3914, 0xC
; NakaClass_AcMixerVol_PropNameText -- 16 x char: the property-name strings NakaClass_AcMixerVol_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcMixerVol_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3920, 0x10
; NakaClass_VwMenuBox_PropNames -- 3 x u32: name pointers of class VwMenuBox (0x160003d)'s own properties, one per letter of its propdata "Xb":
; "str", "icon", ended by "". +20 (propname) of entry 61 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_VwMenuBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3930, 0xC
; NakaClass_VwMenuBox_PropNameText -- 12 x char: the property-name strings NakaClass_VwMenuBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_VwMenuBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x393C, 0xC
; NakaClass_VwEditSwBox_PropNames -- 3 x u32: name pointers of class VwEditSwBox (0x160003e)'s own properties, one per letter of its propdata "fX":
; "style", "str", ended by "". +20 (propname) of entry 62 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_VwEditSwBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3948, 0xC
; NakaClass_VwEditSwBox_PropNameText -- 12 x char: the property-name strings NakaClass_VwEditSwBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_VwEditSwBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3954, 0xC
; NakaClass_VwWideESBox_PropNames -- 3 x u32: name pointers of class VwWideESBox (0x160003f)'s own properties, one per letter of its propdata "fX":
; "style", "str", ended by "". +20 (propname) of entry 63 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_VwWideESBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3960, 0xC
; NakaClass_VwWideESBox_PropNameText -- 12 x char: the property-name strings NakaClass_VwWideESBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_VwWideESBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x396C, 0xC
; NakaClass_AcModeMenu_PropNames -- 4 x u32: name pointers of class AcModeMenu (0x1600040)'s own properties, one per letter of its propdata "X`b":
; "str", "mode", "icon", ended by "". +20 (propname) of entry 64 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcModeMenu_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3978, 0x10
; NakaClass_AcModeMenu_PropNameText -- 18 x char: the property-name strings NakaClass_AcModeMenu_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcModeMenu_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3988, 0x12
; NakaClass_AcScreenMenu_PropNames -- 4 x u32: name pointers of class AcScreenMenu (0x1600041)'s own properties, one per letter of its propdata "XNb":
; "str", "screen", "icon", ended by "". +20 (propname) of entry 65 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcScreenMenu_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x399A, 0x10
; NakaClass_AcScreenMenu_PropNameText -- 20 x char: the property-name strings NakaClass_AcScreenMenu_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcScreenMenu_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x39AA, 0x14
; NakaClass_AcWindowMenu_PropNames -- 4 x u32: name pointers of class AcWindowMenu (0x1600042)'s own properties, one per letter of its propdata "Xtb":
; "str", "window", "icon", ended by "". +20 (propname) of entry 66 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcWindowMenu_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x39BE, 0x10
; NakaClass_AcWindowMenu_PropNameText -- 20 x char: the property-name strings NakaClass_AcWindowMenu_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcWindowMenu_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x39CE, 0x14
; NakaClass_AcBitEditBox_PropNames -- 3 x u32: name pointers of class AcBitEditBox (0x1600043)'s own properties, one per letter of its propdata "jm":
; "func", "data", ended by "". +20 (propname) of entry 67 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcBitEditBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x39E2, 0xC
; NakaClass_AcBitEditBox_PropNameText -- 14 x char: the property-name strings NakaClass_AcBitEditBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcBitEditBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x39EE, 0xE
; NakaClass_AcFuncToggle_PropNames -- 2 x u32: name pointers of class AcFuncToggle (0x1600044)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 68 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcFuncToggle_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x39FC, 0x8
; NakaClass_AcFuncToggle_PropNameText -- 8 x char: the property-name strings NakaClass_AcFuncToggle_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcFuncToggle_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A04, 0x8
; NakaClass_PsWideToggle_PropNames -- 2 x u32: name pointers of class PsWideToggle (0x1600045)'s own properties, one per letter of its propdata "e":
; "editsw2", ended by "". +20 (propname) of entry 69 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsWideToggle_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A0C, 0x8
; NakaClass_PsWideToggle_PropNameText -- 10 x char: the property-name strings NakaClass_PsWideToggle_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsWideToggle_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A14, 0xA
; NakaClass_DbMemo_PropNames -- 1 x u32: name pointers of class DbMemo (0x1600046)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 70 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_DbMemo_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A1E, 0x4
; NakaClass_DbMemo_PropNameText -- 2 x char: the property-name strings NakaClass_DbMemo_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_DbMemo_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A22, 0x2
; NakaClass_IvExit_PropNames -- 1 x u32: name pointers of class IvExit (0x1600047)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 71 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvExit_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A24, 0x4
; NakaClass_IvExit_PropNameText -- 2 x char: the property-name strings NakaClass_IvExit_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvExit_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A28, 0x2
; NakaClass_IvExitMode_PropNames -- 2 x u32: name pointers of class IvExitMode (0x1600048)'s own properties, one per letter of its propdata "`":
; "mode", ended by "". +20 (propname) of entry 72 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvExitMode_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A2A, 0x8
; NakaClass_IvExitMode_PropNameText -- 8 x char: the property-name strings NakaClass_IvExitMode_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvExitMode_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A32, 0x8
; NakaClass_IvExitScreen_PropNames -- 2 x u32: name pointers of class IvExitScreen (0x1600049)'s own properties, one per letter of its propdata "N":
; "screen", ended by "". +20 (propname) of entry 73 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvExitScreen_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A3A, 0x8
; NakaClass_IvExitScreen_PropNameText -- 10 x char: the property-name strings NakaClass_IvExitScreen_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvExitScreen_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A42, 0xA
; NakaClass_IvFixWin_PropNames -- 2 x u32: name pointers of class IvFixWin (0x160004a)'s own properties, one per letter of its propdata "t":
; "window", ended by "". +20 (propname) of entry 74 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvFixWin_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A4C, 0x8
; NakaClass_IvFixWin_PropNameText -- 10 x char: the property-name strings NakaClass_IvFixWin_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvFixWin_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A54, 0xA
; NakaClass_AcNamingWindow_PropNames -- 1 x u32: name pointers of class AcNamingWindow (0x160004b)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 75 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcNamingWindow_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A5E, 0x4
; NakaClass_AcNamingWindow_PropNameText -- 2 x char: the property-name strings NakaClass_AcNamingWindow_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcNamingWindow_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A62, 0x2
; NakaClass_PsCursorBox_PropNames -- 2 x u32: name pointers of class PsCursorBox (0x160004c)'s own properties, one per letter of its propdata "n":
; "cursor", ended by "". +20 (propname) of entry 76 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsCursorBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A64, 0x8
; NakaClass_PsCursorBox_PropNameText -- 10 x char: the property-name strings NakaClass_PsCursorBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsCursorBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A6C, 0xA
; NakaClass_IvNaming_PropNames -- 2 x u32: name pointers of class IvNaming (0x160004d)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 77 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvNaming_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A76, 0x8
; NakaClass_IvNaming_PropNameText -- 8 x char: the property-name strings NakaClass_IvNaming_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvNaming_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A7E, 0x8
; NakaClass_AcIndexToggle_PropNames -- 3 x u32: name pointers of class AcIndexToggle (0x160004e)'s own properties, one per letter of its propdata "AA":
; "index", "tag", ended by "". +20 (propname) of entry 78 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcIndexToggle_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A86, 0xC
; NakaClass_AcIndexToggle_PropNameText -- 12 x char: the property-name strings NakaClass_AcIndexToggle_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcIndexToggle_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A92, 0xC
; NakaClass_AcRamBox_PropNames -- 3 x u32: name pointers of class AcRamBox (0x160004f)'s own properties, one per letter of its propdata "jr":
; "func", "data", ended by "". +20 (propname) of entry 79 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcRamBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3A9E, 0xC
; NakaClass_AcRamBox_PropNameText -- 14 x char: the property-name strings NakaClass_AcRamBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcRamBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3AAA, 0xE
; NakaClass_PsRadioBox_PropNames -- 7 x u32: name pointers of class PsRadioBox (0x1600050)'s own properties, one per letter of its propdata "c^demA":
; "font", "fontcolor", "align", "editsw", "selected", "tag", ended by "". +20 (propname) of entry 80 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsRadioBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3AB8, 0x1C
; NakaClass_PsRadioBox_PropNameText -- 46 x char: the property-name strings NakaClass_PsRadioBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsRadioBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3AD4, 0x2E
; NakaClass_AcStrRadioBox_PropNames -- 2 x u32: name pointers of class AcStrRadioBox (0x1600051)'s own properties, one per letter of its propdata "X":
; "str", ended by "". +20 (propname) of entry 81 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcStrRadioBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B02, 0x8
; NakaClass_AcStrRadioBox_PropNameText -- 6 x char: the property-name strings NakaClass_AcStrRadioBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcStrRadioBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B0A, 0x6
; NakaClass_IvCatchEvent_PropNames -- 2 x u32: name pointers of class IvCatchEvent (0x1600052)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 82 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvCatchEvent_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B10, 0x8
; NakaClass_IvCatchEvent_PropNameText -- 8 x char: the property-name strings NakaClass_IvCatchEvent_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvCatchEvent_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B18, 0x8
; NakaClass_PsListBox_PropNames -- 6 x u32: name pointers of class PsListBox (0x1600053)'s own properties, one per letter of its propdata "c^dBn":
; "font", "fontcolor", "align", "row", "selected", ended by "". +20 (propname) of entry 83 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsListBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B20, 0x18
; NakaClass_PsListBox_PropNameText -- 38 x char: the property-name strings NakaClass_PsListBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsListBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B38, 0x26
; NakaClass_PsGridBox_PropNames -- 12 x u32: name pointers of class PsGridBox (0x1600054)'s own properties, one per letter of its propdata "c^dBBGnnsss":
; "font", "fontcolor", "align", "row", "col", "vertline", "selrow", "selcol", "pcol", "prow", "crow", ended by "". +20 (propname) of entry 84 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsGridBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B5E, 0x30
; NakaClass_PsGridBox_PropNameText -- 76 x char: the property-name strings NakaClass_PsGridBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsGridBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3B8E, 0x4C
; NakaClass_AcListBox_PropNames -- 3 x u32: name pointers of class AcListBox (0x1600055)'s own properties, one per letter of its propdata "XG":
; "list", "dial", ended by "". +20 (propname) of entry 85 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcListBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3BDA, 0xC
; NakaClass_AcListBox_PropNameText -- 14 x char: the property-name strings NakaClass_AcListBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcListBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3BE6, 0xE
; NakaClass_AcGridBox_PropNames -- 4 x u32: name pointers of class AcGridBox (0x1600056)'s own properties, one per letter of its propdata "XXj":
; "fixedcol", "fixedrow", "func", ended by "". +20 (propname) of entry 86 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcGridBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3BF4, 0x10
; NakaClass_AcGridBox_PropNameText -- 28 x char: the property-name strings NakaClass_AcGridBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcGridBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C04, 0x1C
; NakaClass_DbDebugMenu_PropNames -- 2 x u32: name pointers of class DbDebugMenu (0x1600057)'s own properties, one per letter of its propdata "n":
; "page", ended by "". +20 (propname) of entry 87 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_DbDebugMenu_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C20, 0x8
; NakaClass_DbDebugMenu_PropNameText -- 8 x char: the property-name strings NakaClass_DbDebugMenu_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_DbDebugMenu_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C28, 0x8
; NakaClass_PsTrackSwitch_PropNames -- 5 x u32: name pointers of class PsTrackSwitch (0x1600058)'s own properties, one per letter of its propdata "vmnn":
; "track", "onoff", "part", "recplay", ended by "". +20 (propname) of entry 88 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsTrackSwitch_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C30, 0x14
; NakaClass_PsTrackSwitch_PropNameText -- 28 x char: the property-name strings NakaClass_PsTrackSwitch_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsTrackSwitch_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C44, 0x1C
; NakaClass_AcTrackSwitch_PropNames -- 1 x u32: name pointers of class AcTrackSwitch (0x1600059)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 89 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcTrackSwitch_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C60, 0x4
; NakaClass_AcTrackSwitch_PropNameText -- 2 x char: the property-name strings NakaClass_AcTrackSwitch_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcTrackSwitch_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C64, 0x2
; NakaClass_IvDirmdScreen_PropNames -- 1 x u32: name pointers of class IvDirmdScreen (0x160005a)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 90 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvDirmdScreen_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C66, 0x4
; NakaClass_IvDirmdScreen_PropNameText -- 2 x char: the property-name strings NakaClass_IvDirmdScreen_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvDirmdScreen_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C6A, 0x2
; NakaClass_IvTrackSwitch_PropNames -- 1 x u32: name pointers of class IvTrackSwitch (0x160005b)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 91 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvTrackSwitch_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C6C, 0x4
; NakaClass_IvTrackSwitch_PropNameText -- 2 x char: the property-name strings NakaClass_IvTrackSwitch_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvTrackSwitch_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C70, 0x2
; NakaClass_IvExitWindow_PropNames -- 1 x u32: name pointers of class IvExitWindow (0x160005c)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 92 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvExitWindow_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C72, 0x4
; NakaClass_IvExitWindow_PropNameText -- 2 x char: the property-name strings NakaClass_IvExitWindow_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvExitWindow_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C76, 0x2
; NakaClass_DbMemoryDump_PropNames -- 2 x u32: name pointers of class DbMemoryDump (0x160005d)'s own properties, one per letter of its propdata "s":
; "adr", ended by "". +20 (propname) of entry 93 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_DbMemoryDump_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C78, 0x8
; NakaClass_DbMemoryDump_PropNameText -- 6 x char: the property-name strings NakaClass_DbMemoryDump_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_DbMemoryDump_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C80, 0x6
; NakaClass_IvInterrupt_PropNames -- 2 x u32: name pointers of class IvInterrupt (0x160005e)'s own properties, one per letter of its propdata "w":
; "time", ended by "". +20 (propname) of entry 94 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvInterrupt_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C86, 0x8
; NakaClass_IvInterrupt_PropNameText -- 8 x char: the property-name strings NakaClass_IvInterrupt_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvInterrupt_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C8E, 0x8
; NakaClass_IvIntReminder_PropNames -- 1 x u32: name pointers of class IvIntReminder (0x160005f)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 95 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntReminder_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C96, 0x4
; NakaClass_IvIntReminder_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntReminder_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntReminder_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C9A, 0x2
; NakaClass_IvIntError_PropNames -- 1 x u32: name pointers of class IvIntError (0x1600060)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 96 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntError_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3C9C, 0x4
; NakaClass_IvIntError_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntError_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntError_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CA0, 0x2
; NakaClass_IvIntComplete_PropNames -- 1 x u32: name pointers of class IvIntComplete (0x1600061)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 97 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntComplete_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CA2, 0x4
; NakaClass_IvIntComplete_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntComplete_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntComplete_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CA6, 0x2
; NakaClass_IvIntVari_PropNames -- 1 x u32: name pointers of class IvIntVari (0x1600062)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 98 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntVari_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CA8, 0x4
; NakaClass_IvIntVari_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntVari_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntVari_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CAC, 0x2
; NakaClass_IvIntEasySet_PropNames -- 1 x u32: name pointers of class IvIntEasySet (0x1600063)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 99 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntEasySet_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CAE, 0x4
; NakaClass_IvIntEasySet_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntEasySet_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntEasySet_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CB2, 0x2
; NakaClass_IvShowHide_PropNames -- 2 x u32: name pointers of class IvShowHide (0x1600064)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 100 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvShowHide_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CB4, 0x8
; NakaClass_IvShowHide_PropNameText -- 8 x char: the property-name strings NakaClass_IvShowHide_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvShowHide_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CBC, 0x8
; NakaClass_PsTextBox_PropNames -- 5 x u32: name pointers of class PsTextBox (0x1600065)'s own properties, one per letter of its propdata "c^dB":
; "font", "fontcolor", "alignment", "lines", ended by "". +20 (propname) of entry 101 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_PsTextBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CC4, 0x14
; NakaClass_PsTextBox_PropNameText -- 34 x char: the property-name strings NakaClass_PsTextBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_PsTextBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CD8, 0x22
; NakaClass_AcLanguageText_PropNames -- 2 x u32: name pointers of class AcLanguageText (0x1600066)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 102 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_AcLanguageText_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3CFA, 0x8
; NakaClass_AcLanguageText_PropNameText -- 8 x char: the property-name strings NakaClass_AcLanguageText_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_AcLanguageText_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D02, 0x8
; NakaClass_TrTransposeBox_PropNames -- 1 x u32: name pointers of class TrTransposeBox (0x1600067)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 103 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_TrTransposeBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D0A, 0x4
; NakaClass_TrTransposeBox_PropNameText -- 2 x char: the property-name strings NakaClass_TrTransposeBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_TrTransposeBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D0E, 0x2
; NakaClass_TrChordBox_PropNames -- 1 x u32: name pointers of class TrChordBox (0x1600068)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 104 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_TrChordBox_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D10, 0x4
; NakaClass_TrChordBox_PropNameText -- 2 x char: the property-name strings NakaClass_TrChordBox_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_TrChordBox_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D14, 0x2
; NakaClass_VwUserBitmap_PropNames -- 2 x u32: name pointers of class VwUserBitmap (0x1600069)'s own properties, one per letter of its propdata "j":
; "func", ended by "". +20 (propname) of entry 105 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_VwUserBitmap_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D16, 0x8
; NakaClass_VwUserBitmap_PropNameText -- 8 x char: the property-name strings NakaClass_VwUserBitmap_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_VwUserBitmap_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D1E, 0x8
; NakaClass_IvScreen_PropNames -- 1 x u32: name pointers of class IvScreen (0x160006a)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 106 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvScreen_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D26, 0x4
; NakaClass_IvScreen_PropNameText -- 2 x char: the property-name strings NakaClass_IvScreen_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvScreen_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D2A, 0x2
; NakaClass_IvIntWelcome_PropNames -- 1 x u32: name pointers of class IvIntWelcome (0x160006b)'s own properties, one per letter of its propdata "":
; no own property, ended by "". +20 (propname) of entry 107 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_IvIntWelcome_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D2C, 0x4
; NakaClass_IvIntWelcome_PropNameText -- 2 x char: the property-name strings NakaClass_IvIntWelcome_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_IvIntWelcome_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D30, 0x2
; NakaClass_VwUserBitmapByName_PropNames -- 2 x u32: name pointers of class VwUserBitmapByName (0x160006c)'s own properties, one per letter of its propdata "X":
; "file", ended by "". +20 (propname) of entry 108 of Root_ClassTable_160; ClassProc_OnGetPropNameSp reads entry [property].
NakaClass_VwUserBitmapByName_PropNames:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D32, 0x8
; NakaClass_VwUserBitmapByName_PropNameText -- 8 x char: the property-name strings NakaClass_VwUserBitmapByName_PropNames points at, "" first, each NUL-terminated and 0xff-padded to even
NakaClass_VwUserBitmapByName_PropNameText:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D3A, 0x8
; [nakarest] naka_disk_warning+0x3d42  +0x3d42..+0x402e (0xeac9ee, 748 B)
; [nakarest] the table itself: Class slot 0x160 (table 0xeac9ee, 109 entries, InitializeRoot),
; [nakarest] 109 class definitions x 24 bytes. class definition entries 0-31 of Class slot 0x160
; [nakarest] (table 0xeac9ee, 109 entries, InitializeRoot) (24 bytes each: proc, parent,
; [nakarest] allsize, selfsize, name, propdata, propname): Object, Function, ApFunction,
; [nakarest] MainFunction, Class, SupportClass, Mode, Title, ResBitmap, ResFrame, ....
Root_ClassTable_160:	.incbin "includes/generated/naka_disk_warning.bin", 0x3D42, 0x2EC
; External label offsets within the binary blob above.
