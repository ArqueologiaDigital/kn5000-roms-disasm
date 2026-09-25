
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_ExtDevice_Screens
; NakaInst_ExtDevice_Screens  --  naka_extension_device +0x0..+0x2c (ROM 0xed67cc..0xed67f8), 44 bytes
; Widget records of element 13 of Viewable slot 0xf4 (table 0xed7c62, 14
; entries, InitializeToshi); classes: TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaInst_ExtDevice_Screens:
	.incbin "includes/generated/naka_extension_device.bin", 0x0, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x2c
; naka_extension_device+0x2c  --  naka_extension_device +0x2c..+0x41a (ROM 0xed67f8..0xed6be6), 1006 bytes
; Widget records of elements 0-22 of Viewable slot 0xf5 (table 0xed7c9e,
; 23 entries, InitializeToshi), element 0 "TEST2"; classes: TtlScreen
; (42 B, id 0x01600034), TextBox (40 B, id 0x01600036), Label (32 B, id
; 0x0160002b) x13, IvPageControl (28 B, id 0x01600028) x4, Window (36 B,
; id 0x01600035) x4.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x2C, 0x3EE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x41a
; naka_extension_device+0x41a  --  naka_extension_device +0x41a..+0x44e (ROM 0xed6be6..0xed6c1a), 52 bytes
; Widget records of element 0 of Viewable slot 0xf6 (table 0xed7cfe, 1
; entries, InitializeToshi), element 0 "TEST3"; classes: SineWaveScreen
; (52 B, id 0x0162001a).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x41A, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x44e
; naka_extension_device+0x44e  --  naka_extension_device +0x44e..+0x548 (ROM 0xed6c1a..0xed6d14), 250 bytes
; Widget records of elements 0-2 of Viewable slot 0xf7 (table 0xed7d06,
; 3 entries, InitializeToshi), element 0 "TEST4"; classes: TtlScreen (42
; B, id 0x01600034), TextBox (40 B, id 0x01600036), Label (32 B, id
; 0x0160002b).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x44E, 0xFA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x548
; naka_extension_device+0x548  --  naka_extension_device +0x548..+0xe6c (ROM 0xed6d14..0xed7638), 2340 bytes
; Widget records of elements 0-66 of Viewable slot 0xf8 (table 0xed7d16,
; 67 entries, InitializeToshi), element 0 "TEST5"; classes: TtlScreen
; (42 B, id 0x01600034), IvPageControl (28 B, id 0x01600028) x5, Window
; (36 B, id 0x01600035) x6, Label (32 B, id 0x0160002b) x50, Frame (28
; B, id 0x0160002f) x5.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x548, 0x924
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0xe6c
; naka_extension_device+0xe6c  --  naka_extension_device +0xe6c..+0xfe0 (ROM 0xed7638..0xed77ac), 372 bytes
; Widget records of elements 0-8 of Viewable slot 0xf9 (table 0xed7e26,
; 9 entries, InitializeToshi), element 0 "TEST6"; classes: TtlScreen (42
; B, id 0x01600034), Label (32 B, id 0x0160002b) x4, IvPageControl (28
; B, id 0x01600028) x2, Window (36 B, id 0x01600035) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0xE6C, 0x174
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0xfe0
; naka_extension_device+0xfe0  --  naka_extension_device +0xfe0..+0x1002 (ROM 0xed77ac..0xed77ce), 34 bytes
; Widget records of element 0 of Viewable slot 0xfb (table 0xed7e4e, 1
; entries, InitializeToshi), element 0 "EXT"; classes: IvScreen (34 B,
; id 0x0160006a).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0xFE0, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1002
; naka_extension_device+0x1002  --  naka_extension_device +0x1002..+0x1102 (ROM 0xed77ce..0xed78ce), 256 bytes
; The table itself: Viewable slot 0x1 (table 0xed77ce, 63 entries,
; InitializeToshi) -- 63 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1002, 0x100
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1102
; naka_extension_device+0x1102  --  naka_extension_device +0x1102..+0x112a (ROM 0xed78ce..0xed78f6), 40 bytes
; The table itself: Viewable slot 0x40 (table 0xed78ce, 9 entries,
; InitializeToshi) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1102, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x112a
; naka_extension_device+0x112a  --  naka_extension_device +0x112a..+0x1172 (ROM 0xed78f6..0xed793e), 72 bytes
; The table itself: Viewable slot 0x41 (table 0xed78f6, 17 entries,
; InitializeToshi) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x112A, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1172
; naka_extension_device+0x1172  --  naka_extension_device +0x1172..+0x118e (ROM 0xed793e..0xed795a), 28 bytes
; The table itself: Viewable slot 0x42 (table 0xed793e, 6 entries,
; InitializeToshi) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1172, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x118e
; naka_extension_device+0x118e  --  naka_extension_device +0x118e..+0x11b2 (ROM 0xed795a..0xed797e), 36 bytes
; The table itself: Viewable slot 0x43 (table 0xed795a, 8 entries,
; InitializeToshi) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x118E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x11b2
; naka_extension_device+0x11b2  --  naka_extension_device +0x11b2..+0x1202 (ROM 0xed797e..0xed79ce), 80 bytes
; The table itself: Viewable slot 0x44 (table 0xed797e, 19 entries,
; InitializeToshi) -- 19 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x11B2, 0x50
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1202
; naka_extension_device+0x1202  --  naka_extension_device +0x1202..+0x1252 (ROM 0xed79ce..0xed7a1e), 80 bytes
; The table itself: Viewable slot 0x45 (table 0xed79ce, 19 entries,
; InitializeToshi) -- 19 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1202, 0x50
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1252
; naka_extension_device+0x1252  --  naka_extension_device +0x1252..+0x1256 (ROM 0xed7a1e..0xed7a22), 4 bytes
; The table itself: Viewable slot 0x46 (table 0xed7a1e, 0 entries,
; InitializeToshi) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1252, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1256
; naka_extension_device+0x1256  --  naka_extension_device +0x1256..+0x1276 (ROM 0xed7a22..0xed7a42), 32 bytes
; The table itself: Viewable slot 0x47 (table 0xed7a22, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1256, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1276
; naka_extension_device+0x1276  --  naka_extension_device +0x1276..+0x12de (ROM 0xed7a42..0xed7aaa), 104 bytes
; The table itself: Viewable slot 0x48 (table 0xed7a42, 25 entries,
; InitializeToshi) -- 25 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1276, 0x68
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x12de
; naka_extension_device+0x12de  --  naka_extension_device +0x12de..+0x12f2 (ROM 0xed7aaa..0xed7abe), 20 bytes
; The table itself: Viewable slot 0xc0 (table 0xed7aaa, 4 entries,
; InitializeToshi) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x12DE, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x12f2
; naka_extension_device+0x12f2  --  naka_extension_device +0x12f2..+0x1306 (ROM 0xed7abe..0xed7ad2), 20 bytes
; The table itself: Viewable slot 0xc1 (table 0xed7abe, 4 entries,
; InitializeToshi) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x12F2, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1306
; naka_extension_device+0x1306  --  naka_extension_device +0x1306..+0x135a (ROM 0xed7ad2..0xed7b26), 84 bytes
; The table itself: Viewable slot 0xc2 (table 0xed7ad2, 20 entries,
; InitializeToshi) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1306, 0x54
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x135a
; naka_extension_device+0x135a  --  naka_extension_device +0x135a..+0x13a2 (ROM 0xed7b26..0xed7b6e), 72 bytes
; The table itself: Viewable slot 0xc3 (table 0xed7b26, 17 entries,
; InitializeToshi) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x135A, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x13a2
; naka_extension_device+0x13a2  --  naka_extension_device +0x13a2..+0x13c6 (ROM 0xed7b6e..0xed7b92), 36 bytes
; The table itself: Viewable slot 0xc4 (table 0xed7b6e, 8 entries,
; InitializeToshi) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x13A2, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x13c6
; naka_extension_device+0x13c6  --  naka_extension_device +0x13c6..+0x13e6 (ROM 0xed7b92..0xed7bb2), 32 bytes
; The table itself: Viewable slot 0xc5 (table 0xed7b92, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x13C6, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x13e6
; naka_extension_device+0x13e6  --  naka_extension_device +0x13e6..+0x1402 (ROM 0xed7bb2..0xed7bce), 28 bytes
; The table itself: Viewable slot 0xd0 (table 0xed7bb2, 6 entries,
; InitializeToshi) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x13E6, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1402
; naka_extension_device+0x1402  --  naka_extension_device +0x1402..+0x143a (ROM 0xed7bce..0xed7c06), 56 bytes
; The table itself: Viewable slot 0xd1 (table 0xed7bce, 13 entries,
; InitializeToshi) -- 13 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1402, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x143a
; naka_extension_device+0x143a  --  naka_extension_device +0x143a..+0x145a (ROM 0xed7c06..0xed7c26), 32 bytes
; The table itself: Viewable slot 0xd2 (table 0xed7c06, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x143A, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x145a
; naka_extension_device+0x145a  --  naka_extension_device +0x145a..+0x147a (ROM 0xed7c26..0xed7c46), 32 bytes
; The table itself: Viewable slot 0xd3 (table 0xed7c26, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x145A, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x147a
; naka_extension_device+0x147a  --  naka_extension_device +0x147a..+0x1486 (ROM 0xed7c46..0xed7c52), 12 bytes
; The table itself: Viewable slot 0xe8 (table 0xed7c46, 2 entries,
; InitializeToshi) -- 2 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x147A, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1486
; naka_extension_device+0x1486  --  naka_extension_device +0x1486..+0x1496 (ROM 0xed7c52..0xed7c62), 16 bytes
; The table itself: Viewable slot 0xe9 (table 0xed7c52, 3 entries,
; InitializeToshi) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1486, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1496
; naka_extension_device+0x1496  --  naka_extension_device +0x1496..+0x14d2 (ROM 0xed7c62..0xed7c9e), 60 bytes
; The table itself: Viewable slot 0xf4 (table 0xed7c62, 14 entries,
; InitializeToshi) -- 14 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1496, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x14d2
; naka_extension_device+0x14d2  --  naka_extension_device +0x14d2..+0x1532 (ROM 0xed7c9e..0xed7cfe), 96 bytes
; The table itself: Viewable slot 0xf5 (table 0xed7c9e, 23 entries,
; InitializeToshi) -- 23 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x14D2, 0x60
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1532
; naka_extension_device+0x1532  --  naka_extension_device +0x1532..+0x153a (ROM 0xed7cfe..0xed7d06), 8 bytes
; The table itself: Viewable slot 0xf6 (table 0xed7cfe, 1 entries,
; InitializeToshi) -- 1 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1532, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x153a
; naka_extension_device+0x153a  --  naka_extension_device +0x153a..+0x154a (ROM 0xed7d06..0xed7d16), 16 bytes
; The table itself: Viewable slot 0xf7 (table 0xed7d06, 3 entries,
; InitializeToshi) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x153A, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x154a
; naka_extension_device+0x154a  --  naka_extension_device +0x154a..+0x165a (ROM 0xed7d16..0xed7e26), 272 bytes
; The table itself: Viewable slot 0xf8 (table 0xed7d16, 67 entries,
; InitializeToshi) -- 67 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x154A, 0x110
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x165a
; naka_extension_device+0x165a  --  naka_extension_device +0x165a..+0x1682 (ROM 0xed7e26..0xed7e4e), 40 bytes
; The table itself: Viewable slot 0xf9 (table 0xed7e26, 9 entries,
; InitializeToshi) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x165A, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1682
; naka_extension_device+0x1682  --  naka_extension_device +0x1682..+0x168a (ROM 0xed7e4e..0xed7e56), 8 bytes
; The table itself: Viewable slot 0xfb (table 0xed7e4e, 1 entries,
; InitializeToshi) -- 1 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1682, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x168a
; naka_extension_device+0x168a  --  naka_extension_device +0x168a..+0x178c (ROM 0xed7e56..0xed7f58), 258 bytes
; The table itself: ResName slot 0x301 (table 0xed7e56, 63 entries,
; InitializeToshi) -- 63 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x168A, 0x102
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x178c
; naka_extension_device+0x178c  --  naka_extension_device +0x178c..+0x182a (ROM 0xed7f58..0xed7ff6), 158 bytes
; Name strings of elements 0-62 of ResName slot 0x301 (table 0xed7e56,
; 63 entries, InitializeToshi), names for Viewable slot 0x1: "", "",
; "FADEOUT", "", "", "FADEIN", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x178C, 0x9E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x182a
; naka_extension_device+0x182a  --  naka_extension_device +0x182a..+0x1854 (ROM 0xed7ff6..0xed8020), 42 bytes
; The table itself: ResName slot 0x340 (table 0xed7ff6, 9 entries,
; InitializeToshi) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x182A, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1854
; naka_extension_device+0x1854  --  naka_extension_device +0x1854..+0x1870 (ROM 0xed8020..0xed803c), 28 bytes
; Name strings of elements 0-8 of ResName slot 0x340 (table 0xed7ff6, 9
; entries, InitializeToshi), names for Viewable slot 0x40: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1854, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1870
; naka_extension_device+0x1870  --  naka_extension_device +0x1870..+0x18ba (ROM 0xed803c..0xed8086), 74 bytes
; The table itself: ResName slot 0x341 (table 0xed803c, 17 entries,
; InitializeToshi) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1870, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x18ba
; naka_extension_device+0x18ba  --  naka_extension_device +0x18ba..+0x18f6 (ROM 0xed8086..0xed80c2), 60 bytes
; Name strings of elements 0-16 of ResName slot 0x341 (table 0xed803c,
; 17 entries, InitializeToshi), names for Viewable slot 0x41: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x18BA, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x18f6
; naka_extension_device+0x18f6  --  naka_extension_device +0x18f6..+0x1914 (ROM 0xed80c2..0xed80e0), 30 bytes
; The table itself: ResName slot 0x342 (table 0xed80c2, 6 entries,
; InitializeToshi) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x18F6, 0x1E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1914
; naka_extension_device+0x1914  --  naka_extension_device +0x1914..+0x192a (ROM 0xed80e0..0xed80f6), 22 bytes
; Name strings of elements 0-5 of ResName slot 0x342 (table 0xed80c2, 6
; entries, InitializeToshi), names for Viewable slot 0x42: "", "", "",
; "", "", "ControlFsw".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1914, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x192a
; naka_extension_device+0x192a  --  naka_extension_device +0x192a..+0x1950 (ROM 0xed80f6..0xed811c), 38 bytes
; The table itself: ResName slot 0x343 (table 0xed80f6, 8 entries,
; InitializeToshi) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x192A, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1950
; naka_extension_device+0x1950  --  naka_extension_device +0x1950..+0x196a (ROM 0xed811c..0xed8136), 26 bytes
; Name strings of elements 0-7 of ResName slot 0x343 (table 0xed80f6, 8
; entries, InitializeToshi), names for Viewable slot 0x43: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1950, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x196a
; naka_extension_device+0x196a  --  naka_extension_device +0x196a..+0x19bc (ROM 0xed8136..0xed8188), 82 bytes
; The table itself: ResName slot 0x344 (table 0xed8136, 19 entries,
; InitializeToshi) -- 19 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x196A, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x19bc
; naka_extension_device+0x19bc  --  naka_extension_device +0x19bc..+0x19e2 (ROM 0xed8188..0xed81ae), 38 bytes
; Name strings of elements 0-18 of ResName slot 0x344 (table 0xed8136,
; 19 entries, InitializeToshi), names for Viewable slot 0x44: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x19BC, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x19e2
; naka_extension_device+0x19e2  --  naka_extension_device +0x19e2..+0x1a34 (ROM 0xed81ae..0xed8200), 82 bytes
; The table itself: ResName slot 0x345 (table 0xed81ae, 19 entries,
; InitializeToshi) -- 19 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x19E2, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1a34
; naka_extension_device+0x1a34  --  naka_extension_device +0x1a34..+0x1a62 (ROM 0xed8200..0xed822e), 46 bytes
; Name strings of elements 0-18 of ResName slot 0x345 (table 0xed81ae,
; 19 entries, InitializeToshi), names for Viewable slot 0x45: "", "",
; "", "", "", "PMEM2", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1A34, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1a62
; naka_extension_device+0x1a62  --  naka_extension_device +0x1a62..+0x1a68 (ROM 0xed822e..0xed8234), 6 bytes
; The table itself: ResName slot 0x346 (table 0xed822e, 0 entries,
; InitializeToshi) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1A62, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1a68
; naka_extension_device+0x1a68  --  naka_extension_device +0x1a68..+0x1a8a (ROM 0xed8234..0xed8256), 34 bytes
; The table itself: ResName slot 0x347 (table 0xed8234, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1A68, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1a8a
; naka_extension_device+0x1a8a  --  naka_extension_device +0x1a8a..+0x1aa2 (ROM 0xed8256..0xed826e), 24 bytes
; Name strings of elements 0-6 of ResName slot 0x347 (table 0xed8234, 7
; entries, InitializeToshi), names for Viewable slot 0x47: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1A8A, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1aa2
; naka_extension_device+0x1aa2  --  naka_extension_device +0x1aa2..+0x1b0c (ROM 0xed826e..0xed82d8), 106 bytes
; The table itself: ResName slot 0x348 (table 0xed826e, 25 entries,
; InitializeToshi) -- 25 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1AA2, 0x6A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1b0c
; naka_extension_device+0x1b0c  --  naka_extension_device +0x1b0c..+0x1b56 (ROM 0xed82d8..0xed8322), 74 bytes
; Name strings of elements 0-24 of ResName slot 0x348 (table 0xed826e,
; 25 entries, InitializeToshi), names for Viewable slot 0x48: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1B0C, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1b56
; naka_extension_device+0x1b56  --  naka_extension_device +0x1b56..+0x1b6c (ROM 0xed8322..0xed8338), 22 bytes
; The table itself: ResName slot 0x3c0 (table 0xed8322, 4 entries,
; InitializeToshi) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1B56, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1b6c
; naka_extension_device+0x1b6c  --  naka_extension_device +0x1b6c..+0x1b7a (ROM 0xed8338..0xed8346), 14 bytes
; Name strings of elements 0-3 of ResName slot 0x3c0 (table 0xed8322, 4
; entries, InitializeToshi), names for Viewable slot 0xc0: "", "", "",
; "ONETCH".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1B6C, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1b7a
; naka_extension_device+0x1b7a  --  naka_extension_device +0x1b7a..+0x1b90 (ROM 0xed8346..0xed835c), 22 bytes
; The table itself: ResName slot 0x3c1 (table 0xed8346, 4 entries,
; InitializeToshi) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1B7A, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1b90
; naka_extension_device+0x1b90  --  naka_extension_device +0x1b90..+0x1ba0 (ROM 0xed835c..0xed836c), 16 bytes
; Name strings of elements 0-3 of ResName slot 0x3c1 (table 0xed8346, 4
; entries, InitializeToshi), names for Viewable slot 0xc1: "", "", "",
; "MUSICSTYL".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1B90, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1ba0
; naka_extension_device+0x1ba0  --  naka_extension_device +0x1ba0..+0x1bf6 (ROM 0xed836c..0xed83c2), 86 bytes
; The table itself: ResName slot 0x3c2 (table 0xed836c, 20 entries,
; InitializeToshi) -- 20 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1BA0, 0x56
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1bf6
; naka_extension_device+0x1bf6  --  naka_extension_device +0x1bf6..+0x1c30 (ROM 0xed83c2..0xed83fc), 58 bytes
; Name strings of elements 0-19 of ResName slot 0x3c2 (table 0xed836c,
; 20 entries, InitializeToshi), names for Viewable slot 0xc2: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1BF6, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1c30
; naka_extension_device+0x1c30  --  naka_extension_device +0x1c30..+0x1c7a (ROM 0xed83fc..0xed8446), 74 bytes
; The table itself: ResName slot 0x3c3 (table 0xed83fc, 17 entries,
; InitializeToshi) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1C30, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1c7a
; naka_extension_device+0x1c7a  --  naka_extension_device +0x1c7a..+0x1cac (ROM 0xed8446..0xed8478), 50 bytes
; Name strings of elements 0-16 of ResName slot 0x3c3 (table 0xed83fc,
; 17 entries, InitializeToshi), names for Viewable slot 0xc3: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1C7A, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1cac
; naka_extension_device+0x1cac  --  naka_extension_device +0x1cac..+0x1cd2 (ROM 0xed8478..0xed849e), 38 bytes
; The table itself: ResName slot 0x3c4 (table 0xed8478, 8 entries,
; InitializeToshi) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1CAC, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1cd2
; naka_extension_device+0x1cd2  --  naka_extension_device +0x1cd2..+0x1cec (ROM 0xed849e..0xed84b8), 26 bytes
; Name strings of elements 0-7 of ResName slot 0x3c4 (table 0xed8478, 8
; entries, InitializeToshi), names for Viewable slot 0xc4: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1CD2, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1cec
; naka_extension_device+0x1cec  --  naka_extension_device +0x1cec..+0x1d0e (ROM 0xed84b8..0xed84da), 34 bytes
; The table itself: ResName slot 0x3c5 (table 0xed84b8, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1CEC, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1d0e
; naka_extension_device+0x1d0e  --  naka_extension_device +0x1d0e..+0x1d24 (ROM 0xed84da..0xed84f0), 22 bytes
; Name strings of elements 0-6 of ResName slot 0x3c5 (table 0xed84b8, 7
; entries, InitializeToshi), names for Viewable slot 0xc5: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1D0E, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1d24
; naka_extension_device+0x1d24  --  naka_extension_device +0x1d24..+0x1d42 (ROM 0xed84f0..0xed850e), 30 bytes
; The table itself: ResName slot 0x3d0 (table 0xed84f0, 6 entries,
; InitializeToshi) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1D24, 0x1E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1d42
; naka_extension_device+0x1d42  --  naka_extension_device +0x1d42..+0x1d54 (ROM 0xed850e..0xed8520), 18 bytes
; Name strings of elements 0-5 of ResName slot 0x3d0 (table 0xed84f0, 6
; entries, InitializeToshi), names for Viewable slot 0xd0: "", "", "",
; "", "", "PMBANK".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1D42, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1d54
; naka_extension_device+0x1d54  --  naka_extension_device +0x1d54..+0x1d8e (ROM 0xed8520..0xed855a), 58 bytes
; The table itself: ResName slot 0x3d1 (table 0xed8520, 13 entries,
; InitializeToshi) -- 13 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1D54, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1d8e
; naka_extension_device+0x1d8e  --  naka_extension_device +0x1d8e..+0x1dae (ROM 0xed855a..0xed857a), 32 bytes
; Name strings of elements 0-12 of ResName slot 0x3d1 (table 0xed8520,
; 13 entries, InitializeToshi), names for Viewable slot 0xd1: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1D8E, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1dae
; naka_extension_device+0x1dae  --  naka_extension_device +0x1dae..+0x1dd0 (ROM 0xed857a..0xed859c), 34 bytes
; The table itself: ResName slot 0x3d2 (table 0xed857a, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1DAE, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1dd0
; naka_extension_device+0x1dd0  --  naka_extension_device +0x1dd0..+0x1de4 (ROM 0xed859c..0xed85b0), 20 bytes
; Name strings of elements 0-6 of ResName slot 0x3d2 (table 0xed857a, 7
; entries, InitializeToshi), names for Viewable slot 0xd2: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1DD0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1de4
; naka_extension_device+0x1de4  --  naka_extension_device +0x1de4..+0x1e06 (ROM 0xed85b0..0xed85d2), 34 bytes
; The table itself: ResName slot 0x3d3 (table 0xed85b0, 7 entries,
; InitializeToshi) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1DE4, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e06
; naka_extension_device+0x1e06  --  naka_extension_device +0x1e06..+0x1e1c (ROM 0xed85d2..0xed85e8), 22 bytes
; Name strings of elements 0-6 of ResName slot 0x3d3 (table 0xed85b0, 7
; entries, InitializeToshi), names for Viewable slot 0xd3: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E06, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e1c
; naka_extension_device+0x1e1c  --  naka_extension_device +0x1e1c..+0x1e2a (ROM 0xed85e8..0xed85f6), 14 bytes
; The table itself: ResName slot 0x3e8 (table 0xed85e8, 2 entries,
; InitializeToshi) -- 2 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E1C, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e2a
; naka_extension_device+0x1e2a  --  naka_extension_device +0x1e2a..+0x1e32 (ROM 0xed85f6..0xed85fe), 8 bytes
; Name strings of elements 0-1 of ResName slot 0x3e8 (table 0xed85e8, 2
; entries, InitializeToshi), names for Viewable slot 0xe8: "", "SVARI".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E2A, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e32
; naka_extension_device+0x1e32  --  naka_extension_device +0x1e32..+0x1e44 (ROM 0xed85fe..0xed8610), 18 bytes
; The table itself: ResName slot 0x3e9 (table 0xed85fe, 3 entries,
; InitializeToshi) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E32, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e44
; naka_extension_device+0x1e44  --  naka_extension_device +0x1e44..+0x1e4e (ROM 0xed8610..0xed861a), 10 bytes
; Name strings of elements 0-2 of ResName slot 0x3e9 (table 0xed85fe, 3
; entries, InitializeToshi), names for Viewable slot 0xe9: "", "",
; "RVARI".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E44, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e4e
; naka_extension_device+0x1e4e  --  naka_extension_device +0x1e4e..+0x1e8c (ROM 0xed861a..0xed8658), 62 bytes
; The table itself: ResName slot 0x3f4 (table 0xed861a, 14 entries,
; InitializeToshi) -- 14 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E4E, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1e8c
; naka_extension_device+0x1e8c  --  naka_extension_device +0x1e8c..+0x1eb6 (ROM 0xed8658..0xed8682), 42 bytes
; Name strings of elements 0-13 of ResName slot 0x3f4 (table 0xed861a,
; 14 entries, InitializeToshi), names for Viewable slot 0xf4: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1E8C, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1eb6
; naka_extension_device+0x1eb6  --  naka_extension_device +0x1eb6..+0x1f18 (ROM 0xed8682..0xed86e4), 98 bytes
; The table itself: ResName slot 0x3f5 (table 0xed8682, 23 entries,
; InitializeToshi) -- 23 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1EB6, 0x62
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f18
; naka_extension_device+0x1f18  --  naka_extension_device +0x1f18..+0x1f6a (ROM 0xed86e4..0xed8736), 82 bytes
; Name strings of elements 0-22 of ResName slot 0x3f5 (table 0xed8682,
; 23 entries, InitializeToshi), names for Viewable slot 0xf5: "", "",
; "TEST2OKNG", "", "", "TEST2NGOK", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F18, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f6a
; naka_extension_device+0x1f6a  --  naka_extension_device +0x1f6a..+0x1f74 (ROM 0xed8736..0xed8740), 10 bytes
; The table itself: ResName slot 0x3f6 (table 0xed8736, 1 entries,
; InitializeToshi) -- 1 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F6A, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f74
; naka_extension_device+0x1f74  --  naka_extension_device +0x1f74..+0x1f7a (ROM 0xed8740..0xed8746), 6 bytes
; Name strings of element 0 of ResName slot 0x3f6 (table 0xed8736, 1
; entries, InitializeToshi), names for Viewable slot 0xf6: "TEST3".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F74, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f7a
; naka_extension_device+0x1f7a  --  naka_extension_device +0x1f7a..+0x1f8c (ROM 0xed8746..0xed8758), 18 bytes
; The table itself: ResName slot 0x3f7 (table 0xed8746, 3 entries,
; InitializeToshi) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F7A, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f8c
; naka_extension_device+0x1f8c  --  naka_extension_device +0x1f8c..+0x1f96 (ROM 0xed8758..0xed8762), 10 bytes
; Name strings of elements 0-2 of ResName slot 0x3f7 (table 0xed8746, 3
; entries, InitializeToshi), names for Viewable slot 0xf7: "", "",
; "TEST4".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F8C, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x1f96
; naka_extension_device+0x1f96  --  naka_extension_device +0x1f96..+0x20a8 (ROM 0xed8762..0xed8874), 274 bytes
; The table itself: ResName slot 0x3f8 (table 0xed8762, 67 entries,
; InitializeToshi) -- 67 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x1F96, 0x112
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x20a8
; naka_extension_device+0x20a8  --  naka_extension_device +0x20a8..+0x2156 (ROM 0xed8874..0xed8922), 174 bytes
; Name strings of elements 0-66 of ResName slot 0x3f8 (table 0xed8762,
; 67 entries, InitializeToshi), names for Viewable slot 0xf8: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x20A8, 0xAE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x2156
; naka_extension_device+0x2156  --  naka_extension_device +0x2156..+0x2180 (ROM 0xed8922..0xed894c), 42 bytes
; The table itself: ResName slot 0x3f9 (table 0xed8922, 9 entries,
; InitializeToshi) -- 9 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x2156, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x2180
; naka_extension_device+0x2180  --  naka_extension_device +0x2180..+0x21a2 (ROM 0xed894c..0xed896e), 34 bytes
; Name strings of elements 0-8 of ResName slot 0x3f9 (table 0xed8922, 9
; entries, InitializeToshi), names for Viewable slot 0xf9: "",
; "TEST6NG", "", "TEST6OK", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x2180, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x21a2
; naka_extension_device+0x21a2  --  naka_extension_device +0x21a2..+0x21ac (ROM 0xed896e..0xed8978), 10 bytes
; The table itself: ResName slot 0x3fb (table 0xed896e, 1 entries,
; InitializeToshi) -- 1 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x21A2, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_extension_device+0x21ac
; naka_extension_device+0x21ac  --  naka_extension_device +0x21ac..+0x3552 (ROM 0xed8978..0xed9d1e), 5030 bytes
; Name strings of element 0 of ResName slot 0x3fb (table 0xed896e, 1
; entries, InitializeToshi), names for Viewable slot 0xfb: "EXT".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_extension_device.bin", 0x21AC, 0x13A6
; -----------------------------------------------------------------------------
; [nakarest_retype] SoundParam_EncoderMappingData
; SoundParam_EncoderMappingData  --  naka_extension_device +0x3552..+0x3860 (ROM 0xed9d1e..0xeda02c), 782 bytes
; No RegObjTabl-registered table points at the start of these 782 bytes
; (0xed9d1e..0xeda02c); purpose not established by that route.
; -----------------------------------------------------------------------------
SoundParam_EncoderMappingData:
	.incbin "includes/generated/naka_extension_device.bin", 0x3552, 0x30E
; -----------------------------------------------------------------------------
; [nakarest_retype] EffectMode_DispatchTable
; EffectMode_DispatchTable  --  naka_extension_device +0x3860..+0x38f0 (ROM 0xeda02c..0xeda0bc), 144 bytes
; No RegObjTabl-registered table points at the start of these 144 bytes
; (0xeda02c..0xeda0bc); purpose not established by that route.
; -----------------------------------------------------------------------------
EffectMode_DispatchTable:
	.incbin "includes/generated/naka_extension_device.bin", 0x3860, 0x90
; -----------------------------------------------------------------------------
; [nakarest_retype] ENCODER_HANDLER_TABLE
; ENCODER_HANDLER_TABLE  --  naka_extension_device +0x38f0..+0x3970 (ROM 0xeda0bc..0xeda13c), 128 bytes
; No RegObjTabl-registered table points at the start of these 128 bytes
; (0xeda0bc..0xeda13c); purpose not established by that route.
; -----------------------------------------------------------------------------
ENCODER_HANDLER_TABLE:
	.incbin "includes/generated/naka_extension_device.bin", 0x38F0, 0x80
; -----------------------------------------------------------------------------
; [nakarest_retype] ENCODER_LUT_MODWHEEL
; ENCODER_LUT_MODWHEEL  --  naka_extension_device +0x3970..+0x3994 (ROM 0xeda13c..0xeda160), 36 bytes
; No RegObjTabl-registered table points at the start of these 36 bytes
; (0xeda13c..0xeda160); purpose not established by that route.
; -----------------------------------------------------------------------------
ENCODER_LUT_MODWHEEL:
	.incbin "includes/generated/naka_extension_device.bin", 0x3970, 0x24
; External label offsets within the binary blob above.
