
; Control Menu header widgets (9 widgets: CONTAINER + 7 MENU_ITEMs + TYPE_0x48)
; Source: maincpu/ui_widgets/control_menu_header.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_ctrl_menu_body
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
; Viewable slot 0x41: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xed78f6, 0x41 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x41. Element 0 is named "ControlIni" in ResName slot 0x341. Links:
; all 17 records consistent.
;
; Viewable slot 0x42: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xed793e,
; 0x42 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x42. Element 0 is named "ControlFsw" in ResName slot 0x342. Links:
; all 6 records consistent.
;
; Viewable slot 0x43: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xed795a,
; 0x43 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x43. Element 0 is named "ControlSns" in ResName slot 0x343. Links:
; all 8 records consistent.
;
; Viewable slot 0x44: RegObjTabl 0x1600010, ViewableProc, 0x13,
; 0xed797e, 0x44 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x44. Element 0 is named "" in ResName slot 0x344. Links: all 19
; records consistent.
;
; Viewable slot 0x45: RegObjTabl 0x1600010, ViewableProc, 0x13,
; 0xed79ce, 0x45 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x45. Element 0 is named "" in ResName slot 0x345. Links: all 19
; records consistent.
;
; Viewable slot 0x47: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xed7a22,
; 0x47 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x47. Element 0 is named "ControlSys" in ResName slot 0x347. Links:
; all 7 records consistent.
;
; Viewable slot 0x48: RegObjTabl 0x1600010, ViewableProc, 0x19,
; 0xed7a42, 0x48 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x48. Element 0 is named "" in ResName slot 0x348. Links: all 25
; records consistent.
;
; Viewable slot 0xc0: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xed7aaa,
; 0xc0 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xc0. Element 0 is named "ONETCH" in ResName slot 0x3c0. Links: all
; 4 records consistent.
;
; Viewable slot 0xc1: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xed7abe,
; 0xc1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xc1. Element 0 is named "MUSICSTYL" in ResName slot 0x3c1. Links:
; all 4 records consistent.
;
; Viewable slot 0xc2: RegObjTabl 0x1600010, ViewableProc, 0x14,
; 0xed7ad2, 0xc2 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0xc2. Element 0 is named "MSCTSEL" in ResName slot 0x3c2. Links:
; all 20 records consistent.
;
; Viewable slot 0xc3: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xed7b26, 0xc3 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0xc3. Element 0 is named "MSSCTSEL" in ResName slot 0x3c3. Links:
; all 17 records consistent.
;
; Viewable slot 0xc4: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xed7b6e,
; 0xc4 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0xc4. Element 0 is named "MSSONGLIST" in ResName slot 0x3c4. Links:
; all 8 records consistent.
;
; Viewable slot 0xc5: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xed7b92,
; 0xc5 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0xc5. Element 0 is named "MSSTLSEL" in ResName slot 0x3c5. Links:
; all 7 records consistent.
;
; Viewable slot 0xd0: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xed7bb2,
; 0xd0 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xd0. Element 0 is named "PMBANK" in ResName slot 0x3d0. Links: all
; 6 records consistent.
;
; Viewable slot 0xd1: RegObjTabl 0x1600010, ViewableProc, 0xd, 0xed7bce,
; 0xd1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0xd1. Element 0 is named "PMVIEW" in ResName slot 0x3d1. Links: all
; 13 records consistent.
;
; Viewable slot 0xd2: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xed7c06,
; 0xd2 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0xd2. Element 0 is named "PMNAME" in ResName slot 0x3d2. Links: all
; 7 records consistent.
;
; Viewable slot 0xd3: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xed7c26,
; 0xd3 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0xd3. Element 0 is named "PMBKNAME" in ResName slot 0x3d3. Links:
; all 7 records consistent.
;
; Viewable slot 0xe8: RegObjTabl 0x1600010, ViewableProc, 0x2, 0xed7c46,
; 0xe8 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0xe8. Element 0 is named "SVARI" in ResName slot 0x3e8. Links: all
; 2 records consistent.
;
; Viewable slot 0xe9: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xed7c52,
; 0xe9 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0xe9. Element 0 is named "RVARI" in ResName slot 0x3e9. Links: all
; 3 records consistent.
;
; Viewable slot 0xf4: RegObjTabl 0x1600010, ViewableProc, 0xe, 0xed7c62,
; 0xf4 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 14, table} at 0x27ed2 +
; 14*0xf4. Element 0 is named "" in ResName slot 0x3f4. Links: all 14
; records consistent.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_control_menu_header
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
; Viewable slot 0x40: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xed78ce,
; 0x40 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x40. Element 0 is named "ControlMenu" in ResName slot 0x340.
; Links: all 9 records consistent.
; -----------------------------------------------------------------------------

; [nakarest] naka_control_menu_header+0x0  +0x0..+0x250 (0xed3c96, 592 B)
; [nakarest] widget records, elements 0-8 of Viewable slot 0x40 (table 0xed78ce, 9 entries,
; [nakarest] InitializeToshi) ("ControlMenu"): TtlScreen (42 B), AcTitleMenu (54 B) x7,
; [nakarest] IvExitMode (26 B). 8 texts the records point at (Viewable slot 0x40 (table
; [nakarest] 0xed78ce, 9 entries, InitializeToshi)): "CONTROL MENU" (TtlScreen.title of element
; [nakarest] 0); "INITIAL" (AcTitleMenu.str of element 1); "OVERALL TOUCH SENSITIVITY"
; [nakarest] (AcTitleMenu.str of element 2); "FOOT CONTROLLERS" (AcTitleMenu.str of element 3);
; [nakarest] ....
	.incbin "includes/generated/naka_control_menu_header.bin", 0x0, 0x250

; Control Menu body widgets (184 widgets across all sub-screens)
; Source: maincpu/ui_widgets/naka_ctrl_menu_body.c (C struct with named fields)
; [nakarest] naka_ctrl_menu_body+0x0  +0x0..+0x348 (0xed3ee6, 840 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0x41 (table 0xed78f6, 17 entries,
; [nakarest] InitializeToshi) ("ControlIni"): TtlScreen (42 B) x2, AcIndexWideES (42 B),
; [nakarest] AcListBox (48 B), AcFuncEditSw (44 B) x3, IvShowHide (26 B) x2, AcLanguageText (42
; [nakarest] B) x4, Screen (34 B), Label (32 B), Icon (26 B), Box (26 B). 4 texts the records
; [nakarest] point at (Viewable slot 0x41 (table 0xed78f6, 17 entries, InitializeToshi)):
; [nakarest] "INITIAL" (TtlScreen.title of element 0); "PERFORMANCE | CURRENT PANEL | PART "
; [nakarest] (AcListBox.list of element 2); "INITIAL" (TtlScreen.title of element 6); "INITIAL"
; [nakarest] (Label.str of element 8).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x0, 0x348
; [nakarest] naka_ctrl_menu_body+0x348  +0x348..+0x504 (0xed422e, 444 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0x42 (table 0xed793e, 6 entries,
; [nakarest] InitializeToshi) ("ControlFsw"): TtlScreen (42 B), AcFSWAssGridBox (74 B), Label
; [nakarest] (32 B) x2, AcIndexWideES (42 B) x2. 5 texts the records point at (Viewable slot
; [nakarest] 0x42 (table 0xed793e, 6 entries, InitializeToshi)): "FOOT CONTROLLERS"
; [nakarest] (TtlScreen.title of element 0); "|-|FOOT SWITCH 1 |FOOT SWITCH 2 |FOOT CONT.SW 1|"
; [nakarest] (AcFSWAssGridBox.fixedrow of element 1); " | " (AcFSWAssGridBox.fixedcol of element
; [nakarest] 1); "CONTROLLER" (Label.str of element 2); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x348, 0x1BC
; [nakarest] naka_ctrl_menu_body+0x504  +0x504..+0x710 (0xed43ea, 524 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x43 (table 0xed795a, 8 entries,
; [nakarest] InitializeToshi) ("ControlSns"): TtlScreen (42 B), AcTchSensGridBox (74 B), Label
; [nakarest] (32 B) x4, AcIndexWideES (42 B) x2. 7 texts the records point at (Viewable slot
; [nakarest] 0x43 (table 0xed795a, 8 entries, InitializeToshi)): "OVERALL TOUCH SENSITIVITY"
; [nakarest] (TtlScreen.title of element 0); "| VELOCITY SENSE : |-|| ON/OFF"
; [nakarest] (AcTchSensGridBox.fixedrow of element 1); " | " (AcTchSensGridBox.fixedcol of
; [nakarest] element 1); "INITIAL TOUCH" (Label.str of element 2); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x504, 0x20C
; [nakarest] naka_ctrl_menu_body+0x710  +0x710..+0xa4a (0xed45f6, 826 B)
; [nakarest] widget records, elements 0-18 of Viewable slot 0x44 (table 0xed797e, 19 entries,
; [nakarest] InitializeToshi): MsaModeScreen (52 B) x2, Label (32 B) x8, Icon (26 B) x2, EditSw
; [nakarest] (40 B) x6, IvIntEasySet (24 B). 14 texts the records point at (Viewable slot 0x44
; [nakarest] (table 0xed797e, 19 entries, InitializeToshi)): "MUSIC STYLE ARRANGER MODE"
; [nakarest] (Label.str of element 1); "~7f" (EditSw.str of element 3); "~7f" (EditSw.str of
; [nakarest] element 4); "~7f" (EditSw.str of element 5); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x710, 0x33A
; [nakarest] naka_ctrl_menu_body+0xa4a  +0xa4a..+0xdee (0xed4930, 932 B)
; [nakarest] widget records, elements 0-18 of Viewable slot 0x45 (table 0xed79ce, 19 entries,
; [nakarest] InitializeToshi): TtlScreen (42 B), IvPmemWindowPageCtl (26 B), IvPageControl (28
; [nakarest] B) x2, IvIntEasySet (24 B), Window (36 B) x3, PmemModeBox (44 B), EditSw (40 B) x2,
; [nakarest] Label (32 B) x2, AcLanguageText (42 B) x2, AcPmExpFilterGridBox (74 B),
; [nakarest] AcIndexWideES (42 B) x2, StringBox (38 B). 8 texts the records point at (Viewable
; [nakarest] slot 0x45 (table 0xed79ce, 19 entries, InitializeToshi)): "PANEL MEMORY MODE "
; [nakarest] (TtlScreen.title of element 0); "~7f" (EditSw.str of element 7); "~7f" (EditSw.str
; [nakarest] of element 8); "NORMAL" (Label.str of element 9); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xA4A, 0x3A4
; [nakarest] naka_ctrl_menu_body+0xdee  +0xdee..+0xfb0 (0xed4cd4, 450 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0x47 (table 0xed7a22, 7 entries,
; [nakarest] InitializeToshi) ("ControlSys"): TtlScreen (42 B), AcDispTimeSetGridBox (74 B),
; [nakarest] Label (32 B) x2, AcIndexWideES (42 B) x2, AcFuncEditSw (44 B). 5 texts the records
; [nakarest] point at (Viewable slot 0x47 (table 0xed7a22, 7 entries, InitializeToshi)):
; [nakarest] "DISPLAY TIME OUT" (TtlScreen.title of element 0); "|-|SAVE REMINDER|'COMPLETED'
; [nakarest] MESSAGE|ARE YOU SUR" (AcDispTimeSetGridBox.fixedrow of element 1); " | "
; [nakarest] (AcDispTimeSetGridBox.fixedcol of element 1); "DISPLAY TYPE" (Label.str of element
; [nakarest] 2); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xDEE, 0x1C2
; [nakarest] naka_ctrl_menu_body+0xfb0  +0xfb0..+0x1458 (0xed4e96, 1192 B)
; [nakarest] widget records, elements 0-24 of Viewable slot 0x48 (table 0xed7a42, 25 entries,
; [nakarest] InitializeToshi): TtlScreen (42 B) x2, AcTitleMenu (54 B) x2, AcRamEditBox (58 B)
; [nakarest] x3, Label (32 B) x5, AcFuncEditSw (44 B) x4, AcIndexWideES (42 B), IvShowHide (26
; [nakarest] B) x2, Screen (34 B), Box (26 B), AcLanguageText (42 B) x3, Icon (26 B). 12 texts
; [nakarest] the records point at (Viewable slot 0x48 (table 0xed7a42, 25 entries,
; [nakarest] InitializeToshi)): "WALLPAPER SETTING" (TtlScreen.title of element 0); "LOAD"
; [nakarest] (AcTitleMenu.str of element 1); "WALLPAPER SETTING" (TtlScreen.title of element 2);
; [nakarest] "LOAD" (AcTitleMenu.str of element 3); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xFB0, 0x4A8
; [nakarest] naka_ctrl_menu_body+0x1458  +0x1458..+0x14fa (0xed533e, 162 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0xc0 (table 0xed7aaa, 4 entries,
; [nakarest] InitializeToshi) ("ONETCH"): TtlScreen (42 B), Label (32 B), AcRamBox (44 B),
; [nakarest] IvExitMode (26 B). 2 texts the records point at (Viewable slot 0xc0 (table
; [nakarest] 0xed7aaa, 4 entries, InitializeToshi)): "" (TtlScreen.title of element 0); "ONE
; [nakarest] TOUCH PLAY" (Label.str of element 1).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1458, 0xA2
; [nakarest] naka_ctrl_menu_body+0x14fa  +0x14fa..+0x15dc (0xed53e0, 226 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0xc1 (table 0xed7abe, 4 entries,
; [nakarest] InitializeToshi) ("MUSICSTYL"): TtlScreen (42 B), AcTitleMenu (54 B) x2, IvExitMode
; [nakarest] (26 B). 3 texts the records point at (Viewable slot 0xc1 (table 0xed7abe, 4
; [nakarest] entries, InitializeToshi)): "MUSIC STYLIST" (TtlScreen.title of element 0); "STYLE
; [nakarest] EXPLORER" (AcTitleMenu.str of element 1); "STYLE ALPHABETICAL" (AcTitleMenu.str of
; [nakarest] element 3).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x14FA, 0xE2
; [nakarest] naka_ctrl_menu_body+0x15dc  +0x15dc..+0x19d0 (0xed54c2, 1012 B)
; [nakarest] widget records, elements 0-19 of Viewable slot 0xc2 (table 0xed7ad2, 20 entries,
; [nakarest] InitializeToshi) ("MSCTSEL"): TtlScreen (42 B), IvMstStyleWindowPgCtl (26 B),
; [nakarest] IvPageControl (28 B) x2, Window (36 B) x2, AcMstStyle1GridBox (86 B), AcIndexWideES
; [nakarest] (42 B) x3, VwEditSwBox (44 B) x2, Label (32 B) x5, AcMstStyle1SubGridBox (86 B),
; [nakarest] AcMstStyle2GridBox (102 B), Box (26 B). 14 texts the records point at (Viewable
; [nakarest] slot 0xc2 (table 0xed7ad2, 20 entries, InitializeToshi)): "STYLE EXPLORER"
; [nakarest] (TtlScreen.title of element 0); " | | | | | | | | | " (AcMstStyle1GridBox.fixedrow
; [nakarest] of element 5); "| " (AcMstStyle1GridBox.fixedcol of element 5); "" (VwEditSwBox.str
; [nakarest] of element 7); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x15DC, 0x3F4
; [nakarest] naka_ctrl_menu_body+0x19d0  +0x19d0..+0x1d04 (0xed58b6, 820 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xc3 (table 0xed7b26, 17 entries,
; [nakarest] InitializeToshi) ("MSSCTSEL"): TtlScreen (42 B), IvMstStyleWindowPgCtl (26 B),
; [nakarest] IvPageControl (28 B) x2, Window (36 B) x2, AcMstSong1GridBox (86 B), AcIndexWideES
; [nakarest] (42 B) x2, VwEditSwBox (44 B) x2, Label (32 B) x4, AcMstSong2GridBox (102 B), Box
; [nakarest] (26 B). 11 texts the records point at (Viewable slot 0xc3 (table 0xed7b26, 17
; [nakarest] entries, InitializeToshi)): "SUGGESTED SONG LIST" (TtlScreen.title of element 0); "
; [nakarest] | | | | | | | | | |" (AcMstSong1GridBox.fixedrow of element 5); "| "
; [nakarest] (AcMstSong1GridBox.fixedcol of element 5); "" (VwEditSwBox.str of element 7); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x19D0, 0x334
; [nakarest] naka_ctrl_menu_body+0x1d04  +0x1d04..+0x1eae (0xed5bea, 426 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0xc4 (table 0xed7b6e, 8 entries,
; [nakarest] InitializeToshi) ("MSSONGLIST"): TtlScreen (42 B), AcMstSugAlpGridBox (102 B),
; [nakarest] Label (32 B) x3, AcIndexWideES (42 B), Box (26 B), VwEditSwBox (44 B). 7 texts the
; [nakarest] records point at (Viewable slot 0xc4 (table 0xed7b6e, 8 entries, InitializeToshi)):
; [nakarest] "SUGGESTED SONG LIST" (TtlScreen.title of element 0); " | | | | | | | | | |"
; [nakarest] (AcMstSugAlpGridBox.fixedrow of element 1); "| " (AcMstSugAlpGridBox.fixedcol of
; [nakarest] element 1); "(ALPHBETICAL)" (Label.str of element 2); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1D04, 0x1AA
; [nakarest] naka_ctrl_menu_body+0x1eae  +0x1eae..+0x2022 (0xed5d94, 372 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0xc5 (table 0xed7b92, 7 entries,
; [nakarest] InitializeToshi) ("MSSTLSEL"): TtlScreen (42 B), AcMstStyleAlpGridBox (94 B), Box
; [nakarest] (26 B), Label (32 B) x2, AcIndexWideES (42 B), VwEditSwBox (44 B). 6 texts the
; [nakarest] records point at (Viewable slot 0xc5 (table 0xed7b92, 7 entries, InitializeToshi)):
; [nakarest] "STYLE ALPHABETICAL" (TtlScreen.title of element 0); " | | | | | | | | | |"
; [nakarest] (AcMstStyleAlpGridBox.fixedrow of element 1); "| " (AcMstStyleAlpGridBox.fixedcol
; [nakarest] of element 1); "TEMPO" (Label.str of element 3); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1EAE, 0x174
; [nakarest] naka_ctrl_menu_body+0x2022  +0x2022..+0x210e (0xed5f08, 236 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0xd0 (table 0xed7bb2, 6 entries,
; [nakarest] InitializeToshi) ("PMBANK"): PmBankScreen (56 B), Icon (26 B), StringBox (38 B),
; [nakarest] PsPageBox (32 B), Label (32 B), IvIntEasySet (24 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xd0 (table 0xed7bb2, 6 entries, InitializeToshi)): "PMEM BANK
; [nakarest] SELECT" (StringBox.str of element 2); "PAGE 1/2" (Label.str of element 4).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2022, 0xEC
; [nakarest] naka_ctrl_menu_body+0x210e  +0x210e..+0x2326 (0xed5ff4, 536 B)
; [nakarest] widget records, elements 0-12 of Viewable slot 0xd1 (table 0xed7bce, 13 entries,
; [nakarest] InitializeToshi) ("PMVIEW"): TtlScreen (42 B), AcPmBkEditBox (58 B), AcIndexWideES
; [nakarest] (42 B), PsPageBox (32 B), Label (32 B) x6, EditSw (40 B) x2, IvIntEasySet (24 B).
; [nakarest] 10 texts the records point at (Viewable slot 0xd1 (table 0xed7bce, 13 entries,
; [nakarest] InitializeToshi)): "BANK VIEW" (TtlScreen.title of element 0); ""
; [nakarest] (AcPmBkEditBox.caption of element 1); "PAGE 2/2" (Label.str of element 4); "BANK"
; [nakarest] (Label.str of element 5); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x210E, 0x218
; [nakarest] naka_ctrl_menu_body+0x2326  +0x2326..+0x2432 (0xed620c, 268 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0xd2 (table 0xed7c06, 7 entries,
; [nakarest] InitializeToshi) ("PMNAME"): TtlScreen (42 B), IvNaming (26 B), AcFuncEditSw (44
; [nakarest] B), Label (32 B), PmBkNoBox (36 B), EditSw (40 B), IvExit (22 B). 3 texts the
; [nakarest] records point at (Viewable slot 0xd2 (table 0xed7c06, 7 entries, InitializeToshi)):
; [nakarest] "NAMING" (TtlScreen.title of element 0); "P.MEM Memory" (Label.str of element 3);
; [nakarest] "~80" (EditSw.str of element 5).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2326, 0x10C
; [nakarest] naka_ctrl_menu_body+0x2432  +0x2432..+0x253c (0xed6318, 266 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0xd3 (table 0xed7c26, 7 entries,
; [nakarest] InitializeToshi) ("PMBKNAME"): TtlScreen (42 B), IvNaming (26 B), AcFuncEditSw (44
; [nakarest] B), Label (32 B), BkNoBox (36 B), EditSw (40 B), IvExit (22 B). 3 texts the records
; [nakarest] point at (Viewable slot 0xd3 (table 0xed7c26, 7 entries, InitializeToshi)):
; [nakarest] "NAMING" (TtlScreen.title of element 0); "P.MEM Bank" (Label.str of element 3);
; [nakarest] "~80" (EditSw.str of element 5).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2432, 0x10A
; [nakarest] naka_ctrl_menu_body+0x253c  +0x253c..+0x2598 (0xed6422, 92 B)
; [nakarest] widget records, elements 0-1 of Viewable slot 0xe8 (table 0xed7c46, 2 entries,
; [nakarest] InitializeToshi) ("SVARI"): VariScreen (68 B), IvIntVari (24 B).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x253C, 0x5C
; [nakarest] naka_ctrl_menu_body+0x2598  +0x2598..+0x2618 (0xed647e, 128 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0xe9 (table 0xed7c52, 3 entries,
; [nakarest] InitializeToshi) ("RVARI"): RVariScreen (68 B), AcTempoBox (36 B), IvIntVari (24
; [nakarest] B).
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2598, 0x80
; [nakarest] naka_ctrl_menu_body+0x2618  +0x2618..+0x27b4 (0xed64fe, 412 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0xf4 (table 0xed7c62, 14 entries,
; [nakarest] InitializeToshi): TtlScreen (42 B), Window (36 B) x2, Label (32 B) x5. 6 texts the
; [nakarest] records point at (Viewable slot 0xf4 (table 0xed7c62, 14 entries,
; [nakarest] InitializeToshi)): "" (TtlScreen.title of element 0); "CAUTION!!" (Label.str of
; [nakarest] element 2); "** ERROR in back-up SRAM **" (Label.str of element 3); "Please try
; [nakarest] turning off and on again." (Label.str of element 4); ....
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2618, 0x19C


; ===========================================================================
; CPU data-transmission error messages: elements 8-12 of the Viewable table
; of slot 0xf4 (0xed7c62, 14 entries, registered by InitializeToshi in
; extensions/extension_init.s)
; ===========================================================================
; Five records of class Label (class id 0x0160002b: root Class table, slot
; 0x160, entry 0x2b; 32 bytes: class, super, sub, next, prev, flag, rect,
; str, font, fontcolor -- the firmware's own field names) whose strings are
; "CAUTION!!", "** ERROR in CPU data transmission **", "Please try turning
; off and on again.", "If this message appears again," and "this unit
; needs repairing." (the text follows each record in
; extensions/extension_data.s).  Their parent (`super`) is element 7, a
; Window named "TEST1CP" in the parallel ResName table (slot 0x3f4);
; elements 1-6 are the "TEST1RAM" Window and its Labels; elements 0 and 13
; are full-screen (0,0)-(319,239) TtlScreen records.  The .include of this
; file sits in extension_data.s, which carries the rest of element 8 after
; the two bytes below, and elements 9-12.
;
; Record layout: the Viewable fields, +0 class id, +4 super (parent
; element), +6 sub (first child), +8 next, +10 prev (element indices,
; 0xffff = none), +12 flag, +14..+20 rect x1, y1, x2, y2 (element 8:
; (78,128)-(225,146), inside its parent's (4,120)-(315,237)); all 14 links
; of slot 0xf4 consistent (scripts/analysis/nakarest_objtab_map.py; lane
; ext's ext_lane_checks.py test1 found the same).
;
; CORRECTED (lane nakarest, 2026-09-25): this block used to describe the
; records as "Byte 0-1: entry length, Byte 2-3: widget type 0x0160, Byte
; 4-5: screen group ID (0x07 = error dialogs), Byte 6-7: flags, Byte 8-9:
; widget index within screen group", call this one "Widget 9 ... Screen
; group 7, index 9", and read the two bytes below as "Entry length: 43
; bytes".  Proven false by the links: the 0x07 at +4 is the parent element
; (element 7's +6 first child is 8), the 0x09 at +8 is the next sibling
; (element 9's +10 is 8), and 0x2b is the class index of Label for every
; one of the five records, whatever their length.  The earlier header's
; purpose statement, kept as written (not re-verified here -- note that the
; parent panel is named TEST1CP):
; These widgets form the error dialog displayed when Sub-CPU payload
; transfer fails during boot. The dialog shows a severe hardware error
; that typically requires service center attention.
; ===========================================================================
ErrorDialog_CautionHeader:
	.byte 0x2b, 0x00	; class id 0x0160002b (Label), low half: index 0x2b
