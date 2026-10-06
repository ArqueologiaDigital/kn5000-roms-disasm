
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
; Class slot 0x162: RegObjTable 0x1600004, ClassProc, 0xed2d02,
; 0xed27e4, 0x162 in InitializeToshi (extensions/extension_init.s) --
; the count, 28, is the word at 0xed2d02; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x162.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_MasterStyleGrid  +0x0..+0x14 (0xed27e8, 20 B)
; [nakarest] bytes 4-23 of class definition 0 (NormScreen) of Class slot 0x162 (table 0xed27e4, 28 entries, InitializeToshi): its parent, allsize, selfsize, name, propdata and propname; its proc word, bytes 0-3, ends the slice before.
NakaData_MasterStyleGrid:	.incbin "includes/generated/naka_master_style.bin", 0x0, 0x14
; [nakarest] naka_master_style+0x14  +0x14..+0x2b4 (0xed27fc, 672 B)
; [nakarest] class definition entries 1-27 of Class slot 0x162 (table 0xed27e4, 28 entries,
; [nakarest] InitializeToshi) (24 bytes each: proc, parent, allsize, selfsize, name, propdata,
; [nakarest] propname): VariScreen, RVariScreen, TransposeBox, ChordBox, FreeSplitBox, BkNoBox,
; [nakarest] PmBkNoBox, PmBankScreen, AcPmBkEditBox, MsaModeScreen, ....
	.incbin "includes/generated/naka_master_style.bin", 0x14, 0x2A0
; [nakarest] naka_master_style+0x2b4  +0x2b4..+0x2b8 (0xed2a9c, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 27 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): IvPageOverWr "At".
	.incbin "includes/generated/naka_master_style.bin", 0x2B4, 0x4
; [nakarest] naka_master_style+0x2b8  +0x2b8..+0x2c6 (0xed2aa0, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 27 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): IvPageOverWr.
	.incbin "includes/generated/naka_master_style.bin", 0x2B8, 0xE
; [nakarest] naka_master_style+0x2c6  +0x2c6..+0x2cc (0xed2aae, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 26 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): SineWaveScreen "kc^nn".
	.incbin "includes/generated/naka_master_style.bin", 0x2C6, 0x6
; [nakarest] naka_master_style+0x2cc  +0x2cc..+0x2dc (0xed2ab4, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 26 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): SineWaveScreen.
	.incbin "includes/generated/naka_master_style.bin", 0x2CC, 0x10
; [nakarest] naka_master_style+0x2dc  +0x2dc..+0x2e8 (0xed2ac4, 12 B)
; [nakarest] propdata strings (the +16 field signature) of class 25 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSong2GridBox "XXjnnnnnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x2DC, 0xC
; [nakarest] naka_master_style+0x2e8  +0x2e8..+0x2fa (0xed2ad0, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 25 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSong2GridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x2E8, 0x12
; [nakarest] naka_master_style+0x2fa  +0x2fa..+0x302 (0xed2ae2, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 24 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSong1GridBox "XXjnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x2FA, 0x8
; [nakarest] naka_master_style+0x302  +0x302..+0x314 (0xed2aea, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 24 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSong1GridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x302, 0x12
; [nakarest] naka_master_style+0x314  +0x314..+0x320 (0xed2afc, 12 B)
; [nakarest] propdata strings (the +16 field signature) of class 23 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle2GridBox "XXjnnnnnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x314, 0xC
; [nakarest] naka_master_style+0x320  +0x320..+0x334 (0xed2b08, 20 B)
; [nakarest] class-name strings (the +12 name) of classes 23 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle2GridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x320, 0x14
; [nakarest] naka_master_style+0x334  +0x334..+0x33c (0xed2b1c, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 22 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle1SubGridBox "XXjnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x334, 0x8
; [nakarest] naka_master_style+0x33c  +0x33c..+0x352 (0xed2b24, 22 B)
; [nakarest] class-name strings (the +12 name) of classes 22 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle1SubGridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x33C, 0x16
; [nakarest] naka_master_style+0x352  +0x352..+0x35a (0xed2b3a, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 21 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle1GridBox "XXjnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x352, 0x8
; [nakarest] naka_master_style+0x35a  +0x35a..+0x36e (0xed2b42, 20 B)
; [nakarest] class-name strings (the +12 name) of classes 21 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyle1GridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x35A, 0x14
; [nakarest] naka_master_style+0x36e  +0x36e..+0x378 (0xed2b56, 10 B)
; [nakarest] propdata strings (the +16 field signature) of class 20 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyleAlpGridBox "XXjnnnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x36E, 0xA
; [nakarest] naka_master_style+0x378  +0x378..+0x38e (0xed2b60, 22 B)
; [nakarest] class-name strings (the +12 name) of classes 20 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstStyleAlpGridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x378, 0x16
; [nakarest] naka_master_style+0x38e  +0x38e..+0x39a (0xed2b76, 12 B)
; [nakarest] propdata strings (the +16 field signature) of class 19 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSugAlpGridBox "XXjnnnnnnn".
	.incbin "includes/generated/naka_master_style.bin", 0x38E, 0xC
; [nakarest] naka_master_style+0x39a  +0x39a..+0x3ae (0xed2b82, 20 B)
; [nakarest] class-name strings (the +12 name) of classes 19 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcMstSugAlpGridBox.
	.incbin "includes/generated/naka_master_style.bin", 0x39A, 0x14
; [nakarest] naka_master_style+0x3ae  +0x3ae..+0x3b0 (0xed2b96, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 18 of Class slot 0x162 (table
; [nakarest] 0xed27e4, 28 entries, InitializeToshi): AcDispTimeSetGridBox "XXj".
	.incbin "includes/generated/naka_master_style.bin", 0x3AE, 0x2
