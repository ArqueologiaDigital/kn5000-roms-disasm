
; Widget Panel Grid Descriptors (13 widgets, 402 bytes)
; Source: maincpu/ui_widgets/naka_block_007.c (raw byte array)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_block_007
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
; Class slot 0x163: RegObjTable 0x1600004, ClassProc, 0xe55cd4,
; 0xe559ea, 0x163 in InitializeEast (sequencer/seq_event_playback.s) --
; the count, 16, is the word at 0xe55cd4; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x163.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaData_Block007
; NakaData_Block007  --  naka_block_007 +0x0..+0x14 (ROM 0xe55a36..0xe55a4a), 20 bytes
; No RegObjTabl-registered table points at the start of these 20 bytes
; (0xe55a36..0xe55a4a); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaData_Block007:
	.incbin "includes/generated/naka_block_007.bin", 0x0, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x14
; naka_block_007+0x14  --  naka_block_007 +0x14..+0x14c (ROM 0xe55a4a..0xe55b82), 312 bytes
; Class definitions 4-15 of Class slot 0x163 (table 0xe559ea, 16
; entries, InitializeEast): AcGMOnOffBox, AcLswFuncEditBox,
; AcLswFuncBox, AcFadeSetGridBox, AcVocalGridBox, AcInOutGridBox,
; AcParaLoadOptGridBox, AcPcgOutGridBox, AcPmemOutLGridBox,
; AcPmemOutRGridBox, .... 24 bytes each: +0 proc, +4 parent (class id),
; +8 allsize, +10 selfsize, +12 name, +16 propdata, +20 propname -- the
; firmware's own field names, from the propname table of the root class
; "Class".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x14, 0x138
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x14c
; naka_block_007+0x14c  --  naka_block_007 +0x14c..+0x152 (ROM 0xe55b82..0xe55b88), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 15 of Class slot 0x163 (table 0xe559ea, 16 entries,
; InitializeEast) (AcMidiPartGridBox): "XXjn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x14C, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x152
; naka_block_007+0x152  --  naka_block_007 +0x152..+0x164 (ROM 0xe55b88..0xe55b9a), 18 bytes
; Class-name strings (the +12 name of classes 15 of Class slot 0x163
; (table 0xe559ea, 16 entries, InitializeEast)): AcMidiPartGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x152, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x164
; naka_block_007+0x164  --  naka_block_007 +0x164..+0x16a (ROM 0xe55b9a..0xe55ba0), 6 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 14 of Class slot 0x163 (table 0xe559ea, 16 entries,
; InitializeEast) (AcCtlMsgGridBox): "XXjn".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x164, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x16a
; naka_block_007+0x16a  --  naka_block_007 +0x16a..+0x17a (ROM 0xe55ba0..0xe55bb0), 16 bytes
; Class-name strings (the +12 name of classes 14 of Class slot 0x163
; (table 0xe559ea, 16 entries, InitializeEast)): AcCtlMsgGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x16A, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x17a
; naka_block_007+0x17a  --  naka_block_007 +0x17a..+0x17e (ROM 0xe55bb0..0xe55bb4), 4 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 13 of Class slot 0x163 (table 0xe559ea, 16 entries,
; InitializeEast) (AcPmemOutRGridBox): "XXj".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x17A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x17e
; naka_block_007+0x17e  --  naka_block_007 +0x17e..+0x190 (ROM 0xe55bb4..0xe55bc6), 18 bytes
; Class-name strings (the +12 name of classes 13 of Class slot 0x163
; (table 0xe559ea, 16 entries, InitializeEast)): AcPmemOutRGridBox.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x17E, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_block_007+0x190
; naka_block_007+0x190  --  naka_block_007 +0x190..+0x192 (ROM 0xe55bc6..0xe55bc8), 2 bytes
; propdata strings (the +16 field signature, one character per own
; field) of class 12 of Class slot 0x163 (table 0xe559ea, 16 entries,
; InitializeEast) (AcPmemOutLGridBox): "XXj".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_block_007.bin", 0x190, 0x2
