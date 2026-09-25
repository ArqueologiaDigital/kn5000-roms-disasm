
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
; Viewable slot 0x40: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xed78ce,
; 0x40 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x40. Element 0 is named "ControlMenu" in ResName slot 0x340.
; Links: all 9 records consistent.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_control_menu_header+0x0
; naka_control_menu_header+0x0  --  naka_control_menu_header +0x0..+0x250 (ROM 0xed3c96..0xed3ee6), 592 bytes
; Widget records of elements 0-8 of Viewable slot 0x40 (table 0xed78ce,
; 9 entries, InitializeToshi), element 0 "ControlMenu"; classes:
; TtlScreen (42 B, id 0x01600034), AcTitleMenu (54 B, id 0x0160001d) x7,
; IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_control_menu_header.bin", 0x0, 0x250

; Control Menu body widgets (184 widgets across all sub-screens)
; Source: maincpu/ui_widgets/naka_ctrl_menu_body.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x0
; naka_ctrl_menu_body+0x0  --  naka_ctrl_menu_body +0x0..+0x348 (ROM 0xed3ee6..0xed422e), 840 bytes
; Widget records of elements 0-16 of Viewable slot 0x41 (table 0xed78f6,
; 17 entries, InitializeToshi), element 0 "ControlIni"; classes:
; TtlScreen (42 B, id 0x01600034) x2, AcIndexWideES (42 B, id
; 0x01600022), AcListBox (48 B, id 0x01600055), AcFuncEditSw (44 B, id
; 0x01600020) x3, IvShowHide (26 B, id 0x01600064) x2, AcLanguageText
; (42 B, id 0x01600066) x4, Screen (34 B, id 0x01600033), Label (32 B,
; id 0x0160002b), Icon (26 B, id 0x0160002d), Box (26 B, id 0x01600031).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x0, 0x348
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x348
; naka_ctrl_menu_body+0x348  --  naka_ctrl_menu_body +0x348..+0x504 (ROM 0xed422e..0xed43ea), 444 bytes
; Widget records of elements 0-5 of Viewable slot 0x42 (table 0xed793e,
; 6 entries, InitializeToshi), element 0 "ControlFsw"; classes:
; TtlScreen (42 B, id 0x01600034), AcFSWAssGridBox (74 B, id
; 0x01620010), Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id
; 0x01600022) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x348, 0x1BC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x504
; naka_ctrl_menu_body+0x504  --  naka_ctrl_menu_body +0x504..+0x710 (ROM 0xed43ea..0xed45f6), 524 bytes
; Widget records of elements 0-7 of Viewable slot 0x43 (table 0xed795a,
; 8 entries, InitializeToshi), element 0 "ControlSns"; classes:
; TtlScreen (42 B, id 0x01600034), AcTchSensGridBox (74 B, id
; 0x0162000f), Label (32 B, id 0x0160002b) x4, AcIndexWideES (42 B, id
; 0x01600022) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x504, 0x20C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x710
; naka_ctrl_menu_body+0x710  --  naka_ctrl_menu_body +0x710..+0xa4a (ROM 0xed45f6..0xed4930), 826 bytes
; Widget records of elements 0-18 of Viewable slot 0x44 (table 0xed797e,
; 19 entries, InitializeToshi); classes: MsaModeScreen (52 B, id
; 0x0162000a) x2, Label (32 B, id 0x0160002b) x8, Icon (26 B, id
; 0x0160002d) x2, EditSw (40 B, id 0x01600030) x6, IvIntEasySet (24 B,
; id 0x01600063).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x710, 0x33A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0xa4a
; naka_ctrl_menu_body+0xa4a  --  naka_ctrl_menu_body +0xa4a..+0xdee (ROM 0xed4930..0xed4cd4), 932 bytes
; Widget records of elements 0-18 of Viewable slot 0x45 (table 0xed79ce,
; 19 entries, InitializeToshi); classes: TtlScreen (42 B, id
; 0x01600034), IvPmemWindowPageCtl (26 B, id 0x0162000d), IvPageControl
; (28 B, id 0x01600028) x2, IvIntEasySet (24 B, id 0x01600063), Window
; (36 B, id 0x01600035) x3, PmemModeBox (44 B, id 0x0162000b), EditSw
; (40 B, id 0x01600030) x2, Label (32 B, id 0x0160002b) x2,
; AcLanguageText (42 B, id 0x01600066) x2, AcPmExpFilterGridBox (74 B,
; id 0x01620011), AcIndexWideES (42 B, id 0x01600022) x2, StringBox (38
; B, id 0x01600037).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xA4A, 0x3A4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0xdee
; naka_ctrl_menu_body+0xdee  --  naka_ctrl_menu_body +0xdee..+0xfb0 (ROM 0xed4cd4..0xed4e96), 450 bytes
; Widget records of elements 0-6 of Viewable slot 0x47 (table 0xed7a22,
; 7 entries, InitializeToshi), element 0 "ControlSys"; classes:
; TtlScreen (42 B, id 0x01600034), AcDispTimeSetGridBox (74 B, id
; 0x01620012), Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id
; 0x01600022) x2, AcFuncEditSw (44 B, id 0x01600020).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xDEE, 0x1C2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0xfb0
; naka_ctrl_menu_body+0xfb0  --  naka_ctrl_menu_body +0xfb0..+0x1458 (ROM 0xed4e96..0xed533e), 1192 bytes
; Widget records of elements 0-24 of Viewable slot 0x48 (table 0xed7a42,
; 25 entries, InitializeToshi); classes: TtlScreen (42 B, id 0x01600034)
; x2, AcTitleMenu (54 B, id 0x0160001d) x2, AcRamEditBox (58 B, id
; 0x0160001b) x3, Label (32 B, id 0x0160002b) x5, AcFuncEditSw (44 B, id
; 0x01600020) x4, AcIndexWideES (42 B, id 0x01600022), IvShowHide (26 B,
; id 0x01600064) x2, Screen (34 B, id 0x01600033), Box (26 B, id
; 0x01600031), AcLanguageText (42 B, id 0x01600066) x3, Icon (26 B, id
; 0x0160002d).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0xFB0, 0x4A8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x1458
; naka_ctrl_menu_body+0x1458  --  naka_ctrl_menu_body +0x1458..+0x14fa (ROM 0xed533e..0xed53e0), 162 bytes
; Widget records of elements 0-3 of Viewable slot 0xc0 (table 0xed7aaa,
; 4 entries, InitializeToshi), element 0 "ONETCH"; classes: TtlScreen
; (42 B, id 0x01600034), Label (32 B, id 0x0160002b), AcRamBox (44 B, id
; 0x0160004f), IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1458, 0xA2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x14fa
; naka_ctrl_menu_body+0x14fa  --  naka_ctrl_menu_body +0x14fa..+0x15dc (ROM 0xed53e0..0xed54c2), 226 bytes
; Widget records of elements 0-3 of Viewable slot 0xc1 (table 0xed7abe,
; 4 entries, InitializeToshi), element 0 "MUSICSTYL"; classes: TtlScreen
; (42 B, id 0x01600034), AcTitleMenu (54 B, id 0x0160001d) x2,
; IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x14FA, 0xE2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x15dc
; naka_ctrl_menu_body+0x15dc  --  naka_ctrl_menu_body +0x15dc..+0x19d0 (ROM 0xed54c2..0xed58b6), 1012 bytes
; Widget records of elements 0-19 of Viewable slot 0xc2 (table 0xed7ad2,
; 20 entries, InitializeToshi), element 0 "MSCTSEL"; classes: TtlScreen
; (42 B, id 0x01600034), IvMstStyleWindowPgCtl (26 B, id 0x0162000e),
; IvPageControl (28 B, id 0x01600028) x2, Window (36 B, id 0x01600035)
; x2, AcMstStyle1GridBox (86 B, id 0x01620015), AcIndexWideES (42 B, id
; 0x01600022) x3, VwEditSwBox (44 B, id 0x0160003e) x2, Label (32 B, id
; 0x0160002b) x5, AcMstStyle1SubGridBox (86 B, id 0x01620016),
; AcMstStyle2GridBox (102 B, id 0x01620017), Box (26 B, id 0x01600031).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x15DC, 0x3F4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x19d0
; naka_ctrl_menu_body+0x19d0  --  naka_ctrl_menu_body +0x19d0..+0x1d04 (ROM 0xed58b6..0xed5bea), 820 bytes
; Widget records of elements 0-16 of Viewable slot 0xc3 (table 0xed7b26,
; 17 entries, InitializeToshi), element 0 "MSSCTSEL"; classes: TtlScreen
; (42 B, id 0x01600034), IvMstStyleWindowPgCtl (26 B, id 0x0162000e),
; IvPageControl (28 B, id 0x01600028) x2, Window (36 B, id 0x01600035)
; x2, AcMstSong1GridBox (86 B, id 0x01620018), AcIndexWideES (42 B, id
; 0x01600022) x2, VwEditSwBox (44 B, id 0x0160003e) x2, Label (32 B, id
; 0x0160002b) x4, AcMstSong2GridBox (102 B, id 0x01620019), Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x19D0, 0x334
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x1d04
; naka_ctrl_menu_body+0x1d04  --  naka_ctrl_menu_body +0x1d04..+0x1eae (ROM 0xed5bea..0xed5d94), 426 bytes
; Widget records of elements 0-7 of Viewable slot 0xc4 (table 0xed7b6e,
; 8 entries, InitializeToshi), element 0 "MSSONGLIST"; classes:
; TtlScreen (42 B, id 0x01600034), AcMstSugAlpGridBox (102 B, id
; 0x01620013), Label (32 B, id 0x0160002b) x3, AcIndexWideES (42 B, id
; 0x01600022), Box (26 B, id 0x01600031), VwEditSwBox (44 B, id
; 0x0160003e).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1D04, 0x1AA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x1eae
; naka_ctrl_menu_body+0x1eae  --  naka_ctrl_menu_body +0x1eae..+0x2022 (ROM 0xed5d94..0xed5f08), 372 bytes
; Widget records of elements 0-6 of Viewable slot 0xc5 (table 0xed7b92,
; 7 entries, InitializeToshi), element 0 "MSSTLSEL"; classes: TtlScreen
; (42 B, id 0x01600034), AcMstStyleAlpGridBox (94 B, id 0x01620014), Box
; (26 B, id 0x01600031), Label (32 B, id 0x0160002b) x2, AcIndexWideES
; (42 B, id 0x01600022), VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x1EAE, 0x174
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x2022
; naka_ctrl_menu_body+0x2022  --  naka_ctrl_menu_body +0x2022..+0x210e (ROM 0xed5f08..0xed5ff4), 236 bytes
; Widget records of elements 0-5 of Viewable slot 0xd0 (table 0xed7bb2,
; 6 entries, InitializeToshi), element 0 "PMBANK"; classes: PmBankScreen
; (56 B, id 0x01620008), Icon (26 B, id 0x0160002d), StringBox (38 B, id
; 0x01600037), PsPageBox (32 B, id 0x01600024), Label (32 B, id
; 0x0160002b), IvIntEasySet (24 B, id 0x01600063).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2022, 0xEC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x210e
; naka_ctrl_menu_body+0x210e  --  naka_ctrl_menu_body +0x210e..+0x2326 (ROM 0xed5ff4..0xed620c), 536 bytes
; Widget records of elements 0-12 of Viewable slot 0xd1 (table 0xed7bce,
; 13 entries, InitializeToshi), element 0 "PMVIEW"; classes: TtlScreen
; (42 B, id 0x01600034), AcPmBkEditBox (58 B, id 0x01620009),
; AcIndexWideES (42 B, id 0x01600022), PsPageBox (32 B, id 0x01600024),
; Label (32 B, id 0x0160002b) x6, EditSw (40 B, id 0x01600030) x2,
; IvIntEasySet (24 B, id 0x01600063).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x210E, 0x218
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x2326
; naka_ctrl_menu_body+0x2326  --  naka_ctrl_menu_body +0x2326..+0x2432 (ROM 0xed620c..0xed6318), 268 bytes
; Widget records of elements 0-6 of Viewable slot 0xd2 (table 0xed7c06,
; 7 entries, InitializeToshi), element 0 "PMNAME"; classes: TtlScreen
; (42 B, id 0x01600034), IvNaming (26 B, id 0x0160004d), AcFuncEditSw
; (44 B, id 0x01600020), Label (32 B, id 0x0160002b), PmBkNoBox (36 B,
; id 0x01620007), EditSw (40 B, id 0x01600030), IvExit (22 B, id
; 0x01600047).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2326, 0x10C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x2432
; naka_ctrl_menu_body+0x2432  --  naka_ctrl_menu_body +0x2432..+0x253c (ROM 0xed6318..0xed6422), 266 bytes
; Widget records of elements 0-6 of Viewable slot 0xd3 (table 0xed7c26,
; 7 entries, InitializeToshi), element 0 "PMBKNAME"; classes: TtlScreen
; (42 B, id 0x01600034), IvNaming (26 B, id 0x0160004d), AcFuncEditSw
; (44 B, id 0x01600020), Label (32 B, id 0x0160002b), BkNoBox (36 B, id
; 0x01620006), EditSw (40 B, id 0x01600030), IvExit (22 B, id
; 0x01600047).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2432, 0x10A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x253c
; naka_ctrl_menu_body+0x253c  --  naka_ctrl_menu_body +0x253c..+0x2598 (ROM 0xed6422..0xed647e), 92 bytes
; Widget records of elements 0-1 of Viewable slot 0xe8 (table 0xed7c46,
; 2 entries, InitializeToshi), element 0 "SVARI"; classes: VariScreen
; (68 B, id 0x01620001), IvIntVari (24 B, id 0x01600062).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x253C, 0x5C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x2598
; naka_ctrl_menu_body+0x2598  --  naka_ctrl_menu_body +0x2598..+0x2618 (ROM 0xed647e..0xed64fe), 128 bytes
; Widget records of elements 0-2 of Viewable slot 0xe9 (table 0xed7c52,
; 3 entries, InitializeToshi), element 0 "RVARI"; classes: RVariScreen
; (68 B, id 0x01620002), AcTempoBox (36 B, id 0x01600014), IvIntVari (24
; B, id 0x01600062).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_ctrl_menu_body.bin", 0x2598, 0x80
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_ctrl_menu_body+0x2618
; naka_ctrl_menu_body+0x2618  --  naka_ctrl_menu_body +0x2618..+0x27b4 (ROM 0xed64fe..0xed669a), 412 bytes
; Widget records of elements 0-7 of Viewable slot 0xf4 (table 0xed7c62,
; 14 entries, InitializeToshi); classes: TtlScreen (42 B, id
; 0x01600034), Window (36 B, id 0x01600035) x2, Label (32 B, id
; 0x0160002b) x5.
; -----------------------------------------------------------------------------
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
