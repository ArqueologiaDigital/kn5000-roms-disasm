
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
; [nakarest] widget record, element 2 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot): "Panel Simulator
; [nakarest] for HK" (Label.str of element 2). widget record, element 3 of Viewable slot 0x0
; [nakarest] (table 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"): AcTitleMenu (54
; [nakarest] B). text the records point at, in Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot): "CHECK TITLE" (AcTitleMenu.str of element 3). widget records,
; [nakarest] elements 4-5 of Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot)
; [nakarest] ("PanelSimulator"): IvExitMode (26 B), AcWindowMenu (54 B). text the records point
; [nakarest] at, in Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot): "DEBUG
; [nakarest] WINDOW" (AcWindowMenu.str of element 5). widget records, elements 6-8 of Viewable
; [nakarest] slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"): Screen
; [nakarest] (34 B), Window (36 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x0 (table 0xeb3374, 51 entries, InitializeRoot): "DEBUG TIME !" (Label.str of
; [nakarest] element 8). widget records, elements 9-12 of Viewable slot 0x0 (table 0xeb3374, 51
; [nakarest] entries, InitializeRoot) ("PanelSimulator"): DbDebugMenu (46 B), AcNamingWindow (36
; [nakarest] B), AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x0 (table 0xeb3374, 51 entries, InitializeRoot): "DEL" (Label.str of element 12).
; [nakarest] widget records, elements 13-14 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot): "INS" (Label.str of element 14). widget records, elements 15-16 of
; [nakarest] Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"):
; [nakarest] AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable slot 0x0
; [nakarest] (table 0xeb3374, 51 entries, InitializeRoot): "CLR" (Label.str of element 16).
; [nakarest] widget records, elements 17-18 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot): "~8d ~8b" (Label.str of element 18). widget records, elements
; [nakarest] 19-21 of Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot)
; [nakarest] ("PanelSimulator"): AcIndexEditSw (40 B) x2, Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0x0 (table 0xeb3374, 51 entries, InitializeRoot): "POSITION"
; [nakarest] (Label.str of element 21). widget record, element 22 of Viewable slot 0x0 (table
; [nakarest] 0xeb3374, 51 entries, InitializeRoot) ("PanelSimulator"): PsCursorBox (40 B).
NakaDbg_PanelSimTitle:
	.incbin "includes/generated/naka_debug_naming.bin", 0x0, 0x37C
; [nakarest] NakaDbg_LowerCaseChars  +0x37c..+0x380 (0xeb2e7a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xeb2e7a that no registered NAKA table points into
NakaDbg_LowerCaseChars:
	.incbin "includes/generated/naka_debug_naming.bin", 0x37C, 0x4
; [nakarest] NakaDbg_LowerCaseChars2  +0x380..+0x704 (0xeb2e7e, 900 B)
; [nakarest] purpose not established: 12 bytes at 0xeb2e7e that no registered NAKA table points into
; [nakarest] widget records, elements 26-50 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): AcIndexEditSw (40 B) x3, PsParaBox (36 B),
; [nakarest] Window (36 B) x3, DbMemo (22 B), AcTrackSwitch (36 B) x16, DbMemoryDump (26 B).
NakaDbg_LowerCaseChars2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x380, 0x384
; [nakarest] naka_debug_naming+0x704  +0x704..+0x876 (0xeb3202, 370 B)
; [nakarest] widget record, element 0 of Viewable slot 0xff (table 0xeb3444, 9 entries,
; [nakarest] InitializeRoot) ("CheckTitle"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot): "CHECK TITLE"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0xff
; [nakarest] (table 0xeb3444, 9 entries, InitializeRoot) ("CheckTitle"): IvExitScreen (26 B),
; [nakarest] AcScreenMenu (54 B). text the records point at, in Viewable slot 0xff (table
; [nakarest] 0xeb3444, 9 entries, InitializeRoot): "Naming" (AcScreenMenu.str of element 2).
; [nakarest] widget record, element 3 of Viewable slot 0xff (table 0xeb3444, 9 entries,
; [nakarest] InitializeRoot) ("CheckTitle"): AcScreenMenu (54 B). text the records point at, in
; [nakarest] Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot): "Wall"
; [nakarest] (AcScreenMenu.str of element 3). widget record, element 4 of Viewable slot 0xff
; [nakarest] (table 0xeb3444, 9 entries, InitializeRoot) ("CheckTitle"): TtlScreen (42 B). text
; [nakarest] the records point at, in Viewable slot 0xff (table 0xeb3444, 9 entries,
; [nakarest] InitializeRoot): "Check Naming" (TtlScreen.title of element 4). widget records,
; [nakarest] elements 5-8 of Viewable slot 0xff (table 0xeb3444, 9 entries, InitializeRoot)
; [nakarest] ("CheckTitle"): IvNaming (26 B), IvExitScreen (26 B) x2, Screen (34 B).
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
; [nakarest] purpose not established: 1024 bytes at 0xeb3bde that no registered NAKA table points into
NakaColor_Palette1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x10E0, 0x400
; [nakarest] NakaColor_Palette2  +0x14e0..+0x18e0 (0xeb3fde, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb3fde that no registered NAKA table points into
NakaColor_Palette2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x14E0, 0x400
; [nakarest] NakaColor_Palette3  +0x18e0..+0x1ce0 (0xeb43de, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb43de that no registered NAKA table points into
NakaColor_Palette3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x18E0, 0x400
; [nakarest] NakaColor_Palette4  +0x1ce0..+0x20e0 (0xeb47de, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb47de that no registered NAKA table points into
NakaColor_Palette4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x1CE0, 0x400
; [nakarest] NakaColor_Palette5  +0x20e0..+0x24e0 (0xeb4bde, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb4bde that no registered NAKA table points into
NakaColor_Palette5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x20E0, 0x400
; [nakarest] NakaColor_Palette6  +0x24e0..+0x28e0 (0xeb4fde, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb4fde that no registered NAKA table points into
NakaColor_Palette6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x24E0, 0x400
; [nakarest] NakaColor_Palette7  +0x28e0..+0x2ce0 (0xeb53de, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb53de that no registered NAKA table points into
NakaColor_Palette7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x28E0, 0x400
; [nakarest] NakaColor_Palette8  +0x2ce0..+0x30e0 (0xeb57de, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb57de that no registered NAKA table points into
NakaColor_Palette8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x2CE0, 0x400
; [nakarest] NakaColor_Palette9  +0x30e0..+0x34e0 (0xeb5bde, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb5bde that no registered NAKA table points into
NakaColor_Palette9:
	.incbin "includes/generated/naka_debug_naming.bin", 0x30E0, 0x400
; [nakarest] NakaColor_Palette10  +0x34e0..+0x38e0 (0xeb5fde, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb5fde that no registered NAKA table points into
NakaColor_Palette10:
	.incbin "includes/generated/naka_debug_naming.bin", 0x34E0, 0x400
; [nakarest] NakaColor_PaletteBlank  +0x38e0..+0x3ce0 (0xeb63de, 1024 B)
; [nakarest] purpose not established: 1024 bytes at 0xeb63de that no registered NAKA table points into
NakaColor_PaletteBlank:
	.incbin "includes/generated/naka_debug_naming.bin", 0x38E0, 0x400
; [nakarest] NakaProp_FontEntry0  +0x3ce0..+0x3cf4 (0xeb67de, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb67de that no registered NAKA table points into
NakaProp_FontEntry0:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CE0, 0x14
; [nakarest] NakaProp_FontEntry1  +0x3cf4..+0x3d08 (0xeb67f2, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb67f2 that no registered NAKA table points into
NakaProp_FontEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CF4, 0x14
; [nakarest] NakaProp_FontEntry2  +0x3d08..+0x3d1c (0xeb6806, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb6806 that no registered NAKA table points into
NakaProp_FontEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D08, 0x14
; [nakarest] NakaInst_False  +0x3d1c..+0x3d4c (0xeb681a, 48 B)
; [nakarest] purpose not established: 48 bytes at 0xeb681a that no registered NAKA table points into
NakaInst_False:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1C, 0x30
; [nakarest] NakaProp_BoolEntry1  +0x3d4c..+0x3d60 (0xeb684a, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb684a that no registered NAKA table points into
NakaProp_BoolEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D4C, 0x14
; [nakarest] NakaProp_BoolEntry2  +0x3d60..+0x3d74 (0xeb685e, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb685e that no registered NAKA table points into
NakaProp_BoolEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D60, 0x14
; [nakarest] NakaProp_BoolEntry3  +0x3d74..+0x3d88 (0xeb6872, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb6872 that no registered NAKA table points into
NakaProp_BoolEntry3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D74, 0x14
; [nakarest] NakaProp_BoolEntry4  +0x3d88..+0x3d9c (0xeb6886, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb6886 that no registered NAKA table points into
NakaProp_BoolEntry4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D88, 0x14
; [nakarest] NakaProp_BoolEntry5  +0x3d9c..+0x3db0 (0xeb689a, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb689a that no registered NAKA table points into
NakaProp_BoolEntry5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D9C, 0x14
; [nakarest] NakaProp_BoolEntry6  +0x3db0..+0x3dc4 (0xeb68ae, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb68ae that no registered NAKA table points into
NakaProp_BoolEntry6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DB0, 0x14
; [nakarest] NakaProp_BoolEntry7  +0x3dc4..+0x3dd8 (0xeb68c2, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb68c2 that no registered NAKA table points into
NakaProp_BoolEntry7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DC4, 0x14
; [nakarest] NakaProp_BoolEntry8  +0x3dd8..+0x3dec (0xeb68d6, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb68d6 that no registered NAKA table points into
NakaProp_BoolEntry8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DD8, 0x14
; [nakarest] NakaProp_CFlagEntry  +0x3dec..+0x3e24 (0xeb68ea, 56 B)
; [nakarest] purpose not established: 56 bytes at 0xeb68ea that no registered NAKA table points into
NakaProp_CFlagEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DEC, 0x38
; [nakarest] NakaProp_VisFlag_Header  +0x3e24..+0x3e2e (0xeb6922, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xeb6922 that no registered NAKA table points into
NakaProp_VisFlag_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E24, 0xA
; [nakarest] NakaProp_VisFlag_Chain  +0x3e2e..+0x40d2 (0xeb692c, 676 B)
; [nakarest] purpose not established: 676 bytes at 0xeb692c that no registered NAKA table points into
NakaProp_VisFlag_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E2E, 0x2A4
; [nakarest] NakaProp_BorderDefs  +0x40d2..+0x426e (0xeb6bd0, 412 B)
; [nakarest] purpose not established: 412 bytes at 0xeb6bd0 that no registered NAKA table points into
NakaProp_BorderDefs:
	.incbin "includes/generated/naka_debug_naming.bin", 0x40D2, 0x19C
; [nakarest] NakaProp_Align_Header  +0x426e..+0x4282 (0xeb6d6c, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb6d6c that no registered NAKA table points into
NakaProp_Align_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x426E, 0x14
; [nakarest] NakaProp_Align_PtrEntry  +0x4282..+0x42d8 (0xeb6d80, 86 B)
; [nakarest] purpose not established: 86 bytes at 0xeb6d80 that no registered NAKA table points into
NakaProp_Align_PtrEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x4282, 0x56
; [nakarest] NakaProp_EditSwitch_Chain  +0x42d8..+0x457c (0xeb6dd6, 676 B)
; [nakarest] purpose not established: 676 bytes at 0xeb6dd6 that no registered NAKA table points into
NakaProp_EditSwitch_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x42D8, 0x2A4
; [nakarest] NakaInst_LM_RightDown  +0x457c..+0x45dc (0xeb707a, 96 B)
; [nakarest] purpose not established: 96 bytes at 0xeb707a that no registered NAKA table points into
NakaInst_LM_RightDown:
	.incbin "includes/generated/naka_debug_naming.bin", 0x457C, 0x60
; [nakarest] NakaProp_Frame_Header  +0x45dc..+0x45f0 (0xeb70da, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xeb70da that no registered NAKA table points into
NakaProp_Frame_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45DC, 0x14
; [nakarest] NakaProp_Frame_Chain  +0x45f0..+0x46c0 (0xeb70ee, 208 B)
; [nakarest] purpose not established: 208 bytes at 0xeb70ee that no registered NAKA table points into
NakaProp_Frame_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45F0, 0xD0
; External label offsets within the binary blob above.
