
; Disk/System UI Panel Widgets (78 widgets, 1942 bytes)
; Source: maincpu/ui_widgets/naka_block_012.c (raw byte array)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_block_012
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
; Class slot 0x160: RegObjTable 0x1600004, ClassProc, 0xeada92,
; 0xeac9ee, 0x160 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 109, is the word at 0xeada92; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x160.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_Block012  +0x0..+0x14 (0xeaccda, 20 B)
; [nakarest] bytes 4-23 of class definition 31 (AcIndexEditSw) of Class slot 0x160 (table 0xeac9ee, 109 entries, InitializeRoot): its parent, allsize, selfsize, name, propdata and propname; its proc word, bytes 0-3, ends the slice before.
NakaData_Block012:
	.incbin "includes/generated/naka_block_012.bin", 0x0, 0x14
; [nakarest] naka_block_012+0x14  +0x14..+0x764 (0xeaccee, 1872 B)
; [nakarest] class definition entries 32-108 of Class slot 0x160 (table 0xeac9ee, 109 entries,
; [nakarest] InitializeRoot) (24 bytes each: proc, parent, allsize, selfsize, name, propdata,
; [nakarest] propname): AcFuncEditSw, PsWideESBox, AcIndexWideES, AcFuncWideES, PsPageBox,
; [nakarest] AcWindowPage, PsToggleBox, PsInvisibleBox, IvPageControl, IvMainEditSw, ....
	.incbin "includes/generated/naka_block_012.bin", 0x14, 0x750
; [nakarest] naka_block_012+0x764  +0x764..+0x766 (0xead43e, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 108 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwUserBitmapByName "X".
	.incbin "includes/generated/naka_block_012.bin", 0x764, 0x2
; [nakarest] naka_block_012+0x766  +0x766..+0x77a (0xead440, 20 B)
; [nakarest] class-name strings (the +12 name) of classes 108 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): VwUserBitmapByName.
	.incbin "includes/generated/naka_block_012.bin", 0x766, 0x14
; [nakarest] naka_block_012+0x77a  +0x77a..+0x77c (0xead454, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 107 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntWelcome "".
	.incbin "includes/generated/naka_block_012.bin", 0x77A, 0x2
; [nakarest] naka_block_012+0x77c  +0x77c..+0x78a (0xead456, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 107 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvIntWelcome.
	.incbin "includes/generated/naka_block_012.bin", 0x77C, 0xE
; [nakarest] naka_block_012+0x78a  +0x78a..+0x78c (0xead464, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 106 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvScreen "".
	.incbin "includes/generated/naka_block_012.bin", 0x78A, 0x2
; [nakarest] naka_block_012+0x78c  +0x78c..+0x796 (0xead466, 10 B)
; [nakarest] class-name strings (the +12 name) of classes 106 of Class slot 0x160 (table
; [nakarest] 0xeac9ee, 109 entries, InitializeRoot): IvScreen.
	.incbin "includes/generated/naka_block_012.bin", 0x78C, 0xA
