
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
; Class slot 0x163: RegObjTable 0x1600004, ClassProc, 0xe55cd4,
; 0xe559ea, 0x163 in InitializeEast (sequencer/seq_event_playback.s) --
; the count, 16, is the word at 0xe55cd4; RegisterObjectTable stores
; {class, proc, count, table} at 0x27ed2 + 14*0x163.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_Block007  +0x0..+0x14 (0xe55a36, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe55a36 that no registered NAKA table points into
NakaData_Block007:
	.incbin "includes/generated/naka_block_007.bin", 0x0, 0x14
; [nakarest] naka_block_007+0x14  +0x14..+0x14c (0xe55a4a, 312 B)
; [nakarest] class definition entries 4-15 of Class slot 0x163 (table 0xe559ea, 16 entries,
; [nakarest] InitializeEast) (24 bytes each: proc, parent, allsize, selfsize, name, propdata,
; [nakarest] propname): AcGMOnOffBox, AcLswFuncEditBox, AcLswFuncBox, AcFadeSetGridBox,
; [nakarest] AcVocalGridBox, AcInOutGridBox, AcParaLoadOptGridBox, AcPcgOutGridBox,
; [nakarest] AcPmemOutLGridBox, AcPmemOutRGridBox, ....
	.incbin "includes/generated/naka_block_007.bin", 0x14, 0x138
; [nakarest] naka_block_007+0x14c  +0x14c..+0x152 (0xe55b82, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 15 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcMidiPartGridBox "XXjn".
	.incbin "includes/generated/naka_block_007.bin", 0x14C, 0x6
; [nakarest] naka_block_007+0x152  +0x152..+0x164 (0xe55b88, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 15 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcMidiPartGridBox.
	.incbin "includes/generated/naka_block_007.bin", 0x152, 0x12
; [nakarest] naka_block_007+0x164  +0x164..+0x16a (0xe55b9a, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 14 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcCtlMsgGridBox "XXjn".
	.incbin "includes/generated/naka_block_007.bin", 0x164, 0x6
; [nakarest] naka_block_007+0x16a  +0x16a..+0x17a (0xe55ba0, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 14 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcCtlMsgGridBox.
	.incbin "includes/generated/naka_block_007.bin", 0x16A, 0x10
; [nakarest] naka_block_007+0x17a  +0x17a..+0x17e (0xe55bb0, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 13 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcPmemOutRGridBox "XXj".
	.incbin "includes/generated/naka_block_007.bin", 0x17A, 0x4
; [nakarest] naka_block_007+0x17e  +0x17e..+0x190 (0xe55bb4, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 13 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcPmemOutRGridBox.
	.incbin "includes/generated/naka_block_007.bin", 0x17E, 0x12
; [nakarest] naka_block_007+0x190  +0x190..+0x192 (0xe55bc6, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 12 of Class slot 0x163 (table
; [nakarest] 0xe559ea, 16 entries, InitializeEast): AcPmemOutLGridBox "XXj".
	.incbin "includes/generated/naka_block_007.bin", 0x190, 0x2
