
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
; already existed. A widget record starts TT 00 6x 01 (TT = type byte);
; +4 parent, +6 first child, +8 next sibling, +10 previous sibling are
; element indices of the same table (0xffff = none), checked against
; each other for every table (the Links result per table). Name strings
; are NUL-terminated and 0xff-padded to even length. The first word of a
; widget record is its CLASS ID 0x016S_KKKK: ClassProc
; (ui/ui_widget_defs.s) takes (id >> 16) & 0xfff as a registry slot --
; the Class table that RegObjTable 0x1600004 put there -- and 0x18 * (id
; & 0xffff) into it. Each class definition gives the instance size (+8
; allsize), and all 3,340 in-ROM widget records of v10 resolve to a
; class and are at least that far apart (THE CLASS SYSTEM,
; scripts/analysis/nakarest_objtab_map.py).
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaDbg_PanelSimTitle
; NakaDbg_PanelSimTitle  --  naka_debug_naming +0x0..+0x37c (ROM 0xeb2afe..0xeb2e7a), 892 bytes
; Widget records of elements 2-22 of Viewable slot 0x0 (table 0xeb3374,
; 51 entries, InitializeRoot), element 0 "PanelSimulator"; classes:
; Label (32 B, id 0x0160002b) x7, AcTitleMenu (54 B, id 0x0160001d),
; IvExitMode (26 B, id 0x01600048), AcWindowMenu (54 B, id 0x01600042),
; Screen (34 B, id 0x01600033), Window (36 B, id 0x01600035),
; DbDebugMenu (46 B, id 0x01600057), AcNamingWindow (36 B, id
; 0x0160004b), AcIndexEditSw (40 B, id 0x0160001f) x6, PsCursorBox (40
; B, id 0x0160004c).
; -----------------------------------------------------------------------------
NakaDbg_PanelSimTitle:
	.incbin "includes/generated/naka_debug_naming.bin", 0x0, 0x37C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaDbg_LowerCaseChars
; NakaDbg_LowerCaseChars  --  naka_debug_naming +0x37c..+0x380 (ROM 0xeb2e7a..0xeb2e7e), 4 bytes
; No RegObjTabl-registered table points at the start of these 4 bytes
; (0xeb2e7a..0xeb2e7e); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaDbg_LowerCaseChars:
	.incbin "includes/generated/naka_debug_naming.bin", 0x37C, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaDbg_LowerCaseChars2
; NakaDbg_LowerCaseChars2  --  naka_debug_naming +0x380..+0x704 (ROM 0xeb2e7e..0xeb3202), 900 bytes
; No RegObjTabl-registered table points at the start of these 12 bytes
; (0xeb2e7e..0xeb2e8a); purpose not established by that route. Widget
; records of elements 26-50 of Viewable slot 0x0 (table 0xeb3374, 51
; entries, InitializeRoot), element 0 "PanelSimulator"; classes:
; AcIndexEditSw (40 B, id 0x0160001f) x3, PsParaBox (36 B, id
; 0x01600012), Window (36 B, id 0x01600035) x3, DbMemo (22 B, id
; 0x01600046), AcTrackSwitch (36 B, id 0x01600059) x16, DbMemoryDump (26
; B, id 0x0160005d).
; -----------------------------------------------------------------------------
NakaDbg_LowerCaseChars2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x380, 0x384
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0x704
; naka_debug_naming+0x704  --  naka_debug_naming +0x704..+0x876 (ROM 0xeb3202..0xeb3374), 370 bytes
; Widget records of elements 0-8 of Viewable slot 0xff (table 0xeb3444,
; 9 entries, InitializeRoot), element 0 "CheckTitle"; classes: TtlScreen
; (42 B, id 0x01600034) x2, IvExitScreen (26 B, id 0x01600049) x3,
; AcScreenMenu (54 B, id 0x01600041) x2, IvNaming (26 B, id 0x0160004d),
; Screen (34 B, id 0x01600033).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0x704, 0x172
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0x876
; naka_debug_naming+0x876  --  naka_debug_naming +0x876..+0x946 (ROM 0xeb3374..0xeb3444), 208 bytes
; The table itself: Viewable slot 0x0 (table 0xeb3374, 51 entries,
; InitializeRoot) -- 51 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0x876, 0xD0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0x946
; naka_debug_naming+0x946  --  naka_debug_naming +0x946..+0x96e (ROM 0xeb3444..0xeb346c), 40 bytes
; The table itself: Viewable slot 0xff (table 0xeb3444, 9 entries,
; InitializeRoot) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0x946, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0x96e
; naka_debug_naming+0x96e  --  naka_debug_naming +0x96e..+0xa40 (ROM 0xeb346c..0xeb353e), 210 bytes
; The table itself: ResName slot 0x300 (table 0xeb346c, 51 entries,
; InitializeRoot) -- 51 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0x96E, 0xD2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xa40
; naka_debug_naming+0xa40  --  naka_debug_naming +0xa40..+0xb2c (ROM 0xeb353e..0xeb362a), 236 bytes
; Name strings of elements 0-50 of ResName slot 0x300 (table 0xeb346c,
; 51 entries, InitializeRoot), names for Viewable slot 0x0: "",
; "MemDumpWindow", "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xA40, 0xEC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xb2c
; naka_debug_naming+0xb2c  --  naka_debug_naming +0xb2c..+0xb56 (ROM 0xeb362a..0xeb3654), 42 bytes
; The table itself: ResName slot 0x3ff (table 0xeb362a, 9 entries,
; InitializeRoot) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xB2C, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xb56
; naka_debug_naming+0xb56  --  naka_debug_naming +0xb56..+0xb9a (ROM 0xeb3654..0xeb3698), 68 bytes
; Name strings of elements 0-8 of ResName slot 0x3ff (table 0xeb362a, 9
; entries, InitializeRoot), names for Viewable slot 0xff: "",
; "CheckWall", "", "", "CheckNaming", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xB56, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xb9a
; naka_debug_naming+0xb9a  --  naka_debug_naming +0xb9a..+0xbd2 (ROM 0xeb3698..0xeb36d0), 56 bytes
; The table itself: MainFunction slot 0x140 (table 0xeb3698, 13 entries,
; InitializeRoot) -- 13 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xB9A, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xbd2
; naka_debug_naming+0xbd2  --  naka_debug_naming +0xbd2..+0xc0c (ROM 0xeb36d0..0xeb370a), 58 bytes
; The table itself: MainFunction slot 0x440 (table 0xeb36d0, 13 entries,
; InitializeRoot) -- 13 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xBD2, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_debug_naming+0xc0c
; naka_debug_naming+0xc0c  --  naka_debug_naming +0xc0c..+0x10e0 (ROM 0xeb370a..0xeb3bde), 1236 bytes
; Name strings of elements 0-12 of MainFunction slot 0x440 (table
; 0xeb36d0, 13 entries, InitializeRoot), names for MainFunction slot
; 0x140: "MainTaskControl", "DirmdTitleFunc", "MainTrSwControl",
; "CheckTitleFunc", "MainRamControl", "MainBitControl", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_debug_naming.bin", 0xC0C, 0x4D4
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette1
; NakaColor_Palette1  --  naka_debug_naming +0x10e0..+0x14e0 (ROM 0xeb3bde..0xeb3fde), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb3bde..0xeb3fde); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x10E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette2
; NakaColor_Palette2  --  naka_debug_naming +0x14e0..+0x18e0 (ROM 0xeb3fde..0xeb43de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb3fde..0xeb43de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x14E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette3
; NakaColor_Palette3  --  naka_debug_naming +0x18e0..+0x1ce0 (ROM 0xeb43de..0xeb47de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb43de..0xeb47de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x18E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette4
; NakaColor_Palette4  --  naka_debug_naming +0x1ce0..+0x20e0 (ROM 0xeb47de..0xeb4bde), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb47de..0xeb4bde); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x1CE0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette5
; NakaColor_Palette5  --  naka_debug_naming +0x20e0..+0x24e0 (ROM 0xeb4bde..0xeb4fde), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb4bde..0xeb4fde); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x20E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette6
; NakaColor_Palette6  --  naka_debug_naming +0x24e0..+0x28e0 (ROM 0xeb4fde..0xeb53de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb4fde..0xeb53de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x24E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette7
; NakaColor_Palette7  --  naka_debug_naming +0x28e0..+0x2ce0 (ROM 0xeb53de..0xeb57de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb53de..0xeb57de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x28E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette8
; NakaColor_Palette8  --  naka_debug_naming +0x2ce0..+0x30e0 (ROM 0xeb57de..0xeb5bde), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb57de..0xeb5bde); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x2CE0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette9
; NakaColor_Palette9  --  naka_debug_naming +0x30e0..+0x34e0 (ROM 0xeb5bde..0xeb5fde), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb5bde..0xeb5fde); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette9:
	.incbin "includes/generated/naka_debug_naming.bin", 0x30E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_Palette10
; NakaColor_Palette10  --  naka_debug_naming +0x34e0..+0x38e0 (ROM 0xeb5fde..0xeb63de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb5fde..0xeb63de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_Palette10:
	.incbin "includes/generated/naka_debug_naming.bin", 0x34E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaColor_PaletteBlank
; NakaColor_PaletteBlank  --  naka_debug_naming +0x38e0..+0x3ce0 (ROM 0xeb63de..0xeb67de), 1024 bytes
; No RegObjTabl-registered table points at the start of these 1024 bytes
; (0xeb63de..0xeb67de); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaColor_PaletteBlank:
	.incbin "includes/generated/naka_debug_naming.bin", 0x38E0, 0x400
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_FontEntry0
; NakaProp_FontEntry0  --  naka_debug_naming +0x3ce0..+0x3cf4 (ROM 0xeb67de..0xeb67f2), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb67de..0xeb67f2); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_FontEntry0:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CE0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_FontEntry1
; NakaProp_FontEntry1  --  naka_debug_naming +0x3cf4..+0x3d08 (ROM 0xeb67f2..0xeb6806), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb67f2..0xeb6806); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_FontEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3CF4, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_FontEntry2
; NakaProp_FontEntry2  --  naka_debug_naming +0x3d08..+0x3d1c (ROM 0xeb6806..0xeb681a), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb6806..0xeb681a); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_FontEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D08, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_False
; NakaInst_False  --  naka_debug_naming +0x3d1c..+0x3d4c (ROM 0xeb681a..0xeb684a), 48 bytes
; No RegObjTabl-registered table points at the start of these 48 bytes
; (0xeb681a..0xeb684a); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaInst_False:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D1C, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry1
; NakaProp_BoolEntry1  --  naka_debug_naming +0x3d4c..+0x3d60 (ROM 0xeb684a..0xeb685e), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb684a..0xeb685e); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry1:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D4C, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry2
; NakaProp_BoolEntry2  --  naka_debug_naming +0x3d60..+0x3d74 (ROM 0xeb685e..0xeb6872), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb685e..0xeb6872); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry2:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D60, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry3
; NakaProp_BoolEntry3  --  naka_debug_naming +0x3d74..+0x3d88 (ROM 0xeb6872..0xeb6886), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb6872..0xeb6886); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry3:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D74, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry4
; NakaProp_BoolEntry4  --  naka_debug_naming +0x3d88..+0x3d9c (ROM 0xeb6886..0xeb689a), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb6886..0xeb689a); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry4:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D88, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry5
; NakaProp_BoolEntry5  --  naka_debug_naming +0x3d9c..+0x3db0 (ROM 0xeb689a..0xeb68ae), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb689a..0xeb68ae); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry5:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3D9C, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry6
; NakaProp_BoolEntry6  --  naka_debug_naming +0x3db0..+0x3dc4 (ROM 0xeb68ae..0xeb68c2), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb68ae..0xeb68c2); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry6:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DB0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry7
; NakaProp_BoolEntry7  --  naka_debug_naming +0x3dc4..+0x3dd8 (ROM 0xeb68c2..0xeb68d6), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb68c2..0xeb68d6); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry7:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DC4, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BoolEntry8
; NakaProp_BoolEntry8  --  naka_debug_naming +0x3dd8..+0x3dec (ROM 0xeb68d6..0xeb68ea), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb68d6..0xeb68ea); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BoolEntry8:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DD8, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_CFlagEntry
; NakaProp_CFlagEntry  --  naka_debug_naming +0x3dec..+0x3e24 (ROM 0xeb68ea..0xeb6922), 56 bytes
; No RegObjTabl-registered table points at the start of these 56 bytes
; (0xeb68ea..0xeb6922); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_CFlagEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3DEC, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_VisFlag_Header
; NakaProp_VisFlag_Header  --  naka_debug_naming +0x3e24..+0x3e2e (ROM 0xeb6922..0xeb692c), 10 bytes
; No RegObjTabl-registered table points at the start of these 10 bytes
; (0xeb6922..0xeb692c); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_VisFlag_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E24, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_VisFlag_Chain
; NakaProp_VisFlag_Chain  --  naka_debug_naming +0x3e2e..+0x40d2 (ROM 0xeb692c..0xeb6bd0), 676 bytes
; No RegObjTabl-registered table points at the start of these 676 bytes
; (0xeb692c..0xeb6bd0); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_VisFlag_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x3E2E, 0x2A4
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_BorderDefs
; NakaProp_BorderDefs  --  naka_debug_naming +0x40d2..+0x426e (ROM 0xeb6bd0..0xeb6d6c), 412 bytes
; No RegObjTabl-registered table points at the start of these 412 bytes
; (0xeb6bd0..0xeb6d6c); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_BorderDefs:
	.incbin "includes/generated/naka_debug_naming.bin", 0x40D2, 0x19C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_Align_Header
; NakaProp_Align_Header  --  naka_debug_naming +0x426e..+0x4282 (ROM 0xeb6d6c..0xeb6d80), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb6d6c..0xeb6d80); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_Align_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x426E, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_Align_PtrEntry
; NakaProp_Align_PtrEntry  --  naka_debug_naming +0x4282..+0x42d8 (ROM 0xeb6d80..0xeb6dd6), 86 bytes
; No RegObjTabl-registered table points at the start of these 86 bytes
; (0xeb6d80..0xeb6dd6); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_Align_PtrEntry:
	.incbin "includes/generated/naka_debug_naming.bin", 0x4282, 0x56
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_EditSwitch_Chain
; NakaProp_EditSwitch_Chain  --  naka_debug_naming +0x42d8..+0x457c (ROM 0xeb6dd6..0xeb707a), 676 bytes
; No RegObjTabl-registered table points at the start of these 676 bytes
; (0xeb6dd6..0xeb707a); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_EditSwitch_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x42D8, 0x2A4
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_LM_RightDown
; NakaInst_LM_RightDown  --  naka_debug_naming +0x457c..+0x45dc (ROM 0xeb707a..0xeb70da), 96 bytes
; No RegObjTabl-registered table points at the start of these 96 bytes
; (0xeb707a..0xeb70da); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaInst_LM_RightDown:
	.incbin "includes/generated/naka_debug_naming.bin", 0x457C, 0x60
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_Frame_Header
; NakaProp_Frame_Header  --  naka_debug_naming +0x45dc..+0x45f0 (ROM 0xeb70da..0xeb70ee), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeb70da..0xeb70ee); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_Frame_Header:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45DC, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaProp_Frame_Chain
; NakaProp_Frame_Chain  --  naka_debug_naming +0x45f0..+0x46c0 (ROM 0xeb70ee..0xeb71be), 208 bytes
; No RegObjTabl-registered table points at the start of these 208 bytes
; (0xeb70ee..0xeb71be); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaProp_Frame_Chain:
	.incbin "includes/generated/naka_debug_naming.bin", 0x45F0, 0xD0
; External label offsets within the binary blob above.
