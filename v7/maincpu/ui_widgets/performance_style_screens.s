
; Performance & Style screen widgets (477 widgets, 29164 bytes)
; Source: maincpu/ui_widgets/naka_perf_style.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_perf_style
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
; Viewable slot 0xfd: RegObjTabl 0x1600010, ViewableProc, 0x1de,
; 0xe1344e, 0xfd in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 478, table} at 0x27ed2 +
; 14*0xfd. Element 0 is named "ftdemo01" in ResName slot 0x3fd. Links:
; all 478 records consistent.
;
; MainFunction slot 0x14b: RegObjTabl 0x1600003, MainFunctionProc, 0x0,
; 0xe14824, 0x14b in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x14b.
;
; ResName slot 0x3fd: RegObjTabl 0x160000f, ResNameProc, 0x1de,
; 0xe13bca, 0x3fd in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 478, table} at 0x27ed2 +
; 14*0x3fd.
;
; MainFunction slot 0x44b: RegObjTabl 0x1600003, MainFunctionProc, 0x0,
; 0xe14828, 0x44b in InitializeNaka (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 0, table} at 0x27ed2 +
; 14*0x44b.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; [nakarest_retype] NAKA_PerfReg_Container_Root
; NAKA_PerfReg_Container_Root  --  naka_perf_style +0x0..+0x4ada (ROM 0xe0e974..0xe1344e), 19162 bytes
; Widget records of elements 0-477 of Viewable slot 0xfd (table
; 0xe1344e, 478 entries, InitializeNaka), element 0 "ftdemo01"; classes:
; TtlScreen (42 B, id 0x01600034) x26, VwUserBitmapByName (26 B, id
; 0x0160006c) x6, Box (26 B, id 0x01600031) x52, Label (32 B, id
; 0x0160002b) x260, Line (26 B, id 0x0160002e) x72, AcLanguageText (42
; B, id 0x01600066) x15, PsEditSwBox (38 B, id 0x0160001e) x24, EditSw
; (40 B, id 0x01600030) x2, VwEditSwBox (44 B, id 0x0160003e) x3, Bitmap
; (26 B, id 0x0160002c) x5, Frame (28 B, id 0x0160002f) x13.
; -----------------------------------------------------------------------------
NAKA_PerfReg_Container_Root:
	.incbin "includes/generated/naka_perf_style.bin", 0x0, 0x4ADA
; -----------------------------------------------------------------------------
; [nakarest_retype] NAKA_UIObjectTable
; NAKA_UIObjectTable  --  naka_perf_style +0x4ada..+0x5256 (ROM 0xe1344e..0xe13bca), 1916 bytes
; The table itself: Viewable slot 0xfd (table 0xe1344e, 478 entries,
; InitializeNaka) -- 478 x u32 entry pointers.
; -----------------------------------------------------------------------------
NAKA_UIObjectTable:
	.incbin "includes/generated/naka_perf_style.bin", 0x4ADA, 0x77C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_perf_style+0x5256
; naka_perf_style+0x5256  --  naka_perf_style +0x5256..+0x59d4 (ROM 0xe13bca..0xe14348), 1918 bytes
; The table itself: ResName slot 0x3fd (table 0xe13bca, 478 entries,
; InitializeNaka) -- 478 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_perf_style.bin", 0x5256, 0x77E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_perf_style+0x59d4
; naka_perf_style+0x59d4  --  naka_perf_style +0x59d4..+0x5eb0 (ROM 0xe14348..0xe14824), 1244 bytes
; Name strings of elements 0-477 of ResName slot 0x3fd (table 0xe13bca,
; 478 entries, InitializeNaka), names for Viewable slot 0xfd: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_perf_style.bin", 0x59D4, 0x4DC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_perf_style+0x5eb0
; naka_perf_style+0x5eb0  --  naka_perf_style +0x5eb0..+0x5eb4 (ROM 0xe14824..0xe14828), 4 bytes
; The table itself: MainFunction slot 0x14b (table 0xe14824, 0 entries,
; InitializeNaka) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB0, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_perf_style+0x5eb4
; naka_perf_style+0x5eb4  --  naka_perf_style +0x5eb4..+0x71ec (ROM 0xe14828..0xe15b60), 4920 bytes
; The table itself: MainFunction slot 0x44b (table 0xe14828, 0 entries,
; InitializeNaka) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB4, 0x1338
; NAKA_UIObjectTable is at offset 0x4ada within the binary blob above.
; Referenced from flash_floppy_handlers.s (RegisterObjectTable call).
