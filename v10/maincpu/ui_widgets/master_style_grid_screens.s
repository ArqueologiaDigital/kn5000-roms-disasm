
; Master Style Grid screens (28 widgets, 944 bytes)
; Source: maincpu/ui_widgets/naka_master_style.c (raw byte array from ROM)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_master_style
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
; Class slot 0x162: RegObjTable 0x1600004, ClassProc, 0xed2d02,
; 0xed27e4, 0x162 in InitializeToshi (extensions/extension_init.s) --
; the count, 28, is the word at 0xed2d02; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x162.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_MasterStyleGrid
; NakaData_MasterStyleGrid  --  naka_master_style +0x0..+0x14 (ROM 0xed27e8..0xed27fc), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xed27e8..0xed27fc); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_MasterStyleGrid:
	.incbin "includes/generated/naka_master_style.bin", 0x0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x14
; naka_master_style+0x14  --  naka_master_style +0x14..+0x2b4 (ROM 0xed27fc..0xed2a9c), 672 bytes
; Class definitions 1-27 of Class slot 0x162 (table 0xed27e4, 28
; entries, InitializeToshi): VariScreen, RVariScreen, TransposeBox,
; ChordBox, FreeSplitBox, BkNoBox, PmBkNoBox, PmBankScreen,
; AcPmBkEditBox, MsaModeScreen, .... 24 bytes each: +0 proc, +4 parent
; (class id), +8 allsize, +10 selfsize, +12 name, +16 propdata, +20
; propname -- the firmware's own field names, from the propname table of
; the root class "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x14, 0x2A0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2b4
; naka_master_style+0x2b4  --  naka_master_style +0x2b4..+0x2b8 (ROM 0xed2a9c..0xed2aa0), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 27 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (IvPageOverWr): "At".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2B4, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2b8
; naka_master_style+0x2b8  --  naka_master_style +0x2b8..+0x2c6 (ROM 0xed2aa0..0xed2aae), 14 bytes
; Class-name strings (the +12 name of classes 27 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): IvPageOverWr.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2B8, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2c6
; naka_master_style+0x2c6  --  naka_master_style +0x2c6..+0x2cc (ROM 0xed2aae..0xed2ab4), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 26 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (SineWaveScreen): "kc^nn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2C6, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2cc
; naka_master_style+0x2cc  --  naka_master_style +0x2cc..+0x2dc (ROM 0xed2ab4..0xed2ac4), 16 bytes
; Class-name strings (the +12 name of classes 26 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): SineWaveScreen.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2CC, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2dc
; naka_master_style+0x2dc  --  naka_master_style +0x2dc..+0x2e8 (ROM 0xed2ac4..0xed2ad0), 12 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 25 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstSong2GridBox): "XXjnnnnnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2DC, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2e8
; naka_master_style+0x2e8  --  naka_master_style +0x2e8..+0x2fa (ROM 0xed2ad0..0xed2ae2), 18 bytes
; Class-name strings (the +12 name of classes 25 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstSong2GridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2E8, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x2fa
; naka_master_style+0x2fa  --  naka_master_style +0x2fa..+0x302 (ROM 0xed2ae2..0xed2aea), 8 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 24 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstSong1GridBox): "XXjnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x2FA, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x302
; naka_master_style+0x302  --  naka_master_style +0x302..+0x314 (ROM 0xed2aea..0xed2afc), 18 bytes
; Class-name strings (the +12 name of classes 24 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstSong1GridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x302, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x314
; naka_master_style+0x314  --  naka_master_style +0x314..+0x320 (ROM 0xed2afc..0xed2b08), 12 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 23 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstStyle2GridBox): "XXjnnnnnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x314, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x320
; naka_master_style+0x320  --  naka_master_style +0x320..+0x334 (ROM 0xed2b08..0xed2b1c), 20 bytes
; Class-name strings (the +12 name of classes 23 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstStyle2GridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x320, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x334
; naka_master_style+0x334  --  naka_master_style +0x334..+0x33c (ROM 0xed2b1c..0xed2b24), 8 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 22 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstStyle1SubGridBox): "XXjnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x334, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x33c
; naka_master_style+0x33c  --  naka_master_style +0x33c..+0x352 (ROM 0xed2b24..0xed2b3a), 22 bytes
; Class-name strings (the +12 name of classes 22 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstStyle1SubGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x33C, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x352
; naka_master_style+0x352  --  naka_master_style +0x352..+0x35a (ROM 0xed2b3a..0xed2b42), 8 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 21 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstStyle1GridBox): "XXjnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x352, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x35a
; naka_master_style+0x35a  --  naka_master_style +0x35a..+0x36e (ROM 0xed2b42..0xed2b56), 20 bytes
; Class-name strings (the +12 name of classes 21 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstStyle1GridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x35A, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x36e
; naka_master_style+0x36e  --  naka_master_style +0x36e..+0x378 (ROM 0xed2b56..0xed2b60), 10 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 20 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstStyleAlpGridBox): "XXjnnnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x36E, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x378
; naka_master_style+0x378  --  naka_master_style +0x378..+0x38e (ROM 0xed2b60..0xed2b76), 22 bytes
; Class-name strings (the +12 name of classes 20 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstStyleAlpGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x378, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x38e
; naka_master_style+0x38e  --  naka_master_style +0x38e..+0x39a (ROM 0xed2b76..0xed2b82), 12 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 19 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcMstSugAlpGridBox): "XXjnnnnnnn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x38E, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x39a
; naka_master_style+0x39a  --  naka_master_style +0x39a..+0x3ae (ROM 0xed2b82..0xed2b96), 20 bytes
; Class-name strings (the +12 name of classes 19 of Class slot 0x162
; (table 0xed27e4, 28 entries, InitializeToshi)): AcMstSugAlpGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x39A, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_master_style+0x3ae
; naka_master_style+0x3ae  --  naka_master_style +0x3ae..+0x3b0 (ROM 0xed2b96..0xed2b98), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 18 of Class slot 0x162 (table 0xed27e4, 28 entries,
; InitializeToshi) (AcDispTimeSetGridBox): "XXj".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_master_style.bin", 0x3AE, 0x2
