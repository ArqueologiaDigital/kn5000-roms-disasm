
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
	.incbin "includes/generated/naka_effects_seq.bin", 0x2, 0x1BA
; [nakarest] naka_effects_seq+0x1bc  +0x1bc..+0x37c (0xe28160, 448 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xb (table 0xe2e658, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x4, AcIndexWideES (42 B) x3,
; [nakarest] EffectBox (38 B), Box (26 B), IvIntEasySet (24 B), IvSddsp (22 B). 5 texts the
; [nakarest] records point at (Viewable slot 0xb (table 0xe2e658, 12 entries, InitializeKubo)):
; [nakarest] "DSP EFFECT" (TtlScreen.title of element 0); "TYPE :" (Label.str of element 1);
; [nakarest] "TYPE" (Label.str of element 3); "PARAMETER" (Label.str of element 6); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x1BC, 0x1C0
; [nakarest] naka_effects_seq+0x37c  +0x37c..+0x8e4 (0xe28320, 1384 B)
; [nakarest] widget records, elements 0-36 of Viewable slot 0xc (table 0xe2e68c, 37 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x8, Label (32 B) x19, Line
; [nakarest] (26 B) x6, EqualizerBox (34 B), Box (26 B), EqOnOffFuncToggle (44 B). 22 texts the
; [nakarest] records point at (Viewable slot 0xc (table 0xe2e68c, 37 entries, InitializeKubo)):
; [nakarest] "EQUALIZER" (TtlScreen.title of element 0); "FREQ" (Label.str of element 9); "GAIN"
; [nakarest] (Label.str of element 10); "FREQ" (Label.str of element 11); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x37C, 0x568
; [nakarest] naka_effects_seq+0x8e4  +0x8e4..+0xa98 (0xe28888, 436 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xe (table 0xe2e724, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x2, Label (32 B) x4, AccIll
; [nakarest] (32 B), Box (26 B) x2, IvSdacc (22 B), IvIntEasySet (24 B). 5 texts the records
; [nakarest] point at (Viewable slot 0xe (table 0xe2e724, 12 entries, InitializeKubo)):
; [nakarest] "ACOUSTIC ILLUSION" (TtlScreen.title of element 0); "TYPE" (Label.str of element
; [nakarest] 3); "LEVEL" (Label.str of element 4); "ILLUSION LEVEL:" (Label.str of element 8);
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E4, 0x1B4
; [nakarest] naka_effects_seq+0xa98  +0xa98..+0xcb0 (0xe28a3c, 536 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x80 (table 0xe2e758, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcTitleMenu (54 B) x2, Label (32 B), AcModeMenu
; [nakarest] (54 B), IvExitMode (26 B), AcIndexEditSw (40 B) x2, Box (26 B), SngSel (36 B),
; [nakarest] AcLanguageText (42 B) x2. 5 texts the records point at (Viewable slot 0x80 (table
; [nakarest] 0xe2e758, 12 entries, InitializeKubo)): "SEQUENCER MENU" (TtlScreen.title of
; [nakarest] element 0); "CREATE" (AcTitleMenu.str of element 1); "SONG" (Label.str of element
; [nakarest] 2); "EDIT" (AcModeMenu.str of element 3); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0xA98, 0x218
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
	.incbin "includes/generated/naka_effects_seq.bin", 0xCB0, 0x42C
; [nakarest] naka_effects_seq+0x10dc  +0x10dc..+0x127e (0xe29080, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x82 (table 0xe2e800, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqplyVal (32 B), PsEditBox (50 B) x3, Label (32
; [nakarest] B) x2, AcIndexWideES (42 B). 6 texts the records point at (Viewable slot 0x82
; [nakarest] (table 0xe2e800, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CYCLE START MEASURE :" (PsEditBox.caption of element 2); "CURRENT
; [nakarest] MEASURE :" (Label.str of element 3); "CYCLE :" (PsEditBox.caption of element 4);
; [nakarest] ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x10DC, 0x1A2
; [nakarest] naka_effects_seq+0x127e  +0x127e..+0x14f4 (0xe29222, 630 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x83 (table 0xe2e824, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvExitMode (26 B), AcTitleMenu (54
; [nakarest] B), Box (26 B), AcIndexEditSw (40 B) x2, SngSel (36 B), AcFuncEditSw (44 B),
; [nakarest] PsTrackSwitch (36 B) x5, AcLanguageText (42 B) x2. 3 texts the records point at
; [nakarest] (Viewable slot 0x83 (table 0xe2e824, 16 entries, InitializeKubo)): "EASY RECORD"
; [nakarest] (TtlScreen.title of element 0); "SONG" (Label.str of element 1); "NAMING"
; [nakarest] (AcTitleMenu.str of element 3).
	.incbin "includes/generated/naka_effects_seq.bin", 0x127E, 0x276
; [nakarest] naka_effects_seq+0x14f4  +0x14f4..+0x1790 (0xe29498, 668 B)
; [nakarest] widget records, elements 0-9 of Viewable slot 0x84 (table 0xe2e868, 10 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcTitleMenu (54 B) x7, AcModeMenu (54 B) x2. 10
; [nakarest] texts the records point at (Viewable slot 0x84 (table 0xe2e868, 10 entries,
; [nakarest] InitializeKubo)): "CREATE" (TtlScreen.title of element 0); "TRACK ASSIGN"
; [nakarest] (AcTitleMenu.str of element 1); "PANEL WRITE" (AcTitleMenu.str of element 2); "SONG
; [nakarest] SELECT /NAMING" (AcTitleMenu.str of element 3); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x14F4, 0x29C
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
	.incbin "includes/generated/naka_effects_seq.bin", 0x1790, 0x38E
; [nakarest] naka_effects_seq+0x1b1e  +0x1b1e..+0x1d50 (0xe29ac2, 562 B)
; [nakarest] widget records, elements 0-10 of Viewable slot 0x86 (table 0xe2e8fc, 11 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqplyVal (32 B), PsEditBox (50 B) x3, Label (32
; [nakarest] B) x3, AcIndexWideES (42 B), AcFuncToggle (44 B), AcFuncEditSw (44 B). 9 texts the
; [nakarest] records point at (Viewable slot 0x86 (table 0xe2e8fc, 11 entries, InitializeKubo)):
; [nakarest] "REALTIME RECORD" (TtlScreen.title of element 0); "CYCLE START MEASURE :"
; [nakarest] (PsEditBox.caption of element 2); "CURRENT MEASURE :" (Label.str of element 3);
; [nakarest] "CYCLE END MEASURE :" (PsEditBox.caption of element 4); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x1B1E, 0x232
; [nakarest] naka_effects_seq+0x1d50  +0x1d50..+0x20f8 (0xe29cf4, 936 B)
; [nakarest] widget records, elements 0-23 of Viewable slot 0x87 (table 0xe2e92c, 24 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvTrackSwitch (22 B), Box (26 B) x2, SqplyVal
; [nakarest] (32 B), Label (32 B) x8, AcTempoBox (36 B), TrTransposeBox (36 B), TrChordBox (36
; [nakarest] B), SngSel (36 B), AcFuncToggle (44 B) x2, AcIndexEditSw (40 B) x2, AcFuncEditSw
; [nakarest] (44 B) x2, IvPunchExit (22 B). 13 texts the records point at (Viewable slot 0x87
; [nakarest] (table 0xe2e92c, 24 entries, InitializeKubo)): "PUNCH RECORD" (TtlScreen.title of
; [nakarest] element 0); "MEASURE =" (Label.str of element 5); "TIME SIG. =" (Label.str of
; [nakarest] element 6); "MEMORY =" (Label.str of element 7); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x1D50, 0x3A8
; [nakarest] naka_effects_seq+0x20f8  +0x20f8..+0x235e (0xe2a09c, 614 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0x88 (table 0xe2e990, 12 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B) x2, AcIndexWideES (42 B), Label (32 B) x2,
; [nakarest] AcFuncToggle (44 B), SqplyVal (32 B), PsEditBox (50 B) x3, AcLanguageText (42 B),
; [nakarest] IvAutoPunchExit (22 B). 9 texts the records point at (Viewable slot 0x88 (table
; [nakarest] 0xe2e990, 12 entries, InitializeKubo)): "AUTO PUNCH RECORD" (TtlScreen.title of
; [nakarest] element 0); "MEAS" (Label.str of element 2); "CURRENT MEASURE :" (Label.str of
; [nakarest] element 3); "~a4OFF" (AcFuncToggle.stroff of element 4); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x20F8, 0x266
; [nakarest] naka_effects_seq+0x235e  +0x235e..+0x2400 (0xe2a302, 162 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x8d (table 0xe2e9c4, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcFuncEditSw (44 B), AcLanguageText (42 B),
; [nakarest] IvPnlWrExit (22 B). 1 text the records point at (Viewable slot 0x8d (table
; [nakarest] 0xe2e9c4, 4 entries, InitializeKubo)): "PANEL WRITE" (TtlScreen.title of element
; [nakarest] 0).
	.incbin "includes/generated/naka_effects_seq.bin", 0x235E, 0xA2
; [nakarest] naka_effects_seq+0x2400  +0x2400..+0x2686 (0xe2a3a4, 646 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0x90 (table 0xe2e9d8, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B) x3, SqedtVal3
; [nakarest] (30 B), Box (26 B) x2, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), AcLanguageText (42 B) x3. 5 texts the
; [nakarest] records point at (Viewable slot 0x90 (table 0xe2e9d8, 17 entries, InitializeKubo)):
; [nakarest] "SONG CLEAR" (TtlScreen.title of element 0); "SONG NO/ALL" (Label.str of element
; [nakarest] 2); ":" (Label.str of element 5); "%" (Label.str of element 6); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x2400, 0x286
; [nakarest] naka_effects_seq+0x2686  +0x2686..+0x292c (0xe2a62a, 678 B)
; [nakarest] widget records, elements 0-18 of Viewable slot 0x91 (table 0xe2ea20, 19 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqedtVal2 (30 B), SqedtFix (28 B), AcIndexWideES
; [nakarest] (42 B) x4, IvSongCopyExit (22 B) x2, MsgToTtl (22 B), AcFuncEditSw (44 B) x2,
; [nakarest] Window (36 B), Box (26 B) x3, AcScreenMenu (54 B), IvExitScreen (26 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x91 (table
; [nakarest] 0xe2ea20, 19 entries, InitializeKubo)): "SONG/TRACK COPY" (TtlScreen.title of
; [nakarest] element 0); "NO" (AcScreenMenu.str of element 15).
	.incbin "includes/generated/naka_effects_seq.bin", 0x2686, 0x2A6
; [nakarest] naka_effects_seq+0x292c  +0x292c..+0x2e34 (0xe2a8d0, 1288 B)
; [nakarest] widget records, elements 0-25 of Viewable slot 0x93 (table 0xe2ea70, 26 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvPageControl (28 B) x2, AcWindowPage (36 B),
; [nakarest] IvExitMode (26 B), IvShowHide (26 B), Window (36 B) x2, AcTitleMenu (54 B) x14,
; [nakarest] Line (26 B) x3, Label (32 B). 16 texts the records point at (Viewable slot 0x93
; [nakarest] (table 0xe2ea70, 26 entries, InitializeKubo)): "EDIT" (TtlScreen.title of element
; [nakarest] 0); "NOTE EDIT" (AcTitleMenu.str of element 7); "DRUM EDIT" (AcTitleMenu.str of
; [nakarest] element 8); "SONG/TRACK COPY" (AcTitleMenu.str of element 9); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x292C, 0x508
; [nakarest] naka_effects_seq+0x2e34  +0x2e34..+0x2ed8 (0xe2add8, 164 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x94 (table 0xe2eadc, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvTrackSwitch (22 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x94 (table
; [nakarest] 0xe2eadc, 4 entries, InitializeKubo)): "NOTE EDIT " (TtlScreen.title of element 0);
; [nakarest] ":PART SELECT" (Label.str of element 1).
	.incbin "includes/generated/naka_effects_seq.bin", 0x2E34, 0xA4
; [nakarest] naka_effects_seq+0x2ed8  +0x2ed8..+0x32ce (0xe2ae7c, 1014 B)
; [nakarest] widget records, elements 0-26 of Viewable slot 0x95 (table 0xe2eaf0, 27 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x12, Label (32 B) x10,
; [nakarest] NoteEditBox (32 B), Box (26 B), VwUserBitmap (26 B) x2. 11 texts the records point
; [nakarest] at (Viewable slot 0x95 (table 0xe2eaf0, 27 entries, InitializeKubo)): "NOTE EDIT"
; [nakarest] (TtlScreen.title of element 0); "MEAS" (Label.str of element 7); "POS" (Label.str
; [nakarest] of element 8); "NOTE" (Label.str of element 9); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x2ED8, 0x3F6
; [nakarest] naka_effects_seq+0x32ce  +0x32ce..+0x3470 (0xe2b272, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x96 (table 0xe2eb60, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x2, AcIndexWideES (42 B), SqplyVal
; [nakarest] (32 B), PsEditBox (50 B) x3. 6 texts the records point at (Viewable slot 0x96
; [nakarest] (table 0xe2eb60, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CURRENT MEASURE :" (Label.str of element 1); "VALUE" (Label.str of
; [nakarest] element 3); "SOLO :" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x32CE, 0x1A2
; [nakarest] naka_effects_seq+0x3470  +0x3470..+0x3514 (0xe2b414, 164 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x97 (table 0xe2eb84, 4 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), IvTrackSwitch (22 B),
; [nakarest] AcLanguageText (42 B). 2 texts the records point at (Viewable slot 0x97 (table
; [nakarest] 0xe2eb84, 4 entries, InitializeKubo)): "DRUM EDIT " (TtlScreen.title of element 0);
; [nakarest] ":PART SELECT" (Label.str of element 1).
	.incbin "includes/generated/naka_effects_seq.bin", 0x3470, 0xA4
; [nakarest] naka_effects_seq+0x3514  +0x3514..+0x38e2 (0xe2b4b8, 974 B)
; [nakarest] widget records, elements 0-25 of Viewable slot 0x98 (table 0xe2eb98, 26 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexEditSw (40 B) x11, Label (32 B) x10, Box
; [nakarest] (26 B), NoteEditBox (32 B), VwUserBitmap (26 B) x2. 11 texts the records point at
; [nakarest] (Viewable slot 0x98 (table 0xe2eb98, 26 entries, InitializeKubo)): "DRUM EDIT"
; [nakarest] (TtlScreen.title of element 0); "MEAS" (Label.str of element 7); "POS" (Label.str
; [nakarest] of element 8); "SND" (Label.str of element 9); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x3514, 0x3CE
; [nakarest] naka_effects_seq+0x38e2  +0x38e2..+0x3a84 (0xe2b886, 418 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x99 (table 0xe2ec04, 8 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x2, AcIndexWideES (42 B), SqplyVal
; [nakarest] (32 B), PsEditBox (50 B) x3. 6 texts the records point at (Viewable slot 0x99
; [nakarest] (table 0xe2ec04, 8 entries, InitializeKubo)): "CYCLE PLAY" (TtlScreen.title of
; [nakarest] element 0); "CURRENT MEASURE :" (Label.str of element 1); "VALUE" (Label.str of
; [nakarest] element 3); "SOLO :" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x38E2, 0x1A2
; [nakarest] naka_effects_seq+0x3a84  +0x3a84..+0x3ca4 (0xe2ba28, 544 B)
; [nakarest] widget records, elements 0-13 of Viewable slot 0x9a (table 0xe2ec28, 14 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), IvTrackSwitch (22 B), MsgToTtl (22 B),
; [nakarest] AcLanguageText (42 B) x5, AcFuncEditSw (44 B) x2, Window (36 B), AcScreenMenu (54
; [nakarest] B), VwBox (28 B), IvExitScreen (26 B). 2 texts the records point at (Viewable slot
; [nakarest] 0x9a (table 0xe2ec28, 14 entries, InitializeKubo)): "TRACK CLEAR" (TtlScreen.title
; [nakarest] of element 0); "NO" (AcScreenMenu.str of element 8).
	.incbin "includes/generated/naka_effects_seq.bin", 0x3A84, 0x220
; [nakarest] naka_effects_seq+0x3ca4  +0x3ca4..+0x3fd8 (0xe2bc48, 820 B)
; [nakarest] widget records, elements 0-21 of Viewable slot 0x9b (table 0xe2ec64, 22 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Line (26 B) x6, AcIndexWideES (42 B), Label (32
; [nakarest] B), SqedtVal (32 B), PsEditBox (50 B) x3, MsgToTtl (22 B), AcFuncEditSw (44 B) x2,
; [nakarest] Window (36 B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2,
; [nakarest] AcLanguageText (42 B). 6 texts the records point at (Viewable slot 0x9b (table
; [nakarest] 0xe2ec64, 22 entries, InitializeKubo)): "TRACK MERGE" (TtlScreen.title of element
; [nakarest] 0); "VALUE" (Label.str of element 8); "TRACK :" (PsEditBox.caption of element 10);
; [nakarest] "TRACK :" (PsEditBox.caption of element 11); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x3CA4, 0x334
; [nakarest] naka_effects_seq+0x3fd8  +0x3fd8..+0x4384 (0xe2bf7c, 940 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x9c (table 0xe2ecc0, 21 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B) x3, AcIndexWideES (42 B), SqedtVal
; [nakarest] (32 B), PsEditBox (50 B) x6, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36
; [nakarest] B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2, AcLanguageText (42 B).
; [nakarest] 11 texts the records point at (Viewable slot 0x9c (table 0xe2ecc0, 21 entries,
; [nakarest] InitializeKubo)): "QUANTIZE" (TtlScreen.title of element 0); "VALUE" (Label.str of
; [nakarest] element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "WINDOW :"
; [nakarest] (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x3FD8, 0x3AC
; [nakarest] naka_effects_seq+0x4384  +0x4384..+0x4658 (0xe2c328, 724 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x9d (table 0xe2ed18, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0x9d (table 0xe2ed18, 16 entries,
; [nakarest] InitializeKubo)): "TRANSPOSE" (TtlScreen.title of element 0); "VALUE" (Label.str of
; [nakarest] element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "TRACK :"
; [nakarest] (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x4384, 0x2D4
; [nakarest] naka_effects_seq+0x4658  +0x4658..+0x4932 (0xe2c5fc, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0x9e (table 0xe2ed5c, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0x9e (table 0xe2ed5c, 16 entries,
; [nakarest] InitializeKubo)): "VELOCITY CHANGE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 1); "LAST MEASURE :" (PsEditBox.caption of element 4); "TRACK
; [nakarest] :" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x4658, 0x2DA
; [nakarest] naka_effects_seq+0x4932  +0x4932..+0x4d22 (0xe2c8d6, 1008 B)
; [nakarest] widget records, elements 0-24 of Viewable slot 0x9f (table 0xe2eda0, 25 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), SqedtVal (32 B), PsEditBox (50 B) x5, Label (32
; [nakarest] B) x3, AcIndexWideES (42 B), Line (26 B) x5, MsgToTtl (22 B), AcFuncEditSw (44 B)
; [nakarest] x2, Window (36 B), AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B) x2,
; [nakarest] AcLanguageText (42 B). 10 texts the records point at (Viewable slot 0x9f (table
; [nakarest] 0xe2eda0, 25 entries, InitializeKubo)): "NOTE CHANGE" (TtlScreen.title of element
; [nakarest] 0); "" (PsEditBox.caption of element 2); "CHANGE TO" (Label.str of element 3);
; [nakarest] "VALUE" (Label.str of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x4932, 0x3F0
; [nakarest] naka_effects_seq+0x4d22  +0x4d22..+0x4ffc (0xe2ccc6, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0xa0 (table 0xe2ee08, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0xa0 (table 0xe2ee08, 16 entries,
; [nakarest] InitializeKubo)): "ADVANCE/DELAY" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 2); "FIRST MEASURE:" (PsEditBox.caption of element 4); "LAST
; [nakarest] MEASURE :" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x4D22, 0x2DA
; [nakarest] naka_effects_seq+0x4ffc  +0x4ffc..+0x52d6 (0xe2cfa0, 730 B)
; [nakarest] widget records, elements 0-15 of Viewable slot 0xa1 (table 0xe2ee4c, 16 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B), Label (32 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x4, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 7
; [nakarest] texts the records point at (Viewable slot 0xa1 (table 0xe2ee4c, 16 entries,
; [nakarest] InitializeKubo)): "MEASURE ERASE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 2); "TRACK :" (PsEditBox.caption of element 4); "FIRST
; [nakarest] MEASURE:" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x4FFC, 0x2DA
; [nakarest] naka_effects_seq+0x52d6  +0x52d6..+0x554e (0xe2d27a, 632 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xa2 (table 0xe2ee90, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x4, SqedtVal2 (30 B),
; [nakarest] SqedtFix (28 B), MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B), Box (26 B)
; [nakarest] x3, IvExitScreen (26 B), AcLanguageText (42 B), AcScreenMenu (54 B). 2 texts the
; [nakarest] records point at (Viewable slot 0xa2 (table 0xe2ee90, 17 entries, InitializeKubo)):
; [nakarest] "MEASURE COPY" (TtlScreen.title of element 0); "NO" (AcScreenMenu.str of element
; [nakarest] 16).
	.incbin "includes/generated/naka_effects_seq.bin", 0x52D6, 0x278
; [nakarest] naka_effects_seq+0x554e  +0x554e..+0x57e6 (0xe2d4f2, 664 B)
; [nakarest] widget records, elements 0-14 of Viewable slot 0xa3 (table 0xe2eed8, 15 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), Label (32 B), AcIndexWideES (42 B), SqedtVal (32
; [nakarest] B), PsEditBox (50 B) x3, MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B),
; [nakarest] AcScreenMenu (54 B), IvExitScreen (26 B), Box (26 B), AcLanguageText (42 B). 6
; [nakarest] texts the records point at (Viewable slot 0xa3 (table 0xe2eed8, 15 entries,
; [nakarest] InitializeKubo)): "MEASURE DELETE" (TtlScreen.title of element 0); "VALUE"
; [nakarest] (Label.str of element 1); "FIRST MEASURE:" (PsEditBox.caption of element 4); "LAST
; [nakarest] MEASURE :" (PsEditBox.caption of element 5); ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x554E, 0x298
; [nakarest] naka_effects_seq+0x57e6  +0x57e6..+0x5a60 (0xe2d78a, 634 B)
; [nakarest] widget records, elements 0-16 of Viewable slot 0xa4 (table 0xe2ef18, 17 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcIndexWideES (42 B) x4, SqedtVal2 (30 B),
; [nakarest] SqedtFix (28 B), MsgToTtl (22 B), AcFuncEditSw (44 B) x2, Window (36 B), Box (26 B)
; [nakarest] x3, IvExitScreen (26 B), AcLanguageText (42 B), AcScreenMenu (54 B). 2 texts the
; [nakarest] records point at (Viewable slot 0xa4 (table 0xe2ef18, 17 entries, InitializeKubo)):
; [nakarest] "MEASURE INSERT" (TtlScreen.title of element 0); "NO" (AcScreenMenu.str of element
; [nakarest] 16).
	.incbin "includes/generated/naka_effects_seq.bin", 0x57E6, 0x27A
; [nakarest] naka_effects_seq+0x5a60  +0x5a60..+0x5abc (0xe2da04, 92 B)
; [nakarest] widget records, elements 0-1 of Viewable slot 0xab (table 0xe2ef68, 2 entries,
; [nakarest] InitializeKubo): TtlScreen (42 B), AcMixerVol (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xab (table 0xe2ef68, 2 entries, InitializeKubo)): "METRONOME
; [nakarest] BALANCE" (TtlScreen.title of element 0).
	.incbin "includes/generated/naka_effects_seq.bin", 0x5A60, 0x5C
; [nakarest] naka_effects_seq+0x5abc  +0x5abc..+0x5bf2 (0xe2da60, 310 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0xd6 (table 0xe2ef74, 15 entries,
; [nakarest] InitializeKubo) ("EnterTainerScr"): TtlScreen (42 B), AcEntertainerGridBox (74 B),
; [nakarest] Label (32 B). 4 texts the records point at (Viewable slot 0xd6 (table 0xe2ef74, 15
; [nakarest] entries, InitializeKubo)): "ENTERTAINER" (TtlScreen.title of element 0); "MIC
; [nakarest] BALANCE :|-|| ON/OFF :| TYPE :| RE" (AcEntertainerGridBox.fixedrow of element 1); "
; [nakarest] | " (AcEntertainerGridBox.fixedcol of element 1); "VOCAL REVERB" (Label.str of
; [nakarest] element 2).
	.incbin "includes/generated/naka_effects_seq.bin", 0x5ABC, 0x136
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
	.incbin "includes/generated/naka_effects_seq.bin", 0x5BF2, 0x17A
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
	.incbin "includes/generated/naka_effects_seq.bin", 0x5D6C, 0x914
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
InitializeKubo_PtrTable:	.long 0x00E28888
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
InitializeKubo_PtrTable_2:	.long 0x00E28A3C
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
InitializeKubo_PtrTable_3:	.long 0x00E28C54
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
InitializeKubo_PtrTable_4:	.long 0x00E29080
	.long 0x00E290B6
	.long 0x00E290D6
	.long 0x00E2911E
	.long 0x00E29150
	.long 0x00E2918A
	.long 0x00E291D2
	.long 0x00E291FC
	.long 0x00000000
InitializeKubo_PtrTable_5:	.long 0x00E29222
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
InitializeKubo_PtrTable_6:	.long 0x00E29498
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
InitializeKubo_PtrTable_7:	.long 0x00E29734
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
InitializeKubo_PtrTable_8:	.long 0x00E29AC2
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
InitializeKubo_PtrTable_9:	.long 0x00E29CF4
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
InitializeKubo_PtrTable_10:	.long 0x00E2A09C
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
InitializeKubo_PtrTable_11:	.long 0x00E2A302
	.long 0x00E2A338
	.long 0x00E2A364
	.long 0x00E2A38E
	.long 0x00000000
InitializeKubo_PtrTable_12:	.long 0x00E2A3A4
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
InitializeKubo_PtrTable_13:	.long 0x00E2A62A
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
InitializeKubo_PtrTable_14:	.long 0x00E2A8D0
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
InitializeKubo_PtrTable_15:	.long 0x00E2ADD8
	.long 0x00E2AE0E
	.long 0x00E2AE3C
	.long 0x00E2AE52
	.long 0x00000000
InitializeKubo_PtrTable_16:	.long 0x00E2AE7C
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
InitializeKubo_PtrTable_17:	.long 0x00E2B272
	.long 0x00E2B2A8
	.long 0x00E2B2DA
	.long 0x00E2B304
	.long 0x00E2B32A
	.long 0x00E2B34A
	.long 0x00E2B384
	.long 0x00E2B3CC
	.long 0x00000000
InitializeKubo_PtrTable_18:	.long 0x00E2B414
	.long 0x00E2B44A
	.long 0x00E2B478
	.long 0x00E2B48E
	.long 0x00000000
InitializeKubo_PtrTable_19:	.long 0x00E2B4B8
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
InitializeKubo_PtrTable_20:	.long 0x00E2B886
	.long 0x00E2B8BC
	.long 0x00E2B8EE
	.long 0x00E2B918
	.long 0x00E2B93E
	.long 0x00E2B95E
	.long 0x00E2B998
	.long 0x00E2B9E0
	.long 0x00000000
InitializeKubo_PtrTable_21:	.long 0x00E2BA28
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
InitializeKubo_PtrTable_22:	.long 0x00E2BC48
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
InitializeKubo_PtrTable_23:	.long 0x00E2BF7C
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
InitializeKubo_PtrTable_24:	.long 0x00E2C328
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
InitializeKubo_PtrTable_25:	.long 0x00E2C5FC
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
InitializeKubo_PtrTable_26:	.long 0x00E2C8D6
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
InitializeKubo_PtrTable_27:	.long 0x00E2CCC6
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
InitializeKubo_PtrTable_28:	.long 0x00E2CFA0
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
InitializeKubo_PtrTable_29:	.long 0x00E2D27A
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
InitializeKubo_PtrTable_30:	.long 0x00E2D4F2
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
InitializeKubo_PtrTable_31:	.long 0x00E2D78A
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
InitializeKubo_PtrTable_32:	.long 0x00E2DA04
	.long 0x00E2DA40
	.long 0x00000000
InitializeKubo_PtrTable_33:	.long 0x00E2DA60
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
InitializeKubo_PtrTable_34:	.long 0x00E2DD10
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
; [nakarest] naka_effects_seq+0x7100  +0x7100..+0x7108 (0xe2f0a4, 8 B)
; [nakarest] purpose not established: 4 B at 0xe2f0a8 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
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
	.incbin "includes/generated/naka_effects_seq.bin", 0x804C, 0x6
; [nakarest] naka_effects_seq+0x8052  +0x8052..+0x8058 (0xe2fff6, 6 B)
; [nakarest] the table itself: ResName slot 0x3aa (table 0xe2fff6, 0 entries, InitializeKubo), 0
; [nakarest] entry pointers x 4 bytes.
	.incbin "includes/generated/naka_effects_seq.bin", 0x8052, 0x6
; [nakarest] naka_effects_seq+0x8058  +0x8058..+0x8066 (0xe2fffc, 14 B)
; [nakarest] the table itself: ResName slot 0x3ab (table 0xe2fffc, 2 entries, InitializeKubo), 2
; [nakarest] entry pointers x 4 bytes.
InitializeKubo_PtrTable_69:	.incbin "includes/generated/naka_effects_seq.bin", 0x8058, 0xE
; [nakarest] naka_effects_seq+0x8066  +0x8066..+0x806a (0xe3000a, 4 B)
; [nakarest] name strings, entries 0-1 of ResName slot 0x3ab (table 0xe2fffc, 2 entries,
; [nakarest] InitializeKubo) (names for Viewable slot 0xab): "", "".
	.incbin "includes/generated/naka_effects_seq.bin", 0x8066, 0x4
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
; [nakarest] purpose not established: 6 B at 0xe30192 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
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
InitializeKubo_PtrTable_72:	.long 0x00E30932
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
; [nakarest] naka_effects_seq+0x86e0  +0x86e0..+0x86e2 (0xe30684, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe30684 not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v7_naka_effects_seq_008600
; [nakarest] (ui_widgets/effects_sequencer_screens.s: `.long 0x00e30684`); 1 data word in
; [nakarest] EmbeddedPtrTable_v7_naka_effects_seq_008600 (at 0xe30680).
	.incbin "includes/generated/naka_effects_seq.bin", 0x86E0, 0x2
; [nakarest] naka_effects_seq+0x86e2  +0x86e2..+0x899a (0xe30686, 696 B)
; [nakarest] name strings, entries 0-43 of MainFunction slot 0x448 (table 0xe305d0, 44 entries,
; [nakarest] InitializeKubo) (names for MainFunction slot 0x148): "MainPanic",
; [nakarest] "EtmenuTitleFunc", "HelpFlashFunc", "HelpLangChkMain", "HelpTitleFunc",
; [nakarest] "HelpModeFunc", ....
	.incbin "includes/generated/naka_effects_seq.bin", 0x86E2, 0x2B8
; [nakarest] naka_effects_seq+0x899a  +0x899a..+0x89a2 (0xe3093e, 8 B)
; [nakarest] purpose not established: layout of 8 B at 0xe3093e not derived; readers below
; [nakarest] Readers: source references EntertainerGridCheck (sequencer/sequencer_ui.s: `ld xiy,
; [nakarest] Naka_Help_569_E30113_0x82B`).
	.incbin "includes/generated/naka_effects_seq.bin", 0x899A, 0x8
; [nakarest] naka_effects_seq+0x89a2  +0x89a2..+0x8e22 (0xe30946, 1152 B)
; [nakarest] Text (1152 B at 0xe30946), first string
; [nakarest] "~43~2d~32~44~a0~bc~44~2d~32~45~a0~bc~45~2d~32~46"; no registered NAKA table points
; [nakarest] into it; reached through source references
; [nakarest] Sqedt_ParamDispatch_Join6 (sequencer/sequencer_ui.s: `lda xde,
; [nakarest] (Naka_Help_569_E30113_0x833:24)`).
	.incbin "includes/generated/naka_effects_seq.bin", 0x89A2, 0x480
; [nakarest] naka_effects_seq+0x8e22  +0x8e22..+0x8e5a (0xe30dc6, 56 B)
; [nakarest] purpose not established: layout of 56 B at 0xe30dc6 not derived; readers below
; [nakarest] Readers: source references Equalizer_DispatchA (sequencer/sequencer_ui.s: `lda xde,
; [nakarest] (Naka_Help_569_E30113_0xCB3:24)`).
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E22, 0x38
; [nakarest] naka_effects_seq+0x8e5a  +0x8e5a..+0x8ebc (0xe30dfe, 98 B)
; [nakarest] Text (98 B at 0xe30dfe), first string "q"; no registered NAKA table points into it;
; [nakarest] reached through source references Equalizer_DispatchA (sequencer/sequencer_ui.s:
; [nakarest] `lda xbc, (Naka_Help_569_E30113_0xCEB:24)`).
	.incbin "includes/generated/naka_effects_seq.bin", 0x8E5A, 0x62

; External label offsets within the binary blob above.
