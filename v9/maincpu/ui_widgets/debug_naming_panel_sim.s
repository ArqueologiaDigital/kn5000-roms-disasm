
; Debug/Naming Panel Simulator screen widgets (55 widgets, 18112 bytes)
; Source: maincpu/ui_widgets/naka_debug_naming.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_debug_naming
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
; Viewable slot 0x0: RegObjTabl 0x1600010, ViewableProc, 0x33, 0xeb3374,
; 0x0 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 51, table} at 0x27ed2 +
; 14*0x0. Element 0 is named "PanelSimulator" in ResName slot 0x300.
; Links: 5 of 51 records have a disagreeing link (elements 22-26);
; elements 23-25 point outside the program ROM (RAM records).
;
; Viewable slot 0xff: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xeb3444,
; 0xff in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0xff. Element 0 is named "CheckTitle" in ResName slot 0x3ff. Links:
; all 9 records consistent.
;
; MainFunction slot 0x140: RegObjTabl 0x1600003, MainFunctionProc, 0xd,
; 0xeb3698, 0x140 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x140.
;
; ResName slot 0x300: RegObjTabl 0x160000f, ResNameProc, 0x33, 0xeb346c,
; 0x300 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 51, table} at 0x27ed2 +
; 14*0x300.
;
; ResName slot 0x3ff: RegObjTabl 0x160000f, ResNameProc, 0x9, 0xeb362a,
; 0x3ff in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x3ff.
;
; MainFunction slot 0x440: RegObjTabl 0x1600003, MainFunctionProc, 0xd,
; 0xeb36d0, 0x440 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x440.
; -----------------------------------------------------------------------------

; [nakarest] NakaDbg_PanelSimTitle  +0x0..+0x37c (0xeb2afe, 892 B)
; [nakarest] widget records, elements 2-22 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): Label (32 B) x7, AcTitleMenu (54 B), IvExitMode
; [nakarest] (26 B), AcWindowMenu (54 B), Screen (34 B), Window (36 B), DbDebugMenu (46 B),
; [nakarest] AcNamingWindow (36 B), AcIndexEditSw (40 B) x6, PsCursorBox (40 B). 9 texts the
; [nakarest] records point at (Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot)):
; [nakarest] "Panel Simulator for HK" (Label.str of element 2); "CHECK TITLE" (AcTitleMenu.str
; [nakarest] of element 3); "DEBUG WINDOW" (AcWindowMenu.str of element 5); "DEBUG TIME !"
; [nakarest] (Label.str of element 8); ....
NakaDbg_PanelSimTitle:				.incbin "includes/generated/naka_debug_naming.bin", 0x0, 0x38
NakaWidget_PanelSimulator_3_AcTitleMenu:	.incbin "includes/generated/naka_debug_naming.bin", 0x38, 0x42
NakaWidget_PanelSimulator_4_IvExitMode:		.incbin "includes/generated/naka_debug_naming.bin", 0x7A, 0x1A
NakaWidget_PanelSimulator_5_AcWindowMenu:	.incbin "includes/generated/naka_debug_naming.bin", 0x94, 0x44
NakaWidget_ClipBoard:				.incbin "includes/generated/naka_debug_naming.bin", 0xD8, 0x22
NakaWidget_DebugWindow:				.incbin "includes/generated/naka_debug_naming.bin", 0xFA, 0x24
NakaWidget_PanelSimulator_8_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x11E, 0x2E
NakaWidget_PanelSimulator_9_DbDebugMenu:	.incbin "includes/generated/naka_debug_naming.bin", 0x14C, 0x2E
NakaWidget_NamingWindow:			.incbin "includes/generated/naka_debug_naming.bin", 0x17A, 0x24
NakaWidget_PanelSimulator_11_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x19E, 0x28
NakaWidget_PanelSimulator_12_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x1C6, 0x24
NakaWidget_PanelSimulator_13_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x1EA, 0x28
NakaWidget_PanelSimulator_14_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x212, 0x24
NakaWidget_PanelSimulator_15_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x236, 0x28
NakaWidget_PanelSimulator_16_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x25E, 0x24
NakaWidget_PanelSimulator_17_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x282, 0x28
NakaWidget_PanelSimulator_18_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x2AA, 0x28
NakaWidget_PanelSimulator_19_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x2D2, 0x28
NakaWidget_PanelSimulator_20_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x2FA, 0x28
NakaWidget_PanelSimulator_21_Label:		.incbin "includes/generated/naka_debug_naming.bin", 0x322, 0x2A
NakaWidget_NamingCursorBox:			.incbin "includes/generated/naka_debug_naming.bin", 0x34C, 0x30
; [nakarest] NakaDbg_LowerCaseChars  +0x37c..+0x380 (0xeb2e7a, 4 B)
; [nakarest] Text (4 B at 0xeb2e7a), first string "abc"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table2 (at 0xeef54e).
NakaDbg_LowerCaseChars:	.incbin "includes/generated/naka_debug_naming.bin", 0x37C, 0x4
; [nakarest] NakaDbg_LowerCaseChars2  +0x380..+0x704 (0xeb2e7e, 900 B)
; [nakarest] Text (12 B at 0xeb2e7e), first string "abc"; no registered NAKA table points into
; [nakarest] it; reached through 3 data words in Naka_DrawbarDisplay_Table2 (at 0xeef54a,
; [nakarest] 0xeef57a, 0xeef576). widget records, elements 26-50 of Viewable slot 0x0 (table
; [nakarest] 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"): AcIndexEditSw (40 B) x3,
; [nakarest] PsParaBox (36 B), Window (36 B) x3, DbMemo (22 B), AcTrackSwitch (36 B) x16,
; [nakarest] DbMemoryDump (26 B).
NakaDbg_LowerCaseChars2:			.incbin "includes/generated/naka_debug_naming.bin", 0x380, 0xC
NakaWidget_PanelSimulator_26_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x38C, 0x28
NakaWidget_PanelSimulator_27_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x3B4, 0x28
NakaWidget_PanelSimulator_28_AcIndexEditSw:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DC, 0x28
NakaWidget_NamingLabel:				.incbin "includes/generated/naka_debug_naming.bin", 0x404, 0x24
NakaWidget_MemoWindow:				.incbin "includes/generated/naka_debug_naming.bin", 0x428, 0x24
NakaWidget_PanelSimulator_31_DbMemo:		.incbin "includes/generated/naka_debug_naming.bin", 0x44C, 0x16
NakaWidget_TrackSwitchWindow:			.incbin "includes/generated/naka_debug_naming.bin", 0x462, 0x24
NakaWidget_PanelSimulator_33_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x486, 0x24
NakaWidget_PanelSimulator_34_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x4AA, 0x24
NakaWidget_PanelSimulator_35_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x4CE, 0x24
NakaWidget_PanelSimulator_36_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x4F2, 0x24
NakaWidget_PanelSimulator_37_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x516, 0x24
NakaWidget_PanelSimulator_38_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x53A, 0x24
NakaWidget_PanelSimulator_39_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x55E, 0x24
NakaWidget_PanelSimulator_40_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x582, 0x24
NakaWidget_PanelSimulator_41_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x5A6, 0x24
NakaWidget_PanelSimulator_42_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x5CA, 0x24
NakaWidget_PanelSimulator_43_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x5EE, 0x24
NakaWidget_PanelSimulator_44_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x612, 0x24
NakaWidget_PanelSimulator_45_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x636, 0x24
NakaWidget_PanelSimulator_46_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x65A, 0x24
NakaWidget_PanelSimulator_47_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x67E, 0x24
NakaWidget_PanelSimulator_48_AcTrackSwitch:	.incbin "includes/generated/naka_debug_naming.bin", 0x6A2, 0x24
NakaWidget_MemDumpWindow:			.incbin "includes/generated/naka_debug_naming.bin", 0x6C6, 0x24
NakaWidget_PanelSimulator_50_DbMemoryDump:	.incbin "includes/generated/naka_debug_naming.bin", 0x6EA, 0x1A
; [nakarest] naka_debug_naming+0x704  +0x704..+0x876 (0xeb3202, 370 B)
; [nakarest] widget records, elements 0-8 of Viewable slot 0xff (table 0xeb3444, 9 entries,
; [nakarest] InitializeRoot) ("CheckTitle"): TtlScreen (42 B) x2, IvExitScreen (26 B) x3,
; [nakarest] AcScreenMenu (54 B) x2, IvNaming (26 B), Screen (34 B). 4 texts the records point
; [nakarest] at (Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot)): "CHECK TITLE"
; [nakarest] (TtlScreen.title of element 0); "Naming" (AcScreenMenu.str of element 2); "Wall"
; [nakarest] (AcScreenMenu.str of element 3); "Check Naming" (TtlScreen.title of element 4).
NakaWidget_CheckTitle:			.incbin "includes/generated/naka_debug_naming.bin", 0x704, 0x36
NakaWidget_CheckTitle_1_IvExitScreen:	.incbin "includes/generated/naka_debug_naming.bin", 0x73A, 0x1A
NakaWidget_CheckTitle_2_AcScreenMenu:	.incbin "includes/generated/naka_debug_naming.bin", 0x754, 0x3E
NakaWidget_CheckTitle_3_AcScreenMenu:	.incbin "includes/generated/naka_debug_naming.bin", 0x792, 0x3C
NakaWidget_CheckNaming:			.incbin "includes/generated/naka_debug_naming.bin", 0x7CE, 0x38
NakaWidget_CheckTitle_5_IvNaming:	.incbin "includes/generated/naka_debug_naming.bin", 0x806, 0x1A
NakaWidget_CheckTitle_6_IvExitScreen:	.incbin "includes/generated/naka_debug_naming.bin", 0x820, 0x1A
NakaWidget_CheckWall:			.incbin "includes/generated/naka_debug_naming.bin", 0x83A, 0x22
NakaWidget_CheckTitle_8_IvExitScreen:	.incbin "includes/generated/naka_debug_naming.bin", 0x85C, 0x1A
; [nakarest] naka_debug_naming+0x876  +0x876..+0x946 (0xeb3374, 208 B)
; [nakarest] the table itself: Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot),
; [nakarest] 51 entry pointers x 4 bytes.
Root_ViewableTable_000:	.incbin "includes/generated/naka_debug_naming.bin", 0x876, 0xD0
; [nakarest] naka_debug_naming+0x946  +0x946..+0x96e (0xeb3444, 40 B)
; [nakarest] the table itself: Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot), 9
; [nakarest] entry pointers x 4 bytes.
Root_ViewableTable_0FF:	.incbin "includes/generated/naka_debug_naming.bin", 0x946, 0x28
; [nakarest] naka_debug_naming+0x96e  +0x96e..+0xa40 (0xeb346c, 210 B)
; [nakarest] the table itself: ResName slot 0x300 (table 0xeb346c, 51 entries, InitializeRoot),
; [nakarest] 51 entry pointers x 4 bytes.
Root_ResNameTable_300:	.incbin "includes/generated/naka_debug_naming.bin", 0x96E, 0xD2
; [nakarest] naka_debug_naming+0xa40  +0xa40..+0xb2c (0xeb353e, 236 B)
; [nakarest] name strings, entries 0-50 of ResName slot 0x300 (table 0xeb346c, 51 entries,
; [nakarest] InitializeRoot) (names for Viewable slot 0x0): "", "MemDumpWindow", "", "", "", "",
; [nakarest] ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xA40, 0xEC
; [nakarest] naka_debug_naming+0xb2c  +0xb2c..+0xb56 (0xeb362a, 42 B)
; [nakarest] the table itself: ResName slot 0x3ff (table 0xeb362a, 9 entries, InitializeRoot), 9
; [nakarest] entry pointers x 4 bytes.
Root_ResNameTable_3FF:	.incbin "includes/generated/naka_debug_naming.bin", 0xB2C, 0x2A
; [nakarest] naka_debug_naming+0xb56  +0xb56..+0xb9a (0xeb3654, 68 B)
; [nakarest] name strings, entries 0-8 of ResName slot 0x3ff (table 0xeb362a, 9 entries,
; [nakarest] InitializeRoot) (names for Viewable slot 0xff): "", "CheckWall", "", "",
; [nakarest] "CheckNaming", "", ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xB56, 0x2E
InitializeRoot_Str_MD_PS:	.incbin "includes/generated/naka_debug_naming.bin", 0xB84, 0x6	; "MD_PS"
InitializeRoot_Str_TT_PS:	.incbin "includes/generated/naka_debug_naming.bin", 0xB8A, 0x6	; "TT_PS"
InitializeRoot_Str_TT_CHECK:	.incbin "includes/generated/naka_debug_naming.bin", 0xB90, 0xA	; "TT_CHECK"
; [nakarest] naka_debug_naming+0xb9a  +0xb9a..+0xbd2 (0xeb3698, 56 B)
; [nakarest] the table itself: MainFunction slot 0x140 (table 0xeb3698, 13 entries,
; [nakarest] InitializeRoot), 13 entry pointers x 4 bytes.
Root_MainFunctionTable_140:	.incbin "includes/generated/naka_debug_naming.bin", 0xB9A, 0x38
; [nakarest] naka_debug_naming+0xbd2  +0xbd2..+0xc0c (0xeb36d0, 58 B)
; [nakarest] the table itself: MainFunction slot 0x440 (table 0xeb36d0, 13 entries,
; [nakarest] InitializeRoot), 13 entry pointers x 4 bytes.
Root_MainFunctionTable_440:	.incbin "includes/generated/naka_debug_naming.bin", 0xBD2, 0x3A
; [nakarest] naka_debug_naming+0xc0c  +0xc0c..+0xce0 (0xeb370a, 212 B)
; [nakarest] name strings, entries 0-12 of MainFunction slot 0x440 (table 0xeb36d0, 13 entries,
; [nakarest] InitializeRoot) (names for MainFunction slot 0x140): "MainTaskControl",
; [nakarest] "DirmdTitleFunc", "MainTrSwControl", "CheckTitleFunc", "MainRamControl",
; [nakarest] "MainBitControl", ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xC0C, 0xD4
; [nakarest] naka_debug_naming+0xce0  +0xce0..+0x10e0 (0xeb37de, 1024 B)
; [nakarest] The DEFAULT 256-colour palette: InitPaletteRGB (display/graphics_text_vga.s) points
; [nakarest] xbc at this address (`lda xwa, (0xeb37de:24)`), sets the end to +0x400 (`lda_dri
; [nakarest] XHL, 0xe1, 0x00, 0x04`) and copies the 1024 bytes, 4 at a time, to the palette RAM
; [nakarest] at 0x0324fc -- which SetPaletteRGB writes and Table_LookupDword reads 4 bytes per
; [nakarest] colour (`sll xwa, 2`). 256 x {3 colour bytes, 0}: the 4th byte of all 256 entries
; [nakarest] is 0; the channel order was not traced.
Palette_8bit_RGBA:	.incbin "includes/generated/naka_debug_naming.bin", 0xCE0, 0x400
; [nakarest] NakaColor_Palette1  +0x10e0..+0x14e0 (0xeb3bde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 1 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette1:	.incbin "includes/generated/naka_debug_naming.bin", 0x10E0, 0x400
; [nakarest] NakaColor_Palette2  +0x14e0..+0x18e0 (0xeb3fde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 0 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette2:	.incbin "includes/generated/naka_debug_naming.bin", 0x14E0, 0x400
; [nakarest] NakaColor_Palette3  +0x18e0..+0x1ce0 (0xeb43de, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 5 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette3:	.incbin "includes/generated/naka_debug_naming.bin", 0x18E0, 0x400
; [nakarest] NakaColor_Palette4  +0x1ce0..+0x20e0 (0xeb47de, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 4 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette4:	.incbin "includes/generated/naka_debug_naming.bin", 0x1CE0, 0x400
; [nakarest] NakaColor_Palette5  +0x20e0..+0x24e0 (0xeb4bde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 3 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette5:	.incbin "includes/generated/naka_debug_naming.bin", 0x20E0, 0x400
; [nakarest] NakaColor_Palette6  +0x24e0..+0x28e0 (0xeb4fde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 2 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette6:	.incbin "includes/generated/naka_debug_naming.bin", 0x24E0, 0x400
; [nakarest] NakaColor_Palette7  +0x28e0..+0x2ce0 (0xeb53de, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 9 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette7:	.incbin "includes/generated/naka_debug_naming.bin", 0x28E0, 0x400
; [nakarest] NakaColor_Palette8  +0x2ce0..+0x30e0 (0xeb57de, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 8 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette8:	.incbin "includes/generated/naka_debug_naming.bin", 0x2CE0, 0x400
; [nakarest] NakaColor_Palette9  +0x30e0..+0x34e0 (0xeb5bde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 7 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette9:	.incbin "includes/generated/naka_debug_naming.bin", 0x30E0, 0x400
; [nakarest] NakaColor_Palette10  +0x34e0..+0x38e0 (0xeb5fde, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entry 6 of the
; [nakarest] 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM copies to
; [nakarest] RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_Palette10:	.incbin "includes/generated/naka_debug_naming.bin", 0x34E0, 0x400
; [nakarest] NakaColor_PaletteBlank  +0x38e0..+0x3ce0 (0xeb63de, 1024 B)
; [nakarest] A wallpaper palette: 256 x 4 bytes, three colour bytes and a 0 (the 4th byte of all
; [nakarest] 256 entries is 0; the channel order was not traced). Its address is entries 10-11
; [nakarest] of the 12-pointer table Naka_DrawbarReg_Table (0xeef588), which Boot_InitWorkRAM
; [nakarest] copies to RAM 0x3f1e4 with the rest of the work-RAM image; GetWallPaletteRGB
; [nakarest] (display/graphics_text_vga.s) takes that table's entry [index] and returns the
; [nakarest] palette's entry [colour] (`sll 2` twice), and ChangeWallPalette_Impl
; [nakarest] (ui/ui_window_procs.s) calls it for colours 0..15 and writes DAC entries 0xe0..0xef
; [nakarest] with SetPaletteRGB. The 1024-byte size is the spacing of the 11 palettes here; the
; [nakarest] reader shown only reads entries 0..15.
NakaColor_PaletteBlank:	.incbin "includes/generated/naka_debug_naming.bin", 0x38E0, 0x400
; SupportClass_SwordValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the swordProc property type
; +8 of SupportClass record 0 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_SwordValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3CE0, 0xA
; SupportClass_UwordValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the uwordProc property type
; +8 of SupportClass record 1 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_UwordValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3CEA, 0xA
; SupportClass_UcharValueNames -- 1 x 10-byte struct: the empty value-name list of ucharProc (SupportClass object 2)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 2 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_UcharValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3CF4, 0xA
; SupportClass_ScharValueNames -- 1 x 10-byte struct: the empty value-name list of scharProc (SupportClass object 3)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 3 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_ScharValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3CFE, 0xA
; NakaInst_slong_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "slong", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 4 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_slong_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D08, 0x8
; NakaInst_slong_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the slong enum table's terminator.
NakaInst_slong_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D10, 0x2
; NakaInst_ulong_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "ulong", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 5 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_ulong_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D12, 0x8
; NakaInst_ulong_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the ulong enum table's terminator.
NakaInst_ulong_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1A, 0x2
; [nakarest] NakaInst_False  +0x3d1c..+0x3d4c (0xeb681a, 48 B)
; [nakarest] purpose not established: layout of 48 B at 0xeb681a not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb76e0, 0xeb76ec), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaInst_False:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1C, 0x30
; NakaInst_pFunc_EnumTable -- 1 x {char *name; int32 value}: empty pFunc enum, only the {"", 0} end entry
; +8 of the pFuncProc SupportClass record (0xEB76F0) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_pFunc_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D4C, 0x8
; NakaInst_pFunc_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_pFunc_EnumTable
NakaInst_pFunc_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D54, 0x2
; NakaInst_pProc_EnumTable -- 1 x {char *name; int32 value}: empty pProc enum, only the {"", 0} end entry
; +8 of the pProcProc SupportClass record (0xEB76FC) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_pProc_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D56, 0x8
; NakaInst_pProc_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_pProc_EnumTable
NakaInst_pProc_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D5E, 0x2
; SupportClass_PPropValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the pPropProc property type
; +8 of SupportClass record 10 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_PPropValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D60, 0xA
; SupportClass_PStringValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the pStringProc property type
; +8 of SupportClass record 11 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_PStringValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D6A, 0xA
; SupportClass_ClassIDValueNames -- 1 x 10-byte struct: the empty value-name list of ClassIDProc (SupportClass object 12)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 12 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_ClassIDValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D74, 0xA
; SupportClass_ScreenIDValueNames -- 1 x 10-byte struct: the empty value-name list of ScreenIDProc (SupportClass object 13)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 13 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_ScreenIDValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D7E, 0xA
; NakaInst_EventID_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "EventID", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 14 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_EventID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D88, 0x8
; NakaInst_EventID_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the EventID enum table's terminator.
NakaInst_EventID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D90, 0x2
; NakaInst_RECTW_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "RECTW", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 15 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_RECTW_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D92, 0x8
; NakaInst_RECTW_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the RECTW enum table's terminator.
NakaInst_RECTW_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D9A, 0x2
; NakaInst_RectX1_EnumTable -- 1 x {char *name; int32 value}: empty RectX1 enum, only the {"", 0} end entry
; +8 of the RectX1Proc SupportClass record (0xEB7750) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_RectX1_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D9C, 0x8
; NakaInst_RectX1_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_RectX1_EnumTable
NakaInst_RectX1_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DA4, 0x2
; NakaInst_RectY1_EnumTable -- 1 x {char *name; int32 value}: empty RectY1 enum, only the {"", 0} end entry
; +8 of the RectY1Proc SupportClass record (0xEB775C) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_RectY1_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DA6, 0x8
; NakaInst_RectY1_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_RectY1_EnumTable
NakaInst_RectY1_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DAE, 0x2
; SupportClass_RectX2ValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the RectX2Proc property type
; +8 of SupportClass record 18 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_RectX2ValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DB0, 0xA
; SupportClass_RectY2ValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the RectY2Proc property type
; +8 of SupportClass record 19 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_RectY2ValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DBA, 0xA
; SupportClass_POINTWValueNames -- 1 x 10-byte struct: the empty value-name list of POINTWProc (SupportClass object 20)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 20 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_POINTWValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DC4, 0xA
; SupportClass_PointXValueNames -- 1 x 10-byte struct: the empty value-name list of PointXProc (SupportClass object 21)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 21 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_PointXValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DCE, 0xA
; NakaInst_PointY_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "PointY", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 22 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_PointY_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DD8, 0x8
; NakaInst_PointY_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the PointY enum table's terminator.
NakaInst_PointY_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DE0, 0x2
; NakaInst_String_EnumTable -- 1 x {char *name, u32 value}: the enum table of property type "String", holding only its {"", 0} terminator.
; Pointed to by word +8 of SupportClass descriptor 23 (ExitWindow_OK_Data_2, slot 0x260); CommonIDProc
; (ui/ui_widget_defs.s) walks such tables in 8-byte steps until name[0] == 0, but this type's count word (+4) is 0.
NakaInst_String_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DE2, 0x8
; NakaInst_String_EmptyStr -- 2 x char: "" plus a 0xFF alignment pad, the name of the String enum table's terminator.
NakaInst_String_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DEA, 0x2
; SupportClass_NameValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the NameProc property type
; +8 of SupportClass record 24 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_NameValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DEC, 0xA
; SupportClass_ConstFlagValueNames -- 1 x {3 x {u32 name, s32 value}, char text[22]}: value names of ConstFlagProc (record 25, count 2)
; 3 x {u32 name ptr, s32 value}: CF_AllRam = 0, CF_AllRom = 1, end entry ""; then "" 00 FF,
; "CF_AllRom", "CF_AllRam" (the name pointers point into this struct)
; read by CommonIDProc: search by value (DUMP_PROPERTY_EX), name by index (GET_PROP_DATA_SP)
SupportClass_ConstFlagValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3DF6, 0x2E
; SupportClass_ViewIDValueNames -- 1 x 10-byte struct: the empty value-name list of ViewIDProc (SupportClass object 26)
; {name pointer, value} terminator (8 B, name points 8 bytes on) + that name, "" with a 0xFF alignment byte (2 B).
; Entry 26 of ExitWindow_OK_Data_2 (the SupportClass table) points here with value count 0;
; CommonIDProc walks such lists 8 bytes at a time until a name's first byte is 0.
SupportClass_ViewIDValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x3E24, 0xA
; [nakarest] NakaProp_VisFlag_Chain  +0x3e2e..+0x40d2 (0xeb692c, 676 B)
; [nakarest] purpose not established: layout of 676 B at 0xeb692c not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb77e8, 0xeb77f4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaProp_VisFlag_Chain:	.incbin "includes/generated/naka_debug_naming.bin", 0x3E2E, 0x2A4
; [nakarest] NakaProp_BorderDefs  +0x40d2..+0x426e (0xeb6bd0, 412 B)
; [nakarest] purpose not established: layout of 412 B at 0xeb6bd0 not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb7800, 0xeb780c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaProp_BorderDefs:	.incbin "includes/generated/naka_debug_naming.bin", 0x40D2, 0x19C
; NakaInst_TitleID_EnumTable -- 1 x {char *name; int32 value}: empty TitleID enum, only the {"", 0} end entry
; +8 of the TitleIDProc SupportClass record (0xEB7810) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_TitleID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x426E, 0x8
; NakaInst_TitleID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_TitleID_EnumTable
NakaInst_TitleID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x4276, 0x2
; NakaInst_IconID_EnumTable -- 1 x {char *name; int32 value}: empty IconID enum, only the {"", 0} end entry
; +8 of the IconIDProc SupportClass record (0xEB781C) in ExitWindow_OK_Data_2, whose count is 0;
; CommonIDProc (ui/ui_widget_defs.s) stops at once on the empty name.
NakaInst_IconID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x4278, 0x8
; NakaInst_IconID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_IconID_EnumTable
NakaInst_IconID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x4280, 0x2
; [nakarest] NakaProp_Align_PtrEntry  +0x4282..+0x42d8 (0xeb6d80, 86 B)
; [nakarest] purpose not established: layout of 86 B at 0xeb6d80 not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb7830, 0xeb783c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaProp_Align_PtrEntry:	.incbin "includes/generated/naka_debug_naming.bin", 0x4282, 0x56
; [nakarest] NakaProp_EditSwitch_Chain  +0x42d8..+0x457c (0xeb6dd6, 676 B)
; [nakarest] purpose not established: layout of 676 B at 0xeb6dd6 not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb7848, 0xeb7854), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaProp_EditSwitch_Chain:	.incbin "includes/generated/naka_debug_naming.bin", 0x42D8, 0x2A4
; NakaInst_LineModeID_EnumTable -- 3 x {char *name; int32 value}: LineModeID enum, ""-terminated
; {"LM_RightUp", 0}, {"LM_RightDown", 1}, {"", 0}. +8 of the LineModeIDProc SupportClass record in
; ExitWindow_OK_Data_2 (count 2); CommonIDProc (ui/ui_widget_defs.s) maps value <-> name through it.
NakaInst_LineModeID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x457C, 0x18
; NakaInst_LineModeID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_LineModeID_EnumTable
NakaInst_LineModeID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x4594, 0x2
; NakaInst_LM_RightDown_Str -- 14 x char: "LM_RightDown" + 0xFF fill, name of LineModeID value 1
NakaInst_LM_RightDown_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4596, 0xE
; NakaInst_LM_RightUp -- 12 x char: "LM_RightUp" + 0xFF fill, name of LineModeID value 0
NakaInst_LM_RightUp:	.incbin "includes/generated/naka_debug_naming.bin", 0x45A4, 0xC
; NakaInst_FrameID_EnumTable -- 3 x {char *name; int32 value}: FrameID enum, ""-terminated
; {"FR_None", 0}, {"FR_Single", 1}, {"", 0}. +8 of the FrameIDProc SupportClass record in
; ExitWindow_OK_Data_2 (count 2); read by CommonIDProc (ui/ui_widget_defs.s).
NakaInst_FrameID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x45B0, 0x18
; NakaInst_FrameID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_FrameID_EnumTable
NakaInst_FrameID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x45C8, 0x2
; NakaInst_FR_Single -- 10 x char: "FR_Single", name of FrameID value 1
NakaInst_FR_Single:	.incbin "includes/generated/naka_debug_naming.bin", 0x45CA, 0xA
; NakaInst_FR_None -- 8 x char: "FR_None", name of FrameID value 0
NakaInst_FR_None:	.incbin "includes/generated/naka_debug_naming.bin", 0x45D4, 0x8
; SupportClass_BitmapIDValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the BitmapIDProc property type
; +8 of SupportClass record 40 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_BitmapIDValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x45DC, 0xA
; SupportClass_ApFuncIDValueNames -- 1 x {u32 end_name, s32 end_value, char end_text[2]}: empty value-name list of the ApFuncIDProc property type
; +8 of SupportClass record 41 (ExitWindow_OK_Data_2, 12 B/record) points here; its count (+4) is 0
; list format read by CommonIDProc (ui/ui_widget_defs.s): 8-byte {name ptr, s32 value} entries ended
; by an entry whose name is "" -- here only that end entry, then the "" it points at (00 FF)
SupportClass_ApFuncIDValueNames:	.incbin "includes/generated/naka_debug_naming.bin", 0x45E6, 0xA
; [nakarest] NakaProp_Frame_Chain  +0x45f0..+0x46c0 (0xeb70ee, 208 B)
; [nakarest] purpose not established: layout of 208 B at 0xeb70ee not derived; readers below
; [nakarest] Readers: 2 data words in ExitWindow_OK_Data_2 (at 0xeb7890, 0xeb789c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (ExitWindow_OK_Data_2:24)`).
NakaProp_Frame_Chain:	.incbin "includes/generated/naka_debug_naming.bin", 0x45F0, 0xD0
; External label offsets within the binary blob above.
