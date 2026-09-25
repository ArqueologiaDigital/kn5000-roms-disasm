
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
; Class slot 0x160: RegObjTable 0x1600004, ClassProc, 0xeada92,
; 0xeac9ee, 0x160 in InitializeRoot (display/graphics_text_vga.s) -- the
; count, 109, is the word at 0xeada92; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x160.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_Block012
; NakaData_Block012  --  naka_block_012 +0x0..+0x14 (ROM 0xeaccda..0xeaccee), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xeaccda..0xeaccee); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_Block012:
	.incbin "includes/generated/naka_block_012.bin", 0x0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x14
; naka_block_012+0x14  --  naka_block_012 +0x14..+0x764 (ROM 0xeaccee..0xead43e), 1872 bytes
; Class definitions 32-108 of Class slot 0x160 (table 0xeac9ee, 109
; entries, InitializeRoot): AcFuncEditSw, PsWideESBox, AcIndexWideES,
; AcFuncWideES, PsPageBox, AcWindowPage, PsToggleBox, PsInvisibleBox,
; IvPageControl, IvMainEditSw, .... 24 bytes each: +0 proc, +4 parent
; (class id), +8 allsize, +10 selfsize, +12 name, +16 propdata, +20
; propname -- the firmware's own field names, from the propname table of
; the root class "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x14, 0x750
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x764
; naka_block_012+0x764  --  naka_block_012 +0x764..+0x766 (ROM 0xead43e..0xead440), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 108 of Class slot 0x160 (table 0xeac9ee, 109 entries,
; InitializeRoot) (VwUserBitmapByName): "X".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x764, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x766
; naka_block_012+0x766  --  naka_block_012 +0x766..+0x77a (ROM 0xead440..0xead454), 20 bytes
; Class-name strings (the +12 name of classes 108 of Class slot 0x160
; (table 0xeac9ee, 109 entries, InitializeRoot)): VwUserBitmapByName.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x766, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x77a
; naka_block_012+0x77a  --  naka_block_012 +0x77a..+0x77c (ROM 0xead454..0xead456), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 107 of Class slot 0x160 (table 0xeac9ee, 109 entries,
; InitializeRoot) (IvIntWelcome): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x77A, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x77c
; naka_block_012+0x77c  --  naka_block_012 +0x77c..+0x78a (ROM 0xead456..0xead464), 14 bytes
; Class-name strings (the +12 name of classes 107 of Class slot 0x160
; (table 0xeac9ee, 109 entries, InitializeRoot)): IvIntWelcome.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x77C, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x78a
; naka_block_012+0x78a  --  naka_block_012 +0x78a..+0x78c (ROM 0xead464..0xead466), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 106 of Class slot 0x160 (table 0xeac9ee, 109 entries,
; InitializeRoot) (IvScreen): "".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x78A, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_012+0x78c
; naka_block_012+0x78c  --  naka_block_012 +0x78c..+0x796 (ROM 0xead466..0xead470), 10 bytes
; Class-name strings (the +12 name of classes 106 of Class slot 0x160
; (table 0xeac9ee, 109 entries, InitializeRoot)): IvScreen.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_012.bin", 0x78C, 0xA
