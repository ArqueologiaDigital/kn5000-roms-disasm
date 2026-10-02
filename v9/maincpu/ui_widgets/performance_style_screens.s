
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
	.incbin "includes/generated/naka_perf_style.bin", 0x0, 0x1697
CDlikeSwTtl_SetRecordAndNotify_Data:	.incbin "includes/generated/naka_perf_style.bin", 0x1697, 0x3443
; [nakarest] NAKA_UIObjectTable  +0x4ada..+0x5256 (0xe1344e, 1916 B)
; [nakarest] the table itself: Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
NAKA_UIObjectTable:
	.incbin "includes/generated/naka_perf_style.bin", 0x4ADA, 0x77C
; [nakarest] naka_perf_style+0x5256  +0x5256..+0x59d4 (0xe13bca, 1918 B)
; [nakarest] the table itself: ResName slot 0x3fd (table 0xe13bca, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
Naka_ResNameTable_3FD:	.incbin "includes/generated/naka_perf_style.bin", 0x5256, 0x77E
; [nakarest] naka_perf_style+0x59d4  +0x59d4..+0x5eb0 (0xe14348, 1244 B)
; [nakarest] name strings, entries 0-477 of ResName slot 0x3fd (table 0xe13bca, 478 entries,
; [nakarest] InitializeNaka) (names for Viewable slot 0xfd): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_perf_style.bin", 0x59D4, 0x4D2
InitializeNaka_Str_TT_FDMSP:	.incbin "includes/generated/naka_perf_style.bin", 0x5EA6, 0xA	; "TT_FDMSP"
; [nakarest] naka_perf_style+0x5eb0  +0x5eb0..+0x5eb4 (0xe14824, 4 B)
; [nakarest] the table itself: MainFunction slot 0x14b (table 0xe14824, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
Naka_MainFunctionTable_14B:	.incbin "includes/generated/naka_perf_style.bin", 0x5EB0, 0x4
; [nakarest] naka_perf_style+0x5eb4  +0x5eb4..+0x5eba (0xe14828, 6 B)
; [nakarest] the table itself: MainFunction slot 0x44b (table 0xe14828, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
Naka_MainFunctionTable_44B:	.incbin "includes/generated/naka_perf_style.bin", 0x5EB4, 0x6
; [nakarest] naka_perf_style+0x5eba  +0x5eba..+0x5f2c (0xe1482e, 114 B)
; [nakarest] A table of 6 pointers into this piece (114 B at 0xe1482e), then text; entry 0
; [nakarest] points at "Bass Port Speaker"; no registered NAKA table points into it; reached
; [nakarest] through source references NAKA_InitDataBlock (storage/flash_floppy_handlers.s: `lda
; [nakarest] xhl, (NAKA_InitDataBlock_PtrTable:24)`).
NAKA_InitDataBlock_PtrTable:	.incbin "includes/generated/naka_perf_style.bin", 0x5EBA, 0x72	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x5f2c  +0x5f2c..+0x5f6c (0xe148a0, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xe148a0 not derived; readers below
; [nakarest] Readers: source references InitializeNaka_Skip (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_2:24)`).
NAKA_InitDataBlock_PtrTable_2:	.incbin "includes/generated/naka_perf_style.bin", 0x5F2C, 0x40	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x5f6c  +0x5f6c..+0x615e (0xe148e0, 498 B)
; [nakarest] A table of 6 pointers into this piece (498 B at 0xe148e0), then text; entry 0
; [nakarest] points at "The KN5000's Special Woofer & Bass Port produce "; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip2
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_3:24)`).
NAKA_InitDataBlock_PtrTable_3:	.incbin "includes/generated/naka_perf_style.bin", 0x5F6C, 0x1F2	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x615e  +0x615e..+0x61d6 (0xe14ad2, 120 B)
; [nakarest] A table of 6 pointers into this piece (120 B at 0xe14ad2), then text; entry 0
; [nakarest] points at "Huge Styles"; no registered NAKA table points into it; reached through
; [nakarest] source references InitializeNaka_Skip3 (storage/flash_floppy_handlers.s: `lda xhl,
; [nakarest] (NAKA_InitDataBlock_PtrTable_4:24)`).
NAKA_InitDataBlock_PtrTable_4:	.incbin "includes/generated/naka_perf_style.bin", 0x615E, 0x78	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x61d6  +0x61d6..+0x6346 (0xe14b4a, 368 B)
; [nakarest] A table of 6 pointers into this piece (368 B at 0xe14b4a), then text; entry 0
; [nakarest] points at "Explore 1000 Musical Styles with the Music Styli"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip4
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_5:24)`).
NAKA_InitDataBlock_PtrTable_5:	.incbin "includes/generated/naka_perf_style.bin", 0x61D6, 0x170	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6346  +0x6346..+0x64d8 (0xe14cba, 402 B)
; [nakarest] A table of 6 pointers into this piece (402 B at 0xe14cba), then text; entry 0
; [nakarest] points at "Add to your enjoyment with a wide range of Techn"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip5
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_6:24)`).
NAKA_InitDataBlock_PtrTable_6:	.incbin "includes/generated/naka_perf_style.bin", 0x6346, 0x192	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x64d8  +0x64d8..+0x6664 (0xe14e4c, 396 B)
; [nakarest] A table of 6 pointers into this piece (396 B at 0xe14e4c), then text; entry 0
; [nakarest] points at "And convert software from almost any other manuf"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip6
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_7:24)`).
NAKA_InitDataBlock_PtrTable_7:	.incbin "includes/generated/naka_perf_style.bin", 0x64D8, 0x18C	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6664  +0x6664..+0x6848 (0xe14fd8, 484 B)
; [nakarest] A table of 6 pointers into this piece (484 B at 0xe14fd8), then text; entry 0
; [nakarest] points at "Store your favorite software patterns in the Cus"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip7
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_8:24)`).
NAKA_InitDataBlock_PtrTable_8:	.incbin "includes/generated/naka_perf_style.bin", 0x6664, 0x1E4	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6848  +0x6848..+0x68cc (0xe151bc, 132 B)
; [nakarest] A table of 6 pointers into this piece (132 B at 0xe151bc), then text; entry 0
; [nakarest] points at "Accordion Register"; no registered NAKA table points into it; reached
; [nakarest] through source references InitializeNaka_Skip8 (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_9:24)`).
NAKA_InitDataBlock_PtrTable_9:	.incbin "includes/generated/naka_perf_style.bin", 0x6848, 0x84	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x68cc  +0x68cc..+0x6a6e (0xe15240, 418 B)
; [nakarest] A table of 6 pointers into this piece (418 B at 0xe15240), then text; entry 0
; [nakarest] points at "A World of Accordion Sounds at your fingertips w"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip9
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_10:24)`).
NAKA_InitDataBlock_PtrTable_10:	.incbin "includes/generated/naka_perf_style.bin", 0x68CC, 0x1A2	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6a6e  +0x6a6e..+0x6ade (0xe153e2, 112 B)
; [nakarest] A table of 6 pointers into this piece (112 B at 0xe153e2), then text; entry 0
; [nakarest] points at "Digital Drawbar"; no registered NAKA table points into it; reached
; [nakarest] through source references InitializeNaka_Skip10 (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_11:24)`).
NAKA_InitDataBlock_PtrTable_11:	.incbin "includes/generated/naka_perf_style.bin", 0x6A6E, 0x70	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6ade  +0x6ade..+0x6c40 (0xe15452, 354 B)
; [nakarest] A table of 6 pointers into this piece (354 B at 0xe15452), then text; entry 0
; [nakarest] points at "Classic Organ Sounds with Jazz and Rock Drawbars"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip11
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_12:24)`).
NAKA_InitDataBlock_PtrTable_12:	.incbin "includes/generated/naka_perf_style.bin", 0x6ADE, 0x162	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6c40  +0x6c40..+0x6cba (0xe155b4, 122 B)
; [nakarest] A table of 6 pointers into this piece (122 B at 0xe155b4), then text; entry 0
; [nakarest] points at "Acoustic Illusion"; no registered NAKA table points into it; reached
; [nakarest] through source references InitializeNaka_Skip12 (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_13:24)`).
NAKA_InitDataBlock_PtrTable_13:	.incbin "includes/generated/naka_perf_style.bin", 0x6C40, 0x7A	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6cba  +0x6cba..+0x6e1c (0xe1562e, 354 B)
; [nakarest] A table of 6 pointers into this piece (354 B at 0xe1562e), then text; entry 0
; [nakarest] points at "Acoustic Illusion broadens your music to 3-Dimen"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip13
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_14:24)`).
NAKA_InitDataBlock_PtrTable_14:	.incbin "includes/generated/naka_perf_style.bin", 0x6CBA, 0x162	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6e1c  +0x6e1c..+0x6f8c (0xe15790, 368 B)
; [nakarest] A table of 6 pointers into this piece (368 B at 0xe15790), then text; entry 0
; [nakarest] points at "A host of features to suit any style of performa"; no registered NAKA
; [nakarest] table points into it; reached through source references InitializeNaka_Skip14
; [nakarest] (storage/flash_floppy_handlers.s: `lda xhl, (NAKA_InitDataBlock_PtrTable_15:24)`).
NAKA_InitDataBlock_PtrTable_15:	.incbin "includes/generated/naka_perf_style.bin", 0x6E1C, 0x170	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6f8c  +0x6f8c..+0x6fec (0xe15900, 96 B)
; [nakarest] A table of 6 pointers into this piece (96 B at 0xe15900), then text; entry 0 points
; [nakarest] at "Huge Styles"; no registered NAKA table points into it; reached through source
; [nakarest] references InitializeNaka_Skip15 (storage/flash_floppy_handlers.s: `lda xhl,
; [nakarest] (NAKA_InitDataBlock_PtrTable_16:24)`).
NAKA_InitDataBlock_PtrTable_16:	.incbin "includes/generated/naka_perf_style.bin", 0x6F8C, 0x60	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x6fec  +0x6fec..+0x704c (0xe15960, 96 B)
; [nakarest] purpose not established: layout of 96 B at 0xe15960 not derived; readers below
; [nakarest] Readers: source references InitializeNaka_Skip16 (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_17:24)`).
NAKA_InitDataBlock_PtrTable_17:	.incbin "includes/generated/naka_perf_style.bin", 0x6FEC, 0x60	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x704c  +0x704c..+0x70ac (0xe159c0, 96 B)
; [nakarest] purpose not established: layout of 96 B at 0xe159c0 not derived; readers below
; [nakarest] Readers: source references InitializeNaka_Skip17 (storage/flash_floppy_handlers.s:
; [nakarest] `lda xhl, (NAKA_InitDataBlock_PtrTable_18:24)`).
NAKA_InitDataBlock_PtrTable_18:	.incbin "includes/generated/naka_perf_style.bin", 0x704C, 0x60	; 6 x 32-bit pointer
; [nakarest] naka_perf_style+0x70ac  +0x70ac..+0x71ac (0xe15a20, 256 B)
; [nakarest] purpose not established: layout of 256 B at 0xe15a20 not derived; readers below
; [nakarest] Readers: source references NoteEvent_LoadSoundGenParams
; [nakarest] (storage/flash_floppy_handlers.s: `ld xiy, NoteEvent_LoadSoundGenParams_Data`).
NoteEvent_LoadSoundGenParams_Data:
	.incbin "includes/generated/naka_perf_style.bin", 0x70AC, 0x100
; [nakarest] naka_perf_style+0x71ac  +0x71ac..+0x71ec (0xe15b20, 64 B)
; [nakarest] purpose not established: layout of 64 B at 0xe15b20 not derived; readers below
; [nakarest] Readers: source references NoteEvent_LoadSoundGenParams
; [nakarest] (storage/flash_floppy_handlers.s: `ld xiy, NoteEvent_LoadSoundGenParams_Data_2`).
NoteEvent_LoadSoundGenParams_Data_2:
	.incbin "includes/generated/naka_perf_style.bin", 0x71AC, 0x40
; NAKA_UIObjectTable is at offset 0x4ada within the binary blob above.
; Referenced from flash_floppy_handlers.s (RegisterObjectTable call).
