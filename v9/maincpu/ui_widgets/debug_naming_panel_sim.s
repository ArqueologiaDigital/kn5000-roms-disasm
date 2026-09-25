
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
NakaDbg_PanelSimTitle:
	.incbin "includes/generated/naka_debug_naming.bin", 0x0, 0x37C
; [nakarest] NakaDbg_LowerCaseChars  +0x37c..+0x380 (0xeb2e7a, 4 B)
; [nakarest] Text (4 B at 0xeb2e7a), first string "abc"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table2 (at 0xeef54e).
NakaDbg_LowerCaseChars:
	.incbin "includes/generated/naka_debug_naming.bin", 0x37C, 0x4
; [nakarest] NakaDbg_LowerCaseChars2  +0x380..+0x704 (0xeb2e7e, 900 B)
; [nakarest] Text (12 B at 0xeb2e7e), first string "abc"; no registered NAKA table points into
; [nakarest] it; reached through 3 data words in Naka_DrawbarDisplay_Table2 (at 0xeef54a,
; [nakarest] 0xeef57a, 0xeef576). widget records, elements 26-50 of Viewable slot 0x0 (table
; [nakarest] 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"): AcIndexEditSw (40 B) x3,
; [nakarest] PsParaBox (36 B), Window (36 B) x3, DbMemo (22 B), AcTrackSwitch (36 B) x16,
; [nakarest] DbMemoryDump (26 B).
NakaDbg_LowerCaseChars2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x380, 0x384
; [nakarest] naka_debug_naming+0x704  +0x704..+0x876 (0xeb3202, 370 B)
; [nakarest] widget records, elements 0-8 of Viewable slot 0xff (table 0xeb3444, 9 entries,
; [nakarest] InitializeRoot) ("CheckTitle"): TtlScreen (42 B) x2, IvExitScreen (26 B) x3,
; [nakarest] AcScreenMenu (54 B) x2, IvNaming (26 B), Screen (34 B). 4 texts the records point
; [nakarest] at (Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot)): "CHECK TITLE"
; [nakarest] (TtlScreen.title of element 0); "Naming" (AcScreenMenu.str of element 2); "Wall"
; [nakarest] (AcScreenMenu.str of element 3); "Check Naming" (TtlScreen.title of element 4).
	.incbin "includes/generated/naka_debug_naming.bin", 0x704, 0x172
; [nakarest] naka_debug_naming+0x876  +0x876..+0x946 (0xeb3374, 208 B)
; [nakarest] the table itself: Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot),
; [nakarest] 51 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0x876, 0xD0
; [nakarest] naka_debug_naming+0x946  +0x946..+0x96e (0xeb3444, 40 B)
; [nakarest] the table itself: Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot), 9
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0x946, 0x28
; [nakarest] naka_debug_naming+0x96e  +0x96e..+0xa40 (0xeb346c, 210 B)
; [nakarest] the table itself: ResName slot 0x300 (table 0xeb346c, 51 entries, InitializeRoot),
; [nakarest] 51 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0x96E, 0xD2
; [nakarest] naka_debug_naming+0xa40  +0xa40..+0xb2c (0xeb353e, 236 B)
; [nakarest] name strings, entries 0-50 of ResName slot 0x300 (table 0xeb346c, 51 entries,
; [nakarest] InitializeRoot) (names for Viewable slot 0x0): "", "MemDumpWindow", "", "", "", "",
; [nakarest] ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xA40, 0xEC
; [nakarest] naka_debug_naming+0xb2c  +0xb2c..+0xb56 (0xeb362a, 42 B)
; [nakarest] the table itself: ResName slot 0x3ff (table 0xeb362a, 9 entries, InitializeRoot), 9
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0xB2C, 0x2A
; [nakarest] naka_debug_naming+0xb56  +0xb56..+0xb9a (0xeb3654, 68 B)
; [nakarest] name strings, entries 0-8 of ResName slot 0x3ff (table 0xeb362a, 9 entries,
; [nakarest] InitializeRoot) (names for Viewable slot 0xff): "", "CheckWall", "", "",
; [nakarest] "CheckNaming", "", ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xB56, 0x44
; [nakarest] naka_debug_naming+0xb9a  +0xb9a..+0xbd2 (0xeb3698, 56 B)
; [nakarest] the table itself: MainFunction slot 0x140 (table 0xeb3698, 13 entries,
; [nakarest] InitializeRoot), 13 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0xB9A, 0x38
; [nakarest] naka_debug_naming+0xbd2  +0xbd2..+0xc0c (0xeb36d0, 58 B)
; [nakarest] the table itself: MainFunction slot 0x440 (table 0xeb36d0, 13 entries,
; [nakarest] InitializeRoot), 13 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_debug_naming.bin", 0xBD2, 0x3A
; [nakarest] naka_debug_naming+0xc0c  +0xc0c..+0x10e0 (0xeb370a, 1236 B)
; [nakarest] name strings, entries 0-12 of MainFunction slot 0x440 (table 0xeb36d0, 13 entries,
; [nakarest] InitializeRoot) (names for MainFunction slot 0x140): "MainTaskControl",
; [nakarest] "DirmdTitleFunc", "MainTrSwControl", "CheckTitleFunc", "MainRamControl",
; [nakarest] "MainBitControl", ....
	.incbin "includes/generated/naka_debug_naming.bin", 0xC0C, 0x4D4
; [nakarest] NakaColor_Palette1  +0x10e0..+0x14e0 (0xeb3bde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb3bde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette1`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef58c).
NakaColor_Palette1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x10E0, 0x400
; [nakarest] NakaColor_Palette2  +0x14e0..+0x18e0 (0xeb3fde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb3fde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette2`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef588).
NakaColor_Palette2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x14E0, 0x400
; [nakarest] NakaColor_Palette3  +0x18e0..+0x1ce0 (0xeb43de, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb43de not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette3`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef59c).
NakaColor_Palette3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x18E0, 0x400
; [nakarest] NakaColor_Palette4  +0x1ce0..+0x20e0 (0xeb47de, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb47de not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette4`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef598).
NakaColor_Palette4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x1CE0, 0x400
; [nakarest] NakaColor_Palette5  +0x20e0..+0x24e0 (0xeb4bde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb4bde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette5`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef594).
NakaColor_Palette5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x20E0, 0x400
; [nakarest] NakaColor_Palette6  +0x24e0..+0x28e0 (0xeb4fde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb4fde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette6`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef590).
NakaColor_Palette6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x24E0, 0x400
; [nakarest] NakaColor_Palette7  +0x28e0..+0x2ce0 (0xeb53de, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb53de not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette7`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef5ac).
NakaColor_Palette7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x28E0, 0x400
; [nakarest] NakaColor_Palette8  +0x2ce0..+0x30e0 (0xeb57de, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb57de not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette8`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef5a8).
NakaColor_Palette8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x2CE0, 0x400
; [nakarest] NakaColor_Palette9  +0x30e0..+0x34e0 (0xeb5bde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb5bde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette9`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef5a4).
NakaColor_Palette9:
	.incbin "includes/generated/naka_debug_naming.bin", 0x30E0, 0x400
; [nakarest] NakaColor_Palette10  +0x34e0..+0x38e0 (0xeb5fde, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb5fde not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_Palette10`); 1 data
; [nakarest] word in Naka_DrawbarReg_Table (at 0xeef5a0).
NakaColor_Palette10:
	.incbin "includes/generated/naka_debug_naming.bin", 0x34E0, 0x400
; [nakarest] NakaColor_PaletteBlank  +0x38e0..+0x3ce0 (0xeb63de, 1024 B)
; [nakarest] purpose not established: layout of 1024 B at 0xeb63de not derived; readers below
; [nakarest] Readers: source references Naka_DrawbarReg_Table
; [nakarest] (ui_widgets/sequencer_channel_containers.s: `.long NakaColor_PaletteBlank`); 2 data
; [nakarest] words in Naka_DrawbarReg_Table (at 0xeef5b0, 0xeef5b4).
NakaColor_PaletteBlank:
	.incbin "includes/generated/naka_debug_naming.bin", 0x38E0, 0x400
; [nakarest] NakaProp_FontEntry0  +0x3ce0..+0x3cf4 (0xeb67de, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb67de not derived; readers below
; [nakarest] Readers: 3 data words in NakaInst_IT_Off_0x8 (at 0xeb7698, 0xeb76a4, 0xeb77dc),
; [nakarest] which is read by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa,
; [nakarest] (NakaInst_IT_Off_0x8:24)`).
NakaProp_FontEntry0:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CE0, 0x14
; [nakarest] NakaProp_FontEntry1  +0x3cf4..+0x3d08 (0xeb67f2, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb67f2 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb76b0, 0xeb76bc), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_FontEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CF4, 0x14
; [nakarest] NakaProp_FontEntry2  +0x3d08..+0x3d1c (0xeb6806, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb6806 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb76c8, 0xeb76d4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_FontEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D08, 0x14
; [nakarest] NakaInst_False  +0x3d1c..+0x3d4c (0xeb681a, 48 B)
; [nakarest] purpose not established: layout of 48 B at 0xeb681a not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb76e0, 0xeb76ec), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_False:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1C, 0x30
; [nakarest] NakaProp_BoolEntry1  +0x3d4c..+0x3d60 (0xeb684a, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb684a not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb76f8, 0xeb7704), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D4C, 0x14
; [nakarest] NakaProp_BoolEntry2  +0x3d60..+0x3d74 (0xeb685e, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb685e not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7710, 0xeb771c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D60, 0x14
; [nakarest] NakaProp_BoolEntry3  +0x3d74..+0x3d88 (0xeb6872, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb6872 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7728, 0xeb7734), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D74, 0x14
; [nakarest] NakaProp_BoolEntry4  +0x3d88..+0x3d9c (0xeb6886, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb6886 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7740, 0xeb774c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D88, 0x14
; [nakarest] NakaProp_BoolEntry5  +0x3d9c..+0x3db0 (0xeb689a, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb689a not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7758, 0xeb7764), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D9C, 0x14
; [nakarest] NakaProp_BoolEntry6  +0x3db0..+0x3dc4 (0xeb68ae, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb68ae not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7770, 0xeb777c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DB0, 0x14
; [nakarest] NakaProp_BoolEntry7  +0x3dc4..+0x3dd8 (0xeb68c2, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb68c2 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7788, 0xeb7794), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DC4, 0x14
; [nakarest] NakaProp_BoolEntry8  +0x3dd8..+0x3dec (0xeb68d6, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb68d6 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb77a0, 0xeb77ac), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BoolEntry8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DD8, 0x14
; [nakarest] NakaProp_CFlagEntry  +0x3dec..+0x3e24 (0xeb68ea, 56 B)
; [nakarest] purpose not established: layout of 56 B at 0xeb68ea not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb77b8, 0xeb77c4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_CFlagEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DEC, 0x38
; [nakarest] NakaProp_VisFlag_Header  +0x3e24..+0x3e2e (0xeb6922, 10 B)
; [nakarest] purpose not established: layout of 10 B at 0xeb6922 not derived; readers below
; [nakarest] Readers: 1 data word in NakaInst_IT_Off_0x8 (at 0xeb77d0), which is read by
; [nakarest] ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_VisFlag_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E24, 0xA
; [nakarest] NakaProp_VisFlag_Chain  +0x3e2e..+0x40d2 (0xeb692c, 676 B)
; [nakarest] purpose not established: layout of 676 B at 0xeb692c not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb77e8, 0xeb77f4), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_VisFlag_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E2E, 0x2A4
; [nakarest] NakaProp_BorderDefs  +0x40d2..+0x426e (0xeb6bd0, 412 B)
; [nakarest] purpose not established: layout of 412 B at 0xeb6bd0 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7800, 0xeb780c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_BorderDefs:
	.incbin "includes/generated/naka_debug_naming.bin", 0x40D2, 0x19C
; [nakarest] NakaProp_Align_Header  +0x426e..+0x4282 (0xeb6d6c, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb6d6c not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7818, 0xeb7824), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_Align_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x426E, 0x14
; [nakarest] NakaProp_Align_PtrEntry  +0x4282..+0x42d8 (0xeb6d80, 86 B)
; [nakarest] purpose not established: layout of 86 B at 0xeb6d80 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7830, 0xeb783c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_Align_PtrEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x4282, 0x56
; [nakarest] NakaProp_EditSwitch_Chain  +0x42d8..+0x457c (0xeb6dd6, 676 B)
; [nakarest] purpose not established: layout of 676 B at 0xeb6dd6 not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7848, 0xeb7854), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_EditSwitch_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x42D8, 0x2A4
; [nakarest] NakaInst_LM_RightDown  +0x457c..+0x45dc (0xeb707a, 96 B)
; [nakarest] purpose not established: layout of 96 B at 0xeb707a not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7860, 0xeb786c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaInst_LM_RightDown:
	.incbin "includes/generated/naka_debug_naming.bin", 0x457C, 0x60
; [nakarest] NakaProp_Frame_Header  +0x45dc..+0x45f0 (0xeb70da, 20 B)
; [nakarest] purpose not established: layout of 20 B at 0xeb70da not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7878, 0xeb7884), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_Frame_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45DC, 0x14
; [nakarest] NakaProp_Frame_Chain  +0x45f0..+0x46c0 (0xeb70ee, 208 B)
; [nakarest] purpose not established: layout of 208 B at 0xeb70ee not derived; readers below
; [nakarest] Readers: 2 data words in NakaInst_IT_Off_0x8 (at 0xeb7890, 0xeb789c), which is read
; [nakarest] by ExitWindow_OK (ui/ui_widget_defs.s: `lda xwa, (NakaInst_IT_Off_0x8:24)`).
NakaProp_Frame_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45F0, 0xD0
; External label offsets within the binary blob above.
