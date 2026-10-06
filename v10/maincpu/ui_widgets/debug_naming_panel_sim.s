
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
; [nakarest] it; reached through 1 data word in Font_FileNamePtrTable (at 0xeef54e).
NakaDbg_LowerCaseChars:	.incbin "includes/generated/naka_debug_naming.bin", 0x37C, 0x4
; [nakarest] NakaDbg_LowerCaseChars2  +0x380..+0x704 (0xeb2e7e, 900 B)
; [nakarest] Text (12 B at 0xeb2e7e), first string "abc"; no registered NAKA table points into
; [nakarest] it; reached through 3 data words in Font_FileNamePtrTable (at 0xeef54a,
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
; NakaWidget_CheckTitle_8_IvExitScreen -- 1 x struct (IvExitScreen view record, 26 B): the EXIT catcher of the "CheckWall" debug screen, entry 8 of InitializeRoot's Viewable table slot 0xFF
; Child of entry 7 (CheckWall); rect (0,0)-(31,31). +22 screen = view id 0x00FF0000 (slot 0xFF entry 0, the
; "CheckTitle" screen): IvExitScreenProc posts EVT_SHOW to it, so EXIT returns to CheckTitle. Typed as two words
; (entry, slot) because the 32-bit value is not an address.
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
; NakaInst_Bool_EnumTable -- 3 x {u32 name, s32 value}: value names of the Bool property type (2 named + "" end entry)
; Word +8 of SupportClass record 6 (boolProc, count 2) in ExitWindow_OK_Data_2, the 55 x 12-byte table
; ExitWindow_OK registers as class SupportClass.  CommonIDProc (ui/ui_widget_defs.s) walks it in 8-byte steps:
; DUMP_PROPERTY_EX matches the 32-bit value and Strcpy's the name, SET_PROPERTY_EX Strcmp's the names; "" ends it.
; True=1, False=0
NakaInst_Bool_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1C, 0x18
; NakaInst_Bool_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_Bool_EnumTable
; NakaInst_Bool_EnumTable's last entry {"", 0} points here; CommonIDProc stops at a name whose first byte is 0.
NakaInst_Bool_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D34, 0x2
; NakaInst_Bool_False_Str -- 6 x char: "False", name of Bool value 0
; Entry 1 of NakaInst_Bool_EnumTable points here.
NakaInst_Bool_False_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D36, 0x6
; NakaInst_Bool_True_Str -- 6 x char: "True" + 0xFF fill, name of Bool value 1
; Entry 0 of NakaInst_Bool_EnumTable points here.
NakaInst_Bool_True_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D3C, 0x6
; NakaInst_ObjectID_EnumTable -- 1 x {u32 name, s32 value}: empty value-name list of the ObjectID property type, only the "" end entry
; Word +8 of SupportClass record 7 (ObjectIDProc) in ExitWindow_OK_Data_2; its count word (+4) is 0, so
; CommonIDProc (ui/ui_widget_defs.s) does not search it, and its SET_PROPERTY_EX falls back to ParseInt32.
NakaInst_ObjectID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D42, 0x8
; NakaInst_ObjectID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_ObjectID_EnumTable
; NakaInst_ObjectID_EnumTable's only entry {"", 0} points here.
NakaInst_ObjectID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3D4A, 0x2
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
; NakaInst_ViewFlag_EnumTable -- 7 x {u32 name_ptr, s32 value}: ViewFlag property value names, ended by {"", 0}
; VF_None 0, VF_Invisible 1, VF_Fixed 2, VF_Change 4, VF_Const 8, VF_InvisibleBox 0x10. +8 of the ViewFlagProc
; SupportClass record (entry 28 of ExitWindow_OK_Data_2, count 6). CommonIDProc (ui/ui_widget_defs.s) walks it in
; 8-byte steps until the name is "": value -> name for DUMP_PROPERTY_EX, name -> value for SET_PROPERTY_EX.
NakaInst_ViewFlag_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3E2E, 0x38
; NakaInst_ViewFlag_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the {"", 0} end entry of NakaInst_ViewFlag_EnumTable;
; CommonIDProc (ui/ui_widget_defs.s) stops its walk at this empty name.
NakaInst_ViewFlag_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3E66, 0x2
; NakaInst_ViewFlag_NameStrings -- 68 x char: the ViewFlag value names VF_InvisibleBox, VF_Const, VF_Change, VF_Fixed,
; VF_Invisible, VF_None (NUL-terminated, 0xFF-padded to even length); the name_ptr fields of
; NakaInst_ViewFlag_EnumTable point at them.
NakaInst_ViewFlag_NameStrings:	.incbin "includes/generated/naka_debug_naming.bin", 0x3E68, 0x44
; NakaInst_ColorID_EnumTable -- 30 x {u32 name_ptr, s32 value}: ColorID property value names (palette colour numbers), ended by {"", 0}
; CL_Black 0, CL_Maroon 1 .. CL_Teal 6, CL_Silver 7, CL_DarkGray 8, CL_Orange 9, CL_FireRed 10, CL_HairLine 11, CL_DarkYellow 12,
; CL_LightGreen 13, CL_IconBack 0xF0, CL_Text 0xF1, CL_Selected 0xF2, CL_PageBack 0xF3, CL_EditSw 0xF4, CL_WallPattern 0xF5,
; CL_Transparent 0xF7, CL_Gray 0xF8, CL_Red 0xF9 .. CL_Aqua 0xFE, CL_White 0xFF. +8 of the ColorIDProc SupportClass record
; (entry 29 of ExitWindow_OK_Data_2, count 29); CommonIDProc (ui/ui_widget_defs.s) walks it in 8-byte steps.
NakaInst_ColorID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x3EAC, 0xF0
; NakaInst_ColorID_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the {"", 0} end entry of NakaInst_ColorID_EnumTable;
; CommonIDProc (ui/ui_widget_defs.s) stops its walk at this empty name.
NakaInst_ColorID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x3F9C, 0x2
; NakaInst_ColorID_NameStrings -- 308 x char: the 29 ColorID value names, CL_WallPattern first and CL_Black last
; (NUL-terminated, 0xFF-padded to even length); the name_ptr fields of NakaInst_ColorID_EnumTable point at them.
NakaInst_ColorID_NameStrings:	.incbin "includes/generated/naka_debug_naming.bin", 0x3F9E, 0x134
; NakaInst_BorderID_EnumTable -- 21 x {u32 name, s32 value}: value names of the BorderID property type (20 named + "" end entry)
; Word +8 of SupportClass record 30 (BorderIDProc, count 20) in ExitWindow_OK_Data_2, the 55 x 12-byte table
; ExitWindow_OK registers as class SupportClass.  CommonIDProc (ui/ui_widget_defs.s) walks it in 8-byte steps:
; DUMP_PROPERTY_EX matches the 32-bit value and Strcpy's the name, SET_PROPERTY_EX Strcmp's the names; "" ends it.
; BD_None=0, BD_Single1=1, BD_Single2=2, BD_Double1=3, BD_Shadow1=4, BD_Shadow2=5, BD_Round0=6, BD_Round1=7, BD_Round2=8, BD_Round5=9, ... (10 more)
NakaInst_BorderID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x40D2, 0xA8
; NakaInst_BorderID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_BorderID_EnumTable
; NakaInst_BorderID_EnumTable's last entry {"", 0} points here; CommonIDProc stops at a name whose first byte is 0.
NakaInst_BorderID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x417A, 0x2
; NakaInst_BD_TrackSwDown_Str -- 16 x char: "BD_TrackSwDown" + 0xFF fill, name of BorderID value 0xCC
; Entry 19 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_TrackSwDown_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x417C, 0x10
; NakaInst_BD_TrackSwUp_Str -- 14 x char: "BD_TrackSwUp" + 0xFF fill, name of BorderID value 0xCB
; Entry 18 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_TrackSwUp_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x418C, 0xE
; NakaInst_BD_EditSwDown_Str -- 14 x char: "BD_EditSwDown", name of BorderID value 0xCA
; Entry 17 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_EditSwDown_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x419A, 0xE
; NakaInst_BD_EditSwitch_Str -- 14 x char: "BD_EditSwitch", name of BorderID value 0xC9
; Entry 16 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_EditSwitch_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41A8, 0xE
; NakaInst_BD_3D_DOWN2_Str -- 12 x char: "BD_3D_DOWN2", name of BorderID value 0xC3
; Entry 15 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_3D_DOWN2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41B6, 0xC
; NakaInst_BD_3D_DOWN1_Str -- 12 x char: "BD_3D_DOWN1", name of BorderID value 0xC2
; Entry 14 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_3D_DOWN1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41C2, 0xC
; NakaInst_BD_3D_UP2_Str -- 10 x char: "BD_3D_UP2", name of BorderID value 0xC1
; Entry 13 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_3D_UP2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41CE, 0xA
; NakaInst_BD_3D_UP1_Str -- 10 x char: "BD_3D_UP1", name of BorderID value 0xC0
; Entry 12 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_3D_UP1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41D8, 0xA
; NakaInst_BD_Round14_Str -- 12 x char: "BD_Round14" + 0xFF fill, name of BorderID value 0x0B
; Entry 11 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round14_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41E2, 0xC
; NakaInst_BD_Round9_Str -- 10 x char: "BD_Round9", name of BorderID value 0x0A
; Entry 10 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round9_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41EE, 0xA
; NakaInst_BD_Round5_Str -- 10 x char: "BD_Round5", name of BorderID value 9
; Entry 9 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round5_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x41F8, 0xA
; NakaInst_BD_Round2_Str -- 10 x char: "BD_Round2", name of BorderID value 8
; Entry 8 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4202, 0xA
; NakaInst_BD_Round1_Str -- 10 x char: "BD_Round1", name of BorderID value 7
; Entry 7 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x420C, 0xA
; NakaInst_BD_Round0_Str -- 10 x char: "BD_Round0", name of BorderID value 6
; Entry 6 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Round0_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4216, 0xA
; NakaInst_BD_Shadow2_Str -- 12 x char: "BD_Shadow2" + 0xFF fill, name of BorderID value 5
; Entry 5 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Shadow2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4220, 0xC
; NakaInst_BD_Shadow1_Str -- 12 x char: "BD_Shadow1" + 0xFF fill, name of BorderID value 4
; Entry 4 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Shadow1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x422C, 0xC
; NakaInst_BD_Double1_Str -- 12 x char: "BD_Double1" + 0xFF fill, name of BorderID value 3
; Entry 3 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Double1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4238, 0xC
; NakaInst_BD_Single2_Str -- 12 x char: "BD_Single2" + 0xFF fill, name of BorderID value 2
; Entry 2 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Single2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4244, 0xC
; NakaInst_BD_Single1_Str -- 12 x char: "BD_Single1" + 0xFF fill, name of BorderID value 1
; Entry 1 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_Single1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4250, 0xC
; NakaInst_BD_None_Str -- 8 x char: "BD_None", name of BorderID value 0
; Entry 0 of NakaInst_BorderID_EnumTable points here.
NakaInst_BD_None_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x425C, 0x8
; NakaInst_ModeID_EnumTable -- 1 x {u32 name, s32 value}: empty value-name list of the ModeID property type, only the "" end entry
; Word +8 of SupportClass record 31 (ModeIDProc) in ExitWindow_OK_Data_2; its count word (+4) is 0, so
; CommonIDProc (ui/ui_widget_defs.s) does not search it, and its SET_PROPERTY_EX falls back to ParseInt32.
NakaInst_ModeID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x4264, 0x8
; NakaInst_ModeID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_ModeID_EnumTable
; NakaInst_ModeID_EnumTable's only entry {"", 0} points here.
NakaInst_ModeID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x426C, 0x2
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
; NakaInst_FontID_EnumTable -- 1 x {u32 name_ptr, s32 value}: the FontID value-name list, only its {"", 0} end entry
; +8 of the FontIDProc SupportClass record (entry 34 of ExitWindow_OK_Data_2, count 0); FontIDProc handles font names
; itself and passes other events to CommonIDProc (ui/ui_widget_defs.s), which stops at once on the empty name.
NakaInst_FontID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x4282, 0x8
; NakaInst_FontID_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the end entry of NakaInst_FontID_EnumTable
NakaInst_FontID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x428A, 0x2
; NakaInst_AlignmentID_EnumTable -- 4 x {u32 name_ptr, s32 value}: AlignmentID value names, ended by {"", 0}
; AL_Center 0, AL_LeftJustify 1, AL_RightJustify 2. +8 of the AlignmentIDProc SupportClass record (entry 35 of
; ExitWindow_OK_Data_2, count 3, 1-byte data); AlignmentIDProc reads the byte and CommonIDProc (ui/ui_widget_defs.s)
; maps value <-> name through this list.
NakaInst_AlignmentID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x428C, 0x20
; NakaInst_AlignmentID_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the end entry of NakaInst_AlignmentID_EnumTable
NakaInst_AlignmentID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x42AC, 0x2
; NakaInst_AlignmentID_NameStrings -- 42 x char: the AlignmentID value names AL_RightJustify, AL_LeftJustify, AL_Center
; (NUL-terminated, 0xFF-padded to even length); the name_ptr fields of NakaInst_AlignmentID_EnumTable point at them.
NakaInst_AlignmentID_NameStrings:	.incbin "includes/generated/naka_debug_naming.bin", 0x42AE, 0x2A
; NakaInst_EditSwID_EnumTable -- 21 x {u32 name, s32 value}: value names of the EditSwID property type (20 named + "" end entry)
; Word +8 of SupportClass record 36 (EditSwIDProc, count 20) in ExitWindow_OK_Data_2, the 55 x 12-byte table
; ExitWindow_OK registers as class SupportClass.  CommonIDProc (ui/ui_widget_defs.s) walks it in 8-byte steps:
; DUMP_PROPERTY_EX matches the 32-bit value and Strcpy's the name, SET_PROPERTY_EX Strcmp's the names; "" ends it.
; ES_Bottom1=0, ES_Bottom2=1, ES_Bottom3=2, ES_Bottom4=3, ES_Bottom5=4, ES_Bottom6=5, ES_Bottom7=6, ES_Bottom8=7, ES_Left1=0x88, ES_Left2=0x89, ... (10 more)
NakaInst_EditSwID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x42D8, 0xA8
; NakaInst_EditSwID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_EditSwID_EnumTable
; NakaInst_EditSwID_EnumTable's last entry {"", 0} points here; CommonIDProc stops at a name whose first byte is 0.
NakaInst_EditSwID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x4380, 0x2
; NakaInst_ES_None_Str -- 8 x char: "ES_None", name of EditSwID value 0xFF
; Entry 19 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_None_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4382, 0x8
; NakaInst_ES_Exit_Str -- 8 x char: "ES_Exit", name of EditSwID value 0x0F
; Entry 18 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Exit_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x438A, 0x8
; NakaInst_ES_Right5_Str -- 10 x char: "ES_Right5", name of EditSwID value 0x0C
; Entry 17 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Right5_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4392, 0xA
; NakaInst_ES_Right4_Str -- 10 x char: "ES_Right4", name of EditSwID value 0x0B
; Entry 16 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Right4_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x439C, 0xA
; NakaInst_ES_Right3_Str -- 10 x char: "ES_Right3", name of EditSwID value 0x0A
; Entry 15 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Right3_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43A6, 0xA
; NakaInst_ES_Right2_Str -- 10 x char: "ES_Right2", name of EditSwID value 9
; Entry 14 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Right2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43B0, 0xA
; NakaInst_ES_Right1_Str -- 10 x char: "ES_Right1", name of EditSwID value 8
; Entry 13 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Right1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43BA, 0xA
; NakaInst_ES_Left5_Str -- 10 x char: "ES_Left5" + 0xFF fill, name of EditSwID value 0x8C
; Entry 12 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Left5_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43C4, 0xA
; NakaInst_ES_Left4_Str -- 10 x char: "ES_Left4" + 0xFF fill, name of EditSwID value 0x8B
; Entry 11 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Left4_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43CE, 0xA
; NakaInst_ES_Left3_Str -- 10 x char: "ES_Left3" + 0xFF fill, name of EditSwID value 0x8A
; Entry 10 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Left3_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43D8, 0xA
; NakaInst_ES_Left2_Str -- 10 x char: "ES_Left2" + 0xFF fill, name of EditSwID value 0x89
; Entry 9 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Left2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43E2, 0xA
; NakaInst_ES_Left1_Str -- 10 x char: "ES_Left1" + 0xFF fill, name of EditSwID value 0x88
; Entry 8 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Left1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43EC, 0xA
; NakaInst_ES_Bottom8_Str -- 12 x char: "ES_Bottom8" + 0xFF fill, name of EditSwID value 7
; Entry 7 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom8_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x43F6, 0xC
; NakaInst_ES_Bottom7_Str -- 12 x char: "ES_Bottom7" + 0xFF fill, name of EditSwID value 6
; Entry 6 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom7_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4402, 0xC
; NakaInst_ES_Bottom6_Str -- 12 x char: "ES_Bottom6" + 0xFF fill, name of EditSwID value 5
; Entry 5 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom6_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x440E, 0xC
; NakaInst_ES_Bottom5_Str -- 12 x char: "ES_Bottom5" + 0xFF fill, name of EditSwID value 4
; Entry 4 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom5_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x441A, 0xC
; NakaInst_ES_Bottom4_Str -- 12 x char: "ES_Bottom4" + 0xFF fill, name of EditSwID value 3
; Entry 3 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom4_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4426, 0xC
; NakaInst_ES_Bottom3_Str -- 12 x char: "ES_Bottom3" + 0xFF fill, name of EditSwID value 2
; Entry 2 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom3_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4432, 0xC
; NakaInst_ES_Bottom2_Str -- 12 x char: "ES_Bottom2" + 0xFF fill, name of EditSwID value 1
; Entry 1 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x443E, 0xC
; NakaInst_ES_Bottom1_Str -- 12 x char: "ES_Bottom1" + 0xFF fill, name of EditSwID value 0
; Entry 0 of NakaInst_EditSwID_EnumTable points here.
NakaInst_ES_Bottom1_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x444A, 0xC
; NakaInst_EditSwStyleID_EnumTable -- 18 x {u32 name, s32 value}: value names of the EditSwStyleID property type (17 named + "" end entry)
; Word +8 of SupportClass record 37 (EditSwStyleIDProc, count 17) in ExitWindow_OK_Data_2, the 55 x 12-byte table
; ExitWindow_OK registers as class SupportClass.  CommonIDProc (ui/ui_widget_defs.s) walks it in 8-byte steps:
; DUMP_PROPERTY_EX matches the 32-bit value and Strcpy's the name, SET_PROPERTY_EX Strcmp's the names; "" ends it.
; SS_Special=0, SS_Up=1, SS_Down=2, SS_UpDown=3, SS_On=4, SS_Off=5, SS_OK=6, SS_Left=7, SS_Right=8, SS_Yes=9, SS_No=0x0A, SS_OnOff=0x0B, ... (5 more)
NakaInst_EditSwStyleID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x4456, 0x90
; NakaInst_EditSwStyleID_EmptyStr -- 2 x char: "" + 0xFF fill, name of the end entry of NakaInst_EditSwStyleID_EnumTable
; NakaInst_EditSwStyleID_EnumTable's last entry {"", 0} points here; CommonIDProc stops at a name whose first byte is 0.
NakaInst_EditSwStyleID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x44E6, 0x2
; NakaInst_SS_Right2_Str -- 10 x char: "SS_Right2", name of EditSwStyleID value 0x10
; Entry 16 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Right2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x44E8, 0xA
; NakaInst_SS_Left2_Str -- 10 x char: "SS_Left2" + 0xFF fill, name of EditSwStyleID value 0x0F
; Entry 15 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Left2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x44F2, 0xA
; NakaInst_SS_UpDown2_Str -- 12 x char: "SS_UpDown2" + 0xFF fill, name of EditSwStyleID value 0x0E
; Entry 14 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_UpDown2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x44FC, 0xC
; NakaInst_SS_Down2_Str -- 10 x char: "SS_Down2" + 0xFF fill, name of EditSwStyleID value 0x0D
; Entry 13 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Down2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4508, 0xA
; NakaInst_SS_Up2_Str -- 8 x char: "SS_Up2" + 0xFF fill, name of EditSwStyleID value 0x0C
; Entry 12 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Up2_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4512, 0x8
; NakaInst_SS_OnOff_Str -- 10 x char: "SS_OnOff" + 0xFF fill, name of EditSwStyleID value 0x0B
; Entry 11 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_OnOff_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x451A, 0xA
; NakaInst_SS_No_Str -- 6 x char: "SS_No", name of EditSwStyleID value 0x0A
; Entry 10 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_No_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4524, 0x6
; NakaInst_SS_Yes_Str -- 8 x char: "SS_Yes" + 0xFF fill, name of EditSwStyleID value 9
; Entry 9 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Yes_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x452A, 0x8
; NakaInst_SS_Right_Str -- 10 x char: "SS_Right" + 0xFF fill, name of EditSwStyleID value 8
; Entry 8 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Right_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4532, 0xA
; NakaInst_SS_Left_Str -- 8 x char: "SS_Left", name of EditSwStyleID value 7
; Entry 7 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Left_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x453C, 0x8
; NakaInst_SS_OK_Str -- 6 x char: "SS_OK", name of EditSwStyleID value 6
; Entry 6 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_OK_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4544, 0x6
; NakaInst_SS_Off_Str -- 8 x char: "SS_Off" + 0xFF fill, name of EditSwStyleID value 5
; Entry 5 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Off_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x454A, 0x8
; NakaInst_SS_On_Str -- 6 x char: "SS_On", name of EditSwStyleID value 4
; Entry 4 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_On_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4552, 0x6
; NakaInst_SS_UpDown_Str -- 10 x char: "SS_UpDown", name of EditSwStyleID value 3
; Entry 3 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_UpDown_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4558, 0xA
; NakaInst_SS_Down_Str -- 8 x char: "SS_Down", name of EditSwStyleID value 2
; Entry 2 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Down_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4562, 0x8
; NakaInst_SS_Up_Str -- 6 x char: "SS_Up", name of EditSwStyleID value 1
; Entry 1 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Up_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x456A, 0x6
; NakaInst_SS_Special_Str -- 12 x char: "SS_Special" + 0xFF fill, name of EditSwStyleID value 0
; Entry 0 of NakaInst_EditSwStyleID_EnumTable points here.
NakaInst_SS_Special_Str:	.incbin "includes/generated/naka_debug_naming.bin", 0x4570, 0xC
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
; NakaInst_MainFuncID_EnumTable -- 1 x {u32 name_ptr, s32 value}: the MainFuncID value-name list, only its {"", 0} end entry
; +8 of the MainFuncIDProc SupportClass record (entry 42 of ExitWindow_OK_Data_2, count 0); MainFuncIDProc names main
; functions itself and passes other events to CommonIDProc (ui/ui_widget_defs.s), which stops at the empty name.
NakaInst_MainFuncID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x45F0, 0x8
; NakaInst_MainFuncID_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the end entry of NakaInst_MainFuncID_EnumTable
NakaInst_MainFuncID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x45F8, 0x2
; NakaInst_UserID_EnumTable -- 14 x {u32 name_ptr, s32 value}: UserID value names, ended by {"", 0}: iduRoot 0, iduMurai 1,
; iduToshi 2, iduEast 3, iduSuna 4, iduCheap 5, iduScoop 6, iduYoko 7, iduKubo 8, iduHama 9, iduKSS 10, iduNaka 11, iduNone -1
; (the first three names are in naka_style_bitmaps). +8 of the UserIDProc SupportClass record (entry 43 of
; ExitWindow_OK_Data_2, count 13); UserIDProc sign-extends the 16-bit value (-1 = iduNone) and CommonIDProc maps it.
; A title record's +8 is such a user id (TitleProc_OnGetUserId; Title_RecordTemplate holds -1).
NakaInst_UserID_EnumTable:	.incbin "includes/generated/naka_debug_naming.bin", 0x45FA, 0x70
; NakaInst_UserID_EmptyStr -- 2 x char: "" + 0xFF fill, the name of the end entry of NakaInst_UserID_EnumTable
NakaInst_UserID_EmptyStr:	.incbin "includes/generated/naka_debug_naming.bin", 0x466A, 0x2
; NakaInst_UserID_NameStrings -- 84 x char: UserID value names iduNone, iduNaka, iduKSS, iduHama, iduKubo, iduYoko,
; iduScoop, iduCheap, iduSuna, iduEast (NUL-terminated, 0xFF-padded to even length); the list continues past the blob
; end with iduToshi, iduMurai, iduRoot (NakaData_StyleBitmaps, NakaInst_iduMurai, NakaInst_iduRoot).
NakaInst_UserID_NameStrings:	.incbin "includes/generated/naka_debug_naming.bin", 0x466C, 0x54
; External label offsets within the binary blob above.
