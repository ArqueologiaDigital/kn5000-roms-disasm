; naka_accomp7_widgets.s -- Accompaniment screen 7 widget descriptors
;
; 27 widgets for the accompaniment parameter editing screen.
; Two CONTAINER groups (0x35) with MENU_ITEM children, plus
; SEPARATOR (0x28), LIST (0x64), and SCROLLBAR (0x62) widgets.
; ROM address: 0xe1a73e (1050 bytes)

; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_accomp7_widgets
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
; Viewable slot 0xc8: RegObjTabl 0x1600010, ViewableProc, 0x1b,
; 0xe1b9ae, 0xc8 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 27, table} at 0x27ed2 +
; 14*0xc8. Element 0 is named "MspBkslScreen" in ResName slot 0x3c8.
; Links: all 27 records consistent.
; -----------------------------------------------------------------------------

; [nakarest] NakaNode_Accomp7_Widget01  +0x0..+0x24 (0xe1a73e, 36 B)
; [nakarest] widget record, element 1 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): AcWindowPage (36 B).
NakaNode_Accomp7_Widget01:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x0, 0x24
; [nakarest] NakaNode_Accomp7_Widget02  +0x24..+0x40 (0xe1a762, 28 B)
; [nakarest] widget record, element 2 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): IvPageControl (28 B).
NakaNode_Accomp7_Widget02:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x24, 0x1C
; [nakarest] NakaNode_Accomp7_Widget03  +0x40..+0x5c (0xe1a77e, 28 B)
; [nakarest] widget record, element 3 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): IvPageControl (28 B).
NakaNode_Accomp7_Widget03:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x40, 0x1C
; [nakarest] NakaNode_Accomp7_Widget04  +0x5c..+0x76 (0xe1a79a, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): IvShowHide (26 B).
NakaNode_Accomp7_Widget04:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x5C, 0x1A
; [nakarest] NakaNode_Accomp7_Widget05  +0x76..+0x8e (0xe1a7b4, 24 B)
; [nakarest] widget record, element 5 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): IvIntVari (24 B).
NakaNode_Accomp7_Widget05:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x76, 0x18
; [nakarest] NakaNode_Accomp7_Widget06  +0x8e..+0xb2 (0xe1a7cc, 36 B)
; [nakarest] widget record, element 6 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): Window (36 B).
NakaNode_Accomp7_Widget06:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x8E, 0x24
; [nakarest] NakaNode_Accomp7_Widget07  +0xb2..+0xde (0xe1a7f0, 44 B)
; [nakarest] widget record, element 7 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget07:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0xB2, 0x2C
; [nakarest] NakaNode_Accomp7_Widget08  +0xde..+0x10a (0xe1a81c, 44 B)
; [nakarest] widget record, element 8 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget08:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0xDE, 0x2C
; [nakarest] NakaNode_Accomp7_Widget09  +0x10a..+0x136 (0xe1a848, 44 B)
; [nakarest] widget record, element 9 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget09:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x10A, 0x2C
; [nakarest] NakaNode_Accomp7_Widget10  +0x136..+0x162 (0xe1a874, 44 B)
; [nakarest] widget record, element 10 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget10:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x136, 0x2C
; [nakarest] NakaNode_Accomp7_Widget11  +0x162..+0x18e (0xe1a8a0, 44 B)
; [nakarest] widget record, element 11 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget11:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x162, 0x2C
; [nakarest] NakaNode_Accomp7_Widget12  +0x18e..+0x1ba (0xe1a8cc, 44 B)
; [nakarest] widget record, element 12 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget12:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x18E, 0x2C
; [nakarest] NakaNode_Accomp7_Widget13  +0x1ba..+0x1e6 (0xe1a8f8, 44 B)
; [nakarest] widget record, element 13 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget13:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x1BA, 0x2C
; [nakarest] NakaNode_Accomp7_Widget14  +0x1e6..+0x212 (0xe1a924, 44 B)
; [nakarest] widget record, element 14 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget14:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x1E6, 0x2C
; [nakarest] NakaNode_Accomp7_Widget15  +0x212..+0x23e (0xe1a950, 44 B)
; [nakarest] widget record, element 15 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget15:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x212, 0x2C
; [nakarest] NakaNode_Accomp7_Widget16  +0x23e..+0x26a (0xe1a97c, 44 B)
; [nakarest] widget record, element 16 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget16:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x23E, 0x2C
; [nakarest] NakaNode_Accomp7_Widget17  +0x26a..+0x28e (0xe1a9a8, 36 B)
; [nakarest] widget record, element 17 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): Window (36 B).
NakaNode_Accomp7_Widget17:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x26A, 0x24
; [nakarest] NakaNode_Accomp7_Widget18  +0x28e..+0x2ba (0xe1a9cc, 44 B)
; [nakarest] widget record, element 18 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget18:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x28E, 0x2C
; [nakarest] NakaNode_Accomp7_Widget19  +0x2ba..+0x2e6 (0xe1a9f8, 44 B)
; [nakarest] widget record, element 19 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget19:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x2BA, 0x2C
; [nakarest] NakaNode_Accomp7_Widget20  +0x2e6..+0x312 (0xe1aa24, 44 B)
; [nakarest] widget record, element 20 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget20:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x2E6, 0x2C
; [nakarest] NakaNode_Accomp7_Widget21  +0x312..+0x33e (0xe1aa50, 44 B)
; [nakarest] widget record, element 21 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget21:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x312, 0x2C
; [nakarest] NakaNode_Accomp7_Widget22  +0x33e..+0x36a (0xe1aa7c, 44 B)
; [nakarest] widget record, element 22 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget22:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x33E, 0x2C
; [nakarest] NakaNode_Accomp7_Widget23  +0x36a..+0x396 (0xe1aaa8, 44 B)
; [nakarest] widget record, element 23 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget23:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x36A, 0x2C
; [nakarest] NakaNode_Accomp7_Widget24  +0x396..+0x3c2 (0xe1aad4, 44 B)
; [nakarest] widget record, element 24 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget24:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x396, 0x2C
; [nakarest] NakaNode_Accomp7_Widget25  +0x3c2..+0x3ee (0xe1ab00, 44 B)
; [nakarest] widget record, element 25 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget25:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x3C2, 0x2C
; [nakarest] NakaNode_Accomp7_Widget26  +0x3ee..+0x41a (0xe1ab2c, 44 B)
; [nakarest] widget record, element 26 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): VwVariBox (44 B).
NakaNode_Accomp7_Widget26:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x3EE, 0x2C
