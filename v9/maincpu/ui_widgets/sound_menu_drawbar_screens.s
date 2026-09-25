
; Sound Menu / Drawbar Screens widget data (8 widgets, 2314 bytes)
; Source: maincpu/ui_widgets/naka_sound_menu_drawbar.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_sound_menu_drawbar
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
; Viewable slot 0x2: RegObjTabl 0x1600010, ViewableProc, 0x14, 0xe85470,
; 0x2 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x2. Element 0 is named "Sdmenu" in ResName slot 0x302. Links: all
; 20 records consistent.
;
; Function slot 0x101: RegObjTabl 0x1600001, FunctionProc, 0x25,
; 0xe814f4, 0x101 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0x101.
;
; Class slot 0x161: RegObjTable 0x1600004, ClassProc, 0xe812e2,
; 0xe80cf6, 0x161 in InitializeMurai (ui/drawbar_panel_ui.s) -- the
; count, 37, is the word at 0xe812e2; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x161.
;
; ResEvent slot 0x1c1: RegObjTable 0x160000c, ResEventProc, 0xe813a4,
; 0xe812e4, 0x1c1 in InitializeMurai (ui/drawbar_panel_ui.s) -- the
; count, 10, is the word at 0xe813a4; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x1c1.
;
; ResMethod slot 0x1e1: RegObjTable 0x160000d, ResMethodProc, 0xe814f2,
; 0xe813a6, 0x1e1 in InitializeMurai (ui/drawbar_panel_ui.s) -- the
; count, 15, is the word at 0xe814f2; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x1e1.
;
; Function slot 0x401: RegObjTabl 0x1600001, FunctionProc, 0x25,
; 0xe8158c, 0x401 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0x401.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_SoundMenuDrawbar
; NakaData_SoundMenuDrawbar  --  naka_sound_menu_drawbar +0x0..+0x14 (ROM 0xe80fe2..0xe80ff6), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xe80fe2..0xe80ff6); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_SoundMenuDrawbar:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x14
; naka_sound_menu_drawbar+0x14  --  naka_sound_menu_drawbar +0x14..+0xa4 (ROM 0xe80ff6..0xe81086), 144 bytes
; Class definitions 32-36 of Class slot 0x161 (table 0xe80cf6, 37
; entries, InitializeMurai): AcSndEMenu, AcPleaseWait, AcDrawSetting,
; AcDrawbarName, IvMPver. 24 bytes each: +0 proc, +4 parent (class id),
; +8 allsize, +10 selfsize, +12 name, +16 propdata, +20 propname -- the
; firmware's own field names, from the propname table of the root class
; "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14, 0x90
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xa4
; naka_sound_menu_drawbar+0xa4  --  naka_sound_menu_drawbar +0xa4..+0xa6 (ROM 0xe81086..0xe81088), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 36 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvMPver): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xA4, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xa6
; naka_sound_menu_drawbar+0xa6  --  naka_sound_menu_drawbar +0xa6..+0xae (ROM 0xe81088..0xe81090), 8 bytes
; Class-name strings (the +12 name of classes 36 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvMPver.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xA6, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xae
; naka_sound_menu_drawbar+0xae  --  naka_sound_menu_drawbar +0xae..+0xb2 (ROM 0xe81090..0xe81094), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 35 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcDrawbarName): "ue".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xAE, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xb2
; naka_sound_menu_drawbar+0xb2  --  naka_sound_menu_drawbar +0xb2..+0xc0 (ROM 0xe81094..0xe810a2), 14 bytes
; Class-name strings (the +12 name of classes 35 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcDrawbarName.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xB2, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xc0
; naka_sound_menu_drawbar+0xc0  --  naka_sound_menu_drawbar +0xc0..+0xc4 (ROM 0xe810a2..0xe810a6), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 34 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcDrawSetting): "AA".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xC0, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xc4
; naka_sound_menu_drawbar+0xc4  --  naka_sound_menu_drawbar +0xc4..+0xd2 (ROM 0xe810a6..0xe810b4), 14 bytes
; Class-name strings (the +12 name of classes 34 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcDrawSetting.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xC4, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xd2
; naka_sound_menu_drawbar+0xd2  --  naka_sound_menu_drawbar +0xd2..+0xd4 (ROM 0xe810b4..0xe810b6), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 33 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcPleaseWait): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xD2, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xd4
; naka_sound_menu_drawbar+0xd4  --  naka_sound_menu_drawbar +0xd4..+0xe2 (ROM 0xe810b6..0xe810c4), 14 bytes
; Class-name strings (the +12 name of classes 33 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcPleaseWait.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xD4, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xe2
; naka_sound_menu_drawbar+0xe2  --  naka_sound_menu_drawbar +0xe2..+0xe4 (ROM 0xe810c4..0xe810c6), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 32 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcSndEMenu): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xE2, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xe4
; naka_sound_menu_drawbar+0xe4  --  naka_sound_menu_drawbar +0xe4..+0xf0 (ROM 0xe810c6..0xe810d2), 12 bytes
; Class-name strings (the +12 name of classes 32 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcSndEMenu.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xE4, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xf0
; naka_sound_menu_drawbar+0xf0  --  naka_sound_menu_drawbar +0xf0..+0xf2 (ROM 0xe810d2..0xe810d4), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 31 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcFdemoScreen): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xF0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0xf2
; naka_sound_menu_drawbar+0xf2  --  naka_sound_menu_drawbar +0xf2..+0x100 (ROM 0xe810d4..0xe810e2), 14 bytes
; Class-name strings (the +12 name of classes 31 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcFdemoScreen.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xF2, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x100
; naka_sound_menu_drawbar+0x100  --  naka_sound_menu_drawbar +0x100..+0x102 (ROM 0xe810e2..0xe810e4), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 30 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (VwUserBitmapSp): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x100, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x102
; naka_sound_menu_drawbar+0x102  --  naka_sound_menu_drawbar +0x102..+0x112 (ROM 0xe810e4..0xe810f4), 16 bytes
; Class-name strings (the +12 name of classes 30 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): VwUserBitmapSp.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x102, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x112
; naka_sound_menu_drawbar+0x112  --  naka_sound_menu_drawbar +0x112..+0x118 (ROM 0xe810f4..0xe810fa), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 29 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcPresentationBox): "XemA".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x112, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x118
; naka_sound_menu_drawbar+0x118  --  naka_sound_menu_drawbar +0x118..+0x12a (ROM 0xe810fa..0xe8110c), 18 bytes
; Class-name strings (the +12 name of classes 29 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcPresentationBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x118, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x12a
; naka_sound_menu_drawbar+0x12a  --  naka_sound_menu_drawbar +0x12a..+0x12e (ROM 0xe8110c..0xe81110), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 28 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcLswPartPan): "jn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x12A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x12e
; naka_sound_menu_drawbar+0x12e  --  naka_sound_menu_drawbar +0x12e..+0x13c (ROM 0xe81110..0xe8111e), 14 bytes
; Class-name strings (the +12 name of classes 28 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcLswPartPan.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x12E, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x13c
; naka_sound_menu_drawbar+0x13c  --  naka_sound_menu_drawbar +0x13c..+0x13e (ROM 0xe8111e..0xe81120), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 27 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcDrawEditBox): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x13C, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x13e
; naka_sound_menu_drawbar+0x13e  --  naka_sound_menu_drawbar +0x13e..+0x14c (ROM 0xe81120..0xe8112e), 14 bytes
; Class-name strings (the +12 name of classes 27 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcDrawEditBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x13E, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x14c
; naka_sound_menu_drawbar+0x14c  --  naka_sound_menu_drawbar +0x14c..+0x14e (ROM 0xe8112e..0xe81130), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 26 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDemofeature2): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14C, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x14e
; naka_sound_menu_drawbar+0x14e  --  naka_sound_menu_drawbar +0x14e..+0x15e (ROM 0xe81130..0xe81140), 16 bytes
; Class-name strings (the +12 name of classes 26 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDemofeature2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14E, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x15e
; naka_sound_menu_drawbar+0x15e  --  naka_sound_menu_drawbar +0x15e..+0x160 (ROM 0xe81140..0xe81142), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 25 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDemofeature1): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x15E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x160
; naka_sound_menu_drawbar+0x160  --  naka_sound_menu_drawbar +0x160..+0x170 (ROM 0xe81142..0xe81152), 16 bytes
; Class-name strings (the +12 name of classes 25 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDemofeature1.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x160, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x170
; naka_sound_menu_drawbar+0x170  --  naka_sound_menu_drawbar +0x170..+0x172 (ROM 0xe81152..0xe81154), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 24 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcPresentationControl): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x170, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x172
; naka_sound_menu_drawbar+0x172  --  naka_sound_menu_drawbar +0x172..+0x188 (ROM 0xe81154..0xe8116a), 22 bytes
; Class-name strings (the +12 name of classes 24 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcPresentationControl.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x172, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x188
; naka_sound_menu_drawbar+0x188  --  naka_sound_menu_drawbar +0x188..+0x18e (ROM 0xe8116a..0xe81170), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 23 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (PsVariBox): "c^dem".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x188, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x18e
; naka_sound_menu_drawbar+0x18e  --  naka_sound_menu_drawbar +0x18e..+0x198 (ROM 0xe81170..0xe8117a), 10 bytes
; Class-name strings (the +12 name of classes 23 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): PsVariBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x18E, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x198
; naka_sound_menu_drawbar+0x198  --  naka_sound_menu_drawbar +0x198..+0x19a (ROM 0xe8117a..0xe8117c), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 22 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcResetPage): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x198, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x19a
; naka_sound_menu_drawbar+0x19a  --  naka_sound_menu_drawbar +0x19a..+0x1a6 (ROM 0xe8117c..0xe81188), 12 bytes
; Class-name strings (the +12 name of classes 22 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcResetPage.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x19A, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1a6
; naka_sound_menu_drawbar+0x1a6  --  naka_sound_menu_drawbar +0x1a6..+0x1a8 (ROM 0xe81188..0xe8118a), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 21 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDrawbarSndE): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1A6, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1a8
; naka_sound_menu_drawbar+0x1a8  --  naka_sound_menu_drawbar +0x1a8..+0x1b6 (ROM 0xe8118a..0xe81198), 14 bytes
; Class-name strings (the +12 name of classes 21 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDrawbarSndE.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1A8, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1b6
; naka_sound_menu_drawbar+0x1b6  --  naka_sound_menu_drawbar +0x1b6..+0x1b8 (ROM 0xe81198..0xe8119a), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 20 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDrawbarNorm): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1B6, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1b8
; naka_sound_menu_drawbar+0x1b8  --  naka_sound_menu_drawbar +0x1b8..+0x1c6 (ROM 0xe8119a..0xe811a8), 14 bytes
; Class-name strings (the +12 name of classes 20 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDrawbarNorm.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1B8, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1c6
; naka_sound_menu_drawbar+0x1c6  --  naka_sound_menu_drawbar +0x1c6..+0x1c8 (ROM 0xe811a8..0xe811aa), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 19 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDrawbar2): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1C6, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1c8
; naka_sound_menu_drawbar+0x1c8  --  naka_sound_menu_drawbar +0x1c8..+0x1d4 (ROM 0xe811aa..0xe811b6), 12 bytes
; Class-name strings (the +12 name of classes 19 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDrawbar2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1C8, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1d4
; naka_sound_menu_drawbar+0x1d4  --  naka_sound_menu_drawbar +0x1d4..+0x1d6 (ROM 0xe811b6..0xe811b8), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 18 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDrawbar1): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1D4, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1d6
; naka_sound_menu_drawbar+0x1d6  --  naka_sound_menu_drawbar +0x1d6..+0x1e2 (ROM 0xe811b8..0xe811c4), 12 bytes
; Class-name strings (the +12 name of classes 18 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDrawbar1.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1D6, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1e2
; naka_sound_menu_drawbar+0x1e2  --  naka_sound_menu_drawbar +0x1e2..+0x1e4 (ROM 0xe811c4..0xe811c6), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 17 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvDrawbar): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1E2, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1e4
; naka_sound_menu_drawbar+0x1e4  --  naka_sound_menu_drawbar +0x1e4..+0x1ee (ROM 0xe811c6..0xe811d0), 10 bytes
; Class-name strings (the +12 name of classes 17 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvDrawbar.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1E4, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1ee
; naka_sound_menu_drawbar+0x1ee  --  naka_sound_menu_drawbar +0x1ee..+0x1f2 (ROM 0xe811d0..0xe811d4), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 16 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvPageOverWrite): "At".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1EE, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x1f2
; naka_sound_menu_drawbar+0x1f2  --  naka_sound_menu_drawbar +0x1f2..+0x202 (ROM 0xe811d4..0xe811e4), 16 bytes
; Class-name strings (the +12 name of classes 16 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvPageOverWrite.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1F2, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x202
; naka_sound_menu_drawbar+0x202  --  naka_sound_menu_drawbar +0x202..+0x204 (ROM 0xe811e4..0xe811e6), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 15 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvSoftver): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x202, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x204
; naka_sound_menu_drawbar+0x204  --  naka_sound_menu_drawbar +0x204..+0x20e (ROM 0xe811e6..0xe811f0), 10 bytes
; Class-name strings (the +12 name of classes 15 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvSoftver.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x204, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x20e
; naka_sound_menu_drawbar+0x20e  --  naka_sound_menu_drawbar +0x20e..+0x210 (ROM 0xe811f0..0xe811f2), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 14 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcTrackMixer): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x20E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x210
; naka_sound_menu_drawbar+0x210  --  naka_sound_menu_drawbar +0x210..+0x21e (ROM 0xe811f2..0xe81200), 14 bytes
; Class-name strings (the +12 name of classes 14 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcTrackMixer.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x210, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x21e
; naka_sound_menu_drawbar+0x21e  --  naka_sound_menu_drawbar +0x21e..+0x220 (ROM 0xe81200..0xe81202), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 13 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcPartMixer): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x21E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x220
; naka_sound_menu_drawbar+0x220  --  naka_sound_menu_drawbar +0x220..+0x22c (ROM 0xe81202..0xe8120e), 12 bytes
; Class-name strings (the +12 name of classes 13 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcPartMixer.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x220, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x22c
; naka_sound_menu_drawbar+0x22c  --  naka_sound_menu_drawbar +0x22c..+0x22e (ROM 0xe8120e..0xe81210), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 12 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (PsMixerControl): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x22C, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x22e
; naka_sound_menu_drawbar+0x22e  --  naka_sound_menu_drawbar +0x22e..+0x23e (ROM 0xe81210..0xe81220), 16 bytes
; Class-name strings (the +12 name of classes 12 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): PsMixerControl.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x22E, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x23e
; naka_sound_menu_drawbar+0x23e  --  naka_sound_menu_drawbar +0x23e..+0x240 (ROM 0xe81220..0xe81222), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 11 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcWelcomScreen): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x23E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x240
; naka_sound_menu_drawbar+0x240  --  naka_sound_menu_drawbar +0x240..+0x250 (ROM 0xe81222..0xe81232), 16 bytes
; Class-name strings (the +12 name of classes 11 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcWelcomScreen.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x240, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x250
; naka_sound_menu_drawbar+0x250  --  naka_sound_menu_drawbar +0x250..+0x252 (ROM 0xe81232..0xe81234), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 10 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvSdscltyp2): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x250, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x252
; naka_sound_menu_drawbar+0x252  --  naka_sound_menu_drawbar +0x252..+0x25e (ROM 0xe81234..0xe81240), 12 bytes
; Class-name strings (the +12 name of classes 10 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvSdscltyp2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x252, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x25e
; naka_sound_menu_drawbar+0x25e  --  naka_sound_menu_drawbar +0x25e..+0x260 (ROM 0xe81240..0xe81242), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 9 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvSdtecd1): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x25E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x260
; naka_sound_menu_drawbar+0x260  --  naka_sound_menu_drawbar +0x260..+0x26a (ROM 0xe81242..0xe8124c), 10 bytes
; Class-name strings (the +12 name of classes 9 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvSdtecd1.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x260, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x26a
; naka_sound_menu_drawbar+0x26a  --  naka_sound_menu_drawbar +0x26a..+0x26c (ROM 0xe8124c..0xe8124e), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 8 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvSdtecd): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x26A, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x26c
; naka_sound_menu_drawbar+0x26c  --  naka_sound_menu_drawbar +0x26c..+0x276 (ROM 0xe8124e..0xe81258), 10 bytes
; Class-name strings (the +12 name of classes 8 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvSdtecd.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x26C, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x276
; naka_sound_menu_drawbar+0x276  --  naka_sound_menu_drawbar +0x276..+0x27e (ROM 0xe81258..0xe81260), 8 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 7 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (PsLabelBox): "Xc^dmm".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x276, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x27e
; naka_sound_menu_drawbar+0x27e  --  naka_sound_menu_drawbar +0x27e..+0x28a (ROM 0xe81260..0xe8126c), 12 bytes
; Class-name strings (the +12 name of classes 7 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): PsLabelBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x27E, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x28a
; naka_sound_menu_drawbar+0x28a  --  naka_sound_menu_drawbar +0x28a..+0x28e (ROM 0xe8126c..0xe81270), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 6 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcAccordionTab): "XX".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x28A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x28e
; naka_sound_menu_drawbar+0x28e  --  naka_sound_menu_drawbar +0x28e..+0x29e (ROM 0xe81270..0xe81280), 16 bytes
; Class-name strings (the +12 name of classes 6 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcAccordionTab.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x28E, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x29e
; naka_sound_menu_drawbar+0x29e  --  naka_sound_menu_drawbar +0x29e..+0x2a0 (ROM 0xe81280..0xe81282), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 5 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvAccordionX): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x29E, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2a0
; naka_sound_menu_drawbar+0x2a0  --  naka_sound_menu_drawbar +0x2a0..+0x2ae (ROM 0xe81282..0xe81290), 14 bytes
; Class-name strings (the +12 name of classes 5 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvAccordionX.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2A0, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2ae
; naka_sound_menu_drawbar+0x2ae  --  naka_sound_menu_drawbar +0x2ae..+0x2b0 (ROM 0xe81290..0xe81292), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 4 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvAccordion): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2AE, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2b0
; naka_sound_menu_drawbar+0x2b0  --  naka_sound_menu_drawbar +0x2b0..+0x2bc (ROM 0xe81292..0xe8129e), 12 bytes
; Class-name strings (the +12 name of classes 4 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvAccordion.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2B0, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2bc
; naka_sound_menu_drawbar+0x2bc  --  naka_sound_menu_drawbar +0x2bc..+0x2be (ROM 0xe8129e..0xe812a0), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 3 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvMesage): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2BC, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2be
; naka_sound_menu_drawbar+0x2be  --  naka_sound_menu_drawbar +0x2be..+0x2c8 (ROM 0xe812a0..0xe812aa), 10 bytes
; Class-name strings (the +12 name of classes 3 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvMesage.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2BE, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2c8
; naka_sound_menu_drawbar+0x2c8  --  naka_sound_menu_drawbar +0x2c8..+0x2cc (ROM 0xe812aa..0xe812ae), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 2 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcVolPartEditBox): "jjn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2C8, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2cc
; naka_sound_menu_drawbar+0x2cc  --  naka_sound_menu_drawbar +0x2cc..+0x2de (ROM 0xe812ae..0xe812c0), 18 bytes
; Class-name strings (the +12 name of classes 2 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcVolPartEditBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2CC, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2de
; naka_sound_menu_drawbar+0x2de  --  naka_sound_menu_drawbar +0x2de..+0x2e2 (ROM 0xe812c0..0xe812c4), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 1 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (AcLswPartEditBox): "jn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2DE, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2e2
; naka_sound_menu_drawbar+0x2e2  --  naka_sound_menu_drawbar +0x2e2..+0x2f4 (ROM 0xe812c4..0xe812d6), 18 bytes
; Class-name strings (the +12 name of classes 1 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): AcLswPartEditBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2E2, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2f4
; naka_sound_menu_drawbar+0x2f4  --  naka_sound_menu_drawbar +0x2f4..+0x2f6 (ROM 0xe812d6..0xe812d8), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 0 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; InitializeMurai) (IvSdpart): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2F4, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x2f6
; naka_sound_menu_drawbar+0x2f6  --  naka_sound_menu_drawbar +0x2f6..+0x302 (ROM 0xe812d8..0xe812e4), 12 bytes
; Class-name strings (the +12 name of classes 0 of Class slot 0x161
; (table 0xe80cf6, 37 entries, InitializeMurai)): IvSdpart.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2F6, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x302
; naka_sound_menu_drawbar+0x302  --  naka_sound_menu_drawbar +0x302..+0x306 (ROM 0xe812e4..0xe812e8), 4 bytes
; The table itself: ResEvent slot 0x1c1 (table 0xe812e4, 10 entries,
; InitializeMurai) -- 10 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x302, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_EventDispatch_Table
; Naka_EventDispatch_Table  --  naka_sound_menu_drawbar +0x306..+0x32e (ROM 0xe812e8..0xe81310), 40 bytes
; No RegObjTabl-registered table points at the start of these 40 bytes
; (0xe812e8..0xe81310); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_EventDispatch_Table:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x306, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x32e
; naka_sound_menu_drawbar+0x32e  --  naka_sound_menu_drawbar +0x32e..+0x3c4 (ROM 0xe81310..0xe813a6), 150 bytes
; Name strings of elements 0-9 of ResEvent slot 0x1c1 (table 0xe812e4,
; 10 entries, InitializeMurai): "EV_MPVERSION", "EV_TONEMODE",
; "EV_EXECPRESENTATION", "EV_ENDSONG", "EV_STARTSONG", "EV_ALLINITIAL",
; ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x32E, 0x96
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Event_Table3
; Naka_Event_Table3  --  naka_sound_menu_drawbar +0x3c4..+0x404 (ROM 0xe813a6..0xe813e6), 64 bytes
; The table itself: ResMethod slot 0x1e1 (table 0xe813a6, 15 entries,
; InitializeMurai) -- 15 x u32 entry pointers.
; -----------------------------------------------------------------------------
Naka_Event_Table3:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x3C4, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x404
; naka_sound_menu_drawbar+0x404  --  naka_sound_menu_drawbar +0x404..+0x512 (ROM 0xe813e6..0xe814f4), 270 bytes
; Name strings of elements 0-14 of ResMethod slot 0x1e1 (table 0xe813a6,
; 15 entries, InitializeMurai): "MT_GetToneMode", "MT_ExitPresentation",
; "MT_InitPresentation", "MT_ExistPresentation", "MT_SetMemoryDrawbar",
; "MT_RequestMemoryDrawbar", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x404, 0x10E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x512
; naka_sound_menu_drawbar+0x512  --  naka_sound_menu_drawbar +0x512..+0x5aa (ROM 0xe814f4..0xe8158c), 152 bytes
; The table itself: Function slot 0x101 (table 0xe814f4, 37 entries,
; InitializeMurai) -- 37 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x512, 0x98
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x5aa
; naka_sound_menu_drawbar+0x5aa  --  naka_sound_menu_drawbar +0x5aa..+0x5ae (ROM 0xe8158c..0xe81590), 4 bytes
; The table itself: Function slot 0x401 (table 0xe8158c, 37 entries,
; InitializeMurai) -- 37 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x5AA, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka_Event_Table2
; Naka_Event_Table2  --  naka_sound_menu_drawbar +0x5ae..+0x642 (ROM 0xe81590..0xe81624), 148 bytes
; No RegObjTabl-registered table points at the start of these 148 bytes
; (0xe81590..0xe81624); purpose not established by that route.
; -----------------------------------------------------------------------------
Naka_Event_Table2:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x5AE, 0x94
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_EmptyString
; NakaInst_EmptyString  --  naka_sound_menu_drawbar +0x642..+0x644 (ROM 0xe81624..0xe81626), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xe81624..0xe81626); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaInst_EmptyString:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x642, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_sound_menu_drawbar+0x644
; naka_sound_menu_drawbar+0x644  --  naka_sound_menu_drawbar +0x644..+0x8c0 (ROM 0xe81626..0xe818a2), 636 bytes
; Name strings of elements 1-36 of Function slot 0x401 (table 0xe8158c,
; 37 entries, InitializeMurai), names for Function slot 0x101:
; "IvMPverProc", "AcDrawbarNameProc", "AcDrawSettingProc",
; "AcPleaseWaitProc", "AcSndEMenuProc", "AcFdemoScreenProc", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x644, 0x27C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvSdpartProc
; NakaInst_IvSdpartProc  --  naka_sound_menu_drawbar +0x8c0..+0x8ce (ROM 0xe818a2..0xe818b0), 14 bytes
; Name strings of element 0 of Function slot 0x401 (table 0xe8158c, 37
; entries, InitializeMurai), names for Function slot 0x101:
; "IvSdpartProc".
; -----------------------------------------------------------------------------
NakaInst_IvSdpartProc:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8C0, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_SoundMenu_Root
; NakaContainer_SoundMenu_Root  --  naka_sound_menu_drawbar +0x8ce..+0x8f8 (ROM 0xe818b0..0xe818da), 42 bytes
; Widget records of element 0 of Viewable slot 0x2 (table 0xe85470, 20
; entries, InitializeMurai), element 0 "Sdmenu"; classes: TtlScreen (42
; B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_SoundMenu_Root:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8CE, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaDesc_SOUND_MENU
; NakaDesc_SOUND_MENU  --  naka_sound_menu_drawbar +0x8f8..+0x904 (ROM 0xe818da..0xe818e6), 12 bytes
; No RegObjTabl-registered table points at the start of these 12 bytes
; (0xe818da..0xe818e6); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaDesc_SOUND_MENU:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8F8, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaWidget_SoundMenu_PageButton
; NakaWidget_SoundMenu_PageButton  --  naka_sound_menu_drawbar +0x904..+0x90a (ROM 0xe818e6..0xe818ec), 6 bytes
; Widget records of element 1 of Viewable slot 0x2 (table 0xe85470, 20
; entries, InitializeMurai), element 0 "Sdmenu"; classes: AcWindowPage
; (36 B, id 0x01600025).
; -----------------------------------------------------------------------------
NakaWidget_SoundMenu_PageButton:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x904, 0x6
; External label offsets within the binary blob above.
