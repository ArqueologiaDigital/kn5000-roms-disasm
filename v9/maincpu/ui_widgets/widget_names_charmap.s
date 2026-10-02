
; Widget Name Strings & Character Map Data (2 widgets, 22158 bytes)
; Source: maincpu/ui_widgets/naka_widget_names_charmap.c (raw byte array)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_widget_names_charmap
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
; Viewable slot 0x0: RegObjTabl 0x1600010, ViewableProc, 0x33, 0xeb3374,
; 0x0 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 51, table} at 0x27ed2 +
; 14*0x0. Element 0 is named "PanelSimulator" in ResName slot 0x300.
; Links: 5 of 51 records have a disagreeing link (elements 22-26);
; elements 23-25 point outside the program ROM (RAM records).
;
; Function slot 0x100: RegObjTabl 0x1600001, FunctionProc, 0x160,
; 0xeafa6e, 0x100 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 352, table} at 0x27ed2 +
; 14*0x100.
;
; Class slot 0x160: RegObjTable 0x1600004, ClassProc, 0xeada92,
; 0xeac9ee, 0x160 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 109, is the word at 0xeada92; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x160.
;
; ResEvent slot 0x1c0: RegObjTable 0x160000c, ResEventProc, 0xeaebb0,
; 0xeae7b6, 0x1c0 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 60, is the word at 0xeaebb0; RegisterObjectTable stores {class,
; proc, count, table} at 0x27ed2 + 14*0x1c0.
;
; ResMethod slot 0x1e0: RegObjTable 0x160000d, ResMethodProc, 0xeafa6c,
; 0xeaebb2, 0x1e0 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 188, is the word at 0xeafa6c; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x1e0.
;
; Function slot 0x400: RegObjTabl 0x1600001, FunctionProc, 0x160,
; 0xeafff2, 0x400 in InitializeRoot (display/graphics_text_vga.s), i.e.
; RegisterObjectTable stores {class, proc, 352, table} at 0x27ed2 +
; 14*0x400.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_WidgetNames  +0x0..+0x2 (0xead470, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 105 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwUserBitmap "j".
NakaData_WidgetNames:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x0, 0x2
; [nakarest] naka_widget_names_charmap+0x2  +0x2..+0x10 (0xead472, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 105 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwUserBitmap.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2, 0xE
; [nakarest] naka_widget_names_charmap+0x10  +0x10..+0x12 (0xead480, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 104 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TrChordBox "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x10, 0x2
; [nakarest] naka_widget_names_charmap+0x12  +0x12..+0x1e (0xead482, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 104 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TrChordBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x12, 0xC
; [nakarest] naka_widget_names_charmap+0x1e  +0x1e..+0x20 (0xead48e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 103 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TrTransposeBox "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1E, 0x2
; [nakarest] naka_widget_names_charmap+0x20  +0x20..+0x30 (0xead490, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 103 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TrTransposeBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x20, 0x10
; [nakarest] naka_widget_names_charmap+0x30  +0x30..+0x32 (0xead4a0, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 102 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLanguageText "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x30, 0x2
; [nakarest] naka_widget_names_charmap+0x32  +0x32..+0x42 (0xead4a2, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 102 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLanguageText.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32, 0x10
; [nakarest] naka_widget_names_charmap+0x42  +0x42..+0x48 (0xead4b2, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 101 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTextBox "c^dB".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42, 0x6
; [nakarest] naka_widget_names_charmap+0x48  +0x48..+0x52 (0xead4b8, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 101 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTextBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48, 0xA
; [nakarest] naka_widget_names_charmap+0x52  +0x52..+0x54 (0xead4c2, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 100 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvShowHide "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52, 0x2
; [nakarest] naka_widget_names_charmap+0x54  +0x54..+0x60 (0xead4c4, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 100 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvShowHide.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54, 0xC
; [nakarest] naka_widget_names_charmap+0x60  +0x60..+0x62 (0xead4d0, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 99 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntEasySet "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x60, 0x2
; [nakarest] naka_widget_names_charmap+0x62  +0x62..+0x70 (0xead4d2, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 99 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntEasySet.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x62, 0xE
; [nakarest] naka_widget_names_charmap+0x70  +0x70..+0x72 (0xead4e0, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 98 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntVari "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x70, 0x2
; [nakarest] naka_widget_names_charmap+0x72  +0x72..+0x7c (0xead4e2, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 98 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntVari.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x72, 0xA
; [nakarest] naka_widget_names_charmap+0x7c  +0x7c..+0x7e (0xead4ec, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 97 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntComplete "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x7C, 0x2
; [nakarest] naka_widget_names_charmap+0x7e  +0x7e..+0x8c (0xead4ee, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 97 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntComplete.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x7E, 0xE
; [nakarest] naka_widget_names_charmap+0x8c  +0x8c..+0x8e (0xead4fc, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 96 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntError "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x8C, 0x2
; [nakarest] naka_widget_names_charmap+0x8e  +0x8e..+0x9a (0xead4fe, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 96 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntError.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x8E, 0xC
; [nakarest] naka_widget_names_charmap+0x9a  +0x9a..+0x9c (0xead50a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 95 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntReminder "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x9A, 0x2
; [nakarest] naka_widget_names_charmap+0x9c  +0x9c..+0xaa (0xead50c, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 95 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntReminder.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x9C, 0xE
; [nakarest] naka_widget_names_charmap+0xaa  +0xaa..+0xac (0xead51a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 94 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvInterrupt "w".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xAA, 0x2
; [nakarest] naka_widget_names_charmap+0xac  +0xac..+0xb8 (0xead51c, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 94 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvInterrupt.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xAC, 0xC
; [nakarest] naka_widget_names_charmap+0xb8  +0xb8..+0xba (0xead528, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 93 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbMemoryDump "s".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xB8, 0x2
; [nakarest] naka_widget_names_charmap+0xba  +0xba..+0xc8 (0xead52a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 93 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbMemoryDump.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xBA, 0xE
; [nakarest] naka_widget_names_charmap+0xc8  +0xc8..+0xca (0xead538, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 92 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitWindow "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xC8, 0x2
; [nakarest] naka_widget_names_charmap+0xca  +0xca..+0xd8 (0xead53a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 92 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitWindow.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xCA, 0xE
; [nakarest] naka_widget_names_charmap+0xd8  +0xd8..+0xda (0xead548, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 91 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvTrackSwitch "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xD8, 0x2
; [nakarest] naka_widget_names_charmap+0xda  +0xda..+0xe8 (0xead54a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 91 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvTrackSwitch.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xDA, 0xE
; [nakarest] naka_widget_names_charmap+0xe8  +0xe8..+0xea (0xead558, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 90 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvDirmdScreen "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xE8, 0x2
; [nakarest] naka_widget_names_charmap+0xea  +0xea..+0xf8 (0xead55a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 90 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvDirmdScreen.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xEA, 0xE
; [nakarest] naka_widget_names_charmap+0xf8  +0xf8..+0xfa (0xead568, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 89 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTrackSwitch "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xF8, 0x2
; [nakarest] naka_widget_names_charmap+0xfa  +0xfa..+0x108 (0xead56a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 89 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTrackSwitch.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0xFA, 0xE
; [nakarest] naka_widget_names_charmap+0x108  +0x108..+0x10e (0xead578, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 88 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTrackSwitch "vmnn".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x108, 0x6
; [nakarest] naka_widget_names_charmap+0x10e  +0x10e..+0x11c (0xead57e, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 88 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTrackSwitch.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x10E, 0xE
; [nakarest] naka_widget_names_charmap+0x11c  +0x11c..+0x11e (0xead58c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 87 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbDebugMenu "n".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x11C, 0x2
; [nakarest] naka_widget_names_charmap+0x11e  +0x11e..+0x12a (0xead58e, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 87 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbDebugMenu.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x11E, 0xC
; [nakarest] naka_widget_names_charmap+0x12a  +0x12a..+0x12e (0xead59a, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 86 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcGridBox "XXj".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x12A, 0x4
; [nakarest] naka_widget_names_charmap+0x12e  +0x12e..+0x138 (0xead59e, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 86 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcGridBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x12E, 0xA
; [nakarest] naka_widget_names_charmap+0x138  +0x138..+0x13c (0xead5a8, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 85 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcListBox "XG".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x138, 0x4
; [nakarest] naka_widget_names_charmap+0x13c  +0x13c..+0x146 (0xead5ac, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 85 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcListBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x13C, 0xA
; [nakarest] naka_widget_names_charmap+0x146  +0x146..+0x152 (0xead5b6, 12 B)
; [nakarest] propdata strings (the +16 field signature) of class 84 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsGridBox "c^dBBGnnsss".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x146, 0xC
; [nakarest] naka_widget_names_charmap+0x152  +0x152..+0x15c (0xead5c2, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 84 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsGridBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x152, 0xA
; [nakarest] naka_widget_names_charmap+0x15c  +0x15c..+0x162 (0xead5cc, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 83 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsListBox "c^dBn".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x15C, 0x6
; [nakarest] naka_widget_names_charmap+0x162  +0x162..+0x16c (0xead5d2, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 83 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsListBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x162, 0xA
; [nakarest] naka_widget_names_charmap+0x16c  +0x16c..+0x16e (0xead5dc, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 82 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvCatchEvent "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x16C, 0x2
; [nakarest] naka_widget_names_charmap+0x16e  +0x16e..+0x17c (0xead5de, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 82 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvCatchEvent.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x16E, 0xE
; [nakarest] naka_widget_names_charmap+0x17c  +0x17c..+0x17e (0xead5ec, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 81 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcStrRadioBox "X".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x17C, 0x2
; [nakarest] naka_widget_names_charmap+0x17e  +0x17e..+0x18c (0xead5ee, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 81 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcStrRadioBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x17E, 0xE
; [nakarest] naka_widget_names_charmap+0x18c  +0x18c..+0x194 (0xead5fc, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 80 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsRadioBox "c^demA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x18C, 0x8
; [nakarest] naka_widget_names_charmap+0x194  +0x194..+0x1a0 (0xead604, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 80 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsRadioBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x194, 0xC
; [nakarest] naka_widget_names_charmap+0x1a0  +0x1a0..+0x1a4 (0xead610, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 79 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRamBox "jr".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1A0, 0x4
; [nakarest] naka_widget_names_charmap+0x1a4  +0x1a4..+0x1ae (0xead614, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 79 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRamBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1A4, 0xA
; [nakarest] naka_widget_names_charmap+0x1ae  +0x1ae..+0x1b2 (0xead61e, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 78 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexToggle "AA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1AE, 0x4
; [nakarest] naka_widget_names_charmap+0x1b2  +0x1b2..+0x1c0 (0xead622, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 78 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexToggle.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1B2, 0xE
; [nakarest] naka_widget_names_charmap+0x1c0  +0x1c0..+0x1c2 (0xead630, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 77 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvNaming "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1C0, 0x2
; [nakarest] naka_widget_names_charmap+0x1c2  +0x1c2..+0x1cc (0xead632, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 77 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvNaming.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1C2, 0xA
; [nakarest] naka_widget_names_charmap+0x1cc  +0x1cc..+0x1ce (0xead63c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 76 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsCursorBox "n".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1CC, 0x2
; [nakarest] naka_widget_names_charmap+0x1ce  +0x1ce..+0x1da (0xead63e, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 76 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsCursorBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1CE, 0xC
; [nakarest] naka_widget_names_charmap+0x1da  +0x1da..+0x1dc (0xead64a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 75 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcNamingWindow "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1DA, 0x2
; [nakarest] naka_widget_names_charmap+0x1dc  +0x1dc..+0x1ec (0xead64c, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 75 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcNamingWindow.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1DC, 0x10
; [nakarest] naka_widget_names_charmap+0x1ec  +0x1ec..+0x1ee (0xead65c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 74 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvFixWin "t".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1EC, 0x2
; [nakarest] naka_widget_names_charmap+0x1ee  +0x1ee..+0x1f8 (0xead65e, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 74 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvFixWin.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1EE, 0xA
; [nakarest] naka_widget_names_charmap+0x1f8  +0x1f8..+0x1fa (0xead668, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 73 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitScreen "N".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1F8, 0x2
; [nakarest] naka_widget_names_charmap+0x1fa  +0x1fa..+0x208 (0xead66a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 73 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitScreen.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1FA, 0xE
; [nakarest] naka_widget_names_charmap+0x208  +0x208..+0x20a (0xead678, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 72 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitMode "`".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x208, 0x2
; [nakarest] naka_widget_names_charmap+0x20a  +0x20a..+0x216 (0xead67a, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 72 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExitMode.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x20A, 0xC
; [nakarest] naka_widget_names_charmap+0x216  +0x216..+0x218 (0xead686, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 71 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExit "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x216, 0x2
; [nakarest] naka_widget_names_charmap+0x218  +0x218..+0x220 (0xead688, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 71 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvExit.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x218, 0x8
; [nakarest] naka_widget_names_charmap+0x220  +0x220..+0x222 (0xead690, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 70 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbMemo "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x220, 0x2
; [nakarest] naka_widget_names_charmap+0x222  +0x222..+0x22a (0xead692, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 70 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): DbMemo.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x222, 0x8
; [nakarest] naka_widget_names_charmap+0x22a  +0x22a..+0x22c (0xead69a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 69 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsWideToggle "e".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x22A, 0x2
; [nakarest] naka_widget_names_charmap+0x22c  +0x22c..+0x23a (0xead69c, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 69 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsWideToggle.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x22C, 0xE
; [nakarest] naka_widget_names_charmap+0x23a  +0x23a..+0x23c (0xead6aa, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 68 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncToggle "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x23A, 0x2
; [nakarest] naka_widget_names_charmap+0x23c  +0x23c..+0x24a (0xead6ac, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 68 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncToggle.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x23C, 0xE
; [nakarest] naka_widget_names_charmap+0x24a  +0x24a..+0x24e (0xead6ba, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 67 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcBitEditBox "jm".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x24A, 0x4
; [nakarest] naka_widget_names_charmap+0x24e  +0x24e..+0x25c (0xead6be, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 67 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcBitEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x24E, 0xE
; [nakarest] naka_widget_names_charmap+0x25c  +0x25c..+0x260 (0xead6cc, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 66 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcWindowMenu "Xtb".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x25C, 0x4
; [nakarest] naka_widget_names_charmap+0x260  +0x260..+0x26e (0xead6d0, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 66 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcWindowMenu.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x260, 0xE
; [nakarest] naka_widget_names_charmap+0x26e  +0x26e..+0x272 (0xead6de, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 65 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcScreenMenu "XNb".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x26E, 0x4
; [nakarest] naka_widget_names_charmap+0x272  +0x272..+0x280 (0xead6e2, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 65 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcScreenMenu.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x272, 0xE
; [nakarest] naka_widget_names_charmap+0x280  +0x280..+0x284 (0xead6f0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 64 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcModeMenu "X`b".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x280, 0x4
; [nakarest] naka_widget_names_charmap+0x284  +0x284..+0x290 (0xead6f4, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 64 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcModeMenu.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x284, 0xC
; [nakarest] naka_widget_names_charmap+0x290  +0x290..+0x294 (0xead700, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 63 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwWideESBox "fX".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x290, 0x4
; [nakarest] naka_widget_names_charmap+0x294  +0x294..+0x2a0 (0xead704, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 63 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwWideESBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x294, 0xC
; [nakarest] naka_widget_names_charmap+0x2a0  +0x2a0..+0x2a4 (0xead710, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 62 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwEditSwBox "fX".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2A0, 0x4
; [nakarest] naka_widget_names_charmap+0x2a4  +0x2a4..+0x2b0 (0xead714, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 62 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwEditSwBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2A4, 0xC
; [nakarest] naka_widget_names_charmap+0x2b0  +0x2b0..+0x2b4 (0xead720, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 61 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwMenuBox "Xb".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B0, 0x4
; [nakarest] naka_widget_names_charmap+0x2b4  +0x2b4..+0x2be (0xead724, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 61 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwMenuBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B4, 0xA
; [nakarest] naka_widget_names_charmap+0x2be  +0x2be..+0x2c2 (0xead72e, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 60 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcMixerVol "ue".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BE, 0x4
; [nakarest] naka_widget_names_charmap+0x2c2  +0x2c2..+0x2ce (0xead732, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 60 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcMixerVol.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C2, 0xC
; [nakarest] naka_widget_names_charmap+0x2ce  +0x2ce..+0x2d0 (0xead73e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 59 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcPmemName "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2CE, 0x2
; [nakarest] naka_widget_names_charmap+0x2d0  +0x2d0..+0x2dc (0xead740, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 59 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcPmemName.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2D0, 0xC
; [nakarest] naka_widget_names_charmap+0x2dc  +0x2dc..+0x2de (0xead74c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 58 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRhythmName "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2DC, 0x2
; [nakarest] naka_widget_names_charmap+0x2de  +0x2de..+0x2ec (0xead74e, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 58 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRhythmName.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2DE, 0xE
; [nakarest] naka_widget_names_charmap+0x2ec  +0x2ec..+0x2f2 (0xead75c, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 57 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TitleEdit "akNlX".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2EC, 0x6
; [nakarest] naka_widget_names_charmap+0x2f2  +0x2f2..+0x2fc (0xead762, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 57 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TitleEdit.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2F2, 0xA
; [nakarest] naka_widget_names_charmap+0x2fc  +0x2fc..+0x302 (0xead76c, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 56 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ModeEdit "`kalX".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2FC, 0x6
; [nakarest] naka_widget_names_charmap+0x302  +0x302..+0x30c (0xead772, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 56 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ModeEdit.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x302, 0xA
; [nakarest] naka_widget_names_charmap+0x30c  +0x30c..+0x312 (0xead77c, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 55 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): StringBox "Xc^d".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x30C, 0x6
; [nakarest] naka_widget_names_charmap+0x312  +0x312..+0x31c (0xead782, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 55 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): StringBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x312, 0xA
; [nakarest] naka_widget_names_charmap+0x31c  +0x31c..+0x322 (0xead78c, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 54 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TextBox "Xc^dB".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31C, 0x6
; [nakarest] naka_widget_names_charmap+0x322  +0x322..+0x32a (0xead792, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 54 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TextBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x322, 0x8
; [nakarest] naka_widget_names_charmap+0x32a  +0x32a..+0x32e (0xead79a, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 53 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Window "Grr".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32A, 0x4
; [nakarest] naka_widget_names_charmap+0x32e  +0x32e..+0x336 (0xead79e, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 53 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Window.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32E, 0x8
; [nakarest] naka_widget_names_charmap+0x336  +0x336..+0x33a (0xead7a6, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 52 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TtlScreen "Xb".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x336, 0x4
; [nakarest] naka_widget_names_charmap+0x33a  +0x33a..+0x344 (0xead7aa, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 52 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): TtlScreen.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33A, 0xA
; [nakarest] naka_widget_names_charmap+0x344  +0x344..+0x348 (0xead7b4, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 51 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Screen "ar".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x344, 0x4
; [nakarest] naka_widget_names_charmap+0x348  +0x348..+0x350 (0xead7b8, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 51 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Screen.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x348, 0x8
; [nakarest] naka_widget_names_charmap+0x350  +0x350..+0x352 (0xead7c0, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 50 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): GroupBox "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x350, 0x2
; [nakarest] naka_widget_names_charmap+0x352  +0x352..+0x35c (0xead7c2, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 50 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): GroupBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x352, 0xA
; [nakarest] naka_widget_names_charmap+0x35c  +0x35c..+0x360 (0xead7cc, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 49 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Box "^_".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35C, 0x4
; [nakarest] naka_widget_names_charmap+0x360  +0x360..+0x364 (0xead7d0, 4 B)
; [nakarest] class-name strings (the +12 name) of classes 49 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Box.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x360, 0x4
; [nakarest] naka_widget_names_charmap+0x364  +0x364..+0x368 (0xead7d4, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 48 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): EditSw "ejA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x364, 0x4
; [nakarest] naka_widget_names_charmap+0x368  +0x368..+0x370 (0xead7d8, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 48 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): EditSw.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x368, 0x8
; [nakarest] naka_widget_names_charmap+0x370  +0x370..+0x374 (0xead7e0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 47 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Frame "hA^".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x370, 0x4
; [nakarest] naka_widget_names_charmap+0x374  +0x374..+0x37a (0xead7e4, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 47 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Frame.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x374, 0x6
; [nakarest] naka_widget_names_charmap+0x37a  +0x37a..+0x37e (0xead7ea, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 46 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Line "^g".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37A, 0x4
; [nakarest] naka_widget_names_charmap+0x37e  +0x37e..+0x384 (0xead7ee, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 46 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Line.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37E, 0x6
; [nakarest] naka_widget_names_charmap+0x384  +0x384..+0x386 (0xead7f4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 45 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Icon "b".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x384, 0x2
; [nakarest] naka_widget_names_charmap+0x386  +0x386..+0x38c (0xead7f6, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 45 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Icon.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x386, 0x6
; [nakarest] naka_widget_names_charmap+0x38c  +0x38c..+0x38e (0xead7fc, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 44 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Bitmap "i".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38C, 0x2
; [nakarest] naka_widget_names_charmap+0x38e  +0x38e..+0x396 (0xead7fe, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 44 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Bitmap.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38E, 0x8
; [nakarest] naka_widget_names_charmap+0x396  +0x396..+0x39a (0xead806, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 43 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Label "Xc^".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x396, 0x4
; [nakarest] naka_widget_names_charmap+0x39a  +0x39a..+0x3a0 (0xead80a, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 43 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Label.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39A, 0x6
; [nakarest] naka_widget_names_charmap+0x3a0  +0x3a0..+0x3a2 (0xead810, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 42 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcSoundName "u".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A0, 0x2
; [nakarest] naka_widget_names_charmap+0x3a2  +0x3a2..+0x3ae (0xead812, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 42 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcSoundName.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A2, 0xC
; [nakarest] naka_widget_names_charmap+0x3ae  +0x3ae..+0x3b0 (0xead81e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 41 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvMainEditSw "k".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AE, 0x2
; [nakarest] naka_widget_names_charmap+0x3b0  +0x3b0..+0x3be (0xead820, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 41 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvMainEditSw.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B0, 0xE
; [nakarest] naka_widget_names_charmap+0x3be  +0x3be..+0x3c2 (0xead82e, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 40 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvPageControl "At".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BE, 0x4
; [nakarest] naka_widget_names_charmap+0x3c2  +0x3c2..+0x3d0 (0xead832, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 40 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvPageControl.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C2, 0xE
; [nakarest] naka_widget_names_charmap+0x3d0  +0x3d0..+0x3d2 (0xead840, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 39 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsInvisibleBox "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D0, 0x2
; [nakarest] naka_widget_names_charmap+0x3d2  +0x3d2..+0x3e2 (0xead842, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 39 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsInvisibleBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D2, 0x10
; [nakarest] naka_widget_names_charmap+0x3e2  +0x3e2..+0x3e8 (0xead852, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 38 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsToggleBox "cXXme".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E2, 0x6
; [nakarest] naka_widget_names_charmap+0x3e8  +0x3e8..+0x3f4 (0xead858, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 38 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsToggleBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E8, 0xC
; [nakarest] naka_widget_names_charmap+0x3f4  +0x3f4..+0x3f8 (0xead864, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 37 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcWindowPage "AA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F4, 0x4
; [nakarest] naka_widget_names_charmap+0x3f8  +0x3f8..+0x406 (0xead868, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 37 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcWindowPage.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F8, 0xE
; [nakarest] naka_widget_names_charmap+0x406  +0x406..+0x408 (0xead876, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 36 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsPageBox "n".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x406, 0x2
; [nakarest] naka_widget_names_charmap+0x408  +0x408..+0x412 (0xead878, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 36 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsPageBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x408, 0xA
; [nakarest] naka_widget_names_charmap+0x412  +0x412..+0x416 (0xead882, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 35 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncWideES "fj".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x412, 0x4
; [nakarest] naka_widget_names_charmap+0x416  +0x416..+0x424 (0xead886, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 35 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncWideES.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x416, 0xE
; [nakarest] naka_widget_names_charmap+0x424  +0x424..+0x426 (0xead894, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 34 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexWideES "f".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x424, 0x2
; [nakarest] naka_widget_names_charmap+0x426  +0x426..+0x434 (0xead896, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 34 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexWideES.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x426, 0xE
; [nakarest] naka_widget_names_charmap+0x434  +0x434..+0x436 (0xead8a4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 33 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsWideESBox "e".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x434, 0x2
; [nakarest] naka_widget_names_charmap+0x436  +0x436..+0x442 (0xead8a6, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 33 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsWideESBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x436, 0xC
; [nakarest] naka_widget_names_charmap+0x442  +0x442..+0x446 (0xead8b2, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 32 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncEditSw "fj".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x442, 0x4
; [nakarest] naka_widget_names_charmap+0x446  +0x446..+0x454 (0xead8b6, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 32 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcFuncEditSw.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x446, 0xE
; [nakarest] naka_widget_names_charmap+0x454  +0x454..+0x456 (0xead8c4, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 31 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexEditSw "f".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x454, 0x2
; [nakarest] naka_widget_names_charmap+0x456  +0x456..+0x464 (0xead8c6, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 31 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcIndexEditSw.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x456, 0xE
; [nakarest] naka_widget_names_charmap+0x464  +0x464..+0x46a (0xead8d4, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 30 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsEditSwBox "c^de".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x464, 0x6
; [nakarest] naka_widget_names_charmap+0x46a  +0x46a..+0x476 (0xead8da, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 30 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsEditSwBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x46A, 0xC
; [nakarest] naka_widget_names_charmap+0x476  +0x476..+0x47a (0xead8e6, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 29 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTitleMenu "Xab".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x476, 0x4
; [nakarest] naka_widget_names_charmap+0x47a  +0x47a..+0x486 (0xead8ea, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 29 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTitleMenu.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x47A, 0xC
; [nakarest] naka_widget_names_charmap+0x486  +0x486..+0x48c (0xead8f6, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 28 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsMenuBox "c^dem".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x486, 0x6
; [nakarest] naka_widget_names_charmap+0x48c  +0x48c..+0x496 (0xead8fc, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 28 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsMenuBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48C, 0xA
; [nakarest] naka_widget_names_charmap+0x496  +0x496..+0x49a (0xead906, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 27 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRamEditBox "jr".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x496, 0x4
; [nakarest] naka_widget_names_charmap+0x49a  +0x49a..+0x4a8 (0xead90a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 27 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcRamEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49A, 0xE
; [nakarest] naka_widget_names_charmap+0x4a8  +0x4a8..+0x4ac (0xead918, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 26 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLswEditBox "jn".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A8, 0x4
; [nakarest] naka_widget_names_charmap+0x4ac  +0x4ac..+0x4ba (0xead91c, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 26 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLswEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AC, 0xE
; [nakarest] naka_widget_names_charmap+0x4ba  +0x4ba..+0x4c2 (0xead92a, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 25 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcNumEditBox "nAAAAA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BA, 0x8
; [nakarest] naka_widget_names_charmap+0x4c2  +0x4c2..+0x4d0 (0xead932, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 25 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcNumEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C2, 0xE
; [nakarest] naka_widget_names_charmap+0x4d0  +0x4d0..+0x4d2 (0xead940, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 24 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcOnOffBox "m".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4D0, 0x2
; [nakarest] naka_widget_names_charmap+0x4d2  +0x4d2..+0x4de (0xead942, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 24 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcOnOffBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4D2, 0xC
; [nakarest] naka_widget_names_charmap+0x4de  +0x4de..+0x4e0 (0xead94e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 23 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTblEditBox "j".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4DE, 0x2
; [nakarest] naka_widget_names_charmap+0x4e0  +0x4e0..+0x4ee (0xead950, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 23 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsTblEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4E0, 0xE
; [nakarest] naka_widget_names_charmap+0x4ee  +0x4ee..+0x4f0 (0xead95e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 22 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsNumEditBox "A".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4EE, 0x2
; [nakarest] naka_widget_names_charmap+0x4f0  +0x4f0..+0x4fe (0xead960, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 22 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsNumEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4F0, 0xE
; [nakarest] naka_widget_names_charmap+0x4fe  +0x4fe..+0x508 (0xead96e, 10 B)
; [nakarest] propdata strings (the +16 field signature) of class 21 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsEditBox "Xc^dBeGm".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4FE, 0xA
; [nakarest] naka_widget_names_charmap+0x508  +0x508..+0x512 (0xead978, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 21 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsEditBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x508, 0xA
; [nakarest] naka_widget_names_charmap+0x512  +0x512..+0x514 (0xead982, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 20 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTempoBox "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x512, 0x2
; [nakarest] naka_widget_names_charmap+0x514  +0x514..+0x520 (0xead984, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 20 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcTempoBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x514, 0xC
; [nakarest] naka_widget_names_charmap+0x520  +0x520..+0x524 (0xead990, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 19 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLswBox "jn".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x520, 0x4
; [nakarest] naka_widget_names_charmap+0x524  +0x524..+0x52e (0xead994, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 19 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): AcLswBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x524, 0xA
; [nakarest] naka_widget_names_charmap+0x52e  +0x52e..+0x532 (0xead99e, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 18 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsParaBox "c^d".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52E, 0x4
; [nakarest] naka_widget_names_charmap+0x532  +0x532..+0x53c (0xead9a2, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 18 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): PsParaBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x532, 0xA
; [nakarest] naka_widget_names_charmap+0x53c  +0x53c..+0x540 (0xead9ac, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 17 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwBox "^_A".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53C, 0x4
; [nakarest] naka_widget_names_charmap+0x540  +0x540..+0x546 (0xead9b0, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 17 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwBox.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x540, 0x6
; [nakarest] naka_widget_names_charmap+0x546  +0x546..+0x54e (0xead9b6, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 16 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Viewable "M[[[[]P".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x546, 0x8
; [nakarest] naka_widget_names_charmap+0x54e  +0x54e..+0x558 (0xead9be, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 16 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Viewable.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54E, 0xA
; [nakarest] naka_widget_names_charmap+0x558  +0x558..+0x55a (0xead9c8, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 15 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResName "X".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x558, 0x2
; [nakarest] naka_widget_names_charmap+0x55a  +0x55a..+0x562 (0xead9ca, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 15 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResName.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55A, 0x8
; [nakarest] naka_widget_names_charmap+0x562  +0x562..+0x564 (0xead9d2, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 14 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResString "B".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x562, 0x2
; [nakarest] naka_widget_names_charmap+0x564  +0x564..+0x56e (0xead9d4, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 14 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResString.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x564, 0xA
; [nakarest] naka_widget_names_charmap+0x56e  +0x56e..+0x570 (0xead9de, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 13 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResMethod "X".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x56E, 0x2
; [nakarest] naka_widget_names_charmap+0x570  +0x570..+0x57a (0xead9e0, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 13 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResMethod.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x570, 0xA
; [nakarest] naka_widget_names_charmap+0x57a  +0x57a..+0x57c (0xead9ea, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 12 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResEvent "X".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x57A, 0x2
; [nakarest] naka_widget_names_charmap+0x57c  +0x57c..+0x586 (0xead9ec, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 12 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResEvent.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x57C, 0xA
; [nakarest] naka_widget_names_charmap+0x586  +0x586..+0x588 (0xead9f6, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 11 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResFont "B".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x586, 0x2
; [nakarest] naka_widget_names_charmap+0x588  +0x588..+0x590 (0xead9f8, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 11 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResFont.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x588, 0x8
; [nakarest] naka_widget_names_charmap+0x590  +0x590..+0x592 (0xeada00, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 10 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResIcon "B".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x590, 0x2
; [nakarest] naka_widget_names_charmap+0x592  +0x592..+0x59a (0xeada02, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 10 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResIcon.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x592, 0x8
; [nakarest] naka_widget_names_charmap+0x59a  +0x59a..+0x59c (0xeada0a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 9 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResFrame "B".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x59A, 0x2
; [nakarest] naka_widget_names_charmap+0x59c  +0x59c..+0x5a6 (0xeada0c, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 9 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): ResFrame.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x59C, 0xA
; [nakarest] naka_widget_names_charmap+0x5a6  +0x5a6..+0x5a8 (0xeada16, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 8 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ResBitmap "B".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5A6, 0x2
; [nakarest] naka_widget_names_charmap+0x5a8  +0x5a8..+0x5b2 (0xeada18, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 8 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): ResBitmap.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5A8, 0xA
; [nakarest] naka_widget_names_charmap+0x5b2  +0x5b2..+0x5ba (0xeada22, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 7 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Title "kNlXNAA".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5B2, 0x8
; [nakarest] naka_widget_names_charmap+0x5ba  +0x5ba..+0x5c0 (0xeada2a, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 7 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): Title.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5BA, 0x6
; [nakarest] naka_widget_names_charmap+0x5c0  +0x5c0..+0x5c6 (0xeada30, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 6 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Mode "kalX".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5C0, 0x6
; [nakarest] naka_widget_names_charmap+0x5c6  +0x5c6..+0x5cc (0xeada36, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 6 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): Mode.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5C6, 0x6
; [nakarest] naka_widget_names_charmap+0x5cc  +0x5cc..+0x5d2 (0xeada3c, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 5 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): SupportClass "JBBK".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5CC, 0x6
; [nakarest] naka_widget_names_charmap+0x5d2  +0x5d2..+0x5e0 (0xeada42, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 5 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): SupportClass.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5D2, 0xE
; [nakarest] naka_widget_names_charmap+0x5e0  +0x5e0..+0x5e8 (0xeada50, 8 B)
; [nakarest] propdata strings (the +16 field signature) of class 4 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Class "JMBBXXL".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5E0, 0x8
; [nakarest] naka_widget_names_charmap+0x5e8  +0x5e8..+0x5ee (0xeada58, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 4 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): Class.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5E8, 0x6
; [nakarest] naka_widget_names_charmap+0x5ee  +0x5ee..+0x5f0 (0xeada5e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 3 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): MainFunction "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5EE, 0x2
; [nakarest] naka_widget_names_charmap+0x5f0  +0x5f0..+0x5fe (0xeada60, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 3 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): MainFunction.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5F0, 0xE
; [nakarest] naka_widget_names_charmap+0x5fe  +0x5fe..+0x600 (0xeada6e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 2 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): ApFunction "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5FE, 0x2
; [nakarest] naka_widget_names_charmap+0x600  +0x600..+0x60c (0xeada70, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 2 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): ApFunction.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x600, 0xC
; [nakarest] naka_widget_names_charmap+0x60c  +0x60c..+0x60e (0xeada7c, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 1 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Function "I".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x60C, 0x2
; [nakarest] naka_widget_names_charmap+0x60e  +0x60e..+0x618 (0xeada7e, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 1 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): Function.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x60E, 0xA
; [nakarest] naka_widget_names_charmap+0x618  +0x618..+0x61a (0xeada88, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 0 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): Object "".
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x618, 0x2
; [nakarest] naka_widget_names_charmap+0x61a  +0x61a..+0x622 (0xeada8a, 8 B)
; [nakarest] class-name strings (the +12 name) of classes 0 of Class slot 0x160 (table 0xeac9ee,
; [nakarest] 109 entries, InitializeRoot): Object.
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x61A, 0x8
; [nakarest] naka_widget_names_charmap+0x622  +0x622..+0x624 (0xeada92, 2 B)
; [nakarest] Text (2 B at 0xeada92), first string "m"; no registered NAKA table points into it;
; [nakarest] reached through source references InitializeRoot (display/graphics_text_vga.s:
; [nakarest] `RegObjTable 0x1600004, 0xfa44e2, 0xeada92, 0xeac9ee, 0x160`).
Root_ClassCount_160:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x622, 0x2
; [nakarest] naka_widget_names_charmap+0x624  +0x624..+0x628 (0xeada94, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeada94 not derived; readers below
; [nakarest] Readers: source references SliderH_Setup (ui/ui_widget_defs.s: `ld hl,
; [nakarest] (SliderH_Setup_Data:24)`); 1 data word in Naka_DrawbarDisplay_Table1 (at
; [nakarest] 0xeef378).
SliderH_Setup_Data:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x624, 0x4
; [nakarest] NakaInst_CHARA5W  +0x628..+0x630 (0xeada98, 8 B)
; [nakarest] Text (8 B at 0xeada98), first string "CHARA5W"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef374).
NakaInst_CHARA5W:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x628, 0x8
; [nakarest] NakaInst_CHARA2W  +0x630..+0x638 (0xeadaa0, 8 B)
; [nakarest] Text (8 B at 0xeadaa0), first string "CHARA2W"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef370).
NakaInst_CHARA2W:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x630, 0x8
; [nakarest] NakaInst_CHARA1W  +0x638..+0x640 (0xeadaa8, 8 B)
; [nakarest] Text (8 B at 0xeadaa8), first string "CHARA1W"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef36c).
NakaInst_CHARA1W:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x638, 0x8
; [nakarest] NakaInst_CHARA6  +0x640..+0x648 (0xeadab0, 8 B)
; [nakarest] Text (8 B at 0xeadab0), first string "CHARA6"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef368).
NakaInst_CHARA6:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x640, 0x8
; [nakarest] NakaInst_CHARA1P  +0x648..+0x650 (0xeadab8, 8 B)
; [nakarest] Text (8 B at 0xeadab8), first string "CHARA1P"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef364).
NakaInst_CHARA1P:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x648, 0x8
; [nakarest] NakaInst_CHARA5  +0x650..+0x658 (0xeadac0, 8 B)
; [nakarest] Text (8 B at 0xeadac0), first string "CHARA5"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef360).
NakaInst_CHARA5:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x650, 0x8
; [nakarest] NakaInst_CHARA4  +0x658..+0x660 (0xeadac8, 8 B)
; [nakarest] Text (8 B at 0xeadac8), first string "CHARA4"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef35c).
NakaInst_CHARA4:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x658, 0x8
; [nakarest] NakaInst_CHARA3  +0x660..+0x668 (0xeadad0, 8 B)
; [nakarest] Text (8 B at 0xeadad0), first string "CHARA3"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef358).
NakaInst_CHARA3:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x660, 0x8
; [nakarest] NakaInst_CHARA2  +0x668..+0x670 (0xeadad8, 8 B)
; [nakarest] Text (8 B at 0xeadad8), first string "CHARA2"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef354).
NakaInst_CHARA2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x668, 0x8
; [nakarest] NakaInst_CHARA1  +0x670..+0x678 (0xeadae0, 8 B)
; [nakarest] Text (8 B at 0xeadae0), first string "CHARA1"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in Naka_DrawbarDisplay_Table1 (at 0xeef350).
NakaInst_CHARA1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x670, 0x8
; [nakarest] NakaInst_CharaList_Pad  +0x678..+0x67a (0xeadae8, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeadae8 not derived; readers below
; [nakarest] Readers: 1 data word in Naka_DrawbarDisplay_Table2 (at 0xeef3f8).
NakaInst_CharaList_Pad:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x678, 0x2
; [nakarest] NakaInst_chara5w_fnt  +0x67a..+0x686 (0xeadaea, 12 B)
; [nakarest] Text (12 B at 0xeadaea), first string "chara5w.fnt"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in Naka_DrawbarDisplay_Table2 (at
; [nakarest] 0xeef3f4).
NakaInst_chara5w_fnt:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x67A, 0xC
; [nakarest] NakaInst_chara2w_fnt  +0x686..+0x692 (0xeadaf6, 12 B)
; [nakarest] Text (12 B at 0xeadaf6), first string "chara2w.fnt"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in Naka_DrawbarDisplay_Table2 (at
; [nakarest] 0xeef3f0).
NakaInst_chara2w_fnt:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x686, 0xC
; [nakarest] NakaInst_chara1w_fnt  +0x692..+0x69e (0xeadb02, 12 B)
; [nakarest] Text (12 B at 0xeadb02), first string "chara1w.fnt"; no registered NAKA table
; [nakarest] points into it; reached through 1 data word in Naka_DrawbarDisplay_Table2 (at
; [nakarest] 0xeef3ec).
NakaInst_chara1w_fnt:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x692, 0xC
; [nakarest] NakaInst_ara6_fnt  +0x69e..+0x1346 (0xeadb0e, 3240 B)
; [nakarest] purpose not established: layout of 3240 B at 0xeadb0e not derived; readers below
; [nakarest] Readers: 7 data words in Naka_DrawbarDisplay_Table2 (at 0xeef3e8, 0xeef3e4,
; [nakarest] 0xeef3e0).
NakaInst_ara6_fnt:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x69E, 0xCA8
; [nakarest] naka_widget_names_charmap+0x1346  +0x1346..+0x143a (0xeae7b6, 244 B)
; [nakarest] the table itself: ResEvent slot 0x1c0 (table 0xeae7b6, 60 entries, InitializeRoot),
; [nakarest] 60 entry pointers x 4 bytes.
Root_ResEventTable_1C0:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1346, 0xF4
; [nakarest] naka_widget_names_charmap+0x143a  +0x143a..+0x1740 (0xeae8aa, 774 B)
; [nakarest] name strings, entries 0-59 of ResEvent slot 0x1c0 (table 0xeae7b6, 60 entries,
; [nakarest] InitializeRoot): "EV_SWIN_MODE", "EV_OLD_TITLE", "EV_NEW_TITLE", "EV_ASSSWB",
; [nakarest] "EV_DELIVERYEVENT", "EV_UPDATESCREEN", ....
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x143A, 0x306
; [nakarest] naka_widget_names_charmap+0x1740  +0x1740..+0x1742 (0xeaebb0, 2 B)
; [nakarest] Text (2 B at 0xeaebb0), first string "<"; no registered NAKA table points into it;
; [nakarest] reached through source references InitializeRoot (display/graphics_text_vga.s:
; [nakarest] `RegObjTable 0x160000c, 0xfa58fb, 0xeaebb0, 0xeae7b6, 0x1c0`).
Root_ResEventCount_1C0:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1740, 0x2
; [nakarest] naka_widget_names_charmap+0x1742  +0x1742..+0x1a36 (0xeaebb2, 756 B)
; [nakarest] the table itself: ResMethod slot 0x1e0 (table 0xeaebb2, 188 entries,
; [nakarest] InitializeRoot), 188 entry pointers x 4 bytes.
Root_ResMethodTable_1E0:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1742, 0x2F4
; [nakarest] naka_widget_names_charmap+0x1a36  +0x1a36..+0x25fc (0xeaeea6, 3014 B)
; [nakarest] name strings, entries 0-187 of ResMethod slot 0x1e0 (table 0xeaebb2, 188 entries,
; [nakarest] InitializeRoot): "MT_MainLoopCount", "MT_SetTitleFlag", "MT_GetInitData",
; [nakarest] "MT_CheckInitData", "MT_EasySetGo", "MT_InterruptOff", ....
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x1A36, 0xBC6
; [nakarest] naka_widget_names_charmap+0x25fc  +0x25fc..+0x25fe (0xeafa6c, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeafa6c not derived; readers below
; [nakarest] Readers: source references InitializeRoot (display/graphics_text_vga.s:
; [nakarest] `RegObjTable 0x160000d, 0xfa5948, 0xeafa6c, 0xeaebb2, 0x1e0`).
Root_ResMethodCount_1E0:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x25FC, 0x2
; [nakarest] naka_widget_names_charmap+0x25fe  +0x25fe..+0x2b82 (0xeafa6e, 1412 B)
; [nakarest] the table itself: Function slot 0x100 (table 0xeafa6e, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes.
Root_FunctionTable_100:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x25FE, 0x584
; [nakarest] WidgetName_InitPtrTable  +0x2b82..+0x2b98 (0xeafff2, 22 B)
; [nakarest] the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes.
WidgetName_InitPtrTable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B82, 0x15
IvAccordion_ShowHide_UpdatePart_Data:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B97, 0x1
; [nakarest] WidgetName_PtrBlock_A  +0x2b98..+0x2bb0 (0xeb0008, 24 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1386 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_A:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B98, 0x1
IvAccordion_ShowHide_Data:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2B99, 0xE
IvAccordion_ShowHide_Data_2:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BA7, 0x9
; [nakarest] WidgetName_PtrBlock_B1  +0x2bb0..+0x2bb1 (0xeb0020, 1 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1362 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_B1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BB0, 0x1
; [nakarest] WidgetName_PtrBlock_B2  +0x2bb1..+0x2bba (0xeb0021, 9 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1361 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_B2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BB1, 0x9
; [nakarest] WidgetName_PtrBlock_C  +0x2bba..+0x2be1 (0xeb002a, 39 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1352 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_C:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BBA, 0x27
; [nakarest] WidgetName_PtrBlock_D  +0x2be1..+0x2c08 (0xeb0051, 39 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1313 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_D:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2BE1, 0x27
; [nakarest] WidgetName_PtrBlock_E  +0x2c08..+0x2c2c (0xeb0078, 36 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1274 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_E:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C08, 0x24
; [nakarest] WidgetName_PtrBlock_F1  +0x2c2c..+0x2c2f (0xeb009c, 3 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1238 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_F1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C2C, 0x3
; [nakarest] WidgetName_PtrBlock_F2  +0x2c2f..+0x2c34 (0xeb009f, 5 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1235 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_F2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C2F, 0x5
; [nakarest] WidgetName_PtrBlock_G  +0x2c34..+0x2c48 (0xeb00a4, 20 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1230 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_G:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C34, 0x14
; [nakarest] WidgetName_PtrBlock_H  +0x2c48..+0x2c54 (0xeb00b8, 12 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1210 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_H:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C48, 0xC
; [nakarest] WidgetName_PtrBlock_I1  +0x2c54..+0x2c56 (0xeb00c4, 2 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1198 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_I1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C54, 0x2
; [nakarest] WidgetName_PtrBlock_I2  +0x2c56..+0x2c65 (0xeb00c6, 15 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1196 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_I2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C56, 0xF
; [nakarest] Data_WidgetNamesCharMapBlock  +0x2c65..+0x2c68 (0xeb00d5, 3 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1181 of its 1408
; [nakarest] bytes are here or later).
Data_WidgetNamesCharMapBlock:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C65, 0x3
; [nakarest] WidgetCharMap_DataEntry1  +0x2c68..+0x2c6b (0xeb00d8, 3 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1178 of its 1408
; [nakarest] bytes are here or later).
WidgetCharMap_DataEntry1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C68, 0x3
; [nakarest] WidgetName_PtrBlock_K  +0x2c6b..+0x2c7d (0xeb00db, 18 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1175 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_K:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C6B, 0x12
; [nakarest] WidgetName_PtrBlock_L  +0x2c7d..+0x2c9f (0xeb00ed, 34 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1157 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_L:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C7D, 0x22
; [nakarest] WidgetName_PtrBlock_M1  +0x2c9f..+0x2ca4 (0xeb010f, 5 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1123 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_M1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2C9F, 0x5
; [nakarest] WidgetName_PtrBlock_M2  +0x2ca4..+0x2ccb (0xeb0114, 39 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1118 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_M2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2CA4, 0x27
; [nakarest] WidgetName_PtrBlock_N1  +0x2ccb..+0x2ccf (0xeb013b, 4 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1079 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_N1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2CCB, 0x4
; [nakarest] WidgetCharMap_DataEntry2  +0x2ccf..+0x2d56 (0xeb013f, 135 B)
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 1075 of its 1408
; [nakarest] bytes are here or later).
WidgetCharMap_DataEntry2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2CCF, 0x87
; [nakarest] WidgetName_PtrBlock_O  +0x2d56..+0x3106 (0xeb01c6, 944 B)
; [nakarest] purpose not established: 4 B at 0xeb0572 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
; [nakarest] Continues the table itself: Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot), 352 entry pointers x 4 bytes (starts 0xeafff2, 940 of its 1408
; [nakarest] bytes are here or later).
WidgetName_PtrBlock_O:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x2D56, 0x3B0
; [nakarest] NakaInst_FuncNames_Terminator  +0x3106..+0x3108 (0xeb0576, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb0576 not derived; readers below
; [nakarest] Readers: 1 data word in WidgetName_PtrBlock_O (at 0xeb0572), which is read by
; [nakarest] SoundEffect_Dispatch_Table (ui_widgets/widget_dispatch.s: `.long
; [nakarest] WidgetName_PtrBlock_O`).
NakaInst_FuncNames_Terminator:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3106, 0x2
; [nakarest] NakaInst_DrawBitmapSP2  +0x3108..+0x3116 (0xeb0578, 14 B)
; [nakarest] name string, entry 351 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmapSP2".
NakaInst_DrawBitmapSP2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3108, 0xE
; [nakarest] NakaInst_MainDeleteEvent  +0x3116..+0x3126 (0xeb0586, 16 B)
; [nakarest] name string, entry 350 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainDeleteEvent".
NakaInst_MainDeleteEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3116, 0x10
; [nakarest] NakaInst_MainDeleteSpecificEvent  +0x3126..+0x313e (0xeb0596, 24 B)
; [nakarest] name string, entry 349 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainDeleteSpecificEvent".
NakaInst_MainDeleteSpecificEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3126, 0x18
; [nakarest] NakaInst_DrawFunc  +0x313e..+0x3148 (0xeb05ae, 10 B)
; [nakarest] name string, entry 348 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawFunc".
NakaInst_DrawFunc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x313E, 0xA
; [nakarest] NakaInst_SetRootParam  +0x3148..+0x3156 (0xeb05b8, 14 B)
; [nakarest] name string, entry 347 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetRootParam".
NakaInst_SetRootParam:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3148, 0xE
; [nakarest] NakaInst_SetRootEvent  +0x3156..+0x3164 (0xeb05c6, 14 B)
; [nakarest] name string, entry 346 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetRootEvent".
NakaInst_SetRootEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3156, 0xE
; [nakarest] NakaInst_InitDrawTask  +0x3164..+0x3172 (0xeb05d4, 14 B)
; [nakarest] name string, entry 345 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitDrawTask".
NakaInst_InitDrawTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3164, 0xE
; [nakarest] NakaInst_RefreshSwEvent  +0x3172..+0x3182 (0xeb05e2, 16 B)
; [nakarest] name string, entry 344 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RefreshSwEvent".
NakaInst_RefreshSwEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3172, 0x10
; [nakarest] NakaInst_LcdOn  +0x3182..+0x3188 (0xeb05f2, 6 B)
; [nakarest] name string, entry 343 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "LcdOn".
NakaInst_LcdOn:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3182, 0x6
; [nakarest] NakaInst_LcdOff  +0x3188..+0x3190 (0xeb05f8, 8 B)
; [nakarest] name string, entry 342 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "LcdOff".
NakaInst_LcdOff:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3188, 0x8
; [nakarest] NakaInst_DrawBitmapFile  +0x3190..+0x31a0 (0xeb0600, 16 B)
; [nakarest] name string, entry 341 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmapFile".
NakaInst_DrawBitmapFile:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3190, 0x10
; [nakarest] NakaInst_VwUserBitmapByNameProc  +0x31a0..+0x31b8 (0xeb0610, 24 B)
; [nakarest] name string, entry 340 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "VwUserBitmapByNameProc".
NakaInst_VwUserBitmapByNameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31A0, 0x18
; [nakarest] NakaInst_ApDeliveryEvent  +0x31b8..+0x31c8 (0xeb0628, 16 B)
; [nakarest] name string, entry 339 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApDeliveryEvent".
NakaInst_ApDeliveryEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31B8, 0x10
; [nakarest] Str_RefreshApTask  +0x31c8..+0x31d6 (0xeb0638, 14 B)
; [nakarest] name string, entry 338 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RefreshApTask".
Str_RefreshApTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31C8, 0xE
; [nakarest] NakaInst_WakeUpApTask  +0x31d6..+0x31e4 (0xeb0646, 14 B)
; [nakarest] name string, entry 337 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "WakeUpApTask".
NakaInst_WakeUpApTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31D6, 0xE
; [nakarest] Str_SleepApTask  +0x31e4..+0x31f0 (0xeb0654, 12 B)
; [nakarest] name string, entry 336 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SleepApTask".
Str_SleepApTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31E4, 0xC
; [nakarest] NakaInst_WakeUpMainTask  +0x31f0..+0x3200 (0xeb0660, 16 B)
; [nakarest] name string, entry 335 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "WakeUpMainTask".
NakaInst_WakeUpMainTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x31F0, 0x10
; [nakarest] NakaInst_SleepMainTask  +0x3200..+0x320e (0xeb0670, 14 B)
; [nakarest] name string, entry 334 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SleepMainTask".
NakaInst_SleepMainTask:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3200, 0xE
; [nakarest] NakaInst_DeleteEvent  +0x320e..+0x321a (0xeb067e, 12 B)
; [nakarest] name string, entry 333 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DeleteEvent".
NakaInst_DeleteEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x320E, 0xC
; [nakarest] NakaInst_DeleteSpecificEvent  +0x321a..+0x322e (0xeb068a, 20 B)
; [nakarest] name string, entry 332 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DeleteSpecificEvent".
NakaInst_DeleteSpecificEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x321A, 0x14
; [nakarest] NakaInst_FuncCall  +0x322e..+0x3238 (0xeb069e, 10 B)
; [nakarest] name string, entry 331 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "FuncCall".
NakaInst_FuncCall:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x322E, 0xA
; [nakarest] NakaInst_IvIntWelcomeProc  +0x3238..+0x324a (0xeb06a8, 18 B)
; [nakarest] name string, entry 330 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntWelcomeProc".
NakaInst_IvIntWelcomeProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3238, 0x12
; [nakarest] NakaInst_SetWallColor  +0x324a..+0x3258 (0xeb06ba, 14 B)
; [nakarest] name string, entry 329 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetWallColor".
NakaInst_SetWallColor:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x324A, 0xE
; [nakarest] NakaInst_SetWallPaper  +0x3258..+0x3266 (0xeb06c8, 14 B)
; [nakarest] name string, entry 328 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetWallPaper".
NakaInst_SetWallPaper:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3258, 0xE
; [nakarest] NakaInst_InitPaletteRGB  +0x3266..+0x3276 (0xeb06d6, 16 B)
; [nakarest] name string, entry 327 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitPaletteRGB".
NakaInst_InitPaletteRGB:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3266, 0x10
; [nakarest] NakaInst_SetPaletteRGB  +0x3276..+0x3284 (0xeb06e6, 14 B)
; [nakarest] name string, entry 326 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetPaletteRGB".
NakaInst_SetPaletteRGB:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3276, 0xE
; [nakarest] NakaInst_DrawBitmapFast  +0x3284..+0x3294 (0xeb06f4, 16 B)
; [nakarest] name string, entry 325 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmapFast".
NakaInst_DrawBitmapFast:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3284, 0x10
; [nakarest] Str_DrawBitmapSPFast  +0x3294..+0x32a6 (0xeb0704, 18 B)
; [nakarest] name string, entry 324 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmapSPFast".
Str_DrawBitmapSPFast:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3294, 0x12
; [nakarest] Str_GetNamingWindowID  +0x32a6..+0x32b8 (0xeb0716, 18 B)
; [nakarest] name string, entry 323 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetNamingWindowID".
Str_GetNamingWindowID:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32A6, 0x12
; [nakarest] Str_IvScreenProc  +0x32b8..+0x32c6 (0xeb0728, 14 B)
; [nakarest] name string, entry 322 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvScreenProc".
Str_IvScreenProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32B8, 0xE
; [nakarest] Str_CaptureLcd  +0x32c6..+0x32d2 (0xeb0736, 12 B)
; [nakarest] name string, entry 321 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "CaptureLcd".
Str_CaptureLcd:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32C6, 0xC
; [nakarest] Str_VwUserBitmapProc  +0x32d2..+0x32e4 (0xeb0742, 18 B)
; [nakarest] name string, entry 320 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "VwUserBitmapProc".
Str_VwUserBitmapProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32D2, 0x12
; [nakarest] Str_DrawBitmapSP  +0x32e4..+0x32f2 (0xeb0754, 14 B)
; [nakarest] name string, entry 319 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmapSP".
Str_DrawBitmapSP:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32E4, 0xE
; [nakarest] Str_GetPartSelect  +0x32f2..+0x3300 (0xeb0762, 14 B)
; [nakarest] name string, entry 318 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetPartSelect".
Str_GetPartSelect:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x32F2, 0xE
; [nakarest] Str_TrChordBoxProc  +0x3300..+0x3310 (0xeb0770, 16 B)
; [nakarest] name string, entry 317 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TrChordBoxProc".
Str_TrChordBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3300, 0x10
; [nakarest] Str_TrTransposeBoxProc  +0x3310..+0x3324 (0xeb0780, 20 B)
; [nakarest] name string, entry 316 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TrTransposeBoxProc".
Str_TrTransposeBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3310, 0x14
; [nakarest] Str_AcLanguageTextProc  +0x3324..+0x3338 (0xeb0794, 20 B)
; [nakarest] name string, entry 315 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcLanguageTextProc".
Str_AcLanguageTextProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3324, 0x14
; [nakarest] Str_PsTextBoxProc  +0x3338..+0x3346 (0xeb07a8, 14 B)
; [nakarest] name string, entry 314 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsTextBoxProc".
Str_PsTextBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3338, 0xE
; [nakarest] Str_IvShowHideProc  +0x3346..+0x3356 (0xeb07b6, 16 B)
; [nakarest] name string, entry 313 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvShowHideProc".
Str_IvShowHideProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3346, 0x10
; [nakarest] Str_SetNotDrawFlag  +0x3356..+0x3366 (0xeb07c6, 16 B)
; [nakarest] name string, entry 312 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetNotDrawFlag".
Str_SetNotDrawFlag:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3356, 0x10
; [nakarest] Str_ConvertStringsEx  +0x3366..+0x3378 (0xeb07d6, 18 B)
; [nakarest] name string, entry 311 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ConvertStringsEx".
Str_ConvertStringsEx:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3366, 0x12
; [nakarest] Str_SetVariFlag  +0x3378..+0x3384 (0xeb07e8, 12 B)
; [nakarest] name string, entry 310 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetVariFlag".
Str_SetVariFlag:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3378, 0xC
; [nakarest] Str_IvIntEasySetProc  +0x3384..+0x3396 (0xeb07f4, 18 B)
; [nakarest] name string, entry 309 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntEasySetProc".
Str_IvIntEasySetProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3384, 0x12
; [nakarest] Str_IvIntVariProc  +0x3396..+0x33a4 (0xeb0806, 14 B)
; [nakarest] name string, entry 308 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntVariProc".
Str_IvIntVariProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3396, 0xE
; [nakarest] Str_IvIntCompleteProc  +0x33a4..+0x33b6 (0xeb0814, 18 B)
; [nakarest] name string, entry 307 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntCompleteProc".
Str_IvIntCompleteProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33A4, 0x12
; [nakarest] Str_IvIntErrorProc  +0x33b6..+0x33c6 (0xeb0826, 16 B)
; [nakarest] name string, entry 306 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntErrorProc".
Str_IvIntErrorProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33B6, 0x10
; [nakarest] Str_IvIntReminderProc  +0x33c6..+0x33d8 (0xeb0836, 18 B)
; [nakarest] name string, entry 305 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvIntReminderProc".
Str_IvIntReminderProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33C6, 0x12
; [nakarest] Str_CheckNotDrawFlag  +0x33d8..+0x33ea (0xeb0848, 18 B)
; [nakarest] name string, entry 304 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "CheckNotDrawFlag".
Str_CheckNotDrawFlag:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33D8, 0x12
; [nakarest] Str_SetInterruptTime  +0x33ea..+0x33fc (0xeb085a, 18 B)
; [nakarest] name string, entry 303 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetInterruptTime".
Str_SetInterruptTime:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33EA, 0x12
; [nakarest] Str_IvInterruptProc  +0x33fc..+0x340c (0xeb086c, 16 B)
; [nakarest] name string, entry 302 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvInterruptProc".
Str_IvInterruptProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x33FC, 0x10
; [nakarest] Str_IntTimeIDProc  +0x340c..+0x341a (0xeb087c, 14 B)
; [nakarest] name string, entry 301 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IntTimeIDProc".
Str_IntTimeIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x340C, 0xE
; [nakarest] Str_DbMemoryDumpProc  +0x341a..+0x342c (0xeb088a, 18 B)
; [nakarest] name string, entry 300 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DbMemoryDumpProc".
Str_DbMemoryDumpProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x341A, 0x12
; [nakarest] Str_IvExitWindowProc  +0x342c..+0x343e (0xeb089c, 18 B)
; [nakarest] name string, entry 299 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvExitWindowProc".
Str_IvExitWindowProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x342C, 0x12
; [nakarest] Str_IvTrackSwitchProc  +0x343e..+0x3450 (0xeb08ae, 18 B)
; [nakarest] name string, entry 298 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvTrackSwitchProc".
Str_IvTrackSwitchProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x343E, 0x12
; [nakarest] Str_GetDirmdFlag  +0x3450..+0x345e (0xeb08c0, 14 B)
; [nakarest] name string, entry 297 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetDirmdFlag".
Str_GetDirmdFlag:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3450, 0xE
; [nakarest] Str_DirmdEmulator  +0x345e..+0x346c (0xeb08ce, 14 B)
; [nakarest] name string, entry 296 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DirmdEmulator".
Str_DirmdEmulator:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x345E, 0xE
; [nakarest] Str_IvDirmdScreenProc  +0x346c..+0x347e (0xeb08dc, 18 B)
; [nakarest] name string, entry 295 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvDirmdScreenProc".
Str_IvDirmdScreenProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x346C, 0x12
; [nakarest] Str_AcTrackSwitchProc  +0x347e..+0x3490 (0xeb08ee, 18 B)
; [nakarest] name string, entry 294 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcTrackSwitchProc".
Str_AcTrackSwitchProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x347E, 0x12
; [nakarest] Str_PsTrackSwitchProc  +0x3490..+0x34a2 (0xeb0900, 18 B)
; [nakarest] name string, entry 293 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsTrackSwitchProc".
Str_PsTrackSwitchProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3490, 0x12
; [nakarest] Str_DbDebugMenuProc  +0x34a2..+0x34b2 (0xeb0912, 16 B)
; [nakarest] name string, entry 292 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DbDebugMenuProc".
Str_DbDebugMenuProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34A2, 0x10
; [nakarest] Str_AcGridBoxProc  +0x34b2..+0x34c0 (0xeb0922, 14 B)
; [nakarest] name string, entry 291 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcGridBoxProc".
Str_AcGridBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34B2, 0xE
; [nakarest] Str_AcListBoxProc  +0x34c0..+0x34ce (0xeb0930, 14 B)
; [nakarest] name string, entry 290 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcListBoxProc".
Str_AcListBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34C0, 0xE
; [nakarest] Str_PsGridBoxProc  +0x34ce..+0x34dc (0xeb093e, 14 B)
; [nakarest] name string, entry 289 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsGridBoxProc".
Str_PsGridBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34CE, 0xE
; [nakarest] Str_PsListBoxProc  +0x34dc..+0x34ea (0xeb094c, 14 B)
; [nakarest] name string, entry 288 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsListBoxProc".
Str_PsListBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34DC, 0xE
; [nakarest] Str_GetDialFocus  +0x34ea..+0x34f8 (0xeb095a, 14 B)
; [nakarest] name string, entry 287 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetDialFocus".
Str_GetDialFocus:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34EA, 0xE
; [nakarest] Str_SetDialFocus  +0x34f8..+0x3506 (0xeb0968, 14 B)
; [nakarest] name string, entry 286 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetDialFocus".
Str_SetDialFocus:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x34F8, 0xE
; [nakarest] Str_IvCatchEventProc  +0x3506..+0x3518 (0xeb0976, 18 B)
; [nakarest] name string, entry 285 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvCatchEventProc".
Str_IvCatchEventProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3506, 0x12
; [nakarest] Str_AcStrRadioBoxProc  +0x3518..+0x352a (0xeb0988, 18 B)
; [nakarest] name string, entry 284 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcStrRadioBoxProc".
Str_AcStrRadioBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3518, 0x12
; [nakarest] Str_PsRadioBoxProc  +0x352a..+0x353a (0xeb099a, 16 B)
; [nakarest] name string, entry 283 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsRadioBoxProc".
Str_PsRadioBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x352A, 0x10
; [nakarest] Str_AcRamBoxProc  +0x353a..+0x3548 (0xeb09aa, 14 B)
; [nakarest] name string, entry 282 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcRamBoxProc".
Str_AcRamBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x353A, 0xE
; [nakarest] Str_AcIndexToggleProc  +0x3548..+0x355a (0xeb09b8, 18 B)
; [nakarest] name string, entry 281 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcIndexToggleProc".
Str_AcIndexToggleProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3548, 0x12
; [nakarest] Str_IvNamingProc  +0x355a..+0x3568 (0xeb09ca, 14 B)
; [nakarest] name string, entry 280 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvNamingProc".
Str_IvNamingProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x355A, 0xE
; [nakarest] Str_PsCursorBoxProc  +0x3568..+0x3578 (0xeb09d8, 16 B)
; [nakarest] name string, entry 279 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsCursorBoxProc".
Str_PsCursorBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3568, 0x10
; [nakarest] Str_AcNamingWindowProc  +0x3578..+0x358c (0xeb09e8, 20 B)
; [nakarest] name string, entry 278 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcNamingWindowProc".
Str_AcNamingWindowProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3578, 0x14
; [nakarest] Str_IvFixWinProc  +0x358c..+0x359a (0xeb09fc, 14 B)
; [nakarest] name string, entry 277 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvFixWinProc".
Str_IvFixWinProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x358C, 0xE
; [nakarest] Str_GetBoxCenter  +0x359a..+0x35a8 (0xeb0a0a, 14 B)
; [nakarest] name string, entry 276 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetBoxCenter".
Str_GetBoxCenter:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x359A, 0xE
; [nakarest] Str_DrawStringReverse  +0x35a8..+0x35ba (0xeb0a18, 18 B)
; [nakarest] name string, entry 275 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawStringReverse".
Str_DrawStringReverse:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35A8, 0x12
; [nakarest] Str_IvExitScreenProc  +0x35ba..+0x35cc (0xeb0a2a, 18 B)
; [nakarest] name string, entry 274 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvExitScreenProc".
Str_IvExitScreenProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35BA, 0x12
; [nakarest] Str_IvExitModeProc  +0x35cc..+0x35dc (0xeb0a3c, 16 B)
; [nakarest] name string, entry 273 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvExitModeProc".
Str_IvExitModeProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35CC, 0x10
; [nakarest] Str_IvExitProc  +0x35dc..+0x35e8 (0xeb0a4c, 12 B)
; [nakarest] name string, entry 272 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvExitProc".
Str_IvExitProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35DC, 0xC
; [nakarest] Str_GetFocusParam  +0x35e8..+0x35f6 (0xeb0a58, 14 B)
; [nakarest] name string, entry 271 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetFocusParam".
Str_GetFocusParam:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35E8, 0xE
; [nakarest] Str_GetFocusEvent  +0x35f6..+0x3604 (0xeb0a66, 14 B)
; [nakarest] name string, entry 270 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetFocusEvent".
Str_GetFocusEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x35F6, 0xE
; [nakarest] Str_GetFocusObject  +0x3604..+0x3614 (0xeb0a74, 16 B)
; [nakarest] name string, entry 269 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetFocusObject".
Str_GetFocusObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3604, 0x10
; [nakarest] Str_SetRootObject  +0x3614..+0x3622 (0xeb0a84, 14 B)
; [nakarest] name string, entry 268 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetRootObject".
Str_SetRootObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3614, 0xE
; [nakarest] Str_SetAutoInc  +0x3622..+0x362e (0xeb0a92, 12 B)
; [nakarest] name string, entry 267 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetAutoInc".
Str_SetAutoInc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3622, 0xC
; [nakarest] Str_SetAutoIncDefault  +0x362e..+0x3640 (0xeb0a9e, 18 B)
; [nakarest] name string, entry 266 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetAutoIncDefault".
Str_SetAutoIncDefault:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x362E, 0x12
; [nakarest] Str_GetRootParam  +0x3640..+0x364e (0xeb0ab0, 14 B)
; [nakarest] name string, entry 265 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetRootParam".
Str_GetRootParam:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3640, 0xE
; [nakarest] Str_GetRootEvent  +0x364e..+0x365c (0xeb0abe, 14 B)
; [nakarest] name string, entry 264 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetRootEvent".
Str_GetRootEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x364E, 0xE
; [nakarest] Str_GetRootObject  +0x365c..+0x366a (0xeb0acc, 14 B)
; [nakarest] name string, entry 263 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetRootObject".
Str_GetRootObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x365C, 0xE
; [nakarest] Str_KillApTimer  +0x366a..+0x3676 (0xeb0ada, 12 B)
; [nakarest] name string, entry 262 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "KillApTimer".
Str_KillApTimer:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x366A, 0xC
; [nakarest] Str_ResetApTimer  +0x3676..+0x3684 (0xeb0ae6, 14 B)
; [nakarest] name string, entry 261 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResetApTimer".
Str_ResetApTimer:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3676, 0xE
; [nakarest] Str_SetApTimer  +0x3684..+0x3690 (0xeb0af4, 12 B)
; [nakarest] name string, entry 260 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetApTimer".
Str_SetApTimer:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3684, 0xC
; [nakarest] Str_ApTimer  +0x3690..+0x3698 (0xeb0b00, 8 B)
; [nakarest] name string, entry 259 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApTimer".
Str_ApTimer:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3690, 0x8
; [nakarest] Str_InitializeTimer  +0x3698..+0x36a8 (0xeb0b08, 16 B)
; [nakarest] name string, entry 258 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeTimer".
Str_InitializeTimer:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3698, 0x10
; [nakarest] Str_DbMemoProc  +0x36a8..+0x36b4 (0xeb0b18, 12 B)
; [nakarest] name string, entry 257 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DbMemoProc".
Str_DbMemoProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36A8, 0xC
; [nakarest] Str_PsWideToggleProc  +0x36b4..+0x36c6 (0xeb0b24, 18 B)
; [nakarest] name string, entry 256 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsWideToggleProc".
Str_PsWideToggleProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36B4, 0x12
; [nakarest] Str_AcFuncToggleProc  +0x36c6..+0x36d8 (0xeb0b36, 18 B)
; [nakarest] name string, entry 255 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcFuncToggleProc".
Str_AcFuncToggleProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36C6, 0x12
; [nakarest] Str_MainBitGet  +0x36d8..+0x36e4 (0xeb0b48, 12 B)
; [nakarest] name string, entry 254 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainBitGet".
Str_MainBitGet:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36D8, 0xC
; [nakarest] Str_MainBitPut  +0x36e4..+0x36f0 (0xeb0b54, 12 B)
; [nakarest] name string, entry 253 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainBitPut".
Str_MainBitPut:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36E4, 0xC
; [nakarest] Str_AcBitEditBoxProc  +0x36f0..+0x3702 (0xeb0b60, 18 B)
; [nakarest] name string, entry 252 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcBitEditBoxProc".
Str_AcBitEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x36F0, 0x12
; [nakarest] Str_VwEditSwBoxProc  +0x3702..+0x3712 (0xeb0b72, 16 B)
; [nakarest] name string, entry 251 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "VwEditSwBoxProc".
Str_VwEditSwBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3702, 0x10
; [nakarest] Str_VwMenuBoxProc  +0x3712..+0x3720 (0xeb0b82, 14 B)
; [nakarest] name string, entry 250 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "VwMenuBoxProc".
Str_VwMenuBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3712, 0xE
; [nakarest] Str_AcMixerVolProc  +0x3720..+0x3730 (0xeb0b90, 16 B)
; [nakarest] name string, entry 249 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcMixerVolProc".
Str_AcMixerVolProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3720, 0x10
; [nakarest] Str_AcPmemNameProc  +0x3730..+0x3740 (0xeb0ba0, 16 B)
; [nakarest] name string, entry 248 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcPmemNameProc".
Str_AcPmemNameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3730, 0x10
; [nakarest] Str_AcRhythmNameProc  +0x3740..+0x3752 (0xeb0bb0, 18 B)
; [nakarest] name string, entry 247 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcRhythmNameProc".
Str_AcRhythmNameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3740, 0x12
; [nakarest] Str_AcSoundNameProc  +0x3752..+0x3762 (0xeb0bc2, 16 B)
; [nakarest] name string, entry 246 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcSoundNameProc".
Str_AcSoundNameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3752, 0x10
; [nakarest] Str_GetWallPaletteRGB  +0x3762..+0x3774 (0xeb0bd2, 18 B)
; [nakarest] name string, entry 245 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetWallPaletteRGB".
Str_GetWallPaletteRGB:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3762, 0x12
; [nakarest] Str_ChangeWallPalette  +0x3774..+0x3786 (0xeb0be4, 18 B)
; [nakarest] name string, entry 244 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ChangeWallPalette".
Str_ChangeWallPalette:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3774, 0x12
; [nakarest] Str_SetDialDown  +0x3786..+0x3792 (0xeb0bf6, 12 B)
; [nakarest] name string, entry 243 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetDialDown".
Str_SetDialDown:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3786, 0xC
; [nakarest] Str_SetDialUp  +0x3792..+0x379c (0xeb0c02, 10 B)
; [nakarest] name string, entry 242 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetDialUp".
Str_SetDialUp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3792, 0xA
; [nakarest] Str_SetDialEnable  +0x379c..+0x37aa (0xeb0c0c, 14 B)
; [nakarest] name string, entry 241 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetDialEnable".
Str_SetDialEnable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x379C, 0xE
; [nakarest] Str_IvMainEditSwProc  +0x37aa..+0x37bc (0xeb0c1a, 18 B)
; [nakarest] name string, entry 240 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvMainEditSwProc".
Str_IvMainEditSwProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37AA, 0x12
; [nakarest] Str_IvPageControlProc  +0x37bc..+0x37ce (0xeb0c2c, 18 B)
; [nakarest] name string, entry 239 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IvPageControlProc".
Str_IvPageControlProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37BC, 0x12
; [nakarest] Str_PsInvisibleBoxProc  +0x37ce..+0x37e2 (0xeb0c3e, 20 B)
; [nakarest] name string, entry 238 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsInvisibleBoxProc".
Str_PsInvisibleBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37CE, 0x14
; [nakarest] Str_PsToggleBoxProc  +0x37e2..+0x37f2 (0xeb0c52, 16 B)
; [nakarest] name string, entry 237 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsToggleBoxProc".
Str_PsToggleBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37E2, 0x10
; [nakarest] Str_AcWindowPageProc  +0x37f2..+0x3804 (0xeb0c62, 18 B)
; [nakarest] name string, entry 236 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcWindowPageProc".
Str_AcWindowPageProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x37F2, 0x12
; [nakarest] Str_PsPageBoxProc  +0x3804..+0x3812 (0xeb0c74, 14 B)
; [nakarest] name string, entry 235 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsPageBoxProc".
Str_PsPageBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3804, 0xE
; [nakarest] Str_AcFuncEditSwProc  +0x3812..+0x3824 (0xeb0c82, 18 B)
; [nakarest] name string, entry 234 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcFuncEditSwProc".
Str_AcFuncEditSwProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3812, 0x12
; [nakarest] Str_AcIndexEditSwProc  +0x3824..+0x3836 (0xeb0c94, 18 B)
; [nakarest] name string, entry 233 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcIndexEditSwProc".
Str_AcIndexEditSwProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3824, 0x12
; [nakarest] Str_PsWideESBoxProc  +0x3836..+0x3846 (0xeb0ca6, 16 B)
; [nakarest] name string, entry 232 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsWideESBoxProc".
Str_PsWideESBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3836, 0x10
; [nakarest] Str_PsEditSwBoxProc  +0x3846..+0x3856 (0xeb0cb6, 16 B)
; [nakarest] name string, entry 231 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsEditSwBoxProc".
Str_PsEditSwBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3846, 0x10
; [nakarest] Str_AcTitleMenuProc  +0x3856..+0x3866 (0xeb0cc6, 16 B)
; [nakarest] name string, entry 230 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcTitleMenuProc".
Str_AcTitleMenuProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3856, 0x10
; [nakarest] Str_PsMenuBoxProc  +0x3866..+0x3874 (0xeb0cd6, 14 B)
; [nakarest] name string, entry 229 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsMenuBoxProc".
Str_PsMenuBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3866, 0xE
; [nakarest] Str_AcRamEditBoxProc  +0x3874..+0x3886 (0xeb0ce4, 18 B)
; [nakarest] name string, entry 228 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcRamEditBoxProc".
Str_AcRamEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3874, 0x12
; [nakarest] Str_AcLswEditBoxProc  +0x3886..+0x3898 (0xeb0cf6, 18 B)
; [nakarest] name string, entry 227 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcLswEditBoxProc".
Str_AcLswEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3886, 0x12
; [nakarest] Str_AcNumEditBoxProc  +0x3898..+0x38aa (0xeb0d08, 18 B)
; [nakarest] name string, entry 226 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcNumEditBoxProc".
Str_AcNumEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3898, 0x12
; [nakarest] Str_AcOnOffBoxProc  +0x38aa..+0x38ba (0xeb0d1a, 16 B)
; [nakarest] name string, entry 225 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcOnOffBoxProc".
Str_AcOnOffBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38AA, 0x10
; [nakarest] Str_PsTblEditBoxProc  +0x38ba..+0x38cc (0xeb0d2a, 18 B)
; [nakarest] name string, entry 224 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsTblEditBoxProc".
Str_PsTblEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38BA, 0x12
; [nakarest] Str_PsNumEditBoxProc  +0x38cc..+0x38de (0xeb0d3c, 18 B)
; [nakarest] name string, entry 223 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsNumEditBoxProc".
Str_PsNumEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38CC, 0x12
; [nakarest] Str_PsEditBoxProc  +0x38de..+0x38ec (0xeb0d4e, 14 B)
; [nakarest] name string, entry 222 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsEditBoxProc".
Str_PsEditBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38DE, 0xE
; [nakarest] Str_AcTempoBoxProc  +0x38ec..+0x38fc (0xeb0d5c, 16 B)
; [nakarest] name string, entry 221 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcTempoBoxProc".
Str_AcTempoBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38EC, 0x10
; [nakarest] Str_AcLswBoxProc  +0x38fc..+0x390a (0xeb0d6c, 14 B)
; [nakarest] name string, entry 220 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AcLswBoxProc".
Str_AcLswBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x38FC, 0xE
; [nakarest] Str_PsParaBoxProc  +0x390a..+0x3918 (0xeb0d7a, 14 B)
; [nakarest] name string, entry 219 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PsParaBoxProc".
Str_PsParaBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x390A, 0xE
; [nakarest] Str_VwBoxProc  +0x3918..+0x3922 (0xeb0d88, 10 B)
; [nakarest] name string, entry 218 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "VwBoxProc".
Str_VwBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3918, 0xA
; [nakarest] Str_TextBoxProc  +0x3922..+0x392e (0xeb0d92, 12 B)
; [nakarest] name string, entry 217 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TextBoxProc".
Str_TextBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3922, 0xC
; [nakarest] Str_LineProc  +0x392e..+0x3938 (0xeb0d9e, 10 B)
; [nakarest] name string, entry 216 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "LineProc".
Str_LineProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x392E, 0xA
; [nakarest] Str_IconProc  +0x3938..+0x3942 (0xeb0da8, 10 B)
; [nakarest] name string, entry 215 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IconProc".
Str_IconProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3938, 0xA
; [nakarest] Str_BitmapProc  +0x3942..+0x394e (0xeb0db2, 12 B)
; [nakarest] name string, entry 214 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BitmapProc".
Str_BitmapProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3942, 0xC
; [nakarest] Str_LabelProc  +0x394e..+0x3958 (0xeb0dbe, 10 B)
; [nakarest] name string, entry 213 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "LabelProc".
Str_LabelProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x394E, 0xA
; [nakarest] Str_StringBoxProc  +0x3958..+0x3966 (0xeb0dc8, 14 B)
; [nakarest] name string, entry 212 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "StringBoxProc".
Str_StringBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3958, 0xE
; [nakarest] Str_WindowProc  +0x3966..+0x3972 (0xeb0dd6, 12 B)
; [nakarest] name string, entry 211 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "WindowProc".
Str_WindowProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3966, 0xC
; [nakarest] Str_GroupBoxProc  +0x3972..+0x3980 (0xeb0de2, 14 B)
; [nakarest] name string, entry 210 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GroupBoxProc".
Str_GroupBoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3972, 0xE
; [nakarest] Str_TitleEditProc  +0x3980..+0x398e (0xeb0df0, 14 B)
; [nakarest] name string, entry 209 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TitleEditProc".
Str_TitleEditProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3980, 0xE
; [nakarest] Str_ModeEditProc  +0x398e..+0x399c (0xeb0dfe, 14 B)
; [nakarest] name string, entry 208 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ModeEditProc".
Str_ModeEditProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x398E, 0xE
; [nakarest] Str_MainRamGet  +0x399c..+0x39a8 (0xeb0e0c, 12 B)
; [nakarest] name string, entry 207 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainRamGet".
Str_MainRamGet:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x399C, 0xC
; [nakarest] Str_MainRamAdd  +0x39a8..+0x39b4 (0xeb0e18, 12 B)
; [nakarest] name string, entry 206 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainRamAdd".
Str_MainRamAdd:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39A8, 0xC
; [nakarest] Str_MainRamPut  +0x39b4..+0x39c0 (0xeb0e24, 12 B)
; [nakarest] name string, entry 205 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainRamPut".
Str_MainRamPut:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39B4, 0xC
; [nakarest] Str_ResetLswFilter  +0x39c0..+0x39d0 (0xeb0e30, 16 B)
; [nakarest] name string, entry 204 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResetLswFilter".
Str_ResetLswFilter:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39C0, 0x10
; [nakarest] Str_SetLswFilter  +0x39d0..+0x39de (0xeb0e40, 14 B)
; [nakarest] name string, entry 203 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetLswFilter".
Str_SetLswFilter:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39D0, 0xE
; [nakarest] Str_MainLswPartGet  +0x39de..+0x39ee (0xeb0e4e, 16 B)
; [nakarest] name string, entry 202 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswPartGet".
Str_MainLswPartGet:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39DE, 0x10
; [nakarest] Str_MainLswGet  +0x39ee..+0x39fa (0xeb0e5e, 12 B)
; [nakarest] name string, entry 201 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswGet".
Str_MainLswGet:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39EE, 0xC
; [nakarest] Str_MainLswPartAdd  +0x39fa..+0x3a0a (0xeb0e6a, 16 B)
; [nakarest] name string, entry 200 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswPartAdd".
Str_MainLswPartAdd:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x39FA, 0x10
; [nakarest] Str_MainLswAdd  +0x3a0a..+0x3a16 (0xeb0e7a, 12 B)
; [nakarest] name string, entry 199 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswAdd".
Str_MainLswAdd:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A0A, 0xC
; [nakarest] Str_MainLswPartPut  +0x3a16..+0x3a26 (0xeb0e86, 16 B)
; [nakarest] name string, entry 198 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswPartPut".
Str_MainLswPartPut:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A16, 0x10
; [nakarest] Str_MainLswPut  +0x3a26..+0x3a32 (0xeb0e96, 12 B)
; [nakarest] name string, entry 197 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainLswPut".
Str_MainLswPut:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A26, 0xC
; [nakarest] Str_DrawEditSw  +0x3a32..+0x3a3e (0xeb0ea2, 12 B)
; [nakarest] name string, entry 196 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawEditSw".
Str_DrawEditSw:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A32, 0xC
; [nakarest] Str_EditSwProc  +0x3a3e..+0x3a4a (0xeb0eae, 12 B)
; [nakarest] name string, entry 195 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "EditSwProc".
Str_EditSwProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A3E, 0xC
; [nakarest] Str_DrawTitleBar  +0x3a4a..+0x3a58 (0xeb0eba, 14 B)
; [nakarest] name string, entry 194 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawTitleBar".
Str_DrawTitleBar:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A4A, 0xE
; [nakarest] Str_TtlScreenProc  +0x3a58..+0x3a66 (0xeb0ec8, 14 B)
; [nakarest] name string, entry 193 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TtlScreenProc".
Str_TtlScreenProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A58, 0xE
; [nakarest] Str_DrawDesignFrame  +0x3a66..+0x3a76 (0xeb0ed6, 16 B)
; [nakarest] name string, entry 192 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawDesignFrame".
Str_DrawDesignFrame:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A66, 0x10
; [nakarest] Str_GetClientFrame2  +0x3a76..+0x3a86 (0xeb0ee6, 16 B)
; [nakarest] name string, entry 191 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetClientFrame2".
Str_GetClientFrame2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A76, 0x10
; [nakarest] Str_GetClientFrame  +0x3a86..+0x3a96 (0xeb0ef6, 16 B)
; [nakarest] name string, entry 190 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetClientFrame".
Str_GetClientFrame:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A86, 0x10
; [nakarest] Str_FrameProc  +0x3a96..+0x3aa0 (0xeb0f06, 10 B)
; [nakarest] name string, entry 189 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "FrameProc".
Str_FrameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3A96, 0xA
; [nakarest] Str_GetEditSwPoint  +0x3aa0..+0x3ab0 (0xeb0f10, 16 B)
; [nakarest] name string, entry 188 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetEditSwPoint".
Str_GetEditSwPoint:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AA0, 0x10
; [nakarest] Str_ScreenProc  +0x3ab0..+0x3abc (0xeb0f20, 12 B)
; [nakarest] name string, entry 187 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ScreenProc".
Str_ScreenProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AB0, 0xC
; [nakarest] Str_BoxRightCheck  +0x3abc..+0x3aca (0xeb0f2c, 14 B)
; [nakarest] name string, entry 186 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BoxRightCheck".
Str_BoxRightCheck:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3ABC, 0xE
; [nakarest] Str_BoxLeftCheck  +0x3aca..+0x3ad8 (0xeb0f3a, 14 B)
; [nakarest] name string, entry 185 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BoxLeftCheck".
Str_BoxLeftCheck:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3ACA, 0xE
; [nakarest] Str_GetFrameColor  +0x3ad8..+0x3ae6 (0xeb0f48, 14 B)
; [nakarest] name string, entry 184 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetFrameColor".
Str_GetFrameColor:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AD8, 0xE
; [nakarest] Str_DrawDesignBox  +0x3ae6..+0x3af4 (0xeb0f56, 14 B)
; [nakarest] name string, entry 183 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawDesignBox".
Str_DrawDesignBox:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AE6, 0xE
; [nakarest] Str_GetClientBox2  +0x3af4..+0x3b02 (0xeb0f64, 14 B)
; [nakarest] name string, entry 182 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetClientBox2".
Str_GetClientBox2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3AF4, 0xE
; [nakarest] Str_GetClientBox  +0x3b02..+0x3b10 (0xeb0f72, 14 B)
; [nakarest] name string, entry 181 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetClientBox".
Str_GetClientBox:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B02, 0xE
; [nakarest] Str_BoxProc  +0x3b10..+0x3b18 (0xeb0f80, 8 B)
; [nakarest] name string, entry 180 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BoxProc".
Str_BoxProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B10, 0x8
; [nakarest] Str_SetBox  +0x3b18..+0x3b20 (0xeb0f88, 8 B)
; [nakarest] name string, entry 179 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetBox".
Str_SetBox:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B18, 0x8
; [nakarest] Str_GetBox  +0x3b20..+0x3b28 (0xeb0f90, 8 B)
; [nakarest] name string, entry 178 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetBox".
Str_GetBox:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B20, 0x8
; [nakarest] Str_GetViewInstance  +0x3b28..+0x3b38 (0xeb0f98, 16 B)
; [nakarest] name string, entry 177 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetViewInstance".
Str_GetViewInstance:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B28, 0x10
; [nakarest] Str_GetLinkView  +0x3b38..+0x3b44 (0xeb0fa8, 12 B)
; [nakarest] name string, entry 176 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetLinkView".
Str_GetLinkView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B38, 0xC
; [nakarest] Str_SetSuperView  +0x3b44..+0x3b52 (0xeb0fb4, 14 B)
; [nakarest] name string, entry 175 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetSuperView".
Str_SetSuperView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B44, 0xE
; [nakarest] Str_Unlink  +0x3b52..+0x3b5a (0xeb0fc2, 8 B)
; [nakarest] name string, entry 174 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "Unlink".
Str_Unlink:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B52, 0x8
; [nakarest] Str_Link  +0x3b5a..+0x3b60 (0xeb0fca, 6 B)
; [nakarest] name string, entry 173 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "Link".
Str_Link:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B5A, 0x6
; [nakarest] Str_SubView  +0x3b60..+0x3b68 (0xeb0fd0, 8 B)
; [nakarest] name string, entry 172 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SubView".
Str_SubView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B60, 0x8
; [nakarest] Str_SuperView  +0x3b68..+0x3b72 (0xeb0fd8, 10 B)
; [nakarest] name string, entry 171 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SuperView".
Str_SuperView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B68, 0xA
; [nakarest] Str_PrevView  +0x3b72..+0x3b7c (0xeb0fe2, 10 B)
; [nakarest] name string, entry 170 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PrevView".
Str_PrevView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B72, 0xA
; [nakarest] Str_NextView  +0x3b7c..+0x3b86 (0xeb0fec, 10 B)
; [nakarest] name string, entry 169 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "NextView".
Str_NextView:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B7C, 0xA
; [nakarest] Str_GetMovable  +0x3b86..+0x3b92 (0xeb0ff6, 12 B)
; [nakarest] name string, entry 168 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetMovable".
Str_GetMovable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B86, 0xC
; [nakarest] Str_SetMovable  +0x3b92..+0x3b9e (0xeb1002, 12 B)
; [nakarest] name string, entry 167 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetMovable".
Str_SetMovable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B92, 0xC
; [nakarest] Str_GetVisible  +0x3b9e..+0x3baa (0xeb100e, 12 B)
; [nakarest] name string, entry 166 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetVisible".
Str_GetVisible:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3B9E, 0xC
; [nakarest] Str_SetVisible  +0x3baa..+0x3bb6 (0xeb101a, 12 B)
; [nakarest] name string, entry 165 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetVisible".
Str_SetVisible:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BAA, 0xC
; [nakarest] Str_GetChange  +0x3bb6..+0x3bc0 (0xeb1026, 10 B)
; [nakarest] name string, entry 164 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetChange".
Str_GetChange:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BB6, 0xA
; [nakarest] Str_SetChange  +0x3bc0..+0x3bca (0xeb1030, 10 B)
; [nakarest] name string, entry 163 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetChange".
Str_SetChange:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BC0, 0xA
; [nakarest] Str_GetConst  +0x3bca..+0x3bd4 (0xeb103a, 10 B)
; [nakarest] name string, entry 162 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetConst".
Str_GetConst:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BCA, 0xA
; [nakarest] Str_SetConst  +0x3bd4..+0x3bde (0xeb1044, 10 B)
; [nakarest] name string, entry 161 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetConst".
Str_SetConst:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BD4, 0xA
; [nakarest] Str_ViewableProc  +0x3bde..+0x3bec (0xeb104e, 14 B)
; [nakarest] name string, entry 160 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ViewableProc".
Str_ViewableProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BDE, 0xE
; [nakarest] Str_GetTitleOld  +0x3bec..+0x3bf8 (0xeb105c, 12 B)
; [nakarest] name string, entry 159 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetTitleOld".
Str_GetTitleOld:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BEC, 0xC
; [nakarest] Str_GetTitleNow  +0x3bf8..+0x3c04 (0xeb1068, 12 B)
; [nakarest] name string, entry 158 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetTitleNow".
Str_GetTitleNow:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3BF8, 0xC
; [nakarest] Str_UnregisteredTitle  +0x3c04..+0x3c16 (0xeb1074, 18 B)
; [nakarest] name string, entry 157 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "UnregisteredTitle".
Str_UnregisteredTitle:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C04, 0x12
; [nakarest] Str_RegisterTitle  +0x3c16..+0x3c24 (0xeb1086, 14 B)
; [nakarest] name string, entry 156 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RegisterTitle".
Str_RegisterTitle:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C16, 0xE
; [nakarest] Str_TitleProc  +0x3c24..+0x3c2e (0xeb1094, 10 B)
; [nakarest] name string, entry 155 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TitleProc".
Str_TitleProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C24, 0xA
; [nakarest] Str_GetModeOld  +0x3c2e..+0x3c3a (0xeb109e, 12 B)
; [nakarest] name string, entry 154 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetModeOld".
Str_GetModeOld:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C2E, 0xC
; [nakarest] Str_GetModeNow  +0x3c3a..+0x3c46 (0xeb10aa, 12 B)
; [nakarest] name string, entry 153 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetModeNow".
Str_GetModeNow:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C3A, 0xC
; [nakarest] Str_UnregisteredMode  +0x3c46..+0x3c58 (0xeb10b6, 18 B)
; [nakarest] name string, entry 152 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "UnregisteredMode".
Str_UnregisteredMode:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C46, 0x12
; [nakarest] Str_RegisterMode  +0x3c58..+0x3c66 (0xeb10c8, 14 B)
; [nakarest] name string, entry 151 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RegisterMode".
Str_RegisterMode:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C58, 0xE
; [nakarest] Str_ModeProc  +0x3c66..+0x3c70 (0xeb10d6, 10 B)
; [nakarest] name string, entry 150 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ModeProc".
Str_ModeProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C66, 0xA
; [nakarest] Str_MainFuncCall  +0x3c70..+0x3c7e (0xeb10e0, 14 B)
; [nakarest] name string, entry 149 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainFuncCall".
Str_MainFuncCall:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C70, 0xE
; [nakarest] Str_ApFuncCall  +0x3c7e..+0x3c8a (0xeb10ee, 12 B)
; [nakarest] name string, entry 148 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApFuncCall".
Str_ApFuncCall:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C7E, 0xC
; [nakarest] Str_MainFunctionProc  +0x3c8a..+0x3c9c (0xeb10fa, 18 B)
; [nakarest] name string, entry 147 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainFunctionProc".
Str_MainFunctionProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C8A, 0x12
; [nakarest] Str_ApFunctionProc  +0x3c9c..+0x3cac (0xeb110c, 16 B)
; [nakarest] name string, entry 146 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApFunctionProc".
Str_ApFunctionProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3C9C, 0x10
; [nakarest] Str_FunctionProc  +0x3cac..+0x3cba (0xeb111c, 14 B)
; [nakarest] name string, entry 145 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "FunctionProc".
Str_FunctionProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CAC, 0xE
; [nakarest] Str_TrackIDProc  +0x3cba..+0x3cc6 (0xeb112a, 12 B)
; [nakarest] name string, entry 144 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TrackIDProc".
Str_TrackIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CBA, 0xC
; [nakarest] Str_PartIDProc  +0x3cc6..+0x3cd2 (0xeb1136, 12 B)
; [nakarest] name string, entry 143 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PartIDProc".
Str_PartIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CC6, 0xC
; [nakarest] Str_UserIDProc  +0x3cd2..+0x3cde (0xeb1142, 12 B)
; [nakarest] name string, entry 142 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "UserIDProc".
Str_UserIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CD2, 0xC
; [nakarest] Str_MainFuncIDProc  +0x3cde..+0x3cee (0xeb114e, 16 B)
; [nakarest] name string, entry 141 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainFuncIDProc".
Str_MainFuncIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CDE, 0x10
; [nakarest] Str_ApFuncIDProc  +0x3cee..+0x3cfc (0xeb115e, 14 B)
; [nakarest] name string, entry 140 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApFuncIDProc".
Str_ApFuncIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CEE, 0xE
; [nakarest] Str_BitmapIDProc  +0x3cfc..+0x3d0a (0xeb116c, 14 B)
; [nakarest] name string, entry 139 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BitmapIDProc".
Str_BitmapIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3CFC, 0xE
; [nakarest] Str_FrameIDProc  +0x3d0a..+0x3d16 (0xeb117a, 12 B)
; [nakarest] name string, entry 138 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "FrameIDProc".
Str_FrameIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D0A, 0xC
; [nakarest] Str_LineModeIDProc  +0x3d16..+0x3d26 (0xeb1186, 16 B)
; [nakarest] name string, entry 137 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "LineModeIDProc".
Str_LineModeIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D16, 0x10
; [nakarest] Str_EditSwStyleIDProc  +0x3d26..+0x3d38 (0xeb1196, 18 B)
; [nakarest] name string, entry 136 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "EditSwStyleIDProc".
Str_EditSwStyleIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D26, 0x12
; [nakarest] Str_EditSwIDProc  +0x3d38..+0x3d46 (0xeb11a8, 14 B)
; [nakarest] name string, entry 135 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "EditSwIDProc".
Str_EditSwIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D38, 0xE
; [nakarest] Str_AlignmentIDProc  +0x3d46..+0x3d56 (0xeb11b6, 16 B)
; [nakarest] name string, entry 134 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "AlignmentIDProc".
Str_AlignmentIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D46, 0x10
; [nakarest] Str_FontIDProc  +0x3d56..+0x3d62 (0xeb11c6, 12 B)
; [nakarest] name string, entry 133 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "FontIDProc".
Str_FontIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D56, 0xC
; [nakarest] Str_IconIDProc  +0x3d62..+0x3d6e (0xeb11d2, 12 B)
; [nakarest] name string, entry 132 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "IconIDProc".
Str_IconIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D62, 0xC
; [nakarest] Str_TitleIDProc  +0x3d6e..+0x3d7a (0xeb11de, 12 B)
; [nakarest] name string, entry 131 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "TitleIDProc".
Str_TitleIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D6E, 0xC
; [nakarest] Str_ModeIDProc  +0x3d7a..+0x3d86 (0xeb11ea, 12 B)
; [nakarest] name string, entry 130 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ModeIDProc".
Str_ModeIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D7A, 0xC
; [nakarest] Str_BorderIDProc  +0x3d86..+0x3d94 (0xeb11f6, 14 B)
; [nakarest] name string, entry 129 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "BorderIDProc".
Str_BorderIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D86, 0xE
; [nakarest] Str_ColorIDProc  +0x3d94..+0x3da0 (0xeb1204, 12 B)
; [nakarest] name string, entry 128 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ColorIDProc".
Str_ColorIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3D94, 0xC
; [nakarest] Str_ViewFlagProc  +0x3da0..+0x3dae (0xeb1210, 14 B)
; [nakarest] name string, entry 127 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ViewFlagProc".
Str_ViewFlagProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DA0, 0xE
; [nakarest] Str_ViewIDProc  +0x3dae..+0x3dba (0xeb121e, 12 B)
; [nakarest] name string, entry 126 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ViewIDProc".
Str_ViewIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DAE, 0xC
; [nakarest] Str_ConstFlagProc  +0x3dba..+0x3dc8 (0xeb122a, 14 B)
; [nakarest] name string, entry 125 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ConstFlagProc".
Str_ConstFlagProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DBA, 0xE
; [nakarest] Str_NameProc  +0x3dc8..+0x3dd2 (0xeb1238, 10 B)
; [nakarest] name string, entry 124 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "NameProc".
Str_NameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DC8, 0xA
; [nakarest] Str_StringProc  +0x3dd2..+0x3dde (0xeb1242, 12 B)
; [nakarest] name string, entry 123 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "StringProc".
Str_StringProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DD2, 0xC
; [nakarest] Str_PointYProc  +0x3dde..+0x3dea (0xeb124e, 12 B)
; [nakarest] name string, entry 122 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PointYProc".
Str_PointYProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DDE, 0xC
; [nakarest] Str_PointXProc  +0x3dea..+0x3df6 (0xeb125a, 12 B)
; [nakarest] name string, entry 121 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PointXProc".
Str_PointXProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DEA, 0xC
; [nakarest] Str_POINTWProc  +0x3df6..+0x3e02 (0xeb1266, 12 B)
; [nakarest] name string, entry 120 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "POINTWProc".
Str_POINTWProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3DF6, 0xC
; [nakarest] Str_RectY2Proc  +0x3e02..+0x3e0e (0xeb1272, 12 B)
; [nakarest] name string, entry 119 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RectY2Proc".
Str_RectY2Proc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E02, 0xC
; [nakarest] Str_RectX2Proc  +0x3e0e..+0x3e1a (0xeb127e, 12 B)
; [nakarest] name string, entry 118 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RectX2Proc".
Str_RectX2Proc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E0E, 0xC
; [nakarest] Str_RectY1Proc  +0x3e1a..+0x3e26 (0xeb128a, 12 B)
; [nakarest] name string, entry 117 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RectY1Proc".
Str_RectY1Proc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E1A, 0xC
; [nakarest] Str_RectX1Proc  +0x3e26..+0x3e32 (0xeb1296, 12 B)
; [nakarest] name string, entry 116 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RectX1Proc".
Str_RectX1Proc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E26, 0xC
; [nakarest] Str_RECTWProc  +0x3e32..+0x3e3c (0xeb12a2, 10 B)
; [nakarest] name string, entry 115 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RECTWProc".
Str_RECTWProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E32, 0xA
; [nakarest] Str_EventIDProc  +0x3e3c..+0x3e48 (0xeb12ac, 12 B)
; [nakarest] name string, entry 114 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "EventIDProc".
Str_EventIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E3C, 0xC
; [nakarest] Str_WindowIDProc  +0x3e48..+0x3e56 (0xeb12b8, 14 B)
; [nakarest] name string, entry 113 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "WindowIDProc".
Str_WindowIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E48, 0xE
; [nakarest] Str_ScreenIDProc  +0x3e56..+0x3e64 (0xeb12c6, 14 B)
; [nakarest] name string, entry 112 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ScreenIDProc".
Str_ScreenIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E56, 0xE
; [nakarest] Str_ClassIDProc  +0x3e64..+0x3e70 (0xeb12d4, 12 B)
; [nakarest] name string, entry 111 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ClassIDProc".
Str_ClassIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E64, 0xC
; [nakarest] Str_pStringProc  +0x3e70..+0x3e7c (0xeb12e0, 12 B)
; [nakarest] name string, entry 110 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pStringProc".
Str_pStringProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E70, 0xC
; [nakarest] Str_pPropProc  +0x3e7c..+0x3e86 (0xeb12ec, 10 B)
; [nakarest] name string, entry 109 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pPropProc".
Str_pPropProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E7C, 0xA
; [nakarest] Str_pProcProc  +0x3e86..+0x3e90 (0xeb12f6, 10 B)
; [nakarest] name string, entry 108 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pProcProc".
Str_pProcProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E86, 0xA
; [nakarest] Str_pFuncProc  +0x3e90..+0x3e9a (0xeb1300, 10 B)
; [nakarest] name string, entry 107 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pFuncProc".
Str_pFuncProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E90, 0xA
; [nakarest] Str_ObjectIDProc  +0x3e9a..+0x3ea8 (0xeb130a, 14 B)
; [nakarest] name string, entry 106 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ObjectIDProc".
Str_ObjectIDProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3E9A, 0xE
; [nakarest] Str_pUlongProc  +0x3ea8..+0x3eb4 (0xeb1318, 12 B)
; [nakarest] name string, entry 105 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pUlongProc".
Str_pUlongProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EA8, 0xC
; [nakarest] Str_pSlongProc  +0x3eb4..+0x3ec0 (0xeb1324, 12 B)
; [nakarest] name string, entry 104 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pSlongProc".
Str_pSlongProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EB4, 0xC
; [nakarest] Str_pUcharProc  +0x3ec0..+0x3ecc (0xeb1330, 12 B)
; [nakarest] name string, entry 103 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pUcharProc".
Str_pUcharProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EC0, 0xC
; [nakarest] Str_pScharProc  +0x3ecc..+0x3ed8 (0xeb133c, 12 B)
; [nakarest] name string, entry 102 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pScharProc".
Str_pScharProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3ECC, 0xC
; [nakarest] Str_pUwordProc  +0x3ed8..+0x3ee4 (0xeb1348, 12 B)
; [nakarest] name string, entry 101 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pUwordProc".
Str_pUwordProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3ED8, 0xC
; [nakarest] Str_pSwordProc  +0x3ee4..+0x3ef0 (0xeb1354, 12 B)
; [nakarest] name string, entry 100 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pSwordProc".
Str_pSwordProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EE4, 0xC
; [nakarest] Str_pBoolProc  +0x3ef0..+0x3efa (0xeb1360, 10 B)
; [nakarest] name string, entry 99 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "pBoolProc".
Str_pBoolProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EF0, 0xA
; [nakarest] Str_boolProc  +0x3efa..+0x3f04 (0xeb136a, 10 B)
; [nakarest] name string, entry 98 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "boolProc".
Str_boolProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3EFA, 0xA
; [nakarest] Str_ulongProc  +0x3f04..+0x3f0e (0xeb1374, 10 B)
; [nakarest] name string, entry 97 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ulongProc".
Str_ulongProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F04, 0xA
; [nakarest] Str_slongProc  +0x3f0e..+0x3f18 (0xeb137e, 10 B)
; [nakarest] name string, entry 96 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "slongProc".
Str_slongProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F0E, 0xA
; [nakarest] Str_scharProc  +0x3f18..+0x3f22 (0xeb1388, 10 B)
; [nakarest] name string, entry 95 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "scharProc".
Str_scharProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F18, 0xA
; [nakarest] Str_ucharProc  +0x3f22..+0x3f2c (0xeb1392, 10 B)
; [nakarest] name string, entry 94 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ucharProc".
Str_ucharProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F22, 0xA
; [nakarest] Str_uwordProc  +0x3f2c..+0x3f36 (0xeb139c, 10 B)
; [nakarest] name string, entry 93 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "uwordProc".
Str_uwordProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F2C, 0xA
; [nakarest] Str_swordProc  +0x3f36..+0x3f40 (0xeb13a6, 10 B)
; [nakarest] name string, entry 92 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "swordProc".
Str_swordProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F36, 0xA
; [nakarest] Str_SupportClassProc  +0x3f40..+0x3f52 (0xeb13b0, 18 B)
; [nakarest] name string, entry 91 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SupportClassProc".
Str_SupportClassProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F40, 0x12
; [nakarest] Str_ClassProc  +0x3f52..+0x3f5c (0xeb13c2, 10 B)
; [nakarest] name string, entry 90 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ClassProc".
Str_ClassProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F52, 0xA
; [nakarest] Str_WordwrapStrings  +0x3f5c..+0x3f6c (0xeb13cc, 16 B)
; [nakarest] name string, entry 89 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "WordwrapStrings".
Str_WordwrapStrings:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F5C, 0x10
; [nakarest] Str_CalcTotalWidth  +0x3f6c..+0x3f7c (0xeb13dc, 16 B)
; [nakarest] name string, entry 88 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "CalcTotalWidth".
Str_CalcTotalWidth:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F6C, 0x10
; [nakarest] Str_ConvertStrings  +0x3f7c..+0x3f8c (0xeb13ec, 16 B)
; [nakarest] name string, entry 87 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ConvertStrings".
Str_ConvertStrings:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F7C, 0x10
; [nakarest] Str_GetCenteredDelta  +0x3f8c..+0x3f9e (0xeb13fc, 18 B)
; [nakarest] name string, entry 86 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetCenteredDelta".
Str_GetCenteredDelta:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F8C, 0x12
; [nakarest] Str_GetCharDescent  +0x3f9e..+0x3fae (0xeb140e, 16 B)
; [nakarest] name string, entry 85 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetCharDescent".
Str_GetCharDescent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3F9E, 0x10
; [nakarest] Str_GetCharHeight  +0x3fae..+0x3fbc (0xeb141e, 14 B)
; [nakarest] name string, entry 84 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetCharHeight".
Str_GetCharHeight:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FAE, 0xE
; [nakarest] Str_GetFrameSPSize  +0x3fbc..+0x3fcc (0xeb142c, 16 B)
; [nakarest] name string, entry 83 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetFrameSPSize".
Str_GetFrameSPSize:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FBC, 0x10
; [nakarest] Str_ResNameProc  +0x3fcc..+0x3fd8 (0xeb143c, 12 B)
; [nakarest] name string, entry 82 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResNameProc".
Str_ResNameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FCC, 0xC
; [nakarest] Str_ResStringProc  +0x3fd8..+0x3fe6 (0xeb1448, 14 B)
; [nakarest] name string, entry 81 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResStringProc".
Str_ResStringProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FD8, 0xE
; [nakarest] Str_ResMethodProc  +0x3fe6..+0x3ff4 (0xeb1456, 14 B)
; [nakarest] name string, entry 80 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResMethodProc".
Str_ResMethodProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FE6, 0xE
; [nakarest] Str_ResEventProc  +0x3ff4..+0x4002 (0xeb1464, 14 B)
; [nakarest] name string, entry 79 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResEventProc".
Str_ResEventProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x3FF4, 0xE
; [nakarest] Str_ResFontProc  +0x4002..+0x400e (0xeb1472, 12 B)
; [nakarest] name string, entry 78 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResFontProc".
Str_ResFontProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4002, 0xC
; [nakarest] Str_ResIconProc  +0x400e..+0x401a (0xeb147e, 12 B)
; [nakarest] name string, entry 77 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResIconProc".
Str_ResIconProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x400E, 0xC
; [nakarest] Str_ResFrameProc  +0x401a..+0x4028 (0xeb148a, 14 B)
; [nakarest] name string, entry 76 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResFrameProc".
Str_ResFrameProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x401A, 0xE
; [nakarest] Str_ResBitmapProc  +0x4028..+0x4036 (0xeb1498, 14 B)
; [nakarest] name string, entry 75 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResBitmapProc".
Str_ResBitmapProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4028, 0xE
; [nakarest] Str_ResourceProc  +0x4036..+0x4044 (0xeb14a6, 14 B)
; [nakarest] name string, entry 74 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ResourceProc".
Str_ResourceProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4036, 0xE
; [nakarest] Str_ApPostEvent  +0x4044..+0x4050 (0xeb14b4, 12 B)
; [nakarest] name string, entry 73 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ApPostEvent".
Str_ApPostEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4044, 0xC
; [nakarest] Str_MainGetEvent  +0x4050..+0x405e (0xeb14c0, 14 B)
; [nakarest] name string, entry 72 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainGetEvent".
Str_MainGetEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4050, 0xE
; [nakarest] Str_MainPostEvent  +0x405e..+0x406c (0xeb14ce, 14 B)
; [nakarest] name string, entry 71 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainPostEvent".
Str_MainPostEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x405E, 0xE
; [nakarest] Str_MainSendEvent  +0x406c..+0x407a (0xeb14dc, 14 B)
; [nakarest] name string, entry 70 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainSendEvent".
Str_MainSendEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x406C, 0xE
; [nakarest] Str_MainDispatchEvent  +0x407a..+0x408c (0xeb14ea, 18 B)
; [nakarest] name string, entry 69 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MainDispatchEvent".
Str_MainDispatchEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x407A, 0x12
; [nakarest] Str_SetCurrentTarget  +0x408c..+0x409e (0xeb14fc, 18 B)
; [nakarest] name string, entry 68 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetCurrentTarget".
Str_SetCurrentTarget:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x408C, 0x12
; [nakarest] Str_GetCurrentTarget  +0x409e..+0x40b0 (0xeb150e, 18 B)
; [nakarest] name string, entry 67 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetCurrentTarget".
Str_GetCurrentTarget:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x409E, 0x12
; [nakarest] Str_GetEvent  +0x40b0..+0x40ba (0xeb1520, 10 B)
; [nakarest] name string, entry 66 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "GetEvent".
Str_GetEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40B0, 0xA
; [nakarest] Str_PostEvent  +0x40ba..+0x40c4 (0xeb152a, 10 B)
; [nakarest] name string, entry 65 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "PostEvent".
Str_PostEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40BA, 0xA
; [nakarest] Str_SendEvent  +0x40c4..+0x40ce (0xeb1534, 10 B)
; [nakarest] name string, entry 64 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SendEvent".
Str_SendEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40C4, 0xA
; [nakarest] Str_DispatchEvent  +0x40ce..+0x40dc (0xeb153e, 14 B)
; [nakarest] name string, entry 63 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DispatchEvent".
Str_DispatchEvent:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40CE, 0xE
; [nakarest] Str_InitializeEventQueue  +0x40dc..+0x40f2 (0xeb154c, 22 B)
; [nakarest] name string, entry 62 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeEventQueue".
Str_InitializeEventQueue:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40DC, 0x16
; [nakarest] Str_CheckViewObject  +0x40f2..+0x4102 (0xeb1562, 16 B)
; [nakarest] name string, entry 61 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "CheckViewObject".
Str_CheckViewObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x40F2, 0x10
; [nakarest] Str_CountObject  +0x4102..+0x410e (0xeb1572, 12 B)
; [nakarest] name string, entry 60 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "CountObject".
Str_CountObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4102, 0xC
; [nakarest] Str_UnRegisterObject  +0x410e..+0x4120 (0xeb157e, 18 B)
; [nakarest] name string, entry 59 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "UnRegisterObject".
Str_UnRegisterObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x410E, 0x12
; [nakarest] Str_RegisterObject  +0x4120..+0x4130 (0xeb1590, 16 B)
; [nakarest] name string, entry 58 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RegisterObject".
Str_RegisterObject:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4120, 0x10
; [nakarest] Str_RegisterObjectTable  +0x4130..+0x4144 (0xeb15a0, 20 B)
; [nakarest] name string, entry 57 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "RegisterObjectTable".
Str_RegisterObjectTable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4130, 0x14
; [nakarest] Str_InitializeObjectTable  +0x4144..+0x415a (0xeb15b4, 22 B)
; [nakarest] name string, entry 56 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeObjectTable".
Str_InitializeObjectTable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4144, 0x16
; [nakarest] Str_InheritedProc  +0x415a..+0x4168 (0xeb15ca, 14 B)
; [nakarest] name string, entry 55 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InheritedProc".
Str_InheritedProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x415A, 0xE
; [nakarest] Str_ObjectProc  +0x4168..+0x4174 (0xeb15d8, 12 B)
; [nakarest] name string, entry 54 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ObjectProc".
Str_ObjectProc:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4168, 0xC
; [nakarest] Str_DrawStringAlignment  +0x4174..+0x4188 (0xeb15e4, 20 B)
; [nakarest] name string, entry 53 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawStringAlignment".
Str_DrawStringAlignment:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4174, 0x14
; [nakarest] Str_DrawStringRightJustify  +0x4188..+0x41a0 (0xeb15f8, 24 B)
; [nakarest] name string, entry 52 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawStringRightJustify".
Str_DrawStringRightJustify:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4188, 0x18
; [nakarest] Str_DrawStringLeftJustify  +0x41a0..+0x41b6 (0xeb1610, 22 B)
; [nakarest] name string, entry 51 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawStringLeftJustify".
Str_DrawStringLeftJustify:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41A0, 0x16
; [nakarest] Str_DrawStringCentered  +0x41b6..+0x41ca (0xeb1626, 20 B)
; [nakarest] name string, entry 50 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawStringCentered".
Str_DrawStringCentered:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41B6, 0x14
; [nakarest] Str_DrawString  +0x41ca..+0x41d6 (0xeb163a, 12 B)
; [nakarest] name string, entry 49 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawString".
Str_DrawString:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41CA, 0xC
; [nakarest] Str_DrawFrameSP  +0x41d6..+0x41e2 (0xeb1646, 12 B)
; [nakarest] name string, entry 48 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawFrameSP".
Str_DrawFrameSP:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41D6, 0xC
; [nakarest] Str_DrawIcons  +0x41e2..+0x41ec (0xeb1652, 10 B)
; [nakarest] name string, entry 47 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawIcons".
Str_DrawIcons:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41E2, 0xA
; [nakarest] Str_DrawBitmap  +0x41ec..+0x41f8 (0xeb165c, 12 B)
; [nakarest] name string, entry 46 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBitmap".
Str_DrawBitmap:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41EC, 0xC
; [nakarest] Str_DrawWall  +0x41f8..+0x4202 (0xeb1668, 10 B)
; [nakarest] name string, entry 45 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawWall".
Str_DrawWall:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x41F8, 0xA
; [nakarest] Str_MovePixels  +0x4202..+0x420e (0xeb1672, 12 B)
; [nakarest] name string, entry 44 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "MovePixels".
Str_MovePixels:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4202, 0xC
; [nakarest] Str_DrawFrameEx  +0x420e..+0x421a (0xeb167e, 12 B)
; [nakarest] name string, entry 43 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawFrameEx".
Str_DrawFrameEx:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x420E, 0xC
; [nakarest] Str_DrawFrame  +0x421a..+0x4224 (0xeb168a, 10 B)
; [nakarest] name string, entry 42 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawFrame".
Str_DrawFrame:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x421A, 0xA
; [nakarest] Str_DrawBox  +0x4224..+0x422c (0xeb1694, 8 B)
; [nakarest] name string, entry 41 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawBox".
Str_DrawBox:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4224, 0x8
; [nakarest] Str_DrawLineEx  +0x422c..+0x4238 (0xeb169c, 12 B)
; [nakarest] name string, entry 40 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawLineEx".
Str_DrawLineEx:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x422C, 0xC
; [nakarest] Str_DrawLine  +0x4238..+0x4242 (0xeb16a8, 10 B)
; [nakarest] name string, entry 39 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "DrawLine".
Str_DrawLine:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4238, 0xA
; [nakarest] Str_ModifyPixelEx  +0x4242..+0x4250 (0xeb16b2, 14 B)
; [nakarest] name string, entry 38 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ModifyPixelEx".
Str_ModifyPixelEx:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4242, 0xE
; [nakarest] Str_ModifyPixel  +0x4250..+0x425c (0xeb16c0, 12 B)
; [nakarest] name string, entry 37 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ModifyPixel".
Str_ModifyPixel:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4250, 0xC
; [nakarest] Str_ReadPixel  +0x425c..+0x4266 (0xeb16cc, 10 B)
; [nakarest] name string, entry 36 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "ReadPixel".
Str_ReadPixel:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x425C, 0xA
; [nakarest] Str_SetChangeRect  +0x4266..+0x4274 (0xeb16d6, 14 B)
; [nakarest] name string, entry 35 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetChangeRect".
Str_SetChangeRect:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4266, 0xE
; [nakarest] Str_SetNeedUpdate  +0x4274..+0x4282 (0xeb16e4, 14 B)
; [nakarest] name string, entry 34 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "SetNeedUpdate".
Str_SetNeedUpdate:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4274, 0xE
; [nakarest] Str_UpdateScreen  +0x4282..+0x4290 (0xeb16f2, 14 B)
; [nakarest] name string, entry 33 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "UpdateScreen".
Str_UpdateScreen:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4282, 0xE
; [nakarest] Str_InitializeGraphics  +0x4290..+0x42a4 (0xeb1700, 20 B)
; [nakarest] name string, entry 32 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeGraphics".
Str_InitializeGraphics:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4290, 0x14
; [nakarest] Str_InitializeUser31  +0x42a4..+0x42b6 (0xeb1714, 18 B)
; [nakarest] name string, entry 31 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser31".
Str_InitializeUser31:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42A4, 0x12
; [nakarest] Str_InitializeUser30  +0x42b6..+0x42c8 (0xeb1726, 18 B)
; [nakarest] name string, entry 30 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser30".
Str_InitializeUser30:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42B6, 0x12
; [nakarest] Str_InitializeUser29  +0x42c8..+0x42da (0xeb1738, 18 B)
; [nakarest] name string, entry 29 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser29".
Str_InitializeUser29:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42C8, 0x12
; [nakarest] Str_InitializeUser28  +0x42da..+0x42ec (0xeb174a, 18 B)
; [nakarest] name string, entry 28 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser28".
Str_InitializeUser28:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42DA, 0x12
; [nakarest] Str_InitializeUser27  +0x42ec..+0x42fe (0xeb175c, 18 B)
; [nakarest] name string, entry 27 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser27".
Str_InitializeUser27:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42EC, 0x12
; [nakarest] Str_InitializeUser26  +0x42fe..+0x4310 (0xeb176e, 18 B)
; [nakarest] name string, entry 26 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser26".
Str_InitializeUser26:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x42FE, 0x12
; [nakarest] Str_InitializeUser25  +0x4310..+0x4322 (0xeb1780, 18 B)
; [nakarest] name string, entry 25 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser25".
Str_InitializeUser25:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4310, 0x12
; [nakarest] Str_InitializeUser24  +0x4322..+0x4334 (0xeb1792, 18 B)
; [nakarest] name string, entry 24 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser24".
Str_InitializeUser24:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4322, 0x12
; [nakarest] Str_InitializeUser23  +0x4334..+0x4346 (0xeb17a4, 18 B)
; [nakarest] name string, entry 23 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser23".
Str_InitializeUser23:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4334, 0x12
; [nakarest] Str_InitializeUser22  +0x4346..+0x4358 (0xeb17b6, 18 B)
; [nakarest] name string, entry 22 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser22".
Str_InitializeUser22:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4346, 0x12
; [nakarest] Str_InitializeUser21  +0x4358..+0x436a (0xeb17c8, 18 B)
; [nakarest] name string, entry 21 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser21".
Str_InitializeUser21:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4358, 0x12
; [nakarest] Str_InitializeUser20  +0x436a..+0x437c (0xeb17da, 18 B)
; [nakarest] name string, entry 20 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser20".
Str_InitializeUser20:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x436A, 0x12
; [nakarest] Str_InitializeUser19  +0x437c..+0x438e (0xeb17ec, 18 B)
; [nakarest] name string, entry 19 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser19".
Str_InitializeUser19:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x437C, 0x12
; [nakarest] Str_InitializeUser18  +0x438e..+0x43a0 (0xeb17fe, 18 B)
; [nakarest] name string, entry 18 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser18".
Str_InitializeUser18:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x438E, 0x12
; [nakarest] Str_InitializeUser17  +0x43a0..+0x43b2 (0xeb1810, 18 B)
; [nakarest] name string, entry 17 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser17".
Str_InitializeUser17:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43A0, 0x12
; [nakarest] Str_InitializeUser16  +0x43b2..+0x43c4 (0xeb1822, 18 B)
; [nakarest] name string, entry 16 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser16".
Str_InitializeUser16:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43B2, 0x12
; [nakarest] Str_InitializeUser15  +0x43c4..+0x43d6 (0xeb1834, 18 B)
; [nakarest] name string, entry 15 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser15".
Str_InitializeUser15:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43C4, 0x12
; [nakarest] Str_InitializeUser14  +0x43d6..+0x43e8 (0xeb1846, 18 B)
; [nakarest] name string, entry 14 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser14".
Str_InitializeUser14:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43D6, 0x12
; [nakarest] Str_InitializeUser13  +0x43e8..+0x43fa (0xeb1858, 18 B)
; [nakarest] name string, entry 13 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser13".
Str_InitializeUser13:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43E8, 0x12
; [nakarest] Str_InitializeUser12  +0x43fa..+0x440c (0xeb186a, 18 B)
; [nakarest] name string, entry 12 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeUser12".
Str_InitializeUser12:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x43FA, 0x12
; [nakarest] Str_InitializeNaka  +0x440c..+0x441c (0xeb187c, 16 B)
; [nakarest] name string, entry 11 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeNaka".
Str_InitializeNaka:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x440C, 0x10
; [nakarest] Str_InitializeKSS  +0x441c..+0x442a (0xeb188c, 14 B)
; [nakarest] name string, entry 10 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeKSS".
Str_InitializeKSS:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x441C, 0xE
; [nakarest] Str_InitializeHama  +0x442a..+0x443a (0xeb189a, 16 B)
; [nakarest] name string, entry 9 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeHama".
Str_InitializeHama:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x442A, 0x10
; [nakarest] Str_InitializeKubo  +0x443a..+0x444a (0xeb18aa, 16 B)
; [nakarest] name string, entry 8 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeKubo".
Str_InitializeKubo:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x443A, 0x10
; [nakarest] Str_InitializeYoko  +0x444a..+0x445a (0xeb18ba, 16 B)
; [nakarest] name string, entry 7 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeYoko".
Str_InitializeYoko:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x444A, 0x10
; [nakarest] Str_InitializeScoop  +0x445a..+0x446a (0xeb18ca, 16 B)
; [nakarest] name string, entry 6 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeScoop".
Str_InitializeScoop:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x445A, 0x10
; [nakarest] Str_InitializeCheap  +0x446a..+0x447a (0xeb18da, 16 B)
; [nakarest] name string, entry 5 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeCheap".
Str_InitializeCheap:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x446A, 0x10
; [nakarest] Str_InitializeSuna  +0x447a..+0x448a (0xeb18ea, 16 B)
; [nakarest] name string, entry 4 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeSuna".
Str_InitializeSuna:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x447A, 0x10
; [nakarest] Str_InitializeEast  +0x448a..+0x449a (0xeb18fa, 16 B)
; [nakarest] name string, entry 3 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeEast".
Str_InitializeEast:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x448A, 0x10
; [nakarest] Str_InitializeToshi  +0x449a..+0x44aa (0xeb190a, 16 B)
; [nakarest] name string, entry 2 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeToshi".
Str_InitializeToshi:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x449A, 0x10
; [nakarest] Str_InitializeMurai  +0x44aa..+0x44ba (0xeb191a, 16 B)
; [nakarest] name string, entry 1 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeMurai".
Str_InitializeMurai:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x44AA, 0x10
; [nakarest] Str_InitializeRoot  +0x44ba..+0x44ca (0xeb192a, 16 B)
; [nakarest] name string, entry 0 of Function slot 0x400 (table 0xeafff2, 352 entries,
; [nakarest] InitializeRoot) (names for Function slot 0x100): "InitializeRoot".
Str_InitializeRoot:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x44BA, 0x10
; [nakarest] naka_widget_names_charmap+0x44ca  +0x44ca..+0x44cc (0xeb193a, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb193a not derived; readers below
; [nakarest] Readers: source references SliderV_Setup (ui/ui_widget_defs.s: `ld hl,
; [nakarest] (SliderV_Setup_Data:24)`).
SliderV_Setup_Data:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x44CA, 0x2
; [nakarest] naka_widget_names_charmap+0x44cc  +0x44cc..+0x44d0 (0xeb193c, 4 B)
; [nakarest] purpose not established: layout of 4 B at 0xeb193c not derived; readers below
; [nakarest] Readers: source references IconIDProc (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] IconIDProc_PtrTable`), SliderV_CalcRange (ui/ui_widget_defs.s: `ld xbc,
; [nakarest] IconIDProc_PtrTable`), SliderV_ReturnAlt (ui/ui_widget_defs.s: `ld xwa,
; [nakarest] IconIDProc_PtrTable`).
IconIDProc_PtrTable:	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x44CC, 0x4	; 177 x 32-bit pointer
; [nakarest] IconNamePtrTable  +0x44d0..+0x4500 (0xeb1940, 48 B)
; [nakarest] purpose not established: 48 B at 0xeb1940 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
IconNamePtrTable:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x44D0, 0x30
EmbeddedPtrTable_v9_naka_widget_names_charmap_004500:
	.long IconName_i11
	.long IconName_i12
	.long IconName_i13
	.long IconName_i14
	.long IconName_i15
	.long IconName_i16
	.long IconName_i17
	.long IconName_i18
	.long IconName_i19
	.long IconName_i20
	.long IconName_i21
	.long IconName_i22
	.long IconName_i23
	.long IconName_i24
	.long IconName_i25
	.long IconName_i26
	.long IconName_i27
	.long IconName_i28
	.long IconName_i29
	.long IconName_i30
	.long IconName_i31
	.long IconName_i32
	.long IconName_i33
	.long IconName_i34
	.long IconName_i35
	.long IconName_i36
	.long IconName_i37
	.long IconName_i38
	.long IconName_i39
	.long IconName_i40
	.long IconName_i41
	.long IconName_i42
	.long IconName_i43
	.long IconName_i44
	.long IconName_i45
	.long IconName_i46
	.long IconName_i47
	.long IconName_i48
	.long IconName_i49
	.long IconName_i50
	.long IconName_i51
	.long IconName_i52
	.long IconName_i53
	.long IconName_i54
	.long IconName_i55
	.long IconName_i56
	.long IconName_i57
	.long IconName_i58
	.long IconName_i59
	.long IconName_i60
	.long IconName_i61
	.long IconName_i62
	.long IconName_i63
	.long IconName_i64
	.long IconName_i65
	.long IconName_i66
	.long IconName_i67
	.long IconName_i68
	.long IconName_i69
	.long IconName_i70
	.long IconName_i71
	.long IconName_i72
	.long IconName_i73
	.long IconName_i74
	.long IconName_i75
	.long IconName_i76
	.long IconName_i77
	.long IconName_i78
	.long IconName_i79
	.long IconName_i80
	.long IconName_i81
	.long IconName_i82
	.long IconName_i83
	.long IconName_i84
	.long IconName_i85
	.long IconName_i86
	.long IconName_i87
	.long IconName_i88
	.long IconName_i89
	.long IconName_i90
	.long IconName_i91
	.long IconName_i92
	.long IconName_i93
	.long IconName_i94
	.long IconName_i95
	.long IconName_i96
	.long IconName_i97
	.long IconName_i98
	.long IconName_i99
	.long IconName_i100
	.long IconName_i101
	.long IconName_i102
	.long IconName_i103
	.long IconName_i104
	.long IconName_i105
	.long IconName_i106
	.long IconName_i107
	.long IconName_i108
	.long IconName_i109
	.long IconName_i110
	.long IconName_i111
	.long IconName_i112
	.long IconName_i113
	.long IconName_i114
	.long IconName_i115
	.long IconName_i116
	.long IconName_i117
	.long IconName_i118
	.long IconName_i119
	.long IconName_i120
	.long IconName_i121
	.long IconName_i122
	.long IconName_i123
	.long IconName_i124
	.long IconName_i125
	.long IconName_i126
	.long IconName_i127
	.long IconName_i128
	.long IconName_i129
	.long IconName_i130
	.long IconName_i131
	.long IconName_i132
	.long IconName_i133
	.long IconName_i134
	.long IconName_i135
	.long IconName_i136
	.long IconName_i137
	.long IconName_i138
; [nakarest] naka_widget_names_charmap+0x4700  +0x4700..+0x48cc (0xeb1b70, 460 B)
; [nakarest] purpose not established: 460 B at 0xeb1b70 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4700, 0x1CC
; [nakarest] IconName_Empty  +0x48cc..+0x48ce (0xeb1d3c, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb1d3c not derived; readers below
; [nakarest] Readers: 1 data word in EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at
; [nakarest] 0xeb1bfc).
IconName_Empty:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48CC, 0x2
; [nakarest] IconName_i173  +0x48ce..+0x48d4 (0xeb1d3e, 6 B)
; [nakarest] Text (6 B at 0xeb1d3e), first string "i173"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bf8).
IconName_i173:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48CE, 0x6
; [nakarest] IconName_i172  +0x48d4..+0x48da (0xeb1d44, 6 B)
; [nakarest] Text (6 B at 0xeb1d44), first string "i172"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bf4).
IconName_i172:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48D4, 0x6
; [nakarest] IconName_i171  +0x48da..+0x48e0 (0xeb1d4a, 6 B)
; [nakarest] Text (6 B at 0xeb1d4a), first string "i171"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bf0).
IconName_i171:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48DA, 0x6
; [nakarest] IconName_i170  +0x48e0..+0x48e6 (0xeb1d50, 6 B)
; [nakarest] Text (6 B at 0xeb1d50), first string "i170"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bec).
IconName_i170:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48E0, 0x6
; [nakarest] IconName_i169  +0x48e6..+0x48ec (0xeb1d56, 6 B)
; [nakarest] Text (6 B at 0xeb1d56), first string "i169"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1be8).
IconName_i169:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48E6, 0x6
; [nakarest] IconName_i168  +0x48ec..+0x48f2 (0xeb1d5c, 6 B)
; [nakarest] Text (6 B at 0xeb1d5c), first string "i168"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1be4).
IconName_i168:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48EC, 0x6
; [nakarest] IconName_i167  +0x48f2..+0x48f8 (0xeb1d62, 6 B)
; [nakarest] Text (6 B at 0xeb1d62), first string "i167"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1be0).
IconName_i167:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48F2, 0x6
; [nakarest] IconName_i166  +0x48f8..+0x48fe (0xeb1d68, 6 B)
; [nakarest] Text (6 B at 0xeb1d68), first string "i166"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bdc).
IconName_i166:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48F8, 0x6
; [nakarest] IconName_i165  +0x48fe..+0x4904 (0xeb1d6e, 6 B)
; [nakarest] Text (6 B at 0xeb1d6e), first string "i165"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bd8).
IconName_i165:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x48FE, 0x6
; [nakarest] IconName_i164  +0x4904..+0x490a (0xeb1d74, 6 B)
; [nakarest] Text (6 B at 0xeb1d74), first string "i164"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bd4).
IconName_i164:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4904, 0x6
; [nakarest] IconName_i163  +0x490a..+0x4910 (0xeb1d7a, 6 B)
; [nakarest] Text (6 B at 0xeb1d7a), first string "i163"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bd0).
IconName_i163:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x490A, 0x6
; [nakarest] IconName_i162  +0x4910..+0x4916 (0xeb1d80, 6 B)
; [nakarest] Text (6 B at 0xeb1d80), first string "i162"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bcc).
IconName_i162:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4910, 0x6
; [nakarest] IconName_i161  +0x4916..+0x491c (0xeb1d86, 6 B)
; [nakarest] Text (6 B at 0xeb1d86), first string "i161"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bc8).
IconName_i161:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4916, 0x6
; [nakarest] IconName_i160  +0x491c..+0x4922 (0xeb1d8c, 6 B)
; [nakarest] Text (6 B at 0xeb1d8c), first string "i160"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bc4).
IconName_i160:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x491C, 0x6
; [nakarest] IconName_i159  +0x4922..+0x4928 (0xeb1d92, 6 B)
; [nakarest] Text (6 B at 0xeb1d92), first string "i159"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bc0).
IconName_i159:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4922, 0x6
; [nakarest] IconName_i158  +0x4928..+0x492e (0xeb1d98, 6 B)
; [nakarest] Text (6 B at 0xeb1d98), first string "i158"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bbc).
IconName_i158:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4928, 0x6
; [nakarest] IconName_i157  +0x492e..+0x4934 (0xeb1d9e, 6 B)
; [nakarest] Text (6 B at 0xeb1d9e), first string "i157"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bb8).
IconName_i157:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x492E, 0x6
; [nakarest] IconName_i156  +0x4934..+0x493a (0xeb1da4, 6 B)
; [nakarest] Text (6 B at 0xeb1da4), first string "i156"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bb4).
IconName_i156:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4934, 0x6
; [nakarest] IconName_i155  +0x493a..+0x4940 (0xeb1daa, 6 B)
; [nakarest] Text (6 B at 0xeb1daa), first string "i155"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bb0).
IconName_i155:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x493A, 0x6
; [nakarest] IconName_i154  +0x4940..+0x4946 (0xeb1db0, 6 B)
; [nakarest] Text (6 B at 0xeb1db0), first string "i154"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1bac).
IconName_i154:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4940, 0x6
; [nakarest] IconName_i153  +0x4946..+0x494c (0xeb1db6, 6 B)
; [nakarest] Text (6 B at 0xeb1db6), first string "i153"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ba8).
IconName_i153:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4946, 0x6
; [nakarest] IconName_i152  +0x494c..+0x4952 (0xeb1dbc, 6 B)
; [nakarest] Text (6 B at 0xeb1dbc), first string "i152"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ba4).
IconName_i152:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x494C, 0x6
; [nakarest] IconName_i151  +0x4952..+0x4958 (0xeb1dc2, 6 B)
; [nakarest] Text (6 B at 0xeb1dc2), first string "i151"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ba0).
IconName_i151:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4952, 0x6
; [nakarest] IconName_i150  +0x4958..+0x495e (0xeb1dc8, 6 B)
; [nakarest] Text (6 B at 0xeb1dc8), first string "i150"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b9c).
IconName_i150:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4958, 0x6
; [nakarest] IconName_i149  +0x495e..+0x4964 (0xeb1dce, 6 B)
; [nakarest] Text (6 B at 0xeb1dce), first string "i149"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b98).
IconName_i149:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x495E, 0x6
; [nakarest] IconName_i148  +0x4964..+0x496a (0xeb1dd4, 6 B)
; [nakarest] Text (6 B at 0xeb1dd4), first string "i148"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b94).
IconName_i148:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4964, 0x6
; [nakarest] IconName_i147  +0x496a..+0x4970 (0xeb1dda, 6 B)
; [nakarest] Text (6 B at 0xeb1dda), first string "i147"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b90).
IconName_i147:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x496A, 0x6
; [nakarest] IconName_i146  +0x4970..+0x4976 (0xeb1de0, 6 B)
; [nakarest] Text (6 B at 0xeb1de0), first string "i146"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b8c).
IconName_i146:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4970, 0x6
; [nakarest] IconName_i145  +0x4976..+0x497c (0xeb1de6, 6 B)
; [nakarest] Text (6 B at 0xeb1de6), first string "i145"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b88).
IconName_i145:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4976, 0x6
; [nakarest] IconName_i144  +0x497c..+0x4982 (0xeb1dec, 6 B)
; [nakarest] Text (6 B at 0xeb1dec), first string "i144"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b84).
IconName_i144:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x497C, 0x6
; [nakarest] IconName_i143  +0x4982..+0x4988 (0xeb1df2, 6 B)
; [nakarest] Text (6 B at 0xeb1df2), first string "i143"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b80).
IconName_i143:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4982, 0x6
; [nakarest] IconName_i142  +0x4988..+0x498e (0xeb1df8, 6 B)
; [nakarest] Text (6 B at 0xeb1df8), first string "i142"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b7c).
IconName_i142:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4988, 0x6
; [nakarest] IconName_i141  +0x498e..+0x4994 (0xeb1dfe, 6 B)
; [nakarest] Text (6 B at 0xeb1dfe), first string "i141"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b78).
IconName_i141:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x498E, 0x6
; [nakarest] IconName_i140  +0x4994..+0x499a (0xeb1e04, 6 B)
; [nakarest] Text (6 B at 0xeb1e04), first string "i140"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b74).
IconName_i140:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4994, 0x6
; [nakarest] IconName_i139  +0x499a..+0x49a0 (0xeb1e0a, 6 B)
; [nakarest] Text (6 B at 0xeb1e0a), first string "i139"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b70).
IconName_i139:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x499A, 0x6
; [nakarest] IconName_i138  +0x49a0..+0x49a6 (0xeb1e10, 6 B)
; [nakarest] Text (6 B at 0xeb1e10), first string "i138"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i138`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b6c).
IconName_i138:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49A0, 0x6
; [nakarest] IconName_i137  +0x49a6..+0x49ac (0xeb1e16, 6 B)
; [nakarest] Text (6 B at 0xeb1e16), first string "i137"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i137`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b68).
IconName_i137:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49A6, 0x6
; [nakarest] IconName_i136  +0x49ac..+0x49b2 (0xeb1e1c, 6 B)
; [nakarest] Text (6 B at 0xeb1e1c), first string "i136"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i136`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b64).
IconName_i136:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49AC, 0x6
; [nakarest] IconName_i135  +0x49b2..+0x49b8 (0xeb1e22, 6 B)
; [nakarest] Text (6 B at 0xeb1e22), first string "i135"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i135`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b60).
IconName_i135:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49B2, 0x6
; [nakarest] IconName_i134  +0x49b8..+0x49be (0xeb1e28, 6 B)
; [nakarest] Text (6 B at 0xeb1e28), first string "i134"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i134`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b5c).
IconName_i134:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49B8, 0x6
; [nakarest] IconName_i133  +0x49be..+0x49c4 (0xeb1e2e, 6 B)
; [nakarest] Text (6 B at 0xeb1e2e), first string "i133"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i133`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b58).
IconName_i133:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49BE, 0x6
; [nakarest] IconName_i132  +0x49c4..+0x49ca (0xeb1e34, 6 B)
; [nakarest] Text (6 B at 0xeb1e34), first string "i132"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i132`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b54).
IconName_i132:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49C4, 0x6
; [nakarest] IconName_i131  +0x49ca..+0x49d0 (0xeb1e3a, 6 B)
; [nakarest] Text (6 B at 0xeb1e3a), first string "i131"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i131`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b50).
IconName_i131:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49CA, 0x6
; [nakarest] IconName_i130  +0x49d0..+0x49d6 (0xeb1e40, 6 B)
; [nakarest] Text (6 B at 0xeb1e40), first string "i130"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i130`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b4c).
IconName_i130:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49D0, 0x6
; [nakarest] IconName_i129  +0x49d6..+0x49dc (0xeb1e46, 6 B)
; [nakarest] Text (6 B at 0xeb1e46), first string "i129"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i129`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b48).
IconName_i129:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49D6, 0x6
; [nakarest] IconName_i128  +0x49dc..+0x49e2 (0xeb1e4c, 6 B)
; [nakarest] Text (6 B at 0xeb1e4c), first string "i128"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i128`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b44).
IconName_i128:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49DC, 0x6
; [nakarest] IconName_i127  +0x49e2..+0x49e8 (0xeb1e52, 6 B)
; [nakarest] Text (6 B at 0xeb1e52), first string "i127"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i127`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b40).
IconName_i127:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49E2, 0x6
; [nakarest] IconName_i126  +0x49e8..+0x49ee (0xeb1e58, 6 B)
; [nakarest] Text (6 B at 0xeb1e58), first string "i126"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i126`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b3c).
IconName_i126:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49E8, 0x6
; [nakarest] IconName_i125  +0x49ee..+0x49f4 (0xeb1e5e, 6 B)
; [nakarest] Text (6 B at 0xeb1e5e), first string "i125"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i125`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b38).
IconName_i125:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49EE, 0x6
; [nakarest] IconName_i124  +0x49f4..+0x49fa (0xeb1e64, 6 B)
; [nakarest] Text (6 B at 0xeb1e64), first string "i124"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i124`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b34).
IconName_i124:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49F4, 0x6
; [nakarest] IconName_i123  +0x49fa..+0x4a00 (0xeb1e6a, 6 B)
; [nakarest] Text (6 B at 0xeb1e6a), first string "i123"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i123`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b30).
IconName_i123:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x49FA, 0x6
; [nakarest] IconName_i122  +0x4a00..+0x4a06 (0xeb1e70, 6 B)
; [nakarest] Text (6 B at 0xeb1e70), first string "i122"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i122`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b2c).
IconName_i122:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A00, 0x6
; [nakarest] IconName_i121  +0x4a06..+0x4a0c (0xeb1e76, 6 B)
; [nakarest] Text (6 B at 0xeb1e76), first string "i121"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i121`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b28).
IconName_i121:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A06, 0x6
; [nakarest] IconName_i120  +0x4a0c..+0x4a12 (0xeb1e7c, 6 B)
; [nakarest] Text (6 B at 0xeb1e7c), first string "i120"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i120`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b24).
IconName_i120:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A0C, 0x6
; [nakarest] IconName_i119  +0x4a12..+0x4a18 (0xeb1e82, 6 B)
; [nakarest] Text (6 B at 0xeb1e82), first string "i119"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i119`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b20).
IconName_i119:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A12, 0x6
; [nakarest] IconName_i118  +0x4a18..+0x4a1e (0xeb1e88, 6 B)
; [nakarest] Text (6 B at 0xeb1e88), first string "i118"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i118`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b1c).
IconName_i118:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A18, 0x6
; [nakarest] IconName_i117  +0x4a1e..+0x4a24 (0xeb1e8e, 6 B)
; [nakarest] Text (6 B at 0xeb1e8e), first string "i117"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i117`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b18).
IconName_i117:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A1E, 0x6
; [nakarest] IconName_i116  +0x4a24..+0x4a2a (0xeb1e94, 6 B)
; [nakarest] Text (6 B at 0xeb1e94), first string "i116"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i116`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b14).
IconName_i116:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A24, 0x6
; [nakarest] IconName_i115  +0x4a2a..+0x4a30 (0xeb1e9a, 6 B)
; [nakarest] Text (6 B at 0xeb1e9a), first string "i115"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i115`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b10).
IconName_i115:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A2A, 0x6
; [nakarest] IconName_i114  +0x4a30..+0x4a36 (0xeb1ea0, 6 B)
; [nakarest] Text (6 B at 0xeb1ea0), first string "i114"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i114`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b0c).
IconName_i114:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A30, 0x6
; [nakarest] IconName_i113  +0x4a36..+0x4a3c (0xeb1ea6, 6 B)
; [nakarest] Text (6 B at 0xeb1ea6), first string "i113"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i113`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b08).
IconName_i113:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A36, 0x6
; [nakarest] IconName_i112  +0x4a3c..+0x4a42 (0xeb1eac, 6 B)
; [nakarest] Text (6 B at 0xeb1eac), first string "i112"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i112`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b04).
IconName_i112:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A3C, 0x6
; [nakarest] IconName_i111  +0x4a42..+0x4a48 (0xeb1eb2, 6 B)
; [nakarest] Text (6 B at 0xeb1eb2), first string "i111"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i111`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1b00).
IconName_i111:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A42, 0x6
; [nakarest] IconName_i110  +0x4a48..+0x4a4e (0xeb1eb8, 6 B)
; [nakarest] Text (6 B at 0xeb1eb8), first string "i110"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i110`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1afc).
IconName_i110:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A48, 0x6
; [nakarest] IconName_i109  +0x4a4e..+0x4a54 (0xeb1ebe, 6 B)
; [nakarest] Text (6 B at 0xeb1ebe), first string "i109"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i109`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1af8).
IconName_i109:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A4E, 0x6
; [nakarest] IconName_i108  +0x4a54..+0x4a5a (0xeb1ec4, 6 B)
; [nakarest] Text (6 B at 0xeb1ec4), first string "i108"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i108`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1af4).
IconName_i108:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A54, 0x6
; [nakarest] IconName_i107  +0x4a5a..+0x4a60 (0xeb1eca, 6 B)
; [nakarest] Text (6 B at 0xeb1eca), first string "i107"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i107`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1af0).
IconName_i107:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A5A, 0x6
; [nakarest] IconName_i106  +0x4a60..+0x4a66 (0xeb1ed0, 6 B)
; [nakarest] Text (6 B at 0xeb1ed0), first string "i106"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i106`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1aec).
IconName_i106:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A60, 0x6
; [nakarest] IconName_i105  +0x4a66..+0x4a6c (0xeb1ed6, 6 B)
; [nakarest] Text (6 B at 0xeb1ed6), first string "i105"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i105`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ae8).
IconName_i105:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A66, 0x6
; [nakarest] IconName_i104  +0x4a6c..+0x4a72 (0xeb1edc, 6 B)
; [nakarest] Text (6 B at 0xeb1edc), first string "i104"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i104`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ae4).
IconName_i104:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A6C, 0x6
; [nakarest] IconName_i103  +0x4a72..+0x4a78 (0xeb1ee2, 6 B)
; [nakarest] Text (6 B at 0xeb1ee2), first string "i103"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i103`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ae0).
IconName_i103:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A72, 0x6
; [nakarest] IconName_i102  +0x4a78..+0x4a7e (0xeb1ee8, 6 B)
; [nakarest] Text (6 B at 0xeb1ee8), first string "i102"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i102`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1adc).
IconName_i102:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A78, 0x6
; [nakarest] IconName_i101  +0x4a7e..+0x4a84 (0xeb1eee, 6 B)
; [nakarest] Text (6 B at 0xeb1eee), first string "i101"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i101`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ad8).
IconName_i101:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A7E, 0x6
; [nakarest] IconName_i100  +0x4a84..+0x4a8a (0xeb1ef4, 6 B)
; [nakarest] Text (6 B at 0xeb1ef4), first string "i100"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i100`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ad4).
IconName_i100:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A84, 0x6
; [nakarest] IconName_i99  +0x4a8a..+0x4a8e (0xeb1efa, 4 B)
; [nakarest] Text (4 B at 0xeb1efa), first string "i99"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i99`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ad0).
IconName_i99:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A8A, 0x4
; [nakarest] IconName_i98  +0x4a8e..+0x4a92 (0xeb1efe, 4 B)
; [nakarest] Text (4 B at 0xeb1efe), first string "i98"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i98`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1acc).
IconName_i98:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A8E, 0x4
; [nakarest] IconName_i97  +0x4a92..+0x4a96 (0xeb1f02, 4 B)
; [nakarest] Text (4 B at 0xeb1f02), first string "i97"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i97`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ac8).
IconName_i97:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A92, 0x4
; [nakarest] IconName_i96  +0x4a96..+0x4a9a (0xeb1f06, 4 B)
; [nakarest] Text (4 B at 0xeb1f06), first string "i96"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i96`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ac4).
IconName_i96:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A96, 0x4
; [nakarest] IconName_i95  +0x4a9a..+0x4a9e (0xeb1f0a, 4 B)
; [nakarest] Text (4 B at 0xeb1f0a), first string "i95"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i95`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ac0).
IconName_i95:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A9A, 0x4
; [nakarest] IconName_i94  +0x4a9e..+0x4aa2 (0xeb1f0e, 4 B)
; [nakarest] Text (4 B at 0xeb1f0e), first string "i94"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i94`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1abc).
IconName_i94:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4A9E, 0x4
; [nakarest] IconName_i93  +0x4aa2..+0x4aa6 (0xeb1f12, 4 B)
; [nakarest] Text (4 B at 0xeb1f12), first string "i93"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i93`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ab8).
IconName_i93:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AA2, 0x4
; [nakarest] IconName_i92  +0x4aa6..+0x4aaa (0xeb1f16, 4 B)
; [nakarest] Text (4 B at 0xeb1f16), first string "i92"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i92`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ab4).
IconName_i92:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AA6, 0x4
; [nakarest] IconName_i91  +0x4aaa..+0x4aae (0xeb1f1a, 4 B)
; [nakarest] Text (4 B at 0xeb1f1a), first string "i91"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i91`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1ab0).
IconName_i91:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AAA, 0x4
; [nakarest] IconName_i90  +0x4aae..+0x4ab2 (0xeb1f1e, 4 B)
; [nakarest] Text (4 B at 0xeb1f1e), first string "i90"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i90`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1aac).
IconName_i90:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AAE, 0x4
; [nakarest] IconName_i89  +0x4ab2..+0x4ab6 (0xeb1f22, 4 B)
; [nakarest] Text (4 B at 0xeb1f22), first string "i89"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i89`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1aa8).
IconName_i89:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AB2, 0x4
; [nakarest] IconName_i88  +0x4ab6..+0x4aba (0xeb1f26, 4 B)
; [nakarest] Text (4 B at 0xeb1f26), first string "i88"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i88`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1aa4).
IconName_i88:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AB6, 0x4
; [nakarest] IconName_i87  +0x4aba..+0x4abe (0xeb1f2a, 4 B)
; [nakarest] Text (4 B at 0xeb1f2a), first string "i87"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i87`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1aa0).
IconName_i87:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ABA, 0x4
; [nakarest] IconName_i86  +0x4abe..+0x4ac2 (0xeb1f2e, 4 B)
; [nakarest] Text (4 B at 0xeb1f2e), first string "i86"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i86`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a9c).
IconName_i86:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ABE, 0x4
; [nakarest] IconName_i85  +0x4ac2..+0x4ac6 (0xeb1f32, 4 B)
; [nakarest] Text (4 B at 0xeb1f32), first string "i85"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i85`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a98).
IconName_i85:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AC2, 0x4
; [nakarest] IconName_i84  +0x4ac6..+0x4aca (0xeb1f36, 4 B)
; [nakarest] Text (4 B at 0xeb1f36), first string "i84"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i84`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a94).
IconName_i84:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AC6, 0x4
; [nakarest] IconName_i83  +0x4aca..+0x4ace (0xeb1f3a, 4 B)
; [nakarest] Text (4 B at 0xeb1f3a), first string "i83"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i83`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a90).
IconName_i83:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ACA, 0x4
; [nakarest] IconName_i82  +0x4ace..+0x4ad2 (0xeb1f3e, 4 B)
; [nakarest] Text (4 B at 0xeb1f3e), first string "i82"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i82`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a8c).
IconName_i82:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ACE, 0x4
; [nakarest] IconName_i81  +0x4ad2..+0x4ad6 (0xeb1f42, 4 B)
; [nakarest] Text (4 B at 0xeb1f42), first string "i81"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i81`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a88).
IconName_i81:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AD2, 0x4
; [nakarest] IconName_i80  +0x4ad6..+0x4ada (0xeb1f46, 4 B)
; [nakarest] Text (4 B at 0xeb1f46), first string "i80"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i80`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a84).
IconName_i80:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AD6, 0x4
; [nakarest] IconName_i79  +0x4ada..+0x4ade (0xeb1f4a, 4 B)
; [nakarest] Text (4 B at 0xeb1f4a), first string "i79"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i79`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a80).
IconName_i79:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ADA, 0x4
; [nakarest] IconName_i78  +0x4ade..+0x4ae2 (0xeb1f4e, 4 B)
; [nakarest] Text (4 B at 0xeb1f4e), first string "i78"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i78`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a7c).
IconName_i78:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4ADE, 0x4
; [nakarest] IconName_i77  +0x4ae2..+0x4ae6 (0xeb1f52, 4 B)
; [nakarest] Text (4 B at 0xeb1f52), first string "i77"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i77`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a78).
IconName_i77:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AE2, 0x4
; [nakarest] IconName_i76  +0x4ae6..+0x4aea (0xeb1f56, 4 B)
; [nakarest] Text (4 B at 0xeb1f56), first string "i76"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i76`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a74).
IconName_i76:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AE6, 0x4
; [nakarest] IconName_i75  +0x4aea..+0x4aee (0xeb1f5a, 4 B)
; [nakarest] Text (4 B at 0xeb1f5a), first string "i75"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i75`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a70).
IconName_i75:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AEA, 0x4
; [nakarest] IconName_i74  +0x4aee..+0x4af2 (0xeb1f5e, 4 B)
; [nakarest] Text (4 B at 0xeb1f5e), first string "i74"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i74`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a6c).
IconName_i74:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AEE, 0x4
; [nakarest] IconName_i73  +0x4af2..+0x4af6 (0xeb1f62, 4 B)
; [nakarest] Text (4 B at 0xeb1f62), first string "i73"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i73`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a68).
IconName_i73:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AF2, 0x4
; [nakarest] IconName_i72  +0x4af6..+0x4afa (0xeb1f66, 4 B)
; [nakarest] Text (4 B at 0xeb1f66), first string "i72"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i72`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a64).
IconName_i72:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AF6, 0x4
; [nakarest] IconName_i71  +0x4afa..+0x4afe (0xeb1f6a, 4 B)
; [nakarest] Text (4 B at 0xeb1f6a), first string "i71"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i71`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a60).
IconName_i71:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AFA, 0x4
; [nakarest] IconName_i70  +0x4afe..+0x4b02 (0xeb1f6e, 4 B)
; [nakarest] Text (4 B at 0xeb1f6e), first string "i70"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i70`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a5c).
IconName_i70:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4AFE, 0x4
; [nakarest] IconName_i69  +0x4b02..+0x4b06 (0xeb1f72, 4 B)
; [nakarest] Text (4 B at 0xeb1f72), first string "i69"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i69`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a58).
IconName_i69:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B02, 0x4
; [nakarest] IconName_i68  +0x4b06..+0x4b0a (0xeb1f76, 4 B)
; [nakarest] Text (4 B at 0xeb1f76), first string "i68"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i68`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a54).
IconName_i68:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B06, 0x4
; [nakarest] IconName_i67  +0x4b0a..+0x4b0e (0xeb1f7a, 4 B)
; [nakarest] Text (4 B at 0xeb1f7a), first string "i67"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i67`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a50).
IconName_i67:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B0A, 0x4
; [nakarest] IconName_i66  +0x4b0e..+0x4b12 (0xeb1f7e, 4 B)
; [nakarest] Text (4 B at 0xeb1f7e), first string "i66"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i66`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a4c).
IconName_i66:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B0E, 0x4
; [nakarest] IconName_i65  +0x4b12..+0x4b16 (0xeb1f82, 4 B)
; [nakarest] Text (4 B at 0xeb1f82), first string "i65"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i65`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a48).
IconName_i65:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B12, 0x4
; [nakarest] IconName_i64  +0x4b16..+0x4b1a (0xeb1f86, 4 B)
; [nakarest] Text (4 B at 0xeb1f86), first string "i64"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i64`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a44).
IconName_i64:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B16, 0x4
; [nakarest] IconName_i63  +0x4b1a..+0x4b1e (0xeb1f8a, 4 B)
; [nakarest] Text (4 B at 0xeb1f8a), first string "i63"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i63`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a40).
IconName_i63:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B1A, 0x4
; [nakarest] IconName_i62  +0x4b1e..+0x4b22 (0xeb1f8e, 4 B)
; [nakarest] Text (4 B at 0xeb1f8e), first string "i62"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i62`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a3c).
IconName_i62:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B1E, 0x4
; [nakarest] IconName_i61  +0x4b22..+0x4b26 (0xeb1f92, 4 B)
; [nakarest] Text (4 B at 0xeb1f92), first string "i61"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i61`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a38).
IconName_i61:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B22, 0x4
; [nakarest] IconName_i60  +0x4b26..+0x4b2a (0xeb1f96, 4 B)
; [nakarest] Text (4 B at 0xeb1f96), first string "i60"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i60`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a34).
IconName_i60:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B26, 0x4
; [nakarest] IconName_i59  +0x4b2a..+0x4b2e (0xeb1f9a, 4 B)
; [nakarest] Text (4 B at 0xeb1f9a), first string "i59"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i59`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a30).
IconName_i59:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B2A, 0x4
; [nakarest] IconName_i58  +0x4b2e..+0x4b32 (0xeb1f9e, 4 B)
; [nakarest] Text (4 B at 0xeb1f9e), first string "i58"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i58`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a2c).
IconName_i58:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B2E, 0x4
; [nakarest] IconName_i57  +0x4b32..+0x4b36 (0xeb1fa2, 4 B)
; [nakarest] Text (4 B at 0xeb1fa2), first string "i57"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i57`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a28).
IconName_i57:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B32, 0x4
; [nakarest] IconName_i56  +0x4b36..+0x4b3a (0xeb1fa6, 4 B)
; [nakarest] Text (4 B at 0xeb1fa6), first string "i56"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i56`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a24).
IconName_i56:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B36, 0x4
; [nakarest] IconName_i55  +0x4b3a..+0x4b3e (0xeb1faa, 4 B)
; [nakarest] Text (4 B at 0xeb1faa), first string "i55"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i55`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a20).
IconName_i55:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B3A, 0x4
; [nakarest] IconName_i54  +0x4b3e..+0x4b42 (0xeb1fae, 4 B)
; [nakarest] Text (4 B at 0xeb1fae), first string "i54"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i54`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a1c).
IconName_i54:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B3E, 0x4
; [nakarest] IconName_i53  +0x4b42..+0x4b46 (0xeb1fb2, 4 B)
; [nakarest] Text (4 B at 0xeb1fb2), first string "i53"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i53`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a18).
IconName_i53:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B42, 0x4
; [nakarest] IconName_i52  +0x4b46..+0x4b4a (0xeb1fb6, 4 B)
; [nakarest] Text (4 B at 0xeb1fb6), first string "i52"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i52`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a14).
IconName_i52:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B46, 0x4
; [nakarest] IconName_i51  +0x4b4a..+0x4b4e (0xeb1fba, 4 B)
; [nakarest] Text (4 B at 0xeb1fba), first string "i51"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i51`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a10).
IconName_i51:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B4A, 0x4
; [nakarest] IconName_i50  +0x4b4e..+0x4b52 (0xeb1fbe, 4 B)
; [nakarest] Text (4 B at 0xeb1fbe), first string "i50"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i50`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a0c).
IconName_i50:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B4E, 0x4
; [nakarest] IconName_i49  +0x4b52..+0x4b56 (0xeb1fc2, 4 B)
; [nakarest] Text (4 B at 0xeb1fc2), first string "i49"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i49`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a08).
IconName_i49:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B52, 0x4
; [nakarest] IconName_i48  +0x4b56..+0x4b5a (0xeb1fc6, 4 B)
; [nakarest] Text (4 B at 0xeb1fc6), first string "i48"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i48`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a04).
IconName_i48:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B56, 0x4
; [nakarest] IconName_i47  +0x4b5a..+0x4b5e (0xeb1fca, 4 B)
; [nakarest] Text (4 B at 0xeb1fca), first string "i47"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i47`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1a00).
IconName_i47:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B5A, 0x4
; [nakarest] IconName_i46  +0x4b5e..+0x4b62 (0xeb1fce, 4 B)
; [nakarest] Text (4 B at 0xeb1fce), first string "i46"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i46`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19fc).
IconName_i46:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B5E, 0x4
; [nakarest] IconName_i45  +0x4b62..+0x4b66 (0xeb1fd2, 4 B)
; [nakarest] Text (4 B at 0xeb1fd2), first string "i45"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i45`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19f8).
IconName_i45:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B62, 0x4
; [nakarest] IconName_i44  +0x4b66..+0x4b6a (0xeb1fd6, 4 B)
; [nakarest] Text (4 B at 0xeb1fd6), first string "i44"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i44`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19f4).
IconName_i44:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B66, 0x4
; [nakarest] IconName_i43  +0x4b6a..+0x4b6e (0xeb1fda, 4 B)
; [nakarest] Text (4 B at 0xeb1fda), first string "i43"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i43`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19f0).
IconName_i43:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B6A, 0x4
; [nakarest] IconName_i42  +0x4b6e..+0x4b72 (0xeb1fde, 4 B)
; [nakarest] Text (4 B at 0xeb1fde), first string "i42"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i42`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19ec).
IconName_i42:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B6E, 0x4
; [nakarest] IconName_i41  +0x4b72..+0x4b76 (0xeb1fe2, 4 B)
; [nakarest] Text (4 B at 0xeb1fe2), first string "i41"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i41`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19e8).
IconName_i41:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B72, 0x4
; [nakarest] IconName_i40  +0x4b76..+0x4b7a (0xeb1fe6, 4 B)
; [nakarest] Text (4 B at 0xeb1fe6), first string "i40"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i40`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19e4).
IconName_i40:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B76, 0x4
; [nakarest] IconName_i39  +0x4b7a..+0x4b7e (0xeb1fea, 4 B)
; [nakarest] Text (4 B at 0xeb1fea), first string "i39"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i39`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19e0).
IconName_i39:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B7A, 0x4
; [nakarest] IconName_i38  +0x4b7e..+0x4b82 (0xeb1fee, 4 B)
; [nakarest] Text (4 B at 0xeb1fee), first string "i38"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i38`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19dc).
IconName_i38:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B7E, 0x4
; [nakarest] IconName_i37  +0x4b82..+0x4b86 (0xeb1ff2, 4 B)
; [nakarest] Text (4 B at 0xeb1ff2), first string "i37"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i37`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19d8).
IconName_i37:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B82, 0x4
; [nakarest] IconName_i36  +0x4b86..+0x4b8a (0xeb1ff6, 4 B)
; [nakarest] Text (4 B at 0xeb1ff6), first string "i36"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i36`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19d4).
IconName_i36:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B86, 0x4
; [nakarest] IconName_i35  +0x4b8a..+0x4b8e (0xeb1ffa, 4 B)
; [nakarest] Text (4 B at 0xeb1ffa), first string "i35"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i35`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19d0).
IconName_i35:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B8A, 0x4
; [nakarest] IconName_i34  +0x4b8e..+0x4b92 (0xeb1ffe, 4 B)
; [nakarest] Text (4 B at 0xeb1ffe), first string "i34"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i34`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19cc).
IconName_i34:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B8E, 0x4
; [nakarest] IconName_i33  +0x4b92..+0x4b96 (0xeb2002, 4 B)
; [nakarest] Text (4 B at 0xeb2002), first string "i33"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i33`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19c8).
IconName_i33:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B92, 0x4
; [nakarest] IconName_i32  +0x4b96..+0x4b9a (0xeb2006, 4 B)
; [nakarest] Text (4 B at 0xeb2006), first string "i32"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i32`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19c4).
IconName_i32:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B96, 0x4
; [nakarest] IconName_i31  +0x4b9a..+0x4b9e (0xeb200a, 4 B)
; [nakarest] Text (4 B at 0xeb200a), first string "i31"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i31`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19c0).
IconName_i31:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B9A, 0x4
; [nakarest] IconName_i30  +0x4b9e..+0x4ba2 (0xeb200e, 4 B)
; [nakarest] Text (4 B at 0xeb200e), first string "i30"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i30`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19bc).
IconName_i30:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4B9E, 0x4
; [nakarest] IconName_i29  +0x4ba2..+0x4ba6 (0xeb2012, 4 B)
; [nakarest] Text (4 B at 0xeb2012), first string "i29"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i29`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19b8).
IconName_i29:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BA2, 0x4
; [nakarest] IconName_i28  +0x4ba6..+0x4baa (0xeb2016, 4 B)
; [nakarest] Text (4 B at 0xeb2016), first string "i28"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i28`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19b4).
IconName_i28:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BA6, 0x4
; [nakarest] IconName_i27  +0x4baa..+0x4bae (0xeb201a, 4 B)
; [nakarest] Text (4 B at 0xeb201a), first string "i27"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i27`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19b0).
IconName_i27:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BAA, 0x4
; [nakarest] IconName_i26  +0x4bae..+0x4bb2 (0xeb201e, 4 B)
; [nakarest] Text (4 B at 0xeb201e), first string "i26"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i26`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19ac).
IconName_i26:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BAE, 0x4
; [nakarest] IconName_i25  +0x4bb2..+0x4bb6 (0xeb2022, 4 B)
; [nakarest] Text (4 B at 0xeb2022), first string "i25"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i25`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19a8).
IconName_i25:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BB2, 0x4
; [nakarest] IconName_i24  +0x4bb6..+0x4bba (0xeb2026, 4 B)
; [nakarest] Text (4 B at 0xeb2026), first string "i24"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i24`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19a4).
IconName_i24:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BB6, 0x4
; [nakarest] IconName_i23  +0x4bba..+0x4bbe (0xeb202a, 4 B)
; [nakarest] Text (4 B at 0xeb202a), first string "i23"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i23`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb19a0).
IconName_i23:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BBA, 0x4
; [nakarest] IconName_i22  +0x4bbe..+0x4bc2 (0xeb202e, 4 B)
; [nakarest] Text (4 B at 0xeb202e), first string "i22"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i22`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb199c).
IconName_i22:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BBE, 0x4
; [nakarest] IconName_i21  +0x4bc2..+0x4bc6 (0xeb2032, 4 B)
; [nakarest] Text (4 B at 0xeb2032), first string "i21"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i21`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1998).
IconName_i21:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BC2, 0x4
; [nakarest] IconName_i20  +0x4bc6..+0x4bca (0xeb2036, 4 B)
; [nakarest] Text (4 B at 0xeb2036), first string "i20"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i20`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1994).
IconName_i20:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BC6, 0x4
; [nakarest] IconName_i19  +0x4bca..+0x4bce (0xeb203a, 4 B)
; [nakarest] Text (4 B at 0xeb203a), first string "i19"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i19`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1990).
IconName_i19:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BCA, 0x4
; [nakarest] IconName_i18  +0x4bce..+0x4bd2 (0xeb203e, 4 B)
; [nakarest] Text (4 B at 0xeb203e), first string "i18"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i18`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb198c).
IconName_i18:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BCE, 0x4
; [nakarest] IconName_i17  +0x4bd2..+0x4bd6 (0xeb2042, 4 B)
; [nakarest] Text (4 B at 0xeb2042), first string "i17"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i17`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1988).
IconName_i17:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BD2, 0x4
; [nakarest] IconName_i16  +0x4bd6..+0x4bda (0xeb2046, 4 B)
; [nakarest] Text (4 B at 0xeb2046), first string "i16"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i16`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1984).
IconName_i16:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BD6, 0x4
; [nakarest] IconName_i15  +0x4bda..+0x4bde (0xeb204a, 4 B)
; [nakarest] Text (4 B at 0xeb204a), first string "i15"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i15`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1980).
IconName_i15:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BDA, 0x4
; [nakarest] IconName_i14  +0x4bde..+0x4be2 (0xeb204e, 4 B)
; [nakarest] Text (4 B at 0xeb204e), first string "i14"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i14`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb197c).
IconName_i14:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BDE, 0x4
; [nakarest] IconName_i13  +0x4be2..+0x4be6 (0xeb2052, 4 B)
; [nakarest] Text (4 B at 0xeb2052), first string "i13"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i13`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1978).
IconName_i13:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BE2, 0x4
; [nakarest] IconName_i12  +0x4be6..+0x4bea (0xeb2056, 4 B)
; [nakarest] Text (4 B at 0xeb2056), first string "i12"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i12`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1974).
IconName_i12:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BE6, 0x4
; [nakarest] IconName_i11  +0x4bea..+0x4bee (0xeb205a, 4 B)
; [nakarest] Text (4 B at 0xeb205a), first string "i11"; no registered NAKA table points into
; [nakarest] it; reached through source references
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconName_i11`); 1 data word in
; [nakarest] EmbeddedPtrTable_v9_naka_widget_names_charmap_004500 (at 0xeb1970).
IconName_i11:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BEA, 0x4
; [nakarest] IconName_i10  +0x4bee..+0x4bf2 (0xeb205e, 4 B)
; [nakarest] Text (4 B at 0xeb205e), first string "i10"; no registered NAKA table points into
; [nakarest] it; reached through 1 data word in IconNamePtrTable (at 0xeb196c).
IconName_i10:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BEE, 0x4
; [nakarest] IconName_i9  +0x4bf2..+0x4bf6 (0xeb2062, 4 B)
; [nakarest] Text (4 B at 0xeb2062), first string "i9"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1968).
IconName_i9:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BF2, 0x4
; [nakarest] IconName_i8  +0x4bf6..+0x4bfa (0xeb2066, 4 B)
; [nakarest] Text (4 B at 0xeb2066), first string "i8"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1964).
IconName_i8:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BF6, 0x4
; [nakarest] IconName_i7  +0x4bfa..+0x4bfe (0xeb206a, 4 B)
; [nakarest] Text (4 B at 0xeb206a), first string "i7"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1960).
IconName_i7:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BFA, 0x4
; [nakarest] IconName_i6  +0x4bfe..+0x4c02 (0xeb206e, 4 B)
; [nakarest] Text (4 B at 0xeb206e), first string "i6"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb195c).
IconName_i6:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4BFE, 0x4
; [nakarest] IconName_i5  +0x4c02..+0x4c06 (0xeb2072, 4 B)
; [nakarest] Text (4 B at 0xeb2072), first string "i5"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1958).
IconName_i5:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C02, 0x4
; [nakarest] IconName_i4  +0x4c06..+0x4c0a (0xeb2076, 4 B)
; [nakarest] Text (4 B at 0xeb2076), first string "i4"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1954).
IconName_i4:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C06, 0x4
; [nakarest] IconName_i3  +0x4c0a..+0x4c0e (0xeb207a, 4 B)
; [nakarest] Text (4 B at 0xeb207a), first string "i3"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1950).
IconName_i3:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C0A, 0x4
; [nakarest] IconName_i2  +0x4c0e..+0x4c12 (0xeb207e, 4 B)
; [nakarest] Text (4 B at 0xeb207e), first string "i2"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb194c).
IconName_i2:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C0E, 0x4
; [nakarest] IconName_i1  +0x4c12..+0x4c16 (0xeb2082, 4 B)
; [nakarest] Text (4 B at 0xeb2082), first string "i1"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1948).
IconName_i1:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C12, 0x4
; [nakarest] IconName_i0  +0x4c16..+0x4c1a (0xeb2086, 4 B)
; [nakarest] Text (4 B at 0xeb2086), first string "i0"; no registered NAKA table points into it;
; [nakarest] reached through 1 data word in IconNamePtrTable (at 0xeb1944).
IconName_i0:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C16, 0x4
; [nakarest] IconName_Default  +0x4c1a..+0x4c28 (0xeb208a, 14 B)
; [nakarest] Text (14 B at 0xeb208a), first string "Default"; no registered NAKA table points
; [nakarest] into it; reached through 1 data word in IconNamePtrTable (at 0xeb1940); 1 data word
; [nakarest] in IconIDProc_PtrTable (at 0xeb193c), which is read by IconIDProc
; [nakarest] (ui/ui_widget_defs.s: `ld xbc, IconIDProc_PtrTable`), SliderV_CalcRange
; [nakarest] (ui/ui_widget_defs.s: `ld xbc, IconIDProc_PtrTable`), 1 more.
IconName_Default:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4C1A, 0xE
EmbeddedPtrTable_v9_naka_widget_names_charmap_004C28:
IconBitmapNamePtrTable:
	.long NakaInst_trash_bmp
	.long 0x00EB2AAE
	.long 0x00EB2AA6
	.long 0x00EB2A9E
	.long 0x00EB2A96
	.long 0x00EB2A8E
	.long 0x00EB2A86
	.long 0x00EB2A7E
	.long 0x00EB2A76
	.long 0x00EB2A6E
	.long 0x00EB2A66
	.long 0x00EB2A5E
	.long 0x00EB2A56
	.long 0x00EB2A4E
	.long 0x00EB2A46
	.long 0x00EB2A3E
	.long 0x00EB2A36
	.long 0x00EB2A2E
	.long 0x00EB2A26
	.long 0x00EB2A1E
	.long 0x00EB2A16
	.long 0x00EB2A0E
	.long 0x00EB2A06
	.long 0x00EB29FE
	.long 0x00EB29F6
	.long 0x00EB29EE
	.long 0x00EB29E6
	.long 0x00EB29DE
	.long 0x00EB29D6
	.long 0x00EB29CE
	.long 0x00EB29C6
	.long 0x00EB29BE
	.long 0x00EB29B6
	.long 0x00EB29AE
	.long 0x00EB29A6
	.long 0x00EB299E
	.long 0x00EB2996
	.long 0x00EB298E
	.long 0x00EB2986
	.long 0x00EB297E
	.long 0x00EB2976
	.long 0x00EB296E
	.long 0x00EB2966
	.long 0x00EB295E
	.long 0x00EB2956
	.long 0x00EB294E
	.long 0x00EB2946
	.long 0x00EB293E
	.long 0x00EB2936
	.long 0x00EB292E
	.long 0x00EB2926
	.long 0x00EB291E
	.long 0x00EB2916
	.long 0x00EB290E
	.long 0x00EB2906
	.long 0x00EB28FE
	.long 0x00EB28F6
	.long 0x00EB28EE
	.long 0x00EB28E6
	.long 0x00EB28DE
	.long 0x00EB28D6
	.long 0x00EB28CE
	.long 0x00EB28C6
	.long 0x00EB28BE
	.long 0x00EB28B6
	.long 0x00EB28AE
	.long 0x00EB28A6
	.long 0x00EB289E
	.long 0x00EB2896
	.long 0x00EB288E
	.long 0x00EB2886
	.long 0x00EB287E
	.long NakaInst_0_bmp
	.long NakaInst_i71_bmp
	.long NakaInst_i72_bmp
	.long NakaInst_i73o_bmp
	.long NakaInst_i74o_bmp
	.long NakaInst_i75_bmp
	.long NakaInst_i76_bmp
	.long NakaInst_i77_bmp
	.long NakaInst_i78_bmp
	.long NakaInst_i79_bmp
	.long NakaInst_i80_bmp
	.long NakaInst_i81_bmp
	.long NakaInst_i82_bmp
	.long NakaInst_i83_bmp
	.long NakaInst_i84o_bmp
	.long NakaInst_i85_bmp
	.long NakaInst_i86_bmp
	.long NakaInst_i87_bmp
	.long IconBitmapName_i88
	.long IconBitmapName_i89
	.long IconBitmapName_i90o
	.long IconBitmapName_i91o
	.long IconBitmapName_i92o
	.long IconBitmapName_i93o
	.long IconBitmapName_i94
	.long IconBitmapName_i95
	.long 0x00EB2796
	.long IconBitmapName_i97
	.long IconBitmapName_i98
	.long IconBitmapName_i99
	.long IconBitmapName_i100
	.long IconBitmapName_i101
	.long IconBitmapName_i102
	.long IconBitmapName_i103
	.long IconBitmapName_i104
	.long IconBitmapName_i105
	.long IconBitmapName_i106
	.long IconBitmapName_i107o
	.long IconBitmapName_i108
	.long IconBitmapName_i109
	.long IconBitmapName_i110
	.long IconBitmapName_i111
	.long IconBitmapName_i112
	.long IconBitmapName_i113
	.long IconBitmapName_i114
	.long IconBitmapName_i115
	.long IconBitmapName_i116
	.long IconBitmapName_i117
	.long IconBitmapName_i118
	.long IconBitmapName_i119
	.long IconBitmapName_i120
	.long IconBitmapName_i121
	.long IconBitmapName_i122
	.long IconBitmapName_i123
	.long IconBitmapName_i124
	.long IconBitmapName_i125
	.long IconBitmapName_i126
	.long IconBitmapName_i127
	.long IconBitmapName_i128
	.long IconBitmapName_i129
	.long IconBitmapName_i130
	.long IconBitmapName_i131
	.long IconBitmapName_i132
	.long IconBitmapName_i133
	.long IconBitmapName_i134
	.long IconBitmapName_i135
	.long IconBitmapName_i136
	.long IconBitmapName_i137
	.long IconBitmapName_i138
	.long IconBitmapName_i139
	.long IconBitmapName_i140
	.long IconBitmapName_i141
	.long IconBitmapName_i142
	.long IconBitmapName_i143
	.long IconBitmapName_i144
	.long IconBitmapName_i145
	.long IconBitmapName_i146
	.long IconBitmapName_i147
	.long IconBitmapName_i148
	.long IconBitmapName_i149
	.long IconBitmapName_i150
	.long IconBitmapName_i151
	.long IconBitmapName_i152
	.long IconBitmapName_i153
	.long IconBitmapName_i154
	.long IconBitmapName_i155
	.long IconBitmapName_i156
	.long IconBitmapName_i157
	.long IconBitmapName_i158
	.long IconBitmapName_i159
	.long IconBitmapName_i160
	.long IconBitmapName_i161
	.long IconBitmapName_i162
	.long IconBitmapName_i163
	.long IconBitmapName_i164
	.long IconBitmapName_i165
	.long IconBitmapName_i166
	.long IconBitmapName_i167
	.long IconBitmapName_i168
	.long IconBitmapName_i169
	.long IconBitmapName_i170
	.long IconBitmapName_i171
	.long IconBitmapName_i172
	.long IconBitmapName_i173
	.long IconBitmapName_Empty
	.long 0x00000000
	.long 0x00000000
	.long 0x00000000
	.long 0x00000000
	.long 0x00000000
; [nakarest] naka_widget_names_charmap+0x4f00  +0x4f00..+0x5028 (0xeb2370, 296 B)
; [nakarest] purpose not established: 296 B at 0xeb2370 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x4F00, 0x128
; [nakarest] IconBitmapName_Empty  +0x5028..+0x502a (0xeb2498, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xeb2498 not derived; readers below
; [nakarest] Readers: source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_Empty`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2358).
IconBitmapName_Empty:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5028, 0x2
; [nakarest] IconBitmapName_i173  +0x502a..+0x5034 (0xeb249a, 10 B)
; [nakarest] Text (10 B at 0xeb249a), first string "i173.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i173`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2354).
IconBitmapName_i173:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x502A, 0xA
; [nakarest] IconBitmapName_i172  +0x5034..+0x503e (0xeb24a4, 10 B)
; [nakarest] Text (10 B at 0xeb24a4), first string "i172.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i172`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2350).
IconBitmapName_i172:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5034, 0xA
; [nakarest] IconBitmapName_i171  +0x503e..+0x5048 (0xeb24ae, 10 B)
; [nakarest] Text (10 B at 0xeb24ae), first string "i171.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i171`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb234c).
IconBitmapName_i171:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x503E, 0xA
; [nakarest] IconBitmapName_i170  +0x5048..+0x5052 (0xeb24b8, 10 B)
; [nakarest] Text (10 B at 0xeb24b8), first string "i170.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i170`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2348).
IconBitmapName_i170:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5048, 0xA
; [nakarest] IconBitmapName_i169  +0x5052..+0x505c (0xeb24c2, 10 B)
; [nakarest] Text (10 B at 0xeb24c2), first string "i169.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i169`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2344).
IconBitmapName_i169:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5052, 0xA
; [nakarest] IconBitmapName_i168  +0x505c..+0x5066 (0xeb24cc, 10 B)
; [nakarest] Text (10 B at 0xeb24cc), first string "i168.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i168`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2340).
IconBitmapName_i168:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x505C, 0xA
; [nakarest] IconBitmapName_i167  +0x5066..+0x5070 (0xeb24d6, 10 B)
; [nakarest] Text (10 B at 0xeb24d6), first string "i167.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i167`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb233c).
IconBitmapName_i167:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5066, 0xA
; [nakarest] IconBitmapName_i166  +0x5070..+0x507a (0xeb24e0, 10 B)
; [nakarest] Text (10 B at 0xeb24e0), first string "i166.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i166`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2338).
IconBitmapName_i166:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5070, 0xA
; [nakarest] IconBitmapName_i165  +0x507a..+0x5084 (0xeb24ea, 10 B)
; [nakarest] Text (10 B at 0xeb24ea), first string "i165.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i165`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2334).
IconBitmapName_i165:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x507A, 0xA
; [nakarest] IconBitmapName_i164  +0x5084..+0x508e (0xeb24f4, 10 B)
; [nakarest] Text (10 B at 0xeb24f4), first string "i164.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i164`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2330).
IconBitmapName_i164:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5084, 0xA
; [nakarest] IconBitmapName_i163  +0x508e..+0x5098 (0xeb24fe, 10 B)
; [nakarest] Text (10 B at 0xeb24fe), first string "i163.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i163`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb232c).
IconBitmapName_i163:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x508E, 0xA
; [nakarest] IconBitmapName_i162  +0x5098..+0x50a2 (0xeb2508, 10 B)
; [nakarest] Text (10 B at 0xeb2508), first string "i162.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i162`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2328).
IconBitmapName_i162:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5098, 0xA
; [nakarest] IconBitmapName_i161  +0x50a2..+0x50ac (0xeb2512, 10 B)
; [nakarest] Text (10 B at 0xeb2512), first string "i161.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i161`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2324).
IconBitmapName_i161:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50A2, 0xA
; [nakarest] IconBitmapName_i160  +0x50ac..+0x50b6 (0xeb251c, 10 B)
; [nakarest] Text (10 B at 0xeb251c), first string "i160.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i160`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2320).
IconBitmapName_i160:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50AC, 0xA
; [nakarest] IconBitmapName_i159  +0x50b6..+0x50c0 (0xeb2526, 10 B)
; [nakarest] Text (10 B at 0xeb2526), first string "i159.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i159`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb231c).
IconBitmapName_i159:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50B6, 0xA
; [nakarest] IconBitmapName_i158  +0x50c0..+0x50ca (0xeb2530, 10 B)
; [nakarest] Text (10 B at 0xeb2530), first string "i158.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i158`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2318).
IconBitmapName_i158:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50C0, 0xA
; [nakarest] IconBitmapName_i157  +0x50ca..+0x50d4 (0xeb253a, 10 B)
; [nakarest] Text (10 B at 0xeb253a), first string "i157.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i157`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2314).
IconBitmapName_i157:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50CA, 0xA
; [nakarest] IconBitmapName_i156  +0x50d4..+0x50de (0xeb2544, 10 B)
; [nakarest] Text (10 B at 0xeb2544), first string "i156.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i156`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2310).
IconBitmapName_i156:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50D4, 0xA
; [nakarest] IconBitmapName_i155  +0x50de..+0x50e8 (0xeb254e, 10 B)
; [nakarest] Text (10 B at 0xeb254e), first string "i155.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i155`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb230c).
IconBitmapName_i155:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50DE, 0xA
; [nakarest] IconBitmapName_i154  +0x50e8..+0x50f2 (0xeb2558, 10 B)
; [nakarest] Text (10 B at 0xeb2558), first string "i154.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i154`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2308).
IconBitmapName_i154:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50E8, 0xA
; [nakarest] IconBitmapName_i153  +0x50f2..+0x50fc (0xeb2562, 10 B)
; [nakarest] Text (10 B at 0xeb2562), first string "i153.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i153`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2304).
IconBitmapName_i153:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50F2, 0xA
; [nakarest] IconBitmapName_i152  +0x50fc..+0x5106 (0xeb256c, 10 B)
; [nakarest] Text (10 B at 0xeb256c), first string "i152.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i152`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2300).
IconBitmapName_i152:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x50FC, 0xA
; [nakarest] IconBitmapName_i151  +0x5106..+0x5110 (0xeb2576, 10 B)
; [nakarest] Text (10 B at 0xeb2576), first string "i151.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i151`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22fc).
IconBitmapName_i151:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5106, 0xA
; [nakarest] IconBitmapName_i150  +0x5110..+0x511a (0xeb2580, 10 B)
; [nakarest] Text (10 B at 0xeb2580), first string "i150.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i150`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22f8).
IconBitmapName_i150:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5110, 0xA
; [nakarest] IconBitmapName_i149  +0x511a..+0x5124 (0xeb258a, 10 B)
; [nakarest] Text (10 B at 0xeb258a), first string "i149.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i149`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22f4).
IconBitmapName_i149:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x511A, 0xA
; [nakarest] IconBitmapName_i148  +0x5124..+0x512e (0xeb2594, 10 B)
; [nakarest] Text (10 B at 0xeb2594), first string "i148.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i148`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22f0).
IconBitmapName_i148:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5124, 0xA
; [nakarest] IconBitmapName_i147  +0x512e..+0x5138 (0xeb259e, 10 B)
; [nakarest] Text (10 B at 0xeb259e), first string "i147.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i147`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22ec).
IconBitmapName_i147:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x512E, 0xA
; [nakarest] IconBitmapName_i146  +0x5138..+0x5142 (0xeb25a8, 10 B)
; [nakarest] Text (10 B at 0xeb25a8), first string "i146.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i146`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22e8).
IconBitmapName_i146:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5138, 0xA
; [nakarest] IconBitmapName_i145  +0x5142..+0x514c (0xeb25b2, 10 B)
; [nakarest] Text (10 B at 0xeb25b2), first string "i145.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i145`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22e4).
IconBitmapName_i145:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5142, 0xA
; [nakarest] IconBitmapName_i144  +0x514c..+0x5156 (0xeb25bc, 10 B)
; [nakarest] Text (10 B at 0xeb25bc), first string "i144.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i144`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22e0).
IconBitmapName_i144:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x514C, 0xA
; [nakarest] IconBitmapName_i143  +0x5156..+0x5160 (0xeb25c6, 10 B)
; [nakarest] Text (10 B at 0xeb25c6), first string "i143.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i143`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22dc).
IconBitmapName_i143:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5156, 0xA
; [nakarest] IconBitmapName_i142  +0x5160..+0x516a (0xeb25d0, 10 B)
; [nakarest] Text (10 B at 0xeb25d0), first string "i142.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i142`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22d8).
IconBitmapName_i142:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5160, 0xA
; [nakarest] IconBitmapName_i141  +0x516a..+0x5174 (0xeb25da, 10 B)
; [nakarest] Text (10 B at 0xeb25da), first string "i141.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i141`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22d4).
IconBitmapName_i141:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x516A, 0xA
; [nakarest] IconBitmapName_i140  +0x5174..+0x517e (0xeb25e4, 10 B)
; [nakarest] Text (10 B at 0xeb25e4), first string "i140.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i140`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22d0).
IconBitmapName_i140:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5174, 0xA
; [nakarest] IconBitmapName_i139  +0x517e..+0x5188 (0xeb25ee, 10 B)
; [nakarest] Text (10 B at 0xeb25ee), first string "i139.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i139`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22cc).
IconBitmapName_i139:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x517E, 0xA
; [nakarest] IconBitmapName_i138  +0x5188..+0x5192 (0xeb25f8, 10 B)
; [nakarest] Text (10 B at 0xeb25f8), first string "i138.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i138`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22c8).
IconBitmapName_i138:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5188, 0xA
; [nakarest] IconBitmapName_i137  +0x5192..+0x519c (0xeb2602, 10 B)
; [nakarest] Text (10 B at 0xeb2602), first string "i137.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i137`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22c4).
IconBitmapName_i137:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5192, 0xA
; [nakarest] IconBitmapName_i136  +0x519c..+0x51a6 (0xeb260c, 10 B)
; [nakarest] Text (10 B at 0xeb260c), first string "i136.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i136`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22c0).
IconBitmapName_i136:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x519C, 0xA
; [nakarest] IconBitmapName_i135  +0x51a6..+0x51b0 (0xeb2616, 10 B)
; [nakarest] Text (10 B at 0xeb2616), first string "i135.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i135`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22bc).
IconBitmapName_i135:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51A6, 0xA
; [nakarest] IconBitmapName_i134  +0x51b0..+0x51ba (0xeb2620, 10 B)
; [nakarest] Text (10 B at 0xeb2620), first string "i134.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i134`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22b8).
IconBitmapName_i134:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51B0, 0xA
; [nakarest] IconBitmapName_i133  +0x51ba..+0x51c4 (0xeb262a, 10 B)
; [nakarest] Text (10 B at 0xeb262a), first string "i133.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i133`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22b4).
IconBitmapName_i133:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51BA, 0xA
; [nakarest] IconBitmapName_i132  +0x51c4..+0x51ce (0xeb2634, 10 B)
; [nakarest] Text (10 B at 0xeb2634), first string "i132.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i132`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22b0).
IconBitmapName_i132:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51C4, 0xA
; [nakarest] IconBitmapName_i131  +0x51ce..+0x51d8 (0xeb263e, 10 B)
; [nakarest] Text (10 B at 0xeb263e), first string "i131.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i131`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22ac).
IconBitmapName_i131:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51CE, 0xA
; [nakarest] IconBitmapName_i130  +0x51d8..+0x51e2 (0xeb2648, 10 B)
; [nakarest] Text (10 B at 0xeb2648), first string "i130.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i130`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22a8).
IconBitmapName_i130:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51D8, 0xA
; [nakarest] IconBitmapName_i129  +0x51e2..+0x51ec (0xeb2652, 10 B)
; [nakarest] Text (10 B at 0xeb2652), first string "i129.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i129`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22a4).
IconBitmapName_i129:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51E2, 0xA
; [nakarest] IconBitmapName_i128  +0x51ec..+0x51f6 (0xeb265c, 10 B)
; [nakarest] Text (10 B at 0xeb265c), first string "i128.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i128`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb22a0).
IconBitmapName_i128:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51EC, 0xA
; [nakarest] IconBitmapName_i127  +0x51f6..+0x5200 (0xeb2666, 10 B)
; [nakarest] Text (10 B at 0xeb2666), first string "i127.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i127`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb229c).
IconBitmapName_i127:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x51F6, 0xA
; [nakarest] IconBitmapName_i126  +0x5200..+0x520a (0xeb2670, 10 B)
; [nakarest] Text (10 B at 0xeb2670), first string "i126.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i126`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2298).
IconBitmapName_i126:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5200, 0xA
; [nakarest] IconBitmapName_i125  +0x520a..+0x5214 (0xeb267a, 10 B)
; [nakarest] Text (10 B at 0xeb267a), first string "i125.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i125`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2294).
IconBitmapName_i125:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x520A, 0xA
; [nakarest] IconBitmapName_i124  +0x5214..+0x521e (0xeb2684, 10 B)
; [nakarest] Text (10 B at 0xeb2684), first string "i124.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i124`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2290).
IconBitmapName_i124:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5214, 0xA
; [nakarest] IconBitmapName_i123  +0x521e..+0x5228 (0xeb268e, 10 B)
; [nakarest] Text (10 B at 0xeb268e), first string "i123.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i123`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb228c).
IconBitmapName_i123:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x521E, 0xA
; [nakarest] IconBitmapName_i122  +0x5228..+0x5232 (0xeb2698, 10 B)
; [nakarest] Text (10 B at 0xeb2698), first string "i122.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i122`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2288).
IconBitmapName_i122:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5228, 0xA
; [nakarest] IconBitmapName_i121  +0x5232..+0x523c (0xeb26a2, 10 B)
; [nakarest] Text (10 B at 0xeb26a2), first string "i121.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i121`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2284).
IconBitmapName_i121:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5232, 0xA
; [nakarest] IconBitmapName_i120  +0x523c..+0x5246 (0xeb26ac, 10 B)
; [nakarest] Text (10 B at 0xeb26ac), first string "i120.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i120`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2280).
IconBitmapName_i120:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x523C, 0xA
; [nakarest] IconBitmapName_i119  +0x5246..+0x5250 (0xeb26b6, 10 B)
; [nakarest] Text (10 B at 0xeb26b6), first string "i119.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i119`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb227c).
IconBitmapName_i119:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5246, 0xA
; [nakarest] IconBitmapName_i118  +0x5250..+0x525a (0xeb26c0, 10 B)
; [nakarest] Text (10 B at 0xeb26c0), first string "i118.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i118`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2278).
IconBitmapName_i118:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5250, 0xA
; [nakarest] IconBitmapName_i117  +0x525a..+0x5264 (0xeb26ca, 10 B)
; [nakarest] Text (10 B at 0xeb26ca), first string "i117.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i117`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2274).
IconBitmapName_i117:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x525A, 0xA
; [nakarest] IconBitmapName_i116  +0x5264..+0x526e (0xeb26d4, 10 B)
; [nakarest] Text (10 B at 0xeb26d4), first string "i116.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i116`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2270).
IconBitmapName_i116:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5264, 0xA
; [nakarest] IconBitmapName_i115  +0x526e..+0x5278 (0xeb26de, 10 B)
; [nakarest] Text (10 B at 0xeb26de), first string "i115.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i115`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb226c).
IconBitmapName_i115:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x526E, 0xA
; [nakarest] IconBitmapName_i114  +0x5278..+0x5282 (0xeb26e8, 10 B)
; [nakarest] Text (10 B at 0xeb26e8), first string "i114.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i114`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2268).
IconBitmapName_i114:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5278, 0xA
; [nakarest] IconBitmapName_i113  +0x5282..+0x528c (0xeb26f2, 10 B)
; [nakarest] Text (10 B at 0xeb26f2), first string "i113.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i113`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2264).
IconBitmapName_i113:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5282, 0xA
; [nakarest] IconBitmapName_i112  +0x528c..+0x5296 (0xeb26fc, 10 B)
; [nakarest] Text (10 B at 0xeb26fc), first string "i112.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i112`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2260).
IconBitmapName_i112:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x528C, 0xA
; [nakarest] IconBitmapName_i111  +0x5296..+0x52a0 (0xeb2706, 10 B)
; [nakarest] Text (10 B at 0xeb2706), first string "i111.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i111`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb225c).
IconBitmapName_i111:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5296, 0xA
; [nakarest] IconBitmapName_i110  +0x52a0..+0x52aa (0xeb2710, 10 B)
; [nakarest] Text (10 B at 0xeb2710), first string "i110.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i110`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2258).
IconBitmapName_i110:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52A0, 0xA
; [nakarest] IconBitmapName_i109  +0x52aa..+0x52b4 (0xeb271a, 10 B)
; [nakarest] Text (10 B at 0xeb271a), first string "i109.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i109`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2254).
IconBitmapName_i109:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52AA, 0xA
; [nakarest] IconBitmapName_i108  +0x52b4..+0x52be (0xeb2724, 10 B)
; [nakarest] Text (10 B at 0xeb2724), first string "i108.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i108`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2250).
IconBitmapName_i108:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52B4, 0xA
; [nakarest] IconBitmapName_i107o  +0x52be..+0x52c8 (0xeb272e, 10 B)
; [nakarest] Text (10 B at 0xeb272e), first string "i107o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i107o`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb224c).
IconBitmapName_i107o:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52BE, 0xA
; [nakarest] IconBitmapName_i106  +0x52c8..+0x52d2 (0xeb2738, 10 B)
; [nakarest] Text (10 B at 0xeb2738), first string "i106.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i106`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2248).
IconBitmapName_i106:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52C8, 0xA
; [nakarest] IconBitmapName_i105  +0x52d2..+0x52dc (0xeb2742, 10 B)
; [nakarest] Text (10 B at 0xeb2742), first string "i105.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i105`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2244).
IconBitmapName_i105:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52D2, 0xA
; [nakarest] IconBitmapName_i104  +0x52dc..+0x52e6 (0xeb274c, 10 B)
; [nakarest] Text (10 B at 0xeb274c), first string "i104.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i104`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2240).
IconBitmapName_i104:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52DC, 0xA
; [nakarest] IconBitmapName_i103  +0x52e6..+0x52f0 (0xeb2756, 10 B)
; [nakarest] Text (10 B at 0xeb2756), first string "i103.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i103`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb223c).
IconBitmapName_i103:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52E6, 0xA
; [nakarest] IconBitmapName_i102  +0x52f0..+0x52fa (0xeb2760, 10 B)
; [nakarest] Text (10 B at 0xeb2760), first string "i102.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i102`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2238).
IconBitmapName_i102:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52F0, 0xA
; [nakarest] IconBitmapName_i101  +0x52fa..+0x5304 (0xeb276a, 10 B)
; [nakarest] Text (10 B at 0xeb276a), first string "i101.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i101`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2234).
IconBitmapName_i101:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x52FA, 0xA
; [nakarest] IconBitmapName_i100  +0x5304..+0x530e (0xeb2774, 10 B)
; [nakarest] Text (10 B at 0xeb2774), first string "i100.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i100`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2230).
IconBitmapName_i100:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5304, 0xA
; [nakarest] IconBitmapName_i99  +0x530e..+0x5316 (0xeb277e, 8 B)
; [nakarest] Text (8 B at 0xeb277e), first string "i99.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i99`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb222c).
IconBitmapName_i99:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x530E, 0x8
; [nakarest] IconBitmapName_i98  +0x5316..+0x531e (0xeb2786, 8 B)
; [nakarest] Text (8 B at 0xeb2786), first string "i98.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i98`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2228).
IconBitmapName_i98:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5316, 0x8
; [nakarest] IconBitmapName_i97  +0x531e..+0x5326 (0xeb278e, 8 B)
; [nakarest] Text (8 B at 0xeb278e), first string "i97.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i97`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2224).
IconBitmapName_i97:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x531E, 0x8
; [nakarest] naka_widget_names_charmap+0x5326  +0x5326..+0x5330 (0xeb2796, 10 B)
; [nakarest] Text (10 B at 0xeb2796), first string "i96o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2796`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2220).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5326, 0xA
; [nakarest] IconBitmapName_i95  +0x5330..+0x5338 (0xeb27a0, 8 B)
; [nakarest] Text (8 B at 0xeb27a0), first string "i95.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i95`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb221c).
IconBitmapName_i95:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5330, 0x8
; [nakarest] IconBitmapName_i94  +0x5338..+0x5340 (0xeb27a8, 8 B)
; [nakarest] Text (8 B at 0xeb27a8), first string "i94.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i94`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2218).
IconBitmapName_i94:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5338, 0x8
; [nakarest] IconBitmapName_i93o  +0x5340..+0x534a (0xeb27b0, 10 B)
; [nakarest] Text (10 B at 0xeb27b0), first string "i93o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i93o`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2214).
IconBitmapName_i93o:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5340, 0xA
; [nakarest] IconBitmapName_i92o  +0x534a..+0x5354 (0xeb27ba, 10 B)
; [nakarest] Text (10 B at 0xeb27ba), first string "i92o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i92o`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2210).
IconBitmapName_i92o:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x534A, 0xA
; [nakarest] IconBitmapName_i91o  +0x5354..+0x535e (0xeb27c4, 10 B)
; [nakarest] Text (10 B at 0xeb27c4), first string "i91o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i91o`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb220c).
IconBitmapName_i91o:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5354, 0xA
; [nakarest] IconBitmapName_i90o  +0x535e..+0x5368 (0xeb27ce, 10 B)
; [nakarest] Text (10 B at 0xeb27ce), first string "i90o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i90o`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2208).
IconBitmapName_i90o:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x535E, 0xA
; [nakarest] IconBitmapName_i89  +0x5368..+0x5370 (0xeb27d8, 8 B)
; [nakarest] Text (8 B at 0xeb27d8), first string "i89.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i89`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2204).
IconBitmapName_i89:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5368, 0x8
; [nakarest] IconBitmapName_i88  +0x5370..+0x5378 (0xeb27e0, 8 B)
; [nakarest] Text (8 B at 0xeb27e0), first string "i88.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long IconBitmapName_i88`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2200).
IconBitmapName_i88:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5370, 0x8
; [nakarest] NakaInst_i87_bmp  +0x5378..+0x5380 (0xeb27e8, 8 B)
; [nakarest] Text (8 B at 0xeb27e8), first string "i87.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i87_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21fc).
NakaInst_i87_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5378, 0x8
; [nakarest] NakaInst_i86_bmp  +0x5380..+0x5388 (0xeb27f0, 8 B)
; [nakarest] Text (8 B at 0xeb27f0), first string "i86.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i86_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21f8).
NakaInst_i86_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5380, 0x8
; [nakarest] NakaInst_i85_bmp  +0x5388..+0x5390 (0xeb27f8, 8 B)
; [nakarest] Text (8 B at 0xeb27f8), first string "i85.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i85_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21f4).
NakaInst_i85_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5388, 0x8
; [nakarest] NakaInst_i84o_bmp  +0x5390..+0x539a (0xeb2800, 10 B)
; [nakarest] Text (10 B at 0xeb2800), first string "i84o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i84o_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21f0).
NakaInst_i84o_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5390, 0xA
; [nakarest] NakaInst_i83_bmp  +0x539a..+0x53a2 (0xeb280a, 8 B)
; [nakarest] Text (8 B at 0xeb280a), first string "i83.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i83_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21ec).
NakaInst_i83_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x539A, 0x8
; [nakarest] NakaInst_i82_bmp  +0x53a2..+0x53aa (0xeb2812, 8 B)
; [nakarest] Text (8 B at 0xeb2812), first string "i82.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i82_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21e8).
NakaInst_i82_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53A2, 0x8
; [nakarest] NakaInst_i81_bmp  +0x53aa..+0x53b2 (0xeb281a, 8 B)
; [nakarest] Text (8 B at 0xeb281a), first string "i81.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i81_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21e4).
NakaInst_i81_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53AA, 0x8
; [nakarest] NakaInst_i80_bmp  +0x53b2..+0x53ba (0xeb2822, 8 B)
; [nakarest] Text (8 B at 0xeb2822), first string "i80.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i80_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21e0).
NakaInst_i80_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53B2, 0x8
; [nakarest] NakaInst_i79_bmp  +0x53ba..+0x53c2 (0xeb282a, 8 B)
; [nakarest] Text (8 B at 0xeb282a), first string "i79.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i79_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21dc).
NakaInst_i79_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53BA, 0x8
; [nakarest] NakaInst_i78_bmp  +0x53c2..+0x53ca (0xeb2832, 8 B)
; [nakarest] Text (8 B at 0xeb2832), first string "i78.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i78_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21d8).
NakaInst_i78_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53C2, 0x8
; [nakarest] NakaInst_i77_bmp  +0x53ca..+0x53d2 (0xeb283a, 8 B)
; [nakarest] Text (8 B at 0xeb283a), first string "i77.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i77_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21d4).
NakaInst_i77_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53CA, 0x8
; [nakarest] NakaInst_i76_bmp  +0x53d2..+0x53da (0xeb2842, 8 B)
; [nakarest] Text (8 B at 0xeb2842), first string "i76.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i76_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21d0).
NakaInst_i76_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53D2, 0x8
; [nakarest] NakaInst_i75_bmp  +0x53da..+0x53e2 (0xeb284a, 8 B)
; [nakarest] Text (8 B at 0xeb284a), first string "i75.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i75_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21cc).
NakaInst_i75_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53DA, 0x8
; [nakarest] NakaInst_i74o_bmp  +0x53e2..+0x53ec (0xeb2852, 10 B)
; [nakarest] Text (10 B at 0xeb2852), first string "i74o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i74o_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21c8).
NakaInst_i74o_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53E2, 0xA
; [nakarest] NakaInst_i73o_bmp  +0x53ec..+0x53f6 (0xeb285c, 10 B)
; [nakarest] Text (10 B at 0xeb285c), first string "i73o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i73o_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21c4).
NakaInst_i73o_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53EC, 0xA
; [nakarest] NakaInst_i72_bmp  +0x53f6..+0x53fe (0xeb2866, 8 B)
; [nakarest] Text (8 B at 0xeb2866), first string "i72.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i72_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21c0).
NakaInst_i72_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53F6, 0x8
; [nakarest] NakaInst_i71_bmp  +0x53fe..+0x5406 (0xeb286e, 8 B)
; [nakarest] Text (8 B at 0xeb286e), first string "i71.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_i71_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21bc).
NakaInst_i71_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x53FE, 0x8
; [nakarest] NakaInst_0_bmp  +0x5406..+0x540e (0xeb2876, 8 B)
; [nakarest] Text (8 B at 0xeb2876), first string "i70.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_0_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21b8).
NakaInst_0_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5406, 0x8
; [nakarest] naka_widget_names_charmap+0x540e  +0x540e..+0x5416 (0xeb287e, 8 B)
; [nakarest] Text (8 B at 0xeb287e), first string "i69.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb287e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21b4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x540E, 0x8
; [nakarest] naka_widget_names_charmap+0x5416  +0x5416..+0x541e (0xeb2886, 8 B)
; [nakarest] Text (8 B at 0xeb2886), first string "i68.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2886`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21b0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5416, 0x8
; [nakarest] naka_widget_names_charmap+0x541e  +0x541e..+0x5426 (0xeb288e, 8 B)
; [nakarest] Text (8 B at 0xeb288e), first string "i67.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb288e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21ac).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x541E, 0x8
; [nakarest] naka_widget_names_charmap+0x5426  +0x5426..+0x542e (0xeb2896, 8 B)
; [nakarest] Text (8 B at 0xeb2896), first string "i66.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2896`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21a8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5426, 0x8
; [nakarest] naka_widget_names_charmap+0x542e  +0x542e..+0x5436 (0xeb289e, 8 B)
; [nakarest] Text (8 B at 0xeb289e), first string "i65.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb289e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21a4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x542E, 0x8
; [nakarest] naka_widget_names_charmap+0x5436  +0x5436..+0x543e (0xeb28a6, 8 B)
; [nakarest] Text (8 B at 0xeb28a6), first string "i64.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28a6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb21a0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5436, 0x8
; [nakarest] naka_widget_names_charmap+0x543e  +0x543e..+0x5446 (0xeb28ae, 8 B)
; [nakarest] Text (8 B at 0xeb28ae), first string "i63.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28ae`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb219c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x543E, 0x8
; [nakarest] naka_widget_names_charmap+0x5446  +0x5446..+0x544e (0xeb28b6, 8 B)
; [nakarest] Text (8 B at 0xeb28b6), first string "i62.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28b6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2198).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5446, 0x8
; [nakarest] naka_widget_names_charmap+0x544e  +0x544e..+0x5456 (0xeb28be, 8 B)
; [nakarest] Text (8 B at 0xeb28be), first string "i61.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28be`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2194).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x544E, 0x8
; [nakarest] naka_widget_names_charmap+0x5456  +0x5456..+0x545e (0xeb28c6, 8 B)
; [nakarest] Text (8 B at 0xeb28c6), first string "i60.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28c6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2190).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5456, 0x8
; [nakarest] naka_widget_names_charmap+0x545e  +0x545e..+0x5466 (0xeb28ce, 8 B)
; [nakarest] Text (8 B at 0xeb28ce), first string "i59.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28ce`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb218c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x545E, 0x8
; [nakarest] naka_widget_names_charmap+0x5466  +0x5466..+0x546e (0xeb28d6, 8 B)
; [nakarest] Text (8 B at 0xeb28d6), first string "i58.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28d6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2188).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5466, 0x8
; [nakarest] naka_widget_names_charmap+0x546e  +0x546e..+0x5476 (0xeb28de, 8 B)
; [nakarest] Text (8 B at 0xeb28de), first string "i57.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28de`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2184).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x546E, 0x8
; [nakarest] naka_widget_names_charmap+0x5476  +0x5476..+0x547e (0xeb28e6, 8 B)
; [nakarest] Text (8 B at 0xeb28e6), first string "i56.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28e6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2180).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5476, 0x8
; [nakarest] naka_widget_names_charmap+0x547e  +0x547e..+0x5486 (0xeb28ee, 8 B)
; [nakarest] Text (8 B at 0xeb28ee), first string "i55.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28ee`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb217c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x547E, 0x8
; [nakarest] naka_widget_names_charmap+0x5486  +0x5486..+0x548e (0xeb28f6, 8 B)
; [nakarest] Text (8 B at 0xeb28f6), first string "i54.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28f6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2178).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5486, 0x8
; [nakarest] naka_widget_names_charmap+0x548e  +0x548e..+0x5496 (0xeb28fe, 8 B)
; [nakarest] Text (8 B at 0xeb28fe), first string "i53.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb28fe`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2174).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x548E, 0x8
; [nakarest] naka_widget_names_charmap+0x5496  +0x5496..+0x549e (0xeb2906, 8 B)
; [nakarest] Text (8 B at 0xeb2906), first string "i52.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2906`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2170).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5496, 0x8
; [nakarest] naka_widget_names_charmap+0x549e  +0x549e..+0x54a6 (0xeb290e, 8 B)
; [nakarest] Text (8 B at 0xeb290e), first string "i51.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb290e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb216c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x549E, 0x8
; [nakarest] naka_widget_names_charmap+0x54a6  +0x54a6..+0x54ae (0xeb2916, 8 B)
; [nakarest] Text (8 B at 0xeb2916), first string "i50.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2916`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2168).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54A6, 0x8
; [nakarest] naka_widget_names_charmap+0x54ae  +0x54ae..+0x54b6 (0xeb291e, 8 B)
; [nakarest] Text (8 B at 0xeb291e), first string "i49.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb291e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2164).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54AE, 0x8
; [nakarest] naka_widget_names_charmap+0x54b6  +0x54b6..+0x54be (0xeb2926, 8 B)
; [nakarest] Text (8 B at 0xeb2926), first string "i48.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2926`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2160).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54B6, 0x8
; [nakarest] naka_widget_names_charmap+0x54be  +0x54be..+0x54c6 (0xeb292e, 8 B)
; [nakarest] Text (8 B at 0xeb292e), first string "i47.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb292e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb215c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54BE, 0x8
; [nakarest] naka_widget_names_charmap+0x54c6  +0x54c6..+0x54ce (0xeb2936, 8 B)
; [nakarest] Text (8 B at 0xeb2936), first string "i46.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2936`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2158).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54C6, 0x8
; [nakarest] naka_widget_names_charmap+0x54ce  +0x54ce..+0x54d6 (0xeb293e, 8 B)
; [nakarest] Text (8 B at 0xeb293e), first string "i45.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb293e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2154).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54CE, 0x8
; [nakarest] naka_widget_names_charmap+0x54d6  +0x54d6..+0x54de (0xeb2946, 8 B)
; [nakarest] Text (8 B at 0xeb2946), first string "i44.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2946`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2150).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54D6, 0x8
; [nakarest] naka_widget_names_charmap+0x54de  +0x54de..+0x54e6 (0xeb294e, 8 B)
; [nakarest] Text (8 B at 0xeb294e), first string "i43.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb294e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb214c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54DE, 0x8
; [nakarest] naka_widget_names_charmap+0x54e6  +0x54e6..+0x54ee (0xeb2956, 8 B)
; [nakarest] Text (8 B at 0xeb2956), first string "i42.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2956`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2148).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54E6, 0x8
; [nakarest] naka_widget_names_charmap+0x54ee  +0x54ee..+0x54f6 (0xeb295e, 8 B)
; [nakarest] Text (8 B at 0xeb295e), first string "i41.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb295e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2144).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54EE, 0x8
; [nakarest] naka_widget_names_charmap+0x54f6  +0x54f6..+0x54fe (0xeb2966, 8 B)
; [nakarest] Text (8 B at 0xeb2966), first string "i40.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2966`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2140).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54F6, 0x8
; [nakarest] naka_widget_names_charmap+0x54fe  +0x54fe..+0x5506 (0xeb296e, 8 B)
; [nakarest] Text (8 B at 0xeb296e), first string "i39.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb296e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb213c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x54FE, 0x8
; [nakarest] naka_widget_names_charmap+0x5506  +0x5506..+0x550e (0xeb2976, 8 B)
; [nakarest] Text (8 B at 0xeb2976), first string "i38.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2976`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2138).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5506, 0x8
; [nakarest] naka_widget_names_charmap+0x550e  +0x550e..+0x5516 (0xeb297e, 8 B)
; [nakarest] Text (8 B at 0xeb297e), first string "i37.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb297e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2134).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x550E, 0x8
; [nakarest] naka_widget_names_charmap+0x5516  +0x5516..+0x551e (0xeb2986, 8 B)
; [nakarest] Text (8 B at 0xeb2986), first string "i36.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2986`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2130).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5516, 0x8
; [nakarest] naka_widget_names_charmap+0x551e  +0x551e..+0x5526 (0xeb298e, 8 B)
; [nakarest] Text (8 B at 0xeb298e), first string "i35.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb298e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb212c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x551E, 0x8
; [nakarest] naka_widget_names_charmap+0x5526  +0x5526..+0x552e (0xeb2996, 8 B)
; [nakarest] Text (8 B at 0xeb2996), first string "i34.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2996`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2128).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5526, 0x8
; [nakarest] naka_widget_names_charmap+0x552e  +0x552e..+0x5536 (0xeb299e, 8 B)
; [nakarest] Text (8 B at 0xeb299e), first string "i33.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb299e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2124).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x552E, 0x8
; [nakarest] naka_widget_names_charmap+0x5536  +0x5536..+0x553e (0xeb29a6, 8 B)
; [nakarest] Text (8 B at 0xeb29a6), first string "i32.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29a6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2120).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5536, 0x8
; [nakarest] naka_widget_names_charmap+0x553e  +0x553e..+0x5546 (0xeb29ae, 8 B)
; [nakarest] Text (8 B at 0xeb29ae), first string "i31.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29ae`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb211c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x553E, 0x8
; [nakarest] naka_widget_names_charmap+0x5546  +0x5546..+0x554e (0xeb29b6, 8 B)
; [nakarest] Text (8 B at 0xeb29b6), first string "i30.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29b6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2118).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5546, 0x8
; [nakarest] naka_widget_names_charmap+0x554e  +0x554e..+0x5556 (0xeb29be, 8 B)
; [nakarest] Text (8 B at 0xeb29be), first string "i29.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29be`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2114).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x554E, 0x8
; [nakarest] naka_widget_names_charmap+0x5556  +0x5556..+0x555e (0xeb29c6, 8 B)
; [nakarest] Text (8 B at 0xeb29c6), first string "i28.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29c6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2110).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5556, 0x8
; [nakarest] naka_widget_names_charmap+0x555e  +0x555e..+0x5566 (0xeb29ce, 8 B)
; [nakarest] Text (8 B at 0xeb29ce), first string "i27.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29ce`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb210c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x555E, 0x8
; [nakarest] naka_widget_names_charmap+0x5566  +0x5566..+0x556e (0xeb29d6, 8 B)
; [nakarest] Text (8 B at 0xeb29d6), first string "i26.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29d6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2108).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5566, 0x8
; [nakarest] naka_widget_names_charmap+0x556e  +0x556e..+0x5576 (0xeb29de, 8 B)
; [nakarest] Text (8 B at 0xeb29de), first string "i25.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29de`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2104).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x556E, 0x8
; [nakarest] naka_widget_names_charmap+0x5576  +0x5576..+0x557e (0xeb29e6, 8 B)
; [nakarest] Text (8 B at 0xeb29e6), first string "i24.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29e6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2100).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5576, 0x8
; [nakarest] naka_widget_names_charmap+0x557e  +0x557e..+0x5586 (0xeb29ee, 8 B)
; [nakarest] Text (8 B at 0xeb29ee), first string "i23.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29ee`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20fc).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x557E, 0x8
; [nakarest] naka_widget_names_charmap+0x5586  +0x5586..+0x558e (0xeb29f6, 8 B)
; [nakarest] Text (8 B at 0xeb29f6), first string "i22.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29f6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20f8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5586, 0x8
; [nakarest] naka_widget_names_charmap+0x558e  +0x558e..+0x5596 (0xeb29fe, 8 B)
; [nakarest] Text (8 B at 0xeb29fe), first string "i21.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb29fe`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20f4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x558E, 0x8
; [nakarest] naka_widget_names_charmap+0x5596  +0x5596..+0x559e (0xeb2a06, 8 B)
; [nakarest] Text (8 B at 0xeb2a06), first string "i20.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a06`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20f0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5596, 0x8
; [nakarest] naka_widget_names_charmap+0x559e  +0x559e..+0x55a6 (0xeb2a0e, 8 B)
; [nakarest] Text (8 B at 0xeb2a0e), first string "i19.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a0e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20ec).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x559E, 0x8
; [nakarest] naka_widget_names_charmap+0x55a6  +0x55a6..+0x55ae (0xeb2a16, 8 B)
; [nakarest] Text (8 B at 0xeb2a16), first string "i18.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a16`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20e8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55A6, 0x8
; [nakarest] naka_widget_names_charmap+0x55ae  +0x55ae..+0x55b6 (0xeb2a1e, 8 B)
; [nakarest] Text (8 B at 0xeb2a1e), first string "i17.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a1e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20e4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55AE, 0x8
; [nakarest] naka_widget_names_charmap+0x55b6  +0x55b6..+0x55be (0xeb2a26, 8 B)
; [nakarest] Text (8 B at 0xeb2a26), first string "i16.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a26`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20e0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55B6, 0x8
; [nakarest] naka_widget_names_charmap+0x55be  +0x55be..+0x55c6 (0xeb2a2e, 8 B)
; [nakarest] Text (8 B at 0xeb2a2e), first string "i15.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a2e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20dc).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55BE, 0x8
; [nakarest] naka_widget_names_charmap+0x55c6  +0x55c6..+0x55ce (0xeb2a36, 8 B)
; [nakarest] Text (8 B at 0xeb2a36), first string "i14.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a36`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20d8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55C6, 0x8
; [nakarest] naka_widget_names_charmap+0x55ce  +0x55ce..+0x55d6 (0xeb2a3e, 8 B)
; [nakarest] Text (8 B at 0xeb2a3e), first string "i13.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a3e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20d4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55CE, 0x8
; [nakarest] naka_widget_names_charmap+0x55d6  +0x55d6..+0x55de (0xeb2a46, 8 B)
; [nakarest] Text (8 B at 0xeb2a46), first string "i12.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a46`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20d0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55D6, 0x8
; [nakarest] naka_widget_names_charmap+0x55de  +0x55de..+0x55e6 (0xeb2a4e, 8 B)
; [nakarest] Text (8 B at 0xeb2a4e), first string "i11.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a4e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20cc).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55DE, 0x8
; [nakarest] naka_widget_names_charmap+0x55e6  +0x55e6..+0x55ee (0xeb2a56, 8 B)
; [nakarest] Text (8 B at 0xeb2a56), first string "i10.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a56`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20c8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55E6, 0x8
; [nakarest] naka_widget_names_charmap+0x55ee  +0x55ee..+0x55f6 (0xeb2a5e, 8 B)
; [nakarest] Text (8 B at 0xeb2a5e), first string "i9.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a5e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20c4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55EE, 0x8
; [nakarest] naka_widget_names_charmap+0x55f6  +0x55f6..+0x55fe (0xeb2a66, 8 B)
; [nakarest] Text (8 B at 0xeb2a66), first string "i8.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a66`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20c0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55F6, 0x8
; [nakarest] naka_widget_names_charmap+0x55fe  +0x55fe..+0x5606 (0xeb2a6e, 8 B)
; [nakarest] Text (8 B at 0xeb2a6e), first string "i7.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a6e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20bc).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x55FE, 0x8
; [nakarest] naka_widget_names_charmap+0x5606  +0x5606..+0x560e (0xeb2a76, 8 B)
; [nakarest] Text (8 B at 0xeb2a76), first string "i6o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a76`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20b8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5606, 0x8
; [nakarest] naka_widget_names_charmap+0x560e  +0x560e..+0x5616 (0xeb2a7e, 8 B)
; [nakarest] Text (8 B at 0xeb2a7e), first string "i5.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a7e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20b4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x560E, 0x8
; [nakarest] naka_widget_names_charmap+0x5616  +0x5616..+0x561e (0xeb2a86, 8 B)
; [nakarest] Text (8 B at 0xeb2a86), first string "i4o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a86`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20b0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5616, 0x8
; [nakarest] naka_widget_names_charmap+0x561e  +0x561e..+0x5626 (0xeb2a8e, 8 B)
; [nakarest] Text (8 B at 0xeb2a8e), first string "i3o.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a8e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20ac).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x561E, 0x8
; [nakarest] naka_widget_names_charmap+0x5626  +0x5626..+0x562e (0xeb2a96, 8 B)
; [nakarest] Text (8 B at 0xeb2a96), first string "i2.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a96`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20a8).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5626, 0x8
; [nakarest] naka_widget_names_charmap+0x562e  +0x562e..+0x5636 (0xeb2a9e, 8 B)
; [nakarest] Text (8 B at 0xeb2a9e), first string "i1.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2a9e`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20a4).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x562E, 0x8
; [nakarest] naka_widget_names_charmap+0x5636  +0x5636..+0x563e (0xeb2aa6, 8 B)
; [nakarest] Text (8 B at 0xeb2aa6), first string "i0.bmp"; no registered NAKA table points into
; [nakarest] it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2aa6`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb20a0).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5636, 0x8
; [nakarest] naka_widget_names_charmap+0x563e  +0x563e..+0x5648 (0xeb2aae, 10 B)
; [nakarest] Text (10 B at 0xeb2aae), first string "trash.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long 0x00eb2aae`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb209c).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x563E, 0xA
; [nakarest] NakaInst_trash_bmp  +0x5648..+0x5652 (0xeb2ab8, 10 B)
; [nakarest] Text (10 B at 0xeb2ab8), first string "trash.bmp"; no registered NAKA table points
; [nakarest] into it; reached through source references IconBitmapNamePtrTable
; [nakarest] (ui_widgets/widget_names_charmap.s: `.long NakaInst_trash_bmp`); 1 data word in
; [nakarest] IconBitmapNamePtrTable (at 0xeb2098).
NakaInst_trash_bmp:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5648, 0xA
; [nakarest] naka_widget_names_charmap+0x5652  +0x5652..+0x5674 (0xeb2ac2, 34 B)
; [nakarest] widget record, element 0 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): Screen (34 B).
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5652, 0x22
; [nakarest] Naka_FileManagerEntry  +0x5674..+0x568e (0xeb2ae4, 26 B)
; [nakarest] widget record, element 1 of Viewable slot 0x0 (table 0xeb3374, 51 entries,
; [nakarest] InitializeRoot) ("PanelSimulator"): Bitmap (26 B).
Naka_FileManagerEntry:
	.incbin "includes/generated/naka_widget_names_charmap.bin", 0x5674, 0x1A

; External label offsets within the binary blob above.
