
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

; [nakarest] NakaData_SoundMenuDrawbar  +0x0..+0x14 (0xe80fe2, 20 B)
; [nakarest] bytes 4-23 of class definition 31 (AcFdemoScreen) of Class slot 0x161 (table 0xe80cf6, 37 entries, InitializeMurai): its parent, allsize, selfsize, name, propdata and propname; its proc word, bytes 0-3, ends the slice before.
NakaData_SoundMenuDrawbar:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x0, 0x14
; [nakarest] naka_sound_menu_drawbar+0x14  +0x14..+0xa4 (0xe80ff6, 144 B)
; [nakarest] class definition entries 32-36 of Class slot 0x161 (table 0xe80cf6, 37 entries,
; [nakarest] InitializeMurai) (24 bytes each: proc, parent, allsize, selfsize, name, propdata,
; [nakarest] propname): AcSndEMenu, AcPleaseWait, AcDrawSetting, AcDrawbarName, IvMPver.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14, 0x90
; [nakarest] naka_sound_menu_drawbar+0xa4  +0xa4..+0xa6 (0xe81086, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 36 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvMPver "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xA4, 0x2
; [nakarest] naka_sound_menu_drawbar+0xa6  +0xa6..+0xae (0xe81088, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 36 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvMPver.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xA6, 0x8
; [nakarest] naka_sound_menu_drawbar+0xae  +0xae..+0xb2 (0xe81090, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 35 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawbarName "ue".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xAE, 0x4
; [nakarest] naka_sound_menu_drawbar+0xb2  +0xb2..+0xc0 (0xe81094, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 35 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawbarName.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xB2, 0xE
; [nakarest] naka_sound_menu_drawbar+0xc0  +0xc0..+0xc4 (0xe810a2, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 34 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawSetting "AA".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xC0, 0x4
; [nakarest] naka_sound_menu_drawbar+0xc4  +0xc4..+0xd2 (0xe810a6, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 34 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawSetting.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xC4, 0xE
; [nakarest] naka_sound_menu_drawbar+0xd2  +0xd2..+0xd4 (0xe810b4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 33 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPleaseWait "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xD2, 0x2
; [nakarest] naka_sound_menu_drawbar+0xd4  +0xd4..+0xe2 (0xe810b6, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 33 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPleaseWait.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xD4, 0xE
; [nakarest] naka_sound_menu_drawbar+0xe2  +0xe2..+0xe4 (0xe810c4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 32 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcSndEMenu "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xE2, 0x2
; [nakarest] naka_sound_menu_drawbar+0xe4  +0xe4..+0xf0 (0xe810c6, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 32 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcSndEMenu.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xE4, 0xC
; [nakarest] naka_sound_menu_drawbar+0xf0  +0xf0..+0xf2 (0xe810d2, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 31 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcFdemoScreen "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xF0, 0x2
; [nakarest] naka_sound_menu_drawbar+0xf2  +0xf2..+0x100 (0xe810d4, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 31 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcFdemoScreen.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0xF2, 0xE
; [nakarest] naka_sound_menu_drawbar+0x100  +0x100..+0x102 (0xe810e2, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 30 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): VwUserBitmapSp "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x100, 0x2
; [nakarest] naka_sound_menu_drawbar+0x102  +0x102..+0x112 (0xe810e4, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 30 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): VwUserBitmapSp.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x102, 0x10
; [nakarest] naka_sound_menu_drawbar+0x112  +0x112..+0x118 (0xe810f4, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 29 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPresentationBox "XemA".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x112, 0x6
; [nakarest] naka_sound_menu_drawbar+0x118  +0x118..+0x12a (0xe810fa, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 29 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPresentationBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x118, 0x12
; [nakarest] naka_sound_menu_drawbar+0x12a  +0x12a..+0x12e (0xe8110c, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 28 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcLswPartPan "jn".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x12A, 0x4
; [nakarest] naka_sound_menu_drawbar+0x12e  +0x12e..+0x13c (0xe81110, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 28 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcLswPartPan.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x12E, 0xE
; [nakarest] naka_sound_menu_drawbar+0x13c  +0x13c..+0x13e (0xe8111e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 27 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawEditBox "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x13C, 0x2
; [nakarest] naka_sound_menu_drawbar+0x13e  +0x13e..+0x14c (0xe81120, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 27 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcDrawEditBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x13E, 0xE
; [nakarest] naka_sound_menu_drawbar+0x14c  +0x14c..+0x14e (0xe8112e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 26 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDemofeature2 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14C, 0x2
; [nakarest] naka_sound_menu_drawbar+0x14e  +0x14e..+0x15e (0xe81130, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 26 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDemofeature2.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x14E, 0x10
; [nakarest] naka_sound_menu_drawbar+0x15e  +0x15e..+0x160 (0xe81140, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 25 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDemofeature1 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x15E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x160  +0x160..+0x170 (0xe81142, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 25 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDemofeature1.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x160, 0x10
; [nakarest] naka_sound_menu_drawbar+0x170  +0x170..+0x172 (0xe81152, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 24 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPresentationControl "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x170, 0x2
; [nakarest] naka_sound_menu_drawbar+0x172  +0x172..+0x188 (0xe81154, 22 B)
; [nakarest] class-name strings (the +12 name) of classes 24 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPresentationControl.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x172, 0x16
; [nakarest] naka_sound_menu_drawbar+0x188  +0x188..+0x18e (0xe8116a, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 23 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): PsVariBox "c^dem".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x188, 0x6
; [nakarest] naka_sound_menu_drawbar+0x18e  +0x18e..+0x198 (0xe81170, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 23 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): PsVariBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x18E, 0xA
; [nakarest] naka_sound_menu_drawbar+0x198  +0x198..+0x19a (0xe8117a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 22 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcResetPage "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x198, 0x2
; [nakarest] naka_sound_menu_drawbar+0x19a  +0x19a..+0x1a6 (0xe8117c, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 22 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcResetPage.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x19A, 0xC
; [nakarest] naka_sound_menu_drawbar+0x1a6  +0x1a6..+0x1a8 (0xe81188, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 21 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbarSndE "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1A6, 0x2
; [nakarest] naka_sound_menu_drawbar+0x1a8  +0x1a8..+0x1b6 (0xe8118a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 21 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbarSndE.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1A8, 0xE
; [nakarest] naka_sound_menu_drawbar+0x1b6  +0x1b6..+0x1b8 (0xe81198, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 20 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbarNorm "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1B6, 0x2
; [nakarest] naka_sound_menu_drawbar+0x1b8  +0x1b8..+0x1c6 (0xe8119a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 20 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbarNorm.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1B8, 0xE
; [nakarest] naka_sound_menu_drawbar+0x1c6  +0x1c6..+0x1c8 (0xe811a8, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 19 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar2 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1C6, 0x2
; [nakarest] naka_sound_menu_drawbar+0x1c8  +0x1c8..+0x1d4 (0xe811aa, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 19 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar2.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1C8, 0xC
; [nakarest] naka_sound_menu_drawbar+0x1d4  +0x1d4..+0x1d6 (0xe811b6, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 18 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar1 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1D4, 0x2
; [nakarest] naka_sound_menu_drawbar+0x1d6  +0x1d6..+0x1e2 (0xe811b8, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 18 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar1.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1D6, 0xC
; [nakarest] naka_sound_menu_drawbar+0x1e2  +0x1e2..+0x1e4 (0xe811c4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 17 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1E2, 0x2
; [nakarest] naka_sound_menu_drawbar+0x1e4  +0x1e4..+0x1ee (0xe811c6, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 17 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvDrawbar.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1E4, 0xA
; [nakarest] naka_sound_menu_drawbar+0x1ee  +0x1ee..+0x1f2 (0xe811d0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 16 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvPageOverWrite "At".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1EE, 0x4
; [nakarest] naka_sound_menu_drawbar+0x1f2  +0x1f2..+0x202 (0xe811d4, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 16 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvPageOverWrite.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x1F2, 0x10
; [nakarest] naka_sound_menu_drawbar+0x202  +0x202..+0x204 (0xe811e4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 15 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSoftver "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x202, 0x2
; [nakarest] naka_sound_menu_drawbar+0x204  +0x204..+0x20e (0xe811e6, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 15 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSoftver.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x204, 0xA
; [nakarest] naka_sound_menu_drawbar+0x20e  +0x20e..+0x210 (0xe811f0, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 14 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcTrackMixer "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x20E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x210  +0x210..+0x21e (0xe811f2, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 14 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcTrackMixer.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x210, 0xE
; [nakarest] naka_sound_menu_drawbar+0x21e  +0x21e..+0x220 (0xe81200, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 13 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPartMixer "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x21E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x220  +0x220..+0x22c (0xe81202, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 13 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcPartMixer.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x220, 0xC
; [nakarest] naka_sound_menu_drawbar+0x22c  +0x22c..+0x22e (0xe8120e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 12 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): PsMixerControl "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x22C, 0x2
; [nakarest] naka_sound_menu_drawbar+0x22e  +0x22e..+0x23e (0xe81210, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 12 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): PsMixerControl.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x22E, 0x10
; [nakarest] naka_sound_menu_drawbar+0x23e  +0x23e..+0x240 (0xe81220, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 11 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcWelcomScreen "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x23E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x240  +0x240..+0x250 (0xe81222, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 11 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcWelcomScreen.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x240, 0x10
; [nakarest] naka_sound_menu_drawbar+0x250  +0x250..+0x252 (0xe81232, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 10 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSdscltyp2 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x250, 0x2
; [nakarest] naka_sound_menu_drawbar+0x252  +0x252..+0x25e (0xe81234, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 10 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSdscltyp2.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x252, 0xC
; [nakarest] naka_sound_menu_drawbar+0x25e  +0x25e..+0x260 (0xe81240, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 9 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSdtecd1 "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x25E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x260  +0x260..+0x26a (0xe81242, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 9 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvSdtecd1.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x260, 0xA
; [nakarest] naka_sound_menu_drawbar+0x26a  +0x26a..+0x26c (0xe8124c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 8 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSdtecd "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x26A, 0x2
; [nakarest] naka_sound_menu_drawbar+0x26c  +0x26c..+0x276 (0xe8124e, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 8 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvSdtecd.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x26C, 0xA
; [nakarest] naka_sound_menu_drawbar+0x276  +0x276..+0x27e (0xe81258, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 7 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): PsLabelBox "Xc^dmm".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x276, 0x8
; [nakarest] naka_sound_menu_drawbar+0x27e  +0x27e..+0x28a (0xe81260, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 7 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): PsLabelBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x27E, 0xC
; [nakarest] naka_sound_menu_drawbar+0x28a  +0x28a..+0x28e (0xe8126c, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 6 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcAccordionTab "XX".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x28A, 0x4
; [nakarest] naka_sound_menu_drawbar+0x28e  +0x28e..+0x29e (0xe81270, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 6 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): AcAccordionTab.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x28E, 0x10
; [nakarest] naka_sound_menu_drawbar+0x29e  +0x29e..+0x2a0 (0xe81280, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 5 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvAccordionX "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x29E, 0x2
; [nakarest] naka_sound_menu_drawbar+0x2a0  +0x2a0..+0x2ae (0xe81282, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 5 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvAccordionX.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2A0, 0xE
; [nakarest] naka_sound_menu_drawbar+0x2ae  +0x2ae..+0x2b0 (0xe81290, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 4 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvAccordion "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2AE, 0x2
; [nakarest] naka_sound_menu_drawbar+0x2b0  +0x2b0..+0x2bc (0xe81292, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 4 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvAccordion.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2B0, 0xC
; [nakarest] naka_sound_menu_drawbar+0x2bc  +0x2bc..+0x2be (0xe8129e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 3 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvMesage "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2BC, 0x2
; [nakarest] naka_sound_menu_drawbar+0x2be  +0x2be..+0x2c8 (0xe812a0, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 3 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvMesage.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2BE, 0xA
; [nakarest] naka_sound_menu_drawbar+0x2c8  +0x2c8..+0x2cc (0xe812aa, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 2 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcVolPartEditBox "jjn".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2C8, 0x4
; [nakarest] naka_sound_menu_drawbar+0x2cc  +0x2cc..+0x2de (0xe812ae, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 2 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): AcVolPartEditBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2CC, 0x12
; [nakarest] naka_sound_menu_drawbar+0x2de  +0x2de..+0x2e2 (0xe812c0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 1 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): AcLswPartEditBox "jn".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2DE, 0x4
; [nakarest] naka_sound_menu_drawbar+0x2e2  +0x2e2..+0x2f4 (0xe812c4, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 1 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): AcLswPartEditBox.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2E2, 0x12
; [nakarest] naka_sound_menu_drawbar+0x2f4  +0x2f4..+0x2f6 (0xe812d6, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 0 of Class slot 0x161 (table
; [nakarest] 0xe80cf6, 37 entries, InitializeMurai): IvSdpart "".
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2F4, 0x2
; [nakarest] naka_sound_menu_drawbar+0x2f6  +0x2f6..+0x300 (0xe812d8, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 0 of Class slot 0x161 (table 0xe80cf6,
; [nakarest] 37 entries, InitializeMurai): IvSdpart.
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x2F6, 0xA
; [nakarest] naka_sound_menu_drawbar+0x300  +0x300..+0x302 (0xe812e2, 2 B)
; [nakarest] Text (2 B at 0xe812e2), first string "%"; no registered NAKA table points into it;
; [nakarest] reached through source references InitializeMurai (ui/drawbar_panel_ui.s:
; [nakarest] `RegObjTable 0x1600004, 0xfa44e2, 0xe812e2, 0xe80cf6, 0x161`).
Murai_ClassCount_161:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x300, 0x2
; [nakarest] naka_sound_menu_drawbar+0x302  +0x302..+0x306 (0xe812e4, 4 B)
; [nakarest] the table itself: ResEvent slot 0x1c1 (table 0xe812e4, 10 entries,
; [nakarest] InitializeMurai), 10 entry pointers x 4 bytes.
Murai_ResEventTable_1C1:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x302, 0x4
; [nakarest] Naka_EventDispatch_Table  +0x306..+0x32e (0xe812e8, 40 B)
; [nakarest] 4 B at 0xe8130c: the end marker of ResEvent slot 0x1c1 (table 0xe812e4, 10 entries, InitializeMurai) -- a zero word after entry 9, the last, as every ResEvent table ends.
; [nakarest] Continues the table itself: ResEvent slot 0x1c1 (table 0xe812e4, 10 entries,
; [nakarest] InitializeMurai), 10 entry pointers x 4 bytes (starts 0xe812e4, 36 of its 40 bytes
; [nakarest] are here or later).
Naka_EventDispatch_Table:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x306, 0x28
; [nakarest] naka_sound_menu_drawbar+0x32e  +0x32e..+0x3c2 (0xe81310, 148 B)
; [nakarest] name strings, entries 0-9 of ResEvent slot 0x1c1 (table 0xe812e4, 10 entries,
; [nakarest] InitializeMurai): "EV_MPVERSION", "EV_TONEMODE", "EV_EXECPRESENTATION",
; [nakarest] "EV_ENDSONG", "EV_STARTSONG", "EV_ALLINITIAL", ....
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x32E, 0x94
; [nakarest] naka_sound_menu_drawbar+0x3c2  +0x3c2..+0x3c4 (0xe813a4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe813a4 not derived; readers below
; [nakarest] Readers: source references InitializeMurai (ui/drawbar_panel_ui.s: `RegObjTable
; [nakarest] 0x160000c, 0xfa58fb, 0xe813a4, 0xe812e4, 0x1c1`).
Murai_ResEventCount_1C1:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x3C2, 0x2
; [nakarest] Naka_Event_Table3  +0x3c4..+0x404 (0xe813a6, 64 B)
; [nakarest] the table itself: ResMethod slot 0x1e1 (table 0xe813a6, 15 entries,
; [nakarest] InitializeMurai), 15 entry pointers x 4 bytes.
Naka_Event_Table3:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x3C4, 0x40
; [nakarest] naka_sound_menu_drawbar+0x404  +0x404..+0x510 (0xe813e6, 268 B)
; [nakarest] name strings, entries 0-14 of ResMethod slot 0x1e1 (table 0xe813a6, 15 entries,
; [nakarest] InitializeMurai): "MT_GetToneMode", "MT_ExitPresentation", "MT_InitPresentation",
; [nakarest] "MT_ExistPresentation", "MT_SetMemoryDrawbar", "MT_RequestMemoryDrawbar", ....
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x404, 0x10C
; [nakarest] naka_sound_menu_drawbar+0x510  +0x510..+0x512 (0xe814f2, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe814f2 not derived; readers below
; [nakarest] Readers: source references InitializeMurai (ui/drawbar_panel_ui.s: `RegObjTable
; [nakarest] 0x160000d, 0xfa5948, 0xe814f2, 0xe813a6, 0x1e1`).
Murai_ResMethodCount_1E1:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x510, 0x2
; [nakarest] naka_sound_menu_drawbar+0x512  +0x512..+0x5aa (0xe814f4, 152 B)
; [nakarest] the table itself: Function slot 0x101 (table 0xe814f4, 37 entries,
; [nakarest] InitializeMurai), 37 entry pointers x 4 bytes.
Murai_FunctionTable_101:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x512, 0x98
; [nakarest] naka_sound_menu_drawbar+0x5aa  +0x5aa..+0x5ae (0xe8158c, 4 B)
; [nakarest] the table itself: Function slot 0x401 (table 0xe8158c, 37 entries,
; [nakarest] InitializeMurai), 37 entry pointers x 4 bytes.
Murai_FunctionTable_401:	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x5AA, 0x4
; [nakarest] Naka_Event_Table2  +0x5ae..+0x642 (0xe81590, 148 B)
; [nakarest] 4 B at 0xe81620: the end marker of Function slot 0x401 (table 0xe8158c, 37 entries, InitializeMurai) -- entry 37, a pointer to the empty string right after it ("", 00 ff, which starts the next slice), as every function name table ends.
; [nakarest] Continues the table itself: Function slot 0x401 (table 0xe8158c, 37 entries,
; [nakarest] InitializeMurai), 37 entry pointers x 4 bytes (starts 0xe8158c, 144 of its 148
; [nakarest] bytes are here or later).
Naka_Event_Table2:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x5AE, 0x94
; [nakarest] NakaInst_EmptyString  +0x642..+0x644 (0xe81624, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe81624 not derived; readers below
; [nakarest] Readers: 1 data word in Naka_Event_Table2 (at 0xe81620).
NakaInst_EmptyString:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x642, 0x2
; [nakarest] naka_sound_menu_drawbar+0x644  +0x644..+0x8c0 (0xe81626, 636 B)
; [nakarest] name strings, entries 1-36 of Function slot 0x401 (table 0xe8158c, 37 entries,
; [nakarest] InitializeMurai) (names for Function slot 0x101): "IvMPverProc",
; [nakarest] "AcDrawbarNameProc", "AcDrawSettingProc", "AcPleaseWaitProc", "AcSndEMenuProc",
; [nakarest] "AcFdemoScreenProc", ....
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x644, 0x27C
; [nakarest] NakaInst_IvSdpartProc  +0x8c0..+0x8ce (0xe818a2, 14 B)
; [nakarest] name string, entry 0 of Function slot 0x401 (table 0xe8158c, 37 entries,
; [nakarest] InitializeMurai) (names for Function slot 0x101): "IvSdpartProc".
NakaInst_IvSdpartProc:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8C0, 0xE
; [nakarest] NakaContainer_SoundMenu_Root  +0x8ce..+0x8f8 (0xe818b0, 42 B)
; [nakarest] widget record, element 0 of Viewable slot 0x2 (table 0xe85470, 20 entries,
; [nakarest] InitializeMurai) ("Sdmenu"): TtlScreen (42 B).
NakaContainer_SoundMenu_Root:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8CE, 0x2A
; [nakarest] NakaDesc_SOUND_MENU  +0x8f8..+0x904 (0xe818da, 12 B)
; [nakarest] 1 text the records point at (Viewable slot 0x2 (table 0xe85470, 20 entries,
; [nakarest] InitializeMurai)): "SOUND MENU" (TtlScreen.title of element 0).
NakaDesc_SOUND_MENU:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x8F8, 0xC
; [nakarest] NakaWidget_SoundMenu_PageButton  +0x904..+0x90a (0xe818e6, 6 B)
; [nakarest] widget record, element 1 of Viewable slot 0x2 (table 0xe85470, 20 entries,
; [nakarest] InitializeMurai) ("Sdmenu"): AcWindowPage (36 B).
NakaWidget_SoundMenu_PageButton:
	.incbin "includes/generated/naka_sound_menu_drawbar.bin", 0x904, 0x6
; External label offsets within the binary blob above.
