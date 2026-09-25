
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

; [nakarest] NAKA_PerfReg_Container_Root  +0x0..+0x4ada (0xe0e974, 19162 B)
; [nakarest] widget records, elements 0-477 of Viewable slot 0xfd (table 0xe1344e, 478 entries,
; [nakarest] InitializeNaka) ("ftdemo01"): TtlScreen (42 B) x26, VwUserBitmapByName (26 B) x6,
; [nakarest] Box (26 B) x52, Label (32 B) x260, Line (26 B) x72, AcLanguageText (42 B) x15,
; [nakarest] PsEditSwBox (38 B) x24, EditSw (40 B) x2, VwEditSwBox (44 B) x3, Bitmap (26 B) x5,
; [nakarest] Frame (28 B) x13. 297 texts the records point at (Viewable slot 0xfd (table
; [nakarest] 0xe1344e, 478 entries, InitializeNaka)): "" (TtlScreen.title of element 0);
; [nakarest] "FTBMP01" (VwUserBitmapByName.file of element 1); "" (TtlScreen.title of element
; [nakarest] 2); "200 Preset" (Label.str of element 5); ....
NAKA_PerfReg_Container_Root:
	.incbin "includes/generated/naka_perf_style.bin", 0x0, 0x4ADA
; [nakarest] NAKA_UIObjectTable  +0x4ada..+0x5256 (0xe1344e, 1916 B)
; [nakarest] the table itself: Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
NAKA_UIObjectTable:
	.incbin "includes/generated/naka_perf_style.bin", 0x4ADA, 0x77C
; [nakarest] naka_perf_style+0x5256  +0x5256..+0x59d4 (0xe13bca, 1918 B)
; [nakarest] the table itself: ResName slot 0x3fd (table 0xe13bca, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5256, 0x77E
; [nakarest] naka_perf_style+0x59d4  +0x59d4..+0x5eb0 (0xe14348, 1244 B)
; [nakarest] name strings, entries 0-477 of ResName slot 0x3fd (table 0xe13bca, 478 entries,
; [nakarest] InitializeNaka) (names for Viewable slot 0xfd): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_perf_style.bin", 0x59D4, 0x4DC
; [nakarest] naka_perf_style+0x5eb0  +0x5eb0..+0x5eb4 (0xe14824, 4 B)
; [nakarest] the table itself: MainFunction slot 0x14b (table 0xe14824, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB0, 0x4
; [nakarest] naka_perf_style+0x5eb4  +0x5eb4..+0x71ec (0xe14828, 4920 B)
; [nakarest] the table itself: MainFunction slot 0x44b (table 0xe14828, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB4, 0x1338
; NAKA_UIObjectTable is at offset 0x4ada within the binary blob above.
; Referenced from flash_floppy_handlers.s (RegisterObjectTable call).
