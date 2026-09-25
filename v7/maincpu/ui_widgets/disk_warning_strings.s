
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
; [nakarest] points into it; reached through 3 data words in NakaInst_WaitWinCtlSmf_0xE5C (at
; [nakarest] 0xea8c64, 0xea8c60, 0xea8c5c), which is read by DiskSure (file_io/medley.s: `lda
; [nakarest] xhl, (NakaInst_WaitWinCtlSmf_0xE5C:24)`).
DiskWarning_ConfirmStrings:
	.incbin "includes/generated/naka_disk_warning.bin", 0x0, 0x30
; [nakarest] naka_disk_warning+0x30  +0x30..+0x1c4 (0xea8cdc, 404 B)
; [nakarest] A table of 6 pointers into this piece (404 B at 0xea8cdc), then text; entry 0
; [nakarest] points at "Using DISK FORMAT will erase any current data on"; no registered NAKA
; [nakarest] table points into it; reached through source references FormatText
; [nakarest] (file_io/medley.s: `lda xhl, (DiskWarning_ConfirmStrings_0x30:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x30, 0x194
; [nakarest] naka_disk_warning+0x1c4  +0x1c4..+0x47e (0xea8e70, 698 B)
; [nakarest] A table of 6 pointers into this piece (698 B at 0xea8e70), then text; entry 0
; [nakarest] points at "Using FILE DELETE will erase the selected file c"; no registered NAKA
; [nakarest] table points into it; reached through source references DeleteText
; [nakarest] (file_io/medley.s: `lda xhl, (DiskWarning_ConfirmStrings_0x1C4:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4, 0x2BA
; [nakarest] naka_disk_warning+0x47e  +0x47e..+0x790 (0xea912a, 786 B)
; [nakarest] A table of 6 pointers into this piece (786 B at 0xea912a), then text; entry 0
; [nakarest] points at "A file already exists at the chosen location. If"; no registered NAKA
; [nakarest] table points into it; reached through source references SaveText (file_io/medley.s:
; [nakarest] `lda xhl, (DiskWarning_ConfirmStrings_0x47E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x47E, 0x312
; [nakarest] naka_disk_warning+0x790  +0x790..+0x8ac (0xea943c, 284 B)
; [nakarest] A table of 6 pointers into this piece (284 B at 0xea943c), then text; entry 0
; [nakarest] points at "When a disk is inserted open this page."; no registered NAKA table
; [nakarest] points into it; reached through source references InsertOptionText
; [nakarest] (file_io/medley.s: `lda xhl, (DiskWarning_ConfirmStrings_0x790:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x790, 0x11C
; [nakarest] naka_disk_warning+0x8ac  +0x8ac..+0xa38 (0xea9558, 396 B)
; [nakarest] A table of 6 pointers into this piece (396 B at 0xea9558), then text; entry 0
; [nakarest] points at "When a disk contains Technics & SMF files."; no registered NAKA table
; [nakarest] points into it; reached through source references TypePriorityText
; [nakarest] (file_io/medley.s: `lda xhl, (DiskWarning_ConfirmStrings_0x8AC:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x8AC, 0x18C
; [nakarest] naka_disk_warning+0xa38  +0xa38..+0xb46 (0xea96e4, 270 B)
; [nakarest] Text (270 B at 0xea96e4), first string " "; no registered NAKA table points into
; [nakarest] it; reached through source references JumpInsertFunc (file_io/misc_ui.s: `add xbc,
; [nakarest] DiskWarning_ConfirmStrings_0xA38`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xA38, 0x10E
; [nakarest] naka_disk_warning+0xb46  +0xb46..+0xcba (0xea97f2, 372 B)
; [nakarest] purpose not established: layout of 372 B at 0xea97f2 not derived; readers below
; [nakarest] Readers: source references AcFileSfx_DrawLoop (ui/ui_control_panel.s: `lda xhl,
; [nakarest] (DiskWarning_ConfirmStrings_0xB46:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xB46, 0x174
; [nakarest] naka_disk_warning+0xcba  +0xcba..+0xd4c (0xea9966, 146 B)
; [nakarest] purpose not established: layout of 146 B at 0xea9966 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_CheckButtonRelease
; [nakarest] (boot/main_title_ctrl_panel.s: `ld xbc, DiskWarning_ConfirmStrings_0xCBA`),
; [nakarest] CtrlPanel_CheckDiskMenuRelease (boot/main_title_ctrl_panel.s: `ld xbc,
; [nakarest] DiskWarning_ConfirmStrings_0xCBA`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xCBA, 0x92
; [nakarest] naka_disk_warning+0xd4c  +0xd4c..+0xd58 (0xea99f8, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea99f8 not derived; readers below
; [nakarest] Readers: source references MainPmanControl (ui/ui_control_panel.s: `add xwa,
; [nakarest] DiskWarning_ConfirmStrings_0xD4C`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xD4C, 0xC
; [nakarest] naka_disk_warning+0xd58  +0xd58..+0xdae (0xea9a04, 86 B)
; [nakarest] purpose not established: layout of 86 B at 0xea9a04 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_DispatchByIndex (ui/ui_control_panel.s: `lda
; [nakarest] xix, (DiskWarning_ConfirmStrings_0xD58:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xD58, 0x56
; [nakarest] naka_disk_warning+0xdae  +0xdae..+0xe2e (0xea9a5a, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xea9a5a not derived; readers below
; [nakarest] Readers: source references GroupBox_HandleStateCompare (ui/ui_control_panel.s: `lda
; [nakarest] xwa, (DiskWarning_ConfirmStrings_0xDAE:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xDAE, 0x80
; [nakarest] naka_disk_warning+0xe2e  +0xe2e..+0xe56 (0xea9ada, 40 B)
; [nakarest] purpose not established: layout of 40 B at 0xea9ada not derived; readers below
; [nakarest] Readers: source references CtrlPanel_FuncDispatch (ui/ui_control_panel.s: `add xwa,
; [nakarest] DiskWarning_ConfirmStrings_0xE2E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xE2E, 0x28
; [nakarest] naka_disk_warning+0xe56  +0xe56..+0xe70 (0xea9b02, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xea9b02 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_FuncDispatch (ui/ui_control_panel.s: `ld xix,
; [nakarest] DiskWarning_ConfirmStrings_0xE56`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xE56, 0x1A
; [nakarest] naka_disk_warning+0xe70  +0xe70..+0xe8a (0xea9b1c, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xea9b1c not derived; readers below
; [nakarest] Readers: source references GetEditSwPoint (audio/presentation_sound_nav.s: `lda
; [nakarest] xix, (DiskWarning_ConfirmStrings_0xE70:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xE70, 0x1A
; [nakarest] naka_disk_warning+0xe8a  +0xe8a..+0xe96 (0xea9b36, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9b36 not derived; readers below
; [nakarest] Readers: source references SetWallPaper (audio/presentation_sound_nav.s: `lda xix,
; [nakarest] (DiskWarning_ConfirmStrings_0xE8A:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xE8A, 0xC
; [nakarest] naka_disk_warning+0xe96  +0xe96..+0xeb4 (0xea9b42, 30 B)
; [nakarest] purpose not established: layout of 30 B at 0xea9b42 not derived; readers below
; [nakarest] Readers: source references IvDirmdScreenProc (audio/presentation_sound_nav.s: `add
; [nakarest] xbc, DiskWarning_ConfirmStrings_0xE96`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xE96, 0x1E
; [nakarest] naka_disk_warning+0xeb4  +0xeb4..+0xf12 (0xea9b60, 94 B)
; [nakarest] A table of 4 pointers (94 B at 0xea9b60), then text; entry 0 points at
; [nakarest] "\xC1\x9C\x8C!\xC1\x9D\x8C\xF1f0\xFF"; no registered NAKA table points into it;
; [nakarest] reached through source references DirmdTitleFunc (audio/presentation_sound_nav.s:
; [nakarest] `ld xiy, DiskWarning_ConfirmStrings_0xEB4`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xEB4, 0x5E
; [nakarest] naka_disk_warning+0xf12  +0xf12..+0xf32 (0xea9bbe, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xea9bbe not derived; readers below
; [nakarest] Readers: source references DirmdEmulator (audio/presentation_sound_nav.s: `add xbc,
; [nakarest] DiskWarning_ConfirmStrings_0xF12`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xF12, 0x20
; [nakarest] naka_disk_warning+0xf32  +0xf32..+0xf46 (0xea9bde, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xea9bde not derived; readers below
; [nakarest] Readers: source references WindowProc (audio/presentation_sound_nav.s: `add xbc,
; [nakarest] DiskWarning_ConfirmStrings_0xF32`).
	.incbin "includes/generated/naka_disk_warning.bin", 0xF32, 0x14
; [nakarest] naka_disk_warning+0xf46  +0xf46..+0x1154 (0xea9bf2, 526 B)
; [nakarest] purpose not established: layout of 526 B at 0xea9bf2 not derived; readers below
; [nakarest] Readers: source references WndScroll_SendSelectionEvents (ui/ui_window_procs.s: `ld
; [nakarest] xbc, DiskWarning_ConfirmStrings_0xF46`); 2 data words in
; [nakarest] Data_SoundEditorCharsLayout (at 0xea9ed2, 0xea9ed6), which is read by
; [nakarest] WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), 3 more.
	.incbin "includes/generated/naka_disk_warning.bin", 0xF46, 0x20E
; [nakarest] naka_disk_warning+0x1154  +0x1154..+0x1226 (0xea9e00, 210 B)
; [nakarest] purpose not established: layout of 210 B at 0xea9e00 not derived; readers below
; [nakarest] Readers: source references WndScroll_SearchCharTable (ui/ui_window_procs.s: `lda
; [nakarest] xwa, (DiskWarning_ConfirmStrings_0x1154:24)`); 1 data word in
; [nakarest] Data_SoundEditorCharsLayout (at 0xea9eda), which is read by
; [nakarest] WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), 3 more.
	.incbin "includes/generated/naka_disk_warning.bin", 0x1154, 0xD2
; [nakarest] Data_SoundEditorCharsLayout  +0x1226..+0x1232 (0xea9ed2, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9ed2 not derived; readers below
; [nakarest] Readers: source references WndEvt_EventCodeDispatch (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout`), WndScroll_ClampPageCount
; [nakarest] (ui/ui_window_procs.s: `ld xbc, Data_SoundEditorCharsLayout`),
; [nakarest] WndScroll_HandleSelectionChange (ui/ui_window_procs.s: `ld
; [nakarest] XBC,Data_SoundEditorCharsLayout`), 1 more.
Data_SoundEditorCharsLayout:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1226, 0xC
; [nakarest] naka_disk_warning+0x1232  +0x1232..+0x123e (0xea9ede, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9ede not derived; readers below
; [nakarest] Readers: source references WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s: `ld
; [nakarest] xbc, Data_SoundEditorCharsLayout_0xC`), WndEvt_EventCodeDispatch_Skip2
; [nakarest] (ui/ui_window_procs.s: `lda xde, (Data_SoundEditorCharsLayout_0xC:24)`),
; [nakarest] WndScroll_CheckTableEnd (ui/ui_window_procs.s: `ld xbc,
; [nakarest] Data_SoundEditorCharsLayout_0xC`), WndScroll_HandleDialPage (ui/ui_window_procs.s:
; [nakarest] `ld xwa, Data_SoundEditorCharsLayout_0xC`), 1 more.
	.incbin "includes/generated/naka_disk_warning.bin", 0x1232, 0xC
; [nakarest] naka_disk_warning+0x123e  +0x123e..+0x124a (0xea9eea, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xea9eea not derived; readers below
; [nakarest] Readers: source references AcNaming_QueryCharSet (audio/presentation_sound_nav.s:
; [nakarest] `ld xbc, Data_SoundEditorCharsLayout_0x18`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x123E, 0xC
; [nakarest] naka_disk_warning+0x124a  +0x124a..+0x1274 (0xea9ef6, 42 B)
; [nakarest] purpose not established: layout of 42 B at 0xea9ef6 not derived; readers below
; [nakarest] Readers: source references WndEvt_DispatchByEventCode (ui/ui_window_procs.s: `add
; [nakarest] xwa, Data_SoundEditorCharsLayout_0x24`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x124A, 0x2A
; [nakarest] naka_disk_warning+0x1274  +0x1274..+0x14c6 (0xea9f20, 594 B)
; [nakarest] purpose not established: layout of 594 B at 0xea9f20 not derived; readers below
; [nakarest] Readers: source references UserBitmapCheck_ReturnTablePtr (ui/ui_window_procs.s:
; [nakarest] `lda xhl, (Data_SoundEditorCharsLayout_0x4E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1274, 0x252
; [nakarest] naka_disk_warning+0x14c6  +0x14c6..+0x14ca (0xeaa172, 4 B)
; [nakarest] Text (4 B at 0xeaa172), first string "~7f"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw (ui/ui_window_procs.s: `ld xwa,
; [nakarest] Data_SoundEditorCharsLayout_0x2A0`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x14C6, 0x4
; [nakarest] naka_disk_warning+0x14ca  +0x14ca..+0x14ce (0xeaa176, 4 B)
; [nakarest] Text (4 B at 0xeaa176), first string "~80"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw_SelectVariantA
; [nakarest] (ui/ui_window_procs.s: `ld xwa, Data_SoundEditorCharsLayout_0x2A4`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x14CA, 0x4
; [nakarest] naka_disk_warning+0x14ce  +0x14ce..+0x159c (0xeaa17a, 206 B)
; [nakarest] Text (206 B at 0xeaa17a), first string "~81"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawEditSw_SelectVariantC
; [nakarest] (ui/ui_window_procs.s: `ld xwa, Data_SoundEditorCharsLayout_0x2A8`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x14CE, 0xCE
; [nakarest] naka_disk_warning+0x159c  +0x159c..+0x15ac (0xeaa248, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa248 not derived; readers below
; [nakarest] Readers: source references PsGridBoxProc (ui/ui_window_procs.s: `add xbc,
; [nakarest] Data_SoundEditorCharsLayout_0x376`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x159C, 0x10
; [nakarest] naka_disk_warning+0x15ac  +0x15ac..+0x15c0 (0xeaa258, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeaa258 not derived; readers below
; [nakarest] Readers: source references AcGridBoxProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Data_SoundEditorCharsLayout_0x386`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x15AC, 0x14
; [nakarest] naka_disk_warning+0x15c0  +0x15c0..+0x160e (0xeaa26c, 78 B)
; [nakarest] purpose not established: layout of 78 B at 0xeaa26c not derived; readers below
; [nakarest] Readers: source references GridCheck (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Data_SoundEditorCharsLayout_0x39A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x15C0, 0x4E
; [nakarest] naka_disk_warning+0x160e  +0x160e..+0x1636 (0xeaa2ba, 40 B)
; [nakarest] purpose not established: layout of 40 B at 0xeaa2ba not derived; readers below
; [nakarest] Readers: source references RamEditCheck (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Data_SoundEditorCharsLayout_0x3E8`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x160E, 0x28
; [nakarest] naka_disk_warning+0x1636  +0x1636..+0x163a (0xeaa2e2, 4 B)
; [nakarest] Text (4 B at 0xeaa2e2), first string "ON"; no registered NAKA table points into it;
; [nakarest] reached through source references ButtonState_Paint_Default (ui/ui_widget_defs.s:
; [nakarest] `ld xde, Data_SoundEditorCharsLayout_0x410`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1636, 0x4
; [nakarest] naka_disk_warning+0x163a  +0x163a..+0x164e (0xeaa2e6, 20 B)
; [nakarest] Text (20 B at 0xeaa2e6), first string "OFF"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_Paint_Default
; [nakarest] (ui/ui_widget_defs.s: `ld xde, Data_SoundEditorCharsLayout_0x414`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x163A, 0x14
; [nakarest] NakaInst_OK  +0x164e..+0x166a (0xeaa2fa, 28 B)
; [nakarest] purpose not established: 28 B at 0xeaa2fa that no registered NAKA table, symbol, 24/32-bit literal or data word points into
NakaInst_OK:
	.incbin "includes/generated/naka_disk_warning.bin", 0x164E, 0x1C
; [nakarest] Str_No  +0x166a..+0x166e (0xeaa316, 4 B)
; [nakarest] purpose not established: 4 B at 0xeaa316 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
Str_No:
	.incbin "includes/generated/naka_disk_warning.bin", 0x166A, 0x4
; [nakarest] naka_disk_warning+0x166e  +0x166e..+0x1690 (0xeaa31a, 34 B)
; [nakarest] purpose not established: layout of 34 B at 0xeaa31a not derived; readers below
; [nakarest] Readers: source references ButtonState_DispatchDSP (ui/ui_widget_defs.s: `lda xix,
; [nakarest] (Str_No_0x4:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x166E, 0x22
; [nakarest] naka_disk_warning+0x1690  +0x1690..+0x16a2 (0xeaa33c, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xeaa33c not derived; readers below
; [nakarest] Readers: source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `lda xix,
; [nakarest] (Str_No_0x26:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1690, 0x12
; [nakarest] naka_disk_warning+0x16a2  +0x16a2..+0x16d8 (0xeaa34e, 54 B)
; [nakarest] Text (54 B at 0xeaa34e), first string ""; no registered NAKA table points into it;
; [nakarest] reached through source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `ld
; [nakarest] xix, Str_No_0x38`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x16A2, 0x36
; [nakarest] naka_disk_warning+0x16d8  +0x16d8..+0x16de (0xeaa384, 6 B)
; [nakarest] Text (6 B at 0xeaa384), first string "FWin"; no registered NAKA table points into
; [nakarest] it; reached through source references IvFixWin_Paint (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x6E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x16D8, 0x6
; [nakarest] naka_disk_warning+0x16de  +0x16de..+0x16e4 (0xeaa38a, 6 B)
; [nakarest] Text (6 B at 0xeaa38a), first string "Name"; no registered NAKA table points into
; [nakarest] it; reached through source references IvNaming_Paint (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x74`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x16DE, 0x6
; [nakarest] naka_disk_warning+0x16e4  +0x16e4..+0x16ea (0xeaa390, 6 B)
; [nakarest] Text (6 B at 0xeaa390), first string "TrSw"; no registered NAKA table points into
; [nakarest] it; reached through source references IvTrackSwitch_Paint (ui/ui_widget_defs.s: `ld
; [nakarest] xde, Str_No_0x7A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x16E4, 0x6
; [nakarest] naka_disk_warning+0x16ea  +0x16ea..+0x171a (0xeaa396, 48 B)
; [nakarest] Text (48 B at 0xeaa396), first string "CcEv"; no registered NAKA table points into
; [nakarest] it; reached through source references DefaultClass_Paint (ui/ui_widget_defs.s: `ld
; [nakarest] xde, Str_No_0x80`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x16EA, 0x30
; [nakarest] naka_disk_warning+0x171a  +0x171a..+0x175e (0xeaa3c6, 68 B)
; [nakarest] Text (68 B at 0xeaa3c6), first string "Show"; no registered NAKA table points into
; [nakarest] it; reached through source references IvShowHideProc (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0xB0`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x171A, 0x44
; [nakarest] naka_disk_warning+0x175e  +0x175e..+0x1860 (0xeaa40a, 258 B)
; [nakarest] purpose not established: layout of 258 B at 0xeaa40a not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Paint (ui/ui_widget_defs.s: `ld xhl,
; [nakarest] Str_No_0xF4`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x175E, 0x102
; [nakarest] naka_disk_warning+0x1860  +0x1860..+0x1864 (0xeaa50c, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaa50c not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Confirm (ui/ui_widget_defs.s: `ld
; [nakarest] XWA,Str_No_0x1F6`), AcMixerVol_FastScroll (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x1F6`), AcMixerVol_FastScroll_Increment (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x1F6`), AcMixerVol_OK (ui/ui_widget_defs.s: `ld XBC,Str_No_0x1F6`), 3 more.
	.incbin "includes/generated/naka_disk_warning.bin", 0x1860, 0x4
; [nakarest] naka_disk_warning+0x1864  +0x1864..+0x1978 (0xeaa510, 276 B)
; [nakarest] purpose not established: layout of 276 B at 0xeaa510 not derived; readers below
; [nakarest] Readers: source references AcMixerVol_Confirm (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x1FA:24)`), AcMixerVol_OK (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x1FA:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1864, 0x114
; [nakarest] naka_disk_warning+0x1978  +0x1978..+0x1a0e (0xeaa624, 150 B)
; [nakarest] purpose not established: layout of 150 B at 0xeaa624 not derived; readers below
; [nakarest] Readers: source references AcMixerVol_PartSelect_DrawIcon (ui/ui_widget_defs.s:
; [nakarest] `lda xde, (Str_No_0x30E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1978, 0x96
; [nakarest] naka_disk_warning+0x1a0e  +0x1a0e..+0x1a4e (0xeaa6ba, 64 B)
; [nakarest] Text (64 B at 0xeaa6ba), first string "Debug Time!"; no registered NAKA table
; [nakarest] points into it; reached through source references DbMemo_Paint
; [nakarest] (ui/ui_widget_defs.s: `ld xde, Str_No_0x3A4`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A0E, 0x40
; [nakarest] naka_disk_warning+0x1a4e  +0x1a4e..+0x1a66 (0xeaa6fa, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xeaa6fa not derived; readers below
; [nakarest] Readers: source references DbMemDump_OK (ui/ui_widget_defs.s: `add xwa,
; [nakarest] DbMemDump_StepTable`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A4E, 0x18
; [nakarest] naka_disk_warning+0x1a66  +0x1a66..+0x1a98 (0xeaa712, 50 B)
; [nakarest] purpose not established: layout of 50 B at 0xeaa712 not derived; readers below
; [nakarest] Readers: source references DbDebugMenu_Confirm (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (Str_No_0x3FC:24)`), DbDebugMenu_OK_Advance (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (Str_No_0x3FC:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A66, 0x32
; [nakarest] naka_disk_warning+0x1a98  +0x1a98..+0x1aa4 (0xeaa744, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa744 not derived; readers below
; [nakarest] Readers: source references DbDebugMenu_Close (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (Str_No_0x42E:24)`), DbDebugMenu_Init (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (Str_No_0x42E:24)`), DbDebugMenu_OK (ui/ui_widget_defs.s: `lda xde,
; [nakarest] (Str_No_0x42E:24)`), DbDebugMenu_OK_CheckValid (ui/ui_widget_defs.s: `lda xbc,
; [nakarest] (Str_No_0x42E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1A98, 0xC
; [nakarest] naka_disk_warning+0x1aa4  +0x1aa4..+0x1b44 (0xeaa750, 160 B)
; [nakarest] purpose not established: layout of 160 B at 0xeaa750 not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] Str_No_0x43A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1AA4, 0xA0
; [nakarest] naka_disk_warning+0x1b44  +0x1b44..+0x1b6e (0xeaa7f0, 42 B)
; [nakarest] purpose not established: layout of 42 B at 0xeaa7f0 not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] Str_No_0x4DA`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B44, 0x2A
; [nakarest] naka_disk_warning+0x1b6e  +0x1b6e..+0x1b7e (0xeaa81a, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa81a not derived; readers below
; [nakarest] Readers: source references PsTrackSwitchProc (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] Str_No_0x504`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B6E, 0x10
; [nakarest] naka_disk_warning+0x1b7e  +0x1b7e..+0x1b88 (0xeaa82a, 10 B)
; [nakarest] Text (10 B at 0xeaa82a), first string "PsTextBox"; no registered NAKA table points
; [nakarest] into it; reached through source references AcTrkSw_Select_HighTrack
; [nakarest] (ui/ui_widget_defs.s: `lda xhl, (Str_No_0x514:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B7E, 0xA
; [nakarest] naka_disk_warning+0x1b88  +0x1b88..+0x1b98 (0xeaa834, 16 B)
; [nakarest] Text (16 B at 0xeaa834), first string "AcLanguageText"; no registered NAKA table
; [nakarest] points into it; reached through source references AcTrkSw_ShowHide_CheckDirty
; [nakarest] (ui/ui_widget_defs.s: `lda xhl, (Str_No_0x51E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B88, 0x10
; [nakarest] naka_disk_warning+0x1b98  +0x1b98..+0x1bf8 (0xeaa844, 96 B)
; [nakarest] purpose not established: layout of 96 B at 0xeaa844 not derived; readers below
; [nakarest] Readers: source references LanguageCheck (ui/ui_widget_defs.s: `lda xhl,
; [nakarest] (Str_No_0x52E:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1B98, 0x60
; [nakarest] naka_disk_warning+0x1bf8  +0x1bf8..+0x1c20 (0xeaa8a4, 40 B)
; [nakarest] purpose not established: layout of 40 B at 0xeaa8a4 not derived; readers below
; [nakarest] Readers: source references ObjectProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Str_No_0x58E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1BF8, 0x28
; [nakarest] naka_disk_warning+0x1c20  +0x1c20..+0x1c30 (0xeaa8cc, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa8cc not derived; readers below
; [nakarest] Readers: source references ExitWindow_Confirm (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] Str_No_0x5B6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C20, 0x10
; [nakarest] naka_disk_warning+0x1c30  +0x1c30..+0x1c48 (0xeaa8dc, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xeaa8dc not derived; readers below
; [nakarest] Readers: source references ExitWindow_OK (ui/ui_widget_defs.s: `ld xiy,
; [nakarest] Str_No_0x5C6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C30, 0x18
; [nakarest] naka_disk_warning+0x1c48  +0x1c48..+0x1c4a (0xeaa8f4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa8f4 not derived; readers below
; [nakarest] Readers: source references InputDialog_Confirm (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x5DE:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C48, 0x2
; [nakarest] naka_disk_warning+0x1c4a  +0x1c4a..+0x1c4c (0xeaa8f6, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeaa8f6 not derived; readers below
; [nakarest] Readers: source references UnRegisterObject (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x5E0:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4A, 0x2
; [nakarest] naka_disk_warning+0x1c4c  +0x1c4c..+0x1c5c (0xeaa8f8, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeaa8f8 not derived; readers below
; [nakarest] Readers: source references ClassProc (ui/ui_widget_defs.s: `add xbc,
; [nakarest] Str_No_0x5E2`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C4C, 0x10
; [nakarest] naka_disk_warning+0x1c5c  +0x1c5c..+0x1c68 (0xeaa908, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa908 not derived; readers below
; [nakarest] Readers: source references ModeProc (ui/ui_widget_defs.s: `add xbc, Str_No_0x5F2`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C5C, 0xC
; [nakarest] naka_disk_warning+0x1c68  +0x1c68..+0x1c6c (0xeaa914, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaa914 not derived; readers below
; [nakarest] Readers: source references UnregisteredMode (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x5FE:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C68, 0x4
; [nakarest] naka_disk_warning+0x1c6c  +0x1c6c..+0x1c70 (0xeaa918, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaa918 not derived; readers below
; [nakarest] Readers: source references EnumList_HitTest_Loop (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x602`), EnumList_OK_ScrollUp_Done (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] Str_No_0x602`), TitleProc (ui/ui_widget_defs.s: `ld xbc, Str_No_0x602`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C6C, 0x4
; [nakarest] naka_disk_warning+0x1c70  +0x1c70..+0x1d14 (0xeaa91c, 164 B)
; [nakarest] purpose not established: layout of 164 B at 0xeaa91c not derived; readers below
; [nakarest] Readers: source references EnumList_HitTest (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (Str_No_0x606:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1C70, 0xA4
; [nakarest] naka_disk_warning+0x1d14  +0x1d14..+0x1d20 (0xeaa9c0, 12 B)
; [nakarest] purpose not established: layout of 12 B at 0xeaa9c0 not derived; readers below
; [nakarest] Readers: source references TitleProc (ui/ui_widget_defs.s: `add xde,
; [nakarest] Str_No_0x6AA`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D14, 0xC
; [nakarest] naka_disk_warning+0x1d20  +0x1d20..+0x1d3a (0xeaa9cc, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xeaa9cc not derived; readers below
; [nakarest] Readers: source references EnumList_Reset (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] Str_No_0x6B6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D20, 0x1A
; [nakarest] naka_disk_warning+0x1d3a  +0x1d3a..+0x1d48 (0xeaa9e6, 14 B)
; [nakarest] purpose not established: layout of 14 B at 0xeaa9e6 not derived; readers below
; [nakarest] Readers: source references ViewableProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Str_No_0x6D0`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D3A, 0xE
; [nakarest] naka_disk_warning+0x1d48  +0x1d48..+0x1d52 (0xeaa9f4, 10 B)
; [nakarest] Text (10 B at 0xeaa9f4), first string "bool %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle7_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x6DE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D48, 0xA
; [nakarest] naka_disk_warning+0x1d52  +0x1d52..+0x1d58 (0xeaa9fe, 6 B)
; [nakarest] Text (6 B at 0xeaa9fe), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle7_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, Str_No_0x6E8`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D52, 0x6
; [nakarest] naka_disk_warning+0x1d58  +0x1d58..+0x1d64 (0xeaaa04, 12 B)
; [nakarest] Text (12 B at 0xeaaa04), first string "sword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle8_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x6EE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D58, 0xC
; [nakarest] naka_disk_warning+0x1d64  +0x1d64..+0x1d6a (0xeaaa10, 6 B)
; [nakarest] Text (6 B at 0xeaaa10), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle8_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, Str_No_0x6FA`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D64, 0x6
; [nakarest] naka_disk_warning+0x1d6a  +0x1d6a..+0x1d76 (0xeaaa16, 12 B)
; [nakarest] Text (12 B at 0xeaaa16), first string "uword %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle9_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x700`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D6A, 0xC
; [nakarest] naka_disk_warning+0x1d76  +0x1d76..+0x1d7c (0xeaaa22, 6 B)
; [nakarest] Text (6 B at 0xeaaa22), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle9_CalcWidth (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, Str_No_0x70C`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D76, 0x6
; [nakarest] naka_disk_warning+0x1d7c  +0x1d7c..+0x1d88 (0xeaaa28, 12 B)
; [nakarest] Text (12 B at 0xeaaa28), first string "schar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle10_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x712`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D7C, 0xC
; [nakarest] naka_disk_warning+0x1d88  +0x1d88..+0x1d8e (0xeaaa34, 6 B)
; [nakarest] Text (6 B at 0xeaaa34), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle10_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x71E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D88, 0x6
; [nakarest] naka_disk_warning+0x1d8e  +0x1d8e..+0x1d9a (0xeaaa3a, 12 B)
; [nakarest] Text (12 B at 0xeaaa3a), first string "uchar %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle11_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x724`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D8E, 0xC
; [nakarest] naka_disk_warning+0x1d9a  +0x1d9a..+0x1da0 (0xeaaa46, 6 B)
; [nakarest] Text (6 B at 0xeaaa46), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle11_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x730`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1D9A, 0x6
; [nakarest] naka_disk_warning+0x1da0  +0x1da0..+0x1dac (0xeaaa4c, 12 B)
; [nakarest] Text (12 B at 0xeaaa4c), first string "slong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle12_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x736`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DA0, 0xC
; [nakarest] naka_disk_warning+0x1dac  +0x1dac..+0x1db2 (0xeaaa58, 6 B)
; [nakarest] Text (6 B at 0xeaaa58), first string "&%s%d"; no registered NAKA table points into
; [nakarest] it; reached through source references BoxStyle12_CalcWidth (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x742`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DAC, 0x6
; [nakarest] naka_disk_warning+0x1db2  +0x1db2..+0x1dbe (0xeaaa5e, 12 B)
; [nakarest] Text (12 B at 0xeaaa5e), first string "ulong %s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_Setup (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x748`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DB2, 0xC
; [nakarest] naka_disk_warning+0x1dbe  +0x1dbe..+0x1ed0 (0xeaaa6a, 274 B)
; [nakarest] Text (274 B at 0xeaaa6a), first string "&%s%d"; no registered NAKA table points
; [nakarest] into it; reached through source references BoxStyle13_CalcWidth
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, Str_No_0x754`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1DBE, 0x112
; [nakarest] naka_disk_warning+0x1ed0  +0x1ed0..+0x1ed4 (0xeaab7c, 4 B)
; [nakarest] Text (4 B at 0xeaab7c), first string "%d"; no registered NAKA table points into it;
; [nakarest] reached through source references ModeID_GetCurrent (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x866`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1ED0, 0x4
; [nakarest] naka_disk_warning+0x1ed4  +0x1ed4..+0x1efc (0xeaab80, 40 B)
; [nakarest] Text (40 B at 0xeaab80), first string "MAKEMODEID(%s)"; no registered NAKA table
; [nakarest] points into it; reached through source references ModeID_GetCurrent_HasName
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, Str_No_0x86A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1ED4, 0x28
; [nakarest] naka_disk_warning+0x1efc  +0x1efc..+0x1f00 (0xeaaba8, 4 B)
; [nakarest] Text (4 B at 0xeaaba8), first string "%d"; no registered NAKA table points into it;
; [nakarest] reached through source references TitleID_GetCurrent (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x892`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1EFC, 0x4
; [nakarest] naka_disk_warning+0x1f00  +0x1f00..+0x1f20 (0xeaabac, 32 B)
; [nakarest] Text (32 B at 0xeaabac), first string "MAKETITLEID(%s)"; no registered NAKA table
; [nakarest] points into it; reached through source references TitleID_GetCurrent_HasName
; [nakarest] (ui/ui_widget_defs.s: `ld xwa, Str_No_0x896`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F00, 0x20
; [nakarest] naka_disk_warning+0x1f20  +0x1f20..+0x1f26 (0xeaabcc, 6 B)
; [nakarest] Text (6 B at 0xeaabcc), first string "name"; no registered NAKA table points into
; [nakarest] it; reached through source references NameProc_Init (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x8B6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F20, 0x6
; [nakarest] naka_disk_warning+0x1f26  +0x1f26..+0x1f2a (0xeaabd2, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaabd2 not derived; readers below
; [nakarest] Readers: source references NameProc_Init_SetPtr (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x8BC`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F26, 0x4
; [nakarest] naka_disk_warning+0x1f2a  +0x1f2a..+0x1f32 (0xeaabd6, 8 B)
; [nakarest] Text (8 B at 0xeaabd6), first string "romram"; no registered NAKA table points into
; [nakarest] it; reached through source references ConstFlagProc_GetValue (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Str_No_0x8C0`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F2A, 0x8
; [nakarest] naka_disk_warning+0x1f32  +0x1f32..+0x1f38 (0xeaabde, 6 B)
; [nakarest] purpose not established: layout of 6 B at 0xeaabde not derived; readers below
; [nakarest] Readers: source references ConstFlagProc_GetValue_Set (ui/ui_widget_defs.s: `ld
; [nakarest] xwa, Str_No_0x8C8`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F32, 0x6
; [nakarest] naka_disk_warning+0x1f38  +0x1f38..+0x1f46 (0xeaabe4, 14 B)
; [nakarest] purpose not established: layout of 14 B at 0xeaabe4 not derived; readers below
; [nakarest] Readers: source references CommonIDProc (ui/ui_widget_defs.s: `add xde,
; [nakarest] Str_No_0x8CE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F38, 0xE
; [nakarest] naka_disk_warning+0x1f46  +0x1f46..+0x214a (0xeaabf2, 516 B)
; [nakarest] purpose not established: layout of 516 B at 0xeaabf2 not derived; readers below
; [nakarest] Readers: source references DrawIcons_Impl_ColLoop (ui/drawing_primitives.s: `lda
; [nakarest] xbc, (Str_No_0x8DC:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x1F46, 0x204
; [nakarest] naka_disk_warning+0x214a  +0x214a..+0x216a (0xeaadf6, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaadf6 not derived; readers below
; [nakarest] Readers: source references DrawPartGroup_DispatchByType (ui/ui_window_procs.s: `lda
; [nakarest] xix, (Str_No_0xAE0:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x214A, 0x20
; [nakarest] naka_disk_warning+0x216a  +0x216a..+0x21b6 (0xeaae16, 76 B)
; [nakarest] purpose not established: layout of 76 B at 0xeaae16 not derived; readers below
; [nakarest] Readers: source references Draw_DispatchByPartType (ui/ui_window_procs.s: `lda xix,
; [nakarest] (Str_No_0xB00:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x216A, 0x4C
; [nakarest] naka_disk_warning+0x21b6  +0x21b6..+0x21ba (0xeaae62, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeaae62 not derived; readers below
; [nakarest] Readers: source references ChangeWall_Impl (ui/ui_window_procs.s: `ld xwa,
; [nakarest] Str_No_0xB4C`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x21B6, 0x4
; [nakarest] naka_disk_warning+0x21ba  +0x21ba..+0x2228 (0xeaae66, 110 B)
; [nakarest] purpose not established: layout of 110 B at 0xeaae66 not derived; readers below
; [nakarest] Readers: source references ChangePalette_Impl (ui/ui_window_procs.s: `lda xwa,
; [nakarest] (Str_No_0xB50:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x21BA, 0x6E
; [nakarest] naka_disk_warning+0x2228  +0x2228..+0x2248 (0xeaaed4, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaaed4 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_ByteData_Loop2
; [nakarest] (display/graphics_text_vga.s: `ld xbc, Str_No_0xBBE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2228, 0x20
; [nakarest] naka_disk_warning+0x2248  +0x2248..+0x2268 (0xeaaef4, 32 B)
; [nakarest] purpose not established: layout of 32 B at 0xeaaef4 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_ByteData_Loop3
; [nakarest] (display/graphics_text_vga.s: `.long Pad_AfterStr_No`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2248, 0x20
; [nakarest] naka_disk_warning+0x2268  +0x2268..+0x22f8 (0xeaaf14, 144 B)
; [nakarest] purpose not established: layout of 144 B at 0xeaaf14 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_ProcessEntries
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xBFE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2268, 0x90
; [nakarest] naka_disk_warning+0x22f8  +0x22f8..+0x2328 (0xeaafa4, 48 B)
; [nakarest] purpose not established: layout of 48 B at 0xeaafa4 not derived; readers below
; [nakarest] Readers: source references GraphicsRender_Start (display/graphics_text_vga.s: `ld
; [nakarest] xiy, Str_No_0xC8E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x22F8, 0x30
; [nakarest] naka_disk_warning+0x2328  +0x2328..+0x2330 (0xeaafd4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafd4 not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender (display/graphics_text_vga.s:
; [nakarest] `ld xiy, Str_No_0xCBE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2328, 0x8
; [nakarest] naka_disk_warning+0x2330  +0x2330..+0x2338 (0xeaafdc, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafdc not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xCC6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2330, 0x8
; [nakarest] naka_disk_warning+0x2338  +0x2338..+0x2340 (0xeaafe4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafe4 not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xCCE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2338, 0x8
; [nakarest] naka_disk_warning+0x2340  +0x2340..+0x2348 (0xeaafec, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaafec not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xCD6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2340, 0x8
; [nakarest] naka_disk_warning+0x2348  +0x2348..+0x2350 (0xeaaff4, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaaff4 not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xCDE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2348, 0x8
; [nakarest] naka_disk_warning+0x2350  +0x2350..+0x2358 (0xeaaffc, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeaaffc not derived; readers below
; [nakarest] Readers: source references DrawText_LayoutAndRender_Variant1_Loop
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xCE6`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2350, 0x8
; [nakarest] naka_disk_warning+0x2358  +0x2358..+0x2458 (0xeab004, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xeab004 not derived; readers below
; [nakarest] Readers: source references AccDraw_Secondary_Helper20 (display/graphics_text_vga.s:
; [nakarest] `lda xbc, (Str_No_0xCEE:24)`), DrawText_ExtLayout_NullAndDraw
; [nakarest] (display/graphics_text_vga.s: `lda xbc, (Str_No_0xCEE:24)`), Scoop_EnvelopeCalc
; [nakarest] (display/scoop_display.s: `lda xbc, (Str_No_0xCEE:24)`), Scoop_EnvelopeCalc_Data
; [nakarest] (display/scoop_display.s: `lda xbc, (Str_No_0xCEE:24)`), 1 more.
	.incbin "includes/generated/naka_disk_warning.bin", 0x2358, 0x100
; [nakarest] naka_disk_warning+0x2458  +0x2458..+0x2468 (0xeab104, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeab104 not derived; readers below
; [nakarest] Readers: source references DrawText_ExtendedLayout_Skip
; [nakarest] (display/graphics_text_vga.s: `lda xbc, (Str_No_0xDEE:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2458, 0x10
; [nakarest] naka_disk_warning+0x2468  +0x2468..+0x2470 (0xeab114, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab114 not derived; readers below
; [nakarest] Readers: source references DrawText_ExtendedLayout (display/graphics_text_vga.s:
; [nakarest] `ld xiy, Str_No_0xDFE`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2468, 0x8
; [nakarest] naka_disk_warning+0x2470  +0x2470..+0x2478 (0xeab11c, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab11c not derived; readers below
; [nakarest] Readers: source references DrawText_ExtLayout_Variant1
; [nakarest] (display/graphics_text_vga.s: `ld xiy, Str_No_0xE06`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2470, 0x8
; [nakarest] naka_disk_warning+0x2478  +0x2478..+0x2480 (0xeab124, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab124 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init (display/graphics_text_vga.s: `ld xiy,
; [nakarest] Str_No_0xE0E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2478, 0x8
; [nakarest] naka_disk_warning+0x2480  +0x2480..+0x2484 (0xeab12c, 4 B)
; [nakarest] Text (4 B at 0xeab12c), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_SkipShift
; [nakarest] (display/graphics_text_vga.s: `ld xwa, Str_No_0xE16`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2480, 0x4
; [nakarest] naka_disk_warning+0x2484  +0x2484..+0x2488 (0xeab130, 4 B)
; [nakarest] Text (4 B at 0xeab130), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_FontTable2
; [nakarest] (display/graphics_text_vga.s: `ld xwa, Str_No_0xE1A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2484, 0x4
; [nakarest] naka_disk_warning+0x2488  +0x2488..+0x24ac (0xeab134, 36 B)
; [nakarest] Text (36 B at 0xeab134), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references DrawFunc_Init_FontTable0
; [nakarest] (display/graphics_text_vga.s: `ld xwa, Str_No_0xE1E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2488, 0x24
; [nakarest] naka_disk_warning+0x24ac  +0x24ac..+0x24b4 (0xeab158, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xeab158 not derived; readers below
; [nakarest] Readers: source references AccDraw_Secondary_Helper20 (display/graphics_text_vga.s:
; [nakarest] `ld XIY,Str_No_0xE42`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x24AC, 0x8
; [nakarest] naka_disk_warning+0x24b4  +0x24b4..+0x24b8 (0xeab160, 4 B)
; [nakarest] Text (4 B at 0xeab160), first string "%1d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,Str_No_0xE4A`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x24B4, 0x4
; [nakarest] naka_disk_warning+0x24b8  +0x24b8..+0x24bc (0xeab164, 4 B)
; [nakarest] Text (4 B at 0xeab164), first string "%2d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,Str_No_0xE4E`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x24B8, 0x4
; [nakarest] naka_disk_warning+0x24bc  +0x24bc..+0x24f4 (0xeab168, 56 B)
; [nakarest] Text (56 B at 0xeab168), first string "%3d"; no registered NAKA table points into
; [nakarest] it; reached through source references AccDraw_Secondary_Helper20
; [nakarest] (display/graphics_text_vga.s: `ld XWA,Str_No_0xE52`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x24BC, 0x38
; [nakarest] Data_CharMapFormatBlock  +0x24f4..+0x2508 (0xeab1a0, 20 B)
; [nakarest] purpose not established: 20 B at 0xeab1a0 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
Data_CharMapFormatBlock:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24F4, 0x14
; [nakarest] naka_disk_warning+0x2508  +0x2508..+0x2608 (0xeab1b4, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xeab1b4 not derived; readers below
; [nakarest] Readers: source references FontGlyph_ByteData (display/graphics_text_vga.s: `lda
; [nakarest] xde, (Data_CharMapFormatBlock_0x14:24)`), TextRender_CharEncodeAndDraw
; [nakarest] (kn5000_v7_program.s: `lda xde, (0xeab1b4:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2508, 0x100
; [nakarest] naka_disk_warning+0x2608  +0x2608..+0x263c (0xeab2b4, 52 B)
; [nakarest] the table itself: ApFunction slot 0x120 (table 0xeab2b4, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_warning.bin", 0x2608, 0x34
; [nakarest] naka_disk_warning+0x263c  +0x263c..+0x2672 (0xeab2e8, 54 B)
; [nakarest] the table itself: ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_warning.bin", 0x263C, 0x36
; [nakarest] naka_disk_warning+0x2672  +0x2672..+0x271e (0xeab31e, 172 B)
; [nakarest] name strings, entries 0-11 of ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot) (names for ApFunction slot 0x120): "ApTaskControl",
; [nakarest] "CaptureLcdCheck", "UserBitmapCheck", "LanguageCheck", "GridCheck",
; [nakarest] "DefaultClassProc", ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x2672, 0xAC
; [nakarest] naka_disk_warning+0x271e  +0x271e..+0x2720 (0xeab3ca, 2 B)
; [nakarest] Text (2 B at 0xeab3ca), first string """; no registered NAKA table points into it;
; [nakarest] reached through source references DrawHelper_A_Setup (ui/ui_widget_defs.s: `ld hl,
; [nakarest] (Data_CharMapFormatBlock_0x22A:24)`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x271E, 0x2
; [nakarest] naka_disk_warning+0x2720  +0x2720..+0x31e8 (0xeab3cc, 2760 B)
; [nakarest] purpose not established: layout of 2760 B at 0xeab3cc not derived; readers below
; [nakarest] Readers: source references BitmapIDProc (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] Data_CharMapFormatBlock_0x22C`), DrawHelper_A_CalcRange (ui/ui_widget_defs.s: `ld
; [nakarest] xbc, Data_CharMapFormatBlock_0x22C`), DrawHelper_A_ReturnAlt (ui/ui_widget_defs.s:
; [nakarest] `ld xwa, Data_CharMapFormatBlock_0x22C`).
	.incbin "includes/generated/naka_disk_warning.bin", 0x2720, 0xAC8
; [nakarest] naka_disk_warning+0x31e8  +0x31e8..+0x3d42 (0xeabe94, 2906 B)
; [nakarest] propname blocks (the +20 field-name table) of classes 0-108 of Class slot 0x160
; [nakarest] (table 0xeac9ee, 109 entries, InitializeRoot): Object {}; Function {func};
; [nakarest] ApFunction {}; ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x31E8, 0xB5A
; [nakarest] naka_disk_warning+0x3d42  +0x3d42..+0x402e (0xeac9ee, 748 B)
; [nakarest] the table itself: Class slot 0x160 (table 0xeac9ee, 109 entries, InitializeRoot),
; [nakarest] 109 class definitions x 24 bytes. class definition entries 0-31 of Class slot 0x160
; [nakarest] (table 0xeac9ee, 109 entries, InitializeRoot) (24 bytes each: proc, parent,
; [nakarest] allsize, selfsize, name, propdata, propname): Object, Function, ApFunction,
; [nakarest] MainFunction, Class, SupportClass, Mode, Title, ResBitmap, ResFrame, ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x3D42, 0x2EC
; External label offsets within the binary blob above.
