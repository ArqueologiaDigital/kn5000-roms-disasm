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
; Viewable slot 0xc8: RegObjTabl 0x1600010, ViewableProc, 0x1b,
; 0xe1b9ae, 0xc8 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 27, table} at 0x27ed2 +
; 14*0xc8. Element 0 is named "MspBkslScreen" in ResName slot 0x3c8.
; Links: all 27 records consistent.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget01
; NakaNode_Accomp7_Widget01  --  naka_accomp7_widgets +0x0..+0x24 (ROM 0xe1a73e..0xe1a762), 36 bytes
; Widget records of element 1 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; AcWindowPage (36 B, id 0x01600025).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget01:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x0, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget02
; NakaNode_Accomp7_Widget02  --  naka_accomp7_widgets +0x24..+0x40 (ROM 0xe1a762..0xe1a77e), 28 bytes
; Widget records of element 2 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; IvPageControl (28 B, id 0x01600028).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget02:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x24, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget03
; NakaNode_Accomp7_Widget03  --  naka_accomp7_widgets +0x40..+0x5c (ROM 0xe1a77e..0xe1a79a), 28 bytes
; Widget records of element 3 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; IvPageControl (28 B, id 0x01600028).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget03:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x40, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget04
; NakaNode_Accomp7_Widget04  --  naka_accomp7_widgets +0x5c..+0x76 (ROM 0xe1a79a..0xe1a7b4), 26 bytes
; Widget records of element 4 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; IvShowHide (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget04:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x5C, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget05
; NakaNode_Accomp7_Widget05  --  naka_accomp7_widgets +0x76..+0x8e (ROM 0xe1a7b4..0xe1a7cc), 24 bytes
; Widget records of element 5 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; IvIntVari (24 B, id 0x01600062).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget05:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x76, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget06
; NakaNode_Accomp7_Widget06  --  naka_accomp7_widgets +0x8e..+0xb2 (ROM 0xe1a7cc..0xe1a7f0), 36 bytes
; Widget records of element 6 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes: Window
; (36 B, id 0x01600035).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget06:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x8E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget07
; NakaNode_Accomp7_Widget07  --  naka_accomp7_widgets +0xb2..+0xde (ROM 0xe1a7f0..0xe1a81c), 44 bytes
; Widget records of element 7 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget07:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0xB2, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget08
; NakaNode_Accomp7_Widget08  --  naka_accomp7_widgets +0xde..+0x10a (ROM 0xe1a81c..0xe1a848), 44 bytes
; Widget records of element 8 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget08:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0xDE, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget09
; NakaNode_Accomp7_Widget09  --  naka_accomp7_widgets +0x10a..+0x136 (ROM 0xe1a848..0xe1a874), 44 bytes
; Widget records of element 9 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget09:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x10A, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget10
; NakaNode_Accomp7_Widget10  --  naka_accomp7_widgets +0x136..+0x162 (ROM 0xe1a874..0xe1a8a0), 44 bytes
; Widget records of element 10 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget10:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x136, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget11
; NakaNode_Accomp7_Widget11  --  naka_accomp7_widgets +0x162..+0x18e (ROM 0xe1a8a0..0xe1a8cc), 44 bytes
; Widget records of element 11 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget11:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x162, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget12
; NakaNode_Accomp7_Widget12  --  naka_accomp7_widgets +0x18e..+0x1ba (ROM 0xe1a8cc..0xe1a8f8), 44 bytes
; Widget records of element 12 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget12:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x18E, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget13
; NakaNode_Accomp7_Widget13  --  naka_accomp7_widgets +0x1ba..+0x1e6 (ROM 0xe1a8f8..0xe1a924), 44 bytes
; Widget records of element 13 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget13:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x1BA, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget14
; NakaNode_Accomp7_Widget14  --  naka_accomp7_widgets +0x1e6..+0x212 (ROM 0xe1a924..0xe1a950), 44 bytes
; Widget records of element 14 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget14:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x1E6, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget15
; NakaNode_Accomp7_Widget15  --  naka_accomp7_widgets +0x212..+0x23e (ROM 0xe1a950..0xe1a97c), 44 bytes
; Widget records of element 15 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget15:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x212, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget16
; NakaNode_Accomp7_Widget16  --  naka_accomp7_widgets +0x23e..+0x26a (ROM 0xe1a97c..0xe1a9a8), 44 bytes
; Widget records of element 16 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget16:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x23E, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget17
; NakaNode_Accomp7_Widget17  --  naka_accomp7_widgets +0x26a..+0x28e (ROM 0xe1a9a8..0xe1a9cc), 36 bytes
; Widget records of element 17 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes: Window
; (36 B, id 0x01600035).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget17:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x26A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget18
; NakaNode_Accomp7_Widget18  --  naka_accomp7_widgets +0x28e..+0x2ba (ROM 0xe1a9cc..0xe1a9f8), 44 bytes
; Widget records of element 18 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget18:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x28E, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget19
; NakaNode_Accomp7_Widget19  --  naka_accomp7_widgets +0x2ba..+0x2e6 (ROM 0xe1a9f8..0xe1aa24), 44 bytes
; Widget records of element 19 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget19:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x2BA, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget20
; NakaNode_Accomp7_Widget20  --  naka_accomp7_widgets +0x2e6..+0x312 (ROM 0xe1aa24..0xe1aa50), 44 bytes
; Widget records of element 20 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget20:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x2E6, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget21
; NakaNode_Accomp7_Widget21  --  naka_accomp7_widgets +0x312..+0x33e (ROM 0xe1aa50..0xe1aa7c), 44 bytes
; Widget records of element 21 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget21:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x312, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget22
; NakaNode_Accomp7_Widget22  --  naka_accomp7_widgets +0x33e..+0x36a (ROM 0xe1aa7c..0xe1aaa8), 44 bytes
; Widget records of element 22 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget22:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x33E, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget23
; NakaNode_Accomp7_Widget23  --  naka_accomp7_widgets +0x36a..+0x396 (ROM 0xe1aaa8..0xe1aad4), 44 bytes
; Widget records of element 23 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget23:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x36A, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget24
; NakaNode_Accomp7_Widget24  --  naka_accomp7_widgets +0x396..+0x3c2 (ROM 0xe1aad4..0xe1ab00), 44 bytes
; Widget records of element 24 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget24:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x396, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget25
; NakaNode_Accomp7_Widget25  --  naka_accomp7_widgets +0x3c2..+0x3ee (ROM 0xe1ab00..0xe1ab2c), 44 bytes
; Widget records of element 25 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget25:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x3C2, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget26
; NakaNode_Accomp7_Widget26  --  naka_accomp7_widgets +0x3ee..+0x41a (ROM 0xe1ab2c..0xe1ab58), 44 bytes
; Widget records of element 26 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; VwVariBox (44 B, id 0x01640024).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget26:
	.incbin "includes/generated/naka_accomp7_widgets.bin", 0x3EE, 0x2C
