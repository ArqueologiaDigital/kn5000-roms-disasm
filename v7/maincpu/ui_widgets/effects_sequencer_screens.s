
; Effects & Sequencer screen widgets (555 widgets, 36540 bytes)
; Source: maincpu/ui_widgets/naka_effects_seq.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_effects_seq
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
; Viewable slot 0xa: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2e624,
; 0xa in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xa. Element 0 is named "" in ResName slot 0x30a. Links: all 12
; records consistent.
;
; Viewable slot 0xb: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2e658,
; 0xb in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xb. Element 0 is named "" in ResName slot 0x30b. Links: all 12
; records consistent.
;
; Viewable slot 0xc: RegObjTabl 0x1600010, ViewableProc, 0x25, 0xe2e68c,
; 0xc in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0xc. Element 0 is named "" in ResName slot 0x30c. Links: all 37
; records consistent.
;
; Viewable slot 0xe: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2e724,
; 0xe in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xe. Element 0 is named "" in ResName slot 0x30e. Links: all 12
; records consistent.
;
; Viewable slot 0x80: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2e758,
; 0x80 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x80. Element 0 is named "" in ResName slot 0x380. Links: all 12
; records consistent.
;
; Viewable slot 0x81: RegObjTabl 0x1600010, ViewableProc, 0x1c,
; 0xe2e78c, 0x81 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 28, table} at 0x27ed2 +
; 14*0x81. Element 0 is named "" in ResName slot 0x381. Links: all 28
; records consistent.
;
; Viewable slot 0x82: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe2e800,
; 0x82 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x82. Element 0 is named "" in ResName slot 0x382. Links: all 8
; records consistent.
;
; Viewable slot 0x83: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe2e824, 0x83 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x83. Element 0 is named "" in ResName slot 0x383. Links: all 16
; records consistent.
;
; Viewable slot 0x84: RegObjTabl 0x1600010, ViewableProc, 0xa, 0xe2e868,
; 0x84 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 10, table} at 0x27ed2 +
; 14*0x84. Element 0 is named "" in ResName slot 0x384. Links: all 10
; records consistent.
;
; Viewable slot 0x85: RegObjTabl 0x1600010, ViewableProc, 0x19,
; 0xe2e894, 0x85 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x85. Element 0 is named "" in ResName slot 0x385. Links: 4 of 25
; records have a disagreeing link (elements 18-21); elements 19-20 point
; outside the program ROM (RAM records).
;
; Viewable slot 0x86: RegObjTabl 0x1600010, ViewableProc, 0xb, 0xe2e8fc,
; 0x86 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0x86. Element 0 is named "" in ResName slot 0x386. Links: all 11
; records consistent.
;
; Viewable slot 0x87: RegObjTabl 0x1600010, ViewableProc, 0x18,
; 0xe2e92c, 0x87 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0x87. Element 0 is named "" in ResName slot 0x387. Links: all 24
; records consistent.
;
; Viewable slot 0x88: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe2e990,
; 0x88 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x88. Element 0 is named "" in ResName slot 0x388. Links: all 12
; records consistent.
;
; Viewable slot 0x8d: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe2e9c4,
; 0x8d in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x8d. Element 0 is named "" in ResName slot 0x38d. Links: all 4
; records consistent.
;
; Viewable slot 0x90: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xe2e9d8, 0x90 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x90. Element 0 is named "" in ResName slot 0x390. Links: all 17
; records consistent.
;
; Viewable slot 0x91: RegObjTabl 0x1600010, ViewableProc, 0x13,
; 0xe2ea20, 0x91 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x91. Element 0 is named "" in ResName slot 0x391. Links: all 19
; records consistent.
;
; Viewable slot 0x93: RegObjTabl 0x1600010, ViewableProc, 0x1a,
; 0xe2ea70, 0x93 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 26, table} at 0x27ed2 +
; 14*0x93. Element 0 is named "" in ResName slot 0x393. Links: all 26
; records consistent.
;
; Viewable slot 0x94: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe2eadc,
; 0x94 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x94. Element 0 is named "" in ResName slot 0x394. Links: all 4
; records consistent.
;
; Viewable slot 0x95: RegObjTabl 0x1600010, ViewableProc, 0x1b,
; 0xe2eaf0, 0x95 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 27, table} at 0x27ed2 +
; 14*0x95. Element 0 is named "" in ResName slot 0x395. Links: all 27
; records consistent.
;
; Viewable slot 0x96: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe2eb60,
; 0x96 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x96. Element 0 is named "" in ResName slot 0x396. Links: all 8
; records consistent.
;
; Viewable slot 0x97: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe2eb84,
; 0x97 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x97. Element 0 is named "" in ResName slot 0x397. Links: all 4
; records consistent.
;
; Viewable slot 0x98: RegObjTabl 0x1600010, ViewableProc, 0x1a,
; 0xe2eb98, 0x98 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 26, table} at 0x27ed2 +
; 14*0x98. Element 0 is named "" in ResName slot 0x398. Links: all 26
; records consistent.
;
; Viewable slot 0x99: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe2ec04,
; 0x99 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x99. Element 0 is named "" in ResName slot 0x399. Links: all 8
; records consistent.
;
; Viewable slot 0x9a: RegObjTabl 0x1600010, ViewableProc, 0xe, 0xe2ec28,
; 0x9a in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 14, table} at 0x27ed2 +
; 14*0x9a. Element 0 is named "" in ResName slot 0x39a. Links: all 14
; records consistent.
;
; Viewable slot 0x9b: RegObjTabl 0x1600010, ViewableProc, 0x16,
; 0xe2ec64, 0x9b in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 22, table} at 0x27ed2 +
; 14*0x9b. Element 0 is named "" in ResName slot 0x39b. Links: all 22
; records consistent.
;
; Viewable slot 0x9c: RegObjTabl 0x1600010, ViewableProc, 0x15,
; 0xe2ecc0, 0x9c in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 21, table} at 0x27ed2 +
; 14*0x9c. Element 0 is named "" in ResName slot 0x39c. Links: all 21
; records consistent.
;
; Viewable slot 0x9d: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe2ed18, 0x9d in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x9d. Element 0 is named "" in ResName slot 0x39d. Links: all 16
; records consistent.
;
; Viewable slot 0x9e: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe2ed5c, 0x9e in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x9e. Element 0 is named "" in ResName slot 0x39e. Links: all 16
; records consistent.
;
; Viewable slot 0x9f: RegObjTabl 0x1600010, ViewableProc, 0x19,
; 0xe2eda0, 0x9f in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x9f. Element 0 is named "" in ResName slot 0x39f. Links: all 25
; records consistent.
;
; Viewable slot 0xa0: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe2ee08, 0xa0 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0xa0. Element 0 is named "" in ResName slot 0x3a0. Links: all 16
; records consistent.
;
; Viewable slot 0xa1: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe2ee4c, 0xa1 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0xa1. Element 0 is named "" in ResName slot 0x3a1. Links: all 16
; records consistent.
;
; Viewable slot 0xa2: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xe2ee90, 0xa2 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0xa2. Element 0 is named "" in ResName slot 0x3a2. Links: all 17
; records consistent.
;
; Viewable slot 0xa3: RegObjTabl 0x1600010, ViewableProc, 0xf, 0xe2eed8,
; 0xa3 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0xa3. Element 0 is named "" in ResName slot 0x3a3. Links: all 15
; records consistent.
;
; Viewable slot 0xa4: RegObjTabl 0x1600010, ViewableProc, 0x11,
; 0xe2ef18, 0xa4 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0xa4. Element 0 is named "" in ResName slot 0x3a4. Links: all 17
; records consistent.
;
; Viewable slot 0xab: RegObjTabl 0x1600010, ViewableProc, 0x2, 0xe2ef68,
; 0xab in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0xab. Element 0 is named "" in ResName slot 0x3ab. Links: all 2
; records consistent.
;
; Viewable slot 0xd6: RegObjTabl 0x1600010, ViewableProc, 0xf, 0xe2ef74,
; 0xd6 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0xd6. Element 0 is named "EnterTainerScr" in ResName slot 0x3d6.
; Links: 6 of 15 records have a disagreeing link (elements 1, 3-7);
; elements 3-6 point outside the program ROM (RAM records).
;
; Viewable slot 0xe7: RegObjTabl 0x1600010, ViewableProc, 0x3d,
; 0xe2efb4, 0xe7 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 61, table} at 0x27ed2 +
; 14*0xe7. Element 0 is named "" in ResName slot 0x3e7. Links: all 61
; records consistent.
;
; MainFunction slot 0x148: RegObjTabl 0x1600003, MainFunctionProc, 0x2c,
; 0xe3051c, 0x148 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 44, table} at 0x27ed2 +
; 14*0x148.
;
; ResName slot 0x30a: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe2f0ac,
; 0x30a in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x30a.
;
; ResName slot 0x30b: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe2f0fa,
; 0x30b in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x30b.
;
; ResName slot 0x30c: RegObjTabl 0x160000f, ResNameProc, 0x25, 0xe2f148,
; 0x30c in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0x30c.
;
; ResName slot 0x30e: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe2f232,
; 0x30e in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x30e.
;
; ResName slot 0x380: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe2f280,
; 0x380 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x380.
;
; ResName slot 0x381: RegObjTabl 0x160000f, ResNameProc, 0x1c, 0xe2f2ce,
; 0x381 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 28, table} at 0x27ed2 +
; 14*0x381.
;
; ResName slot 0x382: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xe2f3aa,
; 0x382 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x382.
;
; ResName slot 0x383: RegObjTabl 0x160000f, ResNameProc, 0x10, 0xe2f3e0,
; 0x383 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x383.
;
; ResName slot 0x384: RegObjTabl 0x160000f, ResNameProc, 0xa, 0xe2f446,
; 0x384 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 10, table} at 0x27ed2 +
; 14*0x384.
;
; ResName slot 0x385: RegObjTabl 0x160000f, ResNameProc, 0x19, 0xe2f488,
; 0x385 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x385.
;
; ResName slot 0x386: RegObjTabl 0x160000f, ResNameProc, 0xb, 0xe2f560,
; 0x386 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0x386.
;
; ResName slot 0x387: RegObjTabl 0x160000f, ResNameProc, 0x18, 0xe2f5b2,
; 0x387 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0x387.
;
; ResName slot 0x388: RegObjTabl 0x160000f, ResNameProc, 0xc, 0xe2f66a,
; 0x388 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0x388.
;
; ResName slot 0x38d: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe2f6c2,
; 0x38d in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x38d.
;
; ResName slot 0x390: RegObjTabl 0x160000f, ResNameProc, 0x11, 0xe2f6e0,
; 0x390 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x390.
;
; ResName slot 0x391: RegObjTabl 0x160000f, ResNameProc, 0x13, 0xe2f758,
; 0x391 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 19, table} at 0x27ed2 +
; 14*0x391.
;
; ResName slot 0x393: RegObjTabl 0x160000f, ResNameProc, 0x1a, 0xe2f7dc,
; 0x393 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 26, table} at 0x27ed2 +
; 14*0x393.
;
; ResName slot 0x394: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe2f898,
; 0x394 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x394.
;
; ResName slot 0x395: RegObjTabl 0x160000f, ResNameProc, 0x1b, 0xe2f8b6,
; 0x395 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 27, table} at 0x27ed2 +
; 14*0x395.
;
; ResName slot 0x396: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xe2f966,
; 0x396 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x396.
;
; ResName slot 0x397: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe2f99c,
; 0x397 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x397.
;
; ResName slot 0x398: RegObjTabl 0x160000f, ResNameProc, 0x1a, 0xe2f9ba,
; 0x398 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 26, table} at 0x27ed2 +
; 14*0x398.
;
; ResName slot 0x399: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xe2fa64,
; 0x399 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x399.
;
; ResName slot 0x39a: RegObjTabl 0x160000f, ResNameProc, 0xe, 0xe2fa9a,
; 0x39a in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 14, table} at 0x27ed2 +
; 14*0x39a.
;
; ResName slot 0x39b: RegObjTabl 0x160000f, ResNameProc, 0x16, 0xe2fb02,
; 0x39b in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 22, table} at 0x27ed2 +
; 14*0x39b.
;
; ResName slot 0x39c: RegObjTabl 0x160000f, ResNameProc, 0x15, 0xe2fb9a,
; 0x39c in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 21, table} at 0x27ed2 +
; 14*0x39c.
;
; ResName slot 0x39d: RegObjTabl 0x160000f, ResNameProc, 0x10, 0xe2fc28,
; 0x39d in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x39d.
;
; ResName slot 0x39e: RegObjTabl 0x160000f, ResNameProc, 0x10, 0xe2fc9a,
; 0x39e in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x39e.
;
; ResName slot 0x39f: RegObjTabl 0x160000f, ResNameProc, 0x19, 0xe2fd0c,
; 0x39f in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 25, table} at 0x27ed2 +
; 14*0x39f.
;
; ResName slot 0x3a0: RegObjTabl 0x160000f, ResNameProc, 0x10, 0xe2fdb4,
; 0x3a0 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x3a0.
;
; ResName slot 0x3a1: RegObjTabl 0x160000f, ResNameProc, 0x10, 0xe2fe24,
; 0x3a1 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0x3a1.
;
; ResName slot 0x3a2: RegObjTabl 0x160000f, ResNameProc, 0x11, 0xe2fe96,
; 0x3a2 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x3a2.
;
; ResName slot 0x3a3: RegObjTabl 0x160000f, ResNameProc, 0xf, 0xe2ff0c,
; 0x3a3 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0x3a3.
;
; ResName slot 0x3a4: RegObjTabl 0x160000f, ResNameProc, 0x11, 0xe2ff78,
; 0x3a4 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 17, table} at 0x27ed2 +
; 14*0x3a4.
;
; ResName slot 0x3a8: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xe2fff0,
; 0x3a8 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x3a8.
;
; ResName slot 0x3aa: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xe2fff6,
; 0x3aa in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x3aa.
;
; ResName slot 0x3ab: RegObjTabl 0x160000f, ResNameProc, 0x2, 0xe2fffc,
; 0x3ab in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0x3ab.
;
; ResName slot 0x3d6: RegObjTabl 0x160000f, ResNameProc, 0xf, 0xe3000e,
; 0x3d6 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0x3d6.
;
; ResName slot 0x3e7: RegObjTabl 0x160000f, ResNameProc, 0x3d, 0xe3009e,
; 0x3e7 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 61, table} at 0x27ed2 +
; 14*0x3e7.
;
; MainFunction slot 0x448: RegObjTabl 0x1600003, MainFunctionProc, 0x2c,
; 0xe305d0, 0x448 in InitializeKubo (sequencer/sequencer_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 44, table} at 0x27ed2 +
; 14*0x448.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_ReverbScreen_EmptyStr
; Naka_ReverbScreen_EmptyStr  --  naka_effects_seq +0x0..+0x2 (ROM 0xe27fa4..0xe27fa6), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xe27fa4..0xe27fa6); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_ReverbScreen_EmptyStr:
	.incbin "includes/generated/naka_effects_seq.bin", 0x0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x2
; naka_effects_seq+0x2  --  naka_effects_seq +0x2..+0x1bc (ROM 0xe27fa6..0xe28160), 442 bytes
; Widget records of elements 0-11 of Viewable slot 0xa (table 0xe2e624,
; 12 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022) x3, Label (32 B, id 0x0160002b)
; x4, EffectBox (38 B, id 0x01680000), Box (26 B, id 0x01600031),
; IvIntEasySet (24 B, id 0x01600063), IvSdrev (22 B, id 0x01680013).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x2, 0x1BA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x1bc
; naka_effects_seq+0x1bc  --  naka_effects_seq +0x1bc..+0x37c (ROM 0xe28160..0xe28320), 448 bytes
; Widget records of elements 0-11 of Viewable slot 0xb (table 0xe2e658,
; 12 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b) x4, AcIndexWideES (42 B, id 0x01600022)
; x3, EffectBox (38 B, id 0x01680000), Box (26 B, id 0x01600031),
; IvIntEasySet (24 B, id 0x01600063), IvSddsp (22 B, id 0x01680014).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x1BC, 0x1C0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x37c
; naka_effects_seq+0x37c  --  naka_effects_seq +0x37c..+0x8e4 (ROM 0xe28320..0xe28888), 1384 bytes
; Widget records of elements 0-36 of Viewable slot 0xc (table 0xe2e68c,
; 37 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexEditSw (40 B, id 0x0160001f) x8, Label (32 B, id 0x0160002b)
; x19, Line (26 B, id 0x0160002e) x6, EqualizerBox (34 B, id
; 0x01680001), Box (26 B, id 0x01600031), EqOnOffFuncToggle (44 B, id
; 0x0168000d).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x37C, 0x568
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x8e4
; naka_effects_seq+0x8e4  --  naka_effects_seq +0x8e4..+0xa98 (ROM 0xe28888..0xe28a3c), 436 bytes
; Widget records of elements 0-11 of Viewable slot 0xe (table 0xe2e724,
; 12 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022) x2, Label (32 B, id 0x0160002b)
; x4, AccIll (32 B, id 0x01680008), Box (26 B, id 0x01600031) x2,
; IvSdacc (22 B, id 0x01680015), IvIntEasySet (24 B, id 0x01600063).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E4, 0x1B4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0xa98
; naka_effects_seq+0xa98  --  naka_effects_seq +0xa98..+0xcb0 (ROM 0xe28a3c..0xe28c54), 536 bytes
; Widget records of elements 0-11 of Viewable slot 0x80 (table 0xe2e758,
; 12 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcTitleMenu (54 B, id 0x0160001d) x2, Label (32 B, id 0x0160002b),
; AcModeMenu (54 B, id 0x01600040), IvExitMode (26 B, id 0x01600048),
; AcIndexEditSw (40 B, id 0x0160001f) x2, Box (26 B, id 0x01600031),
; SngSel (36 B, id 0x0168000a), AcLanguageText (42 B, id 0x01600066) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0xA98, 0x218
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0xcb0
; naka_effects_seq+0xcb0  --  naka_effects_seq +0xcb0..+0x10dc (ROM 0xe28c54..0xe29080), 1068 bytes
; Widget records of elements 0-27 of Viewable slot 0x81 (table 0xe2e78c,
; 28 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b) x6, IvTrackSwitch (22 B, id 0x0160005b),
; AcFuncToggle (44 B, id 0x01600044), Box (26 B, id 0x01600031) x2,
; SqplyVal (32 B, id 0x01680006), TrTransposeBox (36 B, id 0x01600067),
; TrChordBox (36 B, id 0x01600068), AcTempoBox (36 B, id 0x01600014),
; AcIndexEditSw (40 B, id 0x0160001f) x4, AcFuncEditSw (44 B, id
; 0x01600020) x2, IvPlayExit (26 B, id 0x01680010), SngSel (36 B, id
; 0x0168000a), Window (36 B, id 0x01600035) x2, AcTitleMenu (54 B, id
; 0x0160001d), IvShowHide (26 B, id 0x01600064), SngSel2 (22 B, id
; 0x0168000b).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0xCB0, 0x42C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x10dc
; naka_effects_seq+0x10dc  --  naka_effects_seq +0x10dc..+0x127e (ROM 0xe29080..0xe29222), 418 bytes
; Widget records of elements 0-7 of Viewable slot 0x82 (table 0xe2e800,
; 8 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; SqplyVal (32 B, id 0x01680006), PsEditBox (50 B, id 0x01600015) x3,
; Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x10DC, 0x1A2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x127e
; naka_effects_seq+0x127e  --  naka_effects_seq +0x127e..+0x14f4 (ROM 0xe29222..0xe29498), 630 bytes
; Widget records of elements 0-15 of Viewable slot 0x83 (table 0xe2e824,
; 16 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), IvExitMode (26 B, id 0x01600048),
; AcTitleMenu (54 B, id 0x0160001d), Box (26 B, id 0x01600031),
; AcIndexEditSw (40 B, id 0x0160001f) x2, SngSel (36 B, id 0x0168000a),
; AcFuncEditSw (44 B, id 0x01600020), PsTrackSwitch (36 B, id
; 0x01600058) x5, AcLanguageText (42 B, id 0x01600066) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x127E, 0x276
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x14f4
; naka_effects_seq+0x14f4  --  naka_effects_seq +0x14f4..+0x1790 (ROM 0xe29498..0xe29734), 668 bytes
; Widget records of elements 0-9 of Viewable slot 0x84 (table 0xe2e868,
; 10 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcTitleMenu (54 B, id 0x0160001d) x7, AcModeMenu (54 B, id 0x01600040)
; x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x14F4, 0x29C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x1790
; naka_effects_seq+0x1790  --  naka_effects_seq +0x1790..+0x1b1e (ROM 0xe29734..0xe29ac2), 910 bytes
; Widget records of elements 0-18, 21-24 of Viewable slot 0x85 (table
; 0xe2e894, 25 entries, InitializeKubo); classes: TtlScreen (42 B, id
; 0x01600034), IvTrackSwitch (22 B, id 0x0160005b), AcFuncEditSw (44 B,
; id 0x01600020) x3, Label (32 B, id 0x0160002b) x7, AcFuncToggle (44 B,
; id 0x01600044) x2, Box (26 B, id 0x01600031) x2, SqplyVal (32 B, id
; 0x01680006), AcTempoBox (36 B, id 0x01600014), TrTransposeBox (36 B,
; id 0x01600067), TrChordBox (36 B, id 0x01600068), SngSel (36 B, id
; 0x0168000a), IvRealRecExit (22 B, id 0x01680019), Window (36 B, id
; 0x01600035).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x1790, 0x38E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x1b1e
; naka_effects_seq+0x1b1e  --  naka_effects_seq +0x1b1e..+0x1d50 (ROM 0xe29ac2..0xe29cf4), 562 bytes
; Widget records of elements 0-10 of Viewable slot 0x86 (table 0xe2e8fc,
; 11 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; SqplyVal (32 B, id 0x01680006), PsEditBox (50 B, id 0x01600015) x3,
; Label (32 B, id 0x0160002b) x3, AcIndexWideES (42 B, id 0x01600022),
; AcFuncToggle (44 B, id 0x01600044), AcFuncEditSw (44 B, id
; 0x01600020).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x1B1E, 0x232
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x1d50
; naka_effects_seq+0x1d50  --  naka_effects_seq +0x1d50..+0x20f8 (ROM 0xe29cf4..0xe2a09c), 936 bytes
; Widget records of elements 0-23 of Viewable slot 0x87 (table 0xe2e92c,
; 24 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; IvTrackSwitch (22 B, id 0x0160005b), Box (26 B, id 0x01600031) x2,
; SqplyVal (32 B, id 0x01680006), Label (32 B, id 0x0160002b) x8,
; AcTempoBox (36 B, id 0x01600014), TrTransposeBox (36 B, id
; 0x01600067), TrChordBox (36 B, id 0x01600068), SngSel (36 B, id
; 0x0168000a), AcFuncToggle (44 B, id 0x01600044) x2, AcIndexEditSw (40
; B, id 0x0160001f) x2, AcFuncEditSw (44 B, id 0x01600020) x2,
; IvPunchExit (22 B, id 0x01680016).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x1D50, 0x3A8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x20f8
; naka_effects_seq+0x20f8  --  naka_effects_seq +0x20f8..+0x235e (ROM 0xe2a09c..0xe2a302), 614 bytes
; Widget records of elements 0-11 of Viewable slot 0x88 (table 0xe2e990,
; 12 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034)
; x2, AcIndexWideES (42 B, id 0x01600022), Label (32 B, id 0x0160002b)
; x2, AcFuncToggle (44 B, id 0x01600044), SqplyVal (32 B, id
; 0x01680006), PsEditBox (50 B, id 0x01600015) x3, AcLanguageText (42 B,
; id 0x01600066), IvAutoPunchExit (22 B, id 0x01680017).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x20F8, 0x266
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x235e
; naka_effects_seq+0x235e  --  naka_effects_seq +0x235e..+0x2400 (ROM 0xe2a302..0xe2a3a4), 162 bytes
; Widget records of elements 0-3 of Viewable slot 0x8d (table 0xe2e9c4,
; 4 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcFuncEditSw (44 B, id 0x01600020), AcLanguageText (42 B, id
; 0x01600066), IvPnlWrExit (22 B, id 0x01680012).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x235E, 0xA2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x2400
; naka_effects_seq+0x2400  --  naka_effects_seq +0x2400..+0x2686 (ROM 0xe2a3a4..0xe2a62a), 646 bytes
; Widget records of elements 0-16 of Viewable slot 0x90 (table 0xe2e9d8,
; 17 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022), Label (32 B, id 0x0160002b) x3,
; SqedtVal3 (30 B, id 0x01680007), Box (26 B, id 0x01600031) x2,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), AcLanguageText (42 B, id
; 0x01600066) x3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x2400, 0x286
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x2686
; naka_effects_seq+0x2686  --  naka_effects_seq +0x2686..+0x292c (ROM 0xe2a62a..0xe2a8d0), 678 bytes
; Widget records of elements 0-18 of Viewable slot 0x91 (table 0xe2ea20,
; 19 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; SqedtVal2 (30 B, id 0x01680003), SqedtFix (28 B, id 0x01680004),
; AcIndexWideES (42 B, id 0x01600022) x4, IvSongCopyExit (22 B, id
; 0x01680005) x2, MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id
; 0x01600020) x2, Window (36 B, id 0x01600035), Box (26 B, id
; 0x01600031) x3, AcScreenMenu (54 B, id 0x01600041), IvExitScreen (26
; B, id 0x01600049), AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x2686, 0x2A6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x292c
; naka_effects_seq+0x292c  --  naka_effects_seq +0x292c..+0x2e34 (ROM 0xe2a8d0..0xe2add8), 1288 bytes
; Widget records of elements 0-25 of Viewable slot 0x93 (table 0xe2ea70,
; 26 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; IvPageControl (28 B, id 0x01600028) x2, AcWindowPage (36 B, id
; 0x01600025), IvExitMode (26 B, id 0x01600048), IvShowHide (26 B, id
; 0x01600064), Window (36 B, id 0x01600035) x2, AcTitleMenu (54 B, id
; 0x0160001d) x14, Line (26 B, id 0x0160002e) x3, Label (32 B, id
; 0x0160002b).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x292C, 0x508
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x2e34
; naka_effects_seq+0x2e34  --  naka_effects_seq +0x2e34..+0x2ed8 (ROM 0xe2add8..0xe2ae7c), 164 bytes
; Widget records of elements 0-3 of Viewable slot 0x94 (table 0xe2eadc,
; 4 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), IvTrackSwitch (22 B, id 0x0160005b),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x2E34, 0xA4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x2ed8
; naka_effects_seq+0x2ed8  --  naka_effects_seq +0x2ed8..+0x32ce (ROM 0xe2ae7c..0xe2b272), 1014 bytes
; Widget records of elements 0-26 of Viewable slot 0x95 (table 0xe2eaf0,
; 27 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexEditSw (40 B, id 0x0160001f) x12, Label (32 B, id 0x0160002b)
; x10, NoteEditBox (32 B, id 0x0168000c), Box (26 B, id 0x01600031),
; VwUserBitmap (26 B, id 0x01600069) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x2ED8, 0x3F6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x32ce
; naka_effects_seq+0x32ce  --  naka_effects_seq +0x32ce..+0x3470 (ROM 0xe2b272..0xe2b414), 418 bytes
; Widget records of elements 0-7 of Viewable slot 0x96 (table 0xe2eb60,
; 8 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id 0x01600022),
; SqplyVal (32 B, id 0x01680006), PsEditBox (50 B, id 0x01600015) x3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x32CE, 0x1A2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x3470
; naka_effects_seq+0x3470  --  naka_effects_seq +0x3470..+0x3514 (ROM 0xe2b414..0xe2b4b8), 164 bytes
; Widget records of elements 0-3 of Viewable slot 0x97 (table 0xe2eb84,
; 4 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), IvTrackSwitch (22 B, id 0x0160005b),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x3470, 0xA4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x3514
; naka_effects_seq+0x3514  --  naka_effects_seq +0x3514..+0x38e2 (ROM 0xe2b4b8..0xe2b886), 974 bytes
; Widget records of elements 0-25 of Viewable slot 0x98 (table 0xe2eb98,
; 26 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexEditSw (40 B, id 0x0160001f) x11, Label (32 B, id 0x0160002b)
; x10, Box (26 B, id 0x01600031), NoteEditBox (32 B, id 0x0168000c),
; VwUserBitmap (26 B, id 0x01600069) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x3514, 0x3CE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x38e2
; naka_effects_seq+0x38e2  --  naka_effects_seq +0x38e2..+0x3a84 (ROM 0xe2b886..0xe2ba28), 418 bytes
; Widget records of elements 0-7 of Viewable slot 0x99 (table 0xe2ec04,
; 8 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b) x2, AcIndexWideES (42 B, id 0x01600022),
; SqplyVal (32 B, id 0x01680006), PsEditBox (50 B, id 0x01600015) x3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x38E2, 0x1A2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x3a84
; naka_effects_seq+0x3a84  --  naka_effects_seq +0x3a84..+0x3ca4 (ROM 0xe2ba28..0xe2bc48), 544 bytes
; Widget records of elements 0-13 of Viewable slot 0x9a (table 0xe2ec28,
; 14 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; IvTrackSwitch (22 B, id 0x0160005b), MsgToTtl (22 B, id 0x0168000e),
; AcLanguageText (42 B, id 0x01600066) x5, AcFuncEditSw (44 B, id
; 0x01600020) x2, Window (36 B, id 0x01600035), AcScreenMenu (54 B, id
; 0x01600041), VwBox (28 B, id 0x01600011), IvExitScreen (26 B, id
; 0x01600049).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x3A84, 0x220
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x3ca4
; naka_effects_seq+0x3ca4  --  naka_effects_seq +0x3ca4..+0x3fd8 (ROM 0xe2bc48..0xe2bf7c), 820 bytes
; Widget records of elements 0-21 of Viewable slot 0x9b (table 0xe2ec64,
; 22 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Line (26 B, id 0x0160002e) x6, AcIndexWideES (42 B, id 0x01600022),
; Label (32 B, id 0x0160002b), SqedtVal (32 B, id 0x01680002), PsEditBox
; (50 B, id 0x01600015) x3, MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw
; (44 B, id 0x01600020) x2, Window (36 B, id 0x01600035), AcScreenMenu
; (54 B, id 0x01600041), IvExitScreen (26 B, id 0x01600049), Box (26 B,
; id 0x01600031) x2, AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x3CA4, 0x334
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x3fd8
; naka_effects_seq+0x3fd8  --  naka_effects_seq +0x3fd8..+0x4384 (ROM 0xe2bf7c..0xe2c328), 940 bytes
; Widget records of elements 0-20 of Viewable slot 0x9c (table 0xe2ecc0,
; 21 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b) x3, AcIndexWideES (42 B, id 0x01600022),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x6,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031) x2,
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x3FD8, 0x3AC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x4384
; naka_effects_seq+0x4384  --  naka_effects_seq +0x4384..+0x4658 (ROM 0xe2c328..0xe2c5fc), 724 bytes
; Widget records of elements 0-15 of Viewable slot 0x9d (table 0xe2ed18,
; 16 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), AcIndexWideES (42 B, id 0x01600022),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x4,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x4384, 0x2D4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x4658
; naka_effects_seq+0x4658  --  naka_effects_seq +0x4658..+0x4932 (ROM 0xe2c5fc..0xe2c8d6), 730 bytes
; Widget records of elements 0-15 of Viewable slot 0x9e (table 0xe2ed5c,
; 16 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), AcIndexWideES (42 B, id 0x01600022),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x4,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x4658, 0x2DA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x4932
; naka_effects_seq+0x4932  --  naka_effects_seq +0x4932..+0x4d22 (ROM 0xe2c8d6..0xe2ccc6), 1008 bytes
; Widget records of elements 0-24 of Viewable slot 0x9f (table 0xe2eda0,
; 25 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x5,
; Label (32 B, id 0x0160002b) x3, AcIndexWideES (42 B, id 0x01600022),
; Line (26 B, id 0x0160002e) x5, MsgToTtl (22 B, id 0x0168000e),
; AcFuncEditSw (44 B, id 0x01600020) x2, Window (36 B, id 0x01600035),
; AcScreenMenu (54 B, id 0x01600041), IvExitScreen (26 B, id
; 0x01600049), Box (26 B, id 0x01600031) x2, AcLanguageText (42 B, id
; 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x4932, 0x3F0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x4d22
; naka_effects_seq+0x4d22  --  naka_effects_seq +0x4d22..+0x4ffc (ROM 0xe2ccc6..0xe2cfa0), 730 bytes
; Widget records of elements 0-15 of Viewable slot 0xa0 (table 0xe2ee08,
; 16 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022), Label (32 B, id 0x0160002b),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x4,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x4D22, 0x2DA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x4ffc
; naka_effects_seq+0x4ffc  --  naka_effects_seq +0x4ffc..+0x52d6 (ROM 0xe2cfa0..0xe2d27a), 730 bytes
; Widget records of elements 0-15 of Viewable slot 0xa1 (table 0xe2ee4c,
; 16 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022), Label (32 B, id 0x0160002b),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x4,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x4FFC, 0x2DA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x52d6
; naka_effects_seq+0x52d6  --  naka_effects_seq +0x52d6..+0x554e (ROM 0xe2d27a..0xe2d4f2), 632 bytes
; Widget records of elements 0-16 of Viewable slot 0xa2 (table 0xe2ee90,
; 17 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022) x4, SqedtVal2 (30 B, id
; 0x01680003), SqedtFix (28 B, id 0x01680004), MsgToTtl (22 B, id
; 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2, Window (36 B, id
; 0x01600035), Box (26 B, id 0x01600031) x3, IvExitScreen (26 B, id
; 0x01600049), AcLanguageText (42 B, id 0x01600066), AcScreenMenu (54 B,
; id 0x01600041).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x52D6, 0x278
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x554e
; naka_effects_seq+0x554e  --  naka_effects_seq +0x554e..+0x57e6 (ROM 0xe2d4f2..0xe2d78a), 664 bytes
; Widget records of elements 0-14 of Viewable slot 0xa3 (table 0xe2eed8,
; 15 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; Label (32 B, id 0x0160002b), AcIndexWideES (42 B, id 0x01600022),
; SqedtVal (32 B, id 0x01680002), PsEditBox (50 B, id 0x01600015) x3,
; MsgToTtl (22 B, id 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2,
; Window (36 B, id 0x01600035), AcScreenMenu (54 B, id 0x01600041),
; IvExitScreen (26 B, id 0x01600049), Box (26 B, id 0x01600031),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x554E, 0x298
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x57e6
; naka_effects_seq+0x57e6  --  naka_effects_seq +0x57e6..+0x5a60 (ROM 0xe2d78a..0xe2da04), 634 bytes
; Widget records of elements 0-16 of Viewable slot 0xa4 (table 0xe2ef18,
; 17 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcIndexWideES (42 B, id 0x01600022) x4, SqedtVal2 (30 B, id
; 0x01680003), SqedtFix (28 B, id 0x01680004), MsgToTtl (22 B, id
; 0x0168000e), AcFuncEditSw (44 B, id 0x01600020) x2, Window (36 B, id
; 0x01600035), Box (26 B, id 0x01600031) x3, IvExitScreen (26 B, id
; 0x01600049), AcLanguageText (42 B, id 0x01600066), AcScreenMenu (54 B,
; id 0x01600041).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x57E6, 0x27A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x5a60
; naka_effects_seq+0x5a60  --  naka_effects_seq +0x5a60..+0x5abc (ROM 0xe2da04..0xe2da60), 92 bytes
; Widget records of elements 0-1 of Viewable slot 0xab (table 0xe2ef68,
; 2 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; AcMixerVol (32 B, id 0x0160003c).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x5A60, 0x5C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x5abc
; naka_effects_seq+0x5abc  --  naka_effects_seq +0x5abc..+0x5bf2 (ROM 0xe2da60..0xe2db96), 310 bytes
; Widget records of elements 0-2 of Viewable slot 0xd6 (table 0xe2ef74,
; 15 entries, InitializeKubo), element 0 "EnterTainerScr"; classes:
; TtlScreen (42 B, id 0x01600034), AcEntertainerGridBox (74 B, id
; 0x01680009), Label (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x5ABC, 0x136
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_FADE_IN_OUT_SETTING
; NakaInst_FADE_IN_OUT_SETTING  --  naka_effects_seq +0x5bf2..+0x5d6c (ROM 0xe2db96..0xe2dd10), 378 bytes
; No RegObjTabl-registered table points at the start of these 36 bytes
; (0xe2db96..0xe2dbba); purpose not established by that route. Widget
; records of elements 7-14 of Viewable slot 0xd6 (table 0xe2ef74, 15
; entries, InitializeKubo), element 0 "EnterTainerScr"; classes:
; AcIndexWideES (42 B, id 0x01600022) x2, Label (32 B, id 0x0160002b)
; x3, IvExitMode (26 B, id 0x01600048), AcFuncToggle (44 B, id
; 0x01600044), AcPanicEditSw (46 B, id 0x01680018).
; -----------------------------------------------------------------------------
NakaInst_FADE_IN_OUT_SETTING:
	.incbin "includes/generated/naka_effects_seq.bin", 0x5BF2, 0x17A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x5d6c
; naka_effects_seq+0x5d6c  --  naka_effects_seq +0x5d6c..+0x6680 (ROM 0xe2dd10..0xe2e624), 2324 bytes
; Widget records of elements 0-60 of Viewable slot 0xe7 (table 0xe2efb4,
; 61 entries, InitializeKubo); classes: TtlScreen (42 B, id 0x01600034),
; IvExitMode (26 B, id 0x01600048), AcLanguageText (42 B, id 0x01600066)
; x11, IvShowHide (26 B, id 0x01600064) x5, AcFuncEditSw (44 B, id
; 0x01600020), Window (36 B, id 0x01600035) x11, AcIndexWideToggle (50
; B, id 0x0168000f) x7, Screen (34 B, id 0x01600033) x4, IvExitScreen
; (26 B, id 0x01600049) x4, HelpTtl (36 B, id 0x01680011) x4,
; IvPageControl (28 B, id 0x01600028) x9, AcWindowPage (36 B, id
; 0x01600025) x3.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x5D6C, 0x914
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x6680
; naka_effects_seq+0x6680  --  naka_effects_seq +0x6680..+0x66b4 (ROM 0xe2e624..0xe2e658), 52 bytes
; The table itself: Viewable slot 0xa (table 0xe2e624, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x6680, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x66b4
; naka_effects_seq+0x66b4  --  naka_effects_seq +0x66b4..+0x66e8 (ROM 0xe2e658..0xe2e68c), 52 bytes
; The table itself: Viewable slot 0xb (table 0xe2e658, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x66B4, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x66e8
; naka_effects_seq+0x66e8  --  naka_effects_seq +0x66e8..+0x6700 (ROM 0xe2e68c..0xe2e6a4), 24 bytes
; The table itself: Viewable slot 0xc (table 0xe2e68c, 37 entries,
; InitializeKubo) -- 37 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x66E8, 0x18
EmbeddedPtrTable_v7_naka_effects_seq_006700:
	.long 0x00E2841C
	.long 0x00E28444
	.long 0x00E2846C
	.long 0x00E28494
	.long 0x00E284BA
	.long 0x00E284E0
	.long 0x00E28506
	.long 0x00E2852C
	.long 0x00E28552
	.long 0x00E28578
	.long 0x00E2859E
	.long 0x00E285C4
	.long 0x00E285E8
	.long 0x00E28610
	.long 0x00E2863A
	.long 0x00E28660
	.long 0x00E2867A
	.long 0x00E28694
	.long 0x00E286AE
	.long 0x00E286C8
	.long 0x00E286EA
	.long 0x00E28704
	.long 0x00E2872E
	.long 0x00E28758
	.long 0x00E2877C
	.long 0x00E287A4
	.long 0x00E287CE
	.long 0x00E287F4
	.long 0x00E2880E
	.long 0x00E28828
	.long 0x00E2884E
	.long 0x00000000
	.long 0x00E28888
	.long 0x00E288C4
	.long 0x00E288EE
	.long 0x00E28918
	.long 0x00E2893E
	.long 0x00E28964
	.long 0x00E28984
	.long 0x00E2899E
	.long 0x00E289B8
	.long 0x00E289E8
	.long 0x00E28A0E
	.long 0x00E28A24
	.long 0x00000000
	.long 0x00E28A3C
	.long 0x00E28A76
	.long 0x00E28AB4
	.long 0x00E28ADA
	.long 0x00E28B16
	.long 0x00E28B30
	.long 0x00E28B58
	.long 0x00E28B80
	.long 0x00E28B9A
	.long 0x00E28BBE
	.long 0x00E28BE8
	.long 0x00E28C12
	.long 0x00000000
	.long 0x00E28C54
	.long 0x00E28C8E
	.long 0x00E28CB4
	.long 0x00E28CCA
	.long 0x00E28D0A
	.long 0x00E28D24
	.long 0x00E28D44
	.long 0x00E28D5E
	.long 0x00E28D82
	.long 0x00E28DA6
	.long 0x00E28DD2
	.long 0x00E28DFE
	.long 0x00E28E22
	.long 0x00E28E4A
	.long 0x00E28E72
	.long 0x00E28E9E
	.long 0x00E28EC4
	.long 0x00E28EDE
	.long 0x00E28F02
	.long 0x00E28F26
	.long 0x00E28F64
	.long 0x00E28F90
	.long 0x00E28FB6
	.long 0x00E28FDA
	.long 0x00E29002
	.long 0x00E2902A
	.long 0x00E29050
	.long 0x00E2906A
	.long 0x00000000
	.long 0x00E29080
	.long 0x00E290B6
	.long 0x00E290D6
	.long 0x00E2911E
	.long 0x00E29150
	.long 0x00E2918A
	.long 0x00E291D2
	.long 0x00E291FC
	.long 0x00000000
	.long 0x00E29222
	.long 0x00E29258
	.long 0x00E2927E
	.long 0x00E29298
	.long 0x00E292D6
	.long 0x00E292F0
	.long 0x00E29318
	.long 0x00E29340
	.long 0x00E29364
	.long 0x00E29390
	.long 0x00E293B4
	.long 0x00E293D8
	.long 0x00E293FC
	.long 0x00E29420
	.long 0x00E29444
	.long 0x00E2946E
	.long 0x00000000
	.long 0x00E29498
	.long 0x00E294CA
	.long 0x00E2950E
	.long 0x00E29550
	.long 0x00E2959A
	.long 0x00E295DC
	.long 0x00E29622
	.long 0x00E29668
	.long 0x00E296AE
	.long 0x00E296F0
	.long 0x00000000
	.long 0x00E29734
	.long 0x00E2976E
	.long 0x00E29784
	.long 0x00E297B0
	.long 0x00E297DA
	.long 0x00E2981A
	.long 0x00E29834
	.long 0x00E2986E
	.long 0x00E2988E
	.long 0x00E298A8
	.long 0x00E298D4
	.long 0x00E29900
	.long 0x00E2992C
	.long 0x00E29950
	.long 0x00E29974
	.long 0x00E29998
	.long 0x00E299BA
	.long 0x00E299DE
	.long 0x00E29A0A
	.long 0x0003E1B8
	.long 0x0003E1E4
	.long 0x00E29A36
	.long 0x00E29A4C
	.long 0x00E29A70
	.long 0x00E29A9C
	.long 0x00000000
	.long 0x00E29AC2
	.long 0x00E29AFC
	.long 0x00E29B1C
	.long 0x00E29B64
	.long 0x00E29B96
	.long 0x00E29BDE
	.long 0x00E29C08
	.long 0x00E29C2E
	.long 0x00E29C68
	.long 0x00E29C94
	.long 0x00E29CBA
	.long 0x00000000
	.long 0x00E29CF4
	.long 0x00E29D2C
	.long 0x00E29D42
	.long 0x00E29D5C
	.long 0x00E29D7C
	.long 0x00E29D96
	.long 0x00E29DC2
	.long 0x00E29DEE
	.long 0x00E29E1A
	.long 0x00E29E3E
	.long 0x00E29E62
	.long 0x00E29E86
	.long 0x00E29EA8
	.long 0x00E29ECC
	.long 0x00E29F06
	.long 0x00E29F46
	.long 0x00E29F6C
	.long 0x00E29F94
	.long 0x00E29FBC
	.long 0x00E29FE8
	.long 0x00E2A00E
	.long 0x00E2A024
	.long 0x00E2A050
	.long 0x00E2A076
	.long 0x00000000
	.long 0x00E2A09C
	.long 0x00E2A0D8
	.long 0x00E2A102
	.long 0x00E2A128
	.long 0x00E2A15A
	.long 0x00E2A194
	.long 0x00E2A1B4
	.long 0x00E2A1FA
	.long 0x00E2A240
	.long 0x00E2A286
	.long 0x00E2A2B0
	.long 0x00E2A2C6
	.long 0x00000000
	.long 0x00E2A302
	.long 0x00E2A338
	.long 0x00E2A364
	.long 0x00E2A38E
	.long 0x00000000
	.long 0x00E2A3A4
	.long 0x00E2A3DA
	.long 0x00E2A404
	.long 0x00E2A430
	.long 0x00E2A44E
	.long 0x00E2A468
	.long 0x00E2A48A
	.long 0x00E2A4AC
	.long 0x00E2A4C2
	.long 0x00E2A4EE
	.long 0x00E2A512
	.long 0x00E2A52C
	.long 0x00E2A566
	.long 0x00E2A592
	.long 0x00E2A5AC
	.long 0x00E2A5D6
	.long 0x00E2A600
	.long 0x00000000
	.long 0x00E2A62A
	.long 0x00E2A664
	.long 0x00E2A682
	.long 0x00E2A69E
	.long 0x00E2A6C8
	.long 0x00E2A6F2
	.long 0x00E2A71C
	.long 0x00E2A746
	.long 0x00E2A75C
	.long 0x00E2A772
	.long 0x00E2A788
	.long 0x00E2A7B4
	.long 0x00E2A7D8
	.long 0x00E2A7F2
	.long 0x00E2A80C
	.long 0x00E2A826
	.long 0x00E2A860
	.long 0x00E2A87A
	.long 0x00E2A8A6
	.long 0x00000000
	.long 0x00E2A8D0
	.long 0x00E2A900
	.long 0x00E2A91C
	.long 0x00E2A940
	.long 0x00E2A95C
	.long 0x00E2A976
	.long 0x00E2A990
	.long 0x00E2A9B4
	.long 0x00E2A9F4
	.long 0x00E2AA34
	.long 0x00E2AA7A
	.long 0x00E2AABC
	.long 0x00E2AAFE
	.long 0x00E2AB3E
	.long 0x00E2AB7E
	.long 0x00E2ABC4
	.long 0x00E2AC06
	.long 0x00E2AC4A
	.long 0x00E2AC6E
	.long 0x00E2ACAA
	.long 0x00E2ACC4
	.long 0x00E2AD00
	.long 0x00E2AD3E
	.long 0x00E2AD7C
	.long 0x00E2ADA4
	.long 0x00E2ADBE
	.long 0x00000000
	.long 0x00E2ADD8
	.long 0x00E2AE0E
	.long 0x00E2AE3C
	.long 0x00E2AE52
	.long 0x00000000
	.long 0x00E2AE7C
	.long 0x00E2AEB0
	.long 0x00E2AED8
	.long 0x00E2AF00
	.long 0x00E2AF28
	.long 0x00E2AF50
	.long 0x00E2AF78
	.long 0x00E2AFA0
	.long 0x00E2AFC6
	.long 0x00E2AFEA
	.long 0x00E2B010
	.long 0x00E2B034
	.long 0x00E2B058
	.long 0x00E2B07C
	.long 0x00E2B0A4
	.long 0x00E2B0CC
	.long 0x00E2B0F4
	.long 0x00E2B11A
	.long 0x00E2B13A
	.long 0x00E2B154
	.long 0x00E2B16E
	.long 0x00E2B188
	.long 0x00E2B1B0
	.long 0x00E2B1D4
	.long 0x00E2B1FC
	.long 0x00E2B222
	.long 0x00E2B24A
	.long 0x00000000
	.long 0x00E2B272
	.long 0x00E2B2A8
	.long 0x00E2B2DA
	.long 0x00E2B304
	.long 0x00E2B32A
	.long 0x00E2B34A
	.long 0x00E2B384
	.long 0x00E2B3CC
	.long 0x00000000
	.long 0x00E2B414
	.long 0x00E2B44A
	.long 0x00E2B478
	.long 0x00E2B48E
	.long 0x00000000
	.long 0x00E2B4B8
	.long 0x00E2B4EC
	.long 0x00E2B514
	.long 0x00E2B53C
	.long 0x00E2B564
	.long 0x00E2B58C
	.long 0x00E2B5B4
	.long 0x00E2B5DC
	.long 0x00E2B602
	.long 0x00E2B626
	.long 0x00E2B64A
	.long 0x00E2B66E
	.long 0x00E2B692
	.long 0x00E2B6BA
	.long 0x00E2B6E0
	.long 0x00E2B6FA
	.long 0x00E2B71A
	.long 0x00E2B734
	.long 0x00E2B74E
	.long 0x00E2B776
	.long 0x00E2B79C
	.long 0x00E2B7C4
	.long 0x00E2B7E8
	.long 0x00E2B810
	.long 0x00E2B836
	.long 0x00E2B85E
	.long 0x00000000
	.long 0x00E2B886
	.long 0x00E2B8BC
	.long 0x00E2B8EE
	.long 0x00E2B918
	.long 0x00E2B93E
	.long 0x00E2B95E
	.long 0x00E2B998
	.long 0x00E2B9E0
	.long 0x00000000
	.long 0x00E2BA28
	.long 0x00E2BA5E
	.long 0x00E2BA74
	.long 0x00E2BA8A
	.long 0x00E2BAB4
	.long 0x00E2BADE
	.long 0x00E2BB0A
	.long 0x00E2BB2E
	.long 0x00E2BB5A
	.long 0x00E2BB94
	.long 0x00E2BBB0
	.long 0x00E2BBCA
	.long 0x00E2BBF4
	.long 0x00E2BC1E
	.long 0x00000000
	.long 0x00E2BC48
	.long 0x00E2BC7E
	.long 0x00E2BC98
	.long 0x00E2BCB2
	.long 0x00E2BCCC
	.long 0x00E2BCE6
	.long 0x00E2BD00
	.long 0x00E2BD1A
	.long 0x00E2BD44
	.long 0x00E2BD6A
	.long 0x00E2BD8A
	.long 0x00E2BDC4
	.long 0x00E2BDFE
	.long 0x00E2BE38
	.long 0x00E2BE4E
	.long 0x00E2BE7A
	.long 0x00E2BE9E
	.long 0x00E2BECA
	.long 0x00E2BF04
	.long 0x00E2BF1E
	.long 0x00E2BF38
	.long 0x00E2BF52
	.long 0x00000000
	.long 0x00E2BF7C
	.long 0x00E2BFB0
	.long 0x00E2BFD6
	.long 0x00E2C000
	.long 0x00E2C020
	.long 0x00E2C062
	.long 0x00E2C09E
	.long 0x00E2C0C0
	.long 0x00E2C102
	.long 0x00E2C144
	.long 0x00E2C186
	.long 0x00E2C1C2
	.long 0x00E2C1E4
	.long 0x00E2C1FA
	.long 0x00E2C226
	.long 0x00E2C24A
	.long 0x00E2C284
	.long 0x00E2C2B0
	.long 0x00E2C2CA
	.long 0x00E2C2E4
	.long 0x00E2C2FE
	.long 0x00000000
	.long 0x00E2C328
	.long 0x00E2C35C
	.long 0x00E2C382
	.long 0x00E2C3AC
	.long 0x00E2C3CC
	.long 0x00E2C40E
	.long 0x00E2C450
	.long 0x00E2C492
	.long 0x00E2C4D2
	.long 0x00E2C4E8
	.long 0x00E2C514
	.long 0x00E2C538
	.long 0x00E2C572
	.long 0x00E2C59E
	.long 0x00E2C5B8
	.long 0x00E2C5D2
	.long 0x00000000
	.long 0x00E2C5FC
	.long 0x00E2C636
	.long 0x00E2C65C
	.long 0x00E2C686
	.long 0x00E2C6A6
	.long 0x00E2C6E8
	.long 0x00E2C72A
	.long 0x00E2C76C
	.long 0x00E2C7AC
	.long 0x00E2C7C2
	.long 0x00E2C7EE
	.long 0x00E2C812
	.long 0x00E2C84C
	.long 0x00E2C878
	.long 0x00E2C892
	.long 0x00E2C8AC
	.long 0x00000000
	.long 0x00E2C8D6
	.long 0x00E2C90C
	.long 0x00E2C92C
	.long 0x00E2C960
	.long 0x00E2C98A
	.long 0x00E2C9B4
	.long 0x00E2C9DA
	.long 0x00E2CA1C
	.long 0x00E2CA50
	.long 0x00E2CA7C
	.long 0x00E2CA96
	.long 0x00E2CAB0
	.long 0x00E2CACA
	.long 0x00E2CAE4
	.long 0x00E2CAFE
	.long 0x00E2CB40
	.long 0x00E2CB82
	.long 0x00E2CB98
	.long 0x00E2CBC4
	.long 0x00E2CBE8
	.long 0x00E2CC22
	.long 0x00E2CC4E
	.long 0x00E2CC68
	.long 0x00E2CC82
	.long 0x00E2CC9C
	.long 0x00000000
	.long 0x00E2CCC6
	.long 0x00E2CCFE
	.long 0x00E2CD28
	.long 0x00E2CD4E
	.long 0x00E2CD6E
	.long 0x00E2CDB0
	.long 0x00E2CDF2
	.long 0x00E2CE34
	.long 0x00E2CE76
	.long 0x00E2CE8C
	.long 0x00E2CEB8
	.long 0x00E2CEDC
	.long 0x00E2CF08
	.long 0x00E2CF42
	.long 0x00E2CF5C
	.long 0x00E2CF76
	.long 0x00000000
	.long 0x00E2CFA0
	.long 0x00E2CFD8
	.long 0x00E2D002
	.long 0x00E2D028
	.long 0x00E2D048
	.long 0x00E2D08A
	.long 0x00E2D0CC
	.long 0x00E2D10E
	.long 0x00E2D150
	.long 0x00E2D166
	.long 0x00E2D192
	.long 0x00E2D1B6
	.long 0x00E2D1F0
	.long 0x00E2D21C
	.long 0x00E2D236
	.long 0x00E2D250
	.long 0x00000000
	.long 0x00E2D27A
	.long 0x00E2D2B2
	.long 0x00E2D2DC
	.long 0x00E2D306
	.long 0x00E2D330
	.long 0x00E2D35A
	.long 0x00E2D378
	.long 0x00E2D394
	.long 0x00E2D3AA
	.long 0x00E2D3D6
	.long 0x00E2D3FA
	.long 0x00E2D414
	.long 0x00E2D42E
	.long 0x00E2D448
	.long 0x00E2D462
	.long 0x00E2D48E
	.long 0x00E2D4B8
	.long 0x00000000
	.long 0x00E2D4F2
	.long 0x00E2D52C
	.long 0x00E2D552
	.long 0x00E2D57C
	.long 0x00E2D59C
	.long 0x00E2D5DE
	.long 0x00E2D620
	.long 0x00E2D660
	.long 0x00E2D676
	.long 0x00E2D6A2
	.long 0x00E2D6C6
	.long 0x00E2D700
	.long 0x00E2D72C
	.long 0x00E2D746
	.long 0x00E2D760
	.long 0x00000000
	.long 0x00E2D78A
	.long 0x00E2D7C4
	.long 0x00E2D7EE
	.long 0x00E2D818
	.long 0x00E2D842
	.long 0x00E2D86C
	.long 0x00E2D88A
	.long 0x00E2D8A6
	.long 0x00E2D8BC
	.long 0x00E2D8E8
	.long 0x00E2D90C
	.long 0x00E2D926
	.long 0x00E2D940
	.long 0x00E2D95A
	.long 0x00E2D974
	.long 0x00E2D9A0
	.long 0x00E2D9CA
	.long 0x00000000
	.long 0x00000000
	.long 0x00000000
	.long 0x00E2DA04
	.long 0x00E2DA40
	.long 0x00000000
	.long 0x00E2DA60
	.long 0x00E2DA96
	.long 0x00E2DB52
	.long 0x0003E204
	.long 0x0003E23A
	.long 0x0003E270
	.long 0x0003E2A6
	.long 0x00E2DBBA
	.long 0x00E2DBE4
	.long 0x00E2DC0E
	.long 0x00E2DC34
	.long 0x00E2DC5A
	.long 0x00E2DC74
	.long 0x00E2DCBC
	.long 0x00E2DCEA
	.long 0x00000000
	.long 0x00E2DD10
	.long 0x00E2DD48
	.long 0x00E2DD62
	.long 0x00E2DD8C
	.long 0x00E2DDA6
	.long 0x00E2DDD2
	.long 0x00E2DDF6
	.long 0x00E2DE38
	.long 0x00E2DE7A
	.long 0x00E2DEBC
	.long 0x00E2DEFE
	.long 0x00E2DF22
	.long 0x00E2DF64
	.long 0x00E2DFA6
	.long 0x00E2DFEC
	.long 0x00E2E00E
	.long 0x00E2E028
	.long 0x00E2E04C
	.long 0x00E2E076
	.long 0x00E2E090
	.long 0x00E2E0B4
	.long 0x00E2E0DE
	.long 0x00E2E102
	.long 0x00E2E12C
	.long 0x00E2E14E
	.long 0x00E2E168
	.long 0x00E2E18C
	.long 0x00E2E1A8
	.long 0x00E2E1C4
	.long 0x00E2E1E8
	.long 0x00E2E202
	.long 0x00E2E226
	.long 0x00E2E250
	.long 0x00E2E274
	.long 0x00E2E29E
	.long 0x00E2E2C2
	.long 0x00E2E2EC
	.long 0x00E2E30E
	.long 0x00E2E328
	.long 0x00E2E34C
	.long 0x00E2E370
	.long 0x00E2E38C
	.long 0x00E2E3A8
	.long 0x00E2E3C4
	.long 0x00E2E3DE
	.long 0x00E2E400
	.long 0x00E2E41A
	.long 0x00E2E43E
	.long 0x00E2E462
	.long 0x00E2E47E
	.long 0x00E2E49A
	.long 0x00E2E4B6
	.long 0x00E2E4D2
	.long 0x00E2E4EC
	.long 0x00E2E510
	.long 0x00E2E53A
	.long 0x00E2E55E
	.long 0x00E2E588
	.long 0x00E2E5AC
	.long 0x00E2E5D6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7100
; naka_effects_seq+0x7100  --  naka_effects_seq +0x7100..+0x7108 (ROM 0xe2f0a4..0xe2f0ac), 8 bytes
; No RegObjTabl-registered table points at the start of these 8 bytes
; (0xe2f0a4..0xe2f0ac); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7100, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7108
; naka_effects_seq+0x7108  --  naka_effects_seq +0x7108..+0x713e (ROM 0xe2f0ac..0xe2f0e2), 54 bytes
; The table itself: ResName slot 0x30a (table 0xe2f0ac, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7108, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x713e
; naka_effects_seq+0x713e  --  naka_effects_seq +0x713e..+0x7156 (ROM 0xe2f0e2..0xe2f0fa), 24 bytes
; Name strings of elements 0-11 of ResName slot 0x30a (table 0xe2f0ac,
; 12 entries, InitializeKubo), names for Viewable slot 0xa: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x713E, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7156
; naka_effects_seq+0x7156  --  naka_effects_seq +0x7156..+0x718c (ROM 0xe2f0fa..0xe2f130), 54 bytes
; The table itself: ResName slot 0x30b (table 0xe2f0fa, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7156, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x718c
; naka_effects_seq+0x718c  --  naka_effects_seq +0x718c..+0x71a4 (ROM 0xe2f130..0xe2f148), 24 bytes
; Name strings of elements 0-11 of ResName slot 0x30b (table 0xe2f0fa,
; 12 entries, InitializeKubo), names for Viewable slot 0xb: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x718C, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x71a4
; naka_effects_seq+0x71a4  --  naka_effects_seq +0x71a4..+0x723e (ROM 0xe2f148..0xe2f1e2), 154 bytes
; The table itself: ResName slot 0x30c (table 0xe2f148, 37 entries,
; InitializeKubo) -- 37 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x71A4, 0x9A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x723e
; naka_effects_seq+0x723e  --  naka_effects_seq +0x723e..+0x728e (ROM 0xe2f1e2..0xe2f232), 80 bytes
; Name strings of elements 0-36 of ResName slot 0x30c (table 0xe2f148,
; 37 entries, InitializeKubo), names for Viewable slot 0xc: "EqOnOff",
; "", "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x723E, 0x50
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x728e
; naka_effects_seq+0x728e  --  naka_effects_seq +0x728e..+0x72c4 (ROM 0xe2f232..0xe2f268), 54 bytes
; The table itself: ResName slot 0x30e (table 0xe2f232, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x728E, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x72c4
; naka_effects_seq+0x72c4  --  naka_effects_seq +0x72c4..+0x72dc (ROM 0xe2f268..0xe2f280), 24 bytes
; Name strings of elements 0-11 of ResName slot 0x30e (table 0xe2f232,
; 12 entries, InitializeKubo), names for Viewable slot 0xe: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x72C4, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x72dc
; naka_effects_seq+0x72dc  --  naka_effects_seq +0x72dc..+0x7312 (ROM 0xe2f280..0xe2f2b6), 54 bytes
; The table itself: ResName slot 0x380 (table 0xe2f280, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x72DC, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7312
; naka_effects_seq+0x7312  --  naka_effects_seq +0x7312..+0x732a (ROM 0xe2f2b6..0xe2f2ce), 24 bytes
; Name strings of elements 0-11 of ResName slot 0x380 (table 0xe2f280,
; 12 entries, InitializeKubo), names for Viewable slot 0x80: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7312, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x732a
; naka_effects_seq+0x732a  --  naka_effects_seq +0x732a..+0x73a0 (ROM 0xe2f2ce..0xe2f344), 118 bytes
; The table itself: ResName slot 0x381 (table 0xe2f2ce, 28 entries,
; InitializeKubo) -- 28 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x732A, 0x76
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x73a0
; naka_effects_seq+0x73a0  --  naka_effects_seq +0x73a0..+0x7406 (ROM 0xe2f344..0xe2f3aa), 102 bytes
; Name strings of elements 0-27 of ResName slot 0x381 (table 0xe2f2ce,
; 28 entries, InitializeKubo), names for Viewable slot 0x81: "", "", "",
; "", "", "SngSelWin2", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x73A0, 0x66
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7406
; naka_effects_seq+0x7406  --  naka_effects_seq +0x7406..+0x742c (ROM 0xe2f3aa..0xe2f3d0), 38 bytes
; The table itself: ResName slot 0x382 (table 0xe2f3aa, 8 entries,
; InitializeKubo) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7406, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x742c
; naka_effects_seq+0x742c  --  naka_effects_seq +0x742c..+0x743c (ROM 0xe2f3d0..0xe2f3e0), 16 bytes
; Name strings of elements 0-7 of ResName slot 0x382 (table 0xe2f3aa, 8
; entries, InitializeKubo), names for Viewable slot 0x82: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x742C, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x743c
; naka_effects_seq+0x743c  --  naka_effects_seq +0x743c..+0x7482 (ROM 0xe2f3e0..0xe2f426), 70 bytes
; The table itself: ResName slot 0x383 (table 0xe2f3e0, 16 entries,
; InitializeKubo) -- 16 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x743C, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7482
; naka_effects_seq+0x7482  --  naka_effects_seq +0x7482..+0x74a2 (ROM 0xe2f426..0xe2f446), 32 bytes
; Name strings of elements 0-15 of ResName slot 0x383 (table 0xe2f3e0,
; 16 entries, InitializeKubo), names for Viewable slot 0x83: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7482, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x74a2
; naka_effects_seq+0x74a2  --  naka_effects_seq +0x74a2..+0x74d0 (ROM 0xe2f446..0xe2f474), 46 bytes
; The table itself: ResName slot 0x384 (table 0xe2f446, 10 entries,
; InitializeKubo) -- 10 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x74A2, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x74d0
; naka_effects_seq+0x74d0  --  naka_effects_seq +0x74d0..+0x74e4 (ROM 0xe2f474..0xe2f488), 20 bytes
; Name strings of elements 0-9 of ResName slot 0x384 (table 0xe2f446, 10
; entries, InitializeKubo), names for Viewable slot 0x84: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x74D0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x74e4
; naka_effects_seq+0x74e4  --  naka_effects_seq +0x74e4..+0x754e (ROM 0xe2f488..0xe2f4f2), 106 bytes
; The table itself: ResName slot 0x385 (table 0xe2f488, 25 entries,
; InitializeKubo) -- 25 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x74E4, 0x6A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x754e
; naka_effects_seq+0x754e  --  naka_effects_seq +0x754e..+0x75bc (ROM 0xe2f4f2..0xe2f560), 110 bytes
; Name strings of elements 0-24 of ResName slot 0x385 (table 0xe2f488,
; 25 entries, InitializeKubo), names for Viewable slot 0x85: "", "",
; "CycClrSw", "", "CycRecClrStr", "CycRecClrSw", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x754E, 0x6E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x75bc
; naka_effects_seq+0x75bc  --  naka_effects_seq +0x75bc..+0x75ee (ROM 0xe2f560..0xe2f592), 50 bytes
; The table itself: ResName slot 0x386 (table 0xe2f560, 11 entries,
; InitializeKubo) -- 11 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x75BC, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x75ee
; naka_effects_seq+0x75ee  --  naka_effects_seq +0x75ee..+0x760e (ROM 0xe2f592..0xe2f5b2), 32 bytes
; Name strings of elements 0-10 of ResName slot 0x386 (table 0xe2f560,
; 11 entries, InitializeKubo), names for Viewable slot 0x86: "", "", "",
; "MetCycRecSw", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x75EE, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x760e
; naka_effects_seq+0x760e  --  naka_effects_seq +0x760e..+0x7674 (ROM 0xe2f5b2..0xe2f618), 102 bytes
; The table itself: ResName slot 0x387 (table 0xe2f5b2, 24 entries,
; InitializeKubo) -- 24 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x760E, 0x66
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7674
; naka_effects_seq+0x7674  --  naka_effects_seq +0x7674..+0x76c6 (ROM 0xe2f618..0xe2f66a), 82 bytes
; Name strings of elements 0-23 of ResName slot 0x387 (table 0xe2f5b2,
; 24 entries, InitializeKubo), names for Viewable slot 0x87: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7674, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x76c6
; naka_effects_seq+0x76c6  --  naka_effects_seq +0x76c6..+0x76fc (ROM 0xe2f66a..0xe2f6a0), 54 bytes
; The table itself: ResName slot 0x388 (table 0xe2f66a, 12 entries,
; InitializeKubo) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x76C6, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x76fc
; naka_effects_seq+0x76fc  --  naka_effects_seq +0x76fc..+0x771e (ROM 0xe2f6a0..0xe2f6c2), 34 bytes
; Name strings of elements 0-11 of ResName slot 0x388 (table 0xe2f66a,
; 12 entries, InitializeKubo), names for Viewable slot 0x88: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x76FC, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x771e
; naka_effects_seq+0x771e  --  naka_effects_seq +0x771e..+0x7734 (ROM 0xe2f6c2..0xe2f6d8), 22 bytes
; The table itself: ResName slot 0x38d (table 0xe2f6c2, 4 entries,
; InitializeKubo) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x771E, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7734
; naka_effects_seq+0x7734  --  naka_effects_seq +0x7734..+0x773c (ROM 0xe2f6d8..0xe2f6e0), 8 bytes
; Name strings of elements 0-3 of ResName slot 0x38d (table 0xe2f6c2, 4
; entries, InitializeKubo), names for Viewable slot 0x8d: "", "", "",
; "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7734, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x773c
; naka_effects_seq+0x773c  --  naka_effects_seq +0x773c..+0x7786 (ROM 0xe2f6e0..0xe2f72a), 74 bytes
; The table itself: ResName slot 0x390 (table 0xe2f6e0, 17 entries,
; InitializeKubo) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x773C, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7786
; naka_effects_seq+0x7786  --  naka_effects_seq +0x7786..+0x77b4 (ROM 0xe2f72a..0xe2f758), 46 bytes
; Name strings of elements 0-16 of ResName slot 0x390 (table 0xe2f6e0,
; 17 entries, InitializeKubo), names for Viewable slot 0x90: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7786, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x77b4
; naka_effects_seq+0x77b4  --  naka_effects_seq +0x77b4..+0x7806 (ROM 0xe2f758..0xe2f7aa), 82 bytes
; The table itself: ResName slot 0x391 (table 0xe2f758, 19 entries,
; InitializeKubo) -- 19 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x77B4, 0x52
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7806
; naka_effects_seq+0x7806  --  naka_effects_seq +0x7806..+0x7838 (ROM 0xe2f7aa..0xe2f7dc), 50 bytes
; Name strings of elements 0-18 of ResName slot 0x391 (table 0xe2f758,
; 19 entries, InitializeKubo), names for Viewable slot 0x91: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7806, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7838
; naka_effects_seq+0x7838  --  naka_effects_seq +0x7838..+0x78a6 (ROM 0xe2f7dc..0xe2f84a), 110 bytes
; The table itself: ResName slot 0x393 (table 0xe2f7dc, 26 entries,
; InitializeKubo) -- 26 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7838, 0x6E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x78a6
; naka_effects_seq+0x78a6  --  naka_effects_seq +0x78a6..+0x78f4 (ROM 0xe2f84a..0xe2f898), 78 bytes
; Name strings of elements 0-25 of ResName slot 0x393 (table 0xe2f7dc,
; 26 entries, InitializeKubo), names for Viewable slot 0x93: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x78A6, 0x4E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x78f4
; naka_effects_seq+0x78f4  --  naka_effects_seq +0x78f4..+0x790a (ROM 0xe2f898..0xe2f8ae), 22 bytes
; The table itself: ResName slot 0x394 (table 0xe2f898, 4 entries,
; InitializeKubo) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x78F4, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x790a
; naka_effects_seq+0x790a  --  naka_effects_seq +0x790a..+0x7912 (ROM 0xe2f8ae..0xe2f8b6), 8 bytes
; Name strings of elements 0-3 of ResName slot 0x394 (table 0xe2f898, 4
; entries, InitializeKubo), names for Viewable slot 0x94: "", "", "",
; "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x790A, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7912
; naka_effects_seq+0x7912  --  naka_effects_seq +0x7912..+0x7984 (ROM 0xe2f8b6..0xe2f928), 114 bytes
; The table itself: ResName slot 0x395 (table 0xe2f8b6, 27 entries,
; InitializeKubo) -- 27 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7912, 0x72
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7984
; naka_effects_seq+0x7984  --  naka_effects_seq +0x7984..+0x79c2 (ROM 0xe2f928..0xe2f966), 62 bytes
; Name strings of elements 0-26 of ResName slot 0x395 (table 0xe2f8b6,
; 27 entries, InitializeKubo), names for Viewable slot 0x95: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7984, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x79c2
; naka_effects_seq+0x79c2  --  naka_effects_seq +0x79c2..+0x79e8 (ROM 0xe2f966..0xe2f98c), 38 bytes
; The table itself: ResName slot 0x396 (table 0xe2f966, 8 entries,
; InitializeKubo) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x79C2, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x79e8
; naka_effects_seq+0x79e8  --  naka_effects_seq +0x79e8..+0x79f8 (ROM 0xe2f98c..0xe2f99c), 16 bytes
; Name strings of elements 0-7 of ResName slot 0x396 (table 0xe2f966, 8
; entries, InitializeKubo), names for Viewable slot 0x96: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x79E8, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x79f8
; naka_effects_seq+0x79f8  --  naka_effects_seq +0x79f8..+0x7a0e (ROM 0xe2f99c..0xe2f9b2), 22 bytes
; The table itself: ResName slot 0x397 (table 0xe2f99c, 4 entries,
; InitializeKubo) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x79F8, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7a0e
; naka_effects_seq+0x7a0e  --  naka_effects_seq +0x7a0e..+0x7a16 (ROM 0xe2f9b2..0xe2f9ba), 8 bytes
; Name strings of elements 0-3 of ResName slot 0x397 (table 0xe2f99c, 4
; entries, InitializeKubo), names for Viewable slot 0x97: "", "", "",
; "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7A0E, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7a16
; naka_effects_seq+0x7a16  --  naka_effects_seq +0x7a16..+0x7a84 (ROM 0xe2f9ba..0xe2fa28), 110 bytes
; The table itself: ResName slot 0x398 (table 0xe2f9ba, 26 entries,
; InitializeKubo) -- 26 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7A16, 0x6E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7a84
; naka_effects_seq+0x7a84  --  naka_effects_seq +0x7a84..+0x7ac0 (ROM 0xe2fa28..0xe2fa64), 60 bytes
; Name strings of elements 0-25 of ResName slot 0x398 (table 0xe2f9ba,
; 26 entries, InitializeKubo), names for Viewable slot 0x98: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7A84, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7ac0
; naka_effects_seq+0x7ac0  --  naka_effects_seq +0x7ac0..+0x7ae6 (ROM 0xe2fa64..0xe2fa8a), 38 bytes
; The table itself: ResName slot 0x399 (table 0xe2fa64, 8 entries,
; InitializeKubo) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7AC0, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7ae6
; naka_effects_seq+0x7ae6  --  naka_effects_seq +0x7ae6..+0x7af6 (ROM 0xe2fa8a..0xe2fa9a), 16 bytes
; Name strings of elements 0-7 of ResName slot 0x399 (table 0xe2fa64, 8
; entries, InitializeKubo), names for Viewable slot 0x99: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7AE6, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7af6
; naka_effects_seq+0x7af6  --  naka_effects_seq +0x7af6..+0x7b34 (ROM 0xe2fa9a..0xe2fad8), 62 bytes
; The table itself: ResName slot 0x39a (table 0xe2fa9a, 14 entries,
; InitializeKubo) -- 14 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7AF6, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7b34
; naka_effects_seq+0x7b34  --  naka_effects_seq +0x7b34..+0x7b5e (ROM 0xe2fad8..0xe2fb02), 42 bytes
; Name strings of elements 0-13 of ResName slot 0x39a (table 0xe2fa9a,
; 14 entries, InitializeKubo), names for Viewable slot 0x9a: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7B34, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7b5e
; naka_effects_seq+0x7b5e  --  naka_effects_seq +0x7b5e..+0x7bbc (ROM 0xe2fb02..0xe2fb60), 94 bytes
; The table itself: ResName slot 0x39b (table 0xe2fb02, 22 entries,
; InitializeKubo) -- 22 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7B5E, 0x5E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7bbc
; naka_effects_seq+0x7bbc  --  naka_effects_seq +0x7bbc..+0x7bf6 (ROM 0xe2fb60..0xe2fb9a), 58 bytes
; Name strings of elements 0-21 of ResName slot 0x39b (table 0xe2fb02,
; 22 entries, InitializeKubo), names for Viewable slot 0x9b: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7BBC, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7bf6
; naka_effects_seq+0x7bf6  --  naka_effects_seq +0x7bf6..+0x7c50 (ROM 0xe2fb9a..0xe2fbf4), 90 bytes
; The table itself: ResName slot 0x39c (table 0xe2fb9a, 21 entries,
; InitializeKubo) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7BF6, 0x5A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7c50
; naka_effects_seq+0x7c50  --  naka_effects_seq +0x7c50..+0x7c84 (ROM 0xe2fbf4..0xe2fc28), 52 bytes
; Name strings of elements 0-20 of ResName slot 0x39c (table 0xe2fb9a,
; 21 entries, InitializeKubo), names for Viewable slot 0x9c: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7C50, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7c84
; naka_effects_seq+0x7c84  --  naka_effects_seq +0x7c84..+0x7cca (ROM 0xe2fc28..0xe2fc6e), 70 bytes
; The table itself: ResName slot 0x39d (table 0xe2fc28, 16 entries,
; InitializeKubo) -- 16 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7C84, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7cca
; naka_effects_seq+0x7cca  --  naka_effects_seq +0x7cca..+0x7cf6 (ROM 0xe2fc6e..0xe2fc9a), 44 bytes
; Name strings of elements 0-15 of ResName slot 0x39d (table 0xe2fc28,
; 16 entries, InitializeKubo), names for Viewable slot 0x9d: "", "", "",
; "", "", "TrnsSureDisp", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7CCA, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7cf6
; naka_effects_seq+0x7cf6  --  naka_effects_seq +0x7cf6..+0x7d3c (ROM 0xe2fc9a..0xe2fce0), 70 bytes
; The table itself: ResName slot 0x39e (table 0xe2fc9a, 16 entries,
; InitializeKubo) -- 16 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7CF6, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7d3c
; naka_effects_seq+0x7d3c  --  naka_effects_seq +0x7d3c..+0x7d68 (ROM 0xe2fce0..0xe2fd0c), 44 bytes
; Name strings of elements 0-15 of ResName slot 0x39e (table 0xe2fc9a,
; 16 entries, InitializeKubo), names for Viewable slot 0x9e: "", "", "",
; "", "", "VeloSureDisp", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7D3C, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7d68
; naka_effects_seq+0x7d68  --  naka_effects_seq +0x7d68..+0x7dd2 (ROM 0xe2fd0c..0xe2fd76), 106 bytes
; The table itself: ResName slot 0x39f (table 0xe2fd0c, 25 entries,
; InitializeKubo) -- 25 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7D68, 0x6A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7dd2
; naka_effects_seq+0x7dd2  --  naka_effects_seq +0x7dd2..+0x7e10 (ROM 0xe2fd76..0xe2fdb4), 62 bytes
; Name strings of elements 0-24 of ResName slot 0x39f (table 0xe2fd0c,
; 25 entries, InitializeKubo), names for Viewable slot 0x9f: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7DD2, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7e10
; naka_effects_seq+0x7e10  --  naka_effects_seq +0x7e10..+0x7e56 (ROM 0xe2fdb4..0xe2fdfa), 70 bytes
; The table itself: ResName slot 0x3a0 (table 0xe2fdb4, 16 entries,
; InitializeKubo) -- 16 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7E10, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7e56
; naka_effects_seq+0x7e56  --  naka_effects_seq +0x7e56..+0x7e80 (ROM 0xe2fdfa..0xe2fe24), 42 bytes
; Name strings of elements 0-15 of ResName slot 0x3a0 (table 0xe2fdb4,
; 16 entries, InitializeKubo), names for Viewable slot 0xa0: "", "", "",
; "", "", "AdvSureDisp", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7E56, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7e80
; naka_effects_seq+0x7e80  --  naka_effects_seq +0x7e80..+0x7ec6 (ROM 0xe2fe24..0xe2fe6a), 70 bytes
; The table itself: ResName slot 0x3a1 (table 0xe2fe24, 16 entries,
; InitializeKubo) -- 16 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7E80, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7ec6
; naka_effects_seq+0x7ec6  --  naka_effects_seq +0x7ec6..+0x7ef2 (ROM 0xe2fe6a..0xe2fe96), 44 bytes
; Name strings of elements 0-15 of ResName slot 0x3a1 (table 0xe2fe24,
; 16 entries, InitializeKubo), names for Viewable slot 0xa1: "", "", "",
; "", "", "MersSureDisp", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7EC6, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7ef2
; naka_effects_seq+0x7ef2  --  naka_effects_seq +0x7ef2..+0x7f3c (ROM 0xe2fe96..0xe2fee0), 74 bytes
; The table itself: ResName slot 0x3a2 (table 0xe2fe96, 17 entries,
; InitializeKubo) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7EF2, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7f3c
; naka_effects_seq+0x7f3c  --  naka_effects_seq +0x7f3c..+0x7f68 (ROM 0xe2fee0..0xe2ff0c), 44 bytes
; Name strings of elements 0-16 of ResName slot 0x3a2 (table 0xe2fe96,
; 17 entries, InitializeKubo), names for Viewable slot 0xa2: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7F3C, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7f68
; naka_effects_seq+0x7f68  --  naka_effects_seq +0x7f68..+0x7faa (ROM 0xe2ff0c..0xe2ff4e), 66 bytes
; The table itself: ResName slot 0x3a3 (table 0xe2ff0c, 15 entries,
; InitializeKubo) -- 15 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7F68, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7faa
; naka_effects_seq+0x7faa  --  naka_effects_seq +0x7faa..+0x7fd4 (ROM 0xe2ff4e..0xe2ff78), 42 bytes
; Name strings of elements 0-14 of ResName slot 0x3a3 (table 0xe2ff0c,
; 15 entries, InitializeKubo), names for Viewable slot 0xa3: "", "", "",
; "", "", "MdelSureDisp", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7FAA, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x7fd4
; naka_effects_seq+0x7fd4  --  naka_effects_seq +0x7fd4..+0x801e (ROM 0xe2ff78..0xe2ffc2), 74 bytes
; The table itself: ResName slot 0x3a4 (table 0xe2ff78, 17 entries,
; InitializeKubo) -- 17 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x7FD4, 0x4A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x801e
; naka_effects_seq+0x801e  --  naka_effects_seq +0x801e..+0x804c (ROM 0xe2ffc2..0xe2fff0), 46 bytes
; Name strings of elements 0-16 of ResName slot 0x3a4 (table 0xe2ff78,
; 17 entries, InitializeKubo), names for Viewable slot 0xa4: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x801E, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x804c
; naka_effects_seq+0x804c  --  naka_effects_seq +0x804c..+0x8052 (ROM 0xe2fff0..0xe2fff6), 6 bytes
; The table itself: ResName slot 0x3a8 (table 0xe2fff0, 0 entries,
; InitializeKubo) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x804C, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x8052
; naka_effects_seq+0x8052  --  naka_effects_seq +0x8052..+0x8058 (ROM 0xe2fff6..0xe2fffc), 6 bytes
; The table itself: ResName slot 0x3aa (table 0xe2fff6, 0 entries,
; InitializeKubo) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x8052, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x8058
; naka_effects_seq+0x8058  --  naka_effects_seq +0x8058..+0x8066 (ROM 0xe2fffc..0xe3000a), 14 bytes
; The table itself: ResName slot 0x3ab (table 0xe2fffc, 2 entries,
; InitializeKubo) -- 2 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x8058, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x8066
; naka_effects_seq+0x8066  --  naka_effects_seq +0x8066..+0x806a (ROM 0xe3000a..0xe3000e), 4 bytes
; Name strings of elements 0-1 of ResName slot 0x3ab (table 0xe2fffc, 2
; entries, InitializeKubo), names for Viewable slot 0xab: "", "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x8066, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x806a
; naka_effects_seq+0x806a  --  naka_effects_seq +0x806a..+0x80ac (ROM 0xe3000e..0xe30050), 66 bytes
; The table itself: ResName slot 0x3d6 (table 0xe3000e, 15 entries,
; InitializeKubo) -- 15 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x806A, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x80ac
; naka_effects_seq+0x80ac  --  naka_effects_seq +0x80ac..+0x80fa (ROM 0xe30050..0xe3009e), 78 bytes
; Name strings of elements 0-14 of ResName slot 0x3d6 (table 0xe3000e,
; 15 entries, InitializeKubo), names for Viewable slot 0xd6: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x80AC, 0x4E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x80fa
; naka_effects_seq+0x80fa  --  naka_effects_seq +0x80fa..+0x811c (ROM 0xe3009e..0xe300c0), 34 bytes
; The table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; InitializeKubo) -- 61 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x80FA, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_563_E300C0
; Naka_Help_563_E300C0  --  naka_effects_seq +0x811c..+0x8123 (ROM 0xe300c0..0xe300c7), 7 bytes
; No RegObjTabl-registered table points at the start of these 7 bytes
; (0xe300c0..0xe300c7); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_563_E300C0:
	.incbin "includes/generated/naka_effects_seq.bin", 0x811C, 0x7
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_564_E300C7
; Naka_Help_564_E300C7  --  naka_effects_seq +0x8123..+0x8128 (ROM 0xe300c7..0xe300cc), 5 bytes
; No RegObjTabl-registered table points at the start of these 5 bytes
; (0xe300c7..0xe300cc); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_564_E300C7:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8123, 0x5
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_565_E300CC
; Naka_Help_565_E300CC  --  naka_effects_seq +0x8128..+0x813f (ROM 0xe300cc..0xe300e3), 23 bytes
; No RegObjTabl-registered table points at the start of these 23 bytes
; (0xe300cc..0xe300e3); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_565_E300CC:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8128, 0x17
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_566_E300E3
; Naka_Help_566_E300E3  --  naka_effects_seq +0x813f..+0x8148 (ROM 0xe300e3..0xe300ec), 9 bytes
; No RegObjTabl-registered table points at the start of these 9 bytes
; (0xe300e3..0xe300ec); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_566_E300E3:
	.incbin "includes/generated/naka_effects_seq.bin", 0x813F, 0x9
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_567_E300EC
; Naka_Help_567_E300EC  --  naka_effects_seq +0x8148..+0x816f (ROM 0xe300ec..0xe30113), 39 bytes
; No RegObjTabl-registered table points at the start of these 39 bytes
; (0xe300ec..0xe30113); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_567_E300EC:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8148, 0x27
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Help_569_E30113
; Naka_Help_569_E30113  --  naka_effects_seq +0x816f..+0x81f4 (ROM 0xe30113..0xe30198), 133 bytes
; No RegObjTabl-registered table points at the start of these 133 bytes
; (0xe30113..0xe30198); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Help_569_E30113:
	.incbin "includes/generated/naka_effects_seq.bin", 0x816F, 0x85
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x81f4
; naka_effects_seq+0x81f4  --  naka_effects_seq +0x81f4..+0x8578 (ROM 0xe30198..0xe3051c), 900 bytes
; Name strings of elements 0-60 of ResName slot 0x3e7 (table 0xe3009e,
; 61 entries, InitializeKubo), names for Viewable slot 0xe7: "",
; "HelpLang4P4", "", "HelpLang4P3", "", "HelpLang4P2", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x81F4, 0x384
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x8578
; naka_effects_seq+0x8578  --  naka_effects_seq +0x8578..+0x8600 (ROM 0xe3051c..0xe305a4), 136 bytes
; The table itself: MainFunction slot 0x148 (table 0xe3051c, 44 entries,
; InitializeKubo) -- 44 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x8578, 0x88
EmbeddedPtrTable_v7_naka_effects_seq_008600:
	.long SdAccillTitleFunc
	.long MimeSyori
	.long SqNoteCycpTitleFunc
	.long SqDrmCycpTitleFunc
	.long HelpModeFunc
	.long HelpTitleFunc
	.long HelpLangChkMain
	.long HelpFlashFunc
	.long EtmenuTitleFunc
	.long MainPanic
	.long 0x00000000
	.long 0x00E30932
	.long 0x00E30926
	.long 0x00E3091A
	.long 0x00E3090E
	.long 0x00E30902
	.long 0x00E308F2
	.long 0x00E308E2
	.long 0x00E308D2
	.long 0x00E308C2
	.long 0x00E308AE
	.long 0x00E3089E
	.long 0x00E3088C
	.long 0x00E3087A
	.long 0x00E3086A
	.long 0x00E3085A
	.long 0x00E3084A
	.long 0x00E3083A
	.long 0x00E3082A
	.long 0x00E3081A
	.long 0x00E3080A
	.long 0x00E307FA
	.long 0x00E307EA
	.long 0x00E307DA
	.long 0x00E307C8
	.long 0x00E307B8
	.long 0x00E307A8
	.long 0x00E30796
	.long 0x00E30784
	.long 0x00E30770
	.long 0x00E3075C
	.long 0x00E30750
	.long 0x00E30742
	.long 0x00E30730
	.long 0x00E3071E
	.long 0x00E3070C
	.long 0x00E30702
	.long 0x00E306EE
	.long 0x00E306DA
	.long 0x00E306CC
	.long 0x00E306BE
	.long 0x00E306AE
	.long 0x00E306A0
	.long 0x00E30690
	.long 0x00E30686
	.long 0x00E30684
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x86e0
; naka_effects_seq+0x86e0  --  naka_effects_seq +0x86e0..+0x86e2 (ROM 0xe30684..0xe30686), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xe30684..0xe30686); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x86E0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_effects_seq+0x86e2
; naka_effects_seq+0x86e2  --  naka_effects_seq +0x86e2..+0x8ebc (ROM 0xe30686..0xe30e60), 2010 bytes
; Name strings of elements 0-43 of MainFunction slot 0x448 (table
; 0xe305d0, 44 entries, InitializeKubo), names for MainFunction slot
; 0x148: "MainPanic", "EtmenuTitleFunc", "HelpFlashFunc",
; "HelpLangChkMain", "HelpTitleFunc", "HelpModeFunc", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_effects_seq.bin", 0x86E2, 0x7DA

; External label offsets within the binary blob above.
