
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

; [nakarest] DiskWarning_ConfirmStrings  +0x0..+0x1226 (0xea8cac, 4646 B)
; [nakarest] purpose not established: layout of 4646 B at 0xea8cac not derived; readers below
; [nakarest] Readers: source references AcFileSfx_DrawLoop (ui/ui_control_panel.s: `lda xhl,
; [nakarest] (DiskWarning_ConfirmStrings_0xB46:24)`), CtrlPanel_CheckButtonRelease
; [nakarest] (boot/main_title_ctrl_panel.s: `ld xbc, DiskWarning_ConfirmStrings_0xCBA`),
; [nakarest] CtrlPanel_CheckDiskMenuRelease (boot/main_title_ctrl_panel.s: `ld xbc,
; [nakarest] DiskWarning_ConfirmStrings_0xCBA`), CtrlPanel_DispatchByIndex
; [nakarest] (ui/ui_control_panel.s: `lda xix, (DiskWarning_ConfirmStrings_0xD58:24)`), 27 more;
; [nakarest] 3 data words in NakaInst_WaitWinCtlSmf_0xE5C (at 0xea8c64, 0xea8c60, 0xea8c5c),
; [nakarest] which is read by DiskSure (file_io/medley.s: `lda xhl,
; [nakarest] (NakaInst_WaitWinCtlSmf_0xE5C:24)`); 3 data words in Data_SoundEditorCharsLayout
; [nakarest] (at 0xea9ed2, 0xea9ed6, 0xea9eda), which is read by WndEvt_EventCodeDispatch
; [nakarest] (ui/ui_window_procs.s: `ld xde, Data_SoundEditorCharsLayout`),
; [nakarest] WndEvt_EventCodeDispatch_Join (ui/ui_window_procs.s: `ld xde,
; [nakarest] Data_SoundEditorCharsLayout`), 4 more.
DiskWarning_ConfirmStrings:
	.incbin "includes/generated/naka_disk_warning.bin", 0x0, 0x1226
; [nakarest] Data_SoundEditorCharsLayout  +0x1226..+0x164e (0xea9ed2, 1064 B)
; [nakarest] purpose not established: layout of 1064 B at 0xea9ed2 not derived; readers below
; [nakarest] Readers: source references AcGridBoxProc (ui/ui_widget_defs.s: `add xwa,
; [nakarest] Data_SoundEditorCharsLayout_0x386`), AcNaming_QueryCharSet
; [nakarest] (audio/presentation_sound_nav.s: `ld xbc, Data_SoundEditorCharsLayout_0x18`),
; [nakarest] AcOnOff_GetText (ui/ui_widget_defs.s: `ld xbc, Data_SoundEditorCharsLayout_0x3C8`),
; [nakarest] BitEditCheck (ui/ui_widget_defs.s: `lda xbc,
; [nakarest] (Data_SoundEditorCharsLayout_0x3FC:24)`), 25 more.
Data_SoundEditorCharsLayout:
	.incbin "includes/generated/naka_disk_warning.bin", 0x1226, 0x428
; [nakarest] NakaInst_OK  +0x164e..+0x166a (0xeaa2fa, 28 B)
; [nakarest] Text (28 B at 0xeaa2fa), first string "ON"; no registered NAKA table points into
; [nakarest] it; reached through source references ButtonState_DispatchDSP_InlineData
; [nakarest] (ui/ui_widget_defs.s: `.long NakaInst_OK`).
NakaInst_OK:
	.incbin "includes/generated/naka_disk_warning.bin", 0x164E, 0x1C
; [nakarest] Str_No  +0x166a..+0x24f4 (0xeaa316, 3722 B)
; [nakarest] purpose not established: layout of 3722 B at 0xeaa316 not derived; readers below
; [nakarest] Readers: source references AcIndexEdit_DispatchDSP (ui/ui_widget_defs.s: `lda xix,
; [nakarest] (Str_No_0x26:24)`), AcMixerVol_Confirm (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] Str_No_0x1F6`), AcMixerVol_FastScroll (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x1F6`), AcMixerVol_FastScroll_Increment (ui/ui_widget_defs.s: `ld xde,
; [nakarest] Str_No_0x1F6`), 112 more.
Str_No:
	.incbin "includes/generated/naka_disk_warning.bin", 0x166A, 0xE8A
; [nakarest] Data_CharMapFormatBlock  +0x24f4..+0x2608 (0xeab1a0, 276 B)
; [nakarest] purpose not established: layout of 276 B at 0xeab1a0 not derived; readers below
; [nakarest] Readers: source references DrawFunc_Init_Join6 (display/graphics_text_vga.s: `.long
; [nakarest] Data_CharMapFormatBlock`), FontGlyph_ByteData (display/graphics_text_vga.s: `lda
; [nakarest] xde, (Data_CharMapFormatBlock_0x14:24)`), TextRender_CharEncodeAndDraw
; [nakarest] (kn5000_v10_program.s: `lda xde, (0xeab1b4:24)`).
Data_CharMapFormatBlock:
	.incbin "includes/generated/naka_disk_warning.bin", 0x24F4, 0x114
; [nakarest] naka_disk_warning+0x2608  +0x2608..+0x263c (0xeab2b4, 52 B)
; [nakarest] the table itself: ApFunction slot 0x120 (table 0xeab2b4, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_warning.bin", 0x2608, 0x34
; [nakarest] naka_disk_warning+0x263c  +0x263c..+0x2672 (0xeab2e8, 54 B)
; [nakarest] the table itself: ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot), 12 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_warning.bin", 0x263C, 0x36
; [nakarest] naka_disk_warning+0x2672  +0x2672..+0x31e8 (0xeab31e, 2934 B)
; [nakarest] name strings, entries 0-11 of ApFunction slot 0x420 (table 0xeab2e8, 12 entries,
; [nakarest] InitializeRoot) (names for ApFunction slot 0x120): "ApTaskControl",
; [nakarest] "CaptureLcdCheck", "UserBitmapCheck", "LanguageCheck", "GridCheck",
; [nakarest] "DefaultClassProc", ....
	.incbin "includes/generated/naka_disk_warning.bin", 0x2672, 0xB76
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
