
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

; [nakarest] Naka_ReverbScreen_EmptyStr  +0x0..+0x2 (0xe27fa4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe27fa4 not derived; readers below
; [nakarest] Readers: 1 data word in NakaData_SeqChannels (at 0xeee2b8).
Naka_ReverbScreen_EmptyStr:
	.incbin "includes/generated/naka_effects_seq.bin", 0x0, 0x2
; [nakarest] naka_effects_seq+0x2  +0x2..+0x1bc (0xe27fa6, 442 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xa (table 0xe2e624, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x3, Label (32 B) x4,
; [nakarest] EffectBox (38 B), Box (26 B), IvIntEasySet (24 B), IvSdrev (22 B). 5 texts the
; [nakarest] records point at (Viewable slot 0xa (table 0xe2e624, 12 entries, InitializeKubo)):
; [nakarest] "REVERB" (TtlScreen.title of element 0); "TYPE" (Label.str of element 4);
; [nakarest] "PARAMETER" (Label.str of element 5); "VALUE" (Label.str of element 6); ....
NakaWidget_KuboView00A_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x2, 0x32
NakaWidget_KuboView00A_1_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x34, 0x2A
NakaWidget_KuboView00A_2_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x5E, 0x2A
NakaWidget_KuboView00A_3_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x88, 0x2A
NakaWidget_KuboView00A_4_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xB2, 0x26
NakaWidget_KuboView00A_5_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xD8, 0x2A
NakaWidget_KuboView00A_6_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x102, 0x26
NakaWidget_KuboView00A_7_EffectBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x128, 0x26
NakaWidget_KuboView00A_8_Box:		.incbin "includes/generated/naka_effects_seq.bin", 0x14E, 0x1A
NakaWidget_KuboView00A_9_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x168, 0x26
NakaWidget_KuboView00A_10_IvIntEasySet:	.incbin "includes/generated/naka_effects_seq.bin", 0x18E, 0x18
NakaWidget_KuboView00A_11_IvSdrev:	.incbin "includes/generated/naka_effects_seq.bin", 0x1A6, 0x16
; [nakarest] naka_effects_seq+0x1bc  +0x1bc..+0x37c (0xe28160, 448 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xb (table 0xe2e658, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x4, AcIndexWideES (42 B) x3,
; [nakarest] EffectBox (38 B), Box (26 B), IvIntEasySet (24 B), IvSddsp (22 B). 5 texts the
; [nakarest] records point at (Viewable slot 0xb (table 0xe2e658, 12 entries, InitializeKubo)):
; [nakarest] "DSP EFFECT" (TtlScreen.title of element 0); "TYPE :" (Label.str of element 1);
; [nakarest] "TYPE" (Label.str of element 3); "PARAMETER" (Label.str of element 6); ....
NakaWidget_KuboView00B_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x1BC, 0x36
NakaWidget_KuboView00B_1_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1F2, 0x28
NakaWidget_KuboView00B_2_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x21A, 0x2A
NakaWidget_KuboView00B_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x244, 0x26
NakaWidget_KuboView00B_4_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x26A, 0x2A
NakaWidget_KuboView00B_5_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x294, 0x2A
NakaWidget_KuboView00B_6_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x2BE, 0x2A
NakaWidget_KuboView00B_7_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x2E8, 0x26
NakaWidget_KuboView00B_8_EffectBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x30E, 0x26
NakaWidget_KuboView00B_9_Box:		.incbin "includes/generated/naka_effects_seq.bin", 0x334, 0x1A
NakaWidget_KuboView00B_10_IvIntEasySet:	.incbin "includes/generated/naka_effects_seq.bin", 0x34E, 0x18
NakaWidget_KuboView00B_11_IvSddsp:	.incbin "includes/generated/naka_effects_seq.bin", 0x366, 0x16
; [nakarest] naka_effects_seq+0x37c  +0x37c..+0x8e4 (0xe28320, 1384 B)
; [nakarest] widget records, elements 0-36 of Viewable slot 0xc (table 0xe2e68c, 37 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x8, Label (32 B) x19, Line
; [nakarest] (26 B) x6, EqualizerBox (34 B), Box (26 B), EqOnOffFuncToggle (44 B). 22 texts the
; [nakarest] records point at (Viewable slot 0xc (table 0xe2e68c, 37 entries, InitializeKubo)):
; [nakarest] "EQUALIZER" (TtlScreen.title of element 0); "FREQ" (Label.str of element 9); "GAIN"
; [nakarest] (Label.str of element 10); "FREQ" (Label.str of element 11); ....
NakaWidget_KuboView00C_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x37C, 0x34
NakaWidget_KuboView00C_1_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3B0, 0x28
NakaWidget_KuboView00C_2_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3D8, 0x28
NakaWidget_KuboView00C_3_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x400, 0x28
NakaWidget_KuboView00C_4_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x428, 0x28
NakaWidget_KuboView00C_5_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x450, 0x28
NakaWidget_KuboView00C_6_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x478, 0x28
NakaWidget_KuboView00C_7_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x4A0, 0x28
NakaWidget_KuboView00C_8_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x4C8, 0x28
NakaWidget_KuboView00C_9_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x4F0, 0x26
NakaWidget_KuboView00C_10_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x516, 0x26
NakaWidget_KuboView00C_11_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x53C, 0x26
NakaWidget_KuboView00C_12_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x562, 0x26
NakaWidget_KuboView00C_13_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x588, 0x26
NakaWidget_KuboView00C_14_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x5AE, 0x26
NakaWidget_KuboView00C_15_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x5D4, 0x26
NakaWidget_KuboView00C_16_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x5FA, 0x26
NakaWidget_KuboView00C_17_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x620, 0x24
NakaWidget_KuboView00C_18_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x644, 0x28
NakaWidget_KuboView00C_19_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x66C, 0x2A
NakaWidget_KuboView00C_20_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x696, 0x26
NakaWidget_KuboView00C_21_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x6BC, 0x1A
NakaWidget_KuboView00C_22_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x6D6, 0x1A
NakaWidget_KuboView00C_23_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x6F0, 0x1A
NakaWidget_KuboView00C_24_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x70A, 0x1A
NakaWidget_KuboView00C_25_EqualizerBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x724, 0x22
NakaWidget_KuboView00C_26_Box:		.incbin "includes/generated/naka_effects_seq.bin", 0x746, 0x1A
NakaWidget_KuboView00C_27_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x760, 0x2A
NakaWidget_KuboView00C_28_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x78A, 0x2A
NakaWidget_KuboView00C_29_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x7B4, 0x24
NakaWidget_KuboView00C_30_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x7D8, 0x28
NakaWidget_KuboView00C_31_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x800, 0x2A
NakaWidget_KuboView00C_32_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x82A, 0x26
NakaWidget_KuboView00C_33_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x850, 0x1A
NakaWidget_KuboView00C_34_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x86A, 0x1A
NakaWidget_KuboView00C_35_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x884, 0x26
NakaWidget_EqOnOff:			.incbin "includes/generated/naka_effects_seq.bin", 0x8AA, 0x3A
; [nakarest] naka_effects_seq+0x8e4  +0x8e4..+0xa98 (0xe28888, 436 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xe (table 0xe2e724, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x2, Label (32 B) x4, AccIll
; [nakarest] (32 B), Box (26 B) x2, IvSdacc (22 B), IvIntEasySet (24 B). 5 texts the records
; [nakarest] point at (Viewable slot 0xe (table 0xe2e724, 12 entries, InitializeKubo)):
; [nakarest] "ACOUSTIC ILLUSION" (TtlScreen.title of element 0); "TYPE" (Label.str of element
; [nakarest] 3); "LEVEL" (Label.str of element 4); "ILLUSION LEVEL:" (Label.str of element 8);
; [nakarest] ....
NakaWidget_KuboView00E_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x8E4, 0x3C
NakaWidget_KuboView00E_1_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x920, 0x2A
NakaWidget_KuboView00E_2_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x94A, 0x2A
NakaWidget_KuboView00E_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x974, 0x26
NakaWidget_KuboView00E_4_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x99A, 0x26
NakaWidget_KuboView00E_5_AccIll:	.incbin "includes/generated/naka_effects_seq.bin", 0x9C0, 0x20
NakaWidget_KuboView00E_6_Box:		.incbin "includes/generated/naka_effects_seq.bin", 0x9E0, 0x1A
NakaWidget_KuboView00E_7_Box:		.incbin "includes/generated/naka_effects_seq.bin", 0x9FA, 0x1A
NakaWidget_KuboView00E_8_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xA14, 0x30
NakaWidget_KuboView00E_9_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xA44, 0x26
NakaWidget_KuboView00E_10_IvSdacc:	.incbin "includes/generated/naka_effects_seq.bin", 0xA6A, 0x16
NakaWidget_KuboView00E_11_IvIntEasySet:	.incbin "includes/generated/naka_effects_seq.bin", 0xA80, 0x18
; [nakarest] naka_effects_seq+0xa98  +0xa98..+0xcb0 (0xe28a3c, 536 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x80 (table 0xe2e758, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcTitleMenu (54 B) x2, Label (32 B), AcModeMenu
; [nakarest] (54 B), IvExitMode (26 B), AcIndexEditSw (40 B) x2, Box (26 B), SngSel (36 B),
; [nakarest] AcLanguageText (42 B) x2. 5 texts the records point at (Viewable slot 0x80 (table
; [nakarest] 0xe2e758, 12 entries, InitializeKubo)): "SEQUENCER MENU" (TtlScreen.title of
; [nakarest] element 0); "CREATE" (AcTitleMenu.str of element 1); "SONG" (Label.str of element
; [nakarest] 2); "EDIT" (AcModeMenu.str of element 3); ....
NakaWidget_KuboView080_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0xA98, 0x3A
NakaWidget_KuboView080_1_AcTitleMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0xAD2, 0x3E
NakaWidget_KuboView080_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0xB10, 0x26
NakaWidget_KuboView080_3_AcModeMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0xB36, 0x3C
NakaWidget_KuboView080_4_IvExitMode:		.incbin "includes/generated/naka_effects_seq.bin", 0xB72, 0x1A
NakaWidget_KuboView080_5_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0xB8C, 0x28
NakaWidget_KuboView080_6_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0xBB4, 0x28
NakaWidget_KuboView080_7_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0xBDC, 0x1A
NakaWidget_KuboView080_8_SngSel:		.incbin "includes/generated/naka_effects_seq.bin", 0xBF6, 0x24
NakaWidget_KuboView080_9_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0xC1A, 0x2A
NakaWidget_KuboView080_10_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0xC44, 0x2A
NakaWidget_KuboView080_11_AcTitleMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0xC6E, 0x42
; [nakarest] naka_effects_seq+0xcb0  +0xcb0..+0x10dc (0xe28c54, 1068 B)
; [nakarest] widget records, elements 0-27 of Viewable slot 0x81 (table 0xe2e78c, 28 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x6, IvTrackSwitch (22 B),
; [nakarest] AcFuncToggle (44 B), Box (26 B) x2, SqplyVal (32 B), TrTransposeBox (36 B),
; [nakarest] TrChordBox (36 B), AcTempoBox (36 B), AcIndexEditSw (40 B) x4, AcFuncEditSw (44 B)
; [nakarest] x2, IvPlayExit (26 B), SngSel (36 B), Window (36 B) x2, AcTitleMenu (54 B),
; [nakarest] IvShowHide (26 B), SngSel2 (22 B). 10 texts the records point at (Viewable slot
; [nakarest] 0x81 (table 0xe2e78c, 28 entries, InitializeKubo)): "SEQUENCER PLAY"
; [nakarest] (TtlScreen.title of element 0); "MEAS" (Label.str of element 1); "CYCLE:OFF"
; [nakarest] (AcFuncToggle.stroff of element 3); "CYCLE:ON" (AcFuncToggle.stron of element 3);
; [nakarest] ....
NakaWidget_KuboView081_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0xCB0, 0x3A
NakaWidget_KuboView081_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0xCEA, 0x26
NakaWidget_KuboView081_2_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0xD10, 0x16
NakaWidget_CycPlySw:				.incbin "includes/generated/naka_effects_seq.bin", 0xD26, 0x40
NakaWidget_KuboView081_4_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0xD66, 0x1A
NakaWidget_SqPlayGamen:				.incbin "includes/generated/naka_effects_seq.bin", 0xD80, 0x20
NakaWidget_KuboView081_6_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0xDA0, 0x1A
NakaWidget_KuboView081_7_TrTransposeBox:	.incbin "includes/generated/naka_effects_seq.bin", 0xDBA, 0x24
NakaWidget_KuboView081_8_TrChordBox:		.incbin "includes/generated/naka_effects_seq.bin", 0xDDE, 0x24
NakaWidget_KuboView081_9_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0xE02, 0x2C
NakaWidget_KuboView081_10_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xE2E, 0x2C
NakaWidget_KuboView081_11_AcTempoBox:		.incbin "includes/generated/naka_effects_seq.bin", 0xE5A, 0x24
NakaWidget_KuboView081_12_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0xE7E, 0x28
NakaWidget_KuboView081_13_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0xEA6, 0x28
NakaWidget_KuboView081_14_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0xECE, 0x2C
NakaWidget_KuboView081_15_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xEFA, 0x26
NakaWidget_KuboView081_16_IvPlayExit:		.incbin "includes/generated/naka_effects_seq.bin", 0xF20, 0x1A
NakaWidget_PlySngSel:				.incbin "includes/generated/naka_effects_seq.bin", 0xF3A, 0x24
NakaWidget_SngSelWin1:				.incbin "includes/generated/naka_effects_seq.bin", 0xF5E, 0x24
NakaWidget_KuboView081_19_AcTitleMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0xF82, 0x3E
NakaWidget_KuboView081_20_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0xFC0, 0x2C
NakaWidget_KuboView081_21_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0xFEC, 0x26
NakaWidget_SngSelWin2:				.incbin "includes/generated/naka_effects_seq.bin", 0x1012, 0x24
NakaWidget_KuboView081_23_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x1036, 0x28
NakaWidget_KuboView081_24_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x105E, 0x28
NakaWidget_KuboView081_25_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1086, 0x26
NakaWidget_KuboView081_26_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x10AC, 0x1A
NakaWidget_KuboView081_27_SngSel2:		.incbin "includes/generated/naka_effects_seq.bin", 0x10C6, 0x16
; [nakarest] naka_effects_seq+0x10dc  +0x10dc..+0x127e (0xe29080, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x82 (table 0xe2e800, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqplyVal (32 B), PsEditBox (50 B) x3, Label (32
; [nakarest] B) x2, AcIndexWideES (42 B). 6 texts the records point at (Viewable slot 0x82
; [nakarest] (table 0xe2e800, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CYCLE START MEASURE :" (PsEditBox.caption of element 2); "CURRENT
; [nakarest] MEASURE :" (Label.str of element 3); "CYCLE :" (PsEditBox.caption of element 4);
; [nakarest] ....
NakaWidget_KuboView082_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x10DC, 0x36
NakaWidget_KuboView082_1_SqplyVal:	.incbin "includes/generated/naka_effects_seq.bin", 0x1112, 0x20
NakaWidget_KuboView082_2_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x1132, 0x48
NakaWidget_KuboView082_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x117A, 0x32
NakaWidget_KuboView082_4_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x11AC, 0x3A
NakaWidget_KuboView082_5_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x11E6, 0x48
NakaWidget_KuboView082_6_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x122E, 0x2A
NakaWidget_KuboView082_7_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1258, 0x26
; [nakarest] naka_effects_seq+0x127e  +0x127e..+0x14f4 (0xe29222, 630 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x83 (table 0xe2e824, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvExitMode (26 B), AcTitleMenu (54
; [nakarest] B), Box (26 B), AcIndexEditSw (40 B) x2, SngSel (36 B), AcFuncEditSw (44 B),
; [nakarest] PsTrackSwitch (36 B) x5, AcLanguageText (42 B) x2. 3 texts the records point at
; [nakarest] (Viewable slot 0x83 (table 0xe2e824, 16 entries, InitializeKubo)): "EASY RECORD"
; [nakarest] (TtlScreen.title of element 0); "SONG" (Label.str of element 1); "NAMING"
; [nakarest] (AcTitleMenu.str of element 3).
NakaWidget_KuboView083_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x127E, 0x36
NakaWidget_KuboView083_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x12B4, 0x26
NakaWidget_KuboView083_2_IvExitMode:		.incbin "includes/generated/naka_effects_seq.bin", 0x12DA, 0x1A
NakaWidget_KuboView083_3_AcTitleMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x12F4, 0x3E
NakaWidget_KuboView083_4_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x1332, 0x1A
NakaWidget_KuboView083_5_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x134C, 0x28
NakaWidget_KuboView083_6_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x1374, 0x28
NakaWidget_KuboView083_7_SngSel:		.incbin "includes/generated/naka_effects_seq.bin", 0x139C, 0x24
NakaWidget_KuboView083_8_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x13C0, 0x2C
NakaWidget_KuboView083_9_PsTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x13EC, 0x24
NakaWidget_KuboView083_10_PsTrackSwitch:	.incbin "includes/generated/naka_effects_seq.bin", 0x1410, 0x24
NakaWidget_KuboView083_11_PsTrackSwitch:	.incbin "includes/generated/naka_effects_seq.bin", 0x1434, 0x24
NakaWidget_KuboView083_12_PsTrackSwitch:	.incbin "includes/generated/naka_effects_seq.bin", 0x1458, 0x24
NakaWidget_KuboView083_13_PsTrackSwitch:	.incbin "includes/generated/naka_effects_seq.bin", 0x147C, 0x24
NakaWidget_KuboView083_14_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x14A0, 0x2A
NakaWidget_KuboView083_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x14CA, 0x2A
; [nakarest] naka_effects_seq+0x14f4  +0x14f4..+0x1790 (0xe29498, 668 B)
; [nakarest] widget records, elements 0-9 of Viewable slot 0x84 (table 0xe2e868, 10 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcTitleMenu (54 B) x7, AcModeMenu (54 B) x2. 10
; [nakarest] texts the records point at (Viewable slot 0x84 (table 0xe2e868, 10 entries,
; [nakarest] InitializeKubo)): "CREATE" (TtlScreen.title of element 0); "TRACK ASSIGN"
; [nakarest] (AcTitleMenu.str of element 1); "PANEL WRITE" (AcTitleMenu.str of element 2); "SONG
; [nakarest] SELECT /NAMING" (AcTitleMenu.str of element 3); ....
NakaWidget_KuboView084_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x14F4, 0x32
NakaWidget_KuboView084_1_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x1526, 0x44
NakaWidget_KuboView084_2_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x156A, 0x42
NakaWidget_KuboView084_3_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x15AC, 0x4A
NakaWidget_KuboView084_4_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x15F6, 0x42
NakaWidget_KuboView084_5_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x1638, 0x46
NakaWidget_KuboView084_6_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x167E, 0x46
NakaWidget_KuboView084_7_AcModeMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x16C4, 0x46
NakaWidget_KuboView084_8_AcModeMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x170A, 0x42
NakaWidget_KuboView084_9_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x174C, 0x44
; [nakarest] naka_effects_seq+0x1790  +0x1790..+0x1b1e (0xe29734, 910 B)
; [nakarest] widget records, elements 0-18, 21-24 of Viewable slot 0x85 (table 0xe2e894, 25
; [nakarest] entries, InitializeKubo): TtlScreen (42 B), IvTrackSwitch (22 B), AcFuncEditSw (44
; [nakarest] B) x3, Label (32 B) x7, AcFuncToggle (44 B) x2, Box (26 B) x2, SqplyVal (32 B),
; [nakarest] AcTempoBox (36 B), TrTransposeBox (36 B), TrChordBox (36 B), SngSel (36 B),
; [nakarest] IvRealRecExit (22 B), Window (36 B). 12 texts the records point at (Viewable slot
; [nakarest] 0x85 (table 0xe2e894, 25 entries, InitializeKubo)): "REALTIME RECORD"
; [nakarest] (TtlScreen.title of element 0); "REC STOP" (Label.str of element 3); "CYCLE:OFF"
; [nakarest] (AcFuncToggle.stroff of element 4); "CYCLE:ON" (AcFuncToggle.stron of element 4);
; [nakarest] ....
NakaWidget_KuboView085_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x1790, 0x3A
NakaWidget_KuboView085_1_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x17CA, 0x16
NakaWidget_KuboView085_2_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x17E0, 0x2C
NakaWidget_KuboView085_3_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x180C, 0x2A
NakaWidget_CycRecSw:				.incbin "includes/generated/naka_effects_seq.bin", 0x1836, 0x40
NakaWidget_KuboView085_5_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x1876, 0x1A
NakaWidget_MetRecSw:				.incbin "includes/generated/naka_effects_seq.bin", 0x1890, 0x3A
NakaWidget_SqRealRecGamen:			.incbin "includes/generated/naka_effects_seq.bin", 0x18CA, 0x20
NakaWidget_KuboView085_8_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x18EA, 0x1A
NakaWidget_KuboView085_9_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x1904, 0x2C
NakaWidget_KuboView085_10_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1930, 0x2C
NakaWidget_KuboView085_11_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x195C, 0x2C
NakaWidget_KuboView085_12_AcTempoBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x1988, 0x24
NakaWidget_KuboView085_13_TrTransposeBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x19AC, 0x24
NakaWidget_KuboView085_14_TrChordBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x19D0, 0x24
NakaWidget_KuboView085_15_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x19F4, 0x22
NakaWidget_KuboView085_16_SngSel:		.incbin "includes/generated/naka_effects_seq.bin", 0x1A16, 0x24
NakaWidget_KuboView085_17_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x1A3A, 0x2C
NakaWidget_KuboView085_18_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1A66, 0x2C
NakaWidget_KuboView085_21_IvRealRecExit:	.incbin "includes/generated/naka_effects_seq.bin", 0x1A92, 0x16
NakaWidget_CycClrSw:				.incbin "includes/generated/naka_effects_seq.bin", 0x1AA8, 0x24
NakaWidget_KuboView085_23_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x1ACC, 0x2C
NakaWidget_KuboView085_24_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1AF8, 0x26
; [nakarest] naka_effects_seq+0x1b1e  +0x1b1e..+0x1d50 (0xe29ac2, 562 B)
; [nakarest] widget records, elements 0-10 of Viewable slot 0x86 (table 0xe2e8fc, 11 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqplyVal (32 B), PsEditBox (50 B) x3, Label (32
; [nakarest] B) x3, AcIndexWideES (42 B), AcFuncToggle (44 B), AcFuncEditSw (44 B). 9 texts the
; [nakarest] records point at (Viewable slot 0x86 (table 0xe2e8fc, 11 entries, InitializeKubo)):
; [nakarest] "REALTIME RECORD" (TtlScreen.title of element 0); "CYCLE START MEASURE :"
; [nakarest] (PsEditBox.caption of element 2); "CURRENT MEASURE :" (Label.str of element 3);
; [nakarest] "CYCLE END MEASURE :" (PsEditBox.caption of element 4); ....
NakaWidget_KuboView086_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x1B1E, 0x3A
NakaWidget_KuboView086_1_SqplyVal:	.incbin "includes/generated/naka_effects_seq.bin", 0x1B58, 0x20
NakaWidget_KuboView086_2_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x1B78, 0x48
NakaWidget_KuboView086_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1BC0, 0x32
NakaWidget_KuboView086_4_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x1BF2, 0x48
NakaWidget_KuboView086_5_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x1C3A, 0x2A
NakaWidget_KuboView086_6_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1C64, 0x26
NakaWidget_MetCycRecSw:			.incbin "includes/generated/naka_effects_seq.bin", 0x1C8A, 0x3A
NakaWidget_KuboView086_8_AcFuncEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x1CC4, 0x2C
NakaWidget_KuboView086_9_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1CF0, 0x26
NakaWidget_KuboView086_10_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x1D16, 0x3A
; [nakarest] naka_effects_seq+0x1d50  +0x1d50..+0x20f8 (0xe29cf4, 936 B)
; [nakarest] widget records, elements 0-23 of Viewable slot 0x87 (table 0xe2e92c, 24 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvTrackSwitch (22 B), Box (26 B) x2, SqplyVal
; [nakarest] (32 B), Label (32 B) x8, AcTempoBox (36 B), TrTransposeBox (36 B), TrChordBox (36
; [nakarest] B), SngSel (36 B), AcFuncToggle (44 B) x2, AcIndexEditSw (40 B) x2, AcFuncEditSw
; [nakarest] (44 B) x2, IvPunchExit (22 B). 13 texts the records point at (Viewable slot 0x87
; [nakarest] (table 0xe2e92c, 24 entries, InitializeKubo)): "PUNCH RECORD" (TtlScreen.title of
; [nakarest] element 0); "MEASURE =" (Label.str of element 5); "TIME SIG. =" (Label.str of
; [nakarest] element 6); "MEMORY =" (Label.str of element 7); ....
NakaWidget_KuboView087_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x1D50, 0x38
NakaWidget_KuboView087_1_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x1D88, 0x16
NakaWidget_KuboView087_2_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x1D9E, 0x1A
NakaWidget_SqPunchGamen:			.incbin "includes/generated/naka_effects_seq.bin", 0x1DB8, 0x20
NakaWidget_KuboView087_4_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x1DD8, 0x1A
NakaWidget_KuboView087_5_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x1DF2, 0x2C
NakaWidget_KuboView087_6_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x1E1E, 0x2C
NakaWidget_KuboView087_7_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x1E4A, 0x2C
NakaWidget_KuboView087_8_AcTempoBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x1E76, 0x24
NakaWidget_KuboView087_9_TrTransposeBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x1E9A, 0x24
NakaWidget_KuboView087_10_TrChordBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x1EBE, 0x24
NakaWidget_KuboView087_11_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1EE2, 0x22
NakaWidget_KuboView087_12_SngSel:		.incbin "includes/generated/naka_effects_seq.bin", 0x1F04, 0x24
NakaWidget_MetPunchSw:				.incbin "includes/generated/naka_effects_seq.bin", 0x1F28, 0x3A
NakaWidget_PunchInOutSw:			.incbin "includes/generated/naka_effects_seq.bin", 0x1F62, 0x40
NakaWidget_KuboView087_15_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x1FA2, 0x26
NakaWidget_KuboView087_16_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x1FC8, 0x28
NakaWidget_KuboView087_17_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x1FF0, 0x28
NakaWidget_KuboView087_18_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2018, 0x2C
NakaWidget_KuboView087_19_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x2044, 0x26
NakaWidget_KuboView087_20_IvPunchExit:		.incbin "includes/generated/naka_effects_seq.bin", 0x206A, 0x16
NakaWidget_KuboView087_21_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2080, 0x2C
NakaWidget_KuboView087_22_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x20AC, 0x26
NakaWidget_KuboView087_23_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x20D2, 0x26
; [nakarest] naka_effects_seq+0x20f8  +0x20f8..+0x235e (0xe2a09c, 614 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x88 (table 0xe2e990, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B) x2, AcIndexWideES (42 B), Label (32 B) x2,
; [nakarest] AcFuncToggle (44 B), SqplyVal (32 B), PsEditBox (50 B) x3, AcLanguageText (42 B),
; [nakarest] IvAutoPunchExit (22 B). 9 texts the records point at (Viewable slot 0x88 (table
; [nakarest] 0xe2e990, 12 entries, InitializeKubo)): "AUTO PUNCH RECORD" (TtlScreen.title of
; [nakarest] element 0); "MEAS" (Label.str of element 2); "CURRENT MEASURE :" (Label.str of
; [nakarest] element 3); "~a4OFF" (AcFuncToggle.stroff of element 4); ....
NakaWidget_KuboView088_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x20F8, 0x3C
NakaWidget_KuboView088_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x2134, 0x2A
NakaWidget_KuboView088_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x215E, 0x26
NakaWidget_KuboView088_3_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x2184, 0x32
NakaWidget_MetPunchmSw:				.incbin "includes/generated/naka_effects_seq.bin", 0x21B6, 0x3A
NakaWidget_KuboView088_5_SqplyVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x21F0, 0x20
NakaWidget_KuboView088_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x2210, 0x46
NakaWidget_KuboView088_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x2256, 0x46
NakaWidget_KuboView088_8_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x229C, 0x46
NakaWidget_KuboView088_9_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x22E2, 0x2A
NakaWidget_KuboView088_10_IvAutoPunchExit:	.incbin "includes/generated/naka_effects_seq.bin", 0x230C, 0x16
NakaWidget_KuboView088_11_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x2322, 0x3C
; [nakarest] naka_effects_seq+0x235e  +0x235e..+0x2400 (0xe2a302, 162 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x8d (table 0xe2e9c4, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcFuncEditSw (44 B), AcLanguageText (42 B),
; [nakarest] IvPnlWrExit (22 B). 1 text the records point at (Viewable slot 0x8d (table
; [nakarest] 0xe2e9c4, 4 entries, InitializeKubo)): "PANEL WRITE" (TtlScreen.title of element
; [nakarest] 0).
NakaWidget_KuboView08D_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x235E, 0x36
NakaWidget_KuboView08D_1_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2394, 0x2C
NakaWidget_KuboView08D_2_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x23C0, 0x2A
NakaWidget_KuboView08D_3_IvPnlWrExit:		.incbin "includes/generated/naka_effects_seq.bin", 0x23EA, 0x16
; [nakarest] naka_effects_seq+0x2400  +0x2400..+0x2686 (0xe2a3a4, 646 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0x90 (table 0xe2e9d8, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B) x3, SqedtVal3
; [nakarest] (30 B), Box (26 B) x2, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), AcLanguageText (42 B) x3. 5 texts the
; [nakarest] records point at (Viewable slot 0x90 (table 0xe2e9d8, 17 entries, InitializeKubo)):
; [nakarest] "SONG CLEAR" (TtlScreen.title of element 0); "SONG NO/ALL" (Label.str of element
; [nakarest] 2); ":" (Label.str of element 5); "%" (Label.str of element 6); ....
NakaWidget_KuboView090_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x2400, 0x36
NakaWidget_KuboView090_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x2436, 0x2A
NakaWidget_KuboView090_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x2460, 0x2C
NakaWidget_KuboView090_3_SqedtVal3:		.incbin "includes/generated/naka_effects_seq.bin", 0x248C, 0x1E
NakaWidget_KuboView090_4_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x24AA, 0x1A
NakaWidget_KuboView090_5_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x24C4, 0x22
NakaWidget_KuboView090_6_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x24E6, 0x22
NakaWidget_KuboView090_7_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x2508, 0x16
NakaWidget_KuboView090_8_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x251E, 0x2C
NakaWidget_SoclSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x254A, 0x24
NakaWidget_KuboView090_10_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x256E, 0x1A
NakaWidget_KuboView090_11_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x2588, 0x3A
NakaWidget_KuboView090_12_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x25C2, 0x2C
NakaWidget_KuboView090_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x25EE, 0x1A
NakaWidget_KuboView090_14_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x2608, 0x2A
NakaWidget_KuboView090_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x2632, 0x2A
NakaWidget_KuboView090_16_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x265C, 0x2A
; [nakarest] naka_effects_seq+0x2686  +0x2686..+0x292c (0xe2a62a, 678 B)
; [nakarest] widget records, elements 0-18 of Viewable slot 0x91 (table 0xe2ea20, 19 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqedtVal2 (30 B), SqedtFix (28 B), AcIndexWideES
; [nakarest] (42 B) x4, IvSongCopyExit (22 B) x2, MsgToTtl (22 B), AcFuncEditSw (44 B) x2,
; [nakarest] Window (36 B), Box (26 B) x3, AcScreenMenu (54 B), IvExitScreen (26 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x91 (table
; [nakarest] 0xe2ea20, 19 entries, InitializeKubo)): "SONG/TRACK COPY" (TtlScreen.title of
; [nakarest] element 0); "NO" (AcScreenMenu.str of element 15).
NakaWidget_KuboView091_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x2686, 0x3A
NakaWidget_KuboView091_1_SqedtVal2:		.incbin "includes/generated/naka_effects_seq.bin", 0x26C0, 0x1E
NakaWidget_KuboView091_2_SqedtFix:		.incbin "includes/generated/naka_effects_seq.bin", 0x26DE, 0x1C
NakaWidget_KuboView091_3_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x26FA, 0x2A
NakaWidget_KuboView091_4_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x2724, 0x2A
NakaWidget_KuboView091_5_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x274E, 0x2A
NakaWidget_KuboView091_6_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x2778, 0x2A
NakaWidget_KuboView091_7_IvSongCopyExit:	.incbin "includes/generated/naka_effects_seq.bin", 0x27A2, 0x16
NakaWidget_KuboView091_8_IvSongCopyExit:	.incbin "includes/generated/naka_effects_seq.bin", 0x27B8, 0x16
NakaWidget_KuboView091_9_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x27CE, 0x16
NakaWidget_KuboView091_10_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x27E4, 0x2C
NakaWidget_SngCpSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x2810, 0x24
NakaWidget_KuboView091_12_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x2834, 0x1A
NakaWidget_KuboView091_13_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x284E, 0x1A
NakaWidget_KuboView091_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x2868, 0x1A
NakaWidget_KuboView091_15_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x2882, 0x3A
NakaWidget_KuboView091_16_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x28BC, 0x1A
NakaWidget_KuboView091_17_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x28D6, 0x2C
NakaWidget_KuboView091_18_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x2902, 0x2A
; [nakarest] naka_effects_seq+0x292c  +0x292c..+0x2e34 (0xe2a8d0, 1288 B)
; [nakarest] widget records, elements 0-25 of Viewable slot 0x93 (table 0xe2ea70, 26 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvPageControl (28 B) x2, AcWindowPage (36 B),
; [nakarest] IvExitMode (26 B), IvShowHide (26 B), Window (36 B) x2, AcTitleMenu (54 B) x14,
; [nakarest] Line (26 B) x3, Label (32 B). 16 texts the records point at (Viewable slot 0x93
; [nakarest] (table 0xe2ea70, 26 entries, InitializeKubo)): "EDIT" (TtlScreen.title of element
; [nakarest] 0); "NOTE EDIT" (AcTitleMenu.str of element 7); "DRUM EDIT" (AcTitleMenu.str of
; [nakarest] element 8); "SONG/TRACK COPY" (AcTitleMenu.str of element 9); ....
NakaWidget_KuboView093_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x292C, 0x30
NakaWidget_KuboView093_1_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x295C, 0x1C
NakaWidget_EdMenuPage:			.incbin "includes/generated/naka_effects_seq.bin", 0x2978, 0x24
NakaWidget_KuboView093_3_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x299C, 0x1C
NakaWidget_KuboView093_4_IvExitMode:	.incbin "includes/generated/naka_effects_seq.bin", 0x29B8, 0x1A
NakaWidget_KuboView093_5_IvShowHide:	.incbin "includes/generated/naka_effects_seq.bin", 0x29D2, 0x1A
NakaWidget_SQEMENU_1:			.incbin "includes/generated/naka_effects_seq.bin", 0x29EC, 0x24
NakaWidget_KuboView093_7_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2A10, 0x40
NakaWidget_KuboView093_8_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2A50, 0x40
NakaWidget_KuboView093_9_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2A90, 0x46
NakaWidget_KuboView093_10_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2AD6, 0x42
NakaWidget_KuboView093_11_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2B18, 0x42
NakaWidget_KuboView093_12_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2B5A, 0x40
NakaWidget_KuboView093_13_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2B9A, 0x40
NakaWidget_KuboView093_14_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2BDA, 0x46
NakaWidget_KuboView093_15_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2C20, 0x42
NakaWidget_KuboView093_16_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2C62, 0x44
NakaWidget_SQEMENU_2:			.incbin "includes/generated/naka_effects_seq.bin", 0x2CA6, 0x24
NakaWidget_KuboView093_18_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2CCA, 0x3C
NakaWidget_KuboView093_19_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x2D06, 0x1A
NakaWidget_KuboView093_20_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2D20, 0x3C
NakaWidget_KuboView093_21_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2D5C, 0x3E
NakaWidget_KuboView093_22_AcTitleMenu:	.incbin "includes/generated/naka_effects_seq.bin", 0x2D9A, 0x3E
NakaWidget_KuboView093_23_Label:	.incbin "includes/generated/naka_effects_seq.bin", 0x2DD8, 0x28
NakaWidget_KuboView093_24_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x2E00, 0x1A
NakaWidget_KuboView093_25_Line:		.incbin "includes/generated/naka_effects_seq.bin", 0x2E1A, 0x1A
; [nakarest] naka_effects_seq+0x2e34  +0x2e34..+0x2ed8 (0xe2add8, 164 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x94 (table 0xe2eadc, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvTrackSwitch (22 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x94 (table
; [nakarest] 0xe2eadc, 4 entries, InitializeKubo)): "NOTE EDIT " (TtlScreen.title of element 0);
; [nakarest] ":PART SELECT" (Label.str of element 1).
NakaWidget_KuboView094_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x2E34, 0x36
NakaWidget_KuboView094_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x2E6A, 0x2E
NakaWidget_KuboView094_2_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x2E98, 0x16
NakaWidget_KuboView094_3_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x2EAE, 0x2A
; [nakarest] naka_effects_seq+0x2ed8  +0x2ed8..+0x32ce (0xe2ae7c, 1014 B)
; [nakarest] widget records, elements 0-26 of Viewable slot 0x95 (table 0xe2eaf0, 27 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x12, Label (32 B) x10,
; [nakarest] NoteEditBox (32 B), Box (26 B), VwUserBitmap (26 B) x2. 11 texts the records point
; [nakarest] at (Viewable slot 0x95 (table 0xe2eaf0, 27 entries, InitializeKubo)): "NOTE EDIT"
; [nakarest] (TtlScreen.title of element 0); "MEAS" (Label.str of element 7); "POS" (Label.str
; [nakarest] of element 8); "NOTE" (Label.str of element 9); ....
NakaWidget_KuboView095_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x2ED8, 0x34
NakaWidget_KuboView095_1_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2F0C, 0x28
NakaWidget_KuboView095_2_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2F34, 0x28
NakaWidget_KuboView095_3_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2F5C, 0x28
NakaWidget_KuboView095_4_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2F84, 0x28
NakaWidget_KuboView095_5_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2FAC, 0x28
NakaWidget_KuboView095_6_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x2FD4, 0x28
NakaWidget_KuboView095_7_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x2FFC, 0x26
NakaWidget_KuboView095_8_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x3022, 0x24
NakaWidget_KuboView095_9_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x3046, 0x26
NakaWidget_KuboView095_10_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x306C, 0x24
NakaWidget_KuboView095_11_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3090, 0x24
NakaWidget_KuboView095_12_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x30B4, 0x24
NakaWidget_KuboView095_13_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x30D8, 0x28
NakaWidget_KuboView095_14_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3100, 0x28
NakaWidget_KuboView095_15_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3128, 0x28
NakaWidget_KuboView095_16_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3150, 0x26
NakaWidget_KuboView095_17_NoteEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x3176, 0x20
NakaWidget_KuboView095_18_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x3196, 0x1A
NakaWidget_KuboView095_19_VwUserBitmap:		.incbin "includes/generated/naka_effects_seq.bin", 0x31B0, 0x1A
NakaWidget_NTBitmap:				.incbin "includes/generated/naka_effects_seq.bin", 0x31CA, 0x1A
NakaWidget_KuboView095_21_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x31E4, 0x28
NakaWidget_KuboView095_22_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x320C, 0x24
NakaWidget_KuboView095_23_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3230, 0x28
NakaWidget_KuboView095_24_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3258, 0x26
NakaWidget_KuboView095_25_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x327E, 0x28
NakaWidget_KuboView095_26_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x32A6, 0x28
; [nakarest] naka_effects_seq+0x32ce  +0x32ce..+0x3470 (0xe2b272, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x96 (table 0xe2eb60, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x2, AcIndexWideES (42 B), SqplyVal
; [nakarest] (32 B), PsEditBox (50 B) x3. 6 texts the records point at (Viewable slot 0x96
; [nakarest] (table 0xe2eb60, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CURRENT MEASURE :" (Label.str of element 1); "VALUE" (Label.str of
; [nakarest] element 3); "SOLO :" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView096_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x32CE, 0x36
NakaWidget_KuboView096_1_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3304, 0x32
NakaWidget_KuboView096_2_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x3336, 0x2A
NakaWidget_KuboView096_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3360, 0x26
NakaWidget_KuboView096_4_SqplyVal:	.incbin "includes/generated/naka_effects_seq.bin", 0x3386, 0x20
NakaWidget_KuboView096_5_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x33A6, 0x3A
NakaWidget_KuboView096_6_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x33E0, 0x48
NakaWidget_KuboView096_7_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x3428, 0x48
; [nakarest] naka_effects_seq+0x3470  +0x3470..+0x3514 (0xe2b414, 164 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x97 (table 0xe2eb84, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvTrackSwitch (22 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x97 (table
; [nakarest] 0xe2eb84, 4 entries, InitializeKubo)): "DRUM EDIT " (TtlScreen.title of element 0);
; [nakarest] ":PART SELECT" (Label.str of element 1).
NakaWidget_KuboView097_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3470, 0x36
NakaWidget_KuboView097_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x34A6, 0x2E
NakaWidget_KuboView097_2_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x34D4, 0x16
NakaWidget_KuboView097_3_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x34EA, 0x2A
; [nakarest] naka_effects_seq+0x3514  +0x3514..+0x38e2 (0xe2b4b8, 974 B)
; [nakarest] widget records, elements 0-25 of Viewable slot 0x98 (table 0xe2eb98, 26 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x11, Label (32 B) x10, Box
; [nakarest] (26 B), NoteEditBox (32 B), VwUserBitmap (26 B) x2. 11 texts the records point at
; [nakarest] (Viewable slot 0x98 (table 0xe2eb98, 26 entries, InitializeKubo)): "DRUM EDIT"
; [nakarest] (TtlScreen.title of element 0); "MEAS" (Label.str of element 7); "POS" (Label.str
; [nakarest] of element 8); "SND" (Label.str of element 9); ....
NakaWidget_KuboView098_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3514, 0x34
NakaWidget_KuboView098_1_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3548, 0x28
NakaWidget_KuboView098_2_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3570, 0x28
NakaWidget_KuboView098_3_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3598, 0x28
NakaWidget_KuboView098_4_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x35C0, 0x28
NakaWidget_KuboView098_5_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x35E8, 0x28
NakaWidget_KuboView098_6_AcIndexEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3610, 0x28
NakaWidget_KuboView098_7_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x3638, 0x26
NakaWidget_KuboView098_8_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x365E, 0x24
NakaWidget_KuboView098_9_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x3682, 0x24
NakaWidget_KuboView098_10_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x36A6, 0x24
NakaWidget_KuboView098_11_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x36CA, 0x24
NakaWidget_KuboView098_12_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x36EE, 0x28
NakaWidget_KuboView098_13_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3716, 0x26
NakaWidget_KuboView098_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x373C, 0x1A
NakaWidget_KuboView098_15_NoteEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x3756, 0x20
NakaWidget_KuboView098_16_VwUserBitmap:		.incbin "includes/generated/naka_effects_seq.bin", 0x3776, 0x1A
NakaWidget_DRBitmap:				.incbin "includes/generated/naka_effects_seq.bin", 0x3790, 0x1A
NakaWidget_KuboView098_18_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x37AA, 0x28
NakaWidget_KuboView098_19_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x37D2, 0x26
NakaWidget_KuboView098_20_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x37F8, 0x28
NakaWidget_KuboView098_21_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3820, 0x24
NakaWidget_KuboView098_22_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3844, 0x28
NakaWidget_KuboView098_23_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x386C, 0x26
NakaWidget_KuboView098_24_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x3892, 0x28
NakaWidget_KuboView098_25_AcIndexEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x38BA, 0x28
; [nakarest] naka_effects_seq+0x38e2  +0x38e2..+0x3a84 (0xe2b886, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x99 (table 0xe2ec04, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x2, AcIndexWideES (42 B), SqplyVal
; [nakarest] (32 B), PsEditBox (50 B) x3. 6 texts the records point at (Viewable slot 0x99
; [nakarest] (table 0xe2ec04, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CURRENT MEASURE :" (Label.str of element 1); "VALUE" (Label.str of
; [nakarest] element 3); "SOLO :" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView099_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x38E2, 0x36
NakaWidget_KuboView099_1_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3918, 0x32
NakaWidget_KuboView099_2_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x394A, 0x2A
NakaWidget_KuboView099_3_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x3974, 0x26
NakaWidget_KuboView099_4_SqplyVal:	.incbin "includes/generated/naka_effects_seq.bin", 0x399A, 0x20
NakaWidget_KuboView099_5_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x39BA, 0x3A
NakaWidget_KuboView099_6_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x39F4, 0x48
NakaWidget_KuboView099_7_PsEditBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x3A3C, 0x48
; [nakarest] naka_effects_seq+0x3a84  +0x3a84..+0x3ca4 (0xe2ba28, 544 B)
; [nakarest] widget records, elements 0-13 of Viewable slot 0x9a (table 0xe2ec28, 14 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvTrackSwitch (22 B), MsgToTtl (22 B),
; [nakarest] AcLanguageText (42 B) x5, AcFuncEditSw (44 B) x2, Window (36 B), AcScreenMenu (54
; [nakarest] B), VwBox (28 B), IvExitScreen (26 B). 2 texts the records point at (Viewable slot
; [nakarest] 0x9a (table 0xe2ec28, 14 entries, InitializeKubo)): "TRACK CLEAR" (TtlScreen.title
; [nakarest] of element 0); "NO" (AcScreenMenu.str of element 8).
NakaWidget_KuboView09A_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3A84, 0x36
NakaWidget_KuboView09A_1_IvTrackSwitch:		.incbin "includes/generated/naka_effects_seq.bin", 0x3ABA, 0x16
NakaWidget_KuboView09A_2_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x3AD0, 0x16
NakaWidget_KuboView09A_3_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3AE6, 0x2A
NakaWidget_KuboView09A_4_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3B10, 0x2A
NakaWidget_KuboView09A_5_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3B3A, 0x2C
NakaWidget_TrkClrSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x3B66, 0x24
NakaWidget_KuboView09A_7_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3B8A, 0x2C
NakaWidget_KuboView09A_8_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x3BB6, 0x3A
NakaWidget_KuboView09A_9_VwBox:			.incbin "includes/generated/naka_effects_seq.bin", 0x3BF0, 0x1C
NakaWidget_KuboView09A_10_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3C0C, 0x1A
NakaWidget_KuboView09A_11_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3C26, 0x2A
NakaWidget_KuboView09A_12_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3C50, 0x2A
NakaWidget_KuboView09A_13_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3C7A, 0x2A
; [nakarest] naka_effects_seq+0x3ca4  +0x3ca4..+0x3fd8 (0xe2bc48, 820 B)
; [nakarest] widget records, elements 0-21 of Viewable slot 0x9b (table 0xe2ec64, 22 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Line (26 B) x6, AcIndexWideES (42 B), Label (32
; [nakarest] B), SqedtVal (32 B), PsEditBox (50 B) x3, MsgToTtl (22 B), AcFuncEditSw (44 B) x2,
; [nakarest] Window (36 B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2,
; [nakarest] AcLanguageText (42 B). 6 texts the records point at (Viewable slot 0x9b (table
; [nakarest] 0xe2ec64, 22 entries, InitializeKubo)): "TRACK MERGE" (TtlScreen.title of element
; [nakarest] 0); "VALUE" (Label.str of element 8); "TRACK :" (PsEditBox.caption of element 10);
; [nakarest] "TRACK :" (PsEditBox.caption of element 11); ....
NakaWidget_KuboView09B_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3CA4, 0x36
NakaWidget_KuboView09B_1_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3CDA, 0x1A
NakaWidget_KuboView09B_2_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3CF4, 0x1A
NakaWidget_KuboView09B_3_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3D0E, 0x1A
NakaWidget_KuboView09B_4_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3D28, 0x1A
NakaWidget_KuboView09B_5_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3D42, 0x1A
NakaWidget_KuboView09B_6_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x3D5C, 0x1A
NakaWidget_KuboView09B_7_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x3D76, 0x2A
NakaWidget_KuboView09B_8_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x3DA0, 0x26
NakaWidget_KuboView09B_9_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x3DC6, 0x20
NakaWidget_KuboView09B_10_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x3DE6, 0x3A
NakaWidget_KuboView09B_11_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x3E20, 0x3A
NakaWidget_KuboView09B_12_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x3E5A, 0x3A
NakaWidget_KuboView09B_13_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x3E94, 0x16
NakaWidget_KuboView09B_14_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3EAA, 0x2C
NakaWidget_TrkMrgSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x3ED6, 0x24
NakaWidget_KuboView09B_16_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x3EFA, 0x2C
NakaWidget_KuboView09B_17_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x3F26, 0x3A
NakaWidget_KuboView09B_18_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3F60, 0x1A
NakaWidget_KuboView09B_19_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x3F7A, 0x1A
NakaWidget_KuboView09B_20_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x3F94, 0x1A
NakaWidget_KuboView09B_21_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x3FAE, 0x2A
; [nakarest] naka_effects_seq+0x3fd8  +0x3fd8..+0x4384 (0xe2bf7c, 940 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x9c (table 0xe2ecc0, 21 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x3, AcIndexWideES (42 B), SqedtVal
; [nakarest] (32 B), PsEditBox (50 B) x6, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36
; [nakarest] B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2, AcLanguageText (42 B).
; [nakarest] 11 texts the records point at (Viewable slot 0x9c (table 0xe2ecc0, 21 entries,
; [nakarest] InitializeKubo)): "QUANTIZE" (TtlScreen.title of element 0); "VALUE" (Label.str of
; [nakarest] element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "WINDOW :"
; [nakarest] (PsEditBox.caption of element 5); ....
NakaWidget_KuboView09C_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x3FD8, 0x34
NakaWidget_KuboView09C_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x400C, 0x26
NakaWidget_KuboView09C_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x4032, 0x2A
NakaWidget_KuboView09C_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x405C, 0x20
NakaWidget_KuboView09C_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x407C, 0x42
NakaWidget_KuboView09C_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x40BE, 0x3C
NakaWidget_KuboView09C_6_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x40FA, 0x22
NakaWidget_KuboView09C_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x411C, 0x42
NakaWidget_KuboView09C_8_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x415E, 0x42
NakaWidget_KuboView09C_9_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x41A0, 0x42
NakaWidget_KuboView09C_10_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x41E2, 0x3C
NakaWidget_KuboView09C_11_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x421E, 0x22
NakaWidget_KuboView09C_12_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x4240, 0x16
NakaWidget_KuboView09C_13_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4256, 0x2C
NakaWidget_QtzSureDisp:				.incbin "includes/generated/naka_effects_seq.bin", 0x4282, 0x24
NakaWidget_KuboView09C_15_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x42A6, 0x3A
NakaWidget_KuboView09C_16_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x42E0, 0x2C
NakaWidget_KuboView09C_17_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x430C, 0x1A
NakaWidget_KuboView09C_18_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4326, 0x1A
NakaWidget_KuboView09C_19_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4340, 0x1A
NakaWidget_KuboView09C_20_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x435A, 0x2A
; [nakarest] naka_effects_seq+0x4384  +0x4384..+0x4658 (0xe2c328, 724 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x9d (table 0xe2ed18, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0x9d (table 0xe2ed18, 16 entries,
; [nakarest] InitializeKubo)): "TRANSPOSE" (TtlScreen.title of element 0); "VALUE" (Label.str of
; [nakarest] element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "TRACK :"
; [nakarest] (PsEditBox.caption of element 5); ....
NakaWidget_KuboView09D_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4384, 0x34
NakaWidget_KuboView09D_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x43B8, 0x26
NakaWidget_KuboView09D_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x43DE, 0x2A
NakaWidget_KuboView09D_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x4408, 0x20
NakaWidget_KuboView09D_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4428, 0x42
NakaWidget_KuboView09D_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x446A, 0x42
NakaWidget_KuboView09D_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x44AC, 0x42
NakaWidget_KuboView09D_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x44EE, 0x40
NakaWidget_KuboView09D_8_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x452E, 0x16
NakaWidget_KuboView09D_9_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4544, 0x2C
NakaWidget_TrnsSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x4570, 0x24
NakaWidget_KuboView09D_11_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x4594, 0x3A
NakaWidget_KuboView09D_12_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x45CE, 0x2C
NakaWidget_KuboView09D_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x45FA, 0x1A
NakaWidget_KuboView09D_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4614, 0x1A
NakaWidget_KuboView09D_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x462E, 0x2A
; [nakarest] naka_effects_seq+0x4658  +0x4658..+0x4932 (0xe2c5fc, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x9e (table 0xe2ed5c, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0x9e (table 0xe2ed5c, 16 entries,
; [nakarest] InitializeKubo)): "VELOCITY CHANGE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "TRACK
; [nakarest] :" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView09E_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4658, 0x3A
NakaWidget_KuboView09E_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x4692, 0x26
NakaWidget_KuboView09E_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x46B8, 0x2A
NakaWidget_KuboView09E_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x46E2, 0x20
NakaWidget_KuboView09E_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4702, 0x42
NakaWidget_KuboView09E_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4744, 0x42
NakaWidget_KuboView09E_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4786, 0x42
NakaWidget_KuboView09E_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x47C8, 0x40
NakaWidget_KuboView09E_8_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x4808, 0x16
NakaWidget_KuboView09E_9_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x481E, 0x2C
NakaWidget_VeloSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x484A, 0x24
NakaWidget_KuboView09E_11_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x486E, 0x3A
NakaWidget_KuboView09E_12_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x48A8, 0x2C
NakaWidget_KuboView09E_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x48D4, 0x1A
NakaWidget_KuboView09E_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x48EE, 0x1A
NakaWidget_KuboView09E_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x4908, 0x2A
; [nakarest] naka_effects_seq+0x4932  +0x4932..+0x4d22 (0xe2c8d6, 1008 B)
; [nakarest] widget records, elements 0-24 of Viewable slot 0x9f (table 0xe2eda0, 25 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqedtVal (32 B), PsEditBox (50 B) x5, Label (32
; [nakarest] B) x3, AcIndexWideES (42 B), Line (26 B) x5, MsgToTtl (22 B), AcFuncEditSw (44 B)
; [nakarest] x2, Window (36 B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2,
; [nakarest] AcLanguageText (42 B). 10 texts the records point at (Viewable slot 0x9f (table
; [nakarest] 0xe2eda0, 25 entries, InitializeKubo)): "NOTE CHANGE" (TtlScreen.title of element
; [nakarest] 0); "" (PsEditBox.caption of element 2); "CHANGE TO" (Label.str of element 3);
; [nakarest] "VALUE" (Label.str of element 5); ....
NakaWidget_KuboView09F_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4932, 0x36
NakaWidget_KuboView09F_1_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x4968, 0x20
NakaWidget_KuboView09F_2_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4988, 0x34
NakaWidget_KuboView09F_3_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x49BC, 0x2A
NakaWidget_KuboView09F_4_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x49E6, 0x2A
NakaWidget_KuboView09F_5_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x4A10, 0x26
NakaWidget_KuboView09F_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4A36, 0x42
NakaWidget_KuboView09F_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4A78, 0x34
NakaWidget_KuboView09F_8_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x4AAC, 0x2C
NakaWidget_KuboView09F_9_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x4AD8, 0x1A
NakaWidget_KuboView09F_10_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x4AF2, 0x1A
NakaWidget_KuboView09F_11_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x4B0C, 0x1A
NakaWidget_KuboView09F_12_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x4B26, 0x1A
NakaWidget_KuboView09F_13_Line:			.incbin "includes/generated/naka_effects_seq.bin", 0x4B40, 0x1A
NakaWidget_KuboView09F_14_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4B5A, 0x42
NakaWidget_KuboView09F_15_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4B9C, 0x42
NakaWidget_KuboView09F_16_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x4BDE, 0x16
NakaWidget_KuboView09F_17_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4BF4, 0x2C
NakaWidget_NoteSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x4C20, 0x24
NakaWidget_KuboView09F_19_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x4C44, 0x3A
NakaWidget_KuboView09F_20_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4C7E, 0x2C
NakaWidget_KuboView09F_21_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4CAA, 0x1A
NakaWidget_KuboView09F_22_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4CC4, 0x1A
NakaWidget_KuboView09F_23_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4CDE, 0x1A
NakaWidget_KuboView09F_24_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x4CF8, 0x2A
; [nakarest] naka_effects_seq+0x4d22  +0x4d22..+0x4ffc (0xe2ccc6, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0xa0 (table 0xe2ee08, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0xa0 (table 0xe2ee08, 16 entries,
; [nakarest] InitializeKubo)): "ADVANCE/DELAY" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 2); "FIRST MEASURE:" (PsEditBox.caption of element 4); "LAST
; [nakarest] MEASURE :" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView0A0_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4D22, 0x38
NakaWidget_KuboView0A0_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x4D5A, 0x2A
NakaWidget_KuboView0A0_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x4D84, 0x26
NakaWidget_KuboView0A0_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x4DAA, 0x20
NakaWidget_KuboView0A0_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4DCA, 0x42
NakaWidget_KuboView0A0_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4E0C, 0x42
NakaWidget_KuboView0A0_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4E4E, 0x42
NakaWidget_KuboView0A0_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x4E90, 0x42
NakaWidget_KuboView0A0_8_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x4ED2, 0x16
NakaWidget_KuboView0A0_9_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4EE8, 0x2C
NakaWidget_AdvSureDisp:				.incbin "includes/generated/naka_effects_seq.bin", 0x4F14, 0x24
NakaWidget_KuboView0A0_11_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x4F38, 0x2C
NakaWidget_KuboView0A0_12_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x4F64, 0x3A
NakaWidget_KuboView0A0_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4F9E, 0x1A
NakaWidget_KuboView0A0_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x4FB8, 0x1A
NakaWidget_KuboView0A0_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x4FD2, 0x2A
; [nakarest] naka_effects_seq+0x4ffc  +0x4ffc..+0x52d6 (0xe2cfa0, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0xa1 (table 0xe2ee4c, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0xa1 (table 0xe2ee4c, 16 entries,
; [nakarest] InitializeKubo)): "MEASURE ERASE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 2); "TRACK :" (PsEditBox.caption of element 4); "FIRST
; [nakarest] MEASURE:" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView0A1_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x4FFC, 0x38
NakaWidget_KuboView0A1_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x5034, 0x2A
NakaWidget_KuboView0A1_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x505E, 0x26
NakaWidget_KuboView0A1_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x5084, 0x20
NakaWidget_KuboView0A1_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x50A4, 0x42
NakaWidget_KuboView0A1_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x50E6, 0x42
NakaWidget_KuboView0A1_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x5128, 0x42
NakaWidget_KuboView0A1_7_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x516A, 0x42
NakaWidget_KuboView0A1_8_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x51AC, 0x16
NakaWidget_KuboView0A1_9_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x51C2, 0x2C
NakaWidget_MersSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x51EE, 0x24
NakaWidget_KuboView0A1_11_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x5212, 0x3A
NakaWidget_KuboView0A1_12_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x524C, 0x2C
NakaWidget_KuboView0A1_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x5278, 0x1A
NakaWidget_KuboView0A1_14_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x5292, 0x1A
NakaWidget_KuboView0A1_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x52AC, 0x2A
; [nakarest] naka_effects_seq+0x52d6  +0x52d6..+0x554e (0xe2d27a, 632 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xa2 (table 0xe2ee90, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x4, SqedtVal2 (30 B),
; [nakarest] SqedtFix (28 B), MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B), Box (26 B)
; [nakarest] x3, IvExitScreen (26 B), AcLanguageText (42 B), AcScreenMenu (54 B). 2 texts the
; [nakarest] records point at (Viewable slot 0xa2 (table 0xe2ee90, 17 entries, InitializeKubo)):
; [nakarest] "MEASURE COPY" (TtlScreen.title of element 0); "NO" (AcScreenMenu.str of element
; [nakarest] 16).
NakaWidget_KuboView0A2_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x52D6, 0x38
NakaWidget_KuboView0A2_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x530E, 0x2A
NakaWidget_KuboView0A2_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x5338, 0x2A
NakaWidget_KuboView0A2_3_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x5362, 0x2A
NakaWidget_KuboView0A2_4_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x538C, 0x2A
NakaWidget_KuboView0A2_5_SqedtVal2:		.incbin "includes/generated/naka_effects_seq.bin", 0x53B6, 0x1E
NakaWidget_KuboView0A2_6_SqedtFix:		.incbin "includes/generated/naka_effects_seq.bin", 0x53D4, 0x1C
NakaWidget_KuboView0A2_7_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x53F0, 0x16
NakaWidget_KuboView0A2_8_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x5406, 0x2C
NakaWidget_McpSureDisp:				.incbin "includes/generated/naka_effects_seq.bin", 0x5432, 0x24
NakaWidget_KuboView0A2_10_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x5456, 0x1A
NakaWidget_KuboView0A2_11_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x5470, 0x1A
NakaWidget_KuboView0A2_12_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x548A, 0x1A
NakaWidget_KuboView0A2_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x54A4, 0x1A
NakaWidget_KuboView0A2_14_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x54BE, 0x2C
NakaWidget_KuboView0A2_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x54EA, 0x2A
NakaWidget_KuboView0A2_16_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x5514, 0x3A
; [nakarest] naka_effects_seq+0x554e  +0x554e..+0x57e6 (0xe2d4f2, 664 B)
; [nakarest] widget records, elements 0-14 of Viewable slot 0xa3 (table 0xe2eed8, 15 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x3, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 6
; [nakarest] texts the records point at (Viewable slot 0xa3 (table 0xe2eed8, 15 entries,
; [nakarest] InitializeKubo)): "MEASURE DELETE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 1); "FIRST MEASURE:" (PsEditBox.caption of element 4); "LAST
; [nakarest] MEASURE :" (PsEditBox.caption of element 5); ....
NakaWidget_KuboView0A3_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x554E, 0x3A
NakaWidget_KuboView0A3_1_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x5588, 0x26
NakaWidget_KuboView0A3_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x55AE, 0x2A
NakaWidget_KuboView0A3_3_SqedtVal:		.incbin "includes/generated/naka_effects_seq.bin", 0x55D8, 0x20
NakaWidget_KuboView0A3_4_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x55F8, 0x42
NakaWidget_KuboView0A3_5_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x563A, 0x42
NakaWidget_KuboView0A3_6_PsEditBox:		.incbin "includes/generated/naka_effects_seq.bin", 0x567C, 0x40
NakaWidget_KuboView0A3_7_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x56BC, 0x16
NakaWidget_KuboView0A3_8_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x56D2, 0x2C
NakaWidget_MdelSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x56FE, 0x24
NakaWidget_KuboView0A3_10_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x5722, 0x3A
NakaWidget_KuboView0A3_11_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x575C, 0x2C
NakaWidget_KuboView0A3_12_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x5788, 0x1A
NakaWidget_KuboView0A3_13_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x57A2, 0x1A
NakaWidget_KuboView0A3_14_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x57BC, 0x2A
; [nakarest] naka_effects_seq+0x57e6  +0x57e6..+0x5a60 (0xe2d78a, 634 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xa4 (table 0xe2ef18, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x4, SqedtVal2 (30 B),
; [nakarest] SqedtFix (28 B), MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B), Box (26 B)
; [nakarest] x3, IvExitScreen (26 B), AcLanguageText (42 B), AcScreenMenu (54 B). 2 texts the
; [nakarest] records point at (Viewable slot 0xa4 (table 0xe2ef18, 17 entries, InitializeKubo)):
; [nakarest] "MEASURE INSERT" (TtlScreen.title of element 0); "NO" (AcScreenMenu.str of element
; [nakarest] 16).
NakaWidget_KuboView0A4_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x57E6, 0x3A
NakaWidget_KuboView0A4_1_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x5820, 0x2A
NakaWidget_KuboView0A4_2_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x584A, 0x2A
NakaWidget_KuboView0A4_3_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x5874, 0x2A
NakaWidget_KuboView0A4_4_AcIndexWideES:		.incbin "includes/generated/naka_effects_seq.bin", 0x589E, 0x2A
NakaWidget_KuboView0A4_5_SqedtVal2:		.incbin "includes/generated/naka_effects_seq.bin", 0x58C8, 0x1E
NakaWidget_KuboView0A4_6_SqedtFix:		.incbin "includes/generated/naka_effects_seq.bin", 0x58E6, 0x1C
NakaWidget_KuboView0A4_7_MsgToTtl:		.incbin "includes/generated/naka_effects_seq.bin", 0x5902, 0x16
NakaWidget_KuboView0A4_8_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x5918, 0x2C
NakaWidget_MinsSureDisp:			.incbin "includes/generated/naka_effects_seq.bin", 0x5944, 0x24
NakaWidget_KuboView0A4_10_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x5968, 0x1A
NakaWidget_KuboView0A4_11_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x5982, 0x1A
NakaWidget_KuboView0A4_12_Box:			.incbin "includes/generated/naka_effects_seq.bin", 0x599C, 0x1A
NakaWidget_KuboView0A4_13_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x59B6, 0x1A
NakaWidget_KuboView0A4_14_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x59D0, 0x2C
NakaWidget_KuboView0A4_15_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x59FC, 0x2A
NakaWidget_KuboView0A4_16_AcScreenMenu:		.incbin "includes/generated/naka_effects_seq.bin", 0x5A26, 0x3A
; [nakarest] naka_effects_seq+0x5a60  +0x5a60..+0x5abc (0xe2da04, 92 B)
; [nakarest] widget records, elements 0-1 of Viewable slot 0xab (table 0xe2ef68, 2 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcMixerVol (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xab (table 0xe2ef68, 2 entries, InitializeKubo)): "METRONOME
; [nakarest] BALANCE" (TtlScreen.title of element 0).
NakaWidget_KuboView0AB_0_TtlScreen:	.incbin "includes/generated/naka_effects_seq.bin", 0x5A60, 0x3C
NakaWidget_KuboView0AB_1_AcMixerVol:	.incbin "includes/generated/naka_effects_seq.bin", 0x5A9C, 0x20
; [nakarest] naka_effects_seq+0x5abc  +0x5abc..+0x5bf2 (0xe2da60, 310 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0xd6 (table 0xe2ef74, 15 entries,
; [nakarest] InitializeKubo) ("EnterTainerScr"): TtlScreen (42 B), AcEntertainerGridBox (74 B),
; [nakarest] Label (32 B). 4 texts the records point at (Viewable slot 0xd6 (table 0xe2ef74, 15
; [nakarest] entries, InitializeKubo)): "ENTERTAINER" (TtlScreen.title of element 0); "MIC
; [nakarest] BALANCE :|-|| ON/OFF :| TYPE :| RE" (AcEntertainerGridBox.fixedrow of element 1); "
; [nakarest] | " (AcEntertainerGridBox.fixedcol of element 1); "VOCAL REVERB" (Label.str of
; [nakarest] element 2).
NakaWidget_EnterTainerScr:				.incbin "includes/generated/naka_effects_seq.bin", 0x5ABC, 0x36
NakaWidget_EnterTainerScr_1_AcEntertainerGridBox:	.incbin "includes/generated/naka_effects_seq.bin", 0x5AF2, 0xBC
NakaWidget_EnterTainerScr_2_Label:			.incbin "includes/generated/naka_effects_seq.bin", 0x5BAE, 0x44
; [nakarest] NakaInst_FADE_IN_OUT_SETTING  +0x5bf2..+0x5d6c (0xe2db96, 378 B)
; [nakarest] Text (36 B at 0xe2db96), first string "FADE IN/OUT SETTING"; no registered NAKA
; [nakarest] table points into it; reached through 3 data words in NakaData_SeqChannels (at
; [nakarest] 0xeee608, 0xeee63e, 0xeee674). widget records, elements 7-14 of Viewable slot 0xd6
; [nakarest] (table 0xe2ef74, 15 entries, InitializeKubo) ("EnterTainerScr"): AcIndexWideES (42
; [nakarest] B) x2, Label (32 B) x3, IvExitMode (26 B), AcFuncToggle (44 B), AcPanicEditSw (46
; [nakarest] B). 5 texts the records point at (Viewable slot 0xd6 (table 0xe2ef74, 15 entries,
; [nakarest] InitializeKubo)): "ITEM" (Label.str of element 9); "VALUE" (Label.str of element
; [nakarest] 10); "MUTE KEYS:OFF" (AcFuncToggle.stroff of element 12); "MUTE KEYS:ON "
; [nakarest] (AcFuncToggle.stron of element 12); ....
NakaInst_FADE_IN_OUT_SETTING:
	.incbin "includes/generated/naka_effects_seq.bin", 0x5BF2, 0x24
NakaWidget_EnterTainerScr_7_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x5C16, 0x2A
NakaWidget_EnterTainerScr_8_AcIndexWideES:	.incbin "includes/generated/naka_effects_seq.bin", 0x5C40, 0x2A
NakaWidget_EnterTainerScr_9_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x5C6A, 0x26
NakaWidget_EnterTainerScr_10_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x5C90, 0x26
NakaWidget_EnterTainerScr_11_IvExitMode:	.incbin "includes/generated/naka_effects_seq.bin", 0x5CB6, 0x1A
NakaWidget_EnterTainerScr_12_AcFuncToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5CD0, 0x48
NakaWidget_EnterTainerScr_13_AcPanicEditSw:	.incbin "includes/generated/naka_effects_seq.bin", 0x5D18, 0x2E
NakaWidget_EnterTainerScr_14_Label:		.incbin "includes/generated/naka_effects_seq.bin", 0x5D46, 0x26
; [nakarest] naka_effects_seq+0x5d6c  +0x5d6c..+0x6680 (0xe2dd10, 2324 B)
; [nakarest] widget records, elements 0-60 of Viewable slot 0xe7 (table 0xe2efb4, 61 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvExitMode (26 B), AcLanguageText (42 B) x11,
; [nakarest] IvShowHide (26 B) x5, AcFuncEditSw (44 B), Window (36 B) x11, AcIndexWideToggle (50
; [nakarest] B) x7, Screen (34 B) x4, IvExitScreen (26 B) x4, HelpTtl (36 B) x4, IvPageControl
; [nakarest] (28 B) x9, AcWindowPage (36 B) x3. 15 texts the records point at (Viewable slot
; [nakarest] 0xe7 (table 0xe2efb4, 61 entries, InitializeKubo)): "HELP FUNCTION"
; [nakarest] (TtlScreen.title of element 0); "ENGLISH" (AcIndexWideToggle.stroff of element 6);
; [nakarest] "ENGLISH" (AcIndexWideToggle.stron of element 6); "GERMAN"
; [nakarest] (AcIndexWideToggle.stroff of element 7); ....
NakaWidget_KuboView0E7_0_TtlScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x5D6C, 0x38
NakaWidget_KuboView0E7_1_IvExitMode:		.incbin "includes/generated/naka_effects_seq.bin", 0x5DA4, 0x1A
NakaWidget_HelpMenu:				.incbin "includes/generated/naka_effects_seq.bin", 0x5DBE, 0x2A
NakaWidget_KuboView0E7_3_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x5DE8, 0x1A
NakaWidget_KuboView0E7_4_AcFuncEditSw:		.incbin "includes/generated/naka_effects_seq.bin", 0x5E02, 0x2C
NakaWidget_HelpNotXWin:				.incbin "includes/generated/naka_effects_seq.bin", 0x5E2E, 0x24
NakaWidget_KuboView0E7_6_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5E52, 0x42
NakaWidget_KuboView0E7_7_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5E94, 0x42
NakaWidget_KuboView0E7_8_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5ED6, 0x42
NakaWidget_KuboView0E7_9_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5F18, 0x42
NakaWidget_HelpXWin:				.incbin "includes/generated/naka_effects_seq.bin", 0x5F5A, 0x24
NakaWidget_KuboView0E7_11_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5F7E, 0x32
Str_ENGLISH:					.incbin "includes/generated/naka_effects_seq.bin", 0x5FB0, 0x10
NakaWidget_KuboView0E7_12_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x5FC0, 0x42
NakaWidget_KuboView0E7_13_AcIndexWideToggle:	.incbin "includes/generated/naka_effects_seq.bin", 0x6002, 0x46
NakaWidget_HelpSwTtl1Scr:			.incbin "includes/generated/naka_effects_seq.bin", 0x6048, 0x22
NakaWidget_KuboView0E7_15_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x606A, 0x1A
NakaWidget_HelpTtlStr1:				.incbin "includes/generated/naka_effects_seq.bin", 0x6084, 0x24
NakaWidget_HelpLang1:				.incbin "includes/generated/naka_effects_seq.bin", 0x60A8, 0x2A
NakaWidget_KuboView0E7_18_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x60D2, 0x1A
NakaWidget_HelpLang2P1:				.incbin "includes/generated/naka_effects_seq.bin", 0x60EC, 0x24
NakaWidget_KuboView0E7_20_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x6110, 0x2A
NakaWidget_HelpLang2P2:				.incbin "includes/generated/naka_effects_seq.bin", 0x613A, 0x24
NakaWidget_KuboView0E7_22_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x615E, 0x2A
NakaWidget_HelpSwTtl2Scr:			.incbin "includes/generated/naka_effects_seq.bin", 0x6188, 0x22
NakaWidget_KuboView0E7_24_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x61AA, 0x1A
NakaWidget_HelpTtlStr2:				.incbin "includes/generated/naka_effects_seq.bin", 0x61C4, 0x24
NakaWidget_KuboView0E7_26_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x61E8, 0x1C
NakaWidget_KuboView0E7_27_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x6204, 0x1C
NakaWidget_Help_P2:				.incbin "includes/generated/naka_effects_seq.bin", 0x6220, 0x24
NakaWidget_KuboView0E7_29_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x6244, 0x1A
NakaWidget_HelpLang3P1:				.incbin "includes/generated/naka_effects_seq.bin", 0x625E, 0x24
NakaWidget_KuboView0E7_31_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x6282, 0x2A
NakaWidget_HelpLang3P2:				.incbin "includes/generated/naka_effects_seq.bin", 0x62AC, 0x24
NakaWidget_KuboView0E7_33_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x62D0, 0x2A
NakaWidget_HelpLang3P3:				.incbin "includes/generated/naka_effects_seq.bin", 0x62FA, 0x24
NakaWidget_KuboView0E7_35_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x631E, 0x2A
NakaWidget_HelpSwTtl3Scr:			.incbin "includes/generated/naka_effects_seq.bin", 0x6348, 0x22
NakaWidget_KuboView0E7_37_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x636A, 0x1A
NakaWidget_HelpTtlStr3:				.incbin "includes/generated/naka_effects_seq.bin", 0x6384, 0x24
NakaWidget_Help_P3:				.incbin "includes/generated/naka_effects_seq.bin", 0x63A8, 0x24
NakaWidget_KuboView0E7_40_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x63CC, 0x1C
NakaWidget_KuboView0E7_41_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x63E8, 0x1C
NakaWidget_KuboView0E7_42_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x6404, 0x1C
NakaWidget_KuboView0E7_43_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x6420, 0x1A
NakaWidget_HelpSwTtl4Scr:			.incbin "includes/generated/naka_effects_seq.bin", 0x643A, 0x22
NakaWidget_KuboView0E7_45_IvExitScreen:		.incbin "includes/generated/naka_effects_seq.bin", 0x645C, 0x1A
NakaWidget_Help_P4:				.incbin "includes/generated/naka_effects_seq.bin", 0x6476, 0x24
NakaWidget_HelpTtlStr4:				.incbin "includes/generated/naka_effects_seq.bin", 0x649A, 0x24
NakaWidget_KuboView0E7_48_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x64BE, 0x1C
NakaWidget_KuboView0E7_49_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x64DA, 0x1C
NakaWidget_KuboView0E7_50_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x64F6, 0x1C
NakaWidget_KuboView0E7_51_IvPageControl:	.incbin "includes/generated/naka_effects_seq.bin", 0x6512, 0x1C
NakaWidget_KuboView0E7_52_IvShowHide:		.incbin "includes/generated/naka_effects_seq.bin", 0x652E, 0x1A
NakaWidget_HelpLang4P1:				.incbin "includes/generated/naka_effects_seq.bin", 0x6548, 0x24
NakaWidget_KuboView0E7_54_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x656C, 0x2A
NakaWidget_HelpLang4P2:				.incbin "includes/generated/naka_effects_seq.bin", 0x6596, 0x24
NakaWidget_KuboView0E7_56_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x65BA, 0x2A
NakaWidget_HelpLang4P3:				.incbin "includes/generated/naka_effects_seq.bin", 0x65E4, 0x24
NakaWidget_KuboView0E7_58_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x6608, 0x2A
NakaWidget_HelpLang4P4:				.incbin "includes/generated/naka_effects_seq.bin", 0x6632, 0x24
NakaWidget_KuboView0E7_60_AcLanguageText:	.incbin "includes/generated/naka_effects_seq.bin", 0x6656, 0x2A
; [nakarest] naka_effects_seq+0x6680  +0x6680..+0x66b4 (0xe2e624, 52 B)
; [nakarest] the table itself: Viewable slot 0xa (table 0xe2e624, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
Kubo_ViewableTable_00A:	.incbin "includes/generated/naka_effects_seq.bin", 0x6680, 0x34
; [nakarest] naka_effects_seq+0x66b4  +0x66b4..+0x66e8 (0xe2e658, 52 B)
; [nakarest] the table itself: Viewable slot 0xb (table 0xe2e658, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
Kubo_ViewableTable_00B:	.incbin "includes/generated/naka_effects_seq.bin", 0x66B4, 0x34
; [nakarest] naka_effects_seq+0x66e8  +0x66e8..+0x6700 (0xe2e68c, 24 B)
; [nakarest] the table itself: Viewable slot 0xc (table 0xe2e68c, 37 entries, InitializeKubo),
; [nakarest] 37 entry pointers x 4 bytes.
Kubo_ViewableTable_00C:	.incbin "includes/generated/naka_effects_seq.bin", 0x66E8, 0x18
	.long NakaWidget_KuboView00C_6_AcIndexEditSw
	.long NakaWidget_KuboView00C_7_AcIndexEditSw
	.long NakaWidget_KuboView00C_8_AcIndexEditSw
	.long NakaWidget_KuboView00C_9_Label
	.long NakaWidget_KuboView00C_10_Label
	.long NakaWidget_KuboView00C_11_Label
	.long NakaWidget_KuboView00C_12_Label
	.long NakaWidget_KuboView00C_13_Label
	.long NakaWidget_KuboView00C_14_Label
	.long NakaWidget_KuboView00C_15_Label
	.long NakaWidget_KuboView00C_16_Label
	.long NakaWidget_KuboView00C_17_Label
	.long NakaWidget_KuboView00C_18_Label
	.long NakaWidget_KuboView00C_19_Label
	.long NakaWidget_KuboView00C_20_Label
	.long NakaWidget_KuboView00C_21_Line
	.long NakaWidget_KuboView00C_22_Line
	.long NakaWidget_KuboView00C_23_Line
	.long NakaWidget_KuboView00C_24_Line
	.long NakaWidget_KuboView00C_25_EqualizerBox
	.long NakaWidget_KuboView00C_26_Box
	.long NakaWidget_KuboView00C_27_Label
	.long NakaWidget_KuboView00C_28_Label
	.long NakaWidget_KuboView00C_29_Label
	.long NakaWidget_KuboView00C_30_Label
	.long NakaWidget_KuboView00C_31_Label
	.long NakaWidget_KuboView00C_32_Label
	.long NakaWidget_KuboView00C_33_Line
	.long NakaWidget_KuboView00C_34_Line
	.long NakaWidget_KuboView00C_35_Label
	.long NakaWidget_EqOnOff
	.long 0x00000000
InitializeKubo_PtrTable:	.long NakaWidget_KuboView00E_0_TtlScreen
	.long NakaWidget_KuboView00E_1_AcIndexWideES
	.long NakaWidget_KuboView00E_2_AcIndexWideES
	.long NakaWidget_KuboView00E_3_Label
	.long NakaWidget_KuboView00E_4_Label
	.long NakaWidget_KuboView00E_5_AccIll
	.long NakaWidget_KuboView00E_6_Box
	.long NakaWidget_KuboView00E_7_Box
	.long NakaWidget_KuboView00E_8_Label
	.long NakaWidget_KuboView00E_9_Label
	.long NakaWidget_KuboView00E_10_IvSdacc
	.long NakaWidget_KuboView00E_11_IvIntEasySet
	.long 0x00000000
InitializeKubo_PtrTable_2:	.long NakaWidget_KuboView080_0_TtlScreen
	.long NakaWidget_KuboView080_1_AcTitleMenu
	.long NakaWidget_KuboView080_2_Label
	.long NakaWidget_KuboView080_3_AcModeMenu
	.long NakaWidget_KuboView080_4_IvExitMode
	.long NakaWidget_KuboView080_5_AcIndexEditSw
	.long NakaWidget_KuboView080_6_AcIndexEditSw
	.long NakaWidget_KuboView080_7_Box
	.long NakaWidget_KuboView080_8_SngSel
	.long NakaWidget_KuboView080_9_AcLanguageText
	.long NakaWidget_KuboView080_10_AcLanguageText
	.long NakaWidget_KuboView080_11_AcTitleMenu
	.long 0x00000000
InitializeKubo_PtrTable_3:	.long NakaWidget_KuboView081_0_TtlScreen
	.long NakaWidget_KuboView081_1_Label
	.long NakaWidget_KuboView081_2_IvTrackSwitch
	.long NakaWidget_CycPlySw
	.long NakaWidget_KuboView081_4_Box
	.long NakaWidget_SqPlayGamen
	.long NakaWidget_KuboView081_6_Box
	.long NakaWidget_KuboView081_7_TrTransposeBox
	.long NakaWidget_KuboView081_8_TrChordBox
	.long NakaWidget_KuboView081_9_Label
	.long NakaWidget_KuboView081_10_Label
	.long NakaWidget_KuboView081_11_AcTempoBox
	.long NakaWidget_KuboView081_12_AcIndexEditSw
	.long NakaWidget_KuboView081_13_AcIndexEditSw
	.long NakaWidget_KuboView081_14_AcFuncEditSw
	.long NakaWidget_KuboView081_15_Label
	.long NakaWidget_KuboView081_16_IvPlayExit
	.long NakaWidget_PlySngSel
	.long NakaWidget_SngSelWin1
	.long NakaWidget_KuboView081_19_AcTitleMenu
	.long NakaWidget_KuboView081_20_AcFuncEditSw
	.long NakaWidget_KuboView081_21_Label
	.long NakaWidget_SngSelWin2
	.long NakaWidget_KuboView081_23_AcIndexEditSw
	.long NakaWidget_KuboView081_24_AcIndexEditSw
	.long NakaWidget_KuboView081_25_Label
	.long NakaWidget_KuboView081_26_IvShowHide
	.long NakaWidget_KuboView081_27_SngSel2
	.long 0x00000000
InitializeKubo_PtrTable_4:	.long NakaWidget_KuboView082_0_TtlScreen
	.long NakaWidget_KuboView082_1_SqplyVal
	.long NakaWidget_KuboView082_2_PsEditBox
	.long NakaWidget_KuboView082_3_Label
	.long NakaWidget_KuboView082_4_PsEditBox
	.long NakaWidget_KuboView082_5_PsEditBox
	.long NakaWidget_KuboView082_6_AcIndexWideES
	.long NakaWidget_KuboView082_7_Label
	.long 0x00000000
InitializeKubo_PtrTable_5:	.long NakaWidget_KuboView083_0_TtlScreen
	.long NakaWidget_KuboView083_1_Label
	.long NakaWidget_KuboView083_2_IvExitMode
	.long NakaWidget_KuboView083_3_AcTitleMenu
	.long NakaWidget_KuboView083_4_Box
	.long NakaWidget_KuboView083_5_AcIndexEditSw
	.long NakaWidget_KuboView083_6_AcIndexEditSw
	.long NakaWidget_KuboView083_7_SngSel
	.long NakaWidget_KuboView083_8_AcFuncEditSw
	.long NakaWidget_KuboView083_9_PsTrackSwitch
	.long NakaWidget_KuboView083_10_PsTrackSwitch
	.long NakaWidget_KuboView083_11_PsTrackSwitch
	.long NakaWidget_KuboView083_12_PsTrackSwitch
	.long NakaWidget_KuboView083_13_PsTrackSwitch
	.long NakaWidget_KuboView083_14_AcLanguageText
	.long NakaWidget_KuboView083_15_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_6:	.long NakaWidget_KuboView084_0_TtlScreen
	.long NakaWidget_KuboView084_1_AcTitleMenu
	.long NakaWidget_KuboView084_2_AcTitleMenu
	.long NakaWidget_KuboView084_3_AcTitleMenu
	.long NakaWidget_KuboView084_4_AcTitleMenu
	.long NakaWidget_KuboView084_5_AcTitleMenu
	.long NakaWidget_KuboView084_6_AcTitleMenu
	.long NakaWidget_KuboView084_7_AcModeMenu
	.long NakaWidget_KuboView084_8_AcModeMenu
	.long NakaWidget_KuboView084_9_AcTitleMenu
	.long 0x00000000
InitializeKubo_PtrTable_7:	.long NakaWidget_KuboView085_0_TtlScreen
	.long NakaWidget_KuboView085_1_IvTrackSwitch
	.long NakaWidget_KuboView085_2_AcFuncEditSw
	.long NakaWidget_KuboView085_3_Label
	.long NakaWidget_CycRecSw
	.long NakaWidget_KuboView085_5_Box
	.long NakaWidget_MetRecSw
	.long NakaWidget_SqRealRecGamen
	.long NakaWidget_KuboView085_8_Box
	.long NakaWidget_KuboView085_9_Label
	.long NakaWidget_KuboView085_10_Label
	.long NakaWidget_KuboView085_11_Label
	.long NakaWidget_KuboView085_12_AcTempoBox
	.long NakaWidget_KuboView085_13_TrTransposeBox
	.long NakaWidget_KuboView085_14_TrChordBox
	.long NakaWidget_KuboView085_15_Label
	.long NakaWidget_KuboView085_16_SngSel
	.long NakaWidget_KuboView085_17_AcFuncEditSw
	.long NakaWidget_KuboView085_18_Label
	.long 0x0003E1B8
	.long 0x0003E1E4
	.long NakaWidget_KuboView085_21_IvRealRecExit
	.long NakaWidget_CycClrSw
	.long NakaWidget_KuboView085_23_AcFuncEditSw
	.long NakaWidget_KuboView085_24_Label
	.long 0x00000000
InitializeKubo_PtrTable_8:	.long NakaWidget_KuboView086_0_TtlScreen
	.long NakaWidget_KuboView086_1_SqplyVal
	.long NakaWidget_KuboView086_2_PsEditBox
	.long NakaWidget_KuboView086_3_Label
	.long NakaWidget_KuboView086_4_PsEditBox
	.long NakaWidget_KuboView086_5_AcIndexWideES
	.long NakaWidget_KuboView086_6_Label
	.long NakaWidget_MetCycRecSw
	.long NakaWidget_KuboView086_8_AcFuncEditSw
	.long NakaWidget_KuboView086_9_Label
	.long NakaWidget_KuboView086_10_PsEditBox
	.long 0x00000000
InitializeKubo_PtrTable_9:	.long NakaWidget_KuboView087_0_TtlScreen
	.long NakaWidget_KuboView087_1_IvTrackSwitch
	.long NakaWidget_KuboView087_2_Box
	.long NakaWidget_SqPunchGamen
	.long NakaWidget_KuboView087_4_Box
	.long NakaWidget_KuboView087_5_Label
	.long NakaWidget_KuboView087_6_Label
	.long NakaWidget_KuboView087_7_Label
	.long NakaWidget_KuboView087_8_AcTempoBox
	.long NakaWidget_KuboView087_9_TrTransposeBox
	.long NakaWidget_KuboView087_10_TrChordBox
	.long NakaWidget_KuboView087_11_Label
	.long NakaWidget_KuboView087_12_SngSel
	.long NakaWidget_MetPunchSw
	.long NakaWidget_PunchInOutSw
	.long NakaWidget_KuboView087_15_Label
	.long NakaWidget_KuboView087_16_AcIndexEditSw
	.long NakaWidget_KuboView087_17_AcIndexEditSw
	.long NakaWidget_KuboView087_18_AcFuncEditSw
	.long NakaWidget_KuboView087_19_Label
	.long NakaWidget_KuboView087_20_IvPunchExit
	.long NakaWidget_KuboView087_21_AcFuncEditSw
	.long NakaWidget_KuboView087_22_Label
	.long NakaWidget_KuboView087_23_Label
	.long 0x00000000
InitializeKubo_PtrTable_10:	.long NakaWidget_KuboView088_0_TtlScreen
	.long NakaWidget_KuboView088_1_AcIndexWideES
	.long NakaWidget_KuboView088_2_Label
	.long NakaWidget_KuboView088_3_Label
	.long NakaWidget_MetPunchmSw
	.long NakaWidget_KuboView088_5_SqplyVal
	.long NakaWidget_KuboView088_6_PsEditBox
	.long NakaWidget_KuboView088_7_PsEditBox
	.long NakaWidget_KuboView088_8_PsEditBox
	.long NakaWidget_KuboView088_9_AcLanguageText
	.long NakaWidget_KuboView088_10_IvAutoPunchExit
	.long NakaWidget_KuboView088_11_TtlScreen
	.long 0x00000000
InitializeKubo_PtrTable_11:	.long NakaWidget_KuboView08D_0_TtlScreen
	.long NakaWidget_KuboView08D_1_AcFuncEditSw
	.long NakaWidget_KuboView08D_2_AcLanguageText
	.long NakaWidget_KuboView08D_3_IvPnlWrExit
	.long 0x00000000
InitializeKubo_PtrTable_12:	.long NakaWidget_KuboView090_0_TtlScreen
	.long NakaWidget_KuboView090_1_AcIndexWideES
	.long NakaWidget_KuboView090_2_Label
	.long NakaWidget_KuboView090_3_SqedtVal3
	.long NakaWidget_KuboView090_4_Box
	.long NakaWidget_KuboView090_5_Label
	.long NakaWidget_KuboView090_6_Label
	.long NakaWidget_KuboView090_7_MsgToTtl
	.long NakaWidget_KuboView090_8_AcFuncEditSw
	.long NakaWidget_SoclSureDisp
	.long NakaWidget_KuboView090_10_Box
	.long NakaWidget_KuboView090_11_AcScreenMenu
	.long NakaWidget_KuboView090_12_AcFuncEditSw
	.long NakaWidget_KuboView090_13_IvExitScreen
	.long NakaWidget_KuboView090_14_AcLanguageText
	.long NakaWidget_KuboView090_15_AcLanguageText
	.long NakaWidget_KuboView090_16_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_13:	.long NakaWidget_KuboView091_0_TtlScreen
	.long NakaWidget_KuboView091_1_SqedtVal2
	.long NakaWidget_KuboView091_2_SqedtFix
	.long NakaWidget_KuboView091_3_AcIndexWideES
	.long NakaWidget_KuboView091_4_AcIndexWideES
	.long NakaWidget_KuboView091_5_AcIndexWideES
	.long NakaWidget_KuboView091_6_AcIndexWideES
	.long NakaWidget_KuboView091_7_IvSongCopyExit
	.long NakaWidget_KuboView091_8_IvSongCopyExit
	.long NakaWidget_KuboView091_9_MsgToTtl
	.long NakaWidget_KuboView091_10_AcFuncEditSw
	.long NakaWidget_SngCpSureDisp
	.long NakaWidget_KuboView091_12_Box
	.long NakaWidget_KuboView091_13_Box
	.long NakaWidget_KuboView091_14_Box
	.long NakaWidget_KuboView091_15_AcScreenMenu
	.long NakaWidget_KuboView091_16_IvExitScreen
	.long NakaWidget_KuboView091_17_AcFuncEditSw
	.long NakaWidget_KuboView091_18_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_14:	.long NakaWidget_KuboView093_0_TtlScreen
	.long NakaWidget_KuboView093_1_IvPageControl
	.long NakaWidget_EdMenuPage
	.long NakaWidget_KuboView093_3_IvPageControl
	.long NakaWidget_KuboView093_4_IvExitMode
	.long NakaWidget_KuboView093_5_IvShowHide
	.long NakaWidget_SQEMENU_1
	.long NakaWidget_KuboView093_7_AcTitleMenu
	.long NakaWidget_KuboView093_8_AcTitleMenu
	.long NakaWidget_KuboView093_9_AcTitleMenu
	.long NakaWidget_KuboView093_10_AcTitleMenu
	.long NakaWidget_KuboView093_11_AcTitleMenu
	.long NakaWidget_KuboView093_12_AcTitleMenu
	.long NakaWidget_KuboView093_13_AcTitleMenu
	.long NakaWidget_KuboView093_14_AcTitleMenu
	.long NakaWidget_KuboView093_15_AcTitleMenu
	.long NakaWidget_KuboView093_16_AcTitleMenu
	.long NakaWidget_SQEMENU_2
	.long NakaWidget_KuboView093_18_AcTitleMenu
	.long NakaWidget_KuboView093_19_Line
	.long NakaWidget_KuboView093_20_AcTitleMenu
	.long NakaWidget_KuboView093_21_AcTitleMenu
	.long NakaWidget_KuboView093_22_AcTitleMenu
	.long NakaWidget_KuboView093_23_Label
	.long NakaWidget_KuboView093_24_Line
	.long NakaWidget_KuboView093_25_Line
	.long 0x00000000
InitializeKubo_PtrTable_15:	.long NakaWidget_KuboView094_0_TtlScreen
	.long NakaWidget_KuboView094_1_Label
	.long NakaWidget_KuboView094_2_IvTrackSwitch
	.long NakaWidget_KuboView094_3_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_16:	.long NakaWidget_KuboView095_0_TtlScreen
	.long NakaWidget_KuboView095_1_AcIndexEditSw
	.long NakaWidget_KuboView095_2_AcIndexEditSw
	.long NakaWidget_KuboView095_3_AcIndexEditSw
	.long NakaWidget_KuboView095_4_AcIndexEditSw
	.long NakaWidget_KuboView095_5_AcIndexEditSw
	.long NakaWidget_KuboView095_6_AcIndexEditSw
	.long NakaWidget_KuboView095_7_Label
	.long NakaWidget_KuboView095_8_Label
	.long NakaWidget_KuboView095_9_Label
	.long NakaWidget_KuboView095_10_Label
	.long NakaWidget_KuboView095_11_Label
	.long NakaWidget_KuboView095_12_Label
	.long NakaWidget_KuboView095_13_Label
	.long NakaWidget_KuboView095_14_AcIndexEditSw
	.long NakaWidget_KuboView095_15_AcIndexEditSw
	.long NakaWidget_KuboView095_16_Label
	.long NakaWidget_KuboView095_17_NoteEditBox
	.long NakaWidget_KuboView095_18_Box
	.long NakaWidget_KuboView095_19_VwUserBitmap
	.long NakaWidget_NTBitmap
	.long NakaWidget_KuboView095_21_AcIndexEditSw
	.long NakaWidget_KuboView095_22_Label
	.long NakaWidget_KuboView095_23_AcIndexEditSw
	.long NakaWidget_KuboView095_24_Label
	.long NakaWidget_KuboView095_25_AcIndexEditSw
	.long NakaWidget_KuboView095_26_AcIndexEditSw
	.long 0x00000000
InitializeKubo_PtrTable_17:	.long NakaWidget_KuboView096_0_TtlScreen
	.long NakaWidget_KuboView096_1_Label
	.long NakaWidget_KuboView096_2_AcIndexWideES
	.long NakaWidget_KuboView096_3_Label
	.long NakaWidget_KuboView096_4_SqplyVal
	.long NakaWidget_KuboView096_5_PsEditBox
	.long NakaWidget_KuboView096_6_PsEditBox
	.long NakaWidget_KuboView096_7_PsEditBox
	.long 0x00000000
InitializeKubo_PtrTable_18:	.long NakaWidget_KuboView097_0_TtlScreen
	.long NakaWidget_KuboView097_1_Label
	.long NakaWidget_KuboView097_2_IvTrackSwitch
	.long NakaWidget_KuboView097_3_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_19:	.long NakaWidget_KuboView098_0_TtlScreen
	.long NakaWidget_KuboView098_1_AcIndexEditSw
	.long NakaWidget_KuboView098_2_AcIndexEditSw
	.long NakaWidget_KuboView098_3_AcIndexEditSw
	.long NakaWidget_KuboView098_4_AcIndexEditSw
	.long NakaWidget_KuboView098_5_AcIndexEditSw
	.long NakaWidget_KuboView098_6_AcIndexEditSw
	.long NakaWidget_KuboView098_7_Label
	.long NakaWidget_KuboView098_8_Label
	.long NakaWidget_KuboView098_9_Label
	.long NakaWidget_KuboView098_10_Label
	.long NakaWidget_KuboView098_11_Label
	.long NakaWidget_KuboView098_12_Label
	.long NakaWidget_KuboView098_13_Label
	.long NakaWidget_KuboView098_14_Box
	.long NakaWidget_KuboView098_15_NoteEditBox
	.long NakaWidget_KuboView098_16_VwUserBitmap
	.long NakaWidget_DRBitmap
	.long NakaWidget_KuboView098_18_AcIndexEditSw
	.long NakaWidget_KuboView098_19_Label
	.long NakaWidget_KuboView098_20_AcIndexEditSw
	.long NakaWidget_KuboView098_21_Label
	.long NakaWidget_KuboView098_22_AcIndexEditSw
	.long NakaWidget_KuboView098_23_Label
	.long NakaWidget_KuboView098_24_AcIndexEditSw
	.long NakaWidget_KuboView098_25_AcIndexEditSw
	.long 0x00000000
InitializeKubo_PtrTable_20:	.long NakaWidget_KuboView099_0_TtlScreen
	.long NakaWidget_KuboView099_1_Label
	.long NakaWidget_KuboView099_2_AcIndexWideES
	.long NakaWidget_KuboView099_3_Label
	.long NakaWidget_KuboView099_4_SqplyVal
	.long NakaWidget_KuboView099_5_PsEditBox
	.long NakaWidget_KuboView099_6_PsEditBox
	.long NakaWidget_KuboView099_7_PsEditBox
	.long 0x00000000
InitializeKubo_PtrTable_21:	.long NakaWidget_KuboView09A_0_TtlScreen
	.long NakaWidget_KuboView09A_1_IvTrackSwitch
	.long NakaWidget_KuboView09A_2_MsgToTtl
	.long NakaWidget_KuboView09A_3_AcLanguageText
	.long NakaWidget_KuboView09A_4_AcLanguageText
	.long NakaWidget_KuboView09A_5_AcFuncEditSw
	.long NakaWidget_TrkClrSureDisp
	.long NakaWidget_KuboView09A_7_AcFuncEditSw
	.long NakaWidget_KuboView09A_8_AcScreenMenu
	.long NakaWidget_KuboView09A_9_VwBox
	.long NakaWidget_KuboView09A_10_IvExitScreen
	.long NakaWidget_KuboView09A_11_AcLanguageText
	.long NakaWidget_KuboView09A_12_AcLanguageText
	.long NakaWidget_KuboView09A_13_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_22:	.long NakaWidget_KuboView09B_0_TtlScreen
	.long NakaWidget_KuboView09B_1_Line
	.long NakaWidget_KuboView09B_2_Line
	.long NakaWidget_KuboView09B_3_Line
	.long NakaWidget_KuboView09B_4_Line
	.long NakaWidget_KuboView09B_5_Line
	.long NakaWidget_KuboView09B_6_Line
	.long NakaWidget_KuboView09B_7_AcIndexWideES
	.long NakaWidget_KuboView09B_8_Label
	.long NakaWidget_KuboView09B_9_SqedtVal
	.long NakaWidget_KuboView09B_10_PsEditBox
	.long NakaWidget_KuboView09B_11_PsEditBox
	.long NakaWidget_KuboView09B_12_PsEditBox
	.long NakaWidget_KuboView09B_13_MsgToTtl
	.long NakaWidget_KuboView09B_14_AcFuncEditSw
	.long NakaWidget_TrkMrgSureDisp
	.long NakaWidget_KuboView09B_16_AcFuncEditSw
	.long NakaWidget_KuboView09B_17_AcScreenMenu
	.long NakaWidget_KuboView09B_18_IvExitScreen
	.long NakaWidget_KuboView09B_19_Box
	.long NakaWidget_KuboView09B_20_Box
	.long NakaWidget_KuboView09B_21_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_23:	.long NakaWidget_KuboView09C_0_TtlScreen
	.long NakaWidget_KuboView09C_1_Label
	.long NakaWidget_KuboView09C_2_AcIndexWideES
	.long NakaWidget_KuboView09C_3_SqedtVal
	.long NakaWidget_KuboView09C_4_PsEditBox
	.long NakaWidget_KuboView09C_5_PsEditBox
	.long NakaWidget_KuboView09C_6_Label
	.long NakaWidget_KuboView09C_7_PsEditBox
	.long NakaWidget_KuboView09C_8_PsEditBox
	.long NakaWidget_KuboView09C_9_PsEditBox
	.long NakaWidget_KuboView09C_10_PsEditBox
	.long NakaWidget_KuboView09C_11_Label
	.long NakaWidget_KuboView09C_12_MsgToTtl
	.long NakaWidget_KuboView09C_13_AcFuncEditSw
	.long NakaWidget_QtzSureDisp
	.long NakaWidget_KuboView09C_15_AcScreenMenu
	.long NakaWidget_KuboView09C_16_AcFuncEditSw
	.long NakaWidget_KuboView09C_17_IvExitScreen
	.long NakaWidget_KuboView09C_18_Box
	.long NakaWidget_KuboView09C_19_Box
	.long NakaWidget_KuboView09C_20_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_24:	.long NakaWidget_KuboView09D_0_TtlScreen
	.long NakaWidget_KuboView09D_1_Label
	.long NakaWidget_KuboView09D_2_AcIndexWideES
	.long NakaWidget_KuboView09D_3_SqedtVal
	.long NakaWidget_KuboView09D_4_PsEditBox
	.long NakaWidget_KuboView09D_5_PsEditBox
	.long NakaWidget_KuboView09D_6_PsEditBox
	.long NakaWidget_KuboView09D_7_PsEditBox
	.long NakaWidget_KuboView09D_8_MsgToTtl
	.long NakaWidget_KuboView09D_9_AcFuncEditSw
	.long NakaWidget_TrnsSureDisp
	.long NakaWidget_KuboView09D_11_AcScreenMenu
	.long NakaWidget_KuboView09D_12_AcFuncEditSw
	.long NakaWidget_KuboView09D_13_IvExitScreen
	.long NakaWidget_KuboView09D_14_Box
	.long NakaWidget_KuboView09D_15_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_25:	.long NakaWidget_KuboView09E_0_TtlScreen
	.long NakaWidget_KuboView09E_1_Label
	.long NakaWidget_KuboView09E_2_AcIndexWideES
	.long NakaWidget_KuboView09E_3_SqedtVal
	.long NakaWidget_KuboView09E_4_PsEditBox
	.long NakaWidget_KuboView09E_5_PsEditBox
	.long NakaWidget_KuboView09E_6_PsEditBox
	.long NakaWidget_KuboView09E_7_PsEditBox
	.long NakaWidget_KuboView09E_8_MsgToTtl
	.long NakaWidget_KuboView09E_9_AcFuncEditSw
	.long NakaWidget_VeloSureDisp
	.long NakaWidget_KuboView09E_11_AcScreenMenu
	.long NakaWidget_KuboView09E_12_AcFuncEditSw
	.long NakaWidget_KuboView09E_13_IvExitScreen
	.long NakaWidget_KuboView09E_14_Box
	.long NakaWidget_KuboView09E_15_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_26:	.long NakaWidget_KuboView09F_0_TtlScreen
	.long NakaWidget_KuboView09F_1_SqedtVal
	.long NakaWidget_KuboView09F_2_PsEditBox
	.long NakaWidget_KuboView09F_3_Label
	.long NakaWidget_KuboView09F_4_AcIndexWideES
	.long NakaWidget_KuboView09F_5_Label
	.long NakaWidget_KuboView09F_6_PsEditBox
	.long NakaWidget_KuboView09F_7_PsEditBox
	.long NakaWidget_KuboView09F_8_Label
	.long NakaWidget_KuboView09F_9_Line
	.long NakaWidget_KuboView09F_10_Line
	.long NakaWidget_KuboView09F_11_Line
	.long NakaWidget_KuboView09F_12_Line
	.long NakaWidget_KuboView09F_13_Line
	.long NakaWidget_KuboView09F_14_PsEditBox
	.long NakaWidget_KuboView09F_15_PsEditBox
	.long NakaWidget_KuboView09F_16_MsgToTtl
	.long NakaWidget_KuboView09F_17_AcFuncEditSw
	.long NakaWidget_NoteSureDisp
	.long NakaWidget_KuboView09F_19_AcScreenMenu
	.long NakaWidget_KuboView09F_20_AcFuncEditSw
	.long NakaWidget_KuboView09F_21_IvExitScreen
	.long NakaWidget_KuboView09F_22_Box
	.long NakaWidget_KuboView09F_23_Box
	.long NakaWidget_KuboView09F_24_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_27:	.long NakaWidget_KuboView0A0_0_TtlScreen
	.long NakaWidget_KuboView0A0_1_AcIndexWideES
	.long NakaWidget_KuboView0A0_2_Label
	.long NakaWidget_KuboView0A0_3_SqedtVal
	.long NakaWidget_KuboView0A0_4_PsEditBox
	.long NakaWidget_KuboView0A0_5_PsEditBox
	.long NakaWidget_KuboView0A0_6_PsEditBox
	.long NakaWidget_KuboView0A0_7_PsEditBox
	.long NakaWidget_KuboView0A0_8_MsgToTtl
	.long NakaWidget_KuboView0A0_9_AcFuncEditSw
	.long NakaWidget_AdvSureDisp
	.long NakaWidget_KuboView0A0_11_AcFuncEditSw
	.long NakaWidget_KuboView0A0_12_AcScreenMenu
	.long NakaWidget_KuboView0A0_13_IvExitScreen
	.long NakaWidget_KuboView0A0_14_Box
	.long NakaWidget_KuboView0A0_15_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_28:	.long NakaWidget_KuboView0A1_0_TtlScreen
	.long NakaWidget_KuboView0A1_1_AcIndexWideES
	.long NakaWidget_KuboView0A1_2_Label
	.long NakaWidget_KuboView0A1_3_SqedtVal
	.long NakaWidget_KuboView0A1_4_PsEditBox
	.long NakaWidget_KuboView0A1_5_PsEditBox
	.long NakaWidget_KuboView0A1_6_PsEditBox
	.long NakaWidget_KuboView0A1_7_PsEditBox
	.long NakaWidget_KuboView0A1_8_MsgToTtl
	.long NakaWidget_KuboView0A1_9_AcFuncEditSw
	.long NakaWidget_MersSureDisp
	.long NakaWidget_KuboView0A1_11_AcScreenMenu
	.long NakaWidget_KuboView0A1_12_AcFuncEditSw
	.long NakaWidget_KuboView0A1_13_IvExitScreen
	.long NakaWidget_KuboView0A1_14_Box
	.long NakaWidget_KuboView0A1_15_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_29:	.long NakaWidget_KuboView0A2_0_TtlScreen
	.long NakaWidget_KuboView0A2_1_AcIndexWideES
	.long NakaWidget_KuboView0A2_2_AcIndexWideES
	.long NakaWidget_KuboView0A2_3_AcIndexWideES
	.long NakaWidget_KuboView0A2_4_AcIndexWideES
	.long NakaWidget_KuboView0A2_5_SqedtVal2
	.long NakaWidget_KuboView0A2_6_SqedtFix
	.long NakaWidget_KuboView0A2_7_MsgToTtl
	.long NakaWidget_KuboView0A2_8_AcFuncEditSw
	.long NakaWidget_McpSureDisp
	.long NakaWidget_KuboView0A2_10_Box
	.long NakaWidget_KuboView0A2_11_Box
	.long NakaWidget_KuboView0A2_12_Box
	.long NakaWidget_KuboView0A2_13_IvExitScreen
	.long NakaWidget_KuboView0A2_14_AcFuncEditSw
	.long NakaWidget_KuboView0A2_15_AcLanguageText
	.long NakaWidget_KuboView0A2_16_AcScreenMenu
	.long 0x00000000
InitializeKubo_PtrTable_30:	.long NakaWidget_KuboView0A3_0_TtlScreen
	.long NakaWidget_KuboView0A3_1_Label
	.long NakaWidget_KuboView0A3_2_AcIndexWideES
	.long NakaWidget_KuboView0A3_3_SqedtVal
	.long NakaWidget_KuboView0A3_4_PsEditBox
	.long NakaWidget_KuboView0A3_5_PsEditBox
	.long NakaWidget_KuboView0A3_6_PsEditBox
	.long NakaWidget_KuboView0A3_7_MsgToTtl
	.long NakaWidget_KuboView0A3_8_AcFuncEditSw
	.long NakaWidget_MdelSureDisp
	.long NakaWidget_KuboView0A3_10_AcScreenMenu
	.long NakaWidget_KuboView0A3_11_AcFuncEditSw
	.long NakaWidget_KuboView0A3_12_IvExitScreen
	.long NakaWidget_KuboView0A3_13_Box
	.long NakaWidget_KuboView0A3_14_AcLanguageText
	.long 0x00000000
InitializeKubo_PtrTable_31:	.long NakaWidget_KuboView0A4_0_TtlScreen
	.long NakaWidget_KuboView0A4_1_AcIndexWideES
	.long NakaWidget_KuboView0A4_2_AcIndexWideES
	.long NakaWidget_KuboView0A4_3_AcIndexWideES
	.long NakaWidget_KuboView0A4_4_AcIndexWideES
	.long NakaWidget_KuboView0A4_5_SqedtVal2
	.long NakaWidget_KuboView0A4_6_SqedtFix
	.long NakaWidget_KuboView0A4_7_MsgToTtl
	.long NakaWidget_KuboView0A4_8_AcFuncEditSw
	.long NakaWidget_MinsSureDisp
	.long NakaWidget_KuboView0A4_10_Box
	.long NakaWidget_KuboView0A4_11_Box
	.long NakaWidget_KuboView0A4_12_Box
	.long NakaWidget_KuboView0A4_13_IvExitScreen
	.long NakaWidget_KuboView0A4_14_AcFuncEditSw
	.long NakaWidget_KuboView0A4_15_AcLanguageText
	.long NakaWidget_KuboView0A4_16_AcScreenMenu
	.long 0x00000000
Kubo_ViewableTable_0A8:		.long 0x00000000
Kubo_ViewableTable_0AA:		.long 0x00000000
InitializeKubo_PtrTable_32:	.long NakaWidget_KuboView0AB_0_TtlScreen
	.long NakaWidget_KuboView0AB_1_AcMixerVol
	.long 0x00000000
InitializeKubo_PtrTable_33:	.long NakaWidget_EnterTainerScr
	.long NakaWidget_EnterTainerScr_1_AcEntertainerGridBox
	.long NakaWidget_EnterTainerScr_2_Label
	.long 0x0003E204
	.long 0x0003E23A
	.long 0x0003E270
	.long 0x0003E2A6
	.long NakaWidget_EnterTainerScr_7_AcIndexWideES
	.long NakaWidget_EnterTainerScr_8_AcIndexWideES
	.long NakaWidget_EnterTainerScr_9_Label
	.long NakaWidget_EnterTainerScr_10_Label
	.long NakaWidget_EnterTainerScr_11_IvExitMode
	.long NakaWidget_EnterTainerScr_12_AcFuncToggle
	.long NakaWidget_EnterTainerScr_13_AcPanicEditSw
	.long NakaWidget_EnterTainerScr_14_Label
	.long 0x00000000
InitializeKubo_PtrTable_34:	.long NakaWidget_KuboView0E7_0_TtlScreen
	.long NakaWidget_KuboView0E7_1_IvExitMode
	.long NakaWidget_HelpMenu
	.long NakaWidget_KuboView0E7_3_IvShowHide
	.long NakaWidget_KuboView0E7_4_AcFuncEditSw
	.long NakaWidget_HelpNotXWin
	.long NakaWidget_KuboView0E7_6_AcIndexWideToggle
	.long NakaWidget_KuboView0E7_7_AcIndexWideToggle
	.long NakaWidget_KuboView0E7_8_AcIndexWideToggle
	.long NakaWidget_KuboView0E7_9_AcIndexWideToggle
	.long NakaWidget_HelpXWin
	.long NakaWidget_KuboView0E7_11_AcIndexWideToggle
	.long NakaWidget_KuboView0E7_12_AcIndexWideToggle
	.long NakaWidget_KuboView0E7_13_AcIndexWideToggle
	.long NakaWidget_HelpSwTtl1Scr
	.long NakaWidget_KuboView0E7_15_IvExitScreen
	.long NakaWidget_HelpTtlStr1
	.long NakaWidget_HelpLang1
	.long NakaWidget_KuboView0E7_18_IvShowHide
	.long NakaWidget_HelpLang2P1
	.long NakaWidget_KuboView0E7_20_AcLanguageText
	.long NakaWidget_HelpLang2P2
	.long NakaWidget_KuboView0E7_22_AcLanguageText
	.long NakaWidget_HelpSwTtl2Scr
	.long NakaWidget_KuboView0E7_24_IvExitScreen
	.long NakaWidget_HelpTtlStr2
	.long NakaWidget_KuboView0E7_26_IvPageControl
	.long NakaWidget_KuboView0E7_27_IvPageControl
	.long NakaWidget_Help_P2
	.long NakaWidget_KuboView0E7_29_IvShowHide
	.long NakaWidget_HelpLang3P1
	.long NakaWidget_KuboView0E7_31_AcLanguageText
	.long NakaWidget_HelpLang3P2
	.long NakaWidget_KuboView0E7_33_AcLanguageText
	.long NakaWidget_HelpLang3P3
	.long NakaWidget_KuboView0E7_35_AcLanguageText
	.long NakaWidget_HelpSwTtl3Scr
	.long NakaWidget_KuboView0E7_37_IvExitScreen
	.long NakaWidget_HelpTtlStr3
	.long NakaWidget_Help_P3
	.long NakaWidget_KuboView0E7_40_IvPageControl
	.long NakaWidget_KuboView0E7_41_IvPageControl
	.long NakaWidget_KuboView0E7_42_IvPageControl
	.long NakaWidget_KuboView0E7_43_IvShowHide
	.long NakaWidget_HelpSwTtl4Scr
	.long NakaWidget_KuboView0E7_45_IvExitScreen
	.long NakaWidget_Help_P4
	.long NakaWidget_HelpTtlStr4
	.long NakaWidget_KuboView0E7_48_IvPageControl
	.long NakaWidget_KuboView0E7_49_IvPageControl
	.long NakaWidget_KuboView0E7_50_IvPageControl
	.long NakaWidget_KuboView0E7_51_IvPageControl
	.long NakaWidget_KuboView0E7_52_IvShowHide
	.long NakaWidget_HelpLang4P1
	.long NakaWidget_KuboView0E7_54_AcLanguageText
	.long NakaWidget_HelpLang4P2
	.long NakaWidget_KuboView0E7_56_AcLanguageText
	.long NakaWidget_HelpLang4P3
	.long NakaWidget_KuboView0E7_58_AcLanguageText
	.long NakaWidget_HelpLang4P4
; [nakarest] naka_effects_seq+0x7100  +0x7100..+0x7108 (0xe2f0a4, 8 B)
; [nakarest] 4 B at 0xe2f0a8: the end marker of Viewable slot 0xe7 (table 0xe2efb4, 61 entries, InitializeKubo) -- a zero word after entry 60, the last, as every Viewable table ends.
; [nakarest] Continues the table itself: Viewable slot 0xe7 (table 0xe2efb4, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe2efb4, 4 of its 244 bytes
; [nakarest] are here or later).
	.incbin "includes/generated/naka_effects_seq.bin", 0x7100, 0x8
; [nakarest] naka_effects_seq+0x7108  +0x7108..+0x713e (0xe2f0ac, 54 B)
; [nakarest] the table itself: ResName slot 0x30a (table 0xe2f0ac, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
InitializeKubo_PtrTable_35:	.incbin "includes/generated/naka_effects_seq.bin", 0x7108, 0x36
; [nakarest] naka_effects_seq+0x713e  +0x713e..+0x7156 (0xe2f0e2, 24 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x30a (table 0xe2f0ac, 12 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x713E, 0x18
; [nakarest] naka_effects_seq+0x7156  +0x7156..+0x718c (0xe2f0fa, 54 B)
; [nakarest] the table itself: ResName slot 0x30b (table 0xe2f0fa, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
InitializeKubo_PtrTable_36:	.incbin "includes/generated/naka_effects_seq.bin", 0x7156, 0x36
; [nakarest] naka_effects_seq+0x718c  +0x718c..+0x71a4 (0xe2f130, 24 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x30b (table 0xe2f0fa, 12 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xb): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x718C, 0x18
; [nakarest] naka_effects_seq+0x71a4  +0x71a4..+0x723e (0xe2f148, 154 B)
; [nakarest] the table itself: ResName slot 0x30c (table 0xe2f148, 37 entries, InitializeKubo),
; [nakarest] 37 entry pointers x 4 bytes.
InitializeKubo_PtrTable_37:	.incbin "includes/generated/naka_effects_seq.bin", 0x71A4, 0x9A
; [nakarest] naka_effects_seq+0x723e  +0x723e..+0x728e (0xe2f1e2, 80 B)
; [nakarest] name strings, entries 0-36 of ResName slot 0x30c (table 0xe2f148, 37 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xc): "EqOnOff", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x723E, 0x50
; [nakarest] naka_effects_seq+0x728e  +0x728e..+0x72c4 (0xe2f232, 54 B)
; [nakarest] the table itself: ResName slot 0x30e (table 0xe2f232, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
InitializeKubo_PtrTable_38:	.incbin "includes/generated/naka_effects_seq.bin", 0x728E, 0x36
; [nakarest] naka_effects_seq+0x72c4  +0x72c4..+0x72dc (0xe2f268, 24 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x30e (table 0xe2f232, 12 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xe): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x72C4, 0x18
; [nakarest] naka_effects_seq+0x72dc  +0x72dc..+0x7312 (0xe2f280, 54 B)
; [nakarest] the table itself: ResName slot 0x380 (table 0xe2f280, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
InitializeKubo_PtrTable_39:	.incbin "includes/generated/naka_effects_seq.bin", 0x72DC, 0x36
; [nakarest] naka_effects_seq+0x7312  +0x7312..+0x732a (0xe2f2b6, 24 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x380 (table 0xe2f280, 12 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x80): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7312, 0x18
; [nakarest] naka_effects_seq+0x732a  +0x732a..+0x73a0 (0xe2f2ce, 118 B)
; [nakarest] the table itself: ResName slot 0x381 (table 0xe2f2ce, 28 entries, InitializeKubo),
; [nakarest] 28 entry pointers x 4 bytes.
InitializeKubo_PtrTable_40:	.incbin "includes/generated/naka_effects_seq.bin", 0x732A, 0x76
; [nakarest] naka_effects_seq+0x73a0  +0x73a0..+0x7406 (0xe2f344, 102 B)
; [nakarest] name strings, entries 0-27 of ResName slot 0x381 (table 0xe2f2ce, 28 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x81): "", "", "", "", "", "SngSelWin2",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x73A0, 0x66
; [nakarest] naka_effects_seq+0x7406  +0x7406..+0x742c (0xe2f3aa, 38 B)
; [nakarest] the table itself: ResName slot 0x382 (table 0xe2f3aa, 8 entries, InitializeKubo), 8
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_41:	.incbin "includes/generated/naka_effects_seq.bin", 0x7406, 0x26
; [nakarest] naka_effects_seq+0x742c  +0x742c..+0x743c (0xe2f3d0, 16 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x382 (table 0xe2f3aa, 8 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x82): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x742C, 0x10
; [nakarest] naka_effects_seq+0x743c  +0x743c..+0x7482 (0xe2f3e0, 70 B)
; [nakarest] the table itself: ResName slot 0x383 (table 0xe2f3e0, 16 entries, InitializeKubo),
; [nakarest] 16 entry pointers x 4 bytes.
InitializeKubo_PtrTable_42:	.incbin "includes/generated/naka_effects_seq.bin", 0x743C, 0x46
; [nakarest] naka_effects_seq+0x7482  +0x7482..+0x74a2 (0xe2f426, 32 B)
; [nakarest] name strings, entries 0-15 of ResName slot 0x383 (table 0xe2f3e0, 16 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x83): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7482, 0x20
; [nakarest] naka_effects_seq+0x74a2  +0x74a2..+0x74d0 (0xe2f446, 46 B)
; [nakarest] the table itself: ResName slot 0x384 (table 0xe2f446, 10 entries, InitializeKubo),
; [nakarest] 10 entry pointers x 4 bytes.
InitializeKubo_PtrTable_43:	.incbin "includes/generated/naka_effects_seq.bin", 0x74A2, 0x2E
; [nakarest] naka_effects_seq+0x74d0  +0x74d0..+0x74e4 (0xe2f474, 20 B)
; [nakarest] name strings, entries 0-9 of ResName slot 0x384 (table 0xe2f446, 10 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x84): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x74D0, 0x14
; [nakarest] naka_effects_seq+0x74e4  +0x74e4..+0x754e (0xe2f488, 106 B)
; [nakarest] the table itself: ResName slot 0x385 (table 0xe2f488, 25 entries, InitializeKubo),
; [nakarest] 25 entry pointers x 4 bytes.
InitializeKubo_PtrTable_44:	.incbin "includes/generated/naka_effects_seq.bin", 0x74E4, 0x6A
; [nakarest] naka_effects_seq+0x754e  +0x754e..+0x75bc (0xe2f4f2, 110 B)
; [nakarest] name strings, entries 0-24 of ResName slot 0x385 (table 0xe2f488, 25 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x85): "", "", "CycClrSw", "",
; [nakarest] "CycRecClrStr", "CycRecClrSw", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x754E, 0x6E
; [nakarest] naka_effects_seq+0x75bc  +0x75bc..+0x75ee (0xe2f560, 50 B)
; [nakarest] the table itself: ResName slot 0x386 (table 0xe2f560, 11 entries, InitializeKubo),
; [nakarest] 11 entry pointers x 4 bytes.
InitializeKubo_PtrTable_45:	.incbin "includes/generated/naka_effects_seq.bin", 0x75BC, 0x32
; [nakarest] naka_effects_seq+0x75ee  +0x75ee..+0x760e (0xe2f592, 32 B)
; [nakarest] name strings, entries 0-10 of ResName slot 0x386 (table 0xe2f560, 11 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x86): "", "", "", "MetCycRecSw", "", "",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x75EE, 0x20
; [nakarest] naka_effects_seq+0x760e  +0x760e..+0x7674 (0xe2f5b2, 102 B)
; [nakarest] the table itself: ResName slot 0x387 (table 0xe2f5b2, 24 entries, InitializeKubo),
; [nakarest] 24 entry pointers x 4 bytes.
InitializeKubo_PtrTable_46:	.incbin "includes/generated/naka_effects_seq.bin", 0x760E, 0x66
; [nakarest] naka_effects_seq+0x7674  +0x7674..+0x76c6 (0xe2f618, 82 B)
; [nakarest] name strings, entries 0-23 of ResName slot 0x387 (table 0xe2f5b2, 24 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x87): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7674, 0x52
; [nakarest] naka_effects_seq+0x76c6  +0x76c6..+0x76fc (0xe2f66a, 54 B)
; [nakarest] the table itself: ResName slot 0x388 (table 0xe2f66a, 12 entries, InitializeKubo),
; [nakarest] 12 entry pointers x 4 bytes.
InitializeKubo_PtrTable_47:	.incbin "includes/generated/naka_effects_seq.bin", 0x76C6, 0x36
; [nakarest] naka_effects_seq+0x76fc  +0x76fc..+0x771e (0xe2f6a0, 34 B)
; [nakarest] name strings, entries 0-11 of ResName slot 0x388 (table 0xe2f66a, 12 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x88): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x76FC, 0x22
; [nakarest] naka_effects_seq+0x771e  +0x771e..+0x7734 (0xe2f6c2, 22 B)
; [nakarest] the table itself: ResName slot 0x38d (table 0xe2f6c2, 4 entries, InitializeKubo), 4
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_48:	.incbin "includes/generated/naka_effects_seq.bin", 0x771E, 0x16
; [nakarest] naka_effects_seq+0x7734  +0x7734..+0x773c (0xe2f6d8, 8 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x38d (table 0xe2f6c2, 4 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x8d): "", "", "", "".
	.incbin "includes/generated/naka_effects_seq.bin", 0x7734, 0x8
; [nakarest] naka_effects_seq+0x773c  +0x773c..+0x7786 (0xe2f6e0, 74 B)
; [nakarest] the table itself: ResName slot 0x390 (table 0xe2f6e0, 17 entries, InitializeKubo),
; [nakarest] 17 entry pointers x 4 bytes.
InitializeKubo_PtrTable_49:	.incbin "includes/generated/naka_effects_seq.bin", 0x773C, 0x4A
; [nakarest] naka_effects_seq+0x7786  +0x7786..+0x77b4 (0xe2f72a, 46 B)
; [nakarest] name strings, entries 0-16 of ResName slot 0x390 (table 0xe2f6e0, 17 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x90): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7786, 0x2E
; [nakarest] naka_effects_seq+0x77b4  +0x77b4..+0x7806 (0xe2f758, 82 B)
; [nakarest] the table itself: ResName slot 0x391 (table 0xe2f758, 19 entries, InitializeKubo),
; [nakarest] 19 entry pointers x 4 bytes.
InitializeKubo_PtrTable_50:	.incbin "includes/generated/naka_effects_seq.bin", 0x77B4, 0x52
; [nakarest] naka_effects_seq+0x7806  +0x7806..+0x7838 (0xe2f7aa, 50 B)
; [nakarest] name strings, entries 0-18 of ResName slot 0x391 (table 0xe2f758, 19 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x91): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7806, 0x32
; [nakarest] naka_effects_seq+0x7838  +0x7838..+0x78a6 (0xe2f7dc, 110 B)
; [nakarest] the table itself: ResName slot 0x393 (table 0xe2f7dc, 26 entries, InitializeKubo),
; [nakarest] 26 entry pointers x 4 bytes.
InitializeKubo_PtrTable_51:	.incbin "includes/generated/naka_effects_seq.bin", 0x7838, 0x6E
; [nakarest] naka_effects_seq+0x78a6  +0x78a6..+0x78f4 (0xe2f84a, 78 B)
; [nakarest] name strings, entries 0-25 of ResName slot 0x393 (table 0xe2f7dc, 26 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x93): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x78A6, 0x4E
; [nakarest] naka_effects_seq+0x78f4  +0x78f4..+0x790a (0xe2f898, 22 B)
; [nakarest] the table itself: ResName slot 0x394 (table 0xe2f898, 4 entries, InitializeKubo), 4
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_52:	.incbin "includes/generated/naka_effects_seq.bin", 0x78F4, 0x16
; [nakarest] naka_effects_seq+0x790a  +0x790a..+0x7912 (0xe2f8ae, 8 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x394 (table 0xe2f898, 4 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x94): "", "", "", "".
	.incbin "includes/generated/naka_effects_seq.bin", 0x790A, 0x8
; [nakarest] naka_effects_seq+0x7912  +0x7912..+0x7984 (0xe2f8b6, 114 B)
; [nakarest] the table itself: ResName slot 0x395 (table 0xe2f8b6, 27 entries, InitializeKubo),
; [nakarest] 27 entry pointers x 4 bytes.
InitializeKubo_PtrTable_53:	.incbin "includes/generated/naka_effects_seq.bin", 0x7912, 0x72
; [nakarest] naka_effects_seq+0x7984  +0x7984..+0x79c2 (0xe2f928, 62 B)
; [nakarest] name strings, entries 0-26 of ResName slot 0x395 (table 0xe2f8b6, 27 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x95): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7984, 0x3E
; [nakarest] naka_effects_seq+0x79c2  +0x79c2..+0x79e8 (0xe2f966, 38 B)
; [nakarest] the table itself: ResName slot 0x396 (table 0xe2f966, 8 entries, InitializeKubo), 8
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_54:	.incbin "includes/generated/naka_effects_seq.bin", 0x79C2, 0x26
; [nakarest] naka_effects_seq+0x79e8  +0x79e8..+0x79f8 (0xe2f98c, 16 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x396 (table 0xe2f966, 8 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x96): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x79E8, 0x10
; [nakarest] naka_effects_seq+0x79f8  +0x79f8..+0x7a0e (0xe2f99c, 22 B)
; [nakarest] the table itself: ResName slot 0x397 (table 0xe2f99c, 4 entries, InitializeKubo), 4
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_55:	.incbin "includes/generated/naka_effects_seq.bin", 0x79F8, 0x16
; [nakarest] naka_effects_seq+0x7a0e  +0x7a0e..+0x7a16 (0xe2f9b2, 8 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x397 (table 0xe2f99c, 4 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x97): "", "", "", "".
	.incbin "includes/generated/naka_effects_seq.bin", 0x7A0E, 0x8
; [nakarest] naka_effects_seq+0x7a16  +0x7a16..+0x7a84 (0xe2f9ba, 110 B)
; [nakarest] the table itself: ResName slot 0x398 (table 0xe2f9ba, 26 entries, InitializeKubo),
; [nakarest] 26 entry pointers x 4 bytes.
InitializeKubo_PtrTable_56:	.incbin "includes/generated/naka_effects_seq.bin", 0x7A16, 0x6E
; [nakarest] naka_effects_seq+0x7a84  +0x7a84..+0x7ac0 (0xe2fa28, 60 B)
; [nakarest] name strings, entries 0-25 of ResName slot 0x398 (table 0xe2f9ba, 26 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x98): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7A84, 0x3C
; [nakarest] naka_effects_seq+0x7ac0  +0x7ac0..+0x7ae6 (0xe2fa64, 38 B)
; [nakarest] the table itself: ResName slot 0x399 (table 0xe2fa64, 8 entries, InitializeKubo), 8
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_57:	.incbin "includes/generated/naka_effects_seq.bin", 0x7AC0, 0x26
; [nakarest] naka_effects_seq+0x7ae6  +0x7ae6..+0x7af6 (0xe2fa8a, 16 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x399 (table 0xe2fa64, 8 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x99): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7AE6, 0x10
; [nakarest] naka_effects_seq+0x7af6  +0x7af6..+0x7b34 (0xe2fa9a, 62 B)
; [nakarest] the table itself: ResName slot 0x39a (table 0xe2fa9a, 14 entries, InitializeKubo),
; [nakarest] 14 entry pointers x 4 bytes.
InitializeKubo_PtrTable_58:	.incbin "includes/generated/naka_effects_seq.bin", 0x7AF6, 0x3E
; [nakarest] naka_effects_seq+0x7b34  +0x7b34..+0x7b5e (0xe2fad8, 42 B)
; [nakarest] name strings, entries 0-13 of ResName slot 0x39a (table 0xe2fa9a, 14 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9a): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7B34, 0x2A
; [nakarest] naka_effects_seq+0x7b5e  +0x7b5e..+0x7bbc (0xe2fb02, 94 B)
; [nakarest] the table itself: ResName slot 0x39b (table 0xe2fb02, 22 entries, InitializeKubo),
; [nakarest] 22 entry pointers x 4 bytes.
InitializeKubo_PtrTable_59:	.incbin "includes/generated/naka_effects_seq.bin", 0x7B5E, 0x5E
; [nakarest] naka_effects_seq+0x7bbc  +0x7bbc..+0x7bf6 (0xe2fb60, 58 B)
; [nakarest] name strings, entries 0-21 of ResName slot 0x39b (table 0xe2fb02, 22 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9b): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7BBC, 0x3A
; [nakarest] naka_effects_seq+0x7bf6  +0x7bf6..+0x7c50 (0xe2fb9a, 90 B)
; [nakarest] the table itself: ResName slot 0x39c (table 0xe2fb9a, 21 entries, InitializeKubo),
; [nakarest] 21 entry pointers x 4 bytes.
InitializeKubo_PtrTable_60:	.incbin "includes/generated/naka_effects_seq.bin", 0x7BF6, 0x5A
; [nakarest] naka_effects_seq+0x7c50  +0x7c50..+0x7c84 (0xe2fbf4, 52 B)
; [nakarest] name strings, entries 0-20 of ResName slot 0x39c (table 0xe2fb9a, 21 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9c): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7C50, 0x34
; [nakarest] naka_effects_seq+0x7c84  +0x7c84..+0x7cca (0xe2fc28, 70 B)
; [nakarest] the table itself: ResName slot 0x39d (table 0xe2fc28, 16 entries, InitializeKubo),
; [nakarest] 16 entry pointers x 4 bytes.
InitializeKubo_PtrTable_61:	.incbin "includes/generated/naka_effects_seq.bin", 0x7C84, 0x46
; [nakarest] naka_effects_seq+0x7cca  +0x7cca..+0x7cf6 (0xe2fc6e, 44 B)
; [nakarest] name strings, entries 0-15 of ResName slot 0x39d (table 0xe2fc28, 16 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9d): "", "", "", "", "", "TrnsSureDisp",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7CCA, 0x2C
; [nakarest] naka_effects_seq+0x7cf6  +0x7cf6..+0x7d3c (0xe2fc9a, 70 B)
; [nakarest] the table itself: ResName slot 0x39e (table 0xe2fc9a, 16 entries, InitializeKubo),
; [nakarest] 16 entry pointers x 4 bytes.
InitializeKubo_PtrTable_62:	.incbin "includes/generated/naka_effects_seq.bin", 0x7CF6, 0x46
; [nakarest] naka_effects_seq+0x7d3c  +0x7d3c..+0x7d68 (0xe2fce0, 44 B)
; [nakarest] name strings, entries 0-15 of ResName slot 0x39e (table 0xe2fc9a, 16 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9e): "", "", "", "", "", "VeloSureDisp",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7D3C, 0x2C
; [nakarest] naka_effects_seq+0x7d68  +0x7d68..+0x7dd2 (0xe2fd0c, 106 B)
; [nakarest] the table itself: ResName slot 0x39f (table 0xe2fd0c, 25 entries, InitializeKubo),
; [nakarest] 25 entry pointers x 4 bytes.
InitializeKubo_PtrTable_63:	.incbin "includes/generated/naka_effects_seq.bin", 0x7D68, 0x6A
; [nakarest] naka_effects_seq+0x7dd2  +0x7dd2..+0x7e10 (0xe2fd76, 62 B)
; [nakarest] name strings, entries 0-24 of ResName slot 0x39f (table 0xe2fd0c, 25 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0x9f): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7DD2, 0x3E
; [nakarest] naka_effects_seq+0x7e10  +0x7e10..+0x7e56 (0xe2fdb4, 70 B)
; [nakarest] the table itself: ResName slot 0x3a0 (table 0xe2fdb4, 16 entries, InitializeKubo),
; [nakarest] 16 entry pointers x 4 bytes.
InitializeKubo_PtrTable_64:	.incbin "includes/generated/naka_effects_seq.bin", 0x7E10, 0x46
; [nakarest] naka_effects_seq+0x7e56  +0x7e56..+0x7e80 (0xe2fdfa, 42 B)
; [nakarest] name strings, entries 0-15 of ResName slot 0x3a0 (table 0xe2fdb4, 16 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa0): "", "", "", "", "", "AdvSureDisp",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7E56, 0x2A
; [nakarest] naka_effects_seq+0x7e80  +0x7e80..+0x7ec6 (0xe2fe24, 70 B)
; [nakarest] the table itself: ResName slot 0x3a1 (table 0xe2fe24, 16 entries, InitializeKubo),
; [nakarest] 16 entry pointers x 4 bytes.
InitializeKubo_PtrTable_65:	.incbin "includes/generated/naka_effects_seq.bin", 0x7E80, 0x46
; [nakarest] naka_effects_seq+0x7ec6  +0x7ec6..+0x7ef2 (0xe2fe6a, 44 B)
; [nakarest] name strings, entries 0-15 of ResName slot 0x3a1 (table 0xe2fe24, 16 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa1): "", "", "", "", "", "MersSureDisp",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7EC6, 0x2C
; [nakarest] naka_effects_seq+0x7ef2  +0x7ef2..+0x7f3c (0xe2fe96, 74 B)
; [nakarest] the table itself: ResName slot 0x3a2 (table 0xe2fe96, 17 entries, InitializeKubo),
; [nakarest] 17 entry pointers x 4 bytes.
InitializeKubo_PtrTable_66:	.incbin "includes/generated/naka_effects_seq.bin", 0x7EF2, 0x4A
; [nakarest] naka_effects_seq+0x7f3c  +0x7f3c..+0x7f68 (0xe2fee0, 44 B)
; [nakarest] name strings, entries 0-16 of ResName slot 0x3a2 (table 0xe2fe96, 17 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa2): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7F3C, 0x2C
; [nakarest] naka_effects_seq+0x7f68  +0x7f68..+0x7faa (0xe2ff0c, 66 B)
; [nakarest] the table itself: ResName slot 0x3a3 (table 0xe2ff0c, 15 entries, InitializeKubo),
; [nakarest] 15 entry pointers x 4 bytes.
InitializeKubo_PtrTable_67:	.incbin "includes/generated/naka_effects_seq.bin", 0x7F68, 0x42
; [nakarest] naka_effects_seq+0x7faa  +0x7faa..+0x7fd4 (0xe2ff4e, 42 B)
; [nakarest] name strings, entries 0-14 of ResName slot 0x3a3 (table 0xe2ff0c, 15 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa3): "", "", "", "", "", "MdelSureDisp",
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x7FAA, 0x2A
; [nakarest] naka_effects_seq+0x7fd4  +0x7fd4..+0x801e (0xe2ff78, 74 B)
; [nakarest] the table itself: ResName slot 0x3a4 (table 0xe2ff78, 17 entries, InitializeKubo),
; [nakarest] 17 entry pointers x 4 bytes.
InitializeKubo_PtrTable_68:	.incbin "includes/generated/naka_effects_seq.bin", 0x7FD4, 0x4A
; [nakarest] naka_effects_seq+0x801e  +0x801e..+0x804c (0xe2ffc2, 46 B)
; [nakarest] name strings, entries 0-16 of ResName slot 0x3a4 (table 0xe2ff78, 17 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xa4): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x801E, 0x2E
; [nakarest] naka_effects_seq+0x804c  +0x804c..+0x8052 (0xe2fff0, 6 B)
; [nakarest] the table itself: ResName slot 0x3a8 (table 0xe2fff0, 0 entries, InitializeKubo), 0
; [nakarest] entry pointers x 4 bytes.
Kubo_ResNameTable_3A8:	.incbin "includes/generated/naka_effects_seq.bin", 0x804C, 0x6
; [nakarest] naka_effects_seq+0x8052  +0x8052..+0x8058 (0xe2fff6, 6 B)
; [nakarest] the table itself: ResName slot 0x3aa (table 0xe2fff6, 0 entries, InitializeKubo), 0
; [nakarest] entry pointers x 4 bytes.
Kubo_ResNameTable_3AA:	.incbin "includes/generated/naka_effects_seq.bin", 0x8052, 0x6
; [nakarest] naka_effects_seq+0x8058  +0x8058..+0x8066 (0xe2fffc, 14 B)
; [nakarest] the table itself: ResName slot 0x3ab (table 0xe2fffc, 2 entries, InitializeKubo), 2
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_69:	.incbin "includes/generated/naka_effects_seq.bin", 0x8058, 0x4
InitializeYoko_PtrTable:	.incbin "includes/generated/naka_effects_seq.bin", 0x805C, 0x1	; 2 x 32-bit pointer
NakaData_EffectsBlock_Byte1:	.incbin "includes/generated/naka_effects_seq.bin", 0x805D, 0x1
NakaData_EffectsBlock_Byte2:	.incbin "includes/generated/naka_effects_seq.bin", 0x805E, 0x1
NakaData_EffectsBlock_Byte3:	.incbin "includes/generated/naka_effects_seq.bin", 0x805F, 0x2
NakaData_EffectsBlock_Byte5:	.incbin "includes/generated/naka_effects_seq.bin", 0x8061, 0x1
NakaData_EffectsStringPtrs:	.incbin "includes/generated/naka_effects_seq.bin", 0x8062, 0x4
; [nakarest] naka_effects_seq+0x8066  +0x8066..+0x806a (0xe3000a, 4 B)
; [nakarest] name strings, entries 0-1 of ResName slot 0x3ab (table 0xe2fffc, 2 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xab): "", "".
	.incbin "includes/generated/naka_effects_seq.bin", 0x8066, 0x1
CDlikeSwTtl_SetRecordAndNotify_Data_2:	.incbin "includes/generated/naka_effects_seq.bin", 0x8067, 0x3
; [nakarest] naka_effects_seq+0x806a  +0x806a..+0x80ac (0xe3000e, 66 B)
; [nakarest] the table itself: ResName slot 0x3d6 (table 0xe3000e, 15 entries, InitializeKubo),
; [nakarest] 15 entry pointers x 4 bytes.
InitializeKubo_PtrTable_70:	.incbin "includes/generated/naka_effects_seq.bin", 0x806A, 0x42
; [nakarest] naka_effects_seq+0x80ac  +0x80ac..+0x80fa (0xe30050, 78 B)
; [nakarest] name strings, entries 0-14 of ResName slot 0x3d6 (table 0xe3000e, 15 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xd6): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x80AC, 0x4E
; [nakarest] naka_effects_seq+0x80fa  +0x80fa..+0x811c (0xe3009e, 34 B)
; [nakarest] the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries, InitializeKubo),
; [nakarest] 61 entry pointers x 4 bytes.
InitializeKubo_PtrTable_71:	.incbin "includes/generated/naka_effects_seq.bin", 0x80FA, 0x22
; [nakarest] Naka_Help_563_E300C0  +0x811c..+0x8123 (0xe300c0, 7 B)
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 210 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_563_E300C0:
	.incbin "includes/generated/naka_effects_seq.bin", 0x811C, 0x7
; [nakarest] Naka_Help_564_E300C7  +0x8123..+0x8128 (0xe300c7, 5 B)
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 203 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_564_E300C7:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8123, 0x5
; [nakarest] Naka_Help_565_E300CC  +0x8128..+0x813f (0xe300cc, 23 B)
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 198 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_565_E300CC:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8128, 0x17
; [nakarest] Naka_Help_566_E300E3  +0x813f..+0x8148 (0xe300e3, 9 B)
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 175 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_566_E300E3:
	.incbin "includes/generated/naka_effects_seq.bin", 0x813F, 0x9
; [nakarest] Naka_Help_567_E300EC  +0x8148..+0x816f (0xe300ec, 39 B)
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 166 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_567_E300EC:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8148, 0x27
; [nakarest] Naka_Help_569_E30113  +0x816f..+0x81f4 (0xe30113, 133 B)
; [nakarest] 6 B at 0xe30192: the end marker of ResName slot 0x3e7 (table 0xe3009e, 61 entries, InitializeKubo) -- entry 61, a pointer to the empty string right after it ("", 00 ff), as every ResName table ends.
; [nakarest] Continues the table itself: ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo), 61 entry pointers x 4 bytes (starts 0xe3009e, 127 of its 244 bytes
; [nakarest] are here or later).
Naka_Help_569_E30113:
	.incbin "includes/generated/naka_effects_seq.bin", 0x816F, 0x85
; [nakarest] naka_effects_seq+0x81f4  +0x81f4..+0x8578 (0xe30198, 900 B)
; [nakarest] name strings, entries 0-60 of ResName slot 0x3e7 (table 0xe3009e, 61 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xe7): "", "HelpLang4P4", "",
; [nakarest] "HelpLang4P3", "", "HelpLang4P2", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x81F4, 0x160
InitializeKubo_Str_MD_ENTERTAINER:	.incbin "includes/generated/naka_effects_seq.bin", 0x8354, 0x10	; "MD_ENTERTAINER"
InitializeKubo_Str_MD_SEQ:		.incbin "includes/generated/naka_effects_seq.bin", 0x8364, 0x8	; "MD_SEQ"
InitializeKubo_Str_MD_SEQ_EREC:		.incbin "includes/generated/naka_effects_seq.bin", 0x836C, 0xC	; "MD_SEQ_EREC"
InitializeKubo_Str_MD_SEQ_PLAY:		.incbin "includes/generated/naka_effects_seq.bin", 0x8378, 0xC	; "MD_SEQ_PLAY"
InitializeKubo_Str_MD_SEQ_REAL:		.incbin "includes/generated/naka_effects_seq.bin", 0x8384, 0xC	; "MD_SEQ_REAL"
InitializeKubo_Str_MD_SEQ_EDIT:		.incbin "includes/generated/naka_effects_seq.bin", 0x8390, 0xC	; "MD_SEQ_EDIT"
InitializeKubo_Str_MD_HELP:		.incbin "includes/generated/naka_effects_seq.bin", 0x839C, 0x8	; "MD_HELP"
InitializeKubo_Str_TT_SDREVSET:		.incbin "includes/generated/naka_effects_seq.bin", 0x83A4, 0xC	; "TT_SDREVSET"
InitializeKubo_Str_TT_SDDSPEFF:		.incbin "includes/generated/naka_effects_seq.bin", 0x83B0, 0xC	; "TT_SDDSPEFF"
InitializeKubo_Str_TT_SDEQUALIZER:	.incbin "includes/generated/naka_effects_seq.bin", 0x83BC, 0x10	; "TT_SDEQUALIZER"
InitializeKubo_Str_TT_SDACCILL:		.incbin "includes/generated/naka_effects_seq.bin", 0x83CC, 0xC	; "TT_SDACCILL"
InitializeKubo_Str_TT_SQMENU:		.incbin "includes/generated/naka_effects_seq.bin", 0x83D8, 0xA	; "TT_SQMENU"
InitializeKubo_Str_TT_SQPLAY:		.incbin "includes/generated/naka_effects_seq.bin", 0x83E2, 0xA	; "TT_SQPLAY"
InitializeKubo_Str_TT_SQCYCPLY:		.incbin "includes/generated/naka_effects_seq.bin", 0x83EC, 0xC	; "TT_SQCYCPLY"
InitializeKubo_Str_TT_SQEASYREC:	.incbin "includes/generated/naka_effects_seq.bin", 0x83F8, 0xE	; "TT_SQEASYREC"
InitializeKubo_Str_TT_SQCMENU:		.incbin "includes/generated/naka_effects_seq.bin", 0x8406, 0xC	; "TT_SQCMENU"
InitializeKubo_Str_TT_SQREALREC:	.incbin "includes/generated/naka_effects_seq.bin", 0x8412, 0xE	; "TT_SQREALREC"
InitializeKubo_Str_TT_SQCYCREC:		.incbin "includes/generated/naka_effects_seq.bin", 0x8420, 0xC	; "TT_SQCYCREC"
InitializeKubo_Str_TT_SQPUNCH:		.incbin "includes/generated/naka_effects_seq.bin", 0x842C, 0xC	; "TT_SQPUNCH"
InitializeKubo_Str_TT_SQPUNCHM:		.incbin "includes/generated/naka_effects_seq.bin", 0x8438, 0xC	; "TT_SQPUNCHM"
InitializeKubo_Str_TT_SQPNLWR:		.incbin "includes/generated/naka_effects_seq.bin", 0x8444, 0xC	; "TT_SQPNLWR"
InitializeKubo_Str_TT_SQSNGCLR:		.incbin "includes/generated/naka_effects_seq.bin", 0x8450, 0xC	; "TT_SQSNGCLR"
InitializeKubo_Str_TT_SQSNGCP:		.incbin "includes/generated/naka_effects_seq.bin", 0x845C, 0xC	; "TT_SQSNGCP"
InitializeKubo_Str_TT_SQEMENU:		.incbin "includes/generated/naka_effects_seq.bin", 0x8468, 0xC	; "TT_SQEMENU"
InitializeKubo_Str_TT_SQNOTESEL:	.incbin "includes/generated/naka_effects_seq.bin", 0x8474, 0xE	; "TT_SQNOTESEL"
InitializeKubo_Str_TT_SQNOTEEDT:	.incbin "includes/generated/naka_effects_seq.bin", 0x8482, 0xE	; "TT_SQNOTEEDT"
InitializeKubo_Str_TT_SQNOTECYCP:	.incbin "includes/generated/naka_effects_seq.bin", 0x8490, 0xE	; "TT_SQNOTECYCP"
InitializeKubo_Str_TT_SQDRMSEL:		.incbin "includes/generated/naka_effects_seq.bin", 0x849E, 0xC	; "TT_SQDRMSEL"
InitializeKubo_Str_TT_SQDRMEDT:		.incbin "includes/generated/naka_effects_seq.bin", 0x84AA, 0xC	; "TT_SQDRMEDT"
InitializeKubo_Str_TT_SQDRMCYCP:	.incbin "includes/generated/naka_effects_seq.bin", 0x84B6, 0xE	; "TT_SQDRMCYCP"
InitializeKubo_Str_TT_SQTRKCLR:		.incbin "includes/generated/naka_effects_seq.bin", 0x84C4, 0xC	; "TT_SQTRKCLR"
InitializeKubo_Str_TT_SQTRKMRG:		.incbin "includes/generated/naka_effects_seq.bin", 0x84D0, 0xC	; "TT_SQTRKMRG"
InitializeKubo_Str_TT_SQQTZ:		.incbin "includes/generated/naka_effects_seq.bin", 0x84DC, 0xA	; "TT_SQQTZ"
InitializeKubo_Str_TT_SQTRNS:		.incbin "includes/generated/naka_effects_seq.bin", 0x84E6, 0xA	; "TT_SQTRNS"
InitializeKubo_Str_TT_SQVELOCNG:	.incbin "includes/generated/naka_effects_seq.bin", 0x84F0, 0xE	; "TT_SQVELOCNG"
InitializeKubo_Str_TT_SQNOTECNG:	.incbin "includes/generated/naka_effects_seq.bin", 0x84FE, 0xE	; "TT_SQNOTECNG"
InitializeKubo_Str_TT_SQADVDLY:		.incbin "includes/generated/naka_effects_seq.bin", 0x850C, 0xC	; "TT_SQADVDLY"
InitializeKubo_Str_TT_SQMERS:		.incbin "includes/generated/naka_effects_seq.bin", 0x8518, 0xA	; "TT_SQMERS"
InitializeKubo_Str_TT_SQMCP:		.incbin "includes/generated/naka_effects_seq.bin", 0x8522, 0xA	; "TT_SQMCP"
InitializeKubo_Str_TT_SQMDEL:		.incbin "includes/generated/naka_effects_seq.bin", 0x852C, 0xA	; "TT_SQMDEL"
InitializeKubo_Str_TT_SQMINS:		.incbin "includes/generated/naka_effects_seq.bin", 0x8536, 0xA	; "TT_SQMINS"
InitializeKubo_Str_TT_SQSNGCPC:		.incbin "includes/generated/naka_effects_seq.bin", 0x8540, 0xC	; "TT_SQSNGCPC"
InitializeKubo_Str_TT_SQPNLWRM:		.incbin "includes/generated/naka_effects_seq.bin", 0x854C, 0xC	; "TT_SQPNLWRM"
InitializeKubo_Str_TT_SQMETBAL:		.incbin "includes/generated/naka_effects_seq.bin", 0x8558, 0xC	; "TT_SQMETBAL"
InitializeKubo_Str_TT_ETMENU:		.incbin "includes/generated/naka_effects_seq.bin", 0x8564, 0xA	; "TT_ETMENU"
InitializeKubo_Str_TT_SWHELP:		.incbin "includes/generated/naka_effects_seq.bin", 0x856E, 0xA	; "TT_SWHELP"
; [nakarest] naka_effects_seq+0x8578  +0x8578..+0x8600 (0xe3051c, 136 B)
; [nakarest] the table itself: MainFunction slot 0x148 (table 0xe3051c, 44 entries,
; [nakarest] InitializeKubo), 44 entry pointers x 4 bytes.
Kubo_MainFunctionTable_148:	.incbin "includes/generated/naka_effects_seq.bin", 0x8578, 0x88
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
InitializeKubo_PtrTable_72:	.long FuncName_ApEditSyori
	.long FuncName_MainExeCall
	.long FuncName_EffEditMain
	.long FuncName_ApPlaySyori_Kubo
	.long FuncName_SeqModeFunc
	.long FuncName_SeqRealModeFunc
	.long FuncName_SeqPlayModeFunc
	.long FuncName_SeqErecModeFunc
	.long FuncName_SeqEditModeFunc
	.long FuncName_SqRealRecTitleFunc
	.long FuncName_SqPlayTitleFunc
	.long FuncName_SqPunchTitleFunc
	.long FuncName_SqPunchmTitleFunc
	.long FuncName_SqQtzTitleFunc
	.long FuncName_SqMdelTitleFunc
	.long FuncName_SqMersTitleFunc
	.long FuncName_SqVcngTitleFunc
	.long FuncName_SqTrnsTitleFunc
	.long FuncName_SqNcngTitleFunc
	.long FuncName_SqSoclTitleFunc
	.long FuncName_SqMcpyTitleFunc
	.long FuncName_SqMinsTitleFunc
	.long FuncName_SqTrclTitleFunc
	.long FuncName_SqSngcpTitleFunc
	.long FuncName_SqTrmgTitleFunc
	.long FuncName_SqAdlyTitleFunc
	.long FuncName_SqDrmEdtTitleFunc
	.long FuncName_SqDrmSelTitleFunc
	.long FuncName_SqNoteEdtTitleFunc
	.long FuncName_SqNoteSelTitleFunc
	.long FuncName_SngSelSyori
	.long FuncName_NoteEditSyori
	.long FuncName_SdRevsetTitleFunc
	.long FuncName_SdDspeffTitleFunc
	.long FuncName_SdAccillTitleFunc
	.long FuncName_MimeSyori
	.long FuncName_SqNoteCycpTitleFunc
	.long FuncName_SqDrmCycpTitleFunc
	.long FuncName_HelpModeFunc
	.long FuncName_HelpTitleFunc
	.long FuncName_HelpLangChkMain
	.long FuncName_HelpFlashFunc
	.long FuncName_EtmenuTitleFunc
	.long FuncName_MainPanic
	.long InitializeKubo_PtrTable_72_EndName
; [nakarest] naka_effects_seq+0x86e0  +0x86e0..+0x86e2 (0xe30684, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe30684 not derived; readers below
; [nakarest] Readers: source references Kubo_MainFunctionTable_148
; [nakarest] (ui_widgets/effects_sequencer_screens.s: `.long 0x00e30684`); 1 data word in
; [nakarest] Kubo_MainFunctionTable_148 (at 0xe30680).
InitializeKubo_PtrTable_72_EndName:	.incbin "includes/generated/naka_effects_seq.bin", 0x86E0, 0x2
; [nakarest] naka_effects_seq+0x86e2  +0x86e2..+0x899a (0xe30686, 696 B)
; [nakarest] name strings, entries 0-43 of MainFunction slot 0x448 (table 0xe305d0, 44 entries,
; [nakarest] InitializeKubo) (names for MainFunction slot 0x148): "MainPanic",
; [nakarest] "EtmenuTitleFunc", "HelpFlashFunc", "HelpLangChkMain", "HelpTitleFunc",
; [nakarest] "HelpModeFunc", ....
FuncName_MainPanic:		.incbin "includes/generated/naka_effects_seq.bin", 0x86E2, 0xA
FuncName_EtmenuTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x86EC, 0x10
FuncName_HelpFlashFunc:		.incbin "includes/generated/naka_effects_seq.bin", 0x86FC, 0xE
FuncName_HelpLangChkMain:	.incbin "includes/generated/naka_effects_seq.bin", 0x870A, 0x10
FuncName_HelpTitleFunc:		.incbin "includes/generated/naka_effects_seq.bin", 0x871A, 0xE
FuncName_HelpModeFunc:		.incbin "includes/generated/naka_effects_seq.bin", 0x8728, 0xE
FuncName_SqDrmCycpTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8736, 0x14
FuncName_SqNoteCycpTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x874A, 0x14
FuncName_MimeSyori:		.incbin "includes/generated/naka_effects_seq.bin", 0x875E, 0xA
FuncName_SdAccillTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8768, 0x12
FuncName_SdDspeffTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x877A, 0x12
FuncName_SdRevsetTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x878C, 0x12
FuncName_NoteEditSyori:		.incbin "includes/generated/naka_effects_seq.bin", 0x879E, 0xE
FuncName_SngSelSyori:		.incbin "includes/generated/naka_effects_seq.bin", 0x87AC, 0xC
FuncName_SqNoteSelTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x87B8, 0x14
FuncName_SqNoteEdtTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x87CC, 0x14
FuncName_SqDrmSelTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x87E0, 0x12
FuncName_SqDrmEdtTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x87F2, 0x12
FuncName_SqAdlyTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8804, 0x10
FuncName_SqTrmgTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8814, 0x10
FuncName_SqSngcpTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8824, 0x12
FuncName_SqTrclTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8836, 0x10
FuncName_SqMinsTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8846, 0x10
FuncName_SqMcpyTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8856, 0x10
FuncName_SqSoclTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8866, 0x10
FuncName_SqNcngTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8876, 0x10
FuncName_SqTrnsTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8886, 0x10
FuncName_SqVcngTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x8896, 0x10
FuncName_SqMersTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88A6, 0x10
FuncName_SqMdelTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88B6, 0x10
FuncName_SqQtzTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88C6, 0x10
FuncName_SqPunchmTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88D6, 0x12
FuncName_SqPunchTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88E8, 0x12
FuncName_SqPlayTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x88FA, 0x10
FuncName_SqRealRecTitleFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x890A, 0x14
FuncName_SeqEditModeFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x891E, 0x10
FuncName_SeqErecModeFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x892E, 0x10
FuncName_SeqPlayModeFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x893E, 0x10
FuncName_SeqRealModeFunc:	.incbin "includes/generated/naka_effects_seq.bin", 0x894E, 0x10
FuncName_SeqModeFunc:		.incbin "includes/generated/naka_effects_seq.bin", 0x895E, 0xC
FuncName_ApPlaySyori_Kubo:	.incbin "includes/generated/naka_effects_seq.bin", 0x896A, 0xC
FuncName_EffEditMain:		.incbin "includes/generated/naka_effects_seq.bin", 0x8976, 0xC
FuncName_MainExeCall:		.incbin "includes/generated/naka_effects_seq.bin", 0x8982, 0xC
FuncName_ApEditSyori:		.incbin "includes/generated/naka_effects_seq.bin", 0x898E, 0xC
; [nakarest] naka_effects_seq+0x899a  +0x899a..+0x89a2 (0xe3093e, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xe3093e not derived; readers below
; [nakarest] Readers: source references EntertainerGridCheck (sequencer/sequencer_ui.s: `ld xiy,
; [nakarest] EntertainerGridCheck_Data`).
EntertainerGridCheck_Data:
	.incbin "includes/generated/naka_effects_seq.bin", 0x899A, 0x8
; [nakarest] naka_effects_seq+0x89a2  +0x89a2..+0x8e22 (0xe30946, 1152 B)
; [nakarest] Text (1152 B at 0xe30946), first string
; [nakarest] "~43~2d~32~44~a0~bc~44~2d~32~45~a0~bc~45~2d~32~46"; no registered NAKA table points
; [nakarest] into it; reached through source references
; [nakarest] Sqedt_ParamDispatch_Join6 (sequencer/sequencer_ui.s: `lda xde,
; [nakarest] (NoteEdit_FormatTempoString_Data:24)`).
NoteEdit_FormatTempoString_Data:
	.incbin "includes/generated/naka_effects_seq.bin", 0x89A2, 0x1E4
Str_20469e32473220:	.incbin "includes/generated/naka_effects_seq.bin", 0x8B86, 0x27
Str_42a03242322043:	.incbin "includes/generated/naka_effects_seq.bin", 0x8BAD, 0x275
; [nakarest] naka_effects_seq+0x8e22  +0x8e22..+0x8e5a (0xe30dc6, 56 B)
; [nakarest] purpose not established: layout of 56 B at 0xe30dc6 not derived; readers below
; [nakarest] Readers: source references Equalizer_DispatchA (sequencer/sequencer_ui.s: `lda xde,
; [nakarest] (Equalizer_DispatchA_Data:24)`).
Equalizer_DispatchA_Data:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E22, 0x38
; [nakarest] naka_effects_seq+0x8e5a  +0x8e5a..+0x8ebc (0xe30dfe, 98 B)
; [nakarest] Text (98 B at 0xe30dfe), first string "q"; no registered NAKA table points into it;
; [nakarest] reached through source references Equalizer_DispatchA (sequencer/sequencer_ui.s:
; [nakarest] `lda xbc, (Equalizer_DispatchA_Data_2:24)`).
Equalizer_DispatchA_Data_2:
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E5A, 0x62

; External label offsets within the binary blob above.
