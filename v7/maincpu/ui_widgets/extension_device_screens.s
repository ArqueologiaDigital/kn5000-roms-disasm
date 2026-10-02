
; Extension Device Diagnostic & Config screens (106 widgets, 14740 bytes)
; Source: maincpu/ui_widgets/naka_extension_device.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_extension_device
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
; Viewable slot 0x1: RegObjTabl 0x1600010, ViewableProc, 0x3f, 0xed77ce,
; 0x1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 63, table} at 0x27ed2 +
; 14*0x1. Element 0 is named "Normal" in ResName slot 0x301. Links: all
; 63 records consistent.
;
; Viewable slot 0x40: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xed78ce,
; 0x40 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x40. Element 0 is named "ControlMenu" in ResName slot 0x340.
; Links: all 9 records consistent.
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
; Viewable slot 0x46: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xed7a1e,
; 0x46 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x46. Element 0 is named "" in ResName slot 0x346. Links: all 0
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
;
; Viewable slot 0xf5: RegObjTabl 0x1600010, ViewableProc, 0x17,
; 0xed7c9e, 0xf5 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 23, table} at 0x27ed2 +
; 14*0xf5. Element 0 is named "TEST2" in ResName slot 0x3f5. Links: all
; 23 records consistent.
;
; Viewable slot 0xf6: RegObjTabl 0x1600010, ViewableProc, 0x1, 0xed7cfe,
; 0xf6 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0xf6. Element 0 is named "TEST3" in ResName slot 0x3f6. Links: all
; 1 records consistent.
;
; Viewable slot 0xf7: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xed7d06,
; 0xf7 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0xf7. Element 0 is named "TEST4" in ResName slot 0x3f7. Links: all
; 3 records consistent.
;
; Viewable slot 0xf8: RegObjTabl 0x1600010, ViewableProc, 0x43,
; 0xed7d16, 0xf8 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 67, table} at 0x27ed2 +
; 14*0xf8. Element 0 is named "TEST5" in ResName slot 0x3f8. Links: all
; 67 records consistent.
;
; Viewable slot 0xf9: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xed7e26,
; 0xf9 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0xf9. Element 0 is named "TEST6" in ResName slot 0x3f9. Links: all
; 9 records consistent.
;
; Viewable slot 0xfb: RegObjTabl 0x1600010, ViewableProc, 0x1, 0xed7e4e,
; 0xfb in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0xfb. Element 0 is named "EXT" in ResName slot 0x3fb. Links: all 1
; records consistent.
;
; ResName slot 0x301: RegObjTabl 0x160000f, ResNameProc, 0x3f, 0xed7e56,
; 0x301 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 63, table} at 0x27ed2 +
; 14*0x301.
;
; ResName slot 0x340: RegObjTabl 0x160000f, ResNameProc, 0x9, 0xed7ff6,
; 0x340 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x340.
;
; ResName slot 0x341: RegObjTabl 0x160000f, ResNameProc, 0x11, 0xed803c,
; 0x341 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x341.
;
; ResName slot 0x342: RegObjTabl 0x160000f, ResNameProc, 0x6, 0xed80c2,
; 0x342 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x342.
;
; ResName slot 0x343: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xed80f6,
; 0x343 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x343.
;
; ResName slot 0x344: RegObjTabl 0x160000f, ResNameProc, 0x13, 0xed8136,
; 0x344 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x344.
;
; ResName slot 0x345: RegObjTabl 0x160000f, ResNameProc, 0x13, 0xed81ae,
; 0x345 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x345.
;
; ResName slot 0x346: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xed822e,
; 0x346 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x346.
;
; ResName slot 0x347: RegObjTabl 0x160000f, ResNameProc, 0x7, 0xed8234,
; 0x347 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x347.
;
; ResName slot 0x348: RegObjTabl 0x160000f, ResNameProc, 0x19, 0xed826e,
; 0x348 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x348.
;
; ResName slot 0x3c0: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xed8322,
; 0x3c0 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x3c0.
;
; ResName slot 0x3c1: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xed8346,
; 0x3c1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x3c1.
;
; ResName slot 0x3c2: RegObjTabl 0x160000f, ResNameProc, 0x14, 0xed836c,
; 0x3c2 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x3c2.
;
; ResName slot 0x3c3: RegObjTabl 0x160000f, ResNameProc, 0x11, 0xed83fc,
; 0x3c3 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x3c3.
;
; ResName slot 0x3c4: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xed8478,
; 0x3c4 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x3c4.
;
; ResName slot 0x3c5: RegObjTabl 0x160000f, ResNameProc, 0x7, 0xed84b8,
; 0x3c5 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x3c5.
;
; ResName slot 0x3d0: RegObjTabl 0x160000f, ResNameProc, 0x6, 0xed84f0,
; 0x3d0 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x3d0.
;
; ResName slot 0x3d1: RegObjTabl 0x160000f, ResNameProc, 0xd, 0xed8520,
; 0x3d1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x3d1.
;
; ResName slot 0x3d2: RegObjTabl 0x160000f, ResNameProc, 0x7, 0xed857a,
; 0x3d2 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x3d2.
;
; ResName slot 0x3d3: RegObjTabl 0x160000f, ResNameProc, 0x7, 0xed85b0,
; 0x3d3 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x3d3.
;
; ResName slot 0x3e8: RegObjTabl 0x160000f, ResNameProc, 0x2, 0xed85e8,
; 0x3e8 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0x3e8.
;
; ResName slot 0x3e9: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xed85fe,
; 0x3e9 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x3e9.
;
; ResName slot 0x3f4: RegObjTabl 0x160000f, ResNameProc, 0xe, 0xed861a,
; 0x3f4 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 14, table} at 0x27ed2 +
; 14*0x3f4.
;
; ResName slot 0x3f5: RegObjTabl 0x160000f, ResNameProc, 0x17, 0xed8682,
; 0x3f5 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 23, table} at 0x27ed2 +
; 14*0x3f5.
;
; ResName slot 0x3f6: RegObjTabl 0x160000f, ResNameProc, 0x1, 0xed8736,
; 0x3f6 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0x3f6.
;
; ResName slot 0x3f7: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xed8746,
; 0x3f7 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x3f7.
;
; ResName slot 0x3f8: RegObjTabl 0x160000f, ResNameProc, 0x43, 0xed8762,
; 0x3f8 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 67, table} at 0x27ed2 +
; 14*0x3f8.
;
; ResName slot 0x3f9: RegObjTabl 0x160000f, ResNameProc, 0x9, 0xed8922,
; 0x3f9 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0x3f9.
;
; ResName slot 0x3fb: RegObjTabl 0x160000f, ResNameProc, 0x1, 0xed896e,
; 0x3fb in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0x3fb.
; -----------------------------------------------------------------------------

; [nakarest] NakaInst_ExtDevice_Screens  +0x0..+0x2c (0xed67cc, 44 B)
; [nakarest] widget record, element 13 of Viewable slot 0xf4 (table 0xed7c62, 14 entries,
; [nakarest] InitializeToshi): TtlScreen (42 B). 1 text the records point at (Viewable slot 0xf4
; [nakarest] (table 0xed7c62, 14 entries, InitializeToshi)): "" (TtlScreen.title of element 13).
NakaInst_ExtDevice_Screens:
	.incbin "includes/generated/naka_extension_device.bin", 0x0, 0x2C
; [nakarest] naka_extension_device+0x2c  +0x2c..+0x41a (0xed67f8, 1006 B)
; [nakarest] widget records, elements 0-22 of Viewable slot 0xf5 (table 0xed7c9e, 23 entries,
; [nakarest] InitializeToshi) ("TEST2"): TtlScreen (42 B), TextBox (40 B), Label (32 B) x13,
; [nakarest] IvPageControl (28 B) x4, Window (36 B) x4. 15 texts the records point at (Viewable
; [nakarest] slot 0xf5 (table 0xed7c9e, 23 entries, InitializeToshi)): "" (TtlScreen.title of
; [nakarest] element 0); "Please check by the LED of test port. (PANEL CPU" (TextBox.text of
; [nakarest] element 1); "PANEL CPU CHECKING" (Label.str of element 2); "RESULT: CPU of CPR ="
; [nakarest] (Label.str of element 3); ....
NakaWidget_TEST2:			.incbin "includes/generated/naka_extension_device.bin", 0x2C, 0x2C
NakaWidget_TEST2_1_TextBox:		.incbin "includes/generated/naka_extension_device.bin", 0x58, 0x92
NakaWidget_TEST2_2_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xEA, 0x34
NakaWidget_TEST2_3_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x11E, 0x20
ExtDevScreen_SndParamBank_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0x13E, 0x16
NakaWidget_TEST2_4_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x154, 0x2E
NakaWidget_TEST2_5_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x182, 0x34
NakaWidget_TEST2_6_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x1B6, 0x20
ExtDevScreen_SndParamPage_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0x1D6, 0x24
NakaWidget_TEST2_7_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x1FA, 0x1C
NakaWidget_TEST2_8_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x216, 0x1C
NakaWidget_TEST2_9_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x232, 0x1C
NakaWidget_TEST2_10_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x24E, 0x1C
NakaWidget_TEST2OKOK:			.incbin "includes/generated/naka_extension_device.bin", 0x26A, 0x24
NakaWidget_TEST2_12_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x28E, 0x20
ExtDevScreen_VoiceParamBank_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0x2AE, 0x4
NakaWidget_TEST2_13_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x2B2, 0x24
NakaWidget_TEST2NGNG:			.incbin "includes/generated/naka_extension_device.bin", 0x2D6, 0x24
NakaWidget_TEST2_15_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x2FA, 0x24
NakaWidget_TEST2_16_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x31E, 0x20
ExtDevScreen_VoiceParamRhythm_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0x33E, 0x4
NakaWidget_TEST2NGOK:			.incbin "includes/generated/naka_extension_device.bin", 0x342, 0x24
NakaWidget_TEST2_18_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x366, 0x20
ExtDevScreen_VoiceParamDrums_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0x386, 0x4
NakaWidget_TEST2_19_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x38A, 0x24
NakaWidget_TEST2OKNG:			.incbin "includes/generated/naka_extension_device.bin", 0x3AE, 0x24
NakaWidget_TEST2_21_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x3D2, 0x24
NakaWidget_TEST2_22_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x3F6, 0x20
ExtDevScreen_VoiceSetup_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0x416, 0x4
; [nakarest] naka_extension_device+0x41a  +0x41a..+0x44e (0xed6be6, 52 B)
; [nakarest] widget record, element 0 of Viewable slot 0xf6 (table 0xed7cfe, 1 entries,
; [nakarest] InitializeToshi) ("TEST3"): SineWaveScreen (52 B).
NakaWidget_TEST3:	.incbin "includes/generated/naka_extension_device.bin", 0x41A, 0x34
; [nakarest] naka_extension_device+0x44e  +0x44e..+0x548 (0xed6c1a, 250 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0xf7 (table 0xed7d06, 3 entries,
; [nakarest] InitializeToshi) ("TEST4"): TtlScreen (42 B), TextBox (40 B), Label (32 B). 3 texts
; [nakarest] the records point at (Viewable slot 0xf7 (table 0xed7d06, 3 entries,
; [nakarest] InitializeToshi)): "" (TtlScreen.title of element 0); "After all LEDs ON and OFF,
; [nakarest] Please push any butt" (TextBox.text of element 1); "PANEL SW&LED CHECK" (Label.str
; [nakarest] of element 2).
NakaWidget_TEST4:			.incbin "includes/generated/naka_extension_device.bin", 0x44E, 0x2C
NakaWidget_TEST4_1_TextBox:		.incbin "includes/generated/naka_extension_device.bin", 0x47A, 0x28
ExtDevScreen_VoiceMainPage_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0x4A2, 0x72
NakaWidget_TEST4_2_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x514, 0x34
; [nakarest] naka_extension_device+0x548  +0x548..+0xe6c (0xed6d14, 2340 B)
; [nakarest] widget records, elements 0-66 of Viewable slot 0xf8 (table 0xed7d16, 67 entries,
; [nakarest] InitializeToshi) ("TEST5"): TtlScreen (42 B), IvPageControl (28 B) x5, Window (36
; [nakarest] B) x6, Label (32 B) x50, Frame (28 B) x5. 51 texts the records point at (Viewable
; [nakarest] slot 0xf8 (table 0xed7d16, 67 entries, InitializeToshi)): "" (TtlScreen.title of
; [nakarest] element 0); "LCD PANEL TEST" (Label.str of element 7); "LCD PANEL TEST" (Label.str
; [nakarest] of element 9); "LCD PANEL TEST" (Label.str of element 11); ....
NakaWidget_TEST5:			.incbin "includes/generated/naka_extension_device.bin", 0x548, 0x2C
NakaWidget_TEST5_1_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x574, 0x1C
NakaWidget_TEST5_2_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x590, 0x1C
NakaWidget_TEST5_3_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x5AC, 0x1C
NakaWidget_TEST5_4_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x5C8, 0x1C
NakaWidget_TEST5_5_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0x5E4, 0x1C
NakaWidget_TEST51:			.incbin "includes/generated/naka_extension_device.bin", 0x600, 0x24
NakaWidget_TEST5_7_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x624, 0x30
NakaWidget_TEST52:			.incbin "includes/generated/naka_extension_device.bin", 0x654, 0x24
NakaWidget_TEST5_9_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x678, 0x30
NakaWidget_TEST53:			.incbin "includes/generated/naka_extension_device.bin", 0x6A8, 0x24
NakaWidget_TEST5_11_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x6CC, 0x30
NakaWidget_TEST54:			.incbin "includes/generated/naka_extension_device.bin", 0x6FC, 0x24
NakaWidget_TEST5_13_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x720, 0x30
NakaWidget_TEST55:			.incbin "includes/generated/naka_extension_device.bin", 0x750, 0x24
NakaWidget_TEST5_15_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x774, 0x30
NakaWidget_TEST56:			.incbin "includes/generated/naka_extension_device.bin", 0x7A4, 0x24
NakaWidget_TEST5_17_Frame:		.incbin "includes/generated/naka_extension_device.bin", 0x7C8, 0x1C
NakaWidget_TEST5_18_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x7E4, 0x22
NakaWidget_TEST5_19_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x806, 0x20
ExtDevScreen_MidiCtrl_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0x826, 0x2
NakaWidget_TEST5_20_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x828, 0x28
NakaWidget_TEST5_21_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x850, 0x22
NakaWidget_TEST5_22_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x872, 0x22
NakaWidget_TEST5_23_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x894, 0x22
NakaWidget_TEST5_24_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x8B6, 0x20
ExtDevScreen_MidiCtrlPage_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0x8D6, 0x2
NakaWidget_TEST5_25_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x8D8, 0x22
NakaWidget_TEST5_26_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x8FA, 0x22
NakaWidget_TEST5_27_Frame:		.incbin "includes/generated/naka_extension_device.bin", 0x91C, 0x1C
NakaWidget_TEST5_28_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x938, 0x22
NakaWidget_TEST5_29_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x95A, 0x22
NakaWidget_TEST5_30_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x97C, 0x28
NakaWidget_TEST5_31_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x9A4, 0x22
NakaWidget_TEST5_32_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x9C6, 0x20
ExtDevScreen_MidiCtrlDetail_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0x9E6, 0x2
NakaWidget_TEST5_33_Label:		.incbin "includes/generated/naka_extension_device.bin", 0x9E8, 0x22
NakaWidget_TEST5_34_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xA0A, 0x22
NakaWidget_TEST5_35_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xA2C, 0x22
NakaWidget_TEST5_36_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xA4E, 0x20
ExtDevScreen_MidiCtrlAdvanced_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0xA6E, 0x2
NakaWidget_TEST5_37_Frame:		.incbin "includes/generated/naka_extension_device.bin", 0xA70, 0x1C
NakaWidget_TEST5_38_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xA8C, 0x22
NakaWidget_TEST5_39_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xAAE, 0x20
ExtDevScreen_DspEffect_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0xACE, 0x2
NakaWidget_TEST5_40_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xAD0, 0x28
NakaWidget_TEST5_41_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xAF8, 0x22
NakaWidget_TEST5_42_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xB1A, 0x22
NakaWidget_TEST5_43_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xB3C, 0x22
NakaWidget_TEST5_44_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xB5E, 0x20
ExtDevScreen_DspEffectPage_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0xB7E, 0x2
NakaWidget_TEST5_45_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xB80, 0x22
NakaWidget_TEST5_46_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xBA2, 0x22
NakaWidget_TEST5_47_Frame:		.incbin "includes/generated/naka_extension_device.bin", 0xBC4, 0x1C
NakaWidget_TEST5_48_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xBE0, 0x22
NakaWidget_TEST5_49_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xC02, 0x22
NakaWidget_TEST5_50_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xC24, 0x28
NakaWidget_TEST5_51_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xC4C, 0x22
NakaWidget_TEST5_52_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xC6E, 0x20
ExtDevScreen_ReverbSetup_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0xC8E, 0x2
NakaWidget_TEST5_53_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xC90, 0x22
NakaWidget_TEST5_54_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xCB2, 0x22
NakaWidget_TEST5_55_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xCD4, 0x22
NakaWidget_TEST5_56_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xCF6, 0x20
ExtDevScreen_ReverbPage_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0xD16, 0x2
NakaWidget_TEST5_57_Frame:		.incbin "includes/generated/naka_extension_device.bin", 0xD18, 0x1C
NakaWidget_TEST5_58_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xD34, 0x22
NakaWidget_TEST5_59_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xD56, 0x20
ExtDevScreen_Equalizer_Desc:		.incbin "includes/generated/naka_extension_device.bin", 0xD76, 0x2
NakaWidget_TEST5_60_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xD78, 0x28
NakaWidget_TEST5_61_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xDA0, 0x22
NakaWidget_TEST5_62_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xDC2, 0x22
NakaWidget_TEST5_63_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xDE4, 0x22
NakaWidget_TEST5_64_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xE06, 0x20
ExtDevScreen_EqualizerPage_Desc:	.incbin "includes/generated/naka_extension_device.bin", 0xE26, 0x2
NakaWidget_TEST5_65_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xE28, 0x22
NakaWidget_TEST5_66_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xE4A, 0x22
; [nakarest] naka_extension_device+0xe6c  +0xe6c..+0xfe0 (0xed7638, 372 B)
; [nakarest] widget records, elements 0-8 of Viewable slot 0xf9 (table 0xed7e26, 9 entries,
; [nakarest] InitializeToshi) ("TEST6"): TtlScreen (42 B), Label (32 B) x4, IvPageControl (28 B)
; [nakarest] x2, Window (36 B) x2. 5 texts the records point at (Viewable slot 0xf9 (table
; [nakarest] 0xed7e26, 9 entries, InitializeToshi)): "" (TtlScreen.title of element 0);
; [nakarest] "PERIPHERAL DEVICE CHECK" (Label.str of element 1); "FLOPPY DISK CONTROLLER(FDC) "
; [nakarest] (Label.str of element 2); "= may be OK" (Label.str of element 6); ....
NakaWidget_TEST6:			.incbin "includes/generated/naka_extension_device.bin", 0xE6C, 0x2C
NakaWidget_TEST6_1_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xE98, 0x38
NakaWidget_TEST6_2_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xED0, 0x3E
NakaWidget_TEST6_3_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0xF0E, 0x1C
NakaWidget_TEST6_4_IvPageControl:	.incbin "includes/generated/naka_extension_device.bin", 0xF2A, 0x1C
NakaWidget_TEST6OK:			.incbin "includes/generated/naka_extension_device.bin", 0xF46, 0x24
NakaWidget_TEST6_6_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xF6A, 0x2C
NakaWidget_TEST6NG:			.incbin "includes/generated/naka_extension_device.bin", 0xF96, 0x24
NakaWidget_TEST6_8_Label:		.incbin "includes/generated/naka_extension_device.bin", 0xFBA, 0x26
; [nakarest] naka_extension_device+0xfe0  +0xfe0..+0x1002 (0xed77ac, 34 B)
; [nakarest] widget record, element 0 of Viewable slot 0xfb (table 0xed7e4e, 1 entries,
; [nakarest] InitializeToshi) ("EXT"): IvScreen (34 B).
NakaWidget_EXT:	.incbin "includes/generated/naka_extension_device.bin", 0xFE0, 0x22
; [nakarest] naka_extension_device+0x1002  +0x1002..+0x1102 (0xed77ce, 256 B)
; [nakarest] the table itself: Viewable slot 0x1 (table 0xed77ce, 63 entries, InitializeToshi),
; [nakarest] 63 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1002, 0x100
; [nakarest] naka_extension_device+0x1102  +0x1102..+0x112a (0xed78ce, 40 B)
; [nakarest] the table itself: Viewable slot 0x40 (table 0xed78ce, 9 entries, InitializeToshi),
; [nakarest] 9 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1102, 0x28
; [nakarest] naka_extension_device+0x112a  +0x112a..+0x1172 (0xed78f6, 72 B)
; [nakarest] the table itself: Viewable slot 0x41 (table 0xed78f6, 17 entries, InitializeToshi),
; [nakarest] 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x112A, 0x48
; [nakarest] naka_extension_device+0x1172  +0x1172..+0x118e (0xed793e, 28 B)
; [nakarest] the table itself: Viewable slot 0x42 (table 0xed793e, 6 entries, InitializeToshi),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1172, 0x1C
; [nakarest] naka_extension_device+0x118e  +0x118e..+0x11b2 (0xed795a, 36 B)
; [nakarest] the table itself: Viewable slot 0x43 (table 0xed795a, 8 entries, InitializeToshi),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x118E, 0x24
; [nakarest] naka_extension_device+0x11b2  +0x11b2..+0x1202 (0xed797e, 80 B)
; [nakarest] the table itself: Viewable slot 0x44 (table 0xed797e, 19 entries, InitializeToshi),
; [nakarest] 19 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x11B2, 0x50
; [nakarest] naka_extension_device+0x1202  +0x1202..+0x1252 (0xed79ce, 80 B)
; [nakarest] the table itself: Viewable slot 0x45 (table 0xed79ce, 19 entries, InitializeToshi),
; [nakarest] 19 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1202, 0x50
; [nakarest] naka_extension_device+0x1252  +0x1252..+0x1256 (0xed7a1e, 4 B)
; [nakarest] the table itself: Viewable slot 0x46 (table 0xed7a1e, 0 entries, InitializeToshi),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1252, 0x4
; [nakarest] naka_extension_device+0x1256  +0x1256..+0x1276 (0xed7a22, 32 B)
; [nakarest] the table itself: Viewable slot 0x47 (table 0xed7a22, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1256, 0x20
; [nakarest] naka_extension_device+0x1276  +0x1276..+0x12de (0xed7a42, 104 B)
; [nakarest] the table itself: Viewable slot 0x48 (table 0xed7a42, 25 entries, InitializeToshi),
; [nakarest] 25 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1276, 0x68
; [nakarest] naka_extension_device+0x12de  +0x12de..+0x12f2 (0xed7aaa, 20 B)
; [nakarest] the table itself: Viewable slot 0xc0 (table 0xed7aaa, 4 entries, InitializeToshi),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x12DE, 0x14
; [nakarest] naka_extension_device+0x12f2  +0x12f2..+0x1306 (0xed7abe, 20 B)
; [nakarest] the table itself: Viewable slot 0xc1 (table 0xed7abe, 4 entries, InitializeToshi),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x12F2, 0x14
; [nakarest] naka_extension_device+0x1306  +0x1306..+0x135a (0xed7ad2, 84 B)
; [nakarest] the table itself: Viewable slot 0xc2 (table 0xed7ad2, 20 entries, InitializeToshi),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1306, 0x54
; [nakarest] naka_extension_device+0x135a  +0x135a..+0x13a2 (0xed7b26, 72 B)
; [nakarest] the table itself: Viewable slot 0xc3 (table 0xed7b26, 17 entries, InitializeToshi),
; [nakarest] 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x135A, 0x48
; [nakarest] naka_extension_device+0x13a2  +0x13a2..+0x13c6 (0xed7b6e, 36 B)
; [nakarest] the table itself: Viewable slot 0xc4 (table 0xed7b6e, 8 entries, InitializeToshi),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x13A2, 0x24
; [nakarest] naka_extension_device+0x13c6  +0x13c6..+0x13e6 (0xed7b92, 32 B)
; [nakarest] the table itself: Viewable slot 0xc5 (table 0xed7b92, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x13C6, 0x20
; [nakarest] naka_extension_device+0x13e6  +0x13e6..+0x1402 (0xed7bb2, 28 B)
; [nakarest] the table itself: Viewable slot 0xd0 (table 0xed7bb2, 6 entries, InitializeToshi),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x13E6, 0x1C
; [nakarest] naka_extension_device+0x1402  +0x1402..+0x143a (0xed7bce, 56 B)
; [nakarest] the table itself: Viewable slot 0xd1 (table 0xed7bce, 13 entries, InitializeToshi),
; [nakarest] 13 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1402, 0x38
; [nakarest] naka_extension_device+0x143a  +0x143a..+0x145a (0xed7c06, 32 B)
; [nakarest] the table itself: Viewable slot 0xd2 (table 0xed7c06, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x143A, 0x20
; [nakarest] naka_extension_device+0x145a  +0x145a..+0x147a (0xed7c26, 32 B)
; [nakarest] the table itself: Viewable slot 0xd3 (table 0xed7c26, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x145A, 0x20
; [nakarest] naka_extension_device+0x147a  +0x147a..+0x1486 (0xed7c46, 12 B)
; [nakarest] the table itself: Viewable slot 0xe8 (table 0xed7c46, 2 entries, InitializeToshi),
; [nakarest] 2 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x147A, 0xC
; [nakarest] naka_extension_device+0x1486  +0x1486..+0x1496 (0xed7c52, 16 B)
; [nakarest] the table itself: Viewable slot 0xe9 (table 0xed7c52, 3 entries, InitializeToshi),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1486, 0x10
; [nakarest] naka_extension_device+0x1496  +0x1496..+0x14d2 (0xed7c62, 60 B)
; [nakarest] the table itself: Viewable slot 0xf4 (table 0xed7c62, 14 entries, InitializeToshi),
; [nakarest] 14 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1496, 0x3C
; [nakarest] naka_extension_device+0x14d2  +0x14d2..+0x1532 (0xed7c9e, 96 B)
; [nakarest] the table itself: Viewable slot 0xf5 (table 0xed7c9e, 23 entries, InitializeToshi),
; [nakarest] 23 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x14D2, 0x60
; [nakarest] naka_extension_device+0x1532  +0x1532..+0x153a (0xed7cfe, 8 B)
; [nakarest] the table itself: Viewable slot 0xf6 (table 0xed7cfe, 1 entries, InitializeToshi),
; [nakarest] 1 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1532, 0x8
; [nakarest] naka_extension_device+0x153a  +0x153a..+0x154a (0xed7d06, 16 B)
; [nakarest] the table itself: Viewable slot 0xf7 (table 0xed7d06, 3 entries, InitializeToshi),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x153A, 0x10
; [nakarest] naka_extension_device+0x154a  +0x154a..+0x165a (0xed7d16, 272 B)
; [nakarest] the table itself: Viewable slot 0xf8 (table 0xed7d16, 67 entries, InitializeToshi),
; [nakarest] 67 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x154A, 0x110
; [nakarest] naka_extension_device+0x165a  +0x165a..+0x1682 (0xed7e26, 40 B)
; [nakarest] the table itself: Viewable slot 0xf9 (table 0xed7e26, 9 entries, InitializeToshi),
; [nakarest] 9 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x165A, 0x28
; [nakarest] naka_extension_device+0x1682  +0x1682..+0x168a (0xed7e4e, 8 B)
; [nakarest] the table itself: Viewable slot 0xfb (table 0xed7e4e, 1 entries, InitializeToshi),
; [nakarest] 1 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1682, 0x8
; [nakarest] naka_extension_device+0x168a  +0x168a..+0x178c (0xed7e56, 258 B)
; [nakarest] the table itself: ResName slot 0x301 (table 0xed7e56, 63 entries, InitializeToshi),
; [nakarest] 63 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x168A, 0x102
; [nakarest] naka_extension_device+0x178c  +0x178c..+0x182a (0xed7f58, 158 B)
; [nakarest] name strings, entries 0-62 of ResName slot 0x301 (table 0xed7e56, 63 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x1): "", "", "FADEOUT", "", "",
; [nakarest] "FADEIN", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x178C, 0x9E
; [nakarest] naka_extension_device+0x182a  +0x182a..+0x1854 (0xed7ff6, 42 B)
; [nakarest] the table itself: ResName slot 0x340 (table 0xed7ff6, 9 entries, InitializeToshi),
; [nakarest] 9 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x182A, 0x2A
; [nakarest] naka_extension_device+0x1854  +0x1854..+0x1870 (0xed8020, 28 B)
; [nakarest] name strings, entries 0-8 of ResName slot 0x340 (table 0xed7ff6, 9 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x40): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1854, 0x1C
; [nakarest] naka_extension_device+0x1870  +0x1870..+0x18ba (0xed803c, 74 B)
; [nakarest] the table itself: ResName slot 0x341 (table 0xed803c, 17 entries, InitializeToshi),
; [nakarest] 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1870, 0x4A
; [nakarest] naka_extension_device+0x18ba  +0x18ba..+0x18f6 (0xed8086, 60 B)
; [nakarest] name strings, entries 0-16 of ResName slot 0x341 (table 0xed803c, 17 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x41): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x18BA, 0x3C
; [nakarest] naka_extension_device+0x18f6  +0x18f6..+0x1914 (0xed80c2, 30 B)
; [nakarest] the table itself: ResName slot 0x342 (table 0xed80c2, 6 entries, InitializeToshi),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x18F6, 0x1E
; [nakarest] naka_extension_device+0x1914  +0x1914..+0x192a (0xed80e0, 22 B)
; [nakarest] name strings, entries 0-5 of ResName slot 0x342 (table 0xed80c2, 6 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x42): "", "", "", "", "", "ControlFsw".
	.incbin "includes/generated/naka_extension_device.bin", 0x1914, 0x16
; [nakarest] naka_extension_device+0x192a  +0x192a..+0x1950 (0xed80f6, 38 B)
; [nakarest] the table itself: ResName slot 0x343 (table 0xed80f6, 8 entries, InitializeToshi),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x192A, 0x26
; [nakarest] naka_extension_device+0x1950  +0x1950..+0x196a (0xed811c, 26 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x343 (table 0xed80f6, 8 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x43): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1950, 0x1A
; [nakarest] naka_extension_device+0x196a  +0x196a..+0x19bc (0xed8136, 82 B)
; [nakarest] the table itself: ResName slot 0x344 (table 0xed8136, 19 entries, InitializeToshi),
; [nakarest] 19 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x196A, 0x52
; [nakarest] naka_extension_device+0x19bc  +0x19bc..+0x19e2 (0xed8188, 38 B)
; [nakarest] name strings, entries 0-18 of ResName slot 0x344 (table 0xed8136, 19 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x44): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x19BC, 0x26
; [nakarest] naka_extension_device+0x19e2  +0x19e2..+0x1a34 (0xed81ae, 82 B)
; [nakarest] the table itself: ResName slot 0x345 (table 0xed81ae, 19 entries, InitializeToshi),
; [nakarest] 19 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x19E2, 0x52
; [nakarest] naka_extension_device+0x1a34  +0x1a34..+0x1a62 (0xed8200, 46 B)
; [nakarest] name strings, entries 0-18 of ResName slot 0x345 (table 0xed81ae, 19 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x45): "", "", "", "", "", "PMEM2", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1A34, 0x2E
; [nakarest] naka_extension_device+0x1a62  +0x1a62..+0x1a68 (0xed822e, 6 B)
; [nakarest] the table itself: ResName slot 0x346 (table 0xed822e, 0 entries, InitializeToshi),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1A62, 0x6
; [nakarest] naka_extension_device+0x1a68  +0x1a68..+0x1a8a (0xed8234, 34 B)
; [nakarest] the table itself: ResName slot 0x347 (table 0xed8234, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1A68, 0x22
; [nakarest] naka_extension_device+0x1a8a  +0x1a8a..+0x1aa2 (0xed8256, 24 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x347 (table 0xed8234, 7 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x47): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1A8A, 0x18
; [nakarest] naka_extension_device+0x1aa2  +0x1aa2..+0x1b0c (0xed826e, 106 B)
; [nakarest] the table itself: ResName slot 0x348 (table 0xed826e, 25 entries, InitializeToshi),
; [nakarest] 25 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1AA2, 0x6A
; [nakarest] naka_extension_device+0x1b0c  +0x1b0c..+0x1b56 (0xed82d8, 74 B)
; [nakarest] name strings, entries 0-24 of ResName slot 0x348 (table 0xed826e, 25 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0x48): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1B0C, 0x4A
; [nakarest] naka_extension_device+0x1b56  +0x1b56..+0x1b6c (0xed8322, 22 B)
; [nakarest] the table itself: ResName slot 0x3c0 (table 0xed8322, 4 entries, InitializeToshi),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1B56, 0x16
; [nakarest] naka_extension_device+0x1b6c  +0x1b6c..+0x1b7a (0xed8338, 14 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x3c0 (table 0xed8322, 4 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc0): "", "", "", "ONETCH".
	.incbin "includes/generated/naka_extension_device.bin", 0x1B6C, 0xE
; [nakarest] naka_extension_device+0x1b7a  +0x1b7a..+0x1b90 (0xed8346, 22 B)
; [nakarest] the table itself: ResName slot 0x3c1 (table 0xed8346, 4 entries, InitializeToshi),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1B7A, 0x16
; [nakarest] naka_extension_device+0x1b90  +0x1b90..+0x1ba0 (0xed835c, 16 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x3c1 (table 0xed8346, 4 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc1): "", "", "", "MUSICSTYL".
	.incbin "includes/generated/naka_extension_device.bin", 0x1B90, 0x10
; [nakarest] naka_extension_device+0x1ba0  +0x1ba0..+0x1bf6 (0xed836c, 86 B)
; [nakarest] the table itself: ResName slot 0x3c2 (table 0xed836c, 20 entries, InitializeToshi),
; [nakarest] 20 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1BA0, 0x56
; [nakarest] naka_extension_device+0x1bf6  +0x1bf6..+0x1c30 (0xed83c2, 58 B)
; [nakarest] name strings, entries 0-19 of ResName slot 0x3c2 (table 0xed836c, 20 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc2): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1BF6, 0x3A
; [nakarest] naka_extension_device+0x1c30  +0x1c30..+0x1c7a (0xed83fc, 74 B)
; [nakarest] the table itself: ResName slot 0x3c3 (table 0xed83fc, 17 entries, InitializeToshi),
; [nakarest] 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1C30, 0x4A
; [nakarest] naka_extension_device+0x1c7a  +0x1c7a..+0x1cac (0xed8446, 50 B)
; [nakarest] name strings, entries 0-16 of ResName slot 0x3c3 (table 0xed83fc, 17 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc3): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1C7A, 0x32
; [nakarest] naka_extension_device+0x1cac  +0x1cac..+0x1cd2 (0xed8478, 38 B)
; [nakarest] the table itself: ResName slot 0x3c4 (table 0xed8478, 8 entries, InitializeToshi),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1CAC, 0x26
; [nakarest] naka_extension_device+0x1cd2  +0x1cd2..+0x1cec (0xed849e, 26 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x3c4 (table 0xed8478, 8 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc4): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1CD2, 0x1A
; [nakarest] naka_extension_device+0x1cec  +0x1cec..+0x1d0e (0xed84b8, 34 B)
; [nakarest] the table itself: ResName slot 0x3c5 (table 0xed84b8, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1CEC, 0x22
; [nakarest] naka_extension_device+0x1d0e  +0x1d0e..+0x1d24 (0xed84da, 22 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x3c5 (table 0xed84b8, 7 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xc5): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1D0E, 0x16
; [nakarest] naka_extension_device+0x1d24  +0x1d24..+0x1d42 (0xed84f0, 30 B)
; [nakarest] the table itself: ResName slot 0x3d0 (table 0xed84f0, 6 entries, InitializeToshi),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1D24, 0x1E
; [nakarest] naka_extension_device+0x1d42  +0x1d42..+0x1d54 (0xed850e, 18 B)
; [nakarest] name strings, entries 0-5 of ResName slot 0x3d0 (table 0xed84f0, 6 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xd0): "", "", "", "", "", "PMBANK".
	.incbin "includes/generated/naka_extension_device.bin", 0x1D42, 0x12
; [nakarest] naka_extension_device+0x1d54  +0x1d54..+0x1d8e (0xed8520, 58 B)
; [nakarest] the table itself: ResName slot 0x3d1 (table 0xed8520, 13 entries, InitializeToshi),
; [nakarest] 13 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1D54, 0x3A
; [nakarest] naka_extension_device+0x1d8e  +0x1d8e..+0x1dae (0xed855a, 32 B)
; [nakarest] name strings, entries 0-12 of ResName slot 0x3d1 (table 0xed8520, 13 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xd1): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1D8E, 0x20
; [nakarest] naka_extension_device+0x1dae  +0x1dae..+0x1dd0 (0xed857a, 34 B)
; [nakarest] the table itself: ResName slot 0x3d2 (table 0xed857a, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1DAE, 0x22
; [nakarest] naka_extension_device+0x1dd0  +0x1dd0..+0x1de4 (0xed859c, 20 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x3d2 (table 0xed857a, 7 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xd2): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1DD0, 0x14
; [nakarest] naka_extension_device+0x1de4  +0x1de4..+0x1e06 (0xed85b0, 34 B)
; [nakarest] the table itself: ResName slot 0x3d3 (table 0xed85b0, 7 entries, InitializeToshi),
; [nakarest] 7 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1DE4, 0x22
; [nakarest] naka_extension_device+0x1e06  +0x1e06..+0x1e1c (0xed85d2, 22 B)
; [nakarest] name strings, entries 0-6 of ResName slot 0x3d3 (table 0xed85b0, 7 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xd3): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1E06, 0x16
; [nakarest] naka_extension_device+0x1e1c  +0x1e1c..+0x1e2a (0xed85e8, 14 B)
; [nakarest] the table itself: ResName slot 0x3e8 (table 0xed85e8, 2 entries, InitializeToshi),
; [nakarest] 2 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1E1C, 0xE
; [nakarest] naka_extension_device+0x1e2a  +0x1e2a..+0x1e32 (0xed85f6, 8 B)
; [nakarest] name strings, entries 0-1 of ResName slot 0x3e8 (table 0xed85e8, 2 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xe8): "", "SVARI".
	.incbin "includes/generated/naka_extension_device.bin", 0x1E2A, 0x8
; [nakarest] naka_extension_device+0x1e32  +0x1e32..+0x1e44 (0xed85fe, 18 B)
; [nakarest] the table itself: ResName slot 0x3e9 (table 0xed85fe, 3 entries, InitializeToshi),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1E32, 0x12
; [nakarest] naka_extension_device+0x1e44  +0x1e44..+0x1e4e (0xed8610, 10 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x3e9 (table 0xed85fe, 3 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xe9): "", "", "RVARI".
	.incbin "includes/generated/naka_extension_device.bin", 0x1E44, 0xA
; [nakarest] naka_extension_device+0x1e4e  +0x1e4e..+0x1e8c (0xed861a, 62 B)
; [nakarest] the table itself: ResName slot 0x3f4 (table 0xed861a, 14 entries, InitializeToshi),
; [nakarest] 14 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1E4E, 0x3E
; [nakarest] naka_extension_device+0x1e8c  +0x1e8c..+0x1eb6 (0xed8658, 42 B)
; [nakarest] name strings, entries 0-13 of ResName slot 0x3f4 (table 0xed861a, 14 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf4): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1E8C, 0x2A
; [nakarest] naka_extension_device+0x1eb6  +0x1eb6..+0x1f18 (0xed8682, 98 B)
; [nakarest] the table itself: ResName slot 0x3f5 (table 0xed8682, 23 entries, InitializeToshi),
; [nakarest] 23 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1EB6, 0x62
; [nakarest] naka_extension_device+0x1f18  +0x1f18..+0x1f6a (0xed86e4, 82 B)
; [nakarest] name strings, entries 0-22 of ResName slot 0x3f5 (table 0xed8682, 23 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf5): "", "", "TEST2OKNG", "", "",
; [nakarest] "TEST2NGOK", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x1F18, 0x52
; [nakarest] naka_extension_device+0x1f6a  +0x1f6a..+0x1f74 (0xed8736, 10 B)
; [nakarest] the table itself: ResName slot 0x3f6 (table 0xed8736, 1 entries, InitializeToshi),
; [nakarest] 1 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1F6A, 0xA
; [nakarest] naka_extension_device+0x1f74  +0x1f74..+0x1f7a (0xed8740, 6 B)
; [nakarest] name string, entry 0 of ResName slot 0x3f6 (table 0xed8736, 1 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf6): "TEST3".
	.incbin "includes/generated/naka_extension_device.bin", 0x1F74, 0x6
; [nakarest] naka_extension_device+0x1f7a  +0x1f7a..+0x1f8c (0xed8746, 18 B)
; [nakarest] the table itself: ResName slot 0x3f7 (table 0xed8746, 3 entries, InitializeToshi),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1F7A, 0x12
; [nakarest] naka_extension_device+0x1f8c  +0x1f8c..+0x1f96 (0xed8758, 10 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x3f7 (table 0xed8746, 3 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf7): "", "", "TEST4".
	.incbin "includes/generated/naka_extension_device.bin", 0x1F8C, 0xA
; [nakarest] naka_extension_device+0x1f96  +0x1f96..+0x20a8 (0xed8762, 274 B)
; [nakarest] the table itself: ResName slot 0x3f8 (table 0xed8762, 67 entries, InitializeToshi),
; [nakarest] 67 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x1F96, 0x112
; [nakarest] naka_extension_device+0x20a8  +0x20a8..+0x2156 (0xed8874, 174 B)
; [nakarest] name strings, entries 0-66 of ResName slot 0x3f8 (table 0xed8762, 67 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf8): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x20A8, 0xAE
; [nakarest] naka_extension_device+0x2156  +0x2156..+0x2180 (0xed8922, 42 B)
; [nakarest] the table itself: ResName slot 0x3f9 (table 0xed8922, 9 entries, InitializeToshi),
; [nakarest] 9 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x2156, 0x2A
; [nakarest] naka_extension_device+0x2180  +0x2180..+0x21a2 (0xed894c, 34 B)
; [nakarest] name strings, entries 0-8 of ResName slot 0x3f9 (table 0xed8922, 9 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xf9): "", "TEST6NG", "", "TEST6OK", "",
; [nakarest] "", ....
	.incbin "includes/generated/naka_extension_device.bin", 0x2180, 0x22
; [nakarest] naka_extension_device+0x21a2  +0x21a2..+0x21ac (0xed896e, 10 B)
; [nakarest] the table itself: ResName slot 0x3fb (table 0xed896e, 1 entries, InitializeToshi),
; [nakarest] 1 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_extension_device.bin", 0x21A2, 0xA
; [nakarest] naka_extension_device+0x21ac  +0x21ac..+0x2814 (0xed8978, 1640 B)
; [nakarest] name string, entry 0 of ResName slot 0x3fb (table 0xed896e, 1 entries,
; [nakarest] InitializeToshi) (names for Viewable slot 0xfb): "EXT".
	.incbin "includes/generated/naka_extension_device.bin", 0x21AC, 0x4
InitializeToshi_Str_MD_NORMAL:		.incbin "includes/generated/naka_extension_device.bin", 0x21B0, 0xA	; "MD_NORMAL"
InitializeToshi_Str_MD_CONTROL:		.incbin "includes/generated/naka_extension_device.bin", 0x21BA, 0xC	; "MD_CONTROL"
InitializeToshi_Str_MD_OTP:		.incbin "includes/generated/naka_extension_device.bin", 0x21C6, 0x8	; "MD_OTP"
InitializeToshi_Str_TT_NORMAL:		.incbin "includes/generated/naka_extension_device.bin", 0x21CE, 0xA	; "TT_NORMAL"
InitializeToshi_Str_TT_CTMENU:		.incbin "includes/generated/naka_extension_device.bin", 0x21D8, 0xA	; "TT_CTMENU"
InitializeToshi_Str_TT_CTINIT:		.incbin "includes/generated/naka_extension_device.bin", 0x21E2, 0xA	; "TT_CTINIT"
InitializeToshi_Str_TT_CTFSWAS:		.incbin "includes/generated/naka_extension_device.bin", 0x21EC, 0xC	; "TT_CTFSWAS"
InitializeToshi_Str_TT_CTTOUCH:		.incbin "includes/generated/naka_extension_device.bin", 0x21F8, 0xC	; "TT_CTTOUCH"
InitializeToshi_Str_TT_MSAMODE:		.incbin "includes/generated/naka_extension_device.bin", 0x2204, 0xC	; "TT_MSAMODE"
InitializeToshi_Str_TT_CTPMMD:		.incbin "includes/generated/naka_extension_device.bin", 0x2210, 0xA	; "TT_CTPMMD"
InitializeToshi_Str_TT_CTPMPARA:	.incbin "includes/generated/naka_extension_device.bin", 0x221A, 0xC	; "TT_CTPMPARA"
InitializeToshi_Str_TT_CTSYSTEM:	.incbin "includes/generated/naka_extension_device.bin", 0x2226, 0xC	; "TT_CTSYSTEM"
InitializeToshi_Str_TT_CTWALLSET:	.incbin "includes/generated/naka_extension_device.bin", 0x2232, 0xE	; "TT_CTWALLSET"
InitializeToshi_Str_TT_ONETCH:		.incbin "includes/generated/naka_extension_device.bin", 0x2240, 0xA	; "TT_ONETCH"
InitializeToshi_Str_TT_MUSICSTYL:	.incbin "includes/generated/naka_extension_device.bin", 0x224A, 0xE	; "TT_MUSICSTYL"
InitializeToshi_Str_TT_MSCTSEL:		.incbin "includes/generated/naka_extension_device.bin", 0x2258, 0xC	; "TT_MSCTSEL"
InitializeToshi_Str_TT_MSSCTSEL:	.incbin "includes/generated/naka_extension_device.bin", 0x2264, 0xC	; "TT_MSSCTSEL"
InitializeToshi_Str_TT_MSSONGLIST:	.incbin "includes/generated/naka_extension_device.bin", 0x2270, 0xE	; "TT_MSSONGLIST"
InitializeToshi_Str_TT_MSALPSEL:	.incbin "includes/generated/naka_extension_device.bin", 0x227E, 0xC	; "TT_MSALPSEL"
InitializeToshi_Str_TT_PMBKSEL:		.incbin "includes/generated/naka_extension_device.bin", 0x228A, 0xC	; "TT_PMBKSEL"
InitializeToshi_Str_TT_PMVIEW:		.incbin "includes/generated/naka_extension_device.bin", 0x2296, 0xA	; "TT_PMVIEW"
InitializeToshi_Str_TT_PMNAME:		.incbin "includes/generated/naka_extension_device.bin", 0x22A0, 0xA	; "TT_PMNAME"
InitializeToshi_Str_TT_PMBKNAME:	.incbin "includes/generated/naka_extension_device.bin", 0x22AA, 0xC	; "TT_PMBKNAME"
InitializeToshi_Str_TT_SVARI:		.incbin "includes/generated/naka_extension_device.bin", 0x22B6, 0xA	; "TT_SVARI"
InitializeToshi_Str_TT_RVARI:		.incbin "includes/generated/naka_extension_device.bin", 0x22C0, 0xA	; "TT_RVARI"
InitializeToshi_Str_TT_TEST1:		.incbin "includes/generated/naka_extension_device.bin", 0x22CA, 0xA	; "TT_TEST1"
InitializeToshi_Str_TT_TEST2:		.incbin "includes/generated/naka_extension_device.bin", 0x22D4, 0xA	; "TT_TEST2"
InitializeToshi_Str_TT_TEST3:		.incbin "includes/generated/naka_extension_device.bin", 0x22DE, 0xA	; "TT_TEST3"
InitializeToshi_Str_TT_TEST4:		.incbin "includes/generated/naka_extension_device.bin", 0x22E8, 0xA	; "TT_TEST4"
InitializeToshi_Str_TT_TEST5:		.incbin "includes/generated/naka_extension_device.bin", 0x22F2, 0xA	; "TT_TEST5"
InitializeToshi_Str_TT_TEST6:		.incbin "includes/generated/naka_extension_device.bin", 0x22FC, 0xA	; "TT_TEST6"
InitializeToshi_Str_TT_EXT:		.incbin "includes/generated/naka_extension_device.bin", 0x2306, 0x50E	; "TT_EXT"
; [nakarest] naka_extension_device+0x2814  +0x2814..+0x29e0 (0xed8fe0, 460 B)
; [nakarest] purpose not established: layout of 460 B at 0xed8fe0 not derived; readers below
; [nakarest] Readers: source references DSPCfg_ResetEntryLoop (audio/tonegen_fileio_handlers.s:
; [nakarest] `ld xbc, DSPCfg_ResetEntryLoop_Data`).
DSPCfg_ResetEntryLoop_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2814, 0x1CC
; [nakarest] naka_extension_device+0x29e0  +0x29e0..+0x2b0c (0xed91ac, 300 B)
; [nakarest] purpose not established: layout of 300 B at 0xed91ac not derived; readers below
; [nakarest] Readers: source references DSPCfg_Init_Entry0 (audio/tonegen_fileio_handlers.s: `ld
; [nakarest] xbc, DSPCfg_Init_Entry0_Data`), DSPCfg_ResetAuxEntryLoop
; [nakarest] (audio/tonegen_fileio_handlers.s: `ld xbc, DSPCfg_Init_Entry0_Data`).
DSPCfg_Init_Entry0_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x29E0, 0x12C
; [nakarest] naka_extension_device+0x2b0c  +0x2b0c..+0x2b26 (0xed92d8, 26 B)
; [nakarest] purpose not established: layout of 26 B at 0xed92d8 not derived; readers below
; [nakarest] Readers: source references ToneGen_ApplyMaskTable (audio/tonegen_fileio_handlers.s:
; [nakarest] `lda xwa, (ToneGen_ApplyMaskTable_Data:24)`).
ToneGen_ApplyMaskTable_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2B0C, 0x1A
; [nakarest] naka_extension_device+0x2b26  +0x2b26..+0x2b3e (0xed92f2, 24 B)
; [nakarest] purpose not established: layout of 24 B at 0xed92f2 not derived; readers below
; [nakarest] Readers: source references Voice_InitChannelLoop (audio/tonegen_fileio_handlers.s:
; [nakarest] `ld xbc, Voice_InitChannelLoop_Data`).
Voice_InitChannelLoop_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2B26, 0x18
; [nakarest] naka_extension_device+0x2b3e  +0x2b3e..+0x2b6e (0xed930a, 48 B)
; [nakarest] purpose not established: layout of 48 B at 0xed930a not derived; readers below
; [nakarest] Readers: source references DSPCfg_Init_BoundsCheck
; [nakarest] (audio/tonegen_fileio_handlers.s: `lda xix,
; [nakarest] (DSPCfg_Init_BoundsCheck_Data:24)`).
DSPCfg_Init_BoundsCheck_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2B3E, 0x12
ToneGen_FlashWriteAll_Data_3:	.incbin "includes/generated/naka_extension_device.bin", 0x2B50, 0x4
ToneGen_FlashWriteAll_Data_4:	.incbin "includes/generated/naka_extension_device.bin", 0x2B54, 0x4
ToneGen_FlashWriteAll_Data_5:	.incbin "includes/generated/naka_extension_device.bin", 0x2B58, 0xC
ToneGen_FlashWriteAll_Data_6:	.incbin "includes/generated/naka_extension_device.bin", 0x2B64, 0x4
ToneGen_FlashWriteAll_Data_7:	.incbin "includes/generated/naka_extension_device.bin", 0x2B68, 0x6
; [nakarest] naka_extension_device+0x2b6e  +0x2b6e..+0x2e3c (0xed933a, 718 B)
; [nakarest] purpose not established: layout of 718 B at 0xed933a not derived; readers below
; [nakarest] Readers: source references ToneGen_FlashVerify (audio/tonegen_fileio_handlers.s:
; [nakarest] `lda xhl, (ToneGen_FlashVerify_Str_HK:24)`).
ToneGen_FlashVerify_Str_HK:	.incbin "includes/generated/naka_extension_device.bin", 0x2B6E, 0xFA	; "HK "
ToneGen_FlashWriteAll_Data:	.incbin "includes/generated/naka_extension_device.bin", 0x2C68, 0xEA
ToneGen_FlashWriteAll_Data_2:	.incbin "includes/generated/naka_extension_device.bin", 0x2D52, 0xEA
; [nakarest] naka_extension_device+0x2e3c  +0x2e3c..+0x2e4e (0xed9608, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xed9608 not derived; readers below
; [nakarest] Readers: source references CtrlPanel_IndicatorJumpTable
; [nakarest] (audio/tonegen_fileio_handlers.s: `lda xix,
; [nakarest] (CtrlPanel_IndicatorJumpTable_Data:24)`).
CtrlPanel_IndicatorJumpTable_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2E3C, 0x12
; [nakarest] naka_extension_device+0x2e4e  +0x2e4e..+0x2e60 (0xed961a, 18 B)
; [nakarest] purpose not established: layout of 18 B at 0xed961a not derived; readers below
; [nakarest] Readers: source references Audio_DispatchCommand (audio/tonegen_fileio_handlers.s:
; [nakarest] `lda xix, (Audio_DispatchCommand_Data:24)`).
Audio_DispatchCommand_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2E4E, 0x12
; [nakarest] naka_extension_device+0x2e60  +0x2e60..+0x3452 (0xed962c, 1522 B)
; [nakarest] purpose not established: layout of 1522 B at 0xed962c not derived; readers below
; [nakarest] Readers: source references PanelDisplay_DispatchByMode
; [nakarest] (audio/tonegen_fileio_handlers.s: `lda xix,
; [nakarest] (PanelDisplay_DispatchByMode_Data:24)`); 32 data words in
; [nakarest] Encoder_PrepareCallback_PtrTable (at 0xed9c1e, 0xed9c22, 0xed9c26), which is read
; [nakarest] by Encoder_PrepareCallback (audio/tonegen_fileio_handlers.s: `ld
; [nakarest] XWA,Encoder_PrepareCallback_PtrTable`); 32 data words in
; [nakarest] Encoder_PrepareCallback_PtrTable_2 (at 0xed9c9e, 0xed9ca2, 0xed9ca6), which is read
; [nakarest] by Encoder_PrepareCallback (audio/tonegen_fileio_handlers.s: `ld
; [nakarest] XWA,Encoder_PrepareCallback_PtrTable_2`).
PanelDisplay_DispatchByMode_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x2E60, 0x5F2
; [nakarest] naka_extension_device+0x3452  +0x3452..+0x34d2 (0xed9c1e, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xed9c1e not derived; readers below
; [nakarest] Readers: source references Encoder_PrepareCallback
; [nakarest] (audio/tonegen_fileio_handlers.s: `ld XWA,Encoder_PrepareCallback_PtrTable`).
Encoder_PrepareCallback_PtrTable:	.incbin "includes/generated/naka_extension_device.bin", 0x3452, 0x80	; 68 x 32-bit pointer
; [nakarest] naka_extension_device+0x34d2  +0x34d2..+0x3552 (0xed9c9e, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xed9c9e not derived; readers below
; [nakarest] Readers: source references Encoder_PrepareCallback
; [nakarest] (audio/tonegen_fileio_handlers.s: `ld XWA,Encoder_PrepareCallback_PtrTable_2`).
Encoder_PrepareCallback_PtrTable_2:	.incbin "includes/generated/naka_extension_device.bin", 0x34D2, 0x80	; 36 x 32-bit pointer
; [nakarest] SoundParam_EncoderMappingData  +0x3552..+0x3860 (0xed9d1e, 782 B)
; [nakarest] purpose not established: layout of 782 B at 0xed9d1e not derived; readers below
; [nakarest] Readers: source references SystemConfig_PointerTable (ui_widgets/widget_dispatch.s:
; [nakarest] `.long SoundParam_EncoderMappingData`); 1 data word in SystemConfig_PointerTable
; [nakarest] (at 0xee8ca6).
SoundParam_EncoderMappingData:			.incbin "includes/generated/naka_extension_device.bin", 0x3552, 0x12
FileIO_BytecodeData_Data:			.incbin "includes/generated/naka_extension_device.bin", 0x3564, 0x2
FileIO_BytecodeData_Data_2:			.incbin "includes/generated/naka_extension_device.bin", 0x3566, 0x2
FileIO_BytecodeData_Data_3:			.incbin "includes/generated/naka_extension_device.bin", 0x3568, 0x2
FileIO_BytecodeData_Data_4:			.incbin "includes/generated/naka_extension_device.bin", 0x356A, 0x2
FileIO_BytecodeData_Data_5:			.incbin "includes/generated/naka_extension_device.bin", 0x356C, 0x4
FileIO_BytecodeData_Data_6:			.incbin "includes/generated/naka_extension_device.bin", 0x3570, 0x8
FileIO_BytecodeData_Data_7:			.incbin "includes/generated/naka_extension_device.bin", 0x3578, 0x8
FileIO_BytecodeData_Data_8:			.incbin "includes/generated/naka_extension_device.bin", 0x3580, 0x2
FileIO_BytecodeData_Data_9:			.incbin "includes/generated/naka_extension_device.bin", 0x3582, 0x8
FileIO_BytecodeData_Data_10:			.incbin "includes/generated/naka_extension_device.bin", 0x358A, 0x2
FileIO_BytecodeData_Data_11:			.incbin "includes/generated/naka_extension_device.bin", 0x358C, 0x8
FileIO_BytecodeData_Data_12:			.incbin "includes/generated/naka_extension_device.bin", 0x3594, 0x4
FileIO_BytecodeData_Code_Entry8_PtrTable:	.incbin "includes/generated/naka_extension_device.bin", 0x3598, 0x18	; 6 x 32-bit pointer
FileIO_BytecodeData_Data_13:			.incbin "includes/generated/naka_extension_device.bin", 0x35B0, 0x6
FileIO_BytecodeData_Code_Entry8_PtrTable_2:	.incbin "includes/generated/naka_extension_device.bin", 0x35B6, 0x18	; 6 x 32-bit pointer
FileIO_BytecodeData_Data_14:			.incbin "includes/generated/naka_extension_device.bin", 0x35CE, 0x6
FileIO_BytecodeData_Data_15:			.incbin "includes/generated/naka_extension_device.bin", 0x35D4, 0x4
FileIO_BytecodeData_Data_16:			.incbin "includes/generated/naka_extension_device.bin", 0x35D8, 0x100
FileIO_BytecodeData_Code_Entry8_PtrTable_3:	.incbin "includes/generated/naka_extension_device.bin", 0x36D8, 0xB0	; 22 x 32-bit pointer
ExtDevScreen_UserInitWallpaper_Flag:		.incbin "includes/generated/naka_extension_device.bin", 0x3788, 0x8
ExtDevScreen_UserInitWallpaper_Data:		.incbin "includes/generated/naka_extension_device.bin", 0x3790, 0x48
ExtDev_SndParam_DispatchComplex_PtrTable:	.incbin "includes/generated/naka_extension_device.bin", 0x37D8, 0x7C	; 8 x 32-bit pointer
Audio_CopyStateFromROM_Data:			.incbin "includes/generated/naka_extension_device.bin", 0x3854, 0xC
; [nakarest] EffectMode_DispatchTable  +0x3860..+0x3870 (0xeda02c, 16 B)
; [nakarest] purpose not established: layout of 16 B at 0xeda02c not derived; readers below
; [nakarest] Readers: source references SystemConfig_PointerTable (ui_widgets/widget_dispatch.s:
; [nakarest] `.long EffectMode_DispatchTable`); 1 data word in SystemConfig_PointerTable (at
; [nakarest] 0xee8ca2).
EffectMode_DispatchTable:
	.incbin "includes/generated/naka_extension_device.bin", 0x3860, 0x10
; [nakarest] naka_extension_device+0x3870  +0x3870..+0x38f0 (0xeda03c, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xeda03c not derived; readers below
; [nakarest] Readers: source references MidiCC_LookupHandler (audio/audio_control_engine.s: `lda
; [nakarest] xbc, (MidiCC_LookupHandler_Data:24)`).
MidiCC_LookupHandler_Data:
	.incbin "includes/generated/naka_extension_device.bin", 0x3870, 0x80
; [nakarest] ENCODER_HANDLER_TABLE  +0x38f0..+0x3970 (0xeda0bc, 128 B)
; [nakarest] purpose not established: layout of 128 B at 0xeda0bc not derived; readers below
; [nakarest] Readers: source references CPanel_EncoderDispatch (midi/midi_encoder_routines.s:
; [nakarest] `lda xde, (ENCODER_HANDLER_TABLE:24)`).
ENCODER_HANDLER_TABLE:
	.incbin "includes/generated/naka_extension_device.bin", 0x38F0, 0x80
; [nakarest] ENCODER_LUT_MODWHEEL  +0x3970..+0x3994 (0xeda13c, 36 B)
; [nakarest] 36 B at 0xeda13c: split since into the labelled pieces below; code or data uses ENCODER_LUT_MODWHEEL.
ENCODER_LUT_MODWHEEL:
	.incbin "includes/generated/naka_extension_device.bin", 0x3970, 0x24
; External label offsets within the binary blob above.
